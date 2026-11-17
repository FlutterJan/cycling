import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/localization/app_localizations_pl_en.dart';
import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/services/database/demo_save_preset_builder.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/achievements_and_platinum_trophy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_character_creator_screen.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_dashboard_and_apartment_screen.dart';
import 'package:pro_peloton_manager/ui/screens/bike_garage_rnd_screen.dart';
import 'package:pro_peloton_manager/ui/screens/calendar_and_race_planner_screen.dart';
import 'package:pro_peloton_manager/ui/screens/companion_car_dashboard_screen.dart';
import 'package:pro_peloton_manager/ui/screens/credits_and_architecture_showcase_screen.dart';
import 'package:pro_peloton_manager/ui/screens/cyclocross_winter_series_screen.dart';
import 'package:pro_peloton_manager/ui/screens/dashboard_hq_screen.dart';
import 'package:pro_peloton_manager/ui/screens/development_academy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/game_start_screen.dart';
import 'package:pro_peloton_manager/ui/screens/global_academy_network_map_screen.dart';
import 'package:pro_peloton_manager/ui/screens/grand_tour_rest_day_screen.dart';
import 'package:pro_peloton_manager/ui/screens/gravel_world_series_hub_screen.dart';
import 'package:pro_peloton_manager/ui/screens/hall_of_fame_and_records_screen.dart';
import 'package:pro_peloton_manager/ui/screens/in_game_cycling_encyclopedia_screen.dart';
import 'package:pro_peloton_manager/ui/screens/in_game_database_roster_editor_screen.dart';
import 'package:pro_peloton_manager/ui/screens/in_house_bike_brand_factory_screen.dart';
import 'package:pro_peloton_manager/ui/screens/jersey_and_bike_livery_studio_screen.dart';
import 'package:pro_peloton_manager/ui/screens/legends_card_album_and_packs_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_shell_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_title_menu_screen.dart';
import 'package:pro_peloton_manager/ui/screens/manager_profile_and_achievements_screen.dart';
import 'package:pro_peloton_manager/ui/screens/manager_profile_and_reputation_screen.dart';
import 'package:pro_peloton_manager/ui/screens/medical_and_recovery_center_screen.dart';
import 'package:pro_peloton_manager/ui/screens/mtb_xco_world_cup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/multiplayer_leagues_and_challenges_screen.dart';
import 'package:pro_peloton_manager/ui/screens/new_career_setup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/olympic_games_hub_and_medal_table_screen.dart';
import 'package:pro_peloton_manager/ui/screens/physiology_lab_screen.dart';
import 'package:pro_peloton_manager/ui/screens/post_stage_podium_screen.dart';
import 'package:pro_peloton_manager/ui/screens/pre_race_briefing_screen.dart';
import 'package:pro_peloton_manager/ui/screens/pre_season_team_presentation_screen.dart';
import 'package:pro_peloton_manager/ui/screens/pre_stage_paddock_and_warmup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/quick_race_sandbox_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_organizer_hq_dashboard_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_replay_director_theater_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_simulation_screen.dart';
import 'package:pro_peloton_manager/ui/screens/rider_detail_screen.dart';
import 'package:pro_peloton_manager/ui/screens/service_course_hq_facility_screen.dart';
import 'package:pro_peloton_manager/ui/screens/settings_and_mod_screen.dart';
import 'package:pro_peloton_manager/ui/screens/sponsors_and_finance_screen.dart';
import 'package:pro_peloton_manager/ui/screens/squad_roster_screen.dart';
import 'package:pro_peloton_manager/ui/screens/staff_management_screen.dart';
import 'package:pro_peloton_manager/ui/screens/stage_editor_creator_screen.dart';
import 'package:pro_peloton_manager/ui/screens/strava_style_stage_analysis_screen.dart';
import 'package:pro_peloton_manager/ui/screens/tactical_challenges_hub_screen.dart';
import 'package:pro_peloton_manager/ui/screens/team_builder_hierarchy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/team_bus_locker_room_screen.dart';
import 'package:pro_peloton_manager/ui/screens/track_omnium_madison_championship_screen.dart';
import 'package:pro_peloton_manager/ui/screens/training_and_camps_screen.dart';
import 'package:pro_peloton_manager/ui/screens/transfer_market_scouting_screen.dart';
import 'package:pro_peloton_manager/ui/screens/uci_hour_record_attempt_screen.dart';
import 'package:pro_peloton_manager/ui/screens/ultra_bikepacking_transcontinental_screen.dart';
import 'package:pro_peloton_manager/ui/screens/velo_dor_gala_ceremony_screen.dart';
import 'package:pro_peloton_manager/ui/screens/wind_tunnel_and_bike_fit_screen.dart';

class _SmokeTestCareerController extends CareerController {
  _SmokeTestCareerController(CareerSave save) : super() {
    state = CareerUiState(save: save);
  }
}

class _ScreenSmokeSpec {
  final String name;
  final Widget Function(CareerSave save) builder;
  final bool wrapInScaffold;

  const _ScreenSmokeSpec({
    required this.name,
    required this.builder,
    this.wrapInScaffold = true,
  });
}

void main() {
  late CareerSave testSave;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => Directory.systemTemp.path,
    );
    testSave = await DemoSavePresetBuilder.buildPreset(
      DemoSavePresetType.polishWorldTourProject,
    );
  });

  const targetResolutions = <String, Size>{
    '390x844': Size(390, 844),
    '1024x768': Size(1024, 768),
    '1600x900': Size(1600, 900),
  };

  final screens = <_ScreenSmokeSpec>[
    _ScreenSmokeSpec(
      name: 'MainTitleMenuScreen',
      wrapInScaffold: false,
      builder: (_) => const MainTitleMenuScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'GameStartScreen',
      wrapInScaffold: false,
      builder: (_) => const GameStartScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'NewCareerSetupScreen',
      wrapInScaffold: false,
      builder: (_) => const NewCareerSetupScreen(initialSlotNumber: 1),
    ),
    _ScreenSmokeSpec(
      name: 'MainShellScreen',
      wrapInScaffold: false,
      builder: (_) => const MainShellScreen(
        currentLocation: AppRoutes.dashboard,
        child: DashboardHqScreen(),
      ),
    ),
    _ScreenSmokeSpec(
      name: 'CareerInboxView',
      builder: (_) => const CareerInboxView(),
    ),
    _ScreenSmokeSpec(
      name: 'UciRankingsAndLicenseView',
      builder: (_) => const UciRankingsAndLicenseView(),
    ),
    _ScreenSmokeSpec(
      name: 'ManagerProfileAndAchievementsView',
      builder: (_) => const ManagerProfileAndAchievementsView(),
    ),
    _ScreenSmokeSpec(
      name: 'DashboardHqScreen',
      builder: (_) => const DashboardHqScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'CalendarAndRacePlannerScreen',
      builder: (_) => const CalendarAndRacePlannerScreen(showAppBar: false),
    ),
    _ScreenSmokeSpec(
      name: 'SquadRosterScreen',
      builder: (_) => const SquadRosterScreen(showAppBar: false),
    ),
    _ScreenSmokeSpec(
      name: 'RiderDetailScreen',
      wrapInScaffold: false,
      builder: (save) {
        final firstRider = save.playerRoster.first;
        return RiderDetailScreen(
          riderId: firstRider.id,
          initialRider: firstRider,
        );
      },
    ),
    _ScreenSmokeSpec(
      name: 'TeamBuilderHierarchyScreen',
      builder: (_) => const TeamBuilderHierarchyScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'TrainingAndCampsScreen',
      builder: (save) => TrainingAndCampsScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'PhysiologyLabScreen',
      builder: (save) => PhysiologyLabScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'MedicalAndRecoveryCenterScreen',
      builder: (save) => MedicalAndRecoveryCenterScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'DevelopmentAcademyScreen',
      builder: (save) => DevelopmentAcademyScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'GlobalAcademyNetworkMapScreen',
      wrapInScaffold: false,
      builder: (_) => const GlobalAcademyNetworkMapScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'StaffManagementScreen',
      builder: (_) => const StaffManagementScreen(showAppBar: false),
    ),
    _ScreenSmokeSpec(
      name: 'BikeGarageRndScreen',
      builder: (_) => const BikeGarageRndScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'InHouseBikeBrandFactoryScreen',
      wrapInScaffold: false,
      builder: (_) => const InHouseBikeBrandFactoryScreen(showAppBar: false),
    ),
    _ScreenSmokeSpec(
      name: 'ServiceCourseHqFacilityScreen',
      wrapInScaffold: false,
      builder: (_) => const ServiceCourseHqFacilityScreen(showAppBar: false),
    ),
    _ScreenSmokeSpec(
      name: 'WindTunnelAndBikeFitScreen',
      builder: (save) => WindTunnelAndBikeFitScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'SponsorsAndFinanceScreen',
      builder: (_) => const SponsorsAndFinanceScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'TransferMarketScoutingScreen',
      builder: (_) => const TransferMarketScoutingScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'JerseyAndBikeLiveryStudioScreen',
      builder: (_) => const JerseyAndBikeLiveryStudioScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'HallOfFameAndRecordsScreen',
      builder: (_) => const HallOfFameAndRecordsScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'ManagerProfileAndAchievementsScreen',
      builder: (_) => const ManagerProfileAndAchievementsScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'ManagerProfileAndReputationScreen',
      wrapInScaffold: false,
      builder: (save) => ManagerProfileAndReputationScreen(careerSave: save),
    ),
    _ScreenSmokeSpec(
      name: 'AchievementsAndPlatinumTrophyScreen',
      wrapInScaffold: false,
      builder: (_) => const AchievementsAndPlatinumTrophyScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'LegendsCardAlbumAndPacksScreen',
      wrapInScaffold: false,
      builder: (_) => const LegendsCardAlbumAndPacksScreen(
        enableAmbientShimmer: false,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'StageEditorCreatorScreen',
      builder: (_) => const StageEditorCreatorScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'PreSeasonTeamPresentationScreen',
      builder: (_) => const PreSeasonTeamPresentationScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'SettingsAndModScreen',
      builder: (_) => const SettingsAndModScreen(initialTabIndex: 0),
    ),
    _ScreenSmokeSpec(
      name: 'InGameDatabaseRosterEditorScreen',
      wrapInScaffold: false,
      builder: (_) => const InGameDatabaseRosterEditorScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'InGameCyclingEncyclopediaScreen',
      wrapInScaffold: false,
      builder: (_) => const InGameCyclingEncyclopediaScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'CreditsAndArchitectureShowcaseScreen',
      wrapInScaffold: false,
      builder: (_) => const CreditsAndArchitectureShowcaseScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'QuickRaceSandboxScreen',
      wrapInScaffold: false,
      builder: (_) => const QuickRaceSandboxScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'PreRaceBriefingScreen',
      wrapInScaffold: false,
      builder: (_) => const PreRaceBriefingScreen(isStandalone: true),
    ),
    _ScreenSmokeSpec(
      name: 'PreStagePaddockAndWarmupScreen',
      wrapInScaffold: false,
      builder: (_) => const PreStagePaddockAndWarmupScreen(autoPlay3d: false),
    ),
    _ScreenSmokeSpec(
      name: 'TeamBusLockerRoomScreen',
      wrapInScaffold: false,
      builder: (_) => const TeamBusLockerRoomScreen(
        instantWarmUpForTesting: true,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'RaceSimulationScreen',
      wrapInScaffold: false,
      builder: (_) => const RaceSimulationScreen(
        initialCameraMode: RaceCameraMode.profile2D,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'CompanionCarDashboardScreen',
      wrapInScaffold: false,
      builder: (_) => const CompanionCarDashboardScreen(
        enableLiveTicker: false,
      ),
    ),
    _ScreenSmokeSpec(
      name: 'PostStagePodiumScreen',
      wrapInScaffold: false,
      builder: (_) => const PostStagePodiumScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'StravaStyleStageAnalysisScreen',
      wrapInScaffold: false,
      builder: (_) => const StravaStyleStageAnalysisScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'RaceReplayDirectorTheaterScreen',
      wrapInScaffold: false,
      builder: (_) => const RaceReplayDirectorTheaterScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'GrandTourRestDayScreen',
      wrapInScaffold: false,
      builder: (_) => const GrandTourRestDayScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'TacticalChallengesHubScreen',
      wrapInScaffold: false,
      builder: (_) => const TacticalChallengesHubScreen(showAppBar: false),
    ),
    _ScreenSmokeSpec(
      name: 'BeAProCharacterCreatorScreen',
      wrapInScaffold: false,
      builder: (_) => const BeAProCharacterCreatorScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'BeAProDashboardAndApartmentScreen',
      wrapInScaffold: false,
      builder: (_) => const BeAProDashboardAndApartmentScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'CyclocrossWinterSeriesScreen',
      wrapInScaffold: false,
      builder: (_) => const CyclocrossWinterSeriesScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'GravelWorldSeriesHubScreen',
      wrapInScaffold: false,
      builder: (_) => const GravelWorldSeriesHubScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'MtbXcoWorldCupScreen',
      wrapInScaffold: false,
      builder: (_) => const MtbXcoWorldCupScreen(show3dPreview: false),
    ),
    _ScreenSmokeSpec(
      name: 'TrackOmniumMadisonChampionshipScreen',
      wrapInScaffold: false,
      builder: (_) => const TrackOmniumMadisonChampionshipScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'UciHourRecordAttemptScreen',
      wrapInScaffold: false,
      builder: (_) => const UciHourRecordAttemptScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'OlympicGamesHubAndMedalTableScreen',
      wrapInScaffold: false,
      builder: (_) => const OlympicGamesHubAndMedalTableScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'UltraBikepackingTranscontinentalScreen',
      wrapInScaffold: false,
      builder: (_) => const UltraBikepackingTranscontinentalScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'MultiplayerLeaguesAndChallengesScreen',
      wrapInScaffold: false,
      builder: (_) => const MultiplayerLeaguesAndChallengesScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'RaceOrganizerHqDashboardScreen',
      wrapInScaffold: false,
      builder: (_) => const RaceOrganizerHqDashboardScreen(),
    ),
    _ScreenSmokeSpec(
      name: 'VeloDorGalaCeremonyScreen',
      wrapInScaffold: false,
      builder: (_) => const VeloDorGalaCeremonyScreen(),
    ),
  ];

  Widget buildHarness({
    required _ScreenSmokeSpec spec,
    required Size size,
  }) {
    final screenWidget = spec.builder(testSave);
    return ProviderScope(
      overrides: [
        careerProvider.overrideWith(
          (ref) => _SmokeTestCareerController(testSave),
        ),
      ],
      child: AppLocalizationsScope(
        localizations: const AppLocalizationsPlEn(AppLanguage.pl),
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: spec.wrapInScaffold
                ? Scaffold(body: screenWidget)
                : screenWidget,
          ),
        ),
      ),
    );
  }

  for (final resolution in targetResolutions.entries) {
    final resolutionLabel = resolution.key;
    final size = resolution.value;

    group('Golden smoke render at $resolutionLabel', () {
      for (final spec in screens) {
        testWidgets(
          '${spec.name} renders cleanly at $resolutionLabel',
          (tester) async {
            final capturedMessages = <String>[];
            final capturedFull = <String>[];
            final originalOnError = FlutterError.onError;
            FlutterError.onError = (FlutterErrorDetails details) {
              capturedMessages.add(details.exceptionAsString());
              capturedFull.add(details.toString());
            };

            try {
              await tester.binding.setSurfaceSize(size);
              addTearDown(() => tester.binding.setSurfaceSize(null));

              await tester.pumpWidget(buildHarness(spec: spec, size: size));
              await tester.pump(const Duration(milliseconds: 300));
              await tester.pump(const Duration(milliseconds: 100));

              expect(find.byType(MaterialApp), findsOneWidget);
              expect(
                tester.getSize(find.byType(MaterialApp)),
                equals(size),
              );
              expect(
                find.byWidgetPredicate(
                  (w) => w is Scaffold || w is CustomPaint || w is LayoutBuilder,
                ),
                findsWidgets,
              );

              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
            } finally {
              FlutterError.onError = originalOnError;
            }

            final overflowErrors = <String>[];
            for (var i = 0; i < capturedMessages.length; i++) {
              final msg = capturedMessages[i];
              if (msg.contains('RenderFlex overflowed') ||
                  msg.contains('overflowed by')) {
                overflowErrors.add(capturedFull[i]);
              }
            }

            expect(
              overflowErrors,
              isEmpty,
              reason:
                  'RenderFlex overflow detected in ${spec.name} at $resolutionLabel:\n'
                  '${overflowErrors.join('\n---\n')}',
            );

            expect(
              capturedMessages,
              isEmpty,
              reason:
                  'Unexpected FlutterError in ${spec.name} at $resolutionLabel',
            );

            expect(tester.takeException(), isNull);
          },
        );
      }
    });
  }
}
