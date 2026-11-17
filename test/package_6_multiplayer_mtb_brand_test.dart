import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/physics/mtb_suspension_damping_and_line_choice_solver.dart';
import 'package:pro_peloton_manager/models/equipment/frame_model.dart';
import 'package:pro_peloton_manager/models/multiplayer/online_league_and_ghost_challenge_model.dart';
import 'package:pro_peloton_manager/models/race/mtb_xco_course_and_suspension_model.dart';
import 'package:pro_peloton_manager/models/team/in_house_bike_brand_manufacturing_model.dart';
import 'package:pro_peloton_manager/services/network/async_multiplayer_league_sync_service.dart';
import 'package:pro_peloton_manager/ui/screens/in_house_bike_brand_factory_screen.dart';
import 'package:pro_peloton_manager/ui/screens/mtb_xco_world_cup_screen.dart';
import 'package:pro_peloton_manager/ui/screens/multiplayer_leagues_and_challenges_screen.dart';

void main() {
  const responsiveSizes = <Size>[
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ];

  group('1. Ligi Multiplayer, ELO, Duchy i Sync .ppmleague', () {
    const syncService = AsyncMultiplayerLeagueSyncService();
    final baseTime = DateTime.utc(2026, 7, 1, 10, 0);

    const lockedWeather = WeatherConditionSnapshot(
      weatherSeed: 42401,
      temperatureC: 24.5,
      windSpeedKmh: 18.0,
      windDirectionDegrees: 225.0,
      precipitationMmPerHour: 0.0,
      humidityPercent: 52.0,
      roadWetness: 0.0,
      weatherLabel: 'Słonecznie, umiarkowany wiatr',
    );

    OnlineLeagueModel buildSampleLeague() {
      return OnlineLeagueModel(
        leagueId: 'league_pkg6_01',
        name: 'Puchar WorldTour Online',
        format: LeagueFormat.seasonPoints,
        privacy: LeaguePrivacy.publicRanked,
        status: LeagueStatus.recruiting,
        seasonNumber: 1,
        maxParticipants: 8,
        createdAt: baseTime,
        startsAt: baseTime.add(const Duration(days: 1)),
        endsAt: baseTime.add(const Duration(days: 14)),
        participants: [
          LeagueParticipantEntry(
            participantId: 'p1',
            displayName: 'Janek',
            teamName: 'Bora Polska',
            eloAtJoin: 1450,
            currentElo: 1450,
            role: LeagueMemberRole.commissioner,
            joinedAt: baseTime,
          ),
          LeagueParticipantEntry(
            participantId: 'p2',
            displayName: 'Marek',
            teamName: 'Alpecin North',
            eloAtJoin: 1520,
            currentElo: 1520,
            role: LeagueMemberRole.participant,
            joinedAt: baseTime.add(const Duration(minutes: 5)),
          ),
        ],
        schedule: [
          LeagueStageScheduleEntry(
            stageIndex: 0,
            stageId: 'stage_alpe',
            stageName: 'Alpe d\'Huez Summit',
            distanceKm: 138.0,
            elevationGainM: 3400.0,
            lockedWeather: lockedWeather,
            opensAt: baseTime,
            closesAt: baseTime.add(const Duration(days: 3)),
          ),
        ],
      );
    }

    test('EloCalculator liczy poprawnie H2H i delty wieloosobowe', () {
      final expectedEqual = EloCalculator.expectedScore(1500, 1500);
      expect(expectedEqual, closeTo(0.5, 1e-6));

      final upsetWinDelta = EloCalculator.calculateHeadToHeadDelta(
        playerElo: 1300,
        opponentElo: 1650,
        actualScore: 1.0,
        matchesPlayed: 25,
      );
      expect(upsetWinDelta, greaterThan(15));

      final deltas = EloCalculator.calculateMultiPlayerStageDeltas(
        orderedRatings: const [1400, 1500, 1600],
      );
      expect(deltas.length, 3);
      expect(deltas[0], greaterThan(0));
      expect(deltas[2], lessThan(0));
      expect(EloDivisionTier.fromElo(2350), EloDivisionTier.grandTourLegend);
    });

    test('Snake Draft, walidacja pogody i synchronizacja wyników z ELO', () {
      final league = buildSampleLeague();
      final started = syncService.createDraftSession(
        league,
        availableRiderIds: const ['r1', 'r2', 'r3', 'r4'],
        strategy: DraftOrderStrategy.snake,
        ridersPerTeam: 2,
      );

      expect(started.league.status, LeagueStatus.drafting);
      expect(started.draftState.currentParticipantId, 'p1');

      final pick1 = syncService.submitDraftPick(
        league: started.league,
        draftState: started.draftState,
        participantId: 'p1',
        riderId: 'r1',
        riderName: 'Tadej P.',
        now: baseTime,
      );
      expect(pick1.draftState.currentParticipantId, 'p2');

      final pick2 = syncService.submitDraftPick(
        league: pick1.league,
        draftState: pick1.draftState,
        participantId: 'p2',
        riderId: 'r2',
        now: baseTime,
      );
      // Runda 2 w trybie snake odwraca kolejność: p2 wybiera ponownie.
      expect(pick2.draftState.currentParticipantId, 'p2');

      final pick3 = syncService.autoPickForCurrentTurn(
        league: pick2.league,
        draftState: pick2.draftState,
        now: baseTime,
      );
      final pick4 = syncService.autoPickForCurrentTurn(
        league: pick3.league,
        draftState: pick3.draftState,
        now: baseTime,
      );

      expect(pick4.draftState.isDraftComplete, isTrue);
      expect(pick4.league.status, LeagueStatus.active);
      expect(pick4.league.getParticipantById('p1')!.draftedRiderIds.length, 2);
      expect(pick4.league.getParticipantById('p2')!.draftedRiderIds.length, 2);

      final wrongWeatherResult = LeagueStageResultEntry(
        participantId: 'p1',
        finishTimeSeconds: 12450.0,
        averageWatts: 315.0,
        normalizedPower: 335.0,
        averageSpeedKmh: 39.9,
        weatherHash: 'invalid_weather_hash',
        submittedAt: baseTime,
      );
      final invalidCheck = syncService.validateStageResultSubmission(
        league: pick4.league,
        stageIndex: 0,
        entry: wrongWeatherResult,
      );
      expect(invalidCheck.isValid, isFalse);

      final resP1 = syncService.submitAndSyncStageResult(
        league: pick4.league,
        stageIndex: 0,
        entry: wrongWeatherResult.copyWith(
          weatherHash: lockedWeather.weatherHash,
        ),
        now: baseTime,
      );
      expect(resP1.stageCompleted, isFalse);

      final resP2 = syncService.submitAndSyncStageResult(
        league: resP1.league,
        stageIndex: 0,
        entry: LeagueStageResultEntry(
          participantId: 'p2',
          finishTimeSeconds: 12510.0,
          averageWatts: 308.0,
          normalizedPower: 326.0,
          averageSpeedKmh: 39.7,
          weatherHash: lockedWeather.weatherHash,
          submittedAt: baseTime,
        ),
        now: baseTime,
      );

      expect(resP2.stageCompleted, isTrue);
      expect(resP2.eloUpdatedCount, 2);
      expect(resP2.league.status, LeagueStatus.completed);
      expect(
        resP2.league.getParticipantById('p1')!.currentElo,
        greaterThan(1450),
      );
      expect(
        resP2.league.getParticipantById('p2')!.currentElo,
        lessThan(1520),
      );
    });

    test('Wyzwanie Ducha (interpolacja) i paczka .ppmleague GZip z FNV-1a64', () {
      final league = buildSampleLeague();
      final ghost = GhostChallengeModel(
        challengeId: 'ghost_01',
        title: 'Czasówka Mont Ventoux',
        creatorId: 'p1',
        creatorName: 'Janek',
        stageId: 'ventoux_itt',
        stageName: 'Bédoin -> Mont Ventoux',
        distanceKm: 21.4,
        elevationGainM: 1610.0,
        weatherSnapshot: lockedWeather,
        targetFinishTimeSeconds: 3420.0,
        targetAverageWatts: 395.0,
        targetTelemetry: const [
          GhostTelemetrySample(
            elapsedSeconds: 0.0,
            distanceKm: 0.0,
            speedKmh: 28.0,
            powerWatts: 380.0,
            heartRateBpm: 148,
            cadenceRpm: 90,
            elevationM: 300.0,
            gradientPercent: 4.0,
          ),
          GhostTelemetrySample(
            elapsedSeconds: 100.0,
            distanceKm: 0.7,
            speedKmh: 22.0,
            powerWatts: 400.0,
            heartRateBpm: 172,
            cadenceRpm: 84,
            elevationM: 360.0,
            gradientPercent: 8.6,
          ),
        ],
        createdAt: baseTime,
        expiresAt: baseTime.add(const Duration(days: 7)),
      );

      final interp = ghost.interpolateGhostAtTime(50.0);
      expect(interp, isNotNull);
      expect(interp!.speedKmh, closeTo(25.0, 0.01));
      expect(interp.powerWatts, closeTo(390.0, 0.01));
      expect(ghost.verifyWeatherParity(lockedWeather), isTrue);

      final package = MultiplayerLeaguePackage(
        exportedAt: baseTime,
        league: league,
        ghostChallenges: [ghost],
      ).withValidChecksum();
      expect(package.isChecksumValid, isTrue);

      final exported = syncService.encodePackageToPpmLeague(
        package,
        compress: true,
      );
      expect(exported.fileName, endsWith(kPpmLeagueFileExtension));
      expect(exported.encodedPayload, startsWith(kPpmLeagueGzipPrefix));

      final decoded = syncService.decodePackageFromPpmLeague(
        exported.encodedPayload,
      );
      expect(decoded.isChecksumValid, isTrue);
      expect(decoded.league?.leagueId, league.leagueId);
      expect(decoded.ghostChallenges.length, 1);
      expect(decoded.ghostChallenges.first.challengeId, 'ghost_01');
    });

    testWidgets(
      'MultiplayerLeaguesAndChallengesScreen renderuje się bez overflow 390/1024/1600',
      (tester) async {
        for (final size in responsiveSizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const MultiplayerLeaguesAndChallengesScreen(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow lub wyjątek dla rozdzielczości $size',
          );
        }
        await tester.binding.setSurfaceSize(null);
      },
    );
  });

  group('2. Fizyka MTB XCO, Zawieszenie 100-120mm, Dropper Post i Opony 2.4"', () {
    final noveMesto = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();

    test('Model rundy Nové Město posiada Rock Gardeny, Dropy i rekomenduje 120mm', () {
      expect(noveMesto.lapDistanceKm, closeTo(4.2, 0.01));
      expect(noveMesto.rockGardenCount, greaterThanOrEqualTo(1));
      expect(noveMesto.dropCount, greaterThanOrEqualTo(1));
      expect(noveMesto.recommendedTravelMm, 120);
      expect(noveMesto.segmentAtDistance(500.0)?.featureType, MtbXcoFeatureType.rockGarden);
    });

    test('Full-Suspension 120mm + Dropper dominuje nad Hardtailem 100mm na A-Line', () {
      final optimal = MtbSuspensionDampingAndLineChoiceSolver.recommendOptimalSetup(
        course: noveMesto,
        riderMassKg: 68.0,
      );

      final proFsBike = MtbXcoBikeConfiguration(
        bikeId: 'fs_120_pro',
        modelName: 'WorldCup FS 120 Flight',
        totalWeightKg: 9.8,
        suspension: MtbForkAndShockSetup(
          architecture: MtbSuspensionArchitecture.fullSuspensionDowncountry120,
          forkTravelMm: 120,
          rearShockTravelMm: 120,
          forkAirPressurePsi: optimal.recommendedForkPsi,
          rearShockAirPressurePsi: optimal.recommendedRearShockPsi,
          forkReboundClicks: optimal.recommendedForkReboundClicks,
          rearReboundClicks: optimal.recommendedRearReboundClicks,
          hasElectronicFlightAttendant: true,
        ),
        dropperPost: const DropperPostSpec(
          travelMm: 125,
          isWirelessElectronic: true,
          currentState: DropperPostState.slammed,
        ),
        tireSetup: MtbTire24Setup(
          frontPressureBar: optimal.recommendedFrontTireBar,
          rearPressureBar: optimal.recommendedRearTireBar,
          treadPattern: optimal.recommendedTreadPattern,
          hasRimInsert: true,
        ),
      );

      const basicHardtail = MtbXcoBikeConfiguration(
        bikeId: 'ht_100_basic',
        modelName: 'Hardtail 100 RigidPost',
        totalWeightKg: 9.4,
        suspension: MtbForkAndShockSetup(
          architecture: MtbSuspensionArchitecture.hardtail,
          forkTravelMm: 100,
          rearShockTravelMm: 0,
          forkAirPressurePsi: 115.0,
          rearShockAirPressurePsi: 0.0,
          hasElectronicFlightAttendant: false,
          remoteLockoutMode: SuspensionLockoutMode.locked,
        ),
        dropperPost: DropperPostSpec(
          travelMm: 0,
          isWirelessElectronic: false,
          currentState: DropperPostState.extended,
        ),
        tireSetup: MtbTire24Setup(
          frontPressureBar: 1.05,
          rearPressureBar: 1.05,
          treadPattern: MtbTireTreadPattern.fastSemiSlick,
          hasRimInsert: false,
        ),
      );

      final fsReadiness = proFsBike.evaluateCourseReadiness(noveMesto, 68.0);
      final htReadiness = basicHardtail.evaluateCourseReadiness(noveMesto, 68.0);

      expect(fsReadiness.overallScore, greaterThan(htReadiness.overallScore));
      expect(htReadiness.warnings, isNotEmpty);

      final rockGarden = noveMesto.segments.firstWhere(
        (s) => s.featureType == MtbXcoFeatureType.rockGarden,
      );

      final fsSegResult = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: rockGarden,
          bikeConfig: proFsBike,
          soilCondition: noveMesto.soilCondition,
          riderMassKg: 68.0,
          powerWatts: 360.0,
          bikeHandling: 90.0,
          descendingSkill: 88.0,
          deterministicRoll: 0.99,
        ),
      );

      final htSegResult = MtbSuspensionDampingAndLineChoiceSolver.solveSegment(
        MtbSuspensionAndLineInput(
          segment: rockGarden,
          bikeConfig: basicHardtail,
          soilCondition: noveMesto.soilCondition,
          riderMassKg: 68.0,
          powerWatts: 360.0,
          bikeHandling: 72.0,
          descendingSkill: 70.0,
          deterministicRoll: 0.99,
        ),
      );

      expect(fsSegResult.chosenLine, MtbTrailLineChoice.aLine);
      expect(
        fsSegResult.dampingMetrics.dampingAbsorptionRatio,
        greaterThan(htSegResult.dampingMetrics.dampingAbsorptionRatio),
      );
      expect(
        fsSegResult.segmentTimeSeconds,
        lessThan(htSegResult.segmentTimeSeconds),
      );

      final lapFs = MtbSuspensionDampingAndLineChoiceSolver.simulateLap(
        course: noveMesto,
        bikeConfig: proFsBike,
        riderMassKg: 68.0,
        bikeHandling: 90.0,
        descendingSkill: 88.0,
        deterministicRoll: 0.99,
      );
      expect(lapFs.totalLapTimeSeconds, inInclusiveRange(450.0, 1200.0));
      expect(lapFs.aLinesTaken, greaterThanOrEqualTo(1));
      expect(lapFs.segmentResults.length, noveMesto.segments.length);
    });

    test('Serializacja JSON MtbXcoBikeConfiguration zachowuje wszystkie parametry', () {
      const config = MtbXcoBikeConfiguration(
        bikeId: 'xco_roundtrip',
        modelName: 'Vortex XCO Team',
        totalWeightKg: 9.95,
      );
      final restored = MtbXcoBikeConfiguration.fromJson(config.toJson());
      expect(restored.bikeId, config.bikeId);
      expect(restored.modelName, config.modelName);
      expect(restored.totalWeightKg, closeTo(9.95, 1e-6));
    });

    testWidgets(
      'MtbXcoWorldCupScreen renderuje się bez overflow 390/1024/1600',
      (tester) async {
        for (final size in responsiveSizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: const MtbXcoWorldCupScreen(show3dPreview: false),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow lub wyjątek MTB dla rozdzielczości $size',
          );
        }
        await tester.binding.setSurfaceSize(null);
      },
    );
  });

  group('3. Fabryka Własnej Marki Rowerowej, R&D, CAD, Licencje B2B i Finanse', () {
    test('Cykl życia marki: rozbudowa, projekt R&D do homologacji, licencja B2B i kwartał', () {
      var brand = InHouseBikeBrandModel.createStarter(
        brandId: 'brand_vortex',
        ownerTeamId: 'team_pol',
        ownerTeamName: 'Polonia WorldTeam',
        brandName: 'Vortex Cycles',
        seasonYear: 2026,
      );

      expect(brand.homologatedBlueprints.length, 2);
      expect(brand.asOwnTeamManufacturerDeal().manufacturerName, 'Vortex Cycles');

      // Próba rozbudowy bez wystarczającej gotówki
      final poorUpgrade = brand.upgradeFacility(
        nextTier: ManufacturingFacilityTier.carbonBoutiqueLab,
        availableTeamCashEur: 50000,
      );
      expect(poorUpgrade.success, isFalse);

      // Udana rozbudowa fabryki
      final richUpgrade = brand.upgradeFacility(
        nextTier: ManufacturingFacilityTier.carbonBoutiqueLab,
        availableTeamCashEur: 3000000,
      );
      expect(richUpgrade.success, isTrue);
      expect(richUpgrade.cashDeltaEur, lessThan(0));
      brand = richUpgrade.model;
      expect(brand.facilityTier, ManufacturingFacilityTier.carbonBoutiqueLab);

      // Uruchomienie projektu R&D Ultralight
      final targetBp = brand.blueprints.first;
      final initialWeight = targetBp.weightGrams;
      final rdStart = brand.startRdProject(
        projectId: 'rd_ul_01',
        title: 'Carbon Nano-Resin Layup',
        targetBlueprintId: targetBp.blueprintId,
        focus: RdProjectFocus.ultralightLayup,
        budgetEur: 180000,
        availableTeamCashEur: 1500000,
      );
      expect(rdStart.success, isTrue);
      brand = rdStart.model;
      expect(brand.activeRdProjects.length, 1);

      // Postęp 90 dni -> ukończenie projektu i redukcja masy blueprintu
      brand = brand.advanceRdProjects(90);
      expect(brand.activeRdProjects.first.status, RdProjectStatus.homologated);
      final upgradedBp = brand.blueprints.firstWhere(
        (b) => b.blueprintId == targetBp.blueprintId,
      );
      expect(upgradedBp.weightGrams, lessThan(initialWeight));
      expect(upgradedBp.rdGeneration, 2);

      // Podpisanie licencji B2B z inną ekipą
      final contract = ExternalTeamLicenseContract(
        contractId: 'lic_ext_01',
        partnerTeamId: 'team_bel',
        partnerTeamName: 'Flanders Pro Cycling',
        targetDivision: TeamFrameTargetDivision.proTeam,
        suppliedBlueprintId: upgradedBp.blueprintId,
        annualLicenseFeeEur: 220000,
        framesOrderedPerSeason: 40,
        pricePerFrameEur: upgradedBp.wholesalePriceEur,
        royaltyPerWorldTourWinEur: 15000,
        yearsRemaining: 2,
        status: BrandLicenseDealStatus.active,
        satisfactionScore: 88.0,
      );
      final signResult = brand.signLicenseContract(contract);
      expect(signResult.success, isTrue);
      brand = signResult.model;
      expect(brand.activeLicenseContracts.length, 1);

      // Zamknięcie kwartału finansowego i round-trip JSON
      final quarterResult = brand.simulateQuarterFinancials(
        seasonYear: 2026,
        quarter: 1,
        ownTeamFramesConsumed: 18,
        partnerWorldTourWins: 2,
      );
      expect(quarterResult.success, isTrue);
      expect(quarterResult.model.quarterlyReports.length, 1);
      final report = quarterResult.model.quarterlyReports.first;
      expect(report.framesSoldToTeams, 10);
      expect(report.licenseRevenueEur, greaterThan(0));

      final restored = InHouseBikeBrandModel.fromJson(
        quarterResult.model.toJson(),
      );
      expect(restored.brandId, brand.brandId);
      expect(restored.quarterlyReports.length, 1);
      expect(restored.activeLicenseContracts.length, 1);
    });

    test('FrameGeometryCalculator i InHouseBikeBrandFactoryNotifier działają spójnie', () {
      const aeroGeo = FrameGeometrySpec(
        stackMm: 525.0,
        reachMm: 398.0,
        headTubeAngleDeg: 73.5,
        seatTubeAngleDeg: 74.0,
        chainstayMm: 405.0,
        wheelbaseMm: 985.0,
        bbDropMm: 70.0,
      );
      final aeroEval = FrameGeometryCalculator.evaluate(
        spec: aeroGeo,
        category: FrameCategory.aero,
        carbonGrade: CarbonLayupGrade.ultraHighModulusT1100,
        rdEngineeringLevel: 80,
      );
      expect(aeroEval.uciLegal, isTrue);
      expect(aeroEval.aeroCdaModifier, lessThan(-0.015));

      final notifier = InHouseBikeBrandFactoryNotifier();
      final created = notifier.createNewBlueprint(
        modelName: 'Vortex Aero CAD-9',
        category: FrameCategory.aero,
        carbonGrade: CarbonLayupGrade.ultraHighModulusT1100,
        evaluation: aeroEval,
      );
      expect(notifier.state.model.blueprints.contains(created), isTrue);

      final prevQuarter = notifier.state.currentQuarter;
      final qRes = notifier.simulateQuarter(
        ownTeamFramesConsumed: 12,
        partnerWorldTourWins: 1,
      );
      expect(qRes.success, isTrue);
      expect(
        notifier.state.currentQuarter,
        prevQuarter == 4 ? 1 : prevQuarter + 1,
      );
    });

    testWidgets(
      'InHouseBikeBrandFactoryScreen renderuje się bez overflow 390/1024/1600',
      (tester) async {
        for (final size in responsiveSizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: const InHouseBikeBrandFactoryScreen(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow lub wyjątek Fabryki dla rozdzielczości $size',
          );
        }
        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
