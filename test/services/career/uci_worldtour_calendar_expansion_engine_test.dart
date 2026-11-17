import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/uci_worldtour_calendar_expansion_engine.dart';

void main() {
  group('UciWorldtourCalendarExpansionEngine', () {
    test('2026 baseline has no expansion races and valid Grande Partenza', () {
      final summary =
          UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
        seasonYear: 2026,
      );

      expect(summary.seasonYear, 2026);
      expect(summary.activeExpansions, isEmpty);
      expect(summary.expandedRaceCount, summary.baseRaceCount);
      expect(summary.grandePartenza.giroStartCity, isNotEmpty);
      expect(summary.grandePartenza.tourStartCity, isNotEmpty);
      expect(summary.grandePartenza.vueltaStartCity, isNotEmpty);
    });

    test('2027-2030 dynamically expands calendar and rotates Grande Partenza',
        () {
      final s2027 =
          UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
        seasonYear: 2027,
        maxRaceDaysCap: 220,
      );
      final s2029 =
          UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
        seasonYear: 2029,
        maxRaceDaysCap: 230,
      );

      expect(s2027.activeExpansions.length, greaterThanOrEqualTo(3));
      expect(s2029.activeExpansions.length,
          greaterThan(s2027.activeExpansions.length));
      expect(s2029.expandedRaceCount, greaterThan(s2029.baseRaceCount));
      expect(
        s2027.grandePartenza.tourStartCity,
        isNot(equals(s2029.grandePartenza.tourStartCity)),
      );

      // Verify chronological sorting
      for (int i = 1; i < s2029.expandedRaces.length; i++) {
        final prev = s2029.expandedRaces[i - 1];
        final curr = s2029.expandedRaces[i];
        final prevKey = prev.startMonth * 100 + prev.startDay;
        final currKey = curr.startMonth * 100 + curr.startDay;
        expect(currKey, greaterThanOrEqualTo(prevKey));
      }
    });

    test('respects maxRaceDaysCap and handles explicit rejection', () {
      final summary =
          UciWorldtourCalendarExpansionEngine.expandCalendarForSeason(
        seasonYear: 2029,
        maxRaceDaysCap: 185,
        rejectedCandidateIds: {'wt_exp_tokyo_imperial'},
      );

      expect(
        summary.decisions.any(
          (d) =>
              d.candidateId == 'wt_exp_tokyo_imperial' &&
              d.status == CalendarExpansionStatus.rejected,
        ),
        isTrue,
      );
      expect(summary.congestionAudit.totalRaceDays, lessThanOrEqualTo(185));
    });

    test('JSON serialization round-trip preserves candidate and decision data',
        () {
      final candidate =
          UciWorldtourCalendarExpansionEngine.fullExpansionCatalog().first;
      final restoredCandidate =
          WorldTourExpansionCandidate.fromJson(candidate.toJson());
      expect(restoredCandidate.id, candidate.id);
      expect(restoredCandidate.region, candidate.region);
      expect(restoredCandidate.prizePoolEur, candidate.prizePoolEur);

      final partenza =
          UciWorldtourCalendarExpansionEngine.resolveGrandePartenza(2028);
      final restoredPartenza =
          GrandTourGrandePartenzaSpec.fromJson(partenza.toJson());
      expect(restoredPartenza.seasonYear, 2028);
      expect(restoredPartenza.giroStartCity, partenza.giroStartCity);
    });
  });

  group('UciWorldtourCalendarExpansionPanel responsiveness & interactions',
      () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UciWorldtourCalendarExpansionPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('EKSPANSJA KALENDARZA UCI WORLDTOUR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('EKSPANSJA KALENDARZA UCI WORLDTOUR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and advances season',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Kolejny sezon (2027)'), findsOneWidget);

      await tester.tap(find.text('Kolejny sezon (2027)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Kolejny sezon (2028)'), findsOneWidget);
      expect(find.text('Tour of Saudi Red Sea (KSA)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
