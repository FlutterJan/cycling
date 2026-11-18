import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/club_museum_and_legendary_bikes_screen.dart';
import 'package:pro_peloton_manager/ui/screens/contract_renewals_war_room_screen.dart';
import 'package:pro_peloton_manager/ui/screens/grand_tour_morning_medical_briefing_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_shell_screen.dart';
import 'package:pro_peloton_manager/ui/screens/tv_broadcast_director_control_room_screen.dart';
import 'package:pro_peloton_manager/ui/screens/winter_wind_tunnel_camp_screen.dart';

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
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  group('AppRouter Paczka #10 Routes', () {
    testWidgets(
        'navigates to TvBroadcastDirectorControlRoomScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToTvBroadcastDirector(enableLiveTicker: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byType(TvBroadcastDirectorControlRoomScreen),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to GrandTourMorningMedicalBriefingScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToGrandTourMorningMedical();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byType(GrandTourMorningMedicalBriefingScreen),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to WinterWindTunnelCampScreen via seasonYear query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.winterWindTunnelCamp}?seasonYear=2028',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(WinterWindTunnelCampScreen), findsOneWidget);
      final screen = tester.widget<WinterWindTunnelCampScreen>(
        find.byType(WinterWindTunnelCampScreen),
      );
      expect(screen.seasonYear, 2028);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to ContractRenewalsWarRoomScreen via named route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      router.goNamed(AppRouteNames.contractRenewalsWarRoom);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(ContractRenewalsWarRoomScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to ClubMuseumAndLegendaryBikesScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToClubMuseum();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(ClubMuseumAndLegendaryBikesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MainShellScreen Paczka #10 Integration', () {
    late ProviderContainer testContainer;

    setUpAll(() async {
      const MethodChannel channel =
          MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return '.';
      });

      testContainer = ProviderContainer();
      await testContainer.read(careerProvider.notifier).startNewCareer(
            saveName: 'Test Shell Career Pack 10',
            playerManagerName: 'Dyrektor Sportowy',
            playerTeamId: 'wt_aethel_veloce',
          );
    });

    tearDownAll(() {
      testContainer.dispose();
    });

    Future<void> pumpShellWithCareer(
      WidgetTester tester, {
      required GoRouter router,
      Size viewport = const Size(1600, 900),
    }) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));
    }

    test('MainShellPackage10Route has 4 unique routes', () {
      expect(MainShellPackage10Route.values.length, equals(4));
      final paths =
          MainShellPackage10Route.values.map((r) => r.routePath).toSet();
      expect(paths.length, equals(4));
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders Package 10 routes in MainShellScreen at $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const MainShellScreen(
                currentLocation: AppRoutes.dashboard,
                child: Center(child: Text('Workspace OK')),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(MainShellScreen), findsOneWidget);
        if (size.width >= 768) {
          await tester.scrollUntilVisible(
            find.text('PRODUKCJA TV, MEDYCYNA & KONTRAKTY'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(
            find.text('PRODUKCJA TV, MEDYCYNA & KONTRAKTY'),
            findsOneWidget,
          );
          expect(find.text('Reżyserka TV Live'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Przedłużenia Kontraktów'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('Przedłużenia Kontraktów'), findsOneWidget);
        } else {
          final scaffoldState = tester.state<ScaffoldState>(
            find.byType(Scaffold).first,
          );
          scaffoldState.openDrawer();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          await tester.scrollUntilVisible(
            find.text('PRODUKCJA TV, MEDYCYNA & KONTRAKTY'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(
            find.text('PRODUKCJA TV, MEDYCYNA & KONTRAKTY'),
            findsOneWidget,
          );
          expect(find.text('Reżyserka TV Live'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Przedłużenia Kontraktów'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('Przedłużenia Kontraktów'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'tapping Package 10 item in MainShellScreen sidebar navigates to route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.dashboard);
      await pumpShellWithCareer(
        tester,
        router: router,
        viewport: const Size(1600, 900),
      );

      await tester.scrollUntilVisible(
        find.text('Przedłużenia Kontraktów'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Przedłużenia Kontraktów'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(ContractRenewalsWarRoomScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
