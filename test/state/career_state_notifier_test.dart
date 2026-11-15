import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/recovery_protocol_system.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/team/sponsor_contract.dart';
import 'package:pro_peloton_manager/services/career/sponsor_objectives_evaluator.dart';
import 'package:pro_peloton_manager/services/career/training_and_camps_service.dart';
import 'package:pro_peloton_manager/services/generators/initial_game_seeder.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  Future<CareerSave> createSeededSave({DateTime? overrideDate}) async {
    const config = InitialGameSeedConfig(
      saveName: 'Test Career Loop',
      playerManagerName: 'Jan Kowalski',
      playerTeamId: 'team_aethel_ineos',
      difficulty: CareerDifficulty.normal,
      seasonYear: 2026,
      seed: 101,
      saveToDisk: false,
    );
    final result = await InitialGameSeeder.seedNewGame(config);
    if (overrideDate != null) {
      return result.save.copyWith(currentDate: overrideDate);
    }
    return result.save;
  }

  group('CareerStateNotifier — Daily Loop & Simulation Tests', () {
    test('advanceDay aktualizuje CTL/ATL/TSB, leczy kontuzje z bonusem medycznym i aplikuje sesje regeneracyjne', () async {
      final baseSave = await createSeededSave(overrideDate: DateTime(2026, 3, 10));
      final playerRider = baseSave.playerRoster.first;
      final injuredRider = playerRider.copyWith(
        health: playerRider.health.copyWith(
          acuteTrainingLoad: 70.0,
          chronicTrainingLoad: 85.0,
          currentInjury: const Injury(
            name: 'Szlif powypadkowy',
            type: InjuryType.roadRash,
            daysRemaining: 2,
            trainingAllowed: true,
          ),
        ),
      );
      final save = baseSave.copyWith(medicalCenterLevel: 4).updateRider(injuredRider);
      // Upewniamy się, że lekarz ma >= 80 dla bonusu 2x leczenia
      final boostedTeams = save.teams.map((t) {
        if (t.id == save.playerTeamId) {
          return t.copyWith(staff: t.staff.copyWith(doctorsLevel: 85));
        }
        return t;
      }).toList();

      final notifier = CareerStateNotifier()
        ..loadFromCareerSave(save.copyWith(teams: boostedTeams));

      notifier.scheduleRecoverySession(
        riderId: playerRider.id,
        protocolType: RecoveryProtocolType.hyperbaricOxygenTherapy,
      );

      await notifier.advanceDay(persistAutoSave: false);

      expect(notifier.state.currentDate, DateTime(2026, 3, 11));
      final updatedPlayer = notifier.state.riders.firstWhere((r) => r.id == playerRider.id);
      // Kontuzja 2 dni przy medCenterLevel=4 i doctorsLevel=85 zostaje wyleczona w 1 dzień
      expect(updatedPlayer.health.currentInjury, isNull);
      // HBOT obniża ATL poniżej bazowej wartości 70
      expect(updatedPlayer.health.acuteTrainingLoad, lessThan(70.0));
      expect(notifier.state.scheduledRecoverySessions, isEmpty);
      expect(
        notifier.state.inboxMessages.any((m) => m.category == InboxCategory.medicalReport),
        isTrue,
      );
    });

    test('advanceDay przetwarza obozy wysokogórskie, zużycie sprzętu i symulację wyścigów AI', () async {
      final baseSave = await createSeededSave();
      // Znajdź pierwszy wyścig w kalendarzu bez udziału drużyny gracza lub stwórz kontekst na jego datę zakończenia
      final nonPlayerRace = baseSave.calendar.races.firstWhere(
        (r) => !r.participatingTeamIds.contains(baseSave.playerTeamId),
        orElse: () => baseSave.calendar.races.first,
      );
      final dayBeforeEnd = nonPlayerRace.endDate.subtract(const Duration(days: 1));
      final save = baseSave.copyWith(currentDate: dayBeforeEnd);

      final notifier = CareerStateNotifier()..loadFromCareerSave(save);
      final playerRider = notifier.state.playerRoster.first;

      notifier.enrollRidersInAltitudeCamp(
        location: const AltitudeCampLocation(
          id: 'camp_teide',
          name: 'Mount Teide',
          countryIso: 'ESP',
          altitudeMeters: 2150,
          costPerRiderPerDayEur: 280,
          vo2maxBoostPct: 2.8,
          ftpGainWatts: 11,
          atlFatigueDaily: 3.4,
          description: 'Obóz wulkaniczny na Teneryfie',
        ),
        riderIds: [playerRider.id],
        durationDays: 1,
      );

      await notifier.advanceDay(persistAutoSave: false);

      expect(notifier.state.activeTrainingCamps, isEmpty);
      expect(
        notifier.state.inboxMessages.any((m) => m.category == InboxCategory.trainingUpdate),
        isTrue,
      );

      if (!nonPlayerRace.participatingTeamIds.contains(baseSave.playerTeamId)) {
        expect(notifier.state.calendar.isRaceCompleted(nonPlayerRace.id), isTrue);
        expect(notifier.state.calendar.raceHistory.containsKey(nonPlayerRace.id), isTrue);
      }
    });

    test('Wyzwalacze specjalne: 1 sierpnia okno transferowe, rozliczenie miesięczne, raport U23, konferencja przed GT i cele sponsorskie', () async {
      // 1) 31 lipca -> 1 sierpnia: otwarcie okna transferowego + miesięczne rozliczenie
      final saveTransfer = await createSeededSave(overrideDate: DateTime(2026, 7, 31));
      final notifierTransfer = CareerStateNotifier()..loadFromCareerSave(saveTransfer);
      await notifierTransfer.advanceDay(persistAutoSave: false);

      expect(notifierTransfer.state.currentDate, DateTime(2026, 8, 1));
      expect(
        notifierTransfer.state.inboxMessages.any(
          (m) => m.category == InboxCategory.transferMarket && m.priority == InboxPriority.urgent,
        ),
        isTrue,
      );
      expect(
        notifierTransfer.state.inboxMessages.any((m) => m.category == InboxCategory.finance),
        isTrue,
      );

      // 2) 1 dzień przed Grand Tourem z udziałem gracza -> konferencja prasowa + raport U23 10. dnia miesiąca
      final grandTour = saveTransfer.calendar.races.firstWhere(
        (r) => r.uciCategory == RaceCategory.grandTour && r.participatingTeamIds.contains(saveTransfer.playerTeamId),
      );
      final twoDaysBeforeGt = grandTour.startDate.subtract(const Duration(days: 2));
      final savePreGt = saveTransfer.copyWith(currentDate: twoDaysBeforeGt);
      final notifierGt = CareerStateNotifier()..loadFromCareerSave(savePreGt);
      await notifierGt.advanceDay(persistAutoSave: false);

      expect(notifierGt.state.pendingPressConferences, isNotEmpty);

      // Test raportu U23 w 10. dniu miesiąca
      final saveBefore10 = saveTransfer.copyWith(currentDate: DateTime(2026, 5, 9));
      final notifierU23 = CareerStateNotifier()..loadFromCareerSave(saveBefore10);
      await notifierU23.advanceDay(persistAutoSave: false);
      expect(
        notifierU23.state.inboxMessages.any((m) => m.actionLabel == 'Otwórz Akademię U23'),
        isTrue,
      );

      // 3) Ewaluacja celów sponsorskich po wyścigu
      final teamWithObjective = notifierGt.state.playerTeam.copyWith(
        sponsors: const [
          SponsorContract(
            id: 'sp_test_1',
            companyName: 'Orlen Apex',
            industry: SponsorIndustry.energy,
            sponsorTier: SponsorTier.titlePrimary,
            annualBudgetEur: 5000000,
            contractDurationYears: 2,
            sponsorSatisfaction: 70.0,
            objectives: [
              SponsorObjective(
                id: 'obj_monument_podium',
                description: 'Podium w Monumencie',
                importance: ObjectiveImportance.high,
                targetProgress: 1.0,
                currentProgress: 0.0,
                isCompleted: false,
                bonusPaymentEur: 250000,
              ),
            ],
          ),
        ],
      );
      final saveWithObj = notifierGt.state.rawSave!.copyWith(
        teams: notifierGt.state.teams
            .map((t) => t.id == notifierGt.state.playerTeamId ? teamWithObjective : t)
            .toList(),
      );
      notifierGt.loadFromCareerSave(saveWithObj);
      final initialCash = notifierGt.state.playerTeam.cashBalanceEur;

      final evalRes = notifierGt.evaluatePostRaceObjectives(
        PostRaceSponsorContext(
          raceId: 'monument_1',
          raceName: 'Il Lombardia',
          raceCategory: RaceCategory.monument,
          raceDate: DateTime(2026, 10, 10),
          bestPlayerStageRank: 2,
          topFinishingRiderName: 'Lider Zespołu',
        ),
      );
      expect(evalRes.totalBonusesPaidEur, 250000);
      expect(notifierGt.state.playerTeam.cashBalanceEur, initialCash + 250000);
    });

    test('simulateUntilNextStop oraz advanceToNextEvent zatrzymują się przed wyścigiem gracza i zliczają dni', () async {
      final baseSave = await createSeededSave();
      final playerRace = baseSave.calendar.races.firstWhere(
        (r) => r.participatingTeamIds.contains(baseSave.playerTeamId),
      );
      final threeDaysBefore = playerRace.startDate.subtract(const Duration(days: 3));
      final save = baseSave.copyWith(currentDate: threeDaysBefore);

      final notifier = CareerStateNotifier()..loadFromCareerSave(save);

      final stopReason = await notifier.simulateUntilNextStop(
        maxDays: 10,
        stepDelay: Duration.zero,
      );

      expect(
        stopReason == SimulationStopReason.raceDay ||
            stopReason == SimulationStopReason.urgentDecisionEmail ||
            stopReason == SimulationStopReason.transferOffer,
        isTrue,
      );
      expect(notifier.state.fastForwardDaysSimulated, greaterThanOrEqualTo(1));
      expect(notifier.state.fastForwardDaysSimulated, lessThanOrEqualTo(3));
      expect(notifier.state.isFastForwarding, isFalse);
    });
  });
}
