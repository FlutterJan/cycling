import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/talent_combine_tryouts_screen.dart';

void main() {
  Future<void> pumpScreenAtSize(
    WidgetTester tester,
    Size size, {
    VoidCallback? onBack,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: TalentCombineTryoutsScreen(onBack: onBack),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('TalentCombineTryoutsScreen — Responsywność', () {
    for (final entry in const <String, Size>{
      '390x844 (mobile)': Size(390, 844),
      '1024x768 (tablet)': Size(1024, 768),
      '1600x900 (desktop)': Size(1600, 900),
    }.entries) {
      testWidgets('Renderuje się poprawnie bez przepełnień w ${entry.key}', (
        tester,
      ) async {
        await pumpScreenAtSize(tester, entry.value);

        expect(find.text('Global Young Talent Combine'), findsOneWidget);
        expect(find.text('Otwórz Obóz Combine'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('TalentCombineTryoutsScreen — Pełny przepływ tryouts', () {
    testWidgets(
      'Otwarcie obozu, testy laboratoryjne, wyścig 85 km i podpisanie juniora',
      (tester) async {
        await pumpScreenAtSize(tester, const Size(1600, 900));

        // 1. Otwarcie nowej edycji Combine
        await tester.tap(find.text('Otwórz Obóz Combine'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Lista Adeptów'), findsOneWidget);
        expect(find.text('Batch Lab'), findsOneWidget);

        // 2. Batch Lab dla wszystkich kandydatów
        await tester.tap(find.text('Batch Lab'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Pełne Lab Ukończone'), findsOneWidget);

        // 3. Przejście do Wyścigu Selekcyjnego 85 km i symulacja
        await tester.tap(find.text('Wyścig Selekcyjny 85 km'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Symuluj Wyścig 85 km'), findsOneWidget);
        await tester.tap(find.text('Symuluj Wyścig 85 km'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Miejsce #1'), findsOneWidget);
        expect(find.text('Wyścig Rozegrany'), findsOneWidget);

        // 4. Przejście do Draft & Kontrakty, shortlist i podpisanie juniora
        await tester.tap(find.text('Draft & Kontrakty'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Board Draftu i Kontraktów Juniorów'), findsOneWidget);

        await tester.tap(find.text('Lista życzeń').first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Na liście życzeń'), findsWidgets);

        await tester.tap(find.text('Podpisz (U19/U23)').first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('1/3'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Przycisk powrotu wywołuje callback onBack', (tester) async {
      var backCalled = false;
      await pumpScreenAtSize(
        tester,
        const Size(1024, 768),
        onBack: () => backCalled = true,
      );

      await tester.tap(find.text('Powrót'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(backCalled, isTrue);
    });
  });
}
