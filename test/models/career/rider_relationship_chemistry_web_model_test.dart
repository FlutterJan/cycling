import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/rider_relationship_chemistry_web_model.dart';

void main() {
  List<RiderLockerRoomProfile> buildSampleRoster() {
    return const <RiderLockerRoomProfile>[
      RiderLockerRoomProfile(
        riderId: 'r_leader',
        riderName: 'Tadej Novak',
        archetype: LockerRoomPersonalityArchetype.alphaLeader,
        leadershipWeight: 92,
        egoLevel: 85,
        adaptability: 65,
        currentMorale: 88,
        isTeamCaptain: true,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_domestique',
        riderName: 'Jan Kowalski',
        archetype: LockerRoomPersonalityArchetype.humbleDomestique,
        leadershipWeight: 70,
        egoLevel: 25,
        adaptability: 90,
        currentMorale: 84,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_rival',
        riderName: 'Marco Bellini',
        archetype: LockerRoomPersonalityArchetype.alphaLeader,
        leadershipWeight: 82,
        egoLevel: 90,
        adaptability: 40,
        currentMorale: 72,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_joker',
        riderName: 'Liam Byrne',
        archetype: LockerRoomPersonalityArchetype.lockerRoomJoker,
        leadershipWeight: 60,
        egoLevel: 35,
        adaptability: 95,
        currentMorale: 92,
      ),
    ];
  }

  group('RiderRelationshipChemistryWebModel', () {
    test('initializes symmetric matrix from roster archetypes', () {
      final model = RiderRelationshipChemistryWebModel.fromRoster(
        teamId: 'team_apex',
        seasonYear: 2026,
        roster: buildSampleRoster(),
      );

      expect(model.profiles.length, 4);
      // 4 riders -> 6 unique edges
      expect(model.edges.length, 6);

      // Symmetry check
      expect(
        model.getScore('r_leader', 'r_domestique'),
        equals(model.getScore('r_domestique', 'r_leader')),
      );
      expect(model.getScore('r_leader', 'r_leader'), 0);

      // Alpha leader + humble domestique should start positive
      expect(model.getScore('r_leader', 'r_domestique'), greaterThan(0));
      // Two alpha leaders should start with friction
      expect(model.getScore('r_leader', 'r_rival'), lessThan(0));

      final matrix = model.buildRelationshipMatrix();
      expect(matrix['r_leader']!['r_domestique'],
          equals(matrix['r_domestique']!['r_leader']));
      expect(matrix['r_rival']!['r_rival'], 0);
    });

    test('clamps relationship scores strictly between -100 and +100', () {
      var model = RiderRelationshipChemistryWebModel.fromRoster(
        teamId: 'team_apex',
        seasonYear: 2026,
        roster: buildSampleRoster(),
      );

      final boost = model.applyInteractionEvent(
        riderAId: 'r_leader',
        riderBId: 'r_domestique',
        eventType: RelationshipEventType.heroicMountainDefense,
        scoreDelta: 150,
        summary: 'Obrona żółtej koszulki na Tourmalet',
        dateIso: '2026-07-14',
        raceName: 'Tour de France',
        incrementSharedRaces: 6,
      );
      expect(boost.success, isTrue);
      model = boost.updatedModel;
      expect(model.getScore('r_leader', 'r_domestique'), 100);

      final drop = model.applyInteractionEvent(
        riderAId: 'r_leader',
        riderBId: 'r_rival',
        eventType: RelationshipEventType.tacticalBetrayal,
        scoreDelta: -150,
        summary: 'Zaatakował własnego lidera w dolinie',
        dateIso: '2026-07-15',
        raceName: 'Tour de France',
      );
      expect(drop.success, isTrue);
      model = drop.updatedModel;
      expect(model.getScore('r_leader', 'r_rival'), -100);
      expect(
        model.getEdge('r_leader', 'r_rival')!.tierWithPactStatus(),
        RelationshipTier.toxicFeud,
      );
      expect(
        model.getEdge('r_leader', 'r_rival')!.visualTone(),
        RelationshipConnectionVisualTone.red,
      );
    });

    test('forges Blood Brothers pact only when requirements are met and grants race bonus', () {
      var model = RiderRelationshipChemistryWebModel.fromRoster(
        teamId: 'team_apex',
        seasonYear: 2026,
        roster: buildSampleRoster(),
      );

      // Too few shared races & score below 85
      final failAttempt = model.forgeBloodBrothersPact(
        riderAId: 'r_leader',
        riderBId: 'r_domestique',
        dateIso: '2026-05-01',
        raceName: 'Tour de Romandie',
      );
      expect(failAttempt.success, isFalse);

      // Build bond & shared races
      model = model
          .applyInteractionEvent(
            riderAId: 'r_leader',
            riderBId: 'r_domestique',
            eventType: RelationshipEventType.wheelOrBikeSacrifice,
            scoreDelta: 80,
            summary: 'Oddał rower liderowi na bruku',
            dateIso: '2026-04-12',
            raceName: 'Paris-Roubaix',
            incrementSharedRaces: 5,
          )
          .updatedModel;

      expect(model.canForgeBloodBrothersPact('r_leader', 'r_domestique'), isTrue);

      final forged = model.forgeBloodBrothersPact(
        riderAId: 'r_leader',
        riderBId: 'r_domestique',
        dateIso: '2026-07-20',
        raceName: 'Tour de France',
      );
      expect(forged.success, isTrue);
      model = forged.updatedModel;

      final pact = model.getPactBetween('r_leader', 'r_domestique');
      expect(pact, isNotNull);
      expect(pact!.isActive, isTrue);
      expect(model.getBloodBrothersFor('r_leader'), contains('r_domestique'));

      final edge = model.getEdge('r_leader', 'r_domestique')!;
      expect(
        edge.tierWithPactStatus(activePact: true),
        RelationshipTier.bloodBrothers,
      );
      expect(
        edge.visualTone(activePact: true),
        RelationshipConnectionVisualTone.gold,
      );

      final bonus = pact.calculateRaceBonus();
      expect(bonus.domestiqueSacrificeBonusPct, greaterThan(5.0));
      expect(bonus.moraleResilienceBonusPct, greaterThan(8.0));
      expect(bonus.wPrimeSacrificeMultiplier, greaterThan(1.05));
    });

    test('breaking Blood Brothers pact triggers betrayal (-75) and prevents re-forging', () {
      var model = RiderRelationshipChemistryWebModel.fromRoster(
        teamId: 'team_apex',
        seasonYear: 2026,
        roster: buildSampleRoster(),
      );

      model = model
          .applyInteractionEvent(
            riderAId: 'r_leader',
            riderBId: 'r_domestique',
            eventType: RelationshipEventType.heroicMountainDefense,
            scoreDelta: 80,
            summary: 'Wspólna walka w Alpach',
            dateIso: '2026-07-10',
            incrementSharedRaces: 6,
          )
          .updatedModel;

      model = model
          .forgeBloodBrothersPact(
            riderAId: 'r_leader',
            riderBId: 'r_domestique',
            dateIso: '2026-07-15',
            raceName: 'Tour de France',
          )
          .updatedModel;

      final pact = model.getPactBetween('r_leader', 'r_domestique')!;
      final broken = model.breakBloodBrothersPact(
        pactId: pact.pactId,
        reason: 'Odmowa pracy na finałowym podjeździe',
        dateIso: '2026-07-19',
      );
      expect(broken.success, isTrue);
      model = broken.updatedModel;

      expect(model.getScore('r_leader', 'r_domestique'), -75);
      expect(model.getPactBetween('r_leader', 'r_domestique'), isNull);

      // Even if score is restored later, broken pact cannot be re-forged
      model = model
          .applyInteractionEvent(
            riderAId: 'r_leader',
            riderBId: 'r_domestique',
            eventType: RelationshipEventType.conflictMediationSuccess,
            scoreDelta: 170,
            summary: 'Pojednanie po sezonie',
            dateIso: '2026-10-10',
          )
          .updatedModel;
      expect(model.canForgeBloodBrothersPact('r_leader', 'r_domestique'), isFalse);
    });

    test('evaluates team chemistry summary and race lineup report accurately', () {
      var model = RiderRelationshipChemistryWebModel.fromRoster(
        teamId: 'team_apex',
        seasonYear: 2026,
        roster: buildSampleRoster(),
      );

      // Create a toxic feud between r_leader and r_rival
      model = model
          .applyInteractionEvent(
            riderAId: 'r_leader',
            riderBId: 'r_rival',
            eventType: RelationshipEventType.mediaCriticism,
            scoreDelta: -60,
            summary: 'Ostry wywiad po etapie',
            dateIso: '2026-06-05',
          )
          .updatedModel;

      final summary = model.calculateOverallTeamChemistry();
      expect(summary.toxicFeudsCount, 1);
      expect(summary.leadershipConflictRisk, greaterThan(20.0));

      final lineupReport = model.evaluateLineupChemistry(
        const <String>['r_leader', 'r_rival', 'r_domestique'],
      );
      expect(lineupReport.toxicPairsCount, 1);
      expect(lineupReport.conflictWarnings, isNotEmpty);
      expect(lineupReport.sabotageRiskPct, greaterThan(0.0));
    });

    test('serializes and deserializes JSON round-trip without data loss', () {
      var model = RiderRelationshipChemistryWebModel.fromRoster(
        teamId: 'team_apex',
        seasonYear: 2026,
        roster: buildSampleRoster(),
      );

      model = model
          .applyInteractionEvent(
            riderAId: 'r_leader',
            riderBId: 'r_domestique',
            eventType: RelationshipEventType.winningLeadOut,
            scoreDelta: 75,
            summary: 'Perfekcyjne rozprowadzenie',
            dateIso: '2026-05-10',
            raceName: 'Giro d\'Italia',
            incrementSharedRaces: 5,
          )
          .updatedModel;

      model = model
          .forgeBloodBrothersPact(
            riderAId: 'r_leader',
            riderBId: 'r_domestique',
            dateIso: '2026-05-12',
            raceName: 'Giro d\'Italia',
          )
          .updatedModel;

      final json = model.toJson();
      final restored = RiderRelationshipChemistryWebModel.fromJson(json);

      expect(restored.teamId, model.teamId);
      expect(restored.seasonYear, model.seasonYear);
      expect(restored.profiles.length, model.profiles.length);
      expect(restored.edges.length, model.edges.length);
      expect(restored.bloodBrothersPacts.length, 1);
      expect(
        restored.getScore('r_leader', 'r_domestique'),
        equals(model.getScore('r_leader', 'r_domestique')),
      );
      expect(restored.recentEvents.length, model.recentEvents.length);
    });
  });
}
