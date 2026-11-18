import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/esports_smart_trainer_erg_and_powerups_solver.dart';
import 'package:pro_peloton_manager/models/esports/uci_cycling_esports_world_model.dart';

void main() {
  const solver = EsportsSmartTrainerErgAndPowerupsSolver();

  EsportsRiderLiveState buildRider({
    String id = 'r1',
    double weightKg = 68.0,
    double ftpWatts = 400.0,
    double currentPowerWatts = 360.0,
    double speedKmh = 42.0,
    double distanceMeters = 200.0,
    int rank = 3,
    double wPrimeRemaining = 20000.0,
    EsportsPowerUpInventorySlot? slot,
    SmartTrainerHardwareSpec? trainerSpec,
    double dualRecordingDeltaPercent = 0.4,
  }) {
    return EsportsRiderLiveState(
      riderId: id,
      riderName: 'Rider $id',
      teamCode: 'PPM',
      weightKg: weightKg,
      ftpWatts: ftpWatts,
      currentPowerWatts: currentPowerWatts,
      speedKmh: speedKmh,
      distanceMeters: distanceMeters,
      rank: rank,
      wPrimeRemainingJoules: wPrimeRemaining,
      wPrimeMaxJoules: 20000.0,
      trainerSpec: trainerSpec ?? SmartTrainerHardwareSpec.proDirectDrive(),
      powerUpSlot: slot ?? const EsportsPowerUpInventorySlot(),
      dualRecordingDeltaPercent: dualRecordingDeltaPercent,
    );
  }

  group('EsportsSmartTrainerErgAndPowerupsSolver', () {
    test('Aero Helmet reduces CdA by 25% and increases speed on flat', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final baseRider = buildRider(distanceMeters: 200.0, speedKmh: 45.0);
      final aeroRider = buildRider(
        distanceMeters: 200.0,
        speedKmh: 45.0,
        slot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.aeroHelmet,
          state: EsportsPowerUpSlotState.ready,
        ).activate(),
      );

      final baseRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: baseRider,
          world: world,
          targetPowerWatts: 420.0,
          hasDraftTargetAhead: false,
          deltaTimeSeconds: 2.0,
        ),
      );
      final aeroRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: aeroRider,
          world: world,
          targetPowerWatts: 420.0,
          hasDraftTargetAhead: false,
          deltaTimeSeconds: 2.0,
        ),
      );

      expect(aeroRes.effectiveCda, closeTo(baseRes.effectiveCda * 0.75, 1e-6));
      expect(aeroRes.speedKmh, greaterThan(baseRes.speedKmh));
      expect(aeroRes.powerSavingsFromPowerUpWatts, greaterThan(25.0));
    });

    test('Featherweight reduces rider mass by 10% on 6.5% climb', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      // Segment 1 is 1000..1700m at +6.5%
      final baseRider = buildRider(distanceMeters: 1200.0, speedKmh: 24.0);
      final featherRider = buildRider(
        distanceMeters: 1200.0,
        speedKmh: 24.0,
        slot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.featherweight,
          state: EsportsPowerUpSlotState.ready,
        ).activate(),
      );

      final baseRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: baseRider,
          world: world,
          targetPowerWatts: 420.0,
          deltaTimeSeconds: 2.0,
        ),
      );
      final featherRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: featherRider,
          world: world,
          targetPowerWatts: 420.0,
          deltaTimeSeconds: 2.0,
        ),
      );

      expect(featherRes.effectiveMassKg, lessThan(baseRes.effectiveMassKg));
      expect(featherRes.gravityWatts, lessThan(baseRes.gravityWatts));
      expect(featherRes.speedKmh, greaterThan(baseRes.speedKmh));
      expect(featherRes.powerSavingsFromPowerUpWatts, greaterThan(20.0));
    });

    test('Burrito active ahead blocks drafting for trailing rider', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final rider = buildRider(distanceMeters: 200.0);

      final normalDraftRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 360.0,
          hasDraftTargetAhead: true,
          rivalAheadHasActiveBurrito: false,
        ),
      );
      final burritoBlockedRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 360.0,
          hasDraftTargetAhead: true,
          rivalAheadHasActiveBurrito: true,
        ),
      );

      expect(normalDraftRes.effectiveDraftFactor, lessThan(1.0));
      expect(burritoBlockedRes.isDraftBlockedByBurrito, isTrue);
      expect(burritoBlockedRes.effectiveDraftFactor, equals(1.0));
      expect(burritoBlockedRes.aeroDragWatts, greaterThan(normalDraftRes.aeroDragWatts));
    });

    test('ERG mode zeroes simulated trainer gradient and tracks target power', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final rider = buildRider(distanceMeters: 1200.0, currentPowerWatts: 250.0);

      final res = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 380.0,
          controlMode: EsportsTrainerControlMode.ergMode,
          deltaTimeSeconds: 2.0,
        ),
      );

      expect(res.simulatedTrainerGradientPercent, equals(0.0));
      expect(res.ergTargetPowerWatts, greaterThan(340.0));
      expect(res.ergTargetPowerWatts, lessThanOrEqualTo(380.0));
    });

    test('Dual-recording mismatch disqualifies non-compliant rider', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final nonCompliantTrainer = SmartTrainerHardwareSpec.proDirectDrive().copyWith(
        dualPowerMeterVerified: false,
      );
      final rider = buildRider(
        trainerSpec: nonCompliantTrainer,
        dualRecordingDeltaPercent: 3.4,
      );

      final res = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 400.0,
        ),
      );

      expect(res.dualRecordingStatus, DualRecordingComplianceStatus.disqualified);
      expect(
        res.updatedRider.verdict,
        EsportsAvatarVerdict.disqualifiedDualRecording,
      );
      expect(res.speedKmh, equals(0.0));
    });

    test('W prime depletes above FTP and recovers below FTP', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final rider = buildRider(
        ftpWatts: 380.0,
        currentPowerWatts: 480.0,
        wPrimeRemaining: 15000.0,
      );

      final surgeRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: rider,
          world: world,
          targetPowerWatts: 480.0,
          deltaTimeSeconds: 5.0,
        ),
      );
      expect(surgeRes.updatedRider.wPrimeRemainingJoules, lessThan(15000.0));

      final recoverRes = solver.solveRiderPhysicsStep(
        EsportsRiderPhysicsInput(
          rider: surgeRes.updatedRider.copyWith(currentPowerWatts: 250.0),
          world: world,
          targetPowerWatts: 250.0,
          deltaTimeSeconds: 5.0,
        ),
      );
      expect(
        recoverRes.updatedRider.wPrimeRemainingJoules,
        greaterThan(surgeRes.updatedRider.wPrimeRemainingJoules),
      );
    });

    test('Strategy holds Featherweight on flat before climb and activates on climb', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final flatRider = buildRider(
        distanceMeters: 850.0, // 150m before 6.5% ramp
        slot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.featherweight,
          state: EsportsPowerUpSlotState.ready,
        ),
      );

      final flatDecision = solver.evaluatePowerUpStrategy(
        rider: flatRider,
        world: world,
      );
      expect(flatDecision.shouldActivateNow, isFalse);
      expect(flatDecision.recommendedAction, EsportsPowerUpAction.holdForClimb);

      final climbRider = flatRider.copyWith(distanceMeters: 1200.0);
      final climbDecision = solver.evaluatePowerUpStrategy(
        rider: climbRider,
        world: world,
      );
      expect(climbDecision.shouldActivateNow, isTrue);
      expect(climbDecision.recommendedAction, EsportsPowerUpAction.activateNow);
    });

    test('Strategy triggers emergency activation during final 10s elimination warning', () {
      final world = EsportsVirtualWorldSpec.cyberVelodromeArena();
      final endangeredRider = buildRider(
        distanceMeters: 400.0,
        rank: 18,
        slot: const EsportsPowerUpInventorySlot(
          powerUp: EsportsPowerUpType.burrito,
          state: EsportsPowerUpSlotState.ready,
        ),
      );

      final decision = solver.evaluatePowerUpStrategy(
        rider: endangeredRider,
        world: world,
        activeRidersCount: 20,
        eliminationSchedule: const Elimination60sScheduleState(
          elapsedSeconds: 55,
          currentRound: 1,
        ),
      );

      expect(decision.shouldActivateNow, isTrue);
      expect(decision.urgencyScore, greaterThanOrEqualTo(0.9));
    });

    test('Elimination 60s round removes last rider and records photo-finish gap', () {
      final riders = [
        buildRider(id: 'r1', distanceMeters: 1050.0, speedKmh: 45.0),
        buildRider(id: 'r2', distanceMeters: 1040.0, speedKmh: 44.0),
        buildRider(id: 'r3', distanceMeters: 1035.0, speedKmh: 43.2),
      ];
      const schedule = Elimination60sScheduleState(
        elapsedSeconds: 58,
        currentRound: 1,
      );

      final step = solver.evaluateEliminationRound(
        schedule: schedule,
        riders: riders,
        elapsedIncrementSeconds: 2,
      );

      expect(step.eliminationTriggered, isTrue);
      expect(step.updatedSchedule.currentRound, equals(2));
      expect(step.eliminationRecord?.eliminatedRiderId, equals('r3'));
      expect(step.eliminationRecord?.remainingRidersCount, equals(2));
      expect(step.eliminationRecord?.photoFinishGapSeconds, greaterThan(0.0));
      expect(
        step.updatedRiders.firstWhere((r) => r.riderId == 'r3').verdict,
        EsportsAvatarVerdict.eliminated,
      );
    });
  });
}
