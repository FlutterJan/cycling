import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_colors.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_keirin_and_madison_sling_solver.dart';
import 'package:pro_peloton_manager/models/race/uci_commissaire_rulebook_and_var_model.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/transfer_rumor_mill_and_journalists_service.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';
import 'package:pro_peloton_manager/ui/screens/track_omnium_madison_championship_screen.dart';
import 'package:pro_peloton_manager/ui/widgets/cycling_media_social_feed_panel.dart';
import 'package:pro_peloton_manager/ui/widgets/sprint_var_overhead_replay_inspector.dart';

void main() {
  const responsiveSizes = <Size>[
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ];

  group('1. Przepisy sędziowskie UCI, Sprint Deviation VAR i ewolucja regulaminów (#463, #464)', () {
    const analyzer = SprintDeviationVarAnalyzer();

    test('kontrola sprzętu i pozycji UCI wykrywa naruszenia oraz akceptuje legalny rower', () {
      final model = UciCommissaireRulebookAndVarModel.initial(seasonYear: 2025);

      final legalCheck = model.checkEquipmentAndPostureCompliance(
        bikeWeightKg: 6.85,
        handlebarWidthCm: 38.0,
        brakeLeverInwardDeg: 8.0,
        rimDepthMm: 60.0,
        sockHeightRatio: 0.45,
      );
      expect(legalCheck.isCompliant, isTrue);
      expect(legalCheck.violationsPl, isEmpty);
      expect(legalCheck.totalFineChf, 0);
      expect(legalCheck.resultsInDisqualification, isFalse);

      final illegalCheck = model.checkEquipmentAndPostureCompliance(
        bikeWeightKg: 6.65,
        handlebarWidthCm: 33.5,
        brakeLeverInwardDeg: 14.0,
        rimDepthMm: 85.0,
        sockHeightRatio: 0.62,
        usesSupertuck: true,
        usesPuppyPaws: true,
      );
      expect(illegalCheck.isCompliant, isFalse);
      expect(illegalCheck.resultsInDisqualification, isTrue);
      expect(illegalCheck.totalFineChf, greaterThanOrEqualTo(4200));
      expect(illegalCheck.violationsPl.length, 7);
    });

    test('SprintDeviationVarAnalyzer rozróżnia czysty sprint, relegację z żółtą kartką i DSQ po kraksie', () {
      final rulebook = UciRulebookEdition.baseline(seasonYear: 2025);

      const cleanInput = SprintVarIncidentInput(
        incidentId: 'var_clean_1',
        stageId: 'stage_flat_1',
        riderId: 'r_sprinter_1',
        riderName: 'Jasper Van Der Berg',
        teamId: 'team_a',
        finishingPosition: 1,
        groupEndPosition: 24,
        trajectorySamples: [
          SprintVarFrameSample(
            timestampSeconds: 0.0,
            distanceToFinishMeters: 200.0,
            lateralPositionMeters: 4.0,
            speedKmh: 66.0,
            nearestRivalClearanceMeters: 1.4,
          ),
          SprintVarFrameSample(
            timestampSeconds: 5.0,
            distanceToFinishMeters: 100.0,
            lateralPositionMeters: 4.25,
            speedKmh: 69.5,
            nearestRivalClearanceMeters: 1.2,
          ),
          SprintVarFrameSample(
            timestampSeconds: 10.0,
            distanceToFinishMeters: 0.0,
            lateralPositionMeters: 4.30,
            speedKmh: 71.0,
            nearestRivalClearanceMeters: 1.1,
          ),
        ],
      );

      final cleanVerdict = analyzer.analyze(input: cleanInput, rulebook: rulebook);
      expect(cleanVerdict.status, SprintVarVerdictStatus.cleanSprint);
      expect(cleanVerdict.cardIssued, UciCardType.none);
      expect(cleanVerdict.finalPosition, 1);
      expect(cleanVerdict.fineChf, 0);
      expect(cleanVerdict.maxLateralDeviationMeters, closeTo(0.30, 0.01));

      const relegationInput = SprintVarIncidentInput(
        incidentId: 'var_rel_1',
        stageId: 'stage_flat_1',
        riderId: 'r_sprinter_2',
        riderName: 'Dylan Groeneveld',
        teamId: 'team_b',
        finishingPosition: 1,
        groupEndPosition: 18,
        rivalForcedToBrake: true,
        trajectorySamples: [
          SprintVarFrameSample(
            timestampSeconds: 0.0,
            distanceToFinishMeters: 180.0,
            lateralPositionMeters: 3.0,
            speedKmh: 67.0,
            nearestRivalClearanceMeters: 1.2,
          ),
          SprintVarFrameSample(
            timestampSeconds: 2.0,
            distanceToFinishMeters: 140.0,
            lateralPositionMeters: 4.10,
            speedKmh: 68.5,
            nearestRivalClearanceMeters: 0.35,
          ),
        ],
      );

      final relVerdict = analyzer.analyze(input: relegationInput, rulebook: rulebook);
      expect(relVerdict.status, SprintVarVerdictStatus.yellowCardAndRelegated);
      expect(relVerdict.cardIssued, UciCardType.yellow);
      expect(relVerdict.finalPosition, 18);
      expect(relVerdict.uciPointsDeducted, 20);
      expect(relVerdict.fineChf, 500);

      const crashInput = SprintVarIncidentInput(
        incidentId: 'var_dsq_1',
        stageId: 'stage_flat_1',
        riderId: 'r_sprinter_3',
        riderName: 'Fabio Conti',
        teamId: 'team_c',
        finishingPosition: 2,
        groupEndPosition: 20,
        causedCrash: true,
        handOffHandlebarOrElbow: true,
      );

      final dsqVerdict = analyzer.analyze(input: crashInput, rulebook: rulebook);
      expect(dsqVerdict.status, SprintVarVerdictStatus.disqualified);
      expect(dsqVerdict.cardIssued, UciCardType.redDisqualification);
      expect(dsqVerdict.isAppealable, isFalse);
      expect(dsqVerdict.uciPointsDeducted, 50);
    });

    test('odwołanie od werdyktu VAR w deszczu z pojedynczej kamery przywraca pozycję przy mocnych dowodach', () {
      final rulebook = UciRulebookEdition.baseline(seasonYear: 2025);
      const borderlineInput = SprintVarIncidentInput(
        incidentId: 'var_appeal_1',
        stageId: 'stage_rain_2',
        riderId: 'r_appeal',
        riderName: 'Arnaud Demare',
        teamId: 'team_d',
        finishingPosition: 1,
        groupEndPosition: 15,
        availableCameras: [SprintVarCameraAngle.sideBarrierTracking],
        rainOrLowVisibility: true,
        rivalForcedToBrake: true,
        trajectorySamples: [
          SprintVarFrameSample(
            timestampSeconds: 0.0,
            distanceToFinishMeters: 150.0,
            lateralPositionMeters: 2.0,
            speedKmh: 64.0,
            nearestRivalClearanceMeters: 0.9,
          ),
          SprintVarFrameSample(
            timestampSeconds: 2.5,
            distanceToFinishMeters: 100.0,
            lateralPositionMeters: 3.05,
            speedKmh: 65.0,
            nearestRivalClearanceMeters: 0.50,
          ),
        ],
      );

      final verdict = analyzer.analyze(input: borderlineInput, rulebook: rulebook);
      expect(verdict.status, SprintVarVerdictStatus.yellowCardAndRelegated);
      expect(verdict.varConfidenceScore, lessThan(0.94));
      expect(verdict.isAppealable, isTrue);

      final upheldVerdict = analyzer.processAppeal(
        verdict: verdict,
        teamEvidenceStrength: 0.95,
      );
      expect(upheldVerdict.appealSubmitted, isTrue);
      expect(upheldVerdict.appealUpheld, isTrue);
      expect(upheldVerdict.status, SprintVarVerdictStatus.cleanSprint);
      expect(upheldVerdict.cardIssued, UciCardType.none);
      expect(upheldVerdict.finalPosition, 1);
      expect(upheldVerdict.fineChf, 0);
    });

    test('system żółtych kartek UCI nalicza zawieszenie 7 i 14 dni oraz ewoluuje w latach 2026–2027', () {
      var model = UciCommissaireRulebookAndVarModel.initial(seasonYear: 2025);

      model = model.recordYellowCard('rider_1');
      expect(model.riderYellowCardsInRace['rider_1'], 1);
      expect(model.riderSuspensionDays['rider_1'], isNull);

      // 2 żółte kartki w tym samym wyścigu -> 7 dni zawieszenia
      model = model.recordYellowCard('rider_1');
      expect(model.riderYellowCardsInRace['rider_1'], 2);
      expect(model.riderSuspensionDays['rider_1'], 7);

      // Reset po wyścigu, trzecia żółta kartka w oknie 30 dni -> 14 dni zawieszenia
      model = model.clearRaceYellowCards();
      expect(model.riderYellowCardsInRace, isEmpty);
      model = model.recordYellowCard('rider_1');
      expect(model.riderYellowCardsRolling30Days['rider_1'], 3);
      expect(model.riderSuspensionDays['rider_1'], 14);

      // Ewolucja regulaminu 2026 (strefa ochronna 5 km) -> 2027 (limit wagi 6.50 kg)
      model = model.advanceToNextSeason(targetYear: 2026);
      expect(model.activeRulebook.seasonYear, 2026);
      expect(model.activeRulebook.finalKmProtectionDistanceKm, 5.0);

      model = model.advanceToNextSeason(targetYear: 2027);
      expect(model.activeRulebook.seasonYear, 2027);
      expect(model.activeRulebook.minBikeWeightKg, closeTo(6.50, 0.01));
      expect(model.evolutionHistory.length, greaterThanOrEqualTo(2));

      final lightBike2027 = model.checkEquipmentAndPostureCompliance(
        bikeWeightKg: 6.60,
        handlebarWidthCm: 36.0,
        brakeLeverInwardDeg: 8.0,
        rimDepthMm: 60.0,
        sockHeightRatio: 0.45,
      );
      expect(lightBike2027.isCompliant, isTrue);

      // Round-trip serializacji JSON
      final restored = UciCommissaireRulebookAndVarModel.fromJson(model.toJson());
      expect(restored.activeRulebook.seasonYear, 2027);
      expect(restored.activeRulebook.minBikeWeightKg, closeTo(6.50, 0.01));
      expect(restored.riderSuspensionDays['rider_1'], 14);
      expect(restored.evolutionHistory.length, model.evolutionHistory.length);
    });
  });

  group('2. Fizyka torowa Madison Hand Sling i symulacja wyścigu (#465, #466, #467)', () {
    const velodrome = VelodromeFacilitySpec(
      id: 'grenchen_tissot',
      name: 'Tissot Velodrome',
      city: 'Grenchen',
      countryCode: 'SUI',
      altitudeMeters: 430.0,
      turnBankingDegrees: 43.0,
    );
    const trackBike = FixedGearTrackBike(
      modelName: 'Track Aero Pro',
      chainringTeeth: 62,
      cogTeeth: 14,
      bikeWeightKg: 7.1,
    );

    test('wzorcowy Hand Sling przekazuje pęd z zachowaniem masy zredukowanej i przyspiesza partnera', () {
      final result = VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
        const MadisonHandSlingInput(
          facility: velodrome,
          incomingRiderMassKg: 74.0,
          incomingBike: trackBike,
          incomingSpeedMs: 15.5, // 55.8 km/h
          outgoingRiderMassKg: 70.0,
          outgoingBike: trackBike,
          outgoingSpeedMs: 9.5, // 34.2 km/h
          incomingSlingSkill: 94.0,
          outgoingSlingSkill: 94.0,
          teamChemistry: 92.0,
          longitudinalGapMeters: 0.15,
          lateralGapMeters: 0.65,
        ),
      );

      const expectedMIn = 74.0 + 7.1;
      const expectedMOut = 70.0 + 7.1;
      const expectedReducedMass =
          (expectedMIn * expectedMOut) / (expectedMIn + expectedMOut);

      expect(result.isSuccessfulExchange, isTrue);
      expect(result.quality, MadisonSlingQuality.textbookSlingshot);
      expect(result.reducedMassKg, closeTo(expectedReducedMass, 0.01));
      expect(result.transferEfficiency, greaterThanOrEqualTo(0.87));
      expect(result.outgoingSpeedGainKmh, greaterThanOrEqualTo(12.0));
      expect(result.outgoingPostSlingSpeedKmh, greaterThan(46.0));
      expect(result.incomingPostSlingSpeedMs, lessThan(15.5));
      expect(result.penaltyTimeLostSeconds, 0.0);
    });

    test('chybiony chwyt i zbyt duża różnica prędkości powodują stratę pędu i karę czasową', () {
      final missed = VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
        const MadisonHandSlingInput(
          facility: velodrome,
          incomingRiderMassKg: 72.0,
          incomingBike: trackBike,
          incomingSpeedMs: 15.0,
          outgoingRiderMassKg: 72.0,
          outgoingBike: trackBike,
          outgoingSpeedMs: 9.5,
          longitudinalGapMeters: 1.80,
        ),
      );

      expect(missed.quality, MadisonSlingQuality.missedHandTouch);
      expect(missed.isSuccessfulExchange, isFalse);
      expect(missed.transferEfficiency, 0.0);
      expect(missed.outgoingSpeedGainKmh, 0.0);
      expect(missed.penaltyTimeLostSeconds, greaterThan(1.0));

      final crash = VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
        const MadisonHandSlingInput(
          facility: velodrome,
          incomingRiderMassKg: 75.0,
          incomingBike: trackBike,
          incomingSpeedMs: 21.0,
          outgoingRiderMassKg: 68.0,
          outgoingBike: trackBike,
          outgoingSpeedMs: 7.0,
          incomingSlingSkill: 45.0,
          outgoingSlingSkill: 45.0,
        ),
      );

      expect(crash.quality, MadisonSlingQuality.illegalPushOrCrash);
      expect(crash.isSuccessfulExchange, isFalse);
      expect(crash.penaltyTimeLostSeconds, greaterThanOrEqualTo(5.0));
    });

    test('symulacja wyścigu Madison rozgrywa sprinty co 10 okrążeń i wyłania klasyfikację końcową', () {
      MadisonTeamRiderPair buildPair(String id, String name, double skill, double cp) {
        return MadisonTeamRiderPair(
          teamId: id,
          teamName: name,
          riderA: KeirinRiderProfile(
            riderId: '${id}_a',
            name: '$name A',
            riderMassKg: 72.0,
            bike: trackBike,
            peakSprintPowerWatts: 1550.0,
            criticalPowerWatts: cp,
            wPrimeJoules: 26000.0,
          ),
          riderB: KeirinRiderProfile(
            riderId: '${id}_b',
            name: '$name B',
            riderMassKg: 70.0,
            bike: trackBike,
            peakSprintPowerWatts: 1500.0,
            criticalPowerWatts: cp,
            wPrimeJoules: 25000.0,
          ),
          riderASlingSkill: skill,
          riderBSlingSkill: skill,
          teamChemistry: skill,
          exchangeIntervalLaps: 3,
        );
      }

      final simulation = VelodromeKeirinAndMadisonSlingSolver.simulateMadisonRace(
        config: const MadisonRaceConfig(
          facility: velodrome,
          totalLaps: 40,
          sprintIntervalLaps: 10,
        ),
        teams: [
          buildPair('bel', 'Belgia', 92.0, 420.0),
          buildPair('ned', 'Holandia', 88.0, 410.0),
          buildPair('pol', 'Polska', 85.0, 405.0),
        ],
      );

      expect(simulation.sprintResults.length, 4);
      expect(simulation.sprintResults.last.isFinalDoublePoints, isTrue);
      expect(simulation.standings.length, 3);
      expect(simulation.standings.map((s) => s.rank).toList(), [1, 2, 3]);
      for (final standing in simulation.standings) {
        expect(standing.totalHandSlings, greaterThan(0));
        expect(standing.successfulHandSlings, greaterThan(0));
        expect(standing.averageSpeedKmh, greaterThan(45.0));
      }
    });
  });

  group('3. System przecieków transferowych, zasłona dymna i wpływ na morale (#468, #469)', () {
    const rumorService = TransferRumorMillAndJournalistsService();
    late CyclingTeam playerTeam;
    late List<Rider> playerSquad;
    late List<CyclingTeam> allTeams;
    late List<Rider> marketRiders;

    setUp(() {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 470);
      allTeams = world.teams;
      playerTeam = world.worldTourTeams.first;
      playerSquad = world.getTeamRoster(playerTeam.id);
      marketRiders = world.allRiders
          .where((r) => r.contract.teamId != playerTeam.id)
          .take(25)
          .toList();
    });

    test('dzienny tick wygasza przeterminowane plotki oraz generuje nowe w oknie transferowym', () {
      final now = DateTime(2026, 8, 15);
      final initial = TransferRumorMillState.initial();
      expect(initial.journalists.length, 8);

      final expiredRumor = TransferRumor(
        id: 'rumor_expired_1',
        targetRiderId: marketRiders.first.id,
        targetRiderName: marketRiders.first.fullName,
        targetRiderRole: marketRiders.first.contract.role,
        sourceTeamId: marketRiders.first.contract.teamId,
        sourceTeamName: 'Rival Team',
        rumoredDestinationTeamId: playerTeam.id,
        rumoredDestinationTeamName: playerTeam.name,
        journalistId: initial.journalists.first.id,
        journalistName: initial.journalists.first.name,
        journalistHandle: initial.journalists.first.handle,
        credibilityAtPublish: initial.journalists.first.credibilityRating,
        veracity: RumorVeracityTier.speculative,
        status: RumorStatus.active,
        playerResponse: RumorActionType.noComment,
        headline: 'Przestarzała plotka testowa',
        body: 'Treść testowa',
        createdDate: now.subtract(const Duration(days: 12)),
        expiresDate: now.subtract(const Duration(days: 1)),
        isPlayerTeamInvolved: true,
        estimatedSalaryEur: 450000,
        marketHeatDelta: 5,
      );

      final seededState = initial.copyWith(activeRumors: [expiredRumor]);
      var current = seededState;
      var generatedCount = 0;

      for (var day = 0; day < 6; day++) {
        final tick = rumorService.tickDailyRumorMill(
          currentState: current,
          currentDate: now.add(Duration(days: day)),
          playerTeam: playerTeam,
          playerSquad: playerSquad,
          allTeams: allTeams,
          marketRiders: marketRiders,
          randomSeed: 4700 + day,
        );
        current = tick.nextState;
        generatedCount += tick.newlyPublishedRumors.length;
      }

      expect(
        current.archivedRumors.any(
          (r) => r.id == 'rumor_expired_1' && r.status == RumorStatus.expired,
        ),
        isTrue,
      );
      expect(generatedCount, greaterThan(0));
      expect(current.activeRumors, isNotEmpty);
    });

    test('zasłona dymna i reakcja menedżera wpływają na rynek, relacje i morale oraz przechodzą round-trip JSON', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(transferRumorMillProvider.notifier);
      final initialState = container.read(transferRumorMillProvider);
      final journalist = initialState.journalists.first;
      final decoyRider = marketRiders.first;
      final realTarget = marketRiders[1];
      final now = DateTime(2026, 8, 20);

      final smokeRes = notifier.launchSmokescreen(
        currentDate: now,
        playerTeam: playerTeam,
        playerSquad: playerSquad,
        decoyRider: decoyRider,
        realTargetRider: realTarget,
        decoyCurrentTeamName: 'Rival Pro Cycling',
        journalist: journalist,
        objective: SmokescreenObjective.testLockerRoomLoyalty,
        durationDays: 10,
      );

      expect(smokeRes.campaign.isActive, isTrue);
      expect(smokeRes.campaign.mediaDistractionPct, greaterThan(25.0));
      expect(smokeRes.campaign.rivalBidInflationPct, greaterThan(0.0));
      expect(smokeRes.plantedRumor.isSmokescreen, isTrue);
      expect(smokeRes.plantedRumor.veracity, RumorVeracityTier.smokescreen);

      final afterSmokeState = container.read(transferRumorMillProvider);
      expect(afterSmokeState.activeSmokescreens.length, 1);
      expect(afterSmokeState.marketHeatIndex, greaterThan(initialState.marketHeatIndex));
      final updatedJournalist = afterSmokeState.journalists
          .firstWhere((j) => j.id == journalist.id);
      expect(
        updatedJournalist.relationshipWithPlayer,
        greaterThan(journalist.relationshipWithPlayer),
      );

      // Reakcja menedżera: zdementowanie aktywnej plotki
      final responseOutcome = notifier.respond(
        rumorId: smokeRes.plantedRumor.id,
        action: RumorActionType.deny,
        playerTeam: playerTeam,
        playerSquad: smokeRes.updatedSquad,
        currentDate: now.add(const Duration(days: 1)),
      );
      expect(responseOutcome.updatedRumor.playerResponse, RumorActionType.deny);

      final afterDenyState = container.read(transferRumorMillProvider);
      expect(
        afterDenyState.activeRumors.any((r) => r.id == smokeRes.plantedRumor.id),
        isFalse,
      );

      // Round-trip JSON całego stanu młynka plotek
      final restored = TransferRumorMillState.fromJson(afterDenyState.toJson());
      expect(restored.journalists.length, afterDenyState.journalists.length);
      expect(restored.smokescreens.length, afterDenyState.smokescreens.length);
      expect(restored.archivedRumors.length, afterDenyState.archivedRumors.length);
      expect(restored.marketHeatIndex, afterDenyState.marketHeatIndex);
    });
  });

  group('4. Testy UI i responsywności (390x844, 1024x768, 1600x900) bez pumpAndSettle', () {
    testWidgets('SprintVarOverheadReplayInspector renderuje się bez overflow na 3 rozdzielczościach', (tester) async {
      const replayData = SprintVarOverheadReplayData(
        incidentId: 'ui_var_1',
        stageId: 'stage_1',
        stageName: 'Tour de France — Etap 4',
        tracks: [
          SprintVarRiderTrack(
            riderId: 'r1',
            riderName: 'Jasper Philipsen',
            teamName: 'Alpecin',
            bibNumber: 1,
            jerseyColor: AppColors.accentBlue,
            finishingPosition: 1,
            isSuspect: true,
            samples: [
              SprintVarFrameSample(
                timestampSeconds: 0.0,
                distanceToFinishMeters: 200.0,
                lateralPositionMeters: 3.5,
                speedKmh: 68.0,
                nearestRivalClearanceMeters: 1.1,
              ),
              SprintVarFrameSample(
                timestampSeconds: 4.0,
                distanceToFinishMeters: 0.0,
                lateralPositionMeters: 4.8,
                speedKmh: 71.0,
                nearestRivalClearanceMeters: 0.4,
              ),
            ],
          ),
          SprintVarRiderTrack(
            riderId: 'r2',
            riderName: 'Dylan Groenewegen',
            teamName: 'Jayco',
            bibNumber: 14,
            jerseyColor: AppColors.goldAccent,
            finishingPosition: 2,
            isVictim: true,
            samples: [
              SprintVarFrameSample(
                timestampSeconds: 0.0,
                distanceToFinishMeters: 200.0,
                lateralPositionMeters: 5.0,
                speedKmh: 67.5,
                nearestRivalClearanceMeters: 1.1,
              ),
              SprintVarFrameSample(
                timestampSeconds: 4.0,
                distanceToFinishMeters: 0.0,
                lateralPositionMeters: 5.2,
                speedKmh: 69.0,
                nearestRivalClearanceMeters: 0.4,
              ),
            ],
          ),
        ],
      );

      for (final size in responsiveSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SprintVarOverheadReplayInspector(data: replayData),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SprintVarOverheadReplayInspector), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('TrackOmniumMadisonChampionshipScreen renderuje się poprawnie na 3 rozdzielczościach', (tester) async {
      for (final size in responsiveSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const TrackOmniumMadisonChampionshipScreen(
              initialDiscipline: TrackChampionshipDiscipline.madison,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TrackOmniumMadisonChampionshipScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('CyclingMediaSocialFeedPanel renderuje aktywne plotki i zasłonę dymną na 3 rozdzielczościach', (tester) async {
      final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 470);
      final team = world.worldTourTeams.first;
      final squad = world.getTeamRoster(team.id);
      final decoy = world.allRiders.firstWhere((r) => r.contract.teamId != team.id);
      final now = DateTime(2026, 8, 22);

      const service = TransferRumorMillAndJournalistsService();
      final baseState = TransferRumorMillState.initial();
      final smoke = service.plantSmokescreen(
        currentState: baseState,
        currentDate: now,
        playerTeam: team,
        playerSquad: squad,
        decoyRider: decoy,
        decoyCurrentTeamName: 'Rival Squad',
        journalist: baseState.journalists.first,
        objective: SmokescreenObjective.protectRealTarget,
      );

      for (final size in responsiveSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: CyclingMediaSocialFeedPanel(
                  stateOverride: smoke.nextState,
                  playerTeam: team,
                  playerSquad: smoke.updatedSquad,
                  currentDate: now,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CyclingMediaSocialFeedPanel), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
