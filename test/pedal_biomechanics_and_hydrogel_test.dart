import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/carbohydrate_hydrogel_and_ketones_engine.dart';
import 'package:pro_peloton_manager/engine/physics/nutrition_and_glycogen_engine.dart';
import 'package:pro_peloton_manager/engine/physics/pedal_stroke_biomechanics_analyzer.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';

void main() {
  group('PedalStrokeBiomechanicsAnalyzer — L/R Balance & Torque Effectiveness', () {
    const PedalStrokeBiomechanicsAnalyzer analyzer =
        PedalStrokeBiomechanicsAnalyzer();

    test('computes natural ~49.2% / 50.8% L/R balance and 360-degree samples', () {
      const PedalStrokeAnalysisInput input = PedalStrokeAnalysisInput(
        targetPowerWatts: 400.0,
        cadenceRpm: 92.0,
        crankLengthMm: 172.5,
        posture: PedalingPosture.seatedNormal,
        fatigueLevel: 0.10,
        techniqueSkill: 0.85,
        kneeInjurySide: KneeInjurySide.none,
        kneeInjurySeverity: 0.0,
      );

      final PedalStrokeAnalysisResult result = analyzer.analyze(input);

      expect(result.samples.length, 360);
      expect(result.totalPowerWatts, closeTo(400.0, 0.5));
      expect(
        result.leftPowerWatts + result.rightPowerWatts,
        closeTo(result.totalPowerWatts, 1e-6),
      );
      expect(result.leftBalancePercent, closeTo(49.2, 0.15));
      expect(result.rightBalancePercent, closeTo(50.8, 0.15));
      expect(
        result.leftBalancePercent + result.rightBalancePercent,
        closeTo(100.0, 1e-6),
      );
      expect(result.status, PedalStrokeStatus.balanced);
      expect(result.combinedTorqueEffectivenessPercent, inInclusiveRange(55.0, 99.0));
      expect(result.combinedPedalSmoothnessPercent, inInclusiveRange(30.0, 75.0));
      expect(result.leftPeakAngleDeg, inInclusiveRange(70.0, 120.0));
      expect(result.rightPeakAngleDeg, inInclusiveRange(70.0, 120.0));
    });

    test('shifts L/R balance to ~44% / 56% on full left knee injury compensation', () {
      const PedalStrokeAnalysisInput leftInjured = PedalStrokeAnalysisInput(
        targetPowerWatts: 320.0,
        cadenceRpm: 85.0,
        kneeInjurySide: KneeInjurySide.left,
        kneeInjurySeverity: 1.0,
      );

      final PedalStrokeAnalysisResult leftResult = analyzer.analyze(leftInjured);

      expect(leftResult.leftBalancePercent, closeTo(44.0, 0.25));
      expect(leftResult.rightBalancePercent, closeTo(56.0, 0.25));
      expect(leftResult.asymmetryDeltaPercent, closeTo(12.0, 0.5));
      expect(leftResult.status, PedalStrokeStatus.injuryCompensation);

      const PedalStrokeAnalysisInput rightInjured = PedalStrokeAnalysisInput(
        targetPowerWatts: 320.0,
        cadenceRpm: 85.0,
        kneeInjurySide: KneeInjurySide.right,
        kneeInjurySeverity: 1.0,
      );

      final PedalStrokeAnalysisResult rightResult = analyzer.analyze(rightInjured);

      expect(rightResult.rightBalancePercent, closeTo(44.0, 0.25));
      expect(rightResult.leftBalancePercent, closeTo(56.0, 0.25));
      expect(rightResult.status, PedalStrokeStatus.injuryCompensation);
    });

    test('detects mild asymmetry for moderate bias without severe injury', () {
      const PedalStrokeAnalysisInput input = PedalStrokeAnalysisInput(
        targetPowerWatts: 280.0,
        cadenceRpm: 88.0,
        naturalRightDominanceBias: 0.02, // 48% / 52% -> delta 4.0%
      );

      final PedalStrokeAnalysisResult result = analyzer.analyze(input);

      expect(result.asymmetryDeltaPercent, closeTo(4.0, 0.2));
      expect(result.status, PedalStrokeStatus.mildAsymmetry);
    });

    test('returns coasting state when power or cadence is zero', () {
      const PedalStrokeAnalysisInput input = PedalStrokeAnalysisInput(
        targetPowerWatts: 0.0,
        cadenceRpm: 0.0,
      );

      final PedalStrokeAnalysisResult result = analyzer.analyze(input);

      expect(result.status, PedalStrokeStatus.coasting);
      expect(result.totalPowerWatts, 0.0);
      expect(result.leftBalancePercent, 50.0);
      expect(result.rightBalancePercent, 50.0);
      expect(result.combinedTorqueEffectivenessPercent, 0.0);
      expect(result.combinedPedalSmoothnessPercent, 0.0);
      expect(result.samples.length, 360);
    });

    test('higher technique skill and lower fatigue increase Torque Effectiveness & Smoothness', () {
      const PedalStrokeAnalysisInput eliteFresh = PedalStrokeAnalysisInput(
        targetPowerWatts: 380.0,
        cadenceRpm: 95.0,
        posture: PedalingPosture.seatedAero,
        fatigueLevel: 0.05,
        techniqueSkill: 0.95,
      );
      const PedalStrokeAnalysisInput amateurFatigued = PedalStrokeAnalysisInput(
        targetPowerWatts: 380.0,
        cadenceRpm: 95.0,
        posture: PedalingPosture.standingOutOfSaddle,
        fatigueLevel: 0.90,
        techniqueSkill: 0.20,
      );

      final PedalStrokeAnalysisResult freshResult = analyzer.analyze(eliteFresh);
      final PedalStrokeAnalysisResult fatiguedResult =
          analyzer.analyze(amateurFatigued);

      expect(
        freshResult.combinedTorqueEffectivenessPercent,
        greaterThan(fatiguedResult.combinedTorqueEffectivenessPercent),
      );
      expect(
        freshResult.combinedPedalSmoothnessPercent,
        greaterThan(fatiguedResult.combinedPedalSmoothnessPercent),
      );
      expect(
        freshResult.leftTorqueEffectivenessPercent,
        inInclusiveRange(0.0, 100.0),
      );
      expect(
        freshResult.rightTorqueEffectivenessPercent,
        inInclusiveRange(0.0, 100.0),
      );
    });
  });

  group('CarbohydrateHydrogelAndKetonesEngine — 110 g/h Hydrogel & Bicarbonate', () {
    const RiderPhysiology testPhysiology = RiderPhysiology(
      heightCm: 181.0,
      weightKg: 68.0,
      bodyFatPercentage: 6.5,
      ftpWatts: 410,
      wPrimeJoules: 24000,
      vo2Max: 84.0,
      maxHr: 192,
      restingHr: 38,
      lactateThresholdHr: 174,
      recoveryRate: 1.15,
      glycogenCapacityGrams: 550.0,
    );

    const RiderSupplementationProfile trainedGutProfile =
        RiderSupplementationProfile(
      riderId: 'rider_trained',
      riderName: 'Tadej P.',
      gutTrainingLevel: 0.90,
      bicarbonateTolerance: 0.85,
    );

    const RiderSupplementationProfile untrainedGutProfile =
        RiderSupplementationProfile(
      riderId: 'rider_untrained',
      riderName: 'Rookie R.',
      gutTrainingLevel: 0.25,
      bicarbonateTolerance: 0.25,
    );

    test('110 g/h hydrogel preserves significantly more glycogen than 60 g/h standard', () {
      final PreRaceNutritionStrategyEvaluation hydrogelEval =
          CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.highCarbHydrogel110g,
        profile: trainedGutProfile,
      );
      final PreRaceNutritionStrategyEvaluation standardEval =
          CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.standard60gCho,
        profile: trainedGutProfile,
      );

      expect(hydrogelEval.meetsGutTrainingRequirement, isTrue);
      expect(hydrogelEval.effectiveCarbAbsorptionGramsPerHour, closeTo(110.0, 1e-6));
      expect(standardEval.effectiveCarbAbsorptionGramsPerHour, closeTo(60.0, 1e-6));

      // Symulacja 2 godzin intensywnej jazdy (360 W) z pełnym żołądkiem CHO.
      NutritionState hydrogelState = NutritionState.initial(testPhysiology).copyWith(
        stomachCarbsGrams: 250.0,
        stomachFluidMl: 1500.0,
      );
      NutritionState standardState = hydrogelState;

      double hydrogelAbsorbedTotal = 0.0;
      double standardAbsorbedTotal = 0.0;

      for (int sec = 0; sec < 7200; sec += 60) {
        final SupplementationRaceStepResult hStep =
            CarbohydrateHydrogelAndKetonesEngine.simulateRaceStep(
          state: hydrogelState,
          physiology: testPhysiology,
          profile: trainedGutProfile,
          strategy: TeamNutritionStrategyType.highCarbHydrogel110g,
          currentPowerWatts: 360.0,
          timeStepSeconds: 60.0,
          deterministicGiRoll01: 0.99,
        );
        hydrogelState = hStep.nutritionState;
        hydrogelAbsorbedTotal += hStep.carbsAbsorbedGrams;

        final SupplementationRaceStepResult sStep =
            CarbohydrateHydrogelAndKetonesEngine.simulateRaceStep(
          state: standardState,
          physiology: testPhysiology,
          profile: trainedGutProfile,
          strategy: TeamNutritionStrategyType.standard60gCho,
          currentPowerWatts: 360.0,
          timeStepSeconds: 60.0,
          deterministicGiRoll01: 0.99,
        );
        standardState = sStep.nutritionState;
        standardAbsorbedTotal += sStep.carbsAbsorbedGrams;
      }

      // W ciągu 2h hydrożel dostarcza ~220g vs ~120g w standardzie (+100g różnicy).
      expect(hydrogelAbsorbedTotal, closeTo(220.0, 1.0));
      expect(standardAbsorbedTotal, closeTo(120.0, 1.0));
      expect(
        hydrogelState.currentGlycogenGrams,
        greaterThan(standardState.currentGlycogenGrams + 90.0),
      );
    });

    test('untrained gut on 110 g/h hydrogel suffers elevated GI distress risk and FTP penalty', () {
      final PreRaceNutritionStrategyEvaluation untrainedEval =
          CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.highCarbHydrogel110g,
        profile: untrainedGutProfile,
        raceTemperatureCelsius: 33.0,
      );

      expect(untrainedEval.meetsGutTrainingRequirement, isFalse);
      expect(untrainedEval.effectiveCarbAbsorptionGramsPerHour, lessThan(110.0));
      expect(untrainedEval.giDistressRiskFraction, greaterThan(0.25));

      // Wymuszone wystąpienie ciężkiego GI Distress (roll = 0.01 < risk * 0.25).
      final SupplementationRaceStepResult stepWithDistress =
          CarbohydrateHydrogelAndKetonesEngine.simulateRaceStep(
        state: NutritionState.initial(testPhysiology),
        physiology: testPhysiology,
        profile: untrainedGutProfile,
        strategy: TeamNutritionStrategyType.highCarbHydrogel110g,
        currentPowerWatts: 340.0,
        temperatureCelsius: 33.0,
        timeStepSeconds: 60.0,
        deterministicGiRoll01: 0.01,
      );

      expect(stepWithDistress.giOutcome.severity, GiDistressSeverity.severe);
      expect(stepWithDistress.giOutcome.ftpPenaltyFraction, closeTo(0.12, 1e-6));
      expect(stepWithDistress.effectiveFtpWatts, closeTo(410.0 * 0.88, 0.5));
      expect(stepWithDistress.giOutcome.absorptionMultiplier, closeTo(0.50, 1e-6));
    });

    test('bicarbonate pre-load increases W\' capacity by +6% and scales GI risk by tolerance', () {
      final double baseWPrime =
          CarbohydrateHydrogelAndKetonesEngine.computeEffectiveWPrimeJoules(
        physiology: testPhysiology,
        strategy: TeamNutritionStrategyType.standard60gCho,
      );
      final double bicarbWPrime =
          CarbohydrateHydrogelAndKetonesEngine.computeEffectiveWPrimeJoules(
        physiology: testPhysiology,
        strategy: TeamNutritionStrategyType.bicarbonatePreLoad,
      );

      expect(baseWPrime, closeTo(24000.0, 1e-6));
      expect(bicarbWPrime, closeTo(24000.0 * 1.06, 1e-6));

      final SupplementationRaceStepResult bicarbStep =
          CarbohydrateHydrogelAndKetonesEngine.simulateRaceStep(
        state: NutritionState.initial(testPhysiology),
        physiology: testPhysiology,
        profile: trainedGutProfile,
        strategy: TeamNutritionStrategyType.bicarbonatePreLoad,
        currentPowerWatts: 450.0,
        timeStepSeconds: 30.0,
        deterministicGiRoll01: 0.99,
      );
      expect(bicarbStep.effectiveWPrimeJoules, closeTo(25440.0, 1e-6));
      expect(bicarbStep.evaluation.lactateBufferingMultiplier, closeTo(1.06, 1e-6));

      final PreRaceNutritionStrategyEvaluation highTolEval =
          CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.bicarbonatePreLoad,
        profile: trainedGutProfile,
      );
      final PreRaceNutritionStrategyEvaluation lowTolEval =
          CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.bicarbonatePreLoad,
        profile: untrainedGutProfile,
      );

      expect(
        lowTolEval.giDistressRiskFraction,
        greaterThan(highTolEval.giDistressRiskFraction),
      );
    });

    test('post-finish exogenous ketones boost overnight glycogen resynthesis & ATL drop by +12%', () {
      final OvernightKetoneRecoveryResult recovery =
          CarbohydrateHydrogelAndKetonesEngine.computeOvernightRecovery(
        strategy: TeamNutritionStrategyType.postFinishExogenousKetones,
        baseFatigueDropAtl: 10.0,
        baseGlycogenResynthesisGrams: 300.0,
        riderRecoveryRate: 1.0,
      );

      expect(recovery.recoveryMultiplier, closeTo(1.12, 1e-6));
      expect(recovery.boostedFatigueDropAtl, closeTo(11.2, 1e-6));
      expect(recovery.boostedGlycogenResynthesisGrams, closeTo(336.0, 1e-6));
    });
  });
}
