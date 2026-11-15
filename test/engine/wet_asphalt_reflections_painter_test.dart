// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_3d_canvas_engine.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/engine/rendering3d/wet_asphalt_reflections_painter.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  List<Peloton3dRoadNode> buildStraightRoad({
    int count = 30,
    double stepMeters = 5.0,
    double gradientPercent = 0.0,
    SegmentSurfaceType surfaceType = SegmentSurfaceType.smoothAsphalt,
  }) {
    final List<Peloton3dRoadNode> nodes = <Peloton3dRoadNode>[];
    for (int i = 0; i < count; i++) {
      final double d = i * stepMeters;
      final double y = d * (gradientPercent / 100.0);
      nodes.add(
        Peloton3dRoadNode(
          distanceMeters: d,
          center: Vector3(0.0, y, d),
          tangent: Vector3(0.0, gradientPercent / 100.0, 1.0).normalized(),
          right: Vector3(1.0, 0.0, 0.0),
          normal: Vector3(0.0, 1.0, 0.0),
          roadWidthMeters: 7.2,
          gradientPercent: gradientPercent,
          curvature: 0.0,
          surfaceType: surfaceType,
        ),
      );
    }
    return nodes;
  }

  Scene3DMathProjection buildProjection(Size size) {
    final Scene3DMathProjection projection = Scene3DMathProjection(
      viewportWidth: size.width,
      viewportHeight: size.height,
      fovYDegrees: 58.0,
    );
    projection.setView(
      eye: Vector3(0.0, 3.2, -8.0),
      target: Vector3(0.0, 1.0, 28.0),
      up: Vector3(0.0, 1.0, 0.0),
    );
    return projection;
  }

  List<WetAsphaltRiderReflectionInput> buildRiders(List<Peloton3dRoadNode> nodes) {
    return [
      WetAsphaltRiderReflectionInput(
        riderId: 'r1',
        baseWorldPosition: nodes[5].center + nodes[5].right * 0.6,
        roadTangent: nodes[5].tangent,
        roadRight: nodes[5].right,
        roadNormal: nodes[5].normal,
        jerseyColor: const Color(0xFF38BDF8),
        leaderJersey: LeaderJerseyType.yellow,
        lateralOffsetMeters: 0.6,
        distanceMeters: nodes[5].distanceMeters,
        speedMs: 13.5,
      ),
      WetAsphaltRiderReflectionInput(
        riderId: 'r2',
        baseWorldPosition: nodes[7].center - nodes[7].right * 1.1,
        roadTangent: nodes[7].tangent,
        roadRight: nodes[7].right,
        roadNormal: nodes[7].normal,
        jerseyColor: const Color(0xFFEF4444),
        leaderJersey: LeaderJerseyType.rainbow,
        lateralOffsetMeters: -1.1,
        distanceMeters: nodes[7].distanceMeters,
        speedMs: 12.8,
      ),
    ];
  }

  group('WetAsphaltReflectionsPainter', () {
    test('skips all rendering when road is completely dry', () {
      const Size size = Size(1024, 768);
      final projection = buildProjection(size);
      final road = buildStraightRoad();
      final riders = buildRiders(road);

      final painter = WetAsphaltReflectionsPainter(
        projection: projection,
        roadNodes: road,
        riders: riders,
        surfaceState: WetAsphaltSurfaceState.dry(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      recorder.endRecording();

      expect(painter.lastTelemetry.darkenedRoadQuads, 0);
      expect(painter.lastTelemetry.puddlesRendered, 0);
      expect(painter.lastTelemetry.riderReflectionsRendered, 0);
      expect(painter.lastTelemetry.dryRutSegmentsRendered, 0);
    });

    test('renders darkened asphalt, puddles, dry ruts and rider reflections on wet road', () {
      const Size size = Size(1280, 720);
      final projection = buildProjection(size);
      final road = buildStraightRoad(count: 35);
      final riders = buildRiders(road);

      final painter = WetAsphaltReflectionsPainter(
        projection: projection,
        roadNodes: road,
        riders: riders,
        surfaceState: WetAsphaltSurfaceState(
          wetness: 0.9,
          rainIntensity: 0.8,
          animationTimeSeconds: 2.5,
          sunDirection: Vector3(0.3, 0.85, 0.4).normalized(),
        ),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      recorder.endRecording();

      expect(painter.lastTelemetry.darkenedRoadQuads, greaterThan(0));
      expect(painter.lastTelemetry.puddlesRendered, greaterThan(0));
      expect(painter.lastTelemetry.riderReflectionsRendered, greaterThan(0));
      expect(painter.lastTelemetry.dryRutSegmentsRendered, greaterThan(0));
      expect(painter.lastTelemetry.effectiveWetness, closeTo(0.9, 0.001));
    });

    test('steep climb drains puddles faster than flat road', () {
      final flatRoad = buildStraightRoad(count: 40, gradientPercent: 0.0);
      final steepRoad = buildStraightRoad(count: 40, gradientPercent: 10.0);

      final flatPuddles = WetAsphaltReflectionsPainter.generatePuddlesForRoadNodes(
        roadNodes: flatRoad,
        wetness: 0.85,
      );
      final steepPuddles = WetAsphaltReflectionsPainter.generatePuddlesForRoadNodes(
        roadNodes: steepRoad,
        wetness: 0.85,
      );

      expect(flatPuddles.length, greaterThanOrEqualTo(steepPuddles.length));
    });

    test('PelotonTireRutTracker accumulates dry lanes and rewets in rain', () {
      final road = buildStraightRoad(count: 20);
      final riders = buildRiders(road);
      final tracker = PelotonTireRutTracker();

      for (int i = 0; i < 6; i++) {
        tracker.update(
          deltaSeconds: 0.5,
          riders: riders,
          rainIntensity: 0.1,
          wetness: 0.8,
        );
      }

      final activeTracks = tracker.buildActiveTracks(
        startDistanceMeters: 0.0,
        endDistanceMeters: 80.0,
      );
      expect(activeTracks, isNotEmpty);

      // Brak kolarzy w ulewnym deszczu powoduje ponowne zamakanie kolein.
      for (int i = 0; i < 30; i++) {
        tracker.update(
          deltaSeconds: 0.5,
          riders: const [],
          rainIntensity: 1.0,
          wetness: 0.9,
        );
      }
      final rewettedTracks = tracker.buildActiveTracks(
        startDistanceMeters: 0.0,
        endDistanceMeters: 80.0,
      );
      expect(rewettedTracks, isEmpty);
    });
  });

  group('WetAsphaltReflectionsControlPanel responsive UI', () {
    for (final testSize in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${testSize.width.toInt()}x${testSize.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = testSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        WetAsphaltReflectionsConfig currentConfig = const WetAsphaltReflectionsConfig();
        double currentWetness = 0.75;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0F1115),
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: testSize.width < 500 ? testSize.width - 24 : 360,
                  child: WetAsphaltReflectionsControlPanel(
                    surfaceState: WetAsphaltSurfaceState(
                      wetness: currentWetness,
                      rainIntensity: 0.5,
                      sunDirection: Vector3(0.3, 0.8, 0.4).normalized(),
                    ),
                    config: currentConfig,
                    telemetry: const WetAsphaltTelemetry(
                      darkenedRoadQuads: 24,
                      puddlesRendered: 8,
                      riderReflectionsRendered: 14,
                      dryRutSegmentsRendered: 32,
                      effectiveWetness: 0.75,
                    ),
                    onConfigChanged: (cfg) => currentConfig = cfg,
                    onWetnessChanged: (val) => currentWetness = val,
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Mokry Asfalt i Odbicia 3D'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
