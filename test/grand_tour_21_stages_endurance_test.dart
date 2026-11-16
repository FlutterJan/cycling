import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/events/race_incident_engine.dart';
import 'package:pro_peloton_manager/engine/physics/grand_tour_third_week_fatigue_decay.dart';
import 'package:pro_peloton_manager/engine/simulation/post_stage_recovery_processor.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/tour_race.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/generators/uci_calendar_generator.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

/// Pomocniczy akumulator klasyfikacji Wielkiego Touru po każdym etapie.
class _GrandTourStandingsLedger {
  final Map<String, int> gcSecondsByRider = {};
  final Map<String, int> rawOfficialSecondsByRider = {};
  final Map<String, int> bonusSecondsByRider = {};
  final Map<String, int> sprintPointsByRider = {};
  final Map<String, int> komPointsByRider = {};
  final Set<String> eliminatedRiderIds = {};
  final Map<String, int> eliminatedOnStage = {};

  void registerInitialRiders(Iterable<Rider> riders) {
    for (final rider in riders) {
      gcSecondsByRider[rider.id] = 0;
      rawOfficialSecondsByRider[rider.id] = 0;
      bonusSecondsByRider[rider.id] = 0;
      sprintPointsByRider[rider.id] = 0;
      komPointsByRider[rider.id] = 0;
    }
  }

  void applyStageReport({
    required int stageNumber,
    required StageSummaryReport report,
  }) {
    for (final result in report.results) {
      if (eliminatedRiderIds.contains(result.riderId)) {
        continue;
      }

      if (result.isEliminatedOtl || result.isDnf) {
        eliminatedRiderIds.add(result.riderId);
        eliminatedOnStage[result.riderId] = stageNumber;
        continue;
      }

      final int stageOfficialSec = result.officialFinishTimeSeconds.round();
      final int bonusSec = result.timeBonusSeconds;

      rawOfficialSecondsByRider[result.riderId] =
          (rawOfficialSecondsByRider[result.riderId] ?? 0) + stageOfficialSec;
      bonusSecondsByRider[result.riderId] =
          (bonusSecondsByRider[result.riderId] ?? 0) + bonusSec;
      gcSecondsByRider[result.riderId] =
          (gcSecondsByRider[result.riderId] ?? 0) +
              (stageOfficialSec - bonusSec);

      sprintPointsByRider[result.riderId] =
          (sprintPointsByRider[result.riderId] ?? 0) + result.pointsGreenJersey;
      komPointsByRider[result.riderId] =
          (komPointsByRider[result.riderId] ?? 0) + result.pointsKom;
    }
  }

  RaceClassifications buildClassifications({
    required Map<String, Rider> allRidersById,
    required Map<String, CyclingTeam> teamsById,
  }) {
    final activeIds = allRidersById.keys
        .where((id) => !eliminatedRiderIds.contains(id))
        .toList();

    // 1. Klasyfikacja Generalna (GC)
    final gcSortedIds = List<String>.from(activeIds)
      ..sort((a, b) {
        final cmp =
            (gcSecondsByRider[a] ?? 0).compareTo(gcSecondsByRider[b] ?? 0);
        return cmp != 0 ? cmp : a.compareTo(b);
      });
    final int leaderTime =
        gcSortedIds.isNotEmpty ? (gcSecondsByRider[gcSortedIds.first] ?? 0) : 0;

    final gcEntries = <RiderClassificationEntry>[];
    for (int i = 0; i < gcSortedIds.length; i++) {
      final id = gcSortedIds[i];
      final rider = allRidersById[id]!;
      final totalSec = gcSecondsByRider[id] ?? 0;
      gcEntries.add(
        RiderClassificationEntry(
          riderId: id,
          riderName: rider.fullName,
          teamId: rider.contract.teamId,
          totalTimeSeconds: totalSec,
          points: 0,
          rank: i + 1,
          timeBehindLeaderSeconds: totalSec - leaderTime,
        ),
      );
    }

    // 2. Klasyfikacja Punktowa (Sprint / Zielona koszulka)
    final sprintSortedIds = List<String>.from(activeIds)
      ..sort((a, b) {
        final cmp = (sprintPointsByRider[b] ?? 0)
            .compareTo(sprintPointsByRider[a] ?? 0);
        return cmp != 0 ? cmp : a.compareTo(b);
      });
    final pointsEntries = <RiderClassificationEntry>[];
    for (int i = 0; i < sprintSortedIds.length; i++) {
      final id = sprintSortedIds[i];
      final rider = allRidersById[id]!;
      pointsEntries.add(
        RiderClassificationEntry(
          riderId: id,
          riderName: rider.fullName,
          teamId: rider.contract.teamId,
          totalTimeSeconds: gcSecondsByRider[id] ?? 0,
          points: sprintPointsByRider[id] ?? 0,
          rank: i + 1,
          timeBehindLeaderSeconds: 0,
        ),
      );
    }

    // 3. Klasyfikacja Górska (KOM / Grochy)
    final komSortedIds = List<String>.from(activeIds)
      ..sort((a, b) {
        final cmp =
            (komPointsByRider[b] ?? 0).compareTo(komPointsByRider[a] ?? 0);
        return cmp != 0 ? cmp : a.compareTo(b);
      });
    final komEntries = <RiderClassificationEntry>[];
    for (int i = 0; i < komSortedIds.length; i++) {
      final id = komSortedIds[i];
      final rider = allRidersById[id]!;
      komEntries.add(
        RiderClassificationEntry(
          riderId: id,
          riderName: rider.fullName,
          teamId: rider.contract.teamId,
          totalTimeSeconds: gcSecondsByRider[id] ?? 0,
          points: komPointsByRider[id] ?? 0,
          rank: i + 1,
          timeBehindLeaderSeconds: 0,
        ),
      );
    }

    // 4. Klasyfikacja Młodzieżowa (U25)
    final youthEntries = gcEntries
        .where((e) => (allRidersById[e.riderId]?.age ?? 99) <= 25)
        .toList();
    final int youthLeaderTime =
        youthEntries.isNotEmpty ? youthEntries.first.totalTimeSeconds : 0;
    final rankedYouth = <RiderClassificationEntry>[];
    for (int i = 0; i < youthEntries.length; i++) {
      final e = youthEntries[i];
      rankedYouth.add(
        e.copyWith(
          rank: i + 1,
          timeBehindLeaderSeconds: e.totalTimeSeconds - youthLeaderTime,
        ),
      );
    }

    // 5. Klasyfikacja Drużynowa (suma 3 najlepszych aktywnych kolarzy drużyny)
    final Map<String, List<int>> teamRiderTimes = {};
    for (final entry in gcEntries) {
      teamRiderTimes.putIfAbsent(entry.teamId, () => []).add(entry.totalTimeSeconds);
    }
    final teamTotals = <({String teamId, int totalTime})>[];
    for (final kv in teamRiderTimes.entries) {
      final times = List<int>.from(kv.value)..sort();
      if (times.length >= 3) {
        teamTotals.add((
          teamId: kv.key,
          totalTime: times[0] + times[1] + times[2],
        ));
      }
    }
    teamTotals.sort((a, b) => a.totalTime.compareTo(b.totalTime));
    final int bestTeamTime =
        teamTotals.isNotEmpty ? teamTotals.first.totalTime : 0;
    final teamEntries = <TeamClassificationEntry>[];
    for (int i = 0; i < teamTotals.length; i++) {
      final t = teamTotals[i];
      teamEntries.add(
        TeamClassificationEntry(
          teamId: t.teamId,
          teamName: teamsById[t.teamId]?.name ?? t.teamId,
          totalTimeSeconds: t.totalTime,
          rank: i + 1,
          timeBehindLeaderSeconds: t.totalTime - bestTeamTime,
        ),
      );
    }

    return RaceClassifications(
      generalClassification: gcEntries,
      pointsClassification: pointsEntries,
      mountainsClassification: komEntries,
      youthClassification: rankedYouth,
      teamClassification: teamEntries,
    );
  }
}

/// Aplikuje regenerację dnia przerwy (np. Coffee Ride + masaż + sen) do zdrowia kolarzy.
Map<String, Rider> _applyRestDayRecovery(Map<String, Rider> ridersById) {
  final updated = <String, Rider>{};
  for (final entry in ridersById.entries) {
    final rider = entry.value;
    final currentHealth = rider.health;
    // Dzień przerwy redukuje ATL o ~28% (zależnie od recoveryRate) i poprawia morale
    final double recoveryFactor =
        (0.24 + (rider.physiology.recoveryRate - 0.9) * 0.12).clamp(0.18, 0.38);
    final double newAtl =
        (currentHealth.acuteTrainingLoad * (1.0 - recoveryFactor))
            .clamp(5.0, 200.0);
    final double newCtl =
        (currentHealth.chronicTrainingLoad * 0.99).clamp(20.0, 200.0);
    final double newMorale =
        (currentHealth.morale + 4.0).clamp(0.0, 100.0);

    updated[entry.key] = rider.copyWith(
      health: currentHealth.copyWith(
        acuteTrainingLoad: newAtl,
        chronicTrainingLoad: newCtl,
        morale: newMorale,
      ),
    );
  }
  return updated;
}

void main() {
  late WorldTourGenerationResult world;
  late TourRace grandTour;
  late Map<String, CyclingTeam> teamsById;
  late Map<String, Rider> baseRidersById;
  late Map<String, RiderPhysiology> basePhysiologyById;
  late Map<String, CompleteBike> bikesById;

  setUpAll(() {
    world = WorldTeamsGenerator.generateWorldTourSystem(seed: 20260701);
    final grandTours = UciCalendarGenerator.getGrandTours(seasonYear: 2026);
    grandTour = grandTours.firstWhere(
      (r) => r.id.contains('tdf') || r.stages.length == 21,
      orElse: () => grandTours.first,
    );

    // Wybieramy 3 drużyny WorldTour po 6 kolarzy (łącznie 18 kolarzy) dla szybkiej i pełnej symulacji 21 etapów.
    final selectedTeams = world.worldTourTeams.take(3).toList();
    teamsById = {for (final t in selectedTeams) t.id: t};

    baseRidersById = {};
    basePhysiologyById = {};
    bikesById = {};

    for (int tIdx = 0; tIdx < selectedTeams.length; tIdx++) {
      final team = selectedTeams[tIdx];
      final roster = List<Rider>.from(world.ridersByTeamId[team.id] ?? [])
        ..sort((a, b) => b.physiology.wattsPerKg.compareTo(a.physiology.wattsPerKg));
      final squad = roster.take(6).toList();
      final bike = team.inventoryBikes.first;

      for (int rIdx = 0; rIdx < squad.length; rIdx++) {
        Rider rider = squad[rIdx];
        // Zapewniamy wyraźną reprezentację trzech profili odporności na 3. tydzień:
        // - rIdx == 0: Lider GC (Grand Tour Specialist, recoveryRate >= 1.28)
        // - rIdx == 1: Klasykowiec / Puncheur (One-Day Specialist, recoveryRate <= 0.90, wysokie W/kg by przetrwać góry)
        // - rIdx == 2..3: All-Rounder / Pomocnik (recoveryRate ~1.05..1.12)
        // - rIdx == 4..5: Pomocnik / Sprinter (recoveryRate ~1.00)
        final double targetRecoveryRate = switch (rIdx) {
          0 => 1.32,
          1 => 0.90,
          2 => 1.12,
          3 => 1.06,
          4 => 1.02,
          _ => 1.00,
        };

        rider = rider.copyWith(
          physiology: rider.physiology.copyWith(
            recoveryRate: targetRecoveryRate,
          ),
          health: rider.health.copyWith(
            acuteTrainingLoad: 55.0,
            chronicTrainingLoad: 85.0,
            morale: 78.0,
          ),
        );

        baseRidersById[rider.id] = rider;
        basePhysiologyById[rider.id] = rider.physiology;
        bikesById[rider.id] = bike;
      }
    }
  });

  group('Test wytrzymałościowy Wielkiego Touru (21 etapów + 2 dni przerwy)', () {
    test(
      'Przeprowadza 21 kolejnych etapów z 2 dniami przerwy, weryfikując GC, bonifikaty, KOM/Sprint, OTL/DNF oraz zmęczenie 3. tygodnia',
      () {
        expect(grandTour.isGrandTour, isTrue);
        expect(grandTour.stages.length, 21);
        expect(baseRidersById.length, 18);

        final ledger = _GrandTourStandingsLedger();
        ledger.registerInitialRiders(baseRidersById.values);

        // Identyfikujemy konkretnych kolarzy do asercji:
        final allInitialIds = baseRidersById.keys.toList();
        final gtSpecialistId = baseRidersById.values
            .firstWhere((r) => r.physiology.recoveryRate >= 1.25)
            .id;
        final oneDaySpecialistId = baseRidersById.values
            .firstWhere((r) => r.physiology.recoveryRate <= 0.95)
            .id;
        final otlCandidateId = allInitialIds.last; // tIdx == 2, rIdx == 5 (najniższe FTP)
        final dnfCandidateId = allInitialIds[allInitialIds.length - 2];

        Map<String, Rider> currentRiders = Map<String, Rider>.from(baseRidersById);
        TourRace activeTour = grandTour;

        bool sawFlatTimeBonuses = false;
        bool sawIttZeroBonuses = false;
        bool sawSummitKomPoints = false;
        bool sawOtlElimination = false;
        bool sawDnfElimination = false;
        int restDaysExecuted = 0;

        double? atlBeforeRestDay1;
        double? atlAfterRestDay1;
        double? atlBeforeRestDay2;
        double? atlAfterRestDay2;

        // Zapisujemy przebieg spadku FTP w 3. tygodniu
        final Map<int, double> gtSpecialistDecayByStage = {};
        final Map<int, double> oneDaySpecialistDecayByStage = {};

        for (int idx = 0; idx < grandTour.stages.length; idx++) {
          final RaceStage stage = grandTour.stages[idx];
          final int stageNumber = stage.stageNumber;
          expect(stageNumber, idx + 1);

          // 1. Dzień przerwy nr 1 po etapie 9 (przed etapem 10)
          if (stageNumber == 10) {
            atlBeforeRestDay1 = currentRiders[gtSpecialistId]!.health.acuteTrainingLoad;
            currentRiders = _applyRestDayRecovery(currentRiders);
            atlAfterRestDay1 = currentRiders[gtSpecialistId]!.health.acuteTrainingLoad;
            restDaysExecuted++;

            expect(atlAfterRestDay1, lessThan(atlBeforeRestDay1));
            expect(
              currentRiders[gtSpecialistId]!.health.trainingStressBalance,
              greaterThan(
                currentRiders[gtSpecialistId]!.health.chronicTrainingLoad -
                    atlBeforeRestDay1,
              ),
            );
          }

          // 2. Dzień przerwy nr 2 po etapie 15 (przed etapem 16)
          if (stageNumber == 16) {
            atlBeforeRestDay2 = currentRiders[gtSpecialistId]!.health.acuteTrainingLoad;
            currentRiders = _applyRestDayRecovery(currentRiders);
            atlAfterRestDay2 = currentRiders[gtSpecialistId]!.health.acuteTrainingLoad;
            restDaysExecuted++;

            expect(atlAfterRestDay2, lessThan(atlBeforeRestDay2));
          }

          // Rejestrujemy krzywą zmęczenia 3. tygodnia dla obu profili referencyjnych (etapy 1–21)
          gtSpecialistDecayByStage[stageNumber] =
              GrandTourThirdWeekFatigueDecay.evaluate(
            stageNumber: stageNumber,
            recoveryRate: basePhysiologyById[gtSpecialistId]!.recoveryRate,
          ).thresholdPowerDecayPercent;
          oneDaySpecialistDecayByStage[stageNumber] =
              GrandTourThirdWeekFatigueDecay.evaluate(
            stageNumber: stageNumber,
            recoveryRate: basePhysiologyById[oneDaySpecialistId]!.recoveryRate,
          ).thresholdPowerDecayPercent;

          // 3. Aplikacja modelu zmęczenia 3. tygodnia (etapy 14–21) przed startem etapu
          final activeRidersForStage = <String, Rider>{};
          final activeBikesForStage = <String, CompleteBike>{};

          for (final entry in currentRiders.entries) {
            if (ledger.eliminatedRiderIds.contains(entry.key)) continue;

            final basePhys = basePhysiologyById[entry.key]!;
            final thirdWeekFatigue = GrandTourThirdWeekFatigueDecay.evaluate(
              stageNumber: stageNumber,
              recoveryRate: basePhys.recoveryRate,
            );

            final fatiguedPhysiology = thirdWeekFatigue.applyToPhysiology(basePhys);
            final updatedRider = entry.value.copyWith(
              physiology: fatiguedPhysiology,
            );
            activeRidersForStage[entry.key] = updatedRider;
            activeBikesForStage[entry.key] = bikesById[entry.key]!;
          }

          // 4. Symulacja etapu w StageSimulationLoop (krok dt=15s dla szybkości i deterministyczności)
          final loop = StageSimulationLoop.initializeStage(
            stage: stage,
            playerTeamId: teamsById.keys.first,
            allRidersMap: activeRidersForStage,
            allBikesMap: activeBikesForStage,
            allTeamsMap: teamsById,
            random: math.Random(202600 + stageNumber),
          );

          int safetySteps = 0;
          while (!loop.state.isStageFinished && safetySteps < 4000) {
            loop.step(dt: 15.0);
            safetySteps++;
          }
          expect(
            loop.state.isStageFinished,
            isTrue,
            reason: 'Etap $stageNumber (${stage.name}) powinien ukończyć symulację.',
          );

          // Przygotowujemy surowe wyniki na mecie z symulacji i uzupełniamy kolarzy,
          // którzy w chwili przekroczenia mety przez lidera byli jeszcze na trasie.
          final List<StageFinishResult> rawFinishes =
              List<StageFinishResult>.from(loop.state.finishResults);
          final finishedIds = rawFinishes.map((r) => r.riderId).toSet();
          final double stageLengthM = stage.totalDistanceKm * 1000.0;
          final double baseWinnerTime = rawFinishes.isNotEmpty
              ? rawFinishes.first.finishTimeSeconds
              : loop.state.elapsedSeconds;

          final trailingRiders = activeRidersForStage.values
              .where((r) => !finishedIds.contains(r.id))
              .toList()
            ..sort((a, b) {
              final distA = loop.state.riderStates[a.id]?.distanceCoveredMeters ?? 0.0;
              final distB = loop.state.riderStates[b.id]?.distanceCoveredMeters ?? 0.0;
              return distB.compareTo(distA);
            });

          for (final rider in trailingRiders) {
            final rState = loop.state.riderStates[rider.id];
            final double coveredM = rState?.distanceCoveredMeters ?? 0.0;
            final double remainingM = math.max(1.0, stageLengthM - coveredM);
            final double speedMs = math.max(9.5, rState?.currentSpeedMs ?? 11.0);
            final double rawEstimatedTime =
                loop.state.elapsedSeconds + (remainingM / speedMs);
            // Kolarze w grupetto kończą w bezpiecznym limicie czasu (chyba że na etapie 17 wymuszamy OTL)
            final double estimatedTime =
                math.min(rawEstimatedTime, baseWinnerTime * 1.04);
            rawFinishes.add(
              StageFinishResult(
                riderId: rider.id,
                riderName: rider.fullName,
                teamId: rider.contract.teamId,
                finishRank: rawFinishes.length + 1,
                finishTimeSeconds: estimatedTime,
                gapToWinnerSeconds: math.max(0.0, estimatedTime - baseWinnerTime),
              ),
            );
          }

          // Zbieramy incydenty z etapu, odfiltrowując losowe DNF aby deterministycznie
          // zweryfikować kontrolowane wycofania DNF (etap 11) i OTL (etap 17).
          final List<RaceIncidentEvent> stageIncidents = loop.state.incidentHistory
              .where((inc) => !inc.hasDnf)
              .toList();

          if (stageNumber == 17 &&
              !stage.isTimeTrial &&
              activeRidersForStage.containsKey(otlCandidateId)) {
            rawFinishes.sort(
              (a, b) => a.finishTimeSeconds.compareTo(b.finishTimeSeconds),
            );
            final double winnerTime = rawFinishes.first.finishTimeSeconds;
            final otlRider = activeRidersForStage[otlCandidateId]!;
            // +35% ponad czas zwycięzcy gwarantuje przekroczenie limitu OTL (6–18%)
            final double otlTime = winnerTime * 1.35;
            final int idxOtl =
                rawFinishes.indexWhere((r) => r.riderId == otlCandidateId);
            final otlFinish = StageFinishResult(
              riderId: otlRider.id,
              riderName: otlRider.fullName,
              teamId: otlRider.contract.teamId,
              finishRank: rawFinishes.length + (idxOtl == -1 ? 1 : 0),
              finishTimeSeconds: otlTime,
              gapToWinnerSeconds: otlTime - winnerTime,
            );
            if (idxOtl != -1) {
              rawFinishes[idxOtl] = otlFinish;
            } else {
              rawFinishes.add(otlFinish);
            }
          }

          // Weryfikacja DNF na etapie 11: ciężka kraksa z wycofaniem jednego kolarza
          if (stageNumber == 11 &&
              activeRidersForStage.containsKey(dnfCandidateId)) {
            final dnfRider = activeRidersForStage[dnfCandidateId]!;
            rawFinishes.removeWhere((r) => r.riderId == dnfCandidateId);
            stageIncidents.add(
              RaceIncidentEvent(
                id: 'inc_dnf_stage_11',
                kilometerMark: stage.totalDistanceKm * 0.55,
                type: IncidentType.soloCrash,
                primaryVictims: [
                  IncidentVictim(
                    riderId: dnfRider.id,
                    riderName: dnfRider.fullName,
                    teamId: dnfRider.contract.teamId,
                    incidentType: IncidentType.soloCrash,
                    timeLostSeconds: 0.0,
                    isDnf: true,
                    assistanceMethod: AssistanceMethod.selfRemount,
                    description: '${dnfRider.fullName} wycofuje się po kraksie.',
                  ),
                ],
                heldUpRiderIds: const [],
                isRoadBlocked: false,
                radioReport:
                    'Radio Tour: ${dnfRider.fullName} wycofuje się z wyścigu (DNF).',
              ),
            );
          }

          // 5. Oficjalne przeliczenie wyników UCI (reguła 3s/3km, bonifikaty, punkty, OTL)
          final StageSummaryReport report =
              StageResultsCalculator.calculateStageResults(
            stage: stage,
            rawFinishResults: rawFinishes,
            stageIncidents: stageIncidents,
            allRidersMap: activeRidersForStage,
          );

          // Weryfikacja bonifikat czasowych na etapie płaskim i ITT
          if (stage.stageType == StageType.flat && report.results.length >= 4) {
            sawFlatTimeBonuses = true;
            expect(report.results[0].timeBonusSeconds, 10);
            expect(report.results[1].timeBonusSeconds, 6);
            expect(report.results[2].timeBonusSeconds, 4);
            expect(report.results[3].timeBonusSeconds, 0);
            expect(report.results[0].pointsGreenJersey, 50);
          }
          if (stage.isTimeTrial && report.results.isNotEmpty) {
            sawIttZeroBonuses = true;
            for (final res in report.results) {
              expect(res.timeBonusSeconds, 0);
            }
          }
          if (stage.isSummitFinish && report.results.isNotEmpty) {
            final totalKomOnStage = report.results.fold<int>(
              0,
              (sum, r) => sum + r.pointsKom,
            );
            if (totalKomOnStage > 0) {
              sawSummitKomPoints = true;
            }
          }
          if (stageNumber == 17) {
            expect(report.otlEliminatedCount, greaterThanOrEqualTo(1));
            final otlRes = report.results.firstWhere(
              (r) => r.riderId == otlCandidateId,
            );
            expect(otlRes.isEliminatedOtl, isTrue);
            expect(otlRes.formattedGap, 'OTL');
            sawOtlElimination = true;
          }
          if (stageNumber == 11) {
            expect(report.dnfCount, greaterThanOrEqualTo(1));
            final dnfRes = report.results.firstWhere(
              (r) => r.riderId == dnfCandidateId,
            );
            expect(dnfRes.isDnf, isTrue);
            expect(dnfRes.formattedGap, 'DNF');
            sawDnfElimination = true;
          }

          // 6. Aktualizacja skumulowanych klasyfikacji Wielkiego Touru
          ledger.applyStageReport(stageNumber: stageNumber, report: report);
          final updatedClassifications = ledger.buildClassifications(
            allRidersById: baseRidersById,
            teamsById: teamsById,
          );
          activeTour = activeTour.copyWith(
            classifications: updatedClassifications,
          );

          // 7. Regeneracja nocna po etapie dla każdej drużyny
          for (final team in teamsById.values) {
            final teamActiveRiders = activeRidersForStage.values
                .where((r) => r.contract.teamId == team.id)
                .toList();
            if (teamActiveRiders.isEmpty) continue;

            final recoveryResult = PostStageRecoveryProcessor.processStageRecovery(
              teamRiders: teamActiveRiders,
              team: team,
              stageNumber: stageNumber,
              officialResults: report.results,
              simulationState: loop.state,
              teamHoldsLeaderJersey: activeTour.currentLeaderRiderId != null &&
                  teamActiveRiders.any((r) => r.id == activeTour.currentLeaderRiderId),
            );

            for (final updatedRider in recoveryResult.updatedRiders) {
              expect(updatedRider.health.acuteTrainingLoad.isNaN, isFalse);
              expect(updatedRider.health.chronicTrainingLoad.isNaN, isFalse);
              expect(updatedRider.health.morale, inInclusiveRange(0.0, 100.0));
              currentRiders[updatedRider.id] = updatedRider;
            }
          }
        }

        // =====================================================================
        // WERYFIKACJA KOŃCOWA PO 21 ETAPACH I 2 DNIACH PRZERWY
        // =====================================================================
        expect(restDaysExecuted, 2);
        expect(atlBeforeRestDay1, isNotNull);
        expect(atlAfterRestDay1, isNotNull);
        expect(atlBeforeRestDay2, isNotNull);
        expect(atlAfterRestDay2, isNotNull);

        expect(sawFlatTimeBonuses, isTrue);
        expect(sawIttZeroBonuses, isTrue);
        expect(sawSummitKomPoints, isTrue);
        expect(sawOtlElimination, isTrue);
        expect(sawDnfElimination, isTrue);

        // Weryfikacja wykluczenia OTL i DNF z końcowej klasyfikacji GC
        final finalGc = activeTour.classifications.generalClassification;
        final finalPoints = activeTour.classifications.pointsClassification;
        final finalKom = activeTour.classifications.mountainsClassification;

        expect(ledger.eliminatedRiderIds.length, greaterThanOrEqualTo(2));
        expect(finalGc.length, baseRidersById.length - ledger.eliminatedRiderIds.length);
        expect(finalGc.any((e) => e.riderId == otlCandidateId), isFalse);
        expect(finalGc.any((e) => e.riderId == dnfCandidateId), isFalse);
        expect(ledger.eliminatedOnStage[otlCandidateId], 17);
        expect(ledger.eliminatedOnStage[dnfCandidateId], 11);

        // Weryfikacja spójności matematycznej sumy czasów GC = sum(officialTime - bonus)
        for (int i = 0; i < finalGc.length; i++) {
          final entry = finalGc[i];
          expect(entry.rank, i + 1);
          final expectedGcTime =
              (ledger.rawOfficialSecondsByRider[entry.riderId] ?? 0) -
                  (ledger.bonusSecondsByRider[entry.riderId] ?? 0);
          expect(entry.totalTimeSeconds, expectedGcTime);
          expect(entry.totalTimeSeconds, greaterThan(0));
          expect(
            entry.timeBehindLeaderSeconds,
            entry.totalTimeSeconds - finalGc.first.totalTimeSeconds,
          );
          if (i > 0) {
            expect(
              entry.totalTimeSeconds,
              greaterThanOrEqualTo(finalGc[i - 1].totalTimeSeconds),
            );
          }
        }
        expect(finalGc.first.timeBehindLeaderSeconds, 0);
        expect(activeTour.currentLeaderRiderId, finalGc.first.riderId);

        // Weryfikacja klasyfikacji punktowej i górskiej
        expect(finalPoints.first.points, greaterThan(0));
        for (int i = 1; i < finalPoints.length; i++) {
          expect(finalPoints[i].rank, i + 1);
          expect(finalPoints[i].points, lessThanOrEqualTo(finalPoints[i - 1].points));
        }
        expect(finalKom.first.points, greaterThan(0));
        for (int i = 1; i < finalKom.length; i++) {
          expect(finalKom[i].rank, i + 1);
          expect(finalKom[i].points, lessThanOrEqualTo(finalKom[i - 1].points));
        }

        // Weryfikacja modelu zmęczenia 3. tygodnia (etapy 1–14 vs 15–21)
        for (int st = 1; st <= 14; st++) {
          expect(gtSpecialistDecayByStage[st], 0.0);
          expect(oneDaySpecialistDecayByStage[st], 0.0);
        }
        for (int st = 15; st <= 21; st++) {
          expect(
            gtSpecialistDecayByStage[st]!,
            greaterThan(gtSpecialistDecayByStage[st - 1]!),
          );
          expect(
            oneDaySpecialistDecayByStage[st]!,
            greaterThan(oneDaySpecialistDecayByStage[st - 1]!),
          );
          expect(
            oneDaySpecialistDecayByStage[st]!,
            greaterThan(gtSpecialistDecayByStage[st]!),
          );
        }

        // Etap 21: Specjalista GT traci 2–3% FTP, klasykowiec 9–14% FTP
        expect(gtSpecialistDecayByStage[21], inInclusiveRange(2.0, 3.0));
        expect(oneDaySpecialistDecayByStage[21], inInclusiveRange(9.0, 14.0));

        // Fizjologia w 3. tygodniu faktycznie uległa degradacji względem bazy
        expect(
          currentRiders[gtSpecialistId]!.physiology.ftpWatts,
          lessThan(basePhysiologyById[gtSpecialistId]!.ftpWatts),
        );
        final stage21OneDayPhysiology = GrandTourThirdWeekFatigueDecay.evaluate(
          stageNumber: 21,
          recoveryRate: basePhysiologyById[oneDaySpecialistId]!.recoveryRate,
        ).applyToPhysiology(basePhysiologyById[oneDaySpecialistId]!);
        expect(
          stage21OneDayPhysiology.ftpWatts,
          lessThan(basePhysiologyById[oneDaySpecialistId]!.ftpWatts),
        );
        if (!ledger.eliminatedRiderIds.contains(oneDaySpecialistId)) {
          expect(
            currentRiders[oneDaySpecialistId]!.physiology.ftpWatts,
            lessThan(basePhysiologyById[oneDaySpecialistId]!.ftpWatts),
          );
        }
      },
    );
  });
}
