import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/simulation/isolate_simulation_worker.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/services/generators/stage_profile_builder.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';
import 'package:pro_peloton_manager/services/generators/fictional_brands_catalog.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';

void main() {
  group('SimulationSnapshot & RiderSimulationFrame Domain Unit Tests', () {
    test('RiderSimulationFrame formats and converts to RiderPositionSnapshot properly', () {
      const frame = RiderSimulationFrame(
        riderId: 'rider_01',
        riderName: 'Tadej Pogačar',
        bibNumber: 1,
        teamId: 'team_uae',
        teamName: 'UAE Team Emirates',
        teamJerseyHexColor: '#FFFFFF',
        isPlayerRider: true,
        distanceCoveredMeters: 45000.0,
        kilometerMark: 45.0,
        elevationMeters: 620.0,
        currentGradientPercent: 7.2,
        lateralPositionRoad: -0.4,
        lateralOffsetRoadMeters: -1.2,
        speedMs: 8.5,
        speedKmh: 30.6,
        powerWatts: 420,
        wattsPerKg: 6.36,
        cadenceRpm: 92,
        heartRateBpm: 178,
        wPrimePercentage: 0.85,
        wPrimeJoules: 17000.0,
        glycogenPercentage: 0.75,
        glycogenGrams: 375.0,
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

      expect(frame.riderId, 'rider_01');
      expect(frame.riderName, 'Tadej Pogačar');
      expect(frame.speedKmh, closeTo(30.6, 0.1));
      expect(frame.isPulling, isTrue);

      final posSnapshot = frame.toPositionSnapshot(currentSegmentIndex: 3);
      expect(posSnapshot.riderId, 'rider_01');
      expect(posSnapshot.riderName, 'Tadej Pogačar');
      expect(posSnapshot.currentSegmentIndex, 3);
      expect(posSnapshot.isPlayerRider, isTrue);
      expect(posSnapshot.powerWatts, 420);
      expect(posSnapshot.wattsPerKg, closeTo(6.36, 0.01));
    });

    test('SimulationSnapshot query helpers work correctly', () {
      const riderA = RiderSimulationFrame(
        riderId: 'r_1',
        riderName: 'Rider One',
        bibNumber: 1,
        teamId: 'team_player',
        teamName: 'Player Team',
        teamJerseyHexColor: '#00FF00',
        isPlayerRider: true,
        distanceCoveredMeters: 10500.0,
        kilometerMark: 10.5,
        elevationMeters: 150.0,
        currentGradientPercent: 1.0,
        lateralPositionRoad: 0.0,
        lateralOffsetRoadMeters: 0.0,
        speedMs: 12.0,
        speedKmh: 43.2,
        powerWatts: 300,
        wattsPerKg: 4.5,
        cadenceRpm: 90,
        heartRateBpm: 150,
        wPrimePercentage: 1.0,
        wPrimeJoules: 20000.0,
        glycogenPercentage: 1.0,
        glycogenGrams: 500.0,
        activeTacticalOrder: TacticalOrder.holdPosition,
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

      const riderB = RiderSimulationFrame(
        riderId: 'r_2',
        riderName: 'Rider Two',
        bibNumber: 2,
        teamId: 'team_cpu',
        teamName: 'CPU Team',
        teamJerseyHexColor: '#FF0000',
        isPlayerRider: false,
        distanceCoveredMeters: 10000.0,
        kilometerMark: 10.0,
        elevationMeters: 150.0,
        currentGradientPercent: 1.0,
        lateralPositionRoad: 0.2,
        lateralOffsetRoadMeters: 0.6,
        speedMs: 11.5,
        speedKmh: 41.4,
        powerWatts: 250,
        wattsPerKg: 3.8,
        cadenceRpm: 88,
        heartRateBpm: 140,
        wPrimePercentage: 0.95,
        wPrimeJoules: 19000.0,
        glycogenPercentage: 0.98,
        glycogenGrams: 490.0,
        activeTacticalOrder: TacticalOrder.saveEnergy,
        groupIndex: 1,
        groupType: GroupType.peloton,
        timeGapToLeaderSeconds: 45.0,
        isDrafting: true,
        draftingSavingsPercent: 32.0,
        isPulling: false,
        hasDefect: false,
        defectType: null,
        isCrashed: false,
        isDnf: false,
        finishRank: null,
      );

      const groupBreakaway = PelotonGroupSnapshot(
        groupId: 'grp_0',
        type: GroupType.breakaway,
        riderCount: 1,
        riderIds: ['r_1'],
        gapToRaceLeaderSeconds: 0.0,
        distanceCoveredKm: 10.5,
        speedKmh: 43.2,
        containsPlayerRider: true,
      );

      const groupPeloton = PelotonGroupSnapshot(
        groupId: 'grp_1',
        type: GroupType.peloton,
        riderCount: 1,
        riderIds: ['r_2'],
        gapToRaceLeaderSeconds: 45.0,
        distanceCoveredKm: 10.0,
        speedKmh: 41.4,
        containsPlayerRider: false,
      );

      const snapshot = SimulationSnapshot(
        frameIndex: 12,
        elapsedSeconds: 900.0,
        leadKilometerMark: 10.5,
        totalStageDistanceKm: 160.0,
        distanceToFinishKm: 149.5,
        currentSegmentIndex: 0,
        currentGradientPercent: 1.0,
        currentElevationMeters: 150.0,
        currentWindSpeedKmh: 12.0,
        groups: [groupBreakaway, groupPeloton],
        riders: [riderA, riderB],
        newRadioMessages: [],
        isStageFinished: false,
        finishResults: [],
        computeDurationMs: 1.25,
        timeSpeed: SimulationTimeSpeed.x1,
      );

      expect(snapshot.riderCount, 2);
      expect(snapshot.getRider('r_1'), isNotNull);
      expect(snapshot.getRider('r_1')!.riderName, 'Rider One');
      expect(snapshot.getRider('non_existent'), isNull);
      expect(snapshot.playerRiders.length, 1);
      expect(snapshot.playerRiders.first.riderId, 'r_1');
      expect(snapshot.leaderRider?.riderId, 'r_1');
      expect(snapshot.mainPelotonGroup?.groupId, 'grp_1');
      expect(snapshot.breakawayGroup?.groupId, 'grp_0');

      final posSnapshots = snapshot.toPositionSnapshots();
      expect(posSnapshots.length, 2);
      expect(posSnapshots.first.riderId, 'r_1');
    });
  });

  group('IsolateSimulationWorker Real Isolate Execution Tests', () {
    late IsolateSimulationWorker worker;

    tearDown(() async {
      await worker.dispose();
    });

    test('Isolate spawns, completes handshake, and delivers initial snapshot with full peloton', () async {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
      final stage = StageProfileBuilder.buildHighMountainStage(
        id: 'test_stage_01',
        stageNumber: 1,
        name: 'Test Stage',
        distanceKm: 80.0,
        climbs: [StageProfileBuilder.alpeDHuez],
      );

      final playerTeam = world.teams.first;
      final Map<String, Rider> allRidersMap = {for (final r in world.allRiders) r.id: r};
      final demoBike = FictionalBrandsCatalog.assembleBike(
        brandId: 'brand_aethel',
        frameCategory: FrameCategory.allRounder,
      );
      final Map<String, CompleteBike> allBikesMap = {
        for (final r in world.allRiders) r.id: demoBike,
      };
      final Map<String, CyclingTeam> allTeamsMap = {for (final t in world.teams) t.id: t};

      worker = IsolateSimulationWorker();

      // Inicjalizacja wątku Isolate
      await worker.initialize(
        stage: stage,
        playerTeamId: playerTeam.id,
        allRidersMap: allRidersMap,
        allBikesMap: allBikesMap,
        allTeamsMap: allTeamsMap,
        initialSpeed: SimulationTimeSpeed.x1,
        targetFps: 30,
      );

      expect(worker.isInitialized, isTrue);

      // Poczekaj na pierwszą wyemitowaną klatkę (Frame #1)
      final firstSnapshot = await worker.snapshotStream.first;
      expect(firstSnapshot, isNotNull);
      expect(firstSnapshot.frameIndex, 1);
      expect(firstSnapshot.riderCount, allRidersMap.length);
      expect(firstSnapshot.groups.isNotEmpty, isTrue);
      expect(worker.latestSnapshot, isNotNull);
    });

    test('step() advances distance and updates speed in background Isolate', () async {
      worker = await IsolateSimulationWorker.createDemoWorker(targetFps: 30);
      expect(worker.isInitialized, isTrue);

      // Pobieramy pierwszą klatkę
      final firstSnapshot = await worker.snapshotStream.first;
      final initialLeadDist = firstSnapshot.leadKilometerMark;

      // Wykonujemy krok symulacji o 5 sekund
      final nextSnapshotFuture = worker.snapshotStream.first;
      worker.step(dtSeconds: 5.0);
      final stepSnapshot = await nextSnapshotFuture;

      expect(stepSnapshot.frameIndex, greaterThan(firstSnapshot.frameIndex));
      expect(stepSnapshot.elapsedSeconds, greaterThanOrEqualTo(firstSnapshot.elapsedSeconds));
      expect(stepSnapshot.leadKilometerMark, greaterThanOrEqualTo(initialLeadDist));
    });

    test('setTacticalOrder and applyTeamTactics communicate to background Isolate', () async {
      worker = await IsolateSimulationWorker.createDemoWorker(targetFps: 30);

      final initialSnapshot = await worker.snapshotStream.first;
      final playerRiders = initialSnapshot.playerRiders;
      expect(playerRiders.isNotEmpty, isTrue);

      final targetRiderId = playerRiders.first.riderId;

      // Wysyłamy polecenie taktyczne: Atakuj!
      worker.setTacticalOrder(
        riderId: targetRiderId,
        order: TacticalOrder.attack,
      );

      // Wykonujemy krok symulacji, by sprawdzić zaktualizowany stan
      final snapshotAfterOrderFuture = worker.snapshotStream.first;
      worker.step(dtSeconds: 1.0);
      final snapshotAfterOrder = await snapshotAfterOrderFuture;

      final updatedRider = snapshotAfterOrder.getRider(targetRiderId);
      expect(updatedRider, isNotNull);
      expect(updatedRider!.activeTacticalOrder, TacticalOrder.attack);

      // Test zbiorczego polecenia drużynowego (1-Click Team Tactics)
      final Map<String, TacticalOrder> teamOrders = {
        for (final r in playerRiders) r.riderId: TacticalOrder.protectLeader,
      };

      worker.applyTeamTactics(
        presetName: 'Wszyscy chrońcie Lidera',
        assignments: teamOrders,
      );

      final snapshotAfterTeamTacticsFuture = worker.snapshotStream.first;
      worker.step(dtSeconds: 1.0);
      final snapshotAfterTeamTactics = await snapshotAfterTeamTacticsFuture;

      for (final r in playerRiders) {
        final current = snapshotAfterTeamTactics.getRider(r.riderId);
        expect(current?.activeTacticalOrder, TacticalOrder.protectLeader);
      }
    });

    test('setTimeSpeed changes speed multiplier and start/pause toggles states', () async {
      worker = await IsolateSimulationWorker.createDemoWorker(targetFps: 30);

      // Poczekaj na pierwszą klatkę startową
      await worker.snapshotStream.first;

      // Zmiana prędkości symulacji
      worker.setTimeSpeed(SimulationTimeSpeed.x4);

      final nextSnapshotFuture = worker.snapshotStream.first;
      worker.step(dtSeconds: 1.0);
      final snap = await nextSnapshotFuture;
      expect(snap.timeSpeed, SimulationTimeSpeed.x4);

      // Start i Pause
      worker.start();
      expect(worker.isRunning, isTrue);
      expect(worker.isPaused, isFalse);

      worker.pause();
      expect(worker.isRunning, isFalse);
      expect(worker.isPaused, isTrue);
    });

    test('start() runs continuous background timer and emits periodic snapshots', () async {
      worker = await IsolateSimulationWorker.createDemoWorker(targetFps: 30);
      await worker.snapshotStream.first; // Consume initial frame

      worker.start();

      // Collect multiple periodic snapshots produced by the background Isolate timer
      final emittedSnapshots = await worker.snapshotStream.take(3).toList();
      expect(emittedSnapshots.length, 3);
      expect(emittedSnapshots[0].frameIndex, greaterThanOrEqualTo(2));
      expect(emittedSnapshots[1].frameIndex, greaterThan(emittedSnapshots[0].frameIndex));
      expect(emittedSnapshots[2].frameIndex, greaterThan(emittedSnapshots[1].frameIndex));
      expect(emittedSnapshots.last.computeDurationMs, greaterThanOrEqualTo(0.0));

      worker.pause();
      expect(worker.isRunning, isFalse);
    });

    test('dispose() cleans up isolate and controllers safely', () async {
      worker = await IsolateSimulationWorker.createDemoWorker(targetFps: 30);
      await worker.snapshotStream.first;

      await worker.dispose();
      expect(worker.isInitialized, isFalse);
      expect(worker.isRunning, isFalse);
      expect(worker.isPaused, isFalse);
    });
  });
}
