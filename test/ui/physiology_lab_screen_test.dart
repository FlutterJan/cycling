// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/physiology_lab_screen.dart';

void main() {
  Widget createTestWidget({
    String? initialRiderId,
    bool showAppBar = true,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: PhysiologyLabScreen(
          initialRiderId: initialRiderId,
          showAppBar: showAppBar,
        ),
      ),
    );
  }

  group('PhysiologyLabScreen Widget Tests', () {
    testWidgets('Renders app bar, hero metrics, tabs and lactate chart correctly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Weryfikacja nagłówka i tytułu
      expect(find.text('Laboratorium Wydolnościowe'), findsOneWidget);
      expect(
        find.text('Ergospirometria CPET & Kinetyka Mleczanowa (Ramp Test 100W, +30W/3min)'),
        findsOneWidget,
      );
      expect(find.text('Zleć Nowe Badanie'), findsOneWidget);

      // Weryfikacja 4 głównych kart metryk fizjologicznych
      expect(find.text('PRÓG TLENOWY (LT₁ / FatMax)'), findsOneWidget);
      expect(find.text('PRÓG BEZTLENOWY (LT₂ / MLSS)'), findsOneWidget);
      expect(find.text('PUŁAP TLENOWY (VO₂max)'), findsOneWidget);
      expect(find.text('GLIKOLIZA (VLaMax)'), findsOneWidget);

      // Weryfikacja przełączników jednostek i serii telemetrycznych
      expect(find.text('Waty [W]'), findsOneWidget);
      expect(find.text('W/kg'), findsOneWidget);
      expect(find.text('Mleczan [La] (mmol/l)'), findsOneWidget);
      expect(find.text('Tętno HR (bpm)'), findsOneWidget);
      expect(find.text('Wentylacja VE (l/min)'), findsOneWidget);
      expect(find.text('Pobór VO₂ (ml/kg/min)'), findsOneWidget);

      // Weryfikacja zakładek
      expect(find.text('Porównanie z Poprzednich Miesięcy'), findsOneWidget);
      expect(find.text('Tabela Stopni Ramp Test (100W, +30W/3min)'), findsOneWidget);
      expect(find.text('Strefy Treningowe Z1-Z7'), findsOneWidget);
    });

    testWidgets('Toggles telemetry series chips and units on Lactate Curve Chart', (tester) async {
      tester.view.physicalSize = const Size(1920, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przełącznik jednostek Waty [W] <-> W/kg
      final wKgButton = find.text('W/kg');
      expect(wKgButton, findsOneWidget);
      await tester.tap(wKgButton);
      await tester.pumpAndSettle();

      // Przełączenie z powrotem na Waty [W]
      final wattsButton = find.text('Waty [W]');
      expect(wattsButton, findsOneWidget);
      await tester.tap(wattsButton);
      await tester.pumpAndSettle();

      // Wyłączenie i włączenie serii tętna
      final hrChip = find.text('Tętno HR (bpm)');
      expect(hrChip, findsOneWidget);
      await tester.tap(hrChip);
      await tester.pumpAndSettle();

      // Włączenie serii wentylacji VE
      final veChip = find.text('Wentylacja VE (l/min)');
      await tester.tap(veChip);
      await tester.pumpAndSettle();

      // Włączenie serii tlenu VO2
      final vo2Chip = find.text('Pobór VO₂ (ml/kg/min)');
      await tester.tap(vo2Chip);
      await tester.pumpAndSettle();
    });

    testWidgets('Switching tabs displays Protocol Steps Table and Training Zones', (tester) async {
      tester.view.physicalSize = const Size(1920, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przełączenie na zakładkę 2: "Tabela Stopni Ramp Test (100W, +30W/3min)"
      final tableTab = find.text('Tabela Stopni Ramp Test (100W, +30W/3min)');
      await tester.ensureVisible(tableTab);
      await tester.tap(tableTab);
      await tester.pumpAndSettle();

      // Sprawdzenie nagłówków tabeli prób wysiłkowych
      expect(find.text('KROK'), findsOneWidget);
      expect(find.text('CZAS'), findsOneWidget);
      expect(find.text('MOC (W/kg)'), findsOneWidget);
      expect(find.text('MLECZAN'), findsOneWidget);
      expect(find.text('TĘTNO'), findsOneWidget);
      expect(find.text('VE [l/min]'), findsOneWidget);
      expect(find.text('VO₂ [ml]'), findsOneWidget);
      expect(find.text('RER'), findsOneWidget);
      expect(find.text('SPALANIE (W/T)'), findsOneWidget);

      // Pierwszy krok próby powinien wynosić 100 W
      expect(find.textContaining('100W'), findsWidgets);

      // Przełączenie na zakładkę 3: "Strefy Treningowe Z1-Z7"
      final zonesTab = find.text('Strefy Treningowe Z1-Z7');
      await tester.ensureVisible(zonesTab);
      await tester.tap(zonesTab);
      await tester.pumpAndSettle();

      // Sprawdzenie obecności stref Z1-Z7
      expect(find.text('Z1'), findsOneWidget);
      expect(find.text('Z2'), findsOneWidget);
      expect(find.text('Z4'), findsOneWidget);
      expect(find.text('Z7'), findsOneWidget);
      expect(find.textContaining('Regeneracja Aktywna'), findsOneWidget);
      expect(find.textContaining('Moc Nerwowo-Mięśniowa'), findsOneWidget);
    });

    testWidgets('Selecting another rider updates lab report and metrics', (tester) async {
      tester.view.physicalSize = const Size(1920, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Na liście kolarzy powinni być zawodnicy
      final cards = find.byType(InkWell);
      expect(cards, findsWidgets);

      // Klikamy w kolejnego zawodnika w poziomym pasku
      await tester.tap(cards.at(1));
      await tester.pumpAndSettle();

      // Ekran powinien się odświeżyć bez błędów
      expect(find.text('Laboratorium Wydolnościowe'), findsOneWidget);
    });

    testWidgets('Clicking Zleć Nowe Badanie opens modal and executes test', (tester) async {
      tester.view.physicalSize = const Size(1920, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final orderButton = find.text('Zleć Nowe Badanie');
      expect(orderButton, findsOneWidget);

      await tester.tap(orderButton);
      await tester.pumpAndSettle();

      // Weryfikacja modala
      expect(find.text('Zlecenie Badania Laboratoryjnego'), findsOneWidget);
      expect(find.text('Koszt Badania:'), findsOneWidget);
      expect(find.text('€450'), findsOneWidget);
      expect(find.text('Rozpocznij Badanie'), findsOneWidget);

      // Kliknięcie w przycisk wykonania badania
      final startTestButton = find.text('Rozpocznij Badanie');
      await tester.tap(startTestButton);
      await tester.pumpAndSettle();

      // Modal powinien się zamknąć, a na ekranie pojawia się SnackBar o sukcesie
      expect(find.textContaining('Badanie ukończone dla'), findsOneWidget);
    });

    testWidgets('Changing comparison period updates historical delta metrics', (tester) async {
      tester.view.physicalSize = const Size(1920, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Domyślnie wybrany okres Sierra Nevada
      expect(find.text('Przed Obozem w Sierra Nevada (45 dni temu)'), findsWidgets);

      // Otwórz dropdown wyboru okresu porównawczego
      final periodDropdown = find.text('Przed Obozem w Sierra Nevada (45 dni temu)').first;
      await tester.tap(periodDropdown);
      await tester.pumpAndSettle();

      // Wybierz "Screening Przedsezonowy (90 dni temu)"
      final option = find.text('Screening Przedsezonowy (90 dni temu)').last;
      await tester.tap(option);
      await tester.pumpAndSettle();

      // Weryfikacja aktualizacji stanu
      expect(find.text('Screening Przedsezonowy (90 dni temu)'), findsWidgets);
    });
  });
}
