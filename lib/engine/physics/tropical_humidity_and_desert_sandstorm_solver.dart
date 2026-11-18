// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/race/global_exotic_tours_expansion_model.dart';

/// Poziom zalegania pustynnego piasku na asfalcie oraz intensywności burzy piaskowej.
enum DesertSandCondition {
  cleanAsphalt(
    id: 'clean_asphalt',
    labelPl: 'Czysty asfalt',
    labelEn: 'Clean Asphalt',
    crrMultiplier: 1.00,
    sandDepthMm: 0.0,
    airborneDustMgM3: 0.05,
    visibilityMeters: 10000.0,
  ),
  lightBlownDust(
    id: 'light_blown_dust',
    labelPl: 'Lekki nawiewany pył',
    labelEn: 'Light Blown Dust',
    crrMultiplier: 1.18,
    sandDepthMm: 0.8,
    airborneDustMgM3: 1.20,
    visibilityMeters: 3500.0,
  ),
  sandDrifts(
    id: 'sand_drifts',
    labelPl: 'Łachy nawianego piasku',
    labelEn: 'Sand Drifts',
    crrMultiplier: 1.52,
    sandDepthMm: 3.5,
    airborneDustMgM3: 4.50,
    visibilityMeters: 1200.0,
  ),
  heavySandSheet(
    id: 'heavy_sand_sheet',
    labelPl: 'Gruba warstwa piasku',
    labelEn: 'Heavy Sand Sheet',
    crrMultiplier: 2.15,
    sandDepthMm: 8.5,
    airborneDustMgM3: 12.0,
    visibilityMeters: 450.0,
  ),
  activeSandstorm(
    id: 'active_sandstorm',
    labelPl: 'Aktywna burza piaskowa',
    labelEn: 'Active Sandstorm',
    crrMultiplier: 2.85,
    sandDepthMm: 14.0,
    airborneDustMgM3: 35.0,
    visibilityMeters: 140.0,
  );

  final String id;
  final String labelPl;
  final String labelEn;
  final double crrMultiplier;
  final double sandDepthMm;
  final double airborneDustMgM3;
  final double visibilityMeters;

  const DesertSandCondition({
    required this.id,
    required this.labelPl,
    required this.labelEn,
    required this.crrMultiplier,
    required this.sandDepthMm,
    required this.airborneDustMgM3,
    required this.visibilityMeters,
  });
}

/// Poziom ryzyka termiczno-oddechowego w warunkach tropikalnych lub pustynnych.
enum ExoticClimateRiskLevel {
  nominal(
    labelPl: 'Optymalne',
    labelEn: 'Nominal',
    color: AppColors.statusSuccess,
  ),
  elevated(
    labelPl: 'Podwyższone',
    labelEn: 'Elevated',
    color: AppColors.accentBlue,
  ),
  high(
    labelPl: 'Wysokie',
    labelEn: 'High',
    color: AppColors.amberWarning,
  ),
  extreme(
    labelPl: 'Ekstremalne',
    labelEn: 'Extreme',
    color: AppColors.crimsonAlert,
  );

  final String labelPl;
  final String labelEn;
  final Color color;

  const ExoticClimateRiskLevel({
    required this.labelPl,
    required this.labelEn,
    required this.color,
  });
}

/// Predefiniowane scenariusze klimatyczne dla wyścigów pozaeuropejskich UCI.
enum ExoticClimatePreset {
  langkawiTropical95(
    id: 'langkawi_95',
    tourId: ExoticTourId.tourDeLangkawi,
    climateChallenge: ExoticClimateChallenge.tropicalHeatAndMonsoonHumidity,
    titlePl: 'Langkawi Monsun 95% RH',
    titleEn: 'Langkawi Monsoon 95% RH',
    temperatureCelsius: 33.5,
    relativeHumidityPercent: 95.0,
    altitudeMeters: 45.0,
    sandCondition: DesertSandCondition.cleanAsphalt,
    isRoadWet: true,
    crosswindSpeedMs: 3.2,
  ),
  rwandaHighlandRain(
    id: 'rwanda_highland',
    tourId: ExoticTourId.tourDuRwanda,
    climateChallenge: ExoticClimateChallenge.highAltitudeAndTropicalRain,
    titlePl: 'Rwanda Wyżyna Tropikalna',
    titleEn: 'Rwanda Tropical Highland',
    temperatureCelsius: 24.5,
    relativeHumidityPercent: 88.0,
    altitudeMeters: 1550.0,
    sandCondition: DesertSandCondition.lightBlownDust,
    isRoadWet: true,
    crosswindSpeedMs: 4.0,
  ),
  omanCoastalSand(
    id: 'oman_coastal',
    tourId: ExoticTourId.tourOfOman,
    climateChallenge: ExoticClimateChallenge.desertHeatAndCoastalCrosswinds,
    titlePl: 'Oman Pustynny Wiatr',
    titleEn: 'Oman Desert Crosswind',
    temperatureCelsius: 36.5,
    relativeHumidityPercent: 38.0,
    altitudeMeters: 120.0,
    sandCondition: DesertSandCondition.sandDrifts,
    isRoadWet: false,
    crosswindSpeedMs: 9.8,
  ),
  alUlaSandstorm(
    id: 'alula_sandstorm',
    tourId: ExoticTourId.alUlaTour,
    climateChallenge: ExoticClimateChallenge.aridDesertAndSandstorms,
    titlePl: 'AlUla Burza Piaskowa',
    titleEn: 'AlUla Desert Sandstorm',
    temperatureCelsius: 42.0,
    relativeHumidityPercent: 14.0,
    altitudeMeters: 740.0,
    sandCondition: DesertSandCondition.activeSandstorm,
    isRoadWet: false,
    crosswindSpeedMs: 13.5,
  );

  final String id;
  final ExoticTourId tourId;
  final ExoticClimateChallenge climateChallenge;
  final String titlePl;
  final String titleEn;
  final double temperatureCelsius;
  final double relativeHumidityPercent;
  final double altitudeMeters;
  final DesertSandCondition sandCondition;
  final bool isRoadWet;
  final double crosswindSpeedMs;

  const ExoticClimatePreset({
    required this.id,
    required this.tourId,
    required this.climateChallenge,
    required this.titlePl,
    required this.titleEn,
    required this.temperatureCelsius,
    required this.relativeHumidityPercent,
    required this.altitudeMeters,
    required this.sandCondition,
    required this.isRoadWet,
    required this.crosswindSpeedMs,
  });
}

/// Dane wejściowe dla solvera wilgotności tropikalnej i pustynnego piasku.
class TropicalAndDesertClimateInput {
  /// Temperatura otoczenia [°C]
  final double temperatureCelsius;

  /// Wilgotność względna powietrza [0.0 – 100.0 %]
  final double relativeHumidityPercent;

  /// Wysokość n.p.m. [m]
  final double altitudeMeters;

  /// Warunki zalegania pustynnego piasku / burzy piaskowej
  final DesertSandCondition sandCondition;

  /// Czy nawierzchnia jest mokra (np. tropikalny deszcz monsunowy)
  final bool isRoadWet;

  /// Bazowy współczynnik oporów toczenia opony na czystym suchym asfalcie
  final double baseTireCrr;

  /// Szerokość opony [mm] (wpływa na zapadanie się w warstwie piasku)
  final double tireWidthMm;

  /// Czy łańcuch jest woskowany (wosk znacznie lepiej opiera się przyklejaniu piasku)
  final bool isChainWaxed;

  /// Masa całkowita kolarza i roweru [kg]
  final double totalMassKg;

  /// Współczynnik oporu aerodynamicznego CdA [m^2]
  final double cda;

  /// Docelowa moc kolarza na korbie [W]
  final double riderPowerWatts;

  /// Docelowa prędkość referencyjna do wyliczenia strat mocy [m/s] (np. 11.11 m/s = 40 km/h)
  final double referenceSpeedMs;

  /// Poziom aklimatyzacji cieplno-wilgotnościowej kolarza [0.0 – 1.0]
  final double heatAcclimatizationLevel;

  /// Prędkość wiatru bocznego [m/s]
  final double crosswindSpeedMs;

  const TropicalAndDesertClimateInput({
    this.temperatureCelsius = 33.5,
    this.relativeHumidityPercent = 95.0,
    this.altitudeMeters = 50.0,
    this.sandCondition = DesertSandCondition.cleanAsphalt,
    this.isRoadWet = false,
    this.baseTireCrr = PhysicsConstants.crrSmoothAsphalt,
    this.tireWidthMm = 28.0,
    this.isChainWaxed = true,
    this.totalMassKg = 76.0,
    this.cda = PhysicsConstants.cdaHoods,
    this.riderPowerWatts = 310.0,
    this.referenceSpeedMs = 11.111,
    this.heatAcclimatizationLevel = 0.35,
    this.crosswindSpeedMs = 3.5,
  });

  TropicalAndDesertClimateInput copyWith({
    double? temperatureCelsius,
    double? relativeHumidityPercent,
    double? altitudeMeters,
    DesertSandCondition? sandCondition,
    bool? isRoadWet,
    double? baseTireCrr,
    double? tireWidthMm,
    bool? isChainWaxed,
    double? totalMassKg,
    double? cda,
    double? riderPowerWatts,
    double? referenceSpeedMs,
    double? heatAcclimatizationLevel,
    double? crosswindSpeedMs,
  }) {
    return TropicalAndDesertClimateInput(
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      relativeHumidityPercent:
          relativeHumidityPercent ?? this.relativeHumidityPercent,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      sandCondition: sandCondition ?? this.sandCondition,
      isRoadWet: isRoadWet ?? this.isRoadWet,
      baseTireCrr: baseTireCrr ?? this.baseTireCrr,
      tireWidthMm: tireWidthMm ?? this.tireWidthMm,
      isChainWaxed: isChainWaxed ?? this.isChainWaxed,
      totalMassKg: totalMassKg ?? this.totalMassKg,
      cda: cda ?? this.cda,
      riderPowerWatts: riderPowerWatts ?? this.riderPowerWatts,
      referenceSpeedMs: referenceSpeedMs ?? this.referenceSpeedMs,
      heatAcclimatizationLevel:
          heatAcclimatizationLevel ?? this.heatAcclimatizationLevel,
      crosswindSpeedMs: crosswindSpeedMs ?? this.crosswindSpeedMs,
    );
  }
}

/// Wynik obliczeń fizycznych i fizjologicznych solvera wilgotności tropikalnej oraz piasku.
class TropicalAndDesertClimateResult {
  /// Ciśnienie pary wodnej nasyconej [hPa]
  final double saturationVaporPressureHpa;

  /// Rzeczywiste ciśnienie cząstkowe pary wodnej [hPa]
  final double actualVaporPressureHpa;

  /// Gęstość wilgotnego powietrza z poprawką na pył zawieszony [kg/m^3]
  final double effectiveAirDensityKgM3;

  /// Przybliżony indeks WBGT (Wet-Bulb Globe Temperature) [°C]
  final double wbgtCelsius;

  /// Sprawność chłodzenia przez parowanie potu [0.05 – 1.0]
  final double sweatEvaporationEfficiency;

  /// Szacowane tempo pocenia się kolarza [l/h]
  final double sweatRateLitersPerHour;

  /// Tempo narastania temperatury głębokiej ciała przy stałym wysiłku [°C/h]
  final double coreTempDriftCelsiusPerHour;

  /// Redukcja zrównoważonej mocy progowej (FTP) wskutek stresu termicznego [0.0 – 0.30]
  final double thermalPowerPenaltyFraction;

  /// Efektywna moc kolarza na korbie po uwzględnieniu kary cieplnej [W]
  final double effectiveRiderPowerWatts;

  /// Bazowy Crr opony [dimensionless]
  final double baseCrr;

  /// Efektywny współczynnik oporów toczenia Crr po piasku i wodzie
  final double effectiveCrr;

  /// Dodatkowy przyrost Crr względem suchego czystego asfaltu
  final double deltaCrr;

  /// Dodatkowa moc potrzebna na pokonanie oporów toczenia przy prędkości referencyjnej [W]
  final double extraRollingPowerWatts;

  /// Całkowita moc oporów toczenia przy prędkości referencyjnej [W]
  final double totalRollingPowerWatts;

  /// Sprawność mechaniczna napędu [0.85 – 0.99] (z uwzględnieniem zapiaszczenia)
  final double drivetrainEfficiency;

  /// Dodatkowa strata mocy w napędzie wskutek pyłu/piasku [W]
  final double sandDrivetrainLossWatts;

  /// Osiągana prędkość na płaskim przy efektywnej mocy kolarza [m/s]
  final double projectedFlatSpeedMs;

  /// Prędkość bazowa na czystym suchym asfalcie w 20°C / 50% RH [m/s]
  final double baselineFlatSpeedMs;

  /// Strata prędkości względem warunków wzorcowych [km/h]
  double get speedLossKmh =>
      math.max(0.0, (baselineFlatSpeedMs - projectedFlatSpeedMs) * 3.6);

  /// Prędkość docelowa w km/h
  double get projectedFlatSpeedKmh => projectedFlatSpeedMs * 3.6;

  /// Ogólny poziom ryzyka klimatycznego
  final ExoticClimateRiskLevel riskLevel;

  /// Zalecenie taktyczno-sprzętowe dla dyrektora sportowego
  final String tacticalRecommendationPl;

  const TropicalAndDesertClimateResult({
    required this.saturationVaporPressureHpa,
    required this.actualVaporPressureHpa,
    required this.effectiveAirDensityKgM3,
    required this.wbgtCelsius,
    required this.sweatEvaporationEfficiency,
    required this.sweatRateLitersPerHour,
    required this.coreTempDriftCelsiusPerHour,
    required this.thermalPowerPenaltyFraction,
    required this.effectiveRiderPowerWatts,
    required this.baseCrr,
    required this.effectiveCrr,
    required this.deltaCrr,
    required this.extraRollingPowerWatts,
    required this.totalRollingPowerWatts,
    required this.drivetrainEfficiency,
    required this.sandDrivetrainLossWatts,
    required this.projectedFlatSpeedMs,
    required this.baselineFlatSpeedMs,
    required this.riskLevel,
    required this.tacticalRecommendationPl,
  });
}

/// Telemetria pojedynczego segmentu etapu w warunkach tropikalnych lub pustynnych.
class ClimateSegmentTelemetry {
  final int segmentIndex;
  final double distanceKm;
  final double cumulativeCoreTempC;
  final double cumulativeDehydrationPercent;
  final double effectiveCrr;
  final double averageSpeedKmh;
  final double timeLostSeconds;
  final ExoticClimateRiskLevel riskLevel;

  const ClimateSegmentTelemetry({
    required this.segmentIndex,
    required this.distanceKm,
    required this.cumulativeCoreTempC,
    required this.cumulativeDehydrationPercent,
    required this.effectiveCrr,
    required this.averageSpeedKmh,
    required this.timeLostSeconds,
    required this.riskLevel,
  });
}

/// Porównanie konfiguracji opon i smarowania łańcucha dla danych warunków klimatycznych.
class EquipmentClimateComparison {
  final double tireWidthMm;
  final bool isChainWaxed;
  final double effectiveCrr;
  final double drivetrainEfficiency;
  final double totalPowerAtRefSpeedWatts;
  final double projectedSpeedKmh;
  final double deltaSecondsOver40Km;

  const EquipmentClimateComparison({
    required this.tireWidthMm,
    required this.isChainWaxed,
    required this.effectiveCrr,
    required this.drivetrainEfficiency,
    required this.totalPowerAtRefSpeedWatts,
    required this.projectedSpeedKmh,
    required this.deltaSecondsOver40Km,
  });
}

/// Solver fizyki i termoregulacji dla skrajnej wilgotności tropikalnej (np. 95% RH)
/// oraz pustynnego piasku i burz piaskowych podnoszących współczynnik Crr.
class TropicalHumidityAndDesertSandstormSolver {
  TropicalHumidityAndDesertSandstormSolver._();

  static const double _gasConstantDryAir = 287.058; // J/(kg·K)
  static const double _gasConstantWaterVapor = 461.495; // J/(kg·K)
  static const double _seaLevelPressureHpa = 1013.25;

  /// Oblicza ciśnienie pary nasyconej e_s(T) w hPa wg równania Magnusa-Tetensa.
  static double computeSaturationVaporPressureHpa(double temperatureCelsius) {
    final safeT = temperatureCelsius.clamp(-30.0, 60.0);
    return 6.1078 * math.exp((17.27 * safeT) / (safeT + 237.3));
  }

  /// Oblicza gęstość wilgotnego powietrza [kg/m^3] z poprawką na wysokość i pył pustynny.
  static double computeMoistAndDustyAirDensity({
    required double temperatureCelsius,
    required double relativeHumidityPercent,
    required double altitudeMeters,
    double airborneDustMgM3 = 0.0,
  }) {
    final safeTempC = temperatureCelsius.clamp(-25.0, 58.0);
    final tempKelvin = safeTempC + 273.15;
    final rh = (relativeHumidityPercent / 100.0).clamp(0.0, 1.0);

    // Barometryczne ciśnienie atmosferyczne na wysokości h [hPa]
    final safeAlt = math.max(0.0, altitudeMeters);
    final totalPressureHpa = _seaLevelPressureHpa *
        math.pow(1.0 - (0.0065 * safeAlt) / 288.15, 5.25588);

    final eSatHpa = computeSaturationVaporPressureHpa(safeTempC);
    final vaporPressureHpa = (rh * eSatHpa).clamp(0.0, totalPressureHpa * 0.5);
    final dryPressureHpa = math.max(100.0, totalPressureHpa - vaporPressureHpa);

    // Przeliczenie hPa -> Pa (* 100)
    final rhoDry = (dryPressureHpa * 100.0) / (_gasConstantDryAir * tempKelvin);
    final rhoVapor =
        (vaporPressureHpa * 100.0) / (_gasConstantWaterVapor * tempKelvin);

    // Pył pustynny (mg/m^3 -> kg/m^3 = * 1e-6) nieznacznie zwiększa gęstość ośrodka
    final dustKgM3 = math.max(0.0, airborneDustMgM3) * 1e-6;
    return math.max(0.5, rhoDry + rhoVapor + dustKgM3);
  }

  /// Wyznacza przybliżony wskaźnik WBGT [°C] (Stull wet-bulb + korekta nasłonecznienia).
  static double computeWbgtCelsius({
    required double temperatureCelsius,
    required double relativeHumidityPercent,
  }) {
    final t = temperatureCelsius.clamp(0.0, 55.0);
    final rh = relativeHumidityPercent.clamp(5.0, 100.0);

    // Formuła Stulla dla temperatury termometru wilgotnego T_w
    final wetBulb = t * math.atan(0.151977 * math.sqrt(rh + 8.313659)) +
        math.atan(t + rh) -
        math.atan(rh - 1.676331) +
        0.00391838 * math.pow(rh, 1.5) * math.atan(0.023101 * rh) -
        4.686035;

    // Przybliżenie temperatury czarnej kuli T_g dla bezchmurnej lub tropikalnej trasy
    final solarGain = rh > 80.0 ? 4.5 : 8.0;
    final globeTemp = t + solarGain;
    return 0.7 * wetBulb + 0.2 * globeTemp + 0.1 * t;
  }

  /// Oblicza sprawność odparowywania potu (spada drastycznie przy wilgotności 95% RH).
  static double computeSweatEvaporationEfficiency({
    required double temperatureCelsius,
    required double relativeHumidityPercent,
    required double airflowSpeedMs,
  }) {
    final rh = (relativeHumidityPercent / 100.0).clamp(0.05, 1.0);
    final eSatAmbient = computeSaturationVaporPressureHpa(temperatureCelsius);
    final eAmbient = rh * eSatAmbient;

    // Skóra ma ok. 35.5°C -> ciśnienie nasycenia ~57.8 hPa
    const double skinSaturationHpa = 57.8;
    final vaporGradient = math.max(2.0, skinSaturationHpa - eAmbient);

    // Przewiew powietrza poprawia konwekcję i usuwanie warstwy granicznej pary
    final windFactor = (airflowSpeedMs / 10.0).clamp(0.45, 1.25);

    // W warunkach 33.5°C i 95% RH eAmbient ~ 49.1 hPa -> gradient ~ 8.7 hPa (bardzo niski)
    final rawEfficiency = (vaporGradient / 38.0) * windFactor;
    return rawEfficiency.clamp(0.12, 1.0);
  }

  /// Oblicza efektywny współczynnik oporów toczenia Crr z uwzględnieniem piasku,
  /// szerokości opony oraz mokrego filmu wodnego.
  static double computeEffectiveCrr({
    required double baseTireCrr,
    required DesertSandCondition sandCondition,
    required double tireWidthMm,
    required bool isRoadWet,
  }) {
    final safeBase = baseTireCrr.clamp(0.0020, 0.0300);
    final safeWidth = tireWidthMm.clamp(22.0, 50.0);

    // Szersze opony (np. 30-34 mm) ograniczają zapadanie się w luźnym piasku
    final sandPenaltyRatio = math.max(0.0, sandCondition.crrMultiplier - 1.0);
    final widthMitigation = ((safeWidth - 25.0) / 15.0).clamp(0.0, 1.0) * 0.22;
    final mitigatedSandMultiplier =
        1.0 + sandPenaltyRatio * (1.0 - widthMitigation);

    // Mokra nawierzchnia w tropikalnym monsunie podnosi Crr o ~12% (film wodny)
    final wetMultiplier = isRoadWet ? 1.12 : 1.0;

    return safeBase * mitigatedSandMultiplier * wetMultiplier;
  }

  /// Oblicza sprawność napędu po uwzględnieniu przyklejania się piasku do smaru.
  static double computeDrivetrainEfficiency({
    required DesertSandCondition sandCondition,
    required bool isChainWaxed,
    required bool isRoadWet,
  }) {
    final baseLoss = isChainWaxed
        ? PhysicsConstants.drivetrainLossWaxed
        : PhysicsConstants.drivetrainLossStandard;

    // Piasek w połączeniu z mokrym smarem tworzy pastę ścierną (do +4.5% strat),
    // podczas gdy suchy wosk minimalizuje adhezję ziaren krzemu.
    final sandFactor = (sandCondition.sandDepthMm / 14.0).clamp(0.0, 1.0);
    final gritLoss = isChainWaxed
        ? sandFactor * 0.014
        : sandFactor * (isRoadWet ? 0.048 : 0.036);

    return (1.0 - baseLoss - gritLoss).clamp(0.85, 0.99);
  }

  /// Rozwiązuje równanie równowagi mocy P = v * (F_roll + F_aero) dla płaskiego odcinka.
  static double solveFlatSpeedMs({
    required double wheelPowerWatts,
    required double totalMassKg,
    required double effectiveCrr,
    required double airDensityKgM3,
    required double cda,
  }) {
    final safePower = math.max(20.0, wheelPowerWatts);
    final rollingForce =
        totalMassKg * PhysicsConstants.gravity * effectiveCrr;
    final aeroK = 0.5 * airDensityKgM3 * cda;

    // Metoda bisekcji na przedziale [0.5, 28.0] m/s (stabilna i dokładna)
    double low = 0.5;
    double high = 28.0;
    for (int i = 0; i < 32; i++) {
      final mid = 0.5 * (low + high);
      final reqPower = mid * (rollingForce + aeroK * mid * mid);
      if (reqPower < safePower) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return 0.5 * (low + high);
  }

  /// Główna funkcja solvera analizująca wpływ wilgotności tropikalnej i pustynnego piasku.
  static TropicalAndDesertClimateResult solve(
    TropicalAndDesertClimateInput input,
  ) {
    final eSat = computeSaturationVaporPressureHpa(input.temperatureCelsius);
    final rhFrac = (input.relativeHumidityPercent / 100.0).clamp(0.0, 1.0);
    final eActual = rhFrac * eSat;

    final airDensity = computeMoistAndDustyAirDensity(
      temperatureCelsius: input.temperatureCelsius,
      relativeHumidityPercent: input.relativeHumidityPercent,
      altitudeMeters: input.altitudeMeters,
      airborneDustMgM3: input.sandCondition.airborneDustMgM3,
    );

    final wbgt = computeWbgtCelsius(
      temperatureCelsius: input.temperatureCelsius,
      relativeHumidityPercent: input.relativeHumidityPercent,
    );

    final evapEff = computeSweatEvaporationEfficiency(
      temperatureCelsius: input.temperatureCelsius,
      relativeHumidityPercent: input.relativeHumidityPercent,
      airflowSpeedMs: input.referenceSpeedMs,
    );

    // Tempo pocenia rośnie z temperaturą, mocą oraz nieefektywnym parowaniem przy 95% RH
    final metabolicHeatFactor = (input.riderPowerWatts / 300.0).clamp(0.6, 1.6);
    final tempFactor =
        ((input.temperatureCelsius - 18.0) / 22.0).clamp(0.2, 1.4);
    final humiditySplashFactor = 1.0 + (1.0 - evapEff) * 0.45;
    final sweatRate = (0.75 + 1.15 * tempFactor * metabolicHeatFactor) *
        humiditySplashFactor;

    // Wzrost temperatury głębokiej (aklimatyzacja redukuje dryf termiczny o max 38%)
    final acclim = input.heatAcclimatizationLevel.clamp(0.0, 1.0);
    final rawDrift = math.max(
      0.0,
      ((wbgt - 23.0) * 0.14 + (1.0 - evapEff) * 0.95) * metabolicHeatFactor,
    );
    final coreDrift = rawDrift * (1.0 - acclim * 0.38);

    // Kara mocy wskutek stresu cieplnego (powyżej WBGT 26°C)
    final wbgtExcess = math.max(0.0, wbgt - 25.5);
    final dustBreathPenalty =
        (input.sandCondition.airborneDustMgM3 / 35.0).clamp(0.0, 1.0) * 0.025;
    final rawThermalPenalty =
        (wbgtExcess * 0.011 + (1.0 - evapEff) * 0.045) * (1.0 - acclim * 0.42);
    final totalPowerPenalty =
        (rawThermalPenalty + dustBreathPenalty).clamp(0.0, 0.25);

    final effectivePower = input.riderPowerWatts * (1.0 - totalPowerPenalty);

    final effectiveCrr = computeEffectiveCrr(
      baseTireCrr: input.baseTireCrr,
      sandCondition: input.sandCondition,
      tireWidthMm: input.tireWidthMm,
      isRoadWet: input.isRoadWet,
    );
    final deltaCrr = math.max(0.0, effectiveCrr - input.baseTireCrr);

    final normalForce = input.totalMassKg * PhysicsConstants.gravity;
    final baseRollingWatts =
        normalForce * input.baseTireCrr * input.referenceSpeedMs;
    final totalRollingWatts =
        normalForce * effectiveCrr * input.referenceSpeedMs;
    final extraRollingWatts = math.max(0.0, totalRollingWatts - baseRollingWatts);

    final drivetrainEff = computeDrivetrainEfficiency(
      sandCondition: input.sandCondition,
      isChainWaxed: input.isChainWaxed,
      isRoadWet: input.isRoadWet,
    );
    final cleanEff = input.isChainWaxed
        ? (1.0 - PhysicsConstants.drivetrainLossWaxed)
        : (1.0 - PhysicsConstants.drivetrainLossStandard);
    final gritLossWatts =
        math.max(0.0, (cleanEff - drivetrainEff) * effectivePower);

    final wheelPower = effectivePower * drivetrainEff;
    final projectedSpeedMs = solveFlatSpeedMs(
      wheelPowerWatts: wheelPower,
      totalMassKg: input.totalMassKg,
      effectiveCrr: effectiveCrr,
      airDensityKgM3: airDensity,
      cda: input.cda,
    );

    // Warunki wzorcowe: 20°C, 50% RH, czysty suchy asfalt
    final baselineDensity = computeMoistAndDustyAirDensity(
      temperatureCelsius: 20.0,
      relativeHumidityPercent: 50.0,
      altitudeMeters: input.altitudeMeters,
    );
    final baselineSpeedMs = solveFlatSpeedMs(
      wheelPowerWatts: input.riderPowerWatts * cleanEff,
      totalMassKg: input.totalMassKg,
      effectiveCrr: input.baseTireCrr,
      airDensityKgM3: baselineDensity,
      cda: input.cda,
    );

    final risk = _classifyRisk(
      wbgt: wbgt,
      evapEff: evapEff,
      sandCondition: input.sandCondition,
      deltaCrr: deltaCrr,
    );

    final recommendation = _buildRecommendation(
      input: input,
      wbgt: wbgt,
      evapEff: evapEff,
      deltaCrr: deltaCrr,
      risk: risk,
    );

    return TropicalAndDesertClimateResult(
      saturationVaporPressureHpa: eSat,
      actualVaporPressureHpa: eActual,
      effectiveAirDensityKgM3: airDensity,
      wbgtCelsius: wbgt,
      sweatEvaporationEfficiency: evapEff,
      sweatRateLitersPerHour: sweatRate,
      coreTempDriftCelsiusPerHour: coreDrift,
      thermalPowerPenaltyFraction: totalPowerPenalty,
      effectiveRiderPowerWatts: effectivePower,
      baseCrr: input.baseTireCrr,
      effectiveCrr: effectiveCrr,
      deltaCrr: deltaCrr,
      extraRollingPowerWatts: extraRollingWatts,
      totalRollingPowerWatts: totalRollingWatts,
      drivetrainEfficiency: drivetrainEff,
      sandDrivetrainLossWatts: gritLossWatts,
      projectedFlatSpeedMs: projectedSpeedMs,
      baselineFlatSpeedMs: baselineSpeedMs,
      riskLevel: risk,
      tacticalRecommendationPl: recommendation,
    );
  }

  /// Symuluje progresję etapu podzielonego na równe segmenty dystansu.
  static List<ClimateSegmentTelemetry> simulateStageProgression({
    required TropicalAndDesertClimateInput baseInput,
    required double totalDistanceKm,
    int segmentCount = 6,
    double fluidIntakeLitersPerHour = 0.85,
  }) {
    final safeSegments = segmentCount.clamp(2, 24);
    final segmentKm = totalDistanceKm.clamp(10.0, 260.0) / safeSegments;
    final results = <ClimateSegmentTelemetry>[];

    double coreTemp = 37.1;
    double dehydrationKg = 0.0;

    for (int i = 0; i < safeSegments; i++) {
      final solved = solve(baseInput);
      final segmentHours =
          (segmentKm / math.max(12.0, solved.projectedFlatSpeedKmh));
      final baselineHours =
          (segmentKm / math.max(12.0, solved.baselineFlatSpeedMs * 3.6));

      coreTemp = (coreTemp + solved.coreTempDriftCelsiusPerHour * segmentHours)
          .clamp(36.8, 40.6);

      final netFluidLossLiters = math.max(
        0.0,
        (solved.sweatRateLitersPerHour - fluidIntakeLitersPerHour) *
            segmentHours,
      );
      dehydrationKg += netFluidLossLiters;
      final dehydrationPct =
          ((dehydrationKg / math.max(45.0, baseInput.totalMassKg - 8.0)) *
                  100.0)
              .clamp(0.0, 8.0);

      final timeLostSec = math.max(0.0, (segmentHours - baselineHours) * 3600.0);

      results.add(
        ClimateSegmentTelemetry(
          segmentIndex: i + 1,
          distanceKm: segmentKm * (i + 1),
          cumulativeCoreTempC: coreTemp,
          cumulativeDehydrationPercent: dehydrationPct,
          effectiveCrr: solved.effectiveCrr,
          averageSpeedKmh: solved.projectedFlatSpeedKmh,
          timeLostSeconds: timeLostSec,
          riskLevel: solved.riskLevel,
        ),
      );
    }
    return results;
  }

  /// Porównuje warianty szerokości opon (25/28/32 mm) i smarowania (wosk vs olej)
  /// na dystansie testowym 40 km w danych warunkach klimatycznych.
  static List<EquipmentClimateComparison> compareTireAndLubeSetups(
    TropicalAndDesertClimateInput baseInput,
  ) {
    const widths = [25.0, 28.0, 32.0];
    const waxModes = [false, true];
    final comparisons = <EquipmentClimateComparison>[];

    double? fastestTimeSec;
    final rawEntries = <({
      double width,
      bool waxed,
      TropicalAndDesertClimateResult result,
      double time40KmSec,
    })>[];

    for (final w in widths) {
      for (final waxed in waxModes) {
        final variant = baseInput.copyWith(
          tireWidthMm: w,
          isChainWaxed: waxed,
        );
        final res = solve(variant);
        final timeSec = 40000.0 / math.max(3.0, res.projectedFlatSpeedMs);
        if (fastestTimeSec == null || timeSec < fastestTimeSec) {
          fastestTimeSec = timeSec;
        }
        rawEntries.add((
          width: w,
          waxed: waxed,
          result: res,
          time40KmSec: timeSec,
        ));
      }
    }

    final bestTime = fastestTimeSec ?? 0.0;
    for (final item in rawEntries) {
      final res = item.result;
      final totalPowerRef = res.totalRollingPowerWatts +
          0.5 *
              res.effectiveAirDensityKgM3 *
              baseInput.cda *
              math.pow(baseInput.referenceSpeedMs, 3);
      comparisons.add(
        EquipmentClimateComparison(
          tireWidthMm: item.width,
          isChainWaxed: item.waxed,
          effectiveCrr: res.effectiveCrr,
          drivetrainEfficiency: res.drivetrainEfficiency,
          totalPowerAtRefSpeedWatts: totalPowerRef,
          projectedSpeedKmh: res.projectedFlatSpeedKmh,
          deltaSecondsOver40Km: math.max(0.0, item.time40KmSec - bestTime),
        ),
      );
    }
    return comparisons;
  }

  static ExoticClimateRiskLevel _classifyRisk({
    required double wbgt,
    required double evapEff,
    required DesertSandCondition sandCondition,
    required double deltaCrr,
  }) {
    if (wbgt >= 31.5 ||
        evapEff <= 0.24 ||
        sandCondition == DesertSandCondition.activeSandstorm ||
        deltaCrr >= 0.0055) {
      return ExoticClimateRiskLevel.extreme;
    }
    if (wbgt >= 27.5 ||
        evapEff <= 0.42 ||
        sandCondition == DesertSandCondition.heavySandSheet ||
        deltaCrr >= 0.0025) {
      return ExoticClimateRiskLevel.high;
    }
    if (wbgt >= 23.0 ||
        sandCondition == DesertSandCondition.sandDrifts ||
        deltaCrr >= 0.0010) {
      return ExoticClimateRiskLevel.elevated;
    }
    return ExoticClimateRiskLevel.nominal;
  }

  static String _buildRecommendation({
    required TropicalAndDesertClimateInput input,
    required double wbgt,
    required double evapEff,
    required double deltaCrr,
    required ExoticClimateRiskLevel risk,
  }) {
    if (input.sandCondition == DesertSandCondition.activeSandstorm ||
        input.sandCondition == DesertSandCondition.heavySandSheet) {
      return 'Piasek zwiększa Crr o +${deltaCrr.toStringAsFixed(4)}. '
          'Załóż opony 30–32 mm, woskowany łańcuch i formuj wachlarz na wietrze.';
    }
    if (input.relativeHumidityPercent >= 88.0 && wbgt >= 28.0) {
      return 'Wilgotność ${input.relativeHumidityPercent.toStringAsFixed(0)}% '
          'blokuje parowanie potu (${(evapEff * 100).toStringAsFixed(0)}%). '
          'Wymagane Ice Socks, elektrolity 1.2 l/h i wczesne chłodzenie.';
    }
    if (risk == ExoticClimateRiskLevel.high ||
        risk == ExoticClimateRiskLevel.extreme) {
      return 'Wysokie obciążenie termiczno-nawierzchniowe. Ogranicz zrywy '
          'powyżej progu i kontroluj ciśnienie opon.';
    }
    return 'Warunki stabilne — utrzymuj standardowe nawodnienie i tempo grupowe.';
  }
}

/// Interaktywny panel telemetryczny solvera wilgotności tropikalnej 95% i pustynnego piasku.
class TropicalHumidityAndDesertSandstormPanel extends StatefulWidget {
  final ExoticClimatePreset initialPreset;
  final ValueChanged<TropicalAndDesertClimateResult>? onResultChanged;

  const TropicalHumidityAndDesertSandstormPanel({
    super.key,
    this.initialPreset = ExoticClimatePreset.langkawiTropical95,
    this.onResultChanged,
  });

  @override
  State<TropicalHumidityAndDesertSandstormPanel> createState() =>
      _TropicalHumidityAndDesertSandstormPanelState();
}

class _TropicalHumidityAndDesertSandstormPanelState
    extends State<TropicalHumidityAndDesertSandstormPanel> {
  late ExoticClimatePreset _selectedPreset;
  late TropicalAndDesertClimateInput _input;
  late TropicalAndDesertClimateResult _result;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    _input = _inputFromPreset(_selectedPreset);
    _result = TropicalHumidityAndDesertSandstormSolver.solve(_input);
  }

  TropicalAndDesertClimateInput _inputFromPreset(ExoticClimatePreset preset) {
    return TropicalAndDesertClimateInput(
      temperatureCelsius: preset.temperatureCelsius,
      relativeHumidityPercent: preset.relativeHumidityPercent,
      altitudeMeters: preset.altitudeMeters,
      sandCondition: preset.sandCondition,
      isRoadWet: preset.isRoadWet,
      crosswindSpeedMs: preset.crosswindSpeedMs,
      tireWidthMm: preset.sandCondition == DesertSandCondition.activeSandstorm
          ? 30.0
          : 28.0,
      isChainWaxed: true,
    );
  }

  void _applyPreset(ExoticClimatePreset preset) {
    setState(() {
      _selectedPreset = preset;
      _input = _inputFromPreset(preset);
      _result = TropicalHumidityAndDesertSandstormSolver.solve(_input);
    });
    widget.onResultChanged?.call(_result);
  }

  void _updateInput(TropicalAndDesertClimateInput next) {
    setState(() {
      _input = next;
      _result = TropicalHumidityAndDesertSandstormSolver.solve(_input);
    });
    widget.onResultChanged?.call(_result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          final isMedium = constraints.maxWidth >= 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildPresetSelector(),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildControlsCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: _buildTelemetryGrid(columns: 2)),
                  ],
                )
              else ...[
                _buildControlsCard(),
                const SizedBox(height: 14),
                _buildTelemetryGrid(columns: isMedium ? 2 : 1),
              ],
              const SizedBox(height: 14),
              _buildRecommendationBanner(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Icon(
            Icons.wb_sunny_outlined,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solver Wilgotności Tropikalnej i Piasku Pustynnego',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Parowanie potu 95% RH • Gęstość wilgotna ρ • Przyrost Crr na piasku',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _result.riskLevel.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _result.riskLevel.color.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            _result.riskLevel.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _result.riskLevel.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExoticClimatePreset.values.map((preset) {
        final selected = preset == _selectedPreset;
        return _InteractiveChipButton(
          label: preset.titlePl,
          selected: selected,
          onTap: () => _applyPreset(preset),
        );
      }).toList(),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSliderRow(
            label: 'Wilgotność względna (RH)',
            valueText: '${_input.relativeHumidityPercent.toStringAsFixed(0)}%',
            value: _input.relativeHumidityPercent,
            min: 10,
            max: 100,
            divisions: 90,
            accent: AppColors.cyanAccent,
            onChanged: (v) =>
                _updateInput(_input.copyWith(relativeHumidityPercent: v)),
          ),
          _buildSliderRow(
            label: 'Temperatura powietrza',
            valueText: '${_input.temperatureCelsius.toStringAsFixed(1)} °C',
            value: _input.temperatureCelsius,
            min: 15,
            max: 48,
            divisions: 66,
            accent: AppColors.amberWarning,
            onChanged: (v) =>
                _updateInput(_input.copyWith(temperatureCelsius: v)),
          ),
          _buildSliderRow(
            label: 'Szerokość opony',
            valueText: '${_input.tireWidthMm.toStringAsFixed(0)} mm',
            value: _input.tireWidthMm,
            min: 23,
            max: 36,
            divisions: 13,
            accent: AppColors.goldAccent,
            onChanged: (v) => _updateInput(_input.copyWith(tireWidthMm: v)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Warstwa pustynnego piasku',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: DesertSandCondition.values.map((cond) {
              return _InteractiveChipButton(
                label: cond.labelPl,
                selected: _input.sandCondition == cond,
                onTap: () => _updateInput(_input.copyWith(sandCondition: cond)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InteractiveTogglePill(
                label: 'Woskowany łańcuch',
                active: _input.isChainWaxed,
                onTap: () => _updateInput(
                  _input.copyWith(isChainWaxed: !_input.isChainWaxed),
                ),
              ),
              _InteractiveTogglePill(
                label: 'Mokra nawierzchnia',
                active: _input.isRoadWet,
                onTap: () => _updateInput(
                  _input.copyWith(isRoadWet: !_input.isRoadWet),
                ),
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
    required int divisions,
    required Color accent,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.16),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryGrid({required int columns}) {
    final cards = [
      _TelemetryMetricCard(
        title: 'Efektywne Crr',
        value: _result.effectiveCrr.toStringAsFixed(4),
        subtitle:
            '+${_result.deltaCrr.toStringAsFixed(4)} (+${_result.extraRollingPowerWatts.toStringAsFixed(1)} W @ 40 km/h)',
        accent: _result.deltaCrr > 0.0025
            ? AppColors.crimsonAlert
            : AppColors.goldAccent,
      ),
      _TelemetryMetricCard(
        title: 'Parowanie potu / WBGT',
        value: '${(_result.sweatEvaporationEfficiency * 100).toStringAsFixed(0)}%',
        subtitle:
            'WBGT ${_result.wbgtCelsius.toStringAsFixed(1)} °C • ${_result.sweatRateLitersPerHour.toStringAsFixed(2)} l/h',
        accent: _result.sweatEvaporationEfficiency < 0.35
            ? AppColors.crimsonAlert
            : AppColors.cyanAccent,
      ),
      _TelemetryMetricCard(
        title: 'Moc efektywna / Napęd',
        value: '${_result.effectiveRiderPowerWatts.toStringAsFixed(0)} W',
        subtitle:
            'Sprawność ${(_result.drivetrainEfficiency * 100).toStringAsFixed(1)}% (strata piasku ${_result.sandDrivetrainLossWatts.toStringAsFixed(1)} W)',
        accent: AppColors.accentBlue,
      ),
      _TelemetryMetricCard(
        title: 'Prędkość na płaskim',
        value: '${_result.projectedFlatSpeedKmh.toStringAsFixed(1)} km/h',
        subtitle:
            'Strata -${_result.speedLossKmh.toStringAsFixed(1)} km/h • ρ=${_result.effectiveAirDensityKgM3.toStringAsFixed(3)} kg/m³',
        accent: AppColors.statusSuccess,
      ),
    ];

    if (columns == 1) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 10),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _result.riskLevel.color.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 18,
            color: _result.riskLevel.color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _result.tacticalRecommendationPl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _TelemetryMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
              color: accent,
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

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _InteractiveChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: 0.28)
            : _pressed
                ? AppColors.cardBorder
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    final borderColor = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.selected
            ? AppColors.goldAccent
            : _focused
                ? AppColors.accentBlue
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: disabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
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

class _InteractiveTogglePill extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _InteractiveTogglePill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_InteractiveTogglePill> createState() => _InteractiveTogglePillState();
}

class _InteractiveTogglePillState extends State<_InteractiveTogglePill> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final accent =
        widget.active ? AppColors.statusSuccess : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.surface.withValues(alpha: 0.4)
                : _pressed
                    ? AppColors.cardBorder
                    : widget.active
                        ? AppColors.statusSuccess.withValues(alpha: 0.14)
                        : _hovered
                            ? AppColors.surface
                            : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.accentBlue
                  : widget.active
                      ? AppColors.statusSuccess
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.active ? Icons.check_circle : Icons.circle_outlined,
                size: 15,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
