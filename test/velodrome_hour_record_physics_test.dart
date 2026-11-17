import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/constants/physics_constants.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_banking_and_centripetal_solver.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';

void main() {
  group('Velodrome 42° banking & centripetal G-force physics', () {
    const VelodromeFacilitySpec grenchen42 = VelodromeFacilitySpec(
      id: 'grenchen_tissot',
      name: 'Tissot Velodrome Grenchen',
      city: 'Grenchen',
      countryCode: 'SUI',
      trackLengthMeters: 250.0,
      turnBankingDegrees: 42.0,
      straightBankingDegrees: 12.5,
      altitudeMeters: 450.0,
      woodSurface: VelodromeWoodSurface.siberianPine,
      isIndoor: true,
      indoorTemperatureCelsius: 25.0,
      relativeHumidityPercent: 45.0,
      turnRadiusMeters: 23.0,
    );

    const FixedGearTrackBike trackBike =
        VelodromeTrackAndHourRecordModel.defaultTrackBike;

    test('computes centripetal acceleration a_c = v^2 / R and 42° G-force load', () {
      const double speedMs = 15.80; // ~56.88 km/h (Hour Record pace)
      const double riderMassKg = 74.0;

      final double expectedAc = (speedMs * speedMs) / grenchen42.turnRadiusMeters;
      expect(
        VelodromeBankingAndCentripetalSolver.computeCentripetalAcceleration(
          speedMs: speedMs,
          radiusMeters: grenchen42.turnRadiusMeters,
        ),
        closeTo(expectedAc, 1e-9),
      );

      final VelodromeBankingPhysicsResult turnResult =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchen42,
          bike: trackBike,
          riderMassKg: riderMassKg,
          speedMs: speedMs,
          section: VelodromeTrackSection.turnApex,
          metersAboveBlackLine: 0.0,
        ),
      );

      const double g = PhysicsConstants.gravity;
      const double bankRad = 42.0 * math.pi / 180.0;
      final double expectedRawG =
          (g * math.cos(bankRad) + expectedAc * math.sin(bankRad)) / g;

      expect(turnResult.localBankingDegrees, 42.0);
      expect(turnResult.effectiveTurnRadiusMeters, 23.0);
      expect(turnResult.centripetalAccelerationMs2, closeTo(expectedAc, 1e-6));
      expect(turnResult.rawGForceLoadFactor, closeTo(expectedRawG, 1e-6));
      expect(turnResult.gForceLoadFactor, greaterThan(1.4));
      expect(turnResult.gForceLoadFactor, lessThanOrEqualTo(1.8));
      expect(
        turnResult.effectiveMassKg,
        closeTo(turnResult.totalMassKg * turnResult.gForceLoadFactor, 1e-6),
      );
      expect(
        grenchen42.bankingNormalLoadFactor(speedMs),
        closeTo(expectedRawG, 1e-6),
      );
    });

    test('42° turn increases effective mass and rolling resistance vs straight', () {
      const double speedMs = 15.80;
      const double riderMassKg = 74.0;

      final VelodromeBankingPhysicsResult straightResult =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchen42,
          bike: trackBike,
          riderMassKg: riderMassKg,
          speedMs: speedMs,
          section: VelodromeTrackSection.straight,
        ),
      );

      final VelodromeBankingPhysicsResult turnResult =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchen42,
          bike: trackBike,
          riderMassKg: riderMassKg,
          speedMs: speedMs,
          section: VelodromeTrackSection.turnApex,
        ),
      );

      expect(straightResult.centripetalAccelerationMs2, 0.0);
      expect(straightResult.centripetalForceNewtons, 0.0);
      expect(straightResult.gForceLoadFactor, closeTo(math.cos(12.5 * math.pi / 180.0), 1e-6));

      expect(turnResult.effectiveMassKg, greaterThan(straightResult.effectiveMassKg));
      expect(
        turnResult.rollingResistanceForceNewtons,
        greaterThan(straightResult.rollingResistanceForceNewtons * 1.4),
      );
      expect(turnResult.rollingResistanceIncreasePercent, greaterThan(40.0));
      expect(turnResult.isAboveMinimumTurnSpeed, isTrue);
    });

    test('clamps extreme sprint speed G-force to maxVelodromeGForce (1.80G)', () {
      final VelodromeBankingPhysicsResult sprintTurn =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchen42,
          bike: trackBike,
          riderMassKg: 78.0,
          speedMs: 21.5, // ~77.4 km/h keirin/flying sprint
          section: VelodromeTrackSection.turnApex,
        ),
      );

      expect(sprintTurn.rawGForceLoadFactor, greaterThan(1.80));
      expect(sprintTurn.gForceLoadFactor, 1.80);
      expect(sprintTurn.effectiveMassKg, closeTo(sprintTurn.totalMassKg * 1.80, 1e-6));
    });

    test('riding above black measurement line increases lap distance and time penalty', () {
      expect(
        VelodromeBankingAndCentripetalSolver.computeEffectiveLapLengthMeters(0.0),
        250.0,
      );
      expect(
        VelodromeBankingAndCentripetalSolver.computeEffectiveLapLengthMeters(3.20),
        258.5,
      );
      expect(
        VelodromeBankingAndCentripetalSolver.computeEffectiveLapLengthMeters(5.0),
        258.5,
      );

      final VelodromeBankingPhysicsResult upperLine =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchen42,
          bike: trackBike,
          riderMassKg: 74.0,
          speedMs: 15.80,
          section: VelodromeTrackSection.turnApex,
          metersAboveBlackLine: 3.20,
        ),
      );

      expect(upperLine.effectiveLapLengthMeters, closeTo(258.5, 1e-6));
      expect(upperLine.blackLinePenaltyMetersPerLap, closeTo(8.5, 1e-6));
      expect(
        upperLine.blackLineTimePenaltySecondsPerLap,
        closeTo(8.5 / 15.80, 1e-4),
      );
    });
  });

  group('Velodrome altitude effect on air density rho and hypoxia', () {
    test('higher altitude lowers barometric pressure and air density rho', () {
      const List<VelodromeFacilitySpec> velodromes =
          VelodromeTrackAndHourRecordModel.defaultVelodromes;
      final VelodromeFacilitySpec london = velodromes.firstWhere(
        (v) => v.id == 'london_lee_valley',
      ); // 12 m
      final VelodromeFacilitySpec grenchen = velodromes.firstWhere(
        (v) => v.id == 'grenchen_tissot',
      ); // 450 m
      final VelodromeFacilitySpec aguascalientes = velodromes.firstWhere(
        (v) => v.id == 'aguascalientes_bicentenario',
      ); // 1880 m

      expect(
        london.localBarometricPressureHpa,
        greaterThan(grenchen.localBarometricPressureHpa),
      );
      expect(
        grenchen.localBarometricPressureHpa,
        greaterThan(aguascalientes.localBarometricPressureHpa),
      );

      expect(london.airDensityKgPerM3, inInclusiveRange(1.13, 1.22));
      expect(grenchen.airDensityKgPerM3, inInclusiveRange(1.08, 1.16));
      expect(aguascalientes.airDensityKgPerM3, inInclusiveRange(0.90, 0.99));

      expect(london.airDensityKgPerM3, greaterThan(grenchen.airDensityKgPerM3));
      expect(
        grenchen.airDensityKgPerM3,
        greaterThan(aguascalientes.airDensityKgPerM3),
      );

      expect(
        aguascalientes.aeroDragReductionPercentVsSeaLevel,
        greaterThan(18.0),
      );
      expect(
        aguascalientes.aeroDragReductionPercentVsSeaLevel,
        greaterThan(grenchen.aeroDragReductionPercentVsSeaLevel),
      );
    });

    test('pure altitude comparison with identical indoor climate isolates rho drop', () {
      const VelodromeFacilitySpec seaLevel = VelodromeFacilitySpec(
        id: 'sea',
        name: 'Sea Level Arena',
        city: 'City',
        countryCode: 'POL',
        altitudeMeters: 0.0,
        indoorTemperatureCelsius: 25.0,
        relativeHumidityPercent: 45.0,
      );
      final VelodromeFacilitySpec highAlt = seaLevel.copyWith(
        id: 'high',
        altitudeMeters: 1880.0,
      );

      final double rhoSea = seaLevel.airDensityKgPerM3;
      final double rhoHigh = highAlt.airDensityKgPerM3;
      final double ratio = rhoHigh / rhoSea;

      expect(rhoSea, closeTo(1.17, 0.02));
      expect(rhoHigh, closeTo(0.935, 0.02));
      expect(ratio, closeTo(0.80, 0.03));

      final VelodromeBankingPhysicsResult resSea =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: seaLevel,
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          riderMassKg: 74.0,
          speedMs: 15.80,
          section: VelodromeTrackSection.turnApex,
        ),
      );
      final VelodromeBankingPhysicsResult resHigh =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        VelodromePhysicsInput(
          facility: highAlt,
          bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
          riderMassKg: 74.0,
          speedMs: 15.80,
          section: VelodromeTrackSection.turnApex,
        ),
      );

      expect(
        resHigh.aerodynamicDragForceNewtons / resSea.aerodynamicDragForceNewtons,
        closeTo(ratio, 1e-6),
      );
      expect(
        resHigh.requiredRiderPowerWatts,
        lessThan(resSea.requiredRiderPowerWatts),
      );
    });

    test('hypoxia power penalty is 1.0 below 600 m and drops at 1880 m', () {
      final VelodromeFacilitySpec grenchen =
          VelodromeTrackAndHourRecordModel.defaultVelodromes.firstWhere(
        (v) => v.id == 'grenchen_tissot',
      );
      final VelodromeFacilitySpec aguascalientes =
          VelodromeTrackAndHourRecordModel.defaultVelodromes.firstWhere(
        (v) => v.id == 'aguascalientes_bicentenario',
      );

      expect(grenchen.hypoxiaPowerPenaltyFactor, 1.0);
      expect(aguascalientes.hypoxiaPowerPenaltyFactor, lessThan(0.92));
      expect(aguascalientes.hypoxiaPowerPenaltyFactor, greaterThanOrEqualTo(0.70));
    });
  });

  group('60-minute UCI Hour Record distance simulation', () {
    test('simulates 227+ consecutive laps at 15.80 s pace exceeding 56 km', () {
      final VelodromeTrackAndHourRecordModel model =
          VelodromeTrackAndHourRecordModel.standard(
        initialVelodromeId: 'grenchen_tissot',
      );

      final HourRecordPacingSimulationResult sim =
          VelodromeBankingAndCentripetalSolver.simulateHourRecordPacing(
        facility: model.activeVelodrome,
        bike: model.trackBike,
        riderMassKg: 78.0,
        riderFtpWatts: 510.0,
        riderWPrimeJoules: 28000.0,
        targetLapTimeSeconds: 15.80,
        paceToleranceSeconds: 0.10,
        lineDisciplineSkill: 100.0,
        pacingPrecisionSkill: 100.0,
        includeStandingStartLap: false,
      );

      expect(sim.heldTargetPaceFor227Laps, isTrue);
      expect(sim.maxConsecutiveOnPaceLaps, greaterThanOrEqualTo(227));
      expect(sim.completedFullLaps, greaterThanOrEqualTo(227));
      expect(sim.totalDistanceKm, inInclusiveRange(56.5, 57.5));
      expect(sim.steadyStateAverageLapTimeSeconds, closeTo(15.80, 0.02));
      expect(sim.averageSpeedKmh, inInclusiveRange(56.5, 57.5));
      expect(sim.peakCentripetalGForce, greaterThan(1.4));
      expect(sim.peakCentripetalGForce, lessThanOrEqualTo(1.8));
      expect(sim.totalBlackLinePenaltyMeters, closeTo(0.0, 1e-6));
      expect(sim.laps.last.elapsedTimeSeconds, lessThanOrEqualTo(3600.0));
      expect(sim.laps.last.cumulativeDistanceMeters, lessThanOrEqualTo(sim.totalDistanceMeters));
    });

    test('insufficient FTP and depleted W\' causes pace drop and shorter 60-min distance', () {
      final VelodromeFacilitySpec grenchen =
          VelodromeTrackAndHourRecordModel.defaultVelodromes.firstWhere(
        (v) => v.id == 'grenchen_tissot',
      );

      final HourRecordPacingSimulationResult underpowered =
          VelodromeBankingAndCentripetalSolver.simulateHourRecordPacing(
        facility: grenchen,
        bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
        riderMassKg: 74.0,
        riderFtpWatts: 360.0,
        riderWPrimeJoules: 15000.0,
        targetLapTimeSeconds: 15.80,
        lineDisciplineSkill: 96.0,
        pacingPrecisionSkill: 96.0,
      );

      expect(underpowered.heldTargetPaceFor227Laps, isFalse);
      expect(underpowered.totalDistanceKm, lessThan(55.0));
      expect(underpowered.totalDistanceKm, greaterThan(45.0));
      expect(underpowered.laps.last.remainingWPrimeJoules, closeTo(0.0, 1e-3));
      expect(underpowered.laps.last.lapTimeSeconds, greaterThan(15.90));
    });

    test('model simulateHourRecordAttempt reflects altitude air density and acclimatization', () {
      final VelodromeTrackAndHourRecordModel model =
          VelodromeTrackAndHourRecordModel.standard(
        initialVelodromeId: 'london_lee_valley',
      );
      final VelodromeFacilitySpec london = model.availableVelodromes.firstWhere(
        (v) => v.id == 'london_lee_valley',
      );
      final VelodromeFacilitySpec aguascalientes =
          model.availableVelodromes.firstWhere(
        (v) => v.id == 'aguascalientes_bicentenario',
      );

      final HourRecordAttemptSimulation londonAttempt =
          model.simulateHourRecordAttempt(
        sustainableHourPowerWatts: 460.0,
        riderMassKg: 74.0,
        velodromeOverride: london,
      );

      final HourRecordAttemptSimulation unacclimatizedHighAlt =
          model.simulateHourRecordAttempt(
        sustainableHourPowerWatts: 460.0,
        riderMassKg: 74.0,
        altitudeAcclimatizationBonus: 0.0,
        velodromeOverride: aguascalientes,
      );

      final HourRecordAttemptSimulation acclimatizedHighAlt =
          model.simulateHourRecordAttempt(
        sustainableHourPowerWatts: 460.0,
        riderMassKg: 74.0,
        altitudeAcclimatizationBonus: 0.7,
        velodromeOverride: aguascalientes,
      );

      expect(
        londonAttempt.airDensityKgPerM3,
        greaterThan(unacclimatizedHighAlt.airDensityKgPerM3),
      );
      expect(
        acclimatizedHighAlt.effectivePowerWatts,
        greaterThan(unacclimatizedHighAlt.effectivePowerWatts),
      );
      expect(
        acclimatizedHighAlt.predictedDistanceKm,
        greaterThan(unacclimatizedHighAlt.predictedDistanceKm),
      );
      expect(
        acclimatizedHighAlt.predictedDistanceKm,
        greaterThan(londonAttempt.predictedDistanceKm),
      );
      expect(
        acclimatizedHighAlt.predictedLaps,
        closeTo(acclimatizedHighAlt.predictedDistanceKm * 4.0, 1e-6),
      );
    });
  });
}
