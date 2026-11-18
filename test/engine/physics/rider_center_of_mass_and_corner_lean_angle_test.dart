import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/physics/rider_center_of_mass_and_corner_lean_angle.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('RiderCenterOfMassAndCornerLeanAngle', () {
    test('computes exact arctan(v^2 / (g * R)) lean angle on flat road', () {
      const double speedMs = 20.0;
      const double radiusM = 45.0;
      final double expectedDeg =
          math.atan((speedMs * speedMs) / (PhysicsConstants.gravity * radiusM)) *
              180.0 /
              math.pi;

      final double computedDeg =
          RiderCenterOfMassAndCornerLeanAngle.computeIdealLeanAngleDegrees(
        speedMs: speedMs,
        cornerRadiusMeters: radiusM,
      );

      expect(computedDeg, closeTo(expectedDeg, 1e-6));

      final CornerLeanPhysicsResult result =
          RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(
        const CornerLeanPhysicsInput(
          speedMs: speedMs,
          cornerRadiusMeters: radiusM,
          bodyBalanceStyle: CornerBodyBalanceStyle.uprightNeutral,
        ),
      );

      expect(result.theoreticalLeanAngleDeg, closeTo(expectedDeg, 1e-6));
      expect(result.effectiveComLeanAngleDeg, closeTo(expectedDeg, 1e-6));
      expect(result.bikeFrameLeanAngleDeg, closeTo(expectedDeg, 1e-6));
    });

    test('caps max safe lean angle at 42 degrees on dry smooth asphalt', () {
      final CornerLeanPhysicsResult dryResult =
          RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(
        const CornerLeanPhysicsInput(
          speedMs: 22.0,
          cornerRadiusMeters: 50.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 0.0,
          descendingSkill: 98.0,
          bikeHandlingSkill: 98.0,
        ),
      );

      expect(
        dryResult.maxSafeLeanAngleDeg,
        lessThanOrEqualTo(
          RiderCenterOfMassAndCornerLeanAngle.maxDryAsphaltLeanAngleDeg,
        ),
      );
      expect(dryResult.maxSafeLeanAngleDeg, greaterThanOrEqualTo(39.0));

      final CornerLeanPhysicsResult wetResult =
          RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(
        const CornerLeanPhysicsInput(
          speedMs: 22.0,
          cornerRadiusMeters: 50.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          surfaceWetness: 0.9,
        ),
      );

      expect(wetResult.maxSafeLeanAngleDeg, lessThan(dryResult.maxSafeLeanAngleDeg));
    });

    test('pro knee-out balance reduces bike lean angle and boosts cornering speed', () {
      const CornerLeanPhysicsInput baseInput = CornerLeanPhysicsInput(
        speedMs: 20.5,
        cornerRadiusMeters: 42.0,
        bodyBalanceStyle: CornerBodyBalanceStyle.uprightNeutral,
        kneeOutExtensionFactor: 0.0,
      );

      final CornerLeanPhysicsResult neutral =
          RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(baseInput);
      final CornerLeanPhysicsResult kneeOut =
          RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(
        baseInput.copyWith(
          bodyBalanceStyle: CornerBodyBalanceStyle.proDescenderKneeOut,
          kneeOutExtensionFactor: 1.0,
        ),
      );

      expect(kneeOut.insideKneeOutAngleDeg, greaterThan(25.0));
      expect(kneeOut.comLateralShiftMeters, greaterThan(0.10));
      expect(kneeOut.bikeLeanReliefDeg, greaterThan(2.0));
      expect(kneeOut.bikeFrameLeanAngleDeg, lessThan(neutral.bikeFrameLeanAngleDeg));
      expect(kneeOut.maxSafeCornerSpeedMs, greaterThan(neutral.maxSafeCornerSpeedMs));
      expect(kneeOut.stabilityIndex, greaterThan(neutral.stabilityIndex));
    });

    test('detects pedal strike risk when pedaling at deep lean angles', () {
      final CornerLeanPhysicsResult pedaling =
          RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(
        const CornerLeanPhysicsInput(
          speedMs: 22.5,
          cornerRadiusMeters: 62.0,
          isPedalingThroughCorner: true,
          bodyBalanceStyle: CornerBodyBalanceStyle.uprightNeutral,
        ),
      );

      final CornerLeanPhysicsResult coasting =
          RiderCenterOfMassAndCornerLeanAngle.evaluateCornerLean(
        const CornerLeanPhysicsInput(
          speedMs: 22.5,
          cornerRadiusMeters: 62.0,
          isPedalingThroughCorner: false,
          bodyBalanceStyle: CornerBodyBalanceStyle.uprightNeutral,
        ),
      );

      expect(pedaling.pedalStrikeRisk, greaterThan(0.3));
      expect(coasting.pedalStrikeRisk, equals(0.0));
      expect(coasting.outsidePedalWeightRatio, greaterThan(0.75));
    });

    test('simulates alpine cornering sequence and saves time with knee-out', () {
      final CornerSequenceSimulationSummary summary =
          RiderCenterOfMassAndCornerLeanAngle.simulateCorneringSequence(
        segments:
            RiderCenterOfMassAndCornerLeanAngle.defaultAlpineDescentSequence(),
        baseRiderConfig: const CornerLeanPhysicsInput(
          speedMs: 18.0,
          cornerRadiusMeters: 30.0,
          bodyBalanceStyle: CornerBodyBalanceStyle.proDescenderKneeOut,
          kneeOutExtensionFactor: 1.0,
        ),
      );

      expect(summary.steps.length, equals(4));
      expect(summary.totalTimeSeconds, greaterThan(0.0));
      expect(summary.totalTimeSavedVsNeutralSeconds, greaterThan(0.0));
      expect(summary.peakLeanAngleDeg, greaterThan(20.0));
      expect(summary.peakLateralGForce, greaterThan(0.5));
    });
  });

  group('RiderCenterOfMassAndCornerLeanAnglePanel', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly without overflow at ${viewport.width}x${viewport.height}',
          (WidgetTester tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              backgroundColor: Color(0xFF0F1115),
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: RiderCenterOfMassAndCornerLeanAnglePanel(),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('FIZYKA PRZECHYŁU I ŚRODKA CIĘŻKOŚCI'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
