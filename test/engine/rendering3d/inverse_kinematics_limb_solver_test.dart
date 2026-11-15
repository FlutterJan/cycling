import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/inverse_kinematics_limb_solver.dart';

void main() {
  group('InverseKinematicsLimbSolver', () {
    const solver = InverseKinematicsLimbSolver();

    test('normalizes crank angle to [0, 2*pi) and handles non-finite values', () {
      expect(
        InverseKinematicsLimbSolver.normalizeAngleRadians(-math.pi / 2),
        closeTo(1.5 * math.pi, 1e-9),
      );
      expect(
        InverseKinematicsLimbSolver.normalizeAngleRadians(2.5 * math.pi),
        closeTo(0.5 * math.pi, 1e-9),
      );
      expect(
        InverseKinematicsLimbSolver.normalizeAngleRadians(double.nan),
        0.0,
      );
      expect(
        InverseKinematicsLimbSolver.normalizeAngleRadians(double.infinity),
        0.0,
      );
    });

    test('clamps crank length to [165, 175] mm and places pedals on crank circle', () {
      final shortCrank = solver.solveFrame(
        const LimbIkFrameInput(
          crankAngleRadians: math.pi / 2,
          crankLengthMm: 150.0,
        ),
      );
      expect(shortCrank.crankLengthMm, 165.0);
      expect(shortCrank.rightPedalPosition.z, closeTo(0.165, 1e-6));
      expect(shortCrank.rightPedalPosition.y, closeTo(0.0, 1e-6));

      final longCrank = solver.solveFrame(
        const LimbIkFrameInput(
          crankAngleRadians: 0.0,
          crankLengthMm: 190.0,
        ),
      );
      expect(longCrank.crankLengthMm, 175.0);
      expect(longCrank.rightPedalPosition.y, closeTo(0.175, 1e-6));
      expect(longCrank.leftPedalPosition.y, closeTo(-0.175, 1e-6));
    });

    test('preserves exact 2-bone leg lengths across full 360-degree stroke', () {
      const config = LimbIkGeometryConfig();

      for (int deg = 0; deg < 360; deg += 15) {
        final theta = deg * math.pi / 180.0;
        final result = solver.solveFrame(
          LimbIkFrameInput(
            crankAngleRadians: theta,
            crankLengthMm: 172.5,
            grip: IkGripType.hoods,
          ),
        );

        final rightThighLen =
            (result.rightKneePosition - result.rightHipPosition).length;
        final rightCalfLen =
            (result.rightAnklePosition - result.rightKneePosition).length;
        final leftThighLen =
            (result.leftKneePosition - result.leftHipPosition).length;
        final leftCalfLen =
            (result.leftAnklePosition - result.leftKneePosition).length;

        expect(rightThighLen, closeTo(config.thighLengthMeters, 1e-4));
        expect(rightCalfLen, closeTo(config.calfLengthMeters, 1e-4));
        expect(leftThighLen, closeTo(config.thighLengthMeters, 1e-4));
        expect(leftCalfLen, closeTo(config.calfLengthMeters, 1e-4));

        // Knee always bends forward (+Z) and ankle stays above & behind pedal
        expect(result.rightKneePosition.z, greaterThan(result.rightHipPosition.z));
        expect(result.rightAnklePosition.y, greaterThan(result.rightPedalPosition.y));
        expect(result.rightAnklePosition.z, lessThan(result.rightPedalPosition.z));
      }
    });

    test('solves elbow flexion and arm bone lengths for Tops, Hoods, Drops, AeroTuck', () {
      const config = LimbIkGeometryConfig();
      final flexions = <IkGripType, double>{};

      for (final grip in IkGripType.values) {
        final result = solver.solveFrame(
          LimbIkFrameInput(
            crankAngleRadians: math.pi / 3,
            grip: grip,
          ),
        );

        final rightUpperArm =
            (result.rightElbowPosition - result.rightShoulderPosition).length;
        final rightForearm =
            (result.rightHandPosition - result.rightElbowPosition).length;
        final leftUpperArm =
            (result.leftElbowPosition - result.leftShoulderPosition).length;
        final leftForearm =
            (result.leftHandPosition - result.leftElbowPosition).length;

        expect(rightUpperArm, closeTo(config.upperArmLengthMeters, 1e-4));
        expect(rightForearm, closeTo(config.forearmLengthMeters, 1e-4));
        expect(leftUpperArm, closeTo(config.upperArmLengthMeters, 1e-4));
        expect(leftForearm, closeTo(config.forearmLengthMeters, 1e-4));

        // Elbows sit below shoulder level
        expect(result.rightElbowPosition.y, lessThan(result.rightShoulderPosition.y));
        expect(result.leftElbowPosition.y, lessThan(result.leftShoulderPosition.y));

        flexions[grip] = result.rightElbowFlexionDegrees;
      }

      // AeroTuck has deeper elbow flexion than Tops
      expect(
        flexions[IkGripType.aeroTuck]!,
        greaterThan(flexions[IkGripType.tops]!),
      );
      expect(
        flexions[IkGripType.drops]!,
        greaterThan(flexions[IkGripType.tops]!),
      );
    });

    test('standing progress elevates and shifts pelvis forward', () {
      final seated = solver.solveFrame(
        const LimbIkFrameInput(
          crankAngleRadians: math.pi / 2,
          standingProgress: 0.0,
        ),
      );
      final standing = solver.solveFrame(
        const LimbIkFrameInput(
          crankAngleRadians: math.pi / 2,
          standingProgress: 1.0,
        ),
      );

      expect(
        standing.pelvisCenterPosition.y,
        greaterThan(seated.pelvisCenterPosition.y),
      );
      expect(
        standing.pelvisCenterPosition.z,
        greaterThan(seated.pelvisCenterPosition.z),
      );
    });
  });
}
