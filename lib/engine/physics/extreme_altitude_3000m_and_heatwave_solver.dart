// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';

/// Strefa wysokościowa dla ekstremalnych podjazdów (2500–3500 m n.p.m.).
enum ExtremeAltitudeZone {
  seaLevelOrLow(
    id: 'sea_level_or_low',
    labelPl: 'Nizina (< 1500 m)',
    labelEn: 'Lowland (< 1500 m)',
    accentColor: AppColors.statusSuccess,
  ),
  moderateMountain(
    id: 'moderate_mountain',
    labelPl: 'Średnie góry (1500–2500 m)',
    labelEn: 'Moderate Mountain (1500–2500 m)',
    accentColor: AppColors.accentBlue,
  ),
  highAndesZone(
    id: 'high_andes_zone',
    labelPl: 'Wysokie Andy (2500–2800 m)',
    labelEn: 'High Andes (2500–2800 m)',
    accentColor: AppColors.amberWarning,
  ),
  extremeHypoxiaAbove2800m(
    id: 'extreme_hypoxia_2800m',
    labelPl: 'Ekstremalna hipoksja (> 2800 m)',
    labelEn: 'Extreme Hypoxia (> 2800 m)',
    accentColor: AppColors.crimsonAlert,
  );

  final String id;
  final String labelPl;
  final String labelEn;
  final Color accentColor;

  const ExtremeAltitudeZone({
    required this.id,
    required this.labelPl,
    required this.labelEn,
    required this.accentColor,
  });
}

/// Strefa obciążenia falą upałów i nagrzania nawierzchni asfaltowej.
enum HeatwaveSeverityZone {
  temperate(
    id: 'temperate',
    labelPl: 'Umiarkowana (< 30°C)',
    labelEn: 'Temperate (< 30°C)',
    accentColor: AppColors.statusSuccess,
  ),
  warm(
    id: 'warm',
    labelPl: 'Ciepło (30–38°C)',
    labelEn: 'Warm (30–38°C)',
    accentColor: AppColors.accentBlue,
  ),
  heatwaveAlert(
    id: 'heatwave_alert',
    labelPl: 'Fala upałów (38–40°C)',
    labelEn: 'Heatwave Alert (38–40°C)',
    accentColor: AppColors.amberWarning,
  ),
  australianExtremeHeat(
    id: 'australian_extreme_heat',
    labelPl: 'Australijski skwar (> 40°C)',
    labelEn: 'Australian Extreme Heat (> 40°C)',
    accentColor: AppColors.crimsonAlert,
  );

  final String id;
  final String labelPl;
  final String labelEn;
  final Color accentColor;

  const HeatwaveSeverityZone({
    required this.id,
    required this.labelPl,
    required this.labelEn,
    required this.accentColor,
  });
}

/// Gotowe scenariusze referencyjne dla ekstremalnych wysokości i fal upałów.
enum ExtremeClimateScenarioPreset {
  temperateBaseline(
    id: 'temperate_baseline',
    titlePl: 'Poziom morza (Referencja)',
    subtitlePl: '50 m n.p.m. • 20°C • Standardowy asfalt',
    altitudeMeters: 50.0,
    ambientTempCelsius: 20.0,
    solarRadiationFactor: 0.55,
    windSpeedMs: 2.5,
  ),
  altoDelColorado3000m(
    id: 'alto_del_colorado_3000m',
    titlePl: 'Alto del Colorado (3050 m)',
    subtitlePl: 'Vuelta a San Juan • Ekstremalna hipoksja PaO2',
    altitudeMeters: 3050.0,
    ambientTempCelsius: 14.0,
    solarRadiationFactor: 0.90,
    windSpeedMs: 4.5,
  ),
  tourColombia3300m(
    id: 'tour_colombia_3300m',
    titlePl: 'Alto de Letras / Andy (3300 m)',
    subtitlePl: '3300 m n.p.m. • Krytyczne wydłużenie tau W\'',
    altitudeMeters: 3300.0,
    ambientTempCelsius: 11.0,
    solarRadiationFactor: 0.85,
    windSpeedMs: 3.8,
  ),
  australianHeatwave42c(
    id: 'australian_heatwave_42c',
    titlePl: 'Willunga Hill (42°C Upał)',
    subtitlePl: 'Tour Down Under • Asfalt 58°C • +8% Crr • 2x Bidony',
    altitudeMeters: 160.0,
    ambientTempCelsius: 42.0,
    solarRadiationFactor: 1.0,
    windSpeedMs: 2.0,
  ),
  combinedSanJuanDesertClimb(
    id: 'combined_san_juan_desert_climb',
    titlePl: 'Pustynny podjazd (2900 m / 39°C)',
    subtitlePl: 'Podwójny stres: hipoksja + fala upałów',
    altitudeMeters: 2900.0,
    ambientTempCelsius: 39.0,
    solarRadiationFactor: 0.98,
    windSpeedMs: 2.2,
  );

  final String id;
  final String titlePl;
  final String subtitlePl;
  final double altitudeMeters;
  final double ambientTempCelsius;
  final double solarRadiationFactor;
  final double windSpeedMs;

  const ExtremeClimateScenarioPreset({
    required this.id,
    required this.titlePl,
    required this.subtitlePl,
    required this.altitudeMeters,
    required this.ambientTempCelsius,
    required this.solarRadiationFactor,
    required this.windSpeedMs,
  });
}

/// Dane wejściowe dla solvera ekstremalnych wysokości (2500–3500 m) i fal upałów (>38°C).
class ExtremeAltitudeAndHeatwaveInput {
  /// Wysokość n.p.m. [m].
  final double altitudeMeters;

  /// Temperatura powietrza w cieniu [°C].
  final double ambientTempCelsius;

  /// Natężenie nasłonecznienia (0.0 pełne zachmurzenie / noc, 1.0 pełne słońce).
  final double solarRadiationFactor;

  /// Prędkość wiatru chłodzącego nawierzchnię [m/s].
  final double windSpeedMs;

  /// Bazowy współczynnik oporu toczenia opony (Crr) w 20°C.
  final double baseCrr;

  /// Bazowa stała czasowa regeneracji W' na poziomie morza [s] (typowo 280–360 s).
  final double baseTauWPrimeSeconds;

  /// Bazowe zapotrzebowanie na płyny w warunkach umiarkowanych [L/h].
  final double baseHydrationLitersPerHour;

  /// Moc generowana podczas regeneracji poniżej progu CP [W].
  final double recoveryPowerWatts;

  /// Próg krytyczny kolarza (CP / FTP) na poziomie morza [W].
  final double criticalPowerWatts;

  /// Maksymalna pojemność beztlenowa W' [J].
  final double maxWPrimeJoules;

  /// Zużycie W' pojedynczego gwałtownego ataku [J].
  final double attackWPrimeCostJoules;

  /// Czy kolarz ukończył obóz aklimatyzacyjny wysokościowy (>21 dni).
  final bool hasAltitudeAcclimatization;

  /// Czy kolarz jest rodowitym góralem z Andów (COL, ECU, BOL, PER).
  final bool isAndeanNative;

  /// Czy kolarz przeszedł pełną aklimatyzację cieplną (sauna / obóz w upale).
  final bool hasHeatAcclimatization;

  const ExtremeAltitudeAndHeatwaveInput({
    required this.altitudeMeters,
    required this.ambientTempCelsius,
    this.solarRadiationFactor = 0.90,
    this.windSpeedMs = 2.5,
    this.baseCrr = PhysicsConstants.crrSmoothAsphalt,
    this.baseTauWPrimeSeconds = 300.0,
    this.baseHydrationLitersPerHour = 0.85,
    this.recoveryPowerWatts = 220.0,
    this.criticalPowerWatts = 380.0,
    this.maxWPrimeJoules = 22000.0,
    this.attackWPrimeCostJoules = 6500.0,
    this.hasAltitudeAcclimatization = false,
    this.isAndeanNative = false,
    this.hasHeatAcclimatization = false,
  });

  ExtremeAltitudeAndHeatwaveInput copyWith({
    double? altitudeMeters,
    double? ambientTempCelsius,
    double? solarRadiationFactor,
    double? windSpeedMs,
    double? baseCrr,
    double? baseTauWPrimeSeconds,
    double? baseHydrationLitersPerHour,
    double? recoveryPowerWatts,
    double? criticalPowerWatts,
    double? maxWPrimeJoules,
    double? attackWPrimeCostJoules,
    bool? hasAltitudeAcclimatization,
    bool? isAndeanNative,
    bool? hasHeatAcclimatization,
  }) {
    return ExtremeAltitudeAndHeatwaveInput(
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      ambientTempCelsius: ambientTempCelsius ?? this.ambientTempCelsius,
      solarRadiationFactor: solarRadiationFactor ?? this.solarRadiationFactor,
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      baseCrr: baseCrr ?? this.baseCrr,
      baseTauWPrimeSeconds: baseTauWPrimeSeconds ?? this.baseTauWPrimeSeconds,
      baseHydrationLitersPerHour:
          baseHydrationLitersPerHour ?? this.baseHydrationLitersPerHour,
      recoveryPowerWatts: recoveryPowerWatts ?? this.recoveryPowerWatts,
      criticalPowerWatts: criticalPowerWatts ?? this.criticalPowerWatts,
      maxWPrimeJoules: maxWPrimeJoules ?? this.maxWPrimeJoules,
      attackWPrimeCostJoules:
          attackWPrimeCostJoules ?? this.attackWPrimeCostJoules,
      hasAltitudeAcclimatization:
          hasAltitudeAcclimatization ?? this.hasAltitudeAcclimatization,
      isAndeanNative: isAndeanNative ?? this.isAndeanNative,
      hasHeatAcclimatization:
          hasHeatAcclimatization ?? this.hasHeatAcclimatization,
    );
  }
}

/// Próbka krzywej regeneracji W' po gwałtownym ataku (poziom morza vs wysokość).
class WPrimeRecoveryCurvePoint {
  /// Czas od zakończenia ataku [s].
  final double elapsedSeconds;

  /// Poziom naładowania W' na poziomie morza [0.0–1.0].
  final double seaLevelRatio;

  /// Poziom naładowania W' na docelowej wysokości [0.0–1.0].
  final double altitudeRatio;

  const WPrimeRecoveryCurvePoint({
    required this.elapsedSeconds,
    required this.seaLevelRatio,
    required this.altitudeRatio,
  });
}

/// Wynik obliczeń solvera fizjologii ekstremalnych wysokości i fal upałów.
class ExtremeAltitudeAndHeatwaveResult {
  /// Wysokość n.p.m. [m].
  final double altitudeMeters;

  /// Strefa wysokościowa.
  final ExtremeAltitudeZone altitudeZone;

  /// Ciśnienie atmosferyczne [hPa].
  final double barometricPressureHpa;

  /// Ciśnienie parcjalne tlenu we wdychanym powietrzu PiO2 [mmHg].
  final double inspiredPio2MmHg;

  /// Szacowane ciśnienie parcjalne tlenu we krwi tętniczej PaO2 [mmHg].
  final double arterialPao2MmHg;

  /// Szacowana saturacja krwi tętniczej SpO2 [%].
  final double arterialSpo2Percent;

  /// Gęstość powietrza na danej wysokości [kg/m³].
  final double airDensityKgM3;

  /// Mnożnik dostępnego FTP/CP na wysokości (np. 0.84 = -16%).
  final double aerobicCpMultiplier;

  /// Efektywna wartość CP/FTP na danej wysokości [W].
  final double effectiveCriticalPowerWatts;

  /// Mnożnik stałej czasowej tau W' (powyżej 2800 m >= 1.45, czyli +45%).
  final double tauWPrimeMultiplier;

  /// Efektywna stała czasowa regeneracji tau W' [s].
  final double effectiveTauWPrimeSeconds;

  /// Procentowe wydłużenie czasu regeneracji tau W' [%].
  final double tauWPrimePenaltyPercent;

  /// Czas potrzebny na odzyskanie 80% kosztu ataku na poziomie morza [s].
  final double seaLevelAttackRecoverySeconds;

  /// Czas potrzebny na odzyskanie 80% kosztu ataku na docelowej wysokości [s].
  final double altitudeAttackRecoverySeconds;

  /// Stosunek czasu regeneracji po ataku (wysokość / poziom morza), np. ~2.0x na Alto del Colorado.
  final double attackRecoveryTimeRatio;

  /// Temperatura powietrza w cieniu [°C].
  final double ambientTempCelsius;

  /// Temperatura nawierzchni asfaltowej [°C] (w upale >40°C osiąga ~58°C).
  final double asphaltSurfaceTempCelsius;

  /// Strefa obciążenia falą upałów.
  final HeatwaveSeverityZone heatwaveZone;

  /// Mnożnik oporu toczenia Crr (w upale >40°C i asfalcie 58°C wynosi +8% -> 1.08).
  final double crrMultiplier;

  /// Efektywny współczynnik Crr na nagrzanej nawierzchni.
  final double effectiveCrr;

  /// Procentowy wzrost oporu toczenia Crr [%].
  final double crrIncreasePercent;

  /// Mnożnik zapotrzebowania na nawadnianie (w upale >40°C = 2.0x).
  final double hydrationMultiplier;

  /// Wymagane tempo nawadniania [L/h].
  final double requiredHydrationLitersPerHour;

  /// Liczba standardowych bidonów 500 ml na godzinę.
  final double requiredBidonsPerHour;

  /// Dodatkowy dryf temperatury głębokiej ciała [°C/h].
  final double coreTempDriftCelsiusPerHour;

  /// Czy aktywowany jest protokół podwójnego nawadniania.
  final bool requiresDoubleHydration;

  /// Czy przekroczono próg ekstremalnej hipoksji W' (>2800 m n.p.m.).
  final bool isExtremeHypoxiaWPrimeZone;

  /// Krzywa porównawcza regeneracji W' po pojedynczym ataku.
  final List<WPrimeRecoveryCurvePoint> recoveryCurve;

  const ExtremeAltitudeAndHeatwaveResult({
    required this.altitudeMeters,
    required this.altitudeZone,
    required this.barometricPressureHpa,
    required this.inspiredPio2MmHg,
    required this.arterialPao2MmHg,
    required this.arterialSpo2Percent,
    required this.airDensityKgM3,
    required this.aerobicCpMultiplier,
    required this.effectiveCriticalPowerWatts,
    required this.tauWPrimeMultiplier,
    required this.effectiveTauWPrimeSeconds,
    required this.tauWPrimePenaltyPercent,
    required this.seaLevelAttackRecoverySeconds,
    required this.altitudeAttackRecoverySeconds,
    required this.attackRecoveryTimeRatio,
    required this.ambientTempCelsius,
    required this.asphaltSurfaceTempCelsius,
    required this.heatwaveZone,
    required this.crrMultiplier,
    required this.effectiveCrr,
    required this.crrIncreasePercent,
    required this.hydrationMultiplier,
    required this.requiredHydrationLitersPerHour,
    required this.requiredBidonsPerHour,
    required this.coreTempDriftCelsiusPerHour,
    required this.requiresDoubleHydration,
    required this.isExtremeHypoxiaWPrimeZone,
    required this.recoveryCurve,
  });
}

/// Wyspecjalizowany solver fizjologii ekstremalnych wysokości (2500–3500 m n.p.m.)
/// oraz fal upałów (>38°C / australijski skwar >40°C).
///
/// Modeluje dwa kluczowe zjawiska wyścigowe:
/// 1. Powyżej 2800 m n.p.m. spadek ciśnienia parcjalnego tlenu PaO2 wywołuje
///    wykładnicze wydłużenie stałej czasowej regeneracji W' (tau_W' rośnie o +45%
///    i więcej), przez co każdy atak na Alto del Colorado kosztuje ~2x więcej czasu
///    na odbudowę rezerwy beztlenowej.
/// 2. W australijskim upale >40°C asfalt nagrzewa się do ~58°C, zmiękczając
///    mieszankę i podnosząc opór toczenia Crr o +8%, przy jednoczesnym wymogu
///    podwójnego nawadniania (2.0x bidony/elektrolity).
class ExtremeAltitude3000mAndHeatwaveSolver {
  const ExtremeAltitude3000mAndHeatwaveSolver._();

  /// Próg wysokościowy ekstremalnej hipoksji W' [m n.p.m.].
  static const double extremeHypoxiaAltitudeThresholdMeters = 2800.0;

  /// Próg temperatury fali upałów [°C].
  static const double heatwaveAmbientThresholdCelsius = 38.0;

  /// Próg australijskiego skwaru [°C].
  static const double australianHeatwaveThresholdCelsius = 40.0;

  /// Referencyjna temperatura rozgrzanego asfaltu w australijskim upale [°C].
  static const double peakAustralianAsphaltTempCelsius = 58.0;

  /// Bazowy wzrost Crr w australijskim skwarze (>40°C / asfalt 58°C): +8%.
  static const double australianAsphaltCrrPenaltyFraction = 0.08;

  /// Bazowy wzrost stałej czasowej tau_W' powyżej 2800 m n.p.m.: +45%.
  static const double baseExtremeAltitudeTauPenalty = 0.45;

  /// Ciśnienie atmosferyczne na poziomie morza [hPa].
  static const double seaLevelPressureHpa = 1013.25;

  /// Przelicznik hPa na mmHg.
  static const double hpaToMmHg = 0.750062;

  /// Ciśnienie pary wodnej w pęcherzykach płucnych [mmHg].
  static const double alveolarWaterVaporMmHg = 47.0;

  /// Oblicza pełny stan fizjologiczny i mechaniczny dla zadanej wysokości i upału.
  static ExtremeAltitudeAndHeatwaveResult solve(
    ExtremeAltitudeAndHeatwaveInput input,
  ) {
    final double altitude = input.altitudeMeters.clamp(0.0, 5500.0);
    final double ambientTemp = input.ambientTempCelsius.clamp(-10.0, 52.0);
    final double solar = input.solarRadiationFactor.clamp(0.0, 1.0);
    final double wind = math.max(0.0, input.windSpeedMs);
    final double baseCrr = math.max(0.001, input.baseCrr);
    final double baseTau = math.max(30.0, input.baseTauWPrimeSeconds);
    final double baseHydration = math.max(0.2, input.baseHydrationLitersPerHour);
    final double baseCp = math.max(120.0, input.criticalPowerWatts);
    final double recoveryPower = input.recoveryPowerWatts.clamp(0.0, baseCp * 1.2);
    final double maxWPrime = math.max(2000.0, input.maxWPrimeJoules);
    final double attackCost = input.attackWPrimeCostJoules.clamp(500.0, maxWPrime);

    // 1. Atmosfera barometryczna i ciśnienie parcjalne tlenu PaO2
    final double pressureHpa = computeBarometricPressureHpa(altitude);
    final double pressureMmHg = pressureHpa * hpaToMmHg;
    final double pio2 =
        math.max(0.0, (pressureMmHg - alveolarWaterVaporMmHg) * 0.2093);
    final double pao2 = computeArterialPao2MmHg(altitude, pio2);
    final double spo2 = computeArterialSpo2Percent(pao2);
    final double airDensity = PhysicsConstants.getAirDensityAtAltitude(altitude);

    // 2. Spadek tlenowego progu CP/FTP na wysokości
    final double mitigation = _computeAltitudeMitigation(
      hasAcclimatization: input.hasAltitudeAcclimatization,
      isAndeanNative: input.isAndeanNative,
    );
    final double rawCpLoss = _computeRawAerobicLossFraction(altitude);
    final double effectiveCpLoss = (rawCpLoss * (1.0 - mitigation)).clamp(0.0, 0.45);
    final double cpMultiplier = 1.0 - effectiveCpLoss;
    final double effectiveCp = baseCp * cpMultiplier;

    // 3. Wykładnicze wydłużenie tau_W' powyżej 2800 m n.p.m. (+45% i więcej)
    final double tauMultiplier = computeTauWPrimeMultiplier(
      altitudeMeters: altitude,
      arterialPao2MmHg: pao2,
      acclimatizationMitigation: mitigation,
    );
    final double effectiveTau = baseTau * tauMultiplier;
    final double tauPenaltyPercent = (tauMultiplier - 1.0) * 100.0;

    // 4. Czas regeneracji po gwałtownym ataku (poziom morza vs wysokość)
    // Uwzględnia zarówno wydłużone tau_W', jak i zwężoną rezerwę mocy (CP_alt - P_rec)
    final double seaLevelDcp = math.max(25.0, baseCp - recoveryPower);
    final double altDcp = math.max(15.0, effectiveCp - recoveryPower);

    // Skiba W'bal recovery factor: czas do odzyskania 80% kosztu ataku
    const double targetRecoveryFraction = 0.80;
    final double lnFactor = -math.log(1.0 - targetRecoveryFraction); // ~1.6094

    final double seaLevelTauAdjusted =
        baseTau * (120.0 / seaLevelDcp).clamp(0.65, 1.85);
    final double altitudeTauAdjusted =
        effectiveTau * (120.0 / altDcp).clamp(0.65, 2.40);

    final double seaLevelRecSeconds = seaLevelTauAdjusted * lnFactor;
    final double altitudeRecSeconds = altitudeTauAdjusted * lnFactor;
    final double recoveryRatio =
        (altitudeRecSeconds / math.max(1.0, seaLevelRecSeconds)).clamp(1.0, 4.5);

    // Krzywa regeneracji W' (0..900 s co 30 s)
    final List<WPrimeRecoveryCurvePoint> curve = _buildRecoveryCurve(
      maxWPrime: maxWPrime,
      attackCost: attackCost,
      seaLevelTau: seaLevelTauAdjusted,
      altitudeTau: altitudeTauAdjusted,
    );

    // 5. Termika asfaltu w upale (>38°C / >40°C -> 58°C asfaltu) i wzrost Crr (+8%)
    final double asphaltTemp = computeAsphaltSurfaceTempCelsius(
      ambientTempCelsius: ambientTemp,
      solarRadiationFactor: solar,
      windSpeedMs: wind,
    );
    final double crrMultiplier = computeAsphaltHeatCrrMultiplier(
      ambientTempCelsius: ambientTemp,
      asphaltTempCelsius: asphaltTemp,
    );
    final double effectiveCrr = baseCrr * crrMultiplier;
    final double crrIncreasePercent = (crrMultiplier - 1.0) * 100.0;

    // 6. Podwójne nawadnianie w upale >40°C
    final double hydrationMultiplier = computeHydrationMultiplier(
      ambientTempCelsius: ambientTemp,
      asphaltTempCelsius: asphaltTemp,
      hasHeatAcclimatization: input.hasHeatAcclimatization,
    );
    final double requiredHydration = baseHydration * hydrationMultiplier;
    final double bidonsPerHour = requiredHydration / 0.5;
    final double coreDrift = _computeCoreTempDriftPerHour(
      ambientTempCelsius: ambientTemp,
      asphaltTempCelsius: asphaltTemp,
      hasHeatAcclimatization: input.hasHeatAcclimatization,
    );

    return ExtremeAltitudeAndHeatwaveResult(
      altitudeMeters: altitude,
      altitudeZone: classifyAltitudeZone(altitude),
      barometricPressureHpa: pressureHpa,
      inspiredPio2MmHg: pio2,
      arterialPao2MmHg: pao2,
      arterialSpo2Percent: spo2,
      airDensityKgM3: airDensity,
      aerobicCpMultiplier: cpMultiplier,
      effectiveCriticalPowerWatts: effectiveCp,
      tauWPrimeMultiplier: tauMultiplier,
      effectiveTauWPrimeSeconds: effectiveTau,
      tauWPrimePenaltyPercent: tauPenaltyPercent,
      seaLevelAttackRecoverySeconds: seaLevelRecSeconds,
      altitudeAttackRecoverySeconds: altitudeRecSeconds,
      attackRecoveryTimeRatio: recoveryRatio,
      ambientTempCelsius: ambientTemp,
      asphaltSurfaceTempCelsius: asphaltTemp,
      heatwaveZone: classifyHeatwaveZone(ambientTemp),
      crrMultiplier: crrMultiplier,
      effectiveCrr: effectiveCrr,
      crrIncreasePercent: crrIncreasePercent,
      hydrationMultiplier: hydrationMultiplier,
      requiredHydrationLitersPerHour: requiredHydration,
      requiredBidonsPerHour: bidonsPerHour,
      coreTempDriftCelsiusPerHour: coreDrift,
      requiresDoubleHydration: hydrationMultiplier >= 1.95,
      isExtremeHypoxiaWPrimeZone:
          altitude >= extremeHypoxiaAltitudeThresholdMeters,
      recoveryCurve: curve,
    );
  }

  /// Klasyfikuje strefę wysokościową.
  static ExtremeAltitudeZone classifyAltitudeZone(double altitudeMeters) {
    if (altitudeMeters >= extremeHypoxiaAltitudeThresholdMeters) {
      return ExtremeAltitudeZone.extremeHypoxiaAbove2800m;
    }
    if (altitudeMeters >= 2500.0) {
      return ExtremeAltitudeZone.highAndesZone;
    }
    if (altitudeMeters >= 1500.0) {
      return ExtremeAltitudeZone.moderateMountain;
    }
    return ExtremeAltitudeZone.seaLevelOrLow;
  }

  /// Klasyfikuje strefę fali upałów.
  static HeatwaveSeverityZone classifyHeatwaveZone(double ambientTempCelsius) {
    if (ambientTempCelsius > australianHeatwaveThresholdCelsius) {
      return HeatwaveSeverityZone.australianExtremeHeat;
    }
    if (ambientTempCelsius >= heatwaveAmbientThresholdCelsius) {
      return HeatwaveSeverityZone.heatwaveAlert;
    }
    if (ambientTempCelsius >= 30.0) {
      return HeatwaveSeverityZone.warm;
    }
    return HeatwaveSeverityZone.temperate;
  }

  /// Oblicza ciśnienie barometryczne [hPa] wzorem barometrycznym ISA.
  static double computeBarometricPressureHpa(double altitudeMeters) {
    final double h = altitudeMeters.clamp(0.0, 9000.0);
    return seaLevelPressureHpa * math.pow(1.0 - 2.25577e-5 * h, 5.25588);
  }

  /// Szacuje tętnicze ciśnienie parcjalne tlenu PaO2 [mmHg] na podstawie wysokości i PiO2.
  static double computeArterialPao2MmHg(double altitudeMeters, double pio2MmHg) {
    if (altitudeMeters <= 0.0) return 98.0;
    // Fizjologiczny spadek PaO2 z wysokości (ok. 98 mmHg @ 0m -> ~54 mmHg @ 3000m)
    final double rawPao2 =
        98.0 * math.exp(-altitudeMeters / 5050.0) + (pio2MmHg - 149.0) * 0.06;
    return rawPao2.clamp(35.0, 100.0);
  }

  /// Szacuje saturację krwi tętniczej SpO2 [%] na krzywej dysocjacji oksyhemoglobiny.
  static double computeArterialSpo2Percent(double pao2MmHg) {
    // Równanie Severinghausa (uproszczone)
    final double p = pao2MmHg.clamp(20.0, 120.0);
    final double p3 = math.pow(p, 3).toDouble();
    final double spo2 = 100.0 * p3 / (p3 + 23400.0 * p + 150.0);
    return spo2.clamp(60.0, 99.5);
  }

  /// Oblicza mnożnik stałej czasowej tau_W'.
  ///
  /// Poniżej 2500 m wpływ jest łagodny; powyżej 2800 m n.p.m. spadek PaO2 powoduje
  /// wykładniczy wzrost tau_W' o co najmniej +45% (1.45x) na 2800 m i rosnący do ~1.82x na 3500 m.
  static double computeTauWPrimeMultiplier({
    required double altitudeMeters,
    required double arterialPao2MmHg,
    double acclimatizationMitigation = 0.0,
  }) {
    if (altitudeMeters <= 1500.0) {
      return 1.0;
    }

    double rawPenalty = 0.0;
    if (altitudeMeters < 2500.0) {
      // Łagodne narastanie między 1500 a 2500 m (0% -> 18%)
      final double t = (altitudeMeters - 1500.0) / 1000.0;
      rawPenalty = 0.18 * math.pow(t, 1.35);
    } else if (altitudeMeters < extremeHypoxiaAltitudeThresholdMeters) {
      // Przejście do progu 2800 m (18% -> 45%)
      final double t = (altitudeMeters - 2500.0) / 300.0;
      rawPenalty = 0.18 + (baseExtremeAltitudeTauPenalty - 0.18) * math.pow(t, 1.25);
    } else {
      // Powyżej 2800 m: minimum +45% oraz wykładniczy wzrost wraz ze spadkiem PaO2
      final double excessMeters = altitudeMeters - extremeHypoxiaAltitudeThresholdMeters;
      final double pao2DeficitRatio = math.max(0.0, (58.0 - arterialPao2MmHg) / 18.0);
      rawPenalty = baseExtremeAltitudeTauPenalty +
          0.37 * (1.0 - math.exp(-excessMeters / 520.0)) +
          0.14 * math.pow(pao2DeficitRatio, 1.4);
    }

    // Aklimatyzacja łagodzi nadwyżkę powyżej bazowego progu, ale nie znosi fizyki PaO2
    final double mitigatedPenalty = rawPenalty * (1.0 - acclimatizationMitigation * 0.35);
    final double minAt2800 =
        altitudeMeters >= extremeHypoxiaAltitudeThresholdMeters
            ? baseExtremeAltitudeTauPenalty
            : 0.0;
    return 1.0 + math.max(minAt2800, mitigatedPenalty);
  }

  /// Oblicza temperaturę nawierzchni asfaltowej [°C].
  ///
  /// W australijskim upale (>40°C, pełne nasłonecznienie) asfalt nagrzewa się do ~58°C.
  static double computeAsphaltSurfaceTempCelsius({
    required double ambientTempCelsius,
    double solarRadiationFactor = 0.90,
    double windSpeedMs = 2.5,
  }) {
    final double solar = solarRadiationFactor.clamp(0.0, 1.0);
    final double windCooling = (windSpeedMs.clamp(0.0, 15.0) * 0.45).clamp(0.0, 5.0);
    // Przy 40°C i pełnym słońcu (+18.9°C - ~0.9°C wiatr) => ~58.0°C
    final double solarGain = 18.9 * solar;
    final double asphaltTemp = ambientTempCelsius + solarGain - windCooling;
    return math.max(ambientTempCelsius, asphaltTemp).clamp(-10.0, 72.0);
  }

  /// Oblicza mnożnik oporu toczenia opon Crr od rozgrzanego asfaltu.
  ///
  /// Gdy temperatura otoczenia przekracza 40°C (lub asfalt osiąga >=58°C),
  /// mięknący bitum i guma podnoszą Crr o +8% (1.08x).
  static double computeAsphaltHeatCrrMultiplier({
    required double ambientTempCelsius,
    required double asphaltTempCelsius,
  }) {
    if (ambientTempCelsius <= 25.0 && asphaltTempCelsius <= 35.0) {
      return 1.0;
    }

    if (ambientTempCelsius > australianHeatwaveThresholdCelsius ||
        asphaltTempCelsius >= peakAustralianAsphaltTempCelsius) {
      final double extraHeat = math.max(
        0.0,
        asphaltTempCelsius - peakAustralianAsphaltTempCelsius,
      );
      return 1.0 + australianAsphaltCrrPenaltyFraction + (extraHeat * 0.0025).clamp(0.0, 0.03);
    }

    // Płynne narastanie między 35°C a 58°C asfaltu (0% -> +8%)
    final double ratio =
        ((asphaltTempCelsius - 35.0) / (peakAustralianAsphaltTempCelsius - 35.0))
            .clamp(0.0, 1.0);
    return 1.0 + australianAsphaltCrrPenaltyFraction * math.pow(ratio, 1.35);
  }

  /// Oblicza mnożnik wymaganego nawadniania.
  ///
  /// W upale >40°C wymagane jest podwójne nawadnianie (2.0x).
  static double computeHydrationMultiplier({
    required double ambientTempCelsius,
    required double asphaltTempCelsius,
    bool hasHeatAcclimatization = false,
  }) {
    if (ambientTempCelsius <= 22.0) {
      return 1.0;
    }

    if (ambientTempCelsius > australianHeatwaveThresholdCelsius) {
      // Australijski upał >40°C: pełne 2.0x nawadnianie (aklimatyzacja zmniejsza potliwość
      // tylko marginalnie przy tak ekstremalnej temperaturze)
      final double extra = math.max(0.0, ambientTempCelsius - 40.0) * 0.04;
      final double baseDouble = 2.0 + extra.clamp(0.0, 0.25);
      return hasHeatAcclimatization ? math.max(2.0, baseDouble - 0.05) : baseDouble;
    }

    // Płynne narastanie od 22°C (1.0x) -> 38°C (1.72x) -> 40°C (1.96x)
    final double ratio = ((ambientTempCelsius - 22.0) / 18.0).clamp(0.0, 1.0);
    final double radiantBonus =
        asphaltTempCelsius >= 50.0 ? (asphaltTempCelsius - 50.0) * 0.01 : 0.0;
    final double mult = 1.0 + 0.96 * math.pow(ratio, 1.2) + radiantBonus;
    return mult.clamp(1.0, 2.0);
  }

  static double _computeAltitudeMitigation({
    required bool hasAcclimatization,
    required bool isAndeanNative,
  }) {
    if (isAndeanNative) return 0.50;
    if (hasAcclimatization) return 0.35;
    return 0.0;
  }

  static double _computeRawAerobicLossFraction(double altitudeMeters) {
    if (altitudeMeters <= 1500.0) return 0.0;
    return 0.0085 * math.pow((altitudeMeters - 1500.0) / 100.0, 1.4);
  }

  static double _computeCoreTempDriftPerHour({
    required double ambientTempCelsius,
    required double asphaltTempCelsius,
    required bool hasHeatAcclimatization,
  }) {
    if (ambientTempCelsius <= 28.0) return 0.15;
    final double excess = (ambientTempCelsius - 28.0) * 0.075 +
        math.max(0.0, asphaltTempCelsius - 45.0) * 0.025;
    final double mitigation = hasHeatAcclimatization ? 0.78 : 1.0;
    return (0.15 + excess * mitigation).clamp(0.15, 2.2);
  }

  static List<WPrimeRecoveryCurvePoint> _buildRecoveryCurve({
    required double maxWPrime,
    required double attackCost,
    required double seaLevelTau,
    required double altitudeTau,
  }) {
    final double depletedFraction = (attackCost / maxWPrime).clamp(0.05, 0.95);
    final List<WPrimeRecoveryCurvePoint> points = [];
    for (int t = 0; t <= 900; t += 30) {
      final double elapsed = t.toDouble();
      final double seaLevel =
          1.0 - depletedFraction * math.exp(-elapsed / seaLevelTau);
      final double altitude =
          1.0 - depletedFraction * math.exp(-elapsed / altitudeTau);
      points.add(
        WPrimeRecoveryCurvePoint(
          elapsedSeconds: elapsed,
          seaLevelRatio: seaLevel.clamp(0.0, 1.0),
          altitudeRatio: altitude.clamp(0.0, 1.0),
        ),
      );
    }
    return points;
  }
}

/// Wykres porównawczy regeneracji W' na poziomie morza vs ekstremalna wysokość.
class ExtremeAltitudeRecoveryCurvePainter extends CustomPainter {
  final List<WPrimeRecoveryCurvePoint> curve;
  final Color altitudeColor;

  const ExtremeAltitudeRecoveryCurvePainter({
    required this.curve,
    required this.altitudeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (curve.isEmpty || size.width <= 0 || size.height <= 0) return;

    const double padLeft = 36.0;
    const double padRight = 12.0;
    const double padTop = 12.0;
    const double padBottom = 22.0;

    final double chartW = math.max(10.0, size.width - padLeft - padRight);
    final double chartH = math.max(10.0, size.height - padTop - padBottom);

    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;

    // Siatka pozioma (60%, 80%, 100%)
    for (final double level in [0.6, 0.8, 1.0]) {
      final double y = padTop + chartH * (1.0 - ((level - 0.5) / 0.5).clamp(0.0, 1.0));
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(padLeft + chartW, y),
        gridPaint,
      );
    }

    final Path seaPath = Path();
    final Path altPath = Path();
    final double maxT = curve.last.elapsedSeconds > 0
        ? curve.last.elapsedSeconds
        : 900.0;

    for (int i = 0; i < curve.length; i++) {
      final pt = curve[i];
      final double x = padLeft + (pt.elapsedSeconds / maxT) * chartW;
      final double ySea = padTop +
          chartH * (1.0 - ((pt.seaLevelRatio - 0.5) / 0.5).clamp(0.0, 1.0));
      final double yAlt = padTop +
          chartH * (1.0 - ((pt.altitudeRatio - 0.5) / 0.5).clamp(0.0, 1.0));

      if (i == 0) {
        seaPath.moveTo(x, ySea);
        altPath.moveTo(x, yAlt);
      } else {
        seaPath.lineTo(x, ySea);
        altPath.lineTo(x, yAlt);
      }
    }

    final Paint seaPaint = Paint()
      ..color = AppColors.accentBlue
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint altPaint = Paint()
      ..color = altitudeColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(seaPath, seaPaint);
    canvas.drawPath(altPath, altPaint);

    // Etykiety osi
    final TextPainter tpLow = TextPainter(
      text: const TextSpan(
        text: '50%',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLow.paint(canvas, Offset(4, padTop + chartH - 10));

    final TextPainter tpHigh = TextPainter(
      text: const TextSpan(
        text: '100%',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpHigh.paint(canvas, const Offset(2, padTop - 4));

    final TextPainter tpEnd = TextPainter(
      text: const TextSpan(
        text: '15 min',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEnd.paint(canvas, Offset(padLeft + chartW - 34, padTop + chartH + 4));
  }

  @override
  bool shouldRepaint(covariant ExtremeAltitudeRecoveryCurvePainter oldDelegate) {
    return oldDelegate.curve != curve || oldDelegate.altitudeColor != altitudeColor;
  }
}

/// Interaktywny panel diagnostyczny fizjologii ekstremalnych wysokości (2500–3500 m)
/// oraz fal upałów (>38°C / >40°C).
class ExtremeAltitude3000mAndHeatwavePanel extends StatefulWidget {
  final ExtremeAltitudeAndHeatwaveInput? initialInput;

  const ExtremeAltitude3000mAndHeatwavePanel({
    super.key,
    this.initialInput,
  });

  @override
  State<ExtremeAltitude3000mAndHeatwavePanel> createState() =>
      _ExtremeAltitude3000mAndHeatwavePanelState();
}

class _ExtremeAltitude3000mAndHeatwavePanelState
    extends State<ExtremeAltitude3000mAndHeatwavePanel> {
  late ExtremeAltitudeAndHeatwaveInput _input;
  ExtremeClimateScenarioPreset? _activePreset =
      ExtremeClimateScenarioPreset.altoDelColorado3000m;

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput ??
        ExtremeAltitudeAndHeatwaveInput(
          altitudeMeters: ExtremeClimateScenarioPreset.altoDelColorado3000m.altitudeMeters,
          ambientTempCelsius:
              ExtremeClimateScenarioPreset.altoDelColorado3000m.ambientTempCelsius,
          solarRadiationFactor:
              ExtremeClimateScenarioPreset.altoDelColorado3000m.solarRadiationFactor,
          windSpeedMs: ExtremeClimateScenarioPreset.altoDelColorado3000m.windSpeedMs,
        );
  }

  void _applyPreset(ExtremeClimateScenarioPreset preset) {
    setState(() {
      _activePreset = preset;
      _input = _input.copyWith(
        altitudeMeters: preset.altitudeMeters,
        ambientTempCelsius: preset.ambientTempCelsius,
        solarRadiationFactor: preset.solarRadiationFactor,
        windSpeedMs: preset.windSpeedMs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = ExtremeAltitude3000mAndHeatwaveSolver.solve(_input);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 680;
        final bool isWide = constraints.maxWidth >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isNarrow ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(result, isNarrow),
                const SizedBox(height: 16),
                _buildPresetSelector(),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildControlsCard()),
                      const SizedBox(width: 16),
                      Expanded(flex: 7, child: _buildTelemetryAndChart(result, isNarrow)),
                    ],
                  )
                else ...[
                  _buildControlsCard(),
                  const SizedBox(height: 16),
                  _buildTelemetryAndChart(result, isNarrow),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ExtremeAltitudeAndHeatwaveResult result, bool isNarrow) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ekstremalna Wysokość & Fala Upałów',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isNarrow ? 17 : 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Fizjologia PaO2 >2800 m n.p.m. oraz termika asfaltu 58°C (>40°C)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final badges = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _StatusBadge(
          label: result.altitudeZone.labelPl,
          color: result.altitudeZone.accentColor,
        ),
        _StatusBadge(
          label: result.heatwaveZone.labelPl,
          color: result.heatwaveZone.accentColor,
        ),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          badges,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        badges,
      ],
    );
  }

  Widget _buildPresetSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ExtremeClimateScenarioPreset.values.map((preset) {
        final bool selected = _activePreset == preset;
        return _InteractivePresetButton(
          title: preset.titlePl,
          subtitle: preset.subtitlePl,
          selected: selected,
          onTap: () => _applyPreset(preset),
        );
      }).toList(),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Parametry Środowiskowe i Kolarza',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _SliderRow(
            label: 'Wysokość n.p.m.',
            valueLabel: '${_input.altitudeMeters.toStringAsFixed(0)} m',
            value: _input.altitudeMeters,
            min: 0.0,
            max: 3600.0,
            divisions: 72,
            activeColor: AppColors.accentBlue,
            onChanged: (v) => setState(() {
              _activePreset = null;
              _input = _input.copyWith(altitudeMeters: v);
            }),
          ),
          _SliderRow(
            label: 'Temperatura powietrza',
            valueLabel: '${_input.ambientTempCelsius.toStringAsFixed(1)}°C',
            value: _input.ambientTempCelsius,
            min: 0.0,
            max: 46.0,
            divisions: 92,
            activeColor: AppColors.amberWarning,
            onChanged: (v) => setState(() {
              _activePreset = null;
              _input = _input.copyWith(ambientTempCelsius: v);
            }),
          ),
          _SliderRow(
            label: 'Koszt ataku W\'',
            valueLabel: '${(_input.attackWPrimeCostJoules / 1000.0).toStringAsFixed(1)} kJ',
            value: _input.attackWPrimeCostJoules,
            min: 2000.0,
            max: 14000.0,
            divisions: 24,
            activeColor: AppColors.primaryAccent,
            onChanged: (v) => setState(() {
              _input = _input.copyWith(attackWPrimeCostJoules: v);
            }),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TogglePill(
                label: 'Obóz wysokogórski',
                active: _input.hasAltitudeAcclimatization,
                onChanged: (v) => setState(
                  () => _input = _input.copyWith(hasAltitudeAcclimatization: v),
                ),
              ),
              _TogglePill(
                label: 'Góral z Andów',
                active: _input.isAndeanNative,
                onChanged: (v) => setState(
                  () => _input = _input.copyWith(isAndeanNative: v),
                ),
              ),
              _TogglePill(
                label: 'Aklimatyzacja cieplna',
                active: _input.hasHeatAcclimatization,
                onChanged: (v) => setState(
                  () => _input = _input.copyWith(hasHeatAcclimatization: v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryAndChart(
    ExtremeAltitudeAndHeatwaveResult result,
    bool isNarrow,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              title: 'Ciśnienie PaO2 / SpO2',
              value: '${result.arterialPao2MmHg.toStringAsFixed(1)} mmHg',
              subtitle: 'SpO2 ${result.arterialSpo2Percent.toStringAsFixed(1)}% • '
                  '${result.barometricPressureHpa.toStringAsFixed(0)} hPa',
              accentColor: result.altitudeZone.accentColor,
              width: isNarrow ? double.infinity : 200,
            ),
            _MetricCard(
              title: 'Regeneracja tau W\'',
              value: '+${result.tauWPrimePenaltyPercent.toStringAsFixed(0)}%',
              subtitle: '${result.effectiveTauWPrimeSeconds.toStringAsFixed(0)} s '
                  '(${result.attackRecoveryTimeRatio.toStringAsFixed(2)}x czas po ataku)',
              accentColor: result.isExtremeHypoxiaWPrimeZone
                  ? AppColors.crimsonAlert
                  : AppColors.accentBlue,
              width: isNarrow ? double.infinity : 200,
            ),
            _MetricCard(
              title: 'Asfalt & Opór Crr',
              value: '${result.asphaltSurfaceTempCelsius.toStringAsFixed(1)}°C',
              subtitle: 'Crr +${result.crrIncreasePercent.toStringAsFixed(1)}% '
                  '(${result.effectiveCrr.toStringAsFixed(5)})',
              accentColor: result.heatwaveZone.accentColor,
              width: isNarrow ? double.infinity : 200,
            ),
            _MetricCard(
              title: 'Nawadnianie',
              value: '${result.hydrationMultiplier.toStringAsFixed(2)}x',
              subtitle:
                  '${result.requiredHydrationLitersPerHour.toStringAsFixed(2)} L/h '
                  '(${result.requiredBidonsPerHour.toStringAsFixed(1)} bid./h)',
              accentColor: result.requiresDoubleHydration
                  ? AppColors.crimsonAlert
                  : AppColors.statusSuccess,
              width: isNarrow ? double.infinity : 200,
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Krzywa regeneracji W\' po ataku (Poziom morza vs Wysokość)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${result.attackRecoveryTimeRatio.toStringAsFixed(2)}x wolniej',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: result.altitudeZone.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: CustomPaint(
                  painter: ExtremeAltitudeRecoveryCurvePainter(
                    curve: result.recoveryCurve,
                    altitudeColor: result.altitudeZone.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InteractivePresetButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _InteractivePresetButton({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_InteractivePresetButton> createState() =>
      _InteractivePresetButtonState();
}

class _InteractivePresetButtonState extends State<_InteractivePresetButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused || _hovered)
            ? AppColors.accentBlue
            : AppColors.cardBorder;

    final Color bgColor = widget.selected
        ? AppColors.surfaceLight
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.6)
                : AppColors.surface;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.16),
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
}

class _TogglePill extends StatefulWidget {
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;

  const _TogglePill({
    required this.label,
    required this.active,
    required this.onChanged,
  });

  @override
  State<_TogglePill> createState() => _TogglePillState();
}

class _TogglePillState extends State<_TogglePill> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.active
        ? AppColors.statusSuccess
        : (_hovered || _focused)
            ? AppColors.accentBlue
            : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.active),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.statusSuccess.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.active
                  ? AppColors.statusSuccess
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final double width;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
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
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
