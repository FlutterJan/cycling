import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/voice_command_quick_actions_stub.dart';

void main() {
  group('VoiceCommandParser', () {
    test('normalizes Polish diacritics and whitespace', () {
      expect(
        VoiceCommandParser.normalize('  Zjedź   po   bidony  Żółty  '),
        equals('zjedz po bidony zolty'),
      );
    });

    test('detects rider by bib number and ignores unavailable riders', () {
      const riders = [
        VoiceCommandTargetRider(
          riderId: 'r1',
          name: 'M. Kowalski',
          roleLabel: 'Lider GC',
          bibNumber: 11,
        ),
        VoiceCommandTargetRider(
          riderId: 'r2',
          name: 'L. Moreau',
          roleLabel: 'Góral',
          bibNumber: 12,
          isAvailable: false,
          unavailableReason: 'Wycofany po kraksie',
        ),
      ];

      final foundByBib = VoiceCommandParser.detectTargetRider('#11 atakuj', riders);
      expect(foundByBib?.riderId, equals('r1'));

      final unavailable = VoiceCommandParser.detectTargetRider('#12 atakuj', riders);
      expect(unavailable, isNull);

      final foundByName =
          VoiceCommandParser.detectTargetRider('Kowalski chron lidera', riders);
      expect(foundByName?.riderId, equals('r1'));
    });

    test('filters by category and ranks matching commands', () {
      final matches = VoiceCommandParser.filterAndRank(
        query: 'bidony',
        category: VoiceCommandCategory.nutrition,
        commands: VoiceQuickCommandCatalog.defaultCommands,
        riders: VoiceQuickCommandCatalog.defaultRiders,
      );

      expect(matches, isNotEmpty);
      expect(matches.first.command.id, equals('cmd_fetch_bidons'));
    });

    test('sorts disabled commands below enabled commands', () {
      final disabledFirst = [
        VoiceQuickCommandCatalog.defaultCommands.first.copyWith(
          isEnabled: false,
          disabledReason: 'Brak energii W\'',
        ),
        VoiceQuickCommandCatalog.defaultCommands[1],
      ];

      final matches = VoiceCommandParser.filterAndRank(
        query: '',
        category: VoiceCommandCategory.all,
        commands: disabledFirst,
        riders: VoiceQuickCommandCatalog.defaultRiders,
      );

      expect(matches.length, equals(2));
      expect(matches.first.command.isEnabled, isTrue);
      expect(matches.last.command.isEnabled, isFalse);
    });
  });

  group('VoiceCommandPaletteNotifier', () {
    test('manages open/close, filter, rider selection, and execution history', () {
      final notifier = VoiceCommandPaletteNotifier();
      expect(notifier.state.isOpen, isFalse);

      notifier.openPalette();
      expect(notifier.state.isOpen, isTrue);

      notifier.selectRider('rider_leader');
      expect(notifier.state.selectedRiderId, equals('rider_leader'));

      // Toggle same rider clears selection
      notifier.selectRider('rider_leader');
      expect(notifier.state.selectedRiderId, isNull);

      final cmd = VoiceQuickCommandCatalog.defaultCommands.first;
      for (int i = 0; i < 6; i++) {
        notifier.recordExecution(
          command: cmd,
          targetRider: VoiceQuickCommandCatalog.defaultRiders.first,
          confidence: 0.95,
          rawTranscript: 'Atakuj #$i',
        );
      }

      expect(notifier.state.history.length, equals(5));
      expect(
        notifier.state.listeningMode,
        equals(VoiceRadioListeningMode.confirmed),
      );

      final disabledCmd = cmd.copyWith(
        isEnabled: false,
        disabledReason: 'Limit W\' wyczerpany',
      );
      final rejected = notifier.recordExecution(
        command: disabledCmd,
        targetRider: null,
        confidence: 0.9,
        rawTranscript: 'Atakuj',
      );
      expect(rejected, isNull);
      expect(
        notifier.state.listeningMode,
        equals(VoiceRadioListeningMode.error),
      );

      notifier.closePalette();
      expect(notifier.state.isOpen, isFalse);
      notifier.dispose();
    });
  });

  group('VoiceCommandQuickActionsPalette Widget & Responsiveness', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size, Widget child) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: child,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          VoiceCommandExecutionPayload? executed;
          await pumpAtSize(
            tester,
            size,
            VoiceCommandQuickActionsPalette(
              onCommandExecuted: (payload) => executed = payload,
              onClose: () {},
            ),
          );

          expect(find.text('Paleta Komend Radia Wyścigowego'), findsOneWidget);
          expect(find.text('Atakuj teraz!'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Atakuj teraz!'));
          await tester.pump(const Duration(milliseconds: 300));
          expect(executed, isNotNull);
          expect(executed!.command.id, equals('cmd_attack_now'));
        },
      );
    }

    testWidgets('filters commands by text query and handles empty state', (tester) async {
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        const VoiceCommandQuickActionsPalette(),
      );

      await tester.enterText(find.byType(TextField), '#11 bidony');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Zjedź po bidony do wozu'), findsOneWidget);
      expect(find.text('Atakuj teraz!'), findsNothing);

      await tester.enterText(find.byType(TextField), 'nieistniejaca_fraza_xyz');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak pasujących komend radiowych'), findsOneWidget);
      await tester.tap(find.text('Wyczyść filtry'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Atakuj teraz!'), findsOneWidget);
    });

    testWidgets('simulates voice mic listening and cleans up timer safely', (tester) async {
      await pumpAtSize(
        tester,
        const Size(1024, 768),
        const VoiceCommandQuickActionsPalette(),
      );

      await tester.tap(find.text('Mów'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Nasłuch...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 750));
      expect(find.textContaining('Rozpoznano transkrypcję głosową'), findsOneWidget);
    });

    testWidgets('opens palette with Alt+Space in VoiceCommandQuickActionsShortcutHost', (tester) async {
      await pumpAtSize(
        tester,
        const Size(1280, 800),
        VoiceCommandQuickActionsShortcutHost(
          child: Center(
            child: VoiceCommandPaletteTriggerButton(
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Paleta Komend Radia Wyścigowego'), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Paleta Komend Radia Wyścigowego'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Paleta Komend Radia Wyścigowego'), findsNothing);
    });
  });
}
