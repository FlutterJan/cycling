import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/finish_line_bike_throw_physics.dart';
import 'package:pro_peloton_manager/ui/widgets/bike_throw_timing_minigame_overlay.dart';

void main() {
  const testProfile = BikeThrowRiderProfile(
    riderId: 'sprinter_1',
    riderName: 'Janek Sprinter',
    teamName: 'Polonia Pro Cycling',
    bibNumber: 11,
    countryIso: 'PL',
    sprintSkill: 94,
    bikeHandling: 90,
    riderHeightCm: 184.0,
    wPrimeRemainingFraction: 0.65,
  );

  group('BikeThrowMinigameEvaluator', () {
    test('classifies zones across 150 m finish window accurately', () {
      expect(
        BikeThrowMinigameEvaluator.evaluateZoneForDistance(180.0),
        BikeThrowRingZone.waiting,
      );
      expect(
        BikeThrowMinigameEvaluator.evaluateZoneForDistance(100.0),
        BikeThrowRingZone.redEarly,
      );
      expect(
        BikeThrowMinigameEvaluator.evaluateZoneForDistance(30.0),
        BikeThrowRingZone.amberEarly,
      );
      // 13.5 m => progress = 1 - 13.5/150 = 0.91 (inside [0.86, 0.96])
      expect(
        BikeThrowMinigameEvaluator.evaluateZoneForDistance(13.5),
        BikeThrowRingZone.greenOptimal,
      );
      expect(
        BikeThrowMinigameEvaluator.evaluateZoneForDistance(4.0),
        BikeThrowRingZone.amberLate,
      );
      expect(
        BikeThrowMinigameEvaluator.evaluateZoneForDistance(0.0),
        BikeThrowRingZone.redLate,
      );
    });

    test('awards maximum +28 cm impulse when triggered in green zone', () {
      final result = BikeThrowMinigameEvaluator.evaluateThrow(
        profile: testProfile,
        distanceToFinishMeters: 12.0,
        speedKmh: 72.0,
      );

      expect(result.zone, BikeThrowRingZone.greenOptimal);
      expect(result.timingQuality, BikeThrowTimingQuality.perfect);
      expect(result.wheelExtensionCm, 28.0);
      expect(result.isMaxImpulse, isTrue);
      expect(result.timeSavedSeconds, greaterThan(0.013));
      expect(result.toJson()['wheelExtensionCm'], 28.0);
      expect(result.toJson()['isMaxImpulse'], isTrue);
    });

    test('returns reduced gain outside green zone and zero when missed', () {
      final earlyResult = BikeThrowMinigameEvaluator.evaluateThrow(
        profile: testProfile,
        distanceToFinishMeters: 95.0,
        speedKmh: 68.0,
      );
      expect(earlyResult.isMaxImpulse, isFalse);
      expect(earlyResult.wheelExtensionCm, lessThan(28.0));

      final missedResult = BikeThrowMinigameEvaluator.evaluateThrow(
        profile: testProfile,
        distanceToFinishMeters: 0.0,
        speedKmh: 68.0,
      );
      expect(missedResult.timingQuality, BikeThrowTimingQuality.notTriggered);
      expect(missedResult.wheelExtensionCm, 0.0);
    });
  });

  group('BikeThrowTimingMinigameOverlay widget tests', () {
    Future<void> pumpAtSize(
      WidgetTester tester, {
      required Size size,
      required Widget child,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: child,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets(
      'renders without overflow across 390x844, 1024x768 and 1600x900',
      (tester) async {
        for (final size in const [
          Size(390, 844),
          Size(1024, 768),
          Size(1600, 900),
        ]) {
          await pumpAtSize(
            tester,
            size: size,
            child: BikeThrowTimingMinigameOverlay(
              distanceToFinishMeters: 12.0,
              currentSpeedKmh: 71.5,
              riderProfile: testProfile,
              onToggleEnabled: (_) {},
              onBikeThrowTriggered: (_) {},
            ),
          );
          expect(find.text('Rzut Rowerem'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets('shows waiting banner outside 150 m and disabled banner when off',
        (tester) async {
      await pumpAtSize(
        tester,
        size: const Size(1024, 768),
        child: const BikeThrowTimingMinigameOverlay(
          distanceToFinishMeters: 210.0,
          currentSpeedKmh: 65.0,
          riderProfile: testProfile,
        ),
      );
      expect(
        find.textContaining('Pierścień synchronizacji pojawi się na ostatnich 150 m'),
        findsOneWidget,
      );

      bool toggledValue = true;
      await pumpAtSize(
        tester,
        size: const Size(1024, 768),
        child: BikeThrowTimingMinigameOverlay(
          distanceToFinishMeters: 40.0,
          currentSpeedKmh: 65.0,
          riderProfile: testProfile,
          isEnabled: false,
          onToggleEnabled: (val) => toggledValue = val,
        ),
      );
      expect(find.textContaining('Tryb automatyczny AI'), findsOneWidget);
      await tester.tap(find.text('WYŁ.'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(toggledValue, isTrue);
    });

    testWidgets('triggers +28 cm max impulse when tapped in green zone',
        (tester) async {
      BikeThrowMinigameResult? captured;

      await pumpAtSize(
        tester,
        size: const Size(1024, 768),
        child: BikeThrowTimingMinigameOverlay(
          distanceToFinishMeters: 12.0,
          currentSpeedKmh: 72.0,
          riderProfile: testProfile,
          onBikeThrowTriggered: (result) => captured = result,
        ),
      );

      await tester.tap(find.text('Rzut Rowerem'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(captured, isNotNull);
      expect(captured!.isMaxImpulse, isTrue);
      expect(captured!.wheelExtensionCm, 28.0);
      expect(find.text('WYRZUT +28 cm!'), findsOneWidget);
      expect(find.text('MAKSYMALNY IMPULS +28 cm!'), findsOneWidget);
    });

    testWidgets('supports keyboard Spacebar activation when focused',
        (tester) async {
      BikeThrowMinigameResult? captured;

      await pumpAtSize(
        tester,
        size: const Size(1600, 900),
        child: BikeThrowTimingMinigameOverlay(
          distanceToFinishMeters: 12.5,
          currentSpeedKmh: 70.0,
          riderProfile: testProfile,
          onBikeThrowTriggered: (result) => captured = result,
        ),
      );

      final buttonTextFinder = find.text('Rzut Rowerem');
      expect(buttonTextFinder, findsOneWidget);
      final focusNode = Focus.of(tester.element(buttonTextFinder));
      focusNode.requestFocus();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 350));

      expect(captured, isNotNull);
      expect(captured!.wheelExtensionCm, 28.0);
    });
  });
}
