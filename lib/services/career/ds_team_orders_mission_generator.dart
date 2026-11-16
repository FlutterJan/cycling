import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/pro_cyclist_career_state.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';

/// Rola taktyczna kolarza w hierarchii zespołu w trybie Be a Pro,
/// odblokowywana wraz ze wzrostem `dsTrustScore` i doświadczenia.
enum BeAProRoleStatus {
  youngDomestique,
  trustedDomestique,
  freeElectron,
  teamLeader;

  String toJson() => name;

  String get label {
    switch (this) {
      case BeAProRoleStatus.youngDomestique:
        return 'Młody Pomocnik';
      case BeAProRoleStatus.trustedDomestique:
        return 'Zaufany Pomocnik';
      case BeAProRoleStatus.freeElectron:
        return 'Wolny Elektron';
      case BeAProRoleStatus.teamLeader:
        return 'Lider Drużyny';
    }
  }

  String get subtitle {
    switch (this) {
      case BeAProRoleStatus.youngDomestique:
        return 'Realizujesz rozkazy DS, wozisz bidony i chronisz lidera.';
      case BeAProRoleStatus.trustedDomestique:
        return 'Prowadzisz pociągi na podjazdach i bruku dla lidera.';
      case BeAProRoleStatus.freeElectron:
        return 'Odblokowano: prawo do ucieczek dnia i walki o etapy.';
      case BeAProRoleStatus.teamLeader:
        return 'Odblokowano: pełna ochrona ekipy i walka o wygraną / GC.';
    }
  }

  double get unlockTrustThreshold {
    switch (this) {
      case BeAProRoleStatus.youngDomestique:
        return 0.0;
      case BeAProRoleStatus.trustedDomestique:
        return 40.0;
      case BeAProRoleStatus.freeElectron:
        return 60.0;
      case BeAProRoleStatus.teamLeader:
        return 78.0;
    }
  }

  static BeAProRoleStatus fromTrustScore(double dsTrustScore) {
    final clamped = dsTrustScore.clamp(0.0, 100.0);
    if (clamped >= 78.0) return BeAProRoleStatus.teamLeader;
    if (clamped >= 60.0) return BeAProRoleStatus.freeElectron;
    if (clamped >= 40.0) return BeAProRoleStatus.trustedDomestique;
    return BeAProRoleStatus.youngDomestique;
  }

  static BeAProRoleStatus fromJson(String value) {
    return BeAProRoleStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BeAProRoleStatus.youngDomestique,
    );
  }
}

/// Faza etapu, w której Dyrektor Sportowy nadaje konkretny rozkaz przez radio.
enum DsMissionTriggerPhase {
  preStart,
  earlyStage,
  cobbleSector,
  climbBase,
  sprintApproach,
  crosswindZone,
  finalKilometers;

  String toJson() => name;

  String get label {
    switch (this) {
      case DsMissionTriggerPhase.preStart:
        return 'Odprawa startowa (KM 0)';
      case DsMissionTriggerPhase.earlyStage:
        return 'Początek etapu';
      case DsMissionTriggerPhase.cobbleSector:
        return 'Sektor bruku';
      case DsMissionTriggerPhase.climbBase:
        return 'Podnóże podjazdu';
      case DsMissionTriggerPhase.sprintApproach:
        return 'Strefa finałowego sprintu';
      case DsMissionTriggerPhase.crosswindZone:
        return 'Strefa bocznego wiatru';
      case DsMissionTriggerPhase.finalKilometers:
        return 'Finałowe kilometry';
    }
  }

  static DsMissionTriggerPhase fromJson(String value) {
    return DsMissionTriggerPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DsMissionTriggerPhase.preStart,
    );
  }
}

/// Dynamiczna misja nadana kolarzowi przez Dyrektora Sportowego przez radio wyścigowe.
class DsTeamOrderMission {
  final String missionId;
  final String raceId;
  final String raceName;
  final int stageNumber;
  final String directorName;
  final ProCyclistAssignmentType assignmentType;
  final DsMissionTriggerPhase triggerPhase;
  final String title;
  final String radioCallout;
  final String description;
  final String targetMetricLabel;
  final double targetValue;
  final double currentProgress;
  final int? targetPowerWatts;
  final double? targetKmStart;
  final double? targetKmEnd;
  final int? targetPositionTopN;
  final double rewardTrustDelta;
  final double penaltyTrustDelta;
  final int rewardXp;
  final int rewardSkillPoints;
  final int rewardBonusEur;
  final ProCyclistAssignmentStatus status;
  final DateTime assignedDate;
  final DateTime? completedDate;

  const DsTeamOrderMission({
    required this.missionId,
    required this.raceId,
    required this.raceName,
    this.stageNumber = 1,
    required this.directorName,
    required this.assignmentType,
    required this.triggerPhase,
    required this.title,
    required this.radioCallout,
    required this.description,
    required this.targetMetricLabel,
    required this.targetValue,
    this.currentProgress = 0.0,
    this.targetPowerWatts,
    this.targetKmStart,
    this.targetKmEnd,
    this.targetPositionTopN,
    required this.rewardTrustDelta,
    this.penaltyTrustDelta = -6.0,
    required this.rewardXp,
    this.rewardSkillPoints = 1,
    this.rewardBonusEur = 0,
    this.status = ProCyclistAssignmentStatus.assigned,
    required this.assignedDate,
    this.completedDate,
  });

  double get completionRatio {
    if (targetValue <= 0.0) {
      return status == ProCyclistAssignmentStatus.completed ? 1.0 : 0.0;
    }
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  bool get isFinished =>
      status == ProCyclistAssignmentStatus.completed ||
      status == ProCyclistAssignmentStatus.failed ||
      status == ProCyclistAssignmentStatus.expired;

  /// Konwertuje misję na `ProCyclistRaceAssignment` zapisywalne w `ProCyclistCareerState`.
  ProCyclistRaceAssignment toProCyclistRaceAssignment() {
    return ProCyclistRaceAssignment(
      assignmentId: missionId,
      raceId: raceId,
      raceName: raceName,
      stageNumber: stageNumber,
      type: assignmentType,
      title: title,
      description: radioCallout,
      targetMetricLabel: targetMetricLabel,
      targetValue: targetValue,
      currentProgress: currentProgress,
      rewardTrustDelta: rewardTrustDelta,
      penaltyTrustDelta: penaltyTrustDelta,
      rewardSkillPoints: rewardSkillPoints,
      rewardXp: rewardXp,
      rewardBonusEur: rewardBonusEur,
      status: status,
      assignedDate: assignedDate,
      completedDate: completedDate,
    );
  }

  DsTeamOrderMission copyWith({
    String? missionId,
    String? raceId,
    String? raceName,
    int? stageNumber,
    String? directorName,
    ProCyclistAssignmentType? assignmentType,
    DsMissionTriggerPhase? triggerPhase,
    String? title,
    String? radioCallout,
    String? description,
    String? targetMetricLabel,
    double? targetValue,
    double? currentProgress,
    int? targetPowerWatts,
    double? targetKmStart,
    double? targetKmEnd,
    int? targetPositionTopN,
    double? rewardTrustDelta,
    double? penaltyTrustDelta,
    int? rewardXp,
    int? rewardSkillPoints,
    int? rewardBonusEur,
    ProCyclistAssignmentStatus? status,
    DateTime? assignedDate,
    DateTime? completedDate,
  }) {
    return DsTeamOrderMission(
      missionId: missionId ?? this.missionId,
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      stageNumber: stageNumber ?? this.stageNumber,
      directorName: directorName ?? this.directorName,
      assignmentType: assignmentType ?? this.assignmentType,
      triggerPhase: triggerPhase ?? this.triggerPhase,
      title: title ?? this.title,
      radioCallout: radioCallout ?? this.radioCallout,
      description: description ?? this.description,
      targetMetricLabel: targetMetricLabel ?? this.targetMetricLabel,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      targetPowerWatts: targetPowerWatts ?? this.targetPowerWatts,
      targetKmStart: targetKmStart ?? this.targetKmStart,
      targetKmEnd: targetKmEnd ?? this.targetKmEnd,
      targetPositionTopN: targetPositionTopN ?? this.targetPositionTopN,
      rewardTrustDelta: rewardTrustDelta ?? this.rewardTrustDelta,
      penaltyTrustDelta: penaltyTrustDelta ?? this.penaltyTrustDelta,
      rewardXp: rewardXp ?? this.rewardXp,
      rewardSkillPoints: rewardSkillPoints ?? this.rewardSkillPoints,
      rewardBonusEur: rewardBonusEur ?? this.rewardBonusEur,
      status: status ?? this.status,
      assignedDate: assignedDate ?? this.assignedDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'missionId': missionId,
      'raceId': raceId,
      'raceName': raceName,
      'stageNumber': stageNumber,
      'directorName': directorName,
      'assignmentType': assignmentType.toJson(),
      'triggerPhase': triggerPhase.toJson(),
      'title': title,
      'radioCallout': radioCallout,
      'description': description,
      'targetMetricLabel': targetMetricLabel,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'targetPowerWatts': targetPowerWatts,
      'targetKmStart': targetKmStart,
      'targetKmEnd': targetKmEnd,
      'targetPositionTopN': targetPositionTopN,
      'rewardTrustDelta': rewardTrustDelta,
      'penaltyTrustDelta': penaltyTrustDelta,
      'rewardXp': rewardXp,
      'rewardSkillPoints': rewardSkillPoints,
      'rewardBonusEur': rewardBonusEur,
      'status': status.toJson(),
      'assignedDate': assignedDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory DsTeamOrderMission.fromJson(Map<String, dynamic> json) {
    return DsTeamOrderMission(
      missionId: json['missionId'] as String? ?? '',
      raceId: json['raceId'] as String? ?? '',
      raceName: json['raceName'] as String? ?? '',
      stageNumber: json['stageNumber'] as int? ?? 1,
      directorName: json['directorName'] as String? ?? 'Dyrektor Sportowy',
      assignmentType: ProCyclistAssignmentType.fromJson(
        json['assignmentType'] as String? ?? 'protectLeader',
      ),
      triggerPhase: DsMissionTriggerPhase.fromJson(
        json['triggerPhase'] as String? ?? 'preStart',
      ),
      title: json['title'] as String? ?? '',
      radioCallout: json['radioCallout'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetMetricLabel: json['targetMetricLabel'] as String? ?? '',
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
      currentProgress: (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
      targetPowerWatts: json['targetPowerWatts'] as int?,
      targetKmStart: (json['targetKmStart'] as num?)?.toDouble(),
      targetKmEnd: (json['targetKmEnd'] as num?)?.toDouble(),
      targetPositionTopN: json['targetPositionTopN'] as int?,
      rewardTrustDelta: (json['rewardTrustDelta'] as num?)?.toDouble() ?? 8.0,
      penaltyTrustDelta: (json['penaltyTrustDelta'] as num?)?.toDouble() ?? -6.0,
      rewardXp: json['rewardXp'] as int? ?? 150,
      rewardSkillPoints: json['rewardSkillPoints'] as int? ?? 1,
      rewardBonusEur: json['rewardBonusEur'] as int? ?? 0,
      status: ProCyclistAssignmentStatus.fromJson(
        json['status'] as String? ?? 'assigned',
      ),
      assignedDate: DateTime.tryParse(json['assignedDate'] as String? ?? '') ??
          DateTime(2026, 1, 1),
      completedDate: json['completedDate'] != null
          ? DateTime.tryParse(json['completedDate'] as String)
          : null,
    );
  }
}

/// Telemetria z przebiegu etapu służąca do oceny wykonania rozkazu DS.
class DsMissionEvaluationInput {
  final int leaderMaxPositionInTargetZone;
  final bool protectedLeaderCleanly;
  final double averagePowerWattsInZone;
  final double distanceLedKm;
  final bool joinedDayBreakaway;
  final int komPointsEarned;
  final int bottlesDeliveredCount;
  final bool sprintLeadoutExecuted;
  final int playerFinishPosition;
  final double timeTrialPacingAccuracyRatio;
  final bool stageCompleted;

  const DsMissionEvaluationInput({
    this.leaderMaxPositionInTargetZone = 99,
    this.protectedLeaderCleanly = false,
    this.averagePowerWattsInZone = 0.0,
    this.distanceLedKm = 0.0,
    this.joinedDayBreakaway = false,
    this.komPointsEarned = 0,
    this.bottlesDeliveredCount = 0,
    this.sprintLeadoutExecuted = false,
    this.playerFinishPosition = 99,
    this.timeTrialPacingAccuracyRatio = 0.0,
    this.stageCompleted = true,
  });
}

/// Wynik rozliczenia misji DS oraz aktualizacja stanu kariery Be a Pro.
class DsMissionResolutionResult {
  final DsTeamOrderMission updatedMission;
  final ProCyclistCareerState updatedCareerState;
  final BeAProRoleStatus previousRoleStatus;
  final BeAProRoleStatus newRoleStatus;
  final bool unlockedFreeElectron;
  final bool unlockedTeamLeader;
  final String radioFeedbackMessage;

  const DsMissionResolutionResult({
    required this.updatedMission,
    required this.updatedCareerState,
    required this.previousRoleStatus,
    required this.newRoleStatus,
    required this.unlockedFreeElectron,
    required this.unlockedTeamLeader,
    required this.radioFeedbackMessage,
  });
}

/// Generator dynamicznych misji od Dyrektora Sportowego na każdy etap trybu Be a Pro.
class DsTeamOrdersMissionGenerator {
  const DsTeamOrdersMissionGenerator();

  /// Wyznacza bieżącą rolę w hierarchii zespołu na podstawie `dsTrustScore`.
  BeAProRoleStatus determineRoleStatus(ProCyclistCareerState state) {
    return BeAProRoleStatus.fromTrustScore(state.dsTrustScore);
  }

  /// Generuje główną dynamiczną misję DS dopasowaną do trasy etapu,
  /// specjalizacji gracza oraz jego aktualnego statusu zaufania (`dsTrustScore`).
  DsTeamOrderMission generateStageMission({
    required ProCyclistCareerState careerState,
    required RaceStage stage,
    required String raceId,
    required String raceName,
    String directorName = 'DS Marek Rutkiewicz',
    String leaderName = 'Lider drużyny',
    int? seed,
  }) {
    final roleStatus = determineRoleStatus(careerState);
    final rng = math.Random(
      seed ??
          Object.hash(
            careerState.careerId,
            raceId,
            stage.id,
            stage.stageNumber,
            careerState.currentDate.millisecondsSinceEpoch,
          ),
    );

    final missionId =
        'ds_mission_${raceId}_s${stage.stageNumber}_${stage.id}_${rng.nextInt(9999)}';

    // Czasówki (ITT / TTT) zawsze generują rozkaz wysiłkowy lub zespołowy.
    if (stage.isTimeTrial) {
      return _buildTimeTrialMission(
        missionId: missionId,
        careerState: careerState,
        stage: stage,
        raceId: raceId,
        raceName: raceName,
        directorName: directorName,
        roleStatus: roleStatus,
      );
    }

    // Jeśli gracz ma już status Lidera Drużyny (dsTrustScore >= 78).
    if (roleStatus == BeAProRoleStatus.teamLeader) {
      return _buildLeaderMission(
        missionId: missionId,
        careerState: careerState,
        stage: stage,
        raceId: raceId,
        raceName: raceName,
        directorName: directorName,
        rng: rng,
      );
    }

    // Jeśli gracz odblokował status Wolnego Elektrona (60 <= dsTrustScore < 78).
    if (roleStatus == BeAProRoleStatus.freeElectron) {
      return _buildFreeElectronMission(
        missionId: missionId,
        careerState: careerState,
        stage: stage,
        raceId: raceId,
        raceName: raceName,
        directorName: directorName,
        rng: rng,
      );
    }

    // Młody / Zaufany Pomocnik (dsTrustScore < 60): twarde, konkretne zadania dla ekipy!
    return _buildDomestiqueMission(
      missionId: missionId,
      careerState: careerState,
      stage: stage,
      raceId: raceId,
      raceName: raceName,
      directorName: directorName,
      leaderName: leaderName,
      roleStatus: roleStatus,
      rng: rng,
    );
  }

  /// Generuje pakiet do 3 zróżnicowanych misji taktycznych na dany etap
  /// (np. do wyboru na odprawie lub sekwencyjnego nadawania przez radio).
  List<DsTeamOrderMission> generateStageMissionPack({
    required ProCyclistCareerState careerState,
    required RaceStage stage,
    required String raceId,
    required String raceName,
    String directorName = 'DS Marek Rutkiewicz',
    String leaderName = 'Lider drużyny',
    int? seed,
  }) {
    final baseSeed = seed ??
        Object.hash(careerState.careerId, raceId, stage.id, stage.stageNumber);
    final primary = generateStageMission(
      careerState: careerState,
      stage: stage,
      raceId: raceId,
      raceName: raceName,
      directorName: directorName,
      leaderName: leaderName,
      seed: baseSeed,
    );

    final secondary = _buildBottleOrPositioningBackupMission(
      missionId: 'ds_mission_${raceId}_s${stage.stageNumber}_alt1',
      careerState: careerState,
      stage: stage,
      raceId: raceId,
      raceName: raceName,
      directorName: directorName,
      leaderName: leaderName,
    );

    if (secondary.assignmentType == primary.assignmentType) {
      return [primary];
    }
    return [primary, secondary];
  }

  /// Aktualizuje postęp bieżącej misji na podstawie telemetrii z wyścigu.
  DsTeamOrderMission updateMissionProgress({
    required DsTeamOrderMission mission,
    required DsMissionEvaluationInput telemetry,
  }) {
    if (mission.isFinished) return mission;

    final nextProgress = _computeProgressValue(mission, telemetry);
    final nextStatus = nextProgress >= mission.targetValue
        ? ProCyclistAssignmentStatus.inProgress
        : (nextProgress > 0.0
            ? ProCyclistAssignmentStatus.inProgress
            : mission.status);

    return mission.copyWith(
      currentProgress: nextProgress.clamp(0.0, mission.targetValue),
      status: nextStatus,
    );
  }

  /// Rozlicza misję na mecie (lub po zakończeniu strefy docelowej) i aktualizuje
  /// `dsTrustScore`, `experienceXp`, `skillPoints`, dziennik oraz odblokowanie roli.
  DsMissionResolutionResult resolveMission({
    required DsTeamOrderMission mission,
    required ProCyclistCareerState careerState,
    required DsMissionEvaluationInput telemetry,
    DateTime? resolutionDate,
  }) {
    final resolvedAt = resolutionDate ?? careerState.currentDate;
    final previousRole = determineRoleStatus(careerState);
    final measuredProgress = _computeProgressValue(mission, telemetry);
    final isSuccess = _evaluateSuccess(mission, telemetry, measuredProgress);

    final updatedMission = mission.copyWith(
      currentProgress: isSuccess
          ? mission.targetValue
          : measuredProgress.clamp(0.0, mission.targetValue),
      status: isSuccess
          ? ProCyclistAssignmentStatus.completed
          : ProCyclistAssignmentStatus.failed,
      completedDate: resolvedAt,
    );

    final trustDelta =
        isSuccess ? mission.rewardTrustDelta : mission.penaltyTrustDelta;
    var nextCareer = careerState.applyDsTrustDelta(trustDelta);

    if (isSuccess) {
      nextCareer = nextCareer.grantExperienceXp(mission.rewardXp);
      nextCareer = nextCareer.copyWith(
        skillPoints: nextCareer.skillPoints + mission.rewardSkillPoints,
        totalSkillPointsEarned:
            nextCareer.totalSkillPointsEarned + mission.rewardSkillPoints,
        privateBalanceEur: nextCareer.privateBalanceEur + mission.rewardBonusEur,
        careerEarningsEur: nextCareer.careerEarningsEur + mission.rewardBonusEur,
        completedAssignmentsCount: nextCareer.completedAssignmentsCount + 1,
        currentRaceAssignment: updatedMission.toProCyclistRaceAssignment(),
      );
    } else {
      nextCareer = nextCareer.copyWith(
        failedAssignmentsCount: nextCareer.failedAssignmentsCount + 1,
        currentRaceAssignment: updatedMission.toProCyclistRaceAssignment(),
      );
    }

    final newRole = determineRoleStatus(nextCareer);
    final unlockedFreeElectron =
        previousRole.index < BeAProRoleStatus.freeElectron.index &&
            newRole.index >= BeAProRoleStatus.freeElectron.index;
    final unlockedTeamLeader =
        previousRole.index < BeAProRoleStatus.teamLeader.index &&
            newRole.index >= BeAProRoleStatus.teamLeader.index;

    // Aktualizacja rangi kariery przy awansie zaufania
    if (unlockedTeamLeader &&
        nextCareer.careerTier.index <
            ProCyclistCareerTier.worldTourLeader.index) {
      nextCareer = nextCareer.copyWith(
        careerTier: ProCyclistCareerTier.worldTourLeader,
      );
    } else if (unlockedFreeElectron &&
        nextCareer.careerTier.index <
            ProCyclistCareerTier.worldTourCoLeader.index) {
      nextCareer = nextCareer.copyWith(
        careerTier: ProCyclistCareerTier.worldTourCoLeader,
      );
    }

    final journalEntry = ProCyclistJournalEntry(
      entryId: 'journal_${mission.missionId}_${resolvedAt.millisecondsSinceEpoch}',
      date: resolvedAt,
      seasonYear: nextCareer.seasonYear,
      category: ProCyclistJournalCategory.trustMilestone,
      title: isSuccess
          ? 'Rozkaz DS wykonany: ${mission.title}'
          : 'Niewykonany rozkaz DS: ${mission.title}',
      description: isSuccess
          ? '${mission.directorName}: Świetna robota na etapie ${mission.raceName}. Zaufanie +${trustDelta.toStringAsFixed(1)}, +${mission.rewardXp} XP.'
          : '${mission.directorName}: Zabrakło realizacji celu na etapie ${mission.raceName}. Zaufanie ${trustDelta.toStringAsFixed(1)}.',
      trustDelta: trustDelta,
      xpDelta: isSuccess ? mission.rewardXp : 0,
      eurDelta: isSuccess ? mission.rewardBonusEur : 0,
      isKeyMilestone: unlockedFreeElectron || unlockedTeamLeader,
    );
    nextCareer = nextCareer.appendJournalEntry(journalEntry);

    if (unlockedFreeElectron) {
      nextCareer = nextCareer.appendJournalEntry(
        ProCyclistJournalEntry(
          entryId:
              'unlock_free_electron_${resolvedAt.millisecondsSinceEpoch}',
          date: resolvedAt,
          seasonYear: nextCareer.seasonYear,
          category: ProCyclistJournalCategory.trustMilestone,
          title: 'Odblokowano status: Wolny Elektron!',
          description:
              'Dyrektor Sportowy daje Ci zielone światło na własne ataki, ucieczki dnia i polowanie na premie.',
          trustDelta: 0.0,
          xpDelta: 0,
          isKeyMilestone: true,
        ),
      );
    }

    if (unlockedTeamLeader) {
      nextCareer = nextCareer.appendJournalEntry(
        ProCyclistJournalEntry(
          entryId: 'unlock_team_leader_${resolvedAt.millisecondsSinceEpoch}',
          date: resolvedAt,
          seasonYear: nextCareer.seasonYear,
          category: ProCyclistJournalCategory.trustMilestone,
          title: 'Odblokowano status: Lider Drużyny!',
          description:
              'Zostajesz pełnoprawnym liderem zespołu. Cała ekipa pracuje teraz na Twój wynik i klasyfikację generalną.',
          trustDelta: 0.0,
          xpDelta: 0,
          isKeyMilestone: true,
        ),
      );
    }

    final feedback = _buildRadioFeedback(
      mission: mission,
      isSuccess: isSuccess,
      unlockedFreeElectron: unlockedFreeElectron,
      unlockedTeamLeader: unlockedTeamLeader,
      nextTrustScore: nextCareer.dsTrustScore,
    );

    return DsMissionResolutionResult(
      updatedMission: updatedMission,
      updatedCareerState: nextCareer,
      previousRoleStatus: previousRole,
      newRoleStatus: newRole,
      unlockedFreeElectron: unlockedFreeElectron,
      unlockedTeamLeader: unlockedTeamLeader,
      radioFeedbackMessage: feedback,
    );
  }

  DsTeamOrderMission _buildDomestiqueMission({
    required String missionId,
    required ProCyclistCareerState careerState,
    required RaceStage stage,
    required String raceId,
    required String raceName,
    required String directorName,
    required String leaderName,
    required BeAProRoleStatus roleStatus,
    required math.Random rng,
  }) {
    final cobbleSeg = _findPrimaryCobbleSegment(stage);
    final climbSeg = _findPrimaryClimbSegment(stage);
    final komSeg = _findPrimaryKomSegment(stage);
    final sprintSeg = _findIntermediateSprintSegment(stage);

    // 1. Etap brukowany lub obecność ciężkiego sektora bruku
    if (stage.stageType == StageType.cobbleClassic || cobbleSeg != null) {
      final seg = cobbleSeg ??
          (stage.segments.isNotEmpty ? stage.segments.first : null);
      final sectorLabel = _resolveCobbleSectorLabel(stage, seg);
      final kmStart = seg?.startKm ?? (stage.totalDistanceKm * 0.55);
      final kmEnd = seg?.endKm ?? (kmStart + 2.4);

      return DsTeamOrderMission(
        missionId: missionId,
        raceId: raceId,
        raceName: raceName,
        stageNumber: stage.stageNumber,
        directorName: directorName,
        assignmentType: ProCyclistAssignmentType.protectLeader,
        triggerPhase: DsMissionTriggerPhase.cobbleSector,
        title: 'Ochrona lidera na bruku ($sectorLabel)',
        radioCallout:
            'Utrzymaj $leaderName w Top 15 peletonu przez cały sektor bruku $sectorLabel',
        description:
            'Wprowadź lidera na czoło przed sektorem $sectorLabel (${kmStart.toStringAsFixed(1)}–${kmEnd.toStringAsFixed(1)} km) i osłaniaj go przed wiatrem oraz tłokiem.',
        targetMetricLabel: 'Ukończony sektor z liderem w Top 15',
        targetValue: 1.0,
        targetKmStart: kmStart,
        targetKmEnd: kmEnd,
        targetPositionTopN: 15,
        rewardTrustDelta:
            roleStatus == BeAProRoleStatus.youngDomestique ? 11.0 : 9.0,
        penaltyTrustDelta: -6.5,
        rewardXp: 260,
        rewardSkillPoints: 2,
        rewardBonusEur: 450,
        assignedDate: careerState.currentDate,
      );
    }

    // 2. Etap górski / finisz na szczycie — wyprowadzenie pociągu na podjeździe
    if (stage.stageType == StageType.highMountain ||
        stage.stageType == StageType.summitFinish ||
        (climbSeg != null && rng.nextBool())) {
      final seg = climbSeg ??
          (stage.segments.isNotEmpty ? stage.segments.last : null);
      final riderFtp = careerState.playerRider.physiology.ftpWatts;
      final targetWatts =
          (riderFtp * 0.96).round().clamp(340, 430); // ~380 W dla młodego pro
      final kmStart = seg?.startKm ?? (stage.totalDistanceKm * 0.7);
      const leadDistKm = 2.0;

      return DsTeamOrderMission(
        missionId: missionId,
        raceId: raceId,
        raceName: raceName,
        stageNumber: stage.stageNumber,
        directorName: directorName,
        assignmentType: ProCyclistAssignmentType.pacePeloton,
        triggerPhase: DsMissionTriggerPhase.climbBase,
        title: 'Pociąg na początku podjazdu ($targetWatts W)',
        radioCallout:
            'Wyprowadź pociąg na pierwszych 2 km podjazdu z mocą $targetWatts W',
        description:
            'Ustaw się na czele grupy u podnóża wspinaczki (${kmStart.toStringAsFixed(1)} km) i nadaj mocne, równe tempo $targetWatts W przez 2.0 km.',
        targetMetricLabel: 'Kilometry pracy na czele (>= $targetWatts W)',
        targetValue: leadDistKm,
        targetPowerWatts: targetWatts,
        targetKmStart: kmStart,
        targetKmEnd: kmStart + leadDistKm,
        rewardTrustDelta: 12.0,
        penaltyTrustDelta: -6.0,
        rewardXp: 280,
        rewardSkillPoints: 2,
        rewardBonusEur: 500,
        assignedDate: careerState.currentDate,
      );
    }

    // 3. Etap pagórkowaty / z premią górską — ucieczka dnia i punkty KOM
    if (stage.stageType == StageType.hilly || komSeg != null) {
      const targetKomPts = 5.0;
      return DsTeamOrderMission(
        missionId: missionId,
        raceId: raceId,
        raceName: raceName,
        stageNumber: stage.stageNumber,
        directorName: directorName,
        assignmentType: ProCyclistAssignmentType.huntKomPoints,
        triggerPhase: DsMissionTriggerPhase.earlyStage,
        title: 'Ucieczka dnia i punkty KOM',
        radioCallout:
            'Zabierz się w ucieczkę dnia i zdobądź 5 pkt na premii górskiej',
        description:
            'Kontruj pierwsze ataki po starcie ostrym, wejdź do odjazdu dnia i zafiniszuj na premii górskiej po minimum 5 punktów.',
        targetMetricLabel: 'Punkty górskie (KOM) zdobyte w ucieczce',
        targetValue: targetKomPts,
        targetKmStart: 0.0,
        targetKmEnd: komSeg?.endKm ?? stage.totalDistanceKm * 0.65,
        rewardTrustDelta: 11.5,
        penaltyTrustDelta: -5.0,
        rewardXp: 270,
        rewardSkillPoints: 2,
        rewardBonusEur: 400,
        assignedDate: careerState.currentDate,
      );
    }

    // 4. Etap płaski z wiatrem bocznym
    if (stage.weatherCondition == WeatherCondition.crosswindGale ||
        stage.windSpeedKmh >= 30.0) {
      return DsTeamOrderMission(
        missionId: missionId,
        raceId: raceId,
        raceName: raceName,
        stageNumber: stage.stageNumber,
        directorName: directorName,
        assignmentType: ProCyclistAssignmentType.protectLeader,
        triggerPhase: DsMissionTriggerPhase.crosswindZone,
        title: 'Ochrona lidera na rantach',
        radioCallout:
            'Utrzymaj $leaderName w pierwszym rancie (Top 15) w strefie bocznego wiatru (${stage.windSpeedKmh.round()} km/h)',
        description:
            'Silny wiatr boczny porwie peleton. Nie pozwól, by lider został w drugiej grupie — osłaniaj go od nawietrznej strony.',
        targetMetricLabel: 'Lider w pierwszym rancie (Top 15)',
        targetValue: 1.0,
        targetPositionTopN: 15,
        rewardTrustDelta: 10.5,
        penaltyTrustDelta: -6.5,
        rewardXp: 240,
        rewardSkillPoints: 1,
        rewardBonusEur: 350,
        assignedDate: careerState.currentDate,
      );
    }

    // 5. Etap płaski sprinterski — rozprowadzenie lub dowóz bidonów
    final isTrusted = roleStatus == BeAProRoleStatus.trustedDomestique ||
        careerState.playerRider.specialization ==
            RiderSpecialization.pureSprinter ||
        careerState.playerRider.specialization ==
            RiderSpecialization.versatileSprinter;

    if (isTrusted || sprintSeg != null) {
      final kmStart = math.max(0.0, stage.totalDistanceKm - 3.0);
      return DsTeamOrderMission(
        missionId: missionId,
        raceId: raceId,
        raceName: raceName,
        stageNumber: stage.stageNumber,
        directorName: directorName,
        assignmentType: ProCyclistAssignmentType.leadoutSprint,
        triggerPhase: DsMissionTriggerPhase.sprintApproach,
        title: 'Rozprowadzenie pociągu sprinterskiego',
        radioCallout:
            'Rozprowadź naszego sprintera w pociągu na ostatnich 3 km przed metą w $raceName',
        description:
            'Utrzymaj wysoką prędkość >58 km/h między 3.0 km a 0.5 km do mety i oddaj zmianę sprinterowi na dobrej pozycji.',
        targetMetricLabel: 'Wykonane rozprowadzenie pociągu',
        targetValue: 1.0,
        targetKmStart: kmStart,
        targetKmEnd: stage.totalDistanceKm,
        rewardTrustDelta: 10.0,
        penaltyTrustDelta: -5.5,
        rewardXp: 230,
        rewardSkillPoints: 1,
        rewardBonusEur: 350,
        assignedDate: careerState.currentDate,
      );
    }

    return _buildBottleOrPositioningBackupMission(
      missionId: missionId,
      careerState: careerState,
      stage: stage,
      raceId: raceId,
      raceName: raceName,
      directorName: directorName,
      leaderName: leaderName,
    );
  }

  DsTeamOrderMission _buildFreeElectronMission({
    required String missionId,
    required ProCyclistCareerState careerState,
    required RaceStage stage,
    required String raceId,
    required String raceName,
    required String directorName,
    required math.Random rng,
  }) {
    final komSeg = _findPrimaryKomSegment(stage);
    final cobbleSeg = _findPrimaryCobbleSegment(stage);

    if (komSeg != null ||
        stage.stageType == StageType.highMountain ||
        stage.stageType == StageType.summitFinish) {
      return DsTeamOrderMission(
        missionId: missionId,
        raceId: raceId,
        raceName: raceName,
        stageNumber: stage.stageNumber,
        directorName: directorName,
        assignmentType: ProCyclistAssignmentType.huntKomPoints,
        triggerPhase: DsMissionTriggerPhase.earlyStage,
        title: 'Wolny Elektron: Ucieczka i premia KOM',
        radioCallout:
            'Masz zielone światło! Zabierz się w ucieczkę dnia i zdobądź 8 pkt na premiach górskich',
        description:
            'Jako Wolny Elektron polujesz na klasyfikację górską i zwycięstwo z odjazdu dnia. Atakuj od pierwszych kilometrów.',
        targetMetricLabel: 'Punkty górskie (KOM)',
        targetValue: 8.0,
        rewardTrustDelta: 9.5,
        penaltyTrustDelta: -4.0,
        rewardXp: 340,
        rewardSkillPoints: 2,
        rewardBonusEur: 900,
        assignedDate: careerState.currentDate,
      );
    }

    if (cobbleSeg != null || stage.stageType == StageType.cobbleClassic) {
      return DsTeamOrderMission(
        missionId: missionId,
        raceId: raceId,
        raceName: raceName,
        stageNumber: stage.stageNumber,
        directorName: directorName,
        assignmentType: ProCyclistAssignmentType.freeRole,
        triggerPhase: DsMissionTriggerPhase.cobbleSector,
        title: 'Wolny Elektron: Wyprzedzający atak na bruku',
        radioCallout:
            'Wykorzystaj swoją swobodę — zaatakuj przed głównym sektorem bruku i zamelduj się w Top 10 etapu!',
        description:
            'Przeskocz do przedniej grupy przed decydującym brukiem i powalcz o miejsce w czołowej dziesiątce na mecie.',
        targetMetricLabel: 'Ukończenie etapu w Top 10',
        targetValue: 1.0,
        targetPositionTopN: 10,
        rewardTrustDelta: 10.0,
        penaltyTrustDelta: -4.0,
        rewardXp: 360,
        rewardSkillPoints: 2,
        rewardBonusEur: 1100,
        assignedDate: careerState.currentDate,
      );
    }

    return DsTeamOrderMission(
      missionId: missionId,
      raceId: raceId,
      raceName: raceName,
      stageNumber: stage.stageNumber,
      directorName: directorName,
      assignmentType: ProCyclistAssignmentType.joinBreakaway,
      triggerPhase: DsMissionTriggerPhase.earlyStage,
      title: 'Wolny Elektron: Odjazd dnia',
      radioCallout:
          'Masz wolną rękę — zabierz się w ucieczkę dnia i utrzymaj przewagę do ostatnich 15 km!',
      description:
          'Pokaż koszulkę sponsora w telewizji i powalcz o wygraną etapową z ucieczki.',
      targetMetricLabel: 'Kilometry w ucieczce dnia',
      targetValue: math.max(30.0, (stage.totalDistanceKm * 0.35).roundToDouble()),
      rewardTrustDelta: 9.0,
      penaltyTrustDelta: -4.0,
      rewardXp: 320,
      rewardSkillPoints: 2,
      rewardBonusEur: 800,
      assignedDate: careerState.currentDate,
    );
  }

  DsTeamOrderMission _buildLeaderMission({
    required String missionId,
    required ProCyclistCareerState careerState,
    required RaceStage stage,
    required String raceId,
    required String raceName,
    required String directorName,
    required math.Random rng,
  }) {
    final isSummitOrMountain = stage.stageType == StageType.summitFinish ||
        stage.stageType == StageType.highMountain;

    return DsTeamOrderMission(
      missionId: missionId,
      raceId: raceId,
      raceName: raceName,
      stageNumber: stage.stageNumber,
      directorName: directorName,
      assignmentType: isSummitOrMountain
          ? ProCyclistAssignmentType.winStage
          : ProCyclistAssignmentType.defendJersey,
      triggerPhase: DsMissionTriggerPhase.finalKilometers,
      title: isSummitOrMountain
          ? 'Lider Drużyny: Finałowy atak po zwycięstwo'
          : 'Lider Drużyny: Finisz w Top 3 etapu',
      radioCallout: isSummitOrMountain
          ? 'Chłopaki dowiozą Cię pod ostatni podjazd. Na 3 km do mety idziesz po wygraną etapową!'
          : 'Drużyna pracuje na Ciebie cały dzień. Dowozimy Cię na finisz — celujemy w podium (Top 3)!',
      description:
          'Jako Lider Drużyny oszczędzaj energię w kole kolegów aż do finałowej rozgrywki i wykończ pracę całego zespołu.',
      targetMetricLabel: 'Miejsce na mecie (Top 3)',
      targetValue: 1.0,
      targetPositionTopN: 3,
      rewardTrustDelta: 6.0,
      penaltyTrustDelta: -4.5,
      rewardXp: 420,
      rewardSkillPoints: 3,
      rewardBonusEur: 2000,
      assignedDate: careerState.currentDate,
    );
  }

  DsTeamOrderMission _buildTimeTrialMission({
    required String missionId,
    required ProCyclistCareerState careerState,
    required RaceStage stage,
    required String raceId,
    required String raceName,
    required String directorName,
    required BeAProRoleStatus roleStatus,
  }) {
    final targetWatts =
        (careerState.playerRider.physiology.ftpWatts * 1.02).round();
    final isLeaderOrElectron =
        roleStatus.index >= BeAProRoleStatus.freeElectron.index;

    return DsTeamOrderMission(
      missionId: missionId,
      raceId: raceId,
      raceName: raceName,
      stageNumber: stage.stageNumber,
      directorName: directorName,
      assignmentType: ProCyclistAssignmentType.timeTrialEffort,
      triggerPhase: DsMissionTriggerPhase.preStart,
      title: isLeaderOrElectron
          ? 'Czasówka: Walka o Top 10 ($targetWatts W)'
          : 'Czasówka: Równe tempo testowe ($targetWatts W)',
      radioCallout: isLeaderOrElectron
          ? 'Jedziesz na pełnym gazie w pozycji aero ($targetWatts W) — celujemy w Top 10 etapu!'
          : 'Trzymaj równe tempo $targetWatts W w czasówce i zbierz cenne dane telemetryczne dla zespołu.',
      description:
          'Utrzymaj optymalne rozłożenie sił (pacing) na całym dystansie jazdy na czas bez przepalenia w pierwszej połowie.',
      targetMetricLabel: 'Precyzja tempa czasówki (%)',
      targetValue: 90.0,
      targetPowerWatts: targetWatts,
      targetPositionTopN: isLeaderOrElectron ? 10 : null,
      rewardTrustDelta: 8.5,
      penaltyTrustDelta: -4.0,
      rewardXp: 250,
      rewardSkillPoints: 2,
      rewardBonusEur: isLeaderOrElectron ? 900 : 300,
      assignedDate: careerState.currentDate,
    );
  }

  DsTeamOrderMission _buildBottleOrPositioningBackupMission({
    required String missionId,
    required ProCyclistCareerState careerState,
    required RaceStage stage,
    required String raceId,
    required String raceName,
    required String directorName,
    required String leaderName,
  }) {
    final bottlesCount = stage.totalDistanceKm >= 170 ? 6 : 4;
    return DsTeamOrderMission(
      missionId: missionId,
      raceId: raceId,
      raceName: raceName,
      stageNumber: stage.stageNumber,
      directorName: directorName,
      assignmentType: ProCyclistAssignmentType.fetchBottles,
      triggerPhase: DsMissionTriggerPhase.earlyStage,
      title: 'Serwis bidonów z wozu DS',
      radioCallout:
          'Cofnij się do wozu technicznego i dowieź $bottlesCount bidonów dla $leaderName i reszty ekipy przed strefą bufetu.',
      description:
          'Odbierz bidony z samochodu Dyrektora Sportowego i bezpiecznie wróć do czoła peletonu, rozdając je kolegom.',
      targetMetricLabel: 'Dostarczone bidony do ekipy',
      targetValue: bottlesCount.toDouble(),
      rewardTrustDelta: 9.5,
      penaltyTrustDelta: -5.0,
      rewardXp: 210,
      rewardSkillPoints: 1,
      rewardBonusEur: 300,
      assignedDate: careerState.currentDate,
    );
  }

  double _computeProgressValue(
    DsTeamOrderMission mission,
    DsMissionEvaluationInput telemetry,
  ) {
    switch (mission.assignmentType) {
      case ProCyclistAssignmentType.protectLeader:
        final topN = mission.targetPositionTopN ?? 15;
        if (telemetry.protectedLeaderCleanly &&
            telemetry.leaderMaxPositionInTargetZone <= topN) {
          return mission.targetValue;
        }
        return telemetry.leaderMaxPositionInTargetZone <= topN ? 0.5 : 0.0;

      case ProCyclistAssignmentType.pacePeloton:
        final minWatts = (mission.targetPowerWatts ?? 360) * 0.92;
        if (telemetry.averagePowerWattsInZone >= minWatts) {
          return telemetry.distanceLedKm;
        }
        return telemetry.distanceLedKm * 0.4;

      case ProCyclistAssignmentType.huntKomPoints:
        if (!telemetry.joinedDayBreakaway && telemetry.komPointsEarned == 0) {
          return 0.0;
        }
        return telemetry.komPointsEarned.toDouble();

      case ProCyclistAssignmentType.joinBreakaway:
        return telemetry.joinedDayBreakaway ? telemetry.distanceLedKm : 0.0;

      case ProCyclistAssignmentType.fetchBottles:
        return telemetry.bottlesDeliveredCount.toDouble();

      case ProCyclistAssignmentType.leadoutSprint:
        return telemetry.sprintLeadoutExecuted ? 1.0 : 0.0;

      case ProCyclistAssignmentType.freeRole:
      case ProCyclistAssignmentType.winStage:
      case ProCyclistAssignmentType.defendJersey:
        final topN = mission.targetPositionTopN ?? 10;
        return telemetry.playerFinishPosition <= topN ? 1.0 : 0.0;

      case ProCyclistAssignmentType.timeTrialEffort:
        return (telemetry.timeTrialPacingAccuracyRatio * 100.0)
            .clamp(0.0, 100.0);
    }
  }

  bool _evaluateSuccess(
    DsTeamOrderMission mission,
    DsMissionEvaluationInput telemetry,
    double measuredProgress,
  ) {
    if (!telemetry.stageCompleted) return false;
    return measuredProgress >= mission.targetValue;
  }

  String _buildRadioFeedback({
    required DsTeamOrderMission mission,
    required bool isSuccess,
    required bool unlockedFreeElectron,
    required bool unlockedTeamLeader,
    required double nextTrustScore,
  }) {
    if (unlockedTeamLeader) {
      return '${mission.directorName}: „Fantastyczna robota! Od dziś jesteś Liderem Drużyny (Zaufanie ${nextTrustScore.toStringAsFixed(0)}/100) — cała ekipa jedzie na Ciebie!”';
    }
    if (unlockedFreeElectron) {
      return '${mission.directorName}: „Zaimponowałeś mi na trasie! Odblokowujesz status Wolnego Elektrona (Zaufanie ${nextTrustScore.toStringAsFixed(0)}/100) — możesz sam szukać ucieczek!”';
    }
    if (isSuccess) {
      return '${mission.directorName}: „Brawo, rozkaz wykonany wzorowo! (+${mission.rewardTrustDelta.toStringAsFixed(1)} zaufania, +${mission.rewardXp} XP)”';
    }
    return '${mission.directorName}: „Nie tak to planowaliśmy. Musisz dokładniej słuchać radia na kolejnych etapach.”';
  }

  StageSegment? _findPrimaryCobbleSegment(RaceStage stage) {
    StageSegment? hardest;
    for (final seg in stage.segments) {
      if (!seg.isCobblestone) continue;
      if (hardest == null ||
          seg.surfaceType.index > hardest.surfaceType.index) {
        hardest = seg;
      }
    }
    return hardest;
  }

  StageSegment? _findPrimaryClimbSegment(RaceStage stage) {
    StageSegment? steepest;
    for (final seg in stage.segments) {
      if (!seg.isClimb) continue;
      if (steepest == null || seg.gradientPercent > steepest.gradientPercent) {
        steepest = seg;
      }
    }
    return steepest;
  }

  StageSegment? _findPrimaryKomSegment(RaceStage stage) {
    for (final seg in stage.segments) {
      if (seg.isKom) return seg;
    }
    return null;
  }

  StageSegment? _findIntermediateSprintSegment(RaceStage stage) {
    for (final seg in stage.segments) {
      if (seg.isIntermediateSprint) return seg;
    }
    return null;
  }

  String _resolveCobbleSectorLabel(RaceStage stage, StageSegment? seg) {
    final lowerName = stage.name.toLowerCase();
    if (lowerName.contains('roubaix') || lowerName.contains('arenberg')) {
      return 'Arenberg';
    }
    if (seg != null &&
        seg.surfaceType == SegmentSurfaceType.cobblestonesSector5) {
      return 'Arenberg (5★)';
    }
    if (seg != null &&
        seg.surfaceType == SegmentSurfaceType.cobblestonesSector4) {
      return 'Carrefour de l\'Arbre (4★)';
    }
    return 'Sektor #${(seg?.index ?? 0) + 1}';
  }
}

/// Produkcyjny panel UI radia Dyrektora Sportowego i misji w trybie Be a Pro.
/// Obsługuje pełne stany `hover`/`active`/`disabled`/`focus`, paletę `AppColors`,
/// czcionkę `Inter` oraz responsywność `LayoutBuilder` (390x844, 1024x768, 1600x900).
class DsTeamOrdersRadioMissionPanel extends StatefulWidget {
  final ProCyclistCareerState initialCareerState;
  final RaceStage stage;
  final String raceId;
  final String raceName;
  final String directorName;
  final String leaderName;
  final ValueChanged<DsMissionResolutionResult>? onMissionResolved;

  const DsTeamOrdersRadioMissionPanel({
    super.key,
    required this.initialCareerState,
    required this.stage,
    required this.raceId,
    required this.raceName,
    this.directorName = 'DS Marek Rutkiewicz',
    this.leaderName = 'Lider zespołu',
    this.onMissionResolved,
  });

  @override
  State<DsTeamOrdersRadioMissionPanel> createState() =>
      _DsTeamOrdersRadioMissionPanelState();
}

class _DsTeamOrdersRadioMissionPanelState
    extends State<DsTeamOrdersRadioMissionPanel> {
  final DsTeamOrdersMissionGenerator _generator =
      const DsTeamOrdersMissionGenerator();

  late ProCyclistCareerState _careerState;
  late DsTeamOrderMission _activeMission;
  String? _lastRadioFeedback;
  bool _acknowledged = false;
  int _seedCounter = 1;

  @override
  void initState() {
    super.initState();
    _careerState = widget.initialCareerState;
    _activeMission = _generator.generateStageMission(
      careerState: _careerState,
      stage: widget.stage,
      raceId: widget.raceId,
      raceName: widget.raceName,
      directorName: widget.directorName,
      leaderName: widget.leaderName,
      seed: _seedCounter,
    );
  }

  void _acknowledgeOrder() {
    if (_acknowledged || _activeMission.isFinished) return;
    setState(() {
      _acknowledged = true;
      _activeMission = _activeMission.copyWith(
        status: ProCyclistAssignmentStatus.inProgress,
      );
      _lastRadioFeedback =
          'Potwierdzono rozkaz przez radio: „Copy DS, wykonuję zadanie!”';
    });
  }

  void _advanceSimulatedProgress() {
    if (_activeMission.isFinished) return;
    final step = math.max(0.25, _activeMission.targetValue * 0.35);
    final nextProgress =
        (_activeMission.currentProgress + step).clamp(0.0, _activeMission.targetValue);
    setState(() {
      _acknowledged = true;
      _activeMission = _activeMission.copyWith(
        currentProgress: nextProgress,
        status: ProCyclistAssignmentStatus.inProgress,
      );
    });
  }

  void _resolveMissionSuccess() {
    if (_activeMission.isFinished) return;
    final telemetry = DsMissionEvaluationInput(
      leaderMaxPositionInTargetZone: _activeMission.targetPositionTopN ?? 10,
      protectedLeaderCleanly: true,
      averagePowerWattsInZone:
          (_activeMission.targetPowerWatts ?? 380).toDouble(),
      distanceLedKm: _activeMission.targetValue,
      joinedDayBreakaway: true,
      komPointsEarned: _activeMission.targetValue.ceil(),
      bottlesDeliveredCount: _activeMission.targetValue.ceil(),
      sprintLeadoutExecuted: true,
      playerFinishPosition: _activeMission.targetPositionTopN ?? 3,
      timeTrialPacingAccuracyRatio: 0.95,
      stageCompleted: true,
    );

    final result = _generator.resolveMission(
      mission: _activeMission,
      careerState: _careerState,
      telemetry: telemetry,
    );

    setState(() {
      _activeMission = result.updatedMission;
      _careerState = result.updatedCareerState;
      _lastRadioFeedback = result.radioFeedbackMessage;
    });
    widget.onMissionResolved?.call(result);
  }

  void _generateNextMission() {
    setState(() {
      _seedCounter++;
      _acknowledged = false;
      _lastRadioFeedback = null;
      _activeMission = _generator.generateStageMission(
        careerState: _careerState,
        stage: widget.stage,
        raceId: widget.raceId,
        raceName: widget.raceName,
        directorName: widget.directorName,
        leaderName: widget.leaderName,
        seed: _seedCounter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleStatus = _generator.determineRoleStatus(_careerState);
    final trustScore = _careerState.dsTrustScore;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isWide = constraints.maxWidth >= 1000;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(roleStatus, trustScore, isCompact),
              const SizedBox(height: 14),
              _buildRoleProgressionBar(trustScore, roleStatus),
              const SizedBox(height: 14),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildRadioMissionCard(isCompact)),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: _buildRewardsAndStatsCard()),
                  ],
                )
              else ...[
                _buildRadioMissionCard(isCompact),
                const SizedBox(height: 12),
                _buildRewardsAndStatsCard(),
              ],
              if (_lastRadioFeedback != null) ...[
                const SizedBox(height: 12),
                _buildFeedbackBanner(_lastRadioFeedback!),
              ],
              const SizedBox(height: 14),
              _buildActionButtons(isCompact),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BeAProRoleStatus roleStatus,
    double trustScore,
    bool isCompact,
  ) {
    final roleColor = _roleColor(roleStatus);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.55),
                ),
              ),
              child: const Icon(
                Icons.headset_mic_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RADIO DYREKTORA SPORTOWEGO',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  Text(
                    '${widget.raceName} • Etap ${widget.stage.stageNumber}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: roleColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            '${roleStatus.label} (${trustScore.toStringAsFixed(0)}/100)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: roleColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleProgressionBar(
    double trustScore,
    BeAProRoleStatus currentRole,
  ) {
    final ratio = (trustScore / 100.0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentRole.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Poz. ${_careerState.careerLevel} • ${_careerState.experienceXp} XP',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: ratio),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _roleColor(currentRole),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '0: Pomocnik',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '60: Wolny Elektron',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.accentBlue,
                  ),
                ),
                Text(
                  '78: Lider Drużyny',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.goldAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioMissionCard(bool isCompact) {
    final progressRatio = _activeMission.completionRatio;
    final statusColor = _statusColor(_activeMission.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _acknowledged
              ? AppColors.goldAccent.withValues(alpha: 0.6)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _activeMission.triggerPhase.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  _activeMission.directorName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _activeMission.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '„${_activeMission.radioCallout}”',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: AppColors.goldAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _activeMission.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _activeMission.targetMetricLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_activeMission.currentProgress.toStringAsFixed(1)} / ${_activeMission.targetValue.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyanAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 7,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsAndStatsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NAGRODY ZA WYPEŁNIENIE ROZKAZU',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RewardChip(
                label:
                    '+${_activeMission.rewardTrustDelta.toStringAsFixed(1)} DS Trust',
                color: AppColors.statusSuccess,
                icon: Icons.verified_user_rounded,
              ),
              _RewardChip(
                label: '+${_activeMission.rewardXp} XP',
                color: AppColors.accentBlue,
                icon: Icons.bolt_rounded,
              ),
              _RewardChip(
                label: '+${_activeMission.rewardSkillPoints} SP',
                color: AppColors.goldAccent,
                icon: Icons.trending_up_rounded,
              ),
              if (_activeMission.rewardBonusEur > 0)
                _RewardChip(
                  label: '+${_activeMission.rewardBonusEur} €',
                  color: AppColors.cyanAccent,
                  icon: Icons.euro_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kara za niewykonanie: ${_activeMission.penaltyTrustDelta.toStringAsFixed(1)} DS Trust',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.crimsonAlert,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(String message) {
    final isSuccess = _activeMission.status == ProCyclistAssignmentStatus.completed;
    final borderColor =
        isSuccess ? AppColors.statusSuccess : AppColors.accentBlue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.radio_rounded,
            color: borderColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isCompact) {
    final isFinished = _activeMission.isFinished;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _InteractiveOrderButton(
          label: _acknowledged ? 'Rozkaz przyjęty' : 'Copy DS (Potwierdź)',
          icon: Icons.check_rounded,
          color: AppColors.accentBlue,
          enabled: !_acknowledged && !isFinished,
          onPressed: _acknowledgeOrder,
        ),
        _InteractiveOrderButton(
          label: 'Postęp +35%',
          icon: Icons.speed_rounded,
          color: AppColors.primaryAccent,
          enabled: !isFinished,
          onPressed: _advanceSimulatedProgress,
        ),
        _InteractiveOrderButton(
          label: 'Rozlicz sukces misji',
          icon: Icons.emoji_events_rounded,
          color: AppColors.statusSuccess,
          enabled: !isFinished,
          onPressed: _resolveMissionSuccess,
        ),
        _InteractiveOrderButton(
          label: 'Następna misja DS',
          icon: Icons.refresh_rounded,
          color: AppColors.goldAccent,
          enabled: true,
          onPressed: _generateNextMission,
        ),
      ],
    );
  }

  Color _roleColor(BeAProRoleStatus status) {
    switch (status) {
      case BeAProRoleStatus.youngDomestique:
        return AppColors.textSecondary;
      case BeAProRoleStatus.trustedDomestique:
        return AppColors.statusSuccess;
      case BeAProRoleStatus.freeElectron:
        return AppColors.accentBlue;
      case BeAProRoleStatus.teamLeader:
        return AppColors.goldAccent;
    }
  }

  Color _statusColor(ProCyclistAssignmentStatus status) {
    switch (status) {
      case ProCyclistAssignmentStatus.assigned:
        return AppColors.amberWarning;
      case ProCyclistAssignmentStatus.inProgress:
        return AppColors.accentBlue;
      case ProCyclistAssignmentStatus.completed:
        return AppColors.statusSuccess;
      case ProCyclistAssignmentStatus.failed:
      case ProCyclistAssignmentStatus.expired:
        return AppColors.crimsonAlert;
    }
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _RewardChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveOrderButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveOrderButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveOrderButton> createState() =>
      _InteractiveOrderButtonState();
}

class _InteractiveOrderButtonState extends State<_InteractiveOrderButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgOpacity = !widget.enabled
        ? 0.06
        : _pressed
            ? 0.34
            : _hovered
                ? 0.26
                : 0.16;
    final borderColor = !widget.enabled
        ? AppColors.cardBorder
        : _focused
            ? AppColors.goldAccent
            : widget.color.withValues(alpha: _hovered ? 0.9 : 0.6);
    final fgColor =
        widget.enabled ? AppColors.textPrimary : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: bgOpacity),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled ? widget.color : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
