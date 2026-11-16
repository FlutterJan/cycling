import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/season_awards_velo_dor_ceremony.dart';
import 'package:pro_peloton_manager/ui/screens/velo_dor_gala_ceremony_screen.dart';

void main() {
  Widget buildTestApp({
    required Size size,
    VeloDorCeremonyReport? report,
    VeloDorPlayerSeasonSummary? playerSummary,
    VoidCallback? onProceedToOffseason,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: VeloDorGalaCeremonyScreen(
            report: report ??
                SeasonAwardsVeloDorCeremony.generateSampleCeremonyReport(),
            playerSummary: playerSummary,
            onProceedToOffseason: onProceedToOffseason,
          ),
        ),
      ),
    );
  }

  Future<void> pumpViewport(
    WidgetTester tester,
    Size size, {
    VeloDorCeremonyReport? report,
    VoidCallback? onProceedToOffseason,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildTestApp(
        size: size,
        report: report,
        onProceedToOffseason: onProceedToOffseason,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('VeloDorGalaCeremonyScreen responsive & interaction tests', () {
    testWidgets('renders without overflow on mobile 390x844', (tester) async {
      await pumpViewport(tester, const Size(390, 844));

      expect(find.textContaining("GALA VÉLO D'OR"), findsOneWidget);
      expect(find.text('PODSUMOWANIE DRUŻYNY GRACZA'), findsOneWidget);
      expect(find.text("PEŁNA LISTA LAUREATÓW VÉLO D'OR"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on tablet 1024x768', (tester) async {
      await pumpViewport(tester, const Size(1024, 768));

      expect(find.textContaining("GALA VÉLO D'OR"), findsOneWidget);
      expect(
        find.text('STATYSTYKI Z CAŁEGO ROKU & GŁOSY JURY'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow on desktop 1600x900', (tester) async {
      await pumpViewport(tester, const Size(1600, 900));

      expect(find.textContaining("GALA VÉLO D'OR"), findsOneWidget);
      expect(find.text('PODSUMOWANIE DRUŻYNY GRACZA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'supports category switching, presenting statuettes, and finishing gala',
      (tester) async {
        bool proceeded = false;
        await pumpViewport(
          tester,
          const Size(1600, 900),
          onProceedToOffseason: () => proceeded = true,
        );

        expect(find.text('0/5 Statuetek'), findsOneWidget);

        await tester.tap(find.text("Wręcz Statuetkę Vélo d'Or"));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('1/5 Statuetek'), findsOneWidget);
        expect(find.text('STATUETKA WRĘCZONA'), findsOneWidget);

        await tester.tap(find.text('Góral Roku').first);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Najlepszy Góral Roku'), findsOneWidget);

        await tester.tap(find.text('Wręcz Wszystkie'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('5/5 Statuetek'), findsOneWidget);

        await tester.tap(find.text('Zakończ Galę i Przejdź Dalej'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(proceeded, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('handles empty ceremony report gracefully', (tester) async {
      final emptyReport = VeloDorCeremonyReport(
        seasonYear: 2027,
        ceremonyDate: DateTime(2027, 10, 29, 20, 0),
        venue: 'Pavillon Gabriel, Paryż',
        isOfficialLateOctoberWindow: true,
        categoryResults: const {},
        playerTeamAwardsWon: 0,
        playerTeamPrestigeGain: 0,
        playerTeamMoraleBoost: 0,
      );

      await pumpViewport(
        tester,
        const Size(1024, 768),
        report: emptyReport,
      );

      expect(
        find.text('Brak nominowanych w tej kategorii plebiscytu.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
