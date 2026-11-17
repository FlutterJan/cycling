import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/multiplayer_leagues_and_challenges_screen.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
    MultiplayerHubTab initialTab = MultiplayerHubTab.leagues,
    bool isReadOnly = false,
    bool emptyData = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MultiplayerLeaguesAndChallengesScreen(
            initialTab: initialTab,
            isReadOnly: isReadOnly,
            initialLeagues: emptyData ? const [] : null,
            initialChallenges: emptyData ? const [] : null,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('MultiplayerLeaguesAndChallengesScreen responsive layouts', () {
    const viewports = <String, Size>{
      'mobile_390x844': Size(390, 844),
      'tablet_1024x768': Size(1024, 768),
      'desktop_1600x900': Size(1600, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('renders all tabs without overflow on ${entry.key}', (
        tester,
      ) async {
        await pumpScreen(tester, size: entry.value);

        expect(find.text('Centrum Lig Online & Wyzwań'), findsOneWidget);
        expect(find.text('Liga Przyjaciół: Alpejski Puchar'), findsWidgets);

        for (final tab in MultiplayerHubTab.values) {
          final tabFinder = find.text(tab.label);
          await tester.ensureVisible(tabFinder);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(tabFinder);
          await tester.pump(const Duration(milliseconds: 300));
        }

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('MultiplayerLeaguesAndChallengesScreen interactions', () {
    testWidgets('supports league filtering, joining and stage result submit', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(1600, 900));

      await tester.tap(find.text('WorldTour Open: Grand Tour Cup'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dołącz do Ligi'), findsOneWidget);
      await tester.tap(find.text('Dołącz do Ligi'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Dołączono do ligi'), findsOneWidget);
      expect(find.text('Wyślij Wynik Etapu'), findsOneWidget);

      await tester.tap(find.text('Wyślij Wynik Etapu'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Zapisano wynik etapu'), findsOneWidget);
    });

    testWidgets('supports creating a new league via modal dialog', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(1280, 800));

      await tester.tap(find.text('Nowa Liga'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Utwórz Nową Ligę Online'), findsOneWidget);
      await tester.tap(find.text('Utwórz Ligę'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Puchar Przyjaciół 2026'), findsWidgets);
    });

    testWidgets('records weekly ghost challenge attempt and updates ELO', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        size: const Size(1600, 900),
        initialTab: MultiplayerHubTab.weeklyChallenges,
      );

      expect(find.text('Podejmij Wyzwanie Ducha'), findsOneWidget);
      await tester.tap(find.text('Podejmij Wyzwanie Ducha'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Zapisano próbę'), findsOneWidget);

      await tester.tap(find.text('Podejmij Wyzwanie Ducha'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Pokonano ducha!'), findsOneWidget);
    });

    testWidgets('handles empty state and readOnly mode cleanly', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        size: const Size(1024, 768),
        isReadOnly: true,
        emptyData: true,
      );

      expect(find.text('Brak pasujących lig'), findsOneWidget);
      await tester.tap(find.text('Nowa Liga'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Utwórz Nową Ligę Online'), findsNothing);
    });
  });
}
