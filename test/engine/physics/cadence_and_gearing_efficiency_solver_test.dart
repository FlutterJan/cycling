import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/cadence_and_gearing_efficiency_solver.dart';
import 'package:pro_peloton_manager/models/equipment/drivetrain_gearing_configuration.dart';

void main() {
  group('CadenceAndGearingEfficiencySolver', () {
    const solver = CadenceAndGearingEfficiencySolver();

    test('calculates exact gear ratio i = Z_front / Z_rear', () {
      expect(
        CadenceAndGearingEfficiencySolver.calculateGearRatio(
          frontTeeth: 54,
          rearTeeth: 11,
        ),
        closeTo(54 / 11, 1e-9),
      );
      expect(
        CadenceAndGearingEfficiencySolver.calculateGearRatio(
          frontTeeth: 36,
          rearTeeth: 28,
        ),
        closeTo(36 / 28, 1e-9),
      );
      expect(
        CadenceAndGearingEfficiencySolver.calculateGearRatio(
          frontTeeth: 34,
          rearTeeth: 34,
        ),
        closeTo(1.0, 1e-9),
      );
      expect(
        () => CadenceAndGearingEfficiencySolver.calculateGearRatio(
          frontTeeth: 0,
          rearTeeth: 28,
        ),
        throwsArgumentError,
      );
    });

    test('calculates exact cadence RPM = (v * 60) / (C_wheel * i)', () {
      const wheelCircumferenceM = 2.136; // 700x28c
      final ratio = CadenceAndGearingEfficiencySolver.calculateGearRatio(
        frontTeeth: 36,
        rearTeeth: 28,
      );
      const speedMs = 2.40; // ~8.64 km/h na ściance

      final expectedRpm = (speedMs * 60.0) / (wheelCircumferenceM * ratio);
      final computedRpm = CadenceAndGearingEfficiencySolver.calculateCadenceRpm(
        speedMs: speedMs,
        wheelCircumferenceMeters: wheelCircumferenceM,
        gearRatio: ratio,
      );

      expect(computedRpm, closeTo(expectedRpm, 1e-9));
      expect(computedRpm, lessThan(60.0));

      final reconstructedSpeedMs =
          CadenceAndGearingEfficiencySolver.calculateSpeedMs(
        cadenceRpm: computedRpm,
        wheelCircumferenceMeters: wheelCircumferenceM,
        gearRatio: ratio,
      );
      expect(reconstructedSpeedMs, closeTo(speedMs, 1e-9));
    });

    test(
      'triggers +18% glycogen cost and fast-twitch fatigue on 18% wall with 11-28T cassette (< 60 RPM)',
      () {
        const drivetrain11_28 = DrivetrainGearingConfiguration(
          chainring: CranksetChainringOption.semiCompact52_36,
          cassette: Cassette12SpeedOption.sprint11_28,
        );

        // 8.5 km/h (~2.361 m/s) na ściance 18% przy 36x28 daje ~51.5 RPM (< 60 RPM).
        final result = solver.solve(
          const CadenceAndGearingInput(
            drivetrain: drivetrain11_28,
            speedMs: 8.5 / 3.6,
            powerWatts: 380.0,
            gradePercent: 18.0,
            deltaTimeSeconds: 10.0,
          ),
        );

        expect(result.frontTeeth, 36);
        expect(result.rearTeeth, 28);
        expect(result.gearRatio, closeTo(36 / 28, 1e-9));
        expect(result.cadenceRpm, lessThan(60.0));
        expect(result.isGrinding, isTrue);
        expect(result.zone, CadenceEfficiencyZone.grinding);
        expect(result.glycogenCostMultiplier, closeTo(1.18, 1e-9));
        expect(result.glycogenPenaltyPercent, closeTo(18.0, 1e-6));
        expect(result.fastTwitchFatigueMultiplier, greaterThan(1.6));
        expect(result.fastTwitchFatigueDelta, greaterThan(0.5));
        expect(result.crankTorqueNm, greaterThan(65.0));
      },
    );

    test(
      'climbing cassette 11-34T with 50/34T prevents grinding on steep climb at same speed',
      () {
        const climbingSetup = DrivetrainGearingConfiguration(
          chainring: CranksetChainringOption.compact50_34,
          cassette: Cassette12SpeedOption.climbing11_34,
        );

        // 8.5 km/h na 34x34 (i = 1.0) daje ~66.3 RPM (>= 60 RPM).
        final result = solver.solve(
          const CadenceAndGearingInput(
            drivetrain: climbingSetup,
            speedMs: 8.5 / 3.6,
            powerWatts: 380.0,
            gradePercent: 18.0,
            deltaTimeSeconds: 10.0,
          ),
        );

        expect(result.frontTeeth, 34);
        expect(result.rearTeeth, 34);
        expect(result.cadenceRpm, greaterThan(60.0));
        expect(result.isGrinding, isFalse);
        expect(result.glycogenCostMultiplier, lessThan(1.18));
        expect(result.fastTwitchFatigueMultiplier, lessThan(1.25));
      },
    );

    test('optimal cadence zone has zero glycogen and fast-twitch penalty', () {
      final flatSetup = DrivetrainGearingConfiguration.proPelotonStandard();

      // 45 km/h = 12.5 m/s przy docelowej kadencji 90 RPM
      final result = solver.solve(
        CadenceAndGearingInput(
          drivetrain: flatSetup,
          speedMs: 12.5,
          powerWatts: 320.0,
          gradePercent: 0.0,
          preferredCadenceRpm: 90.0,
          deltaTimeSeconds: 1.0,
        ),
      );

      expect(result.zone, CadenceEfficiencyZone.optimal);
      expect(result.isGrinding, isFalse);
      expect(result.isSpinningOut, isFalse);
      expect(result.glycogenCostMultiplier, closeTo(1.0, 1e-9));
      expect(result.fastTwitchFatigueMultiplier, closeTo(1.0, 1e-9));
      expect(result.fastTwitchFatigueDelta, closeTo(0.0, 1e-9));
      expect(result.biomechanicalPowerFactor, closeTo(1.0, 1e-9));
    });

    test('handles coasting and spinning out edge cases cleanly', () {
      final compact = DrivetrainGearingConfiguration.alpineClimber();

      final coasting = solver.solve(
        CadenceAndGearingInput(
          drivetrain: compact,
          speedMs: 18.0,
          powerWatts: 0.0,
          gradePercent: -8.0,
        ),
      );
      expect(coasting.zone, CadenceEfficiencyZone.coasting);
      expect(coasting.cadenceRpm, 0.0);
      expect(coasting.glycogenCostMultiplier, 1.0);

      // 50x11 przy 72 km/h (20 m/s) -> > 120 RPM (spinning out)
      final spinningOut = solver.solve(
        CadenceAndGearingInput(
          drivetrain: compact,
          speedMs: 20.0,
          powerWatts: 400.0,
          gradePercent: -3.0,
          forcedFrontTeeth: 50,
          forcedRearTeeth: 11,
        ),
      );
      expect(spinningOut.isSpinningOut, isTrue);
      expect(spinningOut.zone, CadenceEfficiencyZone.spinningOut);
      expect(spinningOut.biomechanicalPowerFactor, lessThan(1.0));
    });

    test('detects cross-chaining and reduces mechanical efficiency', () {
      final setup = DrivetrainGearingConfiguration.allRounder();

      final crossChained = solver.solve(
        CadenceAndGearingInput(
          drivetrain: setup,
          speedMs: 8.0,
          powerWatts: 250.0,
          forcedFrontTeeth: 52,
          forcedRearTeeth: 30,
        ),
      );

      final straightChain = solver.solve(
        CadenceAndGearingInput(
          drivetrain: setup,
          speedMs: 8.0,
          powerWatts: 250.0,
          forcedFrontTeeth: 36,
          forcedRearTeeth: 21,
        ),
      );

      expect(crossChained.isCrossChained, isTrue);
      expect(straightChain.isCrossChained, isFalse);
      expect(
        crossChained.mechanicalEfficiency,
        lessThan(straightChain.mechanicalEfficiency),
      );
    });
  });
}
