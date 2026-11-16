import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/config/platform_adaptive_graphics_profiler.dart';
import 'package:pro_peloton_manager/models/settings/game_settings.dart';

void main() {
  group('PlatformAdaptiveGraphicsProfiler - detekcja i dobór presetu', () {
    test('wykrywa platformy Windows, macOS, iOS i Android', () {
      expect(
        PlatformAdaptiveGraphicsProfiler.detectPlatform(
          overridePlatform: TargetPlatform.windows,
          overrideIsWeb: false,
        ),
        AdaptiveGraphicsPlatform.windows,
      );
      expect(
        PlatformAdaptiveGraphicsProfiler.detectPlatform(
          overridePlatform: TargetPlatform.macOS,
          overrideIsWeb: false,
        ),
        AdaptiveGraphicsPlatform.macOS,
      );
      expect(
        PlatformAdaptiveGraphicsProfiler.detectPlatform(
          overridePlatform: TargetPlatform.iOS,
          overrideIsWeb: false,
        ),
        AdaptiveGraphicsPlatform.iOS,
      );
      expect(
        PlatformAdaptiveGraphicsProfiler.detectPlatform(
          overridePlatform: TargetPlatform.android,
          overrideIsWeb: false,
        ),
        AdaptiveGraphicsPlatform.android,
      );
    });

    test(
        'mierzy dokładnie pierwsze 30 klatek i dobiera Ultra 120 FPS Desktop na szybkim Windows/macOS',
        () {
      GraphicsPreset? appliedPreset;
      final notifier = PlatformAdaptiveGraphicsProfilerNotifier(
        platformOverride: AdaptiveGraphicsPlatform.windows,
        isTabletOverride: false,
        onApplyGamePreset: (preset) => appliedPreset = preset,
      );

      final fastFrames = List<Duration>.generate(
        35,
        (_) => const Duration(microseconds: 6200),
      );
      notifier.ingestFrameDurations(fastFrames);

      expect(notifier.state.telemetry.collectedFrames, 30);
      expect(notifier.state.telemetry.isProfilingComplete, isTrue);
      expect(
        notifier.state.recommendedPreset,
        AdaptiveGraphicsProfilePreset.ultra120FpsDesktop,
      );
      expect(
        notifier.state.activePreset,
        AdaptiveGraphicsProfilePreset.ultra120FpsDesktop,
      );
      expect(appliedPreset, GraphicsPreset.ultraMacPc);
    });

    test('dobiera High 60 FPS Tablet dla tabletu iOS/Android o dobrej wydajności',
        () {
      final notifier = PlatformAdaptiveGraphicsProfilerNotifier(
        platformOverride: AdaptiveGraphicsPlatform.iOS,
        isTabletOverride: true,
      );

      final tabletFrames = List<Duration>.generate(
        30,
        (_) => const Duration(microseconds: 12200),
      );
      notifier.ingestFrameDurations(tabletFrames);

      expect(
        notifier.state.recommendedPreset,
        AdaptiveGraphicsProfilePreset.high60FpsTablet,
      );
      expect(
        notifier.state.activePreset.gamePreset,
        GraphicsPreset.highQuality,
      );
    });

    test(
        'dobiera Balanced Mobile Battery Saver dla wolniejszego telefonu Android',
        () {
      final notifier = PlatformAdaptiveGraphicsProfilerNotifier(
        platformOverride: AdaptiveGraphicsPlatform.android,
        isTabletOverride: false,
      );

      final slowMobileFrames = List<Duration>.generate(
        30,
        (i) => Duration(milliseconds: i % 5 == 0 ? 21 : 17),
      );
      notifier.ingestFrameDurations(slowMobileFrames);

      expect(
        notifier.state.recommendedPreset,
        AdaptiveGraphicsProfilePreset.balancedMobileBatterySaver,
      );
      expect(
        notifier.state.activePreset.gamePreset,
        GraphicsPreset.batterySaver,
      );
      expect(notifier.state.telemetry.droppedFramesCount, greaterThan(0));
    });

    test(
        'pozwala na ręczną zmianę presetu w ustawieniach i powrót do trybu auto',
        () {
      GraphicsPreset? appliedPreset;
      final notifier = PlatformAdaptiveGraphicsProfilerNotifier(
        platformOverride: AdaptiveGraphicsPlatform.macOS,
        isTabletOverride: false,
        onApplyGamePreset: (preset) => appliedPreset = preset,
      );

      notifier.ingestFrameDurations(
        List<Duration>.generate(30, (_) => const Duration(milliseconds: 6)),
      );
      expect(
        notifier.state.activePreset,
        AdaptiveGraphicsProfilePreset.ultra120FpsDesktop,
      );

      notifier.setManualPresetOverride(
        AdaptiveGraphicsProfilePreset.balancedMobileBatterySaver,
      );

      expect(notifier.state.isManualOverrideActive, isTrue);
      expect(notifier.state.isAutoProfilingEnabled, isFalse);
      expect(
        notifier.state.activePreset,
        AdaptiveGraphicsProfilePreset.balancedMobileBatterySaver,
      );
      expect(appliedPreset, GraphicsPreset.batterySaver);

      notifier.enableAutoProfiling(restartBenchmark: false);
      expect(notifier.state.isManualOverrideActive, isFalse);
      expect(notifier.state.isAutoProfilingEnabled, isTrue);
      expect(
        notifier.state.activePreset,
        AdaptiveGraphicsProfilePreset.ultra120FpsDesktop,
      );
      expect(appliedPreset, GraphicsPreset.ultraMacPc);
    });

    test('serializuje i deserializuje stan profilera do JSON', () {
      final notifier = PlatformAdaptiveGraphicsProfilerNotifier(
        platformOverride: AdaptiveGraphicsPlatform.windows,
        isTabletOverride: false,
      );
      notifier.ingestFrameDurations(
        List<Duration>.generate(30, (_) => const Duration(milliseconds: 7)),
      );

      final json = notifier.state.toJson();
      final restored = PlatformAdaptiveGraphicsState.fromJson(json);

      expect(restored.platform, AdaptiveGraphicsPlatform.windows);
      expect(restored.samples.length, 30);
      expect(
        restored.activePreset,
        AdaptiveGraphicsProfilePreset.ultra120FpsDesktop,
      );
      expect(restored.telemetry.isProfilingComplete, isTrue);
    });
  });

  group('PlatformAdaptiveGraphicsProfilerPanel - responsywność i interakcje',
      () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez przepełnienia w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final notifier = PlatformAdaptiveGraphicsProfilerNotifier(
            platformOverride: AdaptiveGraphicsPlatform.windows,
            isTabletOverride: false,
          );
          notifier.ingestFrameDurations(
            List<Duration>.generate(
              30,
              (_) => const Duration(microseconds: 7500),
            ),
          );

          AdaptiveGraphicsProfilePreset? tappedPreset;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                backgroundColor: const Color(0xFF0F1115),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PlatformAdaptiveGraphicsProfilerPanel(
                    state: notifier.state,
                    onSelectPreset: (p) => tappedPreset = p,
                    onEnableAutoProfiling: () {},
                    onRerunBenchmark: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('Ultra 120 FPS Desktop'), findsOneWidget);
          expect(find.text('High 60 FPS Tablet'), findsOneWidget);
          expect(find.text('Balanced Mobile Battery Saver'), findsOneWidget);

          await tester.tap(find.text('High 60 FPS Tablet'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tappedPreset, AdaptiveGraphicsProfilePreset.high60FpsTablet);
        },
      );
    }
  });
}
