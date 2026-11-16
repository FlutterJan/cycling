import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/legendary_historic_scenarios_seeder.dart';
import 'package:pro_peloton_manager/ui/screens/tactical_challenges_hub_screen.dart';

void main() {
  group('TacticalChallengesHubScreen — Unit Tests', () {
    test('ChallengePlayerRecord JSON round-trip preserves all fields', () {
      final original = ChallengePlayerRecord(
        scenarioId: 'hist_01_mountain_tt_comeback',
        bestTimeSeconds: 3875,
        medal: ScenarioMedalTier.gold,
        bestScorePoints: 1450,
        attemptsCount: 5,
        leaderRiderName: 'T. Pogacar',
        achievedAt: DateTime(2026, 7, 14),
      );

      final decoded = ChallengePlayerRecord.fromJson(original.toJson());
      expect(decoded.scenarioId, original.scenarioId);
      expect(decoded.bestTimeSeconds, original.bestTimeSeconds);
      expect(decoded.medal, ScenarioMedalTier.gold);
      expect(decoded.bestScorePoints, 1450);
      expect(decoded.attemptsCount, 5);
      expect(decoded.leaderRiderName, 'T. Pogacar');
    });

    test('TacticalChallengesFormatter formats durations and deltas accurately',
        () {
      expect(TacticalChallengesFormatter.formatDurationSeconds(65), '01:05');
      expect(
        TacticalChallengesFormatter.formatDurationSeconds(3665),
        '1:01:05',
      );
      expect(
        TacticalChallengesFormatter.formatDeltaToTarget(3500, 3520),
        '-00:20',
      );
      expect(
        TacticalChallengesFormatter.formatDeltaToTarget(3550, 3520),
        '+00:30',
      );
      expect(
        TacticalChallengesFormatter.formatDeltaToTarget(3520, 3520),
        '0:00 (Cel)',
      );
    });

    test('TacticalChallengeMedalTargets orders gold < silver < bronze', () {
      for (final scenario in LegendaryHistoricScenariosSeeder.scenarios) {
        final targets = TacticalChallengeMedalTargets.forScenario(scenario);
        expect(targets.goldTargetSeconds, lessThan(targets.silverTargetSeconds));
        expect(
          targets.silverTargetSeconds,
          lessThan(targets.bronzeTargetSeconds),
        );
      }
    });
  });

  group('TacticalChallengesHubScreen — Responsive & Interaction Tests', () {
    Future<void> pumpHubAtSize(
      WidgetTester tester,
      Size size, {
      Map<String, ChallengePlayerRecord>? initialRecords,
      void Function(PlayableHistoricScenarioBundle bundle)? onLaunch,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: TacticalChallengesHubScreen(
            initialRecords: initialRecords,
            onLaunchScenario: onLaunch,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets('renders without overflow at 390x844 (mobile)', (tester) async {
      await pumpHubAtSize(tester, const Size(390, 844));
      expect(find.text('CENTRUM WYZWAŃ TAKTYCZNYCH'), findsOneWidget);
      expect(find.text('WARUNKI ZWYCIĘSTWA'), findsOneWidget);
      expect(
        find.text('TABLICA NAJLEPSZYCH CZASÓW GRACZA'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1024x768 (tablet)',
        (tester) async {
      await pumpHubAtSize(tester, const Size(1024, 768));
      expect(find.text('CENTRUM WYZWAŃ TAKTYCZNYCH'), findsOneWidget);
      expect(find.text('PROGI MEDALOWE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1600x900 (desktop)',
        (tester) async {
      await pumpHubAtSize(tester, const Size(1600, 900));
      expect(find.text('CENTRUM WYZWAŃ TAKTYCZNYCH'), findsOneWidget);
      expect(find.text('PROGI MEDALOWE'), findsOneWidget);
      expect(
        find.text('TABLICA NAJLEPSZYCH CZASÓW GRACZA'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays empty leaderboard state and launches scenario',
        (tester) async {
      PlayableHistoricScenarioBundle? launchedBundle;
      await pumpHubAtSize(
        tester,
        const Size(1600, 900),
        initialRecords: const {},
        onLaunch: (bundle) => launchedBundle = bundle,
      );

      expect(find.text('Brak zapisanych czasów dla HIST-01.'), findsOneWidget);

      final launchButton = find.text('Rozpocznij Wyzwanie (HIST-01)');
      await tester.ensureVisible(launchButton);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(launchButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(launchedBundle, isNotNull);
      expect(launchedBundle!.definition.id, 'hist_01_mountain_tt_comeback');
    });

    testWidgets('filters scenarios and toggles global best times view',
        (tester) async {
      await pumpHubAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Ukończone'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('HIST-02'), findsWidgets);

      await tester.tap(find.text('Wszystkie'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('K. Majewski'), findsWidgets);
    });
  });
}
