import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/multi_race_parallel_day_simulator.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';

void main() {
  group('MultiRaceParallelDaySimulator unit tests', () {
    test('generateSample28RiderSquad creates 28 riders with 1 injured', () {
      final squad = MultiRaceParallelDaySimulator.generateSample28RiderSquad();
      expect(squad.length, 28);
      expect(squad.where((r) => !r.isFitToRace).length, 1);
      expect(squad.map((r) => r.riderId).toSet().length, 28);
    });

    test('autoSplitSquadForTwoFronts splits 28 riders without overlap', () {
      final squad = MultiRaceParallelDaySimulator.generateSample28RiderSquad();
      const frontA = ParallelRaceEventSpec(
        raceId: 'tdf_s1',
        raceName: 'Tour de France',
        stageNumber: 1,
        stageName: 'Etap 1',
        terrain: ParallelRaceTerrain.highMountain,
        tier: ParallelRaceTier.grandTour,
        distanceKm: 185.0,
        elevationGainM: 3800,
        requiredMinRiders: 8,
        requiredMaxRiders: 8,
      );
      const frontB = ParallelRaceEventSpec(
        raceId: 'wallonie_s2',
        raceName: 'Tour de Wallonie',
        stageNumber: 2,
        stageName: 'Etap 2',
        terrain: ParallelRaceTerrain.flat,
        tier: ParallelRaceTier.proSeries,
        distanceKm: 175.0,
        elevationGainM: 1100,
        requiredMinRiders: 6,
        requiredMaxRiders: 7,
      );

      for (final strategy in ParallelSplitStrategy.values) {
        final assignments =
            MultiRaceParallelDaySimulator.autoSplitSquadForTwoFronts(
          squad: squad,
          frontA: frontA,
          frontB: frontB,
          strategy: strategy,
        );
        final validation = MultiRaceParallelDaySimulator.validateSplit(
          squad: squad,
          assignments: assignments,
          frontA: frontA,
          frontB: frontB,
        );

        expect(validation.isValid, isTrue, reason: 'Strategy $strategy failed');
        expect(validation.frontACount, 8);
        expect(validation.frontBCount, 7);
        expect(validation.reserveCount, 13);
        expect(validation.duplicateRiderIds, isEmpty);
      }
    });

    test('validateSplit catches unfit rider and invalid front sizes', () {
      final squad = MultiRaceParallelDaySimulator.generateSample28RiderSquad();
      final injuredRider = squad.firstWhere((r) => !r.isFitToRace);
      final initialState = ParallelDaySimulatorState.initialDefault();

      final badAssignments =
          Map<String, ParallelFrontSlot>.from(initialState.assignments);
      badAssignments[injuredRider.riderId] = ParallelFrontSlot.frontA;

      final validation = MultiRaceParallelDaySimulator.validateSplit(
        squad: squad,
        assignments: badAssignments,
        frontA: initialState.frontAEvent,
        frontB: initialState.frontBEvent,
      );

      expect(validation.isValid, isFalse);
      expect(validation.errors.any((e) => e.code == 'RIDER_UNFIT'), isTrue);
      expect(validation.errors.any((e) => e.code == 'FRONT_A_SIZE'), isTrue);
    });

    test('simulateParallelRaceDay runs deterministically for both fronts', () {
      final state = ParallelDaySimulatorState.initialDefault();

      final report1 = MultiRaceParallelDaySimulator.simulateParallelRaceDay(
        calendarDate: state.calendarDate,
        squad: state.squad,
        assignments: state.assignments,
        frontA: state.frontAEvent,
        frontB: state.frontBEvent,
        staffSplit: state.staffSplit,
        seed: 777,
      );
      final report2 = MultiRaceParallelDaySimulator.simulateParallelRaceDay(
        calendarDate: state.calendarDate,
        squad: state.squad,
        assignments: state.assignments,
        frontA: state.frontAEvent,
        frontB: state.frontBEvent,
        staffSplit: state.staffSplit,
        seed: 777,
      );

      expect(report1.frontAResult.riderOutcomes.length, 7);
      expect(report1.frontBResult.riderOutcomes.length, 7);
      expect(report1.reserveRiderIds.length, 14);
      expect(report1.reserveTsbRecoveryDelta, 4.5);
      expect(
        report1.combinedUciPoints,
        report1.frontAResult.totalUciPoints +
            report1.frontBResult.totalUciPoints,
      );
      expect(report1.frontAResult.bestTeamRank, report2.frontAResult.bestTeamRank);
      expect(report1.frontBResult.bestTeamRank, report2.frontBResult.bestTeamRank);
    });

    test('JSON serialization round-trip preserves ParallelRaceDayReport', () {
      final state = ParallelDaySimulatorState.initialDefault();
      final report = MultiRaceParallelDaySimulator.simulateParallelRaceDay(
        calendarDate: state.calendarDate,
        squad: state.squad,
        assignments: state.assignments,
        frontA: state.frontAEvent,
        frontB: state.frontBEvent,
        staffSplit: state.staffSplit,
        seed: 123,
      );

      final json = report.toJson();
      final restored = ParallelRaceDayReport.fromJson(json);

      expect(restored.combinedUciPoints, report.combinedUciPoints);
      expect(restored.combinedPrizeMoneyEur, report.combinedPrizeMoneyEur);
      expect(restored.frontAResult.raceSpec.raceId, report.frontAResult.raceSpec.raceId);
      expect(restored.frontBResult.riderOutcomes.length, report.frontBResult.riderOutcomes.length);
      expect(restored.reserveRiderIds, report.reserveRiderIds);
    });

    test('ParallelRaceEventSpec JSON round-trip preserves weather & terrain', () {
      const spec = ParallelRaceEventSpec(
        raceId: 'roubaix',
        raceName: 'Paris-Roubaix',
        stageNumber: 1,
        stageName: 'Compiègne → Roubaix',
        terrain: ParallelRaceTerrain.cobbleClassic,
        tier: ParallelRaceTier.monument,
        distanceKm: 259.7,
        elevationGainM: 1200,
        requiredMinRiders: 7,
        requiredMaxRiders: 7,
        weatherCondition: WeatherCondition.heavyStorm,
        windSpeedKmh: 42.0,
        priorityWeight: 0.9,
      );
      final restored = ParallelRaceEventSpec.fromJson(spec.toJson());
      expect(restored.terrain, ParallelRaceTerrain.cobbleClassic);
      expect(restored.tier, ParallelRaceTier.monument);
      expect(restored.weatherCondition, WeatherCondition.heavyStorm);
      expect(restored.windSpeedKmh, 42.0);
    });

    test('Notifier handles assignRider, autoSplit, simulation, and readOnly', () {
      final notifier = MultiRaceParallelDaySimulatorNotifier();
      expect(notifier.state.lastReport, isNull);

      notifier.autoSplit(ParallelSplitStrategy.balanced);
      expect(notifier.state.strategy, ParallelSplitStrategy.balanced);

      final report = notifier.runParallelSimulation(seed: 99);
      expect(report, isNotNull);
      expect(notifier.state.lastReport, isNotNull);

      notifier.setReadOnly(true);
      notifier.autoSplit(ParallelSplitStrategy.freshnessFirst);
      expect(notifier.state.strategy, ParallelSplitStrategy.balanced);
    });
  });

  group('MultiRaceParallelDaySimulatorPanel responsive widget tests', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool readOnly = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = MultiRaceParallelDaySimulatorNotifier();
      if (readOnly) {
        notifier.setReadOnly(true);
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            multiRaceParallelDaySimulatorProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: MultiRaceParallelDaySimulatorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile and simulates', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Podwójny Dzień Wyścigowy'), findsOneWidget);

      await tester.tap(find.text('Symuluj Oba Fronty'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Raport Dnia Podwójnego'), findsOneWidget);

      await tester.tap(find.text('Front B'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Równomierny Podział'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop & disabled state', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1600, 900), readOnly: true);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Symuluj Oba Fronty'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Raport Dnia Podwójnego'), findsNothing);
    });
  });
}
