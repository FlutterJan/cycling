import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/alpine_climb_benchmark_calibrator.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/engine/simulation/time_trial_simulation_engine.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';

RaceStage _buildAlpeDHuezStage() {
  // Historyczny finałowy podjazd na Alpe d'Huez (13.8 km, śr. 8.1%, 720 -> 1838 m n.p.m.)
  return const RaceStage(
    id: 'tdf_alpe_dhuez_realism',
    stageNumber: 14,
    name: "Bourg-d'Oisans — Alpe d'Huez (HC)",
    stageType: StageType.summitFinish,
    baseTemperatureCelsius: 19.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 4.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 4.6,
        startElevationM: 720.0,
        endElevationM: 1120.0, // ~8.7%
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 4.6,
        lengthKm: 4.6,
        startElevationM: 1120.0,
        endElevationM: 1488.0, // ~8.0%
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 2,
        startKm: 9.2,
        lengthKm: 4.6,
        startElevationM: 1488.0,
        endElevationM: 1838.0, // ~7.6%
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 42.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
  );
}

RaceStage _build40KmIttStage() {
  // Płasko-pagórkowata 40-kilometrowa czasówka indywidualna UCI WorldTour
  return const RaceStage(
    id: 'wt_itt_40km_realism',
    stageNumber: 7,
    name: 'Nuits-Saint-Georges — Gevrey-Chambertin (ITT 40 km)',
    stageType: StageType.individualTimeTrial,
    baseTemperatureCelsius: 20.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 8.0,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 10.0,
        startElevationM: 230.0,
        endElevationM: 235.0, // +0.05%
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 45.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 10.0,
        lengthKm: 10.0,
        startElevationM: 235.0,
        endElevationM: 275.0, // +0.40%
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 25.0,
        windDirectionDegrees: 45.0,
        roadBearingDegrees: 15.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 2,
        startKm: 20.0,
        lengthKm: 10.0,
        startElevationM: 275.0,
        endElevationM: 245.0, // -0.30%
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 22.0,
        windDirectionDegrees: 45.0,
        roadBearingDegrees: 345.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 3,
        startKm: 30.0,
        lengthKm: 10.0,
        startElevationM: 245.0,
        endElevationM: 255.0, // +0.10%
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 18.0,
        windDirectionDegrees: 45.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
    ],
  );
}

void main() {
  late WorldTourGenerationResult world;
  late Map<String, CyclingTeam> teamsById;

  setUpAll(() {
    world = WorldTeamsGenerator.generateWorldTourSystem(seed: 20260714);
    teamsById = {
      for (final team in world.teams) team.id: team,
    };
  });

  group('Regresja balansu: Alpe d\'Huez (UCI WorldTour)', () {
    test('Wzorzec kalibracji Alpe d\'Huez i Top 10 wspinaczy WorldTour mieszczą się w realistycznych widełkach', () {
      // 1. Weryfikacja wzorca UCI WorldTour (60 kg, 6.4 W/kg -> 38:30–39:45, VAM ~1750 m/h)
      final benchmark = AlpineClimbBenchmarkCalibrator.simulateClimb(
        profile: AlpineClimbBenchmarkCalibrator.alpeDHuez,
      );
      expect(benchmark.isWithinTimeWindow, isTrue);
      expect(benchmark.isWithinVamTolerance, isTrue);
      expect(benchmark.elapsedTimeSeconds, inInclusiveRange(2310.0, 2385.0));
      expect(benchmark.vamMetersPerHour, inInclusiveRange(1710.0, 1790.0));

      // 2. Wybór Top 10 najlepszych górali WorldTour i symulacja tempa ~40 min (104% FTP)
      final wtTeamIds = world.worldTourTeams.map((t) => t.id).toSet();
      final wtClimbers = world.allRiders
          .where((r) =>
              wtTeamIds.contains(r.contract.teamId) &&
              (r.specialization == RiderSpecialization.gcClimber ||
                  r.specialization == RiderSpecialization.pureClimber))
          .toList()
        ..sort((a, b) => b.physiology.wattsPerKg.compareTo(a.physiology.wattsPerKg));

      expect(wtClimbers.length, greaterThanOrEqualTo(10));
      final top10Climbers = wtClimbers.take(10).toList();

      final results = top10Climbers.map((rider) {
        // Na ~40-minutowym finiszu HC liderzy jadą na 100% swojej mocy progowej (FTP)
        return AlpineClimbBenchmarkCalibrator.simulateClimb(
          profile: AlpineClimbBenchmarkCalibrator.alpeDHuez,
          riderWeightKg: rider.physiology.weightKg,
          wattsPerKg: rider.physiology.wattsPerKg,
        );
      }).toList()
        ..sort((a, b) => a.elapsedTimeSeconds.compareTo(b.elapsedTimeSeconds));

      final double winnerTime = results.first.elapsedTimeSeconds;
      final double tenthTime = results[9].elapsedTimeSeconds;
      final double top10Spread = tenthTime - winnerTime;

      // Zwycięzca WorldTour na Alpe d'Huez: 37:00–44:00 (2220–2640 s)
      expect(winnerTime, inInclusiveRange(2220.0, 2640.0));
      // Różnica 1. vs 10. na finiszu HC Alpe d'Huez: 15 s – 5:30 min (15–330 s)
      expect(top10Spread, inInclusiveRange(15.0, 330.0));

      for (int i = 1; i < results.length; i++) {
        expect(
          results[i].elapsedTimeSeconds,
          greaterThanOrEqualTo(results[i - 1].elapsedTimeSeconds),
        );
      }
    });

    test('Pełna symulacja etapu Alpe d\'Huez w StageSimulationLoop daje realistyczny czas zwycięzcy i różnice Top 10', () {
      final stage = _buildAlpeDHuezStage();
      final wtTeams = world.worldTourTeams;
      expect(wtTeams.length, greaterThanOrEqualTo(15));

      // Po 1 najlepszym góralu/GC z każdej z 18 drużyn WorldTour
      final Map<String, Rider> ridersMap = {};
      final Map<String, CompleteBike> bikesMap = {};
      final Map<String, CyclingTeam> activeTeamsMap = {};

      for (final team in wtTeams) {
        final teamRiders = List<Rider>.from(world.ridersByTeamId[team.id] ?? [])
          ..sort((a, b) => b.physiology.wattsPerKg.compareTo(a.physiology.wattsPerKg));
        if (teamRiders.isEmpty || team.inventoryBikes.isEmpty) continue;

        final leader = teamRiders.first;
        ridersMap[leader.id] = leader;
        bikesMap[leader.id] = team.inventoryBikes.first;
        activeTeamsMap[team.id] = team;
      }

      expect(ridersMap.length, greaterThanOrEqualTo(15));

      final loop = StageSimulationLoop.initializeStage(
        stage: stage,
        playerTeamId: activeTeamsMap.keys.first,
        allRidersMap: ridersMap,
        allBikesMap: bikesMap,
        allTeamsMap: activeTeamsMap,
        random: math.Random(20260714),
      );

      int steps = 0;
      const int maxSteps = 3000; // max 6000 s (100 min) przy dt=2.0
      while (!loop.state.isStageFinished && steps < maxSteps) {
        loop.step(dt: 2.0);
        steps++;
      }

      expect(loop.state.isStageFinished, isTrue);
      final finishes = loop.state.finishResults;
      expect(finishes, isNotEmpty);

      final winner = finishes.first;
      // Czas zwycięzcy na 13.8 km Alpe d'Huez w pełnej pętli (z AI, wysokością i zmęczeniem): 36:00–52:00
      expect(winner.finishTimeSeconds, inInclusiveRange(2160.0, 3120.0));
      expect(winner.gapToWinnerSeconds, equals(0.0));

      // Pętla etapu zatrzymuje się po przekroczeniu mety przez zwycięzcę;
      // wyliczamy dystansowe/czasowe straty pozostałych kolarzy Top 10 na mecie.
      final double stageLengthM = stage.totalDistanceKm * 1000.0;
      final sortedStates = loop.state.riderStates.values.toList()
        ..sort((a, b) => b.distanceCoveredMeters.compareTo(a.distanceCoveredMeters));
      expect(sortedStates.length, greaterThanOrEqualTo(10));

      final List<double> top10GapsSeconds = sortedStates.take(10).map((rs) {
        if (rs.riderId == winner.riderId || rs.distanceCoveredMeters >= stageLengthM) {
          return 0.0;
        }
        final double remainingM = stageLengthM - rs.distanceCoveredMeters;
        final double speedMs = math.max(3.5, rs.currentSpeedMs);
        return remainingM / speedMs;
      }).toList()
        ..sort();

      // Różnice w Top 10: 10. zawodnik traci od kilku sekund do maks. 8 minut (480 s)
      expect(top10GapsSeconds.first, equals(0.0));
      expect(top10GapsSeconds[9], greaterThan(0.0));
      expect(top10GapsSeconds[9], lessThanOrEqualTo(480.0));

      for (int i = 1; i < 10; i++) {
        expect(top10GapsSeconds[i], greaterThanOrEqualTo(top10GapsSeconds[i - 1]));
      }
    });
  });

  group('Regresja balansu: 40-kilometrowa czasówka ITT (UCI WorldTour)', () {
    test('Czas zwycięzcy 40 km ITT oraz różnice czasowe w Top 10 mieszczą się w widełkach UCI WorldTour', () {
      final ittStage = _build40KmIttStage();
      final wtTeamIds = world.worldTourTeams.map((t) => t.id).toSet();

      // Wybieramy 18 najlepszych czasowców / liderów GC z WorldTour
      final ttCandidates = world.allRiders
          .where((r) => wtTeamIds.contains(r.contract.teamId))
          .toList()
        ..sort((a, b) {
          final double scoreB = (b.physiology.ftpWatts * 0.7) +
              (b.skills.timeTrialPositioning * 1.5);
          final double scoreA = (a.physiology.ftpWatts * 0.7) +
              (a.skills.timeTrialPositioning * 1.5);
          return scoreB.compareTo(scoreA);
        });

      final startList = ttCandidates.take(18).toList();
      expect(startList.length, equals(18));

      final Map<String, PacingStrategy> pacingMap = {
        for (final rider in startList) rider.id: PacingStrategy.balanced,
      };

      final ittResult = TimeTrialSimulationEngine.simulateIttStage(
        stage: ittStage,
        riders: startList,
        teamsMap: teamsById,
        customPacing: pacingMap,
      );

      expect(ittResult.type, equals(TimeTrialType.itt));
      expect(ittResult.totalDistanceKm, closeTo(40.0, 0.01));
      expect(ittResult.riderResults.length, equals(18));

      final winner = ittResult.riderResults.first;
      final second = ittResult.riderResults[1];
      final tenth = ittResult.riderResults[9];

      // Zwycięzca 40 km ITT WorldTour: 44:00–53:00 (2640–3180 s), śr. 45.2–54.5 km/h
      expect(winner.finishTimeSeconds, inInclusiveRange(2640.0, 3180.0));
      expect(winner.averageSpeedKmh, inInclusiveRange(45.2, 54.5));
      expect(winner.gapToWinnerSeconds, equals(0.0));
      expect(winner.isBlownUp, isFalse);

      // Różnice czasowe w Top 10 na 40 km ITT:
      // 2. miejsce: ciasna walka (0.5 s – 90 s)
      expect(second.gapToWinnerSeconds, inInclusiveRange(0.5, 90.0));
      // 10. miejsce: 20 s – 4:30 min (20–270 s)
      expect(tenth.gapToWinnerSeconds, inInclusiveRange(20.0, 270.0));

      for (int i = 0; i < 10; i++) {
        final r = ittResult.riderResults[i];
        expect(r.rank, equals(i + 1));
        expect(r.isBlownUp, isFalse);
        expect(r.splits.length, equals(ittResult.checkpoints.length));
        for (int s = 1; s < r.splits.length; s++) {
          expect(
            r.splits[s].splitElapsedTimeSeconds,
            greaterThan(r.splits[s - 1].splitElapsedTimeSeconds),
          );
        }
        if (i > 0) {
          expect(
            r.gapToWinnerSeconds,
            greaterThanOrEqualTo(ittResult.riderResults[i - 1].gapToWinnerSeconds),
          );
        }
      }
    });

    test('Strategia All-Out (122% FTP) na 40 km ITT kończy się odcięciem W\' i wyraźną stratą czasową', () {
      final ittStage = _build40KmIttStage();
      final wtTeamIds = world.worldTourTeams.map((t) => t.id).toSet();

      final specialist = world.allRiders.firstWhere(
        (r) =>
            wtTeamIds.contains(r.contract.teamId) &&
            r.specialization == RiderSpecialization.timeTrialist,
      );

      final balancedResult = TimeTrialSimulationEngine.simulateIttStage(
        stage: ittStage,
        riders: [specialist],
        teamsMap: teamsById,
        customPacing: {specialist.id: PacingStrategy.balanced},
      ).riderResults.single;

      final allOutResult = TimeTrialSimulationEngine.simulateIttStage(
        stage: ittStage,
        riders: [specialist],
        teamsMap: teamsById,
        customPacing: {specialist.id: PacingStrategy.allOut},
      ).riderResults.single;

      expect(balancedResult.isBlownUp, isFalse);
      expect(allOutResult.isBlownUp, isTrue);
      expect(
        allOutResult.finishTimeSeconds,
        greaterThan(balancedResult.finishTimeSeconds + 30.0),
      );
    });
  });
}
