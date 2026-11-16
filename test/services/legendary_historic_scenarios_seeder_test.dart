import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/legendary_historic_scenarios_seeder.dart';

void main() {
  group('LegendaryHistoricScenariosSeeder — Unit Tests', () {
    test('contains exactly 10 unique playable historic scenarios', () {
      const scenarios = LegendaryHistoricScenariosSeeder.scenarios;
      expect(scenarios.length, 10);

      final ids = scenarios.map((s) => s.id).toSet();
      final codes = scenarios.map((s) => s.code).toSet();
      expect(ids.length, 10);
      expect(codes.length, 10);

      for (final scenario in scenarios) {
        expect(scenario.objectives, isNotEmpty);
        expect(scenario.initialConditions, isNotEmpty);
        expect(scenario.playableDistanceKm, greaterThan(0.0));
      }
    });

    test('JSON round-trip preserves HistoricScenarioDefinition', () {
      for (final scenario in LegendaryHistoricScenariosSeeder.scenarios) {
        final json = scenario.toJson();
        final decoded = HistoricScenarioDefinition.fromJson(json);
        expect(decoded.id, scenario.id);
        expect(decoded.code, scenario.code);
        expect(decoded.title, scenario.title);
        expect(decoded.difficulty, scenario.difficulty);
        expect(decoded.category, scenario.category);
        expect(decoded.objectives.length, scenario.objectives.length);
        expect(
          decoded.initialConditions.length,
          scenario.initialConditions.length,
        );
      }
    });

    test('buildPlayableScenario builds valid stage, roster and rivals', () {
      for (final scenario in LegendaryHistoricScenariosSeeder.scenarios) {
        final bundle = LegendaryHistoricScenariosSeeder.buildPlayableScenario(
          scenario.id,
        );
        expect(bundle.definition.id, scenario.id);
        expect(bundle.stage.segments, isNotEmpty);
        expect(bundle.stage.totalDistanceKm, greaterThan(10.0));
        expect(
          bundle.playerRoster.length,
          scenario.initialConditions.length,
        );
        expect(bundle.rivalLeaders.length, 2);
        expect(bundle.playerTeam.id, 'scenario_player_team');
        expect(bundle.playerTeam.rosterRiderIds.length, bundle.playerRoster.length);
      }
    });

    test('bonk defense scenario sets leader glycogen to 9% and -55s gap', () {
      final def = LegendaryHistoricScenariosSeeder.findById(
        'hist_03_bonk_hc_defense',
      );
      expect(def, isNotNull);
      expect(def!.initialTimeGapSeconds, -55);
      expect(def.initialConditions.first.startingGlycogenFraction, 0.09);
      expect(def.availableDomestiquesCount, 2);
    });

    test('evaluateOutcome awards gold, bronze, and none medals accurately', () {
      final bundle = LegendaryHistoricScenariosSeeder.buildPlayableScenario(
        'hist_01_mountain_tt_comeback',
      );

      final goldOutcome = bundle.evaluateOutcome(
        const ScenarioSimulationResult(
          scenarioId: 'hist_01_mountain_tt_comeback',
          leaderStageRank: 1,
          timeGainedOverRivalSeconds: 112,
          finalGcMarginSeconds: 7,
          leaderTimeLossSeconds: 0,
          remainingDomestiquesCount: 0,
        ),
      );
      expect(goldOutcome.isSuccess, isTrue);
      expect(goldOutcome.medal, ScenarioMedalTier.gold);
      expect(goldOutcome.scorePoints, greaterThan(0));

      final bronzeOutcome = bundle.evaluateOutcome(
        const ScenarioSimulationResult(
          scenarioId: 'hist_01_mountain_tt_comeback',
          leaderStageRank: 2,
          timeGainedOverRivalSeconds: 108,
          finalGcMarginSeconds: 3,
          leaderTimeLossSeconds: 4,
          remainingDomestiquesCount: 0,
        ),
      );
      expect(bronzeOutcome.isSuccess, isTrue);
      expect(bronzeOutcome.medal, ScenarioMedalTier.bronze);

      final failOutcome = bundle.evaluateOutcome(
        const ScenarioSimulationResult(
          scenarioId: 'hist_01_mountain_tt_comeback',
          leaderStageRank: 4,
          timeGainedOverRivalSeconds: 80,
          finalGcMarginSeconds: -25,
          leaderTimeLossSeconds: 20,
          remainingDomestiquesCount: 0,
        ),
      );
      expect(failOutcome.isSuccess, isFalse);
      expect(failOutcome.medal, ScenarioMedalTier.none);
      expect(failOutcome.scorePoints, 0);
    });
  });

  group('LegendaryHistoricScenariosPanel — Responsive Widget Tests', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      void Function(PlayableHistoricScenarioBundle)? onLaunch,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LegendaryHistoricScenariosPanel(
              completedScenarioIds: const {'hist_02_cobbles_crosswind_3_doms'},
              earnedMedalsByScenarioId: const {
                'hist_02_cobbles_crosswind_3_doms': ScenarioMedalTier.gold,
              },
              onLaunchScenario: onLaunch,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow at 390x844 (mobile)', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Ukończono: 1 / 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1024x768 (tablet)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Ukończono: 1 / 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1600x900 (desktop)',
        (tester) async {
      PlayableHistoricScenarioBundle? launched;
      await pumpPanelAtSize(
        tester,
        const Size(1600, 900),
        onLaunch: (bundle) => launched = bundle,
      );

      // Filter by 'Weteran' and select a scenario
      await tester.tap(find.text('Weteran'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.textContaining('Złapany w drugim rancie'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Uruchom Scenariusz (HIST-06)'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(launched, isNotNull);
      expect(launched!.definition.id, 'hist_06_echelon_chase_65km');
      expect(tester.takeException(), isNull);
    });
  });
}
