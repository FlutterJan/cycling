import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/tv_rider_biometrics_telemetry_box.dart';

void main() {
  TvRiderBiometricsData buildSampleData({
    int heartRateBpm = 179,
    int maxHeartRateBpm = 195,
    double powerWatts = 445.0,
    double ftpWatts = 390.0,
    double riderWeightKg = 66.0,
    int cadenceRpm = 96,
    double wPrimeRemainingKj = 12.4,
    double wPrimeMaxKj = 22.0,
    double wPrimeDeltaKjPerSec = -0.38,
    bool isAttacking = true,
    bool isLiveFeedActive = true,
  }) {
    return TvRiderBiometricsData(
      riderId: 'rider_1',
      riderName: 'T. Pogačar',
      teamShortCode: 'UAD',
      bibNumber: 1,
      heartRateBpm: heartRateBpm,
      maxHeartRateBpm: maxHeartRateBpm,
      powerWatts: powerWatts,
      ftpWatts: ftpWatts,
      riderWeightKg: riderWeightKg,
      cadenceRpm: cadenceRpm,
      wPrimeRemainingKj: wPrimeRemainingKj,
      wPrimeMaxKj: wPrimeMaxKj,
      wPrimeDeltaKjPerSec: wPrimeDeltaKjPerSec,
      heartRateHistoryBpm: const <int>[168, 171, 174, 176, 179],
      isAttacking: isAttacking,
      isLiveFeedActive: isLiveFeedActive,
    );
  }

  group('TvRiderBiometricsData', () {
    test('calculates HRmax percent, power zones Z1-Z7 and W/kg accurately', () {
      final TvRiderBiometricsData z5Data = buildSampleData(
        heartRateBpm: 180,
        maxHeartRateBpm: 200,
        powerWatts: 440.0,
        ftpWatts: 400.0,
        riderWeightKg: 65.0,
      );

      expect(z5Data.heartRateMaxPercent, 90);
      expect(z5Data.powerZone, 5);
      expect(z5Data.powerZoneName, 'VO2 MAX');
      expect(z5Data.wattsPerKg, closeTo(6.77, 0.01));

      expect(buildSampleData(powerWatts: 180, ftpWatts: 400).powerZone, 1);
      expect(buildSampleData(powerWatts: 260, ftpWatts: 400).powerZone, 2);
      expect(buildSampleData(powerWatts: 330, ftpWatts: 400).powerZone, 3);
      expect(buildSampleData(powerWatts: 400, ftpWatts: 400).powerZone, 4);
      expect(buildSampleData(powerWatts: 520, ftpWatts: 400).powerZone, 6);
      expect(buildSampleData(powerWatts: 750, ftpWatts: 400).powerZone, 7);
    });

    test('handles NaN, zero and boundary values safely', () {
      const TvRiderBiometricsData edge = TvRiderBiometricsData(
        riderId: 'edge',
        riderName: 'Edge Rider',
        teamShortCode: 'TST',
        heartRateBpm: -10,
        maxHeartRateBpm: 0,
        powerWatts: double.nan,
        ftpWatts: 0,
        riderWeightKg: 0,
        cadenceRpm: -5,
        wPrimeRemainingKj: double.infinity,
        wPrimeMaxKj: 0,
        wPrimeDeltaKjPerSec: double.nan,
      );

      expect(edge.safeHeartRateBpm, 0);
      expect(edge.heartRateMaxPercent, 0);
      expect(edge.safePowerWatts, 0.0);
      expect(edge.wattsPerKg, 0.0);
      expect(edge.safeCadenceRpm, 0);
      expect(edge.cadenceProfileLabel, 'COASTING');
      expect(edge.wPrimePercent, 0);
      expect(edge.wPrimeStatus, WPrimeBatteryStatus.depleted);
    });
  });

  group('TvRiderBiometricsTelemetryBox', () {
    testWidgets('renders ECG BPM, %HRmax, Z1-Z7, cadence RPM and W prime bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 420,
                child: TvRiderBiometricsTelemetryBox(
                  data: buildSampleData(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('UAD #1'), findsOneWidget);
      expect(find.text('T. POGAČAR'), findsOneWidget);
      expect(find.text('179'), findsOneWidget);
      expect(find.text('92% HRmax'), findsOneWidget);
      expect(find.text('Z5'), findsNWidgets(2));
      expect(find.text('445'), findsOneWidget);
      expect(find.text('96'), findsOneWidget);
      expect(find.text('RPM'), findsOneWidget);
      expect(find.text('12.4 / 22.0 kJ'), findsOneWidget);
      expect(find.text('56% BAL'), findsOneWidget);
      expect(find.text('-0.38 kJ/s'), findsOneWidget);
    });

    testWidgets('supports tap, expand toggle and disabled state', (
      WidgetTester tester,
    ) async {
      int tapCount = 0;
      bool expanded = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Center(
                  child: SizedBox(
                    width: 400,
                    child: TvRiderBiometricsTelemetryBox(
                      data: buildSampleData(isLiveFeedActive: false),
                      isSelected: true,
                      isExpanded: expanded,
                      onTap: () => tapCount++,
                      onExpandedChanged: (bool next) =>
                          setState(() => expanded = next),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Z7'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();
      expect(expanded, isFalse);
      expect(find.text('Z7'), findsNothing);

      await tester.tap(find.text('T. POGAČAR'));
      await tester.pumpAndSettle();
      expect(tapCount, 1);

      // Disabled state ignores taps
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: TvRiderBiometricsTelemetryBox(
                  data: buildSampleData(isLiveFeedActive: false),
                  enabled: false,
                  onTap: () => tapCount++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('T. POGAČAR'));
      await tester.pumpAndSettle();
      expect(tapCount, 1);
    });

    testWidgets(
      'renders cleanly without overflow at 390x844, 1024x768 and 1600x900',
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
                body: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width < 500 ? size.width - 24 : 560,
                    ),
                    child: TvRiderBiometricsTelemetryBox(
                      data: buildSampleData(
                        wPrimeRemainingKj: 3.1,
                        wPrimeMaxKj: 22.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull);
        }

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}
