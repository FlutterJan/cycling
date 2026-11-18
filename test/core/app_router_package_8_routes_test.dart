import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/cycling_esports_and_virtual_academy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/esg_sustainability_and_fleet_screen.dart';
import 'package:pro_peloton_manager/ui/screens/golden_era_retro_campaigns_screen.dart';
import 'package:pro_peloton_manager/ui/screens/grand_tour_route_reveal_ceremony_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_shell_screen.dart';
import 'package:pro_peloton_manager/ui/screens/manager_legacy_hall_of_fame_book_screen.dart';
import 'package:pro_peloton_manager/ui/screens/national_team_selection_hq_screen.dart';

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

  group('AppRouter Paczki #8 Routes', () {
    testWidgets('navigates to GoldenEraRetroCampaignsScreen via year query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.goldenEraRetro}?year=1986',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(GoldenEraRetroCampaignsScreen), findsOneWidget);
      final screen = tester.widget<GoldenEraRetroCampaignsScreen>(
        find.byType(GoldenEraRetroCampaignsScreen),
      );
      expect(screen.initialYear, 1986);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to CyclingEsportsAndVirtualAcademyScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToCyclingEsports(autoAnimate3d: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byType(CyclingEsportsAndVirtualAcademyScreen),
        findsOneWidget,
      );
      final screen = tester.widget<CyclingEsportsAndVirtualAcademyScreen>(
        find.byType(CyclingEsportsAndVirtualAcademyScreen),
      );
      expect(screen.autoAnimate3d, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to EsgSustainabilityAndFleetScreen via tab query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.esgGreenFleet}?tab=carbon',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(EsgSustainabilityAndFleetScreen), findsOneWidget);
      final screen = tester.widget<EsgSustainabilityAndFleetScreen>(
        find.byType(EsgSustainabilityAndFleetScreen),
      );
      expect(screen.initialTab, EsgSustainabilityFleetTab.carbonLedger);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to NationalTeamSelectionHqScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToNationalTeamHq(
        initialTab: NationalTeamHqTab.tacticsAndChemistry,
        isReadOnly: true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(NationalTeamSelectionHqScreen), findsOneWidget);
      final screen = tester.widget<NationalTeamSelectionHqScreen>(
        find.byType(NationalTeamSelectionHqScreen),
      );
      expect(screen.initialTab, NationalTeamHqTab.tacticsAndChemistry);
      expect(screen.isReadOnly, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to GrandTourRouteRevealCeremonyScreen via named route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      router.goNamed(AppRouteNames.grandTourRouteReveal);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(GrandTourRouteRevealCeremonyScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to ManagerLegacyHallOfFameBookScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToManagerLegacyBook(initialEntryId: 'gen_1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(ManagerLegacyHallOfFameBookScreen), findsOneWidget);
      final screen = tester.widget<ManagerLegacyHallOfFameBookScreen>(
        find.byType(ManagerLegacyHallOfFameBookScreen),
      );
      expect(screen.initialEntryId, 'gen_1');
      expect(tester.takeException(), isNull);
    });
  });

  group('MainShellScreen Paczka #8 Integration', () {
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
            saveName: 'Test Shell Career Pack 8',
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

    test('MainShellPackage8Route has 6 unique routes', () {
      expect(MainShellPackage8Route.values.length, equals(6));
      final paths =
          MainShellPackage8Route.values.map((r) => r.routePath).toSet();
      expect(paths.length, equals(6));
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders Package 8 routes in MainShellScreen at $size',
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
            find.text('Złota Era 1970–2015'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('EKSPANSJE & TRYBY SPECJALNE'), findsOneWidget);
          expect(find.text('Złota Era 1970–2015'), findsOneWidget);
        } else {
          final scaffoldState = tester.state<ScaffoldState>(
            find.byType(Scaffold).first,
          );
          scaffoldState.openDrawer();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          await tester.scrollUntilVisible(
            find.text('Złota Era 1970–2015'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('EKSPANSJE & TRYBY SPECJALNE'), findsOneWidget);
          expect(find.text('Złota Era 1970–2015'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'tapping Package 8 item in MainShellScreen sidebar navigates to route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.dashboard);
      await pumpShellWithCareer(
        tester,
        router: router,
        viewport: const Size(1600, 900),
      );

      await tester.scrollUntilVisible(
        find.text('Flota EV & Ekonomia ESG'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Flota EV & Ekonomia ESG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(EsgSustainabilityAndFleetScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
