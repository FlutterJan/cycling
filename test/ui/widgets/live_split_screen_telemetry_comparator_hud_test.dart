import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/live_split_screen_telemetry_comparator_hud.dart';

void main() {
  Widget buildSubject({
    required Size viewportSize,
    SplitScreenTelemetryComparisonData? data,
    bool isEnabled = true,
    ValueChanged<SplitScreenRiderTelemetry>? onFocusRider,
    ValueChanged<SplitScreenMetricMode>? onMetricModeChanged,
    VoidCallback? onSwapSides,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: LiveSplitScreenTelemetryComparatorHud(
              data: data ?? SplitScreenTelemetryComparisonData.sample(),
              isEnabled: isEnabled,
              onFocusRider: onFocusRider,
              onMetricModeChanged: onMetricModeChanged,
              onSwapSides: onSwapSides,
            ),
          ),
        ),
      ),
    );
  }

  group('LiveSplitScreenTelemetryComparatorHud', () {
    testWidgets('renders cleanly at 390x844 mobile without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSubject(viewportSize: const Size(390, 844)));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('T. POGAČAR'), findsWidgets);
      expect(find.text('J. VINGEGAARD'), findsWidgets);
      expect(find.text('LIVE SPLIT-SCREEN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildSubject(viewportSize: const Size(1024, 768)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PORÓWNANIE HEAD-TO-HEAD NA ŻYWO'), findsOneWidget);
      expect(find.text('PRZEBIEG MOCY DUAL-TRACE [W]'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        buildSubject(viewportSize: const Size(1600, 900)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('T. POGAČAR'), findsWidgets);
      expect(find.text('J. VINGEGAARD'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switches metric modes, swaps sides, and focuses rider', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SplitScreenMetricMode? selectedMode;
      SplitScreenRiderTelemetry? focusedRider;
      int swapCount = 0;

      await tester.pumpWidget(
        buildSubject(
          viewportSize: const Size(1280, 800),
          onMetricModeChanged: (SplitScreenMetricMode m) => selectedMode = m,
          onFocusRider: (SplitScreenRiderTelemetry r) => focusedRider = r,
          onSwapSides: () => swapCount++,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Moc & W\''));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selectedMode, SplitScreenMetricMode.powerAndWPrime);

      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(swapCount, 1);

      await tester.tap(find.text('T. POGAČAR').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(focusedRider?.riderId, 'leader_1');
    });

    testWidgets('respects disabled state and offline rider telemetry', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int swapCount = 0;
      final SplitScreenTelemetryComparisonData sample =
          SplitScreenTelemetryComparisonData.sample();
      final SplitScreenTelemetryComparisonData offlineData =
          SplitScreenTelemetryComparisonData(
        leader: sample.leader,
        rival: const SplitScreenRiderTelemetry(
          riderId: 'rival_off',
          riderName: 'R. EVENEPOEL',
          teamShortCode: 'SOQ',
          powerWatts: 0,
          cadenceRpm: 0,
          heartRateBpm: 0,
          speedKmh: 0,
          wPrimeRemainingKj: 0,
          hasLiveTelemetry: false,
        ),
        liveStageGapSeconds: 25.0,
        gcOverallGapSeconds: 50.0,
        isLiveFeedActive: false,
      );

      await tester.pumpWidget(
        buildSubject(
          viewportSize: const Size(1024, 768),
          data: offlineData,
          isEnabled: false,
          onSwapSides: () => swapCount++,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BRAK SYGNAŁU TELEMETRII'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(swapCount, 0);
    });
  });
}
