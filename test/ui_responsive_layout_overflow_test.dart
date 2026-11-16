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
import 'package:pro_peloton_manager/ui/screens/bike_garage_rnd_screen.dart';
import 'package:pro_peloton_manager/ui/screens/calendar_and_race_planner_screen.dart';
import 'package:pro_peloton_manager/ui/screens/dashboard_hq_screen.dart';
import 'package:pro_peloton_manager/ui/screens/development_academy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/game_start_screen.dart';
import 'package:pro_peloton_manager/ui/screens/hall_of_fame_and_records_screen.dart';
import 'package:pro_peloton_manager/ui/screens/jersey_and_bike_livery_studio_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_shell_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_title_menu_screen.dart';
import 'package:pro_peloton_manager/ui/screens/manager_profile_and_achievements_screen.dart';
import 'package:pro_peloton_manager/ui/screens/medical_and_recovery_center_screen.dart';
import 'package:pro_peloton_manager/ui/screens/new_career_setup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/physiology_lab_screen.dart';
import 'package:pro_peloton_manager/ui/screens/post_stage_podium_screen.dart';
import 'package:pro_peloton_manager/ui/screens/pre_race_briefing_screen.dart';
import 'package:pro_peloton_manager/ui/screens/pre_season_team_presentation_screen.dart';
import 'package:pro_peloton_manager/ui/screens/quick_race_sandbox_screen.dart';
import 'package:pro_peloton_manager/ui/screens/race_simulation_screen.dart';
import 'package:pro_peloton_manager/ui/screens/rider_detail_screen.dart';
import 'package:pro_peloton_manager/ui/screens/settings_and_mod_screen.dart';
import 'package:pro_peloton_manager/ui/screens/sponsors_and_finance_screen.dart';
import 'package:pro_peloton_manager/ui/screens/squad_roster_screen.dart';
import 'package:pro_peloton_manager/ui/screens/staff_management_screen.dart';
import 'package:pro_peloton_manager/ui/screens/stage_editor_creator_screen.dart';
import 'package:pro_peloton_manager/ui/screens/team_builder_hierarchy_screen.dart';
import 'package:pro_peloton_manager/ui/screens/training_and_camps_screen.dart';
import 'package:pro_peloton_manager/ui/screens/transfer_market_scouting_screen.dart';
import 'package:pro_peloton_manager/ui/screens/wind_tunnel_and_bike_fit_screen.dart';

class _TestCareerController extends CareerController {
  _TestCareerController(CareerSave save) : super() {
    state = CareerUiState(save: save);
  }
}

class _ScreenEntry {
  final String name;
  final Widget Function(CareerSave save) builder;
  final bool wrapInScaffold;

  const _ScreenEntry({
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
    '390x844 (iPhone)': Size(390, 844),
    '1024x768 (iPad)': Size(1024, 768),
    '1600x900 (Desktop)': Size(1600, 900),
  };

  final screens = <_ScreenEntry>[
    _ScreenEntry(
      name: 'MainTitleMenuScreen',
      wrapInScaffold: false,
      builder: (_) => const MainTitleMenuScreen(),
    ),
    _ScreenEntry(
      name: 'GameStartScreen',
      wrapInScaffold: false,
      builder: (_) => const GameStartScreen(),
    ),
    _ScreenEntry(
      name: 'NewCareerSetupScreen',
      wrapInScaffold: false,
      builder: (_) => const NewCareerSetupScreen(initialSlotNumber: 1),
    ),
    _ScreenEntry(
      name: 'MainShellScreen (Dashboard)',
      wrapInScaffold: false,
      builder: (_) => const MainShellScreen(
        currentLocation: AppRoutes.dashboard,
        child: DashboardHqScreen(),
      ),
    ),
    _ScreenEntry(
      name: 'CareerInboxView',
      builder: (_) => const CareerInboxView(),
    ),
    _ScreenEntry(
      name: 'UciRankingsAndLicenseView',
      builder: (_) => const UciRankingsAndLicenseView(),
    ),
    _ScreenEntry(
      name: 'DashboardHqScreen',
      builder: (_) => const DashboardHqScreen(),
    ),
    _ScreenEntry(
      name: 'CalendarAndRacePlannerScreen',
      builder: (_) => const CalendarAndRacePlannerScreen(showAppBar: false),
    ),
    _ScreenEntry(
      name: 'SquadRosterScreen',
      builder: (_) => const SquadRosterScreen(showAppBar: false),
    ),
    _ScreenEntry(
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
    _ScreenEntry(
      name: 'TeamBuilderHierarchyScreen',
      builder: (_) => const TeamBuilderHierarchyScreen(),
    ),
    _ScreenEntry(
      name: 'TrainingAndCampsScreen',
      builder: (save) => TrainingAndCampsScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenEntry(
      name: 'PhysiologyLabScreen',
      builder: (save) => PhysiologyLabScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenEntry(
      name: 'MedicalAndRecoveryCenterScreen',
      builder: (save) => MedicalAndRecoveryCenterScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenEntry(
      name: 'DevelopmentAcademyScreen',
      builder: (save) => DevelopmentAcademyScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenEntry(
      name: 'StaffManagementScreen',
      builder: (_) => const StaffManagementScreen(showAppBar: false),
    ),
    _ScreenEntry(
      name: 'BikeGarageRndScreen',
      builder: (_) => const BikeGarageRndScreen(),
    ),
    _ScreenEntry(
      name: 'WindTunnelAndBikeFitScreen',
      builder: (save) => WindTunnelAndBikeFitScreen(
        showAppBar: false,
        initialRiderId: save.playerRoster.first.id,
      ),
    ),
    _ScreenEntry(
      name: 'SponsorsAndFinanceScreen',
      builder: (_) => const SponsorsAndFinanceScreen(),
    ),
    _ScreenEntry(
      name: 'TransferMarketScoutingScreen',
      builder: (_) => const TransferMarketScoutingScreen(),
    ),
    _ScreenEntry(
      name: 'JerseyAndBikeLiveryStudioScreen',
      builder: (_) => const JerseyAndBikeLiveryStudioScreen(),
    ),
    _ScreenEntry(
      name: 'HallOfFameAndRecordsScreen',
      builder: (_) => const HallOfFameAndRecordsScreen(),
    ),
    _ScreenEntry(
      name: 'ManagerProfileAndAchievementsScreen',
      builder: (_) => const ManagerProfileAndAchievementsScreen(),
    ),
    _ScreenEntry(
      name: 'StageEditorCreatorScreen',
      builder: (_) => const StageEditorCreatorScreen(),
    ),
    _ScreenEntry(
      name: 'PreSeasonTeamPresentationScreen',
      builder: (_) => const PreSeasonTeamPresentationScreen(),
    ),
    _ScreenEntry(
      name: 'SettingsAndModScreen',
      builder: (_) => const SettingsAndModScreen(initialTabIndex: 0),
    ),
    _ScreenEntry(
      name: 'QuickRaceSandboxScreen',
      wrapInScaffold: false,
      builder: (_) => const QuickRaceSandboxScreen(),
    ),
    _ScreenEntry(
      name: 'PreRaceBriefingScreen',
      wrapInScaffold: false,
      builder: (_) => const PreRaceBriefingScreen(isStandalone: true),
    ),
    _ScreenEntry(
      name: 'RaceSimulationScreen',
      wrapInScaffold: false,
      builder: (_) => const RaceSimulationScreen(
        initialCameraMode: RaceCameraMode.profile2D,
      ),
    ),
    _ScreenEntry(
      name: 'PostStagePodiumScreen',
      wrapInScaffold: false,
      builder: (_) => const PostStagePodiumScreen(),
    ),
  ];

  Widget buildHarness({
    required _ScreenEntry entry,
    required Size size,
  }) {
    final screenWidget = entry.builder(testSave);
    return ProviderScope(
      overrides: [
        careerProvider.overrideWith((ref) => _TestCareerController(testSave)),
      ],
      child: AppLocalizationsScope(
        localizations: const AppLocalizationsPlEn(AppLanguage.pl),
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: entry.wrapInScaffold
                ? Scaffold(body: screenWidget)
                : screenWidget,
          ),
        ),
      ),
    );
  }

  for (final resolutionEntry in targetResolutions.entries) {
    final resolutionLabel = resolutionEntry.key;
    final size = resolutionEntry.value;

    group('Responsive layout check at $resolutionLabel', () {
      for (final screen in screens) {
        testWidgets(
          '${screen.name} renders with zero RenderFlex overflowed at $resolutionLabel',
          (tester) async {
            final capturedErrors = <FlutterErrorDetails>[];
            final originalOnError = FlutterError.onError;
            FlutterError.onError = (FlutterErrorDetails details) {
              capturedErrors.add(details);
            };

            try {
              await tester.binding.setSurfaceSize(size);
              addTearDown(() => tester.binding.setSurfaceSize(null));

              await tester.pumpWidget(buildHarness(entry: screen, size: size));
              await tester.pump(const Duration(milliseconds: 350));
              await tester.pump(const Duration(milliseconds: 100));
            } finally {
              FlutterError.onError = originalOnError;
            }

            final overflowErrors = capturedErrors
                .where(
                  (d) =>
                      d.exceptionAsString().contains('RenderFlex overflowed') ||
                      d.exceptionAsString().contains('overflowed by'),
                )
                .map((d) => d.toString())
                .toList();

            expect(
              overflowErrors,
              isEmpty,
              reason:
                  'RenderFlex overflow detected in ${screen.name} at $resolutionLabel:\n'
                  '${overflowErrors.join('\n---\n')}',
            );

            expect(
              capturedErrors.map((d) => d.exceptionAsString()).toList(),
              isEmpty,
              reason:
                  'Unexpected FlutterError in ${screen.name} at $resolutionLabel',
            );

            expect(tester.takeException(), isNull);
          },
        );
      }
    });
  }
}
