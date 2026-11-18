import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/grand_tour_route_reveal_ceremony_screen.dart';

void main() {
  Widget buildTestApp({
    required Size size,
    List<GrandTourRouteRevealEdition>? editions,
    bool revealAllInitially = false,
    ValueChanged<Map<GrandTourId, GrandTourCeremonyPlanEntry>>?
        onCeremonyCompleted,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: GrandTourRouteRevealCeremonyScreen(
            editions: editions,
            teamNameOverride: 'Polonia Pro Cycling',
            leaderCandidatesOverride: const [
              'M. Kwiatkowski',
              'R. Majka',
              'S. Aniołkowski',
            ],
            revealAllInitially: revealAllInitially,
            onCeremonyCompleted: onCeremonyCompleted,
          ),
        ),
      ),
    );
  }

  Future<void> pumpViewport(
    WidgetTester tester,
    Size size, {
    List<GrandTourRouteRevealEdition>? editions,
    bool revealAllInitially = false,
    ValueChanged<Map<GrandTourId, GrandTourCeremonyPlanEntry>>?
        onCeremonyCompleted,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        size: size,
        editions: editions,
        revealAllInitially: revealAllInitially,
        onCeremonyCompleted: onCeremonyCompleted,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('GrandTourRouteRevealCatalog unit tests', () {
    test('generates 3 Grand Tours with 21 stages and valid totals', () {
      final reveals = GrandTourRouteRevealCatalog.generateNextSeasonReveals(
        editionYear: 2028,
      );

      expect(reveals.length, 3);
      for (final edition in reveals) {
        expect(edition.editionYear, 2028);
        expect(edition.stages.length, 21);
        expect(edition.totalDistanceKm, greaterThan(3000));
        expect(edition.totalElevationGainM, greaterThan(40000));
        expect(edition.queenStage, isNotNull);
        expect(edition.queenStage!.isQueenStage, isTrue);
      }
    });
  });

  group('GrandTourRouteRevealCeremonyScreen responsive & interaction tests',
      () {
    testWidgets('renders without overflow on mobile 390x844', (tester) async {
      await pumpViewport(tester, const Size(390, 844));

      expect(find.textContaining('CEREMONIA PREZENTACJI TRAS'), findsOneWidget);
      expect(find.text('Tour de France 2027'), findsOneWidget);
      expect(find.text('21 Etapów'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on tablet 1024x768', (tester) async {
      await pumpViewport(tester, const Size(1024, 768));

      expect(find.textContaining('CEREMONIA PREZENTACJI TRAS'), findsOneWidget);
      expect(find.text('PANORAMA 21 ETAPÓW (KLIKNIJ ETAP)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on desktop 1600x900', (tester) async {
      await pumpViewport(tester, const Size(1600, 900));

      expect(find.textContaining('CEREMONIA PREZENTACJI TRAS'), findsOneWidget);
      expect(find.text('HARMONOGRAM 21 ETAPÓW'), findsOneWidget);
      expect(find.text('DEKLARACJA CELU NA PRZYSZŁY SEZON'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'supports revealing tours, filtering stages, confirming plan, and completing ceremony',
      (tester) async {
        Map<GrandTourId, GrandTourCeremonyPlanEntry>? completedPlans;
        await pumpViewport(
          tester,
          const Size(1600, 900),
          onCeremonyCompleted: (plans) => completedPlans = plans,
        );

        expect(
          find.textContaining('Odsłonięto 1/3 • Zatwierdzono 0/3'),
          findsOneWidget,
        );

        await tester.tap(find.text("Giro d'Italia").first);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text("Giro d'Italia 2027"), findsOneWidget);
        expect(find.text('Odsłoń Trasę GIRO').first, isNotNull);

        await tester.tap(find.text('Odsłoń Trasę GIRO').first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.textContaining('Odsłonięto 2/3 • Zatwierdzono 0/3'),
          findsOneWidget,
        );

        await tester.tap(find.text('Czasówki'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Radda in Chianti → Greve in Chianti'), findsOneWidget);

        final confirmFinder = find.text('Zatwierdź Plan na GIRO');
        await tester.ensureVisible(confirmFinder);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(confirmFinder);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('ZATWIERDZONO'), findsOneWidget);
        expect(
          find.textContaining('Odsłonięto 2/3 • Zatwierdzono 1/3'),
          findsOneWidget,
        );

        await tester.tap(find.text('Odsłoń Wszystkie'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          find.textContaining('Odsłonięto 3/3 • Zatwierdzono 1/3'),
          findsOneWidget,
        );

        await tester.tap(find.text('Zakończ Ceremonię'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(completedPlans, isNotNull);
        expect(completedPlans!.length, 3);
        expect(completedPlans![GrandTourId.giroDItalia]!.isConfirmed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('handles empty editions list gracefully', (tester) async {
      await pumpViewport(
        tester,
        const Size(1024, 768),
        editions: const [],
      );

      expect(
        find.text('BRAK PREZENTACJI TRAS WIELKICH TOURÓW'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
