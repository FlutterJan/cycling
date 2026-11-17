import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/ultra_sleep_deprivation_and_circadian_solver.dart';
import 'package:pro_peloton_manager/models/race/ultra_endurance_bikepacking_race_model.dart';

void main() {
  group('UltraSleepDeprivationAndCircadianSolver — Circadian & Sleep Debt', () {
    test('normalizeClockHour wraps negative and >= 24 hours into [0, 24)', () {
      expect(UltraSleepDeprivationAndCircadianSolver.normalizeClockHour(0.0), 0.0);
      expect(UltraSleepDeprivationAndCircadianSolver.normalizeClockHour(24.0), 0.0);
      expect(UltraSleepDeprivationAndCircadianSolver.normalizeClockHour(27.5), 3.5);
      expect(UltraSleepDeprivationAndCircadianSolver.normalizeClockHour(-2.0), 22.0);
    });

    test('classifyCircadianPhase maps all 6 Borbely zones accurately', () {
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(3.5),
        CircadianPhaseZone.circadianNadir,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(6.5),
        CircadianPhaseZone.dawnRebound,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(10.5),
        CircadianPhaseZone.peakAlertness,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(14.5),
        CircadianPhaseZone.postLunchDip,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(22.0),
        CircadianPhaseZone.eveningWindDown,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(0.5),
        CircadianPhaseZone.melatoninOnset,
      );
    });

    test('computeCircadianCurve stays within [0.66, 1.04] with nadir ~03:45', () {
      final nadir = UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(3.75);
      final morning = UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(10.0);
      final postLunch = UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(14.5);

      expect(nadir, inInclusiveRange(0.66, 0.78));
      expect(morning, greaterThan(nadir));
      expect(postLunch, lessThan(morning));
      for (var h = 0; h < 24; h++) {
        final v = UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(
          h.toDouble(),
        );
        expect(v, inInclusiveRange(0.66, 1.04));
      }
    });

    test('classifyDeprivationSeverity covers all 5 clinical tiers', () {
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyDeprivationSeverity(
          const UltraCircadianSleepState(),
        ),
        SleepDeprivationSeverity.fresh,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyDeprivationSeverity(
          const UltraCircadianSleepState(hoursSinceLastSleep: 17.0, sleepDebtHours: 2.5),
        ),
        SleepDeprivationSeverity.mildFatigue,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyDeprivationSeverity(
          const UltraCircadianSleepState(hoursSinceLastSleep: 23.0, sleepDebtHours: 5.5),
        ),
        SleepDeprivationSeverity.moderateImpairment,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyDeprivationSeverity(
          const UltraCircadianSleepState(hoursSinceLastSleep: 31.0, sleepDebtHours: 9.5),
        ),
        SleepDeprivationSeverity.severeHallucinationRisk,
      );
      final critical =
          UltraSleepDeprivationAndCircadianSolver.classifyDeprivationSeverity(
        const UltraCircadianSleepState(
          hoursSinceLastSleep: 41.0,
          sleepDebtHours: 14.5,
          microSleepEventsCount: 2,
        ),
      );
      expect(critical, SleepDeprivationSeverity.criticalMicroSleepDanger);
      expect(critical.requiresMandatoryStop, isTrue);
    });

    test('stepRidingPhysiology accumulates sleep debt, decays caffeine, and triggers micro-sleep deterministically', () {
      const initial = UltraCircadianSleepState(
        elapsedRaceHours: 26.0,
        localClockHour: 2.5,
        hoursSinceLastSleep: 26.0,
        sleepDebtHours: 8.5,
        cognitiveAlertnessPercent: 52.0,
        activeCaffeineMg: 200.0,
      );

      final triggered = UltraSleepDeprivationAndCircadianSolver.stepRidingPhysiology(
        initial,
        const UltraSleepPhysiologyStepInput(
          durationHours: 2.0,
          ambientTempCelsius: 4.0,
          isRaining: true,
          elevationMeters: 2200.0,
          caffeineIntakeMg: 0.0,
          riderResilience: 70.0,
          isTechnicalDescent: true,
          deterministicRoll: 0.0,
        ),
      );

      expect(triggered.circadianPhase, CircadianPhaseZone.circadianNadir);
      expect(triggered.nextState.hoursSinceLastSleep, closeTo(28.0, 1e-6));
      expect(triggered.nextState.sleepDebtHours, greaterThan(initial.sleepDebtHours));
      expect(triggered.nextState.activeCaffeineMg, lessThan(initial.activeCaffeineMg));
      expect(triggered.sleepDebtPowerMultiplier, lessThan(1.0));
      expect(triggered.effectivePowerMultiplier, inInclusiveRange(0.58, 1.02));
      expect(triggered.reactionTimePenaltySeconds, greaterThan(0.2));
      expect(triggered.microSleepProbabilityPerHour, greaterThan(0.0));
      expect(triggered.microSleepTriggered, isTrue);
      expect(triggered.nextState.microSleepEventsCount, 1);

      final notTriggered =
          UltraSleepDeprivationAndCircadianSolver.stepRidingPhysiology(
        initial,
        const UltraSleepPhysiologyStepInput(
          durationHours: 2.0,
          deterministicRoll: 0.999,
        ),
      );
      expect(notTriggered.microSleepTriggered, isFalse);
      expect(notTriggered.nextState.microSleepEventsCount, 0);
    });

    test('evaluateSleepStop distinguishes pushThrough, microNap, bivy, and hotel', () {
      const tiredState = UltraCircadianSleepState(
        elapsedRaceHours: 24.0,
        localClockHour: 1.0,
        hoursSinceLastSleep: 24.0,
        sleepDebtHours: 8.0,
        cognitiveAlertnessPercent: 45.0,
        activeCaffeineMg: 80.0,
      );

      final push = UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
        const SleepStopEvaluationInput(
          currentState: tiredState,
          strategy: UltraSleepStrategy.pushThroughNight,
          shelterCondition: BivyShelterCondition.roadsideBenchMicroNap,
        ),
      );
      expect(push.totalStoppedHours, 0.0);
      expect(push.debtRecoveredHours, 0.0);
      expect(push.electronicsRecharged, isFalse);

      final nap = UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
        const SleepStopEvaluationInput(
          currentState: tiredState,
          strategy: UltraSleepStrategy.microNap20Min,
          shelterCondition: BivyShelterCondition.roadsideBenchMicroNap,
        ),
      );
      expect(nap.postWakeSleepInertiaHours, 0.0);
      expect(nap.alertnessGainedPercent, greaterThan(0.0));
      expect(nap.nextState.microNapsCount, 1);

      final hotel = UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
        SleepStopEvaluationInput(
          currentState: tiredState,
          strategy: UltraSleepStrategy.hotel5Hours,
          shelterCondition: BivyShelterCondition.warmIndoorHotel,
          loadout: BikepackingLoadout.ultraRaceMinimal(),
          hotelDetourHours: 0.5,
          hotelCostEur: 95.0,
        ),
      );
      expect(hotel.hypothermiaRisk, 0.0);
      expect(hotel.electronicsRecharged, isTrue);
      expect(hotel.nextState.hotelStopsCount, 1);
      expect(hotel.nextState.totalHotelSpendEur, closeTo(95.0, 1e-6));
      expect(hotel.debtRecoveredHours, greaterThan(nap.debtRecoveredHours));

      final wetBivyNoBag =
          UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
        const SleepStopEvaluationInput(
          currentState: tiredState,
          strategy: UltraSleepStrategy.bivy4Hours,
          shelterCondition: BivyShelterCondition.wetStormBivy,
          loadout: BikepackingLoadout(
            bags: [],
            hasBivyBag: false,
            hasSleepingBag: false,
            hasRainShell: false,
          ),
          ambientTempCelsius: 1.0,
          isRaining: true,
        ),
      );
      expect(wetBivyNoBag.hypothermiaRisk, greaterThanOrEqualTo(0.45));
      expect(
        wetBivyNoBag.sleepQualityMultiplier,
        lessThan(hotel.sleepQualityMultiplier),
      );
    });

    test('compareBivyVsHotelStrategies recommends hotel in freezing storm with critical debt', () {
      const criticalState = UltraCircadianSleepState(
        hoursSinceLastSleep: 34.0,
        sleepDebtHours: 11.0,
        cognitiveAlertnessPercent: 28.0,
      );

      final stormReport =
          UltraSleepDeprivationAndCircadianSolver.compareBivyVsHotelStrategies(
        currentState: criticalState,
        loadout: BikepackingLoadout.ultraRaceMinimal(),
        ambientTempCelsius: 2.0,
        isRaining: true,
      );
      expect(stormReport.recommendedStrategy, UltraSleepStrategy.hotel5Hours);

      const moderateAwake = UltraCircadianSleepState(
        hoursSinceLastSleep: 19.0,
        sleepDebtHours: 3.5,
        cognitiveAlertnessPercent: 72.0,
      );
      final napReport =
          UltraSleepDeprivationAndCircadianSolver.compareBivyVsHotelStrategies(
        currentState: moderateAwake,
        loadout: BikepackingLoadout.ultraRaceMinimal(),
      );
      expect(napReport.recommendedStrategy, UltraSleepStrategy.microNap20Min);

      final freshReport =
          UltraSleepDeprivationAndCircadianSolver.compareBivyVsHotelStrategies(
        currentState: const UltraCircadianSleepState(),
        loadout: BikepackingLoadout.ultraRaceMinimal(),
      );
      expect(
        freshReport.recommendedStrategy,
        UltraSleepStrategy.pushThroughNight,
      );
    });

    test('simulate24HourCircadianProfile returns 24 sequential hourly samples', () {
      final profile =
          UltraSleepDeprivationAndCircadianSolver.simulate24HourCircadianProfile(
        const UltraCircadianSleepState(localClockHour: 6.0),
      );
      expect(profile, hasLength(24));
      expect(profile.last.nextState.elapsedRaceHours, closeTo(24.0, 1e-6));
      expect(profile.last.nextState.sleepDebtHours, greaterThan(5.0));
    });

    test('UltraCircadianSleepState serializes and deserializes round-trip', () {
      const state = UltraCircadianSleepState(
        elapsedRaceHours: 48.5,
        localClockHour: 14.25,
        hoursSinceLastSleep: 12.0,
        sleepDebtHours: 4.2,
        cumulativeSleepHours: 6.5,
        cognitiveAlertnessPercent: 81.0,
        sleepInertiaRemainingHours: 0.1,
        activeCaffeineMg: 120.0,
        microSleepEventsCount: 1,
        hallucinationIntensity: 0.15,
        bivyStopsCount: 2,
        hotelStopsCount: 1,
        microNapsCount: 3,
        totalSleepStopHours: 14.5,
        totalHotelSpendEur: 85.0,
      );
      final restored = UltraCircadianSleepState.fromJson(state.toJson());
      expect(restored.elapsedRaceHours, state.elapsedRaceHours);
      expect(restored.localClockHour, state.localClockHour);
      expect(restored.sleepDebtHours, state.sleepDebtHours);
      expect(restored.microSleepEventsCount, state.microSleepEventsCount);
      expect(restored.hotelStopsCount, state.hotelStopsCount);
      expect(restored.totalHotelSpendEur, state.totalHotelSpendEur);
    });
  });

  group('BikepackingBagSpec & BikepackingLoadout — Aerodynamics, Weight & Rules', () {
    test('BikepackingBagSpec calculates weight and cubic aero drag', () {
      const bag = BikepackingBagSpec(
        id: 'bar_roll',
        slot: BikepackingBagSlot.handlebarRoll,
        name: 'Bar Roll 3L',
        capacityLiters: 3.0,
        emptyWeightGrams: 200.0,
        packedWeightGrams: 800.0,
        cdaPenaltyM2: 0.004,
      );

      expect(bag.totalWeightKg, closeTo(1.0, 1e-6));
      expect(bag.aeroDragWatts(0.0), 0.0);

      final dragAt10Ms = bag.aeroDragWatts(10.0);
      final dragAt20Ms = bag.aeroDragWatts(20.0);
      expect(dragAt10Ms, closeTo(0.5 * 1.225 * 0.004 * 1000.0, 1e-6));
      expect(dragAt20Ms / dragAt10Ms, closeTo(8.0, 1e-6));

      final unpacked = bag.copyWith(isPacked: false);
      expect(unpacked.totalWeightKg, closeTo(0.2, 1e-6));
    });

    test('BikepackingLoadout.ultraRaceMinimal aggregates volume, weight, climb & aero penalties', () {
      final loadout = BikepackingLoadout.ultraRaceMinimal();
      expect(loadout.bags, hasLength(4));
      expect(loadout.totalBagVolumeLiters, closeTo(14.5, 1e-6));
      expect(loadout.totalGearWeightKg, closeTo(3.845, 1e-3));
      expect(loadout.isMandatoryGearComplete, isTrue);
      expect(loadout.missingMandatoryItems, isEmpty);

      final climbWatts = loadout.climbingWeightPenaltyWatts(
        gradePercent: 8.0,
        speedMs: 5.0,
      );
      expect(climbWatts, greaterThan(10.0));
      expect(
        loadout.climbingWeightPenaltyWatts(gradePercent: 0.0, speedMs: 8.0),
        0.0,
      );
      expect(loadout.totalAeroDragWatts(30.0 / 3.6), greaterThan(2.5));
    });

    test('BikepackingLoadout detects all missing mandatory items', () {
      const incomplete = BikepackingLoadout(
        bags: [],
        hasBivyBag: false,
        hasRainShell: false,
        headlightLumens: 250,
        rearLightLumens: 15,
        hasGpsTracker: false,
        spareTubesCount: 0,
        hasFirstAidKit: false,
        waterCapacityLiters: 1.0,
      );
      expect(incomplete.isMandatoryGearComplete, isFalse);
      expect(incomplete.missingMandatoryItems, hasLength(8));
    });

    test('BikepackingLoadout round-trips through JSON', () {
      final loadout = BikepackingLoadout.ultraRaceMinimal();
      final restored = BikepackingLoadout.fromJson(loadout.toJson());
      expect(restored.bags, hasLength(4));
      expect(restored.totalBagVolumeLiters, closeTo(loadout.totalBagVolumeLiters, 1e-6));
      expect(restored.headlightLumens, loadout.headlightLumens);
    });
  });

  group('DynamoHubSpec & ElectronicsPowerState — Power Budget', () {
    test('DynamoHubSpec electrical output and mechanical drag follow speed & engagement', () {
      final son28 = DynamoHubSpec.son28Ultra();
      expect(son28.electricalOutputWattsAtSpeed(4.0), 0.0);
      expect(son28.electricalOutputWattsAtSpeed(20.0), closeTo(4.8, 1e-6));
      expect(son28.electricalOutputWattsAtSpeed(35.0), closeTo(7.5, 1e-6));
      expect(son28.mechanicalDragWattsAtSpeed(25.0), greaterThan(5.0));

      final disengaged = son28.copyWith(isEngaged: false);
      expect(disengaged.electricalOutputWattsAtSpeed(25.0), 0.0);
      expect(
        disengaged.mechanicalDragWattsAtSpeed(25.0),
        lessThan(son28.mechanicalDragWattsAtSpeed(25.0)),
      );

      final batteryOnly = DynamoHubSpec.batteryOnly();
      expect(batteryOnly.electricalOutputWattsAtSpeed(30.0), 0.0);
      expect(batteryOnly.mechanicalDragWattsAtSpeed(30.0), 0.0);

      expect(
        son28.netChargingWatts(speedKmh: 28.0, activeLoadWatts: 4.35),
        greaterThan(0.0),
      );
      expect(
        son28.netChargingWatts(speedKmh: 10.0, activeLoadWatts: 4.35),
        lessThan(0.0),
      );
    });

    test('ElectronicsPowerState charges with dynamo and risks blackout on battery-only night', () {
      final son28 = DynamoHubSpec.son28Ultra();
      const depleted = ElectronicsPowerState(
        headlightBatteryPercent: 60.0,
        gpsComputerBatteryPercent: 70.0,
        powerBankMah: 2000.0,
        powerBankCapacityMah: 10000.0,
      );

      final dayCharge = depleted.stepPowerBudget(
        durationHours: 3.0,
        avgSpeedKmh: 28.0,
        dynamoHub: son28,
        isNight: false,
      );
      expect(dayCharge.netWh, greaterThan(0.0));
      expect(dayCharge.updatedState.powerBankMah, greaterThan(2000.0));
      expect(dayCharge.updatedState.headlightBatteryPercent, greaterThan(60.0));
      expect(dayCharge.hasLightsOutRisk, isFalse);

      final batteryOnly = DynamoHubSpec.batteryOnly();
      const lowBatteryNight = ElectronicsPowerState(
        headlightBatteryPercent: 30.0,
        gpsComputerBatteryPercent: 25.0,
        powerBankMah: 200.0,
        powerBankCapacityMah: 10000.0,
      );
      final nightDrain = lowBatteryNight.stepPowerBudget(
        durationHours: 3.0,
        avgSpeedKmh: 22.0,
        dynamoHub: batteryOnly,
        isNight: true,
      );
      expect(nightDrain.netWh, lessThan(0.0));
      expect(nightDrain.updatedState.powerBankMah, 0.0);
      expect(nightDrain.updatedState.headlightBatteryPercent, lessThan(15.0));
      expect(nightDrain.hasLightsOutRisk, isTrue);
      expect(nightDrain.hasGpsBlackoutRisk, isTrue);
    });

    test('DynamoHubSpec and ElectronicsPowerState serialize round-trip', () {
      final son28 = DynamoHubSpec.son28Ultra();
      final restoredHub = DynamoHubSpec.fromJson(son28.toJson());
      expect(restoredHub.tier, son28.tier);
      expect(restoredHub.peakOutputWatts, son28.peakOutputWatts);

      const electronics = ElectronicsPowerState(
        headlightBatteryPercent: 82.0,
        powerBankMah: 6400.0,
        isNightLightingActive: true,
      );
      final restoredElec = ElectronicsPowerState.fromJson(electronics.toJson());
      expect(restoredElec.headlightBatteryPercent, 82.0);
      expect(restoredElec.powerBankMah, 6400.0);
      expect(restoredElec.isNightLightingActive, isTrue);
    });
  });

  group('UltraEnduranceBikepackingRaceModel — Readiness & Riding Blocks', () {
    test('transcontinental4000KmPreset evaluates readiness and warnings', () {
      final race = UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset();
      expect(race.totalDistanceKm, 4000.0);
      expect(race.checkpoints, hasLength(5));
      expect(race.routeSegments, hasLength(4));
      expect(race.nextPendingCheckpoint(const [])?.id, 'cp_0_start');

      final legalReport = race.evaluateSetupReadiness(
        loadout: race.defaultLoadout,
        dynamoHub: race.defaultDynamoHub,
        electronics: const ElectronicsPowerState(),
      );
      expect(legalReport.isRaceLegal, isTrue);
      expect(legalReport.netDynamoWattsAt25KmhNight, greaterThan(1.0));

      final riskyReport = race.evaluateSetupReadiness(
        loadout: const BikepackingLoadout(bags: [], hasBivyBag: false),
        dynamoHub: DynamoHubSpec.batteryOnly(),
        electronics: const ElectronicsPowerState(powerBankCapacityMah: 10000.0),
      );
      expect(riskyReport.isRaceLegal, isFalse);
      expect(riskyReport.warnings.length, greaterThanOrEqualTo(2));
    });

    test('simulateRidingBlock advances progress, collects stamps, and enforces night light penalty', () {
      final race = UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset();
      const start = UltraBikepackingRiderProgress(
        riderId: 'rider_ultra_1',
        electronicsState: ElectronicsPowerState(
          headlightBatteryPercent: 5.0,
          powerBankMah: 0.0,
        ),
      );

      final afterNight = race.simulateRidingBlock(
        progress: start,
        durationHours: 2.0,
        baseCruisingSpeedKmh: 26.0,
        loadout: race.defaultLoadout,
        dynamoHub: DynamoHubSpec.batteryOnly(),
        isNight: true,
        segment: race.routeSegments.first,
      );

      expect(afterNight.distanceCoveredKm, greaterThan(40.0));
      expect(afterNight.visitedCheckpointIds, contains('cp_0_start'));
      expect(afterNight.collectedStampIds, contains('cp_0_start'));
      expect(afterNight.electronicsState.headlightBatteryPercent, 0.0);
      expect(
        afterNight.penaltiesHours,
        closeTo(
          UltraSelfSupportedRuleViolation.noWorkingLightsAtNight.defaultTimePenaltyHours,
          1e-6,
        ),
      );

      final afterHotel = afterNight.applySleepStop(
        UltraSleepStrategy.hotel5Hours,
        isWarmShelter: true,
      );
      expect(afterHotel.hoursSinceLastSleep, 0.0);
      expect(afterHotel.electronicsState.headlightBatteryPercent, 100.0);
      expect(
        afterHotel.electronicsState.powerBankMah,
        afterHotel.electronicsState.powerBankCapacityMah,
      );
    });

    test('UltraEnduranceBikepackingRaceModel and UltraBikepackingRiderProgress JSON round-trip', () {
      final race = UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset();
      final restoredRace = UltraEnduranceBikepackingRaceModel.fromJson(race.toJson());
      expect(restoredRace.id, race.id);
      expect(restoredRace.checkpoints, hasLength(5));

      const progress = UltraBikepackingRiderProgress(
        riderId: 'r_42',
        distanceCoveredKm: 1120.0,
        elapsedHours: 58.0,
        visitedCheckpointIds: ['cp_0_start', 'cp_1_alps'],
        penaltiesHours: 2.0,
      );
      final restoredProgress =
          UltraBikepackingRiderProgress.fromJson(progress.toJson());
      expect(restoredProgress.riderId, 'r_42');
      expect(restoredProgress.officialElapsedWithPenaltiesHours, closeTo(60.0, 1e-6));
    });
  });
}
