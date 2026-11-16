// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/sponsor_bonus_negotiation_events.dart';

CyclingTeam _buildTestTeam({
  int cashBalanceEur = 1200000,
  List<SponsorContract>? sponsors,
}) {
  return CyclingTeam(
    id: 'team_orlen_pro',
    name: 'Orlen Pro Cycling',
    division: TeamDivision.worldTour,
    countryIso: 'PL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#181B22',
    accentJerseyColorHex: '#D4AF37',
    cashBalanceEur: cashBalanceEur,
    monthlyBurnRateEur: 420000,
    uciPointsSeason: 4850,
    rosterRiderIds: const ['r1', 'r2'],
    staff: const TeamStaff(
      trainersLevel: 82,
      sportsDirectorsLevel: 85,
      doctorsLevel: 80,
      mechanicsLevel: 84,
      scoutsLevel: 78,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'bike_1',
      manufacturerName: 'AeroVeloce',
      prestigeLevel: 5,
      annualCashContributionEur: 1500000,
      freeBikesQuota: 80,
      researchAndDevelopmentLevel: 85,
      suppliedFrameIds: ['f1'],
      suppliedWheelsetIds: ['w1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 10,
    ),
    sponsors: sponsors ??
        const [
          SponsorContract(
            id: 'sp_title_1',
            companyName: 'Apex Energy Corp',
            industry: SponsorIndustry.energy,
            sponsorTier: SponsorTier.titlePrimary,
            annualBudgetEur: 12000000,
            contractDurationYears: 3,
            sponsorSatisfaction: 86.0,
            objectives: [],
          ),
        ],
    inventoryBikes: const [],
  );
}

void main() {
  group('SponsorBonusNegotiationEvents', () {
    test('detects monument victory and 3+ Grand Tour stage wins', () {
      final monumentCtx = SponsorBonusTriggerContext(
        raceId: 'paris_roubaix_2026',
        raceName: 'Paris-Roubaix',
        raceCategory: RaceCategory.monument,
        eventDate: DateTime(2026, 4, 12),
        isMonumentWin: true,
        heroRiderName: 'Michał Kwiatkowski',
      );
      expect(
        SponsorBonusNegotiationEvents.detectTrigger(monumentCtx),
        SpectacularSuccessTrigger.monumentVictory,
      );

      final gtStagesCtx = SponsorBonusTriggerContext(
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        raceCategory: RaceCategory.grandTour,
        eventDate: DateTime(2026, 7, 15),
        grandTourStageWinsInRace: 3,
        heroRiderName: 'Jasper Sprint',
      );
      expect(
        SponsorBonusNegotiationEvents.detectTrigger(gtStagesCtx),
        SpectacularSuccessTrigger.grandTourThreeStageWins,
      );

      final ordinaryCtx = SponsorBonusTriggerContext(
        raceId: 'kuurne_2026',
        raceName: 'Kuurne-Bruxelles-Kuurne',
        raceCategory: RaceCategory.proSeries,
        eventDate: DateTime(2026, 3, 1),
        isMonumentWin: true,
      );
      expect(SponsorBonusNegotiationEvents.detectTrigger(ordinaryCtx), isNull);
    });

    test('creates offer within 250k-1M EUR, prevents duplicates, and serializes cleanly', () {
      final team = _buildTestTeam();
      final ctx = SponsorBonusTriggerContext(
        raceId: 'ronde_2026',
        raceName: 'Ronde van Vlaanderen',
        raceCategory: RaceCategory.monument,
        eventDate: DateTime(2026, 4, 5),
        isMonumentWin: true,
        heroRiderName: 'Kacper Nowak',
        tvExposureMinutes: 95,
      );

      final offer = SponsorBonusNegotiationEvents.evaluateAndCreateOffer(
        team: team,
        context: ctx,
        random: math.Random(42),
      );

      expect(offer, isNotNull);
      expect(
        offer!.offeredAmountEur,
        inInclusiveRange(
          SponsorBonusNegotiationEvents.minBonusEur,
          SponsorBonusNegotiationEvents.maxBonusEur,
        ),
      );
      expect(offer.sponsorCompanyName, 'Apex Energy Corp');
      expect(offer.status, SponsorBonusOfferStatus.pendingDecision);

      // Duplikat dla tego samego klucza nie powinien tworzyć drugiej oferty
      final duplicate = SponsorBonusNegotiationEvents.evaluateAndCreateOffer(
        team: team,
        context: ctx,
        alreadyTriggeredKeys: {offer.triggerKey},
        random: math.Random(42),
      );
      expect(duplicate, isNull);

      // Brak sponsorów zwraca null bez wyjątku
      final noSponsorTeam = _buildTestTeam(sponsors: const []);
      expect(
        SponsorBonusNegotiationEvents.evaluateAndCreateOffer(
          team: noSponsorTeam,
          context: ctx,
        ),
        isNull,
      );

      // Serializacja JSON round-trip
      final restored = SponsorCeoBonusOffer.fromJson(offer.toJson());
      expect(restored.id, offer.id);
      expect(restored.offeredAmountEur, offer.offeredAmountEur);
      expect(restored.trigger, offer.trigger);
      expect(restored.recommendedPurpose, offer.recommendedPurpose);
    });

    test('handles counter-offer negotiation and budget allocation on accept', () {
      final team = _buildTestTeam(cashBalanceEur: 1000000);
      final ctx = SponsorBonusTriggerContext(
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        raceCategory: RaceCategory.grandTour,
        eventDate: DateTime(2026, 7, 18),
        grandTourStageWinsInRace: 3,
        heroRiderName: 'Jan Kowalski',
      );

      final offer = SponsorBonusNegotiationEvents.evaluateAndCreateOffer(
        team: team,
        context: ctx,
        random: math.Random(7),
      )!;

      final negotiated = SponsorBonusNegotiationEvents.submitCounterOffer(
        offer: offer,
        requestedAmountEur: offer.maxNegotiableAmountEur,
        preferredPurpose: BonusAllocationPurpose.windTunnelAndAeroRnD,
      );
      expect(negotiated.offeredAmountEur, greaterThanOrEqualTo(offer.offeredAmountEur));
      expect(negotiated.negotiationRoundsUsed, 1);
      expect(negotiated.status, SponsorBonusOfferStatus.counterOffered);

      final outcome = SponsorBonusNegotiationEvents.acceptOffer(
        team: team,
        offer: negotiated,
        purpose: BonusAllocationPurpose.splitTransferAndWindTunnel,
        decisionDate: DateTime(2026, 7, 19),
      );

      expect(outcome.cashInjectedEur, negotiated.offeredAmountEur);
      expect(
        outcome.transferBudgetAddedEur + outcome.windTunnelBudgetAddedEur,
        negotiated.offeredAmountEur,
      );
      expect(
        outcome.updatedTeam.cashBalanceEur,
        1000000 + negotiated.offeredAmountEur,
      );
      expect(outcome.offer.status, SponsorBonusOfferStatus.accepted);
      expect(outcome.inboxMessage.subject, contains('Apex Energy Corp'));

      expect(
        () => SponsorBonusNegotiationEvents.acceptOffer(
          team: outcome.updatedTeam,
          offer: outcome.offer,
          purpose: BonusAllocationPurpose.transferWarChest,
          decisionDate: DateTime(2026, 7, 20),
        ),
        throwsStateError,
      );
    });
  });

  group('SponsorBonusCallDialogWidget responsiveness', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size,
      SponsorCeoBonusOffer offer, {
      ValueChanged<BonusAllocationPurpose>? onAccepted,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.background,
          ),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SponsorBonusCallDialogWidget(
                  initialOffer: offer,
                  onAccepted: onAccepted,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly without overflow on 390x844, 1024x768 and 1600x900',
        (tester) async {
      final team = _buildTestTeam();
      final offer = SponsorBonusNegotiationEvents.evaluateAndCreateOffer(
        team: team,
        context: SponsorBonusTriggerContext(
          raceId: 'msr_2026',
          raceName: 'Milano-Sanremo',
          raceCategory: RaceCategory.monument,
          eventDate: DateTime(2026, 3, 21),
          isMonumentWin: true,
          heroRiderName: 'Marek Zieliński',
        ),
        random: math.Random(11),
      )!;

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpAtSize(tester, size, offer);
        expect(find.text('TELEFON OD PREZESA SPONSORA'), findsOneWidget);
        expect(find.text('Fundusz Transferowy'), findsOneWidget);
        expect(find.text('Tunel Aerodynamiczny i R&D'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('allows selecting wind tunnel purpose and accepting offer',
        (tester) async {
      final team = _buildTestTeam();
      final offer = SponsorBonusNegotiationEvents.evaluateAndCreateOffer(
        team: team,
        context: SponsorBonusTriggerContext(
          raceId: 'lbl_2026',
          raceName: 'Liège-Bastogne-Liège',
          raceCategory: RaceCategory.monument,
          eventDate: DateTime(2026, 4, 26),
          isMonumentWin: true,
          heroRiderName: 'Tadeusz Lider',
        ),
        random: math.Random(3),
      )!;

      BonusAllocationPurpose? acceptedPurpose;
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        offer,
        onAccepted: (purpose) => acceptedPurpose = purpose,
      );

      await tester.tap(find.text('Tunel Aerodynamiczny i R&D'));
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byIcon(Icons.check_circle_rounded));
      await tester.pump(const Duration(milliseconds: 250));

      expect(acceptedPurpose, BonusAllocationPurpose.windTunnelAndAeroRnD);
    });
  });
}
