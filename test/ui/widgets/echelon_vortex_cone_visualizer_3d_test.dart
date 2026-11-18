import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/aerodynamic_cross_drafting_echelon_vortex.dart';
import 'package:pro_peloton_manager/ui/widgets/echelon_vortex_cone_visualizer_3d.dart';

void main() {
  group('EchelonVortexCone3dCalculator & Data', () {
    test('demo data builds shifted echelon with optimal and gutter riders', () {
      final data = EchelonVortexConeVisualizerData.demo(
        windFromLeft: true,
        windSpeedMs: 9.2,
      );

      expect(data.riders.length, 6);
      expect(data.windSide, EchelonWindSide.fromLeft);
      expect(data.wakeShiftAngleDegrees, greaterThan(15.0));
      expect(data.optimalConeCount, greaterThanOrEqualTo(2));
      expect(data.gutterExposedCount, greaterThanOrEqualTo(1));
      expect(data.totalPowerSavedWatts, greaterThan(100.0));
    });

    test('projectPoint3d projects points with positive scale and hitTestRider matches', () {
      const size = Size(800, 400);
      final p1 = EchelonVortexCone3dCalculator.projectPoint3d(
        xLongitudinal: 2.0,
        yVertical: 0.5,
        zLateral: 0.0,
        canvasSize: size,
        cameraYawDeg: -28.0,
        cameraPitchDeg: 26.0,
        zoom: 1.0,
      );

      expect(p1.scale, greaterThan(0.0));
      expect(p1.offset.dx.isFinite, isTrue);
      expect(p1.offset.dy.isFinite, isTrue);

      final demo = EchelonVortexConeVisualizerData.demo();
      final hitboxes = [
        EchelonProjectedRiderHitbox(
          rider: demo.riders.first,
          center: const Offset(200, 150),
          radius: 26,
          depth: 1.0,
        ),
        EchelonProjectedRiderHitbox(
          rider: demo.riders.last,
          center: const Offset(400, 220),
          radius: 26,
          depth: 2.0,
        ),
      ];

      final hit = EchelonVortexCone3dCalculator.hitTestRider(
        localPosition: const Offset(405, 222),
        hitboxes: hitboxes,
      );
      expect(hit?.id, demo.riders.last.id);
    });
  });

  group('EchelonVortexConeVisualizer3d Widget', () {
    Future<void> pumpAtSize(
      WidgetTester tester, {
      required Size surfaceSize,
      bool enabled = true,
      ValueChanged<EchelonVortexRiderNode3d>? onRiderSelected,
    }) async {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: EchelonVortexConeVisualizer3d(
                data: EchelonVortexConeVisualizerData.demo(),
                enabled: enabled,
                onRiderSelected: onRiderSelected,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly without overflow at 390x844 mobile',
        (WidgetTester tester) async {
      await pumpAtSize(tester, surfaceSize: const Size(390, 844));
      expect(find.textContaining('AERO VISION 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1024x768 tablet',
        (WidgetTester tester) async {
      await pumpAtSize(tester, surfaceSize: const Size(1024, 768));
      expect(find.textContaining('AERO VISION 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1600x900 desktop',
        (WidgetTester tester) async {
      await pumpAtSize(tester, surfaceSize: const Size(1600, 900));
      expect(find.textContaining('AERO VISION 3D'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports camera presets, layer modes, rider selection and disabled state',
        (WidgetTester tester) async {
      EchelonVortexRiderNode3d? selected;
      await pumpAtSize(
        tester,
        surfaceSize: const Size(1600, 900),
        onRiderSelected: (r) => selected = r,
      );

      await tester.tap(find.text('Overhead'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Ekspozycja w rynsztoku'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('#1 PPM'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selected?.bibNumber, 1);

      // Verify disabled state blocks selection callback
      selected = null;
      await pumpAtSize(
        tester,
        surfaceSize: const Size(1600, 900),
        enabled: false,
        onRiderSelected: (r) => selected = r,
      );
      await tester.tap(find.text('#1 PPM'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selected, isNull);
    });
  });
}
