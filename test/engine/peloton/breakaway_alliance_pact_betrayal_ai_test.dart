import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/breakaway_alliance_pact_betrayal_ai.dart';

void main() {
  const ai = BreakawayAlliancePactBetrayalAi();

  const strongGentleman = BreakawayPactCandidate(
    riderId: 'r1',
    riderName: 'Janek',
    teamName: 'Team A',
    powerScore: 92.0,
    remainingWPrimeRatio: 0.80,
    sprintRating: 75,
    reputationScore: 0.88,
    pastPactsHonored: 8,
    pastPactsBetrayed: 0,
    pullContributionRatio: 0.85,
  );

  const strongReliable = BreakawayPactCandidate(
    riderId: 'r2',
    riderName: 'Tom',
    teamName: 'Team B',
    powerScore: 89.0,
    remainingWPrimeRatio: 0.70,
    sprintRating: 78,
    reputationScore: 0.72,
    pastPactsHonored: 5,
    pastPactsBetrayed: 1,
    pullContributionRatio: 0.75,
  );

  const weakerOpportunist = BreakawayPactCandidate(
    riderId: 'r3',
    riderName: 'Luc',
    teamName: 'Team C',
    powerScore: 80.0,
    remainingWPrimeRatio: 0.60,
    sprintRating: 70,
    reputationScore: 0.25,
    pastPactsHonored: 1,
    pastPactsBetrayed: 7,
    pullContributionRatio: 0.20,
  );

  group('BreakawayAlliancePactBetrayalAi', () {
    test('selects two strongest riders from breakaway', () {
      final topTwo = ai.selectTwoStrongestRiders([
        weakerOpportunist,
        strongReliable,
        strongGentleman,
      ]);

      expect(topTwo.length, 2);
      expect(topTwo[0].riderId, 'r1');
      expect(topTwo[1].riderId, 'r2');
    });

    test('forms active pact at 15 km and honors it at 1 km', () {
      final at15Km = ai.evaluatePactStep(
        const BreakawayPactStepInput(
          distanceToFinishKm: 15.0,
          pelotonGapSeconds: 40.0,
          candidates: [strongGentleman, strongReliable, weakerOpportunist],
        ),
      );

      expect(at15Km.pact, isNotNull);
      expect(at15Km.pact!.phase, BreakawayPactPhase.activePact);
      expect(
        at15Km.pact!.agreementText,
        BreakawayAlliancePactBetrayalAi.defaultPactPhrase,
      );
      expect(at15Km.speedBonusKmh, greaterThan(0.0));

      final at1Km = ai.evaluatePactStep(
        const BreakawayPactStepInput(
          distanceToFinishKm: 1.0,
          pelotonGapSeconds: 28.0,
          candidates: [strongGentleman, strongReliable, weakerOpportunist],
        ),
        existingPact: at15Km.pact,
      );

      expect(at1Km.pact!.phase, BreakawayPactPhase.pactHonoredEndgame);
      expect(at1Km.reputationDeltas['r1'], greaterThan(0.0));
      expect(at1Km.reputationDeltas['r2'], greaterThan(0.0));
    });

    test('rejects pact when partner reputation is too low', () {
      final lowTrustPartner = weakerOpportunist.copyWith(powerScore: 90.0);
      final result = ai.evaluatePactStep(
        BreakawayPactStepInput(
          distanceToFinishKm: 15.0,
          pelotonGapSeconds: 45.0,
          candidates: [strongGentleman, lowTrustPartner],
        ),
      );

      expect(result.pact, isNotNull);
      expect(result.pact!.phase, BreakawayPactPhase.rejected);
      expect(
        result.pact!.trustAnalysis.decision,
        PactProposalDecision.rejectedLowTrust,
      );
      expect(result.speedBonusKmh, 0.0);
    });

    test('triggers betrayal on steep kicker when betrayal probability is high',
        () {
      final borderlinePartner = strongReliable.copyWith(
        reputationScore: 0.45,
        pastPactsHonored: 2,
        pastPactsBetrayed: 3,
        pullContributionRatio: 0.40,
      );

      final init = ai.evaluatePactStep(
        BreakawayPactStepInput(
          distanceToFinishKm: 15.0,
          pelotonGapSeconds: 38.0,
          candidates: [strongGentleman, borderlinePartner],
        ),
      );
      expect(init.pact!.phase, BreakawayPactPhase.activePact);

      final betrayed = ai.evaluatePactStep(
        BreakawayPactStepInput(
          distanceToFinishKm: 4.5,
          pelotonGapSeconds: 35.0,
          currentGradientPercent: 8.5,
          candidates: [strongGentleman, borderlinePartner],
        ),
        existingPact: init.pact,
      );

      expect(betrayed.pact!.phase, BreakawayPactPhase.betrayed);
      expect(
        betrayed.pact!.betrayalReason,
        BetrayalTriggerReason.steepKickerAttack,
      );
      expect(betrayed.reputationDeltas[borderlinePartner.riderId], lessThan(0.0));
    });
  });

  group('BreakawayAlliancePactBetrayalPanel responsive layout', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets('renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BreakawayAlliancePactBetrayalPanel(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Mikro-Pakty Ucieczki Dnia (AI)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
