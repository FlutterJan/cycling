import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/in_race_peloton_diplomacy_engine.dart';
import 'package:pro_peloton_manager/services/career/ai_rivalry_grudge_memory_service.dart';
import 'package:pro_peloton_manager/ui/widgets/in_race_diplomacy_radio_modal.dart';

void main() {
  group('InRacePelotonDiplomacyEngine — pakty, zdrady i wendety', () {
    const playerTeam = DiplomacyTeamContext(
      teamId: 'team_player',
      teamName: 'Polonia Pro Cycling',
      riderId: 'rider_p1',
      riderName: 'Jan Kowalski',
      gcPosition: 2,
      gcGapToLeaderSeconds: 24.0,
      hasStageWinAmbition: false,
    );

    const breakawayStageHunter = DiplomacyTeamContext(
      teamId: 'team_hunter',
      teamName: 'Alpine Breakaway',
      riderId: 'rider_h1',
      riderName: 'Marco Rossi',
      gcPosition: 48,
      gcGapToLeaderSeconds: 1420.0,
      hasStageWinAmbition: true,
      trustScore: 70.0,
    );

    const closeGcRival = DiplomacyTeamContext(
      teamId: 'team_gc_rival',
      teamName: 'Iberia Movers',
      riderId: 'rider_r1',
      riderName: 'Carlos Vega',
      gcPosition: 3,
      gcGapToLeaderSeconds: 45.0,
      hasStageWinAmbition: true,
      trustScore: 75.0,
      aggressionFactor: 0.85,
    );

    const raceLeader = DiplomacyTeamContext(
      teamId: 'team_leader',
      teamName: 'Nordic Sky',
      riderId: 'rider_l1',
      riderName: 'Erik Lind',
      gcPosition: 1,
      gcGapToLeaderSeconds: 0.0,
      isRaceLeader: true,
      trustScore: 70.0,
    );

    test('odrzuca pakt wewnątrz własnej drużyny oraz poza grupą', () {
      const initialState = PelotonDiplomacyState();

      final selfResult = InRacePelotonDiplomacyEngine.proposePact(
        state: initialState,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: playerTeam,
        currentStageKm: 120.0,
        totalStageKm: 180.0,
      );
      expect(selfResult.outcome.accepted, isFalse);
      expect(selfResult.outcome.createdPact, isNull);

      final outOfGroup = breakawayStageHunter.copyWith(isInSameGroup: false);
      final groupResult = InRacePelotonDiplomacyEngine.proposePact(
        state: initialState,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: outOfGroup,
        currentStageKm: 120.0,
        totalStageKm: 180.0,
      );
      expect(groupResult.outcome.accepted, isFalse);
      expect(groupResult.nextState.activePacts, isEmpty);
    });

    test('Stage for GC Deal: akceptowany przez łowcę etapów, odrzucany przez rywala GC', () {
      const initialState = PelotonDiplomacyState();

      final acceptedRes = InRacePelotonDiplomacyEngine.proposePact(
        state: initialState,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: breakawayStageHunter,
        currentStageKm: 135.0,
        totalStageKm: 185.0,
      );
      expect(acceptedRes.outcome.accepted, isTrue);
      expect(acceptedRes.outcome.createdPact, isNotNull);
      expect(
        acceptedRes.outcome.createdPact!.stageWinnerTeamId,
        breakawayStageHunter.teamId,
      );
      expect(acceptedRes.nextState.activePacts.length, 1);

      final rejectedRes = InRacePelotonDiplomacyEngine.proposePact(
        state: initialState,
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: closeGcRival,
        currentStageKm: 135.0,
        totalStageKm: 185.0,
      );
      expect(rejectedRes.outcome.accepted, isFalse);
      expect(rejectedRes.outcome.acceptanceScore, lessThan(0.5));
    });

    test('Anti-Leader Coalition: odrzucana przez lidera, akceptowana przez rywala GC', () {
      const initialState = PelotonDiplomacyState();

      final leaderReject = InRacePelotonDiplomacyEngine.proposePact(
        state: initialState,
        type: DiplomacyPactType.antiLeaderCoalition,
        initiator: playerTeam,
        partner: raceLeader,
        currentStageKm: 150.0,
        totalStageKm: 190.0,
        targetLeaderTeamId: raceLeader.teamId,
      );
      expect(leaderReject.outcome.accepted, isFalse);

      final coalitionAccept = InRacePelotonDiplomacyEngine.proposePact(
        state: initialState,
        type: DiplomacyPactType.antiLeaderCoalition,
        initiator: playerTeam,
        partner: closeGcRival,
        currentStageKm: 150.0,
        totalStageKm: 190.0,
        targetLeaderTeamId: raceLeader.teamId,
      );
      expect(coalitionAccept.outcome.accepted, isTrue);
      expect(
        coalitionAccept.outcome.createdPact!.targetLeaderTeamId,
        raceLeader.teamId,
      );
    });

    test('dotrzymanie paktu do mety zwiększa zaufanie i reputację w peletonie', () {
      final proposed = InRacePelotonDiplomacyEngine.proposePact(
        state: const PelotonDiplomacyState(),
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: breakawayStageHunter,
        currentStageKm: 140.0,
        totalStageKm: 180.0,
      );

      final stepResult = InRacePelotonDiplomacyEngine.stepDiplomacy(
        state: proposed.nextState,
        currentStageKm: 179.96,
        totalStageKm: 180.0,
        observations: const [
          RiderDiplomacyActionObservation(
            riderId: 'rider_p1',
            teamId: 'team_player',
            pullEffortRatio: 0.85,
          ),
          RiderDiplomacyActionObservation(
            riderId: 'rider_h1',
            teamId: 'team_hunter',
            pullEffortRatio: 0.90,
          ),
        ],
      );

      expect(stepResult.newBetrayals, isEmpty);
      expect(stepResult.newlyResolvedPacts.length, 1);
      expect(
        stepResult.newlyResolvedPacts.first.status,
        DiplomacyPactStatus.fulfilled,
      );
      expect(stepResult.nextState.activePacts, isEmpty);
      expect(
        stepResult.nextState.trustForTeam(breakawayStageHunter.teamId),
        greaterThan(65.0),
      );
      expect(
        stepResult.nextState.playerPelotonReputation,
        greaterThan(72.0),
      );
    });

    test('zdrada podczas Neutralization Truce wywołuje wendetę i blokuje nowe pakty', () {
      final truce = InRacePelotonDiplomacyEngine.proposePact(
        state: const PelotonDiplomacyState(),
        type: DiplomacyPactType.neutralizationTruce,
        initiator: playerTeam,
        partner: closeGcRival,
        currentStageKm: 100.0,
        totalStageKm: 180.0,
        isCrashOrHazardNeutralization: true,
      );
      expect(truce.outcome.accepted, isTrue);

      final step = InRacePelotonDiplomacyEngine.stepDiplomacy(
        state: truce.nextState,
        currentStageKm: 103.0,
        totalStageKm: 180.0,
        observations: const [
          RiderDiplomacyActionObservation(
            riderId: 'rider_p1',
            teamId: 'team_player',
            didAttackThisStep: true,
          ),
          RiderDiplomacyActionObservation(
            riderId: 'rider_r1',
            teamId: 'team_gc_rival',
          ),
        ],
      );

      expect(step.newBetrayals.length, 1);
      final betrayal = step.newBetrayals.first;
      expect(betrayal.reason, BetrayalReason.attackedDuringTruce);
      expect(betrayal.severity, BetrayalSeverity.infamous);
      expect(betrayal.vendettaStagesAssigned, 6);
      expect(step.nextState.vendettaForTeam(closeGcRival.teamId), 6);
      expect(step.nextState.isTeamHostile(closeGcRival.teamId), isTrue);

      final rivalModifiers = step.modifiersByTeam[closeGcRival.teamId]!;
      expect(rivalModifiers.refusesCooperationWithPlayer, isTrue);
      expect(rivalModifiers.rivalChaseHostilityMultiplier, 1.45);

      // Kolejna próba zawarcia koalicji przy aktywnej wendecie jest odrzucana.
      final blocked = InRacePelotonDiplomacyEngine.proposePact(
        state: step.nextState,
        type: DiplomacyPactType.antiLeaderCoalition,
        initiator: playerTeam,
        partner: closeGcRival,
        currentStageKm: 140.0,
        totalStageKm: 180.0,
        targetLeaderTeamId: raceLeader.teamId,
      );
      expect(blocked.outcome.accepted, isFalse);
      expect(blocked.outcome.rationale, contains('wendeta'));
    });

    test('wykrywa finisz po obiecaną wygraną oraz odmowę zmian w układzie', () {
      final deal = InRacePelotonDiplomacyEngine.proposePact(
        state: const PelotonDiplomacyState(),
        type: DiplomacyPactType.stageForGcDeal,
        initiator: playerTeam,
        partner: breakawayStageHunter,
        currentStageKm: 140.0,
        totalStageKm: 180.0,
      );

      final sprintBetrayal = InRacePelotonDiplomacyEngine.stepDiplomacy(
        state: deal.nextState,
        currentStageKm: 179.3,
        totalStageKm: 180.0,
        observations: const [
          RiderDiplomacyActionObservation(
            riderId: 'rider_p1',
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

      // Test odmowy zmian przez 3 kolejne kroki.
      var state = deal.nextState;
      DiplomacyStepResult? lazyStep;
      for (int i = 0; i < 3; i++) {
        lazyStep = InRacePelotonDiplomacyEngine.stepDiplomacy(
          state: state,
          currentStageKm: 145.0 + i,
          totalStageKm: 180.0,
          observations: const [
            RiderDiplomacyActionObservation(
              riderId: 'rider_p1',
              teamId: 'team_player',
              pullEffortRatio: 0.1,
            ),
          ],
        );
        state = lazyStep.nextState;
      }
      expect(lazyStep!.newBetrayals.length, 1);
      expect(
        lazyStep.newBetrayals.first.reason,
        BetrayalReason.refusedAgreedPulls,
      );
    });

    test('ręczne zerwanie paktu i międzyetapowe wygaszanie wendety + JSON round-trip', () {
      final proposed = InRacePelotonDiplomacyEngine.proposePact(
        state: const PelotonDiplomacyState(),
        type: DiplomacyPactType.antiLeaderCoalition,
        initiator: playerTeam,
        partner: closeGcRival,
        currentStageKm: 145.0,
        totalStageKm: 180.0,
        targetLeaderTeamId: raceLeader.teamId,
      );

      final manual = InRacePelotonDiplomacyEngine.triggerManualBetrayal(
        state: proposed.nextState,
        pactId: proposed.outcome.createdPact!.pactId,
        betrayerTeamId: playerTeam.teamId,
        currentStageKm: 155.0,
      );
      expect(manual.event.reason, BetrayalReason.manualPactBreach);
      expect(manual.nextState.activePacts, isEmpty);
      expect(manual.nextState.vendettaForTeam(closeGcRival.teamId), 4);

      final restored =
          PelotonDiplomacyState.fromJson(manual.nextState.toJson());
      expect(restored.vendettaForTeam(closeGcRival.teamId), 4);
      expect(restored.betrayalHistory.length, 1);
      expect(restored.historicalPacts.length, 1);

      final afterStage =
          InRacePelotonDiplomacyEngine.decayVendettasBetweenStages(restored);
      expect(afterStage.vendettaForTeam(closeGcRival.teamId), 3);
      expect(afterStage.latestBetrayalAlert, isNull);
      expect(
        afterStage.trustForTeam(closeGcRival.teamId),
        greaterThan(restored.trustForTeam(closeGcRival.teamId)),
      );
    });
  });

  group('AiRivalryGrudgeMemoryService — pamięć urazów, przyjaźni i wygaszanie', () {
    const service = AiRivalryGrudgeMemoryService();

    test('canonicalBondKey jest symetryczny niezależnie od kolejności ID', () {
      expect(
        AiRivalryGrudgeMemoryService.canonicalBondKey('rider_b', 'rider_a'),
        AiRivalryGrudgeMemoryService.canonicalBondKey('rider_a', 'rider_b'),
      );
    });

    test('kumulacja urazów prowadzi do Blood Feud i modyfikatorów wrogości AI', () {
      var state = AiRivalryGrudgeMemoryState.empty(seasonYear: 2026);

      state = service.recordIncident(
        state,
        riderAId: 'r_player',
        riderBId: 'r_rival',
        riderAName: 'Jan Kowalski',
        riderBName: 'Lukas Novak',
        riderATeam: 'Polonia Pro',
        riderBTeam: 'Bohemia Cycling',
        incidentType: RelationshipIncidentType.breakawayBetrayal,
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        stageNumber: 11,
        timestamp: DateTime(2026, 7, 15),
      );

      state = service.recordIncident(
        state,
        riderAId: 'r_player',
        riderBId: 'r_rival',
        riderAName: 'Jan Kowalski',
        riderBName: 'Lukas Novak',
        riderATeam: 'Polonia Pro',
        riderBTeam: 'Bohemia Cycling',
        incidentType: RelationshipIncidentType.dangerousSprintDeviation,
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        stageNumber: 12,
        timestamp: DateTime(2026, 7, 16),
      );

      // -28 + -36 = -64, jeszcze jeden drobniejszy uraz daje <= -65 (bloodFeud)
      state = service.recordIncident(
        state,
        riderAId: 'r_player',
        riderBId: 'r_rival',
        riderAName: 'Jan Kowalski',
        riderBName: 'Lukas Novak',
        riderATeam: 'Polonia Pro',
        riderBTeam: 'Bohemia Cycling',
        incidentType: RelationshipIncidentType.publicMediaInsult,
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        stageNumber: 13,
        timestamp: DateTime(2026, 7, 17),
      );

      final mods = service.evaluateTacticalModifiers(
        state,
        observerRiderId: 'r_rival',
        targetRiderId: 'r_player',
      );
      expect(mods.polarity, PelotonRelationshipPolarity.bloodFeud);
      expect(mods.chaseAggressionMultiplier, 1.45);
      expect(mods.breakawayCooperationFactor, lessThan(0.20));
      expect(mods.diplomacyAcceptanceBonus, lessThan(-0.30));
      expect(mods.transferVetoRisk, isTrue);
      expect(mods.sprintBlockingRisk, greaterThan(0.20));
      expect(state.activeVendettasCount, 1);
      expect(service.getTopRivalries(state).length, 1);
    });

    test('przyjaźń i fair play budują Peloton Brotherhood oraz rabat transferowy', () {
      var state = AiRivalryGrudgeMemoryState.empty(seasonYear: 2026);

      for (final type in const [
        RelationshipIncidentType.sportsmanlikeWaitAfterCrash,
        RelationshipIncidentType.bottleOrWheelShare,
        RelationshipIncidentType.sharedBreakawayWork,
      ]) {
        state = service.recordIncident(
          state,
          riderAId: 'r_player',
          riderBId: 'r_ally',
          riderAName: 'Jan Kowalski',
          riderBName: 'Pierre Moreau',
          riderATeam: 'Polonia Pro',
          riderBTeam: 'Gallia Team',
          incidentType: type,
          raceId: 'giro_2026',
          raceName: 'Giro d\'Italia',
          timestamp: DateTime(2026, 5, 20),
        );
      }

      final mods = service.evaluateTacticalModifiers(
        state,
        observerRiderId: 'r_ally',
        targetRiderId: 'r_player',
      );
      expect(mods.polarity, PelotonRelationshipPolarity.pelotonBrotherhood);
      expect(mods.chaseAggressionMultiplier, lessThan(0.90));
      expect(mods.breakawayCooperationFactor, greaterThan(0.80));
      expect(mods.diplomacyAcceptanceBonus, greaterThan(0.20));
      expect(mods.transferVetoRisk, isFalse);
      expect(mods.transferSalaryDiscountFactor, greaterThan(0.05));
      expect(state.activeAlliancesCount, 1);
    });

    test('międzysezonowe wygaszanie wolniej zaciera Blood Feud niż drobne tarcie', () {
      var state = AiRivalryGrudgeMemoryState.empty(seasonYear: 2026);

      // Krwawa wendeta (-70)
      state = service.recordIncident(
        state,
        riderAId: 'r1',
        riderBId: 'r2',
        riderAName: 'A',
        riderBName: 'B',
        riderATeam: 'T1',
        riderBTeam: 'T2',
        incidentType: RelationshipIncidentType.dangerousSprintDeviation,
        raceId: 'race1',
        raceName: 'Race 1',
        customScoreDelta: -70.0,
        timestamp: DateTime(2026, 4, 1),
      );

      // Drobne tarcie (-10)
      state = service.recordIncident(
        state,
        riderAId: 'r1',
        riderBId: 'r3',
        riderAName: 'A',
        riderBName: 'C',
        riderATeam: 'T1',
        riderBTeam: 'T3',
        incidentType: RelationshipIncidentType.publicMediaInsult,
        raceId: 'race1',
        raceName: 'Race 1',
        customScoreDelta: -10.0,
        timestamp: DateTime(2026, 4, 1),
      );

      final transition = service.applySeasonTransitionDecay(
        state,
        newSeasonYear: 2029,
      );

      final feudBond = transition.nextState.bonds[
          AiRivalryGrudgeMemoryService.canonicalBondKey('r1', 'r2')]!;
      final minorBond = transition.nextState.bonds[
          AiRivalryGrudgeMemoryService.canonicalBondKey('r1', 'r3')]!;

      // Po 3 latach: -70 * 0.92^3 ≈ -54.5, -10 * 0.82^3 ≈ -5.5
      expect(feudBond.score.abs(), greaterThan(50.0));
      expect(minorBond.score.abs(), lessThan(7.0));
      expect(transition.report.archivedEventsCount, 2);
      expect(feudBond.events.first.isHistoricalArchive, isTrue);
    });

    test('audyt zgodności składu wykrywa toksyczne konflikty i złote duety + JSON', () {
      var state = AiRivalryGrudgeMemoryState.empty(seasonYear: 2026);

      state = service.recordIncident(
        state,
        riderAId: 'r1',
        riderBId: 'r2',
        riderAName: 'A',
        riderBName: 'B',
        riderATeam: 'T1',
        riderBTeam: 'T1',
        incidentType: RelationshipIncidentType.breakawayBetrayal,
        raceId: 'r_x',
        raceName: 'Race X',
        customScoreDelta: -60.0,
        timestamp: DateTime(2026, 6, 1),
      );
      state = service.recordIncident(
        state,
        riderAId: 'r2',
        riderBId: 'r3',
        riderAName: 'B',
        riderBName: 'C',
        riderATeam: 'T1',
        riderBTeam: 'T1',
        incidentType: RelationshipIncidentType.sportsmanlikeWaitAfterCrash,
        raceId: 'r_y',
        raceName: 'Race Y',
        customScoreDelta: 55.0,
        timestamp: DateTime(2026, 6, 2),
      );

      final restored = AiRivalryGrudgeMemoryState.fromJson(state.toJson());
      expect(restored.bonds.length, 2);

      final report = service.evaluateTeamRosterCompatibility(
        restored,
        const ['r1', 'r2', 'r3'],
      );
      expect(report.toxicConflicts.length, 1);
      expect(report.goldenDuos.length, 1);
    });
  });

  group('Widgety dyplomacji — responsywność 390x844, 1024x768, 1600x900', () {
    const playerTeam = DiplomacyTeamContext(
      teamId: 'team_player',
      teamName: 'Polonia Pro Cycling',
      riderId: 'rider_p1',
      riderName: 'Jan Kowalski',
      gcPosition: 2,
      gcGapToLeaderSeconds: 20.0,
      hasStageWinAmbition: false,
    );

    final rivals = <DiplomacyTeamContext>[
      const DiplomacyTeamContext(
        teamId: 'team_hunter',
        teamName: 'Alpine Breakaway',
        riderId: 'rider_h1',
        riderName: 'Marco Rossi',
        gcPosition: 45,
        gcGapToLeaderSeconds: 1380.0,
        hasStageWinAmbition: true,
        trustScore: 72.0,
      ),
      const DiplomacyTeamContext(
        teamId: 'team_vendetta',
        teamName: 'Nordic Blitz',
        riderId: 'rider_v1',
        riderName: 'Soren Holm',
        gcPosition: 8,
        gcGapToLeaderSeconds: 140.0,
        activeVendettaStages: 3,
        trustScore: 22.0,
      ),
    ];

    const activeState = PelotonDiplomacyState(
      playerPelotonReputation: 74.0,
      teamTrustScores: {
        'team_hunter': 72.0,
        'team_vendetta': 22.0,
      },
      vendettaStagesByTeam: {
        'team_vendetta': 3,
      },
      activePacts: [
        DiplomacyPact(
          pactId: 'pact_1',
          type: DiplomacyPactType.stageForGcDeal,
          status: DiplomacyPactStatus.active,
          initiatorTeamId: 'team_player',
          initiatorTeamName: 'Polonia Pro Cycling',
          initiatorRiderId: 'rider_p1',
          partnerTeamId: 'team_hunter',
          partnerTeamName: 'Alpine Breakaway',
          partnerRiderId: 'rider_h1',
          createdAtKm: 130.0,
          expiresAtKm: 185.0,
          cooperationBonusMultiplier: 1.38,
        ),
      ],
    );

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'InRacePelotonDiplomacyPanel renderuje się bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          String? selectedId;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: InRacePelotonDiplomacyPanel(
                    diplomacyState: activeState,
                    rivalCandidates: rivals,
                    selectedPartnerTeamId: 'team_hunter',
                    currentStageKm: 142.0,
                    onSelectPartnerTeam: (id) => selectedId = id,
                    onProposePact: (_) {},
                    onBetrayPact: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(InRacePelotonDiplomacyPanel), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.textContaining('Nordic Blitz').first);
          await tester.pump(const Duration(milliseconds: 300));
          expect(selectedId, 'team_vendetta');
        },
      );
    }

    for (final size in const [
      Size(390, 844),
      Size(1600, 900),
    ]) {
      testWidgets(
        'InRaceDiplomacyRadioModal renderuje się bez przepełnień w ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: InRaceDiplomacyRadioModal(
                      initialState: activeState,
                      playerTeam: playerTeam,
                      rivalCandidates: rivals,
                      incomingOffers: const [
                        IncomingRivalPactOffer(
                          offerId: 'offer_1',
                          pactType: DiplomacyPactType.antiLeaderCoalition,
                          fromTeam: DiplomacyTeamContext(
                            teamId: 'team_hunter',
                            teamName: 'Alpine Breakaway',
                            riderId: 'rider_h1',
                            riderName: 'Marco Rossi',
                            gcPosition: 45,
                            gcGapToLeaderSeconds: 1380.0,
                            hasStageWinAmbition: true,
                            trustScore: 72.0,
                          ),
                          offeredAtKm: 140.0,
                          expiresAtKm: 175.0,
                          headline: 'Wspólny atak na lidera!',
                          termsSummary: 'Rotacja przez najbliższe 30 km.',
                        ),
                      ],
                      currentStageKm: 142.0,
                      totalStageKm: 185.0,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(InRaceDiplomacyRadioModal), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
