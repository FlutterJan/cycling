import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/prize_money_distribution_service.dart';

void main() {
  const service = PrizeMoneyDistributionService();

  CyclingTeam buildTeam({
    int cashBalanceEur = 2000000,
    int monthlyBurnRateEur = 300000,
  }) {
    return CyclingTeam(
      id: 'team_1',
      name: 'Velo Horizon',
      division: TeamDivision.worldTour,
      countryIso: 'POL',
      primaryJerseyColorHex: '#8E4A49',
      secondaryJerseyColorHex: '#181B22',
      accentJerseyColorHex: '#D4AF37',
      cashBalanceEur: cashBalanceEur,
      monthlyBurnRateEur: monthlyBurnRateEur,
      uciPointsSeason: 4500,
      rosterRiderIds: const ['r1', 'r2', 'r3'],
      staff: const TeamStaff(
        trainersLevel: 80,
        sportsDirectorsLevel: 85,
        doctorsLevel: 78,
        mechanicsLevel: 82,
        scoutsLevel: 75,
      ),
      bikeDeal: const BikeManufacturerDeal(
        manufacturerId: 'aethon',
        manufacturerName: 'Aethon Bikes',
        prestigeLevel: 4,
        annualCashContributionEur: 500000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 85,
        suppliedFrameIds: ['frame_1'],
        suppliedWheelsetIds: ['wheel_1'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 18,
      ),
      sponsors: const [],
      inventoryBikes: const [],
    );
  }

  List<PrizeMoneyRiderInput> buildSevenDomestiques() {
    return List.generate(
      7,
      (index) => PrizeMoneyRiderInput(
        riderId: 'dom_$index',
        riderName: 'Pomocnik $index',
        isWinner: false,
      ),
    );
  }

  group('PrizeMoneyDistributionService', () {
    test('distributes 500,000 EUR Grand Tour victory across club, winner, domestiques and staff', () {
      final result = service.distributeGrandTourVictory(
        raceId: 'tdf_2026',
        raceName: 'Tour de France 2026',
        winner: const PrizeMoneyRiderInput(
          riderId: 'leader_1',
          riderName: 'Jan Kowalski',
          isWinner: true,
        ),
        domestiques: buildSevenDomestiques(),
        awardedAt: DateTime(2026, 7, 26),
      );

      expect(result.totalPoolEur, 500000);
      expect(result.winnerBonusEur, 75000); // 15% z 500 000
      expect(result.perDomestiqueShareEur, 39285); // 275 000 ~/ 7 = 39 285 (reszta 5)
      expect(result.domestiquesPoolEur, 39285 * 7);
      expect(result.perStaffShareEur, 12500); // 50 000 ~/ 4 = 12 500
      expect(result.staffBonusPoolEur, 50000);
      expect(result.clubShareEur, 100000 + 5); // 20% + reszta z dzielenia 5 EUR
      expect(result.isBalanced, isTrue);
      expect(result.totalDistributedEur, 500000);

      final domestiquePayouts = result.riderPayouts
          .where((p) => p.role == PrizeParticipantRole.domestique)
          .toList();
      expect(domestiquePayouts, hasLength(7));
      for (final payout in domestiquePayouts) {
        expect(payout.amountEur, 39285);
      }
    });

    test('reconciles rounding remainders to exact 1 EUR balance', () {
      final result = service.distributePrizePool(
        input: PrizeMoneyPoolInput(
          raceId: 'prime_race',
          raceName: 'Critérium du Dauphiné',
          raceCategory: RaceCategory.worldTourStageRace,
          sourceType: PrizeMoneySourceType.stageWin,
          totalPoolEur: 100003,
          riders: [
            const PrizeMoneyRiderInput(
              riderId: 'w1',
              riderName: 'Leader',
              isWinner: true,
            ),
            ...buildSevenDomestiques(),
          ],
          staffMembers: const [
            PrizeMoneyStaffInput(
              staffId: 's1',
              staffName: 'DS',
              roleLabel: 'DS',
            ),
            PrizeMoneyStaffInput(
              staffId: 's2',
              staffName: 'Mech',
              roleLabel: 'Mech',
            ),
            PrizeMoneyStaffInput(
              staffId: 's3',
              staffName: 'Doc',
              roleLabel: 'Doc',
            ),
          ],
          awardedAt: DateTime(2026, 6, 12),
        ),
        policy: const PrizeMoneyDistributionPolicy.traditionalPeloton(),
      );

      expect(result.isBalanced, isTrue);
      expect(result.totalDistributedEur, 100003);
    });

    test('handles zero pool and missing domestiques/winner edge cases', () {
      final zeroResult = service.distributePrizePool(
        input: PrizeMoneyPoolInput(
          raceId: 'empty',
          raceName: 'Zero Race',
          raceCategory: RaceCategory.class1,
          sourceType: PrizeMoneySourceType.other,
          totalPoolEur: 0,
          riders: buildSevenDomestiques(),
          awardedAt: DateTime(2026, 3, 1),
        ),
      );
      expect(zeroResult.isBalanced, isTrue);
      expect(zeroResult.totalDistributedEur, 0);
      expect(zeroResult.riderPayouts, isEmpty);

      final soloWinnerResult = service.distributePrizePool(
        input: PrizeMoneyPoolInput(
          raceId: 'solo',
          raceName: 'ITT Worlds',
          raceCategory: RaceCategory.worldTourOneDay,
          sourceType: PrizeMoneySourceType.monumentWin,
          totalPoolEur: 40000,
          riders: const [
            PrizeMoneyRiderInput(
              riderId: 'w1',
              riderName: 'Solo TT',
              isWinner: true,
            ),
          ],
          awardedAt: DateTime(2026, 9, 20),
        ),
      );
      expect(soloWinnerResult.isBalanced, isTrue);
      expect(soloWinnerResult.winnerBonusEur, 28000); // 15% + 55% = 70%
      expect(soloWinnerResult.domestiquesPoolEur, 0);
    });

    test('normalizes invalid policy percentages to 100%', () {
      const invalidPolicy = PrizeMoneyDistributionPolicy(
        clubSharePercent: 40,
        winnerBonusPercent: 20,
        domestiquesPoolPercent: 80,
        staffBonusPercent: 20,
      );
      final normalized = invalidPolicy.normalized();
      expect(normalized.isValid, isTrue);
      expect(normalized.totalPercent, 100);
    });

    test('aggregates multiple pools and updates CyclingTeam budget', () {
      final ledger = service.distributeMultiplePools(
        pools: [
          PrizeMoneyPoolInput(
            raceId: 's1',
            raceName: 'Etap 1',
            raceCategory: RaceCategory.grandTour,
            sourceType: PrizeMoneySourceType.stageWin,
            totalPoolEur: 11000,
            riders: [
              const PrizeMoneyRiderInput(
                riderId: 'w1',
                riderName: 'Sprinter',
                isWinner: true,
              ),
              ...buildSevenDomestiques(),
            ],
            awardedAt: DateTime(2026, 7, 1),
          ),
          PrizeMoneyPoolInput(
            raceId: 'gc',
            raceName: 'Tour de France GC',
            raceCategory: RaceCategory.grandTour,
            sourceType: PrizeMoneySourceType.grandTourGc,
            totalPoolEur: 500000,
            riders: [
              const PrizeMoneyRiderInput(
                riderId: 'w1',
                riderName: 'Sprinter',
                isWinner: true,
              ),
              ...buildSevenDomestiques(),
            ],
            awardedAt: DateTime(2026, 7, 26),
          ),
        ],
      );

      expect(ledger.totalPoolEur, 511000);
      expect(ledger.isBalanced, isTrue);

      final team = buildTeam(cashBalanceEur: 1000000);
      final updated = service.applyClubShareToTeamBudget(
        team: team,
        distribution: ledger.distributions.last,
      );
      expect(
        updated.cashBalanceEur,
        1000000 + ledger.distributions.last.clubShareEur,
      );
    });

    test('serializes and deserializes PrizeMoneyDistributionResult cleanly', () {
      final original = service.distributeGrandTourVictory(
        raceId: 'giro_2026',
        raceName: 'Giro d\'Italia',
        winner: const PrizeMoneyRiderInput(
          riderId: 'w1',
          riderName: 'Marek Nowak',
          isWinner: true,
        ),
        domestiques: buildSevenDomestiques(),
        awardedAt: DateTime(2026, 5, 31),
      );

      final json = original.toJson();
      final restored = PrizeMoneyDistributionResult.fromJson(json);

      expect(restored.raceId, original.raceId);
      expect(restored.totalPoolEur, original.totalPoolEur);
      expect(restored.clubShareEur, original.clubShareEur);
      expect(restored.perDomestiqueShareEur, original.perDomestiqueShareEur);
      expect(restored.riderPayouts.length, original.riderPayouts.length);
      expect(restored.staffPayouts.length, original.staffPayouts.length);
      expect(restored.isBalanced, isTrue);
    });
  });
}
