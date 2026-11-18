import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_peloton_manager/ui/widgets/qr_roster_share_card_modal.dart';

void main() {
  group('ShareCardOvrStats', () {
    test('zwraca wyzerowane statystyki dla pustej listy kolarzy', () {
      final stats = ShareCardOvrStats.fromRiders(const []);
      expect(stats.averageOvr, 0);
      expect(stats.peakOvr, 0);
      expect(stats.averageWkg, 0.0);
    });
  });

  group('QrRosterShareCardModal UI & Responsiveness', () {
    Future<void> pumpModalAtSize(
      WidgetTester tester,
      Size size, {
      Widget? child,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: child ?? const QrRosterShareCardModal(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 320));
    }

    testWidgets('renderuje się poprawnie bez overflow w 390x844, 1024x768 i 1600x900',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpModalAtSize(tester, size);
        expect(find.text('Karta Wizytówki i Transfer QR'), findsOneWidget);
        expect(find.text('Obsidian Sovereign Cycling'), findsOneWidget);
        expect(find.text('KOD QR TRANSFERU'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('przełącza tryb drużyny i kolarza oraz kopiuje token do schowka',
        (tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            copiedText = args['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await pumpModalAtSize(tester, const Size(1280, 800));

      // Tryb domyślny: Wizytówka Drużyny
      expect(find.text('KLUCZOWI KOLARZE SKŁADU'), findsOneWidget);

      // Kopiowanie tokena transferowego
      await tester.tap(find.text('Kopiuj kod transferowy do schowka'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Skopiowano kod transferowy!'), findsOneWidget);
      expect(copiedText, isNotNull);
      expect(copiedText!.startsWith('PPM1:TRS.'), isTrue);

      // Przełączenie na Profil Kolarza
      await tester.tap(find.text('Profil Kolarza'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Kacper Majewski'), findsWidgets);

      // Kopiowanie tokena Be a Pro
      await tester.tap(find.text('Kopiuj kod transferowy do schowka'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(copiedText!.startsWith('PPM1:BAP.'), isTrue);

      // Odczekanie wygaśnięcia timerów przed końcem testu
      await tester.pump(const Duration(milliseconds: 2600));
    });

    testWidgets('obsługuje pusty stan i pozwala załadować wizytówkę pokazową',
        (tester) async {
      await pumpModalAtSize(
        tester,
        const Size(1024, 768),
        child: const QrRosterShareCardModal(
          roster: [],
          useDemoFallback: false,
        ),
      );

      expect(
        find.text('Brak aktywnego składu lub profilu kolarza do udostępnienia'),
        findsOneWidget,
      );

      await tester.tap(find.text('Załaduj wizytówkę pokazową'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Obsidian Sovereign Cycling'), findsOneWidget);
    });
  });
}
