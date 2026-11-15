import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/peloton/rider_race_state.dart';
import '../engine/simulation/key_moments_detector.dart';
import '../engine/simulation/stage_results_calculator.dart';
import '../engine/simulation/stage_simulation_loop.dart';
import '../models/equipment/complete_bike.dart';
import '../models/race/race_stage.dart';
import '../models/race/stage_segment.dart';
import '../models/rider/rider.dart';
import '../models/team/cycling_team.dart';

/// Stan telemetryczny i operacyjny symulatora wyścigu 3D dla UI / HUD.
class RaceSimulationUiState {
  final StageSimulationState? simulationState;
  final String? selectedRiderId;
  final bool isPaused;
  final KeyMomentTrigger? activeNotification;
  final StageSummaryReport? stageSummaryReport;

  const RaceSimulationUiState({
    this.simulationState,
    this.selectedRiderId,
    this.isPaused = false,
    this.activeNotification,
    this.stageSummaryReport,
  });

  /// Czy etap jest aktualnie zainicjalizowany i gotowy do symulacji
  bool get hasActiveStage => simulationState != null;

  /// Czy etap został ukończony przez peleton
  bool get isFinished => simulationState?.isStageFinished ?? false;

  /// Aktualny etap wyścigu
  RaceStage? get stage => simulationState?.stage;

  /// Aktualny segment trasy
  StageSegment? get currentSegment {
    final sim = simulationState;
    if (sim == null || sim.stage.segments.isEmpty) return null;
    final idx = sim.currentSegmentIndex.clamp(0, sim.stage.segments.length - 1);
    return sim.stage.segments[idx];
  }

  /// Stan wybranego kolarza w kamerze HUD
  RiderRaceState? get selectedRiderState {
    if (selectedRiderId == null || simulationState == null) return null;
    return simulationState!.riderStates[selectedRiderId];
  }

  /// Lista kolarzy z drużyny gracza
  List<RiderRaceState> get playerRiderStates {
    final sim = simulationState;
    if (sim == null) return const [];
    return sim.playerRiderIds
        .map((id) => sim.riderStates[id])
        .whereType<RiderRaceState>()
        .toList();
  }

  RaceSimulationUiState copyWith({
    StageSimulationState? simulationState,
    String? selectedRiderId,
    bool? isPaused,
    KeyMomentTrigger? activeNotification,
    bool clearNotification = false,
    StageSummaryReport? stageSummaryReport,
  }) {
    return RaceSimulationUiState(
      simulationState: simulationState ?? this.simulationState,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      isPaused: isPaused ?? this.isPaused,
      activeNotification: clearNotification
          ? null
          : (activeNotification ?? this.activeNotification),
      stageSummaryReport: stageSummaryReport ?? this.stageSummaryReport,
    );
  }
}

/// Kontroler symulacji etapu łączący pętlę fizyczną [StageSimulationLoop] z interfejsem graficznym.
class RaceSimulationController extends StateNotifier<RaceSimulationUiState> {
  RaceSimulationController() : super(const RaceSimulationUiState());

  StageSimulationLoop? _loop;
  Timer? _tickerTimer;

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  /// Inicjalizuje nowy etap wyścigu
  void initializeStage({
    required RaceStage stage,
    required String playerTeamId,
    required Map<String, Rider> allRidersMap,
    required Map<String, CompleteBike> allBikesMap,
    required Map<String, CyclingTeam> allTeamsMap,
  }) {
    _tickerTimer?.cancel();

    _loop = StageSimulationLoop.initializeStage(
      stage: stage,
      playerTeamId: playerTeamId,
      allRidersMap: allRidersMap,
      allBikesMap: allBikesMap,
      allTeamsMap: allTeamsMap,
    );

    final playerTeam = allTeamsMap[playerTeamId];
    final defaultSelectedRider = (playerTeam?.rosterRiderIds.isNotEmpty ?? false)
        ? playerTeam!.rosterRiderIds.first
        : (allRidersMap.keys.isNotEmpty ? allRidersMap.keys.first : null);

    state = RaceSimulationUiState(
      simulationState: _loop!.state,
      selectedRiderId: defaultSelectedRider,
      isPaused: false,
      activeNotification: null,
      stageSummaryReport: null,
    );

    _startTicker();
  }

  /// Uruchamia pętlę zegara symulacji (60 FPS lub 10 FPS w zależności od platformy)
  void _startTicker() {
    _tickerTimer?.cancel();
    // Odświeżanie telemetryczne co 100 ms (10 Hz dla płynności HUD i obliczeń)
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!state.isPaused && _loop != null && !_loop!.state.isStageFinished) {
        stepSimulation(0.1);
      }
    });
  }

  /// Wykonuje pojedynczy krok symulacji z uwzględnieniem mnożnika prędkości
  void stepSimulation(double realDeltaSeconds) {
    if (_loop == null || state.isPaused) return;

    final multiplier = _loop!.state.timeSpeed.multiplier;
    final dt = realDeltaSeconds * multiplier;

    final newState = _loop!.step(dt: dt);

    KeyMomentTrigger? notif = state.activeNotification;
    if (newState.activeKeyMoment != null) {
      notif = newState.activeKeyMoment;
    }

    state = state.copyWith(
      simulationState: newState,
      activeNotification: notif,
    );

    // Jeśli etap dobiegł końca, wyliczamy oficjalne wyniki UCI
    if (newState.isStageFinished && state.stageSummaryReport == null) {
      _concludeStage();
    }
  }

  /// Błyskawicznie przelicza symulację fizyki aż do następnego kluczowego momentu
  /// lub do linii mety etapu (Fast-Forward to Next Key Moment).
  void simulateToNextKeyMoment() {
    if (_loop == null) return;

    final updatedState = _loop!.simulateToNextKeyMoment(maxSteps: 20000, stepDt: 2.0);

    state = state.copyWith(
      simulationState: updatedState,
      activeNotification: updatedState.activeKeyMoment,
    );

    if (updatedState.isStageFinished && state.stageSummaryReport == null) {
      _concludeStage();
    }
  }

  /// Zmienia prędkość upływu czasu (1x, 2x, 4x, 8x, Instant)
  void setSimulationSpeed(SimulationTimeSpeed speed) {
    if (_loop == null) return;
    _loop!.setSpeed(speed);
    state = state.copyWith(simulationState: _loop!.state);

    if (speed == SimulationTimeSpeed.instantToKeyMoment) {
      simulateToNextKeyMoment();
    }
  }

  /// Przełącza pauzę symulacji
  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  /// Wybiera kolarza do śledzenia w kamerze i na widżecie telemetrycznym
  void selectRider(String riderId) {
    state = state.copyWith(selectedRiderId: riderId);
  }

  /// Zamyka powiadomienie o kluczowym momencie na HUD
  void dismissNotification() {
    state = state.copyWith(clearNotification: true);
  }

  /// Wydaje rozkaz taktyczny wybranemu kolarzowi
  void issueTacticalOrder(String riderId, TacticalOrder order) {
    if (_loop == null) return;
    _loop!.setRiderTacticalOrder(riderId, order);
    state = state.copyWith(simulationState: _loop!.state);
  }

  /// Kończy etap i uruchamia oficjalny kalkulator wyników UCI
  void _concludeStage() {
    if (_loop == null) return;
    final simState = _loop!.state;

    final summaryReport = StageResultsCalculator.calculateOfficialStageResults(
      stage: simState.stage,
      finishResults: simState.finishResults,
      allRidersMap: _loop!.allRidersMap,
      incidents: simState.incidentHistory,
      playerTeamId: simState.playerTeamId,
    );

    state = state.copyWith(stageSummaryReport: summaryReport);
  }
}

/// Globalny dostawca Riverpod dla symulatora wyścigu
final raceSimulationProvider =
    StateNotifierProvider<RaceSimulationController, RaceSimulationUiState>((ref) {
  return RaceSimulationController();
});

