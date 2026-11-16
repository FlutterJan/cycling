// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/race/cyclocross_course_and_mud_model.dart';

/// Tryb pokonania przeszkody lub trudnego odcinka w kolarstwie przełajowym (CX).
enum CyclocrossTraversalMode {
  /// Jazda w siodle z pełnym naciskiem na pedały.
  rideInSaddle('Ride in Saddle', 'Jazda w siodle'),

  /// Zeskoczenie z roweru, zarzucenie go na ramię i bieg (Dismount & Run).
  dismountAndRun('Dismount & Run', 'Zeskok i bieg z rowerem'),

  /// Przeskok nad drewnianymi belkami bez zsiadania z roweru (Bunny-Hop).
  bunnyHop('Bunny-Hop', 'Skok nad belkami (Bunny-Hop)');

  final String labelEn;
  final String labelPl;

  const CyclocrossTraversalMode(this.labelEn, this.labelPl);
}

/// Technika przenoszenia roweru podczas biegu w trybie Dismount & Run.
enum CyclocrossCarryTechnique {
  /// Klasyczne zarzucenie ramy na ramię (najlepsze w głębokim błocie i na schodach).
  shoulderCarry('Shoulder Carry', 'Rower na ramieniu'),

  /// Chwyt za górną rurę ramy (szybszy na krótkich przeszkodach i belkach).
  topTubeSuitcase('Top-Tube Carry', 'Chwyt za górną rurę');

  final String labelEn;
  final String labelPl;

  const CyclocrossCarryTechnique(this.labelEn, this.labelPl);
}

/// Wynik pokonania segmentu lub przeszkody przełajowej.
enum CyclocrossObstacleOutcome {
  cleanRide('Clean Ride', 'Czysty przejazd w siodle'),
  cleanRunCarry('Clean Dismount & Run', 'Płynny bieg z rowerem na ramieniu'),
  cleanBunnyHop('Clean Bunny-Hop', 'Czysty skok nad belkami (+1.8 s)'),
  wheelClippedCrash('Wheel-Clipped Crash', 'Zahaczenie kołem o belkę!'),
  dismountStumble('Dismount Stumble', 'Potknięcie przy zeskoku / w błocie');

  final String labelEn;
  final String labelPl;

  const CyclocrossObstacleOutcome(this.labelEn, this.labelPl);
}

/// Dane wejściowe dla solvera fizyki przełajowej (CX).
class CyclocrossBunnyhopAndCarryInput {
  final CyclocrossCourseSegment segment;
  final CyclocrossMudCondition mudCondition;
  final double riderMassKg;
  final double bikeMassKg;
  final double mudAdhesionKg;
  final double powerWatts;
  final double bikeHandling;
  final double runningEfficiency;
  final double explosiveness;
  final double wPrimeRemainingRatio;
  final double approachSpeedMps;
  final double tireWidthMm;
  final double altitudeMeters;
  final double? deterministicRoll;

  const CyclocrossBunnyhopAndCarryInput({
    required this.segment,
    this.mudCondition = CyclocrossMudCondition.heavyMud,
    this.riderMassKg = 68.0,
    this.bikeMassKg = 7.9,
    this.mudAdhesionKg = 0.0,
    this.powerWatts = 360.0,
    this.bikeHandling = 75.0,
    this.runningEfficiency = 75.0,
    this.explosiveness = 75.0,
    this.wPrimeRemainingRatio = 0.80,
    this.approachSpeedMps = 6.5,
    this.tireWidthMm = 33.0,
    this.altitudeMeters = 50.0,
    this.deterministicRoll,
  });
}

/// Wynik analizy i symulacji pojedynczego segmentu CX przez solver.
class CyclocrossBunnyhopAndCarryResult {
  final CyclocrossTraversalMode selectedMode;
  final CyclocrossCarryTechnique? carryTechnique;
  final CyclocrossObstacleOutcome outcome;
  final double mountedSpeedMps;
  final double dismountRunSpeedMps;
  final double effectiveSpeedMps;
  final double segmentTimeSeconds;
  final double mountedTimeSeconds;
  final double dismountRunTimeSeconds;
  final double timeDeltaVsSaddleSeconds;
  final double bunnyHopTimeGainSeconds;
  final double transitionOverheadSeconds;
  final bool attemptedBunnyHop;
  final bool wheelClipped;
  final double wheelClipRiskProbability;
  final double extraEnergyCostJoules;
  final String decisionReasonPl;

  const CyclocrossBunnyhopAndCarryResult({
    required this.selectedMode,
    required this.carryTechnique,
    required this.outcome,
    required this.mountedSpeedMps,
    required this.dismountRunSpeedMps,
    required this.effectiveSpeedMps,
    required this.segmentTimeSeconds,
    required this.mountedTimeSeconds,
    required this.dismountRunTimeSeconds,
    required this.timeDeltaVsSaddleSeconds,
    required this.bunnyHopTimeGainSeconds,
    required this.transitionOverheadSeconds,
    required this.attemptedBunnyHop,
    required this.wheelClipped,
    required this.wheelClipRiskProbability,
    required this.extraEnergyCostJoules,
    required this.decisionReasonPl,
  });

  /// Prędkość jazdy w siodle [km/h].
  double get mountedSpeedKmh => mountedSpeedMps * 3.6;

  /// Prędkość biegu z rowerem na ramieniu [km/h].
  double get dismountRunSpeedKmh => dismountRunSpeedMps * 3.6;

  /// Efektywna prędkość pokonania segmentu [km/h].
  double get effectiveSpeedKmh => effectiveSpeedMps * 3.6;
}

/// Zbiorcze podsumowanie jednej rundy CX dla solvera przełajowego.
class CyclocrossLapTraversalSummary {
  final List<CyclocrossBunnyhopAndCarryResult> segmentResults;
  final double totalLapTimeSeconds;
  final double totalTimeGainVsAlwaysSaddleSeconds;
  final double totalBunnyHopGainSeconds;
  final int dismountCount;
  final int bunnyHopCount;
  final int wheelClipCount;

  const CyclocrossLapTraversalSummary({
    required this.segmentResults,
    required this.totalLapTimeSeconds,
    required this.totalTimeGainVsAlwaysSaddleSeconds,
    required this.totalBunnyHopGainSeconds,
    required this.dismountCount,
    required this.bunnyHopCount,
    required this.wheelClipCount,
  });
}

/// Silnik fizyki przełajowej (Cyclocross):
/// - Automatycznie porównuje prędkość jazdy w siodle z prędkością zeskoku,
///   zarzucenia roweru na ramię i biegu (`Dismount & Run`, 12–16 km/h)
///   w głębokim błocie, piasku i na schodach.
/// - Przed drewnianymi belkami (`planks`) kolarze z `bikeHandling >= 85`
///   wykonują skok `Bunny-Hop` bez zsiadania, zyskując 1.8 s na rundzie,
///   ale ryzykując zahaczenie kołem przy wysokim zmęczeniu (`W' < 15%`).
class CyclocrossBunnyhopAndCarrySolver {
  const CyclocrossBunnyhopAndCarrySolver();

  /// Minimalna umiejętność techniczna wymagana do wykonania Bunny-Hop nad belkami.
  static const double bunnyHopMinBikeHandling = 85.0;

  /// Standardowy zysk czasowy na jednej rundzie z czystego Bunny-Hop nad belkami [s].
  static const double standardBunnyHopLapGainSeconds = 1.8;

  /// Próg pozostałego W' poniżej którego rośnie ryzyko zahaczenia kołem o belkę.
  static const double highFatigueWPrimeThreshold = 0.15;

  /// Minimalna i maksymalna bazowa prędkość biegu z rowerem [km/h] -> [m/s].
  static const double minRunCarrySpeedKmh = 12.0;
  static const double maxRunCarrySpeedKmh = 16.0;

  /// Ocenia pojedynczy segment trasy CX i wybiera optymalny tryb pokonania.
  CyclocrossBunnyhopAndCarryResult solveSegment(
    CyclocrossBunnyhopAndCarryInput input,
  ) {
    final segment = input.segment;
    final lengthMeters = math.max(1.0, segment.lengthMeters);
    final wPrimeRatio = input.wPrimeRemainingRatio.clamp(0.0, 1.0);
    final handling = input.bikeHandling.clamp(0.0, 100.0);

    final mountedSpeedMps = _computeMountedSpeedMps(input);
    final mountedTimeSeconds = lengthMeters / mountedSpeedMps;

    final transitionOverhead = _computeTransitionOverheadSeconds(
      handling: handling,
      wPrimeRatio: wPrimeRatio,
      terrainType: segment.terrainType,
    );
    final runCarrySpeedMps = _computeDismountAndRunSpeedMps(input);
    final dismountRunTimeSeconds =
        (lengthMeters / runCarrySpeedMps) + transitionOverhead;

    // Obsługa drewnianych belek (planks): Bunny-Hop vs Dismount & Run.
    if (segment.terrainType == CyclocrossTerrainType.planks) {
      return _solvePlanksSegment(
        input: input,
        lengthMeters: lengthMeters,
        mountedSpeedMps: mountedSpeedMps,
        mountedTimeSeconds: mountedTimeSeconds,
        runCarrySpeedMps: runCarrySpeedMps,
        dismountRunTimeSeconds: dismountRunTimeSeconds,
        transitionOverhead: transitionOverhead,
      );
    }

    // Na schodach jazda w siodle jest niemożliwa; w głębokim błocie i piasku
    // porównujemy bezpośrednio czas jazdy w siodle vs Dismount & Run.
    final bool mustDismountOnStairs =
        segment.terrainType == CyclocrossTerrainType.staircaseRunUp;

    final bool shouldDismount = mustDismountOnStairs ||
        _shouldPreferDismountAndRun(
          segment: segment,
          mountedTimeSeconds: mountedTimeSeconds,
          dismountRunTimeSeconds: dismountRunTimeSeconds,
        );

    if (shouldDismount) {
      final carryTechnique = _selectCarryTechnique(segment);
      final effectiveSpeedMps = lengthMeters / dismountRunTimeSeconds;
      final timeDelta = mountedTimeSeconds - dismountRunTimeSeconds;
      final extraEnergy = _computeRunCarryEnergyCostJoules(
        input: input,
        runDurationSeconds: lengthMeters / runCarrySpeedMps,
      );

      final reason = mustDismountOnStairs
          ? 'Schody (${segment.stairStepCount} stopni): obowiązkowy zeskok i bieg z rowerem na ramieniu (${(runCarrySpeedMps * 3.6).toStringAsFixed(1)} km/h).'
          : 'Głębokie błoto/piasek: bieg z rowerem na ramieniu (${(runCarrySpeedMps * 3.6).toStringAsFixed(1)} km/h) szybszy niż jazda w siodle (${(mountedSpeedMps * 3.6).toStringAsFixed(1)} km/h).';

      return CyclocrossBunnyhopAndCarryResult(
        selectedMode: CyclocrossTraversalMode.dismountAndRun,
        carryTechnique: carryTechnique,
        outcome: CyclocrossObstacleOutcome.cleanRunCarry,
        mountedSpeedMps: mountedSpeedMps,
        dismountRunSpeedMps: runCarrySpeedMps,
        effectiveSpeedMps: effectiveSpeedMps,
        segmentTimeSeconds: dismountRunTimeSeconds,
        mountedTimeSeconds: mountedTimeSeconds,
        dismountRunTimeSeconds: dismountRunTimeSeconds,
        timeDeltaVsSaddleSeconds: timeDelta,
        bunnyHopTimeGainSeconds: 0.0,
        transitionOverheadSeconds: transitionOverhead,
        attemptedBunnyHop: false,
        wheelClipped: false,
        wheelClipRiskProbability: 0.0,
        extraEnergyCostJoules: extraEnergy,
        decisionReasonPl: reason,
      );
    }

    return CyclocrossBunnyhopAndCarryResult(
      selectedMode: CyclocrossTraversalMode.rideInSaddle,
      carryTechnique: null,
      outcome: CyclocrossObstacleOutcome.cleanRide,
      mountedSpeedMps: mountedSpeedMps,
      dismountRunSpeedMps: runCarrySpeedMps,
      effectiveSpeedMps: mountedSpeedMps,
      segmentTimeSeconds: mountedTimeSeconds,
      mountedTimeSeconds: mountedTimeSeconds,
      dismountRunTimeSeconds: dismountRunTimeSeconds,
      timeDeltaVsSaddleSeconds: 0.0,
      bunnyHopTimeGainSeconds: 0.0,
      transitionOverheadSeconds: 0.0,
      attemptedBunnyHop: false,
      wheelClipped: false,
      wheelClipRiskProbability: 0.0,
      extraEnergyCostJoules: 0.0,
      decisionReasonPl:
          'Przejazd w siodle (${(mountedSpeedMps * 3.6).toStringAsFixed(1)} km/h) utrzymuje przewagę nad biegiem (${(runCarrySpeedMps * 3.6).toStringAsFixed(1)} km/h).',
    );
  }

  /// Symuluje pełną rundę CX złożoną z listy segmentów.
  CyclocrossLapTraversalSummary solveLap({
    required List<CyclocrossCourseSegment> segments,
    CyclocrossMudCondition mudCondition = CyclocrossMudCondition.heavyMud,
    double riderMassKg = 68.0,
    double bikeMassKg = 7.9,
    double mudAdhesionKg = 0.0,
    double powerWatts = 360.0,
    double bikeHandling = 75.0,
    double runningEfficiency = 75.0,
    double explosiveness = 75.0,
    double wPrimeRemainingRatio = 0.80,
    double tireWidthMm = 33.0,
    double altitudeMeters = 50.0,
    double? Function(int segmentIndex)? deterministicRollProvider,
  }) {
    if (segments.isEmpty) {
      return const CyclocrossLapTraversalSummary(
        segmentResults: <CyclocrossBunnyhopAndCarryResult>[],
        totalLapTimeSeconds: 0.0,
        totalTimeGainVsAlwaysSaddleSeconds: 0.0,
        totalBunnyHopGainSeconds: 0.0,
        dismountCount: 0,
        bunnyHopCount: 0,
        wheelClipCount: 0,
      );
    }

    final results = <CyclocrossBunnyhopAndCarryResult>[];
    var currentApproachSpeedMps = 7.5;
    var totalLapTime = 0.0;
    var totalGainVsSaddle = 0.0;
    var totalBunnyHopGain = 0.0;
    var dismounts = 0;
    var bunnyHops = 0;
    var wheelClips = 0;

    for (final segment in segments) {
      final result = solveSegment(
        CyclocrossBunnyhopAndCarryInput(
          segment: segment,
          mudCondition: mudCondition,
          riderMassKg: riderMassKg,
          bikeMassKg: bikeMassKg,
          mudAdhesionKg: mudAdhesionKg,
          powerWatts: powerWatts,
          bikeHandling: bikeHandling,
          runningEfficiency: runningEfficiency,
          explosiveness: explosiveness,
          wPrimeRemainingRatio: wPrimeRemainingRatio,
          approachSpeedMps: currentApproachSpeedMps,
          tireWidthMm: tireWidthMm,
          altitudeMeters: altitudeMeters,
          deterministicRoll: deterministicRollProvider?.call(segment.index),
        ),
      );

      results.add(result);
      totalLapTime += result.segmentTimeSeconds;
      totalGainVsSaddle += result.timeDeltaVsSaddleSeconds;
      totalBunnyHopGain += result.bunnyHopTimeGainSeconds;
      if (result.selectedMode == CyclocrossTraversalMode.dismountAndRun) {
        dismounts++;
      } else if (result.selectedMode == CyclocrossTraversalMode.bunnyHop) {
        bunnyHops++;
      }
      if (result.wheelClipped) {
        wheelClips++;
      }
      currentApproachSpeedMps = result.effectiveSpeedMps;
    }

    return CyclocrossLapTraversalSummary(
      segmentResults: results,
      totalLapTimeSeconds: totalLapTime,
      totalTimeGainVsAlwaysSaddleSeconds: totalGainVsSaddle,
      totalBunnyHopGainSeconds: totalBunnyHopGain,
      dismountCount: dismounts,
      bunnyHopCount: bunnyHops,
      wheelClipCount: wheelClips,
    );
  }

  /// Oblicza prawdopodobieństwo zahaczenia kołem o belkę przy Bunny-Hop.
  /// Przy W' >= 15% ryzyko jest minimalne; poniżej W' < 15% rośnie gwałtownie.
  double computeWheelClipRisk({
    required double bikeHandling,
    required double wPrimeRemainingRatio,
    double plankHeightCm = 40.0,
    int plankCount = 2,
    CyclocrossMudCondition mudCondition = CyclocrossMudCondition.heavyMud,
  }) {
    final handling = bikeHandling.clamp(0.0, 100.0);
    if (handling < bunnyHopMinBikeHandling) {
      return 1.0;
    }

    final wPrime = wPrimeRemainingRatio.clamp(0.0, 1.0);
    final heightFactor = (plankHeightCm / 40.0).clamp(0.75, 1.35);
    final countFactor = (math.max(1, plankCount) / 2.0).clamp(0.7, 1.5);
    final mudSlipFactor = 0.85 + (mudCondition.adhesionMultiplier * 0.15);
    final skillMitigation = 1.0 - ((handling - bunnyHopMinBikeHandling) / 15.0) * 0.35;

    if (wPrime >= highFatigueWPrimeThreshold) {
      // Wypoczęty kolarz z wysokim handlingiem ma znikome ryzyko (< 2%).
      final baseCleanRisk = 0.008 * heightFactor * mudSlipFactor;
      return (baseCleanRisk * skillMitigation).clamp(0.0, 0.03);
    }

    // Strefa wysokiego zmęczenia: W' < 15%
    final fatigueDeficit =
        (highFatigueWPrimeThreshold - wPrime) / highFatigueWPrimeThreshold;
    final rawRisk = 0.14 + (math.pow(fatigueDeficit, 1.35) * 0.56);
    final adjustedRisk =
        rawRisk * heightFactor * countFactor * mudSlipFactor * skillMitigation;

    return adjustedRisk.clamp(0.08, 0.85);
  }

  CyclocrossBunnyhopAndCarryResult _solvePlanksSegment({
    required CyclocrossBunnyhopAndCarryInput input,
    required double lengthMeters,
    required double mountedSpeedMps,
    required double mountedTimeSeconds,
    required double runCarrySpeedMps,
    required double dismountRunTimeSeconds,
    required double transitionOverhead,
  }) {
    final segment = input.segment;
    final handling = input.bikeHandling.clamp(0.0, 100.0);
    final wPrimeRatio = input.wPrimeRemainingRatio.clamp(0.0, 1.0);
    final canAttemptBunnyHop = segment.isBunnyHoppable &&
        handling >= bunnyHopMinBikeHandling &&
        segment.plankHeightCm <= 45.0;

    if (!canAttemptBunnyHop) {
      final carryTechnique = _selectCarryTechnique(segment);
      final effectiveSpeed = lengthMeters / dismountRunTimeSeconds;
      final extraEnergy = _computeRunCarryEnergyCostJoules(
        input: input,
        runDurationSeconds: lengthMeters / runCarrySpeedMps,
      );

      return CyclocrossBunnyhopAndCarryResult(
        selectedMode: CyclocrossTraversalMode.dismountAndRun,
        carryTechnique: carryTechnique,
        outcome: CyclocrossObstacleOutcome.cleanRunCarry,
        mountedSpeedMps: mountedSpeedMps,
        dismountRunSpeedMps: runCarrySpeedMps,
        effectiveSpeedMps: effectiveSpeed,
        segmentTimeSeconds: dismountRunTimeSeconds,
        mountedTimeSeconds: mountedTimeSeconds,
        dismountRunTimeSeconds: dismountRunTimeSeconds,
        timeDeltaVsSaddleSeconds: 0.0,
        bunnyHopTimeGainSeconds: 0.0,
        transitionOverheadSeconds: transitionOverhead,
        attemptedBunnyHop: false,
        wheelClipped: false,
        wheelClipRiskProbability: 0.0,
        extraEnergyCostJoules: extraEnergy,
        decisionReasonPl:
            'Belki (bikeHandling ${handling.toStringAsFixed(0)} < 85): zeskok i bieg z rowerem nad przeszkodą.',
      );
    }

    final clipRisk = computeWheelClipRisk(
      bikeHandling: handling,
      wPrimeRemainingRatio: wPrimeRatio,
      plankHeightCm: segment.plankHeightCm,
      plankCount: segment.plankCount,
      mudCondition: input.mudCondition,
    );

    final bool clipped =
        input.deterministicRoll != null && input.deterministicRoll! < clipRisk;

    // Skala zysku dla standardowych 2 belek = 1.8 s na rundzie.
    final plankCountScale =
        segment.plankCount > 0 ? (segment.plankCount / 2.0).clamp(0.5, 1.5) : 1.0;
    final cleanGainSeconds = standardBunnyHopLapGainSeconds * plankCountScale;

    if (clipped) {
      // Zahaczenie tylnym/przednim kołem: upadek lub zatrzymanie i strata 5.2 s.
      final crashPenaltySeconds = 4.6 + (1.0 - wPrimeRatio) * 1.4;
      final finalTimeSeconds = dismountRunTimeSeconds + crashPenaltySeconds;
      final effectiveSpeed = lengthMeters / finalTimeSeconds;

      return CyclocrossBunnyhopAndCarryResult(
        selectedMode: CyclocrossTraversalMode.bunnyHop,
        carryTechnique: null,
        outcome: CyclocrossObstacleOutcome.wheelClippedCrash,
        mountedSpeedMps: mountedSpeedMps,
        dismountRunSpeedMps: runCarrySpeedMps,
        effectiveSpeedMps: effectiveSpeed,
        segmentTimeSeconds: finalTimeSeconds,
        mountedTimeSeconds: mountedTimeSeconds,
        dismountRunTimeSeconds: dismountRunTimeSeconds,
        timeDeltaVsSaddleSeconds: dismountRunTimeSeconds - finalTimeSeconds,
        bunnyHopTimeGainSeconds: -crashPenaltySeconds,
        transitionOverheadSeconds: 0.0,
        attemptedBunnyHop: true,
        wheelClipped: true,
        wheelClipRiskProbability: clipRisk,
        extraEnergyCostJoules: 420.0,
        decisionReasonPl:
            'Bunny-Hop przy W\' ${(wPrimeRatio * 100).toStringAsFixed(1)}% (<15%): zahaczenie kołem o belkę! Strata ${crashPenaltySeconds.toStringAsFixed(1)} s.',
      );
    }

    // Czysty Bunny-Hop: brak zeskoku, bezpośredni zysk 1.8 s względem Dismount & Run.
    final bunnyHopTimeSeconds =
        math.max(0.8, dismountRunTimeSeconds - cleanGainSeconds);
    final effectiveSpeed = lengthMeters / bunnyHopTimeSeconds;
    final popEnergyCost =
        (input.riderMassKg + input.bikeMassKg) * 2.4 * math.max(1, segment.plankCount);

    return CyclocrossBunnyhopAndCarryResult(
      selectedMode: CyclocrossTraversalMode.bunnyHop,
      carryTechnique: null,
      outcome: CyclocrossObstacleOutcome.cleanBunnyHop,
      mountedSpeedMps: mountedSpeedMps,
      dismountRunSpeedMps: runCarrySpeedMps,
      effectiveSpeedMps: effectiveSpeed,
      segmentTimeSeconds: bunnyHopTimeSeconds,
      mountedTimeSeconds: mountedTimeSeconds,
      dismountRunTimeSeconds: dismountRunTimeSeconds,
      timeDeltaVsSaddleSeconds: cleanGainSeconds,
      bunnyHopTimeGainSeconds: cleanGainSeconds,
      transitionOverheadSeconds: 0.0,
      attemptedBunnyHop: true,
      wheelClipped: false,
      wheelClipRiskProbability: clipRisk,
      extraEnergyCostJoules: popEnergyCost,
      decisionReasonPl:
          'Bunny-Hop nad belkami (bikeHandling ${handling.toStringAsFixed(0)} >= 85): zysk ${cleanGainSeconds.toStringAsFixed(1)} s bez zsiadania.',
    );
  }

  /// Oblicza prędkość jazdy w siodle [m/s] z równowagi mocy i oporów w terenie CX.
  double _computeMountedSpeedMps(CyclocrossBunnyhopAndCarryInput input) {
    final segment = input.segment;
    if (segment.terrainType == CyclocrossTerrainType.staircaseRunUp) {
      // Na schodach nie da się jechać w siodle.
      return 0.6;
    }

    final totalMass =
        math.max(45.0, input.riderMassKg + input.bikeMassKg + input.mudAdhesionKg);
    final slopeRadians = math.atan(segment.gradientPercent / 100.0);
    final sinTheta = math.sin(slopeRadians);
    final cosTheta = math.cos(slopeRadians);

    // W głębokim błocie i piasku napęd ma wyższe straty mechaniczne.
    final drivetrainEfficiency =
        segment.terrainType == CyclocrossTerrainType.deepMud ||
                segment.terrainType == CyclocrossTerrainType.sandPit
            ? 0.945
            : PhysicsConstants.getMechanicalEfficiency(isDirty: true);

    final effectivePower = math.max(60.0, input.powerWatts) * drivetrainEfficiency;

    // Efektywne Crr powiększone o lepkość błota i opór zapadania opony.
    var crr = segment.baseRollingResistanceCrr;
    if (segment.terrainType == CyclocrossTerrainType.deepMud) {
      final tireWidthFactor = (33.0 / input.tireWidthMm.clamp(28.0, 42.0));
      crr *= (0.95 + input.mudCondition.adhesionMultiplier * 0.45) *
          tireWidthFactor;
      // Powyżej 12 cm błota opór hydrodynamiczny i zapychanie widelca rosną nieliniowo.
      if (segment.mudDepthCm > 12.0) {
        crr += (segment.mudDepthCm - 12.0) * 0.0085;
      }
    } else if (segment.terrainType == CyclocrossTerrainType.sandPit) {
      crr *= (33.0 / input.tireWidthMm.clamp(28.0, 42.0));
    }

    final fGravity = totalMass * PhysicsConstants.gravity * sinTheta;
    final fRolling = totalMass * PhysicsConstants.gravity * cosTheta * crr;
    final airDensity =
        PhysicsConstants.getAirDensityAtAltitude(input.altitudeMeters);
    final aeroFactor = 0.5 * airDensity * PhysicsConstants.cdaHoods;

    // Bisekcja równowagi sił: P = v * (F_gravity + F_rolling + aeroFactor * v^2)
    var low = 0.5;
    var high = 16.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) * 0.5;
      final powerNeeded = mid * (fGravity + fRolling + aeroFactor * mid * mid);
      if (powerNeeded > effectivePower) {
        high = mid;
      } else {
        low = mid;
      }
    }

    var solvedSpeed = (low + high) * 0.5;

    // Uślizg tylnego koła w głębokim błocie lub na stromym trawersie ogranicza prędkość.
    if (segment.terrainType == CyclocrossTerrainType.deepMud &&
        segment.mudDepthCm >= 12.0) {
      final tractionCap = math.max(
        1.6,
        3.9 - (segment.mudDepthCm - 12.0) * 0.14 - segment.mudViscosityIndex * 0.6,
      );
      solvedSpeed = math.min(solvedSpeed, tractionCap);
    }

    return solvedSpeed.clamp(0.6, 15.0);
  }

  /// Oblicza prędkość biegu z rowerem na ramieniu (`Dismount & Run`) w zakresie 12–16 km/h
  /// na płaskim/umiarkowanym podłożu, korygowaną o głębokość błota, schody i zmęczenie.
  double _computeDismountAndRunSpeedMps(CyclocrossBunnyhopAndCarryInput input) {
    final segment = input.segment;
    final runEff = input.runningEfficiency.clamp(0.0, 100.0) / 100.0;
    final wPrime = input.wPrimeRemainingRatio.clamp(0.0, 1.0);

    // Bazowy zakres 12.0–16.0 km/h zależny od sprawności biegowej kolarza.
    var baseKmh =
        minRunCarrySpeedKmh + (maxRunCarrySpeedKmh - minRunCarrySpeedKmh) * runEff;

    // Cięższy rower (np. oblepiony błotem) lekko spowalnia bieg.
    final carryMassPenalty =
        math.max(0.0, (input.bikeMassKg + input.mudAdhesionKg) - 7.8) * 0.25;
    baseKmh -= carryMassPenalty;

    // Zmęczenie W' < 25% obniża tempo biegu.
    if (wPrime < 0.25) {
      baseKmh *= 0.90 + (wPrime / 0.25) * 0.10;
    }

    // Modyfikatory nawierzchni.
    switch (segment.terrainType) {
      case CyclocrossTerrainType.deepMud:
        final mudDrag = (segment.mudDepthCm.clamp(0.0, 25.0) / 25.0) * 0.18 +
            segment.mudViscosityIndex.clamp(0.0, 1.0) * 0.08;
        baseKmh *= (1.0 - mudDrag).clamp(0.75, 1.0);
      case CyclocrossTerrainType.staircaseRunUp:
        final stepPenalty = (segment.stairStepCount.clamp(0, 60) / 60.0) * 0.16;
        baseKmh *= (0.94 - stepPenalty).clamp(0.72, 0.96);
      case CyclocrossTerrainType.sandPit:
        final sandPenalty = (segment.sandDepthCm.clamp(0.0, 30.0) / 30.0) * 0.14;
        baseKmh *= (1.0 - sandPenalty).clamp(0.80, 1.0);
      case CyclocrossTerrainType.planks:
        baseKmh *= 0.96;
      case CyclocrossTerrainType.offCamberSlope:
      case CyclocrossTerrainType.meadowGrass:
      case CyclocrossTerrainType.woodlandSingletrack:
      case CyclocrossTerrainType.pavedStartFinish:
      case CyclocrossTerrainType.doublePitLane:
        break;
    }

    // Nachylenie w górę lub w dół wpływa na prędkość biegu.
    if (segment.gradientPercent > 0.0) {
      baseKmh *= (1.0 - (segment.gradientPercent.clamp(0.0, 30.0) * 0.011));
    }

    baseKmh *= segment.runningSpeedPenaltyFactor.clamp(0.65, 1.15);

    // Przeliczenie na m/s z rozsądnymi granicami fizycznymi.
    return (baseKmh.clamp(8.5, 16.5)) / 3.6;
  }

  /// Czas stracony na zeskok z roweru i ponowne wskoczenie / wpięcie w pedały [s].
  double _computeTransitionOverheadSeconds({
    required double handling,
    required double wPrimeRatio,
    required CyclocrossTerrainType terrainType,
  }) {
    final skillFactor = 1.0 - (handling / 100.0) * 0.35; // 0.65 .. 1.0
    final fatigueAddition = wPrimeRatio < 0.20 ? 0.35 : 0.0;
    final baseTransition =
        terrainType == CyclocrossTerrainType.planks ? 2.1 : 2.3;
    return (baseTransition * skillFactor) + fatigueAddition;
  }

  bool _shouldPreferDismountAndRun({
    required CyclocrossCourseSegment segment,
    required double mountedTimeSeconds,
    required double dismountRunTimeSeconds,
  }) {
    // Histereza 0.25 s, aby uniknąć zsiadania dla minimalnej różnicy.
    if (dismountRunTimeSeconds + 0.25 < mountedTimeSeconds) {
      return true;
    }
    return segment.requiresDismount &&
        dismountRunTimeSeconds <= mountedTimeSeconds + 0.5;
  }

  CyclocrossCarryTechnique _selectCarryTechnique(
    CyclocrossCourseSegment segment,
  ) {
    if (segment.terrainType == CyclocrossTerrainType.staircaseRunUp ||
        segment.terrainType == CyclocrossTerrainType.deepMud ||
        segment.lengthMeters >= 25.0) {
      return CyclocrossCarryTechnique.shoulderCarry;
    }
    return CyclocrossCarryTechnique.topTubeSuitcase;
  }

  double _computeRunCarryEnergyCostJoules({
    required CyclocrossBunnyhopAndCarryInput input,
    required double runDurationSeconds,
  }) {
    final totalCarryMass = input.bikeMassKg + input.mudAdhesionKg;
    return totalCarryMass * 9.81 * 0.35 * runDurationSeconds;
  }
}
