import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/domestique_road_blocking_mechanics.dart';
import 'package:pro_peloton_manager/engine/peloton/peloton_chase_ai_controller.dart';

void main() {
  const mechanics = DomestiqueRoadBlockingMechanics();

  group('DomestiqueRoadBlockingMechanics', () {
    test('aktywuje pełną blokadę na wąskiej drodze (<4.5 m) przy 65% FTP', () {
      const input = RoadBlockingInput(
        roadWidthMeters: 3.8,
        blockingTeamId: 'team_visma',
        blockingTeamName: 'Team Visma',
        hasTeammateInBreakaway: true,
        breakawayGapSeconds: 95.0,
        domestiquesAtFrontCount: 5,
        blockingPaceFtpRatio: 0.65,
        formationSpreadNormalized: 1.0,
        rivalChaseCommitmentCount: 3,
        rivalDesiredChaseFtpRatio: 0.92,
        rivalPlannedClawbackSecondsPer10Km: 50.0,
      );

      final result = mechanics.evaluateBlocking(input);

      expect(result.isRoadNarrowEnough, isTrue);
      expect(result.isBlockingActive, isTrue);
      expect(result.status, RoadBlockingStatus.fullRoadblock);
      expect(result.blockadeCoverageRatio, closeTo(1.0, 0.001));
      expect(result.canRivalSqueezePast, isFalse);
      expect(result.chaseDisruptionFactor, greaterThanOrEqualTo(0.65));
      expect(result.chaseEfficiencyMultiplier, lessThanOrEqualTo(0.35));
      expect(result.effectiveClawbackSecondsPer10Km, lessThan(20.0));
      expect(result.effectivePelotonPaceFtpRatio, lessThan(0.75));
      expect(result.gutterSurgeExtraWattsRequired, greaterThan(100));
      expect(result.blockingSlots, hasLength(5));
    });

    test('nie aktywuje blokady na szerokiej drodze (>=4.5 m)', () {
      const input = RoadBlockingInput(
        roadWidthMeters: 4.5,
        blockingTeamId: 'team_visma',
        blockingTeamName: 'Team Visma',
        hasTeammateInBreakaway: true,
        breakawayGapSeconds: 90.0,
        domestiquesAtFrontCount: 5,
        blockingPaceFtpRatio: 0.65,
        rivalPlannedClawbackSecondsPer10Km: 50.0,
      );

      final result = mechanics.evaluateBlocking(input);

      expect(result.isRoadNarrowEnough, isFalse);
      expect(result.isBlockingActive, isFalse);
      expect(result.status, RoadBlockingStatus.inactive);
      expect(result.chaseDisruptionFactor, 0.0);
      expect(result.chaseEfficiencyMultiplier, 1.0);
      expect(result.effectiveClawbackSecondsPer10Km, 50.0);
    });

    test('nie blokuje pogoni bez kolegi z drużyny w ucieczce', () {
      const input = RoadBlockingInput(
        roadWidthMeters: 3.5,
        blockingTeamId: 'team_uae',
        blockingTeamName: 'UAE Team',
        hasTeammateInBreakaway: false,
        breakawayGapSeconds: 120.0,
        domestiquesAtFrontCount: 4,
        blockingPaceFtpRatio: 0.65,
        rivalPlannedClawbackSecondsPer10Km: 45.0,
      );

      final result = mechanics.evaluateBlocking(input);

      expect(result.status, RoadBlockingStatus.inactive);
      expect(result.isBlockingActive, isFalse);
      expect(result.blockingSlots, isEmpty);
      expect(result.effectiveClawbackSecondsPer10Km, 45.0);
    });

    test('wysokie tempo (>78% FTP) traci skuteczność blokowania', () {
      const slowInput = RoadBlockingInput(
        roadWidthMeters: 3.9,
        blockingTeamId: 'team_a',
        blockingTeamName: 'Team A',
        hasTeammateInBreakaway: true,
        breakawayGapSeconds: 60.0,
        domestiquesAtFrontCount: 4,
        blockingPaceFtpRatio: 0.65,
        rivalPlannedClawbackSecondsPer10Km: 40.0,
      );

      final fastInput = slowInput.copyWith(blockingPaceFtpRatio: 0.85);

      final slowResult = mechanics.evaluateBlocking(slowInput);
      final fastResult = mechanics.evaluateBlocking(fastInput);

      expect(
        slowResult.chaseDisruptionFactor,
        greaterThan(fastResult.chaseDisruptionFactor),
      );
      expect(
        fastResult.effectiveClawbackSecondsPer10Km,
        greaterThan(slowResult.effectiveClawbackSecondsPer10Km),
      );
    });

    test('computeBlockingSlots rozkłada kolarzy symetrycznie od lewej do prawej', () {
      final slots = mechanics.computeBlockingSlots(
        domestiquesCount: 4,
        roadWidthMeters: 4.0,
        spreadNormalized: 1.0,
      );

      expect(slots, hasLength(4));
      expect(slots.first.normalizedLateralPosition, closeTo(-0.88, 0.001));
      expect(slots.last.normalizedLateralPosition, closeTo(0.88, 0.001));
      expect(slots.first.lateralOffsetMeters, lessThan(0.0));
      expect(slots.last.lateralOffsetMeters, greaterThan(0.0));
      expect(slots.first.targetFtpRatio, 0.65);
    });

    test('applyToChasePlan zmniejsza odrabianie strat i zwiększa szansę ucieczki', () {
      const basePlan = PelotonChasePlan(
        urgency: ChaseUrgency.gradualClosing,
        targetCatchKmRemaining: 8.0,
        projectedCatchKm: 172.0,
        requiredClawbackSecondsPer10Km: 45.0,
        actualClawbackSecondsPer10Km: 50.0,
        aiMiscalculationFactor: 1.0,
        breakawaySurvivalProbability: 0.30,
        committedTeams: [
          ChaseCommitment(
            teamId: 'rival_1',
            teamName: 'Rival Pro',
            committedDomestiqueIds: ['r1', 'r2'],
            targetWattsPerRider: 340,
            motive: 'Pogoń za ucieczką',
          ),
        ],
        radioReport: 'Peleton goni.',
      );

      final blockingResult = mechanics.evaluateBlocking(
        const RoadBlockingInput(
          roadWidthMeters: 3.7,
          blockingTeamId: 'leader_team',
          blockingTeamName: 'Leader Team',
          hasTeammateInBreakaway: true,
          breakawayGapSeconds: 80.0,
          domestiquesAtFrontCount: 5,
          blockingPaceFtpRatio: 0.65,
        ),
      );

      final updatedPlan = mechanics.applyToChasePlan(
        basePlan: basePlan,
        blockingResult: blockingResult,
      );

      expect(
        updatedPlan.actualClawbackSecondsPer10Km,
        lessThan(basePlan.actualClawbackSecondsPer10Km),
      );
      expect(
        updatedPlan.breakawaySurvivalProbability,
        greaterThan(basePlan.breakawaySurvivalProbability),
      );
      expect(updatedPlan.radioReport, contains('Leader Team'));
    });

    test('serializacja JSON zachowuje kluczowe pola', () {
      final result = mechanics.evaluateBlocking(
        const RoadBlockingInput(
          roadWidthMeters: 4.0,
          blockingTeamId: 'team_x',
          blockingTeamName: 'Team X',
          hasTeammateInBreakaway: true,
          breakawayGapSeconds: 55.0,
          domestiquesAtFrontCount: 4,
          blockingPaceFtpRatio: 0.65,
        ),
      );

      final json = result.toJson();
      expect(json['isRoadNarrowEnough'], isTrue);
      expect(json['isBlockingActive'], isTrue);
      expect(json['roadWidthMeters'], 4.0);
      expect(json['blockingSlots'], isA<List<dynamic>>());
    });
  });
}
