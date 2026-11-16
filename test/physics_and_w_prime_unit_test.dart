import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/physics/aero_calculator.dart';
import 'package:pro_peloton_manager/engine/physics/gravity_and_rolling_calculator.dart';
import 'package:pro_peloton_manager/engine/physics/speed_solver.dart';
import 'package:pro_peloton_manager/engine/physics/w_prime_balance_engine.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';

void main() {
  const RiderPhysiology testRider = RiderPhysiology(
    heightCm: 180.0,
    weightKg: 70.0,
    bodyFatPercentage: 7.5,
    ftpWatts: 380,
    wPrimeJoules: 20000,
    vo2Max: 78.0,
    maxHr: 194,
    restingHr: 42,
    lactateThresholdHr: 175,
    recoveryRate: 1.15,
    glycogenCapacityGrams: 550.0,
  );

  group('1. Dokładność matematyczna składowych mocy (P_gravity + P_rolling + P_aero)', () {
    test('P_gravity = m * g * sin(arctan(gradient)) * v zgadza się ze wzorem analitycznym', () {
      const double massKg = 78.0; // 70 kg kolarz + 7 kg rower + 1 kg bidony
      const double speedMs = 6.5;
      const double gradient = 0.085; // 8.5%

      final double expectedTheta = math.atan(gradient);
      final double expectedPGrav =
          massKg * PhysicsConstants.gravity * math.sin(expectedTheta) * speedMs;

      final double actualPGrav = GravityAndRollingCalculator.calculateGravityWatts(
        totalMassKg: massKg,
        speedMs: speedMs,
        gradientFraction: gradient,
      );

      expect(actualPGrav, closeTo(expectedPGrav, 1e-9));

      // Na zjeździe (-6%) moc grawitacji jest ujemna i symetryczna co do modułu
      final double descentPGrav = GravityAndRollingCalculator.calculateGravityWatts(
        totalMassKg: massKg,
        speedMs: speedMs,
        gradientPercent: -6.0,
      );
      final double climbPGrav = GravityAndRollingCalculator.calculateGravityWatts(
        totalMassKg: massKg,
        speedMs: speedMs,
        gradientPercent: 6.0,
      );
      expect(descentPGrav, lessThan(0.0));
      expect(descentPGrav, closeTo(-climbPGrav, 1e-9));

      // Zerowa prędkość lub masa daje 0 W
      expect(
        GravityAndRollingCalculator.calculateGravityWatts(
          totalMassKg: massKg,
          speedMs: 0.0,
          gradientFraction: gradient,
        ),
        equals(0.0),
      );
    });

    test('P_rolling = m * g * cos(arctan(gradient)) * Crr * v zgadza się ze wzorem analitycznym', () {
      const double massKg = 78.0;
      const double speedMs = 11.0;
      const double gradient = 0.05;
      const double crr = PhysicsConstants.crrSmoothAsphalt;

      final double expectedTheta = math.atan(gradient);
      final double expectedPRoll =
          massKg * PhysicsConstants.gravity * math.cos(expectedTheta) * crr * speedMs;

      final double actualPRoll = GravityAndRollingCalculator.calculateRollingResistanceWatts(
        totalMassKg: massKg,
        speedMs: speedMs,
        crr: crr,
        gradientFraction: gradient,
      );

      expect(actualPRoll, closeTo(expectedPRoll, 1e-9));
      expect(actualPRoll, greaterThan(0.0));
    });

    test('P_aero = 0.5 * rho * CdA_eff * v_app * v_ax * v_rider dla braku wiatru i wiatru czołowego/tylnego', () {
      const double speedMs = 12.0; // 43.2 km/h
      const double altitudeM = 0.0;
      const double tempC = 15.0;
      const double frontalArea = AeroCalculator.referenceFrontalAreaM2;

      final double rho = AeroCalculator.calculateAirDensity(
        altitudeMeters: altitudeM,
        temperatureCelsius: tempC,
      );

      // Brak wiatru: v_app = v_ax = v_rider -> P_aero = 0.5 * rho * CdA * v^3
      final AeroCalculationResult noWind = AeroCalculator.calculateDetailed(
        altitudeMeters: altitudeM,
        temperatureCelsius: tempC,
        riderFrontalAreaM2: frontalArea,
        riderPosition: RiderPosition.drops,
        riderSpeedMs: speedMs,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
      );
      final double expectedNoWindAero =
          0.5 * rho * PhysicsConstants.cdaDrops * math.pow(speedMs, 3);
      expect(noWind.aeroPowerWatts, closeTo(expectedNoWindAero, 1e-6));

      // Wiatr czołowy 5 m/s (0 deg): v_ax = v_rider + 5, v_app = v_ax
      const double headwindMs = 5.0;
      final AeroCalculationResult headwind = AeroCalculator.calculateDetailed(
        altitudeMeters: altitudeM,
        temperatureCelsius: tempC,
        riderFrontalAreaM2: frontalArea,
        riderPosition: RiderPosition.drops,
        riderSpeedMs: speedMs,
        windSpeedMs: headwindMs,
        relativeWindAngleDegrees: 0.0,
      );
      const double vAxHead = speedMs + headwindMs;
      final double expectedHeadAero =
          0.5 * rho * PhysicsConstants.cdaDrops * vAxHead * vAxHead * speedMs;
      expect(headwind.aeroPowerWatts, closeTo(expectedHeadAero, 1e-6));
      expect(headwind.aeroPowerWatts, greaterThan(noWind.aeroPowerWatts));

      // Silny wiatr w plecy 15 m/s (180 deg) przy prędkości 12 m/s -> wspomaganie (P_aero < 0)
      final AeroCalculationResult strongTailwind = AeroCalculator.calculateDetailed(
        altitudeMeters: altitudeM,
        temperatureCelsius: tempC,
        riderFrontalAreaM2: frontalArea,
        riderPosition: RiderPosition.drops,
        riderSpeedMs: speedMs,
        windSpeedMs: 15.0,
        relativeWindAngleDegrees: 180.0,
      );
      expect(strongTailwind.isAssistingTailwind, isTrue);
      expect(strongTailwind.aeroPowerWatts, lessThan(0.0));
    });

    test('Bilans mocy na drodze i sprawność napędu: P_legs = (P_grav + P_roll + P_aero) / (1 - loss)', () {
      const double massKg = 76.0;
      const double speedMs = 9.5;
      const double gradientPercent = 4.0;
      const double crr = PhysicsConstants.crrStandardAsphalt;
      const double aeroW = 145.0;
      const double loss = PhysicsConstants.drivetrainLossWaxed;

      final PowerBreakdownResult breakdown = GravityAndRollingCalculator.calculateDetailed(
        totalMassKg: massKg,
        speedMs: speedMs,
        gradientPercent: gradientPercent,
        crr: crr,
        aeroWatts: aeroW,
        drivetrainLoss: loss,
      );

      final double expectedRoadPower =
          breakdown.gravityWatts + breakdown.rollingResistanceWatts + aeroW;
      expect(breakdown.roadPowerWatts, closeTo(expectedRoadPower, 1e-9));
      expect(breakdown.totalLegPowerWatts, closeTo(expectedRoadPower / (1.0 - loss), 1e-9));
      expect(
        breakdown.drivetrainLossWatts,
        closeTo(breakdown.totalLegPowerWatts - expectedRoadPower, 1e-9),
      );

      // Na stromym zjeździe (P_road <= 0) wymagana moc z nóg = 0.0 W (coasting)
      final double coastingPower = GravityAndRollingCalculator.combineWithDrivetrainLoss(
        gravityWatts: -400.0,
        rollingResistanceWatts: 25.0,
        aeroWatts: 200.0,
        drivetrainLoss: loss,
      );
      expect(coastingPower, equals(0.0));
    });
  });

  group('2. Dokładność matematyczna SpeedSolvera (F*v = P_grav + P_roll + P_aero)', () {
    test('Siły oporu * prędkość są identyczne z mocami P_gravity, P_rolling i P_aero', () {
      const double speedMs = 10.5;
      const double massKg = 78.0;
      const double gradient = 0.06;
      const double crr = PhysicsConstants.crrStandardAsphalt;
      const double rho = 1.18;
      const double cda = PhysicsConstants.cdaHoods;
      const double windMs = 3.0;
      const double windAngleDeg = 45.0;

      final forces = SpeedSolver.calculateResistanceForces(
        speedMs: speedMs,
        totalMassKg: massKg,
        gradientFraction: gradient,
        effectiveCdA: cda,
        airDensityKgM3: rho,
        effectiveCrr: crr,
        windSpeedMs: windMs,
        relativeWindAngleDegrees: windAngleDeg,
      );

      final double pGrav = GravityAndRollingCalculator.calculateGravityWatts(
        totalMassKg: massKg,
        speedMs: speedMs,
        gradientFraction: gradient,
      );
      final double pRoll = GravityAndRollingCalculator.calculateRollingResistanceWatts(
        totalMassKg: massKg,
        speedMs: speedMs,
        crr: crr,
        gradientFraction: gradient,
      );

      const double betaRad = windAngleDeg * (math.pi / 180.0);
      final double vAx = speedMs + windMs * math.cos(betaRad);
      final double vAy = windMs * math.sin(betaRad);
      final double vApp = math.sqrt(vAx * vAx + vAy * vAy);
      final double pAeroExpected = 0.5 * rho * cda * vApp * vAx * speedMs;

      expect(forces.gravityForce * speedMs, closeTo(pGrav, 1e-9));
      expect(forces.rollingForce * speedMs, closeTo(pRoll, 1e-9));
      expect(forces.aeroForce * speedMs, closeTo(pAeroExpected, 1e-9));
      expect(
        forces.totalResistanceForce * speedMs,
        closeTo(pGrav + pRoll + pAeroExpected, 1e-9),
      );
    });

    test('W prędkości równowagowej (solveEquilibriumSpeed) P_wheel == P_gravity + P_rolling + P_aero', () {
      const double inputWatts = 360.0;
      const double massKg = 75.0;
      const double gradient = 0.03;
      const double cda = 0.295;
      const double rho = PhysicsConstants.seaLevelAirDensity;
      const double crr = PhysicsConstants.crrSmoothAsphalt;
      const double loss = PhysicsConstants.drivetrainLossStandard;

      final double vEq = SpeedSolver.solveEquilibriumSpeed(
        inputWatts: inputWatts,
        totalMassKg: massKg,
        gradientFraction: gradient,
        effectiveCdA: cda,
        airDensityKgM3: rho,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        drivetrainLoss: loss,
        maxIterations: 28,
      );

      final forces = SpeedSolver.calculateResistanceForces(
        speedMs: vEq,
        totalMassKg: massKg,
        gradientFraction: gradient,
        effectiveCdA: cda,
        airDensityKgM3: rho,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
      );

      const double pWheel = inputWatts * (1.0 - loss);
      final double pResist =
          (forces.gravityForce + forces.rollingForce + forces.aeroForce) * vEq;

      expect(pResist, closeTo(pWheel, 0.01));

      // Krok solveNextSecond w punkcie równowagi utrzymuje prędkość (a ~ 0)
      final SpeedSolverResult steadyStep = SpeedSolver.solveNextSecond(
        inputWatts: inputWatts,
        currentSpeedMs: vEq,
        totalMassKg: massKg,
        gradientFraction: gradient,
        effectiveCdA: cda,
        airDensityKgM3: rho,
        effectiveCrr: crr,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        drivetrainLoss: loss,
      );
      expect(steadyStep.newSpeedMs, closeTo(vEq, 0.01));
      expect(steadyStep.accelerationMs2.abs(), lessThan(0.01));
    });

    test('Zjazd z limitem umiejętności (descendingSkill) aktywuje hamowanie i nie przekracza maxSafeSpeed', () {
      const int lowSkill = 25;
      const int highSkill = 95;
      const double techDiff = 60.0;
      const double descentGrad = -0.10; // -10%

      final double lowMaxMs = SpeedSolver.calculateMaxDescentSpeedMs(
        descendingSkill: lowSkill,
        technicalDifficulty: techDiff,
        roadGradientPercent: -10.0,
      );
      final double highMaxMs = SpeedSolver.calculateMaxDescentSpeedMs(
        descendingSkill: highSkill,
        technicalDifficulty: techDiff,
        roadGradientPercent: -10.0,
      );
      expect(highMaxMs, greaterThan(lowMaxMs));

      // Kolarz o niskim skillu startuje już powyżej swojego limitu na stromym zjeździe
      final SpeedSolverResult cappedResult = SpeedSolver.solveNextSecond(
        inputWatts: 100.0,
        currentSpeedMs: lowMaxMs + 4.0,
        totalMassKg: 78.0,
        gradientFraction: descentGrad,
        effectiveCdA: PhysicsConstants.cdaDrops,
        airDensityKgM3: PhysicsConstants.seaLevelAirDensity,
        effectiveCrr: PhysicsConstants.crrSmoothAsphalt,
        windSpeedMs: 0.0,
        relativeWindAngleDegrees: 0.0,
        descendingSkill: lowSkill,
        technicalDifficulty: techDiff,
      );

      expect(cappedResult.isDescentLimited, isTrue);
      expect(cappedResult.brakingForceNewtons, greaterThan(0.0));
      expect(cappedResult.newSpeedMs, closeTo(lowMaxMs, 1e-9));
    });

    test('Ograniczenie siły trakcyjnej przy v = 0 oraz zerowy napęd dla P <= 0', () {
      final double fZeroPower = SpeedSolver.calculatePropulsionForce(
        inputWatts: 0.0,
        currentSpeedMs: 5.0,
      );
      expect(fZeroPower, equals(0.0));

      final double fNearStop = SpeedSolver.calculatePropulsionForce(
        inputWatts: 1200.0,
        currentSpeedMs: 0.0,
      );
      expect(fNearStop, equals(SpeedSolver.maxTractionForceNewtons));
    });
  });

  group('3. Drenaż W\' powyżej CP (P > CP)', () {
    test('Liniowy drenaż W\'(t+dt) = W\'(t) - (P - CP) * dt oraz addytywność w czasie', () {
      final WPrimeState initial = WPrimeState.initial(testRider);
      expect(initial.currentWPrimeJoules, equals(20000.0));

      // CP = 380 W, target = 530 W -> nadwyżka 150 W
      const double attackWatts = 530.0;
      final double excessWatts = attackWatts - testRider.ftpWatts;

      final WPrimeUpdateResult oneStep = WPrimeBalanceEngine.update(
        state: initial,
        targetPowerWatts: attackWatts,
        physiology: testRider,
        timeStepSeconds: 1.0,
      );

      expect(oneStep.deltaWPrimeJoules, closeTo(-excessWatts, 1e-9));
      expect(oneStep.newState.currentWPrimeJoules, closeTo(20000.0 - excessWatts, 1e-9));
      expect(oneStep.tauSeconds, isNull);
      expect(oneStep.wasPowerCapped, isFalse);

      // 10 kroków po 1s daje identyczny wynik jak 1 krok 10s
      WPrimeState stepped = initial;
      for (int i = 0; i < 10; i++) {
        stepped = WPrimeBalanceEngine.update(
          state: stepped,
          targetPowerWatts: attackWatts,
          physiology: testRider,
          timeStepSeconds: 1.0,
        ).newState;
      }

      final WPrimeUpdateResult tenSecSingle = WPrimeBalanceEngine.update(
        state: initial,
        targetPowerWatts: attackWatts,
        physiology: testRider,
        timeStepSeconds: 10.0,
      );

      expect(stepped.currentWPrimeJoules, closeTo(20000.0 - (excessWatts * 10.0), 1e-9));
      expect(
        stepped.currentWPrimeJoules,
        closeTo(tenSecSingle.newState.currentWPrimeJoules, 1e-9),
      );
    });

    test('Moc dokładnie równa CP (P == CP) daje zerową zmianę W\'', () {
      final WPrimeState halfDepleted = WPrimeState.initial(testRider).copyWith(
        currentWPrimeJoules: 10000.0,
      );

      final WPrimeUpdateResult res = WPrimeBalanceEngine.update(
        state: halfDepleted,
        targetPowerWatts: testRider.ftpWatts.toDouble(),
        physiology: testRider,
        timeStepSeconds: 5.0,
      );

      expect(res.deltaWPrimeJoules, equals(0.0));
      expect(res.newState.currentWPrimeJoules, equals(10000.0));
      expect(res.tauSeconds, isNull);
    });

    test('Wyczerpanie W\' do 0 wyzwala odcięcie beztlenowe i redukuje moc do 85% CP', () {
      // Pozostało 300 J; atak +300 W ponad CP przez 2s wyczerpuje W'
      final WPrimeState nearEmpty = WPrimeState.initial(testRider).copyWith(
        currentWPrimeJoules: 300.0,
      );

      final WPrimeUpdateResult blowUp = WPrimeBalanceEngine.update(
        state: nearEmpty,
        targetPowerWatts: testRider.ftpWatts + 300.0,
        physiology: testRider,
        timeStepSeconds: 2.0,
      );

      final double expectedCap =
          testRider.ftpWatts * WPrimeBalanceEngine.exhaustionPowerCapRatio;

      expect(blowUp.newState.currentWPrimeJoules, equals(0.0));
      expect(blowUp.newState.isExhausted, isTrue);
      expect(blowUp.newState.exhaustionCount, equals(1));
      expect(blowUp.wasPowerCapped, isTrue);
      expect(blowUp.actualPowerWatts, closeTo(expectedCap, 1e-9));
      expect(
        WPrimeBalanceEngine.getEffectiveMaxPower(
          state: blowUp.newState,
          physiology: testRider,
        ),
        closeTo(expectedCap, 1e-9),
      );

      // Kolejna próba jazdy powyżej limitu w stanie odcięcia zwiększa timeInExhaustionSeconds
      final WPrimeUpdateResult nextStep = WPrimeBalanceEngine.update(
        state: blowUp.newState,
        targetPowerWatts: 500.0,
        physiology: testRider,
        timeStepSeconds: 3.0,
      );
      expect(nextStep.wasPowerCapped, isTrue);
      expect(nextStep.actualPowerWatts, closeTo(expectedCap, 1e-9));
      expect(nextStep.newState.timeInExhaustionSeconds, closeTo(3.0, 1e-9));
    });
  });

  group('4. Wykładnicza odbudowa W\' poniżej CP (P < CP)', () {
    test('Stała czasowa tau spełnia wzór Skiby i zależy monotonicznie od deficytu oraz VO2max', () {
      const double cp = 380.0;
      const double pRec = 200.0; // deficyt 180 W
      const double vo2 = 78.0;
      const double recRate = 1.15;

      final double tauBase = (546.0 * math.exp(-0.01 * (cp - pRec))) + 316.0;
      final double vo2Factor = math.pow(vo2 / 70.0, 0.75).toDouble();
      final double expectedTau =
          (tauBase / (vo2Factor * recRate)).clamp(160.0, 1200.0);

      final double actualTau = WPrimeBalanceEngine.calculateTauSeconds(
        cpWatts: cp,
        currentPowerWatts: pRec,
        vo2Max: vo2,
        recoveryRate: recRate,
      );

      expect(actualTau, closeTo(expectedTau, 1e-9));

      // Większy deficyt (niższa moc, np. 100W vs 300W) -> mniejsze tau (szybsza regeneracja)
      final double tauDeepRec = WPrimeBalanceEngine.calculateTauSeconds(
        cpWatts: cp,
        currentPowerWatts: 100.0,
        vo2Max: vo2,
        recoveryRate: recRate,
      );
      final double tauLightRec = WPrimeBalanceEngine.calculateTauSeconds(
        cpWatts: cp,
        currentPowerWatts: 340.0,
        vo2Max: vo2,
        recoveryRate: recRate,
      );
      expect(tauDeepRec, lessThan(tauLightRec));
    });

    test('Wykładnicza regeneracja W\'(t+dt) = W\'_max - (W\'_max - W\'(t)) * exp(-dt / tau) oraz niezmienniczość kroku czasowego', () {
      const double initialW = 5000.0;
      const double recoveryWatts = 220.0;
      final WPrimeState depleted = WPrimeState.initial(testRider).copyWith(
        currentWPrimeJoules: initialW,
      );

      final double expectedTau = WPrimeBalanceEngine.calculateTauSeconds(
        cpWatts: testRider.ftpWatts.toDouble(),
        currentPowerWatts: recoveryWatts,
        vo2Max: testRider.vo2Max,
        recoveryRate: testRider.recoveryRate,
      );

      // Jednorazowy krok 60 s
      const double totalDt = 60.0;
      final WPrimeUpdateResult single60s = WPrimeBalanceEngine.update(
        state: depleted,
        targetPowerWatts: recoveryWatts,
        physiology: testRider,
        timeStepSeconds: totalDt,
      );

      final double expectedWAfter60s = 20000.0 -
          (20000.0 - initialW) * math.exp(-totalDt / expectedTau);

      expect(single60s.tauSeconds, closeTo(expectedTau, 1e-9));
      expect(single60s.newState.currentWPrimeJoules, closeTo(expectedWAfter60s, 1e-9));
      expect(single60s.deltaWPrimeJoules, closeTo(expectedWAfter60s - initialW, 1e-9));

      // 60 kroków po 1 s musi dać identyczny wynik (własność półgrupowa zaniku wykładniczego)
      WPrimeState iterated = depleted;
      for (int s = 0; s < 60; s++) {
        iterated = WPrimeBalanceEngine.update(
          state: iterated,
          targetPowerWatts: recoveryWatts,
          physiology: testRider,
          timeStepSeconds: 1.0,
        ).newState;
      }
      expect(iterated.currentWPrimeJoules, closeTo(expectedWAfter60s, 1e-6));

      // Bardzo długi czas regeneracji dąży asymptotycznie do W'_max bez przekroczenia
      final WPrimeUpdateResult longRecovery = WPrimeBalanceEngine.update(
        state: depleted,
        targetPowerWatts: 100.0,
        physiology: testRider,
        timeStepSeconds: 10000.0,
      );
      expect(longRecovery.newState.currentWPrimeJoules, lessThanOrEqualTo(20000.0));
      expect(longRecovery.newState.currentWPrimeJoules, greaterThan(19999.0));
    });

    test('Wyjście ze stanu odcięcia beztlenowego następuje po odbudowie >= 10% W\'_max', () {
      // W'max = 20000 J -> próg wyjścia = 2000 J
      final WPrimeState exhaustedAtZero = WPrimeState.initial(testRider).copyWith(
        currentWPrimeJoules: 0.0,
        isExhausted: true,
        exhaustionCount: 1,
      );

      // Krótka regeneracja (5s przy 180W) daje < 2000 J -> nadal exhausted
      final WPrimeUpdateResult stillExhausted = WPrimeBalanceEngine.update(
        state: exhaustedAtZero,
        targetPowerWatts: 180.0,
        physiology: testRider,
        timeStepSeconds: 5.0,
      );
      expect(stillExhausted.newState.currentWPrimeJoules, lessThan(2000.0));
      expect(stillExhausted.newState.isExhausted, isTrue);

      // Dłuższa regeneracja (60s przy 180W) przekracza 2000 J -> wyjście z odcięcia
      final WPrimeUpdateResult recovered = WPrimeBalanceEngine.update(
        state: stillExhausted.newState,
        targetPowerWatts: 180.0,
        physiology: testRider,
        timeStepSeconds: 60.0,
      );
      expect(recovered.newState.currentWPrimeJoules, greaterThanOrEqualTo(2000.0));
      expect(recovered.newState.isExhausted, isFalse);
    });

    test('Serializacja WPrimeState (toJson/fromJson) i krok dt <= 0', () {
      final WPrimeState state = WPrimeState.initial(testRider).copyWith(
        currentWPrimeJoules: 12345.6,
        isExhausted: false,
        exhaustionCount: 2,
        timeInExhaustionSeconds: 14.5,
        lastTauSeconds: 280.0,
      );

      final WPrimeState restored = WPrimeState.fromJson(state.toJson());
      expect(restored.currentWPrimeJoules, closeTo(12345.6, 1e-9));
      expect(restored.maxWPrimeJoules, equals(20000.0));
      expect(restored.exhaustionCount, equals(2));
      expect(restored.timeInExhaustionSeconds, closeTo(14.5, 1e-9));
      expect(restored.lastTauSeconds, closeTo(280.0, 1e-9));

      final WPrimeUpdateResult zeroDt = WPrimeBalanceEngine.update(
        state: state,
        targetPowerWatts: 600.0,
        physiology: testRider,
        timeStepSeconds: 0.0,
      );
      expect(zeroDt.deltaWPrimeJoules, equals(0.0));
      expect(zeroDt.newState.currentWPrimeJoules, closeTo(12345.6, 1e-9));
    });
  });
}
