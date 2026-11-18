import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/tandem_and_handbike_physics_solver.dart';
import 'package:pro_peloton_manager/engine/rendering3d/tandem_and_handbike_3d_mesh_renderer.dart';
import 'package:pro_peloton_manager/models/paracycling/uci_paracycling_tandem_handbike_model.dart';

void main() {
  group('TandemAndHandbike3dMeshRenderer', () {
    const renderer = TandemAndHandbike3dMeshRenderer();

    test('renders Tandem B (2 wheels) with thermal rotor glow telemetry', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final telemetry = renderer.renderFrame(
        canvas: canvas,
        size: const Size(800, 500),
        config: const Paracycling3dRenderConfig(
          vehicleType: Paracycling3dVehicleType.tandemRoadB,
          cameraPreset: Paracycling3dCameraPreset.sideDynamic,
        ),
        tandemInput: const Tandem3dRenderInput(
          speedMs: 26.5, // >95 km/h
          rotorTempCelsius: 275.0,
          thermalStatus: DescentThermalBrakeStatus.thermalFade,
          syncPhase: TandemSyncPhase.marginalDrift,
          timeSeconds: 1.2,
        ),
        handbikeInput: const Handbike3dRenderInput(),
      );

      recorder.endRecording();

      expect(telemetry.wheelCount, 2);
      expect(telemetry.primitiveCount, greaterThan(40));
      expect(telemetry.thermalGlowIntensity, greaterThan(0.5));
      expect(telemetry.syncPhaseDriftDeg, greaterThan(0.0));
      expect(telemetry.innerWheelLiftMm, 0.0);
    });

    test('renders Handbike H1-H4 and H5 (3 wheels) with inner wheel lift', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final telemetry = renderer.renderFrame(
        canvas: canvas,
        size: const Size(800, 500),
        config: const Paracycling3dRenderConfig(
          vehicleType: Paracycling3dVehicleType.kneelingHandbikeH5,
          cameraPreset: Paracycling3dCameraPreset.rearPeloton,
        ),
        tandemInput: const Tandem3dRenderInput(),
        handbikeInput: const Handbike3dRenderInput(
          sportClass: ParacyclingSportClass.h5,
          posture: HandbikePostureType.kneeling,
          speedMs: 13.0,
          lateralG: 0.72,
          stabilityZone: HandbikeTurnStabilityZone.innerWheelLiftRisk,
          innerWheelLiftRatio: 0.65,
          steeringAngleRad: 0.25,
          timeSeconds: 0.8,
        ),
      );

      recorder.endRecording();

      expect(telemetry.wheelCount, 3);
      expect(telemetry.primitiveCount, greaterThan(40));
      expect(telemetry.innerWheelLiftMm, greaterThan(10.0));
      expect(telemetry.estimatedCdaM2, closeTo(0.245, 0.01));
    });

    test('handles empty viewport size gracefully', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final telemetry = renderer.renderFrame(
        canvas: canvas,
        size: Size.zero,
        config: const Paracycling3dRenderConfig(),
        tandemInput: const Tandem3dRenderInput(),
        handbikeInput: const Handbike3dRenderInput(),
      );

      recorder.endRecording();
      expect(telemetry.primitiveCount, 0);
    });
  });

  group('TandemAndHandbike3dMeshViewport responsive & interaction', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: TandemAndHandbike3dMeshViewport(
                  autoAnimate: false,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }

    testWidgets('renders cleanly at 390x844 mobile', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('TANDEM B'), findsWidgets);
    });

    testWidgets('renders cleanly at 1024x768 tablet', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('HANDBIKE H3'), findsOneWidget);
    });

    testWidgets('renders cleanly at 1600x900 desktop and switches vehicle',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('2 KOŁA'), findsOneWidget);

      await tester.tap(find.text('HANDBIKE H3'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('3 KOŁA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
