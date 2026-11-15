import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/simulation/stage_results_calculator.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../ui/screens/bike_garage_rnd_screen.dart';
import '../../ui/screens/calendar_and_race_planner_screen.dart';
import '../../ui/screens/dashboard_hq_screen.dart';
import '../../ui/screens/game_start_screen.dart';
import '../../ui/screens/main_shell_screen.dart';
import '../../ui/screens/new_career_setup_screen.dart';
import '../../ui/screens/physiology_lab_screen.dart';
import '../../ui/screens/post_stage_podium_screen.dart';
import '../../ui/screens/pre_race_briefing_screen.dart';
import '../../ui/screens/race_simulation_screen.dart';
import '../../ui/screens/rider_detail_screen.dart';
import '../../ui/screens/settings_and_mod_screen.dart';
import '../../ui/screens/sponsors_and_finance_screen.dart';
import '../../ui/screens/squad_roster_screen.dart';
import '../../ui/screens/team_builder_hierarchy_screen.dart';
import '../../ui/screens/training_and_camps_screen.dart';
import '../../ui/screens/transfer_market_scouting_screen.dart';
import '../../ui/screens/wind_tunnel_and_bike_fit_screen.dart';
import '../theme/app_colors.dart';

/// Stałe ścieżek URL (Route Paths) w aplikacji Pro Peloton Manager
abstract class AppRoutes {
  /// Ekran startowy i wybór zapisu gry
  static const String start = '/';
  static const String welcome = '/welcome';

  /// Kreator nowej kariery (Własny zespół / WorldTour)
  static const String newCareer = '/new-career';

  /// Główna powłoka menedżera (MainShell)
  static const String career = '/career';
  static const String dashboard = '/career/dashboard';
  static const String roster = '/career/roster';
  static const String riderDetail = '/career/rider/:riderId';
  static const String teamBuilder = '/career/team-builder';
  static const String garage = '/career/garage';
  static const String sponsors = '/career/sponsors';
  static const String transfers = '/career/transfers';
  static const String calendar = '/career/calendar';
  static const String training = '/career/training';
  static const String physiologyLab = '/career/lab';
  static const String windTunnel = '/career/wind-tunnel';
  static const String settings = '/career/settings';

  /// Ścieżki wyścigowe (Race Routes)
  static const String raceBriefing = '/race/briefing';
  static const String raceLive = '/race/live';
  static const String racePodium = '/race/podium';

  /// Metoda pomocnicza do tworzenia ścieżki szczegółów kolarza
  static String riderDetailPath(String riderId) => '/career/rider/$riderId';
}

/// Nazwy tras (Route Names) dla nawigacji goNamed
abstract class AppRouteNames {
  static const String start = 'start';
  static const String welcome = 'welcome';
  static const String newCareer = 'newCareer';

  static const String career = 'career';
  static const String dashboard = 'dashboard';
  static const String roster = 'roster';
  static const String riderDetail = 'riderDetail';
  static const String teamBuilder = 'teamBuilder';
  static const String garage = 'garage';
  static const String sponsors = 'sponsors';
  static const String transfers = 'transfers';
  static const String calendar = 'calendar';
  static const String training = 'training';
  static const String physiologyLab = 'physiologyLab';
  static const String windTunnel = 'windTunnel';
  static const String settings = 'settings';

  static const String raceBriefing = 'raceBriefing';
  static const String raceLive = 'raceLive';
  static const String racePodium = 'racePodium';
}

/// Klucze globalne nawigatorów dla powłoki ShellRoute oraz nawigatora głównego
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'ppm_root_navigator');
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'ppm_shell_navigator');

/// Fabryka konfiguracji GoRouter gry
GoRouter createAppRouter({
  String initialLocation = AppRoutes.start,
  GlobalKey<NavigatorState>? rootNavKey,
  GlobalKey<NavigatorState>? shellNavKey,
  List<NavigatorObserver>? observers,
}) {
  final rootKey = rootNavKey ?? GlobalKey<NavigatorState>(debugLabel: 'ppm_root_nav');
  final shellKey = shellNavKey ?? GlobalKey<NavigatorState>(debugLabel: 'ppm_shell_nav');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    observers: observers,
    routes: [
      // 1. Ekran startowy i menu wyboru zapisu
      GoRoute(
        path: AppRoutes.start,
        name: AppRouteNames.start,
        builder: (context, state) => const GameStartScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: AppRouteNames.welcome,
        builder: (context, state) => const GameStartScreen(),
      ),

      // 2. Kreator nowej kariery (Własny zespół lub istniejąca stajnia)
      GoRoute(
        path: AppRoutes.newCareer,
        name: AppRouteNames.newCareer,
        builder: (context, state) {
          final slotStr = state.uri.queryParameters['slot'];
          final slotNum = slotStr != null ? int.tryParse(slotStr) ?? 1 : 1;
          return NewCareerSetupScreen(initialSlotNumber: slotNum);
        },
      ),

      // 3. Główna powłoka menedżera (MainShellScreen z ShellRoute)
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) {
          return MainShellScreen(
            currentLocation: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.career,
            name: AppRouteNames.career,
            redirect: (context, state) => AppRoutes.dashboard,
            builder: (context, state) => const DashboardHqScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            name: AppRouteNames.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardHqScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.roster,
            name: AppRouteNames.roster,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SquadRosterScreen(showAppBar: false),
            ),
          ),
          GoRoute(
            path: AppRoutes.riderDetail,
            name: AppRouteNames.riderDetail,
            pageBuilder: (context, state) {
              final riderId = state.pathParameters['riderId'] ?? '';
              final extra = state.extra;
              final initialRider = extra is Rider ? extra : null;
              return MaterialPage(
                child: RiderDetailScreen(
                  riderId: riderId,
                  initialRider: initialRider,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.teamBuilder,
            name: AppRouteNames.teamBuilder,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TeamBuilderHierarchyScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.garage,
            name: AppRouteNames.garage,
            pageBuilder: (context, state) {
              final extra = state.extra;
              final initialBike = extra is CompleteBike ? extra : null;
              return NoTransitionPage(
                child: BikeGarageRndScreen(initialBike: initialBike),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.sponsors,
            name: AppRouteNames.sponsors,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SponsorsAndFinanceScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transfers,
            name: AppRouteNames.transfers,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransferMarketScoutingScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            name: AppRouteNames.calendar,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarAndRacePlannerScreen(showAppBar: false),
            ),
          ),
          GoRoute(
            path: AppRoutes.training,
            name: AppRouteNames.training,
            pageBuilder: (context, state) {
              final riderId = state.uri.queryParameters['riderId'];
              return NoTransitionPage(
                child: TrainingAndCampsScreen(
                  showAppBar: false,
                  initialRiderId: riderId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.physiologyLab,
            name: AppRouteNames.physiologyLab,
            pageBuilder: (context, state) {
              final riderId = state.uri.queryParameters['riderId'];
              return NoTransitionPage(
                child: PhysiologyLabScreen(
                  showAppBar: false,
                  initialRiderId: riderId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.windTunnel,
            name: AppRouteNames.windTunnel,
            pageBuilder: (context, state) {
              final riderId = state.uri.queryParameters['riderId'];
              return NoTransitionPage(
                child: WindTunnelAndBikeFitScreen(
                  showAppBar: false,
                  initialRiderId: riderId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: AppRouteNames.settings,
            pageBuilder: (context, state) {
              final tabStr = state.uri.queryParameters['tab'];
              final tabIdx = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
              return NoTransitionPage(
                child: SettingsAndModScreen(initialTabIndex: tabIdx),
              );
            },
          ),
        ],
      ),

      // 4. Ścieżki wyścigowe (pełnoekranowe poza powłoką menedżera)
      GoRoute(
        path: AppRoutes.raceBriefing,
        name: AppRouteNames.raceBriefing,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final stage = extra?['stage'] as RaceStage?;
          final race = extra?['race'] as TourRace?;
          return PreRaceBriefingScreen(
            stage: stage,
            race: race,
            isStandalone: true,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.raceLive,
        name: AppRouteNames.raceLive,
        builder: (context, state) => const RaceSimulationScreen(),
      ),
      GoRoute(
        path: AppRoutes.racePodium,
        name: AppRouteNames.racePodium,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final report = extra?['report'] as StageSummaryReport?;
          final simState = extra?['simState'] as StageSimulationState?;
          return PostStagePodiumScreen(
            stageReport: report,
            simulationState: simState,
            onContinue: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dashboard);
              }
            },
          );
        },
      ),
    ],
    errorBuilder: (context, state) => _buildErrorScreen(context, state),
  );
}

/// Domyślna instancja routera
final GoRouter appRouter = createAppRouter();

/// Provider Riverpod dla konfiguracji routera
final appRouterProvider = Provider<GoRouter>((ref) {
  return appRouter;
});

/// Rozszerzenia ułatwiające typowaną nawigację w BuildContext
extension AppRouterNavigationExtensions on BuildContext {
  /// Nawigacja do ekranu startowego / wyboru zapisu
  void goToStart() => go(AppRoutes.start);

  /// Nawigacja do ekranu powitalnego
  void goToWelcome() => go(AppRoutes.welcome);

  /// Nawigacja do kreatora nowej kariery
  void goToNewCareer({int initialSlot = 1}) =>
      go('${AppRoutes.newCareer}?slot=$initialSlot');

  /// Nawigacja do pulpitu dowodzenia (Dashboard HQ)
  void goToDashboard() => go(AppRoutes.dashboard);

  /// Nawigacja do kadry i kolarzy
  void goToRoster() => go(AppRoutes.roster);

  /// Nawigacja do szczegółowego profilu kolarza
  void goToRider(String riderId, {Rider? initialRider}) =>
      go(AppRoutes.riderDetailPath(riderId), extra: initialRider);

  /// Nawigacja do hierarchii i budowy formacji
  void goToTeamBuilder() => go(AppRoutes.teamBuilder);

  /// Nawigacja do warsztatu i garażu rowerowego
  void goToGarage({CompleteBike? initialBike}) =>
      go(AppRoutes.garage, extra: initialBike);

  /// Nawigacja do finansów i sponsorów
  void goToSponsors() => go(AppRoutes.sponsors);

  /// Nawigacja do rynku transferowego i skautingu
  void goToTransfers() => go(AppRoutes.transfers);

  /// Nawigacja do kalendarza sezonu
  void goToCalendar() => go(AppRoutes.calendar);

  /// Nawigacja do centrum treningowego
  void goToTraining({String? riderId}) => go(
        riderId != null
            ? '${AppRoutes.training}?riderId=$riderId'
            : AppRoutes.training,
      );

  /// Nawigacja do laboratorium wydolnościowego (Lactate & Spiro Lab)
  void goToPhysiologyLab({String? riderId}) => go(
        riderId != null
            ? '${AppRoutes.physiologyLab}?riderId=$riderId'
            : AppRoutes.physiologyLab,
      );

  /// Nawigacja do ustawień i modowania
  void goToSettings({int tab = 0}) => go('${AppRoutes.settings}?tab=$tab');

  /// Nawigacja do taktycznej odprawy przedetapowej
  void goToRaceBriefing({RaceStage? stage, TourRace? race}) =>
      go(AppRoutes.raceBriefing, extra: {'stage': stage, 'race': race});

  /// Nawigacja do symulacji wyścigu 3D na żywo
  void goToRaceLive() => go(AppRoutes.raceLive);

  /// Nawigacja do podium i raportu po etapie
  void goToRacePodium({
    StageSummaryReport? report,
    StageSimulationState? simState,
  }) =>
      go(
        AppRoutes.racePodium,
        extra: {'report': report, 'simState': simState},
      );
}

/// Ekran obsługi błędu nieznalezienia trasy (404)
Widget _buildErrorScreen(BuildContext context, GoRouterState state) {
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      title: const Text('Błąd Nawigacji'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppColors.crimsonAlert,
            ),
            const SizedBox(height: 16),
            const Text(
              '404 - Nie znaleziono żądanej trasy',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trasa "${state.uri}" nie istnieje w konfiguracji gry.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.goToStart(),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Wróć do Menu Głównego'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
