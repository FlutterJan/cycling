import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/ultra_sleep_deprivation_and_circadian_solver.dart';
import 'package:pro_peloton_manager/models/race/ultra_endurance_bikepacking_race_model.dart';

void main() {
  group('UltraSleepDeprivationAndCircadianSolver', () {
    test('circadian curve has nadir around 03:45 and peak in morning/evening', () {
      final nadir =
          UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(3.75);
      final morningPeak =
          UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(10.0);
      final postLunch =
          UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(14.5);

      expect(nadir, lessThan(0.75));
      expect(morningPeak, greaterThan(0.90));
      expect(postLunch, lessThan(morningPeak));
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(3.5),
        CircadianPhaseZone.circadianNadir,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(14.5),
        CircadianPhaseZone.postLunchDip,
      );
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(10.0),
        CircadianPhaseZone.peakAlertness,
      );
    });

    test('riding physiology accumulates sleep debt and decays caffeine', () {
      const initial = UltraCircadianSleepState(
        localClockHour: 22.0,
        activeCaffeineMg: 200.0,
      );

      final result =
          UltraSleepDeprivationAndCircadianSolver.stepRidingPhysiology(
        initial,
        const UltraSleepPhysiologyStepInput(
          durationHours: 5.0,
          ambientTempCelsius: 7.0,
          riderResilience: 75.0,
        ),
      );

      expect(result.nextState.hoursSinceLastSleep, closeTo(5.0, 0.001));
      expect(result.nextState.sleepDebtHours, greaterThan(1.2));
      expect(result.nextState.localClockHour, closeTo(3.0, 0.001));
      // After 1 half-life (5h), 200 mg decays to ~100 mg
      expect(result.nextState.activeCaffeineMg, closeTo(100.0, 0.5));
      expect(result.circadianPhase, CircadianPhaseZone.melatoninOnset);
      expect(
        UltraSleepDeprivationAndCircadianSolver.classifyCircadianPhase(
          result.nextState.localClockHour,
        ),
        CircadianPhaseZone.circadianNadir,
      );
    });

    test('severe deprivation during nadir can trigger deterministic micro-sleep', () {
      const exhausted = UltraCircadianSleepState(
        elapsedRaceHours: 38.0,
        localClockHour: 3.0,
        hoursSinceLastSleep: 36.0,
        sleepDebtHours: 11.5,
        cognitiveAlertnessPercent: 32.0,
      );

      final result =
          UltraSleepDeprivationAndCircadianSolver.stepRidingPhysiology(
        exhausted,
        const UltraSleepPhysiologyStepInput(
          durationHours: 2.0,
          ambientTempCelsius: 4.0,
          isTechnicalDescent: true,
          deterministicRoll: 0.01,
        ),
      );

      expect(result.microSleepTriggered, isTrue);
      expect(result.nextState.microSleepEventsCount, 1);
      expect(result.sleepDebtPowerMultiplier, lessThan(0.85));
      expect(result.hallucinationRisk, greaterThan(0.4));
      expect(
        result.severity,
        anyOf(
          SleepDeprivationSeverity.severeHallucinationRisk,
          SleepDeprivationSeverity.criticalMicroSleepDanger,
        ),
      );
    });

    test('hotel vs bivy vs micro-nap evaluation models quality, inertia and hypothermia', () {
      const tired = UltraCircadianSleepState(
        elapsedRaceHours: 28.0,
        localClockHour: 1.5,
        hoursSinceLastSleep: 24.0,
        sleepDebtHours: 8.5,
        cognitiveAlertnessPercent: 45.0,
      );

      final hotel = UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
        const SleepStopEvaluationInput(
          currentState: tired,
          strategy: UltraSleepStrategy.hotel5Hours,
          shelterCondition: BivyShelterCondition.warmIndoorHotel,
          ambientTempCelsius: 2.0,
          isRaining: true,
          hotelCostEur: 95.0,
        ),
      );

      final wetBivyNoBag =
          UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
        const SleepStopEvaluationInput(
          currentState: tired,
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

      final microNap =
          UltraSleepDeprivationAndCircadianSolver.evaluateSleepStop(
        const SleepStopEvaluationInput(
          currentState: tired,
          strategy: UltraSleepStrategy.microNap20Min,
          shelterCondition: BivyShelterCondition.roadsideBenchMicroNap,
          ambientTempCelsius: 12.0,
        ),
      );

      expect(hotel.electronicsRecharged, isTrue);
      expect(hotel.hypothermiaRisk, 0.0);
      expect(hotel.nextState.totalHotelSpendEur, closeTo(95.0, 0.01));
      expect(hotel.sleepQualityMultiplier, greaterThan(wetBivyNoBag.sleepQualityMultiplier));

      expect(wetBivyNoBag.hypothermiaRisk, greaterThan(0.45));
      expect(wetBivyNoBag.electronicsRecharged, isFalse);

      expect(microNap.postWakeSleepInertiaHours, 0.0);
      expect(microNap.alertnessGainedPercent, greaterThan(8.0));
      expect(microNap.nextState.microNapsCount, 1);
    });

    test('compareBivyVsHotelStrategies recommends hotel in freezing rain when exhausted', () {
      const exhausted = UltraCircadianSleepState(
        elapsedRaceHours: 36.0,
        localClockHour: 2.0,
        hoursSinceLastSleep: 32.0,
        sleepDebtHours: 10.5,
        cognitiveAlertnessPercent: 35.0,
      );

      final report =
          UltraSleepDeprivationAndCircadianSolver.compareBivyVsHotelStrategies(
        currentState: exhausted,
        loadout: const BikepackingLoadout(bags: []),
        ambientTempCelsius: 1.5,
        isRaining: true,
      );

      expect(report.recommendedStrategy, UltraSleepStrategy.hotel5Hours);
      expect(report.bivyEvaluation.hypothermiaRisk, greaterThan(0.15));
      expect(report.hotelEvaluation.thermalComfortScore, greaterThan(90.0));
    });

    test('simulate24HourCircadianProfile returns 24 hourly steps', () {
      final profile =
          UltraSleepDeprivationAndCircadianSolver.simulate24HourCircadianProfile(
        const UltraCircadianSleepState(localClockHour: 6.0),
      );

      expect(profile.length, 24);
      expect(profile.last.nextState.elapsedRaceHours, closeTo(24.0, 0.001));
    });

    test('UltraCircadianSleepState JSON round-trip preserves values', () {
      const state = UltraCircadianSleepState(
        elapsedRaceHours: 42.5,
        localClockHour: 3.25,
        hoursSinceLastSleep: 19.0,
        sleepDebtHours: 6.4,
        cumulativeSleepHours: 5.5,
        cognitiveAlertnessPercent: 62.0,
        sleepInertiaRemainingHours: 0.15,
        activeCaffeineMg: 120.0,
        microSleepEventsCount: 1,
        hallucinationIntensity: 0.22,
        bivyStopsCount: 1,
        hotelStopsCount: 1,
        microNapsCount: 2,
        totalSleepStopHours: 9.8,
        totalHotelSpendEur: 85.0,
      );

      final decoded = UltraCircadianSleepState.fromJson(state.toJson());
      expect(decoded.elapsedRaceHours, state.elapsedRaceHours);
      expect(decoded.localClockHour, state.localClockHour);
      expect(decoded.sleepDebtHours, state.sleepDebtHours);
      expect(decoded.microSleepEventsCount, state.microSleepEventsCount);
      expect(decoded.totalHotelSpendEur, state.totalHotelSpendEur);
    });
  });
}
