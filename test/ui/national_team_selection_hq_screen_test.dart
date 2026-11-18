import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/national_federation_team_manager_mode.dart';
import 'package:pro_peloton_manager/ui/screens/national_team_selection_hq_screen.dart';

void main() {
  Widget buildTestApp({
    bool isReadOnly = false,
    NationalTeamHqTab initialTab = NationalTeamHqTab.callUpsAndPool,
    NationalChampionshipCampaignState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          nationalFederationManagerProvider.overrideWith(
            (ref) => NationalFederationTeamManagerNotifier(
              initialState: initialState,
            ),
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: NationalTeamSelectionHqScreen(
          isReadOnly: isReadOnly,
          initialTab: initialTab,
        ),
      ),
    );
  }

  group('NationalTeamSelectionHqScreen responsive & interactive tests', () {
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

          expect(find.textContaining('Biuro Selekcjonera'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('search empty state and filter reset work cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'NieistniejacyKolarzXYZ');
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak kolarzy spełniających kryteria'),
        findsOneWidget,
      );

      await tester.tap(find.text('Resetuj filtry'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak kolarzy spełniających kryteria'),
        findsNothing,
      );
      expect(find.text('Michał Kwiatkowski'), findsWidgets);
    });

    testWidgets('switching nation preset, tabs and simulating championship',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Federacja & Wyniki'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Federacja, Impreza i Trasa'), findsOneWidget);

      await tester.tap(find.text('BEL • Belgia'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Belgia'), findsWidgets);

      final simBtn = find.text('Symuluj Finał');
      await tester.ensureVisible(simBtn);
      await tester.tap(simBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('pkt UCI'), findsWidgets);
    });

    testWidgets('read-only mode shows badge and disables mutations',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(isReadOnly: true));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PODGLĄD'), findsOneWidget);

      await tester.tap(find.text('Auto-Powołanie'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });
}
