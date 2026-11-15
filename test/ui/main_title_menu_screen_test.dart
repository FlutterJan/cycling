import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/main_title_menu_screen.dart';

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainTitleMenuScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('MainTitleMenuScreen renders without overflow on 390x844 mobile',
      (tester) async {
    await pumpAtSize(tester, const Size(390, 844));
    expect(find.textContaining('PRO PELOTON'), findsOneWidget);
    expect(find.text('WORLD TOUR EDITION'), findsOneWidget);
    expect(find.text('NOWA KARIERA'), findsOneWidget);
    expect(find.text('WCZYTAJ GRĘ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MainTitleMenuScreen renders without overflow on 1024x768 tablet',
      (tester) async {
    await pumpAtSize(tester, const Size(1024, 768));
    expect(find.text('WORLD TOUR EDITION'), findsOneWidget);
    expect(find.text('SZYBKI WYŚCIG (SANDBOX)'), findsOneWidget);
    expect(find.text('BAZY DANYCH I USTAWIENIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'MainTitleMenuScreen renders without overflow on 1600x900 desktop and opens modals',
      (tester) async {
    await pumpAtSize(tester, const Size(1600, 900));
    expect(find.text('COL DU GALIBIER • 2 642 M'), findsOneWidget);

    await tester.tap(find.text('WCZYTAJ GRĘ'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('WCZYTAJ GRĘ (SLOTY 1–5)'), findsOneWidget);
    expect(find.text('SLOT 1'), findsOneWidget);
    expect(find.text('SLOT 5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('KREATOR TRAS I STUDIO MALOWANIA'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('KREATOR TRAS I ETAPÓW'), findsOneWidget);
    expect(
      find.text('STUDIO MALOWANIA KOSZULEK I ROWERÓW'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
