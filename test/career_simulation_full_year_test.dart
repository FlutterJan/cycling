import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/services/career/finance_and_budget_service.dart';
import 'package:pro_peloton_manager/services/career/season_transition_service.dart';
import 'package:pro_peloton_manager/services/generators/initial_game_seeder.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel pathChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('Full Year Career Simulation (365x advanceDay)', () {
    test(
      'symuluje pełne 365 dni sezonu bez wyjątków null, z wypłatami pensji, transferami AI i przejściem sezonu',
      () async {
        const int startSeasonYear = 2026;
        const int simulationSeed = 20260101;

        final world = WorldTeamsGenerator.generateWorldTourSystem(
          seed: simulationSeed,
        );
        expect(world.teams, isNotEmpty);

        final playerTeamId = world.teams.first.id;

        final notifier = CareerStateNotifier();
        final seedResult = await InitialGameSeeder.seedAndInitializeCareer(
          careerNotifier: notifier,
          config: InitialGameSeedConfig(
            saveName: 'Full Year Integration Test',
            playerManagerName: 'Test Director',
            playerTeamId: playerTeamId,
            seasonYear: startSeasonYear,
            seed: simulationSeed,
            saveToDisk: false,
          ),
        );

        final DateTime initialDate = notifier.state.currentDate;
        final int initialLedgerCount = notifier.state.financeLedger.length;
        final int initialRidersCount = notifier.state.riders.length;

        expect(seedResult.totalTeamsCount, greaterThanOrEqualTo(18));
        expect(initialRidersCount, greaterThan(0));
        expect(notifier.state.errorMessage, isNull);
        expect(
          SeasonTransitionService.canPerformSeasonTransition(
            notifier.state.toSave(),
          ),
          isFalse,
        );

        CareerSave? lateSeasonSnapshotForTransition;
        bool checkedLateSeasonEligibility = false;

        // Symulacja pełnych 365 dni sezonu dzień po dniu
        for (int day = 1; day <= 365; day++) {
          await notifier.advanceDay(persistAutoSave: false);

          final currentState = notifier.state;
          expect(
            currentState.errorMessage,
            isNull,
            reason:
                'Dzień $day (${currentState.currentDate.toIso8601String()}) zgłosił błąd: ${currentState.errorMessage}',
          );
          expect(currentState.isLoading, isFalse);
          expect(currentState.playerTeam.id, equals(playerTeamId));
          expect(currentState.riders, isNotEmpty);
          expect(currentState.teams, isNotEmpty);

          // Weryfikacja daty każdego dnia
          final expectedDate = initialDate.add(Duration(days: day));
          expect(
            currentState.currentDate,
            equals(expectedDate),
            reason: 'Niezgodna data w dniu symulacji #$day',
          );

          // W listopadzie (po zakończeniu sezonu wyścigowego) zapisujemy stan do weryfikacji przejścia sezonu
          if (!checkedLateSeasonEligibility &&
              currentState.currentDate.month == 11 &&
              currentState.currentDate.day == 15) {
            final candidateSave = currentState.toSave();
            expect(
              SeasonTransitionService.canPerformSeasonTransition(candidateSave),
              isTrue,
              reason:
                  'W połowie listopada gra musi zezwalać na przejście do nowego sezonu.',
            );
            lateSeasonSnapshotForTransition = candidateSave;
            checkedLateSeasonEligibility = true;
          }
        }

        final finalState = notifier.state;

        // 1. Brak błędów i poprawne przekroczenie granicy roku po 365 dniach
        expect(finalState.errorMessage, isNull);
        expect(
          finalState.currentDate,
          equals(initialDate.add(const Duration(days: 365))),
        );
        expect(finalState.currentSeasonYear, equals(startSeasonYear + 1));
        expect(finalState.currentDate.year, equals(startSeasonYear + 1));

        // 2. Poprawność wypłat pensji (12 comiesięcznych rozliczeń w ciągu 365 dni)
        final newLedgerEntries =
            finalState.financeLedger.skip(initialLedgerCount).toList();
        final riderSalaryEntries = finalState.financeLedger
            .where((e) => e.category == FinanceCategory.riderSalaries)
            .toList();
        final staffSalaryEntries = finalState.financeLedger
            .where((e) => e.category == FinanceCategory.staffSalaries)
            .toList();
        final sponsorPayoutEntries = finalState.financeLedger
            .where((e) => e.category == FinanceCategory.sponsorPayout)
            .toList();

        expect(newLedgerEntries, isNotEmpty);
        expect(
          riderSalaryEntries.length,
          greaterThanOrEqualTo(12),
          reason: 'Oczekiwano co najmniej 12 miesięcznych wypłat pensji kolarzy.',
        );
        expect(
          staffSalaryEntries.length,
          greaterThanOrEqualTo(12),
          reason: 'Oczekiwano co najmniej 12 miesięcznych wypłat pensji sztabu.',
        );
        expect(
          sponsorPayoutEntries.length,
          greaterThanOrEqualTo(12),
          reason: 'Oczekiwano co najmniej 12 miesięcznych transz sponsorskich.',
        );

        for (final entry in riderSalaryEntries) {
          expect(entry.amountEur, lessThan(0));
          expect(entry.description, isNotEmpty);
        }
        for (final entry in staffSalaryEntries) {
          expect(entry.amountEur, lessThan(0));
          expect(entry.description, isNotEmpty);
        }

        final expectedMonthlyStaffPayroll =
            FinanceAndBudgetService.calculateStaffMonthlySalaries(
          finalState.playerTeam.staff,
        );
        expect(
          staffSalaryEntries.first.amountEur,
          equals(-expectedMonthlyStaffPayroll),
        );

        final financeInboxMessages = finalState.inboxMessages
            .where((m) => m.category == InboxCategory.finance)
            .toList();
        expect(financeInboxMessages.length, greaterThanOrEqualTo(12));

        // 3. Poprawność transferów AI i okna transferowego
        expect(
          finalState.triggeredOneTimeEventKeys,
          contains('transfer_window_open_$startSeasonYear'),
        );
        final transferWindowMessages = finalState.inboxMessages
            .where((m) => m.category == InboxCategory.transferMarket)
            .toList();
        expect(transferWindowMessages, isNotEmpty);
        expect(
          finalState.recentTransferNews,
          isNotEmpty,
          reason: 'Rynek AI powinien wygenerować transfery w oknie 01.08–15.11.',
        );
        for (final news in finalState.recentTransferNews) {
          expect(news.riderId, isNotEmpty);
          expect(news.riderName, isNotEmpty);
          expect(news.toTeamId, isNotEmpty);
          expect(news.toTeamName, isNotEmpty);
          expect(news.tickerHeadline, isNotEmpty);
        }

        // 4. Przejście do nowego sezonu przez SeasonTransitionService
        expect(checkedLateSeasonEligibility, isTrue);
        expect(lateSeasonSnapshotForTransition, isNotNull);

        final transitionResult = SeasonTransitionService.executeSeasonTransition(
          lateSeasonSnapshotForTransition!,
          random: math.Random(simulationSeed),
        );

        final nextSeasonSave = transitionResult.updatedSave;
        final report = transitionResult.report;

        expect(report.oldSeasonYear, equals(startSeasonYear));
        expect(report.newSeasonYear, equals(startSeasonYear + 1));
        expect(nextSeasonSave.currentSeasonYear, equals(startSeasonYear + 1));
        expect(
          nextSeasonSave.currentDate,
          equals(DateTime(startSeasonYear + 1, 1, 1)),
        );
        expect(
          nextSeasonSave.calendar.seasonYear,
          equals(startSeasonYear + 1),
        );
        expect(nextSeasonSave.calendar.races, isNotEmpty);
        expect(nextSeasonSave.riders, isNotEmpty);
        expect(nextSeasonSave.teams, isNotEmpty);
        expect(
          report.newTalentsGeneratedCount,
          equals(SeasonTransitionService.defaultNewTalentsWaveCount),
        );

        // Wczytanie nowego sezonu z powrotem do CareerStateNotifier i symulacja 1. dnia nowego roku
        notifier.loadFromCareerSave(nextSeasonSave);
        expect(notifier.state.currentSeasonYear, equals(startSeasonYear + 1));
        expect(notifier.state.errorMessage, isNull);

        await notifier.advanceDay(persistAutoSave: false);
        expect(notifier.state.errorMessage, isNull);
        expect(
          notifier.state.currentDate,
          equals(DateTime(startSeasonYear + 1, 1, 2)),
        );
      },
    );
  });
}
