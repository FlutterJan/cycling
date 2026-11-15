// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/grand_tour_rest_day_screen.dart';

void main() {
  Widget createTestWidget({
    GrandTourType grandTourType = GrandTourType.tourDeFrance,
    RestDayStageIndex restDayIndex = RestDayStageIndex.firstRestDay,
    List<RestDayRiderCardState>? initialRiders,
    VoidCallback? onBack,
    void Function(RestDaySummaryReport report)? onProceedToNextStage,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: GrandTourRestDayScreen(
          grandTourType: grandTourType,
          restDayIndex: restDayIndex,
          initialRiders: initialRiders,
          onBack: onBack,
          onProceedToNextStage: onProceedToNextStage,
        ),
      ),
    );
  }

  group('Modele i Enums - Grand Tour Rest Day', () {
    test('GrandTourType definiuje kolory i koszulki lidera', () {
      expect(GrandTourType.tourDeFrance.title, equals('Tour de France'));
      expect(GrandTourType.tourDeFrance.leaderJersey, contains('Żółta Koszulka'));
      expect(GrandTourType.giroDItalia.title, contains('Giro'));
      expect(GrandTourType.giroDItalia.leaderJersey, contains('Różowa Koszulka'));
      expect(GrandTourType.vueltaAEspana.title, contains('Vuelta'));
      expect(GrandTourType.vueltaAEspana.leaderJersey, contains('Czerwona Koszulka'));
    });

    test('RestDayStageIndex poprawnie wskazuje numery etapów', () {
      expect(RestDayStageIndex.firstRestDay.completedStages, equals(9));
      expect(RestDayStageIndex.firstRestDay.nextStageNumber, equals(10));
      expect(RestDayStageIndex.secondRestDay.completedStages, equals(15));
      expect(RestDayStageIndex.secondRestDay.nextStageNumber, equals(16));
    });

    test('CoffeeRideProtocol określa dystans, waty i ryzyko zastygnięcia nóg', () {
      expect(CoffeeRideProtocol.primerOpenersRide.distanceKm, equals(45.0));
      expect(CoffeeRideProtocol.primerOpenersRide.legsStiffnessRiskPercent, equals(0.0));
      expect(CoffeeRideProtocol.totalBedRest.distanceKm, equals(0.0));
      expect(CoffeeRideProtocol.totalBedRest.legsStiffnessRiskPercent, greaterThan(50.0));
    });

    test('PhysiotherapyTreatment redukuje zmęczenie i ból pourazowy', () {
      expect(PhysiotherapyTreatment.wholeBodyCryotherapy.injuryPainReductionPercent, lessThan(-30.0));
      expect(PhysiotherapyTreatment.deepTissueMassage.fatigueReductionPercent, lessThan(-20.0));
    });

    test('RestDayRiderCardState copyWith działa prawidłowo', () {
      const original = RestDayRiderCardState(
        id: 'r_1',
        name: 'Tadej Pogačar',
        bibNumber: 1,
        isLeader: true,
        currentFatiguePercent: 65.0,
      );

      final modified = original.copyWith(
        currentFatiguePercent: 40.0,
        assignedTreatment: PhysiotherapyTreatment.deepTissueMassage,
      );

      expect(modified.id, equals('r_1'));
      expect(modified.currentFatiguePercent, equals(40.0));
      expect(modified.assignedTreatment, equals(PhysiotherapyTreatment.deepTissueMassage));
    });
  });

  group('GrandTourRestDayScreen - UI i Zakładki', () {
    testWidgets('Poprawnie renderuje nagłówek, etykietę I Dnia Przerwy oraz 3 zakładki', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Nagłówek
      expect(find.textContaining('Tour de France • I Dzień Przerwy (po 9. etapie)'), findsOneWidget);
      expect(find.text('Zakończ Dzień Przerwy'), findsOneWidget);

      // Zakładki
      expect(find.text('Coffee Ride (Rozjazd)'), findsOneWidget);
      expect(find.text('Konferencja Prasowa'), findsOneWidget);
      expect(find.text('Fizjoterapia i Medycyna'), findsOneWidget);
    });

    testWidgets('Zakładka Coffee Ride: wybór protokołu przejażdżki regeneracyjnej', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Dostępne protokoły
      expect(find.textContaining('Primer & Openers Ride (45 km z 3x30s zrywami)'), findsOneWidget);
      expect(find.textContaining('Klasyczny Coffee Ride (Z1 - 38 km)'), findsOneWidget);
      expect(find.textContaining('Trening Tlenowy Pomocników (Z2 - 62 km)'), findsOneWidget);
      expect(find.textContaining('Całkowity Odpoczynek w Łóżku (Day Off / Hotel Rest)'), findsOneWidget);

      // Wybór innego protokołu (np. Klasyczny Coffee Ride)
      final classicRideFinder = find.textContaining('Klasyczny Coffee Ride (Z1 - 38 km)');
      await tester.tap(classicRideFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('Zakładka Konferencja Prasowa: odpowiedź na pytania mediów', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przejście do zakładki Konferencji
      await tester.tap(find.text('Konferencja Prasowa'));
      await tester.pumpAndSettle();

      // Sprawdzenie obecności pytań mediów
      expect(find.text('Oficjalna Konferencja Prasowa UCI (Media Day)'), findsOneWidget);
      expect(find.text('ON AIR'), findsOneWidget);
      expect(find.textContaining('L\'Équipe'), findsOneWidget);

      // Wybór pierwszej odpowiedzi (Pewność Siebie)
      final answerFinder = find.textContaining('Jesteśmy w życiowej formie');
      expect(answerFinder, findsOneWidget);
      await tester.tap(answerFinder);
      await tester.pumpAndSettle();

      // Przejście do następnego pytania
      expect(find.text('Następne pytanie'), findsOneWidget);
      await tester.tap(find.text('Następne pytanie'));
      await tester.pumpAndSettle();

      expect(find.textContaining('La Gazzetta dello Sport'), findsOneWidget);
    });

    testWidgets('Zakładka Fizjoterapia i Medycyna: przydział zabiegów poobijanym kolarzom', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Przejście do zakładki Fizjoterapii
      await tester.tap(find.text('Fizjoterapia i Medycyna'));
      await tester.pumpAndSettle();

      // Sprawdzenie listy kolarzy
      expect(find.text('Tadej Pogačar'), findsOneWidget);
      expect(find.text('Rafał Majka'), findsOneWidget);
      expect(find.text('LIDER GC'), findsOneWidget);
      expect(find.textContaining('Szlify prawego biodra po kraksie na 7. etapie'), findsOneWidget);

      // Przypisanie zabiegu Krioterapii dla pierwszego kolarza
      final cryoChips = find.text('Krioterapia');
      expect(cryoChips, findsWidgets);
      await tester.tap(cryoChips.first);
      await tester.pumpAndSettle();
    });

    testWidgets('Zakończenie Dnia Przerwy otwiera dialog podsumowania i wywołuje callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      RestDaySummaryReport? reportResult;

      await tester.pumpWidget(createTestWidget(
        onProceedToNextStage: (report) => reportResult = report,
      ));
      await tester.pumpAndSettle();

      // Kliknięcie w przycisk "Zakończ Dzień Przerwy"
      final finishButton = find.widgetWithText(ElevatedButton, 'Zakończ Dzień Przerwy');
      expect(finishButton, findsOneWidget);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      // Sprawdzenie dialogu podsumowania
      expect(find.text('Dzień Przerwy Zakończony!'), findsOneWidget);
      expect(find.textContaining('Średnia regeneracja zmęczenia:'), findsOneWidget);

      // Przejście na następny etap
      final proceedButton = find.text('Wyrusz na Etap 10');
      expect(proceedButton, findsOneWidget);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();

      expect(reportResult, isNotNull);
      expect(reportResult!.primaryCoffeeRide, equals(CoffeeRideProtocol.primerOpenersRide));
      expect(reportResult!.averageFatigueReduction, greaterThan(20.0));
    });

    testWidgets('Kliknięcie przycisku wstecz wywołuje onBack', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      var backCalled = false;

      await tester.pumpWidget(createTestWidget(
        onBack: () => backCalled = true,
      ));
      await tester.pumpAndSettle();

      final backIcon = find.byIcon(Icons.arrow_back);
      expect(backIcon, findsOneWidget);
      await tester.tap(backIcon);
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });
  });
}

