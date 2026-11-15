import 'dart:math' as math;
import '../../core/constants/physics_constants.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_skills.dart';
import 'aero_calculator.dart';
import 'gravity_and_rolling_calculator.dart';

/// Szczegółowy wynik rozwiązania kroku dynamiki ruchu kolarza.
class SpeedSolverResult {
  /// Nowa prędkość kolarza w kolejnej sekundzie symulacji [m/s]
  final double newSpeedMs;

  /// Nowa prędkość kolarza przeliczona na km/h
  double get newSpeedKmh => newSpeedMs * 3.6;

  /// Przyspieszenie liniowe kolarza w minionym kroku czasowym [m/s^2]
  final double accelerationMs2;

  /// Siła napędowa przekazywana przez tylne koło na podłoże [N]
  final double propulsionForceNewtons;

  /// Łączna siła oporów ruchu [N] (F_gravity + F_rolling + F_aero)
  final double totalResistanceForceNewtons;

  /// Wypadkowa siła przyspieszająca [N] (F_propulsion - F_resistances - F_braking)
  final double netForceNewtons;

  /// Siła oporu aerodynamicznego [N]
  final double aeroForceNewtons;

  /// Siła grawitacji wzdłuż stoku drogi [N] (>0 hamuje pod górę, <0 napędza w dół)
  final double gravityForceNewtons;

  /// Siła oporów toczenia opon po nawierzchni [N]
  final double rollingForceNewtons;

  /// Siła dohamowania na zjeździe [N] (jeśli zadziałał limit umiejętności technicznych kolarza)
  final double brakingForceNewtons;

  /// Czy prędkość została ograniczona limitem umiejętności zjazdowych ([RiderSkills.descending])
  final bool isDescentLimited;

  /// Teoretyczna prędkość równowagowa / ustabilizowana (terminal velocity) dla zadanej mocy [m/s]
  final double equilibriumSpeedMs;

  /// Prędkość równowagowa w km/h
  double get equilibriumSpeedKmh => equilibriumSpeedMs * 3.6;

  /// Liczba iteracji wykonanych przez solver numeryczny
  final int solverIterations;

  const SpeedSolverResult({
    required this.newSpeedMs,
    required this.accelerationMs2,
    required this.propulsionForceNewtons,
    required this.totalResistanceForceNewtons,
    required this.netForceNewtons,
    required this.aeroForceNewtons,
    required this.gravityForceNewtons,
    required this.rollingForceNewtons,
    required this.brakingForceNewtons,
    required this.isDescentLimited,
    required this.equilibriumSpeedMs,
    required this.solverIterations,
  });

  @override
  String toString() {
    return 'SpeedSolverResult(v: ${newSpeedKmh.toStringAsFixed(1)}km/h (${newSpeedMs.toStringAsFixed(2)}m/s), '
        'a: ${accelerationMs2.toStringAsFixed(3)}m/s², '
        'F_prop: ${propulsionForceNewtons.toStringAsFixed(1)}N, '
        'F_res: ${totalResistanceForceNewtons.toStringAsFixed(1)}N, '
        'brake: ${brakingForceNewtons.toStringAsFixed(1)}N, '
        'descLimit: $isDescentLimited, '
        'vEq: ${equilibriumSpeedKmh.toStringAsFixed(1)}km/h, '
        'iter: $solverIterations)';
  }
}

/// Zaawansowany solver równania ruchu kolarza na szosie.
///
/// Implementuje hybrydowy algorytm Newtona-Raphsona z bisekcją (8 iteracji)
/// do rozwiązywania nieliniowych oporów aerodynamicznych, grawitacyjnych i toczenia:
/// m * a = F_propulsion - (F_gravity + F_rolling + F_aero)
class SpeedSolver {
  SpeedSolver._();

  /// Maksymalna dopuszczalna siła trakcyjna na tylnym kole [N]
  /// Zapobiega asymptotycznej nieskończoności F = P / v przy v bliskim 0 m/s
  static const double maxTractionForceNewtons = 1250.0;

  /// Minimalna prędkość w mianowniku siły napędowej [m/s]
  static const double minSpeedThresholdMs = 0.35;

  /// Oblicza maksymalną bezpieczną prędkość zjazdu [m/s] na podstawie umiejętności kolarza
  /// ([descendingSkill] w skali 1-100) oraz stopnia trudności technicznej drogi.
  ///
  /// - Kolarz wybitny (skill ~95-99, np. Pidcock, Mohorič) osiąga do 98 km/h na łagodnych łukach.
  /// - Kolarz przeciętny (skill ~50) bezpiecznie zjeżdża z limitem ~75 km/h.
  /// - Kolarz słaby technicznie (skill ~20-30) asekuracyjnie dohamowuje do 55-62 km/h.
  static double calculateMaxDescentSpeedMs({
    required int descendingSkill,
    double technicalDifficulty = 35.0,
    double roadGradientPercent = -7.0,
  }) {
    final double skill = descendingSkill.clamp(1, 100).toDouble();

    // Bazowy limit prędkości maksymalnej w km/h w zależności od odwagi i techniki
    final double baseSpeedKmh = 54.0 + (skill * 0.44); // 54.44 do 98.0 km/h

    // Kara za trudność techniczną trasy (ostre zakręty, agrafki, zwężenia)
    final double techFactor = technicalDifficulty.clamp(1.0, 100.0) / 100.0;
    final double skillDeficit = (100.0 - skill) / 100.0;
    final double corneringPenaltyKmh = techFactor * skillDeficit * 24.0;

    final double safeSpeedKmh = math.max(32.0, baseSpeedKmh - corneringPenaltyKmh);
    return safeSpeedKmh / 3.6;
  }

  /// Wylicza siłę napędową kolarza na tylnym kole [N].
  ///
  /// Uwzględnia moc wyjściową nóg [inputWatts], sprawność napędu oraz prędkość kolarza.
  static double calculatePropulsionForce({
    required double inputWatts,
    required double currentSpeedMs,
    double drivetrainLoss = PhysicsConstants.drivetrainLossStandard,
  }) {
    if (inputWatts <= 0.0) {
      return 0.0;
    }

    final double clampedLoss = drivetrainLoss.clamp(0.0, 0.20);
    final double efficiency = 1.0 - clampedLoss;
    final double wheelPowerWatts = inputWatts * efficiency;

    final double effectiveSpeed = math.max(minSpeedThresholdMs, currentSpeedMs);
    final double rawForce = wheelPowerWatts / effectiveSpeed;

    return rawForce.clamp(0.0, maxTractionForceNewtons);
  }

  /// Wylicza składowe sił oporu ruchu (grawitacja, toczenie, aerodynamika) dla danej prędkości [v].
  static ({
    double gravityForce,
    double rollingForce,
    double aeroForce,
    double totalResistanceForce,
  }) calculateResistanceForces({
    required double speedMs,
    required double totalMassKg,
    required double gradientFraction,
    required double effectiveCdA,
    required double airDensityKgM3,
    required double effectiveCrr,
    required double windSpeedMs,
    required double relativeWindAngleDegrees,
  }) {
    // 1. Siła grawitacji: F_grav = m * g * sin(arctan(gradient))
    final double slopeAngleRad = math.atan(gradientFraction);
    final double sinSlope = math.sin(slopeAngleRad);
    final double cosSlope = math.cos(slopeAngleRad);

    final double gravityForce = totalMassKg * PhysicsConstants.gravity * sinSlope;

    // 2. Siła oporów toczenia: F_roll = m * g * cos(arctan(gradient)) * Crr
    final double normalForce = totalMassKg * PhysicsConstants.gravity * cosSlope;
    final double rollingForce = speedMs > 0.0 ? normalForce * effectiveCrr : 0.0;

    // 3. Siła oporu aerodynamicznego: F_aero = 0.5 * rho * CdA * v_app * v_ax
    final double betaRad = relativeWindAngleDegrees * (math.pi / 180.0);
    final double vAx = speedMs + (windSpeedMs * math.cos(betaRad));
    final double vAy = windSpeedMs * math.sin(betaRad);
    final double vApp = math.sqrt((vAx * vAx) + (vAy * vAy));

    final double aeroForce = speedMs > 0.0
        ? 0.5 * airDensityKgM3 * effectiveCdA * vApp * vAx
        : 0.0;

    final double totalResistance = gravityForce + rollingForce + aeroForce;

    return (
      gravityForce: gravityForce,
      rollingForce: rollingForce,
      aeroForce: aeroForce,
      totalResistanceForce: totalResistance,
    );
  }

  /// Wyznacza teoretyczną prędkość równowagową (equilibrium / terminal speed) [m/s],
  /// przy której siła napędu dokładnie równoważy wszystkie opory ruchu (F_net = 0).
  ///
  /// Rozwiązuje równanie: F_propulsion(v) - F_resistances(v) = 0
  /// metodą bisekcji / Newtona-Raphsona w 8 iteracjach.
  static double solveEquilibriumSpeed({
    required double inputWatts,
    required double totalMassKg,
    required double gradientFraction,
    required double effectiveCdA,
    required double airDensityKgM3,
    required double effectiveCrr,
    required double windSpeedMs,
    required double relativeWindAngleDegrees,
    double drivetrainLoss = PhysicsConstants.drivetrainLossStandard,
    int maxIterations = 8,
  }) {
    double low = 0.0;
    double high = 35.0; // do 126 km/h

    for (int i = 0; i < maxIterations; i++) {
      final double mid = (low + high) / 2.0;
      final double fProp = calculatePropulsionForce(
        inputWatts: inputWatts,
        currentSpeedMs: mid,
        drivetrainLoss: drivetrainLoss,
      );

      final forces = calculateResistanceForces(
        speedMs: mid,
        totalMassKg: totalMassKg,
        gradientFraction: gradientFraction,
        effectiveCdA: effectiveCdA,
        airDensityKgM3: airDensityKgM3,
        effectiveCrr: effectiveCrr,
        windSpeedMs: windSpeedMs,
        relativeWindAngleDegrees: relativeWindAngleDegrees,
      );

      final double fNet = fProp - forces.totalResistanceForce;

      if (fNet > 0.0) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return (low + high) / 2.0;
  }

  /// Główna metoda rozwiązująca równanie ruchu kolarza w kolejnej sekundzie symulacji.
  ///
  /// Wylicza przyspieszenie:
  /// a = (F_propulsion - F_resistances) / m
  /// oraz prędkość końcową w czasie dt:
  /// v_new = v_current + a * dt
  ///
  /// Stosuje hybrydowy algorytm Newtona-Raphsona z bisekcją (8 iteracji)
  /// dla nieliniowego kroku niejawnego, zapewniając bezwzględną stabilność numeryczną.
  /// Na ostrych zjazdach automatycznie nakłada limit prędkości wynikający z umiejętności [descendingSkill].
  ///
  /// Parametry:
  /// - [inputWatts]: moc generowana przez kolarza [W]
  /// - [currentSpeedMs]: aktualna prędkość kolarza [m/s]
  /// - [totalMassKg]: masa całkowita (kolarz + rower + bidony) [kg]
  /// - [gradientFraction]: nachylenie trasy w ułamku (np. 0.08 dla 8%, -0.07 dla zjazdu)
  /// - [gradientPercent]: alternatywnie nachylenie w procentach (np. 8.0)
  /// - [effectiveCdA]: współczynnik CdA po uwzględnieniu pozycji, roweru i draftingu [m^2]
  /// - [airDensityKgM3]: gęstość powietrza ze wzoru barometrycznego [kg/m^3]
  /// - [effectiveCrr]: współczynnik oporów toczenia dla danej opony i nawierzchni
  /// - [windSpeedMs]: prędkość wiatru w [m/s]
  /// - [relativeWindAngleDegrees]: kąt wiatru względem kierunku jazdy (0° = w twarz, 180° = w plecy)
  /// - [descendingSkill]: umiejętności zjazdowe kolarza w skali 1-100
  /// - [technicalDifficulty]: trudność techniczna segmentu (1-100)
  /// - [drivetrainLoss]: ułamek strat napędu (np. 0.028)
  /// - [timeStepSeconds]: krok czasowy symulacji (domyślnie 1.0 sekunda)
  /// - [wheelInertiaKgM2]: moment bezwładności kompletu kół (opcjonalny)
  static SpeedSolverResult solveNextSecond({
    required double inputWatts,
    required double currentSpeedMs,
    required double totalMassKg,
    double? gradientFraction,
    double? gradientPercent,
    required double effectiveCdA,
    required double airDensityKgM3,
    required double effectiveCrr,
    required double windSpeedMs,
    required double relativeWindAngleDegrees,
    int descendingSkill = 70,
    double technicalDifficulty = 30.0,
    double drivetrainLoss = PhysicsConstants.drivetrainLossStandard,
    double timeStepSeconds = 1.0,
    double wheelInertiaKgM2 = 0.08,
  }) {
    final double gFraction = gradientFraction ??
        (gradientPercent != null ? gradientPercent / 100.0 : 0.0);

    // Efektywna masa układu uwzględniająca bezwładność rotacyjną kół:
    // m_eff = m + (2 * I / r^2); dla kół szosowych 700c r ~ 0.335 m -> r^2 ~ 0.112 m^2
    const double wheelRadiusM = 0.335;
    final double rotationalMassKg = (2.0 * wheelInertiaKgM2) / (wheelRadiusM * wheelRadiusM);
    final double effectiveMassKg = totalMassKg + rotationalMassKg;

    // 1. Wyznaczenie sił w punkcie początkowym (t0)
    final double fProp0 = calculatePropulsionForce(
      inputWatts: inputWatts,
      currentSpeedMs: currentSpeedMs,
      drivetrainLoss: drivetrainLoss,
    );

    final forces0 = calculateResistanceForces(
      speedMs: currentSpeedMs,
      totalMassKg: totalMassKg,
      gradientFraction: gFraction,
      effectiveCdA: effectiveCdA,
      airDensityKgM3: airDensityKgM3,
      effectiveCrr: effectiveCrr,
      windSpeedMs: windSpeedMs,
      relativeWindAngleDegrees: relativeWindAngleDegrees,
    );

    final double rawNetForce0 = fProp0 - forces0.totalResistanceForce;
    final double initialAcceleration = rawNetForce0 / effectiveMassKg;

    // 2. Hybrydowy solver Newtona-Raphsona / bisekcji na kroku niejawnym (8 iteracji)
    // R(v) = v - v_curr - dt * a(v) = 0
    double vLow = math.max(0.0, currentSpeedMs - (12.0 * timeStepSeconds));
    double vHigh = currentSpeedMs + (15.0 * timeStepSeconds);
    double vCandidate = math.max(0.0, currentSpeedMs + (initialAcceleration * timeStepSeconds));

    int iterationsUsed = 0;
    const int maxIterations = 8;

    for (int iter = 0; iter < maxIterations; iter++) {
      iterationsUsed++;

      final double fPropCandidate = calculatePropulsionForce(
        inputWatts: inputWatts,
        currentSpeedMs: vCandidate,
        drivetrainLoss: drivetrainLoss,
      );

      final forcesCandidate = calculateResistanceForces(
        speedMs: vCandidate,
        totalMassKg: totalMassKg,
        gradientFraction: gFraction,
        effectiveCdA: effectiveCdA,
        airDensityKgM3: airDensityKgM3,
        effectiveCrr: effectiveCrr,
        windSpeedMs: windSpeedMs,
        relativeWindAngleDegrees: relativeWindAngleDegrees,
      );

      final double aCandidate = (fPropCandidate - forcesCandidate.totalResistanceForce) / effectiveMassKg;
      final double residual = vCandidate - currentSpeedMs - (timeStepSeconds * aCandidate);

      if (residual.abs() < 0.001) {
        break;
      }

      // Aktualizacja przedziału bisekcji
      if (residual > 0.0) {
        vHigh = vCandidate;
      } else {
        vLow = vCandidate;
      }

      // Krok analityczny Newtona: R'(v) = 1 - dt * (da/dv)
      // d(F_prop)/dv ~ -P / v^2; d(F_aero)/dv ~ rho * CdA * v
      final double dFpropDv = vCandidate > minSpeedThresholdMs
          ? -(inputWatts * (1.0 - drivetrainLoss)) / (vCandidate * vCandidate)
          : 0.0;
      final double dFaeroDv = airDensityKgM3 * effectiveCdA * vCandidate;
      final double dFnetDv = dFpropDv - dFaeroDv;
      final double daDv = dFnetDv / effectiveMassKg;
      final double derivative = 1.0 - (timeStepSeconds * daDv);

      double nextStep;
      if (derivative.abs() > 0.1) {
        nextStep = vCandidate - (residual / derivative);
      } else {
        nextStep = (vLow + vHigh) / 2.0;
      }

      // Jeśli krok Newtona wychodzi poza zacieśniony przedział, cofamy się do bisekcji
      if (nextStep < vLow || nextStep > vHigh) {
        vCandidate = (vLow + vHigh) / 2.0;
      } else {
        vCandidate = nextStep;
      }
    }

    double finalSpeedMs = math.max(0.0, vCandidate);

    // 3. Weryfikacja limitu prędkości na ostrych zjazdach (gradient < -1.5%)
    bool isDescentLimited = false;
    double brakingForceNewtons = 0.0;

    if (gFraction < -0.015) {
      final double maxSafeDescentSpeed = calculateMaxDescentSpeedMs(
        descendingSkill: descendingSkill,
        technicalDifficulty: technicalDifficulty,
        roadGradientPercent: gFraction * 100.0,
      );

      if (finalSpeedMs > maxSafeDescentSpeed) {
        isDescentLimited = true;
        final double excessSpeed = finalSpeedMs - maxSafeDescentSpeed;
        brakingForceNewtons = (effectiveMassKg * excessSpeed) / timeStepSeconds;
        finalSpeedMs = maxSafeDescentSpeed;
      }
    }

    // 4. Końcowe przyspieszenie i siły
    final double finalAcceleration = (finalSpeedMs - currentSpeedMs) / timeStepSeconds;

    // Prędkość równowagowa (terminalna)
    final double eqSpeed = solveEquilibriumSpeed(
      inputWatts: inputWatts,
      totalMassKg: totalMassKg,
      gradientFraction: gFraction,
      effectiveCdA: effectiveCdA,
      airDensityKgM3: airDensityKgM3,
      effectiveCrr: effectiveCrr,
      windSpeedMs: windSpeedMs,
      relativeWindAngleDegrees: relativeWindAngleDegrees,
      drivetrainLoss: drivetrainLoss,
    );

    return SpeedSolverResult(
      newSpeedMs: finalSpeedMs,
      accelerationMs2: finalAcceleration,
      propulsionForceNewtons: fProp0,
      totalResistanceForceNewtons: forces0.totalResistanceForce,
      netForceNewtons: (effectiveMassKg * finalAcceleration),
      aeroForceNewtons: forces0.aeroForce,
      gravityForceNewtons: forces0.gravityForce,
      rollingForceNewtons: forces0.rollingForce,
      brakingForceNewtons: brakingForceNewtons,
      isDescentLimited: isDescentLimited,
      equilibriumSpeedMs: eqSpeed,
      solverIterations: iterationsUsed,
    );
  }

  /// Wygodna metoda integrująca pełne modele symulacji:
  /// [RiderPhysiology], [RiderSkills], [CompleteBike] oraz odcinek [StageSegment].
  static SpeedSolverResult solveForSegment({
    required RiderPhysiology physiology,
    required RiderSkills skills,
    required CompleteBike bike,
    required StageSegment segment,
    required double currentSpeedMs,
    required double inputWatts,
    required double temperatureCelsius,
    required double windSpeedKmh,
    RiderPosition position = RiderPosition.hoods,
    double draftingReduction = 0.0,
    double bottlesWeightKg = GravityAndRollingCalculator.defaultBottlesWeightKg,
    double timeStepSeconds = 1.0,
  }) {
    final double totalMass = GravityAndRollingCalculator.calculateTotalMassKg(
      riderWeightKg: physiology.weightKg,
      bikeWeightKg: bike.totalWeightKg,
      bottlesWeightKg: bottlesWeightKg,
    );

    final double airDensity = AeroCalculator.calculateAirDensity(
      altitudeMeters: (segment.startElevationM + segment.endElevationM) / 2.0,
      temperatureCelsius: temperatureCelsius,
    );

    // Kąt wiatru na segmencie
    final double relWindAngle = AeroCalculator.calculateRelativeWindAngle(
      windDirectionDegrees: segment.windDirectionDegrees,
      roadBearingDegrees: segment.roadBearingDegrees,
    );

    // Modyfikator pozycji aerodynamicznej kolarza ze skilla aeroPositioning
    final double skillCdaMod = skills.cdaModifier;
    final double baseCdA = AeroCalculator.calculateEffectiveCdA(
      riderFrontalAreaM2: physiology.frontalAreaM2,
      position: position,
      bike: bike,
      draftingReduction: draftingReduction * skills.draftingBonusMultiplier,
    );
    final double effectiveCdA = baseCdA * skillCdaMod;

    final double effectiveCrr = GravityAndRollingCalculator.calculateEffectiveCrr(
      tire: bike.tire,
      surfaceType: segment.surfaceType,
    );

    final double drivetrainLoss = 1.0 - bike.groupset.mechanicalEfficiency;

    return solveNextSecond(
      inputWatts: inputWatts,
      currentSpeedMs: currentSpeedMs,
      totalMassKg: totalMass,
      gradientPercent: segment.gradientPercent,
      effectiveCdA: effectiveCdA,
      airDensityKgM3: airDensity,
      effectiveCrr: effectiveCrr,
      windSpeedMs: windSpeedKmh / 3.6,
      relativeWindAngleDegrees: relWindAngle,
      descendingSkill: skills.descending,
      technicalDifficulty: segment.technicalDifficulty,
      drivetrainLoss: drivetrainLoss,
      timeStepSeconds: timeStepSeconds,
      wheelInertiaKgM2: bike.wheelset.momentOfInertia,
    );
  }
}

