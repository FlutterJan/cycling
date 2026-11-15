// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/engine/rendering3d/wind_streamlines_visualizer.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Scene3DMathProjection projection;
  late CameraRigController cameraController;
  late PelotonInstancedRenderer pelotonRenderer;
  late StageSegment sampleSegment;
  late RaceStage sampleStage;

  setUp(() {
    projection = Scene3DMathProjection(
      viewportWidth: 1280.0,
      viewportHeight: 720.0,
      fovYDegrees: 60.0,
      zNear: 0.5,
      zFar: 500.0,
    );

    // Kamera z tyłu (Z = 4985, cel Z = 5050)
    projection.setView(
      eye: Vector3(0.0, 2.5, 4985.0),
      target: Vector3(0.0, 1.5, 5050.0),
      up: Vector3(0.0, 1.0, 0.0),
    );

    cameraController = CameraRigController();
    pelotonRenderer = PelotonInstancedRenderer();

    sampleSegment = const StageSegment(
      index: 0,
      startKm: 0.0,
      lengthKm: 10.0,
      startElevationM: 400.0,
      endElevationM: 450.0,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      technicalDifficulty: 20.0,
      windDirectionDegrees: 270.0, // Wiatr wiejący z zachodu (z lewej przy bearing 0)
      roadBearingDegrees: 0.0,     // Szosa prosto na północ (0°)
      sprintOrKomClassification: SegmentClassification.none,
    );

    sampleStage = const RaceStage(
      id: 'stage_test',
      stageNumber: 1,
      name: 'Etap Rantów',
      stageType: StageType.flat,
      segments: [],
      baseTemperatureCelsius: 20.0,
      weatherCondition: WeatherCondition.crosswindGale,
      windSpeedKmh: 28.0,
    );
  });

  RiderPositionSnapshot createSnapshot({
    required String riderId,
    required String name,
    required int bib,
    double distanceMeters = 5010.0,
    double lateralOffset = 0.0,
    double draftingSavings = 35.0,
    bool isPulling = false,
  }) {
    return RiderPositionSnapshot(
      riderId: riderId,
      riderName: name,
      bibNumber: bib,
      teamId: 'team_uae',
      teamName: 'UAE',
      teamJerseyHexColor: '#FFFFFF',
      isPlayerRider: false,
      distanceCoveredMeters: distanceMeters,
      kilometerMark: distanceMeters / 1000.0,
      elevationMeters: 0.0,
      currentGradientPercent: 0.0,
      currentSegmentIndex: 0,
      speedMs: 12.5,
      speedKmh: 45.0,
      powerWatts: 350,
      wattsPerKg: 5.2,
      cadenceRpm: 92,
      heartRateBpm: 155,
      wPrimePercentage: 0.85,
      wPrimeJoules: 18000.0,
      glycogenPercentage: 0.8,
      glycogenGrams: 380.0,
      hydrationPercent: 0.9,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: TacticalOrder.holdPosition,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: 0.0,
      lateralPositionRoad: (lateralOffset / 3.6).clamp(-1.0, 1.0),
      lateralOffsetRoadMeters: lateralOffset,
      isDrafting: draftingSavings > 0.0,
      draftingSavingsPercent: draftingSavings,
      isPulling: isPulling,
      hasDefect: false,
      isCrashed: false,
      isDnf: false,
    );
  }

  group('Wind Streamlines Visualizer - Enums & Models', () {
    test('EchelonSide lateral signs and descriptions', () {
      expect(EchelonSide.left.lateralSign, equals(-1.0));
      expect(EchelonSide.right.lateralSign, equals(1.0));
      expect(EchelonSide.center.lateralSign, equals(0.0));
    });

    test('RiderAeroPocket drafting shelter and exposure getters', () {
      const sheltered = RiderAeroPocket(
        riderId: 'r1',
        riderName: 'Sheltered Rider',
        bibNumber: 1,
        teamJerseyHex: '#FFF',
        isPlayerRider: true,
        isPulling: false,
        draftingSavingsPercent: 38.0,
        distanceMeters: 5010.0,
        lateralOffsetMeters: 0.5,
        speedKmh: 45.0,
        screenPosition: Offset(640, 360),
        perspectiveScale: 1.0,
        isInFrontOfCamera: true,
        depth: 10.0,
      );
      expect(sheltered.hasEffectiveDrafting, isTrue);
      expect(sheltered.isExposedToWind, isFalse);

      const exposed = RiderAeroPocket(
        riderId: 'r2',
        riderName: 'Pulling Rider',
        bibNumber: 2,
        teamJerseyHex: '#FFF',
        isPlayerRider: false,
        isPulling: true,
        draftingSavingsPercent: 0.0,
        distanceMeters: 5012.0,
        lateralOffsetMeters: -0.2,
        speedKmh: 45.0,
        screenPosition: Offset(640, 350),
        perspectiveScale: 1.0,
        isInFrontOfCamera: true,
        depth: 12.0,
      );
      expect(exposed.hasEffectiveDrafting, isFalse);
      expect(exposed.isExposedToWind, isTrue);
    });

    test('WindStreamlinesConfig copyWith', () {
      const initial = WindStreamlinesConfig(aeroVisionActive: false);
      final updated = initial.copyWith(
        aeroVisionActive: true,
        streamlineLengthMeters: 15.0,
        pocketGreenOpacity: 0.5,
      );
      expect(updated.aeroVisionActive, isTrue);
      expect(updated.streamlineLengthMeters, equals(15.0));
      expect(updated.pocketGreenOpacity, equals(0.5));
      expect(updated.enabled, isTrue);
    });
  });

  group('Apparent Wind and Echelon Physics (calculateApparentWind)', () {
    test('Crosswind from the left creates Echelon Right (ranty w prawo)', () {
      final visualizer = WindStreamlinesVisualizer();

      // Droga na północ (0°), wiatr z zachodu (270°) z prędkością 28 km/h
      const crosswindLeftSegment = StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 10.0,
        startElevationM: 400.0,
        endElevationM: 400.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 270.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final aero = visualizer.calculateApparentWind(
        segment: crosswindLeftSegment,
        windSpeedKmh: 28.0,
        riderSpeedKmh: 45.0,
      );

      expect(aero.echelonSide, equals(EchelonSide.right));
      expect(aero.crosswindSpeedKmh, closeTo(28.0, 1e-3));
      expect(aero.echelonDeflectionRatio, greaterThan(0.0));
      expect(aero.echelonRecommendation, contains('Ranty w prawo'));
    });

    test('Crosswind from the right creates Echelon Left (ranty w lewo)', () {
      final visualizer = WindStreamlinesVisualizer();

      // Droga na północ (0°), wiatr ze wschodu (90°) z prędkością 25 km/h
      const crosswindRightSegment = StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 10.0,
        startElevationM: 400.0,
        endElevationM: 400.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final aero = visualizer.calculateApparentWind(
        segment: crosswindRightSegment,
        windSpeedKmh: 25.0,
        riderSpeedKmh: 45.0,
      );

      expect(aero.echelonSide, equals(EchelonSide.left));
      expect(aero.crosswindSpeedKmh, closeTo(25.0, 1e-3));
      expect(aero.echelonDeflectionRatio, lessThan(0.0));
      expect(aero.echelonRecommendation, contains('Ranty w lewo'));
    });

    test('Headwind creates Center Echelon (wężyk osiowy)', () {
      final visualizer = WindStreamlinesVisualizer();

      // Droga na północ (0°), wiatr prosto z przodu (0°)
      const headwindSegment = StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 10.0,
        startElevationM: 400.0,
        endElevationM: 400.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      );

      final aero = visualizer.calculateApparentWind(
        segment: headwindSegment,
        windSpeedKmh: 20.0,
        riderSpeedKmh: 40.0,
      );

      expect(aero.echelonSide, equals(EchelonSide.center));
      expect(aero.crosswindSpeedKmh, closeTo(0.0, 1e-3));
      expect(aero.echelonDeflectionRatio, closeTo(0.0, 1e-3));
      expect(aero.headwindSpeedKmh, greaterThan(0.0));
    });
  });

  group('WindStreamlinesVisualizer - Simulation Tick and Pockets', () {
    test('updatePhysics with activeRiders builds aero pockets and advances particles', () {
      final visualizer = WindStreamlinesVisualizer(
        config: const WindStreamlinesConfig(aeroVisionActive: true),
      );

      final r1 = createSnapshot(riderId: 'r1', name: 'Leader', bib: 1, distanceMeters: 5020.0, isPulling: true);
      final r2 = createSnapshot(riderId: 'r2', name: 'Follower', bib: 2, distanceMeters: 5015.0, draftingSavings: 35.0);

      final items = pelotonRenderer.prepareDrawList(
        riders: [r1, r2],
        cameraController: cameraController,
        projection: projection,
        segments: [sampleSegment],
      );

      visualizer.updatePhysics(
        activeRiders: items,
        activeStage: sampleStage,
        segments: [sampleSegment],
        dtSeconds: 0.016,
        elapsedAnimSeconds: 0.016,
      );

      expect(visualizer.activePocketsCount, equals(2));
      expect(visualizer.activeStreamlinesCount, greaterThan(0));
      expect(visualizer.lastAeroState.echelonSide, equals(EchelonSide.right));
    });

    test('updatePhysics with snapshots fallback builds aero pockets', () {
      final visualizer = WindStreamlinesVisualizer(
        config: const WindStreamlinesConfig(aeroVisionActive: true),
      );

      final s1 = createSnapshot(riderId: 's1', name: 'Snap 1', bib: 11);
      final s2 = createSnapshot(riderId: 's2', name: 'Snap 2', bib: 12);

      visualizer.updatePhysics(
        snapshots: [s1, s2],
        activeStage: sampleStage,
        segments: [sampleSegment],
        dtSeconds: 0.016,
        elapsedAnimSeconds: 0.016,
      );

      expect(visualizer.activePocketsCount, equals(2));
    });

    test('updatePhysics disabled stops updating', () {
      final visualizer = WindStreamlinesVisualizer(
        config: const WindStreamlinesConfig(enabled: false),
      );

      final s1 = createSnapshot(riderId: 's1', name: 'Snap 1', bib: 11);

      visualizer.updatePhysics(
        snapshots: [s1],
        activeStage: sampleStage,
        segments: [sampleSegment],
        dtSeconds: 0.016,
        elapsedAnimSeconds: 0.016,
      );

      expect(visualizer.activePocketsCount, equals(0));
    });
  });

  group('WindStreamlinesVisualizer - Canvas 3D Rendering', () {
    test('Does not draw when aeroVisionActive is false', () {
      final visualizer = WindStreamlinesVisualizer(
        config: const WindStreamlinesConfig(aeroVisionActive: false),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      visualizer.renderAeroVision(
        canvas: canvas,
        size: const Size(1280, 720),
        projection: projection,
        elapsedAnimSeconds: 1.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('Renders full Aero Vision layer (pockets, streamlines, compass) on Canvas 3D', () {
      final visualizer = WindStreamlinesVisualizer(
        config: const WindStreamlinesConfig(
          aeroVisionActive: true,
          enableDraftingPockets: true,
          enableCrosswindRedZones: true,
          enableStreamlineRibbons: true,
          enableEchelonTeamGuides: true,
          enableAeroCompassHud: true,
        ),
      );

      final r1 = createSnapshot(riderId: 'r1', name: 'Tadej', bib: 1, distanceMeters: 5015.0, lateralOffset: 0.0, isPulling: true);
      final r2 = createSnapshot(riderId: 'r2', name: 'Majka', bib: 2, distanceMeters: 5011.0, lateralOffset: 0.8, draftingSavings: 38.0);

      final items = pelotonRenderer.prepareDrawList(
        riders: [r1, r2],
        cameraController: cameraController,
        projection: projection,
        segments: [sampleSegment],
      );

      visualizer.updatePhysics(
        activeRiders: items,
        activeStage: sampleStage,
        segments: [sampleSegment],
        dtSeconds: 0.016,
        elapsedAnimSeconds: 1.5,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      visualizer.renderAeroVision(
        canvas: canvas,
        size: const Size(1280, 720),
        projection: projection,
        elapsedAnimSeconds: 1.5,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('Camera culling: ignores pockets behind camera without crash', () {
      final visualizer = WindStreamlinesVisualizer(
        config: const WindStreamlinesConfig(aeroVisionActive: true),
      );

      // Kolarz za plecami kamery (Z = 2000, kamera Z = 4985)
      final behindSnapshot = createSnapshot(
        riderId: 'behind',
        name: 'Behind',
        bib: 99,
        distanceMeters: 2000.0,
      );

      visualizer.updatePhysics(
        snapshots: [behindSnapshot],
        activeStage: sampleStage,
        segments: [sampleSegment],
        dtSeconds: 0.016,
        elapsedAnimSeconds: 1.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      visualizer.renderAeroVision(
        canvas: canvas,
        size: const Size(1280, 720),
        projection: projection,
        elapsedAnimSeconds: 1.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('WindStreamlinesVisualizer - Interactive Controls', () {
    test('setAeroVisionActive and toggleAeroVision methods', () {
      final visualizer = WindStreamlinesVisualizer(
        config: const WindStreamlinesConfig(aeroVisionActive: false),
      );
      expect(visualizer.isAeroVisionActive, isFalse);

      visualizer.setAeroVisionActive(true);
      expect(visualizer.isAeroVisionActive, isTrue);

      visualizer.toggleAeroVision();
      expect(visualizer.isAeroVisionActive, isFalse);

      visualizer.toggleAeroVision();
      expect(visualizer.isAeroVisionActive, isTrue);
    });
  });
}

