import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_itt_split_timer_comparison_hud.dart';

void main() {
  TvIttSplitTimerData buildSampleData({
    double currentElapsedSeconds = 740.25,
    double riderDistanceKm = 18.4,
    double? t1RiderTime = 712.40,
    double? t2RiderTime,
    double? t3RiderTime,
    double? t1BestTime = 714.85,
    double? t2BestTime = 1480.50,
    double? t3BestTime = 2210.12,
  }) {
    return TvIttSplitTimerData(
      riderId: 'rider-1',
      riderName: 'Filippo Ganna',
      teamShortCode: 'IGD',
      bibNumber: 1,
      isPlayerTeam: true,
      isProvisionalLeader: t1RiderTime != null &&
          t1BestTime != null &&
          t1RiderTime < t1BestTime,
      currentElapsedSeconds: currentElapsedSeconds,
      riderDistanceKm: riderDistanceKm,
      totalStageDistanceKm: 36.5,
      currentSpeedKmh: 54.8,
      currentPowerWatts: 465,
      checkpoints: <IttSplitCheckpointData>[
        IttSplitCheckpointData(
          checkpoint: IttSplitCheckpointType.split1,
          distanceKm: 10.5,
          bestTimeSeconds: t1BestTime,
          bestRiderName: 'R. Evenepoel',
          riderSplitTimeSeconds: t1RiderTime,
          rankAtCheckpoint: 1,
        ),
        IttSplitCheckpointData(
          checkpoint: IttSplitCheckpointType.split2,
          distanceKm: 21.8,
          bestTimeSeconds: t2BestTime,
          bestRiderName: 'R. Evenepoel',
          riderSplitTimeSeconds: t2RiderTime,
          rankAtCheckpoint: t2RiderTime != null ? 2 : null,
        ),
        IttSplitCheckpointData(
          checkpoint: IttSplitCheckpointType.split3,
          distanceKm: 30.2,
          bestTimeSeconds: t3BestTime,
          bestRiderName: 'J. Vingegaard',
          riderSplitTimeSeconds: t3RiderTime,
          rankAtCheckpoint: t3RiderTime != null ? 3 : null,
        ),
      ],
    );
  }

  group('TvIttSplitTimerComparisonHud formatting', () {
    test('formatStopwatchHundredths formats minutes, hours and hundredths', () {
      expect(
        TvIttSplitTimerComparisonHud.formatStopwatchHundredths(0.0),
        '00:00.00',
      );
      expect(
        TvIttSplitTimerComparisonHud.formatStopwatchHundredths(714.85),
        '11:54.85',
      );
      expect(
        TvIttSplitTimerComparisonHud.formatStopwatchHundredths(3665.07),
        '1:01:05.07',
      );
      expect(
        TvIttSplitTimerComparisonHud.formatStopwatchHundredths(double.nan),
        '00:00.00',
      );
    });

    test('formatSplitDelta formats negative and positive hundredths', () {
      expect(
        TvIttSplitTimerComparisonHud.formatSplitDelta(-2.45),
        '-2.45 s',
      );
      expect(
        TvIttSplitTimerComparisonHud.formatSplitDelta(3.18),
        '+3.18 s',
      );
      expect(
        TvIttSplitTimerComparisonHud.formatSplitDelta(0.0),
        '-0.00 s',
      );
      expect(
        TvIttSplitTimerComparisonHud.formatSplitDelta(74.25),
        "+1'14.25\"",
      );
    });
  });

  group('TvIttSplitTimerComparisonHud widget behavior', () {
    testWidgets(
      'displays live hundredths countdown before crossing T2 and green/red photocell delta after crossing',
      (WidgetTester tester) async {
        // T1 crossed (-2.45 s), T2 approaching (1480.50 - 1465.23 = 15.27 s left)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: SizedBox(
                  width: 680,
                  child: TvIttSplitTimerComparisonHud(
                    data: buildSampleData(
                      currentElapsedSeconds: 1465.23,
                      riderDistanceKm: 21.3,
                      t1RiderTime: 712.40,
                      t2RiderTime: null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Stopwatch with hundredths
        expect(find.text('24:25.23'), findsOneWidget);
        // Active upcoming checkpoint is T2 with countdown 00:15.27
        expect(find.text('00:15.27'), findsAtLeastNWidgets(1));
        // T1 pill shows -2.45 s
        expect(find.text('-2.45 s'), findsOneWidget);

        // Tap T1 pill to inspect green photocell card
        await tester.tap(find.text('T1'));
        await tester.pumpAndSettle();
        expect(find.text('-2.45 s'), findsNWidgets(2));

        // Now cross T2 slower (+4.12 s) -> red photocell background
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: SizedBox(
                  width: 680,
                  child: TvIttSplitTimerComparisonHud(
                    selectedCheckpoint: IttSplitCheckpointType.split2,
                    data: buildSampleData(
                      currentElapsedSeconds: 1484.62,
                      riderDistanceKm: 21.8,
                      t1RiderTime: 712.40,
                      t2RiderTime: 1484.62,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('+4.12 s'), findsNWidgets(2));
      },
    );

    testWidgets('handles first reference rider without benchmark and collapse toggle',
        (WidgetTester tester) async {
      bool? expandedState;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: SizedBox(
                width: 640,
                child: TvIttSplitTimerComparisonHud(
                  onToggleExpanded: (bool v) => expandedState = v,
                  data: buildSampleData(
                    t1BestTime: null,
                    t2BestTime: null,
                    t3BestTime: null,
                    t1RiderTime: 710.00,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PIERWSZY NA TRASIE'), findsOneWidget);
      expect(find.text('P1 BAZA'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();
      expect(expandedState, isFalse);
    });

    testWidgets('renders without overflow across 390x844, 1024x768 and 1600x900',
        (WidgetTester tester) async {
      final List<Size> viewports = <Size>[
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      for (final Size size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: TvIttSplitTimerComparisonHud(
                  data: buildSampleData(
                    t1RiderTime: 712.40,
                    t2RiderTime: 1485.00,
                    t3RiderTime: null,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
