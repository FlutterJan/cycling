import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/roadside_banners_and_arches_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/services/generators/fictional_brands_catalog.dart';
import 'package:vector_math/vector_math_64.dart';

RaceStage _buildTestStage() {
  return const RaceStage(
    id: 'stage_test_177',
    stageNumber: 12,
    name: 'Col du Galibier',
    stageType: StageType.highMountain,
    baseTemperatureCelsius: 18.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 12.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 3.0,
        startElevationM: 800.0,
        endElevationM: 820.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 1,
        startKm: 3.0,
        lengthKm: 4.0,
        startElevationM: 820.0,
        endElevationM: 1180.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      StageSegment(
        index: 2,
        startKm: 7.0,
        lengthKm: 3.0,
        startElevationM: 1180.0,
        endElevationM: 1200.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

void main() {
  group('RoadsideBannersAndArchesRenderer', () {
    test('populates sponsor banners from FictionalBrandsCatalog', () {
      final renderer = RoadsideBannersAndArchesRenderer();
      expect(renderer.catalogBanners, isNotEmpty);
      expect(
        renderer.catalogBanners.length,
        FictionalBrandsCatalog.allBrands.length,
      );
      for (final banner in renderer.catalogBanners) {
        expect(banner.brandName, isNotEmpty);
        expect(banner.primaryColor.a, greaterThan(0.0));
      }
    });

    test('spawns Start, Sprint Intermédiaire, Col/KOM, Flamme Rouge and barriers', () {
      final renderer = RoadsideBannersAndArchesRenderer();
      final stage = _buildTestStage();
      final pack = renderer.spawnForStage(stage);

      expect(pack.arches.length, 4);
      expect(
        pack.arches.map((a) => a.type).toSet(),
        containsAll(<InflatableArchType>{
          InflatableArchType.start,
          InflatableArchType.intermediateSprint,
          InflatableArchType.komMountain,
          InflatableArchType.flammeRouge,
        }),
      );

      final startArch = pack.arches.firstWhere(
        (a) => a.type == InflatableArchType.start,
      );
      expect(startArch.distanceAlongCourseMeters, 0.0);

      final flammeArch = pack.arches.firstWhere(
        (a) => a.type == InflatableArchType.flammeRouge,
      );
      expect(flammeArch.distanceAlongCourseMeters, closeTo(9000.0, 0.1));

      expect(pack.barriers, isNotEmpty);
      expect(pack.barriers.any((b) => b.isRightSide), isTrue);
      expect(pack.barriers.any((b) => !b.isRightSide), isTrue);
    });

    test('renders 3D arches and barriers cleanly at 390x844, 1024x768 and 1600x900', () {
      final renderer = RoadsideBannersAndArchesRenderer();
      final pack = renderer.spawnForStage(_buildTestStage());
      final sizes = <Size>[
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      for (final size in sizes) {
        final projection = Scene3DMathProjection(
          viewportWidth: size.width,
          viewportHeight: size.height,
        )..setView(
            eye: Vector3(0.0, 4.5, -18.0),
            target: Vector3(0.0, 2.0, 35.0),
          );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(
          recorder,
          Rect.fromLTWH(0, 0, size.width, size.height),
        );

        renderer.render(
          canvas: canvas,
          projection: projection,
          arches: pack.arches,
          barriers: pack.barriers,
          elapsedAnimSeconds: 1.25,
          cameraDistanceMeters: 0.0,
        );

        final picture = recorder.endRecording();
        expect(picture, isNotNull);
        picture.dispose();
      }
    });

    test('handles empty stage and disabled config gracefully', () {
      const emptyStage = RaceStage(
        id: 'empty_stage',
        stageNumber: 1,
        name: 'Empty',
        stageType: StageType.flat,
        segments: [],
        baseTemperatureCelsius: 20.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 0.0,
      );

      final renderer = RoadsideBannersAndArchesRenderer(
        config: const RoadsideBannersAndArchesConfig(enabled: false),
      );
      final pack = renderer.spawnForStage(emptyStage);
      expect(pack.isEmpty, isTrue);

      final projection = Scene3DMathProjection(
        viewportWidth: 1024,
        viewportHeight: 768,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1024, 768));

      renderer.render(
        canvas: canvas,
        projection: projection,
        arches: pack.arches,
        barriers: pack.barriers,
      );
      recorder.endRecording().dispose();
    });
  });
}
