import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/gc_time_gap_panic_threshold_ai.dart';
import 'package:pro_peloton_manager/engine/peloton/peloton_chase_ai_controller.dart';

void main() {
  const ai = GcTimeGapPanicThresholdAi();

  List<PelotonDomestiqueCandidate> buildLeaderSquad() {
    return const [
      PelotonDomestiqueCandidate(
        riderId: 'leader_1',
        riderName: 'Tadej Leader',
        ftpWatts: 440,
        currentFatigueRatio: 0.10,
        isGcLeader: true,
      ),
      PelotonDomestiqueCandidate(
        riderId: 'dom_1',
        riderName: 'Domestique A',
        ftpWatts: 400,
        currentFatigueRatio: 0.15,
      ),
      PelotonDomestiqueCandidate(
        riderId: 'dom_2',
        riderName: 'Domestique B',
        ftpWatts: 390,
        currentFatigueRatio: 0.20,
      ),
      PelotonDomestiqueCandidate(
        riderId: 'dom_3',
        riderName: 'Domestique C',
        ftpWatts: 410,
        currentFatigueRatio: 0.25,
      ),
      PelotonDomestiqueCandidate(
        riderId: 'dom_4',
        riderName: 'Domestique D',
        ftpWatts: 380,
        currentFatigueRatio: 0.30,
      ),
      PelotonDomestiqueCandidate(
        riderId: 'dom_5',
        riderName: 'Domestique E (Tired)',
        ftpWatts: 420,
        currentFatigueRatio: 0.75,
      ),
    ];
  }

  group('GcTimeGapPanicThresholdAi', () {
    test(
        'wystawia 4 pomocników i podnosi tempo do 88% FTP gdy groźny kolarz ma < 4 min straty GC',
        () {
      final input = GcPanicThresholdInput(
        leaderTeamId: 'team_uae',
        leaderTeamName: 'UAE Team',
        gcLeaderRiderId: 'leader_1',
        breakawayGapSeconds: 110.0,
        breakawayCandidates: const [
          BreakawayGcThreatCandidate(
            riderId: 'rival_gc_1',
            riderName: 'Jonas Rival',
            teamId: 'team_visma',
            teamName: 'Team Visma',
            gcDeficitSeconds: 185.0, // 3m 05s < 4 min
            gcRank: 4,
          ),
        ],
        leaderTeamDomestiques: buildLeaderSquad(),
      );

      final decision = ai.evaluatePanicReaction(input);

      expect(decision.isPanicTriggered, isTrue);
      expect(decision.reactionLevel, GcPanicReactionLevel.panicPursuit);
      expect(decision.deployedDomestiquesCount, 4);
      expect(
        decision.deployedDomestiqueIds,
        equals(['dom_1', 'dom_2', 'dom_3', 'dom_4']),
      );
      expect(decision.deployedDomestiqueIds, isNot(contains('leader_1')));
      expect(decision.targetChaseFtpRatio, closeTo(0.88, 0.0001));
      expect(decision.recommendedChaseUrgency, ChaseUrgency.panicCatch);
      expect(decision.isVirtualGcLeaderThreat, isFalse);
      expect(decision.chaseCommitment, isNotNull);
      expect(decision.chaseCommitment!.domestiqueCount, 4);
      // Średnia FTP: (400 + 390 + 410 + 380) / 4 = 395; 395 * 0.88 = 347.6 -> 348W
      expect(decision.targetWattsPerDomestique, 348);
      expect(decision.chaseCommitment!.targetWattsPerRider, 348);
      expect(decision.radioAlertMessage, contains('88% FTP'));
      expect(decision.radioAlertMessage, contains('4 pomocników'));
    });

    test('nie uruchamia paniki na progu dokładnie >= 4 min (240 s)', () {
      final input = GcPanicThresholdInput(
        leaderTeamId: 'team_uae',
        leaderTeamName: 'UAE Team',
        gcLeaderRiderId: 'leader_1',
        breakawayGapSeconds: 120.0,
        breakawayCandidates: const [
          BreakawayGcThreatCandidate(
            riderId: 'rival_1',
            riderName: 'Watched Rider',
            teamId: 'team_ineos',
            teamName: 'INEOS',
            gcDeficitSeconds: 240.0, // dokładnie 4 min -> brak paniki
            gcRank: 7,
          ),
        ],
        leaderTeamDomestiques: buildLeaderSquad(),
      );

      final decision = ai.evaluatePanicReaction(input);

      expect(decision.isPanicTriggered, isFalse);
      expect(decision.reactionLevel, GcPanicReactionLevel.monitoring);
      expect(decision.deployedDomestiquesCount, 0);
      expect(decision.targetChaseFtpRatio,
          closeTo(GcTimeGapPanicThresholdAi.defaultBaselineFtpRatio, 0.0001));
      expect(decision.chaseCommitment, isNull);
    });

    test('ignoruje kolarzy własnej drużyny lidera oraz niegroźnych kolarzy', () {
      final input = GcPanicThresholdInput(
        leaderTeamId: 'team_uae',
        leaderTeamName: 'UAE Team',
        gcLeaderRiderId: 'leader_1',
        breakawayGapSeconds: 90.0,
        breakawayCandidates: const [
          BreakawayGcThreatCandidate(
            riderId: 'teammate_sat',
            riderName: 'Satellite Mate',
            teamId: 'team_uae',
            teamName: 'UAE Team',
            gcDeficitSeconds: 100.0,
          ),
          BreakawayGcThreatCandidate(
            riderId: 'non_threat',
            riderName: 'Pure Sprinter',
            teamId: 'team_alpecin',
            teamName: 'Alpecin',
            gcDeficitSeconds: 45.0,
            isDangerousContender: false,
          ),
        ],
        leaderTeamDomestiques: buildLeaderSquad(),
      );

      final decision = ai.evaluatePanicReaction(input);

      expect(decision.isPanicTriggered, isFalse);
      expect(decision.reactionLevel, GcPanicReactionLevel.none);
      expect(decision.deployedDomestiquesCount, 0);
    });

    test(
        'wykrywa wirtualną koszulkę lidera gdy przewaga ucieczki przekracza stratę GC',
        () {
      final input = GcPanicThresholdInput(
        leaderTeamId: 'team_uae',
        leaderTeamName: 'UAE Team',
        gcLeaderRiderId: 'leader_1',
        breakawayGapSeconds: 210.0,
        breakawayCandidates: const [
          BreakawayGcThreatCandidate(
            riderId: 'rival_gc_2',
            riderName: 'Remco Threat',
            teamId: 'team_soudal',
            teamName: 'Soudal',
            gcDeficitSeconds: 170.0, // 2m 50s < 4 min, a ucieczka ma 3m 30s
            gcRank: 3,
          ),
        ],
        leaderTeamDomestiques: buildLeaderSquad(),
      );

      final decision = ai.evaluatePanicReaction(input);

      expect(decision.isPanicTriggered, isTrue);
      expect(
        decision.reactionLevel,
        GcPanicReactionLevel.virtualLeaderEmergency,
      );
      expect(decision.isVirtualGcLeaderThreat, isTrue);
      expect(decision.virtualGcLeadSeconds, closeTo(40.0, 0.001));
      expect(decision.deployedDomestiquesCount, 4);
      expect(decision.targetChaseFtpRatio, closeTo(0.88, 0.0001));
    });

    test('obsługuje mniej niż 4 dostępnych pomocników oraz tryb czasówki', () {
      const fewDomestiquesInput = GcPanicThresholdInput(
        leaderTeamId: 'team_uae',
        leaderTeamName: 'UAE Team',
        gcLeaderRiderId: 'leader_1',
        breakawayGapSeconds: 100.0,
        breakawayCandidates: [
          BreakawayGcThreatCandidate(
            riderId: 'rival_gc_1',
            riderName: 'Close Rival',
            teamId: 'team_bora',
            teamName: 'Bora',
            gcDeficitSeconds: 120.0,
          ),
        ],
        leaderTeamDomestiques: [
          PelotonDomestiqueCandidate(
            riderId: 'dom_only_1',
            riderName: 'Solo Helper 1',
            ftpWatts: 400,
          ),
          PelotonDomestiqueCandidate(
            riderId: 'dom_only_2',
            riderName: 'Solo Helper 2',
            ftpWatts: 400,
          ),
          PelotonDomestiqueCandidate(
            riderId: 'dom_dropped',
            riderName: 'Dropped Helper',
            ftpWatts: 400,
            isAvailableInPeloton: false,
          ),
        ],
      );

      final fewDecision = ai.evaluatePanicReaction(fewDomestiquesInput);
      expect(fewDecision.isPanicTriggered, isTrue);
      expect(fewDecision.deployedDomestiquesCount, 2);
      expect(fewDecision.targetChaseFtpRatio, closeTo(0.88, 0.0001));

      final ttDecision =
          ai.evaluatePanicReaction(fewDomestiquesInput.copyWith(isTimeTrial: true));
      expect(ttDecision.isPanicTriggered, isFalse);
      expect(ttDecision.reactionLevel, GcPanicReactionLevel.none);
    });

    test('applyPanicOverrideToChasePlan nadpisuje plan pościgu peletonu', () {
      const basePlan = PelotonChasePlan(
        urgency: ChaseUrgency.controlledPacing,
        targetCatchKmRemaining: 7.5,
        projectedCatchKm: 172.5,
        requiredClawbackSecondsPer10Km: 35.0,
        actualClawbackSecondsPer10Km: 30.0,
        aiMiscalculationFactor: 1.0,
        breakawaySurvivalProbability: 0.40,
        committedTeams: [
          ChaseCommitment(
            teamId: 'team_uae',
            teamName: 'UAE Team',
            committedDomestiqueIds: ['dom_1'],
            targetWattsPerRider: 280,
            motive: 'Kontrola ucieczki',
          ),
        ],
        radioReport: 'Spokojna kontrola.',
      );

      final input = GcPanicThresholdInput(
        leaderTeamId: 'team_uae',
        leaderTeamName: 'UAE Team',
        gcLeaderRiderId: 'leader_1',
        breakawayGapSeconds: 140.0,
        breakawayCandidates: const [
          BreakawayGcThreatCandidate(
            riderId: 'rival_gc_1',
            riderName: 'Jonas Rival',
            teamId: 'team_visma',
            teamName: 'Team Visma',
            gcDeficitSeconds: 200.0,
          ),
        ],
        leaderTeamDomestiques: buildLeaderSquad(),
      );

      final updatedPlan = ai.applyPanicOverrideToChasePlan(
        basePlan: basePlan,
        input: input,
      );

      expect(updatedPlan.urgency, ChaseUrgency.panicCatch);
      expect(updatedPlan.totalDomestiquesWorking, 4);
      expect(updatedPlan.committedTeams.first.teamId, 'team_uae');
      expect(updatedPlan.committedTeams.first.targetWattsPerRider, 348);
      expect(updatedPlan.breakawaySurvivalProbability, lessThanOrEqualTo(0.12));
    });

    test('serializacja JSON zachowuje pełny stan wejścia i decyzji', () {
      final input = GcPanicThresholdInput(
        leaderTeamId: 'team_uae',
        leaderTeamName: 'UAE Team',
        gcLeaderRiderId: 'leader_1',
        breakawayGapSeconds: 130.0,
        breakawayCandidates: const [
          BreakawayGcThreatCandidate(
            riderId: 'rival_gc_1',
            riderName: 'Jonas Rival',
            teamId: 'team_visma',
            teamName: 'Team Visma',
            gcDeficitSeconds: 180.0,
          ),
        ],
        leaderTeamDomestiques: buildLeaderSquad(),
      );

      final roundTripInput = GcPanicThresholdInput.fromJson(input.toJson());
      final decision = ai.evaluatePanicReaction(roundTripInput);
      final roundTripDecision =
          GcPanicReactionDecision.fromJson(decision.toJson());

      expect(roundTripDecision.isPanicTriggered, isTrue);
      expect(roundTripDecision.deployedDomestiquesCount, 4);
      expect(roundTripDecision.targetChaseFtpRatio, closeTo(0.88, 0.0001));
      expect(roundTripDecision.mostDangerousRider?.riderId, 'rival_gc_1');
    });
  });
}
