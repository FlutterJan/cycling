import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/performance_120fps_frame_budget_auditor.dart';
import 'package:pro_peloton_manager/core/utils/performance_profiler_overlay.dart';

void main() {
  group('Performance120FpsFrameBudgetAuditor unit tests', () {
    const auditor = Performance120FpsFrameBudgetAuditor();

    test('evaluateVerdict klasyfikuje progi budżetu 120 FPS (< 4.5 ms)', () {
      expect(
        Performance120FpsFrameBudgetAuditor.evaluateVerdict(2.8),
        FrameBudgetVerdict.optimal,
      );
      expect(
        Performance120FpsFrameBudgetAuditor.evaluateVerdict(3.9),
        FrameBudgetVerdict.withinBudget,
      );
      expect(
        Performance120FpsFrameBudgetAuditor.evaluateVerdict(4.5),
        FrameBudgetVerdict.warning,
      );
      expect(
        Performance120FpsFrameBudgetAuditor.evaluateVerdict(6.6),
        FrameBudgetVerdict.critical,
      );
    });

    test('auditSamples obsługuje pustą listę bez błędów', () {
      final report = auditor.auditSamples(samples: const <FrameBudgetSample>[]);
      expect(report.totalFramesSampled, 0);
      expect(report.avgFrameMs, 0.0);
      expect(report.overallVerdict, FrameBudgetVerdict.optimal);
      expect(report.passesAudit, isTrue);
    });

    test('auditSamples oblicza percentyle, spadki 120Hz i rekomendacje', () {
      final baseTime = DateTime(2026, 11, 18, 12, 0, 0);
      final samples = <FrameBudgetSample>[
        FrameBudgetSample(
          frameIndex: 1,
          timestamp: baseTime,
          stageMicros: const <FramePipelineStage, int>{
            FramePipelineStage.sceneProjection: 400,
            FramePipelineStage.pelotonInstancing: 1100,
            FramePipelineStage.roadTerrainMesh: 700,
            FramePipelineStage.lightingAndShadows: 500,
            FramePipelineStage.hudAndPostProcess: 300,
          },
        ),
        FrameBudgetSample(
          frameIndex: 2,
          timestamp: baseTime.add(const Duration(milliseconds: 8)),
          stageMicros: const <FramePipelineStage, int>{
            FramePipelineStage.sceneProjection: 800,
            FramePipelineStage.pelotonInstancing: 3200,
            FramePipelineStage.roadTerrainMesh: 1600,
            FramePipelineStage.lightingAndShadows: 1800,
            FramePipelineStage.hudAndPostProcess: 1100,
          },
        ),
      ];

      final report = auditor.auditSamples(samples: samples);
      expect(report.totalFramesSampled, 2);
      expect(report.minFrameMs, closeTo(3.0, 0.001));
      expect(report.maxFrameMs, closeTo(8.5, 0.001));
      expect(report.dropped120FpsFrames, 1);
      expect(report.overBudgetFramesCount, 1);
      expect(report.withinBudgetRatio, closeTo(0.5, 0.001));
      expect(report.passesAudit, isFalse);
      expect(report.recommendations, isNotEmpty);
    });

    test('runDeterministicBenchmark dla ITT mieści się w budżecie < 4.5 ms', () {
      final report = auditor.runDeterministicBenchmark(
        scenario: FrameBudgetPresetScenario.timeTrialSolo,
        frameCount: 60,
        lodBias: 0,
      );

      expect(report.totalFramesSampled, 60);
      expect(report.p95FrameMs, lessThan(4.5));
      expect(report.dropped120FpsFrames, 0);
      expect(report.passesAudit, isTrue);
      expect(report.overallVerdict.passes120FpsBudget, isTrue);
      expect(report.toJson()['passesAudit'], isTrue);
    });

    test('sampleFromTelemetryRegistry konwertuje metryki LOD na próbkę 3D', () {
      const metrics = EnginePerformanceMetrics(
        physicsTickMicroseconds: 480,
        simulatedRidersCount: 176,
        isSimulationActive: true,
        lod0Count: 40,
        lod1Count: 80,
        lod2Count: 56,
        culledCount: 0,
      );

      final sample = auditor.sampleFromTelemetryRegistry(
        metrics: metrics,
        frameIndex: 7,
      );

      expect(sample.frameIndex, 7);
      expect(sample.physicsIsolateMicros, 480);
      expect(sample.lod0Count, 40);
      expect(sample.totalRenderMicros, greaterThan(0));
      expect(sample.toJson()['lod0Count'], 40);
    });
  });

  group('Performance120FpsFrameBudgetAuditorPanel widget tests', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Performance120FpsFrameBudgetAuditorPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się poprawnie w 390x844 (mobile) bez overflow', (
      tester,
    ) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(
        find.text('Audyt Budżetu Klatki 3D — 120 FPS'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się poprawnie w 1024x768 (tablet) bez overflow', (
      tester,
    ) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(
        find.text('Audyt Budżetu Klatki 3D — 120 FPS'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renderuje się poprawnie w 1600x900 (desktop) i obsługuje interakcje',
      (tester) async {
        await pumpAtSize(tester, const Size(1600, 900));
        expect(
          find.text('Audyt Budżetu Klatki 3D — 120 FPS'),
          findsOneWidget,
        );

        await tester.tap(find.text('Jazda Indywidualna na Czas (ITT)'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('Audyt zaliczony'), findsOneWidget);

        await tester.tap(find.text('Telemetria Live'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Zatrzymaj Live'), findsOneWidget);

        await tester.tap(find.text('Zatrzymaj Live'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Telemetria Live'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
