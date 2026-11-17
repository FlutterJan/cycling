import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/gravel_rolling_resistance_and_sealant_solver.dart';
import 'package:pro_peloton_manager/models/equipment/gravel_bike_and_tire_inserts_model.dart';
import 'package:pro_peloton_manager/models/race/gravel_race_and_surface_model.dart';

void main() {
  const solver = GravelRollingResistanceAndSealantSolver();

  group('GravelBikeAndTireInsertsModel & Equipment Specs', () {
    test('presety sprzętu szutrowego mają poprawny prześwit i brak ostrzeżeń', () {
      final uci = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final flint = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      final mud =
          GravelBikeAndTireInsertsModel.technicalMudAndSingletrackPreset();

      expect(uci.isTireClearanceValid, isTrue);
      expect(uci.isInsertWidthCompatible, isTrue);
      expect(uci.hasValidConfiguration, isTrue);
      expect(uci.configurationWarnings, isEmpty);

      expect(flint.isTireClearanceValid, isTrue);
      expect(flint.isInsertWidthCompatible, isTrue);
      expect(flint.hasValidConfiguration, isTrue);

      expect(mud.isTireClearanceValid, isTrue);
      expect(mud.isInsertWidthCompatible, isTrue);
      expect(mud.hasValidConfiguration, isTrue);
    });

    test('walidacja wykrywa przekroczenie prześwitu ramy, złą szerokość wkładki i niskie ciśnienie', () {
      final base = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final oversizedTire = base.frontTire.copyWith(widthMm: 48.0);
      final invalidSetup = base.copyWith(
        frontTire: oversizedTire,
        frontPressureBar: 1.20,
      );

      expect(invalidSetup.isTireClearanceValid, isFalse);
      expect(invalidSetup.isInsertWidthCompatible, isFalse);
      expect(invalidSetup.hasValidConfiguration, isFalse);
      expect(invalidSetup.configurationWarnings.length, greaterThanOrEqualTo(3));
    });

    test('consumeFluid pobiera płyn najpierw z plecaka bukłakowego, a potem z bidonów', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final initialPackMl = setup.hydrationPack.currentFluidMl;
      final initialBottlesMl = setup.currentFrameBottlesFluidMl;

      final afterPackDrink = setup.consumeFluid(500.0);
      expect(afterPackDrink.hydrationPack.currentFluidMl,
          closeTo(initialPackMl - 500.0, 0.01));
      expect(afterPackDrink.currentFrameBottlesFluidMl,
          closeTo(initialBottlesMl, 0.01));

      final afterLargeDrink = setup.consumeFluid(initialPackMl + 400.0);
      expect(afterLargeDrink.hydrationPack.currentFluidMl, closeTo(0.0, 0.01));
      expect(afterLargeDrink.currentFrameBottlesFluidMl,
          closeTo(initialBottlesMl - 400.0, 0.01));
    });

    test('serializacja JSON modeli szutrowych zachowuje wszystkie parametry', () {
      final original = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      final json = original.toJson();
      final restored = GravelBikeAndTireInsertsModel.fromJson(json);

      expect(restored, equals(original));
      expect(restored.frontPressureBar, closeTo(original.frontPressureBar, 1e-6));
      expect(restored.rearPressureBar, closeTo(original.rearPressureBar, 1e-6));
      expect(restored.tireInserts.runFlatMaxRangeKm,
          closeTo(original.tireInserts.runFlatMaxRangeKm, 1e-6));
      expect(restored.tubelessSealant.remainingVolumeMlFront,
          closeTo(original.tubelessSealant.remainingVolumeMlFront, 1e-6));
    });

    test('evaluateForRace ocenia gotowość zestawu na Mistrzostwa Świata UCI Gravel', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final race = GravelRaceAndSurfaceModel.uciGravelWorldsVeneto();

      final report = setup.evaluateForRace(race);

      expect(report.isClearanceValid, isTrue);
      expect(report.suitabilityScore, inInclusiveRange(50.0, 100.0));
      expect(report.weightedExpectedCrr, greaterThan(0.004));
      expect(report.punctureProtectionRating, inInclusiveRange(10.0, 99.0));
      expect(report.hydrationAutonomyHours, greaterThan(1.5));
    });
  });

  group('GravelRollingResistanceAndSealantSolver — Fizyka i Impedancja Szutru', () {
    test('optymalne ciśnienie spada wraz z trudnością nawierzchni, szerokością opony i obecnością wkładki', () {
      final race40 = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final mud50 =
          GravelBikeAndTireInsertsModel.technicalMudAndSingletrackPreset();

      final cat1NoInsert = solver.calculateOptimalGravelPressure(
        bikeSetup: race40.copyWith(tireInserts: const FoamTireInsertSpec.none()),
        surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
      );
      final cat1WithInsert = solver.calculateOptimalGravelPressure(
        bikeSetup: race40,
        surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
      );
      final cat4Pressure = solver.calculateOptimalGravelPressure(
        bikeSetup: race40,
        surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
      );
      final wideCat4Pressure = solver.calculateOptimalGravelPressure(
        bikeSetup: mud50,
        surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
      );
      final wetCat4Pressure = solver.calculateOptimalGravelPressure(
        bikeSetup: race40,
        surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
        rainIntensity: 1.0,
      );

      expect(cat1WithInsert.frontBar, lessThan(cat1NoInsert.frontBar));
      expect(cat4Pressure.rearBar, lessThan(cat1WithInsert.rearBar));
      expect(wideCat4Pressure.frontBar, lessThan(cat4Pressure.frontBar));
      expect(wetCat4Pressure.frontBar, lessThan(cat4Pressure.frontBar));
    });

    test('przepompowanie opony na tarce (Cat 3) generuje wyraźne straty impedancyjne i wibracje', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final optimal = solver.calculateOptimalGravelPressure(
        bikeSetup: setup,
        surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
      );

      final atOptimal = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          speedMetersPerSecond: 9.5,
          overrideFrontPressureBar: optimal.frontBar,
          overrideRearPressureBar: optimal.rearBar,
        ),
      );

      final overInflated = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          speedMetersPerSecond: 9.5,
          overrideFrontPressureBar: optimal.frontBar + 1.2,
          overrideRearPressureBar: optimal.rearBar + 1.2,
        ),
      );

      expect(overInflated.impedanceLossCrr, greaterThan(atOptimal.impedanceLossCrr));
      expect(overInflated.impedancePenaltyWatts,
          greaterThan(atOptimal.impedancePenaltyWatts + 3.0));
      expect(overInflated.effectiveCrr, greaterThan(atOptimal.effectiveCrr));
      expect(overInflated.vibrationFatigueIndex,
          greaterThan(atOptimal.vibrationFatigueIndex));
    });

    test('szersza opona (50 mm vs 40 mm) redukuje zapadanie (sinkage) w głębokim luźnym żwirze', () {
      final narrowSetup =
          GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset().copyWith(
        tireInserts: const FoamTireInsertSpec.none(),
      );
      final wideSetup =
          GravelBikeAndTireInsertsModel.technicalMudAndSingletrackPreset()
              .copyWith(
        tireInserts: const FoamTireInsertSpec.none(),
      );

      final narrowResult = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: narrowSetup,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          speedMetersPerSecond: 8.0,
          looseGravelDepthCm: 4.5,
          overrideFrontPressureBar: 2.1,
          overrideRearPressureBar: 2.2,
        ),
      );

      final wideResult = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: wideSetup,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          speedMetersPerSecond: 8.0,
          looseGravelDepthCm: 4.5,
          overrideFrontPressureBar: 2.1,
          overrideRearPressureBar: 2.2,
        ),
      );

      expect(wideResult.looseGravelSinkageCrr,
          lessThan(narrowResult.looseGravelSinkageCrr));
      expect(wideResult.sinkagePenaltyWatts,
          lessThan(narrowResult.sinkagePenaltyWatts));
    });

    test('wkładka piankowa FoamTireInsertSpec drastycznie obniża ryzyko dobicia obręczy (pinch-flat)', () {
      final base = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      final withoutInsert = base.copyWith(
        tireInserts: const FoamTireInsertSpec.none(),
      );

      final resWithInsert = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: base,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          speedMetersPerSecond: 8.5,
          overrideFrontPressureBar: 1.55,
          overrideRearPressureBar: 1.60,
        ),
      );

      final resWithoutInsert = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: withoutInsert,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          speedMetersPerSecond: 8.5,
          overrideFrontPressureBar: 1.55,
          overrideRearPressureBar: 1.60,
        ),
      );

      expect(resWithInsert.pinchFlatRiskPerHour,
          lessThan(resWithoutInsert.pinchFlatRiskPerHour * 0.25));
      expect(resWithInsert.optimalRearPressureBar,
          lessThan(resWithoutInsert.optimalRearPressureBar));
    });

    test('nagromadzenie błota zwiększa masę systemu i opory toczenia', () {
      final clean =
          GravelBikeAndTireInsertsModel.technicalMudAndSingletrackPreset();
      final muddy = clean.copyWith(mudAccumulationKg: 2.5);

      final resClean = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: clean,
          surfaceCategory: GravelSurfaceCategory.cat5TechnicalSingletrackAndMud,
          speedMetersPerSecond: 6.5,
          rainIntensity: 0.8,
        ),
      );
      final resMuddy = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: muddy,
          surfaceCategory: GravelSurfaceCategory.cat5TechnicalSingletrackAndMud,
          speedMetersPerSecond: 6.5,
          rainIntensity: 0.8,
        ),
      );

      expect(resMuddy.totalSystemMassKg,
          closeTo(resClean.totalSystemMassKg + 2.5, 0.01));
      expect(resMuddy.looseGravelSinkageCrr,
          greaterThan(resClean.looseGravelSinkageCrr));
      expect(resMuddy.totalRollingPowerWatts,
          greaterThan(resClean.totalRollingPowerWatts));
    });
  });

  group('TubelessSealantSpec & Rozstrzyganie Przebić', () {
    test('małe przebicie (3.0 mm) jest automatycznie uszczelniane w ruchu przez mleczko', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final initialFrontMl = setup.tubelessSealant.remainingVolumeMlFront;

      final outcome = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
          punctureSizeMm: 3.0,
          isFrontWheel: true,
          currentTirePressureBar: 2.35,
          deterministicRoll01: 0.20,
        ),
      );

      expect(outcome.resolved, isTrue);
      expect(outcome.selfSealedWithoutStopping, isTrue);
      expect(outcome.strategy, GravelSealantRepairStrategy.selfSealedInMotion);
      expect(outcome.timeLostSeconds, equals(0.0));
      expect(outcome.sealantConsumedMl, greaterThan(0.0));
      expect(outcome.pressureAfterEventBar, lessThan(2.35));
      expect(outcome.updatedBikeSetup.tubelessSealant.remainingVolumeMlFront,
          closeTo(initialFrontMl - outcome.sealantConsumedMl, 0.01));
      expect(outcome.diagnosticCode, 'SEALED_IN_MOTION');
    });

    test('duże przebicie bieżnika (8.0 mm) wymaga zatrzymania, knota i naboju CO2', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();

      final outcome = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          punctureSizeMm: 8.0,
          isFrontWheel: false,
          currentTirePressureBar: 2.40,
          deterministicRoll01: 0.10,
          availableCo2Cartridges: 2,
          availableTubelessPlugs: 4,
        ),
      );

      expect(outcome.resolved, isTrue);
      expect(outcome.selfSealedWithoutStopping, isFalse);
      expect(outcome.strategy, GravelSealantRepairStrategy.tubelessPlugAndCo2);
      expect(outcome.timeLostSeconds, equals(42.0));
      expect(outcome.co2CartridgesUsed, equals(1));
      expect(outcome.plugsUsed, equals(1));
      expect(outcome.diagnosticCode, 'PLUGGED_AND_CO2_INFLATED');
    });

    test('rozcięcie ścianki bocznej z wkładką Foam Insert uruchamia tryb Run-Flat', () {
      final setup = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();

      final outcome = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          punctureSizeMm: 7.5,
          isFrontWheel: false,
          isSidewallCut: true,
          currentTirePressureBar: 2.10,
          deterministicRoll01: 0.50,
        ),
      );

      expect(outcome.resolved, isTrue);
      expect(outcome.strategy, GravelSealantRepairStrategy.runFlatOnFoamInsert);
      expect(outcome.runFlatActive, isTrue);
      expect(outcome.timeLostSeconds, equals(0.0));
      expect(outcome.pressureAfterEventBar, closeTo(0.25, 0.001));
      expect(outcome.postEventRollingPenaltyWatts, greaterThan(20.0));
      expect(outcome.diagnosticCode, 'RUN_FLAT_ON_FOAM_INSERT');
    });

    test('rozcięcie ścianki bocznej bez wkładki eskaluje do zapasowej dętki lub DNF', () {
      final noInsertSetup =
          GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset().copyWith(
        tireInserts: const FoamTireInsertSpec.none(),
        tubelessSealant: const TubelessSealantSpec.none(),
      );

      final withTube = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: noInsertSetup,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          punctureSizeMm: 6.0,
          isFrontWheel: true,
          isSidewallCut: true,
          currentTirePressureBar: 2.40,
          deterministicRoll01: 0.10,
          hasSpareInnerTube: true,
          availableCo2Cartridges: 1,
        ),
      );

      expect(withTube.resolved, isTrue);
      expect(withTube.strategy, GravelSealantRepairStrategy.spareTubeInstall);
      expect(withTube.spareTubeUsed, isTrue);
      expect(withTube.co2CartridgesUsed, equals(1));
      expect(withTube.timeLostSeconds, equals(155.0));

      final noTubeDnf = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: noInsertSetup,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          punctureSizeMm: 6.0,
          isFrontWheel: true,
          isSidewallCut: true,
          currentTirePressureBar: 2.40,
          deterministicRoll01: 0.10,
          hasSpareInnerTube: false,
        ),
      );

      expect(noTubeDnf.resolved, isFalse);
      expect(noTubeDnf.strategy, GravelSealantRepairStrategy.dnfMechanical);
      expect(noTubeDnf.diagnosticCode, 'DNF_UNREPAIRABLE_PUNCTURE');
    });

    test('odparowanie mleczka w upale 35°C jest wolniejsze dla formuły Ultra-Endurance niż Race', () {
      const raceSealant =
          TubelessSealantSpec.raceMicrofiber(volumeMlPerTire: 100.0);
      const ultraSealant =
          TubelessSealantSpec.ultraEndurance(volumeMlPerTire: 100.0);

      final raceAfterHeat = raceSealant.applyHeatEvaporation(
        durationHours: 6.0,
        ambientTempC: 35.0,
      );
      final ultraAfterHeat = ultraSealant.applyHeatEvaporation(
        durationHours: 6.0,
        ambientTempC: 35.0,
      );

      expect(raceAfterHeat.remainingVolumeMlFront, lessThan(100.0));
      expect(ultraAfterHeat.remainingVolumeMlFront,
          greaterThan(raceAfterHeat.remainingVolumeMlFront));
    });

    test('wyczerpane mleczko nie może samodzielnie uszczelnić przebicia', () {
      const lowSealant = TubelessSealantSpec(
        id: 'sealant_low',
        name: 'Resztka mleczka',
        formula: TubelessSealantFormula.latexAmmoniaFree,
        initialVolumeMlPerTire: 80.0,
        remainingVolumeMlFront: 4.0,
        remainingVolumeMlRear: 4.0,
        maxSealablePunctureMm: 5.5,
        sealingSuccessBaseProbability: 0.85,
        pressureLossPerSealBar: 0.25,
        evaporationRateMlPerHourAt30C: 2.0,
        priceEur: 20,
      );

      expect(
        lowSealant.canAttemptSelfSeal(punctureSizeMm: 2.0, isFrontWheel: true),
        isFalse,
      );
      final outcome = lowSealant.consumeSealantForPuncture(
        punctureSizeMm: 2.0,
        isFrontWheel: true,
        deterministicRoll01: 0.05,
      );
      expect(outcome.sealedSuccessfully, isFalse);
      expect(outcome.reasonCode, 'SEALANT_DEPLETED');
    });
  });

  group('Symulacja Etapu Szutrowego i Reguły Self-Supported', () {
    test('simulateStagePhysics agreguje dystans, opory, odparowanie mleczka i czas defektów', () {
      final setup = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      const segments = [
        GravelCourseSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 40.0,
          surfaceCategory: GravelSurfaceCategory.cat2CompactedForestRoad,
        ),
        GravelCourseSegment(
          index: 1,
          startKm: 40.0,
          lengthKm: 60.0,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          gradientPercent: 2.5,
        ),
      ];

      final summary = solver.simulateStagePhysics(
        bikeSetup: setup,
        segments: segments,
        ambientTempC: 32.0,
      );

      expect(summary.totalDistanceKm, closeTo(100.0, 0.01));
      expect(summary.averageEffectiveCrr, greaterThan(0.005));
      expect(summary.averageRollingWatts, greaterThan(20.0));
      expect(summary.totalImpedancePenaltyKilojoules, greaterThan(0.0));
      expect(summary.expectedPuncturesCount, greaterThan(0.0));
      expect(summary.sealantRemainingFrontMl,
          lessThan(setup.tubelessSealant.remainingVolumeMlFront));
    });

    test('simulateStagePhysics obsługuje pustą listę segmentów bezpiecznie', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final summary = solver.simulateStagePhysics(
        bikeSetup: setup,
        segments: const [],
      );

      expect(summary.totalDistanceKm, equals(0.0));
      expect(summary.averageRollingWatts, equals(0.0));
      expect(summary.recommendedFrontPressureBar, inInclusiveRange(1.25, 3.80));
    });

    test('SelfSupportedRulesConfig i GravelRepairKitState weryfikują zestaw i naprawy w terenie', () {
      final ultraRules = SelfSupportedRulesConfig.ultraGravelStrict();
      const incompleteKit = GravelRepairKitState(
        co2CartridgesRemaining: 2,
        hasMiniPumpBackup: false,
      );
      const completeKit = GravelRepairKitState(
        co2CartridgesRemaining: 3,
        tubelessPlugsRemaining: 5,
        spareInnerTubesRemaining: 1,
        hasMiniPumpBackup: true,
      );

      expect(ultraRules.isRepairKitCompliant(incompleteKit), isFalse);
      expect(ultraRules.isRepairKitCompliant(completeKit), isTrue);

      final noCo2Kit = completeKit.copyWith(co2CartridgesRemaining: 0);
      final pumpFallback = noCo2Kit.attemptFieldRepair(
        issueType: GravelMechanicalIssueType.largeTreadGash,
      );
      expect(pumpFallback.raceContinuing, isTrue);
      expect(pumpFallback.outcomeStatus,
          GravelRepairOutcomeStatus.repairedWithHandPumpFallback);
      expect(pumpFallback.co2CartridgesUsed, equals(0));
      expect(pumpFallback.tubelessPlugsUsed, equals(2));

      final brokenChainNoLink =
          completeKit.copyWith(hasQuickLinkAndChainTool: false);
      final chainDnf = brokenChainNoLink.attemptFieldRepair(
        issueType: GravelMechanicalIssueType.chainSnap,
      );
      expect(chainDnf.raceContinuing, isFalse);
      expect(chainDnf.outcomeStatus, GravelRepairOutcomeStatus.dnfOutOfSpares);
    });
  });
}
