import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/core/utils/performance_profiler_overlay.dart';
import 'package:pro_peloton_manager/core/utils/windows_desktop_window_config.dart';

void main() {
  tearDown(() {
    PerformanceTelemetryRegistry.instance.reset();
  });

  group('WindowsDesktopWindowConfig scaling & tiers', () {
    test('classifies desktop and responsive tiers accurately', () {
      expect(
        WindowsDesktopWindowConfig.classifyResolution(const Size(390, 844)),
        DesktopResolutionTier.compact,
      );
      expect(
        WindowsDesktopWindowConfig.classifyResolution(const Size(1024, 768)),
        DesktopResolutionTier.tablet,
      );
      expect(
        WindowsDesktopWindowConfig.classifyResolution(const Size(1280, 720)),
        DesktopResolutionTier.hd720,
      );
      expect(
        WindowsDesktopWindowConfig.classifyResolution(const Size(1920, 1080)),
        DesktopResolutionTier.fhd1080,
      );
      expect(
        WindowsDesktopWindowConfig.classifyResolution(const Size(2560, 1440)),
        DesktopResolutionTier.qhd1440,
      );
      expect(
        WindowsDesktopWindowConfig.classifyResolution(const Size(3840, 2160)),
        DesktopResolutionTier.uhd4k,
      );
    });

    test('computes monotonic crisp scale factors from 720p to 4K', () {
      final hd = WindowsDesktopWindowConfig.computeScaleMetrics(
        const Size(1280, 720),
        devicePixelRatio: 1.0,
      );
      final fhd = WindowsDesktopWindowConfig.computeScaleMetrics(
        const Size(1920, 1080),
        devicePixelRatio: 1.0,
      );
      final qhd = WindowsDesktopWindowConfig.computeScaleMetrics(
        const Size(2560, 1440),
        devicePixelRatio: 1.5,
      );
      final uhd4k = WindowsDesktopWindowConfig.computeScaleMetrics(
        const Size(3840, 2160),
        devicePixelRatio: 2.0,
      );

      expect(fhd.uiScaleFactor, closeTo(1.0, 0.001));
      expect(fhd.textScaleFactor, closeTo(1.0, 0.001));
      expect(hd.uiScaleFactor, lessThan(fhd.uiScaleFactor));
      expect(qhd.uiScaleFactor, greaterThan(fhd.uiScaleFactor));
      expect(uhd4k.uiScaleFactor, greaterThan(qhd.uiScaleFactor));
      expect(uhd4k.textScaleFactor, closeTo(1.2, 0.02));

      // Weryfikacja przyciągania do siatki fizycznych pikseli
      final snapped = WindowsDesktopWindowConfig.snapToPhysicalPixel(16.3, 2.0);
      expect(snapped, 16.5);
    });

    test('computes proportional card dimensions without negative values', () {
      final metrics = WindowsDesktopWindowConfig.computeScaleMetrics(
        const Size(2560, 1440),
        devicePixelRatio: 1.5,
      );
      final cardW = metrics.computeCardWidth(1200);
      final cardH = metrics.computeProportionalCardHeight(cardW);

      expect(cardW, greaterThan(220));
      expect(cardH, greaterThan(150));
    });
  });

  group('DesktopResponsiveScaler & DesktopWindowStatusBar widget', () {
    Future<void> pumpScalerAtSize(
      WidgetTester tester,
      Size size,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: DesktopResponsiveScaler(
                child: Builder(
                  builder: (context) {
                    final metrics = DesktopScaleScope.of(context);
                    return Center(
                      child: Text('Tier: ${metrics.tier.shortTag}'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders without overflow on 390x844, 1024x768, 1600x900, 4K',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
        Size(3840, 2160),
      ]) {
        await pumpScalerAtSize(tester, size);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('displays live Isolate physics thread load telemetry',
        (tester) async {
      PerformanceTelemetryRegistry.instance.updatePhysicsTick(
        microseconds: 850,
        riderCount: 176,
        isActive: true,
      );

      await pumpScalerAtSize(tester, const Size(1600, 900));

      expect(find.textContaining('850 µs'), findsOneWidget);
      expect(find.textContaining('176 kol.'), findsOneWidget);
    });

    testWidgets('toggles Fullscreen via button and F11 shortcut',
        (tester) async {
      await pumpScalerAtSize(tester, const Size(1600, 900));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DesktopWindowStatusBar)),
      );
      expect(container.read(desktopWindowProvider).isFullscreen, isFalse);

      await tester.tap(find.text('Pełny ekran'));
      await tester.pumpAndSettle();
      expect(container.read(desktopWindowProvider).isFullscreen, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.f11);
      await tester.pumpAndSettle();
      expect(container.read(desktopWindowProvider).isFullscreen, isFalse);
    });

    testWidgets('Screenshot Mode hides status bar and restores on ESC',
        (tester) async {
      await pumpScalerAtSize(tester, const Size(1600, 900));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DesktopWindowStatusBar)),
      );
      expect(find.byType(DesktopWindowStatusBar), findsOneWidget);

      await tester.tap(find.text('Zrzut 3D'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(container.read(desktopWindowProvider).isScreenshotMode, isTrue);
      expect(
        container.read(desktopWindowProvider).isCapturingScreenshot,
        isFalse,
      );
      expect(find.byType(DesktopWindowStatusBar), findsNothing);
      expect(find.text('Pokaż HUD (ESC / F12)'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(container.read(desktopWindowProvider).isScreenshotMode, isFalse);
      expect(find.byType(DesktopWindowStatusBar), findsOneWidget);
    });
  });
}
