import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/equipment/drivetrain_gearing_configuration.dart';
import 'package:pro_peloton_manager/ui/widgets/gearing_ratio_speed_cadence_chart.dart';

void main() {
  group('GearingRatioChartCalculator', () {
    test('generates 24 sorted gear points for 2x12 drivetrain at 90 RPM', () {
      final config = DrivetrainGearingConfiguration.allRounder();
      final points = GearingRatioChartCalculator.buildGearPoints(config);

      expect(points.length, 24);
      expect(points.first.gearNumber, 1);
      expect(points.last.gearNumber, 24);

      for (var i = 1; i < points.length; i++) {
        expect(points[i].ratio >= points[i - 1].ratio, isTrue);
      }

      // Najlżejsze przełożenie 36x30T = 1.20 przy 90 RPM i 2136 mm:
      // 1.20 * 2.136 * 90 * 60 / 1000 = 13.84 km/h
      expect(points.first.frontTeeth, 36);
      expect(points.first.rearTeeth, 30);
      expect(points.first.speedAtReferenceCadenceKmh, closeTo(13.84, 0.05));
      expect(points.first.speedAtMinClimbCadenceKmh, closeTo(10.77, 0.05));

      // Najtwardsze przełożenie 52x11T = 4.727 przy 90 RPM: ~54.52 km/h
      expect(points.last.frontTeeth, 52);
      expect(points.last.rearTeeth, 11);
      expect(points.last.speedAtReferenceCadenceKmh, closeTo(54.52, 0.1));
    });

    test('generates 12 gear points for 1x12 aero drivetrain', () {
      final config = DrivetrainGearingConfiguration.timeTrialAero();
      final points = GearingRatioChartCalculator.buildGearPoints(config);

      expect(points.length, 12);
      expect(points.every((p) => p.frontTeeth == 58), isTrue);
      expect(points.every((p) => !p.isCrossChained), isTrue);
    });

    test('computes realistic 15% climb minimum speed and power at 70 RPM', () {
      final climber = DrivetrainGearingConfiguration.alpineClimber();
      final climberSummary =
          GearingRatioChartCalculator.computeSteepClimbSummary(climber);

      // 34x34T (ratio 1.00) @ 70 RPM = 8.97 km/h
      expect(climberSummary.easiestGearLabel, '34x34T');
      expect(climberSummary.minSpeedAt70RpmKmh, closeTo(8.97, 0.05));
      expect(climberSummary.requiredWattsPerKgAt15Percent, inInclusiveRange(3.5, 5.0));

      const proStandard = DrivetrainGearingConfiguration(
        chainring: CranksetChainringOption.proStandard54_40,
        cassette: Cassette12SpeedOption.sprint11_28,
      );
      final proSummary =
          GearingRatioChartCalculator.computeSteepClimbSummary(proStandard);

      // 40x28T wymaga znacznie wyższej prędkości i mocy na 15% niż 34x34T
      expect(
        proSummary.minSpeedAt70RpmKmh,
        greaterThan(climberSummary.minSpeedAt70RpmKmh + 3.0),
      );
      expect(
        proSummary.requiredPowerWattsAt15Percent,
        greaterThan(climberSummary.requiredPowerWattsAt15Percent + 100.0),
      );
    });
  });

  group('GearingRatioSpeedCadenceChart Widget', () {
    testWidgets('updates crankset/cassette and hides cross-chained gears',
        (tester) async {
      DrivetrainGearingConfiguration? latestConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GearingRatioSpeedCadenceChart(
                onConfigurationChanged: (cfg) => latestConfig = cfg,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('24 BIEGÓW'), findsOneWidget);
      expect(find.textContaining('24 poz.'), findsOneWidget);

      // Zmiana korby na 50/34T Compact
      await tester.tap(find.text('50/34T Compact'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestConfig?.chainring, CranksetChainringOption.compact50_34);

      // Zmiana kasety na 11-34T
      await tester.tap(find.text('11-34T'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(latestConfig?.cassette, Cassette12SpeedOption.climbing11_34);
      expect(find.text('OPTYMALNE NA 15%'), findsOneWidget);

      // Ukrycie przekosów łańcucha (4 kombinacje cross-chain -> 20 pozycji)
      await tester.tap(find.text('Ukryj przekosy'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('20 poz.'), findsOneWidget);
    });

    testWidgets('respects disabled state without triggering callbacks',
        (tester) async {
      var callbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GearingRatioSpeedCadenceChart(
                enabled: false,
                onConfigurationChanged: (_) => callbackCount++,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('50/34T Compact'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(callbackCount, 0);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: GearingRatioSpeedCadenceChart(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(GearingRatioSpeedCadenceChart), findsOneWidget);
        },
      );
    }
  });
}
