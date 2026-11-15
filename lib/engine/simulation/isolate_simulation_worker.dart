// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import '../../services/generators/fictional_brands_catalog.dart';
import '../../services/generators/stage_profile_builder.dart';
import '../../services/generators/world_teams_generator.dart';
import '../../state/race_simulation_notifier.dart';
import '../events/race_incident_engine.dart';
import '../events/race_radio_generator.dart';
import '../peloton/drafting_grid_system.dart';
import '../peloton/rider_race_state.dart';
import 'key_moments_detector.dart';
import 'stage_simulation_loop.dart';

// ============================================================================
// 1. PAKIET KLATEK TELEMETRYCZNYCH (SIMULATION SNAPSHOT DLA RENDERERA 3D I UI)
// ============================================================================

/// Snapshot telemetryczno-przestrzenny pojedynczego kolarza w danej klatce symulacji.
class RiderSimulationFrame {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String teamId;
  final String teamName;
  final String teamJerseyHexColor;
  final bool isPlayerRider;

  // Przestrzeń trójwymiarowa (3D) oraz profil wysokościowy trasy
  final double distanceCoveredMeters;
  final double kilometerMark;
  final double elevationMeters;
  final double currentGradientPercent;
  final double lateralPositionRoad; // [-1.0: lewa krawędź, 0.0: środek, 1.0: prawa]
  final double lateralOffsetRoadMeters; // [-3.5m do +3.5m]

  // Kinematyka i dynamika fizyczna
  final double speedMs;
  final double speedKmh;
  final int powerWatts;
  final double wattsPerKg;
  final int cadenceRpm;
  final int heartRateBpm;

  // Fizjologia i zapasy energii
  final double wPrimePercentage; // 0.0 - 1.0
  final double wPrimeJoules;
  final double glycogenPercentage; // 0.0 - 1.0
  final double glycogenGrams;

  // Taktyka i opór powietrza (Aero & Drafting)
  final TacticalOrder activeTacticalOrder;
  final int groupIndex;
  final GroupType groupType;
  final double timeGapToLeaderSeconds;
  final bool isDrafting;
  final double draftingSavingsPercent;
  final bool isPulling;

  // Zdarzenia losowe i status na mecie
  final bool hasDefect;
  final IncidentType? defectType;
  final bool isCrashed;
  final bool isDnf;
  final int? finishRank;

  const RiderSimulationFrame({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.teamId,
    required this.teamName,
    required this.teamJerseyHexColor,
    required this.isPlayerRider,
    required this.distanceCoveredMeters,
    required this.kilometerMark,
    required this.elevationMeters,
    required this.currentGradientPercent,
    required this.lateralPositionRoad,
    required this.lateralOffsetRoadMeters,
    required this.speedMs,
    required this.speedKmh,
    required this.powerWatts,
    required this.wattsPerKg,
    required this.cadenceRpm,
    required this.heartRateBpm,
    required this.wPrimePercentage,
    required this.wPrimeJoules,
    required this.glycogenPercentage,
    required this.glycogenGrams,
    required this.activeTacticalOrder,
    required this.groupIndex,
    required this.groupType,
    required this.timeGapToLeaderSeconds,
    required this.isDrafting,
    required this.draftingSavingsPercent,
    required this.isPulling,
    this.hasDefect = false,
    this.defectType,
    this.isCrashed = false,
    this.isDnf = false,
    this.finishRank,
  });

  /// Konwersja na standardowy snapshot pozycji kolarza [RiderPositionSnapshot]
  RiderPositionSnapshot toPositionSnapshot({int currentSegmentIndex = 0}) {
    return RiderPositionSnapshot(
      riderId: riderId,
      riderName: riderName,
      bibNumber: bibNumber,
      teamId: teamId,
      teamName: teamName,
      teamJerseyHexColor: teamJerseyHexColor,
      isPlayerRider: isPlayerRider,
      distanceCoveredMeters: distanceCoveredMeters,
      kilometerMark: kilometerMark,
      elevationMeters: elevationMeters,
      currentGradientPercent: currentGradientPercent,
      currentSegmentIndex: currentSegmentIndex,
      speedMs: speedMs,
      speedKmh: speedKmh,
      powerWatts: powerWatts,
      wattsPerKg: wattsPerKg,
      cadenceRpm: cadenceRpm,
      heartRateBpm: heartRateBpm,
      wPrimePercentage: wPrimePercentage,
      wPrimeJoules: wPrimeJoules,
      glycogenPercentage: glycogenPercentage,
      glycogenGrams: glycogenGrams,
      hydrationPercent: 1.0,
      bidonsLeft: 2,
      gelsLeft: 3,
      activeTacticalOrder: activeTacticalOrder,
      groupIndex: groupIndex,
      groupType: groupType,
      timeGapToLeaderSeconds: timeGapToLeaderSeconds,
      lateralPositionRoad: lateralPositionRoad,
      lateralOffsetRoadMeters: lateralOffsetRoadMeters,
      isDrafting: isDrafting,
      draftingSavingsPercent: draftingSavingsPercent,
      isPulling: isPulling,
      hasDefect: hasDefect,
      defectType: defectType,
      isCrashed: isCrashed,
      isDnf: isDnf,
      finishRank: finishRank,
    );
  }
}

/// Błyskawiczny snapshot grupy kolarzy na trasie (Ucieczka, Peleton, Kontra, Grupetto).
class PelotonGroupSnapshot {
  final String groupId;
  final GroupType type;
  final int riderCount;
  final List<String> riderIds;
  final String? pacemakerName;
  final String? pacemakerTeamCode;
  final double gapToRaceLeaderSeconds;
  final double distanceCoveredKm;
  final double speedKmh;
  final bool containsPlayerRider;

  const PelotonGroupSnapshot({
    required this.groupId,
    required this.type,
    required this.riderCount,
    required this.riderIds,
    this.pacemakerName,
    this.pacemakerTeamCode,
    required this.gapToRaceLeaderSeconds,
    required this.distanceCoveredKm,
    required this.speedKmh,
    required this.containsPlayerRider,
  });
}

/// Gotowy pakiet klatek symulacji (SimulationSnapshot) wysyłany z wątku Isolate do renderera 3D i UI.
class SimulationSnapshot {
  /// Kolejny numer klatki symulacji (monotoniczny licznik)
  final int frameIndex;

  /// Czas trwania etapu od startu ostro w sekundach [s]
  final double elapsedSeconds;

  /// Kilometraż czoła wyścigu [km]
  final double leadKilometerMark;

  /// Całkowity dystans etapu [km]
  final double totalStageDistanceKm;

  /// Dystans do mety dla czoła wyścigu [km]
  final double distanceToFinishKm;

  /// Indeks aktywnego segmentu trasy
  final int currentSegmentIndex;

  /// Aktualne nachylenie jezdni na czole [%]
  final double currentGradientPercent;

  /// Aktualna wysokość n.p.m. na czole [m]
  final double currentElevationMeters;

  /// Prędkość wiatru na etapie [km/h]
  final double currentWindSpeedKmh;

  /// Wszystkie grupy na trasie wyścigu
  final List<PelotonGroupSnapshot> groups;

  /// Kompletna lista wszystkich kolarzy (176 kolarzy w pełnym peletonie)
  final List<RiderSimulationFrame> riders;

  /// Nowe komunikaty Radia Wyścigu w tej klatce
  final List<RaceRadioMessage> newRadioMessages;

  /// Aktywny kluczowy moment wyścigu (Key Moment), jeśli wystąpił
  final KeyMomentTrigger? activeKeyMoment;

  /// Czy etap został zakończony przez czołówkę
  final bool isStageFinished;

  /// Oficjalne wyniki kolarzy na kresce mety
  final List<StageFinishResult> finishResults;

  /// Czas w milisekundach, jaki zajął wątek Isolate na obliczenie fizyki tej klatki
  final double computeDurationMs;

  /// Aktualny mnożnik prędkości symulacji
  final SimulationTimeSpeed timeSpeed;

  const SimulationSnapshot({
    required this.frameIndex,
    required this.elapsedSeconds,
    required this.leadKilometerMark,
    required this.totalStageDistanceKm,
    required this.distanceToFinishKm,
    required this.currentSegmentIndex,
    required this.currentGradientPercent,
    required this.currentElevationMeters,
    required this.currentWindSpeedKmh,
    required this.groups,
    required this.riders,
    required this.newRadioMessages,
    required this.isStageFinished,
    required this.finishResults,
    required this.computeDurationMs,
    required this.timeSpeed,
    this.activeKeyMoment,
  });

  /// Wyszukiwanie danych klatki konkretnego kolarza po jego identyfikatorze
  RiderSimulationFrame? getRider(String riderId) {
    for (final r in riders) {
      if (r.riderId == riderId) return r;
    }
    return null;
  }

  /// Liczba wszystkich symulowanych kolarzy
  int get riderCount => riders.length;

  /// Kolarze należący do drużyny gracza
  List<RiderSimulationFrame> get playerRiders => riders.where((r) => r.isPlayerRider).toList();

  /// Kolarz prowadzący aktualnie na trasie wyścigu (najdłuższy pokonany dystans)
  RiderSimulationFrame? get leaderRider => riders.isNotEmpty
      ? riders.reduce((a, b) => a.distanceCoveredMeters > b.distanceCoveredMeters ? a : b)
      : null;

  /// Główna grupa peletonu
  PelotonGroupSnapshot? get mainPelotonGroup => groups.firstWhere(
        (g) => g.type == GroupType.peloton,
        orElse: () => groups.first,
      );

  /// Czołowa ucieczka (jeśli istnieje)
  PelotonGroupSnapshot? get breakawayGroup => groups.firstWhere(
        (g) => g.type == GroupType.breakaway,
        orElse: () => groups.first,
      );

  /// Konwersja wszystkich kolarzy do formatu używanego przez renderer 3D
  List<RiderPositionSnapshot> toPositionSnapshots() =>
      riders.map((r) => r.toPositionSnapshot(currentSegmentIndex: currentSegmentIndex)).toList();
}

// ============================================================================
// 2. PROTOKÓŁ DWUKIERUNKOWEJ KOMUNIKACJI (ROZKAZY I WIADOMOŚCI ISOLATE)
// ============================================================================

/// Bazowa klasa rozkazów wysyłanych z wątku UI do wątku Isolate.
sealed class IsolateSimulationCommand {
  const IsolateSimulationCommand();
}

/// Rozkaz inicjalizacji silnika symulacji etapu w wątku Isolate.
class InitSimulationCommand extends IsolateSimulationCommand {
  final RaceStage stage;
  final String playerTeamId;
  final Map<String, Rider> allRidersMap;
  final Map<String, CompleteBike> allBikesMap;
  final Map<String, CyclingTeam> allTeamsMap;
  final SimulationTimeSpeed initialSpeed;
  final int targetFps;

  const InitSimulationCommand({
    required this.stage,
    required this.playerTeamId,
    required this.allRidersMap,
    required this.allBikesMap,
    required this.allTeamsMap,
    this.initialSpeed = SimulationTimeSpeed.x1,
    this.targetFps = 30,
  });
}

/// Rozkaz uruchomienia / wznowienia pętli symulacji.
class StartSimulationCommand extends IsolateSimulationCommand {
  const StartSimulationCommand();
}

/// Rozkaz wstrzymania (pauzy) symulacji.
class PauseSimulationCommand extends IsolateSimulationCommand {
  const PauseSimulationCommand();
}

/// Rozkaz zmiany mnożnika prędkości symulacji (1x, 2x, 4x, 8x, Instant).
class SetTimeSpeedCommand extends IsolateSimulationCommand {
  final SimulationTimeSpeed speed;
  const SetTimeSpeedCommand(this.speed);
}

/// Rozkaz zmiany rozkazu taktycznego dla pojedynczego kolarza.
class SetTacticalOrderCommand extends IsolateSimulationCommand {
  final String riderId;
  final TacticalOrder order;
  final double targetEffortPercent;
  final int? targetWatts;
  final String? leaderRiderId;
  final String? targetRivalId;

  const SetTacticalOrderCommand({
    required this.riderId,
    required this.order,
    this.targetEffortPercent = 100.0,
    this.targetWatts,
    this.leaderRiderId,
    this.targetRivalId,
  });
}

/// Rozkaz zastosowania taktyki drużynowej (1-Click Team Tactics) dla całego zespołu.
class ApplyTeamTacticsCommand extends IsolateSimulationCommand {
  final String presetName;
  final Map<String, TacticalOrder> assignments;
  final Map<String, double>? effortMap;

  const ApplyTeamTacticsCommand({
    required this.presetName,
    required this.assignments,
    this.effortMap,
  });
}

/// Rozkaz wykonania pojedynczego kroku fizyki o [dtSeconds].
class StepSimulationCommand extends IsolateSimulationCommand {
  final double dtSeconds;
  const StepSimulationCommand({this.dtSeconds = 1.0});
}

/// Rozkaz bezpiecznego zakończenia i zamknięcia wątku Isolate.
class TerminateSimulationCommand extends IsolateSimulationCommand {
  const TerminateSimulationCommand();
}

// ----------------------------------------------------------------------------
// Komunikaty przesyłane z wątku Isolate z powrotem do UI
// ----------------------------------------------------------------------------

/// Bazowa klasa wiadomości odsyłanych z wątku Isolate.
sealed class IsolateSimulationMessage {
  const IsolateSimulationMessage();
}

/// Wiadomość potwierdzająca gotowość wątku Isolate z portem zwrotnym do wysyłania rozkazów.
class IsolateReadyMessage extends IsolateSimulationMessage {
  final SendPort commandPort;
  const IsolateReadyMessage(this.commandPort);
}

/// Nowy pakiet klatki symulacji przesłany do UI i renderera 3D.
class SnapshotEmittedMessage extends IsolateSimulationMessage {
  final SimulationSnapshot snapshot;
  const SnapshotEmittedMessage(this.snapshot);
}

/// Potwierdzenie spauzowania symulacji.
class SimulationPausedMessage extends IsolateSimulationMessage {
  const SimulationPausedMessage();
}

/// Potwierdzenie wznowienia symulacji.
class SimulationResumedMessage extends IsolateSimulationMessage {
  const SimulationResumedMessage();
}

/// Wiadomość informująca o ukończeniu etapu wyścigu.
class SimulationFinishedMessage extends IsolateSimulationMessage {
  final List<StageFinishResult> results;
  const SimulationFinishedMessage(this.results);
}

/// Błąd zgłoszony przez wątek Isolate.
class IsolateErrorMessage extends IsolateSimulationMessage {
  final String error;
  final String? stackTrace;
  const IsolateErrorMessage(this.error, [this.stackTrace]);
}

// ============================================================================
// 3. WĄTEK TŁA ISOLATE (ISOLATE WORKER ENTRY POINT)
// ============================================================================

/// Główny punkt wejściowy działający w osobnym wątku Isolate w Darcie.
void _isolateSimulationEntryPoint(SendPort uiSendPort) {
  final ReceivePort isolateReceivePort = ReceivePort();

  // 1. Handshake: wysyłamy do UI port zwrotny do przyjmowania poleceń
  uiSendPort.send(IsolateReadyMessage(isolateReceivePort.sendPort));

  StageSimulationLoop? simulationLoop;
  Timer? tickTimer;
  int frameCounter = 0;
  bool isRunning = false;
  int targetFps = 30;

  void computeAndEmitStep(double dt) {
    if (simulationLoop == null) return;

    final stopwatch = Stopwatch()..start();
    final updatedState = simulationLoop!.step(dt: dt);
    stopwatch.stop();

    frameCounter++;

    // Przekształcenie stanu symulacji w zoptymalizowany snapshot klatki 3D
    final snapshot = _buildSnapshotFromState(
      frameIndex: frameCounter,
      state: updatedState,
      allRidersMap: simulationLoop!.allRidersMap,
      allTeamsMap: simulationLoop!.allTeamsMap,
      computeDurationMs: stopwatch.elapsedMicroseconds / 1000.0,
    );

    uiSendPort.send(SnapshotEmittedMessage(snapshot));

    if (updatedState.isStageFinished) {
      tickTimer?.cancel();
      isRunning = false;
      uiSendPort.send(SimulationFinishedMessage(updatedState.finishResults));
    }
  }

  void startTimer() {
    tickTimer?.cancel();
    if (simulationLoop == null) return;

    final speedMultiplier = simulationLoop!.state.timeSpeed.multiplier;
    // Interwał klatek w milisekundach (dla 30 fps = ~33ms)
    final intervalMs = math.max(8, (1000 ~/ targetFps));
    final double simDtSeconds = (intervalMs / 1000.0) * speedMultiplier;

    tickTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      computeAndEmitStep(simDtSeconds);
    });
    isRunning = true;
  }

  void pauseTimer() {
    tickTimer?.cancel();
    tickTimer = null;
    isRunning = false;
  }

  // Nasłuchiwanie rozkazów z UI
  isolateReceivePort.listen((message) {
    if (message is InitSimulationCommand) {
      try {
        targetFps = message.targetFps;
        simulationLoop = StageSimulationLoop.initializeStage(
          stage: message.stage,
          playerTeamId: message.playerTeamId,
          allRidersMap: message.allRidersMap,
          allBikesMap: message.allBikesMap,
          allTeamsMap: message.allTeamsMap,
        );

        if (message.initialSpeed != SimulationTimeSpeed.x1) {
          simulationLoop!.state = simulationLoop!.state.copyWith(timeSpeed: message.initialSpeed);
        }

        // Emisja początkowej klatki (Frame #0) na starcie etapu
        computeAndEmitStep(0.0);
      } catch (e, st) {
        uiSendPort.send(IsolateErrorMessage(e.toString(), st.toString()));
      }
    } else if (message is StartSimulationCommand) {
      startTimer();
      uiSendPort.send(const SimulationResumedMessage());
    } else if (message is PauseSimulationCommand) {
      pauseTimer();
      uiSendPort.send(const SimulationPausedMessage());
    } else if (message is SetTimeSpeedCommand) {
      if (simulationLoop != null) {
        simulationLoop!.state = simulationLoop!.state.copyWith(timeSpeed: message.speed);
        if (isRunning) {
          startTimer(); // Restart z nowym interwałem czasowym
        }
      }
    } else if (message is SetTacticalOrderCommand) {
      if (simulationLoop != null) {
        final existingState = simulationLoop!.state.riderStates[message.riderId];
        if (existingState != null) {
          final updatedRider = existingState.copyWith(
            activeTacticalOrder: message.order,
          );
          final updatedMap = Map<String, RiderRaceState>.from(simulationLoop!.state.riderStates);
          updatedMap[message.riderId] = updatedRider;
          simulationLoop!.state = simulationLoop!.state.copyWith(riderStates: updatedMap);
        }
      }
    } else if (message is ApplyTeamTacticsCommand) {
      if (simulationLoop != null) {
        final updatedMap = Map<String, RiderRaceState>.from(simulationLoop!.state.riderStates);
        for (final entry in message.assignments.entries) {
          final existing = updatedMap[entry.key];
          if (existing != null) {
            updatedMap[entry.key] = existing.copyWith(activeTacticalOrder: entry.value);
          }
        }
        simulationLoop!.state = simulationLoop!.state.copyWith(riderStates: updatedMap);
      }
    } else if (message is StepSimulationCommand) {
      computeAndEmitStep(message.dtSeconds);
    } else if (message is TerminateSimulationCommand) {
      pauseTimer();
      isolateReceivePort.close();
    }
  });
}

/// Przekształca surowy stan symulacji [StageSimulationState] na niemutowalny pakiet [SimulationSnapshot].
SimulationSnapshot _buildSnapshotFromState({
  required int frameIndex,
  required StageSimulationState state,
  required Map<String, Rider> allRidersMap,
  required Map<String, CyclingTeam> allTeamsMap,
  required double computeDurationMs,
}) {
  final List<RiderSimulationFrame> riderFrames = [];

  final playerTeam = allTeamsMap[state.playerTeamId];
  final playerRiderIdsSet = (playerTeam?.rosterRiderIds ?? state.playerRiderIds).toSet();

  int currentBib = 1;

  for (final entry in state.riderStates.entries) {
    final riderId = entry.key;
    final rState = entry.value;
    final rider = allRidersMap[riderId];
    final team = rider != null ? allTeamsMap[rider.contract.teamId] : null;

    final bool isPlayer = playerRiderIdsSet.contains(riderId);
    final wPrime = state.wPrimeStates[riderId];
    final nutrition = state.nutritionStates[riderId];

    final double wPrimeMax = rider?.physiology.wPrimeJoules.toDouble() ?? 20000.0;
    final double wPrimeVal = wPrime?.currentWPrimeJoules ?? rState.currentWPrime;
    final double wPrimeRatio = wPrimeMax > 0
        ? (wPrimeVal / wPrimeMax).clamp(0.0, 1.0)
        : 1.0;

    final double glycogenMax = rider?.physiology.glycogenCapacityGrams ?? 500.0;
    final double glycogenVal = nutrition?.currentGlycogenGrams ?? rState.currentGlycogen;
    final double glycogenRatio = glycogenMax > 0
        ? (glycogenVal / glycogenMax).clamp(0.0, 1.0)
        : 1.0;

    final double weightKg = rider?.physiology.weightKg ?? 70.0;
    final double wPerKg = weightKg > 0 ? (rState.currentWatts / weightKg) : 0.0;

    // Przeliczenie grupy kolarza
    final int gIndex = rState.groupIndex.clamp(0, math.max(0, state.groups.length - 1));
    final group = state.groups.isNotEmpty ? state.groups[gIndex] : null;
    final gType = group?.type ?? GroupType.peloton;

    // Pozycja na mecie
    int? finishRank;
    for (final f in state.finishResults) {
      if (f.riderId == riderId) {
        finishRank = f.finishRank;
        break;
      }
    }

    // Incydenty
    bool isCrashed = false;
    bool hasDefect = false;
    IncidentType? defectType;
    bool isDnf = false;

    for (final inc in state.incidentHistory) {
      for (final victim in inc.primaryVictims) {
        if (victim.riderId == riderId) {
          if (victim.isDnf) isDnf = true;
          if (victim.incidentType == IncidentType.soloCrash ||
              victim.incidentType == IncidentType.pelotonPileup) {
            isCrashed = true;
          } else if (victim.incidentType == IncidentType.punctureFlatTire ||
              victim.incidentType == IncidentType.mechanicalFailure) {
            hasDefect = true;
            defectType = victim.incidentType;
          }
        }
      }
    }

    final bool isDrafting = rState.activeTacticalOrder != TacticalOrder.pullGroup &&
        (group != null && group.riderCount > 1);
    final double draftingSavings = isDrafting ? 32.0 : 0.0;

    riderFrames.add(RiderSimulationFrame(
      riderId: riderId,
      riderName: rider?.fullName ?? 'Kolarz #$currentBib',
      bibNumber: currentBib++,
      teamId: rider?.contract.teamId ?? 'team_unknown',
      teamName: team?.name ?? 'Zespół',
      teamJerseyHexColor: team?.primaryJerseyColorHex ?? '#1E88E5',
      isPlayerRider: isPlayer,
      distanceCoveredMeters: rState.distanceCoveredMeters,
      kilometerMark: rState.distanceCoveredMeters / 1000.0,
      elevationMeters: 120.0 + (rState.distanceCoveredMeters * 0.005),
      currentGradientPercent: 2.5,
      lateralPositionRoad: rState.lateralPositionRoad,
      lateralOffsetRoadMeters: rState.lateralPositionRoad * 3.2,
      speedMs: rState.currentSpeedMs,
      speedKmh: rState.currentSpeedMs * 3.6,
      powerWatts: rState.currentWatts,
      wattsPerKg: wPerKg,
      cadenceRpm: rState.currentCadenceRpm,
      heartRateBpm: rState.currentHeartRate,
      wPrimePercentage: wPrimeRatio,
      wPrimeJoules: wPrimeVal,
      glycogenPercentage: glycogenRatio,
      glycogenGrams: glycogenVal,
      activeTacticalOrder: rState.activeTacticalOrder,
      groupIndex: gIndex,
      groupType: gType,
      timeGapToLeaderSeconds: group?.gapToRaceLeaderSeconds ?? 0.0,
      isDrafting: isDrafting,
      draftingSavingsPercent: draftingSavings,
      isPulling: rState.activeTacticalOrder == TacticalOrder.pullGroup,
      hasDefect: hasDefect,
      defectType: defectType,
      isCrashed: isCrashed,
      isDnf: isDnf,
      finishRank: finishRank,
    ));
  }

  // Grupy na trasie
  final List<PelotonGroupSnapshot> groupSnapshots = state.groups.map((g) {
    final bool hasPlayer = g.riderIds.any((id) => playerRiderIdsSet.contains(id));
    final pRider = g.pacemakerRiderIds.isNotEmpty ? allRidersMap[g.pacemakerRiderIds.first] : null;

    return PelotonGroupSnapshot(
      groupId: g.id,
      type: g.type,
      riderCount: g.riderCount,
      riderIds: g.riderIds,
      pacemakerName: pRider?.fullName,
      pacemakerTeamCode: pRider?.contract.teamId.toUpperCase(),
      gapToRaceLeaderSeconds: g.gapToRaceLeaderSeconds,
      distanceCoveredKm: g.distanceCoveredKm,
      speedKmh: g.averageSpeedKmh,
      containsPlayerRider: hasPlayer,
    );
  }).toList();

  final StageSegment currentSeg = state.stage.segments.isNotEmpty
      ? state.stage.segments[state.currentSegmentIndex.clamp(0, state.stage.segments.length - 1)]
      : const StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 180.0,
          startElevationM: 100.0,
          endElevationM: 350.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 20.0,
          windDirectionDegrees: 90.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.none,
        );

  return SimulationSnapshot(
    frameIndex: frameIndex,
    elapsedSeconds: state.elapsedSeconds,
    leadKilometerMark: state.leadKilometerMark,
    totalStageDistanceKm: state.stage.totalDistanceKm,
    distanceToFinishKm: state.leadDistanceToFinishKm,
    currentSegmentIndex: state.currentSegmentIndex,
    currentGradientPercent: currentSeg.gradientPercent,
    currentElevationMeters: 250.0 + (state.leadKilometerMark * 8.0),
    currentWindSpeedKmh: state.stage.windSpeedKmh,
    groups: groupSnapshots,
    riders: riderFrames,
    newRadioMessages: state.radioLog,
    activeKeyMoment: state.activeKeyMoment,
    isStageFinished: state.isStageFinished,
    finishResults: state.finishResults,
    computeDurationMs: computeDurationMs,
    timeSpeed: state.timeSpeed,
  );
}

// ============================================================================
// 4. KONTROLER GŁÓWNY PO STRONIE UI (ISOLATE SIMULATION WORKER API)
// ============================================================================

/// Główny interfejs koordynujący komunikację wątku UI z wątkiem w tle Isolate.
///
/// Przenosi wszystkie ciężkie obliczenia fizyki 176 kolarzy do osobnego wątku `Isolate`,
/// nie blokując głównego wątku renderowania interfejsu użytkownika (UI 60/120 FPS).
/// Odbiera pakiety klatek [SimulationSnapshot] i dostarcza je przez strumień [snapshotStream]
/// bezpośrednio do renderera trójwymiarowego [PelotonInstancedRenderer].
class IsolateSimulationWorker {
  Isolate? _isolate;
  ReceivePort? _uiReceivePort;
  SendPort? _isolateCommandPort;

  final StreamController<SimulationSnapshot> _snapshotController =
      StreamController<SimulationSnapshot>.broadcast();
  final StreamController<List<StageFinishResult>> _finishController =
      StreamController<List<StageFinishResult>>.broadcast();

  SimulationSnapshot? _latestSnapshot;
  bool _isInitialized = false;
  bool _isRunning = false;
  bool _isPaused = false;

  /// Strumień gotowych pakietów klatek telemetrycznych dla renderera 3D i widoków UI
  Stream<SimulationSnapshot> get snapshotStream => _snapshotController.stream;

  /// Strumień z wynikami ukończenia etapu
  Stream<List<StageFinishResult>> get finishStream => _finishController.stream;

  /// Najnowsza odebrana klatka symulacji
  SimulationSnapshot? get latestSnapshot => _latestSnapshot;

  /// Czy wątek Isolate został pomyślnie powołany do życia i zainicjalizowany
  bool get isInitialized => _isInitialized;

  /// Czy symulacja jest w trakcie aktywnego biegu
  bool get isRunning => _isRunning;

  /// Czy symulacja jest zapauzowana
  bool get isPaused => _isPaused;

  /// Inicjalizuje wątek Isolate i przesyła bazowe dane etapu, kolarzy i sprzętu.
  Future<void> initialize({
    required RaceStage stage,
    required String playerTeamId,
    required Map<String, Rider> allRidersMap,
    required Map<String, CompleteBike> allBikesMap,
    required Map<String, CyclingTeam> allTeamsMap,
    SimulationTimeSpeed initialSpeed = SimulationTimeSpeed.x1,
    int targetFps = 30,
  }) async {
    if (_isInitialized) {
      await dispose();
    }

    _uiReceivePort = ReceivePort();

    final completer = Completer<void>();

    _uiReceivePort!.listen((message) {
      if (message is IsolateReadyMessage) {
        _isolateCommandPort = message.commandPort;

        // Przesyłamy rozkaz inicjalizacji do wątku Isolate
        _isolateCommandPort!.send(InitSimulationCommand(
          stage: stage,
          playerTeamId: playerTeamId,
          allRidersMap: allRidersMap,
          allBikesMap: allBikesMap,
          allTeamsMap: allTeamsMap,
          initialSpeed: initialSpeed,
          targetFps: targetFps,
        ));

        _isInitialized = true;
        completer.complete();
      } else if (message is SnapshotEmittedMessage) {
        _latestSnapshot = message.snapshot;
        if (!_snapshotController.isClosed) {
          _snapshotController.add(message.snapshot);
        }
      } else if (message is SimulationPausedMessage) {
        _isPaused = true;
        _isRunning = false;
      } else if (message is SimulationResumedMessage) {
        _isPaused = false;
        _isRunning = true;
      } else if (message is SimulationFinishedMessage) {
        _isRunning = false;
        _isPaused = false;
        if (!_finishController.isClosed) {
          _finishController.add(message.results);
        }
      } else if (message is IsolateErrorMessage) {
        // Log błędu z wątku Isolate
        // ignore: avoid_print
        print('IsolateSimulationWorker Error: ${message.error}');
      }
    });

    // Uruchomienie wątku w tle Isolate
    _isolate = await Isolate.spawn(
      _isolateSimulationEntryPoint,
      _uiReceivePort!.sendPort,
      debugName: 'PelotonSimulationIsolate',
    );

    return completer.future;
  }

  /// Fabryka demonstracyjna: automatycznie generuje świat WorldTour ze 176 kolarzami i etapem.
  static Future<IsolateSimulationWorker> createDemoWorker({
    int targetFps = 30,
    SimulationTimeSpeed initialSpeed = SimulationTimeSpeed.x1,
  }) async {
    final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 101);
    final stage = StageProfileBuilder.buildHighMountainStage(
      id: 'demo_stage_high_mountain',
      stageNumber: 15,
      name: 'Grand Colombier • Finałowy Etap Górski',
      distanceKm: 165.0,
      climbs: [StageProfileBuilder.alpeDHuez],
    );

    final playerTeam = world.teams.first;
    final Map<String, Rider> allRidersMap = {for (final r in world.allRiders) r.id: r};
    final demoBike = FictionalBrandsCatalog.assembleBike(
      brandId: 'brand_aethel',
      frameCategory: FrameCategory.allRounder,
    );
    final Map<String, CompleteBike> allBikesMap = {
      for (final r in world.allRiders) r.id: demoBike,
    };
    final Map<String, CyclingTeam> allTeamsMap = {for (final t in world.teams) t.id: t};

    final worker = IsolateSimulationWorker();
    await worker.initialize(
      stage: stage,
      playerTeamId: playerTeam.id,
      allRidersMap: allRidersMap,
      allBikesMap: allBikesMap,
      allTeamsMap: allTeamsMap,
      initialSpeed: initialSpeed,
      targetFps: targetFps,
    );

    return worker;
  }

  /// Rozpoczyna lub wznawia pętlę symulacji w tle.
  void start() {
    _isolateCommandPort?.send(const StartSimulationCommand());
    _isRunning = true;
    _isPaused = false;
  }

  /// Wstrzymuje bieg symulacji w tle.
  void pause() {
    _isolateCommandPort?.send(const PauseSimulationCommand());
    _isRunning = false;
    _isPaused = true;
  }

  /// Zmienia mnożnik prędkości symulacji (np. 1x, 2x, 4x, 8x).
  void setTimeSpeed(SimulationTimeSpeed speed) {
    _isolateCommandPort?.send(SetTimeSpeedCommand(speed));
  }

  /// Wydaje polecenie taktyczne pojedynczemu kolarzowi.
  void setTacticalOrder({
    required String riderId,
    required TacticalOrder order,
    double targetEffortPercent = 100.0,
    int? targetWatts,
    String? leaderRiderId,
    String? targetRivalId,
  }) {
    _isolateCommandPort?.send(SetTacticalOrderCommand(
      riderId: riderId,
      order: order,
      targetEffortPercent: targetEffortPercent,
      targetWatts: targetWatts,
      leaderRiderId: leaderRiderId,
      targetRivalId: targetRivalId,
    ));
  }

  /// Stosuje zbiorczy manewr taktyki drużynowej (1-Click Team Tactics).
  void applyTeamTactics({
    required String presetName,
    required Map<String, TacticalOrder> assignments,
    Map<String, double>? effortMap,
  }) {
    _isolateCommandPort?.send(ApplyTeamTacticsCommand(
      presetName: presetName,
      assignments: assignments,
      effortMap: effortMap,
    ));
  }

  /// Wykonuje pojedynczy krok symulacji w tle (przydatne do testów i precyzyjnego klatkowania).
  void step({double dtSeconds = 1.0}) {
    _isolateCommandPort?.send(StepSimulationCommand(dtSeconds: dtSeconds));
  }

  /// Bezpiecznie zamyka i niszczy wątek Isolate oraz zwalnia zasoby portów.
  Future<void> dispose() async {
    _isolateCommandPort?.send(const TerminateSimulationCommand());
    _uiReceivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isInitialized = false;
    _isRunning = false;
    _isPaused = false;

    await _snapshotController.close();
    await _finishController.close();
  }
}
