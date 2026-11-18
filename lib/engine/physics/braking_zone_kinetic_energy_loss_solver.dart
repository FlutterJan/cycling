// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/equipment/wheelset_model.dart';
import '../../models/race/stage_segment.dart';
import 'wet_cornering_grip_and_braking_solver.dart';

/// Dyscyplina lub typ trasy z licznymi strefami dohamowań.
enum BrakingCourseDiscipline {
  urbanCriterium(
    'Urban Criterium',
    'Kryterium miejskie',
    40,
    0.75,
  ),
  twistyTimeTrial(
    'Twisty Time Trial',
    'Kręta czasówka (ITT)',
    1,
    0.0,
  ),
  urbanPrologue(
    'Urban Prologue',
    'Prolog miejski',
    1,
    0.0,
  ),
  technicalCircuit(
    'Technical City Circuit',
    'Techniczny obwód miejski',
    12,
    0.55,
  );

  final String labelEn;
  final String labelPl;
  final int defaultLaps;
  final double typicalPackDensity;

  const BrakingCourseDiscipline(
    this.labelEn,
    this.labelPl,
    this.defaultLaps,
    this.typicalPackDensity,
  );
}

/// Geometria zakrętu determinująca prędkość w szczycie (apex) i efekt akordeonu.
enum CornerGeometryType {
  sweeper('Fast Sweeper', 'Szybki łuk', 38.0, 45.0, 0.06),
  ninetyDegreeTurn('90° Urban Turn', 'Zakręt miejski 90°', 11.5, 90.0, 0.22),
  chicane('Technical Chicane', 'Szykana techniczna', 9.0, 110.0, 0.28),
  roundabout('City Roundabout', 'Rondo miejskie', 14.0, 120.0, 0.18),
  hairpin180('180° Hairpin', 'Nawrót 180°', 6.5, 180.0, 0.35);

  final String labelEn;
  final String labelPl;
  final double defaultRadiusMeters;
  final double defaultArcAngleDeg;
  final double accordionFactor;

  const CornerGeometryType(
    this.labelEn,
    this.labelPl,
    this.defaultRadiusMeters,
    this.defaultArcAngleDeg,
    this.accordionFactor,
  );
}

/// Klasyfikacja intensywności dohamowania w strefie przed zakrętem.
enum BrakingZoneSeverity {
  noBrakingNeeded('No Braking', 'Bez hamowania'),
  lightScrub('Light Scrub', 'Lekkie przyhamowanie'),
  moderateBraking('Moderate Braking', 'Średnie dohamowanie'),
  heavyThresholdBraking('Heavy Braking', 'Mocne dohamowanie'),
  emergencyHairpin('Max Threshold Hairpin', 'Maksymalne dohamowanie do nawrotu');

  final String labelEn;
  final String labelPl;

  const BrakingZoneSeverity(this.labelEn, this.labelPl);
}

/// Specyfikacja pojedynczego zakrętu / strefy hamowania na trasie.
class BrakingCornerSpec {
  final String id;
  final String name;
  final CornerGeometryType geometryType;

  /// Promień toru jazdy w zakręcie [m].
  final double radiusMeters;

  /// Kąt skrętu łuku [stopnie].
  final double arcAngleDegrees;

  /// Prędkość najazdu przed strefą hamowania [m/s].
  final double entrySpeedMs;

  /// Docelowa prędkość wyjścia po ponownym rozpędzeniu [m/s].
  final double exitSpeedMs;

  /// Nawierzchnia strefy dohamowania i zakrętu.
  final SegmentSurfaceType surfaceType;

  /// Nachylenie drogi na dohamowaniu [%] (< 0 oznacza zjazd).
  final double roadGradientPercent;

  /// Długość prostej za zakrętem do kolejnej strefy hamowania [m].
  final double straightLengthAfterMeters;

  /// Czy obecne są barierki / krawężniki zawężające linię przejazdu.
  final bool hasNarrowBarriers;

  const BrakingCornerSpec({
    required this.id,
    required this.name,
    required this.geometryType,
    required this.radiusMeters,
    required this.arcAngleDegrees,
    required this.entrySpeedMs,
    double? exitSpeedMs,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.roadGradientPercent = 0.0,
    this.straightLengthAfterMeters = 220.0,
    this.hasNarrowBarriers = true,
  }) : exitSpeedMs = exitSpeedMs ?? entrySpeedMs;

  /// Długość łuku zakrętu [m].
  double get arcLengthMeters {
    final safeR = math.max(1.0, radiusMeters);
    final safeAngleRad = math.max(0.0, arcAngleDegrees) * math.pi / 180.0;
    return safeR * safeAngleRad;
  }
}

/// Konfiguracja kolarza, sprzętu i warunków w strefach dohamowań.
class BrakingZoneRiderConfig {
  final double riderMassKg;
  final double bikeMassKg;
  final WheelsetModel? wheelset;
  final double wheelRadiusMeters;
  final double? wheelMomentOfInertiaOverrideKgM2;
  final double drivetrainEfficiency;
  final double riderFtpWatts;
  final double riderWPrimeJoules;

  /// Umiejętność pokonywania zakrętów (1–100).
  final int corneringSkill;

  /// Umiejętność późnego i skutecznego hamowania (1–100).
  final int brakingSkill;

  final double baseCda;
  final double baseCrr;
  final BrakeSystemType brakeSystem;
  final TireCompoundType tireCompound;

  /// Stopień zawilgocenia nawierzchni (`0.0` = sucho, `1.0` = ulewa).
  final double surfaceWetness;

  /// Pozycja w peletonie (`0.0` = przód / jazda indywidualna, `1.0` = ogon peletonu).
  final double pelotonPositionFactor;

  /// Gęstość powietrza [kg/m^3].
  final double airDensityKgM3;

  const BrakingZoneRiderConfig({
    this.riderMassKg = 70.0,
    this.bikeMassKg = 7.2,
    this.wheelset,
    this.wheelRadiusMeters = 0.340,
    this.wheelMomentOfInertiaOverrideKgM2,
    this.drivetrainEfficiency = 0.975,
    this.riderFtpWatts = 385.0,
    this.riderWPrimeJoules = 22000.0,
    this.corneringSkill = 78,
    this.brakingSkill = 78,
    this.baseCda = PhysicsConstants.cdaDrops,
    this.baseCrr = PhysicsConstants.crrSmoothAsphalt,
    this.brakeSystem = BrakeSystemType.hydraulicDisc,
    this.tireCompound = TireCompoundType.standardRace,
    this.surfaceWetness = 0.0,
    this.pelotonPositionFactor = 0.35,
    this.airDensityKgM3 = PhysicsConstants.seaLevelAirDensity,
  });

  /// Masa całkowita układu kolarz + rower [kg].
  double get totalSystemMassKg {
    final wheelMassDeltaKg =
        wheelset != null ? (wheelset!.weightKg - 1.40) : 0.0;
    return math.max(45.0, riderMassKg + bikeMassKg + wheelMassDeltaKg);
  }

  /// Efektywny moment bezwładności obu kół [kg*m^2].
  double get effectiveRotationalInertiaKgM2 {
    if (wheelMomentOfInertiaOverrideKgM2 != null) {
      return math.max(0.04, wheelMomentOfInertiaOverrideKgM2!);
    }
    if (wheelset != null) {
      if (wheelset!.momentOfInertia > 0.01) {
        return wheelset!.momentOfInertia;
      }
      // Szacunek z masy obręczy i wysokości stożka dla pary kół.
      final rimShareKg = wheelset!.weightKg * 0.56;
      final effectiveRimRadiusM =
          math.max(0.24, wheelRadiusMeters - (wheelset!.rimDepthMm / 2000.0));
      return rimShareKg * effectiveRimRadiusM * effectiveRimRadiusM;
    }
    return 0.118;
  }

  /// Zastępcza masa obrotowa kół $m_{eq,rot} = I / r^2$ [kg].
  double get effectiveRotationalMassKg {
    final safeRadius = math.max(0.15, wheelRadiusMeters);
    return effectiveRotationalInertiaKgM2 / (safeRadius * safeRadius);
  }

  /// Całkowita masa bezwładna (translacyjna + obrotowa kół) [kg].
  double get totalEffectiveInertialMassKg =>
      totalSystemMassKg + effectiveRotationalMassKg;

  /// Efektywne CdA z uwzględnieniem profilu aerodynamicznego kół.
  double get effectiveCda {
    final modifier = wheelset?.aeroCdaModifier ?? 0.0;
    return math.max(0.16, baseCda + modifier);
  }

  BrakingZoneRiderConfig copyWith({
    double? riderMassKg,
    double? bikeMassKg,
    WheelsetModel? wheelset,
    double? wheelRadiusMeters,
    double? wheelMomentOfInertiaOverrideKgM2,
    double? drivetrainEfficiency,
    double? riderFtpWatts,
    double? riderWPrimeJoules,
    int? corneringSkill,
    int? brakingSkill,
    double? baseCda,
    double? baseCrr,
    BrakeSystemType? brakeSystem,
    TireCompoundType? tireCompound,
    double? surfaceWetness,
    double? pelotonPositionFactor,
    double? airDensityKgM3,
  }) {
    return BrakingZoneRiderConfig(
      riderMassKg: riderMassKg ?? this.riderMassKg,
      bikeMassKg: bikeMassKg ?? this.bikeMassKg,
      wheelset: wheelset ?? this.wheelset,
      wheelRadiusMeters: wheelRadiusMeters ?? this.wheelRadiusMeters,
      wheelMomentOfInertiaOverrideKgM2: wheelMomentOfInertiaOverrideKgM2 ??
          this.wheelMomentOfInertiaOverrideKgM2,
      drivetrainEfficiency: drivetrainEfficiency ?? this.drivetrainEfficiency,
      riderFtpWatts: riderFtpWatts ?? this.riderFtpWatts,
      riderWPrimeJoules: riderWPrimeJoules ?? this.riderWPrimeJoules,
      corneringSkill: corneringSkill ?? this.corneringSkill,
      brakingSkill: brakingSkill ?? this.brakingSkill,
      baseCda: baseCda ?? this.baseCda,
      baseCrr: baseCrr ?? this.baseCrr,
      brakeSystem: brakeSystem ?? this.brakeSystem,
      tireCompound: tireCompound ?? this.tireCompound,
      surfaceWetness: surfaceWetness ?? this.surfaceWetness,
      pelotonPositionFactor:
          pelotonPositionFactor ?? this.pelotonPositionFactor,
      airDensityKgM3: airDensityKgM3 ?? this.airDensityKgM3,
    );
  }
}

/// Szczegółowy wynik strat energii kinetycznej i czasu w jednej strefie hamowania.
class BrakingZoneEnergyResult {
  final String cornerId;
  final String cornerName;
  final BrakingZoneSeverity severity;
  final double entrySpeedMs;
  final double apexSpeedMs;
  final double exitSpeedMs;

  /// Strata energii kinetycznej ruchu postępowego $\Delta E_{trans}$ [J].
  final double translationalEnergyLossJoules;

  /// Strata energii kinetycznej ruchu obrotowego kół $\Delta E_{rot}$ [J].
  final double rotationalEnergyLossJoules;

  /// Całkowita strata energii kinetycznej $\Delta E_{total}$ [J].
  final double totalKineticEnergyLossJoules;

  /// Energia rozproszona w postaci ciepła przez hamulce (po odjęciu oporów ruchu) [J].
  final double brakeDissipatedEnergyJoules;

  /// Dodatkowa strata wynikająca z efektu akordeonu w peletonie [J].
  final double accordionExtraLossJoules;

  /// Praca mechaniczna na kole potrzebna do ponownego rozpędzenia do [exitSpeedMs] [J].
  final double reaccelerationWorkJoules;

  /// Energia na korbie (uwzględniająca sprawność napędu) [J].
  final double crankReaccelerationEnergyJoules;

  final double brakingDecelerationMs2;
  final double brakingDistanceMeters;
  final double brakingDurationSeconds;
  final double apexDurationSeconds;
  final double reaccelerationDurationSeconds;

  /// Czas stracony na hamowaniu, pokonaniu zakrętu i ponownym rozpędzeniu [s].
  final double timeLostSeconds;

  /// Szczytowa moc zrywu przy wyjściu z zakrętu [W].
  final double reaccelerationPeakPowerWatts;

  /// Zużycie rezerwy beztlenowej $W'$ na wyjściu z zakrętu [J].
  final double wPrimeDepletedJoules;

  /// Przyrost temperatury układu hamulcowego [°C].
  final double brakeThermalLoadCelsiusDelta;

  const BrakingZoneEnergyResult({
    required this.cornerId,
    required this.cornerName,
    required this.severity,
    required this.entrySpeedMs,
    required this.apexSpeedMs,
    required this.exitSpeedMs,
    required this.translationalEnergyLossJoules,
    required this.rotationalEnergyLossJoules,
    required this.totalKineticEnergyLossJoules,
    required this.brakeDissipatedEnergyJoules,
    required this.accordionExtraLossJoules,
    required this.reaccelerationWorkJoules,
    required this.crankReaccelerationEnergyJoules,
    required this.brakingDecelerationMs2,
    required this.brakingDistanceMeters,
    required this.brakingDurationSeconds,
    required this.apexDurationSeconds,
    required this.reaccelerationDurationSeconds,
    required this.timeLostSeconds,
    required this.reaccelerationPeakPowerWatts,
    required this.wPrimeDepletedJoules,
    required this.brakeThermalLoadCelsiusDelta,
  });

  double get totalKineticEnergyLossKj => totalKineticEnergyLossJoules / 1000.0;
  double get rotationalShareFraction => totalKineticEnergyLossJoules > 0.0
      ? rotationalEnergyLossJoules / totalKineticEnergyLossJoules
      : 0.0;
}

/// Zagregowany profil strat energii kinetycznej na całej trasie / kryterium.
class CourseBrakingProfileResult {
  final BrakingCourseDiscipline discipline;
  final int laps;
  final int cornerCountPerLap;
  final int totalBrakingEvents;
  final double totalCourseDistanceMeters;
  final double totalEstimatedTimeSeconds;
  final double totalKineticEnergyLossKj;
  final double totalTranslationalLossKj;
  final double totalRotationalLossKj;
  final double totalBrakeDissipatedEnergyKj;
  final double totalReaccelerationWorkKj;
  final double totalTimeLostInBrakingZonesSeconds;
  final double totalWPrimeDepletedKj;
  final double averagePowerWatts;
  final double estimatedNormalizedPowerWatts;
  final double variabilityIndex;
  final double peakBrakeTempCelsius;
  final double thermalFadePenaltyPercent;
  final List<BrakingZoneEnergyResult> cornerResults;

  const CourseBrakingProfileResult({
    required this.discipline,
    required this.laps,
    required this.cornerCountPerLap,
    required this.totalBrakingEvents,
    required this.totalCourseDistanceMeters,
    required this.totalEstimatedTimeSeconds,
    required this.totalKineticEnergyLossKj,
    required this.totalTranslationalLossKj,
    required this.totalRotationalLossKj,
    required this.totalBrakeDissipatedEnergyKj,
    required this.totalReaccelerationWorkKj,
    required this.totalTimeLostInBrakingZonesSeconds,
    required this.totalWPrimeDepletedKj,
    required this.averagePowerWatts,
    required this.estimatedNormalizedPowerWatts,
    required this.variabilityIndex,
    required this.peakBrakeTempCelsius,
    required this.thermalFadePenaltyPercent,
    required this.cornerResults,
  });
}

/// Porównanie dwóch zestawów kół na tej samej trasie kryterium lub krętej czasówki.
class WheelsetBrakingComparisonResult {
  final WheelsetModel wheelsetA;
  final WheelsetModel wheelsetB;
  final CourseBrakingProfileResult profileA;
  final CourseBrakingProfileResult profileB;

  /// Dodatnia wartość oznacza, że [wheelsetB] jest szybszy od [wheelsetA] o tyle sekund.
  final double netTimeDeltaSeconds;

  /// Zaoszczędzona energia kinetyczna na hamowaniach (`lossA - lossB`) [kJ].
  final double kineticEnergySavedKj;

  /// Zaoszczędzona energia obrotowa kół (`rotLossA - rotLossB`) [kJ].
  final double rotationalEnergySavedKj;

  /// Oszczędność rezerwy beztlenowej $W'$ (`wPrimeA - wPrimeB`) [kJ].
  final double wPrimeSavedKj;

  /// Różnica czasu na prostych wynikająca z aerodynamiki CdA (>0 = B szybsze) [s].
  final double aeroStraightTimeDeltaSeconds;

  /// Różnica czasu w strefach hamowania i rozpędzania (>0 = B szybsze) [s].
  final double cornerReaccelTimeDeltaSeconds;

  final WheelsetModel fasterWheelset;
  final String summaryReasonPl;
  final String summaryReasonEn;

  const WheelsetBrakingComparisonResult({
    required this.wheelsetA,
    required this.wheelsetB,
    required this.profileA,
    required this.profileB,
    required this.netTimeDeltaSeconds,
    required this.kineticEnergySavedKj,
    required this.rotationalEnergySavedKj,
    required this.wPrimeSavedKj,
    required this.aeroStraightTimeDeltaSeconds,
    required this.cornerReaccelTimeDeltaSeconds,
    required this.fasterWheelset,
    required this.summaryReasonPl,
    required this.summaryReasonEn,
  });
}

/// Solver strat energii kinetycznej na dohamowaniach w kryteriach miejskich i krętych czasówkach.
class BrakingZoneKineticEnergyLossSolver {
  const BrakingZoneKineticEnergyLossSolver._();

  static const double _ambientBrakeTempC = 22.0;

  /// Oblicza maksymalną prędkość w szczycie zakrętu oraz straty energii na jednym dohamowaniu.
  static BrakingZoneEnergyResult evaluateCornerBrakingZone({
    required BrakingCornerSpec corner,
    required BrakingZoneRiderConfig config,
    double brakeFadeFactor = 1.0,
  }) {
    final safeEntrySpeed = math.max(0.5, corner.entrySpeedMs);
    final safeExitSpeed = math.max(0.5, corner.exitSpeedMs);
    final wetness = config.surfaceWetness.clamp(0.0, 1.0);
    final packFactor = config.pelotonPositionFactor.clamp(0.0, 1.0);
    final safeDriveEff = config.drivetrainEfficiency.clamp(0.80, 1.0);
    final safeFtp = math.max(100.0, config.riderFtpWatts);

    final muEffective = _computeEffectiveFriction(
      surfaceType: corner.surfaceType,
      wetness: wetness,
      compound: config.tireCompound,
      corneringSkill: config.corneringSkill,
    );

    // Efekt akordeonu w peletonie oraz bariery zawężają promień i obniżają prędkość apex.
    final effectiveRadius = math.max(
      2.0,
      corner.radiusMeters * (corner.hasNarrowBarriers ? 0.94 : 1.0),
    );
    final accordionSpeedPenalty =
        1.0 - (packFactor * corner.geometryType.accordionFactor * 0.45);
    final rawApexMax =
        math.sqrt(muEffective * PhysicsConstants.gravity * effectiveRadius);
    final apexSpeed = math.min(
      safeEntrySpeed,
      math.max(2.5, rawApexMax * accordionSpeedPenalty),
    );

    final deltaV2Brake =
        math.max(0.0, (safeEntrySpeed * safeEntrySpeed) - (apexSpeed * apexSpeed));

    if (deltaV2Brake <= 0.05) {
      final arcTime = corner.arcLengthMeters / safeEntrySpeed;
      return BrakingZoneEnergyResult(
        cornerId: corner.id,
        cornerName: corner.name,
        severity: BrakingZoneSeverity.noBrakingNeeded,
        entrySpeedMs: safeEntrySpeed,
        apexSpeedMs: safeEntrySpeed,
        exitSpeedMs: safeExitSpeed,
        translationalEnergyLossJoules: 0.0,
        rotationalEnergyLossJoules: 0.0,
        totalKineticEnergyLossJoules: 0.0,
        brakeDissipatedEnergyJoules: 0.0,
        accordionExtraLossJoules: 0.0,
        reaccelerationWorkJoules: 0.0,
        crankReaccelerationEnergyJoules: 0.0,
        brakingDecelerationMs2: 0.0,
        brakingDistanceMeters: 0.0,
        brakingDurationSeconds: 0.0,
        apexDurationSeconds: arcTime,
        reaccelerationDurationSeconds: 0.0,
        timeLostSeconds: 0.0,
        reaccelerationPeakPowerWatts: 0.0,
        wPrimeDepletedJoules: 0.0,
        brakeThermalLoadCelsiusDelta: 0.0,
      );
    }

    final mTotal = config.totalSystemMassKg;
    final mRot = config.effectiveRotationalMassKg;
    final transLossJ = 0.5 * mTotal * deltaV2Brake;
    final rotLossJ = 0.5 * mRot * deltaV2Brake;
    final baseKineticLossJ = transLossJ + rotLossJ;

    // Dodatkowa strata w peletonie z wielokrotnego przyhamowania przed wierzchołkiem.
    final accordionExtraJ = baseKineticLossJ *
        (packFactor * corner.geometryType.accordionFactor * 0.35);
    final totalKineticLossJ = baseKineticLossJ + accordionExtraJ;

    // Skuteczność hamowania i opóźnienie.
    final brakeEff = _lerp(
      config.brakeSystem.dryBrakeEfficiency,
      config.brakeSystem.wetBrakeEfficiency,
      wetness,
    );
    final skillFactor = 0.84 + (config.brakingSkill.clamp(1, 100) / 100.0) * 0.22;
    final gradeRad = math.atan(corner.roadGradientPercent / 100.0);
    final gradeGravityTerm = PhysicsConstants.gravity * math.sin(gradeRad);

    final decelMs2 = (muEffective *
                PhysicsConstants.gravity *
                brakeEff *
                skillFactor *
                brakeFadeFactor +
            gradeGravityTerm)
        .clamp(1.8, 8.2);

    final brakingDistM = deltaV2Brake / (2.0 * decelMs2);
    final brakingTimeS = (safeEntrySpeed - apexSpeed) / decelMs2;

    // Część energii wyhamowują same opory aero i toczenia podczas strefy hamowania.
    final avgBrakeSpeed = 0.5 * (safeEntrySpeed + apexSpeed);
    final aeroDragForceN = 0.5 *
        config.airDensityKgM3 *
        config.effectiveCda *
        avgBrakeSpeed *
        avgBrakeSpeed;
    final rollingForceN =
        mTotal * PhysicsConstants.gravity * config.baseCrr;
    final passiveDragWorkJ = (aeroDragForceN + rollingForceN) * brakingDistM;
    final brakeDissipatedJ =
        math.max(0.0, totalKineticLossJ - passiveDragWorkJ);

    // Ponowne rozpędzenie od apexSpeed do exitSpeed.
    final deltaV2Accel =
        math.max(0.0, (safeExitSpeed * safeExitSpeed) - (apexSpeed * apexSpeed));
    final accelKineticWorkJ = 0.5 * (mTotal + mRot) * deltaV2Accel;

    // Moc zrywu na wyjściu z zakrętu (skalowana powyżej FTP).
    final speedDropRatio = (safeEntrySpeed - apexSpeed) / safeEntrySpeed;
    final surgeFactor = (1.35 + speedDropRatio * 1.35).clamp(1.25, 2.55);
    final surgePowerW = safeFtp * surgeFactor;
    final avgReaccelSpeed = 0.5 * (apexSpeed + safeExitSpeed);
    final reaccelDragPowerW = (0.5 *
                config.airDensityKgM3 *
                config.effectiveCda *
                math.pow(avgReaccelSpeed, 3) +
            mTotal * PhysicsConstants.gravity * config.baseCrr * avgReaccelSpeed)
        .toDouble();

    final netAccelPowerW =
        math.max(120.0, surgePowerW * safeDriveEff - reaccelDragPowerW);
    final reaccelTimeS =
        (accelKineticWorkJ / netAccelPowerW).clamp(0.5, 16.0);
    final reaccelDistM = avgReaccelSpeed * reaccelTimeS;
    final reaccelTotalWorkJ =
        accelKineticWorkJ + (reaccelDragPowerW * reaccelTimeS);
    final crankEnergyJ = reaccelTotalWorkJ / safeDriveEff;

    // Zużycie W' podczas przyspieszenia ponad FTP.
    final wPrimeDepletedJ =
        math.max(0.0, surgePowerW - safeFtp) * reaccelTimeS;

    // Czas w łuku i całkowita strata czasowa względem przejazdu ze stałą entrySpeedMs.
    final apexTimeS = corner.arcLengthMeters / apexSpeed;
    final totalZoneDistM =
        brakingDistM + corner.arcLengthMeters + reaccelDistM;
    final idealZoneTimeS = totalZoneDistM / safeEntrySpeed;
    final actualZoneTimeS = brakingTimeS + apexTimeS + reaccelTimeS;
    final timeLostS = math.max(0.0, actualZoneTimeS - idealZoneTimeS);

    // Nagrzewanie tarczy / obręczy (uproszczona pojemność cieplna układu hamulcowego).
    final thermalCapacityJPerC =
        config.brakeSystem == BrakeSystemType.hydraulicDisc ? 260.0 : 340.0;
    final tempDeltaC = (brakeDissipatedJ / thermalCapacityJPerC) * 0.45;

    final severity = _classifySeverity(
      speedDropRatio: speedDropRatio,
      kineticLossJ: totalKineticLossJ,
    );

    return BrakingZoneEnergyResult(
      cornerId: corner.id,
      cornerName: corner.name,
      severity: severity,
      entrySpeedMs: safeEntrySpeed,
      apexSpeedMs: apexSpeed,
      exitSpeedMs: safeExitSpeed,
      translationalEnergyLossJoules: transLossJ,
      rotationalEnergyLossJoules: rotLossJ,
      totalKineticEnergyLossJoules: totalKineticLossJ,
      brakeDissipatedEnergyJoules: brakeDissipatedJ,
      accordionExtraLossJoules: accordionExtraJ,
      reaccelerationWorkJoules: reaccelTotalWorkJ,
      crankReaccelerationEnergyJoules: crankEnergyJ,
      brakingDecelerationMs2: decelMs2,
      brakingDistanceMeters: brakingDistM,
      brakingDurationSeconds: brakingTimeS,
      apexDurationSeconds: apexTimeS,
      reaccelerationDurationSeconds: reaccelTimeS,
      timeLostSeconds: timeLostS,
      reaccelerationPeakPowerWatts: surgePowerW,
      wPrimeDepletedJoules: wPrimeDepletedJ,
      brakeThermalLoadCelsiusDelta: tempDeltaC,
    );
  }

  /// Symuluje pełny profil strat energii kinetycznej dla okrążeń kryterium lub trasy ITT.
  static CourseBrakingProfileResult evaluateCourseBrakingProfile({
    required BrakingCourseDiscipline discipline,
    required List<BrakingCornerSpec> lapCorners,
    required BrakingZoneRiderConfig config,
    int? laps,
  }) {
    final safeLaps = math.max(1, laps ?? discipline.defaultLaps);
    if (lapCorners.isEmpty) {
      return CourseBrakingProfileResult(
        discipline: discipline,
        laps: safeLaps,
        cornerCountPerLap: 0,
        totalBrakingEvents: 0,
        totalCourseDistanceMeters: 0.0,
        totalEstimatedTimeSeconds: 0.0,
        totalKineticEnergyLossKj: 0.0,
        totalTranslationalLossKj: 0.0,
        totalRotationalLossKj: 0.0,
        totalBrakeDissipatedEnergyKj: 0.0,
        totalReaccelerationWorkKj: 0.0,
        totalTimeLostInBrakingZonesSeconds: 0.0,
        totalWPrimeDepletedKj: 0.0,
        averagePowerWatts: config.riderFtpWatts * 0.85,
        estimatedNormalizedPowerWatts: config.riderFtpWatts * 0.85,
        variabilityIndex: 1.0,
        peakBrakeTempCelsius: _ambientBrakeTempC,
        thermalFadePenaltyPercent: 0.0,
        cornerResults: const [],
      );
    }

    var currentBrakeTempC = _ambientBrakeTempC;
    var peakBrakeTempC = _ambientBrakeTempC;

    double totalTransJ = 0.0;
    double totalRotJ = 0.0;
    double totalLossJ = 0.0;
    double totalBrakeDissJ = 0.0;
    double totalReaccelJ = 0.0;
    double totalWPrimeJ = 0.0;
    double totalTimeLostS = 0.0;
    double totalDistanceM = 0.0;
    double totalTimeS = 0.0;
    int totalBrakingEvents = 0;

    // Do estymacji Normalized Power (NP): ważona 4-ta potęga mocy w czasie.
    double weightedPower4Sum = 0.0;
    double weightedPowerSum = 0.0;
    final steadyPowerW =
        _estimateStraightCruisePower(lapCorners.first, config);

    final firstLapResults = <BrakingZoneEnergyResult>[];

    for (var lap = 0; lap < safeLaps; lap++) {
      for (var i = 0; i < lapCorners.length; i++) {
        final corner = lapCorners[i];
        final fadeFactor = _computeBrakeThermalFadeFactor(
          brakeTempC: currentBrakeTempC,
          brakeSystem: config.brakeSystem,
        );

        final res = evaluateCornerBrakingZone(
          corner: corner,
          config: config,
          brakeFadeFactor: fadeFactor,
        );

        if (lap == 0) {
          firstLapResults.add(res);
        }

        if (res.severity != BrakingZoneSeverity.noBrakingNeeded) {
          totalBrakingEvents++;
        }

        totalTransJ += res.translationalEnergyLossJoules;
        totalRotJ += res.rotationalEnergyLossJoules;
        totalLossJ += res.totalKineticEnergyLossJoules;
        totalBrakeDissJ += res.brakeDissipatedEnergyJoules;
        totalReaccelJ += res.reaccelerationWorkJoules;
        totalWPrimeJ += res.wPrimeDepletedJoules;
        totalTimeLostS += res.timeLostSeconds;

        // Chłodzenie konwekcyjne hamulców na prostej po zakręcie.
        currentBrakeTempC += res.brakeThermalLoadCelsiusDelta;
        if (currentBrakeTempC > peakBrakeTempC) {
          peakBrakeTempC = currentBrakeTempC;
        }

        final straightDistM = math.max(
          20.0,
          corner.straightLengthAfterMeters - res.brakingDistanceMeters,
        );
        final straightSpeedMs =
            _solveStraightSpeedFromPower(steadyPowerW, corner, config);
        final straightTimeS = straightDistM / straightSpeedMs;

        // Rozkład czasu i dystansu: hamowanie + zakręt + przyspieszenie + prosta.
        final zoneDistM = res.brakingDistanceMeters +
            corner.arcLengthMeters +
            (0.5 * (res.apexSpeedMs + res.exitSpeedMs) * res.reaccelerationDurationSeconds);
        totalDistanceM += zoneDistM + straightDistM;

        final coastAndBrakeTimeS =
            res.brakingDurationSeconds + res.apexDurationSeconds;
        final reaccelTimeS = res.reaccelerationDurationSeconds;
        totalTimeS += coastAndBrakeTimeS + reaccelTimeS + straightTimeS;

        // Chłodzenie w czasie jazdy po prostej (Newtonian cooling).
        final coolingTimeS = straightTimeS + reaccelTimeS;
        final coolingRate = 0.045 * (straightSpeedMs / 12.0);
        currentBrakeTempC = _ambientBrakeTempC +
            (currentBrakeTempC - _ambientBrakeTempC) *
                math.exp(-coolingRate * coolingTimeS);

        // Akumulacja do mocy średniej i Normalized Power (NP).
        weightedPowerSum += (coastAndBrakeTimeS * 0.0) +
            (reaccelTimeS * res.reaccelerationPeakPowerWatts) +
            (straightTimeS * steadyPowerW);
        weightedPower4Sum +=
            (reaccelTimeS * math.pow(res.reaccelerationPeakPowerWatts, 4)) +
                (straightTimeS * math.pow(steadyPowerW, 4));
      }
    }

    final avgPowerW = totalTimeS > 0.0 ? weightedPowerSum / totalTimeS : 0.0;
    final npWatts = totalTimeS > 0.0
        ? math.pow(weightedPower4Sum / totalTimeS, 0.25).toDouble()
        : 0.0;
    final vi = avgPowerW > 1.0 ? (npWatts / avgPowerW) : 1.0;

    final minFade = _computeBrakeThermalFadeFactor(
      brakeTempC: peakBrakeTempC,
      brakeSystem: config.brakeSystem,
    );
    final thermalFadePenaltyPct = ((1.0 - minFade) * 100.0).clamp(0.0, 35.0);

    return CourseBrakingProfileResult(
      discipline: discipline,
      laps: safeLaps,
      cornerCountPerLap: lapCorners.length,
      totalBrakingEvents: totalBrakingEvents,
      totalCourseDistanceMeters: totalDistanceM,
      totalEstimatedTimeSeconds: totalTimeS,
      totalKineticEnergyLossKj: totalLossJ / 1000.0,
      totalTranslationalLossKj: totalTransJ / 1000.0,
      totalRotationalLossKj: totalRotJ / 1000.0,
      totalBrakeDissipatedEnergyKj: totalBrakeDissJ / 1000.0,
      totalReaccelerationWorkKj: totalReaccelJ / 1000.0,
      totalTimeLostInBrakingZonesSeconds: totalTimeLostS,
      totalWPrimeDepletedKj: totalWPrimeJ / 1000.0,
      averagePowerWatts: avgPowerW,
      estimatedNormalizedPowerWatts: npWatts,
      variabilityIndex: vi,
      peakBrakeTempCelsius: peakBrakeTempC,
      thermalFadePenaltyPercent: thermalFadePenaltyPct,
      cornerResults: firstLapResults,
    );
  }

  /// Porównuje dwa komplety kół (np. lekkie niskostożkowe vs ciężkie aero 60mm) na krętej trasie.
  static WheelsetBrakingComparisonResult compareWheelsetsOnCourse({
    required BrakingCourseDiscipline discipline,
    required List<BrakingCornerSpec> lapCorners,
    required BrakingZoneRiderConfig baseConfig,
    required WheelsetModel wheelsetA,
    required WheelsetModel wheelsetB,
    int? laps,
  }) {
    final configA = baseConfig.copyWith(wheelset: wheelsetA);
    final configB = baseConfig.copyWith(wheelset: wheelsetB);

    final profileA = evaluateCourseBrakingProfile(
      discipline: discipline,
      lapCorners: lapCorners,
      config: configA,
      laps: laps,
    );
    final profileB = evaluateCourseBrakingProfile(
      discipline: discipline,
      lapCorners: lapCorners,
      config: configB,
      laps: laps,
    );

    final netDeltaS =
        profileA.totalEstimatedTimeSeconds - profileB.totalEstimatedTimeSeconds;
    final cornerDeltaS = profileA.totalTimeLostInBrakingZonesSeconds -
        profileB.totalTimeLostInBrakingZonesSeconds;
    final aeroStraightDeltaS = netDeltaS - cornerDeltaS;

    final energySavedKj =
        profileA.totalKineticEnergyLossKj - profileB.totalKineticEnergyLossKj;
    final rotSavedKj =
        profileA.totalRotationalLossKj - profileB.totalRotationalLossKj;
    final wPrimeSavedKj =
        profileA.totalWPrimeDepletedKj - profileB.totalWPrimeDepletedKj;

    final bIsFaster = netDeltaS >= 0.0;
    final faster = bIsFaster ? wheelsetB : wheelsetA;
    final absDeltaS = netDeltaS.abs();

    final String reasonPl;
    final String reasonEn;
    if (bIsFaster && cornerDeltaS > aeroStraightDeltaS) {
      reasonPl =
          '${faster.name} jest szybsze o ${absDeltaS.toStringAsFixed(2)} s dzięki niższej bezwładności obrotowej i szybszym wyjściom z zakrętów (${rotSavedKj.abs().toStringAsFixed(1)} kJ oszczędności obrotowej).';
      reasonEn =
          '${faster.name} is ${absDeltaS.toStringAsFixed(2)} s faster due to lower rotational inertia and quicker corner exits (${rotSavedKj.abs().toStringAsFixed(1)} kJ rotational savings).';
    } else if (!bIsFaster && cornerDeltaS < aeroStraightDeltaS) {
      reasonPl =
          '${faster.name} wygrywa o ${absDeltaS.toStringAsFixed(2)} s dzięki niższej masie wirującej na częstych dohamowaniach.';
      reasonEn =
          '${faster.name} wins by ${absDeltaS.toStringAsFixed(2)} s thanks to lower rotating mass across repeated braking zones.';
    } else {
      reasonPl =
          '${faster.name} jest szybsze o ${absDeltaS.toStringAsFixed(2)} s, ponieważ zysk aerodynamiczny na prostych przewyższa straty na przyspieszeniach.';
      reasonEn =
          '${faster.name} is ${absDeltaS.toStringAsFixed(2)} s faster as straight-line aero gains outweigh re-acceleration penalties.';
    }

    return WheelsetBrakingComparisonResult(
      wheelsetA: wheelsetA,
      wheelsetB: wheelsetB,
      profileA: profileA,
      profileB: profileB,
      netTimeDeltaSeconds: netDeltaS,
      kineticEnergySavedKj: energySavedKj,
      rotationalEnergySavedKj: rotSavedKj,
      wPrimeSavedKj: wPrimeSavedKj,
      aeroStraightTimeDeltaSeconds: aeroStraightDeltaS,
      cornerReaccelTimeDeltaSeconds: cornerDeltaS,
      fasterWheelset: faster,
      summaryReasonPl: reasonPl,
      summaryReasonEn: reasonEn,
    );
  }

  /// Gotowy preset: klasyczne miejskie kryterium 4-zakrętowe (1.2 km / runda).
  static List<BrakingCornerSpec> urbanFourCornerCriterium() {
    return const [
      BrakingCornerSpec(
        id: 'crit_t1',
        name: 'T1 Piazza 90°',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 11.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 13.8,
        straightLengthAfterMeters: 280.0,
      ),
      BrakingCornerSpec(
        id: 'crit_t2',
        name: 'T2 Market Square 90°',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 10.5,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 13.5,
        straightLengthAfterMeters: 310.0,
      ),
      BrakingCornerSpec(
        id: 'crit_t3',
        name: 'T3 Station Hairpin',
        geometryType: CornerGeometryType.hairpin180,
        radiusMeters: 6.5,
        arcAngleDegrees: 180.0,
        entrySpeedMs: 13.9,
        straightLengthAfterMeters: 260.0,
      ),
      BrakingCornerSpec(
        id: 'crit_t4',
        name: 'T4 Finish Sweeper',
        geometryType: CornerGeometryType.sweeper,
        radiusMeters: 26.0,
        arcAngleDegrees: 75.0,
        entrySpeedMs: 14.2,
        straightLengthAfterMeters: 340.0,
      ),
    ];
  }

  /// Gotowy preset: techniczne kryterium z 8 zakrętami (szykany, rondo, nawroty).
  static List<BrakingCornerSpec> technicalEightCornerCriterium() {
    return const [
      BrakingCornerSpec(
        id: 'tech_c1',
        name: 'C1 Old Town Entry',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 10.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 13.6,
        straightLengthAfterMeters: 190.0,
      ),
      BrakingCornerSpec(
        id: 'tech_c2',
        name: 'C2 Tram Chicane Left',
        geometryType: CornerGeometryType.chicane,
        radiusMeters: 8.5,
        arcAngleDegrees: 105.0,
        entrySpeedMs: 12.2,
        straightLengthAfterMeters: 140.0,
      ),
      BrakingCornerSpec(
        id: 'tech_c3',
        name: 'C3 Fountain Roundabout',
        geometryType: CornerGeometryType.roundabout,
        radiusMeters: 13.0,
        arcAngleDegrees: 125.0,
        entrySpeedMs: 12.8,
        straightLengthAfterMeters: 210.0,
      ),
      BrakingCornerSpec(
        id: 'tech_c4',
        name: 'C4 River Hairpin',
        geometryType: CornerGeometryType.hairpin180,
        radiusMeters: 6.0,
        arcAngleDegrees: 180.0,
        entrySpeedMs: 13.2,
        straightLengthAfterMeters: 240.0,
      ),
      BrakingCornerSpec(
        id: 'tech_c5',
        name: 'C5 Boulevard 90°',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 12.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 13.7,
        straightLengthAfterMeters: 180.0,
      ),
      BrakingCornerSpec(
        id: 'tech_c6',
        name: 'C6 Park Chicane',
        geometryType: CornerGeometryType.chicane,
        radiusMeters: 9.0,
        arcAngleDegrees: 100.0,
        entrySpeedMs: 12.5,
        straightLengthAfterMeters: 165.0,
      ),
      BrakingCornerSpec(
        id: 'tech_c7',
        name: 'C7 Museum Turn',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 11.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 13.1,
        straightLengthAfterMeters: 220.0,
      ),
      BrakingCornerSpec(
        id: 'tech_c8',
        name: 'C8 Final Kick Sweeper',
        geometryType: CornerGeometryType.sweeper,
        radiusMeters: 24.0,
        arcAngleDegrees: 65.0,
        entrySpeedMs: 14.0,
        straightLengthAfterMeters: 300.0,
      ),
    ];
  }

  /// Gotowy preset: kręta czasówka miejska ITT z wieloma nawrotami i rondami.
  static List<BrakingCornerSpec> twistyUrbanTimeTrial() {
    return const [
      BrakingCornerSpec(
        id: 'itt_1',
        name: 'Start Ramp 90°',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 12.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 13.0,
        straightLengthAfterMeters: 650.0,
      ),
      BrakingCornerSpec(
        id: 'itt_2',
        name: 'Bridge Approach Roundabout',
        geometryType: CornerGeometryType.roundabout,
        radiusMeters: 15.0,
        arcAngleDegrees: 110.0,
        entrySpeedMs: 14.5,
        straightLengthAfterMeters: 900.0,
      ),
      BrakingCornerSpec(
        id: 'itt_3',
        name: 'Industrial Turnaround 180°',
        geometryType: CornerGeometryType.hairpin180,
        radiusMeters: 7.0,
        arcAngleDegrees: 180.0,
        entrySpeedMs: 14.8,
        straightLengthAfterMeters: 1100.0,
      ),
      BrakingCornerSpec(
        id: 'itt_4',
        name: 'Cathedral Cobble Chicane',
        geometryType: CornerGeometryType.chicane,
        radiusMeters: 9.5,
        arcAngleDegrees: 105.0,
        entrySpeedMs: 14.1,
        surfaceType: SegmentSurfaceType.cobblestonesSector2,
        straightLengthAfterMeters: 720.0,
      ),
      BrakingCornerSpec(
        id: 'itt_5',
        name: 'Harbor Hairpin',
        geometryType: CornerGeometryType.hairpin180,
        radiusMeters: 6.5,
        arcAngleDegrees: 180.0,
        entrySpeedMs: 14.6,
        straightLengthAfterMeters: 850.0,
      ),
      BrakingCornerSpec(
        id: 'itt_6',
        name: 'Finish Straight 90°',
        geometryType: CornerGeometryType.ninetyDegreeTurn,
        radiusMeters: 13.0,
        arcAngleDegrees: 90.0,
        entrySpeedMs: 14.3,
        straightLengthAfterMeters: 550.0,
      ),
    ];
  }

  static double _computeEffectiveFriction({
    required SegmentSurfaceType surfaceType,
    required double wetness,
    required TireCompoundType compound,
    required int corneringSkill,
  }) {
    final double dryMu;
    final double wetMu;
    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        dryMu = 0.88;
        wetMu = 0.56;
        break;
      case SegmentSurfaceType.roughAsphalt:
      case SegmentSurfaceType.concrete:
        dryMu = 0.84;
        wetMu = 0.52;
        break;
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        dryMu = 0.72;
        wetMu = 0.38;
        break;
      case SegmentSurfaceType.gravelStrade:
        dryMu = 0.64;
        wetMu = 0.44;
        break;
    }

    final baseMu = _lerp(dryMu, wetMu, wetness);
    final compoundMult = _lerp(
      compound.dryGripMultiplier,
      compound.wetGripMultiplier,
      wetness,
    );
    final skillMult = 0.92 + (corneringSkill.clamp(1, 100) / 100.0) * 0.14;
    return (baseMu * compoundMult * skillMult).clamp(0.28, 1.05);
  }

  static double _computeBrakeThermalFadeFactor({
    required double brakeTempC,
    required BrakeSystemType brakeSystem,
  }) {
    final thresholdC =
        brakeSystem == BrakeSystemType.hydraulicDisc ? 220.0 : 155.0;
    if (brakeTempC <= thresholdC) return 1.0;
    final overheatC = brakeTempC - thresholdC;
    final penalty =
        (overheatC / 250.0) * (brakeSystem == BrakeSystemType.carbonRim ? 0.35 : 0.18);
    return (1.0 - penalty).clamp(0.65, 1.0);
  }

  static double _estimateStraightCruisePower(
    BrakingCornerSpec sampleCorner,
    BrakingZoneRiderConfig config,
  ) {
    final v = math.max(5.0, sampleCorner.entrySpeedMs);
    final aeroW = 0.5 * config.airDensityKgM3 * config.effectiveCda * v * v * v;
    final rollW = config.totalSystemMassKg *
        PhysicsConstants.gravity *
        config.baseCrr *
        v;
    return ((aeroW + rollW) / config.drivetrainEfficiency.clamp(0.80, 1.0))
        .clamp(180.0, config.riderFtpWatts * 1.15);
  }

  static double _solveStraightSpeedFromPower(
    double powerWatts,
    BrakingCornerSpec corner,
    BrakingZoneRiderConfig config,
  ) {
    // Jednokrokowe przybliżenie Newtona-Raphsona startujące z prędkości wejściowej.
    var v = math.max(6.0, corner.entrySpeedMs);
    final wheelPowerW = powerWatts * config.drivetrainEfficiency.clamp(0.80, 1.0);
    final kAero = 0.5 * config.airDensityKgM3 * config.effectiveCda;
    final fRoll =
        config.totalSystemMassKg * PhysicsConstants.gravity * config.baseCrr;

    for (var iter = 0; iter < 5; iter++) {
      final f = kAero * v * v * v + fRoll * v - wheelPowerW;
      final df = 3.0 * kAero * v * v + fRoll;
      if (df <= 1e-6) break;
      v = (v - f / df).clamp(4.0, 26.0);
    }
    return v;
  }

  static BrakingZoneSeverity _classifySeverity({
    required double speedDropRatio,
    required double kineticLossJ,
  }) {
    if (speedDropRatio <= 0.02 || kineticLossJ < 80.0) {
      return BrakingZoneSeverity.noBrakingNeeded;
    }
    if (speedDropRatio < 0.18) {
      return BrakingZoneSeverity.lightScrub;
    }
    if (speedDropRatio < 0.35) {
      return BrakingZoneSeverity.moderateBraking;
    }
    if (speedDropRatio < 0.52) {
      return BrakingZoneSeverity.heavyThresholdBraking;
    }
    return BrakingZoneSeverity.emergencyHairpin;
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
