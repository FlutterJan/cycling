// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';

void main() {
  group('Scene3DMathProjection - View, Projection & Matrix Math', () {
    test('tworzy domyślny rzut z poprawnymi proporcjami i macierzami', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 1920.0,
        viewportHeight: 1080.0,
        fovYDegrees: 60.0,
      );

      expect(projection.viewportWidth, equals(1920.0));
      expect(projection.viewportHeight, equals(1080.0));
      expect(projection.aspectRatio, closeTo(1920.0 / 1080.0, 1e-4));
      expect(projection.fovYDegrees, closeTo(60.0, 1e-4));

      // Macierze powinny być niepuste i mieć niezerowy wyznacznik
      expect(projection.viewMatrix.determinant(), isNot(equals(0.0)));
      expect(projection.projectionMatrix.determinant(), isNot(equals(0.0)));
      expect(projection.viewProjectionMatrix.determinant(), isNot(equals(0.0)));
      expect(projection.invertedViewProjectionMatrix.determinant(), isNot(equals(0.0)));
    });

    test('aktualizacja kamery przez setView zmienia pozycję i cel', () {
      final projection = Scene3DMathProjection();

      final eye = Vector3(10.0, 5.0, -20.0);
      final target = Vector3(10.0, 1.0, 0.0);
      final up = Vector3(0.0, 1.0, 0.0);

      projection.setView(eye: eye, target: target, up: up);

      expect(projection.cameraPosition.x, equals(10.0));
      expect(projection.cameraPosition.y, equals(5.0));
      expect(projection.cameraPosition.z, equals(-20.0));
      expect(projection.cameraTarget.z, equals(0.0));
    });

    test('aktualizacja rozmiaru rzutni setViewport przelicza aspect ratio', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 800.0,
        viewportHeight: 600.0,
      );
      expect(projection.aspectRatio, closeTo(4.0 / 3.0, 1e-4));

      projection.setViewport(width: 1280.0, height: 720.0);
      expect(projection.aspectRatio, closeTo(16.0 / 9.0, 1e-4));
    });
  });

  group('Scene3DMathProjection - World to Screen Projection', () {
    test('punkt na osi wzroku rzutuje się na środek ekranu', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 1000.0,
        viewportHeight: 500.0,
        fovYDegrees: 60.0,
      );

      // Kamera w (0, 2, -10), patrzy na (0, 2, 0)
      projection.setView(
        eye: Vector3(0.0, 2.0, -10.0),
        target: Vector3(0.0, 2.0, 0.0),
      );

      // Punkt leżący dokładnie na osi wzroku przed kamerą w Z = 0
      final targetPoint = Vector3(0.0, 2.0, 0.0);
      final projected = projection.worldToScreen(targetPoint);

      expect(projected.isInFrontOfCamera, isTrue);
      expect(projected.isInViewport, isTrue);
      // Środek ekranu (w/2 = 500, h/2 = 250)
      expect(projected.screenX, closeTo(500.0, 0.5));
      expect(projected.screenY, closeTo(250.0, 0.5));
      expect(projected.ndcX, closeTo(0.0, 1e-3));
      expect(projected.ndcY, closeTo(0.0, 1e-3));
      expect(projected.depthEye, closeTo(10.0, 0.1));
    });

    test('punkty po lewej i prawej stronie rzutują się symetrycznie względem osi', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 1000.0,
        viewportHeight: 600.0,
      );
      // Kamera w (0, 1.5, 5) patrzy wzdłuż -Z w stronę (0, 1.5, -10)
      projection.setView(
        eye: Vector3(0.0, 1.5, 5.0),
        target: Vector3(0.0, 1.5, -10.0),
      );

      final leftRider = Vector3(-2.0, 1.5, -5.0);
      final rightRider = Vector3(2.0, 1.5, -5.0);

      final pLeft = projection.worldToScreen(leftRider);
      final pRight = projection.worldToScreen(rightRider);

      expect(pLeft.isInViewport, isTrue);
      expect(pRight.isInViewport, isTrue);
      expect(pLeft.screenX, lessThan(500.0));
      expect(pRight.screenX, greaterThan(500.0));
      // Symetria odległości od środka (500px)
      final leftDist = 500.0 - pLeft.screenX;
      final rightDist = pRight.screenX - 500.0;
      expect(leftDist, closeTo(rightDist, 0.5));
    });

    test('punkt za plecami kamery nie jest rzutowany na ekran (isInFrontOfCamera = false)', () {
      final projection = Scene3DMathProjection();
      projection.setView(
        eye: Vector3(0.0, 1.5, 100.0),
        target: Vector3(0.0, 1.5, 200.0),
      );

      // Punkt w Z = 50.0 (za kamerą, bo kamera patrzy w stronę +Z)
      final behindPoint = Vector3(0.0, 1.5, 50.0);
      final projected = projection.worldToScreen(behindPoint);

      expect(projected.isInFrontOfCamera, isFalse);
      expect(projected.isInViewport, isFalse);
    });

    test('skala perspektywiczna maleje wraz z odległością od kamery', () {
      final projection = Scene3DMathProjection();
      projection.setView(
        eye: Vector3(0.0, 1.5, 0.0),
        target: Vector3(0.0, 1.5, 50.0),
      );

      final nearPoint = Vector3(0.0, 1.5, 5.0);
      final farPoint = Vector3(0.0, 1.5, 25.0);

      final pNear = projection.worldToScreen(nearPoint);
      final pFar = projection.worldToScreen(farPoint);

      expect(pNear.perspectiveScale, greaterThan(pFar.perspectiveScale));
      // Punkt 5 razy dalej powinien mieć ~5 razy mniejszą skalę
      final ratio = pNear.perspectiveScale / pFar.perspectiveScale;
      expect(ratio, closeTo(5.0, 0.2));
    });
  });

  group('Scene3DMathProjection - Screen to World Ray Casting & Picking', () {
    test('promień z centrum ekranu pokrywa się z osią celowania kamery', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 800.0,
        viewportHeight: 600.0,
      );
      final eye = Vector3(0.0, 2.0, -10.0);
      final target = Vector3(0.0, 2.0, 10.0);
      projection.setView(eye: eye, target: target);

      // Środek ekranu (400, 300)
      final ray = projection.screenToWorldRay(400.0, 300.0);

      // Promień powinien biec w kierunku osi +Z (0, 0, 1)
      expect(ray.direction.x, closeTo(0.0, 1e-3));
      expect(ray.direction.y, closeTo(0.0, 1e-3));
      expect(ray.direction.z, closeTo(1.0, 1e-3));
    });

    test('przecięcie promienia z poziomem drogi screenToGroundPoint', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 1000.0,
        viewportHeight: 1000.0,
      );
      // Kamera na wysokości 10m pochylona w dół
      projection.setView(
        eye: Vector3(0.0, 10.0, -10.0),
        target: Vector3(0.0, 0.0, 0.0),
      );

      // Kliknięcie w centrum ekranu powinno trafić w punkt (0, 0, 0)
      final hitPoint = projection.screenToGroundPoint(500.0, 500.0, groundElevationY: 0.0);

      expect(hitPoint, isNotNull);
      expect(hitPoint!.x, closeTo(0.0, 0.2));
      expect(hitPoint.y, closeTo(0.0, 1e-3));
      expect(hitPoint.z, closeTo(0.0, 0.2));
    });
  });

  group('Scene3DMathProjection - Frustum Culling', () {
    test('punkt w stożku widzenia jest wykrywany przez isPointInFrustum', () {
      final projection = Scene3DMathProjection(
        viewportWidth: 1000.0,
        viewportHeight: 600.0,
      );
      projection.setView(
        eye: Vector3(0.0, 2.0, 0.0),
        target: Vector3(0.0, 2.0, 50.0),
      );

      final insidePoint = Vector3(0.0, 2.0, 20.0);
      final outsideBehind = Vector3(0.0, 2.0, -10.0);
      final outsideFarSide = Vector3(100.0, 2.0, 20.0);

      expect(projection.isPointInFrustum(insidePoint), isTrue);
      expect(projection.isPointInFrustum(outsideBehind), isFalse);
      expect(projection.isPointInFrustum(outsideFarSide), isFalse);
    });

    test('kula przecinająca krawędź kadru jest wykrywana przez isSphereInFrustum', () {
      final projection = Scene3DMathProjection();
      projection.setView(
        eye: Vector3(0.0, 2.0, 0.0),
        target: Vector3(0.0, 2.0, 50.0),
      );

      // Kula na krawędzi stożka z dużym promieniem
      final centerNearEdge = Vector3(15.0, 2.0, 20.0);
      expect(projection.isSphereInFrustum(centerNearEdge, 10.0), isTrue);
      // Kula całkowicie za kamerą
      expect(projection.isSphereInFrustum(Vector3(0.0, 2.0, -50.0), 2.0), isFalse);
    });
  });

  group('Scene3DMathProjection - Course to 3D World Transformation', () {
    test('prosta droga płaska przekształca dystans na oś Z i pozycję boczną na oś X', () {
      // Prosta droga biegnąca wzdłuż osi +Z (azymut = 0)
      final pos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: 150.0,
        lateralOffsetMeters: -2.5, // 2.5m w lewo od osi jezdni
        elevationMeters: 750.0,
        turningRadiusMeters: double.infinity,
        gradientPercent: 0.0,
        baseBearingRadians: 0.0,
      );

      // Azymut 0 = w przód po +Z; wektor w prawo to +X, więc w lewo to -X
      expect(pos.x, closeTo(-2.5, 1e-4));
      expect(pos.y, closeTo(750.0, 1e-4));
      expect(pos.z, closeTo(150.0, 1e-4));
    });

    test('podjazd wznosi współrzędną Y i wpływa na wektor tangent', () {
      final pos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: 200.0,
        lateralOffsetMeters: 0.0,
        elevationMeters: 800.0,
        turningRadiusMeters: double.infinity,
        gradientPercent: 10.0, // 10% nachylenia
      );

      expect(pos.y, closeTo(800.0, 1e-4));
      expect(pos.z, closeTo(200.0, 1e-4));

      // Sprawdzenie orientacji kolarza na podjeździe
      final pose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: const CoursePosition(
          distanceMeters: 200.0,
          lateralOffsetMeters: 0.0,
          elevationMeters: 800.0,
        ),
        roadGeometry: const RoadGeometryParameters(
          turningRadiusMeters: double.infinity,
          gradientPercent: 10.0,
        ),
      );

      // Kąt wzniosu pitch = atan(0.10) ~ 0.09967 rad
      expect(pose.pitch, closeTo(math.atan(0.10), 1e-4));
      expect(pose.tangent.y, greaterThan(0.0)); // Styczny wektor patrzy w górę
    });

    test('zakręt w prawo (R > 0) powoduje odchylenie toru jazdy w prawo i wzrost azymutu', () {
      const double radius = 100.0;
      const double arcDistance = 50.0; // Pół radiana kąta zwrotu

      final offset = Scene3DMathProjection.computeArcHorizontalOffset(
        arcDistanceMeters: arcDistance,
        turningRadiusMeters: radius,
        initialBearingRadians: 0.0,
      );

      // Skręt w prawo z kierunku północnego (+Z) powinien dać dodatnie X (wschód)
      expect(offset.x, greaterThan(0.0));
      expect(offset.y, greaterThan(0.0)); // Przemieszczenie wzdłuż Z

      final heading = Scene3DMathProjection.computeRoadHeading(
        arcDistanceMeters: arcDistance,
        turningRadiusMeters: radius,
        initialBearingRadians: 0.0,
      );

      // Heading = s / R = 50 / 100 = 0.5 rad
      expect(heading, closeTo(0.5, 1e-4));
    });

    test('zakręt w lewo (R < 0) powoduje odchylenie toru jazdy w lewo', () {
      const double radius = -100.0; // Zakręt w lewo
      const double arcDistance = 50.0;

      final offset = Scene3DMathProjection.computeArcHorizontalOffset(
        arcDistanceMeters: arcDistance,
        turningRadiusMeters: radius,
        initialBearingRadians: 0.0,
      );

      // Skręt w lewo powinien dać ujemne X (zachód)
      expect(offset.x, lessThan(0.0));
      expect(offset.y, greaterThan(0.0)); // Ruch do przodu wzdłuż Z
    });

    test('serpentyna alpejska (hairpin R = 15m) po przebyciu półokręgu wykonuje zwrot o 180 stopni', () {
      const double radius = 15.0;
      const double halfTurnArc = math.pi * radius; // Długość łuku półokręgu: π * R

      final heading = Scene3DMathProjection.computeRoadHeading(
        arcDistanceMeters: halfTurnArc,
        turningRadiusMeters: radius,
        initialBearingRadians: 0.0,
      );

      // Kąt po 180° powinien wynosić dokładnie π rad
      expect(heading, closeTo(math.pi, 1e-4));

      final offset = Scene3DMathProjection.computeArcHorizontalOffset(
        arcDistanceMeters: halfTurnArc,
        turningRadiusMeters: radius,
        initialBearingRadians: 0.0,
      );

      // Po pełnym nawrocie o 180° w prawo:
      // Przemieszczenie boczne X = 2 * R = 30m, a wzdłużne Z wraca do 0!
      expect(offset.x, closeTo(2.0 * radius, 1e-3));
      expect(offset.y, closeTo(0.0, 1e-3));
    });

    test('fizyka pochylenia kolarza w zakręcie computeCyclistLeanAngle', () {
      // Na prostej kąt pochylenia wynosi 0
      final double leanStraight = Scene3DMathProjection.computeCyclistLeanAngle(
        speedMs: 15.0,
        turningRadiusMeters: double.infinity,
      );
      expect(leanStraight, equals(0.0));

      // W zakręcie o R = 50m przy v = 12 m/s (~43 km/h):
      // tan(θ) = v^2 / (g * R) = 144 / (9.81 * 50) = 144 / 490.5 = 0.2935
      // θ = atan(0.2935) ~ 0.285 rad (~16.3°)
      final leanRight = Scene3DMathProjection.computeCyclistLeanAngle(
        speedMs: 12.0,
        turningRadiusMeters: 50.0,
      );
      expect(leanRight, closeTo(math.atan(144.0 / (9.80665 * 50.0)), 1e-3));
      expect(leanRight, greaterThan(0.0)); // W prawo dodatni

      final leanLeft = Scene3DMathProjection.computeCyclistLeanAngle(
        speedMs: 12.0,
        turningRadiusMeters: -50.0,
      );
      expect(leanLeft, lessThan(0.0)); // W lewo ujemny
      expect(leanLeft.abs(), closeTo(leanRight, 1e-5));
    });
  });

  group('Scene3DMathProjection - Cyclist3DPose & Orthonormal Frame', () {
    test('wektory bazy Freneta są wzajemnie prostopadłe i jednostkowe', () {
      const coursePos = CoursePosition(
        distanceMeters: 350.0,
        lateralOffsetMeters: 1.2,
        elevationMeters: 1200.0,
      );
      const roadGeo = RoadGeometryParameters(
        turningRadiusMeters: 75.0,
        gradientPercent: 7.5,
        roadBearingRadians: 0.35,
        speedMs: 14.0,
      );

      final pose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: coursePos,
        roadGeometry: roadGeo,
      );

      // 1. Długości wektorów są jednostkowe (= 1.0)
      expect(pose.tangent.length, closeTo(1.0, 1e-5));
      expect(pose.lateralRight.length, closeTo(1.0, 1e-5));
      expect(pose.surfaceNormal.length, closeTo(1.0, 1e-5));

      // 2. Iloczyny skalarne = 0 (wektory są prostopadłe)
      expect(pose.tangent.dot(pose.lateralRight), closeTo(0.0, 1e-5));
      expect(pose.tangent.dot(pose.surfaceNormal), closeTo(0.0, 1e-5));
      expect(pose.lateralRight.dot(pose.surfaceNormal), closeTo(0.0, 1e-5));

      // 3. Sprawdzenie pozycji kół roweru (rozstaw ~1.0 m)
      final wheelDist = (pose.frontWheelContact - pose.rearWheelContact).length;
      expect(wheelDist, closeTo(1.0, 1e-4));

      // 4. Sprawdzenie pozycji głowy kolarza (powyżej środka suportu)
      expect(pose.headPosition.y, greaterThan(pose.position.y + 1.0));
    });

    test('przekrój poprzeczny szosy RoadCrossSection3D ma prawidłową szerokość', () {
      final crossSection = Scene3DMathProjection.computeRoadCrossSection(
        distanceMeters: 500.0,
        elevationMeters: 450.0,
        roadWidthMeters: 7.0,
        turningRadiusMeters: 120.0,
        gradientPercent: 4.0,
      );

      // Odległość między lewą a prawą krawędzią powinna wynosić dokładnie 7.0m
      final roadWidth = (crossSection.rightEdge - crossSection.leftEdge).length;
      expect(roadWidth, closeTo(7.0, 1e-3));

      // Środek szosy powinien znajdować się dokładnie w połowie szerokości
      final centerCalc = (crossSection.leftEdge + crossSection.rightEdge) * 0.5;
      expect((crossSection.center - centerCalc).length, closeTo(0.0, 1e-3));
    });
  });

  group('Scene3DMathProjection - Camera Rigs for Cycling Simulation', () {
    test('kamera Chase Cam ustawia się za kolarzem i patrzy w przód', () {
      final projection = Scene3DMathProjection();

      const coursePos = CoursePosition(
        distanceMeters: 1000.0,
        lateralOffsetMeters: 0.0,
        elevationMeters: 300.0,
      );
      final pose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: coursePos,
        roadGeometry: const RoadGeometryParameters(),
      );

      projection.setupChaseCamera(riderPose: pose, distanceBack: 5.0);

      // Kamera powinna znajdować się za kolarzem (mniejsze Z przy jeździe na północ)
      expect(projection.cameraPosition.z, lessThan(pose.position.z));
      // Obiektyw skupiony przed kolarzem (większe Z niż kolarz)
      expect(projection.cameraTarget.z, greaterThan(pose.position.z));
      // Kamera uniesiona ponad suport
      expect(projection.cameraPosition.y, greaterThan(pose.position.y));
    });

    test('kamera Moto TV Lead znajduje się przed liderem i patrzy w tył', () {
      final projection = Scene3DMathProjection();

      const coursePos = CoursePosition(
        distanceMeters: 500.0,
        lateralOffsetMeters: 0.0,
        elevationMeters: 100.0,
      );
      final pose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: coursePos,
        roadGeometry: const RoadGeometryParameters(),
      );

      projection.setupMotoTvCamera(leaderPose: pose, distanceAhead: 15.0);

      // Motocykl przed kolarzem (większe Z)
      expect(projection.cameraPosition.z, greaterThan(pose.position.z));
      // Cel kamery na kolarzu (mniejsze Z niż motocykl)
      expect(projection.cameraTarget.z, lessThan(projection.cameraPosition.z));
    });

    test('kamera Drone Cam znajduje się wysoko nad peletonem', () {
      final projection = Scene3DMathProjection();
      final pelotonCenter = Vector3(0.0, 200.0, 1500.0);

      projection.setupDroneCamera(pelotonCenter: pelotonCenter, altitude: 25.0);

      expect(projection.cameraPosition.y, closeTo(225.0, 1e-3));
      expect(projection.cameraTarget.y, closeTo(200.8, 1e-3));
    });

    test('kamera bramy mety Finish Gantry umieszczona jest na wysokości bramy', () {
      final projection = Scene3DMathProjection();
      final finishLine = Vector3(0.0, 50.0, 25000.0);
      final approach = Vector3(0.0, 0.0, 1.0); // Kolarze jadą od Z = 24900 w stronę Z = 25000

      projection.setupFinishGantryCamera(
        finishLinePosition: finishLine,
        roadApproachDirection: approach,
        height: 6.0,
        distanceBeforeLine: 18.0,
      );

      expect(projection.cameraPosition.y, closeTo(56.0, 1e-3));
      // Kamera spogląda w kierunku nadjeżdżających (przed metą)
      expect(projection.cameraTarget.z, lessThan(finishLine.z));
    });
  });
}
