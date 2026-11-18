import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/team_merchandise_and_fan_club_revenue.dart';
import 'package:pro_peloton_manager/ui/widgets/fan_base_and_merchandise_card.dart';

void main() {
  group('FanBaseAndMerchandiseAnalytics', () {
    test('formatFanCount formats small, thousands, and millions properly', () {
      expect(FanBaseAndMerchandiseAnalytics.formatFanCount(0), '0');
      expect(FanBaseAndMerchandiseAnalytics.formatFanCount(-10), '0');
      expect(FanBaseAndMerchandiseAnalytics.formatFanCount(850), '850');
      expect(FanBaseAndMerchandiseAnalytics.formatFanCount(14500), '14.5 tys.');
      expect(FanBaseAndMerchandiseAnalytics.formatFanCount(148500), '149 tys.');
      expect(FanBaseAndMerchandiseAnalytics.formatFanCount(1250000), '1.25 mln');
    });

    test('computeRegionalShares sorts descending and sums to 100%', () {
      final shares = FanBaseAndMerchandiseAnalytics.computeRegionalShares({
        'FR': 250,
        'PL': 500,
        'BE': 250,
      });

      expect(shares.length, 3);
      expect(shares.first.regionCode, 'PL');
      expect(shares.first.sharePercent, closeTo(50.0, 0.01));
      final totalPct = shares.fold<double>(0.0, (s, e) => s + e.sharePercent);
      expect(totalPct, closeTo(100.0, 0.01));
    });

    test('productMarginPercent handles zero retailPriceEur safely', () {
      const zeroPrice = MerchandiseProductSpec(
        id: 'p_zero',
        name: 'Zero',
        category: MerchandiseCategory.waterBottlesAndAccessories,
        qualityTier: MerchandiseQualityTier.budgetSupporter,
        retailPriceEur: 0.0,
        unitProductionCostEur: 5.0,
        stockUnits: 10,
      );
      expect(FanBaseAndMerchandiseAnalytics.productMarginPercent(zeroPrice), 0.0);

      const normal = MerchandiseProductSpec(
        id: 'p_norm',
        name: 'Normal',
        category: MerchandiseCategory.proReplicaJersey,
        qualityTier: MerchandiseQualityTier.proAeroReplica,
        retailPriceEur: 100.0,
        unitProductionCostEur: 35.0,
        stockUnits: 100,
      );
      expect(
        FanBaseAndMerchandiseAnalytics.productMarginPercent(normal),
        closeTo(65.0, 0.01),
      );
    });
  });

  group('FanBaseAndMerchandiseCard widget tests', () {
    Widget buildTestHost({
      required Size size,
      FanBaseAndMerchandiseCard? card,
    }) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: card ?? const FanBaseAndMerchandiseCard(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders default state and switches all 4 tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestHost(size: const Size(1024, 768)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Baza Kibiców & Gadżety Klubowe'), findsOneWidget);
      expect(find.text('Geografia Bazy Kibiców'), findsOneWidget);

      await tester.tap(find.text('Bestsellery Sklepu'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('+250 szt.'), findsWidgets);

      await tester.tap(find.text('Gwiazdy & Repliki'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Edycja Limitowana'), findsWidgets);

      await tester.tap(find.text('Strefy Kibica'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Realizuj Fan Zone'), findsWidgets);
    });

    testWidgets('invokes action callbacks and respects disabled state',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int simulateCalls = 0;
      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1600, 900),
          card: FanBaseAndMerchandiseCard(
            enabled: true,
            onSimulateMonth: () => simulateCalls++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Rozlicz miesiąc'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(simulateCalls, 1);

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1600, 900),
          card: FanBaseAndMerchandiseCard(
            enabled: false,
            onSimulateMonth: () => simulateCalls++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Rozlicz miesiąc'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(simulateCalls, 1);
    });

    testWidgets('handles empty lists gracefully without errors', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const emptyState = TeamMerchandiseAndFanClubState(
        seasonYear: 2026,
        currentMonth: 1,
        teamName: 'Empty Cycling Club',
        teamPrestige: 25.0,
        catalog: [],
        fanClub: FanClubMembershipSnapshot(
          totalFanBase: 0,
          paidClubMembers: 0,
          annualMembershipFeeEur: 29.0,
          fanEngagementIndex: 0.0,
          regionalSupporters: {},
        ),
        fanZones: [],
        starRiders: [],
        monthlyLedger: [],
        report: MerchandiseRevenueReport(
          seasonYear: 2026,
          teamName: 'Empty Cycling Club',
          totalStoreRevenueEur: 0,
          totalFanClubRevenueEur: 0,
          totalFanZoneRevenueEur: 0,
          totalCostsEur: 0,
          totalUnitsSold: 0,
          averageMarginPercent: 0,
          topSellingCategory: MerchandiseCategory.proReplicaJersey,
          topSellingRiderName: 'Brak',
          fanClubTier: FanClubTier.localSupporters,
        ),
      );

      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1024, 768),
          card: const FanBaseAndMerchandiseCard(stateOverride: emptyState),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak danych regionalnych o kibicach.'), findsOneWidget);

      await tester.tap(find.text('Bestsellery Sklepu'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak produktów w katalogu sklepu klubowego.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Gwiazdy & Repliki'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak kolarzy przypisanych do sprzedaży replik koszulek.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Strefy Kibica'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Brak zaplanowanych stref kibica (Fan Zones).'),
        findsOneWidget,
      );
    });

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'no RenderFlex overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestHost(size: viewport));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);

        for (final tab in FanBaseCardTab.values) {
          final finder = find.text(tab.labelPl);
          await tester.ensureVisible(finder);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(finder);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
      });
    }
  });
}
