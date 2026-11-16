import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/events/commissaire_jury_penalties_engine.dart';
import 'package:pro_peloton_manager/ui/widgets/jury_communique_report_modal.dart';

void main() {
  group('JuryCommuniqueReportData models', () {
    test('serializes and deserializes JuryRiderStatusEntry and CombativityAwardWinner', () {
      const entry = JuryRiderStatusEntry(
        riderId: 'r_177',
        riderName: 'Liam O\'Connor',
        teamName: 'Celtic Pro Cycling',
        teamShortCode: 'CPC',
        bibNumber: 177,
        statusType: JuryEliminationType.otl,
        overTimeLimitSeconds: 194,
        reasonPl: 'Przekroczony limit czasu.',
        reasonEn: 'Outside time limit.',
        isPlayerTeam: true,
      );
      final roundTripEntry = JuryRiderStatusEntry.fromJson(entry.toJson());
      expect(roundTripEntry.riderId, 'r_177');
      expect(roundTripEntry.statusType, JuryEliminationType.otl);
      expect(roundTripEntry.overTimeLimitSeconds, 194);
      expect(roundTripEntry.isPlayerTeam, isTrue);

      const award = CombativityAwardWinner(
        riderId: 'r_042',
        riderName: 'Antoine Moreau',
        teamName: 'Veloce Alpine Pro',
        teamShortCode: 'VAP',
        bibNumber: 42,
        breakawayKilometers: 118.4,
        longestSoloLeadKm: 24.5,
        komPointsEarned: 32,
        sprintPointsEarned: 15,
        juryVotesShare: 0.72,
        citationPl: 'Atak od startu.',
        citationEn: 'Attack from the gun.',
        isPlayerTeam: true,
      );
      final roundTripAward = CombativityAwardWinner.fromJson(award.toJson());
      expect(roundTripAward.bibNumber, 42);
      expect(roundTripAward.breakawayKilometers, 118.4);
      expect(roundTripAward.komPointsEarned, 32);
      expect(roundTripAward.isPlayerTeam, isTrue);
    });

    test('sample data exposes penalties, OTL, DNF and combativity totals', () {
      final sample = JuryCommuniqueReportData.sample(
        playerTeamName: 'Veloce Alpine Pro',
      );
      expect(sample.totalPenaltiesCount, 2);
      expect(sample.totalFinesChf, 900);
      expect(sample.otlEntries.length, 1);
      expect(sample.dnfEntries.length, 1);
      expect(sample.combativityAward, isNotNull);
      expect(sample.hasAnyIncidents, isTrue);
    });
  });

  group('JuryCommuniqueReportModal UI & responsiveness', () {
    Widget buildTestApp(Widget child) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      );
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final data = JuryCommuniqueReportData.sample();
          await tester.pumpWidget(
            buildTestApp(JuryCommuniqueReportModal(data: data)),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.textContaining('COMMUNIQUÉ OFFICIEL'), findsOneWidget);
          expect(find.textContaining('CZERWONY NUMER'), findsWidgets);
          expect(find.text('Antoine Moreau'), findsWidgets);
          expect(find.text('Kacper Majewski'), findsOneWidget);
          expect(find.text('Liam O\'Connor'), findsOneWidget);
          expect(find.text('Julien Marchand'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('supports tab filtering, search and close callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var closed = false;
      final data = JuryCommuniqueReportData.sample();

      await tester.pumpWidget(
        buildTestApp(
          JuryCommuniqueReportModal(
            data: data,
            onClose: () => closed = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('OTL / DNF (2)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Liam O\'Connor'), findsOneWidget);
      expect(find.text('Kacper Majewski'), findsNothing);

      await tester.tap(find.text('Kary (2)'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Kacper Majewski'), findsOneWidget);
      expect(find.text('Liam O\'Connor'), findsNothing);

      await tester.enterText(find.byType(TextField), 'Bellini');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Matteo Bellini'), findsOneWidget);
      expect(find.text('Kacper Majewski'), findsNothing);

      await tester.tap(find.text('Zamknij komunikat'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(closed, isTrue);
    });

    testWidgets('renders clean empty states when no penalties or eliminations', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const cleanCommunique = CommissaireStageCommunique(
        stageNumber: 1,
        stageName: 'Bruxelles → Charleroi',
        decisions: [],
        totalTimePenaltiesSeconds: 0,
        totalFinesChf: 0,
        relegationsCount: 0,
        yellowCardsCount: 0,
        disqualificationsCount: 0,
        finesByTeamChf: {},
      );
      const cleanData = JuryCommuniqueReportData(
        raceName: 'Tour de Belgique',
        communiqueNumber: 1,
        stageNumber: 1,
        stageName: 'Bruxelles → Charleroi',
        stageDateLabel: 'Środa, 12 czerwca',
        stageDistanceKm: 178.0,
        winnerTimeFormatted: '3h 54\' 10"',
        otlTimeLimitFormatted: '+28\' 05" (12%)',
        presidentOfJury: 'Marc Lefèvre (UCI)',
        stageCommunique: cleanCommunique,
        eliminations: [],
      );

      await tester.pumpWidget(
        buildTestApp(const JuryCommuniqueReportModal(data: cleanData)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('nie nałożyło żadnych kar'),
        findsOneWidget,
      );
      expect(
        find.textContaining('ukończyli etap w regulaminowym limicie'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
