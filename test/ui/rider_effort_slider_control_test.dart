// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_effort_slider_control.dart';

void main() {
  group('RiderEffortSliderControl - Kontroler Wysiłku i Aerodynamiki', () {
    Widget buildTestControl({
      double initialEffort = 90.0,
      RiderAeroPosition initialPosition = RiderAeroPosition.standard,
      int ftpWatts = 400,
      double weightKg = 68.0,
      String? riderName = 'T. Pogačar',
      String? teamCode = 'UAD',
      ValueChanged<double>? onEffortChanged,
      ValueChanged<RiderAeroPosition>? onPositionChanged,
      ValueChanged<RiderEffortSettings>? onSettingsChanged,
      bool isCompact = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              child: RiderEffortSliderControl(
                initialEffortPercent: initialEffort,
                initialAeroPosition: initialPosition,
                riderFtpWatts: ftpWatts,
                riderWeightKg: weightKg,
                riderName: riderName,
                teamCode: teamCode,
                onEffortChanged: onEffortChanged,
                onPositionChanged: onPositionChanged,
                onSettingsChanged: onSettingsChanged,
                isCompact: isCompact,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renderuje nagłówek, odczyt mocy i progi fizjologiczne LT1, LT2, VO2max', (tester) async {
      await tester.pumpWidget(buildTestControl(
        initialEffort: 100.0,
        ftpWatts: 400,
        weightKg: 68.0,
      ));
      await tester.pumpAndSettle();

      // Nagłówek i zawodnik
      expect(find.textContaining('T. Pogačar (UAD)'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('FTP'), findsOneWidget);
      expect(find.textContaining('400 W • 5.9 W/kg'), findsOneWidget);

      // Progi fizjologiczne na skali
      expect(find.text('LT₁ (75%)'), findsOneWidget);
      expect(find.text('LT₂/FTP (100%)'), findsOneWidget);
      expect(find.text('VO₂max (115%)'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('120%'), findsOneWidget);

      // Presety progowe
      expect(find.text('75% LT₁ (Tlen)'), findsOneWidget);
      expect(find.text('90% Tempo'), findsOneWidget);
      expect(find.text('100% LT₂ (FTP)'), findsOneWidget);
      expect(find.text('115% VO₂max'), findsOneWidget);

      // Trzy wymagane pozycje aerodynamiczne
      expect(find.text('Standardowa'), findsOneWidget);
      expect(find.text('Agresywna Aero (kosztem sterowności)'), findsOneWidget);
      expect(find.text('Maksymalna oszczędność energii w peletonie'), findsOneWidget);
    });

    testWidgets('klikanie w presety progowe aktualizuje intensywność i wywołuje callbacki', (tester) async {
      double? changedEffort;
      RiderEffortSettings? changedSettings;

      await tester.pumpWidget(buildTestControl(
        initialEffort: 90.0,
        ftpWatts: 400,
        onEffortChanged: (val) => changedEffort = val,
        onSettingsChanged: (s) => changedSettings = s,
      ));
      await tester.pumpAndSettle();

      // Kliknięcie w preset LT1 (75%)
      await tester.tap(find.byKey(const Key('preset_lt1')));
      await tester.pumpAndSettle();

      expect(changedEffort, equals(75.0));
      expect(changedSettings?.effortPercentFtp, equals(75.0));
      expect(changedSettings?.targetWatts, equals(300)); // 400 * 0.75 = 300 W
      expect(find.text('75%'), findsOneWidget);
      expect(find.textContaining('300 W'), findsOneWidget);

      // Kliknięcie w preset VO2max (115%)
      await tester.tap(find.byKey(const Key('preset_vo2max')));
      await tester.pumpAndSettle();

      expect(changedEffort, equals(115.0));
      expect(changedSettings?.effortPercentFtp, equals(115.0));
      expect(changedSettings?.targetWatts, equals(460)); // 400 * 1.15 = 460 W
      expect(find.text('115%'), findsOneWidget);
      expect(find.textContaining('460 W'), findsOneWidget);

      // Powyżej 100% FTP wyświetla się ostrzeżenie o drenażu W'
      expect(find.textContaining("Pobór z beztlenowej rezerwy W'"), findsOneWidget);
    });

    testWidgets('przyciski mikro-kroku [-1%] i [+1%] precyzyjnie zmieniają waty', (tester) async {
      double? currentEffort;

      await tester.pumpWidget(buildTestControl(
        initialEffort: 95.0,
        onEffortChanged: (val) => currentEffort = val,
      ));
      await tester.pumpAndSettle();

      // Krok w dół o 1%
      await tester.tap(find.byKey(const Key('button_step_minus')));
      await tester.pumpAndSettle();

      expect(currentEffort, equals(94.0));
      expect(find.text('94%'), findsOneWidget);

      // Krok w górę o 1% dwukrotnie
      await tester.tap(find.byKey(const Key('button_step_plus')));
      await tester.pumpAndSettle();
      expect(currentEffort, equals(95.0));

      await tester.tap(find.byKey(const Key('button_step_plus')));
      await tester.pumpAndSettle();
      expect(currentEffort, equals(96.0));
      expect(find.text('96%'), findsOneWidget);
    });

    testWidgets('przełącznik pozycji aerodynamicznej zmienia tryby i parametry CdA', (tester) async {
      RiderAeroPosition? selectedPosition;
      RiderEffortSettings? lastSettings;

      await tester.pumpWidget(buildTestControl(
        initialPosition: RiderAeroPosition.standard,
        onPositionChanged: (pos) => selectedPosition = pos,
        onSettingsChanged: (s) => lastSettings = s,
      ));
      await tester.pumpAndSettle();

      // Wybór pozycji "Agresywna Aero (kosztem sterowności)"
      await tester.tap(find.byKey(const Key('position_aggressive_aero')));
      await tester.pumpAndSettle();

      expect(selectedPosition, equals(RiderAeroPosition.aggressiveAero));
      expect(lastSettings?.aeroPosition, equals(RiderAeroPosition.aggressiveAero));
      expect(selectedPosition!.cdaMultiplier, closeTo(0.86, 0.01));
      expect(selectedPosition!.handlingFactor, closeTo(0.72, 0.01));

      // Wybór pozycji "Maksymalna oszczędność energii w peletonie"
      await tester.tap(find.byKey(const Key('position_peloton_shelter')));
      await tester.pumpAndSettle();

      expect(selectedPosition, equals(RiderAeroPosition.pelotonShelter));
      expect(lastSettings?.aeroPosition, equals(RiderAeroPosition.pelotonShelter));
      expect(selectedPosition!.draftingBonus, closeTo(0.22, 0.01));

      // Powrót do pozycji standardowej
      await tester.tap(find.byKey(const Key('position_standard')));
      await tester.pumpAndSettle();

      expect(selectedPosition, equals(RiderAeroPosition.standard));
      expect(selectedPosition!.handlingFactor, equals(1.0));
      expect(selectedPosition!.cdaMultiplier, equals(1.0));
    });

    testWidgets('klasyfikacja stref fizjologicznych i wskaźniki metabolizmu', (tester) async {
      // 1. Strefa Z2 (Baza tlenowa - LT1)
      await tester.pumpWidget(buildTestControl(initialEffort: 70.0));
      await tester.pumpAndSettle();

      expect(find.textContaining('Baza tlenowa - LT₁ (Z2)'), findsOneWidget);
      expect(find.textContaining('FatMax'), findsWidgets);

      // 2. Strefa Z4 (Próg mleczanowy - LT2/FTP)
      await tester.pumpWidget(buildTestControl(initialEffort: 100.0));
      await tester.pumpAndSettle();

      expect(find.textContaining('Próg mleczanowy - LT₂ / FTP (Z4)'), findsOneWidget);
      expect(find.textContaining('MLSS'), findsWidgets);

      // 3. Strefa Z5 (VO2max)
      await tester.pumpWidget(buildTestControl(initialEffort: 120.0));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pułap tlenowy - VO₂max (Z5)'), findsOneWidget);
      expect(find.textContaining("W'"), findsWidgets);
    });

    test('model RiderEffortSettings poprawnie wyznacza waty i W/kg', () {
      const settings = RiderEffortSettings(
        effortPercentFtp: 105.0,
        aeroPosition: RiderAeroPosition.aggressiveAero,
        riderFtpWatts: 420,
        riderWeightKg: 70.0,
      );

      expect(settings.targetWatts, equals(441)); // 420 * 1.05 = 441 W
      expect(settings.wattsPerKg, closeTo(6.30, 0.01)); // 441 / 70 = 6.30 W/kg
      expect(settings.isAboveFtp, isTrue);
      expect(settings.zone, equals(PhysiologicalZone.thresholdLt2));
    });
  });
}
