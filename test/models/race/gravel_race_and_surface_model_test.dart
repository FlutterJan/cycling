import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/gravel_race_and_surface_model.dart';

void main() {
  group('GravelSurfaceCategory', () {
    test('has 5 categories with strictly increasing CRR multipliers', () {
      expect(GravelSurfaceCategory.values.length, 5);
      for (var i = 0; i < GravelSurfaceCategory.values.length; i++) {
        final cat = GravelSurfaceCategory.values[i];
        expect(cat.categoryNumber, i + 1);
        expect(cat.crrMultiplier, greaterThan(1.0));
        expect(cat.recommendedMinTireWidthMm, greaterThanOrEqualTo(35.0));
        expect(
          GravelSurfaceCategory.fromJson(cat.toJson()),
          equals(cat),
        );
      }
      expect(
        GravelSurfaceCategory.cat1ChampagneGravel.crrMultiplier,
        lessThan(GravelSurfaceCategory.cat4SharpFlintAndChunkyRock.crrMultiplier),
      );
      expect(
        GravelSurfaceCategory.cat4SharpFlintAndChunkyRock.crrMultiplier,
        lessThan(
            GravelSurfaceCategory.cat5TechnicalSingletrackAndMud.crrMultiplier),
      );
    });
  });

  group('SelfSupportedRulesConfig & GravelRepairKitState (CO2 repairs)', () {
    test('validates compliance against UCI and Ultra-Gravel rules', () {
      final uciRules = SelfSupportedRulesConfig.uciGravelStandard();
      final ultraRules = SelfSupportedRulesConfig.ultraGravelStrict();

      const basicKit = GravelRepairKitState(
        co2CartridgesRemaining: 2,
        co2CartridgeGrams: 16,
        tubelessPlugsRemaining: 4,
        spareInnerTubesRemaining: 1,
        hasMiniPumpBackup: false,
      );
      expect(uciRules.isStrictlySelfSupported, isFalse);
      expect(uciRules.allowFeedZoneSupportOnly, isTrue);
      expect(uciRules.isRepairKitCompliant(basicKit), isTrue);

      expect(ultraRules.isStrictlySelfSupported, isTrue);
      expect(ultraRules.allowOutsideTechnicalAssistance, isFalse);
      expect(ultraRules.isRepairKitCompliant(basicKit), isFalse);

      const ultraKit = GravelRepairKitState(
        co2CartridgesRemaining: 3,
        co2CartridgeGrams: 25,
        tubelessPlugsRemaining: 6,
        spareInnerTubesRemaining: 2,
        hasMiniPumpBackup: true,
      );
      expect(ultraRules.isRepairKitCompliant(ultraKit), isTrue);
    });

    test('simulates CO2 + plug repair, fallback to hand pump, and DNF', () {
      const initialKit = GravelRepairKitState(
        co2CartridgesRemaining: 1,
        co2CartridgeGrams: 25,
        tubelessPlugsRemaining: 3,
        spareInnerTubesRemaining: 1,
        hasMiniPumpBackup: true,
        sealantMlRemaining: 80.0,
      );

      // 1. Small puncture sealed by fluid without using CO2
      final res1 = initialKit.attemptFieldRepair(
        issueType: GravelMechanicalIssueType.smallTubelessPuncture,
      );
      expect(res1.outcomeStatus, GravelRepairOutcomeStatus.sealedByFluidOnly);
      expect(res1.co2CartridgesUsed, 0);
      expect(res1.updatedKit.co2CartridgesRemaining, 1);

      // 2. Large tread gash uses 2 plugs + 1 CO2 cartridge
      final res2 = res1.updatedKit.attemptFieldRepair(
        issueType: GravelMechanicalIssueType.largeTreadGash,
      );
      expect(
        res2.outcomeStatus,
        GravelRepairOutcomeStatus.repairedWithCo2AndPlug,
      );
      expect(res2.co2CartridgesUsed, 1);
      expect(res2.tubelessPlugsUsed, 2);
      expect(res2.updatedKit.co2CartridgesRemaining, 0);
      expect(res2.raceContinuing, isTrue);

      // 3. Sidewall tear with 0 CO2 left falls back to hand pump (slower)
      final res3 = res2.updatedKit.attemptFieldRepair(
        issueType: GravelMechanicalIssueType.sidewallTear,
      );
      expect(
        res3.outcomeStatus,
        GravelRepairOutcomeStatus.repairedWithHandPumpFallback,
      );
      expect(res3.innerTubesUsed, 1);
      expect(res3.timeLostSeconds, greaterThan(150.0));
      expect(res3.updatedKit.spareInnerTubesRemaining, 0);

      // 4. Another sidewall tear with 0 tubes left -> DNF
      final res4 = res3.updatedKit.attemptFieldRepair(
        issueType: GravelMechanicalIssueType.sidewallTear,
      );
      expect(res4.outcomeStatus, GravelRepairOutcomeStatus.dnfOutOfSpares);
      expect(res4.raceContinuing, isFalse);
    });
  });

  group('GravelRaceAndSurfaceModel', () {
    test('computes surface breakdown, checkpoints, and tire evaluation', () {
      final unbound = GravelRaceAndSurfaceModel.unboundGravel200();
      expect(unbound.tier, GravelRaceDisciplineTier.ultraGravelSelfSupported);
      expect(unbound.totalDistanceKm, 322.0);
      expect(unbound.checkpointCount, 2);

      final breakdown = unbound.surfaceBreakdownKm;
      expect(
        breakdown[GravelSurfaceCategory.cat4SharpFlintAndChunkyRock],
        165.0,
      );
      expect(unbound.weightedSurfaceDifficulty, greaterThan(3.0));

      final segAt100 = unbound.segmentAtKm(100.0);
      expect(segAt100, isNotNull);
      expect(
        segAt100!.surfaceCategory,
        GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
      );

      final nextCp = unbound.nextCheckpointAfterKm(10.0);
      expect(nextCp, isNotNull);
      expect(nextCp!.checkpointName, contains('Eureka'));

      final underTired = unbound.evaluateTireSetup(
        tireWidthMm: 35.0,
        tirePressureBar: 3.1,
      );
      expect(underTired.isUnderTired, isTrue);
      expect(underTired.punctureRiskMultiplier, greaterThan(2.0));
    });

    test('round-trips cleanly through JSON', () {
      final traka = GravelRaceAndSurfaceModel.theTraka360();
      final json = traka.toJson();
      final decoded = GravelRaceAndSurfaceModel.fromJson(json);

      expect(decoded, equals(traka));
      expect(decoded.segments.length, traka.segments.length);
      expect(decoded.selfSupportedRules, equals(traka.selfSupportedRules));
      expect(decoded.defaultRepairKit, equals(traka.defaultRepairKit));
    });
  });
}
