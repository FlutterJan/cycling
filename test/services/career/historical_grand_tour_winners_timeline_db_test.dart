import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/historical_grand_tour_winners_timeline_db.dart';

void main() {
  group('HistoricalGrandTourWinnersTimelineDb', () {
    test('default baseline detects 1974, 1987 and 2024 Triple Crown winners', () {
      final db = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: 2026,
      );

      final tripleCrowns = db.detectTripleCrownWinners();
      expect(tripleCrowns.length, 3);
      expect(tripleCrowns.map((e) => e.year).toList(), [2024, 1987, 1974]);
      expect(tripleCrowns[0].riderName, 'Tadej Pogačar');
      expect(tripleCrowns[1].riderName, 'Stephen Roche');
      expect(tripleCrowns[2].riderName, 'Eddy Merckx');

      expect(db.isTripleCrownWinnerInYear('Tadej Pogačar', 2024), isTrue);
      expect(db.isTripleCrownWinnerInYear('Tadej Pogačar', 2026), isFalse);
      expect(db.isCareerTripleCrownLegend('legend_eddy_merckx'), isTrue);
    });

    test('records career winners and detects new Triple Crown only for Giro+Tour+RoadWC in same year', () {
      final db = HistoricalGrandTourWinnersTimelineDb.empty(
        careerStartYear: 2026,
      );

      // 2026: Rider wins Giro + Tour + ITT (NOT Triple Crown)
      db.recordWinners([
        const HistoricalRaceWinnerEntry(
          id: '',
          year: 2026,
          raceId: HistoricalTimelineRaceId.giroDItalia,
          riderId: 'r_jan',
          riderName: 'Jan Kowalski',
          countryCode: 'POL',
          countryName: 'Polska',
          teamId: 't_pol',
          teamName: 'Polska Pro Cycling',
          isPlayerTeam: true,
          isPlayerRider: true,
        ),
        const HistoricalRaceWinnerEntry(
          id: '',
          year: 2026,
          raceId: HistoricalTimelineRaceId.tourDeFrance,
          riderId: 'r_jan',
          riderName: 'Jan Kowalski',
          countryCode: 'POL',
          countryName: 'Polska',
          teamId: 't_pol',
          teamName: 'Polska Pro Cycling',
          isPlayerTeam: true,
          isPlayerRider: true,
        ),
        const HistoricalRaceWinnerEntry(
          id: '',
          year: 2026,
          raceId: HistoricalTimelineRaceId.worldChampionshipTimeTrial,
          riderId: 'r_jan',
          riderName: 'Jan Kowalski',
          countryCode: 'POL',
          countryName: 'Polska',
          teamId: 't_pol',
          teamName: 'Polska Pro Cycling',
          isPlayerTeam: true,
          isPlayerRider: true,
        ),
      ]);

      expect(db.detectTripleCrownWinners(year: 2026), isEmpty);

      // Add Road WC in 2026 -> now Triple Crown!
      db.recordWinner(
        const HistoricalRaceWinnerEntry(
          id: '',
          year: 2026,
          raceId: HistoricalTimelineRaceId.worldChampionshipRoadRace,
          riderId: 'r_jan',
          riderName: 'Jan Kowalski',
          countryCode: 'POL',
          countryName: 'Polska',
          teamId: 't_pol',
          teamName: 'Polska Pro Cycling',
          isPlayerTeam: true,
          isPlayerRider: true,
        ),
      );

      final tc2026 = db.detectTripleCrownWinners(year: 2026);
      expect(tc2026.length, 1);
      expect(tc2026.first.riderName, 'Jan Kowalski');
      expect(tc2026.first.isPlayerManaged, isTrue);
      expect(tc2026.first.totalTimelineWinsInYear, 4);
    });

    test('filters by country, team, rider, category and career start year', () {
      final db = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: 2026,
      );
      db.recordWinner(
        const HistoricalRaceWinnerEntry(
          id: '2026_paris_roubaix',
          year: 2026,
          raceId: HistoricalTimelineRaceId.parisRoubaix,
          riderId: 'r_nowak',
          riderName: 'Piotr Nowak',
          countryCode: 'POL',
          countryName: 'Polska',
          teamId: 't_vistula',
          teamName: 'Vistula Cycling',
        ),
      );

      final polResults = db.query(
        const TimelineFilterCriteria(countryQuery: 'POL'),
      );
      expect(polResults.length, 1);
      expect(polResults.first.riderName, 'Piotr Nowak');

      final teamResults = db.query(
        const TimelineFilterCriteria(teamQuery: 'Alpecin'),
      );
      expect(teamResults.length, 3);

      final riderResults = db.query(
        const TimelineFilterCriteria(riderQuery: 'Pogačar'),
      );
      expect(riderResults.length, 5);

      final sinceStart = db.query(
        const TimelineFilterCriteria(onlySinceCareerStart: true),
      );
      expect(sinceStart.length, 1);
      expect(sinceStart.first.year, 2026);

      final monumentsOnly = db.query(
        const TimelineFilterCriteria(category: TimelineRaceCategory.monument),
      );
      expect(
        monumentsOnly.every(
          (e) => e.raceId.category == TimelineRaceCategory.monument,
        ),
        isTrue,
      );
    });

    test('supports JSON round-trip and rider palmares summary', () {
      final db = HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
        careerStartYear: 2026,
      );
      final encoded = db.toJson();
      final decoded = HistoricalGrandTourWinnersTimelineDb.fromJson(encoded);

      expect(decoded.careerStartYear, 2026);
      expect(decoded.allEntries.length, db.allEntries.length);
      expect(
        decoded.detectTripleCrownWinners().length,
        db.detectTripleCrownWinners().length,
      );

      final palmares = decoded.getRiderPalmares('Tadej Pogačar');
      expect(palmares, isNotNull);
      expect(palmares!.totalWins, 5);
      expect(palmares.grandTourWins, 2);
      expect(palmares.monumentWins, 2);
      expect(palmares.worldChampionshipWins, 1);
      expect(palmares.tripleCrownYears, [2024]);
      expect(palmares.isTripleCrownLegend, isTrue);
    });
  });

  group('HistoricalGrandTourWinnersTimelineNotifier & Panel', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HistoricalGrandTourWinnersTimelinePanel(
                isReadOnly: isReadOnly,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly without overflow at 390x844, 1024x768 and 1600x900',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size);
        expect(tester.takeException(), isNull);
        expect(
          find.text('Kronika Zwycięzców GT, Monumentów i MŚ'),
          findsOneWidget,
        );
        expect(find.text('POTRÓJNA KORONA'), findsWidgets);
      }
    });

    testWidgets('filters entries interactively and handles empty/reset state',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));

      final riderField = find.widgetWithText(TextField, 'Kolarz');
      await tester.enterText(riderField, 'Nieistniejacy Kolarz XYZ');
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak wyników spełniających kryteria filtrowania'),
        findsOneWidget,
      );

      final resetBtn = find.text('Resetuj wszystkie filtry');
      await tester.ensureVisible(resetBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(resetBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tadej Pogačar'), findsWidgets);
    });

    testWidgets('respects isReadOnly disabled state', (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768), isReadOnly: true);

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(tf.enabled, isFalse);
      }
    });
  });
}
