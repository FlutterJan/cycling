import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/onboard_bike_mounted_action_cam_3d.dart';

void main() {
  group('FisheyeLens140Projection', () {
    test('projects points in front of camera and hides points behind camera', () {
      const Size viewport = Size(800, 450);

      final FisheyeProjectedPoint center = FisheyeLens140Projection.project(
        x: 0.0,
        y: 0.0,
        z: 2.0,
        viewport: viewport,
        fovDegrees: 140.0,
      );
      expect(center.isVisible, isTrue);
      expect(center.screenOffset.dx, closeTo(400.0, 0.5));
      expect(center.screenOffset.dy, closeTo(225.0, 0.5));

      final FisheyeProjectedPoint behind = FisheyeLens140Projection.project(
        x: 0.0,
        y: 0.0,
        z: -1.0,
        viewport: viewport,
        fovDegrees: 140.0,
      );
      expect(behind.isVisible, isFalse);

      // 140-degree wide-angle should keep wide lateral points (60 deg off-axis) visible.
      final FisheyeProjectedPoint wideAngle = FisheyeLens140Projection.project(
        x: 1.73,
        y: 0.0,
        z: 1.0,
        viewport: viewport,
        fovDegrees: 140.0,
      );
      expect(wideAngle.isVisible, isTrue);
      expect(wideAngle.screenOffset.dx, greaterThan(600.0));
    });
  });

  group('AsphaltMicroVibrationModel', () {
    test('stabilization reduces RMS G-force and cobbles increase vibration', () {
      final AsphaltMicroVibrationSample smoothStab =
          AsphaltMicroVibrationModel.compute(
        timeSeconds: 1.25,
        speedKmh: 62.0,
        surface: ActionCamRoadSurface.smoothTarmac,
        stabilizationEnabled: true,
        cadenceRpm: 105.0,
        elbowBumpImpulse: 0.0,
      );
      final AsphaltMicroVibrationSample cobblesRaw =
          AsphaltMicroVibrationModel.compute(
        timeSeconds: 1.25,
        speedKmh: 62.0,
        surface: ActionCamRoadSurface.urbanCobbles,
        stabilizationEnabled: false,
        cadenceRpm: 105.0,
        elbowBumpImpulse: 0.6,
      );

      expect(cobblesRaw.gForceRms, greaterThan(smoothStab.gForceRms));
      expect(cobblesRaw.dominantFrequencyHz, greaterThan(smoothStab.dominantFrequencyHz));
    });
  });

  group('Final1500mSprintBattleGenerator', () {
    test('generates lead rider ahead and elbow-squeezing rivals in final 1500m', () {
      final OnBoardActionCamFrameState frame =
          Final1500mSprintBattleGenerator.buildFrame(
        elapsedSeconds: 4.2,
        distanceToFinishMeters: 620.0,
        speedKmh: 67.5,
        config: const ActionCam140Config(),
      );

      expect(frame.distanceToFinishMeters, 620.0);
      expect(frame.gearRearTeeth, 11);
      expect(frame.nearbyRivals.length, greaterThanOrEqualTo(5));
      expect(
        frame.nearbyRivals.any((SprintElbowRival3D r) => r.longitudinalOffsetMeters > 1.2),
        isTrue,
      );
      expect(
        frame.nearbyRivals.any((SprintElbowRival3D r) => r.lateralOffsetMeters < 0),
        isTrue,
      );
      expect(
        frame.nearbyRivals.any((SprintElbowRival3D r) => r.lateralOffsetMeters > 0),
        isTrue,
      );
    });
  });

  group('OnBoardBikeMountedActionCam3d Widget', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnBoardBikeMountedActionCam3d(
              autoPlay: false,
              initialDistanceToFinishMeters: 1200.0,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow on 390x844 mobile', (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.byType(OnBoardBikeMountedActionCam3d), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1024x768 tablet', (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.byType(OnBoardBikeMountedActionCam3d), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on 1600x900 desktop and switches mounts',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('Kamera Akcji 140° FOV'), findsOneWidget);

      await tester.tap(find.text('Pod siodłem'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('CAM-02 // SADDLE'), findsOneWidget);

      await tester.tap(find.text('Dual Cam'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('POD SIODŁEM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
