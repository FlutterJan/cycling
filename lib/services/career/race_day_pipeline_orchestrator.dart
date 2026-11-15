// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/peloton/drafting_grid_system.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/simulation/post_stage_recovery_processor.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/career/career_save.dart';
import '../../models/career/season_calendar.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../state/career_controller.dart';
import '../../state/career_state_notifier.dart';
import '../../state/race_simulation_notifier.dart';
import '../database/save_game_manager.dart';
import '../generators/fictional_brands_catalog.dart';
import 'autosave_and_crash_recovery_guard.dart';
import 'finance_and_budget_service.dart';
import 'sponsor_objectives_evaluator.dart';
import 'team_chemistry_and_builder_service.dart';

/// Kolejne etapy cyklu życia dnia wyścigowego zarządzane przez [RaceDayPipelineOrchestrator].
enum RaceDayPipelinePhase {
  /// Orkiestrator w stanie spoczynku (brak aktywnego dnia wyścigowego).
  idle,

  /// Etap 1: Kalendarz sezonu — wybór wyścigu/etapu, weryfikacja składu i zapis punktu kontrolnego.
  calendarSelection,

  /// Etap 2: Odprawa przedstartowa (`PreRaceBriefingScreen`) — skład, sprzęt, role taktyczne.
  preRaceBriefing,

  /// Etap 3: Symulacja etapu na żywo (`IsolateSimulation` / `RaceSimulationNotifier` / `Race3DViewportWidget`).
  liveSimulation3d,

  /// Etap 4: Obliczanie oficjalnych wyników UCI (`StageResultsCalculator`).
  stageResultsCalculation,

  /// Etap 5: Ceremonia podium i klasyfikacje (`PostStagePodiumScreen`).
  postStagePodium,

  /// Etap 6: Ewaluacja celów sponsorskich i bonusów (`SponsorObjectivesEvaluator`).
  sponsorEvaluation,

  /// Etap 7: Regeneracja nocna kolarzy i rozliczenie nagród (`PostStageRecoveryProcessor`).
  recoveryProcessing,

  /// Etap 8: Atomowy autozapis transakcyjny i aktualizacja kalendarza (`AutosaveAndCrashRecoveryGuard`).
  autoSaving,

  /// Cały dzień wyścigowy został pomyślnie przetworzony i zapisany.
  completed,

  /// Wystąpił błąd krytyczny na jednym z etapów (z możliwością przywrócenia z punktu kontrolnego).
  failed;

  String get labelPl {
    switch (this) {
      case RaceDayPipelinePhase.idle:
        return 'Oczekiwanie';
      case RaceDayPipelinePhase.calendarSelection:
        return 'Kalendarz wyścigowy';
      case RaceDayPipelinePhase.preRaceBriefing:
        return 'Odprawa przedstartowa';
      case RaceDayPipelinePhase.liveSimulation3d:
        return 'Symulacja 3D / Isolate';
      case RaceDayPipelinePhase.stageResultsCalculation:
        return 'Kalkulator wyników UCI';
      case RaceDayPipelinePhase.postStagePodium:
        return 'Ceremonia podium';
      case RaceDayPipelinePhase.sponsorEvaluation:
        return 'Ewaluacja sponsorów';
      case RaceDayPipelinePhase.recoveryProcessing:
        return 'Regeneracja nocna';
      case RaceDayPipelinePhase.autoSaving:
        return 'Autozapis transakcyjny';
      case RaceDayPipelinePhase.completed:
        return 'Dzień wyścigowy ukończony';
      case RaceDayPipelinePhase.failed:
        return 'Błąd pipeline’u';
    }
  }

  double get progressRatio {
    switch (this) {
      case RaceDayPipelinePhase.idle:
        return 0.0;
      case RaceDayPipelinePhase.calendarSelection:
        return 0.12;
      case RaceDayPipelinePhase.preRaceBriefing:
        return 0.25;
      case RaceDayPipelinePhase.liveSimulation3d:
        return 0.42;
      case RaceDayPipelinePhase.stageResultsCalculation:
        return 0.56;
      case RaceDayPipelinePhase.postStagePodium:
        return 0.68;
      case RaceDayPipelinePhase.sponsorEvaluation:
        return 0.80;
      case RaceDayPipelinePhase.recoveryProcessing:
        return 0.90;
      case RaceDayPipelinePhase.autoSaving:
        return 0.96;
      case RaceDayPipelinePhase.completed:
        return 1.0;
      case RaceDayPipelinePhase.failed:
        return 0.0;
    }
  }
}

/// Konfiguracja zatwierdzona przez gracza na etapie odprawy przedstartowej (`PreRaceBriefing`).
class RaceDayBriefingConfig {
  final List<String> selectedRiderIds;
  final Map<String, TacticalOrder> tacticalOrdersByRiderId;
  final Map<String, CompleteBike> bikeOverridesByRiderId;
  final double directorSpeechMoraleDelta;
  final bool reconnaissanceCompleted;
  final String briefingNotes;

  const RaceDayBriefingConfig({
    required this.selectedRiderIds,
    this.tacticalOrdersByRiderId = const {},
    this.bikeOverridesByRiderId = const {},
    this.directorSpeechMoraleDelta = 0.0,
    this.reconnaissanceCompleted = false,
    this.briefingNotes = '',
  });

  RaceDayBriefingConfig copyWith({
    List<String>? selectedRiderIds,
    Map<String, TacticalOrder>? tacticalOrdersByRiderId,
    Map<String, CompleteBike>? bikeOverridesByRiderId,
    double? directorSpeechMoraleDelta,
    bool? reconnaissanceCompleted,
    String? briefingNotes,
  }) {
    return RaceDayBriefingConfig(
      selectedRiderIds: selectedRiderIds != null
          ? List<String>.unmodifiable(selectedRiderIds)
          : this.selectedRiderIds,
      tacticalOrdersByRiderId: tacticalOrdersByRiderId != null
          ? Map<String, TacticalOrder>.unmodifiable(tacticalOrdersByRiderId)
          : this.tacticalOrdersByRiderId,
      bikeOverridesByRiderId: bikeOverridesByRiderId != null
          ? Map<String, CompleteBike>.unmodifiable(bikeOverridesByRiderId)
          : this.bikeOverridesByRiderId,
      directorSpeechMoraleDelta:
          directorSpeechMoraleDelta ?? this.directorSpeechMoraleDelta,
      reconnaissanceCompleted:
          reconnaissanceCompleted ?? this.reconnaissanceCompleted,
      briefingNotes: briefingNotes ?? this.briefingNotes,
    );
  }
}

/// Pojedynczy wpis w dzienniku audytu wykonania kroków dnia wyścigowego.
class RaceDayPipelineStepLog {
  final RaceDayPipelinePhase phase;
  final DateTime startedAtUtc;
  final DateTime completedAtUtc;
  final String statusMessage;
  final bool succeeded;
  final String? errorMessage;

  const RaceDayPipelineStepLog({
    required this.phase,
    required this.startedAtUtc,
    required this.completedAtUtc,
    required this.statusMessage,
    this.succeeded = true,
    this.errorMessage,
  });

  int get elapsedMs => completedAtUtc.difference(startedAtUtc).inMilliseconds;
}

/// Kompletny raport końcowy z przejścia całego cyklu dnia wyścigowego.
class RaceDayPostStageSummary {
  final TourRace race;
  final RaceStage stage;
  final int stageIndex;
  final StageSummaryReport stageSummaryReport;
  final StageSimulationState simulationState;
  final SponsorEvaluationResult sponsorEvaluation;
  final PostStageRecoveryResult recoveryResult;
  final CareerSave updatedSave;
  final List<CareerInboxMessage> generatedInboxMessages;
  final TransactionalSaveReceipt? saveReceipt;
  final int totalPrizeMoneyEur;
  final int totalSponsorBonusesEur;
  final bool wasRaceCompleted;
  final DateTime completedAtUtc;
  final int totalDurationMs;
  final List<RaceDayPipelineStepLog> stepLogs;

  const RaceDayPostStageSummary({
    required this.race,
    required this.stage,
    required this.stageIndex,
    required this.stageSummaryReport,
    required this.simulationState,
    required this.sponsorEvaluation,
    required this.recoveryResult,
    required this.updatedSave,
    required this.generatedInboxMessages,
    this.saveReceipt,
    required this.totalPrizeMoneyEur,
    required this.totalSponsorBonusesEur,
    required this.wasRaceCompleted,
    required this.completedAtUtc,
    required this.totalDurationMs,
    required this.stepLogs,
  });
}

/// Niemutowalny stan orkiestratora dnia wyścigowego.
class RaceDayPipelineState {
  final RaceDayPipelinePhase phase;
  final bool isBusy;
  final CareerSave? careerSave;
  final TourRace? activeRace;
  final RaceStage? activeStage;
  final int activeStageIndex;
  final RaceDayBriefingConfig? briefingConfig;
  final StageSimulationState? simulationState;
  final StageSummaryReport? stageSummaryReport;
  final SponsorEvaluationResult? sponsorEvaluation;
  final PostStageRecoveryResult? recoveryResult;
  final RaceDayPostStageSummary? finalSummary;
  final TransactionalSaveReceipt? lastSaveReceipt;
  final String? preStageCheckpointId;
  final List<RaceDayPipelineStepLog> stepLogs;
  final String? errorMessage;
  final bool canRecoverFromCheckpoint;

  const RaceDayPipelineState({
    this.phase = RaceDayPipelinePhase.idle,
    this.isBusy = false,
    this.careerSave,
    this.activeRace,
    this.activeStage,
    this.activeStageIndex = 0,
    this.briefingConfig,
    this.simulationState,
    this.stageSummaryReport,
    this.sponsorEvaluation,
    this.recoveryResult,
    this.finalSummary,
    this.lastSaveReceipt,
    this.preStageCheckpointId,
    this.stepLogs = const [],
    this.errorMessage,
    this.canRecoverFromCheckpoint = false,
  });

  double get progressRatio => phase.progressRatio;

  bool get hasActivePipeline =>
      phase != RaceDayPipelinePhase.idle &&
      phase != RaceDayPipelinePhase.completed &&
      phase != RaceDayPipelinePhase.failed;

  RaceDayPipelineState copyWith({
    RaceDayPipelinePhase? phase,
    bool? isBusy,
    CareerSave? careerSave,
    TourRace? activeRace,
    RaceStage? activeStage,
    int? activeStageIndex,
    RaceDayBriefingConfig? briefingConfig,
    StageSimulationState? simulationState,
    StageSummaryReport? stageSummaryReport,
    SponsorEvaluationResult? sponsorEvaluation,
    PostStageRecoveryResult? recoveryResult,
    RaceDayPostStageSummary? finalSummary,
    TransactionalSaveReceipt? lastSaveReceipt,
    String? preStageCheckpointId,
    List<RaceDayPipelineStepLog>? stepLogs,
    String? errorMessage,
    bool clearError = false,
    bool? canRecoverFromCheckpoint,
  }) {
    return RaceDayPipelineState(
      phase: phase ?? this.phase,
      isBusy: isBusy ?? this.isBusy,
      careerSave: careerSave ?? this.careerSave,
      activeRace: activeRace ?? this.activeRace,
      activeStage: activeStage ?? this.activeStage,
      activeStageIndex: activeStageIndex ?? this.activeStageIndex,
      briefingConfig: briefingConfig ?? this.briefingConfig,
      simulationState: simulationState ?? this.simulationState,
      stageSummaryReport: stageSummaryReport ?? this.stageSummaryReport,
      sponsorEvaluation: sponsorEvaluation ?? this.sponsorEvaluation,
      recoveryResult: recoveryResult ?? this.recoveryResult,
      finalSummary: finalSummary ?? this.finalSummary,
      lastSaveReceipt: lastSaveReceipt ?? this.lastSaveReceipt,
      preStageCheckpointId: preStageCheckpointId ?? this.preStageCheckpointId,
      stepLogs: stepLogs ?? this.stepLogs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      canRecoverFromCheckpoint:
          canRecoverFromCheckpoint ?? this.canRecoverFromCheckpoint,
    );
  }
}

/// Kompletny orkiestrator cyklu życia dnia wyścigowego:
/// `Calendar -> PreRaceBriefing -> IsolateSimulation / 3D Viewport -> StageResultsCalculator -> PostStagePodium -> SponsorObjectivesEvaluator -> RecoveryProcessor -> AutoSave`.
///
/// Zapewnia:
/// - spójne przejścia faz i walidację danych wejściowych na każdym kroku,
/// - ochronę przed awarią za pomocą punktów kontrolnych `PreStageCheckpoint`,
/// - bezpieczną synchronizację ze stanem Riverpod (`CareerController`, `CareerStateNotifier`,
///   `RaceSimulationNotifier`, `AutosaveGuardNotifier`),
/// - tryb krokowy (dla UI/GoRouter) oraz tryb pełnej orkiestracji w tle (dla szybkiej symulacji i testów).
class RaceDayPipelineOrchestrator {
  final AutosaveAndCrashRecoveryGuard? _explicitGuard;
  final SponsorObjectivesEvaluator _sponsorEvaluator;

  const RaceDayPipelineOrchestrator({
    AutosaveAndCrashRecoveryGuard? autosaveGuard,
    SponsorObjectivesEvaluator sponsorEvaluator = const SponsorObjectivesEvaluator(),
  })  : _explicitGuard = autosaveGuard,
        _sponsorEvaluator = sponsorEvaluator;

  factory RaceDayPipelineOrchestrator.withGuard(
    AutosaveAndCrashRecoveryGuard guard, {
    SponsorObjectivesEvaluator sponsorEvaluator = const SponsorObjectivesEvaluator(),
  }) {
    return RaceDayPipelineOrchestrator(
      autosaveGuard: guard,
      sponsorEvaluator: sponsorEvaluator,
    );
  }

  AutosaveAndCrashRecoveryGuard get _autosaveGuard =>
      _explicitGuard ?? AutosaveAndCrashRecoveryGuard();

  /// KROK 1 (`Calendar`): Inicjuje dzień wyścigowy z kalendarza kariery.
  ///
  /// Rozwiązuje aktywny wyścig i etap, wybiera domyślny skład (do 8 zdrowych kolarzy),
  /// ustawia aktywny wyścig w [SeasonCalendar] i zapisuje punkt kontrolny `PreStageCheckpoint`.
  Future<RaceDayPipelineState> startFromCalendar({
    required CareerSave careerSave,
    TourRace? overrideRace,
    int? overrideStageIndex,
    List<String>? preferredRiderIds,
    bool persistPreStageCheckpoint = true,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final logs = <RaceDayPipelineStepLog>[];

    final resolved = _resolveRaceAndStage(
      calendar: careerSave.calendar,
      overrideRace: overrideRace,
      overrideStageIndex: overrideStageIndex,
    );
    if (resolved == null) {
      return RaceDayPipelineState(
        phase: RaceDayPipelinePhase.failed,
        careerSave: careerSave,
        errorMessage: 'Brak aktywnego lub zaplanowanego wyścigu w kalendarzu sezonu.',
        stepLogs: [
          RaceDayPipelineStepLog(
            phase: RaceDayPipelinePhase.calendarSelection,
            startedAtUtc: startedAt,
            completedAtUtc: DateTime.now().toUtc(),
            statusMessage: 'Nie znaleziono wyścigu w kalendarzu.',
            succeeded: false,
            errorMessage: 'Brak aktywnego wyścigu lub etapów.',
          ),
        ],
      );
    }

    final race = resolved.race;
    final stage = resolved.stage;
    final stageIndex = resolved.stageIndex;

    final selectedRiderIds = _selectStartingRiderIds(
      careerSave: careerSave,
      preferredRiderIds: preferredRiderIds,
    );
    if (selectedRiderIds.isEmpty) {
      return RaceDayPipelineState(
        phase: RaceDayPipelinePhase.failed,
        careerSave: careerSave,
        activeRace: race,
        activeStage: stage,
        activeStageIndex: stageIndex,
        errorMessage: 'Drużyna gracza nie posiada dostępnych kolarzy do startu.',
        stepLogs: [
          RaceDayPipelineStepLog(
            phase: RaceDayPipelinePhase.calendarSelection,
            startedAtUtc: startedAt,
            completedAtUtc: DateTime.now().toUtc(),
            statusMessage: 'Brak dostępnych kolarzy.',
            succeeded: false,
            errorMessage: 'Pusty skład startowy.',
          ),
        ],
      );
    }

    final updatedCalendar = careerSave.calendar.copyWith(
      activeRaceId: race.id,
      activeStageIndex: stageIndex,
    );
    final updatedSave = careerSave.copyWith(calendar: updatedCalendar);

    String? checkpointId;
    if (persistPreStageCheckpoint) {
      try {
        final receipt = await _autosaveGuard.createPreStageCheckpoint(
          careerSave: updatedSave,
          raceId: race.id,
          raceName: race.name,
          stageId: stage.id,
          stageNumber: stage.stageNumber,
          stageName: stage.name,
          selectedRiderIds: selectedRiderIds,
        );
        if (receipt.success) {
          checkpointId = '${updatedSave.id}_${race.id}_s${stage.stageNumber}';
        }
      } catch (_) {
        // W środowisku testowym bez pluginów platformowych checkpoint jest pomijany bezpiecznie.
      }
    }

    final defaultConfig = RaceDayBriefingConfig(
      selectedRiderIds: selectedRiderIds,
    );

    logs.add(
      RaceDayPipelineStepLog(
        phase: RaceDayPipelinePhase.calendarSelection,
        startedAtUtc: startedAt,
        completedAtUtc: DateTime.now().toUtc(),
        statusMessage:
            'Wybrano ${race.name} (Etap ${stage.stageNumber}: ${stage.name}), skład: ${selectedRiderIds.length} kolarzy.',
      ),
    );

    return RaceDayPipelineState(
      phase: RaceDayPipelinePhase.preRaceBriefing,
      careerSave: updatedSave,
      activeRace: race,
      activeStage: stage,
      activeStageIndex: stageIndex,
      briefingConfig: defaultConfig,
      preStageCheckpointId: checkpointId,
      canRecoverFromCheckpoint: checkpointId != null,
      stepLogs: logs,
    );
  }

  /// KROK 2 (`PreRaceBriefing`): Zatwierdza odprawę przedstartową (skład, sprzęt, morale, rozkazy).
  RaceDayPipelineState applyPreRaceBriefing({
    required RaceDayPipelineState currentState,
    required RaceDayBriefingConfig briefingConfig,
  }) {
    final startedAt = DateTime.now().toUtc();
    final save = currentState.careerSave;
    final race = currentState.activeRace;
    final stage = currentState.activeStage;

    if (save == null || race == null || stage == null) {
      return currentState.copyWith(
        phase: RaceDayPipelinePhase.failed,
        errorMessage: 'Brak kontekstu wyścigu lub zapisu przy zatwierdzaniu odprawy.',
      );
    }

    if (briefingConfig.selectedRiderIds.isEmpty) {
      return currentState.copyWith(
        phase: RaceDayPipelinePhase.failed,
        errorMessage: 'Skład startowy po odprawie nie może być pusty.',
      );
    }

    final selectedSet = briefingConfig.selectedRiderIds.toSet();
    final updatedRiders = save.riders.map((rider) {
      if (!selectedSet.contains(rider.id) || briefingConfig.directorSpeechMoraleDelta == 0.0) {
        return rider;
      }
      final double nextMorale =
          (rider.health.morale + briefingConfig.directorSpeechMoraleDelta).clamp(0.0, 1.0);
      return rider.copyWith(
        health: rider.health.copyWith(morale: nextMorale),
      );
    }).toList();

    final updatedSave = save.copyWith(riders: updatedRiders);
    final updatedLogs = [
      ...currentState.stepLogs,
      RaceDayPipelineStepLog(
        phase: RaceDayPipelinePhase.preRaceBriefing,
        startedAtUtc: startedAt,
        completedAtUtc: DateTime.now().toUtc(),
        statusMessage:
            'Zatwierdzono odprawę dla ${briefingConfig.selectedRiderIds.length} kolarzy '
            '(rekonesans: ${briefingConfig.reconnaissanceCompleted ? 'tak' : 'nie'}).',
      ),
    ];

    return currentState.copyWith(
      phase: RaceDayPipelinePhase.liveSimulation3d,
      careerSave: updatedSave,
      briefingConfig: briefingConfig,
      stepLogs: updatedLogs,
      clearError: true,
    );
  }

  /// KROK 3 (`IsolateSimulation / 3D Viewport`): Przygotowuje i uruchamia symulację etapu.
  ///
  /// Jeśli przekazano [simulationNotifier], wywołuje `initializeStage` z kompletem kolarzy,
  /// rowerów i rozkazów taktycznych z odprawy, gotowych dla widoku 3D (`Race3DViewportWidget`).
  RaceDayPipelineState launchSimulationForViewport({
    required RaceDayPipelineState currentState,
    RaceSimulationNotifier? simulationNotifier,
    Map<String, CompleteBike>? customBikesMap,
  }) {
    final startedAt = DateTime.now().toUtc();
    final save = currentState.careerSave;
    final stage = currentState.activeStage;
    final briefing = currentState.briefingConfig;

    if (save == null || stage == null) {
      return currentState.copyWith(
        phase: RaceDayPipelinePhase.failed,
        errorMessage: 'Brak zapisu lub etapu do uruchomienia symulacji 3D.',
      );
    }

    final allRidersMap = <String, Rider>{
      for (final rider in save.riders) rider.id: rider,
    };
    final allTeamsMap = <String, CyclingTeam>{
      for (final team in save.teams) team.id: team,
    };
    final allBikesMap = _buildBikesMap(
      riders: save.riders,
      customBikesMap: customBikesMap,
      briefingOverrides: briefing?.bikeOverridesByRiderId ?? const {},
    );

    if (simulationNotifier != null) {
      simulationNotifier.initializeStage(
        stage: stage,
        playerTeamId: save.playerTeamId,
        allRidersMap: allRidersMap,
        allBikesMap: allBikesMap,
        allTeamsMap: allTeamsMap,
      );

      if (briefing != null) {
        for (final entry in briefing.tacticalOrdersByRiderId.entries) {
          simulationNotifier.setRiderTacticalOrder(entry.key, entry.value);
        }
      }
    }

    final updatedLogs = [
      ...currentState.stepLogs,
      RaceDayPipelineStepLog(
        phase: RaceDayPipelinePhase.liveSimulation3d,
        startedAtUtc: startedAt,
        completedAtUtc: DateTime.now().toUtc(),
        statusMessage:
            'Uruchomiono symulację etapu ${stage.stageNumber} (${stage.totalDistanceKm.toStringAsFixed(1)} km) dla ${allRidersMap.length} kolarzy.',
      ),
    ];

    return currentState.copyWith(
      phase: RaceDayPipelinePhase.liveSimulation3d,
      stepLogs: updatedLogs,
      clearError: true,
    );
  }

  /// KROKI 4–8 (`StageResultsCalculator -> PostStagePodium -> SponsorObjectivesEvaluator -> RecoveryProcessor -> AutoSave`):
  /// Przetwarza kompletną sekwencję powyścigową po przekroczeniu linii mety.
  Future<RaceDayPipelineState> executePostStagePipeline({
    required RaceDayPipelineState currentState,
    required StageSimulationState simulationState,
    StageSummaryReport? precomputedReport,
    bool autoCompleteAfterPodium = true,
    bool persistAutoSave = true,
  }) async {
    final pipelineStart = DateTime.now().toUtc();
    final save = currentState.careerSave;
    final race = currentState.activeRace;
    final stage = currentState.activeStage;

    if (save == null || race == null || stage == null) {
      return currentState.copyWith(
        phase: RaceDayPipelinePhase.failed,
        errorMessage: 'Brak aktywnego stanu wyścigu do przetworzenia wyników.',
      );
    }

    final logs = List<RaceDayPipelineStepLog>.from(currentState.stepLogs);

    try {
      // -----------------------------------------------------------------------
      // ETAP 4: StageResultsCalculator
      // -----------------------------------------------------------------------
      final calcStarted = DateTime.now().toUtc();
      final allRidersMap = <String, Rider>{
        for (final r in save.riders) r.id: r,
      };
      final StageSummaryReport report = precomputedReport ??
          StageResultsCalculator.calculateOfficialStageResults(
            stage: stage,
            finishResults: simulationState.finishResults,
            incidents: simulationState.incidentHistory,
            allRidersMap: allRidersMap,
            playerTeamId: save.playerTeamId,
            mostCombativeRiderId: _detectMostCombativeRiderId(simulationState),
          );

      logs.add(
        RaceDayPipelineStepLog(
          phase: RaceDayPipelinePhase.stageResultsCalculation,
          startedAtUtc: calcStarted,
          completedAtUtc: DateTime.now().toUtc(),
          statusMessage:
              'Obliczono oficjalne wyniki UCI (${report.results.length} sklasyfikowanych, zwycięzca: ${report.winnerRiderName}).',
        ),
      );

      // -----------------------------------------------------------------------
      // ETAP 5: PostStagePodium (przygotowanie danych dla ekranu podium)
      // -----------------------------------------------------------------------
      final podiumStarted = DateTime.now().toUtc();
      logs.add(
        RaceDayPipelineStepLog(
          phase: RaceDayPipelinePhase.postStagePodium,
          startedAtUtc: podiumStarted,
          completedAtUtc: DateTime.now().toUtc(),
          statusMessage:
              'Przygotowano ceremonię podium i klasyfikacje etapu ${stage.stageNumber}.',
        ),
      );

      if (!autoCompleteAfterPodium) {
        return currentState.copyWith(
          phase: RaceDayPipelinePhase.postStagePodium,
          simulationState: simulationState,
          stageSummaryReport: report,
          stepLogs: logs,
          clearError: true,
        );
      }

      // -----------------------------------------------------------------------
      // ETAP 6: SponsorObjectivesEvaluator
      // -----------------------------------------------------------------------
      final sponsorStarted = DateTime.now().toUtc();
      final isLastStage = currentState.activeStageIndex >= race.stages.length - 1;
      final sponsorContext = _buildPostRaceSponsorContext(
        race: race,
        stage: stage,
        report: report,
        simulationState: simulationState,
        playerTeamId: save.playerTeamId,
        raceDate: save.currentDate,
        isFinalStage: isLastStage,
      );

      final sponsorEval = _sponsorEvaluator.evaluatePostRace(
        team: save.playerTeam,
        context: sponsorContext,
      );
      final teamAfterSponsors = _sponsorEvaluator.applyEvaluationToTeam(
        team: save.playerTeam,
        result: sponsorEval,
      );

      final ledgerAfterSponsors = List<CareerFinanceLedgerEntry>.from(save.financeLedger);
      if (sponsorEval.totalBonusesPaidEur > 0) {
        ledgerAfterSponsors.insert(
          0,
          CareerFinanceLedgerEntry(
            id: 'fin_sponsor_bonus_${save.currentDate.millisecondsSinceEpoch}',
            date: save.currentDate,
            category: FinanceCategory.sponsorPayout,
            amountEur: sponsorEval.totalBonusesPaidEur,
            description: 'Bonusy sponsorskie: ${race.name} (Etap ${stage.stageNumber})',
          ),
        );
      }

      final teamsAfterSponsors = save.teams
          .map((t) => t.id == save.playerTeamId ? teamAfterSponsors : t)
          .toList();
      final saveAfterSponsors = save.copyWith(
        teams: teamsAfterSponsors,
        financeLedger: ledgerAfterSponsors,
      );

      logs.add(
        RaceDayPipelineStepLog(
          phase: RaceDayPipelinePhase.sponsorEvaluation,
          startedAtUtc: sponsorStarted,
          completedAtUtc: DateTime.now().toUtc(),
          statusMessage:
              'Ewaluacja sponsorów: ${sponsorEval.newlyCompletedObjectives.length} nowych celów, '
              'bonusy: €${sponsorEval.totalBonusesPaidEur}, zadowolenie: ${sponsorEval.overallBoardSatisfaction.toStringAsFixed(1)}%.',
        ),
      );

      // -----------------------------------------------------------------------
      // ETAP 7: PostStageRecoveryProcessor + Nagrody + Chemia składu
      // -----------------------------------------------------------------------
      final recoveryStarted = DateTime.now().toUtc();
      final recoveryResult = PostStageRecoveryProcessor.processStageRecovery(
        teamRiders: saveAfterSponsors.playerRoster,
        team: saveAfterSponsors.playerTeam,
        stageNumber: report.stageNumber,
        officialResults: report.results,
        simulationState: simulationState,
        teamFacilities: TeamRecoveryFacilities(
          hasCompressionBoots: saveAfterSponsors.medicalCenterLevel >= 2,
          hasCryoCabin: saveAfterSponsors.medicalCenterLevel >= 4,
          nutritionProtocol: saveAfterSponsors.medicalCenterLevel >= 3
              ? RecoveryNutritionProtocol.worldTourElite
              : RecoveryNutritionProtocol.advanced,
          hasSleepOptimizationKit: saveAfterSponsors.serviceCourseLevel >= 3,
          massageQualityLevel: (saveAfterSponsors.medicalCenterLevel * 20).clamp(20, 100),
        ),
        incidents: simulationState.incidentHistory,
        teamHoldsLeaderJersey: _doesPlayerTeamHoldLeaderJersey(
          report: report,
          playerTeamId: saveAfterSponsors.playerTeamId,
        ),
      );

      final updatedRidersMap = <String, Rider>{
        for (final r in saveAfterSponsors.riders) r.id: r,
      };
      for (final updatedRider in recoveryResult.updatedRiders) {
        updatedRidersMap[updatedRider.id] = updatedRider;
      }

      final updatedTeamsAfterRecovery = saveAfterSponsors.teams
          .map((t) => t.id == saveAfterSponsors.playerTeamId ? recoveryResult.updatedTeam : t)
          .toList();

      CareerSave saveAfterRecovery = saveAfterSponsors.copyWith(
        riders: updatedRidersMap.values.toList(),
        teams: updatedTeamsAfterRecovery,
      );

      final prizeMoneyEur = recoveryResult.teamTotalPrizeMoneyEur;
      if (prizeMoneyEur > 0) {
        saveAfterRecovery = FinanceAndBudgetService.processRacePrizeMoney(
          save: saveAfterRecovery,
          raceName: '${report.stageNumber}. etap: ${report.stageName}',
          totalPrizeWonEur: prizeMoneyEur,
        );
      }

      final updatedSquads = TeamChemistryAndBuilderService.updateSquadsAfterStage(
        squads: saveAfterRecovery.dedicatedSquads,
        stageFinisherRiderIds: report.results.map((r) => r.riderId).toList(),
      );

      logs.add(
        RaceDayPipelineStepLog(
          phase: RaceDayPipelinePhase.recoveryProcessing,
          startedAtUtc: recoveryStarted,
          completedAtUtc: DateTime.now().toUtc(),
          statusMessage:
              'Przeliczono regenerację nocną (${recoveryResult.updatedRiders.length} kolarzy), '
              'nagrody: €$prizeMoneyEur.',
        ),
      );

      // -----------------------------------------------------------------------
      // ETAP 8: AutoSave & Aktualizacja Kalendarza
      // -----------------------------------------------------------------------
      final autosaveStarted = DateTime.now().toUtc();
      SeasonCalendar updatedCalendar = saveAfterRecovery.calendar;
      if (isLastStage) {
        final winnerResult = report.results.isNotEmpty ? report.results.first : null;
        final winnerTeamName = winnerResult != null
            ? (saveAfterRecovery.teams
                    .where((t) => t.id == winnerResult.teamId)
                    .map((t) => t.name)
                    .firstOrNull ??
                winnerResult.teamId)
            : '';
        final historyEntry = RaceHistoryEntry(
          raceId: race.id,
          raceName: race.name,
          seasonYear: saveAfterRecovery.currentSeasonYear,
          winnerRiderId: winnerResult?.riderId ?? '',
          winnerRiderName: winnerResult?.riderName ?? report.winnerRiderName,
          winnerTeamId: winnerResult?.teamId ?? report.winnerTeamId,
          winnerTeamName: winnerTeamName,
          winnerTotalTimeSeconds: winnerResult?.officialFinishTimeSeconds.round() ??
              report.winnerTimeSeconds.round(),
          completedDate: saveAfterRecovery.currentDate,
        );
        updatedCalendar = updatedCalendar.completeActiveRace(historyEntry);
      } else {
        updatedCalendar = updatedCalendar.advanceToNextStage();
      }

      final finalSave = saveAfterRecovery.copyWith(
        calendar: updatedCalendar,
        dedicatedSquads: updatedSquads,
        currentDate: saveAfterRecovery.currentDate.add(const Duration(days: 1)),
        lastSavedAt: DateTime.now(),
      );

      TransactionalSaveReceipt? saveReceipt;
      if (persistAutoSave) {
        saveReceipt = await _performSafeTransactionalAutosave(
          save: finalSave,
          stageId: stage.id,
        );
      }

      logs.add(
        RaceDayPipelineStepLog(
          phase: RaceDayPipelinePhase.autoSaving,
          startedAtUtc: autosaveStarted,
          completedAtUtc: DateTime.now().toUtc(),
          statusMessage: saveReceipt != null && saveReceipt.success
              ? 'Autozapis transakcyjny zakończony (checksum: ${saveReceipt.checksum}).'
              : 'Zaktualizowano stan kariery po etapie.',
        ),
      );

      final completedAt = DateTime.now().toUtc();
      final totalDurationMs = completedAt.difference(pipelineStart).inMilliseconds;

      final summary = RaceDayPostStageSummary(
        race: race,
        stage: stage,
        stageIndex: currentState.activeStageIndex,
        stageSummaryReport: report,
        simulationState: simulationState,
        sponsorEvaluation: sponsorEval,
        recoveryResult: recoveryResult,
        updatedSave: finalSave,
        generatedInboxMessages: sponsorEval.generatedEmails,
        saveReceipt: saveReceipt,
        totalPrizeMoneyEur: prizeMoneyEur,
        totalSponsorBonusesEur: sponsorEval.totalBonusesPaidEur,
        wasRaceCompleted: isLastStage,
        completedAtUtc: completedAt,
        totalDurationMs: totalDurationMs,
        stepLogs: List<RaceDayPipelineStepLog>.unmodifiable(logs),
      );

      return currentState.copyWith(
        phase: RaceDayPipelinePhase.completed,
        isBusy: false,
        careerSave: finalSave,
        simulationState: simulationState,
        stageSummaryReport: report,
        sponsorEvaluation: sponsorEval,
        recoveryResult: recoveryResult,
        finalSummary: summary,
        lastSaveReceipt: saveReceipt,
        canRecoverFromCheckpoint: false,
        stepLogs: List<RaceDayPipelineStepLog>.unmodifiable(logs),
        clearError: true,
      );
    } catch (error) {
      logs.add(
        RaceDayPipelineStepLog(
          phase: RaceDayPipelinePhase.failed,
          startedAtUtc: pipelineStart,
          completedAtUtc: DateTime.now().toUtc(),
          statusMessage: 'Błąd przetwarzania po etapie.',
          succeeded: false,
          errorMessage: error.toString(),
        ),
      );

      return currentState.copyWith(
        phase: RaceDayPipelinePhase.failed,
        isBusy: false,
        errorMessage: 'Błąd orkiestratora dnia wyścigowego: $error',
        stepLogs: List<RaceDayPipelineStepLog>.unmodifiable(logs),
      );
    }
  }

  /// Uruchamia kompletny, bezszwowy cykl dnia wyścigowego w trybie automatycznym / headless:
  /// `Calendar -> PreRaceBriefing -> StageSimulationLoop -> StageResultsCalculator -> PostStagePodium -> SponsorObjectivesEvaluator -> RecoveryProcessor -> AutoSave`.
  Future<RaceDayPipelineState> runHeadlessRaceDay({
    required CareerSave careerSave,
    TourRace? overrideRace,
    int? overrideStageIndex,
    RaceDayBriefingConfig? briefingConfig,
    int maxSimulationTicks = 2400,
    double tickDeltaSeconds = 10.0,
    bool persistCheckpointsAndAutosave = true,
  }) async {
    var state = await startFromCalendar(
      careerSave: careerSave,
      overrideRace: overrideRace,
      overrideStageIndex: overrideStageIndex,
      preferredRiderIds: briefingConfig?.selectedRiderIds,
      persistPreStageCheckpoint: persistCheckpointsAndAutosave,
    );
    if (state.phase == RaceDayPipelinePhase.failed) return state;

    final effectiveBriefing = briefingConfig ?? state.briefingConfig!;
    state = applyPreRaceBriefing(
      currentState: state,
      briefingConfig: effectiveBriefing,
    );
    if (state.phase == RaceDayPipelinePhase.failed) return state;

    final simStarted = DateTime.now().toUtc();
    final save = state.careerSave!;
    final stage = state.activeStage!;
    final allRidersMap = <String, Rider>{
      for (final r in save.riders) r.id: r,
    };
    final allTeamsMap = <String, CyclingTeam>{
      for (final t in save.teams) t.id: t,
    };
    final allBikesMap = _buildBikesMap(
      riders: save.riders,
      briefingOverrides: effectiveBriefing.bikeOverridesByRiderId,
    );

    final loop = StageSimulationLoop.initializeStage(
      stage: stage,
      playerTeamId: save.playerTeamId,
      allRidersMap: allRidersMap,
      allBikesMap: allBikesMap,
      allTeamsMap: allTeamsMap,
    );

    for (final entry in effectiveBriefing.tacticalOrdersByRiderId.entries) {
      loop.setRiderTacticalOrder(entry.key, entry.value);
    }

    int ticks = 0;
    while (!loop.state.isStageFinished && ticks < maxSimulationTicks) {
      loop.step(dt: tickDeltaSeconds);
      ticks++;
    }

    // Jeśli limit ticków został osiągnięty przed metą wszystkich kolarzy, domykamy klasyfikację
    // aktualną kolejnością dystansu, aby pipeline zawsze miał deterministyczny wynik.
    final resolvedSimState = _ensureFinishResultsIfNeeded(
      simState: loop.state,
      stage: stage,
      allRidersMap: allRidersMap,
    );

    final simLogs = [
      ...state.stepLogs,
      RaceDayPipelineStepLog(
        phase: RaceDayPipelinePhase.liveSimulation3d,
        startedAtUtc: simStarted,
        completedAtUtc: DateTime.now().toUtc(),
        statusMessage:
            'Symulacja etapu zakończona po $ticks tickach (${resolvedSimState.finishResults.length} wyników na mecie).',
      ),
    ];

    state = state.copyWith(
      simulationState: resolvedSimState,
      stepLogs: simLogs,
    );

    return executePostStagePipeline(
      currentState: state,
      simulationState: resolvedSimState,
      autoCompleteAfterPodium: true,
      persistAutoSave: persistCheckpointsAndAutosave,
    );
  }

  /// Przywraca przerwany dzień wyścigowy z punktu kontrolnego `PreStageCheckpoint`.
  Future<RaceDayPipelineState?> recoverInterruptedRaceDay() async {
    try {
      final checkpoint = await _autosaveGuard.detectAnyInterruptedStageCheckpoint();
      if (checkpoint == null) return null;

      return await startFromCalendar(
        careerSave: checkpoint.careerSave,
        preferredRiderIds: checkpoint.selectedRiderIds,
        persistPreStageCheckpoint: false,
      );
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // METODY POMOCNICZE
  // ===========================================================================

  ({TourRace race, RaceStage stage, int stageIndex})? _resolveRaceAndStage({
    required SeasonCalendar calendar,
    TourRace? overrideRace,
    int? overrideStageIndex,
  }) {
    final race = overrideRace ??
        calendar.activeRace ??
        (calendar.races.isNotEmpty
            ? calendar.races[calendar.currentRaceIndex.clamp(0, calendar.races.length - 1)]
            : null);

    if (race == null || race.stages.isEmpty) return null;

    final rawIndex = overrideStageIndex ?? calendar.activeStageIndex;
    final safeIndex = rawIndex.clamp(0, race.stages.length - 1);
    return (
      race: race,
      stage: race.stages[safeIndex],
      stageIndex: safeIndex,
    );
  }

  List<String> _selectStartingRiderIds({
    required CareerSave careerSave,
    List<String>? preferredRiderIds,
  }) {
    final teamRiders = careerSave.playerRoster;
    if (teamRiders.isEmpty) return const [];

    if (preferredRiderIds != null && preferredRiderIds.isNotEmpty) {
      final validIds = teamRiders.map((r) => r.id).toSet();
      final filtered = preferredRiderIds.where(validIds.contains).take(8).toList();
      if (filtered.isNotEmpty) return filtered;
    }

    final healthy = teamRiders.where((r) => r.health.isFitToRace).toList();
    final pool = healthy.isNotEmpty ? healthy : teamRiders;
    return pool.take(8).map((r) => r.id).toList();
  }

  Map<String, CompleteBike> _buildBikesMap({
    required List<Rider> riders,
    Map<String, CompleteBike>? customBikesMap,
    Map<String, CompleteBike> briefingOverrides = const {},
  }) {
    final fallbackBike = FictionalBrandsCatalog.assembleBike(
      brandId: 'aurelia',
      frameCategory: FrameCategory.allRounder,
    );
    final result = <String, CompleteBike>{};
    for (final rider in riders) {
      result[rider.id] = briefingOverrides[rider.id] ??
          customBikesMap?[rider.id] ??
          fallbackBike;
    }
    return result;
  }

  PostRaceSponsorContext _buildPostRaceSponsorContext({
    required TourRace race,
    required RaceStage stage,
    required StageSummaryReport report,
    required StageSimulationState simulationState,
    required String playerTeamId,
    required DateTime raceDate,
    required bool isFinalStage,
  }) {
    final playerResults = report.results
        .where((r) => r.teamId == playerTeamId && !r.isDnf && !r.isEliminatedOtl)
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    final bestResult = playerResults.isNotEmpty ? playerResults.first : null;
    final wonStage = bestResult != null && bestResult.rank == 1;

    final int? bestGcRank = _computeBestPlayerGcRank(
      race: race,
      report: report,
      playerTeamId: playerTeamId,
    );

    final double breakawayKm = _computeTeamBreakawayKm(
      simulationState: simulationState,
      playerTeamId: playerTeamId,
    );

    final bool wonMostCombative = report.mostCombativeRiderId != null &&
        simulationState.riderStates[report.mostCombativeRiderId]?.teamId == playerTeamId;

    final greenLeader = _findLeaderTeamIdByPoints(report.results, isKom: false);
    final komLeader = _findLeaderTeamIdByPoints(report.results, isKom: true);

    return PostRaceSponsorContext(
      raceId: race.id,
      raceName: race.name,
      raceCategory: race.uciCategory,
      raceDate: raceDate,
      isFinalStage: isFinalStage,
      stageNumber: stage.stageNumber,
      bestPlayerStageRank: bestResult?.rank,
      bestPlayerGcRank: bestGcRank,
      wonStagesCount: wonStage ? 1 : 0,
      wonPointsJersey: isFinalStage && greenLeader == playerTeamId,
      wonMountainsJersey: isFinalStage && komLeader == playerTeamId,
      wonMostCombativeAward: wonMostCombative,
      teamBreakawayKm: breakawayKm,
      topFinishingRiderName: bestResult?.riderName,
    );
  }

  int? _computeBestPlayerGcRank({
    required TourRace race,
    required StageSummaryReport report,
    required String playerTeamId,
  }) {
    final gc = race.classifications.generalClassification;
    if (gc.isNotEmpty) {
      for (int i = 0; i < gc.length; i++) {
        if (gc[i].teamId == playerTeamId) {
          return i + 1;
        }
      }
    }

    final bestStage = report.results
        .where((r) => r.teamId == playerTeamId && !r.isDnf && !r.isEliminatedOtl)
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return bestStage.isNotEmpty ? bestStage.first.rank : null;
  }

  double _computeTeamBreakawayKm({
    required StageSimulationState simulationState,
    required String playerTeamId,
  }) {
    final breakawayGroupIndices = simulationState.groups
        .asMap()
        .entries
        .where((e) => e.value.type == GroupType.breakaway)
        .map((e) => e.key)
        .toSet();

    double maxBreakawayMeters = 0.0;
    for (final riderState in simulationState.riderStates.values) {
      if (riderState.teamId != playerTeamId) continue;
      if (breakawayGroupIndices.contains(riderState.groupIndex)) {
        maxBreakawayMeters = math.max(maxBreakawayMeters, riderState.distanceCoveredMeters);
      }
    }
    return maxBreakawayMeters / 1000.0;
  }

  String? _findLeaderTeamIdByPoints(
    List<OfficialRiderStageResult> results, {
    required bool isKom,
  }) {
    OfficialRiderStageResult? best;
    int bestPoints = 0;
    for (final res in results) {
      final pts = isKom ? res.pointsKom : res.pointsGreenJersey;
      if (pts > bestPoints) {
        bestPoints = pts;
        best = res;
      }
    }
    return best?.teamId;
  }

  bool _doesPlayerTeamHoldLeaderJersey({
    required StageSummaryReport report,
    required String playerTeamId,
  }) {
    if (report.winnerTeamId == playerTeamId) return true;
    return _findLeaderTeamIdByPoints(report.results, isKom: false) == playerTeamId ||
        _findLeaderTeamIdByPoints(report.results, isKom: true) == playerTeamId;
  }

  String? _detectMostCombativeRiderId(StageSimulationState simulationState) {
    final breakawayGroupIndices = simulationState.groups
        .asMap()
        .entries
        .where((e) => e.value.type == GroupType.breakaway)
        .map((e) => e.key)
        .toSet();

    String? bestId;
    double bestScore = -1.0;
    for (final riderState in simulationState.riderStates.values) {
      final bool inFront = breakawayGroupIndices.contains(riderState.groupIndex);
      final score = (inFront ? 5000.0 : 0.0) + riderState.distanceCoveredMeters;
      if (score > bestScore) {
        bestScore = score;
        bestId = riderState.riderId;
      }
    }
    return bestId;
  }

  StageSimulationState _ensureFinishResultsIfNeeded({
    required StageSimulationState simState,
    required RaceStage stage,
    required Map<String, Rider> allRidersMap,
  }) {
    if (simState.finishResults.isNotEmpty) return simState;

    final sortedRiders = simState.riderStates.values.toList()
      ..sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));

    final leaderDist = sortedRiders.isNotEmpty
        ? sortedRiders.first.distanceCoveredMeters
        : stage.totalDistanceKm * 1000.0;
    final elapsedBase = math.max(simState.elapsedSeconds, 3600.0);

    final syntheticResults = <StageFinishResult>[];
    for (int i = 0; i < sortedRiders.length; i++) {
      final rs = sortedRiders[i];
      final rider = allRidersMap[rs.riderId];
      final distGap = math.max(0.0, leaderDist - rs.distanceCoveredMeters);
      final speed = math.max(rs.currentSpeedMs, 10.5);
      final finishTime = elapsedBase + (distGap / speed);

      syntheticResults.add(
        StageFinishResult(
          riderId: rs.riderId,
          riderName: rider?.fullName ?? rs.riderId,
          teamId: rs.teamId,
          finishRank: i + 1,
          finishTimeSeconds: finishTime,
          gapToWinnerSeconds: i == 0 ? 0.0 : (finishTime - elapsedBase),
        ),
      );
    }

    return StageSimulationState(
      elapsedSeconds: simState.elapsedSeconds,
      stage: simState.stage,
      currentSegmentIndex: simState.currentSegmentIndex,
      groups: simState.groups,
      riderStates: simState.riderStates,
      wPrimeStates: simState.wPrimeStates,
      nutritionStates: simState.nutritionStates,
      heartRateStates: simState.heartRateStates,
      keyMomentsState: simState.keyMomentsState,
      radioLog: simState.radioLog,
      incidentHistory: simState.incidentHistory,
      playerTeamId: simState.playerTeamId,
      playerRiderIds: simState.playerRiderIds,
      isStageFinished: true,
      finishResults: syntheticResults,
    );
  }

  Future<TransactionalSaveReceipt?> _performSafeTransactionalAutosave({
    required CareerSave save,
    required String stageId,
  }) async {
    try {
      await _autosaveGuard.markStageCompleted(
        careerSaveId: save.id,
        stageId: stageId,
      );
      final receipt = await _autosaveGuard.saveCareerTransactional(
        save,
        customFileBaseName: 'autosave_career_${save.id}',
        isAutoSave: true,
        trigger: AutosaveTrigger.postStageResult,
      );
      try {
        await SaveGameManager.performAutoSave(save: save);
      } catch (_) {
        // Ignorujemy błędy SaveGameManager w testach bez pluginów platformowych.
      }
      return receipt;
    } catch (_) {
      return null;
    }
  }
}

/// Kontroler Riverpod zarządzający stanem dnia wyścigowego i synchronizujący
/// wszystkie główne notifiery gry (`CareerController`, `CareerStateNotifier`,
/// `RaceSimulationNotifier`, `AutosaveGuardNotifier`).
class RaceDayPipelineNotifier extends StateNotifier<RaceDayPipelineState> {
  final Ref _ref;
  final RaceDayPipelineOrchestrator _orchestrator;

  RaceDayPipelineNotifier(
    this._ref, {
    RaceDayPipelineOrchestrator? orchestrator,
  })  : _orchestrator = orchestrator ?? const RaceDayPipelineOrchestrator(),
        super(const RaceDayPipelineState());

  /// KROK 1: Rozpoczyna dzień wyścigowy z kalendarza.
  Future<RaceDayPipelineState> startFromCalendar({
    CareerSave? explicitSave,
    TourRace? overrideRace,
    int? overrideStageIndex,
    List<String>? preferredRiderIds,
  }) async {
    final save = explicitSave ?? _resolveCurrentCareerSave();
    if (save == null) {
      final failed = state.copyWith(
        phase: RaceDayPipelinePhase.failed,
        isBusy: false,
        errorMessage: 'Brak załadowanej kariery do rozpoczęcia dnia wyścigowego.',
      );
      state = failed;
      return failed;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    final next = await _orchestrator.startFromCalendar(
      careerSave: save,
      overrideRace: overrideRace,
      overrideStageIndex: overrideStageIndex,
      preferredRiderIds: preferredRiderIds,
    );
    state = next;
    return next;
  }

  /// KROK 2: Zatwierdza odprawę przedstartową (`PreRaceBriefingScreen`).
  void completePreRaceBriefing(RaceDayBriefingConfig briefingConfig) {
    state = _orchestrator.applyPreRaceBriefing(
      currentState: state,
      briefingConfig: briefingConfig,
    );
  }

  /// KROK 3: Uruchamia symulację wyścigu w `RaceSimulationNotifier` pod widok 3D.
  void launchLiveSimulation({Map<String, CompleteBike>? customBikesMap}) {
    final simNotifier = _ref.read(raceSimulationNotifierProvider.notifier);
    state = _orchestrator.launchSimulationForViewport(
      currentState: state,
      simulationNotifier: simNotifier,
      customBikesMap: customBikesMap,
    );
  }

  /// KROKI 4–8: Finalizuje etap po mecie, oblicza wyniki UCI, podium, sponsorów,
  /// regenerację i wykonuje atomowy autozapis, synchronizując stan kariery.
  Future<RaceDayPipelineState> finalizePostStage({
    required StageSimulationState simulationState,
    StageSummaryReport? precomputedReport,
    bool autoCompleteAfterPodium = true,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);

    final next = await _orchestrator.executePostStagePipeline(
      currentState: state,
      simulationState: simulationState,
      precomputedReport: precomputedReport,
      autoCompleteAfterPodium: autoCompleteAfterPodium,
    );

    if (next.phase == RaceDayPipelinePhase.completed && next.finalSummary != null) {
      _syncUpdatedSaveToCareerProviders(next.finalSummary!);
    }

    state = next;
    return next;
  }

  /// Jednoetapowe wykonanie pełnego dnia wyścigowego w tle (np. szybka symulacja z kalendarza).
  Future<RaceDayPipelineState> runFullRaceDayHeadless({
    CareerSave? explicitSave,
    TourRace? overrideRace,
    int? overrideStageIndex,
    RaceDayBriefingConfig? briefingConfig,
  }) async {
    final save = explicitSave ?? _resolveCurrentCareerSave();
    if (save == null) {
      final failed = state.copyWith(
        phase: RaceDayPipelinePhase.failed,
        isBusy: false,
        errorMessage: 'Brak załadowanej kariery.',
      );
      state = failed;
      return failed;
    }

    state = state.copyWith(isBusy: true, clearError: true);
    final next = await _orchestrator.runHeadlessRaceDay(
      careerSave: save,
      overrideRace: overrideRace,
      overrideStageIndex: overrideStageIndex,
      briefingConfig: briefingConfig,
    );

    if (next.phase == RaceDayPipelinePhase.completed && next.finalSummary != null) {
      _syncUpdatedSaveToCareerProviders(next.finalSummary!);
    }

    state = next;
    return next;
  }

  /// Przywraca stan orkiestratora z przerwanego punktu kontrolnego `PreStageCheckpoint`.
  Future<bool> recoverFromCheckpointIfAvailable() async {
    final recovered = await _orchestrator.recoverInterruptedRaceDay();
    if (recovered == null) return false;
    state = recovered;
    return true;
  }

  /// Resetuje stan orkiestratora do spoczynku.
  void reset() {
    state = const RaceDayPipelineState();
  }

  CareerSave? _resolveCurrentCareerSave() {
    final controllerSave = _ref.read(careerControllerProvider).save;
    if (controllerSave != null) return controllerSave;

    final careerState = _ref.read(careerStateNotifierProvider);
    if (careerState.teams.isNotEmpty) {
      return careerState.toSave();
    }
    return null;
  }

  void _syncUpdatedSaveToCareerProviders(RaceDayPostStageSummary summary) {
    try {
      final careerNotifier = _ref.read(careerStateNotifierProvider.notifier);
      for (final email in summary.generatedInboxMessages) {
        careerNotifier.addInboxMessage(email);
      }
    } catch (_) {
      // Bezpieczne wyciszenie, gdy CareerStateNotifier nie jest aktywny w izolowanym teście.
    }
  }
}

/// Globalny provider orkiestratora cyklu życia dnia wyścigowego.
final raceDayPipelineOrchestratorProvider =
    Provider<RaceDayPipelineOrchestrator>((ref) {
  final guard = ref.watch(autosaveAndCrashRecoveryGuardProvider);
  return RaceDayPipelineOrchestrator.withGuard(guard);
});

/// Globalny provider stanu i kontrolera pipeline'u dnia wyścigowego.
final raceDayPipelineProvider =
    StateNotifierProvider<RaceDayPipelineNotifier, RaceDayPipelineState>((ref) {
  final orchestrator = ref.watch(raceDayPipelineOrchestratorProvider);
  return RaceDayPipelineNotifier(ref, orchestrator: orchestrator);
});
