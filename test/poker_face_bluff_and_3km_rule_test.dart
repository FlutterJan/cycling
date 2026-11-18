import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/engine/events/race_incident_engine.dart';
import 'package:pro_peloton_manager/engine/peloton/bluffing_and_poker_face_body_language.dart';
import 'package:pro_peloton_manager/engine/peloton/late_race_mechanical_neutral_zone_3km.dart';

void main() {
  group('BluffingAndPokerFaceEngine — blefowanie na podjeździe', () {
    const profile = PokerFaceRiderProfile(
      riderId: 'leader-1',
      riderName: 'M. Kwiatkowski',
      pokerFaceSkill: 85.0,
      mentalToughness: 88.0,
      ftpWatts: 420.0,
      wPrimeMaxJ: 24000.0,
      hasDarkMirroredSunglasses: true,
      helmetMaskBonus: 0.04,
    );

    const hardClimbInput = BluffingStepInput(
      wPrimeRemainingPct: 38.0,
      powerOutputWatts: 460.0,
      heartRateBpm: 184.0,
      maxHeartRateBpm: 194.0,
      lactateMmol: 8.6,
      cadenceRpm: 82.0,
      climbGradientPct: 10.2,
      altitudeMeters: 1950.0,
      distanceToSummitKm: 3.5,
      climbZone: ClimbContextZone.highAltitudeFinal,
      deltaSeconds: 10.0,
    );

    const defaultRivals = [
      RivalBodyLanguageObserver(
        rivalId: 'r1',
        rivalName: 'T. Pogacar',
        teamName: 'UAE',
        observationSkill: 88.0,
        aggression: 92.0,
        suspicionLevel: 0.15,
      ),
      RivalBodyLanguageObserver(
        rivalId: 'r2',
        rivalName: 'J. Vingegaard',
        teamName: 'TVL',
        observationSkill: 90.0,
        aggression: 80.0,
        suspicionLevel: 0.15,
      ),
    ];

    BluffingAndPokerFaceState buildState({
      required PokerFaceTacticMode tactic,
      PokerFaceRiderProfile riderProfile = profile,
      double mentalFocus = 90.0,
      double sandbagCharge = 0.0,
      List<RivalBodyLanguageObserver> rivals = defaultRivals,
    }) {
      return BluffingAndPokerFaceState(
        riderProfile: riderProfile,
        activeTactic: tactic,
        lastInput: hardClimbInput,
        lastResult: const BluffingStepResult(
          trueCrisisScore: 50.0,
          displayedCrisisScore: 50.0,
          deceptionGap: 0.0,
          activeCue: BodyLanguageCue.steadySeatedSpin,
          deceptionSuccessProbability: 0.85,
          metabolicMaskingCostWatts: 0.0,
          mentalFocusDrain: 0.0,
          counterAttackSurpriseBonusPct: 0.0,
          overallOutcome: BluffDetectionOutcome.fooledCompletely,
          radioTacticalNote: 'Start',
        ),
        mentalFocusRemaining: mentalFocus,
        sandbagChargeSeconds: sandbagCharge,
        counterAttackWindowActive: false,
        counterAttackBonusPct: 0.0,
        rivals: rivals,
        selectedRivalId: 'r1',
        history: const [],
      );
    }

    test('authentic mode reveals true crisis with zero masking cost', () {
      final state = buildState(tactic: PokerFaceTacticMode.authentic);
      final (nextState, result) = BluffingAndPokerFaceEngine.evaluateStep(
        state,
        hardClimbInput,
      );

      expect(result.trueCrisisScore, greaterThan(50.0));
      expect(result.displayedCrisisScore, equals(result.trueCrisisScore));
      expect(result.deceptionGap, equals(0.0));
      expect(result.metabolicMaskingCostWatts, equals(0.0));
      expect(result.mentalFocusDrain, lessThan(0.0));
      expect(nextState.mentalFocusRemaining, greaterThan(90.0));
    });

    test('pokerFaceHideCrisis masks crisis and sunglasses improve masking', () {
      final withGlasses = buildState(
        tactic: PokerFaceTacticMode.pokerFaceHideCrisis,
        riderProfile: profile.copyWith(hasDarkMirroredSunglasses: true),
      );
      final withoutGlasses = buildState(
        tactic: PokerFaceTacticMode.pokerFaceHideCrisis,
        riderProfile: profile.copyWith(hasDarkMirroredSunglasses: false),
      );

      final (_, resGlasses) = BluffingAndPokerFaceEngine.evaluateStep(
        withGlasses,
        hardClimbInput,
      );
      final (_, resNoGlasses) = BluffingAndPokerFaceEngine.evaluateStep(
        withoutGlasses,
        hardClimbInput,
      );

      expect(resGlasses.activeCue, equals(BodyLanguageCue.pokerFaceMask));
      expect(resGlasses.displayedCrisisScore, lessThan(resGlasses.trueCrisisScore));
      expect(
        resGlasses.displayedCrisisScore,
        lessThan(resNoGlasses.displayedCrisisScore),
      );
      expect(
        resGlasses.metabolicMaskingCostWatts,
        closeTo(hardClimbInput.powerOutputWatts * 0.025, 0.01),
      );
    });

    test('bluffShowOfStrength suppresses displayed crisis at higher W cost', () {
      final state = buildState(tactic: PokerFaceTacticMode.bluffShowOfStrength);
      final (_, result) = BluffingAndPokerFaceEngine.evaluateStep(
        state,
        hardClimbInput,
      );

      expect(result.activeCue, equals(BodyLanguageCue.zippedUpAndOutOfSaddle));
      expect(result.displayedCrisisScore, lessThan(result.trueCrisisScore));
      expect(
        result.metabolicMaskingCostWatts,
        closeTo(hardClimbInput.powerOutputWatts * 0.042, 0.01),
      );
    });

    test('sandbaggingPlayDead inflates displayed crisis and baits aggressive rivals', () {
      var state = buildState(
        tactic: PokerFaceTacticMode.sandbaggingPlayDead,
        sandbagCharge: 15.0,
      );
      final sandbagInput = hardClimbInput.copyWith(
        wPrimeRemainingPct: 55.0,
        deltaSeconds: 10.0,
      );

      final (nextState, result) = BluffingAndPokerFaceEngine.evaluateStep(
        state,
        sandbagInput,
      );

      expect(result.activeCue, equals(BodyLanguageCue.dropToBackOfGroup));
      expect(result.displayedCrisisScore, greaterThanOrEqualTo(64.0));
      expect(result.metabolicMaskingCostWatts, equals(0.0));
      expect(result.overallOutcome, equals(BluffDetectionOutcome.counterAttackBaited));
      expect(nextState.counterAttackWindowActive, isTrue);
      expect(nextState.counterAttackBonusPct, inInclusiveRange(6.0, 14.0));

      final attackOutcome = BluffingAndPokerFaceEngine.triggerCounterAttack(nextState);
      expect(attackOutcome.activated, isTrue);
      expect(attackOutcome.surpriseBonusPct, inInclusiveRange(6.0, 14.0));
      expect(attackOutcome.state.counterAttackWindowActive, isFalse);
      expect(attackOutcome.state.sandbagChargeSeconds, equals(0.0));
      expect(
        attackOutcome.state.activeTactic,
        equals(PokerFaceTacticMode.bluffShowOfStrength),
      );
      expect(
        attackOutcome.state.lastInput.wPrimeRemainingPct,
        closeTo(41.0, 0.01),
      );
    });

    test('triggerCounterAttack fails when window is inactive', () {
      final state = buildState(tactic: PokerFaceTacticMode.sandbaggingPlayDead);
      final outcome = BluffingAndPokerFaceEngine.triggerCounterAttack(state);

      expect(outcome.activated, isFalse);
      expect(outcome.surpriseBonusPct, equals(0.0));
    });

    test('high observation rival sees through extreme bluff over repeated steps', () {
      final eagleEyedRivals = [
        const RivalBodyLanguageObserver(
          rivalId: 'eagle',
          rivalName: 'Sharp Rival',
          teamName: 'SKY',
          observationSkill: 98.0,
          aggression: 70.0,
          suspicionLevel: 0.60,
        ),
      ];
      final exhaustedInput = hardClimbInput.copyWith(
        wPrimeRemainingPct: 8.0,
        lactateMmol: 11.5,
        cadenceRpm: 66.0,
        deltaSeconds: 15.0,
      );
      var state = buildState(
        tactic: PokerFaceTacticMode.bluffShowOfStrength,
        mentalFocus: 30.0,
        riderProfile: profile.copyWith(
          pokerFaceSkill: 25.0,
          hasDarkMirroredSunglasses: false,
          helmetMaskBonus: 0.0,
        ),
        rivals: eagleEyedRivals,
      );

      late BluffingStepResult lastResult;
      for (var i = 0; i < 4; i++) {
        final (next, res) = BluffingAndPokerFaceEngine.evaluateStep(
          state,
          exhaustedInput,
        );
        state = next;
        lastResult = res;
      }

      expect(lastResult.overallOutcome, equals(BluffDetectionOutcome.bluffSeenThrough));
      expect(state.totalBluffExposed, greaterThan(0));
    });

    test('low mental focus forces fallback to authentic mode', () {
      final state = buildState(
        tactic: PokerFaceTacticMode.pokerFaceHideCrisis,
        mentalFocus: 4.0,
      );
      final (nextState, result) = BluffingAndPokerFaceEngine.evaluateStep(
        state,
        hardClimbInput,
      );

      expect(nextState.activeTactic, equals(PokerFaceTacticMode.authentic));
      expect(result.metabolicMaskingCostWatts, equals(0.0));
    });

    test('JSON serialization round-trip preserves PokerFace models', () {
      final profileCopy = PokerFaceRiderProfile.fromJson(profile.toJson());
      expect(profileCopy.riderId, equals(profile.riderId));
      expect(profileCopy.pokerFaceSkill, equals(profile.pokerFaceSkill));
      expect(
        profileCopy.hasDarkMirroredSunglasses,
        equals(profile.hasDarkMirroredSunglasses),
      );

      final rivalCopy = RivalBodyLanguageObserver.fromJson(
        defaultRivals.first.toJson(),
      );
      expect(rivalCopy.rivalId, equals(defaultRivals.first.rivalId));
      expect(rivalCopy.observationSkill, equals(defaultRivals.first.observationSkill));

      final inputCopy = BluffingStepInput.fromJson(hardClimbInput.toJson());
      expect(inputCopy.climbZone, equals(hardClimbInput.climbZone));
      expect(inputCopy.lactateMmol, equals(hardClimbInput.lactateMmol));

      const historyEntry = BluffingHistoryEntry(
        stepIndex: 3,
        tactic: PokerFaceTacticMode.sandbaggingPlayDead,
        trueCrisisScore: 62.5,
        displayedCrisisScore: 79.0,
        outcome: BluffDetectionOutcome.counterAttackBaited,
        note: 'Pułapka zadziałała',
      );
      final historyCopy = BluffingHistoryEntry.fromJson(historyEntry.toJson());
      expect(historyCopy.stepIndex, equals(3));
      expect(historyCopy.tactic, equals(PokerFaceTacticMode.sandbaggingPlayDead));
      expect(historyCopy.outcome, equals(BluffDetectionOutcome.counterAttackBaited));
    });

    test('BluffingAndPokerFaceNotifier updates state across actions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(bluffingAndPokerFaceProvider.notifier);
      notifier.selectTactic(PokerFaceTacticMode.sandbaggingPlayDead);
      expect(
        container.read(bluffingAndPokerFaceProvider).activeTactic,
        equals(PokerFaceTacticMode.sandbaggingPlayDead),
      );

      notifier.toggleSunglasses();
      expect(
        container
            .read(bluffingAndPokerFaceProvider)
            .riderProfile
            .hasDarkMirroredSunglasses,
        isFalse,
      );

      notifier.selectRival('rival-2');
      expect(
        container.read(bluffingAndPokerFaceProvider).selectedRivalId,
        equals('rival-2'),
      );

      final initialStep = container.read(bluffingAndPokerFaceProvider).stepCounter;
      notifier.simulateNextClimbStep();
      expect(
        container.read(bluffingAndPokerFaceProvider).stepCounter,
        equals(initialStep + 1),
      );

      notifier.resetClimbSession();
      expect(
        container.read(bluffingAndPokerFaceProvider).activeTactic,
        equals(PokerFaceTacticMode.pokerFaceHideCrisis),
      );
    });
  });

  group('LateRaceMechanicalNeutralZoneEngine — reguła neutralizacji 3 km / 5 km', () {
    const engine = LateRaceMechanicalNeutralZoneEngine();

    const sprintConfig3Km = NeutralZoneConfig(
      stageId: 'stage_04',
      stageName: 'Etap 4: Orleans',
      stageTotalDistanceMeters: 185000.0,
      stageType: NeutralZoneStageType.flatSprint,
      distancePreset: NeutralZoneDistancePreset.standard3Km,
    );

    const pelotonRider = RiderNeutralZoneEntry(
      riderId: 'rider_1',
      riderName: 'T. Pogacar',
      teamId: 'team_uae',
      teamShortCode: 'UAD',
      bibNumber: 1,
      groupIndexAtIncident: 1,
      groupLabel: 'Peleton główny',
      groupSizeAtIncident: 135,
      isGcContender: true,
    );

    final groupTimes = <int, double>{
      0: 14800.0,
      1: 14820.0,
    };

    test('NeutralZoneConfig calculates 3 km, 5 km and excluded stages accurately', () {
      expect(sprintConfig3Km.isProtectionActiveForStage, isTrue);
      expect(sprintConfig3Km.activeZoneLengthMeters, equals(3000.0));
      expect(sprintConfig3Km.zoneStartDistanceMeters, equals(182000.0));
      expect(sprintConfig3Km.activeBadgeText, equals('3 KM ZONE'));
      expect(sprintConfig3Km.isDistanceInsideZone(181999.0), isFalse);
      expect(sprintConfig3Km.isDistanceInsideZone(182000.0), isTrue);
      expect(sprintConfig3Km.isDistanceInsideZone(185000.0), isTrue);

      final extended5Km = sprintConfig3Km.copyWith(juryExtendedTo5Km: true);
      expect(extended5Km.activeZoneLengthMeters, equals(5000.0));
      expect(extended5Km.zoneStartDistanceMeters, equals(180000.0));
      expect(extended5Km.activeBadgeText, equals('5 KM ZONE'));

      for (final excludedType in const [
        NeutralZoneStageType.summitFinish,
        NeutralZoneStageType.individualTimeTrial,
        NeutralZoneStageType.teamTimeTrial,
        NeutralZoneStageType.oneDayClassic,
      ]) {
        final cfg = sprintConfig3Km.copyWith(
          stageType: excludedType,
          juryExtendedTo5Km: true,
        );
        expect(cfg.isProtectionActiveForStage, isFalse);
        expect(cfg.activeZoneLengthMeters, equals(0.0));
        expect(cfg.activeBadgeText, equals('NO NEUTRAL ZONE'));
      }
    });

    test('neutralizes GC time for verified puncture inside 3 km zone', () {
      const incident = NeutralZoneIncidentRecord(
        incidentId: 'inc_puncture',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.puncture,
        distanceToFinishMeters: 2100.0,
        incidentRaceTimeSeconds: 14680.0,
        actualFinishTimeSeconds: 14905.0,
        actualStageRank: 98,
        crossedFinishLine: true,
        isCommissaireVerified: true,
        details: 'Przebicie na 2.1 km',
      );

      final result = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: incident,
        groupFinishTimesSeconds: groupTimes,
      );

      expect(result.status, equals(NeutralZoneVerdictStatus.neutralized));
      expect(result.isNeutralized, isTrue);
      expect(result.creditedGcTimeSeconds, equals(14820.0));
      expect(result.savedGcSeconds, equals(85.0));
      expect(result.stagePlacementRank, equals(98));
      expect(result.eligibleForStagePointsAndBonuses, isFalse);
    });

    test('incident at 3.65 km is rejected under 3 km rule and neutralized under 5 km', () {
      const boundaryIncident = NeutralZoneIncidentRecord(
        incidentId: 'inc_3650',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.mechanicalFailure,
        distanceToFinishMeters: 3650.0,
        incidentRaceTimeSeconds: 14550.0,
        actualFinishTimeSeconds: 14890.0,
        actualStageRank: 84,
        crossedFinishLine: true,
        isCommissaireVerified: true,
        details: 'Defekt łańcucha na 3.65 km',
      );

      final res3Km = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: boundaryIncident,
        groupFinishTimesSeconds: groupTimes,
      );
      expect(res3Km.status, equals(NeutralZoneVerdictStatus.rejected));
      expect(res3Km.creditedGcTimeSeconds, equals(14890.0));
      expect(res3Km.savedGcSeconds, equals(0.0));

      final res5Km = engine.evaluateIncident(
        config: sprintConfig3Km.copyWith(juryExtendedTo5Km: true),
        incident: boundaryIncident,
        groupFinishTimesSeconds: groupTimes,
      );
      expect(res5Km.status, equals(NeutralZoneVerdictStatus.neutralized));
      expect(res5Km.creditedGcTimeSeconds, equals(14820.0));
      expect(res5Km.savedGcSeconds, equals(70.0));
    });

    test('rejects droppedOnPace, solo riders, unverified VAR, and summit finishes; handles DNF', () {
      const dropped = NeutralZoneIncidentRecord(
        incidentId: 'inc_drop',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.droppedOnPace,
        distanceToFinishMeters: 1500.0,
        incidentRaceTimeSeconds: 14710.0,
        actualFinishTimeSeconds: 14860.0,
        actualStageRank: 75,
        details: 'Brak sił',
      );
      expect(
        engine
            .evaluateIncident(
              config: sprintConfig3Km,
              incident: dropped,
              groupFinishTimesSeconds: groupTimes,
            )
            .status,
        equals(NeutralZoneVerdictStatus.rejected),
      );

      const soloIncident = NeutralZoneIncidentRecord(
        incidentId: 'inc_solo',
        rider: RiderNeutralZoneEntry(
          riderId: 'solo_1',
          riderName: 'Solo Rider',
          teamId: 't1',
          teamShortCode: 'SOL',
          bibNumber: 99,
          groupIndexAtIncident: 0,
          groupLabel: 'Ucieczka 1-os',
          groupSizeAtIncident: 1,
        ),
        incidentType: NeutralZoneIncidentType.crash,
        distanceToFinishMeters: 1200.0,
        incidentRaceTimeSeconds: 14700.0,
        actualFinishTimeSeconds: 14850.0,
        actualStageRank: 50,
        details: 'Samotna kraksa',
      );
      expect(
        engine
            .evaluateIncident(
              config: sprintConfig3Km,
              incident: soloIncident,
              groupFinishTimesSeconds: groupTimes,
            )
            .status,
        equals(NeutralZoneVerdictStatus.rejected),
      );

      const unverified = NeutralZoneIncidentRecord(
        incidentId: 'inc_var',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.blockedByCrash,
        distanceToFinishMeters: 1100.0,
        incidentRaceTimeSeconds: 14720.0,
        actualFinishTimeSeconds: 14860.0,
        actualStageRank: 70,
        isCommissaireVerified: false,
        details: 'Czeka na VAR',
      );
      expect(
        engine
            .evaluateIncident(
              config: sprintConfig3Km,
              incident: unverified,
              groupFinishTimesSeconds: groupTimes,
            )
            .status,
        equals(NeutralZoneVerdictStatus.pendingReview),
      );

      const dnf = NeutralZoneIncidentRecord(
        incidentId: 'inc_dnf',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.crash,
        distanceToFinishMeters: 900.0,
        incidentRaceTimeSeconds: 14740.0,
        actualFinishTimeSeconds: 0.0,
        actualStageRank: 0,
        crossedFinishLine: false,
        details: 'Wycofanie po kraksie',
      );
      final dnfRes = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: dnf,
        groupFinishTimesSeconds: groupTimes,
      );
      expect(dnfRes.status, equals(NeutralZoneVerdictStatus.dnfNoTime));
      expect(dnfRes.creditedGcTimeSeconds, equals(0.0));
      expect(dnfRes.eligibleForStagePointsAndBonuses, isFalse);

      expect(
        engine
            .evaluateIncident(
              config: sprintConfig3Km.copyWith(
                stageType: NeutralZoneStageType.summitFinish,
              ),
              incident: dropped.copyWith(),
              groupFinishTimesSeconds: groupTimes,
            )
            .status,
        equals(NeutralZoneVerdictStatus.rejected),
      );
    });

    test('maps IncidentType from race_incident_engine and computes batch summary & progress', () {
      expect(
        NeutralZoneIncidentType.fromEngineIncident(IncidentType.punctureFlatTire),
        equals(NeutralZoneIncidentType.puncture),
      );
      expect(
        NeutralZoneIncidentType.fromEngineIncident(IncidentType.pelotonPileup),
        equals(NeutralZoneIncidentType.crash),
      );
      expect(
        NeutralZoneIncidentType.fromEngineIncident(IncidentType.roadBlockage),
        equals(NeutralZoneIncidentType.blockedByCrash),
      );

      expect(
        engine.calculateZoneProgress(
          config: sprintConfig3Km,
          distanceCoveredMeters: 181000.0,
        ),
        equals(0.0),
      );
      expect(
        engine.calculateZoneProgress(
          config: sprintConfig3Km,
          distanceCoveredMeters: 183500.0,
        ),
        closeTo(0.5, 0.001),
      );
      expect(
        engine.calculateZoneProgress(
          config: sprintConfig3Km,
          distanceCoveredMeters: 185000.0,
        ),
        equals(1.0),
      );
    });

    test('JSON serialization round-trip preserves NeutralZone models', () {
      final cfgCopy = NeutralZoneConfig.fromJson(sprintConfig3Km.toJson());
      expect(cfgCopy.stageId, equals(sprintConfig3Km.stageId));
      expect(cfgCopy.stageType, equals(sprintConfig3Km.stageType));

      const inc = NeutralZoneIncidentRecord(
        incidentId: 'inc_json',
        rider: pelotonRider,
        incidentType: NeutralZoneIncidentType.crash,
        distanceToFinishMeters: 1800.0,
        incidentRaceTimeSeconds: 14700.0,
        actualFinishTimeSeconds: 14880.0,
        actualStageRank: 64,
        details: 'Kraksa na zakręcie',
      );
      final incCopy = NeutralZoneIncidentRecord.fromJson(inc.toJson());
      expect(incCopy.incidentId, equals('inc_json'));
      expect(incCopy.rider.bibNumber, equals(1));
      expect(incCopy.incidentType, equals(NeutralZoneIncidentType.crash));

      final res = engine.evaluateIncident(
        config: sprintConfig3Km,
        incident: inc,
        groupFinishTimesSeconds: groupTimes,
      );
      final resCopy = NeutralZoneResolutionResult.fromJson(res.toJson());
      expect(resCopy.status, equals(NeutralZoneVerdictStatus.neutralized));
      expect(resCopy.savedGcSeconds, equals(60.0));
    });

    test('LateRaceNeutralZoneNotifier manages presets, VAR verification and filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(lateRaceNeutralZoneProvider.notifier);
      final initialState = container.read(lateRaceNeutralZoneProvider);
      expect(initialState.summary.totalIncidentsReviewed, equals(4));
      expect(initialState.summary.neutralizedCount, equals(1));
      expect(initialState.summary.pendingCount, equals(1));

      // Rozszerzenie do 5 km neutralizuje incydent na 3.65 km
      notifier.setZonePreset(NeutralZoneDistancePreset.extended5Km);
      expect(
        container.read(lateRaceNeutralZoneProvider).summary.neutralizedCount,
        equals(2),
      );

      // Zatwierdzenie incydentu oczekującego na VAR
      notifier.setCommissaireVerification('inc_02', true);
      expect(
        container.read(lateRaceNeutralZoneProvider).summary.neutralizedCount,
        equals(3),
      );
      expect(
        container.read(lateRaceNeutralZoneProvider).summary.pendingCount,
        equals(0),
      );

      // Filtracja wyników
      notifier.setFilter(NeutralZoneVerdictStatus.neutralized);
      expect(
        container.read(lateRaceNeutralZoneProvider).filteredResolutions.length,
        equals(3),
      );
      notifier.setFilter(null);
      expect(
        container.read(lateRaceNeutralZoneProvider).filteredResolutions.length,
        equals(4),
      );

      // Zmiana etapu na szczytowy wyłącza strefę ochronną
      notifier.setStageType(NeutralZoneStageType.summitFinish);
      expect(
        container
            .read(lateRaceNeutralZoneProvider)
            .config
            .isProtectionActiveForStage,
        isFalse,
      );
      expect(
        container.read(lateRaceNeutralZoneProvider).summary.neutralizedCount,
        equals(0),
      );
    });
  });

  group('Responsive UI widget tests (390x844, 1024x768, 1600x900)', () {
    const viewports = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final size in viewports) {
      testWidgets(
        'BluffingAndPokerFacePanel renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: AppColors.background,
                ),
                home: const Scaffold(
                  body: BluffingAndPokerFacePanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(BluffingAndPokerFacePanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'LateRaceMechanicalNeutralZonePanel renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: AppColors.background,
                ),
                home: const Scaffold(
                  body: LateRaceMechanicalNeutralZonePanel(),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(LateRaceMechanicalNeutralZonePanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
