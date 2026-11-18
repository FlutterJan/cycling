import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/motor_pacing_and_aero_tuck_adaptation.dart';
import 'package:pro_peloton_manager/ui/widgets/aero_vs_road_power_efficiency_gauge.dart';

void main() {
  group('AeroVsRoadEfficiencyCalculator & Data', () {
    const AeroVsRoadComparisonData sample = AeroVsRoadComparisonData(
      riderName: 'Remco V.',
      roadFtpWatts: 420.0,
      aeroTtPowerWatts: 404.0,
      roadCda: 0.285,
      aeroCda: 0.205,
      posturePreset: AeroTuckPosturePreset.standardTtExtensions,
      adaptationScore: 88.0,
      hipOcclusionPenaltyPct: 2.1,
      respiratoryCostPenaltyPct: 1.7,
      targetSpeedKmh: 53.4,
      estimatedTimeGain40KmSeconds: 164.0,
    );

    test('computes power retention, delta, CdA reduction and W/CdA', () {
      expect(AeroVsRoadEfficiencyCalculator.hasValidTelemetry(sample), isTrue);
      expect(
        AeroVsRoadEfficiencyCalculator.powerRetentionPercent(sample),
        closeTo(96.19, 0.05),
      );
      expect(
        AeroVsRoadEfficiencyCalculator.powerDeltaWatts(sample),
        closeTo(-16.0, 0.01),
      );
      expect(
        AeroVsRoadEfficiencyCalculator.cdaReductionPercent(sample),
        closeTo(28.07, 0.05),
      );
      expect(
        AeroVsRoadEfficiencyCalculator.wattsPerCdaRoad(sample),
        closeTo(1473.68, 0.5),
      );
      expect(
        AeroVsRoadEfficiencyCalculator.wattsPerCdaAero(sample),
        closeTo(1970.73, 0.5),
      );
      expect(
        AeroVsRoadEfficiencyCalculator.netAeroEfficiencyGainPercent(sample),
        closeTo(33.72, 0.1),
      );
      expect(
        AeroVsRoadEfficiencyCalculator.tierForRetention(96.2),
        AeroPowerEfficiencyTier.elite,
      );
      expect(
        AeroVsRoadEfficiencyCalculator.tierForRetention(93.5),
        AeroPowerEfficiencyTier.optimal,
      );
      expect(
        AeroVsRoadEfficiencyCalculator.tierForRetention(89.0),
        AeroPowerEfficiencyTier.moderate,
      );
      expect(
        AeroVsRoadEfficiencyCalculator.tierForRetention(83.0),
        AeroPowerEfficiencyTier.compromised,
      );
    });

    test('handles zero/invalid FTP safely without NaN', () {
      const AeroVsRoadComparisonData invalid = AeroVsRoadComparisonData(
        riderName: 'Test',
        roadFtpWatts: 0.0,
        aeroTtPowerWatts: 250.0,
      );
      expect(AeroVsRoadEfficiencyCalculator.hasValidTelemetry(null), isFalse);
      expect(AeroVsRoadEfficiencyCalculator.hasValidTelemetry(invalid), isFalse);
      expect(AeroVsRoadEfficiencyCalculator.powerRetentionRatio(invalid), 0.0);
      expect(AeroVsRoadEfficiencyCalculator.powerRetentionPercent(invalid), 0.0);
    });

    test('JSON round-trip and fromAeroTuckResult preserve fields', () {
      final Map<String, dynamic> json = sample.toJson();
      final AeroVsRoadComparisonData restored =
          AeroVsRoadComparisonData.fromJson(json);

      expect(restored.riderName, sample.riderName);
      expect(restored.roadFtpWatts, sample.roadFtpWatts);
      expect(restored.aeroTtPowerWatts, sample.aeroTtPowerWatts);
      expect(restored.posturePreset, sample.posturePreset);
      expect(restored.targetSpeedKmh, sample.targetSpeedKmh);

      const AeroTuckPowerAndCdaResult engineResult = AeroTuckPowerAndCdaResult(
        effectiveSustainablePowerWatts: 396.0,
        unadaptedPowerDropPercent: 6.4,
        actualPowerDropPercent: 4.1,
        powerRecoveredByAdaptationWatts: 9.5,
        effectiveCda: 0.211,
        cdaPenaltyFromFatigue: 0.004,
        predictedTtSpeedKmh: 52.1,
        speedGainOverUnadaptedKmh: 1.4,
        timeSavedOver40KmSeconds: 121.0,
        hipOcclusionFactor: 0.025,
        respiratoryCostFactor: 0.018,
        postureStabilityRemaining: 0.91,
        breakdownRisk: PostureBreakdownRisk.rockSolid,
        adaptationTier: AeroAdaptationTier.worldTourTtSpecialist,
      );

      final AeroVsRoadComparisonData fromEngine =
          AeroVsRoadComparisonData.fromAeroTuckResult(
        riderName: 'Filippo G.',
        roadFtpWatts: 413.0,
        result: engineResult,
      );
      expect(fromEngine.aeroTtPowerWatts, 396.0);
      expect(fromEngine.aeroCda, 0.211);
      expect(fromEngine.hipOcclusionPenaltyPct, closeTo(2.5, 0.01));
    });
  });

  group('AeroVsRoadPowerEfficiencyGauge Widget', () {
    const AeroVsRoadComparisonData sample = AeroVsRoadComparisonData(
      riderName: 'Jonas V.',
      roadFtpWatts: 400.0,
      aeroTtPowerWatts: 376.0,
      roadCda: 0.280,
      aeroCda: 0.210,
      posturePreset: AeroTuckPosturePreset.standardTtExtensions,
      adaptationScore: 80.0,
      hipOcclusionPenaltyPct: 2.8,
      respiratoryCostPenaltyPct: 1.9,
      targetSpeedKmh: 51.8,
      estimatedTimeGain40KmSeconds: 145.0,
    );

    Widget buildHost({
      required Size size,
      required Widget child,
    }) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('renders metrics, toggles mode and selects posture',
        (WidgetTester tester) async {
      AeroTuckPosturePreset? selectedPosture;
      int optimizeCount = 0;

      await tester.pumpWidget(
        buildHost(
          size: const Size(1024, 768),
          child: AeroVsRoadPowerEfficiencyGauge(
            data: sample,
            onPostureSelected: (AeroTuckPosturePreset p) => selectedPosture = p,
            onOptimizePressed: () => optimizeCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('94.0%'), findsOneWidget);
      expect(find.text('376 W / 400 W'), findsOneWidget);
      expect(find.text('Wysoka Efektywność'), findsOneWidget);

      await tester.tap(find.text('Efektywność W/CdA'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ZYSK W/CdA'), findsOneWidget);

      await tester.tap(find.text('Niski TT (Praying Mantis)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selectedPosture, AeroTuckPosturePreset.extremeLowPrayingMantis);

      await tester.tap(find.text('Optymalizuj pozycję TT w tunelu'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(optimizeCount, 1);
    });

    testWidgets('ignores interactions when disabled and renders empty state',
        (WidgetTester tester) async {
      int optimizeCount = 0;

      await tester.pumpWidget(
        buildHost(
          size: const Size(1024, 768),
          child: AeroVsRoadPowerEfficiencyGauge(
            data: sample,
            isDisabled: true,
            onOptimizePressed: () => optimizeCount++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Optymalizuj pozycję TT w tunelu'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(optimizeCount, 0);

      await tester.pumpWidget(
        buildHost(
          size: const Size(1024, 768),
          child: const AeroVsRoadPowerEfficiencyGauge(data: null),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Brak danych telemetrycznych FTP'), findsOneWidget);
    });

    testWidgets('responsive without overflow on 390x844, 1024x768, 1600x900',
        (WidgetTester tester) async {
      const List<Size> sizes = <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      for (final Size viewport in sizes) {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildHost(
            size: viewport,
            child: AeroVsRoadPowerEfficiencyGauge(
              data: sample,
              onOptimizePressed: () {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('EFEKTYWNOŚĆ MOCY AERO VS SZOSA'), findsOneWidget);
      }
    });
  });
}
