import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/uci_hour_record_attempt_screen.dart';

void main() {
  Widget wrapWithSize(Size size, Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    );
  }

  group('UciHourRecordAttemptScreen', () {
    for (final Size viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow on ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            wrapWithSize(viewportSize, const UciHourRecordAttemptScreen()),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Próba Bicia Rekordu Godzinnego UCI'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'allows selecting lowland vs Mexico velodrome, 61x14 gearing, pacing strategy, and running to 60:00.00 certificate',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          wrapWithSize(
            const Size(1600, 900),
            const UciHourRecordAttemptScreen(
              initialVelodromeId: 'grenchen_tissot',
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));

        // 1. Wybór wysokogórskiego welodromu w Meksyku (Aguascalientes 1880 m)
        await tester.tap(find.text('Velódromo Bicentenario Aguascalientes'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Aklimatyzacja wysokogórska (obóz)'), findsOneWidget);

        // 2. Wybór przełożenia 61x14 oraz strategii Równe Tempo / Negative Split
        await tester.tap(find.text('61x14').last);
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('61x14'), findsWidgets);

        await tester.tap(find.text('Równe Tempo'));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.tap(find.text('Negative Split'));
        await tester.pump(const Duration(milliseconds: 150));

        // 3. Start próby 60:00.00 -> widok 3D + metronom
        await tester.tap(find.text('Rozpocznij Oficjalną Próbę 60:00.00'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Metronom Czasu Okrążenia (250 m)'), findsOneWidget);
        expect(find.text('Telemetria Torowa na Żywo'), findsOneWidget);

        // 4. Przeskok do finału 59:30 oraz przejście przez 60:00.00 przy 240x
        await tester.tap(find.text('240x'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Finał 59:30'));
        for (int i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(
          find.textContaining('60:00.00'),
          findsWidgets,
        );
        expect(
          find.text('CERTYFIKAT NOWEGO REKORDU ŚWIATA UCI'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
