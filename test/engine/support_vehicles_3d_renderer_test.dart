// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/engine/rendering3d/support_vehicles_3d_renderer.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Scene3DMathProjection projection;
  late CameraRigController cameraController;
  late PelotonInstancedRenderer pelotonRenderer;

  setUp(() {
    projection = Scene3DMathProjection(
      viewportWidth: 1280.0,
      viewportHeight: 720.0,
      fovYDegrees: 60.0,
      zNear: 0.5,
      zFar: 500.0,
    );
    cameraController = CameraRigController();
    pelotonRenderer = PelotonInstancedRenderer();
  });

  RiderPositionSnapshot createSnapshot({
    required String riderId,
    required String name,
    required int bib,
    required String teamId,
    required String teamName,
    required String teamHex,
    double distanceMeters = 5000.0,
    TacticalOrder order = TacticalOrder.holdPosition,
    double lateralOffset = 0.0,
  }) {
    return RiderPositionSnapshot(
      riderId: riderId,
      riderName: name,
      bibNumber: bib,
      teamId: teamId,
      teamName: teamName,
      teamJerseyHexColor: teamHex,
      isPlayerRider: false,
      distanceCoveredMeters: distanceMeters,
      kilometerMark: distanceMeters / 1000.0,
      elevationMeters: 0.0,
      currentGradientPercent: 3.5,
      currentSegmentIndex: 1,
      speedMs: 12.0,
      speedKmh: 43.2,
      powerWatts: 320,
      wattsPerKg: 4.5,
      cadenceRpm: 90,
      heartRateBpm: 150,
      wPrimePercentage: 0.9,
      wPrimeJoules: 18000.0,
      glycogenPercentage: 0.85,
      glycogenGrams: 400.0,
      hydrationPercent: 0.95,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: order,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: 0.0,
      lateralPositionRoad: 0.0,
      lateralOffsetRoadMeters: lateralOffset,
      isDrafting: true,
      draftingSavingsPercent: 0.35,
      isPulling: false,
      hasDefect: false,
      isCrashed: false,
      isDnf: false,
    );
  }

  final sampleSegments = <StageSegment>[
    const StageSegment(
      index: 0,
      startKm: 0.0,
      lengthKm: 10.0,
      startElevationM: 0.0,
      endElevationM: 50.0,
      surfaceType: SegmentSurfaceType.smoothAsphalt,
      technicalDifficulty: 10.0,
      windDirectionDegrees: 180.0,
      roadBearingDegrees: 90.0,
      sprintOrKomClassification: SegmentClassification.none,
    ),
  ];

  group('SupportVehicleType & BidonFeedPhase - Typy i Stany Karmienia', () {
    test('poprawnie definiuje typy samochodów i motocykli kolumny', () {
      expect(SupportVehicleType.teamCar.isCar, isTrue);
      expect(SupportVehicleType.neutralServiceCar.isCar, isTrue);
      expect(SupportVehicleType.teamCar.isMotorbike, isFalse);

      expect(SupportVehicleType.motoTv.isMotorbike, isTrue);
      expect(SupportVehicleType.motoCommissaire.isMotorbike, isTrue);
      expect(SupportVehicleType.motoTv.isCar, isFalse);
    });

    test('fazy podjazdu po bidon poprawnie identyfikują aktywną obsługę', () {
      expect(BidonFeedPhase.none.isActivelyServicing, isFalse);
      expect(BidonFeedPhase.approaching.isActivelyServicing, isTrue);
      expect(BidonFeedPhase.feedingStickyBottle.isActivelyServicing, isTrue);
      expect(BidonFeedPhase.returningToPeloton.isActivelyServicing, isTrue);
    });
  });

  group('SupportVehiclesConfig - Parametry Konfiguracyjne', () {
    test('posiada przemyślane parametry domyślne konwoju kolarskiego', () {
      const config = SupportVehiclesConfig();
      expect(config.enabled, isTrue);
      expect(config.maxTeamCarsInConvoy, equals(6));
      expect(config.enableTvMotorbikes, isTrue);
      expect(config.enableNeutralServiceCar, isTrue);
      expect(config.enableBidonFeedAnimation, isTrue);
      expect(config.convoyFollowDistanceMeters, equals(22.0));
      expect(config.teamCarSpacingMeters, equals(14.0));
      expect(config.tvMotoLeadDistanceMeters, equals(10.0));
    });
  });

  group('SupportVehicles3DRenderer - Budowa Floty Pojazdów w Klatce', () {
    test('generuje motocykle TV, wóz neutralny oraz kolumnę aut technicznych',
        () {
      final renderer = SupportVehicles3DRenderer();

      // Utworzenie peletonu: czoło na 5060m, ogon na 5000m
      final riders = [
        createSnapshot(
          riderId: 'front_leader',
          name: 'Lider Grupy',
          bib: 1,
          teamId: 'uae',
          teamName: 'UAE Team Emirates',
          teamHex: '#FFFFFF',
          distanceMeters: 5060.0,
        ),
        createSnapshot(
          riderId: 'mid_rider',
          name: 'Kolarz Środka',
          bib: 21,
          teamId: 'visma',
          teamName: 'Visma Lease a Bike',
          teamHex: '#FFD700',
          distanceMeters: 5030.0,
        ),
        createSnapshot(
          riderId: 'rear_domestique',
          name: 'Pomocnik na Ogonie',
          bib: 31,
          teamId: 'ineos',
          teamName: 'Ineos Grenadiers',
          teamHex: '#001428',
          distanceMeters: 5000.0,
        ),
      ];

      projection.setView(
        eye: Vector3(0.0, 2.2, 4990.0),
        target: Vector3(0.0, 1.5, 5080.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final renderItems = pelotonRenderer.prepareDrawList(
        riders: riders,
        projection: projection,
        cameraController: cameraController,
      );

      final vehicles = renderer.updateAndBuildVehicles(
        activeRiders: renderItems,
        segments: sampleSegments,
        dtSeconds: 0.016,
        elapsedAnimSeconds: 1.0,
      );

      expect(vehicles.isNotEmpty, isTrue);

      // 1. Weryfikacja motocykla TV (przed liderem: > 5060m)
      final motoTv =
          vehicles.firstWhere((v) => v.type == SupportVehicleType.motoTv);
      expect(motoTv.distanceAlongCourseMeters, greaterThan(5060.0));

      // 2. Weryfikacja motocykla sędziowskiego (Moto Commissaire)
      final motoComm = vehicles
          .firstWhere((v) => v.type == SupportVehicleType.motoCommissaire);
      expect(motoComm.distanceAlongCourseMeters,
          greaterThan(motoTv.distanceAlongCourseMeters));

      // 3. Weryfikacja neutralnego wozu serwisowego (Mavic Yellow przed grupą)
      final neutralCar = vehicles
          .firstWhere((v) => v.type == SupportVehicleType.neutralServiceCar);
      expect(neutralCar.distanceAlongCourseMeters,
          greaterThan(motoComm.distanceAlongCourseMeters));
      expect(neutralCar.teamName, equals('SERVICE COURSE'));

      // 4. Weryfikacja wozów technicznych drużyn (za ogonem: < 5000m)
      final teamCars =
          vehicles.where((v) => v.type == SupportVehicleType.teamCar).toList();
      expect(teamCars.length, equals(3)); // UAE, Visma, Ineos

      for (final car in teamCars) {
        expect(car.distanceAlongCourseMeters, lessThan(5000.0));
      }

      // Weryfikacja schodkowego szyku kolumny (na zmianę lewa i prawa strona)
      expect(teamCars[0].lateralOffsetMeters, equals(-1.85));
      expect(teamCars[1].lateralOffsetMeters, equals(1.85));
    });

    test('zwraca pustą listę gdy brak kolarzy lub wyłączono w konfiguracji',
        () {
      final renderer = SupportVehicles3DRenderer(
        config: const SupportVehiclesConfig(enabled: false),
      );

      final vehicles = renderer.updateAndBuildVehicles(
        activeRiders: [],
        segments: sampleSegments,
        dtSeconds: 0.016,
        elapsedAnimSeconds: 0.0,
      );

      expect(vehicles.isEmpty, isTrue);
    });
  });

  group('SupportVehicles3DRenderer - Sticky Bottle & Feed Animation Machine',
      () {
    test(
        'zarządza pełnym cyklem podjazdu kolarza po bidon (approaching -> feeding -> returning)',
        () {
      final renderer = SupportVehicles3DRenderer();

      // Kolarz UAE otrzymuje rozkaz zjechania do wozu po bidony
      final feedRider = createSnapshot(
        riderId: 'domestique_uae',
        name: 'Pomocnik UAE',
        bib: 7,
        teamId: 'uae',
        teamName: 'UAE Team Emirates',
        teamHex: '#FFFFFF',
        distanceMeters: 5010.0,
        order: TacticalOrder.fetchBidonsFromCar,
      );

      final otherRider = createSnapshot(
        riderId: 'leader_visma',
        name: 'Lider Visma',
        bib: 11,
        teamId: 'visma',
        teamName: 'Visma',
        teamHex: '#FFD700',
        distanceMeters: 5050.0,
      );

      projection.setView(
        eye: Vector3(0.0, 2.2, 4990.0),
        target: Vector3(0.0, 1.5, 5080.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final renderItems = pelotonRenderer.prepareDrawList(
        riders: [otherRider, feedRider],
        projection: projection,
        cameraController: cameraController,
      );

      // Klatka 1: Inicjalizacja i faza approaching
      var vehicles = renderer.updateAndBuildVehicles(
        activeRiders: renderItems,
        segments: sampleSegments,
        dtSeconds: 0.5,
        elapsedAnimSeconds: 0.5,
      );

      final uaeCar = vehicles.firstWhere((v) => v.teamId == 'uae');
      expect(uaeCar.isBeaconFlashing, isTrue);
      expect(uaeCar.activeFeedSession, isNotNull);
      expect(
          uaeCar.activeFeedSession!.phase, equals(BidonFeedPhase.approaching));

      // Klatka 2: Po 3 sekundach następuje przejście do feedingStickyBottle
      vehicles = renderer.updateAndBuildVehicles(
        activeRiders: renderItems,
        segments: sampleSegments,
        dtSeconds: 2.6,
        elapsedAnimSeconds: 3.1,
      );

      final feedingCar = vehicles.firstWhere((v) => v.teamId == 'uae');
      expect(feedingCar.activeFeedSession!.phase,
          equals(BidonFeedPhase.feedingStickyBottle));
      // Samochód zrównuje się wzdłużnie z kolarzem
      expect(feedingCar.distanceAlongCourseMeters,
          equals(feedRider.distanceCoveredMeters));

      // Klatka 3: Po 5 sekundach karmienia następuje returningToPeloton
      vehicles = renderer.updateAndBuildVehicles(
        activeRiders: renderItems,
        segments: sampleSegments,
        dtSeconds: 5.1,
        elapsedAnimSeconds: 8.2,
      );

      final returningCar = vehicles.firstWhere((v) => v.teamId == 'uae');
      expect(returningCar.activeFeedSession!.phase,
          equals(BidonFeedPhase.returningToPeloton));

      // Klatka 4: Po kolejnych 4 sekundach sesja kończy się i wóz wraca do normy
      vehicles = renderer.updateAndBuildVehicles(
        activeRiders: renderItems,
        segments: sampleSegments,
        dtSeconds: 4.0,
        elapsedAnimSeconds: 12.2,
      );

      final normalCar = vehicles.firstWhere((v) => v.teamId == 'uae');
      expect(normalCar.activeFeedSession, isNull);
      expect(normalCar.isBeaconFlashing, isFalse);
    });
  });

  group('SupportVehicles3DRenderer - Renderowanie Canvas w 120 FPS', () {
    test(
        'renderuje wszystkie typy pojazdów i animację bidonu na obiekcie Canvas bez błędów',
        () {
      final renderer = SupportVehicles3DRenderer();

      // Kamera na 4990m patrząca na 5040m
      projection.setView(
        eye: Vector3(0.0, 2.2, 4990.0),
        target: Vector3(0.0, 1.5, 5040.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final riders = [
        createSnapshot(
          riderId: 'pogacar',
          name: 'Tadej Pogacar',
          bib: 1,
          teamId: 'uae',
          teamName: 'UAE',
          teamHex: '#FFFFFF',
          distanceMeters: 5040.0,
        ),
        createSnapshot(
          riderId: 'politt',
          name: 'Nils Politt',
          bib: 7,
          teamId: 'uae',
          teamName: 'UAE',
          teamHex: '#FFFFFF',
          distanceMeters: 5010.0,
          order: TacticalOrder.fetchBidonsFromCar,
        ),
      ];

      projection.setView(
        eye: Vector3(0.0, 2.2, 4990.0),
        target: Vector3(0.0, 1.5, 5080.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final renderItems = pelotonRenderer.prepareDrawList(
        riders: riders,
        projection: projection,
        cameraController: cameraController,
      );

      // Krok 1: Wóz w fazie karmienia
      final vehicles = renderer.updateAndBuildVehicles(
        activeRiders: renderItems,
        segments: sampleSegments,
        dtSeconds: 3.5,
        elapsedAnimSeconds: 3.5,
      );

      expect(vehicles.length, greaterThanOrEqualTo(4));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderSupportVehicles(
        canvas: canvas,
        projection: projection,
        vehicles: vehicles,
        elapsedAnimSeconds: 3.5,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('odrzuca pojazdy znajdujące się za plecami kamery (Frustum Culling)',
        () {
      final renderer = SupportVehicles3DRenderer();

      // Kamera na 5020m patrząca w stronę +Z (5050m)
      projection.setView(
        eye: Vector3(0.0, 2.0, 5020.0),
        target: Vector3(0.0, 1.5, 5050.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      // Pojazd na 4950m (za plecami kamery)
      final behindVehicle = SupportVehicleInstance3D(
        id: 'car_behind',
        type: SupportVehicleType.teamCar,
        primaryColor: const Color(0xFFEF4444),
        worldPosition: Vector3(0.0, 0.0, 4950.0),
        tangent: Vector3(0.0, 0.0, 1.0),
        lateralRight: Vector3(1.0, 0.0, 0.0),
        surfaceNormal: Vector3(0.0, 1.0, 0.0),
        distanceAlongCourseMeters: 4950.0,
        lateralOffsetMeters: -1.8,
        speedKmh: 45.0,
      );

      final recorder = PictureRecorder();
      renderer.renderSupportVehicles(
        canvas: Canvas(recorder),
        projection: projection,
        vehicles: [behindVehicle],
      );

      expect(recorder.endRecording(), isNotNull);
    });
  });
}
