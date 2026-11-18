import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/bluffing_and_poker_face_body_language.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_poker_face_bluff_action_button.dart';

void main() {
  Widget wrapTestApp(
    Widget child, {
    Size surfaceSize = const Size(1024, 768),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: surfaceSize.width - 32,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('RiderPokerFaceBluffActionButton', () {
    testWidgets('toggles bluff mode on primary tap and expands mode selector',
        (tester) async {
      PokerFaceTacticMode? selected;
      var sunglassesToggled = false;

      const data = RiderPokerFaceBluffButtonData(
        riderId: 'leader-1',
        riderName: 'M. Kwiatkowski',
        activeTactic: PokerFaceTacticMode.authentic,
        mentalFocusRemaining: 82.0,
        deceptionSuccessProbability: 0.78,
        hasDarkMirroredSunglasses: false,
      );

      await tester.pumpWidget(
        wrapTestApp(
          RiderPokerFaceBluffActionButton(
            data: data,
            onSelectTactic: (mode) => selected = mode,
            onToggleSunglasses: () => sunglassesToggled = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Blefuj Kryzys / Poker Face'), findsOneWidget);
      expect(find.text('NATURAL'), findsAtLeastNWidgets(1));
      expect(find.text('Fokus 82%'), findsOneWidget);

      await tester.tap(find.text('Blefuj Kryzys / Poker Face'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, PokerFaceTacticMode.sandbaggingPlayDead);

      // Expand mode selector and select Poker Face + toggle sunglasses
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MASKA'), findsOneWidget);
      expect(find.text('PUŁAPKA'), findsOneWidget);
      expect(find.text('BLEF SIŁY'), findsOneWidget);

      await tester.tap(find.text('MASKA'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, PokerFaceTacticMode.pokerFaceHideCrisis);

      await tester.tap(find.text('Lustrzanki OFF'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(sunglassesToggled, isTrue);
    });

    testWidgets('shows counter-attack banner and triggers callback',
        (tester) async {
      var counterTriggered = false;
      const data = RiderPokerFaceBluffButtonData(
        riderId: 'leader-1',
        riderName: 'M. Kwiatkowski',
        activeTactic: PokerFaceTacticMode.sandbaggingPlayDead,
        outcome: BluffDetectionOutcome.counterAttackBaited,
        mentalFocusRemaining: 64.0,
        deceptionSuccessProbability: 0.85,
        counterAttackWindowActive: true,
        counterAttackBonusPct: 14.5,
      );

      await tester.pumpWidget(
        wrapTestApp(
          RiderPokerFaceBluffActionButton(
            data: data,
            onTriggerCounterAttack: () => counterTriggered = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('OKNO KONTRATAKU! +14.5% mocy zaskoczenia'),
        findsOneWidget,
      );
      await tester.tap(find.text('ATAKUJ'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(counterTriggered, isTrue);
    });

    testWidgets('handles hover and disabled states cleanly', (tester) async {
      PokerFaceTacticMode? selected;
      const disabledData = RiderPokerFaceBluffButtonData(
        riderId: 'leader-1',
        riderName: 'M. Kwiatkowski',
        activeTactic: PokerFaceTacticMode.authentic,
        mentalFocusRemaining: 4.0,
        isClimbActive: true,
      );

      await tester.pumpWidget(
        wrapTestApp(
          RiderPokerFaceBluffActionButton(
            data: disabledData,
            onSelectTactic: (mode) => selected = mode,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Zbyt niski fokus mentalny (<6%)'), findsOneWidget);

      // Hover over widget
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(
        tester.getCenter(find.text('Blefuj Kryzys / Poker Face')),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Blefuj Kryzys / Poker Face'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(selected, isNull);
    });

    testWidgets('integrates with bluffingAndPokerFaceProvider via Riverpod',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: wrapTestApp(
            const RiderPokerFaceBluffCommandButton(initiallyExpanded: true),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Blefuj Kryzys / Poker Face'), findsOneWidget);
      await tester.tap(find.text('PUŁAPKA'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Sandbagging (Udawaj słabość)'), findsOneWidget);
    });

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

        const data = RiderPokerFaceBluffButtonData(
          riderId: 'leader-1',
          riderName: 'M. Kwiatkowski',
          activeTactic: PokerFaceTacticMode.pokerFaceHideCrisis,
          mentalFocusRemaining: 75.0,
          deceptionSuccessProbability: 0.81,
          counterAttackWindowActive: true,
          counterAttackBonusPct: 12.0,
          hasDarkMirroredSunglasses: true,
        );

        await tester.pumpWidget(
          wrapTestApp(
            const RiderPokerFaceBluffActionButton(
              data: data,
              initiallyExpanded: true,
            ),
            surfaceSize: size,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('Blefuj Kryzys / Poker Face'), findsOneWidget);
      });
    }
  });
}
