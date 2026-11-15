import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/alpine_crowd_tunnel_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('AlpineCrowdTunnelRenderer', () {
    test('detectSteepTunnelZones detects and merges contiguous segments > 8%', () {
      const RaceStage stage = RaceStage(
        id: 'alpe_dhuez_stage',
        stageNumber: 14,
        name: 'Alpe d\'Huez',
        stageType: StageType.summitFinish,
        baseTemperatureCelsius: 22.0,
        weatherCondition: WeatherCondition.sunny,
        windSpeedKmh: 12.0,
        segments: <StageSegment>[
          // 5.0% flat-ish approach (not > 8%)
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 2.0,
            startElevationM: 700.0,
            endElevationM: 800.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          // 10.0% steep climb
          StageSegment(
            index: 1,
            startKm: 2.0,
            lengthKm: 1.5,
            startElevationM: 800.0,
            endElevationM: 950.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 55.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.cat1,
          ),
          // 9.5% contiguous steep climb -> should merge with segment 1
          StageSegment(
            index: 2,
            startKm: 3.5,
            lengthKm: 2.0,
            startElevationM: 950.0,
            endElevationM: 1140.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 65.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.horsCategorie,
          ),
          // 8.0% boundary (not strictly > 8%)
          StageSegment(
            index: 3,
            startKm: 5.5,
            lengthKm: 1.0,
            startElevationM: 1140.0,
            endElevationM: 1220.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 30.0,
            windDirectionDegrees: 180.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
        ],
      );

      final List<AlpineCrowdTunnelZone> zones =
          AlpineCrowdTunnelRenderer.detectSteepTunnelZones(stage);

      expect(zones.length, 1);
      expect(zones.first.startDistanceMeters, 2000.0);
      expect(zones.first.endDistanceMeters, 5500.0);
      expect(zones.first.maxGradientPercent, closeTo(10.0, 0.01));
      expect(zones.first.peakClassification, SegmentClassification.horsCategorie);
    });

    test('corridor narrows to 2.8m ahead of leader and parts just before wheel', () {
      final AlpineCrowdTunnelRenderer renderer = AlpineCrowdTunnelRenderer();
      const double leaderWheelDist = 2500.0;

      // Far ahead (> 14m ahead of leader's front wheel): tight 2.8m corridor
      final double farAheadCorridor = renderer.computeCorridorWidthAtDistance(
        distanceMeters: leaderWheelDist + 20.0,
        gradientPercent: 10.5,
        leaderFrontWheelDistanceMeters: leaderWheelDist,
      );
      expect(farAheadCorridor, closeTo(2.8, 0.001));

      // Right at the leader's front wheel: spectators have parted wider
      final double atWheelCorridor = renderer.computeCorridorWidthAtDistance(
        distanceMeters: leaderWheelDist + 1.5,
        gradientPercent: 10.5,
        leaderFrontWheelDistanceMeters: leaderWheelDist,
      );
      expect(atWheelCorridor, greaterThan(3.8));

      // Gentle slope <= 8%: standard 7.2m road width
      final double gentleCorridor = renderer.computeCorridorWidthAtDistance(
        distanceMeters: leaderWheelDist + 20.0,
        gradientPercent: 6.5,
        leaderFrontWheelDistanceMeters: leaderWheelDist,
      );
      expect(gentleCorridor, closeTo(7.2, 0.001));
    });

    test('buildVisibleSpectators spawns national jerseys, flags, and orange/red flares', () {
      final AlpineCrowdTunnelRenderer renderer = AlpineCrowdTunnelRenderer();

      final List<AlpineCrowdTunnelSpectator3D> spectators =
          renderer.buildVisibleSpectators(
        cameraCourseDistanceMeters: 2500.0,
        currentGradientPercent: 11.2,
        elevationAtDistance: (double d) => 1200.0 + d * 0.112,
      );

      expect(spectators, isNotEmpty);
      expect(spectators.any((s) => s.hasFlag), isTrue);
      expect(spectators.any((s) => s.hasFlare), isTrue);
      expect(
        spectators.where((s) => s.hasFlare).every(
              (s) =>
                  s.flareColor == CrowdTunnelFlareColor.orange ||
                  s.flareColor == CrowdTunnelFlareColor.red,
            ),
        isTrue,
      );
    });

    test('paint renders 3D crowd tunnel onto Canvas and returns active telemetry', () {
      final AlpineCrowdTunnelRenderer renderer = AlpineCrowdTunnelRenderer();
      final Scene3DMathProjection projection = Scene3DMathProjection(
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
      );
      const RoadGeometryParameters roadGeometry = RoadGeometryParameters(
        gradientPercent: 10.2,
      );
      final Cyclist3DPose camOrigin = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 2490.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 1100.0,
          verticalOffsetMeters: 2.8,
        ),
        roadGeometry: roadGeometry,
      );
      final Cyclist3DPose camTarget = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 2520.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 1103.0,
          verticalOffsetMeters: 1.2,
        ),
        roadGeometry: roadGeometry,
      );
      projection.updateCamera(
        Camera3DConfig(
          position: camOrigin.position,
          target: camTarget.position,
          up: Vector3(0.0, 1.0, 0.0),
        ),
        viewportWidth: 1280.0,
        viewportHeight: 720.0,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final AlpineCrowdTunnelTelemetry telemetry = renderer.paint(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        roadGeometry: roadGeometry,
        cameraCourseDistanceMeters: 2500.0,
        leaderFrontWheelDistanceMeters: 2512.0,
        elapsedSeconds: 3.25,
        elevationAtDistance: (double d) => 1100.0 + (d - 2490.0) * 0.102,
      );
      recorder.endRecording();

      expect(telemetry.isTunnelActive, isTrue);
      expect(telemetry.visibleSpectatorsCount, greaterThan(0));
      expect(telemetry.partingSpectatorsCount, greaterThan(0));
      expect(telemetry.activeCorridorWidthMeters, closeTo(2.8, 0.4));
    });

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'AlpineCrowdTunnelControlPanel renders cleanly at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          AlpineCrowdTunnelConfig currentConfig = const AlpineCrowdTunnelConfig();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    child: AlpineCrowdTunnelControlPanel(
                      config: currentConfig,
                      telemetry: const AlpineCrowdTunnelTelemetry(
                        isTunnelActive: true,
                        currentGradientPercent: 10.4,
                        activeCorridorWidthMeters: 2.8,
                        visibleSpectatorsCount: 148,
                        activeFlagsCount: 24,
                        activeFlaresCount: 9,
                        partingSpectatorsCount: 18,
                      ),
                      onConfigChanged: (AlpineCrowdTunnelConfig next) {
                        currentConfig = next;
                      },
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(find.text('TUNEL KIBICÓW (>8% NACHYLENIA)'), findsOneWidget);
          expect(find.text('2.8 m'), findsOneWidget);
          expect(find.text('10.4%'), findsOneWidget);

          await tester.tap(find.text('Dym z Flar'));
          await tester.pumpAndSettle();
          expect(currentConfig.enableFlareSmoke, isFalse);
        },
      );
    }
  });
}
