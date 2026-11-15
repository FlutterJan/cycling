import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/ui/widgets/tactical_radial_command_menu.dart';

void main() {
  Widget buildTestHarness({
    required Size screenSize,
    Offset anchorPosition = const Offset(200, 300),
    TacticalOrder? activeOrder = TacticalOrder.holdPosition,
    bool isPlayerRider = true,
    int gelsLeft = 3,
    int bidonsLeft = 2,
    ValueChanged<TacticalRadialCommandType>? onCommandSelected,
    VoidCallback? onDismiss,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Scaffold(
          body: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: TacticalRadialCommandMenu(
              riderId: 'r_1',
              riderName: 'Michał Kwiatkowski',
              bibNumber: 14,
              anchorPosition: anchorPosition,
              activeOrder: activeOrder,
              isPlayerRider: isPlayerRider,
              gelsLeft: gelsLeft,
              bidonsLeft: bidonsLeft,
              currentWatts: 385,
              onCommandSelected: onCommandSelected,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );
  }

  group('TacticalRadialCommandMenu', () {
    testWidgets('renders all 8 radial slices and center hub without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestHarness(
          screenSize: const Size(1600, 900),
          anchorPosition: const Offset(800, 450),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      for (final cmd in TacticalRadialCommandType.values) {
        expect(find.text(cmd.shortLabel), findsOneWidget);
      }
      expect(find.text('#14'), findsOneWidget);
      expect(find.text('Kwiatkowski'), findsOneWidget);
      expect(find.text('385 W'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive across 390x844, 1024x768, 1600x900 even at corners',
        (tester) async {
      final viewports = <Size>[
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      for (final size in viewports) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          buildTestHarness(
            screenSize: size,
            anchorPosition: Offset(size.width - 5, size.height - 5),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 250));

        expect(find.byType(TacticalRadialCommandMenu), findsOneWidget);
        expect(find.text('#14'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('hovering slice updates detail card and clicking fires command',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TacticalRadialCommandType? selected;
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestHarness(
          screenSize: const Size(1024, 768),
          anchorPosition: const Offset(512, 384),
          onCommandSelected: (cmd) => selected = cmd,
          onDismiss: () => dismissed = true,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      // Top slice (index 0) is Atakuj
      final attackPos = tester.getCenter(find.text('Atakuj'));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(attackPos);
      await tester.pumpAndSettle();

      expect(
        find.text(TacticalRadialCommandType.attack.description),
        findsOneWidget,
      );

      await tester.tapAt(attackPos);
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      expect(selected, TacticalRadialCommandType.attack);
      expect(dismissed, isTrue);
    });

    testWidgets('energy gel is disabled when gelsLeft == 0', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TacticalRadialCommandType? selected;

      await tester.pumpWidget(
        buildTestHarness(
          screenSize: const Size(1024, 768),
          anchorPosition: const Offset(512, 384),
          gelsLeft: 0,
          onCommandSelected: (cmd) => selected = cmd,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      final gelPos = tester.getCenter(find.text('Żel'));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(gelPos);
      await tester.pumpAndSettle();

      expect(
        find.text('Brak żeli energetycznych w kieszonkach'),
        findsOneWidget,
      );

      await tester.tapAt(gelPos);
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      expect(selected, isNull);
    });

    testWidgets('rival rider disables all tactical commands', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TacticalRadialCommandType? selected;

      await tester.pumpWidget(
        buildTestHarness(
          screenSize: const Size(1024, 768),
          anchorPosition: const Offset(512, 384),
          isPlayerRider: false,
          onCommandSelected: (cmd) => selected = cmd,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      await tester.tapAt(tester.getCenter(find.text('Atakuj')));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      expect(selected, isNull);
    });

    testWidgets('keyboard navigation selects command and Escape dismisses',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TacticalRadialCommandType? selected;
      bool dismissed = false;

      await tester.pumpWidget(
        buildTestHarness(
          screenSize: const Size(1024, 768),
          anchorPosition: const Offset(512, 384),
          onCommandSelected: (cmd) => selected = cmd,
          onDismiss: () => dismissed = true,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('Atakuj'), findsAtLeastNWidgets(1));

      await tester.sendKeyEvent(LogicalKeyboardKey.digit8);
      await tester.pumpAndSettle(const Duration(milliseconds: 250));

      expect(selected, TacticalRadialCommandType.grupettoSaveEnergy);
      expect(dismissed, isTrue);
    });
  });
}
