import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/standing_bike_rocking_physics_3d.dart';

void main() {
  group('StandingBikeRockingPhysics3d', () {
    test('stays seated on <= 9% gradient without attack', () {
      final physics = StandingBikeRockingPhysics3d();

      final state = physics.evaluateFrame(
        const StandingRockingFrameInput(
          crankAngleRadians: math.pi / 2,
          gradientPercent: 9.0,
          isAttacking: false,
          cadenceRpm: 80.0,
          powerWatts: 380.0,
        ),
      );

      expect(state.mode, StandingRockingMode.seated);
      expect(state.isStandingActive, isFalse);
      expect(state.bikeRollAngleDegrees, 0.0);
      expect(state.torsoCounterRollDegrees, 0.0);
      expect(state.torsoComLateralOffsetMeters, 0.0);
    });

    test('engages en danseuse when gradient > 9% and follows phi_max * sin(theta)', () {
      final physics = StandingBikeRockingPhysics3d();

      final rightPeak = physics.evaluateFrame(
        const StandingRockingFrameInput(
          crankAngleRadians: math.pi / 2,
          gradientPercent: 14.0,
          isAttacking: false,
          cadenceRpm: 72.0,
          powerWatts: 460.0,
        ),
      );

      expect(rightPeak.mode, StandingRockingMode.steepClimbEnDanseuse);
      expect(rightPeak.isStandingActive, isTrue);
      expect(rightPeak.bikeRollAngleDegrees, closeTo(7.0, 0.001));

      final leftPeak = physics.evaluateFrame(
        const StandingRockingFrameInput(
          crankAngleRadians: 3 * math.pi / 2,
          gradientPercent: 14.0,
          isAttacking: false,
          cadenceRpm: 72.0,
          powerWatts: 460.0,
        ),
      );

      expect(leftPeak.bikeRollAngleDegrees, closeTo(-7.0, 0.001));
    });

    test('reaches exact +-7 degrees during attack and keeps torso/arms in counter-phase', () {
      final physics = StandingBikeRockingPhysics3d();

      final atQuarterTurn = physics.evaluateFrame(
        const StandingRockingFrameInput(
          crankAngleRadians: math.pi / 2,
          gradientPercent: 2.0,
          isAttacking: true,
          cadenceRpm: 95.0,
          powerWatts: 750.0,
        ),
      );

      expect(atQuarterTurn.mode, StandingRockingMode.attackEnDanseuse);
      expect(atQuarterTurn.bikeRollAngleDegrees, closeTo(7.0, 0.001));
      expect(atQuarterTurn.torsoCounterRollDegrees, lessThan(0.0));
      expect(atQuarterTurn.shoulderCounterRollDegrees, lessThan(0.0));
      expect(atQuarterTurn.torsoComLateralOffsetMeters, lessThan(0.0));
      expect(atQuarterTurn.rightArmPullNormalized, closeTo(-1.0, 0.001));
      expect(atQuarterTurn.leftArmPullNormalized, closeTo(1.0, 0.001));

      final atZero = physics.evaluateFrame(
        const StandingRockingFrameInput(
          crankAngleRadians: 0.0,
          gradientPercent: 2.0,
          isAttacking: true,
          cadenceRpm: 95.0,
          powerWatts: 750.0,
        ),
      );

      expect(atZero.bikeRollAngleDegrees, closeTo(0.0, 0.0001));
      expect(atZero.torsoCounterRollDegrees, closeTo(0.0, 0.0001));
      expect(atZero.torsoComLateralOffsetMeters, closeTo(0.0, 0.0001));
    });

    test('combines attackOnSteepClimb and steps smoothly over time', () {
      final physics = StandingBikeRockingPhysics3d();

      StandingBikeRockingState? last;
      for (int i = 0; i < 60; i++) {
        last = physics.step(
          dtSeconds: 1.0 / 60.0,
          gradientPercent: 11.0,
          isAttacking: true,
          cadenceRpm: 80.0,
          powerWatts: 620.0,
        );
      }

      expect(last, isNotNull);
      expect(last!.mode, StandingRockingMode.attackOnSteepClimb);
      expect(last.standingBlend, greaterThan(0.95));
      expect(last.bikeRollAngleDegrees.abs(), lessThanOrEqualTo(7.001));

      physics.reset();
      expect(physics.currentStandingBlend, 0.0);
      expect(physics.currentCrankAngleRadians, 0.0);
    });
  });

  group('StandingBikeRockingControlPanel responsive layout', () {
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
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SafeArea(
                  child: StandingBikeRockingControlPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Biomechanika En Danseuse 3D'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
