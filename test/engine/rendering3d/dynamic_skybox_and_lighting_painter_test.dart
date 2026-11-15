import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/dynamic_skybox_and_lighting_painter.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/engine/rendering3d/support_vehicles_3d_renderer.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('StageTimeOfDay & SunLightState', () {
    test('presets map to expected lighting phases', () {
      const morning = StageTimeOfDay.morningStart();
      expect(morning.formatted, '11:30');
      expect(morning.phase, StageLightingPhase.midday);
      expect(morning.areStreetlampsActive, isFalse);

      const golden = StageTimeOfDay.alpineGoldenHour();
      expect(golden.formatted, '17:15');
      expect(golden.phase, StageLightingPhase.goldenHour);
      expect(golden.areStreetlampsActive, isFalse);

      const paris = StageTimeOfDay.parisEveningCriterium();
      expect(paris.formatted, '20:45');
      expect(paris.phase, StageLightingPhase.nightCriterium);
      expect(paris.areStreetlampsActive, isTrue);
    });

    test('Golden Hour has lower sun elevation and longer shadows than midday', () {
      final midday = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: const StageTimeOfDay.morningStart(),
        weatherCondition: WeatherCondition.sunny,
      );
      final golden = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: const StageTimeOfDay.alpineGoldenHour(),
        weatherCondition: WeatherCondition.sunny,
      );

      expect(golden.sunElevationRadians, lessThan(midday.sunElevationRadians));
      expect(golden.shadowLengthMultiplier, greaterThan(midday.shadowLengthMultiplier));
      expect(midday.isWetSurface, isFalse);
    });

    test('heavyStorm enables wet surface and periodic lightning flashes', () {
      final stormFlash = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: const StageTimeOfDay.morningStart(),
        weatherCondition: WeatherCondition.heavyStorm,
        elapsedSeconds: 0.05,
      );
      final stormCalm = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: const StageTimeOfDay.morningStart(),
        weatherCondition: WeatherCondition.heavyStorm,
        elapsedSeconds: 1.5,
      );

      expect(stormFlash.isWetSurface, isTrue);
      expect(stormFlash.lightningFlashIntensity, greaterThan(0.5));
      expect(stormCalm.lightningFlashIntensity, 0.0);
    });
  });

  group('Projected Drop Shadows', () {
    test('low sun and road gradient affect shadow length', () {
      final midday = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: const StageTimeOfDay.morningStart(),
        weatherCondition: WeatherCondition.sunny,
      );
      final golden = DynamicSkyboxAndLightingPainter.computeSunLightState(
        timeOfDay: const StageTimeOfDay.alpineGoldenHour(),
        weatherCondition: WeatherCondition.sunny,
      );

      final flatMidday = DynamicSkyboxAndLightingPainter.computeProjectedShadowGeometry(
        riderBaseWorld: Vector3(0.0, 0.0, 10.0),
        roadTangent: Vector3(0.0, 0.0, 1.0),
        roadNormal: Vector3(0.0, 1.0, 0.0),
        sunState: midday,
        roadGradientPercent: 0.0,
      );
      final flatGolden = DynamicSkyboxAndLightingPainter.computeProjectedShadowGeometry(
        riderBaseWorld: Vector3(0.0, 0.0, 10.0),
        roadTangent: Vector3(0.0, 0.0, 1.0),
        roadNormal: Vector3(0.0, 1.0, 0.0),
        sunState: golden,
        roadGradientPercent: 0.0,
      );
      final steepGolden = DynamicSkyboxAndLightingPainter.computeProjectedShadowGeometry(
        riderBaseWorld: Vector3(0.0, 0.0, 10.0),
        roadTangent: Vector3(0.0, 0.12, 0.99)..normalize(),
        roadNormal: Vector3(0.0, 1.0, 0.0),
        sunState: golden,
        roadGradientPercent: 12.0,
      );

      expect(flatGolden.projectedLengthMeters, greaterThan(flatMidday.projectedLengthMeters));
      expect(
        (steepGolden.projectedLengthMeters - flatGolden.projectedLengthMeters).abs(),
        greaterThan(0.05),
      );
    });
  });

  group('Canvas rendering & wet road specular reflections', () {
    test('paints skybox, shadows, and wet reflections across all viewport sizes', () {
      final projection = Scene3DMathProjection();
      final sizes = [
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      const riderSnapshot = RiderPositionSnapshot(
        riderId: 'r1',
        riderName: 'Tadej Test',
        bibNumber: 1,
        teamId: 't1',
        teamName: 'Test Team',
        teamJerseyHexColor: '#D4AF37',
        isPlayerRider: true,
        distanceCoveredMeters: 12.0,
        kilometerMark: 0.012,
        elevationMeters: 450.0,
        currentGradientPercent: 0.0,
        currentSegmentIndex: 0,
        speedMs: 11.67,
        speedKmh: 42.0,
        powerWatts: 380,
        wattsPerKg: 5.8,
        cadenceRpm: 92,
        heartRateBpm: 168,
        wPrimePercentage: 88.0,
        wPrimeJoules: 18000.0,
        glycogenPercentage: 95.0,
        glycogenGrams: 480.0,
        hydrationPercent: 98.0,
        bidonsLeft: 2,
        gelsLeft: 4,
        activeTacticalOrder: TacticalOrder.holdPosition,
        groupIndex: 0,
        groupType: GroupType.peloton,
        timeGapToLeaderSeconds: 0.0,
        lateralPositionRoad: 0.0,
        lateralOffsetRoadMeters: 0.0,
        isDrafting: true,
        draftingSavingsPercent: 25.0,
        isPulling: false,
      );

      for (final size in sizes) {
        projection.updateCamera(
          Camera3DConfig(
            position: Vector3(0.0, 3.2, 0.0),
            target: Vector3(0.0, 1.2, 20.0),
            fovYDegrees: 58.0,
          ),
          viewportWidth: size.width,
          viewportHeight: size.height,
        );

        final worldPos = Vector3(0.0, 0.0, 12.0);
        final projPt = projection.worldToScreen(worldPos);
        final item = PelotonRenderItem(
          snapshot: riderSnapshot,
          worldPosition: worldPos,
          tangent: Vector3(0.0, 0.0, 1.0),
          right: Vector3(1.0, 0.0, 0.0),
          up: Vector3(0.0, 1.0, 0.0),
          cameraDistance: 12.0,
          lodLevel: PelotonLodLevel.fullDetail,
          projectedCenter: projPt,
          screenScale: projPt.perspectiveScale,
          isVisibleInFrustum: true,
          jerseyColor: const Color(0xFFD4AF37),
        );

        final teamCar = SupportVehicleInstance3D(
          id: 'car_1',
          type: SupportVehicleType.teamCar,
          primaryColor: const Color(0xFF8E4A49),
          worldPosition: Vector3(-1.5, 0.0, 18.0),
          tangent: Vector3(0.0, 0.0, 1.0),
          lateralRight: Vector3(1.0, 0.0, 0.0),
          surfaceNormal: Vector3(0.0, 1.0, 0.0),
          distanceAlongCourseMeters: 18.0,
          lateralOffsetMeters: -1.5,
          speedKmh: 42.0,
          isBeaconFlashing: true,
        );

        final painter = DynamicSkyboxAndLightingPainter(
          timeOfDay: const StageTimeOfDay.alpineGoldenHour(),
          weatherCondition: WeatherCondition.heavyStorm,
          elapsedSeconds: 0.05,
          projection: projection,
          pelotonRenderItems: [item],
          supportVehicles: [teamCar],
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      }
    });
  });
}
