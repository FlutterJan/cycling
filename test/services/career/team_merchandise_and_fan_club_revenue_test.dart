// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/team_merchandise_and_fan_club_revenue.dart';

void main() {
  group('TeamMerchandiseAndFanClubRevenueService', () {
    const service = TeamMerchandiseAndFanClubRevenueService();

    test('createDefaultCatalog creates 7 products with positive margins', () {
      final catalog = service.createDefaultCatalog(
        teamName: 'Test Pro Cycling',
        teamPrestige: 80.0,
      );
      expect(catalog, hasLength(7));
      for (final p in catalog) {
        expect(p.retailPriceEur, greaterThan(p.unitProductionCostEur));
        expect(p.marginPercent, greaterThan(30.0));
        expect(p.stockUnits, greaterThan(0));
      }
    });

    test('calculateRestockCost applies volume discounts accurately', () {
      const product = MerchandiseProductSpec(
        id: 'p1',
        name: 'Jersey',
        category: MerchandiseCategory.proReplicaJersey,
        qualityTier: MerchandiseQualityTier.proAeroReplica,
        retailPriceEur: 100.0,
        unitProductionCostEur: 30.0,
        stockUnits: 100,
      );

      expect(service.calculateRestockCost(product: product, quantity: 0), 0.0);
      expect(
        service.calculateRestockCost(product: product, quantity: 100),
        3000.0,
      );
      expect(
        service.calculateRestockCost(product: product, quantity: 500),
        closeTo(13650.0, 0.01),
      );
      expect(
        service.calculateRestockCost(product: product, quantity: 2000),
        closeTo(50400.0, 0.01),
      );
    });

    test('simulateMonthlyCycle caps sales at stockUnits and updates fan club', () {
      final catalog = [
        const MerchandiseProductSpec(
          id: 'p_low_stock',
          name: 'Limited Jersey',
          category: MerchandiseCategory.proReplicaJersey,
          qualityTier: MerchandiseQualityTier.proAeroReplica,
          retailPriceEur: 95.0,
          unitProductionCostEur: 35.0,
          stockUnits: 10,
          unitsSoldSeason: 0,
        ),
      ];
      const fanClub = FanClubMembershipSnapshot(
        totalFanBase: 200000,
        paidClubMembers: 15000,
        annualMembershipFeeEur: 48.0,
        fanEngagementIndex: 82.0,
        regionalSupporters: {'PL': 100000},
      );

      final outcome = service.simulateMonthlyCycle(
        monthIndex: 7,
        catalog: catalog,
        fanClub: fanClub,
        teamPrestige: 85.0,
        recentWinHype: 1.2,
      );

      expect(outcome.updatedCatalog.first.stockUnits, 0);
      expect(outcome.updatedCatalog.first.unitsSoldSeason, 10);
      expect(outcome.ledgerEntry.unitsSold, 10);
      expect(outcome.ledgerEntry.storeRevenueEur, 950.0);
      expect(outcome.ledgerEntry.fanClubRevenueEur, closeTo(60000.0, 0.01));
      expect(outcome.updatedFanClub.totalFanBase, greaterThan(200000));
    });

    test('evaluateAndExecuteFanZone computes attendance, revenue and new fans', () {
      const fanClub = FanClubMembershipSnapshot(
        totalFanBase: 120000,
        paidClubMembers: 9000,
        annualMembershipFeeEur: 49.0,
        fanEngagementIndex: 75.0,
        regionalSupporters: {'FR': 25000},
      );
      const zone = FanZoneActivation(
        id: 'fz1',
        raceName: 'Tour de France',
        stageOrLocation: 'Col du Galibier',
        countryCode: 'FR',
        eventTier: FanZoneEventTier.summitFanPark,
        setupCostEur: 26000.0,
        expectedAttendance: 8800,
        merchandiseBoostMultiplier: 1.45,
      );

      final executed = service.evaluateAndExecuteFanZone(
        activation: zone,
        fanClub: fanClub,
        teamPrestige: 82.0,
        hadStagePodiumOrWin: true,
      );

      expect(executed.executed, isTrue);
      expect(executed.actualAttendance, greaterThan(8800));
      expect(executed.totalRevenueEur, greaterThan(executed.setupCostEur));
      expect(executed.newFansGained, greaterThan(0));
      expect(executed.satisfactionScore, greaterThan(70.0));
    });

    test('JSON serialization round-trip preserves product, fanClub and fanZone', () {
      const product = MerchandiseProductSpec(
        id: 'p_rt',
        name: 'Aero Jersey',
        category: MerchandiseCategory.specialEditionJersey,
        qualityTier: MerchandiseQualityTier.collectorAuthentic,
        retailPriceEur: 145.0,
        unitProductionCostEur: 50.0,
        stockUnits: 320,
        unitsSoldSeason: 180,
        featuredRiderId: 'r1',
        featuredRiderName: 'K. Majewski',
        hypeMultiplier: 1.5,
      );
      final parsedProduct = MerchandiseProductSpec.fromJson(product.toJson());
      expect(parsedProduct.id, product.id);
      expect(parsedProduct.category, product.category);
      expect(parsedProduct.qualityTier, product.qualityTier);
      expect(parsedProduct.retailPriceEur, product.retailPriceEur);

      const fanClub = FanClubMembershipSnapshot(
        totalFanBase: 55000,
        paidClubMembers: 4100,
        annualMembershipFeeEur: 45.0,
        fanEngagementIndex: 72.0,
        regionalSupporters: {'PL': 30000, 'BE': 25000},
      );
      final parsedClub = FanClubMembershipSnapshot.fromJson(fanClub.toJson());
      expect(parsedClub.totalFanBase, 55000);
      expect(parsedClub.regionalSupporters['PL'], 30000);
    });
  });

  group('TeamMerchandiseAndFanClubNotifier', () {
    test('notifier actions update state cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(teamMerchandiseAndFanClubProvider.notifier);
      final initialState = container.read(teamMerchandiseAndFanClubProvider);
      final firstId = initialState.catalog.first.id;
      final initialStock = initialState.catalog.first.stockUnits;

      notifier.restockProduct(firstId, 250);
      expect(
        container
            .read(teamMerchandiseAndFanClubProvider)
            .catalog
            .first
            .stockUnits,
        initialStock + 250,
      );

      notifier.updateProductPrice(firstId, 1.0);
      final clampedPrice = container
          .read(teamMerchandiseAndFanClubProvider)
          .catalog
          .first
          .retailPriceEur;
      expect(
        clampedPrice,
        greaterThan(initialState.catalog.first.unitProductionCostEur),
      );

      notifier.scheduleFanZone(
        raceName: 'Giro d\'Italia',
        location: 'Passo dello Stelvio',
        countryCode: 'IT',
        tier: FanZoneEventTier.summitFanPark,
      );
      final afterSchedule = container.read(teamMerchandiseAndFanClubProvider);
      expect(afterSchedule.fanZones.length, initialState.fanZones.length + 1);

      final scheduledId = afterSchedule.fanZones.first.id;
      notifier.executeFanZone(scheduledId);
      expect(
        container
            .read(teamMerchandiseAndFanClubProvider)
            .fanZones
            .first
            .executed,
        isTrue,
      );

      notifier.runMonthlyStoreCycle();
      expect(
        container
            .read(teamMerchandiseAndFanClubProvider)
            .monthlyLedger
            .length,
        initialState.monthlyLedger.length + 1,
      );
    });
  });

  group('TeamMerchandiseAndFanClubPanel responsive UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TeamMerchandiseAndFanClubPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders without overflow at 390x844 (mobile)', (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Sklep Klubowy, Repliki & Fan Zones'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1024x768 (tablet)', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Sklep Klubowy, Repliki & Fan Zones'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1600x900 (desktop) and switches tabs',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Sklep Klubowy, Repliki & Fan Zones'), findsOneWidget);

      await tester.tap(find.text('Strefy Kibica (Fan Zones)').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Zaplanuj Nową Strefę Kibica'), findsOneWidget);

      await tester.tap(find.text('Fanklub & Księga').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Księga Przychodów Miesięcznych'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
