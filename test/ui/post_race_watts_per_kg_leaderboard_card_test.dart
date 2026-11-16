import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/ui/widgets/post_race_watts_per_kg_leaderboard_card.dart';

PostRaceWattsPerKgLeaderboardData _buildSampleData() {
  return const PostRaceWattsPerKgLeaderboardData(
    stageName: 'Etap 17: Saint-Gervais — Alpe d\'Huez',
    routeName: 'Alpe d\'Huez',
    entries: [
      PostRacePowerRecordEntry(
        riderId: 'r1',
        riderName: 'Tadej Vingegaard',
        teamId: 'team_a',
        teamName: 'Team Apex',
        teamShortCode: 'APX',
        teamColor: AppColors.accentBlue,
        isPlayerTeam: false,
        weightKg: 60.0,
        peak5sWatts: 1180,
        peak1mWatts: 690,
        peak5mWatts: 465,
        peak20mWatts: 405, // 6.75 W/kg (beats 6.58)
      ),
      PostRacePowerRecordEntry(
        riderId: 'r2',
        riderName: 'Jan Kowalski',
        teamId: 'team_player',
        teamName: 'Polska Pro Cycling',
        teamShortCode: 'PPC',
        teamColor: AppColors.goldAccent,
        isPlayerTeam: true,
        weightKg: 66.0,
        peak5sWatts: 1420,
        peak1mWatts: 760, // 11.52 W/kg (beats 11.45)
        peak5mWatts: 480,
        peak20mWatts: 410, // 6.21 W/kg
      ),
      PostRacePowerRecordEntry(
        riderId: 'r3',
        riderName: 'Jasper Philipsen',
        teamId: 'team_b',
        teamName: 'Alpecin Aero',
        teamShortCode: 'ALP',
        teamColor: AppColors.crimsonAlert,
        isPlayerTeam: false,
        weightKg: 75.0,
        peak5sWatts: 1620, // Best 5s sprint
        peak1mWatts: 810,
        peak5mWatts: 440,
        peak20mWatts: 375,
      ),
    ],
    historicalRecords: {
      PowerRecordInterval.sprint5s: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.sprint5s,
        recordValue: 1685.0,
        holderName: 'M. Kittel',
        recordYear: 2017,
        routeOrClimbName: 'Alpe d\'Huez — Meta',
      ),
      PowerRecordInterval.attack1m: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.attack1m,
        recordValue: 11.45,
        holderName: 'M. van der Poel',
        recordYear: 2023,
        routeOrClimbName: 'Alpe d\'Huez — Zryw',
      ),
      PowerRecordInterval.vo2Max5m: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.vo2Max5m,
        recordValue: 7.42,
        holderName: 'T. Pogačar',
        recordYear: 2024,
        routeOrClimbName: 'Alpe d\'Huez — Sektor',
      ),
      PowerRecordInterval.climb20m: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.climb20m,
        recordValue: 6.58,
        holderName: 'M. Pantani',
        recordYear: 1998,
        routeOrClimbName: 'Alpe d\'Huez',
      ),
    },
  );
}

Widget _wrapForTest(Widget child, {required Size size}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('PostRaceWattsPerKgLeaderboardData & calculations', () {
    test('calculates W/kg accurately and sorts descending by selected interval', () {
      final data = _buildSampleData();

      final climbSorted = data.sortedEntries(PowerRecordInterval.climb20m);
      expect(climbSorted.first.riderName, 'Tadej Vingegaard');
      expect(climbSorted.first.peak20mWkg, closeTo(6.75, 0.01));

      final sprintSorted = data.sortedEntries(PowerRecordInterval.sprint5s);
      expect(sprintSorted.first.riderName, 'Jasper Philipsen');
      expect(sprintSorted.first.peak5sWatts, 1620);

      final playerOnly = data.sortedEntries(
        PowerRecordInterval.attack1m,
        onlyPlayerTeam: true,
      );
      expect(playerOnly.length, 1);
      expect(playerOnly.first.riderName, 'Jan Kowalski');
    });

    test('PowerRecordComparison detects new route record and near-record deltas', () {
      final data = _buildSampleData();
      final climbBest = data.bestEntryFor(PowerRecordInterval.climb20m)!;
      final climbComp = data.compareWithHistorical(
        PowerRecordInterval.climb20m,
        climbBest.valueForInterval(PowerRecordInterval.climb20m),
      )!;
      expect(climbComp.isNewRouteRecord, isTrue);
      expect(climbComp.deltaValue, closeTo(0.17, 0.01));

      final sprintBest = data.bestEntryFor(PowerRecordInterval.sprint5s)!;
      final sprintComp = data.compareWithHistorical(
        PowerRecordInterval.sprint5s,
        sprintBest.valueForInterval(PowerRecordInterval.sprint5s),
      )!;
      expect(sprintComp.isNewRouteRecord, isFalse);
      expect(sprintComp.deltaValue, closeTo(-65.0, 0.1));
    });

    test('fromStageReport builds entries for finishers and excludes DNF', () {
      const report = StageSummaryReport(
        stageId: 's_1',
        stageNumber: 5,
        stageName: 'Col du Tourmalet',
        stageType: StageType.highMountain,
        winnerRiderName: 'Rider One',
        winnerTeamId: 'team_player',
        winnerTimeSeconds: 14500,
        timeCutLimitSeconds: 16800,
        timeCutPercent: 16.0,
        otlEliminatedCount: 0,
        dnfCount: 1,
        results: [
          OfficialRiderStageResult(
            riderId: 'r_1',
            riderName: 'Rider One',
            teamId: 'team_player',
            rank: 1,
            rawFinishTimeSeconds: 14500,
            officialFinishTimeSeconds: 14500,
            gapToWinnerSeconds: 0,
          ),
          OfficialRiderStageResult(
            riderId: 'r_2',
            riderName: 'Rider DNF',
            teamId: 'team_other',
            rank: 2,
            rawFinishTimeSeconds: 0,
            officialFinishTimeSeconds: 0,
            gapToWinnerSeconds: 0,
            isDnf: true,
          ),
        ],
        teamPrizeMoneyTotals: {'team_player': 12000},
      );

      final data = PostRaceWattsPerKgLeaderboardData.fromStageReport(
        report: report,
        playerTeamId: 'team_player',
      );
      expect(data.entries.length, 1);
      expect(data.entries.first.isPlayerTeam, isTrue);
      expect(data.historicalRecords.length, 4);
    });
  });

  group('PostRaceWattsPerKgLeaderboardCard widget', () {
    testWidgets('switches intervals, filters player team, and handles empty state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapForTest(
          PostRaceWattsPerKgLeaderboardCard(data: _buildSampleData()),
          size: const Size(1200, 900),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rekordy Mocy Dnia (W / W/kg)'), findsOneWidget);
      expect(find.text('5s Sprint (W)'), findsWidgets);
      expect(find.text('1m Attack (W/kg)'), findsWidgets);
      expect(find.text('5m VO2max (W/kg)'), findsWidgets);
      expect(find.text('20m Climb (W/kg)'), findsWidgets);

      // Przełączenie na filtr drużyny gracza
      await tester.tap(find.text('Tylko moja drużyna'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('Jan Kowalski'), findsWidgets);
      expect(find.text('Jasper Philipsen'), findsNothing);

      // Wyłączenie filtra i przełączenie na 5s Sprint
      await tester.tap(find.text('Tylko moja drużyna'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.tap(find.text('5s Sprint (W)').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('Jasper Philipsen'), findsWidgets);
    });

    testWidgets('renders empty state cleanly without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapForTest(
          PostRaceWattsPerKgLeaderboardCard(
            data: PostRaceWattsPerKgLeaderboardData.empty(),
          ),
          size: const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak zarejestrowanych rekordów mocy dla wybranego filtra.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('responsive without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrapForTest(
            PostRaceWattsPerKgLeaderboardCard(data: _buildSampleData()),
            size: size,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Rekordy Mocy Dnia (W / W/kg)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
