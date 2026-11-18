import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/rendering3d/sunrise_sunset_dynamic_sky_dome_3d.dart';

void main() {
  const SunriseSunsetSkyDomeEngine engine = SunriseSunsetSkyDomeEngine();

  group('SunriseSunsetSkyDomeEngine — Fizyka Słońca i Paleta Nieba', () {
    test('Słońce wędruje od wschodu rano do zachodu w Golden Hour na mecie', () {
      final SolarEphemerisVector morning = engine.computeSolarEphemeris(
        decimalHours: 8.5,
        latitudeDeg: 45.2,
        dayOfYear: 195,
      );
      final SolarEphemerisVector noon = engine.computeSolarEphemeris(
        decimalHours: 12.5,
        latitudeDeg: 45.2,
        dayOfYear: 195,
      );
      final SolarEphemerisVector golden = engine.computeSolarEphemeris(
        decimalHours: 18.75,
        latitudeDeg: 45.2,
        dayOfYear: 195,
      );

      expect(morning.azimuthDeg, lessThan(130.0));
      expect(noon.elevationDeg, greaterThan(morning.elevationDeg));
      expect(noon.elevationDeg, greaterThan(golden.elevationDeg));
      expect(golden.azimuthDeg, greaterThan(250.0));
      expect(golden.isGoldenHourBand, isTrue);
      expect(golden.colorTemperatureKelvin, lessThan(noon.colorTemperatureKelvin));
      expect(golden.shadowLengthFactor, greaterThan(noon.shadowLengthFactor));
      expect(morning.direction3D.length, closeTo(1.0, 1e-5));
      expect(noon.direction3D.length, closeTo(1.0, 1e-5));
      expect(golden.direction3D.length, closeTo(1.0, 1e-5));
    });

    test('evaluateAtStageProgress przechodzi od poranka do złotej godziny na mecie', () {
      final SkyDomeAtmosphereSnapshot startSnap = engine.evaluateAtStageProgress(
        preset: SkyCycleStagePreset.summitGoldenFinale,
        stageProgress: 0.0,
      );
      final SkyDomeAtmosphereSnapshot finishSnap = engine.evaluateAtStageProgress(
        preset: SkyCycleStagePreset.summitGoldenFinale,
        stageProgress: 1.0,
      );

      expect(startSnap.formattedTime, equals('12:00'));
      expect(finishSnap.formattedTime, equals('19:09'));
      expect(finishSnap.phase, equals(SkyDomeAtmosphericPhase.goldenHourFinish));
      expect(finishSnap.goldenHourFactor, greaterThan(0.5));
      expect(finishSnap.cloudScatterWarmth, greaterThan(startSnap.cloudScatterWarmth));
    });

    test('generateTimelineSamples zwraca monotoniczną listę próbek', () {
      final List<SkyDomeAtmosphereSnapshot> samples =
          engine.generateTimelineSamples(
        preset: SkyCycleStagePreset.grandDepartMorning,
        sampleCount: 8,
      );

      expect(samples.length, equals(8));
      expect(samples.first.stageProgress, equals(0.0));
      expect(samples.last.stageProgress, equals(1.0));
      for (int i = 1; i < samples.length; i++) {
        expect(
          samples[i].decimalHours,
          greaterThan(samples[i - 1].decimalHours),
        );
      }
    });

    test('SkyDomeRenderConfig.copyWith zachowuje niezmienność i klampuje wartości', () {
      const SkyDomeRenderConfig base = SkyDomeRenderConfig();
      final SkyDomeRenderConfig updated = base.copyWith(
        cloudCoverage: 1.8,
        windDriftSpeed: -0.5,
        cameraPitchDeg: 90.0,
        enableCrepuscularRays: false,
      );

      expect(updated.cloudCoverage, equals(1.0));
      expect(updated.windDriftSpeed, equals(0.0));
      expect(updated.cameraPitchDeg, equals(45.0));
      expect(updated.enableCrepuscularRays, isFalse);
      expect(updated, isNot(equals(base)));
    });
  });

  group('SunriseSunsetDynamicSkyDome3dPanel — Responsywność i Interakcja UI', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      bool isEnabled = true,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SunriseSunsetDynamicSkyDome3dPanel(
                isEnabled: isEnabled,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Renderuje się poprawnie bez przepełnień na 390x844 (Mobile)',
        (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(find.text('Kopuła Nieba 3D • Cykl Dnia Etapu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderuje się poprawnie bez przepełnień na 1024x768 (Tablet)',
        (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Kopuła Nieba 3D • Cykl Dnia Etapu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderuje się poprawnie bez przepełnień na 1600x900 (Desktop)',
        (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));
      expect(find.text('Kopuła Nieba 3D • Cykl Dnia Etapu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Przyciski faz, presety i odtwarzanie działają poprawnie',
        (WidgetTester tester) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Golden Hour Meta'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('POSTĘP '), findsOneWidget);

      await tester.tap(find.text('Symuluj Cykl'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pauza'), findsOneWidget);

      await tester.tap(find.text('Pauza'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Symuluj Cykl'), findsOneWidget);
    });

    testWidgets('Tryb disabled blokuje interakcję przycisków',
        (WidgetTester tester) async {
      await pumpPanelAtSize(
        tester,
        const Size(1024, 768),
        isEnabled: false,
      );

      await tester.tap(find.text('Symuluj Cykl'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Symuluj Cykl'), findsOneWidget);
      expect(find.text('Pauza'), findsNothing);
    });
  });
}
