// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pozycja aerodynamiczna kolarza determinująca kąt biodra, klatki piersiowej i bazowe CdA.
enum AeroTuckPosturePreset {
  uprightRoadHoods(
    'Szosowa (Hoods)',
    'Road Hoods',
    torsoAngleDeg: 32.0,
    hipAngleDeg: 58.0,
    cdaMultiplier: 1.00,
    basePowerDropPct: 0.0,
    neckCoreDemand: 0.15,
  ),
  aggressiveDrops(
    'Dolny chwyt (Drops)',
    'Aggressive Drops',
    torsoAngleDeg: 21.0,
    hipAngleDeg: 50.0,
    cdaMultiplier: 0.87,
    basePowerDropPct: 2.2,
    neckCoreDemand: 0.35,
  ),
  standardTtExtensions(
    'Leżak TT (Standard)',
    'Standard TT Extensions',
    torsoAngleDeg: 11.0,
    hipAngleDeg: 43.0,
    cdaMultiplier: 0.76,
    basePowerDropPct: 6.4,
    neckCoreDemand: 0.65,
  ),
  extremeLowPrayingMantis(
    'Niski TT (Praying Mantis)',
    'Extreme Low Praying Mantis',
    torsoAngleDeg: 4.5,
    hipAngleDeg: 37.5,
    cdaMultiplier: 0.69,
    basePowerDropPct: 10.5,
    neckCoreDemand: 0.90,
  ),
  superTuckAero(
    'Aero Puppy-Paws',
    'Aero Puppy-Paws',
    torsoAngleDeg: 7.0,
    hipAngleDeg: 40.0,
    cdaMultiplier: 0.73,
    basePowerDropPct: 8.2,
    neckCoreDemand: 0.82,
  );

  final String labelPl;
  final String labelEn;
  final double torsoAngleDeg;
  final double hipAngleDeg;
  final double cdaMultiplier;
  final double basePowerDropPct;
  final double neckCoreDemand;

  const AeroTuckPosturePreset(
    this.labelPl,
    this.labelEn, {
    required this.torsoAngleDeg,
    required this.hipAngleDeg,
    required this.cdaMultiplier,
    required this.basePowerDropPct,
    required this.neckCoreDemand,
  });
}

/// Pojazd prowadzący podczas treningu motor-pacing (za skuterem / Derny).
enum MotorPacingVehicleType {
  derny50cc(
    'Derny 50cc (Tor / Szosa)',
    'Derny 50cc',
    draftSavingsBase: 0.42,
    optimalSpeedKmh: 54.0,
    cadenceStimulusFactor: 1.15,
  ),
  vespaScooter125(
    'Skuter 125cc (Szosa)',
    'Scooter 125cc',
    draftSavingsBase: 0.48,
    optimalSpeedKmh: 60.0,
    cadenceStimulusFactor: 1.25,
  ),
  teamCarDraft(
    'Wóz techniczny (Wysokie prędkości)',
    'Team Car Draft',
    draftSavingsBase: 0.56,
    optimalSpeedKmh: 66.0,
    cadenceStimulusFactor: 1.18,
  ),
  soloNoMotor(
    'Trening solo (bez skutera)',
    'Solo (No Motor)',
    draftSavingsBase: 0.0,
    optimalSpeedKmh: 44.0,
    cadenceStimulusFactor: 0.65,
  );

  final String labelPl;
  final String labelEn;
  final double draftSavingsBase;
  final double optimalSpeedKmh;
  final double cadenceStimulusFactor;

  const MotorPacingVehicleType(
    this.labelPl,
    this.labelEn, {
    required this.draftSavingsBase,
    required this.optimalSpeedKmh,
    required this.cadenceStimulusFactor,
  });
}

/// Protokół jednostki treningowej za skuterem.
enum MotorPacingSessionProtocol {
  highCadenceOverspeed(
    'Nadprędkość & Wysoka Kadencja (105–115 RPM)',
    'High-Cadence Overspeed',
    defaultIntensityFtp: 0.82,
    defaultCadenceRpm: 110.0,
    neuromuscularWeight: 1.30,
    hipFlexorWeight: 1.00,
    respiratoryWeight: 0.90,
  ),
  ttThresholdBehindDerny(
    'Próg LT2 w Pozycji TT (95–102 RPM)',
    'TT Threshold Behind Derny',
    defaultIntensityFtp: 0.96,
    defaultCadenceRpm: 98.0,
    neuromuscularWeight: 1.05,
    hipFlexorWeight: 1.30,
    respiratoryWeight: 1.25,
  ),
  raceSimulationOvergear(
    'Symulacja Przełożeń Wyścigowych (88–94 RPM)',
    'Race Simulation Torque',
    defaultIntensityFtp: 1.02,
    defaultCadenceRpm: 91.0,
    neuromuscularWeight: 0.90,
    hipFlexorWeight: 1.20,
    respiratoryWeight: 1.30,
  ),
  recoverySpin(
    'Rozjazd Adaptacyjny (92–98 RPM)',
    'Adaptive Recovery Spin',
    defaultIntensityFtp: 0.65,
    defaultCadenceRpm: 95.0,
    neuromuscularWeight: 0.65,
    hipFlexorWeight: 0.85,
    respiratoryWeight: 0.55,
  );

  final String labelPl;
  final String labelEn;
  final double defaultIntensityFtp;
  final double defaultCadenceRpm;
  final double neuromuscularWeight;
  final double hipFlexorWeight;
  final double respiratoryWeight;

  const MotorPacingSessionProtocol(
    this.labelPl,
    this.labelEn, {
    required this.defaultIntensityFtp,
    required this.defaultCadenceRpm,
    required this.neuromuscularWeight,
    required this.hipFlexorWeight,
    required this.respiratoryWeight,
  });
}

/// Poziom fizjologicznej adaptacji kolarza do generowania mocy w niskiej pozycji TT.
enum AeroAdaptationTier {
  unadapted('Niezaadaptowany', 'Unadapted'),
  developing('W trakcie adaptacji', 'Developing'),
  raceReady('Gotowy do ITT', 'Race Ready'),
  worldTourTtSpecialist('Specjalista WorldTour TT', 'WorldTour TT Specialist');

  final String labelPl;
  final String labelEn;

  const AeroAdaptationTier(this.labelPl, this.labelEn);
}

/// Ryzyko załamania pozycji aerodynamicznej z powodu zmęczenia karku i korpusu.
enum PostureBreakdownRisk {
  rockSolid('Stabilna sylwetka', 'Rock Solid'),
  mildCreep('Lekkie podnoszenie głowy', 'Mild Creep'),
  neckCoreFatigue('Zmęczenie karku i core', 'Neck & Core Fatigue'),
  aeroCollapse('Załamanie pozycji TT', 'Aero Collapse');

  final String labelPl;
  final String labelEn;

  const PostureBreakdownRisk(this.labelPl, this.labelEn);
}

/// Profil fizjologicznej adaptacji kolarza do niskiej pozycji aerodynamicznej TT.
class RiderAeroAdaptationProfile {
  final String riderId;
  final String riderName;
  final double uprightFtpWatts;
  final double massKg;
  final double hipMobilityScore;
  final double coreAndNeckEndurance;
  final double diaphragmEfficiency;
  final double adaptationScore;
  final int motorPacingSessionsCompleted;
  final double cumulativeAeroTuckMinutes;
  final int daysSinceLastAeroSession;
  final AeroTuckPosturePreset preferredPosture;

  const RiderAeroAdaptationProfile({
    required this.riderId,
    required this.riderName,
    required this.uprightFtpWatts,
    this.massKg = 71.0,
    this.hipMobilityScore = 0.55,
    this.coreAndNeckEndurance = 0.50,
    this.diaphragmEfficiency = 0.55,
    this.adaptationScore = 0.20,
    this.motorPacingSessionsCompleted = 0,
    this.cumulativeAeroTuckMinutes = 0.0,
    this.daysSinceLastAeroSession = 0,
    this.preferredPosture = AeroTuckPosturePreset.standardTtExtensions,
  });

  AeroAdaptationTier get tier {
    if (adaptationScore >= 0.82) {
      return AeroAdaptationTier.worldTourTtSpecialist;
    }
    if (adaptationScore >= 0.55) {
      return AeroAdaptationTier.raceReady;
    }
    if (adaptationScore >= 0.25) {
      return AeroAdaptationTier.developing;
    }
    return AeroAdaptationTier.unadapted;
  }

  RiderAeroAdaptationProfile copyWith({
    String? riderId,
    String? riderName,
    double? uprightFtpWatts,
    double? massKg,
    double? hipMobilityScore,
    double? coreAndNeckEndurance,
    double? diaphragmEfficiency,
    double? adaptationScore,
    int? motorPacingSessionsCompleted,
    double? cumulativeAeroTuckMinutes,
    int? daysSinceLastAeroSession,
    AeroTuckPosturePreset? preferredPosture,
  }) {
    return RiderAeroAdaptationProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      uprightFtpWatts: uprightFtpWatts ?? this.uprightFtpWatts,
      massKg: massKg ?? this.massKg,
      hipMobilityScore: hipMobilityScore ?? this.hipMobilityScore,
      coreAndNeckEndurance: coreAndNeckEndurance ?? this.coreAndNeckEndurance,
      diaphragmEfficiency: diaphragmEfficiency ?? this.diaphragmEfficiency,
      adaptationScore: adaptationScore ?? this.adaptationScore,
      motorPacingSessionsCompleted:
          motorPacingSessionsCompleted ?? this.motorPacingSessionsCompleted,
      cumulativeAeroTuckMinutes:
          cumulativeAeroTuckMinutes ?? this.cumulativeAeroTuckMinutes,
      daysSinceLastAeroSession:
          daysSinceLastAeroSession ?? this.daysSinceLastAeroSession,
      preferredPosture: preferredPosture ?? this.preferredPosture,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'uprightFtpWatts': uprightFtpWatts,
      'massKg': massKg,
      'hipMobilityScore': hipMobilityScore,
      'coreAndNeckEndurance': coreAndNeckEndurance,
      'diaphragmEfficiency': diaphragmEfficiency,
      'adaptationScore': adaptationScore,
      'motorPacingSessionsCompleted': motorPacingSessionsCompleted,
      'cumulativeAeroTuckMinutes': cumulativeAeroTuckMinutes,
      'daysSinceLastAeroSession': daysSinceLastAeroSession,
      'preferredPosture': preferredPosture.name,
    };
  }

  factory RiderAeroAdaptationProfile.fromJson(Map<String, dynamic> json) {
    final postureName = json['preferredPosture'] as String?;
    final posture = AeroTuckPosturePreset.values.firstWhere(
      (p) => p.name == postureName,
      orElse: () => AeroTuckPosturePreset.standardTtExtensions,
    );
    return RiderAeroAdaptationProfile(
      riderId: (json['riderId'] as String?) ?? 'rider_0',
      riderName: (json['riderName'] as String?) ?? 'Unknown Rider',
      uprightFtpWatts: ((json['uprightFtpWatts'] as num?) ?? 380.0).toDouble(),
      massKg: ((json['massKg'] as num?) ?? 71.0).toDouble(),
      hipMobilityScore: ((json['hipMobilityScore'] as num?) ?? 0.55).toDouble(),
      coreAndNeckEndurance:
          ((json['coreAndNeckEndurance'] as num?) ?? 0.50).toDouble(),
      diaphragmEfficiency:
          ((json['diaphragmEfficiency'] as num?) ?? 0.55).toDouble(),
      adaptationScore: ((json['adaptationScore'] as num?) ?? 0.20).toDouble(),
      motorPacingSessionsCompleted:
          ((json['motorPacingSessionsCompleted'] as num?) ?? 0).toInt(),
      cumulativeAeroTuckMinutes:
          ((json['cumulativeAeroTuckMinutes'] as num?) ?? 0.0).toDouble(),
      daysSinceLastAeroSession:
          ((json['daysSinceLastAeroSession'] as num?) ?? 0).toInt(),
      preferredPosture: posture,
    );
  }
}

/// Parametry pojedynczego treningu za skuterem / Derny w pozycji TT.
class MotorPacingSessionInput {
  final MotorPacingVehicleType vehicleType;
  final MotorPacingSessionProtocol protocol;
  final AeroTuckPosturePreset posture;
  final double durationMinutes;
  final double targetSpeedKmh;
  final double averageCadenceRpm;
  final double intensityFtpRatio;
  final double draftDistanceMeters;
  final double ambientTempC;

  const MotorPacingSessionInput({
    this.vehicleType = MotorPacingVehicleType.vespaScooter125,
    this.protocol = MotorPacingSessionProtocol.ttThresholdBehindDerny,
    this.posture = AeroTuckPosturePreset.standardTtExtensions,
    this.durationMinutes = 75.0,
    this.targetSpeedKmh = 58.0,
    this.averageCadenceRpm = 102.0,
    this.intensityFtpRatio = 0.92,
    this.draftDistanceMeters = 1.1,
    this.ambientTempC = 20.0,
  });

  MotorPacingSessionInput copyWith({
    MotorPacingVehicleType? vehicleType,
    MotorPacingSessionProtocol? protocol,
    AeroTuckPosturePreset? posture,
    double? durationMinutes,
    double? targetSpeedKmh,
    double? averageCadenceRpm,
    double? intensityFtpRatio,
    double? draftDistanceMeters,
    double? ambientTempC,
  }) {
    return MotorPacingSessionInput(
      vehicleType: vehicleType ?? this.vehicleType,
      protocol: protocol ?? this.protocol,
      posture: posture ?? this.posture,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      targetSpeedKmh: targetSpeedKmh ?? this.targetSpeedKmh,
      averageCadenceRpm: averageCadenceRpm ?? this.averageCadenceRpm,
      intensityFtpRatio: intensityFtpRatio ?? this.intensityFtpRatio,
      draftDistanceMeters: draftDistanceMeters ?? this.draftDistanceMeters,
      ambientTempC: ambientTempC ?? this.ambientTempC,
    );
  }
}

/// Wynik pojedynczej sesji treningowej za skuterem.
class MotorPacingTrainingResult {
  final RiderAeroAdaptationProfile updatedProfile;
  final double adaptationGain;
  final double detrainingDecayApplied;
  final double effectiveRiderPowerWatts;
  final double soloEquivalentPowerWatts;
  final double neuromuscularCadenceStimulus;
  final double hipAngleCompressionStress;
  final double respiratoryAdaptationStimulus;
  final double trainingStressScoreTss;
  final String sessionSummaryPl;
  final String sessionSummaryEn;

  const MotorPacingTrainingResult({
    required this.updatedProfile,
    required this.adaptationGain,
    required this.detrainingDecayApplied,
    required this.effectiveRiderPowerWatts,
    required this.soloEquivalentPowerWatts,
    required this.neuromuscularCadenceStimulus,
    required this.hipAngleCompressionStress,
    required this.respiratoryAdaptationStimulus,
    required this.trainingStressScoreTss,
    required this.sessionSummaryPl,
    required this.sessionSummaryEn,
  });
}

/// Dane wejściowe do obliczenia rzeczywistej mocy i prędkości w niskiej pozycji TT.
class AeroTuckPowerAndCdaInput {
  final RiderAeroAdaptationProfile profile;
  final AeroTuckPosturePreset posture;
  final double elapsedTtMinutes;
  final double targetEffortFtpRatio;
  final double cadenceRpm;
  final double baselineRoadCda;
  final double airDensityKgM3;
  final double rollingResistanceCoeff;
  final double roadGradient;

  const AeroTuckPowerAndCdaInput({
    required this.profile,
    this.posture = AeroTuckPosturePreset.standardTtExtensions,
    this.elapsedTtMinutes = 25.0,
    this.targetEffortFtpRatio = 1.0,
    this.cadenceRpm = 96.0,
    this.baselineRoadCda = 0.285,
    this.airDensityKgM3 = 1.225,
    this.rollingResistanceCoeff = 0.0032,
    this.roadGradient = 0.0,
  });
}

/// Rezultat oceny wydajności fizjologicznej i aerodynamicznej w pozycji TT.
class AeroTuckPowerAndCdaResult {
  final double effectiveSustainablePowerWatts;
  final double unadaptedPowerDropPercent;
  final double actualPowerDropPercent;
  final double powerRecoveredByAdaptationWatts;
  final double effectiveCda;
  final double cdaPenaltyFromFatigue;
  final double predictedTtSpeedKmh;
  final double speedGainOverUnadaptedKmh;
  final double timeSavedOver40KmSeconds;
  final double hipOcclusionFactor;
  final double respiratoryCostFactor;
  final double postureStabilityRemaining;
  final PostureBreakdownRisk breakdownRisk;
  final AeroAdaptationTier adaptationTier;

  const AeroTuckPowerAndCdaResult({
    required this.effectiveSustainablePowerWatts,
    required this.unadaptedPowerDropPercent,
    required this.actualPowerDropPercent,
    required this.powerRecoveredByAdaptationWatts,
    required this.effectiveCda,
    required this.cdaPenaltyFromFatigue,
    required this.predictedTtSpeedKmh,
    required this.speedGainOverUnadaptedKmh,
    required this.timeSavedOver40KmSeconds,
    required this.hipOcclusionFactor,
    required this.respiratoryCostFactor,
    required this.postureStabilityRemaining,
    required this.breakdownRisk,
    required this.adaptationTier,
  });
}

/// Pojedynczy krok symulacji wielotygodniowego bloku treningowego za skuterem.
class MotorPacingBlockPlanStep {
  final int sessionIndex;
  final MotorPacingSessionProtocol protocol;
  final double adaptationScoreAfter;
  final double ttSustainablePowerWatts;
  final double predicted40KmSpeedKmh;
  final double predicted40KmTimeSeconds;

  const MotorPacingBlockPlanStep({
    required this.sessionIndex,
    required this.protocol,
    required this.adaptationScoreAfter,
    required this.ttSustainablePowerWatts,
    required this.predicted40KmSpeedKmh,
    required this.predicted40KmTimeSeconds,
  });
}

/// Podsumowanie całego bloku treningowego motor-pacing.
class MotorPacingBlockSimulationResult {
  final RiderAeroAdaptationProfile initialProfile;
  final RiderAeroAdaptationProfile finalProfile;
  final List<MotorPacingBlockPlanStep> steps;
  final double totalAdaptationGain;
  final double totalPowerRecoveredWatts;
  final double total40KmTimeGainSeconds;

  const MotorPacingBlockSimulationResult({
    required this.initialProfile,
    required this.finalProfile,
    required this.steps,
    required this.totalAdaptationGain,
    required this.totalPowerRecoveredWatts,
    required this.total40KmTimeGainSeconds,
  });
}

/// Silnik fizjologicznej adaptacji generowania mocy w niskiej pozycji TT po treningach za skuterem.
class MotorPacingAndAeroTuckAdaptation {
  static const double _gravity = 9.80665;
  static const double _bikeAndGearMassKg = 7.8;
  static const double _drivetrainEfficiency = 0.975;

  const MotorPacingAndAeroTuckAdaptation();

  /// Oblicza fizjologiczną redukcję mocy oraz efektywne CdA w wybranej pozycji TT.
  AeroTuckPowerAndCdaResult evaluateAeroTuckPerformance(
    AeroTuckPowerAndCdaInput input,
  ) {
    final profile = input.profile;
    final posture = input.posture;
    final adaptation = profile.adaptationScore.clamp(0.0, 1.0);
    final effortRatio = input.targetEffortFtpRatio.clamp(0.4, 1.5);
    final elapsedMin = math.max(0.0, input.elapsedTtMinutes);

    // 1. Bazowy spadek mocy w danej pozycji bez adaptacji (%).
    final baseDropPct = posture.basePowerDropPct;

    // 2. Czynnik okluzji biodrowej (kompresja tętnicy udowej i zmiana krzywej siły).
    final hipCompressionRaw =
        ((58.0 - posture.hipAngleDeg) / 22.0).clamp(0.0, 1.0);
    final hipOcclusionFactor = (hipCompressionRaw *
            (1.0 - 0.55 * profile.hipMobilityScore) *
            (1.0 - 0.45 * adaptation))
        .clamp(0.0, 1.0);

    // 3. Koszt oddechowy przepony w zamkniętej klatce piersiowej (nasila się powyżej LT2).
    final ventilationDemand =
        ((effortRatio - 0.70) / 0.40).clamp(0.15, 1.25);
    final respiratoryCostFactor = (hipCompressionRaw *
            ventilationDemand *
            (1.0 - 0.50 * profile.diaphragmEfficiency) *
            (1.0 - 0.48 * adaptation))
        .clamp(0.0, 1.0);

    // 4. Wpływ kadencji (wysoka kadencja 95-105 RPM w TT zmniejsza szczytowy moment w martwym punkcie).
    final cadenceDelta = (input.cadenceRpm - 96.0).abs();
    final cadencePenaltyPct =
        (cadenceDelta > 12.0) ? ((cadenceDelta - 12.0) * 0.08).clamp(0.0, 2.5) : 0.0;

    // 5. Faktyczny spadek mocy po uwzględnieniu adaptacji za skuterem (nawet u specjalistów zostaje ~12% bazowej straty w ekstremalnym TT).
    final residualFraction = 1.0 - (0.86 * adaptation);
    final biomechModulation = 0.65 + 0.35 * (hipOcclusionFactor + respiratoryCostFactor) * 0.5;
    final actualDropPct = (baseDropPct * residualFraction * biomechModulation +
            cadencePenaltyPct)
        .clamp(0.0, 18.0);
    final unadaptedDropPct =
        (baseDropPct * (1.0 + 0.15 * hipCompressionRaw) + cadencePenaltyPct)
            .clamp(0.0, 20.0);

    final nominalTargetWatts =
        math.max(50.0, profile.uprightFtpWatts * effortRatio);
    final effectivePowerWatts =
        nominalTargetWatts * (1.0 - actualDropPct / 100.0);
    final unadaptedPowerWatts =
        nominalTargetWatts * (1.0 - unadaptedDropPct / 100.0);
    final recoveredWatts =
        math.max(0.0, effectivePowerWatts - unadaptedPowerWatts);

    // 6. Stabilność pozycji karku i korpusu w czasie (zapobiega "podnoszeniu głowy" i skokowi CdA).
    final enduranceCapacityMin = 18.0 +
        (profile.coreAndNeckEndurance * 34.0) +
        (adaptation * 38.0);
    final fatigueRatio =
        (elapsedMin * posture.neckCoreDemand) / math.max(10.0, enduranceCapacityMin);
    final stabilityRemaining = (1.0 - math.pow(fatigueRatio, 1.45)).clamp(0.0, 1.0);

    final PostureBreakdownRisk breakdownRisk;
    if (stabilityRemaining >= 0.72) {
      breakdownRisk = PostureBreakdownRisk.rockSolid;
    } else if (stabilityRemaining >= 0.45) {
      breakdownRisk = PostureBreakdownRisk.mildCreep;
    } else if (stabilityRemaining >= 0.22) {
      breakdownRisk = PostureBreakdownRisk.neckCoreFatigue;
    } else {
      breakdownRisk = PostureBreakdownRisk.aeroCollapse;
    }

    final basePostureCda = input.baselineRoadCda * posture.cdaMultiplier;
    final cdaPenalty = (1.0 - stabilityRemaining) * 0.048 * posture.neckCoreDemand;
    final effectiveCda = (basePostureCda + cdaPenalty).clamp(0.165, 0.420);

    final totalMassKg = profile.massKg + _bikeAndGearMassKg;
    final predictedSpeedMs = solveSpeedFromPower(
      powerWatts: effectivePowerWatts,
      cda: effectiveCda,
      totalMassKg: totalMassKg,
      airDensityKgM3: input.airDensityKgM3,
      rollingResistanceCoeff: input.rollingResistanceCoeff,
      roadGradient: input.roadGradient,
    );

    // Porównanie z niezaadaptowanym kolarzem (adaptation = 0.0, wyższy spadek mocy i wyższy rozkład pozycji).
    final unadaptedCda = basePostureCda + (0.032 * posture.neckCoreDemand);
    final unadaptedSpeedMs = solveSpeedFromPower(
      powerWatts: unadaptedPowerWatts,
      cda: unadaptedCda,
      totalMassKg: totalMassKg,
      airDensityKgM3: input.airDensityKgM3,
      rollingResistanceCoeff: input.rollingResistanceCoeff,
      roadGradient: input.roadGradient,
    );

    final predictedSpeedKmh = predictedSpeedMs * 3.6;
    final unadaptedSpeedKmh = unadaptedSpeedMs * 3.6;
    final speedGainKmh = predictedSpeedKmh - unadaptedSpeedKmh;

    final timeAdapted40KmSec =
        predictedSpeedMs > 0.5 ? 40000.0 / predictedSpeedMs : 7200.0;
    final timeUnadapted40KmSec =
        unadaptedSpeedMs > 0.5 ? 40000.0 / unadaptedSpeedMs : 7200.0;
    final timeSavedSec =
        math.max(0.0, timeUnadapted40KmSec - timeAdapted40KmSec);

    return AeroTuckPowerAndCdaResult(
      effectiveSustainablePowerWatts: effectivePowerWatts,
      unadaptedPowerDropPercent: unadaptedDropPct,
      actualPowerDropPercent: actualDropPct,
      powerRecoveredByAdaptationWatts: recoveredWatts,
      effectiveCda: effectiveCda,
      cdaPenaltyFromFatigue: cdaPenalty,
      predictedTtSpeedKmh: predictedSpeedKmh,
      speedGainOverUnadaptedKmh: speedGainKmh,
      timeSavedOver40KmSeconds: timeSavedSec,
      hipOcclusionFactor: hipOcclusionFactor,
      respiratoryCostFactor: respiratoryCostFactor,
      postureStabilityRemaining: stabilityRemaining,
      breakdownRisk: breakdownRisk,
      adaptationTier: profile.tier,
    );
  }

  /// Aplikuje pojedynczą sesję treningu za skuterem / Derny i zwraca zaktualizowany profil kolarza.
  MotorPacingTrainingResult applyMotorPacingSession(
    RiderAeroAdaptationProfile profile,
    MotorPacingSessionInput session,
  ) {
    // Najpierw ewentualny spadek adaptacji z powodu przerwy od ostatniej sesji.
    final decayedProfile = applyDetrainingDecay(
      profile,
      profile.daysSinceLastAeroSession,
    );
    final decayApplied =
        (profile.adaptationScore - decayedProfile.adaptationScore)
            .clamp(0.0, 1.0);

    final durationMin = session.durationMinutes.clamp(10.0, 240.0);
    final speedMs = (session.targetSpeedKmh.clamp(25.0, 80.0)) / 3.6;
    final draftDist = session.draftDistanceMeters.clamp(0.4, 5.0);

    // Efekt cienia aerodynamicznego za pojazdem prowadzącym (maleje wraz z odległością).
    final distanceFactor = math.exp(-0.28 * (draftDist - 0.6)).clamp(0.20, 1.0);
    final draftSavings =
        (session.vehicleType.draftSavingsBase * distanceFactor).clamp(0.0, 0.65);

    final soloCda = 0.285 * session.posture.cdaMultiplier;
    final totalMassKg = decayedProfile.massKg + _bikeAndGearMassKg;
    final soloEquivalentWatts = computeRequiredPowerForSpeed(
      speedMs: speedMs,
      cda: soloCda,
      totalMassKg: totalMassKg,
    );

    // Realna moc na pedałach za skuterem (z uwzględnieniem wybranej intensywności protokołu).
    final draftPowerWatts = soloEquivalentWatts * (1.0 - draftSavings);
    final targetProtocolWatts =
        decayedProfile.uprightFtpWatts * session.intensityFtpRatio;
    final effectiveRiderPowerWatts =
        (draftPowerWatts * 0.45 + targetProtocolWatts * 0.55)
            .clamp(80.0, decayedProfile.uprightFtpWatts * 1.35);

    // Bodziec nerwowo-mięśniowy wysokiej kadencji przy dużej prędkości (>50 km/h).
    final cadenceRatio =
        (session.averageCadenceRpm / 105.0).clamp(0.65, 1.20);
    final speedStimulus = (session.targetSpeedKmh / 58.0).clamp(0.55, 1.25);
    final neuromuscularStimulus = (cadenceRatio *
            speedStimulus *
            session.vehicleType.cadenceStimulusFactor *
            session.protocol.neuromuscularWeight *
            0.65)
        .clamp(0.05, 1.0);

    // Bodziec dla kąta biodrowego i przepony.
    final postureDepth = ((58.0 - session.posture.hipAngleDeg) / 22.0)
        .clamp(0.10, 1.0);
    final hipStress = (postureDepth *
            session.protocol.hipFlexorWeight *
            (durationMin / 90.0).clamp(0.25, 1.25))
        .clamp(0.05, 1.0);
    final respiratoryStimulus = (postureDepth *
            session.intensityFtpRatio *
            session.protocol.respiratoryWeight)
        .clamp(0.05, 1.0);

    // Krzywa malejących przyrostów (diminishing returns) przy zbliżaniu się do 1.0.
    final headroom = (1.0 - decayedProfile.adaptationScore).clamp(0.01, 1.0);
    final durationFactor = (durationMin / 75.0).clamp(0.25, 1.65);
    final rawGain = (0.042 * neuromuscularStimulus +
            0.036 * hipStress +
            0.028 * respiratoryStimulus) *
        durationFactor *
        math.pow(headroom, 0.80);
    final adaptationGain = rawGain.clamp(0.004, 0.14);

    final newAdaptation =
        (decayedProfile.adaptationScore + adaptationGain).clamp(0.0, 1.0);
    final newHipMobility = (decayedProfile.hipMobilityScore +
            hipStress * 0.025 * (1.0 - decayedProfile.hipMobilityScore))
        .clamp(0.0, 1.0);
    final newCoreEndurance = (decayedProfile.coreAndNeckEndurance +
            durationFactor *
                session.posture.neckCoreDemand *
                0.032 *
                (1.0 - decayedProfile.coreAndNeckEndurance))
        .clamp(0.0, 1.0);
    final newDiaphragm = (decayedProfile.diaphragmEfficiency +
            respiratoryStimulus * 0.028 * (1.0 - decayedProfile.diaphragmEfficiency))
        .clamp(0.0, 1.0);

    final intensityFactor =
        (effectiveRiderPowerWatts / math.max(100.0, decayedProfile.uprightFtpWatts))
            .clamp(0.4, 1.4);
    final tss = (durationMin / 60.0) * intensityFactor * intensityFactor * 100.0;

    final updatedProfile = decayedProfile.copyWith(
      adaptationScore: newAdaptation,
      hipMobilityScore: newHipMobility,
      coreAndNeckEndurance: newCoreEndurance,
      diaphragmEfficiency: newDiaphragm,
      motorPacingSessionsCompleted:
          decayedProfile.motorPacingSessionsCompleted + 1,
      cumulativeAeroTuckMinutes:
          decayedProfile.cumulativeAeroTuckMinutes + durationMin,
      daysSinceLastAeroSession: 0,
      preferredPosture: session.posture,
    );

    final gainPct = (adaptationGain * 100.0).toStringAsFixed(1);
    final totalPct = (newAdaptation * 100.0).toStringAsFixed(1);

    return MotorPacingTrainingResult(
      updatedProfile: updatedProfile,
      adaptationGain: adaptationGain,
      detrainingDecayApplied: decayApplied,
      effectiveRiderPowerWatts: effectiveRiderPowerWatts,
      soloEquivalentPowerWatts: soloEquivalentWatts,
      neuromuscularCadenceStimulus: neuromuscularStimulus,
      hipAngleCompressionStress: hipStress,
      respiratoryAdaptationStimulus: respiratoryStimulus,
      trainingStressScoreTss: tss,
      sessionSummaryPl:
          'Sesja ${durationMin.round()} min za ${session.vehicleType.labelPl} (${session.targetSpeedKmh.round()} km/h, ${session.averageCadenceRpm.round()} RPM): +$gainPct% adaptacji TT (łącznie $totalPct%).',
      sessionSummaryEn:
          '${durationMin.round()} min behind ${session.vehicleType.labelEn} (${session.targetSpeedKmh.round()} km/h, ${session.averageCadenceRpm.round()} RPM): +$gainPct% TT adaptation (total $totalPct%).',
    );
  }

  /// Utrata adaptacji TT po dłuższej przerwie (>10 dni bez treningów w pozycji aerodynamicznej).
  RiderAeroAdaptationProfile applyDetrainingDecay(
    RiderAeroAdaptationProfile profile,
    int daysWithoutAeroTraining,
  ) {
    if (daysWithoutAeroTraining <= 10) {
      return profile;
    }
    final excessDays = daysWithoutAeroTraining - 10;
    final decayFactor = math.exp(-0.018 * excessDays).clamp(0.45, 1.0);
    final decayedScore = (profile.adaptationScore * decayFactor).clamp(0.05, 1.0);
    return profile.copyWith(
      adaptationScore: decayedScore,
      daysSinceLastAeroSession: daysWithoutAeroTraining,
    );
  }

  /// Symuluje wielosesyjny blok treningowy za skuterem i mierzy postęp na 40 km ITT.
  MotorPacingBlockSimulationResult simulateTrainingBlock({
    required RiderAeroAdaptationProfile initialProfile,
    required List<MotorPacingSessionInput> sessions,
    AeroTuckPosturePreset evaluationPosture =
        AeroTuckPosturePreset.standardTtExtensions,
  }) {
    if (sessions.isEmpty) {
      return MotorPacingBlockSimulationResult(
        initialProfile: initialProfile,
        finalProfile: initialProfile,
        steps: const [],
        totalAdaptationGain: 0.0,
        totalPowerRecoveredWatts: 0.0,
        total40KmTimeGainSeconds: 0.0,
      );
    }

    final baselineEval = evaluateAeroTuckPerformance(
      AeroTuckPowerAndCdaInput(
        profile: initialProfile,
        posture: evaluationPosture,
        elapsedTtMinutes: 45.0,
      ),
    );
    final baseline40KmSec =
        40000.0 / math.max(1.0, baselineEval.predictedTtSpeedKmh / 3.6);

    var current = initialProfile;
    final steps = <MotorPacingBlockPlanStep>[];

    for (var i = 0; i < sessions.length; i++) {
      final res = applyMotorPacingSession(current, sessions[i]);
      current = res.updatedProfile;
      final eval = evaluateAeroTuckPerformance(
        AeroTuckPowerAndCdaInput(
          profile: current,
          posture: evaluationPosture,
          elapsedTtMinutes: 45.0,
        ),
      );
      final time40KmSec = 40000.0 / math.max(1.0, eval.predictedTtSpeedKmh / 3.6);
      steps.add(
        MotorPacingBlockPlanStep(
          sessionIndex: i + 1,
          protocol: sessions[i].protocol,
          adaptationScoreAfter: current.adaptationScore,
          ttSustainablePowerWatts: eval.effectiveSustainablePowerWatts,
          predicted40KmSpeedKmh: eval.predictedTtSpeedKmh,
          predicted40KmTimeSeconds: time40KmSec,
        ),
      );
    }

    final finalEval = evaluateAeroTuckPerformance(
      AeroTuckPowerAndCdaInput(
        profile: current,
        posture: evaluationPosture,
        elapsedTtMinutes: 45.0,
      ),
    );
    final final40KmSec =
        40000.0 / math.max(1.0, finalEval.predictedTtSpeedKmh / 3.6);

    return MotorPacingBlockSimulationResult(
      initialProfile: initialProfile,
      finalProfile: current,
      steps: steps,
      totalAdaptationGain:
          (current.adaptationScore - initialProfile.adaptationScore)
              .clamp(0.0, 1.0),
      totalPowerRecoveredWatts: math.max(
        0.0,
        finalEval.effectiveSustainablePowerWatts -
            baselineEval.effectiveSustainablePowerWatts,
      ),
      total40KmTimeGainSeconds: math.max(0.0, baseline40KmSec - final40KmSec),
    );
  }

  /// Oblicza moc potrzebną do utrzymania zadanej prędkości (W) na płaskim/nachyleniu.
  double computeRequiredPowerForSpeed({
    required double speedMs,
    required double cda,
    required double totalMassKg,
    double airDensityKgM3 = 1.225,
    double rollingResistanceCoeff = 0.0032,
    double roadGradient = 0.0,
  }) {
    final v = math.max(0.0, speedMs);
    final aeroForce = 0.5 * airDensityKgM3 * cda * v * v;
    final rollForce = rollingResistanceCoeff * totalMassKg * _gravity;
    final gravForce = roadGradient * totalMassKg * _gravity;
    final wheelPower = (aeroForce + rollForce + gravForce) * v;
    return math.max(0.0, wheelPower / _drivetrainEfficiency);
  }

  /// Rozwiązuje prędkość [m/s] metodą Newtona-Raphsona dla zadanej mocy na korbie [W].
  double solveSpeedFromPower({
    required double powerWatts,
    required double cda,
    required double totalMassKg,
    double airDensityKgM3 = 1.225,
    double rollingResistanceCoeff = 0.0032,
    double roadGradient = 0.0,
  }) {
    if (powerWatts <= 1.0) return 0.0;
    final wheelPower = powerWatts * _drivetrainEfficiency;
    final kAero = 0.5 * airDensityKgM3 * cda;
    final fRes = (rollingResistanceCoeff + roadGradient) * totalMassKg * _gravity;

    var v = 12.0; // ~43 km/h punkt startowy
    for (var i = 0; i < 16; i++) {
      final f = kAero * v * v * v + fRes * v - wheelPower;
      final df = 3.0 * kAero * v * v + fRes;
      if (df.abs() < 1e-6) break;
      final nextV = (v - f / df).clamp(0.5, 40.0);
      if ((nextV - v).abs() < 1e-4) {
        v = nextV;
        break;
      }
      v = nextV;
    }
    return v;
  }
}

/// Rysuje krzywą redukcji straty mocy TT i zysku czasowego na 40 km wraz ze wzrostem adaptacji.
class AeroTuckAdaptationCurvePainter extends CustomPainter {
  final double currentAdaptation;
  final AeroTuckPosturePreset posture;
  final double animationProgress;

  const AeroTuckAdaptationCurvePainter({
    required this.currentAdaptation,
    required this.posture,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const leftPad = 36.0;
    const rightPad = 14.0;
    const topPad = 14.0;
    const bottomPad = 24.0;
    final chartW = math.max(10.0, size.width - leftPad - rightPad);
    final chartH = math.max(10.0, size.height - topPad - bottomPad);

    final gridPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1.0;

    for (var i = 0; i <= 4; i++) {
      final y = topPad + (chartH * i / 4.0);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartW, y),
        gridPaint,
      );
    }

    final maxDrop = math.max(4.0, posture.basePowerDropPct * 1.15);
    final curvePath = Path();
    final fillPath = Path();

    const samples = 40;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final x = leftPad + chartW * t * animationProgress;
      final dropPct = posture.basePowerDropPct * (1.0 - 0.86 * t);
      final normY = (dropPct / maxDrop).clamp(0.0, 1.0);
      final y = topPad + chartH * (1.0 - normY);

      if (i == 0) {
        curvePath.moveTo(x, y);
        fillPath.moveTo(x, topPad + chartH);
        fillPath.lineTo(x, y);
      } else {
        curvePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(leftPad + chartW * animationProgress, topPad + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.28),
          AppColors.goldAccent.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, linePaint);

    // Punkt bieżącej adaptacji kolarza.
    final clampedAdapt = currentAdaptation.clamp(0.0, 1.0);
    final currentDrop = posture.basePowerDropPct * (1.0 - 0.86 * clampedAdapt);
    final markerX = leftPad + chartW * clampedAdapt * animationProgress;
    final markerY =
        topPad + chartH * (1.0 - (currentDrop / maxDrop).clamp(0.0, 1.0));

    canvas.drawCircle(
      Offset(markerX, markerY),
      7.0,
      Paint()..color = AppColors.accentBlue.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      Offset(markerX, markerY),
      4.5,
      Paint()..color = AppColors.accentBlue,
    );

    _drawAxisLabel(
      canvas,
      '${maxDrop.toStringAsFixed(0)}%',
      const Offset(4, topPad - 4),
    );
    _drawAxisLabel(canvas, '0%', Offset(10, topPad + chartH - 6));
    _drawAxisLabel(
      canvas,
      '0% Adapt.',
      Offset(leftPad, topPad + chartH + 6),
    );
    _drawAxisLabel(
      canvas,
      '100%',
      Offset(leftPad + chartW - 28, topPad + chartH + 6),
    );
  }

  void _drawAxisLabel(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: AppColors.textSecondary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant AeroTuckAdaptationCurvePainter oldDelegate) {
    return oldDelegate.currentAdaptation != currentAdaptation ||
        oldDelegate.posture != posture ||
        oldDelegate.animationProgress != animationProgress;
  }
}

/// Produkcyjny, responsywny panel treningu za skuterem i adaptacji mocy w niskiej pozycji TT.
class MotorPacingAndAeroTuckPanel extends StatefulWidget {
  final RiderAeroAdaptationProfile initialProfile;
  final ValueChanged<RiderAeroAdaptationProfile>? onProfileUpdated;

  const MotorPacingAndAeroTuckPanel({
    super.key,
    required this.initialProfile,
    this.onProfileUpdated,
  });

  @override
  State<MotorPacingAndAeroTuckPanel> createState() =>
      _MotorPacingAndAeroTuckPanelState();
}

class _MotorPacingAndAeroTuckPanelState
    extends State<MotorPacingAndAeroTuckPanel>
    with SingleTickerProviderStateMixin {
  final MotorPacingAndAeroTuckAdaptation _engine =
      const MotorPacingAndAeroTuckAdaptation();

  late RiderAeroAdaptationProfile _profile;
  late AeroTuckPosturePreset _selectedPosture;
  MotorPacingVehicleType _selectedVehicle =
      MotorPacingVehicleType.vespaScooter125;
  MotorPacingSessionProtocol _selectedProtocol =
      MotorPacingSessionProtocol.ttThresholdBehindDerny;
  double _durationMinutes = 75.0;
  double _targetSpeedKmh = 60.0;
  double _cadenceRpm = 100.0;
  MotorPacingTrainingResult? _lastTrainingResult;

  late final AnimationController _curveController;
  late final Animation<double> _curveAnim;

  bool _runHovered = false;
  bool _runPressed = false;
  bool _runFocused = false;
  bool _resetHovered = false;
  bool _resetPressed = false;
  bool _resetFocused = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _selectedPosture = widget.initialProfile.preferredPosture;
    _curveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _curveAnim = CurvedAnimation(
      parent: _curveController,
      curve: Curves.easeOutCubic,
    );
    _curveController.forward();
  }

  @override
  void dispose() {
    _curveController.dispose();
    super.dispose();
  }

  void _runMotorPacingSession() {
    final session = MotorPacingSessionInput(
      vehicleType: _selectedVehicle,
      protocol: _selectedProtocol,
      posture: _selectedPosture,
      durationMinutes: _durationMinutes,
      targetSpeedKmh: _targetSpeedKmh,
      averageCadenceRpm: _cadenceRpm,
      intensityFtpRatio: _selectedProtocol.defaultIntensityFtp,
    );
    final result = _engine.applyMotorPacingSession(_profile, session);
    setState(() {
      _profile = result.updatedProfile;
      _lastTrainingResult = result;
    });
    _curveController
      ..reset()
      ..forward();
    widget.onProfileUpdated?.call(_profile);
  }

  void _resetAdaptation() {
    setState(() {
      _profile = widget.initialProfile;
      _selectedPosture = widget.initialProfile.preferredPosture;
      _lastTrainingResult = null;
    });
    _curveController
      ..reset()
      ..forward();
    widget.onProfileUpdated?.call(_profile);
  }

  @override
  Widget build(BuildContext context) {
    final eval = _engine.evaluateAeroTuckPerformance(
      AeroTuckPowerAndCdaInput(
        profile: _profile,
        posture: _selectedPosture,
        elapsedTtMinutes: 45.0,
        cadenceRpm: _cadenceRpm,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final isWide = constraints.maxWidth >= 1024;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14.0 : 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(eval, isCompact),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildTelemetryCard(eval)),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: _buildControlsCard(isCompact)),
                    ],
                  )
                else ...[
                  _buildTelemetryCard(eval),
                  const SizedBox(height: 16),
                  _buildControlsCard(isCompact),
                ],
                if (_lastTrainingResult != null) ...[
                  const SizedBox(height: 14),
                  _buildLastSessionBanner(_lastTrainingResult!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AeroTuckPowerAndCdaResult eval, bool isCompact) {
    final tierColor = switch (eval.adaptationTier) {
      AeroAdaptationTier.worldTourTtSpecialist => AppColors.goldAccent,
      AeroAdaptationTier.raceReady => AppColors.statusSuccess,
      AeroAdaptationTier.developing => AppColors.accentBlue,
      AeroAdaptationTier.unadapted => AppColors.amberWarning,
    };

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motor-Pacing & Adaptacja Pozycji TT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_profile.riderName} • FTP ${_profile.uprightFtpWatts.round()} W • ${_profile.motorPacingSessionsCompleted} sesji za skuterem',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tierColor.withValues(alpha: 0.55)),
          ),
          child: Text(
            '${eval.adaptationTier.labelPl} (${(_profile.adaptationScore * 100).round()}%)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tierColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard(AeroTuckPowerAndCdaResult eval) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Telemetria Mocy i Aerodynamiki TT',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metricTile(
                label: 'Moc w pozycji TT',
                value: '${eval.effectiveSustainablePowerWatts.round()} W',
                sub:
                    '+${eval.powerRecoveredByAdaptationWatts.toStringAsFixed(1)} W odzyskane',
                accent: AppColors.goldAccent,
              ),
              _metricTile(
                label: 'Strata mocy TT',
                value: '-${eval.actualPowerDropPercent.toStringAsFixed(1)}%',
                sub:
                    'Bazowo -${eval.unadaptedPowerDropPercent.toStringAsFixed(1)}%',
                accent: AppColors.accentBlue,
              ),
              _metricTile(
                label: 'Efektywne CdA',
                value: '${eval.effectiveCda.toStringAsFixed(3)} m²',
                sub:
                    'Prędkość ${eval.predictedTtSpeedKmh.toStringAsFixed(1)} km/h',
                accent: AppColors.cyanAccent,
              ),
              _metricTile(
                label: 'Zysk na 40 km ITT',
                value: '-${eval.timeSavedOver40KmSeconds.round()} s',
                sub: eval.breakdownRisk.labelPl,
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Krzywa redukcji spadku mocy w pozycji TT (%)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 145,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _curveAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: AeroTuckAdaptationCurvePainter(
                    currentAdaptation: _profile.adaptationScore,
                    posture: _selectedPosture,
                    animationProgress: _curveAnim.value,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required String sub,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
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

  Widget _buildControlsCard(bool isCompact) {
    final canRun = _profile.adaptationScore < 0.999;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfiguracja Sesji za Skuterem',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pozycja aerodynamiczna',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AeroTuckPosturePreset.values.map((p) {
              return _InteractiveChip(
                label: p.labelPl,
                selected: _selectedPosture == p,
                onTap: () {
                  setState(() => _selectedPosture = p);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pojazd prowadzący',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MotorPacingVehicleType.values.map((v) {
              return _InteractiveChip(
                label: v.labelPl,
                selected: _selectedVehicle == v,
                onTap: () {
                  setState(() {
                    _selectedVehicle = v;
                    _targetSpeedKmh = v.optimalSpeedKmh;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Protokół jednostki',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MotorPacingSessionProtocol.values.map((proto) {
              return _InteractiveChip(
                label: proto.labelPl,
                selected: _selectedProtocol == proto,
                onTap: () {
                  setState(() {
                    _selectedProtocol = proto;
                    _cadenceRpm = proto.defaultCadenceRpm;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _buildSliderRow(
            label: 'Czas sesji',
            valueText: '${_durationMinutes.round()} min',
            value: _durationMinutes,
            min: 20,
            max: 150,
            onChanged: (v) => setState(() => _durationMinutes = v),
          ),
          _buildSliderRow(
            label: 'Prędkość za skuterem',
            valueText: '${_targetSpeedKmh.round()} km/h',
            value: _targetSpeedKmh,
            min: 38,
            max: 72,
            onChanged: (v) => setState(() => _targetSpeedKmh = v),
          ),
          _buildSliderRow(
            label: 'Docelowa kadencja',
            valueText: '${_cadenceRpm.round()} RPM',
            value: _cadenceRpm,
            min: 80,
            max: 120,
            onChanged: (v) => setState(() => _cadenceRpm = v),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildActionButton(
                label: canRun
                    ? 'Wykonaj trening za skuterem'
                    : 'Pełna adaptacja osiągnięta',
                enabled: canRun,
                hovered: _runHovered,
                pressed: _runPressed,
                focused: _runFocused,
                primary: true,
                onHoverChanged: (v) => setState(() => _runHovered = v),
                onPressedChanged: (v) => setState(() => _runPressed = v),
                onFocusChanged: (v) => setState(() => _runFocused = v),
                onTap: canRun ? _runMotorPacingSession : null,
              ),
              _buildActionButton(
                label: 'Resetuj blok',
                enabled: true,
                hovered: _resetHovered,
                pressed: _resetPressed,
                focused: _resetFocused,
                primary: false,
                onHoverChanged: (v) => setState(() => _resetHovered = v),
                onPressedChanged: (v) => setState(() => _resetPressed = v),
                onFocusChanged: (v) => setState(() => _resetFocused = v),
                onTap: _resetAdaptation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            trackHeight: 3.0,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool enabled,
    required bool hovered,
    required bool pressed,
    required bool focused,
    required bool primary,
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<bool> onPressedChanged,
    required ValueChanged<bool> onFocusChanged,
    required VoidCallback? onTap,
  }) {
    final baseBg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : primary
            ? (pressed
                ? AppColors.primaryAccent.withValues(alpha: 0.85)
                : hovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.95)
                    : AppColors.primaryAccent)
            : (pressed
                ? AppColors.surfaceLight
                : hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.9)
                    : AppColors.background);

    final borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : focused
            ? AppColors.goldAccent
            : hovered
                ? AppColors.goldAccent.withValues(alpha: 0.65)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: onHoverChanged,
      onShowFocusHighlight: onFocusChanged,
      child: GestureDetector(
        onTapDown: enabled ? (_) => onPressedChanged(true) : null,
        onTapUp: enabled
            ? (_) {
                onPressedChanged(false);
                onTap?.call();
              }
            : null,
        onTapCancel: enabled ? () => onPressedChanged(false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: baseBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: focused ? 1.6 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastSessionBanner(MotorPacingTrainingResult res) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bolt_rounded,
            color: AppColors.goldAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${res.sessionSummaryPl} (TSS ${res.trainingStressScoreTss.round()}, Moc śr. ${res.effectiveRiderPowerWatts.round()} W)',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.85 : 0.95)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final border = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.7)
            : _hovered
                ? AppColors.textSecondary
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
