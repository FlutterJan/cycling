import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/cobblestone_vibration_camera_fx.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('CobblestoneVibrationCameraFx', () {
    test('mapuje nawierzchnie bruku 1..5 gwiazdek i zwraca null dla asfaltu', () {
      expect(
        CobblestoneSectorDifficulty.fromSurfaceType(
          SegmentSurfaceType.cobblestonesSector1,
        ),
        CobblestoneSectorDifficulty.oneStar,
      );
      expect(
        CobblestoneSectorDifficulty.fromSurfaceType(
          SegmentSurfaceType.cobblestonesSector5,
        ),
        CobblestoneSectorDifficulty.fiveStars,
      );
      expect(
        CobblestoneSectorDifficulty.fromSurfaceType(
          SegmentSurfaceType.smoothAsphalt,
        ),
        isNull,
      );
      expect(CobblestoneSectorDifficulty.fromStars(9),
          CobblestoneSectorDifficulty.fiveStars);
    });

    test('generuje wyższe mikro-wstrząsy kierownicy i kamery na 5★ niż na 1★', () {
      final fx1 = CobblestoneVibrationCameraFx(randomSeed: 42);
      final fx5 = CobblestoneVibrationCameraFx(randomSeed: 42);

      CobblestoneFxFrameState state1 = CobblestoneFxFrameState.inactive;
      CobblestoneFxFrameState state5 = CobblestoneFxFrameState.inactive;

      for (int i = 0; i < 20; i++) {
        state1 = fx1.step(
          dtSeconds: 0.016,
          surfaceType: SegmentSurfaceType.cobblestonesSector1,
          focalRiderSpeedKmh: 40.0,
          cameraMode: RaceCameraMode.chaseCam,
          isFirstPersonCockpit: true,
        );
        state5 = fx5.step(
          dtSeconds: 0.016,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          focalRiderSpeedKmh: 40.0,
          cameraMode: RaceCameraMode.chaseCam,
          isFirstPersonCockpit: true,
        );
      }

      expect(state1.isActive, isTrue);
      expect(state5.isActive, isTrue);
      expect(
        state5.handlebarVibration.dominantFrequencyHz,
        greaterThan(state1.handlebarVibration.dominantFrequencyHz),
      );
      expect(
        state5.handlebarVibration.forkChatterIntensity,
        greaterThan(state1.handlebarVibration.forkChatterIntensity),
      );
    });

    test('tłumi wstrząsy kamery w trybie helikoptera względem kokpitu FPP', () {
      final fxCockpit = CobblestoneVibrationCameraFx(randomSeed: 7);
      final fxHeli = CobblestoneVibrationCameraFx(randomSeed: 7);

      CobblestoneFxFrameState cockpitState = CobblestoneFxFrameState.inactive;
      CobblestoneFxFrameState heliState = CobblestoneFxFrameState.inactive;

      for (int i = 0; i < 25; i++) {
        cockpitState = fxCockpit.step(
          dtSeconds: 0.016,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          focalRiderSpeedKmh: 44.0,
          cameraMode: RaceCameraMode.chaseCam,
          isFirstPersonCockpit: true,
        );
        heliState = fxHeli.step(
          dtSeconds: 0.016,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          focalRiderSpeedKmh: 44.0,
          cameraMode: RaceCameraMode.heliCam,
          isFirstPersonCockpit: false,
        );
      }

      expect(
        cockpitState.cameraImpulse.screenShakeOffsetPx.distance,
        greaterThan(heliState.cameraImpulse.screenShakeOffsetPx.distance * 4.0),
      );
    });

    test('emituje kurz na suchym bruku i wygasza go na mokrym bruku', () {
      final riders = List<CobblestoneRiderInput>.generate(
        8,
        (i) => CobblestoneRiderInput(
          riderId: 'r_$i',
          progressMeters: 1000.0 - i * 2.0,
          lateralOffsetMeters: (i % 3 - 1) * 1.2,
          speedKmh: 41.0,
          worldPosition: Vector3(0.0, 0.0, i * 2.0),
        ),
      );

      final dryFx = CobblestoneVibrationCameraFx(randomSeed: 11);
      CobblestoneFxFrameState dryState = CobblestoneFxFrameState.inactive;
      for (int i = 0; i < 15; i++) {
        dryState = dryFx.step(
          dtSeconds: 0.05,
          surfaceType: SegmentSurfaceType.cobblestonesSector4,
          focalRiderSpeedKmh: 41.0,
          cameraMode: RaceCameraMode.chaseCam,
          riders: riders,
        );
      }
      expect(dryState.activeDustCount, greaterThan(0));

      final wetFx = CobblestoneVibrationCameraFx(
        config: const CobblestoneVibrationConfig(isWetCobbles: true),
        randomSeed: 11,
      );
      final wetState = wetFx.step(
        dtSeconds: 0.05,
        surfaceType: SegmentSurfaceType.cobblestonesSector4,
        focalRiderSpeedKmh: 41.0,
        cameraMode: RaceCameraMode.chaseCam,
        riders: riders,
      );
      expect(wetState.activeDustCount, 0);
    });

    test('rozciąga peleton w pojedynczy wężyk na koronie bruku', () {
      final riders = List<CobblestoneRiderInput>.generate(
        10,
        (i) => CobblestoneRiderInput(
          riderId: 'rider_$i',
          progressMeters: 500.0 - i * 1.5,
          lateralOffsetMeters: (i.isEven ? 2.4 : -2.4),
          speedKmh: 42.0,
          cobbleSkill: 85.0,
          worldPosition: Vector3(0.0, 0.0, i * 1.5),
        ),
      );

      final fx1 = CobblestoneVibrationCameraFx(randomSeed: 5);
      final fx5 = CobblestoneVibrationCameraFx(randomSeed: 5);

      final s1 = fx1.step(
        dtSeconds: 0.05,
        surfaceType: SegmentSurfaceType.cobblestonesSector1,
        focalRiderSpeedKmh: 42.0,
        cameraMode: RaceCameraMode.heliCam,
        riders: riders,
      );
      final s5 = fx5.step(
        dtSeconds: 0.05,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        focalRiderSpeedKmh: 42.0,
        cameraMode: RaceCameraMode.heliCam,
        riders: riders,
      );

      expect(s5.pelotonFileLengthMeters, greaterThan(s1.pelotonFileLengthMeters));
      expect(s5.averageCrownAlignment, greaterThan(s1.averageCrownAlignment));
      expect(
        s5.stringOutDisplacements['rider_9']!.targetLateralOffsetMeters.abs(),
        lessThan(1.0),
      );
    });
  });

  group('CobblestoneVibrationControlPanel responsywność', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje się bez przepełnień przy ${viewport.width}x${viewport.height}',
          (WidgetTester tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        CobblestoneSectorDifficulty selected =
            CobblestoneSectorDifficulty.threeStars;
        CobblestoneVibrationConfig config = const CobblestoneVibrationConfig();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CobblestoneVibrationControlPanel(
                  config: config,
                  frameState: CobblestoneFxFrameState.inactive,
                  selectedDifficulty: selected,
                  onConfigChanged: (c) => config = c,
                  onDifficultySelected: (d) => selected = d,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(CobblestoneVibrationControlPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
