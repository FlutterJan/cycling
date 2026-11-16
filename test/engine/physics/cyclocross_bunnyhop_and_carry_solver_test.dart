import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/cyclocross_bunnyhop_and_carry_solver.dart';
import 'package:pro_peloton_manager/models/race/cyclocross_course_and_mud_model.dart';

void main() {
  const solver = CyclocrossBunnyhopAndCarrySolver();

  group('CyclocrossBunnyhopAndCarrySolver', () {
    test('wybiera Dismount & Run w głębokim błocie gdy bieg 12-16 km/h jest szybszy', () {
      const deepMudSegment = CyclocrossCourseSegment(
        index: 1,
        startMeter: 400.0,
        lengthMeters: 120.0,
        terrainType: CyclocrossTerrainType.deepMud,
        gradientPercent: 2.0,
        mudDepthCm: 18.0,
        mudViscosityIndex: 0.85,
      );

      final result = solver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: deepMudSegment,
          mudCondition: CyclocrossMudCondition.boggySwamp,
          powerWatts: 340.0,
          bikeHandling: 80.0,
          runningEfficiency: 80.0,
          wPrimeRemainingRatio: 0.75,
        ),
      );

      expect(result.selectedMode, CyclocrossTraversalMode.dismountAndRun);
      expect(result.carryTechnique, CyclocrossCarryTechnique.shoulderCarry);
      expect(result.outcome, CyclocrossObstacleOutcome.cleanRunCarry);
      expect(result.dismountRunSpeedKmh, inInclusiveRange(11.0, 16.0));
      expect(result.effectiveSpeedKmh, greaterThan(result.mountedSpeedKmh));
      expect(result.timeDeltaVsSaddleSeconds, greaterThan(0.0));
    });

    test('utrzymuje jazdę w siodle na szybkiej łące i płytkim błocie', () {
      const grassSegment = CyclocrossCourseSegment(
        index: 0,
        startMeter: 0.0,
        lengthMeters: 250.0,
        terrainType: CyclocrossTerrainType.meadowGrass,
        gradientPercent: 0.0,
      );

      final result = solver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: grassSegment,
          mudCondition: CyclocrossMudCondition.tackyLoam,
          powerWatts: 380.0,
          bikeHandling: 78.0,
        ),
      );

      expect(result.selectedMode, CyclocrossTraversalMode.rideInSaddle);
      expect(result.carryTechnique, isNull);
      expect(result.outcome, CyclocrossObstacleOutcome.cleanRide);
      expect(result.mountedSpeedKmh, greaterThan(result.dismountRunSpeedKmh));
    });

    test('zawsze wybiera Dismount & Run z rowerem na ramieniu na schodach', () {
      const stairsSegment = CyclocrossCourseSegment(
        index: 2,
        startMeter: 900.0,
        lengthMeters: 35.0,
        terrainType: CyclocrossTerrainType.staircaseRunUp,
        gradientPercent: 18.0,
        stairStepCount: 28,
      );

      final result = solver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: stairsSegment,
          powerWatts: 420.0,
          bikeHandling: 92.0,
          runningEfficiency: 85.0,
        ),
      );

      expect(result.selectedMode, CyclocrossTraversalMode.dismountAndRun);
      expect(result.carryTechnique, CyclocrossCarryTechnique.shoulderCarry);
      expect(result.outcome, CyclocrossObstacleOutcome.cleanRunCarry);
      expect(result.timeDeltaVsSaddleSeconds, greaterThan(0.0));
    });

    test('kolarz z bikeHandling >= 85 wykonuje Bunny-Hop nad belkami i zyskuje 1.8 s', () {
      const planksSegment = CyclocrossCourseSegment(
        index: 3,
        startMeter: 1500.0,
        lengthMeters: 30.0,
        terrainType: CyclocrossTerrainType.planks,
        plankCount: 2,
        plankHeightCm: 40.0,
        isBunnyHoppable: true,
      );

      final result = solver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: planksSegment,
          bikeHandling: 88.0,
          wPrimeRemainingRatio: 0.65,
          deterministicRoll: 0.99,
        ),
      );

      expect(result.selectedMode, CyclocrossTraversalMode.bunnyHop);
      expect(result.attemptedBunnyHop, isTrue);
      expect(result.wheelClipped, isFalse);
      expect(result.outcome, CyclocrossObstacleOutcome.cleanBunnyHop);
      expect(result.bunnyHopTimeGainSeconds, closeTo(1.8, 0.001));
      expect(result.wheelClipRiskProbability, lessThan(0.03));
    });

    test('kolarz z bikeHandling < 85 zsiada przed belkami zamiast Bunny-Hop', () {
      const planksSegment = CyclocrossCourseSegment(
        index: 3,
        startMeter: 1500.0,
        lengthMeters: 30.0,
        terrainType: CyclocrossTerrainType.planks,
        plankCount: 2,
        plankHeightCm: 40.0,
        isBunnyHoppable: true,
      );

      final result = solver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: planksSegment,
          bikeHandling: 84.0,
          wPrimeRemainingRatio: 0.90,
        ),
      );

      expect(result.selectedMode, CyclocrossTraversalMode.dismountAndRun);
      expect(result.attemptedBunnyHop, isFalse);
      expect(result.bunnyHopTimeGainSeconds, 0.0);
    });

    test('wysokie zmęczenie W\' < 15% zwiększa ryzyko zahaczenia kołem o belkę', () {
      const planksSegment = CyclocrossCourseSegment(
        index: 3,
        startMeter: 1500.0,
        lengthMeters: 30.0,
        terrainType: CyclocrossTerrainType.planks,
        plankCount: 2,
        plankHeightCm: 40.0,
        isBunnyHoppable: true,
      );

      final freshRisk = solver.computeWheelClipRisk(
        bikeHandling: 86.0,
        wPrimeRemainingRatio: 0.50,
      );
      final fatiguedRisk = solver.computeWheelClipRisk(
        bikeHandling: 86.0,
        wPrimeRemainingRatio: 0.05,
      );

      expect(freshRisk, lessThan(0.03));
      expect(fatiguedRisk, greaterThan(0.30));

      final crashResult = solver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: planksSegment,
          bikeHandling: 86.0,
          wPrimeRemainingRatio: 0.04,
          deterministicRoll: 0.05,
        ),
      );

      expect(crashResult.selectedMode, CyclocrossTraversalMode.bunnyHop);
      expect(crashResult.attemptedBunnyHop, isTrue);
      expect(crashResult.wheelClipped, isTrue);
      expect(crashResult.outcome, CyclocrossObstacleOutcome.wheelClippedCrash);
      expect(crashResult.bunnyHopTimeGainSeconds, lessThan(0.0));
      expect(crashResult.timeDeltaVsSaddleSeconds, lessThan(0.0));
    });

    test('solveLap agreguje całą rundę przełajową z belkami, błotem i schodami', () {
      const segments = <CyclocrossCourseSegment>[
        CyclocrossCourseSegment(
          index: 0,
          startMeter: 0.0,
          lengthMeters: 500.0,
          terrainType: CyclocrossTerrainType.meadowGrass,
        ),
        CyclocrossCourseSegment(
          index: 1,
          startMeter: 500.0,
          lengthMeters: 100.0,
          terrainType: CyclocrossTerrainType.deepMud,
          mudDepthCm: 17.0,
          mudViscosityIndex: 0.8,
        ),
        CyclocrossCourseSegment(
          index: 2,
          startMeter: 600.0,
          lengthMeters: 30.0,
          terrainType: CyclocrossTerrainType.staircaseRunUp,
          gradientPercent: 16.0,
          stairStepCount: 24,
        ),
        CyclocrossCourseSegment(
          index: 3,
          startMeter: 630.0,
          lengthMeters: 30.0,
          terrainType: CyclocrossTerrainType.planks,
          plankCount: 2,
          plankHeightCm: 40.0,
          isBunnyHoppable: true,
        ),
      ];

      final lapSummary = solver.solveLap(
        segments: segments,
        bikeHandling: 90.0,
        runningEfficiency: 85.0,
        wPrimeRemainingRatio: 0.70,
        deterministicRollProvider: (_) => 0.99,
      );

      expect(lapSummary.segmentResults.length, 4);
      expect(lapSummary.dismountCount, 2);
      expect(lapSummary.bunnyHopCount, 1);
      expect(lapSummary.wheelClipCount, 0);
      expect(lapSummary.totalBunnyHopGainSeconds, closeTo(1.8, 0.001));
      expect(lapSummary.totalLapTimeSeconds, greaterThan(0.0));
    });
  });
}
