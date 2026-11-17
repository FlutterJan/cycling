import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Aktualny tryb etykiety i niepisanych zasad obowiązujący w peletonie.
enum PelotonEtiquetteMode {
  /// Normalna rywalizacja sportowa bez aktywnych ograniczeń.
  normalRacing,

  /// Aktywna przerwa fizjologiczna peletonu ("Nature Break").
  natureBreakActive,

  /// Czasowe zawieszenie ataków po kraksie lidera wyścigu.
  leaderCrashNeutralization,

  /// Przejazd przez strefę bufetu (Feed Zone) — niepisany zakaz ataków.
  feedZoneEtiquette,

  /// Kryzys etykiety: ktoś złamał rozejm, trwa gniewny pościg peletonu.
  etiquetteBreachPursuit;

  String toJson() => name;

  static PelotonEtiquetteMode fromJson(String value) {
    return PelotonEtiquetteMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PelotonEtiquetteMode.normalRacing,
    );
  }

  String get label {
    switch (this) {
      case PelotonEtiquetteMode.normalRacing:
        return 'Normalne ściganie';
      case PelotonEtiquetteMode.natureBreakActive:
        return 'Nature Break';
      case PelotonEtiquetteMode.leaderCrashNeutralization:
        return 'Zawieszenie ataków (Kraksa lidera)';
      case PelotonEtiquetteMode.feedZoneEtiquette:
        return 'Strefa Bufetu (Rozejm)';
      case PelotonEtiquetteMode.etiquetteBreachPursuit:
        return 'Złamanie etykiety — Pościg!';
    }
  }
}

/// Strefa kontekstowa etapu określająca, czy niepisane zasady mają zastosowanie.
enum EtiquetteCourseZone {
  /// Strefa neutralna lub wczesny etap formowania ucieczki.
  earlyStage,

  /// Otwarta szosa w środku etapu — pełne obowiązywanie niepisanych zasad.
  openRoad,

  /// Strefa bufetu (Feed Zone) — zakaz inicjowania ataków.
  feedZone,

  /// Finałowe 25 km lub finałowy podjazd Cat 1 / HC — "Wyścig już trwa", brak rozejmu.
  finalRedZone;

  String toJson() => name;

  static EtiquetteCourseZone fromJson(String value) {
    return EtiquetteCourseZone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EtiquetteCourseZone.openRoad,
    );
  }

  String get label {
    switch (this) {
      case EtiquetteCourseZone.earlyStage:
        return 'Wczesna faza etapu';
      case EtiquetteCourseZone.openRoad:
        return 'Otwarta szosa';
      case EtiquetteCourseZone.feedZone:
        return 'Strefa Bufetu';
      case EtiquetteCourseZone.finalRedZone:
        return 'Strefa Finałowa (<25 km / Góra)';
    }
  }
}

/// Rodzaj naruszenia niepisanych zasad peletonu.
enum EtiquetteViolationType {
  /// Atak podczas ogłoszonego Nature Break.
  attackDuringNatureBreak,

  /// Atak wykorzystujący kraksę lub defekt lidera wyścigu.
  attackOnCrashedLeader,

  /// Atak w strefie bufetu podczas pobierania toreb z prowiantem.
  attackInFeedZone,

  /// Odmowa zwolnienia przez ucieczkę mimo prośby patrona w krytycznym momencie.
  breakawayRefusedCeasefire;

  String toJson() => name;

  static EtiquetteViolationType fromJson(String value) {
    return EtiquetteViolationType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EtiquetteViolationType.attackOnCrashedLeader,
    );
  }

  String get title {
    switch (this) {
      case EtiquetteViolationType.attackDuringNatureBreak:
        return 'Atak podczas Nature Break!';
      case EtiquetteViolationType.attackOnCrashedLeader:
        return 'Atak po kraksie lidera!';
      case EtiquetteViolationType.attackInFeedZone:
        return 'Atak w strefie bufetu!';
      case EtiquetteViolationType.breakawayRefusedCeasefire:
        return 'Ucieczka ignoruje rozejm!';
    }
  }
}

/// Poziom reputacji drużyny w oczach peletonu (wpływa na współpracę i tolerancję).
enum PelotonRespectTier {
  /// Wyrzutek (0–24): rywale nie czekają po kraksach, brak zmian w ucieczkach.
  pariah,

  /// Oportunista (25–49): chłodny dystans, mniejsza chęć do paktów.
  opportunist,

  /// Szanowana ekipa (50–79): standardowa etykieta i wzajemny szacunek.
  respected,

  /// Patron peletonu (80–100): wysoki autorytet, łatwiejsze ogłaszanie rozejmu.
  pelotonPatron;

  String toJson() => name;

  static PelotonRespectTier fromJson(String value) {
    return PelotonRespectTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PelotonRespectTier.respected,
    );
  }

  static PelotonRespectTier fromScore(double score) {
    if (score < 25.0) return PelotonRespectTier.pariah;
    if (score < 50.0) return PelotonRespectTier.opportunist;
    if (score < 80.0) return PelotonRespectTier.respected;
    return PelotonRespectTier.pelotonPatron;
  }

  String get label {
    switch (this) {
      case PelotonRespectTier.pariah:
        return 'Wyrzutek Peletonu';
      case PelotonRespectTier.opportunist:
        return 'Oportunista';
      case PelotonRespectTier.respected:
        return 'Szanowana Ekipa';
      case PelotonRespectTier.pelotonPatron:
        return 'Patron Peletonu';
    }
  }
}

/// Stan pojedynczego kolarza podczas przerwy fizjologicznej Nature Break.
enum NatureBreakRiderPhase {
  /// Jedzie spokojnie w głównej grupie.
  inPeloton,

  /// Zjechał na pobocze na postój fizjologiczny.
  stoppingAtRoadside,

  /// Wraca spokojnym tempem na ogon peletonu.
  chasingBackOn,

  /// Zakończył przerwę i wrócił do szyku.
  completed;

  String toJson() => name;

  static NatureBreakRiderPhase fromJson(String value) {
    return NatureBreakRiderPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NatureBreakRiderPhase.inPeloton,
    );
  }
}

/// Wejściowy kontekst etapu potrzebny do oceny i symulacji etykiety peletonu.
class PelotonEtiquetteStageContext {
  final double distanceCompletedKm;
  final double totalStageDistanceKm;
  final double currentGradientPercent;
  final double crosswindIntensityKmh;
  final bool isBreakawayEstablished;
  final double breakawayGapSeconds;
  final bool isInFeedZone;
  final bool isFinalClimbActive;
  final String raceLeaderId;
  final String raceLeaderName;
  final String raceLeaderTeamId;
  final bool raceLeaderCrashed;
  final double raceLeaderGapSeconds;
  final String patronRiderName;

  const PelotonEtiquetteStageContext({
    required this.distanceCompletedKm,
    required this.totalStageDistanceKm,
    this.currentGradientPercent = 0.0,
    this.crosswindIntensityKmh = 8.0,
    this.isBreakawayEstablished = true,
    this.breakawayGapSeconds = 180.0,
    this.isInFeedZone = false,
    this.isFinalClimbActive = false,
    this.raceLeaderId = 'leader_1',
    this.raceLeaderName = 'Lider GC',
    this.raceLeaderTeamId = 'team_leader',
    this.raceLeaderCrashed = false,
    this.raceLeaderGapSeconds = 0.0,
    this.patronRiderName = 'Kapitan Peletonu',
  });

  double get remainingKm =>
      math.max(0.0, totalStageDistanceKm - distanceCompletedKm);

  double get progressFraction => totalStageDistanceKm <= 0
      ? 0.0
      : (distanceCompletedKm / totalStageDistanceKm).clamp(0.0, 1.0);

  EtiquetteCourseZone resolveZone() {
    if (remainingKm <= 25.0 || isFinalClimbActive) {
      return EtiquetteCourseZone.finalRedZone;
    }
    if (isInFeedZone) {
      return EtiquetteCourseZone.feedZone;
    }
    if (progressFraction < 0.15) {
      return EtiquetteCourseZone.earlyStage;
    }
    return EtiquetteCourseZone.openRoad;
  }

  Map<String, dynamic> toJson() => {
        'distanceCompletedKm': distanceCompletedKm,
        'totalStageDistanceKm': totalStageDistanceKm,
        'currentGradientPercent': currentGradientPercent,
        'crosswindIntensityKmh': crosswindIntensityKmh,
        'isBreakawayEstablished': isBreakawayEstablished,
        'breakawayGapSeconds': breakawayGapSeconds,
        'isInFeedZone': isInFeedZone,
        'isFinalClimbActive': isFinalClimbActive,
        'raceLeaderId': raceLeaderId,
        'raceLeaderName': raceLeaderName,
        'raceLeaderTeamId': raceLeaderTeamId,
        'raceLeaderCrashed': raceLeaderCrashed,
        'raceLeaderGapSeconds': raceLeaderGapSeconds,
        'patronRiderName': patronRiderName,
      };

  factory PelotonEtiquetteStageContext.fromJson(Map<String, dynamic> json) {
    return PelotonEtiquetteStageContext(
      distanceCompletedKm:
          (json['distanceCompletedKm'] as num?)?.toDouble() ?? 0.0,
      totalStageDistanceKm:
          (json['totalStageDistanceKm'] as num?)?.toDouble() ?? 180.0,
      currentGradientPercent:
          (json['currentGradientPercent'] as num?)?.toDouble() ?? 0.0,
      crosswindIntensityKmh:
          (json['crosswindIntensityKmh'] as num?)?.toDouble() ?? 8.0,
      isBreakawayEstablished: json['isBreakawayEstablished'] as bool? ?? true,
      breakawayGapSeconds:
          (json['breakawayGapSeconds'] as num?)?.toDouble() ?? 180.0,
      isInFeedZone: json['isInFeedZone'] as bool? ?? false,
      isFinalClimbActive: json['isFinalClimbActive'] as bool? ?? false,
      raceLeaderId: json['raceLeaderId'] as String? ?? 'leader_1',
      raceLeaderName: json['raceLeaderName'] as String? ?? 'Lider GC',
      raceLeaderTeamId: json['raceLeaderTeamId'] as String? ?? 'team_leader',
      raceLeaderCrashed: json['raceLeaderCrashed'] as bool? ?? false,
      raceLeaderGapSeconds:
          (json['raceLeaderGapSeconds'] as num?)?.toDouble() ?? 0.0,
      patronRiderName:
          json['patronRiderName'] as String? ?? 'Kapitan Peletonu',
    );
  }
}

/// Aktywny stan przerwy fizjologicznej peletonu ("Nature Break").
class NatureBreakSession {
  final bool isActive;
  final double elapsedSeconds;
  final double totalDurationSeconds;
  final String initiatedByTeamId;
  final String initiatedByRiderName;
  final bool breakawayHonoring;
  final double targetPelotonFtpRatio;
  final int ridersStoppingCount;
  final int ridersChasingBackCount;
  final int ridersCompletedCount;

  const NatureBreakSession({
    required this.isActive,
    required this.elapsedSeconds,
    required this.totalDurationSeconds,
    required this.initiatedByTeamId,
    required this.initiatedByRiderName,
    this.breakawayHonoring = true,
    this.targetPelotonFtpRatio = 0.48,
    this.ridersStoppingCount = 0,
    this.ridersChasingBackCount = 0,
    this.ridersCompletedCount = 0,
  });

  double get progress => totalDurationSeconds <= 0
      ? 1.0
      : (elapsedSeconds / totalDurationSeconds).clamp(0.0, 1.0);

  double get remainingSeconds =>
      math.max(0.0, totalDurationSeconds - elapsedSeconds);

  NatureBreakSession copyWith({
    bool? isActive,
    double? elapsedSeconds,
    double? totalDurationSeconds,
    String? initiatedByTeamId,
    String? initiatedByRiderName,
    bool? breakawayHonoring,
    double? targetPelotonFtpRatio,
    int? ridersStoppingCount,
    int? ridersChasingBackCount,
    int? ridersCompletedCount,
  }) {
    return NatureBreakSession(
      isActive: isActive ?? this.isActive,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      initiatedByTeamId: initiatedByTeamId ?? this.initiatedByTeamId,
      initiatedByRiderName: initiatedByRiderName ?? this.initiatedByRiderName,
      breakawayHonoring: breakawayHonoring ?? this.breakawayHonoring,
      targetPelotonFtpRatio:
          targetPelotonFtpRatio ?? this.targetPelotonFtpRatio,
      ridersStoppingCount: ridersStoppingCount ?? this.ridersStoppingCount,
      ridersChasingBackCount:
          ridersChasingBackCount ?? this.ridersChasingBackCount,
      ridersCompletedCount: ridersCompletedCount ?? this.ridersCompletedCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'elapsedSeconds': elapsedSeconds,
        'totalDurationSeconds': totalDurationSeconds,
        'initiatedByTeamId': initiatedByTeamId,
        'initiatedByRiderName': initiatedByRiderName,
        'breakawayHonoring': breakawayHonoring,
        'targetPelotonFtpRatio': targetPelotonFtpRatio,
        'ridersStoppingCount': ridersStoppingCount,
        'ridersChasingBackCount': ridersChasingBackCount,
        'ridersCompletedCount': ridersCompletedCount,
      };

  factory NatureBreakSession.fromJson(Map<String, dynamic> json) {
    return NatureBreakSession(
      isActive: json['isActive'] as bool? ?? false,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      totalDurationSeconds:
          (json['totalDurationSeconds'] as num?)?.toDouble() ?? 150.0,
      initiatedByTeamId: json['initiatedByTeamId'] as String? ?? 'peloton',
      initiatedByRiderName:
          json['initiatedByRiderName'] as String? ?? 'Patron Peletonu',
      breakawayHonoring: json['breakawayHonoring'] as bool? ?? true,
      targetPelotonFtpRatio:
          (json['targetPelotonFtpRatio'] as num?)?.toDouble() ?? 0.48,
      ridersStoppingCount: json['ridersStoppingCount'] as int? ?? 0,
      ridersChasingBackCount: json['ridersChasingBackCount'] as int? ?? 0,
      ridersCompletedCount: json['ridersCompletedCount'] as int? ?? 0,
    );
  }
}

/// Aktywny stan zawieszenia ataków po kraksie lidera wyścigu.
class LeaderCrashNeutralizationState {
  final bool isActive;
  final String crashedLeaderId;
  final String crashedLeaderName;
  final String crashedLeaderTeamId;
  final double initialGapSeconds;
  final double currentGapSeconds;
  final double elapsedSeconds;
  final double maxTimeoutSeconds;
  final double maxAllowedPelotonFtpRatio;
  final bool leaderRejoined;
  final bool expiredByTimeoutOrRedZone;

  const LeaderCrashNeutralizationState({
    required this.isActive,
    required this.crashedLeaderId,
    required this.crashedLeaderName,
    required this.crashedLeaderTeamId,
    required this.initialGapSeconds,
    required this.currentGapSeconds,
    this.elapsedSeconds = 0.0,
    this.maxTimeoutSeconds = 360.0,
    this.maxAllowedPelotonFtpRatio = 0.68,
    this.leaderRejoined = false,
    this.expiredByTimeoutOrRedZone = false,
  });

  double get closureProgress {
    if (initialGapSeconds <= 0) return 1.0;
    return (1.0 - (currentGapSeconds / initialGapSeconds)).clamp(0.0, 1.0);
  }

  LeaderCrashNeutralizationState copyWith({
    bool? isActive,
    String? crashedLeaderId,
    String? crashedLeaderName,
    String? crashedLeaderTeamId,
    double? initialGapSeconds,
    double? currentGapSeconds,
    double? elapsedSeconds,
    double? maxTimeoutSeconds,
    double? maxAllowedPelotonFtpRatio,
    bool? leaderRejoined,
    bool? expiredByTimeoutOrRedZone,
  }) {
    return LeaderCrashNeutralizationState(
      isActive: isActive ?? this.isActive,
      crashedLeaderId: crashedLeaderId ?? this.crashedLeaderId,
      crashedLeaderName: crashedLeaderName ?? this.crashedLeaderName,
      crashedLeaderTeamId: crashedLeaderTeamId ?? this.crashedLeaderTeamId,
      initialGapSeconds: initialGapSeconds ?? this.initialGapSeconds,
      currentGapSeconds: currentGapSeconds ?? this.currentGapSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      maxTimeoutSeconds: maxTimeoutSeconds ?? this.maxTimeoutSeconds,
      maxAllowedPelotonFtpRatio:
          maxAllowedPelotonFtpRatio ?? this.maxAllowedPelotonFtpRatio,
      leaderRejoined: leaderRejoined ?? this.leaderRejoined,
      expiredByTimeoutOrRedZone:
          expiredByTimeoutOrRedZone ?? this.expiredByTimeoutOrRedZone,
    );
  }

  Map<String, dynamic> toJson() => {
        'isActive': isActive,
        'crashedLeaderId': crashedLeaderId,
        'crashedLeaderName': crashedLeaderName,
        'crashedLeaderTeamId': crashedLeaderTeamId,
        'initialGapSeconds': initialGapSeconds,
        'currentGapSeconds': currentGapSeconds,
        'elapsedSeconds': elapsedSeconds,
        'maxTimeoutSeconds': maxTimeoutSeconds,
        'maxAllowedPelotonFtpRatio': maxAllowedPelotonFtpRatio,
        'leaderRejoined': leaderRejoined,
        'expiredByTimeoutOrRedZone': expiredByTimeoutOrRedZone,
      };

  factory LeaderCrashNeutralizationState.fromJson(Map<String, dynamic> json) {
    return LeaderCrashNeutralizationState(
      isActive: json['isActive'] as bool? ?? false,
      crashedLeaderId: json['crashedLeaderId'] as String? ?? 'leader_1',
      crashedLeaderName: json['crashedLeaderName'] as String? ?? 'Lider GC',
      crashedLeaderTeamId:
          json['crashedLeaderTeamId'] as String? ?? 'team_leader',
      initialGapSeconds:
          (json['initialGapSeconds'] as num?)?.toDouble() ?? 45.0,
      currentGapSeconds:
          (json['currentGapSeconds'] as num?)?.toDouble() ?? 45.0,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      maxTimeoutSeconds:
          (json['maxTimeoutSeconds'] as num?)?.toDouble() ?? 360.0,
      maxAllowedPelotonFtpRatio:
          (json['maxAllowedPelotonFtpRatio'] as num?)?.toDouble() ?? 0.68,
      leaderRejoined: json['leaderRejoined'] as bool? ?? false,
      expiredByTimeoutOrRedZone:
          json['expiredByTimeoutOrRedZone'] as bool? ?? false,
    );
  }
}

/// Zarejestrowany incydent złamania lub uhonorowania etykiety peletonu.
class PelotonEtiquetteEventRecord {
  final String id;
  final double stageKm;
  final String title;
  final String description;
  final bool isViolation;
  final EtiquetteViolationType? violationType;
  final String teamId;
  final double respectDelta;

  const PelotonEtiquetteEventRecord({
    required this.id,
    required this.stageKm,
    required this.title,
    required this.description,
    required this.isViolation,
    this.violationType,
    required this.teamId,
    required this.respectDelta,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageKm': stageKm,
        'title': title,
        'description': description,
        'isViolation': isViolation,
        'violationType': violationType?.toJson(),
        'teamId': teamId,
        'respectDelta': respectDelta,
      };

  factory PelotonEtiquetteEventRecord.fromJson(Map<String, dynamic> json) {
    final rawViolation = json['violationType'] as String?;
    return PelotonEtiquetteEventRecord(
      id: json['id'] as String? ?? '',
      stageKm: (json['stageKm'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isViolation: json['isViolation'] as bool? ?? false,
      violationType: rawViolation == null
          ? null
          : EtiquetteViolationType.fromJson(rawViolation),
      teamId: json['teamId'] as String? ?? '',
      respectDelta: (json['respectDelta'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Wynik próby ogłoszenia Nature Break.
class NatureBreakRequestResult {
  final bool accepted;
  final String reason;
  final NatureBreakSession? session;

  const NatureBreakRequestResult({
    required this.accepted,
    required this.reason,
    this.session,
  });
}

/// Modyfikatory fizjologiczno-taktyczne narzucane przez etykietę peletonu.
class PelotonEtiquetteModifiers {
  final PelotonEtiquetteMode mode;
  final bool attacksSuspended;
  final double pelotonFtpCapRatio;
  final double pelotonChaseBoostMultiplier;
  final double breakawayCooperationPenalty;
  final double playerRespectScore;
  final PelotonRespectTier respectTier;
  final String? activeRadioAlert;

  const PelotonEtiquetteModifiers({
    required this.mode,
    required this.attacksSuspended,
    required this.pelotonFtpCapRatio,
    required this.pelotonChaseBoostMultiplier,
    required this.breakawayCooperationPenalty,
    required this.playerRespectScore,
    required this.respectTier,
    this.activeRadioAlert,
  });
}

/// Pełny stan silnika niepisanych zasad peletonu w trakcie etapu.
class PelotonEtiquetteState {
  final PelotonEtiquetteMode mode;
  final EtiquetteCourseZone currentZone;
  final NatureBreakSession? natureBreak;
  final LeaderCrashNeutralizationState? crashNeutralization;
  final double playerRespectScore;
  final double breachPursuitRemainingSeconds;
  final int natureBreaksCompletedThisStage;
  final List<PelotonEtiquetteEventRecord> eventLog;
  final String? lastRadioMessage;

  const PelotonEtiquetteState({
    this.mode = PelotonEtiquetteMode.normalRacing,
    this.currentZone = EtiquetteCourseZone.openRoad,
    this.natureBreak,
    this.crashNeutralization,
    this.playerRespectScore = 65.0,
    this.breachPursuitRemainingSeconds = 0.0,
    this.natureBreaksCompletedThisStage = 0,
    this.eventLog = const [],
    this.lastRadioMessage,
  });

  PelotonRespectTier get respectTier =>
      PelotonRespectTier.fromScore(playerRespectScore);

  bool get areAttacksSuspended =>
      mode == PelotonEtiquetteMode.natureBreakActive ||
      mode == PelotonEtiquetteMode.leaderCrashNeutralization ||
      mode == PelotonEtiquetteMode.feedZoneEtiquette;

  PelotonEtiquetteState copyWith({
    PelotonEtiquetteMode? mode,
    EtiquetteCourseZone? currentZone,
    NatureBreakSession? natureBreak,
    bool clearNatureBreak = false,
    LeaderCrashNeutralizationState? crashNeutralization,
    bool clearCrashNeutralization = false,
    double? playerRespectScore,
    double? breachPursuitRemainingSeconds,
    int? natureBreaksCompletedThisStage,
    List<PelotonEtiquetteEventRecord>? eventLog,
    String? lastRadioMessage,
    bool clearLastRadioMessage = false,
  }) {
    return PelotonEtiquetteState(
      mode: mode ?? this.mode,
      currentZone: currentZone ?? this.currentZone,
      natureBreak:
          clearNatureBreak ? null : (natureBreak ?? this.natureBreak),
      crashNeutralization: clearCrashNeutralization
          ? null
          : (crashNeutralization ?? this.crashNeutralization),
      playerRespectScore:
          (playerRespectScore ?? this.playerRespectScore).clamp(0.0, 100.0),
      breachPursuitRemainingSeconds: math.max(
        0.0,
        breachPursuitRemainingSeconds ?? this.breachPursuitRemainingSeconds,
      ),
      natureBreaksCompletedThisStage: natureBreaksCompletedThisStage ??
          this.natureBreaksCompletedThisStage,
      eventLog: eventLog ?? this.eventLog,
      lastRadioMessage: clearLastRadioMessage
          ? null
          : (lastRadioMessage ?? this.lastRadioMessage),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.toJson(),
        'currentZone': currentZone.toJson(),
        'natureBreak': natureBreak?.toJson(),
        'crashNeutralization': crashNeutralization?.toJson(),
        'playerRespectScore': playerRespectScore,
        'breachPursuitRemainingSeconds': breachPursuitRemainingSeconds,
        'natureBreaksCompletedThisStage': natureBreaksCompletedThisStage,
        'eventLog': eventLog.map((e) => e.toJson()).toList(),
        'lastRadioMessage': lastRadioMessage,
      };

  factory PelotonEtiquetteState.fromJson(Map<String, dynamic> json) {
    final rawBreak = json['natureBreak'] as Map<String, dynamic>?;
    final rawCrash = json['crashNeutralization'] as Map<String, dynamic>?;
    final rawLog = json['eventLog'] as List<dynamic>? ?? const [];
    return PelotonEtiquetteState(
      mode: PelotonEtiquetteMode.fromJson(
        json['mode'] as String? ?? 'normalRacing',
      ),
      currentZone: EtiquetteCourseZone.fromJson(
        json['currentZone'] as String? ?? 'openRoad',
      ),
      natureBreak:
          rawBreak == null ? null : NatureBreakSession.fromJson(rawBreak),
      crashNeutralization: rawCrash == null
          ? null
          : LeaderCrashNeutralizationState.fromJson(rawCrash),
      playerRespectScore:
          (json['playerRespectScore'] as num?)?.toDouble() ?? 65.0,
      breachPursuitRemainingSeconds:
          (json['breachPursuitRemainingSeconds'] as num?)?.toDouble() ?? 0.0,
      natureBreaksCompletedThisStage:
          json['natureBreaksCompletedThisStage'] as int? ?? 0,
      eventLog: rawLog
          .whereType<Map<String, dynamic>>()
          .map(PelotonEtiquetteEventRecord.fromJson)
          .toList(),
      lastRadioMessage: json['lastRadioMessage'] as String?,
    );
  }
}

/// Silnik niepisanych zasad peletonu:
/// 1) `Nature Break` — kontrolowana przerwa fizjologiczna w spokojnej fazie etapu.
/// 2) Zawieszenie ataków po kraksie lidera wyścigu (z wyjątkami finałowych 25 km i gór).
/// 3) Strefa bufetu (`Feed Zone`) oraz system reputacji i konsekwencji złamania etykiety.
class NatureBreakAndPelotonEtiquetteEngine {
  static const double minStageProgressForNatureBreak = 0.18;
  static const double maxRemainingKmForNatureBreak = 35.0;
  static const double maxGradientForNatureBreak = 3.5;
  static const double maxCrosswindForNatureBreak = 22.0;
  static const double minRemainingKmForCrashNeutralization = 25.0;

  /// Sprawdza, czy warunki na trasie pozwalają na ogłoszenie Nature Break.
  NatureBreakRequestResult requestNatureBreak({
    required PelotonEtiquetteState currentState,
    required PelotonEtiquetteStageContext context,
    required String teamId,
    required String riderName,
    double durationSeconds = 150.0,
    int totalPelotonRiders = 150,
  }) {
    if (currentState.mode == PelotonEtiquetteMode.natureBreakActive) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason: 'Nature Break jest już w toku.',
      );
    }
    if (currentState.mode == PelotonEtiquetteMode.leaderCrashNeutralization) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason: 'Trwa zawieszenie ataków po kraksie lidera.',
      );
    }
    if (currentState.mode == PelotonEtiquetteMode.etiquetteBreachPursuit) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason: 'Peleton goni po złamaniu etykiety — brak zgody na postój.',
      );
    }
    if (currentState.natureBreaksCompletedThisStage >= 2) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason: 'Limit przerw Nature Break na ten etap został wykorzystany.',
      );
    }
    if (context.progressFraction < minStageProgressForNatureBreak ||
        !context.isBreakawayEstablished) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason:
            'Ucieczka nie jest jeszcze ustabilizowana — peleton wciąż walczy o odjazd.',
      );
    }
    if (context.remainingKm <= maxRemainingKmForNatureBreak ||
        context.isFinalClimbActive) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason: 'Zbyt blisko mety lub finałowego podjazdu na Nature Break.',
      );
    }
    if (context.currentGradientPercent.abs() > maxGradientForNatureBreak) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason: 'Nachylenie trasy uniemożliwia bezpieczny postój peletonu.',
      );
    }
    if (context.crosswindIntensityKmh >= maxCrosswindForNatureBreak) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason: 'Silny wiatr boczny grozi wachlarzami — peleton nie zwalnia.',
      );
    }
    if (currentState.respectTier == PelotonRespectTier.pariah &&
        teamId != context.raceLeaderTeamId) {
      return const NatureBreakRequestResult(
        accepted: false,
        reason:
            'Peleton odrzucił prośbę ekipy o statusie Wyrzutka — niech poprosi Patron.',
      );
    }

    final clampedDuration = durationSeconds.clamp(60.0, 240.0);
    final initialStopping = math.max(1, (totalPelotonRiders * 0.14).round());

    final session = NatureBreakSession(
      isActive: true,
      elapsedSeconds: 0.0,
      totalDurationSeconds: clampedDuration,
      initiatedByTeamId: teamId,
      initiatedByRiderName: riderName,
      breakawayHonoring: context.breakawayGapSeconds >= 60.0,
      targetPelotonFtpRatio: 0.48,
      ridersStoppingCount: initialStopping,
      ridersChasingBackCount: 0,
      ridersCompletedCount: 0,
    );

    return NatureBreakRequestResult(
      accepted: true,
      reason:
          '${context.patronRiderName} przytaknął: peleton zwalnia na Nature Break.',
      session: session,
    );
  }

  /// Uruchamia Nature Break i zwraca zaktualizowany stan etykiety.
  PelotonEtiquetteState startNatureBreak({
    required PelotonEtiquetteState currentState,
    required PelotonEtiquetteStageContext context,
    required String teamId,
    required String riderName,
    double durationSeconds = 150.0,
    int totalPelotonRiders = 150,
  }) {
    final result = requestNatureBreak(
      currentState: currentState,
      context: context,
      teamId: teamId,
      riderName: riderName,
      durationSeconds: durationSeconds,
      totalPelotonRiders: totalPelotonRiders,
    );
    if (!result.accepted || result.session == null) {
      return currentState.copyWith(lastRadioMessage: result.reason);
    }

    final record = PelotonEtiquetteEventRecord(
      id: 'nb_${context.distanceCompletedKm.toStringAsFixed(1)}',
      stageKm: context.distanceCompletedKm,
      title: 'Ogłoszono Nature Break',
      description:
          '$riderName i ${context.patronRiderName} zatrzymali tempo peletonu (~48% FTP).',
      isViolation: false,
      teamId: teamId,
      respectDelta: 1.5,
    );

    return currentState.copyWith(
      mode: PelotonEtiquetteMode.natureBreakActive,
      currentZone: context.resolveZone(),
      natureBreak: result.session,
      playerRespectScore: currentState.playerRespectScore + 1.5,
      eventLog: [...currentState.eventLog, record],
      lastRadioMessage: result.reason,
    );
  }

  /// Aktywuje zawieszenie ataków po kraksie lidera wyścigu, jeśli pozwala na to strefa etapu.
  PelotonEtiquetteState triggerLeaderCrashNeutralization({
    required PelotonEtiquetteState currentState,
    required PelotonEtiquetteStageContext context,
    double initialGapSeconds = 45.0,
    double maxTimeoutSeconds = 360.0,
  }) {
    final zone = context.resolveZone();
    if (zone == EtiquetteCourseZone.finalRedZone ||
        context.remainingKm <= minRemainingKmForCrashNeutralization) {
      final record = PelotonEtiquetteEventRecord(
        id: 'crash_red_${context.distanceCompletedKm.toStringAsFixed(1)}',
        stageKm: context.distanceCompletedKm,
        title: 'Kraksa lidera w strefie finałowej',
        description:
            '${context.raceLeaderName} upadł <25 km przed metą — wyścig trwa, brak rozejmu!',
        isViolation: false,
        teamId: context.raceLeaderTeamId,
        respectDelta: 0.0,
      );
      return currentState.copyWith(
        currentZone: zone,
        eventLog: [...currentState.eventLog, record],
        lastRadioMessage:
            'Kraksa lidera w strefie finałowej (<25 km) — peleton nie zatrzymuje wyścigu.',
      );
    }

    final clampedGap = initialGapSeconds.clamp(10.0, 240.0);
    final neutralization = LeaderCrashNeutralizationState(
      isActive: true,
      crashedLeaderId: context.raceLeaderId,
      crashedLeaderName: context.raceLeaderName,
      crashedLeaderTeamId: context.raceLeaderTeamId,
      initialGapSeconds: clampedGap,
      currentGapSeconds: clampedGap,
      elapsedSeconds: 0.0,
      maxTimeoutSeconds: maxTimeoutSeconds.clamp(120.0, 600.0),
      maxAllowedPelotonFtpRatio: 0.68,
    );

    final record = PelotonEtiquetteEventRecord(
      id: 'crash_truce_${context.distanceCompletedKm.toStringAsFixed(1)}',
      stageKm: context.distanceCompletedKm,
      title: 'Zawieszenie ataków po kraksie lidera',
      description:
          '${context.raceLeaderName} leżał w kraksie (${clampedGap.toStringAsFixed(0)} s straty). Peleton wstrzymuje ataki.',
      isViolation: false,
      teamId: context.raceLeaderTeamId,
      respectDelta: 0.0,
    );

    return currentState.copyWith(
      mode: PelotonEtiquetteMode.leaderCrashNeutralization,
      currentZone: zone,
      clearNatureBreak: true,
      crashNeutralization: neutralization,
      eventLog: [...currentState.eventLog, record],
      lastRadioMessage:
          'Radio Peletonu: ${context.raceLeaderName} po kraksie! Ataki zawieszone do powrotu lidera.',
    );
  }

  /// Gracz lub drużyna świadomie honoruje rozejm (np. nakazuje liderowi/ekipie czekać).
  PelotonEtiquetteState honorNeutralization({
    required PelotonEtiquetteState currentState,
    required PelotonEtiquetteStageContext context,
    required String teamId,
  }) {
    if (!currentState.areAttacksSuspended) {
      return currentState.copyWith(
        lastRadioMessage: 'Obecnie nie obowiązuje żaden rozejm do uhonorowania.',
      );
    }

    const bonus = 4.0;
    final record = PelotonEtiquetteEventRecord(
      id: 'fairplay_${context.distanceCompletedKm.toStringAsFixed(1)}_${currentState.eventLog.length}',
      stageKm: context.distanceCompletedKm,
      title: 'Fair Play: Uhonorowano rozejm',
      description:
          'Ekipa zwolniła tempo i wezwała grupę do poszanowania niepisanych zasad.',
      isViolation: false,
      teamId: teamId,
      respectDelta: bonus,
    );

    return currentState.copyWith(
      playerRespectScore: currentState.playerRespectScore + bonus,
      eventLog: [...currentState.eventLog, record],
      lastRadioMessage:
          'Peleton docenia postawę Fair Play (+${bonus.toStringAsFixed(0)} pkt szacunku).',
    );
  }

  /// Rejestruje próbę ataku podczas aktywnego rozejmu / Nature Break / Feed Zone.
  PelotonEtiquetteState reportAttackAttempt({
    required PelotonEtiquetteState currentState,
    required PelotonEtiquetteStageContext context,
    required String attackingTeamId,
    required String attackingRiderName,
    bool isPlayerTeam = true,
  }) {
    final zone = context.resolveZone();
    EtiquetteViolationType? violation;

    if (currentState.mode == PelotonEtiquetteMode.natureBreakActive) {
      violation = EtiquetteViolationType.attackDuringNatureBreak;
    } else if (currentState.mode ==
        PelotonEtiquetteMode.leaderCrashNeutralization) {
      violation = EtiquetteViolationType.attackOnCrashedLeader;
    } else if (currentState.mode == PelotonEtiquetteMode.feedZoneEtiquette ||
        zone == EtiquetteCourseZone.feedZone) {
      violation = EtiquetteViolationType.attackInFeedZone;
    }

    if (violation == null) {
      return currentState.copyWith(
        currentZone: zone,
        lastRadioMessage: 'Atak $attackingRiderName w ramach czystej rywalizacji.',
      );
    }

    final respectPenalty = switch (violation) {
      EtiquetteViolationType.attackOnCrashedLeader => -28.0,
      EtiquetteViolationType.attackDuringNatureBreak => -22.0,
      EtiquetteViolationType.attackInFeedZone => -15.0,
      EtiquetteViolationType.breakawayRefusedCeasefire => -12.0,
    };

    final record = PelotonEtiquetteEventRecord(
      id: 'breach_${context.distanceCompletedKm.toStringAsFixed(1)}_${currentState.eventLog.length}',
      stageKm: context.distanceCompletedKm,
      title: violation.title,
      description:
          '$attackingRiderName zaatakował wbrew niepisanym zasadom! Peleton rusza w gniewny pościg.',
      isViolation: true,
      violationType: violation,
      teamId: attackingTeamId,
      respectDelta: isPlayerTeam ? respectPenalty : 0.0,
    );

    return currentState.copyWith(
      mode: PelotonEtiquetteMode.etiquetteBreachPursuit,
      currentZone: zone,
      clearNatureBreak: true,
      clearCrashNeutralization: true,
      playerRespectScore: isPlayerTeam
          ? currentState.playerRespectScore + respectPenalty
          : currentState.playerRespectScore,
      breachPursuitRemainingSeconds: 180.0,
      eventLog: [...currentState.eventLog, record],
      lastRadioMessage:
          'SKANDAL NA SZOSIE: ${violation.title} Peleton podkręca tempo do 125%!',
    );
  }

  /// Aktualizuje stan niepisanych zasad o krok czasowy `deltaSeconds`.
  PelotonEtiquetteState step({
    required PelotonEtiquetteState currentState,
    required PelotonEtiquetteStageContext context,
    required double deltaSeconds,
    int totalPelotonRiders = 150,
  }) {
    if (deltaSeconds <= 0) return currentState;

    var state = currentState.copyWith(currentZone: context.resolveZone());

    // Automatyczne przejście do strefy finałowej kończy każdy rozejm.
    if (state.currentZone == EtiquetteCourseZone.finalRedZone &&
        (state.mode == PelotonEtiquetteMode.natureBreakActive ||
            state.mode == PelotonEtiquetteMode.leaderCrashNeutralization ||
            state.mode == PelotonEtiquetteMode.feedZoneEtiquette)) {
      final resumeRecord = PelotonEtiquetteEventRecord(
        id: 'redzone_${context.distanceCompletedKm.toStringAsFixed(1)}',
        stageKm: context.distanceCompletedKm,
        title: 'Wznowienie pełnego ścigania',
        description:
            'Wjazd w strefę finałową (<25 km / podjazd) — wszystkie rozejmy wygasają.',
        isViolation: false,
        teamId: 'peloton',
        respectDelta: 0.0,
      );
      return state.copyWith(
        mode: PelotonEtiquetteMode.normalRacing,
        clearNatureBreak: true,
        clearCrashNeutralization: true,
        eventLog: [...state.eventLog, resumeRecord],
        lastRadioMessage: 'Koniec rozejmu — wjazd w strefę finałową!',
      );
    }

    // Automatyczne wyzwolenie rozejmu, jeśli lider właśnie uległ kraksie.
    if (context.raceLeaderCrashed &&
        context.raceLeaderGapSeconds > 8.0 &&
        state.mode == PelotonEtiquetteMode.normalRacing &&
        state.currentZone != EtiquetteCourseZone.finalRedZone) {
      state = triggerLeaderCrashNeutralization(
        currentState: state,
        context: context,
        initialGapSeconds: context.raceLeaderGapSeconds,
      );
    }

    switch (state.mode) {
      case PelotonEtiquetteMode.natureBreakActive:
        final session = state.natureBreak;
        if (session == null) {
          return state.copyWith(mode: PelotonEtiquetteMode.normalRacing);
        }
        final nextElapsed = session.elapsedSeconds + deltaSeconds;
        final progress =
            (nextElapsed / session.totalDurationSeconds).clamp(0.0, 1.0);
        final activeWave =
            (totalPelotonRiders * 0.25 * math.sin(progress * math.pi))
                .round()
                .clamp(0, totalPelotonRiders);
        final chasingWave =
            (totalPelotonRiders * 0.15 * progress).round().clamp(0, totalPelotonRiders);
        final completedCount =
            (totalPelotonRiders * progress).round().clamp(0, totalPelotonRiders);

        if (nextElapsed >= session.totalDurationSeconds) {
          final doneRecord = PelotonEtiquetteEventRecord(
            id: 'nb_done_${context.distanceCompletedKm.toStringAsFixed(1)}',
            stageKm: context.distanceCompletedKm,
            title: 'Koniec Nature Break',
            description:
                'Wszyscy kolarze wrócili do peletonu. Tempo wraca do normy.',
            isViolation: false,
            teamId: session.initiatedByTeamId,
            respectDelta: 0.0,
          );
          return state.copyWith(
            mode: PelotonEtiquetteMode.normalRacing,
            clearNatureBreak: true,
            natureBreaksCompletedThisStage:
                state.natureBreaksCompletedThisStage + 1,
            eventLog: [...state.eventLog, doneRecord],
            lastRadioMessage:
                'Nature Break zakończony — peleton wznawia normalne tempo.',
          );
        }

        return state.copyWith(
          natureBreak: session.copyWith(
            elapsedSeconds: nextElapsed,
            ridersStoppingCount: activeWave,
            ridersChasingBackCount: chasingWave,
            ridersCompletedCount: completedCount,
          ),
        );

      case PelotonEtiquetteMode.leaderCrashNeutralization:
        final truce = state.crashNeutralization;
        if (truce == null) {
          return state.copyWith(mode: PelotonEtiquetteMode.normalRacing);
        }
        final nextElapsed = truce.elapsedSeconds + deltaSeconds;
        // Symulujemy odrabianie straty przez lidera z pomocą pomocników (~0.35 s/s),
        // chyba że kontekst zewnętrzny podaje już mniejszą stratę.
        final simulatedGap = math.max(
          0.0,
          truce.currentGapSeconds - deltaSeconds * 0.35,
        );
        final effectiveGap = context.raceLeaderCrashed
            ? math.min(simulatedGap, context.raceLeaderGapSeconds)
            : simulatedGap;

        if (effectiveGap <= 2.0) {
          final rejoinedRecord = PelotonEtiquetteEventRecord(
            id: 'leader_back_${context.distanceCompletedKm.toStringAsFixed(1)}',
            stageKm: context.distanceCompletedKm,
            title: '${truce.crashedLeaderName} wrócił do peletonu',
            description:
                'Lider wyścigu dołączył do głównej grupy. Rozejm zostaje oficjalnie zakończony.',
            isViolation: false,
            teamId: truce.crashedLeaderTeamId,
            respectDelta: 0.0,
          );
          return state.copyWith(
            mode: PelotonEtiquetteMode.normalRacing,
            clearCrashNeutralization: true,
            eventLog: [...state.eventLog, rejoinedRecord],
            lastRadioMessage:
                '${truce.crashedLeaderName} wrócił do peletonu — wznowienie ścigania!',
          );
        }

        if (nextElapsed >= truce.maxTimeoutSeconds) {
          final timeoutRecord = PelotonEtiquetteEventRecord(
            id: 'truce_timeout_${context.distanceCompletedKm.toStringAsFixed(1)}',
            stageKm: context.distanceCompletedKm,
            title: 'Koniec okna rozejmu',
            description:
                'Upłynął maksymalny czas oczekiwania (${(truce.maxTimeoutSeconds / 60).toStringAsFixed(0)} min). Ekipy wracają do wyścigu.',
            isViolation: false,
            teamId: 'peloton',
            respectDelta: 0.0,
          );
          return state.copyWith(
            mode: PelotonEtiquetteMode.normalRacing,
            clearCrashNeutralization: true,
            eventLog: [...state.eventLog, timeoutRecord],
            lastRadioMessage:
                'Limit czasu rozejmu wygasł — wyścig zostaje wznowiony.',
          );
        }

        return state.copyWith(
          crashNeutralization: truce.copyWith(
            elapsedSeconds: nextElapsed,
            currentGapSeconds: effectiveGap,
          ),
        );

      case PelotonEtiquetteMode.feedZoneEtiquette:
        if (state.currentZone != EtiquetteCourseZone.feedZone) {
          return state.copyWith(
            mode: PelotonEtiquetteMode.normalRacing,
            lastRadioMessage: 'Koniec strefy bufetu — pełne ściganie wznowione.',
          );
        }
        return state;

      case PelotonEtiquetteMode.etiquetteBreachPursuit:
        final nextPursuit = state.breachPursuitRemainingSeconds - deltaSeconds;
        if (nextPursuit <= 0.0) {
          return state.copyWith(
            mode: PelotonEtiquetteMode.normalRacing,
            breachPursuitRemainingSeconds: 0.0,
            lastRadioMessage: 'Gniewny pościg peletonu wygasł.',
          );
        }
        return state.copyWith(breachPursuitRemainingSeconds: nextPursuit);

      case PelotonEtiquetteMode.normalRacing:
        if (state.currentZone == EtiquetteCourseZone.feedZone) {
          return state.copyWith(
            mode: PelotonEtiquetteMode.feedZoneEtiquette,
            lastRadioMessage:
                'Wjazd do Strefy Bufetu — obowiązuje niepisany zakaz ataków.',
          );
        }
        return state;
    }
  }

  /// Zwraca aktualne modyfikatory dla silnika fizyki i AI peletonu.
  PelotonEtiquetteModifiers computeModifiers(PelotonEtiquetteState state) {
    final coopPenalty = switch (state.respectTier) {
      PelotonRespectTier.pariah => 0.45,
      PelotonRespectTier.opportunist => 0.20,
      PelotonRespectTier.respected => 0.0,
      PelotonRespectTier.pelotonPatron => -0.10,
    };

    switch (state.mode) {
      case PelotonEtiquetteMode.natureBreakActive:
        return PelotonEtiquetteModifiers(
          mode: state.mode,
          attacksSuspended: true,
          pelotonFtpCapRatio:
              state.natureBreak?.targetPelotonFtpRatio ?? 0.48,
          pelotonChaseBoostMultiplier: 0.50,
          breakawayCooperationPenalty: coopPenalty,
          playerRespectScore: state.playerRespectScore,
          respectTier: state.respectTier,
          activeRadioAlert: state.lastRadioMessage,
        );
      case PelotonEtiquetteMode.leaderCrashNeutralization:
        return PelotonEtiquetteModifiers(
          mode: state.mode,
          attacksSuspended: true,
          pelotonFtpCapRatio:
              state.crashNeutralization?.maxAllowedPelotonFtpRatio ?? 0.68,
          pelotonChaseBoostMultiplier: 0.65,
          breakawayCooperationPenalty: coopPenalty,
          playerRespectScore: state.playerRespectScore,
          respectTier: state.respectTier,
          activeRadioAlert: state.lastRadioMessage,
        );
      case PelotonEtiquetteMode.feedZoneEtiquette:
        return PelotonEtiquetteModifiers(
          mode: state.mode,
          attacksSuspended: true,
          pelotonFtpCapRatio: 0.78,
          pelotonChaseBoostMultiplier: 0.85,
          breakawayCooperationPenalty: coopPenalty,
          playerRespectScore: state.playerRespectScore,
          respectTier: state.respectTier,
          activeRadioAlert: state.lastRadioMessage,
        );
      case PelotonEtiquetteMode.etiquetteBreachPursuit:
        return PelotonEtiquetteModifiers(
          mode: state.mode,
          attacksSuspended: false,
          pelotonFtpCapRatio: 1.25,
          pelotonChaseBoostMultiplier: 1.40,
          breakawayCooperationPenalty: math.max(0.25, coopPenalty),
          playerRespectScore: state.playerRespectScore,
          respectTier: state.respectTier,
          activeRadioAlert: state.lastRadioMessage,
        );
      case PelotonEtiquetteMode.normalRacing:
        return PelotonEtiquetteModifiers(
          mode: state.mode,
          attacksSuspended: false,
          pelotonFtpCapRatio: 1.15,
          pelotonChaseBoostMultiplier: 1.0,
          breakawayCooperationPenalty: coopPenalty,
          playerRespectScore: state.playerRespectScore,
          respectTier: state.respectTier,
          activeRadioAlert: state.lastRadioMessage,
        );
    }
  }
}

/// Produkcyjny panel UI zarządzania niepisanymi zasadami peletonu
/// (`Nature Break` oraz zawieszenie ataków po kraksie lidera).
class NatureBreakAndPelotonEtiquettePanel extends StatefulWidget {
  final PelotonEtiquetteState state;
  final PelotonEtiquetteStageContext stageContext;
  final VoidCallback? onRequestNatureBreak;
  final VoidCallback? onSimulateLeaderCrash;
  final VoidCallback? onHonorNeutralization;
  final VoidCallback? onAttackDuringTruce;
  final VoidCallback? onAdvanceStep;

  const NatureBreakAndPelotonEtiquettePanel({
    super.key,
    required this.state,
    required this.stageContext,
    this.onRequestNatureBreak,
    this.onSimulateLeaderCrash,
    this.onHonorNeutralization,
    this.onAttackDuringTruce,
    this.onAdvanceStep,
  });

  @override
  State<NatureBreakAndPelotonEtiquettePanel> createState() =>
      _NatureBreakAndPelotonEtiquettePanelState();
}

class _NatureBreakAndPelotonEtiquettePanelState
    extends State<NatureBreakAndPelotonEtiquettePanel> {
  static const Duration _animDuration = Duration(milliseconds: 240);

  Color _modeAccent(PelotonEtiquetteMode mode) {
    switch (mode) {
      case PelotonEtiquetteMode.normalRacing:
        return AppColors.accentBlue;
      case PelotonEtiquetteMode.natureBreakActive:
        return AppColors.statusSuccess;
      case PelotonEtiquetteMode.leaderCrashNeutralization:
        return AppColors.amberWarning;
      case PelotonEtiquetteMode.feedZoneEtiquette:
        return AppColors.goldAccent;
      case PelotonEtiquetteMode.etiquetteBreachPursuit:
        return AppColors.crimsonAlert;
    }
  }

  IconData _modeIcon(PelotonEtiquetteMode mode) {
    switch (mode) {
      case PelotonEtiquetteMode.normalRacing:
        return Icons.directions_bike_rounded;
      case PelotonEtiquetteMode.natureBreakActive:
        return Icons.pause_circle_outline_rounded;
      case PelotonEtiquetteMode.leaderCrashNeutralization:
        return Icons.health_and_safety_rounded;
      case PelotonEtiquetteMode.feedZoneEtiquette:
        return Icons.local_drink_rounded;
      case PelotonEtiquetteMode.etiquetteBreachPursuit:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _modeAccent(widget.state.mode);
    final modifiers = NatureBreakAndPelotonEtiquetteEngine()
        .computeModifiers(widget.state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final isWide = constraints.maxWidth >= 900;

        return AnimatedContainer(
          duration: _animDuration,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.state.mode ==
                      PelotonEtiquetteMode.etiquetteBreachPursuit
                  ? AppColors.crimsonAlert
                  : AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(accent, isCompact),
              const SizedBox(height: 14),
              if (widget.state.lastRadioMessage != null) ...[
                _buildRadioBanner(accent),
                const SizedBox(height: 14),
              ],
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildActiveMechanismCard(accent, modifiers),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildRespectCard(),
                    ),
                  ],
                )
              else ...[
                _buildActiveMechanismCard(accent, modifiers),
                const SizedBox(height: 12),
                _buildRespectCard(),
              ],
              const SizedBox(height: 14),
              _buildActionButtons(isCompact),
              if (widget.state.eventLog.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildEventLog(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color accent, bool isCompact) {
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
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Icon(_modeIcon(widget.state.mode), color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Etykieta Peletonu & Nature Break',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Strefa: ${widget.state.currentZone.label} • Do mety: ${widget.stageContext.remainingKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: _animDuration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Text(
            widget.state.mode.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioBanner(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.headset_mic_rounded, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.state.lastRadioMessage ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMechanismCard(
    Color accent,
    PelotonEtiquetteModifiers modifiers,
  ) {
    final natureBreak = widget.state.natureBreak;
    final crashTruce = widget.state.crashNeutralization;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Status Zasad na Szosie',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Limit tempa: ${(modifiers.pelotonFtpCapRatio * 100).toStringAsFixed(0)}% FTP',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (natureBreak != null && natureBreak.isActive) ...[
            Text(
              'Inicjator: ${natureBreak.initiatedByRiderName} • Pozostało: ${natureBreak.remainingSeconds.toStringAsFixed(0)} s',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: natureBreak.progress,
                minHeight: 7,
                backgroundColor: AppColors.background,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.statusSuccess),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _statChip('Na poboczu', '${natureBreak.ridersStoppingCount}'),
                _statChip('Wraca do grupy', '${natureBreak.ridersChasingBackCount}'),
                _statChip('W szyku', '${natureBreak.ridersCompletedCount}'),
              ],
            ),
          ] else if (crashTruce != null && crashTruce.isActive) ...[
            Text(
              'Lider po kraksie: ${crashTruce.crashedLeaderName} • Strata: ${crashTruce.currentGapSeconds.toStringAsFixed(1)} s',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: crashTruce.closureProgress,
                minHeight: 7,
                backgroundColor: AppColors.background,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.amberWarning),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ataki w peletonie zawieszone do powrotu lidera lub wjazdu w ostatnie 25 km.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            Text(
              widget.state.mode == PelotonEtiquetteMode.etiquetteBreachPursuit
                  ? 'Peleton goni złamany rozejm! Pozostało ${widget.state.breachPursuitRemainingSeconds.toStringAsFixed(0)} s pościgu (+40% motywacji).'
                  : 'Brak aktywnego rozejmu. Możesz zgłosić Nature Break w spokojnej fazie etapu.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          color: AppColors.textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildRespectCard() {
    final score = widget.state.playerRespectScore;
    final tier = widget.state.respectTier;
    final tierColor = switch (tier) {
      PelotonRespectTier.pariah => AppColors.crimsonAlert,
      PelotonRespectTier.opportunist => AppColors.amberWarning,
      PelotonRespectTier.respected => AppColors.accentBlue,
      PelotonRespectTier.pelotonPatron => AppColors.goldAccent,
    };

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Szacunek Peletonu',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${score.toStringAsFixed(0)} / 100',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tierColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ranga: ${tier.label}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tierColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isCompact) {
    final truceActive = widget.state.areAttacksSuspended;
    final canRequestBreak =
        widget.state.mode == PelotonEtiquetteMode.normalRacing &&
            widget.onRequestNatureBreak != null;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _EtiquetteActionButton(
          label: 'Ogłoś Nature Break',
          icon: Icons.pause_rounded,
          accentColor: AppColors.statusSuccess,
          enabled: canRequestBreak,
          onPressed: widget.onRequestNatureBreak,
        ),
        _EtiquetteActionButton(
          label: 'Kraksa Lidera (Rozejm)',
          icon: Icons.personal_injury_rounded,
          accentColor: AppColors.amberWarning,
          enabled: widget.onSimulateLeaderCrash != null &&
              widget.state.mode !=
                  PelotonEtiquetteMode.leaderCrashNeutralization,
          onPressed: widget.onSimulateLeaderCrash,
        ),
        _EtiquetteActionButton(
          label: 'Szanuj Rozejm (Fair Play)',
          icon: Icons.handshake_rounded,
          accentColor: AppColors.goldAccent,
          enabled: truceActive && widget.onHonorNeutralization != null,
          onPressed: widget.onHonorNeutralization,
        ),
        _EtiquetteActionButton(
          label: 'Atakuj Mimo Rozejmu',
          icon: Icons.bolt_rounded,
          accentColor: AppColors.crimsonAlert,
          enabled: truceActive && widget.onAttackDuringTruce != null,
          onPressed: widget.onAttackDuringTruce,
        ),
        if (widget.onAdvanceStep != null)
          _EtiquetteActionButton(
            label: '+30 s Symulacji',
            icon: Icons.fast_forward_rounded,
            accentColor: AppColors.accentBlue,
            enabled: true,
            onPressed: widget.onAdvanceStep,
          ),
      ],
    );
  }

  Widget _buildEventLog() {
    final recent = widget.state.eventLog.reversed.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dziennik Etykiety',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        for (final entry in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: entry.isViolation
                      ? AppColors.crimsonAlert.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.isViolation
                        ? Icons.gavel_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: entry.isViolation
                        ? AppColors.crimsonAlert
                        : AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '[${entry.stageKm.toStringAsFixed(1)} km] ${entry.title}: ${entry.description}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EtiquetteActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback? onPressed;

  const _EtiquetteActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_EtiquetteActionButton> createState() => _EtiquetteActionButtonState();
}

class _EtiquetteActionButtonState extends State<_EtiquetteActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.enabled && widget.onPressed != null;
    final bgColor = !isActive
        ? AppColors.background.withValues(alpha: 0.6)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.28)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.20)
                : widget.accentColor.withValues(alpha: 0.12);

    final borderColor = !isActive
        ? AppColors.cardBorder
        : _focused
            ? AppColors.textPrimary
            : widget.accentColor.withValues(alpha: _hovered ? 0.85 : 0.45);

    final fgColor = isActive ? AppColors.textPrimary : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: isActive,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isActive ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isActive ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: isActive ? () => setState(() => _pressed = false) : null,
        onTap: isActive ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isActive ? widget.accentColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
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
