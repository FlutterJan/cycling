import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/first_person_cockpit_camera_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/on_bike_computer_hud_widget.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_3d_canvas_engine.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  group('FirstPersonCockpitCameraRenderer', () {
    test('positions eye-level camera and updates wheel phase and FOV with speed', () {
      final renderer = FirstPersonCockpitCameraRenderer();

      final resultHoods = renderer.stepFrame(
        FirstPersonCockpitFrameInput(
          dtSeconds: 1.0 / 60.0,
          viewportSize: const Size(1280, 720),
          riderWorldPosition: Vector3.zero(),
          roadTangent: Vector3(0.0, 0.0, 1.0),
          roadLateralRight: Vector3(1.0, 0.0, 0.0),
          roadSurfaceNormal: Vector3(0.0, 1.0, 0.0),
          speedMs: 12.0,
          powerWatts: 380.0,
          cadenceRpm: 92.0,
          gradientPercent: 4.5,
          gripPosture: CockpitGripPosture.hoods,
        ),
      );

      expect(resultHoods.cameraConfig.position.y, closeTo(1.34, 0.05));
      expect(resultHoods.frontWheelPhaseRadians, greaterThan(0.0));
      expect(resultHoods.liveGradientPercent, closeTo(4.5, 0.01));

      final resultAero = renderer.stepFrame(
        FirstPersonCockpitFrameInput(
          dtSeconds: 1.0 / 60.0,
          viewportSize: const Size(1280, 720),
          riderWorldPosition: Vector3.zero(),
          roadTangent: Vector3(0.0, 0.0, 1.0),
          roadLateralRight: Vector3(1.0, 0.0, 0.0),
          roadSurfaceNormal: Vector3(0.0, 1.0, 0.0),
          speedMs: 21.0,
          powerWatts: 760.0,
          cadenceRpm: 112.0,
          gradientPercent: -2.5,
          gripPosture: CockpitGripPosture.aeroTuck,
        ),
      );

      expect(resultAero.cameraConfig.position.y, lessThan(1.15));
      expect(resultAero.fovYDegrees, greaterThan(resultHoods.fovYDegrees));
      expect(resultAero.speedLinesIntensity, greaterThan(0.5));
    });

    test('triggers finger shift animations and updates gear ratio', () {
      final renderer = FirstPersonCockpitCameraRenderer();
      expect(renderer.state.gearLabel, '54x14');

      renderer.triggerGearShift(CockpitShiftDirection.upshift);
      expect(renderer.state.gearLabel, '54x13');
      expect(renderer.state.rightShiftAnimationProgress, 1.0);

      renderer.triggerGearShift(CockpitShiftDirection.downshift);
      expect(renderer.state.gearLabel, '54x14');
      expect(renderer.state.leftShiftAnimationProgress, 1.0);
    });

    test('projects 30 cm peloton rivals sorted back-to-front with tight draft flag', () {
      final renderer = FirstPersonCockpitCameraRenderer();
      final result = renderer.stepFrame(
        FirstPersonCockpitFrameInput(
          dtSeconds: 1.0 / 60.0,
          viewportSize: const Size(1600, 900),
          riderWorldPosition: Vector3.zero(),
          roadTangent: Vector3(0.0, 0.0, 1.0),
          roadLateralRight: Vector3(1.0, 0.0, 0.0),
          roadSurfaceNormal: Vector3(0.0, 1.0, 0.0),
          speedMs: 13.5,
          powerWatts: 310.0,
          cadenceRpm: 94.0,
          gradientPercent: 0.5,
          rivalsAhead: const <CockpitRivalAheadSample>[
            CockpitRivalAheadSample(
              riderId: 'close_rival',
              riderName: 'T. Pogacar',
              bibNumber: 1,
              jerseyColor: Color(0xFF8E4A49),
              leaderJerseyType: LeaderJerseyType.yellow,
              gapAheadMeters: 0.30,
              lateralOffsetMeters: 0.05,
              speedMs: 13.5,
            ),
            CockpitRivalAheadSample(
              riderId: 'far_rival',
              riderName: 'J. Vingegaard',
              bibNumber: 11,
              jerseyColor: Color(0xFF38BDF8),
              gapAheadMeters: 4.50,
              lateralOffsetMeters: -0.60,
              speedMs: 13.5,
            ),
          ],
        ),
      );

      expect(result.projectedRivals.length, 2);
      expect(result.projectedRivals.first.sample.riderId, 'far_rival');
      expect(result.projectedRivals.last.sample.riderId, 'close_rival');
      expect(result.projectedRivals.last.isTightDraftTarget, isTrue);
      expect(result.closestRivalGapMeters, closeTo(0.30, 0.001));
    });

    test('extracts rival samples from RiderPositionSnapshot list', () {
      final renderer = FirstPersonCockpitCameraRenderer();
      final snapshots = <RiderPositionSnapshot>[
        const RiderPositionSnapshot(
          riderId: 'player',
          riderName: 'Gracz',
          bibNumber: 7,
          teamId: 't1',
          teamName: 'Team 1',
          teamJerseyHexColor: '#8E4A49',
          isPlayerRider: true,
          distanceCoveredMeters: 1000.0,
          kilometerMark: 1.0,
          elevationMeters: 200.0,
          currentGradientPercent: 3.0,
          currentSegmentIndex: 0,
          speedMs: 12.0,
          speedKmh: 43.2,
          powerWatts: 340,
          wattsPerKg: 5.0,
          cadenceRpm: 92,
          heartRateBpm: 162,
          wPrimePercentage: 0.9,
          wPrimeJoules: 18000.0,
          glycogenPercentage: 0.9,
          glycogenGrams: 400.0,
          hydrationPercent: 0.9,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 0,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 0.2,
          lateralPositionRoad: 0.0,
          lateralOffsetRoadMeters: 0.0,
          isDrafting: true,
          draftingSavingsPercent: 34.0,
          isPulling: false,
          hasDefect: false,
          isCrashed: false,
          isDnf: false,
        ),
        const RiderPositionSnapshot(
          riderId: 'ahead_30cm',
          riderName: 'Rywal 1',
          bibNumber: 1,
          teamId: 't2',
          teamName: 'Team 2',
          teamJerseyHexColor: '#D4AF37',
          isPlayerRider: false,
          distanceCoveredMeters: 1002.02, // 1.72m bike + 0.30m gap
          kilometerMark: 1.002,
          elevationMeters: 200.1,
          currentGradientPercent: 3.0,
          currentSegmentIndex: 0,
          speedMs: 12.0,
          speedKmh: 43.2,
          powerWatts: 410,
          wattsPerKg: 6.0,
          cadenceRpm: 94,
          heartRateBpm: 166,
          wPrimePercentage: 0.9,
          wPrimeJoules: 18000.0,
          glycogenPercentage: 0.9,
          glycogenGrams: 400.0,
          hydrationPercent: 0.9,
          bidonsLeft: 2,
          gelsLeft: 3,
          activeTacticalOrder: TacticalOrder.holdPosition,
          groupIndex: 0,
          groupType: GroupType.peloton,
          timeGapToLeaderSeconds: 0.0,
          lateralPositionRoad: 0.0,
          lateralOffsetRoadMeters: 0.1,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          isPulling: true,
          hasDefect: false,
          isCrashed: false,
          isDnf: false,
        ),
      ];

      final samples = renderer.buildRivalSamplesFromSnapshots(
        snapshots: snapshots,
        playerRiderId: 'player',
      );

      expect(samples.length, 1);
      expect(samples.first.gapAheadMeters, closeTo(0.30, 0.01));
    });
  });

  group('FirstPersonCockpitViewportWidget', () {
    for (final Size size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: FirstPersonCockpitViewportWidget(
                  initialComputerModel: BikeComputerModel.wahooElemnt,
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(FirstPersonCockpitViewportWidget), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Bieg + (R)'));
          await tester.pump(const Duration(milliseconds: 120));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
