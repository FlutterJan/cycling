import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/team_time_trial_rider_drop_strategy.dart';
import 'package:pro_peloton_manager/models/team/team_bus_and_warmup_protocol_model.dart';

List<TttDropStrategyRiderProfile> _buildSampleTttRoster({int count = 6}) {
  final List<TttDropStrategyRiderProfile> roster = [
    const TttDropStrategyRiderProfile(
      riderId: 'gc_leader',
      riderName: 'Jan Lider GC',
      ftpWatts: 410,
      wPrimeTotalJoules: 22000,
      wPrimeRemainingJoules: 20000,
      timeTrialSkill: 88,
      staminaSkill: 90,
      isGcLeader: true,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'tt_engine_1',
      riderName: 'Marek Silnik TT',
      ftpWatts: 440,
      wPrimeTotalJoules: 24000,
      wPrimeRemainingJoules: 22000,
      timeTrialSkill: 92,
      staminaSkill: 86,
      isDesignatedPacelineCaptain: true,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'tt_engine_2',
      riderName: 'Piotr Czasowiec',
      ftpWatts: 425,
      wPrimeTotalJoules: 21000,
      wPrimeRemainingJoules: 19500,
      timeTrialSkill: 85,
      staminaSkill: 84,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'domestique_kamikaze',
      riderName: 'Tomasz Pomocnik',
      ftpWatts: 365,
      wPrimeTotalJoules: 23000,
      wPrimeRemainingJoules: 21500,
      timeTrialSkill: 74,
      staminaSkill: 76,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'domestique_2',
      riderName: 'Adam Góral',
      ftpWatts: 380,
      wPrimeTotalJoules: 19000,
      wPrimeRemainingJoules: 17500,
      timeTrialSkill: 72,
      staminaSkill: 80,
    ),
    const TttDropStrategyRiderProfile(
      riderId: 'domestique_low_w',
      riderName: 'Kamil Zmęczony',
      ftpWatts: 360,
      wPrimeTotalJoules: 18000,
      wPrimeRemainingJoules: 2000,
      timeTrialSkill: 70,
      staminaSkill: 72,
    ),
  ];
  return roster.take(count).toList();
}

void main() {
  group('TeamBusAndWarmupProtocolModel & WarmupProtocolPreset', () {
    test('allPresets covers all protocol types and VO2 Priming grants +4.5% ITT bonus', () {
      expect(
        WarmupProtocolPreset.allPresets.length,
        WarmupProtocolType.values.length,
      );
      final vo2Preset = WarmupProtocolPreset.fromType(WarmupProtocolType.vo2PrimingItt);
      expect(vo2Preset.ittStartPowerBonusPercent, 4.5);
      expect(vo2Preset.totalDurationMinutes, 32);
      expect(vo2Preset.steps, isNotEmpty);
    });

    test('VO2 Priming on Pro ERG in optimal window (8-15 min) yields +4.5% start power', () {
      final bus = TeamBusSpecification.forTier(TeamBusTier.worldTourFlagshipBus);
      final model = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_itt_1',
        stageName: 'ITT Chrono',
        isIndividualTimeTrial: true,
        isTeamTimeTrial: false,
        ambientTempCelsius: 20.0,
        hasSteepEarlyClimb: false,
        teamBus: bus,
      ).assignRiderToTrainer(
        riderId: 'r1',
        riderName: 'Lider',
        riderFtpWatts: 400,
        riderWeightKg: 68.0,
        protocolType: WarmupProtocolType.vo2PrimingItt,
        minutesBeforeStart: 12,
      );

      final outcomes = model.evaluateAllAssignments();
      expect(outcomes, hasLength(1));
      final outcome = outcomes.first;
      expect(outcome.effectiveStartPowerBonusPercent, 4.5);
      expect(outcome.startPowerMultiplier, closeTo(1.045, 0.0001));
      expect(outcome.effectiveStartPowerWatts, closeTo(418.0, 0.1));
      expect(outcome.timingEfficiencyFactor, 1.0);
      expect(outcome.isOverheatedRisk, isFalse);
    });

    test('Cold start (none), suboptimal timing, and rollers reduce start power', () {
      final rollersBus = TeamBusSpecification.forTier(TeamBusTier.continentalMinibus);
      final model = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_itt_2',
        stageName: 'ITT Chrono 2',
        isIndividualTimeTrial: true,
        isTeamTimeTrial: false,
        ambientTempCelsius: 20.0,
        hasSteepEarlyClimb: false,
        teamBus: rollersBus,
      );

      final coldOutcome = model.evaluateRiderWarmup(
        const RiderWarmupAssignment(
          riderId: 'r_cold',
          riderName: 'Zimny',
          trainerSlotIndex: 0,
          protocolType: WarmupProtocolType.none,
          coolingStrategy: CoolingStrategyType.none,
          minutesBeforeStart: 10,
          riderFtpWatts: 400,
          riderWeightKg: 70.0,
          ambientTempCelsius: 20.0,
          isIttOrPrologue: true,
        ),
      );
      expect(coldOutcome.effectiveStartPowerBonusPercent, -2.5);
      expect(coldOutcome.effectiveStartPowerWatts, closeTo(390.0, 0.1));

      final rollersLateOutcome = model.evaluateRiderWarmup(
        const RiderWarmupAssignment(
          riderId: 'r_late',
          riderName: 'Spóźniony',
          trainerSlotIndex: 1,
          protocolType: WarmupProtocolType.vo2PrimingItt,
          coolingStrategy: CoolingStrategyType.fanAndColdTowels,
          minutesBeforeStart: 25,
          riderFtpWatts: 400,
          riderWeightKg: 70.0,
          ambientTempCelsius: 20.0,
          isIttOrPrologue: true,
        ),
      );
      expect(rollersLateOutcome.timingEfficiencyFactor, lessThan(1.0));
      expect(rollersLateOutcome.effectiveStartPowerBonusPercent, lessThan(4.5));
    });

    test('Pre-Cooling Ice Vest prevents overheating in hot weather when bus has freezer', () {
      final flagshipBus = TeamBusSpecification.forTier(TeamBusTier.worldTourFlagshipBus);
      final hotModel = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_hot',
        stageName: 'Hot ITT',
        isIndividualTimeTrial: true,
        isTeamTimeTrial: false,
        ambientTempCelsius: 34.0,
        hasSteepEarlyClimb: false,
        teamBus: flagshipBus,
      );

      final noCoolingOutcome = hotModel.evaluateRiderWarmup(
        const RiderWarmupAssignment(
          riderId: 'r_hot_1',
          riderName: 'Przegrzany',
          trainerSlotIndex: 0,
          protocolType: WarmupProtocolType.vo2PrimingItt,
          coolingStrategy: CoolingStrategyType.none,
          minutesBeforeStart: 12,
          riderFtpWatts: 400,
          riderWeightKg: 70.0,
          ambientTempCelsius: 34.0,
          isIttOrPrologue: true,
        ),
      );
      expect(noCoolingOutcome.isOverheatedRisk, isTrue);

      final iceVestOutcome = hotModel.evaluateRiderWarmup(
        const RiderWarmupAssignment(
          riderId: 'r_hot_2',
          riderName: 'Chłodzony',
          trainerSlotIndex: 1,
          protocolType: WarmupProtocolType.vo2PrimingItt,
          coolingStrategy: CoolingStrategyType.preCoolingIceVest,
          minutesBeforeStart: 12,
          riderFtpWatts: 400,
          riderWeightKg: 70.0,
          ambientTempCelsius: 34.0,
          isIttOrPrologue: true,
        ),
      );
      expect(iceVestOutcome.isOverheatedRisk, isFalse);
      expect(
        iceVestOutcome.effectiveStartPowerBonusPercent,
        greaterThan(noCoolingOutcome.effectiveStartPowerBonusPercent),
      );
    });

    test('Paddock trainer slot capacity, removal, recommendations, and JSON round-trip', () {
      final miniBus = TeamBusSpecification.forTier(TeamBusTier.continentalMinibus);
      var model = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_ttt',
        stageName: 'TTT',
        isIndividualTimeTrial: false,
        isTeamTimeTrial: true,
        ambientTempCelsius: 25.0,
        hasSteepEarlyClimb: false,
        teamBus: miniBus,
      );

      expect(
        model.recommendProtocolForStage(
          isItt: false,
          isTtt: true,
          hasSteepEarlyClimb: false,
          isShortPrologueOrCrit: false,
        ),
        WarmupProtocolType.vo2PrimingItt,
      );
      // Continental minibus lacks freezer, so ice vest falls back to fanAndColdTowels
      expect(
        model.recommendCoolingForProtocol(WarmupProtocolType.vo2PrimingItt),
        CoolingStrategyType.fanAndColdTowels,
      );

      model = model
          .assignRiderToTrainer(
            riderId: 'a1',
            riderName: 'A1',
            riderFtpWatts: 380,
            riderWeightKg: 70,
            protocolType: WarmupProtocolType.vo2PrimingItt,
          )
          .assignRiderToTrainer(
            riderId: 'a2',
            riderName: 'A2',
            riderFtpWatts: 390,
            riderWeightKg: 71,
            protocolType: WarmupProtocolType.progressiveRamp,
          )
          .assignRiderToTrainer(
            riderId: 'a3',
            riderName: 'A3',
            riderFtpWatts: 400,
            riderWeightKg: 72,
            protocolType: WarmupProtocolType.progressiveRamp,
          );

      expect(model.assignedRidersCount, 2);
      expect(model.isPaddockFull, isTrue);
      expect(model.freeTrainerSlotsCount, 0);

      final roundTripped = TeamBusAndWarmupProtocolModel.fromJson(model.toJson());
      expect(roundTripped, equals(model));

      model = model.removeRiderFromTrainer('a1');
      expect(model.assignedRidersCount, 1);
      expect(model.isPaddockFull, isFalse);
    });
  });

  group('TeamTimeTrialRiderDropStrategy (Kamikaze Pull & Drop)', () {
    test('evaluatePlan protects GC leader and core TT engines, recommends domestique', () {
      final input = KamikazePullDropInput(
        riders: _buildSampleTttRoster(count: 6),
        distanceRemainingKm: 6.5,
        totalStageDistanceKm: 28.0,
        currentTrainSpeedKmh: 48.0,
        intensity: KamikazePullIntensity.classicKamikaze,
        safetyMode: TttCountingSafetyMode.fiveRiderBuffer,
      );

      final plan = TeamTimeTrialRiderDropStrategy.evaluatePlan(input);
      expect(plan.canExecuteSafely, isTrue);
      expect(plan.activeRidersCount, 6);
      expect(plan.minRequiredFinishers, 5);
      expect(plan.recommendedCandidate, isNotNull);
      expect(
        plan.recommendedCandidate!.riderId,
        isIn(['domestique_kamikaze', 'domestique_2']),
      );
      expect(plan.recommendedCandidate!.isEligible, isTrue);
      expect(plan.projectedPacelineSpeedKmh, greaterThan(48.0));
      expect(plan.projectedTeamTimeGainSeconds, greaterThan(0.0));

      final gcEval = plan.allEvaluations.firstWhere((e) => e.riderId == 'gc_leader');
      expect(gcEval.verdict, KamikazeCandidateVerdict.protectedGcLeader);

      final engineEval = plan.allEvaluations.firstWhere((e) => e.riderId == 'tt_engine_1');
      expect(engineEval.verdict, KamikazeCandidateVerdict.protectedCoreTtEngine);

      final lowWEval = plan.allEvaluations.firstWhere((e) => e.riderId == 'domestique_low_w');
      expect(lowWEval.verdict, KamikazeCandidateVerdict.insufficientWPrime);
    });

    test('safety guard blocks Kamikaze when active riders <= safety floor', () {
      final inputFiveRiders = KamikazePullDropInput(
        riders: _buildSampleTttRoster(count: 5),
        distanceRemainingKm: 5.0,
        totalStageDistanceKm: 25.0,
        currentTrainSpeedKmh: 52.0,
        safetyMode: TttCountingSafetyMode.fiveRiderBuffer,
      );

      final blockedPlan = TeamTimeTrialRiderDropStrategy.evaluatePlan(inputFiveRiders);
      expect(blockedPlan.canExecuteSafely, isFalse);

      final abortedState = TeamTimeTrialRiderDropStrategy.initiateKamikazePull(
        currentState: const KamikazePullDropExecutionState(activeRidersRemaining: 5),
        input: inputFiveRiders,
        candidateRiderId: 'domestique_kamikaze',
      );
      expect(abortedState.phase, KamikazePullDropPhase.abortedSafetyGuard);

      // Switching to UCI minimum 4 allows 1 sacrifice from 5 riders
      final uciMinFourInput = KamikazePullDropInput(
        riders: _buildSampleTttRoster(count: 5),
        distanceRemainingKm: 5.0,
        totalStageDistanceKm: 25.0,
        currentTrainSpeedKmh: 52.0,
        safetyMode: TttCountingSafetyMode.uciMinimumFour,
      );
      final allowedPlan = TeamTimeTrialRiderDropStrategy.evaluatePlan(uciMinFourInput);
      expect(allowedPlan.canExecuteSafely, isTrue);
    });

    test('full execution lifecycle: initiate -> stepExecution -> swingOffAndDrop -> regroupPaceline', () {
      final input = KamikazePullDropInput(
        riders: _buildSampleTttRoster(count: 6),
        distanceRemainingKm: 5.0,
        totalStageDistanceKm: 25.0,
        currentTrainSpeedKmh: 51.0,
        intensity: KamikazePullIntensity.allOutNuclear,
        safetyMode: TttCountingSafetyMode.fiveRiderBuffer,
      );

      var state = TeamTimeTrialRiderDropStrategy.initiateKamikazePull(
        currentState: const KamikazePullDropExecutionState(activeRidersRemaining: 6),
        input: input,
        candidateRiderId: 'domestique_kamikaze',
      );
      expect(state.phase, KamikazePullDropPhase.kamikazePullActive);
      expect(state.activeKamikazeRiderId, 'domestique_kamikaze');
      expect(state.pullTargetWatts, closeTo(365 * 1.38, 0.1));

      // Step until W' drains or maxPullDurationSeconds is reached
      for (int i = 0; i < 20; i++) {
        if (state.phase != KamikazePullDropPhase.kamikazePullActive) break;
        state = TeamTimeTrialRiderDropStrategy.stepExecution(
          state: state,
          input: input,
          dtSeconds: 5.0,
        );
      }

      expect(state.phase, KamikazePullDropPhase.swingOffAndDrop);
      expect(state.activeRidersRemaining, 5);
      expect(state.droppedByKamikazeCount, 1);
      expect(state.droppedRiderIds, contains('domestique_kamikaze'));
      expect(state.cumulativeTimeGainedSeconds, greaterThan(0.0));

      state = TeamTimeTrialRiderDropStrategy.regroupPaceline(state: state);
      expect(state.phase, KamikazePullDropPhase.pacelineRegrouped);
    });

    test('forceSwingOffAndDrop and TttDropStrategyRiderProfile JSON round-trip', () {
      final profile = _buildSampleTttRoster(count: 1).first;
      final decoded = TttDropStrategyRiderProfile.fromJson(profile.toJson());
      expect(decoded.riderId, profile.riderId);
      expect(decoded.ftpWatts, profile.ftpWatts);
      expect(decoded.isGcLeader, profile.isGcLeader);

      const active = KamikazePullDropExecutionState(
        phase: KamikazePullDropPhase.kamikazePullActive,
        activeKamikazeRiderId: 'domestique_kamikaze',
        activeKamikazeRiderName: 'Tomasz Pomocnik',
        activeRidersRemaining: 6,
      );
      final dropped = TeamTimeTrialRiderDropStrategy.forceSwingOffAndDrop(state: active);
      expect(dropped.phase, KamikazePullDropPhase.swingOffAndDrop);
      expect(dropped.activeRidersRemaining, 5);
      expect(dropped.droppedRiderIds, ['domestique_kamikaze']);
    });
  });

  group('KamikazePullDropStrategyPanel Widget Tests', () {
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

          final input = KamikazePullDropInput(
            riders: _buildSampleTttRoster(count: 6),
            distanceRemainingKm: 6.0,
            totalStageDistanceKm: 25.0,
            currentTrainSpeedKmh: 52.0,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox.expand(
                  child: KamikazePullDropStrategyPanel(initialInput: input),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('TTT: Kamikaze Pull & Drop'), findsOneWidget);
          expect(find.text('Odpal Kamikaze Pull'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('interactive Kamikaze Pull & Drop flow updates UI state', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      KamikazePullDropExecutionState? latestState;
      final input = KamikazePullDropInput(
        riders: _buildSampleTttRoster(count: 6),
        distanceRemainingKm: 6.0,
        totalStageDistanceKm: 25.0,
        currentTrainSpeedKmh: 52.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KamikazePullDropStrategyPanel(
              initialInput: input,
              onStateChanged: (s) => latestState = s,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Odpal Kamikaze Pull'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestState?.phase, KamikazePullDropPhase.kamikazePullActive);

      await tester.tap(find.text('Symuluj +5s'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestState?.pullElapsedSeconds, 5.0);

      await tester.tap(find.text('Zjazd & Drop'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestState?.phase, KamikazePullDropPhase.swingOffAndDrop);

      await tester.tap(find.text('Przegrupuj Pociąg'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestState?.phase, KamikazePullDropPhase.pacelineRegrouped);
    });
  });
}
