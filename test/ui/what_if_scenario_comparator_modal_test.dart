import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/simulation/what_if_tactical_sandbox_simulator.dart';
import 'package:pro_peloton_manager/ui/widgets/what_if_scenario_comparator_modal.dart';

WhatIfSandboxSimulationReport _buildSampleReport({bool empty = false}) {
  final stage = WhatIfTacticalSandboxSimulator.defaultStageContext();
  if (empty) {
    return WhatIfSandboxSimulationReport(
      stageContext: stage,
      variantsCount: 0,
      runsPerVariant: 0,
      totalSimulationsRun: 0,
      elapsedMs: 12,
      metLatencyBudget: true,
      bestWinVariantId: '',
      bestSafeVariantId: '',
      outcomes: const <WhatIfVariantOutcome>[],
      generatedAtIso: '2026-11-18T12:00:00Z',
    );
  }

  final rider = WhatIfTacticalSandboxSimulator.defaultRiderProfile();
  final variants = WhatIfTacticalSandboxSimulator.buildDefault20Variants(stage)
      .take(6)
      .toList();
  return WhatIfTacticalSandboxSimulator.simulateVariantsSync(
    stageContext: stage,
    riderProfile: rider,
    variants: variants,
    runsPerVariant: 25,
  );
}

WhatIfVariantOutcome _buildCustomOutcome({
  required String id,
  required List<double> timeGaps,
  double winProbability = 0.25,
}) {
  final samples = List<WhatIfMonteCarloRunSample>.generate(
    timeGaps.length,
    (int i) => WhatIfMonteCarloRunSample(
      runIndex: i,
      finishPosition: i + 1,
      timeGapToWinnerSeconds: timeGaps[i],
      remainingWPrimePercent: 30.0 + i * 2.0,
      bonkOccurred: false,
      incidentOccurred: false,
      energySpentKj: 3200.0,
    ),
  );
  return WhatIfVariantOutcome(
    variant: WhatIfTacticalVariant(
      id: id,
      name: 'Wariant $id',
      strategy: WhatIfTacticalStrategyType.finalClimbAllIn,
      riskLevel: WhatIfRiskLevel.aggressive,
      attackKmFromFinish: 6.5,
      effortPercentFtp: 108.0,
      domestiquesCommitted: 2,
      nutritionBoostEnabled: true,
      aeroEquipmentBonus: 0.02,
    ),
    runCount: samples.length,
    winProbability: winProbability,
    podiumProbability: 0.55,
    top10Probability: 0.85,
    expectedFinishPosition: 3.5,
    p10TimeGapSeconds: 2.0,
    p50TimeGapSeconds: 12.0,
    p90TimeGapSeconds: 24.0,
    bonkRiskProbability: 0.12,
    incidentRiskProbability: 0.04,
    expectedUciPoints: 140.0,
    tacticalVerdictScore: 82.0,
    isOptimalRecommended: true,
    samples: samples,
  );
}

void main() {
  group('WhatIfBoxPlotCalculator', () {
    test('wylicza poprawne kwartyle oraz outliery 1.5xIQR', () {
      final outcome = _buildCustomOutcome(
        id: 'test_outliers',
        timeGaps: <double>[2, 4, 5, 6, 7, 8, 9, 10, 40],
      );

      final stats = WhatIfBoxPlotCalculator.computeStats(
        outcome: outcome,
        metric: WhatIfComparatorMetric.timeGapSeconds,
      );

      expect(stats.q1, closeTo(5.0, 0.01));
      expect(stats.median, closeTo(7.0, 0.01));
      expect(stats.q3, closeTo(9.0, 0.01));
      expect(stats.iqr, closeTo(4.0, 0.01));
      expect(stats.min, closeTo(2.0, 0.01));
      expect(stats.max, closeTo(10.0, 0.01));
      expect(stats.outliers, contains(40.0));
    });

    test('obsługuje bezpiecznie pustą listę próbek Monte Carlo', () {
      final outcome = _buildCustomOutcome(
        id: 'empty_samples',
        timeGaps: const <double>[],
      );

      final stats = WhatIfBoxPlotCalculator.computeStats(
        outcome: outcome,
        metric: WhatIfComparatorMetric.timeGapSeconds,
      );

      expect(stats.median, 12.0);
      expect(stats.min, 2.0);
      expect(stats.max, 24.0);
      expect(stats.outliers, isEmpty);
    });

    test('serializuje i deserializuje WhatIfBoxPlotStats do JSON', () {
      final outcome = _buildCustomOutcome(
        id: 'json_roundtrip',
        timeGaps: <double>[1, 3, 5, 7, 9],
      );
      final stats = WhatIfBoxPlotCalculator.computeStats(
        outcome: outcome,
        metric: WhatIfComparatorMetric.remainingWPrime,
      );

      final restored = WhatIfBoxPlotStats.fromJson(stats.toJson());
      expect(restored.variantId, stats.variantId);
      expect(restored.metric, WhatIfComparatorMetric.remainingWPrime);
      expect(restored.median, closeTo(stats.median, 0.001));
      expect(restored.winProbability, closeTo(stats.winProbability, 0.001));
    });

    test('wylicza deltę H2H pomiędzy dwoma wariantami', () {
      final a = WhatIfBoxPlotCalculator.computeStats(
        outcome: _buildCustomOutcome(
          id: 'A',
          timeGaps: <double>[2, 4, 6],
          winProbability: 0.40,
        ),
        metric: WhatIfComparatorMetric.timeGapSeconds,
      );
      final b = WhatIfBoxPlotCalculator.computeStats(
        outcome: _buildCustomOutcome(
          id: 'B',
          timeGaps: <double>[8, 10, 12],
          winProbability: 0.15,
        ),
        metric: WhatIfComparatorMetric.timeGapSeconds,
      );

      final delta = WhatIfBoxPlotCalculator.computeHeadToHeadDelta(a, b);
      expect(delta.winProbDeltaPp, closeTo(25.0, 0.01));
      expect(delta.medianDelta, closeTo(-6.0, 0.01));
    });
  });

  group('WhatIfScenarioComparatorModal UI & Responsywność', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień na ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          final report = _buildSampleReport();
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: Center(
                  child: WhatIfScenarioComparatorModal(report: report),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byKey(const Key('what_if_boxplot_canvas')), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('przełącza metrykę, sortowanie i aplikuje wariant',
        (WidgetTester tester) async {
      final report = _buildSampleReport();
      WhatIfVariantOutcome? applied;

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: WhatIfScenarioComparatorModal(
                report: report,
                onApplyVariant: (WhatIfVariantOutcome o) => applied = o,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(Key('metric_chip_${WhatIfComparatorMetric.finishPosition.name}')),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('what_if_comparator_apply_button')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(applied, isNotNull);
    });

    testWidgets('obsługuje pusty raport oraz stan disabled',
        (WidgetTester tester) async {
      final emptyReport = _buildSampleReport(empty: true);

      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: WhatIfScenarioComparatorModal(
                report: emptyReport,
                enabled: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak danych symulacji Monte Carlo'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('showWhatIfScenarioComparatorModal otwiera i zamyka dialog',
        (WidgetTester tester) async {
      final report = _buildSampleReport();
      WhatIfScenarioComparatorResult? result;

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showWhatIfScenarioComparatorModal(
                      context,
                      report: report,
                    );
                  },
                  child: const Text('Otwórz'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otwórz'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WhatIfScenarioComparatorModal), findsOneWidget);

      await tester.tap(find.byKey(const Key('what_if_comparator_cancel_button')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(result?.action, WhatIfComparatorModalAction.dismissed);
    });
  });
}
