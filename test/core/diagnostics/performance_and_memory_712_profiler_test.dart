import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/diagnostics/performance_and_memory_712_profiler.dart';

void main() {
  group('PerformanceAndMemory712Profiler unit tests', () {
    const profiler = PerformanceAndMemory712Profiler();

    test('evaluateModeVerdict klasyfikuje progi FPS, RAM i wycieków', () {
      const mode = GameMode712ProfileTarget.worldTourPeloton;

      expect(
        PerformanceAndMemory712Profiler.evaluateModeVerdict(
          mode: mode,
          p95FrameMs: 3.1,
          p99FrameMs: 3.4,
          peakRamMb: 440.0,
          dropped120FpsFrames: 0,
          totalLeakedHandles: 0,
          ramLeakDeltaMb: 1.2,
        ),
        Profiler712AuditVerdict.sovereign120Fps,
      );

      expect(
        PerformanceAndMemory712Profiler.evaluateModeVerdict(
          mode: mode,
          p95FrameMs: 4.2,
          p99FrameMs: 4.4,
          peakRamMb: 550.0,
          dropped120FpsFrames: 0,
          totalLeakedHandles: 0,
          ramLeakDeltaMb: 2.0,
        ),
        Profiler712AuditVerdict.withinBudget,
      );

      expect(
        PerformanceAndMemory712Profiler.evaluateModeVerdict(
          mode: mode,
          p95FrameMs: 4.9,
          p99FrameMs: 5.5,
          peakRamMb: 550.0,
          dropped120FpsFrames: 0,
          totalLeakedHandles: 0,
          ramLeakDeltaMb: 2.0,
        ),
        Profiler712AuditVerdict.memoryOrFrameWarning,
      );

      expect(
        PerformanceAndMemory712Profiler.evaluateModeVerdict(
          mode: mode,
          p95FrameMs: 3.5,
          p99FrameMs: 3.8,
          peakRamMb: 450.0,
          dropped120FpsFrames: 0,
          totalLeakedHandles: 1,
          ramLeakDeltaMb: 2.0,
        ),
        Profiler712AuditVerdict.criticalBottleneck,
      );
    });

    test('runFullAllModesAudit zalicza wszystkie 11 trybów przy obciążeniu 1.0x', () {
      final report = profiler.runFullAllModesAudit();

      expect(GameMode712ProfileTarget.values.length, 11);
      expect(report.totalModesCount, 11);
      expect(report.passingModesCount, 11);
      expect(report.totalDetectedLeaks, 0);
      expect(report.worstP99FrameMs, lessThan(4.5));
      expect(report.peakGlobalRamMb, lessThanOrEqualTo(report.globalRamCeilingMb));
      expect(report.passesFullAudit, isTrue);

      final json = report.toJson();
      expect(json['passesFullAudit'], isTrue);
      expect((json['modeResults'] as List<dynamic>).length, 11);
      expect(report.toPrettyJson(), contains('worldtour_peloton'));
      expect(report.toPrettyJson(), contains('be_a_pro_career'));
      expect(report.toPrettyJson(), contains('tv_director_live_production'));
    });

    test('stress test wykrywa przekroczenia budżetu 120 FPS i RAM', () {
      final report = profiler.runFullAllModesAudit(
        frameLoadFactor: 2.1,
        ramLoadFactor: 1.8,
      );

      expect(report.passesFullAudit, isFalse);
      expect(report.overallVerdict, Profiler712AuditVerdict.criticalBottleneck);
      expect(report.totalDetectedLeaks, greaterThan(0));
      expect(report.recommendations, isNotEmpty);
    });

    test('auditCustomSamples obsługuje pustą listę bez wyjątków', () {
      final report = profiler.auditCustomSamples(
        const <ModePerformanceMemory712Sample>[],
      );

      expect(report.totalModesCount, 0);
      expect(report.worstP99FrameMs, 0.0);
      expect(report.peakGlobalRamMb, 0.0);
      expect(report.passesFullAudit, isFalse);
    });

    test('PerformanceAndMemory712Notifier zarządza filtrami i obciążeniem', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(performanceAndMemory712Provider.notifier);

      expect(container.read(performanceAndMemory712Provider).report, isNotNull);
      expect(
        container.read(performanceAndMemory712Provider).selectedMode,
        isNull,
      );

      notifier.selectMode(GameMode712ProfileTarget.tvDirectorLiveProduction);
      expect(
        container.read(performanceAndMemory712Provider).selectedMode,
        GameMode712ProfileTarget.tvDirectorLiveProduction,
      );

      notifier.setFrameLoadFactor(1.5);
      expect(
        container.read(performanceAndMemory712Provider).frameLoadFactor,
        1.5,
      );

      notifier.resetFilters();
      final state = container.read(performanceAndMemory712Provider);
      expect(state.selectedMode, isNull);
      expect(state.frameLoadFactor, 1.0);
      expect(state.ramLoadFactor, 1.0);
    });
  });

  group('PerformanceAndMemory712ProfilerPanel widget tests', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PerformanceAndMemory712ProfilerPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renderuje się bez przepełnień w 390x844 (mobile)',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(
        find.text('Audyt Wydajności 120 FPS & Pamięci RAM (#710)'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień w 1024x768 (tablet)',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('Zaliczone Tryby'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renderuje się bez przepełnień w 1600x900 (desktop)',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('Uruchom Audyt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('filtrowanie po trybie zawęża widoczną listę kart',
        (WidgetTester tester) async {
      await pumpAtSize(tester, const Size(1600, 900));

      final chip = find.text('Tryb Reżysera TV').first;
      await tester.tap(chip);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('WorldTour (176)'), findsOneWidget);
      expect(
        find.text('12 kamer na żywo, przełączenia PiP, grafiki TV i realizacja'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
