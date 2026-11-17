// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/night_riding_headlight_and_stars_3d_renderer.dart';

void main() {
  group('NightRidingHeadlightAndStars3dRenderer', () {
    test('generates deterministic starfield and initial night peloton', () {
      final NightRidingHeadlightAndStars3dRenderer r1 =
          NightRidingHeadlightAndStars3dRenderer(
        config: const NightRiding3dConfig(starCount: 220),
        seed: 520,
      );
      final NightRidingHeadlightAndStars3dRenderer r2 =
          NightRidingHeadlightAndStars3dRenderer(
        config: const NightRiding3dConfig(starCount: 220),
        seed: 520,
      );

      expect(r1.stars.length, 220);
      expect(r1.stars.first.azimuthRadians, r2.stars.first.azimuthRadians);
      expect(r1.stars.first.elevationRadians, r2.stars.first.elevationRadians);
      expect(r1.riders.length, greaterThanOrEqualTo(4));
      expect(r1.reflectors, isNotEmpty);
    });

    test('headlight cone illumination decays with distance and angle', () {
      final NightRidingHeadlightAndStars3dRenderer renderer =
          NightRidingHeadlightAndStars3dRenderer(
        config: const NightRiding3dConfig(
          headlightMode: HeadlightBeamMode.highBeam,
        ),
      );

      final double nearCenter = renderer.evaluateHeadlightIlluminationAt(
        forwardMeters: 12.0,
        lateralMeters: 0.0,
      );
      final double farCenter = renderer.evaluateHeadlightIlluminationAt(
        forwardMeters: 75.0,
        lateralMeters: 0.0,
      );
      final double offAxis = renderer.evaluateHeadlightIlluminationAt(
        forwardMeters: 12.0,
        lateralMeters: 18.0,
      );

      expect(nearCenter, greaterThan(farCenter));
      expect(nearCenter, greaterThan(0.3));
      expect(offAxis, 0.0);

      renderer.updateConfig(
        renderer.config.copyWith(headlightMode: HeadlightBeamMode.off),
      );
      expect(
        renderer.evaluateHeadlightIlluminationAt(
          forwardMeters: 12.0,
          lateralMeters: 0.0,
        ),
        0.0,
      );
    });

    test('battery depletion forces effective headlight off', () {
      final NightRidingHeadlightAndStars3dRenderer renderer =
          NightRidingHeadlightAndStars3dRenderer(
        config: const NightRiding3dConfig(
          headlightMode: HeadlightBeamMode.highBeam,
        ),
      );

      expect(renderer.effectiveHeadlightMode, HeadlightBeamMode.highBeam);
      renderer.setBatteryPercent(0.0);
      expect(renderer.effectiveHeadlightMode, HeadlightBeamMode.off);
      expect(renderer.latestTelemetry.activeHeadlightLumens, 0);
    });

    test('3D projection works across all camera modes and advances frame', () {
      final NightRidingHeadlightAndStars3dRenderer renderer =
          NightRidingHeadlightAndStars3dRenderer();

      for (final NightCameraViewMode cam in NightCameraViewMode.values) {
        renderer.updateConfig(renderer.config.copyWith(cameraMode: cam));
        final ProjectedNightPoint3D? pt = renderer.projectRoadRelativePoint(
          forwardMeters: 15.0,
          lateralMeters: 0.0,
          heightMeters: 0.5,
          viewportSize: const Size(1280, 720),
        );
        expect(pt, isNotNull);
        expect(pt!.depthMeters, greaterThan(0.0));
      }

      final double initialDist = renderer.cameraDistanceMeters;
      renderer.advanceFrame(0.1, speedMs: 10.0);
      expect(renderer.cameraDistanceMeters, closeTo(initialDist + 1.0, 0.001));
    });

    test('taillight pulse factors respond to all modes', () {
      final NightRidingHeadlightAndStars3dRenderer renderer =
          NightRidingHeadlightAndStars3dRenderer();

      expect(
        renderer.computeTaillightPulseFactor(TaillightPulseMode.off, 0.0),
        0.0,
      );
      expect(
        renderer.computeTaillightPulseFactor(TaillightPulseMode.steady, 0.0),
        greaterThan(0.8),
      );
      expect(
        renderer.computeTaillightPulseFactor(
            TaillightPulseMode.pelotonPulse, 0.0),
        inInclusiveRange(0.4, 1.0),
      );
      expect(
        renderer.computeTaillightPulseFactor(
            TaillightPulseMode.radarAlert, 0.0),
        inInclusiveRange(0.1, 1.0),
      );
    });
  });

  group('NightRidingHeadlightAndStars3dViewportWidget', () {
    for (final Size viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(viewportSize);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NightRidingHeadlightAndStars3dViewportWidget(
                    autoAnimate: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Jazda Nocna 3D • LED & Gwiazdy'), findsOneWidget);

          // Interakcja: przełączenie trybu lampki i bioma
          await tester.tap(find.text('EKO'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('350 lm'), findsOneWidget);

          await tester.tap(find.text('RADAR'));
          await tester.pump(const Duration(milliseconds: 250));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
