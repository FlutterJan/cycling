import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/ui/widgets/grand_tour_jersey_point_rules_modal.dart';

void main() {
  group('GrandTourPointRulesCatalog', () {
    test('calculates OTL time cut percentages matching engine rules', () {
      expect(
        GrandTourPointRulesCatalog.calculateTimeCutPercent(
          stageType: StageType.flat,
          winnerSpeedKmh: 42.0,
        ),
        6.0,
      );
      expect(
        GrandTourPointRulesCatalog.calculateTimeCutPercent(
          stageType: StageType.flat,
          winnerSpeedKmh: 46.0,
        ),
        9.0,
      );
      expect(
        GrandTourPointRulesCatalog.calculateTimeCutPercent(
          stageType: StageType.flat,
          winnerSpeedKmh: 49.5,
        ),
        11.0,
      );
      expect(
        GrandTourPointRulesCatalog.calculateTimeCutPercent(
          stageType: StageType.hilly,
          winnerSpeedKmh: 40.0,
        ),
        12.0,
      );
      expect(
        GrandTourPointRulesCatalog.calculateTimeCutPercent(
          stageType: StageType.highMountain,
          winnerSpeedKmh: 39.0,
        ),
        18.0,
      );
      expect(
        GrandTourPointRulesCatalog.calculateTimeCutPercent(
          stageType: StageType.individualTimeTrial,
          winnerSpeedKmh: 52.0,
        ),
        25.0,
      );
    });

    test('computes OTL preview and formats duration', () {
      final preview = GrandTourPointRulesCatalog.computeOtlPreview(
        stageType: StageType.flat,
        distanceKm: 180.0,
        winnerSpeedKmh: 45.0,
      );

      // 180 km / 45 km/h = 4h = 14400s, OTL = 9% -> +1296s (21m 36s)
      expect(preview.winnerTimeSeconds, closeTo(14400.0, 0.01));
      expect(preview.timeCutPercent, 9.0);
      expect(preview.maxGapSeconds, closeTo(1296.0, 0.01));
      expect(preview.totalCutoffSeconds, closeTo(15696.0, 0.01));
      expect(
        GrandTourPointRulesCatalog.formatDurationHms(preview.winnerTimeSeconds),
        '04:00:00',
      );
      expect(
        GrandTourPointRulesCatalog.formatDurationHms(preview.maxGapSeconds),
        '21:36',
      );
    });
  });

  group('GrandTourJerseyPointRulesModal UI & Responsiveness', () {
    Future<void> pumpModalAtSize(
      WidgetTester tester,
      Size size, {
      GrandTourRulesTab initialTab = GrandTourRulesTab.pointsClassification,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: GrandTourJerseyPointRulesModal(
                  initialTab: initialTab,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders all tabs without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpModalAtSize(tester, size);

          expect(find.text('Regulamin Punktacji & OTL'), findsOneWidget);
          expect(find.text('Etap Płaski (Sprinterski)'), findsOneWidget);
          expect(find.text('Etap Pagórkowaty / Bruk'), findsOneWidget);
          expect(find.text('Etap Górski / Szczyt / ITT'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Switch to KOM tab
          await tester.ensureVisible(find.text('Klasyfikacja Górska'));
          await tester.tap(find.text('Klasyfikacja Górska'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('HC — Finisz na Szczycie (x2)'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Switch to Bonuses tab
          await tester.ensureVisible(find.text('Bonifikaty Czasowe'));
          await tester.tap(find.text('Bonifikaty Czasowe'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('META ETAPU: 10-6-4 s'), findsOneWidget);
          expect(find.text('PREMIA BONUSOWA: 8-5-2 s'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Switch to OTL tab
          await tester.ensureVisible(find.text('Limit Czasu (OTL)'));
          await tester.tap(find.text('Limit Czasu (OTL)'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            find.text('Limit OTL = Czas Zwycięzcy × (1 + Współczynnik Limitu %)'),
            findsOneWidget,
          );
          expect(find.text('Kalkulator Limitu OTL Na Żywo'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('switches Grand Tour edition jerseys dynamically', (tester) async {
      await pumpModalAtSize(tester, const Size(1024, 768));

      expect(find.text('Maillot Jaune (GC)'), findsOneWidget);

      await tester.tap(find.text("Giro d'Italia"));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Maglia Rosa (GC)'), findsOneWidget);
      expect(find.text('Maglia Ciclamino (Punkty)'), findsOneWidget);

      await tester.tap(find.text('Vuelta a España'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('La Roja (GC)'), findsOneWidget);
    });

    testWidgets('opens and closes via static show helper', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => GrandTourJerseyPointRulesModal.show(context),
                child: const Text('Otwórz Zasady'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz Zasady'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Regulamin Punktacji & OTL'), findsOneWidget);

      await tester.tap(find.text('Rozumiem'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Regulamin Punktacji & OTL'), findsNothing);
    });
  });
}
