import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/rendering3d/broadcast_tv_graphics_overlay.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  const sampleSpotlight = BroadcastRiderSpotlightData(
    riderId: 'rider_1',
    riderName: 'Tadej Pogačar',
    teamName: 'UAE Team Emirates',
    teamShortCode: 'UAD',
    nationalityIso: 'SLO',
    gcPosition: 1,
    gcGapSeconds: 0.0,
    currentPowerWatts: 432.0,
    riderWeightKg: 66.0,
    heartRateBpm: 178,
    speedKmh: 24.6,
    isAttacking: true,
    isRaceLeader: true,
  );

  const sampleClimb = BroadcastClimbTelemetryData(
    climbName: 'Col du Galibier',
    category: SegmentClassification.horsCategorie,
    totalLengthKm: 17.7,
    remainingKm: 8.4,
    averageGradientPercent: 6.9,
    currentGradientPercent: 8.8,
    summitElevationM: 2642.0,
    currentElevationM: 2010.0,
    estimatedClimbTimeSeconds: 2715.0,
    leaderGroupVamMetersPerHour: 1685.0,
    elevationProfileSamples: [1420, 1600, 1850, 2100, 2380, 2642],
  );

  const sampleSplit = BroadcastLiveSplitData(
    checkpointName: 'Col du Galibier (HC)',
    checkpointType: BroadcastSplitCheckpointType.komSummit,
    baseElapsedSeconds: 125.43,
    isTimerRunning: true,
    topEntries: [
      BroadcastSplitEntry(
        rank: 1,
        riderName: 'Tadej Pogačar',
        teamShortCode: 'UAD',
        nationalityIso: 'SLO',
        gapSeconds: -12.0,
        elapsedSeconds: 2680.0,
      ),
      BroadcastSplitEntry(
        rank: 2,
        riderName: 'Jonas Vingegaard',
        teamShortCode: 'TVL',
        nationalityIso: 'DEN',
        gapSeconds: 0.0,
        elapsedSeconds: 2692.0,
      ),
      BroadcastSplitEntry(
        rank: 3,
        riderName: 'Remco Evenepoel',
        teamShortCode: 'SOQ',
        nationalityIso: 'BEL',
        gapSeconds: 28.0,
        elapsedSeconds: 2720.0,
      ),
      BroadcastSplitEntry(
        rank: 4,
        riderName: 'Primož Roglič',
        teamShortCode: 'RBH',
        nationalityIso: 'SLO',
        gapSeconds: 41.0,
        elapsedSeconds: 2733.0,
      ),
      BroadcastSplitEntry(
        rank: 5,
        riderName: 'Rafał Majka',
        teamShortCode: 'POL',
        nationalityIso: 'POL',
        gapSeconds: 55.0,
        elapsedSeconds: 2747.0,
      ),
    ],
  );

  group('BroadcastTvGraphicsOverlay formatters', () {
    test('formatHundredthsTimer formats MM:SS.cc and HH:MM:SS.cc', () {
      expect(
        BroadcastTvGraphicsOverlay.formatHundredthsTimer(125.43),
        '02:05.43',
      );
      expect(
        BroadcastTvGraphicsOverlay.formatHundredthsTimer(3725.09),
        '01:02:05.09',
      );
      expect(
        BroadcastTvGraphicsOverlay.formatHundredthsTimer(-5.0),
        '00:00.00',
      );
    });

    test('formatSplitGap formats negative, zero, and positive gaps', () {
      expect(BroadcastTvGraphicsOverlay.formatSplitGap(-12.0), "-0'12\"");
      expect(BroadcastTvGraphicsOverlay.formatSplitGap(28.0), "+0'28\"");
      expect(BroadcastTvGraphicsOverlay.formatSplitGap(0.0), "0'00\"");
      expect(BroadcastTvGraphicsOverlay.formatSplitGap(74.0), "+1'14\"");
    });
  });

  group('BroadcastTvGraphicsOverlay widget rendering & responsiveness', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders all 3 broadcast panels without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                backgroundColor: AppColors.background,
                body: BroadcastTvGraphicsOverlay(
                  riderSpotlight: sampleSpotlight,
                  climbTelemetry: sampleClimb,
                  liveSplit: sampleSplit,
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 50));

          expect(tester.takeException(), isNull);
          expect(find.text('TADEJ POGAČAR'), findsOneWidget);
          expect(find.text('Col du Galibier'), findsOneWidget);
          expect(find.text('HC'), findsOneWidget);
          expect(find.text('1685 m/h'), findsOneWidget);
          expect(find.text("-0'12\""), findsOneWidget);
          expect(find.text("+0'28\""), findsOneWidget);
        },
      );
    }

    testWidgets('live split timer ticks and supports pause/dismiss callbacks',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool dismissedSpotlight = false;
      String? tappedRiderId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: BroadcastTvGraphicsOverlay(
              riderSpotlight: sampleSpotlight,
              climbTelemetry: sampleClimb,
              liveSplit: sampleSplit,
              onDismissSpotlight: () => dismissedSpotlight = true,
              onRiderSpotlightTap: (id) => tappedRiderId = id,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('LIVE SPLIT'), findsOneWidget);

      await tester.tap(find.text('TADEJ POGAČAR'));
      await tester.pump();
      expect(tappedRiderId, 'rider_1');

      await tester.tap(find.byTooltip('Wstrzymaj stoper'));
      await tester.pump();
      expect(find.text('WSTRZYMANO'), findsOneWidget);

      await tester.tap(find.byTooltip('Ukryj prezentację kolarza'));
      await tester.pump();
      expect(dismissedSpotlight, isTrue);
    });
  });
}
