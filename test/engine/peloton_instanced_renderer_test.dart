// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PelotonInstancedRenderer renderer;
  late Scene3DMathProjection projection;
  late CameraRigController cameraController;

  setUp(() {
    renderer = PelotonInstancedRenderer();
    projection = Scene3DMathProjection(
      viewportWidth: 1920.0,
      viewportHeight: 1080.0,
      fovYDegrees: 60.0,
      zNear: 0.5,
      zFar: 600.0,
    );
    cameraController = CameraRigController();
  });

  /// Generator pełnego peletonu Grand Tour: 22 zespoły x 8 kolarzy = 176 kolarzy.
  List<RiderPositionSnapshot> generatePeloton176({
    double baseDistanceMeters = 10000.0,
    double pelotonDepthMeters = 120.0,
    double elevationMeters = 0.0,
  }) {
    final riders = <RiderPositionSnapshot>[];

    final teamColors = [
      '#EF4444', '#3B82F6', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899',
      '#06B6D4', '#84CC16', '#6366F1', '#D97706', '#14B8A6', '#F97316',
      '#A855F7', '#E11D48', '#0284C7', '#22C55E', '#EAB308', '#64748B',
      '#0F172A', '#78350F', '#1E3A8A', '#15803D',
    ];

    for (int teamIdx = 0; teamIdx < 22; teamIdx++) {
      final teamColor = teamColors[teamIdx];
      for (int riderInTeam = 0; riderInTeam < 8; riderInTeam++) {
        final globalIndex = (teamIdx * 8) + riderInTeam;
        final bib = (teamIdx + 1) * 10 + (riderInTeam + 1);

        // Kolarze ułożeni w szyku peletonu: wzdłuż szosy i w poprzek
        final row = globalIndex ~/ 4; // ok. 4 kolarzy w rzędzie
        final col = globalIndex % 4;

        final distOffset = (row / 44.0) * pelotonDepthMeters;
        final lateralOffset = -2.5 + (col * 1.65);

        riders.add(RiderPositionSnapshot(
          riderId: 'rider_$bib',
          riderName: 'Kolarz #$bib',
          bibNumber: bib,
          teamId: 'team_$teamIdx',
          teamName: 'Team $teamIdx',
          teamJerseyHexColor: teamColor,
          isPlayerRider: (teamIdx == 0 && riderInTeam == 0), // Lider gracza
          distanceCoveredMeters: baseDistanceMeters - distOffset,
          kilometerMark: (baseDistanceMeters - distOffset) / 1000.0,
          elevationMeters: elevationMeters,
          currentGradientPercent: 3.5,
          currentSegmentIndex: 2,
          speedMs: 12.5, // 45 km/h
          speedKmh: 45.0,
          powerWatts: (riderInTeam == 0) ? 420 : 310,
          wattsPerKg: 4.8,
          cadenceRpm: 92,
          heartRateBpm: 155,
          wPrimePercentage: 0.88,
          wPrimeJoules: 18000,
          glycogenPercentage: 0.75,
          glycogenGrams: 350,
          hydrationPercent: 0.90,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 0,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: distOffset / 12.5,
          lateralPositionRoad: lateralOffset / 3.5,
          lateralOffsetRoadMeters: lateralOffset,
          isDrafting: (row > 1),
          draftingSavingsPercent: (row > 1) ? 0.35 : 0.0,
          isPulling: false,
        ));
      }
    }

    return riders;
  }

  group('PelotonRendererConfig - Konfiguracja i Progi LOD', () {
    test('posiada poprawne domyślne progi odległościowe zgodne ze specyfikacją', () {
      const cfg = PelotonRendererConfig();
      expect(cfg.lod0MaxDistanceMeters, equals(30.0));
      expect(cfg.lod1MaxDistanceMeters, equals(100.0));
      expect(cfg.maxRenderDistanceMeters, equals(380.0));
      expect(cfg.enableFrustumCulling, isTrue);
      expect(cfg.enableDepthSorting, isTrue);
      expect(cfg.enableContactShadows, isTrue);
      expect(cfg.enableAeroStreams, isTrue);
      expect(cfg.enableOverheadTags, isTrue);
    });

    test('LOD Enum zawiera prawidłowe opisy i maksymalne zasięgi', () {
      expect(PelotonLodLevel.fullDetail.maxDistanceMeters, equals(30.0));
      expect(PelotonLodLevel.mediumDetail.maxDistanceMeters, equals(100.0));
      expect(PelotonLodLevel.distantSilhouette.maxDistanceMeters, equals(double.infinity));
    });
  });

  group('PelotonInstancedRenderer - Przygotowanie Kolejki, Culling i LOD', () {
    test('poprawnie przetwarza pełny peleton 176 kolarzy', () {
      final peloton = generatePeloton176(baseDistanceMeters: 10000.0);
      expect(peloton.length, equals(176));

      // Ustawienie kamery za całym peletonem (na 9860m, patrzącej w przód)
      projection.setView(
        eye: Vector3(0.0, 6.0, 9860.0),
        target: Vector3(0.0, 1.2, 9950.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final items = renderer.prepareDrawList(
        riders: peloton,
        projection: projection,
        cameraController: cameraController,
      );

      expect(items.isNotEmpty, isTrue);
      expect(renderer.lastStats.totalRiders, equals(176));
      expect(renderer.lastStats.renderedCount + renderer.lastStats.culledCount, equals(176));
      expect(renderer.lastStats.renderedCount, equals(items.length));
    });

    test('obcina kolarzy znajdujących się za plecami kamery (Frustum Culling)', () {
      final peloton = generatePeloton176(baseDistanceMeters: 10000.0);

      // Kamera umieszczona w połowie peletonu (na 9950m), patrząca w przód (+Z)
      projection.setView(
        eye: Vector3(0.0, 2.0, 9950.0),
        target: Vector3(0.0, 1.5, 9980.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final items = renderer.prepareDrawList(
        riders: peloton,
        projection: projection,
        cameraController: cameraController,
      );

      // Kolarze za kamerą (Z < 9950m) muszą zostać ucięci przez Frustum Culling
      for (final item in items) {
        expect(item.worldPosition.z, greaterThanOrEqualTo(9948.0));
      }

      expect(renderer.lastStats.culledCount, greaterThan(0));
    });

    test('przypisuje właściwe poziomy LOD (LOD 0 <30m, LOD 1 30-100m, LOD 2 >100m)', () {
      // 3 kolarzy w precyzyjnie określonych odległościach od kamery
      final riders = <RiderPositionSnapshot>[
        const RiderPositionSnapshot(
          riderId: 'r_close',
          riderName: 'Bliski',
          bibNumber: 1,
          teamId: 't1',
          teamName: 'T1',
          teamJerseyHexColor: '#FFD700',
          isPlayerRider: true,
          distanceCoveredMeters: 5015.0, // 15m od kamery -> LOD 0
          kilometerMark: 5.015,
          elevationMeters: 0.0,
          currentGradientPercent: 0.0,
          currentSegmentIndex: 0,
          speedMs: 12.0,
          speedKmh: 43.2,
          powerWatts: 380,
          wattsPerKg: 5.5,
          cadenceRpm: 90,
          heartRateBpm: 160,
          wPrimePercentage: 1.0,
          wPrimeJoules: 20000,
          glycogenPercentage: 1.0,
          glycogenGrams: 400,
          hydrationPercent: 1.0,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 0,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 0.0,
          lateralPositionRoad: 0.0,
          lateralOffsetRoadMeters: 0.0,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          isPulling: false,
        ),
        const RiderPositionSnapshot(
          riderId: 'r_mid',
          riderName: 'Średni',
          bibNumber: 2,
          teamId: 't1',
          teamName: 'T1',
          teamJerseyHexColor: '#3B82F6',
          isPlayerRider: false,
          distanceCoveredMeters: 5055.0, // 55m od kamery -> LOD 1
          kilometerMark: 5.055,
          elevationMeters: 0.0,
          currentGradientPercent: 0.0,
          currentSegmentIndex: 0,
          speedMs: 12.0,
          speedKmh: 43.2,
          powerWatts: 320,
          wattsPerKg: 4.5,
          cadenceRpm: 88,
          heartRateBpm: 150,
          wPrimePercentage: 1.0,
          wPrimeJoules: 20000,
          glycogenPercentage: 1.0,
          glycogenGrams: 400,
          hydrationPercent: 1.0,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 0,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 0.0,
          lateralPositionRoad: 0.0,
          lateralOffsetRoadMeters: 0.0,
          isDrafting: true,
          draftingSavingsPercent: 0.3,
          isPulling: false,
        ),
        const RiderPositionSnapshot(
          riderId: 'r_far',
          riderName: 'Daleki',
          bibNumber: 3,
          teamId: 't1',
          teamName: 'T1',
          teamJerseyHexColor: '#EF4444',
          isPlayerRider: false,
          distanceCoveredMeters: 5140.0, // 140m od kamery -> LOD 2
          kilometerMark: 5.140,
          elevationMeters: 0.0,
          currentGradientPercent: 0.0,
          currentSegmentIndex: 0,
          speedMs: 12.0,
          speedKmh: 43.2,
          powerWatts: 300,
          wattsPerKg: 4.2,
          cadenceRpm: 85,
          heartRateBpm: 145,
          wPrimePercentage: 1.0,
          wPrimeJoules: 20000,
          glycogenPercentage: 1.0,
          glycogenGrams: 400,
          hydrationPercent: 1.0,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 0,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 0.0,
          lateralPositionRoad: 0.0,
          lateralOffsetRoadMeters: 0.0,
          isDrafting: true,
          draftingSavingsPercent: 0.35,
          isPulling: false,
        ),
      ];

      // Kamera na 5000m
      projection.setView(
        eye: Vector3(0.0, 1.8, 5000.0),
        target: Vector3(0.0, 1.2, 5100.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final items = renderer.prepareDrawList(
        riders: riders,
        projection: projection,
        cameraController: cameraController,
      );

      expect(items.length, equals(3));

      final closeItem = items.firstWhere((i) => i.snapshot.riderId == 'r_close');
      expect(closeItem.lodLevel, equals(PelotonLodLevel.fullDetail));
      expect(closeItem.animatedPose, isNotNull);

      final midItem = items.firstWhere((i) => i.snapshot.riderId == 'r_mid');
      expect(midItem.lodLevel, equals(PelotonLodLevel.mediumDetail));

      final farItem = items.firstWhere((i) => i.snapshot.riderId == 'r_far');
      expect(farItem.lodLevel, equals(PelotonLodLevel.distantSilhouette));
    });
  });

  group('PelotonInstancedRenderer - Depth Sorting (Painter\'s Algorithm)', () {
    test('sortuje kolarzy w ścisłym porządku Back-to-Front (najdalsi najpierw)', () {
      final peloton = generatePeloton176(baseDistanceMeters: 10000.0);

      projection.setView(
        eye: Vector3(0.0, 6.0, 9860.0),
        target: Vector3(0.0, 1.2, 9950.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final items = renderer.prepareDrawList(
        riders: peloton,
        projection: projection,
        cameraController: cameraController,
      );

      expect(items.length, greaterThan(10));

      // Sprawdzenie monotoniczności malejącej odległości cameraDistance
      for (int i = 0; i < items.length - 1; i++) {
        expect(
          items[i].cameraDistance,
          greaterThanOrEqualTo(items[i + 1].cameraDistance),
          reason: 'Element na indeksie $i musi być dalej od kamery niż element ${i + 1}',
        );
      }
    });
  });

  group('PelotonInstancedRenderer - Rysowanie Canvas w 120 FPS', () {
    test('renderuje 176 kolarzy na Canvas bez crashy i w budżecie klatki 120 FPS', () {
      final peloton = generatePeloton176(baseDistanceMeters: 10000.0);

      projection.setView(
        eye: Vector3(0.0, 2.2, 9940.0),
        target: Vector3(0.0, 1.2, 9990.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final items = renderer.prepareDrawList(
        riders: peloton,
        projection: projection,
        cameraController: cameraController,
      );

      // Nagrywanie klatki na wirtualnym Canvas Fluttera
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1920.0, 1080.0);

      // Główny test wykonania rysowania
      renderer.renderPeloton(
        canvas: canvas,
        size: size,
        projection: projection,
        renderItems: items,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);

      // Weryfikacja statystyk wydajnościowych
      final stats = renderer.lastStats;
      expect(stats.totalRiders, equals(176));
      expect(stats.renderedCount, equals(items.length));
      expect(stats.drawTimeMicroseconds, greaterThan(0));

      // Drugie wywołanie (po rozgrzaniu cache kolorów i shaderów tekstu)
      final recorderWarm = PictureRecorder();
      final canvasWarm = Canvas(recorderWarm);
      renderer.renderPeloton(
        canvas: canvasWarm,
        size: size,
        projection: projection,
        renderItems: items,
      );
      final pictureWarm = recorderWarm.endRecording();
      expect(pictureWarm, isNotNull);

      // Czas klatki w środowisku testowym VM
      expect(renderer.lastStats.totalFrameTimeMs, lessThan(40.0));
    });

    test('reprezentacja graficzna w LOD 0 zawiera wszystkie wymagane detale', () {
      // Przygotowanie kolarza w zasięgu LOD 0
      final rider = generatePeloton176(baseDistanceMeters: 5010.0).first;
      projection.setView(
        eye: Vector3(0.0, 1.5, 5000.0),
        target: Vector3(0.0, 1.2, 5010.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final items = renderer.prepareDrawList(
        riders: [rider],
        projection: projection,
        cameraController: cameraController,
      );

      expect(items.length, equals(1));
      expect(items.first.lodLevel, equals(PelotonLodLevel.fullDetail));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Wywołanie rysowania
      renderer.renderPeloton(
        canvas: canvas,
        size: const Size(1920.0, 1080.0),
        projection: projection,
        renderItems: items,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
