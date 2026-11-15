import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/uci_points_live_ledger_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  Rider buildRider(String id, {int careerPoints = 0}) {
    final rider = RiderProceduralGenerator.generateRider(
      id: id,
      targetOverallRating: 80,
      random: math.Random(id.hashCode),
    );
    return rider.copyWith(careerPointsUci: careerPoints);
  }

  CyclingTeam buildTeam(
    String id,
    String name,
    List<String> riderIds, {
    TeamDivision division = TeamDivision.worldTour,
  }) {
    return CyclingTeam(
      id: id,
      name: name,
      division: division,
      countryIso: 'POL',
      primaryJerseyColorHex: '#8E4A49',
      secondaryJerseyColorHex: '#181B22',
      accentJerseyColorHex: '#D4AF37',
      cashBalanceEur: 5000000,
      monthlyBurnRateEur: 250000,
      uciPointsSeason: 0,
      rosterRiderIds: riderIds,
      staff: const TeamStaff(
        trainersLevel: 80,
        sportsDirectorsLevel: 80,
        doctorsLevel: 80,
        mechanicsLevel: 80,
        scoutsLevel: 80,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'brand_test',
        manufacturerName: 'VeloTest',
        prestigeLevel: 5,
        annualCashContributionEur: 500000,
        freeBikesQuota: 40,
        suppliedFrameIds: ['frame_1'],
        suppliedWheelsetIds: ['wheel_1'],
        researchAndDevelopmentLevel: 80,
        contractYearsLeft: 2,
        minimumUciRankingRequired: 18,
      ),
      sponsors: const [],
      inventoryBikes: const [],
    );
  }

  TourRace buildRace(String id, String name, RaceCategory category) {
    return TourRace(
      id: id,
      name: name,
      countryIso: 'FRA',
      uciCategory: category,
      startMonth: 4,
      startDay: 10,
      stages: const [],
      prizePoolEur: 250000,
      participatingTeamIds: const ['team_a', 'team_b'],
      ridersPerTeam: 7,
      classifications: const RaceClassifications(
        generalClassification: [],
        pointsClassification: [],
        mountainsClassification: [],
        youthClassification: [],
        teamClassification: [],
      ),
    );
  }

  group('UciPointsLiveLedgerService - Points Scales 1..60', () {
    test('One-day race points cover ranks 1 to 60 and return 0 outside 1..60', () {
      expect(UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.monument, 1), 800);
      expect(UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.monument, 10), 135);
      expect(UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.monument, 30), 30);
      expect(UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.monument, 60), 5);
      expect(UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.monument, 61), 0);
      expect(UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.monument, 0), 0);

      for (int rank = 1; rank <= 60; rank++) {
        expect(
          UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.worldTourOneDay, rank),
          greaterThan(0),
        );
        expect(
          UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.proSeries, rank),
          greaterThan(0),
        );
        expect(
          UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.class1, rank),
          greaterThan(0),
        );
      }
    });

    test('Stage, GC, and leader jersey day scales match UCI categories', () {
      expect(UciPointsLiveLedgerService.stagePointsForRank(RaceCategory.grandTour, 1), 210);
      expect(UciPointsLiveLedgerService.stagePointsForRank(RaceCategory.grandTour, 15), 5);
      expect(UciPointsLiveLedgerService.stagePointsForRank(RaceCategory.grandTour, 16), 0);

      expect(UciPointsLiveLedgerService.gcPointsForRank(RaceCategory.grandTour, 1), 1000);
      expect(UciPointsLiveLedgerService.gcPointsForRank(RaceCategory.grandTour, 60), 5);
      expect(UciPointsLiveLedgerService.gcPointsForRank(RaceCategory.worldTourStageRace, 1), 500);
      expect(UciPointsLiveLedgerService.gcPointsForRank(RaceCategory.worldTourStageRace, 60), 5);

      expect(UciPointsLiveLedgerService.leaderJerseyDayPoints(RaceCategory.grandTour), 25);
      expect(UciPointsLiveLedgerService.leaderJerseyDayPoints(RaceCategory.worldTourStageRace), 10);
      expect(UciPointsLiveLedgerService.leaderJerseyDayPoints(RaceCategory.monument), 0);
    });
  });

  group('UciPointsLiveLedgerService - Live Ledger & Rankings', () {
    test('One-day race 1-60 updates individual ranking and 3-year license table immediately', () {
      final ledger = UciPointsLiveLedgerService(
        state: UciPointsLedgerState(seasonYear: 2026),
      );

      final riders = List.generate(
        65,
        (i) => buildRider('r_${i + 1}', careerPoints: 100),
      );
      final teamAIds = riders.take(25).map((r) => r.id).toList();
      final teamBIds = riders.skip(25).map((r) => r.id).toList();
      final teams = [
        buildTeam('team_a', 'Team Alpha', teamAIds),
        buildTeam('team_b', 'Team Beta', teamBIds, division: TeamDivision.proTeam),
      ];

      final results = List.generate(65, (i) {
        final rank = i + 1;
        final rider = riders[i];
        final teamId = i < 25 ? 'team_a' : 'team_b';
        return OfficialRiderStageResult(
          riderId: rider.id,
          riderName: rider.fullName,
          teamId: teamId,
          rank: rank,
          rawFinishTimeSeconds: 18000.0 + rank,
          officialFinishTimeSeconds: 18000.0 + rank,
          gapToWinnerSeconds: rank == 1 ? 0.0 : rank.toDouble(),
          isDnf: rank == 62, // 62nd is DNF
        );
      });

      final monument = buildRace('roubaix_26', 'Paris-Roubaix', RaceCategory.monument);
      final batch = ledger.recordOneDayRaceFinish(
        race: monument,
        results: results,
        riders: riders,
        teams: teams,
        playerTeamId: 'team_a',
      );

      // Only ranks 1..60 earn points (60 entries)
      expect(batch.awardedEntries.length, 60);
      expect(batch.pointsByRider['r_1'], 800);
      expect(batch.pointsByRider['r_60'], 5);
      expect(batch.pointsByRider['r_61'], isNull);

      // Rider careerPointsUci updated immediately
      final updatedR1 = batch.updatedRiders.firstWhere((r) => r.id == 'r_1');
      expect(updatedR1.careerPointsUci, 900);

      // Individual ranking sorted with r_1 at #1
      expect(batch.individualRanking.first.riderId, 'r_1');
      expect(batch.individualRanking.first.seasonPoints, 800);
      expect(batch.individualRanking.first.oneDayPoints, 800);

      // Rule of 20 applied to team_a (25 riders scored, only top 20 count!)
      final top20ExpectedTeamA = List.generate(
        20,
        (i) => UciPointsLiveLedgerService.oneDayPointsForRank(RaceCategory.monument, i + 1),
      ).reduce((a, b) => a + b);

      final updatedTeamA = batch.updatedTeams.firstWhere((t) => t.id == 'team_a');
      expect(updatedTeamA.uciPointsSeason, top20ExpectedTeamA);

      // 3-year license table reflects team_a at #1 with exact top-20 points
      expect(batch.triennialTable.length, 2);
      expect(batch.triennialTable.first.teamId, 'team_a');
      expect(batch.triennialTable.first.totalCyclePoints, top20ExpectedTeamA);
      expect(batch.triennialTable.first.isPlayerTeam, isTrue);
    });

    test('Stage finish, leader jersey days, and final GC accumulate accurately & idempotently', () {
      final ledger = UciPointsLiveLedgerService(
        state: UciPointsLedgerState(seasonYear: 2026),
      );

      final riders = [
        buildRider('r_1'),
        buildRider('r_2'),
      ];
      final teams = [
        buildTeam('team_a', 'Team Alpha', ['r_1']),
        buildTeam('team_b', 'Team Beta', ['r_2']),
      ];
      final gt = buildRace('tdf_26', 'Tour de France', RaceCategory.grandTour);

      // Stage 1: r_1 wins stage (210) + wears leader jersey (25) = 235
      var batch = ledger.recordStageFinish(
        race: gt,
        stageNumber: 1,
        stageResults: [
          OfficialRiderStageResult(
            riderId: 'r_1',
            riderName: riders[0].fullName,
            teamId: 'team_a',
            rank: 1,
            rawFinishTimeSeconds: 14000,
            officialFinishTimeSeconds: 14000,
            gapToWinnerSeconds: 0,
          ),
          OfficialRiderStageResult(
            riderId: 'r_2',
            riderName: riders[1].fullName,
            teamId: 'team_b',
            rank: 2,
            rawFinishTimeSeconds: 14005,
            officialFinishTimeSeconds: 14005,
            gapToWinnerSeconds: 5,
          ),
        ],
        riders: riders,
        teams: teams,
        gcLeaderRiderId: 'r_1',
        gcLeaderTeamId: 'team_a',
      );

      expect(batch.individualRanking.first.seasonPoints, 235);
      expect(batch.individualRanking.first.stagePoints, 210);
      expect(batch.individualRanking.first.jerseyDayPoints, 25);

      // Duplicate call for stage 1 should be idempotent (0 new points)
      final dupBatch = ledger.recordStageFinish(
        race: gt,
        stageNumber: 1,
        stageResults: [
          OfficialRiderStageResult(
            riderId: 'r_1',
            riderName: riders[0].fullName,
            teamId: 'team_a',
            rank: 1,
            rawFinishTimeSeconds: 14000,
            officialFinishTimeSeconds: 14000,
            gapToWinnerSeconds: 0,
          ),
        ],
        riders: batch.updatedRiders,
        teams: batch.updatedTeams,
        gcLeaderRiderId: 'r_1',
        gcLeaderTeamId: 'team_a',
      );
      expect(dupBatch.totalPointsAwarded, 0);

      // Extra leader jersey day on stage 2
      batch = ledger.recordLeaderJerseyDay(
        race: gt,
        stageNumber: 2,
        leaderRiderId: 'r_1',
        leaderRiderName: riders[0].fullName,
        leaderTeamId: 'team_a',
        riders: batch.updatedRiders,
        teams: batch.updatedTeams,
      );

      // Final GC: r_1 1st (1000), r_2 2nd (800)
      batch = ledger.recordGeneralClassificationFinish(
        race: gt,
        generalClassification: [
          RiderClassificationEntry(
            riderId: 'r_1',
            riderName: riders[0].fullName,
            teamId: 'team_a',
            totalTimeSeconds: 280000,
            points: 0,
            rank: 1,
            timeBehindLeaderSeconds: 0,
          ),
          RiderClassificationEntry(
            riderId: 'r_2',
            riderName: riders[1].fullName,
            teamId: 'team_b',
            totalTimeSeconds: 280120,
            points: 0,
            rank: 2,
            timeBehindLeaderSeconds: 120,
          ),
        ],
        riders: batch.updatedRiders,
        teams: batch.updatedTeams,
      );

      // r_1 total: 210 (stage 1) + 25 (jersey s1) + 25 (jersey s2) + 1000 (GC) = 1260
      final r1Rank = batch.individualRanking.firstWhere((e) => e.riderId == 'r_1');
      expect(r1Rank.seasonPoints, 1260);
      expect(r1Rank.gcPoints, 1000);
      expect(r1Rank.jerseyDayPoints, 50);

      // r_2 total: 150 (stage 1) + 800 (GC) = 950
      final r2Rank = batch.individualRanking.firstWhere((e) => e.riderId == 'r_2');
      expect(r2Rank.seasonPoints, 950);

      // JSON roundtrip & season advance
      final json = ledger.state.toJson();
      final restored = UciPointsLiveLedgerService(
        state: UciPointsLedgerState.fromJson(json),
      );
      expect(restored.getEntriesForRace('tdf_26').length, 6);
      expect(restored.getTriennialLicenseRanking().first.totalCyclePoints, 1260);

      final nextSeason = restored.advanceToNextSeason(2027);
      expect(nextSeason.state.seasonYear, 2027);
      expect(nextSeason.state.riderSeasonPoints, isEmpty);
      // 3-year cycle preserves 2026 points in year1Points!
      expect(nextSeason.getTriennialLicenseRanking().first.year1Points, 1260);
    });
  });
}
