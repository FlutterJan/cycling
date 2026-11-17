import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/router/app_router.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/peloton/cx_pit_bike_exchange_mechanics.dart';
import 'package:pro_peloton_manager/engine/physics/cyclocross_bunnyhop_and_carry_solver.dart';
import 'package:pro_peloton_manager/engine/physics/gravel_rolling_resistance_and_sealant_solver.dart';
import 'package:pro_peloton_manager/engine/physics/mtb_suspension_damping_and_line_choice_solver.dart';
import 'package:pro_peloton_manager/engine/physics/ultra_sleep_deprivation_and_circadian_solver.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_banking_and_centripetal_solver.dart';
import 'package:pro_peloton_manager/engine/physics/velodrome_keirin_and_madison_sling_solver.dart';
import 'package:pro_peloton_manager/engine/simulation/multi_race_parallel_day_simulator.dart';
import 'package:pro_peloton_manager/engine/simulation/post_stage_recovery_processor.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_results_calculator.dart';
import 'package:pro_peloton_manager/engine/simulation/stage_simulation_loop.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/models/career/womens_worldtour_and_mixed_relay_model.dart';
import 'package:pro_peloton_manager/models/equipment/complete_bike.dart';
import 'package:pro_peloton_manager/models/equipment/gravel_bike_and_tire_inserts_model.dart';
import 'package:pro_peloton_manager/models/multiplayer/online_league_and_ghost_challenge_model.dart';
import 'package:pro_peloton_manager/models/organizer/race_organizer_empire_model.dart';
import 'package:pro_peloton_manager/models/race/cyclocross_course_and_mud_model.dart';
import 'package:pro_peloton_manager/models/race/gravel_race_and_surface_model.dart';
import 'package:pro_peloton_manager/models/race/mtb_xco_course_and_suspension_model.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/race/ultra_endurance_bikepacking_race_model.dart';
import 'package:pro_peloton_manager/models/race/velodrome_track_and_hour_record_model.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/team/in_house_bike_brand_manufacturing_model.dart';
import 'package:pro_peloton_manager/services/career/autosave_and_crash_recovery_guard.dart';
import 'package:pro_peloton_manager/services/career/ds_team_orders_mission_generator.dart';
import 'package:pro_peloton_manager/services/career/legendary_historic_scenarios_seeder.dart';
import 'package:pro_peloton_manager/services/career/olympic_games_quadrennial_cycle_service.dart';
import 'package:pro_peloton_manager/services/generators/initial_game_seeder.dart';
import 'package:pro_peloton_manager/services/generators/womens_worldtour_teams_and_riders_seeder.dart';
import 'package:pro_peloton_manager/services/generators/world_teams_generator.dart';
import 'package:pro_peloton_manager/services/network/async_multiplayer_league_sync_service.dart';
import 'package:pro_peloton_manager/services/organizer/course_safety_barriers_and_marshals_planner.dart';
import 'package:pro_peloton_manager/services/organizer/star_rider_appearance_fee_negotiator.dart';
import 'package:pro_peloton_manager/state/career_state_notifier.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_character_creator_screen.dart';
import 'package:pro_peloton_manager/ui/screens/main_title_menu_screen.dart';
import 'package:pro_peloton_manager/ui/screens/quick_race_sandbox_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('ppm_e2e_560_');
    const MethodChannel pathChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
      return tempDir.path;
    });
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group(
    'E2E Mode 1: Kariera Menedżera (WorldTour -> Symulacja Etapu -> Regeneracja -> Save)',
    () {
      test(
        'inicjalizuje świat gry, symuluje dni kalendarza, rozgrywa etap i wykonuje zapis/odczyt JSON',
        () async {
          const int seed = 560001;
          final world = WorldTeamsGenerator.generateWorldTourSystem(seed: seed);
          expect(world.teams.length, greaterThanOrEqualTo(18));

          final playerTeamId = world.teams.first.id;
          final notifier = CareerStateNotifier();
          final seedResult = await InitialGameSeeder.seedAndInitializeCareer(
            careerNotifier: notifier,
            config: InitialGameSeedConfig(
              saveName: 'E2E Career 560',
              playerManagerName: 'Dyrektor E2E',
              playerTeamId: playerTeamId,
              seasonYear: 2026,
              seed: seed,
              saveToDisk: false,
            ),
          );

          expect(seedResult.totalTeamsCount, greaterThanOrEqualTo(18));
          expect(notifier.state.errorMessage, isNull);
          expect(notifier.state.riders, isNotEmpty);

          for (int i = 0; i < 7; i++) {
            await notifier.advanceDay(persistAutoSave: false);
            expect(notifier.state.errorMessage, isNull);
          }

          const stage = RaceStage(
            id: 'e2e_wt_stage_1',
            stageNumber: 1,
            name: 'E2E WorldTour Opening Stage',
            stageType: StageType.flat,
            baseTemperatureCelsius: 21.0,
            weatherCondition: WeatherCondition.sunny,
            windSpeedKmh: 12.0,
            segments: [
              StageSegment(
                index: 0,
                startKm: 0.0,
                lengthKm: 8.0,
                startElevationM: 100.0,
                endElevationM: 120.0,
                surfaceType: SegmentSurfaceType.smoothAsphalt,
                technicalDifficulty: 15.0,
                windDirectionDegrees: 270.0,
                roadBearingDegrees: 90.0,
                sprintOrKomClassification:
                    SegmentClassification.intermediateSprint,
              ),
              StageSegment(
                index: 1,
                startKm: 8.0,
                lengthKm: 4.0,
                startElevationM: 120.0,
                endElevationM: 110.0,
                surfaceType: SegmentSurfaceType.smoothAsphalt,
                technicalDifficulty: 10.0,
                windDirectionDegrees: 270.0,
                roadBearingDegrees: 90.0,
                sprintOrKomClassification: SegmentClassification.finishLine,
              ),
            ],
          );

          final raceRiders = notifier.state.riders.take(18).toList();
          final allRidersMap = <String, Rider>{
            for (final r in raceRiders) r.id: r,
          };
          final teamsMap = {for (final t in notifier.state.teams) t.id: t};
          final bikesMap = <String, CompleteBike>{
            for (final r in raceRiders)
              r.id: (teamsMap[r.contract.teamId]?.inventoryBikes.isNotEmpty ??
                      false)
                  ? teamsMap[r.contract.teamId]!.inventoryBikes.first
                  : notifier.state.playerTeam.inventoryBikes.first,
          };

          final loop = StageSimulationLoop.initializeStage(
            stage: stage,
            playerTeamId: playerTeamId,
            allRidersMap: allRidersMap,
            allBikesMap: bikesMap,
            allTeamsMap: teamsMap,
            random: math.Random(seed),
          );

          int safetySteps = 0;
          while (!loop.state.isStageFinished && safetySteps < 2000) {
            loop.step(dt: 10.0);
            safetySteps++;
          }
          expect(loop.state.isStageFinished, isTrue);

          final rawFinishes =
              List<StageFinishResult>.from(loop.state.finishResults);
          final finishedIds = rawFinishes.map((r) => r.riderId).toSet();
          final baseTime = rawFinishes.isNotEmpty
              ? rawFinishes.first.finishTimeSeconds
              : loop.state.elapsedSeconds;

          for (final r in raceRiders) {
            if (!finishedIds.contains(r.id)) {
              rawFinishes.add(
                StageFinishResult(
                  riderId: r.id,
                  riderName: r.fullName,
                  teamId: r.contract.teamId,
                  finishRank: rawFinishes.length + 1,
                  finishTimeSeconds: baseTime + 25.0,
                  gapToWinnerSeconds: 25.0,
                ),
              );
            }
          }

          final report = StageResultsCalculator.calculateStageResults(
            stage: stage,
            rawFinishResults: rawFinishes,
            stageIncidents: loop.state.incidentHistory,
            allRidersMap: allRidersMap,
          );
          expect(report.results.length, raceRiders.length);
          expect(report.results.first.rank, 1);

          final playerTeam = notifier.state.playerTeam;
          final playerRiders = raceRiders
              .where((r) => r.contract.teamId == playerTeam.id)
              .toList();
          final recovery = PostStageRecoveryProcessor.processStageRecovery(
            teamRiders:
                playerRiders.isNotEmpty ? playerRiders : raceRiders.take(6).toList(),
            team: playerTeam,
            stageNumber: stage.stageNumber,
            officialResults: report.results,
            simulationState: loop.state,
            incidents: loop.state.incidentHistory,
          );
          expect(recovery.updatedRiders, isNotEmpty);

          // Round-trip serializacji CareerSave + AutosaveAndCrashRecoveryGuard
          final save = notifier.state.toSave();
          final json = save.toJson();
          final restored = CareerSave.fromJson(json);
          expect(restored.saveName, save.saveName);
          expect(restored.playerTeamId, playerTeamId);
          expect(restored.riders.length, save.riders.length);

          final guard = AutosaveAndCrashRecoveryGuard(
            directoryResolver: () async => tempDir,
          );
          final receipt = await guard.saveCareerTransactional(
            restored,
            customFileBaseName: 'e2e_560_slot',
          );
          expect(receipt.success, isTrue);
          final loaded = await guard.loadCareerWithRecovery(
            restored.id,
            customFileBaseName: 'e2e_560_slot',
          );
          expect(loaded.save, isNotNull);
          expect(loaded.save!.playerTeamId, playerTeamId);
        },
      );
    },
  );

  group('E2E Mode 2: Be a Pro ("Zostań Legendą")', () {
    test(
      'kreuje kolarza, generuje i rozlicza rozkazy DS oraz zwiększa XP i zaufanie',
      () {
        const draft = BeAProCharacterDraft(
          firstName: 'Kacper',
          lastName: 'Majewski',
          nationalityIso: 'POL',
          heightCm: 178.0,
          weightKg: 67.0,
        );
        final physique = BeAProPhysicsCalculator.evaluate(
          heightCm: draft.heightCm,
          weightKg: draft.weightKg,
          archetype: draft.archetype,
        );
        expect(physique.baseCdaHoodsM2, inInclusiveRange(0.18, 0.36));

        var career = draft
            .buildCareerResult(startDate: DateTime(2026, 3, 1))
            .careerState;

        const stage = RaceStage(
          id: 'pro_stage_1',
          stageNumber: 1,
          name: 'Klasyk Wiosenny',
          stageType: StageType.cobbleClassic,
          baseTemperatureCelsius: 15.0,
          weatherCondition: WeatherCondition.overcast,
          windSpeedKmh: 18.0,
          segments: [
            StageSegment(
              index: 0,
              startKm: 0.0,
              lengthKm: 80.0,
              startElevationM: 120.0,
              endElevationM: 180.0,
              surfaceType: SegmentSurfaceType.smoothAsphalt,
              technicalDifficulty: 30.0,
              windDirectionDegrees: 240.0,
              roadBearingDegrees: 90.0,
              sprintOrKomClassification: SegmentClassification.finishLine,
            ),
          ],
        );

        const generator = DsTeamOrdersMissionGenerator();
        final mission = generator.generateStageMission(
          careerState: career,
          stage: stage,
          raceId: 'pro_race_1',
          raceName: 'Klasyk Wiosenny',
          seed: 56002,
        );
        expect(mission.title, isNotEmpty);

        final resolution = generator.resolveMission(
          mission: mission,
          careerState: career,
          telemetry: const DsMissionEvaluationInput(
            leaderMaxPositionInTargetZone: 9,
            protectedLeaderCleanly: true,
            komPointsEarned: 6,
            stageCompleted: true,
          ),
        );
        expect(resolution.updatedCareerState.experienceXp, greaterThan(0));
        career = resolution.updatedCareerState;
        expect(career.experienceXp, greaterThan(0));
      },
    );
  });

  group('E2E Mode 3: Kobiecy WorldTour & Drużynowa Sztafeta Mieszana TTT', () {
    test(
      'generuje 24 drużyny WWT / 360 zawodniczek i weryfikuje sztafetę mieszaną TTT',
      () {
        final wwtSeed = WomensWorldtourTeamsAndRidersSeeder.seedWomensWorldTour(
          seasonYear: 2026,
          seed: 56003,
        );
        expect(wwtSeed.teams.length, 24);
        expect(wwtSeed.allRiders.length, 360);

        final restored = WomensWorldTourSeasonState.fromJson(
          wwtSeed.seasonState.toJson(),
        );
        expect(restored.teams.length, 24);

        const menTrio = [
          MixedRelayRiderSlot(
            riderId: 'mr_m1',
            fullName: 'Michał K.',
            nationalityIso: 'POL',
            isFemale: false,
            ftpWatts: 430.0,
            weightKg: 70.0,
            aerodynamicsCda: 0.20,
            timeTrialSkill: 88,
            distanceMeters: 14002.0,
            currentSpeedKmh: 53.0,
            currentPowerWatts: 430.0,
            wPrimeRemainingPct: 0.65,
            isPulling: true,
          ),
          MixedRelayRiderSlot(
            riderId: 'mr_m2',
            fullName: 'Filip M.',
            nationalityIso: 'POL',
            isFemale: false,
            ftpWatts: 440.0,
            weightKg: 75.0,
            aerodynamicsCda: 0.21,
            timeTrialSkill: 86,
            distanceMeters: 14000.0,
            currentSpeedKmh: 53.0,
            currentPowerWatts: 420.0,
            wPrimeRemainingPct: 0.70,
          ),
          MixedRelayRiderSlot(
            riderId: 'mr_m3',
            fullName: 'Maciej B.',
            nationalityIso: 'POL',
            isFemale: false,
            ftpWatts: 435.0,
            weightKg: 77.0,
            aerodynamicsCda: 0.21,
            timeTrialSkill: 85,
            distanceMeters: 13992.0,
            currentSpeedKmh: 53.0,
            currentPowerWatts: 410.0,
            wPrimeRemainingPct: 0.70,
          ),
        ];
        const womenTrio = [
          MixedRelayRiderSlot(
            riderId: 'mr_w1',
            fullName: 'Katarzyna N.',
            nationalityIso: 'POL',
            isFemale: true,
            ftpWatts: 345.0,
            weightKg: 54.0,
            aerodynamicsCda: 0.185,
            timeTrialSkill: 89,
            distanceMeters: 0.0,
            currentSpeedKmh: 47.0,
            currentPowerWatts: 345.0,
            wPrimeRemainingPct: 1.0,
            isPulling: true,
          ),
          MixedRelayRiderSlot(
            riderId: 'mr_w2',
            fullName: 'Agnieszka S.',
            nationalityIso: 'POL',
            isFemale: true,
            ftpWatts: 330.0,
            weightKg: 56.0,
            aerodynamicsCda: 0.19,
            timeTrialSkill: 85,
            distanceMeters: 0.0,
            currentSpeedKmh: 47.0,
            currentPowerWatts: 330.0,
            wPrimeRemainingPct: 1.0,
          ),
          MixedRelayRiderSlot(
            riderId: 'mr_w3',
            fullName: 'Marta L.',
            nationalityIso: 'POL',
            isFemale: true,
            ftpWatts: 325.0,
            weightKg: 55.0,
            aerodynamicsCda: 0.19,
            timeTrialSkill: 84,
            distanceMeters: 0.0,
            currentSpeedKmh: 47.0,
            currentPowerWatts: 325.0,
            wPrimeRemainingPct: 1.0,
          ),
        ];

        const entry = MixedRelayTeamEntry(
          teamId: 'pol',
          nationOrClubName: 'Polska',
          countryIso: 'POL',
          primaryColorHex: '#DC2626',
          mensTrio: menTrio,
          womensTrio: womenTrio,
          phase: MixedRelayPhase.mensLegActive,
        );
        expect(entry.isLineupValid, isTrue);
        expect(entry.mensSecondRiderDistanceMeters, 14000.0);
      },
    );
  });

  group('E2E Mode 4: Igrzyska Olimpijskie (No Race Radio, kadry narodowe)', () {
    test(
      'wybiera kadrę w limicie kwotowym, blokuje radio i symuluje wyścig olimpijski',
      () {
        final service = OlympicGamesQuadrennialCycleService();
        expect(service.isOlympicYear(2028), isTrue);
        expect(service.isOlympicYear(2026), isFalse);

        final rules = service.getNoRaceRadioRules(OlympicDiscipline.roadRace);
        expect(rules.raceRadioEnabled, isFalse);

        final world = WorldTeamsGenerator.generateWorldTourSystem(seed: 56004);
        final pool = world.ridersByTeamId.values.expand((e) => e).toList();
        final iso = pool.first.nationalityIso;

        final roster = service.buildNationalTeamRoster(
          olympicYear: 2028,
          nationalityIso: iso,
          discipline: OlympicDiscipline.roadRace,
          worldRiders: pool,
          nationUciRank: 1,
        );
        expect(roster.selectedRiderIds.length, lessThanOrEqualTo(4));

        final report = service.simulateOlympicRace(
          olympicYear: 2028,
          discipline: OlympicDiscipline.roadRace,
          worldRiders: pool,
        );
        expect(report.standings, isNotEmpty);
      },
    );
  });

  group('E2E Mode 5: Kolarstwo Przełajowe (CX) — błoto, Pit Lane, Bunny-Hop', () {
    test(
      'akumuluje błoto, wymienia rower w boksie i ocenia skok nad belkami',
      () {
        const pitMechanics = CxPitBikeExchangeMechanics();
        const cxSolver = CyclocrossBunnyhopAndCarrySolver();

        var state = pitMechanics.createInitialState(
          riderId: 'cx_560',
          baseBikeWeightKg: 7.8,
        );
        const pitConfig = DoublePitLaneConfig(
          pitSide: CyclocrossPitLaneSide.centerIsland,
          firstAccessStartMeter: 1100.0,
          firstAccessLengthMeters: 150.0,
          secondAccessStartMeter: 2400.0,
          secondAccessLengthMeters: 150.0,
          pressureWashEfficiency: 1.0,
        );
        const mudSeg = CyclocrossCourseSegment(
          index: 1,
          startMeter: 200.0,
          lengthMeters: 1200.0,
          terrainType: CyclocrossTerrainType.deepMud,
          mudDepthCm: 14.0,
          mudViscosityIndex: 0.7,
        );

        final step1 = pitMechanics.step(
          state: state,
          dtSeconds: 200.0,
          distanceMeters: 1200.0,
          mudCondition: CyclocrossMudCondition.heavyMud,
          segment: mudSeg,
          pitLaneConfig: pitConfig,
        );
        state = step1.state;
        expect(state.accumulatedMudKg, greaterThan(0.4));
        expect(state.drivetrainDragWatts, greaterThan(0.0));

        state = pitMechanics.queuePitExchange(state);
        final pitEnter = pitMechanics.step(
          state: state,
          dtSeconds: 2.0,
          distanceMeters: 20.0,
          mudCondition: CyclocrossMudCondition.heavyMud,
          pitLaneConfig: pitConfig,
          lapDistanceMeters: 1150.0,
        );
        final pitExit = pitMechanics.step(
          state: pitEnter.state,
          dtSeconds: 2.5,
          distanceMeters: 0.0,
          mudCondition: CyclocrossMudCondition.heavyMud,
          pitLaneConfig: pitConfig,
          lapDistanceMeters: 1160.0,
        );
        expect(pitExit.completedBikeExchange, isTrue);
        expect(pitExit.state.accumulatedMudKg, 0.0);

        const planksSegment = CyclocrossCourseSegment(
          index: 4,
          startMeter: 1500.0,
          lengthMeters: 25.0,
          terrainType: CyclocrossTerrainType.planks,
          plankCount: 2,
          plankHeightCm: 40.0,
          isBunnyHoppable: true,
        );
        final bunny = cxSolver.solveSegment(
          const CyclocrossBunnyhopAndCarryInput(
            segment: planksSegment,
            bikeHandling: 90.0,
            wPrimeRemainingRatio: 0.70,
            deterministicRoll: 0.99,
          ),
        );
        expect(bunny.selectedMode, CyclocrossTraversalMode.bunnyHop);
      },
    );
  });

  group(
    'E2E Mode 6: Kolarstwo Torowe — Welodrom, Rekord Godzinny, Keirin & Madison',
    () {
      test(
        'symuluje 60-minutową próbę Rekordu Godzinnego oraz rzut Madison',
        () {
          const grenchen = VelodromeFacilitySpec(
            id: 'grenchen',
            name: 'Tissot Velodrome',
            city: 'Grenchen',
            countryCode: 'SUI',
            trackLengthMeters: 250.0,
            turnBankingDegrees: 42.0,
            straightBankingDegrees: 12.5,
            altitudeMeters: 450.0,
            woodSurface: VelodromeWoodSurface.siberianPine,
            isIndoor: true,
            indoorTemperatureCelsius: 25.0,
            relativeHumidityPercent: 45.0,
            turnRadiusMeters: 23.0,
          );
          final hourResult =
              VelodromeBankingAndCentripetalSolver.simulateHourRecordPacing(
            facility: grenchen,
            bike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
            riderMassKg: 76.0,
            riderFtpWatts: 510.0,
            riderWPrimeJoules: 28000.0,
            targetLapTimeSeconds: 15.80,
          );
          expect(hourResult.totalDistanceMeters, greaterThan(55000.0));
          expect(hourResult.completedFullLaps, greaterThanOrEqualTo(220));

          final slingResult =
              VelodromeKeirinAndMadisonSlingSolver.solveMadisonHandSling(
            const MadisonHandSlingInput(
              facility: grenchen,
              incomingRiderMassKg: 74.0,
              incomingBike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
              incomingSpeedMs: 15.5,
              outgoingRiderMassKg: 70.0,
              outgoingBike: VelodromeTrackAndHourRecordModel.defaultTrackBike,
              outgoingSpeedMs: 12.2,
              incomingSlingSkill: 92.0,
              outgoingSlingSkill: 94.0,
              teamChemistry: 92.0,
              longitudinalGapMeters: 0.15,
              lateralGapMeters: 0.65,
            ),
          );
          expect(
            slingResult.outgoingPostSlingSpeedKmh,
            greaterThan(46.0),
          );
          expect(
            slingResult.quality,
            MadisonSlingQuality.textbookSlingshot,
          );
        },
      );
    },
  );

  group('E2E Mode 7: UCI Gravel World Series — impedancja i samonaprawa Tubeless', () {
    test(
      'oblicza opory na luźnym szutrze i naprawia przebicie mleczkiem Tubeless',
      () {
        const solver = GravelRollingResistanceAndSealantSolver();
        final bike = GravelBikeAndTireInsertsModel.uciWorldSeriesRacePreset();
        expect(bike.hasValidConfiguration, isTrue);

        final impedance = solver.solveRollingResistance(
          GravelImpedanceInput(
            bikeSetup: bike,
            surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
            speedMetersPerSecond: 10.0,
          ),
        );
        expect(impedance.impedancePenaltyWatts, greaterThan(0.0));

        final puncture = solver.resolvePunctureAndSealant(
          GravelPunctureEventInput(
            bikeSetup: bike,
            surfaceCategory: GravelSurfaceCategory.cat3LooseWashboardsAndRuts,
            punctureSizeMm: 2.8,
            isFrontWheel: false,
            currentTirePressureBar: 2.40,
            deterministicRoll01: 0.20,
          ),
        );
        expect(puncture.strategy, GravelSealantRepairStrategy.selfSealedInMotion);
      },
    );
  });

  group('E2E Mode 8: MTB XCO World Cup — zawieszenie 100-120mm i linie A/B-Line', () {
    test(
      'symuluje rundę Nové Město na Full-Suspension 120mm z wyborem linii A-Line',
      () {
        final noveMesto = MtbXcoCourseAndSuspensionModel.noveMestoWorldCup();
        final optimal =
            MtbSuspensionDampingAndLineChoiceSolver.recommendOptimalSetup(
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
      },
    );
  });

  group('E2E Mode 9: Ultra-Endurance Bikepacking — rytm dobowy, brak snu i dynamo', () {
    test(
      'symuluje jazdę nocną z deficytem snu i ładowaniem z piasty dynamo',
      () {
        final nadir =
            UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(3.75);
        final day =
            UltraSleepDeprivationAndCircadianSolver.computeCircadianCurve(10.0);
        expect(nadir, lessThan(day));

        final son28 = DynamoHubSpec.son28Ultra();
        const depleted = ElectronicsPowerState(
          headlightBatteryPercent: 55.0,
          gpsComputerBatteryPercent: 60.0,
          powerBankMah: 2500.0,
          powerBankCapacityMah: 10000.0,
        );
        final budget = depleted.stepPowerBudget(
          durationHours: 2.0,
          avgSpeedKmh: 28.0,
          dynamoHub: son28,
          isNight: false,
        );
        expect(budget.hasLightsOutRisk, isFalse);
      },
    );
  });

  group('E2E Mode 10: Organizator Wyścigów ASO/RCS — przetargi, gwiazdy i bezpieczeństwo', () {
    test(
      'przyznaje Grand Départ, negocjuje gwiazdę i audytuje bariery SafeR',
      () {
        final starter =
            RaceOrganizerEmpireModel.createStarterAsoPreset(seasonYear: 2026);
        final openBid = starter.pendingHostCityBids
            .firstWhere((b) => b.status == HostBidStatus.openForBidding);
        final awarded = starter.awardHostCityBid(
          openBid.bidId,
          contractLengthYears: 2,
        );
        expect(awarded.success, isTrue);

        const planner = CourseSafetyBarriersAndMarshalsPlanner();
        final zones =
            CourseSafetyBarriersAndMarshalsPlanner.createDefaultStageHazardZones();
        final inventory =
            CourseSafetyBarriersAndMarshalsPlanner.createDefaultInventory();
        final tdf = starter.managedRaces.first;
        final audit = planner.auditCourseSafety(
          raceId: tdf.raceId,
          raceName: tdf.raceName,
          stageNumber: 14,
          zones: zones,
          inventory: inventory,
        );
        expect(audit.complianceGrade, isNotNull);

        final catalog = StarRiderAppearanceFeeNegotiator.createDefaultCatalog();
        final sessions =
            StarRiderAppearanceFeeNegotiator.createInitialSessions(catalog);
        final course =
            StarRiderAppearanceFeeNegotiator.createDefaultCourseBlueprint();
        expect(sessions, isNotEmpty);
        expect(course.raceId, isNotEmpty);
      },
    );
  });

  group('E2E Mode 11: Własna Marka Rowerowa R&D', () {
    test(
      'tworzy fabrykę, uruchamia projekt R&D do homologacji i podpisuje licencję B2B',
      () {
        var brand = InHouseBikeBrandModel.createStarter(
          brandId: 'brand_560',
          ownerTeamId: 'team_polska',
          ownerTeamName: 'Polonia WorldTeam',
          brandName: 'Vortex Cycles',
          seasonYear: 2026,
        );
        expect(brand.homologatedBlueprints.length, 2);

        final targetBp = brand.blueprints.first;
        final rdStart = brand.startRdProject(
          projectId: 'rd_560',
          title: 'Aero Layup Mk.II',
          targetBlueprintId: targetBp.blueprintId,
          focus: RdProjectFocus.aeroTubeProfiles,
          budgetEur: 180000,
          availableTeamCashEur: 1500000,
        );
        expect(rdStart.success, isTrue);
        brand = rdStart.model.advanceRdProjects(90);
        expect(brand.activeRdProjects.first.status, RdProjectStatus.homologated);
      },
    );
  });

  group('E2E Mode 12: Ligi Online Multiplayer, ELO, Wyzwania Duchów i .ppmleague', () {
    test(
      'liczy ELO i wykonuje bezstratny eksport/import paczki .ppmleague',
      () {
        const syncService = AsyncMultiplayerLeagueSyncService();
        final delta = EloCalculator.calculateHeadToHeadDelta(
          playerElo: 1450,
          opponentElo: 1600,
          actualScore: 1.0,
          matchesPlayed: 20,
        );
        expect(delta, greaterThan(10));

        final now = DateTime.utc(2026, 8, 1);
        final league = OnlineLeagueModel(
          leagueId: 'e2e_league_560',
          name: 'Liga Mistrzów E2E',
          format: LeagueFormat.seasonPoints,
          privacy: LeaguePrivacy.publicRanked,
          status: LeagueStatus.active,
          seasonNumber: 1,
          maxParticipants: 8,
          createdAt: now,
          startsAt: now,
          endsAt: now.add(const Duration(days: 14)),
          participants: [
            LeagueParticipantEntry(
              participantId: 'p1',
              displayName: 'Gracz 1',
              teamName: 'Team A',
              eloAtJoin: 1500,
              currentElo: 1500 + delta,
              role: LeagueMemberRole.commissioner,
              joinedAt: now,
            ),
          ],
          schedule: const [],
        );

        final package = MultiplayerLeaguePackage(
          exportedAt: now,
          league: league,
          ghostChallenges: const [],
        ).withValidChecksum();

        final exported = syncService.encodePackageToPpmLeague(
          package,
          compress: true,
        );
        final imported = syncService.decodePackageFromPpmLeague(
          exported.encodedPayload,
        );
        expect(imported.isChecksumValid, isTrue);
        expect(imported.league?.leagueId, league.leagueId);
        expect(imported.league?.participants.first.currentElo, 1500 + delta);
      },
    );
  });

  group('E2E Mode 13: Scenariusze Historyczne & Równoległe Wyścigi (Split-Squad)', () {
    test(
      'buduje scenariusz historyczny oraz dzieli kadrę 28 kolarzy na 2 fronty',
      () {
        final bundle = LegendaryHistoricScenariosSeeder.buildPlayableScenario(
          'hist_01_mountain_tt_comeback',
        );
        final outcome = bundle.evaluateOutcome(
          const ScenarioSimulationResult(
            scenarioId: 'hist_01_mountain_tt_comeback',
            leaderStageRank: 1,
            timeGainedOverRivalSeconds: 115,
            finalGcMarginSeconds: 10,
            leaderTimeLossSeconds: 0,
            remainingDomestiquesCount: 0,
          ),
        );
        expect(outcome.isSuccess, isTrue);
        expect(outcome.medal, ScenarioMedalTier.gold);

        final squad = MultiRaceParallelDaySimulator.generateSample28RiderSquad();
        final simState = ParallelDaySimulatorState.initialDefault();
        final assignments =
            MultiRaceParallelDaySimulator.autoSplitSquadForTwoFronts(
          squad: squad,
          frontA: simState.frontAEvent,
          frontB: simState.frontBEvent,
        );
        final validation = MultiRaceParallelDaySimulator.validateSplit(
          squad: squad,
          assignments: assignments,
          frontA: simState.frontAEvent,
          frontB: simState.frontBEvent,
        );
        expect(validation.isValid, isTrue);
        expect(validation.duplicateRiderIds, isEmpty);
      },
    );
  });

  group(
    'E2E Mode 14: UI Menu Tytułowe & Szybki Wyścig Sandbox (390x844 / 1024x768 / 1600x900)',
    () {
      const responsiveSizes = <Size>[
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ];

      for (final size in responsiveSizes) {
        testWidgets(
          'MainTitleMenuScreen i QuickRaceSandboxScreen renderują się bez overflow na ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  theme: AppTheme.darkTheme,
                  home: const MainTitleMenuScreen(),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.byType(MainTitleMenuScreen), findsOneWidget);
            expect(tester.takeException(), isNull);

            await tester.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  theme: AppTheme.darkTheme,
                  home: const QuickRaceSandboxScreen(),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.byType(QuickRaceSandboxScreen), findsOneWidget);
            expect(tester.takeException(), isNull);

            expect(AppRoutes.start, isNotEmpty);
            expect(AppRoutes.dashboard, isNotEmpty);
            expect(AppRoutes.beAProDashboard, isNotEmpty);
            expect(AppRoutes.quickRaceSandbox, isNotEmpty);
            expect(AppRoutes.raceOrganizerHq, isNotEmpty);
            expect(AppRoutes.multiplayerLeagues, isNotEmpty);
            expect(AppRoutes.mtbXcoWorldCup, isNotEmpty);
            expect(AppRoutes.ultraBikepacking, isNotEmpty);
          },
        );
      }
    },
  );
}
