// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import 'tire_pressure_calculator.dart';

/// Klasyfikacja trudności sektora brukowanego (skala 1★–5★ Paris-Roubaix / Flandria).
enum CobbleSectorRating {
  oneStar(
    stars: 1,
    labelPl: '1★ Łagodny bruk miejski',
    labelEn: '1★ Smooth Town Cobbles',
    meanStepHeightMm: 11.0,
    cobblePitchMm: 220.0,
    roughnessIndex: 0.34,
    breakpointFactor: 0.91,
  ),
  twoStar(
    stars: 2,
    labelPl: '2★ Równy bruk klasyczny',
    labelEn: '2★ Even Classic Pavé',
    meanStepHeightMm: 16.0,
    cobblePitchMm: 235.0,
    roughnessIndex: 0.50,
    breakpointFactor: 0.85,
  ),
  threeStar(
    stars: 3,
    labelPl: '3★ Wymagający bruk szosowy',
    labelEn: '3★ Rough Sector Pavé',
    meanStepHeightMm: 22.0,
    cobblePitchMm: 250.0,
    roughnessIndex: 0.68,
    breakpointFactor: 0.80,
  ),
  fourStar(
    stars: 4,
    labelPl: '4★ Ciężki bruk sektorowy',
    labelEn: '4★ Severe Sector Pavé',
    meanStepHeightMm: 28.0,
    cobblePitchMm: 270.0,
    roughnessIndex: 0.85,
    breakpointFactor: 0.75,
  ),
  fiveStar(
    stars: 5,
    labelPl: '5★ Ekstremalny bruk (Arenberg / Carrefour)',
    labelEn: '5★ Monumental 5-Star Pavé',
    meanStepHeightMm: 35.0,
    cobblePitchMm: 295.0,
    roughnessIndex: 1.00,
    breakpointFactor: 0.70,
  );

  final int stars;
  final String labelPl;
  final String labelEn;
  final double meanStepHeightMm;
  final double cobblePitchMm;
  final double roughnessIndex;
  final double breakpointFactor;

  const CobbleSectorRating({
    required this.stars,
    required this.labelPl,
    required this.labelEn,
    required this.meanStepHeightMm,
    required this.cobblePitchMm,
    required this.roughnessIndex,
    required this.breakpointFactor,
  });
}

/// Stan wilgotności i zabłocenia nawierzchni brukowanej.
enum CobbleSurfaceMoisture {
  dry('Suchy bruk', 'Dry Pavé', 1.00, 1.00),
  damp('Wilgotny bruk', 'Damp Pavé', 0.94, 0.84),
  wetMuddy('Mokry i błotnisty bruk', 'Wet & Muddy Pavé', 0.89, 0.68);

  final String labelPl;
  final String labelEn;
  final double pressureMultiplier;
  final double gripMultiplier;

  const CobbleSurfaceMoisture(
    this.labelPl,
    this.labelEn,
    this.pressureMultiplier,
    this.gripMultiplier,
  );
}

/// Werdykt oceny ugięcia opony na bruku w czasie rzeczywistym.
enum CobbleDeflectionVerdict {
  optimalCompliance(
    'Optymalne pochłanianie bruku',
    'Opona pracuje w idealnym oknie ugięcia (15–20%), pochłaniając krawędzie kamieni bez dobicia obręczy.',
  ),
  tooStiffHighImpedance(
    'Zbyt wysokie ciśnienie – odbijanie koła',
    'Opona jest zbyt twarda i odbija się od kostki zamiast ją opływać, generując wysokie straty impedancji wibracyjnej.',
  ),
  excessiveSquirm(
    'Nadmierne ugięcie – pływanie karkasu',
    'Opona ugina się powyżej bezpiecznego progu; rosną straty histerezy i niestabilność boczna.',
  ),
  imminentRimStrike(
    'Krytyczne ryzyko dobicia obręczy (Rim Strike)',
    'Dynamiczne ugięcie na 5★ bruku wyczerpuje skok opony – grozi rozcięcie karkasu lub pęknięcie karbonowej felgi.',
  ),
  hooklessOverpressure(
    'Przekroczony limit Hookless (>5.0 BAR)',
    'Ciśnienie przekracza normę bezpieczeństwa ETRTO 5.0 BAR (72.5 PSI) dla obręczy bezhaczykowych.',
  );

  final String titlePl;
  final String descriptionPl;

  const CobbleDeflectionVerdict(this.titlePl, this.descriptionPl);
}

/// Parametry wejściowe chwilowej symulacji ugięcia opony na bruku.
class CobbleTireDeflectionInput {
  final double totalMassKg;
  final double frontWeightRatio;
  final int nominalTireWidthMm;
  final double internalRimWidthMm;
  final double frontPressureBar;
  final double rearPressureBar;
  final TireSystemType tireSystem;
  final RimType rimType;
  final CobbleSectorRating sectorRating;
  final CobbleSurfaceMoisture moisture;
  final double speedKmh;
  final int riderCobbleSkill;
  final bool hasTireInsert;
  final double timeSec;

  const CobbleTireDeflectionInput({
    this.totalMassKg = 82.0,
    this.frontWeightRatio = 0.44,
    this.nominalTireWidthMm = 32,
    this.internalRimWidthMm = 23.0,
    this.frontPressureBar = 3.20,
    this.rearPressureBar = 3.45,
    this.tireSystem = TireSystemType.tubeless,
    this.rimType = RimType.hookless,
    this.sectorRating = CobbleSectorRating.fiveStar,
    this.moisture = CobbleSurfaceMoisture.dry,
    this.speedKmh = 38.0,
    this.riderCobbleSkill = 82,
    this.hasTireInsert = false,
    this.timeSec = 0.0,
  });

  CobbleTireDeflectionInput copyWith({
    double? totalMassKg,
    double? frontWeightRatio,
    int? nominalTireWidthMm,
    double? internalRimWidthMm,
    double? frontPressureBar,
    double? rearPressureBar,
    TireSystemType? tireSystem,
    RimType? rimType,
    CobbleSectorRating? sectorRating,
    CobbleSurfaceMoisture? moisture,
    double? speedKmh,
    int? riderCobbleSkill,
    bool? hasTireInsert,
    double? timeSec,
  }) {
    return CobbleTireDeflectionInput(
      totalMassKg: totalMassKg ?? this.totalMassKg,
      frontWeightRatio: frontWeightRatio ?? this.frontWeightRatio,
      nominalTireWidthMm: nominalTireWidthMm ?? this.nominalTireWidthMm,
      internalRimWidthMm: internalRimWidthMm ?? this.internalRimWidthMm,
      frontPressureBar: frontPressureBar ?? this.frontPressureBar,
      rearPressureBar: rearPressureBar ?? this.rearPressureBar,
      tireSystem: tireSystem ?? this.tireSystem,
      rimType: rimType ?? this.rimType,
      sectorRating: sectorRating ?? this.sectorRating,
      moisture: moisture ?? this.moisture,
      speedKmh: speedKmh ?? this.speedKmh,
      riderCobbleSkill: riderCobbleSkill ?? this.riderCobbleSkill,
      hasTireInsert: hasTireInsert ?? this.hasTireInsert,
      timeSec: timeSec ?? this.timeSec,
    );
  }
}

/// Telemetria ugięcia i strat pojedynczego koła (przód lub tył).
class WheelDeflectionTelemetry {
  final String wheelLabel;
  final double pressureBar;
  final double pressurePsi;
  final double verticalLoadKg;
  final double verticalLoadN;
  final double casingHeightMm;
  final double verticalSpringRateNPerMm;
  final double staticDeflectionMm;
  final double staticDeflectionPercent;
  final double dynamicPeakDeflectionMm;
  final double dynamicDeflectionPercent;
  final double contactPatchLengthMm;
  final double contactPatchAreaCm2;
  final double hysteresisLossWatts;
  final double impedanceVibrationLossWatts;
  final double rimBottomOutMarginMm;
  final double pinchFlatRiskPerKmPercent;
  final double tractionIndexPercent;

  double get totalWheelLossWatts =>
      hysteresisLossWatts + impedanceVibrationLossWatts;

  bool get isRimStrikeImminent => rimBottomOutMarginMm <= 0.5;

  const WheelDeflectionTelemetry({
    required this.wheelLabel,
    required this.pressureBar,
    required this.pressurePsi,
    required this.verticalLoadKg,
    required this.verticalLoadN,
    required this.casingHeightMm,
    required this.verticalSpringRateNPerMm,
    required this.staticDeflectionMm,
    required this.staticDeflectionPercent,
    required this.dynamicPeakDeflectionMm,
    required this.dynamicDeflectionPercent,
    required this.contactPatchLengthMm,
    required this.contactPatchAreaCm2,
    required this.hysteresisLossWatts,
    required this.impedanceVibrationLossWatts,
    required this.rimBottomOutMarginMm,
    required this.pinchFlatRiskPerKmPercent,
    required this.tractionIndexPercent,
  });
}

/// Chwilowy snapshot fizyki ugięcia opon i strat wibracyjnych na bruku.
class CobbleDeflectionSnapshot {
  final double timeSec;
  final double speedKmh;
  final double effectiveTireWidthMm;
  final CobbleSectorRating sectorRating;
  final CobbleSurfaceMoisture moisture;
  final WheelDeflectionTelemetry frontWheel;
  final WheelDeflectionTelemetry rearWheel;
  final double hysteresisLossWatts;
  final double impedanceLossWatts;
  final double totalVibrationLossWatts;
  final double vibrationFrequencyHz;
  final double rmsVerticalAccelerationG;
  final double fatigueMultiplier;
  final double rimStrikeProbabilityPercent;
  final double punctureRiskPerSectorPercent;
  final double overallTractionPercent;
  final double optimalFrontBar;
  final double optimalRearBar;
  final double potentialSavingsWatts;
  final CobbleDeflectionVerdict verdict;
  final String adviceSummary;

  const CobbleDeflectionSnapshot({
    required this.timeSec,
    required this.speedKmh,
    required this.effectiveTireWidthMm,
    required this.sectorRating,
    required this.moisture,
    required this.frontWheel,
    required this.rearWheel,
    required this.hysteresisLossWatts,
    required this.impedanceLossWatts,
    required this.totalVibrationLossWatts,
    required this.vibrationFrequencyHz,
    required this.rmsVerticalAccelerationG,
    required this.fatigueMultiplier,
    required this.rimStrikeProbabilityPercent,
    required this.punctureRiskPerSectorPercent,
    required this.overallTractionPercent,
    required this.optimalFrontBar,
    required this.optimalRearBar,
    required this.potentialSavingsWatts,
    required this.verdict,
    required this.adviceSummary,
  });
}

/// Punkt krzywej przemiatania ciśnienia (Histereza vs Impedancja).
class CobblePressureSweepPoint {
  final double pressureBar;
  final double hysteresisWatts;
  final double impedanceWatts;
  final double totalLossWatts;
  final double deflectionPercent;
  final double rimStrikeRiskPercent;

  const CobblePressureSweepPoint({
    required this.pressureBar,
    required this.hysteresisWatts,
    required this.impedanceWatts,
    required this.totalLossWatts,
    required this.deflectionPercent,
    required this.rimStrikeRiskPercent,
  });
}

/// Podsumowanie przejazdu całego sektora brukowanego.
class CobbleSectorSimulationSummary {
  final double sectorLengthKm;
  final double averageSpeedKmh;
  final double elapsedTimeSec;
  final double totalEnergyLostKj;
  final double averageVibrationWatts;
  final double peakRmsAccelerationG;
  final int rimStrikesCount;
  final double cumulativePunctureProbabilityPercent;
  final List<CobbleDeflectionSnapshot> samples;

  const CobbleSectorSimulationSummary({
    required this.sectorLengthKm,
    required this.averageSpeedKmh,
    required this.elapsedTimeSec,
    required this.totalEnergyLostKj,
    required this.averageVibrationWatts,
    required this.peakRmsAccelerationG,
    required this.rimStrikesCount,
    required this.cumulativePunctureProbabilityPercent,
    required this.samples,
  });
}

/// Silnik fizyki ugięcia opon, powierzchni styku i strat wibracyjnych
/// (impedancja vs histereza) na bruku 1★–5★ w czasie rzeczywistym.
class CobbleTirePressureRealTimeDeflection {
  CobbleTirePressureRealTimeDeflection._();

  static const double _gravity = 9.80665;

  /// Wylicza optymalne ciśnienie (punkt przegięcia breakpoint) dla zadanego
  /// sektora brukowego, szerokości opony, masy i wilgotności.
  static ({double frontBar, double rearBar}) computeOptimalCobblePressures(
    CobbleTireDeflectionInput input,
  ) {
    final double safeMass = input.totalMassKg.clamp(45.0, 130.0);
    final double frontRatio = input.frontWeightRatio.clamp(0.36, 0.52);
    final double effectiveWidth =
        TirePressureCalculator.calculateEffectiveTireWidth(
      nominalWidthMm: input.nominalTireWidthMm.clamp(23, 42),
      internalRimWidthMm: input.internalRimWidthMm.clamp(17.0, 27.0),
    );

    final double frontLoadKg = safeMass * frontRatio;
    final double rearLoadKg = safeMass * (1.0 - frontRatio);

    const double refLoadKg = 40.0;
    const double refWidthMm = 28.0;
    const double refPressureBar = 4.0;

    final double baseFront = refPressureBar *
        math.pow(frontLoadKg / refLoadKg, 0.68) *
        math.pow(refWidthMm / effectiveWidth, 1.35);
    final double baseRear = refPressureBar *
        math.pow(rearLoadKg / refLoadKg, 0.68) *
        math.pow(refWidthMm / effectiveWidth, 1.35);

    final double envMult = input.sectorRating.breakpointFactor *
        input.moisture.pressureMultiplier *
        input.tireSystem.pressureMultiplier;

    final double minSafe = input.tireSystem == TireSystemType.tubeless
        ? (effectiveWidth >= 30.0 ? 2.15 : 2.55)
        : (effectiveWidth >= 30.0 ? 2.75 : 3.25);

    final double maxRim = input.rimType.maxSafePressureBar;

    final double optFront = _roundToStep(
      (baseFront * envMult).clamp(minSafe, maxRim),
      0.05,
    );
    final double optRear = _roundToStep(
      (baseRear * envMult).clamp(minSafe + 0.15, maxRim),
      0.05,
    );

    return (frontBar: optFront, rearBar: optRear);
  }

  /// Rozwiązuje chwilowy stan ugięcia opon, przyspieszeń wibracyjnych i strat mocy
  /// na bruku (w szczególności 5-gwiazdkowym).
  static CobbleDeflectionSnapshot evaluateStep(
    CobbleTireDeflectionInput input,
  ) {
    final double safeMass = input.totalMassKg.clamp(45.0, 130.0);
    final double frontRatio = input.frontWeightRatio.clamp(0.36, 0.52);
    final double speedKmh = input.speedKmh.clamp(8.0, 70.0);
    final double speedMs = speedKmh / 3.6;
    final double skillFactor =
        (input.riderCobbleSkill.clamp(1, 100) / 100.0);

    final double effectiveWidth =
        TirePressureCalculator.calculateEffectiveTireWidth(
      nominalWidthMm: input.nominalTireWidthMm.clamp(23, 42),
      internalRimWidthMm: input.internalRimWidthMm.clamp(17.0, 27.0),
    );
    final double casingHeightMm = effectiveWidth * 0.92;

    final optimal = computeOptimalCobblePressures(input);

    // Częstotliwość wzbudzenia wibracji przez kolejne kostki bruku [Hz].
    final double pitchMeters = input.sectorRating.cobblePitchMm / 1000.0;
    final double excitationHz = (speedMs / pitchMeters).clamp(6.0, 85.0);

    // Dynamiczna modulacja chwilowa dla symulacji w czasie rzeczywistym.
    final double phaseFront = input.timeSec * excitationHz * 2.0 * math.pi;
    final double phaseRear =
        phaseFront - (1.02 / pitchMeters) * 2.0 * math.pi; // Rozstaw osi ~1.02m

    final double frontPulse = 0.78 + 0.22 * math.sin(phaseFront).abs();
    final double rearPulse = 0.78 + 0.22 * math.sin(phaseRear).abs();

    final WheelDeflectionTelemetry frontWheel = _solveSingleWheel(
      wheelLabel: 'Przód',
      pressureBar: input.frontPressureBar.clamp(1.5, 9.0),
      optimalBar: optimal.frontBar,
      loadKg: safeMass * frontRatio,
      effectiveWidthMm: effectiveWidth,
      casingHeightMm: casingHeightMm,
      speedKmh: speedKmh,
      tireSystem: input.tireSystem,
      sectorRating: input.sectorRating,
      moisture: input.moisture,
      skillFactor: skillFactor,
      hasTireInsert: input.hasTireInsert,
      dynamicPulseFactor: frontPulse,
      weightLossShare: 0.42,
    );

    final WheelDeflectionTelemetry rearWheel = _solveSingleWheel(
      wheelLabel: 'Tył',
      pressureBar: input.rearPressureBar.clamp(1.5, 9.0),
      optimalBar: optimal.rearBar,
      loadKg: safeMass * (1.0 - frontRatio),
      effectiveWidthMm: effectiveWidth,
      casingHeightMm: casingHeightMm,
      speedKmh: speedKmh,
      tireSystem: input.tireSystem,
      sectorRating: input.sectorRating,
      moisture: input.moisture,
      skillFactor: skillFactor,
      hasTireInsert: input.hasTireInsert,
      dynamicPulseFactor: rearPulse,
      weightLossShare: 0.58,
    );

    final double totalHysteresis =
        frontWheel.hysteresisLossWatts + rearWheel.hysteresisLossWatts;
    final double totalImpedance =
        frontWheel.impedanceVibrationLossWatts +
            rearWheel.impedanceVibrationLossWatts;
    final double totalVibrationLoss = totalHysteresis + totalImpedance;

    // Oblicz potencjalną oszczędność przy idealnym ciśnieniu.
    final CobbleDeflectionSnapshot optimalSnapshot =
        _evaluateStaticOptimalReference(
      input: input,
      optimalFrontBar: optimal.frontBar,
      optimalRearBar: optimal.rearBar,
      safeMass: safeMass,
      frontRatio: frontRatio,
      effectiveWidth: effectiveWidth,
      casingHeightMm: casingHeightMm,
      speedKmh: speedKmh,
      skillFactor: skillFactor,
    );
    final double savingsWatts = math.max(
      0.0,
      totalVibrationLoss - optimalSnapshot.totalVibrationLossWatts,
    );

    // Przyspieszenie pionowe RMS [G] odczuwane na kierownicy i siodle.
    final double avgPressure =
        (frontWheel.pressureBar + rearWheel.pressureBar) * 0.5;
    final double avgOptimal = (optimal.frontBar + optimal.rearBar) * 0.5;
    final double overStiffnessRatio =
        (avgPressure / math.max(1.5, avgOptimal)).clamp(0.55, 2.5);
    final double speedNorm = math.pow(speedKmh / 35.0, 1.25).toDouble();
    final double rmsG = (1.35 *
            input.sectorRating.roughnessIndex *
            speedNorm *
            math.pow(overStiffnessRatio, 0.85) *
            (1.08 - 0.16 * skillFactor) *
            (30.0 / effectiveWidth))
        .clamp(0.35, 6.50);

    // Mnożnik zmęczenia mięśniowego rąk, barków i korpusu na bruku.
    final double fatigueMultiplier =
        (1.0 + (rmsG - 0.8).clamp(0.0, 5.5) * 0.068).clamp(1.0, 1.42);

    // Łączne prawdopodobieństwo dobicia obręczy oraz defektu na sektorze.
    final double rimStrikeProb = (math.max(
              frontWheel.isRimStrikeImminent
                  ? 65.0 + frontWheel.rimBottomOutMarginMm.abs() * 12.0
                  : math.max(0.0, 18.0 - frontWheel.rimBottomOutMarginMm * 4.5),
              rearWheel.isRimStrikeImminent
                  ? 72.0 + rearWheel.rimBottomOutMarginMm.abs() * 12.0
                  : math.max(0.0, 22.0 - rearWheel.rimBottomOutMarginMm * 4.5),
            ) *
            (input.hasTireInsert ? 0.35 : 1.0))
        .clamp(0.0, 99.5);

    final double sectorPunctureRisk = (1.0 -
            (1.0 - frontWheel.pinchFlatRiskPerKmPercent / 100.0) *
                (1.0 - rearWheel.pinchFlatRiskPerKmPercent / 100.0)) *
        100.0;

    final double overallTraction =
        (frontWheel.tractionIndexPercent * 0.45 +
                rearWheel.tractionIndexPercent * 0.55)
            .clamp(10.0, 100.0);

    final CobbleDeflectionVerdict verdict = _determineVerdict(
      input: input,
      front: frontWheel,
      rear: rearWheel,
      optimalFront: optimal.frontBar,
      optimalRear: optimal.rearBar,
    );

    final String advice = _buildAdviceSummary(
      verdict: verdict,
      front: frontWheel,
      rear: rearWheel,
      optimalFront: optimal.frontBar,
      optimalRear: optimal.rearBar,
      savingsWatts: savingsWatts,
      sectorRating: input.sectorRating,
    );

    return CobbleDeflectionSnapshot(
      timeSec: input.timeSec,
      speedKmh: speedKmh,
      effectiveTireWidthMm: effectiveWidth,
      sectorRating: input.sectorRating,
      moisture: input.moisture,
      frontWheel: frontWheel,
      rearWheel: rearWheel,
      hysteresisLossWatts: totalHysteresis,
      impedanceLossWatts: totalImpedance,
      totalVibrationLossWatts: totalVibrationLoss,
      vibrationFrequencyHz: excitationHz,
      rmsVerticalAccelerationG: rmsG,
      fatigueMultiplier: fatigueMultiplier,
      rimStrikeProbabilityPercent: rimStrikeProb,
      punctureRiskPerSectorPercent: sectorPunctureRisk.clamp(0.0, 99.0),
      overallTractionPercent: overallTraction,
      optimalFrontBar: optimal.frontBar,
      optimalRearBar: optimal.rearBar,
      potentialSavingsWatts: savingsWatts,
      verdict: verdict,
      adviceSummary: advice,
    );
  }

  /// Generuje krzywą strat mocy (histereza + impedancja = suma) w funkcji ciśnienia
  /// dla wykresu punktu przegięcia (breakpoint) na zadanym bruku.
  static List<CobblePressureSweepPoint> sweepPressureCurve(
    CobbleTireDeflectionInput baseInput, {
    double minBar = 2.0,
    double maxBar = 7.5,
    double stepBar = 0.25,
  }) {
    final List<CobblePressureSweepPoint> points = [];
    final double rearOffset = baseInput.rearPressureBar - baseInput.frontPressureBar;
    final double safeStep = stepBar.clamp(0.05, 1.0);

    for (double p = minBar; p <= maxBar + 0.001; p += safeStep) {
      final double clampedFront = p.clamp(1.8, 8.5);
      final double clampedRear = (clampedFront + rearOffset).clamp(1.8, 8.5);
      final CobbleDeflectionSnapshot snap = evaluateStep(
        baseInput.copyWith(
          frontPressureBar: clampedFront,
          rearPressureBar: clampedRear,
          timeSec: 0.25,
        ),
      );
      points.add(
        CobblePressureSweepPoint(
          pressureBar: _roundToStep(clampedFront, 0.01),
          hysteresisWatts: snap.hysteresisLossWatts,
          impedanceWatts: snap.impedanceLossWatts,
          totalLossWatts: snap.totalVibrationLossWatts,
          deflectionPercent: snap.frontWheel.staticDeflectionPercent,
          rimStrikeRiskPercent: snap.rimStrikeProbabilityPercent,
        ),
      );
    }
    return points;
  }

  /// Symuluje przejazd całego sektora brukowanego (np. 2.4 km Trouée d'Arenberg)
  /// z krokiem czasowym `dtSec`, zliczając energię utraconą na wibracje i uderzenia obręczy.
  static CobbleSectorSimulationSummary simulateSectorTraversal(
    CobbleTireDeflectionInput input, {
    double sectorLengthKm = 2.4,
    double dtSec = 1.0,
  }) {
    final double safeLengthKm = sectorLengthKm.clamp(0.2, 15.0);
    final double safeSpeedKmh = input.speedKmh.clamp(10.0, 65.0);
    final double speedMs = safeSpeedKmh / 3.6;
    final double totalTimeSec = (safeLengthKm * 1000.0) / speedMs;
    final double safeDt = dtSec.clamp(0.1, 5.0);

    final List<CobbleDeflectionSnapshot> samples = [];
    double sumWatts = 0.0;
    double peakRmsG = 0.0;
    int rimStrikes = 0;

    for (double t = 0.0; t <= totalTimeSec; t += safeDt) {
      final CobbleDeflectionSnapshot snap = evaluateStep(
        input.copyWith(timeSec: t),
      );
      samples.add(snap);
      sumWatts += snap.totalVibrationLossWatts;
      if (snap.rmsVerticalAccelerationG > peakRmsG) {
        peakRmsG = snap.rmsVerticalAccelerationG;
      }
      if (snap.frontWheel.isRimStrikeImminent ||
          snap.rearWheel.isRimStrikeImminent) {
        rimStrikes++;
      }
    }

    final double avgWatts =
        samples.isEmpty ? 0.0 : sumWatts / samples.length;
    final double totalEnergyKj = (avgWatts * totalTimeSec) / 1000.0;
    final double perKmRisk = samples.isEmpty
        ? 0.0
        : samples.first.punctureRiskPerSectorPercent / 100.0;
    final double cumulativePuncture =
        (1.0 - math.pow(1.0 - perKmRisk.clamp(0.0, 0.95), safeLengthKm)) *
            100.0;

    return CobbleSectorSimulationSummary(
      sectorLengthKm: safeLengthKm,
      averageSpeedKmh: safeSpeedKmh,
      elapsedTimeSec: totalTimeSec,
      totalEnergyLostKj: totalEnergyKj,
      averageVibrationWatts: avgWatts,
      peakRmsAccelerationG: peakRmsG,
      rimStrikesCount: rimStrikes,
      cumulativePunctureProbabilityPercent: cumulativePuncture.clamp(0.0, 99.5),
      samples: samples,
    );
  }

  static CobbleDeflectionSnapshot _evaluateStaticOptimalReference({
    required CobbleTireDeflectionInput input,
    required double optimalFrontBar,
    required double optimalRearBar,
    required double safeMass,
    required double frontRatio,
    required double effectiveWidth,
    required double casingHeightMm,
    required double speedKmh,
    required double skillFactor,
  }) {
    final front = _solveSingleWheel(
      wheelLabel: 'Przód',
      pressureBar: optimalFrontBar,
      optimalBar: optimalFrontBar,
      loadKg: safeMass * frontRatio,
      effectiveWidthMm: effectiveWidth,
      casingHeightMm: casingHeightMm,
      speedKmh: speedKmh,
      tireSystem: input.tireSystem,
      sectorRating: input.sectorRating,
      moisture: input.moisture,
      skillFactor: skillFactor,
      hasTireInsert: input.hasTireInsert,
      dynamicPulseFactor: 0.89,
      weightLossShare: 0.42,
    );
    final rear = _solveSingleWheel(
      wheelLabel: 'Tył',
      pressureBar: optimalRearBar,
      optimalBar: optimalRearBar,
      loadKg: safeMass * (1.0 - frontRatio),
      effectiveWidthMm: effectiveWidth,
      casingHeightMm: casingHeightMm,
      speedKmh: speedKmh,
      tireSystem: input.tireSystem,
      sectorRating: input.sectorRating,
      moisture: input.moisture,
      skillFactor: skillFactor,
      hasTireInsert: input.hasTireInsert,
      dynamicPulseFactor: 0.89,
      weightLossShare: 0.58,
    );
    final double hyst = front.hysteresisLossWatts + rear.hysteresisLossWatts;
    final double imp =
        front.impedanceVibrationLossWatts + rear.impedanceVibrationLossWatts;

    return CobbleDeflectionSnapshot(
      timeSec: 0.0,
      speedKmh: speedKmh,
      effectiveTireWidthMm: effectiveWidth,
      sectorRating: input.sectorRating,
      moisture: input.moisture,
      frontWheel: front,
      rearWheel: rear,
      hysteresisLossWatts: hyst,
      impedanceLossWatts: imp,
      totalVibrationLossWatts: hyst + imp,
      vibrationFrequencyHz: 25.0,
      rmsVerticalAccelerationG: 1.4,
      fatigueMultiplier: 1.05,
      rimStrikeProbabilityPercent: 1.0,
      punctureRiskPerSectorPercent: 1.0,
      overallTractionPercent: 95.0,
      optimalFrontBar: optimalFrontBar,
      optimalRearBar: optimalRearBar,
      potentialSavingsWatts: 0.0,
      verdict: CobbleDeflectionVerdict.optimalCompliance,
      adviceSummary: '',
    );
  }

  static WheelDeflectionTelemetry _solveSingleWheel({
    required String wheelLabel,
    required double pressureBar,
    required double optimalBar,
    required double loadKg,
    required double effectiveWidthMm,
    required double casingHeightMm,
    required double speedKmh,
    required TireSystemType tireSystem,
    required CobbleSectorRating sectorRating,
    required CobbleSurfaceMoisture moisture,
    required double skillFactor,
    required bool hasTireInsert,
    required double dynamicPulseFactor,
    required double weightLossShare,
  }) {
    final double loadN = loadKg * _gravity;

    // Sztywność pionowa opony k_v [N/mm] ~ P * sqrt(W) + sztywność karkasu.
    final double casingStiffness = tireSystem == TireSystemType.tubeless
        ? 11.0
        : (tireSystem == TireSystemType.butylTube ? 15.5 : 12.5);
    final double springRateNPerMm =
        (pressureBar * 18.2 * math.pow(effectiveWidthMm / 28.0, 0.55) +
                casingStiffness)
            .clamp(25.0, 260.0);

    final double staticDeflMm =
        (loadN / springRateNPerMm).clamp(0.8, casingHeightMm * 0.72);
    final double staticDeflPct =
        ((staticDeflMm / casingHeightMm) * 100.0).clamp(3.0, 75.0);

    // Dynamiczne ugięcie od uderzenia w krawędź kostki brukowej.
    final double speedImpulseFactor = math.pow(speedKmh / 36.0, 1.15).toDouble();
    final double stepContributionMm = sectorRating.meanStepHeightMm *
        0.34 *
        speedImpulseFactor *
        (1.10 - 0.22 * skillFactor) *
        dynamicPulseFactor *
        (65.0 / springRateNPerMm).clamp(0.50, 1.85);

    final double maxPossibleTravel =
        casingHeightMm * (hasTireInsert ? 0.94 : 0.87);
    final double dynamicPeakMm =
        (staticDeflMm + stepContributionMm).clamp(1.0, casingHeightMm * 1.05);
    final double dynamicDeflPct =
        ((dynamicPeakMm / casingHeightMm) * 100.0).clamp(4.0, 100.0);

    final double bottomOutMarginMm = maxPossibleTravel - dynamicPeakMm;

    // Powierzchnia styku (Contact Patch) z geometrii cięciwy koła (R = 340 mm).
    const double wheelRadiusMm = 340.0;
    final double contactLengthMm =
        (2.0 * math.sqrt(2.0 * wheelRadiusMm * staticDeflMm)).clamp(35.0, 165.0);
    final double contactWidthMm =
        (effectiveWidthMm * (0.48 + 0.42 * (staticDeflPct / 25.0)))
            .clamp(12.0, effectiveWidthMm * 0.96);
    final double contactAreaCm2 = (contactLengthMm * contactWidthMm * 0.78) / 100.0;

    // 1. Straty histerezy (rosną przy niskim ciśnieniu / dużym ugięciu karkasu).
    final double speedRatio = speedKmh / 40.0;
    final double underDelta = math.max(0.0, optimalBar - pressureBar);
    final double baseHysteresis = (4.2 +
            tireSystem.internalTubeLossWatts * 0.55 +
            math.pow(staticDeflPct / 16.0, 1.25) * 2.4) *
        weightLossShare *
        speedRatio;
    final double excessHysteresis =
        (4.8 * math.pow(underDelta, 1.35) * speedRatio) * weightLossShare;
    final double hysteresisWatts = baseHysteresis + excessHysteresis;

    // 2. Straty impedancji wibracyjnej (rosną gwałtownie przy zbyt wysokim ciśnieniu na bruku).
    final double overDelta = math.max(0.0, pressureBar - optimalBar);
    final double speedPow = math.pow(speedKmh / 38.0, 1.55).toDouble();
    final double baselineImpedance =
        2.6 * sectorRating.roughnessIndex * weightLossShare * speedPow;
    final double excessImpedance = (13.8 *
            sectorRating.roughnessIndex *
            math.pow(overDelta, 1.62) *
            speedPow *
            (1.06 - 0.14 * skillFactor)) *
        weightLossShare;
    final double impedanceWatts = baselineImpedance + excessImpedance;

    // 3. Ryzyko przyszczypnięcia / rozcięcia na kilometr bruku.
    double pinchRiskPerKm = 0.25 * sectorRating.roughnessIndex;
    if (bottomOutMarginMm < 3.0) {
      final double deficit = 3.0 - bottomOutMarginMm;
      pinchRiskPerKm += math.pow(deficit, 1.65) *
          (2.6 - 1.7 * tireSystem.pinchFlatResistanceFactor);
    }
    if (hasTireInsert) {
      pinchRiskPerKm *= 0.38;
    }
    pinchRiskPerKm = pinchRiskPerKm.clamp(0.1, 85.0);

    // 4. Przyczepność na kostce (spada przy odbijaniu na nadciśnieniu oraz przy błocie).
    double traction = 97.0 * moisture.gripMultiplier;
    if (overDelta > 0.15) {
      traction -= overDelta * 11.5 * sectorRating.roughnessIndex;
    } else if (underDelta > 0.65) {
      traction -= (underDelta - 0.65) * 9.0;
    }
    traction = traction.clamp(18.0, 100.0);

    return WheelDeflectionTelemetry(
      wheelLabel: wheelLabel,
      pressureBar: pressureBar,
      pressurePsi: TirePressureCalculator.barToPsi(pressureBar),
      verticalLoadKg: loadKg,
      verticalLoadN: loadN,
      casingHeightMm: casingHeightMm,
      verticalSpringRateNPerMm: springRateNPerMm,
      staticDeflectionMm: staticDeflMm,
      staticDeflectionPercent: staticDeflPct,
      dynamicPeakDeflectionMm: dynamicPeakMm,
      dynamicDeflectionPercent: dynamicDeflPct,
      contactPatchLengthMm: contactLengthMm,
      contactPatchAreaCm2: contactAreaCm2,
      hysteresisLossWatts: hysteresisWatts,
      impedanceVibrationLossWatts: impedanceWatts,
      rimBottomOutMarginMm: bottomOutMarginMm,
      pinchFlatRiskPerKmPercent: pinchRiskPerKm,
      tractionIndexPercent: traction,
    );
  }

  static CobbleDeflectionVerdict _determineVerdict({
    required CobbleTireDeflectionInput input,
    required WheelDeflectionTelemetry front,
    required WheelDeflectionTelemetry rear,
    required double optimalFront,
    required double optimalRear,
  }) {
    if (input.rimType == RimType.hookless &&
        (front.pressureBar > 5.0 || rear.pressureBar > 5.0)) {
      return CobbleDeflectionVerdict.hooklessOverpressure;
    }
    if (front.isRimStrikeImminent || rear.isRimStrikeImminent) {
      return CobbleDeflectionVerdict.imminentRimStrike;
    }
    final double maxOver = math.max(
      front.pressureBar - optimalFront,
      rear.pressureBar - optimalRear,
    );
    if (maxOver >= 0.45) {
      return CobbleDeflectionVerdict.tooStiffHighImpedance;
    }
    final double maxUnder = math.max(
      optimalFront - front.pressureBar,
      optimalRear - rear.pressureBar,
    );
    if (maxUnder >= 0.45) {
      return CobbleDeflectionVerdict.excessiveSquirm;
    }
    return CobbleDeflectionVerdict.optimalCompliance;
  }

  static String _buildAdviceSummary({
    required CobbleDeflectionVerdict verdict,
    required WheelDeflectionTelemetry front,
    required WheelDeflectionTelemetry rear,
    required double optimalFront,
    required double optimalRear,
    required double savingsWatts,
    required CobbleSectorRating sectorRating,
  }) {
    switch (verdict) {
      case CobbleDeflectionVerdict.hooklessOverpressure:
        return 'ALARM HOOKLESS: Przekroczono limit 5.0 BAR (72.5 PSI). Obniż ciśnienie do '
            '${optimalFront.toStringAsFixed(2)}/${optimalRear.toStringAsFixed(2)} BAR.';
      case CobbleDeflectionVerdict.imminentRimStrike:
        return 'UWAGA DOBICIE OBRĘCZY na bruku ${sectorRating.stars}★! '
            'Zapas skoku opony spadł poniżej 0.5 mm – dopompuj +0.25 BAR lub zastosuj wkładkę Foam Insert.';
      case CobbleDeflectionVerdict.tooStiffHighImpedance:
        return 'Opona odbija się od kostki ${sectorRating.stars}★: tracisz ${savingsWatts.toStringAsFixed(1)} W '
            'wibracji. Zejdź do ${optimalFront.toStringAsFixed(2)}F / ${optimalRear.toStringAsFixed(2)}R BAR.';
      case CobbleDeflectionVerdict.excessiveSquirm:
        return 'Zbyt niskie ciśnienie: ugięcie statyczne ${rear.staticDeflectionPercent.toStringAsFixed(1)}% '
            'zwiększa straty histerezy. Zalecane ${optimalFront.toStringAsFixed(2)}F / ${optimalRear.toStringAsFixed(2)}R BAR.';
      case CobbleDeflectionVerdict.optimalCompliance:
        return 'Perfekcyjne tłumienie ${sectorRating.stars}★: ugięcie '
            '${front.staticDeflectionPercent.toStringAsFixed(1)}%F / ${rear.staticDeflectionPercent.toStringAsFixed(1)}%R, '
            'optymalny styk gumy i minimalne straty wibracyjne.';
    }
  }

  static double _roundToStep(double value, double step) {
    return (value / step).round() * step;
  }
}

/// Interaktywny panel telemetryczny fizyki ugięcia opon i strat wibracyjnych
/// na bruku 1★–5★ (zgodny z AppColors, czcionką Inter i responsywnym LayoutBuilder).
class CobbleTirePressureDeflectionPanel extends StatefulWidget {
  final CobbleTireDeflectionInput initialInput;
  final ValueChanged<CobbleDeflectionSnapshot>? onSnapshotChanged;

  const CobbleTirePressureDeflectionPanel({
    super.key,
    this.initialInput = const CobbleTireDeflectionInput(),
    this.onSnapshotChanged,
  });

  @override
  State<CobbleTirePressureDeflectionPanel> createState() =>
      _CobbleTirePressureDeflectionPanelState();
}

class _CobbleTirePressureDeflectionPanelState
    extends State<CobbleTirePressureDeflectionPanel>
    with SingleTickerProviderStateMixin {
  late CobbleTireDeflectionInput _input;
  late CobbleDeflectionSnapshot _snapshot;
  late List<CobblePressureSweepPoint> _sweepCurve;
  late final Ticker _ticker;
  bool _isLiveRunning = false;
  Duration _lastTick = Duration.zero;

  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  static const TextStyle _tabularInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput;
    _recompute(notify: false);
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_isLiveRunning) return;
    final double dt = (_lastTick == Duration.zero)
        ? 0.016
        : ((elapsed - _lastTick).inMicroseconds / 1000000.0).clamp(0.001, 0.1);
    _lastTick = elapsed;
    setState(() {
      _input = _input.copyWith(timeSec: _input.timeSec + dt);
      _snapshot = CobbleTirePressureRealTimeDeflection.evaluateStep(_input);
    });
    widget.onSnapshotChanged?.call(_snapshot);
  }

  void _toggleLiveSimulation() {
    setState(() {
      _isLiveRunning = !_isLiveRunning;
      if (_isLiveRunning) {
        _lastTick = Duration.zero;
        _ticker.start();
      } else {
        _ticker.stop();
      }
    });
  }

  void _updateInput(CobbleTireDeflectionInput next) {
    setState(() {
      _input = next;
      _recompute(notify: true);
    });
  }

  void _applyOptimalPressure() {
    final opt = CobbleTirePressureRealTimeDeflection.computeOptimalCobblePressures(
      _input,
    );
    _updateInput(
      _input.copyWith(
        frontPressureBar: opt.frontBar,
        rearPressureBar: opt.rearBar,
      ),
    );
  }

  void _recompute({required bool notify}) {
    _snapshot = CobbleTirePressureRealTimeDeflection.evaluateStep(_input);
    _sweepCurve = CobbleTirePressureRealTimeDeflection.sweepPressureCurve(_input);
    if (notify) {
      widget.onSnapshotChanged?.call(_snapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1024.0;
        final bool isCompact = width < 680;
        final bool isWideDesktop = width >= 1180;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12.0 : 18.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 14),
                _buildVerdictBanner(),
                const SizedBox(height: 14),
                if (isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildControlsCard(isCompact)),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            _buildVisualizersCard(),
                            const SizedBox(height: 14),
                            _buildTelemetryGrid(isCompact),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildVisualizersCard(),
                  const SizedBox(height: 14),
                  _buildTelemetryGrid(isCompact),
                  const SizedBox(height: 14),
                  _buildControlsCard(isCompact),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAccent),
              ),
              child: const Icon(
                Icons.tire_repair_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cobble Tire Deflection & Vibration Lab',
                    style: _baseInter.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Fizyka ugięcia opon i strat impedancji na bruku ${_input.sectorRating.stars}★',
                    style: _baseInter.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CobbleActionButton(
              label: 'Auto-Optimum',
              icon: Icons.auto_fix_high_rounded,
              accentColor: AppColors.goldAccent,
              onPressed: _applyOptimalPressure,
            ),
            _CobbleActionButton(
              label: _isLiveRunning ? 'Pauza Live' : 'Symulacja Live',
              icon: _isLiveRunning
                  ? Icons.pause_circle_outline_rounded
                  : Icons.play_circle_outline_rounded,
              accentColor:
                  _isLiveRunning ? AppColors.statusSuccess : AppColors.accentBlue,
              isActive: _isLiveRunning,
              onPressed: _toggleLiveSimulation,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerdictBanner() {
    final Color statusColor = switch (_snapshot.verdict) {
      CobbleDeflectionVerdict.optimalCompliance => AppColors.statusSuccess,
      CobbleDeflectionVerdict.tooStiffHighImpedance => AppColors.amberWarning,
      CobbleDeflectionVerdict.excessiveSquirm => AppColors.amberWarning,
      CobbleDeflectionVerdict.imminentRimStrike => AppColors.crimsonAlert,
      CobbleDeflectionVerdict.hooklessOverpressure => AppColors.crimsonAlert,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _snapshot.verdict == CobbleDeflectionVerdict.optimalCompliance
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _snapshot.verdict.titlePl,
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _snapshot.adviceSummary,
                  style: _baseInter.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizersCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Przekrój ugięcia karkasu i krzywa strat (Impedancja vs Histereza)',
            style: _baseInter.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _CobbleDeflectionCrossSectionPainter(
                snapshot: _snapshot,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _CobbleLossCurvePainter(
                points: _sweepCurve,
                currentFrontBar: _snapshot.frontWheel.pressureBar,
                optimalFrontBar: _snapshot.optimalFrontBar,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(bool isCompact) {
    final List<({String label, String value, Color accent})> metrics = [
      (
        label: 'Straty wibracyjne',
        value: '${_snapshot.totalVibrationLossWatts.toStringAsFixed(1)} W',
        accent: _snapshot.potentialSavingsWatts > 5.0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
      ),
      (
        label: 'Impedancja / Histereza',
        value:
            '${_snapshot.impedanceLossWatts.toStringAsFixed(1)}W / ${_snapshot.hysteresisLossWatts.toStringAsFixed(1)}W',
        accent: AppColors.accentBlue,
      ),
      (
        label: 'Ugięcie (Przód / Tył)',
        value:
            '${_snapshot.frontWheel.staticDeflectionPercent.toStringAsFixed(1)}% / ${_snapshot.rearWheel.staticDeflectionPercent.toStringAsFixed(1)}%',
        accent: AppColors.goldAccent,
      ),
      (
        label: 'Wstrząsy RMS / Częst.',
        value:
            '${_snapshot.rmsVerticalAccelerationG.toStringAsFixed(2)} G @ ${_snapshot.vibrationFrequencyHz.toStringAsFixed(0)} Hz',
        accent: _snapshot.rmsVerticalAccelerationG > 3.2
            ? AppColors.crimsonAlert
            : AppColors.cyanAccent,
      ),
      (
        label: 'Zapas dobicia obręczy',
        value:
            '${math.min(_snapshot.frontWheel.rimBottomOutMarginMm, _snapshot.rearWheel.rimBottomOutMarginMm).toStringAsFixed(1)} mm',
        accent: _snapshot.rimStrikeProbabilityPercent > 35.0
            ? AppColors.crimsonAlert
            : AppColors.statusSuccess,
      ),
      (
        label: 'Przyczepność na kostce',
        value: '${_snapshot.overallTractionPercent.toStringAsFixed(0)}%',
        accent: AppColors.emeraldGreen,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isCompact ? 2 : 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: isCompact ? 2.1 : 2.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _tabularInter.copyWith(
                  color: item.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsCard(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfiguracja Ogumienia i Sektora',
            style: _baseInter.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kategoria bruku (1★ – 5★)',
            style: _baseInter.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CobbleSectorRating.values.map((rating) {
              final bool selected = _input.sectorRating == rating;
              return _CobbleActionButton(
                label: '${rating.stars}★',
                accentColor: AppColors.goldAccent,
                isActive: selected,
                onPressed: () =>
                    _updateInput(_input.copyWith(sectorRating: rating)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Wilgotność nawierzchni',
            style: _baseInter.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CobbleSurfaceMoisture.values.map((m) {
              final bool selected = _input.moisture == m;
              return _CobbleActionButton(
                label: m.labelPl,
                accentColor: AppColors.accentBlue,
                isActive: selected,
                onPressed: () => _updateInput(_input.copyWith(moisture: m)),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _buildPressureSlider(
            label: 'Ciśnienie Przód',
            valueBar: _input.frontPressureBar,
            optimalBar: _snapshot.optimalFrontBar,
            onChanged: (v) => _updateInput(
              _input.copyWith(
                frontPressureBar:
                    CobbleTirePressureRealTimeDeflection._roundToStep(v, 0.05),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPressureSlider(
            label: 'Ciśnienie Tył',
            valueBar: _input.rearPressureBar,
            optimalBar: _snapshot.optimalRearBar,
            onChanged: (v) => _updateInput(
              _input.copyWith(
                rearPressureBar:
                    CobbleTirePressureRealTimeDeflection._roundToStep(v, 0.05),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSliderRow(
            label: 'Szerokość opony',
            valueText: '${_input.nominalTireWidthMm} mm',
            value: _input.nominalTireWidthMm.toDouble(),
            min: 25,
            max: 36,
            divisions: 11,
            onChanged: (v) => _updateInput(
              _input.copyWith(nominalTireWidthMm: v.round()),
            ),
          ),
          _buildSliderRow(
            label: 'Prędkość na sektorze',
            valueText: '${_input.speedKmh.toStringAsFixed(0)} km/h',
            value: _input.speedKmh,
            min: 20,
            max: 55,
            divisions: 35,
            onChanged: (v) => _updateInput(_input.copyWith(speedKmh: v)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CobbleActionButton(
                label: _input.hasTireInsert
                    ? 'Foam Insert: WŁ'
                    : 'Foam Insert: WYŁ',
                icon: Icons.shield_outlined,
                accentColor: AppColors.statusSuccess,
                isActive: _input.hasTireInsert,
                onPressed: () => _updateInput(
                  _input.copyWith(hasTireInsert: !_input.hasTireInsert),
                ),
              ),
              _CobbleActionButton(
                label: _input.rimType == RimType.hookless
                    ? 'Obręcz: Hookless'
                    : 'Obręcz: Hooked',
                icon: Icons.circle_outlined,
                accentColor: AppColors.primaryAccent,
                isActive: _input.rimType == RimType.hookless,
                onPressed: () => _updateInput(
                  _input.copyWith(
                    rimType: _input.rimType == RimType.hookless
                        ? RimType.hooked
                        : RimType.hookless,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureSlider({
    required String label,
    required double valueBar,
    required double optimalBar,
    required ValueChanged<double> onChanged,
  }) {
    final double psi = TirePressureCalculator.barToPsi(valueBar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 2,
          children: [
            Text(
              label,
              style: _baseInter.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${valueBar.toStringAsFixed(2)} BAR (${psi.toStringAsFixed(0)} PSI) · Opt ${optimalBar.toStringAsFixed(2)}',
              style: _tabularInter.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: valueBar.clamp(2.0, 7.5),
            min: 2.0,
            max: 7.5,
            divisions: 110,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: _baseInter.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              valueText,
              style: _tabularInter.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accentBlue,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.accentBlue,
            overlayColor: AppColors.accentBlue.withValues(alpha: 0.2),
            trackHeight: 4,
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

/// Przycisk interaktywny z pełną obsługą stanów hover / active / focus / disabled.
class _CobbleActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color accentColor;
  final bool isActive;
  final VoidCallback? onPressed;

  const _CobbleActionButton({
    required this.label,
    required this.accentColor,
    this.icon,
    this.isActive = false,
    this.onPressed,
  });

  @override
  State<_CobbleActionButton> createState() => _CobbleActionButtonState();
}

class _CobbleActionButtonState extends State<_CobbleActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isActive
            ? widget.accentColor.withValues(alpha: _pressed ? 0.34 : 0.24)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused || widget.isActive
            ? widget.accentColor
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.65)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: enabled
                      ? (widget.isActive
                          ? widget.accentColor
                          : AppColors.textSecondary)
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rysuje w czasie rzeczywistym przekrój opony opływającej kamień bruku 5★.
class _CobbleDeflectionCrossSectionPainter extends CustomPainter {
  final CobbleDeflectionSnapshot snapshot;

  const _CobbleDeflectionCrossSectionPainter({required this.snapshot});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = AppColors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );

    // Rysuj zarys kostki brukowej na dole.
    final Paint cobblePaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.fill;
    final double groundY = size.height - 24;
    const int stoneCount = 7;
    final double stoneW = size.width / stoneCount;
    for (int i = 0; i < stoneCount; i++) {
      final double stepJitter =
          (i.isEven ? 1.0 : -0.6) * snapshot.sectorRating.roughnessIndex * 6.0;
      final Rect stoneRect = Rect.fromLTWH(
        i * stoneW + 3,
        groundY - stepJitter,
        stoneW - 6,
        20 + stepJitter,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(stoneRect, const Radius.circular(5)),
        cobblePaint,
      );
    }

    // Rysuj oponę (przód i tył obok siebie).
    _drawWheelCrossSection(
      canvas,
      centerX: size.width * 0.30,
      groundY: groundY,
      wheel: snapshot.frontWheel,
      color: AppColors.accentBlue,
    );
    _drawWheelCrossSection(
      canvas,
      centerX: size.width * 0.70,
      groundY: groundY,
      wheel: snapshot.rearWheel,
      color: AppColors.goldAccent,
    );
  }

  void _drawWheelCrossSection(
    Canvas canvas, {
    required double centerX,
    required double groundY,
    required WheelDeflectionTelemetry wheel,
    required Color color,
  }) {
    final double deflRatio =
        (wheel.dynamicDeflectionPercent / 100.0).clamp(0.05, 0.92);
    const double radius = 36.0;
    final double compressedHeight = radius * (1.0 - deflRatio * 0.55);
    final double centerY = groundY - compressedHeight;

    final Paint tirePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final Paint tireStroke = Paint()
      ..color = wheel.isRimStrikeImminent ? AppColors.crimsonAlert : color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final Rect oval = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: radius * 2.0 + deflRatio * 14.0,
      height: compressedHeight * 2.0,
    );
    canvas.drawOval(oval, tirePaint);
    canvas.drawOval(oval, tireStroke);

    // Obręcz wewnątrz.
    final Paint rimPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.75)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(centerX, centerY - 2), 14.0, rimPaint);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text:
            '${wheel.wheelLabel}: ${wheel.pressureBar.toStringAsFixed(2)} BAR (${wheel.staticDeflectionPercent.toStringAsFixed(0)}%)',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(centerX - tp.width / 2, 8));
  }

  @override
  bool shouldRepaint(covariant _CobbleDeflectionCrossSectionPainter oldDelegate) {
    return oldDelegate.snapshot != snapshot;
  }
}

/// Rysuje krzywą strat mocy (Histereza, Impedancja, Suma) w funkcji ciśnienia.
class _CobbleLossCurvePainter extends CustomPainter {
  final List<CobblePressureSweepPoint> points;
  final double currentFrontBar;
  final double optimalFrontBar;

  const _CobbleLossCurvePainter({
    required this.points,
    required this.currentFrontBar,
    required this.optimalFrontBar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = AppColors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bgPaint,
    );

    if (points.length < 2) return;

    const double padL = 36;
    const double padR = 14;
    const double padT = 16;
    const double padB = 24;
    final double plotW = math.max(10.0, size.width - padL - padR);
    final double plotH = math.max(10.0, size.height - padT - padB);

    final double minP = points.first.pressureBar;
    final double maxP = points.last.pressureBar;
    double maxW = 10.0;
    for (final p in points) {
      if (p.totalLossWatts > maxW) maxW = p.totalLossWatts;
    }
    maxW = math.max(25.0, maxW * 1.12);

    double xForBar(double bar) =>
        padL + ((bar - minP) / math.max(0.1, maxP - minP)) * plotW;
    double yForWatts(double w) => padT + plotH - (w / maxW) * plotH;

    // Linie siatki poziomej.
    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final double y = padT + (plotH / 3) * i;
      canvas.drawLine(Offset(padL, y), Offset(padL + plotW, y), gridPaint);
    }

    final Path hystPath = Path();
    final Path impPath = Path();
    final Path totalPath = Path();

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final double x = xForBar(p.pressureBar);
      final double yh = yForWatts(p.hysteresisWatts);
      final double yi = yForWatts(p.impedanceWatts);
      final double yt = yForWatts(p.totalLossWatts);
      if (i == 0) {
        hystPath.moveTo(x, yh);
        impPath.moveTo(x, yi);
        totalPath.moveTo(x, yt);
      } else {
        hystPath.lineTo(x, yh);
        impPath.lineTo(x, yi);
        totalPath.lineTo(x, yt);
      }
    }

    canvas.drawPath(
      hystPath,
      Paint()
        ..color = AppColors.accentBlue.withValues(alpha: 0.7)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      impPath,
      Paint()
        ..color = AppColors.crimsonAlert.withValues(alpha: 0.75)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      totalPath,
      Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );

    // Linia optimum.
    final double optX = xForBar(optimalFrontBar.clamp(minP, maxP));
    canvas.drawLine(
      Offset(optX, padT),
      Offset(optX, padT + plotH),
      Paint()
        ..color = AppColors.statusSuccess
        ..strokeWidth = 1.5,
    );

    // Linia aktualnego ciśnienia.
    final double curX = xForBar(currentFrontBar.clamp(minP, maxP));
    canvas.drawLine(
      Offset(curX, padT),
      Offset(curX, padT + plotH),
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 1.8,
    );

    // Etykiety osi.
    final TextPainter maxLabel = TextPainter(
      text: TextSpan(
        text: '${maxW.toStringAsFixed(0)}W',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    maxLabel.paint(canvas, const Offset(4, padT - 4));

    final TextPainter legend = TextPainter(
      text: const TextSpan(
        text: 'Suma (Złoty) · Impedancja (Czerwony) · Histereza (Niebieski)',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    legend.paint(canvas, Offset(padL, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant _CobbleLossCurvePainter oldDelegate) {
    return oldDelegate.currentFrontBar != currentFrontBar ||
        oldDelegate.optimalFrontBar != optimalFrontBar ||
        oldDelegate.points != points;
  }
}
