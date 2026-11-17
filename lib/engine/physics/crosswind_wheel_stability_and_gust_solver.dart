// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/equipment/wheelset_model.dart';
import 'aero_calculator.dart';

/// Kształt profilu obręczy karbonowej wpływający na położenie środka parcia wiatru.
enum RimProfileShape {
  /// Klasyczny profil V-shape (ostrzejsze oderwanie strug i większy moment skręcający).
  traditionalVShape(
    'Traditional V-Shape',
    'Klasyczny profil V-shape',
    1.28,
    1.18,
  ),

  /// Nowoczesny profil toroidalny U-shape (łagodniejsze przejście strug, mniejszy moment na kierownicy).
  modernToroidalUShape(
    'Modern Toroidal U-Shape',
    'Nowoczesny profil U-shape',
    0.92,
    0.94,
  );

  final String labelEn;
  final String labelPl;
  final double steeringArmMultiplier;
  final double gustImpulseMultiplier;

  const RimProfileShape(
    this.labelEn,
    this.labelPl,
    this.steeringArmMultiplier,
    this.gustImpulseMultiplier,
  );
}

/// Kategoria wysokości stożka aerodynamicznego koła.
enum RimAerodynamicProfile {
  /// Niski profil górski (<35 mm).
  boxShallow('Shallow (<35 mm)', 'Niski profil (<35 mm)'),

  /// Uniwersalny profil all-round (35–59 mm).
  allRoundMid('Mid-Depth (35–59 mm)', 'Uniwersalny (35–59 mm)'),

  /// Wysoki stożek karbonowy aero (60–85 mm, typowo 65–80 mm).
  deepCarbon65to80('Deep Carbon (65–80 mm)', 'Wysoki stożek (65–80 mm)'),

  /// Pełny dysk czasowy (>=90 mm lub 0 mm).
  fullDiscTt('TT Disc', 'Pełny dysk TT');

  final String labelEn;
  final String labelPl;

  const RimAerodynamicProfile(this.labelEn, this.labelPl);

  /// Klasyfikuje wysokość stożka w milimetrach do kategorii aerodynamicznej.
  static RimAerodynamicProfile fromDepthMm(int rimDepthMm) {
    if (rimDepthMm == 0 || rimDepthMm >= 90) {
      return RimAerodynamicProfile.fullDiscTt;
    }
    if (rimDepthMm >= 60) {
      return RimAerodynamicProfile.deepCarbon65to80;
    }
    if (rimDepthMm >= 35) {
      return RimAerodynamicProfile.allRoundMid;
    }
    return RimAerodynamicProfile.boxShallow;
  }
}

/// Charakterystyka terenu pod kątem ekspozycji na nagłe podmuchy boczne.
enum CrosswindGustEnvironment {
  /// Otwarta równina lub polder (umiarkowana turbulencja, płynny wiatr).
  openPlain('Open Plain', 'Otwarta równina', 1.00, 0.55),

  /// Morski most lub grobla (np. Wielki Bełt — bardzo silne podmuchy bez osłony).
  coastalBridge('Coastal Bridge', 'Morski most / grobla', 1.28, 0.38),

  /// Wyjazd zza lasu lub zabudowań na otwartą przestrzeń (gwałtowny skok impulsu).
  forestBreak('Forest Break', 'Wyjazd z lasu / luki', 1.22, 0.28),

  /// Odsłonięta grań górska na szybkim zjeździe (np. Mont Ventoux).
  mountainRidgeDescent(
    'Mountain Ridge Descent',
    'Grań górska (zjazd)',
    1.25,
    0.34,
  ),

  /// Osłonięta dolina (stłumione podmuchy).
  shelteredValley('Sheltered Valley', 'Osłonięta dolina', 0.72, 0.75);

  final String labelEn;
  final String labelPl;
  final double gustSeverityMultiplier;
  final double typicalRiseTimeSeconds;

  const CrosswindGustEnvironment(
    this.labelEn,
    this.labelPl,
    this.gustSeverityMultiplier,
    this.typicalRiseTimeSeconds,
  );
}

/// Poziom stabilności roweru podczas jazdy na wysokich stożkach przy wietrze bocznym.
enum CrosswindStabilityLevel {
  rockSolid('Rock Solid', 'Pełna stabilność', AppColors.statusSuccess),
  manageable('Manageable', 'Stabilne z korektą', AppColors.accentBlue),
  twitchy('Twitchy', 'Nerwowe prowadzenie', AppColors.amberWarning),
  dangerousSway('Dangerous Sway', 'Niebezpieczne znoszenie', AppColors.powerZone5),
  criticalLossOfControl(
    'Critical Control Loss',
    'Krytyczne ryzyko wywrotki',
    AppColors.crimsonAlert,
  );

  final String labelEn;
  final String labelPl;
  final Color statusColor;

  const CrosswindStabilityLevel(
    this.labelEn,
    this.labelPl,
    this.statusColor,
  );
}

/// Rekomendacja doboru wysokości stożka dla danych warunków wiatrowych.
enum CrosswindWheelRecommendation {
  optimalDeepSection(
    'Keep 65–80 mm Deep Carbon',
    'Zostań przy stożkach 65–80 mm (maksymalny zysk aero)',
  ),
  useMixedDepthFront50Rear80(
    'Mixed Setup: 45–50 mm Front / 65–80 mm Rear',
    'Układ mieszany: 45–50 mm przód / 65–80 mm tył',
  ),
  switchToMidDepth38to50(
    'Switch to Mid-Depth 38–50 mm',
    'Zmień komplet na uniwersalne 38–50 mm',
  ),
  switchToShallowClimbingWheels(
    'Switch to Shallow <35 mm',
    'Wymagane niskie koła <35 mm (zbyt silne podmuchy)',
  );

  final String labelEn;
  final String labelPl;

  const CrosswindWheelRecommendation(this.labelEn, this.labelPl);
}

/// Dane wejściowe do solvera stabilności wysokich stożków i podmuchów bocznych.
class CrosswindWheelStabilityInput {
  /// Prędkość jazdy kolarza [m/s].
  final double riderSpeedMs;

  /// Stała bazowa prędkość wiatru [m/s].
  final double steadyWindSpeedMs;

  /// Szczytowa prędkość wiatru w podmuchu [m/s].
  final double gustPeakSpeedMs;

  /// Kąt wiatru względem osi jazdy [stopnie]: 0° = czołowy, 90° = idealnie boczny, 180° = w plecy.
  final double windRelativeAngleDeg;

  /// Czas narastania podmuchu [s] (krótszy = ostrzejszy impuls na kierownicy).
  final double? gustRiseTimeSeconds;

  /// Wysokość stożka przedniego koła [mm] (np. 65 lub 80; 0/100 oznacza dysk).
  final int frontRimDepthMm;

  /// Wysokość stożka tylnego koła [mm] (np. 65, 80 lub 100 dla dysku).
  final int rearRimDepthMm;

  /// Kształt profilu obręczy.
  final RimProfileShape rimProfileShape;

  /// Dodatkowy współczynnik kary z modelu sprzętu (0.0–1.0).
  final double wheelsetCrosswindPenalty;

  /// Pozycja kolarza na rowerze (wpływa na dźwignię na kierownicy i pewność chwytu).
  final RiderPosition riderPosition;

  /// Łączna masa kolarza i roweru [kg].
  final double riderAndBikeMassKg;

  /// Umiejętność panowania nad rowerem (1–100).
  final int bikeHandlingSkill;

  /// Umiejętność zjazdów (1–100).
  final int descendingSkill;

  /// Poziom zmęczenia kolarza (`0.0` = wypoczęty, `1.0` = skrajne wyczerpanie).
  final double fatigueFactor;

  /// Stopień osłonięcia w peletonie (`0.0` = pełna ekspozycja na rancie, `0.85` = środek peletonu).
  final double pelotonShelterFactor;

  /// Wysokość n.p.m. [m] wpływająca na gęstość powietrza.
  final double altitudeMeters;

  /// Typ otoczenia determinujący gwałtowność podmuchów.
  final CrosswindGustEnvironment environment;

  /// Szerokość jezdni [m] (wyznacza margines bezpieczeństwa przed zjechaniem na pobocze).
  final double roadWidthMeters;

  /// Czy nawierzchnia jest mokra (zmniejsza margines przyczepności opony przy znoszeniu).
  final bool isWetAsphalt;

  const CrosswindWheelStabilityInput({
    required this.riderSpeedMs,
    required this.steadyWindSpeedMs,
    required this.gustPeakSpeedMs,
    this.windRelativeAngleDeg = 90.0,
    this.gustRiseTimeSeconds,
    this.frontRimDepthMm = 65,
    this.rearRimDepthMm = 80,
    this.rimProfileShape = RimProfileShape.modernToroidalUShape,
    this.wheelsetCrosswindPenalty = 0.0,
    this.riderPosition = RiderPosition.hoods,
    this.riderAndBikeMassKg = 74.0,
    this.bikeHandlingSkill = 78,
    this.descendingSkill = 75,
    this.fatigueFactor = 0.15,
    this.pelotonShelterFactor = 0.0,
    this.altitudeMeters = 0.0,
    this.environment = CrosswindGustEnvironment.openPlain,
    this.roadWidthMeters = 6.5,
    this.isWetAsphalt = false,
  });

  /// Tworzy konfigurację wejściową bezpośrednio z modelu kół drużynowych [WheelsetModel].
  factory CrosswindWheelStabilityInput.fromWheelset({
    required WheelsetModel wheelset,
    required double riderSpeedMs,
    required double steadyWindSpeedMs,
    required double gustPeakSpeedMs,
    int? rearRimDepthOverrideMm,
    double windRelativeAngleDeg = 90.0,
    double? gustRiseTimeSeconds,
    RimProfileShape rimProfileShape = RimProfileShape.modernToroidalUShape,
    RiderPosition riderPosition = RiderPosition.hoods,
    double riderAndBikeMassKg = 74.0,
    int bikeHandlingSkill = 78,
    int descendingSkill = 75,
    double fatigueFactor = 0.15,
    double pelotonShelterFactor = 0.0,
    double altitudeMeters = 0.0,
    CrosswindGustEnvironment environment = CrosswindGustEnvironment.openPlain,
    double roadWidthMeters = 6.5,
    bool isWetAsphalt = false,
  }) {
    return CrosswindWheelStabilityInput(
      riderSpeedMs: riderSpeedMs,
      steadyWindSpeedMs: steadyWindSpeedMs,
      gustPeakSpeedMs: gustPeakSpeedMs,
      windRelativeAngleDeg: windRelativeAngleDeg,
      gustRiseTimeSeconds: gustRiseTimeSeconds,
      frontRimDepthMm: wheelset.rimDepthMm,
      rearRimDepthMm: rearRimDepthOverrideMm ?? wheelset.rimDepthMm,
      rimProfileShape: rimProfileShape,
      wheelsetCrosswindPenalty: wheelset.crosswindStabilityPenalty,
      riderPosition: riderPosition,
      riderAndBikeMassKg: riderAndBikeMassKg,
      bikeHandlingSkill: bikeHandlingSkill,
      descendingSkill: descendingSkill,
      fatigueFactor: fatigueFactor,
      pelotonShelterFactor: pelotonShelterFactor,
      altitudeMeters: altitudeMeters,
      environment: environment,
      roadWidthMeters: roadWidthMeters,
      isWetAsphalt: isWetAsphalt,
    );
  }

  /// Zwraca skopiowaną instancję z wybranymi modyfikacjami.
  CrosswindWheelStabilityInput copyWith({
    double? riderSpeedMs,
    double? steadyWindSpeedMs,
    double? gustPeakSpeedMs,
    double? windRelativeAngleDeg,
    double? gustRiseTimeSeconds,
    int? frontRimDepthMm,
    int? rearRimDepthMm,
    RimProfileShape? rimProfileShape,
    double? wheelsetCrosswindPenalty,
    RiderPosition? riderPosition,
    double? riderAndBikeMassKg,
    int? bikeHandlingSkill,
    int? descendingSkill,
    double? fatigueFactor,
    double? pelotonShelterFactor,
    double? altitudeMeters,
    CrosswindGustEnvironment? environment,
    double? roadWidthMeters,
    bool? isWetAsphalt,
  }) {
    return CrosswindWheelStabilityInput(
      riderSpeedMs: riderSpeedMs ?? this.riderSpeedMs,
      steadyWindSpeedMs: steadyWindSpeedMs ?? this.steadyWindSpeedMs,
      gustPeakSpeedMs: gustPeakSpeedMs ?? this.gustPeakSpeedMs,
      windRelativeAngleDeg: windRelativeAngleDeg ?? this.windRelativeAngleDeg,
      gustRiseTimeSeconds: gustRiseTimeSeconds ?? this.gustRiseTimeSeconds,
      frontRimDepthMm: frontRimDepthMm ?? this.frontRimDepthMm,
      rearRimDepthMm: rearRimDepthMm ?? this.rearRimDepthMm,
      rimProfileShape: rimProfileShape ?? this.rimProfileShape,
      wheelsetCrosswindPenalty:
          wheelsetCrosswindPenalty ?? this.wheelsetCrosswindPenalty,
      riderPosition: riderPosition ?? this.riderPosition,
      riderAndBikeMassKg: riderAndBikeMassKg ?? this.riderAndBikeMassKg,
      bikeHandlingSkill: bikeHandlingSkill ?? this.bikeHandlingSkill,
      descendingSkill: descendingSkill ?? this.descendingSkill,
      fatigueFactor: fatigueFactor ?? this.fatigueFactor,
      pelotonShelterFactor: pelotonShelterFactor ?? this.pelotonShelterFactor,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      environment: environment ?? this.environment,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      isWetAsphalt: isWetAsphalt ?? this.isWetAsphalt,
    );
  }
}

/// Wynik obliczeń stabilności stożków i reakcji na podmuchy boczne.
class CrosswindWheelStabilityResult {
  /// Gęstość powietrza na zadanej wysokości [kg/m³].
  final double airDensityKgM3;

  /// Pozorna prędkość napływającego powietrza przy wietrze stałym [m/s].
  final double apparentWindSpeedMs;

  /// Kąt pozornego wiatru (yaw) dla wiatru stałego [stopnie 0°–90°].
  final double apparentYawAngleDeg;

  /// Kąt pozornego wiatru (yaw) w szczycie podmuchu [stopnie 0°–90°].
  final double gustApparentYawAngleDeg;

  /// Boczna siła aerodynamiczna na zestawie kół przy wietrze stałym [N].
  final double steadyLateralForceNewtons;

  /// Szczytowa boczna siła aerodynamiczna podczas podmuchu [N].
  final double gustPeakLateralForceNewtons;

  /// Moment skręcający na przednim kole w wietrze stałym [N·m].
  final double frontSteeringTorqueNm;

  /// Szczytowy impuls momentu skręcającego na kierownicy podczas podmuchu [N·m].
  final double gustPeakSteeringTorqueNm;

  /// Wymagany kąt pochylenia roweru pod wiatr dla zrównoważenia siły stałej [stopnie].
  final double requiredLeanAngleDeg;

  /// Przejściowe znoszenie boczne (odchylenie od toru jazdy) wywołane podmuchem [m].
  final double estimatedLateralSwayMeters;

  /// Znormalizowany indeks niestabilności (`0.0` = idealnie stabilny, `>= 1.0` = utrata kontroli).
  final double instabilityIndex;

  /// Prawdopodobieństwo wywrotki lub wypchnięcia poza jezdnię przy danym podmuchu (`0.0–1.0`).
  final double crashOrRunOffRisk;

  /// Zysk aerodynamiczny (efekt żagla) wysokich stożków przy umiarkowanym kącie yaw [W].
  final double sailingAeroSavingsWatts;

  /// Dodatkowa strata mocy wynikająca z kontrowania kierownicą i podnoszenia sylwetki [W].
  final double stabilityPowerPenaltyWatts;

  /// Bilans mocy: dodatni = strata netto, ujemny = zysk netto dzięki efektowi żagla [W].
  double get netAeroPowerDeltaWatts =>
      stabilityPowerPenaltyWatts - sailingAeroSavingsWatts;

  /// Szacowana redukcja prędkości z powodu ostrożności kolarza w podmuchach [m/s].
  final double speedPenaltyMs;

  /// Klasyfikacja stabilności jazdy.
  final CrosswindStabilityLevel stabilityLevel;

  /// Taktyczno-sprzętowa rekomendacja wysokości stożka.
  final CrosswindWheelRecommendation recommendation;

  /// Czy co najmniej jedno koło znajduje się w zakresie wysokich stożków 65–80 mm.
  final bool isDeepSection65to80;

  /// Krótkie podsumowanie telemetryczne w języku polskim.
  final String summaryPl;

  const CrosswindWheelStabilityResult({
    required this.airDensityKgM3,
    required this.apparentWindSpeedMs,
    required this.apparentYawAngleDeg,
    required this.gustApparentYawAngleDeg,
    required this.steadyLateralForceNewtons,
    required this.gustPeakLateralForceNewtons,
    required this.frontSteeringTorqueNm,
    required this.gustPeakSteeringTorqueNm,
    required this.requiredLeanAngleDeg,
    required this.estimatedLateralSwayMeters,
    required this.instabilityIndex,
    required this.crashOrRunOffRisk,
    required this.sailingAeroSavingsWatts,
    required this.stabilityPowerPenaltyWatts,
    required this.speedPenaltyMs,
    required this.stabilityLevel,
    required this.recommendation,
    required this.isDeepSection65to80,
    required this.summaryPl,
  });
}

/// Pojedyncza próbka czasowa symulacji przejazdu przez strefę podmuchu bocznego.
class CrosswindGustSimulationStep {
  final double timeSeconds;
  final double instantaneousWindSpeedMs;
  final double steeringTorqueNm;
  final double lateralSwayMeters;
  final double counterSteerAngleDeg;
  final double instabilityRatio;

  const CrosswindGustSimulationStep({
    required this.timeSeconds,
    required this.instantaneousWindSpeedMs,
    required this.steeringTorqueNm,
    required this.lateralSwayMeters,
    required this.counterSteerAngleDeg,
    required this.instabilityRatio,
  });
}

/// Wynik czasowej symulacji sekwencji podmuchu bocznego i kontrowania przez kolarza.
class CrosswindGustSequenceResult {
  final CrosswindWheelStabilityResult staticSummary;
  final List<CrosswindGustSimulationStep> steps;
  final double peakLateralSwayMeters;
  final double peakSteeringTorqueNm;
  final double peakCounterSteerAngleDeg;
  final double recoveryTimeSeconds;

  const CrosswindGustSequenceResult({
    required this.staticSummary,
    required this.steps,
    required this.peakLateralSwayMeters,
    required this.peakSteeringTorqueNm,
    required this.peakCounterSteerAngleDeg,
    required this.recoveryTimeSeconds,
  });
}

/// Porównanie różnych wysokości stożków w tych samych warunkach wiatrowych.
class CrosswindWheelDepthComparison {
  final int frontDepthMm;
  final int rearDepthMm;
  final String label;
  final CrosswindWheelStabilityResult result;

  const CrosswindWheelDepthComparison({
    required this.frontDepthMm,
    required this.rearDepthMm,
    required this.label,
    required this.result,
  });
}

/// Solver fizyki podmuchów bocznych na wysokich stożkach karbonowych 65–80 mm.
///
/// Modeluje:
/// - Boczną siłę aerodynamiczną $F_{lat} = \frac{1}{2}\rho V_{app}^2 A_{lat} C_y(\psi)$
/// - Moment skręcający na przedniej osi kierowniczej $\tau_{steer}$ zależny od profilu (V vs U-shape)
/// - Impuls nagłego podmuchu (wyjazd z lasu, most morski, zjazd granią) oraz tłumioną odpowiedź kolarza
/// - Efekt żagla (sailing effect) przy kątach yaw $5^\circ\text{–}18^\circ$ vs straty na kontrowanie i podnoszenie sylwetki
class CrosswindWheelStabilityAndGustSolver {
  CrosswindWheelStabilityAndGustSolver._();

  static const double _standardWheelDiameterMeters = 0.680;
  static const double _nominalForkTrailLeverMeters = 0.058;

  /// Oblicza współczynnik siły bocznej $C_y(\psi)$ dla koła o zadanej głębokości stożka i profilu.
  ///
  /// Kąt [yawDeg] w zakresie 0°–90°. Współczynnik rośnie nieliniowo do ok. 25°–32°,
  /// po czym wchodzi w obszar częściowego oderwania strug przy bardzo dużych kątach.
  static double computeRimSideForceCoefficient({
    required double yawDeg,
    required int rimDepthMm,
    RimProfileShape shape = RimProfileShape.modernToroidalUShape,
  }) {
    final double clampedYaw = yawDeg.clamp(0.0, 90.0);
    if (clampedYaw <= 0.01) return 0.0;

    final double yawRad = clampedYaw * math.pi / 180.0;
    final double effectiveDepth = _effectiveAerodynamicDepthMm(rimDepthMm);

    // Wyższe stożki działają jak profil skrzydła: silniejsze narastanie siły nośnej/bocznej przy małym yaw.
    final double depthFactor = (effectiveDepth / 50.0).clamp(0.35, 2.25);
    final double sinComponent = math.sin(yawRad);
    // Charakterystyczny pik aerodynamiczny w okolicach 22°-30° dla głębokich profili.
    final double airfoilPeak =
        math.exp(-math.pow((clampedYaw - 26.0) / 18.0, 2.0)) *
            0.38 *
            depthFactor;

    final double baseCy = (0.72 * sinComponent + airfoilPeak) *
        (0.65 + 0.35 * depthFactor);

    return (baseCy * shape.gustImpulseMultiplier).clamp(0.0, 2.8);
  }

  /// Rozwiązuje statykę wiatru stałego i dynamikę szczytowego podmuchu bocznego.
  static CrosswindWheelStabilityResult solve(
    CrosswindWheelStabilityInput input,
  ) {
    final double riderSpeed = math.max(0.5, input.riderSpeedMs);
    final double steadyWind = math.max(0.0, input.steadyWindSpeedMs);
    final double gustPeakWind = math.max(steadyWind, input.gustPeakSpeedMs);
    final double shelter = input.pelotonShelterFactor.clamp(0.0, 0.90);

    // Ekspozycja na wiatr po uwzględnieniu osłony w peletonie.
    final double windExposure = 1.0 - shelter;
    final double effectiveSteadyWind = steadyWind * windExposure;
    final double effectiveGustWind = gustPeakWind *
        windExposure *
        input.environment.gustSeverityMultiplier;

    final double airDensity =
        PhysicsConstants.getAirDensityAtAltitude(input.altitudeMeters);

    // Rozkład kąta wiatru (0° = czołowy, 90° = boczny, 180° = w plecy).
    final double normalizedAngleDeg =
        (input.windRelativeAngleDeg.abs() % 360.0);
    final double symmetricAngleDeg =
        normalizedAngleDeg > 180.0 ? 360.0 - normalizedAngleDeg : normalizedAngleDeg;
    final double windAngleRad = symmetricAngleDeg * math.pi / 180.0;

    final double steadyHeadwind = effectiveSteadyWind * math.cos(windAngleRad);
    final double steadyCrosswind = effectiveSteadyWind * math.sin(windAngleRad);
    final double gustHeadwind = effectiveGustWind * math.cos(windAngleRad);
    final double gustCrosswind = effectiveGustWind * math.sin(windAngleRad);

    final double steadyAxial = math.max(0.1, riderSpeed + steadyHeadwind);
    final double steadyApparentSpeed = math.sqrt(
      steadyAxial * steadyAxial + steadyCrosswind * steadyCrosswind,
    );
    final double steadyYawDeg =
        (math.atan2(steadyCrosswind.abs(), steadyAxial) * 180.0 / math.pi)
            .clamp(0.0, 90.0);

    final double gustAxial = math.max(0.1, riderSpeed + gustHeadwind);
    final double gustApparentSpeed = math.sqrt(
      gustAxial * gustAxial + gustCrosswind * gustCrosswind,
    );
    final double gustYawDeg =
        (math.atan2(gustCrosswind.abs(), gustAxial) * 180.0 / math.pi)
            .clamp(0.0, 90.0);

    // Powierzchnia boczna koła przedniego i tylnego [m²] zależna od wysokości stożka.
    final double frontLatArea = _computeWheelLateralAreaM2(input.frontRimDepthMm);
    final double rearLatArea = _computeWheelLateralAreaM2(input.rearRimDepthMm);

    final double steadyFrontCy = computeRimSideForceCoefficient(
      yawDeg: steadyYawDeg,
      rimDepthMm: input.frontRimDepthMm,
      shape: input.rimProfileShape,
    );
    final double steadyRearCy = computeRimSideForceCoefficient(
      yawDeg: steadyYawDeg,
      rimDepthMm: input.rearRimDepthMm,
      shape: input.rimProfileShape,
    );

    final double gustFrontCy = computeRimSideForceCoefficient(
      yawDeg: gustYawDeg,
      rimDepthMm: input.frontRimDepthMm,
      shape: input.rimProfileShape,
    );
    final double gustRearCy = computeRimSideForceCoefficient(
      yawDeg: gustYawDeg,
      rimDepthMm: input.rearRimDepthMm,
      shape: input.rimProfileShape,
    );

    final double steadyQ = 0.5 * airDensity * steadyApparentSpeed * steadyApparentSpeed;
    final double gustQ = 0.5 * airDensity * gustApparentSpeed * gustApparentSpeed;

    final double steadyFrontForce = steadyQ * frontLatArea * steadyFrontCy;
    final double steadyRearForce = steadyQ * rearLatArea * steadyRearCy;
    final double steadyTotalLateralForce = steadyFrontForce + steadyRearForce;

    final double gustFrontForce = gustQ * frontLatArea * gustFrontCy;
    final double gustRearForce = gustQ * rearLatArea * gustRearCy;
    final double gustTotalLateralForce = gustFrontForce + gustRearForce;

    // Moment skręcający na przednim kole [N·m]:
    // Zależy od siły bocznej na przednim kole, ramienia wyprzedzenia widelca i głębokości stożka.
    final double frontDepthNormalized =
        (_effectiveAerodynamicDepthMm(input.frontRimDepthMm) / 65.0)
            .clamp(0.35, 1.55);
    final double steeringLeverMeters = _nominalForkTrailLeverMeters *
        (0.75 + 0.50 * frontDepthNormalized) *
        input.rimProfileShape.steeringArmMultiplier *
        (1.0 + input.wheelsetCrosswindPenalty * 0.25);

    final double steadyTorqueNm = steadyFrontForce * steeringLeverMeters;
    final double riseTime = math.max(
      0.15,
      input.gustRiseTimeSeconds ?? input.environment.typicalRiseTimeSeconds,
    );
    // Impuls dynamiczny: im krótszy czas narastania podmuchu, tym większy szarpnięcie.
    final double dynamicImpulseAmplifier =
        (1.0 + (0.55 / riseTime) * 0.42).clamp(1.0, 2.15);
    final double gustDeltaForce = math.max(0.0, gustFrontForce - steadyFrontForce);
    final double gustPeakTorqueNm =
        (steadyFrontForce + gustDeltaForce * dynamicImpulseAmplifier) *
            steeringLeverMeters;

    // Wymagany kąt pochylenia roweru pod stały wiatr boczny.
    final double massKg = math.max(45.0, input.riderAndBikeMassKg);
    final double riderWeightN = massKg * PhysicsConstants.gravity;
    final double requiredLeanAngleDeg =
        (math.atan2(steadyTotalLateralForce, riderWeightN) * 180.0 / math.pi)
            .clamp(0.0, 28.0);

    // Zdolność kolarza do opanowania kierownicy (masa + technika + chwyt + świeżość).
    final double gripLeverageFactor = _positionLeverageFactor(input.riderPosition);
    final double skillFactor = ((input.bikeHandlingSkill * 0.65 +
                input.descendingSkill * 0.35) /
            100.0)
        .clamp(0.25, 1.0);
    final double fatiguePenalty = 1.0 + input.fatigueFactor.clamp(0.0, 1.0) * 0.55;
    final double wetMarginMultiplier = input.isWetAsphalt ? 1.24 : 1.0;

    // Masa bezwładnościowa stawia opór znoszeniu bocznemu (cięższy kolarz jest stabilniejszy).
    final double massResistance = (massKg / 74.0).clamp(0.68, 1.40);
    final double riderControlCapacityNm =
        11.5 * gripLeverageFactor * (0.55 + 0.70 * skillFactor) / fatiguePenalty;

    // Szacowane chwilowe odchylenie boczne (lane sway) [m] w trakcie podmuchu.
    final double netLateralImpulseForce =
        math.max(0.0, gustTotalLateralForce - steadyTotalLateralForce * 0.75);
    final double reactionDelaySeconds =
        (0.18 + (1.0 - skillFactor) * 0.22) * fatiguePenalty;
    final double rawSwayMeters = 0.5 *
        (netLateralImpulseForce / massKg) *
        reactionDelaySeconds *
        reactionDelaySeconds *
        (1.0 + (gustPeakTorqueNm / math.max(1.0, riderControlCapacityNm)) * 0.65);

    final double estimatedLateralSwayMeters =
        (rawSwayMeters * wetMarginMultiplier / massResistance).clamp(0.0, 2.4);

    // Indeks niestabilności (0.0 - 1.5): kombinacja momentu skręcającego i znoszenia bocznego.
    final double torqueRatio = gustPeakTorqueNm / math.max(1.0, riderControlCapacityNm);
    final double safeLaneMargin = math.max(0.6, input.roadWidthMeters * 0.22);
    final double swayRatio = estimatedLateralSwayMeters / safeLaneMargin;
    final double instabilityIndex =
        (torqueRatio * 0.60 + swayRatio * 0.40).clamp(0.0, 1.5);

    final double crashOrRunOffRisk = instabilityIndex <= 0.60
        ? (instabilityIndex * 0.08).clamp(0.0, 0.05)
        : ((instabilityIndex - 0.60) / 0.65).clamp(0.0, 0.98);

    // Efekt żagla (sailing effect) wysokich stożków przy umiarkowanym kącie yaw (5°-22°).
    final double sailingAeroSavingsWatts = _computeSailingAeroSavingsWatts(
      riderSpeedMs: riderSpeed,
      apparentWindSpeedMs: steadyApparentSpeed,
      yawDeg: steadyYawDeg,
      airDensity: airDensity,
      frontDepthMm: input.frontRimDepthMm,
      rearDepthMm: input.rearRimDepthMm,
      shape: input.rimProfileShape,
      shelterFactor: shelter,
    );

    // Strata mocy z kontrowania kierownicą i konieczności wyjścia z pozycji aero przy niestabilności.
    final double stabilityPowerPenaltyWatts = instabilityIndex <= 0.30
        ? 0.0
        : math.pow(instabilityIndex - 0.30, 1.45) *
            (18.0 + riderSpeed * 1.35);

    // Redukcja prędkości (np. odpuszczenie gazu / dohamowanie na zjeździe przy nerwowym przodzie).
    final double speedPenaltyMs = instabilityIndex <= 0.45
        ? 0.0
        : ((instabilityIndex - 0.45) * riderSpeed * 0.26).clamp(0.0, riderSpeed * 0.45);

    final CrosswindStabilityLevel stabilityLevel =
        _classifyStability(instabilityIndex);
    final CrosswindWheelRecommendation recommendation =
        _recommendWheelSetup(
      instabilityIndex: instabilityIndex,
      frontDepthMm: input.frontRimDepthMm,
      rearDepthMm: input.rearRimDepthMm,
    );

    final bool isDeep65to80 =
        (input.frontRimDepthMm >= 65 && input.frontRimDepthMm <= 80) ||
            (input.rearRimDepthMm >= 65 && input.rearRimDepthMm <= 80);

    final String summaryPl = _buildSummaryPl(
      frontDepthMm: input.frontRimDepthMm,
      rearDepthMm: input.rearRimDepthMm,
      level: stabilityLevel,
      gustTorqueNm: gustPeakTorqueNm,
      swayMeters: estimatedLateralSwayMeters,
    );

    return CrosswindWheelStabilityResult(
      airDensityKgM3: airDensity,
      apparentWindSpeedMs: steadyApparentSpeed,
      apparentYawAngleDeg: steadyYawDeg,
      gustApparentYawAngleDeg: gustYawDeg,
      steadyLateralForceNewtons: steadyTotalLateralForce,
      gustPeakLateralForceNewtons: gustTotalLateralForce,
      frontSteeringTorqueNm: steadyTorqueNm,
      gustPeakSteeringTorqueNm: gustPeakTorqueNm,
      requiredLeanAngleDeg: requiredLeanAngleDeg,
      estimatedLateralSwayMeters: estimatedLateralSwayMeters,
      instabilityIndex: instabilityIndex,
      crashOrRunOffRisk: crashOrRunOffRisk,
      sailingAeroSavingsWatts: sailingAeroSavingsWatts,
      stabilityPowerPenaltyWatts: stabilityPowerPenaltyWatts,
      speedPenaltyMs: speedPenaltyMs,
      stabilityLevel: stabilityLevel,
      recommendation: recommendation,
      isDeepSection65to80: isDeep65to80,
      summaryPl: summaryPl,
    );
  }

  /// Symuluje przejazd przez nagły podmuch boczny w dziedzinie czasu (np. wyjazd na most).
  static CrosswindGustSequenceResult simulateGustSequence(
    CrosswindWheelStabilityInput input, {
    double durationSeconds = 5.0,
    double stepSeconds = 0.05,
    double gustStartSeconds = 1.0,
    double gustHoldSeconds = 1.1,
  }) {
    final CrosswindWheelStabilityResult baseResult = solve(input);
    final double dt = stepSeconds.clamp(0.01, 0.25);
    final double totalDuration = math.max(1.5, durationSeconds);
    final double riseTime = math.max(
      0.15,
      input.gustRiseTimeSeconds ?? input.environment.typicalRiseTimeSeconds,
    );

    final List<CrosswindGustSimulationStep> steps = [];
    double currentSway = 0.0;
    double lateralVelocity = 0.0;
    double peakSway = 0.0;
    double peakTorque = 0.0;
    double peakCounterSteer = 0.0;
    double recoveryTime = 0.0;
    bool gustExited = false;

    final double massKg = math.max(45.0, input.riderAndBikeMassKg);
    final double skillNorm =
        ((input.bikeHandlingSkill * 0.7 + input.descendingSkill * 0.3) / 100.0)
            .clamp(0.25, 1.0);
    final double stiffnessK = 9.0 + skillNorm * 14.0;
    final double dampingC = 4.2 + skillNorm * 4.5;

    for (double t = 0.0; t <= totalDuration + 1e-9; t += dt) {
      final double envelope = _gustEnvelope(
        t: t,
        start: gustStartSeconds,
        riseTime: riseTime,
        holdTime: gustHoldSeconds,
      );

      final double instWind = input.steadyWindSpeedMs +
          (input.gustPeakSpeedMs - input.steadyWindSpeedMs) * envelope;

      final double instTorque = baseResult.frontSteeringTorqueNm +
          (baseResult.gustPeakSteeringTorqueNm - baseResult.frontSteeringTorqueNm) *
              envelope;

      final double extraLateralForce =
          (baseResult.gustPeakLateralForceNewtons -
                  baseResult.steadyLateralForceNewtons) *
              envelope;

      // Równanie tłumionego oscylatora kontrowania toru jazdy kolarza:
      // m * y'' = F_gust(t) - c * y' - k * y
      final double accel =
          (extraLateralForce / massKg) - dampingC * lateralVelocity - stiffnessK * currentSway;
      lateralVelocity += accel * dt;
      currentSway = (currentSway + lateralVelocity * dt).clamp(-0.5, 2.8);

      final double counterSteerDeg =
          (instTorque * 0.72 + currentSway.abs() * 3.8).clamp(0.0, 22.0);
      final double instRatio =
          (baseResult.instabilityIndex * (0.45 + 0.55 * envelope)).clamp(0.0, 1.5);

      if (currentSway.abs() > peakSway) peakSway = currentSway.abs();
      if (instTorque > peakTorque) peakTorque = instTorque;
      if (counterSteerDeg > peakCounterSteer) peakCounterSteer = counterSteerDeg;

      if (t > gustStartSeconds + riseTime + gustHoldSeconds) {
        gustExited = true;
      }
      if (gustExited && currentSway.abs() < 0.04 && recoveryTime == 0.0) {
        recoveryTime = t - (gustStartSeconds + riseTime);
      }

      steps.add(
        CrosswindGustSimulationStep(
          timeSeconds: t,
          instantaneousWindSpeedMs: instWind,
          steeringTorqueNm: instTorque,
          lateralSwayMeters: currentSway.abs(),
          counterSteerAngleDeg: counterSteerDeg,
          instabilityRatio: instRatio,
        ),
      );
    }

    return CrosswindGustSequenceResult(
      staticSummary: baseResult,
      steps: steps,
      peakLateralSwayMeters: peakSway,
      peakSteeringTorqueNm: peakTorque,
      peakCounterSteerAngleDeg: peakCounterSteer,
      recoveryTimeSeconds: recoveryTime > 0.0
          ? recoveryTime
          : (totalDuration - gustStartSeconds),
    );
  }

  /// Porównuje zachowanie różnych głębokości stożków (np. 32, 50, 65, 80 mm) w tym samym wietrze.
  static List<CrosswindWheelDepthComparison> compareRimDepths(
    CrosswindWheelStabilityInput baseInput, {
    List<int> frontDepthsMm = const [32, 50, 65, 80],
  }) {
    return frontDepthsMm.map((depth) {
      final int pairedRear = depth >= 65 ? math.min(80, depth + 15) : depth;
      final CrosswindWheelStabilityResult res = solve(
        baseInput.copyWith(
          frontRimDepthMm: depth,
          rearRimDepthMm: pairedRear,
        ),
      );
      final String label = depth == pairedRear
          ? '$depth mm / $pairedRear mm'
          : '$depth mm / $pairedRear mm';
      return CrosswindWheelDepthComparison(
        frontDepthMm: depth,
        rearDepthMm: pairedRear,
        label: label,
        result: res,
      );
    }).toList();
  }

  static double _gustEnvelope({
    required double t,
    required double start,
    required double riseTime,
    required double holdTime,
  }) {
    if (t < start) return 0.0;
    final double riseEnd = start + riseTime;
    final double holdEnd = riseEnd + holdTime;
    final double decayEnd = holdEnd + riseTime * 1.4;

    if (t < riseEnd) {
      final double u = (t - start) / riseTime;
      // Płynne, lecz strome narastanie S-curve.
      return u * u * (3.0 - 2.0 * u);
    }
    if (t < holdEnd) return 1.0;
    if (t < decayEnd) {
      final double u = 1.0 - (t - holdEnd) / (riseTime * 1.4);
      return u.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  static double _effectiveAerodynamicDepthMm(int rimDepthMm) {
    if (rimDepthMm == 0 || rimDepthMm >= 95) return 125.0;
    return rimDepthMm.clamp(18, 95).toDouble();
  }

  static double _computeWheelLateralAreaM2(int rimDepthMm) {
    // Obręcz stanowi pierścień o średniej średnicy ~0.62 m + powierzchnia szprych/piasty.
    final double depthMeters = _effectiveAerodynamicDepthMm(rimDepthMm) / 1000.0;
    final double circumference = math.pi * (_standardWheelDiameterMeters - depthMeters);
    final double rimArea = circumference * depthMeters;
    const double spokesAndHubArea = 0.022;
    return rimArea + spokesAndHubArea;
  }

  static double _positionLeverageFactor(RiderPosition position) {
    switch (position) {
      case RiderPosition.drops:
        return 1.15; // Najszersza i najpewniejsza kontrola kierownicy
      case RiderPosition.hoods:
        return 1.00;
      case RiderPosition.standing:
        return 0.92;
      case RiderPosition.puppyPaws:
        return 0.62; // Brak bezpośredniego chwytu hamulców i kierownicy
      case RiderPosition.timeTrial:
        return 0.56; // Wąskie lemondki — najmniejsza dźwignia kontrująca
    }
  }

  static double _computeSailingAeroSavingsWatts({
    required double riderSpeedMs,
    required double apparentWindSpeedMs,
    required double yawDeg,
    required double airDensity,
    required int frontDepthMm,
    required int rearDepthMm,
    required RimProfileShape shape,
    required double shelterFactor,
  }) {
    if (yawDeg < 2.0 || yawDeg > 30.0) {
      return 0.0;
    }
    final double avgDepth =
        (_effectiveAerodynamicDepthMm(frontDepthMm) +
            _effectiveAerodynamicDepthMm(rearDepthMm)) *
        0.5;
    if (avgDepth < 40.0) return 0.0;

    // Efekt żagla maksymalizuje się w okolicach 12°-16° yaw dla stożków 65-80 mm.
    final double yawSweetSpot =
        math.exp(-math.pow((yawDeg - 13.5) / 8.5, 2.0));
    final double depthGain = ((avgDepth - 35.0) / 45.0).clamp(0.0, 1.4);
    final double shapeBonus =
        shape == RimProfileShape.modernToroidalUShape ? 1.15 : 0.90;
    final double speedPowerFactor =
        math.pow(apparentWindSpeedMs / 12.5, 2.5).toDouble();

    final double watts = 11.5 *
        yawSweetSpot *
        depthGain *
        shapeBonus *
        speedPowerFactor *
        (airDensity / PhysicsConstants.seaLevelAirDensity) *
        (1.0 - shelterFactor * 0.65) *
        (riderSpeedMs / 12.5).clamp(0.4, 1.6);

    return watts.clamp(0.0, 38.0);
  }

  static CrosswindStabilityLevel _classifyStability(double instabilityIndex) {
    if (instabilityIndex < 0.28) return CrosswindStabilityLevel.rockSolid;
    if (instabilityIndex < 0.48) return CrosswindStabilityLevel.manageable;
    if (instabilityIndex < 0.70) return CrosswindStabilityLevel.twitchy;
    if (instabilityIndex < 0.92) return CrosswindStabilityLevel.dangerousSway;
    return CrosswindStabilityLevel.criticalLossOfControl;
  }

  static CrosswindWheelRecommendation _recommendWheelSetup({
    required double instabilityIndex,
    required int frontDepthMm,
    required int rearDepthMm,
  }) {
    if (instabilityIndex < 0.48) {
      return CrosswindWheelRecommendation.optimalDeepSection;
    }
    if (instabilityIndex < 0.72 && frontDepthMm >= 60) {
      return CrosswindWheelRecommendation.useMixedDepthFront50Rear80;
    }
    if (instabilityIndex < 0.92) {
      return CrosswindWheelRecommendation.switchToMidDepth38to50;
    }
    return CrosswindWheelRecommendation.switchToShallowClimbingWheels;
  }

  static String _buildSummaryPl({
    required int frontDepthMm,
    required int rearDepthMm,
    required CrosswindStabilityLevel level,
    required double gustTorqueNm,
    required double swayMeters,
  }) {
    return 'Stożki $frontDepthMm/$rearDepthMm mm: ${level.labelPl} '
        '(impuls ${gustTorqueNm.toStringAsFixed(1)} N·m, '
        'znoszenie ${swayMeters.toStringAsFixed(2)} m).';
  }
}

/// Interaktywny panel diagnostyczny stabilności wysokich stożków 65–80 mm w podmuchach bocznych.
class CrosswindWheelStabilityPanel extends StatefulWidget {
  final CrosswindWheelStabilityInput initialInput;
  final ValueChanged<CrosswindWheelStabilityResult>? onSolved;

  const CrosswindWheelStabilityPanel({
    super.key,
    this.initialInput = const CrosswindWheelStabilityInput(
      riderSpeedMs: 13.5,
      steadyWindSpeedMs: 8.5,
      gustPeakSpeedMs: 16.5,
      windRelativeAngleDeg: 80.0,
      frontRimDepthMm: 65,
      rearRimDepthMm: 80,
      environment: CrosswindGustEnvironment.coastalBridge,
    ),
    this.onSolved,
  });

  @override
  State<CrosswindWheelStabilityPanel> createState() =>
      _CrosswindWheelStabilityPanelState();
}

class _CrosswindWheelStabilityPanelState
    extends State<CrosswindWheelStabilityPanel> {
  late CrosswindWheelStabilityInput _input;

  @override
  void initState() {
    super.initState();
    _input = widget.initialInput;
  }

  void _updateInput(CrosswindWheelStabilityInput next) {
    setState(() {
      _input = next;
    });
    widget.onSolved?.call(CrosswindWheelStabilityAndGustSolver.solve(next));
  }

  @override
  Widget build(BuildContext context) {
    final CrosswindGustSequenceResult sequence =
        CrosswindWheelStabilityAndGustSolver.simulateGustSequence(_input);
    final CrosswindWheelStabilityResult result = sequence.staticSummary;
    final List<CrosswindWheelDepthComparison> comparisons =
        CrosswindWheelStabilityAndGustSolver.compareRimDepths(_input);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 680;
        final bool isWide = constraints.maxWidth >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(result, isCompact),
                const SizedBox(height: 16),
                _buildControlsSection(isCompact),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildMetricsGrid(result, isCompact)),
                      const SizedBox(width: 16),
                      Expanded(flex: 6, child: _buildGustChartCard(sequence)),
                    ],
                  )
                else ...[
                  _buildMetricsGrid(result, isCompact),
                  const SizedBox(height: 16),
                  _buildGustChartCard(sequence),
                ],
                const SizedBox(height: 16),
                _buildComparisonTable(comparisons, isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(CrosswindWheelStabilityResult result, bool isCompact) {
    final Color statusColor = result.stabilityLevel.statusColor;
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AERODYNAMIKA STOŻKÓW 65–80 MM & PODMUCHY BOCZNE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.recommendation.labelPl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.65)),
          ),
          child: Text(
            result.stabilityLevel.labelPl.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsSection(bool isCompact) {
    final List<({String label, int front, int rear})> wheelPresets = [
      (label: '32 mm', front: 32, rear: 32),
      (label: '50 mm', front: 50, rear: 50),
      (label: '50/65 mm', front: 50, rear: 65),
      (label: '65 mm', front: 65, rear: 65),
      (label: '65/80 mm', front: 65, rear: 80),
      (label: '80 mm', front: 80, rear: 80),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wheelPresets.map((preset) {
              final bool selected = _input.frontRimDepthMm == preset.front &&
                  _input.rearRimDepthMm == preset.rear;
              return _InteractiveSelectorChip(
                label: preset.label,
                isSelected: selected,
                onTap: () => _updateInput(
                  _input.copyWith(
                    frontRimDepthMm: preset.front,
                    rearRimDepthMm: preset.rear,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CrosswindGustEnvironment.values.map((env) {
              return _InteractiveSelectorChip(
                label: env.labelPl,
                isSelected: _input.environment == env,
                accentColor: AppColors.accentBlue,
                onTap: () => _updateInput(_input.copyWith(environment: env)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 290,
                child: _buildSliderRow(
                  label: 'Podmuch szczytowy',
                  valueLabel:
                      '${(_input.gustPeakSpeedMs * 3.6).toStringAsFixed(0)} km/h',
                  value: _input.gustPeakSpeedMs,
                  min: 4.0,
                  max: 26.0,
                  onChanged: (v) => _updateInput(_input.copyWith(gustPeakSpeedMs: v)),
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 290,
                child: _buildSliderRow(
                  label: 'Prędkość jazdy',
                  valueLabel:
                      '${(_input.riderSpeedMs * 3.6).toStringAsFixed(0)} km/h',
                  value: _input.riderSpeedMs,
                  min: 6.0,
                  max: 24.0,
                  onChanged: (v) => _updateInput(_input.copyWith(riderSpeedMs: v)),
                ),
              ),
              _InteractiveSelectorChip(
                label: _input.isWetAsphalt ? 'Mokry asfalt: TAK' : 'Mokry asfalt: NIE',
                isSelected: _input.isWetAsphalt,
                accentColor: AppColors.amberWarning,
                onTap: () => _updateInput(
                  _input.copyWith(isWetAsphalt: !_input.isWetAsphalt),
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
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            trackHeight: 3,
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

  Widget _buildMetricsGrid(CrosswindWheelStabilityResult result, bool isCompact) {
    final List<({String title, String value, Color accent})> cards = [
      (
        title: 'Impuls na kierownicy',
        value: '${result.gustPeakSteeringTorqueNm.toStringAsFixed(1)} N·m',
        accent: result.stabilityLevel.statusColor,
      ),
      (
        title: 'Znoszenie boczne',
        value: '${result.estimatedLateralSwayMeters.toStringAsFixed(2)} m',
        accent: AppColors.amberWarning,
      ),
      (
        title: 'Kąt yaw (podmuch)',
        value: '${result.gustApparentYawAngleDeg.toStringAsFixed(1)}°',
        accent: AppColors.accentBlue,
      ),
      (
        title: 'Efekt żagla (netto)',
        value:
            '${result.netAeroPowerDeltaWatts <= 0 ? '+' : '-'}${result.netAeroPowerDeltaWatts.abs().toStringAsFixed(1)} W',
        accent: result.netAeroPowerDeltaWatts <= 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isCompact ? 2 : 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: isCompact ? 1.85 : 2.25,
      ),
      itemBuilder: (context, index) {
        final item = cards[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: item.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGustChartCard(CrosswindGustSequenceResult sequence) {
    return Container(
      height: 176,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Symulacja impulsu podmuchu (5.0 s)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Powrót: ${sequence.recoveryTimeSeconds.toStringAsFixed(2)} s',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.accentBlue,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              painter: _GustResponseCurvePainter(steps: sequence.steps),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(
    List<CrosswindWheelDepthComparison> comparisons,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Porównanie profili w aktualnym wietrze',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...comparisons.map((entry) {
            final CrosswindWheelStabilityResult r = entry.result;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: isCompact ? 86 : 120,
                    child: Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${r.gustPeakSteeringTorqueNm.toStringAsFixed(1)} N·m | '
                      '${r.estimatedLateralSwayMeters.toStringAsFixed(2)} m',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 0,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: r.stabilityLevel.statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.stabilityLevel.labelPl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: r.stabilityLevel.statusColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InteractiveSelectorChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color accentColor;

  const _InteractiveSelectorChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.accentColor = AppColors.goldAccent,
  });

  @override
  State<_InteractiveSelectorChip> createState() =>
      _InteractiveSelectorChipState();
}

class _InteractiveSelectorChipState extends State<_InteractiveSelectorChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onTap == null;
    final Color borderColor = isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.isSelected || _focused
            ? widget.accentColor
            : _hovered
                ? AppColors.textSecondary
                : const Color(0xFF2A2F3D);

    final Color bgColor = isDisabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : widget.isSelected
                      ? widget.accentColor
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GustResponseCurvePainter extends CustomPainter {
  final List<CrosswindGustSimulationStep> steps;

  const _GustResponseCurvePainter({required this.steps});

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.length < 2 || size.width <= 0 || size.height <= 0) return;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final double y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double maxTorque = 1.0;
    double maxSway = 0.25;
    for (final step in steps) {
      if (step.steeringTorqueNm > maxTorque) maxTorque = step.steeringTorqueNm;
      if (step.lateralSwayMeters > maxSway) maxSway = step.lateralSwayMeters;
    }

    final Path torquePath = Path();
    final Path swayPath = Path();
    final double totalTime = steps.last.timeSeconds > 0 ? steps.last.timeSeconds : 1.0;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final double x = (step.timeSeconds / totalTime) * size.width;
      final double yTorque =
          size.height - (step.steeringTorqueNm / (maxTorque * 1.15)) * size.height;
      final double ySway =
          size.height - (step.lateralSwayMeters / (maxSway * 1.15)) * size.height;

      if (i == 0) {
        torquePath.moveTo(x, yTorque);
        swayPath.moveTo(x, ySway);
      } else {
        torquePath.lineTo(x, yTorque);
        swayPath.lineTo(x, ySway);
      }
    }

    final Paint torquePaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint swayPaint = Paint()
      ..color = AppColors.amberWarning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(torquePath, torquePaint);
    canvas.drawPath(swayPath, swayPaint);
  }

  @override
  bool shouldRepaint(covariant _GustResponseCurvePainter oldDelegate) {
    return oldDelegate.steps != steps;
  }
}
