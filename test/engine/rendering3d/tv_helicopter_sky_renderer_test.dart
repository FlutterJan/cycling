import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/engine/rendering3d/tv_helicopter_sky_renderer.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('TvHelicopterSkyRenderer', () {
    test('computeState orbits lead group and rotates main and tail rotors', () {
      final renderer = TvHelicopterSkyRenderer();
      final leadPos = Vector3(0.0, 10.0, 100.0);
      final roadTangent = Vector3(0.0, 0.0, 1.0);

      final s0 = renderer.computeState(
        leadRiderWorldPos: leadPos,
        roadTangent: roadTangent,
        elapsedSeconds: 0.0,
      );
      final s1 = renderer.computeState(
        leadRiderWorldPos: leadPos,
        roadTangent: roadTangent,
        elapsedSeconds: 0.05,
      );

      expect(s0.worldPosition.y, greaterThan(leadPos.y + 15.0));
      expect(s0.gimbalTargetWorld, equals(leadPos));
      expect(s1.mainRotorAngleRadians, isNot(equals(s0.mainRotorAngleRadians)));
      expect(s1.tailRotorAngleRadians, isNot(equals(s0.tailRotorAngleRadians)));
      expect(s0.forward.length, closeTo(1.0, 1e-4));
      expect(s0.up.length, closeTo(1.0, 1e-4));
      expect(s0.right.length, closeTo(1.0, 1e-4));
    });

    test('computeRoadShadow projects onto road surface with altitude penumbra', () {
      final renderer = TvHelicopterSkyRenderer();
      final state = renderer.computeState(
        leadRiderWorldPos: Vector3(0.0, 5.0, 50.0),
        roadTangent: Vector3(0.0, 0.0, 1.0),
        elapsedSeconds: 2.0,
      );

      final shadow = renderer.computeRoadShadow(
        state: state,
        roadSurfaceY: 5.0,
      );

      expect(shadow, isNotNull);
      expect(shadow!.shadowCenterWorld.y, closeTo(5.02, 1e-3));
      expect(shadow.penumbraScale, greaterThan(1.0));
      expect(shadow.opacity, inInclusiveRange(0.1, 0.55));
      expect(shadow.mainRotorAngleRadians, equals(state.mainRotorAngleRadians));
    });

    test('computeTreeDownwashSways displaces nearby tree canopies more than distant trees', () {
      final renderer = TvHelicopterSkyRenderer();
      final state = renderer.computeState(
        leadRiderWorldPos: Vector3(0.0, 0.0, 0.0),
        roadTangent: Vector3(0.0, 0.0, 1.0),
        elapsedSeconds: 1.0,
      );

      final nearTree = HelicopterDownwashTreeInput(
        treeId: 'tree_near',
        baseWorldPosition: Vector3(state.worldPosition.x + 5.0, 0.0, state.worldPosition.z + 4.0),
      );
      final farTree = HelicopterDownwashTreeInput(
        treeId: 'tree_far',
        baseWorldPosition: Vector3(state.worldPosition.x + 120.0, 0.0, state.worldPosition.z + 120.0),
      );

      final sways = renderer.computeTreeDownwashSways(
        state: state,
        trees: [nearTree, farTree],
        elapsedSeconds: 1.0,
      );

      expect(sways.length, equals(2));
      expect(sways[0].gustIntensity, greaterThan(0.5));
      expect(sways[0].swayOffsetWorld.length, greaterThan(sways[1].swayOffsetWorld.length));
      expect(sways[1].gustIntensity, equals(0.0));
    });

    test('paint renders helicopter, road shadow, and tree downwash without errors', () {
      final renderer = TvHelicopterSkyRenderer();
      final projection = Scene3DMathProjection(
        viewportWidth: 1280,
        viewportHeight: 720,
      )..updateCamera(
          Camera3DConfig(
            position: Vector3(0.0, 6.0, -25.0),
            target: Vector3(0.0, 12.0, 35.0),
          ),
          viewportWidth: 1280,
          viewportHeight: 720,
        );

      final state = renderer.computeState(
        leadRiderWorldPos: Vector3(0.0, 0.0, 35.0),
        roadTangent: Vector3(0.0, 0.0, 1.0),
        elapsedSeconds: 1.5,
        flightMode: TvHelicopterFlightMode.trackingBreakaway,
      );
      final shadow = renderer.computeRoadShadow(
        state: state,
        roadSurfaceY: 0.0,
      );
      final trees = [
        HelicopterDownwashTreeInput(
          treeId: 't1',
          baseWorldPosition: Vector3(state.worldPosition.x + 6.0, 0.0, state.worldPosition.z),
        ),
      ];

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      renderer.paint(
        canvas: canvas,
        size: const Size(1280, 720),
        projection: projection,
        state: state,
        roadShadow: shadow,
        nearbyTrees: trees,
        elapsedSeconds: 1.5,
      );
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
      picture.dispose();
    });

    for (final viewportSize in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'TvHelicopterTelemetryControlPanel renders without overflow at ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (tester) async {
          TvHelicopterFlightMode selectedMode = TvHelicopterFlightMode.orbitingLeadGroup;
          bool shadowOn = true;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: viewportSize.width,
                  height: viewportSize.height,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TvHelicopterTelemetryControlPanel(
                      currentMode: selectedMode,
                      showRoadShadow: shadowOn,
                      onModeChanged: (mode) => selectedMode = mode,
                      onToggleRoadShadow: (v) => shadowOn = v,
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(find.textContaining('HELIKOPTER TV'), findsOneWidget);
          expect(find.text('Śledzenie ucieczki'), findsOneWidget);
          await tester.tap(find.text('Śledzenie ucieczki'));
          await tester.pumpAndSettle();
          expect(selectedMode, equals(TvHelicopterFlightMode.trackingBreakaway));
        },
      );
    }
  });
}
