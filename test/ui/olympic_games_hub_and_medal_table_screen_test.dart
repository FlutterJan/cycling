import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/olympic_games_quadrennial_cycle_service.dart';
import 'package:pro_peloton_manager/ui/screens/olympic_games_hub_and_medal_table_screen.dart';

void main() {
  group('OlympicMedalTableAggregator', () {
    test('builds and sorts baseline medal table for 2024 and 2028', () {
      final service = OlympicGamesQuadrennialCycleService();
      final rows2024 = OlympicMedalTableAggregator.buildMedalTable(
        olympicYear: 2024,
        reports: const [],
        playerNationalityIso: 'POL',
        service: service,
      );

      expect(rows2024, isNotEmpty);
      expect(rows2024.first.countryIso, 'BEL');
      expect(rows2024.first.goldCount, 2);
      expect(rows2024.first.bronzeCount, 1);
      expect(rows2024.first.totalMedals, 3);

      final polRow = rows2024.firstWhere((r) => r.countryIso == 'POL');
      expect(polRow.isPlayerNation, isTrue);

      final onlyMedals = OlympicMedalTableAggregator.sortRows(
        rows2024,
        sortColumn: OlympicMedalTableSortColumn.olympicRank,
        ascending: false,
        onlyWithMedals: true,
      );
      expect(onlyMedals.every((r) => r.totalMedals > 0), isTrue);

      final searchPol = OlympicMedalTableAggregator.sortRows(
        rows2024,
        sortColumn: OlympicMedalTableSortColumn.countryName,
        ascending: true,
        searchQuery: 'Polska',
      );
      expect(searchPol.length, 1);
      expect(searchPol.first.countryIso, 'POL');
    });
  });

  group('OlympicGamesHubAndMedalTableScreen responsive & interactions', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size, {
      bool isReadOnly = false,
      ValueChanged<OlympicHostEdition>? onLaunchRace3d,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: OlympicGamesHubAndMedalTableScreen(
            playerNationalityIso: 'POL',
            isReadOnly: isReadOnly,
            onLaunchRace3d: onLaunchRace3d,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (
      tester,
    ) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.textContaining('IGRZYSKA OLIMPIJSKIE'), findsOneWidget);
      expect(find.textContaining('TABELA MEDALOWA PAŃSTW'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Składy Narodowe'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Składy Narodowe'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('MAŁE REPREZENTACJE NARODOWE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (
      tester,
    ) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.textContaining('IGRZYSKA OLIMPIJSKIE'), findsOneWidget);
      expect(find.text('Symuluj Wyścig Olimpijski'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop Bento layout', (
      tester,
    ) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.textContaining('TABELA MEDALOWA PAŃSTW'), findsOneWidget);
      expect(find.text('TRASA OLIMPIJSKA & ZASADA NO RACE RADIO'), findsOneWidget);
      expect(find.text('ZŁOTY KASK & ZŁOTA RAMA (4-LETNI CYKL)'), findsOneWidget);
      expect(find.text('MAŁE REPREZENTACJE NARODOWE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('simulates Olympic race and updates champions & results', (
      tester,
    ) async {
      await pumpAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('2024 Paryż'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('PARYŻ 2024'), findsOneWidget);

      await tester.tap(find.text('Symuluj Wyścig Olimpijski'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('WYNIKI SYMULACJI: PARYŻ 2024'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects isReadOnly disabled state', (tester) async {
      OlympicHostEdition? launched;
      await pumpAtSize(
        tester,
        const Size(1600, 900),
        isReadOnly: true,
        onLaunchRace3d: (ed) => launched = ed,
      );

      await tester.tap(find.text('2024 Paryż'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('LOS ANGELES 2028'), findsOneWidget);

      await tester.tap(find.text('Startuj w 3D'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(launched, isNull);
    });
  });
}
