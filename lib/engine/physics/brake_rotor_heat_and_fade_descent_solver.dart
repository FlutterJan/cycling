// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';

/// Średnica tarczy hamulcowej w układzie hydraulicznym roweru szosowego.
enum BrakeRotorDiameter {
  /// Lekka tarcza 140 mm (niższa masa rotująca, mniejsza pojemność cieplna).
  mm140(
    labelEn: '140 mm Rotor',
    labelPl: 'Tarcza 140 mm',
    diameterMm: 140.0,
    effectiveRadiusMeters: 0.060,
    baseMassKg: 0.095,
    effectiveThermalMassKg: 0.088,
    coolingAreaFactor: 1.00,
    leverageMultiplier: 1.00,
  ),

  /// Standardowa tarcza alpejska 160 mm (większa pojemność cieplna i ramię siły).
  mm160(
    labelEn: '160 mm Rotor',
    labelPl: 'Tarcza 160 mm',
    diameterMm: 160.0,
    effectiveRadiusMeters: 0.070,
    baseMassKg: 0.120,
    effectiveThermalMassKg: 0.112,
    coolingAreaFactor: 1.32,
    leverageMultiplier: 1.167,
  ),

  /// Wzmocniona tarcza 180 mm (tandemy, ciężcy kolarze, ekstremalne zjazdy).
  mm180(
    labelEn: '180 mm Rotor',
    labelPl: 'Tarcza 180 mm',
    diameterMm: 180.0,
    effectiveRadiusMeters: 0.080,
    baseMassKg: 0.148,
    effectiveThermalMassKg: 0.138,
    coolingAreaFactor: 1.62,
    leverageMultiplier: 1.333,
  );

  final String labelEn;
  final String labelPl;
  final double diameterMm;
  final double effectiveRadiusMeters;
  final double baseMassKg;
  final double effectiveThermalMassKg;
  final double coolingAreaFactor;
  final double leverageMultiplier;

  const BrakeRotorDiameter({
    required this.labelEn,
    required this.labelPl,
    required this.diameterMm,
    required this.effectiveRadiusMeters,
    required this.baseMassKg,
    required this.effectiveThermalMassKg,
    required this.coolingAreaFactor,
    required this.leverageMultiplier,
  });
}

/// Technologia odprowadzania ciepła tarczy hamulcowej.
enum BrakeRotorCoolingTech {
  /// Klasyczna tarcza ze stali nierdzewnej.
  standardSteel(
    labelEn: 'Standard Stainless Steel',
    labelPl: 'Standardowa stalowa',
    specificHeatJPerKgK: 490.0,
    convectionMultiplier: 1.00,
    emissivity: 0.48,
  ),

  /// Tarcza wielowarstwowa z rdzeniem aluminiowym i radiatorami (Ice-Tech).
  iceTechFinned(
    labelEn: 'Ice-Tech Finned Core',
    labelPl: 'Wielowarstwowa z radiatorami (Ice-Tech)',
    specificHeatJPerKgK: 615.0,
    convectionMultiplier: 1.24,
    emissivity: 0.62,
  );

  final String labelEn;
  final String labelPl;
  final double specificHeatJPerKgK;
  final double convectionMultiplier;
  final double emissivity;

  const BrakeRotorCoolingTech({
    required this.labelEn,
    required this.labelPl,
    required this.specificHeatJPerKgK,
    required this.convectionMultiplier,
    required this.emissivity,
  });
}

/// Mieszanka klocków hamulcowych wpływająca na próg i krzywą Brake Fade.
enum BrakePadCompound {
  /// Klocki żywiczne (organiczne) — świetna modulacja, niższy próg przegrzania.
  resinOrganic(
    labelEn: 'Resin / Organic',
    labelPl: 'Żywiczne (organiczne)',
    fadeThresholdCelsius: 425.0,
    fadeSlope: 0.0036,
    minFadeFloor: 0.38,
    rotorHeatShare: 0.90,
  ),

  /// Klocki wyścigowe półmetaliczne z radiatorem — zrównoważone WorldTour.
  worldTourFinned(
    labelEn: 'WorldTour Finned Semi-Metallic',
    labelPl: 'Wyścigowe półmetaliczne z radiatorem',
    fadeThresholdCelsius: 450.0,
    fadeSlope: 0.0029,
    minFadeFloor: 0.44,
    rotorHeatShare: 0.89,
  ),

  /// Klocki spiekane (metaliczne) — najwyższa odporność na przegrzanie.
  sinteredMetallic(
    labelEn: 'Sintered Metallic',
    labelPl: 'Spiekane (metaliczne)',
    fadeThresholdCelsius: 475.0,
    fadeSlope: 0.0022,
    minFadeFloor: 0.50,
    rotorHeatShare: 0.87,
  );

  final String labelEn;
  final String labelPl;
  final double fadeThresholdCelsius;
  final double fadeSlope;
  final double minFadeFloor;
  final double rotorHeatShare;

  const BrakePadCompound({
    required this.labelEn,
    required this.labelPl,
    required this.fadeThresholdCelsius,
    required this.fadeSlope,
    required this.minFadeFloor,
    required this.rotorHeatShare,
  });
}

/// Strefa termiczna tarczy hamulcowej.
enum RotorThermalZone {
  optimal('Optimal Bite', 'Optymalna temperatura'),
  warm('Warm Performance', 'Rozgrzana roboczo'),
  hot('High Thermal Load', 'Wysokie obciążenie cieplne'),
  fadeOnset('Brake Fade (>450°C)', 'Spadek siły hamowania (Brake Fade)'),
  criticalBoil('Critical Fade & Fluid Boil Risk', 'Krytyczne przegrzanie i ryzyko zagotowania płynu');

  final String labelEn;
  final String labelPl;

  const RotorThermalZone(this.labelEn, this.labelPl);
}

/// Presety słynnych technicznych zjazdów alpejskich z licznymi serpentynami.
enum AlpineDescentPreset {
  passoDelloStelvio(
    labelEn: 'Passo dello Stelvio (North)',
    labelPl: 'Passo dello Stelvio (Strona Północna)',
    hairpinCount: 24,
    averageGradientPercent: -8.6,
    averageStraightMeters: 340.0,
    startAltitudeMeters: 2757.0,
    endAltitudeMeters: 1550.0,
    entrySpeedKmh: 85.0,
    apexSpeedKmh: 25.0,
  ),
  alpeDHuez(
    labelEn: 'Alpe d\'Huez (21 Hairpins)',
    labelPl: 'Alpe d\'Huez (21 serpentyn)',
    hairpinCount: 21,
    averageGradientPercent: -8.1,
    averageStraightMeters: 410.0,
    startAltitudeMeters: 1850.0,
    endAltitudeMeters: 740.0,
    entrySpeedKmh: 85.0,
    apexSpeedKmh: 25.0,
  ),
  colDuGalibier(
    labelEn: 'Col du Galibier (South-West)',
    labelPl: 'Col du Galibier (Zjazd do Lautaret)',
    hairpinCount: 14,
    averageGradientPercent: -7.4,
    averageStraightMeters: 520.0,
    startAltitudeMeters: 2642.0,
    endAltitudeMeters: 1750.0,
    entrySpeedKmh: 88.0,
    apexSpeedKmh: 28.0,
  ),
  passoGavia(
    labelEn: 'Passo Gavia (Technical South)',
    labelPl: 'Passo Gavia (Techniczny zjazd)',
    hairpinCount: 16,
    averageGradientPercent: -9.5,
    averageStraightMeters: 290.0,
    startAltitudeMeters: 2621.0,
    endAltitudeMeters: 1400.0,
    entrySpeedKmh: 82.0,
    apexSpeedKmh: 24.0,
  );

  final String labelEn;
  final String labelPl;
  final int hairpinCount;
  final double averageGradientPercent;
  final double averageStraightMeters;
  final double startAltitudeMeters;
  final double endAltitudeMeters;
  final double entrySpeedKmh;
  final double apexSpeedKmh;

  const AlpineDescentPreset({
    required this.labelEn,
    required this.labelPl,
    required this.hairpinCount,
    required this.averageGradientPercent,
    required this.averageStraightMeters,
    required this.startAltitudeMeters,
    required this.endAltitudeMeters,
    required this.entrySpeedKmh,
    required this.apexSpeedKmh,
  });
}

/// Konfiguracja układu hamulcowego i kolarza na zjeździe.
class BrakeRotorSystemConfig {
  final BrakeRotorDiameter frontRotor;
  final BrakeRotorDiameter rearRotor;
  final BrakeRotorCoolingTech coolingTech;
  final BrakePadCompound padCompound;

  /// Masa całkowita układu (kolarz + rower + bidony) w kg.
  final double totalSystemMassKg;

  /// Współczynnik oporu aerodynamicznego CdA w pozycji zjazdowej [m^2].
  final double descentCda;

  /// Współczynnik oporu toczenia opon Crr.
  final double tireCrr;

  /// Maksymalne opóźnienie hamowania bazowe bez przegrzania [m/s^2] (przed korektą przyczepności).
  final double nominalMaxDecelerationMs2;

  /// Udział przedniego hamulca w całkowitej sile hamowania (0.50–0.85).
  final double frontBrakeBias;

  /// Umiejętność techniki zjazdu (0–100) zmniejszająca niepotrzebne "wiszenie na klamkach".
  final int descenderSkill;

  const BrakeRotorSystemConfig({
    this.frontRotor = BrakeRotorDiameter.mm160,
    this.rearRotor = BrakeRotorDiameter.mm140,
    this.coolingTech = BrakeRotorCoolingTech.iceTechFinned,
    this.padCompound = BrakePadCompound.worldTourFinned,
    this.totalSystemMassKg = 74.0,
    this.descentCda = 0.275,
    this.tireCrr = PhysicsConstants.crrSmoothAsphalt,
    this.nominalMaxDecelerationMs2 = 7.4,
    this.frontBrakeBias = 0.72,
    this.descenderSkill = 78,
  });

  BrakeRotorSystemConfig copyWith({
    BrakeRotorDiameter? frontRotor,
    BrakeRotorDiameter? rearRotor,
    BrakeRotorCoolingTech? coolingTech,
    BrakePadCompound? padCompound,
    double? totalSystemMassKg,
    double? descentCda,
    double? tireCrr,
    double? nominalMaxDecelerationMs2,
    double? frontBrakeBias,
    int? descenderSkill,
  }) {
    return BrakeRotorSystemConfig(
      frontRotor: frontRotor ?? this.frontRotor,
      rearRotor: rearRotor ?? this.rearRotor,
      coolingTech: coolingTech ?? this.coolingTech,
      padCompound: padCompound ?? this.padCompound,
      totalSystemMassKg: totalSystemMassKg ?? this.totalSystemMassKg,
      descentCda: descentCda ?? this.descentCda,
      tireCrr: tireCrr ?? this.tireCrr,
      nominalMaxDecelerationMs2:
          nominalMaxDecelerationMs2 ?? this.nominalMaxDecelerationMs2,
      frontBrakeBias: frontBrakeBias ?? this.frontBrakeBias,
      descenderSkill: descenderSkill ?? this.descenderSkill,
    );
  }
}

/// Specyfikacja pojedynczego nawrotu / serpentyny na zjeździe alpejskim.
class AlpineHairpinCornerSpec {
  final int index;
  final double entrySpeedKmh;
  final double apexSpeedKmh;
  final double gradientPercent;
  final double straightApproachMeters;
  final double altitudeMeters;
  final double availableBrakingRunwayMeters;

  const AlpineHairpinCornerSpec({
    required this.index,
    this.entrySpeedKmh = 85.0,
    this.apexSpeedKmh = 25.0,
    this.gradientPercent = -8.5,
    this.straightApproachMeters = 350.0,
    this.altitudeMeters = 1800.0,
    this.availableBrakingRunwayMeters = 62.0,
  });
}

/// Warunki atmosferyczne na zjeździe wpływające na chłodzenie tarcz i przyczepność.
class DescentEnvironmentConditions {
  final double ambientTempCelsius;
  final bool isWetRoad;
  final double headwindMs;

  const DescentEnvironmentConditions({
    this.ambientTempCelsius = 18.0,
    this.isWetRoad = false,
    this.headwindMs = 0.0,
  });
}

/// Wynik pojedynczego gwałtownego dohamowania przed serpentyną.
class HairpinBrakingStepResult {
  final int hairpinIndex;
  final double frontTempBeforeCelsius;
  final double frontTempAfterCelsius;
  final double rearTempBeforeCelsius;
  final double rearTempAfterCelsius;
  final double energyDissipatedKj;
  final double frontEnergyKj;
  final double rearEnergyKj;
  final double fadeFactor;
  final double brakeForceLossPercent;
  final double baselineBrakingDistanceMeters;
  final double actualBrakingDistanceMeters;
  final double brakingDistanceExtensionMeters;
  final double brakingDurationSeconds;
  final double timeLostToFadeSeconds;
  final bool isFading;
  final bool isOvershootRisk;
  final RotorThermalZone frontThermalZone;
  final RotorThermalZone rearThermalZone;

  const HairpinBrakingStepResult({
    required this.hairpinIndex,
    required this.frontTempBeforeCelsius,
    required this.frontTempAfterCelsius,
    required this.rearTempBeforeCelsius,
    required this.rearTempAfterCelsius,
    required this.energyDissipatedKj,
    required this.frontEnergyKj,
    required this.rearEnergyKj,
    required this.fadeFactor,
    required this.brakeForceLossPercent,
    required this.baselineBrakingDistanceMeters,
    required this.actualBrakingDistanceMeters,
    required this.brakingDistanceExtensionMeters,
    required this.brakingDurationSeconds,
    required this.timeLostToFadeSeconds,
    required this.isFading,
    required this.isOvershootRisk,
    required this.frontThermalZone,
    required this.rearThermalZone,
  });

  double get maxRotorTempAfterCelsius =>
      math.max(frontTempAfterCelsius, rearTempAfterCelsius);
}

/// Podsumowanie symulacji całego technicznego zjazdu alpejskiego.
class AlpineDescentBrakeSimulationResult {
  final BrakeRotorSystemConfig config;
  final List<HairpinBrakingStepResult> hairpinSteps;
  final double peakFrontTempCelsius;
  final double peakRearTempCelsius;
  final double finalFrontTempCelsius;
  final double finalRearTempCelsius;
  final int fadeTriggeredHairpinCount;
  final int overshootRiskHairpinCount;
  final double maxBrakingDistanceExtensionMeters;
  final double minFadeFactorObserved;
  final double totalTimeLostToFadeSeconds;
  final RotorThermalZone peakThermalZone;

  const AlpineDescentBrakeSimulationResult({
    required this.config,
    required this.hairpinSteps,
    required this.peakFrontTempCelsius,
    required this.peakRearTempCelsius,
    required this.finalFrontTempCelsius,
    required this.finalRearTempCelsius,
    required this.fadeTriggeredHairpinCount,
    required this.overshootRiskHairpinCount,
    required this.maxBrakingDistanceExtensionMeters,
    required this.minFadeFactorObserved,
    required this.totalTimeLostToFadeSeconds,
    required this.peakThermalZone,
  });

  double get peakMaxTempCelsius =>
      math.max(peakFrontTempCelsius, peakRearTempCelsius);

  double get maxBrakeForceLossPercent => (1.0 - minFadeFactorObserved) * 100.0;
}

/// Bezpośrednie porównanie zestawu 140 mm vs 160 mm na tym samym zjeździe.
class RotorSizeDescentComparison {
  final AlpineDescentBrakeSimulationResult result140mm;
  final AlpineDescentBrakeSimulationResult result160mm;
  final double peakTempDifferenceCelsius;
  final double maxExtensionDifferenceMeters;
  final double totalTimeSavedWith160mmSeconds;
  final int fadeHairpinsAvoidedWith160mm;

  const RotorSizeDescentComparison({
    required this.result140mm,
    required this.result160mm,
    required this.peakTempDifferenceCelsius,
    required this.maxExtensionDifferenceMeters,
    required this.totalTimeSavedWith160mmSeconds,
    required this.fadeHairpinsAvoidedWith160mm,
  });
}

/// Zaawansowany solver fizyki termiki tarcz hamulcowych i zjawiska Brake Fade
/// na długich, technicznych zjazdach alpejskich (140 mm vs 160 mm).
class BrakeRotorHeatAndFadeDescentSolver {
  BrakeRotorHeatAndFadeDescentSolver._();

  /// Kanoniczny próg przegrzania tarcz hamulcowych, powyżej którego następuje Brake Fade.
  static const double canonicalFadeThresholdCelsius = 450.0;

  /// Temperatura krytyczna z ryzykiem zagotowania płynu hydraulicznego i wichrowania tarczy.
  static const double criticalBoilThresholdCelsius = 550.0;

  /// Stała Stefana-Boltzmanna [W / (m^2 * K^4)].
  static const double _stefanBoltzmann = 5.670374419e-8;

  /// Bazowa efektywna powierzchnia wymiany ciepła tarczy 140 mm (obie strony + krawędź) [m^2].
  static const double _base140mmCoolingAreaM2 = 0.0155;

  /// Wylicza współczynnik zachowanej siły hamowania (1.0 = brak fade, <1.0 = Brake Fade)
  /// dla danej temperatury tarczy oraz mieszanki klocków.
  static double computeFadeFactor({
    required double rotorTempCelsius,
    BrakePadCompound padCompound = BrakePadCompound.worldTourFinned,
  }) {
    final threshold = padCompound.fadeThresholdCelsius;
    if (rotorTempCelsius <= threshold) {
      return 1.0;
    }
    final excessTemp = rotorTempCelsius - threshold;
    // Nieliniowy spadek współczynnika tarcia po przekroczeniu progu 450°C.
    final decay = math.exp(-padCompound.fadeSlope * math.pow(excessTemp, 1.15));
    final rawFactor =
        padCompound.minFadeFloor + (1.0 - padCompound.minFadeFloor) * decay;
    return rawFactor.clamp(padCompound.minFadeFloor, 1.0);
  }

  /// Klasyfikuje aktualną strefę termiczną tarczy hamulcowej.
  static RotorThermalZone classifyThermalZone(
    double rotorTempCelsius, {
    double fadeThresholdCelsius = canonicalFadeThresholdCelsius,
  }) {
    if (rotorTempCelsius >= criticalBoilThresholdCelsius) {
      return RotorThermalZone.criticalBoil;
    }
    if (rotorTempCelsius > fadeThresholdCelsius) {
      return RotorThermalZone.fadeOnset;
    }
    if (rotorTempCelsius >= 320.0) {
      return RotorThermalZone.hot;
    }
    if (rotorTempCelsius >= 150.0) {
      return RotorThermalZone.warm;
    }
    return RotorThermalZone.optimal;
  }

  /// Oblicza moc chłodzenia konwekcyjnego i radiacyjnego tarczy [W] w danych warunkach.
  static double computeCoolingPowerWatts({
    required double rotorTempCelsius,
    required double ambientTempCelsius,
    required double bikeSpeedMs,
    required BrakeRotorDiameter rotor,
    required BrakeRotorCoolingTech coolingTech,
    required double altitudeMeters,
    DescentEnvironmentConditions environment =
        const DescentEnvironmentConditions(),
  }) {
    final deltaT = rotorTempCelsius - ambientTempCelsius;
    if (deltaT <= 0.0) {
      return 0.0;
    }

    final airDensity = PhysicsConstants.getAirDensityAtAltitude(altitudeMeters);
    final densityRatio = airDensity / PhysicsConstants.seaLevelAirDensity;
    final effectiveAirSpeed =
        math.max(1.5, bikeSpeedMs + environment.headwindMs);

    // Współczynnik konwekcji wymuszonej rośnie z prędkością (~v^0.75) i gęstością powietrza.
    final wetMultiplier = environment.isWetRoad ? 1.38 : 1.0;
    final hConv = (12.0 + 11.0 * math.pow(effectiveAirSpeed, 0.75)) *
        math.pow(densityRatio, 0.6) *
        coolingTech.convectionMultiplier *
        wetMultiplier;

    final areaM2 = _base140mmCoolingAreaM2 * rotor.coolingAreaFactor;
    final convectiveWatts = hConv * areaM2 * deltaT;

    final tRotorK = rotorTempCelsius + 273.15;
    final tAmbientK = ambientTempCelsius + 273.15;
    final radiativeWatts = coolingTech.emissivity *
        _stefanBoltzmann *
        areaM2 *
        (math.pow(tRotorK, 4) - math.pow(tAmbientK, 4));

    return math.max(0.0, convectiveWatts + radiativeWatts);
  }

  /// Symuluje chłodzenie tarczy na odcinku prostym między serpentynami (z ewentualnym drag braking).
  static double simulateCoolingInterval({
    required double startTempCelsius,
    required double intervalDistanceMeters,
    required double averageSpeedKmh,
    required BrakeRotorDiameter rotor,
    required BrakeRotorCoolingTech coolingTech,
    required double altitudeMeters,
    double dragBrakingHeatWatts = 0.0,
    DescentEnvironmentConditions environment =
        const DescentEnvironmentConditions(),
  }) {
    if (intervalDistanceMeters <= 0.0 || averageSpeedKmh <= 1.0) {
      return startTempCelsius;
    }

    final speedMs = averageSpeedKmh / 3.6;
    final totalDurationSec = intervalDistanceMeters / speedMs;
    const stepSec = 0.25;
    final steps = math.max(1, (totalDurationSec / stepSec).ceil());
    final dt = totalDurationSec / steps;

    final thermalCapacityJPerK =
        rotor.effectiveThermalMassKg * coolingTech.specificHeatJPerKgK;
    var tempC = startTempCelsius;

    for (var i = 0; i < steps; i++) {
      final coolingW = computeCoolingPowerWatts(
        rotorTempCelsius: tempC,
        ambientTempCelsius: environment.ambientTempCelsius,
        bikeSpeedMs: speedMs,
        rotor: rotor,
        coolingTech: coolingTech,
        altitudeMeters: altitudeMeters,
        environment: environment,
      );
      final netPowerW = dragBrakingHeatWatts - coolingW;
      tempC += (netPowerW * dt) / thermalCapacityJPerK;
      if (tempC < environment.ambientTempCelsius) {
        tempC = environment.ambientTempCelsius;
      }
    }

    return tempC;
  }

  /// Symuluje pojedyncze gwałtowne dohamowanie przed serpentyną (np. z 85 km/h do 25 km/h).
  static HairpinBrakingStepResult simulateSingleHairpinBraking({
    required AlpineHairpinCornerSpec corner,
    required BrakeRotorSystemConfig config,
    required double frontTempBeforeCelsius,
    required double rearTempBeforeCelsius,
    DescentEnvironmentConditions environment =
        const DescentEnvironmentConditions(),
  }) {
    final vEntry = math.max(0.5, corner.entrySpeedKmh / 3.6);
    final vApex = math.max(0.5, corner.apexSpeedKmh / 3.6);

    if (vEntry <= vApex) {
      return HairpinBrakingStepResult(
        hairpinIndex: corner.index,
        frontTempBeforeCelsius: frontTempBeforeCelsius,
        frontTempAfterCelsius: frontTempBeforeCelsius,
        rearTempBeforeCelsius: rearTempBeforeCelsius,
        rearTempAfterCelsius: rearTempBeforeCelsius,
        energyDissipatedKj: 0.0,
        frontEnergyKj: 0.0,
        rearEnergyKj: 0.0,
        fadeFactor: 1.0,
        brakeForceLossPercent: 0.0,
        baselineBrakingDistanceMeters: 0.0,
        actualBrakingDistanceMeters: 0.0,
        brakingDistanceExtensionMeters: 0.0,
        brakingDurationSeconds: 0.0,
        timeLostToFadeSeconds: 0.0,
        isFading: false,
        isOvershootRisk: false,
        frontThermalZone: classifyThermalZone(
          frontTempBeforeCelsius,
          fadeThresholdCelsius: config.padCompound.fadeThresholdCelsius,
        ),
        rearThermalZone: classifyThermalZone(
          rearTempBeforeCelsius,
          fadeThresholdCelsius: config.padCompound.fadeThresholdCelsius,
        ),
      );
    }

    final mass = math.max(40.0, config.totalSystemMassKg);
    final slopeAngleRad = math.atan(corner.gradientPercent / 100.0);
    // Na zjeździe gradientPercent < 0, więc siła ciężkości przyspiesza kolarza w dół.
    final gravityDownhillAccel =
        corner.gradientPercent < 0 ? -PhysicsConstants.gravity * math.sin(slopeAngleRad) : 0.0;

    final airDensity =
        PhysicsConstants.getAirDensityAtAltitude(corner.altitudeMeters);
    final vAvg = 0.5 * (vEntry + vApex);
    final aeroDragForce =
        0.5 * airDensity * config.descentCda * vAvg * vAvg;
    final rollingForce =
        mass * PhysicsConstants.gravity * config.tireCrr * math.cos(slopeAngleRad);
    final passiveDecel = (aeroDragForce + rollingForce) / mass;

    // Dostępna przyczepność opony ogranicza maksymalne opóźnienie (na mokrym spada).
    final roadGripMultiplier = environment.isWetRoad ? 0.72 : 1.0;
    final maxGripDecel =
        config.nominalMaxDecelerationMs2 * roadGripMultiplier;

    // Ramię tarczy (160 mm vs 140 mm) wpływa na moment hamujący przy tym samym nacisku klamki.
    final frontLeverage = config.frontRotor.leverageMultiplier;
    final rearLeverage = config.rearRotor.leverageMultiplier;
    final weightedLeverage = config.frontBrakeBias * frontLeverage +
        (1.0 - config.frontBrakeBias) * rearLeverage;
    final baselineBrakeDecel =
        math.min(maxGripDecel, config.nominalMaxDecelerationMs2 * math.min(1.06, 0.94 + 0.06 * weightedLeverage));

    final baselineNetDecel =
        math.max(1.8, baselineBrakeDecel + passiveDecel - gravityDownhillAccel);
    final deltaV2 = vEntry * vEntry - vApex * vApex;
    final baselineDistance = deltaV2 / (2.0 * baselineNetDecel);
    final baselineDuration = (vEntry - vApex) / baselineNetDecel;

    // Fade liczony na podstawie średniej temperatury w strefie hamowania (iteracja 2-krokowa).
    final frontBias = config.frontBrakeBias.clamp(0.50, 0.85);
    final rearBias = 1.0 - frontBias;

    var estFrontAfter = frontTempBeforeCelsius;
    var estRearAfter = rearTempBeforeCelsius;
    var effectiveFade = 1.0;
    var actualDistance = baselineDistance;
    var actualDuration = baselineDuration;
    var totalBrakeEnergyJ = 0.0;
    var frontEnergyJ = 0.0;
    var rearEnergyJ = 0.0;

    for (var iter = 0; iter < 2; iter++) {
      final frontMidTemp = 0.5 * (frontTempBeforeCelsius + estFrontAfter);
      final rearMidTemp = 0.5 * (rearTempBeforeCelsius + estRearAfter);

      final frontFade = computeFadeFactor(
        rotorTempCelsius: frontMidTemp,
        padCompound: config.padCompound,
      );
      final rearFade = computeFadeFactor(
        rotorTempCelsius: rearMidTemp,
        padCompound: config.padCompound,
      );
      effectiveFade = frontBias * frontFade + rearBias * rearFade;

      final fadedBrakeDecel = baselineBrakeDecel * effectiveFade;
      final netDecel =
          math.max(1.2, fadedBrakeDecel + passiveDecel - gravityDownhillAccel);
      actualDistance = deltaV2 / (2.0 * netDecel);
      actualDuration = (vEntry - vApex) / netDecel;

      // Bilans energetyczny: delta E_kin + delta E_pot - W_aero - W_roll.
      final deltaEKin = 0.5 * mass * deltaV2;
      final deltaEPot = mass * gravityDownhillAccel * actualDistance;
      final passiveWork = (aeroDragForce + rollingForce) * actualDistance;
      totalBrakeEnergyJ = math.max(0.0, deltaEKin + deltaEPot - passiveWork);

      final rotorEnergyJ = totalBrakeEnergyJ * config.padCompound.rotorHeatShare;
      frontEnergyJ = rotorEnergyJ * frontBias;
      rearEnergyJ = rotorEnergyJ * rearBias;

      final frontCoolingJ = computeCoolingPowerWatts(
            rotorTempCelsius: frontMidTemp,
            ambientTempCelsius: environment.ambientTempCelsius,
            bikeSpeedMs: vAvg,
            rotor: config.frontRotor,
            coolingTech: config.coolingTech,
            altitudeMeters: corner.altitudeMeters,
            environment: environment,
          ) *
          actualDuration;

      final rearCoolingJ = computeCoolingPowerWatts(
            rotorTempCelsius: rearMidTemp,
            ambientTempCelsius: environment.ambientTempCelsius,
            bikeSpeedMs: vAvg,
            rotor: config.rearRotor,
            coolingTech: config.coolingTech,
            altitudeMeters: corner.altitudeMeters,
            environment: environment,
          ) *
          actualDuration;

      final frontCap =
          config.frontRotor.effectiveThermalMassKg *
          config.coolingTech.specificHeatJPerKgK;
      final rearCap =
          config.rearRotor.effectiveThermalMassKg *
          config.coolingTech.specificHeatJPerKgK;

      estFrontAfter = math.max(
        environment.ambientTempCelsius,
        frontTempBeforeCelsius + (frontEnergyJ - frontCoolingJ) / frontCap,
      );
      estRearAfter = math.max(
        environment.ambientTempCelsius,
        rearTempBeforeCelsius + (rearEnergyJ - rearCoolingJ) / rearCap,
      );
    }

    final extensionMeters = math.max(0.0, actualDistance - baselineDistance);
    final isFading = effectiveFade < 0.999 ||
        estFrontAfter > config.padCompound.fadeThresholdCelsius ||
        estRearAfter > config.padCompound.fadeThresholdCelsius;
    final isOvershoot = actualDistance > corner.availableBrakingRunwayMeters;

    // Kolarz z przegrzanym hamulcem musi hamować wcześniej i ostrożniej pokonuje nawrót.
    final timeLost = isFading
        ? math.max(0.0, actualDuration - baselineDuration) * 0.65 +
            (1.0 - effectiveFade) * 1.45
        : 0.0;

    return HairpinBrakingStepResult(
      hairpinIndex: corner.index,
      frontTempBeforeCelsius: frontTempBeforeCelsius,
      frontTempAfterCelsius: estFrontAfter,
      rearTempBeforeCelsius: rearTempBeforeCelsius,
      rearTempAfterCelsius: estRearAfter,
      energyDissipatedKj: totalBrakeEnergyJ / 1000.0,
      frontEnergyKj: frontEnergyJ / 1000.0,
      rearEnergyKj: rearEnergyJ / 1000.0,
      fadeFactor: effectiveFade,
      brakeForceLossPercent: (1.0 - effectiveFade) * 100.0,
      baselineBrakingDistanceMeters: baselineDistance,
      actualBrakingDistanceMeters: actualDistance,
      brakingDistanceExtensionMeters: extensionMeters,
      brakingDurationSeconds: actualDuration,
      timeLostToFadeSeconds: timeLost,
      isFading: isFading,
      isOvershootRisk: isOvershoot,
      frontThermalZone: classifyThermalZone(
        estFrontAfter,
        fadeThresholdCelsius: config.padCompound.fadeThresholdCelsius,
      ),
      rearThermalZone: classifyThermalZone(
        estRearAfter,
        fadeThresholdCelsius: config.padCompound.fadeThresholdCelsius,
      ),
    );
  }

  /// Buduje listę serpentyn na podstawie presetu zjazdu alpejskiego.
  static List<AlpineHairpinCornerSpec> buildPresetCorners(
    AlpineDescentPreset preset,
  ) {
    final corners = <AlpineHairpinCornerSpec>[];
    final count = math.max(1, preset.hairpinCount);
    final altStep =
        (preset.startAltitudeMeters - preset.endAltitudeMeters) / count;

    for (var i = 0; i < count; i++) {
      final altitude = preset.startAltitudeMeters - i * altStep;
      corners.add(
        AlpineHairpinCornerSpec(
          index: i + 1,
          entrySpeedKmh: preset.entrySpeedKmh,
          apexSpeedKmh: preset.apexSpeedKmh,
          gradientPercent: preset.averageGradientPercent,
          straightApproachMeters: preset.averageStraightMeters,
          altitudeMeters: altitude,
          availableBrakingRunwayMeters: 62.0,
        ),
      );
    }
    return corners;
  }

  /// Symuluje pełny, wielozakrętowy zjazd alpejski z kumulacją ciepła w tarczach.
  static AlpineDescentBrakeSimulationResult simulateAlpineDescent({
    required BrakeRotorSystemConfig config,
    required List<AlpineHairpinCornerSpec> corners,
    DescentEnvironmentConditions environment =
        const DescentEnvironmentConditions(),
    double? initialRotorTempCelsius,
  }) {
    final startTemp = initialRotorTempCelsius ?? environment.ambientTempCelsius;
    if (corners.isEmpty) {
      final zone = classifyThermalZone(
        startTemp,
        fadeThresholdCelsius: config.padCompound.fadeThresholdCelsius,
      );
      return AlpineDescentBrakeSimulationResult(
        config: config,
        hairpinSteps: const [],
        peakFrontTempCelsius: startTemp,
        peakRearTempCelsius: startTemp,
        finalFrontTempCelsius: startTemp,
        finalRearTempCelsius: startTemp,
        fadeTriggeredHairpinCount: 0,
        overshootRiskHairpinCount: 0,
        maxBrakingDistanceExtensionMeters: 0.0,
        minFadeFactorObserved: 1.0,
        totalTimeLostToFadeSeconds: 0.0,
        peakThermalZone: zone,
      );
    }

    var frontTemp = startTemp;
    var rearTemp = startTemp;
    var peakFront = startTemp;
    var peakRear = startTemp;
    var fadeCount = 0;
    var overshootCount = 0;
    var maxExtension = 0.0;
    var minFade = 1.0;
    var totalTimeLost = 0.0;

    // Słabszy zjazdowiec częściej lekko przyhamowuje między serpentynami (drag braking).
    final skillRatio = (100 - config.descenderSkill.clamp(0, 100)) / 100.0;
    final dragPowerTotalW = skillRatio * 260.0;
    final frontDragW = dragPowerTotalW * config.frontBrakeBias;
    final rearDragW = dragPowerTotalW * (1.0 - config.frontBrakeBias);

    final steps = <HairpinBrakingStepResult>[];

    for (final corner in corners) {
      if (corner.straightApproachMeters > 0.0) {
        final avgCruiseKmh =
            0.5 * (corner.entrySpeedKmh + math.max(55.0, corner.entrySpeedKmh - 12.0));
        frontTemp = simulateCoolingInterval(
          startTempCelsius: frontTemp,
          intervalDistanceMeters: corner.straightApproachMeters,
          averageSpeedKmh: avgCruiseKmh,
          rotor: config.frontRotor,
          coolingTech: config.coolingTech,
          altitudeMeters: corner.altitudeMeters,
          dragBrakingHeatWatts: frontDragW,
          environment: environment,
        );
        rearTemp = simulateCoolingInterval(
          startTempCelsius: rearTemp,
          intervalDistanceMeters: corner.straightApproachMeters,
          averageSpeedKmh: avgCruiseKmh,
          rotor: config.rearRotor,
          coolingTech: config.coolingTech,
          altitudeMeters: corner.altitudeMeters,
          dragBrakingHeatWatts: rearDragW,
          environment: environment,
        );
      }

      final stepResult = simulateSingleHairpinBraking(
        corner: corner,
        config: config,
        frontTempBeforeCelsius: frontTemp,
        rearTempBeforeCelsius: rearTemp,
        environment: environment,
      );
      steps.add(stepResult);

      frontTemp = stepResult.frontTempAfterCelsius;
      rearTemp = stepResult.rearTempAfterCelsius;

      if (frontTemp > peakFront) peakFront = frontTemp;
      if (rearTemp > peakRear) peakRear = rearTemp;
      if (stepResult.isFading) fadeCount++;
      if (stepResult.isOvershootRisk) overshootCount++;
      if (stepResult.brakingDistanceExtensionMeters > maxExtension) {
        maxExtension = stepResult.brakingDistanceExtensionMeters;
      }
      if (stepResult.fadeFactor < minFade) {
        minFade = stepResult.fadeFactor;
      }
      totalTimeLost += stepResult.timeLostToFadeSeconds;
    }

    final peakOverall = math.max(peakFront, peakRear);
    return AlpineDescentBrakeSimulationResult(
      config: config,
      hairpinSteps: List<HairpinBrakingStepResult>.unmodifiable(steps),
      peakFrontTempCelsius: peakFront,
      peakRearTempCelsius: peakRear,
      finalFrontTempCelsius: frontTemp,
      finalRearTempCelsius: rearTemp,
      fadeTriggeredHairpinCount: fadeCount,
      overshootRiskHairpinCount: overshootCount,
      maxBrakingDistanceExtensionMeters: maxExtension,
      minFadeFactorObserved: minFade,
      totalTimeLostToFadeSeconds: totalTimeLost,
      peakThermalZone: classifyThermalZone(
        peakOverall,
        fadeThresholdCelsius: config.padCompound.fadeThresholdCelsius,
      ),
    );
  }

  /// Porównuje wprost zestaw tarcz 140 mm (przód i tył) vs 160 mm na tym samym zjeździe.
  static RotorSizeDescentComparison compare140mmVs160mm({
    required BrakeRotorSystemConfig baseConfig,
    required List<AlpineHairpinCornerSpec> corners,
    DescentEnvironmentConditions environment =
        const DescentEnvironmentConditions(),
  }) {
    final config140 = baseConfig.copyWith(
      frontRotor: BrakeRotorDiameter.mm140,
      rearRotor: BrakeRotorDiameter.mm140,
    );
    final config160 = baseConfig.copyWith(
      frontRotor: BrakeRotorDiameter.mm160,
      rearRotor: BrakeRotorDiameter.mm160,
    );

    final res140 = simulateAlpineDescent(
      config: config140,
      corners: corners,
      environment: environment,
    );
    final res160 = simulateAlpineDescent(
      config: config160,
      corners: corners,
      environment: environment,
    );

    return RotorSizeDescentComparison(
      result140mm: res140,
      result160mm: res160,
      peakTempDifferenceCelsius:
          res140.peakMaxTempCelsius - res160.peakMaxTempCelsius,
      maxExtensionDifferenceMeters:
          res140.maxBrakingDistanceExtensionMeters -
              res160.maxBrakingDistanceExtensionMeters,
      totalTimeSavedWith160mmSeconds:
          res140.totalTimeLostToFadeSeconds -
              res160.totalTimeLostToFadeSeconds,
      fadeHairpinsAvoidedWith160mm:
          res140.fadeTriggeredHairpinCount - res160.fadeTriggeredHairpinCount,
    );
  }
}
