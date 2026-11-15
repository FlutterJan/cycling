import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_telemetry_sparklines_card.dart';

void main() {
  group('MatchesBurnedCalculator', () {
    test('does not count surge of 15 seconds or less as a burned match', () {
      const double ftp = 350.0;
      final List<double> history = [
        ...List.filled(10, 280.0),
        ...List.filled(15, 430.0), // 430 > 420 (120% of 350), exactly 15s
        ...List.filled(10, 260.0),
      ];

      final result = MatchesBurnedCalculator.analyzeStageTelemetry(
        stagePowerHistoryWatts: history,
        ftpWatts: ftp,
        baseMaxSprintWatts: 1200.0,
      );

      expect(result.matchesBurned, 0);
      expect(result.sprintPenaltyPercent, 0.0);
      expect(result.effectiveMaxSprintWatts, 1200.0);
      expect(result.isAboveThresholdNow, isFalse);
    });

    test('counts surges >120% FTP lasting longer than 15 seconds and reduces max sprint', () {
      const double ftp = 350.0;
      final List<double> history = [
        ...List.filled(16, 450.0), // Match #1 (16s > 15s)
        ...List.filled(20, 250.0), // Recovery
        ...List.filled(18, 480.0), // Match #2 (18s > 15s)
        ...List.filled(10, 270.0),
      ];

      final result = MatchesBurnedCalculator.analyzeStageTelemetry(
        stagePowerHistoryWatts: history,
        ftpWatts: ftp,
        baseMaxSprintWatts: 1200.0,
      );

      expect(result.matchesBurned, 2);
      expect(result.sprintPenaltyPercent, 5.0);
      expect(result.effectiveMaxSprintWatts, closeTo(1140.0, 0.01));
    });

    test('tracks ongoing surge below 15s without counting completed match yet', () {
      const double ftp = 300.0;
      final List<double> history = [
        ...List.filled(20, 220.0),
        ...List.filled(9, 390.0), // 390 > 360 (120% of 300), active 9s
      ];

      final result = MatchesBurnedCalculator.analyzeStageTelemetry(
        stagePowerHistoryWatts: history,
        ftpWatts: ftp,
      );

      expect(result.matchesBurned, 0);
      expect(result.currentSurgeSeconds, 9);
      expect(result.isAboveThresholdNow, isTrue);
    });

    test('handles empty telemetry and zero FTP safely', () {
      final emptyResult = MatchesBurnedCalculator.analyzeStageTelemetry(
        stagePowerHistoryWatts: const [],
        ftpWatts: 350.0,
        baseMaxSprintWatts: 1100.0,
      );
      expect(emptyResult.matchesBurned, 0);
      expect(emptyResult.effectiveMaxSprintWatts, 1100.0);

      final zeroFtpResult = MatchesBurnedCalculator.analyzeStageTelemetry(
        stagePowerHistoryWatts: const [400.0, 500.0],
        ftpWatts: 0.0,
        baseMaxSprintWatts: 1100.0,
      );
      expect(zeroFtpResult.matchesBurned, 0);
      expect(zeroFtpResult.effectiveMaxSprintWatts, 1100.0);
    });

    test('resolves Coggan power zones Z1 through Z7 accurately', () {
      const double ftp = 300.0;
      expect(MatchesBurnedCalculator.resolvePowerZone(powerWatts: 120, ftpWatts: ftp).zone, 1);
      expect(MatchesBurnedCalculator.resolvePowerZone(powerWatts: 195, ftpWatts: ftp).zone, 2);
      expect(MatchesBurnedCalculator.resolvePowerZone(powerWatts: 245, ftpWatts: ftp).zone, 3);
      expect(MatchesBurnedCalculator.resolvePowerZone(powerWatts: 295, ftpWatts: ftp).zone, 4);
      expect(MatchesBurnedCalculator.resolvePowerZone(powerWatts: 340, ftpWatts: ftp).zone, 5);
      expect(MatchesBurnedCalculator.resolvePowerZone(powerWatts: 400, ftpWatts: ftp).zone, 6);
      expect(MatchesBurnedCalculator.resolvePowerZone(powerWatts: 520, ftpWatts: ftp).zone, 7);
    });
  });

  group('RiderTelemetrySparklinesCard Widget', () {
    List<TelemetrySample> buildSamples() {
      return List.generate(60, (i) {
        final double watts = i >= 20 && i <= 38 ? 460.0 : 280.0 + (i % 5) * 8;
        final int hr = 148 + (i % 25);
        return TelemetrySample(
          timestampSeconds: 1000 + i,
          powerWatts: watts,
          heartRateBpm: hr,
        );
      });
    }

    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size, {
      bool showLab = false,
      bool isDisabled = false,
      VoidCallback? onTap,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: RiderTelemetrySparklinesCard(
                data: RiderTelemetrySparklinesData(
                  riderId: 'r1',
                  riderName: 'Tadej Pogačar',
                  ftpWatts: 360.0,
                  baseMaxSprintWatts: 1200.0,
                  last60sSamples: buildSamples(),
                ),
                showLaboratoryDetails: showLab,
                isDisabled: isDisabled,
                onTap: onTap,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('renders without overflow at 390x844, 1024x768, and 1600x900', (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpAtSize(tester, size, showLab: true);
        expect(find.text('Tadej Pogačar'), findsOneWidget);
        expect(find.text('Spalone zapałki'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('displays burned match count and handles tap when enabled', (tester) async {
      int taps = 0;
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        onTap: () => taps++,
      );

      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byType(RiderTelemetrySparklinesCard));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('ignores tap when disabled', (tester) async {
      int taps = 0;
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        isDisabled: true,
        onTap: () => taps++,
      );

      await tester.tap(find.byType(RiderTelemetrySparklinesCard));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('renders empty state gracefully', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: RiderTelemetrySparklinesCard(
              data: RiderTelemetrySparklinesData(
                riderId: 'r2',
                riderName: 'Jonas Vingegaard',
                ftpWatts: 370.0,
                baseMaxSprintWatts: 1100.0,
                last60sSamples: [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Brak danych telemetrycznych (60s)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
