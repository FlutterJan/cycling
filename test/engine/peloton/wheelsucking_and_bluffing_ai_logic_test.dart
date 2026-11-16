import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/peloton/wheelsucking_and_bluffing_ai_logic.dart';
import 'package:pro_peloton_manager/engine/simulation/tactical_ai_personality_profiles.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';

RiderRaceState _buildState(String riderId, {String teamId = 'team_a'}) {
  return RiderRaceState.initial(
    riderId: riderId,
    teamId: teamId,
    initialWPrimeJoules: 22000,
    initialGlycogenGrams: 420,
  );
}

void main() {
  group('WheelsuckingAndBluffingAiLogic', () {
    test('odmawia zmian (Skip Pulls / Sit On), gdy sprinter drużyny jedzie w peletonie z tyłu', () {
      final decision = WheelsuckingAndBluffingAiLogic.evaluateRiderDecision(
        WheelsuckingAiInput(
          riderId: 'r1',
          teamId: 'team_a',
          specialization: RiderSpecialization.domestiqueEngine,
          riderState: _buildState('r1'),
          hasTeamSprinterInPelotonBehind: true,
          pelotonGapSeconds: 95.0,
          distanceToFinishKm: 28.0,
          riderWPrimeRatio: 0.35,
          riderFatigueRatio: 0.70,
          riderSprintRating: 60,
          breakawaySize: 4,
          rivalsInBreakawayCount: 3,
          rivalFrustrationIndex: 0.50,
          currentGroupSpeedMs: 12.2,
          basePullPowerWatts: 360.0,
        ),
      );

      expect(decision.mode, WheelsuckingTacticMode.skipPullsSitOn);
      expect(decision.justification, SitOnJustification.sprinterInPelotonBehind);
      expect(decision.pullContributionRatio, 0.0);
      expect(decision.isRefusingPulls, isTrue);
      expect(decision.expectedRivalReaction, RivalReactionType.frustratedPaceSurge);
      expect(decision.wPrimeSavedWatts, greaterThan(80.0));
    });

    test('odmawia zmian i blefuje zmęczenie (Poker Face), gdy lider GC jest z tyłu a W\' wysokie', () {
      final decision = WheelsuckingAndBluffingAiLogic.evaluateRiderDecision(
        WheelsuckingAiInput(
          riderId: 'r2',
          teamId: 'team_a',
          specialization: RiderSpecialization.puncher,
          archetype: TacticalAiArchetype.wheelsuckerOpportunist,
          riderState: _buildState('r2'),
          hasTeamLeaderInPelotonBehind: true,
          pelotonGapSeconds: 140.0,
          distanceToFinishKm: 18.0,
          riderWPrimeRatio: 0.85,
          riderFatigueRatio: 0.25,
          riderSprintRating: 78,
          breakawaySize: 3,
          rivalsInBreakawayCount: 2,
          rivalFrustrationIndex: 0.82,
          currentGroupSpeedMs: 11.5,
          basePullPowerWatts: 380.0,
        ),
      );

      expect(decision.mode, WheelsuckingTacticMode.bluffingPainFace);
      expect(decision.justification, SitOnJustification.gcLeaderInPelotonBehind);
      expect(decision.bluffIntensity, greaterThan(0.7));
      expect(decision.expectedRivalReaction, RivalReactionType.furiousAttack);
    });

    test('współpracuje normalnie przy braku interesu w peletonie i braku profilu pasożyta', () {
      final decision = WheelsuckingAndBluffingAiLogic.evaluateRiderDecision(
        WheelsuckingAiInput(
          riderId: 'r3',
          teamId: 'team_b',
          specialization: RiderSpecialization.breakawaySpecialist,
          archetype: TacticalAiArchetype.breakawayHunter,
          riderState: _buildState('r3', teamId: 'team_b'),
          hasTeamSprinterInPelotonBehind: false,
          hasTeamLeaderInPelotonBehind: false,
          pelotonGapSeconds: 180.0,
          distanceToFinishKm: 45.0,
          riderWPrimeRatio: 0.75,
          riderFatigueRatio: 0.30,
          riderSprintRating: 65,
          breakawaySize: 4,
          rivalsInBreakawayCount: 3,
          currentGroupSpeedMs: 12.0,
          basePullPowerWatts: 350.0,
        ),
      );

      expect(decision.mode, WheelsuckingTacticMode.cooperative);
      expect(decision.justification, SitOnJustification.none);
      expect(decision.pullContributionRatio, 1.0);
      expect(decision.recommendedOrder, TacticalOrder.pullGroup);
    });

    test('na ostatnim kilometrze uruchamia grę nerwów i oglądanie się za siebie, a w końcówce kontratak', () {
      final standoffDecision = WheelsuckingAndBluffingAiLogic.evaluateRiderDecision(
        WheelsuckingAiInput(
          riderId: 'r4',
          teamId: 'team_a',
          specialization: RiderSpecialization.puncher,
          riderState: _buildState('r4'),
          hasTeamSprinterInPelotonBehind: true,
          pelotonGapSeconds: 45.0,
          distanceToFinishKm: 0.85,
          riderWPrimeRatio: 0.70,
          riderFatigueRatio: 0.40,
          riderSprintRating: 80,
          breakawaySize: 3,
          rivalsInBreakawayCount: 2,
          rivalFrustrationIndex: 0.65,
          currentGroupSpeedMs: 12.5,
          basePullPowerWatts: 400.0,
        ),
      );

      expect(standoffDecision.mode, WheelsuckingTacticMode.finalKmStandoff);
      expect(standoffDecision.lookBackFrequencyHz, greaterThan(0.3));
      expect(standoffDecision.targetSpeedFactor, lessThan(1.0));
      expect(standoffDecision.expectedRivalReaction, RivalReactionType.lookBackSlowdown);

      final ambushDecision = WheelsuckingAndBluffingAiLogic.evaluateRiderDecision(
        WheelsuckingAiInput(
          riderId: 'r4',
          teamId: 'team_a',
          specialization: RiderSpecialization.puncher,
          riderState: _buildState('r4'),
          hasTeamSprinterInPelotonBehind: true,
          pelotonGapSeconds: 45.0,
          distanceToFinishKm: 0.20,
          riderWPrimeRatio: 0.70,
          riderFatigueRatio: 0.40,
          riderSprintRating: 80,
          breakawaySize: 3,
          rivalsInBreakawayCount: 2,
          rivalFrustrationIndex: 0.65,
          currentGroupSpeedMs: 12.5,
          basePullPowerWatts: 400.0,
        ),
      );

      expect(ambushDecision.mode, WheelsuckingTacticMode.counterAttackAmbush);
      expect(ambushDecision.recommendedOrder, TacticalOrder.attack);
      expect(ambushDecision.targetSpeedFactor, greaterThan(1.1));
    });

    test('evaluateGroup agreguje pasywność i wykrywa szarpanie tempa oraz serializuje decyzje', () {
      final evaluation = WheelsuckingAndBluffingAiLogic.evaluateGroup([
        WheelsuckingAiInput(
          riderId: 'r1',
          teamId: 'team_a',
          specialization: RiderSpecialization.domestiqueEngine,
          riderState: _buildState('r1'),
          hasTeamSprinterInPelotonBehind: true,
          pelotonGapSeconds: 80.0,
          distanceToFinishKm: 15.0,
          riderWPrimeRatio: 0.60,
          riderFatigueRatio: 0.40,
          riderSprintRating: 65,
          breakawaySize: 2,
          rivalsInBreakawayCount: 1,
          rivalFrustrationIndex: 0.55,
          currentGroupSpeedMs: 12.0,
          basePullPowerWatts: 360.0,
        ),
        WheelsuckingAiInput(
          riderId: 'r2',
          teamId: 'team_b',
          specialization: RiderSpecialization.breakawaySpecialist,
          riderState: _buildState('r2', teamId: 'team_b'),
          pelotonGapSeconds: 80.0,
          distanceToFinishKm: 15.0,
          riderWPrimeRatio: 0.50,
          riderFatigueRatio: 0.55,
          riderSprintRating: 62,
          breakawaySize: 2,
          rivalsInBreakawayCount: 1,
          currentGroupSpeedMs: 12.0,
          basePullPowerWatts: 360.0,
        ),
      ]);

      expect(evaluation.wheelsuckerCount, 1);
      expect(evaluation.paceSurgesTriggered, isTrue);
      expect(evaluation.paceSurgeIntensity, greaterThan(0.0));
      expect(evaluation.groupCooperationMultiplier, lessThan(1.0));

      final original = evaluation.decisionsByRiderId['r1']!;
      final roundTrip = WheelsuckingAiDecision.fromJson(original.toJson());
      expect(roundTrip.riderId, original.riderId);
      expect(roundTrip.mode, original.mode);
      expect(roundTrip.justification, original.justification);
      expect(roundTrip.targetPowerWatts, original.targetPowerWatts);
    });
  });
}
