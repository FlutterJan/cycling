// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/rider_floating_labels_overlay.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
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
    double distanceMeters = 5000.0,
    double elevationMeters = 0.0,
    bool isPlayer = false,
    int power = 300,
    double wkg = 4.2,
    TacticalOrder order = TacticalOrder.holdPosition,
    bool isPulling = false,
  }) {
    return RiderPositionSnapshot(
      riderId: riderId,
      riderName: name,
      bibNumber: bib,
      teamId: 'team_uae',
      teamName: 'UAE Team Emirates',
      teamJerseyHexColor: '#FFFFFF',
      isPlayerRider: isPlayer,
      distanceCoveredMeters: distanceMeters,
      kilometerMark: distanceMeters / 1000.0,
      elevationMeters: elevationMeters,
      currentGradientPercent: 4.5,
      currentSegmentIndex: 1,
      speedMs: 12.0,
      speedKmh: 43.2,
      powerWatts: power,
      wattsPerKg: wkg,
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
      lateralOffsetRoadMeters: 0.0,
      isDrafting: true,
      draftingSavingsPercent: 0.35,
      isPulling: isPulling,
      hasDefect: false,
      isCrashed: false,
      isDnf: false,
    );
  }

  group('LeaderJerseyType - Klasyfikacje i Koszulki Liderów', () {
    test('poprawnie definiuje koszulki wielkich tourów i ich kolory', () {
      expect(LeaderJerseyType.none.isLeader, isFalse);
      expect(LeaderJerseyType.yellowGC.isLeader, isTrue);
      expect(LeaderJerseyType.yellowGC.shortTag, equals('GC'));
      expect(LeaderJerseyType.yellowGC.primaryColor, equals(const Color(0xFFFFD700)));

      expect(LeaderJerseyType.greenPoints.isLeader, isTrue);
      expect(LeaderJerseyType.greenPoints.shortTag, equals('SPRINT'));

      expect(LeaderJerseyType.polkaDotKOM.isLeader, isTrue);
      expect(LeaderJerseyType.polkaDotKOM.shortTag, equals('KOM'));

      expect(LeaderJerseyType.whiteYoung.isLeader, isTrue);
      expect(LeaderJerseyType.whiteYoung.shortTag, equals('U25'));

      expect(LeaderJerseyType.pinkGC.isLeader, isTrue);
      expect(LeaderJerseyType.redGC.isLeader, isTrue);
    });
  });

  group('TacticalActionState - Stany Taktyczne Kolarzy', () {
    test('zawiera stany ataku, osłony aerodynamicznej i pościgu', () {
      expect(TacticalActionState.values, contains(TacticalActionState.none));
      expect(TacticalActionState.values, contains(TacticalActionState.attacking));
      expect(TacticalActionState.values, contains(TacticalActionState.shelteringLeader));
      expect(TacticalActionState.values, contains(TacticalActionState.chasingBreakaway));
    });
  });

  group('RiderFloatingLabelsConfig - Parametry Konfiguracyjne', () {
    test('posiada przemyślane wartości domyślne dla 120 FPS', () {
      const config = RiderFloatingLabelsConfig();
      expect(config.enabled, isTrue);
      expect(config.maxLabelDistanceMeters, equals(55.0));
      expect(config.fullDetailDistanceMeters, equals(32.0));
      expect(config.showPlayerRiderAlways, isTrue);
      expect(config.showSelectedRiderAlways, isTrue);
      expect(config.showLeaderJerseys, isTrue);
      expect(config.showTacticalIcons, isTrue);
      expect(config.showWkgPill, isTrue);
      expect(config.showCountryFlag, isTrue);
      expect(config.headOffsetMeters, equals(1.95));
      expect(config.maxLabelsOnScreen, equals(24));
      expect(config.ftpWatts, equals(390));
    });

    test('pozwala na dostosowanie parametrów widoczności', () {
      const custom = RiderFloatingLabelsConfig(
        enabled: false,
        maxLabelDistanceMeters: 40.0,
        showCountryFlag: false,
        maxLabelsOnScreen: 10,
      );
      expect(custom.enabled, isFalse);
      expect(custom.maxLabelDistanceMeters, equals(40.0));
      expect(custom.showCountryFlag, isFalse);
      expect(custom.maxLabelsOnScreen, equals(10));
    });
  });

  group('CountryFlagHelper - Detekcja Narodowości i Flag', () {
    test('rozpoznaje kody państw UCI / ISO', () {
      final slo = CountryFlagHelper.resolveCountry(explicitCountryIso: 'SLO');
      expect(slo.$1, equals('🇸🇮'));
      expect(slo.$2, equals('SLO'));

      final den = CountryFlagHelper.resolveCountry(explicitCountryIso: 'DEN');
      expect(den.$1, equals('🇩🇰'));
      expect(den.$2, equals('DEN'));

      final pol = CountryFlagHelper.resolveCountry(explicitCountryIso: 'POL');
      expect(pol.$1, equals('🇵🇱'));
      expect(pol.$2, equals('POL'));

      final bel = CountryFlagHelper.resolveCountry(explicitCountryIso: 'BEL');
      expect(bel.$1, equals('🇧🇪'));
      expect(bel.$2, equals('BEL'));

      final fra = CountryFlagHelper.resolveCountry(explicitCountryIso: 'FRA');
      expect(fra.$1, equals('🇫🇷'));
      expect(fra.$2, equals('FRA'));
    });

    test('wnioskuje narodowość z nazwisk gwiazd peletonu', () {
      expect(CountryFlagHelper.resolveCountry(riderName: 'Tadej Pogačar').$1, equals('🇸🇮'));
      expect(CountryFlagHelper.resolveCountry(riderName: 'Jonas Vingegaard').$1, equals('🇩🇰'));
      expect(CountryFlagHelper.resolveCountry(riderName: 'Michał Kwiatkowski').$1, equals('🇵🇱'));
      expect(CountryFlagHelper.resolveCountry(riderName: 'Wout van Aert').$1, equals('🇧🇪'));
      expect(CountryFlagHelper.resolveCountry(riderName: 'Mathieu van der Poel').$1, equals('🇳🇱'));
      expect(CountryFlagHelper.resolveCountry(riderName: 'Julian Alaphilippe').$1, equals('🇫🇷'));
      expect(CountryFlagHelper.resolveCountry(riderName: 'Filippo Ganna').$1, equals('🇮🇹'));
      expect(CountryFlagHelper.resolveCountry(riderName: 'Sepp Kuss').$1, equals('🇺🇸'));
    });

    test('zwraca poprawny fallback dla nieznanych kolarzy', () {
      final fallback = CountryFlagHelper.resolveCountry(riderName: 'Jan Kowal');
      expect(fallback.$1, equals('🏳️'));
      expect(fallback.$2, equals('PRO'));

      final customIso = CountryFlagHelper.resolveCountry(explicitCountryIso: 'XYZ');
      expect(customIso.$1, equals('🏳️'));
      expect(customIso.$2, equals('XYZ'));
    });
  });

  group('RiderFloatingLabelsOverlay - Filtrowanie, Culling i Renderowanie Canvas', () {
    test('nie rysuje nic, gdy etykiety są wyłączone w konfiguracji', () {
      final overlay = RiderFloatingLabelsOverlay(
        config: const RiderFloatingLabelsConfig(enabled: false),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      overlay.renderFloatingLabels(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        renderItems: [],
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('rysuje etykiety dla kolarzy w polu widzenia kamery', () {
      final overlay = RiderFloatingLabelsOverlay();

      // Kamera na 4985m, kolarze na 5000m (+15m przed kamerą)
      projection.setView(
        eye: Vector3(0.0, 2.2, 4985.0),
        target: Vector3(0.0, 1.2, 5010.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final rLeader = createSnapshot(
        riderId: 'pogacar',
        name: 'Tadej Pogacar',
        bib: 1, // Domyślnie GC
        distanceMeters: 5000.0,
        isPlayer: true,
        power: 450,
        wkg: 6.8,
      );

      final rSprinter = createSnapshot(
        riderId: 'philipsen',
        name: 'Jasper Philipsen',
        bib: 21, // Domyślnie Green Points
        distanceMeters: 5002.0,
        power: 320,
        wkg: 4.1,
      );

      final rClimber = createSnapshot(
        riderId: 'carapaz',
        name: 'Richard Carapaz',
        bib: 31, // Domyślnie KOM
        distanceMeters: 4998.0,
        power: 380,
        wkg: 5.9,
      );

      final rAttacker = createSnapshot(
        riderId: 'evenepoel',
        name: 'Remco Evenepoel',
        bib: 51,
        distanceMeters: 5005.0,
        power: 580,
        wkg: 9.1,
        order: TacticalOrder.attack,
      );

      final rHelper = createSnapshot(
        riderId: 'politt',
        name: 'Nils Politt',
        bib: 5,
        distanceMeters: 5004.0,
        power: 420,
        wkg: 5.0,
        order: TacticalOrder.protectLeader,
        isPulling: true,
      );

      final riders = [rLeader, rSprinter, rClimber, rAttacker, rHelper];

      final items = pelotonRenderer.prepareDrawList(
        riders: riders,
        projection: projection,
        cameraController: cameraController,
      );

      expect(items.length, equals(5));

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Renderowanie z różnymi flagami i parametrami czasu animacji
      overlay.renderFloatingLabels(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        renderItems: items,
        selectedRiderId: 'pogacar',
        playerRiderIds: const ['pogacar'],
        leaderJerseys: const {
          'pogacar': LeaderJerseyType.yellowGC,
          'philipsen': LeaderJerseyType.greenPoints,
          'carapaz': LeaderJerseyType.polkaDotKOM,
        },
        riderNationalities: const {
          'pogacar': 'SLO',
          'philipsen': 'BEL',
          'carapaz': 'ECU',
          'evenepoel': 'BEL',
          'politt': 'GER',
        },
        animSeconds: 1.25,
      );

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('odrzuca kolarzy znajdujących się za plecami kamery (Frustum Culling)', () {
      final overlay = RiderFloatingLabelsOverlay();

      // Kamera na 5010m patrząca w przód (+Z) na 5050m
      projection.setView(
        eye: Vector3(0.0, 2.0, 5010.0),
        target: Vector3(0.0, 1.2, 5050.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      // Kolarz na 4950m (za plecami kamery)
      final rBehind = createSnapshot(
        riderId: 'behind_cam',
        name: 'Kolarz Z Tyłu',
        bib: 99,
        distanceMeters: 4950.0,
      );

      final items = pelotonRenderer.prepareDrawList(
        riders: [rBehind],
        projection: projection,
        cameraController: cameraController,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      overlay.renderFloatingLabels(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        renderItems: items,
      );

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('zawsze renderuje kolarza gracza oraz zaznaczonego kolarza nawet na dużym dystansie', () {
      final overlay = RiderFloatingLabelsOverlay(
        config: const RiderFloatingLabelsConfig(
          maxLabelDistanceMeters: 40.0,
          showPlayerRiderAlways: true,
          showSelectedRiderAlways: true,
        ),
      );

      // Kamera na 4900m patrząca na 5000m
      projection.setView(
        eye: Vector3(0.0, 2.0, 4900.0),
        target: Vector3(0.0, 1.2, 5000.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      // Kolarz na 4980m (odległość = 80m > maxLabelDistanceMeters 40m)
      final rPlayerFar = createSnapshot(
        riderId: 'player_far',
        name: 'Gracz Daleko',
        bib: 10,
        distanceMeters: 4980.0,
        isPlayer: true,
      );

      final rOpponentFar = createSnapshot(
        riderId: 'opponent_far',
        name: 'Rywal Daleko',
        bib: 11,
        distanceMeters: 4980.0,
        isPlayer: false,
      );

      final items = pelotonRenderer.prepareDrawList(
        riders: [rPlayerFar, rOpponentFar],
        projection: projection,
        cameraController: cameraController,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      overlay.renderFloatingLabels(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        renderItems: items,
        playerRiderIds: const ['player_far'],
      );

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('obsługuje koszulki U25, Rosa i Roja oraz strefy mocy Coggana', () {
      final overlay = RiderFloatingLabelsOverlay();

      projection.setView(
        eye: Vector3(0.0, 2.0, 4980.0),
        target: Vector3(0.0, 1.2, 5020.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final rU25 = createSnapshot(
        riderId: 'ayuso',
        name: 'Juan Ayuso',
        bib: 44,
        distanceMeters: 5000.0,
        power: 500, // Z6
        wkg: 7.5,
      );

      final rRosa = createSnapshot(
        riderId: 'del_toro',
        name: 'Isaac Del Toro',
        bib: 45,
        distanceMeters: 5002.0,
        power: 180, // Z1
        wkg: 2.8,
      );

      final items = pelotonRenderer.prepareDrawList(
        riders: [rU25, rRosa],
        projection: projection,
        cameraController: cameraController,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      overlay.renderFloatingLabels(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        renderItems: items,
        leaderJerseys: const {
          'ayuso': LeaderJerseyType.whiteYoung,
          'del_toro': LeaderJerseyType.pinkGC,
        },
      );

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });

    test('ogranicza liczbę etykiet do maxLabelsOnScreen zachowując priorytety', () {
      const maxLabels = 5;
      final overlay = RiderFloatingLabelsOverlay(
        config: const RiderFloatingLabelsConfig(maxLabelsOnScreen: maxLabels),
      );

      projection.setView(
        eye: Vector3(0.0, 2.0, 4980.0),
        target: Vector3(0.0, 1.2, 5020.0),
        up: Vector3(0.0, 1.0, 0.0),
      );

      final riders = List.generate(15, (index) {
        return createSnapshot(
          riderId: 'rider_$index',
          name: 'Kolarz $index',
          bib: index + 1,
          distanceMeters: 4990.0 + (index * 2.0),
          isPlayer: index == 0,
        );
      });

      final items = pelotonRenderer.prepareDrawList(
        riders: riders,
        projection: projection,
        cameraController: cameraController,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      overlay.renderFloatingLabels(
        canvas: canvas,
        size: const Size(1280.0, 720.0),
        projection: projection,
        renderItems: items,
        selectedRiderId: 'rider_0',
      );

      final pic = recorder.endRecording();
      expect(pic, isNotNull);
    });
  });
}
