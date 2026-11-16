import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/ds_team_orders_mission_generator.dart';

Rider _buildTestProRider({int ftpWatts = 396}) {
  return Rider(
    id: 'pro_player_1',
    firstName: 'Kacper',
    lastName: 'Majewski',
    nationalityIso: 'POL',
    birthDate: DateTime(2006, 5, 14),
    potential: 91,
    specialization: RiderSpecialization.domestiqueEngine,
    physiology: RiderPhysiology(
      heightCm: 181,
      weightKg: 70.0,
      bodyFatPercentage: 7.2,
      ftpWatts: ftpWatts,
      wPrimeJoules: 23500,
      vo2Max: 82.0,
      maxHr: 196,
      restingHr: 42,
      lactateThresholdHr: 176,
      recoveryRate: 84.0,
      glycogenCapacityGrams: 510.0,
    ),
    powerProfile: PowerProfileHelper.fromFtp(ftpWatts),
    skills: const RiderSkills(
      cobbles: 76,
      descending: 78,
      bikeHandling: 80,
      aeroPositioning: 75,
      draftingEfficiency: 82,
      raceIq: 79,
      rainResistance: 74,
      heatTolerance: 75,
      timeTrialPositioning: 72,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 0,
      skinToneHex: '#F2C9AC',
      hairStyleIndex: 1,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'glasses_pro',
      glassesLensColorHex: '#D4AF37',
      helmetModelId: 'helmet_aero',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.5,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_wt_1',
      role: RiderRole.domestique,
      monthlySalaryEur: 4500,
      signingBonusEur: 0,
      winBonusEur: 1000,
      releaseClauseEur: 120000,
      contractEndYear: 2028,
      morale: 82.0,
      leaderLoyalty: 85.0,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 40.0,
      chronicTrainingLoad: 75.0,
    ),
    careerPointsUci: 45,
  );
}

class PowerProfileHelper {
  static RiderPowerProfile fromFtp(int ftp) {
    return RiderPowerProfile(
      watts5s: (ftp * 3.1).round(),
      watts15s: (ftp * 2.5).round(),
      watts30s: (ftp * 2.0).round(),
      watts1m: (ftp * 1.7).round(),
      watts3m: (ftp * 1.25).round(),
      watts5m: (ftp * 1.15).round(),
      watts20m: ftp,
      watts60m: (ftp * 0.94).round(),
    );
  }
}

ProCyclistCareerState _buildTestCareerState({double dsTrustScore = 35.0}) {
  return ProCyclistCareerState.createNew(
    careerId: 'be_a_pro_test_1',
    careerName: 'Kariera Kacpra',
    playerRider: _buildTestProRider(),
    startDate: DateTime(2026, 4, 12),
    initialDsTrustScore: dsTrustScore,
  );
}

RaceStage _buildCobbleStage() {
  return const RaceStage(
    id: 'stage_roubaix',
    stageNumber: 1,
    name: 'Paris-Roubaix — Trouée d\'Arenberg',
    stageType: StageType.cobbleClassic,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0,
        lengthKm: 120,
        startElevationM: 50,
        endElevationM: 70,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 20,
        windDirectionDegrees: 90,
        roadBearingDegrees: 180,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 120,
        lengthKm: 2.4,
        startElevationM: 70,
        endElevationM: 72,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        technicalDifficulty: 95,
        windDirectionDegrees: 90,
        roadBearingDegrees: 180,
        sprintOrKomClassification: SegmentClassification.none,
      ),
    ],
    baseTemperatureCelsius: 14.0,
    weatherCondition: WeatherCondition.overcast,
    windSpeedKmh: 22.0,
  );
}

RaceStage _buildMountainStage() {
  return const RaceStage(
    id: 'stage_alpe',
    stageNumber: 14,
    name: 'Alpe d\'Huez Summit',
    stageType: StageType.summitFinish,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0,
        lengthKm: 110,
        startElevationM: 250,
        endElevationM: 720,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 30,
        windDirectionDegrees: 180,
        roadBearingDegrees: 180,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 110,
        lengthKm: 13.8,
        startElevationM: 720,
        endElevationM: 1850,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 60,
        windDirectionDegrees: 180,
        roadBearingDegrees: 180,
        sprintOrKomClassification: SegmentClassification.horsCategorie,
      ),
    ],
    baseTemperatureCelsius: 21.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 12.0,
  );
}

RaceStage _buildHillyKomStage() {
  return const RaceStage(
    id: 'stage_ardennes',
    stageNumber: 3,
    name: 'Etap Pagórkowaty w Ardenach',
    stageType: StageType.hilly,
    segments: [
      StageSegment(
        index: 0,
        startKm: 0,
        lengthKm: 70,
        startElevationM: 150,
        endElevationM: 220,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 40,
        windDirectionDegrees: 45,
        roadBearingDegrees: 90,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 70,
        lengthKm: 4.5,
        startElevationM: 220,
        endElevationM: 540,
        surfaceType: SegmentSurfaceType.roughAsphalt,
        technicalDifficulty: 55,
        windDirectionDegrees: 45,
        roadBearingDegrees: 90,
        sprintOrKomClassification: SegmentClassification.cat2,
      ),
    ],
    baseTemperatureCelsius: 17.0,
    weatherCondition: WeatherCondition.sunny,
    windSpeedKmh: 16.0,
  );
}

void main() {
  const generator = DsTeamOrdersMissionGenerator();

  group('DsTeamOrdersMissionGenerator - Generowanie misji DS', () {
    test('generuje misję ochrony lidera w Top 15 na bruku Arenberg dla młodego pomocnika', () {
      final state = _buildTestCareerState(dsTrustScore: 35.0);
      final mission = generator.generateStageMission(
        careerState: state,
        stage: _buildCobbleStage(),
        raceId: 'roubaix_2026',
        raceName: 'Paris-Roubaix',
        leaderName: 'Lider',
        seed: 1,
      );

      expect(mission.assignmentType, ProCyclistAssignmentType.protectLeader);
      expect(mission.triggerPhase, DsMissionTriggerPhase.cobbleSector);
      expect(mission.radioCallout, contains('Top 15'));
      expect(mission.radioCallout, contains('Arenberg'));
      expect(mission.rewardTrustDelta, greaterThanOrEqualTo(10.0));
      expect(mission.rewardXp, greaterThanOrEqualTo(250));
    });

    test('generuje misję wyprowadzenia pociągu na podjeździe z mocą ~380 W', () {
      final state = _buildTestCareerState(dsTrustScore: 42.0);
      final mission = generator.generateStageMission(
        careerState: state,
        stage: _buildMountainStage(),
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        seed: 2,
      );

      expect(mission.assignmentType, ProCyclistAssignmentType.pacePeloton);
      expect(mission.triggerPhase, DsMissionTriggerPhase.climbBase);
      expect(mission.targetPowerWatts, 380);
      expect(mission.radioCallout, contains('2 km podjazdu'));
      expect(mission.radioCallout, contains('380 W'));
    });

    test('generuje misję ucieczki dnia i zdobycia 5 pkt KOM na etapie pagórkowatym', () {
      final state = _buildTestCareerState(dsTrustScore: 30.0);
      final mission = generator.generateStageMission(
        careerState: state,
        stage: _buildHillyKomStage(),
        raceId: 'lbl_2026',
        raceName: 'Liège-Bastogne-Liège',
        seed: 3,
      );

      expect(mission.assignmentType, ProCyclistAssignmentType.huntKomPoints);
      expect(mission.targetValue, 5.0);
      expect(mission.radioCallout, contains('ucieczkę dnia'));
      expect(mission.radioCallout, contains('5 pkt'));
    });

    test('serializacja JSON DsTeamOrderMission zachowuje wszystkie pola', () {
      final state = _buildTestCareerState(dsTrustScore: 35.0);
      final mission = generator.generateStageMission(
        careerState: state,
        stage: _buildCobbleStage(),
        raceId: 'roubaix_2026',
        raceName: 'Paris-Roubaix',
        seed: 7,
      );

      final decoded = DsTeamOrderMission.fromJson(mission.toJson());
      expect(decoded.missionId, mission.missionId);
      expect(decoded.assignmentType, mission.assignmentType);
      expect(decoded.radioCallout, mission.radioCallout);
      expect(decoded.rewardTrustDelta, mission.rewardTrustDelta);
      expect(decoded.rewardXp, mission.rewardXp);
    });
  });

  group('DsTeamOrdersMissionGenerator - Rozliczanie i odblokowanie ról', () {
    test('wypełnienie misji daje bonus dsTrustScore i XP oraz odblokowuje Wolnego Elektrona i Lidera Drużyny', () {
      var state = _buildTestCareerState(dsTrustScore: 52.0);
      expect(
        generator.determineRoleStatus(state),
        BeAProRoleStatus.trustedDomestique,
      );

      final cobbleMission = generator.generateStageMission(
        careerState: state,
        stage: _buildCobbleStage(),
        raceId: 'roubaix_2026',
        raceName: 'Paris-Roubaix',
        seed: 10,
      );

      final firstResult = generator.resolveMission(
        mission: cobbleMission,
        careerState: state,
        telemetry: const DsMissionEvaluationInput(
          leaderMaxPositionInTargetZone: 9,
          protectedLeaderCleanly: true,
          stageCompleted: true,
        ),
      );

      expect(firstResult.updatedMission.status,
          ProCyclistAssignmentStatus.completed);
      expect(firstResult.unlockedFreeElectron, isTrue);
      expect(firstResult.newRoleStatus, BeAProRoleStatus.freeElectron);
      expect(firstResult.updatedCareerState.dsTrustScore, greaterThanOrEqualTo(60.0));
      expect(firstResult.updatedCareerState.experienceXp, greaterThan(0));
      expect(
        firstResult.updatedCareerState.careerTier,
        ProCyclistCareerTier.worldTourCoLeader,
      );

      // Podniesienie zaufania do 72 i kolejna misja odblokowująca Lidera Drużyny (>= 78)
      state = firstResult.updatedCareerState.copyWith(dsTrustScore: 72.0);
      final electronMission = generator.generateStageMission(
        careerState: state,
        stage: _buildMountainStage(),
        raceId: 'tdf_2026',
        raceName: 'Tour de France',
        seed: 11,
      );

      final secondResult = generator.resolveMission(
        mission: electronMission,
        careerState: state,
        telemetry: const DsMissionEvaluationInput(
          joinedDayBreakaway: true,
          komPointsEarned: 10,
          stageCompleted: true,
        ),
      );

      expect(secondResult.unlockedTeamLeader, isTrue);
      expect(secondResult.newRoleStatus, BeAProRoleStatus.teamLeader);
      expect(
        secondResult.updatedCareerState.careerTier,
        ProCyclistCareerTier.worldTourLeader,
      );
    });

    test('niewykonanie misji obniża dsTrustScore i zwiększa failedAssignmentsCount', () {
      final state = _buildTestCareerState(dsTrustScore: 45.0);
      final mission = generator.generateStageMission(
        careerState: state,
        stage: _buildCobbleStage(),
        raceId: 'roubaix_2026',
        raceName: 'Paris-Roubaix',
        seed: 15,
      );

      final result = generator.resolveMission(
        mission: mission,
        careerState: state,
        telemetry: const DsMissionEvaluationInput(
          leaderMaxPositionInTargetZone: 48,
          protectedLeaderCleanly: false,
          stageCompleted: true,
        ),
      );

      expect(result.updatedMission.status, ProCyclistAssignmentStatus.failed);
      expect(result.updatedCareerState.dsTrustScore, lessThan(45.0));
      expect(result.updatedCareerState.failedAssignmentsCount, 1);
    });
  });

  group('DsTeamOrdersRadioMissionPanel - Responsywność i interakcja UI', () {
    for (final viewport in [
      const Size(390, 844),
      const Size(1024, 768),
      const Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje się bez błędów przepełnienia w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: DsTeamOrdersRadioMissionPanel(
                    initialCareerState: _buildTestCareerState(dsTrustScore: 52.0),
                    stage: _buildCobbleStage(),
                    raceId: 'roubaix_2026',
                    raceName: 'Paris-Roubaix',
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('RADIO DYREKTORA SPORTOWEGO'), findsOneWidget);
          expect(find.textContaining('Arenberg'), findsWidgets);

          final ackFinder = find.text('Copy DS (Potwierdź)');
          await tester.ensureVisible(ackFinder);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(ackFinder);
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Rozkaz przyjęty'), findsOneWidget);

          final resolveFinder = find.text('Rozlicz sukces misji');
          await tester.ensureVisible(resolveFinder);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(resolveFinder);
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.textContaining('Wolnego Elektrona'), findsOneWidget);
        },
      );
    }
  });
}
