// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/gravel_white_roads_and_dust_3d_renderer.dart';

void main() {
  group('GravelWhiteRoadsAndDust3dRenderer', () {
    test('renderuje białe drogi Sterrato, kolarzy i gęste chmury pyłu', () {
      const renderer = GravelWhiteRoadsAndDust3dRenderer();
      const animator = RoadsideTireRepairAnimator();
      const config = GravelRoad3dConfig(
        biomePreset: GravelRoadBiomePreset.tuscanySterrato,
        dustDensity: 0.90,
      );

      final repairState = animator.evaluate(
        isRepairActive: true,
        normalizedProgress: 0.55,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final telemetry = renderer.paintScene(
        canvas: canvas,
        size: const Size(1280, 720),
        cameraDistanceMeters: 24.0,
        simulationTimeSeconds: 3.5,
        config: config,
        repairState: repairState,
      );
      recorder.endRecording();

      expect(telemetry.roadSegmentsRendered, greaterThan(20));
      expect(telemetry.ridersRendered, greaterThanOrEqualTo(10));
      expect(telemetry.dustParticlesRendered, greaterThan(30));
      expect(telemetry.sceneryPropsRendered, greaterThan(6));
      expect(telemetry.currentDustVisibilityPenalty, greaterThan(0.4));
      expect(
        telemetry.repairPhase,
        RoadsideTireRepairPhase.plugAndCo2Inflation,
      );
    });

    test('obsługuje pustynne prerie i zerową gęstość pyłu', () {
      const renderer = GravelWhiteRoadsAndDust3dRenderer();
      const config = GravelRoad3dConfig(
        biomePreset: GravelRoadBiomePreset.kansasFlintHills,
        dustDensity: 0.0,
        showDustClouds: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final telemetry = renderer.paintScene(
        canvas: canvas,
        size: const Size(1024, 768),
        cameraDistanceMeters: 10.0,
        simulationTimeSeconds: 1.0,
        config: config,
        repairState: RoadsideTireRepairState.inactive(),
      );
      recorder.endRecording();

      expect(telemetry.dustParticlesRendered, 0);
      expect(telemetry.currentDustVisibilityPenalty, 0.0);
      expect(telemetry.currentCrrMultiplier, greaterThan(1.5));
    });

    test('RoadsideTireRepairAnimator przechodzi przez wszystkie fazy naprawy CO2', () {
      const animator = RoadsideTireRepairAnimator();

      final s0 = animator.evaluate(isRepairActive: false, normalizedProgress: 0.5);
      expect(s0.isRepairActive, isFalse);
      expect(s0.phase, RoadsideTireRepairPhase.ridingNormally);

      final s1 = animator.evaluate(isRepairActive: true, normalizedProgress: 0.08);
      expect(s1.phase, RoadsideTireRepairPhase.pullingOverToShoulder);

      final s2 = animator.evaluate(isRepairActive: true, normalizedProgress: 0.28);
      expect(s2.phase, RoadsideTireRepairPhase.dismountAndWheelRemoval);
      expect(s2.wheelDetachedOffsetMeters, greaterThan(0.0));

      final s3 = animator.evaluate(isRepairActive: true, normalizedProgress: 0.62);
      expect(s3.phase, RoadsideTireRepairPhase.plugAndCo2Inflation);
      expect(s3.co2JetIntensity, greaterThan(0.0));

      final s4 = animator.evaluate(isRepairActive: true, normalizedProgress: 0.92);
      expect(s4.phase, RoadsideTireRepairPhase.remountAndChaseBack);
      expect(s4.tirePressureBar, closeTo(2.60, 0.01));
    });
  });

  group('GravelWhiteRoadsAndDust3dViewportWidget (Responsywność)', () {
    for (final viewportSize in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnienia w ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(viewportSize);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: GravelWhiteRoadsAndDust3dViewportWidget(),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Sterrato & Prerie 3D'), findsOneWidget);
          expect(find.text('PRERIA'), findsOneWidget);

          await tester.tap(find.text('PRERIA'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.textContaining('Kansas — Pustynne Prerie'),
            findsOneWidget,
          );
        },
      );
    }
  });
}
