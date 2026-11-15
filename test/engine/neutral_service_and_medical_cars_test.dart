import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/neutral_service_and_medical_cars.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

PelotonRenderItem _makeRider({
  required String id,
  required double distanceMeters,
  double speedKmh = 44.0,
  bool isCrashed = false,
}) {
  final pos = Scene3DMathProjection.courseToWorld3D(
    distanceMeters: distanceMeters,
    lateralOffsetMeters: 0.0,
    elevationMeters: 450.0,
  );
  return PelotonRenderItem(
    snapshot: RiderPositionSnapshot(
      riderId: id,
      riderName: 'Rider $id',
      bibNumber: 1,
      teamId: 't1',
      teamName: 'Team Test',
      teamJerseyHexColor: '#38BDF8',
      isPlayerRider: true,
      distanceCoveredMeters: distanceMeters,
      kilometerMark: distanceMeters / 1000.0,
      elevationMeters: 450.0,
      currentGradientPercent: 0.0,
      currentSegmentIndex: 0,
      speedMs: speedKmh / 3.6,
      speedKmh: speedKmh,
      powerWatts: 350,
      wattsPerKg: 5.1,
      cadenceRpm: 92,
      heartRateBpm: 162,
      wPrimePercentage: 0.9,
      wPrimeJoules: 18000,
      glycogenPercentage: 0.85,
      glycogenGrams: 350,
      hydrationPercent: 0.9,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: TacticalOrder.holdPosition,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: 0.0,
      lateralPositionRoad: 0.0,
      lateralOffsetRoadMeters: 0.0,
      isDrafting: true,
      draftingSavingsPercent: 25.0,
      isPulling: false,
      isCrashed: isCrashed,
    ),
    worldPosition: pos,
    tangent: Vector3(0, 0, 1),
    right: Vector3(1, 0, 0),
    up: Vector3(0, 1, 0),
    cameraDistance: 20.0,
    lodLevel: PelotonLodLevel.fullDetail,
    projectedCenter: const ProjectedPoint3D(
      screenX: 400,
      screenY: 300,
      ndcX: 0.0,
      ndcY: 0.0,
      ndcZ: 0.5,
      clipW: 20.0,
      depthEye: 20.0,
      perspectiveScale: 1.0,
      isInFrontOfCamera: true,
      isInViewport: true,
    ),
    screenScale: 1.0,
    isVisibleInFrustum: true,
    jerseyColor: const Color(0xFF38BDF8),
  );
}

List<StageSegment> _makeSegments() {
  return const [
    StageSegment(
      index: 0,
      startKm: 0.0,
      lengthKm: 50.0,
      startElevationM: 450.0,
      endElevationM: 650.0,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      technicalDifficulty: 20.0,
      windDirectionDegrees: 90.0,
      roadBearingDegrees: 0.0,
      sprintOrKomClassification: SegmentClassification.none,
    ),
  ];
}

void main() {
  group('NeutralServiceAndMedicalCarsController', () {
    test('spawns yellow/blue neutral cars, ambulance, and red-roof commissaire cars ahead and behind peloton', () {
      final controller = NeutralServiceAndMedicalCarsController();
      final riders = [
        _makeRider(id: 'r1', distanceMeters: 1200.0),
        _makeRider(id: 'r2', distanceMeters: 1190.0),
        _makeRider(id: 'r3', distanceMeters: 1180.0),
      ];

      final vehicles = controller.updateVehicles(
        activeRiders: riders,
        segments: _makeSegments(),
        dtSeconds: 0.016,
        elapsedSeconds: 1.0,
      );

      expect(vehicles.length, 5);

      final yellow = vehicles.firstWhere(
          (v) => v.role == RaceConvoyVehicleRole.neutralServiceYellow);
      final blue = vehicles.firstWhere(
          (v) => v.role == RaceConvoyVehicleRole.neutralServiceBlue);
      final ambulance = vehicles.firstWhere(
          (v) => v.role == RaceConvoyVehicleRole.medicalAmbulance);
      final commissaires = vehicles
          .where((v) => v.role == RaceConvoyVehicleRole.commissaireCar)
          .toList();

      expect(commissaires.length, 2);
      expect(yellow.roofBikeCount, 4);
      expect(blue.roofBikeCount, 4);
      expect(yellow.placementZone, ConvoyPlacementZone.aheadOfLeadGroup);
      expect(yellow.distanceAlongCourseMeters, greaterThan(1200.0));

      expect(ambulance.placementZone, ConvoyPlacementZone.behindPeloton);
      expect(ambulance.distanceAlongCourseMeters, lessThan(1180.0));
      expect(ambulance.isEmergencyBeaconActive, isTrue);

      // Commissaire car has distinctive red roof and covers ahead & behind
      for (final c in commissaires) {
        expect(c.roofColor, const Color(0xFFDC2626));
      }
      expect(
        commissaires.any(
            (c) => c.placementZone == ConvoyPlacementZone.aheadOfLeadGroup),
        isTrue,
      );
      expect(
        commissaires
            .any((c) => c.placementZone == ConvoyPlacementZone.behindPeloton),
        isTrue,
      );
    });

    test('places blue neutral service car between breakaway and peloton when gap is large', () {
      final controller = NeutralServiceAndMedicalCarsController();
      final riders = [
        _makeRider(id: 'break_1', distanceMeters: 1500.0, speedKmh: 47.0),
        _makeRider(id: 'break_2', distanceMeters: 1495.0, speedKmh: 47.0),
        _makeRider(id: 'peloton_1', distanceMeters: 1350.0, speedKmh: 43.0),
        _makeRider(id: 'peloton_2', distanceMeters: 1335.0, speedKmh: 43.0),
      ];

      final vehicles = controller.updateVehicles(
        activeRiders: riders,
        segments: _makeSegments(),
        dtSeconds: 0.016,
        elapsedSeconds: 2.0,
      );

      final blue = vehicles.firstWhere(
          (v) => v.role == RaceConvoyVehicleRole.neutralServiceBlue);

      expect(controller.latestMetrics?.hasBreakawayGroup, isTrue);
      expect(blue.placementZone, ConvoyPlacementZone.betweenGroups);
      expect(blue.distanceAlongCourseMeters, lessThan(1495.0));
      expect(blue.distanceAlongCourseMeters, greaterThan(1350.0));
    });

    test('renders all vehicles in 3D onto Canvas without throwing', () {
      final controller = NeutralServiceAndMedicalCarsController();
      final riders = [
        _makeRider(id: 'r1', distanceMeters: 1020.0, isCrashed: true),
        _makeRider(id: 'r2', distanceMeters: 1000.0),
      ];
      final vehicles = controller.updateVehicles(
        activeRiders: riders,
        segments: _makeSegments(),
        dtSeconds: 0.016,
        elapsedSeconds: 3.5,
      );

      final projection = Scene3DMathProjection();
      projection.updateCamera(
        Camera3DConfig(
          position: Vector3(0.0, 6.0, 975.0),
          target: Vector3(0.0, 2.0, 1025.0),
          fovYDegrees: 60.0,
        ),
        viewportWidth: 1600.0,
        viewportHeight: 900.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => controller.renderVehicles(
          canvas: canvas,
          projection: projection,
          vehicles: vehicles,
          elapsedAnimSeconds: 3.5,
        ),
        returnsNormally,
      );

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('returns empty list when activeRiders is empty or disabled', () {
      final controller = NeutralServiceAndMedicalCarsController();
      expect(
        controller.updateVehicles(
          activeRiders: const [],
          segments: _makeSegments(),
          dtSeconds: 0.016,
          elapsedSeconds: 0.0,
        ),
        isEmpty,
      );
    });
  });
}
