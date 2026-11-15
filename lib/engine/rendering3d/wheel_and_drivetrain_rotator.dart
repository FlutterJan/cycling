// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';

/// Konfiguracja geometrii napędu i kół roweru szosowego lub czasowego.
class DrivetrainConfig {
  /// Liczba zębów tarcz korby (np. `[40, 54]` dla napędu 2x12 WorldTour).
  final List<int> chainringTeeth;

  /// Liczba zębów zębatek kasety od najmniejszej (najtwardszej) do największej (najlżejszej).
  final List<int> cassetteTeeth;

  /// Promień zewnętrzny koła z oponą w metrach (domyślnie 0.34 m dla 700x28c).
  final double wheelRadiusMeters;

  /// Długość ramienia korby w metrach (domyślnie 0.1725 m = 172.5 mm).
  final double crankLengthMeters;

  /// Liczba widocznych szprych koła (dla efektu wizualnego i motion blur).
  final int spokeCount;

  /// Czy tylne koło jest pełnym dyskiem czasowym (brak widocznych szprych).
  final bool isDiscWheel;

  /// Rozstaw koronek kasety w metrach (ok. 0.0036 m dla napędu 12-rzędowego).
  final double cassettePitchMeters;

  /// Długość wózka tylnej przerzutki (odległość między osiami kółek) w metrach.
  final double derailleurCageLengthMeters;

  /// Próg prędkości [km/h], powyżej którego aktywuje się efekt rozmycia ruchu (motion blur).
  final double motionBlurThresholdKmh;

  /// Prędkość [km/h], przy której rozmycie ruchu osiąga maksymalne nasycenie.
  final double motionBlurFullKmh;

  const DrivetrainConfig({
    this.chainringTeeth = const <int>[40, 54],
    this.cassetteTeeth = const <int>[
      11,
      12,
      13,
      14,
      15,
      17,
      19,
      21,
      24,
      27,
      30,
      34,
    ],
    this.wheelRadiusMeters = 0.34,
    this.crankLengthMeters = 0.1725,
    this.spokeCount = 16,
    this.isDiscWheel = false,
    this.cassettePitchMeters = 0.0036,
    this.derailleurCageLengthMeters = 0.075,
    this.motionBlurThresholdKmh = 40.0,
    this.motionBlurFullKmh = 85.0,
  });

  /// Obwód koła w metrach ($2 \pi R$).
  double get wheelCircumferenceMeters => 2.0 * math.pi * wheelRadiusMeters;

  /// Minimalna suma zębów (mała tarcza + najmniejsza koronka kasety).
  int get minTeethDemand =>
      (chainringTeeth.isEmpty ? 39 : chainringTeeth.first) +
      (cassetteTeeth.isEmpty ? 11 : cassetteTeeth.first);

  /// Maksymalna suma zębów (duża tarcza + największa koronka kasety).
  int get maxTeethDemand =>
      (chainringTeeth.isEmpty ? 54 : chainringTeeth.last) +
      (cassetteTeeth.isEmpty ? 34 : cassetteTeeth.last);
}

/// Wybrane przełożenie napędu (tarcza przednia + koronka tylnej kasety).
class DrivetrainGearSelection {
  /// Indeks tarczy korby (`0` = mała tarcza, `1` = duża tarcza).
  final int frontChainringIndex;

  /// Indeks koronki kasety (`0` = najmniejsza/najtwardsza, `N-1` = największa/najlżejsza).
  final int rearCogIndex;

  /// Liczba zębów aktywnej tarczy korby.
  final int frontTeeth;

  /// Liczba zębów aktywnej koronki kasety.
  final int rearTeeth;

  const DrivetrainGearSelection({
    required this.frontChainringIndex,
    required this.rearCogIndex,
    required this.frontTeeth,
    required this.rearTeeth,
  });

  /// Przełożenie mechaniczne (stosunek zębów korby do kasety).
  double get gearRatio => rearTeeth > 0 ? frontTeeth / rearTeeth : 1.0;

  /// Zapis tekstowy przełożenia, np. `54/14`.
  String get label => '$frontTeeth/$rearTeeth';

  /// Czy łańcuch znajduje się w skrajnym przekosie (cross-chaining).
  bool isCrossChained(DrivetrainConfig config) {
    if (config.chainringTeeth.length < 2 || config.cassetteTeeth.length < 4) {
      return false;
    }
    final bool onSmallRing = frontChainringIndex == 0;
    final bool onLargeRing =
        frontChainringIndex == config.chainringTeeth.length - 1;
    final bool onSmallestCogs = rearCogIndex <= 1;
    final bool onLargestCogs = rearCogIndex >= config.cassetteTeeth.length - 2;
    return (onSmallRing && onSmallestCogs) || (onLargeRing && onLargestCogs);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrivetrainGearSelection &&
        other.frontChainringIndex == frontChainringIndex &&
        other.rearCogIndex == rearCogIndex &&
        other.frontTeeth == frontTeeth &&
        other.rearTeeth == rearTeeth;
  }

  @override
  int get hashCode =>
      Object.hash(frontChainringIndex, rearCogIndex, frontTeeth, rearTeeth);
}

/// Parametry rozmycia ruchu (motion blur) szprych koła powyżej 40 km/h.
class WheelMotionBlurProfile {
  /// Czy przekroczono próg prędkości 40 km/h aktywujący motion blur.
  final bool isActive;

  /// Znormalizowana intensywność rozmycia w zakresie `[0.0, 1.0]`.
  final double intensity;

  /// Przezroczystość pojedynczych ostrych szprych `[0.15, 1.0]` (maleje ze wzrostem prędkości).
  final double sharpSpokeOpacity;

  /// Przezroczystość smugowego pierścienia rozmycia `[0.0, 0.55]`.
  final double blurDiscOpacity;

  /// Kątowy ślad smugi za każdą szprychą w radianach.
  final double trailSweepRadians;

  /// Liczba półprzezroczystych powidoków na jedną szprychę.
  final int ghostTrailSteps;

  const WheelMotionBlurProfile({
    required this.isActive,
    required this.intensity,
    required this.sharpSpokeOpacity,
    required this.blurDiscOpacity,
    required this.trailSweepRadians,
    required this.ghostTrailSteps,
  });

  static const WheelMotionBlurProfile none = WheelMotionBlurProfile(
    isActive: false,
    intensity: 0.0,
    sharpSpokeOpacity: 1.0,
    blurDiscOpacity: 0.0,
    trailSweepRadians: 0.0,
    ghostTrailSteps: 0,
  );
}

/// Kinematyka wózka tylnej przerzutki zależna od wybranego przełożenia.
class RearDerailleurKinematics {
  /// Kąt wychylenia wózka przerzutki w radianach (0 = pionowo w dół, dodatni = wychylenie do przodu ku korbie).
  final double cageSwingAngleRadians;

  /// Kąt wychylenia wózka przerzutki w stopniach.
  double get cageSwingAngleDegrees => cageSwingAngleRadians * 180.0 / math.pi;

  /// Znormalizowana pozycja boczna na kasecie `[0.0, 1.0]` (0 = mała koronka zewnętrzna, 1 = duża koronka wewnętrzna).
  final double lateralCassetteProgress;

  /// Boczne przesunięcie wózka w metrach względem płaszczyzny najmniejszej koronki.
  final double lateralOffsetMeters;

  /// Pozycja górnego kółka prowadzącego (guide pulley) w lokalnym układzie 2D względem osi tylnego koła `[m]`.
  final Offset guidePulleyLocalMeters;

  /// Pozycja dolnego kółka napinającego (tension pulley) w lokalnym układzie 2D względem osi tylnego koła `[m]`.
  final Offset tensionPulleyLocalMeters;

  /// Kąt obrotu kółek przerzutki w radianach.
  final double pulleyRotationRadians;

  /// Współczynnik napięcia łańcucha `[0.0, 1.0]`.
  final double chainTensionFactor;

  const RearDerailleurKinematics({
    required this.cageSwingAngleRadians,
    required this.lateralCassetteProgress,
    required this.lateralOffsetMeters,
    required this.guidePulleyLocalMeters,
    required this.tensionPulleyLocalMeters,
    required this.pulleyRotationRadians,
    required this.chainTensionFactor,
  });
}

/// Kompletny stan animacji mechanicznej kół, korby, łańcucha i przerzutki w bieżącej klatce.
class WheelAndDrivetrainFrameState {
  /// Identyfikator roweru / kolarza.
  final String riderId;

  /// Prędkość jazdy w m/s.
  final double speedMs;

  /// Prędkość jazdy w km/h.
  double get speedKmh => speedMs * 3.6;

  /// Aktualna kadencja pedałowania [RPM].
  final int cadenceRpm;

  /// Czy kolarz jedzie na luzie (wolnobieg / zjazd bez pedałowania).
  bool get isCoasting => cadenceRpm <= 0 && speedMs > 0.2;

  /// Kąt obrotu przedniego i tylnego koła w radianach `[0, 2π)`.
  final double wheelAngleRadians;

  /// Prędkość kątowa koła [rad/s].
  final double wheelAngularVelocity;

  /// Wyliczone kąty wszystkich szprych w radianach `[0, 2π)`.
  final List<double> spokeAnglesRadians;

  /// Profil efektu motion blur dla szprych (aktywny powyżej 40 km/h).
  final WheelMotionBlurProfile motionBlur;

  /// Kąt obrotu tarczy korby i prawego ramienia korby w radianach `[0, 2π)`.
  final double crankAngleRadians;

  /// Kąt obrotu lewego ramienia korby w radianach (`crankAngleRadians + π`).
  double get leftCrankAngleRadians =>
      (crankAngleRadians + math.pi) % (2.0 * math.pi);

  /// Prędkość kątowa tarczy korby [rad/s].
  final double crankAngularVelocity;

  /// Kąt obrotu tylnej kasety w radianach (obraca się tylko podczas pedałowania).
  final double cassetteAngleRadians;

  /// Prędkość liniowa łańcucha w m/s.
  final double chainLinearSpeedMs;

  /// Aktywne przełożenie (tarcza / koronka).
  final DrivetrainGearSelection gear;

  /// Kinematyka wózka i kółek tylnej przerzutki.
  final RearDerailleurKinematics derailleur;

  const WheelAndDrivetrainFrameState({
    required this.riderId,
    required this.speedMs,
    required this.cadenceRpm,
    required this.wheelAngleRadians,
    required this.wheelAngularVelocity,
    required this.spokeAnglesRadians,
    required this.motionBlur,
    required this.crankAngleRadians,
    required this.crankAngularVelocity,
    required this.cassetteAngleRadians,
    required this.chainLinearSpeedMs,
    required this.gear,
    required this.derailleur,
  });
}

/// Wewnętrzny stan całkowania fazy pojedynczego roweru.
class _RiderDrivetrainAccumulator {
  double wheelAngleRad = 0.0;
  double crankAngleRad = 0.0;
  double cassetteAngleRad = 0.0;
  double pulleyAngleRad = 0.0;
  double smoothedCageAngleRad = 0.15;
  double smoothedLateralProgress = 0.35;
  DrivetrainGearSelection? lastGear;
}

/// Moduł animacji mechanicznej kół, korby oraz wózka tylnej przerzutki.
///
/// Odpowiada za:
/// 1. Płynny obrót kół z profilem rozmycia ruchu (motion blur powyżej 40 km/h).
/// 2. Obrót tarczy korby i ramion pedałów dokładnie z kadencją [RPM] (oraz zatrzymanie wolnobiegu na zjeździe).
/// 3. Kinematykę wychylenia i przesuwu bocznego wózka tylnej przerzutki w zależności od wybranego przełożenia.
class WheelAndDrivetrainRotator {
  /// Konfiguracja geometrii napędu.
  final DrivetrainConfig config;

  final Map<String, _RiderDrivetrainAccumulator> _accumulators =
      <String, _RiderDrivetrainAccumulator>{};

  static const double _twoPi = 2.0 * math.pi;

  /// Rozstaw ogniwa łańcucha rowerowego (1/2 cala = 12.7 mm).
  static const double _chainPitchMeters = 0.0127;

  /// Stała czasowa tłumienia ruchu wózka przerzutki przy zmianie przełożenia [1/s].
  static const double _shiftDampingRate = 14.0;

  WheelAndDrivetrainRotator({this.config = const DrivetrainConfig()});

  /// Aktualizuje stan mechaniczny dla pojedynczego kolarza i zwraca kompletną klatkę animacji.
  ///
  /// Jeśli [manualGear] jest `null`, przełożenie dobierane jest automatycznie na podstawie
  /// [speedMs], [cadenceRpm] i [gradientPercent].
  WheelAndDrivetrainFrameState update({
    required String riderId,
    required double dtSeconds,
    required double speedMs,
    required int cadenceRpm,
    double gradientPercent = 0.0,
    DrivetrainGearSelection? manualGear,
    double? initialPhaseSeed,
  }) {
    final double clampedDt = dtSeconds.isFinite && dtSeconds > 0.0
        ? dtSeconds.clamp(0.0, 0.1)
        : 0.0;
    final double safeSpeedMs =
        speedMs.isFinite && speedMs > 0.0 ? speedMs : 0.0;
    final int safeCadenceRpm = cadenceRpm.clamp(0, 200);

    final _RiderDrivetrainAccumulator acc = _accumulators.putIfAbsent(
      riderId,
      () {
        final _RiderDrivetrainAccumulator created =
            _RiderDrivetrainAccumulator();
        if (initialPhaseSeed != null && initialPhaseSeed.isFinite) {
          created.wheelAngleRad = initialPhaseSeed % _twoPi;
          created.crankAngleRad = (initialPhaseSeed * 1.7) % _twoPi;
        }
        return created;
      },
    );

    // 1. Dobór przełożenia (ręczny lub automatyczny z telemetrii).
    final DrivetrainGearSelection gear = manualGear ??
        selectOptimalGear(
          speedMs: safeSpeedMs,
          cadenceRpm: safeCadenceRpm,
          gradientPercent: gradientPercent,
        );
    acc.lastGear = gear;

    // 2. Obrót kół: omega = v / R.
    final double wheelOmega = safeSpeedMs / config.wheelRadiusMeters;
    acc.wheelAngleRad = (acc.wheelAngleRad + wheelOmega * clampedDt) % _twoPi;

    // 3. Obrót tarczy korby: omega = (RPM / 60) * 2π.
    final double crankOmega = (safeCadenceRpm / 60.0) * _twoPi;
    if (safeCadenceRpm > 0) {
      acc.crankAngleRad = (acc.crankAngleRad + crankOmega * clampedDt) % _twoPi;
      // Kaseta obraca się razem z napędem (prędkość kątowa proporcjonalna do przełożenia).
      final double cassetteOmega = crankOmega * gear.gearRatio;
      acc.cassetteAngleRad =
          (acc.cassetteAngleRad + cassetteOmega * clampedDt) % _twoPi;
    }

    // 4. Prędkość liniowa łańcucha i obrót kółek przerzutki (11T).
    final double chainLinearSpeedMs = safeCadenceRpm > 0
        ? (safeCadenceRpm / 60.0) * gear.frontTeeth * _chainPitchMeters
        : 0.0;
    const double pulleyRadiusMeters = 0.022;
    final double pulleyOmega = chainLinearSpeedMs / pulleyRadiusMeters;
    acc.pulleyAngleRad = (acc.pulleyAngleRad + pulleyOmega * clampedDt) % _twoPi;

    // 5. Kąty poszczególnych szprych oraz profil motion blur (> 40 km/h).
    final List<double> spokeAngles = _computeSpokeAngles(acc.wheelAngleRad);
    final WheelMotionBlurProfile blurProfile =
        computeMotionBlurProfile(safeSpeedMs * 3.6);

    // 6. Kinematyka wózka tylnej przerzutki z płynnym tłumieniem zmiany biegów.
    final RearDerailleurKinematics derailleur = _computeDerailleurKinematics(
      acc: acc,
      gear: gear,
      dtSeconds: clampedDt,
    );

    return WheelAndDrivetrainFrameState(
      riderId: riderId,
      speedMs: safeSpeedMs,
      cadenceRpm: safeCadenceRpm,
      wheelAngleRadians: acc.wheelAngleRad,
      wheelAngularVelocity: wheelOmega,
      spokeAnglesRadians: spokeAngles,
      motionBlur: blurProfile,
      crankAngleRadians: acc.crankAngleRad,
      crankAngularVelocity: crankOmega,
      cassetteAngleRadians: acc.cassetteAngleRad,
      chainLinearSpeedMs: chainLinearSpeedMs,
      gear: gear,
      derailleur: derailleur,
    );
  }

  /// Wylicza profil rozmycia ruchu (motion blur) dla zadanej prędkości w km/h.
  WheelMotionBlurProfile computeMotionBlurProfile(double speedKmh) {
    if (config.isDiscWheel) {
      return WheelMotionBlurProfile.none;
    }
    if (!speedKmh.isFinite || speedKmh <= config.motionBlurThresholdKmh) {
      return WheelMotionBlurProfile.none;
    }

    final double span = math.max(
      1.0,
      config.motionBlurFullKmh - config.motionBlurThresholdKmh,
    );
    final double linear =
        ((speedKmh - config.motionBlurThresholdKmh) / span).clamp(0.0, 1.0);
    // Płynna krzywa przyspieszenia rozmycia (ease-out cubic).
    final double inv = 1.0 - linear;
    final double intensity = (1.0 - inv * inv * inv).clamp(0.0, 1.0);

    final int spokes = math.max(1, config.spokeCount);
    final double maxSectorSweep = (_twoPi / spokes) * 0.88;

    return WheelMotionBlurProfile(
      isActive: true,
      intensity: intensity,
      sharpSpokeOpacity: (1.0 - intensity * 0.82).clamp(0.15, 1.0),
      blurDiscOpacity: (0.08 + intensity * 0.44).clamp(0.0, 0.55),
      trailSweepRadians: maxSectorSweep * intensity,
      ghostTrailSteps: 2 + (intensity * 4.0).round(),
    );
  }

  /// Dobiera realistyczne przełożenie szosowe na podstawie prędkości, kadencji i nachylenia.
  DrivetrainGearSelection selectOptimalGear({
    required double speedMs,
    required int cadenceRpm,
    double gradientPercent = 0.0,
  }) {
    final List<int> rings = config.chainringTeeth;
    final List<int> cogs = config.cassetteTeeth;
    if (rings.isEmpty || cogs.isEmpty) {
      return const DrivetrainGearSelection(
        frontChainringIndex: 1,
        rearCogIndex: 3,
        frontTeeth: 54,
        rearTeeth: 14,
      );
    }

    // Gdy kolarz jedzie na luzie (0 RPM), utrzymujemy twarde przełożenie zjazdowe lub ostatnie.
    if (cadenceRpm <= 0 || speedMs <= 0.5) {
      final int ringIdx = gradientPercent > 4.5 ? 0 : rings.length - 1;
      final int cogIdx = gradientPercent > 4.5 ? cogs.length - 3 : 2;
      final int safeCogIdx = cogIdx.clamp(0, cogs.length - 1);
      return DrivetrainGearSelection(
        frontChainringIndex: ringIdx,
        rearCogIndex: safeCogIdx,
        frontTeeth: rings[ringIdx],
        rearTeeth: cogs[safeCogIdx],
      );
    }

    // Wymagane przełożenie z równania: v = (RPM / 60) * ratio * obwód_koła.
    final double targetRatio =
        speedMs / ((cadenceRpm / 60.0) * config.wheelCircumferenceMeters);

    // Preferujemy małą tarczę na stromych podjazdach (>5%) lub przy niskim przełożeniu (<2.25).
    final int preferredRingIdx = (rings.length > 1 &&
            (gradientPercent > 5.0 || targetRatio < 2.25))
        ? 0
        : rings.length - 1;

    int bestRingIdx = preferredRingIdx;
    int bestCogIdx = 0;
    double bestError = double.infinity;

    for (int rIdx = 0; rIdx < rings.length; rIdx++) {
      for (int cIdx = 0; cIdx < cogs.length; cIdx++) {
        final DrivetrainGearSelection candidate = DrivetrainGearSelection(
          frontChainringIndex: rIdx,
          rearCogIndex: cIdx,
          frontTeeth: rings[rIdx],
          rearTeeth: cogs[cIdx],
        );
        final double ratioError = (candidate.gearRatio - targetRatio).abs();
        // Delikatna kara za przekos łańcucha oraz zmianę preferowanej tarczy.
        final double crossPenalty = candidate.isCrossChained(config) ? 0.35 : 0.0;
        final double ringPenalty = rIdx == preferredRingIdx ? 0.0 : 0.12;
        final double totalScore = ratioError + crossPenalty + ringPenalty;
        if (totalScore < bestError) {
          bestError = totalScore;
          bestRingIdx = rIdx;
          bestCogIdx = cIdx;
        }
      }
    }

    return DrivetrainGearSelection(
      frontChainringIndex: bestRingIdx,
      rearCogIndex: bestCogIdx,
      frontTeeth: rings[bestRingIdx],
      rearTeeth: cogs[bestCogIdx],
    );
  }

  List<double> _computeSpokeAngles(double baseWheelAngleRad) {
    if (config.isDiscWheel || config.spokeCount <= 0) {
      return const <double>[];
    }
    final double step = _twoPi / config.spokeCount;
    return List<double>.generate(
      config.spokeCount,
      (int i) => (baseWheelAngleRad + i * step) % _twoPi,
      growable: false,
    );
  }

  RearDerailleurKinematics _computeDerailleurKinematics({
    required _RiderDrivetrainAccumulator acc,
    required DrivetrainGearSelection gear,
    required double dtSeconds,
  }) {
    final int cogCount = math.max(2, config.cassetteTeeth.length);
    final double targetLateralProgress =
        (gear.rearCogIndex / (cogCount - 1)).clamp(0.0, 1.0);

    // Zapotrzebowanie na długość łańcucha określa wychylenie wózka przerzutki:
    // Mała tarcza + mała koronka -> wózek cofnięty do tyłu (-18°).
    // Duża tarcza + duża koronka -> wózek mocno napięty do przodu (+42°).
    final int teethSpan = math.max(1, config.maxTeethDemand - config.minTeethDemand);
    final double demandProgress =
        ((gear.frontTeeth + gear.rearTeeth - config.minTeethDemand) / teethSpan)
            .clamp(0.0, 1.0);

    const double minSwingRad = -18.0 * math.pi / 180.0;
    const double maxSwingRad = 42.0 * math.pi / 180.0;
    final double targetSwingRad =
        minSwingRad + (maxSwingRad - minSwingRad) * demandProgress;

    final double alpha = dtSeconds > 0.0
        ? (1.0 - math.exp(-_shiftDampingRate * dtSeconds)).clamp(0.0, 1.0)
        : 1.0;

    acc.smoothedCageAngleRad +=
        (targetSwingRad - acc.smoothedCageAngleRad) * alpha;
    acc.smoothedLateralProgress +=
        (targetLateralProgress - acc.smoothedLateralProgress) * alpha;

    // Współrzędne lokalne względem osi tylnego koła (X+ w przód roweru, Y+ w dół).
    const Offset bPivot = Offset(-0.008, 0.026);
    final double guideAngle = acc.smoothedCageAngleRad * 0.45;
    final Offset guidePulley = Offset(
      bPivot.dx + math.sin(guideAngle) * 0.024,
      bPivot.dy + math.cos(guideAngle) * 0.024,
    );
    final Offset tensionPulley = Offset(
      guidePulley.dx + math.sin(acc.smoothedCageAngleRad) * config.derailleurCageLengthMeters,
      guidePulley.dy + math.cos(acc.smoothedCageAngleRad) * config.derailleurCageLengthMeters,
    );

    return RearDerailleurKinematics(
      cageSwingAngleRadians: acc.smoothedCageAngleRad,
      lateralCassetteProgress: acc.smoothedLateralProgress,
      lateralOffsetMeters:
          acc.smoothedLateralProgress * (cogCount - 1) * config.cassettePitchMeters,
      guidePulleyLocalMeters: guidePulley,
      tensionPulleyLocalMeters: tensionPulley,
      pulleyRotationRadians: acc.pulleyAngleRad,
      chainTensionFactor: demandProgress,
    );
  }

  /// Usuwa zapamiętany stan fazy dla podanego kolarza.
  void removeRider(String riderId) {
    _accumulators.remove(riderId);
  }

  /// Resetuje fazy animacji wszystkich kolarzy.
  void resetAll() {
    _accumulators.clear();
  }

  /// Rysuje koło szosowe ze szprychami oraz efektem motion blur (> 40 km/h) na podanym [Canvas].
  static void paintWheelWithMotionBlur({
    required Canvas canvas,
    required Offset center,
    required double outerRadiusPx,
    required double rimInnerRadiusPx,
    required WheelAndDrivetrainFrameState state,
    Color tireColor = const Color(0xFF14171D),
    Color carbonRimColor = const Color(0xFF222630),
    Color spokeColor = const Color(0xFFD1D5DB),
    Color hubColor = AppColors.goldAccent,
    double spokeStrokeWidth = 1.4,
  }) {
    if (outerRadiusPx <= 1.0) return;

    final double hubRadius = (outerRadiusPx * 0.095).clamp(2.5, 14.0);
    final double spokeMidRadius = (rimInnerRadiusPx + hubRadius) * 0.5;

    // 1. Opona i karbonowy stożek obręczy.
    final Paint tirePaint = Paint()
      ..color = tireColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, outerRadiusPx * 0.075);
    canvas.drawCircle(center, outerRadiusPx * 0.96, tirePaint);

    final double rimWidth = math.max(1.5, outerRadiusPx - rimInnerRadiusPx);
    final Paint rimPaint = Paint()
      ..color = carbonRimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimWidth;
    canvas.drawCircle(
      center,
      rimInnerRadiusPx + rimWidth * 0.5,
      rimPaint,
    );

    // 2. Efekt rozmycia ruchu (motion blur powyżej 40 km/h).
    final WheelMotionBlurProfile blur = state.motionBlur;
    if (blur.isActive && blur.blurDiscOpacity > 0.01) {
      final Paint blurRingPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          rimInnerRadiusPx,
          <Color>[
            spokeColor.withValues(alpha: 0.0),
            spokeColor.withValues(alpha: blur.blurDiscOpacity * 0.55),
            spokeColor.withValues(alpha: blur.blurDiscOpacity),
            spokeColor.withValues(alpha: 0.0),
          ],
          const <double>[0.0, 0.35, 0.85, 1.0],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, rimInnerRadiusPx - hubRadius);
      canvas.drawCircle(center, spokeMidRadius, blurRingPaint);

      // Kierunkowe łuki smugi za każdą szprychą.
      final Rect arcRect = Rect.fromCircle(center: center, radius: spokeMidRadius);
      for (final double angle in state.spokeAnglesRadians) {
        for (int g = 1; g <= blur.ghostTrailSteps; g++) {
          final double frac = g / (blur.ghostTrailSteps + 1);
          final double ghostAlpha =
              blur.blurDiscOpacity * (1.0 - frac) * 0.85;
          final Paint ghostPaint = Paint()
            ..color = spokeColor.withValues(alpha: ghostAlpha.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = spokeStrokeWidth * (1.2 + blur.intensity * 1.4);
          final double startAngle = angle - blur.trailSweepRadians * frac;
          canvas.drawArc(
            arcRect,
            startAngle,
            blur.trailSweepRadians / (blur.ghostTrailSteps + 1),
            false,
            ghostPaint,
          );
        }
      }
    }

    // 3. Ostre szprychy (zanikają płynnie przy dużych prędkościach).
    if (state.spokeAnglesRadians.isNotEmpty) {
      final Paint spokePaint = Paint()
        ..color = spokeColor.withValues(alpha: blur.sharpSpokeOpacity)
        ..strokeWidth = spokeStrokeWidth
        ..strokeCap = StrokeCap.round;

      for (final double angle in state.spokeAnglesRadians) {
        final double cosA = math.cos(angle);
        final double sinA = math.sin(angle);
        canvas.drawLine(
          Offset(center.dx + cosA * hubRadius, center.dy + sinA * hubRadius),
          Offset(
            center.dx + cosA * rimInnerRadiusPx,
            center.dy + sinA * rimInnerRadiusPx,
          ),
          spokePaint,
        );
      }
    }

    // 4. Piasta centralna.
    final Paint hubPaint = Paint()..color = hubColor;
    canvas.drawCircle(center, hubRadius, hubPaint);
    canvas.drawCircle(
      center,
      hubRadius * 0.45,
      Paint()..color = AppColors.background,
    );
  }

  /// Rysuje kompletny układ napędowy (korba, zębatki, łańcuch, tylna przerzutka) na [Canvas].
  ///
  /// [pixelsPerMeter] określa skalę metryczną modelu (np. `360.0` dla widoku garażowego).
  /// Zakłada kierunek jazdy w prawo (+X).
  static void paintDrivetrain({
    required Canvas canvas,
    required Offset rearAxleCenter,
    required Offset bottomBracketCenter,
    required double pixelsPerMeter,
    required WheelAndDrivetrainFrameState state,
    required DrivetrainConfig config,
  }) {
    final double rearRadiusPx =
        (state.gear.rearTeeth * 0.00205) * pixelsPerMeter;
    final double frontRadiusPx =
        (state.gear.frontTeeth * 0.00205) * pixelsPerMeter;
    final double crankLenPx = config.crankLengthMeters * pixelsPerMeter;

    final Offset guidePx = Offset(
      rearAxleCenter.dx +
          state.derailleur.guidePulleyLocalMeters.dx * pixelsPerMeter,
      rearAxleCenter.dy +
          state.derailleur.guidePulleyLocalMeters.dy * pixelsPerMeter,
    );
    final Offset tensionPx = Offset(
      rearAxleCenter.dx +
          state.derailleur.tensionPulleyLocalMeters.dx * pixelsPerMeter,
      rearAxleCenter.dy +
          state.derailleur.tensionPulleyLocalMeters.dy * pixelsPerMeter,
    );

    // 1. Tylna kaseta (wszystkie koronki w tle + aktywna koronka podświetlona).
    final int cogCount = config.cassetteTeeth.length;
    for (int i = cogCount - 1; i >= 0; i--) {
      final double cogRadius = (config.cassetteTeeth[i] * 0.00205) * pixelsPerMeter;
      final bool isActive = i == state.gear.rearCogIndex;
      canvas.drawCircle(
        rearAxleCenter,
        cogRadius,
        Paint()
          ..color = isActive
              ? AppColors.goldAccent.withValues(alpha: 0.9)
              : const Color(0xFF4B5563).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2.4 : 1.4,
      );
    }

    // 2. Łańcuch (górna nitka napięta + dolna nitka przez wózek przerzutki).
    final Path chainPath = Path()
      ..moveTo(rearAxleCenter.dx, rearAxleCenter.dy - rearRadiusPx)
      ..lineTo(bottomBracketCenter.dx, bottomBracketCenter.dy - frontRadiusPx)
      ..arcTo(
        Rect.fromCircle(center: bottomBracketCenter, radius: frontRadiusPx),
        -math.pi / 2,
        math.pi,
        false,
      )
      ..lineTo(tensionPx.dx, tensionPx.dy + 5.0)
      ..lineTo(guidePx.dx, guidePx.dy - 4.0)
      ..lineTo(rearAxleCenter.dx + rearRadiusPx * 0.65, rearAxleCenter.dy + rearRadiusPx * 0.75);

    canvas.drawPath(
      chainPath,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 3. Wózek tylnej przerzutki (korpus + ramię wózka + 2 obracające się kółka).
    final Offset bPivotPx = Offset(
      rearAxleCenter.dx - 0.008 * pixelsPerMeter,
      rearAxleCenter.dy + 0.026 * pixelsPerMeter,
    );
    canvas.drawLine(
      rearAxleCenter,
      bPivotPx,
      Paint()
        ..color = const Color(0xFF9CA3AF)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      guidePx,
      tensionPx,
      Paint()
        ..color = AppColors.primaryAccent
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );
    _paintPulleyWheel(
      canvas,
      guidePx,
      radius: math.max(4.0, 0.015 * pixelsPerMeter),
      angleRad: state.derailleur.pulleyRotationRadians,
    );
    _paintPulleyWheel(
      canvas,
      tensionPx,
      radius: math.max(4.0, 0.015 * pixelsPerMeter),
      angleRad: state.derailleur.pulleyRotationRadians,
    );

    // 4. Tarcza korby (zębatka obracająca się zgodnie z kadencją RPM).
    canvas.drawCircle(
      bottomBracketCenter,
      frontRadiusPx,
      Paint()
        ..color = const Color(0xFF2D3340)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      bottomBracketCenter,
      frontRadiusPx,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Ramiona pająka korby obracające się z fazą crankAngleRadians.
    final Paint spiderPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (int s = 0; s < 4; s++) {
      final double a = state.crankAngleRadians + s * (math.pi / 2.0);
      canvas.drawLine(
        bottomBracketCenter,
        Offset(
          bottomBracketCenter.dx + math.cos(a) * frontRadiusPx * 0.9,
          bottomBracketCenter.dy + math.sin(a) * frontRadiusPx * 0.9,
        ),
        spiderPaint,
      );
    }

    // 5. Lewe ramię korby (w głębi) oraz prawe ramię korby (na wierzchu).
    _paintCrankArm(
      canvas: canvas,
      center: bottomBracketCenter,
      angleRad: state.leftCrankAngleRadians,
      lengthPx: crankLenPx,
      color: const Color(0xFF4B5563),
    );
    _paintCrankArm(
      canvas: canvas,
      center: bottomBracketCenter,
      angleRad: state.crankAngleRadians,
      lengthPx: crankLenPx,
      color: const Color(0xFFF3F4F6),
    );
  }

  static void _paintPulleyWheel(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double angleRad,
  }) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF1F2937),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.accentBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawLine(
      Offset(
        center.dx - math.cos(angleRad) * radius * 0.7,
        center.dy - math.sin(angleRad) * radius * 0.7,
      ),
      Offset(
        center.dx + math.cos(angleRad) * radius * 0.7,
        center.dy + math.sin(angleRad) * radius * 0.7,
      ),
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 1.2,
    );
  }

  static void _paintCrankArm({
    required Canvas canvas,
    required Offset center,
    required double angleRad,
    required double lengthPx,
    required Color color,
  }) {
    final Offset pedalEnd = Offset(
      center.dx + math.cos(angleRad) * lengthPx,
      center.dy + math.sin(angleRad) * lengthPx,
    );
    canvas.drawLine(
      center,
      pedalEnd,
      Paint()
        ..color = color
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round,
    );
    // Pedał utrzymywany poziomo niezależnie od kąta korby.
    canvas.drawLine(
      Offset(pedalEnd.dx - 7.0, pedalEnd.dy),
      Offset(pedalEnd.dx + 7.0, pedalEnd.dy),
      Paint()
        ..color = AppColors.goldAccent
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Rzutuje lokalne współrzędne 3D punktu szprychy/korby na przestrzeń świata z użyciem macierzy roweru.
Vector3 transformWheelLocalPoint({
  required Vector3 hubLocalPosition,
  required double radiusMeters,
  required double angleRadians,
  required Matrix4 bikeRotationMatrix,
}) {
  final Vector3 localOffset = Vector3(
    math.cos(angleRadians) * radiusMeters,
    math.sin(angleRadians) * radiusMeters,
    0.0,
  );
  return bikeRotationMatrix.transformed3(hubLocalPosition + localOffset);
}
