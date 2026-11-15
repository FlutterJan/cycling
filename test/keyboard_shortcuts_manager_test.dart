import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/rendering3d/camera_rig_controller.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/ui/widgets/keyboard_shortcuts_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyboardShortcutsManager — Tryb Wyścigu 3D', () {
    testWidgets('obsługuje Space, prędkość ]/[, kolarzy 1-8, taktykę A/R/P, żel G, bidon B, kamerę C, Aero V i HUD Tab',
        (WidgetTester tester) async {
      bool pausedCalled = false;
      final speeds = <SimulationTimeSpeed>[];
      final selectedSlots = <int>[];
      final orders = <TacticalOrder>[];
      int gelCount = 0;
      int bidonCount = 0;
      final cameraModes = <RaceCameraMode>[];
      final aeroStates = <bool>[];
      final hudStates = <bool>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: KeyboardShortcutsManager(
                mode: ShortcutContextMode.race3d,
                onTogglePause: () => pausedCalled = true,
                onSpeedChanged: speeds.add,
                onSelectRiderBySlot: selectedSlots.add,
                onTacticalOrder: (_, order) => orders.add(order),
                onConsumeGel: (_) => gelCount++,
                onFetchBidons: (_) => bidonCount++,
                onCameraModeChanged: cameraModes.add,
                onAeroVisionChanged: aeroStates.add,
                onHudVisibilityChanged: hudStates.add,
                child: const SizedBox.expand(child: Text('Race 3D')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Space -> Pauza / Wznów
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(pausedCalled, isTrue);

      // ] oraz [ -> Zmiana mnożnika prędkości (1x -> 2x -> 1x)
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketRight);
      await tester.pump();
      expect(speeds.last, SimulationTimeSpeed.x2);

      // NumpadAdd / NumpadSubtract
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadAdd);
      await tester.pump();
      expect(speeds.last, SimulationTimeSpeed.x2);

      // Kolarze 1..8
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pump();
      expect(selectedSlots, [0, 7]);

      // A, R, P -> Rozkazy taktyczne
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      expect(orders, [
        TacticalOrder.attack,
        TacticalOrder.pullGroup,
        TacticalOrder.protectLeader,
      ]);

      // G -> Żel, B -> Bidony
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump();
      expect(gelCount, 1);
      expect(bidonCount, 1);

      // C -> Cykl kamer: ChaseCam -> MotoTvCam -> HeliCam -> FinishLineCam -> ChaseCam
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      expect(cameraModes, [
        RaceCameraMode.motoTvCam,
        RaceCameraMode.heliCam,
        RaceCameraMode.finishLineCam,
        RaceCameraMode.chaseCam,
      ]);

      // V -> Aero Vision Mode
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(aeroStates, [true, false]);

      // Tab -> Ukrycie/pokazanie bocznych paneli HUD
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(hudStates, [false, true]);
    });

    testWidgets('nie przechwytuje pojedynczych klawiszy podczas pisania w TextField',
        (WidgetTester tester) async {
      bool attackTriggered = false;
      final controller = TextEditingController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: KeyboardShortcutsManager(
                mode: ShortcutContextMode.race3d,
                onTacticalOrder: (_, __) => attackTriggered = true,
                child: Center(
                  child: TextField(controller: controller),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(attackTriggered, isFalse);
      controller.dispose();
    });
  });

  group('KeyboardShortcutsManager — Tryb Menedżera i F1 Overlay', () {
    testWidgets('obsługuje Ctrl+S, Enter, Ctrl+Space oraz F1/Escape dla ściągi skrótów',
        (WidgetTester tester) async {
      int quickSaveCount = 0;
      int advanceDayCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: KeyboardShortcutsManager(
                mode: ShortcutContextMode.manager,
                onQuickSave: () async => quickSaveCount++,
                onAdvanceDay: () => advanceDayCount++,
                child: const SizedBox.expand(child: Text('Manager')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ctrl+S -> Szybki zapis
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(quickSaveCount, 1);

      // Enter -> AdvanceDay
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(advanceDayCount, 1);

      // Ctrl+Space -> AdvanceDay
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(advanceDayCount, 2);

      // F1 -> Otwiera ShortcutsCheatSheetOverlay
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      expect(find.byType(ShortcutsCheatSheetOverlay), findsOneWidget);
      expect(find.text('Skróty Klawiszowe'), findsOneWidget);

      // Escape -> Zamyka ShortcutsCheatSheetOverlay
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ShortcutsCheatSheetOverlay), findsNothing);
    });
  });

  group('ShortcutsCheatSheetOverlay — Responsywność 390x844 / 1024x768 / 1600x900',
      () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje bez przepełnienia przy ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool closed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: ShortcutsCheatSheetOverlay(
                activeMode: ShortcutContextMode.both,
                onClose: () => closed = true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Skróty Klawiszowe'), findsOneWidget);
        expect(find.byType(ShortcutKeycap), findsWidgets);

        // Sprawdzenie filtrowania po kategorii
        final filterFinder = find.text('Tryb Menedżera i System').first;
        await tester.ensureVisible(filterFinder);
        await tester.tap(filterFinder);
        await tester.pumpAndSettle();
        expect(find.text('Szybki zapis gry'), findsOneWidget);

        // Sprawdzenie przycisku zamknięcia
        await tester.tap(find.text('Zamknij'));
        await tester.pumpAndSettle();
        expect(closed, isTrue);
      });
    }
  });
}
