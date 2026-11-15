// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';

void main() {
  group('CameraRigController - ChaseCam (Zwift / MyWhoosh Style)', () {
    test('ChaseCam utrzymuje zadaną odległość za plecami kolarza i patrzy w przód', () {
      final controller = CameraRigController(
        initialMode: RaceCameraMode.chaseCam,
      );

      final riderPose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 500.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 100.0,
        ),
        roadGeometry: const RoadGeometryParameters(),
      );

      // Kilka kroków symulacji do ustabilizowania wygładzania
      for (int i = 0; i < 20; i++) {
        controller.update(
          dtSeconds: 0.016,
          targetRiderPose: riderPose,
          isSprinting: false,
          isAttacking: false,
        );
      }

      // Kamera powinna być za kolarzem (mniejsze Z niż kolarz)
      expect(controller.position.z, lessThan(riderPose.position.z));
      final distanceBehind = riderPose.position.z - controller.position.z;
      expect(distanceBehind, closeTo(controller.chaseParams.distanceBack, 0.4));

      // Cel kamery powinien być przed kolarzem (większe Z niż kolarz)
      expect(controller.target.z, greaterThan(riderPose.position.z));

      // Wysokość kamery powinna być wyższa niż suport kolarza
      expect(controller.position.y, greaterThan(riderPose.position.y));
    });

    test('W trybie sprintu i ataku ChaseCam obniża pozycję i zwiększa FOV', () {
      final controllerNormal = CameraRigController(
        initialMode: RaceCameraMode.chaseCam,
      );
      final controllerSprint = CameraRigController(
        initialMode: RaceCameraMode.chaseCam,
      );

      final riderPose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 1000.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 50.0,
        ),
        roadGeometry: const RoadGeometryParameters(),
      );

      // 40 kroków symulacji (ok. 0.6s) dla obu kamer
      for (int i = 0; i < 40; i++) {
        controllerNormal.update(
          dtSeconds: 0.016,
          targetRiderPose: riderPose,
          isSprinting: false,
          isAttacking: false,
          riderSpeedMs: 12.0, // 43 km/h (normalna jazda)
        );

        controllerSprint.update(
          dtSeconds: 0.016,
          targetRiderPose: riderPose,
          isSprinting: true,
          isAttacking: true,
          riderSpeedMs: 18.0, // 65 km/h (sprint finiszowy)
        );
      }

      // W sprincie kamera powinna znajdować się niżej nad asfaltem
      expect(controllerSprint.position.y, lessThan(controllerNormal.position.y));
      final heightDiff = controllerNormal.position.y - controllerSprint.position.y;
      expect(heightDiff, closeTo(controllerSprint.chaseParams.sprintHeightDrop, 0.15));

      // W sprincie kąt widzenia FOV powinien być większy (speed zoom)
      expect(controllerSprint.fovDegrees, greaterThan(controllerNormal.fovDegrees));
      final fovDiff = controllerSprint.fovDegrees - controllerNormal.fovDegrees;
      expect(fovDiff, closeTo(controllerSprint.chaseParams.sprintFovBoostDegrees, 1.0));

      // W sprincie kamera przybliża się bliżej kolarza (tuck)
      final normalDist = (riderPose.position - controllerNormal.position).length;
      final sprintDist = (riderPose.position - controllerSprint.position).length;
      expect(sprintDist, lessThan(normalDist));
    });
  });

  group('CameraRigController - MotoTvCam (Motocykl TV 8m przed grupą)', () {
    test('MotoTvCam znajduje się 8 metrów przed liderem i filmuje wstecz', () {
      final controller = CameraRigController(
        initialMode: RaceCameraMode.motoTvCam,
      );

      final leaderPose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 1200.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 200.0,
        ),
        roadGeometry: const RoadGeometryParameters(),
      );

      for (int i = 0; i < 30; i++) {
        controller.update(
          dtSeconds: 0.016,
          targetRiderPose: leaderPose,
        );
      }

      // Motocykl jedzie przed kolarzem (większe Z niż lider)
      expect(controller.position.z, greaterThan(leaderPose.position.z));
      final leadDist = controller.position.z - leaderPose.position.z;
      expect(leadDist, closeTo(8.0, 0.5));

      // Motocykl jest lekko odsunięty w bok (lateral offset)
      final lateralDiff = (controller.position.x - leaderPose.position.x).abs();
      expect(lateralDiff, closeTo(controller.motoParams.lateralOffsetMeters, 0.25));

      // Wektor spojrzenia kamery (target - position) powinien być skierowany w tył (przeciwnie do jazdy)
      final lookDirection = (controller.target - controller.position)..normalize();
      final dotWithTangent = lookDirection.dot(leaderPose.tangent);
      expect(dotWithTangent, lessThan(-0.85)); // Silny zwrot wstecz
    });
  });

  group('CameraRigController - HeliCam (Helikopter i Wachlarze)', () {
    test('HeliCam krąży na dużej wysokości wokół centrum peletonu', () {
      final controller = CameraRigController(
        initialMode: RaceCameraMode.heliCam,
      );

      final pelotonCentroid = Vector3(10.0, 300.0, 5000.0);
      final dummyPose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 5000.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 300.0,
        ),
        roadGeometry: const RoadGeometryParameters(),
      );

      // Krok 1: Inicjalizacja
      controller.update(
        dtSeconds: 0.016,
        targetRiderPose: dummyPose,
        pelotonCentroid: pelotonCentroid,
        pelotonSpreadRadius: 20.0,
      );

      // Ustabilizowanie pozycji helikoptera
      for (int i = 0; i < 40; i++) {
        controller.update(
          dtSeconds: 0.05,
          targetRiderPose: dummyPose,
          pelotonCentroid: pelotonCentroid,
          pelotonSpreadRadius: 20.0,
        );
      }

      // Wysokość lotu nad terenem
      expect(controller.position.y, greaterThan(pelotonCentroid.y + 50.0));
      expect(controller.position.y - pelotonCentroid.y, closeTo(controller.heliParams.altitudeMeters, 5.0));

      // Punkt skupienia na centrum peletonu
      expect(controller.target.x, closeTo(pelotonCentroid.x, 2.0));
      expect(controller.target.z, closeTo(pelotonCentroid.z, 2.0));

      // Sprawdzenie, że helikopter przemieszcza się po orbicie wraz z upływem czasu
      final initialPos = Vector3.copy(controller.position);
      for (int i = 0; i < 60; i++) {
        controller.update(
          dtSeconds: 0.1,
          targetRiderPose: dummyPose,
          pelotonCentroid: pelotonCentroid,
        );
      }
      expect((controller.position - initialPos).length, greaterThan(2.0));
    });
  });

  group('CameraRigController - FinishLineCam (Teleobiektyw na Bramie Mety)', () {
    test('FinishLineCam zbliża zoom w miarę dojazdu sprintera do kreski', () {
      final controller = CameraRigController(
        initialMode: RaceCameraMode.finishLineCam,
      );

      final finishLine = Vector3(0.0, 10.0, 20000.0);
      final approachDir = Vector3(0.0, 0.0, 1.0);

      // Kolarz 150m przed metą
      final farSprinter = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 19850.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 10.0,
        ),
        roadGeometry: const RoadGeometryParameters(),
      );

      for (int i = 0; i < 30; i++) {
        controller.update(
          dtSeconds: 0.016,
          targetRiderPose: farSprinter,
          finishLinePosition: finishLine,
          finishApproachDirection: approachDir,
        );
      }

      final fovAt150m = controller.fovDegrees;

      // Kolarz 15m przed metą (rzut roweru)
      final nearSprinter = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 19985.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 10.0,
        ),
        roadGeometry: const RoadGeometryParameters(),
      );

      for (int i = 0; i < 40; i++) {
        controller.update(
          dtSeconds: 0.016,
          targetRiderPose: nearSprinter,
          finishLinePosition: finishLine,
          finishApproachDirection: approachDir,
        );
      }

      final fovAt15m = controller.fovDegrees;

      // Kamera na bramie mety powinna mocno zawęzić FOV (teleobiektyw zoom)
      expect(fovAt15m, lessThan(fovAt150m));
      expect(fovAt15m, lessThan(30.0));
      expect(fovAt15m, greaterThan(15.0));

      // Pozycja kamery powinna być statyczna na bramie mety (wysokość ~5.6m)
      expect(controller.position.y - finishLine.y, closeTo(controller.finishParams.gantryHeightMeters, 0.8));
    });
  });

  group('CameraRigController - Spring-Damper & Transitions', () {
    test('Przełączenie trybów kamer z animacją płynnie interpoluje pozycję', () {
      final controller = CameraRigController(
        initialMode: RaceCameraMode.chaseCam,
      );

      final riderPose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 500.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 50.0,
        ),
        roadGeometry: const RoadGeometryParameters(),
      );

      // Ustabilizowanie kamery startowej
      for (int i = 0; i < 20; i++) {
        controller.update(dtSeconds: 0.016, targetRiderPose: riderPose);
      }

      final chasePos = Vector3.copy(controller.position);

      // Przełączenie na HeliCam z czasem przejścia 1.0s
      controller.switchMode(RaceCameraMode.heliCam, transitionDurationSeconds: 1.0);

      expect(controller.isTransitioning, isTrue);
      expect(controller.activeMode, equals(RaceCameraMode.heliCam));
      expect(controller.previousMode, equals(RaceCameraMode.chaseCam));

      // W połowie przejścia (0.5s)
      for (int i = 0; i < 30; i++) {
        controller.update(dtSeconds: 0.016, targetRiderPose: riderPose);
      }

      expect(controller.isTransitioning, isTrue);
      expect(controller.transitionProgress, greaterThan(0.3));
      expect(controller.transitionProgress, lessThan(0.7));

      // Pozycja w trakcie przejścia powinna być pomiędzy Chase a Heli
      expect(controller.position.y, greaterThan(chasePos.y));

      // Dokończenie przejścia (kolejne 0.7s)
      for (int i = 0; i < 45; i++) {
        controller.update(dtSeconds: 0.016, targetRiderPose: riderPose);
      }

      expect(controller.isTransitioning, isFalse);
      expect(controller.transitionProgress, equals(1.0));
      expect(controller.position.y, greaterThan(chasePos.y + 40.0));
    });

    test('Przełączenie natychmiastowe immediate = true zeruje prędkości i transitionProgress', () {
      final controller = CameraRigController(
        initialMode: RaceCameraMode.chaseCam,
      );

      controller.switchMode(RaceCameraMode.finishLineCam, immediate: true);

      expect(controller.activeMode, equals(RaceCameraMode.finishLineCam));
      expect(controller.isTransitioning, isFalse);
      expect(controller.transitionProgress, equals(1.0));
    });

    test('toCameraConfig tworzy kompatybilny obiekt dla Scene3DMathProjection', () {
      final controller = CameraRigController();
      final projection = Scene3DMathProjection(viewportWidth: 1280.0, viewportHeight: 720.0);

      final config = controller.toCameraConfig();

      expect(config.position, equals(controller.position));
      expect(config.target, equals(controller.target));
      expect(config.fovYDegrees, equals(controller.fovDegrees));

      // Powinno się poprawnie zaaplikować do projekcji 3D
      projection.updateCamera(config, viewportWidth: 1280.0, viewportHeight: 720.0);
      expect(projection.cameraPosition, equals(controller.position));
    });
  });
}
