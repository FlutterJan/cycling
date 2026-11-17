import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/in_race_peloton_diplomacy_engine.dart';

void main() {
  const playerTeam = DiplomacyTeamContext(
    teamId: 'team_player',
    teamName: 'Pro Peloton Racing',
    riderId: 'rider_player_gc',
    riderName: 'Jan Kowalski',
    gcPosition: 2,
    gcGapToLeaderSeconds: 32.0,
    isRaceLeader: false,
    hasStageWinAmbition: false,
    trustScore: 80.0,
  );

  const stageHunterTeam = DiplomacyTeamContext(
    teamId: 'team_hunter',
    teamName: 'Alpecin Hunters',
    riderId: 'rider_hunter',
    riderName: 'Marc Dupont',
    gcPosition: 28,
    gcGapToLeaderSeconds: 920.0,
    isRaceLeader: false,
    hasStageWinAmbition: true,
    trustScore: 72.0,
  );

  const rivalGcTeam = DiplomacyTeamContext(
    teamId: 'team_rival_gc',
    teamName: 'Nordic Sky',
    riderId: 'rider_rival_gc',
    riderName: 'Erik Lindqvist',
    gcPosition: 3,
    gcGapToLeaderSeconds: 58.0,
    isRaceLeader: false,
    hasStageWinAmbition: true,
    trustScore: 70.0,
    aggressionFactor: 0.78,
  );

  const raceLeaderTeam = DiplomacyTeamContext(
    teamId: 'team_leader',
    teamName: 'Yellow Armada',
    riderId: 'rider_leader',
    riderName: 'Pierre Moreau',
    gcPosition: 1,
    gcGapToLeaderSeconds: 0.0,
    isRaceLeader: true,
    hasStageWinAmbition: true,
    trustScore: 75.0,
  );

  group('InRacePelotonDiplomacyEngine — Pakty i Sojusze', () {
    test('Stage for GC Deal zostaje zaakceptowany przez łowcę etapów', () {
      const state = PelotonDiplomacyState();
      final res = InRacePelotonDiplomacyEngine.proposePact(
        state: state,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: stageHunterTeam,
        currentStageKm: 120.0,
        totalStageKm: 175.0,
      );

      expect(res.outcome.accepted, isTrue);
      expect(res.outcome.createdPact, isNotNull);
      expect(
          res.outcome.createdPact!.type, DiplomacyPactType.stageForGcDeal);
      expect(res.nextState.activePacts.length, 1);
    });

    test('Stage for GC Deal odrzucony przez bliskiego rywala GC', () {
      const state = PelotonDiplomacyState();
      final res = InRacePelotonDiplomacyEngine.proposePact(
        state: state,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: rivalGcTeam,
        currentStageKm: 130.0,
        totalStageKm: 175.0,
      );

      expect(res.outcome.accepted, isFalse);
      expect(res.outcome.createdPact, isNull);
      expect(res.nextState.activePacts, isEmpty);
    });

    test('Anti-Leader Coalition odrzuca lidera wyścigu, akceptuje rywala GC',
        () {
      const state = PelotonDiplomacyState();
      final leaderRes = InRacePelotonDiplomacyEngine.proposePact(
        state: state,
        type: DiplomacyPactType.antiLeaderCoalition,
        initiator: playerTeam,
        partner: raceLeaderTeam,
        currentStageKm: 140.0,
        totalStageKm: 175.0,
        targetLeaderTeamId: raceLeaderTeam.teamId,
      );
      expect(leaderRes.outcome.accepted, isFalse);

      final rivalRes = InRacePelotonDiplomacyEngine.proposePact(
        state: state,
        type: DiplomacyPactType.antiLeaderCoalition,
        initiator: playerTeam,
        partner: rivalGcTeam,
        currentStageKm: 140.0,
        totalStageKm: 175.0,
        targetLeaderTeamId: raceLeaderTeam.teamId,
      );
      expect(rivalRes.outcome.accepted, isTrue);

      final step = InRacePelotonDiplomacyEngine.stepDiplomacy(
        state: rivalRes.nextState,
        currentStageKm: 142.0,
        totalStageKm: 175.0,
        observations: const [
          RiderDiplomacyActionObservation(
            riderId: 'rider_player_gc',
            teamId: 'team_player',
            pullEffortRatio: 0.9,
          ),
          RiderDiplomacyActionObservation(
            riderId: 'rider_rival_gc',
            teamId: 'team_rival_gc',
            pullEffortRatio: 0.9,
          ),
        ],
      );

      expect(
        step.modifiersByTeam['team_player']?.antiLeaderChaseBoostActive,
        isTrue,
      );
      expect(
        step.modifiersByTeam['team_rival_gc']?.pullCooperationMultiplier,
        greaterThan(1.2),
      );
    });

    test('Neutralization Truce tłumi ataki, a złamanie wyzwala Betrayal!', () {
      const state = PelotonDiplomacyState();
      final proposed = InRacePelotonDiplomacyEngine.proposePact(
        state: state,
        type: DiplomacyPactType.neutralizationTruce,
        initiator: playerTeam,
        partner: rivalGcTeam,
        currentStageKm: 80.0,
        totalStageKm: 175.0,
        isCrashOrHazardNeutralization: true,
      );
      expect(proposed.outcome.accepted, isTrue);

      final calmStep = InRacePelotonDiplomacyEngine.stepDiplomacy(
        state: proposed.nextState,
        currentStageKm: 82.0,
        totalStageKm: 175.0,
        observations: const [
          RiderDiplomacyActionObservation(
            riderId: 'rider_player_gc',
            teamId: 'team_player',
          ),
        ],
      );
      expect(
          calmStep.modifiersByTeam['team_player']?.attacksSuppressed, isTrue);
      expect(calmStep.newBetrayals, isEmpty);

      // Zdrada poprzez atak podczas rozejmu
      final betrayalStep = InRacePelotonDiplomacyEngine.stepDiplomacy(
        state: calmStep.nextState,
        currentStageKm: 83.0,
        totalStageKm: 175.0,
        observations: const [
          RiderDiplomacyActionObservation(
            riderId: 'rider_player_gc',
            teamId: 'team_player',
            didAttackThisStep: true,
          ),
        ],
      );

      expect(betrayalStep.newBetrayals.length, 1);
      expect(
        betrayalStep.newBetrayals.first.reason,
        BetrayalReason.attackedDuringTruce,
      );
      expect(betrayalStep.nextState.activePacts, isEmpty);
      expect(
        betrayalStep.nextState.vendettaForTeam('team_rival_gc'),
        greaterThan(0),
      );
      expect(
        betrayalStep.nextState.playerPelotonReputation,
        lessThan(state.playerPelotonReputation),
      );
    });

    test(
        'Stage for GC Deal: sprint w ostatnim 1.2 km wyzwala zdradę i wendetę',
        () {
      const state = PelotonDiplomacyState();
      final proposed = InRacePelotonDiplomacyEngine.proposePact(
        state: state,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: stageHunterTeam,
        currentStageKm: 130.0,
        totalStageKm: 175.0,
      );
      expect(proposed.outcome.accepted, isTrue);

      final sprintBetrayal = InRacePelotonDiplomacyEngine.stepDiplomacy(
        state: proposed.nextState,
        currentStageKm: 174.2,
        totalStageKm: 175.0,
        observations: const [
          RiderDiplomacyActionObservation(
            riderId: 'rider_player_gc',
            teamId: 'team_player',
            didSprintForStageFinish: true,
          ),
        ],
      );

      expect(sprintBetrayal.newBetrayals.length, 1);
      expect(
        sprintBetrayal.newBetrayals.first.reason,
        BetrayalReason.sprintedForPromisedStage,
      );
      expect(
        sprintBetrayal.nextState.isTeamHostile('team_hunter'),
        isTrue,
      );

      // Kolejna próba negocjacji z tą ekipą zostaje odrzucona przez wendetę.
      final rejectedFollowup = InRacePelotonDiplomacyEngine.proposePact(
        state: sprintBetrayal.nextState,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: stageHunterTeam,
        currentStageKm: 174.5,
        totalStageKm: 175.0,
      );
      expect(rejectedFollowup.outcome.accepted, isFalse);
    });

    test('Ręczna zdrada i wygaszanie wendety między etapami + JSON round-trip',
        () {
      const state = PelotonDiplomacyState();
      final proposed = InRacePelotonDiplomacyEngine.proposePact(
        state: state,
        type: DiplomacyPactType.antiLeaderCoalition,
        initiator: playerTeam,
        partner: rivalGcTeam,
        currentStageKm: 140.0,
        totalStageKm: 175.0,
        targetLeaderTeamId: raceLeaderTeam.teamId,
      );
      final pact = proposed.outcome.createdPact!;

      final manual = InRacePelotonDiplomacyEngine.triggerManualBetrayal(
        state: proposed.nextState,
        pactId: pact.pactId,
        betrayerTeamId: playerTeam.teamId,
        currentStageKm: 155.0,
      );

      expect(manual.event.severity, BetrayalSeverity.severe);
      final vendettaBefore =
          manual.nextState.vendettaForTeam(rivalGcTeam.teamId);
      expect(vendettaBefore, greaterThan(1));

      final decayed = InRacePelotonDiplomacyEngine.decayVendettasBetweenStages(
        manual.nextState,
      );
      expect(
        decayed.vendettaForTeam(rivalGcTeam.teamId),
        vendettaBefore - 1,
      );
      expect(decayed.latestBetrayalAlert, isNull);

      final roundTrip = PelotonDiplomacyState.fromJson(
        manual.nextState.toJson(),
      );
      expect(
        roundTrip.playerPelotonReputation,
        manual.nextState.playerPelotonReputation,
      );
      expect(roundTrip.betrayalHistory.length, 1);
      expect(
        roundTrip.vendettaForTeam(rivalGcTeam.teamId),
        vendettaBefore,
      );
    });
  });

  group('InRacePelotonDiplomacyPanel — Responsywność i Interakcja', () {
    Future<void> pumpPanelAtSize(
      WidgetTester tester,
      Size size, {
      required PelotonDiplomacyState state,
      ValueChanged<DiplomacyPactType>? onPropose,
      ValueChanged<String>? onBetray,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InRacePelotonDiplomacyPanel(
                diplomacyState: state,
                rivalCandidates: const [stageHunterTeam, rivalGcTeam],
                selectedPartnerTeamId: stageHunterTeam.teamId,
                currentStageKm: 142.5,
                onSelectPartnerTeam: (_) {},
                onProposePact: onPropose ?? (_) {},
                onBetrayPact: onBetray ?? (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('Renderuje się bez przepełnień w 390x844, 1024x768 i 1600x900',
        (tester) async {
      final proposed = InRacePelotonDiplomacyEngine.proposePact(
        state: const PelotonDiplomacyState(),
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: stageHunterTeam,
        currentStageKm: 135.0,
        totalStageKm: 175.0,
      );

      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await pumpPanelAtSize(tester, size, state: proposed.nextState);
        expect(find.text('DYPLOMACJA NA SZOSIE'), findsOneWidget);
        expect(find.text('Stage for GC Deal'), findsOneWidget);
        expect(find.text('Zdradź (Betrayal!)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Obsługuje kliknięcie propozycji paktu oraz zdrady',
        (tester) async {
      DiplomacyPactType? proposedType;
      String? betrayedPactId;

      final proposed = InRacePelotonDiplomacyEngine.proposePact(
        state: const PelotonDiplomacyState(),
        type: DiplomacyPactType.neutralizationTruce,
        initiator: playerTeam,
        partner: rivalGcTeam,
        currentStageKm: 90.0,
        totalStageKm: 175.0,
        isCrashOrHazardNeutralization: true,
      );

      await pumpPanelAtSize(
        tester,
        const Size(1024, 768),
        state: proposed.nextState,
        onPropose: (type) => proposedType = type,
        onBetray: (id) => betrayedPactId = id,
      );

      await tester.tap(find.text('Anti-Leader Coalition'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(proposedType, DiplomacyPactType.antiLeaderCoalition);

      await tester.tap(find.text('Zdradź (Betrayal!)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(betrayedPactId, proposed.outcome.createdPact!.pactId);
    });
  });
}
