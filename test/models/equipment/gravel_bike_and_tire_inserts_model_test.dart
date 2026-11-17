import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/gravel_bike_and_tire_inserts_model.dart';
import 'package:pro_peloton_manager/models/race/gravel_race_and_surface_model.dart';

void main() {
  group('GravelBikeAndTireInsertsModel', () {
    test('presets have valid configurations and expected 38–50 mm tire widths', () {
      final uci = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final flint = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      final mud =
          GravelBikeAndTireInsertsModel.technicalMudAndSingletrackPreset();

      expect(uci.hasValidConfiguration, isTrue);
      expect(uci.frontTire.widthMm, 40.0);
      expect(uci.hydrationPack.tier, AeroHydrationPackTier.minimalistAeroVest1500Ml);
      expect(uci.effectiveCdaModifier, lessThan(0.0));

      expect(flint.hasValidConfiguration, isTrue);
      expect(flint.frontTire.widthMm, 45.0);
      expect(flint.tireInserts.isInstalled, isTrue);
      expect(flint.tireInserts.runFlatSpeedRetention, greaterThan(0.6));

      expect(mud.hasValidConfiguration, isTrue);
      expect(mud.frontTire.widthMm, 50.0);
      expect(mud.totalHydrationCapacityMl, 5250.0);
    });

    test('detects invalid tire clearance and incompatible insert width', () {
      final base = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final oversized = base.copyWith(
        frontTire: base.frontTire.copyWith(widthMm: 50.0),
      );

      expect(oversized.isTireClearanceValid, isFalse);
      expect(oversized.isInsertWidthCompatible, isFalse);
      expect(oversized.hasValidConfiguration, isFalse);
      expect(oversized.configurationWarnings.length, greaterThanOrEqualTo(2));
    });

    test('rejects tires narrower than 38 mm as outside gravel range', () {
      final base = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final tooNarrow = base.copyWith(
        rearTire: base.rearTire.copyWith(widthMm: 32.0),
      );

      expect(tooNarrow.rearTire.isWithinGravelRange, isFalse);
      expect(tooNarrow.isTireClearanceValid, isFalse);
      expect(tooNarrow.hasValidConfiguration, isFalse);
    });

    test('TubelessSealantSpec seals small punctures and depletes on heat', () {
      const sealant = TubelessSealantSpec.raceMicrofiber(volumeMlPerTire: 80.0);
      expect(
        sealant.canAttemptSelfSeal(punctureSizeMm: 4.0, isFrontWheel: true),
        isTrue,
      );

      final outcome = sealant.consumeSealantForPuncture(
        punctureSizeMm: 4.0,
        isFrontWheel: true,
        deterministicRoll01: 0.2,
      );
      expect(outcome.sealedSuccessfully, isTrue);
      expect(outcome.sealantConsumedMl, greaterThan(0.0));
      expect(outcome.pressureLostBar, greaterThan(0.0));
      expect(
        outcome.updatedSealantState.remainingVolumeMlFront,
        lessThan(80.0),
      );
      expect(outcome.updatedSealantState.remainingVolumeMlRear, 80.0);

      final tooBig = sealant.consumeSealantForPuncture(
        punctureSizeMm: 8.5,
        isFrontWheel: false,
        deterministicRoll01: 0.0,
      );
      expect(tooBig.sealedSuccessfully, isFalse);
      expect(tooBig.reasonCode, 'PUNCTURE_TOO_LARGE');

      final evaporated = sealant.applyHeatEvaporation(
        durationHours: 6.0,
        ambientTempC: 36.0,
      );
      expect(evaporated.remainingVolumeMlFront, lessThan(80.0));
    });

    test('AeroHydrationPackSpec tracks weight, drinking, and refilling', () {
      const pack = AeroHydrationPackSpec.aeroVest1500Ml();
      expect(pack.isEquipped, isTrue);
      expect(pack.hydrationFraction, 1.0);
      expect(pack.currentTotalWeightKg, closeTo(1.745, 0.001));

      final afterDrink = pack.drink(500.0);
      expect(afterDrink.currentFluidMl, 1000.0);
      expect(afterDrink.hydrationFraction, closeTo(2 / 3, 0.001));

      final refilled = afterDrink.refillToCapacity();
      expect(refilled.currentFluidMl, 1500.0);
    });

    test('consumeFluid drains hydration pack before frame bottles', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final after1000 = setup.consumeFluid(1000.0);
      expect(after1000.hydrationPack.currentFluidMl, 500.0);
      expect(after1000.currentFrameBottlesFluidMl, 1500.0);

      final afterAnother1000 = after1000.consumeFluid(1000.0);
      expect(afterAnother1000.hydrationPack.currentFluidMl, 0.0);
      expect(afterAnother1000.currentFrameBottlesFluidMl, 1000.0);
    });

    test('CRR and puncture risk scale across gravel surface categories', () {
      final setup = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      final crrCat1 = setup.effectiveCrrForSurface(
        GravelSurfaceCategory.cat1ChampagneGravel,
      );
      final crrCat4 = setup.effectiveCrrForSurface(
        GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
      );
      expect(crrCat4, greaterThan(crrCat1));

      final riskCat1 = setup.effectivePunctureRiskFactor(
        GravelSurfaceCategory.cat1ChampagneGravel,
      );
      final riskCat4 = setup.effectivePunctureRiskFactor(
        GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
      );
      expect(riskCat4, greaterThan(riskCat1));
    });

    test('evaluateForRace produces readiness report with warnings when under-tired', () {
      final uciSetup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final roughRace = GravelRaceAndSurfaceModel(
        id: 'race_unbound_200',
        name: 'Unbound Gravel 200',
        countryCode: 'US',
        region: 'Kansas Flint Hills',
        tier: GravelRaceDisciplineTier.ultraGravelSelfSupported,
        totalDistanceKm: 320.0,
        totalElevationGainM: 3400.0,
        recommendedTireWidthMm: 45.0,
        ambientTemperatureC: 31.0,
        segments: const [
          GravelCourseSegment(
            index: 0,
            startKm: 0.0,
            lengthKm: 160.0,
            surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
            gradientPercent: 1.5,
            isFeedOrCheckpointZone: true,
          ),
          GravelCourseSegment(
            index: 1,
            startKm: 160.0,
            lengthKm: 160.0,
            surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
            gradientPercent: 1.2,
          ),
        ],
        selfSupportedRules: SelfSupportedRulesConfig.ultraGravelStrict(),
      );

      final uciReport = uciSetup.evaluateForRace(roughRace);
      expect(uciReport.warnings, isNotEmpty);
      expect(uciReport.isClearanceValid, isTrue);

      final flintSetup = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      final flintReport = flintSetup.evaluateForRace(roughRace);
      expect(flintReport.suitabilityScore, greaterThan(uciReport.suitabilityScore));
      expect(flintReport.warnings, isEmpty);
    });

    test('JSON round-trip preserves all fields accurately', () {
      final original = GravelBikeAndTireInsertsModel.flintHillsUltraPreset()
          .consumeFluid(400.0)
          .copyWith(mudAccumulationKg: 0.45);
      final json = original.toJson();
      final restored = GravelBikeAndTireInsertsModel.fromJson(json);

      expect(restored, equals(original));
      expect(restored.mudAccumulationKg, 0.45);
      expect(restored.hydrationPack.currentFluidMl, 1600.0);
      expect(restored.totalSystemWeightKg, closeTo(original.totalSystemWeightKg, 0.0001));
    });
  });
}
