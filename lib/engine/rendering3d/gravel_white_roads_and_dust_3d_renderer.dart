// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/gravel_race_and_surface_model.dart';

// =============================================================================
// 1. PRESETY BIOMÓW SZUTROWYCH (STERRATO & PUSTYNNE PRERIE)
// =============================================================================

/// Charakterystyka wizualna i fizyczna trasy szutrowej w silniku 3D.
enum GravelRoadBiomePreset {
  tuscanySterrato(
    labelPl: 'Toskania — Białe Drogi (Sterrato)',
    shortTag: 'STERRATO',
    regionPl: 'Siena, Włochy • Strade Bianche',
    surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
    roadSurfaceColor: Color(0xFFE7E2D4),
    roadRutColor: Color(0xFFD1C9B4),
    roadShoulderColor: Color(0xFFC3B89E),
    dustCloudColor: Color(0xFFF3EFE6),
    skyTopColor: Color(0xFF1F3B5C),
    skyHorizonColor: Color(0xFFD8D0BE),
    terrainGroundColor: Color(0xFF5D6B42),
    defaultDustDensity: 0.88,
    windCrossSpeedMps: 3.4,
    hasCypressTrees: true,
    hasPrairieGrass: false,
    hasDesertCacti: false,
  ),
  kansasFlintHills(
    labelPl: 'Kansas — Pustynne Prerie (Flint Hills)',
    shortTag: 'PRERIA',
    regionPl: 'Emporia, USA • Unbound Gravel',
    surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
    roadSurfaceColor: Color(0xFFD4C19C),
    roadRutColor: Color(0xFFB8A27A),
    roadShoulderColor: Color(0xFF9F8962),
    dustCloudColor: Color(0xFFEAD9B7),
    skyTopColor: Color(0xFF284664),
    skyHorizonColor: Color(0xFFE3C89E),
    terrainGroundColor: Color(0xFF8C7B47),
    defaultDustDensity: 0.94,
    windCrossSpeedMps: 6.2,
    hasCypressTrees: false,
    hasPrairieGrass: true,
    hasDesertCacti: false,
  ),
  arizonaDesertWash(
    labelPl: 'Arizona — Pustynny Kanion (Sonora)',
    shortTag: 'PUSTYNIA',
    regionPl: 'Tucson, USA • Desert Gravel',
    surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
    roadSurfaceColor: Color(0xFFD9AE84),
    roadRutColor: Color(0xFFBC8D63),
    roadShoulderColor: Color(0xFFA77850),
    dustCloudColor: Color(0xFFF0D2B2),
    skyTopColor: Color(0xFF1E3755),
    skyHorizonColor: Color(0xFFE9BA8F),
    terrainGroundColor: Color(0xFF9D6B47),
    defaultDustDensity: 0.96,
    windCrossSpeedMps: 5.0,
    hasCypressTrees: false,
    hasPrairieGrass: false,
    hasDesertCacti: true,
  ),
  icelandVolcanicGravel(
    labelPl: 'Islandia — Bazaltowy Szuter (The Rift)',
    shortTag: 'BAZALT',
    regionPl: 'Hvolsvöllur, Islandia • Volcanic Gravel',
    surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
    roadSurfaceColor: Color(0xFF6B6E75),
    roadRutColor: Color(0xFF51545B),
    roadShoulderColor: Color(0xFF43464D),
    dustCloudColor: Color(0xFFB8BDC7),
    skyTopColor: Color(0xFF182536),
    skyHorizonColor: Color(0xFF8C97A4),
    terrainGroundColor: Color(0xFF3E4C3A),
    defaultDustDensity: 0.72,
    windCrossSpeedMps: 8.1,
    hasCypressTrees: false,
    hasPrairieGrass: true,
    hasDesertCacti: false,
  );

  final String labelPl;
  final String shortTag;
  final String regionPl;
  final GravelSurfaceCategory surfaceCategory;
  final Color roadSurfaceColor;
  final Color roadRutColor;
  final Color roadShoulderColor;
  final Color dustCloudColor;
  final Color skyTopColor;
  final Color skyHorizonColor;
  final Color terrainGroundColor;
  final double defaultDustDensity;
  final double windCrossSpeedMps;
  final bool hasCypressTrees;
  final bool hasPrairieGrass;
  final bool hasDesertCacti;

  const GravelRoadBiomePreset({
    required this.labelPl,
    required this.shortTag,
    required this.regionPl,
    required this.surfaceCategory,
    required this.roadSurfaceColor,
    required this.roadRutColor,
    required this.roadShoulderColor,
    required this.dustCloudColor,
    required this.skyTopColor,
    required this.skyHorizonColor,
    required this.terrainGroundColor,
    required this.defaultDustDensity,
    required this.windCrossSpeedMps,
    required this.hasCypressTrees,
    required this.hasPrairieGrass,
    required this.hasDesertCacti,
  });
}

// =============================================================================
// 2. KONFIGURACJA SCENY 3D I STAN NAPRAWY OPONY NA POBOCZU
// =============================================================================

/// Konfiguracja parametrów renderera 3D białych dróg szutrowych i chmur pyłu.
class GravelRoad3dConfig {
  final GravelRoadBiomePreset biomePreset;
  final double fieldOfViewDegrees;
  final double maxDrawDistanceMeters;
  final double roadWidthMeters;
  final double dustDensity;
  final double riderSpeedKmh;
  final double windCrossSpeedMps;
  final bool showDustClouds;
  final bool showRoadsideVegetation;
  final bool showRoadsideRepairAnimation;
  final bool showTelemetryOverlay;

  const GravelRoad3dConfig({
    this.biomePreset = GravelRoadBiomePreset.tuscanySterrato,
    this.fieldOfViewDegrees = 56.0,
    this.maxDrawDistanceMeters = 240.0,
    this.roadWidthMeters = 5.4,
    this.dustDensity = 0.88,
    this.riderSpeedKmh = 36.5,
    this.windCrossSpeedMps = 3.4,
    this.showDustClouds = true,
    this.showRoadsideVegetation = true,
    this.showRoadsideRepairAnimation = true,
    this.showTelemetryOverlay = true,
  });

  GravelRoad3dConfig copyWith({
    GravelRoadBiomePreset? biomePreset,
    double? fieldOfViewDegrees,
    double? maxDrawDistanceMeters,
    double? roadWidthMeters,
    double? dustDensity,
    double? riderSpeedKmh,
    double? windCrossSpeedMps,
    bool? showDustClouds,
    bool? showRoadsideVegetation,
    bool? showRoadsideRepairAnimation,
    bool? showTelemetryOverlay,
  }) {
    return GravelRoad3dConfig(
      biomePreset: biomePreset ?? this.biomePreset,
      fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
      maxDrawDistanceMeters:
          maxDrawDistanceMeters ?? this.maxDrawDistanceMeters,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      dustDensity: dustDensity ?? this.dustDensity,
      riderSpeedKmh: riderSpeedKmh ?? this.riderSpeedKmh,
      windCrossSpeedMps: windCrossSpeedMps ?? this.windCrossSpeedMps,
      showDustClouds: showDustClouds ?? this.showDustClouds,
      showRoadsideVegetation:
          showRoadsideVegetation ?? this.showRoadsideVegetation,
      showRoadsideRepairAnimation:
          showRoadsideRepairAnimation ?? this.showRoadsideRepairAnimation,
      showTelemetryOverlay: showTelemetryOverlay ?? this.showTelemetryOverlay,
    );
  }
}

/// Fazy animacji naprawy przebitej opony szutrowej na poboczu drogi.
enum RoadsideTireRepairPhase {
  ridingNormally(
    labelPl: 'Jazda w grupie szutrowej',
    shortTag: 'JAZDA',
    durationFraction: 0.0,
  ),
  pullingOverToShoulder(
    labelPl: 'Zjazd na pobocze (przebicie opony)',
    shortTag: 'ZJAZD',
    durationFraction: 0.16,
  ),
  dismountAndWheelRemoval(
    labelPl: 'Zsiadanie i zdjęcie uszkodzonego koła',
    shortTag: 'KOŁO',
    durationFraction: 0.24,
  ),
  plugAndCo2Inflation(
    labelPl: 'Korek Dynaplug + pompowanie CO₂',
    shortTag: 'CO₂',
    durationFraction: 0.40,
  ),
  remountAndChaseBack(
    labelPl: 'Założenie koła i powrót na szuter',
    shortTag: 'POWRÓT',
    durationFraction: 0.20,
  );

  final String labelPl;
  final String shortTag;
  final double durationFraction;

  const RoadsideTireRepairPhase({
    required this.labelPl,
    required this.shortTag,
    required this.durationFraction,
  });
}

/// Bieżący stan animacji naprawy opony na poboczu w przestrzeni 3D.
class RoadsideTireRepairState {
  final bool isRepairActive;
  final RoadsideTireRepairPhase phase;
  final double overallProgress;
  final double phaseProgress;
  final double lateralOffsetMeters;
  final double tirePressureBar;
  final double co2JetIntensity;
  final double riderCrouchFactor;
  final double wheelDetachedOffsetMeters;
  final double elapsedRepairSeconds;

  const RoadsideTireRepairState({
    required this.isRepairActive,
    required this.phase,
    required this.overallProgress,
    required this.phaseProgress,
    required this.lateralOffsetMeters,
    required this.tirePressureBar,
    required this.co2JetIntensity,
    required this.riderCrouchFactor,
    required this.wheelDetachedOffsetMeters,
    required this.elapsedRepairSeconds,
  });

  factory RoadsideTireRepairState.inactive() {
    return const RoadsideTireRepairState(
      isRepairActive: false,
      phase: RoadsideTireRepairPhase.ridingNormally,
      overallProgress: 0.0,
      phaseProgress: 0.0,
      lateralOffsetMeters: 1.15,
      tirePressureBar: 2.55,
      co2JetIntensity: 0.0,
      riderCrouchFactor: 0.0,
      wheelDetachedOffsetMeters: 0.0,
      elapsedRepairSeconds: 0.0,
    );
  }
}

/// Kalkulator kinematyki naprawy opony na poboczu (bez alokacji).
class RoadsideTireRepairAnimator {
  static const double totalRepairCycleSeconds = 11.0;

  const RoadsideTireRepairAnimator();

  /// Wylicza stan animacji naprawy dla postępu z zakresu `0.0..1.0`.
  RoadsideTireRepairState evaluate({
    required bool isRepairActive,
    required double normalizedProgress,
    double roadHalfWidthMeters = 2.7,
  }) {
    if (!isRepairActive) {
      return RoadsideTireRepairState.inactive();
    }

    final double p = normalizedProgress.clamp(0.0, 1.0);
    final double shoulderTarget = roadHalfWidthMeters + 1.25;
    final double elapsed = p * totalRepairCycleSeconds;

    if (p < 0.16) {
      final double t = (p / 0.16).clamp(0.0, 1.0);
      final double ease = Curves.easeOutCubic.transform(t);
      return RoadsideTireRepairState(
        isRepairActive: true,
        phase: RoadsideTireRepairPhase.pullingOverToShoulder,
        overallProgress: p,
        phaseProgress: t,
        lateralOffsetMeters: 1.15 + (shoulderTarget - 1.15) * ease,
        tirePressureBar: 2.2 - 1.75 * ease,
        co2JetIntensity: 0.0,
        riderCrouchFactor: 0.15 * ease,
        wheelDetachedOffsetMeters: 0.0,
        elapsedRepairSeconds: elapsed,
      );
    }

    if (p < 0.40) {
      final double t = ((p - 0.16) / 0.24).clamp(0.0, 1.0);
      final double ease = Curves.easeInOutCubic.transform(t);
      return RoadsideTireRepairState(
        isRepairActive: true,
        phase: RoadsideTireRepairPhase.dismountAndWheelRemoval,
        overallProgress: p,
        phaseProgress: t,
        lateralOffsetMeters: shoulderTarget,
        tirePressureBar: 0.45,
        co2JetIntensity: 0.0,
        riderCrouchFactor: 0.15 + 0.85 * ease,
        wheelDetachedOffsetMeters: 0.48 * ease,
        elapsedRepairSeconds: elapsed,
      );
    }

    if (p < 0.80) {
      final double t = ((p - 0.40) / 0.40).clamp(0.0, 1.0);
      // Pierwsze 35% tej fazy: wciskanie korka; kolejne 65%: strzał naboju CO₂.
      final double co2Phase = t > 0.35 ? ((t - 0.35) / 0.65).clamp(0.0, 1.0) : 0.0;
      final double jetPulse = co2Phase > 0.0 && co2Phase < 0.92
          ? (0.65 + 0.35 * math.sin(co2Phase * math.pi * 10.0))
          : 0.0;
      return RoadsideTireRepairState(
        isRepairActive: true,
        phase: RoadsideTireRepairPhase.plugAndCo2Inflation,
        overallProgress: p,
        phaseProgress: t,
        lateralOffsetMeters: shoulderTarget,
        tirePressureBar: 0.45 + 2.15 * Curves.easeOutCubic.transform(co2Phase),
        co2JetIntensity: jetPulse,
        riderCrouchFactor: 1.0,
        wheelDetachedOffsetMeters: 0.48 * (1.0 - (co2Phase * 1.4).clamp(0.0, 1.0)),
        elapsedRepairSeconds: elapsed,
      );
    }

    final double t = ((p - 0.80) / 0.20).clamp(0.0, 1.0);
    final double ease = Curves.easeInOutCubic.transform(t);
    return RoadsideTireRepairState(
      isRepairActive: true,
      phase: RoadsideTireRepairPhase.remountAndChaseBack,
      overallProgress: p,
      phaseProgress: t,
      lateralOffsetMeters: shoulderTarget - (shoulderTarget - 1.25) * ease,
      tirePressureBar: 2.60,
      co2JetIntensity: 0.0,
      riderCrouchFactor: 1.0 - ease,
      wheelDetachedOffsetMeters: 0.0,
      elapsedRepairSeconds: elapsed,
    );
  }
}

// =============================================================================
// 3. MODELE OBIEKTÓW SCENY 3D (KOLARZE, CZĄSTECZKI PYŁU, TELEMETRIA)
// =============================================================================

/// Cząsteczka gęstej chmury pyłu w przestrzeni 3D.
class GravelDustParticle3D {
  final Vector3 worldPosition;
  final double baseRadiusMeters;
  final double opacity;
  final double ageFactor;

  const GravelDustParticle3D({
    required this.worldPosition,
    required this.baseRadiusMeters,
    required this.opacity,
    required this.ageFactor,
  });
}

/// Kolarz w grupie szutrowej renderowany w scenie 3D.
class GravelPelotonRider3D {
  final int id;
  final double forwardDistanceMeters;
  final double lateralOffsetMeters;
  final double speedMps;
  final Color jerseyColor;
  final Color helmetColor;
  final bool isHighlightedLeader;

  const GravelPelotonRider3D({
    required this.id,
    required this.forwardDistanceMeters,
    required this.lateralOffsetMeters,
    required this.speedMps,
    required this.jerseyColor,
    required this.helmetColor,
    this.isHighlightedLeader = false,
  });
}

/// Telemetria pojedynczej klatki renderera 3D szutru i chmur pyłu.
class GravelRoadFrameTelemetry {
  final int roadSegmentsRendered;
  final int ridersRendered;
  final int dustParticlesRendered;
  final int sceneryPropsRendered;
  final double currentDustVisibilityPenalty;
  final double currentCrrMultiplier;
  final RoadsideTireRepairPhase repairPhase;

  const GravelRoadFrameTelemetry({
    required this.roadSegmentsRendered,
    required this.ridersRendered,
    required this.dustParticlesRendered,
    required this.sceneryPropsRendered,
    required this.currentDustVisibilityPenalty,
    required this.currentCrrMultiplier,
    required this.repairPhase,
  });
}

// =============================================================================
// 4. SILNIK RZUTOWANIA I RENDERER 3D BIAŁYCH DRÓG SZUTROWYCH I PYŁU
// =============================================================================

/// Główny renderer 3D białych dróg szutrowych (*Sterrato* i pustynnych prerii)
/// z gęstymi chmurami pyłu i animacją naprawy opony na poboczu.
class GravelWhiteRoadsAndDust3dRenderer {
  const GravelWhiteRoadsAndDust3dRenderer();

  /// Generuje deterministyczną grupę kolarzy na trasie szutrowej przed kamerą.
  List<GravelPelotonRider3D> buildGravelPack({
    required double cameraDistanceMeters,
    required double simulationTimeSeconds,
    required GravelRoad3dConfig config,
  }) {
    const List<Color> jerseyPalette = [
      AppColors.primaryAccent,
      AppColors.goldAccent,
      AppColors.accentBlue,
      Color(0xFFE5E7EB),
      Color(0xFF10B981),
      Color(0xFFF97316),
      Color(0xFF6366F1),
    ];

    final List<GravelPelotonRider3D> riders = [];
    final double baseSpeedMps = config.riderSpeedKmh / 3.6;

    for (int i = 0; i < 14; i++) {
      final int row = i ~/ 3;
      final int lane = i % 3;
      final double longitudinalJitter =
          math.sin(i * 2.13 + simulationTimeSeconds * 0.8) * 0.9;
      final double lateralJitter =
          math.cos(i * 1.47 + simulationTimeSeconds * 1.1) * 0.22;

      final double forward =
          cameraDistanceMeters + 14.0 + row * 4.4 + longitudinalJitter;
      final double lateral = -1.35 + lane * 1.35 + lateralJitter;

      riders.add(
        GravelPelotonRider3D(
          id: i,
          forwardDistanceMeters: forward,
          lateralOffsetMeters: lateral.clamp(
            -(config.roadWidthMeters * 0.44),
            config.roadWidthMeters * 0.44,
          ),
          speedMps: baseSpeedMps,
          jerseyColor: jerseyPalette[i % jerseyPalette.length],
          helmetColor: i == 0 ? AppColors.goldAccent : const Color(0xFFF3F4F6),
          isHighlightedLeader: i == 0,
        ),
      );
    }

    return riders;
  }

  /// Wyznacza krzywiznę i wysokość terenu wzdłuż osi drogi dla danego dystansu.
  double roadCenterXAt(double distanceMeters) {
    return math.sin(distanceMeters * 0.022) * 8.5 +
        math.cos(distanceMeters * 0.009) * 5.0;
  }

  double roadElevationYAt(double distanceMeters) {
    return math.sin(distanceMeters * 0.017) * 2.4 +
        math.cos(distanceMeters * 0.031) * 0.8;
  }

  /// Rzutuje punkt świata 3D na ekran 2D względem pozycji kamery.
  Offset? projectPoint({
    required Vector3 worldPoint,
    required Vector3 cameraPos,
    required double cameraYawRad,
    required double cameraPitchRad,
    required Size viewportSize,
    required double fovDegrees,
  }) {
    final double dx = worldPoint.x - cameraPos.x;
    final double dy = worldPoint.y - cameraPos.y;
    final double dz = worldPoint.z - cameraPos.z;

    final double cosYaw = math.cos(-cameraYawRad);
    final double sinYaw = math.sin(-cameraYawRad);
    final double rx = dx * cosYaw - dz * sinYaw;
    final double rz = dx * sinYaw + dz * cosYaw;

    final double cosPitch = math.cos(cameraPitchRad);
    final double sinPitch = math.sin(cameraPitchRad);
    final double ry = dy * cosPitch - rz * sinPitch;
    final double fz = dy * sinPitch + rz * cosPitch;

    if (fz <= 0.65) {
      return null;
    }

    final double fovRad = fovDegrees * math.pi / 180.0;
    final double focalLength =
        (viewportSize.height * 0.5) / math.tan(fovRad * 0.5);

    final double screenX = viewportSize.width * 0.5 + (rx / fz) * focalLength;
    final double screenY = viewportSize.height * 0.52 - (ry / fz) * focalLength;

    return Offset(screenX, screenY);
  }

  /// Renderuje pełną scenę 3D szutrową i zwraca telemetrię klatki.
  GravelRoadFrameTelemetry paintScene({
    required Canvas canvas,
    required Size size,
    required double cameraDistanceMeters,
    required double simulationTimeSeconds,
    required GravelRoad3dConfig config,
    required RoadsideTireRepairState repairState,
  }) {
    if (size.width <= 0 || size.height <= 0) {
      return GravelRoadFrameTelemetry(
        roadSegmentsRendered: 0,
        ridersRendered: 0,
        dustParticlesRendered: 0,
        sceneryPropsRendered: 0,
        currentDustVisibilityPenalty: 0.0,
        currentCrrMultiplier: config.biomePreset.surfaceCategory.crrMultiplier,
        repairPhase: repairState.phase,
      );
    }

    final GravelRoadBiomePreset biome = config.biomePreset;
    final double camZ = cameraDistanceMeters;
    final double camX = roadCenterXAt(camZ);
    final double camY = roadElevationYAt(camZ) + 2.55;
    final double lookAheadX = roadCenterXAt(camZ + 22.0);
    final double lookAheadY = roadElevationYAt(camZ + 22.0) + 1.1;

    final double cameraYaw = math.atan2(lookAheadX - camX, 22.0);
    final double cameraPitch = math.atan2(lookAheadY - camY, 22.0);
    final Vector3 cameraPos = Vector3(camX, camY, camZ);

    // 1. Niebo i pustynna/toskańska poświata horyzontu
    _paintSkyAndTerrainBackground(
      canvas: canvas,
      size: size,
      biome: biome,
      dustDensity: config.showDustClouds ? config.dustDensity : 0.0,
    );

    // 2. Wstęga szutru 3D z koleinami, poboczem i drobnym kruszywem
    final int roadSegments = _paintGravelRoadRibbon(
      canvas: canvas,
      size: size,
      cameraPos: cameraPos,
      cameraYaw: cameraYaw,
      cameraPitch: cameraPitch,
      cameraDistanceMeters: cameraDistanceMeters,
      config: config,
    );

    // 3. Przydrożna roślinność i skały (cyprysy, trawa preriowa, kaktusy)
    int sceneryProps = 0;
    if (config.showRoadsideVegetation) {
      sceneryProps = _paintRoadsideBiomeProps(
        canvas: canvas,
        size: size,
        cameraPos: cameraPos,
        cameraYaw: cameraYaw,
        cameraPitch: cameraPitch,
        cameraDistanceMeters: cameraDistanceMeters,
        config: config,
        simulationTimeSeconds: simulationTimeSeconds,
      );
    }

    // 4. Kolarze szutrowi + kolarz naprawiający oponę na poboczu + chmury pyłu
    final List<GravelPelotonRider3D> riders = buildGravelPack(
      cameraDistanceMeters: cameraDistanceMeters,
      simulationTimeSeconds: simulationTimeSeconds,
      config: config,
    );

    int ridersRendered = 0;
    int dustParticlesRendered = 0;

    // Sortowanie od najdalszych do najbliższych (algorytm malarza)
    riders.sort(
      (a, b) => b.forwardDistanceMeters.compareTo(a.forwardDistanceMeters),
    );

    final double repairWorldZ = cameraDistanceMeters + 12.2;

    for (final rider in riders) {
      if (config.showRoadsideRepairAnimation &&
          repairState.isRepairActive &&
          rider.forwardDistanceMeters < repairWorldZ) {
        // Rysujemy najpierw scenę naprawy przed bliższymi elementami
      }

      final bool drew = _paintRider3D(
        canvas: canvas,
        size: size,
        cameraPos: cameraPos,
        cameraYaw: cameraYaw,
        cameraPitch: cameraPitch,
        config: config,
        rider: rider,
        simulationTimeSeconds: simulationTimeSeconds,
      );
      if (drew) {
        ridersRendered++;
      }

      if (config.showDustClouds) {
        dustParticlesRendered += _paintRiderDustPlume(
          canvas: canvas,
          size: size,
          cameraPos: cameraPos,
          cameraYaw: cameraYaw,
          cameraPitch: cameraPitch,
          config: config,
          rider: rider,
          simulationTimeSeconds: simulationTimeSeconds,
        );
      }
    }

    // 5. Dedykowany kolarz z animacją naprawy opony na poboczu
    if (config.showRoadsideRepairAnimation) {
      final bool repairDrawn = _paintRoadsideRepairRider3D(
        canvas: canvas,
        size: size,
        cameraPos: cameraPos,
        cameraYaw: cameraYaw,
        cameraPitch: cameraPitch,
        config: config,
        repairWorldZ: repairWorldZ,
        repairState: repairState,
        simulationTimeSeconds: simulationTimeSeconds,
      );
      if (repairDrawn) {
        ridersRendered++;
      }
    }

    // 6. Gęsta warstwa unoszącego się pyłu na horyzoncie / nad peletonem
    if (config.showDustClouds && config.dustDensity > 0.05) {
      _paintAtmosphericDustVeil(
        canvas: canvas,
        size: size,
        biome: biome,
        dustDensity: config.dustDensity,
        simulationTimeSeconds: simulationTimeSeconds,
      );
    }

    final double visibilityPenalty = config.showDustClouds
        ? (config.dustDensity * 0.68).clamp(0.0, 0.85)
        : 0.0;

    return GravelRoadFrameTelemetry(
      roadSegmentsRendered: roadSegments,
      ridersRendered: ridersRendered,
      dustParticlesRendered: dustParticlesRendered,
      sceneryPropsRendered: sceneryProps,
      currentDustVisibilityPenalty: visibilityPenalty,
      currentCrrMultiplier: biome.surfaceCategory.crrMultiplier,
      repairPhase: repairState.phase,
    );
  }

  void _paintSkyAndTerrainBackground({
    required Canvas canvas,
    required Size size,
    required GravelRoadBiomePreset biome,
    required double dustDensity,
  }) {
    final double horizonY = size.height * 0.43;

    // Niebo
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          biome.skyTopColor,
          Color.lerp(
                biome.skyHorizonColor,
                biome.dustCloudColor,
                dustDensity * 0.45,
              ) ??
              biome.skyHorizonColor,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY + 8));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY + 8), skyPaint);

    // Tarcza słońca + ciepła poświata
    final Offset sunCenter = Offset(size.width * 0.78, size.height * 0.17);
    final Paint sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF8DC).withValues(alpha: 0.90),
          biome.dustCloudColor.withValues(alpha: 0.32),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: 95));
    canvas.drawCircle(sunCenter, 95, sunGlow);

    // Odległe wzgórza Toskanii / płaskowyż prerii
    final Path hillsPath = Path()..moveTo(0, horizonY);
    for (double x = 0; x <= size.width; x += 24) {
      final double hill = math.sin(x * 0.008) * 16.0 +
          math.cos(x * 0.021) * 7.0;
      hillsPath.lineTo(x, horizonY - 12.0 + hill);
    }
    hillsPath
      ..lineTo(size.width, horizonY + 12)
      ..lineTo(0, horizonY + 12)
      ..close();

    final Paint hillPaint = Paint()
      ..color = Color.lerp(
            biome.terrainGroundColor,
            biome.skyHorizonColor,
            0.42,
          ) ??
          biome.terrainGroundColor;
    canvas.drawPath(hillsPath, hillPaint);

    // Główny grunt poza drogą
    final Paint groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(biome.terrainGroundColor, biome.skyHorizonColor, 0.28) ??
              biome.terrainGroundColor,
          biome.terrainGroundColor,
        ],
      ).createShader(
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      groundPaint,
    );
  }

  int _paintGravelRoadRibbon({
    required Canvas canvas,
    required Size size,
    required Vector3 cameraPos,
    required double cameraYaw,
    required double cameraPitch,
    required double cameraDistanceMeters,
    required GravelRoad3dConfig config,
  }) {
    final GravelRoadBiomePreset biome = config.biomePreset;
    final double halfWidth = config.roadWidthMeters * 0.5;
    const double shoulderExtra = 1.45;
    const double stepMeters = 4.0;

    int segmentsDrawn = 0;
    final double startZ = cameraDistanceMeters + 2.0;
    final double endZ = cameraDistanceMeters + config.maxDrawDistanceMeters;

    for (double z = endZ; z > startZ; z -= stepMeters) {
      final double zNear = (z - stepMeters).clamp(startZ, endZ);
      final double zFar = z;

      final double xNear = roadCenterXAt(zNear);
      final double yNear = roadElevationYAt(zNear);
      final double xFar = roadCenterXAt(zFar);
      final double yFar = roadElevationYAt(zFar);

      final Offset? pNearL = projectPoint(
        worldPoint: Vector3(xNear - halfWidth, yNear, zNear),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );
      final Offset? pNearR = projectPoint(
        worldPoint: Vector3(xNear + halfWidth, yNear, zNear),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );
      final Offset? pFarL = projectPoint(
        worldPoint: Vector3(xFar - halfWidth, yFar, zFar),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );
      final Offset? pFarR = projectPoint(
        worldPoint: Vector3(xFar + halfWidth, yFar, zFar),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );

      if (pNearL == null || pNearR == null || pFarL == null || pFarR == null) {
        continue;
      }

      final double distFactor =
          ((zFar - cameraDistanceMeters) / config.maxDrawDistanceMeters)
              .clamp(0.0, 1.0);

      // Pobocze (miejsce zjazdu na naprawę opony)
      final Offset? sNearL = projectPoint(
        worldPoint: Vector3(xNear - halfWidth - shoulderExtra, yNear, zNear),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );
      final Offset? sNearR = projectPoint(
        worldPoint: Vector3(xNear + halfWidth + shoulderExtra, yNear, zNear),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );
      final Offset? sFarL = projectPoint(
        worldPoint: Vector3(xFar - halfWidth - shoulderExtra, yFar, zFar),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );
      final Offset? sFarR = projectPoint(
        worldPoint: Vector3(xFar + halfWidth + shoulderExtra, yFar, zFar),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );

      if (sNearL != null && sNearR != null && sFarL != null && sFarR != null) {
        final Path shoulderPath = Path()
          ..moveTo(sNearL.dx, sNearL.dy)
          ..lineTo(sNearR.dx, sNearR.dy)
          ..lineTo(sFarR.dx, sFarR.dy)
          ..lineTo(sFarL.dx, sFarL.dy)
          ..close();

        final Color shoulderColor = Color.lerp(
              biome.roadShoulderColor,
              biome.skyHorizonColor,
              distFactor * 0.55,
            ) ??
            biome.roadShoulderColor;
        canvas.drawPath(shoulderPath, Paint()..color = shoulderColor);
      }

      // Główna nawierzchnia białego szutru / preriowej drogi
      final Path roadPath = Path()
        ..moveTo(pNearL.dx, pNearL.dy)
        ..lineTo(pNearR.dx, pNearR.dy)
        ..lineTo(pFarR.dx, pFarR.dy)
        ..lineTo(pFarL.dx, pFarL.dy)
        ..close();

      final Color baseRoadColor = Color.lerp(
            biome.roadSurfaceColor,
            biome.skyHorizonColor,
            distFactor * 0.50,
          ) ??
          biome.roadSurfaceColor;
      canvas.drawPath(roadPath, Paint()..color = baseRoadColor);

      // Dwie wyjeżdżone koleiny kół (lewa i prawa)
      final Paint rutPaint = Paint()
        ..color = (Color.lerp(
                  biome.roadRutColor,
                  biome.skyHorizonColor,
                  distFactor * 0.55,
                ) ??
                biome.roadRutColor)
            .withValues(alpha: 0.72);

      for (final double rutFrac in const [0.30, 0.70]) {
        final Offset nA = Offset.lerp(pNearL, pNearR, rutFrac - 0.055)!;
        final Offset nB = Offset.lerp(pNearL, pNearR, rutFrac + 0.055)!;
        final Offset fA = Offset.lerp(pFarL, pFarR, rutFrac - 0.055)!;
        final Offset fB = Offset.lerp(pFarL, pFarR, rutFrac + 0.055)!;

        final Path rutPath = Path()
          ..moveTo(nA.dx, nA.dy)
          ..lineTo(nB.dx, nB.dy)
          ..lineTo(fB.dx, fB.dy)
          ..lineTo(fA.dx, fA.dy)
          ..close();
        canvas.drawPath(rutPath, rutPaint);
      }

      // Drobne kamyczki i tarka szutrowa w bliższym planie
      if (distFactor < 0.45) {
        final int stoneSeed = (zNear * 13).floor();
        final Paint stonePaint = Paint()
          ..color = biome.roadRutColor.withValues(alpha: (1.0 - distFactor) * 0.55);
        for (int s = 0; s < 4; s++) {
          final double frac = ((stoneSeed + s * 37) % 100) / 100.0;
          final Offset stonePos = Offset.lerp(pNearL, pNearR, frac)!;
          final double stoneR = (1.0 - distFactor) * 2.2 + 0.7;
          canvas.drawCircle(stonePos, stoneR, stonePaint);
        }
      }

      segmentsDrawn++;
    }

    return segmentsDrawn;
  }

  int _paintRoadsideBiomeProps({
    required Canvas canvas,
    required Size size,
    required Vector3 cameraPos,
    required double cameraYaw,
    required double cameraPitch,
    required double cameraDistanceMeters,
    required GravelRoad3dConfig config,
    required double simulationTimeSeconds,
  }) {
    final GravelRoadBiomePreset biome = config.biomePreset;
    const double spacing = 14.0;
    final double firstPropZ =
        (cameraDistanceMeters / spacing).ceil() * spacing;
    int propsDrawn = 0;

    for (double z = firstPropZ + config.maxDrawDistanceMeters * 0.82;
        z >= firstPropZ;
        z -= spacing) {
      if (z <= cameraDistanceMeters + 3.0) continue;

      final double roadX = roadCenterXAt(z);
      final double roadY = roadElevationYAt(z);
      final int idx = (z / spacing).round();

      for (final int side in const [-1, 1]) {
        final double lateral =
            side * (config.roadWidthMeters * 0.5 + 3.2 + (idx % 3) * 1.4);
        final Vector3 basePos = Vector3(roadX + lateral, roadY, z);

        final Offset? screenBase = projectPoint(
          worldPoint: basePos,
          cameraPos: cameraPos,
          cameraYawRad: cameraYaw,
          cameraPitchRad: cameraPitch,
          viewportSize: size,
          fovDegrees: config.fieldOfViewDegrees,
        );
        if (screenBase == null) continue;

        final double heightMeters = biome.hasCypressTrees
            ? 7.8 + (idx % 3) * 1.2
            : biome.hasDesertCacti
                ? 4.4 + (idx % 2) * 1.1
                : 1.35 + (idx % 3) * 0.35;

        final Offset? screenTop = projectPoint(
          worldPoint: Vector3(roadX + lateral, roadY + heightMeters, z),
          cameraPos: cameraPos,
          cameraYawRad: cameraYaw,
          cameraPitchRad: cameraPitch,
          viewportSize: size,
          fovDegrees: config.fieldOfViewDegrees,
        );
        if (screenTop == null) continue;

        final double pixelH = (screenBase.dy - screenTop.dy).abs();
        if (pixelH < 3.0) continue;

        if (biome.hasCypressTrees) {
          _drawCypressTree(canvas, screenBase, pixelH);
        } else if (biome.hasDesertCacti) {
          _drawSaguaroCactus(canvas, screenBase, pixelH);
        } else if (biome.hasPrairieGrass) {
          final double sway =
              math.sin(simulationTimeSeconds * 2.8 + idx) * pixelH * 0.14;
          _drawPrairieGrassTuft(canvas, screenBase, pixelH, sway, biome);
        }
        propsDrawn++;
      }
    }

    return propsDrawn;
  }

  void _drawCypressTree(Canvas canvas, Offset base, double heightPx) {
    final double w = heightPx * 0.22;
    // Pień
    canvas.drawLine(
      base,
      Offset(base.dx, base.dy - heightPx * 0.22),
      Paint()
        ..color = const Color(0xFF4A3728)
        ..strokeWidth = (w * 0.32).clamp(1.2, 6.0),
    );
    // Smukła korona toskańskiego cyprysa
    final Path crown = Path()
      ..moveTo(base.dx, base.dy - heightPx)
      ..quadraticBezierTo(
        base.dx + w,
        base.dy - heightPx * 0.48,
        base.dx + w * 0.45,
        base.dy - heightPx * 0.16,
      )
      ..lineTo(base.dx - w * 0.45, base.dy - heightPx * 0.16)
      ..quadraticBezierTo(
        base.dx - w,
        base.dy - heightPx * 0.48,
        base.dx,
        base.dy - heightPx,
      )
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFF283D26));
  }

  void _drawSaguaroCactus(Canvas canvas, Offset base, double heightPx) {
    final double strokeW = (heightPx * 0.14).clamp(2.0, 9.0);
    final Paint cactusPaint = Paint()
      ..color = const Color(0xFF43643B)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Główny pień kaktusa
    canvas.drawLine(
      base,
      Offset(base.dx, base.dy - heightPx),
      cactusPaint,
    );
    // Ramiona
    final double armY = base.dy - heightPx * 0.56;
    canvas.drawLine(
      Offset(base.dx, armY),
      Offset(base.dx + strokeW * 1.4, armY - heightPx * 0.18),
      cactusPaint..strokeWidth = strokeW * 0.72,
    );
    canvas.drawLine(
      Offset(base.dx, armY + heightPx * 0.08),
      Offset(base.dx - strokeW * 1.3, armY - heightPx * 0.12),
      cactusPaint..strokeWidth = strokeW * 0.72,
    );
  }

  void _drawPrairieGrassTuft(
    Canvas canvas,
    Offset base,
    double heightPx,
    double swayPx,
    GravelRoadBiomePreset biome,
  ) {
    final Paint grassPaint = Paint()
      ..color = Color.lerp(
            const Color(0xFFC2A35B),
            biome.terrainGroundColor,
            0.35,
          )!
          .withValues(alpha: 0.85)
      ..strokeWidth = (heightPx * 0.08).clamp(1.0, 3.0)
      ..strokeCap = StrokeCap.round;

    for (int b = -2; b <= 2; b++) {
      canvas.drawLine(
        Offset(base.dx + b * heightPx * 0.14, base.dy),
        Offset(
          base.dx + b * heightPx * 0.24 + swayPx,
          base.dy - heightPx * (0.75 + (b.abs() == 1 ? 0.2 : 0.0)),
        ),
        grassPaint,
      );
    }
  }

  bool _paintRider3D({
    required Canvas canvas,
    required Size size,
    required Vector3 cameraPos,
    required double cameraYaw,
    required double cameraPitch,
    required GravelRoad3dConfig config,
    required GravelPelotonRider3D rider,
    required double simulationTimeSeconds,
  }) {
    final double z = rider.forwardDistanceMeters;
    final double x = roadCenterXAt(z) + rider.lateralOffsetMeters;
    final double y = roadElevationYAt(z);

    final Offset? wheelBase = projectPoint(
      worldPoint: Vector3(x, y, z),
      cameraPos: cameraPos,
      cameraYawRad: cameraYaw,
      cameraPitchRad: cameraPitch,
      viewportSize: size,
      fovDegrees: config.fieldOfViewDegrees,
    );
    final Offset? headPos = projectPoint(
      worldPoint: Vector3(x, y + 1.48, z),
      cameraPos: cameraPos,
      cameraYawRad: cameraYaw,
      cameraPitchRad: cameraPitch,
      viewportSize: size,
      fovDegrees: config.fieldOfViewDegrees,
    );

    if (wheelBase == null || headPos == null) return false;
    final double h = (wheelBase.dy - headPos.dy).abs();
    if (h < 5.0) return false;

    // Miękki cień pod rowerem
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(wheelBase.dx, wheelBase.dy + 1.5),
        width: h * 0.52,
        height: h * 0.14,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.26),
    );

    // Tylne koło + rama
    final double wheelRadius = h * 0.22;
    canvas.drawCircle(
      Offset(wheelBase.dx, wheelBase.dy - wheelRadius),
      wheelRadius,
      Paint()
        ..color = const Color(0xFF1F242D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (h * 0.06).clamp(1.2, 4.5),
    );

    // Lekkie kołysanie kadencji
    final double cadenceSway =
        math.sin(simulationTimeSeconds * 8.5 + rider.id) * h * 0.04;

    // Tułów / koszulka
    final Path torso = Path()
      ..moveTo(wheelBase.dx - h * 0.17 + cadenceSway, wheelBase.dy - h * 0.42)
      ..lineTo(wheelBase.dx + h * 0.17 + cadenceSway, wheelBase.dy - h * 0.42)
      ..lineTo(headPos.dx + h * 0.12 + cadenceSway, headPos.dy + h * 0.18)
      ..lineTo(headPos.dx - h * 0.12 + cadenceSway, headPos.dy + h * 0.18)
      ..close();
    canvas.drawPath(torso, Paint()..color = rider.jerseyColor);

    // Kask
    canvas.drawCircle(
      Offset(headPos.dx + cadenceSway, headPos.dy + h * 0.08),
      h * 0.11,
      Paint()..color = rider.helmetColor,
    );

    if (rider.isHighlightedLeader) {
      canvas.drawCircle(
        Offset(headPos.dx + cadenceSway, headPos.dy - h * 0.12),
        (h * 0.06).clamp(2.5, 5.5),
        Paint()..color = AppColors.goldAccent,
      );
    }

    return true;
  }

  int _paintRiderDustPlume({
    required Canvas canvas,
    required Size size,
    required Vector3 cameraPos,
    required double cameraYaw,
    required double cameraPitch,
    required GravelRoad3dConfig config,
    required GravelPelotonRider3D rider,
    required double simulationTimeSeconds,
  }) {
    if (config.dustDensity <= 0.03) return 0;

    final GravelRoadBiomePreset biome = config.biomePreset;
    int rendered = 0;
    const int puffsPerRider = 6;

    for (int p = 0; p < puffsPerRider; p++) {
      final double cycle =
          ((simulationTimeSeconds * 1.45 + rider.id * 0.23 + p * 0.16) % 1.0);
      final double pz = rider.forwardDistanceMeters - cycle * 8.5;
      final double windDriftX = config.windCrossSpeedMps * cycle * 0.42;
      final double px =
          roadCenterXAt(pz) + rider.lateralOffsetMeters + windDriftX;
      final double py = roadElevationYAt(pz) + 0.18 + cycle * 1.65;

      final Offset? screenPos = projectPoint(
        worldPoint: Vector3(px, py, pz),
        cameraPos: cameraPos,
        cameraYawRad: cameraYaw,
        cameraPitchRad: cameraPitch,
        viewportSize: size,
        fovDegrees: config.fieldOfViewDegrees,
      );
      if (screenPos == null) continue;

      final double dist = (pz - cameraPos.z).abs().clamp(4.0, 220.0);
      final double scale = 28.0 / dist;
      final double radiusPx = (16.0 + cycle * 32.0) * scale * (0.6 + config.dustDensity * 0.8);
      final double alpha =
          (1.0 - cycle) * 0.34 * config.dustDensity.clamp(0.0, 1.0);

      if (alpha <= 0.01 || radiusPx < 1.5) continue;

      final Paint dustPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            biome.dustCloudColor.withValues(alpha: alpha),
            biome.dustCloudColor.withValues(alpha: alpha * 0.35),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: screenPos, radius: radiusPx));

      canvas.drawCircle(screenPos, radiusPx, dustPaint);
      rendered++;
    }

    return rendered;
  }

  bool _paintRoadsideRepairRider3D({
    required Canvas canvas,
    required Size size,
    required Vector3 cameraPos,
    required double cameraYaw,
    required double cameraPitch,
    required GravelRoad3dConfig config,
    required double repairWorldZ,
    required RoadsideTireRepairState repairState,
    required double simulationTimeSeconds,
  }) {
    final double z = repairWorldZ;
    final double x = roadCenterXAt(z) + repairState.lateralOffsetMeters;
    final double y = roadElevationYAt(z);

    final Offset? basePos = projectPoint(
      worldPoint: Vector3(x, y, z),
      cameraPos: cameraPos,
      cameraYawRad: cameraYaw,
      cameraPitchRad: cameraPitch,
      viewportSize: size,
      fovDegrees: config.fieldOfViewDegrees,
    );
    final Offset? topPos = projectPoint(
      worldPoint: Vector3(x, y + 1.48, z),
      cameraPos: cameraPos,
      cameraYawRad: cameraYaw,
      cameraPitchRad: cameraPitch,
      viewportSize: size,
      fovDegrees: config.fieldOfViewDegrees,
    );
    if (basePos == null || topPos == null) return false;

    final double h = (basePos.dy - topPos.dy).abs();
    if (h < 8.0) return false;

    // Cień na poboczu
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(basePos.dx, basePos.dy + 2.0),
        width: h * 0.85,
        height: h * 0.18,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.30),
    );

    // Rower pochylony/odwrócony na poboczu podczas naprawy
    final double wheelR = h * 0.24;
    final Offset rearWheelCenter = Offset(
      basePos.dx - h * 0.24,
      basePos.dy - wheelR - repairState.wheelDetachedOffsetMeters * h * 0.28,
    );
    final Offset frontWheelCenter = Offset(
      basePos.dx + h * 0.26,
      basePos.dy - wheelR,
    );

    final Paint wheelPaint = Paint()
      ..color = const Color(0xFF1F242D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (h * 0.065).clamp(1.6, 5.0);

    canvas.drawCircle(rearWheelCenter, wheelR, wheelPaint);
    canvas.drawCircle(frontWheelCenter, wheelR, wheelPaint);

    // Rama roweru
    final Paint framePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = (h * 0.055).clamp(1.5, 4.2)
      ..strokeCap = StrokeCap.round;

    final Offset bb = Offset(basePos.dx, basePos.dy - wheelR * 1.05);
    final Offset seatCluster = Offset(basePos.dx - h * 0.10, basePos.dy - h * 0.44);
    final Offset headTube = Offset(basePos.dx + h * 0.18, basePos.dy - h * 0.46);

    canvas.drawLine(rearWheelCenter, bb, framePaint);
    canvas.drawLine(bb, seatCluster, framePaint);
    canvas.drawLine(seatCluster, headTube, framePaint);
    canvas.drawLine(headTube, frontWheelCenter, framePaint);

    // Kolarz kucający przy tylnym kole podczas naprawy CO2
    final double crouchDrop = repairState.riderCrouchFactor * h * 0.38;
    final Offset riderHip = Offset(
      basePos.dx - h * 0.18,
      basePos.dy - h * 0.46 + crouchDrop,
    );
    final Offset riderHead = Offset(
      basePos.dx - h * 0.24,
      topPos.dy + h * 0.08 + crouchDrop * 1.15,
    );

    canvas.drawLine(
      riderHip,
      riderHead,
      Paint()
        ..color = AppColors.primaryAccent
        ..strokeWidth = (h * 0.18).clamp(3.0, 12.0)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      riderHead,
      h * 0.11,
      Paint()..color = const Color(0xFFF3F4F6),
    );

    // Animacja strumienia gazu CO2 przy pompowaniu opony
    if (repairState.co2JetIntensity > 0.02) {
      final double jetLen = h * (0.28 + 0.16 * math.sin(simulationTimeSeconds * 24.0));
      final Paint co2Paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.92 * repairState.co2JetIntensity),
            AppColors.cyanAccent.withValues(alpha: 0.55 * repairState.co2JetIntensity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: rearWheelCenter, radius: jetLen),
        );
      canvas.drawCircle(rearWheelCenter, jetLen, co2Paint);
    }

    return true;
  }

  void _paintAtmosphericDustVeil({
    required Canvas canvas,
    required Size size,
    required GravelRoadBiomePreset biome,
    required double dustDensity,
    required double simulationTimeSeconds,
  }) {
    final double horizonY = size.height * 0.43;
    final double pulse = 0.92 + 0.08 * math.sin(simulationTimeSeconds * 1.2);
    final double alpha = (dustDensity * 0.26 * pulse).clamp(0.0, 0.32);

    final Paint veilPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          biome.dustCloudColor.withValues(alpha: alpha),
          biome.dustCloudColor.withValues(alpha: alpha * 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 0.72, 1.0],
      ).createShader(
        Rect.fromLTWH(0, horizonY - 40, size.width, size.height * 0.45),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 40, size.width, size.height * 0.45),
      veilPaint,
    );
  }
}

// =============================================================================
// 5. CUSTOM PAINTER + RESPONSYWNY WIDGET VIEWPORTU 3D (390x844 / 1024x768 / 1600x900)
// =============================================================================

/// Painter przekazujący klatkę do [GravelWhiteRoadsAndDust3dRenderer].
class GravelWhiteRoadsAndDust3dPainter extends CustomPainter {
  final GravelWhiteRoadsAndDust3dRenderer renderer;
  final double cameraDistanceMeters;
  final double simulationTimeSeconds;
  final GravelRoad3dConfig config;
  final RoadsideTireRepairState repairState;
  final ValueChanged<GravelRoadFrameTelemetry>? onTelemetry;

  const GravelWhiteRoadsAndDust3dPainter({
    required this.renderer,
    required this.cameraDistanceMeters,
    required this.simulationTimeSeconds,
    required this.config,
    required this.repairState,
    this.onTelemetry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final GravelRoadFrameTelemetry telemetry = renderer.paintScene(
      canvas: canvas,
      size: size,
      cameraDistanceMeters: cameraDistanceMeters,
      simulationTimeSeconds: simulationTimeSeconds,
      config: config,
      repairState: repairState,
    );
    onTelemetry?.call(telemetry);
  }

  @override
  bool shouldRepaint(covariant GravelWhiteRoadsAndDust3dPainter oldDelegate) {
    return oldDelegate.cameraDistanceMeters != cameraDistanceMeters ||
        oldDelegate.simulationTimeSeconds != simulationTimeSeconds ||
        oldDelegate.config != config ||
        oldDelegate.repairState.overallProgress != repairState.overallProgress ||
        oldDelegate.repairState.isRepairActive != repairState.isRepairActive;
  }
}

/// Interaktywny viewport 3D białych dróg szutrowych z chmurami pyłu i panelem naprawy opony.
class GravelWhiteRoadsAndDust3dViewportWidget extends StatefulWidget {
  final GravelRoad3dConfig initialConfig;

  const GravelWhiteRoadsAndDust3dViewportWidget({
    super.key,
    this.initialConfig = const GravelRoad3dConfig(),
  });

  @override
  State<GravelWhiteRoadsAndDust3dViewportWidget> createState() =>
      _GravelWhiteRoadsAndDust3dViewportWidgetState();
}

class _GravelWhiteRoadsAndDust3dViewportWidgetState
    extends State<GravelWhiteRoadsAndDust3dViewportWidget>
    with SingleTickerProviderStateMixin {
  static const GravelWhiteRoadsAndDust3dRenderer _renderer =
      GravelWhiteRoadsAndDust3dRenderer();
  static const RoadsideTireRepairAnimator _repairAnimator =
      RoadsideTireRepairAnimator();

  late final AnimationController _ticker;
  late GravelRoad3dConfig _config;
  bool _isPaused = false;
  bool _isRepairActive = true;
  double _cameraDistanceMeters = 18.0;
  double _simulationTimeSeconds = 0.0;
  double _repairProgress = 0.42;
  GravelRoadFrameTelemetry? _lastTelemetry;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onTick);
    _ticker.repeat();
  }

  void _onTick() {
    if (_isPaused) return;
    setState(() {
      const double dt = 1.0 / 60.0;
      _simulationTimeSeconds += dt;
      _cameraDistanceMeters += (_config.riderSpeedKmh / 3.6) * dt * 0.45;
      if (_isRepairActive) {
        _repairProgress =
            (_repairProgress + dt / RoadsideTireRepairAnimator.totalRepairCycleSeconds) %
                1.0;
      }
    });
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  void _selectBiome(GravelRoadBiomePreset preset) {
    setState(() {
      _config = _config.copyWith(
        biomePreset: preset,
        dustDensity: preset.defaultDustDensity,
        windCrossSpeedMps: preset.windCrossSpeedMps,
      );
    });
  }

  void _triggerNewTireRepair() {
    setState(() {
      _isRepairActive = true;
      _repairProgress = 0.0;
      _config = _config.copyWith(showRoadsideRepairAnimation: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final RoadsideTireRepairState repairState = _repairAnimator.evaluate(
      isRepairActive: _isRepairActive,
      normalizedProgress: _repairProgress,
      roadHalfWidthMeters: _config.roadWidthMeters * 0.5,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 720;
        final bool isWideDesktop = constraints.maxWidth >= 1200;

        final Widget canvasArea = ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: GravelWhiteRoadsAndDust3dPainter(
                    renderer: _renderer,
                    cameraDistanceMeters: _cameraDistanceMeters,
                    simulationTimeSeconds: _simulationTimeSeconds,
                    config: _config,
                    repairState: repairState,
                    onTelemetry: (t) => _lastTelemetry = t,
                  ),
                ),
                if (_config.showTelemetryOverlay)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: isCompact ? 12 : null,
                    child: _GravelTelemetryHudBadge(
                      preset: _config.biomePreset,
                      telemetry: _lastTelemetry,
                      repairState: repairState,
                    ),
                  ),
              ],
            ),
          ),
        );

        final Widget controlPanel = Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: SingleChildScrollView(
            child: _buildControlPanelContent(
              isCompact: isCompact,
              repairState: repairState,
            ),
          ),
        );

        if (isCompact) {
          return Column(
            children: [
              Expanded(flex: 5, child: canvasArea),
              const SizedBox(height: 10),
              Expanded(flex: 4, child: controlPanel),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: isWideDesktop ? 7 : 6, child: canvasArea),
            const SizedBox(width: 14),
            SizedBox(
              width: isWideDesktop ? 360 : 300,
              child: controlPanel,
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlPanelContent({
    required bool isCompact,
    required RoadsideTireRepairState repairState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sterrato & Prerie 3D',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _GravelActionButton(
              label: _isPaused ? 'Wznów' : 'Pauza',
              icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              isActive: !_isPaused,
              onPressed: () => setState(() => _isPaused = !_isPaused),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Biom Szutrowy',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: GravelRoadBiomePreset.values.map((preset) {
            return _GravelActionButton(
              label: preset.shortTag,
              isActive: _config.biomePreset == preset,
              onPressed: () => _selectBiome(preset),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Gęstość Chmury Pyłu: ${(_config.dustDensity * 100).round()}%',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Slider(
          value: _config.dustDensity,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.goldAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: (v) => setState(
            () => _config = _config.copyWith(dustDensity: v),
          ),
        ),
        Text(
          'Prędkość Grupy: ${_config.riderSpeedKmh.toStringAsFixed(1)} km/h',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Slider(
          value: _config.riderSpeedKmh,
          min: 20.0,
          max: 52.0,
          activeColor: AppColors.primaryAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: (v) => setState(
            () => _config = _config.copyWith(riderSpeedKmh: v),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _GravelActionButton(
              label: 'Chmury Pyłu',
              isActive: _config.showDustClouds,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  showDustClouds: !_config.showDustClouds,
                ),
              ),
            ),
            _GravelActionButton(
              label: 'Roślinność',
              isActive: _config.showRoadsideVegetation,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  showRoadsideVegetation: !_config.showRoadsideVegetation,
                ),
              ),
            ),
            _GravelActionButton(
              label: 'Naprawa CO₂',
              icon: Icons.build_rounded,
              isActive: _isRepairActive,
              isDisabled: _isPaused,
              onPressed: _triggerNewTireRepair,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RoadsideRepairStatusCard(repairState: repairState),
      ],
    );
  }
}

class _GravelTelemetryHudBadge extends StatelessWidget {
  final GravelRoadBiomePreset preset;
  final GravelRoadFrameTelemetry? telemetry;
  final RoadsideTireRepairState repairState;

  const _GravelTelemetryHudBadge({
    required this.preset,
    required this.telemetry,
    required this.repairState,
  });

  @override
  Widget build(BuildContext context) {
    final double crr = telemetry?.currentCrrMultiplier ??
        preset.surfaceCategory.crrMultiplier;
    final int dustCount = telemetry?.dustParticlesRendered ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            preset.labelPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'CRR ×${crr.toStringAsFixed(2)} • Pył: $dustCount cz. • Pobocze: ${repairState.phase.shortTag}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RoadsideRepairStatusCard extends StatelessWidget {
  final RoadsideTireRepairState repairState;

  const _RoadsideRepairStatusCard({required this.repairState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tire_repair_rounded,
                size: 15,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  repairState.phase.labelPl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: repairState.overallProgress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.goldAccent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ciśnienie: ${repairState.tirePressureBar.toStringAsFixed(2)} bar • Czas: ${repairState.elapsedRepairSeconds.toStringAsFixed(1)} s',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Przycisk kontrolny z pełnymi stanami hover / active / disabled / focus.
class _GravelActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _GravelActionButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
    this.icon,
    this.isDisabled = false,
  });

  @override
  State<_GravelActionButton> createState() => _GravelActionButtonState();
}

class _GravelActionButtonState extends State<_GravelActionButton> {
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

    final Color textColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: textColor),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
