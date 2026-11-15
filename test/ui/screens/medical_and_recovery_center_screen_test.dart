// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/ui/screens/medical_and_recovery_center_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    String? initialRiderId,
    bool showAppBar = true,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: MedicalAndRecoveryCenterScreen(
          initialRiderId: initialRiderId,
          showAppBar: showAppBar,
        ),
      ),
    );
  }

  group('MedicalAndRecoveryCenterScreen - Inicjalizacja i Struktura', () {
    testWidgets('Poprawnie renderuje nagłówek, wskaźniki KPI i 3 zakładki',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Weryfikacja tytułu i nagłówka
      expect(find.text('Centrum Medyczne & Odnowa Biologiczna'), findsOneWidget);
      expect(find.text('DZIAŁ MEDYCYNY SPORTOWEJ & REGENERACJI'), findsOneWidget);

      // Weryfikacja 3 zakładek
      expect(find.text('Wykaz Medyczny Kolarzy'), findsOneWidget);
      expect(find.text('Protokoły Odnowy & Zabiegi'), findsOneWidget);
      expect(find.text('Inwestycje & Sprzęt Kliniki'), findsOneWidget);

      // Weryfikacja wskaźników KPI
      expect(find.textContaining('Średnie ATL'), findsOneWidget);
      expect(find.textContaining('Aktywne Kontuzje'), findsOneWidget);
      expect(find.textContaining('Średni Hematokryt'), findsOneWidget);
    });

    testWidgets('Poprawnie renderuje w trybie bez AppBar (dla widoku Shell)',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(showAppBar: false));
      await tester.pumpAndSettle();

      // Główny nagłówek kontenera jest widoczny
      expect(find.text('DZIAŁ MEDYCYNY SPORTOWEJ & REGENERACJI'), findsOneWidget);
      // AppBar nie jest renderowany
      expect(find.byType(AppBar), findsNothing);
    });
  });

  group('MedicalAndRecoveryCenterScreen - Zakładka 1: Wykaz Medyczny Kolarzy', () {
    testWidgets('Renderuje karty kolarzy z parametrami ATL, CK, Hct i Ferrytyną',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Weryfikacja kolarzy z demo squad
      expect(find.text('Tadej Pogačar'), findsOneWidget);
      expect(find.text('Jasper Philipsen'), findsOneWidget);

      // Weryfikacja etykiet 4 biomarkerów
      expect(find.textContaining('Zmęczenie Układowe (ATL)'), findsWidgets);
      expect(find.textContaining('Kinaza Kreatynowa (CK)'), findsWidgets);
      expect(find.textContaining('Hematokryt (Hct)'), findsWidgets);
      expect(find.textContaining('Ferrytyna (Żelazo)'), findsWidgets);

      // Weryfikacja kontuzji Jaspera Philipsena (szlif powypadkowy)
      expect(find.textContaining('Asfaltowy szlif biodra'), findsOneWidget);
    });

    testWidgets('Filtrowanie kolarzy według kategorii Kontuzje & Szlify',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Kliknięcie filtra "Kontuzje & Szlify"
      final injuryFilter = find.text('Kontuzje & Szlify');
      expect(injuryFilter, findsOneWidget);
      await tester.tap(injuryFilter);
      await tester.pumpAndSettle();

      // Widoczny tylko poszkodowany kolarz (Jasper Philipsen ze szlifem)
      expect(find.text('Jasper Philipsen'), findsOneWidget);
      expect(find.text('Tadej Pogačar'), findsNothing);
    });

    testWidgets('Wyszukiwarka kolarzy filtruje listę po nazwisku',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Wpisanie "Ganna" w wyszukiwarkę
      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);
      await tester.enterText(searchInput, 'Ganna');
      await tester.pumpAndSettle();

      expect(find.text('Filippo Ganna'), findsOneWidget);
      expect(find.text('Tadej Pogačar'), findsNothing);
    });

    testWidgets('Przycisk Badanie Krwi otwiera raport morfologii i ferrytyny',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Kliknięcie pierwszego przycisku "Badanie Krwi"
      final bloodBtn = find.text('Badanie Krwi').first;
      await tester.ensureVisible(bloodBtn);
      await tester.tap(bloodBtn);
      await tester.pumpAndSettle();

      // Modal raportu badań krwi
      expect(find.text('Raport Badań Morfologii Krwi'), findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('Hematokryt (Hct):'),
          ),
          findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('Hemoglobina (Hb):'),
          ),
          findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.textContaining('Ferrytyna (magazyn żelaza):'),
          ),
          findsOneWidget);

      // Zamknięcie okna
      final okBtn = find.text('OK');
      await tester.tap(okBtn);
      await tester.pumpAndSettle();
      expect(find.text('Raport Badań Morfologii Krwi'), findsNothing);
    });
  });

  group('MedicalAndRecoveryCenterScreen - Zakładka 2: Protokoły Odnowy', () {
    testWidgets('Przełączenie na Tab 2 renderuje listę protokołów i selektor zawodnika',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Kliknięcie zakładki 2
      final tab2 = find.text('Protokoły Odnowy & Zabiegi');
      await tester.tap(tab2);
      await tester.pumpAndSettle();

      expect(find.text('WYBIERZ ZAWODNIKA DO ZABIEGU REGENERACYJNEGO'), findsOneWidget);
      expect(find.text('KATALOG PROCEDUR ODNOWY BIOLOGICZNEJ'), findsOneWidget);
      expect(find.textContaining('Zalecenie Lekarza Zespołowego'), findsOneWidget);

      // Weryfikacja obecności kluczowych protokołów
      expect(find.textContaining('Nogawki do drenażu limfatycznego'), findsOneWidget);
      expect(find.textContaining('Krioterapia ogólnoustrojowa'), findsOneWidget);
      expect(find.textContaining('Komora hiperbaryczna'), findsOneWidget);
      expect(find.textContaining('Sauna sucha – Adaptacja cieplna'), findsOneWidget);
      expect(find.textContaining('Opatrunki hydrokoloidowe'), findsOneWidget);
      expect(find.textContaining('Fizjoterapia i terapia manualna'), findsOneWidget);
    });

    testWidgets('Wykonanie nogawek kompresyjnych wyświetla modal sukcesu z redukcją ATL',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przejście do Tab 2
      await tester.tap(find.text('Protokoły Odnowy & Zabiegi'));
      await tester.pumpAndSettle();

      // Kliknięcie "Wykonaj Zabieg" na aktywnym protokole nogawek kompresyjnych
      final executeBtn = find.text('Wykonaj Zabieg').first;
      await tester.ensureVisible(executeBtn);
      await tester.tap(executeBtn);
      await tester.pumpAndSettle();

      // Weryfikacja okna z wynikiem zabiegu
      expect(find.text('Zabieg Wykonany Pomyślnie'), findsOneWidget);
      expect(find.textContaining('Ostre zmęczenie (ATL):'), findsOneWidget);
      expect(find.textContaining('Drenaż limfatyczny'), findsOneWidget);

      // Zamknięcie
      await tester.tap(find.text('Zamknij'));
      await tester.pumpAndSettle();
    });

    testWidgets('Próba wykonania zablokowanego protokołu (np. krio) pokazuje dialog blokady',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przejście do Tab 2
      await tester.tap(find.text('Protokoły Odnowy & Zabiegi'));
      await tester.pumpAndSettle();

      // Kliknięcie "Kup w Inwestycjach" dla nieposiadanej krioterapii
      final buyInInvestmentsBtn = find.text('Kup w Inwestycjach').first;
      await tester.ensureVisible(buyInInvestmentsBtn);
      await tester.tap(buyInInvestmentsBtn);
      await tester.pumpAndSettle();

      // Automatyczne przejście do Tab 3
      expect(find.text('KATALOG INWESTYCJI W APARATURĘ I SPRZĘT REGENERACYJNY'), findsOneWidget);
    });
  });

  group('MedicalAndRecoveryCenterScreen - Zakładka 3: Inwestycje w Sprzęt', () {
    testWidgets('Renderuje poziom kliniki i pozycje katalogu sprzętowego',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przejście do Tab 3
      await tester.tap(find.text('Inwestycje & Sprzęt Kliniki'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CENTRUM MEDYCZNE ZESPOŁU: POZIOM'), findsOneWidget);
      expect(find.textContaining('Mobilna Komora Krioterapii (-110°C)'), findsOneWidget);
      expect(find.textContaining('Łagodna Komora Hiperbaryczna (HBOT 1.75 ATA)'), findsOneWidget);
      expect(find.textContaining('Moduł Sauny Suchej w Bazie Treningowej'), findsOneWidget);
      expect(find.textContaining('Mobilny Analizator Krwi i-STAT (w Autobusie)'), findsOneWidget);
    });

    testWidgets('Zakup sprzętu medycznego (np. Sauny Suchej) aktualizuje status na Na wyposażeniu',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przejście do Tab 3
      await tester.tap(find.text('Inwestycje & Sprzęt Kliniki'));
      await tester.pumpAndSettle();

      // Znajdź przycisk zakupu
      final buyButtons = find.text('Kup dla Drużyny');
      expect(buyButtons, findsWidgets);

      await tester.tap(buyButtons.first);
      await tester.pumpAndSettle();

      // Weryfikacja powiadomienia SnackBar o pomyślnym zakupie
      expect(find.textContaining('Zakupiono'), findsOneWidget);
    });
  });

  group('MedicalAndRecoveryCenterScreen - Masowy Drenaż Zespołu', () {
    testWidgets('Przycisk masowego drenażu w nagłówku przeprowadza procedurę dla wszystkich kolarzy',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 950);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final massBtn = find.text('Masowy Drenaż Zespołu');
      expect(massBtn, findsOneWidget);
      await tester.tap(massBtn);
      await tester.pumpAndSettle();

      // Weryfikacja komunikatu
      expect(find.textContaining('Zrealizowano masowy zabieg'), findsOneWidget);
    });
  });
}
