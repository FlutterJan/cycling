import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/what_if_tactical_sandbox_simulator.dart';

void main() {
  group('WhatIfTacticalSandboxSimulator', () {
    test('buildDefault20Variants generates exactly 20 distinct variants', () {
      final WhatIfStageContext ctx =
          WhatIfTacticalSandboxSimulator.defaultStageContext();
      final List<WhatIfTacticalVariant> variants =
          WhatIfTacticalSandboxSimulator.buildDefault20Variants(ctx);

      expect(variants.length, 20);
      expect(variants.map((v) => v.id).toSet().length, 20);
    });

    test('simulateVariantsSync is deterministic and within latency budget', () {
      final WhatIfStageContext ctx =
          WhatIfTacticalSandboxSimulator.defaultStageContext();
      final WhatIfRiderProfile rider =
          WhatIfTacticalSandboxSimulator.defaultRiderProfile();
      final List<WhatIfTacticalVariant> variants =
          WhatIfTacticalSandboxSimulator.buildDefault20Variants(ctx);

      final WhatIfSandboxSimulationReport reportA =
          WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: ctx,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 100,
      );
      final WhatIfSandboxSimulationReport reportB =
          WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: ctx,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 100,
      );

      expect(reportA.variantsCount, 20);
      expect(reportA.totalSimulationsRun, 2000);
      expect(reportA.metLatencyBudget, isTrue);
      expect(reportA.elapsedMs, lessThan(1500));
      expect(reportA.outcomes.length, 20);
      expect(
        reportA.outcomes.where((o) => o.isOptimalRecommended).length,
        1,
      );

      for (int i = 0; i < reportA.outcomes.length; i++) {
        final WhatIfVariantOutcome a = reportA.outcomes[i];
        final WhatIfVariantOutcome b = reportB.outcomes[i];
        expect(a.variant.id, b.variant.id);
        expect(a.winProbability, b.winProbability);
        expect(a.p10TimeGapSeconds, lessThanOrEqualTo(a.p50TimeGapSeconds));
        expect(a.p50TimeGapSeconds, lessThanOrEqualTo(a.p90TimeGapSeconds));
        expect(a.winProbability, inInclusiveRange(0.0, 1.0));
        expect(a.podiumProbability, inInclusiveRange(0.0, 1.0));
        expect(a.top10Probability, inInclusiveRange(0.0, 1.0));
      }
    });

    test('simulateVariantsInBackground completes 20 variants in < 1.5 s',
        () async {
      final WhatIfStageContext ctx =
          WhatIfTacticalSandboxSimulator.defaultStageContext();
      final WhatIfRiderProfile rider =
          WhatIfTacticalSandboxSimulator.defaultRiderProfile();
      final List<WhatIfTacticalVariant> variants =
          WhatIfTacticalSandboxSimulator.buildDefault20Variants(ctx);

      final WhatIfSandboxSimulationReport report =
          await WhatIfTacticalSandboxSimulator.simulateVariantsInBackground(
        stageContext: ctx,
        riderProfile: rider,
        variants: variants,
        runsPerVariant: 100,
      );

      expect(report.variantsCount, 20);
      expect(report.totalSimulationsRun, 2000);
      expect(report.elapsedMs, lessThan(1500));
      expect(report.metLatencyBudget, isTrue);
      expect(report.outcomes.length, 20);
    });

    test('handles empty variants list gracefully', () {
      final WhatIfSandboxSimulationReport report =
          WhatIfTacticalSandboxSimulator.simulateVariantsSync(
        stageContext: WhatIfTacticalSandboxSimulator.defaultStageContext(),
        riderProfile: WhatIfTacticalSandboxSimulator.defaultRiderProfile(),
        variants: const <WhatIfTacticalVariant>[],
      );

      expect(report.variantsCount, 0);
      expect(report.totalSimulationsRun, 0);
      expect(report.outcomes, isEmpty);
      expect(report.metLatencyBudget, isTrue);
    });

    test('JSON serialization round-trip preserves key fields', () {
      final WhatIfStageContext ctx =
          WhatIfTacticalSandboxSimulator.defaultStageContext();
      final WhatIfRiderProfile rider =
          WhatIfTacticalSandboxSimulator.defaultRiderProfile();
      final WhatIfTacticalVariant variant =
          WhatIfTacticalSandboxSimulator.buildDefault20Variants(ctx).first;

      expect(WhatIfStageContext.fromJson(ctx.toJson()).stageName, ctx.stageName);
      expect(WhatIfRiderProfile.fromJson(rider.toJson()).ftpWatts, rider.ftpWatts);
      expect(WhatIfTacticalVariant.fromJson(variant.toJson()).id, variant.id);
    });

    test('WhatIfSandboxNotifier updates terrain, weather, filter and effort', () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final WhatIfSandboxNotifier notifier =
          container.read(whatIfSandboxProvider.notifier);

      notifier.selectTerrain(WhatIfStageTerrainProfile.cobbleMonument);
      notifier.selectWeather(WhatIfWeatherCondition.crosswindGusts);
      notifier.setFilterRisk(WhatIfRiskLevel.aggressive);
      notifier.updateSelectedVariantEffort(117.0);
      notifier.runSimulationSync();

      final WhatIfSandboxState state = container.read(whatIfSandboxProvider);
      expect(
        state.stageContext.terrain,
        WhatIfStageTerrainProfile.cobbleMonument,
      );
      expect(state.stageContext.weather, WhatIfWeatherCondition.crosswindGusts);
      expect(state.filterRiskLevel, WhatIfRiskLevel.aggressive);
      expect(state.report?.variantsCount, 20);
    });
  });

  group('WhatIfTacticalSandboxPanel responsive UI', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: WhatIfTacticalSandboxPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Piaskownica Taktyczna Monte Carlo „Co Jeśli?”'),
            findsOneWidget,
          );
          expect(find.text('Uruchom 20 wariantów'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
