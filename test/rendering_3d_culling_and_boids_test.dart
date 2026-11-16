import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/boids_peloton_flocking_solver.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:vector_math/vector_math_64.dart';

List<PelotonBoidAgent> _buildPeloton176({
  double startDistanceMeters = 1000.0,
  double baseSpeedMs = 13.5,
}) {
  const riderCount = 176;
  const columns = 8;
  const roadWidth = 7.0;
  const usableHalfWidth = roadWidth * 0.5 - 0.5;

  return List<PelotonBoidAgent>.generate(riderCount, (index) {
    final row = index ~/ columns;
    final col = index % columns;
    final colFraction = (col / (columns - 1)) * 2.0 - 1.0; // -1..+1
    final lateralOffset = colFraction * usableHalfWidth;
    final longitudinalJitter = (col.isEven ? 0.0 : 0.45);
    final distance = startDistanceMeters - row * 2.2 - longitudinalJitter;

    // Slight speed variation to trigger alignment, draft seeking, and overtakes.
    final speedDelta = ((index % 7) - 3) * 0.35;
    final desiredSpeed = baseSpeedMs + speedDelta;

    return PelotonBoidAgent(
      riderId: 'rider_${index + 1}',
      distanceMeters: distance,
      lateralOffsetMeters: lateralOffset,
      speedMs: baseSpeedMs,
      desiredSpeedMs: desiredSpeed,
    );
  }, growable: false);
}

void main() {
  group('Rendering 3D Culling & Boids Performance', () {
    test(
      '1000 steps of BoidsPelotonFlockingSolver and Scene3DMathProjection for 176 riders averages under 2.0 ms/frame',
      () {
        final solver = BoidsPelotonFlockingSolver();
        final projection = Scene3DMathProjection(
          viewportWidth: 1600.0,
          viewportHeight: 900.0,
          fovYDegrees: 58.0,
          zNear: 0.2,
          zFar: 500.0,
        );

        var agents = _buildPeloton176();
        const totalSteps = 1000;
        const dt = 1.0 / 60.0;
        const roadWidth = 7.5;

        // Warm-up pass to stabilize Dart VM JIT before timing.
        for (var w = 0; w < 25; w++) {
          final stepRes = solver.step(
            agents,
            dtSeconds: dt,
            roadWidthMeters: roadWidth,
            crosswindSpeedMs: 4.5,
            windAngleRad: 0.4,
          );
          agents = stepRes.agents;

          final leadDist = agents.first.distanceMeters;
          final eye = Scene3DMathProjection.courseToWorld3D(
            distanceMeters: leadDist - 60.0,
            lateralOffsetMeters: 0.0,
            elevationMeters: 120.0,
            verticalOffsetMeters: 6.5,
          );
          final target = Scene3DMathProjection.courseToWorld3D(
            distanceMeters: leadDist - 12.0,
            lateralOffsetMeters: 0.0,
            elevationMeters: 120.0,
            verticalOffsetMeters: 1.0,
          );
          projection.setView(eye: eye, target: target);

          for (var i = 0; i < agents.length; i++) {
            final a = agents[i];
            final pos = Scene3DMathProjection.courseToWorld3D(
              distanceMeters: a.distanceMeters,
              lateralOffsetMeters: a.lateralOffsetMeters,
              elevationMeters: 120.0,
              verticalOffsetMeters: 0.9,
            );
            if (projection.isSphereInFrustum(pos, 1.1)) {
              projection.worldToScreen(pos);
            }
          }
        }

        var visibleCountLastFrame = 0;
        var culledCountLastFrame = 0;

        final stopwatch = Stopwatch()..start();
        for (var step = 0; step < totalSteps; step++) {
          final stepRes = solver.step(
            agents,
            dtSeconds: dt,
            roadWidthMeters: roadWidth,
            crosswindSpeedMs: 4.5,
            windAngleRad: 0.4,
          );
          agents = stepRes.agents;

          // Position broadcast chase camera behind the peloton tail looking forward.
          final leadDist = agents.first.distanceMeters;
          final eye = Scene3DMathProjection.courseToWorld3D(
            distanceMeters: leadDist - 60.0,
            lateralOffsetMeters: 0.0,
            elevationMeters: 120.0,
            verticalOffsetMeters: 6.5,
          );
          final target = Scene3DMathProjection.courseToWorld3D(
            distanceMeters: leadDist - 12.0,
            lateralOffsetMeters: 0.0,
            elevationMeters: 120.0,
            verticalOffsetMeters: 1.0,
          );
          projection.setView(eye: eye, target: target);

          var visibleThisFrame = 0;
          var culledThisFrame = 0;

          for (var i = 0; i < agents.length; i++) {
            final a = agents[i];
            final worldPos = Scene3DMathProjection.courseToWorld3D(
              distanceMeters: a.distanceMeters,
              lateralOffsetMeters: a.lateralOffsetMeters,
              elevationMeters: 120.0,
              verticalOffsetMeters: 0.9,
            );

            if (projection.isSphereInFrustum(worldPos, 1.1)) {
              final projected = projection.worldToScreen(worldPos);
              if (projected.isInFrontOfCamera) {
                visibleThisFrame++;
              }
            } else {
              culledThisFrame++;
            }
          }

          visibleCountLastFrame = visibleThisFrame;
          culledCountLastFrame = culledThisFrame;
        }
        stopwatch.stop();

        final totalMs = stopwatch.elapsedMicroseconds / 1000.0;
        final avgMsPerFrame = totalMs / totalSteps;

        // Print telemetry for CI/benchmark visibility.
        // ignore: avoid_print
        print(
          '1000-step 176-rider Boids + 3D Projection/Culling: '
          '${totalMs.toStringAsFixed(2)} ms total, '
          '${avgMsPerFrame.toStringAsFixed(4)} ms/frame '
          '(visible: $visibleCountLastFrame, culled: $culledCountLastFrame)',
        );

        expect(
          avgMsPerFrame,
          lessThan(2.0),
          reason:
              'Average frame time (${avgMsPerFrame.toStringAsFixed(3)} ms) must stay below 2.0 ms for 176 riders',
        );

        // Verify simulation integrity after 1000 steps.
        expect(agents.length, 176);
        final halfUsableRoad = roadWidth * 0.5 - solver.config.roadShoulderMarginMeters;
        for (final agent in agents) {
          expect(agent.isActive, isTrue);
          expect(agent.distanceMeters.isFinite, isTrue);
          expect(agent.lateralOffsetMeters.isFinite, isTrue);
          expect(agent.speedMs.isFinite, isTrue);
          expect(agent.lateralOffsetMeters.abs(), lessThanOrEqualTo(halfUsableRoad + 1e-6));
        }
        expect(visibleCountLastFrame + culledCountLastFrame, 176);
      },
    );

    test(
      'BoidsPelotonFlockingSolver enforces minimum lateral clearance and draft savings',
      () {
        final solver = BoidsPelotonFlockingSolver();
        final agents = [
          const PelotonBoidAgent(
            riderId: 'leader',
            distanceMeters: 500.0,
            lateralOffsetMeters: 0.0,
            speedMs: 12.0,
            desiredSpeedMs: 12.0,
          ),
          const PelotonBoidAgent(
            riderId: 'overlap_neighbor',
            distanceMeters: 500.2,
            lateralOffsetMeters: 0.05,
            speedMs: 12.0,
            desiredSpeedMs: 12.0,
          ),
          const PelotonBoidAgent(
            riderId: 'drafter',
            distanceMeters: 498.65,
            lateralOffsetMeters: 0.0,
            speedMs: 12.0,
            desiredSpeedMs: 12.0,
          ),
        ];

        final result = solver.step(agents, dtSeconds: 1.0 / 60.0, collectBreakdowns: true);
        final a0 = result.agents[0];
        final a1 = result.agents[1];
        final drafter = result.agents[2];

        final lateralGap = (a0.lateralOffsetMeters - a1.lateralOffsetMeters).abs();
        expect(lateralGap, greaterThanOrEqualTo(solver.config.minLateralSeparationMeters - 0.02));
        expect(drafter.draftSavingsRatio, greaterThan(0.15));
        expect(drafter.estimatedCda, lessThan(solver.config.baseRiderCda));
        expect(result.breakdowns.containsKey('drafter'), isTrue);
      },
    );

    test(
      'Scene3DMathProjection culls riders behind camera and projects riders in front accurately',
      () {
        final projection = Scene3DMathProjection(
          viewportWidth: 1280.0,
          viewportHeight: 720.0,
          fovYDegrees: 60.0,
          zNear: 0.5,
          zFar: 450.0,
        );

        projection.setView(
          eye: Vector3(0.0, 3.0, 0.0),
          target: Vector3(0.0, 1.5, 25.0),
        );

        final inFrontPoint = Scene3DMathProjection.courseToWorld3D(
          distanceMeters: 30.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 0.0,
          verticalOffsetMeters: 1.0,
        );
        final behindPoint = Scene3DMathProjection.courseToWorld3D(
          distanceMeters: -15.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 0.0,
          verticalOffsetMeters: 1.0,
        );
        final tooFarPoint = Scene3DMathProjection.courseToWorld3D(
          distanceMeters: 600.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 0.0,
          verticalOffsetMeters: 1.0,
        );

        expect(projection.isPointInFrustum(inFrontPoint), isTrue);
        expect(projection.isSphereInFrustum(inFrontPoint, 1.0), isTrue);
        expect(projection.isPointInFrustum(behindPoint), isFalse);
        expect(projection.isSphereInFrustum(behindPoint, 1.0), isFalse);
        expect(projection.isPointInFrustum(tooFarPoint), isFalse);

        final projectedFront = projection.worldToScreen(inFrontPoint);
        expect(projectedFront.isInFrontOfCamera, isTrue);
        expect(projectedFront.isInViewport, isTrue);
        expect(projectedFront.screenX, closeTo(640.0, 1.0));
        expect(projectedFront.depthEye, closeTo(30.0, 2.0));

        final projectedBehind = projection.worldToScreen(behindPoint);
        expect(projectedBehind.isInFrontOfCamera, isFalse);
        expect(projectedBehind.isInViewport, isFalse);

        // Verify curved mountain road pose computation.
        final pose = Scene3DMathProjection.courseToCyclistPose(
          coursePosition: const CoursePosition(
            distanceMeters: 50.0,
            lateralOffsetMeters: 1.2,
            elevationMeters: 1450.0,
          ),
          roadGeometry: const RoadGeometryParameters(
            turningRadiusMeters: 25.0,
            gradientPercent: 8.5,
            speedMs: 11.0,
          ),
        );
        expect(pose.pitch, closeTo(math.atan(0.085), 1e-6));
        expect(pose.roll, greaterThan(0.0));
        expect(pose.headPosition.y, greaterThan(pose.position.y));
      },
    );
  });
}
