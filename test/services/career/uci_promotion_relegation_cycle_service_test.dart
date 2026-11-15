// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/uci_promotion_relegation_cycle_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  group('UciPromotionRelegationCycleService Tests', () {
    Rider createTestRider({
      required String id,
      required String firstName,
      required String lastName,
      required String nationalityIso,
    }) {
      final base = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        targetOverallRating: 85,
      );
      return base.copyWith(
        id: id,
        firstName: firstName,
        lastName: lastName,
        nationalityIso: nationalityIso,
      );
    }

    test('UciTriennialCycleState creates default 3-year cycle and tracks year indices', () {
      final cycle = UciPromotionRelegationCycleService.createDefaultCycleState(currentYear: 2026);

      expect(cycle.startYear, 2026);
      expect(cycle.endYear, 2028);
      expect(cycle.cycleYearIndex, 1);
      expect(cycle.isDecisionYear, isFalse);

      final cycleYear2 = UciTriennialCycleState(
        cycleId: 'cycle_2026_2028',
        startYear: 2026,
        endYear: 2028,
        currentYear: 2027,
      );
      expect(cycleYear2.cycleYearIndex, 2);
      expect(cycleYear2.isDecisionYear, isFalse);

      final cycleDecisionYear = UciTriennialCycleState(
        cycleId: 'cycle_2026_2028',
        startYear: 2026,
        endYear: 2028,
        currentYear: 2028,
      );
      expect(cycleDecisionYear.cycleYearIndex, 3);
      expect(cycleDecisionYear.isDecisionYear, isTrue);
    });

    test('calculateTeamTop20Points strictly enforces the UCI Rule of 20', () {
      final service = UciPromotionRelegationCycleService();

      // Utwórz 25 kolarzy z punktami malejąco: od 1000 pkt do 20 pkt
      final Map<String, int> scores = {};
      final List<Rider> testRoster = [];

      for (int i = 1; i <= 25; i++) {
        final id = 'rider-$i';
        scores[id] = 1000 - (i * 30); // 970, 940, 910 ...
        testRoster.add(createTestRider(
          id: id,
          firstName: 'Rider',
          lastName: '#$i',
          nationalityIso: 'FRA',
        ));
      }

      final breakdown = service.calculateTeamTop20Points(
        teamId: 'team-cofidis',
        teamName: 'Cofidis',
        year: 2026,
        riderSeasonPoints: scores,
        roster: testRoster,
      );

      expect(breakdown.contributingRiders.length, 25);

      // Sprawdź czy kolarze 1-20 mają isCountedInTop20 == true, a 21-25 mają false
      for (int i = 0; i < 20; i++) {
        expect(breakdown.contributingRiders[i].isCountedInTop20, isTrue);
      }
      for (int i = 20; i < 25; i++) {
        expect(breakdown.contributingRiders[i].isCountedInTop20, isFalse);
      }

      // Weryfikacja sumy top 20
      final expectedTop20Sum = breakdown.contributingRiders
          .take(20)
          .map((r) => r.seasonPoints)
          .reduce((a, b) => a + b);

      expect(breakdown.countedTop20Points, expectedTop20Sum);
      expect(breakdown.grossAllRidersPoints, greaterThan(breakdown.countedTop20Points));
      expect(breakdown.wastedPoints, breakdown.grossAllRidersPoints - breakdown.countedTop20Points);

      // Kolarz 20. i 21. oraz dystans do wejścia do top 20
      final r20Pts = breakdown.contributingRiders[19].seasonPoints;
      final r21Pts = breakdown.contributingRiders[20].seasonPoints;
      expect(breakdown.cutoffRiderPoints, r20Pts);
      expect(breakdown.nextChallengerPoints, r21Pts);
      expect(breakdown.pointsToBreakIntoTop20, (r20Pts - r21Pts) + 1);
    });

    test('calculateTeamTop20Points handles smaller teams with fewer than 20 riders', () {
      final service = UciPromotionRelegationCycleService();
      final Map<String, int> scores = {
        'r-1': 500,
        'r-2': 300,
        'r-3': 150,
      };

      final breakdown = service.calculateTeamTop20Points(
        teamId: 'team-small',
        teamName: 'Small ProTeam',
        year: 2026,
        riderSeasonPoints: scores,
      );

      expect(breakdown.contributingRiders.length, 3);
      expect(breakdown.countedTop20Points, 950);
      expect(breakdown.grossAllRidersPoints, 950);
      expect(breakdown.wastedPoints, 0);
      expect(breakdown.cutoffRiderPoints, 0);
      expect(breakdown.pointsToBreakIntoTop20, 0);
    });

    test('recordSeasonPointsForTeam saves points for respective cycle years', () {
      final service = UciPromotionRelegationCycleService();

      const breakdownY1 = TeamTop20Breakdown(
        teamId: 'team-arkea',
        teamName: 'Arkéa-B&B Hotels',
        year: 2026,
        countedTop20Points: 4500,
        grossAllRidersPoints: 4700,
        wastedPoints: 200,
        contributingRiders: [],
        cutoffRiderPoints: 80,
        nextChallengerPoints: 75,
        pointsToBreakIntoTop20: 6,
      );

      const breakdownY2 = TeamTop20Breakdown(
        teamId: 'team-arkea',
        teamName: 'Arkéa-B&B Hotels',
        year: 2027,
        countedTop20Points: 5200,
        grossAllRidersPoints: 5400,
        wastedPoints: 200,
        contributingRiders: [],
        cutoffRiderPoints: 90,
        nextChallengerPoints: 85,
        pointsToBreakIntoTop20: 6,
      );

      service.recordSeasonPointsForTeam(
        teamId: 'team-arkea',
        teamName: 'Arkéa-B&B Hotels',
        countryIso: 'FRA',
        division: TeamDivision.worldTour,
        year: 2026,
        breakdown: breakdownY1,
      );

      service.recordSeasonPointsForTeam(
        teamId: 'team-arkea',
        teamName: 'Arkéa-B&B Hotels',
        countryIso: 'FRA',
        division: TeamDivision.worldTour,
        year: 2027,
        breakdown: breakdownY2,
      );

      final record = service.state.teamRecords['team-arkea'];
      expect(record, isNotNull);
      expect(record!.year1Points, 4500);
      expect(record.year2Points, 5200);
      expect(record.year3Points, 0);
      expect(record.totalCyclePoints, 9700);
      expect(record.yearlyBreakdowns.length, 2);
    });

    test('generateRelegationBattleTable ranks teams and determines accurate survival cutoffs', () {
      final service = UciPromotionRelegationCycleService();

      // Utwórz 22 zespoły symulujące peleton WorldTour i ProTeam
      for (int i = 1; i <= 22; i++) {
        final teamId = 'team-$i';
        final division = i <= 18 ? TeamDivision.worldTour : TeamDivision.proTeam;
        final totalPts = 25000 - (i * 800); // Team 1: 24200, Team 18: 10600, Team 19: 9800...

        service.state.teamRecords[teamId] = TeamTriennialRecord(
          teamId: teamId,
          teamName: 'Cycling Team #$i',
          countryIso: 'BEL',
          division: division,
          year1Points: (totalPts * 0.33).round(),
          year2Points: (totalPts * 0.33).round(),
          year3Points: totalPts - (2 * (totalPts * 0.33).round()),
        );
      }

      final table = service.generateRelegationBattleTable(
        currentYear: 2026,
        playerTeamId: 'team-18',
      );

      expect(table.length, 22);

      // Team 1: Bezpieczny WorldTour z dużym buforem
      final leader = table[0];
      expect(leader.rank, 1);
      expect(leader.relegationStatus, RelegationStatus.safeWorldTour);
      expect(leader.bufferOrDeficitTo18th, greaterThan(0));

      // Team 18: Na krawędzi (danger zone)
      final team18 = table[17];
      expect(team18.rank, 18);
      expect(team18.relegationStatus, RelegationStatus.relegationThreatened);
      expect(team18.bufferOrDeficitTo18th, 0); // Jest dokładnie na progu 18. miejsca
      expect(team18.isPlayerTeam, isTrue);

      // Team 19: W strefie spadkowej (ujemny bilans)
      final team19 = table[18];
      expect(team19.rank, 19);
      expect(team19.bufferOrDeficitTo18th, lessThan(0));
    });

    test('getRelegationRiskAnalysis detects high urgency when team is below 18th place', () {
      final service = UciPromotionRelegationCycleService();

      for (int i = 1; i <= 20; i++) {
        final teamId = 'team-$i';
        final totalPts = 20000 - (i * 600);
        service.state.teamRecords[teamId] = TeamTriennialRecord(
          teamId: teamId,
          teamName: 'Team $i',
          countryIso: 'FRA',
          division: TeamDivision.worldTour,
          year1Points: totalPts,
        );
      }

      // Analiza dla zespołu na 20. miejscu
      final analysis = service.getRelegationRiskAnalysis(
        teamId: 'team-20',
        currentYear: 2026,
      );

      expect(analysis.currentRank, 20);
      expect(analysis.gapToSafety, lessThan(0));
      expect(analysis.tacticalUrgency, TacticalUrgency.maximumSurviveOrDie);
      expect(analysis.summaryHeadline, contains('ALARM! Strefa Spadku'));
      expect(analysis.tacticalAdvice, contains('1.Pro i 1.1'));
      expect(analysis.remainingTargetPointsNeeded, greaterThan(0));
    });

    test('getPointHuntingRecommendations filters high-value 1.Pro and 1.1 races', () {
      final service = UciPromotionRelegationCycleService();

      final allSpringRaces = service.getPointHuntingRecommendations(currentMonth: 3);
      expect(allSpringRaces.isNotEmpty, isTrue);

      // Sprawdź obecność klasyka 1.Pro z 200 pkt za zwycięstwo
      final kbk = allSpringRaces.firstWhere((r) => r.raceId == 'race_kbk_pro');
      expect(kbk.category, RaceCategory.proSeries);
      expect(kbk.categoryCode, '1.Pro');
      expect(kbk.winnerUciPoints, 200);
      expect(kbk.tacticalReason, contains('200 pkt za zwycięstwo'));

      // Filtrowanie po typie terenu
      final cobbleRaces = service.getPointHuntingRecommendations(currentMonth: 3, terrainFocus: 'szutry');
      expect(cobbleRaces.any((r) => r.raceId == 'race_tro_bro_leon'), isTrue);
    });

    test('evaluateTriennialCycleDecisions executes promotions and relegations after Year 3', () {
      final service = UciPromotionRelegationCycleService();

      // Stwórz 20 ekip:
      // Ekipy 1-17: WorldTour
      // Ekipa 18: PROTEAM (awansuje!)
      // Ekipa 19: WORLDTOUR (spada!)
      // Ekipa 20: PROTEAM
      for (int i = 1; i <= 20; i++) {
        final teamId = 'team-$i';
        TeamDivision division;
        if (i == 18) {
          division = TeamDivision.proTeam; // Sensacyjny ProTeam w top 18
        } else if (i == 19) {
          division = TeamDivision.worldTour; // WorldTour na 19. miejscu (spadek)
        } else if (i <= 17) {
          division = TeamDivision.worldTour;
        } else {
          division = TeamDivision.proTeam;
        }

        final pts = 20000 - (i * 700);
        service.state.teamRecords[teamId] = TeamTriennialRecord(
          teamId: teamId,
          teamName: 'Team $i',
          countryIso: 'FRA',
          division: division,
          year1Points: (pts * 0.33).round(),
          year2Points: (pts * 0.33).round(),
          year3Points: pts - (2 * (pts * 0.33).round()),
        );
      }

      final outcome = service.evaluateTriennialCycleDecisions(
        finalYear: 2028,
        playerTeamId: 'team-18',
      );

      expect(outcome.awardedWorldTourTeamIds.length, 18);
      // Team 18 awansował z ProTeam do WorldTour
      expect(outcome.promotedToWorldTourTeamIds, contains('team-18'));
      // Team 19 spadł z WorldTour do ProTeam
      expect(outcome.relegatedToProTeamTeamIds, contains('team-19'));
      // Gracz (Team 18) osiągnął sukces (awans)
      expect(outcome.didPlayerTeamSurviveOrPromote, isTrue);
      // Sprawdź dzikie karty dla ProTeamów
      expect(outcome.mandatoryGrandTourWildcardTeamIds.isNotEmpty, isTrue);
      expect(outcome.officialUciAnnouncement, contains('OFICJALNY KOMUNIKAT'));
    });

    test('Serialization roundtrip of models and cycle state', () {
      final state = UciTriennialCycleState(
        cycleId: 'cycle_2026_2028',
        startYear: 2026,
        endYear: 2028,
        currentYear: 2026,
        teamRecords: {
          'team-1': const TeamTriennialRecord(
            teamId: 'team-1',
            teamName: 'Team One',
            countryIso: 'BEL',
            division: TeamDivision.worldTour,
            year1Points: 5000,
            year2Points: 0,
            year3Points: 0,
          ),
        },
      );

      final json = state.toJson();
      final revived = UciTriennialCycleState.fromJson(json);

      expect(revived.cycleId, 'cycle_2026_2028');
      expect(revived.startYear, 2026);
      expect(revived.endYear, 2028);
      expect(revived.teamRecords.containsKey('team-1'), isTrue);
      expect(revived.teamRecords['team-1']!.totalCyclePoints, 5000);
    });
  });
}
