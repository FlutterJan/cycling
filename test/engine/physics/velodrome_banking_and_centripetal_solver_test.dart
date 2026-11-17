import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_banking_and_centripetal_solver.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';

void main() {
  const VelodromeFacilitySpec grenchenVelodrome = VelodromeFacilitySpec(
    id: 'grenchen_tissot',
    name: 'Tissot Velodrome',
    city: 'Grenchen',
    countryCode: 'SUI',
    trackLengthMeters: 250.0,
    turnBankingDegrees: 45.0,
    straightBankingDegrees: 13.0,
    altitudeMeters: 451.0,
    woodSurface: VelodromeWoodSurface.siberianSpruce,
    turnRadiusMeters: 23.0,
  );

  const FixedGearTrackBike hourRecordBike = FixedGearTrackBike(
    modelName: 'Bolide F HR 3D',
    chainringTeeth: 64,
    cogTeeth: 14,
    bikeWeightKg: 7.1,
    cdaMetersSquared: 0.172,
    drivetrainEfficiency: 0.986,
  );

  group('VelodromeBankingAndCentripetalSolver', () {
    test('wylicza przyspieszenie odśrodkowe a_c = v^2 / R i podnosi efektywną masę oraz opór toczenia w wirażu', () {
      const double speedMs = 15.8228; // ~56.96 km/h (15.80 s na okrążenie 250 m)
      const double riderMassKg = 80.0;

      final VelodromeBankingPhysicsResult straight =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchenVelodrome,
          bike: hourRecordBike,
          riderMassKg: riderMassKg,
          speedMs: speedMs,
          section: VelodromeTrackSection.straight,
        ),
      );

      final VelodromeBankingPhysicsResult turn =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchenVelodrome,
          bike: hourRecordBike,
          riderMassKg: riderMassKg,
          speedMs: speedMs,
          section: VelodromeTrackSection.turnApex,
        ),
      );

      // a_c = v^2 / R = 15.8228^2 / 23.0 ≈ 10.885 m/s^2
      expect(
        turn.centripetalAccelerationMs2,
        closeTo((speedMs * speedMs) / 23.0, 1e-4),
      );
      expect(straight.centripetalAccelerationMs2, 0.0);

      // Na wirażu 45° przeciążenie G jest znacznie większe niż 1.0G i mieści się w limicie 1.8G.
      expect(turn.gForceLoadFactor, greaterThan(1.40));
      expect(turn.gForceLoadFactor, lessThanOrEqualTo(1.80));
      expect(turn.effectiveMassKg, greaterThan(turn.totalMassKg * 1.40));

      // Opór toczenia w wirażu rośnie proporcjonalnie do efektywnej masy.
      expect(
        turn.rollingResistanceForceNewtons,
        greaterThan(straight.rollingResistanceForceNewtons * 1.45),
      );
      expect(turn.rollingResistanceIncreasePercent, greaterThan(40.0));
    });

    test('ogranicza maksymalne przeciążenie w wirażu do 1.8G przy bardzo dużych prędkościach sprinterskich', () {
      const double sprintSpeedMs = 21.5; // ~77.4 km/h
      final VelodromeBankingPhysicsResult turnSprint =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchenVelodrome,
          bike: hourRecordBike,
          riderMassKg: 82.0,
          speedMs: sprintSpeedMs,
          section: VelodromeTrackSection.turnApex,
        ),
      );

      expect(turnSprint.rawGForceLoadFactor, greaterThan(1.80));
      expect(turnSprint.gForceLoadFactor, equals(1.80));
      expect(
        turnSprint.effectiveMassKg,
        closeTo(turnSprint.totalMassKg * 1.80, 1e-6),
      );
    });

    test('nalicza karę za wyjechanie powyżej czarnej linii pomiarowej (250.0 m -> 258.5 m)', () {
      expect(
        VelodromeBankingAndCentripetalSolver.computeEffectiveLapLengthMeters(0.0),
        equals(250.0),
      );
      expect(
        VelodromeBankingAndCentripetalSolver.computeEffectiveLapLengthMeters(
          VelodromeBankingAndCentripetalSolver.maxLineDeviationMeters,
        ),
        equals(258.5),
      );
      expect(
        VelodromeBankingAndCentripetalSolver.computeEffectiveLapLengthMeters(10.0),
        equals(258.5),
      );

      final VelodromeBankingPhysicsResult blackLine =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchenVelodrome,
          bike: hourRecordBike,
          riderMassKg: 78.0,
          speedMs: 15.82,
          metersAboveBlackLine: 0.0,
        ),
      );

      final VelodromeBankingPhysicsResult highLine =
          VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
        const VelodromePhysicsInput(
          facility: grenchenVelodrome,
          bike: hourRecordBike,
          riderMassKg: 78.0,
          speedMs: 15.82,
          metersAboveBlackLine: 3.20,
        ),
      );

      expect(blackLine.blackLinePenaltyMetersPerLap, 0.0);
      expect(blackLine.blackLineTimePenaltySecondsPerLap, 0.0);

      expect(highLine.effectiveLapLengthMeters, closeTo(258.5, 1e-6));
      expect(highLine.blackLinePenaltyMetersPerLap, closeTo(8.5, 1e-6));
      expect(
        highLine.blackLineTimePenaltySecondsPerLap,
        closeTo(8.5 / 15.82, 1e-4),
      );
    });

    test('utrzymuje precyzyjne tempo Rekordu Godzinnego (~15.80 s) przez 227 okrążeń z rzędu przy elicie', () {
      final HourRecordPacingSimulationResult result =
          VelodromeBankingAndCentripetalSolver.simulateHourRecordPacing(
        facility: grenchenVelodrome,
        bike: hourRecordBike,
        riderMassKg: 80.0,
        riderFtpWatts: 485.0,
        riderWPrimeJoules: 24000.0,
        targetLapTimeSeconds: 15.80,
        paceToleranceSeconds: 0.10,
        lineDisciplineSkill: 100.0,
        pacingPrecisionSkill: 100.0,
        includeStandingStartLap: false,
      );

      expect(result.completedFullLaps, greaterThanOrEqualTo(227));
      expect(result.maxConsecutiveOnPaceLaps, greaterThanOrEqualTo(227));
      expect(result.heldTargetPaceFor227Laps, isTrue);
      expect(result.steadyStateAverageLapTimeSeconds, closeTo(15.80, 0.05));
      expect(result.totalDistanceKm, greaterThan(56.8));
      expect(result.peakCentripetalGForce, greaterThan(1.40));
      expect(result.peakCentripetalGForce, lessThanOrEqualTo(1.80));
    });

    test('spada z tempa Rekordu Godzinnego gdy FTP kolarza jest niewystarczające', () {
      final HourRecordPacingSimulationResult underpowered =
          VelodromeBankingAndCentripetalSolver.simulateHourRecordPacing(
        facility: grenchenVelodrome,
        bike: hourRecordBike,
        riderMassKg: 80.0,
        riderFtpWatts: 310.0,
        riderWPrimeJoules: 12000.0,
        targetLapTimeSeconds: 15.80,
        paceToleranceSeconds: 0.10,
        lineDisciplineSkill: 95.0,
        pacingPrecisionSkill: 95.0,
      );

      expect(underpowered.heldTargetPaceFor227Laps, isFalse);
      expect(underpowered.maxConsecutiveOnPaceLaps, lessThan(227));
      expect(underpowered.totalDistanceKm, lessThan(54.0));
    });
  });
}
