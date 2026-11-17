import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/cx_pit_bike_exchange_mechanics.dart';
import 'package:pro_peloton_manager/engine/physics/cyclocross_bunnyhop_and_carry_solver.dart';
import 'package:pro_peloton_manager/models/race/cyclocross_course_and_mud_model.dart';

void main() {
  const pitMechanics = CxPitBikeExchangeMechanics();
  const cxSolver = CyclocrossBunnyhopAndCarrySolver();

  group('Fizyka przyrostu masy błota na rowerze przełajowym (CX)', () {
    test('przyrost błota w ciężkim błocie mieści się w zakresie 0.4–1.8 kg/km i generuje +12 W/km oporu napędu', () {
      final minRate = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 0.0,
        mudViscosityIndex: 0.0,
      );
      final midRate = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 12.5,
        mudViscosityIndex: 0.5,
      );
      final maxRate = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 25.0,
        mudViscosityIndex: 1.0,
      );

      expect(minRate, closeTo(0.4, 1e-6));
      expect(midRate, greaterThan(0.4));
      expect(midRate, lessThan(1.8));
      expect(maxRate, closeTo(1.8, 1e-6));

      final dragRate = pitMechanics.computeDrivetrainDragRateWattsPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
      );
      expect(dragRate, closeTo(12.0, 1e-6));

      final pavedRate = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.pavedStartFinish,
      );
      final pavedDrag = pitMechanics.computeDrivetrainDragRateWattsPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.pavedStartFinish,
      );
      expect(pavedRate, 0.0);
      expect(pavedDrag, 0.0);
    });

    test('jazda 1.5 km w ciężkim błocie zwiększa masę roweru oraz opory napędu i respektuje limit fizyczny 6.5 kg', () {
      var state = pitMechanics.createInitialState(
        riderId: 'cx_rider_1',
        baseBikeWeightKg: 7.9,
      );

      const mudSegment = CyclocrossCourseSegment(
        index: 1,
        startMeter: 200.0,
        lengthMeters: 1500.0,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 15.0,
        mudViscosityIndex: 0.75,
      );

      final step1 = pitMechanics.step(
        state: state,
        dtSeconds: 270.0,
        distanceMeters: 1500.0,
        mudCondition: CyclocrossMudCondition.heavyMud,
        segment: mudSegment,
      );

      expect(step1.mudAddedKg, greaterThanOrEqualTo(0.4 * 1.5 - 1e-6));
      expect(step1.mudAddedKg, lessThanOrEqualTo(1.8 * 1.5 + 1e-6));
      expect(step1.drivetrainDragAddedWatts, closeTo(18.0, 1e-6));
      expect(
        step1.state.currentBikeWeightKg,
        closeTo(7.9 + step1.state.accumulatedMudKg, 1e-6),
      );
      expect(step1.state.heavyMudDistanceOnCurrentBikeKm, closeTo(1.5, 1e-6));

      // Wielokilometrowy przejazd nie może przekroczyć limitu 6.5 kg błota na ramie/kołach.
      state = step1.state;
      for (var i = 0; i < 6; i++) {
        state = pitMechanics
            .step(
              state: state,
              dtSeconds: 200.0,
              distanceMeters: 1500.0,
              mudCondition: CyclocrossMudCondition.boggySwamp,
              segment: mudSegment,
            )
            .state;
      }

      expect(
        state.accumulatedMudKg,
        closeTo(CxPitBikeExchangeMechanics.maxPhysicalMudCapKg, 1e-6),
      );
      expect(state.currentBikeWeightKg, closeTo(7.9 + 6.5, 1e-6));
    });

    test('przyrost błota rośnie monotonicznie wraz z warunkami od frozenHard do boggySwamp', () {
      final frozen = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.frozenHard,
        terrainType: CyclocrossTerrainType.deepMud,
      );
      final tacky = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.tackyLoam,
        terrainType: CyclocrossTerrainType.deepMud,
      );
      final heavy = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.heavyMud,
        terrainType: CyclocrossTerrainType.deepMud,
      );
      final swamp = pitMechanics.computeMudAccumulationRateKgPerKm(
        mudCondition: CyclocrossMudCondition.boggySwamp,
        terrainType: CyclocrossTerrainType.deepMud,
      );

      expect(frozen, lessThan(tacky));
      expect(tacky, lessThan(heavy));
      expect(heavy, lessThanOrEqualTo(swamp));
    });
  });

  group('Decyzja Dismount & Run vs jazda w siodle oraz Bunny-Hop', () {
    test('w głębokim błocie i na schodach solver wybiera Dismount & Run z rowerem na ramieniu', () {
      const deepMudSegment = CyclocrossCourseSegment(
        index: 2,
        startMeter: 400.0,
        lengthMeters: 120.0,
        terrainType: CyclocrossTerrainType.deepMud,
        gradientPercent: 4.0,
        mudDepthCm: 18.0,
        mudViscosityIndex: 0.85,
      );

      final mudResult = cxSolver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: deepMudSegment,
          mudCondition: CyclocrossMudCondition.heavyMud,
          powerWatts: 340.0,
          bikeHandling: 80.0,
          runningEfficiency: 85.0,
          wPrimeRemainingRatio: 0.85,
        ),
      );

      expect(mudResult.selectedMode, CyclocrossTraversalMode.dismountAndRun);
      expect(mudResult.carryTechnique, CyclocrossCarryTechnique.shoulderCarry);
      expect(mudResult.outcome, CyclocrossObstacleOutcome.cleanRunCarry);
      expect(mudResult.dismountRunSpeedKmh, inInclusiveRange(9.0, 16.5));
      expect(mudResult.segmentTimeSeconds, lessThan(mudResult.mountedTimeSeconds));
      expect(mudResult.timeDeltaVsSaddleSeconds, greaterThan(0.0));

      const stairsSegment = CyclocrossCourseSegment(
        index: 3,
        startMeter: 800.0,
        lengthMeters: 45.0,
        terrainType: CyclocrossTerrainType.staircaseRunUp,
        gradientPercent: 18.0,
        stairStepCount: 32,
      );

      final stairsResult = cxSolver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: stairsSegment,
          runningEfficiency: 80.0,
        ),
      );

      expect(stairsResult.selectedMode, CyclocrossTraversalMode.dismountAndRun);
      expect(stairsResult.carryTechnique, CyclocrossCarryTechnique.shoulderCarry);
      expect(stairsResult.segmentTimeSeconds, lessThan(stairsResult.mountedTimeSeconds));
    });

    test('na szybkim odcinku trawiastym lub asfalcie solver utrzymuje jazdę w siodle', () {
      const grassSegment = CyclocrossCourseSegment(
        index: 0,
        startMeter: 0.0,
        lengthMeters: 300.0,
        terrainType: CyclocrossTerrainType.meadowGrass,
        gradientPercent: 0.0,
      );

      final result = cxSolver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: grassSegment,
          mudCondition: CyclocrossMudCondition.tackyLoam,
          powerWatts: 380.0,
          runningEfficiency: 75.0,
        ),
      );

      expect(result.selectedMode, CyclocrossTraversalMode.rideInSaddle);
      expect(result.carryTechnique, isNull);
      expect(result.outcome, CyclocrossObstacleOutcome.cleanRide);
      expect(result.mountedSpeedKmh, greaterThan(result.dismountRunSpeedKmh));
    });

    test('przed belkami kolarz z bikeHandling >= 85 wykonuje Bunny-Hop z zyskiem 1.8 s, a poniżej 85 zsiada', () {
      const planksSegment = CyclocrossCourseSegment(
        index: 4,
        startMeter: 1500.0,
        lengthMeters: 25.0,
        terrainType: CyclocrossTerrainType.planks,
        plankCount: 2,
        plankHeightCm: 40.0,
        isBunnyHoppable: true,
      );

      final proResult = cxSolver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: planksSegment,
          bikeHandling: 90.0,
          wPrimeRemainingRatio: 0.70,
          deterministicRoll: 0.99,
        ),
      );

      expect(proResult.selectedMode, CyclocrossTraversalMode.bunnyHop);
      expect(proResult.outcome, CyclocrossObstacleOutcome.cleanBunnyHop);
      expect(proResult.attemptedBunnyHop, isTrue);
      expect(proResult.wheelClipped, isFalse);
      expect(proResult.bunnyHopTimeGainSeconds, closeTo(1.8, 1e-6));

      final amateurResult = cxSolver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: planksSegment,
          bikeHandling: 78.0,
          wPrimeRemainingRatio: 0.70,
        ),
      );

      expect(amateurResult.selectedMode, CyclocrossTraversalMode.dismountAndRun);
      expect(amateurResult.attemptedBunnyHop, isFalse);
      expect(amateurResult.bunnyHopTimeGainSeconds, 0.0);
    });

    test('zmęczenie W\' < 15% drastycznie zwiększa ryzyko zahaczenia kołem o belkę podczas Bunny-Hop', () {
      const planksSegment = CyclocrossCourseSegment(
        index: 5,
        startMeter: 1800.0,
        lengthMeters: 25.0,
        terrainType: CyclocrossTerrainType.planks,
        plankCount: 2,
        plankHeightCm: 40.0,
        isBunnyHoppable: true,
      );

      final freshRisk = cxSolver.computeWheelClipRisk(
        bikeHandling: 88.0,
        wPrimeRemainingRatio: 0.65,
      );
      final fatiguedRisk = cxSolver.computeWheelClipRisk(
        bikeHandling: 88.0,
        wPrimeRemainingRatio: 0.08,
      );

      expect(freshRisk, lessThan(0.03));
      expect(fatiguedRisk, greaterThan(0.20));

      final crashResult = cxSolver.solveSegment(
        const CyclocrossBunnyhopAndCarryInput(
          segment: planksSegment,
          bikeHandling: 88.0,
          wPrimeRemainingRatio: 0.08,
          deterministicRoll: 0.05,
        ),
      );

      expect(crashResult.selectedMode, CyclocrossTraversalMode.bunnyHop);
      expect(crashResult.attemptedBunnyHop, isTrue);
      expect(crashResult.wheelClipped, isTrue);
      expect(crashResult.outcome, CyclocrossObstacleOutcome.wheelClippedCrash);
      expect(crashResult.bunnyHopTimeGainSeconds, lessThan(0.0));
    });
  });

  group('Wymiana roweru w boksie technicznym (Pit Lane) i zysk czasowy', () {
    test('kolejkowanie zjazdu i 4.5-sekundowa wymiana w Pit Lane oddaje czysty rower o wadze bazowej', () {
      const pitConfig = DoublePitLaneConfig(
        pitSide: CyclocrossPitLaneSide.centerIsland,
        firstAccessStartMeter: 1100.0,
        firstAccessLengthMeters: 150.0,
        secondAccessStartMeter: 2400.0,
        secondAccessLengthMeters: 150.0,
        pressureWashEfficiency: 1.0,
      );

      var state = pitMechanics.createInitialState(
        riderId: 'van_der_cx',
        baseBikeWeightKg: 7.9,
      );

      // Oblepienie roweru na 2 km ciężkiego błota.
      const mudSegment = CyclocrossCourseSegment(
        index: 1,
        startMeter: 200.0,
        lengthMeters: 1000.0,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 16.0,
        mudViscosityIndex: 0.85,
      );
      state = pitMechanics
          .step(
            state: state,
            dtSeconds: 360.0,
            distanceMeters: 2000.0,
            mudCondition: CyclocrossMudCondition.heavyMud,
            segment: mudSegment,
          )
          .state;

      expect(state.accumulatedMudKg, greaterThan(2.0));
      expect(state.drivetrainDragWatts, closeTo(24.0, 1e-6));
      expect(state.activeBikeSlot, CxBikeSlot.bikeA);

      // Zakolejkowanie zjazdu i wjazd do strefy Pit Lane.
      state = pitMechanics.queuePitExchange(state);
      expect(state.status, CxPitExchangeStatus.pitQueued);

      final enterStep = pitMechanics.step(
        state: state,
        dtSeconds: 2.0,
        distanceMeters: 20.0,
        pitLaneConfig: pitConfig,
        lapDistanceMeters: 1150.0,
      );

      expect(enterStep.enteredPitLane, isTrue);
      expect(enterStep.completedBikeExchange, isFalse);
      expect(enterStep.state.status, CxPitExchangeStatus.inPitLane);
      expect(enterStep.state.pitRemainingSeconds, closeTo(2.5, 1e-6));

      // Dokończenie pozostałych 2.5 s postoju (łącznie 4.5 s).
      final exitStep = pitMechanics.step(
        state: enterStep.state,
        dtSeconds: 2.5,
        distanceMeters: 0.0,
        pitLaneConfig: pitConfig,
        lapDistanceMeters: 1160.0,
      );

      expect(exitStep.completedBikeExchange, isTrue);
      expect(exitStep.state.status, CxPitExchangeStatus.onCourse);
      expect(exitStep.state.activeBikeSlot, CxBikeSlot.bikeB);
      expect(exitStep.state.accumulatedMudKg, 0.0);
      expect(exitStep.state.drivetrainDragWatts, 0.0);
      expect(exitStep.state.currentBikeWeightKg, closeTo(7.9, 1e-6));
      expect(exitStep.state.totalPitTimeSeconds, closeTo(4.5, 1e-6));
      expect(exitStep.state.exchangeCount, 1);
      expect(exitStep.state.isSpareBikeClean, isFalse);
      expect(exitStep.state.spareBikeWashRemainingSeconds, greaterThan(0.0));
    });

    test('wymiana oblepionego błotem roweru w boksie przynosi realny zysk czasowy na kolejnych kilometrach', () {
      var state = pitMechanics.createInitialState(
        riderId: 'pidcock_cx',
        baseBikeWeightKg: 7.9,
      );

      // 2.5 km w ciężkim błocie daje ~3.0–4.0 kg błota i +30 W oporu napędu.
      const mudSegment = CyclocrossCourseSegment(
        index: 1,
        startMeter: 200.0,
        lengthMeters: 1000.0,
        terrainType: CyclocrossTerrainType.deepMud,
        mudDepthCm: 16.0,
        mudViscosityIndex: 0.85,
      );

      final dirtyStep = pitMechanics.step(
        state: state,
        dtSeconds: 450.0,
        distanceMeters: 2500.0,
        mudCondition: CyclocrossMudCondition.heavyMud,
        segment: mudSegment,
      );
      final dirtyState = dirtyStep.state;

      // Ocena taktyczna na pozostałe 6 km wyścigu: zjazd 4.5 s wyraźnie się opłaca.
      final dirtyEval = pitMechanics.evaluatePitExchangeRecommendation(
        state: dirtyState,
        remainingRaceDistanceKm: 6.0,
        riderPowerWatts: 360.0,
      );
      expect(dirtyEval.recommendation, CxPitRecommendation.pitNow);
      expect(dirtyEval.pitStopCostSeconds, closeTo(4.5, 1e-6));
      expect(dirtyEval.estimatedTimeSavedSeconds, greaterThan(10.0));

      // Weryfikacja bezpośrednia w fizyce jazdy: porównanie 2 rund (6 km) na brudnym rowerze
      // vs 4.5 s postoju w boksie + 2 rundy na czystym rowerze (bez błota i strat napędu).
      const lapSegments = <CyclocrossCourseSegment>[
        CyclocrossCourseSegment(
          index: 0,
          startMeter: 0.0,
          lengthMeters: 1200.0,
          terrainType: CyclocrossTerrainType.meadowGrass,
          gradientPercent: 2.0,
        ),
        CyclocrossCourseSegment(
          index: 1,
          startMeter: 1200.0,
          lengthMeters: 900.0,
          terrainType: CyclocrossTerrainType.deepMud,
          gradientPercent: 3.0,
          mudDepthCm: 10.0,
          mudViscosityIndex: 0.65,
        ),
        CyclocrossCourseSegment(
          index: 2,
          startMeter: 2100.0,
          lengthMeters: 900.0,
          terrainType: CyclocrossTerrainType.offCamberSlope,
          gradientPercent: 4.0,
          camberAngleDegrees: 18.0,
        ),
      ];

      final dirtyPower = (360.0 - dirtyState.drivetrainDragWatts).clamp(180.0, 360.0);
      final dirtyLap = cxSolver.solveLap(
        segments: lapSegments,
        mudCondition: CyclocrossMudCondition.heavyMud,
        bikeMassKg: dirtyState.baseBikeWeightKg,
        mudAdhesionKg: dirtyState.accumulatedMudKg,
        powerWatts: dirtyPower,
        bikeHandling: 86.0,
      );

      final cleanLap = cxSolver.solveLap(
        segments: lapSegments,
        mudCondition: CyclocrossMudCondition.heavyMud,
        bikeMassKg: dirtyState.baseBikeWeightKg,
        mudAdhesionKg: 0.0,
        powerWatts: 360.0,
        bikeHandling: 86.0,
      );

      final twoDirtyLapsSeconds = dirtyLap.totalLapTimeSeconds * 2.0;
      final pitPlusTwoCleanLapsSeconds =
          CxPitBikeExchangeMechanics.pitLaneExchangeDurationSeconds +
              (cleanLap.totalLapTimeSeconds * 2.0);

      expect(cleanLap.totalLapTimeSeconds, lessThan(dirtyLap.totalLapTimeSeconds));
      expect(pitPlusTwoCleanLapsSeconds, lessThan(twoDirtyLapsSeconds));

      // Dla czystego roweru po wyjściu z boksu rekomendacja to stayOut.
      final postPitState = pitMechanics
          .step(
            state: pitMechanics.enterPitLane(state: dirtyState),
            dtSeconds: CxPitBikeExchangeMechanics.pitLaneExchangeDurationSeconds,
          )
          .state;
      final cleanEval = pitMechanics.evaluatePitExchangeRecommendation(
        state: postPitState,
        remainingRaceDistanceKm: 6.0,
        riderPowerWatts: 360.0,
      );
      expect(cleanEval.recommendation, CxPitRecommendation.stayOut);
    });
  });
}
