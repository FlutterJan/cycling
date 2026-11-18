import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/sprinter_elbow_rubbing_and_wheel_fighting.dart';

void main() {
  group('SprinterElbowRubbingAndWheelFighting', () {
    const eliteSprinter = WheelFightRiderProfile(
      riderId: 'elite_def',
      riderName: 'K. De Bruyn',
      teamName: 'Alpecin Apex',
      weightKg: 79.0,
      coreStrength: 92,
      sprint: 93,
      raceIq: 90,
      bikeHandling: 88,
      remainingWPrimePct: 90.0,
    );

    const lighterIntruder = WheelFightRiderProfile(
      riderId: 'light_chal',
      riderName: 'L. Rossi',
      teamName: 'Movi Aero',
      weightKg: 66.0,
      coreStrength: 74,
      sprint: 84,
      raceIq: 75,
      bikeHandling: 78,
      remainingWPrimePct: 82.0,
    );

    test('high raceIq, sprint, weight and core win shoulder-to-shoulder duel at 62 km/h', () {
      const input = WheelFightStepInput(
        defender: eliteSprinter,
        challenger: lighterIntruder,
        distanceToFinishKm: 1.8,
        pelotonSpeedKmh: 62.0,
        leadoutWheelGapMeters: 0.30,
        defenderAggression: WheelFightTacticAggression.balancedShoulderHold,
        challengerAggression: WheelFightTacticAggression.balancedShoulderHold,
        deltaSeconds: 1.0,
      );

      final result = SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
        input: input,
        previousRetentionPct: 82.0,
        previousUciRiskPct: 10.0,
      );

      expect(result.isInFinal3KmZone, isTrue);
      expect(result.defenderTotalForceNewtons, greaterThan(result.challengerIntrusionForceNewtons));
      expect(result.netLateralMarginNewtons, greaterThan(0.0));
      expect(result.defenderHoldProbability, greaterThan(0.75));
      expect(result.wheelPositionRetentionPct, greaterThan(82.0));
      expect(result.aeroDraftSavedWatts, greaterThan(180.0));
      expect(result.uciVerdict, UciElbowRuleVerdict.cleanContact);
    });

    test('outside final 3 km zone returns outsideFinal3Km phase with zero core cost', () {
      const input = WheelFightStepInput(
        defender: eliteSprinter,
        challenger: lighterIntruder,
        distanceToFinishKm: 6.5,
        pelotonSpeedKmh: 52.0,
      );

      final result = SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
        input: input,
      );

      expect(result.isInFinal3KmZone, isFalse);
      expect(result.phase, WheelFightPhase.outsideFinal3Km);
      expect(result.isometricCoreWPrimeCostJoules, 0.0);
    });

    test('reckless barge triggers UCI warning or relegation without exceeding bounds', () {
      const input = WheelFightStepInput(
        defender: WheelFightRiderProfile(
          riderId: 'hothead',
          riderName: 'R.猛',
          teamName: 'Sprint Squad',
          weightKg: 76.0,
          coreStrength: 85,
          sprint: 88,
          raceIq: 58,
          bikeHandling: 62,
        ),
        challenger: lighterIntruder,
        distanceToFinishKm: 0.9,
        pelotonSpeedKmh: 65.0,
        roadWidthMeters: 4.5,
        defenderAggression: WheelFightTacticAggression.recklessBarge,
        deltaSeconds: 2.0,
      );

      var risk = 45.0;
      var retention = 80.0;
      late WheelFightStepResult result;
      for (int i = 0; i < 3; i++) {
        result = SprinterElbowRubbingAndWheelFighting.evaluateWheelFightStep(
          input: input,
          previousRetentionPct: retention,
          previousUciRiskPct: risk,
        );
        risk = result.uciInfractionRiskPct;
        retention = result.wheelPositionRetentionPct;
      }

      expect(
        result.uciVerdict == UciElbowRuleVerdict.yellowCardWarning ||
            result.uciVerdict == UciElbowRuleVerdict.relegationAndFine,
        isTrue,
      );
      expect(result.uciInfractionRiskPct, inInclusiveRange(0.0, 100.0));
    });

    test('JSON round-trip preserves SprinterWheelFightState', () {
      final initial = SprinterWheelFightState.initial();
      final json = initial.toJson();
      final restored = SprinterWheelFightState.fromJson(json);

      expect(restored.currentInput.defender, initial.currentInput.defender);
      expect(restored.lastResult.phase, initial.lastResult.phase);
      expect(restored.history.length, initial.history.length);
    });
  });

  group('SprinterWheelFightNotifier & Responsive Panel', () {
    test('notifier updates aggression, speed, steps simulation and resets', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(sprinterWheelFightProvider.notifier);
      notifier.setDefenderAggression(WheelFightTacticAggression.cleanDefensive);
      expect(
        container.read(sprinterWheelFightProvider).currentInput.defenderAggression,
        WheelFightTacticAggression.cleanDefensive,
      );

      notifier.setPelotonSpeed(64.5);
      expect(
        container.read(sprinterWheelFightProvider).currentInput.pelotonSpeedKmh,
        64.5,
      );

      final initialDist =
          container.read(sprinterWheelFightProvider).currentInput.distanceToFinishKm;
      notifier.stepSimulation();
      final afterStep = container.read(sprinterWheelFightProvider);
      expect(afterStep.stepCount, 1);
      expect(afterStep.currentInput.distanceToFinishKm, lessThan(initialDist));
      expect(afterStep.history.length, 2);

      notifier.reset();
      expect(container.read(sprinterWheelFightProvider).stepCount, 0);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders SprinterElbowRubbingAndWheelFightingPanel cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: SprinterElbowRubbingAndWheelFightingPanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Walka o Koło w Pociągu Sprinterskim (Ostatnie 3 km)'),
            findsOneWidget,
          );
          expect(find.text('Symuluj Krok (1 s)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
