import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/post_stage_morale_and_ego_updater.dart';
import 'package:pro_peloton_manager/services/career/rider_ego_and_conflicts_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required RiderSpecialization specialization,
  required RiderRole role,
  double morale = 70.0,
  double leaderLoyalty = 70.0,
  int targetOvr = 80,
}) {
  final generated = RiderProceduralGenerator.generateRider(
    specialization: specialization,
    role: role,
    targetOverallRating: targetOvr,
  );
  return generated.copyWith(
    id: id,
    firstName: firstName,
    lastName: lastName,
    contract: generated.contract.copyWith(
      teamId: 'team_pl',
      role: role,
      morale: morale,
      leaderLoyalty: leaderLoyalty,
    ),
  );
}

RaceStage _buildStage({
  required StageType stageType,
  WeatherCondition weather = WeatherCondition.sunny,
  double windSpeedKmh = 10.0,
  double windDirectionDegrees = 90.0,
}) {
  return RaceStage(
    id: 'stage_1',
    stageNumber: 1,
    name: 'Etap testowy',
    stageType: stageType,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 160.0,
        startElevationM: 120.0,
        endElevationM: 140.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 15.0,
        windDirectionDegrees: windDirectionDegrees,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.finishLine,
      ),
    ],
    baseTemperatureCelsius: 21.0,
    weatherCondition: weather,
    windSpeedKmh: windSpeedKmh,
  );
}

OfficialRiderStageResult _buildResult({
  required Rider rider,
  required int rank,
  bool isDnf = false,
}) {
  return OfficialRiderStageResult(
    riderId: rider.id,
    riderName: rider.fullName,
    teamId: 'team_pl',
    rank: rank,
    rawFinishTimeSeconds: 14400.0 + rank,
    officialFinishTimeSeconds: 14400.0 + rank,
    gapToWinnerSeconds: rank == 1 ? 0.0 : rank * 2.0,
    isDnf: isDnf,
  );
}

void main() {
  group('PostStageMoraleAndEgoUpdater', () {
    test('handles empty squad gracefully', () {
      final report = PostStageMoraleAndEgoUpdater.processPostStageMoraleAndEgo(
        squadRiders: const [],
        context: PostStageMoraleContext(
          raceId: 'tour_1',
          raceName: 'Tour de Pologne',
          stage: _buildStage(stageType: StageType.flat),
          teamId: 'team_pl',
          teamResults: const [],
        ),
      );

      expect(report.updatedSquad, isEmpty);
      expect(report.riderDeltas, isEmpty);
      expect(report.triggeredEvents, isEmpty);
      expect(report.teamAverageMoraleDelta, 0.0);
    });

    test('boosts entire team morale on stage victory and leader jersey takeover',
        () {
      final leader = _buildTestRider(
        id: 'r_leader',
        firstName: 'Michał',
        lastName: 'Kowalski',
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        morale: 70.0,
      );
      final domestique = _buildTestRider(
        id: 'r_dom',
        firstName: 'Jan',
        lastName: 'Nowak',
        specialization: RiderSpecialization.domestiqueEngine,
        role: RiderRole.domestique,
        morale: 68.0,
      );

      final report = PostStageMoraleAndEgoUpdater.processPostStageMoraleAndEgo(
        squadRiders: [leader, domestique],
        context: PostStageMoraleContext(
          raceId: 'tdf_2026',
          raceName: 'Tour de France',
          stage: _buildStage(stageType: StageType.highMountain),
          teamId: 'team_pl',
          designatedLeaderId: leader.id,
          tookGcLeaderJersey: true,
          jerseyHolderRiderId: leader.id,
          teamResults: [
            _buildResult(rider: leader, rank: 1),
            _buildResult(rider: domestique, rank: 24),
          ],
        ),
      );

      expect(
        report.triggeredEvents,
        containsAll([
          PostStageMoraleEventType.stageVictoryTeamSurge,
          PostStageMoraleEventType.leaderJerseyTakenSurge,
        ]),
      );

      final updatedLeader =
          report.updatedSquad.firstWhere((r) => r.id == leader.id);
      final updatedDom =
          report.updatedSquad.firstWhere((r) => r.id == domestique.id);

      expect(updatedLeader.contract.morale, greaterThan(90.0));
      expect(updatedDom.contract.morale, greaterThan(80.0));
      expect(report.teamAverageMoraleDelta, greaterThan(15.0));
    });

    test(
        'drops leader morale, loyalty and emits incident when unprotected in crosswind',
        () {
      final leader = _buildTestRider(
        id: 'r_leader',
        firstName: 'Tadej',
        lastName: 'Królewski',
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        morale: 80.0,
        leaderLoyalty: 80.0,
      );
      final domestique = _buildTestRider(
        id: 'r_dom',
        firstName: 'Piotr',
        lastName: 'Wiatr',
        specialization: RiderSpecialization.domestiqueEngine,
        role: RiderRole.domestique,
        morale: 75.0,
      );

      final report = PostStageMoraleAndEgoUpdater.processPostStageMoraleAndEgo(
        squadRiders: [leader, domestique],
        context: PostStageMoraleContext(
          raceId: 'tdf_2026',
          raceName: 'Tour de France',
          stage: _buildStage(
            stageType: StageType.flat,
            weather: WeatherCondition.crosswindGale,
            windSpeedKmh: 45.0,
            windDirectionDegrees: 90.0,
          ),
          teamId: 'team_pl',
          designatedLeaderId: leader.id,
          leaderWindProtectionRatio: 0.1,
          leaderProtectedDomestiquesCount: 0,
          leaderCrosswindTimeLossSeconds: 65.0,
          sprintTrainOrganized: true,
          teamResults: [
            _buildResult(rider: leader, rank: 42),
            _buildResult(rider: domestique, rank: 55),
          ],
        ),
      );

      expect(
        report.triggeredEvents,
        contains(PostStageMoraleEventType.leaderUnprotectedInCrosswind),
      );

      final updatedLeader =
          report.updatedSquad.firstWhere((r) => r.id == leader.id);
      final leaderDelta = report.deltaForRider(leader.id)!;

      expect(updatedLeader.contract.morale, lessThan(65.0));
      expect(updatedLeader.contract.leaderLoyalty, lessThan(65.0));
      expect(leaderDelta.egoPressureDelta, greaterThan(15.0));
      expect(report.generatedIncidents, isNotEmpty);
      expect(
        report.generatedIncidents.first.incidentType,
        IntraTeamIncidentType.postStageMediaRant,
      );
    });

    test(
        'frustrates sprinter when no leadout train is organized on flat finish',
        () {
      final sprinter = _buildTestRider(
        id: 'r_sprinter',
        firstName: 'Jasper',
        lastName: 'Błysk',
        specialization: RiderSpecialization.pureSprinter,
        role: RiderRole.sprinter,
        morale: 78.0,
        leaderLoyalty: 76.0,
      );
      final helper = _buildTestRider(
        id: 'r_help',
        firstName: 'Adam',
        lastName: 'Koło',
        specialization: RiderSpecialization.domestiqueEngine,
        role: RiderRole.domestique,
        morale: 72.0,
      );

      final report = PostStageMoraleAndEgoUpdater.processPostStageMoraleAndEgo(
        squadRiders: [sprinter, helper],
        context: PostStageMoraleContext(
          raceId: 'giro_2026',
          raceName: 'Giro d\'Italia',
          stage: _buildStage(stageType: StageType.flat),
          teamId: 'team_pl',
          designatedSprinterId: sprinter.id,
          sprintTrainOrganized: false,
          sprintLeadoutRidersCount: 0,
          sprintLeadoutSupportRatio: 0.1,
          teamResults: [
            _buildResult(rider: sprinter, rank: 14),
            _buildResult(rider: helper, rank: 48),
          ],
          personalityProfilesByRiderId: {
            sprinter.id: RiderPersonalityProfile(
              riderId: sprinter.id,
              archetype: PersonalityArchetype.primaDonnaSprinter,
              ambition: 92,
              egoLevel: 88,
              teamLoyalty: 45,
              mediaDramaProneness: 85,
              tacticalPatience: 20,
            ),
          },
        ),
      );

      expect(
        report.triggeredEvents,
        contains(PostStageMoraleEventType.sprinterNoLeadoutTrainFrustration),
      );

      final updatedSprinter =
          report.updatedSquad.firstWhere((r) => r.id == sprinter.id);
      final sprinterDelta = report.deltaForRider(sprinter.id)!;

      expect(updatedSprinter.contract.morale, lessThan(60.0));
      expect(updatedSprinter.contract.leaderLoyalty, lessThan(60.0));
      expect(sprinterDelta.egoPressureDelta, greaterThan(20.0));
      expect(report.generatedIncidents, isNotEmpty);
      expect(
        report.generatedIncidents.first.incidentType,
        IntraTeamIncidentType.sprintLeadoutSabotage,
      );
    });

    test('supports normalized 0.0-1.0 morale scale without overflow', () {
      final rider = _buildTestRider(
        id: 'r_norm',
        firstName: 'Kamil',
        lastName: 'Skala',
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        morale: 0.75,
        leaderLoyalty: 0.80,
      );

      final report = PostStageMoraleAndEgoUpdater.processPostStageMoraleAndEgo(
        squadRiders: [rider],
        context: PostStageMoraleContext(
          raceId: 'vuelta_2026',
          raceName: 'La Vuelta',
          stage: _buildStage(stageType: StageType.summitFinish),
          teamId: 'team_pl',
          tookGcLeaderJersey: true,
          teamResults: [_buildResult(rider: rider, rank: 1)],
        ),
      );

      final updated = report.updatedSquad.single;
      expect(updated.contract.morale, greaterThan(0.75));
      expect(updated.contract.morale, lessThanOrEqualTo(1.0));
      expect(updated.contract.leaderLoyalty, greaterThan(0.80));
      expect(updated.contract.leaderLoyalty, lessThanOrEqualTo(1.0));
    });
  });
}
