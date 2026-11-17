import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/rendering3d/team_bus_paddock_3d_scene_renderer.dart';
import '../../engine/simulation/stage_replay_recorder.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/team_bus_and_warmup_protocol_model.dart';
import '../../services/career/olympic_games_quadrennial_cycle_service.dart';
import '../../services/network/dual_screen_telemetry_wall_server.dart';
import '../../ui/screens/achievements_and_platinum_trophy_screen.dart';
import '../../ui/screens/be_a_pro_character_creator_screen.dart';
import '../../ui/screens/be_a_pro_dashboard_and_apartment_screen.dart';
import '../../ui/screens/bike_garage_rnd_screen.dart';
import '../../ui/screens/calendar_and_race_planner_screen.dart';
import '../../ui/screens/companion_car_dashboard_screen.dart';
import '../../ui/screens/cyclocross_winter_series_screen.dart';
import '../../ui/screens/dashboard_hq_screen.dart';
import '../../ui/screens/development_academy_screen.dart';
import '../../ui/screens/game_start_screen.dart';
import '../../ui/screens/gravel_world_series_hub_screen.dart';
import '../../ui/screens/hall_of_fame_and_records_screen.dart';
import '../../ui/screens/in_game_database_roster_editor_screen.dart';
import '../../ui/screens/jersey_and_bike_livery_studio_screen.dart';
import '../../ui/screens/legends_card_album_and_packs_screen.dart';
import '../../ui/screens/main_shell_screen.dart';
import '../../ui/screens/main_title_menu_screen.dart';
import '../../ui/screens/manager_profile_and_achievements_screen.dart';
import '../../ui/screens/medical_and_recovery_center_screen.dart';
import '../../ui/screens/new_career_setup_screen.dart';
import '../../ui/screens/olympic_games_hub_and_medal_table_screen.dart';
import '../../ui/screens/physiology_lab_screen.dart';
import '../../ui/screens/post_stage_podium_screen.dart';
import '../../ui/screens/pre_race_briefing_screen.dart';
import '../../ui/screens/pre_season_team_presentation_screen.dart';
import '../../ui/screens/pre_stage_paddock_and_warmup_screen.dart';
import '../../ui/screens/quick_race_sandbox_screen.dart';
import '../../ui/screens/race_replay_director_theater_screen.dart';
import '../../ui/screens/race_simulation_screen.dart';
import '../../ui/screens/rider_detail_screen.dart';
import '../../ui/screens/settings_and_mod_screen.dart';
import '../../ui/screens/sponsors_and_finance_screen.dart';
import '../../ui/screens/squad_roster_screen.dart';
import '../../ui/screens/staff_management_screen.dart';
import '../../ui/screens/stage_editor_creator_screen.dart';
import '../../ui/screens/team_builder_hierarchy_screen.dart';
import '../../ui/screens/training_and_camps_screen.dart';
import '../../ui/screens/transfer_market_scouting_screen.dart';
import '../../ui/screens/uci_hour_record_attempt_screen.dart';
import '../../ui/screens/wind_tunnel_and_bike_fit_screen.dart';
import '../../ui/widgets/animated_screen_transition_router.dart';
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
  static const String inbox = '/career/inbox';
  static const String calendar = '/career/calendar';
  static const String roster = '/career/roster';
  static const String riderDetail = '/career/rider/:riderId';
  static const String teamBuilder = '/career/team-builder';
  static const String training = '/career/training';
  static const String physiologyLab = '/career/lab';
  static const String medical = '/career/medical';
  static const String academy = '/career/academy';
  static const String staff = '/career/staff';
  static const String garage = '/career/garage';
  static const String windTunnel = '/career/wind-tunnel';
  static const String sponsors = '/career/sponsors';
  static const String transfers = '/career/transfers';
  static const String liveryStudio = '/career/livery-studio';
  static const String uciRankings = '/career/uci-rankings';
  static const String hallOfFame = '/career/hall-of-fame';
  static const String managerProfile = '/career/manager-profile';
  static const String stageEditor = '/career/stage-editor';
  static const String preSeasonPresentation = '/career/pre-season-gala';
  static const String cyclocross = '/career/cyclocross';
  static const String gravelWorldSeries = '/career/gravel';
  static const String olympicGames = '/career/olympics';
  static const String databaseEditor = '/career/database-editor';
  static const String achievements = '/career/achievements';
  static const String legendsAlbum = '/career/legends-album';
  static const String settings = '/career/settings';

  /// Tryb Be a Pro ("Zostań Legendą")
  static const String beAProCreator = '/be-a-pro/creator';
  static const String beAProDashboard = '/be-a-pro/dashboard';

  /// Ścieżki wyścigowe, Welodrom i Kino Powtórek (Race & Special Routes)
  static const String quickRaceSandbox = '/quick-race-sandbox';
  static const String raceBriefing = '/race/briefing';
  static const String preStagePaddock = '/race/paddock';
  static const String companionCar = '/race/companion-car';
  static const String raceLive = '/race/live';
  static const String racePodium = '/race/podium';
  static const String replayTheater = '/race/replay-theater';
  static const String velodromeHourRecord = '/velodrome/hour-record';

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
  static const String inbox = 'inbox';
  static const String calendar = 'calendar';
  static const String roster = 'roster';
  static const String riderDetail = 'riderDetail';
  static const String teamBuilder = 'teamBuilder';
  static const String training = 'training';
  static const String physiologyLab = 'physiologyLab';
  static const String medical = 'medical';
  static const String academy = 'academy';
  static const String staff = 'staff';
  static const String garage = 'garage';
  static const String windTunnel = 'windTunnel';
  static const String sponsors = 'sponsors';
  static const String transfers = 'transfers';
  static const String liveryStudio = 'liveryStudio';
  static const String uciRankings = 'uciRankings';
  static const String hallOfFame = 'hallOfFame';
  static const String managerProfile = 'managerProfile';
  static const String stageEditor = 'stageEditor';
  static const String preSeasonPresentation = 'preSeasonPresentation';
  static const String cyclocross = 'cyclocross';
  static const String gravelWorldSeries = 'gravelWorldSeries';
  static const String olympicGames = 'olympicGames';
  static const String databaseEditor = 'databaseEditor';
  static const String achievements = 'achievements';
  static const String legendsAlbum = 'legendsAlbum';
  static const String settings = 'settings';

  static const String beAProCreator = 'beAProCreator';
  static const String beAProDashboard = 'beAProDashboard';

  static const String quickRaceSandbox = 'quickRaceSandbox';
  static const String raceBriefing = 'raceBriefing';
  static const String preStagePaddock = 'preStagePaddock';
  static const String companionCar = 'companionCar';
  static const String raceLive = 'raceLive';
  static const String racePodium = 'racePodium';
  static const String replayTheater = 'replayTheater';
  static const String velodromeHourRecord = 'velodromeHourRecord';
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
      // 1. Ekran tytułowy AAA i menu wyboru zapisu
      GoRoute(
        path: AppRoutes.start,
        name: AppRouteNames.start,
        builder: (context, state) => const MainTitleMenuScreen(),
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
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const DashboardHqScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.inbox,
            name: AppRouteNames.inbox,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const CareerInboxView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            name: AppRouteNames.calendar,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const CalendarAndRacePlannerScreen(showAppBar: false),
            ),
          ),
          GoRoute(
            path: AppRoutes.roster,
            name: AppRouteNames.roster,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const SquadRosterScreen(showAppBar: false),
            ),
          ),
          GoRoute(
            path: AppRoutes.riderDetail,
            name: AppRouteNames.riderDetail,
            pageBuilder: (context, state) {
              final riderId = state.pathParameters['riderId'] ?? '';
              final extra = state.extra;
              final initialRider = extra is Rider ? extra : null;
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
                axis: SharedAxisDirection.vertical,
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
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const TeamBuilderHierarchyScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.training,
            name: AppRouteNames.training,
            pageBuilder: (context, state) {
              final riderId = state.uri.queryParameters['riderId'];
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
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
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
                child: PhysiologyLabScreen(
                  showAppBar: false,
                  initialRiderId: riderId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.medical,
            name: AppRouteNames.medical,
            pageBuilder: (context, state) {
              final riderId = state.uri.queryParameters['riderId'];
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
                child: MedicalAndRecoveryCenterScreen(
                  showAppBar: false,
                  initialRiderId: riderId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.academy,
            name: AppRouteNames.academy,
            pageBuilder: (context, state) {
              final riderId = state.uri.queryParameters['riderId'];
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
                child: DevelopmentAcademyScreen(
                  showAppBar: false,
                  initialRiderId: riderId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.staff,
            name: AppRouteNames.staff,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const StaffManagementScreen(showAppBar: false),
            ),
          ),
          GoRoute(
            path: AppRoutes.garage,
            name: AppRouteNames.garage,
            pageBuilder: (context, state) {
              final extra = state.extra;
              final initialBike = extra is CompleteBike ? extra : null;
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
                child: BikeGarageRndScreen(initialBike: initialBike),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.windTunnel,
            name: AppRouteNames.windTunnel,
            pageBuilder: (context, state) {
              final riderId = state.uri.queryParameters['riderId'];
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
                child: WindTunnelAndBikeFitScreen(
                  showAppBar: false,
                  initialRiderId: riderId,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.sponsors,
            name: AppRouteNames.sponsors,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const SponsorsAndFinanceScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transfers,
            name: AppRouteNames.transfers,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const TransferMarketScoutingScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.liveryStudio,
            name: AppRouteNames.liveryStudio,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const JerseyAndBikeLiveryStudioScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.uciRankings,
            name: AppRouteNames.uciRankings,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const UciRankingsAndLicenseView(),
            ),
          ),
          GoRoute(
            path: AppRoutes.hallOfFame,
            name: AppRouteNames.hallOfFame,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const HallOfFameAndRecordsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.managerProfile,
            name: AppRouteNames.managerProfile,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const ManagerProfileAndAchievementsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.stageEditor,
            name: AppRouteNames.stageEditor,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              child: const StageEditorCreatorScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.preSeasonPresentation,
            name: AppRouteNames.preSeasonPresentation,
            pageBuilder: (context, state) =>
                AnimatedScreenTransitionRouter.buildManagerPage(
              state: state,
              axis: SharedAxisDirection.scaled,
              child: const PreSeasonTeamPresentationScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: AppRouteNames.settings,
            pageBuilder: (context, state) {
              final tabStr = state.uri.queryParameters['tab'];
              final tabIdx = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
              return AnimatedScreenTransitionRouter.buildManagerPage(
                state: state,
                child: SettingsAndModScreen(initialTabIndex: tabIdx),
              );
            },
          ),
        ],
      ),

      // 4. Tryb Be a Pro ("Zostań Legendą") oraz tryby specjalne (CX, Album Kart)
      GoRoute(
        path: AppRoutes.cyclocross,
        name: AppRouteNames.cyclocross,
        pageBuilder: (context, state) {
          final extra = state.extra;
          List<Rider>? initialRoster;
          if (extra is List<Rider>) {
            initialRoster = extra;
          } else if (extra is Map<String, dynamic>) {
            initialRoster = extra['initialRoster'] as List<Rider>?;
          }
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: CyclocrossWinterSeriesScreen(
              initialRoster: initialRoster,
              onLaunch3dCourse: (_) => context.go(AppRoutes.raceLive),
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.gravelWorldSeries,
        name: AppRouteNames.gravelWorldSeries,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialRaceId = state.uri.queryParameters['raceId'] ??
              extraMap?['raceId'] as String?;
          final tireMmQuery =
              double.tryParse(state.uri.queryParameters['tireMm'] ?? '');
          final initialTireWidthMm = (tireMmQuery ??
                  (extraMap?['tireWidthMm'] as num?)?.toDouble() ??
                  42.0)
              .clamp(40.0, 50.0);
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: GravelWorldSeriesHubScreen(
              initialRaceId: initialRaceId,
              initialTireWidthMm: initialTireWidthMm,
              isReadOnly: isReadOnly,
              onLaunchRace: (race, setup, oasisPlan) => context.go(
                AppRoutes.raceLive,
                extra: {
                  'stageLabel': race.raceModel.name,
                  'subtitle':
                      '${race.locationLabel} • ${race.raceModel.totalDistanceKm.toStringAsFixed(0)} km Gravel',
                },
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.olympicGames,
        name: AppRouteNames.olympicGames,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialState = extra is OlympicGamesQuadrennialCycleState
              ? extra
              : extraMap?['initialState'] as OlympicGamesQuadrennialCycleState?;
          final initialReports =
              extraMap?['initialReports'] as List<OlympicRaceSimulationReport>?;
          final nationParam = state.uri.queryParameters['nation'];
          final playerNationalityIso = (nationParam != null &&
                  nationParam.trim().isNotEmpty)
              ? nationParam.trim().toUpperCase()
              : (extraMap?['playerNationalityIso'] as String? ?? 'POL');
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: OlympicGamesHubAndMedalTableScreen(
              initialState: initialState,
              initialReports: initialReports,
              playerNationalityIso: playerNationalityIso,
              isReadOnly: isReadOnly,
              onLaunchRace3d: (edition) => context.go(
                AppRoutes.raceLive,
                extra: {
                  'stageLabel': 'Igrzyska Olimpijskie ${edition.year}',
                  'subtitle': edition.hostCity,
                },
              ),
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.databaseEditor,
        name: AppRouteNames.databaseEditor,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialTeams = extraMap?['teams'] as List<CyclingTeam>?;
          final initialRiders = extraMap?['riders'] as List<Rider>?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: InGameDatabaseRosterEditorScreen(
              initialTeams: initialTeams,
              initialRiders: initialRiders,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.settings);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.achievements,
        name: AppRouteNames.achievements,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final readOnly = extraMap?['readOnly'] as bool? ?? false;
          final sectionParam = state.uri.queryParameters['section'];
          final initialSection = extraMap?['initialSection']
                  as AchievementsScreenSection? ??
              switch (sectionParam) {
                'platinum' => AchievementsScreenSection.platinumShowcase,
                'history' => AchievementsScreenSection.unlockHistory,
                _ => AchievementsScreenSection.allAchievements,
              };
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: AchievementsAndPlatinumTrophyScreen(
              readOnly: readOnly,
              initialSection: initialSection,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.managerProfile);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.legendsAlbum,
        name: AppRouteNames.legendsAlbum,
        pageBuilder: (context, state) {
          final extra = state.extra;
          LegendsCardAlbumState? initialState;
          if (extra is LegendsCardAlbumState) {
            initialState = extra;
          } else if (extra is Map<String, dynamic>) {
            initialState = extra['initialState'] as LegendsCardAlbumState?;
          }
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: LegendsCardAlbumAndPacksScreen(
              initialState: initialState,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.beAProCreator,
        name: AppRouteNames.beAProCreator,
        pageBuilder: (context, state) =>
            AnimatedScreenTransitionRouter.buildManagerPage(
          state: state,
          axis: SharedAxisDirection.scaled,
          child: BeAProCharacterCreatorScreen(
            onCareerCreated: (result) => context.go(
              AppRoutes.beAProDashboard,
              extra: result.careerState,
            ),
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.start);
              }
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.beAProDashboard,
        name: AppRouteNames.beAProDashboard,
        pageBuilder: (context, state) {
          final extra = state.extra;
          ProCyclistCareerState? initialState;
          if (extra is ProCyclistCareerState) {
            initialState = extra;
          } else if (extra is Map<String, dynamic>) {
            initialState = extra['careerState'] as ProCyclistCareerState?;
          }
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: BeAProDashboardAndApartmentScreen(
              initialState: initialState,
              onOpenRaceCalendar: () => context.go(AppRoutes.calendar),
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.start);
                }
              },
            ),
          );
        },
      ),

      // 5. Ścieżki wyścigowe, Welodrom i Kino Powtórek (pełnoekranowe poza powłoką menedżera)
      GoRoute(
        path: AppRoutes.quickRaceSandbox,
        name: AppRouteNames.quickRaceSandbox,
        builder: (context, state) => const QuickRaceSandboxScreen(),
      ),
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
        path: AppRoutes.preStagePaddock,
        name: AppRouteNames.preStagePaddock,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialModel = extra is TeamBusAndWarmupProtocolModel
              ? extra
              : extraMap?['model'] as TeamBusAndWarmupProtocolModel?;
          final initialWeatherPreset = extraMap?['weatherPreset']
                  as PaddockWeatherPreset? ??
              PaddockWeatherPreset.hotGrandTour;
          final teamName =
              extraMap?['teamName'] as String? ?? 'Veloce Pro Cycling';
          final teamShortCode =
              extraMap?['teamShortCode'] as String? ?? 'VPC';
          final primaryTeamColor =
              extraMap?['primaryTeamColor'] as Color? ?? AppColors.primaryAccent;
          final autoPlay3d = extraMap?['autoPlay3d'] as bool? ?? true;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: PreStagePaddockAndWarmupScreen(
              initialModel: initialModel,
              initialWeatherPreset: initialWeatherPreset,
              teamName: teamName,
              teamShortCode: teamShortCode,
              primaryTeamColor: primaryTeamColor,
              autoPlay3d: autoPlay3d,
              isReadOnly: isReadOnly,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.raceBriefing);
                }
              },
              onProceedToStart: (_) => context.go(AppRoutes.raceLive),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.companionCar,
        name: AppRouteNames.companionCar,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialFrame = extra is TelemetryWallFrame
              ? extra
              : extraMap?['initialFrame'] as TelemetryWallFrame?;
          final enableLiveTicker =
              extraMap?['enableLiveTicker'] as bool? ?? true;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: CompanionCarDashboardScreen(
              initialFrame: initialFrame,
              enableLiveTicker: enableLiveTicker,
              onBackPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.raceLive,
        name: AppRouteNames.raceLive,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialCameraMode =
              extra?['initialCameraMode'] as RaceCameraMode? ??
                  RaceCameraMode.profile2D;
          final stageLabel = extra?['stageLabel'] as String?;
          final subtitle = extra?['subtitle'] as String?;
          return AnimatedScreenTransitionRouter.buildRaceDivePage(
            state: state,
            stageLabel: stageLabel,
            subtitle: subtitle,
            child: RaceSimulationScreen(initialCameraMode: initialCameraMode),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.racePodium,
        name: AppRouteNames.racePodium,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final report = extra?['report'] as StageSummaryReport?;
          final simState = extra?['simState'] as StageSimulationState?;
          return AnimatedScreenTransitionRouter.buildPodiumRevealPage(
            state: state,
            child: PostStagePodiumScreen(
              stageReport: report,
              simulationState: simState,
              onContinue: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.replayTheater,
        name: AppRouteNames.replayTheater,
        pageBuilder: (context, state) {
          final extra = state.extra;
          StageReplayRecorder? recorder;
          ReplayClip? initialClip;
          String? initialFocusedRiderId = state.uri.queryParameters['riderId'];
          if (extra is StageReplayRecorder) {
            recorder = extra;
          } else if (extra is ReplayClip) {
            initialClip = extra;
          } else if (extra is Map<String, dynamic>) {
            recorder = extra['recorder'] as StageReplayRecorder?;
            initialClip = extra['initialClip'] as ReplayClip?;
            initialFocusedRiderId ??= extra['focusedRiderId'] as String?;
          }
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: RaceReplayDirectorTheaterScreen(
              recorder: recorder,
              initialClip: initialClip,
              initialFocusedRiderId: initialFocusedRiderId,
              onClose: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.velodromeHourRecord,
        name: AppRouteNames.velodromeHourRecord,
        pageBuilder: (context, state) {
          final extra = state.extra;
          Rider? initialRider;
          String initialVelodromeId =
              state.uri.queryParameters['velodromeId'] ??
                  'aguascalientes_bicentenario';
          if (extra is Rider) {
            initialRider = extra;
          } else if (extra is Map<String, dynamic>) {
            initialRider = extra['rider'] as Rider?;
            final velId = extra['velodromeId'] as String?;
            if (velId != null && velId.isNotEmpty) {
              initialVelodromeId = velId;
            }
          }
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: UciHourRecordAttemptScreen(
              initialRider: initialRider,
              initialVelodromeId: initialVelodromeId,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
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

  /// Nawigacja do skrzynki odbiorczej (Inbox)
  void goToInbox() => go(AppRoutes.inbox);

  /// Nawigacja do kadry i kolarzy
  void goToRoster() => go(AppRoutes.roster);

  /// Nawigacja do szczegółowego profilu kolarza
  void goToRider(String riderId, {Rider? initialRider}) =>
      go(AppRoutes.riderDetailPath(riderId), extra: initialRider);

  /// Nawigacja do hierarchii i budowy formacji
  void goToTeamBuilder() => go(AppRoutes.teamBuilder);

  /// Nawigacja do centrum medycznego i regeneracji
  void goToMedical({String? riderId}) => go(
        riderId != null
            ? '${AppRoutes.medical}?riderId=$riderId'
            : AppRoutes.medical,
      );

  /// Nawigacja do akademii młodzieżowej U23
  void goToAcademy({String? riderId}) => go(
        riderId != null
            ? '${AppRoutes.academy}?riderId=$riderId'
            : AppRoutes.academy,
      );

  /// Nawigacja do zarządzania sztabem szkoleniowym
  void goToStaff() => go(AppRoutes.staff);

  /// Nawigacja do warsztatu i garażu rowerowego
  void goToGarage({CompleteBike? initialBike}) =>
      go(AppRoutes.garage, extra: initialBike);

  /// Nawigacja do tunelu aerodynamicznego i bike fittingu
  void goToWindTunnel({String? riderId}) => go(
        riderId != null
            ? '${AppRoutes.windTunnel}?riderId=$riderId'
            : AppRoutes.windTunnel,
      );

  /// Nawigacja do finansów i sponsorów
  void goToSponsors() => go(AppRoutes.sponsors);

  /// Nawigacja do rynku transferowego i skautingu
  void goToTransfers() => go(AppRoutes.transfers);

  /// Nawigacja do studia malowania rowerów i koszulek
  void goToLiveryStudio() => go(AppRoutes.liveryStudio);

  /// Nawigacja do rankingów UCI i walki o licencję
  void goToUciRankings() => go(AppRoutes.uciRankings);

  /// Nawigacja do gabloty trofeów i rekordów górskich
  void goToHallOfFame() => go(AppRoutes.hallOfFame);

  /// Nawigacja do profilu menedżera i osiągnięć
  void goToManagerProfile() => go(AppRoutes.managerProfile);

  /// Nawigacja do kreatora tras i etapów
  void goToStageEditor() => go(AppRoutes.stageEditor);

  /// Nawigacja do Gali Prezentacji Zespołu przed sezonem
  void goToPreSeasonPresentation() => go(AppRoutes.preSeasonPresentation);

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

  /// Nawigacja do Laboratorium Taktycznego Sandbox (Szybki Wyścig 3D)
  void goToQuickRaceSandbox() => go(AppRoutes.quickRaceSandbox);

  /// Nawigacja do taktycznej odprawy przedetapowej
  void goToRaceBriefing({RaceStage? stage, TourRace? race}) =>
      go(AppRoutes.raceBriefing, extra: {'stage': stage, 'race': race});

  /// Nawigacja do symulacji wyścigu 3D na żywo
  void goToRaceLive({RaceCameraMode initialCameraMode = RaceCameraMode.profile2D}) =>
      go(AppRoutes.raceLive, extra: {'initialCameraMode': initialCameraMode});

  /// Nawigacja do podium i raportu po etapie
  void goToRacePodium({
    StageSummaryReport? report,
    StageSimulationState? simState,
  }) =>
      go(
        AppRoutes.racePodium,
        extra: {'report': report, 'simState': simState},
      );

  /// Nawigacja do kreatora postaci w trybie Be a Pro ("Zostań Legendą")
  void goToBeAProCreator() => go(AppRoutes.beAProCreator);

  /// Nawigacja do apartamentu i pulpitu kariery Be a Pro
  void goToBeAProDashboard({ProCyclistCareerState? careerState}) =>
      go(AppRoutes.beAProDashboard, extra: careerState);

  /// Nawigacja do Zimowego Pucharu Przełajowego CX
  void goToCyclocross({List<Rider>? initialRoster}) =>
      go(AppRoutes.cyclocross, extra: initialRoster);

  /// Nawigacja do centrum UCI Gravel World Series & Ultra-Gravel
  void goToGravelWorldSeries({
    String? raceId,
    double tireWidthMm = 42.0,
    bool isReadOnly = false,
  }) =>
      go(
        raceId != null
            ? '${AppRoutes.gravelWorldSeries}?raceId=$raceId&tireMm=${tireWidthMm.toStringAsFixed(1)}'
            : AppRoutes.gravelWorldSeries,
        extra: {
          'raceId': raceId,
          'tireWidthMm': tireWidthMm,
          'isReadOnly': isReadOnly,
        },
      );

  /// Nawigacja do centrum Igrzysk Olimpijskich i tabeli medalowej
  void goToOlympicGames({
    OlympicGamesQuadrennialCycleState? initialState,
    List<OlympicRaceSimulationReport>? initialReports,
    String playerNationalityIso = 'POL',
    bool isReadOnly = false,
  }) =>
      go(
        '${AppRoutes.olympicGames}?nation=$playerNationalityIso',
        extra: {
          'initialState': initialState,
          'initialReports': initialReports,
          'playerNationalityIso': playerNationalityIso,
          'isReadOnly': isReadOnly,
        },
      );

  /// Nawigacja do wbudowanego Edytora Bazy Danych i Składów
  void goToDatabaseEditor({
    List<CyclingTeam>? teams,
    List<Rider>? riders,
  }) =>
      go(
        AppRoutes.databaseEditor,
        extra: {
          'teams': teams,
          'riders': riders,
        },
      );

  /// Nawigacja do ekranu 60 Osiągnięć i Platynowego Trofeum
  void goToAchievements({
    AchievementsScreenSection initialSection =
        AchievementsScreenSection.allAchievements,
    bool readOnly = false,
  }) =>
      go(
        AppRoutes.achievements,
        extra: {
          'initialSection': initialSection,
          'readOnly': readOnly,
        },
      );

  /// Nawigacja do Paddocku Przedstartowego i Rozgrzewki 3D
  void goToPreStagePaddock({
    TeamBusAndWarmupProtocolModel? model,
    PaddockWeatherPreset weatherPreset = PaddockWeatherPreset.hotGrandTour,
    String teamName = 'Veloce Pro Cycling',
    String teamShortCode = 'VPC',
    Color primaryTeamColor = AppColors.primaryAccent,
    bool autoPlay3d = true,
    bool isReadOnly = false,
  }) =>
      go(
        AppRoutes.preStagePaddock,
        extra: {
          'model': model,
          'weatherPreset': weatherPreset,
          'teamName': teamName,
          'teamShortCode': teamShortCode,
          'primaryTeamColor': primaryTeamColor,
          'autoPlay3d': autoPlay3d,
          'isReadOnly': isReadOnly,
        },
      );

  /// Nawigacja do Konsoli Wozu Technicznego (Dual-Screen Telemetry Wall)
  void goToCompanionCar({
    TelemetryWallFrame? initialFrame,
    bool enableLiveTicker = true,
  }) =>
      go(
        AppRoutes.companionCar,
        extra: {
          'initialFrame': initialFrame,
          'enableLiveTicker': enableLiveTicker,
        },
      );

  /// Nawigacja do Welodromu (Próba Rekordu Godzinnego UCI)
  void goToVelodromeHourRecord({Rider? rider, String? velodromeId}) => go(
        velodromeId != null
            ? '${AppRoutes.velodromeHourRecord}?velodromeId=$velodromeId'
            : AppRoutes.velodromeHourRecord,
        extra: rider,
      );

  /// Nawigacja do Kina Powtórek Wyścigowych
  void goToReplayTheater({
    StageReplayRecorder? recorder,
    ReplayClip? initialClip,
    String? focusedRiderId,
  }) =>
      go(
        focusedRiderId != null
            ? '${AppRoutes.replayTheater}?riderId=$focusedRiderId'
            : AppRoutes.replayTheater,
        extra: {
          'recorder': recorder,
          'initialClip': initialClip,
          'focusedRiderId': focusedRiderId,
        },
      );

  /// Nawigacja do Albumu Kart Kolekcjonerskich i Paczek Gwiazd
  void goToLegendsAlbum({LegendsCardAlbumState? initialState}) =>
      go(AppRoutes.legendsAlbum, extra: initialState);
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
