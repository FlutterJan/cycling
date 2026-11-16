// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/rider/rider.dart';

/// Strefa fizjologicznego oddziaływania hipoksji na wysokość n.p.m.
enum HypoxiaSeverityZone {
  /// Normoksja (<= 1500 m n.p.m.) — brak spadku VO2max i FTP.
  normoxia,

  /// Umiarkowana wysokość (1500 - 2000 m n.p.m.) — początkowy spadek tlenowy.
  moderateAltitude,

  /// Strefa wysokogórska (2000 - 2500 m n.p.m., np. Col du Tourmalet).
  highMountain,

  /// Ekstremalne Alpy / Dolomity (> 2500 m n.p.m., np. Col du Galibier, Stelvio).
  extremeAlpine;

  String get displayName {
    switch (this) {
      case HypoxiaSeverityZone.normoxia:
        return 'Normoksja (<= 1500 m)';
      case HypoxiaSeverityZone.moderateAltitude:
        return 'Średnie góry (1500–2000 m)';
      case HypoxiaSeverityZone.highMountain:
        return 'Wysokie góry (2000–2500 m)';
      case HypoxiaSeverityZone.extremeAlpine:
        return 'Strefa alpejska (> 2500 m)';
    }
  }
}

/// Referencyjna przełęcz wysokogórska (>2000 m n.p.m.) do kalibracji i podglądu hipoksji.
class AlpineHypoxiaPassBenchmark {
  final String name;
  final String mountainRange;
  final double summitAltitudeMeters;

  const AlpineHypoxiaPassBenchmark({
    required this.name,
    required this.mountainRange,
    required this.summitAltitudeMeters,
  });

  static const AlpineHypoxiaPassBenchmark tourmalet = AlpineHypoxiaPassBenchmark(
    name: 'Col du Tourmalet',
    mountainRange: 'Pireneje',
    summitAltitudeMeters: 2115.0,
  );

  static const AlpineHypoxiaPassBenchmark galibier = AlpineHypoxiaPassBenchmark(
    name: 'Col du Galibier',
    mountainRange: 'Alpy',
    summitAltitudeMeters: 2642.0,
  );

  static const AlpineHypoxiaPassBenchmark stelvio = AlpineHypoxiaPassBenchmark(
    name: 'Passo dello Stelvio',
    mountainRange: 'Dolomity / Alpy Ortleskie',
    summitAltitudeMeters: 2758.0,
  );

  static const List<AlpineHypoxiaPassBenchmark> iconicPasses = [
    tourmalet,
    galibier,
    stelvio,
  ];
}

/// Wynik naukowego modelu hipoksji wysokogórskiej dla dostępnego VO2max i FTP.
class HighAltitudeHypoxiaResult {
  /// Wysokość n.p.m. [m].
  final double altitudeMeters;

  /// Czy wysokość przekracza próg hipoksji (1500 m n.p.m.).
  final bool isAboveHypoxiaThreshold;

  /// Czy wysokość znajduje się w strefie wysokogórskiej (> 2000 m n.p.m.).
  final bool isHighMountainZone;

  /// Klasyfikacja strefy hipoksji.
  final HypoxiaSeverityZone severityZone;

  /// Surowy nieliniowy spadek względny wg wzoru
  /// `ΔP = -0.0085 * ((h - 1500) / 100)^1.4` (<= 0.0).
  final double rawDeltaP;

  /// Efektywny spadek względny po uwzględnieniu redukcji o połowę
  /// dla kolarzy po obozie wysokogórskim lub pochodzących z Andów (<= 0.0).
  final double effectiveDeltaP;

  /// Mnożnik dostępnego VO2max oraz FTP (np. 0.892 oznacza -10.8%).
  final double performanceMultiplier;

  /// Czy kolarz posiada adaptację po obozie wysokogórskim.
  final bool hasAltitudeCampAdaptation;

  /// Czy kolarz pochodzi z regionu Andów (np. COL, ECU, BOL, PER).
  final bool isAndeanNative;

  /// Zastosowany współczynnik łagodzenia hipoksji (0.0 brak, 0.5 redukcja o połowę).
  final double acclimatizationMitigationFraction;

  /// Bazowe VO2max na poziomie morza [ml/kg/min].
  final double baseVo2Max;

  /// Dostępne VO2max na danej wysokości [ml/kg/min].
  final double availableVo2Max;

  /// Bazowe FTP na poziomie morza [W].
  final double baseFtpWatts;

  /// Dostępne FTP na danej wysokości [W].
  final double availableFtpWatts;

  /// Gęstość powietrza na danej wysokości [kg/m^3].
  final double airDensityKgM3;

  const HighAltitudeHypoxiaResult({
    required this.altitudeMeters,
    required this.isAboveHypoxiaThreshold,
    required this.isHighMountainZone,
    required this.severityZone,
    required this.rawDeltaP,
    required this.effectiveDeltaP,
    required this.performanceMultiplier,
    required this.hasAltitudeCampAdaptation,
    required this.isAndeanNative,
    required this.acclimatizationMitigationFraction,
    required this.baseVo2Max,
    required this.availableVo2Max,
    required this.baseFtpWatts,
    required this.availableFtpWatts,
    required this.airDensityKgM3,
  });

  /// Procentowy spadek dostępnego VO2max (wartość dodatnia, np. 10.79 dla -10.79%).
  double get vo2MaxLossPercent => (1.0 - performanceMultiplier) * 100.0;

  /// Procentowy spadek dostępnego FTP (wartość dodatnia, np. 10.79 dla -10.79%).
  double get ftpLossPercent => (1.0 - performanceMultiplier) * 100.0;

  /// Bezwzględna utrata VO2max [ml/kg/min].
  double get vo2MaxLossAbsolute => math.max(0.0, baseVo2Max - availableVo2Max);

  /// Bezwzględna utrata mocy FTP [W].
  double get ftpLossWatts => math.max(0.0, baseFtpWatts - availableFtpWatts);
}

/// Naukowy kalkulator hipoksji wysokogórskiej dla przełęczy >2000 m n.p.m.
/// (Col du Galibier, Passo dello Stelvio, Col du Tourmalet).
///
/// Modeluje nieliniowy spadek dostępnego VO2max i mocy progowej FTP powyżej 1500 m n.p.m.
/// zgodnie z zależnością potęgową:
/// `ΔP = -0.0085 * ((h - 1500) / 100)^1.4`
///
/// Dla kolarzy po obozie wysokogórskim lub pochodzących z Andów (`COL`, `ECU`,
/// `BOL`, `PER`, itp.) spadek wydolności jest redukowany o połowę (50%).
class HighAltitudeHypoxiaCalculator {
  HighAltitudeHypoxiaCalculator._();

  /// Wysokość progowa początku hipoksji wysiłkowej [m n.p.m.].
  static const double hypoxiaThresholdMeters = 1500.0;

  /// Próg strefy wysokogórskiej (Galibier, Stelvio, Tourmalet) [m n.p.m.].
  static const double highMountainZoneMeters = 2000.0;

  /// Współczynnik skali wzoru potęgowego hipoksji.
  static const double hypoxiaCoefficient = 0.0085;

  /// Wykładnik nieliniowości spadku tlenowego wraz z wysokością.
  static const double hypoxiaExponent = 1.4;

  /// Krok normalizacji wysokości ponad progiem [m].
  static const double altitudeScaleStepMeters = 100.0;

  /// Maksymalna redukcja straty dla kolarzy po obozie lub z Andów (50%).
  static const double acclimatizedMitigationFraction = 0.5;

  /// Bezpieczna dolna granica mnożnika wydolności na ekstremalnych wysokościach.
  static const double minPerformanceMultiplier = 0.45;

  /// Kody ISO krajów andyjskich o wrodzonej / długotrwałej adaptacji wysokościowej.
  static const Set<String> andeanCountriesIso = {
    'COL', // Kolumbia
    'ECU', // Ekwador
    'BOL', // Boliwia
    'PER', // Peru
  };

  /// Zwraca `true`, jeśli kod kraju ISO odpowiada pochodzeniu z Andów.
  static bool isAndeanCountry(String nationalityIso) {
    final normalized = nationalityIso.trim().toUpperCase();
    return andeanCountriesIso.contains(normalized);
  }

  /// Klasyfikuje wysokość n.p.m. do odpowiedniej strefy hipoksji.
  static HypoxiaSeverityZone classifyZone(double altitudeMeters) {
    if (altitudeMeters <= hypoxiaThresholdMeters) {
      return HypoxiaSeverityZone.normoxia;
    }
    if (altitudeMeters <= highMountainZoneMeters) {
      return HypoxiaSeverityZone.moderateAltitude;
    }
    if (altitudeMeters <= 2500.0) {
      return HypoxiaSeverityZone.highMountain;
    }
    return HypoxiaSeverityZone.extremeAlpine;
  }

  /// Oblicza surową nieliniową zmianę wydolności `ΔP` (<= 0.0) dla wysokości [m n.p.m.]:
  /// `ΔP = -0.0085 * ((h - 1500) / 100)^1.4` dla `h > 1500`, w przeciwnym razie `0.0`.
  static double calculateRawDeltaP(double altitudeMeters) {
    if (!altitudeMeters.isFinite || altitudeMeters <= hypoxiaThresholdMeters) {
      return 0.0;
    }
    final double normalizedSteps =
        (altitudeMeters - hypoxiaThresholdMeters) / altitudeScaleStepMeters;
    return -hypoxiaCoefficient *
        math.pow(normalizedSteps, hypoxiaExponent).toDouble();
  }

  /// Oblicza wpływ hipoksji wysokogórskiej na dostępne VO2max i FTP kolarza.
  ///
  /// - [altitudeMeters]: wysokość n.p.m. [m].
  /// - [baseVo2Max]: bazowe VO2max kolarza na poziomie morza [ml/kg/min].
  /// - [baseFtpWatts]: bazowe FTP kolarza na poziomie morza [W].
  /// - [nationalityIso]: 3-literowy kod ISO narodowości (np. `COL`, `ECU`, `POL`).
  /// - [hasCompletedAltitudeCamp]: czy kolarz odbył obóz wysokogórski.
  /// - [isAndeanNativeOverride]: opcjonalne jawne nadpisanie pochodzenia z Andów.
  /// - [acclimatizationProgress]: częściowy postęp aklimatyzacji `[0.0, 1.0]`
  ///   (ignorowany, jeśli `hasCompletedAltitudeCamp` lub pochodzenie z Andów daje pełne 1.0).
  static HighAltitudeHypoxiaResult calculate({
    required double altitudeMeters,
    required double baseVo2Max,
    required double baseFtpWatts,
    String nationalityIso = '',
    bool hasCompletedAltitudeCamp = false,
    bool? isAndeanNativeOverride,
    double acclimatizationProgress = 0.0,
  }) {
    final double safeAltitude = altitudeMeters.isFinite ? altitudeMeters : 0.0;
    final double safeVo2Max =
        baseVo2Max.isFinite ? math.max(0.0, baseVo2Max) : 0.0;
    final double safeFtpWatts =
        baseFtpWatts.isFinite ? math.max(0.0, baseFtpWatts) : 0.0;

    final bool isAndean =
        isAndeanNativeOverride ?? isAndeanCountry(nationalityIso);
    final double clampedProgress = acclimatizationProgress.isFinite
        ? acclimatizationProgress.clamp(0.0, 1.0).toDouble()
        : 0.0;

    final double mitigationFraction = (hasCompletedAltitudeCamp || isAndean)
        ? acclimatizedMitigationFraction
        : acclimatizedMitigationFraction * clampedProgress;

    final double rawDeltaP = calculateRawDeltaP(safeAltitude);
    final double effectiveDeltaP = rawDeltaP * (1.0 - mitigationFraction);
    final double multiplier = (1.0 + effectiveDeltaP)
        .clamp(minPerformanceMultiplier, 1.0)
        .toDouble();

    final double airDensity =
        PhysicsConstants.getAirDensityAtAltitude(safeAltitude);

    return HighAltitudeHypoxiaResult(
      altitudeMeters: safeAltitude,
      isAboveHypoxiaThreshold: safeAltitude > hypoxiaThresholdMeters,
      isHighMountainZone: safeAltitude > highMountainZoneMeters,
      severityZone: classifyZone(safeAltitude),
      rawDeltaP: rawDeltaP,
      effectiveDeltaP: effectiveDeltaP,
      performanceMultiplier: multiplier,
      hasAltitudeCampAdaptation: hasCompletedAltitudeCamp,
      isAndeanNative: isAndean,
      acclimatizationMitigationFraction: mitigationFraction,
      baseVo2Max: safeVo2Max,
      availableVo2Max: safeVo2Max * multiplier,
      baseFtpWatts: safeFtpWatts,
      availableFtpWatts: safeFtpWatts * multiplier,
      airDensityKgM3: airDensity,
    );
  }

  /// Wygodna metoda obliczająca hipoksję bezpośrednio dla modelu [Rider].
  static HighAltitudeHypoxiaResult calculateForRider({
    required Rider rider,
    required double altitudeMeters,
    bool hasCompletedAltitudeCamp = false,
    double acclimatizationProgress = 0.0,
  }) {
    return calculate(
      altitudeMeters: altitudeMeters,
      baseVo2Max: rider.physiology.vo2Max,
      baseFtpWatts: rider.physiology.ftpWatts.toDouble(),
      nationalityIso: rider.nationalityIso,
      hasCompletedAltitudeCamp: hasCompletedAltitudeCamp,
      acclimatizationProgress: acclimatizationProgress,
    );
  }
}
