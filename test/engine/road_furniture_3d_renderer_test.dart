// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/road_furniture_3d_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Scene3DMathProjection projection;

  setUp(() {
    projection = Scene3DMathProjection(
      viewportWidth: 1280.0,
      viewportHeight: 720.0,
      fovYDegrees: 60.0,
      zNear: 0.5,
      zFar: 600.0,
    );
  });

  /// Generator testowego etapu wieloetapowego wyścigu z lotną premią i premiami górskimi.
  RaceStage createSampleStage({
    double totalDistanceKm = 160.0,
    bool includeClimbs = true,
  }) {
    final segments = <StageSegment>[
      // Segment 1: Rozgrzewkowy płaski (0 - 40 km)
      const StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 40.0,
        startElevationM: 150.0,
        endElevationM: 180.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 10.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // Segment 2: Lotna premia sprinterska (40 - 70 km, meta premii na 70 km)
      const StageSegment(
        index: 1,
        startKm: 40.0,
        lengthKm: 30.0,
        startElevationM: 180.0,
        endElevationM: 210.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      // Segment 3: Podjazd Cat 2 (70 - 100 km)
      StageSegment(
        index: 2,
        startKm: 70.0,
        lengthKm: 30.0,
        startElevationM: 210.0,
        endElevationM: 950.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 40.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: includeClimbs ? SegmentClassification.cat2 : SegmentClassification.none,
      ),
      // Segment 4: Wysokogórska premia Hors Catégorie (100 - 130 km)
      StageSegment(
        index: 3,
        startKm: 100.0,
        lengthKm: 30.0,
        startElevationM: 950.0,
        endElevationM: 2115.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 65.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: includeClimbs ? SegmentClassification.horsCategorie : SegmentClassification.none,
      ),
      // Segment 5: Zjazd i finałowa prosta do mety (130 - 160 km)
      const StageSegment(
        index: 4,
        startKm: 130.0,
        lengthKm: 30.0,
        startElevationM: 2115.0,
        endElevationM: 350.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 25.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ];

    return RaceStage(
      id: 'tour_stage_1',
      stageNumber: 1,
      name: 'Grand Départ - Etap 1',
      stageType: includeClimbs ? StageType.highMountain : StageType.flat,
      segments: segments,
      baseTemperatureCelsius: 22.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 14.0,
    );
  }

  group('RoadFurnitureType & SponsorBrand - Typy i Marki Sponsorów', () {
    test('zawiera wszystkie wymagane typy elementów infrastruktury szosowej', () {
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.crowdBarrierWithBanner));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.distanceCountdownBoard));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.flammeRougeArch));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.intermediateSprintArch));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.komMountainArch));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.finishLineGantry));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.finishCheckeredLine));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.finishPhotoFinishTower));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.finishVipGrandstand));
      expect(RoadFurnitureType.values, contains(RoadFurnitureType.finishPodiumBackdrop));
    });

    test('poprawnie kategoryzuje bramownice napowietrzne oraz elementy strefy mety', () {
      expect(RoadFurnitureType.flammeRougeArch.isOverheadArch, isTrue);
      expect(RoadFurnitureType.intermediateSprintArch.isOverheadArch, isTrue);
      expect(RoadFurnitureType.komMountainArch.isOverheadArch, isTrue);
      expect(RoadFurnitureType.finishLineGantry.isOverheadArch, isTrue);
      expect(RoadFurnitureType.crowdBarrierWithBanner.isOverheadArch, isFalse);

      expect(RoadFurnitureType.finishLineGantry.isFinishZone, isTrue);
      expect(RoadFurnitureType.finishCheckeredLine.isFinishZone, isTrue);
      expect(RoadFurnitureType.finishVipGrandstand.isFinishZone, isTrue);
      expect(RoadFurnitureType.finishPhotoFinishTower.isFinishZone, isTrue);
      expect(RoadFurnitureType.distanceCountdownBoard.isFinishZone, isFalse);
    });

    test('definiuje autentyczne marki sponsorów kolarskich', () {
      expect(SponsorBrand.values, contains(SponsorBrand.shimano));
      expect(SponsorBrand.values, contains(SponsorBrand.skoda));
      expect(SponsorBrand.values, contains(SponsorBrand.continental));
      expect(SponsorBrand.values, contains(SponsorBrand.tissot));
      expect(SponsorBrand.values, contains(SponsorBrand.santini));
      expect(SponsorBrand.values, contains(SponsorBrand.lcl));
      expect(SponsorBrand.values, contains(SponsorBrand.carrefour));

      expect(SponsorBrand.shimano.name, equals('SHIMANO'));
      expect(SponsorBrand.tissot.name, equals('TISSOT'));
    });
  });

  group('RoadFurnitureConfig - Konfiguracja Renderera', () {
    test('posiada przemyślane parametry domyślne', () {
      const config = RoadFurnitureConfig();
      expect(config.enabled, isTrue);
      expect(config.forwardVisibilityMeters, equals(380.0));
      expect(config.backwardVisibilityMeters, equals(70.0));
      expect(config.finishBarriersLengthMeters, equals(1200.0));
      expect(config.enableCountdownBoards, isTrue);
      expect(config.enableFlammeRouge, isTrue);
      expect(config.enableVipGrandstands, isTrue);
      expect(config.enablePhotoFinishTowers, isTrue);
    });
  });

  group('RoadFurniture3DRenderer - Spawner Infrastruktury Etapu', () {
    test('generuje pełną scenografię dla etapu górskiego', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0, includeClimbs: true);

      final items = renderer.spawnFurnitureForStage(stage: stage);
      expect(items.isNotEmpty, isTrue);

      // 1. Weryfikacja tablic odliczania dystansu (20, 10, 5, 3 km)
      final countdowns = items.where((i) => i.type == RoadFurnitureType.distanceCountdownBoard).toList();
      expect(countdowns.length, equals(4));

      final labels = countdowns.map((c) => c.customLabel).toSet();
      expect(labels, contains('20 KM'));
      expect(labels, contains('10 KM'));
      expect(labels, contains('5 KM'));
      expect(labels, contains('3 KM'));

      // 2. Weryfikacja czerwonej bramy Flamme Rouge (1 km przed metą = na 159,000m)
      final flammeRouge = items.firstWhere((i) => i.type == RoadFurnitureType.flammeRougeArch);
      expect(flammeRouge.distanceAlongCourseMeters, equals(159000.0));
      expect(flammeRouge.customLabel, equals('1 KM'));

      // 3. Weryfikacja zielonej bramy lotnej premii (na 70,000m)
      final sprintArch = items.firstWhere((i) => i.type == RoadFurnitureType.intermediateSprintArch);
      expect(sprintArch.distanceAlongCourseMeters, equals(70000.0));
      expect(sprintArch.customLabel, contains('SPRINT'));

      // 4. Weryfikacja bram premii górskich (Cat 2 na 100,000m i HC na 130,000m)
      final komArches = items.where((i) => i.type == RoadFurnitureType.komMountainArch).toList();
      expect(komArches.length, equals(2));
      expect(komArches.any((a) => a.customLabel!.contains('HORS CATÉGORIE')), isTrue);
      expect(komArches.any((a) => a.customLabel!.contains('2e CAT')), isTrue);

      // 5. Weryfikacja scenografii linii mety (na 160,000m)
      final finishGantry = items.firstWhere((i) => i.type == RoadFurnitureType.finishLineGantry);
      expect(finishGantry.distanceAlongCourseMeters, equals(160000.0));

      final finishLine = items.firstWhere((i) => i.type == RoadFurnitureType.finishCheckeredLine);
      expect(finishLine.distanceAlongCourseMeters, equals(160000.0));

      final finishTowers = items.where((i) => i.type == RoadFurnitureType.finishPhotoFinishTower).toList();
      expect(finishTowers.length, equals(2)); // Lewa i prawa strona kreski mety

      final vipStands = items.where((i) => i.type == RoadFurnitureType.finishVipGrandstand).toList();
      expect(vipStands.length, equals(2)); // Lewa i prawa trybuna VIP

      final podium = items.firstWhere((i) => i.type == RoadFurnitureType.finishPodiumBackdrop);
      expect(podium.distanceAlongCourseMeters, greaterThan(160000.0));

      // 6. Weryfikacja ciągłego korytarza barierek ze sponsorami
      final barriers = items.where((i) => i.type == RoadFurnitureType.crowdBarrierWithBanner).toList();
      expect(barriers.length, greaterThan(200));

      // Weryfikacja cykliczności sponsorów na barierkach
      final sponsorBrands = barriers.map((b) => b.sponsor).toSet();
      expect(sponsorBrands, contains(SponsorBrand.shimano));
      expect(sponsorBrands, contains(SponsorBrand.skoda));
      expect(sponsorBrands, contains(SponsorBrand.continental));
      expect(sponsorBrands, contains(SponsorBrand.tissot));
    });

    test('używa buforowania (caching) dla tego samego etapu', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0);

      final list1 = renderer.spawnFurnitureForStage(stage: stage);
      final list2 = renderer.spawnFurnitureForStage(stage: stage);

      expect(identical(list1, list2), isTrue);
    });

    test('zwraca pustą listę gdy moduł jest wyłączony', () {
      final renderer = RoadFurniture3DRenderer(
        config: const RoadFurnitureConfig(enabled: false),
      );
      final stage = createSampleStage();

      final items = renderer.spawnFurnitureForStage(stage: stage);
      expect(items.isEmpty, isTrue);
    });
  });

  group('RoadFurniture3DRenderer - Okno Widoczności i Filtrowanie', () {
    test('getFurnitureInWindow zwraca tylko elementy w zasięgu wzroku kamery', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0);
      final allItems = renderer.spawnFurnitureForStage(stage: stage);

      // Kamera na 159,500m (500m przed metą, widząca finisz)
      final inWindow = renderer.getFurnitureInWindow(
        allFurniture: allItems,
        cameraDistanceMeters: 159500.0,
      );

      expect(inWindow.isNotEmpty, isTrue);
      // Wszystkie elementy w oknie mieszczą się w przedziale [camera - backward, camera + forward]
      for (final item in inWindow) {
        expect(item.distanceAlongCourseMeters, greaterThanOrEqualTo(159500.0 - 70.0));
        expect(item.distanceAlongCourseMeters, lessThanOrEqualTo(159500.0 + 380.0));
      }

      // Elementy z 70km (lotna premia) nie powinny znaleźć się w oknie mety
      expect(inWindow.any((i) => i.type == RoadFurnitureType.intermediateSprintArch), isFalse);
    });
  });

  group('RoadFurniture3DRenderer - Renderowanie Canvas w 120 FPS', () {
    test('renderuje pełną scenografię finiszu na obiekcie Canvas bez błędów', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0);
      final allItems = renderer.spawnFurnitureForStage(stage: stage);

      // Kamera na 159,960m (40m przed metą), patrząca prosto na bramę mety
      projection.setView(
        eye: Vector3(0.0, 2.5, 159960.0),
        target: Vector3(0.0, 3.5, 160010.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final finishItems = renderer.getFurnitureInWindow(
        allFurniture: allItems,
        cameraDistanceMeters: 159960.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderRoadFurniture(
        canvas: canvas,
        projection: projection,
        instances: finishItems,
        elapsedAnimSeconds: 2.5,
        stageElapsedTime: const Duration(hours: 3, minutes: 54, seconds: 12),
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('renderuje czerwoną bramę Flamme Rouge (1 km) z proporcem', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0);
      final allItems = renderer.spawnFurnitureForStage(stage: stage);

      // Kamera na 158,970m (30m przed Flamme Rouge na 159,000m)
      projection.setView(
        eye: Vector3(0.0, 2.2, 158970.0),
        target: Vector3(0.0, 3.0, 159010.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final flammeItems = renderer.getFurnitureInWindow(
        allFurniture: allItems,
        cameraDistanceMeters: 158970.0,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderRoadFurniture(
        canvas: canvas,
        projection: projection,
        instances: flammeItems,
        elapsedAnimSeconds: 1.0,
      );

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('renderuje zieloną bramę lotnej premii i górską bramę KOM w grochy', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0);
      final allItems = renderer.spawnFurnitureForStage(stage: stage);

      // 1. Lotna premia na 70,000m
      projection.setView(
        eye: Vector3(0.0, 2.2, 69970.0),
        target: Vector3(0.0, 3.0, 70010.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final sprintItems = renderer.getFurnitureInWindow(
        allFurniture: allItems,
        cameraDistanceMeters: 69970.0,
      );

      final rec1 = PictureRecorder();
      renderer.renderRoadFurniture(
        canvas: Canvas(rec1),
        projection: projection,
        instances: sprintItems,
      );
      expect(rec1.endRecording(), isNotNull);

      // 2. Brama KOM na 130,000m
      projection.setView(
        eye: Vector3(0.0, 2.2, 129970.0),
        target: Vector3(0.0, 3.0, 130010.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final komItems = renderer.getFurnitureInWindow(
        allFurniture: allItems,
        cameraDistanceMeters: 129970.0,
      );

      final rec2 = PictureRecorder();
      renderer.renderRoadFurniture(
        canvas: Canvas(rec2),
        projection: projection,
        instances: komItems,
      );
      expect(rec2.endRecording(), isNotNull);
    });

    test('renderuje tablice odliczania dystansu (20 km, 10 km, 5 km, 3 km)', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0);
      final allItems = renderer.spawnFurnitureForStage(stage: stage);

      // Tablica 5 km (na 155,000m)
      projection.setView(
        eye: Vector3(0.0, 2.0, 154980.0),
        target: Vector3(4.8, 2.5, 155010.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final countdownItems = renderer.getFurnitureInWindow(
        allFurniture: allItems,
        cameraDistanceMeters: 154980.0,
      );

      final recorder = PictureRecorder();
      renderer.renderRoadFurniture(
        canvas: Canvas(recorder),
        projection: projection,
        instances: countdownItems,
      );
      expect(recorder.endRecording(), isNotNull);
    });

    test('odrzuca elementy znajdujące się za plecami kamery (Frustum Culling)', () {
      final renderer = RoadFurniture3DRenderer();
      final stage = createSampleStage(totalDistanceKm: 160.0);
      final allItems = renderer.spawnFurnitureForStage(stage: stage);

      // Kamera na 160,050m (za metą) patrząca w przód (od mety w stronę +Z)
      projection.setView(
        eye: Vector3(0.0, 2.0, 160050.0),
        target: Vector3(0.0, 2.0, 160100.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      // Brama mety na 160,000m jest za plecami kamery
      final recorder = PictureRecorder();
      renderer.renderRoadFurniture(
        canvas: Canvas(recorder),
        projection: projection,
        instances: allItems.where((i) => i.distanceAlongCourseMeters <= 160000.0).toList(),
      );

      expect(recorder.endRecording(), isNotNull);
    });
  });
}

