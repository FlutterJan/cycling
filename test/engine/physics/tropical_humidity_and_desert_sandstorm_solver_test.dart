import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/physics/tropical_humidity_and_desert_sandstorm_solver.dart';

void main() {
  group('TropicalHumidityAndDesertSandstormSolver', () {
    test('95% tropical humidity severely impairs sweat evaporation and raises WBGT', () {
      const tropicalInput = TropicalAndDesertClimateInput(
        temperatureCelsius: 34.0,
        relativeHumidityPercent: 95.0,
        altitudeMeters: 30.0,
        sandCondition: DesertSandCondition.cleanAsphalt,
        isRoadWet: true,
        riderPowerWatts: 320.0,
        heatAcclimatizationLevel: 0.1,
      );

      const dryTemperateInput = TropicalAndDesertClimateInput(
        temperatureCelsius: 20.0,
        relativeHumidityPercent: 50.0,
        altitudeMeters: 30.0,
        sandCondition: DesertSandCondition.cleanAsphalt,
        isRoadWet: false,
        riderPowerWatts: 320.0,
        heatAcclimatizationLevel: 0.1,
      );

      final tropicalResult =
          TropicalHumidityAndDesertSandstormSolver.solve(tropicalInput);
      final temperateResult =
          TropicalHumidityAndDesertSandstormSolver.solve(dryTemperateInput);

      expect(tropicalResult.sweatEvaporationEfficiency, lessThan(0.32));
      expect(
        tropicalResult.sweatEvaporationEfficiency,
        lessThan(temperateResult.sweatEvaporationEfficiency),
      );
      expect(tropicalResult.wbgtCelsius, greaterThan(30.0));
      expect(tropicalResult.coreTempDriftCelsiusPerHour, greaterThan(0.5));
      expect(tropicalResult.thermalPowerPenaltyFraction, greaterThan(0.05));
      expect(
        tropicalResult.riskLevel,
        anyOf(ExoticClimateRiskLevel.high, ExoticClimateRiskLevel.extreme),
      );
    });

    test('desert sandstorm sharply increases effective Crr and reduces speed', () {
      const cleanInput = TropicalAndDesertClimateInput(
        temperatureCelsius: 40.0,
        relativeHumidityPercent: 15.0,
        sandCondition: DesertSandCondition.cleanAsphalt,
        tireWidthMm: 28.0,
        isChainWaxed: true,
      );

      final sandstormInput = cleanInput.copyWith(
        sandCondition: DesertSandCondition.activeSandstorm,
      );

      final cleanRes =
          TropicalHumidityAndDesertSandstormSolver.solve(cleanInput);
      final stormRes =
          TropicalHumidityAndDesertSandstormSolver.solve(sandstormInput);

      expect(stormRes.effectiveCrr, greaterThan(cleanRes.effectiveCrr * 2.2));
      expect(stormRes.deltaCrr, greaterThan(0.0045));
      expect(stormRes.extraRollingPowerWatts, greaterThan(35.0));
      expect(stormRes.projectedFlatSpeedKmh, lessThan(cleanRes.projectedFlatSpeedKmh));
      expect(stormRes.riskLevel, ExoticClimateRiskLevel.extreme);
    });

    test('wider tires and waxed chain mitigate sand Crr and drivetrain grit loss', () {
      const narrowWetLube = TropicalAndDesertClimateInput(
        temperatureCelsius: 41.0,
        relativeHumidityPercent: 18.0,
        sandCondition: DesertSandCondition.heavySandSheet,
        tireWidthMm: 25.0,
        isChainWaxed: false,
      );

      final wideWaxed = narrowWetLube.copyWith(
        tireWidthMm: 32.0,
        isChainWaxed: true,
      );

      final resNarrow =
          TropicalHumidityAndDesertSandstormSolver.solve(narrowWetLube);
      final resWide = TropicalHumidityAndDesertSandstormSolver.solve(wideWaxed);

      expect(resWide.effectiveCrr, lessThan(resNarrow.effectiveCrr));
      expect(resWide.drivetrainEfficiency, greaterThan(resNarrow.drivetrainEfficiency));
      expect(resWide.projectedFlatSpeedKmh, greaterThan(resNarrow.projectedFlatSpeedKmh));
    });

    test('moist air is slightly less dense than dry air at identical temperature and altitude', () {
      final dryRho =
          TropicalHumidityAndDesertSandstormSolver.computeMoistAndDustyAirDensity(
        temperatureCelsius: 32.0,
        relativeHumidityPercent: 10.0,
        altitudeMeters: 0.0,
      );
      final humidRho =
          TropicalHumidityAndDesertSandstormSolver.computeMoistAndDustyAirDensity(
        temperatureCelsius: 32.0,
        relativeHumidityPercent: 95.0,
        altitudeMeters: 0.0,
      );

      expect(humidRho, lessThan(dryRho));
      expect(humidRho, greaterThan(1.05));
    });

    test('simulateStageProgression and compareTireAndLubeSetups return consistent telemetry', () {
      const input = TropicalAndDesertClimateInput(
        temperatureCelsius: 33.5,
        relativeHumidityPercent: 95.0,
        sandCondition: DesertSandCondition.sandDrifts,
        baseTireCrr: PhysicsConstants.crrSmoothAsphalt,
      );

      final segments =
          TropicalHumidityAndDesertSandstormSolver.simulateStageProgression(
        baseInput: input,
        totalDistanceKm: 150.0,
        segmentCount: 5,
      );

      expect(segments.length, 5);
      expect(segments.last.distanceKm, closeTo(150.0, 0.01));
      expect(
        segments.last.cumulativeCoreTempC,
        greaterThan(segments.first.cumulativeCoreTempC),
      );

      final comparisons =
          TropicalHumidityAndDesertSandstormSolver.compareTireAndLubeSetups(
        input,
      );
      expect(comparisons.length, 6);
      expect(comparisons.any((c) => c.deltaSecondsOver40Km == 0.0), isTrue);
    });
  });

  group('TropicalHumidityAndDesertSandstormPanel responsive layout', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
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
                child: TropicalHumidityAndDesertSandstormPanel(
                  initialPreset: ExoticClimatePreset.langkawiTropical95,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile viewport without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Efektywne Crr'), findsOneWidget);
      expect(find.text('Parowanie potu / WBGT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet viewport without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('AlUla Burza Piaskowa'), findsOneWidget);
      await tester.tap(find.text('AlUla Burza Piaskowa'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Ekstremalne'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop viewport without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(
        find.text('Solver Wilgotności Tropikalnej i Piasku Pustynnego'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
