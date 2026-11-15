// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/race_incident_engine.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/rendering3d/crash_and_mechanical_visuals.dart';
import 'package:pro_peloton_manager/engine/rendering3d/peloton_instanced_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/scene_3d_math_projection.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/state/race_simulation_notifier.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Scene3DMathProjection projection;
  late CameraRigController cameraController;
  late List<StageSegment> sampleSegments;

  setUp(() {
    projection = Scene3DMathProjection(
      viewportWidth: 1280.0,
      viewportHeight: 720.0,
      fovYDegrees: 60.0,
      zNear: 0.5,
      zFar: 500.0,
    );
    // Ustawienie kamery za kolarzami (Z = 4985, patrząca w kierunku Z = 5050)
    projection.setView(
      eye: Vector3(0.0, 2.4, 4985.0),
      target: Vector3(0.0, 1.5, 5050.0),
      up: Vector3(0.0, 1.0, 0.0),
    );

    cameraController = CameraRigController();

    sampleSegments = const [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 10.0,
        startElevationM: 400.0,
        endElevationM: 450.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
    ];
  });

  RiderPositionSnapshot createSnapshot({
    required String riderId,
    required String name,
    required int bib,
    required String teamId,
    required String teamName,
    required String teamHex,
    double distanceMeters = 5000.0,
    double lateralOffset = 0.0,
    double speedMs = 12.5,
    bool hasDefect = false,
    IncidentType? defectType,
    bool isCrashed = false,
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
      currentGradientPercent: 2.0,
      currentSegmentIndex: 0,
      speedMs: speedMs,
      speedKmh: speedMs * 3.6,
      powerWatts: 350,
      wattsPerKg: 5.0,
      cadenceRpm: 90,
      heartRateBpm: 155,
      wPrimePercentage: 0.85,
      wPrimeJoules: 18000.0,
      glycogenPercentage: 0.8,
      glycogenGrams: 380.0,
      hydrationPercent: 0.9,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: TacticalOrder.holdPosition,
      groupIndex: 0,
      groupType: GroupType.peloton,
      timeGapToLeaderSeconds: 0.0,
      lateralPositionRoad: (lateralOffset / 3.6).clamp(-1.0, 1.0),
      lateralOffsetRoadMeters: lateralOffset,
      isDrafting: false,
      draftingSavingsPercent: 0.0,
      isPulling: false,
      hasDefect: hasDefect,
      defectType: defectType,
      isCrashed: isCrashed,
      isDnf: false,
    );
  }

  group('Crash and Mechanical Visuals - Enums & Models', () {
    test('MechanicalIncidentPhase properties', () {
      expect(MechanicalIncidentPhase.signalingAndDriftingToVerge.isOngoing, isTrue);
      expect(MechanicalIncidentPhase.signalingAndDriftingToVerge.isMechanicActive, isFalse);

      expect(MechanicalIncidentPhase.awaitingServiceAtVerge.isOngoing, isTrue);
      expect(MechanicalIncidentPhase.awaitingServiceAtVerge.isMechanicActive, isFalse);

      expect(MechanicalIncidentPhase.mechanicRunningWithWheel.isOngoing, isTrue);
      expect(MechanicalIncidentPhase.mechanicRunningWithWheel.isMechanicActive, isTrue);

      expect(MechanicalIncidentPhase.mechanicReplacingWheel.isOngoing, isTrue);
      expect(MechanicalIncidentPhase.mechanicReplacingWheel.isMechanicActive, isTrue);

      expect(MechanicalIncidentPhase.pushOffAndAcceleration.isOngoing, isTrue);
      expect(MechanicalIncidentPhase.pushOffAndAcceleration.isMechanicActive, isTrue);

      expect(MechanicalIncidentPhase.resolved.isOngoing, isFalse);
      expect(MechanicalIncidentPhase.resolved.isMechanicActive, isFalse);
      expect(MechanicalIncidentPhase.resolved.defaultDurationSeconds, equals(0.0));
    });

    test('CrashIncidentPhase properties', () {
      expect(CrashIncidentPhase.tumbleAndSlide.isOngoing, isTrue);
      expect(CrashIncidentPhase.tumbleAndSlide.isDownOnTarmac, isTrue);
      expect(CrashIncidentPhase.tumbleAndSlide.isRecovering, isFalse);

      expect(CrashIncidentPhase.lyingOnTarmac.isOngoing, isTrue);
      expect(CrashIncidentPhase.lyingOnTarmac.isDownOnTarmac, isTrue);
      expect(CrashIncidentPhase.lyingOnTarmac.isRecovering, isFalse);

      expect(CrashIncidentPhase.standingAndInspectingBike.isOngoing, isTrue);
      expect(CrashIncidentPhase.standingAndInspectingBike.isDownOnTarmac, isFalse);
      expect(CrashIncidentPhase.standingAndInspectingBike.isRecovering, isTrue);

      expect(CrashIncidentPhase.adjustingHandlebarAndChain.isOngoing, isTrue);
      expect(CrashIncidentPhase.adjustingHandlebarAndChain.isDownOnTarmac, isFalse);
      expect(CrashIncidentPhase.adjustingHandlebarAndChain.isRecovering, isTrue);

      expect(CrashIncidentPhase.remountingAndStartingSlow.isOngoing, isTrue);
      expect(CrashIncidentPhase.remountingAndStartingSlow.isDownOnTarmac, isFalse);
      expect(CrashIncidentPhase.remountingAndStartingSlow.isRecovering, isTrue);

      expect(CrashIncidentPhase.slowAcceleration.isOngoing, isTrue);
      expect(CrashIncidentPhase.slowAcceleration.isDownOnTarmac, isFalse);
      expect(CrashIncidentPhase.slowAcceleration.isRecovering, isFalse);

      expect(CrashIncidentPhase.resolved.isOngoing, isFalse);
      expect(CrashIncidentPhase.resolved.isDownOnTarmac, isFalse);
      expect(CrashIncidentPhase.resolved.isRecovering, isFalse);
      expect(CrashIncidentPhase.resolved.defaultDurationSeconds, equals(0.0));
    });

    test('CrashAndMechanicalConfig default and custom values', () {
      const defaultConfig = CrashAndMechanicalConfig();
      expect(defaultConfig.enabled, isTrue);
      expect(defaultConfig.enableTeamCarAndMechanic, isTrue);
      expect(defaultConfig.enableRollingBidons, isTrue);
      expect(defaultConfig.enableWarningFlags, isTrue);
      expect(defaultConfig.roadVergeOffsetMeters, equals(3.6));
      expect(defaultConfig.animationSpeedMultiplier, equals(1.0));

      const customConfig = CrashAndMechanicalConfig(
        enabled: false,
        enableTeamCarAndMechanic: false,
        enableRollingBidons: false,
        enableWarningFlags: false,
        roadVergeOffsetMeters: 4.2,
        animationSpeedMultiplier: 2.0,
      );
      expect(customConfig.enabled, isFalse);
      expect(customConfig.enableTeamCarAndMechanic, isFalse);
      expect(customConfig.enableRollingBidons, isFalse);
      expect(customConfig.enableWarningFlags, isFalse);
      expect(customConfig.roadVergeOffsetMeters, equals(4.2));
      expect(customConfig.animationSpeedMultiplier, equals(2.0));
    });

    test('ActiveMechanicalIncident and ActiveCrashIncident model instantiation', () {
      final mech = ActiveMechanicalIncident(
        riderId: 'rider_1',
        riderName: 'T. Pogacar',
        bibNumber: 1,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        teamColorHex: '#FFFFFF',
        defectType: IncidentType.punctureFlatTire,
        incidentDistanceMeters: 5120.0,
        currentLateralOffsetMeters: 1.2,
      );
      expect(mech.riderId, equals('rider_1'));
      expect(mech.phase, equals(MechanicalIncidentPhase.signalingAndDriftingToVerge));
      expect(mech.targetVergeLateralOffset, equals(3.6));
      expect(mech.totalProgress, equals(0.0));

      final crash = ActiveCrashIncident(
        riderId: 'rider_2',
        riderName: 'J. Vingegaard',
        bibNumber: 11,
        teamId: 'team_visma',
        teamName: 'Visma Lease a Bike',
        teamColorHex: '#FFFF00',
        crashType: IncidentType.pelotonPileup,
        crashDistanceMeters: 5150.0,
        lateralOffsetMeters: -0.8,
      );
      expect(crash.riderId, equals('rider_2'));
      expect(crash.phase, equals(CrashIncidentPhase.tumbleAndSlide));
      expect(crash.bikeRotationAngle, greaterThan(0.0));
      expect(crash.totalProgress, equals(0.0));
    });
  });

  group('Mechanical Incident State Machine', () {
    test('Drift to verge, wheel swap with mechanic, push-off and resolve', () {
      final renderer = CrashAndMechanicalVisualsRenderer();

      final riderSnapshot = createSnapshot(
        riderId: 'rider_pog',
        name: 'Tadej Pogacar',
        bib: 1,
        teamId: 'uae',
        teamName: 'UAE',
        teamHex: '#E2E8F0',
        distanceMeters: 5010.0,
        lateralOffset: 0.5,
        hasDefect: true,
        defectType: IncidentType.punctureFlatTire,
        isCrashed: false,
      );

      // Krok 1: Wykrycie i start fazy signalingAndDriftingToVerge
      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      expect(renderer.activeMechanicalsCount, equals(1));
      final inc = renderer.getMechanicalIncident('rider_pog');
      expect(inc, isNotNull);
      expect(inc!.phase, equals(MechanicalIncidentPhase.signalingAndDriftingToVerge));
      expect(inc.targetVergeLateralOffset, equals(3.6));

      // Krok 2: Ukończenie fazy sygnalizacji i zjazdu (domyślnie 2.8s)
      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 3.0,
        segments: sampleSegments,
      );
      expect(inc.phase, equals(MechanicalIncidentPhase.awaitingServiceAtVerge));
      expect(inc.currentSpeedMs, equals(0.0));

      // Krok 3: Oczekiwanie na wóz na poboczu (domyślnie 3.5s)
      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 3.6,
        segments: sampleSegments,
      );
      expect(inc.phase, equals(MechanicalIncidentPhase.mechanicRunningWithWheel));

      // Krok 4: Bieg mechanika z kołem (domyślnie 2.2s)
      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 2.3,
        segments: sampleSegments,
      );
      expect(inc.phase, equals(MechanicalIncidentPhase.mechanicReplacingWheel));

      // Krok 5: Wymiana koła przez mechanika (domyślnie 4.5s)
      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 4.6,
        segments: sampleSegments,
      );
      expect(inc.phase, equals(MechanicalIncidentPhase.pushOffAndAcceleration));

      // Krok 6: Pchnięcie przez mechanika i przyspieszenie (domyślnie 3.0s)
      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 1.5,
        segments: sampleSegments,
      );
      expect(inc.currentSpeedMs, greaterThan(0.0));

      // Krok 7: Zakończenie i automatyczne usunięcie incydentu
      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 2.0,
        segments: sampleSegments,
      );
      expect(renderer.activeMechanicalsCount, equals(0));
    });

    test('Drift to left verge when rider starts on left side of road', () {
      final renderer = CrashAndMechanicalVisualsRenderer();

      final riderSnapshot = createSnapshot(
        riderId: 'rider_left',
        name: 'Left Rider',
        bib: 5,
        teamId: 'team',
        teamName: 'Team',
        teamHex: '#38BDF8',
        distanceMeters: 5010.0,
        lateralOffset: -1.2, // Lewa strona szosy
        hasDefect: true,
        defectType: IncidentType.mechanicalFailure,
      );

      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      final inc = renderer.getMechanicalIncident('rider_left');
      expect(inc, isNotNull);
      expect(inc!.targetVergeLateralOffset, equals(-3.6));
    });
  });

  group('Crash Incident State Machine', () {
    test('Crash slide, tarmac recovery, handlebar check and remount', () {
      final renderer = CrashAndMechanicalVisualsRenderer();

      final riderCrash = createSnapshot(
        riderId: 'rider_crashed',
        name: 'Crashed Rider',
        bib: 12,
        teamId: 'team_visma',
        teamName: 'Visma',
        teamHex: '#EAB308',
        distanceMeters: 5020.0,
        lateralOffset: 0.4,
        speedMs: 14.0,
        isCrashed: true,
      );

      // Krok 1: Wykrycie kraksy i faza poślizgu tumbleAndSlide
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      expect(renderer.activeCrashesCount, equals(1));
      final crash = renderer.getCrashIncident('rider_crashed');
      expect(crash, isNotNull);
      expect(crash!.phase, equals(CrashIncidentPhase.tumbleAndSlide));

      // Krok 2: Koniec ślizgu po asfalcie (domyślnie 2.2s)
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 2.3,
        segments: sampleSegments,
      );
      expect(crash.phase, equals(CrashIncidentPhase.lyingOnTarmac));
      expect(crash.currentSpeedMs, equals(0.0));

      // Krok 3: Leżenie na asfalcie i zbieranie sił (domyślnie 3.5s)
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 3.6,
        segments: sampleSegments,
      );
      expect(crash.phase, equals(CrashIncidentPhase.standingAndInspectingBike));

      // Krok 4: Wstawanie i oględziny roweru (domyślnie 4.0s)
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 4.1,
        segments: sampleSegments,
      );
      expect(crash.phase, equals(CrashIncidentPhase.adjustingHandlebarAndChain));

      // Krok 5: Prostowanie klamkomanetek i zakładanie łańcucha (domyślnie 3.5s)
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 3.6,
        segments: sampleSegments,
      );
      expect(crash.phase, equals(CrashIncidentPhase.remountingAndStartingSlow));

      // Krok 6: Wsiadanie na rower (domyślnie 2.5s)
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 2.6,
        segments: sampleSegments,
      );
      expect(crash.phase, equals(CrashIncidentPhase.slowAcceleration));

      // Krok 7: Powolne rozpędzanie się (domyślnie 4.0s)
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 2.0,
        segments: sampleSegments,
      );
      expect(crash.currentSpeedMs, greaterThan(0.0));

      // Krok 8: Powrót do wyścigu i usunięcie z incydentów
      renderer.updateIncidents(
        snapshots: [riderCrash],
        dtSeconds: 2.5,
        segments: sampleSegments,
      );
      expect(renderer.activeCrashesCount, equals(0));
    });
  });

  group('Crash and Mechanical Canvas 3D Rendering', () {
    test('Early return without crash when no incidents active', () {
      final renderer = CrashAndMechanicalVisualsRenderer();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      renderer.renderIncidentVisuals(
        canvas: canvas,
        projection: projection,
        elapsedAnimSeconds: 1.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('Renders mechanical incident in all servicing phases on 3D canvas', () {
      final renderer = CrashAndMechanicalVisualsRenderer();

      final riderSnapshot = createSnapshot(
        riderId: 'rider_pog',
        name: 'Tadej Pogacar',
        bib: 1,
        teamId: 'uae',
        teamName: 'UAE',
        teamHex: '#E2E8F0',
        distanceMeters: 5015.0,
        lateralOffset: 1.0,
        hasDefect: true,
      );

      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      // Renderowanie fazy signalingAndDriftingToVerge
      final recorder1 = PictureRecorder();
      final canvas1 = Canvas(recorder1);
      renderer.renderIncidentVisuals(
        canvas: canvas1,
        projection: projection,
        elapsedAnimSeconds: 0.5,
      );
      expect(recorder1.endRecording(), isNotNull);

      // Przejście do fazy z mechanikiem i wozem
      final inc = renderer.getMechanicalIncident('rider_pog')!;
      inc.phase = MechanicalIncidentPhase.mechanicReplacingWheel;
      inc.phaseElapsedSeconds = 2.0;

      final recorder2 = PictureRecorder();
      final canvas2 = Canvas(recorder2);
      renderer.renderIncidentVisuals(
        canvas: canvas2,
        projection: projection,
        elapsedAnimSeconds: 2.0,
      );
      expect(recorder2.endRecording(), isNotNull);

      // Przejście do fazy push-off
      inc.phase = MechanicalIncidentPhase.pushOffAndAcceleration;
      inc.phaseElapsedSeconds = 1.0;

      final recorder3 = PictureRecorder();
      final canvas3 = Canvas(recorder3);
      renderer.renderIncidentVisuals(
        canvas: canvas3,
        projection: projection,
        elapsedAnimSeconds: 3.0,
      );
      expect(recorder3.endRecording(), isNotNull);
    });

    test('Renders crash incident across tumble, lying, adjusting and flag warning', () {
      final renderer = CrashAndMechanicalVisualsRenderer();

      final crashSnapshot = createSnapshot(
        riderId: 'rider_crashed',
        name: 'Crashed Rider',
        bib: 22,
        teamId: 'ineos',
        teamName: 'INEOS',
        teamHex: '#DC2626',
        distanceMeters: 5018.0,
        lateralOffset: -0.5,
        isCrashed: true,
      );

      renderer.updateIncidents(
        snapshots: [crashSnapshot],
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      final crash = renderer.getCrashIncident('rider_crashed')!;

      // 1. Faza ślizgu po asfalcie
      crash.phase = CrashIncidentPhase.tumbleAndSlide;
      final rec1 = PictureRecorder();
      renderer.renderIncidentVisuals(canvas: Canvas(rec1), projection: projection, elapsedAnimSeconds: 1.0);
      expect(rec1.endRecording(), isNotNull);

      // 2. Faza leżenia na asfalcie
      crash.phase = CrashIncidentPhase.lyingOnTarmac;
      final rec2 = PictureRecorder();
      renderer.renderIncidentVisuals(canvas: Canvas(rec2), projection: projection, elapsedAnimSeconds: 2.0);
      expect(rec2.endRecording(), isNotNull);

      // 3. Faza wstawania i oględzin roweru
      crash.phase = CrashIncidentPhase.standingAndInspectingBike;
      final rec3 = PictureRecorder();
      renderer.renderIncidentVisuals(canvas: Canvas(rec3), projection: projection, elapsedAnimSeconds: 3.0);
      expect(rec3.endRecording(), isNotNull);

      // 4. Faza prostowania klamkomanetek
      crash.phase = CrashIncidentPhase.adjustingHandlebarAndChain;
      final rec4 = PictureRecorder();
      renderer.renderIncidentVisuals(canvas: Canvas(rec4), projection: projection, elapsedAnimSeconds: 4.0);
      expect(rec4.endRecording(), isNotNull);

      // 5. Faza wsiadania na rower
      crash.phase = CrashIncidentPhase.remountingAndStartingSlow;
      final rec5 = PictureRecorder();
      renderer.renderIncidentVisuals(canvas: Canvas(rec5), projection: projection, elapsedAnimSeconds: 5.0);
      expect(rec5.endRecording(), isNotNull);
    });

    test('Camera culling: ignores drawing when incident is behind camera', () {
      final renderer = CrashAndMechanicalVisualsRenderer();

      // Incydent daleko za plecami kamery (Z = 2000 m, a kamera jest na Z = 4985 m)
      final behindSnapshot = createSnapshot(
        riderId: 'rider_behind',
        name: 'Behind Rider',
        bib: 30,
        teamId: 'team',
        teamName: 'Team',
        teamHex: '#000000',
        distanceMeters: 2000.0,
        isCrashed: true,
      );

      renderer.updateIncidents(
        snapshots: [behindSnapshot],
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Nie wywołuje żadnego błędu ani rysowania
      renderer.renderIncidentVisuals(
        canvas: canvas,
        projection: projection,
        elapsedAnimSeconds: 1.0,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('Crash and Mechanical Visuals - Options & Clear', () {
    test('Config disabled stops updating and rendering', () {
      final renderer = CrashAndMechanicalVisualsRenderer(
        config: const CrashAndMechanicalConfig(enabled: false),
      );

      final riderSnapshot = createSnapshot(
        riderId: 'rider_pog',
        name: 'Tadej',
        bib: 1,
        teamId: 'uae',
        teamName: 'UAE',
        teamHex: '#FFFFFF',
        hasDefect: true,
      );

      renderer.updateIncidents(
        snapshots: [riderSnapshot],
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      expect(renderer.activeMechanicalsCount, equals(0));
    });

    test('clearIncidents clears all tracked states', () {
      final renderer = CrashAndMechanicalVisualsRenderer();

      final s1 = createSnapshot(riderId: 'r1', name: 'R1', bib: 1, teamId: 't1', teamName: 'T1', teamHex: '#FFF', hasDefect: true);
      final s2 = createSnapshot(riderId: 'r2', name: 'R2', bib: 2, teamId: 't2', teamName: 'T2', teamHex: '#FFF', isCrashed: true);

      renderer.updateIncidents(snapshots: [s1, s2], dtSeconds: 0.1, segments: sampleSegments);
      expect(renderer.activeMechanicalsCount, equals(1));
      expect(renderer.activeCrashesCount, equals(1));

      renderer.clearIncidents();
      expect(renderer.activeMechanicalsCount, equals(0));
      expect(renderer.activeCrashesCount, equals(0));
    });

    test('updateIncidents accepts activeRiders List<PelotonRenderItem>', () {
      final renderer = CrashAndMechanicalVisualsRenderer();
      final pelotonRenderer = PelotonInstancedRenderer();

      final s1 = createSnapshot(
        riderId: 'r_render_item',
        name: 'Render Item Rider',
        bib: 7,
        teamId: 'team_uae',
        teamName: 'UAE',
        teamHex: '#E2E8F0',
        distanceMeters: 5010.0,
        hasDefect: true,
      );

      final renderItems = pelotonRenderer.prepareDrawList(
        riders: [s1],
        cameraController: cameraController,
        projection: projection,
        segments: sampleSegments,
      );

      renderer.updateIncidents(
        activeRiders: renderItems,
        dtSeconds: 0.1,
        segments: sampleSegments,
      );

      expect(renderer.activeMechanicalsCount, equals(1));
      expect(renderer.getMechanicalIncident('r_render_item'), isNotNull);
    });
  });
}
