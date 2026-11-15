import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_3d_canvas_engine.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';

List<RiderPositionSnapshot> _buildTestPeloton({int count = 24}) {
  return List<RiderPositionSnapshot>.generate(count, (index) {
    final bool isPlayer = index == 0;
    return RiderPositionSnapshot(
      riderId: 'rider_$index',
      riderName: 'Kolarz $index',
      bibNumber: index + 1,
      teamId: 'team_${index % 4}',
      teamName: 'Team ${index % 4}',
      teamJerseyHexColor: index % 2 == 0 ? '#8E4A49' : '#38BDF8',
      isPlayerRider: isPlayer,
      distanceCoveredMeters: 8500.0 - (index * 1.4),
      kilometerMark: 8.5,
      elevationMeters: 420.0,
      currentGradientPercent: 4.5,
      currentSegmentIndex: 2,
      speedMs: 12.8 - (index * 0.02),
      speedKmh: (12.8 - (index * 0.02)) * 3.6,
      powerWatts: isPlayer ? 820 : 380,
      wattsPerKg: isPlayer ? 11.2 : 5.4,
      cadenceRpm: 94,
      heartRateBpm: 168,
      wPrimePercentage: 0.78,
      wPrimeJoules: 15600.0,
      glycogenPercentage: 0.82,
      glycogenGrams: 360.0,
      hydrationPercent: 0.85,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: isPlayer ? TacticalOrder.attack : TacticalOrder.holdPosition,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: index * 0.1,
      lateralPositionRoad: ((index % 5) - 2) * 0.35,
      lateralOffsetRoadMeters: ((index % 5) - 2) * 1.1,
      isDrafting: index > 0,
      draftingSavingsPercent: index > 0 ? 28.0 : 0.0,
      isPulling: index == 0,
      hasDefect: false,
      isCrashed: false,
      isDnf: false,
    );
  });
}

void main() {
  group('Peloton3dCanvasEngine', () {
    test('loads course segments and samples road with curves and cobbles', () {
      final engine = Peloton3dCanvasEngine();
      engine.loadCourseFromSegments(
        const <StageSegment>[
          StageSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 5.0,
            startElevationM: 100.0,
            endElevationM: 200.0,
            surfaceType: SegmentSurfaceType.smoothAsphalt,
            technicalDifficulty: 20.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.none,
          ),
          StageSegment(
            index: 1,
            startKm: 5.0,
            lengthKm: 5.0,
            startElevationM: 200.0,
            endElevationM: 575.0,
            surfaceType: SegmentSurfaceType.cobblestonesSector4,
            technicalDifficulty: 80.0,
            windDirectionDegrees: 90.0,
            roadBearingDegrees: 0.0,
            sprintOrKomClassification: SegmentClassification.cat2,
          ),
        ],
        totalDistanceMeters: 10000.0,
      );

      final asphaltNode = engine.sampleRoadAtDistance(2500.0);
      final cobbleNode = engine.sampleRoadAtDistance(7500.0);

      expect(asphaltNode.surfaceType, SegmentSurfaceType.smoothAsphalt);
      expect(cobbleNode.surfaceType, SegmentSurfaceType.cobblestonesSector4);
      expect(cobbleNode.gradientPercent, closeTo(7.5, 0.5));
      expect(cobbleNode.center.y, greaterThan(asphaltNode.center.y));
    });

    test('steps Boids physics (#184), wheel/crank RPM phases, and all 4 camera modes', () {
      final engine = Peloton3dCanvasEngine();
      final snapshots = _buildTestPeloton(count: 18);

      for (final mode in RaceCameraMode.values) {
        engine.switchCameraMode(mode, immediate: true);
        final stats = engine.stepFrame(
          dtSeconds: 1.0 / 60.0,
          snapshots: snapshots,
          focusRiderId: 'rider_0',
          windSpeedKmh: 22.0,
          leaderJerseys: const <String, LeaderJerseyType>{
            'rider_0': LeaderJerseyType.yellow,
            'rider_1': LeaderJerseyType.green,
            'rider_2': LeaderJerseyType.polkaDot,
            'rider_3': LeaderJerseyType.rainbow,
          },
          wheelProfiles: const <String, WheelProfileType>{
            'rider_0': WheelProfileType.depth65mm,
            'rider_1': WheelProfileType.discRear,
            'rider_2': WheelProfileType.depth35mm,
          },
        );

        expect(stats.totalRiders, 18);
        expect(stats.cameraMode, mode);
        expect(engine.activeRiders.length, 18);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paintStats = engine.render(canvas, const Size(1600, 900));
        recorder.endRecording();

        expect(paintStats.roadQuadsDrawn, greaterThan(0));
        expect(paintStats.renderedRiders, greaterThan(0));
      }
    });

    testWidgets('Peloton3dViewportWidget renders cleanly on 390x844, 1024x768 and 1600x900',
        (tester) async {
      final sizes = <Size>[
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      for (final size in sizes) {
        final engine = Peloton3dCanvasEngine();
        final snapshots = _buildTestPeloton(count: 10);

        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Peloton3dViewportWidget(
                engine: engine,
                snapshots: snapshots,
                focusRiderId: 'rider_0',
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 32));
        expect(tester.takeException(), isNull);
      }

      await tester.binding.setSurfaceSize(null);
    });
  });
}
