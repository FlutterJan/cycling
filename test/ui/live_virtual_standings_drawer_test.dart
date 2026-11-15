// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/live_virtual_standings_drawer.dart';

void main() {
  group('LiveVirtualStandingsDrawer - Wirtualna Klasyfikacja Generalna na żywo (Virtual GC)', () {
    Widget buildTestDrawer({
      List<VirtualGcRiderEntry>? initialStandings,
      double breakawayGap = 240.0, // 4 minuty przewagi
      bool initiallyExpanded = true,
      VoidCallback? onClose,
      ValueChanged<VirtualGcRiderEntry>? onRiderSelected,
      double width = 450,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: LiveVirtualStandingsDrawer(
                initialStandings: initialStandings,
                breakawayRoadGapSeconds: breakawayGap,
                initiallyExpanded: initiallyExpanded,
                onClose: onClose,
                onRiderSelected: onRiderSelected,
              ),
            ),
          ),
        ),
      );
    }

    test('VirtualGcCalculator precyzyjnie przelicza wirtualnego lidera przy 4 minutach przewagi ucieczki', () {
      // Scenariusz z promptu:
      // Pogačar: lider na starcie (0:00)
      // Mohorič: +3'15" (195s) na starcie, w ucieczce z 4 minutami przewagi (240s)
      final standings = VirtualGcCalculator.demoStandings(breakawayGapSeconds: 240.0);

      // Mohorič powinien być wirtualnym liderem wyścigu (#1, LIDER, żółta koszulka)
      final virtualLeader = standings.first;
      expect(virtualLeader.riderName, equals('M. Mohorič'));
      expect(virtualLeader.virtualRank, equals(1));
      expect(virtualLeader.isVirtualYellowJersey, isTrue);
      expect(virtualLeader.formattedVirtualGap, equals('LIDER'));
      expect(virtualLeader.rankChange, equals(13)); // z 14 na 1

      // Pogačar powinien być wirtualnie drugi ze stratą 45 sekund do Mohoriča (240 - 195 = 45s)
      final pogacar = standings.firstWhere((r) => r.riderId == 'r_pogacar');
      expect(pogacar.virtualRank, equals(2));
      expect(pogacar.isVirtualYellowJersey, isFalse);
      expect(pogacar.virtualGapToLeaderSeconds, equals(45.0));
      expect(pogacar.formattedVirtualGap, equals("+0'45\""));

      // Vingegaard (miał +38s do Pogačara) teraz traci 45 + 38 = 83s (+1'23") do Mohoriča
      final vingegaard = standings.firstWhere((r) => r.riderId == 'r_vingegaard');
      expect(vingegaard.virtualGapToLeaderSeconds, equals(83.0));
      expect(vingegaard.formattedVirtualGap, equals("+1'23\""));
    });

    test('spadek przewagi ucieczki do 2 minut przywraca Pogačara na pozycję wirtualnego lidera', () {
      // Przy 2 minutach (120s) przewagi ucieczki, Mohorič traci 195 - 120 = 75s do Pogačara
      final standings = VirtualGcCalculator.demoStandings(breakawayGapSeconds: 120.0);

      final virtualLeader = standings.first;
      expect(virtualLeader.riderName, equals('T. Pogačar'));
      expect(virtualLeader.virtualRank, equals(1));
      expect(virtualLeader.isVirtualYellowJersey, isTrue);

      final mohoric = standings.firstWhere((r) => r.riderId == 'r_mohoric');
      expect(mohoric.virtualRank, greaterThan(1));
      expect(mohoric.virtualGapToLeaderSeconds, equals(75.0));
      expect(mohoric.formattedVirtualGap, equals("+1'15\""));
    });

    testWidgets('renderuje nagłówek, baner Wirtualnego Lidera i tabelę z kolarzami', (tester) async {
      await tester.pumpWidget(buildTestDrawer(breakawayGap: 240.0));
      await tester.pumpAndSettle();

      // Nagłówek panelu
      expect(find.text('WIRTUALNA KLASYFIKACJA GC'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      // Karta wyróżnienia Wirtualnego Lidera (Mohorič)
      expect(find.text('WIRTUALNY LIDER (MAILLOT JAUNE)'), findsOneWidget);
      expect(find.textContaining('M. Mohorič (TBV)'), findsWidgets);
      expect(find.textContaining('Awans o +13 pozycji'), findsOneWidget);
      expect(find.textContaining('+45s nad Pogačarem'), findsOneWidget);

      // Tabela z kolarzami
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('T. Pogačar'), findsOneWidget);
      expect(find.text("+0'45\""), findsOneWidget);
    });

    testWidgets('filtry widoku (Top 15, Ucieczka, Mój Zespół, Faworyci GC) działają poprawnie', (tester) async {
      await tester.pumpWidget(buildTestDrawer(breakawayGap: 240.0));
      await tester.pumpAndSettle();

      // Domyślnie filtr Top 15 pokazuje kolarzy z peletonu i ucieczki
      expect(find.text('M. Mohorič'), findsWidgets);
      expect(find.text('T. Pogačar'), findsOneWidget);

      // Filtr: Tylko Ucieczka
      await tester.tap(find.byKey(const Key('filter_breakawayOnly')));
      await tester.pumpAndSettle();

      // Kolarze z ucieczki są widoczni (Mohorič, Cort, Majka)
      expect(find.text('M. Mohorič'), findsWidgets);
      expect(find.text('M. Cort Nielsen'), findsOneWidget);
      expect(find.text('R. Majka'), findsOneWidget);
      // Pogačar jedzie w peletonie, więc znika z listy
      expect(find.text('T. Pogačar'), findsNothing);

      // Filtr: Mój Zespół (UAE Team Emirates)
      await tester.tap(find.byKey(const Key('filter_myTeamOnly')));
      await tester.pumpAndSettle();

      expect(find.text('T. Pogačar'), findsOneWidget);
      expect(find.text('R. Majka'), findsOneWidget);
      expect(find.text('J. Almeida'), findsOneWidget);
      expect(find.text('M. Mohorič'), findsNothing); // Nie jest w zespole gracza
    });

    testWidgets('wyszukiwarka kolarza filtruje listę na żywo', (tester) async {
      await tester.pumpWidget(buildTestDrawer(breakawayGap: 240.0));
      await tester.pumpAndSettle();

      // Otwarcie paska wyszukiwania
      await tester.tap(find.byKey(const Key('button_toggle_search_gc')));
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const Key('input_search_rider'));
      expect(searchInput, findsOneWidget);

      // Wpisanie "Vingegaard"
      await tester.enterText(searchInput, 'Vingegaard');
      await tester.pumpAndSettle();

      expect(find.text('J. Vingegaard'), findsOneWidget);
      expect(find.text('R. Evenepoel'), findsNothing);
    });

    testWidgets('kliknięcie w wiersz kolarza wywołuje callback onRiderSelected', (tester) async {
      VirtualGcRiderEntry? clickedRider;

      await tester.pumpWidget(buildTestDrawer(
        breakawayGap: 240.0,
        onRiderSelected: (r) => clickedRider = r,
      ));
      await tester.pumpAndSettle();

      // Kliknięcie w Pogačara
      await tester.tap(find.text('T. Pogačar'));
      await tester.pumpAndSettle();

      expect(clickedRider, isNotNull);
      expect(clickedRider!.riderName, equals('T. Pogačar'));
      expect(clickedRider!.virtualRank, equals(2));
    });

    testWidgets('przycisk zamknięcia wywołuje onClose', (tester) async {
      bool closed = false;

      await tester.pumpWidget(buildTestDrawer(
        onClose: () => closed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('button_close_virtual_gc')));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });
  });
}

