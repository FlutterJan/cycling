import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/organizer/race_organizer_empire_model.dart';
import 'package:pro_peloton_manager/ui/widgets/host_city_bidding_auction_modal.dart';

RaceOrganizerEmpireModel _buildTestEmpire() {
  final base = RaceOrganizerEmpireModel.createStarterAsoPreset();
  return base.copyWith(
    pendingHostCityBids: [
      ...base.pendingHostCityBids,
      const HostCityBid(
        bidId: 'bid_bilbao_gd',
        raceId: 'race_grande_boucle_2uwt',
        cityName: 'Bilbao',
        countryCode: 'ES',
        regionName: 'Kraj Basków',
        role: HostBidRole.grandDepart,
        targetStageNumber: 1,
        bidFeeEur: 3200000,
        localInfrastructureGrantEur: 900000,
        hospitalityRevenuePotentialEur: 1200000,
        tourismExposureDemand: 95.0,
        terrainFitScore: 91.0,
        politicalStabilityIndex: 92.0,
        crowdTurnoutForecast: 380000,
        deadlineDay: 20,
      ),
      const HostCityBid(
        bidId: 'bid_copenhagen_gd',
        raceId: 'race_grande_boucle_2uwt',
        cityName: 'Copenhagen',
        countryCode: 'DK',
        regionName: 'Zelandia',
        role: HostBidRole.grandDepart,
        targetStageNumber: 1,
        bidFeeEur: 2950000,
        localInfrastructureGrantEur: 850000,
        hospitalityRevenuePotentialEur: 1100000,
        tourismExposureDemand: 90.0,
        terrainFitScore: 86.0,
        politicalStabilityIndex: 98.0,
        crowdTurnoutForecast: 310000,
        deadlineDay: 25,
      ),
    ],
  );
}

Future<void> _pumpModalAtSize(
  WidgetTester tester, {
  required Size size,
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
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  group('HostCityBiddingAuctionModal', () {
    testWidgets('renders cleanly without overflow at 390x844, 1024x768, 1600x900',
        (tester) async {
      final empire = _buildTestEmpire();

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await _pumpModalAtSize(tester, size: size, empire: empire);
        expect(find.textContaining('Przetargi Miast Gospodarzy'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('filters by Grand Départ and Meta Górska', (tester) async {
      final empire = _buildTestEmpire();
      await _pumpModalAtSize(
        tester,
        size: const Size(1280, 800),
        empire: empire,
      );

      // Initially all cities are visible
      expect(find.text('Bilbao'), findsWidgets);
      expect(find.text("Alpe d'Huez"), findsWidgets);

      // Filter to Grand Départ
      await tester.tap(find.text('Grand Départ').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bilbao'), findsWidgets);
      expect(find.text("Alpe d'Huez"), findsNothing);

      // Filter to Meta Górska
      await tester.tap(find.text('Meta Górska').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text("Alpe d'Huez"), findsWidgets);
      expect(find.text('Bilbao'), findsNothing);
    });

    testWidgets('awards Grand Départ bid, rejects rival slot, and updates ledger',
        (tester) async {
      HostCityBiddingAuctionResult? latestResult;
      final empire = _buildTestEmpire();

      await _pumpModalAtSize(
        tester,
        size: const Size(1280, 800),
        empire: empire,
        onEmpireChanged: (res) => latestResult = res,
      );

      // Select Bilbao
      await tester.tap(find.text('Bilbao').first);
      await tester.pump(const Duration(milliseconds: 300));

      // Award bid
      await tester.ensureVisible(find.text('Przyznaj Przetarg'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Przyznaj Przetarg'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(latestResult, isNotNull);
      expect(latestResult!.awardedBidIds, contains('bid_bilbao_gd'));

      final bilbao = latestResult!.updatedEmpire.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_bilbao_gd');
      final copenhagen = latestResult!.updatedEmpire.pendingHostCityBids
          .firstWhere((b) => b.bidId == 'bid_copenhagen_gd');

      expect(bilbao.status, HostBidStatus.awarded);
      expect(copenhagen.status, HostBidStatus.rejected);
      expect(
        latestResult!.updatedEmpire.budgetLedger.liquidCashEur,
        greaterThan(empire.budgetLedger.liquidCashEur),
      );
    });

    testWidgets('shortlist and counter-offer update bid state', (tester) async {
      HostCityBiddingAuctionResult? latestResult;
      final empire = _buildTestEmpire();

      await _pumpModalAtSize(
        tester,
        size: const Size(1280, 800),
        empire: empire,
        onEmpireChanged: (res) => latestResult = res,
      );

      await tester.ensureVisible(find.text('Krótka lista'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Krótka lista'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestResult, isNotNull);
      expect(
        latestResult!.updatedEmpire.pendingHostCityBids.first.status,
        HostBidStatus.shortlisted,
      );

      await tester.ensureVisible(find.textContaining('Wyślij Kontrofertę'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.textContaining('Wyślij Kontrofertę'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestResult!.counterOfferedBidIds, isNotEmpty);
    });

    testWidgets('read-only mode disables action buttons', (tester) async {
      HostCityBiddingAuctionResult? latestResult;
      final empire = _buildTestEmpire();

      await _pumpModalAtSize(
        tester,
        size: const Size(1280, 800),
        empire: empire,
        isReadOnly: true,
        onEmpireChanged: (res) => latestResult = res,
      );

      await tester.ensureVisible(find.text('Przyznaj Przetarg'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Przyznaj Przetarg'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(latestResult, isNull);
    });
  });
}
