// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import 'wet_cornering_grip_and_braking_solver.dart';

/// Styl balansowania ciałem kolarza w szybkich łukach i serpentynach.
enum CornerBodyBalanceStyle {
  /// Neutralna pozycja w osi roweru (rower i kolarz pochylają się pod tym samym kątem).
  uprightNeutral(
    'Upright Neutral',
    'Neutralna w osi ramy',
    0.0,
    0.0,
    0.0,
  ),

  /// Kontrbalans MTB/CX: rower pochylony głębiej niż tułów (luźna nawierzchnia).
  counterLeanBike(
    'Counter-Lean Bike',
    'Kontrbalans (rower głębiej)',
    -0.06,
    0.02,
    0.0,
  ),

  /// Pozycja aero w szybkim łuku z lekkim przesunięciem bioder do wewnątrz.
  aeroTuckCornering(
    'Aero Tuck Shift',
    'Pozycja Aero + biodro',
    0.07,
    0.05,
    12.0,
  ),

  /// Technika Pro Descender: obniżenie środka ciężkości i wystawienie kolana do wewnątrz zakrętu.
  proDescenderKneeOut(
    'Pro Knee-Out Balance',
    'Balans Pro + wystawienie kolana',
    0.16,
    0.09,
    36.0,
  );

  final String labelEn;
  final String labelPl;

  /// Maksymalne przesunięcie poprzeczne środka ciężkości ciała względem osi roweru [m].
  final double maxLateralBodyShiftMeters;

  /// Obniżenie środka ciężkości kolarza w złożeniu do zakrętu [m].
  final double verticalComDropMeters;

  /// Docelowy kąt odwiedzenia wewnętrznego kolana do szczytu zakrętu [stopnie].
  final double targetKneeOutAngleDeg;

  const CornerBodyBalanceStyle(
    this.labelEn,
    this.labelPl,
    this.maxLateralBodyShiftMeters,
    this.verticalComDropMeters,
    this.targetKneeOutAngleDeg,
  );
}

/// Typ zakrętu determinujący dynamikę wejścia, złożenia i wyjścia.
enum CornerTurnProfile {
  /// Szybki łuk zjazdowy (R = 35–90 m, wysokie prędkości 60–90 km/h).
  fastSweeper('Fast Sweeper', 'Szybki łuk zjazdowy', 48.0, 20.0),

  /// Średni zakręt techniczny (R = 18–35 m).
  technicalBend('Technical Bend', 'Zakręt techniczny', 24.0, 15.0),

  /// Alpejska serpentyna / agrafka 180° (R = 6–14 m).
  alpineHairpin('Alpine Hairpin', 'Serpentyna / Agrafka 180°', 8.5, 11.0),

  /// Szybka szykana (naprzemienne przerzucenie środka ciężkości L -> P).
  highSpeedChicane('High-Speed Chicane', 'Szybka szykana', 19.0, 16.5);

  final String labelEn;
  final String labelPl;
  final double typicalRadiusMeters;
  final double typicalEntrySpeedMs;

  const CornerTurnProfile(
    this.labelEn,
    this.labelPl,
    this.typicalRadiusMeters,
    this.typicalEntrySpeedMs,
  );
}

/// Klasyfikacja stabilności złożenia w zakręcie.
enum CornerLeanStabilityLevel {
  /// Pełna stabilność, duży zapas przyczepności i prześwitu pedałów.
  optimalStable('Optimal Stable', 'Pełna stabilność'),

  /// Agresywne, kontrolowane złożenie na szczycie zakrętu (apex).
  aggressiveApex('Aggressive Apex', 'Agresywny Apex'),

  /// Jazda na granicy limitu przyczepności opony i kąta przechyłu.
  edgeOfGrip('Edge of Grip', 'Granica przyczepności'),

  /// Wysokie ryzyko uślizgu przedniego lub tylnego koła.
  highSideSlipRisk('High Slip Risk', 'Ryzyko uślizgu'),

  /// Krytyczne przekroczenie limitu tarcia lub zahaczenie pedałem o asfalt.
  washoutCritical('Washout Critical', 'Krytyczny uślizg / kraksa');

  final String labelEn;
  final String labelPl;

  const CornerLeanStabilityLevel(this.labelEn, this.labelPl);
}

/// Dane wejściowe dla solvera środka ciężkości i kąta przechyłu w zakręcie.
class CornerLeanPhysicsInput {
  /// Prędkość jazdy w zakręcie [m/s].
  final double speedMs;

  /// Promień krzywizny toru jazdy $R$ [m].
  final double cornerRadiusMeters;

  /// Masa kolarza [kg].
  final double riderMassKg;

  /// Masa roweru wraz z ekwipunkiem [kg].
  final double bikeMassKg;

  /// Wysokość środka ciężkości układu kolarz+rower w pozycji wyprostowanej [m].
  final double nominalComHeightMeters;

  /// Pochylenie poprzeczne drogi (banking) [stopnie] (`> 0` pochylony do wnętrza zakrętu).
  final double roadCamberDegrees;

  /// Rodzaj nawierzchni segmentu.
  final SegmentSurfaceType surfaceType;

  /// Stopień zawilgocenia nawierzchni (`0.0` = suchy asfalt, `1.0` = ulewa).
  final double surfaceWetness;

  /// Mieszanka gumy opony.
  final TireCompoundType tireCompound;

  /// Ciśnienie w oponie [bar].
  final double tirePressureBar;

  /// Wybrany styl balansowania ciałem.
  final CornerBodyBalanceStyle bodyBalanceStyle;

  /// Intensywność wystawienia wewnętrznego kolana (`0.0`–`1.0`).
  final double kneeOutExtensionFactor;

  /// Czy kolarz kręci korbą w zakręcie (zamiast trzymać zewnętrzny pedał w dole na godzinie 6:00).
  final bool isPedalingThroughCorner;

  /// Umiejętność zjazdów kolarza (`1`–`100`).
  final double descendingSkill;

  /// Umiejętność prowadzenia roweru i balansu (`1`–`100`).
  final double bikeHandlingSkill;

  /// Aktualny poziom zmęczenia / wyczerpania W' (`0.0` = świeży, `1.0` = skrajne zmęczenie).
  final double fatigueRatio;

  const CornerLeanPhysicsInput({
    required this.speedMs,
    required this.cornerRadiusMeters,
    this.riderMassKg = 68.0,
    this.bikeMassKg = 7.2,
    this.nominalComHeightMeters = 1.02,
    this.roadCamberDegrees = 0.0,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.surfaceWetness = 0.0,
    this.tireCompound = TireCompoundType.softRace,
    this.tirePressureBar = 5.4,
    this.bodyBalanceStyle = CornerBodyBalanceStyle.proDescenderKneeOut,
    this.kneeOutExtensionFactor = 1.0,
    this.isPedalingThroughCorner = false,
    this.descendingSkill = 82.0,
    this.bikeHandlingSkill = 85.0,
    this.fatigueRatio = 0.1,
  });

  CornerLeanPhysicsInput copyWith({
    double? speedMs,
    double? cornerRadiusMeters,
    double? riderMassKg,
    double? bikeMassKg,
    double? nominalComHeightMeters,
    double? roadCamberDegrees,
    SegmentSurfaceType? surfaceType,
    double? surfaceWetness,
    TireCompoundType? tireCompound,
    double? tirePressureBar,
    CornerBodyBalanceStyle? bodyBalanceStyle,
    double? kneeOutExtensionFactor,
    bool? isPedalingThroughCorner,
    double? descendingSkill,
    double? bikeHandlingSkill,
    double? fatigueRatio,
  }) {
    return CornerLeanPhysicsInput(
      speedMs: speedMs ?? this.speedMs,
      cornerRadiusMeters: cornerRadiusMeters ?? this.cornerRadiusMeters,
      riderMassKg: riderMassKg ?? this.riderMassKg,
      bikeMassKg: bikeMassKg ?? this.bikeMassKg,
      nominalComHeightMeters:
          nominalComHeightMeters ?? this.nominalComHeightMeters,
      roadCamberDegrees: roadCamberDegrees ?? this.roadCamberDegrees,
      surfaceType: surfaceType ?? this.surfaceType,
      surfaceWetness: surfaceWetness ?? this.surfaceWetness,
      tireCompound: tireCompound ?? this.tireCompound,
      tirePressureBar: tirePressureBar ?? this.tirePressureBar,
      bodyBalanceStyle: bodyBalanceStyle ?? this.bodyBalanceStyle,
      kneeOutExtensionFactor:
          kneeOutExtensionFactor ?? this.kneeOutExtensionFactor,
      isPedalingThroughCorner:
          isPedalingThroughCorner ?? this.isPedalingThroughCorner,
      descendingSkill: descendingSkill ?? this.descendingSkill,
      bikeHandlingSkill: bikeHandlingSkill ?? this.bikeHandlingSkill,
      fatigueRatio: fatigueRatio ?? this.fatigueRatio,
    );
  }
}

/// Wynik obliczeń fizyki kąta przechyłu, przesunięcia środka ciężkości i stabilności w zakręcie.
class CornerLeanPhysicsResult {
  /// Teoretyczny kąt przechyłu układu z równania $\theta_{lean} = \arctan\left(\frac{v^2}{g \cdot R}\right)$ [stopnie].
  final double theoreticalLeanAngleDeg;

  /// Efektywny kąt przechyłu środka ciężkości względem normalnej do nawierzchni [stopnie].
  final double effectiveComLeanAngleDeg;

  /// Faktyczny kąt przechyłu ramy roweru po uwzględnieniu balansu ciałem i kolana [stopnie].
  final double bikeFrameLeanAngleDeg;

  /// Kąt pochylenia tułowia kolarza do wnętrza zakrętu [stopnie].
  final double riderTorsoLeanAngleDeg;

  /// Redukcja kąta przechyłu ramy roweru dzięki balansowi ciałem i wystawieniu kolana [stopnie].
  final double bikeLeanReliefDeg;

  /// Kąt odwiedzenia wewnętrznego kolana do wewnątrz zakrętu [stopnie].
  final double insideKneeOutAngleDeg;

  /// Przesunięcie poprzeczne środka ciężkości kolarza do wewnątrz zakrętu [m].
  final double comLateralShiftMeters;

  /// Obniżenie wysokości środka ciężkości układu [m].
  final double effectiveComHeightMeters;

  /// Przyspieszenie dośrodkowe $a_c = v^2 / R$ [m/s^2].
  final double centripetalAccelerationMs2;

  /// Przeciążenie boczne wyrażone w wielokrotnościach $g$ [G].
  final double lateralGForce;

  /// Wypadkowy współczynnik obciążenia normalnego na opony [G].
  final double totalLoadFactorG;

  /// Udział obciążenia na zewnętrzny pedał (`0.50`–`0.95`).
  final double outsidePedalWeightRatio;

  /// Maksymalny dopuszczalny kąt przechyłu dla aktualnej nawierzchni i opony [stopnie] (do 42° na suchym asfalcie).
  final double maxSafeLeanAngleDeg;

  /// Maksymalna bezpieczna prędkość w zakręcie z uwzględnieniem balansu ciałem [m/s].
  final double maxSafeCornerSpeedMs;

  /// Przewidywany zysk prędkości w zakręcie dzięki technice Knee-Out vs jazda sztywna [m/s].
  final double kneeOutSpeedAdvantageMs;

  /// Efektywny współczynnik przyczepności opony $\mu_{eff}$.
  final double effectiveGripCoefficient;

  /// Wykorzystanie dostępnej przyczepności (`0.0`–`1.5+`, `> 1.0` oznacza uślizg).
  final double gripUtilizationRatio;

  /// Indeks stabilności i kontroli w zakręcie (`0.0`–`100.0`).
  final double stabilityIndex;

  /// Ryzyko zahaczenia wewnętrznym pedałem o nawierzchnię (`0.0`–`1.0`).
  final double pedalStrikeRisk;

  /// Prawdopodobieństwo uślizgu lub wywrotki w kroku zakrętu (`0.0`–`1.0`).
  final double crashProbability;

  /// Klasyfikacja poziomu stabilności.
  final CornerLeanStabilityLevel stabilityLevel;

  const CornerLeanPhysicsResult({
    required this.theoreticalLeanAngleDeg,
    required this.effectiveComLeanAngleDeg,
    required this.bikeFrameLeanAngleDeg,
    required this.riderTorsoLeanAngleDeg,
    required this.bikeLeanReliefDeg,
    required this.insideKneeOutAngleDeg,
    required this.comLateralShiftMeters,
    required this.effectiveComHeightMeters,
    required this.centripetalAccelerationMs2,
    required this.lateralGForce,
    required this.totalLoadFactorG,
    required this.outsidePedalWeightRatio,
    required this.maxSafeLeanAngleDeg,
    required this.maxSafeCornerSpeedMs,
    required this.kneeOutSpeedAdvantageMs,
    required this.effectiveGripCoefficient,
    required this.gripUtilizationRatio,
    required this.stabilityIndex,
    required this.pedalStrikeRisk,
    required this.crashProbability,
    required this.stabilityLevel,
  });

  /// Prędkość bezpieczna w km/h.
  double get maxSafeCornerSpeedKmh => maxSafeCornerSpeedMs * 3.6;

  /// Zapas kąta przechyłu przed zerwaniem przyczepności [stopnie].
  double get leanAngleMarginDeg => maxSafeLeanAngleDeg - bikeFrameLeanAngleDeg;
}

/// Specyfikacja pojedynczego zakrętu w symulacji sekwencji serpentyn i łuków.
class CornerSequenceSegment {
  final String id;
  final String name;
  final CornerTurnProfile turnProfile;
  final double radiusMeters;
  final double arcAngleDegrees;
  final double targetSpeedMs;
  final double roadCamberDegrees;
  final SegmentSurfaceType surfaceType;
  final double surfaceWetness;

  const CornerSequenceSegment({
    required this.id,
    required this.name,
    required this.turnProfile,
    required this.radiusMeters,
    required this.arcAngleDegrees,
    required this.targetSpeedMs,
    this.roadCamberDegrees = 0.0,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.surfaceWetness = 0.0,
  });

  /// Długość łuku zakrętu $L = R \cdot \Delta\phi$ [m].
  double get arcLengthMeters =>
      radiusMeters * (arcAngleDegrees * math.pi / 180.0);
}

/// Wynik przejazdu pojedynczego zakrętu w sekwencji.
class CornerSequenceStepOutcome {
  final CornerSequenceSegment segment;
  final CornerLeanPhysicsResult physics;
  final double achievedApexSpeedMs;
  final double segmentTimeSeconds;
  final double timeGainedVsNeutralSeconds;

  const CornerSequenceStepOutcome({
    required this.segment,
    required this.physics,
    required this.achievedApexSpeedMs,
    required this.segmentTimeSeconds,
    required this.timeGainedVsNeutralSeconds,
  });
}

/// Zbiorczy raport przejazdu sekwencji serpentyn i szybkich łuków.
class CornerSequenceSimulationSummary {
  final List<CornerSequenceStepOutcome> steps;
  final double totalTimeSeconds;
  final double totalTimeSavedVsNeutralSeconds;
  final double peakLeanAngleDeg;
  final double peakLateralGForce;
  final double minStabilityIndex;
  final double cumulativeCrashRisk;

  const CornerSequenceSimulationSummary({
    required this.steps,
    required this.totalTimeSeconds,
    required this.totalTimeSavedVsNeutralSeconds,
    required this.peakLeanAngleDeg,
    required this.peakLateralGForce,
    required this.minStabilityIndex,
    required this.cumulativeCrashRisk,
  });
}

/// Silnik fizyki środka ciężkości kolarza i kąta przechyłu w szybkich łukach i serpentynach.
///
/// Implementuje dokładne równanie równowagi momentu przechylającego:
/// $$\theta_{lean} = \arctan\left(\frac{v^2}{g \cdot R}\right)$$
/// z limitem do $42^\circ$ na suchym asfalcie oraz modelowaniem przesunięcia środka ciężkości
/// i wystawienia wewnętrznego kolana do środka zakrętu (*Knee-Out Counter-Balance*)
/// dla obniżenia kąta pochylenia ramy, zwiększenia stabilności i prześwitu korby.
class RiderCenterOfMassAndCornerLeanAngle {
  RiderCenterOfMassAndCornerLeanAngle._();

  /// Maksymalny kąt przechyłu roweru szosowego na suchym asfalcie [stopnie].
  static const double maxDryAsphaltLeanAngleDeg = 42.0;

  /// Kąt przechyłu ramy, powyżej którego pojawia się ryzyko zahaczenia pedałem podczas kręcenia [stopnie].
  static const double pedalingStrikeThresholdDeg = 28.5;

  /// Kąt przechyłu ramy przy zewnętrznym pedale w dole (6:00), przy którym kończy się prześwit [stopnie].
  static const double coastingClearanceLimitDeg = 43.5;

  static const double _degToRad = math.pi / 180.0;
  static const double _radToDeg = 180.0 / math.pi;

  /// Oblicza pełny stan fizyki przechyłu, środka ciężkości i stabilności dla pojedynczego zakrętu.
  static CornerLeanPhysicsResult evaluateCornerLean(
    CornerLeanPhysicsInput input,
  ) {
    final double speed = math.max(0.0, input.speedMs);
    final double radius = math.max(1.5, input.cornerRadiusMeters);
    const double gravity = PhysicsConstants.gravity;

    // 1. Przyspieszenie dośrodkowe i podstawowy kąt przechyłu: theta = atan(v^2 / (g * R))
    final double centripetalAcc = (speed * speed) / radius;
    final double lateralG = centripetalAcc / gravity;
    final double theoreticalLeanRad = math.atan(centripetalAcc / gravity);
    final double theoreticalLeanDeg = theoreticalLeanRad * _radToDeg;

    // 2. Korekta o pochylenie poprzeczne drogi (camber / banking)
    final double camberRad =
        input.roadCamberDegrees.clamp(-12.0, 25.0) * _degToRad;
    final double tangentialAcc =
        centripetalAcc * math.cos(camberRad) - gravity * math.sin(camberRad);
    final double normalAcc =
        math.max(0.5, gravity * math.cos(camberRad) + centripetalAcc * math.sin(camberRad));
    final double effectiveComLeanRad = math.atan2(tangentialAcc, normalAcc);
    final double effectiveComLeanDeg = math.max(0.0, effectiveComLeanRad * _radToDeg);

    final double totalLoadG =
        math.sqrt(tangentialAcc * tangentialAcc + normalAcc * normalAcc) / gravity;

    // 3. Ocena umiejętności i zmęczenia na precyzję balansu ciałem
    final double handlingNorm =
        ((input.bikeHandlingSkill - 40.0) / 60.0).clamp(0.15, 1.15);
    final double descendingNorm =
        ((input.descendingSkill - 40.0) / 60.0).clamp(0.15, 1.15);
    final double skillFactor = (0.55 * handlingNorm + 0.45 * descendingNorm)
        .clamp(0.25, 1.12);
    final double fatiguePenalty = 1.0 - (input.fatigueRatio.clamp(0.0, 1.0) * 0.22);

    final double kneeFactor = input.kneeOutExtensionFactor.clamp(0.0, 1.0);
    final double leanActivation = (effectiveComLeanDeg / 18.0).clamp(0.0, 1.0);

    // 4. Przesunięcie środka ciężkości (CoM) i wystawienie kolana do wewnątrz zakrętu
    final double totalMass =
        math.max(45.0, input.riderMassKg + input.bikeMassKg);
    final double riderMassRatio =
        (input.riderMassKg / totalMass).clamp(0.75, 0.94);

    final double lateralShift =
        input.bodyBalanceStyle.maxLateralBodyShiftMeters *
            kneeFactor *
            leanActivation *
            skillFactor *
            fatiguePenalty;

    final double comDrop =
        input.bodyBalanceStyle.verticalComDropMeters *
            leanActivation *
            (0.7 + 0.3 * skillFactor);
    final double effectiveComHeight =
        math.max(0.65, input.nominalComHeightMeters - comDrop);

    final double insideKneeOutAngleDeg =
        input.bodyBalanceStyle.targetKneeOutAngleDeg *
            kneeFactor *
            leanActivation *
            (0.8 + 0.2 * skillFactor);

    // Redukcja kąta pochylenia ramy roweru dzięki przesunięciu CoM kolarza do środka łuku:
    // delta_theta = atan((m_rider * delta_y) / (m_total * h_CoM))
    final double rawReliefRad = math.atan(
      (riderMassRatio * lateralShift) / effectiveComHeight,
    );
    // Dodatkowy moment stabilizujący z wystawienia kolana (opór aerodynamiczny + tłumienie odchylenia)
    final double kneeAeroStabilizationDeg =
        (insideKneeOutAngleDeg / 36.0) * 1.15 * leanActivation;

    final double bikeLeanReliefDeg =
        (rawReliefRad * _radToDeg + kneeAeroStabilizationDeg)
            .clamp(-4.5, 7.2);

    final double bikeFrameLeanDeg =
        math.max(0.0, effectiveComLeanDeg - bikeLeanReliefDeg);

    final double riderTorsoLeanDeg =
        (effectiveComLeanDeg + (bikeLeanReliefDeg * 0.65)).clamp(0.0, 52.0);

    // 5. Dociążenie zewnętrznego pedału (przy zjeździe bez pedałowania: noga zewnętrzna na 6:00)
    final double outsidePedalWeightRatio = input.isPedalingThroughCorner
        ? 0.54
        : (0.62 + 0.28 * (effectiveComLeanDeg / maxDryAsphaltLeanAngleDeg))
            .clamp(0.55, 0.94);

    // 6. Przyczepność nawierzchni i limit kąta przechyłu (do 42° na suchym asfalcie)
    final double muEff = _computeEffectiveGrip(input);
    // Kąt graniczny wynikający z tarcia: theta_max = atan(mu_eff) + camber,
    // przycięty do maksymalnego fizycznego przechyłu opony szosowej (42° na suchym asfalcie)
    final double frictionLimitDeg =
        (math.atan(muEff) * _radToDeg) + (input.roadCamberDegrees * 0.65);

    final double surfaceMaxLeanCap = _surfaceMaxLeanCap(
      input.surfaceType,
      input.surfaceWetness,
    );
    final double compoundBonus =
        (input.tireCompound.maxTreadLeanAngleDeg - 44.0) * 0.45;
    final double skillGripBonus = (skillFactor - 0.8) * 2.2;

    final double maxSafeLeanDeg = math
        .min(frictionLimitDeg, surfaceMaxLeanCap + compoundBonus + skillGripBonus)
        .clamp(16.0, maxDryAsphaltLeanAngleDeg);

    // Maksymalna bezpieczna prędkość z uwzględnieniem redukcji przechyłu przez balans ciałem
    final double effectiveMaxTotalLeanRad =
        (maxSafeLeanDeg + math.max(0.0, bikeLeanReliefDeg)) * _degToRad +
            (camberRad * 0.5);
    final double maxSafeSpeedMs = math.sqrt(
      math.max(
        1.0,
        gravity * radius * math.tan(effectiveMaxTotalLeanRad.clamp(0.15, 1.05)),
      ),
    );

    final double neutralMaxSpeedMs = math.sqrt(
      math.max(
        1.0,
        gravity *
            radius *
            math.tan((maxSafeLeanDeg * _degToRad + camberRad * 0.5).clamp(0.15, 1.0)),
      ),
    );
    final double kneeOutSpeedAdvantageMs =
        math.max(0.0, maxSafeSpeedMs - neutralMaxSpeedMs);

    // 7. Ryzyko zahaczenia pedałem i uślizgu
    double pedalStrikeRisk = 0.0;
    if (input.isPedalingThroughCorner &&
        bikeFrameLeanDeg > pedalingStrikeThresholdDeg) {
      pedalStrikeRisk =
          ((bikeFrameLeanDeg - pedalingStrikeThresholdDeg) / 9.5)
              .clamp(0.0, 1.0);
    } else if (!input.isPedalingThroughCorner &&
        bikeFrameLeanDeg > coastingClearanceLimitDeg - 2.0) {
      pedalStrikeRisk =
          ((bikeFrameLeanDeg - (coastingClearanceLimitDeg - 2.0)) / 4.0)
              .clamp(0.0, 1.0);
    }

    final double gripUtilization =
        (bikeFrameLeanDeg / math.max(1.0, maxSafeLeanDeg)).clamp(0.0, 1.65);

    final double stabilityBonusFromKnee =
        (insideKneeOutAngleDeg / 36.0) * 8.5 + (comDrop * 60.0);
    final double rawStability = 100.0 -
        (math.pow(gripUtilization, 1.55) * 62.0) -
        (pedalStrikeRisk * 34.0) +
        stabilityBonusFromKnee -
        (input.fatigueRatio.clamp(0.0, 1.0) * 8.0);
    final double stabilityIndex = rawStability.clamp(0.0, 100.0);

    final double crashProbability = _computeCrashProbability(
      gripUtilization: gripUtilization,
      pedalStrikeRisk: pedalStrikeRisk,
      skillFactor: skillFactor,
    );

    final CornerLeanStabilityLevel stabilityLevel = _classifyStability(
      gripUtilization: gripUtilization,
      pedalStrikeRisk: pedalStrikeRisk,
    );

    return CornerLeanPhysicsResult(
      theoreticalLeanAngleDeg: theoreticalLeanDeg,
      effectiveComLeanAngleDeg: effectiveComLeanDeg,
      bikeFrameLeanAngleDeg: bikeFrameLeanDeg,
      riderTorsoLeanAngleDeg: riderTorsoLeanDeg,
      bikeLeanReliefDeg: bikeLeanReliefDeg,
      insideKneeOutAngleDeg: insideKneeOutAngleDeg,
      comLateralShiftMeters: lateralShift,
      effectiveComHeightMeters: effectiveComHeight,
      centripetalAccelerationMs2: centripetalAcc,
      lateralGForce: lateralG,
      totalLoadFactorG: totalLoadG,
      outsidePedalWeightRatio: outsidePedalWeightRatio,
      maxSafeLeanAngleDeg: maxSafeLeanDeg,
      maxSafeCornerSpeedMs: maxSafeSpeedMs,
      kneeOutSpeedAdvantageMs: kneeOutSpeedAdvantageMs,
      effectiveGripCoefficient: muEff,
      gripUtilizationRatio: gripUtilization,
      stabilityIndex: stabilityIndex,
      pedalStrikeRisk: pedalStrikeRisk,
      crashProbability: crashProbability,
      stabilityLevel: stabilityLevel,
    );
  }

  /// Oblicza optymalny kąt przechyłu $\theta_{lean} = \arctan\left(\frac{v^2}{g \cdot R}\right)$ w stopniach.
  static double computeIdealLeanAngleDegrees({
    required double speedMs,
    required double cornerRadiusMeters,
  }) {
    final double v = math.max(0.0, speedMs);
    final double r = math.max(1.5, cornerRadiusMeters);
    return math.atan((v * v) / (PhysicsConstants.gravity * r)) * _radToDeg;
  }

  /// Symuluje przejazd przez sekwencję szybkich łuków i serpentyn zjazdowych.
  static CornerSequenceSimulationSummary simulateCorneringSequence({
    required List<CornerSequenceSegment> segments,
    required CornerLeanPhysicsInput baseRiderConfig,
    double aggressivenessRatio = 0.92,
  }) {
    if (segments.isEmpty) {
      return const CornerSequenceSimulationSummary(
        steps: <CornerSequenceStepOutcome>[],
        totalTimeSeconds: 0.0,
        totalTimeSavedVsNeutralSeconds: 0.0,
        peakLeanAngleDeg: 0.0,
        peakLateralGForce: 0.0,
        minStabilityIndex: 100.0,
        cumulativeCrashRisk: 0.0,
      );
    }

    final double aggr = aggressivenessRatio.clamp(0.55, 1.05);
    final List<CornerSequenceStepOutcome> outcomes = <CornerSequenceStepOutcome>[];
    double totalTime = 0.0;
    double totalTimeSaved = 0.0;
    double peakLean = 0.0;
    double peakG = 0.0;
    double minStability = 100.0;
    double survivalProb = 1.0;

    for (final CornerSequenceSegment seg in segments) {
      final CornerLeanPhysicsInput probeInput = baseRiderConfig.copyWith(
        speedMs: seg.targetSpeedMs,
        cornerRadiusMeters: seg.radiusMeters,
        roadCamberDegrees: seg.roadCamberDegrees,
        surfaceType: seg.surfaceType,
        surfaceWetness: seg.surfaceWetness,
      );
      final CornerLeanPhysicsResult probeResult = evaluateCornerLean(probeInput);

      final double apexSpeed = math.min(
        seg.targetSpeedMs,
        probeResult.maxSafeCornerSpeedMs * aggr,
      );
      final CornerLeanPhysicsResult actualResult = evaluateCornerLean(
        probeInput.copyWith(speedMs: apexSpeed),
      );

      final CornerLeanPhysicsResult neutralResult = evaluateCornerLean(
        probeInput.copyWith(
          bodyBalanceStyle: CornerBodyBalanceStyle.uprightNeutral,
          kneeOutExtensionFactor: 0.0,
        ),
      );
      final double neutralApexSpeed = math.min(
        seg.targetSpeedMs,
        neutralResult.maxSafeCornerSpeedMs * aggr,
      );

      final double arcLen = math.max(1.0, seg.arcLengthMeters);
      final double timeTaken = arcLen / math.max(2.0, apexSpeed);
      final double neutralTime = arcLen / math.max(2.0, neutralApexSpeed);
      final double timeSaved = neutralTime - timeTaken;

      totalTime += timeTaken;
      totalTimeSaved += timeSaved;
      peakLean = math.max(peakLean, actualResult.bikeFrameLeanAngleDeg);
      peakG = math.max(peakG, actualResult.lateralGForce);
      minStability = math.min(minStability, actualResult.stabilityIndex);
      survivalProb *= (1.0 - actualResult.crashProbability);

      outcomes.add(
        CornerSequenceStepOutcome(
          segment: seg,
          physics: actualResult,
          achievedApexSpeedMs: apexSpeed,
          segmentTimeSeconds: timeTaken,
          timeGainedVsNeutralSeconds: timeSaved,
        ),
      );
    }

    return CornerSequenceSimulationSummary(
      steps: outcomes,
      totalTimeSeconds: totalTime,
      totalTimeSavedVsNeutralSeconds: totalTimeSaved,
      peakLeanAngleDeg: peakLean,
      peakLateralGForce: peakG,
      minStabilityIndex: minStability,
      cumulativeCrashRisk: (1.0 - survivalProb).clamp(0.0, 1.0),
    );
  }

  /// Zwraca domyślny zestaw serpentyn i łuków alpejskich do testów i podglądu telemetrycznego.
  static List<CornerSequenceSegment> defaultAlpineDescentSequence() {
    return const <CornerSequenceSegment>[
      CornerSequenceSegment(
        id: 'sweeper_1',
        name: 'Szybki łuk Galibier Nord',
        turnProfile: CornerTurnProfile.fastSweeper,
        radiusMeters: 52.0,
        arcAngleDegrees: 55.0,
        targetSpeedMs: 21.5,
        roadCamberDegrees: 2.5,
      ),
      CornerSequenceSegment(
        id: 'chicane_2',
        name: 'Szykana przed tunelem',
        turnProfile: CornerTurnProfile.highSpeedChicane,
        radiusMeters: 22.0,
        arcAngleDegrees: 70.0,
        targetSpeedMs: 14.5,
        roadCamberDegrees: 1.0,
      ),
      CornerSequenceSegment(
        id: 'hairpin_3',
        name: 'Agrafka Alpe d\'Huez #7',
        turnProfile: CornerTurnProfile.alpineHairpin,
        radiusMeters: 8.5,
        arcAngleDegrees: 180.0,
        targetSpeedMs: 9.2,
        roadCamberDegrees: 3.0,
      ),
      CornerSequenceSegment(
        id: 'sweeper_4',
        name: 'Finałowy łuk w dolinie',
        turnProfile: CornerTurnProfile.fastSweeper,
        radiusMeters: 44.0,
        arcAngleDegrees: 62.0,
        targetSpeedMs: 20.0,
        roadCamberDegrees: 2.0,
      ),
    ];
  }

  static double _computeEffectiveGrip(CornerLeanPhysicsInput input) {
    final double wetness = input.surfaceWetness.clamp(0.0, 1.0);
    double dryMu;
    double wetMu;

    switch (input.surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        dryMu = 0.91;
        wetMu = 0.62;
      case SegmentSurfaceType.roughAsphalt:
        dryMu = 0.86;
        wetMu = 0.58;
      case SegmentSurfaceType.concrete:
        dryMu = 0.84;
        wetMu = 0.50;
      case SegmentSurfaceType.gravelStrade:
        dryMu = 0.60;
        wetMu = 0.44;
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
        dryMu = 0.72;
        wetMu = 0.43;
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        dryMu = 0.64;
        wetMu = 0.36;
    }

    final double baseMu = dryMu - (dryMu - wetMu) * wetness;
    final double compoundMult = input.tireCompound.dryGripMultiplier * (1.0 - wetness) +
        input.tireCompound.wetGripMultiplier * wetness;

    // Zbyt wysokie ciśnienie (>6.5 bar) zmniejsza ślad kontaktu i obniża przyczepność
    final double pressureDelta = (input.tirePressureBar - 5.2).abs();
    final double pressureFactor = (1.0 - pressureDelta * 0.025).clamp(0.86, 1.02);

    return (baseMu * compoundMult * pressureFactor).clamp(0.28, 1.05);
  }

  static double _surfaceMaxLeanCap(
    SegmentSurfaceType surfaceType,
    double wetness,
  ) {
    final double w = wetness.clamp(0.0, 1.0);
    switch (surfaceType) {
      case SegmentSurfaceType.smoothAsphalt:
        return maxDryAsphaltLeanAngleDeg - (11.0 * w);
      case SegmentSurfaceType.roughAsphalt:
        return 39.5 - (10.5 * w);
      case SegmentSurfaceType.concrete:
        return 38.0 - (12.0 * w);
      case SegmentSurfaceType.gravelStrade:
        return 27.5 - (6.5 * w);
      case SegmentSurfaceType.cobblestonesSector1:
      case SegmentSurfaceType.cobblestonesSector2:
        return 32.0 - (10.0 * w);
      case SegmentSurfaceType.cobblestonesSector3:
      case SegmentSurfaceType.cobblestonesSector4:
      case SegmentSurfaceType.cobblestonesSector5:
        return 27.0 - (9.0 * w);
    }
  }

  static double _computeCrashProbability({
    required double gripUtilization,
    required double pedalStrikeRisk,
    required double skillFactor,
  }) {
    double slipProb = 0.0;
    if (gripUtilization > 0.94) {
      slipProb = math.pow((gripUtilization - 0.94) * 2.2, 1.65).toDouble();
    }
    final double strikeProb = pedalStrikeRisk * 0.55;
    final double combined =
        (slipProb + strikeProb * (1.0 - slipProb)) / skillFactor.clamp(0.6, 1.15);
    return combined.clamp(0.0, 0.98);
  }

  static CornerLeanStabilityLevel _classifyStability({
    required double gripUtilization,
    required double pedalStrikeRisk,
  }) {
    if (gripUtilization >= 1.05 || pedalStrikeRisk >= 0.75) {
      return CornerLeanStabilityLevel.washoutCritical;
    }
    if (gripUtilization >= 0.95 || pedalStrikeRisk >= 0.45) {
      return CornerLeanStabilityLevel.highSideSlipRisk;
    }
    if (gripUtilization >= 0.84) {
      return CornerLeanStabilityLevel.edgeOfGrip;
    }
    if (gripUtilization >= 0.62) {
      return CornerLeanStabilityLevel.aggressiveApex;
    }
    return CornerLeanStabilityLevel.optimalStable;
  }
}

/// Rysownik wektorowy przedstawiający kąt przechyłu ramy roweru, środek ciężkości (CoM),
/// wystawione wewnętrzne kolano oraz limit $42^\circ$ przyczepności na asfalcie.
class CornerLeanAngleTelemetryPainter extends CustomPainter {
  final CornerLeanPhysicsResult result;
  final double maxLimitDeg;

  const CornerLeanAngleTelemetryPainter({
    required this.result,
    this.maxLimitDeg = RiderCenterOfMassAndCornerLeanAngle.maxDryAsphaltLeanAngleDeg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centerBottom = Offset(size.width * 0.5, size.height * 0.84);
    final double radius = math.min(size.width * 0.40, size.height * 0.66);

    // Linia asfaltu
    final Paint roadPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width * 0.08, centerBottom.dy),
      Offset(size.width * 0.92, centerBottom.dy),
      roadPaint,
    );

    // Pionowa oś odniesienia
    final Paint verticalPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      centerBottom,
      Offset(centerBottom.dx, centerBottom.dy - radius * 1.05),
      verticalPaint,
    );

    // Łuk limitu przyczepności (do 42° na suchym asfalcie)
    final double limitRad = maxLimitDeg * math.pi / 180.0;
    final Paint limitArcPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCircle(center: centerBottom, radius: radius * 0.88),
      -math.pi / 2,
      limitRad,
      false,
      limitArcPaint,
    );

    // Linia limitu maxSafeLeanAngleDeg
    final double safeRad = result.maxSafeLeanAngleDeg * math.pi / 180.0;
    final Offset safeEnd = Offset(
      centerBottom.dx + math.sin(safeRad) * radius * 0.95,
      centerBottom.dy - math.cos(safeRad) * radius * 0.95,
    );
    final Paint safeLimitPaint = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.65)
      ..strokeWidth = 1.5;
    canvas.drawLine(centerBottom, safeEnd, safeLimitPaint);

    // Wektor przechyłu ramy roweru
    final double bikeRad = result.bikeFrameLeanAngleDeg * math.pi / 180.0;
    final Offset bikeTop = Offset(
      centerBottom.dx + math.sin(bikeRad) * radius * 0.72,
      centerBottom.dy - math.cos(bikeRad) * radius * 0.72,
    );
    final Color leanColor = switch (result.stabilityLevel) {
      CornerLeanStabilityLevel.optimalStable => AppColors.statusSuccess,
      CornerLeanStabilityLevel.aggressiveApex => AppColors.accentBlue,
      CornerLeanStabilityLevel.edgeOfGrip => AppColors.goldAccent,
      CornerLeanStabilityLevel.highSideSlipRisk => AppColors.amberWarning,
      CornerLeanStabilityLevel.washoutCritical => AppColors.crimsonAlert,
    };
    final Paint bikePaint = Paint()
      ..color = leanColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(centerBottom, bikeTop, bikePaint);

    // Wektor tułowia / środka ciężkości CoM
    final double comRad = result.effectiveComLeanAngleDeg * math.pi / 180.0;
    final Offset comPoint = Offset(
      centerBottom.dx + math.sin(comRad) * radius * 0.92,
      centerBottom.dy - math.cos(comRad) * radius * 0.92,
    );
    final Paint comLinePaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.85)
      ..strokeWidth = 2.0;
    canvas.drawLine(bikeTop, comPoint, comLinePaint);

    // Wskaźnik wystawionego wewnętrznego kolana
    if (result.insideKneeOutAngleDeg > 2.0) {
      final double kneeRad =
          bikeRad + (result.insideKneeOutAngleDeg * math.pi / 180.0) * 0.55;
      final Offset kneePivot = Offset(
        centerBottom.dx + math.sin(bikeRad) * radius * 0.45,
        centerBottom.dy - math.cos(bikeRad) * radius * 0.45,
      );
      final Offset kneeTip = Offset(
        kneePivot.dx + math.sin(kneeRad) * radius * 0.28,
        kneePivot.dy - math.cos(kneeRad) * radius * 0.14,
      );
      final Paint kneePaint = Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(kneePivot, kneeTip, kneePaint);
      canvas.drawCircle(
        kneeTip,
        4.0,
        Paint()..color = AppColors.goldAccent,
      );
    }

    // Punkt CoM
    canvas.drawCircle(
      comPoint,
      5.5,
      Paint()..color = AppColors.cyanAccent,
    );
    canvas.drawCircle(
      centerBottom,
      4.5,
      Paint()..color = AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant CornerLeanAngleTelemetryPainter oldDelegate) {
    return oldDelegate.result.bikeFrameLeanAngleDeg !=
            result.bikeFrameLeanAngleDeg ||
        oldDelegate.result.effectiveComLeanAngleDeg !=
            result.effectiveComLeanAngleDeg ||
        oldDelegate.result.insideKneeOutAngleDeg !=
            result.insideKneeOutAngleDeg ||
        oldDelegate.result.maxSafeLeanAngleDeg != result.maxSafeLeanAngleDeg;
  }
}

/// Produkcyjny, responsywny panel telemetrii i konfiguratora fizyki przechyłu w zakrętach.
class RiderCenterOfMassAndCornerLeanAnglePanel extends StatefulWidget {
  final CornerLeanPhysicsInput initialInput;
  final ValueChanged<CornerLeanPhysicsResult>? onPhysicsUpdated;
  final bool enabled;

  const RiderCenterOfMassAndCornerLeanAnglePanel({
    super.key,
    this.initialInput = const CornerLeanPhysicsInput(
      speedMs: 19.5,
      cornerRadiusMeters: 28.0,
    ),
    this.onPhysicsUpdated,
    this.enabled = true,
  });

  @override
  State<RiderCenterOfMassAndCornerLeanAnglePanel> createState() =>
      _RiderCenterOfMassAndCornerLeanAnglePanelState();
}

class _RiderCenterOfMassAndCornerLeanAnglePanelState
    extends State<RiderCenterOfMassAndCornerLeanAnglePanel> {
  late CornerLeanPhysicsInput _input;
  late CornerLeanPhysicsResult _result;
  CornerBodyBalanceStyle? _hoveredStyle;
  bool _presetHovered = false;
  bool _presetFocused = false;

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput;
    _result = RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(_input);
  }

  void _updateInput(CornerLeanPhysicsInput next) {
    setState(() {
      _input = next;
      _result = RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(_input);
    });
    widget.onPhysicsUpdated?.call(_result);
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
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 560;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: 14),
                if (isCompact) ...<Widget>[
                  _buildDiagramCard(),
                  const SizedBox(height: 12),
                  _buildMetricsGrid(isCompact: true),
                  const SizedBox(height: 12),
                  _buildControls(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: <Widget>[
                            _buildDiagramCard(),
                            const SizedBox(height: 12),
                            _buildMetricsGrid(isCompact: false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildControls(),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final Color badgeColor = switch (_result.stabilityLevel) {
      CornerLeanStabilityLevel.optimalStable => AppColors.statusSuccess,
      CornerLeanStabilityLevel.aggressiveApex => AppColors.accentBlue,
      CornerLeanStabilityLevel.edgeOfGrip => AppColors.goldAccent,
      CornerLeanStabilityLevel.highSideSlipRisk => AppColors.amberWarning,
      CornerLeanStabilityLevel.washoutCritical => AppColors.crimsonAlert,
    };

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'FIZYKA PRZECHYŁU I ŚRODKA CIĘŻKOŚCI',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'θ_lean = arctan(v² / g·R) • Balans kolanem do wewnątrz łuku',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: badgeColor.withValues(alpha: 0.55)),
          ),
          child: Text(
            _result.stabilityLevel.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagramCard() {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: CornerLeanAngleTelemetryPainter(result: _result),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildMetricsGrid({required bool isCompact}) {
    final List<_TelemetryMetric> metrics = <_TelemetryMetric>[
      _TelemetryMetric(
        label: 'Kąt ramy roweru',
        value: '${_result.bikeFrameLeanAngleDeg.toStringAsFixed(1)}°',
        accent: AppColors.goldAccent,
      ),
      _TelemetryMetric(
        label: 'Kąt CoM (θ_lean)',
        value: '${_result.effectiveComLeanAngleDeg.toStringAsFixed(1)}°',
        accent: AppColors.cyanAccent,
      ),
      _TelemetryMetric(
        label: 'Wystawienie kolana',
        value: '${_result.insideKneeOutAngleDeg.toStringAsFixed(1)}°',
        accent: AppColors.statusSuccess,
      ),
      _TelemetryMetric(
        label: 'Przeciążenie boczne',
        value: '${_result.lateralGForce.toStringAsFixed(2)} G',
        accent: AppColors.accentBlue,
      ),
      _TelemetryMetric(
        label: 'Limit nawierzchni',
        value: '${_result.maxSafeLeanAngleDeg.toStringAsFixed(1)}°',
        accent: AppColors.amberWarning,
      ),
      _TelemetryMetric(
        label: 'Stabilność',
        value: '${_result.stabilityIndex.toStringAsFixed(0)}%',
        accent: AppColors.textPrimary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isCompact ? 2 : 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: isCompact ? 2.5 : 2.1,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _TelemetryMetric m = metrics[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                m.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: m.accent,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.45,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'STYL BALANSU CIAŁEM',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CornerBodyBalanceStyle.values.map((style) {
                  final bool isSelected = _input.bodyBalanceStyle == style;
                  final bool isHovered = _hoveredStyle == style;
                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredStyle = style),
                    onExit: (_) => setState(() => _hoveredStyle = null),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _updateInput(
                        _input.copyWith(bodyBalanceStyle: style),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent.withValues(alpha: 0.28)
                              : isHovered
                                  ? AppColors.background
                                  : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : isHovered
                                    ? AppColors.goldAccent.withValues(alpha: 0.6)
                                    : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          style.labelPl,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _buildSliderRow(
                label: 'Prędkość najazdu',
                valueText: '${(_input.speedMs * 3.6).toStringAsFixed(0)} km/h',
                value: _input.speedMs,
                min: 5.0,
                max: 27.0,
                onChanged: (double v) => _updateInput(_input.copyWith(speedMs: v)),
              ),
              _buildSliderRow(
                label: 'Promień zakrętu (R)',
                valueText: '${_input.cornerRadiusMeters.toStringAsFixed(1)} m',
                value: _input.cornerRadiusMeters,
                min: 6.0,
                max: 70.0,
                onChanged: (double v) =>
                    _updateInput(_input.copyWith(cornerRadiusMeters: v)),
              ),
              _buildSliderRow(
                label: 'Wilgotność asfaltu',
                valueText: '${(_input.surfaceWetness * 100).toStringAsFixed(0)}%',
                value: _input.surfaceWetness,
                min: 0.0,
                max: 1.0,
                onChanged: (double v) =>
                    _updateInput(_input.copyWith(surfaceWetness: v)),
              ),
              const SizedBox(height: 8),
              Focus(
                onFocusChange: (bool focused) =>
                    setState(() => _presetFocused = focused),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _presetHovered = true),
                  onExit: (_) => setState(() => _presetHovered = false),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _updateInput(
                      const CornerLeanPhysicsInput(
                        speedMs: 22.8,
                        cornerRadiusMeters: 58.0,
                        bodyBalanceStyle:
                            CornerBodyBalanceStyle.proDescenderKneeOut,
                        kneeOutExtensionFactor: 1.0,
                      ),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _presetHovered
                            ? AppColors.primaryAccent.withValues(alpha: 0.32)
                            : AppColors.primaryAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _presetFocused
                              ? AppColors.goldAccent
                              : AppColors.primaryAccent,
                        ),
                      ),
                      child: const Text(
                        'Preset: Szybki łuk 82 km/h (max 42° na suchym asfalcie)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
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
}

class _TelemetryMetric {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryMetric({
    required this.label,
    required this.value,
    required this.accent,
  });
}
