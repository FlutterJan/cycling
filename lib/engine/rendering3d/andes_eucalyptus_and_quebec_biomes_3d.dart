// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';

// =============================================================================
// 1. BIOMY GEOGRAFICZNE 3D: ANDY, BUSZ AUSTRALIJSKI ORAZ QUÉBEC & MONTRÉAL
// =============================================================================

/// Unikalne biomy geograficzne 3D dla ekspansji Ameryk i Oceanii:
/// Wysokie Andy, Australijski Busz i Wybrzeże Wiktorii oraz Jesienne Rundy w Québecu.
enum AndesEucalyptusQuebecBiome {
  highAndesArgentinaColombia(
    id: 'high_andes_argentina_colombia',
    labelPl: 'Wysokie Andy (Argentyna / Kolumbia)',
    shortTag: 'WYSOKIE ANDY',
    regionPl: 'Argentyna / Kolumbia • Alto del Colorado (3265 m n.p.m.)',
    descriptionPl:
        'Surowe, wielobarwne formacje skalne powyżej granicy lasu, kręte drogi '
        'szutrowo-asfaltowe na krawędzi przepaści, rozrzedzone błękitne niebo '
        'oraz kondory krążące nad przełęczą.',
    skyTopColor: Color(0xFF0A2454),
    skyHorizonColor: Color(0xFF8EC5EE),
    terrainBaseColor: Color(0xFF6B4C3B),
    terrainAccentColor: Color(0xFFB35D3C),
    roadSurfaceColor: Color(0xFF5A5652),
    roadEdgeColor: Color(0xFFA68B73),
    accentHighlightColor: Color(0xFF38BDF8),
    altitudeMeters: 3265.0,
    ambientTempCelsius: 7.5,
    humidityPercent: 28.0,
    defaultWindMps: 9.4,
    rollingResistanceMultiplier: 1.24,
    surfaceGripMu: 0.72,
    roadWidthMeters: 5.3,
    isCobblestone: false,
    hasCliffDropOff: true,
    hasOceanHorizon: false,
    baseGradientPercent: 9.6,
  ),
  australianBushVictoriaCoast(
    id: 'australian_bush_victoria_coast',
    labelPl: 'Australijski Busz i Wybrzeże Wiktorii',
    shortTag: 'BUSZ & WIKTORIA',
    regionPl: 'Australia • Adelaide / Geelong (45 m n.p.m.)',
    descriptionPl:
        'Lasy eukaliptusowe, czerwono-złota trawa w pełnym słońcu, błękitny '
        'Ocean Południowy w tle oraz tłumy kibiców w kapeluszach przeciwsłonecznych.',
    skyTopColor: Color(0xFF154E8A),
    skyHorizonColor: Color(0xFFF6D49A),
    terrainBaseColor: Color(0xFF9F4A28),
    terrainAccentColor: Color(0xFFD69F3D),
    roadSurfaceColor: Color(0xFF34383F),
    roadEdgeColor: Color(0xFFC97843),
    accentHighlightColor: Color(0xFFF59E0B),
    altitudeMeters: 45.0,
    ambientTempCelsius: 40.5,
    humidityPercent: 24.0,
    defaultWindMps: 11.2,
    rollingResistanceMultiplier: 1.08,
    surfaceGripMu: 0.84,
    roadWidthMeters: 7.4,
    isCobblestone: false,
    hasCliffDropOff: false,
    hasOceanHorizon: true,
    baseGradientPercent: 4.2,
  ),
  quebecMontrealAutumnCircuit(
    id: 'quebec_montreal_autumn_circuit',
    labelPl: 'Jesienne Rundy w Québec i Montréal',
    shortTag: 'QUÉBEC JESIEŃ',
    regionPl: 'Kanada • Stare Miasto Québec & Montréal (95 m n.p.m.)',
    descriptionPl:
        'Historyczne brukowane uliczki Starego Miasta, klony w ognistych '
        'jesiennych barwach czerwieni i złota oraz gęste barierki miejskie.',
    skyTopColor: Color(0xFF1F3C64),
    skyHorizonColor: Color(0xFFE9BA87),
    terrainBaseColor: Color(0xFF473B30),
    terrainAccentColor: Color(0xFFD94F2B),
    roadSurfaceColor: Color(0xFF52545A),
    roadEdgeColor: Color(0xFF8C7B6B),
    accentHighlightColor: Color(0xFFEF4444),
    altitudeMeters: 95.0,
    ambientTempCelsius: 13.5,
    humidityPercent: 58.0,
    defaultWindMps: 4.8,
    rollingResistanceMultiplier: 1.36,
    surfaceGripMu: 0.67,
    roadWidthMeters: 6.2,
    isCobblestone: true,
    hasCliffDropOff: false,
    hasOceanHorizon: false,
    baseGradientPercent: 7.8,
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
  final double roadWidthMeters;
  final bool isCobblestone;
  final bool hasCliffDropOff;
  final bool hasOceanHorizon;
  final double baseGradientPercent;

  const AndesEucalyptusQuebecBiome({
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
    required this.roadWidthMeters,
    required this.isCobblestone,
    required this.hasCliffDropOff,
    required this.hasOceanHorizon,
    required this.baseGradientPercent,
  });
}

/// Presety kamery 3D dla biomów Andy / Busz Australijski / Québec.
enum AndesEucalyptusQuebecCameraPreset {
  pelotonChase(
    id: 'peloton_chase',
    labelPl: 'Pościg',
    heightMeters: 2.7,
    fovDegrees: 58.0,
    pitchRadians: -0.06,
  ),
  helicopterPan(
    id: 'helicopter_pan',
    labelPl: 'Helikopter',
    heightMeters: 10.5,
    fovDegrees: 52.0,
    pitchRadians: -0.20,
  ),
  cliffEdgeSide(
    id: 'cliff_edge_side',
    labelPl: 'Krawędź',
    heightMeters: 3.8,
    fovDegrees: 62.0,
    pitchRadians: -0.09,
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

  const AndesEucalyptusQuebecCameraPreset({
    required this.id,
    required this.labelPl,
    required this.heightMeters,
    required this.fovDegrees,
    required this.pitchRadians,
  });
}

// =============================================================================
// 2. MODELE KONFIGURACJI, OBIEKTÓW SCENERII 3D I STANU KLATKI
// =============================================================================

/// Konfiguracja generatora scenerii 3D dla biomów Andy, Wiktoria i Québec.
class AndesEucalyptusQuebecConfig {
  final AndesEucalyptusQuebecBiome biome;
  final AndesEucalyptusQuebecCameraPreset cameraPreset;
  final double drawDistanceMeters;
  final double sliceStepMeters;
  final double propDensity;
  final double weatherIntensity;
  final bool enableSurfaceVibration;
  final bool enableDynamicWildlife;

  const AndesEucalyptusQuebecConfig({
    this.biome = AndesEucalyptusQuebecBiome.highAndesArgentinaColombia,
    this.cameraPreset = AndesEucalyptusQuebecCameraPreset.pelotonChase,
    this.drawDistanceMeters = 260.0,
    this.sliceStepMeters = 7.5,
    this.propDensity = 1.0,
    this.weatherIntensity = 0.75,
    this.enableSurfaceVibration = true,
    this.enableDynamicWildlife = true,
  });

  AndesEucalyptusQuebecConfig copyWith({
    AndesEucalyptusQuebecBiome? biome,
    AndesEucalyptusQuebecCameraPreset? cameraPreset,
    double? drawDistanceMeters,
    double? sliceStepMeters,
    double? propDensity,
    double? weatherIntensity,
    bool? enableSurfaceVibration,
    bool? enableDynamicWildlife,
  }) {
    return AndesEucalyptusQuebecConfig(
      biome: biome ?? this.biome,
      cameraPreset: cameraPreset ?? this.cameraPreset,
      drawDistanceMeters: drawDistanceMeters ?? this.drawDistanceMeters,
      sliceStepMeters: sliceStepMeters ?? this.sliceStepMeters,
      propDensity: propDensity ?? this.propDensity,
      weatherIntensity: weatherIntensity ?? this.weatherIntensity,
      enableSurfaceVibration:
          enableSurfaceVibration ?? this.enableSurfaceVibration,
      enableDynamicWildlife:
          enableDynamicWildlife ?? this.enableDynamicWildlife,
    );
  }
}

/// Rodzaje obiektów 3D rozmieszczanych wzdłuż trasy.
enum AndesEucalyptusQuebecPropKind {
  // Wysokie Andy
  multicolorAndeanRockStrata,
  precipiceGuardStone,
  circlingAndeanCondor,
  highlandScrubTuft,
  // Australijski Busz & Wiktoria
  eucalyptusGumTree,
  redGoldBushGrass,
  sunHatSpectatorCrowd,
  coastalOceanCliffBeacon,
  // Jesienny Québec & Montréal
  fieryAutumnMapleTree,
  oldTownHistoricFacade,
  denseUrbanRaceBarrier,
  autumnBannerArchway,
}

/// Pojedynczy obiekt scenerii 3D zakotwiczony w układzie trasy.
class AndesEucalyptusQuebecProp3D {
  final String id;
  final AndesEucalyptusQuebecPropKind kind;
  final Vector3 worldPosition;
  final double distanceAlongCourseMeters;
  final double scale;
  final double heightMeters;
  final double widthMeters;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final double phaseOffset;
  final bool isLeftSide;

  const AndesEucalyptusQuebecProp3D({
    required this.id,
    required this.kind,
    required this.worldPosition,
    required this.distanceAlongCourseMeters,
    required this.scale,
    required this.heightMeters,
    required this.widthMeters,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    this.phaseOffset = 0.0,
    this.isLeftSide = true,
  });
}

/// Wycinek wstęgi drogi 3D (szutrowo-asfaltowej, asfaltu lub miejskiego bruku).
class AndesEucalyptusQuebecRoadSlice3D {
  final double distanceMeters;
  final Vector3 centerWorld;
  final double halfWidthMeters;
  final double slopeRadians;
  final double bankingRadians;
  final bool hasGravelPatches;
  final bool hasCobbleJoints;
  final bool hasCliffDropOnRight;

  const AndesEucalyptusQuebecRoadSlice3D({
    required this.distanceMeters,
    required this.centerWorld,
    required this.halfWidthMeters,
    required this.slopeRadians,
    this.bankingRadians = 0.0,
    this.hasGravelPatches = false,
    this.hasCobbleJoints = false,
    this.hasCliffDropOnRight = false,
  });
}

/// Cząsteczka atmosferyczna lub przyrodnicza 3D (pył andyjski, żar buszu, liście klonu).
class AndesEucalyptusQuebecParticle3D {
  final Vector3 worldPosition;
  final double sizePx;
  final double opacity;
  final Color color;
  final double rotationRadians;
  final bool isMapleLeaf;

  const AndesEucalyptusQuebecParticle3D({
    required this.worldPosition,
    required this.sizePx,
    required this.opacity,
    required this.color,
    this.rotationRadians = 0.0,
    this.isMapleLeaf = false,
  });
}

/// Marker kolarza 3D na wstędze drogi.
class AndesEucalyptusQuebecRiderMarker3D {
  final String id;
  final String teamCode;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final Color jerseyColor;
  final Color helmetColor;
  final double cadencePhaseRad;
  final bool isOutOfSaddle;

  const AndesEucalyptusQuebecRiderMarker3D({
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

/// Kompletny stan pojedynczej klatki 3D dla biomów Andy, Wiktoria i Québec.
class AndesEucalyptusQuebecFrameState {
  final AndesEucalyptusQuebecBiome biome;
  final AndesEucalyptusQuebecCameraPreset cameraPreset;
  final double cameraDistanceMeters;
  final double cameraHeightMeters;
  final double cameraYawRadians;
  final double cameraPitchRadians;
  final double cameraFovDegrees;
  final double cameraVibrationOffsetPx;
  final double heatShimmerAmplitudePx;
  final double effectiveWindMps;
  final double effectiveCrrMultiplier;
  final double airDensityKgM3;
  final double visibilityRangeMeters;
  final double elapsedSeconds;
  final List<AndesEucalyptusQuebecRoadSlice3D> roadSlices;
  final List<AndesEucalyptusQuebecProp3D> visibleProps;
  final List<AndesEucalyptusQuebecParticle3D> particles;
  final List<AndesEucalyptusQuebecRiderMarker3D> pelotonMarkers;

  const AndesEucalyptusQuebecFrameState({
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
    required this.airDensityKgM3,
    required this.visibilityRangeMeters,
    required this.elapsedSeconds,
    required this.roadSlices,
    required this.visibleProps,
    required this.particles,
    required this.pelotonMarkers,
  });
}

// =============================================================================
// 3. GENERATOR SCENERII 3D (AndesEucalyptusAndQuebecBiomes3d)
// =============================================================================

/// Generator scenerii 3D dla 3 unikalnych biomów geograficznych:
/// 1. Wysokie Andy (Argentyna / Kolumbia)
/// 2. Australijski Busz i Wybrzeże Wiktorii (Adelaide / Geelong)
/// 3. Jesienne Rundy w Québec i Montréal
class AndesEucalyptusAndQuebecBiomes3d {
  const AndesEucalyptusAndQuebecBiomes3d();

  /// Zwraca pozycję osi X trasy [m] dla danego dystansu [m].
  double courseCenterX(
    AndesEucalyptusQuebecBiome biome,
    double distanceMeters,
  ) {
    switch (biome) {
      case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
        // Kręte serpentyny andyjskie na krawędzi przepaści
        return math.sin(distanceMeters * 0.024) * 14.5 +
            math.cos(distanceMeters * 0.008) * 7.0;
      case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
        // Długie nadmorskie łuki wzdłuż Great Ocean Road
        return math.sin(distanceMeters * 0.009) * 16.0 +
            math.sin(distanceMeters * 0.0035) * 6.0;
      case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
        // Dynamiczne miejskie zakręty rund w Starym Mieście
        return math.sin(distanceMeters * 0.019) * 11.0 +
            math.cos(distanceMeters * 0.011) * 5.5;
    }
  }

  /// Zwraca elewację osi trasy [m] dla danego dystansu [m].
  double courseCenterY(
    AndesEucalyptusQuebecBiome biome,
    double distanceMeters,
  ) {
    switch (biome) {
      case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
        return distanceMeters * 0.096 + math.sin(distanceMeters * 0.018) * 1.6;
      case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
        return distanceMeters * 0.042 + math.sin(distanceMeters * 0.014) * 1.9;
      case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
        return distanceMeters * 0.078 + math.sin(distanceMeters * 0.022) * 1.4;
    }
  }

  /// Zwraca kąt nachylenia podłużnego trasy w radianach.
  double courseSlopeRadians(
    AndesEucalyptusQuebecBiome biome,
    double distanceMeters,
  ) {
    const double delta = 2.0;
    final double dy = courseCenterY(biome, distanceMeters + delta) -
        courseCenterY(biome, distanceMeters - delta);
    return math.atan2(dy, delta * 2.0);
  }

  /// Oblicza gęstość powietrza $\rho$ [kg/m³] na podstawie wysokości i temperatury.
  double computeAirDensityKgM3(AndesEucalyptusQuebecBiome biome) {
    // Barometryczne przybliżenie ISA z poprawką temperaturową
    final double pressureRatio =
        math.pow(1.0 - 2.25577e-5 * biome.altitudeMeters, 5.25588).toDouble();
    final double tempKelvin = biome.ambientTempCelsius + 273.15;
    return (1.225 * pressureRatio) * (288.15 / tempKelvin);
  }

  /// Rzutuje punkt świata 3D na płaszczyznę ekranu 2D.
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
    final double xYaw = dx * cosYaw - dz * sinYaw;
    final double zYaw = dx * sinYaw + dz * cosYaw;

    final double cosPitch = math.cos(-cameraPitchRadians);
    final double sinPitch = math.sin(-cameraPitchRadians);
    final double yCam = dy * cosPitch - zYaw * sinPitch;
    final double zCam = dy * sinPitch + zYaw * cosPitch;

    if (zCam <= 0.65) {
      return null;
    }

    final double fovRad = fovDegrees * math.pi / 180.0;
    final double focal =
        (viewportSize.height * 0.5) / math.tan(fovRad * 0.5);
    final double screenX = (viewportSize.width * 0.5) + (xYaw / zCam) * focal;
    final double screenY = (viewportSize.height * 0.5) - (yCam / zCam) * focal;
    return Offset(screenX, screenY);
  }

  /// Buduje kompletną klatkę scenerii 3D dla wybranego biomu i pozycji kamery.
  AndesEucalyptusQuebecFrameState buildFrame({
    required AndesEucalyptusQuebecConfig config,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    final AndesEucalyptusQuebecBiome biome = config.biome;
    final AndesEucalyptusQuebecCameraPreset preset = config.cameraPreset;
    final double weather = config.weatherIntensity.clamp(0.0, 1.5);
    final double density = config.propDensity.clamp(0.3, 1.6);

    final double camX = courseCenterX(biome, cameraDistanceMeters);
    final double camY = courseCenterY(biome, cameraDistanceMeters);
    final double aheadX = courseCenterX(biome, cameraDistanceMeters + 16.0);
    final double cameraYaw = math.atan2(aheadX - camX, 16.0) * 0.55;
    final double slopePitch = courseSlopeRadians(biome, cameraDistanceMeters);

    final double cameraVibration = _computeCameraVibrationPx(
      biome: biome,
      enabled: config.enableSurfaceVibration,
      elapsedSeconds: elapsedSeconds,
    );

    final double heatShimmer =
        biome == AndesEucalyptusQuebecBiome.australianBushVictoriaCoast
            ? (1.2 + weather * 1.4)
            : 0.0;

    final double effectiveWind =
        biome.defaultWindMps * (0.65 + weather * 0.65);

    final double effectiveCrr = _computeEffectiveCrr(
      biome: biome,
      weather: weather,
    );

    final double visibilityRange = _computeVisibilityRangeMeters(
      biome: biome,
      drawDistance: config.drawDistanceMeters,
      weather: weather,
    );

    final List<AndesEucalyptusQuebecRoadSlice3D> slices = _buildRoadSlices(
      biome: biome,
      startDist: cameraDistanceMeters - 6.0,
      endDist: cameraDistanceMeters + config.drawDistanceMeters,
      stepMeters: config.sliceStepMeters,
    );

    final List<AndesEucalyptusQuebecProp3D> props = _buildVisibleProps(
      biome: biome,
      startDist: cameraDistanceMeters + 4.0,
      endDist: cameraDistanceMeters + config.drawDistanceMeters,
      density: density,
      elapsedSeconds: elapsedSeconds,
      enableDynamicWildlife: config.enableDynamicWildlife,
    );

    final List<AndesEucalyptusQuebecParticle3D> particles = _buildParticles(
      biome: biome,
      cameraDistanceMeters: cameraDistanceMeters,
      cameraBaseY: camY,
      elapsedSeconds: elapsedSeconds,
      weather: weather,
    );

    final List<AndesEucalyptusQuebecRiderMarker3D> pelotonMarkers =
        _buildPelotonMarkers(
      biome: biome,
      cameraDistanceMeters: cameraDistanceMeters,
      elapsedSeconds: elapsedSeconds,
    );

    return AndesEucalyptusQuebecFrameState(
      biome: biome,
      cameraPreset: preset,
      cameraDistanceMeters: cameraDistanceMeters,
      cameraHeightMeters: camY + preset.heightMeters,
      cameraYawRadians: cameraYaw,
      cameraPitchRadians: preset.pitchRadians + slopePitch * 0.48,
      cameraFovDegrees: preset.fovDegrees,
      cameraVibrationOffsetPx: cameraVibration,
      heatShimmerAmplitudePx: heatShimmer,
      effectiveWindMps: effectiveWind,
      effectiveCrrMultiplier: effectiveCrr,
      airDensityKgM3: computeAirDensityKgM3(biome),
      visibilityRangeMeters: visibilityRange,
      elapsedSeconds: elapsedSeconds,
      roadSlices: slices,
      visibleProps: props,
      particles: particles,
      pelotonMarkers: pelotonMarkers,
    );
  }

  double _computeCameraVibrationPx({
    required AndesEucalyptusQuebecBiome biome,
    required bool enabled,
    required double elapsedSeconds,
  }) {
    if (!enabled) return 0.0;
    switch (biome) {
      case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
        // Wyraźne drgania na historycznym bruku Starego Miasta
        return math.sin(elapsedSeconds * 44.0) * 1.45 +
            math.cos(elapsedSeconds * 27.0) * 0.65;
      case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
        // Szutrowe odcinki andyjskiej drogi na przełęczy
        return math.sin(elapsedSeconds * 31.0) * 0.95;
      case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
        return math.sin(elapsedSeconds * 18.0) * 0.25;
    }
  }

  double _computeEffectiveCrr({
    required AndesEucalyptusQuebecBiome biome,
    required double weather,
  }) {
    switch (biome) {
      case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
        return biome.rollingResistanceMultiplier + weather * 0.06;
      case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
        // Upał >40°C podnosi temperaturę asfaltu do 58°C (+8% Crr)
        return biome.rollingResistanceMultiplier + weather * 0.05;
      case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
        return biome.rollingResistanceMultiplier + weather * 0.04;
    }
  }

  double _computeVisibilityRangeMeters({
    required AndesEucalyptusQuebecBiome biome,
    required double drawDistance,
    required double weather,
  }) {
    switch (biome) {
      case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
        // Krystalicznie czyste, rozrzedzone powietrze na 3265 m n.p.m.
        return drawDistance * (1.08 - weather * 0.08);
      case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
        return drawDistance * (0.98 - weather * 0.14);
      case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
        return drawDistance * (0.92 - weather * 0.12);
    }
  }

  List<AndesEucalyptusQuebecRoadSlice3D> _buildRoadSlices({
    required AndesEucalyptusQuebecBiome biome,
    required double startDist,
    required double endDist,
    required double stepMeters,
  }) {
    final List<AndesEucalyptusQuebecRoadSlice3D> slices =
        <AndesEucalyptusQuebecRoadSlice3D>[];
    final double halfWidth = biome.roadWidthMeters * 0.5;
    for (double d = startDist; d <= endDist; d += stepMeters) {
      final double cx = courseCenterX(biome, d);
      final double cy = courseCenterY(biome, d);
      final double slope = courseSlopeRadians(biome, d);
      final double nextCx = courseCenterX(biome, d + stepMeters);
      final double lateralCurve = (nextCx - cx) / stepMeters;
      slices.add(
        AndesEucalyptusQuebecRoadSlice3D(
          distanceMeters: d,
          centerWorld: Vector3(cx, cy, d),
          halfWidthMeters: halfWidth,
          slopeRadians: slope,
          bankingRadians: (lateralCurve * 0.07).clamp(-0.08, 0.08),
          hasGravelPatches:
              biome == AndesEucalyptusQuebecBiome.highAndesArgentinaColombia,
          hasCobbleJoints: biome.isCobblestone,
          hasCliffDropOnRight: biome.hasCliffDropOff,
        ),
      );
    }
    return slices;
  }

  List<AndesEucalyptusQuebecProp3D> _buildVisibleProps({
    required AndesEucalyptusQuebecBiome biome,
    required double startDist,
    required double endDist,
    required double density,
    required double elapsedSeconds,
    required bool enableDynamicWildlife,
  }) {
    final List<AndesEucalyptusQuebecProp3D> props =
        <AndesEucalyptusQuebecProp3D>[];
    final double step = (15.0 / density).clamp(7.0, 26.0);
    final double firstSlot = (startDist / step).floor() * step;

    for (double d = firstSlot; d <= endDist; d += step) {
      if (d < startDist) continue;
      final int slotIndex = (d / step).round();
      final double cx = courseCenterX(biome, d);
      final double cy = courseCenterY(biome, d);
      final double halfRoad = biome.roadWidthMeters * 0.5;

      switch (biome) {
        case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
          _appendHighAndesProps(
            props: props,
            slotIndex: slotIndex,
            d: d,
            cx: cx,
            cy: cy,
            halfRoad: halfRoad,
            elapsedSeconds: elapsedSeconds,
            enableDynamicWildlife: enableDynamicWildlife,
          );
          break;
        case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
          _appendAustralianBushProps(
            props: props,
            slotIndex: slotIndex,
            d: d,
            cx: cx,
            cy: cy,
            halfRoad: halfRoad,
          );
          break;
        case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
          _appendQuebecAutumnProps(
            props: props,
            slotIndex: slotIndex,
            d: d,
            cx: cx,
            cy: cy,
            halfRoad: halfRoad,
          );
          break;
      }
    }

    // Sortowanie od najdalszych do najbliższych (algorytm malarza)
    props.sort(
      (a, b) =>
          b.distanceAlongCourseMeters.compareTo(a.distanceAlongCourseMeters),
    );
    return props;
  }

  void _appendHighAndesProps({
    required List<AndesEucalyptusQuebecProp3D> props,
    required int slotIndex,
    required double d,
    required double cx,
    required double cy,
    required double halfRoad,
    required double elapsedSeconds,
    required bool enableDynamicWildlife,
  }) {
    // 1. Wielobarwne formacje skalne po lewej (ściana andyjska powyżej granicy lasu)
    const List<Color> strataPrimary = <Color>[
      Color(0xFFA94D32), // Terakota
      Color(0xFFC58A3C), // Ochra złocista
      Color(0xFF6B5368), // Łupek fioletowy
      Color(0xFF8C3B2B), // Rdzawy hematyt
    ];
    const List<Color> strataSecondary = <Color>[
      Color(0xFFD89D58),
      Color(0xFF7D6B5D),
      Color(0xFF4F667A),
      Color(0xFFD0C4A8),
    ];
    const List<Color> strataTertiary = <Color>[
      Color(0xFF51443C),
      Color(0xFF9E5A3E),
      Color(0xFFC9A66B),
      Color(0xFF3E4C59),
    ];

    final int rockVariant = slotIndex.abs() % strataPrimary.length;
    final double rockScale = 1.0 + (slotIndex.abs() % 4) * 0.28;
    props.add(
      AndesEucalyptusQuebecProp3D(
        id: 'andes_rock_$slotIndex',
        kind: AndesEucalyptusQuebecPropKind.multicolorAndeanRockStrata,
        worldPosition: Vector3(cx - halfRoad - 9.5, cy + 2.5, d),
        distanceAlongCourseMeters: d,
        scale: rockScale,
        heightMeters: 16.0 * rockScale,
        widthMeters: 15.0 * rockScale,
        primaryColor: strataPrimary[rockVariant],
        secondaryColor: strataSecondary[rockVariant],
        tertiaryColor: strataTertiary[rockVariant],
        phaseOffset: slotIndex * 0.5,
        isLeftSide: true,
      ),
    );

    // 2. Słupki kamienne / barierki ostrzegawcze na krawędzi przepaści po prawej
    props.add(
      AndesEucalyptusQuebecProp3D(
        id: 'andes_guard_$slotIndex',
        kind: AndesEucalyptusQuebecPropKind.precipiceGuardStone,
        worldPosition: Vector3(cx + halfRoad + 0.45, cy, d),
        distanceAlongCourseMeters: d,
        scale: 1.0,
        heightMeters: 0.95,
        widthMeters: 0.45,
        primaryColor: const Color(0xFFD6D3CE),
        secondaryColor: const Color(0xFFF59E0B),
        tertiaryColor: const Color(0xFF4B4742),
        isLeftSide: false,
      ),
    );

    // 3. Kępy suchej trawy wysokogórskiej (ichu) na poboczu lewym
    if (slotIndex % 2 == 0) {
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'andes_scrub_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.highlandScrubTuft,
          worldPosition: Vector3(cx - halfRoad - 2.1, cy, d + 2.0),
          distanceAlongCourseMeters: d + 2.0,
          scale: 0.9,
          heightMeters: 0.8,
          widthMeters: 1.4,
          primaryColor: const Color(0xFFA79052),
          secondaryColor: const Color(0xFF7D6B3C),
          tertiaryColor: const Color(0xFF5B4D35),
          phaseOffset: slotIndex * 0.9,
          isLeftSide: true,
        ),
      );
    }

    // 4. Kondory andyjskie krążące w prądach wznoszących nad przełęczą
    if (enableDynamicWildlife && slotIndex % 4 == 1) {
      final double orbitAngle = elapsedSeconds * 0.55 + slotIndex * 1.1;
      final double condorX = cx + 8.0 + math.cos(orbitAngle) * 14.0;
      final double condorY = cy + 16.5 + math.sin(orbitAngle * 1.3) * 2.4;
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'andes_condor_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.circlingAndeanCondor,
          worldPosition: Vector3(condorX, condorY, d + 6.0),
          distanceAlongCourseMeters: d + 6.0,
          scale: 1.15,
          heightMeters: 1.2,
          widthMeters: 3.2, // Rozpiętość skrzydeł kondora ~3.2 m
          primaryColor: const Color(0xFF181A1F),
          secondaryColor: const Color(0xFFF3F4F6), // Biały kołnierz
          tertiaryColor: const Color(0xFF9E5A4C),
          phaseOffset: orbitAngle,
          isLeftSide: false,
        ),
      );
    }
  }

  void _appendAustralianBushProps({
    required List<AndesEucalyptusQuebecProp3D> props,
    required int slotIndex,
    required double d,
    required double cx,
    required double cy,
    required double halfRoad,
  }) {
    // 1. Drzewa eukaliptusowe po stronie lądu (lewa strona) oraz sporadycznie po prawej
    final double treeHeight = 11.0 + (slotIndex.abs() % 4) * 2.2;
    props.add(
      AndesEucalyptusQuebecProp3D(
        id: 'aus_eucalyptus_l_$slotIndex',
        kind: AndesEucalyptusQuebecPropKind.eucalyptusGumTree,
        worldPosition: Vector3(cx - halfRoad - 6.8, cy, d),
        distanceAlongCourseMeters: d,
        scale: 1.0 + (slotIndex.abs() % 3) * 0.15,
        heightMeters: treeHeight,
        widthMeters: 6.4,
        primaryColor: const Color(0xFF4B7356), // Szałwiowo-oliwkowe liście
        secondaryColor: const Color(0xFF6B8E70),
        tertiaryColor: const Color(0xFFD5CCC0), // Jasna kora eukaliptusa
        phaseOffset: slotIndex * 0.7,
        isLeftSide: true,
      ),
    );

    if (slotIndex % 3 == 0) {
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'aus_eucalyptus_r_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.eucalyptusGumTree,
          worldPosition: Vector3(cx + halfRoad + 9.2, cy - 0.5, d + 4.0),
          distanceAlongCourseMeters: d + 4.0,
          scale: 0.92,
          heightMeters: 9.5,
          widthMeters: 5.5,
          primaryColor: const Color(0xFF426A4D),
          secondaryColor: const Color(0xFF638466),
          tertiaryColor: const Color(0xFFCCC2B5),
          phaseOffset: slotIndex * 1.1,
          isLeftSide: false,
        ),
      );
    }

    // 2. Czerwono-złota trawa buszu w pełnym słońcu po obu stronach pobocza
    props.add(
      AndesEucalyptusQuebecProp3D(
        id: 'aus_grass_l_$slotIndex',
        kind: AndesEucalyptusQuebecPropKind.redGoldBushGrass,
        worldPosition: Vector3(cx - halfRoad - 2.3, cy, d + 1.5),
        distanceAlongCourseMeters: d + 1.5,
        scale: 1.0,
        heightMeters: 1.05,
        widthMeters: 2.8,
        primaryColor: const Color(0xFFD99B26), // Złocista trawa
        secondaryColor: const Color(0xFFB54A28), // Czerwona ziemia / trawa
        tertiaryColor: const Color(0xFF8C391F),
        phaseOffset: slotIndex * 0.4,
        isLeftSide: true,
      ),
    );

    // 3. Tłumy kibiców w kapeluszach przeciwsłonecznych przy trasie
    if (slotIndex % 2 == 0) {
      final bool leftCrowd = slotIndex % 4 == 0;
      final double crowdX =
          leftCrowd ? cx - halfRoad - 1.6 : cx + halfRoad + 1.7;
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'aus_crowd_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.sunHatSpectatorCrowd,
          worldPosition: Vector3(crowdX, cy, d + 2.5),
          distanceAlongCourseMeters: d + 2.5,
          scale: 1.0,
          heightMeters: 1.85,
          widthMeters: 3.4,
          primaryColor: const Color(0xFFE5C47D), // Słomkowy kapelusz
          secondaryColor: const Color(0xFF38BDF8), // Letnie koszulki
          tertiaryColor: const Color(0xFFF59E0B), // Złoty akcent
          phaseOffset: slotIndex * 1.3,
          isLeftSide: leftCrowd,
        ),
      );
    }

    // 4. Nadmorskie skały i słupki widokowe przy wybrzeżu Wiktorii
    if (slotIndex % 4 == 2) {
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'aus_coast_beacon_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.coastalOceanCliffBeacon,
          worldPosition: Vector3(cx + halfRoad + 2.4, cy - 0.3, d),
          distanceAlongCourseMeters: d,
          scale: 1.0,
          heightMeters: 1.4,
          widthMeters: 2.2,
          primaryColor: const Color(0xFFC87D4B),
          secondaryColor: const Color(0xFFF3F4F6),
          tertiaryColor: const Color(0xFF0E7490),
          isLeftSide: false,
        ),
      );
    }
  }

  void _appendQuebecAutumnProps({
    required List<AndesEucalyptusQuebecProp3D> props,
    required int slotIndex,
    required double d,
    required double cx,
    required double cy,
    required double halfRoad,
  }) {
    // 1. Gęste barierki miejskie po obu stronach brukowanej uliczki
    for (final bool isLeft in <bool>[true, false]) {
      final double bx =
          isLeft ? cx - halfRoad - 0.55 : cx + halfRoad + 0.55;
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'qc_barrier_${isLeft ? "l" : "r"}_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.denseUrbanRaceBarrier,
          worldPosition: Vector3(bx, cy, d),
          distanceAlongCourseMeters: d,
          scale: 1.0,
          heightMeters: 1.15,
          widthMeters: 2.6,
          primaryColor: const Color(0xFFD1D5DB), // Stalowa barierka
          secondaryColor:
              isLeft ? const Color(0xFF8E4A49) : const Color(0xFFD4AF37),
          tertiaryColor: const Color(0xFF1F2937),
          isLeftSide: isLeft,
        ),
      );
    }

    // 2. Klony w ognistych jesiennych barwach czerwieni i złota
    final bool fieryRed = slotIndex.isEven;
    final double mapleX =
        fieryRed ? cx - halfRoad - 3.6 : cx + halfRoad + 3.8;
    props.add(
      AndesEucalyptusQuebecProp3D(
        id: 'qc_maple_$slotIndex',
        kind: AndesEucalyptusQuebecPropKind.fieryAutumnMapleTree,
        worldPosition: Vector3(mapleX, cy, d + 1.2),
        distanceAlongCourseMeters: d + 1.2,
        scale: 1.0 + (slotIndex.abs() % 3) * 0.14,
        heightMeters: 9.2,
        widthMeters: 5.8,
        primaryColor:
            fieryRed ? const Color(0xFFD62828) : const Color(0xFFF77F00),
        secondaryColor: const Color(0xFFFCBF49), // Złoto jesienne
        tertiaryColor: const Color(0xFF4A3525), // Pień klonu
        phaseOffset: slotIndex * 0.8,
        isLeftSide: fieryRed,
      ),
    );

    // 3. Historyczne kamienice Starego Miasta Québec / Montréal
    if (slotIndex % 2 == 0) {
      final bool leftSide = slotIndex % 4 == 0;
      final double hx =
          leftSide ? cx - halfRoad - 8.2 : cx + halfRoad + 8.2;
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'qc_facade_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.oldTownHistoricFacade,
          worldPosition: Vector3(hx, cy, d + 3.0),
          distanceAlongCourseMeters: d + 3.0,
          scale: 1.0,
          heightMeters: 12.5 + (slotIndex.abs() % 3) * 1.8,
          widthMeters: 8.5,
          primaryColor: const Color(0xFF7B6D62), // Kamienna elewacja
          secondaryColor: const Color(0xFF2B3A42), // Spadzisty dach miedziano-łupkowy
          tertiaryColor: const Color(0xFFFDE68A), // Ciepłe okna
          isLeftSide: leftSide,
        ),
      );
    }

    // 4. Brama miejska rundy Grand Prix Cycliste co 8 slotów
    if (slotIndex % 8 == 3) {
      props.add(
        AndesEucalyptusQuebecProp3D(
          id: 'qc_arch_$slotIndex',
          kind: AndesEucalyptusQuebecPropKind.autumnBannerArchway,
          worldPosition: Vector3(cx, cy, d),
          distanceAlongCourseMeters: d,
          scale: 1.0,
          heightMeters: 5.8,
          widthMeters: halfRoad * 2.0 + 1.4,
          primaryColor: const Color(0xFF8E4A49),
          secondaryColor: const Color(0xFFD4AF37),
          tertiaryColor: const Color(0xFF181B22),
          isLeftSide: true,
        ),
      );
    }
  }

  List<AndesEucalyptusQuebecParticle3D> _buildParticles({
    required AndesEucalyptusQuebecBiome biome,
    required double cameraDistanceMeters,
    required double cameraBaseY,
    required double elapsedSeconds,
    required double weather,
  }) {
    final List<AndesEucalyptusQuebecParticle3D> list =
        <AndesEucalyptusQuebecParticle3D>[];
    final int count = (24 * weather.clamp(0.25, 1.5)).round();

    for (int i = 0; i < count; i++) {
      final double seed = i * 19.37;
      final double zOffset =
          ((seed * 7.3 + elapsedSeconds * 16.0) % 130.0) + 4.0;
      final double d = cameraDistanceMeters + zOffset;
      final double cx = courseCenterX(biome, d);
      final double cy = courseCenterY(biome, d);
      final double lateral = math.sin(seed + elapsedSeconds * 0.7) * 9.0;

      switch (biome) {
        case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
          // Drobny pył mineralny niesiony wiatrem wysokogórskim
          final double height = cy + 0.4 + ((seed + elapsedSeconds * 2.0) % 3.5);
          list.add(
            AndesEucalyptusQuebecParticle3D(
              worldPosition: Vector3(cx + lateral, height, d),
              sizePx: 2.8 + (i % 3) * 1.1,
              opacity: 0.34,
              color: const Color(0xFFD9C7B0),
              rotationRadians: elapsedSeconds + seed,
            ),
          );
          break;
        case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
          // Złote drobinki pyłku eukaliptusa i morskiej bryzy w słońcu
          final double height =
              cy + 0.6 + ((seed + elapsedSeconds * 1.4) % 4.2);
          list.add(
            AndesEucalyptusQuebecParticle3D(
              worldPosition: Vector3(cx + lateral, height, d),
              sizePx: 3.2 + (i % 3) * 1.3,
              opacity: 0.30,
              color: i.isEven
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFBAE6FD),
              rotationRadians: elapsedSeconds * 0.8 + seed,
            ),
          );
          break;
        case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
          // Wirujące czerwono-złote liście klonu opadające na bruk
          final double fall = (seed + elapsedSeconds * 2.2) % 6.0;
          final double height = cy + 6.2 - fall;
          list.add(
            AndesEucalyptusQuebecParticle3D(
              worldPosition: Vector3(cx + lateral, height, d),
              sizePx: 5.5 + (i % 3) * 1.6,
              opacity: 0.86,
              color: i % 3 == 0
                  ? const Color(0xFFDC2626)
                  : (i % 3 == 1
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEA580C)),
              rotationRadians: elapsedSeconds * 2.4 + seed,
              isMapleLeaf: true,
            ),
          );
          break;
      }
    }
    return list;
  }

  List<AndesEucalyptusQuebecRiderMarker3D> _buildPelotonMarkers({
    required AndesEucalyptusQuebecBiome biome,
    required double cameraDistanceMeters,
    required double elapsedSeconds,
  }) {
    const List<Color> jerseys = <Color>[
      AppColors.goldAccent,
      AppColors.accentBlue,
      AppColors.primaryAccent,
      AppColors.statusSuccess,
      Color(0xFFF97316),
      Color(0xFFE5E7EB),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF14B8A6),
    ];
    const List<String> codes = <String>[
      'COL',
      'AUS',
      'CAN',
      'ARG',
      'PPM',
      'UAE',
      'VIS',
      'INE',
      'SOQ',
    ];

    final List<AndesEucalyptusQuebecRiderMarker3D> riders =
        <AndesEucalyptusQuebecRiderMarker3D>[];
    for (int i = 0; i < 9; i++) {
      final double distAhead =
          12.0 + (i ~/ 3) * 4.5 + math.sin(elapsedSeconds + i) * 0.5;
      final double lateral = ((i % 3) - 1) * 1.25 +
          math.sin(elapsedSeconds * 0.9 + i * 1.4) * 0.28;
      riders.add(
        AndesEucalyptusQuebecRiderMarker3D(
          id: 'rider_$i',
          teamCode: codes[i],
          distanceMeters: cameraDistanceMeters + distAhead,
          lateralOffsetMeters: lateral,
          jerseyColor: jerseys[i],
          helmetColor: i == 0 ? AppColors.goldAccent : const Color(0xFFF3F4F6),
          cadencePhaseRad: elapsedSeconds * 8.4 + i * 0.85,
          isOutOfSaddle:
              biome != AndesEucalyptusQuebecBiome.australianBushVictoriaCoast &&
                  i < 3,
        ),
      );
    }
    return riders;
  }
}

// =============================================================================
// 4. PAINTER 3D RENDERUJĄCY SCENERIĘ
// =============================================================================

/// `CustomPainter` renderujący klatkę 3D dla biomów Andy, Busz Australijski i Québec.
class AndesEucalyptusQuebecPainter extends CustomPainter {
  final AndesEucalyptusQuebecFrameState frame;
  final AndesEucalyptusAndQuebecBiomes3d engine;

  const AndesEucalyptusQuebecPainter({
    required this.frame,
    this.engine = const AndesEucalyptusAndQuebecBiomes3d(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1 || size.height <= 1) return;

    final AndesEucalyptusQuebecBiome biome = frame.biome;
    final Vector3 cameraPos = Vector3(
      engine.courseCenterX(biome, frame.cameraDistanceMeters),
      frame.cameraHeightMeters,
      frame.cameraDistanceMeters,
    );

    canvas.save();
    if (frame.cameraVibrationOffsetPx != 0.0) {
      canvas.translate(0.0, frame.cameraVibrationOffsetPx);
    }

    // 1. Niebo i horyzont biomu (w tym rozrzedzony błękit Andów lub ocean Wiktorii)
    _paintSkyAndBackground(canvas, size, biome);

    // 2. Wstęga drogi 3D (szutrowo-asfaltowa, przepaść, bruk Starego Miasta)
    _paintRoadRibbon(canvas, size, cameraPos);

    // 3. Obiekty scenerii 3D (posortowane od najdalszych)
    for (final AndesEucalyptusQuebecProp3D prop in frame.visibleProps) {
      _paintProp3D(canvas, size, cameraPos, prop);
    }

    // 4. Kolarze peletonu 3D
    _paintPelotonRiders(canvas, size, cameraPos);

    // 5. Cząsteczki (pył andyjski, pyłki buszu, wirujące liście klonu)
    _paintParticles(canvas, size, cameraPos);

    // 6. Subtelny efekt rozgrzanego powietrza nad asfaltem w Australii
    if (frame.heatShimmerAmplitudePx > 0.1) {
      _paintHeatShimmerOverlay(canvas, size);
    }

    canvas.restore();
  }

  void _paintSkyAndBackground(
    Canvas canvas,
    Size size,
    AndesEucalyptusQuebecBiome biome,
  ) {
    final double horizonY = size.height * 0.43;
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 18);
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[biome.skyTopColor, biome.skyHorizonColor],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Tło charakterystyczne dla biomu
    switch (biome) {
      case AndesEucalyptusQuebecBiome.highAndesArgentinaColombia:
        _paintAndeanMountainRangeBackdrop(canvas, size, horizonY);
        break;
      case AndesEucalyptusQuebecBiome.australianBushVictoriaCoast:
        _paintSouthernOceanBackdrop(canvas, size, horizonY);
        break;
      case AndesEucalyptusQuebecBiome.quebecMontrealAutumnCircuit:
        _paintQuebecSkylineBackdrop(canvas, size, horizonY);
        break;
    }

    // Baza gruntu poniżej horyzontu
    final Rect groundRect =
        Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY);
    final Paint groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          biome.terrainAccentColor,
          biome.terrainBaseColor,
        ],
      ).createShader(groundRect);
    canvas.drawRect(groundRect, groundPaint);

    // W Wysokich Andach prawa strona poniżej drogi to głęboka przepaść doliny
    if (biome.hasCliffDropOff) {
      final Path abyssPath = Path()
        ..moveTo(size.width * 0.56, horizonY)
        ..lineTo(size.width, horizonY)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width * 0.64, size.height)
        ..close();
      final Paint abyssPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF283D52),
            Color(0xFF131D28),
          ],
        ).createShader(groundRect);
      canvas.drawPath(abyssPath, abyssPaint);
    }
  }

  void _paintAndeanMountainRangeBackdrop(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // Wielowarstwowe, wielobarwne pasmo Andów na horyzoncie
    final Path backPeaks = Path()..moveTo(0, horizonY);
    for (int i = 0; i <= 8; i++) {
      final double x = size.width * (i / 8.0);
      final double peakH =
          28.0 + math.sin(i * 1.45) * 22.0 + (i.isOdd ? 18.0 : 0.0);
      backPeaks.lineTo(x, horizonY - peakH);
    }
    backPeaks
      ..lineTo(size.width, horizonY + 8)
      ..lineTo(0, horizonY + 8)
      ..close();
    canvas.drawPath(
      backPeaks,
      Paint()..color = const Color(0xFF4C5F7A).withValues(alpha: 0.75),
    );

    final Path coloredStrataRidge = Path()..moveTo(0, horizonY + 4);
    for (int i = 0; i <= 10; i++) {
      final double x = size.width * (i / 10.0);
      final double ridgeH = 14.0 + math.cos(i * 1.1) * 12.0;
      coloredStrataRidge.lineTo(x, horizonY - ridgeH);
    }
    coloredStrataRidge
      ..lineTo(size.width, horizonY + 6)
      ..lineTo(0, horizonY + 6)
      ..close();
    canvas.drawPath(
      coloredStrataRidge,
      Paint()..color = const Color(0xFF9E513B).withValues(alpha: 0.68),
    );
  }

  void _paintSouthernOceanBackdrop(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // Błękitny Ocean Południowy rozciągający się po prawej stronie wybrzeża
    final Rect oceanRect = Rect.fromLTWH(
      size.width * 0.42,
      horizonY - 6,
      size.width * 0.58,
      size.height * 0.20,
    );
    final Paint oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF0284C7),
          Color(0xFF0369A1),
          Color(0xFF0C4A6E),
        ],
      ).createShader(oceanRect);
    canvas.drawRect(oceanRect, oceanPaint);

    // Refleksy fal na oceanie
    final Paint wavePaint = Paint()
      ..color = const Color(0xFFE0F2FE).withValues(alpha: 0.45)
      ..strokeWidth = 1.4;
    for (int i = 0; i < 7; i++) {
      final double y = horizonY + 4.0 + i * 7.5;
      final double xStart = size.width * (0.48 + (i % 3) * 0.08);
      final double waveShift = math.sin(frame.elapsedSeconds * 1.8 + i) * 8.0;
      canvas.drawLine(
        Offset(xStart + waveShift, y),
        Offset(xStart + 36.0 + waveShift, y),
        wavePaint,
      );
    }
  }

  void _paintQuebecSkylineBackdrop(
    Canvas canvas,
    Size size,
    double horizonY,
  ) {
    // Sylwetka historycznych dachów i wież Starego Miasta Québec
    final Paint silhouettePaint = Paint()
      ..color = const Color(0xFF323A47).withValues(alpha: 0.65);
    for (int i = 0; i < 12; i++) {
      final double x = size.width * (i / 12.0);
      final double w = size.width / 12.0 + 4.0;
      final double h = 16.0 + (i % 4) * 9.0;
      canvas.drawRect(
        Rect.fromLTWH(x, horizonY - h, w, h + 4),
        silhouettePaint,
      );
      if (i == 4 || i == 9) {
        // Spadzista wieżyczka w stylu Château Frontenac
        final Path spire = Path()
          ..moveTo(x + w * 0.25, horizonY - h)
          ..lineTo(x + w * 0.5, horizonY - h - 22.0)
          ..lineTo(x + w * 0.75, horizonY - h)
          ..close();
        canvas.drawPath(spire, silhouettePaint);
      }
    }
  }

  void _paintRoadRibbon(Canvas canvas, Size size, Vector3 cameraPos) {
    final List<AndesEucalyptusQuebecRoadSlice3D> slices = frame.roadSlices;
    if (slices.length < 2) return;

    final AndesEucalyptusQuebecBiome biome = frame.biome;
    final Paint roadPaint = Paint()..color = biome.roadSurfaceColor;
    final Paint edgePaint = Paint()
      ..color = biome.roadEdgeColor
      ..strokeWidth = 2.0;
    final Paint centerDashPaint = Paint()
      ..color = const Color(0xFFF3F4F6).withValues(alpha: 0.65)
      ..strokeWidth = 1.6;
    final Paint gravelPaint = Paint()
      ..color = const Color(0xFFA38B70).withValues(alpha: 0.45);
    final Paint cobblePaint = Paint()
      ..color = const Color(0xFF35373C).withValues(alpha: 0.52)
      ..strokeWidth = 1.1;

    for (int i = slices.length - 1; i >= 1; i--) {
      final AndesEucalyptusQuebecRoadSlice3D farSlice = slices[i];
      final AndesEucalyptusQuebecRoadSlice3D nearSlice = slices[i - 1];

      final Offset? fl = engine.projectWorldPoint(
        worldPoint: Vector3(
          farSlice.centerWorld.x - farSlice.halfWidthMeters,
          farSlice.centerWorld.y,
          farSlice.centerWorld.z,
        ),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      final Offset? fr = engine.projectWorldPoint(
        worldPoint: Vector3(
          farSlice.centerWorld.x + farSlice.halfWidthMeters,
          farSlice.centerWorld.y,
          farSlice.centerWorld.z,
        ),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      final Offset? nl = engine.projectWorldPoint(
        worldPoint: Vector3(
          nearSlice.centerWorld.x - nearSlice.halfWidthMeters,
          nearSlice.centerWorld.y,
          nearSlice.centerWorld.z,
        ),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      final Offset? nr = engine.projectWorldPoint(
        worldPoint: Vector3(
          nearSlice.centerWorld.x + nearSlice.halfWidthMeters,
          nearSlice.centerWorld.y,
          nearSlice.centerWorld.z,
        ),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );

      if (fl == null || fr == null || nl == null || nr == null) continue;

      final Path quad = Path()
        ..moveTo(fl.dx, fl.dy)
        ..lineTo(fr.dx, fr.dy)
        ..lineTo(nr.dx, nr.dy)
        ..lineTo(nl.dx, nl.dy)
        ..close();
      canvas.drawPath(quad, roadPaint);

      // Krawędzie drogi
      canvas.drawLine(fl, nl, edgePaint);
      canvas.drawLine(fr, nr, edgePaint);

      // Szutrowo-asfaltowe łaty w Wysokich Andach
      if (nearSlice.hasGravelPatches && i % 2 == 0) {
        final Offset midFar = Offset.lerp(fl, fr, 0.35)!;
        final Offset midNear = Offset.lerp(nl, nr, 0.65)!;
        canvas.drawRect(
          Rect.fromPoints(midFar, midNear),
          gravelPaint,
        );
      }

      // Historyczny bruk w Québec & Montréal
      if (nearSlice.hasCobbleJoints) {
        final Offset midLeft = Offset.lerp(fl, nl, 0.5)!;
        final Offset midRight = Offset.lerp(fr, nr, 0.5)!;
        canvas.drawLine(midLeft, midRight, cobblePaint);
      }

      // Przerywana linia środkowa na asfalcie w Australii
      if (!nearSlice.hasCobbleJoints &&
          !nearSlice.hasGravelPatches &&
          i.isEven) {
        final Offset fc = Offset.lerp(fl, fr, 0.5)!;
        final Offset nc = Offset.lerp(nl, nr, 0.5)!;
        canvas.drawLine(fc, nc, centerDashPaint);
      }
    }
  }

  void _paintProp3D(
    Canvas canvas,
    Size size,
    Vector3 cameraPos,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final Offset? base = engine.projectWorldPoint(
      worldPoint: prop.worldPosition,
      cameraPos: cameraPos,
      cameraYawRadians: frame.cameraYawRadians,
      cameraPitchRadians: frame.cameraPitchRadians,
      fovDegrees: frame.cameraFovDegrees,
      viewportSize: size,
    );
    final Offset? top = engine.projectWorldPoint(
      worldPoint: Vector3(
        prop.worldPosition.x,
        prop.worldPosition.y + prop.heightMeters,
        prop.worldPosition.z,
      ),
      cameraPos: cameraPos,
      cameraYawRadians: frame.cameraYawRadians,
      cameraPitchRadians: frame.cameraPitchRadians,
      fovDegrees: frame.cameraFovDegrees,
      viewportSize: size,
    );

    if (base == null || top == null) return;
    final double pxHeight = (base.dy - top.dy).abs().clamp(3.0, 320.0);
    final double pxWidth =
        pxHeight * (prop.widthMeters / math.max(0.5, prop.heightMeters));

    switch (prop.kind) {
      case AndesEucalyptusQuebecPropKind.multicolorAndeanRockStrata:
        _drawAndeanRockStrata(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.precipiceGuardStone:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(base.dx, base.dy - pxHeight * 0.5),
            width: pxWidth.clamp(3.0, 14.0),
            height: pxHeight.clamp(4.0, 28.0),
          ),
          Paint()..color = prop.primaryColor,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(base.dx, base.dy - pxHeight * 0.78),
            width: pxWidth.clamp(3.0, 14.0),
            height: (pxHeight * 0.22).clamp(1.5, 6.0),
          ),
          Paint()..color = prop.secondaryColor,
        );
        break;
      case AndesEucalyptusQuebecPropKind.circlingAndeanCondor:
        _drawAndeanCondor(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.highlandScrubTuft:
      case AndesEucalyptusQuebecPropKind.redGoldBushGrass:
        _drawGrassTuft(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.eucalyptusGumTree:
        _drawEucalyptusTree(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.sunHatSpectatorCrowd:
        _drawSunHatCrowd(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.coastalOceanCliffBeacon:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(base.dx, base.dy - pxHeight * 0.5),
            width: pxWidth.clamp(4.0, 26.0),
            height: pxHeight.clamp(5.0, 32.0),
          ),
          Paint()..color = prop.primaryColor,
        );
        break;
      case AndesEucalyptusQuebecPropKind.fieryAutumnMapleTree:
        _drawAutumnMapleTree(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.oldTownHistoricFacade:
        _drawHistoricFacade(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.denseUrbanRaceBarrier:
        _drawUrbanBarrier(canvas, base, pxWidth, pxHeight, prop);
        break;
      case AndesEucalyptusQuebecPropKind.autumnBannerArchway:
        _drawBannerArchway(canvas, base, pxWidth, pxHeight, prop);
        break;
    }
  }

  void _drawAndeanRockStrata(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final Path rock = Path()
      ..moveTo(base.dx - w * 0.52, base.dy)
      ..lineTo(base.dx - w * 0.26, base.dy - h * 0.88)
      ..lineTo(base.dx + w * 0.14, base.dy - h)
      ..lineTo(base.dx + w * 0.50, base.dy);
    rock.close();
    canvas.drawPath(rock, Paint()..color = prop.primaryColor);

    // Pasy mineralne (wielobarwne warstwy geologiczne)
    final Path band2 = Path()
      ..moveTo(base.dx - w * 0.36, base.dy - h * 0.32)
      ..lineTo(base.dx + w * 0.32, base.dy - h * 0.44)
      ..lineTo(base.dx + w * 0.38, base.dy - h * 0.24)
      ..lineTo(base.dx - w * 0.42, base.dy - h * 0.14)
      ..close();
    canvas.drawPath(band2, Paint()..color = prop.secondaryColor);

    final Path band3 = Path()
      ..moveTo(base.dx - w * 0.24, base.dy - h * 0.62)
      ..lineTo(base.dx + w * 0.20, base.dy - h * 0.72)
      ..lineTo(base.dx + w * 0.26, base.dy - h * 0.56)
      ..lineTo(base.dx - w * 0.28, base.dy - h * 0.48)
      ..close();
    canvas.drawPath(band3, Paint()..color = prop.tertiaryColor);
  }

  void _drawAndeanCondor(
    Canvas canvas,
    Offset center,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final double wingSpan = w.clamp(12.0, 56.0);
    final double flap = math.sin(frame.elapsedSeconds * 3.1 + prop.phaseOffset) *
        (wingSpan * 0.14);
    final Paint wingPaint = Paint()
      ..color = prop.primaryColor
      ..strokeWidth = (wingSpan * 0.11).clamp(1.8, 4.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path wings = Path()
      ..moveTo(center.dx - wingSpan * 0.5, center.dy - flap)
      ..quadraticBezierTo(
        center.dx - wingSpan * 0.22,
        center.dy - wingSpan * 0.14,
        center.dx,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + wingSpan * 0.22,
        center.dy - wingSpan * 0.14,
        center.dx + wingSpan * 0.5,
        center.dy - flap,
      );
    canvas.drawPath(wings, wingPaint);

    // Biały kołnierz kondora
    canvas.drawCircle(
      center,
      (wingSpan * 0.08).clamp(1.5, 4.0),
      Paint()..color = prop.secondaryColor,
    );
  }

  void _drawGrassTuft(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final double sway =
        math.sin(frame.elapsedSeconds * 2.5 + prop.phaseOffset) * 2.2;
    final Paint p1 = Paint()
      ..color = prop.primaryColor
      ..strokeWidth = 2.0;
    final Paint p2 = Paint()
      ..color = prop.secondaryColor
      ..strokeWidth = 1.8;
    for (int i = -2; i <= 2; i++) {
      final double bx = base.dx + i * (w * 0.14);
      canvas.drawLine(
        Offset(bx, base.dy),
        Offset(bx + i * 2.0 + sway, base.dy - h),
        i.isEven ? p1 : p2,
      );
    }
  }

  void _drawEucalyptusTree(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    // Jasny pień eukaliptusa
    final double trunkW = (w * 0.11).clamp(2.5, 11.0);
    canvas.drawRect(
      Rect.fromLTWH(
        base.dx - trunkW * 0.5,
        base.dy - h * 0.62,
        trunkW,
        h * 0.62,
      ),
      Paint()..color = prop.tertiaryColor,
    );

    // Asymetryczne kępy szałwiowo-zielonych liści
    final double canopyR = (w * 0.36).clamp(6.0, 56.0);
    canvas.drawCircle(
      Offset(base.dx - canopyR * 0.35, base.dy - h * 0.72),
      canopyR * 0.75,
      Paint()..color = prop.primaryColor,
    );
    canvas.drawCircle(
      Offset(base.dx + canopyR * 0.30, base.dy - h * 0.78),
      canopyR * 0.68,
      Paint()..color = prop.secondaryColor,
    );
    canvas.drawCircle(
      Offset(base.dx, base.dy - h * 0.88),
      canopyR * 0.62,
      Paint()..color = prop.primaryColor,
    );
  }

  void _drawSunHatCrowd(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final double personH = h.clamp(6.0, 34.0);
    final double spacing = (w / 3.0).clamp(4.0, 18.0);
    for (int i = -1; i <= 1; i++) {
      final double px = base.dx + i * spacing;
      final double cheerBob =
          math.sin(frame.elapsedSeconds * 5.2 + prop.phaseOffset + i) * 1.5;
      // Tułów kibica
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(px, base.dy - personH * 0.38),
            width: spacing * 0.68,
            height: personH * 0.62,
          ),
          const Radius.circular(2),
        ),
        Paint()
          ..color = i == 0 ? prop.tertiaryColor : prop.secondaryColor,
      );
      // Szeroki kapelusz przeciwsłoneczny
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, base.dy - personH * 0.82 + cheerBob),
          width: spacing * 1.05,
          height: (personH * 0.20).clamp(2.0, 6.0),
        ),
        Paint()..color = prop.primaryColor,
      );
    }
  }

  void _drawAutumnMapleTree(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final double trunkW = (w * 0.13).clamp(2.5, 12.0);
    canvas.drawRect(
      Rect.fromLTWH(
        base.dx - trunkW * 0.5,
        base.dy - h * 0.48,
        trunkW,
        h * 0.48,
      ),
      Paint()..color = prop.tertiaryColor,
    );

    final double r = (w * 0.42).clamp(7.0, 64.0);
    canvas.drawCircle(
      Offset(base.dx - r * 0.3, base.dy - h * 0.68),
      r * 0.72,
      Paint()..color = prop.primaryColor,
    );
    canvas.drawCircle(
      Offset(base.dx + r * 0.32, base.dy - h * 0.64),
      r * 0.68,
      Paint()..color = prop.secondaryColor,
    );
    canvas.drawCircle(
      Offset(base.dx, base.dy - h * 0.84),
      r * 0.74,
      Paint()..color = prop.primaryColor,
    );
  }

  void _drawHistoricFacade(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final double bw = w.clamp(12.0, 140.0);
    final double bh = h.clamp(16.0, 210.0);
    final Rect wallRect = Rect.fromLTWH(
      base.dx - bw * 0.5,
      base.dy - bh * 0.76,
      bw,
      bh * 0.76,
    );
    canvas.drawRect(wallRect, Paint()..color = prop.primaryColor);

    // Spadzisty dach Starego Miasta
    final Path roof = Path()
      ..moveTo(base.dx - bw * 0.54, base.dy - bh * 0.76)
      ..lineTo(base.dx, base.dy - bh)
      ..lineTo(base.dx + bw * 0.54, base.dy - bh * 0.76)
      ..close();
    canvas.drawPath(roof, Paint()..color = prop.secondaryColor);

    // Ciepłe okna kamienicy
    if (bw > 24.0) {
      final Paint winPaint = Paint()..color = prop.tertiaryColor;
      for (int row = 0; row < 2; row++) {
        for (int col = -1; col <= 1; col += 2) {
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(
                base.dx + col * bw * 0.22,
                base.dy - bh * (0.28 + row * 0.26),
              ),
              width: bw * 0.14,
              height: bh * 0.13,
            ),
            winPaint,
          );
        }
      }
    }
  }

  void _drawUrbanBarrier(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final double bw = w.clamp(6.0, 48.0);
    final double bh = h.clamp(4.0, 24.0);
    final Rect barRect = Rect.fromLTWH(
      base.dx - bw * 0.5,
      base.dy - bh,
      bw,
      bh,
    );
    canvas.drawRect(barRect, Paint()..color = prop.secondaryColor);
    canvas.drawRect(
      barRect,
      Paint()
        ..color = prop.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawBannerArchway(
    Canvas canvas,
    Offset base,
    double w,
    double h,
    AndesEucalyptusQuebecProp3D prop,
  ) {
    final double aw = w.clamp(24.0, 280.0);
    final double ah = h.clamp(16.0, 140.0);
    final double pillarW = (aw * 0.08).clamp(3.0, 16.0);
    final Paint pillarPaint = Paint()..color = prop.tertiaryColor;
    canvas.drawRect(
      Rect.fromLTWH(base.dx - aw * 0.5, base.dy - ah, pillarW, ah),
      pillarPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx + aw * 0.5 - pillarW, base.dy - ah, pillarW, ah),
      pillarPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx - aw * 0.5, base.dy - ah, aw, ah * 0.22),
      Paint()..color = prop.primaryColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        base.dx - aw * 0.5,
        base.dy - ah * 0.80,
        aw,
        (ah * 0.04).clamp(1.5, 4.0),
      ),
      Paint()..color = prop.secondaryColor,
    );
  }

  void _paintPelotonRiders(Canvas canvas, Size size, Vector3 cameraPos) {
    final List<AndesEucalyptusQuebecRiderMarker3D> sorted =
        List<AndesEucalyptusQuebecRiderMarker3D>.from(frame.pelotonMarkers)
          ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));

    for (final AndesEucalyptusQuebecRiderMarker3D rider in sorted) {
      final double cx =
          engine.courseCenterX(frame.biome, rider.distanceMeters) +
              rider.lateralOffsetMeters;
      final double cy =
          engine.courseCenterY(frame.biome, rider.distanceMeters);
      final Offset? base = engine.projectWorldPoint(
        worldPoint: Vector3(cx, cy, rider.distanceMeters),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      final Offset? head = engine.projectWorldPoint(
        worldPoint: Vector3(
          cx,
          cy + (rider.isOutOfSaddle ? 1.62 : 1.44),
          rider.distanceMeters,
        ),
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      if (base == null || head == null) continue;

      final double h = (base.dy - head.dy).abs().clamp(8.0, 120.0);
      final double w = h * 0.44;
      final double rock = rider.isOutOfSaddle
          ? math.sin(rider.cadencePhaseRad) * (w * 0.22)
          : 0.0;

      // Cień pod rowerem
      canvas.drawOval(
        Rect.fromCenter(
          center: base,
          width: w * 0.9,
          height: (h * 0.10).clamp(2.0, 8.0),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.36),
      );

      // Rama / koła
      canvas.drawLine(
        base,
        Offset(base.dx + rock * 0.5, base.dy - h * 0.45),
        Paint()
          ..color = const Color(0xFF1F2937)
          ..strokeWidth = (w * 0.14).clamp(1.4, 4.0),
      );

      // Koszulka kolarza
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(base.dx + rock, base.dy - h * 0.62),
            width: w * 0.68,
            height: h * 0.42,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = rider.jerseyColor,
      );

      // Kask
      canvas.drawCircle(
        Offset(base.dx + rock * 1.1, head.dy + h * 0.08),
        (w * 0.22).clamp(2.0, 10.0),
        Paint()..color = rider.helmetColor,
      );
    }
  }

  void _paintParticles(Canvas canvas, Size size, Vector3 cameraPos) {
    for (final AndesEucalyptusQuebecParticle3D p in frame.particles) {
      final Offset? pos = engine.projectWorldPoint(
        worldPoint: p.worldPosition,
        cameraPos: cameraPos,
        cameraYawRadians: frame.cameraYawRadians,
        cameraPitchRadians: frame.cameraPitchRadians,
        fovDegrees: frame.cameraFovDegrees,
        viewportSize: size,
      );
      if (pos == null) continue;

      final Paint paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity);
      if (p.isMapleLeaf) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.rotationRadians);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.sizePx,
            height: p.sizePx * 0.65,
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(pos, p.sizePx * 0.5, paint);
      }
    }
  }

  void _paintHeatShimmerOverlay(Canvas canvas, Size size) {
    final Rect bottomBand = Rect.fromLTWH(
      0,
      size.height * 0.62,
      size.width,
      size.height * 0.38,
    );
    final Paint shimmer = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.transparent,
          const Color(0xFFF59E0B).withValues(alpha: 0.06),
        ],
      ).createShader(bottomBand);
    canvas.drawRect(bottomBand, shimmer);
  }

  @override
  bool shouldRepaint(covariant AndesEucalyptusQuebecPainter oldDelegate) {
    return oldDelegate.frame.biome != frame.biome ||
        oldDelegate.frame.cameraPreset != frame.cameraPreset ||
        oldDelegate.frame.cameraDistanceMeters != frame.cameraDistanceMeters ||
        oldDelegate.frame.elapsedSeconds != frame.elapsedSeconds;
  }
}

// =============================================================================
// 5. RESPONSYWNY PANEL WIDŻETU 3D Z PEŁNYMI STANAMI INTERAKTYWNYMI
// =============================================================================

/// Interaktywny panel podglądu i sterowania scenerią 3D biomów
/// Wysokie Andy, Australijski Busz & Wiktoria oraz Jesienny Québec & Montréal.
class AndesEucalyptusQuebecPanel extends StatefulWidget {
  final AndesEucalyptusQuebecBiome initialBiome;
  final AndesEucalyptusQuebecCameraPreset initialCamera;
  final bool autoPlay;
  final bool enabled;
  final ValueChanged<AndesEucalyptusQuebecBiome>? onBiomeChanged;

  const AndesEucalyptusQuebecPanel({
    super.key,
    this.initialBiome =
        AndesEucalyptusQuebecBiome.highAndesArgentinaColombia,
    this.initialCamera = AndesEucalyptusQuebecCameraPreset.pelotonChase,
    this.autoPlay = true,
    this.enabled = true,
    this.onBiomeChanged,
  });

  @override
  State<AndesEucalyptusQuebecPanel> createState() =>
      _AndesEucalyptusQuebecPanelState();
}

class _AndesEucalyptusQuebecPanelState extends State<AndesEucalyptusQuebecPanel>
    with SingleTickerProviderStateMixin {
  static const AndesEucalyptusAndQuebecBiomes3d _engine =
      AndesEucalyptusAndQuebecBiomes3d();

  late AndesEucalyptusQuebecConfig _config;
  late bool _isPlaying;
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _elapsedSeconds = 0.0;
  double _cameraDistanceMeters = 110.0;

  @override
  void initState() {
    super.initState();
    _config = AndesEucalyptusQuebecConfig(
      biome: widget.initialBiome,
      cameraPreset: widget.initialCamera,
    );
    _isPlaying = widget.autoPlay;
    _ticker = createTicker(_onTick);
    if (_isPlaying) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_isPlaying) return;
    final double dt = _lastTick == Duration.zero
        ? 0.016
        : ((elapsed - _lastTick).inMicroseconds / 1000000.0)
            .clamp(0.001, 0.05);
    _lastTick = elapsed;
    setState(() {
      _elapsedSeconds += dt;
      _cameraDistanceMeters += dt * 11.5;
    });
  }

  void _selectBiome(AndesEucalyptusQuebecBiome biome) {
    if (!widget.enabled) return;
    setState(() {
      _config = _config.copyWith(biome: biome);
    });
    widget.onBiomeChanged?.call(biome);
  }

  void _selectCamera(AndesEucalyptusQuebecCameraPreset preset) {
    if (!widget.enabled) return;
    setState(() {
      _config = _config.copyWith(cameraPreset: preset);
    });
  }

  void _togglePlay() {
    if (!widget.enabled) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _lastTick = Duration.zero;
      if (_isPlaying) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    });
  }

  void _stepForward() {
    if (!widget.enabled) return;
    setState(() {
      _elapsedSeconds += 0.6;
      _cameraDistanceMeters += 7.5;
    });
  }

  void _toggleWildlife() {
    if (!widget.enabled) return;
    setState(() {
      _config = _config.copyWith(
        enableDynamicWildlife: !_config.enableDynamicWildlife,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AndesEucalyptusQuebecFrameState frame = _engine.buildFrame(
      config: _config,
      cameraDistanceMeters: _cameraDistanceMeters,
      elapsedSeconds: _elapsedSeconds,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 680;
        final bool isShort = constraints.maxHeight < 520;
        final double viewportHeight = isShort
            ? math.max(150.0, constraints.maxHeight * 0.42)
            : (isCompact ? 230.0 : 320.0);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _HeaderBar(
                  biome: frame.biome,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: viewportHeight,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        CustomPaint(
                          painter: AndesEucalyptusQuebecPainter(
                            frame: frame,
                            engine: _engine,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          right: 10,
                          child: _ViewportTelemetryOverlay(
                            frame: frame,
                            isCompact: isCompact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _BiomeSelectorRow(
                  selectedBiome: _config.biome,
                  enabled: widget.enabled,
                  isCompact: isCompact,
                  onSelect: _selectBiome,
                ),
                const SizedBox(height: 10),
                _ControlToolbar(
                  selectedPreset: _config.cameraPreset,
                  isPlaying: _isPlaying,
                  wildlifeEnabled: _config.enableDynamicWildlife,
                  enabled: widget.enabled,
                  isCompact: isCompact,
                  onSelectPreset: _selectCamera,
                  onTogglePlay: _togglePlay,
                  onStepForward: _stepForward,
                  onToggleWildlife: _toggleWildlife,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final AndesEucalyptusQuebecBiome biome;
  final bool isCompact;

  const _HeaderBar({
    required this.biome,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              biome.labelPl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 15 : 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              biome.regionPl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: biome.accentHighlightColor, width: 1.0),
          ),
          child: Text(
            biome.shortTag,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: biome.accentHighlightColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewportTelemetryOverlay extends StatelessWidget {
  final AndesEucalyptusQuebecFrameState frame;
  final bool isCompact;

  const _ViewportTelemetryOverlay({
    required this.frame,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        _TelemetryChip(
          label: 'ALT',
          value: '${frame.biome.altitudeMeters.toStringAsFixed(0)} m',
        ),
        _TelemetryChip(
          label: 'TEMP',
          value: '${frame.biome.ambientTempCelsius.toStringAsFixed(1)} °C',
        ),
        _TelemetryChip(
          label: 'AIR ρ',
          value: '${frame.airDensityKgM3.toStringAsFixed(2)} kg/m³',
        ),
        if (!isCompact)
          _TelemetryChip(
            label: 'CRR',
            value: 'x${frame.effectiveCrrMultiplier.toStringAsFixed(2)}',
          ),
        _TelemetryChip(
          label: 'WIND',
          value: '${frame.effectiveWindMps.toStringAsFixed(1)} m/s',
        ),
      ],
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BiomeSelectorRow extends StatelessWidget {
  final AndesEucalyptusQuebecBiome selectedBiome;
  final bool enabled;
  final bool isCompact;
  final ValueChanged<AndesEucalyptusQuebecBiome> onSelect;

  const _BiomeSelectorRow({
    required this.selectedBiome,
    required this.enabled,
    required this.isCompact,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = AndesEucalyptusQuebecBiome.values
        .map(
          (AndesEucalyptusQuebecBiome biome) => _InteractiveBiomeTile(
            biome: biome,
            isSelected: biome == selectedBiome,
            enabled: enabled,
            onTap: () => onSelect(biome),
          ),
        )
        .toList(growable: false);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tiles
            .map(
              (Widget w) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: w,
              ),
            )
            .toList(growable: false),
      );
    }

    return Row(
      children: <Widget>[
        for (int i = 0; i < tiles.length; i++) ...<Widget>[
          Expanded(child: tiles[i]),
          if (i < tiles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _InteractiveBiomeTile extends StatefulWidget {
  final AndesEucalyptusQuebecBiome biome;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveBiomeTile({
    required this.biome,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_InteractiveBiomeTile> createState() => _InteractiveBiomeTileState();
}

class _InteractiveBiomeTileState extends State<_InteractiveBiomeTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.isSelected
            ? widget.biome.accentHighlightColor
            : _focused
                ? AppColors.goldAccent
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    final Color bgColor = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.surfaceLight
            : widget.isSelected
                ? AppColors.surfaceLight
                : _hovered
                    ? const Color(0xFF1E222B)
                    : AppColors.surface;

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (bool hasFocus) => setState(() => _focused = hasFocus),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.biome.shortTag,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.enabled
                        ? (widget.isSelected
                            ? widget.biome.accentHighlightColor
                            : AppColors.textPrimary)
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.biome.regionPl,
                  maxLines: 2,
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
        ),
      ),
    );
  }
}

class _ControlToolbar extends StatelessWidget {
  final AndesEucalyptusQuebecCameraPreset selectedPreset;
  final bool isPlaying;
  final bool wildlifeEnabled;
  final bool enabled;
  final bool isCompact;
  final ValueChanged<AndesEucalyptusQuebecCameraPreset> onSelectPreset;
  final VoidCallback onTogglePlay;
  final VoidCallback onStepForward;
  final VoidCallback onToggleWildlife;

  const _ControlToolbar({
    required this.selectedPreset,
    required this.isPlaying,
    required this.wildlifeEnabled,
    required this.enabled,
    required this.isCompact,
    required this.onSelectPreset,
    required this.onTogglePlay,
    required this.onStepForward,
    required this.onToggleWildlife,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AndesEucalyptusQuebecCameraPreset.values
              .map(
                (AndesEucalyptusQuebecCameraPreset preset) => _ActionPillButton(
                  label: preset.labelPl,
                  isActive: preset == selectedPreset,
                  enabled: enabled,
                  onTap: () => onSelectPreset(preset),
                ),
              )
              .toList(growable: false),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _ActionPillButton(
              label: isPlaying ? 'Pauza' : 'Start',
              isActive: isPlaying,
              enabled: enabled,
              onTap: onTogglePlay,
            ),
            _ActionPillButton(
              label: '+0.6s',
              isActive: false,
              enabled: enabled,
              onTap: onStepForward,
            ),
            _ActionPillButton(
              label: wildlifeEnabled ? 'Fauna ON' : 'Fauna OFF',
              isActive: wildlifeEnabled,
              enabled: enabled,
              onTap: onToggleWildlife,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionPillButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionPillButton({
    required this.label,
    required this.isActive,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.isActive
            ? AppColors.goldAccent
            : _focused
                ? AppColors.accentBlue
                : _hovered
                    ? AppColors.textSecondary
                    : AppColors.cardBorder;

    final Color bgColor = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.4)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : widget.isActive
                ? AppColors.surfaceLight
                : _hovered
                    ? const Color(0xFF1E222B)
                    : AppColors.surface;

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (bool hasFocus) => setState(() => _focused = hasFocus),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.enabled
                    ? (widget.isActive
                        ? AppColors.goldAccent
                        : AppColors.textPrimary)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
