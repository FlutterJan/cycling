import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/ui/screens/achievements_and_platinum_trophy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/companion_car_dashboard_screen.dart';
import 'package:pro_peloton_manager/ui/screens/gravel_world_series_hub_screen.dart';
import 'package:pro_peloton_manager/ui/screens/in_game_database_roster_editor_screen.dart';
import 'package:pro_peloton_manager/ui/screens/olympic_games_hub_and_medal_table_screen.dart';
import 'package:pro_peloton_manager/ui/screens/pre_stage_paddock_and_warmup_screen.dart';

void main() {
  Future<void> pumpRoute(
    WidgetTester tester, {
    required GoRouter router,
    Size viewport = const Size(1600, 900),
  }) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  group('AppRouter Paczka #5 Routes', () {
    testWidgets('navigates to GravelWorldSeriesHubScreen via path and query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.gravelWorldSeries}?tireMm=45.0',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(GravelWorldSeriesHubScreen), findsOneWidget);
      final screen = tester.widget<GravelWorldSeriesHubScreen>(
        find.byType(GravelWorldSeriesHubScreen),
      );
      expect(screen.initialTireWidthMm, 45.0);
    });

    testWidgets('navigates to OlympicGamesHubAndMedalTableScreen via nation query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.olympicGames}?nation=bel',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(OlympicGamesHubAndMedalTableScreen), findsOneWidget);
      final screen = tester.widget<OlympicGamesHubAndMedalTableScreen>(
        find.byType(OlympicGamesHubAndMedalTableScreen),
      );
      expect(screen.playerNationalityIso, 'BEL');
    });

    testWidgets('navigates to InGameDatabaseRosterEditorScreen via named route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      router.goNamed(AppRouteNames.databaseEditor);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(InGameDatabaseRosterEditorScreen), findsOneWidget);
    });

    testWidgets('navigates to AchievementsAndPlatinumTrophyScreen with section query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.achievements}?section=platinum',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(AchievementsAndPlatinumTrophyScreen), findsOneWidget);
      final screen = tester.widget<AchievementsAndPlatinumTrophyScreen>(
        find.byType(AchievementsAndPlatinumTrophyScreen),
      );
      expect(
        screen.initialSection,
        AchievementsScreenSection.platinumShowcase,
      );
    });

    testWidgets('navigates to PreStagePaddockAndWarmupScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToPreStagePaddock(
        teamName: 'Bora Test Squad',
        teamShortCode: 'BTS',
        autoPlay3d: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PreStagePaddockAndWarmupScreen), findsOneWidget);
      final screen = tester.widget<PreStagePaddockAndWarmupScreen>(
        find.byType(PreStagePaddockAndWarmupScreen),
      );
      expect(screen.teamName, 'Bora Test Squad');
      expect(screen.teamShortCode, 'BTS');
      expect(screen.autoPlay3d, isFalse);
    });

    testWidgets('navigates to CompanionCarDashboardScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToCompanionCar(enableLiveTicker: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CompanionCarDashboardScreen), findsOneWidget);
      final screen = tester.widget<CompanionCarDashboardScreen>(
        find.byType(CompanionCarDashboardScreen),
      );
      expect(screen.enableLiveTicker, isFalse);
    });

    testWidgets('renders Paczka #5 routes cleanly on mobile 390x844 & tablet 1024x768',
        (tester) async {
      for (final size in const [Size(390, 844), Size(1024, 768)]) {
        final router = createAppRouter(
          initialLocation: AppRoutes.gravelWorldSeries,
        );
        await pumpRoute(tester, router: router, viewport: size);
        expect(find.byType(GravelWorldSeriesHubScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
