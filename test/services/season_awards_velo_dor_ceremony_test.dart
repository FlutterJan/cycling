import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/season_awards_velo_dor_ceremony.dart';

void main() {
  group('SeasonAwardsVeloDorCeremony — plebiscyt Vélo d\'Or', () {
    const service = SeasonAwardsVeloDorCeremony();

    test('wykrywa okno gali pod koniec października (25–31.10)', () {
      expect(
        SeasonAwardsVeloDorCeremony.isLateOctoberCeremonyDate(
          DateTime(2026, 10, 25),
        ),
        isTrue,
      );
      expect(
        SeasonAwardsVeloDorCeremony.isLateOctoberCeremonyDate(
          DateTime(2026, 10, 29),
        ),
        isTrue,
      );
      expect(
        SeasonAwardsVeloDorCeremony.isLateOctoberCeremonyDate(
          DateTime(2026, 10, 24),
        ),
        isFalse,
      );
      expect(
        SeasonAwardsVeloDorCeremony.isLateOctoberCeremonyDate(
          DateTime(2026, 11, 1),
        ),
        isFalse,
      );
    });

    test('wybiera zwycięzców wszystkich 5 kategorii i liczy bonusy gracza', () {
      final report = SeasonAwardsVeloDorCeremony.generateSampleCeremonyReport(
        seasonYear: 2026,
      );

      expect(report.seasonYear, 2026);
      expect(report.isOfficialLateOctoberWindow, isTrue);
      expect(report.categoryResults.length, 5);

      final worldBest =
          report.resultFor(VeloDorAwardCategory.worldBestRider)!;
      expect(worldBest.winner?.candidateName, 'Tadej Kovačič');
      expect(worldBest.podiumFinalists.length, 3);
      expect(worldBest.winner?.statuetteSpec, isNotNull);

      final climber = report.resultFor(VeloDorAwardCategory.bestClimber)!;
      expect(climber.winner, isNotNull);

      final classics =
          report.resultFor(VeloDorAwardCategory.bestClassicsRider)!;
      expect(classics.winner?.candidateName, 'Mathieu Van Der Berg');

      final u23 = report.resultFor(VeloDorAwardCategory.u23Breakthrough)!;
      expect(u23.winner?.candidateName, 'Jakub Zieliński');
      expect(u23.totalCandidatesEvaluated, 2);

      final manager =
          report.resultFor(VeloDorAwardCategory.managerOfTheYear)!;
      expect(manager.winner?.candidateName, 'Matteo Gianetti');
      expect(manager.podiumFinalists.any((n) => n.isPlayerTeam), isTrue);

      expect(report.playerTeamAwardsWon, greaterThanOrEqualTo(1));
      expect(report.playerTeamPrestigeGain, greaterThan(0));
      expect(report.playerTeamMoraleBoost, greaterThan(0));
    });

    test('filtruje kandydatów U23 wyłącznie do wieku <= 23 lat', () {
      final report = service.conductCeremony(
        seasonYear: 2027,
        riderCandidates: const [
          VeloDorRiderSeasonStats(
            riderId: 'old_star',
            riderName: 'Weteran Szos',
            teamId: 't1',
            teamName: 'Team A',
            nationalityIso: 'BEL',
            age: 28,
            specialization: RiderSpecialization.gcClimber,
            uciPointsSeason: 6000,
            grandTourGcWins: 2,
            totalSeasonWins: 18,
            overallRating: 95,
          ),
          VeloDorRiderSeasonStats(
            riderId: 'young_star',
            riderName: 'Młody Talent',
            teamId: 't2',
            teamName: 'Team B',
            nationalityIso: 'POL',
            age: 20,
            specialization: RiderSpecialization.puncher,
            uciPointsSeason: 1200,
            totalSeasonWins: 4,
            overallRating: 81,
          ),
        ],
        managerCandidates: const [
          VeloDorManagerCandidate(
            managerId: 'm1',
            managerName: 'Jan Kowalski',
            teamId: 't2',
            teamName: 'Team B',
            nationalityIso: 'POL',
            division: TeamDivision.worldTour,
            teamUciPoints: 9000,
            totalSeasonWins: 20,
          ),
        ],
      );

      final u23 = report.resultFor(VeloDorAwardCategory.u23Breakthrough)!;
      expect(u23.totalCandidatesEvaluated, 1);
      expect(u23.winner?.candidateId, 'young_star');
    });

    test('bezpiecznie obsługuje puste listy kandydatów', () {
      final report = service.conductCeremony(
        seasonYear: 2026,
        ceremonyDate: DateTime(2026, 10, 30),
        riderCandidates: const [],
        managerCandidates: const [],
      );

      expect(report.playerTeamAwardsWon, 0);
      expect(report.playerTeamPrestigeGain, 0);
      for (final category in VeloDorAwardCategory.values) {
        final res = report.resultFor(category)!;
        expect(res.winner, isNull);
        expect(res.podiumFinalists, isEmpty);
      }
    });

    test('pełna serializacja JSON (toJson / fromJson) zachowuje spójność', () {
      final original = SeasonAwardsVeloDorCeremony.generateSampleCeremonyReport(
        seasonYear: 2028,
      );
      final json = original.toJson();
      final restored = VeloDorCeremonyReport.fromJson(json);

      expect(restored.seasonYear, original.seasonYear);
      expect(restored.venue, original.venue);
      expect(restored.playerTeamAwardsWon, original.playerTeamAwardsWon);
      expect(restored.playerTeamPrestigeGain, original.playerTeamPrestigeGain);
      expect(restored.categoryResults.length, original.categoryResults.length);
      expect(
        restored.resultFor(VeloDorAwardCategory.worldBestRider)?.winner?.candidateName,
        original.resultFor(VeloDorAwardCategory.worldBestRider)?.winner?.candidateName,
      );
    });
  });

  group('VeloDorCeremonyGalaWidget — UI i responsywność', () {
    Widget buildHarness(Size size, {ValueChanged<VeloDorCategoryResult>? onPresent}) {
      final report = SeasonAwardsVeloDorCeremony.generateSampleCeremonyReport();
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: VeloDorCeremonyGalaWidget(
                report: report,
                onPresentStatuette: onPresent,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('interakcja: zmiana kategorii i wręczenie statuetki', (
      tester,
    ) async {
      VeloDorCategoryResult? presented;
      await tester.pumpWidget(
        buildHarness(
          const Size(1280, 800),
          onPresent: (res) => presented = res,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("GALA VÉLO D'OR 2026"), findsOneWidget);
      expect(find.text('Wręcz Statuetkę'), findsOneWidget);

      await tester.tap(find.text('Menedżer Roku'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ty (Dyrektor Sportowy)'), findsWidgets);

      await tester.tap(find.text('Wręcz Statuetkę'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(presented?.category, VeloDorAwardCategory.managerOfTheYear);
      expect(find.text('Statuetka Wręczona'), findsOneWidget);
    });

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'brak przepełnień RenderFlex w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(buildHarness(viewport));
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text("GALA VÉLO D'OR 2026"), findsOneWidget);
        },
      );
    }
  });
}
