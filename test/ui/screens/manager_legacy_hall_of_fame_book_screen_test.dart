import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/end_of_career_hall_of_fame_retirement_mode.dart';
import 'package:pro_peloton_manager/ui/screens/manager_legacy_hall_of_fame_book_screen.dart';

void main() {
  Widget buildTestApp({
    required Size size,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const ManagerLegacyHallOfFameBookScreen(),
        ),
      ),
    );
  }

  group('ManagerLegacyHallOfFameBookScreen', () {
    testWidgets('renders cleanly on mobile 390x844 and toggles book sides',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(size: const Size(390, 844)));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Księga Legendy Menedżera'), findsOneWidget);
      expect(find.text('Złota Księga Legendy Kolarskiej'), findsOneWidget);
      expect(find.text('Strona I: Pieczęć i Wynik'), findsOneWidget);
      expect(find.text('Strona II: Palmares i Tablice'), findsOneWidget);

      await tester.ensureVisible(find.text('Strona II: Palmares i Tablice'));
      await tester.tap(find.text('Strona II: Palmares i Tablice'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PALMARES HISTORYCZNE'), findsOneWidget);
      expect(find.text('ZŁOTE TABLICE CHWAŁY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders two-page spread on tablet 1024x768', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(size: const Size(1024, 768)));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('INSKRYPCJA W ZŁOCIE'), findsOneWidget);
      expect(find.text('PALMARES HISTORYCZNE'), findsOneWidget);
      expect(find.text('ZŁOTE TABLICE CHWAŁY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on desktop 1600x900 and switches to Dynasty NG+ tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(size: const Size(1600, 900)));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Panteon i Dynastia NG+'), findsOneWidget);
      await tester.tap(find.text('Panteon i Dynastia NG+'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EndOfCareerHallOfFameRetirementPanel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search filter shows empty state and resets cleanly',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(size: const Size(1280, 800)));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.enterText(
        find.byType(TextField),
        'NieistniejącyMenedżerXYZ',
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('Brak wpisów spełniających wybrane kryteria'),
        findsOneWidget,
      );

      await tester.tap(find.text('Przywróć domyślny widok Księgi'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('INSKRYPCJA W ZŁOCIE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
