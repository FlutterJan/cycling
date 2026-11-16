// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Presety nawierzchni i ciśnienia opon dla wizualizacji mikro-detali kół 3D.
enum TireSurfacePreset {
  /// Bruk paryski / flandryjski (niskie ciśnienie 3.8 bar, maksymalne spłaszczenie styku).
  cobblestone(
    label: 'Bruk 3.8 bar',
    pressureBar: 3.8,
    tireWidthMm: 32.0,
    surfaceRoughness: 0.92,
    isDiscWheel: false,
  ),

  /// Mokry asfalt (obniżone ciśnienie 4.8 bar dla przyczepności).
  wetAsphalt(
    label: 'Mokry 4.8 bar',
    pressureBar: 4.8,
    tireWidthMm: 30.0,
    surfaceRoughness: 0.35,
    isDiscWheel: false,
  ),

  /// Standardowy etap szosowy (optymalne 5.5 bar).
  roadStage(
    label: 'Szosa 5.5 bar',
    pressureBar: 5.5,
    tireWidthMm: 28.0,
    surfaceRoughness: 0.18,
    isDiscWheel: false,
  ),

  /// Jazda indywidualna na czas (wysokie ciśnienie 6.5 bar, tylny dysk TT).
  timeTrial(
    label: 'Czasówka 6.5 bar',
    pressureBar: 6.5,
    tireWidthMm: 25.0,
    surfaceRoughness: 0.08,
    isDiscWheel: true,
  );

  final String label;
  final double pressureBar;
  final double tireWidthMm;
  final double surfaceRoughness;
  final bool isDiscWheel;

  const TireSurfacePreset({
    required this.label,
    required this.pressureBar,
    required this.tireWidthMm,
    required this.surfaceRoughness,
    required this.isDiscWheel,
  });
}

/// Konfiguracja fizyki odkształcenia opony oraz odbić światła na szprychach i tarczach.
class TireDeformationConfig {
  /// Minimalne dopuszczalne ciśnienie [bar].
  final double minPressureBar;

  /// Maksymalne dopuszczalne ciśnienie [bar].
  final double maxPressureBar;

  /// Zewnętrzny promień koła z oponą [m] (domyślnie 0.34 m dla 700c).
  final double wheelRadiusMeters;

  /// Liczba szprych koła szosowego (ignorowana dla pełnego dysku).
  final int spokeCount;

  /// Stosunek promienia tarczy hamulcowej do promienia koła (~0.21 dla 140/160 mm).
  final double brakeRotorRadiusRatio;

  /// Mnożnik wizualnego uwypuklenia spłaszczenia na ekranie 3D (dla czytelności z kamery).
  final double visualExaggerationScale;

  /// Szerokość kątowa płata odbicia lustrzanego słońca na szprysze [rad].
  final double spokeGlintWidthRadians;

  /// Szerokość kątowa płata odbicia na tarczy hamulcowej [rad].
  final double rotorGlintWidthRadians;

  const TireDeformationConfig({
    this.minPressureBar = 2.5,
    this.maxPressureBar = 8.5,
    this.wheelRadiusMeters = 0.34,
    this.spokeCount = 18,
    this.brakeRotorRadiusRatio = 0.22,
    this.visualExaggerationScale = 1.85,
    this.spokeGlintWidthRadians = 0.18,
    this.rotorGlintWidthRadians = 0.34,
  });

  TireDeformationConfig copyWith({
    double? minPressureBar,
    double? maxPressureBar,
    double? wheelRadiusMeters,
    int? spokeCount,
    double? brakeRotorRadiusRatio,
    double? visualExaggerationScale,
    double? spokeGlintWidthRadians,
    double? rotorGlintWidthRadians,
  }) {
    return TireDeformationConfig(
      minPressureBar: minPressureBar ?? this.minPressureBar,
      maxPressureBar: maxPressureBar ?? this.maxPressureBar,
      wheelRadiusMeters: wheelRadiusMeters ?? this.wheelRadiusMeters,
      spokeCount: spokeCount ?? this.spokeCount,
      brakeRotorRadiusRatio:
          brakeRotorRadiusRatio ?? this.brakeRotorRadiusRatio,
      visualExaggerationScale:
          visualExaggerationScale ?? this.visualExaggerationScale,
      spokeGlintWidthRadians:
          spokeGlintWidthRadians ?? this.spokeGlintWidthRadians,
      rotorGlintWidthRadians:
          rotorGlintWidthRadians ?? this.rotorGlintWidthRadians,
    );
  }
}

/// Dane wejściowe pojedynczej klatki dla kalkulatora mikro-detali kół 3D.
class TireDeformationFrameInput {
  /// Ciśnienie w oponach [bar] (np. 3.8 na bruku, 6.5 na czasówce).
  final double tirePressureBar;

  /// Łączna masa kolarza i roweru [kg].
  final double totalMassKg;

  /// Udział obciążenia przedniego koła `[0.35, 0.55]` (reszta przypada na tył).
  final double frontWeightDistribution;

  /// Szerokość opony [mm] (np. 25, 28, 32 mm).
  final double tireWidthMm;

  /// Aktualny kąt obrotu koła [rad].
  final double wheelAngleRadians;

  /// Prędkość jazdy [km/h].
  final double speedKmh;

  /// Chropowatość nawierzchni `[0.0, 1.0]` (bruk ~0.9, gładki asfalt ~0.1).
  final double surfaceRoughness;

  /// Znormalizowany wektor kierunku do słońca.
  final vm.Vector3 sunDirection;

  /// Znormalizowany wektor kierunku do kamery.
  final vm.Vector3 cameraViewDirection;

  /// Znormalizowana normalna płaszczyzny koła (oś piasty).
  final vm.Vector3 wheelAxleNormal;

  /// Natężenie światła słonecznego `[0.0, 1.0]` (spada przy zachmurzeniu/cieniu).
  final double sunlightIntensity;

  /// Czy koło jest pełnym dyskiem czasowym (brak szprych).
  final bool isDiscWheel;

  /// Czy rower wyposażony jest w hamulce tarczowe.
  final bool hasDiscBrakes;

  /// Czas symulacji [s] do mikro-oscylacji styku na bruku.
  final double timeSeconds;

  TireDeformationFrameInput({
    this.tirePressureBar = 5.5,
    this.totalMassKg = 76.0,
    this.frontWeightDistribution = 0.44,
    this.tireWidthMm = 28.0,
    this.wheelAngleRadians = 0.0,
    this.speedKmh = 42.0,
    this.surfaceRoughness = 0.15,
    vm.Vector3? sunDirection,
    vm.Vector3? cameraViewDirection,
    vm.Vector3? wheelAxleNormal,
    this.sunlightIntensity = 1.0,
    this.isDiscWheel = false,
    this.hasDiscBrakes = true,
    this.timeSeconds = 0.0,
  }) : sunDirection =
           sunDirection ?? vm.Vector3(0.45, 0.78, 0.43).normalized(),
       cameraViewDirection =
           cameraViewDirection ?? vm.Vector3(0.15, 0.25, 0.96).normalized(),
       wheelAxleNormal = wheelAxleNormal ?? vm.Vector3(0.0, 0.0, 1.0);
}

/// Obliczone parametry spłaszczenia dolnego styku opony z asfaltem.
class TireContactPatchDeformation {
  /// Ciśnienie użyte do obliczeń [bar].
  final double pressureBar;

  /// Fizyczne ugięcie pionowe opony $\delta_z$ w milimetrach [mm].
  final double verticalDeflectionMm;

  /// Znormalizowany współczynnik spłaszczenia `[0.0, 1.0]`.
  final double normalizedSquishRatio;

  /// Długość łaty styku opony z nawierzchnią [mm].
  final double contactPatchLengthMm;

  /// Szerokość styku wraz z wybrzuszeniem bocznym [mm].
  final double contactPatchWidthMm;

  /// Skala pionowa dolnej części opony w rzucie 2D/3D (`< 1.0`).
  final double bottomScaleY;

  /// Współczynnik wybrzuszenia ścianki bocznej przy styku (`>= 1.0`).
  final double sidewallBulgeScaleX;

  /// Obniżenie osi piasty względem promienia nominalnego [m].
  final double hubDropMeters;

  const TireContactPatchDeformation({
    required this.pressureBar,
    required this.verticalDeflectionMm,
    required this.normalizedSquishRatio,
    required this.contactPatchLengthMm,
    required this.contactPatchWidthMm,
    required this.bottomScaleY,
    required this.sidewallBulgeScaleX,
    required this.hubDropMeters,
  });
}

/// Pojedynczy błysk światła słonecznego na obracającej się szprysze.
class SpokeGlintSample {
  /// Indeks szprychy (`0 .. spokeCount - 1`).
  final int spokeIndex;

  /// Kąt położenia szprychy w płaszczyźnie koła [rad].
  final double angleRadians;

  /// Intensywność błysku słonecznego `[0.0, 1.0]`.
  final double glintIntensity;

  /// Kolor odblasku (ciepłe złoto-białe światło słoneczne).
  final Color specularColor;

  /// Kątowy rozrzut smugi błysku przy wyższej prędkości [rad].
  final double streakArcRadians;

  const SpokeGlintSample({
    required this.spokeIndex,
    required this.angleRadians,
    required this.glintIntensity,
    required this.specularColor,
    required this.streakArcRadians,
  });
}

/// Stan błysku słonecznego na obracającej się tarczy hamulcowej.
class BrakeRotorGlintState {
  /// Główna intensywność odbicia na powierzchni tarczy `[0.0, 1.0]`.
  final double rotorGlintIntensity;

  /// Kąt orientacji głównego refleksyjnego łuku na tarczy [rad].
  final double highlightAngleRadians;

  /// Wtórny refleks przeciwny (symetria szczotkowanej stali) `[0.0, 1.0]`.
  final double secondaryGlintIntensity;

  /// Kolor bazowy stali tarczy z domieszką światła słonecznego.
  final Color rotorHighlightColor;

  const BrakeRotorGlintState({
    required this.rotorGlintIntensity,
    required this.highlightAngleRadians,
    required this.secondaryGlintIntensity,
    required this.rotorHighlightColor,
  });
}

/// Zbiorczy stan mikro-detali kół 3D w pojedynczej klatce renderingu.
class TireDeformationAndSpokeGlintState {
  final TireContactPatchDeformation frontTire;
  final TireContactPatchDeformation rearTire;
  final List<SpokeGlintSample> spokeGlints;
  final BrakeRotorGlintState brakeRotorGlint;
  final double peakSpokeGlintIntensity;
  final double effectiveSunlightFactor;

  const TireDeformationAndSpokeGlintState({
    required this.frontTire,
    required this.rearTire,
    required this.spokeGlints,
    required this.brakeRotorGlint,
    required this.peakSpokeGlintIntensity,
    required this.effectiveSunlightFactor,
  });
}

/// Kalkulator i renderer mikro-detali kół 3D:
/// - spłaszczenie dolnego styku opony z asfaltem zależne od ciśnienia (np. 3.8 bar bruk vs 6.5 bar TT),
/// - błyski światła słonecznego na obracających się szprychach i tarczach hamulcowych.
class TireDeformationAndSpokeGlintFx {
  final TireDeformationConfig config;

  const TireDeformationAndSpokeGlintFx({
    this.config = const TireDeformationConfig(),
  });

  /// Oblicza fizyczne i wizualne spłaszczenie dolnego styku opony z nawierzchnią.
  TireContactPatchDeformation computeTireDeformation({
    required double pressureBar,
    required double wheelLoadKg,
    double tireWidthMm = 28.0,
    double surfaceRoughness = 0.15,
    double speedKmh = 40.0,
    double timeSeconds = 0.0,
  }) {
    final double clampedPressure = pressureBar.clamp(
      config.minPressureBar,
      config.maxPressureBar,
    );
    final double safeLoadKg = wheelLoadKg.clamp(15.0, 95.0);
    final double safeWidthMm = tireWidthMm.clamp(20.0, 45.0);
    final double roughness = surfaceRoughness.clamp(0.0, 1.0);

    // Prawo styku pneumatycznego: ugięcie rośnie proporcjonalnie do obciążenia
    // oraz odwrotnie proporcjonalnie do ciśnienia i szerokości opony.
    // Dla 3.8 bar i ~42 kg na tylnym kole daje ~6.2 mm ugięcia;
    // dla 6.5 bar na czasówce daje ~2.7 mm ugięcia.
    final double loadNewtons = safeLoadKg * 9.80665;
    final double pressureKpa = clampedPressure * 100.0;
    final double casingStiffnessFactor = 1.0 + (28.0 / safeWidthMm - 1.0) * 0.25;
    final double rawDeflectionMm =
        (loadNewtons / (pressureKpa * 0.185 * casingStiffnessFactor)) * 1.18;

    // Mikro-pulsacja styku na nierównościach (bruk zwiększa chwilowe ugięcie opony).
    final double speedFactor = (speedKmh.clamp(0.0, 90.0) / 45.0);
    final double cobbleImpactPulse =
        roughness *
        0.55 *
        (0.5 + 0.5 * math.sin(timeSeconds * (18.0 + speedFactor * 26.0)));

    final double totalDeflectionMm = (rawDeflectionMm + cobbleImpactPulse)
        .clamp(1.2, safeWidthMm * 0.42);

    // Długość łaty styku z geometrii cięciwy koła: L = 2 * sqrt(2*R*d - d^2).
    final double radiusMm = config.wheelRadiusMeters * 1000.0;
    final double chordTerm = math.max(
      0.0,
      2.0 * radiusMm * totalDeflectionMm - totalDeflectionMm * totalDeflectionMm,
    );
    final double contactLengthMm = 2.0 * math.sqrt(chordTerm);

    // Wybrzuszenie boczne ścianki w strefie styku.
    final double normalizedSquish = ((totalDeflectionMm - 1.8) / 7.0).clamp(
      0.0,
      1.0,
    );
    final double bulgeRatio = 1.0 + normalizedSquish * 0.18;
    final double contactWidthMm = safeWidthMm * bulgeRatio;

    // Parametry deformacji dla rzutowania 3D / Canvas.
    final double visualFactor =
        (totalDeflectionMm / radiusMm) * config.visualExaggerationScale;
    final double bottomScaleY = (1.0 - visualFactor * 3.1).clamp(0.74, 0.985);
    final double sidewallBulgeScaleX = (1.0 + normalizedSquish * 0.085).clamp(
      1.0,
      1.12,
    );

    return TireContactPatchDeformation(
      pressureBar: clampedPressure,
      verticalDeflectionMm: totalDeflectionMm,
      normalizedSquishRatio: normalizedSquish,
      contactPatchLengthMm: contactLengthMm,
      contactPatchWidthMm: contactWidthMm,
      bottomScaleY: bottomScaleY,
      sidewallBulgeScaleX: sidewallBulgeScaleX,
      hubDropMeters: totalDeflectionMm / 1000.0,
    );
  }

  /// Wylicza błyski światła słonecznego na obracających się szprychach koła.
  List<SpokeGlintSample> computeSpokeGlints({
    required double wheelAngleRadians,
    required vm.Vector3 sunDirection,
    required vm.Vector3 cameraViewDirection,
    required vm.Vector3 wheelAxleNormal,
    double sunlightIntensity = 1.0,
    double speedKmh = 40.0,
    bool isDiscWheel = false,
  }) {
    if (isDiscWheel || config.spokeCount <= 0 || sunlightIntensity <= 0.01) {
      return const <SpokeGlintSample>[];
    }

    final vm.Vector3 sunDir = _safeNormalized(
      sunDirection,
      vm.Vector3(0.45, 0.78, 0.43).normalized(),
    );
    final vm.Vector3 viewDir = _safeNormalized(
      cameraViewDirection,
      vm.Vector3(0.15, 0.25, 0.96).normalized(),
    );
    final vm.Vector3 axle = _safeNormalized(
      wheelAxleNormal,
      vm.Vector3(0.0, 0.0, 1.0),
    );

    // Wektor połówkowy Blinna-Phonga rzutowany na płaszczyznę koła.
    final vm.Vector3 halfVector = _safeNormalized(sunDir + viewDir, sunDir);
    final double axleDotH = halfVector.dot(axle);
    final vm.Vector3 halfInPlane = halfVector - axle * axleDotH;
    final double inPlaneLen = halfInPlane.length;

    // Baza ortonormalna w płaszczyźnie koła.
    final vm.Vector3 upRef = axle.y.abs() < 0.92
        ? vm.Vector3(0.0, 1.0, 0.0)
        : vm.Vector3(1.0, 0.0, 0.0);
    final vm.Vector3 tangentU = upRef.cross(axle).normalized();
    final vm.Vector3 tangentV = axle.cross(tangentU).normalized();

    final double optimalGlintAngle = inPlaneLen > 1e-4
        ? math.atan2(halfInPlane.dot(tangentV), halfInPlane.dot(tangentU))
        : 0.78;

    // Równoległość wektora połówkowego do płaszczyzny koła wzmacnia refleks na płaskich szprychach aero.
    final double planeAlignment = (1.0 - axleDotH.abs() * 0.55).clamp(0.2, 1.0);
    final double clampedSun = sunlightIntensity.clamp(0.0, 1.0);
    final double streakArc =
        0.02 + (speedKmh.clamp(0.0, 85.0) / 85.0) * 0.14;

    final int count = config.spokeCount;
    final double step = (2.0 * math.pi) / count;
    final double width = math.max(0.05, config.spokeGlintWidthRadians);
    final List<SpokeGlintSample> samples = <SpokeGlintSample>[];

    for (int i = 0; i < count; i++) {
      final double spokeAngle = wheelAngleRadians + i * step;
      // Szprycha odbija kierunkowo zarówno pod kątem $\theta$, jak i $\theta + \pi/2$ (krawędź aero).
      final double deltaPrimary = _shortestAngleDiff(
        spokeAngle,
        optimalGlintAngle,
      );
      final double deltaSecondary = _shortestAngleDiff(
        spokeAngle,
        optimalGlintAngle + math.pi,
      );
      final double minDelta = math.min(deltaPrimary.abs(), deltaSecondary.abs());

      final double gaussianLobe = math.exp(
        -(minDelta * minDelta) / (2.0 * width * width),
      );
      final double intensity = (gaussianLobe * planeAlignment * clampedSun)
          .clamp(0.0, 1.0);

      final Color specularColor = Color.lerp(
        const Color(0xFFFFF4CC),
        Colors.white,
        intensity,
      )!;

      samples.add(
        SpokeGlintSample(
          spokeIndex: i,
          angleRadians: spokeAngle,
          glintIntensity: intensity,
          specularColor: specularColor,
          streakArcRadians: streakArc * (0.4 + 0.6 * intensity),
        ),
      );
    }

    return samples;
  }

  /// Oblicza błysk światła słonecznego na obracającej się tarczy hamulcowej.
  BrakeRotorGlintState computeBrakeRotorGlint({
    required double wheelAngleRadians,
    required vm.Vector3 sunDirection,
    required vm.Vector3 cameraViewDirection,
    required vm.Vector3 wheelAxleNormal,
    double sunlightIntensity = 1.0,
    bool hasDiscBrakes = true,
  }) {
    if (!hasDiscBrakes || sunlightIntensity <= 0.01) {
      return const BrakeRotorGlintState(
        rotorGlintIntensity: 0.0,
        highlightAngleRadians: 0.0,
        secondaryGlintIntensity: 0.0,
        rotorHighlightColor: Color(0xFF9CA3AF),
      );
    }

    final vm.Vector3 sunDir = _safeNormalized(
      sunDirection,
      vm.Vector3(0.45, 0.78, 0.43).normalized(),
    );
    final vm.Vector3 viewDir = _safeNormalized(
      cameraViewDirection,
      vm.Vector3(0.15, 0.25, 0.96).normalized(),
    );
    final vm.Vector3 axle = _safeNormalized(
      wheelAxleNormal,
      vm.Vector3(0.0, 0.0, 1.0),
    );

    final vm.Vector3 halfVec = _safeNormalized(sunDir + viewDir, sunDir);
    final double fresnelBoost = math.pow(
      (1.0 - viewDir.dot(axle).abs()).clamp(0.0, 1.0),
      1.6,
    ).toDouble();
    final double alignment = math.max(0.0, halfVec.dot(axle)).clamp(0.0, 1.0);

    // Anizotropowe szczotkowanie stali powoduje pulsowanie błysku przy obrocie otworów wentylacyjnych tarczy.
    final double rotorSlotModulation =
        0.72 + 0.28 * math.sin(wheelAngleRadians * 6.0);
    final double baseIntensity =
        ((0.35 + 0.65 * alignment) *
                (0.65 + 0.35 * fresnelBoost) *
                rotorSlotModulation *
                sunlightIntensity)
            .clamp(0.0, 1.0);

    final double secondary = (baseIntensity * 0.58).clamp(0.0, 1.0);
    final double highlightAngle =
        math.atan2(sunDir.y, sunDir.x) + math.sin(wheelAngleRadians * 3.0) * 0.08;

    final Color rotorColor = Color.lerp(
      const Color(0xFFD1D5DB),
      const Color(0xFFFFFBEB),
      baseIntensity,
    )!;

    return BrakeRotorGlintState(
      rotorGlintIntensity: baseIntensity,
      highlightAngleRadians: highlightAngle,
      secondaryGlintIntensity: secondary,
      rotorHighlightColor: rotorColor,
    );
  }

  /// Wylicza pełny stan mikro-detali dla klatki 3D (przednia i tylna opona, szprychy, tarcza).
  TireDeformationAndSpokeGlintState evaluateFrame(
    TireDeformationFrameInput input,
  ) {
    final double frontFraction = input.frontWeightDistribution.clamp(0.30, 0.60);
    final double rearFraction = 1.0 - frontFraction;

    final TireContactPatchDeformation frontDeformation = computeTireDeformation(
      pressureBar: input.tirePressureBar,
      wheelLoadKg: input.totalMassKg * frontFraction,
      tireWidthMm: input.tireWidthMm,
      surfaceRoughness: input.surfaceRoughness,
      speedKmh: input.speedKmh,
      timeSeconds: input.timeSeconds,
    );

    final TireContactPatchDeformation rearDeformation = computeTireDeformation(
      pressureBar: input.tirePressureBar,
      wheelLoadKg: input.totalMassKg * rearFraction,
      tireWidthMm: input.tireWidthMm,
      surfaceRoughness: input.surfaceRoughness,
      speedKmh: input.speedKmh,
      timeSeconds: input.timeSeconds + 0.04,
    );

    final List<SpokeGlintSample> glints = computeSpokeGlints(
      wheelAngleRadians: input.wheelAngleRadians,
      sunDirection: input.sunDirection,
      cameraViewDirection: input.cameraViewDirection,
      wheelAxleNormal: input.wheelAxleNormal,
      sunlightIntensity: input.sunlightIntensity,
      speedKmh: input.speedKmh,
      isDiscWheel: input.isDiscWheel,
    );

    final BrakeRotorGlintState rotor = computeBrakeRotorGlint(
      wheelAngleRadians: input.wheelAngleRadians,
      sunDirection: input.sunDirection,
      cameraViewDirection: input.cameraViewDirection,
      wheelAxleNormal: input.wheelAxleNormal,
      sunlightIntensity: input.sunlightIntensity,
      hasDiscBrakes: input.hasDiscBrakes,
    );

    double peakSpoke = 0.0;
    for (final SpokeGlintSample sample in glints) {
      if (sample.glintIntensity > peakSpoke) {
        peakSpoke = sample.glintIntensity;
      }
    }

    return TireDeformationAndSpokeGlintState(
      frontTire: frontDeformation,
      rearTire: rearDeformation,
      spokeGlints: glints,
      brakeRotorGlint: rotor,
      peakSpokeGlintIntensity: peakSpoke,
      effectiveSunlightFactor: input.sunlightIntensity.clamp(0.0, 1.0),
    );
  }

  /// Generuje punkty obrysu opony ze spłaszczonym dolnym stykiem z asfaltem.
  List<Offset> buildDeformedTireProfilePoints({
    required Offset wheelCenter,
    required double screenRadiusPx,
    required TireContactPatchDeformation deformation,
    int segments = 56,
  }) {
    final int safeSegments = math.max(16, segments);
    final List<Offset> points = List<Offset>.filled(
      safeSegments,
      Offset.zero,
      growable: false,
    );

    // Płaski próg styku w pobliżu dolnej części koła (sin(theta) > 0).
    final double contactFloorY =
        wheelCenter.dy + screenRadiusPx * deformation.bottomScaleY;

    for (int i = 0; i < safeSegments; i++) {
      final double theta = (i / safeSegments) * 2.0 * math.pi;
      final double cosT = math.cos(theta);
      final double sinT = math.sin(theta);

      // Płynne wybrzuszenie boczne w dolnej połowie opony.
      final double bottomWeight = math.max(0.0, sinT);
      final double bulgeX =
          1.0 + (deformation.sidewallBulgeScaleX - 1.0) * bottomWeight;

      final double rawX = wheelCenter.dx + cosT * screenRadiusPx * bulgeX;
      double rawY = wheelCenter.dy + sinT * screenRadiusPx;

      if (rawY > contactFloorY) {
        // Miękkie spłaszczenie przy styku z asfaltem (z zachowaniem ciągłości C1).
        final double excess = rawY - contactFloorY;
        rawY = contactFloorY + excess * 0.08;
      }

      points[i] = Offset(rawX, rawY);
    }

    return points;
  }

  /// Rysuje kompletne mikro-detale koła 3D na Canvasie: spłaszczoną oponę, obręcz,
  /// tarczę hamulcową z błyskiem i szprychy z refleksami słonecznymi.
  void paintWheelMicroDetails({
    required Canvas canvas,
    required Offset wheelCenter,
    required double screenRadiusPx,
    required double wheelAngleRadians,
    required TireContactPatchDeformation deformation,
    required List<SpokeGlintSample> spokeGlints,
    required BrakeRotorGlintState rotorGlint,
    bool isDiscWheel = false,
    bool hasDiscBrakes = true,
    Color tireColor = const Color(0xFF17191E),
    Color rimColor = const Color(0xFF2B303C),
  }) {
    if (screenRadiusPx <= 2.0) return;

    final double tireThickness = (screenRadiusPx * 0.115).clamp(2.5, 20.0);
    final double rimOuterRadius = screenRadiusPx - tireThickness;
    final double rimInnerRadius = (rimOuterRadius * 0.84).clamp(
      2.0,
      rimOuterRadius,
    );
    final double contactY =
        wheelCenter.dy + screenRadiusPx * deformation.bottomScaleY;

    // 1. Cień styku opony na nawierzchni (szerszy przy niższym ciśnieniu).
    final double patchHalfWidth =
        screenRadiusPx * (0.28 + deformation.normalizedSquishRatio * 0.24);
    final Rect contactShadowRect = Rect.fromCenter(
      center: Offset(wheelCenter.dx, contactY + 2.0),
      width: patchHalfWidth * 2.2,
      height: (screenRadiusPx * 0.09).clamp(3.0, 14.0),
    );
    canvas.drawOval(
      contactShadowRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // 2. Zdeformowana opona (spłaszczona u dołu).
    final List<Offset> outerPoints = buildDeformedTireProfilePoints(
      wheelCenter: wheelCenter,
      screenRadiusPx: screenRadiusPx,
      deformation: deformation,
    );
    final Path tirePath = Path()..addPolygon(outerPoints, true);
    canvas.drawPath(
      tirePath,
      Paint()
        ..color = tireColor
        ..style = PaintingStyle.fill,
    );

    // Subtelny rant Tan-Wall / bieżnik dla głębi.
    canvas.drawPath(
      tirePath,
      Paint()
        ..color = const Color(0xFF3A3F4B).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 3. Obręcz karbonowa.
    canvas.drawCircle(
      wheelCenter,
      rimOuterRadius,
      Paint()..color = rimColor,
    );

    if (isDiscWheel) {
      // Pełny dysk czasowy z radialnym połyskiem włókna węglowego.
      final Paint discPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: wheelAngleRadians,
          endAngle: wheelAngleRadians + math.pi * 2.0,
          colors: const <Color>[
            Color(0xFF181B22),
            Color(0xFF2B313E),
            Color(0xFF15181F),
            Color(0xFF323948),
            Color(0xFF181B22),
          ],
        ).createShader(
          Rect.fromCircle(center: wheelCenter, radius: rimOuterRadius),
        );
      canvas.drawCircle(wheelCenter, rimInnerRadius, discPaint);
    } else {
      // Wnętrze koła szprychowego (prześwit na tło).
      canvas.drawCircle(
        wheelCenter,
        rimInnerRadius,
        Paint()..color = AppColors.background.withValues(alpha: 0.85),
      );

      // 4. Szprychy z błyskami słońca.
      final double hubRadius = (screenRadiusPx * 0.085).clamp(2.5, 12.0);
      for (final SpokeGlintSample glint in spokeGlints) {
        final double cosA = math.cos(glint.angleRadians);
        final double sinA = math.sin(glint.angleRadians);
        final Offset pStart = Offset(
          wheelCenter.dx + cosA * hubRadius,
          wheelCenter.dy + sinA * hubRadius,
        );
        final Offset pEnd = Offset(
          wheelCenter.dx + cosA * rimInnerRadius,
          wheelCenter.dy + sinA * rimInnerRadius,
        );

        final Color baseSpokeColor = Color.lerp(
          const Color(0xFF565E6E),
          glint.specularColor,
          glint.glintIntensity,
        )!;
        canvas.drawLine(
          pStart,
          pEnd,
          Paint()
            ..color = baseSpokeColor
            ..strokeWidth = (1.2 + glint.glintIntensity * 1.6).clamp(1.0, 3.0)
            ..strokeCap = StrokeCap.round,
        );

        // Rozbłysk punktowy przy silnym trafieniu światła w szprychę.
        if (glint.glintIntensity > 0.62) {
          final double glintDist = rimInnerRadius * 0.58;
          final Offset flashCenter = Offset(
            wheelCenter.dx + cosA * glintDist,
            wheelCenter.dy + sinA * glintDist,
          );
          canvas.drawCircle(
            flashCenter,
            (screenRadiusPx * 0.045) * glint.glintIntensity,
            Paint()
              ..color = glint.specularColor.withValues(
                alpha: (glint.glintIntensity - 0.35).clamp(0.0, 0.85),
              )
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
          );
        }
      }
    }

    // 5. Tarcza hamulcowa z metalicznym błyskiem słońca.
    if (hasDiscBrakes) {
      final double rotorRadius =
          screenRadiusPx * config.brakeRotorRadiusRatio;
      final double rotorInnerRadius = rotorRadius * 0.52;

      canvas.drawCircle(
        wheelCenter,
        rotorRadius,
        Paint()
          ..color = const Color(0xFF8B93A3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (rotorRadius - rotorInnerRadius).clamp(2.0, 14.0),
      );

      // Łuk refleksyjny światła na szczotkowanej stali tarczy.
      if (rotorGlint.rotorGlintIntensity > 0.05) {
        final double midRadius = (rotorRadius + rotorInnerRadius) * 0.5;
        final Rect rotorArcRect = Rect.fromCircle(
          center: wheelCenter,
          radius: midRadius,
        );
        final Paint glintArcPaint = Paint()
          ..color = rotorGlint.rotorHighlightColor.withValues(
            alpha: (rotorGlint.rotorGlintIntensity * 0.9).clamp(0.0, 0.95),
          )
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = (rotorRadius - rotorInnerRadius) * 0.72;

        canvas.drawArc(
          rotorArcRect,
          rotorGlint.highlightAngleRadians - 0.38,
          0.76,
          false,
          glintArcPaint,
        );
        canvas.drawArc(
          rotorArcRect,
          rotorGlint.highlightAngleRadians + math.pi - 0.28,
          0.56,
          false,
          glintArcPaint
            ..color = rotorGlint.rotorHighlightColor.withValues(
              alpha: (rotorGlint.secondaryGlintIntensity * 0.75).clamp(
                0.0,
                0.85,
              ),
            ),
        );
      }

      // Otwory wentylacyjne tarczy obracające się z kołem.
      final double ventRadius = (rotorRadius + rotorInnerRadius) * 0.5;
      const int ventCount = 12;
      for (int i = 0; i < ventCount; i++) {
        final double a = wheelAngleRadians + (i * 2.0 * math.pi / ventCount);
        canvas.drawCircle(
          Offset(
            wheelCenter.dx + math.cos(a) * ventRadius,
            wheelCenter.dy + math.sin(a) * ventRadius,
          ),
          (rotorRadius * 0.06).clamp(0.8, 2.5),
          Paint()..color = AppColors.background,
        );
      }
    }

    // 6. Piasta centralna.
    final double hubSize = (screenRadiusPx * 0.08).clamp(2.5, 11.0);
    canvas.drawCircle(
      wheelCenter,
      hubSize,
      Paint()..color = const Color(0xFF1F242E),
    );
    canvas.drawCircle(
      wheelCenter,
      hubSize * 0.55,
      Paint()..color = AppColors.goldAccent.withValues(alpha: 0.75),
    );
  }

  static vm.Vector3 _safeNormalized(vm.Vector3 v, vm.Vector3 fallback) {
    final double len = v.length;
    if (len < 1e-6) return fallback;
    return v / len;
  }

  static double _shortestAngleDiff(double a, double b) {
    double diff = (a - b) % (2.0 * math.pi);
    if (diff > math.pi) diff -= 2.0 * math.pi;
    if (diff < -math.pi) diff += 2.0 * math.pi;
    return diff;
  }
}

/// Painter prezentujący mikro-detale koła 3D: spłaszczenie styku opony oraz błyski szprych i tarcz.
class TireDeformationWheelPainter extends CustomPainter {
  final TireDeformationAndSpokeGlintFx fx;
  final TireDeformationAndSpokeGlintState state;
  final double wheelAngleRadians;
  final bool isDiscWheel;
  final bool hasDiscBrakes;
  final double surfaceRoughness;

  const TireDeformationWheelPainter({
    required this.fx,
    required this.state,
    required this.wheelAngleRadians,
    this.isDiscWheel = false,
    this.hasDiscBrakes = true,
    this.surfaceRoughness = 0.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width * 0.36, size.height * 0.38);
    if (radius <= 4.0) return;

    final Offset center = Offset(size.width * 0.5, size.height * 0.47);
    final double roadTopY =
        center.dy + radius * state.rearTire.bottomScaleY + 1.0;

    // Nawierzchnia szosy lub bruku pod kołem.
    final Rect roadRect = Rect.fromLTWH(
      0,
      roadTopY,
      size.width,
      math.max(0.0, size.height - roadTopY),
    );
    canvas.drawRect(
      roadRect,
      Paint()
        ..color = surfaceRoughness > 0.55
            ? const Color(0xFF23262E)
            : const Color(0xFF171A21),
    );

    // Kostka brukowa lub ziarno asfaltu.
    if (surfaceRoughness > 0.55) {
      final Paint cobblePaint = Paint()
        ..color = const Color(0xFF313644)
        ..style = PaintingStyle.fill;
      const double blockW = 22.0;
      const double blockH = 9.0;
      for (double x = -12.0; x < size.width + blockW; x += blockW + 4.0) {
        final double shift = ((wheelAngleRadians * radius) % (blockW + 4.0));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - shift, roadTopY + 2.0, blockW, blockH),
            const Radius.circular(2.5),
          ),
          cobblePaint,
        );
      }
    }

    // Linia nominalnego promienia bez ugięcia (złota linia referencyjna).
    final double nominalBottomY = center.dy + radius;
    canvas.drawLine(
      Offset(center.dx - radius * 0.65, nominalBottomY),
      Offset(center.dx + radius * 0.65, nominalBottomY),
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.35)
        ..strokeWidth = 1.0,
    );

    fx.paintWheelMicroDetails(
      canvas: canvas,
      wheelCenter: center,
      screenRadiusPx: radius,
      wheelAngleRadians: wheelAngleRadians,
      deformation: state.rearTire,
      spokeGlints: state.spokeGlints,
      rotorGlint: state.brakeRotorGlint,
      isDiscWheel: isDiscWheel,
      hasDiscBrakes: hasDiscBrakes,
    );
  }

  @override
  bool shouldRepaint(covariant TireDeformationWheelPainter oldDelegate) {
    return oldDelegate.wheelAngleRadians != wheelAngleRadians ||
        oldDelegate.isDiscWheel != isDiscWheel ||
        oldDelegate.hasDiscBrakes != hasDiscBrakes ||
        oldDelegate.surfaceRoughness != surfaceRoughness ||
        oldDelegate.state.rearTire.pressureBar != state.rearTire.pressureBar ||
        oldDelegate.state.peakSpokeGlintIntensity !=
            state.peakSpokeGlintIntensity;
  }
}

/// Interaktywny panel podglądu i sterowania mikro-detalami kół 3D.
class TireDeformationAndSpokeGlintPanel extends StatefulWidget {
  final TireDeformationConfig config;
  final TireSurfacePreset initialPreset;
  final bool animateByDefault;

  const TireDeformationAndSpokeGlintPanel({
    super.key,
    this.config = const TireDeformationConfig(),
    this.initialPreset = TireSurfacePreset.cobblestone,
    this.animateByDefault = true,
  });

  @override
  State<TireDeformationAndSpokeGlintPanel> createState() =>
      _TireDeformationAndSpokeGlintPanelState();
}

class _TireDeformationAndSpokeGlintPanelState
    extends State<TireDeformationAndSpokeGlintPanel>
    with SingleTickerProviderStateMixin {
  late final TireDeformationAndSpokeGlintFx _fx;
  late final AnimationController _rotationController;

  late TireSurfacePreset _selectedPreset;
  late double _pressureBar;
  late double _tireWidthMm;
  late double _surfaceRoughness;
  late bool _isDiscWheel;
  bool _hasDiscBrakes = true;
  double _speedKmh = 44.0;
  double _sunAzimuthDegrees = 42.0;
  bool _isAnimating = true;
  double _wheelAngleRadians = 0.0;
  double _elapsedSeconds = 0.0;

  @override
  void initState() {
    super.initState();
    _fx = TireDeformationAndSpokeGlintFx(config: widget.config);
    _selectedPreset = widget.initialPreset;
    _pressureBar = widget.initialPreset.pressureBar;
    _tireWidthMm = widget.initialPreset.tireWidthMm;
    _surfaceRoughness = widget.initialPreset.surfaceRoughness;
    _isDiscWheel = widget.initialPreset.isDiscWheel;
    _isAnimating = widget.animateByDefault;

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_onTick);

    if (_isAnimating) {
      _rotationController.repeat();
    }
  }

  void _onTick() {
    if (!mounted || !_isAnimating) return;
    final double speedMetersPerSec = _speedKmh / 3.6;
    final double angularVelocity =
        speedMetersPerSec / widget.config.wheelRadiusMeters;
    const double dt = 1.0 / 60.0;
    setState(() {
      _elapsedSeconds += dt;
      _wheelAngleRadians =
          (_wheelAngleRadians + angularVelocity * dt) % (2.0 * math.pi);
    });
  }

  void _applyPreset(TireSurfacePreset preset) {
    setState(() {
      _selectedPreset = preset;
      _pressureBar = preset.pressureBar;
      _tireWidthMm = preset.tireWidthMm;
      _surfaceRoughness = preset.surfaceRoughness;
      _isDiscWheel = preset.isDiscWheel;
    });
  }

  void _togglePlayback() {
    setState(() {
      _isAnimating = !_isAnimating;
      if (_isAnimating) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.removeListener(_onTick);
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sunRad = _sunAzimuthDegrees * (math.pi / 180.0);
    final TireDeformationFrameInput frameInput = TireDeformationFrameInput(
      tirePressureBar: _pressureBar,
      tireWidthMm: _tireWidthMm,
      wheelAngleRadians: _wheelAngleRadians,
      speedKmh: _speedKmh,
      surfaceRoughness: _surfaceRoughness,
      sunDirection: vm.Vector3(
        math.cos(sunRad) * 0.72,
        0.68,
        math.sin(sunRad) * 0.45,
      ).normalized(),
      isDiscWheel: _isDiscWheel,
      hasDiscBrakes: _hasDiscBrakes,
      timeSeconds: _elapsedSeconds,
    );
    final TireDeformationAndSpokeGlintState state = _fx.evaluateFrame(
      frameInput,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        final double canvasHeight = isCompact ? 180.0 : 220.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                _buildPresetRow(),
                const SizedBox(height: 12),
                Container(
                  height: canvasHeight,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder, width: 1.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: TireDeformationWheelPainter(
                      fx: _fx,
                      state: state,
                      wheelAngleRadians: _wheelAngleRadians,
                      isDiscWheel: _isDiscWheel,
                      hasDiscBrakes: _hasDiscBrakes,
                      surfaceRoughness: _surfaceRoughness,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTelemetryGrid(state, isCompact),
                const SizedBox(height: 12),
                _buildControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      children: <Widget>[
        const Icon(
          Icons.tire_repair,
          color: AppColors.goldAccent,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mikro-detale Kół 3D: Styk Opony & Błyski Szprych',
            maxLines: isCompact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _InteractiveFxChipButton(
          label: _isAnimating ? 'Pauza' : 'Start',
          selected: _isAnimating,
          onPressed: _togglePlayback,
        ),
      ],
    );
  }

  Widget _buildPresetRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TireSurfacePreset.values.map((TireSurfacePreset preset) {
        return _InteractiveFxChipButton(
          label: preset.label,
          selected: _selectedPreset == preset,
          onPressed: () => _applyPreset(preset),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildTelemetryGrid(
    TireDeformationAndSpokeGlintState state,
    bool isCompact,
  ) {
    final List<Widget> tiles = <Widget>[
      _TelemetryStatTile(
        label: 'Ugięcie styku (tył)',
        value: '${state.rearTire.verticalDeflectionMm.toStringAsFixed(1)} mm',
        accent: state.rearTire.normalizedSquishRatio > 0.55
            ? AppColors.amberWarning
            : AppColors.accentBlue,
      ),
      _TelemetryStatTile(
        label: 'Długość styku',
        value: '${state.rearTire.contactPatchLengthMm.toStringAsFixed(0)} mm',
        accent: AppColors.cyanAccent,
      ),
      _TelemetryStatTile(
        label: 'Błysk szprych',
        value: '${(state.peakSpokeGlintIntensity * 100).round()}%',
        accent: AppColors.goldAccent,
      ),
      _TelemetryStatTile(
        label: 'Błysk tarczy',
        value:
            '${(state.brakeRotorGlint.rotorGlintIntensity * 100).round()}%',
        accent: AppColors.statusSuccess,
      ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tiles
            .map((Widget w) => SizedBox(width: 155, child: w))
            .toList(growable: false),
      );
    }
    return Row(
      children: tiles
          .map(
            (Widget w) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: w,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _LabeledSliderRow(
          label: 'Ciśnienie opony',
          valueText: '${_pressureBar.toStringAsFixed(1)} bar',
          value: _pressureBar,
          min: widget.config.minPressureBar,
          max: widget.config.maxPressureBar,
          onChanged: (double v) {
            setState(() {
              _pressureBar = v;
            });
          },
        ),
        _LabeledSliderRow(
          label: 'Prędkość obrotu',
          valueText: '${_speedKmh.toStringAsFixed(0)} km/h',
          value: _speedKmh,
          min: 0.0,
          max: 80.0,
          onChanged: (double v) {
            setState(() {
              _speedKmh = v;
            });
          },
        ),
        _LabeledSliderRow(
          label: 'Azymut słońca',
          valueText: '${_sunAzimuthDegrees.toStringAsFixed(0)}°',
          value: _sunAzimuthDegrees,
          min: 0.0,
          max: 180.0,
          onChanged: (double v) {
            setState(() {
              _sunAzimuthDegrees = v;
            });
          },
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _InteractiveFxChipButton(
              label: _isDiscWheel ? 'Koło: Dysk TT' : 'Koło: Szprychowe',
              selected: _isDiscWheel,
              onPressed: () {
                setState(() {
                  _isDiscWheel = !_isDiscWheel;
                });
              },
            ),
            _InteractiveFxChipButton(
              label: _hasDiscBrakes ? 'Tarcze: Wł.' : 'Tarcze: Wył.',
              selected: _hasDiscBrakes,
              onPressed: () {
                setState(() {
                  _hasDiscBrakes = !_hasDiscBrakes;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _TelemetryStatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryStatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledSliderRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _LabeledSliderRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 115,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 66,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractiveFxChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  const _InteractiveFxChipButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  State<_InteractiveFxChipButton> createState() =>
      _InteractiveFxChipButtonState();
}

class _InteractiveFxChipButtonState extends State<_InteractiveFxChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color backgroundColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.selected
        ? AppColors.primaryAccent.withValues(alpha: _hovered ? 0.92 : 0.78)
        : _hovered
        ? AppColors.surfaceLight
        : AppColors.background;
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
        ? AppColors.cyanAccent
        : widget.selected
        ? AppColors.goldAccent
        : _hovered
        ? AppColors.textSecondary
        : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _focused = value),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(
            _pressed ? 0.97 : 1.0,
            _pressed ? 0.97 : 1.0,
            1.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
