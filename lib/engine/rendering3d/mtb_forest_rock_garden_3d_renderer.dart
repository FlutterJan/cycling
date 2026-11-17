// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/mtb_xco_course_and_suspension_model.dart';

// =============================================================================
// 1. PRESETY BIOMÓW LEŚNYCH MTB XCO
// =============================================================================

/// Charakterystyka wizualna i środowiskowa leśnej trasy MTB XCO w silniku 3D.
enum MtbForestBiomePreset {
  noveMestoPineForest(
    labelPl: 'Nové Město — Sosnowy Las i Granit',
    shortTag: 'NOVÉ MĚSTO',
    regionPl: 'Vysočina, Czechy • Puchar Świata XCO',
    soilCondition: MtbTrailSoilCondition.dryHardpack,
    canopyTopColor: Color(0xFF0E1B16),
    canopyMidColor: Color(0xFF1A3327),
    forestFloorColor: Color(0xFF283522),
    trailSurfaceColor: Color(0xFF6B533B),
    trailRutColor: Color(0xFF4F3B27),
    boulderBaseColor: Color(0xFF686D73),
    boulderHighlightColor: Color(0xFF9AA0A8),
    woodPlankColor: Color(0xFF7D5836),
    sunbeamColor: Color(0xFFFFD885),
    dustColor: Color(0xFFEBD2A4),
    defaultSunbeamIntensity: 0.88,
    defaultDustDensity: 0.84,
    defaultCanopyDensity: 0.86,
  ),
  valDiSoleAlpineRoots(
    labelPl: 'Val di Sole — Świerki i Czarne Głazy',
    shortTag: 'VAL DI SOLE',
    regionPl: 'Trydent, Włochy • Black Snake XCO',
    soilCondition: MtbTrailSoilCondition.tackyLoam,
    canopyTopColor: Color(0xFF0A1412),
    canopyMidColor: Color(0xFF142923),
    forestFloorColor: Color(0xFF1F2B1D),
    trailSurfaceColor: Color(0xFF4D3B2C),
    trailRutColor: Color(0xFF35271C),
    boulderBaseColor: Color(0xFF474C54),
    boulderHighlightColor: Color(0xFF777E88),
    woodPlankColor: Color(0xFF63452A),
    sunbeamColor: Color(0xFFF6CF7D),
    dustColor: Color(0xFFCBB696),
    defaultSunbeamIntensity: 0.74,
    defaultDustDensity: 0.62,
    defaultCanopyDensity: 0.94,
  ),
  lesGetsBirchAndDust(
    labelPl: 'Les Gets — Brzozowe Skocznie i Pył',
    shortTag: 'LES GETS',
    regionPl: 'Górna Sabaudia, Francja • Alpy XCO',
    soilCondition: MtbTrailSoilCondition.dryHardpack,
    canopyTopColor: Color(0xFF132218),
    canopyMidColor: Color(0xFF26422C),
    forestFloorColor: Color(0xFF394729),
    trailSurfaceColor: Color(0xFF846747),
    trailRutColor: Color(0xFF644B31),
    boulderBaseColor: Color(0xFF7A7872),
    boulderHighlightColor: Color(0xFFAFA99E),
    woodPlankColor: Color(0xFF8E6740),
    sunbeamColor: Color(0xFFFFE199),
    dustColor: Color(0xFFF4DFB9),
    defaultSunbeamIntensity: 0.94,
    defaultDustDensity: 0.92,
    defaultCanopyDensity: 0.74,
  ),
  cransMontanaCedarGorge(
    labelPl: 'Crans-Montana — Kanion Modrzewiowy',
    shortTag: 'CRANS-M.',
    regionPl: 'Valais, Szwajcaria • Mistrzostwa Świata',
    soilCondition: MtbTrailSoilCondition.looseDust,
    canopyTopColor: Color(0xFF0E181B),
    canopyMidColor: Color(0xFF1E3235),
    forestFloorColor: Color(0xFF2D392A),
    trailSurfaceColor: Color(0xFF6E5A46),
    trailRutColor: Color(0xFF524130),
    boulderBaseColor: Color(0xFF5F666E),
    boulderHighlightColor: Color(0xFF909AA6),
    woodPlankColor: Color(0xFF775639),
    sunbeamColor: Color(0xFFFFD47A),
    dustColor: Color(0xFFE3CEA9),
    defaultSunbeamIntensity: 0.82,
    defaultDustDensity: 0.78,
    defaultCanopyDensity: 0.80,
  );

  final String labelPl;
  final String shortTag;
  final String regionPl;
  final MtbTrailSoilCondition soilCondition;
  final Color canopyTopColor;
  final Color canopyMidColor;
  final Color forestFloorColor;
  final Color trailSurfaceColor;
  final Color trailRutColor;
  final Color boulderBaseColor;
  final Color boulderHighlightColor;
  final Color woodPlankColor;
  final Color sunbeamColor;
  final Color dustColor;
  final double defaultSunbeamIntensity;
  final double defaultDustDensity;
  final double defaultCanopyDensity;

  const MtbForestBiomePreset({
    required this.labelPl,
    required this.shortTag,
    required this.regionPl,
    required this.soilCondition,
    required this.canopyTopColor,
    required this.canopyMidColor,
    required this.forestFloorColor,
    required this.trailSurfaceColor,
    required this.trailRutColor,
    required this.boulderBaseColor,
    required this.boulderHighlightColor,
    required this.woodPlankColor,
    required this.sunbeamColor,
    required this.dustColor,
    required this.defaultSunbeamIntensity,
    required this.defaultDustDensity,
    required this.defaultCanopyDensity,
  });
}

/// Tryby kamery 3D na leśnej trasie MTB XCO.
enum MtbCameraViewMode {
  chaseSingletrack(
    labelPl: 'Pościg Singletrack',
    shortTag: 'CHASE',
  ),
  rockGardenTrackside(
    labelPl: 'Rock Garden Cam',
    shortTag: 'ROCKS',
  ),
  jumpKickerLowAngle(
    labelPl: 'Skocznia Low-Angle',
    shortTag: 'JUMP',
  ),
  canopySunbeamOverview(
    labelPl: 'Korony Drzew',
    shortTag: 'CANOPY',
  );

  final String labelPl;
  final String shortTag;

  const MtbCameraViewMode({
    required this.labelPl,
    required this.shortTag,
  });
}

// =============================================================================
// 2. KONFIGURACJA SCENY 3D I MODELE GEOMETRII
// =============================================================================

/// Konfiguracja parametrów renderera 3D leśnej trasy MTB XCO.
class MtbForestRockGarden3dConfig {
  final MtbForestBiomePreset biomePreset;
  final MtbCameraViewMode cameraMode;
  final MtbTrailLineChoice selectedLineChoice;
  final double fieldOfViewDegrees;
  final double maxDrawDistanceMeters;
  final double trailWidthMeters;
  final double sunbeamIntensity;
  final double dustDensity;
  final double canopyDensity;
  final double riderSpeedKmh;
  final bool showSunbeamsAndDust;
  final bool showRockGardens;
  final bool showWoodenBridgesAndJumps;
  final bool showLineChoiceMarkers;
  final bool showTelemetryOverlay;

  const MtbForestRockGarden3dConfig({
    this.biomePreset = MtbForestBiomePreset.noveMestoPineForest,
    this.cameraMode = MtbCameraViewMode.chaseSingletrack,
    this.selectedLineChoice = MtbTrailLineChoice.aLine,
    this.fieldOfViewDegrees = 58.0,
    this.maxDrawDistanceMeters = 185.0,
    this.trailWidthMeters = 2.7,
    this.sunbeamIntensity = 0.88,
    this.dustDensity = 0.84,
    this.canopyDensity = 0.86,
    this.riderSpeedKmh = 27.5,
    this.showSunbeamsAndDust = true,
    this.showRockGardens = true,
    this.showWoodenBridgesAndJumps = true,
    this.showLineChoiceMarkers = true,
    this.showTelemetryOverlay = true,
  });

  MtbForestRockGarden3dConfig copyWith({
    MtbForestBiomePreset? biomePreset,
    MtbCameraViewMode? cameraMode,
    MtbTrailLineChoice? selectedLineChoice,
    double? fieldOfViewDegrees,
    double? maxDrawDistanceMeters,
    double? trailWidthMeters,
    double? sunbeamIntensity,
    double? dustDensity,
    double? canopyDensity,
    double? riderSpeedKmh,
    bool? showSunbeamsAndDust,
    bool? showRockGardens,
    bool? showWoodenBridgesAndJumps,
    bool? showLineChoiceMarkers,
    bool? showTelemetryOverlay,
  }) {
    return MtbForestRockGarden3dConfig(
      biomePreset: biomePreset ?? this.biomePreset,
      cameraMode: cameraMode ?? this.cameraMode,
      selectedLineChoice: selectedLineChoice ?? this.selectedLineChoice,
      fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
      maxDrawDistanceMeters:
          maxDrawDistanceMeters ?? this.maxDrawDistanceMeters,
      trailWidthMeters: trailWidthMeters ?? this.trailWidthMeters,
      sunbeamIntensity: sunbeamIntensity ?? this.sunbeamIntensity,
      dustDensity: dustDensity ?? this.dustDensity,
      canopyDensity: canopyDensity ?? this.canopyDensity,
      riderSpeedKmh: riderSpeedKmh ?? this.riderSpeedKmh,
      showSunbeamsAndDust: showSunbeamsAndDust ?? this.showSunbeamsAndDust,
      showRockGardens: showRockGardens ?? this.showRockGardens,
      showWoodenBridgesAndJumps:
          showWoodenBridgesAndJumps ?? this.showWoodenBridgesAndJumps,
      showLineChoiceMarkers:
          showLineChoiceMarkers ?? this.showLineChoiceMarkers,
      showTelemetryOverlay: showTelemetryOverlay ?? this.showTelemetryOverlay,
    );
  }
}

/// Próbka geometrii osi ścieżki singletrack w przestrzeni 3D.
class MtbTrailSegmentSample3D {
  final double distanceMeters;
  final double centerX;
  final double elevationY;
  final double tangentSlope;
  final double lateralCamber;
  final MtbXcoFeatureType featureType;

  const MtbTrailSegmentSample3D({
    required this.distanceMeters,
    required this.centerX,
    required this.elevationY,
    required this.tangentSlope,
    required this.lateralCamber,
    required this.featureType,
  });
}

/// Głaz w sekcji Rock Garden na leśnej trasie MTB XCO.
class MtbRockGardenBoulder3D {
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double radiusMeters;
  final double heightMeters;
  final int facetSeed;
  final bool isALineObstacle;
  final bool hasCourseTape;

  const MtbRockGardenBoulder3D({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.radiusMeters,
    required this.heightMeters,
    required this.facetSeed,
    required this.isALineObstacle,
    required this.hasCourseTape,
  });
}

/// Drewniany mostek lub kładka nad leśnym strumieniem / wąwozem.
class MtbWoodenBridge3D {
  final double startDistanceMeters;
  final double lengthMeters;
  final double widthMeters;
  final double deckElevationOffsetMeters;
  final bool hasSideRails;
  final int plankCount;

  const MtbWoodenBridge3D({
    required this.startDistanceMeters,
    required this.lengthMeters,
    required this.widthMeters,
    required this.deckElevationOffsetMeters,
    required this.hasSideRails,
    required this.plankCount,
  });
}

/// Drewniano-ziemna skocznia (kicker) z lądowaniem na trasie MTB XCO.
class MtbTrailJumpRamp3D {
  final double takeoffDistanceMeters;
  final double rampLengthMeters;
  final double rampHeightMeters;
  final double gapLengthMeters;
  final bool isTabletop;

  const MtbTrailJumpRamp3D({
    required this.takeoffDistanceMeters,
    required this.rampLengthMeters,
    required this.rampHeightMeters,
    required this.gapLengthMeters,
    required this.isTabletop,
  });

  double get landingDistanceMeters =>
      takeoffDistanceMeters + rampLengthMeters + gapLengthMeters;
}

/// Drzewo leśne z pniem i warstwą korony filtrującą promienie słońca.
class MtbForestTree3D {
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double trunkHeightMeters;
  final double canopyRadiusMeters;
  final int treeVariant;
  final double swayPhase;

  const MtbForestTree3D({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.trunkHeightMeters,
    required this.canopyRadiusMeters,
    required this.treeVariant,
    required this.swayPhase,
  });
}

/// Promień światła słonecznego przebijający przez lukę w koronach drzew.
class MtbSunbeamShaft3D {
  final double distanceMeters;
  final double lateralOriginMeters;
  final double widthMeters;
  final double tiltAngleRad;
  final double intensity;

  const MtbSunbeamShaft3D({
    required this.distanceMeters,
    required this.lateralOriginMeters,
    required this.widthMeters,
    required this.tiltAngleRad,
    required this.intensity,
  });
}

/// Cząsteczka kurzu i pyłu unosząca się w lesie i rozświetlana w promieniach.
class MtbDustMoteParticle3D {
  final Vector3 position;
  final double radiusMeters;
  final double alpha;
  final double sunlitGlowFactor;

  const MtbDustMoteParticle3D({
    required this.position,
    required this.radiusMeters,
    required this.alpha,
    required this.sunlitGlowFactor,
  });
}

/// Kolarz MTB XCO z parametrami zawieszenia, skoku i wyboru linii.
class MtbXcoRider3D {
  final String id;
  final String name;
  final Color jerseyColor;
  final Color accentColor;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double speedKmh;
  final double cadenceRpm;
  final double suspensionCompression;
  final double airborneHeightMeters;
  final double pitchAngleRad;
  final bool dropperDown;
  final MtbTrailLineChoice lineChoice;
  final bool isLeader;

  const MtbXcoRider3D({
    required this.id,
    required this.name,
    required this.jerseyColor,
    required this.accentColor,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.speedKmh,
    required this.cadenceRpm,
    required this.suspensionCompression,
    required this.airborneHeightMeters,
    required this.pitchAngleRad,
    required this.dropperDown,
    required this.lineChoice,
    required this.isLeader,
  });
}

/// Telemetria pojedynczej wyrenderowanej klatki sceny 3D MTB XCO.
class MtbForestRockGardenTelemetry {
  final int visibleTrailSlices;
  final int visibleBoulders;
  final int visibleBridges;
  final int visibleJumps;
  final int visibleTrees;
  final int activeSunbeams;
  final int activeDustMotes;
  final int activeRiders;
  final MtbXcoFeatureType currentFeature;
  final double leaderSpeedKmh;
  final double leaderAirborneMeters;
  final double suspensionTravelPercent;
  final double sunbeamDustScatterIndex;

  const MtbForestRockGardenTelemetry({
    required this.visibleTrailSlices,
    required this.visibleBoulders,
    required this.visibleBridges,
    required this.visibleJumps,
    required this.visibleTrees,
    required this.activeSunbeams,
    required this.activeDustMotes,
    required this.activeRiders,
    required this.currentFeature,
    required this.leaderSpeedKmh,
    required this.leaderAirborneMeters,
    required this.suspensionTravelPercent,
    required this.sunbeamDustScatterIndex,
  });

  factory MtbForestRockGardenTelemetry.empty() {
    return const MtbForestRockGardenTelemetry(
      visibleTrailSlices: 0,
      visibleBoulders: 0,
      visibleBridges: 0,
      visibleJumps: 0,
      visibleTrees: 0,
      activeSunbeams: 0,
      activeDustMotes: 0,
      activeRiders: 0,
      currentFeature: MtbXcoFeatureType.rockGarden,
      leaderSpeedKmh: 0.0,
      leaderAirborneMeters: 0.0,
      suspensionTravelPercent: 0.0,
      sunbeamDustScatterIndex: 0.0,
    );
  }
}

// =============================================================================
// 3. WEWNĘTRZNY ELEMENT SORTOWANIA Z-BUFFERA
// =============================================================================

class _ProjectedItem {
  final double depth;
  final void Function(Canvas canvas) draw;

  const _ProjectedItem({
    required this.depth,
    required this.draw,
  });
}

// =============================================================================
// 4. SILNIK RENDEROWANIA 3D LEŚNEJ TRASY MTB XCO
// =============================================================================

/// Proceduralny renderer 3D leśnej trasy MTB XCO z głazami (Rock Garden),
/// drewnianymi mostkami, skoczniami i kurzem w promieniach słońca.
class MtbForestRockGarden3dRenderer {
  static const double _lapCycleMeters = 320.0;

  const MtbForestRockGarden3dRenderer();

  /// Wylicza próbkę ścieżki singletrack dla zadanego dystansu [distanceMeters].
  MtbTrailSegmentSample3D sampleTrailAt(double distanceMeters) {
    final double wrapped = distanceMeters % _lapCycleMeters;
    final double curveX = math.sin(distanceMeters * 0.042) * 4.4 +
        math.cos(distanceMeters * 0.019) * 2.6;
    final double elevationY = math.sin(distanceMeters * 0.032) * 2.4 +
        math.cos(distanceMeters * 0.068) * 0.75;
    final double slope = math.cos(distanceMeters * 0.032) * 2.4 * 0.032 -
        math.sin(distanceMeters * 0.068) * 0.75 * 0.068;
    final double camber = math.cos(distanceMeters * 0.042) * 0.14;

    final MtbXcoFeatureType feature = _featureForWrappedDistance(wrapped);

    return MtbTrailSegmentSample3D(
      distanceMeters: distanceMeters,
      centerX: curveX,
      elevationY: elevationY,
      tangentSlope: slope,
      lateralCamber: camber,
      featureType: feature,
    );
  }

  MtbXcoFeatureType _featureForWrappedDistance(double wrapped) {
    if (wrapped < 68.0) {
      return MtbXcoFeatureType.rockGarden;
    }
    if (wrapped < 120.0) {
      return MtbXcoFeatureType.woodBridge;
    }
    if (wrapped < 185.0) {
      return MtbXcoFeatureType.pumpRollers;
    }
    if (wrapped < 245.0) {
      return MtbXcoFeatureType.dropOff;
    }
    if (wrapped < 285.0) {
      return MtbXcoFeatureType.rootSection;
    }
    return MtbXcoFeatureType.bermSwitchback;
  }

  /// Generuje deterministyczne głazy Rock Garden dla okna widoczności kamery.
  List<MtbRockGardenBoulder3D> generateVisibleBoulders({
    required double minDistanceMeters,
    required double maxDistanceMeters,
  }) {
    final List<MtbRockGardenBoulder3D> boulders = <MtbRockGardenBoulder3D>[];
    final int startBlock = (minDistanceMeters / _lapCycleMeters).floor() - 1;
    final int endBlock = (maxDistanceMeters / _lapCycleMeters).ceil();

    for (int block = startBlock; block <= endBlock; block++) {
      final double baseDist = block * _lapCycleMeters;
      // Główny Rock Garden (0..68 m w cyklu) oraz mniejsza sekcja przy 245..280 m
      for (int i = 0; i < 18; i++) {
        final double d = baseDist + 8.0 + i * 3.3;
        if (d < minDistanceMeters || d > maxDistanceMeters) continue;
        final double lat = math.sin(i * 2.17 + block * 1.3) * 1.45;
        final double radius = 0.36 + ((i * 37) % 10) * 0.045;
        final double height = 0.24 + ((i * 23) % 8) * 0.055;
        boulders.add(
          MtbRockGardenBoulder3D(
            distanceMeters: d,
            lateralOffsetMeters: lat,
            radiusMeters: radius,
            heightMeters: height,
            facetSeed: i * 17 + block * 31,
            isALineObstacle: lat.abs() < 0.72,
            hasCourseTape: i % 4 == 0,
          ),
        );
      }

      for (int i = 0; i < 7; i++) {
        final double d = baseDist + 248.0 + i * 4.4;
        if (d < minDistanceMeters || d > maxDistanceMeters) continue;
        final double lat = math.cos(i * 1.83 + block * 0.7) * 1.35;
        boulders.add(
          MtbRockGardenBoulder3D(
            distanceMeters: d,
            lateralOffsetMeters: lat,
            radiusMeters: 0.34 + (i % 4) * 0.06,
            heightMeters: 0.22 + (i % 3) * 0.06,
            facetSeed: 500 + i * 19 + block * 13,
            isALineObstacle: lat < 0.2,
            hasCourseTape: i == 0 || i == 6,
          ),
        );
      }
    }
    return boulders;
  }

  /// Generuje drewniane mostki nad leśnymi jarami w oknie widoczności.
  List<MtbWoodenBridge3D> generateVisibleBridges({
    required double minDistanceMeters,
    required double maxDistanceMeters,
  }) {
    final List<MtbWoodenBridge3D> bridges = <MtbWoodenBridge3D>[];
    final int startBlock = (minDistanceMeters / _lapCycleMeters).floor() - 1;
    final int endBlock = (maxDistanceMeters / _lapCycleMeters).ceil();

    for (int block = startBlock; block <= endBlock; block++) {
      final double baseDist = block * _lapCycleMeters;
      final List<(double, double, bool)> specs = <(double, double, bool)>[
        (baseDist + 78.0, 16.0, true),
        (baseDist + 216.0, 12.5, false),
      ];
      for (final (double startD, double len, bool rails) in specs) {
        if (startD + len < minDistanceMeters || startD > maxDistanceMeters) {
          continue;
        }
        bridges.add(
          MtbWoodenBridge3D(
            startDistanceMeters: startD,
            lengthMeters: len,
            widthMeters: 2.05,
            deckElevationOffsetMeters: 0.32,
            hasSideRails: rails,
            plankCount: (len * 2.4).round(),
          ),
        );
      }
    }
    return bridges;
  }

  /// Generuje drewniano-ziemne skocznie (kickers & tabletops) w oknie widoczności.
  List<MtbTrailJumpRamp3D> generateVisibleJumps({
    required double minDistanceMeters,
    required double maxDistanceMeters,
  }) {
    final List<MtbTrailJumpRamp3D> jumps = <MtbTrailJumpRamp3D>[];
    final int startBlock = (minDistanceMeters / _lapCycleMeters).floor() - 1;
    final int endBlock = (maxDistanceMeters / _lapCycleMeters).ceil();

    for (int block = startBlock; block <= endBlock; block++) {
      final double baseDist = block * _lapCycleMeters;
      final List<MtbTrailJumpRamp3D> candidates = <MtbTrailJumpRamp3D>[
        MtbTrailJumpRamp3D(
          takeoffDistanceMeters: baseDist + 134.0,
          rampLengthMeters: 3.4,
          rampHeightMeters: 0.92,
          gapLengthMeters: 4.6,
          isTabletop: true,
        ),
        MtbTrailJumpRamp3D(
          takeoffDistanceMeters: baseDist + 164.0,
          rampLengthMeters: 3.0,
          rampHeightMeters: 1.05,
          gapLengthMeters: 5.2,
          isTabletop: false,
        ),
      ];
      for (final MtbTrailJumpRamp3D jump in candidates) {
        if (jump.landingDistanceMeters < minDistanceMeters ||
            jump.takeoffDistanceMeters > maxDistanceMeters) {
          continue;
        }
        jumps.add(jump);
      }
    }
    return jumps;
  }

  /// Generuje kolarzy MTB XCO jadących i skaczących po leśnej ścieżce.
  List<MtbXcoRider3D> generateRiders({
    required double leaderDistanceMeters,
    required double simulationTimeSeconds,
    required MtbForestRockGarden3dConfig config,
    required List<MtbTrailJumpRamp3D> visibleJumps,
    required List<MtbRockGardenBoulder3D> visibleBoulders,
  }) {
    const List<(String, String, Color, Color, double, double)> roster =
        <(String, String, Color, Color, double, double)>[
      (
        'mtb_1',
        'T. Pidcock',
        AppColors.goldAccent,
        Color(0xFF1F242E),
        0.0,
        0.0,
      ),
      (
        'mtb_2',
        'N. Schurter',
        Color(0xFFDC2626),
        Color(0xFFF3F4F6),
        -7.5,
        -0.55,
      ),
      (
        'mtb_3',
        'V. Koretzky',
        Color(0xFF2563EB),
        Color(0xFF93C5FD),
        -15.2,
        0.52,
      ),
      (
        'mtb_4',
        'M. Flückiger',
        Color(0xFF10B981),
        Color(0xFFD1FAE5),
        -24.0,
        -0.38,
      ),
      (
        'mtb_5',
        'A. Hatherly',
        AppColors.primaryAccent,
        Color(0xFFFCA5A5),
        -34.5,
        0.44,
      ),
    ];

    final List<MtbXcoRider3D> riders = <MtbXcoRider3D>[];
    for (int i = 0; i < roster.length; i++) {
      final (
        String id,
        String name,
        Color jersey,
        Color accent,
        double offsetD,
        double baseLat,
      ) = roster[i];
      final double d = leaderDistanceMeters + offsetD;
      final MtbTrailSegmentSample3D seg = sampleTrailAt(d);
      final MtbTrailLineChoice line = i == 0
          ? config.selectedLineChoice
          : (i.isEven
              ? MtbTrailLineChoice.aLine
              : MtbTrailLineChoice.bLine);

      final double lineShift =
          line == MtbTrailLineChoice.aLine ? -0.45 : 0.68;
      final double lat = (baseLat +
              lineShift * 0.5 +
              math.sin(simulationTimeSeconds * 1.6 + i) * 0.14)
          .clamp(-1.1, 1.1);

      // Oblicz wysokość skoku nad rampami
      double airHeight = 0.0;
      double pitchRad = seg.tangentSlope * 0.8;
      for (final MtbTrailJumpRamp3D jump in visibleJumps) {
        if (d >= jump.takeoffDistanceMeters &&
            d <= jump.takeoffDistanceMeters + jump.rampLengthMeters) {
          final double t =
              (d - jump.takeoffDistanceMeters) / jump.rampLengthMeters;
          airHeight = jump.rampHeightMeters * t;
          pitchRad = -0.34;
        } else if (d > jump.takeoffDistanceMeters + jump.rampLengthMeters &&
            d <= jump.landingDistanceMeters) {
          final double t =
              (d - (jump.takeoffDistanceMeters + jump.rampLengthMeters)) /
                  jump.gapLengthMeters;
          // Paraboliczna trajektoria lotu po wybiciu ze skoczni
          final double arc = 4.0 * t * (1.0 - t);
          airHeight = jump.rampHeightMeters * (1.0 - t * 0.55) + arc * 0.95;
          pitchRad = -0.25 + t * 0.55;
        }
      }

      // Oblicz kompresję zawieszenia na głazach lub lądowaniu
      double compression = 0.18 +
          0.12 * math.sin(simulationTimeSeconds * 9.0 + i * 1.4).abs();
      if (seg.featureType == MtbXcoFeatureType.rockGarden) {
        compression = 0.52 +
            0.34 * math.sin(simulationTimeSeconds * 18.0 + d * 0.9).abs();
        for (final MtbRockGardenBoulder3D b in visibleBoulders) {
          if ((b.distanceMeters - d).abs() < 1.1 &&
              (b.lateralOffsetMeters - lat).abs() < 0.7) {
            compression = 0.92;
            break;
          }
        }
      } else if (airHeight > 0.05) {
        compression = 0.08;
      }

      final bool dropperDown =
          seg.featureType == MtbXcoFeatureType.rockGarden ||
              seg.featureType == MtbXcoFeatureType.dropOff ||
              seg.featureType == MtbXcoFeatureType.pumpRollers ||
              airHeight > 0.05;

      final double speedVariation = (config.riderSpeedKmh - i * 0.6 +
              math.sin(simulationTimeSeconds * 0.9 + i) * 1.2)
          .clamp(12.0, 52.0);

      riders.add(
        MtbXcoRider3D(
          id: id,
          name: name,
          jerseyColor: jersey,
          accentColor: accent,
          distanceMeters: d,
          lateralOffsetMeters: lat,
          speedKmh: speedVariation,
          cadenceRpm: airHeight > 0.1 ? 0.0 : 86.0 + (i % 3) * 4.0,
          suspensionCompression: compression.clamp(0.0, 1.0),
          airborneHeightMeters: airHeight,
          pitchAngleRad: pitchRad,
          dropperDown: dropperDown,
          lineChoice: line,
          isLeader: i == 0,
        ),
      );
    }
    return riders;
  }

  /// Renderuje pełną klatkę sceny 3D na przekazanym [Canvas] i zwraca telemetrię.
  MtbForestRockGardenTelemetry renderFrame({
    required Canvas canvas,
    required Size size,
    required double leaderDistanceMeters,
    required double simulationTimeSeconds,
    required MtbForestRockGarden3dConfig config,
  }) {
    if (size.width <= 1.0 || size.height <= 1.0) {
      return MtbForestRockGardenTelemetry.empty();
    }

    final MtbForestBiomePreset biome = config.biomePreset;
    final double fovRad = config.fieldOfViewDegrees * (math.pi / 180.0);
    final double focalLength =
        (size.height * 0.5) / math.tan(fovRad * 0.5).clamp(0.2, 4.0);
    final double horizonY = size.height *
        (config.cameraMode == MtbCameraViewMode.canopySunbeamOverview
            ? 0.44
            : 0.36);

    // 1. Tło leśnego baldachimu i dna lasu
    _drawForestBackdrop(
      canvas: canvas,
      size: size,
      horizonY: horizonY,
      biome: biome,
      config: config,
    );

    // 2. Ustawienie kamery 3D w zależności od trybu
    final double camDist = _resolveCameraDistance(
      leaderDistanceMeters: leaderDistanceMeters,
      mode: config.cameraMode,
    );
    final MtbTrailSegmentSample3D camSeg = sampleTrailAt(camDist);
    final MtbTrailSegmentSample3D lookSeg = sampleTrailAt(camDist + 14.0);

    final double camHeight = switch (config.cameraMode) {
      MtbCameraViewMode.chaseSingletrack => 2.35,
      MtbCameraViewMode.rockGardenTrackside => 1.65,
      MtbCameraViewMode.jumpKickerLowAngle => 1.15,
      MtbCameraViewMode.canopySunbeamOverview => 5.6,
    };
    final double camLateralOffset = switch (config.cameraMode) {
      MtbCameraViewMode.chaseSingletrack => 0.35,
      MtbCameraViewMode.rockGardenTrackside => 2.9,
      MtbCameraViewMode.jumpKickerLowAngle => -2.4,
      MtbCameraViewMode.canopySunbeamOverview => 1.4,
    };

    final Vector3 camPos = Vector3(
      camSeg.centerX + camLateralOffset,
      camSeg.elevationY + camHeight,
      camDist,
    );
    final double yaw = math.atan2(
      lookSeg.centerX - camPos.x,
      lookSeg.distanceMeters - camPos.z,
    );
    final double cosYaw = math.cos(yaw);
    final double sinYaw = math.sin(yaw);

    Offset? projectPoint(Vector3 world) {
      final double dx = world.x - camPos.x;
      final double dy = world.y - camPos.y;
      final double dz = world.z - camPos.z;

      final double rx = dx * cosYaw - dz * sinYaw;
      final double rz = dx * sinYaw + dz * cosYaw;

      if (rz <= 1.2 || rz > config.maxDrawDistanceMeters) {
        return null;
      }

      final double invZ = focalLength / rz;
      final double sx = size.width * 0.5 + rx * invZ;
      final double sy = horizonY - dy * invZ;
      return Offset(sx, sy);
    }

    double depthOf(Vector3 world) {
      final double dx = world.x - camPos.x;
      final double dz = world.z - camPos.z;
      return dx * sinYaw + dz * cosYaw;
    }

    final double minVisDist = camDist + 1.5;
    final double maxVisDist = camDist + config.maxDrawDistanceMeters;

    // 3. Zbieranie elementów 3D i sortowanie Z (Painter's Algorithm)
    final List<_ProjectedItem> drawQueue = <_ProjectedItem>[];

    // 3a. Wstęga ścieżki singletrack
    int visibleTrailSlices = 0;
    const double sliceStep = 3.2;
    for (double d = minVisDist; d < maxVisDist - sliceStep; d += sliceStep) {
      final MtbTrailSegmentSample3D s0 = sampleTrailAt(d);
      final MtbTrailSegmentSample3D s1 = sampleTrailAt(d + sliceStep);
      final double halfW = config.trailWidthMeters * 0.5;

      final Offset? p0L = projectPoint(
        Vector3(s0.centerX - halfW, s0.elevationY, s0.distanceMeters),
      );
      final Offset? p0R = projectPoint(
        Vector3(s0.centerX + halfW, s0.elevationY, s0.distanceMeters),
      );
      final Offset? p1L = projectPoint(
        Vector3(s1.centerX - halfW, s1.elevationY, s1.distanceMeters),
      );
      final Offset? p1R = projectPoint(
        Vector3(s1.centerX + halfW, s1.elevationY, s1.distanceMeters),
      );

      if (p0L == null || p0R == null || p1L == null || p1R == null) {
        continue;
      }

      visibleTrailSlices++;
      final double depth = depthOf(
        Vector3(s0.centerX, s0.elevationY, s0.distanceMeters),
      );
      final double fogT = (depth / config.maxDrawDistanceMeters).clamp(0.0, 1.0);

      drawQueue.add(
        _ProjectedItem(
          depth: depth + 4.0,
          draw: (Canvas c) {
            final Path trailPath = Path()
              ..moveTo(p0L.dx, p0L.dy)
              ..lineTo(p0R.dx, p0R.dy)
              ..lineTo(p1R.dx, p1R.dy)
              ..lineTo(p1L.dx, p1L.dy)
              ..close();

            final Color surfaceColor = Color.lerp(
              biome.trailSurfaceColor,
              biome.canopyMidColor,
              fogT * 0.65,
            )!;
            c.drawPath(
              trailPath,
              Paint()..color = surfaceColor,
            );

            // Koleina opon pośrodku ścieżki
            final Offset rut0L = Offset.lerp(p0L, p0R, 0.36)!;
            final Offset rut0R = Offset.lerp(p0L, p0R, 0.64)!;
            final Offset rut1L = Offset.lerp(p1L, p1R, 0.36)!;
            final Offset rut1R = Offset.lerp(p1L, p1R, 0.64)!;
            final Path rutPath = Path()
              ..moveTo(rut0L.dx, rut0L.dy)
              ..lineTo(rut0R.dx, rut0R.dy)
              ..lineTo(rut1R.dx, rut1R.dy)
              ..lineTo(rut1L.dx, rut1L.dy)
              ..close();
            c.drawPath(
              rutPath,
              Paint()
                ..color = Color.lerp(
                  biome.trailRutColor,
                  biome.canopyMidColor,
                  fogT * 0.7,
                )!,
            );

            // Znaczniki linii A-Line / B-Line w sekcjach technicznych
            if (config.showLineChoiceMarkers &&
                s0.featureType.hasTypicalLineChoice) {
              final bool isA =
                  config.selectedLineChoice == MtbTrailLineChoice.aLine;
              final Offset lineMarker0 = Offset.lerp(
                p0L,
                p0R,
                isA ? 0.28 : 0.75,
              )!;
              final Offset lineMarker1 = Offset.lerp(
                p1L,
                p1R,
                isA ? 0.28 : 0.75,
              )!;
              c.drawLine(
                lineMarker0,
                lineMarker1,
                Paint()
                  ..color = (isA
                          ? AppColors.goldAccent
                          : AppColors.accentBlue)
                      .withValues(alpha: (1.0 - fogT) * 0.55)
                  ..strokeWidth = (2.8 * (1.0 - fogT)).clamp(0.8, 3.0),
              );
            }
          },
        ),
      );
    }

    // 3b. Drewniane mostki nad wąwozem
    final List<MtbWoodenBridge3D> bridges = config.showWoodenBridgesAndJumps
        ? generateVisibleBridges(
            minDistanceMeters: minVisDist,
            maxDistanceMeters: maxVisDist,
          )
        : const <MtbWoodenBridge3D>[];

    for (final MtbWoodenBridge3D bridge in bridges) {
      final int planks = bridge.plankCount;
      final double step = bridge.lengthMeters / planks;
      for (int p = 0; p < planks; p++) {
        final double d0 = bridge.startDistanceMeters + p * step;
        final double d1 = d0 + step * 0.86;
        final MtbTrailSegmentSample3D s0 = sampleTrailAt(d0);
        final MtbTrailSegmentSample3D s1 = sampleTrailAt(d1);
        final double halfW = bridge.widthMeters * 0.5;
        final double y0 = s0.elevationY + bridge.deckElevationOffsetMeters;
        final double y1 = s1.elevationY + bridge.deckElevationOffsetMeters;

        final Offset? p0L =
            projectPoint(Vector3(s0.centerX - halfW, y0, d0));
        final Offset? p0R =
            projectPoint(Vector3(s0.centerX + halfW, y0, d0));
        final Offset? p1L =
            projectPoint(Vector3(s1.centerX - halfW, y1, d1));
        final Offset? p1R =
            projectPoint(Vector3(s1.centerX + halfW, y1, d1));
        if (p0L == null || p0R == null || p1L == null || p1R == null) {
          continue;
        }
        final double depth = depthOf(Vector3(s0.centerX, y0, d0));
        final double fogT =
            (depth / config.maxDrawDistanceMeters).clamp(0.0, 1.0);

        Offset? rail0L;
        Offset? rail1L;
        Offset? rail0R;
        Offset? rail1R;
        if (bridge.hasSideRails && p % 2 == 0) {
          rail0L = projectPoint(Vector3(s0.centerX - halfW, y0 + 0.68, d0));
          rail1L = projectPoint(Vector3(s1.centerX - halfW, y1 + 0.68, d1));
          rail0R = projectPoint(Vector3(s0.centerX + halfW, y0 + 0.68, d0));
          rail1R = projectPoint(Vector3(s1.centerX + halfW, y1 + 0.68, d1));
        }

        drawQueue.add(
          _ProjectedItem(
            depth: depth + 1.5,
            draw: (Canvas c) {
              final Path plank = Path()
                ..moveTo(p0L.dx, p0L.dy)
                ..lineTo(p0R.dx, p0R.dy)
                ..lineTo(p1R.dx, p1R.dy)
                ..lineTo(p1L.dx, p1L.dy)
                ..close();
              final Color woodColor = Color.lerp(
                p.isEven
                    ? biome.woodPlankColor
                    : biome.woodPlankColor.withValues(alpha: 0.85),
                biome.canopyMidColor,
                fogT * 0.55,
              )!;
              c.drawPath(plank, Paint()..color = woodColor);
              c.drawPath(
                plank,
                Paint()
                  ..color = Colors.black.withValues(alpha: 0.25 * (1.0 - fogT))
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 0.8,
              );

              if (rail0L != null &&
                  rail1L != null &&
                  rail0R != null &&
                  rail1R != null) {
                final Paint railPaint = Paint()
                  ..color = Color.lerp(
                    biome.woodPlankColor.withValues(alpha: 0.92),
                    biome.canopyMidColor,
                    fogT * 0.5,
                  )!
                  ..strokeWidth = (2.4 * (1.0 - fogT)).clamp(0.8, 2.6);
                c.drawLine(p0L, rail0L, railPaint);
                c.drawLine(p0R, rail0R, railPaint);
                c.drawLine(rail0L, rail1L, railPaint);
                c.drawLine(rail0R, rail1R, railPaint);
              }
            },
          ),
        );
      }
    }

    // 3c. Skocznie (kicker ramps)
    final List<MtbTrailJumpRamp3D> jumps = config.showWoodenBridgesAndJumps
        ? generateVisibleJumps(
            minDistanceMeters: minVisDist,
            maxDistanceMeters: maxVisDist,
          )
        : const <MtbTrailJumpRamp3D>[];

    for (final MtbTrailJumpRamp3D jump in jumps) {
      final MtbTrailSegmentSample3D sBase =
          sampleTrailAt(jump.takeoffDistanceMeters);
      final MtbTrailSegmentSample3D sLip =
          sampleTrailAt(jump.takeoffDistanceMeters + jump.rampLengthMeters);
      const double halfW = 1.15;

      final Offset? bL = projectPoint(
        Vector3(sBase.centerX - halfW, sBase.elevationY, sBase.distanceMeters),
      );
      final Offset? bR = projectPoint(
        Vector3(sBase.centerX + halfW, sBase.elevationY, sBase.distanceMeters),
      );
      final Offset? lipL = projectPoint(
        Vector3(
          sLip.centerX - halfW,
          sLip.elevationY + jump.rampHeightMeters,
          sLip.distanceMeters,
        ),
      );
      final Offset? lipR = projectPoint(
        Vector3(
          sLip.centerX + halfW,
          sLip.elevationY + jump.rampHeightMeters,
          sLip.distanceMeters,
        ),
      );
      final Offset? lipBaseL = projectPoint(
        Vector3(sLip.centerX - halfW, sLip.elevationY, sLip.distanceMeters),
      );
      final Offset? lipBaseR = projectPoint(
        Vector3(sLip.centerX + halfW, sLip.elevationY, sLip.distanceMeters),
      );

      if (bL != null &&
          bR != null &&
          lipL != null &&
          lipR != null &&
          lipBaseL != null &&
          lipBaseR != null) {
        final double depth = depthOf(
          Vector3(sLip.centerX, sLip.elevationY, sLip.distanceMeters),
        );
        final double fogT =
            (depth / config.maxDrawDistanceMeters).clamp(0.0, 1.0);
        drawQueue.add(
          _ProjectedItem(
            depth: depth + 1.0,
            draw: (Canvas c) {
              // Drewniana powierzchnia wybicia skoczni
              final Path deck = Path()
                ..moveTo(bL.dx, bL.dy)
                ..lineTo(bR.dx, bR.dy)
                ..lineTo(lipR.dx, lipR.dy)
                ..lineTo(lipL.dx, lipL.dy)
                ..close();
              c.drawPath(
                deck,
                Paint()
                  ..color = Color.lerp(
                    biome.woodPlankColor,
                    biome.canopyMidColor,
                    fogT * 0.5,
                  )!,
              );

              // Przednia ścianka wsporcza pod wybiciem
              final Path face = Path()
                ..moveTo(lipL.dx, lipL.dy)
                ..lineTo(lipR.dx, lipR.dy)
                ..lineTo(lipBaseR.dx, lipBaseR.dy)
                ..lineTo(lipBaseL.dx, lipBaseL.dy)
                ..close();
              c.drawPath(
                face,
                Paint()
                  ..color = Color.lerp(
                    biome.woodPlankColor.withValues(alpha: 0.65),
                    Colors.black,
                    0.35 + fogT * 0.3,
                  )!,
              );

              // Ostrzegawcza krawędź wybicia (pomarańczowo-złoty pas)
              c.drawLine(
                lipL,
                lipR,
                Paint()
                  ..color = AppColors.goldAccent.withValues(alpha: 1.0 - fogT)
                  ..strokeWidth = (3.0 * (1.0 - fogT)).clamp(1.0, 3.2),
              );
            },
          ),
        );
      }
    }

    // 3d. Głazy Rock Garden
    final List<MtbRockGardenBoulder3D> boulders = config.showRockGardens
        ? generateVisibleBoulders(
            minDistanceMeters: minVisDist,
            maxDistanceMeters: maxVisDist,
          )
        : const <MtbRockGardenBoulder3D>[];

    int visibleBoulders = 0;
    for (final MtbRockGardenBoulder3D boulder in boulders) {
      final MtbTrailSegmentSample3D seg = sampleTrailAt(boulder.distanceMeters);
      final Vector3 basePos = Vector3(
        seg.centerX + boulder.lateralOffsetMeters,
        seg.elevationY,
        boulder.distanceMeters,
      );
      final Offset? centerScreen = projectPoint(basePos);
      final Offset? topScreen = projectPoint(
        Vector3(basePos.x, basePos.y + boulder.heightMeters, basePos.z),
      );
      final Offset? rightScreen = projectPoint(
        Vector3(basePos.x + boulder.radiusMeters, basePos.y, basePos.z),
      );
      if (centerScreen == null || topScreen == null || rightScreen == null) {
        continue;
      }

      visibleBoulders++;
      final double depth = depthOf(basePos);
      final double fogT = (depth / config.maxDrawDistanceMeters).clamp(0.0, 1.0);
      final double rx = (rightScreen.dx - centerScreen.dx).abs().clamp(2.5, 64.0);
      final double ry = (centerScreen.dy - topScreen.dy).abs().clamp(2.0, 52.0);

      drawQueue.add(
        _ProjectedItem(
          depth: depth,
          draw: (Canvas c) {
            _drawFacetedBoulder(
              canvas: c,
              center: centerScreen,
              rx: rx,
              ry: ry,
              seed: boulder.facetSeed,
              biome: biome,
              fogT: fogT,
              hasTape: boulder.hasCourseTape,
            );
          },
        ),
      );
    }

    // 3e. Leśne drzewa (pnie i korony po obu stronach singletracka)
    int visibleTrees = 0;
    const double treeStep = 5.5;
    final double firstTreeDist = (minVisDist / treeStep).floor() * treeStep;
    for (double d = firstTreeDist; d < maxVisDist; d += treeStep) {
      final int idx = (d / treeStep).round();
      final MtbTrailSegmentSample3D seg = sampleTrailAt(d);

      for (final int side in const <int>[-1, 1]) {
        // Rzadkie luki w koronach drzew tworzą naturalne okna na promienie słońca
        if ((idx + (side == 1 ? 3 : 0)) % 5 == 0 &&
            config.canopyDensity < 0.92) {
          continue;
        }
        final double latOffset = side *
            (2.8 +
                ((idx * 17 + (side + 2) * 11) % 7) * 0.85 +
                (1.0 - config.canopyDensity) * 1.4);
        final double trunkH = 7.5 + ((idx * 13) % 5) * 1.4;
        final double canopyR = 2.6 + ((idx * 7) % 4) * 0.55;

        final Vector3 basePos = Vector3(
          seg.centerX + latOffset,
          seg.elevationY,
          d,
        );
        final Offset? baseScreen = projectPoint(basePos);
        final Offset? topScreen = projectPoint(
          Vector3(basePos.x, basePos.y + trunkH, basePos.z),
        );
        final Offset? canopyEdge = projectPoint(
          Vector3(basePos.x + canopyR, basePos.y + trunkH * 0.72, basePos.z),
        );

        if (baseScreen == null || topScreen == null || canopyEdge == null) {
          continue;
        }

        visibleTrees++;
        final double depth = depthOf(basePos);
        final double fogT =
            (depth / config.maxDrawDistanceMeters).clamp(0.0, 1.0);
        final double screenCanopyR =
            (canopyEdge.dx - topScreen.dx).abs().clamp(6.0, 140.0);

        drawQueue.add(
          _ProjectedItem(
            depth: depth,
            draw: (Canvas c) {
              _drawForestTree(
                canvas: c,
                base: baseScreen,
                top: topScreen,
                canopyRadius: screenCanopyR,
                biome: biome,
                fogT: fogT,
                variant: idx % 3,
              );
            },
          ),
        );
      }
    }

    // 3f. Kolarze MTB XCO na trasie
    final List<MtbXcoRider3D> riders = generateRiders(
      leaderDistanceMeters: leaderDistanceMeters,
      simulationTimeSeconds: simulationTimeSeconds,
      config: config,
      visibleJumps: jumps,
      visibleBoulders: boulders,
    );

    int activeRiders = 0;
    for (final MtbXcoRider3D rider in riders) {
      final MtbTrailSegmentSample3D seg = sampleTrailAt(rider.distanceMeters);
      final Vector3 worldPos = Vector3(
        seg.centerX + rider.lateralOffsetMeters,
        seg.elevationY + rider.airborneHeightMeters,
        rider.distanceMeters,
      );
      final Offset? baseScreen = projectPoint(worldPos);
      final Offset? headScreen = projectPoint(
        Vector3(worldPos.x, worldPos.y + 1.55, worldPos.z),
      );
      if (baseScreen == null || headScreen == null) continue;

      activeRiders++;
      final double depth = depthOf(worldPos);
      final double heightPx = (baseScreen.dy - headScreen.dy).abs().clamp(8.0, 220.0);

      drawQueue.add(
        _ProjectedItem(
          depth: depth - 0.5,
          draw: (Canvas c) {
            _drawMtbRider(
              canvas: c,
              groundPoint: baseScreen,
              heightPx: heightPx,
              rider: rider,
              simulationTimeSeconds: simulationTimeSeconds,
            );
          },
        ),
      );
    }

    // Sortowanie od najdalszych do najbliższych
    drawQueue.sort((a, b) => b.depth.compareTo(a.depth));
    for (final _ProjectedItem item in drawQueue) {
      item.draw(canvas);
    }

    // 4. Promienie słońca przebijające przez korony drzew + rozświetlony kurz
    int activeSunbeams = 0;
    int activeDustMotes = 0;
    if (config.showSunbeamsAndDust && config.sunbeamIntensity > 0.02) {
      final List<MtbSunbeamShaft3D> sunbeams = _generateSunbeams(
        minDistanceMeters: minVisDist,
        maxDistanceMeters: maxVisDist,
        config: config,
      );
      activeSunbeams = sunbeams.length;
      _drawVolumetricSunbeams(
        canvas: canvas,
        size: size,
        sunbeams: sunbeams,
        projectPoint: projectPoint,
        sampleTrailAt: sampleTrailAt,
        biome: biome,
        config: config,
        simulationTimeSeconds: simulationTimeSeconds,
      );

      final List<MtbDustMoteParticle3D> dustMotes = _generateDustMotes(
        riders: riders,
        sunbeams: sunbeams,
        sampleTrailAt: sampleTrailAt,
        simulationTimeSeconds: simulationTimeSeconds,
        config: config,
      );
      activeDustMotes = dustMotes.length;
      _drawDustMotes(
        canvas: canvas,
        dustMotes: dustMotes,
        projectPoint: projectPoint,
        depthOf: depthOf,
        maxDrawDistance: config.maxDrawDistanceMeters,
        biome: biome,
      );
    }

    final MtbXcoRider3D leader = riders.first;
    final MtbTrailSegmentSample3D leaderSeg =
        sampleTrailAt(leader.distanceMeters);

    return MtbForestRockGardenTelemetry(
      visibleTrailSlices: visibleTrailSlices,
      visibleBoulders: visibleBoulders,
      visibleBridges: bridges.length,
      visibleJumps: jumps.length,
      visibleTrees: visibleTrees,
      activeSunbeams: activeSunbeams,
      activeDustMotes: activeDustMotes,
      activeRiders: activeRiders,
      currentFeature: leaderSeg.featureType,
      leaderSpeedKmh: leader.speedKmh,
      leaderAirborneMeters: leader.airborneHeightMeters,
      suspensionTravelPercent: (leader.suspensionCompression * 100.0),
      sunbeamDustScatterIndex:
          (config.sunbeamIntensity * config.dustDensity * 100.0),
    );
  }

  double _resolveCameraDistance({
    required double leaderDistanceMeters,
    required MtbCameraViewMode mode,
  }) {
    switch (mode) {
      case MtbCameraViewMode.chaseSingletrack:
        return leaderDistanceMeters - 13.5;
      case MtbCameraViewMode.rockGardenTrackside:
        return leaderDistanceMeters - 9.0;
      case MtbCameraViewMode.jumpKickerLowAngle:
        return leaderDistanceMeters - 7.5;
      case MtbCameraViewMode.canopySunbeamOverview:
        return leaderDistanceMeters - 21.0;
    }
  }

  void _drawForestBackdrop({
    required Canvas canvas,
    required Size size,
    required double horizonY,
    required MtbForestBiomePreset biome,
    required MtbForestRockGarden3dConfig config,
  }) {
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 8);
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          biome.canopyTopColor,
          biome.canopyMidColor,
        ],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Złota poświata słońca ponad koronami drzew
    if (config.showSunbeamsAndDust) {
      final Offset sunCenter = Offset(size.width * 0.24, horizonY * 0.35);
      final Rect glowRect = Rect.fromCircle(
        center: sunCenter,
        radius: size.width * 0.42,
      );
      canvas.drawCircle(
        sunCenter,
        size.width * 0.42,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              biome.sunbeamColor.withValues(
                alpha: 0.36 * config.sunbeamIntensity,
              ),
              biome.sunbeamColor.withValues(alpha: 0.0),
            ],
          ).createShader(glowRect),
      );
    }

    // Dno lasu poniżej horyzontu
    final Rect floorRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      size.height - horizonY,
    );
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            biome.canopyMidColor,
            biome.forestFloorColor,
          ],
        ).createShader(floorRect),
    );
  }

  void _drawFacetedBoulder({
    required Canvas canvas,
    required Offset center,
    required double rx,
    required double ry,
    required int seed,
    required MtbForestBiomePreset biome,
    required double fogT,
    required bool hasTape,
  }) {
    // Cień kontaktowy pod głazem
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + rx * 0.08, center.dy + ry * 0.14),
        width: rx * 2.15,
        height: ry * 0.55,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.38 * (1.0 - fogT)),
    );

    final double skew = ((seed % 5) - 2) * 0.09 * rx;
    final Path mainBody = Path()
      ..moveTo(center.dx - rx, center.dy)
      ..lineTo(center.dx - rx * 0.62 + skew, center.dy - ry * 0.85)
      ..lineTo(center.dx + rx * 0.18 + skew, center.dy - ry)
      ..lineTo(center.dx + rx * 0.85, center.dy - ry * 0.55)
      ..lineTo(center.dx + rx, center.dy)
      ..close();

    final Color baseCol = Color.lerp(
      biome.boulderBaseColor,
      biome.canopyMidColor,
      fogT * 0.6,
    )!;
    canvas.drawPath(mainBody, Paint()..color = baseCol);

    // Rozświetlona górna ściana głazu od słońca
    final Path litFacet = Path()
      ..moveTo(center.dx - rx * 0.62 + skew, center.dy - ry * 0.85)
      ..lineTo(center.dx + rx * 0.18 + skew, center.dy - ry)
      ..lineTo(center.dx + rx * 0.35, center.dy - ry * 0.35)
      ..lineTo(center.dx - rx * 0.42, center.dy - ry * 0.25)
      ..close();
    canvas.drawPath(
      litFacet,
      Paint()
        ..color = Color.lerp(
          biome.boulderHighlightColor,
          biome.canopyMidColor,
          fogT * 0.65,
        )!,
    );

    // Opcjonalna taśma trasy XCO przy skrajnych głazach
    if (hasTape && rx > 6.0) {
      canvas.drawLine(
        Offset(center.dx, center.dy - ry * 0.5),
        Offset(center.dx, center.dy - ry * 2.1),
        Paint()
          ..color = AppColors.textSecondary.withValues(alpha: 1.0 - fogT)
          ..strokeWidth = 1.6,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          center.dx,
          center.dy - ry * 2.1,
          rx * 0.85,
          (ry * 0.28).clamp(2.0, 6.0),
        ),
        Paint()..color = AppColors.crimsonAlert.withValues(alpha: 1.0 - fogT),
      );
    }
  }

  void _drawForestTree({
    required Canvas canvas,
    required Offset base,
    required Offset top,
    required double canopyRadius,
    required MtbForestBiomePreset biome,
    required double fogT,
    required int variant,
  }) {
    final double trunkWidth = (canopyRadius * 0.18).clamp(2.2, 16.0);
    final Color trunkColor = Color.lerp(
      variant == 2 ? const Color(0xFFB8B3A8) : const Color(0xFF3E2D20),
      biome.canopyMidColor,
      fogT * 0.65,
    )!;

    canvas.drawLine(
      base,
      top,
      Paint()
        ..color = trunkColor
        ..strokeWidth = trunkWidth
        ..strokeCap = StrokeCap.round,
    );

    // Warstwowe korony drzew (3 stożki/kaskady liści)
    final Color canopyDark = Color.lerp(
      biome.canopyTopColor,
      biome.canopyMidColor,
      fogT * 0.5,
    )!;
    final Color canopyLit = Color.lerp(
      const Color(0xFF2E5438),
      biome.canopyMidColor,
      fogT * 0.6,
    )!;

    for (int layer = 0; layer < 3; layer++) {
      final double yFrac = 0.25 + layer * 0.26;
      final Offset layerCenter = Offset.lerp(top, base, yFrac * 0.45)!;
      final double r = canopyRadius * (0.72 + layer * 0.2);

      final Path crown = Path()
        ..moveTo(layerCenter.dx, layerCenter.dy - r * 1.1)
        ..lineTo(layerCenter.dx + r, layerCenter.dy + r * 0.45)
        ..lineTo(layerCenter.dx - r, layerCenter.dy + r * 0.45)
        ..close();

      canvas.drawPath(
        crown,
        Paint()..color = layer == 0 ? canopyLit : canopyDark,
      );
    }
  }

  void _drawMtbRider({
    required Canvas canvas,
    required Offset groundPoint,
    required double heightPx,
    required MtbXcoRider3D rider,
    required double simulationTimeSeconds,
  }) {
    final double scale = heightPx / 62.0;
    final double wheelR = 11.0 * scale;
    final double wheelbase = 30.0 * scale;
    final double compOffset = rider.suspensionCompression * 4.5 * scale;

    // Cień na ścieżce pod rowerem (maleje gdy kolarz jest w powietrzu)
    final double shadowAlpha =
        (0.45 - rider.airborneHeightMeters * 0.18).clamp(0.12, 0.45);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          groundPoint.dx,
          groundPoint.dy + rider.airborneHeightMeters * 10.0 * scale,
        ),
        width: wheelbase * 1.15,
        height: 6.0 * scale,
      ),
      Paint()..color = Colors.black.withValues(alpha: shadowAlpha),
    );

    canvas.save();
    canvas.translate(groundPoint.dx, groundPoint.dy - wheelR);
    canvas.rotate(rider.pitchAngleRad * 0.55);

    // Opony 2.4" MTB (przednia i tylna)
    final Paint tirePaint = Paint()
      ..color = const Color(0xFF1A1D24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (3.4 * scale).clamp(1.2, 5.0);
    final Offset rearWheel = Offset(-wheelbase * 0.45, 0);
    final Offset frontWheel = Offset(wheelbase * 0.45, 0);
    canvas.drawCircle(rearWheel, wheelR, tirePaint);
    canvas.drawCircle(frontWheel, wheelR, tirePaint);

    // Rama Full-Suspension (tylny wahacz + przedni amortyzator 110mm)
    final Offset bb = Offset(-3.0 * scale, -2.0 * scale + compOffset * 0.4);
    final Offset seatTubeTop = Offset(
      -10.0 * scale,
      -(rider.dropperDown ? 15.0 : 21.0) * scale + compOffset,
    );
    final Offset headTubeTop = Offset(
      11.0 * scale,
      -21.0 * scale + compOffset * 0.8,
    );

    final Paint framePaint = Paint()
      ..color = rider.accentColor
      ..strokeWidth = (2.8 * scale).clamp(1.0, 4.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(rearWheel, bb, framePaint);
    canvas.drawLine(bb, seatTubeTop, framePaint);
    canvas.drawLine(seatTubeTop, headTubeTop, framePaint);
    canvas.drawLine(headTubeTop, frontWheel, framePaint);

    // Sylwetka kolarza (tułów w pozycji atakującej na zjeździe / skoku)
    final double crankAngle =
        simulationTimeSeconds * (rider.cadenceRpm / 60.0) * math.pi * 2.0;
    final Offset hip = Offset(
      seatTubeTop.dx + (rider.dropperDown ? -2.0 : 1.0) * scale,
      seatTubeTop.dy - 5.0 * scale,
    );
    final Offset shoulder = Offset(
      headTubeTop.dx - 2.0 * scale,
      headTubeTop.dy - 14.0 * scale,
    );
    final Offset knee = Offset(
      bb.dx + math.cos(crankAngle) * 7.0 * scale,
      bb.dy - 6.0 * scale + math.sin(crankAngle) * 3.0 * scale,
    );

    // Noga
    canvas.drawLine(
      hip,
      knee,
      Paint()
        ..color = const Color(0xFF252A34)
        ..strokeWidth = (3.4 * scale).clamp(1.2, 4.5)
        ..strokeCap = StrokeCap.round,
    );

    // Koszulka MTB
    canvas.drawLine(
      hip,
      shoulder,
      Paint()
        ..color = rider.jerseyColor
        ..strokeWidth = (6.2 * scale).clamp(2.2, 9.0)
        ..strokeCap = StrokeCap.round,
    );

    // Ręce na szerokiej kierownicy 760 mm
    canvas.drawLine(
      shoulder,
      Offset(headTubeTop.dx + 1.0 * scale, headTubeTop.dy - 2.0 * scale),
      Paint()
        ..color = rider.jerseyColor
        ..strokeWidth = (2.8 * scale).clamp(1.0, 4.0)
        ..strokeCap = StrokeCap.round,
    );

    // Kask z daszkiem MTB
    canvas.drawCircle(
      Offset(shoulder.dx + 3.0 * scale, shoulder.dy - 6.5 * scale),
      4.8 * scale,
      Paint()
        ..color = rider.isLeader ? AppColors.goldAccent : AppColors.textPrimary,
    );

    canvas.restore();
  }

  List<MtbSunbeamShaft3D> _generateSunbeams({
    required double minDistanceMeters,
    required double maxDistanceMeters,
    required MtbForestRockGarden3dConfig config,
  }) {
    final List<MtbSunbeamShaft3D> shafts = <MtbSunbeamShaft3D>[];
    const double step = 18.0;
    final double first = (minDistanceMeters / step).floor() * step;
    for (double d = first; d < maxDistanceMeters; d += step) {
      final int idx = (d / step).round();
      if (idx % 2 != 0 && config.canopyDensity > 0.88) continue;
      shafts.add(
        MtbSunbeamShaft3D(
          distanceMeters: d,
          lateralOriginMeters: -5.5 + (idx % 3) * 1.8,
          widthMeters: 2.2 + (idx % 4) * 0.75,
          tiltAngleRad: 0.42,
          intensity:
              (0.55 + (idx % 3) * 0.15) * config.sunbeamIntensity,
        ),
      );
    }
    return shafts;
  }

  void _drawVolumetricSunbeams({
    required Canvas canvas,
    required Size size,
    required List<MtbSunbeamShaft3D> sunbeams,
    required Offset? Function(Vector3 world) projectPoint,
    required MtbTrailSegmentSample3D Function(double d) sampleTrailAt,
    required MtbForestBiomePreset biome,
    required MtbForestRockGarden3dConfig config,
    required double simulationTimeSeconds,
  }) {
    for (int i = 0; i < sunbeams.length; i++) {
      final MtbSunbeamShaft3D shaft = sunbeams[i];
      final MtbTrailSegmentSample3D seg = sampleTrailAt(shaft.distanceMeters);

      final Offset? topLeft = projectPoint(
        Vector3(
          seg.centerX + shaft.lateralOriginMeters,
          seg.elevationY + 12.5,
          shaft.distanceMeters,
        ),
      );
      final Offset? botLeft = projectPoint(
        Vector3(
          seg.centerX + shaft.lateralOriginMeters + 4.8,
          seg.elevationY - 0.3,
          shaft.distanceMeters,
        ),
      );
      final Offset? botRight = projectPoint(
        Vector3(
          seg.centerX +
              shaft.lateralOriginMeters +
              4.8 +
              shaft.widthMeters,
          seg.elevationY - 0.3,
          shaft.distanceMeters,
        ),
      );
      final Offset? topRight = projectPoint(
        Vector3(
          seg.centerX + shaft.lateralOriginMeters + shaft.widthMeters * 0.7,
          seg.elevationY + 12.5,
          shaft.distanceMeters,
        ),
      );

      if (topLeft == null ||
          botLeft == null ||
          botRight == null ||
          topRight == null) {
        continue;
      }

      final double shimmer =
          0.85 + 0.15 * math.sin(simulationTimeSeconds * 1.4 + i * 1.7);
      final double alpha = (0.24 * shaft.intensity * shimmer).clamp(0.0, 0.42);

      final Path rayPath = Path()
        ..moveTo(topLeft.dx, topLeft.dy)
        ..lineTo(topRight.dx, topRight.dy)
        ..lineTo(botRight.dx, botRight.dy)
        ..lineTo(botLeft.dx, botLeft.dy)
        ..close();

      final Rect bounds = rayPath.getBounds();
      if (bounds.isEmpty) continue;

      canvas.drawPath(
        rayPath,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              biome.sunbeamColor.withValues(alpha: alpha),
              biome.sunbeamColor.withValues(alpha: alpha * 0.45),
              biome.sunbeamColor.withValues(alpha: 0.0),
            ],
          ).createShader(bounds),
      );
    }
  }

  List<MtbDustMoteParticle3D> _generateDustMotes({
    required List<MtbXcoRider3D> riders,
    required List<MtbSunbeamShaft3D> sunbeams,
    required MtbTrailSegmentSample3D Function(double d) sampleTrailAt,
    required double simulationTimeSeconds,
    required MtbForestRockGarden3dConfig config,
  }) {
    final List<MtbDustMoteParticle3D> motes = <MtbDustMoteParticle3D>[];
    final int perRiderCount = (18 * config.dustDensity).round().clamp(0, 26);

    for (final MtbXcoRider3D rider in riders) {
      for (int p = 0; p < perRiderCount; p++) {
        final double age = ((p / (perRiderCount + 1)) +
                (simulationTimeSeconds * 0.65) % 1.0) %
            1.0;
        final double d = rider.distanceMeters - age * 7.5;
        final MtbTrailSegmentSample3D seg = sampleTrailAt(d);
        final double x = seg.centerX +
            rider.lateralOffsetMeters +
            math.sin(p * 3.1 + simulationTimeSeconds * 2.0) * (0.25 + age * 0.9);
        final double y = seg.elevationY +
            0.18 +
            age * 1.45 +
            math.cos(p * 2.3 + simulationTimeSeconds) * 0.14;

        // Sprawdź czy drobinka kurzu znajduje się w stożku promienia słońca
        double sunlitBoost = 0.0;
        for (final MtbSunbeamShaft3D shaft in sunbeams) {
          if ((shaft.distanceMeters - d).abs() < 4.5) {
            sunlitBoost = shaft.intensity;
            break;
          }
        }

        motes.add(
          MtbDustMoteParticle3D(
            position: Vector3(x, y, d),
            radiusMeters: 0.08 + age * 0.24,
            alpha: (1.0 - age) * (0.35 + sunlitBoost * 0.48) * config.dustDensity,
            sunlitGlowFactor: sunlitBoost,
          ),
        );
      }
    }
    return motes;
  }

  void _drawDustMotes({
    required Canvas canvas,
    required List<MtbDustMoteParticle3D> dustMotes,
    required Offset? Function(Vector3 world) projectPoint,
    required double Function(Vector3 world) depthOf,
    required double maxDrawDistance,
    required MtbForestBiomePreset biome,
  }) {
    for (final MtbDustMoteParticle3D mote in dustMotes) {
      final Offset? screen = projectPoint(mote.position);
      if (screen == null) continue;
      final double depth = depthOf(mote.position);
      final double distScale =
          (1.0 - depth / maxDrawDistance).clamp(0.15, 1.0);
      final double r = (mote.radiusMeters * 38.0 * distScale).clamp(1.2, 22.0);
      final Color col = Color.lerp(
        biome.dustColor,
        biome.sunbeamColor,
        mote.sunlitGlowFactor * 0.8,
      )!;
      canvas.drawCircle(
        screen,
        r,
        Paint()
          ..color = col.withValues(alpha: (mote.alpha * distScale).clamp(0.0, 0.75)),
      );
    }
  }
}

// =============================================================================
// 5. CUSTOM PAINTER SCENY 3D MTB XCO
// =============================================================================

/// [CustomPainter] renderujący leśną trasę MTB XCO 3D w każdej klatce animacji.
class MtbForestRockGarden3dPainter extends CustomPainter {
  final MtbForestRockGarden3dRenderer renderer;
  final double leaderDistanceMeters;
  final double simulationTimeSeconds;
  final MtbForestRockGarden3dConfig config;
  final ValueChanged<MtbForestRockGardenTelemetry>? onTelemetry;

  const MtbForestRockGarden3dPainter({
    required this.renderer,
    required this.leaderDistanceMeters,
    required this.simulationTimeSeconds,
    required this.config,
    this.onTelemetry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final MtbForestRockGardenTelemetry telemetry = renderer.renderFrame(
      canvas: canvas,
      size: size,
      leaderDistanceMeters: leaderDistanceMeters,
      simulationTimeSeconds: simulationTimeSeconds,
      config: config,
    );
    onTelemetry?.call(telemetry);
  }

  @override
  bool shouldRepaint(covariant MtbForestRockGarden3dPainter oldDelegate) {
    return oldDelegate.leaderDistanceMeters != leaderDistanceMeters ||
        oldDelegate.simulationTimeSeconds != simulationTimeSeconds ||
        oldDelegate.config != config;
  }
}

// =============================================================================
// 6. INTERAKTYWNY WIDGET VIEWPORTU 3D (RESPONSIVE 390x844 / 1024x768 / 1600x900)
// =============================================================================

/// Produkcyjny widget sceny 3D leśnej trasy MTB XCO z panelem sterowania.
class MtbForestRockGarden3dViewportWidget extends StatefulWidget {
  final MtbForestRockGarden3dConfig initialConfig;

  const MtbForestRockGarden3dViewportWidget({
    super.key,
    this.initialConfig = const MtbForestRockGarden3dConfig(),
  });

  @override
  State<MtbForestRockGarden3dViewportWidget> createState() =>
      _MtbForestRockGarden3dViewportWidgetState();
}

class _MtbForestRockGarden3dViewportWidgetState
    extends State<MtbForestRockGarden3dViewportWidget>
    with SingleTickerProviderStateMixin {
  final MtbForestRockGarden3dRenderer _renderer =
      const MtbForestRockGarden3dRenderer();

  late AnimationController _ticker;
  late MtbForestRockGarden3dConfig _config;
  double _simulationTimeSeconds = 0.0;
  double _leaderDistanceMeters = 12.0;
  bool _isPaused = false;
  DateTime _lastTick = DateTime.now();
  MtbForestRockGardenTelemetry _lastTelemetry =
      MtbForestRockGardenTelemetry.empty();

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    _ticker.repeat();
  }

  void _onTick() {
    final DateTime now = DateTime.now();
    final double dt =
        (now.difference(_lastTick).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastTick = now;

    if (!_isPaused && mounted) {
      setState(() {
        _simulationTimeSeconds += dt;
        _leaderDistanceMeters += (_config.riderSpeedKmh / 3.6) * dt;
      });
    }
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  void _selectBiome(MtbForestBiomePreset preset) {
    setState(() {
      _config = _config.copyWith(
        biomePreset: preset,
        sunbeamIntensity: preset.defaultSunbeamIntensity,
        dustDensity: preset.defaultDustDensity,
        canopyDensity: preset.defaultCanopyDensity,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 720;
        final bool isWideDesktop = constraints.maxWidth >= 1200;

        final Widget canvasCard = ClipRRect(
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
                  painter: MtbForestRockGarden3dPainter(
                    renderer: _renderer,
                    leaderDistanceMeters: _leaderDistanceMeters,
                    simulationTimeSeconds: _simulationTimeSeconds,
                    config: _config,
                    onTelemetry: (t) => _lastTelemetry = t,
                  ),
                ),
                if (_config.showTelemetryOverlay)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: isCompact ? 12 : null,
                    child: _MtbTelemetryHudBadge(
                      preset: _config.biomePreset,
                      telemetry: _lastTelemetry,
                      lineChoice: _config.selectedLineChoice,
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
            child: _buildControlPanel(isCompact: isCompact),
          ),
        );

        if (isCompact) {
          return Column(
            children: [
              Expanded(flex: 5, child: canvasCard),
              const SizedBox(height: 10),
              Expanded(flex: 4, child: controlPanel),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: isWideDesktop ? 7 : 6, child: canvasCard),
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

  Widget _buildControlPanel({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'MTB XCO Las & Rock Garden 3D',
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
            _MtbActionButton(
              label: _isPaused ? 'Wznów' : 'Pauza',
              icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              isActive: !_isPaused,
              onPressed: () => setState(() => _isPaused = !_isPaused),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Biom Leśny XCO',
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
          children: MtbForestBiomePreset.values.map((preset) {
            return _MtbActionButton(
              label: preset.shortTag,
              isActive: _config.biomePreset == preset,
              onPressed: () => _selectBiome(preset),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kamera & Linia Przejazdu',
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
          children: MtbCameraViewMode.values.map((mode) {
            return _MtbActionButton(
              label: mode.shortTag,
              isActive: _config.cameraMode == mode,
              onPressed: () => setState(
                () => _config = _config.copyWith(cameraMode: mode),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MtbActionButton(
              label: 'A-Line (Techniczna)',
              isActive: _config.selectedLineChoice ==
                  MtbTrailLineChoice.aLine,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  selectedLineChoice: MtbTrailLineChoice.aLine,
                ),
              ),
            ),
            _MtbActionButton(
              label: 'B-Line (Objazd)',
              isActive: _config.selectedLineChoice ==
                  MtbTrailLineChoice.bLine,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  selectedLineChoice: MtbTrailLineChoice.bLine,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSliderLabel(
          'Promienie Słońca w Koronach: ${(_config.sunbeamIntensity * 100).round()}%',
        ),
        Slider(
          value: _config.sunbeamIntensity,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.goldAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: (v) => setState(
            () => _config = _config.copyWith(sunbeamIntensity: v),
          ),
        ),
        _buildSliderLabel(
          'Gęstość Kurzu i Pyłu: ${(_config.dustDensity * 100).round()}%',
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
        _buildSliderLabel(
          'Prędkość Czołówki: ${_config.riderSpeedKmh.toStringAsFixed(1)} km/h',
        ),
        Slider(
          value: _config.riderSpeedKmh,
          min: 14.0,
          max: 44.0,
          activeColor: AppColors.primaryAccent,
          inactiveColor: AppColors.surfaceLight,
          onChanged: (v) => setState(
            () => _config = _config.copyWith(riderSpeedKmh: v),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MtbActionButton(
              label: 'Promienie & Kurz',
              isActive: _config.showSunbeamsAndDust,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  showSunbeamsAndDust: !_config.showSunbeamsAndDust,
                ),
              ),
            ),
            _MtbActionButton(
              label: 'Rock Garden',
              isActive: _config.showRockGardens,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  showRockGardens: !_config.showRockGardens,
                ),
              ),
            ),
            _MtbActionButton(
              label: 'Mostki & Skocznie',
              isActive: _config.showWoodenBridgesAndJumps,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  showWoodenBridgesAndJumps: !_config.showWoodenBridgesAndJumps,
                ),
              ),
            ),
            _MtbActionButton(
              label: 'Telemetria HUD',
              isActive: _config.showTelemetryOverlay,
              onPressed: () => setState(
                () => _config = _config.copyWith(
                  showTelemetryOverlay: !_config.showTelemetryOverlay,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliderLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: AppColors.textSecondary,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _MtbTelemetryHudBadge extends StatelessWidget {
  final MtbForestBiomePreset preset;
  final MtbForestRockGardenTelemetry telemetry;
  final MtbTrailLineChoice lineChoice;

  const _MtbTelemetryHudBadge({
    required this.preset,
    required this.telemetry,
    required this.lineChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
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
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${telemetry.currentFeature.displayNamePl} • ${lineChoice == MtbTrailLineChoice.aLine ? 'A-Line' : 'B-Line'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 2,
            children: [
              _HudMetricText(
                label: 'Prędkość',
                value: '${telemetry.leaderSpeedKmh.toStringAsFixed(1)} km/h',
              ),
              _HudMetricText(
                label: 'Skok',
                value: '${telemetry.suspensionTravelPercent.round()}%',
              ),
              _HudMetricText(
                label: 'Głazy',
                value: '${telemetry.visibleBoulders}',
              ),
              _HudMetricText(
                label: 'Promienie',
                value: '${telemetry.activeSunbeams}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudMetricText extends StatelessWidget {
  final String label;
  final String value;

  const _HudMetricText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        color: AppColors.textSecondary,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Przycisk kontrolny z pełnymi stanami hover / active / disabled / focus.
class _MtbActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _MtbActionButton({
    required this.label,
    this.icon,
    this.isActive = false,
    this.onPressed,
  });

  @override
  State<_MtbActionButton> createState() => _MtbActionButtonState();
}

class _MtbActionButtonState extends State<_MtbActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;

    final Color bgColor;
    if (!enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.45);
    } else if (_isPressed) {
      bgColor = AppColors.primaryAccent;
    } else if (widget.isActive) {
      bgColor = AppColors.primaryAccent.withValues(alpha: _isHovered ? 0.92 : 0.78);
    } else if (_isHovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background;
    }

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (_isFocused
            ? AppColors.goldAccent
            : (widget.isActive ? AppColors.primaryAccent : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
