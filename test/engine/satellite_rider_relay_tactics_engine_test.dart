import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/rider_race_state.dart';
import 'package:pro_peloton_manager/engine/peloton/satellite_rider_relay_tactics_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';

RaceStage _buildAlpineStage() {
  return const RaceStage(
    id: 'stage_alps_17',
    stageNumber: 17,
    name: 'Col du Galibier - Alpe d\'Huez',
    stageType: StageType.summitFinish,
    baseTemperatureCelsius: 18.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 14.0,
    segments: <StageSegment>[
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 50.0,
        startElevationM: 400.0,
        endElevationM: 550.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // Przedostatnia przełęcz: km 50 -> km 70 (1500m przewyższenia)
      StageSegment(
        index: 1,
        startKm: 50.0,
        lengthKm: 20.0,
        startElevationM: 550.0,
        endElevationM: 2050.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 55.0,
        windDirectionDegrees: 180.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
      // Zjazd + dolina: km 70 -> km 100
      StageSegment(
        index: 2,
        startKm: 70.0,
        lengthKm: 30.0,
        startElevationM: 2050.0,
        endElevationM: 750.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 45.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 180.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      // Finałowy podjazd: km 100 -> km 114
      StageSegment(
        index: 3,
        startKm: 100.0,
        lengthKm: 14.0,
        startElevationM: 750.0,
        endElevationM: 1860.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 60.0,
        windDirectionDegrees: 90.0,
        roadBearingDegrees: 90.0,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
  );
}

Rider _makeRider({
  required String id,
  required String firstName,
  required String lastName,
  required RiderSpecialization spec,
  required int ftpWatts,
  required double weightKg,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'PL',
    birthDate: DateTime(1998, 5, 10),
    potential: 86,
    specialization: spec,
    physiology: RiderPhysiology(
      heightCm: 180.0,
      weightKg: weightKg,
      bodyFatPercentage: 7.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 22000,
      vo2Max: 80.0,
      maxHr: 192,
      restingHr: 42,
      lactateThresholdHr: 174,
      recoveryRate: 85.0,
      glycogenCapacityGrams: 550.0,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: 1050,
      watts15s: 880,
      watts30s: 740,
      watts1m: 620,
      watts3m: 510,
      watts5m: 480,
      watts20m: (ftpWatts * 1.05).round(),
      watts60m: ftpWatts,
    ),
    skills: const RiderSkills(
      cobbles: 65,
      descending: 82,
      bikeHandling: 80,
      aeroPositioning: 84,
      draftingEfficiency: 85,
      raceIq: 88,
      rainResistance: 75,
      heatTolerance: 78,
      timeTrialPositioning: 80,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F0C8A0',
      hairStyleIndex: 2,
      hairColorHex: '#332211',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'aero_road',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.45,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_1',
      role: RiderRole.superDomestique,
      monthlySalaryEur: 35000,
      signingBonusEur: 10000,
      winBonusEur: 15000,
      releaseClauseEur: 500000,
      contractEndYear: 2027,
      morale: 0.90,
      leaderLoyalty: 0.95,
      requiredRacesIds: <String>[],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 45.0,
      chronicTrainingLoad: 65.0,
    ),
    careerPointsUci: 1200,
  );
}

void main() {
  group('SatelliteRiderRelayTacticsEngine', () {
    test('analyzeStageTerrain detects penultimate pass, valley, and final climb',
        () {
      final RaceStage alpineStage = _buildAlpineStage();
      final PenultimatePassCheckpoint cp =
          SatelliteRiderRelayTacticsEngine.analyzeStageTerrain(alpineStage);

      expect(cp.hasValidSatelliteTerrain, isTrue);
      expect(cp.penultimatePassStartKm, 50.0);
      expect(cp.penultimatePassSummitKm, 70.0);
      expect(cp.valleyStartKm, 70.0);
      expect(cp.valleyEndKm, 100.0);
      expect(cp.finalClimbStartKm, 100.0);
      expect(cp.finalClimbSummitKm, 114.0);
      expect(cp.valleyLengthKm, 30.0);
    });

    test('evaluateCandidates excludes GC leader and ranks domestique above sprinter',
        () {
      final List<Rider> roster = <Rider>[
        _makeRider(
          id: 'leader',
          firstName: 'Jan',
          lastName: 'Kowalski',
          spec: RiderSpecialization.gcClimber,
          ftpWatts: 410,
          weightKg: 62.0,
        ),
        _makeRider(
          id: 'sat_1',
          firstName: 'Michał',
          lastName: 'Kwiatkowski',
          spec: RiderSpecialization.domestiqueEngine,
          ftpWatts: 415,
          weightKg: 68.0,
        ),
        _makeRider(
          id: 'sprinter_1',
          firstName: 'Olav',
          lastName: 'Sprint',
          spec: RiderSpecialization.pureSprinter,
          ftpWatts: 390,
          weightKg: 78.0,
        ),
      ];

      final List<SatelliteDomestiqueCandidate> candidates =
          SatelliteRiderRelayTacticsEngine.evaluateCandidates(
        teamRoster: roster,
        gcLeaderId: 'leader',
      );

      expect(candidates.length, 2);
      expect(candidates.first.riderId, 'sat_1');
      expect(
        candidates.first.suitabilityScore,
        greaterThan(candidates.last.suitabilityScore),
      );
    });

    test(
        'full mission lifecycle: breakaway -> Wait for GC Leader -> valley pull -> final climb leadout -> completed',
        () {
      final RaceStage stage = _buildAlpineStage();
      SatelliteRelayMissionState mission =
          SatelliteRiderRelayTacticsEngine.createMission(
        satelliteRiderId: 'sat_1',
        satelliteRiderName: 'Michał Kwiatkowski',
        gcLeaderId: 'leader',
        gcLeaderName: 'Jan Kowalski',
        stage: stage,
      );

      expect(mission.phase, SatelliteRelayPhase.inMorningBreakaway);

      // 1. Wydanie rozkazu Wait for GC Leader na przedostatniej przełęczy (km 69.5)
      mission = SatelliteRiderRelayTacticsEngine.issueOrder(
        currentState: mission,
        order: SatelliteRelayOrder.waitForGcLeader,
        currentStageKm: 69.5,
      );
      expect(mission.phase, SatelliteRelayPhase.waitingOnPenultimatePass);

      RiderRaceState satState = RiderRaceState.initial(
        riderId: 'sat_1',
        teamId: 'team_1',
        initialWPrimeJoules: 16000.0,
        initialGlycogenGrams: 350.0,
      ).copyWith(
        distanceCoveredMeters: 70200.0,
        currentSpeedMs: 8.5,
      );

      RiderRaceState leaderState = RiderRaceState.initial(
        riderId: 'leader',
        teamId: 'team_1',
        initialWPrimeJoules: 20000.0,
        initialGlycogenGrams: 380.0,
      ).copyWith(
        distanceCoveredMeters: 69700.0, // 500 m za pomocnikiem
        currentSpeedMs: 11.0,
      );

      // Krok oczekiwania na przełęczy (odbudowa W' i niska moc)
      final SatelliteRelayStepResult waitResult =
          SatelliteRiderRelayTacticsEngine.step(
        missionState: mission,
        input: SatelliteRelayStepInput(
          dtSeconds: 10.0,
          gradientPercent: -2.0,
          satelliteState: satState,
          gcLeaderState: leaderState,
          satelliteFtpWatts: 410,
          satelliteMassKg: 68.0,
          satelliteMaxWPrimeJoules: 22000.0,
          gcLeaderFtpWatts: 415,
          gcLeaderMassKg: 62.0,
        ),
      );
      mission = waitResult.updatedMissionState;
      satState = waitResult.updatedSatelliteState;
      expect(mission.phase, SatelliteRelayPhase.waitingOnPenultimatePass);
      expect(waitResult.satelliteTargetWatts, lessThan(260));
      expect(satState.currentWPrime, greaterThan(16000.0));

      // 2. Lider dołącza do pomocnika w dolinie (luka 15 m <= 25 m)
      satState = satState.copyWith(
        distanceCoveredMeters: 78015.0,
        currentSpeedMs: 13.5,
      );
      leaderState = leaderState.copyWith(
        distanceCoveredMeters: 78000.0,
        currentSpeedMs: 13.5,
      );

      final SatelliteRelayStepResult rendezvousResult =
          SatelliteRiderRelayTacticsEngine.step(
        missionState: mission,
        input: SatelliteRelayStepInput(
          dtSeconds: 1.0,
          gradientPercent: 0.5,
          headwindMs: 3.0,
          satelliteState: satState,
          gcLeaderState: leaderState,
          satelliteFtpWatts: 410,
          satelliteMassKg: 68.0,
          satelliteMaxWPrimeJoules: 22000.0,
          satelliteAeroPositioning: 88,
          gcLeaderFtpWatts: 415,
          gcLeaderMassKg: 62.0,
        ),
      );
      mission = rendezvousResult.updatedMissionState;
      expect(mission.phase, SatelliteRelayPhase.rendezvousAndValleyPull);
      expect(rendezvousResult.radioMessage, isNotNull);

      // Kolejne 60s ciągnięcia w dolinie -> duża oszczędność watów lidera
      final SatelliteRelayStepResult valleyPullResult =
          SatelliteRiderRelayTacticsEngine.step(
        missionState: mission,
        input: SatelliteRelayStepInput(
          dtSeconds: 60.0,
          gradientPercent: 0.5,
          headwindMs: 3.0,
          satelliteState: satState,
          gcLeaderState: leaderState,
          satelliteFtpWatts: 410,
          satelliteMassKg: 68.0,
          satelliteMaxWPrimeJoules: 22000.0,
          satelliteAeroPositioning: 88,
          gcLeaderFtpWatts: 415,
          gcLeaderMassKg: 62.0,
        ),
      );
      mission = valleyPullResult.updatedMissionState;
      expect(valleyPullResult.gcLeaderDraftingReduction, greaterThan(0.30));
      expect(valleyPullResult.gcLeaderWattsSaved, greaterThan(30.0));
      expect(mission.leaderEnergySavedJoules, greaterThan(1800.0));

      // 3. Wjazd na finałowy podjazd (km 100.2 >= 100.0)
      satState = satState.copyWith(
        distanceCoveredMeters: 100200.0,
        currentSpeedMs: 6.5,
      );
      leaderState = leaderState.copyWith(
        distanceCoveredMeters: 100195.0,
        currentSpeedMs: 6.5,
      );

      final SatelliteRelayStepResult climbEnterResult =
          SatelliteRiderRelayTacticsEngine.step(
        missionState: mission,
        input: SatelliteRelayStepInput(
          dtSeconds: 1.0,
          gradientPercent: 8.5,
          satelliteState: satState,
          gcLeaderState: leaderState,
          satelliteFtpWatts: 410,
          satelliteMassKg: 68.0,
          satelliteMaxWPrimeJoules: 22000.0,
          gcLeaderFtpWatts: 415,
          gcLeaderMassKg: 62.0,
          isGcLeaderAttacking: true,
        ),
      );
      mission = climbEnterResult.updatedMissionState;
      expect(mission.phase, SatelliteRelayPhase.finalClimbLeadout);

      // 4. Rozprowadzanie aż do wyczerpania W' -> completed
      satState = satState.copyWith(currentWPrime: 500.0);
      final SatelliteRelayStepResult finishResult =
          SatelliteRiderRelayTacticsEngine.step(
        missionState: mission,
        input: SatelliteRelayStepInput(
          dtSeconds: 10.0,
          gradientPercent: 9.0,
          satelliteState: satState,
          gcLeaderState: leaderState,
          satelliteFtpWatts: 410,
          satelliteMassKg: 68.0,
          satelliteMaxWPrimeJoules: 22000.0,
          gcLeaderFtpWatts: 415,
          gcLeaderMassKg: 62.0,
          isGcLeaderAttacking: true,
        ),
      );
      mission = finishResult.updatedMissionState;
      expect(mission.phase, SatelliteRelayPhase.completed);

      final SatelliteRelaySimulationSummary summary =
          SatelliteRiderRelayTacticsEngine.buildSummary(mission);
      expect(summary.finalPhase, SatelliteRelayPhase.completed);
      expect(summary.tacticalEfficiencyScore, greaterThan(35.0));
      expect(summary.leaderEnergySavedKj, greaterThan(1.5));
    });
  });

  group('SatelliteRelayTacticsPanel UI responsiveness', () {
    for (final Size viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() async => tester.binding.setSurfaceSize(null));

        final RaceStage stage = _buildAlpineStage();
        SatelliteRelayMissionState mission =
            SatelliteRiderRelayTacticsEngine.createMission(
          satelliteRiderId: 'sat_1',
          satelliteRiderName: 'Michał Kwiatkowski',
          gcLeaderId: 'leader',
          gcLeaderName: 'Jan Kowalski',
          stage: stage,
        );

        bool waitClicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SatelliteRelayTacticsPanel(
                    missionState: mission,
                    currentStageKm: 68.5,
                    onWaitForGcLeader: () {
                      waitClicked = true;
                    },
                    onAbortRelay: () {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('Wait for GC Leader'), findsOneWidget);

        await tester.tap(find.text('Wait for GC Leader'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(waitClicked, isTrue);
      });
    }
  });
}
