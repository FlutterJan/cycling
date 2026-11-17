import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/career_achievements_and_trophies_engine.dart';
import 'package:pro_peloton_manager/ui/screens/achievements_and_platinum_trophy_screen.dart';

Widget _wrapWithApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  group('AchievementsAndPlatinumTrophyScreen & AchievementUnlockedToast', () {
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

          await tester.pumpWidget(
            _wrapWithApp(const AchievementsAndPlatinumTrophyScreen()),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(
            find.text('Osiągnięcia i Platynowe Trofeum'),
            findsOneWidget,
          );
          expect(find.text('0/60'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('switches between all 3 sections cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapWithApp(const AchievementsAndPlatinumTrophyScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Platynowe Trofeum'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Postęp wg Rangi Trofeów'), findsOneWidget);
      expect(find.text('Postęp wg Kategorii (6 x 10)'), findsOneWidget);

      await tester.tap(find.text('Historia Odblokowań'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Dziennik Odblokowanych Trofeów'), findsOneWidget);
      expect(find.text('Brak odblokowanych osiągnięć'), findsOneWidget);
    });

    testWidgets('search filter shows empty state and clears filters',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapWithApp(const AchievementsAndPlatinumTrophyScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField), 'nieistniejace_xyz_999');
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak osiągnięć pasujących do filtrów'),
        findsOneWidget,
      );

      await tester.tap(find.text('Wyczyść filtry').last);
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak osiągnięć pasujących do filtrów'),
        findsNothing,
      );
    });

    testWidgets('triggers and dismisses AchievementUnlockedToast preview',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapWithApp(const AchievementsAndPlatinumTrophyScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Podgląd Toastu'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AchievementUnlockedToast), findsOneWidget);
      expect(find.text('OSIĄGNIĘCIE ODBLOKOWANE'), findsOneWidget);

      // Dismiss via close icon
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AchievementUnlockedToast), findsNothing);
    });

    testWidgets('reacts to provider unlock and displays in history',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = CareerAchievementsNotifier();
      final firstId = CareerAchievementsAndTrophiesEngine.catalog.first.id;

      await tester.pumpWidget(
        _wrapWithApp(
          const AchievementsAndPlatinumTrophyScreen(),
          overrides: [
            careerAchievementsProvider.overrideWith((ref) => notifier),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      notifier.incrementProgress(
        firstId,
        delta: 10.0,
        seasonYear: 2026,
        contextNote: 'Testowy etap',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AchievementUnlockedToast), findsOneWidget);

      // Dismiss toast before switching tabs
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Historia Odblokowań'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak odblokowanych osiągnięć'), findsNothing);
      expect(find.text('Pokaż Toast'), findsOneWidget);
    });

    testWidgets('readOnly mode disables Podgląd Toastu', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapWithApp(
          const AchievementsAndPlatinumTrophyScreen(readOnly: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Podgląd Toastu'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AchievementUnlockedToast), findsNothing);
    });

    testWidgets('standalone AchievementUnlockedToast renders platinum & disabled',
        (tester) async {
      final platinumEvent = CareerTrophyUnlockEvent(
        achievementId: PlatinumTrophyRecord.platinumId,
        title: PlatinumTrophyRecord.platinumTitle,
        description: PlatinumTrophyRecord.platinumDescription,
        tier: CareerAchievementTier.legendary,
        category: CareerAchievementCategory.grandToursAndStageRaces,
        pointsAwarded: PlatinumTrophyRecord.platinumBonusPoints,
        isPlatinumTrophy: true,
        unlockedAt: DateTime(2026, 7, 26),
      );

      await tester.pumpWidget(
        _wrapWithApp(
          Scaffold(
            body: Center(
              child: AchievementUnlockedToast(
                event: platinumEvent,
                shimmerProgress: 0.5,
                enabled: false,
                onDismiss: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('PLATYNOWE TROFEUM'), findsOneWidget);
      expect(find.text('+500 PKT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
