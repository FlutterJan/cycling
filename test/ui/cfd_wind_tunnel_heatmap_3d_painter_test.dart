// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/real_time_cfd_vortex_and_drag_solver.dart';
import 'package:pro_peloton_manager/ui/widgets/cfd_wind_tunnel_heatmap_3d_painter.dart';

void main() {
  group('CfdWindTunnelHeatmapCalculator unit tests', () {
    test('projectPoint3d projects 3D coordinates into finite canvas bounds', () {
      const Size canvasSize = Size(800, 420);
      final CfdProjectedPoint3d front = CfdWindTunnelHeatmapCalculator.projectPoint3d(
        x: 0.56,
        y: 0.34,
        z: 0.0,
        canvasSize: canvasSize,
        cameraYawDeg: 0.0,
        cameraPitchDeg: 6.0,
        zoom: 1.0,
      );
      final CfdProjectedPoint3d rear = CfdWindTunnelHeatmapCalculator.projectPoint3d(
        x: -0.52,
        y: 0.34,
        z: 0.0,
        canvasSize: canvasSize,
        cameraYawDeg: 0.0,
        cameraPitchDeg: 6.0,
        zoom: 1.0,
      );

      expect(front.offset.dx, greaterThan(rear.offset.dx));
      expect(front.offset.dx.isFinite, isTrue);
      expect(front.offset.dy.isFinite, isTrue);
      expect(front.depth, greaterThan(0));
    });

    test('heatmapColorForNormalized returns valid colors across all layer modes', () {
      for (final CfdHeatmapLayerMode mode in CfdHeatmapLayerMode.values) {
        final Color low = CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(-0.2, mode: mode);
        final Color mid = CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(0.5, mode: mode);
        final Color high = CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(1.3, mode: mode);
        expect(low.a, closeTo(1.0, 0.01));
        expect(mid.a, closeTo(1.0, 0.01));
        expect(high.a, closeTo(1.0, 0.01));
        expect(low, isNot(equals(high)));
      }
    });

    test('buildProjectedZoneHitboxes & hitTestProbe detect CFD zones', () {
      const CfdSolverInput input = CfdSolverInput(
        groundSpeedKmh: 50.0,
        crosswindKmh: 10.0,
        helmetType: CfdHelmetType.ttShortTail,
        forearmPosture: CfdForearmPosture.ttAeroBars,
      );
      final CfdSolverResult result = RealTimeCfdVortexAndDragSolver.solveFrame(input);

      final List<CfdProjectedZoneHitbox> hitboxes =
          CfdWindTunnelHeatmapCalculator.buildProjectedZoneHitboxes(
        canvasSize: const Size(720, 360),
        input: input,
        solverResult: result,
        cameraYawDeg: 0.0,
        cameraPitchDeg: 8.0,
        zoom: 1.0,
      );

      expect(hitboxes.length, equals(CfdAeroZone.values.length));

      final CfdProjectedZoneHitbox helmetBox =
          hitboxes.firstWhere((b) => b.zone == CfdAeroZone.helmet);
      final CfdHeatmapProbeReading? probe = CfdWindTunnelHeatmapCalculator.hitTestProbe(
        position: helmetBox.center,
        hitboxes: hitboxes,
        solverResult: result,
        mode: CfdHeatmapLayerMode.pressureCp,
      );

      expect(probe, isNotNull);
      expect(probe!.zone, equals(CfdAeroZone.helmet));
      expect(probe.pressureCp, greaterThan(0));
      expect(probe.dragWatts, greaterThan(0));
    });
  });

  group('CfdWindTunnelHeatmap3dWidget responsive & interaction tests', () {
    Widget buildHarness({
      required Size size,
      bool isDisabled = false,
      bool isReadOnly = false,
      ValueChanged<CfdAeroZone?>? onZoneSelected,
    }) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SingleChildScrollView(
              child: CfdWindTunnelHeatmap3dWidget(
                isDisabled: isDisabled,
                isReadOnly: isReadOnly,
                onZoneSelected: onZoneSelected,
              ),
            ),
          ),
        ),
      );
    }

    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildHarness(size: viewport));
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(CfdWindTunnelHeatmap3dWidget), findsOneWidget);
          expect(find.text('CFD Wind Tunnel 3D Heatmap'), findsOneWidget);
          expect(find.text('Zone Pressure & Drag Breakdown'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('supports layer switching, camera presets, zone tap and disabled state',
        (WidgetTester tester) async {
      const Size viewport = Size(1280, 800);
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CfdAeroZone? selected;
      await tester.pumpWidget(
        buildHarness(
          size: viewport,
          onZoneSelected: (CfdAeroZone? z) => selected = z,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Przełączenie warstwy CFD
      await tester.tap(find.text('Drag Power'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('W'), findsWidgets);

      // Przełączenie presetu kamery i wyłączenie strug
      await tester.tap(find.text('Top Yaw'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Streamlines'));
      await tester.pump(const Duration(milliseconds: 250));

      // Kliknięcie strefy w panelu bocznym
      await tester.tap(find.text('Helmet & Head'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selected, equals(CfdAeroZone.helmet));

      // Stan disabled blokuje kliknięcia
      selected = null;
      await tester.pumpWidget(
        buildHarness(
          size: viewport,
          isDisabled: true,
          onZoneSelected: (CfdAeroZone? z) => selected = z,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Helmet & Head'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
