import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/sprinter_train_counter_surfing_ai.dart';

void main() {
  const SprinterSurfProfile baseSprinter = SprinterSurfProfile(
    riderId: 'solo_1',
    riderName: 'Solo Ace',
    ftpWatts: 400,
    power5sWatts: 1550,
    sprintSkill: 94,
    bikeHandling: 91,
    raceIq: 88,
    aggression: 82,
    wPrimeTotalJoules: 24000.0,
    wPrimeRemainingJoules: 22000.0,
    currentLateralPosition: 0.0,
    currentSpeedKmh: 61.0,
  );

  const List<RivalTrainSnapshot> sampleTrains = <RivalTrainSnapshot>[
    RivalTrainSnapshot(
      teamId: 't_alpha',
      teamName: 'Alpha Sprint',
      targetSprinterId: 'r_alpha',
      targetSprinterName: 'A. Alpha',
      activeLeadoutRiderId: 'p_alpha',
      remainingHelpers: 3,
      trainSpeedKmh: 64.0,
      lateralRoadPosition: -0.15,
      leadoutPowerWatts: 630,
      leadoutFatigueFraction: 0.18,
      wheelGapOpen: true,
      rivalWheelDefenseSkill: 75,
    ),
    RivalTrainSnapshot(
      teamId: 't_beta',
      teamName: 'Beta Leadout',
      targetSprinterId: 'r_beta',
      targetSprinterName: 'B. Beta',
      activeLeadoutRiderId: 'p_beta',
      remainingHelpers: 1,
      trainSpeedKmh: 60.5,
      lateralRoadPosition: -0.88,
      leadoutPowerWatts: 540,
      leadoutFatigueFraction: 0.82,
      wheelGapOpen: false,
      rivalWheelDefenseSkill: 88,
    ),
  ];

  group('SprinterTrainCounterSurfingAi - Engine', () {
    test('returns standby above 3000m and completed at 0m', () {
      final CounterSurfDecision standby =
          SprinterTrainCounterSurfingAi.evaluateStep(
        const CounterSurfStepInput(
          sprinter: baseSprinter,
          rivalTrains: sampleTrains,
          distanceToFinishMeters: 3500.0,
        ),
      );
      expect(standby.phase, CounterSurfPhase.standby);
      expect(standby.selectedTrainTeamId, isNull);

      final CounterSurfDecision done =
          SprinterTrainCounterSurfingAi.evaluateStep(
        const CounterSurfStepInput(
          sprinter: baseSprinter,
          rivalTrains: sampleTrains,
          distanceToFinishMeters: 0.0,
        ),
      );
      expect(done.phase, CounterSurfPhase.completed);
    });

    test('handles empty rival trains gracefully without throwing', () {
      final CounterSurfDecision decision =
          SprinterTrainCounterSurfingAi.evaluateStep(
        const CounterSurfStepInput(
          sprinter: baseSprinter,
          rivalTrains: [],
          distanceToFinishMeters: 1200.0,
        ),
      );
      expect(decision.phase, CounterSurfPhase.scanningTrains);
      expect(decision.evaluations, isEmpty);
      expect(decision.targetWatts, greaterThan(0));
    });

    test('selects prime rival train and drafts on wheel', () {
      final CounterSurfDecision decision =
          SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: baseSprinter.copyWith(currentLateralPosition: -0.14),
          rivalTrains: sampleTrains,
          distanceToFinishMeters: 1400.0,
        ),
      );
      expect(decision.selectedTrainTeamId, 't_alpha');
      expect(decision.phase, CounterSurfPhase.draftingRivalWheel);
      expect(decision.estimatedDraftSavingsPercent, greaterThan(25.0));
    });

    test('performs wheel hop when current train leadout is fading', () {
      final CounterSurfDecision decision =
          SprinterTrainCounterSurfingAi.evaluateStep(
        const CounterSurfStepInput(
          sprinter: baseSprinter,
          rivalTrains: sampleTrains,
          distanceToFinishMeters: 950.0,
          currentTargetTeamId: 't_beta',
        ),
      );
      expect(decision.didWheelHop, isTrue);
      expect(decision.selectedTrainTeamId, 't_alpha');
      expect(decision.hopReason, WheelHopReason.leadoutFading);
      expect(decision.phase, CounterSurfPhase.wheelHopping);
    });

    test('detects barrier boxing when trapped near barrier by rival train', () {
      final SprinterSurfProfile trappedSprinter = baseSprinter.copyWith(
        currentLateralPosition: -0.90,
        bikeHandling: 76,
        raceIq: 74,
      );
      final List<RivalTrainSnapshot> boxingTrains = <RivalTrainSnapshot>[
        sampleTrains[0].copyWith(lateralRoadPosition: -0.75),
        sampleTrains[1].copyWith(lateralRoadPosition: -0.92),
      ];
      final CounterSurfDecision decision =
          SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: trappedSprinter,
          rivalTrains: boxingTrains,
          distanceToFinishMeters: 600.0,
        ),
      );
      expect(decision.isBoxedIn, isTrue);
      expect(decision.phase, CounterSurfPhase.boxedInRecovery);
      expect(decision.targetLateralPosition, greaterThan(-0.90));
    });

    test('triggers slingshot launch inside 220m with high sprint watts', () {
      final CounterSurfDecision decision =
          SprinterTrainCounterSurfingAi.evaluateStep(
        CounterSurfStepInput(
          sprinter: baseSprinter.copyWith(currentLateralPosition: -0.15),
          rivalTrains: sampleTrains,
          distanceToFinishMeters: 180.0,
          currentTargetTeamId: 't_alpha',
        ),
      );
      expect(decision.phase, CounterSurfPhase.slingshotLaunch);
      expect(decision.isSlingshotReady, isTrue);
      expect(decision.targetWatts, greaterThanOrEqualTo(1400));
    });

    test('respects manual director lock over auto scoring', () {
      final CounterSurfDecision decision =
          SprinterTrainCounterSurfingAi.evaluateStep(
        const CounterSurfStepInput(
          sprinter: baseSprinter,
          rivalTrains: sampleTrains,
          distanceToFinishMeters: 1100.0,
          currentTargetTeamId: 't_alpha',
          manualLockedTeamId: 't_beta',
        ),
      );
      expect(decision.selectedTrainTeamId, 't_beta');
      expect(decision.hopReason, WheelHopReason.manualDirectorOrder);
      expect(decision.didWheelHop, isTrue);
    });

    test('simulates full final approach to slingshot launch', () {
      final List<CounterSurfDecision> steps =
          SprinterTrainCounterSurfingAi.simulateFinalApproach(
        initialSprinter: baseSprinter,
        rivalTrains: sampleTrains,
        startDistanceMeters: 1600.0,
      );
      expect(steps, isNotEmpty);
      expect(
        steps.any((s) => s.phase == CounterSurfPhase.slingshotLaunch),
        isTrue,
      );
    });

    test('JSON serialization round-trip preserves models and enums', () {
      final RivalTrainSnapshot restoredTrain =
          RivalTrainSnapshot.fromJson(sampleTrains.first.toJson());
      expect(restoredTrain.teamId, sampleTrains.first.teamId);
      expect(restoredTrain.trainSpeedKmh, sampleTrains.first.trainSpeedKmh);

      final SprinterSurfProfile restoredSprinter =
          SprinterSurfProfile.fromJson(baseSprinter.toJson());
      expect(restoredSprinter.riderId, baseSprinter.riderId);
      expect(restoredSprinter.power5sWatts, baseSprinter.power5sWatts);

      expect(
        CounterSurfPhase.fromJson(CounterSurfPhase.wheelHopping.toJson()),
        CounterSurfPhase.wheelHopping,
      );
      expect(
        CounterSurfAggression.fromJson(
          CounterSurfAggression.aggressiveWheelThief.toJson(),
        ),
        CounterSurfAggression.aggressiveWheelThief,
      );
    });
  });

  group('SprinterTrainCounterSurfingPanel - Responsive UI', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SprinterTrainCounterSurfingPanel(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('Surf Rival Lead-out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Surf Rival Lead-out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop without overflow',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('Surf Rival Lead-out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports step, aggression switch, and manual wheel lock',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1280, 840));

      await tester.tap(find.text('Krok'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Agresywny Złodziej Koła'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('J. Milan (Lidl-Trek)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tryb Auto AI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
