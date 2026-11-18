import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/retro_steel_frame_and_no_powermeter_solver.dart';
import 'package:pro_peloton_manager/models/retro/golden_era_retro_season_model.dart';

void main() {
  const solver = RetroSteelFrameAndNoPowermeterSolver();

  group('RetroSteelFrameAndNoPowermeterSolver - RPE Borg 6-20', () {
    test('hides live watts and heart rate when noPowerMeterRpeOnly is active', () {
      final result = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          requestedPowerWatts: 360.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(result.visiblePowerWatts, isNull);
      expect(result.visibleHeartRateBpm, isNull);
      expect(result.borgRpeScore, inInclusiveRange(6.0, 20.0));
      expect(result.borgRpeRounded, inInclusiveRange(13, 18));
      expect(result.actualPowerWatts, greaterThan(250.0));
    });

    test('shows live watts and heart rate in fullPowerAndLiveWatts mode', () {
      final result = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.fullPowerAndLiveWatts,
          riderFtpWatts: 400.0,
          requestedPowerWatts: 400.0,
          cumulativeFatigue: 0.0,
          wPrimeRemainingFraction: 1.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(result.visiblePowerWatts, isNotNull);
      expect(result.visiblePowerWatts, closeTo(400.0, 0.5));
      expect(result.visibleHeartRateBpm, isNotNull);
      expect(result.rpeEstimationErrorPercent, closeTo(0.0, 0.01));
    });

    test('fatigue and glycogen depletion increase perceived Borg RPE', () {
      final fresh = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 360.0,
          requestedPowerWatts: 300.0,
          cumulativeFatigue: 0.05,
          wPrimeRemainingFraction: 1.0,
          glycogenFraction: 0.95,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      final depleted = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 360.0,
          requestedPowerWatts: 300.0,
          cumulativeFatigue: 0.75,
          wPrimeRemainingFraction: 0.25,
          glycogenFraction: 0.15,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(depleted.borgRpeScore, greaterThan(fresh.borgRpeScore));
      expect(depleted.bonkRiskScore, greaterThan(fresh.bonkRiskScore));
    });

    test('targetBorgRpe paces rider by perceived effort', () {
      final easy = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          targetBorgRpe: 9.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      final hard = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
          riderFtpWatts: 380.0,
          targetBorgRpe: 17.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(hard.actualPowerWatts, greaterThan(easy.actualPowerWatts));
      expect(easy.borgZone, BorgRpeZone.veryLight);
      expect(hard.borgZone, BorgRpeZone.veryHard);
    });
  });

  group('RetroSteelFrameAndNoPowermeterSolver - Downtube Shifter & Steel Frame', () {
    test('downtube friction shift introduces hand-off-bar delay and completes over steps', () {
      final initialShift = DowntubeShiftState.initial(
        frontTeeth: 52,
        rearTeeth: 19,
      );

      final step1 = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          shifterType: RetroShifterType.downtubeFriction,
          requestedFrontTeeth: 52,
          requestedRearTeeth: 21,
          deltaTimeSeconds: 0.5,
          deterministicSeed: 7,
        ),
        shiftState: initialShift,
      );

      expect(step1.shiftState.isShifting, isTrue);
      expect(step1.shiftState.isHandOffBar, isTrue);
      expect(step1.cdaPenaltyM2, greaterThanOrEqualTo(0.025));
      expect(step1.shiftPowerTransferFactor, lessThan(0.90));
      expect(step1.shiftState.currentRearTeeth, 19);

      // Advance enough time to complete the downtube shift.
      var state = step1.shiftState;
      for (var i = 0; i < 10 && state.isShifting; i++) {
        final next = solver.stepSimulation(
          input: const RetroPhysicsAndRpeInput(
            shifterType: RetroShifterType.downtubeFriction,
            deltaTimeSeconds: 0.5,
          ),
          shiftState: state,
        );
        state = next.shiftState;
      }

      expect(state.isShifting, isFalse);
      expect(state.isHandOffBar, isFalse);
      expect(state.currentRearTeeth, 21);
      expect(state.totalShiftsCompleted, 1);
    });

    test('rain increases wet merino wool weight and CdA penalty', () {
      final dry = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          frameMaterial: RetroFrameMaterial.columbusSlSteel,
          jerseyMaterial: RetroJerseyMaterial.heavyMerinoWool,
          rainIntensity: 0.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      final heavyRain = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          frameMaterial: RetroFrameMaterial.columbusSlSteel,
          jerseyMaterial: RetroJerseyMaterial.heavyMerinoWool,
          rainIntensity: 1.0,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(
        heavyRain.effectiveBikeAndKitWeightKg,
        closeTo(dry.effectiveBikeAndKitWeightKg + 1.4, 0.05),
      );
      expect(heavyRain.cdaPenaltyM2, greaterThan(dry.cdaPenaltyM2));
    });

    test('steel frame flex absorbs power during out-of-saddle sprints', () {
      final seated = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          frameMaterial: RetroFrameMaterial.reynolds531Steel,
          riderFtpWatts: 360.0,
          requestedPowerWatts: 300.0,
          isOutOfSaddle: false,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      final sprint = solver.stepSimulation(
        input: const RetroPhysicsAndRpeInput(
          frameMaterial: RetroFrameMaterial.reynolds531Steel,
          riderFtpWatts: 360.0,
          requestedPowerWatts: 950.0,
          isOutOfSaddle: true,
        ),
        shiftState: DowntubeShiftState.initial(),
      );

      expect(seated.frameFlexPowerLossWatts, 0.0);
      expect(sprint.frameFlexPowerLossWatts, greaterThan(10.0));
    });
  });

  group('RetroSteelAndRpeHudPanel responsive layout', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final res = solver.stepSimulation(
          input: const RetroPhysicsAndRpeInput(
            telemetryMode: RetroTelemetryMode.noPowerMeterRpeOnly,
            requestedFrontTeeth: 52,
            requestedRearTeeth: 21,
            deltaTimeSeconds: 0.4,
          ),
          shiftState: DowntubeShiftState.initial(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RetroSteelAndRpeHudPanel(
                  result: res,
                  onTargetRpeChanged: (_) {},
                  onShiftEasier: () {},
                  onShiftHarder: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('TELEMETRIA RETRO'), findsOneWidget);
        expect(find.textContaining('Skala Borga (6–20)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
