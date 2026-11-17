import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/aero_calculator.dart';
import 'package:pro_peloton_manager/engine/physics/crosswind_wheel_stability_and_gust_solver.dart';
import 'package:pro_peloton_manager/models/equipment/wheelset_model.dart';

void main() {
  group('CrosswindWheelStabilityAndGustSolver', () {
    test('65-80mm deep carbon rims produce higher steering torque and sway than 32mm shallow rims', () {
      const shallowInput = CrosswindWheelStabilityInput(
        riderSpeedMs: 13.0,
        steadyWindSpeedMs: 8.0,
        gustPeakSpeedMs: 16.0,
        windRelativeAngleDeg: 85.0,
        frontRimDepthMm: 32,
        rearRimDepthMm: 32,
        environment: CrosswindGustEnvironment.coastalBridge,
      );

      final deepInput = shallowInput.copyWith(
        frontRimDepthMm: 80,
        rearRimDepthMm: 80,
      );

      final shallowResult =
          CrosswindWheelStabilityAndGustSolver.solve(shallowInput);
      final deepResult = CrosswindWheelStabilityAndGustSolver.solve(deepInput);

      expect(shallowResult.isDeepSection65to80, isFalse);
      expect(deepResult.isDeepSection65to80, isTrue);
      expect(
        deepResult.gustPeakSteeringTorqueNm,
        greaterThan(shallowResult.gustPeakSteeringTorqueNm * 1.5),
      );
      expect(
        deepResult.estimatedLateralSwayMeters,
        greaterThan(shallowResult.estimatedLateralSwayMeters),
      );
      expect(
        deepResult.instabilityIndex,
        greaterThan(shallowResult.instabilityIndex),
      );
    });

    test('modern toroidal U-shape reduces steering torque vs traditional V-shape', () {
      const vShape = CrosswindWheelStabilityInput(
        riderSpeedMs: 14.0,
        steadyWindSpeedMs: 9.0,
        gustPeakSpeedMs: 17.0,
        frontRimDepthMm: 65,
        rearRimDepthMm: 80,
        rimProfileShape: RimProfileShape.traditionalVShape,
      );
      final uShape = vShape.copyWith(
        rimProfileShape: RimProfileShape.modernToroidalUShape,
      );

      final vRes = CrosswindWheelStabilityAndGustSolver.solve(vShape);
      final uRes = CrosswindWheelStabilityAndGustSolver.solve(uShape);

      expect(uRes.gustPeakSteeringTorqueNm, lessThan(vRes.gustPeakSteeringTorqueNm));
      expect(uRes.instabilityIndex, lessThan(vRes.instabilityIndex));
    });

    test('heavier rider, higher handling skill, and peloton shelter improve stability', () {
      const lightExposed = CrosswindWheelStabilityInput(
        riderSpeedMs: 15.0,
        steadyWindSpeedMs: 10.0,
        gustPeakSpeedMs: 19.0,
        frontRimDepthMm: 65,
        rearRimDepthMm: 80,
        riderAndBikeMassKg: 58.0,
        bikeHandlingSkill: 60,
        pelotonShelterFactor: 0.0,
      );

      final heavySheltered = lightExposed.copyWith(
        riderAndBikeMassKg: 82.0,
        bikeHandlingSkill: 92,
        pelotonShelterFactor: 0.65,
      );

      final lightRes = CrosswindWheelStabilityAndGustSolver.solve(lightExposed);
      final heavyRes = CrosswindWheelStabilityAndGustSolver.solve(heavySheltered);

      expect(heavyRes.estimatedLateralSwayMeters,
          lessThan(lightRes.estimatedLateralSwayMeters));
      expect(heavyRes.instabilityIndex, lessThan(lightRes.instabilityIndex));
    });

    test('sailing effect saves watts at moderate yaw angles on 65-80mm wheels', () {
      const moderateCrosswind = CrosswindWheelStabilityInput(
        riderSpeedMs: 13.5,
        steadyWindSpeedMs: 5.0,
        gustPeakSpeedMs: 5.5,
        windRelativeAngleDeg: 55.0,
        frontRimDepthMm: 65,
        rearRimDepthMm: 80,
      );

      final result =
          CrosswindWheelStabilityAndGustSolver.solve(moderateCrosswind);

      expect(result.apparentYawAngleDeg, inInclusiveRange(5.0, 25.0));
      expect(result.sailingAeroSavingsWatts, greaterThan(2.0));
      expect(result.stabilityLevel, CrosswindStabilityLevel.rockSolid);
    });

    test('extreme coastal bridge gust recommends switching away from deep front wheel', () {
      const extremeGust = CrosswindWheelStabilityInput(
        riderSpeedMs: 18.0,
        steadyWindSpeedMs: 13.0,
        gustPeakSpeedMs: 24.0,
        windRelativeAngleDeg: 90.0,
        frontRimDepthMm: 80,
        rearRimDepthMm: 80,
        riderAndBikeMassKg: 62.0,
        riderPosition: RiderPosition.timeTrial,
        environment: CrosswindGustEnvironment.coastalBridge,
        isWetAsphalt: true,
      );

      final result = CrosswindWheelStabilityAndGustSolver.solve(extremeGust);

      expect(result.instabilityIndex, greaterThan(0.70));
      expect(
        result.recommendation,
        isNot(CrosswindWheelRecommendation.optimalDeepSection),
      );
      expect(result.speedPenaltyMs, greaterThan(0.0));
    });

    test('fromWheelset factory and simulateGustSequence produce valid telemetry', () {
      const wheelset = WheelsetModel(
        id: 'ws_aero_65',
        brandId: 'brand_pro',
        name: 'Aero Carbon 65',
        rimDepthMm: 65,
        weightGrams: 1480,
        aeroCdaModifier: -0.012,
        crosswindStabilityPenalty: 0.45,
        momentOfInertia: 0.088,
        hubEngagementDragWatts: 1.4,
        priceEur: 2400,
      );

      final input = CrosswindWheelStabilityInput.fromWheelset(
        wheelset: wheelset,
        rearRimDepthOverrideMm: 80,
        riderSpeedMs: 13.0,
        steadyWindSpeedMs: 8.0,
        gustPeakSpeedMs: 16.0,
        environment: CrosswindGustEnvironment.forestBreak,
      );

      final sequence =
          CrosswindWheelStabilityAndGustSolver.simulateGustSequence(input);

      expect(sequence.steps, isNotEmpty);
      expect(sequence.peakLateralSwayMeters, greaterThan(0.0));
      expect(sequence.peakSteeringTorqueNm, greaterThan(0.0));
      expect(sequence.recoveryTimeSeconds, greaterThan(0.0));

      final comparisons =
          CrosswindWheelStabilityAndGustSolver.compareRimDepths(input);
      expect(comparisons.length, 4);
      expect(
        comparisons.last.result.gustPeakSteeringTorqueNm,
        greaterThan(comparisons.first.result.gustPeakSteeringTorqueNm),
      );
    });
  });

  group('CrosswindWheelStabilityPanel responsive UI', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(8),
              child: CrosswindWheelStabilityPanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('65/80 mm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet and updates on chip tap',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('32 mm'), findsOneWidget);

      await tester.tap(find.text('32 mm'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop without overflow',
        (tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(
        find.text('AERODYNAMIKA STOŻKÓW 65–80 MM & PODMUCHY BOCZNE'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
