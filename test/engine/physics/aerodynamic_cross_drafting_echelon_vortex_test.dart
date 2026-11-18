import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/aerodynamic_cross_drafting_echelon_vortex.dart';

void main() {
  group('AerodynamicCrossDraftingEchelonVortex', () {
    test('35° echelon gives 38% drag reduction in shifted cone vs 12% directly behind wheel', () {
      final optimalInput = EchelonVortexInput.canonical35DegreeEchelon(
        riderSpeedMs: 12.5,
        longitudinalGapMeters: 0.55,
        windFromLeft: true,
      );
      final optimalResult =
          AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(optimalInput);

      expect(optimalResult.wakeShiftAngleDegrees, closeTo(35.0, 0.05));
      expect(optimalResult.effectiveDragReduction, closeTo(0.38, 0.005));
      expect(optimalResult.dragReductionPercent, closeTo(38.0, 0.5));
      expect(optimalResult.coneZone, EchelonConeZone.optimalVortexCone);
      expect(optimalResult.windSide, EchelonWindSide.fromLeft);
      expect(optimalResult.powerSavedWatts, greaterThan(100.0));

      final directBehindInput = EchelonVortexInput.canonical35DegreeEchelon(
        riderSpeedMs: 12.5,
        longitudinalGapMeters: 0.55,
        windFromLeft: true,
        alignDirectlyBehindWheel: true,
      );
      final directResult =
          AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
            directBehindInput,
          );

      expect(directResult.wakeShiftAngleDegrees, closeTo(35.0, 0.05));
      expect(directResult.effectiveDragReduction, closeTo(0.12, 0.005));
      expect(directResult.dragReductionPercent, closeTo(12.0, 0.5));
      expect(directResult.coneZone, EchelonConeZone.directWheelMisaligned);
      expect(directResult.lateralCorrectionNeededMeters, greaterThan(0.65));
    });

    test('asymmetric shift flips to -y when crosswind blows from right', () {
      final rightWindOptimal = EchelonVortexInput.canonical35DegreeEchelon(
        windFromLeft: false,
      );
      final result = AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
        rightWindOptimal,
      );

      expect(result.wakeShiftAngleDegrees, closeTo(-35.0, 0.05));
      expect(result.optimalLateralOffsetMeters, lessThan(-0.65));
      expect(result.effectiveDragReduction, closeTo(0.38, 0.005));
      expect(result.windSide, EchelonWindSide.fromRight);

      // Rider positioned on the windward side (+0.70 m when wind is from right) is exposed
      final windwardExposed = rightWindOptimal.copyWith(
        lateralOffsetMeters: 0.70,
      );
      final exposedResult =
          AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
            windwardExposed,
          );
      expect(exposedResult.effectiveDragReduction, lessThan(0.05));
      expect(exposedResult.coneZone, EchelonConeZone.windwardExposed);
    });

    test('evaluateEchelonFormation identifies misaligned rider in 5-rider echelon', () {
      const double stepX = 0.55;
      final double stepY =
          AerodynamicCrossDraftingEchelonVortex.computeOptimalLateralOffsetMeters(
            longitudinalGapMeters: stepX,
            wakeShiftAngleDegrees: 35.0,
          );

      final riders = [
        const EchelonFormationRiderInput(
          riderId: 'r1',
          riderName: 'Leader',
          longitudinalGapFromLeaderMeters: 0.0,
          lateralOffsetFromLeaderMeters: 0.0,
        ),
        EchelonFormationRiderInput(
          riderId: 'r2',
          riderName: 'Slot 2 (Optimal)',
          longitudinalGapFromLeaderMeters: stepX,
          lateralOffsetFromLeaderMeters: stepY,
        ),
        EchelonFormationRiderInput(
          riderId: 'r3',
          riderName: 'Slot 3 (Directly Behind)',
          longitudinalGapFromLeaderMeters: stepX * 2,
          // Misaligned: directly behind r2's rear wheel instead of shifted by stepY
          lateralOffsetFromLeaderMeters: stepY,
        ),
      ];

      final summary =
          AerodynamicCrossDraftingEchelonVortex.evaluateEchelonFormation(
            riders: riders,
            riderSpeedMs: 12.5,
            windSpeedMs: 8.75,
            windRelativeAngleDegrees: 90.0,
            overrideWakeShiftAngleDegrees: 35.0,
          );

      expect(summary.riders.length, 3);
      expect(summary.riders[0].vortexResult.effectiveDragReduction, 0.0);
      expect(
        summary.riders[1].vortexResult.effectiveDragReduction,
        closeTo(0.38, 0.01),
      );
      expect(
        summary.riders[2].vortexResult.effectiveDragReduction,
        closeTo(0.12, 0.01),
      );
      expect(summary.mostExposedFollower?.input.riderId, 'r3');
      expect(summary.totalPowerSavedWatts, greaterThan(150.0));
    });
  });

  group('AerodynamicCrossDraftingEchelonVortexPanel UI', () {
    for (final Size viewport in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: AerodynamicCrossDraftingEchelonVortexPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('ECHELON VORTEX AERO CONE'), findsOneWidget);
          expect(find.text('38.0%'), findsOneWidget);

          // Switch to "Za kołem (12%)" preset
          await tester.tap(find.text('Za kołem (12%)'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('12.0%'), findsOneWidget);
        },
      );
    }
  });
}
