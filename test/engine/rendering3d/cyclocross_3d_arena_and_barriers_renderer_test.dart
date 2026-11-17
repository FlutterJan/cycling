import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/cyclocross_bunnyhop_and_carry_solver.dart';
import 'package:pro_peloton_manager/engine/rendering3d/cyclocross_3d_arena_and_barriers_renderer.dart';
import 'package:pro_peloton_manager/models/race/cyclocross_course_and_mud_model.dart';

void main() {
  group('Cyclocross3dArenaAndBarriersRenderer', () {
    test('samples winding course and resolves mud, stairs, planks, sand, and pit', () {
      const renderer = Cyclocross3dArenaAndBarriersRenderer(
        config: Cyclocross3dArenaConfig(
          stylePreset: CyclocrossArenaStylePreset.koksijdeDunes,
        ),
      );

      final grass = renderer.sampleCourseAt(10.0);
      final mud = renderer.sampleCourseAt(35.0);
      final stairs = renderer.sampleCourseAt(68.0);
      final planks = renderer.sampleCourseAt(90.0);
      final sand = renderer.sampleCourseAt(125.0);
      final pit = renderer.sampleCourseAt(165.0);

      expect(grass.terrainType, CyclocrossTerrainType.meadowGrass);
      expect(mud.terrainType, CyclocrossTerrainType.deepMud);
      expect(stairs.terrainType, CyclocrossTerrainType.staircaseRunUp);
      expect(planks.terrainType, CyclocrossTerrainType.planks);
      expect(sand.terrainType, CyclocrossTerrainType.sandPit);
      expect(pit.terrainType, CyclocrossTerrainType.doublePitLane);
      expect(grass.center.x, isNot(equals(mud.center.x)));
    });

    test('shoulderCarry animator places bike on right shoulder and animates stride', () {
      const renderer = Cyclocross3dArenaAndBarriersRenderer();
      final sample = renderer.sampleCourseAt(68.0);

      final poseA = renderer.runnerAnimator.evaluatePose(
        actor: const CyclocrossRider3DActor(
          riderId: 'r1',
          shortName: 'MVDP',
          jerseyColor: Colors.white,
          helmetColor: Colors.black,
          bikeFrameColor: Colors.red,
          distanceMeters: 68.0,
          lateralOffsetMeters: 0.0,
          speedMps: 4.2,
          traversalMode: CyclocrossTraversalMode.dismountAndRun,
          animationTimeSeconds: 0.1,
        ),
        courseSample: sample,
      );

      final poseB = renderer.runnerAnimator.evaluatePose(
        actor: const CyclocrossRider3DActor(
          riderId: 'r1',
          shortName: 'MVDP',
          jerseyColor: Colors.white,
          helmetColor: Colors.black,
          bikeFrameColor: Colors.red,
          distanceMeters: 68.0,
          lateralOffsetMeters: 0.0,
          speedMps: 4.2,
          traversalMode: CyclocrossTraversalMode.dismountAndRun,
          animationTimeSeconds: 0.35,
        ),
        courseSample: sample,
      );

      // Rower spoczywa wyżej (na prawym barku), powyżej miednicy
      expect(poseA.bikeHeadTubeTop.y, greaterThan(poseA.pelvis.y));
      // Stride porusza stopami w czasie
      expect(
        poseA.leftFoot.distanceTo(poseB.leftFoot),
        greaterThan(0.05),
      );
      // Prawa strona barku jest po prawej stronie wektora lateralRight względem klatki
      final rightOffset =
          (poseA.rightShoulder - poseA.chest).dot(sample.lateralRight);
      final leftOffset =
          (poseA.leftShoulder - poseA.chest).dot(sample.lateralRight);
      expect(rightOffset, greaterThan(0.0));
      expect(leftOffset, lessThan(0.0));
    });

    test('renderFrame paints all CX arena elements and returns telemetry', () {
      const renderer = Cyclocross3dArenaAndBarriersRenderer(
        config: Cyclocross3dArenaConfig(
          stylePreset: CyclocrossArenaStylePreset.zonhovenSandBowl,
          maxDrawDistanceMeters: 210.0,
        ),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final telemetry = renderer.renderFrame(
        canvas: canvas,
        size: const Size(1280, 720),
        cameraDistanceMeters: 20.0,
        cameraYawOffsetRadians: 0.1,
        cameraPitchDegrees: 14.0,
        timeSeconds: 1.5,
        riders: const [
          CyclocrossRider3DActor(
            riderId: 'r1',
            shortName: 'MVDP',
            jerseyColor: Colors.white,
            helmetColor: Colors.black,
            bikeFrameColor: Colors.red,
            distanceMeters: 32.0,
            lateralOffsetMeters: -0.3,
            speedMps: 4.4,
            traversalMode: CyclocrossTraversalMode.dismountAndRun,
            animationTimeSeconds: 1.5,
          ),
          CyclocrossRider3DActor(
            riderId: 'r2',
            shortName: 'WVA',
            jerseyColor: Colors.amber,
            helmetColor: Colors.red,
            bikeFrameColor: Colors.blue,
            distanceMeters: 28.0,
            lateralOffsetMeters: 0.4,
            speedMps: 5.5,
            traversalMode: CyclocrossTraversalMode.bunnyHop,
            animationTimeSeconds: 1.5,
          ),
        ],
      );

      final picture = recorder.endRecording();
      picture.dispose();

      expect(telemetry.visibleCourseSamples, greaterThan(20));
      expect(telemetry.tapePostsRendered, greaterThan(20));
      expect(telemetry.woodenPlanksRendered, greaterThanOrEqualTo(2));
      expect(telemetry.staircasesRendered, greaterThanOrEqualTo(1));
      expect(telemetry.sandPitSectionsRendered, greaterThanOrEqualTo(1));
      expect(telemetry.fritesTentsRendered, greaterThanOrEqualTo(1));
      expect(telemetry.spectatorsRendered, greaterThanOrEqualTo(5));
      expect(telemetry.pitMechanicsRendered, greaterThanOrEqualTo(4));
      expect(telemetry.runningShoulderCarryRiders, equals(1));
    });

    for (final viewportSize in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'Cyclocross3dArenaViewportWidget renders without overflow at ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Cyclocross3dArenaViewportWidget(
                  autoAnimate: false,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(Cyclocross3dArenaViewportWidget), findsOneWidget);
          expect(find.text('Arena Przełajowa CX 3D'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
