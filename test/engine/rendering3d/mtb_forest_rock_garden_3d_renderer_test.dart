import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/mtb_forest_rock_garden_3d_renderer.dart';
import 'package:pro_peloton_manager/models/race/mtb_xco_course_and_suspension_model.dart';

void main() {
  group('MtbForestRockGarden3dRenderer', () {
    const MtbForestRockGarden3dRenderer renderer =
        MtbForestRockGarden3dRenderer();

    test('sampleTrailAt deterministically cycles MTB XCO features', () {
      final MtbTrailSegmentSample3D rockSample = renderer.sampleTrailAt(24.0);
      final MtbTrailSegmentSample3D bridgeSample = renderer.sampleTrailAt(85.0);
      final MtbTrailSegmentSample3D jumpSample = renderer.sampleTrailAt(145.0);

      expect(rockSample.featureType, MtbXcoFeatureType.rockGarden);
      expect(bridgeSample.featureType, MtbXcoFeatureType.woodBridge);
      expect(jumpSample.featureType, MtbXcoFeatureType.pumpRollers);
    });

    test('generates boulders, wooden bridges, and jumps in visible range', () {
      final List<MtbRockGardenBoulder3D> boulders =
          renderer.generateVisibleBoulders(
        minDistanceMeters: 0.0,
        maxDistanceMeters: 180.0,
      );
      final List<MtbWoodenBridge3D> bridges =
          renderer.generateVisibleBridges(
        minDistanceMeters: 0.0,
        maxDistanceMeters: 180.0,
      );
      final List<MtbTrailJumpRamp3D> jumps = renderer.generateVisibleJumps(
        minDistanceMeters: 0.0,
        maxDistanceMeters: 180.0,
      );

      expect(boulders, isNotEmpty);
      expect(bridges, isNotEmpty);
      expect(jumps, isNotEmpty);
    });

    test('renderFrame draws 3D scene and reports accurate telemetry', () {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final MtbForestRockGardenTelemetry telemetry = renderer.renderFrame(
        canvas: canvas,
        size: const Size(1280, 720),
        leaderDistanceMeters: 20.0,
        simulationTimeSeconds: 1.5,
        config: const MtbForestRockGarden3dConfig(),
      );

      recorder.endRecording().dispose();

      expect(telemetry.visibleTrailSlices, greaterThan(10));
      expect(telemetry.visibleBoulders, greaterThan(0));
      expect(telemetry.visibleBridges, greaterThan(0));
      expect(telemetry.visibleJumps, greaterThan(0));
      expect(telemetry.visibleTrees, greaterThan(0));
      expect(telemetry.activeSunbeams, greaterThan(0));
      expect(telemetry.activeDustMotes, greaterThan(0));
      expect(telemetry.activeRiders, greaterThanOrEqualTo(2));
    });
  });

  group('MtbForestRockGarden3dViewportWidget', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MtbForestRockGarden3dViewportWidget(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 (mobile)', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('MTB XCO Las & Rock Garden 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 (tablet)', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('MTB XCO Las & Rock Garden 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 (desktop) and switches presets',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('NOVÉ MĚSTO'), findsOneWidget);

      await tester.tap(find.text('LES GETS'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('ROCKS'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('B-Line (Objazd)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
