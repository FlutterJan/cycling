import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/team_bus_locker_room_screen.dart';

void main() {
  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size, {
    List<int>? presetDayConditions,
    ValueChanged<TeamBusBriefingResult>? onSpeechDelivered,
    ValueChanged<TeamBusBriefingResult>? onProceedToStart,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: TeamBusLockerRoomScreen(
          presetDayConditions:
              presetDayConditions ?? const [4, 2, 0, -1, 3, -3, 1, 5],
          instantWarmUpForTesting: true,
          onSpeechDelivered: onSpeechDelivered,
          onProceedToStart: onProceedToStart,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders cleanly at 390x844, 1024x768 and 1600x900 without overflow',
      (WidgetTester tester) async {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      await pumpAtSize(tester, size);
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is TeamBusInteriorPainter,
        ),
        findsOneWidget,
      );
      expect(find.text('Zdejmijcie presję'), findsOneWidget);
      expect(
        find.text('Jedziemy dziś wszystko na naszego lidera!'),
        findsOneWidget,
      );
      expect(find.text('Zaatakujcie od kilometra zero!'), findsOneWidget);
      expect(
        find.text('Przetrwajcie ten etap w limicie czasu'),
        findsOneWidget,
      );
    }
  });

  testWidgets('reveals Day Condition (-5..+5) after trainer warm-up',
      (WidgetTester tester) async {
    await pumpAtSize(
      tester,
      const Size(1600, 900),
      presetDayConditions: const [4, -2, 0, 1, 3, -4, 2, 5],
    );

    expect(find.text('0 / 8 po rozgrzewce'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(8));

    await tester.tap(find.text('Rozgrzewka na trenażerze').first);
    await tester.pump();

    expect(find.text('1 / 8 po rozgrzewce'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);

    await tester.tap(find.text('Rozgrzej wszystkich (1/8)'));
    await tester.pump();

    expect(find.text('8 / 8 po rozgrzewce'), findsOneWidget);
    expect(find.text('-4'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
  });

  testWidgets('delivering director speech updates morale and first 20km focus',
      (WidgetTester tester) async {
    TeamBusBriefingResult? speechResult;
    TeamBusBriefingResult? proceedResult;

    await pumpAtSize(
      tester,
      const Size(1600, 900),
      onSpeechDelivered: (r) => speechResult = r,
      onProceedToStart: (r) => proceedResult = r,
    );

    await tester.tap(find.text('Zaatakujcie od kilometra zero!'));
    await tester.pump();

    final speechBtn = find.text('Wygłoś mowę motywacyjną');
    await tester.ensureVisible(speechBtn);
    await tester.tap(speechBtn);
    await tester.pump();

    expect(speechResult, isNotNull);
    expect(
      speechResult!.deliveredSpeech,
      DirectorSpeechOption.attackFromKmZero,
    );
    expect(speechResult!.riderSlots.length, 8);
    for (final slot in speechResult!.riderSlots) {
      expect(slot.currentMorale, greaterThanOrEqualTo(slot.baseMorale));
      expect(
        slot.currentFocusFirst20Km,
        greaterThan(slot.baseFocusFirst20Km),
      );
    }

    expect(find.text('WYGŁOSZONA'), findsOneWidget);

    await tester.tap(find.text('Wyjdź na linię startu'));
    await tester.pump();
    expect(proceedResult, isNotNull);
  });
}
