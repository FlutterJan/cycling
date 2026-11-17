import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/services/career/tv_broadcast_rights_revenue_sharing.dart';

void main() {
  group('TvBroadcastRightsRevenueSharingService', () {
    const service = TvBroadcastRightsRevenueSharingService();

    test('distributes full pool accurately across WorldTour and Wildcard teams',
        () {
      final teams =
          TvBroadcastRightsRevenueSharingService.createSampleWorldTourGrid();
      const config = BroadcastPoolConfiguration(
        seasonYear: 2026,
        totalWorldTourPoolEur: 48000000.0,
        grandTourBonusPoolEur: 12000000.0,
        distributionModel: BroadcastDistributionModel.balancedWorldTour,
      );

      final report = service.calculateSeasonDistribution(
        config: config,
        teams: teams,
      );

      expect(report.teamShares.length, teams.length);
      expect(
        report.totalDistributedEur,
        closeTo(config.effectiveTotalPoolEur, 1.0),
      );
      expect(report.playerTeamShare, isNotNull);
      expect(report.playerTeamShare!.teamId, 'player_team');
      expect(report.giniInequalityIndex, inInclusiveRange(0.0, 1.0));

      // Ranking malejący wg wypłaty
      for (var i = 0; i < report.teamShares.length - 1; i++) {
        expect(
          report.teamShares[i].totalPayoutEur,
          greaterThanOrEqualTo(report.teamShares[i + 1].totalPayoutEur),
        );
        expect(report.teamShares[i].rankByRevenue, i + 1);
      }
    });

    test('commercialViewership rewards high TV viewership more than equalitarian',
        () {
      final teams =
          TvBroadcastRightsRevenueSharingService.createSampleWorldTourGrid();
      final eqReport = service.calculateSeasonDistribution(
        config: const BroadcastPoolConfiguration(
          distributionModel: BroadcastDistributionModel.equalitarian,
        ),
        teams: teams,
      );
      final tvReport = service.calculateSeasonDistribution(
        config: const BroadcastPoolConfiguration(
          distributionModel: BroadcastDistributionModel.commercialViewership,
        ),
        teams: teams,
      );

      expect(
        tvReport.giniInequalityIndex,
        greaterThan(eqReport.giniInequalityIndex),
      );
      final topTeamEq = eqReport.teamShares.first.totalPayoutEur;
      final topTeamTv = tvReport.teamShares.first.totalPayoutEur;
      expect(topTeamTv, greaterThan(topTeamEq));
    });

    test('handles empty teams, zero pool, and NaN/negative inputs safely', () {
      final emptyReport = service.calculateSeasonDistribution(
        config: const BroadcastPoolConfiguration(),
        teams: const [],
      );
      expect(emptyReport.teamShares, isEmpty);
      expect(emptyReport.totalDistributedEur, 0.0);

      final dirtyTeams = [
        const TeamBroadcastPerformanceInput(
          teamId: 't1',
          teamName: 'Dirty Team',
          teamShortCode: 'DRT',
          uciSeasonPoints: double.nan,
          worldTourWins: -3,
          averageViewersMillions: -5.0,
          tvExposureMinutes: double.infinity,
          socialMediaEngagementIndex: 250.0,
        ),
      ];

      final zeroPoolReport = service.calculateSeasonDistribution(
        config: const BroadcastPoolConfiguration(
          totalWorldTourPoolEur: 0.0,
          grandTourBonusPoolEur: 0.0,
        ),
        teams: dirtyTeams,
      );
      expect(zeroPoolReport.totalDistributedEur, 0.0);
      expect(zeroPoolReport.teamShares.first.totalPayoutEur, 0.0);

      final validPoolReport = service.calculateSeasonDistribution(
        config: const BroadcastPoolConfiguration(
          totalWorldTourPoolEur: 10000000.0,
          grandTourBonusPoolEur: 0.0,
        ),
        teams: dirtyTeams,
      );
      expect(validPoolReport.totalDistributedEur, closeTo(10000000.0, 1.0));
      expect(validPoolReport.teamShares.first.totalPayoutEur.isFinite, isTrue);
    });

    test('simulateViewershipImpact computes positive delta for extra exposure',
        () {
      final teams =
          TvBroadcastRightsRevenueSharingService.createSampleWorldTourGrid();
      const config = BroadcastPoolConfiguration();

      final sim = service.simulateViewershipImpact(
        targetTeamId: 'player_team',
        extraExposureMinutes: 300.0,
        extraUciPoints: 2500.0,
        extraGrandTourStageWins: 2,
        config: config,
        teams: teams,
      );

      expect(sim.netDeltaEur, greaterThan(0.0));
      expect(sim.projectedPayoutEur, greaterThan(sim.baselinePayoutEur));
      expect(sim.projectedRank, lessThanOrEqualTo(sim.baselineRank));
    });

    test('JSON round-trip preserves SeasonBroadcastRevenueReport', () {
      final teams =
          TvBroadcastRightsRevenueSharingService.createSampleWorldTourGrid();
      final report = service.calculateSeasonDistribution(
        config: const BroadcastPoolConfiguration(),
        teams: teams,
      );

      final decoded = SeasonBroadcastRevenueReport.fromJson(report.toJson());
      expect(decoded.seasonYear, report.seasonYear);
      expect(decoded.teamShares.length, report.teamShares.length);
      expect(decoded.totalDistributedEur, closeTo(report.totalDistributedEur, 0.01));
      expect(decoded.playerTeamShare?.teamId, report.playerTeamShare?.teamId);
    });
  });

  group('TvBroadcastRightsRevenuePanel Widget & Responsiveness', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      TvBroadcastRevenueState? initialState,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (initialState != null)
              tvBroadcastRevenueProvider.overrideWith(
                (ref) => TvBroadcastRevenueNotifier(initialState: initialState),
              ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TvBroadcastRightsRevenuePanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844, 1024x768, and 1600x900',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('Prawa Telewizyjne WorldTour'),
          findsOneWidget,
        );
        expect(find.text('Polonia Pro Cycling'), findsWidgets);
      }
    });

    testWidgets('switches distribution model and selects team', (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Komercyjny TV'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('UAE Team Emirates XRG').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays empty state and read-only badge when configured',
        (tester) async {
      await pumpPanelAtSize(
        tester,
        const Size(1024, 768),
        initialState: const TvBroadcastRevenueState(
          teams: [],
          isReadOnly: true,
        ),
      );

      expect(find.text('TYLKO ODCZYT'), findsOneWidget);
      expect(
        find.text('Brak danych drużyn dla bieżącego cyklu praw TV'),
        findsOneWidget,
      );
    });
  });
}
