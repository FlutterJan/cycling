import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/equipment_sponsorship_bidding_engine.dart';

void main() {
  group('EquipmentSponsorshipBiddingEngine - 1. Polityka producenta ram w sprawie kół (Proprietary Wheels Policy)', () {
    test('Specialized wymusza koła Roval i blokuje niezależny przetarg na koła', () {
      const specializedDeal = BikeManufacturerDeal(
        manufacturerId: 'brand_specialized',
        manufacturerName: 'Specialized S-Works',
        prestigeLevel: 5,
        annualCashContributionEur: 2500000,
        freeBikesQuota: 90,
        researchAndDevelopmentLevel: 95,
        suppliedFrameIds: ['frame_tarmac_sl8', 'frame_shiv_tt'],
        suppliedWheelsetIds: ['wheels_roval_rapide', 'wheels_roval_disc'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 10,
      );

      final policy = EquipmentSponsorshipBiddingEngine.checkProprietaryWheelsPolicy(
        frameDeal: specializedDeal,
      );

      expect(policy.isRestricted, isTrue);
      expect(policy.proprietaryWheelBrand, contains('Roval'));
      expect(policy.explanation, contains('wyłącznego stosowania kół marki Roval'));
    });

    test('Trek wymusza koła Bontrager i blokuje przetarg', () {
      const trekDeal = BikeManufacturerDeal(
        manufacturerId: 'brand_trek',
        manufacturerName: 'Trek Factory Racing',
        prestigeLevel: 5,
        annualCashContributionEur: 2200000,
        freeBikesQuota: 85,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: ['frame_madone_gen8'],
        suppliedWheelsetIds: ['wheels_bontrager_aeolus'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 12,
      );

      final policy = EquipmentSponsorshipBiddingEngine.checkProprietaryWheelsPolicy(
        frameDeal: trekDeal,
      );

      expect(policy.isRestricted, isTrue);
      expect(policy.proprietaryWheelBrand, contains('Bontrager'));
    });

    test('Giant/Cadex wymusza koła Cadex', () {
      const giantDeal = BikeManufacturerDeal(
        manufacturerId: 'brand_giant',
        manufacturerName: 'Giant Bicycles',
        prestigeLevel: 4,
        annualCashContributionEur: 1800000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 88,
        suppliedFrameIds: ['frame_propel_advanced'],
        suppliedWheelsetIds: ['wheels_cadex_50'],
        contractYearsLeft: 1,
        minimumUciRankingRequired: 15,
      );

      final policy = EquipmentSponsorshipBiddingEngine.checkProprietaryWheelsPolicy(
        frameDeal: giantDeal,
      );

      expect(policy.isRestricted, isTrue);
      expect(policy.proprietaryWheelBrand, contains('Cadex'));
    });

    test('Cervélo i Colnago zezwalają na wolny przetarg na koła niezależne', () {
      const cerveloDeal = BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo Cycles',
        prestigeLevel: 5,
        annualCashContributionEur: 2600000,
        freeBikesQuota: 95,
        researchAndDevelopmentLevel: 96,
        suppliedFrameIds: ['frame_s5_aero', 'frame_p5_tt'],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 8,
      );

      final policy = EquipmentSponsorshipBiddingEngine.checkProprietaryWheelsPolicy(
        frameDeal: cerveloDeal,
      );

      expect(policy.isRestricted, isFalse);
      expect(policy.proprietaryWheelBrand, isNull);
      expect(policy.explanation, contains('pełną swobodę techniczną'));
    });
  });

  group('EquipmentSponsorshipBiddingEngine - 2. Inicjalizacja sesji przetargowej pod koniec sezonu', () {
    late CyclingTeam openTeam;
    late CyclingTeam restrictedTeam;

    setUp(() {
      const openDeal = BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo Cycles',
        prestigeLevel: 5,
        annualCashContributionEur: 2000000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: ['cervelo_s5'],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 15,
      );

      const specializedDeal = BikeManufacturerDeal(
        manufacturerId: 'specialized',
        manufacturerName: 'Specialized S-Works',
        prestigeLevel: 5,
        annualCashContributionEur: 2500000,
        freeBikesQuota: 85,
        researchAndDevelopmentLevel: 95,
        suppliedFrameIds: ['tarmac_sl8'],
        suppliedWheelsetIds: ['roval_rapide'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 10,
      );

      openTeam = const CyclingTeam(
        id: 'team_cervelo_wt',
        name: 'Veloce Cervélo Team',
        division: TeamDivision.worldTour,
        countryIso: 'NED',
        primaryJerseyColorHex: '#FFFF00',
        secondaryJerseyColorHex: '#000000',
        accentJerseyColorHex: '#FF0000',
        cashBalanceEur: 3000000,
        monthlyBurnRateEur: 400000,
        uciPointsSeason: 4500,
        rosterRiderIds: [],
        staff: TeamStaff(
          trainersLevel: 80,
          sportsDirectorsLevel: 80,
          doctorsLevel: 80,
          mechanicsLevel: 80,
          scoutsLevel: 80,
        ),
        bikeDeal: openDeal,
        sponsors: [],
        inventoryBikes: [],
      );

      restrictedTeam = openTeam.copyWith(
        id: 'team_specialized_wt',
        bikeDeal: specializedDeal,
      );
    });

    test('openEndOfSeasonTender dla Cervélo generuje oferty we wszystkich kategoriach (w tym koła)', () {
      final session = EquipmentSponsorshipBiddingEngine.openEndOfSeasonTender(
        team: openTeam,
        seasonYear: 2026,
      );

      expect(session.seasonYear, 2026);
      expect(session.negotiationRoundsRemaining, 3);
      expect(session.isConcluded, isFalse);

      // Sprawdzenie obecności ofert na koła
      final wheelOffers = session.availableOffersByCategory[EquipmentSponsorCategory.wheels];
      expect(wheelOffers, isNotNull);
      expect(wheelOffers!.length, greaterThanOrEqualTo(4));
      expect(wheelOffers.any((o) => o.brandName.contains('Reserve')), isTrue);
      expect(wheelOffers.any((o) => o.brandName.contains('Vision')), isTrue);
      expect(wheelOffers.any((o) => o.brandName.contains('Princeton')), isTrue);

      // Pozostałe kategorie
      expect(session.availableOffersByCategory[EquipmentSponsorCategory.groupsetAndPower]!.length, 3);
      expect(session.availableOffersByCategory[EquipmentSponsorCategory.helmetsAndEyewear]!.length, 4);
      expect(session.availableOffersByCategory[EquipmentSponsorCategory.apparel]!.length, 4);
      expect(session.availableOffersByCategory[EquipmentSponsorCategory.nutrition]!.length, 4);
    });

    test('openEndOfSeasonTender dla Specialized blokuje oferty na koła (pusta lista kół)', () {
      final session = EquipmentSponsorshipBiddingEngine.openEndOfSeasonTender(
        team: restrictedTeam,
        seasonYear: 2026,
      );

      expect(session.availableOffersByCategory[EquipmentSponsorCategory.wheels], isEmpty);
      // Odzież i żywienie są nadal dostępne
      expect(session.availableOffersByCategory[EquipmentSponsorCategory.apparel]!.isNotEmpty, isTrue);
      expect(session.availableOffersByCategory[EquipmentSponsorCategory.nutrition]!.isNotEmpty, isTrue);
    });
  });

  group('EquipmentSponsorshipBiddingEngine - 3. Negocjacje i kontroferty (Bidding Negotiation)', () {
    late EquipmentTenderSession session;
    late TechnicalContractOffer apparelOffer;

    setUp(() {
      const openDeal = BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo Cycles',
        prestigeLevel: 5,
        annualCashContributionEur: 2000000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: [],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 15,
      );

      const team = CyclingTeam(
        id: 'team_cervelo_wt',
        name: 'Veloce Cervélo Team',
        division: TeamDivision.worldTour,
        countryIso: 'NED',
        primaryJerseyColorHex: '#FFFF00',
        secondaryJerseyColorHex: '#000000',
        accentJerseyColorHex: '#FF0000',
        cashBalanceEur: 3000000,
        monthlyBurnRateEur: 400000,
        uciPointsSeason: 4500,
        rosterRiderIds: [],
        staff: TeamStaff(
          trainersLevel: 80,
          sportsDirectorsLevel: 80,
          doctorsLevel: 80,
          mechanicsLevel: 80,
          scoutsLevel: 80,
        ),
        bikeDeal: openDeal,
        sponsors: [],
        inventoryBikes: [],
      );

      session = EquipmentSponsorshipBiddingEngine.openEndOfSeasonTender(
        team: team,
        seasonYear: 2026,
      );

      apparelOffer = session.availableOffersByCategory[EquipmentSponsorCategory.apparel]!
          .firstWhere((o) => o.brandId == 'brand_bioracer');
    });

    test('Umiarkowane żądanie (+10% gotówki) zostaje zaakceptowane', () {
      final originalCash = apparelOffer.annualCashContributionEur;
      final requestedCash = (originalCash * 1.10).round();

      final result = EquipmentSponsorshipBiddingEngine.negotiateOffer(
        session: session,
        offer: apparelOffer,
        requestedAnnualCashEur: requestedCash,
        requestedDurationYears: apparelOffer.contractDurationYears,
      );

      expect(result.isAccepted, isTrue);
      expect(result.reaction, TenderNegotiationReaction.accepted);
      expect(result.revisedOffer!.annualCashContributionEur, requestedCash);
      expect(result.roundsRemaining, 2);
    });

    test('Średnie żądanie (+30% gotówki) + tunel aero skutkuje kompromisową kontrofertą', () {
      final originalCash = apparelOffer.annualCashContributionEur;
      final requestedCash = (originalCash * 1.30).round();

      final result = EquipmentSponsorshipBiddingEngine.negotiateOffer(
        session: session,
        offer: apparelOffer,
        requestedAnnualCashEur: requestedCash,
        requestedDurationYears: 3,
        demandWindTunnelAllocation: true,
      );

      expect(result.isCounterOffered, isTrue);
      expect(result.reaction, TenderNegotiationReaction.counterOffered);
      expect(result.revisedOffer!.annualCashContributionEur, greaterThan(originalCash));
      expect(result.revisedOffer!.annualCashContributionEur, lessThan(requestedCash));
      expect(result.revisedOffer!.contractDurationYears, 3);
      // Dodatkowe waty za sesje w tunelu
      expect(result.revisedOffer!.apparelPerks!.ttSkinsuitWattSavings,
          greaterThan(apparelOffer.apparelPerks!.ttSkinsuitWattSavings));
    });

    test('Przesadne żądania (+60% gotówki) powodują zerwanie rozmów (withdrawn)', () {
      final originalCash = apparelOffer.annualCashContributionEur;
      final requestedCash = (originalCash * 1.60).round();

      final result = EquipmentSponsorshipBiddingEngine.negotiateOffer(
        session: session,
        offer: apparelOffer,
        requestedAnnualCashEur: requestedCash,
        requestedDurationYears: apparelOffer.contractDurationYears,
      );

      expect(result.isWithdrawn, isTrue);
      expect(result.reaction, TenderNegotiationReaction.withdrawn);
      expect(result.sponsorCommentary, contains('obraźliwe'));
    });

    test('Wyczerpanie rund negocjacyjnych odrzuca próbę', () {
      final exhaustedSession = session.copyWith(negotiationRoundsRemaining: 0);

      final result = EquipmentSponsorshipBiddingEngine.negotiateOffer(
        session: exhaustedSession,
        offer: apparelOffer,
        requestedAnnualCashEur: 400000,
        requestedDurationYears: 2,
      );

      expect(result.isRejected, isTrue);
      expect(result.roundsRemaining, 0);
    });
  });

  group('EquipmentSponsorshipBiddingEngine - 4. Podpisywanie kontraktów i finalizacja przetargu', () {
    late CyclingTeam team;
    late EquipmentTenderSession session;

    setUp(() {
      const openDeal = BikeManufacturerDeal(
        manufacturerId: 'cervelo',
        manufacturerName: 'Cervélo Cycles',
        prestigeLevel: 5,
        annualCashContributionEur: 2000000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 90,
        suppliedFrameIds: [],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 15,
      );

      team = const CyclingTeam(
        id: 'team_cervelo_wt',
        name: 'Veloce Cervélo Team',
        division: TeamDivision.worldTour,
        countryIso: 'NED',
        primaryJerseyColorHex: '#FFFF00',
        secondaryJerseyColorHex: '#000000',
        accentJerseyColorHex: '#FF0000',
        cashBalanceEur: 3000000,
        monthlyBurnRateEur: 400000,
        uciPointsSeason: 4500,
        rosterRiderIds: [],
        staff: TeamStaff(
          trainersLevel: 80,
          sportsDirectorsLevel: 80,
          doctorsLevel: 80,
          mechanicsLevel: 80,
          scoutsLevel: 80,
        ),
        bikeDeal: openDeal,
        sponsors: [],
        inventoryBikes: [],
      );

      session = EquipmentSponsorshipBiddingEngine.openEndOfSeasonTender(
        team: team,
        seasonYear: 2026,
      );
    });

    test('Podpisanie kontraktu na koła, osprzęt, odzież i żywienie aktualizuje portfolio', () {
      final wheelsOffer = session.availableOffersByCategory[EquipmentSponsorCategory.wheels]!.first;
      final groupsetOffer = session.availableOffersByCategory[EquipmentSponsorCategory.groupsetAndPower]!.first;
      final apparelOffer = session.availableOffersByCategory[EquipmentSponsorCategory.apparel]!.first;
      final nutritionOffer = session.availableOffersByCategory[EquipmentSponsorCategory.nutrition]!.first;

      var s = EquipmentSponsorshipBiddingEngine.signContract(
        session: session,
        team: team,
        offer: wheelsOffer,
      );
      s = EquipmentSponsorshipBiddingEngine.signContract(
        session: s,
        team: team,
        offer: groupsetOffer,
      );
      s = EquipmentSponsorshipBiddingEngine.signContract(
        session: s,
        team: team,
        offer: apparelOffer,
      );
      s = EquipmentSponsorshipBiddingEngine.signContract(
        session: s,
        team: team,
        offer: nutritionOffer,
      );

      expect(s.signedContracts.length, 4);
      expect(s.currentPortfolio.wheelsContract?.brandName, wheelsOffer.brandName);
      expect(s.currentPortfolio.groupsetContract?.brandName, groupsetOffer.brandName);
      expect(s.currentPortfolio.apparelContract?.brandName, apparelOffer.brandName);
      expect(s.currentPortfolio.nutritionContract?.brandName, nutritionOffer.brandName);

      // Sprawdzenie sumarycznego rocznego wkładu gotówkowego
      final totalCash = s.currentPortfolio.totalAnnualCashContributionEur;
      expect(totalCash, greaterThan(team.bikeDeal.annualCashContributionEur));
    });

    test('Próba podpisania kół przy restrykcji Specialized rzuca ArgumentError', () {
      const specializedDeal = BikeManufacturerDeal(
        manufacturerId: 'specialized',
        manufacturerName: 'Specialized S-Works',
        prestigeLevel: 5,
        annualCashContributionEur: 2500000,
        freeBikesQuota: 85,
        researchAndDevelopmentLevel: 95,
        suppliedFrameIds: [],
        suppliedWheelsetIds: ['roval_wheels'],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 10,
      );

      final specSession = EquipmentSponsorshipBiddingEngine.openEndOfSeasonTender(
        team: team.copyWith(bikeDeal: specializedDeal),
        seasonYear: 2026,
      );

      final wheelOffer = session.availableOffersByCategory[EquipmentSponsorCategory.wheels]!.first;

      expect(
        () => EquipmentSponsorshipBiddingEngine.signContract(
          session: specSession,
          team: team,
          offer: wheelOffer,
        ),
        throwsArgumentError,
      );
    });

    test('concludeTenderAndApplyPortfolio wypłaca dopłaty gotówkowe do budżetu zespołu', () {
      final apparelOffer = session.availableOffersByCategory[EquipmentSponsorCategory.apparel]!.first;
      final nutritionOffer = session.availableOffersByCategory[EquipmentSponsorCategory.nutrition]!.first;

      var s = EquipmentSponsorshipBiddingEngine.signContract(
        session: session,
        team: team,
        offer: apparelOffer,
      );
      s = EquipmentSponsorshipBiddingEngine.signContract(
        session: s,
        team: team,
        offer: nutritionOffer,
      );

      final result = EquipmentSponsorshipBiddingEngine.concludeTenderAndApplyPortfolio(
        session: s,
        team: team,
      );

      final expectedCash = team.cashBalanceEur + result.portfolio.totalAnnualCashContributionEur;
      expect(result.updatedTeam.cashBalanceEur, expectedCash);
      expect(result.portfolio.apparelContract, isNotNull);
      expect(result.portfolio.nutritionContract, isNotNull);
    });
  });

  group('EquipmentSponsorshipBiddingEngine - 5. Realny zysk w watach (Aero Skinsuits, Helmets, Drivetrain)', () {
    test('calculateRaceWattImpact w jeździe na czas (ITT) wylicza realną przewagę rzędu 35-50W', () {
      const portfolio = TeamTechnicalPortfolio(
        frameDeal: BikeManufacturerDeal(
          manufacturerId: 'cervelo',
          manufacturerName: 'Cervélo Cycles',
          prestigeLevel: 5,
          annualCashContributionEur: 2000000,
          freeBikesQuota: 80,
          researchAndDevelopmentLevel: 90,
          suppliedFrameIds: [],
          suppliedWheelsetIds: [],
          contractYearsLeft: 2,
          minimumUciRankingRequired: 15,
        ),
        apparelContract: ActiveTechnicalContract(
          id: 'app_bioracer',
          category: EquipmentSponsorCategory.apparel,
          brandId: 'brand_bioracer',
          brandName: 'Bioracer Speedwear Works',
          annualCashContributionEur: 350000,
          contractYearsTotal: 2,
          contractYearsRemaining: 2,
          signedSeasonYear: 2026,
          performanceBonuses: {},
          perksJson: {
            'ttSkinsuitWattSavings': 23.5,
            'roadAeroJerseyWattSavings': 6.8,
            'badWeatherThermalProtectionScore': 90,
            'antiChafingComfortScore': 94,
            'customWindTunnelFittingsCount': 5,
          },
        ),
        helmetsEyewearContract: ActiveTechnicalContract(
          id: 'helmets_kask',
          category: EquipmentSponsorCategory.helmetsAndEyewear,
          brandId: 'brand_kask',
          brandName: 'KASK & KOO Eyewear',
          annualCashContributionEur: 180000,
          contractYearsTotal: 2,
          contractYearsRemaining: 2,
          signedSeasonYear: 2026,
          performanceBonuses: {},
          perksJson: {
            'ttHelmetAeroWattSavings': 12.5,
            'roadHelmetVentilationEfficiencyPct': 94.0,
            'eyewearOpticsContrastRating': 92,
            'crashProtectionSafetyFactor': 95,
            'annualFreeHelmetsCount': 120,
          },
        ),
        wheelsContract: ActiveTechnicalContract(
          id: 'wheels_princeton',
          category: EquipmentSponsorCategory.wheels,
          brandId: 'brand_princeton',
          brandName: 'Princeton CarbonWorks',
          annualCashContributionEur: 240000,
          contractYearsTotal: 2,
          contractYearsRemaining: 2,
          signedSeasonYear: 2026,
          performanceBonuses: {},
          perksJson: {
            'aeroCdAReduction': 0.015,
            'rollingResistanceWattsSaved': 4.2,
            'crosswindStabilityScore': 98,
            'climbingWeightSavingGrams': 350,
            'annualFreeWheelsetsPool': 90,
            'includesTtDiscWheel': true,
          },
        ),
        groupsetContract: ActiveTechnicalContract(
          id: 'groupset_shimano',
          category: EquipmentSponsorCategory.groupsetAndPower,
          brandId: 'brand_shimano',
          brandName: 'Shimano Dura-Ace Di2',
          annualCashContributionEur: 450000,
          contractYearsTotal: 3,
          contractYearsRemaining: 3,
          signedSeasonYear: 2026,
          performanceBonuses: {},
          perksJson: {
            'drivetrainEfficiency': 0.987,
            'shiftLatencyMs': 140,
            'chainDropRiskReductionPct': 95.0,
            'powerMeterAccuracyPct': 1.0,
            'dualSidedTorqueTelemetry': true,
            'annualFreeGroupsetsPool': 65,
          },
        ),
      );

      final report = EquipmentSponsorshipBiddingEngine.calculateRaceWattImpact(
        portfolio: portfolio,
        isTimeTrial: true,
        raceSpeedKmh: 50.0,
      );

      expect(report.totalWattsSaved, greaterThanOrEqualTo(45.0));
      expect(report.componentBreakdown['Kombinezon czasowy Aero TT'], 23.5);
      expect(report.componentBreakdown['Kask czasowy Aero TT'], 12.5);
      expect(report.componentBreakdown['Koła aero & Dysk TT (łożyska)'], greaterThan(20.0));
      expect(report.cdaDeltaSquareMeters, greaterThan(0.035));
      expect(report.engineeringSummary, contains('przewagi'));
    });

    test('calculateRaceWattImpact w wyścigu szosowym uwzględnia chłodzenie w upale', () {
      const portfolio = TeamTechnicalPortfolio(
        frameDeal: BikeManufacturerDeal(
          manufacturerId: 'cervelo',
          manufacturerName: 'Cervélo Cycles',
          prestigeLevel: 5,
          annualCashContributionEur: 2000000,
          freeBikesQuota: 80,
          researchAndDevelopmentLevel: 90,
          suppliedFrameIds: [],
          suppliedWheelsetIds: [],
          contractYearsLeft: 2,
          minimumUciRankingRequired: 15,
        ),
        helmetsEyewearContract: ActiveTechnicalContract(
          id: 'helmets_kask',
          category: EquipmentSponsorCategory.helmetsAndEyewear,
          brandId: 'brand_kask',
          brandName: 'KASK & KOO Eyewear',
          annualCashContributionEur: 180000,
          contractYearsTotal: 2,
          contractYearsRemaining: 2,
          signedSeasonYear: 2026,
          performanceBonuses: {},
          perksJson: {
            'ttHelmetAeroWattSavings': 12.5,
            'roadHelmetVentilationEfficiencyPct': 94.0,
            'eyewearOpticsContrastRating': 92,
            'crashProtectionSafetyFactor': 95,
            'annualFreeHelmetsCount': 120,
          },
        ),
      );

      final reportInHeat = EquipmentSponsorshipBiddingEngine.calculateRaceWattImpact(
        portfolio: portfolio,
        isTimeTrial: false,
        ambientTempC: 34.0,
      );

      expect(reportInHeat.componentBreakdown.containsKey('Wentylacja kasku (ochrona przed przegrzaniem)'), isTrue);
      expect(reportInHeat.totalWattsSaved, greaterThan(5.0));
    });
  });

  group('EquipmentSponsorshipBiddingEngine - 6. Żywienie sportowe i żele 120g/h (Hydrogel Technology)', () {
    test('Żywienie Maurten 120g/h zabezpiecza przed głodem (bonk < 1%) i problemami żołądkowymi (0.2%)', () {
      const portfolio = TeamTechnicalPortfolio(
        frameDeal: BikeManufacturerDeal(
          manufacturerId: 'cervelo',
          manufacturerName: 'Cervélo Cycles',
          prestigeLevel: 5,
          annualCashContributionEur: 2000000,
          freeBikesQuota: 80,
          researchAndDevelopmentLevel: 90,
          suppliedFrameIds: [],
          suppliedWheelsetIds: [],
          contractYearsLeft: 2,
          minimumUciRankingRequired: 15,
        ),
        nutritionContract: ActiveTechnicalContract(
          id: 'nutrition_maurten',
          category: EquipmentSponsorCategory.nutrition,
          brandId: 'brand_maurten',
          brandName: 'Maurten Hydrogel Lab',
          annualCashContributionEur: 260000,
          contractYearsTotal: 2,
          contractYearsRemaining: 2,
          signedSeasonYear: 2026,
          performanceBonuses: {},
          perksJson: {
            'maxCarbIntakeGramsPerHour': 120,
            'giDistressRiskPct': 0.2,
            'electrolytePlasmaBufferScore': 96,
            'glycogenRecoverySpeedupPct': 28.0,
            'annualNutritionUnitsProvided': 20000,
          },
        ),
      );

      final report = EquipmentSponsorshipBiddingEngine.evaluateInRaceNutrition(
        portfolio: portfolio,
        stageDistanceKm: 215,
        raceIntensityPct: 0.88,
        ambientTempC: 28.0,
      );

      expect(report.targetCarbIntakePerHourGrams, 120);
      expect(report.giDistressRiskPercent, lessThanOrEqualTo(0.5));
      expect(report.bonkRiskPercent, lessThan(1.0));
      expect(report.staminaRetentionPercent, greaterThanOrEqualTo(98.0));
      expect(report.nutritionistAssessment, contains('Hydrogel'));
    });

    test('Brak sponsora żywieniowego (podstawowe 60g/h) zwiększa ryzyko głodu i spadku mocy', () {
      const portfolio = TeamTechnicalPortfolio(
        frameDeal: BikeManufacturerDeal(
          manufacturerId: 'cervelo',
          manufacturerName: 'Cervélo Cycles',
          prestigeLevel: 5,
          annualCashContributionEur: 2000000,
          freeBikesQuota: 80,
          researchAndDevelopmentLevel: 90,
          suppliedFrameIds: [],
          suppliedWheelsetIds: [],
          contractYearsLeft: 2,
          minimumUciRankingRequired: 15,
        ),
      );

      final report = EquipmentSponsorshipBiddingEngine.evaluateInRaceNutrition(
        portfolio: portfolio,
        stageDistanceKm: 215,
        raceIntensityPct: 0.88,
        ambientTempC: 28.0,
      );

      expect(report.targetCarbIntakePerHourGrams, 60);
      expect(report.bonkRiskPercent, greaterThan(15.0));
      expect(report.staminaRetentionPercent, lessThan(90.0));
      expect(report.giDistressRiskPercent, greaterThan(10.0));
    });
  });

  group('EquipmentSponsorshipBiddingEngine - 7. Serializacja i deserializacja JSON', () {
    test('TeamTechnicalPortfolio serializuje i deserializuje się bezstratnie', () {
      const portfolio = TeamTechnicalPortfolio(
        frameDeal: BikeManufacturerDeal(
          manufacturerId: 'cervelo',
          manufacturerName: 'Cervélo Cycles',
          prestigeLevel: 5,
          annualCashContributionEur: 2000000,
          freeBikesQuota: 80,
          researchAndDevelopmentLevel: 90,
          suppliedFrameIds: ['cervelo_s5'],
          suppliedWheelsetIds: [],
          contractYearsLeft: 2,
          minimumUciRankingRequired: 15,
        ),
        apparelContract: ActiveTechnicalContract(
          id: 'app_bioracer',
          category: EquipmentSponsorCategory.apparel,
          brandId: 'brand_bioracer',
          brandName: 'Bioracer Speedwear Works',
          annualCashContributionEur: 350000,
          contractYearsTotal: 2,
          contractYearsRemaining: 2,
          signedSeasonYear: 2026,
          performanceBonuses: {'monument_win': 30000},
          perksJson: {'ttSkinsuitWattSavings': 23.5},
        ),
      );

      final json = portfolio.toJson();
      final restored = TeamTechnicalPortfolio.fromJson(json);

      expect(restored.frameDeal.manufacturerName, 'Cervélo Cycles');
      expect(restored.apparelContract?.brandName, 'Bioracer Speedwear Works');
      expect(restored.apparelContract?.annualCashContributionEur, 350000);
      expect(restored.totalAnnualCashContributionEur, 2350000);
    });

    test('EquipmentTenderSession serializuje i deserializuje się bezstratnie', () {
      const deal = BikeManufacturerDeal(
        manufacturerId: 'colnago',
        manufacturerName: 'Colnago',
        prestigeLevel: 5,
        annualCashContributionEur: 2200000,
        freeBikesQuota: 80,
        researchAndDevelopmentLevel: 92,
        suppliedFrameIds: [],
        suppliedWheelsetIds: [],
        contractYearsLeft: 2,
        minimumUciRankingRequired: 10,
      );

      const team = CyclingTeam(
        id: 'team_colnago',
        name: 'UAE Emirates Style',
        division: TeamDivision.worldTour,
        countryIso: 'UAE',
        primaryJerseyColorHex: '#FFFFFF',
        secondaryJerseyColorHex: '#000000',
        accentJerseyColorHex: '#FF0000',
        cashBalanceEur: 5000000,
        monthlyBurnRateEur: 600000,
        uciPointsSeason: 6000,
        rosterRiderIds: [],
        staff: TeamStaff(
          trainersLevel: 85,
          sportsDirectorsLevel: 85,
          doctorsLevel: 85,
          mechanicsLevel: 85,
          scoutsLevel: 85,
        ),
        bikeDeal: deal,
        sponsors: [],
        inventoryBikes: [],
      );

      final session = EquipmentSponsorshipBiddingEngine.openEndOfSeasonTender(
        team: team,
        seasonYear: 2026,
      );

      final json = session.toJson();
      final restored = EquipmentTenderSession.fromJson(json);

      expect(restored.seasonYear, 2026);
      expect(restored.teamId, 'team_colnago');
      expect(restored.negotiationRoundsRemaining, 3);
      expect(restored.availableOffersByCategory.length, 5);
      expect(restored.availableOffersByCategory[EquipmentSponsorCategory.wheels]!.length, greaterThanOrEqualTo(4));
    });
  });
}
