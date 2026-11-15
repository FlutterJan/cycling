// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/ui/widgets/group_gaps_chalkboard_widget.dart';

void main() {
  group('GroupGapsChalkboardWidget - Tablica Motocyklisty (Ardoisier)', () {
    Widget buildTestChalkboard({
      List<ChalkboardGroup>? groups,
      bool isCollapsible = true,
      bool initiallyCollapsed = false,
      ValueChanged<ChalkboardGroup>? onGroupSelected,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 1200,
                child: GroupGapsChalkboardWidget(
                  groups: groups,
                  isCollapsible: isCollapsible,
                  initiallyCollapsed: initiallyCollapsed,
                  onGroupSelected: onGroupSelected,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('wyświetla nagłówek ARDOISIER oraz kafelki wszystkich grup na trasie', (tester) async {
      await tester.pumpWidget(buildTestChalkboard(
        groups: ChalkboardGroup.demoGroups(),
      ));
      await tester.pumpAndSettle();

      // Sprawdzenie nagłówka tablicy motocyklisty
      expect(find.text('ARDOISIER'), findsOneWidget);
      expect(find.text('RÓŻNICE CZASOWE • TIME GAPS'), findsOneWidget);

      // Kafelki 4 grup demonstracyjnych: Ucieczka, Kontra, Peleton, Grupetto
      expect(find.text('UCIECZKA'), findsOneWidget);
      expect(find.text('KONTRA'), findsOneWidget);
      expect(find.text('PELETON'), findsOneWidget);
      expect(find.text('GRUPETTO'), findsOneWidget);

      // Liczba kolarzy w każdej grupie
      expect(find.text('4 KOL.'), findsOneWidget);
      expect(find.text('2 KOL.'), findsOneWidget);
      expect(find.text('124 KOL.'), findsOneWidget);
      expect(find.text('28 KOL.'), findsOneWidget);

      // Różnice czasowe
      expect(find.text('LIDER'), findsOneWidget);
      expect(find.text('+0\'42"'), findsOneWidget);
      expect(find.text('+2\'15"'), findsOneWidget);
      expect(find.text('+12\'40"'), findsOneWidget);
    });

    testWidgets('poprawnie prezentuje pacemakera dyktującego tempo na czele formacji', (tester) async {
      await tester.pumpWidget(buildTestChalkboard(
        groups: ChalkboardGroup.demoGroups(),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Czoło: R. Majka (UAD)'), findsOneWidget);
      expect(find.textContaining('Czoło: W. Van Aert (TVL)'), findsOneWidget);
      expect(find.textContaining('Czoło: J. Castroviejo (IGD)'), findsOneWidget);
      expect(find.textContaining('Czoło: M. Cavendish (AST)'), findsOneWidget);
    });

    testWidgets('wyświetla strzałki trendów czasowych (▲ rośnie, ▼ topnieje, — stała)', (tester) async {
      const customGroups = [
        ChalkboardGroup(
          id: 'lead',
          type: GroupType.breakaway,
          title: 'Ucieczka',
          riderCount: 3,
          gapToLeaderSeconds: 0.0,
          trend: GapTrend.growing,
          gapChangeSecondsPerKm: 4.2,
        ),
        ChalkboardGroup(
          id: 'chase',
          type: GroupType.chaseGroup,
          title: 'Kontra',
          riderCount: 2,
          gapToLeaderSeconds: 55.0,
          trend: GapTrend.shrinking,
          gapChangeSecondsPerKm: -5.1,
        ),
        ChalkboardGroup(
          id: 'peloton',
          type: GroupType.peloton,
          title: 'Peleton',
          riderCount: 110,
          gapToLeaderSeconds: 180.0,
          trend: GapTrend.stable,
          gapChangeSecondsPerKm: 0.0,
        ),
      ];

      await tester.pumpWidget(buildTestChalkboard(groups: customGroups));
      await tester.pumpAndSettle();

      // Kontra odrabia straty: strzałka ▼ i ujemna wartość
      expect(find.text('▼'), findsOneWidget);
      expect(find.text('-5.1s/km'), findsOneWidget);

      // Peleton jedzie równym tempem: stabilna kreska
      expect(find.text('—'), findsOneWidget);
      expect(find.text('tempo równe'), findsOneWidget);
    });

    testWidgets('wyróżnia kafelki grup, w których jedzie kolarz zespołu gracza', (tester) async {
      await tester.pumpWidget(buildTestChalkboard(
        groups: ChalkboardGroup.demoGroups(),
      ));
      await tester.pumpAndSettle();

      // Ucieczka ma kolarza gracza (Majka)
      expect(find.text('Twój: R. Majka'), findsOneWidget);

      // Peleton ma kolarza gracza (Pogačar)
      expect(find.text('Twój: T. Pogačar'), findsOneWidget);

      // Ikony gwiazdek przy zawodnikach gracza
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    });

    testWidgets('zwijanie i rozwijanie tablicy motocyklisty (Collapsible mode)', (tester) async {
      await tester.pumpWidget(buildTestChalkboard(
        groups: ChalkboardGroup.demoGroups(),
        initiallyCollapsed: false,
      ));
      await tester.pumpAndSettle();

      // Przed zwinięciem widoczne są kafelki grup
      expect(find.text('UCIECZKA'), findsOneWidget);
      expect(find.text('PELETON'), findsOneWidget);

      // Kliknięcie w nagłówek zwija tablicę
      final headerFinder = find.text('RÓŻNICE CZASOWE • TIME GAPS');
      await tester.tap(headerFinder);
      await tester.pumpAndSettle();

      // Po zwinięciu kafelki są ukryte, a pojawia się podsumowanie kompaktowe
      expect(find.text('UCIECZKA'), findsNothing);
      expect(find.textContaining('vs Peleton:'), findsOneWidget);

      // Ponowne kliknięcie rozwija tablicę z powrotem
      await tester.tap(headerFinder);
      await tester.pumpAndSettle();

      expect(find.text('UCIECZKA'), findsOneWidget);
      expect(find.text('PELETON'), findsOneWidget);
    });

    testWidgets('kliknięcie na kafelek grupy wywołuje callback i otwiera modal ze składem', (tester) async {
      ChalkboardGroup? selectedGroup;

      await tester.pumpWidget(buildTestChalkboard(
        groups: ChalkboardGroup.demoGroups(),
        onGroupSelected: (g) => selectedGroup = g,
      ));
      await tester.pumpAndSettle();

      // Kliknięcie w kafelek Ucieczki
      final breakawayTile = find.text('UCIECZKA');
      expect(breakawayTile, findsOneWidget);
      await tester.tap(breakawayTile);
      await tester.pumpAndSettle();

      // Sprawdzenie wywołania callbacku
      expect(selectedGroup, isNotNull);
      expect(selectedGroup!.type, equals(GroupType.breakaway));

      // Sprawdzenie czy otworzył się modal ze składem grupy
      expect(find.text('SKŁAD GRUPY:'), findsOneWidget);
      expect(find.text('K. Neilands'), findsOneWidget);
      expect(find.text('M. Cort'), findsOneWidget);
      expect(find.text('N. Politt'), findsOneWidget);
    });

    testWidgets('brak przekazanych grup bezpiecznie pobiera grupy demo lub Riverpod', (tester) async {
      await tester.pumpWidget(buildTestChalkboard());
      await tester.pumpAndSettle();

      expect(find.text('ARDOISIER'), findsOneWidget);
      expect(find.byType(GroupGapsChalkboardWidget), findsOneWidget);
    });
  });
}

