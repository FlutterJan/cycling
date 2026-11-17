import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/models/organizer/race_organizer_empire_model.dart';
import 'package:pro_peloton_manager/services/organizer/course_safety_barriers_and_marshals_planner.dart';
import 'package:pro_peloton_manager/services/organizer/star_rider_appearance_fee_negotiator.dart';
import 'package:pro_peloton_manager/ui/screens/race_organizer_hq_dashboard_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/host_city_bidding_auction_modal.dart';

HostCityBid _makeGrandDepartBid({
  required String bidId,
  required String cityName,
  required String countryCode,
  required int feeEur,
  double terrainFitScore = 88.0,
  int crowdTurnout = 320000,
}) {
  return HostCityBid(
    bidId: bidId,
    raceId: 'race_grande_boucle_2uwt',
    cityName: cityName,
    countryCode: countryCode,
    regionName: 'Region $cityName',
    role: HostBidRole.grandDepart,
    targetStageNumber: 1,
    bidFeeEur: feeEur,
    localInfrastructureGrantEur: 900000,
    hospitalityRevenuePotentialEur: 1150000,
    tourismExposureDemand: 92.0,
    terrainFitScore: terrainFitScore,
    politicalStabilityIndex: 94.0,
    crowdTurnoutForecast: crowdTurnout,
    deadlineDay: 24,
  );
}

void main() {
  group('RaceOrganizerEmpireModel — przetargi miast, kontrakty TV i budżet', () {
    test('starter ASO preset posiada wyścigi 2.UWT, kontrakty i otwarte przetargi', () {
      final empire = RaceOrganizerEmpireModel.createStarterAsoPreset(seasonYear: 2026);

      expect(empire.organizerId, 'org_aso_global');
      expect(empire.seasonYear, 2026);
      expect(empire.managedRaces.length, greaterThanOrEqualTo(2));
      expect(empire.worldTourRaceCount, 2);
      expect(empire.totalAnnualTvRevenueEur, greaterThan(0));
      expect(empire.totalCommittedHostFeesEur, greaterThan(0));
      expect(empire.empireValuationEur, greaterThan(empire.budgetLedger.liquidCashEur));
      expect(
        empire.pendingHostCityBids.any((b) => b.status == HostBidStatus.openForBidding),
        isTrue,
      );
    });

    test('przyznanie przetargu odrzuca konkurencyjne oferty na ten sam slot i księguje opłatę', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset(seasonYear: 2026);
      final withCompetingBids = base
          .submitHostCityBid(
            _makeGrandDepartBid(
              bidId: 'bid_bilbao_gd',
              cityName: 'Bilbao',
              countryCode: 'ES',
              feeEur: 3400000,
              terrainFitScore: 93.0,
              crowdTurnout: 410000,
            ),
          )
          .submitHostCityBid(
            _makeGrandDepartBid(
              bidId: 'bid_copenhagen_gd',
              cityName: 'Copenhagen',
              countryCode: 'DK',
              feeEur: 2900000,
              terrainFitScore: 86.0,
              crowdTurnout: 310000,
            ),
          );

      final cashBefore = withCompetingBids.budgetLedger.liquidCashEur;
      final tdfBefore = withCompetingBids.managedRaces
          .firstWhere((r) => r.raceId == 'race_grande_boucle_2uwt');

      final result = withCompetingBids.awardHostCityBid(
        'bid_bilbao_gd',
        contractLengthYears: 2,
      );

      expect(result.success, isTrue);
      final updated = result.updatedEmpire;

      final bilbao = updated.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_bilbao_gd');
      final copenhagen = updated.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_copenhagen_gd');
      final alpeOtherSlot = updated.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_alpe_dhuez_s19');

      expect(bilbao.status, HostBidStatus.awarded);
      expect(copenhagen.status, HostBidStatus.rejected);
      expect(alpeOtherSlot.status, HostBidStatus.openForBidding);

      expect(updated.budgetLedger.liquidCashEur, cashBefore + 3400000);
      expect(
        updated.budgetLedger.recentTransactions.any(
          (tx) =>
              tx.category == OrganizerCashflowCategory.hostCityFee &&
              tx.amountEur == 3400000 &&
              tx.relatedRaceId == 'race_grande_boucle_2uwt',
        ),
        isTrue,
      );

      final tdfAfter = updated.managedRaces
          .firstWhere((r) => r.raceId == 'race_grande_boucle_2uwt');
      expect(
        tdfAfter.hostCityContracts.length,
        tdfBefore.hostCityContracts.length + 1,
      );
      final newContract = tdfAfter.hostCityContracts.last;
      expect(newContract.cityName, 'Bilbao');
      expect(newContract.contractLengthYears, 2);
      expect(newContract.remainingYears, 2);
      expect(tdfAfter.courseQualityScore, greaterThanOrEqualTo(tdfBefore.courseQualityScore));
    });

    test('obsługuje błędy brzegowe przy nieistniejącym lub zamkniętym przetargu', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset();

      final missingAward = base.awardHostCityBid('non_existent_bid');
      expect(missingAward.success, isFalse);
      expect(missingAward.updatedEmpire.budgetLedger.liquidCashEur, base.budgetLedger.liquidCashEur);

      final missingReject = base.rejectHostCityBid('non_existent_bid');
      expect(missingReject.success, isFalse);

      final rejected = base.rejectHostCityBid('bid_grenoble_s1');
      expect(rejected.success, isTrue);

      final awardAfterReject = rejected.updatedEmpire.awardHostCityBid('bid_grenoble_s1');
      expect(awardAfterReject.success, isFalse);
    });

    test('podpisanie praw TV, ocena prestiżu UCI oraz zamknięcie roku budżetowego', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset(seasonYear: 2026);
      const tvContract = TvRightsContract(
        contractId: 'tv_global_stream_2026',
        raceId: 'race_dauphine_2uwt',
        broadcasterName: 'Eurosport Global',
        territory: TvRightsTerritory.globalWorldwide,
        tier: TvBroadcastTier.panContinentalSports,
        status: TvContractStatus.active,
        annualRightsFeeEur: 1650000,
        viewershipBonusPerMillionEur: 180000,
        estimatedAvgViewersMillions: 1.8,
        minimumLiveHoursPerStage: 4.0,
        helicopterRelayRequired: true,
        onboardCamerasRequired: true,
        startSeasonYear: 2026,
        durationYears: 1,
        remainingYears: 1,
      );

      final tvResult = base.signTvRightsContract(tvContract);
      expect(tvResult.success, isTrue);

      final prestige = tvResult.updatedEmpire.recalculateRacePrestige('race_dauphine_2uwt');
      expect(prestige, isNotNull);
      expect(prestige!.meetsPrizePoolRequirement, isTrue);
      expect(prestige.meetsTvCoverageRequirement, isTrue);
      expect(prestige.calculatedPrestigeScore, inInclusiveRange(0.0, 100.0));

      final nextSeason = tvResult.updatedEmpire.advanceSeasonFinancials();
      expect(nextSeason.seasonYear, 2027);

      final dauphineNext = nextSeason.managedRaces
          .firstWhere((r) => r.raceId == 'race_dauphine_2uwt');
      expect(dauphineNext.consecutivelyHeldYears, 79);
      expect(dauphineNext.tvRightsContracts.first.status, TvContractStatus.expired);
      expect(dauphineNext.tvRightsContracts.first.remainingYears, 0);

      final tdfNext = nextSeason.managedRaces
          .firstWhere((r) => r.raceId == 'race_grande_boucle_2uwt');
      // 1-roczny kontrakt Barcelony wygasł po zamknięciu sezonu 2026.
      expect(tdfNext.hostCityContracts, isEmpty);
    });

    test('ocena prestiżu wykrywa kwalifikację do awansu UCI i ryzyko degradacji', () {
      const strongProRace = ManagedRacePortfolioItem(
        raceId: 'race_promo_candidate',
        raceName: 'Tour de Bretagne',
        countryCode: 'FR',
        tier: UciRaceClassificationTier.uci2Pro,
        stageCount: 6,
        prestigeScore: 84.0,
        globalViewershipIndex: 86.0,
        courseQualityScore: 88.0,
        safetyRatingScore: 85.0,
        starPowerScore: 84.0,
        uciComplianceScore: 90.0,
        titleSponsorName: 'Breizh Bank',
        titleSponsorAnnualEur: 1200000,
        prizePoolEur: 200000,
        consecutivelyHeldYears: 12,
        tvRightsContracts: [
          TvRightsContract(
            contractId: 'tv_breizh',
            raceId: 'race_promo_candidate',
            broadcasterName: 'France 3',
            territory: TvRightsTerritory.franceBenelux,
            tier: TvBroadcastTier.freeToAirNational,
            status: TvContractStatus.active,
            annualRightsFeeEur: 600000,
            viewershipBonusPerMillionEur: 50000,
            estimatedAvgViewersMillions: 1.0,
            minimumLiveHoursPerStage: 3.0,
            helicopterRelayRequired: false,
            onboardCamerasRequired: false,
            startSeasonYear: 2026,
            durationYears: 2,
            remainingYears: 2,
          ),
        ],
      );

      final promoEval = strongProRace.evaluateUciPrestige();
      expect(promoEval.promotionEligible, isTrue);
      expect(promoEval.recommendedTier, UciRaceClassificationTier.uci2Uwt);

      final weakRace = strongProRace.copyWith(
        starPowerScore: 30.0,
        globalViewershipIndex: 25.0,
        courseQualityScore: 40.0,
        safetyRatingScore: 45.0,
        uciComplianceScore: 40.0,
        prizePoolEur: 10000,
        tvRightsContracts: const [],
      );
      final relegEval = weakRace.evaluateUciPrestige();
      expect(relegEval.relegationRisk, isTrue);
      expect(relegEval.complianceNotes, isNotEmpty);
    });

    test('serializacja JSON zachowuje pełny stan imperium 1:1', () {
      final base = RaceOrganizerEmpireModel.createStarterAsoPreset(seasonYear: 2026);
      final awarded = base.awardHostCityBid('bid_alpe_dhuez_s19').updatedEmpire;

      final json = awarded.toJson();
      final restored = RaceOrganizerEmpireModel.fromJson(json);

      expect(restored.organizerId, awarded.organizerId);
      expect(restored.syndicateName, awarded.syndicateName);
      expect(restored.seasonYear, awarded.seasonYear);
      expect(
        restored.budgetLedger.liquidCashEur,
        awarded.budgetLedger.liquidCashEur,
      );
      expect(restored.managedRaces.length, awarded.managedRaces.length);
      expect(restored.pendingHostCityBids.length, awarded.pendingHostCityBids.length);
      expect(
        restored.pendingHostCityBids
            .firstWhere((b) => b.bidId == 'bid_alpe_dhuez_s19')
            .status,
        HostBidStatus.awarded,
      );
    });
  });

  group('Integracja usług Organizatora — Gwiazdy i Bezpieczeństwo SafeR', () {
    test('negocjacja Appearance Fee i księgowanie w budżecie organizatora', () {
      final empire = RaceOrganizerEmpireModel.createStarterAsoPreset();
      const negotiator = StarRiderAppearanceFeeNegotiator();
      final catalog = StarRiderAppearanceFeeNegotiator.createDefaultCatalog();
      final blueprint = StarRiderAppearanceFeeNegotiator.createDefaultCourseBlueprint(
        raceId: 'race_grande_boucle_2uwt',
        raceName: 'Tour de France',
      );
      final sessions = StarRiderAppearanceFeeNegotiator.createInitialSessions(
        catalog,
      );

      final session = sessions.firstWhere(
        (s) => s.status == AppearanceNegotiationStatus.available,
        orElse: () => sessions.first,
      );
      final dynamicDemand = session.rider.calculateDynamicDemandEur(blueprint);
      final offer = AppearanceOfferTerms(
        offeredFeeEur: (dynamicDemand * 1.25).round(),
        includePrivateJetAndVipHospitality: true,
        includeGuaranteedTvSpotlight: true,
        includeWildcardTeamInvite: true,
        stageWinBonusEur: 40000,
      );

      final outcome = negotiator.evaluateOffer(
        session: session,
        course: blueprint,
        offer: offer,
        availableBudgetEur: empire.budgetLedger.liquidCashEur,
      );

      expect(outcome.accepted, isTrue);
      expect(outcome.session.status, AppearanceNegotiationStatus.signed);

      final cashBefore = empire.budgetLedger.liquidCashEur;
      final updatedLedger = negotiator.recordSignedFeeInLedger(
        ledger: empire.budgetLedger,
        session: outcome.session,
        raceId: 'race_grande_boucle_2uwt',
        seasonYear: empire.seasonYear,
      );

      expect(
        updatedLedger.liquidCashEur,
        cashBefore - (outcome.session.agreedFeeEur ?? 0),
      );

      final impact = negotiator.computePortfolioImpact(
        sessions: [outcome.session],
        course: blueprint,
        raceItem: empire.managedRaces.first,
      );
      expect(impact.signedStarsCount, 1);
      expect(impact.totalAppearanceFeesEur, outcome.session.agreedFeeEur);
    });

    test('audyt SafeR, auto-optymalizacja barier Boplan i księgowanie w imperium', () {
      final empire = RaceOrganizerEmpireModel.createStarterAsoPreset();
      const planner = CourseSafetyBarriersAndMarshalsPlanner();
      final zones = CourseSafetyBarriersAndMarshalsPlanner.createDefaultStageHazardZones();
      final inventory = CourseSafetyBarriersAndMarshalsPlanner.createDefaultInventory();
      final tdf = empire.managedRaces.first;

      final initialAudit = planner.auditCourseSafety(
        raceId: tdf.raceId,
        raceName: tdf.raceName,
        stageNumber: 14,
        zones: zones,
        inventory: inventory,
        availableBudgetEur: empire.budgetLedger.safetyInfrastructureBudgetEur,
      );
      // Strefa na półce skalnej ma domyślnie SafetyBarrierSystemType.none -> criticalFailure
      expect(initialAudit.complianceGrade, SafetyAuditComplianceGrade.criticalFailure);
      expect(initialAudit.uciFineRiskEur, greaterThan(0));

      final optimizedZones = planner.autoOptimizeSafeRDeployment(
        zones: zones,
        maxBudgetEur: empire.budgetLedger.safetyInfrastructureBudgetEur,
      );
      final optimizedAudit = planner.auditCourseSafety(
        raceId: tdf.raceId,
        raceName: tdf.raceName,
        stageNumber: 14,
        zones: optimizedZones,
        inventory: inventory,
        availableBudgetEur: empire.budgetLedger.safetyInfrastructureBudgetEur,
      );

      expect(
        optimizedAudit.overallSafetyScore,
        greaterThan(initialAudit.overallSafetyScore),
      );
      expect(
        optimizedAudit.complianceGrade,
        isNot(SafetyAuditComplianceGrade.criticalFailure),
      );
      expect(optimizedAudit.uciFineRiskEur, 0);

      final integration = planner.applySafetyPlanToEmpire(
        ledger: empire.budgetLedger,
        race: tdf,
        auditReport: optimizedAudit,
        seasonYear: empire.seasonYear,
      );
      expect(
        integration.updatedLedger.liquidCashEur,
        empire.budgetLedger.liquidCashEur - optimizedAudit.totalDeploymentCostEur,
      );
    });
  });

  group('RaceOrganizerHqNotifier & RaceOrganizerHqDashboardScreen', () {
    test('notifier obsługuje sekcje, filtry, przetargi, prawa TV i tryb readOnly', () {
      final notifier = RaceOrganizerHqNotifier();
      expect(notifier.state.activeSection, OrganizerHqSection.overviewAndBroadcast);

      notifier.setSection(OrganizerHqSection.hostCityBiddingMap);
      expect(notifier.state.activeSection, OrganizerHqSection.hostCityBiddingMap);

      notifier.setBidFilter(HostCityBidFilter.openOnly);
      expect(notifier.state.bidFilter, HostCityBidFilter.openOnly);

      notifier.setCameraMode(RaceCameraMode.heliCam);
      expect(notifier.state.cameraMode, RaceCameraMode.heliCam);

      final initialCash = notifier.state.empire.budgetLedger.liquidCashEur;
      notifier.awardSelectedBid();
      expect(notifier.state.isLastActionSuccess, isTrue);
      expect(notifier.state.empire.budgetLedger.liquidCashEur, greaterThan(initialCash));

      final roNotifier = RaceOrganizerHqNotifier(isReadOnly: true);
      final roCash = roNotifier.state.empire.budgetLedger.liquidCashEur;
      roNotifier.awardSelectedBid();
      roNotifier.advanceSeason();
      expect(roNotifier.state.empire.budgetLedger.liquidCashEur, roCash);
      expect(roNotifier.state.empire.seasonYear, 2026);
    });

    Future<void> pumpDashboard(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: RaceOrganizerHqDashboardScreen(
              isReadOnly: isReadOnly,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje RaceOrganizerHqDashboardScreen bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpDashboard(tester, size);
          expect(tester.takeException(), isNull);
          expect(find.byType(RaceOrganizerHqDashboardScreen), findsOneWidget);

          final mapTab = find.text('Mapa Przetargów');
          if (mapTab.evaluate().isNotEmpty) {
            await tester.tap(mapTab.first);
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  });

  group('HostCityBiddingAuctionModal — interakcja i responsywność', () {
    Future<void> pumpAuctionModal(
      WidgetTester tester,
      Size size, {
      required RaceOrganizerEmpireModel empire,
      bool isReadOnly = false,
      ValueChanged<HostCityBiddingAuctionResult>? onEmpireChanged,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: HostCityBiddingAuctionModal(
                  initialEmpire: empire,
                  isReadOnly: isReadOnly,
                  onEmpireChanged: onEmpireChanged,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje HostCityBiddingAuctionModal bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final empire = RaceOrganizerEmpireModel.createStarterAsoPreset()
              .submitHostCityBid(
            _makeGrandDepartBid(
              bidId: 'bid_bilbao_gd',
              cityName: 'Bilbao',
              countryCode: 'ES',
              feeEur: 3400000,
            ),
          );

          await pumpAuctionModal(tester, size, empire: empire);
          expect(tester.takeException(), isNull);
          expect(find.byType(HostCityBiddingAuctionModal), findsOneWidget);
        },
      );
    }

    testWidgets('filtrowanie Grand Départ i przyznanie przetargu wywołuje callback', (tester) async {
      final empire = RaceOrganizerEmpireModel.createStarterAsoPreset()
          .submitHostCityBid(
        _makeGrandDepartBid(
          bidId: 'bid_bilbao_gd',
          cityName: 'Bilbao',
          countryCode: 'ES',
          feeEur: 3400000,
        ),
      );

      HostCityBiddingAuctionResult? latestResult;
      await pumpAuctionModal(
        tester,
        const Size(1280, 840),
        empire: empire,
        onEmpireChanged: (res) => latestResult = res,
      );

      await tester.tap(find.text('Grand Départ').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Bilbao'), findsWidgets);

      final awardBtn = find.textContaining('Przyznaj').first;
      await tester.ensureVisible(awardBtn);
      await tester.tap(awardBtn);
      await tester.pump(const Duration(milliseconds: 250));

      expect(latestResult, isNotNull);
      expect(latestResult!.awardedBidIds, contains('bid_bilbao_gd'));
    });
  });
}
