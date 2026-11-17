import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/live_strava_segment_ghost_comparison_hud.dart';

void main() {
  group('LiveStravaSegmentGhostCalculator & Data', () {
    test('JSON round-trip preserves all segment telemetry fields', () {
      final LiveStravaSegmentGhostData original =
          LiveStravaSegmentGhostData.sampleAlpeDhuez(ahead: true);
      final Map<String, dynamic> json = original.toJson();
      final LiveStravaSegmentGhostData restored =
          LiveStravaSegmentGhostData.fromJson(json);

      expect(restored.segmentId, original.segmentId);
      expect(restored.segmentName, original.segmentName);
      expect(restored.komHolderName, original.komHolderName);
      expect(restored.komRecordSeconds, original.komRecordSeconds);
      expect(restored.distanceCoveredKm, original.distanceCoveredKm);
      expect(restored.riderElapsedSeconds, original.riderElapsedSeconds);
      expect(
        restored.ghostElapsedAtSameDistanceSeconds,
        original.ghostElapsedAtSameDistanceSeconds,
      );
      expect(restored.deltaHistorySeconds, original.deltaHistorySeconds);
    });

    test('computes live delta, projected summit time and status accurately', () {
      final LiveStravaSegmentGhostData ahead =
          LiveStravaSegmentGhostData.sampleAlpeDhuez(ahead: true);
      final double delta =
          LiveStravaSegmentGhostCalculator.liveDeltaSeconds(ahead);
      expect(delta, closeTo(-14.2, 0.01));
      expect(
        LiveStravaSegmentGhostCalculator.resolveStatus(ahead),
        KomGhostComparisonStatus.aheadOfKom,
      );

      final double projected =
          LiveStravaSegmentGhostCalculator.projectedSummitTimeSeconds(ahead);
      // 1358.4 + ((13.8 - 8.4) / 22.8) * 3600 = 1358.4 + 852.63 = 2211.03
      expect(projected, closeTo(2211.03, 0.2));
      expect(
        LiveStravaSegmentGhostCalculator.projectedSummitDeltaSeconds(ahead),
        lessThan(0.0),
      );

      final LiveStravaSegmentGhostData behind =
          LiveStravaSegmentGhostData.sampleAlpeDhuez(ahead: false);
      expect(
        LiveStravaSegmentGhostCalculator.liveDeltaSeconds(behind),
        closeTo(14.2, 0.01),
      );
      expect(
        LiveStravaSegmentGhostCalculator.resolveStatus(behind),
        KomGhostComparisonStatus.behindKom,
      );
    });

    test('handles NaN, Infinity and summit states safely', () {
      final LiveStravaSegmentGhostData broken =
          LiveStravaSegmentGhostData.sampleAlpeDhuez().copyWith(
        currentSpeedKmh: double.nan,
        distanceCoveredKm: double.infinity,
        wPrimeRemainingPercent: 12.0,
      );

      expect(
        LiveStravaSegmentGhostCalculator.projectedSummitTimeSeconds(broken)
            .isFinite,
        isTrue,
      );
      expect(
        LiveStravaSegmentGhostCalculator.resolveAdvice(broken),
        KomGhostPacingAdvice.redZoneWarning,
      );

      final LiveStravaSegmentGhostData summitNewKom =
          LiveStravaSegmentGhostData.sampleAlpeDhuez(
        ahead: true,
        hasCrossedSummitGate: true,
      );
      expect(
        LiveStravaSegmentGhostCalculator.resolveStatus(summitNewKom),
        KomGhostComparisonStatus.summitCrossedNewKom,
      );
      expect(
        LiveStravaSegmentGhostCalculator.formatRaceTime(2255.0),
        '37:35',
      );
      expect(
        LiveStravaSegmentGhostCalculator.formatSignedDelta(-14.24),
        '-14.2 s',
      );
    });
  });

  group('LiveStravaSegmentGhostComparisonHud Widget', () {
    testWidgets('renders standby state when data is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveStravaSegmentGhostComparisonHud(data: null),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak aktywnego segmentu KOM na tym odcinku trasy'),
        findsOneWidget,
      );
    });

    testWidgets('renders pre-gate countdown and live comparison states', (
      WidgetTester tester,
    ) async {
      final LiveStravaSegmentGhostData preGate =
          LiveStravaSegmentGhostData.sampleAlpeDhuez(
        hasCrossedStartGate: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveStravaSegmentGhostComparisonHud(data: preGate),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BRAMA POMIAROWA KOM ZA'), findsOneWidget);
      expect(find.text('240 m'), findsOneWidget);

      final LiveStravaSegmentGhostData liveAhead =
          LiveStravaSegmentGhostData.sampleAlpeDhuez(ahead: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveStravaSegmentGhostComparisonHud(data: liveAhead),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PRZEWAGA NAD KOM'), findsOneWidget);
      expect(find.text('-14.2 s'), findsOneWidget);
      expect(find.text('PROGNOZA NA SZCZYCIE'), findsOneWidget);
      expect(find.text('Rekord KOM: 37:35'), findsOneWidget);
    });

    testWidgets('handles interactive buttons and disabled state', (
      WidgetTester tester,
    ) async {
      bool? ghostLineVisible;
      int cameraFocusCalls = 0;
      int expandCalls = 0;

      final LiveStravaSegmentGhostData data =
          LiveStravaSegmentGhostData.sampleAlpeDhuez(ahead: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveStravaSegmentGhostComparisonHud(
                data: data,
                onGhostLineVisibilityChanged: (bool value) {
                  ghostLineVisible = value;
                },
                onFocusGhostCamera: () {
                  cameraFocusCalls++;
                },
                onToggleExpand: () {
                  expandCalls++;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(ghostLineVisible, isFalse);

      await tester.tap(find.byIcon(Icons.videocam_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(cameraFocusCalls, 1);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(expandCalls, 1);

      // Disabled state blocks callbacks
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LiveStravaSegmentGhostComparisonHud(
                data: data,
                enabled: false,
                onFocusGhostCamera: () {
                  cameraFocusCalls++;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.videocam_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(cameraFocusCalls, 1);
    });

    testWidgets(
      'responsive without overflow at 390x844, 1024x768, and 1600x900',
      (WidgetTester tester) async {
        final List<Size> viewports = <Size>[
          const Size(390, 844),
          const Size(1024, 768),
          const Size(1600, 900),
        ];

        for (final Size size in viewports) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LiveStravaSegmentGhostComparisonHud(
                      data: LiveStravaSegmentGhostData.sampleAlpeDhuez(
                        ahead: true,
                      ),
                      onFocusGhostCamera: () {},
                      onDismiss: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(
            find.byType(LiveStravaSegmentGhostComparisonHud),
            findsOneWidget,
          );
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
