// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../core/constants/physics_constants.dart';
import '../../models/equipment/tire_model.dart';
import '../../models/race/stage_segment.dart';

/// Typ mieszanki gumowej opony wpływający na przyczepność na sucho i mokro.
enum TireCompoundType {
  /// Miękka mieszanka wyścigowa (wysoka przyczepność, szybsze zużycie).
  softRace('Soft Race Compound', 'Miękka mieszanka wyścigowa', 1.05, 1.06, 46.0),

  /// Mieszanka całoroczna / deszczowa (maksymalne odprowadzanie wody i chłód).
  allSeasonWet('All-Season Wet', 'Mieszanka deszczowa / całoroczna', 0.99, 1.12, 44.0),

  /// Standardowa mieszanka szosowa WorldTour.
  standardRace('Standard Race', 'Standardowa mieszanka wyścigowa', 1.00, 1.00, 44.0),

  /// Twarda mieszanka czasowa (minimalny Crr, niższa przyczepność w deszczu).
  hardTimeTrial('Hard TT Compound', 'Twarda mieszanka czasowa', 0.95, 0.86, 40.0),

  /// Wzmocniona mieszanka na bruk i szuter.
  cobbleReinforced('Cobble Reinforced', 'Mieszanka brukowa / endurance', 0.98, 1.05, 42.0);

  final String labelEn;
  final String labelPl;
  final double dryGripMultiplier;
  final double wetGripMultiplier;
  final double maxTreadLeanAngleDeg;

  const TireCompoundType(
    this.labelEn,
    this.labelPl,
    this.dryGripMultiplier,
    this.wetGripMultiplier,
    this.maxTreadLeanAngleDeg,
  );
}

/// Typ układu hamulcowego wpływający na modulację i skuteczność hamowania w deszczu.
enum BrakeSystemType {
  /// Hydrauliczne hamulce tarczowe (stała siła i modulacja w ulewie).
  hydraulicDisc('Hydraulic Disc', 'Hamulce tarczowe hydrauliczne', 1.00, 0.94),

  /// Hamulce szczękowe z karbonową powierzchnią cierną (opóźniona reakcja na mokro).
  carbonRim('Carbon Rim Brake', 'Szczękowe (obręcz karbonowa)', 0.94, 0.68),

  /// Hamulce szczękowe z aluminiową powierzchnią cierną.
  aluminumRim('Aluminum Rim Brake', 'Szczękowe (obręcz aluminiowa)', 0.95, 0.80);

  final String labelEn;
  final String labelPl;
  final double dryBrakeEfficiency;
  final double wetBrakeEfficiency;

  const BrakeSystemType(
    this.labelEn,
    this.labelPl,
    this.dryBrakeEfficiency,
    this.wetBrakeEfficiency,
  );
}

/// Poziom ryzyka utraty przyczepności w zakręcie.
enum CorneringRiskLevel {
  safe('Safe', 'Bezpiecznie'),
  moderate('Moderate', 'Na granicy komfortu'),
  high('High Risk', 'Wysokie ryzyko uślizgu'),
  criticalSlip('Critical Slip', 'Zerwanie przyczepności');

  final String labelEn;
  final String labelPl;

  const CorneringRiskLevel(this.labelEn, this.labelPl);
}

/// Dane wejściowe do solvera przyczepności w zakrętach i hamowania.
class WetCorneringInput {
  /// Promień zakrętu $R$ w metrach [m].
  final double cornerRadiusMeters;

  /// Aktualna prędkość najazdu w metrach na sekundę [m/s].
  final double currentSpeedMs;

  /// Dystans do punktu wejścia w zakręt (apex) [m].
  final double distanceToCornerMeters;

  /// Rodzaj nawierzchni segmentu.
  final SegmentSurfaceType surfaceType;

  /// Stopień zawilgocenia nawierzchni (`0.0` = sucho, `1.0` = ulewa / stojąca woda).
  final double surfaceWetness;

  /// Ciśnienie w oponie [bar].
  final double tirePressureBar;

  /// Opcjonalne ciśnienie optymalne [bar]; jeśli `null`, wyliczane z szerokości i nawierzchni.
  final double? optimalPressureBar;

  /// Opcjonalny model opony z ekwipunku (dostarcza `wetGripIndex`, `widthMm`, `isTubeless`).
  final TireModel? tireModel;

  /// Mieszanka gumy opony.
  final TireCompoundType tireCompound;

  /// Układ hamulcowy roweru.
  final BrakeSystemType brakeSystem;

  /// Opcjonalny zadany kąt pochylenia roweru [stopnie]; jeśli `null`, wyliczany z dynamiki zakrętu.
  final double? leanAngleDegrees;

  /// Pochylenie poprzeczne drogi (banking) w stopniach (`> 0` profilowany zakręt do środka).
  final double roadCamberDegrees;

  /// Nachylenie podłużne drogi [%] (`< 0` oznacza zjazd).
  final double roadGradientPercent;

  /// Umiejętność zjazdów kolarza (1–100).
  final int descendingSkill;

  /// Umiejętność panowania nad rowerem (1–100).
  final int bikeHandlingSkill;

  /// Masa całkowita kolarza i roweru [kg].
  final double riderAndBikeMassKg;

  const WetCorneringInput({
    required this.cornerRadiusMeters,
    required this.currentSpeedMs,
    this.distanceToCornerMeters = 50.0,
    this.surfaceType = SegmentSurfaceType.smoothAsphalt,
    this.surfaceWetness = 0.0,
    this.tirePressureBar = 5.5,
    this.optimalPressureBar,
    this.tireModel,
    this.tireCompound = TireCompoundType.standardRace,
    this.brakeSystem = BrakeSystemType.hydraulicDisc,
    this.leanAngleDegrees,
    this.roadCamberDegrees = 0.0,
    this.roadGradientPercent = 0.0,
    this.descendingSkill = 75,
    this.bikeHandlingSkill = 75,
    this.riderAndBikeMassKg = 75.0,
  });
}

/// Wynik rozwiązania fizyki przyczepności w zakręcie i hamowania.
class WetCorneringResult {
  /// Bazowy współczynnik tarcia $\mu_{base}$ samej nawierzchni i wody.
  final double baseSurfaceFrictionMu;

  /// Efektywny współczynnik tarcia $\mu$ po uwzględnieniu mieszanki, ciśnienia i pochylenia.
  final double effectiveFrictionMu;

  /// Maksymalna fizyczna prędkość w wirażu $v_{max} = \sqrt{\mu \cdot g \cdot R}$ [m/s].
  final double maxCorneringSpeedMs;

  /// Maksymalna fizyczna prędkość w wirażu [km/h].
  double get maxCorneringSpeedKmh => maxCorneringSpeedMs * 3.6;

  /// Bezpieczna prędkość docelowa uwzględniająca margines techniczny kolarza [m/s].
  final double targetEntrySpeedMs;

  /// Bezpieczna prędkość docelowa [km/h].
  double get targetEntrySpeedKmh => targetEntrySpeedMs * 3.6;

  /// Wymagany kąt pochylenia dla prędkości najazdu i promienia $R$ [stopnie].
  final double requiredLeanAngleDegrees;

  /// Maksymalny bezpieczny kąt pochylenia przy obecnym $\mu$ [stopnie].
  final double maxSafeLeanAngleDegrees;

  /// Zastosowany kąt pochylenia w obliczeniach [stopnie].
  final double appliedLeanAngleDegrees;

  /// Maksymalne dostępne opóźnienie hamowania [m/s²].
  final double maxBrakingDecelerationMs2;

  /// Wymagane opóźnienie do wyhamowania przed zakrętem [m/s²].
  final double requiredBrakingDecelerationMs2;

  /// Droga hamowania do $v_{max}$ przy maksymalnym opóźnieniu [m].
  final double brakingDistanceMeters;

  /// Czas potrzebny na wyhamowanie do $v_{max}$ [s].
  final double brakingTimeSeconds;

  /// Czy aktualna prędkość wymaga hamowania przed zakrętem.
  final bool needsBraking;

  /// Czy kolarz zdąży wyhamować przed wejściem w zakręt na dostępnym dystansie.
  final bool canBrakeInTime;

  /// Wykorzystanie koła tarcia (Kamm's circle): `<= 1.0` oznacza utrzymanie przyczepności.
  final double gripUtilization;

  /// Ocena ryzyka poślizgu w zakręcie.
  final CorneringRiskLevel riskLevel;

  /// Prawdopodobieństwo uślizgu / kraksy (`0.0`–`1.0`).
  final double slipProbability;

  /// Prędkość kolarza na wejściu w zakręt po zastosowaniu dostępnego hamowania [m/s].
  final double speedAtCornerEntryMs;

  const WetCorneringResult({
    required this.baseSurfaceFrictionMu,
    required this.effectiveFrictionMu,
    required this.maxCorneringSpeedMs,
    required this.targetEntrySpeedMs,
    required this.requiredLeanAngleDegrees,
    required this.maxSafeLeanAngleDegrees,
    required this.appliedLeanAngleDegrees,
    required this.maxBrakingDecelerationMs2,
    required this.requiredBrakingDecelerationMs2,
    required this.brakingDistanceMeters,
    required this.brakingTimeSeconds,
    required this.needsBraking,
    required this.canBrakeInTime,
    required this.gripUtilization,
    required this.riskLevel,
    required this.slipProbability,
    required this.speedAtCornerEntryMs,
  });
}

/// Solver fizyki przyczepności w zakrętach oraz hamowania na suchej i mokrej nawierzchni.
///
/// Maksymalna prędkość w wirażu o promieniu $R$ jest ograniczona przez:
/// $$v_{max} = \sqrt{\mu \cdot g \cdot R}$$
/// gdzie współczynnik tarcia $\mu$ zależy od nawierzchni i wody
/// ($\mu_{dry} \approx 0.85$, $\mu_{wet} \approx 0.55$, $\mu_{wet\_cobble} \approx 0.40$),
/// mieszanki opony, ciśnienia roboczego oraz kąta pochylenia.
class WetCorneringGripAndBrakingSolver {
  WetCorneringGripAndBrakingSolver._();

  // Bazowe współczynniki tarcia nawierzchni
  static const double muDrySmoothAsphalt = 0.85;
  static const double muWetAsphalt = 0.55;
  static const double muDryRoughAsphalt = 0.82;
  static const double muWetRoughAsphalt = 0.53;
  static const double muDryCobblestones = 0.68;
  static const double muWetCobblestones = 0.40;
  static const double muDryGravel = 0.58;
  static const double muWetGravel = 0.43;
  static const double muDryConcrete = 0.80;
  static const double muWetConcrete = 0.48;

  static const double _minRadiusMeters = 2.0;
  static const double _maxRadiusMeters = 5000.0;

  /// Wylicza bazowy współczynnik tarcia nawierzchni $\mu_{base}$ z płynną interpolacją
  /// między warunkami suchymi (`surfaceWetness = 0.0`) a pełnym deszczem (`1.0`).
  static double calculateBaseSurfaceFriction({
    required SegmentSurfaceType surfaceType,
    required double surfaceWetness,
  }) {
    final double w = surfaceWetness.clamp(0.0, 1.0);
    final (double dryMu, double wetMu) = switch (surfaceType) {
      SegmentSurfaceType.smoothAsphalt => (muDrySmoothAsphalt, muWetAsphalt),
      SegmentSurfaceType.roughAsphalt => (muDryRoughAsphalt, muWetRoughAsphalt),
      SegmentSurfaceType.cobblestonesSector1 => (0.72, 0.44),
      SegmentSurfaceType.cobblestonesSector2 => (0.70, 0.42),
      SegmentSurfaceType.cobblestonesSector3 => (muDryCobblestones, muWetCobblestones),
      SegmentSurfaceType.cobblestonesSector4 => (0.65, 0.38),
      SegmentSurfaceType.cobblestonesSector5 => (0.62, 0.36),
      SegmentSurfaceType.gravelStrade => (muDryGravel, muWetGravel),
      SegmentSurfaceType.concrete => (muDryConcrete, muWetConcrete),
    };

    // Pierwsze krople deszczu ("first-rain film") dają silniejszy spadek tarcia na początku.
    final double nonLinearWetness = math.pow(w, 0.82).toDouble();
    return dryMu + (wetMu - dryMu) * nonLinearWetness;
  }

  /// Szacuje optymalne ciśnienie bazowe [bar] dla danej szerokości opony, nawierzchni i wody.
  static double estimateOptimalPressureBar({
    required int tireWidthMm,
    required SegmentSurfaceType surfaceType,
    required double surfaceWetness,
    bool isTubeless = true,
  }) {
    final int width = tireWidthMm.clamp(23, 42);
    // Bazowe ciśnienie dla 28 mm na gładkim suchym asfalcie ~ 5.6 bar.
    double baseBar = 5.6 - (width - 28) * 0.24;

    if (surfaceType == SegmentSurfaceType.gravelStrade) {
      baseBar *= 0.72;
    } else if (_isCobblestone(surfaceType)) {
      baseBar *= 0.78;
    } else if (surfaceType == SegmentSurfaceType.roughAsphalt) {
      baseBar *= 0.94;
    }

    // Na mokrym asfalcie optymalne ciśnienie jest niższe o ok. 6-8% dla większego styku.
    final double w = surfaceWetness.clamp(0.0, 1.0);
    baseBar *= (1.0 - 0.07 * w);

    if (!isTubeless) {
      baseBar *= 1.05;
    }

    return baseBar.clamp(2.6, 8.5);
  }

  /// Mnożnik przyczepności wynikający z mieszanki opony oraz indeksu `wetGripIndex`.
  static double calculateCompoundFactor({
    required TireCompoundType compound,
    TireModel? tireModel,
    required double surfaceWetness,
  }) {
    final double w = surfaceWetness.clamp(0.0, 1.0);
    double factor = compound.dryGripMultiplier +
        (compound.wetGripMultiplier - compound.dryGripMultiplier) * w;

    if (tireModel != null) {
      // `wetGripIndex` mieści się w zakresie 1.0..5.0 (3.0 = neutralny punkt odniesienia).
      final double clampedWetIndex = tireModel.wetGripIndex.clamp(1.0, 5.0);
      final double wetDelta = (clampedWetIndex - 3.0) * 0.035; // -0.07 .. +0.07
      factor *= (1.0 + wetDelta * (0.25 + 0.75 * w));

      // Szersza opona poprawia powierzchnię styku (contact patch), zwłaszcza na mokrym i nierównym.
      final double widthBonus = ((tireModel.widthMm.clamp(23, 38) - 28) * 0.004) * (0.5 + 0.5 * w);
      factor *= (1.0 + widthBonus);
    }

    return factor.clamp(0.75, 1.22);
  }

  /// Mnożnik przyczepności wynikający z ciśnienia w oponach [bar].
  ///
  /// Zbyt wysokie ciśnienie zmniejsza powierzchnię styku i powoduje podskakiwanie
  /// na mikronierównościach (szczególnie dotkliwe na mokro i na bruku).
  static double calculatePressureFactor({
    required double tirePressureBar,
    required double optimalPressureBar,
    required double surfaceWetness,
    required bool isCobblestone,
    bool isTubeless = true,
  }) {
    final double p = tirePressureBar.clamp(1.8, 10.0);
    final double opt = optimalPressureBar.clamp(2.2, 9.0);
    final double diff = p - opt;
    final double w = surfaceWetness.clamp(0.0, 1.0);

    if (diff >= 0.0) {
      // Przepompowana opona: wyraźna utrata przyczepności na mokrym i bruku.
      final double sensitivity = 0.045 + 0.055 * w + (isCobblestone ? 0.045 : 0.0);
      final double penalty = diff * sensitivity;
      return (1.0 - penalty).clamp(0.68, 1.02);
    } else {
      // Lekko niższe ciśnienie pomaga w przyczepności, ale poniżej -1.2 bar pojawia się pływanie karkasu.
      final double under = -diff;
      final double softLimit = isTubeless ? 1.1 : 0.7;
      if (under <= 0.4) {
        return (1.0 + under * 0.025 * (0.4 + 0.6 * w)).clamp(0.95, 1.02);
      }
      if (under <= softLimit) {
        return (1.01 - (under - 0.4) * 0.03).clamp(0.92, 1.02);
      }
      // Krytycznie niskie ciśnienie: odkształcanie boczne opony w zakręcie.
      final double squirmPenalty = (under - softLimit) * 0.14;
      return (0.98 - squirmPenalty).clamp(0.72, 1.0);
    }
  }

  /// Mnożnik przyczepności zależny od kąta pochylenia roweru względem granicy bieżnika.
  static double calculateLeanAngleGripFactor({
    required double leanAngleDegrees,
    required double maxSafeLeanAngleDegrees,
    required double surfaceWetness,
    TireCompoundType compound = TireCompoundType.standardRace,
  }) {
    final double absLean = leanAngleDegrees.abs().clamp(0.0, 70.0);
    final double w = surfaceWetness.clamp(0.0, 1.0);

    // Powyżej kąta krawędzi bieżnika lub bezpiecznego pochylenia dla danej nawierzchni
    // powierzchnia styku gwałtownie maleje.
    final double treadLimit = compound.maxTreadLeanAngleDeg - 6.0 * w;
    final double effectiveLimit = math.min(maxSafeLeanAngleDegrees, treadLimit);

    if (absLean <= effectiveLimit * 0.85) {
      // Lekkie pochylenie (camber thrust) utrzymuje pełną przyczepność.
      return 1.0;
    }

    if (absLean <= effectiveLimit) {
      final double t = (absLean - effectiveLimit * 0.85) /
          math.max(1.0, effectiveLimit * 0.15);
      return 1.0 - 0.05 * t;
    }

    final double excess = absLean - effectiveLimit;
    return (0.95 - excess * (0.028 + 0.015 * w)).clamp(0.45, 0.95);
  }

  /// Oblicza pełny efektywny współczynnik tarcia $\mu$.
  static double calculateEffectiveFrictionMu({
    required SegmentSurfaceType surfaceType,
    required double surfaceWetness,
    required TireCompoundType tireCompound,
    required double tirePressureBar,
    TireModel? tireModel,
    double? optimalPressureBar,
    double leanAngleDegrees = 0.0,
  }) {
    final double baseMu = calculateBaseSurfaceFriction(
      surfaceType: surfaceType,
      surfaceWetness: surfaceWetness,
    );
    final bool isTubeless = tireModel?.isTubeless ?? true;
    final int widthMm = tireModel?.widthMm ?? 28;
    final double resolvedOptimalBar = optimalPressureBar ??
        estimateOptimalPressureBar(
          tireWidthMm: widthMm,
          surfaceType: surfaceType,
          surfaceWetness: surfaceWetness,
          isTubeless: isTubeless,
        );

    final double compoundFactor = calculateCompoundFactor(
      compound: tireCompound,
      tireModel: tireModel,
      surfaceWetness: surfaceWetness,
    );
    final double pressureFactor = calculatePressureFactor(
      tirePressureBar: tirePressureBar,
      optimalPressureBar: resolvedOptimalBar,
      surfaceWetness: surfaceWetness,
      isCobblestone: _isCobblestone(surfaceType),
      isTubeless: isTubeless,
    );

    final double preLeanMu = (baseMu * compoundFactor * pressureFactor).clamp(0.18, 1.15);
    final double maxSafeLean = math.atan(preLeanMu) * (180.0 / math.pi);

    final double leanFactor = calculateLeanAngleGripFactor(
      leanAngleDegrees: leanAngleDegrees,
      maxSafeLeanAngleDegrees: maxSafeLean,
      surfaceWetness: surfaceWetness,
      compound: tireCompound,
    );

    return (preLeanMu * leanFactor).clamp(0.15, 1.15);
  }

  /// Wylicza maksymalną prędkość w zakręcie [m/s] ze wzoru $v_{max} = \sqrt{\mu \cdot g \cdot R}$
  /// z opcjonalnym uwzględnieniem pochylenia poprzecznego drogi (banking).
  static double calculateMaxCorneringSpeedMs({
    required double frictionMu,
    required double cornerRadiusMeters,
    double roadCamberDegrees = 0.0,
  }) {
    final double mu = frictionMu.clamp(0.05, 1.5);
    final double r = cornerRadiusMeters.clamp(_minRadiusMeters, _maxRadiusMeters);
    const double g = PhysicsConstants.gravity;

    if (roadCamberDegrees.abs() < 0.01) {
      return math.sqrt(mu * g * r);
    }

    // Wzór z pochyleniem poprzecznym drogi alpha:
    // v_max^2 = g * R * (mu + tan(alpha)) / (1 - mu * tan(alpha))
    final double alphaRad = roadCamberDegrees.clamp(-15.0, 25.0) * (math.pi / 180.0);
    final double tanAlpha = math.tan(alphaRad);
    final double numerator = mu + tanAlpha;
    if (numerator <= 0.01) {
      return math.sqrt(0.05 * g * r);
    }
    final double denominator = math.max(0.25, 1.0 - mu * tanAlpha);
    return math.sqrt(g * r * (numerator / denominator));
  }

  /// Rozwiązuje kompletny stan przyczepności w zakręcie oraz parametry hamowania.
  static WetCorneringResult solve(WetCorneringInput input) {
    const double g = PhysicsConstants.gravity;
    final double radius = input.cornerRadiusMeters.clamp(_minRadiusMeters, _maxRadiusMeters);
    final double currentSpeed = math.max(0.0, input.currentSpeedMs);
    final double distance = math.max(0.1, input.distanceToCornerMeters);
    final double wetness = input.surfaceWetness.clamp(0.0, 1.0);

    final double baseMu = calculateBaseSurfaceFriction(
      surfaceType: input.surfaceType,
      surfaceWetness: wetness,
    );

    // Wyznaczamy kąt pochylenia potrzebny przy obecnej prędkości (lub zadany z zewnątrz).
    final double alphaRad = input.roadCamberDegrees.clamp(-15.0, 25.0) * (math.pi / 180.0);
    final double requiredLeanRad = math.atan((currentSpeed * currentSpeed) / (g * radius)) - alphaRad;
    final double requiredLeanDeg = requiredLeanRad * (180.0 / math.pi);
    final double appliedLeanDeg = input.leanAngleDegrees ?? requiredLeanDeg;

    final double effectiveMu = calculateEffectiveFrictionMu(
      surfaceType: input.surfaceType,
      surfaceWetness: wetness,
      tireCompound: input.tireCompound,
      tirePressureBar: input.tirePressureBar,
      tireModel: input.tireModel,
      optimalPressureBar: input.optimalPressureBar,
      leanAngleDegrees: appliedLeanDeg,
    );

    final double maxSafeLeanDeg =
        (math.atan(effectiveMu) + alphaRad) * (180.0 / math.pi);

    final double vMax = calculateMaxCorneringSpeedMs(
      frictionMu: effectiveMu,
      cornerRadiusMeters: radius,
      roadCamberDegrees: input.roadCamberDegrees,
    );

    // Margines techniczny kolarza: lepsi zjazdowcy mogą zbliżyć się do 97% limitu fizycznego,
    // słabsi jadą z zapasem lub ryzykują błędy przy próbie ataku.
    final double skillComposite =
        ((input.descendingSkill.clamp(1, 100) * 0.6) +
                (input.bikeHandlingSkill.clamp(1, 100) * 0.4)) /
            100.0;
    final double skillMargin = 0.84 + 0.13 * skillComposite;
    final double targetEntrySpeed = vMax * skillMargin;

    // Składowa normalna siły ciężkości i wpływ zjazdu na hamowanie.
    final double slopeRad = math.atan(input.roadGradientPercent.clamp(-30.0, 30.0) / 100.0);
    final double cosSlope = math.cos(slopeRad);
    final double sinSlope = math.sin(slopeRad); // < 0 na zjeździe (pcha w dół)

    // Efektywność układu hamulcowego w aktualnych warunkach wodnych.
    final double brakeEff = input.brakeSystem.dryBrakeEfficiency +
        (input.brakeSystem.wetBrakeEfficiency - input.brakeSystem.dryBrakeEfficiency) * wetness;
    final double riderModulation = 0.82 + 0.18 * skillComposite;

    // Dostępna rezerwa w kole tarcia Kamma po odjęciu aktualnego przyspieszenia bocznego.
    final double maxTotalAccel = effectiveMu * g * cosSlope;
    final double currentLatAccel =
        input.leanAngleDegrees != null
            ? g * math.tan(appliedLeanDeg.abs().clamp(0.0, 60.0) * (math.pi / 180.0))
            : 0.0; // Przed zakrętem (na dohamowaniu) jedziemy prosto, chyba że hamujemy w złożeniu.
    final double availableLongGripRatio = math.sqrt(
      math.max(0.05, 1.0 - math.pow(math.min(0.95, currentLatAccel / math.max(0.5, maxTotalAccel)), 2)),
    );

    // Maksymalne opóźnienie na zjeździe musi pokonać składową grawitacyjną g * sin(slope) (na zjeździe sin < 0).
    final double rawTireBrakeDecel = maxTotalAccel * availableLongGripRatio * brakeEff * riderModulation;
    final double maxBrakingDecel = math.max(0.8, rawTireBrakeDecel + g * sinSlope);

    final bool needsBraking = currentSpeed > vMax;
    double brakingDistance = 0.0;
    double brakingTime = 0.0;
    double requiredDecel = 0.0;
    bool canBrakeInTime = true;
    double speedAtEntry = currentSpeed;

    if (needsBraking) {
      final double dvSq = (currentSpeed * currentSpeed) - (vMax * vMax);
      brakingDistance = dvSq / (2.0 * maxBrakingDecel);
      brakingTime = (currentSpeed - vMax) / maxBrakingDecel;
      requiredDecel = dvSq / (2.0 * distance);
      canBrakeInTime = requiredDecel <= maxBrakingDecel;

      if (canBrakeInTime) {
        speedAtEntry = vMax;
      } else {
        final double remainingVSq =
            math.max(0.0, (currentSpeed * currentSpeed) - 2.0 * maxBrakingDecel * distance);
        speedAtEntry = math.sqrt(remainingVSq);
      }
    }

    // Wykorzystanie przyczepności na wejściu w zakręt (koło tarcia).
    final double entryLatAccel = (speedAtEntry * speedAtEntry) / radius;
    final double longRatio = needsBraking && !canBrakeInTime
        ? (requiredDecel / math.max(0.5, maxBrakingDecel)).clamp(0.0, 1.5)
        : 0.0;
    final double latRatio = entryLatAccel / math.max(0.5, maxTotalAccel);
    final double gripUtilization = math.sqrt(latRatio * latRatio + longRatio * longRatio);

    final CorneringRiskLevel riskLevel;
    if (gripUtilization > 1.0) {
      riskLevel = CorneringRiskLevel.criticalSlip;
    } else if (gripUtilization > 0.88) {
      riskLevel = CorneringRiskLevel.high;
    } else if (gripUtilization > 0.72) {
      riskLevel = CorneringRiskLevel.moderate;
    } else {
      riskLevel = CorneringRiskLevel.safe;
    }

    // Prawdopodobieństwo uślizgu rośnie gwałtownie po przekroczeniu 92% wykorzystania tarcia.
    double slipProb = 0.0;
    if (gripUtilization > 0.92) {
      final double over = gripUtilization - 0.92;
      final double skillProtection = 0.65 + 0.35 * (1.0 - skillComposite);
      slipProb = (over * 2.8 * skillProtection).clamp(0.0, 1.0);
    }

    return WetCorneringResult(
      baseSurfaceFrictionMu: baseMu,
      effectiveFrictionMu: effectiveMu,
      maxCorneringSpeedMs: vMax,
      targetEntrySpeedMs: targetEntrySpeed,
      requiredLeanAngleDegrees: requiredLeanDeg,
      maxSafeLeanAngleDegrees: maxSafeLeanDeg,
      appliedLeanAngleDegrees: appliedLeanDeg,
      maxBrakingDecelerationMs2: maxBrakingDecel,
      requiredBrakingDecelerationMs2: requiredDecel,
      brakingDistanceMeters: brakingDistance,
      brakingTimeSeconds: brakingTime,
      needsBraking: needsBraking,
      canBrakeInTime: canBrakeInTime,
      gripUtilization: gripUtilization,
      riskLevel: riskLevel,
      slipProbability: slipProb,
      speedAtCornerEntryMs: speedAtEntry,
    );
  }

  static bool _isCobblestone(SegmentSurfaceType surfaceType) {
    return surfaceType == SegmentSurfaceType.cobblestonesSector1 ||
        surfaceType == SegmentSurfaceType.cobblestonesSector2 ||
        surfaceType == SegmentSurfaceType.cobblestonesSector3 ||
        surfaceType == SegmentSurfaceType.cobblestonesSector4 ||
        surfaceType == SegmentSurfaceType.cobblestonesSector5;
  }
}
