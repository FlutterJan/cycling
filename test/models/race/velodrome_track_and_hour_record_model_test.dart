import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';

void main() {
  group('VelodromeTrackAndHourRecordModel', () {
    test('standard model loads Grenchen, Aguascalientes and 56.792 km record', () {
      final model = VelodromeTrackAndHourRecordModel.standard();

      expect(model.activeVelodrome.id, 'grenchen_tissot');
      expect(model.activeVelodrome.trackLengthMeters, 250.0);
      expect(model.activeVelodrome.altitudeMeters, 450.0);
      expect(model.activeVelodrome.isStandard250mHourRecordTrack, isTrue);

      final aguascalientes = model.availableVelodromes.firstWhere(
        (v) => v.id == 'aguascalientes_bicentenario',
      );
      expect(aguascalientes.altitudeMeters, 1880.0);
      expect(aguascalientes.turnBankingDegrees, 45.0);
      expect(aguascalientes.isStandard250mHourRecordTrack, isTrue);

      // Wyżej położony welodrom ma istotnie niższą gęstość powietrza niż Grenchen.
      expect(
        aguascalientes.airDensityKgPerM3,
        lessThan(model.activeVelodrome.airDensityKgPerM3),
      );
      expect(
        aguascalientes.hypoxiaPowerPenaltyFactor,
        lessThan(model.activeVelodrome.hypoxiaPowerPenaltyFactor),
      );

      final menRecord = model.currentRecordForCategory(
        UciHourRecordCategory.menElite,
      );
      expect(menRecord.riderName, 'Filippo Ganna');
      expect(menRecord.distanceKm, 56.792);
      expect(menRecord.lapsOn250mTrack, closeTo(227.168, 0.001));
      expect(menRecord.gearingLabel, '64x14');

      final womenRecord = model.currentRecordForCategory(
        UciHourRecordCategory.womenElite,
      );
      expect(womenRecord.riderName, 'Vittoria Bussi');
      expect(womenRecord.distanceKm, 50.455);
    });

    test('FixedGearTrackBike enforces fixed-gear no-brakes 58-64T x 13-15T', () {
      const bike = VelodromeTrackAndHourRecordModel.defaultTrackBike;

      expect(bike.isFixedGear, isTrue);
      expect(bike.hasBrakes, isFalse);
      expect(bike.hasFreewheel, isFalse);
      expect(bike.isUciTrackLegal, isTrue);
      expect(bike.chainringTeeth, 64);
      expect(bike.cogTeeth, 14);

      // Sprawdzenie spójności przeliczania prędkość <-> kadencja na ostrym kole.
      final double speedAt100Rpm = bike.speedKmhFromCadence(100.0);
      expect(speedAt100Rpm, closeTo(57.49, 0.05));
      expect(bike.cadenceRpmFromSpeedKmh(speedAt100Rpm), closeTo(100.0, 0.01));

      // copyWith bezpiecznie przycina zębatki do dozwolonego zakresu torowego.
      final clampedBike = bike.copyWith(
        chainringTeeth: 70,
        cogTeeth: 11,
        bikeWeightKg: 5.5,
      );
      expect(clampedBike.chainringTeeth, FixedGearTrackBike.maxChainringTeeth);
      expect(clampedBike.cogTeeth, FixedGearTrackBike.minCogTeeth);
      expect(clampedBike.bikeWeightKg, FixedGearTrackBike.uciMinWeightKg);
      expect(clampedBike.isUciTrackLegal, isTrue);
    });

    test('simulateHourRecordAttempt computes realistic speed and record delta', () {
      final model = VelodromeTrackAndHourRecordModel.standard();

      final simElite = model.simulateHourRecordAttempt(
        sustainableHourPowerWatts: 465.0,
        riderMassKg: 76.0,
      );

      expect(simElite.predictedDistanceKm, greaterThan(53.0));
      expect(simElite.predictedDistanceKm, lessThan(60.0));
      expect(simElite.predictedLaps, closeTo(simElite.predictedDistanceKm * 4.0, 0.01));
      expect(simElite.requiredCadenceRpm, greaterThan(90.0));
      expect(simElite.currentRecordDistanceKm, 56.792);

      // Zbyt niska moc nie pobije aktualnego rekordu 56.792 km.
      final simAmateur = model.simulateHourRecordAttempt(
        sustainableHourPowerWatts: 280.0,
        riderMassKg: 74.0,
      );
      expect(simAmateur.beatsCurrentRecord, isFalse);
      expect(simAmateur.deltaToRecordMeters, lessThan(0.0));
    });

    test('JSON serialization round-trip preserves full model equality', () {
      final original = VelodromeTrackAndHourRecordModel.standard(
        initialVelodromeId: 'aguascalientes_bicentenario',
        customBike: const FixedGearTrackBike(
          modelName: 'Custom Track Prototype',
          chainringTeeth: 60,
          cogTeeth: 13,
          bikeWeightKg: 6.9,
          cdaMetersSquared: 0.172,
        ),
      );

      final Map<String, dynamic> json = original.toJson();
      final VelodromeTrackAndHourRecordModel restored =
          VelodromeTrackAndHourRecordModel.fromJson(json);

      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
      expect(restored.activeVelodrome.id, 'aguascalientes_bicentenario');
      expect(restored.trackBike.gearingLabel, '60x13');
    });
  });
}
