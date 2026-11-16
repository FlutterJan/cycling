import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/breakaway_vs_peloton_equilibrium_solver.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

RaceStage _buildStage({
  required StageType stageType,
  required List<StageSegment> segments,
  double windSpeedKmh = 12.0,
}) {
  return RaceStage(
    id: 'stage_${stageType.name}',
    stageNumber: 1,
    name: 'Test Stage ${stageType.name}',
    stageType: stageType,
    segments: segments,
    baseTemperatureCelsius: 21.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: windSpeedKmh,
  );
}

StageSegment _segment({
  required int index,
  required double startKm,
  required double lengthKm,
  required double startElevM,
  required double endElevM,
  SegmentClassification classification = SegmentClassification.none,
}) {
  return StageSegment(
    index: index,
    startKm: startKm,
    lengthKm: lengthKm,
    startElevationM: startElevM,
    endElevationM: endElevM,
    surfaceType: SegmentSurfaceType.smoothAsphalt,
    technicalDifficulty: 20.0,
    windDirectionDegrees: 90.0,
    roadBearingDegrees: 90.0,
    sprintOrKomClassification: classification,
  );
}

void main() {
  group('BreakawayVsPelotonEquilibriumSolver', () {
    test('flat stage with sprint teams yields 8-12% survival probability', () {
      final result = BreakawayVsPelotonEquilibriumSolver.solve(
        const BreakawayEquilibriumInput(
          stageType: StageType.flat,
          stageDistanceKm: 185.0,
          currentKm: 95.0,
          currentGapSeconds: 180.0,
          breakawayRiderCount: 5,
          breakawayCooperationScore: 0.85,
          sprintTeamsInterestedCount: 3,
          committedChaseDomestiques: 4,
        ),
      );

      expect(
        result.terrainProfile,
        EquilibriumTerrainProfile.flatSprinterControlled,
      );
      expect(result.survivalProbability, inInclusiveRange(0.08, 0.12));
      expect(result.baselineProbability, closeTo(0.10, 1e-6));
    });

    test('hilly Breakaway-Friendly stage yields 45-55% survival probability',
        () {
      final result = BreakawayVsPelotonEquilibriumSolver.solve(
        const BreakawayEquilibriumInput(
          stageType: StageType.hilly,
          stageDistanceKm: 192.0,
          currentKm: 110.0,
          currentGapSeconds: 240.0,
          breakawayRiderCount: 8,
          breakawayCooperationScore: 0.86,
          sprintTeamsInterestedCount: 1,
          committedChaseDomestiques: 3,
        ),
      );

      expect(
        result.terrainProfile,
        EquilibriumTerrainProfile.hillyBreakawayFriendly,
      );
      expect(result.survivalProbability, inInclusiveRange(0.45, 0.55));
      expect(result.baselineProbability, closeTo(0.50, 1e-6));
    });

    test(
        'high mountain survival depends on >= 1 min per 3 km at foot of final climb',
        () {
      // 15 km final climb -> required foot gap = (15 / 3) * 60 = 300 s (5 min)
      expect(
        BreakawayVsPelotonEquilibriumSolver.requiredMountainFootGapSeconds(15.0),
        closeTo(300.0, 1e-6),
      );
      expect(
        BreakawayVsPelotonEquilibriumSolver.requiredMountainFootGapSeconds(12.0),
        closeTo(240.0, 1e-6),
      );

      const finalClimb = FinalClimbProfile(
        lengthKm: 15.0,
        averageGradientPercent: 8.2,
        elevationGainM: 1230.0,
        footKm: 150.0,
        summitKm: 165.0,
      );

      final sufficientBuffer = BreakawayVsPelotonEquilibriumSolver.solve(
        const BreakawayEquilibriumInput(
          stageType: StageType.summitFinish,
          stageDistanceKm: 165.0,
          currentKm: 150.0,
          currentGapSeconds: 360.0,
          breakawayRiderCount: 6,
          breakawayCooperationScore: 0.85,
          finalClimb: finalClimb,
          gapAtClimbFootSeconds: 360.0, // 6 min >= 5 min required
          gcBattleIntensity: 0.75,
        ),
      );

      final insufficientBuffer = BreakawayVsPelotonEquilibriumSolver.solve(
        const BreakawayEquilibriumInput(
          stageType: StageType.summitFinish,
          stageDistanceKm: 165.0,
          currentKm: 150.0,
          currentGapSeconds: 120.0,
          breakawayRiderCount: 6,
          breakawayCooperationScore: 0.85,
          finalClimb: finalClimb,
          gapAtClimbFootSeconds: 120.0, // 2 min < 5 min required
          gcBattleIntensity: 0.75,
        ),
      );

      expect(sufficientBuffer.meetsMountainFootRule, isTrue);
      expect(sufficientBuffer.requiredClimbFootGapSeconds, closeTo(300.0, 1e-6));
      expect(sufficientBuffer.climbFootGapMarginSeconds, closeTo(60.0, 1e-6));
      expect(sufficientBuffer.survivalProbability, greaterThan(0.55));

      expect(insufficientBuffer.meetsMountainFootRule, isFalse);
      expect(insufficientBuffer.climbFootGapMarginSeconds, closeTo(-180.0, 1e-6));
      expect(insufficientBuffer.survivalProbability, lessThan(0.25));
    });

    test('solveForStage detects final climb from RaceStage segments', () {
      final stage = _buildStage(
        stageType: StageType.highMountain,
        segments: [
          _segment(
            index: 0,
            startKm: 0.0,
            lengthKm: 120.0,
            startElevM: 400.0,
            endElevM: 600.0,
          ),
          _segment(
            index: 1,
            startKm: 120.0,
            lengthKm: 18.0,
            startElevM: 600.0,
            endElevM: 1950.0,
            classification: SegmentClassification.horsCategorie,
          ),
        ],
      );

      final detected = FinalClimbProfile.detectFromStage(stage);
      expect(detected, isNotNull);
      expect(detected!.lengthKm, closeTo(18.0, 1e-6));
      // 18 km -> 6 min (360 s) required at foot
      expect(detected.requiredFootGapSeconds, closeTo(360.0, 1e-6));

      final result = BreakawayVsPelotonEquilibriumSolver.solveForStage(
        stage: stage,
        currentKm: 120.0,
        currentGapSeconds: 420.0,
        breakawayRiderCount: 4,
        gapAtClimbFootSeconds: 420.0,
      );

      expect(result.meetsMountainFootRule, isTrue);
      expect(result.requiredClimbFootGapSeconds, closeTo(360.0, 1e-6));
      expect(result.survivalProbability, greaterThan(0.55));
    });

    test('time trial and empty breakaway return 0.0 survival probability', () {
      final ttResult = BreakawayVsPelotonEquilibriumSolver.solve(
        const BreakawayEquilibriumInput(
          stageType: StageType.individualTimeTrial,
          stageDistanceKm: 32.0,
          currentKm: 10.0,
          currentGapSeconds: 0.0,
          breakawayRiderCount: 0,
        ),
      );
      expect(ttResult.terrainProfile, EquilibriumTerrainProfile.timeTrial);
      expect(ttResult.survivalProbability, 0.0);

      final caughtResult = BreakawayVsPelotonEquilibriumSolver.solve(
        const BreakawayEquilibriumInput(
          stageType: StageType.flat,
          stageDistanceKm: 180.0,
          currentKm: 160.0,
          currentGapSeconds: 3.0,
          breakawayRiderCount: 4,
        ),
      );
      expect(caughtResult.survivalProbability, 0.0);
    });

    test('JSON serialization round-trip preserves equilibrium models', () {
      const input = BreakawayEquilibriumInput(
        stageType: StageType.highMountain,
        stageDistanceKm: 170.0,
        currentKm: 140.0,
        currentGapSeconds: 330.0,
        breakawayRiderCount: 5,
        finalClimb: FinalClimbProfile(
          lengthKm: 15.0,
          averageGradientPercent: 7.8,
          elevationGainM: 1170.0,
          footKm: 155.0,
          summitKm: 170.0,
        ),
        gapAtClimbFootSeconds: 320.0,
      );

      final inputRestored = BreakawayEquilibriumInput.fromJson(input.toJson());
      expect(inputRestored.stageType, input.stageType);
      expect(inputRestored.finalClimb?.lengthKm, 15.0);
      expect(inputRestored.gapAtClimbFootSeconds, 320.0);

      final result = BreakawayVsPelotonEquilibriumSolver.solve(input);
      final resultRestored =
          BreakawayEquilibriumResult.fromJson(result.toJson());
      expect(resultRestored.terrainProfile, result.terrainProfile);
      expect(resultRestored.survivalProbability, result.survivalProbability);
      expect(resultRestored.meetsMountainFootRule, result.meetsMountainFootRule);
    });
  });
}
