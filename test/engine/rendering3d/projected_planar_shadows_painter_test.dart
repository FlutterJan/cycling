// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/dynamic_skybox_and_lighting_painter.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_3d_canvas_engine.dart';
import 'package:pro_peloton_manager/engine/rendering3d/projected_planar_shadows_painter.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('ProjectedPlanarShadowsPainter - Solar Angle & Slope Exposure', () {
    test('sun elevation peaks around midday and drops toward 17:30 Golden Hour', () {
      final morningState = ProjectedPlanarShadowsPainter.computeSunProjectionState(
        timeOfDay: const StageTimeOfDay(hour: 11, minute: 0),
        weatherCondition: WeatherCondition.sunny,
      );
      final middayState = ProjectedPlanarShadowsPainter.computeSunProjectionState(
        timeOfDay: const StageTimeOfDay(hour: 13, minute: 15),
        weatherCondition: WeatherCondition.sunny,
      );
      final lateAfternoonState = ProjectedPlanarShadowsPainter.computeSunProjectionState(
        timeOfDay: const StageTimeOfDay(hour: 17, minute: 30),
        weatherCondition: WeatherCondition.sunny,
      );

      expect(middayState.sunElevationRadians, greaterThan(morningState.sunElevationRadians));
      expect(middayState.sunElevationRadians, greaterThan(lateAfternoonState.sunElevationRadians));
      expect(lateAfternoonState.sunAzimuthRadians, greaterThan(morningState.sunAzimuthRadians));
      expect(
        lateAfternoonState.penumbraSpreadPerMeter,
        greaterThan(middayState.penumbraSpreadPerMeter),
      );
    });

    test('shaded north slope produces softer and lower-contrast shadows than sunny south slope', () {
      final southState = ProjectedPlanarShadowsPainter.computeSunProjectionState(
        timeOfDay: const StageTimeOfDay(hour: 14, minute: 30),
        weatherCondition: WeatherCondition.sunny,
        slopeExposure: const SlopeExposureProfile.sunnySouthAspect(gradientPercent: 8.5),
      );
      final northState = ProjectedPlanarShadowsPainter.computeSunProjectionState(
        timeOfDay: const StageTimeOfDay(hour: 14, minute: 30),
        weatherCondition: WeatherCondition.sunny,
        slopeExposure: const SlopeExposureProfile.shadedNorthAspect(gradientPercent: 8.5),
      );

      expect(southState.slopeIncidenceFactor, greaterThan(northState.slopeIncidenceFactor));
      expect(southState.umbraOpacity, greaterThan(northState.umbraOpacity));
      expect(northState.penumbraSpreadPerMeter, greaterThan(southState.penumbraSpreadPerMeter));
    });

    test('projectWorldPointOntoAsphaltPlane projects onto tilted road plane and clamps stretch', () {
      final planeOrigin = Vector3(0.0, 100.0, 20.0);
      final planeNormal = ProjectedPlanarShadowsPainter.resolveAsphaltPlaneNormal(
        roadTangent: Vector3(0.0, 0.0, 1.0),
        roadNormal: Vector3(0.0, 1.0, 0.0),
        roadGradientPercent: 10.0,
        slopeExposure: const SlopeExposureProfile(gradientPercent: 10.0, crossSlopePercent: 3.0),
      );

      final sunState = ProjectedPlanarShadowsPainter.computeSunProjectionState(
        timeOfDay: const StageTimeOfDay(hour: 17, minute: 30),
        weatherCondition: WeatherCondition.sunny,
      );

      final headPoint = planeOrigin + (planeNormal * 1.5);
      final projected = ProjectedPlanarShadowsPainter.projectWorldPointOntoAsphaltPlane(
        worldPoint: headPoint,
        planeOrigin: planeOrigin,
        planeNormal: planeNormal,
        sunDirectionWorld: sunState.sunDirectionWorld,
        maxStretchMultiplier: 4.5,
      );

      // Odległość od płaszczyzny asfaltu powinna wynosić ~0.006 m (anty-z-fighting).
      final distFromPlane = (projected - planeOrigin).dot(planeNormal);
      expect(distFromPlane, closeTo(0.006, 0.01));

      // Długość cienia powinna być większa niż 0 i ograniczona przez maxStretchMultiplier.
      final shadowLen = (projected - planeOrigin).length;
      expect(shadowLen, greaterThan(0.5));
      expect(shadowLen, lessThanOrEqualTo(1.5 * 4.5 + 0.1));
    });

    test('adapter factories build valid inputs from Peloton3d models', () {
      final roadNode = Peloton3dRoadNode(
        distanceMeters: 1000.0,
        center: Vector3(0.0, 0.0, 25.0),
        tangent: Vector3(0.0, 0.0, 1.0),
        right: Vector3(1.0, 0.0, 0.0),
        normal: Vector3(0.0, 1.0, 0.0),
        roadWidthMeters: 7.2,
        gradientPercent: 6.0,
        curvature: 0.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
      );

      const riderData = Peloton3dRiderRenderData(
        riderId: 'r1',
        riderName: 'Tadej P.',
        bibNumber: 1,
        jerseyColor: Color(0xFFD4AF37),
        frameColor: Color(0xFF181B22),
        distanceMeters: 1000.0,
        lateralOffsetMeters: 0.5,
        speedMs: 11.2,
        powerWatts: 410,
        cadenceRpm: 92,
        leanAngleRad: 0.12,
        isStanding: true,
      );

      final riderInput = PlanarShadowRiderInput.fromPeloton3d(
        rider: riderData,
        roadNode: roadNode,
        isSelected: true,
      );
      expect(riderInput.riderId, 'r1');
      expect(riderInput.isStanding, isTrue);
      expect(riderInput.isSelected, isTrue);
      expect(riderInput.roadGradientPercent, 6.0);

      final treeProp = Peloton3dSceneryProp(
        id: 'tree_1',
        type: Peloton3dPropType.pineTree,
        distanceMeters: 1015.0,
        position: Vector3(-5.0, 0.0, 30.0),
        tangent: Vector3(0.0, 0.0, 1.0),
        right: Vector3(1.0, 0.0, 0.0),
        normal: Vector3(0.0, 1.0, 0.0),
        scale: 1.2,
      );
      final treeInput = PlanarShadowTreeInput.fromSceneryProp(prop: treeProp);
      expect(treeInput.species, PlanarTreeSpecies.pine);
      expect(treeInput.heightMeters, closeTo(9.5 * 1.2, 0.001));

      final gateProp = Peloton3dSceneryProp(
        id: 'gate_flamme',
        type: Peloton3dPropType.flammeRougeGate,
        distanceMeters: 1030.0,
        position: Vector3(0.0, 0.0, 45.0),
        tangent: Vector3(0.0, 0.0, 1.0),
        right: Vector3(1.0, 0.0, 0.0),
        normal: Vector3(0.0, 1.0, 0.0),
      );
      final gateInput = PlanarShadowGateInput.fromSceneryProp(gateProp);
      expect(gateInput.kind, PlanarGateKind.flammeRougeGate);
      expect(gateInput.spanWidthMeters, closeTo(8.4, 0.001));
    });
  });

  group('ProjectedPlanarShadowsPainter - Canvas Rendering', () {
    for (final viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders riders, bikes, trees and gates cleanly at ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          final projection = Scene3DMathProjection(
            viewportWidth: viewportSize.width,
            viewportHeight: viewportSize.height,
          );

          final painter = ProjectedPlanarShadowsPainter(
            projection: projection,
            timeOfDay: const StageTimeOfDay(hour: 16, minute: 45),
            weatherCondition: WeatherCondition.sunny,
            slopeExposure: const SlopeExposureProfile(
              gradientPercent: 7.5,
              crossSlopePercent: 2.0,
              slopeAspectRadians: math.pi * 0.75,
            ),
            riders: [
              PlanarShadowRiderInput(
                riderId: 'r1',
                baseWorldPosition: Vector3(0.0, 0.0, 12.0),
                roadTangent: Vector3(0.0, 0.0, 1.0),
                roadRight: Vector3(1.0, 0.0, 0.0),
                roadNormal: Vector3(0.0, 1.0, 0.0),
                leanAngleRadians: 0.15,
                isStanding: true,
                isSelected: true,
                roadGradientPercent: 7.5,
              ),
              PlanarShadowRiderInput(
                riderId: 'r2',
                baseWorldPosition: Vector3(-1.4, 0.0, 16.0),
                roadTangent: Vector3(0.0, 0.0, 1.0),
                roadRight: Vector3(1.0, 0.0, 0.0),
                roadNormal: Vector3(0.0, 1.0, 0.0),
                isAeroTuck: true,
                roadGradientPercent: 7.5,
              ),
            ],
            trees: [
              PlanarShadowTreeInput(
                id: 't_pine',
                species: PlanarTreeSpecies.pine,
                baseWorldPosition: Vector3(-6.0, 0.0, 22.0),
                roadPlaneOrigin: Vector3(0.0, 0.0, 22.0),
                roadNormal: Vector3(0.0, 1.0, 0.0),
                roadTangent: Vector3(0.0, 0.0, 1.0),
                roadRight: Vector3(1.0, 0.0, 0.0),
              ),
              PlanarShadowTreeInput(
                id: 't_decid',
                species: PlanarTreeSpecies.deciduous,
                baseWorldPosition: Vector3(6.5, 0.0, 28.0),
                roadPlaneOrigin: Vector3(0.0, 0.0, 28.0),
                roadNormal: Vector3(0.0, 1.0, 0.0),
                roadTangent: Vector3(0.0, 0.0, 1.0),
                roadRight: Vector3(1.0, 0.0, 0.0),
              ),
              PlanarShadowTreeInput(
                id: 't_cypress',
                species: PlanarTreeSpecies.cypress,
                baseWorldPosition: Vector3(-5.5, 0.0, 34.0),
                roadPlaneOrigin: Vector3(0.0, 0.0, 34.0),
                roadNormal: Vector3(0.0, 1.0, 0.0),
                roadTangent: Vector3(0.0, 0.0, 1.0),
                roadRight: Vector3(1.0, 0.0, 0.0),
              ),
            ],
            gates: [
              PlanarShadowGateInput(
                id: 'g_finish',
                kind: PlanarGateKind.finishGantry,
                centerWorldPosition: Vector3(0.0, 0.0, 40.0),
                roadTangent: Vector3(0.0, 0.0, 1.0),
                roadRight: Vector3(1.0, 0.0, 0.0),
                roadNormal: Vector3(0.0, 1.0, 0.0),
              ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: viewportSize.width,
                    height: viewportSize.height,
                    child: CustomPaint(painter: painter),
                  ),
                ),
              ),
            ),
          );

          expect(find.byType(CustomPaint), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
