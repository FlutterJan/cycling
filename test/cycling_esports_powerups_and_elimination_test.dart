import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/esports_smart_trainer_erg_and_powerups_solver.dart';
import 'package:pro_peloton_manager/models/esports/uci_cycling_esports_world_model.dart';

void main() {
  const solver = EsportsSmartTrainerErgAndPowerupsSolver();

  EsportsRiderLiveState buildRider({
    String riderId = 'r1',
    String riderName = 'Kacper Majewski',
    double weightKg = 70.0,
    double ftpWatts = 400.0,
    double currentPowerWatts = 400.0,
    double speedKmh = 45.0,
    double distanceMeters = 500.0,
    int rank = 1,
    double wPrimeRemainingJoules = 20000.0,
    double wPrimeMaxJoules = 20000.0,
    double dualRecordingDeltaPercent = 0.4,
    SmartTrainerHardwareSpec? trainerSpec,
    EsportsPowerUpInventorySlot powerUpSlot = const EsportsPowerUpInventorySlot(),
    EsportsAvatarVerdict verdict = EsportsAvatarVerdict.active,
  }) {
    return EsportsRiderLiveState(
      riderId: riderId,
      riderName: riderName,
      teamCode: 'POL',
      weightKg: weightKg,
      ftpWatts: ftpWatts,
      currentPowerWatts: currentPowerWatts,
      speedKmh: speedKmh,
      distanceMeters: distanceMeters,
      rank: rank,
      wPrimeRemainingJoules: wPrimeRemainingJoules,
      wPrimeMaxJoules: wPrimeMaxJoules,
      dualRecordingDeltaPercent: dualRecordingDeltaPercent,
      trainerSpec: trainerSpec ?? SmartTrainerHardwareSpec.proDirectDrive(),
      powerUpSlot: powerUpSlot,
      verdict: verdict,
    );
  }

  group('Power-Upy e-Sports — fizyka i modyfikatory', () {
    test('Aero Helmet redukuje CdA o 25% i zwiększa prędkość na płaskim', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final baselineRider = buildRider(distanceMeters: 100.0, speedKmh: 45.0);
      final aeroRider = baselineRider.copyWith(
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.aeroHelmet,
          state: EsportsPowerUpSlotState.active,
          remainingActiveSeconds: 15.0,
        ),
      );

      final baselineRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: baselineRider,
          world: world,
          targetPowerWatts: 420.0,
          hasDraftTargetAhead: false,
        ),
      );
      final aeroRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: aeroRider,
          world: world,
          targetPowerWatts: 420.0,
          hasDraftTargetAhead: false,
        ),
      );

      expect(aeroRes.effectiveCda, closeTo(baselineRes.effectiveCda * 0.75, 1e-6));
      expect(aeroRes.speedKmh, greaterThan(baselineRes.speedKmh));
      expect(aeroRes.powerSavingsFromPowerUpWatts, greaterThan(0.0));
      expect(
        aeroRes.updatedRider.powerUpSlot.remainingActiveSeconds,
        closeTo(14.0, 1e-6),
      );
    });

    test('Featherweight redukuje masę kolarza o 10% i przyspiesza na podjeździe 6.5%', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      // Segment 1: 1000..1700 m, nachylenie 6.5%
      final baselineRider = buildRider(distanceMeters: 1100.0, speedKmh: 24.0);
      final featherRider = baselineRider.copyWith(
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.featherweight,
          state: EsportsPowerUpSlotState.active,
          remainingActiveSeconds: 15.0,
        ),
      );

      final baselineRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: baselineRider,
          world: world,
          targetPowerWatts: 420.0,
        ),
      );
      final featherRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: featherRider,
          world: world,
          targetPowerWatts: 420.0,
        ),
      );

      expect(featherRes.effectiveMassKg, closeTo(70.0 * 0.90 + 6.8, 1e-6));
      expect(featherRes.effectiveMassKg, lessThan(baselineRes.effectiveMassKg));
      expect(featherRes.speedKmh, greaterThan(baselineRes.speedKmh));
      expect(featherRes.powerSavingsFromPowerUpWatts, greaterThan(0.0));
    });

    test('Burrito rywala z przodu całkowicie odcina cień aerodynamiczny (draft)', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final rider = buildRider(distanceMeters: 200.0, speedKmh: 46.0);

      final withDraft = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 380.0,
          hasDraftTargetAhead: true,
          baseDraftShelterIntensity: 0.8,
          rivalAheadHasActiveBurrito: false,
        ),
      );
      final blockedByBurrito = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 380.0,
          hasDraftTargetAhead: true,
          baseDraftShelterIntensity: 0.8,
          rivalAheadHasActiveBurrito: true,
        ),
      );

      expect(withDraft.isDraftBlockedByBurrito, isFalse);
      expect(withDraft.effectiveDraftFactor, lessThan(1.0));
      expect(blockedByBurrito.isDraftBlockedByBurrito, isTrue);
      expect(blockedByBurrito.effectiveDraftFactor, 1.0);
      expect(blockedByBurrito.aeroDragWatts, greaterThan(withDraft.aeroDragWatts));
    });

    test('Draft Boost wzmacnia efekt jazdy na kole, a Steamroller obniża CRR o 50%', () {
      const roughWorld = EsportsVirtualWorldSpec(
        id: 'rough_crit',
        name: 'Cobble & Gravel Crit',
        theme: VirtualWorldTheme.tokyoNeonCrit,
        lapLengthMeters: 2000.0,
        totalLaps: 5,
        elevationGainPerLapMeters: 10.0,
        segments: [
          EsportsVirtualCourseSegment(
            index: 0,
            name: 'Sektor Brukowy',
            startDistanceMeters: 0.0,
            endDistanceMeters: 2000.0,
            gradientPercent: 0.0,
            surfaceCrr: 0.0055,
            draftingEnabled: true,
          ),
        ],
      );

      final baseRider = buildRider(distanceMeters: 100.0, speedKmh: 42.0);
      final draftBoostRider = baseRider.copyWith(
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.draftBoost,
          state: EsportsPowerUpSlotState.active,
          remainingActiveSeconds: 20.0,
        ),
      );
      final steamrollerRider = baseRider.copyWith(
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.steamroller,
          state: EsportsPowerUpSlotState.active,
          remainingActiveSeconds: 20.0,
        ),
      );

      final baseRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: baseRider,
          world: roughWorld,
          targetPowerWatts: 400.0,
          hasDraftTargetAhead: true,
          baseDraftShelterIntensity: 0.75,
        ),
      );
      final draftRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: draftBoostRider,
          world: roughWorld,
          targetPowerWatts: 400.0,
          hasDraftTargetAhead: true,
          baseDraftShelterIntensity: 0.75,
        ),
      );
      final steamRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: steamrollerRider,
          world: roughWorld,
          targetPowerWatts: 400.0,
          hasDraftTargetAhead: true,
          baseDraftShelterIntensity: 0.75,
        ),
      );

      expect(draftRes.effectiveDraftFactor, lessThan(baseRes.effectiveDraftFactor));
      expect(steamRes.effectiveCrr, closeTo(0.0055 * 0.5, 1e-6));
      expect(steamRes.rollingResistanceWatts, lessThan(baseRes.rollingResistanceWatts));
    });

    test('przekroczenie bramy Power-Up Banner z pustym slotem przyznaje nowy Power-Up', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      // Segment 1 (1000..1700) -> przejście do Segmentu 2 (1700..2500, isPowerUpBannerGate: true)
      final rider = buildRider(
        distanceMeters: 1696.0,
        speedKmh: 36.0, // 10 m/s -> po 1 s dystans ~1706 m
        powerUpSlot: const EsportsPowerUpInventorySlot(),
      );

      final res = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 380.0,
          deltaTimeSeconds: 1.0,
        ),
      );

      expect(res.crossedBannerGate, isTrue);
      expect(res.updatedRider.powerUpSlot.state, EsportsPowerUpSlotState.ready);
      expect(res.updatedRider.powerUpSlot.powerUp, isNotNull);
    });

    test('tryb ERG zeruje symulowane nachylenie trenażera, a niezgodny Dual-Recording daje DSQ', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final climbingRider = buildRider(distanceMeters: 1200.0, speedKmh: 25.0);

      final ergRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: climbingRider,
          world: world,
          targetPowerWatts: 360.0,
          controlMode: EsportsTrainerControlMode.ergMode,
        ),
      );
      expect(ergRes.simulatedTrainerGradientPercent, 0.0);

      final nonCompliantTrainer = SmartTrainerHardwareSpec.proDirectDrive().copyWith(
        dualPowerMeterVerified: false,
      );
      final dsqCandidate = buildRider(
        distanceMeters: 500.0,
        dualRecordingDeltaPercent: 3.4,
        trainerSpec: nonCompliantTrainer,
      );

      final dsqRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: dsqCandidate,
          world: world,
          targetPowerWatts: 400.0,
        ),
      );

      expect(dsqRes.dualRecordingStatus, DualRecordingComplianceStatus.disqualified);
      expect(dsqRes.updatedRider.verdict, EsportsAvatarVerdict.disqualifiedDualRecording);
      expect(dsqRes.speedKmh, 0.0);
    });
  });

  group('Power-Upy e-Sports — strategia użycia', () {
    test('brak gotowego Power-Upa zwraca akcję none', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final rider = buildRider(
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.aeroHelmet,
          state: EsportsPowerUpSlotState.active,
          remainingActiveSeconds: 10.0,
        ),
      );

      final decision = solver.evaluatePowerUpStrategy(
        rider: rider,
        world: world,
      );

      expect(decision.recommendedAction, EsportsPowerUpAction.none);
      expect(decision.shouldActivateNow, isFalse);
      expect(decision.powerUpType, isNull);
    });

    test('alarm ostatnich 10 s przed eliminacją wymusza natychmiastową aktywację', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final endangeredRider = buildRider(
        rank: 18,
        distanceMeters: 500.0,
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.featherweight,
          state: EsportsPowerUpSlotState.ready,
        ),
      );
      const schedule = Elimination60sScheduleState(
        intervalSeconds: 60,
        currentRound: 2,
        elapsedSeconds: 114,
      );

      final decision = solver.evaluatePowerUpStrategy(
        rider: endangeredRider,
        world: world,
        eliminationSchedule: schedule,
        activeRidersCount: 20,
      );

      expect(decision.recommendedAction, EsportsPowerUpAction.activateNow);
      expect(decision.shouldActivateNow, isTrue);
      expect(decision.urgencyScore, greaterThanOrEqualTo(0.95));
    });

    test('Featherweight aktywuje się na podjeździe 6.5% i czeka na płaskim', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final flatRider = buildRider(
        distanceMeters: 100.0, // gradient 0.2%
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.featherweight,
          state: EsportsPowerUpSlotState.ready,
        ),
      );
      final climbRider = flatRider.copyWith(distanceMeters: 1200.0); // gradient 6.5%

      final flatDecision = solver.evaluatePowerUpStrategy(
        rider: flatRider,
        world: world,
      );
      final climbDecision = solver.evaluatePowerUpStrategy(
        rider: climbRider,
        world: world,
      );

      expect(flatDecision.recommendedAction, EsportsPowerUpAction.holdForClimb);
      expect(flatDecision.shouldActivateNow, isFalse);

      expect(climbDecision.recommendedAction, EsportsPowerUpAction.activateNow);
      expect(climbDecision.shouldActivateNow, isTrue);
    });

    test('Aero Helmet, Burrito, Draft Boost i Steamroller dobierają właściwe okna aktywacji', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();

      final aeroSprintRider = buildRider(
        distanceMeters: 2800.0, // Finiszowa pętla (isSprintOrKomPrime: true, 0.8%)
        speedKmh: 52.0,
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.aeroHelmet,
          state: EsportsPowerUpSlotState.ready,
        ),
      );
      final aeroDecision = solver.evaluatePowerUpStrategy(
        rider: aeroSprintRider,
        world: world,
      );
      expect(aeroDecision.recommendedAction, EsportsPowerUpAction.activateNow);
      expect(aeroDecision.shouldActivateNow, isTrue);

      final burritoRider = buildRider(
        distanceMeters: 2800.0,
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.burrito,
          state: EsportsPowerUpSlotState.ready,
        ),
      );
      final burritoDecision = solver.evaluatePowerUpStrategy(
        rider: burritoRider,
        world: world,
        rivalsDraftingBehind: true,
      );
      expect(burritoDecision.recommendedAction, EsportsPowerUpAction.activateNow);
      expect(burritoDecision.shouldActivateNow, isTrue);

      final draftRider = buildRider(
        rank: 4,
        distanceMeters: 300.0,
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.draftBoost,
          state: EsportsPowerUpSlotState.ready,
        ),
      );
      final draftDecision = solver.evaluatePowerUpStrategy(
        rider: draftRider,
        world: world,
      );
      expect(draftDecision.recommendedAction, EsportsPowerUpAction.activateNow);
      expect(draftDecision.shouldActivateNow, isTrue);

      const cobbleWorld = EsportsVirtualWorldSpec(
        id: 'cobble_arena',
        name: 'Cobble Arena',
        theme: VirtualWorldTheme.glasgowUciCircuit,
        lapLengthMeters: 3000.0,
        totalLaps: 4,
        elevationGainPerLapMeters: 20.0,
        segments: [
          EsportsVirtualCourseSegment(
            index: 0,
            name: 'Bruk Miejski',
            startDistanceMeters: 0.0,
            endDistanceMeters: 3000.0,
            gradientPercent: 1.0,
            surfaceCrr: 0.0052,
          ),
        ],
      );
      final steamRider = buildRider(
        distanceMeters: 400.0,
        powerUpSlot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.steamroller,
          state: EsportsPowerUpSlotState.ready,
        ),
      );
      final steamDecision = solver.evaluatePowerUpStrategy(
        rider: steamRider,
        world: cobbleWorld,
      );
      expect(steamDecision.recommendedAction, EsportsPowerUpAction.activateNow);
      expect(steamDecision.shouldActivateNow, isTrue);
    });
  });

  group('Wyścig eliminacyjny co 60 sekund', () {
    test('przed 60 s nie eliminuje nikogo, ale aktualizuje ranking i straty czasowe', () {
      const schedule = Elimination60sScheduleState(
        intervalSeconds: 60,
        currentRound: 1,
        elapsedSeconds: 40,
      );
      final riders = [
        buildRider(riderId: 'r_slow', riderName: 'Slow', distanceMeters: 950.0, speedKmh: 40.0, rank: 1),
        buildRider(riderId: 'r_fast', riderName: 'Fast', distanceMeters: 1050.0, speedKmh: 45.0, rank: 2),
        buildRider(riderId: 'r_mid', riderName: 'Mid', distanceMeters: 1000.0, speedKmh: 42.0, rank: 3),
      ];

      final res = solver.evaluateEliminationRound(
        schedule: schedule,
        riders: riders,
        elapsedIncrementSeconds: 15, // łącznie 55 s -> strefa alarmu <10 s
      );

      expect(res.eliminationTriggered, isFalse);
      expect(res.eliminationRecord, isNull);
      expect(res.updatedSchedule.elapsedSeconds, 55);
      expect(res.updatedSchedule.isInFinalTenSecondsWarning, isTrue);

      final byId = {for (final r in res.updatedRiders) r.riderId: r};
      expect(byId['r_fast']!.rank, 1);
      expect(byId['r_fast']!.gapToLeaderSeconds, 0.0);
      expect(byId['r_mid']!.rank, 2);
      expect(byId['r_slow']!.rank, 3);
      expect(byId['r_slow']!.gapToLeaderSeconds, greaterThan(0.0));
    });

    test('w 60. sekundzie odpada ostatni aktywny kolarz i zapisuje się foto-finisz', () {
      const schedule = Elimination60sScheduleState(
        intervalSeconds: 60,
        currentRound: 1,
        elapsedSeconds: 55,
      );
      final riders = [
        buildRider(riderId: 'r1', riderName: 'Lider', distanceMeters: 1500.0, speedKmh: 45.0),
        buildRider(riderId: 'r2', riderName: 'Drugi', distanceMeters: 1480.0, speedKmh: 45.0),
        buildRider(riderId: 'r3', riderName: 'Ostatni', distanceMeters: 1465.0, speedKmh: 36.0), // 10 m/s -> 1.5 s
      ];

      final res = solver.evaluateEliminationRound(
        schedule: schedule,
        riders: riders,
        elapsedIncrementSeconds: 5,
      );

      expect(res.eliminationTriggered, isTrue);
      expect(res.eliminationRecord, isNotNull);
      expect(res.eliminationRecord!.eliminatedRiderId, 'r3');
      expect(res.eliminationRecord!.remainingRidersCount, 2);
      expect(res.eliminationRecord!.photoFinishGapSeconds, closeTo(1.5, 1e-6));

      expect(res.updatedSchedule.currentRound, 2);
      expect(res.updatedSchedule.nextTriggerSecond, 120);
      expect(res.updatedSchedule.lastEliminatedRiderId, 'r3');

      final eliminated = res.updatedRiders.firstWhere((r) => r.riderId == 'r3');
      expect(eliminated.verdict, EsportsAvatarVerdict.eliminated);
      expect(eliminated.eliminatedAtSecond, 60);
      expect(eliminated.eliminatedRound, 1);
      expect(eliminated.currentPowerWatts, 0.0);
      expect(eliminated.speedKmh, 0.0);
    });

    test('kolejne rundy eliminują po jednym kolarzu aż do wyłonienia jedynego zwycięzcy', () {
      var schedule = const Elimination60sScheduleState(
        intervalSeconds: 60,
        currentRound: 1,
        elapsedSeconds: 0,
      );
      var riders = [
        buildRider(riderId: 'r1', riderName: 'A', distanceMeters: 3000.0),
        buildRider(riderId: 'r2', riderName: 'B', distanceMeters: 2900.0),
        buildRider(riderId: 'r3', riderName: 'C', distanceMeters: 2800.0),
        buildRider(
          riderId: 'r_dsq',
          riderName: 'DSQ',
          distanceMeters: 100.0,
          verdict: EsportsAvatarVerdict.disqualifiedDualRecording,
        ),
      ];

      // Runda 1 (t = 60 s): odpada r3 (r_dsq jest pominięty jako nieaktywny).
      final round1 = solver.evaluateEliminationRound(
        schedule: schedule,
        riders: riders,
        elapsedIncrementSeconds: 60,
      );
      expect(round1.eliminationTriggered, isTrue);
      expect(round1.eliminationRecord!.eliminatedRiderId, 'r3');
      schedule = round1.updatedSchedule;
      riders = round1.updatedRiders;

      // Runda 2 (t = 120 s): odpada r2.
      final round2 = solver.evaluateEliminationRound(
        schedule: schedule,
        riders: riders,
        elapsedIncrementSeconds: 60,
      );
      expect(round2.eliminationTriggered, isTrue);
      expect(round2.eliminationRecord!.eliminatedRiderId, 'r2');
      schedule = round2.updatedSchedule;
      riders = round2.updatedRiders;

      // Runda 3 (t = 180 s): pozostał już tylko r1 — zwycięzca nie może zostać wyeliminowany.
      final round3 = solver.evaluateEliminationRound(
        schedule: schedule,
        riders: riders,
        elapsedIncrementSeconds: 60,
      );
      expect(round3.eliminationTriggered, isFalse);
      expect(round3.eliminationRecord, isNull);
      final winner = round3.updatedRiders.firstWhere((r) => r.riderId == 'r1');
      expect(winner.verdict, EsportsAvatarVerdict.active);
      expect(schedule.eliminationHistory, hasLength(2));
    });
  });
}
