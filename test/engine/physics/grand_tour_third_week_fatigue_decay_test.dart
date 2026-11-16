import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/grand_tour_third_week_fatigue_decay.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';

void main() {
  group('GrandTourThirdWeekFatigueDecay', () {
    test('etapy <= 14 nie generują spadku 3. tygodnia', () {
      for (final stage in [1, 7, 14]) {
        final result = GrandTourThirdWeekFatigueDecay.evaluate(
          stageNumber: stage,
          recoveryRate: 0.90,
        );
        expect(result.thirdWeekProgress, 0.0);
        expect(result.thresholdPowerDecayRatio, 0.0);
        expect(result.vo2MaxDecayRatio, 0.0);
        expect(result.hepaticGlycogenDecayRatio, 0.0);
        expect(result.thresholdPowerRetentionFactor, 1.0);
      }
    });

    test('specjaliści od Grand Tourów (recoveryRate 1.25..1.40) tracą 2–3% mocy progowej do etapu 21', () {
      final eliteGt = GrandTourThirdWeekFatigueDecay.evaluate(
        stageNumber: 21,
        recoveryRate: 1.40,
      );
      final strongGt = GrandTourThirdWeekFatigueDecay.evaluate(
        stageNumber: 21,
        recoveryRate: 1.25,
      );

      expect(
        eliteGt.resilienceTier,
        GrandTourFatigueResilienceTier.grandTourSpecialist,
      );
      expect(eliteGt.thresholdPowerDecayRatio, closeTo(0.020, 0.001));
      expect(strongGt.thresholdPowerDecayRatio, inInclusiveRange(0.020, 0.030));
      expect(strongGt.vo2MaxDecayRatio, greaterThan(0.0));
      expect(
        strongGt.hepaticGlycogenDecayRatio,
        greaterThan(strongGt.thresholdPowerDecayRatio),
      );
    });

    test('kolarze 1-dniowi (recoveryRate 0.80..0.95) tracą 9–14% mocy progowej do etapu 21', () {
      final pureSprinter = GrandTourThirdWeekFatigueDecay.evaluate(
        stageNumber: 21,
        recoveryRate: 0.80,
      );
      final classicRider = GrandTourThirdWeekFatigueDecay.evaluate(
        stageNumber: 21,
        recoveryRate: 0.95,
      );

      expect(
        classicRider.resilienceTier,
        GrandTourFatigueResilienceTier.oneDayClassicSpecialist,
      );
      expect(pureSprinter.thresholdPowerDecayRatio, closeTo(0.140, 0.001));
      expect(
        classicRider.thresholdPowerDecayRatio,
        inInclusiveRange(0.090, 0.140),
      );
    });

    test('progresja między etapem 14 a 21 jest ściśle rosnąca', () {
      final progression =
          GrandTourThirdWeekFatigueDecay.simulateStageProgression(
        recoveryRate: 1.05,
        startStage: 14,
        endStage: 21,
      );

      expect(progression.length, 8);
      expect(progression.first.stageNumber, 14);
      expect(progression.last.stageNumber, 21);

      for (int i = 1; i < progression.length; i++) {
        expect(
          progression[i].thresholdPowerDecayRatio,
          greaterThan(progression[i - 1].thresholdPowerDecayRatio),
        );
        expect(
          progression[i].vo2MaxDecayRatio,
          greaterThan(progression[i - 1].vo2MaxDecayRatio),
        );
        expect(
          progression[i].hepaticGlycogenDecayRatio,
          greaterThan(progression[i - 1].hepaticGlycogenDecayRatio),
        );
      }
    });

    test('applyToPhysiology poprawnie redukuje FTP, VO2max i pojemność glikogenu', () {
      const basePhysiology = RiderPhysiology(
        heightCm: 178.0,
        weightKg: 64.0,
        bodyFatPercentage: 5.5,
        ftpWatts: 400,
        wPrimeJoules: 20000,
        vo2Max: 84.0,
        maxHr: 194,
        restingHr: 38,
        lactateThresholdHr: 174,
        recoveryRate: 1.30,
        glycogenCapacityGrams: 600.0,
      );

      final result = GrandTourThirdWeekFatigueDecay.evaluateForPhysiology(
        physiology: basePhysiology,
        stageNumber: 21,
      );
      final decayed = result.applyToPhysiology(basePhysiology);

      expect(decayed.ftpWatts, lessThan(basePhysiology.ftpWatts));
      expect(decayed.ftpWatts, inInclusiveRange(388, 392));
      expect(decayed.vo2Max, lessThan(basePhysiology.vo2Max));
      expect(
        decayed.glycogenCapacityGrams,
        lessThan(basePhysiology.glycogenCapacityGrams),
      );
    });

    test('serializacja JSON zachowuje wszystkie pola wyniku', () {
      final original = GrandTourThirdWeekFatigueDecay.evaluate(
        stageNumber: 19,
        recoveryRate: 1.12,
      );
      final restored = GrandTourThirdWeekFatigueResult.fromJson(
        original.toJson(),
      );
      expect(restored, original);
    });
  });
}
