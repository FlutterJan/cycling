// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/simulation/isolate_simulation_worker.dart';
import 'package:pro_peloton_manager/engine/simulation/key_moments_detector.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_replay_recorder.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';

void main() {
  group('RiderTelemetryTrackPoint & Telemetry Serialization Tests', () {
    test('RiderTelemetryTrackPoint creates and serializes properly to JSON', () {
      const point = RiderTelemetryTrackPoint(
        timestampSeconds: 120.5,
        distanceMeters: 1540.0,
        speedMs: 12.5,
        powerWatts: 420,
        cadenceRpm: 92,
        heartRateBpm: 172,
        elevationMeters: 450.0,
        gradientPercent: 6.5,
        wPrimeJoules: 18500.0,
        wPrimePercentage: 0.92,
        glycogenGrams: 420.0,
        lateralPositionRoad: -0.2,
        isDrafting: true,
        draftingSavingsPercent: 32.0,
        activeTacticalOrder: TacticalOrder.attack,
      );

      expect(point.speedKmh, closeTo(45.0, 0.1));
      expect(point.distanceKm, closeTo(1.54, 0.01));

      final json = point.toJson();
      final restored = RiderTelemetryTrackPoint.fromJson(json);

      expect(restored.timestampSeconds, point.timestampSeconds);
      expect(restored.powerWatts, 420);
      expect(restored.speedMs, 12.5);
      expect(restored.isDrafting, isTrue);
      expect(restored.activeTacticalOrder, TacticalOrder.attack);
    });
  });

  group('RiderTelemetryLog & Coggan Power Metrics Tests', () {
    test('Calculates accurate average power, work (kJ), calories and normalized power (NP)', () {
      final log = RiderTelemetryLog(
        riderId: 'rider_pogacar',
        riderName: 'Tadej Pogačar',
        bibNumber: 1,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        isPlayerRider: true,
        ftpWatts: 420,
        maxHrBpm: 198,
      );

      // Symulacja 60 sekund wysiłku ze stałą mocą 400W i tętnem 160 bpm
      for (int i = 0; i < 60; i++) {
        log.addPoint(RiderTelemetryTrackPoint(
          timestampSeconds: i.toDouble(),
          distanceMeters: i * 11.0,
          speedMs: 11.0,
          powerWatts: 400,
          cadenceRpm: 90,
          heartRateBpm: 160,
          elevationMeters: 200.0 + (i * 0.5),
          gradientPercent: 4.5,
          wPrimeJoules: 20000.0 - (i * 50),
          wPrimePercentage: 0.95,
          glycogenGrams: 480.0,
          lateralPositionRoad: 0.0,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          activeTacticalOrder: TacticalOrder.pullGroup,
        ));
      }

      final summary = log.computeFitSummary(stageName: 'Etap 1 - Góry');

      expect(summary.avgPowerWatts, 400);
      expect(summary.maxPowerWatts, 400);
      expect(summary.normalizedPowerWatts, 400);
      expect(summary.intensityFactor, closeTo(400.0 / 420.0, 0.01));
      expect(summary.variabilityIndex, closeTo(1.0, 0.01));
      expect(summary.totalWorkKj, closeTo(24.0, 1.0)); // 400W * 60s / 1000 = 24 kJ
      expect(summary.caloriesKcal, greaterThan(20));
      expect(summary.avgHeartRateBpm, 160);
      expect(summary.avgCadenceRpm, 90);
      expect(summary.elevationGainMeters, greaterThan(25.0));
      expect(summary.peakPowerCurve['1s'], 400);
      expect(summary.peakPowerCurve['30s'], 400);
    });

    test('Computes Variable Power & Peak Power curve properly', () {
      final log = RiderTelemetryLog(
        riderId: 'rider_sprinter',
        riderName: 'Jasper Philipsen',
        bibNumber: 11,
        teamId: 'team_alpecin',
        teamName: 'Alpecin-Deceuninck',
        isPlayerRider: false,
        ftpWatts: 380,
      );

      // 50 sekund oszczędzania (200W) + 35 sekund finiszu sprinterskiego (1200W w peaku, potem 800W) + 50 sekund wytoczenia (150W)
      int t = 0;
      for (int i = 0; i < 50; i++, t++) {
        log.addPoint(RiderTelemetryTrackPoint(
          timestampSeconds: t.toDouble(),
          distanceMeters: t * 12.0,
          speedMs: 12.0,
          powerWatts: 200,
          cadenceRpm: 85,
          heartRateBpm: 135,
          elevationMeters: 50.0,
          gradientPercent: 0.0,
          wPrimeJoules: 22000.0,
          wPrimePercentage: 1.0,
          glycogenGrams: 450.0,
          lateralPositionRoad: 0.2,
          isDrafting: true,
          draftingSavingsPercent: 32.0,
          activeTacticalOrder: TacticalOrder.saveEnergy,
        ));
      }

      for (int i = 0; i < 35; i++, t++) {
        final int power = i < 15 ? 1200 : 800;
        log.addPoint(RiderTelemetryTrackPoint(
          timestampSeconds: t.toDouble(),
          distanceMeters: 600.0 + i * 18.0,
          speedMs: 18.0,
          powerWatts: power,
          cadenceRpm: 115,
          heartRateBpm: 188,
          elevationMeters: 50.0,
          gradientPercent: 0.0,
          wPrimeJoules: 15000.0,
          wPrimePercentage: 0.68,
          glycogenGrams: 440.0,
          lateralPositionRoad: -0.1,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          activeTacticalOrder: TacticalOrder.attack,
        ));
      }

      for (int i = 0; i < 50; i++, t++) {
        log.addPoint(RiderTelemetryTrackPoint(
          timestampSeconds: t.toDouble(),
          distanceMeters: 1230.0 + i * 10.0,
          speedMs: 10.0,
          powerWatts: 150,
          cadenceRpm: 80,
          heartRateBpm: 145,
          elevationMeters: 50.0,
          gradientPercent: 0.0,
          wPrimeJoules: 18000.0,
          wPrimePercentage: 0.82,
          glycogenGrams: 435.0,
          lateralPositionRoad: 0.0,
          isDrafting: true,
          draftingSavingsPercent: 32.0,
          activeTacticalOrder: TacticalOrder.saveEnergy,
        ));
      }

      final summary = log.computeFitSummary(stageName: 'Płaski Etap Sprinterski');

      expect(summary.maxPowerWatts, 1200);
      expect(summary.peakPowerCurve['1s'], 1200);
      expect(summary.peakPowerCurve['5s'], 1200);
      expect(summary.peakPowerCurve['15s'], 1200);
      expect(summary.peakPowerCurve['30s'], lessThan(1200));
      expect(summary.normalizedPowerWatts, greaterThan(summary.avgPowerWatts));
      expect(summary.variabilityIndex, greaterThan(1.1));
    });
  });

  group('StageReplayRecorder Full Recording & Final Kilometer Tests', () {
    late StageReplayRecorder recorder;

    setUp(() {
      recorder = StageReplayRecorder(
        config: const StageReplayRecorderConfig(
          fullTelemetrySampleIntervalSeconds: 1.0,
          finalKilometerThresholdKm: 1.0,
          maxReplayFramesCapacity: 500,
        ),
        stageName: 'Alpe d\'Huez Finał',
      );
    });

    test('Records periodic telemetry points for all riders in snapshot', () {
      const frameA = RiderSimulationFrame(
        riderId: 'r_01',
        riderName: 'Jonas Vingegaard',
        bibNumber: 1,
        teamId: 'team_visma',
        teamName: 'Visma Lease a Bike',
        teamJerseyHexColor: '#FFEB3B',
        isPlayerRider: true,
        distanceCoveredMeters: 120000.0,
        kilometerMark: 120.0,
        elevationMeters: 1450.0,
        currentGradientPercent: 8.2,
        lateralPositionRoad: 0.0,
        lateralOffsetRoadMeters: 0.0,
        speedMs: 6.2,
        speedKmh: 22.3,
        powerWatts: 430,
        wattsPerKg: 7.1,
        cadenceRpm: 88,
        heartRateBpm: 178,
        wPrimePercentage: 0.72,
        wPrimeJoules: 14400.0,
        glycogenPercentage: 0.65,
        glycogenGrams: 325.0,
        activeTacticalOrder: TacticalOrder.pullGroup,
        groupIndex: 0,
        groupType: GroupType.breakaway,
        timeGapToLeaderSeconds: 0.0,
        isDrafting: false,
        draftingSavingsPercent: 0.0,
        isPulling: true,
        hasDefect: false,
        defectType: null,
        isCrashed: false,
        isDnf: false,
        finishRank: null,
      );

      const snapshot1 = SimulationSnapshot(
        frameIndex: 1,
        elapsedSeconds: 12000.0,
        leadKilometerMark: 120.0,
        totalStageDistanceKm: 140.0,
        distanceToFinishKm: 20.0,
        currentSegmentIndex: 4,
        currentGradientPercent: 8.2,
        currentElevationMeters: 1450.0,
        currentWindSpeedKmh: 14.0,
        groups: [],
        riders: [frameA],
        newRadioMessages: [],
        isStageFinished: false,
        finishResults: [],
        computeDurationMs: 0.8,
        timeSpeed: SimulationTimeSpeed.x1,
      );

      recorder.recordSnapshot(snapshot1);

      expect(recorder.riderLogs.containsKey('r_01'), isTrue);
      expect(recorder.playerRiderLogs.length, 1);
      expect(recorder.getRiderLog('r_01')!.sampleCount, 1);
      expect(recorder.isFinalKilometerActive, isFalse);
    });

    test('Activates final kilometer replay buffer when distanceToFinishKm <= 1.0', () {
      const frameA = RiderSimulationFrame(
        riderId: 'r_01',
        riderName: 'Wout van Aert',
        bibNumber: 7,
        teamId: 'team_visma',
        teamName: 'Visma Lease a Bike',
        teamJerseyHexColor: '#FFEB3B',
        isPlayerRider: true,
        distanceCoveredMeters: 159200.0,
        kilometerMark: 159.2,
        elevationMeters: 25.0,
        currentGradientPercent: 0.5,
        lateralPositionRoad: -0.3,
        lateralOffsetRoadMeters: -1.0,
        speedMs: 16.5,
        speedKmh: 59.4,
        powerWatts: 950,
        wattsPerKg: 12.1,
        cadenceRpm: 108,
        heartRateBpm: 186,
        wPrimePercentage: 0.35,
        wPrimeJoules: 7000.0,
        glycogenPercentage: 0.5,
        glycogenGrams: 250.0,
        activeTacticalOrder: TacticalOrder.attack,
        groupIndex: 0,
        groupType: GroupType.peloton,
        timeGapToLeaderSeconds: 0.0,
        isDrafting: false,
        draftingSavingsPercent: 0.0,
        isPulling: true,
        hasDefect: false,
        defectType: null,
        isCrashed: false,
        isDnf: false,
        finishRank: null,
      );

      // Klatka w odległości 800m do mety (<= 1.0 km)
      const snapshotFinalKm = SimulationSnapshot(
        frameIndex: 100,
        elapsedSeconds: 14000.0,
        leadKilometerMark: 159.2,
        totalStageDistanceKm: 160.0,
        distanceToFinishKm: 0.8,
        currentSegmentIndex: 8,
        currentGradientPercent: 0.5,
        currentElevationMeters: 25.0,
        currentWindSpeedKmh: 10.0,
        groups: [],
        riders: [frameA],
        newRadioMessages: [],
        isStageFinished: false,
        finishResults: [],
        computeDurationMs: 0.75,
        timeSpeed: SimulationTimeSpeed.x1,
      );

      recorder.recordSnapshot(snapshotFinalKm);

      expect(recorder.isFinalKilometerActive, isTrue);
      expect(recorder.hasFinalKmReplay, isTrue);
      expect(recorder.finalKilometerFrames.length, 1);

      final clip = recorder.buildFinalKilometerClip();
      expect(clip, isNotNull);
      expect(clip!.type, ReplayClipType.finalKilometer);
      expect(clip.frameCount, 1);
    });

    test('Records Key Moment attack clips and finalizes them properly', () {
      const frameA = RiderSimulationFrame(
        riderId: 'r_01',
        riderName: 'Remco Evenepoel',
        bibNumber: 21,
        teamId: 'team_soudal',
        teamName: 'Soudal Quick-Step',
        teamJerseyHexColor: '#0055A5',
        isPlayerRider: false,
        distanceCoveredMeters: 135000.0,
        kilometerMark: 135.0,
        elevationMeters: 1100.0,
        currentGradientPercent: 9.0,
        lateralPositionRoad: 0.1,
        lateralOffsetRoadMeters: 0.3,
        speedMs: 7.0,
        speedKmh: 25.2,
        powerWatts: 520,
        wattsPerKg: 8.2,
        cadenceRpm: 94,
        heartRateBpm: 182,
        wPrimePercentage: 0.80,
        wPrimeJoules: 16000.0,
        glycogenPercentage: 0.70,
        glycogenGrams: 350.0,
        activeTacticalOrder: TacticalOrder.attack,
        groupIndex: 0,
        groupType: GroupType.breakaway,
        timeGapToLeaderSeconds: 0.0,
        isDrafting: false,
        draftingSavingsPercent: 0.0,
        isPulling: true,
        hasDefect: false,
        defectType: null,
        isCrashed: false,
        isDnf: false,
        finishRank: null,
      );

      const trigger = KeyMomentTrigger(
        type: KeyMomentType.gcLeaderAttack,
        kilometerMark: 135.0,
        title: 'ATAK REMCO EVENEPOELA!',
        description: 'Potężny skok na stromiźnie 9%!',
        shouldSwitchTo3d: true,
        recommendedCameraMode: 'helicopter',
        triggerKey: 'attack_remco_135',
        relatedRiderId: 'r_01',
      );

      const attackSnapshot = SimulationSnapshot(
        frameIndex: 50,
        elapsedSeconds: 11500.0,
        leadKilometerMark: 135.0,
        totalStageDistanceKm: 165.0,
        distanceToFinishKm: 30.0,
        currentSegmentIndex: 5,
        currentGradientPercent: 9.0,
        currentElevationMeters: 1100.0,
        currentWindSpeedKmh: 12.0,
        groups: [],
        riders: [frameA],
        newRadioMessages: [],
        activeKeyMoment: trigger,
        isStageFinished: false,
        finishResults: [],
        computeDurationMs: 0.9,
        timeSpeed: SimulationTimeSpeed.x1,
      );

      recorder.recordSnapshot(attackSnapshot);
      recorder.finalizeCurrentAttackClip();

      expect(recorder.highlightClips.isNotEmpty, isTrue);
      final clip = recorder.highlightClips.first;
      expect(clip.title, 'ATAK REMCO EVENEPOELA!');
      expect(clip.type, ReplayClipType.gcAttack);
    });
  });

  group('StageReplayPlayer Interactive Replay Controller Tests', () {
    test('Player controls playback, speeds, seeking, and camera modes', () {
      final List<ReplayFrameSnapshot> frames = [];
      for (int i = 0; i < 60; i++) {
        frames.add(ReplayFrameSnapshot(
          frameIndex: i,
          timestampSeconds: 1000.0 + (i * 0.033),
          leadKilometerMark: 159.0 + (i * 0.015),
          distanceToFinishKm: 1.0 - (i * 0.015),
          currentGradientPercent: 0.0,
          currentElevationMeters: 10.0,
          leadRiderName: 'Lead Rider',
          riders: const [],
        ));
      }

      final clip = ReplayClip(
        id: 'test_clip',
        title: 'Finisz',
        description: 'Test clip',
        type: ReplayClipType.finalKilometer,
        startDistanceKm: 159.0,
        endDistanceKm: 160.0,
        startTimestampSeconds: 1000.0,
        endTimestampSeconds: 1002.0,
        frames: frames,
      );

      final player = StageReplayPlayer(clip: clip);

      expect(player.currentFrameIndex, 0);
      expect(player.isPlaying, isFalse);
      expect(player.cameraMode, RaceCameraMode.chaseCam);

      // Play & Tick
      player.play();
      expect(player.isPlaying, isTrue);

      player.tick(0.1); // ~3 klatki do przodu
      expect(player.currentFrameIndex, greaterThan(0));

      // Slow-motion 0.25x
      player.setPlaybackSpeed(0.25);
      expect(player.playbackSpeed, 0.25);

      // Seeking
      player.seekToProgress(0.5);
      expect(player.progress, closeTo(0.5, 0.05));

      // Camera change
      player.setCameraMode(RaceCameraMode.finishLineCam);
      expect(player.cameraMode, RaceCameraMode.finishLineCam);

      // Step
      final before = player.currentFrameIndex;
      player.stepForward();
      expect(player.currentFrameIndex, before + 1);
      player.stepBackward();
      expect(player.currentFrameIndex, before);
    });
  });

  group('FitFileExporter CSV, JSON & Binary FIT Format Tests', () {
    late RiderTelemetryLog testLog;

    setUp(() {
      testLog = RiderTelemetryLog(
        riderId: 'r_01',
        riderName: 'Mathieu van der Poel',
        bibNumber: 1,
        teamId: 'team_alpecin',
        teamName: 'Alpecin-Deceuninck',
        isPlayerRider: true,
        ftpWatts: 440,
      );

      for (int i = 0; i < 20; i++) {
        testLog.addPoint(RiderTelemetryTrackPoint(
          timestampSeconds: i.toDouble(),
          distanceMeters: i * 14.0,
          speedMs: 14.0,
          powerWatts: 450,
          cadenceRpm: 96,
          heartRateBpm: 175,
          elevationMeters: 80.0,
          gradientPercent: 0.0,
          wPrimeJoules: 21000.0,
          wPrimePercentage: 0.95,
          glycogenGrams: 460.0,
          lateralPositionRoad: 0.0,
          isDrafting: false,
          draftingSavingsPercent: 0.0,
          activeTacticalOrder: TacticalOrder.holdPosition,
        ));
      }
    });

    test('exportToCsv produces valid comma-separated values with headers', () {
      final csv = FitFileExporter.exportToCsv(testLog);

      expect(csv.contains('timestamp_s,distance_m,speed_kmh,power_w'), isTrue);
      expect(csv.contains('450'), isTrue);
      expect(csv.contains('175'), isTrue);
      final lines = csv.trim().split('\n');
      expect(lines.length, 21); // Header + 20 points
    });

    test('exportToJson serializes activity summary properly', () {
      final summary = testLog.computeFitSummary(stageName: 'Paryż-Roubaix');
      final jsonStr = FitFileExporter.exportToJson(summary);

      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      expect(decoded['riderName'], 'Mathieu van der Poel');
      expect(decoded['stageName'], 'Paryż-Roubaix');
      expect(decoded['avgPower'], 450);
      expect(decoded['normalizedPower'], 450);
    });

    test('generateFitBinary generates valid 14-byte FIT protocol header and payload', () {
      final Uint8List fitBytes = FitFileExporter.generateFitBinary(testLog, stageName: 'Tour de France');

      expect(fitBytes.length, greaterThan(14));

      // Weryfikacja 14-bajtowego nagłówka FIT
      expect(fitBytes[0], 14); // Header size: 14 bajtów
      expect(fitBytes[1], 0x20); // Protocol version: 2.0
      // Sygnatura ".FIT" na bajtach 8..11 (ASCII: 0x2E, 0x46, 0x49, 0x54)
      expect(fitBytes[8], 0x2E);
      expect(fitBytes[9], 0x46);
      expect(fitBytes[10], 0x49);
      expect(fitBytes[11], 0x54);

      // Sprawdzenie obecności sumy kontrolnej na końcu
      expect(fitBytes.length, greaterThan(32));
    });
  });
}
