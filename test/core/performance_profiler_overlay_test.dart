import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/utils/performance_profiler_overlay.dart';
import 'package:pro_peloton_manager/state/game_settings_notifier.dart';

void main() {
  setUp(() {
    PerformanceTelemetryRegistry.instance.reset();
  });

  Widget buildTestApp({
    required Size surfaceSize,
    ProviderContainer? container,
  }) {
    return UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const Scaffold(
            body: PerformanceProfilerOverlay(
              child: Center(child: Text('Main Game Content')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Ukryty domyślnie, przełączany przez GameSettings oraz klawisz F3',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(surfaceSize: const Size(1600, 900), container: container),
    );

    expect(find.text('Main Game Content'), findsOneWidget);
    expect(find.text('FRAME TIME GRAPH (60 KLATEK)'), findsNothing);

    // Włączenie przez ustawienia
    container.read(gameSettingsProvider.notifier).setShowFpsCounter(true);
    await tester.pumpAndSettle();

    expect(find.text('FRAME TIME GRAPH (60 KLATEK)'), findsOneWidget);
    expect(find.text('120 Hz: 8.33 ms'), findsOneWidget);
    expect(find.text('60 Hz: 16.67 ms'), findsOneWidget);

    // Wyłączenie klawiszem F3
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();

    expect(container.read(gameSettingsProvider).showFpsCounter, isFalse);
    expect(find.text('FRAME TIME GRAPH (60 KLATEK)'), findsNothing);

    // Ponowne włączenie klawiszem F3
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();

    expect(container.read(gameSettingsProvider).showFpsCounter, isTrue);
    expect(find.text('FRAME TIME GRAPH (60 KLATEK)'), findsOneWidget);
  });

  testWidgets('Wyświetla telemetrię Isolate 176 kolarzy, LOD0/1/2 oraz RAM',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameSettingsProvider.notifier).setShowFpsCounter(true);

    PerformanceTelemetryRegistry.instance.updatePhysicsTick(
      microseconds: 485,
      riderCount: 176,
    );
    PerformanceTelemetryRegistry.instance.updateLodStats(
      lod0: 18,
      lod1: 64,
      lod2: 94,
      culled: 0,
    );

    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(surfaceSize: const Size(1024, 768), container: container),
    );
    await tester.pumpAndSettle();

    expect(find.text('Isolate (176 kolarzy)'), findsOneWidget);
    expect(find.text('485 µs'), findsOneWidget);
    expect(find.text('Obiekty 3D (LOD0/1/2)'), findsOneWidget);
    expect(find.text('18 / 64 / 94'), findsOneWidget);
    expect(find.text('Pamięć RAM procesu'), findsOneWidget);
  });

  testWidgets('Responsywność bez przepełnień w 390x844, 1024x768 i 1600x900',
      (tester) async {
    final sizes = [
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ];

    for (final size in sizes) {
      final container = ProviderContainer();
      container.read(gameSettingsProvider.notifier).setShowFpsCounter(true);

      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        buildTestApp(surfaceSize: size, container: container),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'Brak błędów layoutu dla $size');
      expect(find.text('FRAME TIME GRAPH (60 KLATEK)'), findsOneWidget);

      container.dispose();
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Przyciski zwijania, pauzy i zamykania działają poprawnie',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameSettingsProvider.notifier).setShowFpsCounter(true);

    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(surfaceSize: const Size(1600, 900), container: container),
    );
    await tester.pumpAndSettle();

    // Zwiń do pigułki FPS
    await tester.tap(find.byTooltip('Zwiń do pigułki FPS'));
    await tester.pumpAndSettle();
    expect(find.text('FRAME TIME GRAPH (60 KLATEK)'), findsNothing);

    // Rozwiń ponownie
    await tester.tap(find.byTooltip('Rozwiń profiler'));
    await tester.pumpAndSettle();
    expect(find.text('FRAME TIME GRAPH (60 KLATEK)'), findsOneWidget);

    // Wstrzymaj i wznów próbkowanie
    await tester.tap(find.byTooltip('Wstrzymaj próbkowanie'));
    await tester.pump();
    expect(find.byTooltip('Wznów próbkowanie'), findsOneWidget);

    await tester.tap(find.byTooltip('Wznów próbkowanie'));
    await tester.pump();
    expect(find.byTooltip('Wstrzymaj próbkowanie'), findsOneWidget);

    // Zamknij profiler przyciskiem X
    await tester.tap(find.byTooltip('Zamknij profiler (F3)'));
    await tester.pumpAndSettle();
    expect(container.read(gameSettingsProvider).showFpsCounter, isFalse);
  });
}
