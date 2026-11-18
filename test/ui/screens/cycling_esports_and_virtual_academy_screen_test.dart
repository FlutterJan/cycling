import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/cycling_esports_and_virtual_academy_screen.dart';

void main() {
  Future<void> pumpScreenAtSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: CyclingEsportsAndVirtualAcademyScreen(
          autoAnimate3d: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('CyclingEsportsAndVirtualAcademyScreen', () {
    testWidgets('renders cleanly without overflow at 390x844 (mobile)', (
      tester,
    ) async {
      await pumpScreenAtSize(tester, const Size(390, 844));
      expect(
        find.text('UCI Cycling Esports & Virtual Talent ID'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1024x768 (tablet)', (
      tester,
    ) async {
      await pumpScreenAtSize(tester, const Size(1024, 768));
      expect(
        find.text('UCI Cycling Esports & Virtual Talent ID'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly without overflow at 1600x900 (desktop)', (
      tester,
    ) async {
      await pumpScreenAtSize(tester, const Size(1600, 900));
      expect(
        find.text('UCI Cycling Esports & Virtual Talent ID'),
        findsOneWidget,
      );
      expect(find.text('Klasyfikacja Live & Strefa Eliminacji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'supports race step progression, Power-Up activation, and all 4 tabs',
      (tester) async {
        await pumpScreenAtSize(tester, const Size(1600, 900));

        // Tab 1: Activate a Power-Up and advance race by 4x 15s (60s -> triggers round 1 elimination).
        final aeroBtn = find.text('Aero Helmet').last;
        await tester.ensureVisible(aeroBtn);
        await tester.tap(aeroBtn);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.textContaining('aktywuje Power-Up: Aero Helmet'), findsOneWidget);

        for (var i = 0; i < 4; i++) {
          await tester.tap(find.text('+15s'));
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(find.text('Historia Eliminacji'), findsOneWidget);

        // Tab 2: Trenażer & Dual-Rec
        await tester.tap(find.text('Trenażer & Dual-Rec'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text('Weryfikacja Dual-Recording & Bilans Mocy'),
          findsOneWidget,
        );
        final spindownBtn =
            find.text('Wykonaj Spindown & Kalibrację Dual-Recording');
        await tester.ensureVisible(spindownBtn);
        await tester.tap(spindownBtn);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.textContaining('Spindown OK:'), findsOneWidget);

        // Tab 3: Virtual Talent ID
        await tester.tap(find.text('Virtual Talent ID'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text('Pula Skautingu — Virtual Talent ID Academy'),
          findsOneWidget,
        );
        final signBtn = find.text('Podpisz do Devo Squad');
        await tester.ensureVisible(signBtn);
        await tester.tap(signBtn);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Zwolnij z Devo Squad'), findsOneWidget);

        final combineBtn = find.text('Test Combine 5-min');
        await tester.ensureVisible(combineBtn);
        await tester.tap(combineBtn);
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.textContaining('Test Combine 5-min ukończony:'), findsOneWidget);

        // Tab 4: Regulamin & Power-Upy
        await tester.tap(find.text('Regulamin & Power-Upy'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text('Katalog Power-Upów UCI Cycling Esports'),
          findsOneWidget,
        );
        expect(
          find.text('Przepisy Techniczne UCI Cycling Esports'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
