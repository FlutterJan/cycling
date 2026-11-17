import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/team_bus_and_warmup_protocol_model.dart';

void main() {
  group('TeamBusAndWarmupProtocolModel', () {
    test('VO2 Priming grants +4.5% start power bonus on ITT with Pro ERG and Ice Vest', () {
      final bus = TeamBusSpecification.forTier(
        TeamBusTier.worldTourFlagshipBus,
        teamName: 'Bora-RedBull',
      );
      var model = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_13_itt',
        stageName: 'Pau - Pau ITT',
        isIndividualTimeTrial: true,
        isTeamTimeTrial: false,
        ambientTempCelsius: 25.0,
        hasSteepEarlyClimb: false,
        teamBus: bus,
      );

      model = model.assignRiderToTrainer(
        riderId: 'r1',
        riderName: 'Remco Evenepoel',
        riderFtpWatts: 430,
        riderWeightKg: 62.5,
        protocolType: WarmupProtocolType.vo2PrimingItt,
        coolingStrategy: CoolingStrategyType.preCoolingIceVest,
        minutesBeforeStart: 12,
      );

      expect(model.assignedRidersCount, 1);
      expect(model.freeTrainerSlotsCount, 7);

      final outcome = model.evaluateRiderWarmup(model.assignments.first);
      expect(outcome.effectiveStartPowerBonusPercent, 4.5);
      expect(outcome.startPowerMultiplier, closeTo(1.045, 0.0001));
      expect(outcome.effectiveStartPowerWatts, closeTo(449.4, 0.2));
      expect(outcome.isOverheatedRisk, isFalse);
      expect(outcome.timingEfficiencyFactor, 1.0);
    });

    test('High heat without Ice Vest triggers overheating risk and reduces bonus', () {
      final bus = TeamBusSpecification.forTier(
        TeamBusTier.worldTourFlagshipBus,
      );
      var model = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_hot_itt',
        stageName: 'Sevilla ITT',
        isIndividualTimeTrial: true,
        isTeamTimeTrial: false,
        ambientTempCelsius: 33.0,
        hasSteepEarlyClimb: false,
        teamBus: bus,
      );

      model = model.assignRiderToTrainer(
        riderId: 'r_hot',
        riderName: 'Filippo Ganna',
        riderFtpWatts: 470,
        riderWeightKg: 82.0,
        protocolType: WarmupProtocolType.vo2PrimingItt,
        coolingStrategy: CoolingStrategyType.none,
        minutesBeforeStart: 12,
      );

      final hotNoCooling = model.evaluateRiderWarmup(model.assignments.first);
      expect(hotNoCooling.isOverheatedRisk, isTrue);
      expect(hotNoCooling.effectiveStartPowerBonusPercent, lessThan(4.5));

      model = model.assignRiderToTrainer(
        riderId: 'r_hot',
        riderName: 'Filippo Ganna',
        riderFtpWatts: 470,
        riderWeightKg: 82.0,
        protocolType: WarmupProtocolType.vo2PrimingItt,
        coolingStrategy: CoolingStrategyType.preCoolingIceVest,
        minutesBeforeStart: 12,
      );

      final hotWithVest = model.evaluateRiderWarmup(model.assignments.first);
      expect(hotWithVest.isOverheatedRisk, isFalse);
      expect(hotWithVest.effectiveStartPowerBonusPercent, 4.5);
    });

    test('Cold start penalizes ITT start power and preserves glycogen', () {
      final bus = TeamBusSpecification.forTier(
        TeamBusTier.continentalMinibus,
      );
      var model = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_itt',
        stageName: 'Prologue',
        isIndividualTimeTrial: true,
        isTeamTimeTrial: false,
        ambientTempCelsius: 18.0,
        hasSteepEarlyClimb: false,
        teamBus: bus,
      );

      model = model.assignRiderToTrainer(
        riderId: 'r_cold',
        riderName: 'Jan Kowalski',
        riderFtpWatts: 380,
        riderWeightKg: 68.0,
        protocolType: WarmupProtocolType.none,
      );

      final outcome = model.evaluateRiderWarmup(model.assignments.first);
      expect(outcome.effectiveStartPowerBonusPercent, -2.5);
      expect(outcome.glycogenSpentGrams, 0.0);
    });

    test('Respects bus trainer capacity and removes riders cleanly', () {
      final bus = TeamBusSpecification.forTier(
        TeamBusTier.continentalMinibus, // 2 slots
      );
      var model = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_1',
        stageName: 'Opening Stage',
        isIndividualTimeTrial: false,
        isTeamTimeTrial: false,
        ambientTempCelsius: 20.0,
        hasSteepEarlyClimb: true,
        teamBus: bus,
      );

      model = model
          .assignRiderToTrainer(
            riderId: 'r1',
            riderName: 'Rider 1',
            riderFtpWatts: 390,
            riderWeightKg: 65.0,
            protocolType: WarmupProtocolType.mountainStartOpener,
          )
          .assignRiderToTrainer(
            riderId: 'r2',
            riderName: 'Rider 2',
            riderFtpWatts: 400,
            riderWeightKg: 67.0,
            protocolType: WarmupProtocolType.mountainStartOpener,
          )
          .assignRiderToTrainer(
            riderId: 'r3',
            riderName: 'Rider 3',
            riderFtpWatts: 410,
            riderWeightKg: 69.0,
            protocolType: WarmupProtocolType.mountainStartOpener,
          );

      expect(model.isPaddockFull, isTrue);
      expect(model.assignedRidersCount, 2);
      expect(model.freeTrainerSlotsCount, 0);

      model = model.removeRiderFromTrainer('r1');
      expect(model.assignedRidersCount, 1);
      expect(model.freeTrainerSlotsCount, 1);
    });

    test('JSON serialization roundtrip preserves complete model state', () {
      final bus = TeamBusSpecification.forTier(
        TeamBusTier.grandTourCommandCenter,
        teamName: 'Visma Lease a Bike',
      );
      final original = TeamBusAndWarmupProtocolModel(
        stageId: 'stage_21_nice_itt',
        stageName: 'Monaco - Nice ITT',
        isIndividualTimeTrial: true,
        isTeamTimeTrial: false,
        ambientTempCelsius: 27.5,
        hasSteepEarlyClimb: true,
        teamBus: bus,
      ).assignRiderToTrainer(
        riderId: 'jonas',
        riderName: 'Jonas Vingegaard',
        riderFtpWatts: 415,
        riderWeightKg: 59.5,
        protocolType: WarmupProtocolType.vo2PrimingItt,
        coolingStrategy: CoolingStrategyType.preCoolingIceVest,
        minutesBeforeStart: 11,
      );

      final json = original.toJson();
      final restored = TeamBusAndWarmupProtocolModel.fromJson(json);

      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
      expect(WarmupProtocolPreset.allPresets.length, 6);
    });
  });
}
