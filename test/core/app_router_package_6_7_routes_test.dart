import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/ui/screens/global_academy_network_map_screen.dart';
import 'package:pro_peloton_manager/ui/screens/in_house_bike_brand_factory_screen.dart';
import 'package:pro_peloton_manager/ui/screens/manager_profile_and_reputation_screen.dart';
import 'package:pro_peloton_manager/ui/screens/mtb_xco_world_cup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/multiplayer_leagues_and_challenges_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_organizer_hq_dashboard_screen.dart';
import 'package:pro_peloton_manager/ui/screens/track_omnium_madison_championship_screen.dart';
import 'package:pro_peloton_manager/ui/screens/ultra_bikepacking_transcontinental_screen.dart';

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

  group('AppRouter Paczki #6 i #7 Routes', () {
    testWidgets(
        'navigates to MultiplayerLeaguesAndChallengesScreen via tab query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.multiplayerLeagues}?tab=elo',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(MultiplayerLeaguesAndChallengesScreen), findsOneWidget);
      final screen = tester.widget<MultiplayerLeaguesAndChallengesScreen>(
        find.byType(MultiplayerLeaguesAndChallengesScreen),
      );
      expect(screen.initialTab, MultiplayerHubTab.eloRanking);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to MtbXcoWorldCupScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToMtbXcoWorldCup(isReadOnly: true, show3dPreview: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(MtbXcoWorldCupScreen), findsOneWidget);
      final screen = tester.widget<MtbXcoWorldCupScreen>(
        find.byType(MtbXcoWorldCupScreen),
      );
      expect(screen.isReadOnly, isTrue);
      expect(screen.show3dPreview, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to InHouseBikeBrandFactoryScreen via named route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      router.goNamed(AppRouteNames.bikeBrandFactory);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(InHouseBikeBrandFactoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to TrackOmniumMadisonChampionshipScreen via discipline query',
        (tester) async {
      final router = createAppRouter(
        initialLocation:
            '${AppRoutes.velodromeTrackChampionship}?discipline=madison&velodromeId=grenchen_tissot',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(TrackOmniumMadisonChampionshipScreen), findsOneWidget);
      final screen = tester.widget<TrackOmniumMadisonChampionshipScreen>(
        find.byType(TrackOmniumMadisonChampionshipScreen),
      );
      expect(screen.initialDiscipline, TrackChampionshipDiscipline.madison);
      expect(screen.initialVelodromeId, 'grenchen_tissot');
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to RaceOrganizerHqDashboardScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToRaceOrganizerHq(isReadOnly: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(RaceOrganizerHqDashboardScreen), findsOneWidget);
      final screen = tester.widget<RaceOrganizerHqDashboardScreen>(
        find.byType(RaceOrganizerHqDashboardScreen),
      );
      expect(screen.isReadOnly, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to UltraBikepackingTranscontinentalScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToUltraBikepacking(isReadOnly: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
          find.byType(UltraBikepackingTranscontinentalScreen), findsOneWidget);
      final screen = tester.widget<UltraBikepackingTranscontinentalScreen>(
        find.byType(UltraBikepackingTranscontinentalScreen),
      );
      expect(screen.isReadOnly, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to GlobalAcademyNetworkMapScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToGlobalAcademies();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GlobalAcademyNetworkMapScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to ManagerProfileAndReputationScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToManagerReputation(isReadOnly: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ManagerProfileAndReputationScreen), findsOneWidget);
      final screen = tester.widget<ManagerProfileAndReputationScreen>(
        find.byType(ManagerProfileAndReputationScreen),
      );
      expect(screen.isReadOnly, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders Paczki #6 & #7 routes cleanly on mobile 390x844 & tablet 1024x768',
        (tester) async {
      for (final size in const [Size(390, 844), Size(1024, 768)]) {
        final router = createAppRouter(
          initialLocation: AppRoutes.multiplayerLeagues,
        );
        await pumpRoute(tester, router: router, viewport: size);
        expect(
            find.byType(MultiplayerLeaguesAndChallengesScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
