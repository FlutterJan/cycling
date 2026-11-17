import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/organizer/race_organizer_empire_model.dart';

void main() {
  group('RaceOrganizerEmpireModel', () {
    test('JSON round-trip preserves full empire state and equality', () {
      final starter = RaceOrganizerEmpireModel.createStarterAsoPreset(
        seasonYear: 2026,
      );

      final encoded = starter.toJson();
      final decoded = RaceOrganizerEmpireModel.fromJson(encoded);

      expect(decoded, equals(starter));
      expect(decoded.organizerId, 'org_aso_global');
      expect(decoded.managedRaces.length, 2);
      expect(decoded.pendingHostCityBids.length, 2);
      expect(decoded.worldTourRaceCount, 2);
    });

    test('enum fromJson falls back safely on unknown values', () {
      expect(
        UciRaceClassificationTier.fromJson('unknown_tier'),
        UciRaceClassificationTier.uci2Pro,
      );
      expect(
        HostBidRole.fromJson('unknown_role'),
        HostBidRole.stageFinish,
      );
      expect(
        TvBroadcastTier.fromJson('unknown_tv'),
        TvBroadcastTier.panContinentalSports,
      );
      expect(
        OrganizerSyndicateArchetype.fromJson('unknown_arch'),
        OrganizerSyndicateArchetype.independentProSeries,
      );
    });

    test('awardHostCityBid awards winner, rejects competing slot bids, and credits budget', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset();
      const competingBid = HostCityBid(
        bidId: 'bid_courchevel_s19',
        raceId: 'race_grande_boucle_2uwt',
        cityName: 'Courchevel',
        countryCode: 'FR',
        regionName: 'Auvergne-Rhône-Alpes',
        role: HostBidRole.mountainSummitFinish,
        targetStageNumber: 19,
        bidFeeEur: 1500000,
        localInfrastructureGrantEur: 500000,
        hospitalityRevenuePotentialEur: 750000,
        tourismExposureDemand: 88.0,
        terrainFitScore: 95.0,
        politicalStabilityIndex: 94.0,
        crowdTurnoutForecast: 300000,
        deadlineDay: 45,
      );

      final withCompetitor = base.submitHostCityBid(competingBid);
      final initialCash = withCompetitor.budgetLedger.liquidCashEur;

      final result = withCompetitor.awardHostCityBid(
        'bid_alpe_dhuez_s19',
        contractLengthYears: 2,
      );

      expect(result.success, isTrue);
      final updated = result.updatedEmpire;
      expect(updated.budgetLedger.liquidCashEur, initialCash + 1850000);
      expect(updated.budgetLedger.totalRevenueYtdEur, 1850000);

      final alpeBid = updated.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_alpe_dhuez_s19');
      final courchevelBid = updated.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_courchevel_s19');
      final grenobleBid = updated.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_grenoble_s1');

      expect(alpeBid.status, HostBidStatus.awarded);
      expect(courchevelBid.status, HostBidStatus.rejected);
      expect(grenobleBid.status, HostBidStatus.openForBidding);

      final tour = updated.managedRaces
          .firstWhere((r) => r.raceId == 'race_grande_boucle_2uwt');
      expect(tour.hostCityContracts.length, 2);
      expect(tour.hostCityContracts.last.cityName, "Alpe d'Huez");
      expect(tour.hostCityContracts.last.remainingYears, 2);
    });

    test('awardHostCityBid fails gracefully for missing or already decided bid', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset();
      final missing = base.awardHostCityBid('non_existent');
      expect(missing.success, isFalse);

      final rejected = base.rejectHostCityBid('bid_grenoble_s1');
      expect(rejected.success, isTrue);

      final secondAttempt =
          rejected.updatedEmpire.awardHostCityBid('bid_grenoble_s1');
      expect(secondAttempt.success, isFalse);
    });

    test('signTvRightsContract adds contract, boosts viewership, and updates revenue', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset();
      final initialTvRev = base.totalAnnualTvRevenueEur;

      const eurosportDeal = TvRightsContract(
        contractId: 'tv_eurosport_pan',
        raceId: 'race_dauphine_2uwt',
        broadcasterName: 'Eurosport / Discovery+',
        territory: TvRightsTerritory.europeCore,
        tier: TvBroadcastTier.panContinentalSports,
        status: TvContractStatus.active,
        annualRightsFeeEur: 3200000,
        viewershipBonusPerMillionEur: 200000,
        estimatedAvgViewersMillions: 1.5,
        minimumLiveHoursPerStage: 4.0,
        helicopterRelayRequired: true,
        onboardCamerasRequired: false,
        startSeasonYear: 2026,
        durationYears: 4,
        remainingYears: 4,
      );

      final res = base.signTvRightsContract(eurosportDeal);
      expect(res.success, isTrue);
      expect(
        res.updatedEmpire.totalAnnualTvRevenueEur,
        initialTvRev + 3500000,
      );
      expect(
        eurosportDeal.meetsUciLiveCoverageForTier(
          UciRaceClassificationTier.uci2Uwt,
        ),
        isTrue,
      );
    });

    test('UCI prestige evaluation detects promotion eligibility and relegation risk', () {
      const highFlyingProRace = ManagedRacePortfolioItem(
        raceId: 'race_pro_candidate',
        raceName: 'Tour of the Alps Pro',
        countryCode: 'IT',
        tier: UciRaceClassificationTier.uci2Pro,
        stageCount: 5,
        prestigeScore: 80.0,
        globalViewershipIndex: 82.0,
        courseQualityScore: 88.0,
        safetyRatingScore: 86.0,
        starPowerScore: 85.0,
        uciComplianceScore: 90.0,
        titleSponsorName: 'Melinda',
        titleSponsorAnnualEur: 900000,
        prizePoolEur: 180000,
        consecutivelyHeldYears: 12,
        tvRightsContracts: [
          TvRightsContract(
            contractId: 'tv_rai',
            raceId: 'race_pro_candidate',
            broadcasterName: 'RAI Sport',
            territory: TvRightsTerritory.italySpain,
            tier: TvBroadcastTier.freeToAirNational,
            status: TvContractStatus.active,
            annualRightsFeeEur: 650000,
            viewershipBonusPerMillionEur: 50000,
            estimatedAvgViewersMillions: 0.8,
            minimumLiveHoursPerStage: 3.0,
            helicopterRelayRequired: true,
            onboardCamerasRequired: false,
            startSeasonYear: 2026,
            durationYears: 2,
            remainingYears: 2,
          ),
        ],
      );

      final promoAssessment = highFlyingProRace.evaluateUciPrestige();
      expect(promoAssessment.promotionEligible, isTrue);
      expect(promoAssessment.relegationRisk, isFalse);
      expect(
        promoAssessment.recommendedTier,
        UciRaceClassificationTier.uci2Uwt,
      );

      const strugglingUwtRace = ManagedRacePortfolioItem(
        raceId: 'race_uwt_risk',
        raceName: 'Struggling Tour',
        countryCode: 'BE',
        tier: UciRaceClassificationTier.uci2Uwt,
        stageCount: 7,
        prestigeScore: 52.0,
        globalViewershipIndex: 42.0,
        courseQualityScore: 55.0,
        safetyRatingScore: 58.0,
        starPowerScore: 45.0,
        uciComplianceScore: 60.0,
        titleSponsorName: 'Local Bank',
        titleSponsorAnnualEur: 300000,
        prizePoolEur: 150000,
        consecutivelyHeldYears: 4,
      );

      final riskAssessment = strugglingUwtRace.evaluateUciPrestige();
      expect(riskAssessment.relegationRisk, isTrue);
      expect(riskAssessment.meetsPrizePoolRequirement, isFalse);
      expect(riskAssessment.meetsTvCoverageRequirement, isFalse);
      expect(riskAssessment.complianceNotes.length, greaterThanOrEqualTo(3));
      expect(
        riskAssessment.recommendedTier,
        UciRaceClassificationTier.uci2Pro,
      );
    });

    test('advanceSeasonFinancials settles cashflow and decrements contract years', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset(
        seasonYear: 2026,
      );

      final nextSeason = base.advanceSeasonFinancials();

      expect(nextSeason.seasonYear, 2027);
      expect(nextSeason.managedRaces.first.consecutivelyHeldYears, 114);
      // 1-year Barcelona Grand Départ contract expires after season rollover
      expect(nextSeason.managedRaces.first.hostCityContracts, isEmpty);
      // 4-year remaining TV contract becomes 3 years
      expect(
        nextSeason.managedRaces.first.tvRightsContracts.first.remainingYears,
        3,
      );
      expect(nextSeason.budgetLedger.recentTransactions, isNotEmpty);
      expect(nextSeason.empireValuationEur, greaterThan(0));
    });
  });
}
