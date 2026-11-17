import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/carbohydrate_hydrogel_and_ketones_engine.dart';
import 'package:pro_peloton_manager/engine/physics/nutrition_and_glycogen_engine.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';

void main() {
  const RiderPhysiology samplePhysiology = RiderPhysiology(
    heightCm: 180.0,
    weightKg: 68.0,
    bodyFatPercentage: 7.5,
    ftpWatts: 400,
    wPrimeJoules: 22000,
    vo2Max: 82.0,
    maxHr: 192,
    restingHr: 38,
    lactateThresholdHr: 174,
    recoveryRate: 1.0,
    glycogenCapacityGrams: 600.0,
  );

  group('CarbohydrateHydrogelAndKetonesEngine', () {
    test('Standard 60g/h CHO provides 60g/h with minimal GI risk and no gut requirement', () {
      const profile = RiderSupplementationProfile(
        riderId: 'r1',
        riderName: 'Domestique',
        gutTrainingLevel: 0.20,
      );

      final eval = CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.standard60gCho,
        profile: profile,
      );

      expect(eval.effectiveCarbAbsorptionGramsPerHour, closeTo(60.0, 0.01));
      expect(eval.meetsGutTrainingRequirement, isTrue);
      expect(eval.wPrimeMultiplier, closeTo(1.0, 0.001));
      expect(eval.overnightRecoveryMultiplier, closeTo(1.0, 0.001));
      expect(eval.giDistressRiskFraction, lessThan(0.05));
    });

    test('High-Carb Hydrogel 110g/h requires gutTrainingLevel >= 0.70 for full 110g/h', () {
      const trainedProfile = RiderSupplementationProfile(
        riderId: 'r2',
        riderName: 'Trained Leader',
        gutTrainingLevel: 0.85,
      );
      const untrainedProfile = RiderSupplementationProfile(
        riderId: 'r3',
        riderName: 'Untrained Rider',
        gutTrainingLevel: 0.30,
      );

      final trainedEval = CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.highCarbHydrogel110g,
        profile: trainedProfile,
      );
      final untrainedEval = CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.highCarbHydrogel110g,
        profile: untrainedProfile,
      );

      expect(trainedEval.meetsGutTrainingRequirement, isTrue);
      expect(trainedEval.effectiveCarbAbsorptionGramsPerHour, closeTo(110.0, 0.01));
      expect(untrainedEval.meetsGutTrainingRequirement, isFalse);
      expect(untrainedEval.effectiveCarbAbsorptionGramsPerHour, lessThan(110.0));
      expect(untrainedEval.giDistressRiskFraction, greaterThan(trainedEval.giDistressRiskFraction));
    });

    test('Bicarbonate Pre-Load boosts W\' capacity and lactate buffering by +6% with GI Distress risk', () {
      const profile = RiderSupplementationProfile(
        riderId: 'r4',
        riderName: 'Puncheur',
        gutTrainingLevel: 0.60,
        bicarbonateTolerance: 0.50,
      );

      final eval = CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.bicarbonatePreLoad,
        profile: profile,
      );
      final effectiveWPrime = CarbohydrateHydrogelAndKetonesEngine.computeEffectiveWPrimeJoules(
        physiology: samplePhysiology,
        strategy: TeamNutritionStrategyType.bicarbonatePreLoad,
      );

      expect(eval.wPrimeMultiplier, closeTo(1.06, 0.0001));
      expect(eval.lactateBufferingMultiplier, closeTo(1.06, 0.0001));
      expect(effectiveWPrime, closeTo(22000.0 * 1.06, 0.01));
      expect(eval.giDistressRiskFraction, greaterThan(0.08));

      final severeGi = CarbohydrateHydrogelAndKetonesEngine.evaluateGiDistress(
        evaluation: eval,
        deterministicRoll01: 0.01,
      );
      expect(severeGi.hasDistress, isTrue);
      expect(severeGi.severity, GiDistressSeverity.severe);
      expect(severeGi.ftpPenaltyFraction, closeTo(0.12, 0.001));
    });

    test('Post-Finish Exogenous Ketones accelerates overnight recovery by +12%', () {
      final recovery = CarbohydrateHydrogelAndKetonesEngine.computeOvernightRecovery(
        strategy: TeamNutritionStrategyType.postFinishExogenousKetones,
        baseFatigueDropAtl: 20.0,
        baseGlycogenResynthesisGrams: 300.0,
      );

      expect(recovery.recoveryMultiplier, closeTo(1.12, 0.0001));
      expect(recovery.boostedFatigueDropAtl, closeTo(22.4, 0.01));
      expect(recovery.boostedGlycogenResynthesisGrams, closeTo(336.0, 0.01));
      expect(recovery.recoveryBoostPercent, closeTo(12.0, 0.01));
    });

    test('simulateRaceStep integrates hydrogel absorption and GI distress penalties', () {
      const profile = RiderSupplementationProfile(
        riderId: 'r5',
        riderName: 'GC Contender',
        gutTrainingLevel: 0.90,
      );
      final initialState = NutritionState.initial(samplePhysiology).copyWith(
        stomachCarbsGrams: 120.0,
      );

      final stepClean = CarbohydrateHydrogelAndKetonesEngine.simulateRaceStep(
        state: initialState,
        physiology: samplePhysiology,
        profile: profile,
        strategy: TeamNutritionStrategyType.highCarbHydrogel110g,
        currentPowerWatts: 360.0,
        timeStepSeconds: 60.0,
        deterministicGiRoll01: 0.95,
      );

      expect(stepClean.giOutcome.hasDistress, isFalse);
      expect(stepClean.carbsAbsorbedGrams, closeTo((110.0 / 3600.0) * 60.0, 0.01));
      expect(stepClean.effectiveFtpWatts, closeTo(400.0, 0.01));
    });

    test('evaluateTeamRosterPlan aggregates cost, warnings, and empty map safely', () {
      final emptySummary = CarbohydrateHydrogelAndKetonesEngine.evaluateTeamRosterPlan(
        assignments: {},
      );
      expect(emptySummary.riderCount, 0);
      expect(emptySummary.totalCostEur, 0);

      const r1 = RiderSupplementationProfile(
        riderId: '1',
        riderName: 'A',
        gutTrainingLevel: 0.40,
      );
      const r2 = RiderSupplementationProfile(
        riderId: '2',
        riderName: 'B',
        gutTrainingLevel: 0.85,
      );

      final summary = CarbohydrateHydrogelAndKetonesEngine.evaluateTeamRosterPlan(
        assignments: {
          r1: TeamNutritionStrategyType.highCarbHydrogel110g,
          r2: TeamNutritionStrategyType.postFinishExogenousKetones,
        },
      );

      expect(summary.riderCount, 2);
      expect(summary.totalCostEur, 45 + 85);
      expect(summary.gutTrainingWarningCount, 1);
    });
  });

  group('CarbohydrateHydrogelAndKetonesPanel responsive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        TeamNutritionStrategyType? appliedStrategy;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: CarbohydrateHydrogelAndKetonesPanel(
                  onStrategyApplied: (s) => appliedStrategy = s,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Bicarbonate Pre-Load'), findsOneWidget);
        await tester.tap(find.text('Bicarbonate Pre-Load'));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.ensureVisible(find.textContaining('Zatwierdź Strategię'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.textContaining('Zatwierdź Strategię'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(appliedStrategy, TeamNutritionStrategyType.bicarbonatePreLoad);
      });
    }
  });
}
