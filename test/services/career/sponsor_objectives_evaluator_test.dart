// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/sponsor_objectives_evaluator.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';

void main() {
  group('SponsorObjectivesEvaluator Tests', () {
    const evaluator = SponsorObjectivesEvaluator();

    CyclingTeam createTestTeam({
      int cashBalanceEur = 1000000,
      double titleSatisfaction = 65.0,
      double secondarySatisfaction = 60.0,
      List<SponsorObjective>? titleObjectives,
      List<SponsorObjective>? secondaryObjectives,
    }) {
      return CyclingTeam(
        id: 'team-player',
        name: 'Orlen Pro Cycling',
        division: TeamDivision.worldTour,
        countryIso: 'POL',
        primaryJerseyColorHex: '#DC2626',
        secondaryJerseyColorHex: '#FFFFFF',
        accentJerseyColorHex: '#111827',
        cashBalanceEur: cashBalanceEur,
        monthlyBurnRateEur: 250000,
        uciPointsSeason: 2400,
        rosterRiderIds: const ['r1', 'r2', 'r3'],
        staff: const TeamStaff(
          trainersLevel: 80,
          sportsDirectorsLevel: 82,
          doctorsLevel: 78,
          mechanicsLevel: 81,
          scoutsLevel: 75,
        ),
        bikeDeal: const BikeManufacturerDeal(
          manufacturerId: 'bike-1',
          manufacturerName: 'Specialized',
          prestigeLevel: 90,
          annualCashContributionEur: 500000,
          freeBikesQuota: 40,
          researchAndDevelopmentLevel: 88,
          suppliedFrameIds: ['f1'],
          suppliedWheelsetIds: ['w1'],
          contractYearsLeft: 2,
          minimumUciRankingRequired: 18,
        ),
        sponsors: [
          SponsorContract(
            id: 'sp-title',
            companyName: 'ORLEN Group',
            industry: SponsorIndustry.energy,
            sponsorTier: SponsorTier.titlePrimary,
            annualBudgetEur: 12000000,
            contractDurationYears: 3,
            sponsorSatisfaction: titleSatisfaction,
            objectives: titleObjectives ??
                const [
                  SponsorObjective(
                    id: 'obj-monument-podium',
                    description: 'Podium w Monumencie Kolarskim (Top 3)',
                    bonusPaymentEur: 250000,
                    importance: ObjectiveImportance.high,
                    isCompleted: false,
                    currentProgress: 0.0,
                    targetProgress: 1.0,
                  ),
                ],
          ),
          if (secondaryObjectives != null)
            SponsorContract(
              id: 'sp-sec',
              companyName: 'CCC',
              industry: SponsorIndustry.apparel,
              sponsorTier: SponsorTier.titleSecondary,
              annualBudgetEur: 4000000,
              contractDurationYears: 2,
              sponsorSatisfaction: secondarySatisfaction,
              objectives: secondaryObjectives,
            ),
        ],
        inventoryBikes: const [],
      );
    }

    test('classifyObjective correctly identifies all standard objective types', () {
      const obj1 = SponsorObjective(
        id: '1',
        description: 'Podium w Monumencie Kolarskim',
        bonusPaymentEur: 250000,
        importance: ObjectiveImportance.high,
        isCompleted: false,
        currentProgress: 0,
        targetProgress: 1,
      );
      const obj2 = SponsorObjective(
        id: '2',
        description: 'Minimum 1200 km w Ucieczkach (Ekspozycja TV)',
        bonusPaymentEur: 250000,
        importance: ObjectiveImportance.medium,
        isCompleted: false,
        currentProgress: 0,
        targetProgress: 1200,
      );
      const obj3 = SponsorObjective(
        id: '3',
        description: 'Zwycięstwo w Klasyfikacji Generalnej Grand Touru',
        bonusPaymentEur: 1200000,
        importance: ObjectiveImportance.critical,
        isCompleted: false,
        currentProgress: 0,
        targetProgress: 1,
      );
      const obj4 = SponsorObjective(
        id: '4',
        description: 'Miejsce w Top 5 Drużynowego Rankingu UCI',
        bonusPaymentEur: 500000,
        importance: ObjectiveImportance.high,
        isCompleted: false,
        currentProgress: 0,
        targetProgress: 1,
      );

      expect(evaluator.classifyObjective(obj1), EvaluatedObjectiveType.podiumMonument);
      expect(evaluator.classifyObjective(obj2), EvaluatedObjectiveType.breakawayKmExposure);
      expect(evaluator.classifyObjective(obj3), EvaluatedObjectiveType.winGrandTourGc);
      expect(evaluator.classifyObjective(obj4), EvaluatedObjectiveType.top5UciTeamRanking);
    });

    test('Podium in a Monument completes objective, pays €250,000 bonus, boosts satisfaction and sends congrats email', () {
      final team = createTestTeam(cashBalanceEur: 1000000, titleSatisfaction: 65.0);

      final context = PostRaceSponsorContext(
        raceId: 'paris-roubaix-2026',
        raceName: 'Paris-Roubaix',
        raceCategory: RaceCategory.monument,
        raceDate: DateTime(2026, 4, 12),
        bestPlayerStageRank: 2,
        topFinishingRiderName: 'Michał Kwiatkowski',
      );

      final result = evaluator.evaluatePostRace(team: team, context: context);

      expect(result.totalBonusesPaidEur, 250000);
      expect(result.updatedCashBalanceEur, 1250000);
      expect(result.newlyCompletedObjectives.length, 1);
      expect(result.newlyCompletedObjectives.first.bonusPaidEur, 250000);

      final updatedTitle = result.updatedSponsors.first;
      expect(updatedTitle.objectives.first.isCompleted, isTrue);
      expect(updatedTitle.objectives.first.currentProgress, 1.0);
      expect(updatedTitle.sponsorSatisfaction, 77.0); // 65.0 + 12.0 (high importance)
      expect(result.boardSatisfactionDelta, 12.0);

      // Sprawdź mail z gratulacjami
      expect(result.generatedEmails.length, 1);
      final email = result.generatedEmails.first;
      expect(email.category, InboxCategory.sponsorNews);
      expect(email.priority, InboxPriority.urgent);
      expect(email.senderName, contains('ORLEN Group'));
      expect(email.subject, contains('€250,000'));
      expect(email.body, contains('Michał Kwiatkowski'));
      expect(email.body, contains('Paris-Roubaix'));

      // Aplikacja na model drużyny
      final updatedTeam = evaluator.applyEvaluationToTeam(team: team, result: result);
      expect(updatedTeam.cashBalanceEur, 1250000);
      expect(updatedTeam.sponsors.first.objectives.first.isCompleted, isTrue);
    });

    test('Incremental objectives accumulate progress across stages without premature payout', () {
      final team = createTestTeam(
        cashBalanceEur: 500000,
        titleSatisfaction: 60.0,
        titleObjectives: const [
          SponsorObjective(
            id: 'obj-breakaway',
            description: 'Minimum 500 km w ucieczkach (Ekspozycja TV)',
            bonusPaymentEur: 150000,
            importance: ObjectiveImportance.medium,
            isCompleted: false,
            currentProgress: 0.0,
            targetProgress: 500.0,
          ),
          SponsorObjective(
            id: 'obj-stages',
            description: 'Pakiet Zwycięstw Etapowych w WorldTourze',
            bonusPaymentEur: 300000,
            importance: ObjectiveImportance.high,
            isCompleted: false,
            currentProgress: 0.0,
            targetProgress: 2.0,
          ),
        ],
      );

      // Etap 1: 180 km w ucieczce, 1 wygrany etap
      final stage1Context = PostRaceSponsorContext(
        raceId: 'tdf-2026',
        raceName: 'Tour de France',
        raceCategory: RaceCategory.grandTour,
        raceDate: DateTime(2026, 7, 4),
        isFinalStage: false,
        stageNumber: 1,
        bestPlayerStageRank: 1,
        wonStagesCount: 1,
        teamBreakawayKm: 180.0,
      );

      final res1 = evaluator.evaluatePostRace(team: team, context: stage1Context);
      expect(res1.totalBonusesPaidEur, 0); // Żaden cel jeszcze nie ukończony (180/500 oraz 1/2)
      expect(res1.updatedCashBalanceEur, 500000);
      expect(res1.updatedSponsors.first.objectives[0].currentProgress, 180.0);
      expect(res1.updatedSponsors.first.objectives[1].currentProgress, 1.0);
      expect(res1.updatedSponsors.first.sponsorSatisfaction, greaterThan(60.0)); // Wzrost za postęp i wygrany etap

      // Etap 2: kolejne 350 km w ucieczce i 1 wygrany etap -> oba cele ukończone!
      final teamAfterStage1 = evaluator.applyEvaluationToTeam(team: team, result: res1);
      final stage2Context = PostRaceSponsorContext(
        raceId: 'tdf-2026',
        raceName: 'Tour de France',
        raceCategory: RaceCategory.grandTour,
        raceDate: DateTime(2026, 7, 5),
        isFinalStage: false,
        stageNumber: 2,
        bestPlayerStageRank: 1,
        wonStagesCount: 1,
        teamBreakawayKm: 350.0,
      );

      final res2 = evaluator.evaluatePostRace(team: teamAfterStage1, context: stage2Context);
      expect(res2.totalBonusesPaidEur, 450000); // 150k + 300k
      expect(res2.updatedCashBalanceEur, 950000);
      expect(res2.newlyCompletedObjectives.length, 2);
      expect(res2.updatedSponsors.first.objectives[0].currentProgress, 500.0); // Clamped do targetProgress
      expect(res2.updatedSponsors.first.objectives[0].isCompleted, isTrue);
      expect(res2.updatedSponsors.first.objectives[1].isCompleted, isTrue);

      // Etap 3: Ponowne wygranie etapu nie wypłaca ponownie bonusu za ukończone cele
      final teamAfterStage2 = evaluator.applyEvaluationToTeam(team: teamAfterStage1, result: res2);
      final res3 = evaluator.evaluatePostRace(team: teamAfterStage2, context: stage2Context);
      expect(res3.totalBonusesPaidEur, 0);
      expect(res3.newlyCompletedObjectives, isEmpty);
    });

    test('Disappointing result in Monument drops satisfaction and triggers title sponsor warning email', () {
      final team = createTestTeam(
        titleSatisfaction: 46.0, // Tuż nad progiem ostrzegawczym 45%
        titleObjectives: const [
          SponsorObjective(
            id: 'obj-win-monument',
            description: 'Zwycięstwo w Monumencie Kolarskim',
            bonusPaymentEur: 500000,
            importance: ObjectiveImportance.critical,
            isCompleted: false,
            currentProgress: 0.0,
            targetProgress: 1.0,
          ),
        ],
      );

      // Słaby wynik: 38. miejsce w Ronde van Vlaanderen
      final flopContext = PostRaceSponsorContext(
        raceId: 'rvv-2026',
        raceName: 'Ronde van Vlaanderen',
        raceCategory: RaceCategory.monument,
        raceDate: DateTime(2026, 4, 5),
        bestPlayerStageRank: 38,
      );

      final result = evaluator.evaluatePostRace(team: team, context: flopContext);

      expect(result.totalBonusesPaidEur, 0);
      expect(result.updatedSponsors.first.sponsorSatisfaction, lessThan(45.0));
      expect(result.boardSatisfactionDelta, lessThan(0.0));

      // Powinien przyjść pilny mail ostrzegawczy od sponsora tytularnego
      expect(result.generatedEmails.length, 1);
      final warningEmail = result.generatedEmails.first;
      expect(warningEmail.priority, InboxPriority.urgent);
      expect(warningEmail.category, InboxCategory.sponsorNews);
      expect(warningEmail.subject, contains('Ostrzeżenie'));
      expect(warningEmail.body, contains('Ronde van Vlaanderen'));
    });

    test('calculateBoardSatisfaction weights titlePrimary higher than secondary sponsors', () {
      final team = createTestTeam(
        titleSatisfaction: 80.0,
        secondarySatisfaction: 40.0,
        secondaryObjectives: const [],
      );

      // Wagi: titlePrimary = 0.60, titleSecondary = 0.20 -> (80*0.6 + 40*0.2) / 0.8 = 56 / 0.8 = 70.0
      final boardSat = evaluator.calculateBoardSatisfaction(team.sponsors);
      expect(boardSat, closeTo(70.0, 0.01));
    });
  });
}
