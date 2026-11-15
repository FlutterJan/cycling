import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/physics/altitude_acclimatization_and_heat_engine.dart';
import 'package:pro_peloton_manager/engine/physics/bike_fit_and_wind_tunnel_engine.dart';
import 'package:pro_peloton_manager/engine/physics/nutrition_and_glycogen_engine.dart';
import 'package:pro_peloton_manager/engine/physics/speed_solver.dart';
import 'package:pro_peloton_manager/engine/physics/tire_pressure_calculator.dart';
import 'package:pro_peloton_manager/engine/physics/w_prime_balance_engine.dart';
import 'package:pro_peloton_manager/models/equipment/bike_fit_configuration.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';

void main() {
  group('1. Test Równania Mocy (Góral 58kg/370W vs Sprinter 78kg/420W)', () {
    // Masa całkowita = masa kolarza + rower (6.8 kg) + bidony (1.0 kg)
    const double bikeAndBottlesMassKg = 7.8;
    const double climberMassKg = 58.0 + bikeAndBottlesMassKg; // 65.8 kg
    const double sprinterMassKg = 78.0 + bikeAndBottlesMassKg; // 85.8 kg

    const double climberPowerW = 370.0;
    const double sprinterPowerW = 420.0;

    // Porównujemy w tej samej pozycji aerodynamicznej (drops), aby wyizolować równanie mocy
    const double climberCdA = PhysicsConstants.cdaDrops;
    const double sprinterCdA = PhysicsConstants.cdaDrops;

    const double airDensity = PhysicsConstants.seaLevelAirDensity;
    const double crr = PhysicsConstants.crrSmoothAsphalt;

    test('Na płaskim (0%) sprinter (420W) jest szybszy od górala (370W) mimo większej masy', () {
      final double climberEqSpeedMs = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: climberPowerW,
        totalMassKg: climberMassKg,
        gradientFraction: 0.0,
        effectiveCdA: climberCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double sprinterEqSpeedMs = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: sprinterPowerW,
        totalMassKg: sprinterMassKg,
        gradientFraction: 0.0,
        effectiveCdA: sprinterCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double climberKmh = climberEqSpeedMs * 3.6;
      final double sprinterKmh = sprinterEqSpeedMs * 3.6;

      // Na płaskim decyduje moc bezwzględna przeciw oporowi aero (~43-50 km/h)
      expect(climberKmh, inInclusiveRange(42.0, 50.0));
      expect(sprinterKmh, inInclusiveRange(43.0, 52.0));
      expect(sprinterKmh, greaterThan(climberKmh));
    });

    test('Na ściance (10%) góral (58kg, 370W) jest wyraźnie szybszy od sprintera (78kg, 420W)', () {
      final double climberEqSpeedMs = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: climberPowerW,
        totalMassKg: climberMassKg,
        gradientFraction: 0.10,
        effectiveCdA: climberCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double sprinterEqSpeedMs = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: sprinterPowerW,
        totalMassKg: sprinterMassKg,
        gradientFraction: 0.10,
        effectiveCdA: sprinterCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double climberKmh = climberEqSpeedMs * 3.6;
      final double sprinterKmh = sprinterEqSpeedMs * 3.6;

      // Góral: 370/58 = 6.38 W/kg vs Sprinter: 420/78 = 5.38 W/kg
      expect(climberKmh, inInclusiveRange(18.0, 25.0));
      expect(sprinterKmh, inInclusiveRange(15.0, 22.0));
      expect(climberKmh - sprinterKmh, greaterThan(1.5));
    });

    test('Bilans sił w punkcie równowagi i zbieżność kroku czasowego solveNextSecond', () {
      const double gradient = 0.08;
      final double eqSpeedMs = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: climberPowerW,
        totalMassKg: climberMassKg,
        gradientFraction: gradient,
        effectiveCdA: climberCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 30,
      );

      final double fProp = SpeedSolver.calculatePropulsionForce(
        inputWatts: climberPowerW,
        currentSpeedMs: eqSpeedMs,
      );
      final forces = SpeedSolver.calculateResistanceForces(
        speedMs: eqSpeedMs,
        totalMassKg: climberMassKg,
        gradientFraction: gradient,
        effectiveCdA: climberCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
      );

      // W prędkości równowagowej siła napędowa równoważy sumę oporów
      expect((fProp - forces.totalResistanceForce).abs(), lessThan(0.1));

      // Rozpędzanie od 2.0 m/s przez 60 sekund powinno zbiegać do prędkości równowagowej
      double v = 2.0;
      for (int s = 0; s < 60; s++) {
        final step = SpeedSolver.solveNextSecond(
          inputWatts: climberPowerW,
          currentSpeedMs: v,
          totalMassKg: climberMassKg,
          gradientFraction: gradient,
          effectiveCdA: climberCdA,
          airDensityKgM3: airDensity,
          effectiveCrr: crr,
          windSpeedMs: 0.0,
          relativeWindAngleDegrees: 0.0,
        );
        v = step.newSpeedMs;
      }
      expect((v - eqSpeedMs).abs(), lessThan(0.05));
    });
  });

  group('2. Test Tunelu Aero i Ciśnienia na dystansie 40 km', () {
    const ttSpecialistPhysiology = RiderPhysiology(
      heightCm: 180.0,
      weightKg: 72.0,
      bodyFatPercentage: 6.5,
      ftpWatts: 430,
      wPrimeJoules: 22000,
      vo2Max: 80.0,
      maxHr: 194,
      restingHr: 39,
      lactateThresholdHr: 174,
      recoveryRate: 1.15,
      glycogenCapacityGrams: 580.0,
    );

    const baselineFit = BikeFitConfiguration(
      saddleHeightMm: 760.0,
      saddleSetbackMm: 60.0,
      saddleTiltDegrees: 0.0,
      cockpitWidthMm: 420,
      stemLengthMm: 100,
      spacersStackMm: 30,
      hoodInwardTiltDegrees: 0.0,
      crankArmLengthMm: 175.0,
      cleatOffsetMm: 0.0,
    );

    const aggressiveAeroFit = BikeFitConfiguration(
      saddleHeightMm: 760.0,
      saddleSetbackMm: 52.0,
      saddleTiltDegrees: -2.0,
      cockpitWidthMm: 360,
      stemLengthMm: 130,
      spacersStackMm: 0,
      hoodInwardTiltDegrees: 14.0,
      crankArmLengthMm: 165.0,
      cleatOffsetMm: -5.0,
    );

    test('Obniżenie CdA w tunelu aero daje mierzalną oszczędność watów i czasu na 40 km', () {
      final baselineReport = BikeFitAndWindTunnelEngine.calculateAerodynamics(
        fit: baselineFit,
        physiology: ttSpecialistPhysiology,
      );
      final aeroReport = BikeFitAndWindTunnelEngine.calculateAerodynamics(
        fit: aggressiveAeroFit,
        physiology: ttSpecialistPhysiology,
      );

      expect(aeroReport.fittedCdA, lessThan(baselineReport.fittedCdA));
      expect(aeroReport.deltaCdA, lessThan(0.0));
      expect(aeroReport.wattsSavedAt45Kmh, greaterThan(10));
      expect(aeroReport.wattsSavedAt50Kmh, greaterThan(aeroReport.wattsSavedAt45Kmh));
      expect(aeroReport.timeSavedSecondsOver40Km, greaterThan(20.0));

      // Weryfikacja bezpośrednio przez SpeedSolver na dystansie 40 km (40 000 m)
      const double distanceM = 40000.0;
      const double totalMassKg = 72.0 + 7.8;
      const double powerW = 400.0;

      final double vBaseline = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: powerW,
        totalMassKg: totalMassKg,
        gradientFraction: 0.0,
        effectiveCdA: baselineReport.fittedCdA,
        airDensityKgM3: PhysicsConstants.seaLevelAirDensity,
        effectiveCrr: PhysicsConstants.crrSmoothAsphalt,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double vAero = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: powerW,
        totalMassKg: totalMassKg,
        gradientFraction: 0.0,
        effectiveCdA: aeroReport.fittedCdA,
        airDensityKgM3: PhysicsConstants.seaLevelAirDensity,
        effectiveCrr: PhysicsConstants.crrSmoothAsphalt,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double timeBaselineSec = distanceM / vBaseline;
      final double timeAeroSec = distanceM / vAero;
      final double timeGainSec = timeBaselineSec - timeAeroSec;

      expect(vAero, greaterThan(vBaseline));
      expect(timeGainSec, greaterThan(30.0));
    });

    test('Dobór optymalnego ciśnienia na bruku eliminuje straty impedancji i daje przewagę na 40 km', () {
      const double totalMassKg = 82.0; // 73 kg kolarz + 7.8 kg rower + 1.2 kg
      const int tireWidthMm = 30;

      final smoothRec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: totalMassKg,
        tireWidthMm: tireWidthMm,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.smoothAsphalt,
      );

      final cobbleRec = TirePressureCalculator.calculateOptimalPressure(
        totalMassKg: totalMassKg,
        tireWidthMm: tireWidthMm,
        tireSystem: TireSystemType.tubeless,
        surface: RoadSurfaceCategory.cobblestones,
      );

      // Optymalne ciśnienie na bruku musi być wyraźnie niższe niż na gładkim asfalcie
      expect(cobbleRec.frontPressureBar, lessThan(smoothRec.frontPressureBar));
      expect(cobbleRec.rearPressureBar, lessThan(smoothRec.rearPressureBar));

      // Ocena ciśnienia optymalnego vs przepompowanego (7.5 BAR na bruku)
      final optimalEval = TirePressureCalculator.evaluatePressure(
        frontPressureBar: cobbleRec.frontPressureBar,
        rearPressureBar: cobbleRec.rearPressureBar,
        recommendation: cobbleRec,
        speedKmh: 40.0,
      );

      final overpressureEval = TirePressureCalculator.evaluatePressure(
        frontPressureBar: 7.5,
        rearPressureBar: 7.5,
        recommendation: cobbleRec,
        speedKmh: 40.0,
      );

      expect(optimalEval.verdict, equals(PressureEvaluationVerdict.optimal));
      expect(optimalEval.impedanceLossWatts, equals(0.0));
      expect(overpressureEval.impedanceLossWatts, greaterThan(15.0));
      expect(overpressureEval.corneringGripPercent, lessThan(optimalEval.corneringGripPercent));

      // Przełożenie różnicy strat watów wibracyjnych na czas przejazdu 40 km bruku
      const double distanceM = 40000.0;
      const double riderPowerW = 360.0;
      final double effectivePowerOptimal = riderPowerW - optimalEval.impedanceLossWatts;
      final double effectivePowerOverpressured =
          math.max(100.0, riderPowerW - overpressureEval.impedanceLossWatts);

      final double speedOptimal = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: effectivePowerOptimal,
        totalMassKg: totalMassKg,
        gradientFraction: 0.0,
        effectiveCdA: PhysicsConstants.cdaDrops,
        airDensityKgM3: PhysicsConstants.seaLevelAirDensity,
        effectiveCrr: PhysicsConstants.crrCobblestones,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double speedOverpressured = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: effectivePowerOverpressured,
        totalMassKg: totalMassKg,
        gradientFraction: 0.0,
        effectiveCdA: PhysicsConstants.cdaDrops,
        airDensityKgM3: PhysicsConstants.seaLevelAirDensity,
        effectiveCrr: PhysicsConstants.crrCobblestones,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        maxIterations: 24,
      );

      final double timeAdvantageSec =
          (distanceM / speedOverpressured) - (distanceM / speedOptimal);

      expect(speedOptimal, greaterThan(speedOverpressured));
      expect(timeAdvantageSec, greaterThan(45.0));
    });
  });

  group('3. Test Skiba W\', Glikogenu i Wysokości n.p.m.', () {
    const gcRiderPhysiology = RiderPhysiology(
      heightCm: 175.0,
      weightKg: 64.0,
      bodyFatPercentage: 5.5,
      ftpWatts: 380,
      wPrimeJoules: 20000,
      vo2Max: 83.0,
      maxHr: 195,
      restingHr: 38,
      lactateThresholdHr: 175,
      recoveryRate: 1.10,
      glycogenCapacityGrams: 500.0,
    );

    test('Wyczerpanie W\' podczas ataku (>FTP), odcięcie beztlenowe oraz regeneracja (<FTP)', () {
      var state = WPrimeState.initial(gcRiderPhysiology);
      expect(state.currentWPrimeJoules, equals(20000.0));
      expect(state.isExhausted, isFalse);

      // Faza 1: Atak 580 W (nadwyżka +200 W ponad FTP 380 W) przez dokładnie 100 s -> 20 000 J
      WPrimeUpdateResult? lastAttackResult;
      for (int s = 0; s < 100; s++) {
        lastAttackResult = WPrimeBalanceEngine.update(
          state: state,
          targetPowerWatts: 580.0,
          physiology: gcRiderPhysiology,
          timeStepSeconds: 1.0,
        );
        state = lastAttackResult.newState;
      }

      expect(state.currentWPrimeJoules, equals(0.0));
      expect(state.isExhausted, isTrue);
      expect(state.exhaustionCount, equals(1));
      expect(lastAttackResult!.wasPowerCapped, isTrue);
      // W stanie odcięcia moc jest cięta do 85% FTP = 323 W
      expect(
        lastAttackResult.actualPowerWatts,
        closeTo(gcRiderPhysiology.ftpWatts * WPrimeBalanceEngine.exhaustionPowerCapRatio, 0.01),
      );

      // Faza 2: Regeneracja poniżej progu (200 W < 380 W) przez 120 sekund
      WPrimeUpdateResult? recoveryResult;
      for (int s = 0; s < 120; s++) {
        recoveryResult = WPrimeBalanceEngine.update(
          state: state,
          targetPowerWatts: 200.0,
          physiology: gcRiderPhysiology,
          timeStepSeconds: 1.0,
        );
        state = recoveryResult.newState;
      }

      expect(recoveryResult!.tauSeconds, isNotNull);
      expect(recoveryResult.tauSeconds!, inInclusiveRange(160.0, 1200.0));
      expect(state.currentWPrimeJoules, greaterThan(2000.0)); // >10% W'_max
      expect(state.isExhausted, isFalse);
    });

    test('Spadek mocy na wysokości 2500 m n.p.m. oraz redukcja straty przez aklimatyzację', () {
      final seaLevel = AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 100.0,
        baseFtpWatts: 380.0,
        altitudeAcclimatizationScore: 0.0,
      );

      final unacclimatized2500m = AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 2500.0,
        baseFtpWatts: 380.0,
        altitudeAcclimatizationScore: 0.0,
        nationalityIso: 'POL',
      );

      final acclimatized2500m = AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 2500.0,
        baseFtpWatts: 380.0,
        altitudeAcclimatizationScore: 100.0,
        nationalityIso: 'POL',
      );

      final colombian2500m = AltitudeAcclimatizationAndHeatEngine.evaluateAltitudeEffect(
        altitudeMeters: 2500.0,
        baseFtpWatts: 380.0,
        altitudeAcclimatizationScore: 0.0,
        nationalityIso: 'COL',
      );

      // Poniżej 1500m brak spadku FTP
      expect(seaLevel.ftpMultiplier, equals(1.0));
      expect(seaLevel.effectiveFtpWatts, equals(380.0));

      // Na 2500m (1000m ponad 1500m): (1000/300) * 1.5% = 5.0% straty
      expect(unacclimatized2500m.ftpMultiplier, closeTo(0.95, 1e-6));
      expect(unacclimatized2500m.effectiveFtpWatts, closeTo(380.0 * 0.95, 0.01));
      expect(unacclimatized2500m.airDensityKgM3, lessThan(seaLevel.airDensityKgM3));

      // Pełna aklimatyzacja lub pochodzenie wysokogórskie (COL) redukuje stratę o 50% (do 2.5%)
      expect(acclimatized2500m.ftpMultiplier, closeTo(0.975, 1e-6));
      expect(colombian2500m.ftpMultiplier, closeTo(0.975, 1e-6));
      expect(acclimatized2500m.effectiveFtpWatts, greaterThan(unacclimatized2500m.effectiveFtpWatts));
    });

    test('Wyczerpanie glikogenu (bonk) i regeneracja po podaniu żelu energetycznego', () {
      // Rozpoczynamy z niskim poziomem glikogenu (70 g, pusty żołądek), aby przetestować przejście w bonk i powrót
      var state = const NutritionState(
        currentGlycogenGrams: 70.0,
        maxGlycogenGrams: 500.0,
        hydrationPercent: 95.0,
        stomachCarbsGrams: 0.0,
        stomachFluidMl: 100.0,
      );

      // Wysiłek na progu 380 W przez 10 minut (600 s) -> spadek poniżej 50 g i wejście w bonk
      for (int s = 0; s < 600; s++) {
        final step = NutritionAndGlycogenEngine.update(
          state: state,
          currentPowerWatts: 380.0,
          physiology: gcRiderPhysiology,
          timeStepSeconds: 1.0,
        );
        state = step.newState;
      }

      expect(state.currentGlycogenGrams, lessThan(NutritionAndGlycogenEngine.bonkThresholdGrams));
      expect(state.isBonking, isTrue);
      expect(state.effectiveFtpMultiplier, closeTo(0.65, 1e-6));

      // Podanie 3 żeli energetycznych (+90 g węglowodanów do żołądka)
      state = NutritionAndGlycogenEngine.consumeGel(state);
      state = NutritionAndGlycogenEngine.consumeGel(state);
      state = NutritionAndGlycogenEngine.consumeGel(state);
      expect(state.stomachCarbsGrams, closeTo(90.0, 1e-6));

      final double glycogenBeforeAbsorption = state.currentGlycogenGrams;

      // Zjazd / jazda bez pedałowania (0 W) przez 60 minut (3600 s),
      // gdzie wchłanianie jelitowe (100 g/h) wyraźnie przewyższa metabolizm spoczynkowy (~15 g/h)
      for (int s = 0; s < 3600; s++) {
        final step = NutritionAndGlycogenEngine.update(
          state: state,
          currentPowerWatts: 0.0,
          physiology: gcRiderPhysiology,
          timeStepSeconds: 1.0,
        );
        state = step.newState;
      }

      expect(state.currentGlycogenGrams, greaterThan(glycogenBeforeAbsorption));
      expect(state.currentGlycogenGrams, greaterThanOrEqualTo(NutritionAndGlycogenEngine.bonkExitThresholdGrams));
      expect(state.isBonking, isFalse);
      expect(state.effectiveFtpMultiplier, equals(1.0));
    });
  });
}
