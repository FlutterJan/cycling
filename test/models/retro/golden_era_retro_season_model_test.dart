import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/retro/golden_era_retro_season_model.dart';

void main() {
  group('GoldenEraRetroSeasonModel', () {
    test('columbusSl1976Classic has authentic 1976 analog specs', () {
      final season = GoldenEraRetroSeasonModel.columbusSl1976Classic();

      expect(season.seasonYear, 1976);
      expect(season.ruleset.era, GoldenEraDecade.steelCannibalEra1970s);
      expect(season.isPureAnalogEra, isTrue);
      expect(season.ruleset.hasPowerMeter, isFalse);
      expect(season.ruleset.hasRaceRadio, isFalse);

      expect(
        season.teamEquipment.frameMaterial,
        RetroFrameMaterial.columbusSlSteel,
      );
      expect(season.teamEquipment.completeBikeWeightKg, 9.2);
      expect(
        season.teamEquipment.shifterType,
        RetroShifterType.downtubeFriction,
      );
      expect(season.teamEquipment.shifterType.requiresHandOffBar, isTrue);
      expect(
        season.teamEquipment.jerseyMaterial,
        RetroJerseyMaterial.heavyMerinoWool,
      );
      expect(season.teamEquipment.handlebarBottleCage, isTrue);
      expect(season.teamEquipment.hasHardShellHelmet, isFalse);
      expect(season.calendarEvents.length, 4);
    });

    test('GoldenEraDecade.fromYear maps decades and clamps bounds', () {
      expect(GoldenEraDecade.fromYear(1965), GoldenEraDecade.steelCannibalEra1970s);
      expect(GoldenEraDecade.fromYear(1970), GoldenEraDecade.steelCannibalEra1970s);
      expect(GoldenEraDecade.fromYear(1979), GoldenEraDecade.steelCannibalEra1970s);
      expect(GoldenEraDecade.fromYear(1985), GoldenEraDecade.badgerAndAeroDawn1980s);
      expect(GoldenEraDecade.fromYear(1998), GoldenEraDecade.stiAndRadioDawn1990s);
      expect(GoldenEraDecade.fromYear(2000), GoldenEraDecade.carbonAndPowerEra2000s);
      expect(GoldenEraDecade.fromYear(2015), GoldenEraDecade.carbonAndPowerEra2000s);
      expect(GoldenEraDecade.fromYear(2024), GoldenEraDecade.carbonAndPowerEra2000s);
    });

    test('wet merino wool jersey increases system weight and watt penalty', () {
      final season = GoldenEraRetroSeasonModel.columbusSl1976Classic();

      final dryWeight = season.computeTotalWetWeightKg(
        riderWeightKg: 68.0,
        rainIntensity01: 0.0,
        wetnessProgress01: 0.0,
      );
      expect(dryWeight, closeTo(77.2, 1e-6));

      final soakedWeight = season.computeTotalWetWeightKg(
        riderWeightKg: 68.0,
        rainIntensity01: 1.0,
        wetnessProgress01: 1.0,
      );
      expect(soakedWeight, closeTo(78.6, 1e-6));

      final penaltyWatts = season.computeWoolJerseyPenaltyWatts(
        rainIntensity01: 1.0,
        speedMs: 6.0,
        gradientPercent: 8.0,
        wetnessProgress01: 1.0,
      );
      expect(penaltyWatts, greaterThan(6.0));
    });

    test('markEventCompleted updates progress and prestige idempotently', () {
      final season = GoldenEraRetroSeasonModel.columbusSl1976Classic();
      final firstId = season.calendarEvents.first.id;

      final updated = season.markEventCompleted(firstId, prestigeEarned: 250);
      expect(updated.completedEventIds, [firstId]);
      expect(updated.seasonPrestigePoints, 250);
      expect(updated.calendarCompletionProgress, closeTo(0.25, 1e-6));

      final duplicate = updated.markEventCompleted(firstId, prestigeEarned: 250);
      expect(duplicate.seasonPrestigePoints, 250);
      expect(duplicate.completedEventIds.length, 1);
    });

    test('JSON serialization round-trip preserves full model equality', () {
      for (final preset in GoldenEraRetroSeasonModel.presets()) {
        final modified = preset
            .markEventCompleted(preset.calendarEvents.first.id, prestigeEarned: 180)
            .copyWith(activeWetnessFactor: 0.62);

        final json = modified.toJson();
        final restored = GoldenEraRetroSeasonModel.fromJson(json);

        expect(restored, equals(modified));
        expect(restored.hashCode, equals(modified.hashCode));
      }
    });
  });
}
