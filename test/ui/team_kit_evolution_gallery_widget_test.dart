import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/ui/widgets/team_kit_evolution_gallery_widget.dart';

void main() {
  group('TeamKitEvolutionGalleryWidget & Archive', () {
    test('TeamSeasonKitRecord JSON round-trip preserves kit, bike and successes', () {
      final demo = TeamKitEvolutionArchive.buildDemoArchive();
      final original = demo.last;

      final json = original.toJson();
      final restored = TeamSeasonKitRecord.fromJson(json);

      expect(restored.seasonYear, original.seasonYear);
      expect(restored.teamName, original.teamName);
      expect(restored.teamTla, original.teamTla);
      expect(restored.jerseyPattern, original.jerseyPattern);
      expect(restored.primaryColor.toARGB32(), original.primaryColor.toARGB32());
      expect(restored.bike.name, original.bike.name);
      expect(restored.bike.frame.weightGrams, original.bike.frame.weightGrams);
      expect(restored.successes.length, original.successes.length);
      expect(restored.successes.first, original.successes.first);
    });

    test('archiveCompletedSeason sorts chronologically and updates existing year', () {
      final demo = TeamKitEvolutionArchive.buildDemoArchive();
      final updated2028 = demo[2].copyWith(
        totalWinsCount: 33,
        seasonSummaryNote: 'Zaktualizowany rekord sezonu 2028',
      );

      final result = TeamKitEvolutionArchive.archiveCompletedSeason(
        existingArchive: demo.reversed.toList(),
        completedSeasonRecord: updated2028,
      );

      expect(result.length, demo.length);
      expect(result.map((e) => e.seasonYear).toList(), [2026, 2027, 2028, 2029]);
      expect(
        result.firstWhere((e) => e.seasonYear == 2028).totalWinsCount,
        33,
      );
    });

    testWidgets('displays seasons, switches selection, flips jersey and toggles compare mode', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final records = TeamKitEvolutionArchive.buildDemoArchive();
      TeamSeasonKitRecord? selectedFromCallback;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: TeamKitEvolutionGalleryWidget(
              seasonRecords: records,
              onSeasonSelected: (record) => selectedFromCallback = record,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Galeria Ewolucji Barw i Rowerów'), findsOneWidget);
      expect(find.text('SEZON 2029'), findsOneWidget);
      expect(find.text('Tour de France'), findsOneWidget);

      // Wybierz sezon 2028
      await tester.tap(find.text('2028'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(selectedFromCallback?.seasonYear, 2028);
      expect(find.text('SEZON 2028'), findsOneWidget);
      expect(find.text('Paris-Roubaix'), findsOneWidget);

      // Odwróć koszulkę na tył
      await tester.tap(find.text('Widok: Przód'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Widok: Tył'), findsOneWidget);
      expect(find.text('KOSZULKA (TYŁ)'), findsOneWidget);

      // Włącz tryb porównania 2 sezonów
      await tester.tap(find.text('Porównaj sezony'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Porównanie Ewolucji Między Sezonami'), findsOneWidget);
      expect(find.text('SEZON A'), findsOneWidget);
      expect(find.text('SEZON B'), findsOneWidget);
    });

    testWidgets('handles empty archive and disabled archive button state', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int archiveCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: TeamKitEvolutionGalleryWidget(
              seasonRecords: const [],
              isCurrentSeasonArchived: true,
              onArchiveCurrentSeason: () => archiveCalls++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak zarchiwizowanych sezonów'), findsOneWidget);
      expect(find.text('Sezon zapisany'), findsOneWidget);

      await tester.tap(find.text('Sezon zapisany'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(archiveCalls, 0);
    });

    testWidgets('renders without overflow on 390x844, 1024x768 and 1600x900', (
      WidgetTester tester,
    ) async {
      final records = TeamKitEvolutionArchive.buildDemoArchive();
      const viewports = [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: TeamKitEvolutionGalleryWidget(
                seasonRecords: records,
                onArchiveCurrentSeason: () {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Unexpected exception at viewport $size',
        );
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
