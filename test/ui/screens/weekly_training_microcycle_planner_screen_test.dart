import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/screens/weekly_training_microcycle_planner_screen.dart';

void main() {
  Widget buildTestApp() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const WeeklyTrainingMicrocyclePlannerScreen(),
      ),
    );
  }

  group('WeeklyTrainingMicrocyclePlannerScreen', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(buildTestApp());
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Kalendarz Mikrocyklu Treningowego'),
            findsOneWidget,
          );
          expect(find.text('Łączny TSS'), findsOneWidget);
          expect(find.text('Prognoza TSB (Nd)'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('updates day selection, preset, workout type and applies plan',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 300));

      // Switch preset to Sweet Spot
      await tester.tap(find.text('Blok Sweet Spot (Budowa FTP)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.textContaining('Załadowano szablon: Blok Sweet Spot'),
        findsOneWidget,
      );

      // Select Friday
      await tester.tap(find.text('PT'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Piątek — Konfigurator Jednostki'),
        findsOneWidget,
      );

      // Save template
      await tester.tap(find.text('Zapisz szablon'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Zapisano mikrocykl'), findsOneWidget);

      // Apply plan
      await tester.tap(find.text('Zastosuj plan'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
