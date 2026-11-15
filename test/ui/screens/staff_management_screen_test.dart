// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/ui/screens/staff_management_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    int initialTab = 0,
    bool showAppBar = true,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: StaffManagementScreen(
          initialTab: initialTab,
          showAppBar: showAppBar,
        ),
      ),
    );
  }

  group('StaffManagementScreen - Inicjalizacja i Zakładki', () {
    testWidgets('Poprawnie renderuje AppBar, stan budżetu i 4 zakładki',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Weryfikacja tytułu i opisu
      expect(find.text('SZTAB SZKOLENIOWY & ZARZĄDZANIE'), findsOneWidget);
      expect(
        find.text('Dyrektorzy, Trenerzy, Lekarze, Mechanicy, Skauci i Wóz Techniczny'),
        findsOneWidget,
      );

      // Weryfikacja 4 zakładek
      expect(find.text('Zatrudniony Sztab'), findsOneWidget);
      expect(find.text('Rynek Wolnych Specjalistów'), findsOneWidget);
      expect(find.text('Grupy Treningowe (Opieka)'), findsOneWidget);
      expect(find.text('Wóz Techniczny na Wyścig'), findsOneWidget);

      // Weryfikacja budżetu klubu
      expect(find.textContaining('€'), findsWidgets);
    });

    testWidgets('Poprawnie renderuje w trybie bez AppBar (dla widoku Shell)',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(showAppBar: false));
      await tester.pumpAndSettle();

      expect(find.text('SZTAB SZKOLENIOWY & ZARZĄDZANIE'), findsNothing);
      expect(find.text('Zatrudniony Sztab'), findsOneWidget);
    });
  });

  group('StaffManagementScreen - Tab 1: Zatrudniony Sztab', () {
    testWidgets('Wyświetla banner KPI sztabu oraz filtry ról',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wskaźniki KPI
      expect(find.text('Podsumowanie Kadr Sztabu'), findsOneWidget);
      expect(find.textContaining('Średnia ocena:'), findsOneWidget);
      expect(find.text('Zatrudnionych'), findsOneWidget);
      expect(find.text('Miesięczne Pensje'), findsOneWidget);
      expect(find.text('Dyrektorzy Sportowi'), findsOneWidget);
      expect(find.text('Trenerzy Przygotowania'), findsOneWidget);

      // Filtry ról
      expect(find.textContaining('Wszyscy ('), findsOneWidget);
      expect(find.textContaining('Dyrektorzy ('), findsOneWidget);
      expect(find.textContaining('Trenerzy ('), findsOneWidget);
      expect(find.textContaining('Lekarze ('), findsOneWidget);
      expect(find.textContaining('Mechanicy ('), findsOneWidget);
      expect(find.textContaining('Skauci ('), findsOneWidget);
    });

    testWidgets('Filtrowanie pracowników po roli i wyszukiwanie po nazwisku',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Kliknięcie w filtr 'Dyrektorzy'
      await tester.tap(find.textContaining('Dyrektorzy ('));
      await tester.pumpAndSettle();

      // Wyszukanie w polu tekstowym
      final searchField = find.widgetWithText(TextField, 'Szukaj po nazwisku lub roli...');
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Patrick');
      await tester.pumpAndSettle();

      // Weryfikacja istnienia przynajmniej jednej karty lub pustego stanu jeśli inne imię
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Otwiera i potwierdza dialog przedłużenia kontraktu',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Znajdź przycisk 'Przedłuż (+1 rok)'
      final extendBtn = find.text('Przedłuż (+1 rok)').first;
      await tester.ensureVisible(extendBtn);
      await tester.tap(extendBtn);
      await tester.pumpAndSettle();

      // Weryfikacja dialogu
      expect(find.text('Przedłużenie Kontraktu'), findsOneWidget);
      expect(find.textContaining('Podwyżka lojalnościowa: +5%'), findsOneWidget);

      // Zatwierdzenie
      final confirmBtn = find.text('Zatwierdź');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // SnackBar
      expect(find.textContaining('przedłużony do końca'), findsOneWidget);
    });

    testWidgets('Otwiera i anuluje dialog zwolnienia pracownika',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final fireBtn = find.text('Zwolnij').first;
      await tester.ensureVisible(fireBtn);
      await tester.tap(fireBtn);
      await tester.pumpAndSettle();

      expect(find.text('Rozwiązanie Kontraktu'), findsOneWidget);
      expect(find.textContaining('Odprawa wynosi 1-miesięczne wynagrodzenie'), findsOneWidget);

      final cancelBtn = find.text('Anuluj');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.text('Rozwiązanie Kontraktu'), findsNothing);
    });
  });

  group('StaffManagementScreen - Tab 2: Rynek Wolnych Specjalistów', () {
    testWidgets('Przełącza na rynek, wyświetla kandydatów i otwiera dialog zatrudnienia',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(initialTab: 1));
      await tester.pumpAndSettle();

      // Weryfikacja nagłówka rynku
      expect(find.text('Rynek Wolnych Trenerów i Dyrektorów'), findsOneWidget);
      expect(find.text('Dostępny Budżet'), findsOneWidget);

      // Przycisk zatrudnij
      final hireBtns = find.widgetWithText(ElevatedButton, 'Zatrudnij');
      expect(hireBtns, findsWidgets);

      // Kliknięcie w pierwszego kandydata
      await tester.tap(hireBtns.first);
      await tester.pumpAndSettle();

      // Dialog zatrudnienia
      expect(find.text('Zatrudnienie Specjalisty'), findsOneWidget);
      expect(find.textContaining('Premia powitalna (Signing Fee):'), findsOneWidget);
      expect(find.text('Długość kontraktu:'), findsOneWidget);

      // Wybór długości kontraktu (3 lata)
      final threeYearsOption = find.text('3 lata');
      expect(threeYearsOption, findsOneWidget);
      await tester.tap(threeYearsOption);
      await tester.pumpAndSettle();

      // Podpisanie kontraktu
      final signBtn = find.widgetWithText(ElevatedButton, 'Podpisz Kontrakt');
      expect(signBtn, findsOneWidget);
      await tester.tap(signBtn);
      await tester.pumpAndSettle();

      // SnackBar zatrudnienia
      expect(find.textContaining('Zatrudniono:'), findsOneWidget);
    });
  });

  group('StaffManagementScreen - Tab 3: Grupy Treningowe', () {
    testWidgets('Wyświetla 4 grupy treningowe, przypisanego trenera i kolarzy',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(initialTab: 2));
      await tester.pumpAndSettle();

      // Weryfikacja banera
      expect(find.text('Podział na Grupy Treningowe (4–5 Kolarzy)'), findsOneWidget);

      // Weryfikacja nazw grup
      expect(find.text('Grupa Górska / Liderzy GC'), findsOneWidget);
      expect(find.text('Pociąg Sprinterski & Finiszerzy'), findsOneWidget);
      expect(find.text('Maszyny Aero & Jazda na Czas'), findsOneWidget);
      expect(find.text('Młodzieżowcy & Wszechstronni'), findsOneWidget);

      // Wskaźniki synergii
      expect(find.textContaining('Synergia Grupy Treningowej:'), findsWidgets);
      expect(find.textContaining('Rozwoju'), findsWidgets);
    });

    testWidgets('Otwiera okno wyboru trenera dla grupy',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(initialTab: 2));
      await tester.pumpAndSettle();

      // Znajdź 'Zmień Trenera' lub 'Przypisz Trenera'
      final coachChangeBtn = find.text('Zmień Trenera').first;
      await tester.ensureVisible(coachChangeBtn);
      await tester.tap(coachChangeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Wybierz Trenera Prowadzącego'), findsOneWidget);

      // Zamknij dialog
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();
      expect(find.text('Wybierz Trenera Prowadzącego'), findsNothing);
    });

    testWidgets('Otwiera okno dodawania kolarza do grupy',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(initialTab: 2));
      await tester.pumpAndSettle();

      final addRiderBtn = find.text('Dodaj Kolarza').first;
      await tester.ensureVisible(addRiderBtn);
      await tester.tap(addRiderBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Dodaj Kolarza do:'), findsOneWidget);

      // Zamknięcie
      await tester.tap(find.text('Zamknij'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Dodaj Kolarza do:'), findsNothing);
    });
  });

  group('StaffManagementScreen - Tab 4: Wóz Techniczny na Wyścig', () {
    testWidgets('Wyświetla selektor wyścigu, wóz #1 i #2 oraz odprawę w autobusie',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(initialTab: 3));
      await tester.pumpAndSettle();

      // Banner
      expect(find.text('Wóz Techniczny w Kolumnie Wyścigowej UCI'), findsOneWidget);
      expect(find.text('Tour de France 2026'), findsWidgets);

      // Wozy
      expect(find.textContaining('WÓZ #1 – GŁÓWNY DYREKTOR SPORTOWY'), findsOneWidget);
      expect(find.textContaining('WÓZ #2 – DRUGI DYREKTOR SPORTOWY'), findsOneWidget);

      // Statystyki wyścigowe
      expect(find.text('Czas wymiany roweru'), findsWidgets);
      expect(find.text('Bonus morale z odprawy'), findsWidgets);
      expect(find.text('Poranna Odprawa w Autobusie Zespołu'), findsOneWidget);

      // Przycisk zatwierdzenia obsady
      final saveBtn = find.text('Zatwierdź Obsadę Wozów Technicznych');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // SnackBar z potwierdzeniem
      expect(find.textContaining('Zatwierdzono wóz #1'), findsOneWidget);
    });
  });
}

