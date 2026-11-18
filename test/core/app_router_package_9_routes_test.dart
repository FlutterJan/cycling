import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/club_museum_and_legendary_bikes_screen.dart';
import 'package:pro_peloton_manager/ui/screens/deep_career_analytics_bi_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_shell_screen.dart';
import 'package:pro_peloton_manager/ui/screens/talent_combine_tryouts_screen.dart';
import 'package:pro_peloton_manager/ui/screens/uci_paracycling_world_cup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/weekly_training_microcycle_planner_screen.dart';

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

  group('AppRouter Paczka #9 Routes', () {
    testWidgets('navigates to UciParacyclingWorldCupScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToParacyclingWorldCup();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(UciParacyclingWorldCupScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to ClubMuseumAndLegendaryBikesScreen via exhibitId query',
        (tester) async {
      final router = createAppRouter(
        initialLocation: '${AppRoutes.clubMuseum}?exhibitId=exhibit_1',
      );
      await pumpRoute(tester, router: router);

      expect(find.byType(ClubMuseumAndLegendaryBikesScreen), findsOneWidget);
      final screen = tester.widget<ClubMuseumAndLegendaryBikesScreen>(
        find.byType(ClubMuseumAndLegendaryBikesScreen),
      );
      expect(screen.initialExhibitId, 'exhibit_1');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'navigates to WeeklyTrainingMicrocyclePlannerScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToWeeklyMicrocycle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.byType(WeeklyTrainingMicrocyclePlannerScreen),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to TalentCombineTryoutsScreen via named route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      router.goNamed(AppRouteNames.talentCombine);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(TalentCombineTryoutsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('navigates to DeepCareerAnalyticsBiScreen via extension',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.start);
      await pumpRoute(tester, router: router);

      final ctx = tester.element(find.byType(Scaffold).first);
      ctx.goToCareerAnalyticsBi();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(DeepCareerAnalyticsBiScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MainShellScreen Paczka #9 Integration', () {
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
            saveName: 'Test Shell Career Pack 9',
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

    test('MainShellPackage9Route has 5 unique routes', () {
      expect(MainShellPackage9Route.values.length, equals(5));
      final paths =
          MainShellPackage9Route.values.map((r) => r.routePath).toSet();
      expect(paths.length, equals(5));
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders Package 9 routes in MainShellScreen at $size',
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
            find.text('EKSPANSJA GLOBALNA & BI'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('EKSPANSJA GLOBALNA & BI'), findsOneWidget);
          expect(find.text('UCI Para-Cycling'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Analityka BI & ROI'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('Analityka BI & ROI'), findsOneWidget);
        } else {
          final scaffoldState = tester.state<ScaffoldState>(
            find.byType(Scaffold).first,
          );
          scaffoldState.openDrawer();
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          await tester.scrollUntilVisible(
            find.text('Analityka BI & ROI'),
            300.0,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.text('EKSPANSJA GLOBALNA & BI'), findsOneWidget);
          expect(find.text('UCI Para-Cycling'), findsOneWidget);
          expect(find.text('Analityka BI & ROI'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'tapping Package 9 item in MainShellScreen sidebar navigates to route',
        (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.dashboard);
      await pumpShellWithCareer(
        tester,
        router: router,
        viewport: const Size(1600, 900),
      );

      await tester.scrollUntilVisible(
        find.text('Analityka BI & ROI'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Analityka BI & ROI'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(DeepCareerAnalyticsBiScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
