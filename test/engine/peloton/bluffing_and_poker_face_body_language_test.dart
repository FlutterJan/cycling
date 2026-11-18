import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/bluffing_and_poker_face_body_language.dart';

void main() {
  group('BluffingAndPokerFaceEngine', () {
    test('pokerFaceHideCrisis hides true crisis and incurs metabolic cost', () {
      final initial = BluffingAndPokerFaceState.initial().copyWith(
        activeTactic: PokerFaceTacticMode.pokerFaceHideCrisis,
        mentalFocusRemaining: 90.0,
      );
      const hardClimbInput = BluffingStepInput(
        wPrimeRemainingPct: 24.0,
        powerOutputWatts: 465.0,
        heartRateBpm: 186.0,
        maxHeartRateBpm: 192.0,
        lactateMmol: 9.2,
        cadenceRpm: 74.0,
        climbGradientPct: 11.2,
        altitudeMeters: 2150.0,
        distanceToSummitKm: 2.8,
        climbZone: ClimbContextZone.highAltitudeFinal,
        deltaSeconds: 15.0,
      );

      final (nextState, result) =
          BluffingAndPokerFaceEngine.evaluateStep(initial, hardClimbInput);

      expect(result.trueCrisisScore, greaterThan(60.0));
      expect(result.displayedCrisisScore, lessThan(result.trueCrisisScore));
      expect(result.metabolicMaskingCostWatts, greaterThan(0.0));
      expect(result.activeCue, BodyLanguageCue.pokerFaceMask);
      expect(nextState.mentalFocusRemaining, lessThan(90.0));
    });

    test('sandbaggingPlayDead charges counter-attack window and triggers bonus', () {
      var state = BluffingAndPokerFaceState.initial().copyWith(
        activeTactic: PokerFaceTacticMode.sandbaggingPlayDead,
        mentalFocusRemaining: 95.0,
        sandbagChargeSeconds: 0.0,
      );
      const strongReserveInput = BluffingStepInput(
        wPrimeRemainingPct: 78.0,
        powerOutputWatts: 415.0,
        heartRateBpm: 170.0,
        maxHeartRateBpm: 193.0,
        lactateMmol: 5.2,
        cadenceRpm: 88.0,
        climbGradientPct: 8.5,
        altitudeMeters: 1650.0,
        distanceToSummitKm: 3.5,
        deltaSeconds: 12.0,
      );

      for (int i = 0; i < 2; i++) {
        state = BluffingAndPokerFaceEngine.evaluateStep(
          state,
          strongReserveInput,
        ).$1;
      }

      expect(state.sandbagChargeSeconds, greaterThanOrEqualTo(20.0));
      expect(state.counterAttackWindowActive, isTrue);
      expect(state.counterAttackBonusPct, inInclusiveRange(6.0, 14.0));
      expect(state.lastResult.activeCue, BodyLanguageCue.dropToBackOfGroup);

      final counter = BluffingAndPokerFaceEngine.triggerCounterAttack(state);
      expect(counter.activated, isTrue);
      expect(counter.surpriseBonusPct, greaterThanOrEqualTo(6.0));
      expect(counter.state.counterAttackWindowActive, isFalse);
      expect(counter.state.sandbagChargeSeconds, 0.0);
    });

    test('depleted mental focus forces fallback to authentic riding', () {
      final exhausted = BluffingAndPokerFaceState.initial().copyWith(
        activeTactic: PokerFaceTacticMode.bluffShowOfStrength,
        mentalFocusRemaining: 4.0,
      );

      final (nextState, result) = BluffingAndPokerFaceEngine.evaluateStep(
        exhausted,
        exhausted.lastInput,
      );

      expect(nextState.activeTactic, PokerFaceTacticMode.authentic);
      expect(result.displayedCrisisScore, closeTo(result.trueCrisisScore, 0.01));
      expect(result.metabolicMaskingCostWatts, 0.0);
    });

    test('JSON serialization round-trip preserves models cleanly', () {
      final state = BluffingAndPokerFaceState.initial();
      final decodedProfile =
          PokerFaceRiderProfile.fromJson(state.riderProfile.toJson());
      final decodedInput = BluffingStepInput.fromJson(state.lastInput.toJson());
      final decodedResult =
          BluffingStepResult.fromJson(state.lastResult.toJson());
      final decodedRival =
          RivalBodyLanguageObserver.fromJson(state.rivals.first.toJson());

      expect(decodedProfile.riderName, state.riderProfile.riderName);
      expect(
        decodedProfile.hasDarkMirroredSunglasses,
        state.riderProfile.hasDarkMirroredSunglasses,
      );
      expect(decodedInput.climbZone, state.lastInput.climbZone);
      expect(decodedResult.activeCue, state.lastResult.activeCue);
      expect(decodedRival.rivalName, state.rivals.first.rivalName);
    });
  });

  group('BluffingAndPokerFacePanel Responsive & Interactive UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: BluffingAndPokerFacePanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Poker Face & Mowa Ciała na Podjeździe'), findsOneWidget);
          expect(find.text('TAKTYKA MOWY CIAŁA'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('switching tactics and simulating climb step updates UI',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BluffingAndPokerFacePanel(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Sandbagging (Udawaj słabość)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Spadek na ogon grupy'), findsOneWidget);

      await tester.tap(find.text('Kolejny odcinek (+0.6 km)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
