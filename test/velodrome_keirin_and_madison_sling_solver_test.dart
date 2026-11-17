import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_banking_and_centripetal_solver.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_keirin_and_madison_sling_solver.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';

void main() {
  final VelodromeFacilitySpec grenchen =
      VelodromeTrackAndHourRecordModel.defaultVelodromes.first;
  const FixedGearTrackBike trackBike =
      VelodromeTrackAndHourRecordModel.defaultTrackBike;

  KeirinRiderProfile buildRider(
    String id, {
    double mass = 76.0,
    double peakPower = 1850.0,
    double cp = 420.0,
    double wPrime = 24000.0,
    double tactics = 82.0,
    int slot = 1,
  }) {
    return KeirinRiderProfile(
      riderId: id,
      name: 'Rider $id',
      riderMassKg: mass,
      bike: trackBike,
      peakSprintPowerWatts: peakPower,
      criticalPowerWatts: cp,
      wPrimeJoules: wPrime,
      trackTacticsSkill: tactics,
      startingSlot: slot,
    );
  }

  group('Keirin Physics & Derny Pacing', () {
    test('Derny smoothly accelerates from 30 km/h to 50 km/h at 750 m pull-off', () {
      const derny = KeirinDernySpec();
      final double vStartKmh =
          VelodromeKeirinAndMadisonSlingSolver.computeDernyTargetSpeedMs(
                derny: derny,
                elapsedDistanceMeters: 0.0,
                dernyPullOffDistanceMeters: 750.0,
              ) *
              3.6;
      final double vMidKmh =
          VelodromeKeirinAndMadisonSlingSolver.computeDernyTargetSpeedMs(
                derny: derny,
                elapsedDistanceMeters: 375.0,
                dernyPullOffDistanceMeters: 750.0,
              ) *
              3.6;
      final double vPullOffKmh =
          VelodromeKeirinAndMadisonSlingSolver.computeDernyTargetSpeedMs(
                derny: derny,
                elapsedDistanceMeters: 750.0,
                dernyPullOffDistanceMeters: 750.0,
              ) *
              3.6;

      expect(vStartKmh, closeTo(30.0, 0.05));
      expect(vMidKmh, closeTo(40.0, 0.5));
      expect(vPullOffKmh, closeTo(50.0, 0.05));
    });

    test('Direct Derny slipstream gives strong CdA reduction vs lateral attack', () {
      const derny = KeirinDernySpec();
      final double slot1Draft =
          VelodromeKeirinAndMadisonSlingSolver.computeKeirinDraftCdaFactor(
        derny: derny,
        pacelineSlot: 1,
        gapToLeadMeters: 0.8,
        lateralOffsetMeters: 0.0,
        isDernyActive: true,
      );
      final double slot4Draft =
          VelodromeKeirinAndMadisonSlingSolver.computeKeirinDraftCdaFactor(
        derny: derny,
        pacelineSlot: 4,
        gapToLeadMeters: 0.8,
        lateralOffsetMeters: 0.0,
        isDernyActive: true,
      );
      final double outInWind =
          VelodromeKeirinAndMadisonSlingSolver.computeKeirinDraftCdaFactor(
        derny: derny,
        pacelineSlot: 1,
        gapToLeadMeters: 0.8,
        lateralOffsetMeters: 1.8,
        isDernyActive: true,
      );

      expect(slot1Draft, lessThan(0.45));
      expect(slot4Draft, greaterThan(slot1Draft));
      expect(outInWind, greaterThan(0.95));
    });

    test('Diving from upper banking converts potential energy into speed gain', () {
      final double gainMs =
          VelodromeKeirinAndMadisonSlingSolver.computeBankingDiveSpeedGainMs(
        facility: grenchen,
        section: VelodromeTrackSection.turnApex,
        previousMetersAboveBlackLine: 3.0,
        currentMetersAboveBlackLine: 0.2,
        currentSpeedMs: 14.0,
      );
      expect(gainMs, greaterThan(0.8));
      expect(gainMs, lessThan(2.5));
    });

    test('solveKeirinStep detects illegal Derny pass and computes sprint speed', () {
      final rider = buildRider('k1');
      final illegalStep = VelodromeKeirinAndMadisonSlingSolver.solveKeirinStep(
        KeirinStepInput(
          facility: grenchen,
          derny: const KeirinDernySpec(),
          rider: rider,
          elapsedDistanceMeters: 500.0,
          totalRaceDistanceMeters: 1500.0,
          currentSpeedMs: 12.5,
          riderPowerWatts: 500.0,
          pacelineSlot: 1,
          gapToDernyMeters: -0.5,
        ),
      );
      expect(illegalStep.phase, KeirinRacePhase.dernyRampUp);
      expect(illegalStep.hasPassedDernyIllegally, isTrue);

      final sprintStep = VelodromeKeirinAndMadisonSlingSolver.solveKeirinStep(
        KeirinStepInput(
          facility: grenchen,
          derny: const KeirinDernySpec(),
          rider: rider,
          elapsedDistanceMeters: 1250.0,
          totalRaceDistanceMeters: 1500.0,
          currentSpeedMs: 18.0,
          riderPowerWatts: 1850.0,
          pacelineSlot: 1,
          gapToDernyMeters: 2.0,
          previousMetersAboveBlackLine: 2.2,
          metersAboveBlackLine: 0.0,
        ),
      );
      expect(sprintStep.phase, KeirinRacePhase.finalSprint);
      expect(sprintStep.nextSpeedKmh, greaterThan(64.0));
      expect(sprintStep.hasPassedDernyIllegally, isFalse);
    });

    test('simulateKeirinRace runs full 6-lap 1500 m race with 6 riders', () {
      final riders = [
        buildRider('1', peakPower: 1980, tactics: 92, slot: 1),
        buildRider('2', peakPower: 1890, tactics: 85, slot: 2),
        buildRider('3', peakPower: 1780, tactics: 80, slot: 3),
        buildRider('4', peakPower: 1820, tactics: 76, slot: 4),
        buildRider('5', peakPower: 1700, tactics: 72, slot: 5),
        buildRider('6', peakPower: 1650, tactics: 68, slot: 6),
      ];

      final result = VelodromeKeirinAndMadisonSlingSolver.simulateKeirinRace(
        config: KeirinRaceConfig(facility: grenchen),
        riders: riders,
      );

      expect(result.standings.length, 6);
      expect(result.dernyPullOffSpeedKmh, closeTo(50.0, 2.0));
      expect(result.standings.first.finishingPosition, 1);
      expect(result.standings.first.peakSpeedKmh, greaterThan(62.0));
      expect(
        result.standings.first.finishTimeSeconds,
        lessThanOrEqualTo(result.standings.last.finishTimeSeconds),
      );
    });
  });

  group('Madison Hand Sling Physics & Race Simulation', () {
    test('Textbook Hand Sling transfers momentum and boosts outgoing rider', () {
      final sling = VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
        MadisonHandSlingInput(
          facility: grenchen,
          incomingRiderMassKg: 74.0,
          incomingBike: trackBike,
          incomingSpeedMs: 15.8, // ~56.9 km/h
          outgoingRiderMassKg: 72.0,
          outgoingBike: trackBike,
          outgoingSpeedMs: 9.5, // ~34.2 km/h
          incomingSlingSkill: 92.0,
          outgoingSlingSkill: 90.0,
          teamChemistry: 94.0,
          longitudinalGapMeters: 0.15,
          lateralGapMeters: 0.65,
        ),
      );

      expect(sling.isSuccessfulExchange, isTrue);
      expect(sling.quality, MadisonSlingQuality.textbookSlingshot);
      expect(sling.outgoingSpeedGainKmh, greaterThan(14.0));
      expect(sling.outgoingPostSlingSpeedKmh, greaterThan(48.0));
      expect(sling.incomingPostSlingSpeedKmh, lessThan(56.9));
      expect(sling.transferredImpulseNs, greaterThan(350.0));
    });

    test('Excessive lateral/longitudinal gap results in missed hand touch', () {
      final missed = VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
        MadisonHandSlingInput(
          facility: grenchen,
          incomingRiderMassKg: 74.0,
          incomingBike: trackBike,
          incomingSpeedMs: 15.0,
          outgoingRiderMassKg: 72.0,
          outgoingBike: trackBike,
          outgoingSpeedMs: 9.5,
          longitudinalGapMeters: 2.1,
          lateralGapMeters: 1.9,
        ),
      );

      expect(missed.isSuccessfulExchange, isFalse);
      expect(missed.quality, MadisonSlingQuality.missedHandTouch);
      expect(missed.outgoingSpeedGainKmh, 0.0);
      expect(missed.penaltyTimeLostSeconds, greaterThan(1.0));
    });

    test('Extreme speed delta with low skill triggers crash/illegal push', () {
      final crash = VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
        MadisonHandSlingInput(
          facility: grenchen,
          incomingRiderMassKg: 74.0,
          incomingBike: trackBike,
          incomingSpeedMs: 20.5, // 73.8 km/h
          outgoingRiderMassKg: 72.0,
          outgoingBike: trackBike,
          outgoingSpeedMs: 7.5, // 27.0 km/h
          incomingSlingSkill: 35.0,
          outgoingSlingSkill: 35.0,
        ),
      );

      expect(crash.isSuccessfulExchange, isFalse);
      expect(crash.quality, MadisonSlingQuality.illegalPushOrCrash);
      expect(crash.penaltyTimeLostSeconds, greaterThan(4.0));
    });

    test('simulateMadisonRace scores sprints every 10 laps with double final points', () {
      final teams = [
        MadisonTeamRiderPair(
          teamId: 'BEL',
          teamName: 'Belgium',
          riderA: buildRider('bel_a', cp: 445, wPrime: 26000),
          riderB: buildRider('bel_b', cp: 440, wPrime: 25500),
          riderASlingSkill: 92,
          riderBSlingSkill: 91,
          teamChemistry: 95,
          exchangeIntervalLaps: 3,
        ),
        MadisonTeamRiderPair(
          teamId: 'DEN',
          teamName: 'Denmark',
          riderA: buildRider('den_a', cp: 435, wPrime: 24500),
          riderB: buildRider('den_b', cp: 432, wPrime: 24000),
          riderASlingSkill: 88,
          riderBSlingSkill: 87,
          teamChemistry: 90,
          exchangeIntervalLaps: 3,
        ),
        MadisonTeamRiderPair(
          teamId: 'POL',
          teamName: 'Poland',
          riderA: buildRider('pol_a', cp: 420, wPrime: 23000),
          riderB: buildRider('pol_b', cp: 418, wPrime: 22800),
          riderASlingSkill: 84,
          riderBSlingSkill: 84,
          teamChemistry: 86,
          exchangeIntervalLaps: 4,
        ),
        MadisonTeamRiderPair(
          teamId: 'FRA',
          teamName: 'France',
          riderA: buildRider('fra_a', cp: 405, wPrime: 21000),
          riderB: buildRider('fra_b', cp: 400, wPrime: 20500),
          riderASlingSkill: 78,
          riderBSlingSkill: 77,
          teamChemistry: 80,
          exchangeIntervalLaps: 4,
        ),
      ];

      final result = VelodromeKeirinAndMadisonSlingSolver.simulateMadisonRace(
        config: MadisonRaceConfig(
          facility: grenchen,
          totalLaps: 40,
          sprintIntervalLaps: 10,
        ),
        teams: teams,
      );

      expect(result.sprintResults.length, 4);
      expect(result.sprintResults.last.isFinalDoublePoints, isTrue);
      expect(result.standings.length, 4);
      expect(result.standings.first.rank, 1);
      expect(result.standings.first.successfulHandSlings, greaterThan(0));
      expect(result.standings.first.averageSlingBoostKmh, greaterThan(10.0));
      expect(result.standings.first.averageSpeedKmh, greaterThan(50.0));
    });

    test('Edge cases: empty riders/teams return empty standings cleanly', () {
      final keirinEmpty =
          VelodromeKeirinAndMadisonSlingSolver.simulateKeirinRace(
        config: KeirinRaceConfig(facility: grenchen),
        riders: const [],
      );
      expect(keirinEmpty.standings, isEmpty);

      final madisonEmpty =
          VelodromeKeirinAndMadisonSlingSolver.simulateMadisonRace(
        config: MadisonRaceConfig(facility: grenchen, totalLaps: 20),
        teams: const [],
      );
      expect(madisonEmpty.standings, isEmpty);
      expect(madisonEmpty.sprintResults, isEmpty);
    });
  });
}
