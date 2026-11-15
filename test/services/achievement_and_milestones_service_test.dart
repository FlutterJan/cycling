import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/season_calendar.dart';
import 'package:pro_peloton_manager/models/team/bike_manufacturer_deal.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/achievement_and_milestones_service.dart';
import 'package:pro_peloton_manager/ui/widgets/achievement_unlock_toast_overlay.dart';

CareerSave _createDummySave({
  TeamDivision division = TeamDivision.continental,
  int cashBalanceEur = 1200000,
  int managerReputation = 55,
  int windTunnelLevel = 1,
  int serviceCourseLevel = 1,
  int medicalCenterLevel = 1,
}) {
  final team = CyclingTeam(
    id: 'team_player',
    name: 'Polonia Pro Cycling',
    division: division,
    countryIso: 'POL',
    primaryJerseyColorHex: '#8E4A49',
    secondaryJerseyColorHex: '#D4AF37',
    accentJerseyColorHex: '#FFFFFF',
    cashBalanceEur: cashBalanceEur,
    monthlyBurnRateEur: 90000,
    uciPointsSeason: 450,
    rosterRiderIds: const [],
    staff: const TeamStaff(
      trainersLevel: 60,
      sportsDirectorsLevel: 65,
      doctorsLevel: 60,
      mechanicsLevel: 65,
      scoutsLevel: 60,
    ),
    bikeDeal: const BikeManufacturerDeal(
      manufacturerId: 'romet_carbon',
      manufacturerName: 'Romet Carbon',
      prestigeLevel: 3,
      annualCashContributionEur: 150000,
      freeBikesQuota: 40,
      researchAndDevelopmentLevel: 65,
      suppliedFrameIds: ['frame_1'],
      suppliedWheelsetIds: ['wheel_1'],
      contractYearsLeft: 2,
      minimumUciRankingRequired: 20,
    ),
    sponsors: const [],
    inventoryBikes: const [],
  );

  return CareerSave(
    id: 'save_test',
    saveName: 'Test Career',
    createdAt: DateTime(2026, 1, 1),
    lastSavedAt: DateTime(2026, 4, 10),
    difficulty: CareerDifficulty.normal,
    playerManagerName: 'Jan Kowalski',
    playerTeamId: team.id,
    currentDate: DateTime(2026, 4, 10),
    currentSeasonYear: 2026,
    calendar: const SeasonCalendar(seasonYear: 2026, races: []),
    teams: [team],
    riders: const [],
    managerReputation: managerReputation,
    windTunnelLevel: windTunnelLevel,
    serviceCourseLevel: serviceCourseLevel,
    medicalCenterLevel: medicalCenterLevel,
  );
}

void main() {
  group('AchievementAndMilestonesService', () {
    test('zawiera dokładnie 45 zdefiniowanych osiągnięć w 4 rangach', () {
      expect(AchievementAndMilestonesService.definitions.length, 45);

      final ids = AchievementAndMilestonesService.definitions
          .map((e) => e.id)
          .toSet();
      expect(ids.length, 45);

      for (final tier in AchievementTier.values) {
        final count = AchievementAndMilestonesService.definitions
            .where((d) => d.tier == tier)
            .length;
        expect(count, greaterThan(0), reason: 'Brak osiągnięć rangi $tier');
      }
    });

    test('odblokowuje kluczowe wyzwania etapowe i emituje zdarzenia na strumieniu',
        () async {
      final service = AchievementAndMilestonesService();
      addTearDown(service.dispose);

      final emittedEvents = <AchievementUnlockEvent>[];
      final sub = service.unlockStream.listen(emittedEvents.add);
      addTearDown(sub.cancel);

      final save = _createDummySave();

      // 1. Solo z Daleka (>50 km) + Mistrz Rantów (>120s w rantach) + Król Piekła Północy
      final unlocked = service.evaluateAfterStage(
        save: save,
        stageContext: const StageEvaluationContext(
          raceId: 'paris_roubaix',
          raceName: 'Paris-Roubaix',
          stageWon: true,
          isMonument: true,
          isCobbleMonument: true,
          isRainy: true,
          bikeChanges: 0,
          soloAttackDistanceKm: 54.2,
          echelonSplitAchieved: true,
          gapOverGcRivalSeconds: 145,
          wonWithZeroCrashes: true,
        ),
      );

      final unlockedIds = unlocked.map((e) => e.achievement.id).toSet();
      expect(unlockedIds, contains('solo_from_afar'));
      expect(unlockedIds, contains('echelon_master'));
      expect(unlockedIds, contains('king_of_hell_north'));
      expect(unlockedIds, contains('first_victory'));

      // Ponowna ewaluacja tego samego etapu nie powinna duplikować odblokowań
      final secondRun = service.evaluateAfterStage(
        save: save,
        stageContext: const StageEvaluationContext(
          raceId: 'paris_roubaix',
          raceName: 'Paris-Roubaix',
          stageWon: true,
          isMonument: true,
          isCobbleMonument: true,
          isRainy: true,
          bikeChanges: 0,
          soloAttackDistanceKm: 54.2,
          echelonSplitAchieved: true,
          gapOverGcRivalSeconds: 145,
        ),
      );
      expect(secondRun, isEmpty);

      await pumpEventQueue();
      expect(emittedEvents.length, unlocked.length);
    });

    test('odblokowuje Inżynier Watów (CdA < 0.190) i Od Zera do WorldTouru',
        () {
      final service = AchievementAndMilestonesService();
      addTearDown(service.dispose);

      final save = _createDummySave(division: TeamDivision.worldTour);

      final aeroEvents = service.evaluateClubAndAero(
        save: save,
        testedCdaM2: 0.186,
      );
      expect(
        aeroEvents.any((e) => e.achievement.id == 'watt_engineer_cda'),
        isTrue,
      );

      final seasonEvents = service.evaluateAfterSeason(
        save: save,
        seasonContext: const SeasonEvaluationContext(
          seasonYear: 2029,
          startedDivision: TeamDivision.continental,
          currentDivision: TeamDivision.worldTour,
          promotedToWorldTour: true,
          grandTourGcWins: 1,
          seasonTotalWins: 18,
          sponsorObjectivesCompletedRatio: 1.0,
        ),
      );

      final seasonIds = seasonEvents.map((e) => e.achievement.id).toSet();
      expect(seasonIds, contains('from_zero_to_worldtour'));
      expect(seasonIds, contains('first_grand_tour_gc'));
      expect(seasonIds, contains('sponsor_perfection'));
    });

    test('serializacja toJson i loadFromJson zachowuje stan odblokowań', () {
      final service = AchievementAndMilestonesService();
      addTearDown(service.dispose);

      service.triggerUnlock('watt_engineer_cda', seasonYear: 2027);
      final json = service.toJson();

      final restored = AchievementAndMilestonesService();
      addTearDown(restored.dispose);
      restored.loadFromJson(json);

      expect(restored.isUnlocked('watt_engineer_cda'), isTrue);
      expect(restored.unlockedCount, 1);
      expect(restored.totalPoints, AchievementTier.gold.points);
    });
  });

  group('AchievementUnlockToastOverlay UI', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'wyświetla animowany toast ze złotym blaskiem bez overflow (${size.width.toInt()}x${size.height.toInt()})',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final service = AchievementAndMilestonesService();
          addTearDown(service.dispose);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                achievementServiceProvider.overrideWithValue(service),
              ],
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const AchievementUnlockToastOverlay(
                  displayDuration: Duration(seconds: 5),
                  child: Scaffold(
                    backgroundColor: AppColors.background,
                    body: Center(child: Text('Kariera')),
                  ),
                ),
              ),
            ),
          );

          service.triggerUnlock('solo_from_afar', seasonYear: 2026);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));

          expect(find.text('Solo z Daleka'), findsOneWidget);
          expect(find.text('+30 PKT'), findsOneWidget);
          expect(find.byType(AchievementTrophyToastBanner), findsOneWidget);

          // Zamknięcie toasta przyciskiem X
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(AchievementTrophyToastBanner), findsNothing);
        },
      );
    }
  });
}
