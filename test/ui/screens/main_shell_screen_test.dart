import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/main_shell_screen.dart';

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
          saveName: 'Test Shell Career',
          playerManagerName: 'Dyrektor Sportowy',
          playerTeamId: 'wt_aethel_veloce',
        );
  });

  group('MainNavigationSection & MainNavigationTab', () {
    test('Wszystkie 4 sekcje i 20 zakładek są poprawnie skategoryzowane', () {
      expect(MainNavigationSection.values.length, equals(4));
      expect(MainNavigationTab.values.length, equals(20));

      final commandTabs = MainNavigationTab.values
          .where((t) => t.section == MainNavigationSection.commandCenter)
          .length;
      final teamTabs = MainNavigationTab.values
          .where((t) => t.section == MainNavigationSection.teamPerformance)
          .length;
      final equipTabs = MainNavigationTab.values
          .where((t) => t.section == MainNavigationSection.equipmentFinance)
          .length;
      final uciTabs = MainNavigationTab.values
          .where((t) => t.section == MainNavigationSection.uciWorld)
          .length;

      expect(commandTabs, equals(3));
      expect(teamTabs, equals(7));
      expect(equipTabs, equals(5));
      expect(uciTabs, equals(5));
    });

    test('Wszystkie nowe ścieżki AppRoutes są unikalne', () {
      final routes = MainNavigationTab.values.map((t) => t.routePath).toList();
      expect(routes.toSet().length, equals(routes.length));
    });
  });

  group('MainShellScreen Responsywność (390x844, 1024x768, 1600x900)', () {
    Future<void> pumpShellAtSize(WidgetTester tester, Size size, {String? route}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      if (route != null) {
        final router = createAppRouter(initialLocation: route);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: testContainer,
            child: MaterialApp.router(
              theme: AppTheme.darkTheme,
              routerConfig: router,
            ),
          ),
        );
      } else {
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
      }
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    }

    testWidgets('Desktop 1600x900 renderuje Sidebar z 4 sekcjami i TopBar bez overflow',
        (tester) async {
      await pumpShellAtSize(tester, const Size(1600, 900));

      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(find.text('CENTRUM DOWODZENIA'), findsOneWidget);
      expect(find.text('ZESPÓŁ I WYDOLNOŚĆ'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ŚWIAT UCI'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SPRZĘT I FINANSE'), findsOneWidget);
      expect(find.text('ŚWIAT UCI'), findsOneWidget);
      expect(find.text('NASTĘPNY DZIEŃ'), findsOneWidget);
    });

    testWidgets('Tablet 1024x768 renderuje powłokę bez overflow', (tester) async {
      await pumpShellAtSize(tester, const Size(1024, 768));

      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(find.text('NASTĘPNY DZIEŃ'), findsOneWidget);
    });

    testWidgets('Mobile 390x844 renderuje AppBar, BottomBar i przycisk akcji bez overflow',
        (tester) async {
      await pumpShellAtSize(tester, const Size(390, 844));

      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(find.text('HQ'), findsOneWidget);
      expect(find.text('Więcej'), findsOneWidget);
      expect(find.text('NASTĘPNY DZIEŃ'), findsOneWidget);
    });

    testWidgets('Nowe trasy GoRouter (inbox, uci-rankings, manager-profile) działają bez overflow',
        (tester) async {
      await pumpShellAtSize(tester, const Size(1600, 900), route: AppRoutes.inbox);
      expect(find.byType(CareerInboxView), findsOneWidget);

      await pumpShellAtSize(tester, const Size(1600, 900), route: AppRoutes.uciRankings);
      expect(find.byType(UciRankingsAndLicenseView), findsOneWidget);

      await pumpShellAtSize(tester, const Size(390, 844), route: AppRoutes.managerProfile);
      expect(find.byType(ManagerProfileAndAchievementsView), findsOneWidget);
    });
  });
}
