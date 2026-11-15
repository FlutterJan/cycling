import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/career_onboarding_interactive_tour.dart';

void main() {
  Future<void> pumpTourWithViewport(
    WidgetTester tester,
    Widget child,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('CareerOnboardingInteractiveTour', () {
    testWidgets('przechodzi przez wszystkie 5 kroków i wywołuje onComplete',
        (tester) async {
      bool completed = false;
      int? lastStepSeen;

      await pumpTourWithViewport(
        tester,
        CareerOnboardingInteractiveTour(
          onStepChanged: (step) => lastStepSeen = step.index,
          onComplete: () => completed = true,
          child: const SizedBox.expand(),
        ),
        const Size(1600, 900),
      );

      expect(find.text('Centrum Dowodzenia HQ'), findsOneWidget);
      expect(find.text('KROK 1 / 5 • BIURO MENEDŻERA'), findsOneWidget);

      await tester.tap(find.text('Dalej'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(lastStepSeen, 1);
      expect(find.text('Budowanie Pociągu i Ról'), findsOneWidget);

      await tester.tap(find.text('Dalej'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(lastStepSeen, 2);
      expect(find.text('Ciśnienie w Oponach i Nawierzchnia'), findsOneWidget);

      await tester.tap(find.text('Dalej'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(lastStepSeen, 3);
      expect(find.text('Sterowanie Kolarzami w 3D'), findsOneWidget);

      await tester.tap(find.text('Dalej'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(lastStepSeen, 4);
      expect(find.text('Odprawa i Symulacja Etapu'), findsOneWidget);
      expect(find.text('Zakończ'), findsOneWidget);

      await tester.tap(find.text('Zakończ'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(completed, isTrue);
      expect(find.text('Odprawa i Symulacja Etapu'), findsNothing);
    });

    testWidgets('przycisk Pomiń samouczek ukrywa nakładkę i wywołuje onSkip',
        (tester) async {
      bool skipped = false;

      await pumpTourWithViewport(
        tester,
        CareerOnboardingInteractiveTour(
          onSkip: () => skipped = true,
          child: const Center(child: Text('HQ_BG')),
        ),
        const Size(1024, 768),
      );

      expect(find.text('Centrum Dowodzenia HQ'), findsOneWidget);
      await tester.tap(find.text('Pomiń samouczek'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(skipped, isTrue);
      expect(find.text('Centrum Dowodzenia HQ'), findsNothing);
      expect(find.text('HQ_BG'), findsOneWidget);
    });

    testWidgets('zwijanie do pigułki i ponowne rozwijanie działa poprawnie',
        (tester) async {
      await pumpTourWithViewport(
        tester,
        const CareerOnboardingInteractiveTour(
          child: SizedBox.expand(),
        ),
        const Size(1024, 768),
      );

      await tester.tap(find.byIcon(Icons.minimize_rounded));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Samouczek 1/5'), findsOneWidget);

      await tester.tap(find.text('Rozwiń'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Centrum Dowodzenia HQ'), findsOneWidget);
    });

    testWidgets(
        'jest nieinwazyjny: pozwala klikać elementy tła i podświetla GlobalKey',
        (tester) async {
      int bgClicks = 0;
      final officeKey = GlobalKey();

      await pumpTourWithViewport(
        tester,
        CareerOnboardingInteractiveTour(
          targetKeys: {
            OnboardingHighlightTarget.managerOffice: officeKey,
          },
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                key: officeKey,
                onPressed: () => bgClicks++,
                child: const Text('Akcja HQ'),
              ),
            ),
          ),
        ),
        const Size(1600, 900),
      );

      await tester.tap(find.text('Akcja HQ'));
      await tester.pump();
      expect(bgClicks, 1);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renderuje się bez błędów przepełnienia w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pumpTourWithViewport(
          tester,
          const CareerOnboardingInteractiveTour(
            child: SizedBox.expand(),
          ),
          size,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Centrum Dowodzenia HQ'), findsOneWidget);

        await tester.tap(find.text('Dalej'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull);
        expect(find.text('Budowanie Pociągu i Ról'), findsOneWidget);
      });
    }
  });

  group('CareerOnboardingTourNotifier', () {
    test('poprawnie zarządza stanem kroków, pominięciem i resetem', () {
      final notifier = CareerOnboardingTourNotifier(totalSteps: 5);
      expect(notifier.state.isVisible, isTrue);
      expect(notifier.state.currentStepIndex, 0);

      notifier.previousStep();
      expect(notifier.state.currentStepIndex, 0);

      notifier.nextStep();
      expect(notifier.state.currentStepIndex, 1);

      notifier.goToStep(4);
      expect(notifier.state.currentStepIndex, 4);

      notifier.nextStep();
      expect(notifier.state.isVisible, isFalse);
      expect(notifier.state.hasCompleted, isTrue);

      notifier.resetTour();
      expect(notifier.state.isVisible, isTrue);
      expect(notifier.state.currentStepIndex, 0);
      expect(notifier.state.hasCompleted, isFalse);

      notifier.skipTour();
      expect(notifier.state.isVisible, isFalse);
      expect(notifier.state.wasSkipped, isTrue);
    });
  });
}
