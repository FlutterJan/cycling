import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/bike_garage_rnd_screen.dart';
import 'package:pro_peloton_manager/ui/screens/calendar_and_race_planner_screen.dart';
import 'package:pro_peloton_manager/ui/screens/dashboard_hq_screen.dart';
import 'package:pro_peloton_manager/ui/screens/game_start_screen.dart';
import 'package:pro_peloton_manager/ui/screens/new_career_setup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/physiology_lab_screen.dart';
import 'package:pro_peloton_manager/ui/screens/post_stage_podium_screen.dart';
import 'package:pro_peloton_manager/ui/screens/pre_race_briefing_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_simulation_screen.dart';
import 'package:pro_peloton_manager/ui/screens/rider_detail_screen.dart';
import 'package:pro_peloton_manager/ui/screens/settings_and_mod_screen.dart';
import 'package:pro_peloton_manager/ui/screens/sponsors_and_finance_screen.dart';
import 'package:pro_peloton_manager/ui/screens/squad_roster_screen.dart';
import 'package:pro_peloton_manager/ui/screens/team_builder_hierarchy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/training_and_camps_screen.dart';
import 'package:pro_peloton_manager/ui/screens/transfer_market_scouting_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer testContainer;

  setUpAll(() async {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });

    testContainer = ProviderContainer();
    await testContainer.read(careerProvider.notifier).startNewCareer(
      saveName: 'Test Router Career',
      playerManagerName: 'Dyrektor Sportowy',
      playerTeamId: 'wt_aethel_veloce',
    );
  });

  group('AppRoutes & AppRouteNames Constants', () {
    test('Wszystkie stałe ścieżek URL mają prawidłowe formaty', () {
      expect(AppRoutes.start, equals('/'));
      expect(AppRoutes.welcome, equals('/welcome'));
      expect(AppRoutes.newCareer, equals('/new-career'));

      expect(AppRoutes.career, equals('/career'));
      expect(AppRoutes.dashboard, equals('/career/dashboard'));
      expect(AppRoutes.roster, equals('/career/roster'));
      expect(AppRoutes.riderDetail, equals('/career/rider/:riderId'));
      expect(AppRoutes.teamBuilder, equals('/career/team-builder'));
      expect(AppRoutes.garage, equals('/career/garage'));
      expect(AppRoutes.sponsors, equals('/career/sponsors'));
      expect(AppRoutes.transfers, equals('/career/transfers'));
      expect(AppRoutes.calendar, equals('/career/calendar'));
      expect(AppRoutes.training, equals('/career/training'));
      expect(AppRoutes.physiologyLab, equals('/career/lab'));
      expect(AppRoutes.settings, equals('/career/settings'));

      expect(AppRoutes.raceBriefing, equals('/race/briefing'));
      expect(AppRoutes.raceLive, equals('/race/live'));
      expect(AppRoutes.racePodium, equals('/race/podium'));
    });

    test('riderDetailPath poprawnie generuje sparametryzowany URL', () {
      expect(
        AppRoutes.riderDetailPath('rider_jonas_001'),
        equals('/career/rider/rider_jonas_001'),
      );
      expect(
        AppRoutes.riderDetailPath('pl_kolarz_42'),
        equals('/career/rider/pl_kolarz_42'),
      );
    });

    test('Nazwy tras w AppRouteNames są unikalne i spójne', () {
      final names = [
        AppRouteNames.start,
        AppRouteNames.welcome,
        AppRouteNames.newCareer,
        AppRouteNames.career,
        AppRouteNames.dashboard,
        AppRouteNames.roster,
        AppRouteNames.riderDetail,
        AppRouteNames.teamBuilder,
        AppRouteNames.garage,
        AppRouteNames.sponsors,
        AppRouteNames.transfers,
        AppRouteNames.calendar,
        AppRouteNames.training,
        AppRouteNames.physiologyLab,
        AppRouteNames.settings,
        AppRouteNames.raceBriefing,
        AppRouteNames.raceLive,
        AppRouteNames.racePodium,
      ];

      final uniqueNames = names.toSet();
      expect(uniqueNames.length, equals(names.length));
    });
  });

  group('GoRouter Configuration & Route Resolution', () {
    testWidgets('Inicjalizacja na trasie startowej "/" renderuje GameStartScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.start);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GameStartScreen), findsOneWidget);
      expect(find.text('PRO PELOTON MANAGER'), findsOneWidget);
    });

    testWidgets('Trasa "/new-career" renderuje NewCareerSetupScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: '${AppRoutes.newCareer}?slot=2');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NewCareerSetupScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/roster" poprawnie otwiera SquadRosterScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.roster);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SquadRosterScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/team-builder" otwiera TeamBuilderHierarchyScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.teamBuilder);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TeamBuilderHierarchyScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/garage" otwiera BikeGarageRndScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.garage);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BikeGarageRndScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/sponsors" otwiera SponsorsAndFinanceScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.sponsors);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SponsorsAndFinanceScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/transfers" otwiera TransferMarketScoutingScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.transfers);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TransferMarketScoutingScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/calendar" otwiera CalendarAndRacePlannerScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.calendar);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CalendarAndRacePlannerScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/training" otwiera TrainingAndCampsScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.training);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TrainingAndCampsScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/lab" otwiera PhysiologyLabScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.physiologyLab);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PhysiologyLabScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/settings" otwiera SettingsAndModScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: '${AppRoutes.settings}?tab=1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SettingsAndModScreen), findsOneWidget);
    });

    testWidgets('Trasa "/career/rider/:riderId" przekazuje riderId do RiderDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: '/career/rider/rider_pogacar_01');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final riderDetailFinder = find.byType(RiderDetailScreen);
      expect(riderDetailFinder, findsOneWidget);
      final widget = tester.widget<RiderDetailScreen>(riderDetailFinder);
      expect(widget.riderId, equals('rider_pogacar_01'));
    });

    testWidgets('Trasa wyścigowa "/race/briefing" otwiera PreRaceBriefingScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.raceBriefing);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PreRaceBriefingScreen), findsOneWidget);
    });

    testWidgets('Trasa wyścigowa "/race/live" otwiera RaceSimulationScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.raceLive);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(RaceSimulationScreen), findsOneWidget);
    });

    testWidgets('Trasa wyścigowa "/race/podium" otwiera PostStagePodiumScreen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.racePodium);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PostStagePodiumScreen), findsOneWidget);
    });

    testWidgets('Nieprawidłowa trasa wyświetla ekran błędu 404', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: '/nieistniejaca/sciezka/404');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('404 - Nie znaleziono żądanej trasy'), findsOneWidget);
      expect(find.text('Wróć do Menu Głównego'), findsOneWidget);
    });

    testWidgets('Przekierowanie z "/career" do "/career/dashboard"', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.career);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Po przekierowaniu powinien być na dashboardzie
      expect(find.byType(DashboardHqScreen), findsOneWidget);
    });
  });

  group('BuildContext Navigation Extensions', () {
    testWidgets('Metody rozszerzeń BuildContext poprawnie zmieniają lokalizację routera', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final router = createAppRouter(initialLocation: AppRoutes.start);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: testContainer,
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final context = tester.element(find.byType(GameStartScreen));

      // Test goToNewCareer
      context.goToNewCareer(initialSlot: 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NewCareerSetupScreen), findsOneWidget);

      // Test goToGarage
      final newCareerContext = tester.element(find.byType(NewCareerSetupScreen));
      newCareerContext.goToGarage();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(BikeGarageRndScreen), findsOneWidget);

      // Test goToCalendar
      final garageContext = tester.element(find.byType(BikeGarageRndScreen));
      garageContext.goToCalendar();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CalendarAndRacePlannerScreen), findsOneWidget);
    });
  });
}
