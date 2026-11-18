// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';

// =============================================================================
// 1. BIOMY EGZOTYCZNE 3D (RWANDA MUR DE KIGALI, ALULA, MALEZJA)
// =============================================================================

/// Egzotyczne biomy kolarskie 3D obsługiwane przez dedykowany renderer.
enum Exotic3dBiome {
  rwandaMurDeKigali(
    id: 'rwanda_mur_de_kigali',
    labelPl: 'Czerwona Ziemia — Mur de Kigali',
    shortTag: 'MUR DE KIGALI',
    regionPl: 'Rwanda • Kigali (1567 m n.p.m.)',
    descriptionPl:
        'Kultowy bruk bazaltowy na stromym podjeździe 11–18% wśród czerwonych '
        'skarp laterytowych, akacji sawannowych, bananowców i morza kibiców.',
    skyTopColor: Color(0xFF1A3A5C),
    skyHorizonColor: Color(0xFFE09F6B),
    terrainBaseColor: Color(0xFF9E3F24),
    terrainAccentColor: Color(0xFFC25734),
    roadSurfaceColor: Color(0xFF4B4745),
    roadEdgeColor: Color(0xFFB55132),
    accentHighlightColor: Color(0xFFD4AF37),
    altitudeMeters: 1567.0,
    ambientTempCelsius: 24.5,
    humidityPercent: 62.0,
    defaultWindMps: 3.4,
    rollingResistanceMultiplier: 1.48,
    surfaceGripMu: 0.66,
    canopyShadowFactor: 0.22,
    roadWidthMeters: 5.4,
    isCobblestone: true,
    baseGradientPercent: 11.2,
  ),
  alulaDesertCanyons(
    id: 'alula_desert_canyons',
    labelPl: 'Pustynne Kaniony — AlUla',
    shortTag: 'ALULA KANIONY',
    regionPl: 'Arabia Saudyjska • AlUla (720 m n.p.m.)',
    descriptionPl:
        'Monumentalne ściany kanionów z piaskowca, złote wydmy, łachy '
        'nawianego piasku na asfalcie oraz miraż termiczny i burza pyłowa.',
    skyTopColor: Color(0xFF1C436E),
    skyHorizonColor: Color(0xFFF0C684),
    terrainBaseColor: Color(0xFFC8914E),
    terrainAccentColor: Color(0xFFE0B270),
    roadSurfaceColor: Color(0xFF3A3938),
    roadEdgeColor: Color(0xFFD9A660),
    accentHighlightColor: Color(0xFFF59E0B),
    altitudeMeters: 720.0,
    ambientTempCelsius: 41.5,
    humidityPercent: 14.0,
    defaultWindMps: 10.8,
    rollingResistanceMultiplier: 1.65,
    surfaceGripMu: 0.64,
    canopyShadowFactor: 0.08,
    roadWidthMeters: 7.6,
    isCobblestone: false,
    baseGradientPercent: 2.1,
  ),
  malaysiaTropicalJungle(
    id: 'malaysia_tropical_jungle',
    labelPl: 'Tropikalna Dżungla — Malezja',
    shortTag: 'MALEZJA DŻUNGLA',
    regionPl: 'Malezja • Langkawi / Genting (480 m n.p.m.)',
    descriptionPl:
        'Gęsta równikowa dżungla palm olejowych, gigantycznych bambusów '
        'i paproci przy 95% wilgotności oraz parującym po monsunie asfalcie.',
    skyTopColor: Color(0xFF183630),
    skyHorizonColor: Color(0xFF7CA494),
    terrainBaseColor: Color(0xFF193C23),
    terrainAccentColor: Color(0xFF2B5E36),
    roadSurfaceColor: Color(0xFF282E33),
    roadEdgeColor: Color(0xFF3E6E46),
    accentHighlightColor: Color(0xFF10B981),
    altitudeMeters: 480.0,
    ambientTempCelsius: 33.5,
    humidityPercent: 95.0,
    defaultWindMps: 2.4,
    rollingResistanceMultiplier: 1.12,
    surfaceGripMu: 0.70,
    canopyShadowFactor: 0.72,
    roadWidthMeters: 6.8,
    isCobblestone: false,
    baseGradientPercent: 6.4,
  );

  final String id;
  final String labelPl;
  final String shortTag;
  final String regionPl;
  final String descriptionPl;
  final Color skyTopColor;
  final Color skyHorizonColor;
  final Color terrainBaseColor;
  final Color terrainAccentColor;
  final Color roadSurfaceColor;
  final Color roadEdgeColor;
  final Color accentHighlightColor;
  final double altitudeMeters;
  final double ambientTempCelsius;
  final double humidityPercent;
  final double defaultWindMps;
  final double rollingResistanceMultiplier;
  final double surfaceGripMu;
  final double canopyShadowFactor;
  final double roadWidthMeters;
  final bool isCobblestone;
  final double baseGradientPercent;

  const Exotic3dBiome({
    required this.id,
    required this.labelPl,
    required this.shortTag,
    required this.regionPl,
    required this.descriptionPl,
    required this.skyTopColor,
    required this.skyHorizonColor,
    required this.terrainBaseColor,
    required this.terrainAccentColor,
    required this.roadSurfaceColor,
    required this.roadEdgeColor,
    required this.accentHighlightColor,
    required this.altitudeMeters,
    required this.ambientTempCelsius,
    required this.humidityPercent,
    required this.defaultWindMps,
    required this.rollingResistanceMultiplier,
    required this.surfaceGripMu,
    required this.canopyShadowFactor,
    required this.roadWidthMeters,
    required this.isCobblestone,
    required this.baseGradientPercent,
  });
}

/// Presety ustawienia kamery 3D w egzotycznych biomach.
enum Exotic3dCameraPreset {
  pelotonChase(
    id: 'peloton_chase',
    labelPl: 'Pościg',
    heightMeters: 2.6,
    fovDegrees: 58.0,
    pitchRadians: -0.06,
  ),
  helicopterPan(
    id: 'helicopter_pan',
    labelPl: 'Helikopter',
    heightMeters: 9.2,
    fovDegrees: 52.0,
    pitchRadians: -0.18,
  ),
  lowWheelAngle(
    id: 'low_wheel',
    labelPl: 'Koło 3D',
    heightMeters: 1.25,
    fovDegrees: 66.0,
    pitchRadians: -0.02,
  ),
  cockpitFpp(
    id: 'cockpit_fpp',
    labelPl: 'Kokpit',
    heightMeters: 1.55,
    fovDegrees: 72.0,
    pitchRadians: -0.04,
  );

  final String id;
  final String labelPl;
  final double heightMeters;
  final double fovDegrees;
  final double pitchRadians;

  const Exotic3dCameraPreset({
    required this.id,
    required this.labelPl,
    required this.heightMeters,
    required this.fovDegrees,
    required this.pitchRadians,
  });
}

// =============================================================================
// 2. KONFIGURACJA I STRUKTURY DANYCH SCENERII 3D
// =============================================================================

/// Konfiguracja renderera egzotycznych biomów 3D.
class ExoticBiomes3dConfig {
  final Exotic3dBiome biome;
  final Exotic3dCameraPreset cameraPreset;
  final double forwardVisibilityMeters;
  final double backwardVisibilityMeters;
  final double speedMetersPerSecond;
  final double weatherIntensity;
  final bool showPelotonMarkers;
  final bool showAtmosphericParticles;
  final bool enableSurfaceVibration;
  final int stageSeed;

  const ExoticBiomes3dConfig({
    this.biome = Exotic3dBiome.rwandaMurDeKigali,
    this.cameraPreset = Exotic3dCameraPreset.pelotonChase,
    this.forwardVisibilityMeters = 360.0,
    this.backwardVisibilityMeters = 10.0,
    this.speedMetersPerSecond = 11.5,
    this.weatherIntensity = 0.85,
    this.showPelotonMarkers = true,
    this.showAtmosphericParticles = true,
    this.enableSurfaceVibration = true,
    this.stageSeed = 615,
  });

  ExoticBiomes3dConfig copyWith({
    Exotic3dBiome? biome,
    Exotic3dCameraPreset? cameraPreset,
    double? forwardVisibilityMeters,
    double? backwardVisibilityMeters,
    double? speedMetersPerSecond,
    double? weatherIntensity,
    bool? showPelotonMarkers,
    bool? showAtmosphericParticles,
    bool? enableSurfaceVibration,
    int? stageSeed,
  }) {
    return ExoticBiomes3dConfig(
      biome: biome ?? this.biome,
      cameraPreset: cameraPreset ?? this.cameraPreset,
      forwardVisibilityMeters:
          forwardVisibilityMeters ?? this.forwardVisibilityMeters,
      backwardVisibilityMeters:
          backwardVisibilityMeters ?? this.backwardVisibilityMeters,
      speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
      weatherIntensity: weatherIntensity ?? this.weatherIntensity,
      showPelotonMarkers: showPelotonMarkers ?? this.showPelotonMarkers,
      showAtmosphericParticles:
          showAtmosphericParticles ?? this.showAtmosphericParticles,
      enableSurfaceVibration:
          enableSurfaceVibration ?? this.enableSurfaceVibration,
      stageSeed: stageSeed ?? this.stageSeed,
    );
  }
}

/// Rodzaj obiektu terenowego lub architektonicznego 3D dla biomów egzotycznych.
enum Exotic3dPropKind {
  // Rwanda (Mur de Kigali)
  lateriteEmbankment,
  savannaAcaciaTree,
  bananaGrove,
  kigaliSpectatorCrowd,
  rwandaFlagPole,
  rwandaCobbleBannerArch,

  // AlUla (Pustynne kaniony)
  sandstoneCanyonWall,
  alulaMonolithArch,
  desertSandDune,
  datePalmOasis,
  sandDriftPatch,

  // Malezja (Tropikalna dżungla)
  tropicalOilPalm,
  giantBambooCluster,
  jungleFernUnderstory,
  monsoonMistPillar,
  langkawiKmMarker,
}

/// Obiekt 3D umieszczony względem osi trasy w przestrzeni świata.
class ExoticSceneryProp3D {
  final String id;
  final Exotic3dPropKind kind;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double elevationOffsetMeters;
  final double widthMeters;
  final double heightMeters;
  final double depthMeters;
  final Color primaryColor;
  final Color secondaryColor;
  final double swayPhaseRad;
  final int variantSeed;

  const ExoticSceneryProp3D({
    required this.id,
    required this.kind,
    required this.distanceAlongCourseMeters,
    required this.lateralOffsetMeters,
    this.elevationOffsetMeters = 0.0,
    required this.widthMeters,
    required this.heightMeters,
    this.depthMeters = 1.0,
    required this.primaryColor,
    required this.secondaryColor,
    this.swayPhaseRad = 0.0,
    this.variantSeed = 0,
  });
}

/// Próbka segmentu nawierzchni drogi w przestrzeni 3D.
class ExoticRoadSlice3D {
  final double distanceMeters;
  final double centerX;
  final double centerY;
  final double halfWidthMeters;
  final double slopeRadians;
  final double sandDriftCoverage;
  final double wetnessFactor;
  final double lateriteDustEdgeFactor;
  final int cobbleRowSeed;

  const ExoticRoadSlice3D({
    required this.distanceMeters,
    required this.centerX,
    required this.centerY,
    required this.halfWidthMeters,
    required this.slopeRadians,
    this.sandDriftCoverage = 0.0,
    this.wetnessFactor = 0.0,
    this.lateriteDustEdgeFactor = 0.0,
    this.cobbleRowSeed = 0,
  });
}

/// Cząsteczka atmosferyczna 3D (pył laterytowy, piasek pustynny, deszcz/mgła).
class ExoticAtmosphericParticle3D {
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double heightMeters;
  final double radiusPx;
  final double streakLengthPx;
  final double opacity;
  final Color color;

  const ExoticAtmosphericParticle3D({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.heightMeters,
    required this.radiusPx,
    this.streakLengthPx = 0.0,
    required this.opacity,
    required this.color,
  });
}

/// Uproszczony marker kolarza 3D na drodze w widoku egzotycznego biomu.
class ExoticPelotonRiderMarker3D {
  final String id;
  final String teamCode;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final Color jerseyColor;
  final Color helmetColor;
  final double cadencePhaseRad;
  final bool isOutOfSaddle;

  const ExoticPelotonRiderMarker3D({
    required this.id,
    required this.teamCode,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.jerseyColor,
    required this.helmetColor,
    required this.cadencePhaseRad,
    this.isOutOfSaddle = false,
  });
}

/// Zbudowany stan pojedynczej klatki 3D egzotycznego biomu.
class ExoticBiomes3dFrameState {
  final Exotic3dBiome biome;
  final Exotic3dCameraPreset cameraPreset;
  final double cameraDistanceMeters;
  final double cameraHeightMeters;
  final double cameraYawRadians;
  final double cameraPitchRadians;
  final double cameraFovDegrees;
  final double cameraVibrationOffsetPx;
  final double heatShimmerAmplitudePx;
  final double effectiveWindMps;
  final double effectiveCrrMultiplier;
  final double visibilityRangeMeters;
  final double elapsedSeconds;
  final List<ExoticRoadSlice3D> roadSlices;
  final List<ExoticSceneryProp3D> visibleProps;
  final List<ExoticAtmosphericParticle3D> particles;
  final List<ExoticPelotonRiderMarker3D> pelotonMarkers;

  const ExoticBiomes3dFrameState({
    required this.biome,
    required this.cameraPreset,
    required this.cameraDistanceMeters,
    required this.cameraHeightMeters,
    required this.cameraYawRadians,
    required this.cameraPitchRadians,
    required this.cameraFovDegrees,
    required this.cameraVibrationOffsetPx,
    required this.heatShimmerAmplitudePx,
    required this.effectiveWindMps,
    required this.effectiveCrrMultiplier,
    required this.visibilityRangeMeters,
    required this.elapsedSeconds,
    required this.roadSlices,
    required this.visibleProps,
    required this.particles,
    required this.pelotonMarkers,
  });
}

// =============================================================================
// 3. SILNIK GEOMETRII I RZUTOWANIA 3D
// =============================================================================

/// Silnik generujący geometrię 3D, rzutowanie perspektywiczne oraz cząsteczki
/// dla Rwandy (*Mur de Kigali*), kanionów AlUla i dżungli Malezji.
class ExoticBiomesSavannaDesertJungleEngine {
  const ExoticBiomesSavannaDesertJungleEngine();

  /// Zwraca pozycję osi X trasy [m] dla danego dystansu [m].
  double courseCenterX(Exotic3dBiome biome, double distanceMeters) {
    switch (biome) {
      case Exotic3dBiome.rwandaMurDeKigali:
        return math.sin(distanceMeters * 0.017) * 9.5 +
            math.cos(distanceMeters * 0.0065) * 5.0;
      case Exotic3dBiome.alulaDesertCanyons:
        return math.sin(distanceMeters * 0.0095) * 14.0 +
            math.sin(distanceMeters * 0.0032) * 8.0;
      case Exotic3dBiome.malaysiaTropicalJungle:
        return math.sin(distanceMeters * 0.021) * 11.5 +
            math.cos(distanceMeters * 0.011) * 6.5;
    }
  }

  /// Zwraca elewację osi trasy [m] dla danego dystansu [m].
  double courseCenterY(Exotic3dBiome biome, double distanceMeters) {
    switch (biome) {
      case Exotic3dBiome.rwandaMurDeKigali:
        // Strome rampy 11–18% na Mur de Kigali
        return distanceMeters * 0.112 +
            math.sin(distanceMeters * 0.024) * 1.4;
      case Exotic3dBiome.alulaDesertCanyons:
        return distanceMeters * 0.018 +
            math.sin(distanceMeters * 0.012) * 1.1;
      case Exotic3dBiome.malaysiaTropicalJungle:
        return distanceMeters * 0.058 +
            math.sin(distanceMeters * 0.019) * 1.8;
    }
  }

  /// Zwraca nachylenie podłużne drogi w radianach dla danego dystansu.
  double courseSlopeRadians(Exotic3dBiome biome, double distanceMeters) {
    const double delta = 2.0;
    final double dy = courseCenterY(biome, distanceMeters + delta) -
        courseCenterY(biome, distanceMeters - delta);
    return math.atan2(dy, delta * 2.0);
  }

  /// Rzutuje punkt świata 3D względem kamery na współrzędne ekranu 2D.
  /// Zwraca `null`, jeśli punkt znajduje się za kamerą.
  Offset? projectWorldPoint({
    required Vector3 worldPoint,
    required Vector3 cameraPos,
    required double cameraYawRadians,
    required double cameraPitchRadians,
    required double fovDegrees,
    required Size viewportSize,
  }) {
    final double dx = worldPoint.x - cameraPos.x;
    final double dy = worldPoint.y - cameraPos.y;
    final double dz = worldPoint.z - cameraPos.z;

    final double cosYaw = math.cos(-cameraYawRadians);
    final double sinYaw = math.sin(-cameraYawRadians);
    final double rx = dx * cosYaw - dz * sinYaw;
    final double rzYaw = dx * sinYaw + dz * cosYaw;

    final double cosPitch = math.cos(-cameraPitchRadians);
    final double sinPitch = math.sin(-cameraPitchRadians);
    final double ry = dy * cosPitch - rzYaw * sinPitch;
    final double rz = dy * sinPitch + rzYaw * cosPitch;

    if (rz <= 0.6) {
      return null;
    }

    final double fovRad = fovDegrees * math.pi / 180.0;
    final double focalLength =
        (viewportSize.height * 0.5) / math.tan(fovRad * 0.5);

    final double screenX = (viewportSize.width * 0.5) + (rx / rz) * focalLength;
    final double screenY =
        (viewportSize.height * 0.52) - (ry / rz) * focalLength;
    return Offset(screenX, screenY);
  }

  /// Oblicza rozmiar rzutowany w pikselach dla szerokości/wysokości w metrach.
  double projectMetersToPixels({
    required double meters,
    required double depthMeters,
    required double fovDegrees,
    required double viewportHeight,
  }) {
    if (depthMeters <= 0.6) return 0.0;
    final double fovRad = fovDegrees * math.pi / 180.0;
    final double focalLength =
        (viewportHeight * 0.5) / math.tan(fovRad * 0.5);
    return (meters / depthMeters) * focalLength;
  }

  /// Buduje kompletną klatkę scenerii 3D dla wybranego biomu i dystansu kamery.
  ExoticBiomes3dFrameState buildFrame({
    required ExoticBiomes3dConfig config,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    final Exotic3dBiome biome = config.biome;
    final double weather = config.weatherIntensity.clamp(0.0, 1.5);

    final double camX = courseCenterX(biome, cameraDistanceMeters);
    final double camY = courseCenterY(biome, cameraDistanceMeters);
    final double lookAheadX =
        courseCenterX(biome, cameraDistanceMeters + 26.0);
    final double lookAheadY =
        courseCenterY(biome, cameraDistanceMeters + 26.0);

    final double yaw = math.atan2(lookAheadX - camX, 26.0);
    final double slopePitch = math.atan2(lookAheadY - camY, 26.0);
    final double cameraPitch =
        config.cameraPreset.pitchRadians + slopePitch * 0.62;

    // Drgania kamery na bruku Mur de Kigali lub wybojach piaszczystych AlUla
    double vibrationPx = 0.0;
    if (config.enableSurfaceVibration) {
      if (biome == Exotic3dBiome.rwandaMurDeKigali) {
        vibrationPx = math.sin(elapsedSeconds * 56.0) * 1.65 +
            math.cos(elapsedSeconds * 92.0) * 0.85;
      } else if (biome == Exotic3dBiome.alulaDesertCanyons) {
        vibrationPx = math.sin(elapsedSeconds * 24.0) * 0.45 * weather;
      } else {
        vibrationPx = math.sin(elapsedSeconds * 18.0) * 0.25;
      }
    }

    // Drganie powietrza od upału (miraż termiczny)
    final double shimmerPx = biome == Exotic3dBiome.alulaDesertCanyons
        ? 1.2 + weather * 1.8
        : (biome == Exotic3dBiome.malaysiaTropicalJungle ? 0.6 : 0.4);

    // Efektywne parametry fizyczno-klimatyczne
    final double effectiveWind = biome.defaultWindMps * (0.7 + weather * 0.55);
    final double effectiveCrr = switch (biome) {
      Exotic3dBiome.rwandaMurDeKigali =>
        biome.rollingResistanceMultiplier + weather * 0.08,
      Exotic3dBiome.alulaDesertCanyons =>
        biome.rollingResistanceMultiplier + weather * 0.52,
      Exotic3dBiome.malaysiaTropicalJungle =>
        biome.rollingResistanceMultiplier + weather * 0.14,
    };

    final double visibilityRange = switch (biome) {
      Exotic3dBiome.rwandaMurDeKigali => 360.0 - weather * 55.0,
      Exotic3dBiome.alulaDesertCanyons =>
        (360.0 - weather * 155.0).clamp(120.0, 360.0),
      Exotic3dBiome.malaysiaTropicalJungle =>
        (340.0 - weather * 125.0).clamp(135.0, 340.0),
    };

    final List<ExoticRoadSlice3D> roadSlices = _buildRoadSlices(
      config: config,
      cameraDistanceMeters: cameraDistanceMeters,
    );

    final List<ExoticSceneryProp3D> props = _buildVisibleProps(
      config: config,
      cameraDistanceMeters: cameraDistanceMeters,
      elapsedSeconds: elapsedSeconds,
    );

    final List<ExoticAtmosphericParticle3D> particles =
        config.showAtmosphericParticles
            ? _buildParticles(
                config: config,
                cameraDistanceMeters: cameraDistanceMeters,
                elapsedSeconds: elapsedSeconds,
              )
            : const <ExoticAtmosphericParticle3D>[];

    final List<ExoticPelotonRiderMarker3D> pelotonMarkers =
        config.showPelotonMarkers
            ? _buildPelotonMarkers(
                config: config,
                cameraDistanceMeters: cameraDistanceMeters,
                elapsedSeconds: elapsedSeconds,
              )
            : const <ExoticPelotonRiderMarker3D>[];

    return ExoticBiomes3dFrameState(
      biome: biome,
      cameraPreset: config.cameraPreset,
      cameraDistanceMeters: cameraDistanceMeters,
      cameraHeightMeters: config.cameraPreset.heightMeters,
      cameraYawRadians: yaw,
      cameraPitchRadians: cameraPitch,
      cameraFovDegrees: config.cameraPreset.fovDegrees,
      cameraVibrationOffsetPx: vibrationPx,
      heatShimmerAmplitudePx: shimmerPx,
      effectiveWindMps: effectiveWind,
      effectiveCrrMultiplier: effectiveCrr,
      visibilityRangeMeters: visibilityRange,
      elapsedSeconds: elapsedSeconds,
      roadSlices: roadSlices,
      visibleProps: props,
      particles: particles,
      pelotonMarkers: pelotonMarkers,
    );
  }

  List<ExoticRoadSlice3D> _buildRoadSlices({
    required ExoticBiomes3dConfig config,
    required double cameraDistanceMeters,
  }) {
    final Exotic3dBiome biome = config.biome;
    final double halfW = biome.roadWidthMeters * 0.5;
    const double stepMeters = 5.5;
    final double startDist =
        (cameraDistanceMeters - config.backwardVisibilityMeters).floorToDouble();
    final double endDist = cameraDistanceMeters + config.forwardVisibilityMeters;

    final List<ExoticRoadSlice3D> slices = <ExoticRoadSlice3D>[];
    for (double d = startDist; d <= endDist; d += stepMeters) {
      final int rowSeed = (d / stepMeters).round();
      final double sandCoverage = biome == Exotic3dBiome.alulaDesertCanyons
          ? (0.25 + 0.55 * math.sin(d * 0.045).abs()) *
              config.weatherIntensity.clamp(0.2, 1.5)
          : 0.0;
      final double wetness = biome == Exotic3dBiome.malaysiaTropicalJungle
          ? (0.45 + 0.45 * math.cos(d * 0.032).abs()) *
              config.weatherIntensity.clamp(0.3, 1.5)
          : 0.0;
      final double lateriteDust = biome == Exotic3dBiome.rwandaMurDeKigali
          ? (0.55 + 0.35 * math.sin(d * 0.06).abs())
          : 0.0;

      slices.add(
        ExoticRoadSlice3D(
          distanceMeters: d,
          centerX: courseCenterX(biome, d),
          centerY: courseCenterY(biome, d),
          halfWidthMeters: halfW,
          slopeRadians: courseSlopeRadians(biome, d),
          sandDriftCoverage: sandCoverage.clamp(0.0, 1.0),
          wetnessFactor: wetness.clamp(0.0, 1.0),
          lateriteDustEdgeFactor: lateriteDust.clamp(0.0, 1.0),
          cobbleRowSeed: rowSeed,
        ),
      );
    }
    return slices;
  }

  List<ExoticSceneryProp3D> _buildVisibleProps({
    required ExoticBiomes3dConfig config,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    final Exotic3dBiome biome = config.biome;
    final double minDist = cameraDistanceMeters + 2.0;
    final double maxDist = cameraDistanceMeters + config.forwardVisibilityMeters;
    final List<ExoticSceneryProp3D> props = <ExoticSceneryProp3D>[];

    switch (biome) {
      case Exotic3dBiome.rwandaMurDeKigali:
        _populateRwandaProps(props, minDist, maxDist, elapsedSeconds, config);
      case Exotic3dBiome.alulaDesertCanyons:
        _populateAlulaProps(props, minDist, maxDist, elapsedSeconds, config);
      case Exotic3dBiome.malaysiaTropicalJungle:
        _populateMalaysiaProps(props, minDist, maxDist, elapsedSeconds, config);
    }

    // Sortuj od najdalszych do najbliższych (painter's algorithm)
    props.sort(
      (ExoticSceneryProp3D a, ExoticSceneryProp3D b) =>
          b.distanceAlongCourseMeters.compareTo(a.distanceAlongCourseMeters),
    );
    return props;
  }

  void _populateRwandaProps(
    List<ExoticSceneryProp3D> out,
    double minDist,
    double maxDist,
    double elapsedSeconds,
    ExoticBiomes3dConfig config,
  ) {
    final double firstStep = (minDist / 14.0).floorToDouble() * 14.0;
    for (double d = firstStep; d <= maxDist; d += 14.0) {
      if (d < minDist) continue;
      final int idx = (d / 14.0).round();

      // Czerwone skarpy laterytowe po obu stronach drogi
      out.add(
        ExoticSceneryProp3D(
          id: 'rw_bank_l_$idx',
          kind: Exotic3dPropKind.lateriteEmbankment,
          distanceAlongCourseMeters: d,
          lateralOffsetMeters: -5.2 - (idx % 3) * 0.8,
          widthMeters: 6.5,
          heightMeters: 3.4 + (idx % 4) * 0.7,
          depthMeters: 10.0,
          primaryColor: const Color(0xFF9E3F24),
          secondaryColor: const Color(0xFFC95A38),
          variantSeed: idx,
        ),
      );
      out.add(
        ExoticSceneryProp3D(
          id: 'rw_bank_r_$idx',
          kind: Exotic3dPropKind.lateriteEmbankment,
          distanceAlongCourseMeters: d + 4.0,
          lateralOffsetMeters: 5.4 + ((idx + 1) % 3) * 0.7,
          widthMeters: 6.2,
          heightMeters: 3.1 + ((idx + 2) % 4) * 0.65,
          depthMeters: 10.0,
          primaryColor: const Color(0xFF8C351E),
          secondaryColor: const Color(0xFFB54E30),
          variantSeed: idx + 11,
        ),
      );

      // Kibice na skarpach i wzdłuż bruku Mur de Kigali
      out.add(
        ExoticSceneryProp3D(
          id: 'rw_crowd_l_$idx',
          kind: Exotic3dPropKind.kigaliSpectatorCrowd,
          distanceAlongCourseMeters: d + 1.5,
          lateralOffsetMeters: -3.6,
          widthMeters: 2.2,
          heightMeters: 1.85,
          primaryColor: const Color(0xFF00A1DE),
          secondaryColor: const Color(0xFFFAD201),
          swayPhaseRad: elapsedSeconds * 4.5 + idx * 0.9,
          variantSeed: idx,
        ),
      );
      if (idx % 2 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'rw_crowd_r_$idx',
            kind: Exotic3dPropKind.kigaliSpectatorCrowd,
            distanceAlongCourseMeters: d + 6.5,
            lateralOffsetMeters: 3.7,
            widthMeters: 2.2,
            heightMeters: 1.85,
            primaryColor: const Color(0xFF20603D),
            secondaryColor: const Color(0xFFFAD201),
            swayPhaseRad: elapsedSeconds * 4.8 + idx * 1.3,
            variantSeed: idx + 5,
          ),
        );
      }

      // Akacje sawannowe i bananowce
      if (idx % 3 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'rw_acacia_$idx',
            kind: Exotic3dPropKind.savannaAcaciaTree,
            distanceAlongCourseMeters: d + 2.0,
            lateralOffsetMeters: (idx % 2 == 0 ? -1.0 : 1.0) * 11.5,
            widthMeters: 9.2,
            heightMeters: 7.8,
            primaryColor: const Color(0xFF4A3628),
            secondaryColor: const Color(0xFF4F6B2D),
            swayPhaseRad: elapsedSeconds * 1.4 + idx,
            variantSeed: idx,
          ),
        );
      } else if (idx % 3 == 1) {
        out.add(
          ExoticSceneryProp3D(
            id: 'rw_banana_$idx',
            kind: Exotic3dPropKind.bananaGrove,
            distanceAlongCourseMeters: d + 3.0,
            lateralOffsetMeters: (idx % 2 == 0 ? 1.0 : -1.0) * 8.6,
            widthMeters: 4.5,
            heightMeters: 4.4,
            primaryColor: const Color(0xFF3E7028),
            secondaryColor: const Color(0xFF6B9E38),
            swayPhaseRad: elapsedSeconds * 2.0 + idx,
            variantSeed: idx,
          ),
        );
      }

      // Flagi Rwandy i brama Tour du Rwanda
      if (idx % 5 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'rw_flag_$idx',
            kind: Exotic3dPropKind.rwandaFlagPole,
            distanceAlongCourseMeters: d + 5.0,
            lateralOffsetMeters: -4.1,
            widthMeters: 1.4,
            heightMeters: 4.2,
            primaryColor: const Color(0xFF00A1DE),
            secondaryColor: const Color(0xFFFAD201),
            swayPhaseRad: elapsedSeconds * 5.2 + idx,
            variantSeed: idx,
          ),
        );
      }
      if (idx % 12 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'rw_arch_$idx',
            kind: Exotic3dPropKind.rwandaCobbleBannerArch,
            distanceAlongCourseMeters: d + 1.0,
            lateralOffsetMeters: 0.0,
            widthMeters: config.biome.roadWidthMeters + 1.2,
            heightMeters: 5.4,
            primaryColor: AppColors.primaryAccent,
            secondaryColor: AppColors.goldAccent,
            variantSeed: idx,
          ),
        );
      }
    }
  }

  void _populateAlulaProps(
    List<ExoticSceneryProp3D> out,
    double minDist,
    double maxDist,
    double elapsedSeconds,
    ExoticBiomes3dConfig config,
  ) {
    final double firstStep = (minDist / 20.0).floorToDouble() * 20.0;
    for (double d = firstStep; d <= maxDist; d += 20.0) {
      if (d < minDist) continue;
      final int idx = (d / 20.0).round();

      // Monumentalne ściany piaskowcowych kanionów AlUla
      out.add(
        ExoticSceneryProp3D(
          id: 'al_canyon_l_$idx',
          kind: Exotic3dPropKind.sandstoneCanyonWall,
          distanceAlongCourseMeters: d,
          lateralOffsetMeters: -18.5 - (idx % 3) * 3.5,
          widthMeters: 16.0,
          heightMeters: 26.0 + (idx % 4) * 6.5,
          depthMeters: 18.0,
          primaryColor: const Color(0xFFB56C3B),
          secondaryColor: const Color(0xFFD99559),
          variantSeed: idx,
        ),
      );
      out.add(
        ExoticSceneryProp3D(
          id: 'al_canyon_r_$idx',
          kind: Exotic3dPropKind.sandstoneCanyonWall,
          distanceAlongCourseMeters: d + 8.0,
          lateralOffsetMeters: 19.0 + ((idx + 1) % 3) * 3.5,
          widthMeters: 16.0,
          heightMeters: 24.0 + ((idx + 2) % 4) * 7.0,
          depthMeters: 18.0,
          primaryColor: const Color(0xFFA66033),
          secondaryColor: const Color(0xFFCF894E),
          variantSeed: idx + 7,
        ),
      );

      // Złote wydmy piaskowe bliżej pobocza
      out.add(
        ExoticSceneryProp3D(
          id: 'al_dune_$idx',
          kind: Exotic3dPropKind.desertSandDune,
          distanceAlongCourseMeters: d + 4.0,
          lateralOffsetMeters: (idx % 2 == 0 ? -1.0 : 1.0) * 9.5,
          widthMeters: 11.0,
          heightMeters: 3.8 + (idx % 3) * 1.1,
          primaryColor: const Color(0xFFD6A058),
          secondaryColor: const Color(0xFFEBC282),
          variantSeed: idx,
        ),
      );

      // Łachy nawianego piasku na asfalcie
      if (idx % 2 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'al_sandpatch_$idx',
            kind: Exotic3dPropKind.sandDriftPatch,
            distanceAlongCourseMeters: d + 6.0,
            lateralOffsetMeters: (idx % 4 == 0 ? -1.6 : 1.6),
            widthMeters: 3.4,
            heightMeters: 0.14,
            primaryColor: const Color(0xFFE3B773),
            secondaryColor: const Color(0xFFC8914E),
            variantSeed: idx,
          ),
        );
      }

      // Palmy daktylowe w oazie przy kanionie
      if (idx % 4 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'al_palm_$idx',
            kind: Exotic3dPropKind.datePalmOasis,
            distanceAlongCourseMeters: d + 2.0,
            lateralOffsetMeters: (idx % 8 == 0 ? -7.2 : 7.4),
            widthMeters: 4.8,
            heightMeters: 9.4,
            primaryColor: const Color(0xFF6B533B),
            secondaryColor: const Color(0xFF4D7B36),
            swayPhaseRad: elapsedSeconds * 2.2 + idx,
            variantSeed: idx,
          ),
        );
      }

      // Słynny skalny łuk / monolit AlUla
      if (idx % 10 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'al_monolith_$idx',
            kind: Exotic3dPropKind.alulaMonolithArch,
            distanceAlongCourseMeters: d + 10.0,
            lateralOffsetMeters: idx % 20 == 0 ? -13.0 : 13.0,
            widthMeters: 14.0,
            heightMeters: 22.0,
            primaryColor: const Color(0xFF9C542B),
            secondaryColor: const Color(0xFFD68D54),
            variantSeed: idx,
          ),
        );
      }
    }
  }

  void _populateMalaysiaProps(
    List<ExoticSceneryProp3D> out,
    double minDist,
    double maxDist,
    double elapsedSeconds,
    ExoticBiomes3dConfig config,
  ) {
    final double firstStep = (minDist / 12.0).floorToDouble() * 12.0;
    for (double d = firstStep; d <= maxDist; d += 12.0) {
      if (d < minDist) continue;
      final int idx = (d / 12.0).round();

      // Wysokie palmy olejowe i kokosowe po obu stronach drogi
      out.add(
        ExoticSceneryProp3D(
          id: 'my_palm_l_$idx',
          kind: Exotic3dPropKind.tropicalOilPalm,
          distanceAlongCourseMeters: d,
          lateralOffsetMeters: -5.6 - (idx % 3) * 1.1,
          widthMeters: 7.4,
          heightMeters: 12.5 + (idx % 3) * 2.2,
          primaryColor: const Color(0xFF42372A),
          secondaryColor: const Color(0xFF286933),
          swayPhaseRad: elapsedSeconds * 1.8 + idx * 0.7,
          variantSeed: idx,
        ),
      );
      out.add(
        ExoticSceneryProp3D(
          id: 'my_palm_r_$idx',
          kind: Exotic3dPropKind.tropicalOilPalm,
          distanceAlongCourseMeters: d + 4.5,
          lateralOffsetMeters: 5.8 + ((idx + 1) % 3) * 1.1,
          widthMeters: 7.2,
          heightMeters: 11.8 + ((idx + 2) % 3) * 2.1,
          primaryColor: const Color(0xFF3B3025),
          secondaryColor: const Color(0xFF235C2D),
          swayPhaseRad: elapsedSeconds * 1.9 + idx * 1.1,
          variantSeed: idx + 9,
        ),
      );

      // Gęste kępy gigantycznego bambusa
      if (idx % 2 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'my_bamboo_$idx',
            kind: Exotic3dPropKind.giantBambooCluster,
            distanceAlongCourseMeters: d + 2.5,
            lateralOffsetMeters: (idx % 4 == 0 ? -4.3 : 4.4),
            widthMeters: 3.4,
            heightMeters: 9.2,
            primaryColor: const Color(0xFF5D8A38),
            secondaryColor: const Color(0xFF83B352),
            swayPhaseRad: elapsedSeconds * 2.3 + idx,
            variantSeed: idx,
          ),
        );
      }

      // Tropikalne paprocie drzewiaste w poszyciu
      out.add(
        ExoticSceneryProp3D(
          id: 'my_fern_l_$idx',
          kind: Exotic3dPropKind.jungleFernUnderstory,
          distanceAlongCourseMeters: d + 1.5,
          lateralOffsetMeters: -3.9,
          widthMeters: 2.8,
          heightMeters: 2.3,
          primaryColor: const Color(0xFF1F5428),
          secondaryColor: const Color(0xFF428A48),
          swayPhaseRad: elapsedSeconds * 2.5 + idx,
          variantSeed: idx,
        ),
      );

      // Słupy tropikalnej mgły między koronami drzew
      if (idx % 4 == 0 && config.weatherIntensity > 0.25) {
        out.add(
          ExoticSceneryProp3D(
            id: 'my_mist_$idx',
            kind: Exotic3dPropKind.monsoonMistPillar,
            distanceAlongCourseMeters: d + 6.0,
            lateralOffsetMeters: (idx % 8 == 0 ? -7.5 : 7.5),
            widthMeters: 11.0,
            heightMeters: 8.5,
            primaryColor: const Color(0xFFDCEBE3),
            secondaryColor: const Color(0xFF9BC2B0),
            swayPhaseRad: elapsedSeconds * 0.7 + idx,
            variantSeed: idx,
          ),
        );
      }

      // Tabliczki dystansowe Tour de Langkawi
      if (idx % 9 == 0) {
        out.add(
          ExoticSceneryProp3D(
            id: 'my_km_$idx',
            kind: Exotic3dPropKind.langkawiKmMarker,
            distanceAlongCourseMeters: d + 3.0,
            lateralOffsetMeters: -3.6,
            widthMeters: 0.9,
            heightMeters: 1.9,
            primaryColor: AppColors.goldAccent,
            secondaryColor: AppColors.surface,
            variantSeed: idx,
          ),
        );
      }
    }
  }

  List<ExoticAtmosphericParticle3D> _buildParticles({
    required ExoticBiomes3dConfig config,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    final Exotic3dBiome biome = config.biome;
    final double weather = config.weatherIntensity.clamp(0.1, 1.5);
    final int count = (36 * weather).round().clamp(12, 64);
    final List<ExoticAtmosphericParticle3D> particles =
        <ExoticAtmosphericParticle3D>[];

    for (int i = 0; i < count; i++) {
      final double seed = (i * 37.0 + config.stageSeed) % 100.0;
      final double cycle =
          (seed * 2.4 + elapsedSeconds * (biome == Exotic3dBiome.alulaDesertCanyons ? 22.0 : 12.0)) %
              160.0;
      final double dist = cameraDistanceMeters + 6.0 + cycle;

      switch (biome) {
        case Exotic3dBiome.rwandaMurDeKigali:
          // Czerwony pył laterytowy wzbijany przez koła i kibiców
          particles.add(
            ExoticAtmosphericParticle3D(
              distanceMeters: dist,
              lateralOffsetMeters:
                  math.sin(i * 1.7 + elapsedSeconds * 1.3) * 5.2,
              heightMeters: 0.35 + ((i * 0.29) % 2.6),
              radiusPx: 1.8 + (i % 3) * 1.1,
              opacity: (0.28 + (i % 4) * 0.1) * weather.clamp(0.4, 1.0),
              color: const Color(0xFFD66A43),
            ),
          );
        case Exotic3dBiome.alulaDesertCanyons:
          // Pędzące ziarna pustynnego piasku i zamieć pyłowa
          particles.add(
            ExoticAtmosphericParticle3D(
              distanceMeters: dist,
              lateralOffsetMeters:
                  -8.0 + ((i * 2.9 + elapsedSeconds * 14.0) % 16.0),
              heightMeters: 0.2 + ((i * 0.42) % 4.5),
              radiusPx: 2.0 + (i % 3) * 1.2,
              streakLengthPx: 8.0 + weather * 10.0,
              opacity: (0.35 + (i % 4) * 0.12) * weather.clamp(0.4, 1.0),
              color: const Color(0xFFEBC383),
            ),
          );
        case Exotic3dBiome.malaysiaTropicalJungle:
          // Tropikalne krople deszczu monsunowego i zawiesina pary
          final double fallOffset = (elapsedSeconds * 16.0 + i * 0.8) % 6.0;
          particles.add(
            ExoticAtmosphericParticle3D(
              distanceMeters: dist,
              lateralOffsetMeters: math.cos(i * 2.1) * 6.5,
              heightMeters: (6.2 - fallOffset).clamp(0.1, 6.2),
              radiusPx: 1.3,
              streakLengthPx: 11.0 + weather * 9.0,
              opacity: (0.32 + (i % 3) * 0.14) * weather.clamp(0.4, 1.0),
              color: const Color(0xFFD4EFE2),
            ),
          );
      }
    }
    return particles;
  }

  List<ExoticPelotonRiderMarker3D> _buildPelotonMarkers({
    required ExoticBiomes3dConfig config,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    final List<Color> teamColors = <Color>[
      AppColors.goldAccent,
      AppColors.primaryAccent,
      AppColors.accentBlue,
      AppColors.statusSuccess,
      AppColors.amberWarning,
      const Color(0xFFE5E7EB),
      const Color(0xFF00A1DE),
      AppColors.crimsonAlert,
      const Color(0xFF8B5CF6),
    ];
    final List<String> codes = <String>[
      'RWA',
      'UAE',
      'TJV',
      'IGD',
      'SOQ',
      'JAY',
      'TSG',
      'ADC',
      'Q36',
    ];

    final bool steepClimb = config.biome == Exotic3dBiome.rwandaMurDeKigali;
    final List<ExoticPelotonRiderMarker3D> markers =
        <ExoticPelotonRiderMarker3D>[];

    for (int i = 0; i < 9; i++) {
      final double relDist = 14.0 + i * 5.2;
      final double latWave = math.sin(elapsedSeconds * 0.9 + i * 1.4) * 0.35;
      final double lateral = ((i % 3) - 1) * 1.15 + latWave;
      markers.add(
        ExoticPelotonRiderMarker3D(
          id: 'exotic_rider_$i',
          teamCode: codes[i],
          distanceMeters: cameraDistanceMeters + relDist,
          lateralOffsetMeters: lateral,
          jerseyColor: teamColors[i],
          helmetColor: i == 0 ? AppColors.goldAccent : const Color(0xFFF3F4F6),
          cadencePhaseRad: elapsedSeconds * (steepClimb ? 7.2 : 10.5) + i * 0.8,
          isOutOfSaddle: steepClimb && i < 4,
        ),
      );
    }

    markers.sort(
      (ExoticPelotonRiderMarker3D a, ExoticPelotonRiderMarker3D b) =>
          b.distanceMeters.compareTo(a.distanceMeters),
    );
    return markers;
  }
}

// =============================================================================
// 4. RENDERER CANVAS 3D (CUSTOM PAINTER)
// =============================================================================

/// CustomPainter rysujący kompletną scenę 3D dla biomów egzotycznych:
/// Rwandy (*Mur de Kigali*), kanionów AlUla i tropikalnej dżungli Malezji.
class ExoticBiomesSavannaDesertJunglePainter extends CustomPainter {
  final ExoticBiomes3dFrameState frame;
  final ExoticBiomes3dConfig config;
  final ExoticBiomesSavannaDesertJungleEngine engine;

  const ExoticBiomesSavannaDesertJunglePainter({
    required this.frame,
    required this.config,
    this.engine = const ExoticBiomesSavannaDesertJungleEngine(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 4 || size.height <= 4) return;

    canvas.save();
    if (frame.cameraVibrationOffsetPx != 0.0) {
      canvas.translate(0.0, frame.cameraVibrationOffsetPx);
    }

    final Vector3 cameraPos = Vector3(
      engine.courseCenterX(frame.biome, frame.cameraDistanceMeters),
      engine.courseCenterY(frame.biome, frame.cameraDistanceMeters) +
          frame.cameraHeightMeters,
      frame.cameraDistanceMeters,
    );

    // 1. Niebo + słońce / mgła równikowa / blask pustynny
    _paintSkyAndSun(canvas, size);

    // 2. Dalekie pasma horyzontu (wzgórza Kigali, mesy AlUla, grzbiety Malezji)
    _paintHorizonSilhouettes(canvas, size);

    // 3. Płaszczyzna podłoża (czerwony lateryt / złoty piasek / ciemna dżungla)
    _paintGroundPlane(canvas, size);

    // 4. Wstęga drogi 3D (bruk Mur de Kigali / asfalt AlUla / mokry asfalt MY)
    _paintRoadRibbon(canvas, size, cameraPos);

    // 5. Obiekty scenerii 3D posortowane od najdalszych
    _paintProps(canvas, size, cameraPos);

    // 6. Kolarze 3D na trasie
    _paintPelotonRiders(canvas, size, cameraPos);

    // 7. Cząsteczki atmosferyczne (pył czerwony, burza piaskowa, deszcz)
    _paintParticles(canvas, size, cameraPos);

    // 8. Atmosferyczny post-pass (miraż AlUla / wilgoć dżungli / pył Rwandy)
    _paintAtmosphericOverlay(canvas, size);

    canvas.restore();
  }

  void _paintSkyAndSun(Canvas canvas, Size size) {
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.56);
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          frame.biome.skyTopColor,
          frame.biome.skyHorizonColor,
        ],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Słońce lub rozproszona poświata przez korony drzew
    final Offset sunCenter = switch (frame.biome) {
      Exotic3dBiome.rwandaMurDeKigali =>
        Offset(size.width * 0.74, size.height * 0.22),
      Exotic3dBiome.alulaDesertCanyons =>
        Offset(size.width * 0.52, size.height * 0.17),
      Exotic3dBiome.malaysiaTropicalJungle =>
        Offset(size.width * 0.28, size.height * 0.19),
    };

    final double sunRadius = frame.biome == Exotic3dBiome.alulaDesertCanyons
        ? size.height * 0.16
        : size.height * 0.12;
    final Color sunCoreColor = switch (frame.biome) {
      Exotic3dBiome.rwandaMurDeKigali => const Color(0xFFFFE4B5),
      Exotic3dBiome.alulaDesertCanyons => const Color(0xFFFFF4D2),
      Exotic3dBiome.malaysiaTropicalJungle => const Color(0xFFDDF2E6),
    };

    final Paint sunGlow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          sunCoreColor.withValues(alpha: 0.9),
          frame.biome.skyHorizonColor.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius * 2.2));
    canvas.drawCircle(sunCenter, sunRadius * 2.2, sunGlow);
  }

  void _paintHorizonSilhouettes(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.52;
    final double yawShift = frame.cameraYawRadians * 180.0;
    final Path ridge = Path()..moveTo(0, horizonY);

    switch (frame.biome) {
      case Exotic3dBiome.rwandaMurDeKigali:
        // "Kraj Tysiąca Wzgórz" — falujące tarasowe wzgórza Kigali
        for (double x = 0; x <= size.width + 20; x += 24) {
          final double h = 28.0 +
              math.sin((x + yawShift) * 0.012) * 18.0 +
              math.cos((x + yawShift) * 0.029) * 9.0;
          ridge.lineTo(x, horizonY - h);
        }
        ridge
          ..lineTo(size.width, horizonY + 8)
          ..lineTo(0, horizonY + 8)
          ..close();
        canvas.drawPath(
          ridge,
          Paint()..color = const Color(0xFF7B3E2B).withValues(alpha: 0.68),
        );
      case Exotic3dBiome.alulaDesertCanyons:
        // Płaskie mesy i strome wieże piaskowca AlUla
        for (double x = 0; x <= size.width + 24; x += 28) {
          final int bucket = ((x + yawShift) / 56).floor();
          final double plateau = (bucket % 3 == 0)
              ? 46.0
              : (bucket % 3 == 1 ? 22.0 : 34.0);
          ridge.lineTo(x, horizonY - plateau);
        }
        ridge
          ..lineTo(size.width, horizonY + 8)
          ..lineTo(0, horizonY + 8)
          ..close();
        canvas.drawPath(
          ridge,
          Paint()..color = const Color(0xFF9C5E35).withValues(alpha: 0.72),
        );
      case Exotic3dBiome.malaysiaTropicalJungle:
        // Mgliste górskie grzbiety dżungli równikowej
        for (double x = 0; x <= size.width + 20; x += 20) {
          final double h = 36.0 +
              math.sin((x + yawShift) * 0.016) * 20.0 +
              math.sin((x + yawShift) * 0.045) * 6.0;
          ridge.lineTo(x, horizonY - h);
        }
        ridge
          ..lineTo(size.width, horizonY + 8)
          ..lineTo(0, horizonY + 8)
          ..close();
        canvas.drawPath(
          ridge,
          Paint()..color = const Color(0xFF204731).withValues(alpha: 0.78),
        );
    }
  }

  void _paintGroundPlane(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.515;
    final Rect groundRect = Rect.fromLTRB(0, horizonY, size.width, size.height);
    final Paint groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          frame.biome.terrainAccentColor,
          frame.biome.terrainBaseColor,
        ],
      ).createShader(groundRect);
    canvas.drawRect(groundRect, groundPaint);
  }

  void _paintRoadRibbon(Canvas canvas, Size size, Vector3 cameraPos) {
    final List<ExoticRoadSlice3D> slices = frame.roadSlices;
    if (slices.length < 2) return;

    final List<Offset?> leftPts = <Offset?>[];
    final List<Offset?> rightPts = <Offset?>[];
    final List<Offset?> centerPts = <Offset?>[];

    for (final ExoticRoadSlice3D slice in slices) {
      leftPts.add(
        engine.projectWorldPoint(
          worldPoint: Vector3(
            slice.centerX - slice.halfWidthMeters,
            slice.centerY,
            slice.distanceMeters,
          ),
          cameraPos: cameraPos,
          cameraYawRadians: frame.cameraYawRadians,
          cameraPitchRadians: frame.cameraPitchRadians,
          fovDegrees: frame.cameraFovDegrees,
          viewportSize: size,
        ),
      );
      rightPts.add(
        engine.projectWorldPoint(
          worldPoint: Vector3(
            slice.centerX + slice.halfWidthMeters,
            slice.centerY,
            slice.distanceMeters,
          ),
          cameraPos: cameraPos,
          cameraYawRadians: frame.cameraYawRadians,
          cameraPitchRadians: frame.cameraPitchRadians,
          fovDegrees: frame.cameraFovDegrees,
          viewportSize: size,
        ),
      );
      centerPts.add(
        engine.projectWorldPoint(
          worldPoint: Vector3(
            slice.centerX,
            slice.centerY,
            slice.distanceMeters,
          ),
          cameraPos: cameraPos,
          cameraYawRadians: frame.cameraYawRadians,
          cameraPitchRadians: frame.cameraPitchRadians,
          fovDegrees: frame.cameraFovDegrees,
          viewportSize: size,
        ),
      );
    }

    // Rysuj segmenty od najdalszego do najbliższego
    for (int i = slices.length - 2; i >= 0; i--) {
      final Offset? l1 = leftPts[i];
      final Offset? r1 = rightPts[i];
      final Offset? l2 = leftPts[i + 1];
      final Offset? r2 = rightPts[i + 1];
      final Offset? c1 = centerPts[i];
      final Offset? c2 = centerPts[i + 1];

      if (l1 == null || r1 == null || l2 == null || r2 == null) continue;
      final ExoticRoadSlice3D slice = slices[i];

      // Pobocze drogi (czerwona ziemia / piasek / zielony rów)
      final Path shoulderPath = Path()
        ..moveTo(l1.dx - (r1.dx - l1.dx) * 0.22, l1.dy)
        ..lineTo(r1.dx + (r1.dx - l1.dx) * 0.22, r1.dy)
        ..lineTo(r2.dx + (r2.dx - l2.dx) * 0.22, r2.dy)
        ..lineTo(l2.dx - (r2.dx - l2.dx) * 0.22, l2.dy)
        ..close();
      canvas.drawPath(
        shoulderPath,
        Paint()..color = frame.biome.roadEdgeColor,
      );

      // Główna nawierzchnia drogi
      Color surfaceColor = frame.biome.roadSurfaceColor;
      if (frame.biome == Exotic3dBiome.rwandaMurDeKigali) {
        final bool alt = slice.cobbleRowSeed.isEven;
        surfaceColor = alt
            ? const Color(0xFF554D49)
            : const Color(0xFF47403D);
      } else if (frame.biome == Exotic3dBiome.alulaDesertCanyons &&
          slice.sandDriftCoverage > 0.15) {
        surfaceColor = Color.lerp(
          frame.biome.roadSurfaceColor,
          const Color(0xFFD6A35B),
          slice.sandDriftCoverage * 0.55,
        )!;
      } else if (frame.biome == Exotic3dBiome.malaysiaTropicalJungle &&
          slice.wetnessFactor > 0.15) {
        surfaceColor = Color.lerp(
          frame.biome.roadSurfaceColor,
          const Color(0xFF4D6E68),
          slice.wetnessFactor * 0.32,
        )!;
      }

      final Path roadPath = Path()
        ..moveTo(l1.dx, l1.dy)
        ..lineTo(r1.dx, r1.dy)
        ..lineTo(r2.dx, r2.dy)
        ..lineTo(l2.dx, l2.dy)
        ..close();
      canvas.drawPath(roadPath, Paint()..color = surfaceColor);

      // Rząd kostki brukowej na Mur de Kigali
      if (frame.biome.isCobblestone && (r1.dx - l1.dx) > 40.0) {
        final Paint cobbleLinePaint = Paint()
          ..color = const Color(0xFF2E2927).withValues(alpha: 0.48)
          ..strokeWidth = 1.2;
        canvas.drawLine(l1, r1, cobbleLinePaint);
      }

      // Środkowa przerywana linia na asfalcie (AlUla / Malezja)
      if (!frame.biome.isCobblestone &&
          c1 != null &&
          c2 != null &&
          slice.cobbleRowSeed % 3 == 0) {
        final Paint centerLinePaint = Paint()
          ..color = frame.biome == Exotic3dBiome.alulaDesertCanyons
              ? const Color(0xFFEBD29A).withValues(alpha: 0.72)
              : const Color(0xFFE5E7EB).withValues(alpha: 0.75)
          ..strokeWidth = ((r1.dx - l1.dx) * 0.025).clamp(1.0, 3.5);
        canvas.drawLine(c1, c2, centerLinePaint);
      }
    }
  }

  void _paintProps(Canvas canvas, Size size, Vector3 cameraPos) {
    for (final ExoticSceneryProp3D prop in frame.visibleProps) {
      final double baseX =
          engine.courseCenterX(frame.biome, prop.distanceAlongCourseMeters) +
              prop.lateralOffsetMeters;
      final double baseY =
          engine.courseCenterY(frame.biome, prop.distanceAlongCourseMeters) +
              prop.elevationOffsetMeters;

      final Offset? baseScreen = engine.projectWorldPoint(
        worldPoint: Vector3(baseX, baseY, prop.distanceAlongCourseMeters),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      if (baseScreen == null) continue;

      final double depth = prop.distanceAlongCourseMeters - cameraPos.z;
      if (depth <= 1.0) continue;

      final double pxWidth = engine.projectMetersToPixels(
        meters: prop.widthMeters,
        depthMeters: depth,
        fovDegrees: frame.cameraFovDegrees,
        viewportHeight: size.height,
      );
      final double pxHeight = engine.projectMetersToPixels(
        meters: prop.heightMeters,
        depthMeters: depth,
        fovDegrees: frame.cameraFovDegrees,
        viewportHeight: size.height,
      );

      if (pxWidth < 1.5 && pxHeight < 1.5) continue;

      final double fogFactor =
          (depth / frame.visibilityRangeMeters).clamp(0.0, 0.75);

      _drawPropByKind(
        canvas: canvas,
        prop: prop,
        base: baseScreen,
        w: pxWidth,
        h: pxHeight,
        fogFactor: fogFactor,
      );
    }
  }

  void _drawPropByKind({
    required Canvas canvas,
    required ExoticSceneryProp3D prop,
    required Offset base,
    required double w,
    required double h,
    required double fogFactor,
  }) {
    final Color pCol = Color.lerp(
      prop.primaryColor,
      frame.biome.skyHorizonColor,
      fogFactor * 0.55,
    )!;
    final Color sCol = Color.lerp(
      prop.secondaryColor,
      frame.biome.skyHorizonColor,
      fogFactor * 0.55,
    )!;

    switch (prop.kind) {
      case Exotic3dPropKind.lateriteEmbankment:
        final Path bank = Path()
          ..moveTo(base.dx - w * 0.5, base.dy)
          ..lineTo(base.dx - w * 0.25, base.dy - h)
          ..lineTo(base.dx + w * 0.3, base.dy - h * 0.9)
          ..lineTo(base.dx + w * 0.5, base.dy)
          ..close();
        canvas.drawPath(bank, Paint()..color = pCol);
        canvas.drawLine(
          Offset(base.dx - w * 0.25, base.dy - h),
          Offset(base.dx + w * 0.3, base.dy - h * 0.9),
          Paint()
            ..color = sCol
            ..strokeWidth = (h * 0.14).clamp(1.0, 4.0),
        );

      case Exotic3dPropKind.savannaAcaciaTree:
        final double sway = math.sin(prop.swayPhaseRad) * w * 0.04;
        // Pień akacji
        canvas.drawLine(
          base,
          Offset(base.dx + sway * 0.5, base.dy - h * 0.75),
          Paint()
            ..color = pCol
            ..strokeWidth = (w * 0.09).clamp(1.5, 7.0),
        );
        // Płaska parasolowata korona akacji sawannowej
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(base.dx + sway, base.dy - h * 0.82),
            width: w,
            height: h * 0.26,
          ),
          Paint()..color = sCol,
        );

      case Exotic3dPropKind.bananaGrove:
        for (int b = -1; b <= 1; b++) {
          final double sway = math.sin(prop.swayPhaseRad + b) * w * 0.08;
          final Offset top = Offset(base.dx + b * w * 0.24 + sway, base.dy - h);
          canvas.drawLine(
            Offset(base.dx + b * w * 0.12, base.dy),
            top,
            Paint()
              ..color = pCol
              ..strokeWidth = (w * 0.08).clamp(1.2, 4.0),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(top.dx + b * w * 0.12, top.dy + h * 0.12),
              width: w * 0.48,
              height: h * 0.22,
            ),
            Paint()..color = sCol,
          );
        }

      case Exotic3dPropKind.kigaliSpectatorCrowd:
        final double jump = math.sin(prop.swayPhaseRad).abs() * h * 0.16;
        final double personW = (w * 0.22).clamp(2.0, 12.0);
        for (int k = -1; k <= 1; k++) {
          final double cx = base.dx + k * personW * 1.15;
          final Color shirt = k == 0 ? pCol : (k < 0 ? sCol : AppColors.crimsonAlert);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                cx - personW * 0.4,
                base.dy - h * 0.72 - jump,
                personW * 0.8,
                h * 0.65,
              ),
              const Radius.circular(3),
            ),
            Paint()..color = shirt,
          );
          canvas.drawCircle(
            Offset(cx, base.dy - h * 0.84 - jump),
            personW * 0.32,
            Paint()..color = const Color(0xFF432C22),
          );
        }

      case Exotic3dPropKind.rwandaFlagPole:
        canvas.drawLine(
          base,
          Offset(base.dx, base.dy - h),
          Paint()
            ..color = const Color(0xFFD1D5DB)
            ..strokeWidth = 1.6,
        );
        final double wave = math.sin(prop.swayPhaseRad) * h * 0.04;
        final double fw = w.clamp(6.0, 32.0);
        final double fh = (h * 0.26).clamp(4.0, 18.0);
        canvas.drawRect(
          Rect.fromLTWH(base.dx, base.dy - h + wave, fw, fh * 0.5),
          Paint()..color = const Color(0xFF00A1DE),
        );
        canvas.drawRect(
          Rect.fromLTWH(base.dx, base.dy - h + fh * 0.5 + wave, fw, fh * 0.25),
          Paint()..color = const Color(0xFFFAD201),
        );
        canvas.drawRect(
          Rect.fromLTWH(base.dx, base.dy - h + fh * 0.75 + wave, fw, fh * 0.25),
          Paint()..color = const Color(0xFF20603D),
        );

      case Exotic3dPropKind.rwandaCobbleBannerArch:
        final double pillarW = (w * 0.07).clamp(3.0, 14.0);
        canvas.drawRect(
          Rect.fromLTWH(base.dx - w * 0.5, base.dy - h, pillarW, h),
          Paint()..color = pCol,
        );
        canvas.drawRect(
          Rect.fromLTWH(base.dx + w * 0.5 - pillarW, base.dy - h, pillarW, h),
          Paint()..color = pCol,
        );
        canvas.drawRect(
          Rect.fromLTWH(base.dx - w * 0.5, base.dy - h, w, h * 0.22),
          Paint()..color = sCol,
        );

      case Exotic3dPropKind.sandstoneCanyonWall:
        final Path cliff = Path()
          ..moveTo(base.dx - w * 0.5, base.dy)
          ..lineTo(base.dx - w * 0.42, base.dy - h * 0.92)
          ..lineTo(base.dx - w * 0.1, base.dy - h)
          ..lineTo(base.dx + w * 0.36, base.dy - h * 0.88)
          ..lineTo(base.dx + w * 0.5, base.dy)
          ..close();
        canvas.drawPath(cliff, Paint()..color = pCol);
        // Warstwy geologiczne piaskowca
        for (int s = 1; s <= 3; s++) {
          final double sy = base.dy - h * (0.22 * s);
          canvas.drawLine(
            Offset(base.dx - w * 0.4, sy),
            Offset(base.dx + w * 0.4, sy + h * 0.03),
            Paint()
              ..color = sCol.withValues(alpha: 0.55)
              ..strokeWidth = (h * 0.04).clamp(1.0, 5.0),
          );
        }

      case Exotic3dPropKind.alulaMonolithArch:
        final Path arch = Path()
          ..moveTo(base.dx - w * 0.5, base.dy)
          ..lineTo(base.dx - w * 0.35, base.dy - h)
          ..lineTo(base.dx + w * 0.35, base.dy - h * 0.96)
          ..lineTo(base.dx + w * 0.5, base.dy)
          ..lineTo(base.dx + w * 0.22, base.dy)
          ..lineTo(base.dx + w * 0.14, base.dy - h * 0.52)
          ..lineTo(base.dx - w * 0.14, base.dy - h * 0.52)
          ..lineTo(base.dx - w * 0.22, base.dy)
          ..close();
        canvas.drawPath(arch, Paint()..color = pCol);

      case Exotic3dPropKind.desertSandDune:
        final Path dune = Path()
          ..moveTo(base.dx - w * 0.55, base.dy)
          ..quadraticBezierTo(base.dx, base.dy - h * 1.45, base.dx + w * 0.55, base.dy)
          ..close();
        canvas.drawPath(dune, Paint()..color = pCol);
        final Path crest = Path()
          ..moveTo(base.dx - w * 0.55, base.dy)
          ..quadraticBezierTo(base.dx - w * 0.1, base.dy - h * 1.38, base.dx, base.dy - h * 0.75)
          ..lineTo(base.dx + w * 0.55, base.dy)
          ..close();
        canvas.drawPath(crest, Paint()..color = sCol.withValues(alpha: 0.45));

      case Exotic3dPropKind.datePalmOasis:
      case Exotic3dPropKind.tropicalOilPalm:
        final double sway = math.sin(prop.swayPhaseRad) * w * 0.06;
        final Offset crown = Offset(base.dx + sway, base.dy - h);
        canvas.drawLine(
          base,
          crown,
          Paint()
            ..color = pCol
            ..strokeWidth = (w * 0.08).clamp(1.5, 6.5),
        );
        // Liście palmy
        for (int f = 0; f < 6; f++) {
          final double angle = (f / 6.0) * math.pi * 2.0 + sway * 0.02;
          final Offset tip = Offset(
            crown.dx + math.cos(angle) * w * 0.48,
            crown.dy + math.sin(angle) * h * 0.22 + h * 0.06,
          );
          canvas.drawLine(
            crown,
            tip,
            Paint()
              ..color = sCol
              ..strokeWidth = (w * 0.07).clamp(1.2, 4.5)
              ..strokeCap = StrokeCap.round,
          );
        }

      case Exotic3dPropKind.sandDriftPatch:
        canvas.drawOval(
          Rect.fromCenter(
            center: base,
            width: w,
            height: (h * 4.5).clamp(2.5, 16.0),
          ),
          Paint()..color = pCol.withValues(alpha: 0.72),
        );

      case Exotic3dPropKind.giantBambooCluster:
        for (int b = -2; b <= 2; b++) {
          final double sway = math.sin(prop.swayPhaseRad + b * 0.4) * w * 0.08;
          canvas.drawLine(
            Offset(base.dx + b * w * 0.14, base.dy),
            Offset(base.dx + b * w * 0.24 + sway, base.dy - h),
            Paint()
              ..color = b.isEven ? pCol : sCol
              ..strokeWidth = (w * 0.07).clamp(1.0, 3.5),
          );
        }

      case Exotic3dPropKind.jungleFernUnderstory:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(base.dx, base.dy - h * 0.45),
            width: w,
            height: h * 0.9,
          ),
          Paint()..color = pCol,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(base.dx, base.dy - h * 0.65),
            width: w * 0.7,
            height: h * 0.55,
          ),
          Paint()..color = sCol,
        );

      case Exotic3dPropKind.monsoonMistPillar:
        final double drift = math.sin(prop.swayPhaseRad) * w * 0.12;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(base.dx + drift, base.dy - h * 0.5),
            width: w,
            height: h,
          ),
          Paint()..color = pCol.withValues(alpha: 0.18 * (1.0 - fogFactor)),
        );

      case Exotic3dPropKind.langkawiKmMarker:
        canvas.drawLine(
          base,
          Offset(base.dx, base.dy - h),
          Paint()
            ..color = const Color(0xFF9CA3AF)
            ..strokeWidth = 1.6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              base.dx - w * 0.5,
              base.dy - h,
              w.clamp(6.0, 26.0),
              (h * 0.42).clamp(5.0, 18.0),
            ),
            const Radius.circular(2),
          ),
          Paint()..color = pCol,
        );
    }
  }

  void _paintPelotonRiders(Canvas canvas, Size size, Vector3 cameraPos) {
    for (final ExoticPelotonRiderMarker3D rider in frame.pelotonMarkers) {
      final double worldX =
          engine.courseCenterX(frame.biome, rider.distanceMeters) +
              rider.lateralOffsetMeters;
      final double worldY =
          engine.courseCenterY(frame.biome, rider.distanceMeters);

      final Offset? pos = engine.projectWorldPoint(
        worldPoint: Vector3(worldX, worldY, rider.distanceMeters),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      if (pos == null) continue;

      final double depth = rider.distanceMeters - cameraPos.z;
      if (depth <= 1.0) continue;

      final double h = engine
          .projectMetersToPixels(
            meters: 1.72,
            depthMeters: depth,
            fovDegrees: frame.cameraFovDegrees,
            viewportHeight: size.height,
          )
          .clamp(8.0, 120.0);
      final double w = h * 0.42;

      // Cień kolarza na drodze
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pos.dx + w * 0.18, pos.dy + 1.0),
          width: w * 1.15,
          height: (h * 0.12).clamp(2.0, 8.0),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.36),
      );

      // Tylne koło
      final double wheelR = (h * 0.22).clamp(2.0, 18.0);
      canvas.drawCircle(
        Offset(pos.dx, pos.dy - wheelR),
        wheelR,
        Paint()
          ..color = const Color(0xFF1F2937)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (wheelR * 0.24).clamp(1.0, 3.2),
      );

      // Sylwetka tułowia + kołysanie na stojąco na Mur de Kigali
      final double rock = rider.isOutOfSaddle
          ? math.sin(rider.cadencePhaseRad) * w * 0.22
          : math.sin(rider.cadencePhaseRad) * w * 0.05;
      final double lift = rider.isOutOfSaddle ? h * 0.08 : 0.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            pos.dx - w * 0.34 + rock,
            pos.dy - h * 0.82 - lift,
            w * 0.68,
            h * 0.44,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = rider.jerseyColor,
      );

      // Kask kolarza
      canvas.drawCircle(
        Offset(pos.dx + rock * 1.1, pos.dy - h * 0.92 - lift),
        (w * 0.26).clamp(1.8, 12.0),
        Paint()..color = rider.helmetColor,
      );
    }
  }

  void _paintParticles(Canvas canvas, Size size, Vector3 cameraPos) {
    for (final ExoticAtmosphericParticle3D p in frame.particles) {
      final double worldX =
          engine.courseCenterX(frame.biome, p.distanceMeters) +
              p.lateralOffsetMeters;
      final double worldY =
          engine.courseCenterY(frame.biome, p.distanceMeters) + p.heightMeters;

      final Offset? pt = engine.projectWorldPoint(
        worldPoint: Vector3(worldX, worldY, p.distanceMeters),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      if (pt == null) continue;

      final Paint particlePaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity);

      if (p.streakLengthPx > 0.0) {
        final double dx = frame.biome == Exotic3dBiome.alulaDesertCanyons
            ? p.streakLengthPx
            : -p.streakLengthPx * 0.25;
        final double dy = frame.biome == Exotic3dBiome.alulaDesertCanyons
            ? p.streakLengthPx * 0.14
            : p.streakLengthPx;
        particlePaint.strokeWidth = p.radiusPx.clamp(1.0, 2.5);
        canvas.drawLine(pt, Offset(pt.dx + dx, pt.dy + dy), particlePaint);
      } else {
        canvas.drawCircle(pt, p.radiusPx, particlePaint);
      }
    }
  }

  void _paintAtmosphericOverlay(Canvas canvas, Size size) {
    final double intensity = config.weatherIntensity.clamp(0.0, 1.5);
    if (intensity <= 0.05) return;

    final Color veilColor = switch (frame.biome) {
      Exotic3dBiome.rwandaMurDeKigali => const Color(0xFFB84E32),
      Exotic3dBiome.alulaDesertCanyons => const Color(0xFFE5AE63),
      Exotic3dBiome.malaysiaTropicalJungle => const Color(0xFF8BB8A2),
    };

    final Paint veil = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          veilColor.withValues(alpha: (0.04 * intensity).clamp(0.0, 0.22)),
          veilColor.withValues(alpha: (0.14 * intensity).clamp(0.0, 0.34)),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), veil);
  }

  @override
  bool shouldRepaint(
    covariant ExoticBiomesSavannaDesertJunglePainter oldDelegate,
  ) {
    return oldDelegate.frame != frame || oldDelegate.config != config;
  }
}

// =============================================================================
// 5. INTERAKTYWNY PANEL UI PODGLĄDU 3D (PRODUKCYJNY WIDGET)
// =============================================================================

/// Interaktywny panel podglądu 3D egzotycznych biomów kolarskich:
/// Czerwona ziemia Rwandy (*Mur de Kigali*), Kaniony AlUla i Dżungla Malezji.
class ExoticBiomesSavannaDesertJunglePanel extends StatefulWidget {
  final Exotic3dBiome initialBiome;
  final bool autoPlay;
  final ValueChanged<Exotic3dBiome>? onBiomeChanged;

  const ExoticBiomesSavannaDesertJunglePanel({
    super.key,
    this.initialBiome = Exotic3dBiome.rwandaMurDeKigali,
    this.autoPlay = true,
    this.onBiomeChanged,
  });

  @override
  State<ExoticBiomesSavannaDesertJunglePanel> createState() =>
      _ExoticBiomesSavannaDesertJunglePanelState();
}

class _ExoticBiomesSavannaDesertJunglePanelState
    extends State<ExoticBiomesSavannaDesertJunglePanel>
    with SingleTickerProviderStateMixin {
  final ExoticBiomesSavannaDesertJungleEngine _engine =
      const ExoticBiomesSavannaDesertJungleEngine();

  late AnimationController _ticker;
  late ExoticBiomes3dConfig _config;
  bool _isPlaying = true;
  double _cameraDistanceMeters = 100.0;
  double _elapsedSeconds = 0.0;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.autoPlay;
    _config = ExoticBiomes3dConfig(biome: widget.initialBiome);
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onFrameTick);
    if (_isPlaying) {
      _ticker.repeat();
    }
  }

  @override
  void dispose() {
    _ticker.removeListener(_onFrameTick);
    _ticker.dispose();
    super.dispose();
  }

  void _onFrameTick() {
    final DateTime now = DateTime.now();
    final double dt =
        (now.difference(_lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;

    if (!mounted || !_isPlaying) return;
    setState(() {
      _elapsedSeconds += dt;
      _cameraDistanceMeters += _config.speedMetersPerSecond * dt;
    });
  }

  void _selectBiome(Exotic3dBiome biome) {
    setState(() {
      _config = _config.copyWith(biome: biome);
    });
    widget.onBiomeChanged?.call(biome);
  }

  void _selectCameraPreset(Exotic3dCameraPreset preset) {
    setState(() {
      _config = _config.copyWith(cameraPreset: preset);
    });
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      _lastTick = DateTime.now();
      if (_isPlaying) {
        _ticker.repeat();
      } else {
        _ticker.stop();
      }
    });
  }

  void _stepForward() {
    setState(() {
      _elapsedSeconds += 0.35;
      _cameraDistanceMeters += _config.speedMetersPerSecond * 0.6;
    });
  }

  void _resetCamera() {
    setState(() {
      _cameraDistanceMeters = 100.0;
      _elapsedSeconds = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ExoticBiomes3dFrameState frame = _engine.buildFrame(
      config: _config,
      cameraDistanceMeters: _cameraDistanceMeters,
      elapsedSeconds: _elapsedSeconds,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isDesktopWide = constraints.maxWidth >= 980;
          final bool isCompactMobile = constraints.maxWidth < 600;

          if (isDesktopWide) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: _buildViewportCard(frame, minHeight: 380),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 340,
                    child: SingleChildScrollView(
                      child: _buildControlSidebar(frame, isCompact: false),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompactMobile ? 10 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: isCompactMobile ? 250 : 320,
                  child: _buildViewportCard(frame, minHeight: 240),
                ),
                const SizedBox(height: 12),
                _buildControlSidebar(frame, isCompact: isCompactMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewportCard(
    ExoticBiomes3dFrameState frame, {
    required double minHeight,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            painter: ExoticBiomesSavannaDesertJunglePainter(
              frame: frame,
              config: _config,
              engine: _engine,
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _ExoticHudHeaderBadge(frame: frame),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: _ExoticTelemetryStrip(frame: frame),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSidebar(
    ExoticBiomes3dFrameState frame, {
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'BIOMY EGZOTYCZNE 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            frame.biome.descriptionPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          for (final Exotic3dBiome biome in Exotic3dBiome.values) ...<Widget>[
            _ExoticBiomeSelectorTile(
              biome: biome,
              isSelected: _config.biome == biome,
              onTap: () => _selectBiome(biome),
            ),
            const SizedBox(height: 8),
          ],
          const Divider(color: AppColors.cardBorder, height: 18),
          const Text(
            'KAMERA 3D',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: Exotic3dCameraPreset.values
                .map(
                  (Exotic3dCameraPreset preset) => _ExoticActionChipButton(
                    label: preset.labelPl,
                    isSelected: _config.cameraPreset == preset,
                    onPressed: () => _selectCameraPreset(preset),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ExoticActionButton(
                icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                label: _isPlaying ? 'Pauza' : 'Start',
                isPrimary: true,
                onPressed: _togglePlayback,
              ),
              _ExoticActionButton(
                icon: Icons.skip_next_rounded,
                label: '+0.6s',
                isEnabled: !_isPlaying,
                onPressed: _isPlaying ? null : _stepForward,
              ),
              _ExoticActionButton(
                icon: Icons.restart_alt_rounded,
                label: 'Reset',
                onPressed: _resetCamera,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSliderRow(
            label: 'Intensywność pogody',
            valueLabel: '${(_config.weatherIntensity * 100).round()}%',
            value: _config.weatherIntensity,
            min: 0.0,
            max: 1.5,
            onChanged: (double v) {
              setState(() {
                _config = _config.copyWith(weatherIntensity: v);
              });
            },
          ),
          _buildSliderRow(
            label: 'Prędkość kamery',
            valueLabel: '${_config.speedMetersPerSecond.toStringAsFixed(1)} m/s',
            value: _config.speedMetersPerSecond,
            min: 4.0,
            max: 24.0,
            onChanged: (double v) {
              setState(() {
                _config = _config.copyWith(speedMetersPerSecond: v);
              });
            },
          ),
          const SizedBox(height: 8),
          _buildToggleTile(
            label: 'Markery peletonu 3D',
            value: _config.showPelotonMarkers,
            onChanged: (bool v) {
              setState(() {
                _config = _config.copyWith(showPelotonMarkers: v);
              });
            },
          ),
          _buildToggleTile(
            label: 'Cząsteczki pyłu / piasku / deszczu',
            value: _config.showAtmosphericParticles,
            onChanged: (bool v) {
              setState(() {
                _config = _config.copyWith(showAtmosphericParticles: v);
              });
            },
          ),
          _buildToggleTile(
            label: 'Drgania nawierzchni',
            value: _config.enableSurfaceVibration,
            onChanged: (bool v) {
              setState(() {
                _config = _config.copyWith(enableSurfaceVibration: v);
              });
            },
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.cardBorder,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
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

  Widget _buildToggleTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.goldAccent,
            activeTrackColor: AppColors.primaryAccent,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.surfaceLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ExoticHudHeaderBadge extends StatelessWidget {
  final ExoticBiomes3dFrameState frame;

  const _ExoticHudHeaderBadge({required this.frame});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: frame.biome.accentHighlightColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  frame.biome.labelPl,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  frame.biome.regionPl,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: Text(
              '${frame.cameraDistanceMeters.toStringAsFixed(0)} m',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                color: AppColors.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExoticTelemetryStrip extends StatelessWidget {
  final ExoticBiomes3dFrameState frame;

  const _ExoticTelemetryStrip({required this.frame});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          _metric(
            'TEMP / RH',
            '${frame.biome.ambientTempCelsius.toStringAsFixed(0)}°C / ${frame.biome.humidityPercent.toStringAsFixed(0)}%',
          ),
          _metric(
            'OPÓR CRR',
            '×${frame.effectiveCrrMultiplier.toStringAsFixed(2)}',
          ),
          _metric(
            'WIATR',
            '${frame.effectiveWindMps.toStringAsFixed(1)} m/s',
          ),
          _metric(
            'WIDOCZNOŚĆ',
            '${frame.visibilityRangeMeters.toStringAsFixed(0)} m',
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ExoticBiomeSelectorTile extends StatefulWidget {
  final Exotic3dBiome biome;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExoticBiomeSelectorTile({
    required this.biome,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ExoticBiomeSelectorTile> createState() =>
      _ExoticBiomeSelectorTileState();
}

class _ExoticBiomeSelectorTileState extends State<_ExoticBiomeSelectorTile> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_isFocused
            ? AppColors.accentBlue
            : (_isHovered ? AppColors.textSecondary : AppColors.cardBorder));

    final Color bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.28)
        : (_isPressed
            ? AppColors.surfaceLight
            : (_isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.72)
                : AppColors.background));

    return FocusableActionDetector(
      onShowFocusHighlight: (bool focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 10,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.biome.terrainBaseColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: widget.biome.accentHighlightColor,
                      width: 1.0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.biome.shortTag,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.isSelected
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.biome.regionPl,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExoticActionChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ExoticActionChipButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<_ExoticActionChipButton> createState() =>
      _ExoticActionChipButtonState();
}

class _ExoticActionChipButtonState extends State<_ExoticActionChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (bool f) => setState(() => _isFocused = f),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primaryAccent
                  : (_isHovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : (_isFocused ? AppColors.accentBlue : AppColors.cardBorder),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExoticActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _ExoticActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  State<_ExoticActionButton> createState() => _ExoticActionButtonState();
}

class _ExoticActionButtonState extends State<_ExoticActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled && widget.onPressed != null;
    final Color bg = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isPrimary
            ? (_isPressed
                ? AppColors.primaryAccent.withValues(alpha: 0.78)
                : (_isHovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.92)
                    : AppColors.primaryAccent))
            : (_isPressed
                ? AppColors.surfaceLight
                : (_isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.background));

    final Color border = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : (_isFocused
            ? AppColors.accentBlue
            : (widget.isPrimary ? AppColors.goldAccent : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (bool f) => setState(() => _isFocused = f),
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) {
          if (enabled) setState(() => _isHovered = true);
        },
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 16,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
