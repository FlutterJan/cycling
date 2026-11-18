import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/paracycling/uci_paracycling_tandem_handbike_model.dart';

void main() {
  group('ParacyclingSportClass & Equipment', () {
    test('covers Tandem B, Handbike H1-H5 and Bicycle C1-C5 correctly', () {
      expect(ParacyclingSportClass.values.length, 11);
      expect(ParacyclingSportClass.b.division, ParacyclingDivision.tandemB);
      expect(ParacyclingSportClass.b.requiresPilot, isTrue);
      expect(ParacyclingSportClass.b.wheelCount, 2);

      for (final h in [
        ParacyclingSportClass.h1,
        ParacyclingSportClass.h2,
        ParacyclingSportClass.h3,
        ParacyclingSportClass.h4,
        ParacyclingSportClass.h5,
      ]) {
        expect(h.division, ParacyclingDivision.handbike);
        expect(h.requiresPilot, isFalse);
        expect(h.wheelCount, 3);
        expect(h.relayClassificationPoints, inInclusiveRange(1, 5));
      }

      for (final c in [
        ParacyclingSportClass.c1,
        ParacyclingSportClass.c2,
        ParacyclingSportClass.c3,
        ParacyclingSportClass.c4,
        ParacyclingSportClass.c5,
      ]) {
        expect(c.division, ParacyclingDivision.bicycleC);
        expect(c.requiresPilot, isFalse);
        expect(c.wheelCount, 2);
      }
    });

    test('default fleet enforces class compatibility', () {
      final fleet = ParacyclingBikeSpec.defaultFleet();
      final tandem = fleet.firstWhere(
        (b) => b.equipmentType == ParacyclingEquipmentType.tandemRoadBike,
      );
      final recumbent = fleet.firstWhere(
        (b) => b.equipmentType == ParacyclingEquipmentType.recumbentHandbike,
      );
      final kneeling = fleet.firstWhere(
        (b) => b.equipmentType == ParacyclingEquipmentType.kneelingHandbike,
      );
      final soloRoad = fleet.firstWhere(
        (b) => b.equipmentType == ParacyclingEquipmentType.soloParaRoadBike,
      );

      expect(tandem.isCompatibleWithClass(ParacyclingSportClass.b), isTrue);
      expect(tandem.isCompatibleWithClass(ParacyclingSportClass.h3), isFalse);

      expect(recumbent.isCompatibleWithClass(ParacyclingSportClass.h3), isTrue);
      expect(recumbent.isCompatibleWithClass(ParacyclingSportClass.h5), isFalse);

      expect(kneeling.isCompatibleWithClass(ParacyclingSportClass.h5), isTrue);
      expect(kneeling.isCompatibleWithClass(ParacyclingSportClass.h4), isFalse);

      expect(soloRoad.isCompatibleWithClass(ParacyclingSportClass.c4), isTrue);
      expect(soloRoad.isCompatibleWithClass(ParacyclingSportClass.b), isFalse);
    });
  });

  group('TandemCrewPairing & HandbikeTeamRelayEntry', () {
    test('default tandem crew outputs >800W and >95 km/h descent capability', () {
      final season = UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason();
      final crew = season.tandemCrews.first;

      expect(crew.isUciValid, isTrue);
      expect(crew.combinedFtpWatts, greaterThan(800.0));
      expect(crew.combinedPeak5sWatts, greaterThan(2200.0));
      expect(crew.projectedMaxDescentKmh, greaterThan(95.0));
      expect(crew.totalSystemWeightKg, greaterThan(150.0));
      expect(crew.effectiveWPerKg, greaterThan(5.0));
    });

    test('handbike team relay validates 3 riders and <= 11 points', () {
      final season = UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason();
      final relay = season.relayEntries.first;

      // H2 (2) + H3 (3) + H5 (5) = 10 <= 11
      expect(relay.totalClassificationPoints, 10);
      expect(relay.isRulesCompliant, isTrue);
      expect(relay.combinedRelayFtpWatts, greaterThan(600.0));

      final invalidRelay = relay.copyWith(maxClassificationPoints: 9);
      expect(invalidRelay.isRulesCompliant, isFalse);
    });
  });

  group('UciParacyclingTandemHandbikeModel Season & Serialization', () {
    test('records results, computes standings and readiness reports', () {
      final initial = UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason();
      final updated = initial
          .recordResult(
            const ParacyclingRaceResult(
              eventId: 'wc_ostend_itt',
              competitorId: 'crew_pol_b_1',
              displayName: 'Kacper Kowalski / Michał Nowak',
              sportClass: ParacyclingSportClass.b,
              finishTimeSeconds: 1842.5,
              rank: 1,
              uciPointsEarned: 100,
              averagePowerWatts: 855.0,
              maxSpeedKmh: 62.4,
              medalEarned: ParacyclingMedalType.gold,
            ),
          )
          .recordResult(
            const ParacyclingRaceResult(
              eventId: 'wc_maniago_rr',
              competitorId: 'crew_pol_b_1',
              displayName: 'Kacper Kowalski / Michał Nowak',
              sportClass: ParacyclingSportClass.b,
              finishTimeSeconds: 7420.0,
              rank: 2,
              uciPointsEarned: 88,
              averagePowerWatts: 760.0,
              maxSpeedKmh: 98.6,
              medalEarned: ParacyclingMedalType.silver,
            ),
          );

      final standings = updated.computeWorldCupStandings(
        filterClass: ParacyclingSportClass.b,
      );
      expect(standings.length, 1);
      expect(standings.first.totalPoints, 188);
      expect(standings.first.podiumsCount, 2);

      final tandemReadiness =
          updated.evaluateClassReadiness(ParacyclingSportClass.b);
      expect(tandemReadiness.isReadyForCompetition, isTrue);
      expect(tandemReadiness.averageFtpWatts, greaterThan(800.0));

      final h1Readiness =
          updated.evaluateClassReadiness(ParacyclingSportClass.h1);
      expect(h1Readiness.isReadyForCompetition, isFalse);
    });

    test('round-trips JSON cleanly', () {
      final season = UciParacyclingTandemHandbikeModel.createDefaultWorldCupSeason()
          .recordResult(
        const ParacyclingRaceResult(
          eventId: 'paralympics_road_final',
          competitorId: 'para_h3_1',
          displayName: 'Rafał Wilk',
          sportClass: ParacyclingSportClass.h3,
          finishTimeSeconds: 5120.3,
          rank: 1,
          uciPointsEarned: 400,
          averagePowerWatts: 232.0,
          maxSpeedKmh: 58.1,
          medalEarned: ParacyclingMedalType.gold,
        ),
      );

      final json = season.toJson();
      final decoded = UciParacyclingTandemHandbikeModel.fromJson(json);

      expect(decoded.seasonYear, season.seasonYear);
      expect(decoded.teamName, season.teamName);
      expect(decoded.athletes.length, season.athletes.length);
      expect(decoded.tandemCrews.length, season.tandemCrews.length);
      expect(decoded.bikes.length, season.bikes.length);
      expect(decoded.events.length, season.events.length);
      expect(decoded.relayEntries.length, season.relayEntries.length);
      expect(decoded.results.length, 1);
      expect(decoded.results.first.medalEarned, ParacyclingMedalType.gold);
      expect(
        decoded.tandemCrews.first.combinedFtpWatts,
        closeTo(season.tandemCrews.first.combinedFtpWatts, 0.001),
      );
    });
  });
}
