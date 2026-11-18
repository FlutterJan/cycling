// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/paracycling/uci_paracycling_tandem_handbike_model.dart';

/// Stan synchronizacji pedałowania pilota i stokera na tandemie Klasy B.
enum TandemSyncPhase {
  synchronized(
    labelPl: 'Zsynchronizowany',
    labelEn: 'Synchronized',
    color: AppColors.statusSuccess,
  ),
  marginalDrift(
    labelPl: 'Lekki rozjazd',
    labelEn: 'Marginal Drift',
    color: AppColors.amberWarning,
  ),
  cadenceMismatch(
    labelPl: 'Rozsynchronizowany',
    labelEn: 'Cadence Mismatch',
    color: AppColors.crimsonAlert,
  );

  final String labelPl;
  final String labelEn;
  final Color color;

  const TandemSyncPhase({
    required this.labelPl,
    required this.labelEn,
    required this.color,
  });
}

/// Strefa stabilności poprzecznej trójkołowego handbike'a w zakręcie.
enum HandbikeTurnStabilityZone {
  planted(
    labelPl: 'Stabilny tor',
    labelEn: 'Planted',
    color: AppColors.statusSuccess,
  ),
  innerWheelLiftRisk(
    labelPl: 'Ryzyko oderwania koła',
    labelEn: 'Inner Wheel Lift Risk',
    color: AppColors.amberWarning,
  ),
  tipOverCritical(
    labelPl: 'Krytyczne wywrócenie',
    labelEn: 'Tip-Over Critical',
    color: AppColors.crimsonAlert,
  );

  final String labelPl;
  final String labelEn;
  final Color color;

  const HandbikeTurnStabilityZone({
    required this.labelPl,
    required this.labelEn,
    required this.color,
  });
}

/// Stan termiczny tarcz hamulcowych na długich zjazdach tandemowych (>95 km/h).
enum DescentThermalBrakeStatus {
  nominal(
    labelPl: 'Nominalna',
    labelEn: 'Nominal',
    color: AppColors.statusSuccess,
  ),
  warm(
    labelPl: 'Rozgrzane tarcze',
    labelEn: 'Warm Rotors',
    color: AppColors.accentBlue,
  ),
  fadeWarning(
    labelPl: 'Ryzyko fadingu',
    labelEn: 'Fade Warning',
    color: AppColors.amberWarning,
  ),
  thermalFade(
    labelPl: 'Fading hamulców!',
    labelEn: 'Thermal Fade!',
    color: AppColors.crimsonAlert,
  );

  final String labelPl;
  final String labelEn;
  final Color color;

  const DescentThermalBrakeStatus({
    required this.labelPl,
    required this.labelEn,
    required this.color,
  });
}

/// Tryb pracy interaktywnego panelu fizyki paraolimpijskiej.
enum ParacyclingPhysicsViewMode {
  tandemPowerAndDescent(
    labelPl: 'Tandem B (>800 W / >95 km/h)',
    labelEn: 'Tandem B (>800 W / >95 km/h)',
  ),
  handbikeAeroAndCornering(
    labelPl: 'Handbike H1–H5 (Aero & Zakręty)',
    labelEn: 'Handbike H1–H5 (Aero & Cornering)',
  );

  final String labelPl;
  final String labelEn;

  const ParacyclingPhysicsViewMode({
    required this.labelPl,
    required this.labelEn,
  });
}

/// Dane wejściowe do kroku fizyki dwuosobowego tandemu Klasy B.
class TandemPhysicsInput {
  final TandemCrewPairing crew;
  final double pilotTargetWatts;
  final double stokerTargetWatts;
  final double pilotCadenceRpm;
  final double stokerCadenceRpm;
  final double currentSpeedMs;
  final double gradientPercent;
  final double altitudeMeters;
  final double headwindMs;
  final double crosswindMs;
  final double? cornerRadiusM;
  final double technicalDifficulty;
  final double draftingFactor;
  final double surfaceCrrMultiplier;
  final double rotorTempCelsius;
  final double dtSeconds;

  const TandemPhysicsInput({
    required this.crew,
    required this.pilotTargetWatts,
    required this.stokerTargetWatts,
    this.pilotCadenceRpm = 92.0,
    this.stokerCadenceRpm = 92.0,
    this.currentSpeedMs = 12.0,
    this.gradientPercent = 0.0,
    this.altitudeMeters = 200.0,
    this.headwindMs = 0.0,
    this.crosswindMs = 0.0,
    this.cornerRadiusM,
    this.technicalDifficulty = 30.0,
    this.draftingFactor = 1.0,
    this.surfaceCrrMultiplier = 1.0,
    this.rotorTempCelsius = 45.0,
    this.dtSeconds = 1.0,
  });

  double get currentSpeedKmh => currentSpeedMs * 3.6;
}

/// Wynik kroku solvera fizyki tandemu Klasy B.
class TandemPhysicsResult {
  final double combinedInputWatts;
  final double effectiveWheelWatts;
  final double syncEfficiencyMultiplier;
  final TandemSyncPhase syncPhase;
  final double totalSystemMassKg;
  final double effectiveCdaM2;
  final double propulsionForceN;
  final double aeroDragForceN;
  final double gravityForceN;
  final double rollingResistanceForceN;
  final double brakingForceN;
  final double netForceN;
  final double accelerationMs2;
  final double newSpeedMs;
  final double equilibriumSpeedMs;
  final double maxSafeDescentKmh;
  final bool isDescentSpeedLimited;
  final double estimatedRotorTempCelsius;
  final DescentThermalBrakeStatus brakeStatus;
  final int solverIterations;

  const TandemPhysicsResult({
    required this.combinedInputWatts,
    required this.effectiveWheelWatts,
    required this.syncEfficiencyMultiplier,
    required this.syncPhase,
    required this.totalSystemMassKg,
    required this.effectiveCdaM2,
    required this.propulsionForceN,
    required this.aeroDragForceN,
    required this.gravityForceN,
    required this.rollingResistanceForceN,
    required this.brakingForceN,
    required this.netForceN,
    required this.accelerationMs2,
    required this.newSpeedMs,
    required this.equilibriumSpeedMs,
    required this.maxSafeDescentKmh,
    required this.isDescentSpeedLimited,
    required this.estimatedRotorTempCelsius,
    required this.brakeStatus,
    required this.solverIterations,
  });

  double get newSpeedKmh => newSpeedMs * 3.6;
  double get equilibriumSpeedKmh => equilibriumSpeedMs * 3.6;
  bool get isOver800Watts => combinedInputWatts >= 800.0;
  bool get isOver95Kmh => newSpeedKmh >= 95.0 || equilibriumSpeedKmh >= 95.0;
}

/// Podsumowanie wielosekundowej symulacji zjazdu tandemem Klasy B.
class TandemDescentSimulationSummary {
  final double peakSpeedKmh;
  final double finalSpeedKmh;
  final double averageSpeedKmh;
  final double peakRotorTempCelsius;
  final DescentThermalBrakeStatus finalBrakeStatus;
  final double distanceCoveredM;
  final double durationSeconds;
  final bool exceeded95Kmh;

  const TandemDescentSimulationSummary({
    required this.peakSpeedKmh,
    required this.finalSpeedKmh,
    required this.averageSpeedKmh,
    required this.peakRotorTempCelsius,
    required this.finalBrakeStatus,
    required this.distanceCoveredM,
    required this.durationSeconds,
    required this.exceeded95Kmh,
  });
}

/// Dane wejściowe do kroku fizyki trójkołowego handbike'a (H1–H5).
class HandbikePhysicsInput {
  final ParacyclingAthleteProfile athlete;
  final ParacyclingBikeSpec bike;
  final double armCrankWatts;
  final double crankCadenceRpm;
  final double currentSpeedMs;
  final double gradientPercent;
  final double altitudeMeters;
  final double headwindMs;
  final double crosswindMs;
  final double? cornerRadiusM;
  final double trackWidthM;
  final double draftingFactor;
  final double surfaceCrrMultiplier;
  final double upperBodyFatigueFactor;
  final double dtSeconds;

  const HandbikePhysicsInput({
    required this.athlete,
    required this.bike,
    required this.armCrankWatts,
    this.crankCadenceRpm = 84.0,
    this.currentSpeedMs = 9.0,
    this.gradientPercent = 0.0,
    this.altitudeMeters = 200.0,
    this.headwindMs = 0.0,
    this.crosswindMs = 0.0,
    this.cornerRadiusM,
    this.trackWidthM = 0.72,
    this.draftingFactor = 1.0,
    this.surfaceCrrMultiplier = 1.0,
    this.upperBodyFatigueFactor = 0.0,
    this.dtSeconds = 1.0,
  });

  double get currentSpeedKmh => currentSpeedMs * 3.6;
}

/// Wynik kroku solvera fizyki trójkołowego handbike'a (H1–H5).
class HandbikePhysicsResult {
  final ParacyclingSportClass sportClass;
  final HandbikePostureType posture;
  final double armCrankInputWatts;
  final double effectiveWheelWatts;
  final double totalSystemMassKg;
  final double effectiveCdaM2;
  final double effectiveCrr;
  final double propulsionForceN;
  final double aeroDragForceN;
  final double gravityForceN;
  final double rollingResistanceForceN;
  final double corneringScrubForceN;
  final double brakingForceN;
  final double netForceN;
  final double accelerationMs2;
  final double newSpeedMs;
  final double equilibriumSpeedMs;
  final double lateralAccelerationG;
  final double maxSafeCorneringSpeedKmh;
  final HandbikeTurnStabilityZone turnStabilityZone;
  final bool isCorneringLimited;
  final double climbingTractionPenaltyFactor;
  final int solverIterations;

  const HandbikePhysicsResult({
    required this.sportClass,
    required this.posture,
    required this.armCrankInputWatts,
    required this.effectiveWheelWatts,
    required this.totalSystemMassKg,
    required this.effectiveCdaM2,
    required this.effectiveCrr,
    required this.propulsionForceN,
    required this.aeroDragForceN,
    required this.gravityForceN,
    required this.rollingResistanceForceN,
    required this.corneringScrubForceN,
    required this.brakingForceN,
    required this.netForceN,
    required this.accelerationMs2,
    required this.newSpeedMs,
    required this.equilibriumSpeedMs,
    required this.lateralAccelerationG,
    required this.maxSafeCorneringSpeedKmh,
    required this.turnStabilityZone,
    required this.isCorneringLimited,
    required this.climbingTractionPenaltyFactor,
    required this.solverIterations,
  });

  double get newSpeedKmh => newSpeedMs * 3.6;
  double get equilibriumSpeedKmh => equilibriumSpeedMs * 3.6;
}

/// Zaawansowany solver fizyki ruchu dla tandemów Klasy B (podwójna moc >800 W,
/// zjazdy >95 km/h) oraz trójkołowych handbike'ów klas H1–H5.
class TandemAndHandbikePhysicsSolver {
  TandemAndHandbikePhysicsSolver._();

  static const double _minSpeedDenominatorMs = 0.45;
  static const double _tandemMaxTractionN = 1850.0;
  static const double _handbikeMaxTractionN = 680.0;
  static const double _tandemTimingChainLoss = 0.012;
  static const double _handbikeLongChainLoss = 0.016;

  /// Rozwiązuje krok dynamiki ruchu dla dwuosobowego tandemu Klasy B.
  static TandemPhysicsResult solveTandemStep(TandemPhysicsInput input) {
    final double pilotWatts = math.max(0.0, input.pilotTargetWatts);
    final double stokerWatts = math.max(0.0, input.stokerTargetWatts);
    final double combinedInputWatts = pilotWatts + stokerWatts;

    final ({double multiplier, TandemSyncPhase phase}) syncEval =
        _evaluateTandemSync(
      crew: input.crew,
      pilotCadenceRpm: input.pilotCadenceRpm,
      stokerCadenceRpm: input.stokerCadenceRpm,
    );

    final double primaryEfficiency =
        input.crew.tandemBike.drivetrainEfficiency.clamp(0.85, 0.99);
    final double totalDrivetrainEfficiency =
        primaryEfficiency * (1.0 - _tandemTimingChainLoss);
    final double effectiveWheelWatts =
        combinedInputWatts * syncEval.multiplier * totalDrivetrainEfficiency;

    final double totalMassKg =
        math.max(95.0, input.crew.totalSystemWeightKg);
    final double airDensity =
        PhysicsConstants.getAirDensityAtAltitude(input.altitudeMeters);

    // Wiatr boczny zwiększa efektywny opór czołowy tandemu o długim rozstawie osi.
    final double crosswindPenalty =
        1.0 + math.min(0.18, (input.crosswindMs.abs() / 22.0) * 0.14);
    final double effectiveCdaM2 =
        input.crew.tandemBike.cdaM2 * crosswindPenalty;

    final double effectiveCrr = (input.crew.tandemBike.crr *
            input.surfaceCrrMultiplier.clamp(0.8, 3.5))
        .clamp(0.0020, 0.025);

    final double slopeRad = math.atan(input.gradientPercent / 100.0);
    final double gravityForceN =
        totalMassKg * PhysicsConstants.gravity * math.sin(slopeRad);
    final double rollingForceN = totalMassKg *
        PhysicsConstants.gravity *
        math.cos(slopeRad) *
        effectiveCrr;

    final double currentSpeedMs = math.max(0.0, input.currentSpeedMs);
    final double propulsionForceN = _computePropulsionForce(
      wheelWatts: effectiveWheelWatts,
      speedMs: currentSpeedMs,
      maxTractionN: _tandemMaxTractionN,
    );

    final double aeroDragN = _computeAeroDrag(
      airDensity: airDensity,
      cdaM2: effectiveCdaM2,
      draftingFactor: input.draftingFactor.clamp(0.35, 1.0),
      speedMs: currentSpeedMs,
      headwindMs: input.headwindMs,
    );

    // Wyliczenie bezpiecznej prędkości maksymalnej na zjeździe (dla elity >95 km/h).
    final double maxSafeDescentKmh = calculateTandemMaxDescentKmh(
      crew: input.crew,
      technicalDifficulty: input.technicalDifficulty,
      cornerRadiusM: input.cornerRadiusM,
      gradientPercent: input.gradientPercent,
    );
    final double maxSafeDescentMs = maxSafeDescentKmh / 3.6;

    // Równanie równowagi ustalonej bez ogranicznika hamulcowego.
    final ({double speedMs, int iterations}) eqResult =
        _solveEquilibriumSpeed(
      wheelWatts: effectiveWheelWatts,
      gravityPlusRollingN: gravityForceN + rollingForceN,
      airDensity: airDensity,
      cdaM2: effectiveCdaM2,
      draftingFactor: input.draftingFactor.clamp(0.35, 1.0),
      headwindMs: input.headwindMs,
      maxSpeedCapMs: 42.0, // 151.2 km/h górna granica numeryczna
    );

    final double dt = input.dtSeconds.clamp(0.05, 5.0);
    final double totalResistanceN = gravityForceN + rollingForceN + aeroDragN;
    final double unbrakedNetForceN = propulsionForceN - totalResistanceN;
    final double unbrakedAccel = unbrakedNetForceN / totalMassKg;
    final double unbrakedNextSpeedMs =
        math.max(0.0, currentSpeedMs + unbrakedAccel * dt);

    double brakingForceN = 0.0;
    bool isDescentLimited = false;
    double newSpeedMs = unbrakedNextSpeedMs;

    if (unbrakedNextSpeedMs > maxSafeDescentMs && input.gradientPercent < -1.0) {
      isDescentLimited = true;
      newSpeedMs = maxSafeDescentMs;
      final double requiredNetAccel = (newSpeedMs - currentSpeedMs) / dt;
      final double requiredNetForceN = requiredNetAccel * totalMassKg;
      brakingForceN = math.max(0.0, propulsionForceN - totalResistanceN - requiredNetForceN);
    }

    final double finalNetForceN = unbrakedNetForceN - brakingForceN;
    final double finalAccelMs2 = finalNetForceN / totalMassKg;

    // Model nagrzewania tarcz 203 mm podczas dohamowywania na zjeździe.
    final double nextRotorTemp = _updateBrakeRotorTemperature(
      currentTempC: input.rotorTempCelsius,
      brakingForceN: brakingForceN,
      speedMs: currentSpeedMs,
      coolingRating: input.crew.tandemBike.brakeCoolingRating,
      dtSeconds: dt,
    );

    return TandemPhysicsResult(
      combinedInputWatts: combinedInputWatts,
      effectiveWheelWatts: effectiveWheelWatts,
      syncEfficiencyMultiplier: syncEval.multiplier,
      syncPhase: syncEval.phase,
      totalSystemMassKg: totalMassKg,
      effectiveCdaM2: effectiveCdaM2,
      propulsionForceN: propulsionForceN,
      aeroDragForceN: aeroDragN,
      gravityForceN: gravityForceN,
      rollingResistanceForceN: rollingForceN,
      brakingForceN: brakingForceN,
      netForceN: finalNetForceN,
      accelerationMs2: finalAccelMs2,
      newSpeedMs: newSpeedMs,
      equilibriumSpeedMs: eqResult.speedMs,
      maxSafeDescentKmh: maxSafeDescentKmh,
      isDescentSpeedLimited: isDescentLimited,
      estimatedRotorTempCelsius: nextRotorTemp,
      brakeStatus: _classifyBrakeTemp(nextRotorTemp),
      solverIterations: eqResult.iterations,
    );
  }

  /// Symuluje wielosekundowy zjazd tandemem Klasy B (np. z przełęczy alpejskiej),
  /// weryfikując osiągnięcie prędkości >95 km/h oraz temperaturę hamulców.
  static TandemDescentSimulationSummary simulateTandemDescent({
    required TandemCrewPairing crew,
    double gradientPercent = -9.0,
    double pilotWatts = 260.0,
    double stokerWatts = 240.0,
    double initialSpeedKmh = 48.0,
    double technicalDifficulty = 22.0,
    double durationSeconds = 30.0,
    double dtSeconds = 1.0,
    double altitudeMeters = 1400.0,
  }) {
    final double stepDt = dtSeconds.clamp(0.1, 2.0);
    final int steps = math.max(1, (durationSeconds / stepDt).round());

    double speedMs = math.max(1.0, initialSpeedKmh / 3.6);
    double rotorTemp = 45.0;
    double peakSpeedKmh = initialSpeedKmh;
    double peakRotorTemp = rotorTemp;
    double speedSumMs = 0.0;
    double distanceM = 0.0;
    DescentThermalBrakeStatus finalStatus = DescentThermalBrakeStatus.nominal;

    for (int i = 0; i < steps; i++) {
      final result = solveTandemStep(
        TandemPhysicsInput(
          crew: crew,
          pilotTargetWatts: pilotWatts,
          stokerTargetWatts: stokerWatts,
          currentSpeedMs: speedMs,
          gradientPercent: gradientPercent,
          altitudeMeters: altitudeMeters,
          technicalDifficulty: technicalDifficulty,
          rotorTempCelsius: rotorTemp,
          dtSeconds: stepDt,
        ),
      );
      speedMs = result.newSpeedMs;
      rotorTemp = result.estimatedRotorTempCelsius;
      finalStatus = result.brakeStatus;
      peakSpeedKmh = math.max(peakSpeedKmh, result.newSpeedKmh);
      peakRotorTemp = math.max(peakRotorTemp, rotorTemp);
      speedSumMs += speedMs;
      distanceM += speedMs * stepDt;
    }

    return TandemDescentSimulationSummary(
      peakSpeedKmh: peakSpeedKmh,
      finalSpeedKmh: speedMs * 3.6,
      averageSpeedKmh: (speedSumMs / steps) * 3.6,
      peakRotorTempCelsius: peakRotorTemp,
      finalBrakeStatus: finalStatus,
      distanceCoveredM: distanceM,
      durationSeconds: steps * stepDt,
      exceeded95Kmh: peakSpeedKmh >= 95.0,
    );
  }

  /// Oblicza maksymalną bezpieczną prędkość zjazdową tandemu [km/h].
  /// Elitarny duet o dużej masie całkowitej i zaufaniu pilota bez problemu
  /// przekracza 95 km/h na szybkich zjazdach o niskiej trudności technicznej.
  static double calculateTandemMaxDescentKmh({
    required TandemCrewPairing crew,
    double technicalDifficulty = 30.0,
    double? cornerRadiusM,
    double gradientPercent = -8.0,
  }) {
    final double weightedConfidence =
        (crew.pilot.downhillConfidence * 0.68 +
                crew.stoker.downhillConfidence * 0.20 +
                crew.communicationChemistry * 0.12)
            .clamp(20.0, 100.0);

    final double skillFactor = weightedConfidence / 100.0;
    final double baseLimitKmh = 68.0 + skillFactor * 39.0; // do 107.0 km/h
    final double techPenaltyKmh =
        (technicalDifficulty.clamp(0.0, 100.0) / 100.0) *
            (1.0 - skillFactor * 0.65) *
            22.0;

    // Długi rozstaw osi tandemu stabilizuje jazdę na wprost przy dużych prędkościach.
    final double wheelbaseBonus =
        ((crew.tandemBike.wheelbaseM - 1.75) * 8.0).clamp(-2.0, 3.5);
    double safeKmh =
        (baseLimitKmh - techPenaltyKmh + wheelbaseBonus).clamp(42.0, 114.0);

    if (cornerRadiusM != null && cornerRadiusM > 1.0) {
      // Tandem ma wysoki środek ciężkości i mniejszą zwinność w ciasnych agrafkach.
      final double gripMu = 0.78 + skillFactor * 0.12;
      final double cornerLimitKmh =
          math.sqrt(gripMu * PhysicsConstants.gravity * cornerRadiusM) * 3.6;
      safeKmh = math.min(safeKmh, cornerLimitKmh);
    }

    return safeKmh;
  }

  /// Rozwiązuje krok dynamiki ruchu dla trójkołowego handbike'a (H1–H5).
  static HandbikePhysicsResult solveHandbikeStep(HandbikePhysicsInput input) {
    final double rawWatts = math.max(0.0, input.armCrankWatts);

    // Zmęczenie górnej partii ciała redukuje efektywną moc przenoszoną na korbę ręczną.
    final double enduranceMitigation =
        (input.athlete.upperBodyEndurance.clamp(1, 100) / 100.0) * 0.45;
    final double fatiguePenalty =
        input.upperBodyFatigueFactor.clamp(0.0, 0.85) *
            (1.0 - enduranceMitigation);
    final double fatigueMultiplier = (1.0 - fatiguePenalty).clamp(0.45, 1.0);

    // Optymalna kadencja ręczna to ~80-90 RPM.
    final double cadenceDelta = (input.crankCadenceRpm - 84.0).abs();
    final double cadenceEfficiency =
        (1.0 - math.max(0.0, cadenceDelta - 12.0) * 0.004).clamp(0.86, 1.0);

    final double drivetrainEff =
        input.bike.drivetrainEfficiency.clamp(0.88, 0.99) *
            (1.0 - _handbikeLongChainLoss);
    final double effectiveWheelWatts =
        rawWatts * fatigueMultiplier * cadenceEfficiency * drivetrainEff;

    // Na stromych podjazdach pozycja leżąca ma gorszą trakcję przedniego koła niż klęcząca H5.
    final HandbikePostureType posture = _resolvePosture(input);
    final double climbingTractionFactor = _computeHandbikeClimbingTraction(
      posture: posture,
      gradientPercent: input.gradientPercent,
    );
    final double tractionAdjustedWheelWatts =
        effectiveWheelWatts * climbingTractionFactor;

    final double totalMassKg =
        math.max(52.0, input.athlete.weightKg + input.bike.weightKg);
    final double airDensity =
        PhysicsConstants.getAirDensityAtAltitude(input.altitudeMeters);

    // Niski profil leżący H1–H4 daje mniejsze CdA niż pozycja klęcząca H5.
    final double baseCda = input.bike.cdaM2 > 0
        ? input.bike.cdaM2
        : input.athlete.sportClass.referenceCdaM2;
    final double yawPenalty =
        1.0 + math.min(0.15, (input.crosswindMs.abs() / 20.0) * 0.12);
    final double effectiveCdaM2 = baseCda * yawPenalty;

    // Trzy koła zwiększają bazowy opór toczenia o ~8% w stosunku do porównywalnego roweru 2-kołowego.
    final double effectiveCrr = (input.bike.crr *
            1.08 *
            input.surfaceCrrMultiplier.clamp(0.8, 3.5))
        .clamp(0.0025, 0.030);

    final double slopeRad = math.atan(input.gradientPercent / 100.0);
    final double gravityForceN =
        totalMassKg * PhysicsConstants.gravity * math.sin(slopeRad);
    final double rollingForceN = totalMassKg *
        PhysicsConstants.gravity *
        math.cos(slopeRad) *
        effectiveCrr;

    final double currentSpeedMs = math.max(0.0, input.currentSpeedMs);
    final double propulsionForceN = _computePropulsionForce(
      wheelWatts: tractionAdjustedWheelWatts,
      speedMs: currentSpeedMs,
      maxTractionN: _handbikeMaxTractionN,
    );

    final double aeroDragN = _computeAeroDrag(
      airDensity: airDensity,
      cdaM2: effectiveCdaM2,
      draftingFactor: input.draftingFactor.clamp(0.45, 1.0),
      speedMs: currentSpeedMs,
      headwindMs: input.headwindMs,
    );

    // Ocena stabilności poprzecznej 3-kołowego podwozia w zakręcie.
    final ({
      double lateralG,
      double maxSafeCornerKmh,
      HandbikeTurnStabilityZone zone,
      double scrubForceN,
    }) cornerEval = _evaluateHandbikeCornering(
      speedMs: currentSpeedMs,
      totalMassKg: totalMassKg,
      cornerRadiusM: input.cornerRadiusM,
      trackWidthM: input.trackWidthM,
      cogHeightM: input.bike.centerOfGravityHeightM,
      bikeHandling: input.athlete.bikeHandling,
    );

    final ({double speedMs, int iterations}) eqResult =
        _solveEquilibriumSpeed(
      wheelWatts: tractionAdjustedWheelWatts,
      gravityPlusRollingN:
          gravityForceN + rollingForceN + cornerEval.scrubForceN,
      airDensity: airDensity,
      cdaM2: effectiveCdaM2,
      draftingFactor: input.draftingFactor.clamp(0.45, 1.0),
      headwindMs: input.headwindMs,
      maxSpeedCapMs: 30.0,
    );

    final double dt = input.dtSeconds.clamp(0.05, 5.0);
    final double totalResistanceN =
        gravityForceN + rollingForceN + aeroDragN + cornerEval.scrubForceN;
    final double unbrakedNetForceN = propulsionForceN - totalResistanceN;
    final double unbrakedNextSpeedMs =
        math.max(0.0, currentSpeedMs + (unbrakedNetForceN / totalMassKg) * dt);

    double brakingForceN = 0.0;
    bool isCornerLimited = false;
    double newSpeedMs = unbrakedNextSpeedMs;
    final double maxCornerMs = cornerEval.maxSafeCornerKmh / 3.6;

    if (input.cornerRadiusM != null && unbrakedNextSpeedMs > maxCornerMs) {
      isCornerLimited = true;
      newSpeedMs = maxCornerMs;
      final double reqNetForce =
          ((newSpeedMs - currentSpeedMs) / dt) * totalMassKg;
      brakingForceN =
          math.max(0.0, propulsionForceN - totalResistanceN - reqNetForce);
    }

    final double finalNetForceN = unbrakedNetForceN - brakingForceN;
    final double finalAccelMs2 = finalNetForceN / totalMassKg;

    return HandbikePhysicsResult(
      sportClass: input.athlete.sportClass,
      posture: posture,
      armCrankInputWatts: rawWatts,
      effectiveWheelWatts: tractionAdjustedWheelWatts,
      totalSystemMassKg: totalMassKg,
      effectiveCdaM2: effectiveCdaM2,
      effectiveCrr: effectiveCrr,
      propulsionForceN: propulsionForceN,
      aeroDragForceN: aeroDragN,
      gravityForceN: gravityForceN,
      rollingResistanceForceN: rollingForceN,
      corneringScrubForceN: cornerEval.scrubForceN,
      brakingForceN: brakingForceN,
      netForceN: finalNetForceN,
      accelerationMs2: finalAccelMs2,
      newSpeedMs: newSpeedMs,
      equilibriumSpeedMs: eqResult.speedMs,
      lateralAccelerationG: cornerEval.lateralG,
      maxSafeCorneringSpeedKmh: cornerEval.maxSafeCornerKmh,
      turnStabilityZone: cornerEval.zone,
      isCorneringLimited: isCornerLimited,
      climbingTractionPenaltyFactor: climbingTractionFactor,
      solverIterations: eqResult.iterations,
    );
  }

  static ({double multiplier, TandemSyncPhase phase}) _evaluateTandemSync({
    required TandemCrewPairing crew,
    required double pilotCadenceRpm,
    required double stokerCadenceRpm,
  }) {
    final double cadenceDiff = (pilotCadenceRpm - stokerCadenceRpm).abs();
    final double cadencePenalty =
        (math.max(0.0, cadenceDiff - 2.0) * 0.008).clamp(0.0, 0.14);
    final double effectiveSync =
        (crew.synchronizationIndex - cadencePenalty).clamp(0.0, 1.0);
    final double multiplier = 0.88 + (effectiveSync * 0.14);

    final TandemSyncPhase phase;
    if (effectiveSync >= 0.88) {
      phase = TandemSyncPhase.synchronized;
    } else if (effectiveSync >= 0.72) {
      phase = TandemSyncPhase.marginalDrift;
    } else {
      phase = TandemSyncPhase.cadenceMismatch;
    }
    return (multiplier: multiplier, phase: phase);
  }

  static HandbikePostureType _resolvePosture(HandbikePhysicsInput input) {
    if (input.bike.handbikePosture != HandbikePostureType.notApplicable) {
      return input.bike.handbikePosture;
    }
    return input.athlete.sportClass == ParacyclingSportClass.h5
        ? HandbikePostureType.kneeling
        : HandbikePostureType.recumbentLow;
  }

  static double _computeHandbikeClimbingTraction({
    required HandbikePostureType posture,
    required double gradientPercent,
  }) {
    if (gradientPercent <= 6.0) {
      return 1.0;
    }
    final double excessGrade = gradientPercent - 6.0;
    final double lossPerPercent =
        posture == HandbikePostureType.kneeling ? 0.004 : 0.011;
    return (1.0 - excessGrade * lossPerPercent).clamp(0.84, 1.0);
  }

  static ({
    double lateralG,
    double maxSafeCornerKmh,
    HandbikeTurnStabilityZone zone,
    double scrubForceN,
  }) _evaluateHandbikeCornering({
    required double speedMs,
    required double totalMassKg,
    required double? cornerRadiusM,
    required double trackWidthM,
    required double cogHeightM,
    required int bikeHandling,
  }) {
    if (cornerRadiusM == null || cornerRadiusM <= 1.0) {
      return (
        lateralG: 0.0,
        maxSafeCornerKmh: 95.0,
        zone: HandbikeTurnStabilityZone.planted,
        scrubForceN: 0.0,
      );
    }

    final double safeCog = math.max(0.18, cogHeightM);
    final double staticStabilityFactor =
        (trackWidthM.clamp(0.55, 0.90) * 0.5) / safeCog;
    final double handlingBonus =
        0.92 + (bikeHandling.clamp(1, 100) / 100.0) * 0.16;
    final double maxTipG = (staticStabilityFactor * handlingBonus).clamp(0.45, 1.05);

    final double lateralG =
        (speedMs * speedMs) / (cornerRadiusM * PhysicsConstants.gravity);
    final double maxSafeSpeedMs =
        math.sqrt(maxTipG * PhysicsConstants.gravity * cornerRadiusM);

    final HandbikeTurnStabilityZone zone;
    if (lateralG >= maxTipG * 0.90) {
      zone = HandbikeTurnStabilityZone.tipOverCritical;
    } else if (lateralG >= maxTipG * 0.65) {
      zone = HandbikeTurnStabilityZone.innerWheelLiftRisk;
    } else {
      zone = HandbikeTurnStabilityZone.planted;
    }

    // Opór tarcia poprzecznego 3 opon podczas szybkiego pokonywania łuku.
    final double scrubForceN =
        totalMassKg * PhysicsConstants.gravity * lateralG * lateralG * 0.085;

    return (
      lateralG: lateralG,
      maxSafeCornerKmh: maxSafeSpeedMs * 3.6,
      zone: zone,
      scrubForceN: scrubForceN,
    );
  }

  static double _computePropulsionForce({
    required double wheelWatts,
    required double speedMs,
    required double maxTractionN,
  }) {
    if (wheelWatts <= 0.0) {
      return 0.0;
    }
    final double vEff = math.max(_minSpeedDenominatorMs, speedMs);
    return (wheelWatts / vEff).clamp(0.0, maxTractionN);
  }

  static double _computeAeroDrag({
    required double airDensity,
    required double cdaM2,
    required double draftingFactor,
    required double speedMs,
    required double headwindMs,
  }) {
    final double vRel = speedMs + headwindMs;
    final double sign = vRel >= 0 ? 1.0 : -1.0;
    return 0.5 * airDensity * cdaM2 * draftingFactor * sign * vRel * vRel;
  }

  /// Hybrydowy solver bisekcja + Newton-Raphson znajdujący prędkość ustaloną.
  static ({double speedMs, int iterations}) _solveEquilibriumSpeed({
    required double wheelWatts,
    required double gravityPlusRollingN,
    required double airDensity,
    required double cdaM2,
    required double draftingFactor,
    required double headwindMs,
    required double maxSpeedCapMs,
  }) {
    double f(double v) {
      final double vSafe = math.max(_minSpeedDenominatorMs, v);
      final double fProp = wheelWatts / vSafe;
      final double fAero = _computeAeroDrag(
        airDensity: airDensity,
        cdaM2: cdaM2,
        draftingFactor: draftingFactor,
        speedMs: v,
        headwindMs: headwindMs,
      );
      return fProp - (gravityPlusRollingN + fAero);
    }

    double low = _minSpeedDenominatorMs;
    double high = maxSpeedCapMs;
    double v = 12.0.clamp(low, high);
    int iterations = 0;

    for (int i = 0; i < 12; i++) {
      iterations = i + 1;
      final double fv = f(v);
      if (fv.abs() < 0.05) {
        break;
      }
      if (fv > 0) {
        low = v;
      } else {
        high = v;
      }

      final double vRel = v + headwindMs;
      final double dfAero = airDensity * cdaM2 * draftingFactor * vRel.abs();
      final double dfProp = -wheelWatts / (v * v);
      final double df = dfProp - dfAero;

      double nextV = df.abs() > 1e-6 ? v - fv / df : (low + high) * 0.5;
      if (nextV <= low || nextV >= high || nextV.isNaN) {
        nextV = (low + high) * 0.5;
      }
      v = nextV;
    }

    return (speedMs: v.clamp(low, maxSpeedCapMs), iterations: iterations);
  }

  static double _updateBrakeRotorTemperature({
    required double currentTempC,
    required double brakingForceN,
    required double speedMs,
    required double coolingRating,
    required double dtSeconds,
  }) {
    const double ambientC = 20.0;
    const double thermalMass = 680.0; // J/K dla dwóch dużych tarcz 203 mm
    final double heatWatts = brakingForceN * speedMs * 0.65;
    final double coolingCoeff =
        (6.0 + 4.5 * math.pow(math.max(1.0, speedMs), 0.6)) *
            coolingRating.clamp(0.5, 1.3);
    final double coolingWatts =
        coolingCoeff * math.max(0.0, currentTempC - ambientC);
    final double dTemp = ((heatWatts - coolingWatts) / thermalMass) * dtSeconds;
    return (currentTempC + dTemp).clamp(ambientC, 360.0);
  }

  static DescentThermalBrakeStatus _classifyBrakeTemp(double tempC) {
    if (tempC >= 275.0) {
      return DescentThermalBrakeStatus.thermalFade;
    }
    if (tempC >= 210.0) {
      return DescentThermalBrakeStatus.fadeWarning;
    }
    if (tempC >= 140.0) {
      return DescentThermalBrakeStatus.warm;
    }
    return DescentThermalBrakeStatus.nominal;
  }
}

/// Responsywny panel telemetryczny solvera fizyki tandemów Klasy B oraz handbike'ów H1–H5.
class TandemAndHandbikePhysicsPanel extends StatefulWidget {
  final TandemCrewPairing? initialTandemCrew;
  final ParacyclingAthleteProfile? initialHandbikeAthlete;
  final ParacyclingBikeSpec? initialHandbikeSpec;

  const TandemAndHandbikePhysicsPanel({
    super.key,
    this.initialTandemCrew,
    this.initialHandbikeAthlete,
    this.initialHandbikeSpec,
  });

  @override
  State<TandemAndHandbikePhysicsPanel> createState() =>
      _TandemAndHandbikePhysicsPanelState();
}

class _TandemAndHandbikePhysicsPanelState
    extends State<TandemAndHandbikePhysicsPanel> {
  ParacyclingPhysicsViewMode _viewMode =
      ParacyclingPhysicsViewMode.tandemPowerAndDescent;
  double _tandemCombinedWatts = 860.0;
  double _gradientPercent = -9.0;
  double _handbikeWatts = 245.0;
  double _cornerRadiusM = 32.0;
  bool _isKneelingH5 = false;

  late final TandemCrewPairing _crew;
  late final ParacyclingAthleteProfile _recumbentAthlete;
  late final ParacyclingAthleteProfile _kneelingAthlete;
  late final ParacyclingBikeSpec _recumbentBike;
  late final ParacyclingBikeSpec _kneelingBike;

  @override
  void initState() {
    super.initState();
    final fleet = ParacyclingBikeSpec.defaultFleet();
    final tandemBike = fleet.firstWhere(
      (b) => b.equipmentType == ParacyclingEquipmentType.tandemRoadBike,
    );
    _recumbentBike = widget.initialHandbikeSpec ??
        fleet.firstWhere(
          (b) => b.equipmentType == ParacyclingEquipmentType.recumbentHandbike,
        );
    _kneelingBike = fleet.firstWhere(
      (b) => b.equipmentType == ParacyclingEquipmentType.kneelingHandbike,
    );

    _crew = widget.initialTandemCrew ??
        TandemCrewPairing(
          id: 'default_tandem_b',
          pilot: const ParacyclingAthleteProfile(
            id: 'pilot_1',
            name: 'M. Kowalski',
            nationalityCode: 'POL',
            age: 29,
            sportClass: ParacyclingSportClass.b,
            gender: ParacyclingGenderCategory.men,
            ftpWatts: 435.0,
            peak5sWatts: 1180.0,
            vo2Max: 76.0,
            weightKg: 74.0,
            downhillConfidence: 94,
            bikeHandling: 92,
            isPilot: true,
          ),
          stoker: const ParacyclingAthleteProfile(
            id: 'stoker_1',
            name: 'A. Nowak',
            nationalityCode: 'POL',
            age: 27,
            sportClass: ParacyclingSportClass.b,
            gender: ParacyclingGenderCategory.men,
            ftpWatts: 415.0,
            peak5sWatts: 1140.0,
            vo2Max: 74.0,
            weightKg: 71.0,
            downhillConfidence: 88,
            bikeHandling: 82,
          ),
          synchronizationIndex: 0.96,
          communicationChemistry: 94,
          tandemBike: tandemBike,
        );

    _recumbentAthlete = widget.initialHandbikeAthlete ??
        const ParacyclingAthleteProfile(
          id: 'hb_h3',
          name: 'R. Wilk',
          nationalityCode: 'POL',
          age: 32,
          sportClass: ParacyclingSportClass.h3,
          gender: ParacyclingGenderCategory.men,
          ftpWatts: 245.0,
          peak5sWatts: 560.0,
          vo2Max: 61.0,
          weightKg: 66.0,
          upperBodyEndurance: 91,
          bikeHandling: 88,
        );

    _kneelingAthlete = _recumbentAthlete.copyWith(
      id: 'hb_h5',
      sportClass: ParacyclingSportClass.h5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 560;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 14),
              _buildModeSelector(isCompact),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: _viewMode ==
                        ParacyclingPhysicsViewMode.tandemPowerAndDescent
                    ? _buildTandemTelemetry(isCompact)
                    : _buildHandbikeTelemetry(isCompact),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent, width: 1.0),
          ),
          child: const Icon(
            Icons.speed_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solver Fizyki Tandemów i Handbike\'ów',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'UCI Para-Cycling • Klasa B (>800 W / >95 km/h) • H1–H5 Aero',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ParacyclingPhysicsViewMode.values.map((mode) {
        final bool selected = _viewMode == mode;
        return _InteractiveModeButton(
          label: mode.labelPl,
          selected: selected,
          onTap: () => setState(() => _viewMode = mode),
        );
      }).toList(),
    );
  }

  Widget _buildTandemTelemetry(bool isCompact) {
    final double halfWatts = _tandemCombinedWatts * 0.5;
    final TandemPhysicsResult flatResult =
        TandemAndHandbikePhysicsSolver.solveTandemStep(
      TandemPhysicsInput(
        crew: _crew,
        pilotTargetWatts: halfWatts,
        stokerTargetWatts: halfWatts,
        currentSpeedMs: 16.5,
        gradientPercent: 0.0,
      ),
    );
    final TandemDescentSimulationSummary descentSummary =
        TandemAndHandbikePhysicsSolver.simulateTandemDescent(
      crew: _crew,
      gradientPercent: _gradientPercent,
      pilotWatts: 250.0,
      stokerWatts: 240.0,
      durationSeconds: 32.0,
    );

    final List<Widget> cards = [
      _MetricTile(
        title: 'Moc Łączna Duetu',
        value: '${flatResult.combinedInputWatts.toStringAsFixed(0)} W',
        subtitle: flatResult.isOver800Watts
            ? 'Strefa >800 W • Sync ${(flatResult.syncEfficiencyMultiplier * 100).toStringAsFixed(1)}%'
            : 'Sync ${flatResult.syncPhase.labelPl}',
        accentColor: flatResult.isOver800Watts
            ? AppColors.goldAccent
            : AppColors.accentBlue,
      ),
      _MetricTile(
        title: 'Prędkość na Płaskim',
        value: '${flatResult.equilibriumSpeedKmh.toStringAsFixed(1)} km/h',
        subtitle:
            'CdA ${flatResult.effectiveCdaM2.toStringAsFixed(3)} m² • Masa ${flatResult.totalSystemMassKg.toStringAsFixed(0)} kg',
        accentColor: AppColors.cyanAccent,
      ),
      _MetricTile(
        title: 'Szczyt Zjazdu (${_gradientPercent.toStringAsFixed(1)}%)',
        value: '${descentSummary.peakSpeedKmh.toStringAsFixed(1)} km/h',
        subtitle: descentSummary.exceeded95Kmh
            ? 'Przekroczono 95 km/h • Tarcze ${descentSummary.peakRotorTempCelsius.toStringAsFixed(0)}°C'
            : 'Tarcze ${descentSummary.peakRotorTempCelsius.toStringAsFixed(0)}°C (${descentSummary.finalBrakeStatus.labelPl})',
        accentColor: descentSummary.exceeded95Kmh
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
      ),
    ];

    return Column(
      key: const ValueKey('tandem_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResponsiveMetrics(cards, isCompact),
        const SizedBox(height: 12),
        _buildSliderRow(
          label: 'Moc Tandemu (${_tandemCombinedWatts.toStringAsFixed(0)} W)',
          value: _tandemCombinedWatts,
          min: 500.0,
          max: 1200.0,
          onChanged: (v) => setState(() => _tandemCombinedWatts = v),
        ),
        _buildSliderRow(
          label: 'Nachylenie Zjazdu (${_gradientPercent.toStringAsFixed(1)}%)',
          value: _gradientPercent,
          min: -12.0,
          max: -3.0,
          onChanged: (v) => setState(() => _gradientPercent = v),
        ),
      ],
    );
  }

  Widget _buildHandbikeTelemetry(bool isCompact) {
    final athlete = _isKneelingH5 ? _kneelingAthlete : _recumbentAthlete;
    final bike = _isKneelingH5 ? _kneelingBike : _recumbentBike;

    final HandbikePhysicsResult result =
        TandemAndHandbikePhysicsSolver.solveHandbikeStep(
      HandbikePhysicsInput(
        athlete: athlete,
        bike: bike,
        armCrankWatts: _handbikeWatts,
        currentSpeedMs: 11.5,
        cornerRadiusM: _cornerRadiusM,
      ),
    );

    final List<Widget> cards = [
      _MetricTile(
        title: 'Klasa ${result.sportClass.code}',
        value: '${result.equilibriumSpeedKmh.toStringAsFixed(1)} km/h',
        subtitle:
            'CdA ${result.effectiveCdaM2.toStringAsFixed(3)} m² • Crr ${result.effectiveCrr.toStringAsFixed(4)}',
        accentColor: AppColors.cyanAccent,
      ),
      _MetricTile(
        title: 'Stabilność 3-Kołowa',
        value: '${result.lateralAccelerationG.toStringAsFixed(2)} G',
        subtitle:
            '${result.turnStabilityZone.labelPl} (max ${result.maxSafeCorneringSpeedKmh.toStringAsFixed(1)} km/h)',
        accentColor: result.turnStabilityZone.color,
      ),
      _MetricTile(
        title: 'Moc Efektywna na Kole',
        value: '${result.effectiveWheelWatts.toStringAsFixed(0)} W',
        subtitle: 'Masa układu ${result.totalSystemMassKg.toStringAsFixed(1)} kg',
        accentColor: AppColors.goldAccent,
      ),
    ];

    return Column(
      key: const ValueKey('handbike_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResponsiveMetrics(cards, isCompact),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InteractiveModeButton(
              label: 'Leżący H3 (CdA 0.192)',
              selected: !_isKneelingH5,
              onTap: () => setState(() => _isKneelingH5 = false),
            ),
            _InteractiveModeButton(
              label: 'Klęczący H5 (CdA 0.242)',
              selected: _isKneelingH5,
              onTap: () => setState(() => _isKneelingH5 = true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSliderRow(
          label: 'Moc Korby Ręcznej (${_handbikeWatts.toStringAsFixed(0)} W)',
          value: _handbikeWatts,
          min: 120.0,
          max: 380.0,
          onChanged: (v) => setState(() => _handbikeWatts = v),
        ),
        _buildSliderRow(
          label: 'Promień Zakrętu (${_cornerRadiusM.toStringAsFixed(0)} m)',
          value: _cornerRadiusM,
          min: 14.0,
          max: 80.0,
          onChanged: (v) => setState(() => _cornerRadiusM = v),
        ),
      ],
    );
  }

  Widget _buildResponsiveMetrics(List<Widget> cards, bool isCompact) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryAccent,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.goldAccent,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractiveModeButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _InteractiveModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveModeButton> createState() => _InteractiveModeButtonState();
}

class _InteractiveModeButtonState extends State<_InteractiveModeButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null;
    final Color bgColor = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.45 : 0.30)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.primaryAccent
            : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: disabled ? AppColors.background : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                  : widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
