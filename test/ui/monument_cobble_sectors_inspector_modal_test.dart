import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/monument_cobble_sectors_inspector_modal.dart';

void main() {
  group('MonumentSectorPressureAdvisor', () {
    test('lowers recommended tire pressure when surface becomes wet or muddy', () {
      final sectors = MonumentCobbleSectorsCatalog.defaultMonumentSectors();
      final arenberg = sectors.firstWhere((s) => s.id == 'trouee_arenberg');

      final dryRec = MonumentSectorPressureAdvisor.calculate(
        sector: arenberg,
        moisture: SectorMoistureCondition.dry,
        systemWeightKg: 76.0,
        tireWidthMm: 32.0,
        isTubeless: true,
      );

      final wetRec = MonumentSectorPressureAdvisor.calculate(
        sector: arenberg,
        moisture: SectorMoistureCondition.wet,
        systemWeightKg: 76.0,
        tireWidthMm: 32.0,
        isTubeless: true,
      );

      final muddyRec = MonumentSectorPressureAdvisor.calculate(
        sector: arenberg,
        moisture: SectorMoistureCondition.muddy,
        systemWeightKg: 76.0,
        tireWidthMm: 32.0,
        isTubeless: true,
      );

      expect(wetRec.frontBar, lessThan(dryRec.frontBar));
      expect(wetRec.rearBar, lessThan(dryRec.rearBar));
      expect(muddyRec.frontBar, lessThan(wetRec.frontBar));
      expect(muddyRec.pinchFlatRiskPercent, greaterThan(dryRec.pinchFlatRiskPercent));
    });

    test('recommends higher pressure for inner tube than tubeless', () {
      final sectors = MonumentCobbleSectorsCatalog.defaultMonumentSectors();
      final carrefour = sectors.firstWhere((s) => s.id == 'carrefour_de_larbre');

      final tubelessRec = MonumentSectorPressureAdvisor.calculate(
        sector: carrefour,
        moisture: SectorMoistureCondition.dry,
        systemWeightKg: 75.0,
        tireWidthMm: 30.0,
        isTubeless: true,
      );

      final tubeRec = MonumentSectorPressureAdvisor.calculate(
        sector: carrefour,
        moisture: SectorMoistureCondition.dry,
        systemWeightKg: 75.0,
        tireWidthMm: 30.0,
        isTubeless: false,
      );

      expect(tubeRec.frontBar, greaterThan(tubelessRec.frontBar));
      expect(tubeRec.rearBar, greaterThan(tubelessRec.rearBar));
      expect(tubeRec.pinchFlatRiskPercent, greaterThan(tubelessRec.pinchFlatRiskPercent));
    });
  });

  group('MonumentCobbleSectorsInspectorModal widget', () {
    Widget buildTestHost({
      required Size size,
      List<MonumentSectorData>? sectors,
      ValueChanged<TirePressureRecommendation>? onApply,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: MonumentCobbleSectorsInspectorModal(
                sectors:
                    sectors ?? MonumentCobbleSectorsCatalog.defaultMonumentSectors(),
                onApplyPressureSetup: onApply,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays iconic sectors, metrics, moisture and tire pressure',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TirePressureRecommendation? applied;
      await tester.pumpWidget(
        buildTestHost(
          size: const Size(1280, 820),
          onApply: (rec) => applied = rec,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Trouée d'Arenberg"), findsWidgets);
      expect(find.text('Mons-en-Pévèle'), findsOneWidget);
      expect(find.text("Carrefour de l'Arbre"), findsOneWidget);
      expect(find.text('2300 m'), findsWidgets);
      expect(find.text('5 / 5 ★'), findsOneWidget);
      expect(find.textContaining('BAR'), findsWidgets);
      expect(find.textContaining('PSI'), findsWidgets);

      // Select Paterberg
      await tester.tap(find.text('Paterberg'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('360 m'), findsWidgets);
      expect(find.text('+12.9%'), findsWidgets);

      // Switch moisture to Błoto and apply setup
      final muddyBtn = find.text('Błoto').last;
      await tester.ensureVisible(muddyBtn);
      await tester.tap(muddyBtn);
      await tester.pump(const Duration(milliseconds: 300));

      final applyBtn = find.text('Zastosuj ciśnienie mechanika');
      await tester.ensureVisible(applyBtn);
      await tester.tap(applyBtn);
      await tester.pump(const Duration(milliseconds: 300));
      expect(applied, isNotNull);
      expect(applied!.sectorId, equals('paterberg'));
    });

    testWidgets('handles empty sector list gracefully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestHost(size: const Size(1024, 768), sectors: const []),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Brak zdefiniowanych sektorów'),
        findsOneWidget,
      );
    });

    for (final Size viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestHost(size: viewport));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text("Trouée d'Arenberg"), findsWidgets);
      });
    }
  });
}
