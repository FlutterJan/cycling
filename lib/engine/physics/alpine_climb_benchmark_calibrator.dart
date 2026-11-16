import 'dart:math' as math;

import '../../models/race/stage_segment.dart';
import 'aero_calculator.dart';
import 'gravity_and_rolling_calculator.dart';
import 'speed_solver.dart';

/// Profil wzorcowego podjazdu alpejskiego oparty na danych historycznych.
class AlpineClimbBenchmarkProfile {
  final String id;
  final String name;
  final String mountainRange;
  final double distanceMeters;
  final double averageGradientPercent;
  final double startElevationM;
  final double summitElevationM;
  final SegmentSurfaceType surfaceType;
  final double technicalDifficulty;

  /// Parametry wzorcowego wspinacza z danych historycznych
  final double referenceRiderWeightKg;
  final double referenceWattsPerKg;

  /// Oczekiwany przedział czasu przejazdu [s] oraz docelowe VAM [m/h]
  final double expectedMinTimeSeconds;
  final double expectedMaxTimeSeconds;
  final double expectedVamMetersPerHour;
  final double vamToleranceMetersPerHour;

  const AlpineClimbBenchmarkProfile({
    required this.id,
    required this.name,
    required this.mountainRange,
    required this.distanceMeters,
    required this.averageGradientPercent,
    required this.startElevationM,
    required this.summitElevationM,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.technicalDifficulty = 40.0,
    required this.referenceRiderWeightKg,
    required this.referenceWattsPerKg,
    required this.expectedMinTimeSeconds,
    required this.expectedMaxTimeSeconds,
    required this.expectedVamMetersPerHour,
    this.vamToleranceMetersPerHour = 45.0,
  });

  /// Przewyższenie podjazdu wynikające z dystansu i średniego nachylenia [m].
  double get nominalElevationGainM =>
      distanceMeters * (averageGradientPercent / 100.0);

  /// Średnia wysokość n.p.m. podjazdu [m].
  double get averageElevationM => (startElevationM + summitElevationM) * 0.5;

  /// Środek oczekiwanego okna czasowego [s].
  double get expectedMidpointTimeSeconds =>
      (expectedMinTimeSeconds + expectedMaxTimeSeconds) * 0.5;
}

/// Skalibrowane parametry fizyki wspinaczki dla solvera [SpeedSolver].
class ClimbCalibrationParameters {
  final double bikeWeightKg;
  final double bottlesAndKitWeightKg;
  final double climbingCdABase;
  final double standingGradientThresholdPercent;
  final double standingCdABoost;
  final double climbingCrr;
  final double drivetrainLoss;
  final double temperatureCelsius;
  final double windSpeedMs;
  final double relativeWindAngleDegrees;
  final double draftingReduction;
  final double timeStepSeconds;

  const ClimbCalibrationParameters({
    this.bikeWeightKg = 6.8,
    this.bottlesAndKitWeightKg = 1.2,
    this.climbingCdABase = 0.332,
    this.standingGradientThresholdPercent = 7.5,
    this.standingCdABoost = 0.018,
    this.climbingCrr = 0.0040,
    this.drivetrainLoss = 0.025,
    this.temperatureCelsius = 20.0,
    this.windSpeedMs = 0.0,
    this.relativeWindAngleDegrees = 0.0,
    this.draftingReduction = 0.0,
    this.timeStepSeconds = 1.0,
  });

  /// Domyślny zestaw parametrów skalibrowany na alpejskich podjazdach HC.
  const ClimbCalibrationParameters.calibrated() : this();

  ClimbCalibrationParameters copyWith({
    double? bikeWeightKg,
    double? bottlesAndKitWeightKg,
    double? climbingCdABase,
    double? standingGradientThresholdPercent,
    double? standingCdABoost,
    double? climbingCrr,
    double? drivetrainLoss,
    double? temperatureCelsius,
    double? windSpeedMs,
    double? relativeWindAngleDegrees,
    double? draftingReduction,
    double? timeStepSeconds,
  }) {
    return ClimbCalibrationParameters(
      bikeWeightKg: bikeWeightKg ?? this.bikeWeightKg,
      bottlesAndKitWeightKg:
          bottlesAndKitWeightKg ?? this.bottlesAndKitWeightKg,
      climbingCdABase: climbingCdABase ?? this.climbingCdABase,
      standingGradientThresholdPercent: standingGradientThresholdPercent ??
          this.standingGradientThresholdPercent,
      standingCdABoost: standingCdABoost ?? this.standingCdABoost,
      climbingCrr: climbingCrr ?? this.climbingCrr,
      drivetrainLoss: drivetrainLoss ?? this.drivetrainLoss,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      relativeWindAngleDegrees:
          relativeWindAngleDegrees ?? this.relativeWindAngleDegrees,
      draftingReduction: draftingReduction ?? this.draftingReduction,
      timeStepSeconds: timeStepSeconds ?? this.timeStepSeconds,
    );
  }
}

/// Wynik symulacji wspinaczki i weryfikacji kalibracji względem benchmarku.
class ClimbSimulationBenchmarkResult {
  final AlpineClimbBenchmarkProfile profile;
  final ClimbCalibrationParameters parameters;
  final double riderWeightKg;
  final double wattsPerKg;
  final double inputWatts;
  final double totalMassKg;
  final double elapsedTimeSeconds;
  final double averageSpeedMs;
  final double equilibriumSpeedMs;
  final double vamMetersPerHour;
  final double elevationGainMeters;
  final double averageAirDensityKgM3;
  final double effectiveCdA;
  final double effectiveCrr;
  final double gravityWatts;
  final double rollingWatts;
  final double aeroWatts;
  final double drivetrainLossWatts;
  final int simulationSteps;

  const ClimbSimulationBenchmarkResult({
    required this.profile,
    required this.parameters,
    required this.riderWeightKg,
    required this.wattsPerKg,
    required this.inputWatts,
    required this.totalMassKg,
    required this.elapsedTimeSeconds,
    required this.averageSpeedMs,
    required this.equilibriumSpeedMs,
    required this.vamMetersPerHour,
    required this.elevationGainMeters,
    required this.averageAirDensityKgM3,
    required this.effectiveCdA,
    required this.effectiveCrr,
    required this.gravityWatts,
    required this.rollingWatts,
    required this.aeroWatts,
    required this.drivetrainLossWatts,
    required this.simulationSteps,
  });

  double get averageSpeedKmh => averageSpeedMs * 3.6;
  double get equilibriumSpeedKmh => equilibriumSpeedMs * 3.6;

  String get formattedTime =>
      AlpineClimbBenchmarkCalibrator.formatClimbTime(elapsedTimeSeconds);

  bool get isWithinTimeWindow =>
      elapsedTimeSeconds >= profile.expectedMinTimeSeconds &&
      elapsedTimeSeconds <= profile.expectedMaxTimeSeconds;

  bool get isWithinVamTolerance =>
      (vamMetersPerHour - profile.expectedVamMetersPerHour).abs() <=
      profile.vamToleranceMetersPerHour;

  bool get isCalibratedPass => isWithinTimeWindow && isWithinVamTolerance;

  double get timeDeltaFromMidpointSeconds =>
      elapsedTimeSeconds - profile.expectedMidpointTimeSeconds;

  double get vamDeltaFromTarget =>
      vamMetersPerHour - profile.expectedVamMetersPerHour;
}

/// Zbiorczy raport kalibracji solvera wspinaczki dla zestawu podjazdów.
class ClimbCalibrationReport {
  final ClimbCalibrationParameters calibratedParameters;
  final List<ClimbSimulationBenchmarkResult> results;
  final int calibrationIterations;

  const ClimbCalibrationReport({
    required this.calibratedParameters,
    required this.results,
    required this.calibrationIterations,
  });

  ClimbSimulationBenchmarkResult? get alpeDHuezResult {
    for (final result in results) {
      if (result.profile.id == AlpineClimbBenchmarkCalibrator.alpeDHuezId) {
        return result;
      }
    }
    return null;
  }

  bool get allPassed =>
      results.isNotEmpty && results.every((result) => result.isCalibratedPass);
}

/// Kalibrator solvera fizyki wspinaczki ([SpeedSolver]) na danych z prawdziwych podjazdów.
///
/// Weryfikuje i dostraja parametry oporów (CdA w pozycji wspinaczkowej, Crr asfaltu górskiego,
/// masę zestawu oraz straty napędu) tak, aby wspinacz 60 kg przy 6.4 W/kg na Alpe d'Huez
/// (13.8 km, 8.1%) osiągał czas 38:30–39:45 oraz VAM ≈ 1750 m/h.
class AlpineClimbBenchmarkCalibrator {
  AlpineClimbBenchmarkCalibrator._();

  static const String alpeDHuezId = 'alpe_dhuez';

  /// Wzorcowy podjazd Alpe d'Huez (13.8 km, 8.1%, Bourg d'Oisans -> Alpe d'Huez).
  static const AlpineClimbBenchmarkProfile alpeDHuez =
      AlpineClimbBenchmarkProfile(
    id: alpeDHuezId,
    name: "Alpe d'Huez",
    mountainRange: 'Alpy Francuskie',
    distanceMeters: 13800.0,
    averageGradientPercent: 8.1,
    startElevationM: 720.0,
    summitElevationM: 1838.0,
    surfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 45.0,
    referenceRiderWeightKg: 60.0,
    referenceWattsPerKg: 6.4,
    expectedMinTimeSeconds: 2310.0, // 38:30
    expectedMaxTimeSeconds: 2385.0, // 39:45
    expectedVamMetersPerHour: 1750.0,
    vamToleranceMetersPerHour: 40.0,
  );

  /// Mont Ventoux z Bédoin (21.5 km, 7.5%).
  static const AlpineClimbBenchmarkProfile montVentouxBedoin =
      AlpineClimbBenchmarkProfile(
    id: 'mont_ventoux_bedoin',
    name: 'Mont Ventoux (Bédoin)',
    mountainRange: 'Prowansja',
    distanceMeters: 21500.0,
    averageGradientPercent: 7.5,
    startElevationM: 300.0,
    summitElevationM: 1912.0,
    surfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 35.0,
    referenceRiderWeightKg: 60.0,
    referenceWattsPerKg: 6.1,
    expectedMinTimeSeconds: 3480.0, // 58:00
    expectedMaxTimeSeconds: 3690.0, // 61:30
    expectedVamMetersPerHour: 1620.0,
    vamToleranceMetersPerHour: 60.0,
  );

  /// Col du Tourmalet z Luz-Saint-Sauveur (19.0 km, 7.4%).
  static const AlpineClimbBenchmarkProfile colDuTourmalet =
      AlpineClimbBenchmarkProfile(
    id: 'col_du_tourmalet',
    name: 'Col du Tourmalet',
    mountainRange: 'Pireneje',
    distanceMeters: 19000.0,
    averageGradientPercent: 7.4,
    startElevationM: 710.0,
    summitElevationM: 2115.0,
    surfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 38.0,
    referenceRiderWeightKg: 60.0,
    referenceWattsPerKg: 6.15,
    expectedMinTimeSeconds: 3030.0, // 50:30
    expectedMaxTimeSeconds: 3210.0, // 53:30
    expectedVamMetersPerHour: 1625.0,
    vamToleranceMetersPerHour: 60.0,
  );

  /// Passo dello Stelvio z Prato allo Stelvio (24.3 km, 7.4%).
  static const AlpineClimbBenchmarkProfile passoDelloStelvio =
      AlpineClimbBenchmarkProfile(
    id: 'passo_dello_stelvio',
    name: 'Passo dello Stelvio',
    mountainRange: 'Alpy Retyckie',
    distanceMeters: 24300.0,
    averageGradientPercent: 7.4,
    startElevationM: 950.0,
    summitElevationM: 2758.0,
    surfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 58.0,
    referenceRiderWeightKg: 60.0,
    referenceWattsPerKg: 6.0,
    expectedMinTimeSeconds: 3960.0, // 66:00
    expectedMaxTimeSeconds: 4230.0, // 70:30
    expectedVamMetersPerHour: 1580.0,
    vamToleranceMetersPerHour: 65.0,
  );

  /// Alto de l'Angliru (12.5 km, 10.1%).
  static const AlpineClimbBenchmarkProfile altoDeLAngliru =
      AlpineClimbBenchmarkProfile(
    id: 'alto_de_l_angliru',
    name: "Alto de l'Angliru",
    mountainRange: 'Asturia',
    distanceMeters: 12500.0,
    averageGradientPercent: 10.1,
    startElevationM: 310.0,
    summitElevationM: 1572.0,
    surfaceType: SegmentSurfaceType.roughAsphalt,
    technicalDifficulty: 65.0,
    referenceRiderWeightKg: 60.0,
    referenceWattsPerKg: 6.3,
    expectedMinTimeSeconds: 2520.0, // 42:00
    expectedMaxTimeSeconds: 2700.0, // 45:00
    expectedVamMetersPerHour: 1745.0,
    vamToleranceMetersPerHour: 65.0,
  );

  static const List<AlpineClimbBenchmarkProfile> allBenchmarks = [
    alpeDHuez,
    montVentouxBedoin,
    colDuTourmalet,
    passoDelloStelvio,
    altoDeLAngliru,
  ];

  /// Wylicza efektywne CdA wspinaczkowe z uwzględnieniem skali masy/powierzchni czołowej
  /// oraz udziału jazdy na stojąco na stromych nachyleniach.
  static double calculateClimbingEffectiveCdA({
    required double riderWeightKg,
    required double gradientPercent,
    required ClimbCalibrationParameters parameters,
  }) {
    final double weightScale = math.pow(
      math.max(40.0, riderWeightKg) / 60.0,
      0.35,
    ).toDouble();

    final double steepnessExcess = math.max(
      0.0,
      gradientPercent - parameters.standingGradientThresholdPercent,
    );
    final double standingBoost = math.min(
      parameters.standingCdABoost * 2.0,
      steepnessExcess * (parameters.standingCdABoost / 2.5),
    );

    final double baseCdA =
        (parameters.climbingCdABase * weightScale) + standingBoost;
    final double draftingMultiplier =
        1.0 - parameters.draftingReduction.clamp(0.0, 0.48);

    return math.max(
      AeroCalculator.minAllowedCdA,
      baseCdA * draftingMultiplier,
    );
  }

  /// Wylicza efektywny współczynnik oporów toczenia Crr dla nawierzchni podjazdu.
  static double calculateClimbingEffectiveCrr({
    required SegmentSurfaceType surfaceType,
    required ClimbCalibrationParameters parameters,
  }) {
    final double surfaceScale;
    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        surfaceScale = 1.0;
        break;
      case SegmentSurfaceType.concrete:
        surfaceScale = 1.18;
        break;
      case SegmentSurfaceType.roughAsphalt:
        surfaceScale = 1.25;
        break;
      case SegmentSurfaceType.gravelStrade:
        surfaceScale = 2.10;
        break;
      default:
        surfaceScale = 2.40;
        break;
    }
    return (parameters.climbingCrr * surfaceScale).clamp(0.0025, 0.0350);
  }

  /// Symuluje przejazd podjazdu krok po kroku przez [SpeedSolver.solveNextSecond]
  /// i zwraca pełne metryki czasu, prędkości, VAM oraz bilansu mocy.
  static ClimbSimulationBenchmarkResult simulateClimb({
    required AlpineClimbBenchmarkProfile profile,
    double? riderWeightKg,
    double? wattsPerKg,
    ClimbCalibrationParameters parameters =
        const ClimbCalibrationParameters.calibrated(),
  }) {
    final double resolvedWeightKg =
        math.max(40.0, riderWeightKg ?? profile.referenceRiderWeightKg);
    final double resolvedWkg =
        math.max(1.0, wattsPerKg ?? profile.referenceWattsPerKg);
    final double inputWatts = resolvedWeightKg * resolvedWkg;

    final double totalMassKg = GravityAndRollingCalculator.calculateTotalMassKg(
      riderWeightKg: resolvedWeightKg,
      bikeWeightKg: parameters.bikeWeightKg,
      bottlesWeightKg: parameters.bottlesAndKitWeightKg,
    );

    final double gradientFraction = profile.averageGradientPercent / 100.0;
    final double effectiveCdA = calculateClimbingEffectiveCdA(
      riderWeightKg: resolvedWeightKg,
      gradientPercent: profile.averageGradientPercent,
      parameters: parameters,
    );
    final double effectiveCrr = calculateClimbingEffectiveCrr(
      surfaceType: profile.surfaceType,
      parameters: parameters,
    );

    final double averageAirDensity = AeroCalculator.calculateAirDensity(
      altitudeMeters: profile.averageElevationM,
      temperatureCelsius: parameters.temperatureCelsius,
    );

    final double eqSpeedMs = SpeedSolver.solveEquilibriumSpeed(
      inputWatts: inputWatts,
      totalMassKg: totalMassKg,
      gradientFraction: gradientFraction,
      effectiveCdA: effectiveCdA,
      airDensityKgM3: averageAirDensity,
      effectiveCrr: effectiveCrr,
      windSpeedMs: parameters.windSpeedMs,
      relativeWindAngleDegrees: parameters.relativeWindAngleDegrees,
      drivetrainLoss: parameters.drivetrainLoss,
      maxIterations: 16,
    );

    final double dt = math.max(0.25, parameters.timeStepSeconds);
    double distanceCoveredM = 0.0;
    double elapsedTimeS = 0.0;
    double currentSpeedMs = eqSpeedMs;
    double sumAirDensity = 0.0;
    double sumGravityW = 0.0;
    double sumRollingW = 0.0;
    double sumAeroW = 0.0;
    int steps = 0;

    const int maxSteps = 25000;
    while (distanceCoveredM < profile.distanceMeters && steps < maxSteps) {
      final double progress =
          (distanceCoveredM / profile.distanceMeters).clamp(0.0, 1.0);
      final double currentElevationM = profile.startElevationM +
          ((profile.summitElevationM - profile.startElevationM) * progress);

      final double airDensity = AeroCalculator.calculateAirDensity(
        altitudeMeters: currentElevationM,
        temperatureCelsius: parameters.temperatureCelsius,
      );

      final SpeedSolverResult step = SpeedSolver.solveNextSecond(
        inputWatts: inputWatts,
        currentSpeedMs: currentSpeedMs,
        totalMassKg: totalMassKg,
        gradientFraction: gradientFraction,
        effectiveCdA: effectiveCdA,
        airDensityKgM3: airDensity,
        effectiveCrr: effectiveCrr,
        windSpeedMs: parameters.windSpeedMs,
        relativeWindAngleDegrees: parameters.relativeWindAngleDegrees,
        technicalDifficulty: profile.technicalDifficulty,
        drivetrainLoss: parameters.drivetrainLoss,
        timeStepSeconds: dt,
      );

      final double stepDistanceM =
          ((currentSpeedMs + step.newSpeedMs) * 0.5) * dt;
      final double remainingDistanceM =
          profile.distanceMeters - distanceCoveredM;

      if (stepDistanceM >= remainingDistanceM && stepDistanceM > 0.0) {
        final double fraction = remainingDistanceM / stepDistanceM;
        elapsedTimeS += dt * fraction;
        distanceCoveredM = profile.distanceMeters;
      } else {
        elapsedTimeS += dt;
        distanceCoveredM += stepDistanceM;
      }

      currentSpeedMs = step.newSpeedMs;
      sumAirDensity += airDensity;
      sumGravityW += step.gravityForceNewtons * currentSpeedMs;
      sumRollingW += step.rollingForceNewtons * currentSpeedMs;
      sumAeroW += step.aeroForceNewtons * currentSpeedMs;
      steps++;
    }

    final int safeSteps = math.max(1, steps);
    final double averageSpeedMs =
        elapsedTimeS > 0.0 ? profile.distanceMeters / elapsedTimeS : 0.0;
    final double elevationGainM = profile.nominalElevationGainM;
    final double vam = calculateVamMetersPerHour(
      elevationGainMeters: elevationGainM,
      elapsedTimeSeconds: elapsedTimeS,
    );

    final double avgGravityW = sumGravityW / safeSteps;
    final double avgRollingW = sumRollingW / safeSteps;
    final double avgAeroW = sumAeroW / safeSteps;
    final double drivetrainLossW = inputWatts * parameters.drivetrainLoss;

    return ClimbSimulationBenchmarkResult(
      profile: profile,
      parameters: parameters,
      riderWeightKg: resolvedWeightKg,
      wattsPerKg: resolvedWkg,
      inputWatts: inputWatts,
      totalMassKg: totalMassKg,
      elapsedTimeSeconds: elapsedTimeS,
      averageSpeedMs: averageSpeedMs,
      equilibriumSpeedMs: eqSpeedMs,
      vamMetersPerHour: vam,
      elevationGainMeters: elevationGainM,
      averageAirDensityKgM3: sumAirDensity / safeSteps,
      effectiveCdA: effectiveCdA,
      effectiveCrr: effectiveCrr,
      gravityWatts: avgGravityW,
      rollingWatts: avgRollingW,
      aeroWatts: avgAeroW,
      drivetrainLossWatts: drivetrainLossW,
      simulationSteps: steps,
    );
  }

  /// Kalibruje parametr [ClimbCalibrationParameters.climbingCdABase] metodą bisekcji
  /// względem wskazanego podjazdu (domyślnie Alpe d'Huez) i docelowego czasu przejazdu.
  static ({ClimbCalibrationParameters parameters, int iterations})
      calibrateParameters({
    AlpineClimbBenchmarkProfile primaryTarget = alpeDHuez,
    double? targetTimeSeconds,
    ClimbCalibrationParameters initialParameters =
        const ClimbCalibrationParameters.calibrated(),
    int maxIterations = 24,
  }) {
    final double targetTime =
        targetTimeSeconds ?? primaryTarget.expectedMidpointTimeSeconds;

    double lowCdA = 0.250;
    double highCdA = 0.420;
    ClimbCalibrationParameters current = initialParameters;
    int iterations = 0;

    for (int i = 0; i < maxIterations; i++) {
      iterations++;
      final double midCdA = (lowCdA + highCdA) * 0.5;
      current = initialParameters.copyWith(climbingCdABase: midCdA);

      final result = simulateClimb(
        profile: primaryTarget,
        parameters: current,
      );

      final double diff = result.elapsedTimeSeconds - targetTime;
      if (diff.abs() <= 0.5) {
        break;
      }

      // Większe CdA spowalnia wspinacza (wydłuża czas), mniejsze przyspiesza.
      if (result.elapsedTimeSeconds < targetTime) {
        lowCdA = midCdA;
      } else {
        highCdA = midCdA;
      }
    }

    return (parameters: current, iterations: iterations);
  }

  /// Uruchamia pełny zestaw benchmarków alpejskich i zwraca raport kalibracji.
  static ClimbCalibrationReport runFullBenchmarkSuite({
    ClimbCalibrationParameters? parameters,
    bool autoCalibrateOnAlpeDHuez = false,
  }) {
    ClimbCalibrationParameters activeParams =
        parameters ?? const ClimbCalibrationParameters.calibrated();
    int iterations = 0;

    if (autoCalibrateOnAlpeDHuez) {
      final calibrated = calibrateParameters(
        primaryTarget: alpeDHuez,
        initialParameters: activeParams,
      );
      activeParams = calibrated.parameters;
      iterations = calibrated.iterations;
    }

    final List<ClimbSimulationBenchmarkResult> results = [
      for (final profile in allBenchmarks)
        simulateClimb(
          profile: profile,
          parameters: activeParams,
        ),
    ];

    return ClimbCalibrationReport(
      calibratedParameters: activeParams,
      results: results,
      calibrationIterations: iterations,
    );
  }

  /// Oblicza VAM (Velocità Ascensionale Media) w [m/h].
  static double calculateVamMetersPerHour({
    required double elevationGainMeters,
    required double elapsedTimeSeconds,
  }) {
    if (elapsedTimeSeconds <= 0.0 || elevationGainMeters <= 0.0) {
      return 0.0;
    }
    return elevationGainMeters / (elapsedTimeSeconds / 3600.0);
  }

  /// Formatuje czas przejazdu w sekundach jako `MM:SS`.
  static String formatClimbTime(double seconds) {
    final int totalSeconds = math.max(0, seconds.round());
    final int minutes = totalSeconds ~/ 60;
    final int remSeconds = totalSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = remSeconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
