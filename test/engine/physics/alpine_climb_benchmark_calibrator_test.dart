import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/alpine_climb_benchmark_calibrator.dart';

void main() {
  group('AlpineClimbBenchmarkCalibrator', () {
    test(
      '60 kg rider at 6.4 W/kg on Alpe d\'Huez (13.8 km, 8.1%) finishes in 38:30-39:45 with VAM ~1750 m/h',
      () {
        final result = AlpineClimbBenchmarkCalibrator.simulateClimb(
          profile: AlpineClimbBenchmarkCalibrator.alpeDHuez,
          riderWeightKg: 60.0,
          wattsPerKg: 6.4,
        );

        expect(result.inputWatts, closeTo(384.0, 0.01));
        expect(
          result.elapsedTimeSeconds,
          inInclusiveRange(2310.0, 2385.0),
          reason:
              'Expected 38:30-39:45 (2310-2385s), got ${result.formattedTime} (${result.elapsedTimeSeconds.toStringAsFixed(1)}s)',
        );
        expect(
          result.vamMetersPerHour,
          closeTo(1750.0, 40.0),
          reason:
              'Expected VAM ~1750 m/h, got ${result.vamMetersPerHour.toStringAsFixed(1)} m/h',
        );
        expect(result.isWithinTimeWindow, isTrue);
        expect(result.isWithinVamTolerance, isTrue);
        expect(result.isCalibratedPass, isTrue);
      },
    );

    test('full alpine benchmark suite passes with calibrated parameters', () {
      final report = AlpineClimbBenchmarkCalibrator.runFullBenchmarkSuite();

      expect(report.results.length, 5);
      expect(report.alpeDHuezResult, isNotNull);
      expect(report.alpeDHuezResult!.isCalibratedPass, isTrue);

      for (final r in report.results) {
        expect(
          r.isWithinTimeWindow,
          isTrue,
          reason:
              '${r.profile.name} time ${r.formattedTime} (${r.elapsedTimeSeconds.toStringAsFixed(1)}s) outside [${r.profile.expectedMinTimeSeconds}, ${r.profile.expectedMaxTimeSeconds}]',
        );
        expect(
          r.isWithinVamTolerance,
          isTrue,
          reason:
              '${r.profile.name} VAM ${r.vamMetersPerHour.toStringAsFixed(1)} outside ${r.profile.expectedVamMetersPerHour} +/- ${r.profile.vamToleranceMetersPerHour}',
        );
      }
      expect(report.allPassed, isTrue);
    });

    test('bisection calibrator converges to target midpoint time', () {
      final calibrated = AlpineClimbBenchmarkCalibrator.calibrateParameters(
        primaryTarget: AlpineClimbBenchmarkCalibrator.alpeDHuez,
        targetTimeSeconds: 2325.0, // 38:45
      );

      final verified = AlpineClimbBenchmarkCalibrator.simulateClimb(
        profile: AlpineClimbBenchmarkCalibrator.alpeDHuez,
        parameters: calibrated.parameters,
      );

      expect(verified.elapsedTimeSeconds, closeTo(2325.0, 2.0));
      expect(calibrated.iterations, greaterThan(0));
    });

    test('VAM and time formatting utilities handle edge cases', () {
      expect(
        AlpineClimbBenchmarkCalibrator.calculateVamMetersPerHour(
          elevationGainMeters: 1117.8,
          elapsedTimeSeconds: 2310.0,
        ),
        closeTo(1742.02, 0.5),
      );
      expect(
        AlpineClimbBenchmarkCalibrator.calculateVamMetersPerHour(
          elevationGainMeters: 1000.0,
          elapsedTimeSeconds: 0.0,
        ),
        0.0,
      );
      expect(AlpineClimbBenchmarkCalibrator.formatClimbTime(2310.0), '38:30');
      expect(AlpineClimbBenchmarkCalibrator.formatClimbTime(2385.0), '39:45');
    });
  });
}
