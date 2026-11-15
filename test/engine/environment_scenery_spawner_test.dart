// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/environment_scenery_spawner.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Scene3DMathProjection projection;

  setUp(() {
    projection = Scene3DMathProjection(
      viewportWidth: 1920.0,
      viewportHeight: 1080.0,
      fovYDegrees: 60.0,
      zNear: 0.5,
      zFar: 1500.0,
    );
  });

  /// Pomocnicza fabryka segmentu trasy
  StageSegment createSegment({
    required int index,
    required double startKm,
    required double lengthKm,
    required double startElevationM,
    required double endElevationM,
    SegmentSurfaceType surfaceType = SegmentSurfaceType.smoothAsphalt,
    SegmentClassification classification = SegmentClassification.none,
  }) {
    return StageSegment(
      index: index,
      startKm: startKm,
      lengthKm: lengthKm,
      startElevationM: startElevationM,
      endElevationM: endElevationM,
      surfaceType: surfaceType,
      technicalDifficulty: 25.0,
      windDirectionDegrees: 180.0,
      roadBearingDegrees: 0.0,
      sprintOrKomClassification: classification,
    );
  }

  group('ElevationBiomeZone - Klasyfikacja Stref Wysokościowych', () {
    test('poprawnie klasyfikuje strefy wysokościowe na podstawie metrów n.p.m.', () {
      // Poniżej 800m -> Nizina / Dolina
      expect(ElevationBiomeZone.fromElevation(0.0), equals(ElevationBiomeZone.lowlandValley));
      expect(ElevationBiomeZone.fromElevation(450.0), equals(ElevationBiomeZone.lowlandValley));
      expect(ElevationBiomeZone.fromElevation(799.0), equals(ElevationBiomeZone.lowlandValley));

      // 800m - 1800m -> Regiel Górski / Bór Świerkowy
      expect(ElevationBiomeZone.fromElevation(800.0), equals(ElevationBiomeZone.subalpineForest));
      expect(ElevationBiomeZone.fromElevation(1250.0), equals(ElevationBiomeZone.subalpineForest));
      expect(ElevationBiomeZone.fromElevation(1800.0), equals(ElevationBiomeZone.subalpineForest));

      // Powyżej 1800m -> Wysokie Alpy / Tundra Turniowa
      expect(ElevationBiomeZone.fromElevation(1801.0), equals(ElevationBiomeZone.highAlpineTundra));
      expect(ElevationBiomeZone.fromElevation(2642.0), equals(ElevationBiomeZone.highAlpineTundra)); // Col du Galibier
      expect(ElevationBiomeZone.fromElevation(2758.0), equals(ElevationBiomeZone.highAlpineTundra)); // Passo dello Stelvio
    });
  });

  group('EnvironmentScenerySpawner - Strefa Nizinna (<800m n.p.m.)', () {
    test('poniżej 800m generuje drzewa liściaste, kamienice miasteczek i kibiców', () {
      final spawner = EnvironmentScenerySpawner(
        config: const ScenerySpawnerConfig(
          region: GeographicRegion.alpsAndDolomites,
          sampleStepMeters: 14.0,
          forwardVisibilityMeters: 400.0,
          backwardVisibilityMeters: 50.0,
        ),
      );

      final segments = [
        createSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 10.0,
          startElevationM: 250.0,
          endElevationM: 450.0,
        ),
      ];

      final instances = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 2000.0,
        segments: segments,
        projection: projection,
        totalStageLengthKm: 100.0,
      );

      expect(instances.isNotEmpty, isTrue);

      // Wszystkie obiekty w tej strefie należą do lowlandValley
      for (final inst in instances) {
        expect(inst.biomeZone, equals(ElevationBiomeZone.lowlandValley));
        expect(inst.elevationMeters, lessThan(800.0));

        // Bezpieczna odległość od osi jezdni (nigdy nie stoi na środku szosy)
        expect(inst.lateralOffsetMeters.abs(), greaterThanOrEqualTo(4.0));
      }

      // W strefie nizinnej pojawiają się drzewa liściaste lub kamienice
      final hasDeciduous = instances.any((i) => i.type == SceneryObjectType.deciduousTree);
      final hasTownhouse = instances.any((i) => i.type == SceneryObjectType.townhouse);
      expect(hasDeciduous || hasTownhouse, isTrue);
    });

    test('w regionie Toskanii generuje charakterystyczne cyprysy włoskie', () {
      final spawner = EnvironmentScenerySpawner(
        config: const ScenerySpawnerConfig(
          region: GeographicRegion.tuscanyAndMediterranean,
          sampleStepMeters: 12.0,
          forwardVisibilityMeters: 500.0,
        ),
      );

      final segments = [
        createSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 15.0,
          startElevationM: 180.0,
          endElevationM: 320.0,
        ),
      ];

      final instances = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 3000.0,
        segments: segments,
        projection: projection,
      );

      final hasCypress = instances.any((i) => i.type == SceneryObjectType.cypressTree);
      expect(hasCypress, isTrue, reason: 'W Toskanii muszą pojawiać się cyprysy włoskie');
    });

    test('na nizinach i sektorach brukowanych generuje pola uprawne oraz brukowane aleje z drzewami', () {
      final spawner = EnvironmentScenerySpawner(
        config: const ScenerySpawnerConfig(
          region: GeographicRegion.flandersAndArdennes,
          sampleStepMeters: 10.0,
          forwardVisibilityMeters: 800.0,
        ),
      );

      final segments = [
        createSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 15.0,
          startElevationM: 40.0,
          endElevationM: 120.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector3,
        ),
      ];

      final instances = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 4000.0,
        segments: segments,
        projection: projection,
      );

      final hasAvenueTree = instances.any((i) => i.type == SceneryObjectType.avenueTree);
      final hasFarmland = instances.any((i) => i.type == SceneryObjectType.farmlandField);

      expect(hasAvenueTree, isTrue, reason: 'W alejach brukowanych Flandrii muszą występować drzewa w szpalerze alei');
      expect(hasFarmland || instances.any((i) => i.type == SceneryObjectType.deciduousTree), isTrue);
    });
  });

  group('EnvironmentScenerySpawner - Regiel Górski (800m – 1800m n.p.m.)', () {
    test('w przedziale 800m-1800m generuje sosny alpejskie, głazy i drewniane barierki', () {
      final spawner = EnvironmentScenerySpawner(
        config: const ScenerySpawnerConfig(
          sampleStepMeters: 14.0,
          forwardVisibilityMeters: 450.0,
        ),
      );

      final segments = [
        createSegment(
          index: 0,
          startKm: 20.0,
          lengthKm: 12.0,
          startElevationM: 950.0,
          endElevationM: 1650.0,
        ),
      ];

      final instances = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 24000.0,
        segments: segments,
        projection: projection,
      );

      expect(instances.isNotEmpty, isTrue);

      for (final inst in instances) {
        expect(inst.biomeZone, equals(ElevationBiomeZone.subalpineForest));
        expect(inst.elevationMeters, inInclusiveRange(800.0, 1800.0));
      }

      // W reglu górskim pojawiają się sosny i głazy
      final hasPines = instances.any((i) => i.type == SceneryObjectType.pineTree);
      final hasRocks = instances.any((i) => i.type == SceneryObjectType.boulderRock);
      expect(hasPines, isTrue);
      expect(hasRocks, isTrue);
    });
  });

  group('EnvironmentScenerySpawner - Wysokie Alpy (>1800m n.p.m.) & Finiszowy Szpaler', () {
    test('powyżej 1800m generuje turnie skalne, łaty śniegu i szpalery kibiców', () {
      final spawner = EnvironmentScenerySpawner(
        config: const ScenerySpawnerConfig(
          sampleStepMeters: 12.0,
          forwardVisibilityMeters: 400.0,
        ),
      );

      // Etap z metą na Alpe d'Huez / Passo dello Stelvio (długość 25km, meta na 2100m)
      final segments = [
        createSegment(
          index: 0,
          startKm: 20.0,
          lengthKm: 5.0,
          startElevationM: 1850.0,
          endElevationM: 2150.0,
          classification: SegmentClassification.horsCategorie,
        ),
      ];

      // Kolarze znajdują się na 24200m (800m do mety etapu na 25000m)
      final instances = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 24200.0,
        segments: segments,
        projection: projection,
        totalStageLengthKm: 25.0, // Meta na 25.0 km
      );

      expect(instances.isNotEmpty, isTrue);

      for (final inst in instances) {
        expect(inst.biomeZone, equals(ElevationBiomeZone.highAlpineTundra));
        expect(inst.elevationMeters, greaterThan(1800.0));
      }

      // Obecność elementów wysokogórskich: głazy, turnie skalne lub śnieg
      final hasRocksOrSnow = instances.any(
        (i) => i.type == SceneryObjectType.boulderRock ||
            i.type == SceneryObjectType.alpineCrag ||
            i.type == SceneryObjectType.snowPatch,
      );
      expect(hasRocksOrSnow, isTrue);

      // Sprawdzenie obecności ostrych turni skalnych (alpineCrag)
      final hasCrags = instances.any((i) => i.type == SceneryObjectType.alpineCrag);
      expect(hasCrags, isTrue, reason: 'W Wysokich Alpach i Dolomitach muszą powstawać turnie i urwiska skalne');

      // Na ostatnim kilometrze podjazdu musi powstać gęsty szpaler kibiców z flagami
      final crowdFans = instances.where((i) => i.type == SceneryObjectType.cheeringSpectators).toList();
      expect(crowdFans.length, greaterThanOrEqualTo(3), reason: 'Na finiszu podjazdu musi być gęsty tłum kibiców');
    });
  });

  group('EnvironmentScenerySpawner - Determinizm i Stabilność Generowania', () {
    test('ten sam seed i pozycja kamery generują dokładnie te same obiekty krajobrazu', () {
      final spawner = EnvironmentScenerySpawner();

      final segments = [
        createSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 10.0,
          startElevationM: 500.0,
          endElevationM: 1200.0,
        ),
      ];

      final run1 = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 5000.0,
        segments: segments,
        projection: projection,
        stageSeed: 12345,
      );

      final run2 = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 5000.0,
        segments: segments,
        projection: projection,
        stageSeed: 12345,
      );

      expect(run1.length, equals(run2.length));
      for (int i = 0; i < run1.length; i++) {
        expect(run1[i].id, equals(run2[i].id));
        expect(run1[i].type, equals(run2[i].type));
        expect(run1[i].worldPosition.x, closeTo(run2[i].worldPosition.x, 1e-4));
        expect(run1[i].worldPosition.z, closeTo(run2[i].worldPosition.z, 1e-4));
      }
    });
  });

  group('EnvironmentScenerySpawner - Rysowanie Canvas 3D', () {
    test('renderuje instancje otoczenia na Canvas bez błędów', () {
      final spawner = EnvironmentScenerySpawner();

      final segments = [
        createSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 10.0,
          startElevationM: 400.0,
          endElevationM: 1900.0,
        ),
      ];

      projection.setView(
        eye: Vector3(0.0, 3.5, 4980.0),
        target: Vector3(0.0, 1.2, 5100.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final instances = spawner.spawnSceneryInWindow(
        cameraDistanceMeters: 5000.0,
        segments: segments,
        projection: projection,
      );

      expect(instances.isNotEmpty, isTrue);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Główny test rysowania otoczenia
      spawner.renderSceneryInstances(
        canvas: canvas,
        projection: projection,
        instances: instances,
        animSeconds: 1.25,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
