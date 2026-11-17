import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/womens_worldtour_and_mixed_relay_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/services/generators/womens_worldtour_teams_and_riders_seeder.dart';

void main() {
  group('WomensWorldtourTeamsAndRidersSeeder', () {
    test('generates 24 teams (15 WWT, 6 Pro, 3 Conti) and 360 roster riders', () {
      final result = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 20260375,
        freeAgentsCount: 30,
      );

      expect(result.teams.length, 24);
      expect(result.worldTourTeams.length, 15);
      expect(result.proTeams.length, 6);
      expect(result.continentalTeams.length, 3);

      expect(result.seededRiders.length, 360);
      expect(result.allRiders.length, 360);
      expect(result.physiologyByRiderId.length, 360);

      for (final team in result.teams) {
        expect(team.rosterSize, 15);
        expect(team.isRosterCompliant, isTrue);
        expect(result.getTeamRoster(team.teamId).length, 15);
      }

      final uniqueIds = result.allRiders.map((r) => r.id).toSet();
      final uniqueNames = result.allRiders.map((r) => r.fullName).toSet();
      expect(uniqueIds.length, 360);
      expect(uniqueNames.length, 360);
    });

    test('calibrates women physiology realistically across specializations', () {
      final result = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        seed: 12345,
      );

      final climbers = result.seededRiders
          .where((r) => r.rider.specialization == RiderSpecialization.pureClimber)
          .toList();
      final sprinters = result.seededRiders
          .where((r) => r.rider.specialization == RiderSpecialization.pureSprinter)
          .toList();

      expect(climbers, isNotEmpty);
      expect(sprinters, isNotEmpty);

      final avgClimberWeight =
          climbers.map((r) => r.womensPhysiology.weightKg).reduce((a, b) => a + b) /
              climbers.length;
      final avgSprinterWeight =
          sprinters.map((r) => r.womensPhysiology.weightKg).reduce((a, b) => a + b) /
              sprinters.length;

      final avgClimber5s =
          climbers.map((r) => r.womensPhysiology.watts5s).reduce((a, b) => a + b) /
              climbers.length;
      final avgSprinter5s =
          sprinters.map((r) => r.womensPhysiology.watts5s).reduce((a, b) => a + b) /
              sprinters.length;

      expect(avgClimberWeight, lessThan(avgSprinterWeight));
      expect(avgSprinter5s, greaterThan(avgClimber5s));

      for (final seeded in result.seededRiders) {
        expect(seeded.rider.appearance.facialHairIndex, 0);
        expect(seeded.rider.physiology.labProfile, isNotNull);
        expect(seeded.womensPhysiology.weightKg, inInclusiveRange(45.0, 72.0));
        expect(seeded.womensPhysiology.ftpWatts, inInclusiveRange(190.0, 400.0));
        expect(seeded.womensPhysiology.aerodynamicsCda, inInclusiveRange(0.18, 0.25));
        expect(seeded.womensOverallRating, inInclusiveRange(40, 99));
      }
    });

    test('builds transfer market with free agents and contracted listings', () {
      final result = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
        seasonYear: 2026,
        freeAgentsCount: 28,
      );

      expect(result.freeAgentListings.length, 28);
      expect(result.contractedTransferListings, isNotEmpty);

      for (final fa in result.freeAgentListings) {
        expect(fa.isFreeAgent, isTrue);
        expect(fa.buyoutFeeEur, 0);
        expect(fa.annualSalaryDemandEur, greaterThan(0));
      }

      for (int i = 1; i < result.transferMarket.length; i++) {
        expect(
          result.transferMarket[i - 1].overallRating,
          greaterThanOrEqualTo(result.transferMarket[i].overallRating),
        );
      }
    });

    test('produces serializable WomensWorldTourSeasonState and deterministic output', () {
      final a = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(seed: 99);
      final b = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(seed: 99);

      expect(a.allRiders.first.fullName, b.allRiders.first.fullName);
      expect(a.teams.length, b.teams.length);
      expect(a.calendarEvents.length, greaterThanOrEqualTo(7));

      final json = a.seasonState.toJson();
      final restored = WomensWorldTourSeasonState.fromJson(json);
      expect(restored.teams.length, 24);
      expect(restored.transferMarket.length, a.transferMarket.length);
      expect(restored.calendarEvents.length, a.calendarEvents.length);
    });
  });
}
