import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/real_time_cfd_vortex_and_drag_solver.dart';

void main() {
  group('RealTimeCfdVortexAndDragSolver', () {
    test('computes all 6 aero zones with shares summing to 1.0', () {
      const input = CfdSolverInput(
        groundSpeedKmh: 45.0,
        altitudeMeters: 250.0,
        temperatureCelsius: 22.0,
      );

      final result = RealTimeCfdVortexAndDragSolver.solveFrame(input);

      expect(result.zones.length, CfdAeroZone.values.length);
      final double totalShare = result.zones.fold(
        0.0,
        (sum, z) => sum + z.shareOfTotalDrag,
      );
      expect(totalShare, closeTo(1.0, 1e-6));
      expect(result.totalCdA, inInclusiveRange(0.20, 0.36));
      expect(result.totalAeroPowerWatts, greaterThan(220.0));
      expect(result.karmanDominantFrequencyHz, inInclusiveRange(7.0, 15.0));
    });

    test('TT aero setup dramatically reduces CdA and power vs rain crosswind', () {
      const ttInput = CfdSolverInput(
        groundSpeedKmh: 50.0,
        helmetType: CfdHelmetType.ttLongTeardrop,
        headTuckFactor: 0.9,
        forearmPosture: CfdForearmPosture.ttAeroBars,
        textileSpec: CfdTextileSpec.aeroSkinsuitRibbed,
        wheelSpec: CfdWheelProfileSpec.ttDiscRear80Front,
        tireWidthMm: 25.0,
        frameAeroIntegration: 1.0,
      );

      const rainInput = CfdSolverInput(
        groundSpeedKmh: 50.0,
        helmetType: CfdHelmetType.roadVented,
        headTuckFactor: 0.1,
        forearmPosture: CfdForearmPosture.hoodsWide,
        textileSpec: CfdTextileSpec.rainJacketFlapping,
        zipperOpenFraction: 0.8,
        wheelSpec: CfdWheelProfileSpec.shallowAlloy24,
        tireWidthMm: 30.0,
        frameAeroIntegration: 0.2,
      );

      final comparison = RealTimeCfdVortexAndDragSolver.compareConfigurations(
        baselineInput: rainInput,
        upgradedInput: ttInput,
        distanceKm: 40.0,
        riderPowerWatts: 400.0,
      );

      expect(comparison.deltaCdA, lessThan(-0.12));
      expect(comparison.wattsSaved, greaterThan(150.0));
      expect(comparison.timeSavedSeconds, greaterThan(250.0));
    });

    test('Rule of 105% and crosswind sailing effect behave accurately', () {
      const compliantInput = CfdSolverInput(
        groundSpeedKmh: 46.0,
        crosswindKmh: 8.5, // ~10.5 deg yaw
        wheelSpec: CfdWheelProfileSpec.deepCarbon65, // 28 mm external
        tireWidthMm: 26.0, // 26 * 1.05 = 27.3 <= 28
      );
      const nonCompliantInput = CfdSolverInput(
        groundSpeedKmh: 46.0,
        crosswindKmh: 8.5,
        wheelSpec: CfdWheelProfileSpec.deepCarbon65, // 28 mm external
        tireWidthMm: 32.0, // 32 * 1.05 = 33.6 > 28
      );

      final compliant = RealTimeCfdVortexAndDragSolver.solveFrame(compliantInput);
      final nonCompliant = RealTimeCfdVortexAndDragSolver.solveFrame(nonCompliantInput);

      expect(compliant.satisfiesRuleOf105, isTrue);
      expect(nonCompliant.satisfiesRuleOf105, isFalse);
      expect(
        compliant.zoneOf(CfdAeroZone.wheels).effectiveCdA,
        lessThan(nonCompliant.zoneOf(CfdAeroZone.wheels).effectiveCdA),
      );
      expect(compliant.sailingEffectWattsGain, greaterThan(4.0));
    });

    test('Karman vortex street produces alternating circulation and handles zero speed', () {
      const zeroSpeed = CfdSolverInput(groundSpeedKmh: 0.0);
      final zeroResult = RealTimeCfdVortexAndDragSolver.solveFrame(zeroSpeed);
      expect(zeroResult.karmanDominantFrequencyHz, equals(0.0));
      expect(zeroResult.totalAeroPowerWatts, equals(0.0));

      const fastInput = CfdSolverInput(groundSpeedKmh: 48.0, crosswindKmh: 6.0);
      final fastResult = RealTimeCfdVortexAndDragSolver.solveFrame(fastInput);
      final nodes = RealTimeCfdVortexAndDragSolver.sampleWakeVortexField(
        solverResult: fastResult,
        timeSeconds: 0.25,
        vortexPairCount: 8,
      );

      expect(nodes, isNotEmpty);
      expect(nodes.first.circulationStrength, greaterThan(0.0));
      if (nodes.length > 1) {
        expect(nodes[1].circulationStrength, lessThan(0.0));
      }
    });

    test('Yaw sweep covers range and drafting reduces aero power', () {
      const solo = CfdSolverInput(groundSpeedKmh: 45.0, draftingReduction: 0.0);
      const draft = CfdSolverInput(
        groundSpeedKmh: 45.0,
        draftingReduction: 0.42,
        gapToRiderAheadMeters: 0.8,
      );

      final soloRes = RealTimeCfdVortexAndDragSolver.solveFrame(solo);
      final draftRes = RealTimeCfdVortexAndDragSolver.solveFrame(draft);
      expect(draftRes.totalAeroPowerWatts, lessThan(soloRes.totalAeroPowerWatts * 0.65));

      final sweep = RealTimeCfdVortexAndDragSolver.sweepYawAngles(
        solo,
        minYawDegrees: -15.0,
        maxYawDegrees: 15.0,
        stepDegrees: 5.0,
      );
      expect(sweep.length, 7);
      expect(sweep.first.yawDegrees, -15.0);
      expect(sweep.last.yawDegrees, 15.0);
    });
  });

  group('RealTimeCfdVortexAndDragPanel responsiveness & interactions', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RealTimeCfdVortexAndDragPanel(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('REAL-TIME CFD VORTEX & ZONAL DRAG'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('switches presets when enabled and ignores taps when disabled',
        (tester) async {
      CfdSolverResult? lastResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealTimeCfdVortexAndDragPanel(
              onSolved: (res) => lastResult = res,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('TT Aero Setup'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastResult, isNotNull);
      expect(lastResult!.totalCdA, lessThan(0.24));

      lastResult = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealTimeCfdVortexAndDragPanel(
              enabled: false,
              onSolved: (res) => lastResult = res,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Rain Crosswind'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(lastResult, isNull);
    });
  });
}
