// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/equipment/groupset_model.dart';
import 'package:pro_peloton_manager/models/equipment/tire_model.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/ui/widgets/mechanic_workshop_panel.dart';

void main() {
  const testBike = CompleteBike(
    id: 'test-bike-1',
    name: 'Pinarello Dogma F Team Issue',
    frame: FrameModel(
      id: 'frame-pinarello',
      brandId: 'pinarello',
      name: 'Dogma F',
      category: FrameCategory.allRounder,
      weightGrams: 860,
      aeroCdaModifier: -0.014,
      stiffnessToWeightIndex: 2.2,
      comfortCompliance: 0.68,
      priceEur: 5800,
      mesh3dAssetPath: 'assets/models/frame.glb',
      primaryColorHex: '#E11D48',
    ),
    wheelset: WheelsetModel(
      id: 'wheels-duraace-c50',
      brandId: 'shimano',
      name: 'Dura-Ace C50',
      rimDepthMm: 50,
      weightGrams: 1460,
      aeroCdaModifier: -0.012,
      crosswindStabilityPenalty: 0.2,
      momentOfInertia: 0.12,
      hubEngagementDragWatts: 0.4,
      priceEur: 2200,
    ),
    groupset: GroupsetModel(
      id: 'groupset-duraace-di2',
      brandId: 'shimano',
      name: 'Dura-Ace Di2 R9200',
      weightGrams: 2200,
      isElectronic: true,
      speedCount: 12,
      mechanicalEfficiency: 0.985,
      priceEur: 3800,
    ),
    tire: TireModel(
      id: 'tire-gp5000-28',
      brandId: 'continental',
      name: 'GP5000 S TR',
      widthMm: 28,
      weightGrams: 275,
      rollingResistanceCrr: 0.0035,
      punctureResistanceIndex: 4.0,
      wetGripIndex: 4.5,
      isTubeless: true,
      priceEur: 85,
    ),
    cockpitWidthMm: 380,
    hoodInwardTiltDegrees: 12.0,
    slammedStem: true,
  );

  Widget createTestWidget({
    CompleteBike? bike = testBike,
    bool isRain = false,
    SegmentSurfaceType surface = SegmentSurfaceType.roughAsphalt,
    ValueChanged<CompleteBike>? onBikeUpdated,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 1000,
          child: MechanicWorkshopPanel(
            bike: bike,
            riderWeightKg: 68.0,
            riderName: 'Jonas Vingegaard-Type',
            upcomingSurface: surface,
            isUpcomingRain: isRain,
            onBikeUpdated: onBikeUpdated,
          ),
        ),
      ),
    );
  }

  group('MechanicWorkshopPanel - Struktura i Zakładki', () {
    testWidgets('Renderuje nagłówek warsztatu z kondycją roweru i 4 zakładkami', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('WARSZTAT MECHANIKÓW I SERWIS WYŚCIGOWY'), findsOneWidget);
      expect(find.textContaining('Pinarello Dogma F Team Issue'), findsOneWidget);
      expect(find.textContaining('Jonas Vingegaard-Type (68 kg)'), findsOneWidget);

      // Weryfikacja 4 zakładek
      expect(find.text('Ciśnienie & Crr'), findsOneWidget);
      expect(find.text('Smarowanie & Wosk'), findsOneWidget);
      expect(find.text('Części & Zużycie'), findsOneWidget);
      expect(find.text('Nocna Zmiana GT'), findsOneWidget);
    });
  });

  group('MechanicWorkshopPanel - Zakładka 1: Ciśnienie w Oponach i Wykres Crr', () {
    testWidgets('Wyświetla suwaki ciśnienia, wykres Crr oraz przycisk ZASTOSUJ SILCA/SRAM', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('OPTYMALIZACJA CIŚNIENIA SILCA / SRAM'), findsOneWidget);
      expect(find.text('PRZEDNIE KOŁO (Front)'), findsOneWidget);
      expect(find.text('TYLNE KOŁO (Rear - napędzane)'), findsOneWidget);
      expect(find.text('ZASTOSUJ SILCA/SRAM'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
      expect(find.byType(CustomPaint), findsWidgets);

      // Kliknięcie w przycisk Silca/SRAM
      await tester.tap(find.text('ZASTOSUJ SILCA/SRAM'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Zastosowano zalecenia Silca/SRAM'), findsOneWidget);
    });

    testWidgets('Na bruku wyświetla ostrzeżenie o stratach impedancji (+15-25W)', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        surface: SegmentSurfaceType.cobblestonesSector4,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('UWAGA NA BRUK'), findsOneWidget);
      expect(find.textContaining('impedance losses = +15-25W!'), findsOneWidget);
    });
  });

  group('MechanicWorkshopPanel - Zakładka 2: Smarowanie Łańcucha & Wosk', () {
    testWidgets('Przełączenie na zakładkę 2 wyświetla prognozę i formuły smarowania', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(isRain: true));
      await tester.pumpAndSettle();

      // Przełączenie na drugą zakładkę
      await tester.tap(find.text('Smarowanie & Wosk'));
      await tester.pumpAndSettle();

      expect(find.text('PROGNOZA: ULEWNY DESZCZ NA JUTRZEJSZYM ETAPIE!'), findsOneWidget);
      expect(find.textContaining('All-Weather Hydrofobową'), findsOneWidget);
      expect(find.text('WYBÓR FORMUŁY SMAROWANIA / WOSKU'), findsOneWidget);

      // Wybór formuły All-Weather
      final applyButton = find.text('ZASTOSUJ TĘ FORMUŁĘ').first;
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Mechanicy wygotowali łańcuch'), findsOneWidget);
    });
  });

  group('MechanicWorkshopPanel - Zakładka 3: Części & Zużycie', () {
    testWidgets('Przełączenie na zakładkę 3 wyświetla diagnostykę łańcucha, opon i hamulców', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      CompleteBike? updatedBike;

      await tester.pumpWidget(createTestWidget(
        onBikeUpdated: (b) => updatedBike = b,
      ));
      await tester.pumpAndSettle();

      // Przełączenie na trzecią zakładkę
      await tester.tap(find.text('Części & Zużycie'));
      await tester.pumpAndSettle();

      expect(find.text('DIAGNOSTYKA CZĘŚCI I AKCJE SERWISOWE'), findsOneWidget);
      expect(find.text('PEŁNY OVERHAUL GT'), findsOneWidget);
      expect(find.text('WYMIEŃ ŁAŃCUCH'), findsOneWidget);
      expect(find.text('WYMIEŃ OPONY I ZALEJ PŁYN'), findsOneWidget);
      expect(find.text('NOWE KLOCKI & ODPOWIETRZENIE'), findsOneWidget);

      // Kliknięcie w wymianę łańcucha
      await tester.ensureVisible(find.text('WYMIEŃ ŁAŃCUCH'));
      await tester.tap(find.text('WYMIEŃ ŁAŃCUCH'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Założono fabrycznie nowy łańcuch'), findsOneWidget);
      expect(updatedBike, isNotNull);

      // Schowaj poprzedni SnackBar przed kolejnym kliknięciem
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Kliknięcie w pełny overhaul
      await tester.ensureVisible(find.text('PEŁNY OVERHAUL GT'));
      await tester.tap(find.text('PEŁNY OVERHAUL GT'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Wykonano pełny przegląd generalny'), findsOneWidget);
    });
  });

  group('MechanicWorkshopPanel - Zakładka 4: Nocna Zmiana Mechaników GT', () {
    testWidgets('Wyświetla kadrę 4 mechaników i harmonogram 8 rowerów wyścigowych', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przełączenie na czwartą zakładkę
      await tester.tap(find.text('Nocna Zmiana GT'));
      await tester.pumpAndSettle();

      expect(find.text('BILANS ROBOCZOGODZIN NOCNEJ ZMIANY'), findsOneWidget);
      expect(find.text('KADRA MECHANIKÓW W TRUCKU SERWISOWYM (4 OSOBY)'), findsOneWidget);
      expect(find.text('HARMONOGRAM SERWISU DLA 8 ROWERÓW WYŚCIGOWYCH'), findsOneWidget);

      // Mechanicy
      expect(find.text('Marek Velo'), findsOneWidget);
      expect(find.text('Johan De Smet'), findsOneWidget);
      expect(find.text('Pierre Moreau'), findsOneWidget);
      expect(find.text('Lukas Novak'), findsOneWidget);

      // Rowery
      expect(find.text('Jonas Vingegaard-Type'), findsOneWidget);
      expect(find.text('Lider Klasyfikacji Generalnej (GC)'), findsOneWidget);
    });
  });
}
