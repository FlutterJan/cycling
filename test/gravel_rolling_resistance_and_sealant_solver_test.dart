import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/gravel_rolling_resistance_and_sealant_solver.dart';
import 'package:pro_peloton_manager/models/equipment/gravel_bike_and_tire_inserts_model.dart';
import 'package:pro_peloton_manager/models/race/gravel_race_and_surface_model.dart';

void main() {
  const solver = GravelRollingResistanceAndSealantSolver();

  group('GravelRollingResistanceAndSealantSolver — Impedance & Pressure', () {
    test('optimal pressure scales with mass, tire width, and foam inserts', () {
      final raceSetup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final ultraSetup = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();

      final lightRiderOpt = solver.calculateOptimalGravelPressure(
        bikeSetup: raceSetup,
        surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
        riderMassKg: 62.0,
      );
      final heavyRiderOpt = solver.calculateOptimalGravelPressure(
        bikeSetup: raceSetup,
        surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
        riderMassKg: 86.0,
      );
      final ultraRiderOpt = solver.calculateOptimalGravelPressure(
        bikeSetup: ultraSetup,
        surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
        riderMassKg: 72.0,
      );

      expect(heavyRiderOpt.rearBar, greaterThan(lightRiderOpt.rearBar));
      expect(heavyRiderOpt.frontBar, lessThan(heavyRiderOpt.rearBar));
      expect(ultraRiderOpt.rearBar, lessThan(heavyRiderOpt.rearBar));
    });

    test('over-inflation increases impedance loss watts on washboard gravel', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final optimal = solver.calculateOptimalGravelPressure(
        bikeSetup: setup,
        surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
      );

      final atOptimal = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          speedMetersPerSecond: 9.5,
          overrideFrontPressureBar: optimal.frontBar,
          overrideRearPressureBar: optimal.rearBar,
        ),
      );

      final overInflated = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          speedMetersPerSecond: 9.5,
          overrideFrontPressureBar: optimal.frontBar + 1.1,
          overrideRearPressureBar: optimal.rearBar + 1.1,
        ),
      );

      expect(
        overInflated.impedanceLossCrr,
        greaterThan(atOptimal.impedanceLossCrr),
      );
      expect(
        overInflated.impedancePenaltyWatts,
        greaterThan(atOptimal.impedancePenaltyWatts + 8.0),
      );
      expect(
        overInflated.vibrationFatigueIndex,
        greaterThan(atOptimal.vibrationFatigueIndex),
      );
    });

    test('under-inflation without inserts increases pinch-flat risk', () {
      final base = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final noInserts = GravelBikeAndTireInsertsModel(
        id: base.id,
        name: base.name,
        frame: base.frame,
        frontTire: base.frontTire,
        rearTire: base.rearTire,
        frontPressureBar: 1.35,
        rearPressureBar: 1.40,
        tireInserts: const FoamTireInsertSpec.none(),
        tubelessSealant: base.tubelessSealant,
        hydrationPack: base.hydrationPack,
      );

      final withInserts = GravelBikeAndTireInsertsModel(
        id: base.id,
        name: base.name,
        frame: base.frame,
        frontTire: base.frontTire,
        rearTire: base.rearTire,
        frontPressureBar: 1.35,
        rearPressureBar: 1.40,
        tireInserts: const FoamTireInsertSpec.flintGuardEnduro(),
        tubelessSealant: base.tubelessSealant,
        hydrationPack: base.hydrationPack,
      );

      final resNoInserts = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: noInserts,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          speedMetersPerSecond: 8.5,
        ),
      );
      final resWithInserts = solver.solveRollingResistance(
        GravelImpedanceInput(
          bikeSetup: withInserts,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          speedMetersPerSecond: 8.5,
        ),
      );

      expect(
        resNoInserts.pinchFlatRiskPerHour,
        greaterThan(resWithInserts.pinchFlatRiskPerHour * 4.0),
      );
    });
  });

  group('GravelRollingResistanceAndSealantSolver — Tubeless Sealant', () {
    test('small tread puncture self-seals in motion with 0s time loss', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final result = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          punctureSizeMm: 2.8,
          isFrontWheel: false,
          currentTirePressureBar: 2.40,
          deterministicRoll01: 0.20,
        ),
      );

      expect(result.resolved, isTrue);
      expect(result.selfSealedWithoutStopping, isTrue);
      expect(result.strategy, GravelSealantRepairStrategy.selfSealedInMotion);
      expect(result.timeLostSeconds, 0.0);
      expect(result.sealantConsumedMl, greaterThan(10.0));
      expect(result.pressureAfterEventBar, lessThan(2.40));
      expect(
        result.updatedBikeSetup.tubelessSealant.remainingVolumeMlRear,
        lessThan(setup.tubelessSealant.remainingVolumeMlRear),
      );
    });

    test('large tread gash escalates to tubeless plug and CO2 cartridge', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final result = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          punctureSizeMm: 8.2,
          isFrontWheel: true,
          currentTirePressureBar: 2.35,
          deterministicRoll01: 0.15,
          availableCo2Cartridges: 2,
          availableTubelessPlugs: 4,
        ),
      );

      expect(result.resolved, isTrue);
      expect(result.selfSealedWithoutStopping, isFalse);
      expect(result.strategy, GravelSealantRepairStrategy.tubelessPlugAndCo2);
      expect(result.plugsUsed, 1);
      expect(result.co2CartridgesUsed, 1);
      expect(result.timeLostSeconds, greaterThan(30.0));
    });

    test('sidewall tear with foam insert and no tube triggers run-flat mode', () {
      final setup = GravelBikeAndTireInsertsModel.flintHillsUltraPreset();
      final result = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: setup,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          punctureSizeMm: 10.5,
          isFrontWheel: false,
          isSidewallCut: true,
          currentTirePressureBar: 2.20,
          deterministicRoll01: 0.90,
          availableCo2Cartridges: 0,
          availableTubelessPlugs: 0,
          hasSpareInnerTube: false,
        ),
      );

      expect(result.resolved, isTrue);
      expect(result.strategy, GravelSealantRepairStrategy.runFlatOnFoamInsert);
      expect(result.runFlatActive, isTrue);
      expect(result.postEventRollingPenaltyWatts, greaterThan(20.0));
    });

    test('sidewall tear without inserts falls back to spare inner tube', () {
      final base = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final noInserts = GravelBikeAndTireInsertsModel(
        id: base.id,
        name: base.name,
        frame: base.frame,
        frontTire: base.frontTire,
        rearTire: base.rearTire,
        frontPressureBar: base.frontPressureBar,
        rearPressureBar: base.rearPressureBar,
        tireInserts: const FoamTireInsertSpec.none(),
        tubelessSealant: base.tubelessSealant,
        hydrationPack: base.hydrationPack,
      );

      final result = solver.resolvePunctureAndSealant(
        GravelPunctureEventInput(
          bikeSetup: noInserts,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
          punctureSizeMm: 11.0,
          isFrontWheel: false,
          isSidewallCut: true,
          currentTirePressureBar: 2.40,
          deterministicRoll01: 0.85,
          hasSpareInnerTube: true,
        ),
      );

      expect(result.resolved, isTrue);
      expect(result.strategy, GravelSealantRepairStrategy.spareTubeInstall);
      expect(result.spareTubeUsed, isTrue);
      expect(result.timeLostSeconds, greaterThan(120.0));
    });

    test('stage physics simulation aggregates segments and evaporates sealant', () {
      final setup = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
      final segments = [
        const GravelCourseSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 40.0,
          surfaceCategory: GravelSurfaceCategory.cat1ChampagneGravel,
        ),
        const GravelCourseSegment(
          index: 1,
          startKm: 40.0,
          lengthKm: 65.0,
          surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
          gradientPercent: 2.5,
        ),
        const GravelCourseSegment(
          index: 2,
          startKm: 105.0,
          lengthKm: 35.0,
          surfaceCategory: GravelSurfaceCategory.cat4SharpFlintAndChunkyRock,
        ),
      ];

      final summary = solver.simulateStagePhysics(
        bikeSetup: setup,
        segments: segments,
        ambientTempC: 32.0,
      );

      expect(summary.totalDistanceKm, closeTo(140.0, 0.01));
      expect(summary.averageEffectiveCrr, greaterThan(0.005));
      expect(summary.averageRollingWatts, greaterThan(20.0));
      expect(summary.expectedPuncturesCount, greaterThan(0.0));
      expect(
        summary.sealantRemainingFrontMl,
        lessThan(setup.tubelessSealant.remainingVolumeMlFront),
      );
    });
  });
}
