// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';

// =============================================================================
// 1. BIOMY IKONICZNYCH SCENERII 3D (WIELKI BEŁT, ARENBERG, TOSKANIA, VENTOUX)
// =============================================================================

/// Ikoniczne biomy scenerii kolarskiej 3D obsługiwane przez silnik.
enum Iconic3dSceneryBiome {
  greatBeltSeaBridge(
    id: 'great_belt_bridge',
    labelPl: 'Morski Most — Wielki Bełt',
    shortTag: 'WIELKI BEŁT',
    regionPl: 'Dania • Storebælt (65 m n.p.m.)',
    descriptionPl:
        'Wiszący most morski nad cieśniną Wielki Bełt z pylonami 254 m, '
        'linami nośnymi, falami Bałtyku i silnym wiatrem bocznym.',
    skyTopColor: Color(0xFF0E233A),
    skyHorizonColor: Color(0xFF7CA4C4),
    terrainBaseColor: Color(0xFF133854),
    roadSurfaceColor: Color(0xFF2B313B),
    roadEdgeColor: Color(0xFF6B7280),
    accentHighlightColor: Color(0xFF38BDF8),
    altitudeMeters: 65.0,
    defaultCrosswindMps: 11.4,
    crosswindDirectionDeg: 285.0,
    surfaceGripMu: 0.82,
    rollingResistanceMultiplier: 1.00,
    canopyShadowFactor: 0.05,
    ambientTempCelsius: 14.5,
    roadWidthMeters: 8.6,
  ),
  arenbergForestTrench(
    id: 'arenberg_trench',
    labelPl: 'Przekop Leśny — Trouée d\'Arenberg',
    shortTag: 'ARENBERG',
    regionPl: 'Francja • Paryż–Roubaix (25 m n.p.m.)',
    descriptionPl:
        'Słynny leśny przekop o długości 2.4 km z 5-gwiazdkowym brukiem, '
        'gęstym sklepieniem buków, skarpami i barierami kibiców.',
    skyTopColor: Color(0xFF132419),
    skyHorizonColor: Color(0xFF547255),
    terrainBaseColor: Color(0xFF213624),
    roadSurfaceColor: Color(0xFF56585C),
    roadEdgeColor: Color(0xFF3E4A2E),
    accentHighlightColor: Color(0xFF10B981),
    altitudeMeters: 25.0,
    defaultCrosswindMps: 2.1,
    crosswindDirectionDeg: 140.0,
    surfaceGripMu: 0.58,
    rollingResistanceMultiplier: 1.78,
    canopyShadowFactor: 0.76,
    ambientTempCelsius: 13.0,
    roadWidthMeters: 5.2,
  ),
  tuscanyChalkHills(
    id: 'tuscany_chalk_hills',
    labelPl: 'Kredowe Wzgórza — Toskania',
    shortTag: 'TOSKANIA',
    regionPl: 'Włochy • Crete Senesi / Strade Bianche',
    descriptionPl:
        'Falujące kredowe wzgórza Crete Senesi z białymi drogami sterrato, '
        'alejami cyprysów, wapiennymi skarpami i chmurami pyłu.',
    skyTopColor: Color(0xFF1E3B5C),
    skyHorizonColor: Color(0xFFE5D2B0),
    terrainBaseColor: Color(0xFF7B6E44),
    roadSurfaceColor: Color(0xFFE5DEC9),
    roadEdgeColor: Color(0xFFC5B999),
    accentHighlightColor: Color(0xFFD4AF37),
    altitudeMeters: 340.0,
    defaultCrosswindMps: 4.5,
    crosswindDirectionDeg: 215.0,
    surfaceGripMu: 0.68,
    rollingResistanceMultiplier: 1.38,
    canopyShadowFactor: 0.14,
    ambientTempCelsius: 25.5,
    roadWidthMeters: 5.8,
  ),
  montVentouxLunarSummit(
    id: 'mont_ventoux_summit',
    labelPl: 'Księżycowy Szczyt — Mont Ventoux',
    shortTag: 'MONT VENTOUX',
    regionPl: 'Prowansja • 1909 m n.p.m. (HC)',
    descriptionPl:
        'Surowy wapienny piarg powyżej linii lasu, czerwono-biała wieża '
        'obserwatorium na szczycie, pomnik Simpsona i porywy Mistralu.',
    skyTopColor: Color(0xFF0A1629),
    skyHorizonColor: Color(0xFFAEC4D8),
    terrainBaseColor: Color(0xFFC9CDD1),
    roadSurfaceColor: Color(0xFF393E47),
    roadEdgeColor: Color(0xFFD5D9DE),
    accentHighlightColor: Color(0xFFEF4444),
    altitudeMeters: 1909.0,
    defaultCrosswindMps: 14.8,
    crosswindDirectionDeg: 320.0,
    surfaceGripMu: 0.80,
    rollingResistanceMultiplier: 1.04,
    canopyShadowFactor: 0.0,
    ambientTempCelsius: 8.5,
    roadWidthMeters: 6.4,
  );

  final String id;
  final String labelPl;
  final String shortTag;
  final String regionPl;
  final String descriptionPl;
  final Color skyTopColor;
  final Color skyHorizonColor;
  final Color terrainBaseColor;
  final Color roadSurfaceColor;
  final Color roadEdgeColor;
  final Color accentHighlightColor;
  final double altitudeMeters;
  final double defaultCrosswindMps;
  final double crosswindDirectionDeg;
  final double surfaceGripMu;
  final double rollingResistanceMultiplier;
  final double canopyShadowFactor;
  final double ambientTempCelsius;
  final double roadWidthMeters;

  const Iconic3dSceneryBiome({
    required this.id,
    required this.labelPl,
    required this.shortTag,
    required this.regionPl,
    required this.descriptionPl,
    required this.skyTopColor,
    required this.skyHorizonColor,
    required this.terrainBaseColor,
    required this.roadSurfaceColor,
    required this.roadEdgeColor,
    required this.accentHighlightColor,
    required this.altitudeMeters,
    required this.defaultCrosswindMps,
    required this.crosswindDirectionDeg,
    required this.surfaceGripMu,
    required this.rollingResistanceMultiplier,
    required this.canopyShadowFactor,
    required this.ambientTempCelsius,
    required this.roadWidthMeters,
  });
}

// =============================================================================
// 2. KONFIGURACJA, KAMERA I STRUKTURY DANYCH SCENERII 3D
// =============================================================================

/// Konfiguracja renderera ikonicznych scenerii 3D.
class CoastalBridgesAndCobbleConfig {
  final Iconic3dSceneryBiome biome;
  final double forwardVisibilityMeters;
  final double backwardVisibilityMeters;
  final double cameraHeightMeters;
  final double cameraFovDegrees;
  final double speedMetersPerSecond;
  final double windIntensityScale;
  final bool showPelotonMarkers;
  final bool showAtmosphericParticles;
  final bool enableSurfaceVibration;
  final int stageSeed;

  const CoastalBridgesAndCobbleConfig({
    this.biome = Iconic3dSceneryBiome.greatBeltSeaBridge,
    this.forwardVisibilityMeters = 360.0,
    this.backwardVisibilityMeters = 12.0,
    this.cameraHeightMeters = 2.6,
    this.cameraFovDegrees = 58.0,
    this.speedMetersPerSecond = 12.5,
    this.windIntensityScale = 1.0,
    this.showPelotonMarkers = true,
    this.showAtmosphericParticles = true,
    this.enableSurfaceVibration = true,
    this.stageSeed = 383,
  });

  CoastalBridgesAndCobbleConfig copyWith({
    Iconic3dSceneryBiome? biome,
    double? forwardVisibilityMeters,
    double? backwardVisibilityMeters,
    double? cameraHeightMeters,
    double? cameraFovDegrees,
    double? speedMetersPerSecond,
    double? windIntensityScale,
    bool? showPelotonMarkers,
    bool? showAtmosphericParticles,
    bool? enableSurfaceVibration,
    int? stageSeed,
  }) {
    return CoastalBridgesAndCobbleConfig(
      biome: biome ?? this.biome,
      forwardVisibilityMeters:
          forwardVisibilityMeters ?? this.forwardVisibilityMeters,
      backwardVisibilityMeters:
          backwardVisibilityMeters ?? this.backwardVisibilityMeters,
      cameraHeightMeters: cameraHeightMeters ?? this.cameraHeightMeters,
      cameraFovDegrees: cameraFovDegrees ?? this.cameraFovDegrees,
      speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
      windIntensityScale: windIntensityScale ?? this.windIntensityScale,
      showPelotonMarkers: showPelotonMarkers ?? this.showPelotonMarkers,
      showAtmosphericParticles:
          showAtmosphericParticles ?? this.showAtmosphericParticles,
      enableSurfaceVibration:
          enableSurfaceVibration ?? this.enableSurfaceVibration,
      stageSeed: stageSeed ?? this.stageSeed,
    );
  }
}

/// Typ obiektu architektonicznego lub terenowego w scenerii 3D.
enum SceneryPropKind {
  bridgePylon,
  bridgeSuspender,
  seaVessel,
  trenchCanopyTree,
  trenchSpectatorBarrier,
  tuscanCypress,
  tuscanChalkOutcrop,
  tuscanFarmhouse,
  ventouxSummitTower,
  ventouxMemorialStele,
  ventouxLimestoneBoulder,
  ventouxSnowPole,
}

/// Obiekt 3D umieszczony względem osi trasy w układzie świata.
class SceneryProp3D {
  final String id;
  final SceneryPropKind kind;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double elevationOffsetMeters;
  final double widthMeters;
  final double heightMeters;
  final double depthMeters;
  final Color primaryColor;
  final Color secondaryColor;
  final double swayPhaseRad;

  const SceneryProp3D({
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
  });
}

/// Próbka segmentu nawierzchni drogi w przestrzeni 3D.
class RoadRibbonSlice3D {
  final double distanceMeters;
  final double centerX;
  final double centerY;
  final double halfWidthMeters;
  final double slopeRadians;
  final bool hasExpansionJoint;
  final int cobbleRowSeed;

  const RoadRibbonSlice3D({
    required this.distanceMeters,
    required this.centerX,
    required this.centerY,
    required this.halfWidthMeters,
    required this.slopeRadians,
    this.hasExpansionJoint = false,
    this.cobbleRowSeed = 0,
  });
}

/// Cząsteczka atmosferyczna (bryza morska, pył kredowy, liście, mgła szczytowa).
class AtmosphericParticle3D {
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double heightMeters;
  final double radiusPx;
  final double opacity;
  final Color color;

  const AtmosphericParticle3D({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.heightMeters,
    required this.radiusPx,
    required this.opacity,
    required this.color,
  });
}

/// Znacznik kolarza w peletonie nadający skalę przestrzeni 3D.
class SceneryPelotonRiderMarker3D {
  final int riderIndex;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final Color jerseyColor;
  final Color helmetColor;
  final double cadencePhase;

  const SceneryPelotonRiderMarker3D({
    required this.riderIndex,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.jerseyColor,
    required this.helmetColor,
    required this.cadencePhase,
  });
}

/// Zrzut stanu klatki scenerii 3D wraz z metrykami fizycznymi i wydajnościowymi.
class Scenery3dFrameState {
  final Iconic3dSceneryBiome biome;
  final double cameraDistanceMeters;
  final double elapsedSeconds;
  final double effectiveCrosswindMps;
  final double cameraVibrationOffsetPx;
  final List<RoadRibbonSlice3D> roadSlices;
  final List<SceneryProp3D> visibleProps;
  final List<AtmosphericParticle3D> particles;
  final List<SceneryPelotonRiderMarker3D> pelotonMarkers;
  final int totalGeneratedProps;
  final int culledPropsCount;

  const Scenery3dFrameState({
    required this.biome,
    required this.cameraDistanceMeters,
    required this.elapsedSeconds,
    required this.effectiveCrosswindMps,
    required this.cameraVibrationOffsetPx,
    required this.roadSlices,
    required this.visibleProps,
    required this.particles,
    required this.pelotonMarkers,
    required this.totalGeneratedProps,
    required this.culledPropsCount,
  });
}

// =============================================================================
// 3. SILNIK GEOMETRII I RZUTOWANIA SCENERII 3D
// =============================================================================

/// Generator deterministycznej geometrii 3D i rzutowania perspektywicznego
/// dla mostów morskich, przekopów leśnych, wzgórz kredowych i szczytów alpejskich.
class CoastalBridgesAndCobbleTrenchesEngine {
  static const List<Color> _pelotonJerseys = <Color>[
    AppColors.goldAccent,
    AppColors.primaryAccent,
    AppColors.accentBlue,
    AppColors.statusSuccess,
    Color(0xFFE5E7EB),
    AppColors.amberWarning,
  ];

  const CoastalBridgesAndCobbleTrenchesEngine();

  /// Buduje kompletną klatkę 3D na podstawie konfiguracji, dystansu kamery i czasu.
  Scenery3dFrameState buildFrame({
    required CoastalBridgesAndCobbleConfig config,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    final Iconic3dSceneryBiome biome = config.biome;
    final double startDist = math.max(
      0.0,
      cameraDistanceMeters - config.backwardVisibilityMeters,
    );
    final double endDist = cameraDistanceMeters + config.forwardVisibilityMeters;

    final double effectiveWind = _computeEffectiveWind(
      biome: biome,
      windScale: config.windIntensityScale,
      elapsedSeconds: elapsedSeconds,
    );

    final double vibrationPx = _computeCameraVibrationPx(
      config: config,
      elapsedSeconds: elapsedSeconds,
      effectiveWind: effectiveWind,
    );

    final List<RoadRibbonSlice3D> slices = _buildRoadSlices(
      biome: biome,
      startDist: startDist,
      endDist: endDist,
    );

    final List<SceneryProp3D> allProps = _generateBiomeProps(
      biome: biome,
      startDist: startDist,
      endDist: endDist,
      seed: config.stageSeed,
    );

    final List<SceneryProp3D> visibleProps = <SceneryProp3D>[];
    int culled = 0;
    for (final SceneryProp3D prop in allProps) {
      final double relZ = prop.distanceAlongCourseMeters - cameraDistanceMeters;
      if (relZ >= 1.5 && relZ <= config.forwardVisibilityMeters) {
        visibleProps.add(prop);
      } else {
        culled++;
      }
    }

    // Sortowanie od najdalszych do najbliższych (algorytm malarza).
    visibleProps.sort(
      (a, b) =>
          b.distanceAlongCourseMeters.compareTo(a.distanceAlongCourseMeters),
    );

    final List<AtmosphericParticle3D> particles =
        config.showAtmosphericParticles
            ? _generateParticles(
                biome: biome,
                cameraDistanceMeters: cameraDistanceMeters,
                forwardVisibilityMeters: config.forwardVisibilityMeters,
                elapsedSeconds: elapsedSeconds,
                effectiveWind: effectiveWind,
              )
            : const <AtmosphericParticle3D>[];

    final List<SceneryPelotonRiderMarker3D> riders = config.showPelotonMarkers
        ? _generatePelotonMarkers(
            biome: biome,
            cameraDistanceMeters: cameraDistanceMeters,
            elapsedSeconds: elapsedSeconds,
          )
        : const <SceneryPelotonRiderMarker3D>[];

    return Scenery3dFrameState(
      biome: biome,
      cameraDistanceMeters: cameraDistanceMeters,
      elapsedSeconds: elapsedSeconds,
      effectiveCrosswindMps: effectiveWind,
      cameraVibrationOffsetPx: vibrationPx,
      roadSlices: slices,
      visibleProps: visibleProps,
      particles: particles,
      pelotonMarkers: riders,
      totalGeneratedProps: allProps.length,
      culledPropsCount: culled,
    );
  }

  /// Wylicza współrzędną X osi drogi dla zadanego dystansu w zależności od biomu.
  static double roadCenterX(Iconic3dSceneryBiome biome, double distanceMeters) {
    switch (biome) {
      case Iconic3dSceneryBiome.greatBeltSeaBridge:
        // Długi łagodny łuk nad cieśniną Wielki Bełt.
        return math.sin(distanceMeters * 0.0022) * 14.0;
      case Iconic3dSceneryBiome.arenbergForestTrench:
        // Ikoniczna, niemal idealnie prosta linia przekopu Arenberg.
        return math.sin(distanceMeters * 0.0012) * 1.1;
      case Iconic3dSceneryBiome.tuscanyChalkHills:
        // Kręte szutrowe serpentyny przez toskańskie wzgórza.
        return math.sin(distanceMeters * 0.011) * 18.0 +
            math.cos(distanceMeters * 0.0045) * 9.0;
      case Iconic3dSceneryBiome.montVentouxLunarSummit:
        // Szerokie łuki podjazdu pod wieżę na szczycie.
        return math.sin(distanceMeters * 0.0075) * 15.0;
    }
  }

  /// Wylicza wysokość nawierzchni Y [m] w zależności od biomu i dystansu.
  static double roadElevationY(
    Iconic3dSceneryBiome biome,
    double distanceMeters,
  ) {
    switch (biome) {
      case Iconic3dSceneryBiome.greatBeltSeaBridge:
        // Wznosząca się krzywizna przęsła mostu (65 m nad taflą morza).
        return 65.0 + math.sin(distanceMeters * 0.004) * 3.8;
      case Iconic3dSceneryBiome.arenbergForestTrench:
        // Lekkie zapadlisko przekopu z minimalnym pofalowaniem.
        return 25.0 + math.sin(distanceMeters * 0.015) * 0.45;
      case Iconic3dSceneryBiome.tuscanyChalkHills:
        // Dynamiczne góra-dół po kredowych pagórkach.
        return 340.0 +
            math.sin(distanceMeters * 0.014) * 7.5 +
            math.cos(distanceMeters * 0.006) * 4.0;
      case Iconic3dSceneryBiome.montVentouxLunarSummit:
        // Stała wspinaczka ~8.8% na księżycowej pustyni.
        return 1720.0 + distanceMeters * 0.088;
    }
  }

  /// Rzutuje punkt świata 3D na współrzędne ekranu 2D przy użyciu macierzy widoku
  /// i projekcji perspektywicznej.
  static Offset? projectWorldToScreen({
    required Vector3 worldPoint,
    required Vector3 cameraPos,
    required double fovDegrees,
    required Size viewportSize,
    double pitchBiasRad = -0.055,
  }) {
    final double dx = worldPoint.x - cameraPos.x;
    final double dy = worldPoint.y - cameraPos.y;
    final double dz = worldPoint.z - cameraPos.z;

    if (dz <= 1.2) {
      return null;
    }

    // Lekkie pochylenie kamery w dół na nawierzchnię drogi.
    final double cosP = math.cos(pitchBiasRad);
    final double sinP = math.sin(pitchBiasRad);
    final double rotY = dy * cosP - dz * sinP;
    final double rotZ = dy * sinP + dz * cosP;

    if (rotZ <= 1.0) {
      return null;
    }

    final double fovRad = fovDegrees * math.pi / 180.0;
    final double focalLength =
        (viewportSize.height * 0.5) / math.tan(fovRad * 0.5);

    final double screenX = viewportSize.width * 0.5 + (dx / rotZ) * focalLength;
    final double screenY =
        viewportSize.height * 0.48 - (rotY / rotZ) * focalLength;

    return Offset(screenX, screenY);
  }

  /// Skala obiektu w pikselach na ekranie przy danej odległości Z.
  static double projectMetersToPixels({
    required double meters,
    required double depthZ,
    required double fovDegrees,
    required Size viewportSize,
  }) {
    if (depthZ <= 0.5) return 0.0;
    final double fovRad = fovDegrees * math.pi / 180.0;
    final double focalLength =
        (viewportSize.height * 0.5) / math.tan(fovRad * 0.5);
    return (meters / depthZ) * focalLength;
  }

  double _computeEffectiveWind({
    required Iconic3dSceneryBiome biome,
    required double windScale,
    required double elapsedSeconds,
  }) {
    final double gustWave =
        1.0 +
        0.18 * math.sin(elapsedSeconds * 1.15) +
        0.09 * math.cos(elapsedSeconds * 2.7);
    return (biome.defaultCrosswindMps * windScale * gustWave).clamp(0.0, 32.0);
  }

  double _computeCameraVibrationPx({
    required CoastalBridgesAndCobbleConfig config,
    required double elapsedSeconds,
    required double effectiveWind,
  }) {
    if (!config.enableSurfaceVibration) {
      return 0.0;
    }
    switch (config.biome) {
      case Iconic3dSceneryBiome.arenbergForestTrench:
        // Wyraźne drgania 24 Hz na 5★ bruku.
        return math.sin(elapsedSeconds * 48.0) * 2.2 +
            math.cos(elapsedSeconds * 31.0) * 1.1;
      case Iconic3dSceneryBiome.tuscanyChalkHills:
        return math.sin(elapsedSeconds * 28.0) * 0.9;
      case Iconic3dSceneryBiome.greatBeltSeaBridge:
        // Delikatne kołysanie podmuchów wiatru bocznego.
        return math.sin(elapsedSeconds * 3.5) * (effectiveWind * 0.08);
      case Iconic3dSceneryBiome.montVentouxLunarSummit:
        return math.sin(elapsedSeconds * 4.2) * (effectiveWind * 0.06);
    }
  }

  List<RoadRibbonSlice3D> _buildRoadSlices({
    required Iconic3dSceneryBiome biome,
    required double startDist,
    required double endDist,
  }) {
    const double stepMeters = 6.0;
    final double alignedStart = (startDist / stepMeters).floor() * stepMeters;
    final List<RoadRibbonSlice3D> slices = <RoadRibbonSlice3D>[];

    for (double d = alignedStart; d <= endDist; d += stepMeters) {
      final double cx = roadCenterX(biome, d);
      final double cy = roadElevationY(biome, d);
      final double nextCy = roadElevationY(biome, d + stepMeters);
      final double slope = math.atan2(nextCy - cy, stepMeters);
      final bool isJoint =
          biome == Iconic3dSceneryBiome.greatBeltSeaBridge &&
          (d.round() % 36 == 0);

      slices.add(
        RoadRibbonSlice3D(
          distanceMeters: d,
          centerX: cx,
          centerY: cy,
          halfWidthMeters: biome.roadWidthMeters * 0.5,
          slopeRadians: slope,
          hasExpansionJoint: isJoint,
          cobbleRowSeed: (d / stepMeters).round(),
        ),
      );
    }
    return slices;
  }

  List<SceneryProp3D> _generateBiomeProps({
    required Iconic3dSceneryBiome biome,
    required double startDist,
    required double endDist,
    required int seed,
  }) {
    final List<SceneryProp3D> props = <SceneryProp3D>[];

    switch (biome) {
      case Iconic3dSceneryBiome.greatBeltSeaBridge:
        // Pylony co 180 m, wieszaki linowe co 18 m, statki na horyzoncie co 140 m.
        const double pylonStep = 180.0;
        final double firstPylon =
            (startDist / pylonStep).floor() * pylonStep + 90.0;
        for (double d = firstPylon; d <= endDist; d += pylonStep) {
          props.add(
            SceneryProp3D(
              id: 'gb_pylon_${d.round()}',
              kind: SceneryPropKind.bridgePylon,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: 0.0,
              widthMeters: 13.5,
              heightMeters: 52.0,
              depthMeters: 3.5,
              primaryColor: const Color(0xFFD1D5DB),
              secondaryColor: const Color(0xFF9CA3AF),
            ),
          );
        }

        const double hangerStep = 18.0;
        final double firstHanger =
            (startDist / hangerStep).floor() * hangerStep;
        for (double d = firstHanger; d <= endDist; d += hangerStep) {
          final double localPhase = ((d % 180.0) / 180.0 - 0.5).abs();
          final double cableHeight = 7.5 + localPhase * localPhase * 120.0;
          props.add(
            SceneryProp3D(
              id: 'gb_hang_l_${d.round()}',
              kind: SceneryPropKind.bridgeSuspender,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: -5.4,
              widthMeters: 0.18,
              heightMeters: cableHeight,
              primaryColor: const Color(0xFFE5E7EB),
              secondaryColor: const Color(0xFF6B7280),
            ),
          );
          props.add(
            SceneryProp3D(
              id: 'gb_hang_r_${d.round()}',
              kind: SceneryPropKind.bridgeSuspender,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: 5.4,
              widthMeters: 0.18,
              heightMeters: cableHeight,
              primaryColor: const Color(0xFFE5E7EB),
              secondaryColor: const Color(0xFF6B7280),
            ),
          );
        }

        const double shipStep = 145.0;
        final double firstShip = (startDist / shipStep).floor() * shipStep + 60;
        for (double d = firstShip; d <= endDist; d += shipStep) {
          final bool onLeft = ((d / shipStep).round() + seed) % 2 == 0;
          props.add(
            SceneryProp3D(
              id: 'gb_ship_${d.round()}',
              kind: SceneryPropKind.seaVessel,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: onLeft ? -46.0 : 48.0,
              elevationOffsetMeters: -38.0,
              widthMeters: 16.0,
              heightMeters: 7.5,
              primaryColor: const Color(0xFF8E4A49),
              secondaryColor: const Color(0xFFF3F4F6),
            ),
          );
        }
        break;

      case Iconic3dSceneryBiome.arenbergForestTrench:
        // Gęste drzewa bukowe po obu stronach przekopu co 11 m + barierki co 14 m.
        const double treeStep = 11.0;
        final double firstTree = (startDist / treeStep).floor() * treeStep;
        for (double d = firstTree; d <= endDist; d += treeStep) {
          final int h = ((d / treeStep).round() * 31 + seed) & 0xFF;
          final double heightL = 13.0 + (h % 6) * 0.9;
          final double heightR = 12.5 + ((h >> 2) % 6) * 0.9;
          props.add(
            SceneryProp3D(
              id: 'ar_tree_l_${d.round()}',
              kind: SceneryPropKind.trenchCanopyTree,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: -4.8 - (h % 3) * 0.45,
              elevationOffsetMeters: 0.6,
              widthMeters: 6.8,
              heightMeters: heightL,
              primaryColor: const Color(0xFF28462B),
              secondaryColor: const Color(0xFF3E3124),
              swayPhaseRad: d * 0.08,
            ),
          );
          props.add(
            SceneryProp3D(
              id: 'ar_tree_r_${d.round()}',
              kind: SceneryPropKind.trenchCanopyTree,
              distanceAlongCourseMeters: d + 3.0,
              lateralOffsetMeters: 4.8 + ((h >> 1) % 3) * 0.45,
              elevationOffsetMeters: 0.6,
              widthMeters: 6.8,
              heightMeters: heightR,
              primaryColor: const Color(0xFF213D24),
              secondaryColor: const Color(0xFF3B2D20),
              swayPhaseRad: d * 0.09 + 1.2,
            ),
          );
        }

        const double barrierStep = 14.0;
        final double firstBarrier =
            (startDist / barrierStep).floor() * barrierStep;
        for (double d = firstBarrier; d <= endDist; d += barrierStep) {
          props.add(
            SceneryProp3D(
              id: 'ar_bar_l_${d.round()}',
              kind: SceneryPropKind.trenchSpectatorBarrier,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: -3.2,
              widthMeters: 0.45,
              heightMeters: 1.25,
              primaryColor: const Color(0xFFD4AF37),
              secondaryColor: const Color(0xFF1F2937),
            ),
          );
          props.add(
            SceneryProp3D(
              id: 'ar_bar_r_${d.round()}',
              kind: SceneryPropKind.trenchSpectatorBarrier,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: 3.2,
              widthMeters: 0.45,
              heightMeters: 1.25,
              primaryColor: const Color(0xFF8E4A49),
              secondaryColor: const Color(0xFF1F2937),
            ),
          );
        }
        break;

      case Iconic3dSceneryBiome.tuscanyChalkHills:
        // Aleje cyprysów, kredowe wychodnie skalne i wille na wzgórzach.
        const double cypressStep = 18.0;
        final double firstCypress =
            (startDist / cypressStep).floor() * cypressStep;
        for (double d = firstCypress; d <= endDist; d += cypressStep) {
          final int h = ((d / cypressStep).round() * 19 + seed) & 0xFF;
          final bool bothSides = h % 3 == 0;
          final double sideSign = (h % 2 == 0) ? -1.0 : 1.0;

          props.add(
            SceneryProp3D(
              id: 'tc_cyp_a_${d.round()}',
              kind: SceneryPropKind.tuscanCypress,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: sideSign * (5.2 + (h % 4) * 1.1),
              widthMeters: 2.1,
              heightMeters: 11.0 + (h % 4) * 1.3,
              primaryColor: const Color(0xFF2B4229),
              secondaryColor: const Color(0xFF473729),
              swayPhaseRad: d * 0.05,
            ),
          );
          if (bothSides) {
            props.add(
              SceneryProp3D(
                id: 'tc_cyp_b_${d.round()}',
                kind: SceneryPropKind.tuscanCypress,
                distanceAlongCourseMeters: d + 4.0,
                lateralOffsetMeters: -sideSign * (6.0 + (h % 3) * 0.9),
                widthMeters: 2.0,
                heightMeters: 10.5 + (h % 3) * 1.2,
                primaryColor: const Color(0xFF314B2E),
                secondaryColor: const Color(0xFF473729),
                swayPhaseRad: d * 0.06 + 0.9,
              ),
            );
          }
        }

        const double chalkStep = 34.0;
        final double firstChalk = (startDist / chalkStep).floor() * chalkStep;
        for (double d = firstChalk; d <= endDist; d += chalkStep) {
          final int h = ((d / chalkStep).round() * 41 + seed) & 0xFF;
          props.add(
            SceneryProp3D(
              id: 'tc_chalk_${d.round()}',
              kind: SceneryPropKind.tuscanChalkOutcrop,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: (h % 2 == 0 ? -1.0 : 1.0) * (12.0 + h % 8),
              elevationOffsetMeters: 1.5,
              widthMeters: 14.0,
              heightMeters: 6.0 + (h % 4) * 1.6,
              primaryColor: const Color(0xFFE5DFCE),
              secondaryColor: const Color(0xFFB9AE92),
            ),
          );
        }

        const double villaStep = 140.0;
        final double firstVilla =
            (startDist / villaStep).floor() * villaStep + 50.0;
        for (double d = firstVilla; d <= endDist; d += villaStep) {
          final bool onLeft = ((d / villaStep).round() + seed) % 2 == 0;
          props.add(
            SceneryProp3D(
              id: 'tc_villa_${d.round()}',
              kind: SceneryPropKind.tuscanFarmhouse,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: onLeft ? -28.0 : 28.0,
              elevationOffsetMeters: 4.5,
              widthMeters: 12.0,
              heightMeters: 7.2,
              primaryColor: const Color(0xFFD6B98C),
              secondaryColor: const Color(0xFF8E4A49),
            ),
          );
        }
        break;

      case Iconic3dSceneryBiome.montVentouxLunarSummit:
        // Słupki śniegowe co 24 m, białe głazy wapienne co 16 m, pomnik i wieża.
        const double poleStep = 24.0;
        final double firstPole = (startDist / poleStep).floor() * poleStep;
        for (double d = firstPole; d <= endDist; d += poleStep) {
          props.add(
            SceneryProp3D(
              id: 'mv_pole_l_${d.round()}',
              kind: SceneryPropKind.ventouxSnowPole,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: -3.7,
              widthMeters: 0.16,
              heightMeters: 2.3,
              primaryColor: const Color(0xFFF3F4F6),
              secondaryColor: const Color(0xFFEF4444),
            ),
          );
          props.add(
            SceneryProp3D(
              id: 'mv_pole_r_${d.round()}',
              kind: SceneryPropKind.ventouxSnowPole,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: 3.7,
              widthMeters: 0.16,
              heightMeters: 2.3,
              primaryColor: const Color(0xFFF3F4F6),
              secondaryColor: const Color(0xFFEF4444),
            ),
          );
        }

        const double boulderStep = 16.0;
        final double firstBoulder =
            (startDist / boulderStep).floor() * boulderStep;
        for (double d = firstBoulder; d <= endDist; d += boulderStep) {
          final int h = ((d / boulderStep).round() * 29 + seed) & 0xFF;
          final double side = (h % 2 == 0) ? -1.0 : 1.0;
          props.add(
            SceneryProp3D(
              id: 'mv_rock_${d.round()}',
              kind: SceneryPropKind.ventouxLimestoneBoulder,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: side * (6.2 + (h % 11) * 1.4),
              widthMeters: 2.8 + (h % 4) * 1.1,
              heightMeters: 1.5 + (h % 3) * 0.85,
              primaryColor: const Color(0xFFDCE0E5),
              secondaryColor: const Color(0xFF9CA3AF),
            ),
          );
        }

        // Pomnik Toma Simpsona po prawej stronie co 220 m w pętli podjazdu.
        const double steleStep = 220.0;
        final double firstStele =
            (startDist / steleStep).floor() * steleStep + 65.0;
        for (double d = firstStele; d <= endDist; d += steleStep) {
          props.add(
            SceneryProp3D(
              id: 'mv_stele_${d.round()}',
              kind: SceneryPropKind.ventouxMemorialStele,
              distanceAlongCourseMeters: d,
              lateralOffsetMeters: 5.0,
              widthMeters: 1.6,
              heightMeters: 2.6,
              primaryColor: const Color(0xFF9CA3AF),
              secondaryColor: const Color(0xFFD4AF37),
            ),
          );
        }

        // Ikoniczna wieża obserwatorium zawsze widoczna w oddali na grani.
        final double towerDist = endDist - 45.0;
        props.add(
          SceneryProp3D(
            id: 'mv_summit_tower',
            kind: SceneryPropKind.ventouxSummitTower,
            distanceAlongCourseMeters: towerDist,
            lateralOffsetMeters: -8.0,
            elevationOffsetMeters: 5.5,
            widthMeters: 11.0,
            heightMeters: 44.0,
            primaryColor: const Color(0xFFF3F4F6),
            secondaryColor: const Color(0xFFEF4444),
          ),
        );
        break;
    }

    return props;
  }

  List<AtmosphericParticle3D> _generateParticles({
    required Iconic3dSceneryBiome biome,
    required double cameraDistanceMeters,
    required double forwardVisibilityMeters,
    required double elapsedSeconds,
    required double effectiveWind,
  }) {
    const int count = 28;
    final List<AtmosphericParticle3D> particles = <AtmosphericParticle3D>[];

    Color color;
    switch (biome) {
      case Iconic3dSceneryBiome.greatBeltSeaBridge:
        color = const Color(0xFFE0F2FE);
        break;
      case Iconic3dSceneryBiome.arenbergForestTrench:
        color = const Color(0xFFA7F3D0);
        break;
      case Iconic3dSceneryBiome.tuscanyChalkHills:
        color = const Color(0xFFF3EFE6);
        break;
      case Iconic3dSceneryBiome.montVentouxLunarSummit:
        color = const Color(0xFFE5E7EB);
        break;
    }

    for (int i = 0; i < count; i++) {
      final double phase = (i * 0.37 + elapsedSeconds * (0.25 + effectiveWind * 0.04)) % 1.0;
      final double dist =
          cameraDistanceMeters + 8.0 + ((i * 11.3) % (forwardVisibilityMeters * 0.55));
      final double lateral =
          math.sin(i * 1.9 + elapsedSeconds * 1.3) * 6.5 + (phase - 0.5) * 8.0;
      final double height = 0.4 + ((i * 0.43 + elapsedSeconds * 0.2) % 3.2);

      particles.add(
        AtmosphericParticle3D(
          distanceMeters: dist,
          lateralOffsetMeters: lateral,
          heightMeters: height,
          radiusPx: biome == Iconic3dSceneryBiome.tuscanyChalkHills ? 3.2 : 2.1,
          opacity: 0.28 + (i % 4) * 0.11,
          color: color,
        ),
      );
    }

    return particles;
  }

  List<SceneryPelotonRiderMarker3D> _generatePelotonMarkers({
    required Iconic3dSceneryBiome biome,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    final List<SceneryPelotonRiderMarker3D> riders =
        <SceneryPelotonRiderMarker3D>[];
    final double maxHalfWidth = biome.roadWidthMeters * 0.36;

    for (int i = 0; i < 9; i++) {
      final double baseDist = cameraDistanceMeters + 14.0 + i * 7.2;
      final double latWave =
          math.sin(i * 1.7 + elapsedSeconds * 0.45) * maxHalfWidth;
      riders.add(
        SceneryPelotonRiderMarker3D(
          riderIndex: i,
          distanceMeters: baseDist,
          lateralOffsetMeters: latWave,
          jerseyColor: _pelotonJerseys[i % _pelotonJerseys.length],
          helmetColor: i == 0 ? AppColors.goldAccent : AppColors.textPrimary,
          cadencePhase: elapsedSeconds * 8.5 + i * 0.8,
        ),
      );
    }
    return riders;
  }
}

// =============================================================================
// 4. RENDERER CANVAS (CUSTOMPAINTER) DLA 4 BIOMÓW SCENERII 3D
// =============================================================================

/// Rysuje pełną scenę 3D w wybranym biomie z zachowaniem głębi, perspektywy i detali.
class CoastalBridgesAndCobbleTrenchesPainter extends CustomPainter {
  final Scenery3dFrameState frame;
  final CoastalBridgesAndCobbleConfig config;

  const CoastalBridgesAndCobbleTrenchesPainter({
    required this.frame,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Iconic3dSceneryBiome biome = frame.biome;
    final double camDist = frame.cameraDistanceMeters;
    final double camX =
        CoastalBridgesAndCobbleTrenchesEngine.roadCenterX(biome, camDist);
    final double camY =
        CoastalBridgesAndCobbleTrenchesEngine.roadElevationY(biome, camDist) +
        config.cameraHeightMeters;
    final Vector3 cameraPos = Vector3(camX, camY, camDist);

    canvas.save();
    canvas.translate(0.0, frame.cameraVibrationOffsetPx);

    // 1. Niebo i horyzont.
    _paintSkyAndHorizon(canvas, size, biome);

    // 2. Tło dalekiego planu (morze z falami / las / wzgórza Toskanii / piargi Ventoux).
    _paintBiomeBackdrop(canvas, size, biome);

    // 3. Wstęga drogi 3D (asfalt mostu, bruk Arenberg, biały szuter sterrato, asfalt Ventoux).
    _paintRoadRibbon(canvas, size, cameraPos, biome);

    // 4. Liny nośne mostu Wielki Bełt (jeśli aktywny).
    if (biome == Iconic3dSceneryBiome.greatBeltSeaBridge) {
      _paintGreatBeltMainCables(canvas, size, cameraPos);
    }

    // 5. Sklepienie gałęzi nad przekopem Arenberg.
    if (biome == Iconic3dSceneryBiome.arenbergForestTrench) {
      _paintArenbergCanopyLightShafts(canvas, size);
    }

    // 6. Obiekty 3D posortowane od najdalszych do najbliższych.
    for (final SceneryProp3D prop in frame.visibleProps) {
      _paintProp3D(canvas, size, cameraPos, prop, biome);
    }

    // 7. Kolarze na trasie dla skali głębi.
    for (int i = frame.pelotonMarkers.length - 1; i >= 0; i--) {
      _paintRiderMarker(canvas, size, cameraPos, frame.pelotonMarkers[i], biome);
    }

    // 8. Cząsteczki atmosferyczne (bryza, pył kredowy, liście).
    _paintParticles(canvas, size, cameraPos);

    canvas.restore();
  }

  void _paintSkyAndHorizon(
    Canvas canvas,
    Size size,
    Iconic3dSceneryBiome biome,
  ) {
    final Rect skyRect = Rect.fromLTWH(0, -10, size.width, size.height * 0.54);
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[biome.skyTopColor, biome.skyHorizonColor],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);
  }

  void _paintBiomeBackdrop(
    Canvas canvas,
    Size size,
    Iconic3dSceneryBiome biome,
  ) {
    final double horizonY = size.height * 0.45;
    final Rect groundRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      size.height - horizonY + 12,
    );

    switch (biome) {
      case Iconic3dSceneryBiome.greatBeltSeaBridge:
        final Paint seaPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF1A4B6E), Color(0xFF0B2236)],
          ).createShader(groundRect);
        canvas.drawRect(groundRect, seaPaint);

        // Animowane grzbiety fal morskich.
        final Paint wavePaint = Paint()
          ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.22)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;
        for (int row = 0; row < 12; row++) {
          final double y = horizonY + 8 + row * (size.height * 0.042);
          final Path wavePath = Path();
          for (double x = 0; x <= size.width; x += 28) {
            final double dy = math.sin(
                  x * 0.03 + frame.elapsedSeconds * 2.2 + row,
                ) *
                (1.2 + row * 0.15);
            if (x == 0) {
              wavePath.moveTo(x, y + dy);
            } else {
              wavePath.lineTo(x, y + dy);
            }
          }
          canvas.drawPath(wavePath, wavePaint);
        }
        break;

      case Iconic3dSceneryBiome.arenbergForestTrench:
        final Paint forestFloor = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF1B2E1E), Color(0xFF101C12)],
          ).createShader(groundRect);
        canvas.drawRect(groundRect, forestFloor);
        break;

      case Iconic3dSceneryBiome.tuscanyChalkHills:
        // Warstwowe kredowe wzgórza Crete Senesi.
        final Paint backHillPaint = Paint()..color = const Color(0xFF9C9166);
        final Path backHill = Path()..moveTo(0, horizonY + 15);
        for (double x = 0; x <= size.width; x += 24) {
          final double hillY =
              horizonY - 22 + math.sin(x * 0.008 + 0.7) * 26.0;
          backHill.lineTo(x, hillY);
        }
        backHill
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(backHill, backHillPaint);

        final Paint frontGroundPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF8C7E4E), Color(0xFF5D5333)],
          ).createShader(groundRect);
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            horizonY + 18,
            size.width,
            size.height - horizonY,
          ),
          frontGroundPaint,
        );
        break;

      case Iconic3dSceneryBiome.montVentouxLunarSummit:
        // Księżycowy grzbiet wapienny Mont Ventoux.
        final Paint ridgePaint = Paint()..color = const Color(0xFFD6DADF);
        final Path ridgePath = Path()..moveTo(0, horizonY + 12);
        for (double x = 0; x <= size.width; x += 20) {
          final double y =
              horizonY -
              18 +
              math.sin(x * 0.007) * 18.0 +
              math.cos(x * 0.019) * 6.0;
          ridgePath.lineTo(x, y);
        }
        ridgePath
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(ridgePath, ridgePaint);

        final Paint screePaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFC5C9CE), Color(0xFF8F959E)],
          ).createShader(groundRect);
        canvas.drawRect(
          Rect.fromLTWH(0, horizonY + 10, size.width, size.height - horizonY),
          screePaint,
        );
        break;
    }
  }

  void _paintRoadRibbon(
    Canvas canvas,
    Size size,
    Vector3 cameraPos,
    Iconic3dSceneryBiome biome,
  ) {
    final List<RoadRibbonSlice3D> slices = frame.roadSlices;
    if (slices.length < 2) return;

    final Paint roadPaint = Paint()..style = PaintingStyle.fill;
    final Paint shoulderPaint = Paint()
      ..color = biome.roadEdgeColor
      ..style = PaintingStyle.fill;
    final Paint linePaint = Paint()
      ..color = const Color(0xFFF3F4F6).withValues(alpha: 0.78)
      ..strokeWidth = 1.6;
    final Paint cobbleStrokePaint = Paint()
      ..color = const Color(0xFF2B2D32).withValues(alpha: 0.65)
      ..strokeWidth = 1.1;

    for (int i = slices.length - 2; i >= 0; i--) {
      final RoadRibbonSlice3D farSlice = slices[i + 1];
      final RoadRibbonSlice3D nearSlice = slices[i];

      final Offset? fl = CoastalBridgesAndCobbleTrenchesEngine
          .projectWorldToScreen(
            worldPoint: Vector3(
              farSlice.centerX - farSlice.halfWidthMeters,
              farSlice.centerY,
              farSlice.distanceMeters,
            ),
            cameraPos: cameraPos,
            fovDegrees: config.cameraFovDegrees,
            viewportSize: size,
          );
      final Offset? fr = CoastalBridgesAndCobbleTrenchesEngine
          .projectWorldToScreen(
            worldPoint: Vector3(
              farSlice.centerX + farSlice.halfWidthMeters,
              farSlice.centerY,
              farSlice.distanceMeters,
            ),
            cameraPos: cameraPos,
            fovDegrees: config.cameraFovDegrees,
            viewportSize: size,
          );
      final Offset? nr = CoastalBridgesAndCobbleTrenchesEngine
          .projectWorldToScreen(
            worldPoint: Vector3(
              nearSlice.centerX + nearSlice.halfWidthMeters,
              nearSlice.centerY,
              nearSlice.distanceMeters,
            ),
            cameraPos: cameraPos,
            fovDegrees: config.cameraFovDegrees,
            viewportSize: size,
          );
      final Offset? nl = CoastalBridgesAndCobbleTrenchesEngine
          .projectWorldToScreen(
            worldPoint: Vector3(
              nearSlice.centerX - nearSlice.halfWidthMeters,
              nearSlice.centerY,
              nearSlice.distanceMeters,
            ),
            cameraPos: cameraPos,
            fovDegrees: config.cameraFovDegrees,
            viewportSize: size,
          );

      if (fl == null || fr == null || nr == null || nl == null) continue;

      // Pobocze / krawężnik drogi.
      final double nearPad = (nr.dx - nl.dx) * 0.08;
      final double farPad = (fr.dx - fl.dx) * 0.08;
      final Path shoulderPath = Path()
        ..moveTo(fl.dx - farPad, fl.dy)
        ..lineTo(fr.dx + farPad, fr.dy)
        ..lineTo(nr.dx + nearPad, nr.dy)
        ..lineTo(nl.dx - nearPad, nl.dy)
        ..close();
      canvas.drawPath(shoulderPath, shoulderPaint);

      // Główna nawierzchnia drogi.
      final bool altTone = nearSlice.cobbleRowSeed % 2 == 0;
      roadPaint.color = altTone
          ? biome.roadSurfaceColor
          : Color.lerp(biome.roadSurfaceColor, Colors.black, 0.06)!;

      final Path roadPath = Path()
        ..moveTo(fl.dx, fl.dy)
        ..lineTo(fr.dx, fr.dy)
        ..lineTo(nr.dx, nr.dy)
        ..lineTo(nl.dx, nl.dy)
        ..close();
      canvas.drawPath(roadPath, roadPaint);

      // Detale nawierzchni specyficzne dla biomu.
      if (biome == Iconic3dSceneryBiome.greatBeltSeaBridge) {
        final Offset midFar = Offset((fl.dx + fr.dx) * 0.5, (fl.dy + fr.dy) * 0.5);
        final Offset midNear = Offset((nl.dx + nr.dx) * 0.5, (nl.dy + nr.dy) * 0.5);
        if (nearSlice.cobbleRowSeed % 2 == 0) {
          canvas.drawLine(midFar, midNear, linePaint);
        }
        if (nearSlice.hasExpansionJoint) {
          canvas.drawLine(
            nl,
            nr,
            Paint()
              ..color = const Color(0xFF111827)
              ..strokeWidth = 2.0,
          );
        }
      } else if (biome == Iconic3dSceneryBiome.arenbergForestTrench) {
        // Siatka kostki brukowej na przekopie Arenberg.
        canvas.drawLine(nl, nr, cobbleStrokePaint);
        for (int c = 1; c <= 4; c++) {
          final double t = c / 5.0;
          final Offset topStone = Offset.lerp(fl, fr, t)!;
          final Offset botStone = Offset.lerp(nl, nr, t)!;
          canvas.drawLine(topStone, botStone, cobbleStrokePaint);
        }
      } else if (biome == Iconic3dSceneryBiome.tuscanyChalkHills) {
        // Koleiny kół na białym szutrze sterrato.
        final Paint rutPaint = Paint()
          ..color = const Color(0xFFB5A888).withValues(alpha: 0.45)
          ..strokeWidth = 2.2;
        canvas.drawLine(
          Offset.lerp(fl, fr, 0.32)!,
          Offset.lerp(nl, nr, 0.32)!,
          rutPaint,
        );
        canvas.drawLine(
          Offset.lerp(fl, fr, 0.68)!,
          Offset.lerp(nl, nr, 0.68)!,
          rutPaint,
        );
      } else if (biome == Iconic3dSceneryBiome.montVentouxLunarSummit) {
        // Białe linie boczne na podjeździe pod Mont Ventoux.
        canvas.drawLine(fl, nl, linePaint);
        canvas.drawLine(fr, nr, linePaint);
      }
    }
  }

  void _paintGreatBeltMainCables(
    Canvas canvas,
    Size size,
    Vector3 cameraPos,
  ) {
    final Paint cablePaint = Paint()
      ..color = const Color(0xFFE5E7EB).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final double sideX in <double>[-5.4, 5.4]) {
      final Path cablePath = Path();
      bool started = false;
      for (int i = 0; i < frame.roadSlices.length; i++) {
        final RoadRibbonSlice3D slice = frame.roadSlices[i];
        final double d = slice.distanceMeters;
        final double localPhase = ((d % 180.0) / 180.0 - 0.5).abs();
        final double cableY = slice.centerY + 7.5 + localPhase * localPhase * 120.0;
        final Offset? pt = CoastalBridgesAndCobbleTrenchesEngine
            .projectWorldToScreen(
              worldPoint: Vector3(slice.centerX + sideX, cableY, d),
              cameraPos: cameraPos,
              fovDegrees: config.cameraFovDegrees,
              viewportSize: size,
            );
        if (pt == null) continue;
        if (!started) {
          cablePath.moveTo(pt.dx, pt.dy);
          started = true;
        } else {
          cablePath.lineTo(pt.dx, pt.dy);
        }
      }
      if (started) {
        canvas.drawPath(cablePath, cablePaint);
      }
    }
  }

  void _paintArenbergCanopyLightShafts(Canvas canvas, Size size) {
    // Prześwity promieni słonecznych w gęstym przekopie leśnym.
    final Paint shaftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFFD9F99D).withValues(alpha: 0.12),
          const Color(0xFFD9F99D).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < 3; i++) {
      final double baseX =
          size.width * (0.28 + i * 0.22) +
          math.sin(frame.elapsedSeconds * 0.4 + i) * 12.0;
      final Path beam = Path()
        ..moveTo(baseX - 18, 0)
        ..lineTo(baseX + 18, 0)
        ..lineTo(baseX + 75, size.height * 0.85)
        ..lineTo(baseX - 55, size.height * 0.85)
        ..close();
      canvas.drawPath(beam, shaftPaint);
    }
  }

  void _paintProp3D(
    Canvas canvas,
    Size size,
    Vector3 cameraPos,
    SceneryProp3D prop,
    Iconic3dSceneryBiome biome,
  ) {
    final double d = prop.distanceAlongCourseMeters;
    final double depthZ = d - cameraPos.z;
    if (depthZ <= 1.2) return;

    final double roadX = CoastalBridgesAndCobbleTrenchesEngine.roadCenterX(
      biome,
      d,
    );
    final double roadY = CoastalBridgesAndCobbleTrenchesEngine.roadElevationY(
      biome,
      d,
    );

    final Offset? basePos = CoastalBridgesAndCobbleTrenchesEngine
        .projectWorldToScreen(
          worldPoint: Vector3(
            roadX + prop.lateralOffsetMeters,
            roadY + prop.elevationOffsetMeters,
            d,
          ),
          cameraPos: cameraPos,
          fovDegrees: config.cameraFovDegrees,
          viewportSize: size,
        );
    if (basePos == null) return;

    final double pxW = CoastalBridgesAndCobbleTrenchesEngine
        .projectMetersToPixels(
          meters: prop.widthMeters,
          depthZ: depthZ,
          fovDegrees: config.cameraFovDegrees,
          viewportSize: size,
        );
    final double pxH = CoastalBridgesAndCobbleTrenchesEngine
        .projectMetersToPixels(
          meters: prop.heightMeters,
          depthZ: depthZ,
          fovDegrees: config.cameraFovDegrees,
          viewportSize: size,
        );

    switch (prop.kind) {
      case SceneryPropKind.bridgePylon:
        // Dwie potężne wieże H-pylonu mostu Wielki Bełt z poprzeczkami.
        final double legW = math.max(2.5, pxW * 0.12);
        final double halfSpan = pxW * 0.44;
        final Paint pylonPaint = Paint()..color = prop.primaryColor;
        final Paint crossPaint = Paint()..color = prop.secondaryColor;

        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - halfSpan - legW * 0.5,
            basePos.dy - pxH,
            legW,
            pxH * 1.35,
          ),
          pylonPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx + halfSpan - legW * 0.5,
            basePos.dy - pxH,
            legW,
            pxH * 1.35,
          ),
          pylonPaint,
        );
        // Górna i środkowa poprzeczka pylonu.
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - halfSpan,
            basePos.dy - pxH * 0.92,
            halfSpan * 2,
            legW * 1.4,
          ),
          crossPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - halfSpan,
            basePos.dy - pxH * 0.54,
            halfSpan * 2,
            legW * 1.2,
          ),
          crossPaint,
        );
        break;

      case SceneryPropKind.bridgeSuspender:
        canvas.drawLine(
          basePos,
          Offset(basePos.dx, basePos.dy - pxH),
          Paint()
            ..color = prop.primaryColor.withValues(alpha: 0.72)
            ..strokeWidth = math.max(0.8, pxW),
        );
        break;

      case SceneryPropKind.seaVessel:
        // Sylwetka statku handlowego / promu pod mostem.
        final Rect hull = Rect.fromCenter(
          center: Offset(basePos.dx, basePos.dy - pxH * 0.3),
          width: math.max(8.0, pxW),
          height: math.max(3.0, pxH * 0.45),
        );
        canvas.drawRect(hull, Paint()..color = prop.primaryColor);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(basePos.dx, hull.top - pxH * 0.22),
            width: math.max(4.0, pxW * 0.48),
            height: math.max(2.0, pxH * 0.35),
          ),
          Paint()..color = prop.secondaryColor,
        );
        break;

      case SceneryPropKind.trenchCanopyTree:
        final double sway = math.sin(frame.elapsedSeconds * 1.5 + prop.swayPhaseRad) * 2.5;
        final double trunkW = math.max(2.0, pxW * 0.11);
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - trunkW * 0.5,
            basePos.dy - pxH * 0.68,
            trunkW,
            pxH * 0.68,
          ),
          Paint()..color = prop.secondaryColor,
        );
        canvas.drawCircle(
          Offset(basePos.dx + sway, basePos.dy - pxH * 0.78),
          math.max(6.0, pxW * 0.46),
          Paint()..color = prop.primaryColor,
        );
        break;

      case SceneryPropKind.trenchSpectatorBarrier:
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - pxW * 0.5,
            basePos.dy - pxH,
            math.max(2.0, pxW),
            pxH,
          ),
          Paint()..color = prop.primaryColor,
        );
        break;

      case SceneryPropKind.tuscanCypress:
        final double sway = math.sin(frame.elapsedSeconds * 1.4 + prop.swayPhaseRad) * 1.6;
        final Path cypress = Path()
          ..moveTo(basePos.dx + sway, basePos.dy - pxH)
          ..quadraticBezierTo(
            basePos.dx + pxW * 0.65,
            basePos.dy - pxH * 0.35,
            basePos.dx + pxW * 0.35,
            basePos.dy - pxH * 0.12,
          )
          ..lineTo(basePos.dx - pxW * 0.35, basePos.dy - pxH * 0.12)
          ..quadraticBezierTo(
            basePos.dx - pxW * 0.65,
            basePos.dy - pxH * 0.35,
            basePos.dx + sway,
            basePos.dy - pxH,
          )
          ..close();
        canvas.drawPath(cypress, Paint()..color = prop.primaryColor);
        break;

      case SceneryPropKind.tuscanChalkOutcrop:
        final Path chalk = Path()
          ..moveTo(basePos.dx - pxW * 0.55, basePos.dy)
          ..lineTo(basePos.dx - pxW * 0.25, basePos.dy - pxH)
          ..lineTo(basePos.dx + pxW * 0.2, basePos.dy - pxH * 0.78)
          ..lineTo(basePos.dx + pxW * 0.55, basePos.dy)
          ..close();
        canvas.drawPath(chalk, Paint()..color = prop.primaryColor);
        break;

      case SceneryPropKind.tuscanFarmhouse:
        final Rect walls = Rect.fromLTWH(
          basePos.dx - pxW * 0.5,
          basePos.dy - pxH * 0.65,
          pxW,
          pxH * 0.65,
        );
        canvas.drawRect(walls, Paint()..color = prop.primaryColor);
        final Path roof = Path()
          ..moveTo(walls.left - pxW * 0.08, walls.top)
          ..lineTo(basePos.dx, walls.top - pxH * 0.32)
          ..lineTo(walls.right + pxW * 0.08, walls.top)
          ..close();
        canvas.drawPath(roof, Paint()..color = prop.secondaryColor);
        break;

      case SceneryPropKind.ventouxSummitTower:
        // Baza budynku obserwatorium + czerwono-biały maszt na szczycie Mont Ventoux.
        final Rect baseBlock = Rect.fromLTWH(
          basePos.dx - pxW * 0.55,
          basePos.dy - pxH * 0.26,
          pxW * 1.1,
          pxH * 0.26,
        );
        canvas.drawRect(baseBlock, Paint()..color = prop.primaryColor);

        final double mastW = math.max(2.5, pxW * 0.14);
        const int bands = 6;
        final double bandH = (pxH * 0.74) / bands;
        for (int b = 0; b < bands; b++) {
          canvas.drawRect(
            Rect.fromLTWH(
              basePos.dx - mastW * 0.5,
              baseBlock.top - (b + 1) * bandH,
              mastW,
              bandH,
            ),
            Paint()
              ..color = b % 2 == 0 ? prop.secondaryColor : prop.primaryColor,
          );
        }
        break;

      case SceneryPropKind.ventouxMemorialStele:
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - pxW * 0.5,
            basePos.dy - pxH,
            math.max(4.0, pxW),
            pxH,
          ),
          Paint()..color = prop.primaryColor,
        );
        canvas.drawCircle(
          Offset(basePos.dx, basePos.dy - pxH * 0.7),
          math.max(1.5, pxW * 0.18),
          Paint()..color = prop.secondaryColor,
        );
        break;

      case SceneryPropKind.ventouxLimestoneBoulder:
        final Path rock = Path()
          ..moveTo(basePos.dx - pxW * 0.5, basePos.dy)
          ..lineTo(basePos.dx - pxW * 0.22, basePos.dy - pxH)
          ..lineTo(basePos.dx + pxW * 0.35, basePos.dy - pxH * 0.72)
          ..lineTo(basePos.dx + pxW * 0.5, basePos.dy)
          ..close();
        canvas.drawPath(rock, Paint()..color = prop.primaryColor);
        break;

      case SceneryPropKind.ventouxSnowPole:
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - pxW * 0.5,
            basePos.dy - pxH,
            math.max(1.4, pxW),
            pxH,
          ),
          Paint()..color = prop.primaryColor,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            basePos.dx - pxW * 0.5,
            basePos.dy - pxH,
            math.max(1.4, pxW),
            pxH * 0.25,
          ),
          Paint()..color = prop.secondaryColor,
        );
        break;
    }
  }

  void _paintRiderMarker(
    Canvas canvas,
    Size size,
    Vector3 cameraPos,
    SceneryPelotonRiderMarker3D rider,
    Iconic3dSceneryBiome biome,
  ) {
    final double d = rider.distanceMeters;
    final double depthZ = d - cameraPos.z;
    if (depthZ <= 1.2) return;

    final double roadX = CoastalBridgesAndCobbleTrenchesEngine.roadCenterX(
      biome,
      d,
    );
    final double roadY = CoastalBridgesAndCobbleTrenchesEngine.roadElevationY(
      biome,
      d,
    );

    final Offset? base = CoastalBridgesAndCobbleTrenchesEngine
        .projectWorldToScreen(
          worldPoint: Vector3(roadX + rider.lateralOffsetMeters, roadY, d),
          cameraPos: cameraPos,
          fovDegrees: config.cameraFovDegrees,
          viewportSize: size,
        );
    if (base == null) return;

    final double riderH = CoastalBridgesAndCobbleTrenchesEngine
        .projectMetersToPixels(
          meters: 1.55,
          depthZ: depthZ,
          fovDegrees: config.cameraFovDegrees,
          viewportSize: size,
        );
    final double riderW = riderH * 0.42;
    final double bob = math.sin(rider.cadencePhase).abs() * (riderH * 0.04);

    // Cień pod kolarzem.
    canvas.drawOval(
      Rect.fromCenter(
        center: base,
        width: math.max(3.0, riderW * 1.15),
        height: math.max(1.5, riderH * 0.14),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Tułów w koszulce drużynowej.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - riderH * 0.55 - bob),
          width: math.max(2.5, riderW),
          height: math.max(4.0, riderH * 0.48),
        ),
        const Radius.circular(3.0),
      ),
      Paint()..color = rider.jerseyColor,
    );

    // Kask kolarza.
    canvas.drawCircle(
      Offset(base.dx, base.dy - riderH * 0.88 - bob),
      math.max(1.5, riderW * 0.34),
      Paint()..color = rider.helmetColor,
    );
  }

  void _paintParticles(Canvas canvas, Size size, Vector3 cameraPos) {
    final double camDist = frame.cameraDistanceMeters;
    for (final AtmosphericParticle3D p in frame.particles) {
      final double roadX = CoastalBridgesAndCobbleTrenchesEngine.roadCenterX(
        frame.biome,
        p.distanceMeters,
      );
      final double roadY = CoastalBridgesAndCobbleTrenchesEngine.roadElevationY(
        frame.biome,
        p.distanceMeters,
      );
      final Offset? pt = CoastalBridgesAndCobbleTrenchesEngine
          .projectWorldToScreen(
            worldPoint: Vector3(
              roadX + p.lateralOffsetMeters,
              roadY + p.heightMeters,
              p.distanceMeters,
            ),
            cameraPos: cameraPos,
            fovDegrees: config.cameraFovDegrees,
            viewportSize: size,
          );
      if (pt == null || p.distanceMeters <= camDist + 1.0) continue;

      canvas.drawCircle(
        pt,
        p.radiusPx,
        Paint()..color = p.color.withValues(alpha: p.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CoastalBridgesAndCobbleTrenchesPainter oldDelegate,
  ) {
    return oldDelegate.frame != frame || oldDelegate.config != config;
  }
}

// =============================================================================
// 5. WIDŻET PODGLĄDU 3D I PANEL STEROWANIA (RESPONSYWNY + PEŁNE STANY UI)
// =============================================================================

/// Interaktywny panel podglądu 3D ikonicznych scenerii kolarskich:
/// Wielki Bełt, Trouée d'Arenberg, Kredowe Wzgórza Toskanii oraz Mont Ventoux.
class CoastalBridgesAndCobbleTrenchesPanel extends StatefulWidget {
  final Iconic3dSceneryBiome initialBiome;
  final bool autoPlay;
  final ValueChanged<Iconic3dSceneryBiome>? onBiomeChanged;

  const CoastalBridgesAndCobbleTrenchesPanel({
    super.key,
    this.initialBiome = Iconic3dSceneryBiome.greatBeltSeaBridge,
    this.autoPlay = true,
    this.onBiomeChanged,
  });

  @override
  State<CoastalBridgesAndCobbleTrenchesPanel> createState() =>
      _CoastalBridgesAndCobbleTrenchesPanelState();
}

class _CoastalBridgesAndCobbleTrenchesPanelState
    extends State<CoastalBridgesAndCobbleTrenchesPanel>
    with SingleTickerProviderStateMixin {
  final CoastalBridgesAndCobbleTrenchesEngine _engine =
      const CoastalBridgesAndCobbleTrenchesEngine();

  late AnimationController _ticker;
  late CoastalBridgesAndCobbleConfig _config;
  bool _isPlaying = true;
  double _cameraDistanceMeters = 120.0;
  double _elapsedSeconds = 0.0;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.autoPlay;
    _config = CoastalBridgesAndCobbleConfig(biome: widget.initialBiome);
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
    final double dt = (now.difference(_lastTick).inMicroseconds / 1e6).clamp(
      0.0,
      0.05,
    );
    _lastTick = now;

    if (!mounted || !_isPlaying) return;
    setState(() {
      _elapsedSeconds += dt;
      _cameraDistanceMeters += _config.speedMetersPerSecond * dt;
    });
  }

  void _selectBiome(Iconic3dSceneryBiome biome) {
    setState(() {
      _config = _config.copyWith(biome: biome);
    });
    widget.onBiomeChanged?.call(biome);
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
      _elapsedSeconds += 0.25;
      _cameraDistanceMeters += _config.speedMetersPerSecond * 0.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Scenery3dFrameState frame = _engine.buildFrame(
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
          final bool isDesktopWide = constraints.maxWidth >= 1000;
          final bool isCompactMobile = constraints.maxWidth < 600;

          if (isDesktopWide) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 7,
                    child: _buildViewportCard(frame, minHeight: 360),
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
    Scenery3dFrameState frame, {
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
            painter: CoastalBridgesAndCobbleTrenchesPainter(
              frame: frame,
              config: _config,
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _SceneryHudHeaderBadge(frame: frame),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: _SceneryTelemetryStrip(frame: frame),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSidebar(
    Scenery3dFrameState frame, {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'SCENERIA 3D — IKONICZNE SEKTORY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Iconic3dSceneryBiome.values.map((biome) {
              return _SceneryActionButton(
                label: biome.shortTag,
                icon: _iconForBiome(biome),
                isActive: _config.biome == biome,
                onPressed: () => _selectBiome(biome),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            frame.biome.descriptionPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _SceneryActionButton(
                label: _isPlaying ? 'Pauza' : 'Start',
                icon: _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                isActive: _isPlaying,
                onPressed: _togglePlayback,
              ),
              _SceneryActionButton(
                label: 'Krok +6 m',
                icon: Icons.skip_next_rounded,
                isActive: false,
                isDisabled: _isPlaying,
                onPressed: _stepForward,
              ),
              _SceneryActionButton(
                label: 'Kolarze',
                icon: Icons.directions_bike_rounded,
                isActive: _config.showPelotonMarkers,
                onPressed: () {
                  setState(() {
                    _config = _config.copyWith(
                      showPelotonMarkers: !_config.showPelotonMarkers,
                    );
                  });
                },
              ),
              _SceneryActionButton(
                label: 'Cząsteczki',
                icon: Icons.air_rounded,
                isActive: _config.showAtmosphericParticles,
                onPressed: () {
                  setState(() {
                    _config = _config.copyWith(
                      showAtmosphericParticles:
                          !_config.showAtmosphericParticles,
                    );
                  });
                },
              ),
              _SceneryActionButton(
                label: 'Drgania',
                icon: Icons.vibration_rounded,
                isActive: _config.enableSurfaceVibration,
                onPressed: () {
                  setState(() {
                    _config = _config.copyWith(
                      enableSurfaceVibration: !_config.enableSurfaceVibration,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSliderRow(
            label: 'Prędkość kamery',
            valueText: '${(_config.speedMetersPerSecond * 3.6).round()} km/h',
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
          _buildSliderRow(
            label: 'Siła wiatru',
            valueText: '${frame.effectiveCrosswindMps.toStringAsFixed(1)} m/s',
            value: _config.windIntensityScale,
            min: 0.2,
            max: 2.0,
            onChanged: (double v) {
              setState(() {
                _config = _config.copyWith(windIntensityScale: v);
              });
            },
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryAccent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            trackHeight: 4,
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

  IconData _iconForBiome(Iconic3dSceneryBiome biome) {
    switch (biome) {
      case Iconic3dSceneryBiome.greatBeltSeaBridge:
        return Icons.waves_rounded;
      case Iconic3dSceneryBiome.arenbergForestTrench:
        return Icons.forest_rounded;
      case Iconic3dSceneryBiome.tuscanyChalkHills:
        return Icons.landscape_rounded;
      case Iconic3dSceneryBiome.montVentouxLunarSummit:
        return Icons.terrain_rounded;
    }
  }
}

class _SceneryHudHeaderBadge extends StatelessWidget {
  final Scenery3dFrameState frame;

  const _SceneryHudHeaderBadge({required this.frame});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  frame.biome.regionPl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(frame.cameraDistanceMeters / 1000.0).toStringAsFixed(2)} km',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneryTelemetryStrip extends StatelessWidget {
  final Scenery3dFrameState frame;

  const _SceneryTelemetryStrip({required this.frame});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: <Widget>[
          _metric(
            'Wiatr boczny',
            '${frame.effectiveCrosswindMps.toStringAsFixed(1)} m/s',
          ),
          _metric(
            'Opór CRR',
            '×${frame.biome.rollingResistanceMultiplier.toStringAsFixed(2)}',
          ),
          _metric(
            'Przyczepność μ',
            frame.biome.surfaceGripMu.toStringAsFixed(2),
          ),
          _metric(
            'Obiekty 3D',
            '${frame.visibleProps.length}/${frame.totalGeneratedProps}',
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Przycisk kontrolny z pełnymi stanami hover / active / disabled / focus.
class _SceneryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _SceneryActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onPressed,
    this.isDisabled = false,
  });

  @override
  State<_SceneryActionButton> createState() => _SceneryActionButtonState();
}

class _SceneryActionButtonState extends State<_SceneryActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.isActive
            ? AppColors.primaryAccent
            : (_isHovered ? AppColors.surfaceLight : AppColors.background);

    final Color borderColor = widget.isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : (widget.isActive
                ? AppColors.goldAccent.withValues(alpha: 0.85)
                : AppColors.cardBorder);

    final Color fgColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (bool v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 14, color: fgColor),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
