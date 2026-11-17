import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/ultra_bikepacking_transcontinental_screen.dart';

void main() {
  Widget buildTestApp({
    required Size size,
    bool isReadOnly = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: SizedBox(
          width: size.width,
          height: size.height,
          child: UltraBikepackingTranscontinentalScreen(
            isReadOnly: isReadOnly,
          ),
        ),
      ),
    );
  }

  group('UltraBikepackingTranscontinentalScreen', () {
    testWidgets('renders without overflow at 1600x900 desktop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(size: const Size(1600, 900)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dotwatching Live Tracker (GPS)'), findsOneWidget);
      expect(find.text('Panel Decyzji Nocnych & Sleep Debt'), findsOneWidget);
      expect(find.text('Dynamo Hub, Elektronika & Bagaż'), findsOneWidget);
      expect(find.text('Punkty Kontrolne (CP & Parcours)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at 1024x768 tablet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(size: const Size(1024, 768)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dotwatching Live Tracker (GPS)'), findsOneWidget);
      expect(find.text('Panel Decyzji Nocnych & Sleep Debt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders and switches tabs without overflow at 390x844 mobile',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(size: const Size(390, 844)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dotwatching Live Tracker (GPS)'), findsOneWidget);

      await tester.tap(find.text('Decyzje Nocne'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Panel Decyzji Nocnych & Sleep Debt'), findsOneWidget);

      await tester.ensureVisible(find.text('Dynamo & Bagaż'));
      await tester.tap(find.text('Dynamo & Bagaż'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Dynamo Hub, Elektronika & Bagaż'), findsOneWidget);

      await tester.ensureVisible(find.text('CP & Ranking'));
      await tester.tap(find.text('CP & Ranking'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Klasyfikacja Live Dotwatching'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('executes riding block, caffeine dose, and sleep stop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(size: const Size(1600, 900)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Execute +2h riding block
      await tester.tap(find.text('+2h Jazdy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Przejechano +'), findsOneWidget);

      // Take Espresso +100 mg
      await tester.tap(find.text('Espresso +100 mg'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Dawka kofeiny +100 mg'), findsOneWidget);

      // Switch Dynamo Hub
      await tester.ensureVisible(find.text('Aero Dynamo'));
      await tester.tap(find.text('Aero Dynamo'));
      await tester.pump(const Duration(milliseconds: 300));

      // Select Hotel 5h strategy and execute sleep decision
      final hotelOption = find.text('Hotel (5 h snu + ładowanie)').first;
      await tester.ensureVisible(hotelOption);
      await tester.tap(hotelOption);
      await tester.pump(const Duration(milliseconds: 300));

      final execButton =
          find.text('Wykonaj postój: Hotel (5 h snu + ładowanie)');
      await tester.ensureVisible(execButton);
      await tester.tap(execButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Postój: Hotel (5 h snu + ładowanie)'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects isReadOnly disabled state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(size: const Size(1600, 900), isReadOnly: true),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('+2h Jazdy'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Przejechano +'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
