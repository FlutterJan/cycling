import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/historic_legend_hall_of_fame_compare.dart';
import 'package:pro_peloton_manager/services/career/historical_records_and_palmares_service.dart';

void main() {
  group('HistoricLegendHallOfFameCompareService', () {
    const service = HistoricLegendHallOfFameCompareService();

    test('evaluates Eddy Merckx as Immortal Apex (Tier 5) and rank #1', () {
      final leaderboard = service.buildMergedHallOfFame();
      expect(leaderboard, isNotEmpty);
      expect(leaderboard.first.riderId, 'legend_eddy_merckx');
      expect(leaderboard.first.breakdown.tier, GoatTier.immortalApex);
      expect(leaderboard.first.effectiveScore, greaterThan(14000));
      expect(leaderboard.first.gapToLeader, 0);
    });

    test('applies era adjustment multiplier accurately', () {
      final pogacar = HistoricLegendsCatalog.legends.firstWhere(
        (l) => l.id == 'legend_tadej_pogacar',
      );
      final breakdown = service.evaluateLegend(pogacar);

      expect(
        breakdown.eraAdjustedTotalScore,
        greaterThan(breakdown.rawTotalScore),
      );
      expect(breakdown.hasTripleCrownSameYear, isTrue);
      expect(breakdown.normalizedIndex100, inInclusiveRange(0.0, 100.0));
    });

    test('compares two legends head-to-head with all 6 categories', () {
      final merckx = service.evaluateLegend(
        HistoricLegendsCatalog.legends.firstWhere(
          (l) => l.id == 'legend_eddy_merckx',
        ),
      );
      final pogacar = service.evaluateLegend(
        HistoricLegendsCatalog.legends.firstWhere(
          (l) => l.id == 'legend_tadej_pogacar',
        ),
      );

      final report = service.compareRiders(pogacar, merckx);
      expect(report.categories.length, 6);
      expect(report.scoreDelta, lessThan(0));
      expect(report.verdictHeadline, contains('Eddy Merckx'));
    });

    test('merges active career riders and filters by tier, era, and query', () {
      const activeStar = RiderPalmares(
        riderId: 'career_star_1',
        riderName: 'Jan Kowalski',
        nationalityIso: 'POL',
        grandTourOverallWins: 2,
        tourDeFranceGcWins: 2,
        monumentWins: 2,
        rondeVanVlaanderenWins: 1,
        parisRoubaixWins: 1,
        grandTourStageWins: 6,
        totalCareerVictories: 28,
      );

      final merged = service.buildMergedHallOfFame(
        careerRiders: const [activeStar],
        searchQuery: 'Kowalski',
      );
      expect(merged.length, 1);
      expect(merged.first.isCareerRider, isTrue);
      expect(merged.first.breakdown.tier.level, greaterThanOrEqualTo(3));

      final emptyFiltered = service.buildMergedHallOfFame(
        careerRiders: const [activeStar],
        filterTier: GoatTier.immortalApex,
        filterEra: CyclingEra.modernEra2000_2019,
      );
      expect(emptyFiltered, isEmpty);
    });

    test('nextMilestoneRecommendations computes projected score and tier jump', () {
      const emerging = RiderPalmares(
        riderId: 'emerging_1',
        riderName: 'Młody Talent',
        nationalityIso: 'POL',
        grandTourStageWins: 2,
        otherWorldTourWins: 5,
        totalCareerVictories: 10,
      );

      final breakdown = service.evaluatePalmares(
        emerging,
        activeSeasons: 3,
      );
      expect(breakdown.tier, GoatTier.risingLegend);

      final projections = service.nextMilestoneRecommendations(breakdown);
      expect(projections, isNotEmpty);
      expect(projections.first.pointsGain, greaterThan(0));
      expect(
        projections.any((p) => p.promotesTier),
        isTrue,
      );
    });
  });

  group('HistoricLegendHallOfFameComparePanel responsive widget tests', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
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
              body: HistoricLegendHallOfFameComparePanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('ALL-TIME GOAT SCORE & HALL OF FAME'), findsOneWidget);
      expect(find.text('Ranking Wszech Czasów'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('ALL-TIME GOAT SCORE & HALL OF FAME'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and supports swap/filter',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('ALL-TIME GOAT SCORE & HALL OF FAME'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Normalizacja Epok'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
