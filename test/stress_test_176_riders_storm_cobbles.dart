import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/drafting_grid_system.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

/// Buduje ekstremalny etap klasyku brukowego z 5-gwiazdkowymi sektorami,
/// ulewą ([WeatherCondition.heavyStorm]) i wiatrem bocznym 50 km/h.
RaceStage _buildExtremeStormCobblesStage() {
  return const RaceStage(
    id: 'stress_test_storm_cobbles_5star',
    stageNumber: 1,
    name: "Trouée d'Arenberg — Carrefour de l'Arbre (Ulewa & Wiatr 50 km/h)",
    stageType: StageType.cobbleClassic,
    baseTemperatureCelsius: 7.5,
    weatherCondition: WeatherCondition.heavyStorm,
    windSpeedKmh: 50.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 2.0,
        startElevationM: 28.0,
        endElevationM: 32.0,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 75.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 2.0,
        lengthKm: 3.5,
        startElevationM: 32.0,
        endElevationM: 48.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 98.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 2,
        startKm: 5.5,
        lengthKm: 3.5,
        startElevationM: 48.0,
        endElevationM: 36.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 96.0,
        windDirectionDegrees: 250.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.intermediateSprint,
      ),
      StageSegment(
        index: 3,
        startKm: 9.0,
        lengthKm: 3.0,
        startElevationM: 36.0,
        endElevationM: 42.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 95.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
  );
}

/// Zbiera dokładnie 176 kolarzy (22 drużyny × 8 kolarzy) z wygenerowanego świata.
({
  Map<String, Rider> ridersMap,
  Map<String, CompleteBike> bikesMap,
  Map<String, CyclingTeam> teamsMap,
  String playerTeamId,
}) _build176RiderPeloton(WorldTourGenerationResult world) {
  final Map<String, Rider> ridersMap = {};
  final Map<String, CompleteBike> bikesMap = {};
  final Map<String, CyclingTeam> teamsMap = {};

  for (final team in world.teams) {
    if (teamsMap.length >= 22) break;
    final teamRiders = world.ridersByTeamId[team.id] ?? const <Rider>[];
    if (teamRiders.length < 8 || team.inventoryBikes.isEmpty) continue;

    final selectedRiders = teamRiders.take(8).toList();
    final List<String> selectedIds = [];

    for (final rider in selectedRiders) {
      ridersMap[rider.id] = rider;
      bikesMap[rider.id] = team.inventoryBikes.first;
      selectedIds.add(rider.id);
    }

    teamsMap[team.id] = team.copyWith(rosterRiderIds: selectedIds);
  }

  return (
    ridersMap: ridersMap,
    bikesMap: bikesMap,
    teamsMap: teamsMap,
    playerTeamId: teamsMap.keys.first,
  );
}

/// Weryfikuje brak wartości NaN/Infinity oraz poprawność zakresów w całym stanie symulacji.
void _assertSimulationStateFiniteAndValid(StageSimulationState state) {
  expect(state.elapsedSeconds.isFinite, isTrue,
      reason: 'elapsedSeconds nie może być NaN/Infinity');
  expect(state.elapsedSeconds, greaterThanOrEqualTo(0.0));
  expect(state.leadKilometerMark.isFinite, isTrue,
      reason: 'leadKilometerMark nie może być NaN/Infinity');
  expect(state.leadDistanceToFinishKm.isFinite, isTrue,
      reason: 'leadDistanceToFinishKm nie może być NaN/Infinity');
  expect(state.riderStates.length, equals(176));
  expect(state.groups, isNotEmpty);

  for (final RiderRaceState rs in state.riderStates.values) {
    expect(rs.distanceCoveredMeters.isFinite, isTrue,
        reason: 'distanceCoveredMeters NaN/Infinity dla ${rs.riderId}');
    expect(rs.distanceCoveredMeters, greaterThanOrEqualTo(0.0));

    expect(rs.lateralPositionRoad.isFinite, isTrue,
        reason: 'lateralPositionRoad NaN/Infinity dla ${rs.riderId}');
    expect(rs.lateralPositionRoad, inInclusiveRange(-1.0, 1.0));

    expect(rs.currentSpeedMs.isFinite, isTrue,
        reason: 'currentSpeedMs NaN/Infinity dla ${rs.riderId}');
    expect(rs.currentSpeedMs, greaterThanOrEqualTo(0.0));

    expect(rs.currentWPrime.isFinite, isTrue,
        reason: 'currentWPrime NaN/Infinity dla ${rs.riderId}');
    expect(rs.currentWPrime, greaterThanOrEqualTo(0.0));

    expect(rs.currentGlycogen.isFinite, isTrue,
        reason: 'currentGlycogen NaN/Infinity dla ${rs.riderId}');
    expect(rs.currentGlycogen, greaterThanOrEqualTo(0.0));

    expect(rs.timeGapToLeaderSeconds.isFinite, isTrue,
        reason: 'timeGapToLeaderSeconds NaN/Infinity dla ${rs.riderId}');
    expect(rs.timeGapToLeaderSeconds, greaterThanOrEqualTo(0.0));
  }

  for (final PelotonGroup group in state.groups) {
    expect(group.gapToRaceLeaderSeconds.isFinite, isTrue,
        reason: 'gapToRaceLeaderSeconds NaN/Infinity w grupie ${group.id}');
    expect(group.distanceCoveredKm.isFinite, isTrue,
        reason: 'distanceCoveredKm NaN/Infinity w grupie ${group.id}');
    expect(group.averageSpeedKmh.isFinite, isTrue,
        reason: 'averageSpeedKmh NaN/Infinity w grupie ${group.id}');

    for (final GridRiderPosition pos in group.positions) {
      expect(pos.draftingSavingsPercent.isFinite, isTrue);
      expect(pos.longitudinalOffsetMeters.isFinite, isTrue);
      expect(pos.lateralOffsetMeters.isFinite, isTrue);
    }
  }
}

void main() {
  late WorldTourGenerationResult world;

  setUpAll(() {
    world = WorldTeamsGenerator.generateWorldTourSystem(seed: 20260412);
  });

  group('Stress test 176 kolarzy — 5★ bruk, ulewa i wiatr boczny 50 km/h', () {
    test('Pełna symulacja 176 kolarzy w ulewie na 5★ bruku kończy się stabilnie bez NaN/Infinity', () {
      final peloton = _build176RiderPeloton(world);
      expect(peloton.ridersMap.length, equals(176));
      expect(peloton.bikesMap.length, equals(176));
      expect(peloton.teamsMap.length, equals(22));

      final stage = _buildExtremeStormCobblesStage();
      final loop = StageSimulationLoop.initializeStage(
        stage: stage,
        playerTeamId: peloton.playerTeamId,
        allRidersMap: peloton.ridersMap,
        allBikesMap: peloton.bikesMap,
        allTeamsMap: peloton.teamsMap,
        random: math.Random(20260412),
      );

      _assertSimulationStateFiniteAndValid(loop.state);

      final playerIds = loop.state.playerRiderIds;
      expect(playerIds.length, equals(8));

      int steps = 0;
      const int maxSteps = 2400; // max 40 min przy dt=1.0 s na 12 km ekstremalnym sektorze
      bool hasEnteredCobbles5Star = false;

      while (!loop.state.isStageFinished && steps < maxSteps) {
        // Testujemy dynamiczną zmianę rozkazów taktycznych w trakcie jazdy po 5★ bruku
        if (steps == 120) {
          loop.setTacticalOrder(playerIds[0], TacticalOrder.attack);
          loop.setTacticalOrder(playerIds[1], TacticalOrder.pullGroup);
          loop.setTacticalOrder(playerIds[2], TacticalOrder.protectLeader);
          loop.setTacticalOrder(playerIds[3], TacticalOrder.saveEnergy);
        } else if (steps == 300) {
          loop.setTacticalOrder(playerIds[0], TacticalOrder.followWheels);
          loop.setTacticalOrder(playerIds[4], TacticalOrder.fetchBidonsFromCar);
        }

        final state = loop.step(dt: 1.0);
        steps++;

        final currentSeg = state.stage.segments[state.currentSegmentIndex];
        if (currentSeg.surfaceType == SegmentSurfaceType.cobblestonesSector5) {
          hasEnteredCobbles5Star = true;
        }

        // Pełna weryfikacja stabilności numerycznej w każdym kroku dla wszystkich 176 kolarzy
        _assertSimulationStateFiniteAndValid(state);
      }

      expect(hasEnteredCobbles5Star, isTrue);
      expect(loop.state.isStageFinished, isTrue,
          reason: 'Symulacja powinna ukończyć 12 km etap w limicie $maxSteps kroków');
      expect(loop.state.finishResults, isNotEmpty);

      for (final result in loop.state.finishResults) {
        expect(result.finishTimeSeconds.isFinite, isTrue);
        expect(result.finishTimeSeconds, greaterThan(0.0));
        expect(result.gapToWinnerSeconds.isFinite, isTrue);
        expect(result.gapToWinnerSeconds, greaterThanOrEqualTo(0.0));
      }
    });

    test('Wysoka częstotliwość kroków (dt=0.5 s) dla 176 kolarzy na mokrym 5★ bruku zachowuje ciągłość fizyki', () {
      final peloton = _build176RiderPeloton(world);
      final stage = _buildExtremeStormCobblesStage();

      final loop = StageSimulationLoop.initializeStage(
        stage: stage,
        playerTeamId: peloton.playerTeamId,
        allRidersMap: peloton.ridersMap,
        allBikesMap: peloton.bikesMap,
        allTeamsMap: peloton.teamsMap,
        random: math.Random(998877),
      );

      for (int stepIdx = 0; stepIdx < 300; stepIdx++) {
        if (loop.state.isStageFinished) break;
        final state = loop.step(dt: 0.5);
        _assertSimulationStateFiniteAndValid(state);
      }

      expect(loop.state.elapsedSeconds, closeTo(150.0, 1e-6));
      expect(loop.state.leadKilometerMark, greaterThan(0.5));
    });
  });
}
