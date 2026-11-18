import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/rendering3d/team_bus_paddock_3d_scene_renderer.dart';
import '../../engine/simulation/stage_replay_recorder.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/career/career_save.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/career/team_esg_sustainability_and_green_fleet_model.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/esports/uci_cycling_esports_world_model.dart';
import '../../models/medical/grand_tour_nightly_hrv_and_physio_model.dart';
import '../../models/multiplayer/online_league_and_ghost_challenge_model.dart';
import '../../models/organizer/race_organizer_empire_model.dart';
import '../../models/paracycling/uci_paracycling_tandem_handbike_model.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/race/ultra_endurance_bikepacking_race_model.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/team_bus_and_warmup_protocol_model.dart';
import '../../services/career/olympic_games_quadrennial_cycle_service.dart';
import '../../services/career/pre_season_wind_tunnel_camp_event.dart';
import '../../services/medical/grand_tour_physiotherapy_triage_service.dart';
import '../../services/network/dual_screen_telemetry_wall_server.dart';
import '../../ui/screens/achievements_and_platinum_trophy_screen.dart';
import '../../ui/screens/be_a_pro_character_creator_screen.dart';
import '../../ui/screens/be_a_pro_dashboard_and_apartment_screen.dart';
import '../../ui/screens/bike_garage_rnd_screen.dart';
import '../../ui/screens/calendar_and_race_planner_screen.dart';
import '../../ui/screens/club_museum_and_legendary_bikes_screen.dart';
import '../../ui/screens/companion_car_dashboard_screen.dart';
import '../../ui/screens/contract_renewals_war_room_screen.dart';
import '../../ui/screens/cyclocross_winter_series_screen.dart';
import '../../ui/screens/cycling_esports_and_virtual_academy_screen.dart';
import '../../ui/screens/dashboard_hq_screen.dart';
import '../../ui/screens/deep_career_analytics_bi_screen.dart';
import '../../ui/screens/development_academy_screen.dart';
import '../../ui/screens/esg_sustainability_and_fleet_screen.dart';
import '../../ui/screens/game_start_screen.dart';
import '../../ui/screens/global_academy_network_map_screen.dart';
import '../../ui/screens/golden_era_retro_campaigns_screen.dart';
import '../../ui/screens/grand_tour_morning_medical_briefing_screen.dart';
import '../../ui/screens/grand_tour_route_reveal_ceremony_screen.dart';
import '../../ui/screens/gravel_world_series_hub_screen.dart';
import '../../ui/screens/hall_of_fame_and_records_screen.dart';
import '../../ui/screens/in_game_database_roster_editor_screen.dart';
import '../../ui/screens/in_house_bike_brand_factory_screen.dart';
import '../../ui/screens/jersey_and_bike_livery_studio_screen.dart';
import '../../ui/screens/legends_card_album_and_packs_screen.dart';
import '../../ui/screens/main_shell_screen.dart';
import '../../ui/screens/main_title_menu_screen.dart';
import '../../ui/screens/manager_legacy_hall_of_fame_book_screen.dart';
import '../../ui/screens/manager_profile_and_achievements_screen.dart';
import '../../ui/screens/manager_profile_and_reputation_screen.dart';
import '../../ui/screens/medical_and_recovery_center_screen.dart';
import '../../ui/screens/mtb_xco_world_cup_screen.dart';
import '../../ui/screens/multiplayer_leagues_and_challenges_screen.dart';
import '../../ui/screens/national_team_selection_hq_screen.dart';
import '../../ui/screens/new_career_setup_screen.dart';
import '../../ui/screens/olympic_games_hub_and_medal_table_screen.dart';
import '../../ui/screens/physiology_lab_screen.dart';
import '../../ui/screens/post_stage_podium_screen.dart';
import '../../ui/screens/pre_race_briefing_screen.dart';
import '../../ui/screens/pre_season_team_presentation_screen.dart';
import '../../ui/screens/pre_stage_paddock_and_warmup_screen.dart';
import '../../ui/screens/quick_race_sandbox_screen.dart';
import '../../ui/screens/race_organizer_hq_dashboard_screen.dart';
import '../../ui/screens/race_replay_director_theater_screen.dart';
import '../../ui/screens/race_simulation_screen.dart';
import '../../ui/screens/rider_detail_screen.dart';
import '../../ui/screens/settings_and_mod_screen.dart';
import '../../ui/screens/sponsors_and_finance_screen.dart';
import '../../ui/screens/squad_roster_screen.dart';
import '../../ui/screens/staff_management_screen.dart';
import '../../ui/screens/stage_editor_creator_screen.dart';
import '../../ui/screens/talent_combine_tryouts_screen.dart';
import '../../ui/screens/team_builder_hierarchy_screen.dart';
import '../../ui/screens/track_omnium_madison_championship_screen.dart';
import '../../ui/screens/training_and_camps_screen.dart';
import '../../ui/screens/transfer_market_scouting_screen.dart';
import '../../ui/screens/tv_broadcast_director_control_room_screen.dart';
import '../../ui/screens/uci_hour_record_attempt_screen.dart';
import '../../ui/screens/uci_paracycling_world_cup_screen.dart';
import '../../ui/screens/ultra_bikepacking_transcontinental_screen.dart';
import '../../ui/screens/weekly_training_microcycle_planner_screen.dart';
import '../../ui/screens/wind_tunnel_and_bike_fit_screen.dart';
import '../../ui/screens/winter_wind_tunnel_camp_screen.dart';
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
  static const String bikeBrandFactory = '/career/bike-brand-factory';
  static const String globalAcademies = '/career/global-academies';
  static const String managerReputation = '/career/manager-reputation';
  static const String mtbXcoWorldCup = '/career/mtb-xco';
  static const String settings = '/career/settings';

  /// Tryb Be a Pro ("Zostań Legendą")
  static const String beAProCreator = '/be-a-pro/creator';
  static const String beAProDashboard = '/be-a-pro/dashboard';

  /// Tryby Multiplayer & Organizator Wyścigów (Paczki #6 i #7)
  static const String multiplayerLeagues = '/multiplayer/leagues';
  static const String raceOrganizerHq = '/organizer/hq';

  /// Trasy Paczki #8 (Złota Era, UCI e-Sports, ESG, Reprezentacja, Prezentacja GT, Księga Legendy)
  static const String goldenEraRetro = '/career/golden-era';
  static const String cyclingEsports = '/career/esports';
  static const String esgGreenFleet = '/career/esg-fleet';
  static const String nationalTeamHq = '/career/national-team';
  static const String grandTourRouteReveal = '/career/grand-tour-reveal';
  static const String managerLegacyBook = '/career/legacy-book';

  /// Trasy Paczki #9 (UCI Para-Cycling, Muzeum Klubowe 3D, Mikrocykle Treningowe, Talent Combine, Analityka BI)
  static const String paracyclingWorldCup = '/career/paracycling';
  static const String clubMuseum = '/career/club-museum';
  static const String weeklyMicrocycle = '/career/weekly-microcycle';
  static const String talentCombine = '/career/talent-combine';
  static const String careerAnalyticsBi = '/career/analytics-bi';

  /// Trasy Paczki #10 (Reżyserka TV na Żywo, Poranny Raport Medyczny GT, Grudniowy Obóz Aero, Centrum Przedłużeń Kontraktów; Muzeum Klubowe: AppRoutes.clubMuseum)
  static const String tvBroadcastDirector = '/race/tv-director';
  static const String grandTourMorningMedical = '/career/grand-tour-medical';
  static const String winterWindTunnelCamp = '/career/winter-wind-tunnel-camp';
  static const String contractRenewalsWarRoom = '/career/contract-renewals';

  /// Ścieżki wyścigowe, Welodrom i Kino Powtórek (Race & Special Routes)
  static const String quickRaceSandbox = '/quick-race-sandbox';
  static const String raceBriefing = '/race/briefing';
  static const String preStagePaddock = '/race/paddock';
  static const String companionCar = '/race/companion-car';
  static const String raceLive = '/race/live';
  static const String racePodium = '/race/podium';
  static const String replayTheater = '/race/replay-theater';
  static const String ultraBikepacking = '/race/ultra-bikepacking';
  static const String velodromeHourRecord = '/velodrome/hour-record';
  static const String velodromeTrackChampionship = '/velodrome/track-championship';

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
  static const String bikeBrandFactory = 'bikeBrandFactory';
  static const String globalAcademies = 'globalAcademies';
  static const String managerReputation = 'managerReputation';
  static const String mtbXcoWorldCup = 'mtbXcoWorldCup';
  static const String settings = 'settings';

  static const String beAProCreator = 'beAProCreator';
  static const String beAProDashboard = 'beAProDashboard';

  static const String multiplayerLeagues = 'multiplayerLeagues';
  static const String raceOrganizerHq = 'raceOrganizerHq';

  static const String goldenEraRetro = 'goldenEraRetro';
  static const String cyclingEsports = 'cyclingEsports';
  static const String esgGreenFleet = 'esgGreenFleet';
  static const String nationalTeamHq = 'nationalTeamHq';
  static const String grandTourRouteReveal = 'grandTourRouteReveal';
  static const String managerLegacyBook = 'managerLegacyBook';

  static const String paracyclingWorldCup = 'paracyclingWorldCup';
  static const String clubMuseum = 'clubMuseum';
  static const String weeklyMicrocycle = 'weeklyMicrocycle';
  static const String talentCombine = 'talentCombine';
  static const String careerAnalyticsBi = 'careerAnalyticsBi';

  static const String tvBroadcastDirector = 'tvBroadcastDirector';
  static const String grandTourMorningMedical = 'grandTourMorningMedical';
  static const String winterWindTunnelCamp = 'winterWindTunnelCamp';
  static const String contractRenewalsWarRoom = 'contractRenewalsWarRoom';

  static const String quickRaceSandbox = 'quickRaceSandbox';
  static const String raceBriefing = 'raceBriefing';
  static const String preStagePaddock = 'preStagePaddock';
  static const String companionCar = 'companionCar';
  static const String raceLive = 'raceLive';
  static const String racePodium = 'racePodium';
  static const String replayTheater = 'replayTheater';
  static const String ultraBikepacking = 'ultraBikepacking';
  static const String velodromeHourRecord = 'velodromeHourRecord';
  static const String velodromeTrackChampionship = 'velodromeTrackChampionship';
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

      // 6. Trasy Paczek #6 i #7 (Multiplayer, MTB XCO, Własna Marka, Tor, Organizator, Ultra, Akademie, Reputacja)
      GoRoute(
        path: AppRoutes.multiplayerLeagues,
        name: AppRouteNames.multiplayerLeagues,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = extraMap?['initialTab'] as MultiplayerHubTab? ??
              switch (tabParam) {
                'challenges' => MultiplayerHubTab.weeklyChallenges,
                'draft' => MultiplayerHubTab.syncAndDraft,
                'elo' => MultiplayerHubTab.eloRanking,
                _ => MultiplayerHubTab.leagues,
              };
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: MultiplayerLeaguesAndChallengesScreen(
              initialLeagues:
                  extraMap?['initialLeagues'] as List<OnlineLeagueModel>?,
              initialChallenges:
                  extraMap?['initialChallenges'] as List<GhostChallengeModel>?,
              initialPlayerProfile:
                  extraMap?['initialPlayerProfile'] as EloRatingProfile?,
              initialTab: initialTab,
              isReadOnly: isReadOnly,
              onLaunchGhostRace: (challenge) => context.go(
                AppRoutes.raceLive,
                extra: {
                  'stageLabel': challenge.title,
                  'subtitle':
                      '${challenge.stageName} • ${challenge.distanceKm.toStringAsFixed(1)} km Ghost',
                },
              ),
              onLaunchLeagueStage: (league) => context.go(
                AppRoutes.raceLive,
                extra: {
                  'stageLabel': league.name,
                  'subtitle': 'Liga Online • ${league.format.name}',
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
        path: AppRoutes.mtbXcoWorldCup,
        name: AppRouteNames.mtbXcoWorldCup,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          final show3dPreview = extraMap?['show3dPreview'] as bool? ?? true;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: MtbXcoWorldCupScreen(
              isReadOnly: isReadOnly,
              show3dPreview: show3dPreview,
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
        path: AppRoutes.bikeBrandFactory,
        name: AppRouteNames.bikeBrandFactory,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialState = extra is InHouseBikeBrandFactoryState
              ? extra
              : extraMap?['initialState'] as InHouseBikeBrandFactoryState?;
          final showAppBar = extraMap?['showAppBar'] as bool? ?? true;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: InHouseBikeBrandFactoryScreen(
              initialState: initialState,
              showAppBar: showAppBar,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.velodromeTrackChampionship,
        name: AppRouteNames.velodromeTrackChampionship,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final discParam = state.uri.queryParameters['discipline'];
          final initialDiscipline =
              extraMap?['discipline'] as TrackChampionshipDiscipline? ??
                  switch (discParam) {
                    'madison' => TrackChampionshipDiscipline.madison,
                    'omnium' => TrackChampionshipDiscipline.omnium,
                    'points' => TrackChampionshipDiscipline.pointsRace,
                    _ => TrackChampionshipDiscipline.keirin,
                  };
          final velParam = state.uri.queryParameters['velodromeId'];
          final initialVelodromeId = (velParam != null && velParam.isNotEmpty)
              ? velParam
              : (extraMap?['velodromeId'] as String? ?? 'grenchen_tissot');
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: TrackOmniumMadisonChampionshipScreen(
              initialDiscipline: initialDiscipline,
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
      GoRoute(
        path: AppRoutes.raceOrganizerHq,
        name: AppRouteNames.raceOrganizerHq,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialEmpire = extra is RaceOrganizerEmpireModel
              ? extra
              : extraMap?['initialEmpire'] as RaceOrganizerEmpireModel?;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: RaceOrganizerHqDashboardScreen(
              initialEmpire: initialEmpire,
              isReadOnly: isReadOnly,
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
        path: AppRoutes.ultraBikepacking,
        name: AppRouteNames.ultraBikepacking,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialRace = extra is UltraEnduranceBikepackingRaceModel
              ? extra
              : extraMap?['initialRace'] as UltraEnduranceBikepackingRaceModel?;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: UltraBikepackingTranscontinentalScreen(
              initialRace: initialRace,
              isReadOnly: isReadOnly,
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
        path: AppRoutes.globalAcademies,
        name: AppRouteNames.globalAcademies,
        pageBuilder: (context, state) {
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: GlobalAcademyNetworkMapScreen(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.academy);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.managerReputation,
        name: AppRouteNames.managerReputation,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final careerSave = extra is CareerSave
              ? extra
              : extraMap?['careerSave'] as CareerSave?;
          final initialSnapshot = extra is ManagerProfileSnapshot
              ? extra
              : extraMap?['initialSnapshot'] as ManagerProfileSnapshot?;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: ManagerProfileAndReputationScreen(
              careerSave: careerSave,
              initialSnapshot: initialSnapshot,
              isReadOnly: isReadOnly,
              onBackPressed: () {
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

      // 7. Trasy Paczki #8 (Złota Era 1970–2015, UCI e-Sports, ESG, Reprezentacja, Prezentacja GT, Księga Legendy)
      GoRoute(
        path: AppRoutes.goldenEraRetro,
        name: AppRouteNames.goldenEraRetro,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final yearParam =
              int.tryParse(state.uri.queryParameters['year'] ?? '');
          final initialYear =
              (yearParam ?? extraMap?['initialYear'] as int? ?? 1976)
                  .clamp(1970, 2015);
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: GoldenEraRetroCampaignsScreen(
              initialYear: initialYear,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cyclingEsports,
        name: AppRouteNames.cyclingEsports,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialWorldModel = extra is UciCyclingEsportsWorldModel
              ? extra
              : extraMap?['initialWorldModel'] as UciCyclingEsportsWorldModel?;
          final autoAnimateParam = state.uri.queryParameters['autoAnimate'];
          final autoAnimate3d = autoAnimateParam != null
              ? autoAnimateParam != 'false'
              : (extraMap?['autoAnimate3d'] as bool? ?? true);
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: CyclingEsportsAndVirtualAcademyScreen(
              initialWorldModel: initialWorldModel,
              autoAnimate3d: autoAnimate3d,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.esgGreenFleet,
        name: AppRouteNames.esgGreenFleet,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialModel =
              extra is TeamEsgSustainabilityAndGreenFleetModel
                  ? extra
                  : extraMap?['initialModel']
                      as TeamEsgSustainabilityAndGreenFleetModel?;
          final showAppBar = extraMap?['showAppBar'] as bool? ?? true;
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab =
              extraMap?['initialTab'] as EsgSustainabilityFleetTab? ??
                  switch (tabParam) {
                    'carbon' => EsgSustainabilityFleetTab.carbonLedger,
                    'convoy' => EsgSustainabilityFleetTab.convoyAndInfra,
                    'sponsors' => EsgSustainabilityFleetTab.greenSponsors,
                    _ => EsgSustainabilityFleetTab.fleet,
                  };
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: EsgSustainabilityAndFleetScreen(
              initialModel: initialModel,
              showAppBar: showAppBar,
              initialTab: initialTab,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.nationalTeamHq,
        name: AppRouteNames.nationalTeamHq,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = extraMap?['initialTab'] as NationalTeamHqTab? ??
              switch (tabParam) {
                'tactics' => NationalTeamHqTab.tacticsAndChemistry,
                'federation' => NationalTeamHqTab.federationAndHistory,
                _ => NationalTeamHqTab.callUpsAndPool,
              };
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: NationalTeamSelectionHqScreen(
              isReadOnly: isReadOnly,
              initialTab: initialTab,
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
        path: AppRoutes.grandTourRouteReveal,
        name: AppRouteNames.grandTourRouteReveal,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final editions =
              extraMap?['editions'] as List<GrandTourRouteRevealEdition>?;
          final teamNameOverride = extraMap?['teamNameOverride'] as String?;
          final leaderCandidatesOverride =
              extraMap?['leaderCandidatesOverride'] as List<String>?;
          final revealAllInitially =
              extraMap?['revealAllInitially'] as bool? ??
                  (state.uri.queryParameters['revealAll'] == 'true');
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: GrandTourRouteRevealCeremonyScreen(
              editions: editions,
              teamNameOverride: teamNameOverride,
              leaderCandidatesOverride: leaderCandidatesOverride,
              revealAllInitially: revealAllInitially,
              onCeremonyCompleted: (_) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.calendar);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.managerLegacyBook,
        name: AppRouteNames.managerLegacyBook,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialEntryId = state.uri.queryParameters['entryId'] ??
              extraMap?['initialEntryId'] as String?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: ManagerLegacyHallOfFameBookScreen(
              initialEntryId: initialEntryId,
              onStartNewGamePlus: (_) => context.go(AppRoutes.newCareer),
            ),
          );
        },
      ),

      // 8. Trasy Paczki #9 (UCI Para-Cycling, Muzeum Klubowe 3D, Mikrocykle Treningowe, Talent Combine, Analityka BI)
      GoRoute(
        path: AppRoutes.paracyclingWorldCup,
        name: AppRouteNames.paracyclingWorldCup,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialModel = extra is UciParacyclingTandemHandbikeModel
              ? extra
              : extraMap?['initialModel'] as UciParacyclingTandemHandbikeModel?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: UciParacyclingWorldCupScreen(
              initialModel: initialModel,
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
        path: AppRoutes.clubMuseum,
        name: AppRouteNames.clubMuseum,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialExhibitId = state.uri.queryParameters['exhibitId'] ??
              extraMap?['initialExhibitId'] as String?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: ClubMuseumAndLegendaryBikesScreen(
              initialExhibitId: initialExhibitId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.weeklyMicrocycle,
        name: AppRouteNames.weeklyMicrocycle,
        pageBuilder: (context, state) {
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: WeeklyTrainingMicrocyclePlannerScreen(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.training);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.talentCombine,
        name: AppRouteNames.talentCombine,
        pageBuilder: (context, state) {
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: TalentCombineTryoutsScreen(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.academy);
                }
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.careerAnalyticsBi,
        name: AppRouteNames.careerAnalyticsBi,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final overrideSave = extra is CareerSave
              ? extra
              : extraMap?['overrideSave'] as CareerSave?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: DeepCareerAnalyticsBiScreen(
              overrideSave: overrideSave,
            ),
          );
        },
      ),

      // 9. Trasy Paczki #10 (Reżyserka TV na Żywo, Poranny Raport Medyczny GT, Grudniowy Obóz Aero, Centrum Przedłużeń Kontraktów)
      GoRoute(
        path: AppRoutes.tvBroadcastDirector,
        name: AppRouteNames.tvBroadcastDirector,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          final liveTickerParam = state.uri.queryParameters['liveTicker'];
          final enableLiveTicker = liveTickerParam != null
              ? liveTickerParam != 'false'
              : (extraMap?['enableLiveTicker'] as bool? ?? true);
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: TvBroadcastDirectorControlRoomScreen(
              isReadOnly: isReadOnly,
              enableLiveTicker: enableLiveTicker,
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
        path: AppRoutes.grandTourMorningMedical,
        name: AppRouteNames.grandTourMorningMedical,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final initialReport = extra is GrandTourTeamMorningReport
              ? extra
              : extraMap?['initialReport'] as GrandTourTeamMorningReport?;
          final initialHrvHistoryByRider =
              extraMap?['initialHrvHistoryByRider'] as Map<String, List<double>>?;
          final riderRolesById =
              extraMap?['riderRolesById'] as Map<String, GrandTourTriageRole>?;
          final totalPhysioPoolMinutes =
              extraMap?['totalPhysioPoolMinutes'] as int? ?? 360;
          final specialistCount = extraMap?['specialistCount'] as int? ?? 3;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          final onCommitBriefing = extraMap?['onCommitBriefing']
              as ValueChanged<GrandTourMorningBriefingAllocationResult>?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: GrandTourMorningMedicalBriefingScreen(
              initialReport: initialReport,
              initialHrvHistoryByRider: initialHrvHistoryByRider,
              riderRolesById: riderRolesById,
              totalPhysioPoolMinutes: totalPhysioPoolMinutes,
              specialistCount: specialistCount,
              isReadOnly: isReadOnly,
              onCommitBriefing: onCommitBriefing,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.winterWindTunnelCamp,
        name: AppRouteNames.winterWindTunnelCamp,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final yearParam =
              int.tryParse(state.uri.queryParameters['seasonYear'] ?? '');
          final seasonYear =
              yearParam ?? extraMap?['seasonYear'] as int? ?? 2027;
          final teamBudgetEur =
              extraMap?['teamBudgetEur'] as int? ?? 250000;
          final initialRoster = extra is List<Rider>
              ? extra
              : extraMap?['initialRoster'] as List<Rider>?;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          final onCampCompleted = extraMap?['onCampCompleted']
              as ValueChanged<PreSeasonWindTunnelCampOutcome>?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            axis: SharedAxisDirection.scaled,
            child: WinterWindTunnelCampScreen(
              seasonYear: seasonYear,
              teamBudgetEur: teamBudgetEur,
              initialRoster: initialRoster,
              isReadOnly: isReadOnly,
              onCampCompleted: onCampCompleted,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.contractRenewalsWarRoom,
        name: AppRouteNames.contractRenewalsWarRoom,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final extraMap = extra is Map<String, dynamic> ? extra : null;
          final riders = extra is List<Rider>
              ? extra
              : extraMap?['riders'] as List<Rider>?;
          final yearParam =
              int.tryParse(state.uri.queryParameters['seasonYear'] ?? '');
          final seasonYear =
              yearParam ?? extraMap?['seasonYear'] as int? ?? 2027;
          final annualWageBudgetEur =
              extraMap?['annualWageBudgetEur'] as int? ?? 6800000;
          final isReadOnly = extraMap?['isReadOnly'] as bool? ?? false;
          final onContractsUpdated = extraMap?['onContractsUpdated']
              as ValueChanged<ContractRenewalsOutcome>?;
          return AnimatedScreenTransitionRouter.buildManagerPage(
            state: state,
            child: ContractRenewalsWarRoomScreen(
              riders: riders,
              seasonYear: seasonYear,
              annualWageBudgetEur: annualWageBudgetEur,
              isReadOnly: isReadOnly,
              onContractsUpdated: onContractsUpdated,
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

  /// Nawigacja do Centrum Lig Online, ELO i Wyzwań Tygodnia
  void goToMultiplayerLeagues({
    MultiplayerHubTab initialTab = MultiplayerHubTab.leagues,
    List<OnlineLeagueModel>? initialLeagues,
    List<GhostChallengeModel>? initialChallenges,
    EloRatingProfile? initialPlayerProfile,
    bool isReadOnly = false,
  }) =>
      go(
        AppRoutes.multiplayerLeagues,
        extra: {
          'initialTab': initialTab,
          'initialLeagues': initialLeagues,
          'initialChallenges': initialChallenges,
          'initialPlayerProfile': initialPlayerProfile,
          'isReadOnly': isReadOnly,
        },
      );

  /// Nawigacja do Pucharu Świata MTB XCO
  void goToMtbXcoWorldCup({
    bool isReadOnly = false,
    bool show3dPreview = true,
  }) =>
      go(
        AppRoutes.mtbXcoWorldCup,
        extra: {
          'isReadOnly': isReadOnly,
          'show3dPreview': show3dPreview,
        },
      );

  /// Nawigacja do Fabryki i Działu R&D Własnej Marki Rowerowej
  void goToBikeBrandFactory({
    InHouseBikeBrandFactoryState? initialState,
    bool showAppBar = true,
  }) =>
      go(
        AppRoutes.bikeBrandFactory,
        extra: {
          'initialState': initialState,
          'showAppBar': showAppBar,
        },
      );

  /// Nawigacja do Mistrzostw Torowych UCI (Keirin, Madison, Omnium, Wyścig Punktowy)
  void goToVelodromeTrackChampionship({
    TrackChampionshipDiscipline discipline = TrackChampionshipDiscipline.keirin,
    String velodromeId = 'grenchen_tissot',
  }) =>
      go(
        '${AppRoutes.velodromeTrackChampionship}?velodromeId=$velodromeId',
        extra: {
          'discipline': discipline,
          'velodromeId': velodromeId,
        },
      );

  /// Nawigacja do trybu Organizatora Wyścigów ASO/RCS
  void goToRaceOrganizerHq({
    RaceOrganizerEmpireModel? initialEmpire,
    bool isReadOnly = false,
  }) =>
      go(
        AppRoutes.raceOrganizerHq,
        extra: {
          'initialEmpire': initialEmpire,
          'isReadOnly': isReadOnly,
        },
      );

  /// Nawigacja do wyścigów Ultra-Endurance Bikepacking (Dotwatching Live Tracker)
  void goToUltraBikepacking({
    UltraEnduranceBikepackingRaceModel? initialRace,
    bool isReadOnly = false,
  }) =>
      go(
        AppRoutes.ultraBikepacking,
        extra: {
          'initialRace': initialRace,
          'isReadOnly': isReadOnly,
        },
      );

  /// Nawigacja do Globalnej Sieci Akademii Satelickich
  void goToGlobalAcademies() => go(AppRoutes.globalAcademies);

  /// Nawigacja do Profilu Menedżera, Statystyk Życiowych i Reputacji
  void goToManagerReputation({
    CareerSave? careerSave,
    ManagerProfileSnapshot? initialSnapshot,
    bool isReadOnly = false,
  }) =>
      go(
        AppRoutes.managerReputation,
        extra: {
          'careerSave': careerSave,
          'initialSnapshot': initialSnapshot,
          'isReadOnly': isReadOnly,
        },
      );

  /// Nawigacja do kampanii historycznych „Złota Era Kolarstwa: 1970–2015”
  void goToGoldenEraRetro({int initialYear = 1976}) => go(
        '${AppRoutes.goldenEraRetro}?year=${initialYear.clamp(1970, 2015)}',
        extra: {'initialYear': initialYear.clamp(1970, 2015)},
      );

  /// Nawigacja do Centrum UCI Cycling Esports i Virtual Talent ID Academy
  void goToCyclingEsports({
    UciCyclingEsportsWorldModel? initialWorldModel,
    bool autoAnimate3d = true,
  }) =>
      go(
        '${AppRoutes.cyclingEsports}?autoAnimate=$autoAnimate3d',
        extra: {
          'initialWorldModel': initialWorldModel,
          'autoAnimate3d': autoAnimate3d,
        },
      );

  /// Nawigacja do ekranu Ekologii ESG i Zielonej Floty EV/FCEV
  void goToEsgGreenFleet({
    TeamEsgSustainabilityAndGreenFleetModel? initialModel,
    EsgSustainabilityFleetTab initialTab = EsgSustainabilityFleetTab.fleet,
    bool showAppBar = true,
  }) {
    final tabSlug = switch (initialTab) {
      EsgSustainabilityFleetTab.fleet => 'fleet',
      EsgSustainabilityFleetTab.carbonLedger => 'carbon',
      EsgSustainabilityFleetTab.convoyAndInfra => 'convoy',
      EsgSustainabilityFleetTab.greenSponsors => 'sponsors',
    };
    go(
      '${AppRoutes.esgGreenFleet}?tab=$tabSlug',
      extra: {
        'initialModel': initialModel,
        'initialTab': initialTab,
        'showAppBar': showAppBar,
      },
    );
  }

  /// Nawigacja do Biura Selekcjonera Reprezentacji Narodowej (MŚ / IO)
  void goToNationalTeamHq({
    NationalTeamHqTab initialTab = NationalTeamHqTab.callUpsAndPool,
    bool isReadOnly = false,
  }) {
    final tabSlug = switch (initialTab) {
      NationalTeamHqTab.callUpsAndPool => 'callups',
      NationalTeamHqTab.tacticsAndChemistry => 'tactics',
      NationalTeamHqTab.federationAndHistory => 'federation',
    };
    go(
      '${AppRoutes.nationalTeamHq}?tab=$tabSlug',
      extra: {
        'initialTab': initialTab,
        'isReadOnly': isReadOnly,
      },
    );
  }

  /// Nawigacja do Ceremonii Prezentacji Oficjalnej Trasy Wielkich Tourów
  void goToGrandTourRouteReveal({
    List<GrandTourRouteRevealEdition>? editions,
    String? teamNameOverride,
    List<String>? leaderCandidatesOverride,
    bool revealAllInitially = false,
  }) =>
      go(
        '${AppRoutes.grandTourRouteReveal}?revealAll=$revealAllInitially',
        extra: {
          'editions': editions,
          'teamNameOverride': teamNameOverride,
          'leaderCandidatesOverride': leaderCandidatesOverride,
          'revealAllInitially': revealAllInitially,
        },
      );

  /// Nawigacja do Księgi Legendy Menedżera i trybu Dynastia NG+
  void goToManagerLegacyBook({String? initialEntryId}) => go(
        initialEntryId != null
            ? '${AppRoutes.managerLegacyBook}?entryId=$initialEntryId'
            : AppRoutes.managerLegacyBook,
        extra: {'initialEntryId': initialEntryId},
      );

  /// Nawigacja do Pucharu Świata UCI Para-Cycling i Igrzysk Paralimpijskich
  void goToParacyclingWorldCup({
    UciParacyclingTandemHandbikeModel? initialModel,
  }) =>
      go(
        AppRoutes.paracyclingWorldCup,
        extra: {'initialModel': initialModel},
      );

  /// Nawigacja do Muzeum Klubowego i Historycznych Rowerów 3D
  void goToClubMuseum({String? initialExhibitId}) => go(
        initialExhibitId != null
            ? '${AppRoutes.clubMuseum}?exhibitId=$initialExhibitId'
            : AppRoutes.clubMuseum,
        extra: {'initialExhibitId': initialExhibitId},
      );

  /// Nawigacja do Kalendarza Tygodniowych Mikrocykli Treningowych (TSS/TSB)
  void goToWeeklyMicrocycle() => go(AppRoutes.weeklyMicrocycle);

  /// Nawigacja do Obozu Selekcyjnego Juniorów (Global Young Talent Combine)
  void goToTalentCombine() => go(AppRoutes.talentCombine);

  /// Nawigacja do Analityki Biznesowo-Sportowej BI (ROI Transferów i R&D)
  void goToCareerAnalyticsBi({CareerSave? overrideSave}) => go(
        AppRoutes.careerAnalyticsBi,
        extra: {'overrideSave': overrideSave},
      );

  /// Nawigacja do Reżyserki Transmisji Telewizyjnej na Żywo
  void goToTvBroadcastDirector({
    bool isReadOnly = false,
    bool enableLiveTicker = true,
  }) =>
      go(
        '${AppRoutes.tvBroadcastDirector}?liveTicker=$enableLiveTicker',
        extra: {
          'isReadOnly': isReadOnly,
          'enableLiveTicker': enableLiveTicker,
        },
      );

  /// Nawigacja do Porannego Raportu Medycznego i Fizjoterapii Wielkiego Touru
  void goToGrandTourMorningMedical({
    GrandTourTeamMorningReport? initialReport,
    Map<String, List<double>>? initialHrvHistoryByRider,
    Map<String, GrandTourTriageRole>? riderRolesById,
    int totalPhysioPoolMinutes = 360,
    int specialistCount = 3,
    bool isReadOnly = false,
    ValueChanged<GrandTourMorningBriefingAllocationResult>? onCommitBriefing,
  }) =>
      go(
        AppRoutes.grandTourMorningMedical,
        extra: {
          'initialReport': initialReport,
          'initialHrvHistoryByRider': initialHrvHistoryByRider,
          'riderRolesById': riderRolesById,
          'totalPhysioPoolMinutes': totalPhysioPoolMinutes,
          'specialistCount': specialistCount,
          'isReadOnly': isReadOnly,
          'onCommitBriefing': onCommitBriefing,
        },
      );

  /// Nawigacja do Grudniowego Obozu Aerodynamicznego (Tunel w Newtonach)
  void goToWinterWindTunnelCamp({
    int seasonYear = 2027,
    int teamBudgetEur = 250000,
    List<Rider>? initialRoster,
    bool isReadOnly = false,
    ValueChanged<PreSeasonWindTunnelCampOutcome>? onCampCompleted,
  }) =>
      go(
        '${AppRoutes.winterWindTunnelCamp}?seasonYear=$seasonYear',
        extra: {
          'seasonYear': seasonYear,
          'teamBudgetEur': teamBudgetEur,
          'initialRoster': initialRoster,
          'isReadOnly': isReadOnly,
          'onCampCompleted': onCampCompleted,
        },
      );

  /// Nawigacja do Centrum Przedłużeń Kontraktów (War Room)
  void goToContractRenewalsWarRoom({
    List<Rider>? riders,
    int seasonYear = 2027,
    int annualWageBudgetEur = 6800000,
    bool isReadOnly = false,
    ValueChanged<ContractRenewalsOutcome>? onContractsUpdated,
  }) =>
      go(
        '${AppRoutes.contractRenewalsWarRoom}?seasonYear=$seasonYear',
        extra: {
          'riders': riders,
          'seasonYear': seasonYear,
          'annualWageBudgetEur': annualWageBudgetEur,
          'isReadOnly': isReadOnly,
          'onContractsUpdated': onContractsUpdated,
        },
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
