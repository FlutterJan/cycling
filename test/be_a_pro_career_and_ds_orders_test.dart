import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/pro_cyclist_career_state.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/team/cycling_team.dart';
import 'package:pro_peloton_manager/services/career/ds_team_orders_mission_generator.dart';
import 'package:pro_peloton_manager/ui/screens/be_a_pro_character_creator_screen.dart';

void main() {
  RaceStage buildCobbleStage() {
    return const RaceStage(
      id: 'stage_cobble_test',
      stageNumber: 1,
      name: 'Piekło Północy — Sektor Arenberg',
      stageType: StageType.cobbleClassic,
      baseTemperatureCelsius: 14.0,
      weatherCondition: WeatherCondition.overcast,
      windSpeedKmh: 22.0,
      segments: [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 60.0,
          startElevationM: 45.0,
          endElevationM: 50.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 20.0,
          windDirectionDegrees: 270.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 1,
          startKm: 60.0,
          lengthKm: 3.7,
          startElevationM: 50.0,
          endElevationM: 55.0,
          surfaceType: SegmentSurfaceType.cobblestonesSector5,
          technicalDifficulty: 95.0,
          windDirectionDegrees: 270.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 2,
          startKm: 63.7,
          lengthKm: 40.0,
          startElevationM: 55.0,
          endElevationM: 48.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 25.0,
          windDirectionDegrees: 270.0,
          roadBearingDegrees: 0.0,
          sprintOrKomClassification: SegmentClassification.finishLine,
        ),
      ],
    );
  }

  RaceStage buildMountainStage() {
    return const RaceStage(
      id: 'stage_mountain_test',
      stageNumber: 2,
      name: 'Królewski Etap Alpejski',
      stageType: StageType.highMountain,
      baseTemperatureCelsius: 18.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 10.0,
      segments: [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 45.0,
          startElevationM: 400.0,
          endElevationM: 600.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 20.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.intermediateSprint,
        ),
        StageSegment(
          index: 1,
          startKm: 45.0,
          lengthKm: 14.0,
          startElevationM: 600.0,
          endElevationM: 1850.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 55.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.horsCategorie,
        ),
        StageSegment(
          index: 2,
          startKm: 59.0,
          lengthKm: 25.0,
          startElevationM: 1850.0,
          endElevationM: 1200.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 60.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.finishLine,
        ),
      ],
    );
  }

  RaceStage buildTimeTrialStage() {
    return const RaceStage(
      id: 'stage_itt_test',
      stageNumber: 3,
      name: 'Jazda Indywidualna na Czas',
      stageType: StageType.individualTimeTrial,
      baseTemperatureCelsius: 20.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 12.0,
      segments: [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 28.0,
          startElevationM: 100.0,
          endElevationM: 120.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 30.0,
          windDirectionDegrees: 90.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.finishLine,
        ),
      ],
    );
  }

  DsMissionEvaluationInput buildSuccessTelemetry(DsTeamOrderMission mission) {
    switch (mission.assignmentType) {
      case ProCyclistAssignmentType.protectLeader:
        return DsMissionEvaluationInput(
          leaderMaxPositionInTargetZone: mission.targetPositionTopN ?? 10,
          protectedLeaderCleanly: true,
          stageCompleted: true,
        );
      case ProCyclistAssignmentType.pacePeloton:
        return DsMissionEvaluationInput(
          averagePowerWattsInZone: (mission.targetPowerWatts ?? 360) + 15.0,
          distanceLedKm: mission.targetValue + 1.0,
          stageCompleted: true,
        );
      case ProCyclistAssignmentType.huntKomPoints:
        return DsMissionEvaluationInput(
          joinedDayBreakaway: true,
          komPointsEarned: mission.targetValue.ceil() + 2,
          stageCompleted: true,
        );
      case ProCyclistAssignmentType.joinBreakaway:
        return DsMissionEvaluationInput(
          joinedDayBreakaway: true,
          distanceLedKm: mission.targetValue + 5.0,
          stageCompleted: true,
        );
      case ProCyclistAssignmentType.fetchBottles:
        return DsMissionEvaluationInput(
          bottlesDeliveredCount: mission.targetValue.ceil() + 1,
          stageCompleted: true,
        );
      case ProCyclistAssignmentType.leadoutSprint:
        return const DsMissionEvaluationInput(
          sprintLeadoutExecuted: true,
          stageCompleted: true,
        );
      case ProCyclistAssignmentType.freeRole:
      case ProCyclistAssignmentType.winStage:
      case ProCyclistAssignmentType.defendJersey:
        return DsMissionEvaluationInput(
          playerFinishPosition: mission.targetPositionTopN ?? 1,
          stageCompleted: true,
        );
      case ProCyclistAssignmentType.timeTrialEffort:
        return const DsMissionEvaluationInput(
          timeTrialPacingAccuracyRatio: 0.96,
          stageCompleted: true,
        );
    }
  }

  group('Be a Pro — Tworzenie kolarza i fizyka startowa', () {
    test('kalkulacja fizyki CdA i W/kg rozróżnia górala i sprintera', () {
      final climberMetrics = BeAProPhysicsCalculator.evaluate(
        heightCm: 171.0,
        weightKg: 57.0,
        archetype: BeAProGeneticArchetype.alpineClimber,
      );
      final sprinterMetrics = BeAProPhysicsCalculator.evaluate(
        heightCm: 185.0,
        weightKg: 79.0,
        archetype: BeAProGeneticArchetype.sprinter,
      );

      expect(
        climberMetrics.baseCdaHoodsM2,
        lessThan(sprinterMetrics.baseCdaHoodsM2),
      );
      expect(
        climberMetrics.wattsPerKg,
        greaterThan(sprinterMetrics.wattsPerKg),
      );
      expect(
        sprinterMetrics.sprint5sWatts,
        greaterThan(climberMetrics.sprint5sWatts),
      );
      expect(
        climberMetrics.mountainPredisposition,
        greaterThan(sprinterMetrics.mountainPredisposition),
      );
    });

    test('BeAProCharacterDraft buduje kompletnego kolarza i stan kariery U23', () {
      const draft = BeAProCharacterDraft(
        firstName: 'Jan',
        lastName: 'Nowak',
        nationalityIso: 'POL',
        heightCm: 174.0,
        weightKg: 60.5,
        archetype: BeAProGeneticArchetype.alpineClimber,
      );

      expect(draft.isValidIdentity, isTrue);
      expect(draft.resolvedBodyBuild, BodyBuildType.climberLean);

      final startDate = DateTime(2026, 2, 1);
      final result = draft.buildCareerResult(startDate: startDate);
      final rider = result.playerRider;
      final career = result.careerState;

      expect(rider.fullName, 'Jan Nowak');
      expect(rider.nationalityIso, 'POL');
      expect(
        rider.specialization,
        BeAProGeneticArchetype.alpineClimber.riderSpecialization,
      );
      expect(rider.contract.role, RiderRole.neoPro);
      expect(rider.potential, 92);
      expect(rider.physiology.weightKg, 60.5);
      expect(rider.powerProfile.watts60m, rider.physiology.ftpWatts);

      expect(career.currentDivision, TeamDivision.continental);
      expect(career.careerTier, ProCyclistCareerTier.u23Continental);
      expect(career.careerLevel, 1);
      expect(career.experienceXp, 0);
      expect(career.skillPoints, 6);
      expect(career.dsTrustScore, result.selectedTeam.initialDsTrust);
      expect(career.achievementJournal, isNotEmpty);
      expect(
        career.achievementJournal.first.category,
        ProCyclistJournalCategory.debut,
      );

      // Weryfikacja bezstratnej serializacji JSON całego stanu kariery.
      final restored = ProCyclistCareerState.fromJson(career.toJson());
      expect(restored.careerId, career.careerId);
      expect(restored.playerRider.fullName, 'Jan Nowak');
      expect(restored.dsTrustScore, career.dsTrustScore);
      expect(restored.careerTier, ProCyclistCareerTier.u23Continental);
    });
  });

  group('Be a Pro — Naliczanie XP, awanse poziomów i punkty umiejętności', () {
    test('grantExperienceXp obsługuje wielokrotny awans poziomów i punkty SP', () {
      const draft = BeAProCharacterDraft();
      final initial = draft.buildCareerResult().careerState;

      expect(initial.careerLevel, 1);
      expect(initial.xpRequiredForNextLevel, 500);
      expect(initial.skillPoints, 6);

      // Dodanie 300 XP nie powoduje awansu poziomu (300 < 500).
      final after300 = initial.grantExperienceXp(300);
      expect(after300.careerLevel, 1);
      expect(after300.experienceXp, 300);
      expect(after300.levelProgressRatio, closeTo(0.6, 1e-6));
      expect(after300.skillPoints, 6);

      // Dodanie 1300 XP (łącznie 1600 XP):
      // Poziom 1 -> 2 kosztuje 500 XP (+2 SP), zostaje 1100 XP.
      // Poziom 2 -> 3 kosztuje 1000 XP (+2 SP), zostaje 100 XP.
      final after1600 = after300.grantExperienceXp(1300);
      expect(after1600.careerLevel, 3);
      expect(after1600.experienceXp, 100);
      expect(after1600.xpRequiredForNextLevel, 1500);
      expect(after1600.skillPoints, 10);
      expect(after1600.totalSkillPointsEarned, 10);

      // Wartość <= 0 nie zmienia stanu.
      expect(identical(after1600.grantExperienceXp(0), after1600), isTrue);
      expect(identical(after1600.grantExperienceXp(-50), after1600), isTrue);

      // Wydanie punktów SP.
      final afterSpend = after1600.spendSkillPoints(4);
      expect(afterSpend.skillPoints, 6);
      expect(afterSpend.totalSkillPointsSpent, 4);

      // Próba wydania więcej SP niż dostępne jest ignorowana.
      expect(identical(afterSpend.spendSkillPoints(99), afterSpend), isTrue);
    });
  });

  group('Rozkazy Dyrektora Sportowego — generowanie i ocena wykonania', () {
    const generator = DsTeamOrdersMissionGenerator();

    test('ocena pozytywna i negatywna misji poprawnie modyfikuje zaufanie, XP i budżet', () {
      final baseCareer = const BeAProCharacterDraft()
          .buildCareerResult(startDate: DateTime(2026, 3, 1))
          .careerState
          .copyWith(dsTrustScore: 30.0);

      final cobbleStage = buildCobbleStage();
      final mission = generator.generateStageMission(
        careerState: baseCareer,
        stage: cobbleStage,
        raceId: 'roubaix_u23',
        raceName: 'Paris-Roubaix Espoirs',
        seed: 42,
      );

      expect(mission.status, ProCyclistAssignmentStatus.assigned);
      expect(mission.rewardXp, greaterThan(0));
      expect(mission.rewardTrustDelta, greaterThan(0));
      expect(mission.penaltyTrustDelta, lessThan(0));

      // Częściowy postęp przed metą.
      final partialTelemetry = DsMissionEvaluationInput(
        leaderMaxPositionInTargetZone: mission.targetPositionTopN ?? 15,
        protectedLeaderCleanly: false,
        stageCompleted: false,
      );
      final inProgress = generator.updateMissionProgress(
        mission: mission,
        telemetry: partialTelemetry,
      );
      expect(inProgress.currentProgress, greaterThanOrEqualTo(0.0));
      expect(inProgress.currentProgress, lessThanOrEqualTo(mission.targetValue));

      // Rozliczenie sukcesu na mecie.
      final successResult = generator.resolveMission(
        mission: mission,
        careerState: baseCareer,
        telemetry: buildSuccessTelemetry(mission),
        resolutionDate: DateTime(2026, 3, 1),
      );

      expect(
        successResult.updatedMission.status,
        ProCyclistAssignmentStatus.completed,
      );
      expect(
        successResult.updatedCareerState.dsTrustScore,
        closeTo(baseCareer.dsTrustScore + mission.rewardTrustDelta, 1e-6),
      );
      expect(
        successResult.updatedCareerState.completedAssignmentsCount,
        baseCareer.completedAssignmentsCount + 1,
      );
      expect(
        successResult.updatedCareerState.privateBalanceEur,
        baseCareer.privateBalanceEur + mission.rewardBonusEur,
      );
      expect(
        successResult.updatedCareerState.experienceXp +
            (successResult.updatedCareerState.careerLevel - 1) * 500,
        greaterThanOrEqualTo(mission.rewardXp),
      );

      // Rozliczenie porażki (DNF lub brak realizacji celu).
      final failureResult = generator.resolveMission(
        mission: mission,
        careerState: baseCareer,
        telemetry: const DsMissionEvaluationInput(
          leaderMaxPositionInTargetZone: 85,
          protectedLeaderCleanly: false,
          stageCompleted: false,
        ),
        resolutionDate: DateTime(2026, 3, 1),
      );

      expect(
        failureResult.updatedMission.status,
        ProCyclistAssignmentStatus.failed,
      );
      expect(
        failureResult.updatedCareerState.dsTrustScore,
        closeTo(baseCareer.dsTrustScore + mission.penaltyTrustDelta, 1e-6),
      );
      expect(
        failureResult.updatedCareerState.failedAssignmentsCount,
        baseCareer.failedAssignmentsCount + 1,
      );
      expect(failureResult.updatedCareerState.experienceXp, 0);
      expect(
        failureResult.updatedCareerState.privateBalanceEur,
        baseCareer.privateBalanceEur,
      );
    });
  });

  group('Test integracyjny — pełna ścieżka awansu w hierarchii zespołu Be a Pro', () {
    const generator = DsTeamOrdersMissionGenerator();

    test('kolarz przechodzi od Młodego Pomocnika przez Wolnego Elektrona do Lidera Drużyny', () {
      const draft = BeAProCharacterDraft(
        firstName: 'Michał',
        lastName: 'Zieliński',
        nationalityIso: 'POL',
        heightCm: 175.0,
        weightKg: 62.0,
        archetype: BeAProGeneticArchetype.explosivePuncheur,
      );

      var career = draft
          .buildCareerResult(startDate: DateTime(2026, 4, 1))
          .careerState
          .copyWith(dsTrustScore: 28.0);

      expect(
        generator.determineRoleStatus(career),
        BeAProRoleStatus.youngDomestique,
      );
      expect(career.canRequestBreakawayOrFreeRole, isFalse);
      expect(career.hasProtectedLeaderStatus, isFalse);

      final stages = [
        buildCobbleStage(),
        buildMountainStage(),
        buildTimeTrialStage(),
      ];

      bool sawFreeElectronUnlock = false;
      bool sawTeamLeaderUnlock = false;
      int stageCursor = 0;

      // Symulujemy kolejne etapy z wzorowym wykonaniem rozkazów DS aż do pełnego awansu.
      while (!sawTeamLeaderUnlock && stageCursor < 25) {
        final stage = stages[stageCursor % stages.length];
        final mission = generator.generateStageMission(
          careerState: career,
          stage: stage,
          raceId: 'race_$stageCursor',
          raceName: 'Wyścig Etapowy #${stageCursor + 1}',
          seed: 100 + stageCursor,
        );

        final telemetry = buildSuccessTelemetry(mission);
        final progressed = generator.updateMissionProgress(
          mission: mission,
          telemetry: telemetry,
        );
        expect(progressed.currentProgress, greaterThan(0.0));

        final resolution = generator.resolveMission(
          mission: progressed,
          careerState: career,
          telemetry: telemetry,
          resolutionDate: DateTime(2026, 4, 1).add(Duration(days: stageCursor)),
        );

        expect(
          resolution.updatedMission.status,
          ProCyclistAssignmentStatus.completed,
        );
        career = resolution.updatedCareerState;

        if (resolution.unlockedFreeElectron) {
          sawFreeElectronUnlock = true;
          expect(
            resolution.newRoleStatus,
            BeAProRoleStatus.freeElectron,
          );
          expect(career.canRequestBreakawayOrFreeRole, isTrue);
          expect(
            career.careerTier.index,
            greaterThanOrEqualTo(ProCyclistCareerTier.worldTourCoLeader.index),
          );
        }

        if (resolution.unlockedTeamLeader) {
          sawTeamLeaderUnlock = true;
          expect(
            resolution.newRoleStatus,
            BeAProRoleStatus.teamLeader,
          );
          expect(career.hasProtectedLeaderStatus, isTrue);
          expect(
            career.careerTier,
            ProCyclistCareerTier.worldTourLeader,
          );
        }

        stageCursor++;
      }

      expect(sawFreeElectronUnlock, isTrue);
      expect(sawTeamLeaderUnlock, isTrue);
      expect(career.dsTrustScore, greaterThanOrEqualTo(78.0));
      expect(career.careerLevel, greaterThan(1));
      expect(career.completedAssignmentsCount, stageCursor);
      expect(career.assignmentSuccessRate, 1.0);

      // Jako Lider Drużyny generujemy nowy rozkaz DS i sprawdzamy, że dotyczy roli lidera.
      final leaderMission = generator.generateStageMission(
        careerState: career,
        stage: buildMountainStage(),
        raceId: 'tour_final',
        raceName: 'Wielki Tour',
        seed: 999,
      );
      expect(
        leaderMission.assignmentType,
        anyOf(
          ProCyclistAssignmentType.winStage,
          ProCyclistAssignmentType.defendJersey,
          ProCyclistAssignmentType.freeRole,
        ),
      );

      // Dziennik kariery zawiera wpisy kamieni milowych dla obu awansów.
      final milestoneTitles = career.achievementJournal
          .where((e) => e.isKeyMilestone)
          .map((e) => e.title)
          .toList();
      expect(
        milestoneTitles,
        contains('Odblokowano status: Wolny Elektron!'),
      );
      expect(
        milestoneTitles,
        contains('Odblokowano status: Lider Drużyny!'),
      );
    });
  });
}
