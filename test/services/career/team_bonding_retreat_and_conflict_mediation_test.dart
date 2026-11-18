import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/rider_relationship_chemistry_web_model.dart';
import 'package:pro_peloton_manager/services/career/team_bonding_retreat_and_conflict_mediation.dart';

RiderRelationshipChemistryWebModel _buildTestModel() {
  final base = RiderRelationshipChemistryWebModel.fromRoster(
    teamId: 'team_test',
    seasonYear: 2026,
    roster: const <RiderLockerRoomProfile>[
      RiderLockerRoomProfile(
        riderId: 'r_a',
        riderName: 'Lider A',
        archetype: LockerRoomPersonalityArchetype.alphaLeader,
        leadershipWeight: 90,
        egoLevel: 86,
        adaptability: 55,
        currentMorale: 70,
        isTeamCaptain: true,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_b',
        riderName: 'Lider B',
        archetype: LockerRoomPersonalityArchetype.alphaLeader,
        leadershipWeight: 85,
        egoLevel: 82,
        adaptability: 60,
        currentMorale: 72,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_vet',
        riderName: 'Kapitan Vet',
        archetype: LockerRoomPersonalityArchetype.mentorVeteran,
        leadershipWeight: 75,
        egoLevel: 35,
        adaptability: 88,
        currentMorale: 80,
      ),
      RiderLockerRoomProfile(
        riderId: 'r_joker',
        riderName: 'Joker',
        archetype: LockerRoomPersonalityArchetype.lockerRoomJoker,
        leadershipWeight: 60,
        egoLevel: 40,
        adaptability: 92,
        currentMorale: 84,
      ),
    ],
  );

  return base
      .applyInteractionEvent(
        riderAId: 'r_a',
        riderBId: 'r_b',
        eventType: RelationshipEventType.leadershipClash,
        scoreDelta: -40,
        summary: 'Spór o rolę lidera.',
        dateIso: '2026-06-10',
      )
      .updatedModel;
}

void main() {
  const service = TeamBondingRetreatAndConflictMediationService();

  group('TeamBondingRetreatAndConflictMediationService', () {
    test('wykrywa aktywne konflikty i sortuje je po severity', () {
      final model = _buildTestModel();
      final conflicts = service.detectActiveConflicts(model);

      expect(conflicts, isNotEmpty);
      expect(conflicts.first.riderAId, 'r_a');
      expect(conflicts.first.riderBId, 'r_b');
      expect(conflicts.first.currentScore, lessThan(0));
      expect(
        conflicts.first.recommendedApproach,
        ConflictMediationApproach.sharedLeadershipCharter,
      );
    });

    test('integracja drużynowa odrzuca zbyt niski budżet', () {
      final model = _buildTestModel();
      final res = service.executeTeamBondingRetreat(
        model: model,
        retreatType: TeamBondingRetreatType.alpsCabinRetreat,
        availableBudgetEur: 1000,
        dateIso: '2026-06-15',
      );

      expect(res.success, isFalse);
      expect(res.costEur, 0);
      expect(res.pairsAffectedCount, 0);
    });

    test('integracja drużynowa podnosi chemię wszystkich par uczestników', () {
      final model = _buildTestModel();
      final beforeAvg =
          model.calculateOverallTeamChemistry().averageMatrixScore;

      final res = service.executeTeamBondingRetreat(
        model: model,
        retreatType: TeamBondingRetreatType.gastronomyAndWineEvening,
        availableBudgetEur: 50000,
        dateIso: '2026-06-15',
      );

      expect(res.success, isTrue);
      expect(res.costEur, 4500);
      expect(res.pairsAffectedCount, 6);
      expect(res.teamMoraleDelta, 5);
      expect(
        res.updatedChemistryModel
            .calculateOverallTeamChemistry()
            .averageMatrixScore,
        greaterThan(beforeAvg),
      );
    });

    test('mediacja przełomowa poprawia relację i zmniejsza napięcie', () {
      final model = _buildTestModel();
      final beforeEdge = model.getEdge('r_a', 'r_b')!;

      final res = service.mediateLeaderConflict(
        model: model,
        riderAId: 'r_a',
        riderBId: 'r_b',
        approach: ConflictMediationApproach.sharedLeadershipCharter,
        dateIso: '2026-06-16',
        overrideRoll: 0.05,
      );

      expect(res.success, isTrue);
      expect(
        res.outcomeTier,
        MediationOutcomeTier.breakthroughReconciliation,
      );
      expect(res.scoreAfter, greaterThan(beforeEdge.clampedScore));
      expect(res.tensionAfter, lessThan(beforeEdge.tension));
    });

    test('fiasko mediacji obniża wynik relacji', () {
      final model = _buildTestModel();
      final beforeScore = model.getEdge('r_a', 'r_b')!.clampedScore;

      final res = service.mediateLeaderConflict(
        model: model,
        riderAId: 'r_a',
        riderBId: 'r_b',
        approach: ConflictMediationApproach.authorityUltimatum,
        dateIso: '2026-06-16',
        overrideRoll: 0.99,
      );

      expect(res.success, isFalse);
      expect(res.outcomeTier, MediationOutcomeTier.mediationBackfire);
      expect(res.scoreAfter, lessThan(beforeScore));
    });
  });

  group('TeamBondingRetreatAndConflictMediationPanel UI', () {
    for (final size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renderuje bez przepełnienia na ${size.width}x${size.height}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: TeamBondingRetreatAndConflictMediationPanel(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text('Integracja Szatni & Mediacje Liderów'),
          findsOneWidget,
        );
        expect(find.text('Integracje Drużynowe'), findsOneWidget);
        expect(find.text('Mediacja Konfliktów Liderów'), findsOneWidget);
      });
    }
  });
}
