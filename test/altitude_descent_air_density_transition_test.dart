import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/altitude_descent_air_density_transition.dart';

void main() {
  group('AltitudeDescentAirDensityTransition', () {
    test('oblicza standardową gęstość powietrza na poziomie morza przy 15°C', () {
      final double rhoDry = AltitudeDescentAirDensityTransition.calculateAirDensity(
        altitudeMeters: 0.0,
        temperatureCelsius: 15.0,
        seaLevelPressureHpa: 1013.25,
        includeHumidityCorrection: false,
      );
      expect(rhoDry, closeTo(1.225, 0.002));

      final double rhoHumid = AltitudeDescentAirDensityTransition.calculateAirDensity(
        altitudeMeters: 0.0,
        temperatureCelsius: 15.0,
        relativeHumidity: 0.80,
        seaLevelPressureHpa: 1013.25,
        includeHumidityCorrection: true,
      );
      expect(rhoHumid, lessThan(rhoDry));
      expect(rhoHumid, closeTo(1.219, 0.004));
    });

    test('zapewnia ciągłą interpolację C1 podczas zjazdu z Col du Galibier', () {
      final AirDensityTransitionConfig config = AirDensityTransitionConfig.fromPreset(
        AlpineDescentAtmospherePreset.galibier,
      );

      final DescentDensityProfileSummary summary =
          AltitudeDescentAirDensityTransition.generateDescentProfile(
        config: config,
        sampleCount: 60,
      );

      expect(summary.isSmoothContinuous, isTrue);
      expect(summary.summitSample.altitudeMeters, closeTo(2642.0, 0.01));
      expect(summary.valleySample.altitudeMeters, closeTo(720.0, 0.01));
      expect(summary.valleySample.airDensityKgM3, greaterThan(summary.summitSample.airDensityKgM3));
      expect(summary.densityIncreasePercent, greaterThan(10.0));
      expect(summary.terminalSpeedDropKmh, greaterThan(2.0));

      for (int i = 1; i < summary.samples.length; i++) {
        expect(
          summary.samples[i].airDensityKgM3,
          greaterThan(summary.samples[i - 1].airDensityKgM3),
        );
      }
    });

    test('obsługuje punkty pośrednie (inwersja w dolinie) oraz ekstrapolację', () {
      const AirDensityTransitionConfig config = AirDensityTransitionConfig(
        waypoints: [
          AtmosphereWaypoint(altitudeMeters: 500.0, temperatureCelsius: 6.0, relativeHumidity: 0.85),
          AtmosphereWaypoint(altitudeMeters: 1400.0, temperatureCelsius: 14.0, relativeHumidity: 0.45),
          AtmosphereWaypoint(altitudeMeters: 2500.0, temperatureCelsius: 3.0, relativeHumidity: 0.35),
        ],
      );

      final AirDensitySample mid = AltitudeDescentAirDensityTransition.evaluateAtAltitude(
        altitudeMeters: 1400.0,
        config: config,
      );
      expect(mid.temperatureCelsius, closeTo(14.0, 0.01));

      final AirDensitySample above = AltitudeDescentAirDensityTransition.evaluateAtAltitude(
        altitudeMeters: 2800.0,
        config: config,
      );
      expect(above.temperatureCelsius, lessThan(3.0));
      expect(above.airDensityKgM3, lessThan(mid.airDensityKgM3));
    });
  });

  group('AltitudeDescentAirDensityPanel', () {
    for (final Size size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje się bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
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
                  child: AltitudeDescentAirDensityPanel(),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('INTERPOLACJA GĘSTOŚCI POWIETRZA ρ(h, T)'), findsOneWidget);
        expect(find.text('STELVIO'), findsOneWidget);

        await tester.tap(find.text('STELVIO'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Passo dello Stelvio → Bormio'), findsOneWidget);
      });
    }
  });
}
