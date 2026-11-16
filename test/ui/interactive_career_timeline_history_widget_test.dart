import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/interactive_career_timeline_history_widget.dart';

void main() {
  group('CareerTimelineAnalytics', () {
    test('summarize handles empty seasons list safely', () {
      final stats = CareerTimelineAnalytics.summarize(const []);

      expect(stats.totalSeasons, 0);
      expect(stats.distinctTeamsCount, 0);
      expect(stats.totalGrandTours, 0);
      expect(stats.totalMonuments, 0);
      expect(stats.totalSeasonWins, 0);
      expect(stats.peakBudgetEur, 0);
      expect(stats.latestBudgetEur, 0);
      expect(stats.biggestTransferFeeEur, 0);
      expect(stats.biggestTransferSummary, 'Brak transferów');
    });

    test('summarize aggregates demo career history accurately', () {
      final demo = CareerTimelineAnalytics.defaultDemoHistory();
      final stats = CareerTimelineAnalytics.summarize(demo);

      expect(stats.totalSeasons, 5);
      expect(stats.distinctTeamsCount, 3);
      expect(stats.totalGrandTours, 3);
      expect(stats.totalMonuments, 5);
      expect(stats.totalSeasonWins, 14 + 24 + 39 + 47 + 56);
      expect(stats.peakBudgetEur, 34200000);
      expect(stats.latestBudgetEur, 34200000);
      expect(stats.biggestTransferFeeEur, 4100000);
      expect(stats.biggestTransferSummary, contains('Théo Moreau'));
    });
  });

  group('InteractiveCareerTimelineHistoryWidget', () {
    Future<void> pumpTimelineAtSize(
      WidgetTester tester, {
      required Size size,
      required List<CareerSeasonHistoryEntry> seasons,
      int? initialSelectedYear,
      ValueChanged<CareerSeasonHistoryEntry>? onSeasonSelected,
      ValueChanged<CareerHeadlineTransferEntry>? onTransferTap,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: InteractiveCareerTimelineHistoryWidget(
                seasons: seasons,
                managerName: 'Jan Kowalski',
                initialSelectedYear: initialSelectedYear,
                onSeasonSelected: onSeasonSelected,
                onTransferTap: onTransferTap,
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
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpTimelineAtSize(
            tester,
            size: size,
            seasons: CareerTimelineAnalytics.defaultDemoHistory(),
          );

          expect(find.text('OŚ CZASU KARIERY MENEDŻERA'), findsOneWidget);
          expect(find.textContaining('SEZON 2030'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('selecting a year node updates detail panel and fires callback',
        (tester) async {
      CareerSeasonHistoryEntry? selectedCallback;
      await pumpTimelineAtSize(
        tester,
        size: const Size(1280, 800),
        seasons: CareerTimelineAnalytics.defaultDemoHistory(),
        onSeasonSelected: (s) => selectedCallback = s,
      );

      expect(find.textContaining('SEZON 2030'), findsOneWidget);

      await tester.tap(find.text('2028').first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(selectedCallback?.seasonYear, 2028);
      expect(find.textContaining('SEZON 2028'), findsOneWidget);
      expect(find.text('La Vuelta a España'), findsOneWidget);
    });

    testWidgets('filter pills narrow visible seasons and allow resetting',
        (tester) async {
      await pumpTimelineAtSize(
        tester,
        size: const Size(1280, 800),
        seasons: CareerTimelineAnalytics.defaultDemoHistory(),
      );

      await tester.tap(find.textContaining('Wielkie Toury (3)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('SEZON 2030'), findsOneWidget);

      final teamChangesPill = find.textContaining('Zmiany Zespołu (2)');
      await tester.ensureVisible(teamChangesPill);
      await tester.tap(teamChangesPill);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('SEZON 2028'), findsOneWidget);
    });

    testWidgets('renders empty state cleanly when seasons list is empty',
        (tester) async {
      await pumpTimelineAtSize(
        tester,
        size: const Size(1024, 768),
        seasons: const [],
      );

      expect(find.text('Brak zapisanych sezonów kariery'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
