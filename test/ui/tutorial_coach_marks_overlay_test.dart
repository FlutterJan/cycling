import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/settings/game_settings.dart';
import 'package:pro_peloton_manager/state/game_settings_notifier.dart';
import 'package:pro_peloton_manager/ui/widgets/tutorial_coach_marks_overlay.dart';

void main() {
  group('TutorialCoachMarksOverlay & Interactive Race Academy', () {
    test('kInteractiveRaceAcademySteps zawiera 6 kroków z wymaganymi tematami', () {
      expect(kInteractiveRaceAcademySteps.length, 6);
      expect(kInteractiveRaceAcademySteps[0].title, contains('Draftingu'));
      expect(kInteractiveRaceAcademySteps[1].title, contains('Glikogen'));
      expect(kInteractiveRaceAcademySteps[2].title, contains('Pociąg Górski'));
      expect(kInteractiveRaceAcademySteps[3].title, contains('Bruk'));
      expect(kInteractiveRaceAcademySteps[4].title, contains('TSB'));
      expect(kInteractiveRaceAcademySteps[5].stepNumber, 6);
    });

    test('GameSettings serializuje i odtwarza flagi samouczka z bezpiecznymi domyślnymi', () {
      const settings = GameSettings(
        hasCompletedRaceTutorial: true,
        showTutorialHints: false,
      );
      final restored = GameSettings.fromJson(settings.toJson());
      expect(restored.hasCompletedRaceTutorial, isTrue);
      expect(restored.showTutorialHints, isFalse);

      final legacy = GameSettings.fromJson(const {});
      expect(legacy.hasCompletedRaceTutorial, isFalse);
      expect(legacy.showTutorialHints, isTrue);
    });

    test('GameSettingsNotifier obsługuje ukończenie, pominięcie i restart samouczka', () {
      final notifier = GameSettingsNotifier();
      expect(notifier.state.hasCompletedRaceTutorial, isFalse);
      expect(notifier.state.showTutorialHints, isTrue);

      notifier.skipRaceTutorial();
      expect(notifier.state.hasCompletedRaceTutorial, isTrue);

      notifier.restartRaceTutorial();
      expect(notifier.state.hasCompletedRaceTutorial, isFalse);
      expect(notifier.state.showTutorialHints, isTrue);

      notifier.completeRaceTutorial();
      expect(notifier.state.hasCompletedRaceTutorial, isTrue);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje wszystkie 6 kroków bez przepełnień w rozdzielczości ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final container = ProviderContainer();
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(
                  body: TutorialCoachMarksOverlay(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 350));

          // Krok 1
          expect(find.text('Fizyka Draftingu i Wiatru'), findsOneWidget);

          // Przejście przez kroki 2..6
          for (var step = 2; step <= 6; step++) {
            await tester.tap(find.text('Dalej').last);
            await tester.pump(const Duration(milliseconds: 350));
            await tester.pump();
            expect(find.textContaining('KROK $step / 6'), findsOneWidget);
          }

          // Krok 4 ma interaktywny przełącznik 28mm / 32mm — sprawdźmy brak błędów
          await tester.tap(find.text('Poprzedni').last);
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pump();
          await tester.tap(find.text('Poprzedni').last);
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pump();
          expect(find.text('Ciśnienie w oponach i Bruk'), findsOneWidget);
          await tester.ensureVisible(find.text('28mm (6.2 BAR)'));
          await tester.pump();
          await tester.tap(find.text('28mm (6.2 BAR)'));
          await tester.pump();
          expect(find.textContaining('Na gładkim asfalcie 28mm'), findsOneWidget);

          // Pominięcie samouczka w dowolnej chwili
          await tester.tap(find.text('Pomiń').last);
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pump();
          expect(container.read(gameSettingsProvider).hasCompletedRaceTutorial, isTrue);
          expect(find.text('INTERACTIVE RACE ACADEMY'), findsNothing);
        },
      );
    }
  });
}
