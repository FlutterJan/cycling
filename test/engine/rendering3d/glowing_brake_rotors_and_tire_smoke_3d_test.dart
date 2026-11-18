import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/glowing_brake_rotors_and_tire_smoke_3d.dart';

void main() {
  group('GlowingBrakeRotorsAndTireSmokeEngine', () {
    test('nagrzewa tarcze i generuje subtelną czerwoną poświatę przed nawrotem 180°', () {
      final GlowingBrakeRotorsAndTireSmokeEngine engine =
          GlowingBrakeRotorsAndTireSmokeEngine();

      late BrakeRotorAndTireSmokeFrameState frame;
      const BrakingScenarioPreset preset =
          BrakingScenarioPreset.hairpin180Approach;

      for (int i = 0; i < 260; i++) {
        frame = engine.step(
          BrakeAndTireTelemetryInput(
            speedKmh: preset.speedKmh,
            brakePressureRatio: preset.brakePressureRatio,
            roadGradientPercent: preset.roadGradientPercent,
            cornerCurvature180Ratio: preset.cornerCurvature180Ratio,
            asphaltWetness: preset.asphaltWetness,
            dtSeconds: 1.0 / 60.0,
          ),
        );
      }

      expect(
        frame.rotorState.frontTempCelsius,
        greaterThan(engine.config.glowStartTempCelsius),
      );
      expect(frame.rotorState.frontGlowIntensity, greaterThan(0.1));
      expect(frame.rotorState.frontGlowIntensity, lessThanOrEqualTo(1.0));
      expect(
        frame.rotorState.frontTempCelsius,
        greaterThan(frame.rotorState.rearTempCelsius),
      );
    });

    test('blokuje tylną oponę przy awaryjnym hamowaniu na zjeździe, emitując dym, ślad i pisk', () {
      final GlowingBrakeRotorsAndTireSmokeEngine engine =
          GlowingBrakeRotorsAndTireSmokeEngine();

      late BrakeRotorAndTireSmokeFrameState frame;
      const BrakingScenarioPreset preset =
          BrakingScenarioPreset.emergencyDescentLockup;

      for (int i = 0; i < 30; i++) {
        frame = engine.step(
          BrakeAndTireTelemetryInput(
            speedKmh: preset.speedKmh,
            brakePressureRatio: preset.brakePressureRatio,
            roadGradientPercent: preset.roadGradientPercent,
            cornerCurvature180Ratio: preset.cornerCurvature180Ratio,
            asphaltWetness: preset.asphaltWetness,
            riderWorldZ: i * 0.35,
            dtSeconds: 1.0 / 60.0,
          ),
        );
      }

      expect(frame.rearTireLocked, isTrue);
      expect(
        frame.rearSlipRatio,
        greaterThanOrEqualTo(engine.config.rearLockupSlipThreshold),
      );
      expect(frame.smokeParticles, isNotEmpty);
      expect(frame.skidMarks, isNotEmpty);
      expect(frame.screechCue.isTriggered, isTrue);
      expect(frame.screechCue.frequencyHz, inInclusiveRange(1400.0, 2750.0));
      expect(frame.screechCue.volume, greaterThan(0.1));
    });

    test('spokojne hamowanie w peletonie nie wywołuje poświaty ani dymu i reset chłodzi tarcze', () {
      final GlowingBrakeRotorsAndTireSmokeEngine engine =
          GlowingBrakeRotorsAndTireSmokeEngine();

      for (int i = 0; i < 40; i++) {
        engine.step(
          const BrakeAndTireTelemetryInput(
            speedKmh: 82.0,
            brakePressureRatio: 0.95,
            roadGradientPercent: -12.0,
            riderWorldZ: 1.0,
            dtSeconds: 1.0 / 60.0,
          ),
        );
      }

      engine.reset();
      final BrakeRotorAndTireSmokeFrameState afterReset = engine.step(
        BrakeAndTireTelemetryInput(
          speedKmh: BrakingScenarioPreset.pelotonCoastControl.speedKmh,
          brakePressureRatio:
              BrakingScenarioPreset.pelotonCoastControl.brakePressureRatio,
          roadGradientPercent:
              BrakingScenarioPreset.pelotonCoastControl.roadGradientPercent,
          dtSeconds: 1.0 / 60.0,
        ),
      );

      expect(afterReset.rotorState.frontGlowIntensity, equals(0.0));
      expect(afterReset.rearTireLocked, isFalse);
      expect(afterReset.smokeParticles, isEmpty);
      expect(afterReset.skidMarks, isEmpty);
      expect(afterReset.screechCue.isTriggered, isFalse);
    });
  });

  group('GlowingBrakeRotorsAndTireSmokePanel', () {
    for (final Size viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez przepełnień dla rozdzielczości ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(
                body: GlowingBrakeRotorsAndTireSmokePanel(),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.text('Tarcze Hamulcowe & Dym Opony 3D'), findsOneWidget);

          await tester.tap(find.text('Awaryjne na zjeździe'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
