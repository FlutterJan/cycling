// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/rider/rider.dart';

/// Poziom stresu cieplnego kolarza na podstawie temperatury głębokiej ciała.
enum ThermalStrainLevel {
  /// Temperatura w normie (<= 37.8 °C).
  optimal,

  /// Lekkie nagrzanie wysiłkowe (37.8 - 38.4 °C).
  elevated,

  /// Wyraźny stres cieplny, spadek wydolności (38.4 - 39.0 °C).
  highStrain,

  /// Przegrzanie / hipertermia krytyczna (> 39.0 °C, próg 39.5 °C).
  criticalOverheating;

  String get displayName {
    switch (this) {
      case ThermalStrainLevel.optimal:
        return 'Optymalna';
      case ThermalStrainLevel.elevated:
        return 'Podwyższona';
      case ThermalStrainLevel.highStrain:
        return 'Stres cieplny';
      case ThermalStrainLevel.criticalOverheating:
        return 'Przegrzanie!';
    }
  }
}

/// Wynik obliczeń wpływu wysokości n.p.m. na wydolność tlenową kolarza.
class AltitudePerformanceResult {
  /// Wysokość n.p.m. [m].
  final double altitudeMeters;

  /// Efektywny wynik aklimatyzacji wysokościowej użyty w obliczeniach (0.0 - 100.0).
  final double effectiveAcclimatizationScore;

  /// Czy kolarz pochodzi z regionu wysokogórskiego (np. Kolumbia, Ekwador).
  final bool isHighAltitudeNative;

  /// Bazowy spadek FTP przed uwzględnieniem aklimatyzacji [0.0 - 1.0].
  final double rawFtpLossFraction;

  /// Rzeczywisty spadek FTP po uwzględnieniu aklimatyzacji [0.0 - 1.0].
  final double actualFtpLossFraction;

  /// Mnożnik bazowego FTP (np. 0.94 oznacza -6% mocy).
  final double ftpMultiplier;

  /// Efektywne FTP na danej wysokości [W].
  final double effectiveFtpWatts;

  /// Gęstość powietrza na danej wysokości [kg/m^3].
  final double airDensityKgM3;

  const AltitudePerformanceResult({
    required this.altitudeMeters,
    required this.effectiveAcclimatizationScore,
    required this.isHighAltitudeNative,
    required this.rawFtpLossFraction,
    required this.actualFtpLossFraction,
    required this.ftpMultiplier,
    required this.effectiveFtpWatts,
    required this.airDensityKgM3,
  });

  /// Procentowa strata mocy FTP na wysokości (np. 6.0 dla -6%).
  double get ftpLossPercent => actualFtpLossFraction * 100.0;
}

/// Stan termoregulacji i użycia skarpet lodowych (Ice Socks) kolarza w trakcie etapu.
class RiderThermalState {
  /// Temperatura głęboka ciała (Core Body Temperature) [°C]. Bazowo 37.0 °C.
  final double coreBodyTemperatureCelsius;

  /// Skumulowany poziom adaptacji cieplnej kolarza (0.0 - 100.0).
  final double heatAcclimatizationScore;

  /// Pozostały czas działania aktywnych skarpet lodowych [s].
  final double iceSockRemainingSeconds;

  /// Liczba użytych skarpet lodowych na bieżącym etapie.
  final int iceSocksUsedCount;

  /// Liczba dostępnych skarpet lodowych w wozie technicznym dla tego kolarza.
  final int iceSocksAvailableInTeamCar;

  const RiderThermalState({
    this.coreBodyTemperatureCelsius =
        AltitudeAcclimatizationAndHeatEngine.baselineCoreTempCelsius,
    this.heatAcclimatizationScore = 0.0,
    this.iceSockRemainingSeconds = 0.0,
    this.iceSocksUsedCount = 0,
    this.iceSocksAvailableInTeamCar = 3,
  });

  /// Czy skarpety lodowe aktualnie aktywnie chłodzą kolarza.
  bool get isIceSockActive => iceSockRemainingSeconds > 0.0;

  /// Aktualny poziom stresu cieplnego.
  ThermalStrainLevel get strainLevel {
    if (coreBodyTemperatureCelsius >=
        AltitudeAcclimatizationAndHeatEngine.criticalCoreTempThresholdCelsius) {
      return ThermalStrainLevel.criticalOverheating;
    }
    if (coreBodyTemperatureCelsius >= 38.4) {
      return ThermalStrainLevel.highStrain;
    }
    if (coreBodyTemperatureCelsius >= 37.8) {
      return ThermalStrainLevel.elevated;
    }
    return ThermalStrainLevel.optimal;
  }

  /// Czy kolarz znajduje się w strefie krytycznego przegrzania (>= 39.0 °C).
  bool get isOverheating =>
      coreBodyTemperatureCelsius >=
      AltitudeAcclimatizationAndHeatEngine.criticalCoreTempThresholdCelsius;

  RiderThermalState copyWith({
    double? coreBodyTemperatureCelsius,
    double? heatAcclimatizationScore,
    double? iceSockRemainingSeconds,
    int? iceSocksUsedCount,
    int? iceSocksAvailableInTeamCar,
  }) {
    return RiderThermalState(
      coreBodyTemperatureCelsius:
          coreBodyTemperatureCelsius ?? this.coreBodyTemperatureCelsius,
      heatAcclimatizationScore:
          heatAcclimatizationScore ?? this.heatAcclimatizationScore,
      iceSockRemainingSeconds:
          iceSockRemainingSeconds ?? this.iceSockRemainingSeconds,
      iceSocksUsedCount: iceSocksUsedCount ?? this.iceSocksUsedCount,
      iceSocksAvailableInTeamCar:
          iceSocksAvailableInTeamCar ?? this.iceSocksAvailableInTeamCar,
    );
  }
}

/// Wynik pojedynczego kroku symulacji termicznej oraz wpływu na moc kolarza.
class HeatStrainStepResult {
  /// Zaktualizowany stan termiczny kolarza.
  final RiderThermalState updatedState;

  /// Zmiana temperatury głębokiej w tym kroku [°C].
  final double deltaCoreTempCelsius;

  /// Mnożnik mocy FTP wynikający ze stresu cieplnego (1.0 = brak strat).
  final double thermalFtpMultiplier;

  /// Dodatkowy dryf tętna spowodowany przegrzaniem [bpm].
  final double heartRateThermalDriftBpm;

  /// Wskaźnik obciążenia cieplnego (dodatni = nagrzewanie, ujemny = chłodzenie).
  final double netThermalRateCelsiusPerSecond;

  /// Czy zalecane jest natychmiastowe podanie skarpet lodowych z wozu technicznego.
  final bool shouldRecommendIceSocks;

  const HeatStrainStepResult({
    required this.updatedState,
    required this.deltaCoreTempCelsius,
    required this.thermalFtpMultiplier,
    required this.heartRateThermalDriftBpm,
    required this.netThermalRateCelsiusPerSecond,
    required this.shouldRecommendIceSocks,
  });
}

/// Połączona ocena wpływu wysokości n.p.m. oraz stresu cieplnego na wydolność kolarza.
class AltitudeAndHeatCombinedResult {
  final AltitudePerformanceResult altitudeResult;
  final HeatStrainStepResult heatResult;

  /// Łączny mnożnik bazowego FTP (wysokość * stres cieplny).
  final double combinedFtpMultiplier;

  /// Końcowe efektywne FTP [W] uwzględniające oba czynniki środowiskowe.
  final double effectiveFtpWatts;

  const AltitudeAndHeatCombinedResult({
    required this.altitudeResult,
    required this.heatResult,
    required this.combinedFtpMultiplier,
    required this.effectiveFtpWatts,
  });
}

/// Silnik fizjologiczny aklimatyzacji wysokościowej i adaptacji cieplnej.
///
/// Odpowiada za:
/// 1. Modelowanie spadku wydolności tlenowej (FTP) powyżej 1500 m n.p.m.
///    (1.5% na każde kolejne 300 m dla kolarza niezaaklimatyzowanego; o połowę
///    mniej dla kolarzy po obozie wysokogórskim lub urodzonych w wysokich górach,
///    np. Kolumbia, Ekwador).
/// 2. Modelowanie temperatury głębokiej ciała (`CoreBodyTemperatureCelsius`) podczas
///    jazdy pod górę w upale (>32 °C) przy niskiej prędkości chłodzenia powietrzem
///    oraz mechanikę skarpet lodowych (Ice Socks) podawanych z wozu technicznego.
class AltitudeAcclimatizationAndHeatEngine {
  AltitudeAcclimatizationAndHeatEngine._();

  // --- Stałe modelu wysokościowego ---

  /// Wysokość progowa [m n.p.m.], powyżej której zaczyna się spadek FTP.
  static const double altitudeThresholdMeters = 1500.0;

  /// Krok wysokościowy [m] dla referencyjnej straty 1.5% FTP.
  static const double altitudeLossStepMeters = 300.0;

  /// Bazowa strata FTP na każde 300 m powyżej 1500 m dla niezaaklimatyzowanego kolarza.
  static const double baseFtpLossPerStep = 0.015; // 1.5%

  /// Minimalna wartość mnożnika FTP na ekstremalnych wysokościach (zabezpieczenie).
  static const double minAltitudeFtpMultiplier = 0.60;

  /// Kody ISO krajów o wysokiej naturalnej adaptacji wysokościowej (Andy / Wyżyna Wschodnioafrykańska).
  static const Set<String> highAltitudeNativeCountriesIso = {
    'COL', // Kolumbia
    'ECU', // Ekwador
    'BOL', // Boliwia
    'PER', // Peru
    'ETH', // Etiopia
    'KEN', // Kenia
    'ERI', // Erytrea
    'RWA', // Rwanda
  };

  // --- Stałe modelu cieplnego ---

  /// Fizjologiczna spoczynkowa temperatura głęboka ciała [°C].
  static const double baselineCoreTempCelsius = 37.0;

  /// Dolna granica bezpieczeństwa modelu temperatury głębokiej [°C].
  static const double minCoreTempCelsius = 36.2;

  /// Górna granica temperatury głębokiej w modelu (ciężka hipertermia) [°C].
  static const double maxCoreTempCelsius = 40.2;

  /// Docelowa temperatura krytyczna hipertermii na podjazdach w upale [°C].
  static const double peakHeatStrainTargetCelsius = 39.5;

  /// Próg ostrzegawczy / krytycznego przegrzania [°C].
  static const double criticalCoreTempThresholdCelsius = 39.0;

  /// Próg temperatury otoczenia uznawany za upał ograniczający chłodzenie [°C].
  static const double heatStressAmbientThresholdCelsius = 32.0;

  /// Standardowy czas działania jednej pary skarpet lodowych [s] (15 minut).
  static const double defaultIceSockDurationSeconds = 900.0;

  /// Sprawdza, czy kod kraju ISO odpowiada regionowi wysokogórskiemu (np. COL, ECU).
  static bool isHighAltitudeNativeCountry(String nationalityIso) {
    final normalized = nationalityIso.trim().toUpperCase();
    return highAltitudeNativeCountriesIso.contains(normalized);
  }

  /// Oblicza wpływ wysokości n.p.m. na bazowe FTP kolarza.
  ///
  /// - Do 1500 m n.p.m. brak spadku wydolności (`ftpMultiplier = 1.0`).
  /// - Powyżej 1500 m niezreklimatyzowany kolarz traci 1.5% FTP na każde 300 m
  ///   (np. na 2700 m n.p.m. jest to -6.0% mocy).
  /// - Kolarz z pełną aklimatyzacją (`altitudeAcclimatizationScore == 100`)
  ///   lub urodzony na dużej wysokości (`COL`, `ECU`, itp.) traci dokładnie
  ///   o połowę mniej (-3.0% na 2700 m n.p.m.).
  static AltitudePerformanceResult evaluateAltitudeEffect({
    required double altitudeMeters,
    required double baseFtpWatts,
    double altitudeAcclimatizationScore = 0.0,
    String nationalityIso = '',
    bool? isHighAltitudeNativeOverride,
  }) {
    final double clampedFtp = math.max(0.0, baseFtpWatts);
    final bool isNative = isHighAltitudeNativeOverride ??
        isHighAltitudeNativeCountry(nationalityIso);

    final double clampedScore =
        altitudeAcclimatizationScore.clamp(0.0, 100.0).toDouble();
    final double effectiveScore = isNative ? 100.0 : clampedScore;

    final double airDensity =
        PhysicsConstants.getAirDensityAtAltitude(altitudeMeters);

    if (altitudeMeters <= altitudeThresholdMeters) {
      return AltitudePerformanceResult(
        altitudeMeters: altitudeMeters,
        effectiveAcclimatizationScore: effectiveScore,
        isHighAltitudeNative: isNative,
        rawFtpLossFraction: 0.0,
        actualFtpLossFraction: 0.0,
        ftpMultiplier: 1.0,
        effectiveFtpWatts: clampedFtp,
        airDensityKgM3: airDensity,
      );
    }

    final double excessMeters = altitudeMeters - altitudeThresholdMeters;
    final double rawLossFraction =
        (excessMeters / altitudeLossStepMeters) * baseFtpLossPerStep;

    // Pełna aklimatyzacja (100) lub pochodzenie wysokogórskie redukuje stratę o 50%.
    final double acclimatizationMitigation =
        1.0 - (0.5 * (effectiveScore / 100.0));
    final double actualLossFraction =
        (rawLossFraction * acclimatizationMitigation).clamp(0.0, 0.40);

    final double ftpMultiplier =
        (1.0 - actualLossFraction).clamp(minAltitudeFtpMultiplier, 1.0);

    return AltitudePerformanceResult(
      altitudeMeters: altitudeMeters,
      effectiveAcclimatizationScore: effectiveScore,
      isHighAltitudeNative: isNative,
      rawFtpLossFraction: rawLossFraction,
      actualFtpLossFraction: actualLossFraction,
      ftpMultiplier: ftpMultiplier,
      effectiveFtpWatts: clampedFtp * ftpMultiplier,
      airDensityKgM3: airDensity,
    );
  }

  /// Wygodna metoda obliczająca wpływ wysokości bezpośrednio dla obiektu [Rider].
  static AltitudePerformanceResult evaluateAltitudeEffectForRider({
    required Rider rider,
    required double altitudeMeters,
    double altitudeAcclimatizationScore = 0.0,
  }) {
    return evaluateAltitudeEffect(
      altitudeMeters: altitudeMeters,
      baseFtpWatts: rider.physiology.ftpWatts.toDouble(),
      altitudeAcclimatizationScore: altitudeAcclimatizationScore,
      nationalityIso: rider.nationalityIso,
    );
  }

  /// Aktualizuje wynik aklimatyzacji wysokościowej po dniu spędzonym na obozie
  /// wysokogórskim lub na nizinach (stopniowy zanik adaptacji).
  static double updateAltitudeAcclimatizationScore({
    required double currentScore,
    required double campAltitudeMeters,
    required int daysAtAltitude,
  }) {
    final double clampedCurrent = currentScore.clamp(0.0, 100.0).toDouble();
    if (daysAtAltitude <= 0) return clampedCurrent;

    if (campAltitudeMeters >= altitudeThresholdMeters) {
      // Ok. 14-21 dni na >1800 m pozwala osiągnąć pełną aklimatyzację (~6-7 pkt/dzień).
      final double altitudeFactor =
          ((campAltitudeMeters - 1200.0) / 1000.0).clamp(0.4, 1.4);
      final double dailyGain = 5.5 * altitudeFactor;
      return (clampedCurrent + dailyGain * daysAtAltitude).clamp(0.0, 100.0);
    }

    // Na nizinach adaptacja wygasa stopniowo (~3.5 pkt/dzień).
    const double dailyDecay = 3.5;
    return (clampedCurrent - dailyDecay * daysAtAltitude).clamp(0.0, 100.0);
  }

  /// Wydaje skarpety lodowe (Ice Socks) z wozu technicznego.
  ///
  /// Jeśli brak dostępnych skarpet w zapasie, stan pozostaje niezmieniony.
  static RiderThermalState deployIceSocks(
    RiderThermalState state, {
    double durationSeconds = defaultIceSockDurationSeconds,
  }) {
    if (state.iceSocksAvailableInTeamCar <= 0 || durationSeconds <= 0.0) {
      return state;
    }
    return state.copyWith(
      iceSockRemainingSeconds: durationSeconds,
      iceSocksUsedCount: state.iceSocksUsedCount + 1,
      iceSocksAvailableInTeamCar: state.iceSocksAvailableInTeamCar - 1,
    );
  }

  /// Wykonuje krok symulacji temperatury głębokiej ciała (`CoreBodyTemperatureCelsius`).
  ///
  /// Podczas jazdy pod górę w upale (>32 °C) przy niskiej prędkości powietrza
  /// chłodzącego temperatura rośnie z 37.0 °C w stronę 39.5 °C.
  /// Aktywne skarpety lodowe (Ice Socks) skutecznie obniżają temperaturę głęboką
  /// i chronią przed wejściem w strefę przegrzania.
  static HeatStrainStepResult simulateThermalStep({
    required RiderThermalState currentState,
    required double deltaTimeSeconds,
    required double ambientTemperatureCelsius,
    required double airSpeedMetersPerSecond,
    required double currentPowerWatts,
    required double baseFtpWatts,
    int heatTolerance = 50,
    double relativeHumidity01 = 0.45,
    double gradientPercent = 0.0,
  }) {
    if (deltaTimeSeconds <= 0.0) {
      final double mult =
          calculateThermalFtpMultiplier(currentState.coreBodyTemperatureCelsius);
      return HeatStrainStepResult(
        updatedState: currentState,
        deltaCoreTempCelsius: 0.0,
        thermalFtpMultiplier: mult,
        heartRateThermalDriftBpm:
            calculateHeartRateThermalDrift(currentState.coreBodyTemperatureCelsius),
        netThermalRateCelsiusPerSecond: 0.0,
        shouldRecommendIceSocks:
            _shouldRecommendIceSocks(currentState, ambientTemperatureCelsius),
      );
    }

    final double safeFtp = math.max(100.0, baseFtpWatts);
    final double intensityRatio =
        (currentPowerWatts / safeFtp).clamp(0.0, 2.2).toDouble();
    final double clampedHumidity = relativeHumidity01.clamp(0.05, 0.98);
    final double clampedTolerance = heatTolerance.clamp(0, 100).toDouble();
    final double clampedHeatAcclim =
        currentState.heatAcclimatizationScore.clamp(0.0, 100.0).toDouble();

    // 1. Produkcja ciepła metabolicznego: rośnie z intensywnością wysiłku.
    // Przy intensywności FTP (1.0) w warunkach bazowych generuje ~0.0019 °C/s przed chłodzeniem.
    final double metabolicHeatRate =
        0.00035 + (math.pow(intensityRatio, 1.18) * 0.00175);

    // 2. Chłodzenie konwekcyjne i przez parowanie potu:
    // Niska prędkość powietrza na podjeździe (np. 3-5 m/s) dramatycznie obniża chłodzenie.
    final double effectiveWindMs = math.max(0.5, airSpeedMetersPerSecond);
    final double windCoolingFactor =
        (math.sqrt(effectiveWindMs / 10.0)).clamp(0.25, 1.45);

    // W upale > 32°C gradient temperaturowy skóra-powietrze zanika lub się odwraca.
    final double ambientDelta = 36.0 - ambientTemperatureCelsius;
    final double ambientCoolingFactor =
        (ambientDelta / 16.0).clamp(-0.35, 1.35);

    // Wysoka wilgotność blokuje parowanie potu.
    final double evaporativeEfficiency =
        (1.15 - clampedHumidity * 0.65).clamp(0.35, 1.0);

    // Adaptacja cieplna i cecha heatTolerance poprawiają termoregulację (do ~25% lepiej).
    final double toleranceFactor = 1.0 +
        ((clampedTolerance - 50.0) / 100.0) * 0.18 +
        (clampedHeatAcclim / 100.0) * 0.14;

    // Gradient powyżej 4% zmniejsza ekspozycję na opływ i zwiększa obciążenie statyczne.
    final double climbPenalty =
        gradientPercent > 4.0 ? ((gradientPercent - 4.0) * 0.015).clamp(0.0, 0.15) : 0.0;

    final double naturalCoolingRate = ((0.00125 * windCoolingFactor) +
            (0.00075 * ambientCoolingFactor)) *
        evaporativeEfficiency *
        toleranceFactor *
        (1.0 - climbPenalty);

    // 3. Chłodzenie przez skarpety lodowe (Ice Socks):
    // Topią się szybciej w skrajnym upale.
    double remainingIceSeconds = currentState.iceSockRemainingSeconds;
    double iceCoolingRate = 0.0;
    if (remainingIceSeconds > 0.0) {
      final double meltMultiplier = ambientTemperatureCelsius > 32.0
          ? 1.0 + ((ambientTemperatureCelsius - 32.0) * 0.05).clamp(0.0, 0.5)
          : 1.0;
      final double effectiveActiveSeconds =
          math.min(deltaTimeSeconds, remainingIceSeconds / meltMultiplier);
      final double activeFraction =
          (effectiveActiveSeconds / deltaTimeSeconds).clamp(0.0, 1.0);

      // Silny efekt chłodzący z okolicy karku i naczyń krwionośnych (~0.0022 °C/s).
      iceCoolingRate = 0.0022 * activeFraction;
      remainingIceSeconds =
          math.max(0.0, remainingIceSeconds - deltaTimeSeconds * meltMultiplier);
    }

    // 4. Homeostaza dążąca do przywrócenia temperatury spoczynkowej 37.0 °C
    // (proporcjonalna do różnicy względem 37.0 °C przy braku przegrzewania zewnętrznego).
    final double excessTemp =
        currentState.coreBodyTemperatureCelsius - baselineCoreTempCelsius;
    final double passiveHomeostasis = excessTemp > 0.0
        ? excessTemp * (ambientTemperatureCelsius > 32.0 ? 0.00025 : 0.00065)
        : excessTemp * 0.0008;

    // Tłumienie asymptotyczne przy zbliżaniu się do 39.5-40.2 °C.
    final double highTempDamping =
        currentState.coreBodyTemperatureCelsius > 39.2
            ? (1.0 -
                    ((currentState.coreBodyTemperatureCelsius - 39.2) / 1.1)
                        .clamp(0.0, 0.75))
            : 1.0;

    double netRate = (metabolicHeatRate - naturalCoolingRate - passiveHomeostasis) *
            highTempDamping -
        iceCoolingRate;

    // W warunkach głębokiego upału (>32 °C) przy niskiej prędkości powietrza na podjeździe
    // bez skarpet lodowych temperatura nie spada poniżej progu wysiłkowego, lecz zmierza ku 39.5 °C.
    if (ambientTemperatureCelsius > heatStressAmbientThresholdCelsius &&
        effectiveWindMs < 6.5 &&
        intensityRatio >= 0.70 &&
        iceCoolingRate == 0.0 &&
        currentState.coreBodyTemperatureCelsius < peakHeatStrainTargetCelsius &&
        netRate < 0.00035) {
      netRate = math.max(netRate, 0.00035 * (intensityRatio.clamp(0.7, 1.3)));
    }

    final double newTemp =
        (currentState.coreBodyTemperatureCelsius + netRate * deltaTimeSeconds)
            .clamp(minCoreTempCelsius, maxCoreTempCelsius);
    final double actualDelta = newTemp - currentState.coreBodyTemperatureCelsius;

    final RiderThermalState updatedState = currentState.copyWith(
      coreBodyTemperatureCelsius: newTemp,
      iceSockRemainingSeconds: remainingIceSeconds,
    );

    final double thermalMultiplier = calculateThermalFtpMultiplier(newTemp);
    final double hrDrift = calculateHeartRateThermalDrift(newTemp);

    return HeatStrainStepResult(
      updatedState: updatedState,
      deltaCoreTempCelsius: actualDelta,
      thermalFtpMultiplier: thermalMultiplier,
      heartRateThermalDriftBpm: hrDrift,
      netThermalRateCelsiusPerSecond: netRate,
      shouldRecommendIceSocks:
          _shouldRecommendIceSocks(updatedState, ambientTemperatureCelsius),
    );
  }

  /// Oblicza mnożnik dostępnej mocy FTP w zależności od temperatury głębokiej ciała.
  ///
  /// - Do 38.0 °C: 1.0 (brak strat).
  /// - 38.0 - 39.0 °C: łagodny spadek do 0.94 (-6%).
  /// - 39.0 - 39.5+ °C: gwałtowny spadek wydolności (do 0.78 przy 40.0 °C).
  static double calculateThermalFtpMultiplier(double coreBodyTemperatureCelsius) {
    if (coreBodyTemperatureCelsius <= 38.0) {
      return 1.0;
    }
    if (coreBodyTemperatureCelsius <= 39.0) {
      final double progress = (coreBodyTemperatureCelsius - 38.0) / 1.0;
      return (1.0 - progress * 0.06).clamp(0.94, 1.0);
    }
    final double severeProgress =
        ((coreBodyTemperatureCelsius - 39.0) / 1.0).clamp(0.0, 1.2);
    return (0.94 - severeProgress * 0.16).clamp(0.75, 0.94);
  }

  /// Oblicza termiczny dryf tętna [bpm] wynikający z przekrwienia skóry i odwodnienia.
  static double calculateHeartRateThermalDrift(double coreBodyTemperatureCelsius) {
    if (coreBodyTemperatureCelsius <= 37.6) {
      return 0.0;
    }
    final double excess = coreBodyTemperatureCelsius - 37.6;
    return (excess * 7.5).clamp(0.0, 22.0);
  }

  /// Łączy model wysokościowy i cieplny w jednym kroku fizjologicznym.
  static AltitudeAndHeatCombinedResult evaluateCombinedStep({
    required double altitudeMeters,
    required double baseFtpWatts,
    required double altitudeAcclimatizationScore,
    required String nationalityIso,
    required RiderThermalState thermalState,
    required double deltaTimeSeconds,
    required double ambientTemperatureCelsius,
    required double airSpeedMetersPerSecond,
    required double currentPowerWatts,
    int heatTolerance = 50,
    double relativeHumidity01 = 0.45,
    double gradientPercent = 0.0,
  }) {
    final AltitudePerformanceResult altitudeResult = evaluateAltitudeEffect(
      altitudeMeters: altitudeMeters,
      baseFtpWatts: baseFtpWatts,
      altitudeAcclimatizationScore: altitudeAcclimatizationScore,
      nationalityIso: nationalityIso,
    );

    final HeatStrainStepResult heatResult = simulateThermalStep(
      currentState: thermalState,
      deltaTimeSeconds: deltaTimeSeconds,
      ambientTemperatureCelsius: ambientTemperatureCelsius,
      airSpeedMetersPerSecond: airSpeedMetersPerSecond,
      currentPowerWatts: currentPowerWatts,
      baseFtpWatts: baseFtpWatts,
      heatTolerance: heatTolerance,
      relativeHumidity01: relativeHumidity01,
      gradientPercent: gradientPercent,
    );

    final double combinedMultiplier =
        (altitudeResult.ftpMultiplier * heatResult.thermalFtpMultiplier)
            .clamp(0.50, 1.0);

    return AltitudeAndHeatCombinedResult(
      altitudeResult: altitudeResult,
      heatResult: heatResult,
      combinedFtpMultiplier: combinedMultiplier,
      effectiveFtpWatts: math.max(0.0, baseFtpWatts) * combinedMultiplier,
    );
  }

  static bool _shouldRecommendIceSocks(
    RiderThermalState state,
    double ambientTemperatureCelsius,
  ) {
    if (state.isIceSockActive || state.iceSocksAvailableInTeamCar <= 0) {
      return false;
    }
    return state.coreBodyTemperatureCelsius >= 38.3 ||
        (ambientTemperatureCelsius > heatStressAmbientThresholdCelsius &&
            state.coreBodyTemperatureCelsius >= 37.9);
  }
}
