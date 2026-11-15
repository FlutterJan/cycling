import 'dart:math' as math;
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../events/race_incident_engine.dart';
import '../events/race_radio_generator.dart';
import '../peloton/breakaway_ai_controller.dart';
import '../peloton/drafting_grid_system.dart';
import '../peloton/echelon_crosswind_engine.dart';
import '../peloton/mountain_gc_ai_controller.dart';
import '../peloton/peloton_chase_ai_controller.dart';
import '../peloton/rider_race_state.dart';
import '../peloton/sprint_train_ai_controller.dart';
import '../peloton/tactical_orders_processor.dart';
import '../physics/aero_calculator.dart';
import '../physics/gravity_and_rolling_calculator.dart';
import '../physics/heart_rate_simulator.dart';
import '../physics/nutrition_and_glycogen_engine.dart';
import '../physics/speed_solver.dart';
import '../physics/w_prime_balance_engine.dart';
import 'key_moments_detector.dart';

/// Mnożnik prędkości symulacji etapu.
enum SimulationTimeSpeed {
  /// 1x: Czas rzeczywisty (interaktywny tryb 3D)
  x1,

  /// 2x: Przyspieszenie dwukrotne
  x2,

  /// 4x: Przyspieszenie czterokrotne
  x4,

  /// 8x: Przyspieszenie ośmiokrotne
  x8,

  /// Błyskawiczne przeliczenie matematyczne w tle aż do kolejnego kluczowego momentu
  instantToKeyMoment;

  double get multiplier {
    switch (this) {
      case SimulationTimeSpeed.x1:
        return 1.0;
      case SimulationTimeSpeed.x2:
        return 2.0;
      case SimulationTimeSpeed.x4:
        return 4.0;
      case SimulationTimeSpeed.x8:
        return 8.0;
      case SimulationTimeSpeed.instantToKeyMoment:
        return 50.0;
    }
  }

  String get label {
    switch (this) {
      case SimulationTimeSpeed.x1:
        return '1x';
      case SimulationTimeSpeed.x2:
        return '2x';
      case SimulationTimeSpeed.x4:
        return '4x';
      case SimulationTimeSpeed.x8:
        return '8x';
      case SimulationTimeSpeed.instantToKeyMoment:
        return 'Instant ⏩';
    }
  }

  String toJson() => name;
}

/// Wynik kolarza na mecie etapu.
class StageFinishResult {
  final String riderId;
  final String riderName;
  final String teamId;
  final int finishRank;
  final double finishTimeSeconds;
  final double gapToWinnerSeconds;

  const StageFinishResult({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.finishRank,
    required this.finishTimeSeconds,
    required this.gapToWinnerSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'teamId': teamId,
      'finishRank': finishRank,
      'finishTimeSeconds': finishTimeSeconds,
      'gapToWinnerSeconds': gapToWinnerSeconds,
    };
  }

  factory StageFinishResult.fromJson(Map<String, dynamic> json) {
    return StageFinishResult(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      finishRank: (json['finishRank'] as num).toInt(),
      finishTimeSeconds: (json['finishTimeSeconds'] as num).toDouble(),
      gapToWinnerSeconds: (json['gapToWinnerSeconds'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return '#$finishRank $riderName ($teamId) +${gapToWinnerSeconds.toStringAsFixed(1)}s';
  }
}

/// Pełny stan symulacji etapu w danym momencie wyścigu.
class StageSimulationState {
  final double elapsedSeconds;
  final RaceStage stage;
  final int currentSegmentIndex;
  final List<PelotonGroup> groups;
  final Map<String, RiderRaceState> riderStates;
  final Map<String, WPrimeState> wPrimeStates;
  final Map<String, NutritionState> nutritionStates;
  final Map<String, HeartRateState> heartRateStates;
  final KeyMomentsDetectorState keyMomentsState;
  final List<RaceRadioMessage> radioLog;
  final List<RaceIncidentEvent> incidentHistory;
  final String playerTeamId;
  final List<String> playerRiderIds;
  final bool isStageFinished;
  final List<StageFinishResult> finishResults;
  final SimulationTimeSpeed timeSpeed;
  final KeyMomentTrigger? activeKeyMoment;

  const StageSimulationState({
    required this.elapsedSeconds,
    required this.stage,
    required this.currentSegmentIndex,
    required this.groups,
    required this.riderStates,
    required this.wPrimeStates,
    required this.nutritionStates,
    required this.heartRateStates,
    required this.keyMomentsState,
    required this.radioLog,
    required this.incidentHistory,
    required this.playerTeamId,
    required this.playerRiderIds,
    this.isStageFinished = false,
    this.finishResults = const [],
    this.timeSpeed = SimulationTimeSpeed.x1,
    this.activeKeyMoment,
  });

  /// Aktualny kilometraż czoła wyścigu [km]
  double get leadKilometerMark {
    if (riderStates.isEmpty) return 0.0;
    final maxDistMeters = riderStates.values.map((s) => s.distanceCoveredMeters).reduce(math.max);
    return maxDistMeters / 1000.0;
  }

  /// Kilometry pozostałe do mety dla czoła wyścigu [km]
  double get leadDistanceToFinishKm => math.max(0.0, stage.totalDistanceKm - leadKilometerMark);

  StageSimulationState copyWith({
    double? elapsedSeconds,
    RaceStage? stage,
    int? currentSegmentIndex,
    List<PelotonGroup>? groups,
    Map<String, RiderRaceState>? riderStates,
    Map<String, WPrimeState>? wPrimeStates,
    Map<String, NutritionState>? nutritionStates,
    Map<String, HeartRateState>? heartRateStates,
    KeyMomentsDetectorState? keyMomentsState,
    List<RaceRadioMessage>? radioLog,
    List<RaceIncidentEvent>? incidentHistory,
    String? playerTeamId,
    List<String>? playerRiderIds,
    bool? isStageFinished,
    List<StageFinishResult>? finishResults,
    SimulationTimeSpeed? timeSpeed,
    KeyMomentTrigger? activeKeyMoment,
    bool clearActiveKeyMoment = false,
  }) {
    return StageSimulationState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      stage: stage ?? this.stage,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      groups: groups ?? this.groups,
      riderStates: riderStates ?? this.riderStates,
      wPrimeStates: wPrimeStates ?? this.wPrimeStates,
      nutritionStates: nutritionStates ?? this.nutritionStates,
      heartRateStates: heartRateStates ?? this.heartRateStates,
      keyMomentsState: keyMomentsState ?? this.keyMomentsState,
      radioLog: radioLog ?? this.radioLog,
      incidentHistory: incidentHistory ?? this.incidentHistory,
      playerTeamId: playerTeamId ?? this.playerTeamId,
      playerRiderIds: playerRiderIds ?? this.playerRiderIds,
      isStageFinished: isStageFinished ?? this.isStageFinished,
      finishResults: finishResults ?? this.finishResults,
      timeSpeed: timeSpeed ?? this.timeSpeed,
      activeKeyMoment: clearActiveKeyMoment ? null : (activeKeyMoment ?? this.activeKeyMoment),
    );
  }
}

/// Główny silnik pętli symulacji etapu (Stage Simulation Loop).
///
/// Spina w jedną harmonijną całość:
/// - Wszystkie kalkulatory fizyki: Aerodynamikę ([AeroCalculator]), grawitację i toczenie ([GravityAndRollingCalculator]),
///   równanie ruchu Newtona ([SpeedSolver]).
/// - Fizjologię kolarzy: baterię beztlenową ([WPrimeBalanceEngine]), magazyny glikogenu ([NutritionAndGlycogenEngine]),
///   tętno i inercję układu krążenia ([HeartRateSimulator]).
/// - Dynamikę peletonu: siatkę 2D i oszczędności draftingu ([DraftingGridSystem]), wachlarze boczne ([EchelonCrosswindEngine]),
///   procesor rozkazów taktycznych ([TacticalOrdersProcessor]).
/// - Sztuczną inteligencję wyścigu: formowanie ucieczki ([BreakawayAiController]), pościg lokomotywy peletonu ([PelotonChaseAiController]),
///   pociągi górskie GC ([MountainGcAiController]), pociągi sprinterskie ([SprintTrainAiController]).
/// - Zdarzenia losowe i komunikaty: kraksy i defekty ([RaceIncidentEngine]), Radio Wyścigu ([RaceRadioGenerator]).
/// - Detektor kluczowych momentów ([KeyMomentsDetector]), zatrzymujący symulację w tle i przełączający w tryb 3D.
class StageSimulationLoop {
  final Map<String, Rider> allRidersMap;
  final Map<String, CompleteBike> allBikesMap;
  final Map<String, CyclingTeam> allTeamsMap;
  final math.Random random;

  StageSimulationState state;

  StageSimulationLoop({
    required this.allRidersMap,
    required this.allBikesMap,
    required this.allTeamsMap,
    required this.state,
    math.Random? random,
  }) : random = random ?? math.Random();

  /// Tworzy nową instancję pętli na starcie etapu.
  factory StageSimulationLoop.initializeStage({
    required RaceStage stage,
    required String playerTeamId,
    required Map<String, Rider> allRidersMap,
    required Map<String, CompleteBike> allBikesMap,
    required Map<String, CyclingTeam> allTeamsMap,
    math.Random? random,
  }) {
    final playerTeam = allTeamsMap[playerTeamId];
    final playerRiderIds = playerTeam?.rosterRiderIds ?? <String>[];

    final Map<String, RiderRaceState> initialRiderStates = {};
    final Map<String, WPrimeState> initialWPrime = {};
    final Map<String, NutritionState> initialNutrition = {};
    final Map<String, HeartRateState> initialHeartRate = {};

    final allRiderIdsList = allRidersMap.keys.toList();

    for (final riderId in allRiderIdsList) {
      final rider = allRidersMap[riderId];
      if (rider == null) continue;

      initialRiderStates[riderId] = RiderRaceState.initial(
        riderId: riderId,
        teamId: rider.contract.teamId,
        initialWPrimeJoules: rider.physiology.wPrimeJoules.toDouble(),
        initialGlycogenGrams: rider.physiology.glycogenCapacityGrams,
        groupIndex: 0,
      );

      initialWPrime[riderId] = WPrimeState.initial(rider.physiology);
      initialNutrition[riderId] = NutritionState.initial(rider.physiology);
      initialHeartRate[riderId] = HeartRateState.initial(rider.physiology);
    }

    final initialGroup = PelotonGroup(
      id: 'main_peloton',
      type: GroupType.peloton,
      riderIds: allRiderIdsList,
      pacemakerRiderIds: allRiderIdsList.take(4).toList(),
      positions: const [],
      gapToRaceLeaderSeconds: 0.0,
      distanceCoveredKm: 0.0,
      averageSpeedKmh: 42.0,
    );

    final initialState = StageSimulationState(
      elapsedSeconds: 0.0,
      stage: stage,
      currentSegmentIndex: 0,
      groups: [initialGroup],
      riderStates: initialRiderStates,
      wPrimeStates: initialWPrime,
      nutritionStates: initialNutrition,
      heartRateStates: initialHeartRate,
      keyMomentsState: const KeyMomentsDetectorState(),
      radioLog: const [],
      incidentHistory: const [],
      playerTeamId: playerTeamId,
      playerRiderIds: playerRiderIds,
      timeSpeed: SimulationTimeSpeed.x1,
    );

    return StageSimulationLoop(
      allRidersMap: allRidersMap,
      allBikesMap: allBikesMap,
      allTeamsMap: allTeamsMap,
      state: initialState,
      random: random,
    );
  }

  /// Wykonuje pojedynczy krok symulacji o zadanym czasie [dt] sekund (domyślnie 1.0 s).
  StageSimulationState step({double dt = 1.0}) {
    if (state.isStageFinished) return state;

    final double newElapsed = state.elapsedSeconds + dt;
    final double leadKm = state.leadKilometerMark;
    final double stageLengthKm = state.stage.totalDistanceKm;

    // 1. Znalezienie aktualnego segmentu trasy
    int currentSegIdx = state.currentSegmentIndex;
    if (currentSegIdx < state.stage.segments.length - 1) {
      final seg = state.stage.segments[currentSegIdx];
      if (leadKm >= seg.endKm) {
        currentSegIdx = math.min(state.stage.segments.length - 1, currentSegIdx + 1);
      }
    }
    final StageSegment currentSegment = state.stage.segments[currentSegIdx];

    // 2. Obsługa rozkazów taktycznych i wyznaczanie mocy wyjściowej każdego kolarza
    final Map<String, RiderRaceState> updatedRiderStates = {};
    final Map<String, WPrimeState> updatedWPrime = {};
    final Map<String, NutritionState> updatedNutrition = {};
    final Map<String, HeartRateState> updatedHeartRate = {};

    final mainGroup = state.groups.isNotEmpty
        ? state.groups.first
        : PelotonGroup(
            id: 'main',
            type: GroupType.peloton,
            riderIds: state.riderStates.keys.toList(),
            pacemakerRiderIds: const [],
            positions: const [],
          );

    final double groupSpeedMs = math.max(8.0, mainGroup.averageSpeedKmh / 3.6);

    for (final entry in state.riderStates.entries) {
      final String rId = entry.key;
      final RiderRaceState rState = entry.value;
      final Rider? rider = allRidersMap[rId];
      final CompleteBike? bike = allBikesMap[rId];
      if (rider == null || bike == null) continue;

      // A) Przetwarzanie rozkazu taktycznego
      final tacticalResult = TacticalOrdersProcessor.processOrder(
        riderState: rState,
        physiology: rider.physiology,
        skills: rider.skills,
        group: mainGroup,
        currentGroupSpeedMs: groupSpeedMs,
        roadGradientPercent: currentSegment.gradientPercent,
        timeStepSeconds: dt,
      );

      // B) Sprawdzenie metabolizmu i glikogenu (weryfikacja stanu bonk)
      final nutritionResult = NutritionAndGlycogenEngine.update(
        state: state.nutritionStates[rId] ?? NutritionState.initial(rider.physiology),
        currentPowerWatts: tacticalResult.targetWatts.toDouble(),
        physiology: rider.physiology,
        temperatureCelsius: state.stage.baseTemperatureCelsius,
        timeStepSeconds: dt,
      );
      updatedNutrition[rId] = nutritionResult.newState;

      // C) Sprawdzenie zapasu beztlenowego W' (odcięcie beztlenowe)
      final wPrimeResult = WPrimeBalanceEngine.update(
        state: state.wPrimeStates[rId] ?? WPrimeState.initial(rider.physiology),
        targetPowerWatts: tacticalResult.targetWatts.toDouble(),
        physiology: rider.physiology,
        timeStepSeconds: dt,
      );
      updatedWPrime[rId] = wPrimeResult.newState;

      final double actualExecutedWatts = wPrimeResult.actualPowerWatts;

      // D) Rozwiązanie równania ruchu i nowej prędkości (SpeedSolver)
      final solverResult = SpeedSolver.solveForSegment(
        physiology: rider.physiology,
        skills: rider.skills,
        bike: bike,
        segment: currentSegment,
        currentSpeedMs: math.max(0.5, rState.currentSpeedMs),
        inputWatts: actualExecutedWatts,
        temperatureCelsius: state.stage.baseTemperatureCelsius,
        windSpeedKmh: state.stage.windSpeedKmh,
        draftingReduction: 0.32 + tacticalResult.draftingModifier,
        timeStepSeconds: dt,
      );

      // E) Tętno i inercja układu krążenia
      final hrState = HeartRateSimulator.update(
        state: state.heartRateStates[rId] ?? HeartRateState.initial(rider.physiology),
        powerWatts: actualExecutedWatts,
        physiology: rider.physiology,
        hydrationPercent: nutritionResult.newState.hydrationPercent,
        ambientTemperatureCelsius: state.stage.baseTemperatureCelsius,
        timeStepSeconds: dt,
      );
      updatedHeartRate[rId] = hrState;

      // F) Nowy dystans i kadencja
      final double newDistanceMeters = rState.distanceCoveredMeters + (solverResult.newSpeedMs * dt);
      final int cadence = solverResult.newSpeedMs > 1.0 ? 88 + (actualExecutedWatts ~/ 50) : 0;

      updatedRiderStates[rId] = rState.copyWith(
        distanceCoveredMeters: newDistanceMeters,
        currentSpeedMs: solverResult.newSpeedMs,
        currentWatts: actualExecutedWatts.round(),
        currentCadenceRpm: cadence.clamp(40, 125),
        currentHeartRate: hrState.currentHrBpm,
        currentWPrime: wPrimeResult.newState.currentWPrimeJoules,
        currentGlycogen: nutritionResult.newState.currentGlycogenGrams,
        bidonsLeft: tacticalResult.updatedState.bidonsLeft,
        gelsLeft: tacticalResult.updatedState.gelsLeft,
      );
    }

    // 3. Sprawdzenie incydentów losowych (kraksy, defekty)
    final stepIncidents = RaceIncidentEngine.evaluateIncidentsForStep(
      currentKm: leadKm,
      stepDistanceKm: (groupSpeedMs * dt) / 1000.0,
      group: mainGroup,
      stage: state.stage,
      segment: currentSegment,
      ridersMap: allRidersMap,
      bikesMap: allBikesMap,
      random: random,
    );

    final List<RaceIncidentEvent> updatedIncidents = List.from(state.incidentHistory)..addAll(stepIncidents);
    final List<RaceRadioMessage> updatedRadio = List.from(state.radioLog);

    for (final inc in stepIncidents) {
      final radioMsg = RaceRadioGenerator.generateCrashMessage(
        kilometerMark: leadKm,
        elapsedSeconds: newElapsed,
        incident: inc,
      );
      updatedRadio.add(radioMsg);
    }

    // 4. Detekcja linii mety (Finish line)
    final List<StageFinishResult> newFinishes = List.from(state.finishResults);
    bool stageFinished = state.isStageFinished;

    for (final entry in updatedRiderStates.entries) {
      if (entry.value.distanceCoveredMeters >= stageLengthKm * 1000.0) {
        final alreadyFinished = newFinishes.any((f) => f.riderId == entry.key);
        if (!alreadyFinished) {
          final rider = allRidersMap[entry.key];
          final winnerTime = newFinishes.isNotEmpty ? newFinishes.first.finishTimeSeconds : newElapsed;
          newFinishes.add(
            StageFinishResult(
              riderId: entry.key,
              riderName: '${rider?.firstName ?? ""} ${rider?.lastName ?? entry.key}',
              teamId: entry.value.teamId,
              finishRank: newFinishes.length + 1,
              finishTimeSeconds: newElapsed,
              gapToWinnerSeconds: newElapsed - winnerTime,
            ),
          );
        }
      }
    }

    if (newFinishes.length >= updatedRiderStates.length || (newFinishes.isNotEmpty && leadKm >= stageLengthKm)) {
      stageFinished = true;
    }

    // 5. Sprawdzenie kluczowych momentów przez KeyMomentsDetector
    final keyMomentCheck = KeyMomentsDetector.evaluateStep(
      state: state.keyMomentsState,
      currentKm: leadKm,
      stage: state.stage,
      currentSegment: currentSegment,
      playerTeamId: state.playerTeamId,
      playerRiderIds: state.playerRiderIds,
      allRiderStates: updatedRiderStates,
      stepIncidents: stepIncidents,
    );

    SimulationTimeSpeed effectiveSpeed = state.timeSpeed;
    KeyMomentTrigger? triggeredMoment = keyMomentCheck.trigger;

    // Jeśli wykryto kluczowy moment, natychmiast zatrzymujemy przyspieszenie i przełączamy w tryb 1x (3D)
    if (triggeredMoment != null) {
      effectiveSpeed = SimulationTimeSpeed.x1;
    }

    state = state.copyWith(
      elapsedSeconds: newElapsed,
      currentSegmentIndex: currentSegIdx,
      riderStates: updatedRiderStates,
      wPrimeStates: updatedWPrime,
      nutritionStates: updatedNutrition,
      heartRateStates: updatedHeartRate,
      incidentHistory: updatedIncidents,
      radioLog: updatedRadio,
      finishResults: newFinishes,
      isStageFinished: stageFinished,
      keyMomentsState: keyMomentCheck.updatedState,
      timeSpeed: effectiveSpeed,
      activeKeyMoment: triggeredMoment,
    );

    return state;
  }

  /// Błyskawiczne przeliczenie matematyczne w pętli w tle (Instant Fast-Forward),
  /// aż do wystąpienia kolejnego kluczowego momentu lub zakończenia etapu.
  StageSimulationState runUntilNextKeyMoment({int maxSteps = 18000, double stepDt = 1.0}) {
    int stepsTaken = 0;
    while (!state.isStageFinished && stepsTaken < maxSteps) {
      step(dt: stepDt);
      stepsTaken++;

      // Jeśli wystąpił kluczowy moment lub etap dobiegł końca, wychodzimy z pętli do interaktywnego 3D
      if (state.activeKeyMoment != null || state.isStageFinished) {
        break;
      }
    }
    return state;
  }

  /// Alias dla runUntilNextKeyMoment()
  StageSimulationState simulateToNextKeyMoment({int maxSteps = 18000, double stepDt = 1.0}) =>
      runUntilNextKeyMoment(maxSteps: maxSteps, stepDt: stepDt);

  /// Ustawia prędkość symulacji
  void setTimeSpeed(SimulationTimeSpeed newSpeed) {
    state = state.copyWith(timeSpeed: newSpeed);
  }

  /// Alias dla setTimeSpeed()
  void setSpeed(SimulationTimeSpeed newSpeed) => setTimeSpeed(newSpeed);

  /// Zmienia rozkaz taktyczny kolarza
  void setTacticalOrder(String riderId, TacticalOrder newOrder) {
    final rState = state.riderStates[riderId];
    if (rState != null) {
      final updatedRiders = Map<String, RiderRaceState>.from(state.riderStates);
      updatedRiders[riderId] = rState.copyWith(activeTacticalOrder: newOrder);
      state = state.copyWith(riderStates: updatedRiders);
    }
  }

  /// Alias dla setTacticalOrder()
  void setRiderTacticalOrder(String riderId, TacticalOrder newOrder) =>
      setTacticalOrder(riderId, newOrder);

  /// Zezwala kolarzowi na spożycie żelu energetycznego (+30g węglowodanów).
  void consumeGelForRider(String riderId) {
    final nState = state.nutritionStates[riderId];
    final rState = state.riderStates[riderId];
    if (nState != null && rState != null && rState.gelsLeft > 0) {
      final updatedNutrition = Map<String, NutritionState>.from(state.nutritionStates);
      updatedNutrition[riderId] = NutritionAndGlycogenEngine.consumeGel(nState);

      final updatedRiders = Map<String, RiderRaceState>.from(state.riderStates);
      updatedRiders[riderId] = rState.copyWith(gelsLeft: rState.gelsLeft - 1);

      state = state.copyWith(
        nutritionStates: updatedNutrition,
        riderStates: updatedRiders,
      );
    }
  }

  /// Zezwala kolarzowi gracza na napicie się z bidonu (+500ml płynu).
  void drinkBidonForRider(String riderId) {
    final nState = state.nutritionStates[riderId];
    final rState = state.riderStates[riderId];
    if (nState != null && rState != null && rState.bidonsLeft > 0) {
      final updatedNutrition = Map<String, NutritionState>.from(state.nutritionStates);
      updatedNutrition[riderId] = NutritionAndGlycogenEngine.drinkBidon(nState);

      final updatedRiders = Map<String, RiderRaceState>.from(state.riderStates);
      updatedRiders[riderId] = rState.copyWith(bidonsLeft: rState.bidonsLeft - 1);

      state = state.copyWith(
        nutritionStates: updatedNutrition,
        riderStates: updatedRiders,
      );
    }
  }

  /// Zapewnia dostarczenie nowych bidonów dla kolarza (np. od pomocnika lub wozu technicznego).
  void refillBidonsForRider(String riderId, {int count = 2}) {
    final rState = state.riderStates[riderId];
    if (rState != null) {
      final updatedRiders = Map<String, RiderRaceState>.from(state.riderStates);
      updatedRiders[riderId] = rState.copyWith(
        bidonsLeft: (rState.bidonsLeft + count).clamp(0, 2),
      );
      state = state.copyWith(riderStates: updatedRiders);
    }
  }

  /// Zapewnia dostarczenie nowych żeli dla kolarza (np. od wozu technicznego).
  void refillGelsForRider(String riderId, {int count = 3}) {
    final rState = state.riderStates[riderId];
    if (rState != null) {
      final updatedRiders = Map<String, RiderRaceState>.from(state.riderStates);
      updatedRiders[riderId] = rState.copyWith(
        gelsLeft: (rState.gelsLeft + count).clamp(0, 6),
      );
      state = state.copyWith(riderStates: updatedRiders);
    }
  }

  /// Pomocnik pobiera bidony z wozu technicznego i rozdaje kolegom z drużyny.
  void distributeBidonsFromDomestique(String domestiqueId, {int totalBidons = 6}) {
    final domState = state.riderStates[domestiqueId];
    if (domState == null) return;

    final updatedRiders = Map<String, RiderRaceState>.from(state.riderStates);
    
    // Pomocnik zaopatruje najpierw siebie w 2 bidony
    updatedRiders[domestiqueId] = domState.copyWith(
      bidonsLeft: 2,
      activeTacticalOrder: TacticalOrder.holdPosition,
    );

    // Następnie zaopatruje pozostałych kolegów z drużyny gracza
    int bidonsRemaining = totalBidons - 2;
    for (final id in state.playerRiderIds) {
      if (id == domestiqueId || bidonsRemaining <= 0) continue;
      final teammate = updatedRiders[id];
      if (teammate != null && teammate.bidonsLeft < 2) {
        final needed = 2 - teammate.bidonsLeft;
        final given = needed <= bidonsRemaining ? needed : bidonsRemaining;
        updatedRiders[id] = teammate.copyWith(
          bidonsLeft: teammate.bidonsLeft + given,
        );
        bidonsRemaining -= given;
      }
    }

    state = state.copyWith(riderStates: updatedRiders);
  }

  /// Bezpośrednia aplikacja rozwiązania defektu / incydentu dla kolarza
  void applyIncidentResolution({
    required String victimId,
    required double timeLostSeconds,
    required AssistanceMethod method,
    String? helperId,
  }) {
    final victimState = state.riderStates[victimId];
    if (victimState == null) return;

    final updatedRiders = Map<String, RiderRaceState>.from(state.riderStates);

    // Kolarz poszkodowany traci dystans odpowiadający czasowi postoju
    // (prędkość grupy lidera ~ 12 m/s * timeLostSeconds)
    final distanceLostMeters = 12.0 * timeLostSeconds;
    final newDistance = (victimState.currentDistanceMeters - distanceLostMeters).clamp(0.0, state.stage.totalDistanceKm * 1000.0);

    updatedRiders[victimId] = victimState.copyWith(
      distanceCoveredMeters: newDistance,
      currentSpeedMs: 9.0, // rusza z mniejszej prędkości po postoju
      activeTacticalOrder: TacticalOrder.attack, // goni peleton
    );

    // Jeśli pomocnik oddał rower
    if (helperId != null && method == AssistanceMethod.teammateBikeSwap) {
      final helperState = updatedRiders[helperId];
      if (helperState != null) {
        // Pomocnik musi poczekać na wóz techniczny (~45s straty)
        const helperDistLost = 12.0 * 45.0;
        final helperNewDist = (helperState.currentDistanceMeters - helperDistLost).clamp(0.0, state.stage.totalDistanceKm * 1000.0);
        updatedRiders[helperId] = helperState.copyWith(
          distanceCoveredMeters: helperNewDist,
          currentSpeedMs: 8.0,
          activeTacticalOrder: TacticalOrder.saveEnergy,
        );
      }
    }

    state = state.copyWith(riderStates: updatedRiders);
  }

  /// Resetuje aktywny kluczowy moment po obejrzeniu go w trybie 3D przez gracza.
  void dismissActiveKeyMoment() {
    state = state.copyWith(clearActiveKeyMoment: true);
  }
}

