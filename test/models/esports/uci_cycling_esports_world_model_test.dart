import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/esports/uci_cycling_esports_world_model.dart';

void main() {
  group('SmartTrainerHardwareSpec', () {
    test('proDirectDrive i smartBike spełniają wymogi UCI i liczą margines błędu', () {
      final proTrainer = SmartTrainerHardwareSpec.proDirectDrive();
      final smartBike = SmartTrainerHardwareSpec.smartBike();

      expect(proTrainer.isUciCompliant, isTrue);
      expect(smartBike.isUciCompliant, isTrue);
      expect(proTrainer.effectivePowerErrorMarginWatts(400.0), closeTo(4.0, 0.001));
      expect(smartBike.effectivePowerErrorMarginWatts(400.0), closeTo(2.0, 0.001));
      expect(proTrainer.clampSimulatedGradient(30.0), 25.0);
    });

    test('wheelOnBasic lub rozkalibrowany trenażer nie spełniają wymogów UCI', () {
      final wheelOn = SmartTrainerHardwareSpec.proDirectDrive().copyWith(
        tier: SmartTrainerTier.wheelOnBasic,
      );
      final drifted = SmartTrainerHardwareSpec.proDirectDrive().copyWith(
        calibrationStatus: SmartTrainerCalibrationStatus.driftDetected,
      );
      final noDual = SmartTrainerHardwareSpec.proDirectDrive().copyWith(
        dualPowerMeterVerified: false,
      );

      expect(wheelOn.isUciCompliant, isFalse);
      expect(drifted.isUciCompliant, isFalse);
      expect(noDual.isUciCompliant, isFalse);
    });
  });

  group('EsportsPowerUpSpec & EsportsPowerUpInventorySlot', () {
    test('katalog Power-Upów zawiera Aero Helmet, Featherweight i Burrito', () {
      final aero = EsportsPowerUpSpec.forType(EsportsPowerUpType.aeroHelmet);
      final feather = EsportsPowerUpSpec.forType(EsportsPowerUpType.featherweight);
      final burrito = EsportsPowerUpSpec.forType(EsportsPowerUpType.burrito);

      expect(aero.displayName, 'Aero Helmet');
      expect(aero.cdaMultiplier, 0.75);
      expect(aero.durationSeconds, 15.0);

      expect(feather.displayName, 'Featherweight');
      expect(feather.massMultiplier, 0.90);
      expect(feather.isOptimalForGradient(8.0), isTrue);

      expect(burrito.displayName, 'Burrito');
      expect(burrito.disablesRivalDraftBehind, isTrue);
      expect(burrito.disablesRivalDraftRadiusMeters, 10.0);
      expect(burrito.durationSeconds, 10.0);
    });

    test('aktywacja i odliczanie czasu trwania Power-Upa', () {
      const slot = EsportsPowerUpInventorySlot(
        powerUp: EsportsPowerUpType.burrito,
        state: EsportsPowerUpSlotState.ready,
      );

      final active = slot.activate();
      expect(active.state, EsportsPowerUpSlotState.active);
      expect(active.remainingActiveSeconds, 10.0);

      final mid = active.tick(4.0);
      expect(mid.state, EsportsPowerUpSlotState.active);
      expect(mid.remainingActiveSeconds, 6.0);

      final expired = mid.tick(6.0);
      expect(expired.state, EsportsPowerUpSlotState.empty);
      expect(expired.powerUp, isNull);
    });
  });

  group('Elimination60sScheduleState & UciCyclingEsportsWorldModel', () {
    test('harmonogram eliminacji co 60 s wykrywa alarm 10 s i rejestruje odpadnięcia', () {
      var schedule = const Elimination60sScheduleState(
        intervalSeconds: 60,
        currentRound: 1,
        elapsedSeconds: 52,
      );

      expect(schedule.nextTriggerSecond, 60);
      expect(schedule.secondsUntilNextElimination, 8);
      expect(schedule.isInFinalTenSecondsWarning, isTrue);

      final world = UciCyclingEsportsWorldModel.uciWorldChampionshipElimination();
      final atRisk = world.atRiskEliminationRider;
      expect(atRisk, isNotNull);
      expect(atRisk!.riderId, 'esp_r4');

      schedule = schedule.copyWith(elapsedSeconds: 60).recordElimination(
        eliminatedRider: atRisk,
        remainingCount: 3,
      );

      expect(schedule.currentRound, 2);
      expect(schedule.nextTriggerSecond, 120);
      expect(schedule.lastEliminatedRiderId, 'esp_r4');
      expect(schedule.eliminationHistory, hasLength(1));
    });

    test('serializacja JSON round-trip zachowuje wszystkie dane modelu', () {
      final original =
          UciCyclingEsportsWorldModel.uciWorldChampionshipElimination();
      final json = original.toJson();
      final decoded = UciCyclingEsportsWorldModel.fromJson(json);

      expect(decoded.eventId, original.eventId);
      expect(decoded.platformTier, original.platformTier);
      expect(decoded.raceFormat, original.raceFormat);
      expect(decoded.worldSpec.segments.length, original.worldSpec.segments.length);
      expect(decoded.riders.length, original.riders.length);
      expect(decoded.talentIdPool.length, original.talentIdPool.length);
      expect(decoded.riders.first.powerUpSlot.powerUp,
          EsportsPowerUpType.aeroHelmet);
      expect(decoded.checkDualRecordingCompliance(decoded.riders.first), isTrue);
    });
  });
}
