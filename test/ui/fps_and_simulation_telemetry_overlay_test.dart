import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/fps_and_simulation_telemetry_overlay.dart';

void main() {
  group('SimulationTelemetrySnapshot', () {
    test('sanitized normalizes NaN, infinity, negative and invalid targetFps', () {
      const dirty = SimulationTelemetrySnapshot(
        fps: double.nan,
        frameRenderTimeMs: -12.5,
        isolatePhysicsStepMs: double.infinity,
        visiblePolygons3d: -42,
        ramUsageMb: double.negativeInfinity,
        targetFps: 0,
        isSimulationActive: true,
      );

      final clean = dirty.sanitized();
      expect(clean.fps, 0.0);
      expect(clean.frameRenderTimeMs, 0.0);
      expect(clean.isolatePhysicsStepMs, 0.0);
      expect(clean.visiblePolygons3d, 0);
      expect(clean.ramUsageMb, 0.0);
      expect(clean.targetFps, 60);
      expect(clean.isSimulationActive, isTrue);
    });
  });

  group('FpsAndSimulationTelemetryOverlay', () {
    const sampleSnapshot = SimulationTelemetrySnapshot(
      fps: 118.4,
      frameRenderTimeMs: 7.2,
      isolatePhysicsStepMs: 0.95,
      visiblePolygons3d: 48600,
      ramUsageMb: 312.5,
      targetFps: 120,
      isSimulationActive: true,
    );

    Widget buildHarness({
      required Size size,
      required Widget child,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('displays all 5 required telemetry metrics', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          size: const Size(1600, 900),
          child: const FpsAndSimulationTelemetryOverlay(
            snapshot: sampleSnapshot,
            enableLiveSchedulerTimings: false,
            child: SizedBox.expand(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TELEMETRIA 3D'), findsOneWidget);
      expect(find.text('Aktualny FPS'), findsOneWidget);
      expect(find.text('118 FPS'), findsOneWidget);
      expect(find.text('Render ramki'), findsOneWidget);
      expect(find.text('7.2 ms'), findsOneWidget);
      expect(find.text('Fizyka Isolate'), findsOneWidget);
      expect(find.text('0.95 ms'), findsOneWidget);
      expect(find.text('Wielokąty 3D'), findsOneWidget);
      expect(find.text('48.6k'), findsOneWidget);
      expect(find.text('Pamięć RAM'), findsOneWidget);
      expect(find.text('312.5 MB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports pause, collapse, corner cycle and close interactions',
        (tester) async {
      final notifier = ValueNotifier<SimulationTelemetrySnapshot>(sampleSnapshot);
      addTearDown(notifier.dispose);

      TelemetryOverlayCorner? lastCorner;
      var closedCount = 0;

      await tester.pumpWidget(
        buildHarness(
          size: const Size(1024, 768),
          child: FpsAndSimulationTelemetryOverlay(
            telemetryListenable: notifier,
            enableLiveSchedulerTimings: false,
            onCornerChanged: (corner) => lastCorner = corner,
            onClose: () => closedCount++,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Pause
      await tester.tap(find.byTooltip('Wstrzymaj pomiar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TELEMETRIA (PAUZA)'), findsOneWidget);

      // Update notifier while paused — UI should keep 118 FPS
      notifier.value = sampleSnapshot.copyWith(fps: 44.0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('118 FPS'), findsOneWidget);

      // Resume
      await tester.tap(find.byTooltip('Wznów pomiar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TELEMETRIA 3D'), findsOneWidget);

      // Cycle corner
      await tester.tap(find.byTooltip('Zmień narożnik'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastCorner, TelemetryOverlayCorner.bottomRight);

      // Collapse
      await tester.tap(find.byTooltip('Zwiń panel'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pamięć RAM'), findsNothing);

      // Expand again
      await tester.tap(find.byTooltip('Rozwiń panel'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pamięć RAM'), findsOneWidget);

      // Close
      await tester.tap(find.byTooltip('Ukryj licznik'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(closedCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects disabled state when isInteractive is false',
        (tester) async {
      var closedCount = 0;
      TelemetryOverlayCorner? changedCorner;

      await tester.pumpWidget(
        buildHarness(
          size: const Size(1024, 768),
          child: FpsAndSimulationTelemetryOverlay(
            snapshot: sampleSnapshot,
            enableLiveSchedulerTimings: false,
            isInteractive: false,
            onClose: () => closedCount++,
            onCornerChanged: (c) => changedCorner = c,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Wstrzymaj pomiar'));
      await tester.tap(find.byTooltip('Zmień narożnik'));
      await tester.tap(find.byTooltip('Ukryj licznik'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TELEMETRIA 3D'), findsOneWidget);
      expect(changedCorner, isNull);
      expect(closedCount, 0);
    });

    for (final viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(viewport);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            buildHarness(
              size: viewport,
              child: const FpsAndSimulationTelemetryOverlay(
                snapshot: sampleSnapshot,
                enableLiveSchedulerTimings: false,
                child: SizedBox.expand(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('118 FPS'), findsOneWidget);
          expect(find.text('48.6k'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
