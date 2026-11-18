import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/race/global_exotic_tours_expansion_model.dart';
import 'package:pro_peloton_manager/services/career/global_sponsor_market_expansion_service.dart';

void main() {
  group('GlobalSponsorMarketExpansionService', () {
    const service = GlobalSponsorMarketExpansionService();

    test('builds all 3 emerging market regions with linked exotic tours', () {
      final profiles = service.buildDefaultRegionProfiles();

      expect(profiles.keys, containsAll(EmergingSponsorRegion.values));
      expect(
        profiles[EmergingSponsorRegion.asia]!.linkedExoticTours,
        contains(ExoticTourId.tourDeLangkawi),
      );
      expect(
        profiles[EmergingSponsorRegion.africa]!.linkedExoticTours,
        contains(ExoticTourId.tourDuRwanda),
      );
      expect(
        profiles[EmergingSponsorRegion.middleEast]!.linkedExoticTours,
        containsAll([ExoticTourId.tourOfOman, ExoticTourId.alUlaTour]),
      );
    });

    test('generates offers across Asia, Africa, and Middle East', () {
      final profiles = service.buildDefaultRegionProfiles();
      final offers = service.generateMarketOffers(
        teamPrestige: 62.0,
        regionProfiles: profiles,
      );

      expect(offers.length, greaterThanOrEqualTo(8));
      expect(
        offers.any((o) => o.region == EmergingSponsorRegion.asia),
        isTrue,
      );
      expect(
        offers.any((o) => o.region == EmergingSponsorRegion.africa),
        isTrue,
      );
      expect(
        offers.any((o) => o.region == EmergingSponsorRegion.middleEast),
        isTrue,
      );
    });

    test('evaluates eligibility including scouting and local rider rules', () {
      final profiles = service.buildDefaultRegionProfiles();
      final offers = service.generateMarketOffers(
        teamPrestige: 70.0,
        regionProfiles: profiles,
      );

      final mtnOffer = offers.firstWhere(
        (o) => o.id == 'emg_africa_mtn_qhubeka',
      );
      final africaReport = service.evaluateOfferEligibility(
        offer: mtnOffer,
        teamPrestige: 70.0,
        regionProfile: profiles[EmergingSponsorRegion.africa]!,
        activeContractsCount: 0,
        alreadySignedOffer: false,
      );
      expect(africaReport.isEligible, isFalse);
      expect(
        africaReport.unmetReasons.any((r) => r.contains('kolarz')),
        isTrue,
      );

      final omanOffer = offers.firstWhere(
        (o) => o.id == 'emg_me_oman_energy',
      );
      final middleEastUnscouted = service.evaluateOfferEligibility(
        offer: omanOffer,
        teamPrestige: 70.0,
        regionProfile: profiles[EmergingSponsorRegion.middleEast]!,
        activeContractsCount: 0,
        alreadySignedOffer: false,
      );
      expect(middleEastUnscouted.isEligible, isFalse);
      expect(
        middleEastUnscouted.unmetReasons.any((r) => r.contains('rozpoznania')),
        isTrue,
      );
    });

    test('negotiateOffer handles acceptance and counter-offer deterministically',
        () {
      final profiles = service.buildDefaultRegionProfiles();
      final offers = service.generateMarketOffers(
        teamPrestige: 65.0,
        regionProfiles: profiles,
      );
      final rakuten = offers.firstWhere(
        (o) => o.id == 'emg_asia_rakuten_fintech',
      );

      final accepted = service.negotiateOffer(
        offer: rakuten,
        requestedBudgetBoostPercent: 10.0,
        teamPrestige: 65.0,
        regionProfile: profiles[EmergingSponsorRegion.asia]!,
        activeContractsCount: 0,
        alreadySignedOffer: false,
        currentSeasonDay: 20,
        rng: _FixedRandom(0.10),
      );
      expect(accepted.status, SponsorNegotiationOutcomeStatus.accepted);
      expect(accepted.signedContract, isNotNull);
      expect(
        accepted.proposedAnnualBudgetEur,
        greaterThan(rakuten.annualBudgetEur),
      );

      final counter = service.negotiateOffer(
        offer: rakuten,
        requestedBudgetBoostPercent: 25.0,
        teamPrestige: 65.0,
        regionProfile: profiles[EmergingSponsorRegion.asia]!,
        activeContractsCount: 0,
        alreadySignedOffer: false,
        currentSeasonDay: 20,
        rng: _FixedRandom(0.75),
      );
      expect(counter.status, SponsorNegotiationOutcomeStatus.counterOffer);
      expect(counter.signedContract, isNull);
    });

    test('notifier scouts Middle East, signs contract, and awards exotic bonus',
        () {
      final notifier = GlobalSponsorMarketNotifier(
        initialState: GlobalSponsorMarketState.initial(
          teamPrestige: 65.0,
          teamAvailableBudgetEur: 500000,
        ),
      );

      expect(notifier.scoutRegion(EmergingSponsorRegion.middleEast), isTrue);
      expect(
        notifier.state.regionProfiles[EmergingSponsorRegion.middleEast]!
            .isScouted,
        isTrue,
      );

      expect(notifier.signOfferDirectly('emg_me_oman_energy'), isTrue);
      expect(notifier.state.activeContracts.length, 1);

      final bonus = notifier.recordExoticTourPerformance(
        tourId: ExoticTourId.tourOfOman,
        stageWins: 2,
        bestGcRank: 2,
      );
      expect(bonus, greaterThan(0));
      expect(notifier.state.summary.totalEarnedBonusesEur, greaterThan(0));
    });

    test('activation mission advances days and boosts regional penetration', () {
      final notifier = GlobalSponsorMarketNotifier(
        initialState: GlobalSponsorMarketState.initial(
          teamPrestige: 60.0,
          teamAvailableBudgetEur: 400000,
        ),
      );

      final initialPenetration =
          notifier.state.regionProfiles[EmergingSponsorRegion.asia]!
              .fanbasePenetration;

      expect(notifier.startActivationMission('act_asia_kl_summit'), isTrue);
      notifier.advanceDays(7);

      final mission = notifier.state.activationMissions
          .firstWhere((m) => m.id == 'act_asia_kl_summit');
      expect(mission.isCompleted, isTrue);
      expect(
        notifier.state.regionProfiles[EmergingSponsorRegion.asia]!
            .fanbasePenetration,
        greaterThan(initialPenetration),
      );
    });

    test('GlobalSponsorMarketState JSON round-trip preserves state', () {
      final initial = GlobalSponsorMarketState.initial(teamPrestige: 64.0);
      final encoded = initial.toJson();
      final decoded = GlobalSponsorMarketState.fromJson(encoded);

      expect(decoded.teamPrestige, initial.teamPrestige);
      expect(decoded.selectedRegion, initial.selectedRegion);
      expect(decoded.regionProfiles.length, initial.regionProfiles.length);
      expect(decoded.availableOffers.length, initial.availableOffers.length);
      expect(
        decoded.activationMissions.length,
        initial.activationMissions.length,
      );
    });
  });

  group('GlobalSponsorMarketExpansionPanel UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GlobalSponsorMarketExpansionPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly without overflow at 390x844 (mobile)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(
        find.text('Ekspansja Sponsorów: Rynki Wschodzące'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1024x768 (tablet)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Azja & Pacyfik'), findsOneWidget);
      expect(find.text('Afryka Wschodnia & Płd.'), findsOneWidget);
      expect(find.text('Bliski Wschód & Zatoka'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1600x900 (desktop)',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Aktywni Sponsorzy Wschodzący'), findsOneWidget);

      await tester.tap(find.text('Podpisz teraz').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('1/4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FixedRandom implements math.Random {
  final double _value;
  _FixedRandom(this._value);

  @override
  bool nextBool() => _value >= 0.5;

  @override
  double nextDouble() => _value;

  @override
  int nextInt(int max) => (_value * max).floor().clamp(0, max - 1);
}
