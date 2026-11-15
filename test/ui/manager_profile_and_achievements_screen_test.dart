import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/services/career/achievement_and_milestones_service.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';
import 'package:pro_peloton_manager/state/career_controller.dart';
import 'package:pro_peloton_manager/ui/screens/manager_profile_and_achievements_screen.dart';

class _TestCareerController extends CareerController {
  _TestCareerController(CareerSave initialSave) {
    state = CareerUiState(save: initialSave);
  }

  @override
  Future<void> refreshSlotsList() async {}

  @override
  Future<void> refreshSavedGamesList() async {}
}

void main() {
  CareerSave buildTestSave() {
    final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 42);
    final teamId = world.teams.first.id;
    return CareerSave(
      id: 'test_save_1',
      saveName: 'Test Manager Profile',
      createdAt: DateTime(2026, 1, 1),
      lastSavedAt: DateTime(2026, 5, 14),
      difficulty: CareerDifficulty.normal,
      playerManagerName: 'Jan Kowalski',
      playerTeamId: teamId,
      currentDate: DateTime(2026, 5, 14),
      currentSeasonYear: 2026,
      calendar: const SeasonCalendar(seasonYear: 2026, races: []),
      teams: world.teams,
      riders: const [],
      managerReputation: 78,
      financeLedger: [
        CareerFinanceLedgerEntry(
          id: 'prize_1',
          date: DateTime(2026, 5, 14),
          category: FinanceCategory.racePrizeMoney,
          amountEur: 125000,
          description: 'Premia za zwycięstwo etapowe',
        ),
      ],
    );
  }

  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    required Size viewportSize,
    required CareerSave save,
    required AchievementAndMilestonesService service,
  }) async {
    tester.view.physicalSize = viewportSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careerProvider.overrideWith((_) => _TestCareerController(save)),
          achievementServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: ManagerProfileAndAchievementsScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ManagerProfileAndAchievementsScreen', () {
    testWidgets(
        'renders UCI license, terrain charts, and 45 achievements on desktop 1600x900',
        (tester) async {
      final save = buildTestSave();
      final service = AchievementAndMilestonesService()
        ..triggerUnlock(
          'first_victory',
          seasonYear: 2026,
          timestamp: DateTime(2026, 5, 14),
        );

      await pumpProfileScreen(
        tester,
        viewportSize: const Size(1600, 900),
        save: save,
        service: service,
      );

      expect(find.text('UCI • VIP DIRECTEUR SPORTIF'), findsOneWidget);
      expect(find.text('Jan Kowalski'), findsOneWidget);
      expect(find.text('78 / 100'), findsOneWidget);
      expect(find.text('Zwycięstwa Według Typu Terenu'), findsOneWidget);
      expect(find.text('Płaskie'), findsWidgets);
      expect(find.text('Pagórki'), findsWidgets);
      expect(find.text('Wysokie Góry'), findsOneWidget);
      expect(find.text('Bruki'), findsWidgets);
      expect(find.text('Czasówki'), findsWidgets);
      expect(find.textContaining('Osiągnięcia Kariery ('), findsOneWidget);
      expect(find.textContaining('/ 45)'), findsOneWidget);
      expect(find.text('Zdobyto: 14.05.2026'), findsWidgets);
    });

    testWidgets('filters achievements by tier', (tester) async {
      final save = buildTestSave();
      final service = AchievementAndMilestonesService();

      await pumpProfileScreen(
        tester,
        viewportSize: const Size(1024, 768),
        save: save,
        service: service,
      );

      final goldChip = find.textContaining('Gold (');
      await tester.ensureVisible(goldChip);
      await tester.tap(goldChip);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Bronze'), findsNothing);
    });

    testWidgets('renders without overflow on mobile 390x844', (tester) async {
      final save = buildTestSave();
      final service = AchievementAndMilestonesService();

      await pumpProfileScreen(
        tester,
        viewportSize: const Size(390, 844),
        save: save,
        service: service,
      );

      expect(find.text('Jan Kowalski'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
