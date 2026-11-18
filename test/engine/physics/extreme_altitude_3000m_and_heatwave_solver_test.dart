import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/extreme_altitude_3000m_and_heatwave_solver.dart';

void main() {
  group('ExtremeAltitude3000mAndHeatwaveSolver', () {
    test('sea level baseline has no hypoxia or heatwave penalties', () {
      const input = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 50.0,
        ambientTempCelsius: 20.0,
        solarRadiationFactor: 0.5,
      );

      final result = ExtremeAltitude3000mAndHeatwaveSolver.solve(input);

      expect(result.altitudeZone, ExtremeAltitudeZone.seaLevelOrLow);
      expect(result.heatwaveZone, HeatwaveSeverityZone.temperate);
      expect(result.tauWPrimeMultiplier, closeTo(1.0, 0.001));
      expect(result.crrMultiplier, closeTo(1.0, 0.001));
      expect(result.hydrationMultiplier, closeTo(1.0, 0.001));
      expect(result.isExtremeHypoxiaWPrimeZone, isFalse);
      expect(result.requiresDoubleHydration, isFalse);
    });

    test('above 2800m PaO2 drops and tau_W\' increases by >= +45% (~2x recovery)', () {
      const input = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 3050.0,
        ambientTempCelsius: 14.0,
        solarRadiationFactor: 0.9,
        criticalPowerWatts: 380.0,
        recoveryPowerWatts: 220.0,
      );

      final result = ExtremeAltitude3000mAndHeatwaveSolver.solve(input);

      expect(
        result.altitudeZone,
        ExtremeAltitudeZone.extremeHypoxiaAbove2800m,
      );
      expect(result.isExtremeHypoxiaWPrimeZone, isTrue);
      expect(result.arterialPao2MmHg, lessThan(60.0));
      expect(result.tauWPrimeMultiplier, greaterThanOrEqualTo(1.45));
      expect(result.tauWPrimePenaltyPercent, greaterThanOrEqualTo(45.0));
      expect(result.attackRecoveryTimeRatio, greaterThanOrEqualTo(1.85));
      expect(result.recoveryCurve, isNotEmpty);
    });

    test('Australian heatwave >40C heats asphalt to ~58C, +8% Crr, 2x hydration', () {
      const input = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: 120.0,
        ambientTempCelsius: 42.0,
        solarRadiationFactor: 1.0,
        windSpeedMs: 2.0,
      );

      final result = ExtremeAltitude3000mAndHeatwaveSolver.solve(input);

      expect(result.heatwaveZone, HeatwaveSeverityZone.australianExtremeHeat);
      expect(result.asphaltSurfaceTempCelsius, greaterThanOrEqualTo(58.0));
      expect(result.crrMultiplier, greaterThanOrEqualTo(1.08));
      expect(result.crrIncreasePercent, greaterThanOrEqualTo(8.0));
      expect(result.hydrationMultiplier, greaterThanOrEqualTo(2.0));
      expect(result.requiresDoubleHydration, isTrue);
    });

    test('clamps extreme out-of-range inputs safely', () {
      const input = ExtremeAltitudeAndHeatwaveInput(
        altitudeMeters: -200.0,
        ambientTempCelsius: 80.0,
        baseCrr: 0.0,
        baseTauWPrimeSeconds: -10.0,
        baseHydrationLitersPerHour: 0.0,
      );

      final result = ExtremeAltitude3000mAndHeatwaveSolver.solve(input);

      expect(result.altitudeMeters, 0.0);
      expect(result.ambientTempCelsius, 52.0);
      expect(result.effectiveCrr, greaterThan(0.0));
      expect(result.effectiveTauWPrimeSeconds, greaterThanOrEqualTo(30.0));
      expect(result.requiredHydrationLitersPerHour, greaterThan(0.0));
    });
  });

  group('ExtremeAltitude3000mAndHeatwavePanel responsive layout', () {
    for (final Size size in const [
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
                body: ExtremeAltitude3000mAndHeatwavePanel(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(ExtremeAltitude3000mAndHeatwavePanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
