// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';

/// Strefa aerodynamiczna, w której znajduje się kolarz jadący w wachlarzu.
enum EchelonConeZone {
  /// Idealne ustawienie w przesuniętym na zawietrzną stożku cienia (30%–38% redukcji oporu).
  optimalVortexCone(
    'Optimal Vortex Cone',
    'Optymalny stożek wachlarza',
    AppColors.statusSuccess,
  ),

  /// Częściowa osłona po stronie zawietrznej lub na skraju stożka (18%–30% redukcji).
  partialLeewardShelter(
    'Partial Leeward Shelter',
    'Częściowa osłona zawietrzna',
    AppColors.accentBlue,
  ),

  /// Jazda bezpośrednio za tylnym kołem w wietrze bocznym (ok. 12% redukcji — strata 26% vs optimum).
  directWheelMisaligned(
    'Direct Wheel (Exposed)',
    'Bezpośrednio za kołem (błąd)',
    AppColors.amberWarning,
  ),

  /// Pełna ekspozycja na wiatr boczny lub jazda po stronie nawietrznej (<10% redukcji).
  windwardExposed(
    'Windward / Gutter Exposed',
    'Ekspozycja na wiatr boczny',
    AppColors.crimsonAlert,
  );

  final String labelEn;
  final String labelPl;
  final Color color;

  const EchelonConeZone(this.labelEn, this.labelPl, this.color);
}

/// Kierunek napływu wiatru bocznego względem osi jazdy kolarza.
enum EchelonWindSide {
  /// Wiatr wieje z lewej strony — cień aerodynamiczny przesuwa się w prawo (+y).
  fromLeft('From Left → Leeward Right', 'Z lewej → cień w prawo'),

  /// Wiatr wieje z prawej strony — cień aerodynamiczny przesuwa się w lewo (-y).
  fromRight('From Right → Leeward Left', 'Z prawej → cień w lewo'),

  /// Brak istotnej składowej bocznej (wiatr czołowy/tylny lub cisza).
  neutral('Head/Tailwind (Symmetric)', 'Wiatr osiowy (symetryczny)');

  final String labelEn;
  final String labelPl;

  const EchelonWindSide(this.labelEn, this.labelPl);
}

/// Dane wejściowe dla modelu asymetrycznego draftingu w wachlarzu na wietrze bocznym.
@immutable
class EchelonVortexInput {
  /// Prędkość jazdy kolarza wzdłuż osi drogi [m/s].
  final double riderSpeedMs;

  /// Prędkość rzeczywista wiatru [m/s].
  final double windSpeedMs;

  /// Kąt wiatru względem osi jazdy [stopnie, -180..180]:
  /// 0° = czysty wiatr czołowy, +90° = wiatr z lewej strony, -90° = wiatr z prawej strony, ±180° = wiatr w plecy.
  final double windRelativeAngleDegrees;

  /// Odstęp podłużny od tylnego koła poprzedzającego kolarza do przedniego koła śledzącego [m].
  final double longitudinalGapMeters;

  /// Przesunięcie boczne osi śledzącego kolarza względem osi poprzedzającego [m] (>0 w prawo, <0 w lewo).
  final double lateralOffsetMeters;

  /// Bazowy współczynnik oporu aerodynamicznego CdA kolarza [m^2].
  final double baseCdA;

  /// Gęstość powietrza [kg/m^3].
  final double airDensityKgM3;

  /// Opcjonalne wymuszenie kąta osi stożka wachlarza [stopnie] (np. 35.0°);
  /// jeśli null, kąt jest wyliczany z wektora wiatru pozornego.
  final double? overrideWakeShiftAngleDegrees;

  const EchelonVortexInput({
    this.riderSpeedMs = 12.5,
    this.windSpeedMs = 8.75,
    this.windRelativeAngleDegrees = 90.0,
    this.longitudinalGapMeters = 0.55,
    this.lateralOffsetMeters = 0.70,
    this.baseCdA = PhysicsConstants.cdaHoods,
    this.airDensityKgM3 = PhysicsConstants.seaLevelAirDensity,
    this.overrideWakeShiftAngleDegrees,
  });

  /// Tworzy kanoniczny scenariusz wachlarza ustawionego pod kątem 35° do osi drogi.
  factory EchelonVortexInput.canonical35DegreeEchelon({
    double riderSpeedMs = 12.5,
    double longitudinalGapMeters = 0.55,
    double? lateralOffsetMeters,
    bool windFromLeft = true,
    bool alignDirectlyBehindWheel = false,
    double baseCdA = PhysicsConstants.cdaHoods,
    double airDensityKgM3 = PhysicsConstants.seaLevelAirDensity,
  }) {
    final double sign = windFromLeft ? 1.0 : -1.0;
    final double shiftDeg =
        AerodynamicCrossDraftingEchelonVortex.canonicalEchelonAngleDegrees * sign;
    final double effectiveLong =
        longitudinalGapMeters.clamp(-0.3, 12.0) +
        AerodynamicCrossDraftingEchelonVortex.wakeOriginOffsetMeters;
    final double idealLateral =
        effectiveLong *
        math.tan(
          AerodynamicCrossDraftingEchelonVortex.canonicalEchelonAngleDegrees *
              math.pi /
              180.0,
        ) *
        sign;

    return EchelonVortexInput(
      riderSpeedMs: riderSpeedMs,
      // w_cross = v * tan(35°) -> wiatr pozorny odchylony dokładnie o 35°
      windSpeedMs:
          riderSpeedMs *
          math.tan(
            AerodynamicCrossDraftingEchelonVortex.canonicalEchelonAngleDegrees *
                math.pi /
                180.0,
          ),
      windRelativeAngleDegrees: windFromLeft ? 90.0 : -90.0,
      longitudinalGapMeters: longitudinalGapMeters,
      lateralOffsetMeters: alignDirectlyBehindWheel
          ? 0.0
          : (lateralOffsetMeters ?? idealLateral),
      baseCdA: baseCdA,
      airDensityKgM3: airDensityKgM3,
      overrideWakeShiftAngleDegrees: shiftDeg,
    );
  }

  EchelonVortexInput copyWith({
    double? riderSpeedMs,
    double? windSpeedMs,
    double? windRelativeAngleDegrees,
    double? longitudinalGapMeters,
    double? lateralOffsetMeters,
    double? baseCdA,
    double? airDensityKgM3,
    double? overrideWakeShiftAngleDegrees,
    bool clearOverrideAngle = false,
  }) {
    return EchelonVortexInput(
      riderSpeedMs: riderSpeedMs ?? this.riderSpeedMs,
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      windRelativeAngleDegrees:
          windRelativeAngleDegrees ?? this.windRelativeAngleDegrees,
      longitudinalGapMeters:
          longitudinalGapMeters ?? this.longitudinalGapMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      baseCdA: baseCdA ?? this.baseCdA,
      airDensityKgM3: airDensityKgM3 ?? this.airDensityKgM3,
      overrideWakeShiftAngleDegrees: clearOverrideAngle
          ? null
          : (overrideWakeShiftAngleDegrees ?? this.overrideWakeShiftAngleDegrees),
    );
  }
}

/// Wynik obliczeń fizyki asymetrycznego stożka cienia w wachlarzu.
@immutable
class EchelonVortexResult {
  /// Uzyskana redukcja oporu aerodynamicznego [0.0..0.38].
  final double effectiveDragReduction;

  /// Efektywny współczynnik CdA po uwzględnieniu draftingu [m^2].
  final double effectiveCdA;

  /// Moc aerodynamiczna wymagana przy jeździe solo bez osłony [W].
  final double soloAeroPowerWatts;

  /// Moc aerodynamiczna wymagana w bieżącej pozycji w wachlarzu [W].
  final double draftingAeroPowerWatts;

  /// Zaoszczędzona moc dzięki osłonie w wachlarzu [W].
  final double powerSavedWatts;

  /// Kąt przesunięcia osi stożka cienia na zawietrzną [stopnie] (+ w prawo, - w lewo).
  final double wakeShiftAngleDegrees;

  /// Kąt pozycji śledzącego kolarza względem tylnego koła poprzedzającego [stopnie].
  final double riderRelativeAngleDegrees;

  /// Odchylenie kątowe kolarza od osi przesuniętego stożka cienia [stopnie].
  final double angularDeviationFromConeDegrees;

  /// Optymalne przesunięcie boczne [m] przy aktualnym odstępie podłużnym dające 38% redukcji.
  final double optimalLateralOffsetMeters;

  /// Korekta boczna [m] potrzebna do wejścia w centrum przesuniętego stożka.
  final double lateralCorrectionNeededMeters;

  /// Prędkość wiatru pozornego [m/s].
  final double apparentWindSpeedMs;

  /// Kąt wiatru pozornego (yaw) względem osi roweru [stopnie].
  final double apparentYawAngleDegrees;

  /// Częstotliwość zrzucania wirów Kármána za sylwetką lidera [Hz].
  final double vortexSheddingFrequencyHz;

  /// Zaklasyfikowana strefa cienia aerodynamicznego.
  final EchelonConeZone coneZone;

  /// Kierunek wiatru bocznego.
  final EchelonWindSide windSide;

  /// Czy koła kolarzy nakładają się podłużnie (zwiększone ryzyko zahaczenia).
  final bool isWheelOverlap;

  const EchelonVortexResult({
    required this.effectiveDragReduction,
    required this.effectiveCdA,
    required this.soloAeroPowerWatts,
    required this.draftingAeroPowerWatts,
    required this.powerSavedWatts,
    required this.wakeShiftAngleDegrees,
    required this.riderRelativeAngleDegrees,
    required this.angularDeviationFromConeDegrees,
    required this.optimalLateralOffsetMeters,
    required this.lateralCorrectionNeededMeters,
    required this.apparentWindSpeedMs,
    required this.apparentYawAngleDegrees,
    required this.vortexSheddingFrequencyHz,
    required this.coneZone,
    required this.windSide,
    required this.isWheelOverlap,
  });

  /// Procentowa redukcja oporu (0–38%).
  double get dragReductionPercent => effectiveDragReduction * 100.0;
}

/// Dane wejściowe pojedynczego kolarza w szyku wachlarza.
@immutable
class EchelonFormationRiderInput {
  final String riderId;
  final String riderName;
  final double longitudinalGapFromLeaderMeters;
  final double lateralOffsetFromLeaderMeters;
  final double baseCdA;

  const EchelonFormationRiderInput({
    required this.riderId,
    required this.riderName,
    required this.longitudinalGapFromLeaderMeters,
    required this.lateralOffsetFromLeaderMeters,
    this.baseCdA = PhysicsConstants.cdaHoods,
  });
}

/// Wynik analizy pojedynczego kolarza w szyku wachlarza.
@immutable
class EchelonFormationRiderResult {
  final EchelonFormationRiderInput input;
  final EchelonVortexResult vortexResult;
  final int echelonSlotIndex;

  const EchelonFormationRiderResult({
    required this.input,
    required this.vortexResult,
    required this.echelonSlotIndex,
  });
}

/// Zbiorcze podsumowanie efektywności całego wachlarza.
@immutable
class EchelonFormationSummary {
  final List<EchelonFormationRiderResult> riders;
  final double averageDragReduction;
  final double totalPowerSavedWatts;
  final double wakeShiftAngleDegrees;
  final EchelonFormationRiderResult? mostExposedFollower;

  const EchelonFormationSummary({
    required this.riders,
    required this.averageDragReduction,
    required this.totalPowerSavedWatts,
    required this.wakeShiftAngleDegrees,
    required this.mostExposedFollower,
  });
}

/// Silnik fizyki asymetrycznego draftingu i wirów aerodynamicznych w wachlarzu
/// przy wietrze bocznym (`AerodynamicCrossDraftingEchelonVortex`).
///
/// W wachlarzu ustawionym pod kątem 35° do osi drogi strefa cienia aerodynamicznego
/// przesuwa się asymetrycznie na zawietrzną stronę od tylnego koła poprzedzającego kolarza:
/// - kolarz jadący idealnie w tym przesuniętym stożku zyskuje **38%** redukcji oporu,
/// - kolarz jadący bezpośrednio za tylnym kołem (0° odchylenia bocznego) zyskuje tylko **12%**.
class AerodynamicCrossDraftingEchelonVortex {
  AerodynamicCrossDraftingEchelonVortex._();

  /// Kanoniczny kąt ustawienia wachlarza względem osi drogi [stopnie].
  static const double canonicalEchelonAngleDegrees = 35.0;

  /// Maksymalna redukcja oporu w osi przesuniętego stożka cienia (38%).
  static const double optimalShiftedConeReduction = 0.38;

  /// Redukcja oporu przy jeździe bezpośrednio za kołem w wachlarzu 35° (12%).
  static const double directBehindWheelAt35DegReduction = 0.12;

  /// Odległość od efektywnego środka parcia poprzedzającego kolarza do krawędzi tylnego koła [m].
  static const double wakeOriginOffsetMeters = 0.45;

  /// Maksymalny promień optymalnego rdzenia bliskości bez straty na rozproszenie wiru [m].
  static const double optimalCoreRadiusMeters = 1.35;

  /// Współczynnik zaniku siły cienia aerodynamicznego wraz z odległością [1/m].
  static const double longitudinalDecayPerMeter = 0.22;

  /// Szerokość kątowa Gaussa stożka wirów dobrana tak, aby przy odchyleniu 35°
  /// redukcja spadała dokładnie z 38% do 12%:
  /// sigma = 35 / sqrt(2 * ln(0.38 / 0.12)) ≈ 23.05147°.
  static const double _coneGaussianSigmaDegrees = 23.0514734;

  /// Liczba Strouhala dla opływu tułowia kolarza (ciało opływowo-tępe).
  static const double _riderStrouhalNumber = 0.21;

  /// Średnia szerokość aerodynamiczna sylwetki kolarza [m].
  static const double _riderTorsoWidthMeters = 0.42;

  /// Wylicza kąt przesunięcia stożka cienia aerodynamicznego [stopnie] na podstawie
  /// prędkości jazdy, prędkości wiatru oraz jego kąta względem drogi.
  static double computeWakeShiftAngleDegrees({
    required double riderSpeedMs,
    required double windSpeedMs,
    required double windRelativeAngleDegrees,
  }) {
    final double safeSpeed = math.max(0.5, riderSpeedMs);
    final double safeWind = math.max(0.0, windSpeedMs);
    final double rad = windRelativeAngleDegrees * math.pi / 180.0;

    final double headwindMs = safeWind * math.cos(rad);
    final double crosswindMs = safeWind * math.sin(rad);

    // Składowa osiowa wiatru pozornego (zawsze dodatnia dla bezpiecznego atan2)
    final double effectiveAxialAirspeed = math.max(0.5, safeSpeed + headwindMs);
    final double rawShiftRad = math.atan2(crosswindMs, effectiveAxialAirspeed);
    final double rawShiftDeg = rawShiftRad * 180.0 / math.pi;

    return rawShiftDeg.clamp(-65.0, 65.0);
  }

  /// Wylicza optymalne przesunięcie boczne [m] względem osi poprzedzającego kolarza,
  /// pozwalające ustawić przednie koło i tułów w centrum przesuniętego stożka cienia.
  static double computeOptimalLateralOffsetMeters({
    required double longitudinalGapMeters,
    required double wakeShiftAngleDegrees,
  }) {
    final double clampedGap = longitudinalGapMeters.clamp(-0.3, 15.0);
    final double effectiveX = math.max(0.25, clampedGap + wakeOriginOffsetMeters);
    final double shiftRad = wakeShiftAngleDegrees * math.pi / 180.0;
    return effectiveX * math.tan(shiftRad);
  }

  /// Oblicza pełny stan fizyki asymetrycznego draftingu w stożku wirów na wietrze bocznym.
  static EchelonVortexResult evaluateSingleDraft(EchelonVortexInput input) {
    final double safeSpeed = math.max(0.5, input.riderSpeedMs);
    final double safeWind = math.max(0.0, input.windSpeedMs);
    final double safeCdA = math.max(0.10, input.baseCdA);
    final double safeRho = math.max(0.40, input.airDensityKgM3);

    final double windRad = input.windRelativeAngleDegrees * math.pi / 180.0;
    final double headwindMs = safeWind * math.cos(windRad);
    final double crosswindMs = safeWind * math.sin(windRad);

    final double axialApparentMs = safeSpeed + headwindMs;
    final double apparentWindSpeedMs = math.sqrt(
      axialApparentMs * axialApparentMs + crosswindMs * crosswindMs,
    );
    final double apparentYawDeg =
        math.atan2(crosswindMs.abs(), math.max(0.5, axialApparentMs)) *
        180.0 /
        math.pi;

    final double wakeShiftDeg =
        (input.overrideWakeShiftAngleDegrees ??
                computeWakeShiftAngleDegrees(
                  riderSpeedMs: safeSpeed,
                  windSpeedMs: safeWind,
                  windRelativeAngleDegrees: input.windRelativeAngleDegrees,
                ))
            .clamp(-65.0, 65.0);

    final EchelonWindSide windSide;
    if (wakeShiftDeg > 2.5) {
      windSide = EchelonWindSide.fromLeft;
    } else if (wakeShiftDeg < -2.5) {
      windSide = EchelonWindSide.fromRight;
    } else {
      windSide = EchelonWindSide.neutral;
    }

    final double clampedLongGap = input.longitudinalGapMeters.clamp(-0.30, 20.0);
    final double effectiveX = math.max(
      0.25,
      clampedLongGap + wakeOriginOffsetMeters,
    );
    final double lateralOffset = input.lateralOffsetMeters;

    final double riderAngleDeg =
        math.atan2(lateralOffset, effectiveX) * 180.0 / math.pi;
    final double angularDevDeg = riderAngleDeg - wakeShiftDeg;

    // Asymetria: odchylenie po stronie nawietrznej (przeciwnej do kierunku cienia)
    // wystawia kolarza na czysty, niezaburzony napływ wiatru szybciej niż strona zawietrzna.
    final bool isWindwardDeviation =
        (wakeShiftDeg > 0 && angularDevDeg < 0) ||
        (wakeShiftDeg < 0 && angularDevDeg > 0);
    final double effectiveSigma = isWindwardDeviation
        ? _coneGaussianSigmaDegrees
        : _coneGaussianSigmaDegrees * 1.08;

    final double angularFactor = math.exp(
      -(angularDevDeg * angularDevDeg) / (2.0 * effectiveSigma * effectiveSigma),
    );

    final double radialDist = math.sqrt(
      effectiveX * effectiveX + lateralOffset * lateralOffset,
    );
    final double excessDistance = math.max(
      0.0,
      radialDist - optimalCoreRadiusMeters,
    );
    final double distanceFactor = math.exp(
      -longitudinalDecayPerMeter * excessDistance,
    );

    final double effectiveReduction =
        (optimalShiftedConeReduction * angularFactor * distanceFactor).clamp(
          0.0,
          optimalShiftedConeReduction,
        );

    final double effectiveCdA = safeCdA * (1.0 - effectiveReduction);

    // Moc aerodynamiczna: P = 0.5 * rho * CdA * v_app^2 * v_rider
    final double soloAeroPower =
        0.5 * safeRho * safeCdA * apparentWindSpeedMs * apparentWindSpeedMs * safeSpeed;
    final double draftingAeroPower =
        0.5 *
        safeRho *
        effectiveCdA *
        apparentWindSpeedMs *
        apparentWindSpeedMs *
        safeSpeed;
    final double powerSaved = math.max(0.0, soloAeroPower - draftingAeroPower);

    final double optimalLateral = computeOptimalLateralOffsetMeters(
      longitudinalGapMeters: clampedLongGap,
      wakeShiftAngleDegrees: wakeShiftDeg,
    );
    final double lateralCorrection = optimalLateral - lateralOffset;

    final double sheddingHz =
        (_riderStrouhalNumber * apparentWindSpeedMs) / _riderTorsoWidthMeters;

    final EchelonConeZone zone;
    if (effectiveReduction >= 0.30) {
      zone = EchelonConeZone.optimalVortexCone;
    } else if (effectiveReduction >= 0.18) {
      zone = EchelonConeZone.partialLeewardShelter;
    } else if (effectiveReduction >= 0.10) {
      zone = EchelonConeZone.directWheelMisaligned;
    } else {
      zone = EchelonConeZone.windwardExposed;
    }

    return EchelonVortexResult(
      effectiveDragReduction: effectiveReduction,
      effectiveCdA: effectiveCdA,
      soloAeroPowerWatts: soloAeroPower,
      draftingAeroPowerWatts: draftingAeroPower,
      powerSavedWatts: powerSaved,
      wakeShiftAngleDegrees: wakeShiftDeg,
      riderRelativeAngleDegrees: riderAngleDeg,
      angularDeviationFromConeDegrees: angularDevDeg,
      optimalLateralOffsetMeters: optimalLateral,
      lateralCorrectionNeededMeters: lateralCorrection,
      apparentWindSpeedMs: apparentWindSpeedMs,
      apparentYawAngleDegrees: apparentYawDeg,
      vortexSheddingFrequencyHz: sheddingHz,
      coneZone: zone,
      windSide: windSide,
      isWheelOverlap: input.longitudinalGapMeters < 0.0,
    );
  }

  /// Analizuje cały szyk kolarzy w wachlarzu, oceniając każdego kolejnego zawodnika
  /// względem jego bezpośredniego poprzednika w linii wiatru.
  static EchelonFormationSummary evaluateEchelonFormation({
    required List<EchelonFormationRiderInput> riders,
    double riderSpeedMs = 12.5,
    double windSpeedMs = 8.75,
    double windRelativeAngleDegrees = 90.0,
    double airDensityKgM3 = PhysicsConstants.seaLevelAirDensity,
    double? overrideWakeShiftAngleDegrees,
  }) {
    if (riders.isEmpty) {
      final double shift =
          overrideWakeShiftAngleDegrees ??
          computeWakeShiftAngleDegrees(
            riderSpeedMs: riderSpeedMs,
            windSpeedMs: windSpeedMs,
            windRelativeAngleDegrees: windRelativeAngleDegrees,
          );
      return EchelonFormationSummary(
        riders: const [],
        averageDragReduction: 0.0,
        totalPowerSavedWatts: 0.0,
        wakeShiftAngleDegrees: shift,
        mostExposedFollower: null,
      );
    }

    final List<EchelonFormationRiderResult> results = [];
    double totalReduction = 0.0;
    double totalSavedWatts = 0.0;
    EchelonFormationRiderResult? worstFollower;

    // Pierwszy kolarz jedzie na czole (brak poprzednika — 0% redukcji).
    final first = riders.first;
    final firstVortex = evaluateSingleDraft(
      EchelonVortexInput(
        riderSpeedMs: riderSpeedMs,
        windSpeedMs: windSpeedMs,
        windRelativeAngleDegrees: windRelativeAngleDegrees,
        longitudinalGapMeters: 15.0,
        lateralOffsetMeters: 0.0,
        baseCdA: first.baseCdA,
        airDensityKgM3: airDensityKgM3,
        overrideWakeShiftAngleDegrees: overrideWakeShiftAngleDegrees,
      ),
    );
    final firstResult = EchelonFormationRiderResult(
      input: first,
      vortexResult: EchelonVortexResult(
        effectiveDragReduction: 0.0,
        effectiveCdA: first.baseCdA,
        soloAeroPowerWatts: firstVortex.soloAeroPowerWatts,
        draftingAeroPowerWatts: firstVortex.soloAeroPowerWatts,
        powerSavedWatts: 0.0,
        wakeShiftAngleDegrees: firstVortex.wakeShiftAngleDegrees,
        riderRelativeAngleDegrees: 0.0,
        angularDeviationFromConeDegrees: -firstVortex.wakeShiftAngleDegrees,
        optimalLateralOffsetMeters: 0.0,
        lateralCorrectionNeededMeters: 0.0,
        apparentWindSpeedMs: firstVortex.apparentWindSpeedMs,
        apparentYawAngleDegrees: firstVortex.apparentYawAngleDegrees,
        vortexSheddingFrequencyHz: firstVortex.vortexSheddingFrequencyHz,
        coneZone: EchelonConeZone.windwardExposed,
        windSide: firstVortex.windSide,
        isWheelOverlap: false,
      ),
      echelonSlotIndex: 0,
    );
    results.add(firstResult);

    for (int i = 1; i < riders.length; i++) {
      final prev = riders[i - 1];
      final curr = riders[i];
      final double relLongGap =
          curr.longitudinalGapFromLeaderMeters -
          prev.longitudinalGapFromLeaderMeters;
      final double relLatOffset =
          curr.lateralOffsetFromLeaderMeters -
          prev.lateralOffsetFromLeaderMeters;

      final vortex = evaluateSingleDraft(
        EchelonVortexInput(
          riderSpeedMs: riderSpeedMs,
          windSpeedMs: windSpeedMs,
          windRelativeAngleDegrees: windRelativeAngleDegrees,
          longitudinalGapMeters: relLongGap,
          lateralOffsetMeters: relLatOffset,
          baseCdA: curr.baseCdA,
          airDensityKgM3: airDensityKgM3,
          overrideWakeShiftAngleDegrees: overrideWakeShiftAngleDegrees,
        ),
      );

      final entry = EchelonFormationRiderResult(
        input: curr,
        vortexResult: vortex,
        echelonSlotIndex: i,
      );
      results.add(entry);
      totalReduction += vortex.effectiveDragReduction;
      totalSavedWatts += vortex.powerSavedWatts;

      if (worstFollower == null ||
          vortex.effectiveDragReduction <
              worstFollower.vortexResult.effectiveDragReduction) {
        worstFollower = entry;
      }
    }

    final int followerCount = math.max(1, riders.length - 1);
    return EchelonFormationSummary(
      riders: results,
      averageDragReduction: riders.length <= 1
          ? 0.0
          : totalReduction / followerCount,
      totalPowerSavedWatts: totalSavedWatts,
      wakeShiftAngleDegrees: firstVortex.wakeShiftAngleDegrees,
      mostExposedFollower: worstFollower,
    );
  }
}

/// Rysownik przekroju poziomego stożka cienia aerodynamicznego w wachlarzu 35°.
class EchelonVortexConePainter extends CustomPainter {
  final EchelonVortexInput input;
  final EchelonVortexResult result;

  const EchelonVortexConePainter({
    required this.input,
    required this.result,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Paint bgPaint = Paint()..color = AppColors.background;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(12)),
      bgPaint,
    );

    // Siatka asfaltu i linie drogi
    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 4; i++) {
      final double y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Pozycja lidera (przód po prawej, cień ciągnie się w lewo)
    final Offset leaderPos = Offset(size.width * 0.76, size.height * 0.42);
    const double metersToPx = 64.0;

    // Rysowanie stożka cienia przesuniętego pod kątem wakeShiftAngleDegrees
    final double shiftRad = result.wakeShiftAngleDegrees * math.pi / 180.0;
    const double coneLengthPx = 220.0;
    const double halfSpreadRad = 22.0 * math.pi / 180.0;

    // Uwaga: na ekranie Oś X drogi biegnie w prawo (+x), więc za liderem to -x.
    // Kierunek w prawo (+y) na drodze to w dół na rzucie z góry.
    final Offset coneCenterEnd = Offset(
      leaderPos.dx - coneLengthPx * math.cos(shiftRad),
      leaderPos.dy + coneLengthPx * math.sin(shiftRad),
    );
    final Offset coneUpperEdge = Offset(
      leaderPos.dx - coneLengthPx * math.cos(shiftRad - halfSpreadRad),
      leaderPos.dy + coneLengthPx * math.sin(shiftRad - halfSpreadRad),
    );
    final Offset coneLowerEdge = Offset(
      leaderPos.dx - coneLengthPx * math.cos(shiftRad + halfSpreadRad),
      leaderPos.dy + coneLengthPx * math.sin(shiftRad + halfSpreadRad),
    );

    final Path conePath = Path()
      ..moveTo(leaderPos.dx, leaderPos.dy)
      ..lineTo(coneUpperEdge.dx, coneUpperEdge.dy)
      ..lineTo(coneLowerEdge.dx, coneLowerEdge.dy)
      ..close();

    final Paint coneFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          AppColors.statusSuccess.withValues(alpha: 0.36),
          AppColors.accentBlue.withValues(alpha: 0.14),
          AppColors.accentBlue.withValues(alpha: 0.02),
        ],
      ).createShader(bounds);
    canvas.drawPath(conePath, coneFillPaint);

    // Oś optymalnego stożka (38%)
    final Paint coneAxisPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.75)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(leaderPos, coneCenterEnd, coneAxisPaint);

    // Linia bezpośrednio za kołem (12% przy 35°)
    final Paint directLinePaint = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      leaderPos,
      Offset(leaderPos.dx - coneLengthPx * 0.85, leaderPos.dy),
      directLinePaint,
    );

    // Lider (złoty punkt)
    final Paint leaderPaint = Paint()..color = AppColors.goldAccent;
    canvas.drawCircle(leaderPos, 7.5, leaderPaint);

    // Optymalny punkt (38%)
    final double optDx =
        (input.longitudinalGapMeters.clamp(0.0, 3.0) +
            AerodynamicCrossDraftingEchelonVortex.wakeOriginOffsetMeters) *
        metersToPx;
    final double optDy = result.optimalLateralOffsetMeters * metersToPx;
    final Offset optimalSpot = Offset(
      (leaderPos.dx - optDx).clamp(16.0, size.width - 16.0),
      (leaderPos.dy + optDy).clamp(16.0, size.height - 16.0),
    );
    final Paint optRingPaint = Paint()
      ..color = AppColors.statusSuccess
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(optimalSpot, 11.0, optRingPaint);

    // Aktualna pozycja śledzącego kolarza
    final double folDy = input.lateralOffsetMeters * metersToPx;
    final Offset followerPos = Offset(
      (leaderPos.dx - optDx).clamp(16.0, size.width - 16.0),
      (leaderPos.dy + folDy).clamp(16.0, size.height - 16.0),
    );
    final Paint followerPaint = Paint()..color = result.coneZone.color;
    canvas.drawCircle(followerPos, 7.5, followerPaint);

    // Strzałka kierunku wiatru
    final Offset windOrigin = Offset(size.width * 0.14, size.height * 0.16);
    final double windRad = input.windRelativeAngleDegrees * math.pi / 180.0;
    final Offset windTip = Offset(
      windOrigin.dx - 24.0 * math.cos(windRad),
      windOrigin.dy + 24.0 * math.sin(windRad),
    );
    final Paint windPaint = Paint()
      ..color = AppColors.cyanAccent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(windOrigin, windTip, windPaint);
    canvas.drawCircle(windTip, 3.0, windPaint);
  }

  @override
  bool shouldRepaint(covariant EchelonVortexConePainter oldDelegate) {
    return oldDelegate.input.lateralOffsetMeters != input.lateralOffsetMeters ||
        oldDelegate.input.longitudinalGapMeters != input.longitudinalGapMeters ||
        oldDelegate.input.windRelativeAngleDegrees !=
            input.windRelativeAngleDegrees ||
        oldDelegate.input.windSpeedMs != input.windSpeedMs ||
        oldDelegate.result.effectiveDragReduction !=
            result.effectiveDragReduction;
  }
}

/// Interaktywny panel telemetryczny fizyki stożka cienia aerodynamicznego w wachlarzu.
class AerodynamicCrossDraftingEchelonVortexPanel extends StatefulWidget {
  final EchelonVortexInput? initialInput;
  final ValueChanged<EchelonVortexResult>? onResultChanged;

  const AerodynamicCrossDraftingEchelonVortexPanel({
    super.key,
    this.initialInput,
    this.onResultChanged,
  });

  @override
  State<AerodynamicCrossDraftingEchelonVortexPanel> createState() =>
      _AerodynamicCrossDraftingEchelonVortexPanelState();
}

class _AerodynamicCrossDraftingEchelonVortexPanelState
    extends State<AerodynamicCrossDraftingEchelonVortexPanel> {
  late EchelonVortexInput _input;
  bool _autoSnapToOptimalCone = false;
  int _selectedPresetIndex = 0;

  @override
  void initState() {
    super.initState();
    _input =
        widget.initialInput ??
        EchelonVortexInput.canonical35DegreeEchelon();
  }

  void _updateInput(EchelonVortexInput next, {int? presetIndex}) {
    setState(() {
      if (_autoSnapToOptimalCone) {
        final double shift =
            next.overrideWakeShiftAngleDegrees ??
            AerodynamicCrossDraftingEchelonVortex.computeWakeShiftAngleDegrees(
              riderSpeedMs: next.riderSpeedMs,
              windSpeedMs: next.windSpeedMs,
              windRelativeAngleDegrees: next.windRelativeAngleDegrees,
            );
        final double optimalLat =
            AerodynamicCrossDraftingEchelonVortex
                .computeOptimalLateralOffsetMeters(
                  longitudinalGapMeters: next.longitudinalGapMeters,
                  wakeShiftAngleDegrees: shift,
                );
        _input = next.copyWith(lateralOffsetMeters: optimalLat);
      } else {
        _input = next;
      }
      if (presetIndex != null) {
        _selectedPresetIndex = presetIndex;
      }
    });
    widget.onResultChanged?.call(
      AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(_input),
    );
  }

  void _applyPreset(int index) {
    switch (index) {
      case 0:
        _updateInput(
          EchelonVortexInput.canonical35DegreeEchelon(),
          presetIndex: 0,
        );
        break;
      case 1:
        _updateInput(
          EchelonVortexInput.canonical35DegreeEchelon(
            alignDirectlyBehindWheel: true,
          ),
          presetIndex: 1,
        );
        break;
      case 2:
        _updateInput(
          EchelonVortexInput.canonical35DegreeEchelon(
            lateralOffsetMeters: -0.55,
          ),
          presetIndex: 2,
        );
        break;
      case 3:
        _updateInput(
          const EchelonVortexInput(
            riderSpeedMs: 12.5,
            windSpeedMs: 6.0,
            windRelativeAngleDegrees: 0.0,
            longitudinalGapMeters: 0.55,
            lateralOffsetMeters: 0.0,
          ),
          presetIndex: 3,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EchelonVortexResult result =
        AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(_input);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(result, isCompact),
                const SizedBox(height: 14),
                _buildPresetBar(),
                const SizedBox(height: 14),
                if (isCompact) ...[
                  _buildConeCanvas(result),
                  const SizedBox(height: 14),
                  _buildMetricsGrid(result, isCompact),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildConeCanvas(result)),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildMetricsGrid(result, isCompact),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _buildControls(result),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(EchelonVortexResult result, bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ECHELON VORTEX AERO CONE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              result.windSide.labelPl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: result.coneZone.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: result.coneZone.color.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            result.coneZone.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: result.coneZone.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetBar() {
    const List<String> labels = [
      '35° Wachlarz (38%)',
      'Za kołem (12%)',
      'Pod wiatr',
      'Czołowy 0°',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        final bool selected = _selectedPresetIndex == index;
        return _EchelonPresetChip(
          label: labels[index],
          selected: selected,
          onPressed: () => _applyPreset(index),
        );
      }),
    );
  }

  Widget _buildConeCanvas(EchelonVortexResult result) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: EchelonVortexConePainter(input: _input, result: result),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildMetricsGrid(EchelonVortexResult result, bool isCompact) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Redukcja oporu',
                value: '${result.dragReductionPercent.toStringAsFixed(1)}%',
                accentColor: result.coneZone.color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Oszczędność mocy',
                value: '${result.powerSavedWatts.toStringAsFixed(0)} W',
                accentColor: AppColors.goldAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Kąt stożka cienia',
                value: '${result.wakeShiftAngleDegrees.toStringAsFixed(1)}°',
                accentColor: AppColors.accentBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Efektywne CdA',
                value: '${result.effectiveCdA.toStringAsFixed(3)} m²',
                accentColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls(EchelonVortexResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Przesunięcie boczne za kołem [m]',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${_input.lateralOffsetMeters.toStringAsFixed(2)} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Slider(
            value: _input.lateralOffsetMeters.clamp(-1.5, 1.5),
            min: -1.5,
            max: 1.5,
            activeColor: AppColors.goldAccent,
            inactiveColor: AppColors.cardBorder,
            onChanged: _autoSnapToOptimalCone
                ? null
                : (val) => _updateInput(
                    _input.copyWith(lateralOffsetMeters: val),
                  ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Auto-ustawienie w stożku 35° (38%)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _autoSnapToOptimalCone,
                activeThumbColor: AppColors.statusSuccess,
                onChanged: (enabled) {
                  setState(() => _autoSnapToOptimalCone = enabled);
                  _updateInput(_input);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EchelonPresetChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _EchelonPresetChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  State<_EchelonPresetChip> createState() => _EchelonPresetChipState();
}

class _EchelonPresetChipState extends State<_EchelonPresetChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.selected
        ? AppColors.primaryAccent
        : (_pressed
              ? AppColors.surfaceLight
              : (_hovered ? AppColors.surfaceLight : AppColors.background));
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.goldAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
