import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/ultra_endurance_bikepacking_race_model.dart';

void main() {
  group('UltraEnduranceBikepackingRaceModel', () {
    test('transcontinental4000KmPreset initializes 4000 km route and checkpoints', () {
      final race =
          UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset();

      expect(race.totalDistanceKm, 4000.0);
      expect(race.checkpoints.length, 5);
      expect(race.routeSegments.length, 4);
      expect(race.mandatoryCheckpoints.length, 4);
      expect(race.defaultLoadout.isMandatoryGearComplete, isTrue);
      expect(race.defaultDynamoHub.tier, DynamoHubTier.highEfficiencySon28);
    });

    test('BikepackingLoadout computes weight, aero penalty and missing gear', () {
      final loadout = BikepackingLoadout.ultraRaceMinimal();
      expect(loadout.totalBagVolumeLiters, closeTo(14.5, 0.01));
      expect(loadout.totalGearWeightKg, closeTo(3.845, 0.01));
      expect(loadout.totalAeroDragWatts(30.0 / 3.6), greaterThan(2.5));
      expect(
        loadout.climbingWeightPenaltyWatts(gradePercent: 8.0, speedMs: 4.0),
        greaterThan(10.0),
      );

      final incomplete = loadout.copyWith(
        hasBivyBag: false,
        headlightLumens: 200,
      );
      expect(incomplete.isMandatoryGearComplete, isFalse);
      expect(incomplete.missingMandatoryItems, contains('Bivy Bag'));
      expect(
        incomplete.missingMandatoryItems,
        contains('Front Light (>=400 lm)'),
      );
    });

    test('DynamoHubSpec output curve and ElectronicsPowerState budget', () {
      final dynamo = DynamoHubSpec.son28Ultra();
      expect(dynamo.electricalOutputWattsAtSpeed(4.0), 0.0);
      expect(dynamo.electricalOutputWattsAtSpeed(20.0), closeTo(4.8, 0.01));
      expect(dynamo.electricalOutputWattsAtSpeed(35.0), closeTo(7.5, 0.01));
      expect(dynamo.mechanicalDragWattsAtSpeed(25.0), greaterThan(4.0));

      final disengaged = dynamo.copyWith(isEngaged: false);
      expect(disengaged.electricalOutputWattsAtSpeed(25.0), 0.0);
      expect(disengaged.mechanicalDragWattsAtSpeed(25.0), lessThan(1.0));

      const electronics = ElectronicsPowerState(
        powerBankMah: 5000.0,
        powerBankCapacityMah: 10000.0,
      );
      final dayStep = electronics.stepPowerBudget(
        durationHours: 4.0,
        avgSpeedKmh: 26.0,
        dynamoHub: dynamo,
        isNight: false,
      );
      expect(dayStep.netWh, greaterThan(0.0));
      expect(dayStep.updatedState.powerBankMah, greaterThan(5000.0));
      expect(dayStep.hasLightsOutRisk, isFalse);

      final batteryOnly = DynamoHubSpec.batteryOnly();
      final nightDrain = const ElectronicsPowerState(
        powerBankMah: 0.0,
        powerBankCapacityMah: 10000.0,
        headlightBatteryPercent: 20.0,
      ).stepPowerBudget(
        durationHours: 3.0,
        avgSpeedKmh: 22.0,
        dynamoHub: batteryOnly,
        isNight: true,
      );
      expect(nightDrain.netWh, lessThan(0.0));
      expect(nightDrain.updatedState.headlightBatteryPercent, lessThan(15.0));
      expect(nightDrain.hasLightsOutRisk, isTrue);
    });

    test('simulateRidingBlock advances checkpoints and applies sleep recovery', () {
      final race =
          UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset();
      var progress = const UltraBikepackingRiderProgress(riderId: 'rider_ultra_1');

      progress = race.simulateRidingBlock(
        progress: progress,
        durationHours: 40.0,
        baseCruisingSpeedKmh: 28.0,
        loadout: race.defaultLoadout,
        dynamoHub: race.defaultDynamoHub,
        isNight: false,
        segment: race.routeSegments.first,
      );

      expect(progress.distanceCoveredKm, greaterThan(1000.0));
      expect(progress.visitedCheckpointIds, contains('cp_0_start'));
      expect(progress.sleepDeprivationPowerMultiplier, lessThan(1.0));
      expect(progress.hallucinationAndCrashRisk(isNight: true), greaterThan(0.5));

      final rested = progress.applySleepStop(
        UltraSleepStrategy.hotel5Hours,
        isWarmShelter: true,
      );
      expect(rested.hoursSinceLastSleep, 0.0);
      expect(rested.totalSleepHours, 5.0);
      expect(rested.electronicsState.powerBankPercent, 100.0);
    });

    test('JSON serialization round-trip preserves all fields', () {
      final original =
          UltraEnduranceBikepackingRaceModel.transcontinental4000KmPreset();
      final json = original.toJson();
      final restored = UltraEnduranceBikepackingRaceModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.series, original.series);
      expect(restored.totalDistanceKm, original.totalDistanceKm);
      expect(restored.checkpoints.length, original.checkpoints.length);
      expect(restored.routeSegments.length, original.routeSegments.length);
      expect(
        restored.defaultLoadout.bags.length,
        original.defaultLoadout.bags.length,
      );
      expect(restored.defaultDynamoHub.name, original.defaultDynamoHub.name);
    });
  });
}
