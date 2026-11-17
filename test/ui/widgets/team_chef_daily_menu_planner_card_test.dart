import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/team_chef_daily_menu_planner_card.dart';

void main() {
  Widget buildTestHarness({required Size size}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: TeamChefDailyMenuPlannerCard(),
            ),
          ),
        ),
      ),
    );
  }

  group('TeamChefDailyMenuPlannerCard', () {
    testWidgets('renderuje się poprawnie w 390x844 (mobile) bez przepełnienia',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestHarness(size: const Size(390, 844)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Planer Posiłków i Bilansu Energetycznego'),
        findsOneWidget,
      );
      expect(find.text('Śr. Glikogen'), findsOneWidget);
      expect(find.text('Mikrobiom Jelit'), findsOneWidget);
    });

    testWidgets('renderuje się poprawnie w 1024x768 (tablet) bez przepełnienia',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestHarness(size: const Size(1024, 768)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Harmonogram Posiłków Dnia (5 Pór Żywienia)'),
        findsOneWidget,
      );
      expect(find.text('Bilans Energetyczny Dnia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie w 1600x900 (desktop) bez przepełnienia',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestHarness(size: const Size(1600, 900)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Kolarze Drużyny (Wybierz do Planowania Menu)'),
        findsOneWidget,
      );
      expect(find.text('Makroskładniki Dnia'), findsOneWidget);
      expect(find.text('Prognoza Regeneracji Nocnej'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'obsługuje przełączanie trybu Dnia Przerwy, pór posiłków, strategii i zatwierdzenia',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var committed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TeamChefDailyMenuPlannerCard(
                  onMenuCommitted: () => committed = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Przełącz na Dzień Przerwy
      await tester.tap(find.text('Tryb: Etap'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tryb: Dzień Przerwy'), findsOneWidget);

      // Przełącz porę posiłku na Śniadanie
      await tester.tap(find.text('Śniadanie'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Śniadanie Przedstartowe (-3h)'), findsOneWidget);

      // Uruchom Auto-Optymalizację
      await tester.tap(find.text('Auto-Optymalizuj'));
      await tester.pump(const Duration(milliseconds: 300));

      // Zatwierdź jadłospis
      await tester.tap(find.text('Zatwierdź Jadłospis'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(committed, isTrue);
      expect(find.text('Zatwierdzono'), findsNothing);
      expect(find.text('Zatwierdź Jadłospis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
