// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

/// Strefa termiczna temperatury głębokiej ciała kolarza.
enum CoreThermalZone {
  /// Normotermia spoczynkowa i umiarkowany wysiłek (37.0 °C - 38.0 °C).
  normothermia,

  /// Podwyższona temperatura wysiłkowa — optymalna dla skurczu mięśni (38.0 °C - 38.8 °C).
  elevatedExercise,

  /// Wysokie obciążenie cieplne zbliżające się do progu krytycznego (38.8 °C - 39.2 °C).
  highThermalStrain,

  /// Hipertermia powyżej 39.2 °C — termiczny spadek mocy maksymalnej i dryf tętna +12 BPM.
  hyperthermicCollapse,
}

/// Parametry wejściowe pojedynczego kroku modelu termoregulacji.
class ThermoregulationStepInput {
  /// Generowana moc mechaniczna na pedałach [W].
  final double powerWatts;

  /// Prędkość względna przepływu powietrza (prędkość jazdy + składowa czołowa wiatru) [m/s].
  final double airSpeedMps;

  /// Temperatura otoczenia [°C].
  final double ambientTemperatureCelsius;

  /// Względna wilgotność powietrza [0.0 - 1.0].
  final double relativeHumidity;

  /// Czas trwania kroku symulacji [s].
  final double deltaTimeSeconds;

  /// Masa ciała kolarza [kg] wpływająca na pojemność cieplną organizmu.
  final double riderMassKg;

  /// Powierzchnia ciała (BSA) [m^2]. Domyślnie ~1.85 m^2 dla zawodowego kolarza.
  final double bodySurfaceAreaM2;

  /// Sprawność brutto układu mięśniowego (eta), domyślnie 0.23 (23%).
  final double grossEfficiency;

  /// Poziom nawodnienia organizmu [0.0 - 1.0] (1.0 = pełne nawodnienie).
  final double hydrationLevel;

  /// Poziom aklimatyzacji cieplnej [0.0 - 1.0] (zwiększa tempo pocenia i efektywność parowania).
  final double heatAcclimatization;

  /// Dodatkowe chłodzenie zewnętrzne (np. skarpety lodowe, polewanie wodą) [W].
  final double externalCoolingWatts;

  /// Czy kolarz ma założoną nieprzewiewną pelerynę przeciwdeszczową (ogranicza parowanie).
  final bool wearingRainJacket;

  const ThermoregulationStepInput({
    required this.powerWatts,
    required this.airSpeedMps,
    required this.ambientTemperatureCelsius,
    this.relativeHumidity = 0.50,
    required this.deltaTimeSeconds,
    this.riderMassKg = 68.0,
    this.bodySurfaceAreaM2 = 1.85,
    this.grossEfficiency =
        CoreBodyTemperatureThermoregulation.defaultGrossEfficiency,
    this.hydrationLevel = 1.0,
    this.heatAcclimatization = 0.0,
    this.externalCoolingWatts = 0.0,
    this.wearingRainJacket = false,
  });
}

/// Stan termiczny kolarza utrzymywany pomiędzy krokami symulacji.
class ThermoregulationState {
  /// Temperatura głęboka ciała [°C] w zakresie [37.0, 40.5].
  final double coreBodyTemperatureCelsius;

  /// Temperatura skóry [°C].
  final double skinTemperatureCelsius;

  /// Skumulowana utrata płynów z potem [ml].
  final double cumulativeSweatLossMl;

  const ThermoregulationState({
    this.coreBodyTemperatureCelsius =
        CoreBodyTemperatureThermoregulation.minCoreTempCelsius,
    this.skinTemperatureCelsius = 34.0,
    this.cumulativeSweatLossMl = 0.0,
  });

  /// Aktualna strefa termiczna.
  CoreThermalZone get thermalZone =>
      CoreBodyTemperatureThermoregulation.classifyZone(
        coreBodyTemperatureCelsius,
      );

  /// Czy przekroczono próg hipertermii (> 39.2 °C).
  bool get isAboveCriticalThreshold =>
      coreBodyTemperatureCelsius >
      CoreBodyTemperatureThermoregulation.criticalPowerDropThresholdCelsius;

  ThermoregulationState copyWith({
    double? coreBodyTemperatureCelsius,
    double? skinTemperatureCelsius,
    double? cumulativeSweatLossMl,
  }) {
    return ThermoregulationState(
      coreBodyTemperatureCelsius:
          coreBodyTemperatureCelsius ?? this.coreBodyTemperatureCelsius,
      skinTemperatureCelsius:
          skinTemperatureCelsius ?? this.skinTemperatureCelsius,
      cumulativeSweatLossMl:
          cumulativeSweatLossMl ?? this.cumulativeSweatLossMl,
    );
  }
}

/// Wynik pojedynczego kroku obliczeń termoregulacji i wpływu na wydolność.
class ThermoregulationStepResult {
  /// Zaktualizowany stan termiczny kolarza.
  final ThermoregulationState updatedState;

  /// Produkcja ciepła metabolicznego Q_prod = P * (1 - eta) / eta [W].
  final double metabolicHeatProductionWatts;

  /// Chłodzenie konwekcyjne wiatrem Q_conv ~ v^0.6 [W] (dodatnie = oddawanie ciepła).
  final double convectiveCoolingWatts;

  /// Chłodzenie przez parowanie potu Q_evap [W].
  final double evaporativeCoolingWatts;

  /// Bilans cieplny netto dQ/dt = Q_prod - Q_conv - Q_evap - externalCooling [W].
  final double netHeatStorageWatts;

  /// Zmiana temperatury głębokiej w tym kroku [°C].
  final double deltaCoreTempCelsius;

  /// Utrata potu w tym kroku [ml].
  final double sweatLossStepMl;

  /// Mnożnik mocy maksymalnej (1.00 dla T <= 39.2 °C, spadek powyżej 39.2 °C).
  final double maxPowerMultiplier;

  /// Dryf tętna wynikający z przegrzania (+12.0 BPM powyżej 39.2 °C).
  final double heartRateDriftBpm;

  /// Strefa termiczna po kroku symulacji.
  final CoreThermalZone thermalZone;

  const ThermoregulationStepResult({
    required this.updatedState,
    required this.metabolicHeatProductionWatts,
    required this.convectiveCoolingWatts,
    required this.evaporativeCoolingWatts,
    required this.netHeatStorageWatts,
    required this.deltaCoreTempCelsius,
    required this.sweatLossStepMl,
    required this.maxPowerMultiplier,
    required this.heartRateDriftBpm,
    required this.thermalZone,
  });

  /// Procentowy spadek mocy maksymalnej (0.0 dla T <= 39.2 °C).
  double get maxPowerPenaltyPercent => (1.0 - maxPowerMultiplier) * 100.0;
}

/// Naukowy model termoregulacji i temperatury głębokiej ciała kolarza (37.0 °C – 40.5 °C).
///
/// Równanie bilansu cieplnego:
/// - Produkcja ciepła metabolicznego: `Q_prod = P * (1 - eta) / eta` (eta ≈ 0.23).
/// - Chłodzenie konwekcyjne wiatrem: `Q_conv = h_c * BSA * (T_skin - T_amb)`,
///   gdzie współczynnik konwekcji `h_c ~ v^0.6`.
/// - Chłodzenie przez parowanie potu `Q_evap` ograniczone maksymalną zdolnością
///   parowania `E_max` (zależną od wilgotności i `v^0.6`) oraz wydolnością gruczołów potowych.
/// - Powyżej 39.2 °C następuje termiczny spadek mocy maksymalnej oraz dryf tętna +12 BPM.
class CoreBodyTemperatureThermoregulation {
  CoreBodyTemperatureThermoregulation._();

  /// Minimalna (spoczynkowa) temperatura głęboka ciała w modelu [°C].
  static const double minCoreTempCelsius = 37.0;

  /// Maksymalna temperatura głęboka ciała w modelu [°C].
  static const double maxCoreTempCelsius = 40.5;

  /// Próg krytyczny temperatury głębokiej [°C], powyżej którego spada moc maksymalna
  /// i pojawia się dryf tętna +12 BPM.
  static const double criticalPowerDropThresholdCelsius = 39.2;

  /// Dryf tętna powyżej 39.2 °C [BPM].
  static const double hyperthermicHeartRateDriftBpm = 12.0;

  /// Maksymalna redukcja mocy maksymalnej przy 40.5 °C (25% spadku).
  static const double maxHyperthermicPowerDropFraction = 0.25;

  /// Domyślna sprawność brutto kolarza (eta = 0.23).
  static const double defaultGrossEfficiency = 0.23;

  /// Ciepło właściwe tkanek ciała ludzkiego [J / (kg * °C)].
  static const double humanBodySpecificHeatJPerKgC = 3470.0;

  /// Stała konwekcji wymuszonej dla kolarza [W / (m^2 * °C * (m/s)^0.6)].
  static const double convectiveCoefficientConstant = 8.3;

  /// Relacja Lewisa wiążąca konwekcję i parowanie [°C / kPa].
  static const double lewisRelationCoeff = 16.5;

  /// Utajone ciepło parowania potu [J / ml] (~2426 J/g).
  static const double sweatLatentHeatJPerMl = 2426.0;

  /// Minimalny efektywny przepływ powietrza (konwekcja naturalna przy postoju) [m/s].
  static const double minNaturalAirSpeedMps = 0.4;

  /// Oblicza produkcję ciepła metabolicznego `Q_prod = P * (1 - eta) / eta` [W].
  static double calculateMetabolicHeatProductionWatts({
    required double powerWatts,
    double grossEfficiency = defaultGrossEfficiency,
  }) {
    final double safePower = math.max(0.0, powerWatts);
    final double safeEta = grossEfficiency.clamp(0.10, 0.40).toDouble();
    return safePower * (1.0 - safeEta) / safeEta;
  }

  /// Oblicza współczynnik konwekcji `h_c ~ v^0.6` [W / (m^2 * °C)].
  static double calculateConvectiveCoefficient(double airSpeedMps) {
    final double effectiveSpeed = math.max(minNaturalAirSpeedMps, airSpeedMps);
    return convectiveCoefficientConstant * math.pow(effectiveSpeed, 0.6);
  }

  /// Oblicza chłodzenie konwekcyjne wiatrem `Q_conv` [W] (dodatnie = utrata ciepła).
  static double calculateConvectiveCoolingWatts({
    required double airSpeedMps,
    required double skinTemperatureCelsius,
    required double ambientTemperatureCelsius,
    double bodySurfaceAreaM2 = 1.85,
  }) {
    final double hc = calculateConvectiveCoefficient(airSpeedMps);
    final double bsa = math.max(1.0, bodySurfaceAreaM2);
    return hc * bsa * (skinTemperatureCelsius - ambientTemperatureCelsius);
  }

  /// Oblicza prężność pary nasyconej (wzór Magnusa) [kPa].
  static double saturationVaporPressureKpa(double temperatureCelsius) {
    return 0.61078 *
        math.exp(
          (17.27 * temperatureCelsius) / (temperatureCelsius + 237.3),
        );
  }

  /// Oblicza chłodzenie przez parowanie potu `Q_evap` [W] oraz utratę potu [ml/s].
  static ({double evaporativeCoolingWatts, double sweatRateMlPerSecond})
      calculateEvaporativeCooling({
    required double coreTemperatureCelsius,
    required double skinTemperatureCelsius,
    required double ambientTemperatureCelsius,
    required double relativeHumidity,
    required double airSpeedMps,
    double bodySurfaceAreaM2 = 1.85,
    double hydrationLevel = 1.0,
    double heatAcclimatization = 0.0,
    bool wearingRainJacket = false,
  }) {
    final double bsa = math.max(1.0, bodySurfaceAreaM2);
    final double rh = relativeHumidity.clamp(0.05, 1.0).toDouble();
    final double hydration = hydrationLevel.clamp(0.0, 1.0).toDouble();
    final double acclimation = heatAcclimatization.clamp(0.0, 1.0).toDouble();

    // Napęd termoregulacyjny pocenia rośnie wraz ze wzrostem T_core powyżej 37.0 °C.
    final double coreDrive =
        math.max(0.0, coreTemperatureCelsius - minCoreTempCelsius);
    // Bazowa max szybkość pocenia ~0.42 ml/s (~1.5 L/h), z aklimatyzacją do ~0.58 ml/s (~2.1 L/h).
    final double maxPhysiologicalSweatRate = 0.42 * (1.0 + 0.38 * acclimation);
    final double hydrationFactor = 0.35 + 0.65 * hydration;
    final double targetSweatRateMlPerSec =
        (coreDrive / 2.0).clamp(0.0, 1.0) *
            maxPhysiologicalSweatRate *
            hydrationFactor;

    final double potentialSweatCoolingWatts =
        targetSweatRateMlPerSec * sweatLatentHeatJPerMl;

    // Maksymalna zdolność parowania otoczenia E_max (zależna od v^0.6 i gradientu ciśnień pary).
    final double hc = calculateConvectiveCoefficient(airSpeedMps);
    final double he = lewisRelationCoeff * hc;
    final double pSkinSat = saturationVaporPressureKpa(skinTemperatureCelsius);
    final double pAmbSat =
        saturationVaporPressureKpa(ambientTemperatureCelsius);
    final double vaporGradientKpa = math.max(0.0, pSkinSat - rh * pAmbSat);

    final double jacketPermeability = wearingRainJacket ? 0.25 : 1.0;
    final double eMaxWatts = he * bsa * vaporGradientKpa * jacketPermeability;

    final double actualEvapWatts =
        math.min(potentialSweatCoolingWatts, eMaxWatts);

    return (
      evaporativeCoolingWatts: actualEvapWatts,
      sweatRateMlPerSecond: targetSweatRateMlPerSec,
    );
  }

  /// Zwraca mnożnik mocy maksymalnej (1.0 dla T <= 39.2 °C; spadek powyżej 39.2 °C).
  static double evaluateMaxPowerMultiplier(double coreBodyTemperatureCelsius) {
    if (coreBodyTemperatureCelsius <= criticalPowerDropThresholdCelsius) {
      return 1.0;
    }
    const double span = maxCoreTempCelsius - criticalPowerDropThresholdCelsius;
    final double excess =
        (coreBodyTemperatureCelsius - criticalPowerDropThresholdCelsius)
            .clamp(0.0, span)
            .toDouble();
    final double fraction = excess / span;
    return (1.0 - fraction * maxHyperthermicPowerDropFraction)
        .clamp(1.0 - maxHyperthermicPowerDropFraction, 1.0)
        .toDouble();
  }

  /// Zwraca termiczny dryf tętna (+12.0 BPM powyżej 39.2 °C).
  static double evaluateHeartRateDriftBpm(double coreBodyTemperatureCelsius) {
    if (coreBodyTemperatureCelsius > criticalPowerDropThresholdCelsius) {
      return hyperthermicHeartRateDriftBpm;
    }
    return 0.0;
  }

  /// Klasyfikuje temperaturę głęboką do strefy termicznej.
  static CoreThermalZone classifyZone(double coreBodyTemperatureCelsius) {
    if (coreBodyTemperatureCelsius > criticalPowerDropThresholdCelsius) {
      return CoreThermalZone.hyperthermicCollapse;
    }
    if (coreBodyTemperatureCelsius >= 38.8) {
      return CoreThermalZone.highThermalStrain;
    }
    if (coreBodyTemperatureCelsius >= 38.0) {
      return CoreThermalZone.elevatedExercise;
    }
    return CoreThermalZone.normothermia;
  }

  /// Wykonuje jeden krok czasowy symulacji bilansu cieplnego i temperatury głębokiej.
  static ThermoregulationStepResult step({
    required ThermoregulationState currentState,
    required ThermoregulationStepInput input,
  }) {
    final double dt = math.max(0.0, input.deltaTimeSeconds);
    final double qProd = calculateMetabolicHeatProductionWatts(
      powerWatts: input.powerWatts,
      grossEfficiency: input.grossEfficiency,
    );

    final double qConv = calculateConvectiveCoolingWatts(
      airSpeedMps: input.airSpeedMps,
      skinTemperatureCelsius: currentState.skinTemperatureCelsius,
      ambientTemperatureCelsius: input.ambientTemperatureCelsius,
      bodySurfaceAreaM2: input.bodySurfaceAreaM2,
    );

    final evap = calculateEvaporativeCooling(
      coreTemperatureCelsius: currentState.coreBodyTemperatureCelsius,
      skinTemperatureCelsius: currentState.skinTemperatureCelsius,
      ambientTemperatureCelsius: input.ambientTemperatureCelsius,
      relativeHumidity: input.relativeHumidity,
      airSpeedMps: input.airSpeedMps,
      bodySurfaceAreaM2: input.bodySurfaceAreaM2,
      hydrationLevel: input.hydrationLevel,
      heatAcclimatization: input.heatAcclimatization,
      wearingRainJacket: input.wearingRainJacket,
    );

    final double qEvap = evap.evaporativeCoolingWatts;
    final double externalCooling = math.max(0.0, input.externalCoolingWatts);
    final double netHeatWatts = qProd - qConv - qEvap - externalCooling;

    final double safeMassKg = math.max(40.0, input.riderMassKg);
    final double thermalCapacityJPerC =
        safeMassKg * humanBodySpecificHeatJPerKgC;
    final double rawDeltaT = (netHeatWatts * dt) / thermalCapacityJPerC;

    final double nextCoreTemp =
        (currentState.coreBodyTemperatureCelsius + rawDeltaT)
            .clamp(minCoreTempCelsius, maxCoreTempCelsius)
            .toDouble();
    final double actualDeltaT =
        nextCoreTemp - currentState.coreBodyTemperatureCelsius;

    // Temperatura skóry dąży do równowagi między temperaturą otoczenia a głęboką.
    final double targetSkinTemp = (0.35 * input.ambientTemperatureCelsius +
            0.65 * nextCoreTemp)
        .clamp(28.0, 38.5)
        .toDouble();
    final double skinAlpha = (dt / 120.0).clamp(0.0, 1.0).toDouble();
    final double nextSkinTemp = currentState.skinTemperatureCelsius +
        skinAlpha * (targetSkinTemp - currentState.skinTemperatureCelsius);

    final double sweatStepMl = evap.sweatRateMlPerSecond * dt;
    final ThermoregulationState updatedState = currentState.copyWith(
      coreBodyTemperatureCelsius: nextCoreTemp,
      skinTemperatureCelsius: nextSkinTemp,
      cumulativeSweatLossMl: currentState.cumulativeSweatLossMl + sweatStepMl,
    );

    return ThermoregulationStepResult(
      updatedState: updatedState,
      metabolicHeatProductionWatts: qProd,
      convectiveCoolingWatts: qConv,
      evaporativeCoolingWatts: qEvap,
      netHeatStorageWatts: netHeatWatts,
      deltaCoreTempCelsius: actualDeltaT,
      sweatLossStepMl: sweatStepMl,
      maxPowerMultiplier: evaluateMaxPowerMultiplier(nextCoreTemp),
      heartRateDriftBpm: evaluateHeartRateDriftBpm(nextCoreTemp),
      thermalZone: classifyZone(nextCoreTemp),
    );
  }
}
