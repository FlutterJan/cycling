import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/gravel_bike_and_tire_inserts_model.dart';
import 'package:pro_peloton_manager/ui/screens/gravel_world_series_hub_screen.dart';

void main() {
  group('GravelWorldSeriesCalendarCatalog & GravelOasisPlannerCalculator', () {
    test('catalog contains 7 season rounds with Oasis zones', () {
      final calendar = GravelWorldSeriesCalendarCatalog.buildSeasonCalendar();
      expect(calendar, hasLength(7));
      expect(
        calendar.where((r) => r.isWorldChampionship),
        hasLength(1),
      );
      expect(
        calendar.where((r) => r.isUltraGravel),
        hasLength(3),
      );
      for (final race in calendar) {
        expect(race.oasisZones, isNotEmpty);
        expect(race.raceModel.totalDistanceKm, greaterThan(100.0));
      }
    });

    test('Oasis planner detects dehydration risk when skipping stops on Unbound 200',
        () {
      final unbound = GravelWorldSeriesCalendarCatalog.buildSeasonCalendar()
          .firstWhere((r) => r.id == 'unbound_gravel_200');
      const calculator = GravelOasisPlannerCalculator();
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();

      final skipAllPlan = calculator.evaluatePlan(
        race: unbound.raceModel,
        oasisZones: unbound.oasisZones,
        selectedPriorities: {
          for (final z in unbound.oasisZones)
            z.id: GravelOasisServicePriority.skipNonStop,
        },
        bikeSetup: setup,
        targetSpeedKmh: 28.0,
      );

      expect(skipAllPlan.activeStopCount, 0);
      expect(skipAllPlan.totalStopTimeSeconds, 0);
      expect(skipAllPlan.hasDehydrationRisk, isTrue);

      final fullRefillPlan = calculator.evaluatePlan(
        race: unbound.raceModel,
        oasisZones: unbound.oasisZones,
        selectedPriorities: {
          for (final z in unbound.oasisZones)
            z.id: GravelOasisServicePriority.fullHydrationRefill,
        },
        bikeSetup: GravelBikeAndTireInsertsModel.flintHillsUltraPreset(),
        targetSpeedKmh: 28.0,
      );

      expect(fullRefillPlan.activeStopCount, unbound.oasisZones.length);
      expect(fullRefillPlan.totalStopTimeSeconds, greaterThan(0));
      expect(fullRefillPlan.totalFluidRefilledMl, greaterThan(2000.0));
      expect(fullRefillPlan.hasDehydrationRisk, isFalse);
    });
  });

  group('GravelWorldSeriesHubScreen widget & responsiveness', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size,
      Widget child,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: child));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile and switches tabs', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(
        tester,
        const Size(390, 844),
        const GravelWorldSeriesHubScreen(),
      );

      expect(find.text('GRAVEL WORLD SERIES HUB'), findsOneWidget);
      expect(find.text('Kalendarz'), findsOneWidget);
      expect(find.text('Opony 40–50 mm'), findsOneWidget);
      expect(find.text('Strefy Oasis'), findsOneWidget);

      await tester.tap(find.text('Opony 40–50 mm'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Konfigurator Opon 40–50 mm'), findsOneWidget);

      await tester.tap(find.text('Strefy Oasis'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Strefy Oasis & Nawadnianie'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        const GravelWorldSeriesHubScreen(),
      );

      expect(find.text('Kalendarz Gravel World Series'), findsOneWidget);
      expect(find.text('Konfigurator Opon 40–50 mm'), findsOneWidget);

      await tester.tap(find.text('Strefy Oasis'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Strefy Oasis & Nawadnianie'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders 3-column bento at 1600x900 desktop and updates 40-50mm & Oasis',
      (WidgetTester tester) async {
        GravelSeriesRaceEntry? appliedRace;
        GravelBikeAndTireInsertsModel? appliedSetup;
        GravelOasisPlanSummary? appliedOasis;

        await pumpAtSize(
          tester,
          const Size(1600, 900),
          GravelWorldSeriesHubScreen(
            onApplyConfiguration: (race, setup, oasis) {
              appliedRace = race;
              appliedSetup = setup;
              appliedOasis = oasis;
            },
          ),
        );

        expect(find.text('Kalendarz Gravel World Series'), findsOneWidget);
        expect(find.text('Konfigurator Opon 40–50 mm'), findsOneWidget);
        expect(find.text('Strefy Oasis & Nawadnianie'), findsOneWidget);

        // Wybierz oponę 50 mm i sprawdź walidację prześwitu ramy 48 mm.
        await tester.tap(find.text('50 mm'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.textContaining('Przekroczono prześwit ramy'),
          findsOneWidget,
        );

        // Zmień ramę na Cutthroat 52 (Max 52 mm).
        await tester.tap(find.text('Cutthroat 52 (Max 52 mm)'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.textContaining('Przekroczono prześwit ramy'),
          findsNothing,
        );

        // Zoptymalizuj ciśnienie i zapisz setup.
        await tester.tap(find.text('Optymalizuj BAR'));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Zapisz Setup'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(appliedRace, isNotNull);
        expect(appliedSetup?.frontTire.widthMm, 50.0);
        expect(appliedOasis, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('respects isReadOnly disabled state', (
      WidgetTester tester,
    ) async {
      await pumpAtSize(
        tester,
        const Size(1600, 900),
        const GravelWorldSeriesHubScreen(
          isReadOnly: true,
          initialTireWidthMm: 44.0,
        ),
      );

      await tester.tap(find.text('50 mm'));
      await tester.pump(const Duration(milliseconds: 300));

      // W trybie read-only szerokość pozostaje 44 mm.
      expect(find.text('44 mm'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
