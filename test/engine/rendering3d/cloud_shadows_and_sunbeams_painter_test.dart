import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/cloud_shadows_and_sunbeams_painter.dart';
import 'package:pro_peloton_manager/engine/rendering3d/dynamic_skybox_and_lighting_painter.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('CloudShadowFieldEvaluator', () {
    test('przesuwa plamy cienia zgodnie z wektorem wiatru w czasie', () {
      final patches = CloudShadowFieldEvaluator.generatePatches(seed: 263, patchCount: 10);
      const wind = CloudWindVector(windSpeedMs: 12.0, windDirectionRadians: math.pi * 0.5);

      final centerT0 = CloudShadowFieldEvaluator.computeWrappedPatchCenter(
        patch: patches.first,
        wind: wind,
        elapsedSeconds: 0.0,
        refX: 0.0,
        refZ: 0.0,
      );
      final centerT5 = CloudShadowFieldEvaluator.computeWrappedPatchCenter(
        patch: patches.first,
        wind: wind,
        elapsedSeconds: 5.0,
        refX: 0.0,
        refZ: 0.0,
      );

      expect(centerT0.dx, isNot(closeTo(centerT5.dx, 0.5)));
      expect(centerT5.dy, closeTo(centerT0.dy, 0.001));
    });

    test('lokalnie obniża jasność asfaltu i temperaturę odczuwalną w cieniu chmury', () {
      const wind = CloudWindVector(windSpeedMs: 8.0, windDirectionRadians: 0.4);
      final patches = CloudShadowFieldEvaluator.generatePatches(seed: 263, patchCount: 14);
      final targetPatch = patches.first;

      final inShadow = CloudShadowFieldEvaluator.evaluateShadowAtWorldPoint(
        worldX: targetPatch.baseWorldX,
        worldZ: targetPatch.baseWorldZ,
        elapsedSeconds: 0.0,
        wind: wind,
        weather: WeatherCondition.sunny,
        timeOfDay: const StageTimeOfDay(hour: 13, minute: 30),
        precomputedPatches: patches,
      );

      expect(inShadow.shadowIntensity, greaterThan(0.2));
      expect(inShadow.asphaltBrightnessMultiplier, lessThan(1.0));
      expect(inShadow.apparentTemperatureDeltaCelsius, lessThan(0.0));
    });

    test('w nocy cienie chmur i delty temperatury słonecznej wygasają do zera', () {
      const wind = CloudWindVector(windSpeedMs: 6.0, windDirectionRadians: 0.0);
      final patches = CloudShadowFieldEvaluator.generatePatches(seed: 263, patchCount: 12);

      final nightSample = CloudShadowFieldEvaluator.evaluateShadowAtWorldPoint(
        worldX: patches.first.baseWorldX,
        worldZ: patches.first.baseWorldZ,
        elapsedSeconds: 0.0,
        wind: wind,
        weather: WeatherCondition.sunny,
        timeOfDay: const StageTimeOfDay.nightFinale(),
        precomputedPatches: patches,
      );

      expect(nightSample.shadowIntensity, equals(0.0));
      expect(nightSample.sunbeamFactor, equals(0.0));
      expect(nightSample.apparentTemperatureDeltaCelsius, equals(0.0));
      expect(nightSample.asphaltBrightnessMultiplier, equals(1.0));
    });

    test('evaluateRidersThermalAndBrightness wylicza wpływ dla listy kolarzy', () {
      final riders = <CoursePosition>[
        const CoursePosition(distanceMeters: 120.0, lateralOffsetMeters: -1.2, elevationMeters: 450.0),
        const CoursePosition(distanceMeters: 260.0, lateralOffsetMeters: 1.5, elevationMeters: 462.0),
      ];

      final impacts = CloudShadowFieldEvaluator.evaluateRidersThermalAndBrightness(
        riderPositions: riders,
        roadGeometry: const RoadGeometryParameters(gradientPercent: 6.0),
        elapsedSeconds: 4.0,
        wind: const CloudWindVector(windSpeedMs: 10.0),
        weather: WeatherCondition.extremeHeat,
        timeOfDay: const StageTimeOfDay(hour: 14, minute: 0),
        baseAmbientTempCelsius: 31.0,
      );

      expect(impacts, hasLength(2));
      for (final impact in impacts) {
        expect(impact.sample.asphaltBrightnessMultiplier, inInclusiveRange(0.54, 1.08));
        expect(impact.effectiveApparentTempCelsius, lessThanOrEqualTo(32.0));
      }
    });
  });

  group('CloudShadowsAndSunbeamsPainter', () {
    test('renderuje poprawnie w trybie 3D z Scene3DMathProjection oraz w trybie fallback', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 1280,
        viewportHeight: 720,
      )..updateCamera(
          Camera3DConfig(
            position: Vector3(0.0, 5.5, -14.0),
            target: Vector3(0.0, 1.2, 45.0),
          ),
          viewportWidth: 1280,
          viewportHeight: 720,
        );

      final painter3d = CloudShadowsAndSunbeamsPainter(
        projection: projection,
        cameraCourseDistanceMeters: 0.0,
        cameraElevationMeters: 0.0,
        weatherCondition: WeatherCondition.crosswindGale,
        timeOfDay: const StageTimeOfDay.alpineGoldenHour(),
        elapsedSeconds: 3.5,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter3d.paint(canvas, const Size(1280, 720));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);

      const fallbackPainter = CloudShadowsAndSunbeamsPainter(
        projection: null,
        weatherCondition: WeatherCondition.sunny,
        elapsedSeconds: 1.2,
      );
      final recorder2 = ui.PictureRecorder();
      fallbackPainter.paint(Canvas(recorder2), const Size(640, 360));
      expect(recorder2.endRecording(), isNotNull);

      expect(painter3d.shouldRepaint(fallbackPainter), isTrue);
    });
  });

  group('CloudShadowsAndSunbeamsControlPanel', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester, {
      required Size size,
      bool enabled = true,
      ValueChanged<CloudShadowsAndSunbeamsConfig>? onConfigChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const telemetry = CloudShadowsTelemetry(
        activePatchCount: 8,
        sunbeamShaftCount: 5,
        averageRoadShadowIntensity: 0.34,
        averageAsphaltBrightness: 0.84,
        minRiderTempDeltaC: -2.4,
        maxRiderTempDeltaC: -0.3,
        windSpeedKmh: 23.4,
        effectiveCloudCoverage: 0.45,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CloudShadowsAndSunbeamsControlPanel(
                config: const CloudShadowsAndSunbeamsConfig(),
                windVector: const CloudWindVector(),
                telemetry: telemetry,
                enabled: enabled,
                onConfigChanged: onConfigChanged ?? (_) {},
                onWindChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje bez przepełnienia w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        await pumpPanelAtSize(tester, size: size);
        expect(find.text('Cienie Chmur i Promienie 3D'), findsOneWidget);
        expect(find.text('Asfalt 84%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('reaguje na przełączniki jakości i warstw oraz respektuje disabled', (tester) async {
      CloudShadowsAndSunbeamsConfig? updated;
      await pumpPanelAtSize(
        tester,
        size: const Size(1024, 768),
        onConfigChanged: (cfg) => updated = cfg,
      );

      await tester.tap(find.text('Balanced'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(updated?.quality, equals(CloudShadowQuality.balanced));

      updated = null;
      await pumpPanelAtSize(
        tester,
        size: const Size(1024, 768),
        enabled: false,
        onConfigChanged: (cfg) => updated = cfg,
      );
      await tester.tap(find.text('Szosa'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(updated, isNull);
    });
  });
}
