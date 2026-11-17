import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Rodzaj paktu dyplomatycznego zawieranego na szosie podczas etapu.
enum DiplomacyPactType {
  /// Układ "Etap za GC": uciekinier lub rywal bez ambicji GC ciągnie mocno,
  /// aby pomóc liderowi GC zyskać czas w zamian za oddanie zwycięstwa etapowego.
  stageForGcDeal,

  /// Koalicja Anty-Lidera: dwie lub więcej ekip łączy siły w rotacji i atakach,
  /// aby odizolować i złamać lidera wyścigu (żółta/różowa/czerwona koszulka).
  antiLeaderCoalition,

  /// Rozejm Neutralizacyjny: czasowe zawieszenie ataków (np. po kraksie lidera,
  /// w niebezpiecznych warunkach pogodowych lub przed finałowym podjazdem).
  neutralizationTruce;

  String toJson() => name;

  static DiplomacyPactType fromJson(String value) {
    return DiplomacyPactType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DiplomacyPactType.stageForGcDeal,
    );
  }

  String get displayName {
    switch (this) {
      case DiplomacyPactType.stageForGcDeal:
        return 'Stage for GC Deal';
      case DiplomacyPactType.antiLeaderCoalition:
        return 'Anti-Leader Coalition';
      case DiplomacyPactType.neutralizationTruce:
        return 'Neutralization Truce';
    }
  }

  String get shortDescription {
    switch (this) {
      case DiplomacyPactType.stageForGcDeal:
        return 'Ty oddajesz wygraną etapową, partner daje pełne zmiany pod GC.';
      case DiplomacyPactType.antiLeaderCoalition:
        return 'Wspólne ataki i rotacja ekip przeciwko liderowi klasyfikacji GC.';
      case DiplomacyPactType.neutralizationTruce:
        return 'Czasowe zawieszenie broni i zakaz ataków w grupie.';
    }
  }
}

/// Aktualny status paktu dyplomatycznego na szosie.
enum DiplomacyPactStatus {
  /// Propozycja wysłana przez radio / na szosie, oczekuje na odpowiedź.
  proposed,

  /// Pakt aktywny i egzekwowany przez obie strony w symulacji.
  active,

  /// Pakt dotrzymany do końca i rozliczony z bonusem reputacji.
  fulfilled,

  /// Pakt wygasł naturalnie (np. koniec okna czasowego lub złapanie grupy).
  expired,

  /// Pakt złamany przez zdradę ("Betrayal!") — wywołuje wendetę.
  betrayed;

  String toJson() => name;

  static DiplomacyPactStatus fromJson(String value) {
    return DiplomacyPactStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DiplomacyPactStatus.proposed,
    );
  }

  String get label {
    switch (this) {
      case DiplomacyPactStatus.proposed:
        return 'Propozycja';
      case DiplomacyPactStatus.active:
        return 'Aktywny';
      case DiplomacyPactStatus.fulfilled:
        return 'Dotrzymany';
      case DiplomacyPactStatus.expired:
        return 'Wygasły';
      case DiplomacyPactStatus.betrayed:
        return 'ZDRADA (Betrayal!)';
    }
  }
}

/// Powód wykrycia lub wywołania zdrady paktu na szosie.
enum BetrayalReason {
  /// Atak w trakcie trwania rozejmu neutralizacyjnego.
  attackedDuringTruce,

  /// Złamanie układu "Stage for GC Deal" poprzez walkę o wygraną etapową na finiszu.
  sprintedForPromisedStage,

  /// Odmowa dawania zmian (jazda na kole) mimo zobowiązania w pakcie.
  refusedAgreedPulls,

  /// Pomoc liderowi wyścigu lub sabotaż koalicji anty-lidera.
  sabotagedCoalition,

  /// Ręczne zerwanie paktu przez dyrektora sportowego z wozu.
  manualPactBreach;

  String toJson() => name;

  static BetrayalReason fromJson(String value) {
    return BetrayalReason.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BetrayalReason.manualPactBreach,
    );
  }

  String get label {
    switch (this) {
      case BetrayalReason.attackedDuringTruce:
        return 'Atak podczas rozejmu';
      case BetrayalReason.sprintedForPromisedStage:
        return 'Finisz po obiecaną wygraną etapową';
      case BetrayalReason.refusedAgreedPulls:
        return 'Odmowa zmian w układzie';
      case BetrayalReason.sabotagedCoalition:
        return 'Sabotaż koalicji anty-lidera';
      case BetrayalReason.manualPactBreach:
        return 'Celowe zerwanie paktu';
    }
  }
}

/// Poziom dotkliwości zdrady paktu.
enum BetrayalSeverity {
  moderate,
  severe,
  infamous;

  String toJson() => name;

  static BetrayalSeverity fromJson(String value) {
    return BetrayalSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BetrayalSeverity.severe,
    );
  }
}

/// Profil uczestnika negocjacji dyplomatycznych na szosie (ekipa / kolarz).
class DiplomacyTeamContext {
  final String teamId;
  final String teamName;
  final String riderId;
  final String riderName;
  final int gcPosition;
  final double gcGapToLeaderSeconds;
  final bool isRaceLeader;
  final bool hasStageWinAmbition;
  final bool isInSameGroup;

  /// Aktualny poziom zaufania tej ekipy do inicjatora (0..100).
  final double trustScore;

  /// Liczba etapów pozostałej wendety za wcześniejszą zdradę.
  final int activeVendettaStages;

  /// Skłonność ekipy do ryzyka / agresji (0.0..1.0).
  final double aggressionFactor;

  const DiplomacyTeamContext({
    required this.teamId,
    required this.teamName,
    required this.riderId,
    required this.riderName,
    required this.gcPosition,
    required this.gcGapToLeaderSeconds,
    this.isRaceLeader = false,
    this.hasStageWinAmbition = true,
    this.isInSameGroup = true,
    this.trustScore = 65.0,
    this.activeVendettaStages = 0,
    this.aggressionFactor = 0.5,
  });

  bool get isHostile => activeVendettaStages > 0 || trustScore < 30.0;

  DiplomacyTeamContext copyWith({
    String? teamId,
    String? teamName,
    String? riderId,
    String? riderName,
    int? gcPosition,
    double? gcGapToLeaderSeconds,
    bool? isRaceLeader,
    bool? hasStageWinAmbition,
    bool? isInSameGroup,
    double? trustScore,
    int? activeVendettaStages,
    double? aggressionFactor,
  }) {
    return DiplomacyTeamContext(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      gcPosition: gcPosition ?? this.gcPosition,
      gcGapToLeaderSeconds: gcGapToLeaderSeconds ?? this.gcGapToLeaderSeconds,
      isRaceLeader: isRaceLeader ?? this.isRaceLeader,
      hasStageWinAmbition: hasStageWinAmbition ?? this.hasStageWinAmbition,
      isInSameGroup: isInSameGroup ?? this.isInSameGroup,
      trustScore: trustScore ?? this.trustScore,
      activeVendettaStages: activeVendettaStages ?? this.activeVendettaStages,
      aggressionFactor: aggressionFactor ?? this.aggressionFactor,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'riderId': riderId,
        'riderName': riderName,
        'gcPosition': gcPosition,
        'gcGapToLeaderSeconds': gcGapToLeaderSeconds,
        'isRaceLeader': isRaceLeader,
        'hasStageWinAmbition': hasStageWinAmbition,
        'isInSameGroup': isInSameGroup,
        'trustScore': trustScore,
        'activeVendettaStages': activeVendettaStages,
        'aggressionFactor': aggressionFactor,
      };

  factory DiplomacyTeamContext.fromJson(Map<String, dynamic> json) {
    return DiplomacyTeamContext(
      teamId: json['teamId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      gcPosition: (json['gcPosition'] as num?)?.toInt() ?? 99,
      gcGapToLeaderSeconds:
          (json['gcGapToLeaderSeconds'] as num?)?.toDouble() ?? 0.0,
      isRaceLeader: json['isRaceLeader'] as bool? ?? false,
      hasStageWinAmbition: json['hasStageWinAmbition'] as bool? ?? true,
      isInSameGroup: json['isInSameGroup'] as bool? ?? true,
      trustScore: (json['trustScore'] as num?)?.toDouble() ?? 65.0,
      activeVendettaStages:
          (json['activeVendettaStages'] as num?)?.toInt() ?? 0,
      aggressionFactor: (json['aggressionFactor'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// Aktywny lub historyczny pakt dyplomatyczny zawarty na trasie etapu.
class DiplomacyPact {
  final String pactId;
  final DiplomacyPactType type;
  final DiplomacyPactStatus status;
  final String initiatorTeamId;
  final String initiatorTeamName;
  final String initiatorRiderId;
  final String partnerTeamId;
  final String partnerTeamName;
  final String partnerRiderId;
  final double createdAtKm;
  final double expiresAtKm;
  final double cooperationBonusMultiplier;
  final bool blocksAttacks;
  final String? targetLeaderTeamId;
  final String? stageWinnerTeamId;
  final int consecutiveLowPullTicks;

  const DiplomacyPact({
    required this.pactId,
    required this.type,
    required this.status,
    required this.initiatorTeamId,
    required this.initiatorTeamName,
    required this.initiatorRiderId,
    required this.partnerTeamId,
    required this.partnerTeamName,
    required this.partnerRiderId,
    required this.createdAtKm,
    required this.expiresAtKm,
    this.cooperationBonusMultiplier = 1.25,
    this.blocksAttacks = false,
    this.targetLeaderTeamId,
    this.stageWinnerTeamId,
    this.consecutiveLowPullTicks = 0,
  });

  bool get isActive => status == DiplomacyPactStatus.active;

  DiplomacyPact copyWith({
    String? pactId,
    DiplomacyPactType? type,
    DiplomacyPactStatus? status,
    String? initiatorTeamId,
    String? initiatorTeamName,
    String? initiatorRiderId,
    String? partnerTeamId,
    String? partnerTeamName,
    String? partnerRiderId,
    double? createdAtKm,
    double? expiresAtKm,
    double? cooperationBonusMultiplier,
    bool? blocksAttacks,
    String? targetLeaderTeamId,
    String? stageWinnerTeamId,
    int? consecutiveLowPullTicks,
  }) {
    return DiplomacyPact(
      pactId: pactId ?? this.pactId,
      type: type ?? this.type,
      status: status ?? this.status,
      initiatorTeamId: initiatorTeamId ?? this.initiatorTeamId,
      initiatorTeamName: initiatorTeamName ?? this.initiatorTeamName,
      initiatorRiderId: initiatorRiderId ?? this.initiatorRiderId,
      partnerTeamId: partnerTeamId ?? this.partnerTeamId,
      partnerTeamName: partnerTeamName ?? this.partnerTeamName,
      partnerRiderId: partnerRiderId ?? this.partnerRiderId,
      createdAtKm: createdAtKm ?? this.createdAtKm,
      expiresAtKm: expiresAtKm ?? this.expiresAtKm,
      cooperationBonusMultiplier:
          cooperationBonusMultiplier ?? this.cooperationBonusMultiplier,
      blocksAttacks: blocksAttacks ?? this.blocksAttacks,
      targetLeaderTeamId: targetLeaderTeamId ?? this.targetLeaderTeamId,
      stageWinnerTeamId: stageWinnerTeamId ?? this.stageWinnerTeamId,
      consecutiveLowPullTicks:
          consecutiveLowPullTicks ?? this.consecutiveLowPullTicks,
    );
  }

  Map<String, dynamic> toJson() => {
        'pactId': pactId,
        'type': type.toJson(),
        'status': status.toJson(),
        'initiatorTeamId': initiatorTeamId,
        'initiatorTeamName': initiatorTeamName,
        'initiatorRiderId': initiatorRiderId,
        'partnerTeamId': partnerTeamId,
        'partnerTeamName': partnerTeamName,
        'partnerRiderId': partnerRiderId,
        'createdAtKm': createdAtKm,
        'expiresAtKm': expiresAtKm,
        'cooperationBonusMultiplier': cooperationBonusMultiplier,
        'blocksAttacks': blocksAttacks,
        'targetLeaderTeamId': targetLeaderTeamId,
        'stageWinnerTeamId': stageWinnerTeamId,
        'consecutiveLowPullTicks': consecutiveLowPullTicks,
      };

  factory DiplomacyPact.fromJson(Map<String, dynamic> json) {
    return DiplomacyPact(
      pactId: json['pactId'] as String? ?? '',
      type: DiplomacyPactType.fromJson(json['type'] as String? ?? ''),
      status: DiplomacyPactStatus.fromJson(json['status'] as String? ?? ''),
      initiatorTeamId: json['initiatorTeamId'] as String? ?? '',
      initiatorTeamName: json['initiatorTeamName'] as String? ?? '',
      initiatorRiderId: json['initiatorRiderId'] as String? ?? '',
      partnerTeamId: json['partnerTeamId'] as String? ?? '',
      partnerTeamName: json['partnerTeamName'] as String? ?? '',
      partnerRiderId: json['partnerRiderId'] as String? ?? '',
      createdAtKm: (json['createdAtKm'] as num?)?.toDouble() ?? 0.0,
      expiresAtKm: (json['expiresAtKm'] as num?)?.toDouble() ?? 0.0,
      cooperationBonusMultiplier:
          (json['cooperationBonusMultiplier'] as num?)?.toDouble() ?? 1.25,
      blocksAttacks: json['blocksAttacks'] as bool? ?? false,
      targetLeaderTeamId: json['targetLeaderTeamId'] as String?,
      stageWinnerTeamId: json['stageWinnerTeamId'] as String?,
      consecutiveLowPullTicks:
          (json['consecutiveLowPullTicks'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Zdarzenie zdrady paktu wraz z jej konsekwencjami sportowymi i reputacyjnymi.
class BetrayalEvent {
  final String pactId;
  final DiplomacyPactType pactType;
  final String betrayerTeamId;
  final String betrayerTeamName;
  final String victimTeamId;
  final String victimTeamName;
  final BetrayalReason reason;
  final BetrayalSeverity severity;
  final double occurredAtKm;

  /// Spadek zaufania u poszkodowanej ekipy (wartość ujemna).
  final double victimTrustDelta;

  /// Spadek ogólnej reputacji dyplomatycznej w peletonie (wartość ujemna).
  final double pelotonReputationDelta;

  /// Liczba etapów, przez które poszkodowana ekipa odmawia współpracy i ściga zdrajcę.
  final int vendettaStagesAssigned;

  /// Mnożnik agresji pościgu rywali wobec zdrajcy po zdradzie.
  final double rivalChaseAggressionBoost;

  /// Komunikat radia / mediów po zdradzie.
  final String radioHeadline;

  const BetrayalEvent({
    required this.pactId,
    required this.pactType,
    required this.betrayerTeamId,
    required this.betrayerTeamName,
    required this.victimTeamId,
    required this.victimTeamName,
    required this.reason,
    required this.severity,
    required this.occurredAtKm,
    required this.victimTrustDelta,
    required this.pelotonReputationDelta,
    required this.vendettaStagesAssigned,
    required this.rivalChaseAggressionBoost,
    required this.radioHeadline,
  });

  Map<String, dynamic> toJson() => {
        'pactId': pactId,
        'pactType': pactType.toJson(),
        'betrayerTeamId': betrayerTeamId,
        'betrayerTeamName': betrayerTeamName,
        'victimTeamId': victimTeamId,
        'victimTeamName': victimTeamName,
        'reason': reason.toJson(),
        'severity': severity.toJson(),
        'occurredAtKm': occurredAtKm,
        'victimTrustDelta': victimTrustDelta,
        'pelotonReputationDelta': pelotonReputationDelta,
        'vendettaStagesAssigned': vendettaStagesAssigned,
        'rivalChaseAggressionBoost': rivalChaseAggressionBoost,
        'radioHeadline': radioHeadline,
      };

  factory BetrayalEvent.fromJson(Map<String, dynamic> json) {
    return BetrayalEvent(
      pactId: json['pactId'] as String? ?? '',
      pactType: DiplomacyPactType.fromJson(json['pactType'] as String? ?? ''),
      betrayerTeamId: json['betrayerTeamId'] as String? ?? '',
      betrayerTeamName: json['betrayerTeamName'] as String? ?? '',
      victimTeamId: json['victimTeamId'] as String? ?? '',
      victimTeamName: json['victimTeamName'] as String? ?? '',
      reason: BetrayalReason.fromJson(json['reason'] as String? ?? ''),
      severity: BetrayalSeverity.fromJson(json['severity'] as String? ?? ''),
      occurredAtKm: (json['occurredAtKm'] as num?)?.toDouble() ?? 0.0,
      victimTrustDelta: (json['victimTrustDelta'] as num?)?.toDouble() ?? -30.0,
      pelotonReputationDelta:
          (json['pelotonReputationDelta'] as num?)?.toDouble() ?? -15.0,
      vendettaStagesAssigned:
          (json['vendettaStagesAssigned'] as num?)?.toInt() ?? 3,
      rivalChaseAggressionBoost:
          (json['rivalChaseAggressionBoost'] as num?)?.toDouble() ?? 1.4,
      radioHeadline: json['radioHeadline'] as String? ?? '',
    );
  }
}

/// Wynik oceny propozycji paktu dyplomatycznego na szosie.
class PactProposalOutcome {
  final bool accepted;
  final double acceptanceScore;
  final DiplomacyPact? createdPact;
  final String rationale;
  final String radioMessage;

  const PactProposalOutcome({
    required this.accepted,
    required this.acceptanceScore,
    required this.createdPact,
    required this.rationale,
    required this.radioMessage,
  });
}

/// Obserwowana akcja kolarza w trakcie kroku symulacji służąca do weryfikacji paktów.
class RiderDiplomacyActionObservation {
  final String riderId;
  final String teamId;
  final bool didAttackThisStep;
  final bool didSprintForStageFinish;
  final double pullEffortRatio;

  const RiderDiplomacyActionObservation({
    required this.riderId,
    required this.teamId,
    this.didAttackThisStep = false,
    this.didSprintForStageFinish = false,
    this.pullEffortRatio = 1.0,
  });
}

/// Modyfikatory taktyczne wynikające z aktywnej dyplomacji dla pojedynczej ekipy.
class TeamDiplomacyModifiers {
  final String teamId;
  final double pullCooperationMultiplier;
  final bool attacksSuppressed;
  final bool antiLeaderChaseBoostActive;
  final double rivalChaseHostilityMultiplier;
  final bool refusesCooperationWithPlayer;

  const TeamDiplomacyModifiers({
    required this.teamId,
    this.pullCooperationMultiplier = 1.0,
    this.attacksSuppressed = false,
    this.antiLeaderChaseBoostActive = false,
    this.rivalChaseHostilityMultiplier = 1.0,
    this.refusesCooperationWithPlayer = false,
  });
}

/// Pełny stan systemu dyplomacji peletonu (serializowalny między etapami).
class PelotonDiplomacyState {
  final double playerPelotonReputation;
  final Map<String, double> teamTrustScores;
  final Map<String, int> vendettaStagesByTeam;
  final List<DiplomacyPact> activePacts;
  final List<DiplomacyPact> historicalPacts;
  final List<BetrayalEvent> betrayalHistory;
  final BetrayalEvent? latestBetrayalAlert;
  final String latestRadioFeed;

  const PelotonDiplomacyState({
    this.playerPelotonReputation = 72.0,
    this.teamTrustScores = const {},
    this.vendettaStagesByTeam = const {},
    this.activePacts = const [],
    this.historicalPacts = const [],
    this.betrayalHistory = const [],
    this.latestBetrayalAlert,
    this.latestRadioFeed = 'Brak aktywnych negocjacji na szosie.',
  });

  double trustForTeam(String teamId) => teamTrustScores[teamId] ?? 65.0;

  int vendettaForTeam(String teamId) => vendettaStagesByTeam[teamId] ?? 0;

  bool isTeamHostile(String teamId) =>
      vendettaForTeam(teamId) > 0 || trustForTeam(teamId) < 30.0;

  PelotonDiplomacyState copyWith({
    double? playerPelotonReputation,
    Map<String, double>? teamTrustScores,
    Map<String, int>? vendettaStagesByTeam,
    List<DiplomacyPact>? activePacts,
    List<DiplomacyPact>? historicalPacts,
    List<BetrayalEvent>? betrayalHistory,
    BetrayalEvent? latestBetrayalAlert,
    bool clearLatestBetrayalAlert = false,
    String? latestRadioFeed,
  }) {
    return PelotonDiplomacyState(
      playerPelotonReputation:
          playerPelotonReputation ?? this.playerPelotonReputation,
      teamTrustScores: teamTrustScores ?? this.teamTrustScores,
      vendettaStagesByTeam: vendettaStagesByTeam ?? this.vendettaStagesByTeam,
      activePacts: activePacts ?? this.activePacts,
      historicalPacts: historicalPacts ?? this.historicalPacts,
      betrayalHistory: betrayalHistory ?? this.betrayalHistory,
      latestBetrayalAlert: clearLatestBetrayalAlert
          ? null
          : (latestBetrayalAlert ?? this.latestBetrayalAlert),
      latestRadioFeed: latestRadioFeed ?? this.latestRadioFeed,
    );
  }

  Map<String, dynamic> toJson() => {
        'playerPelotonReputation': playerPelotonReputation,
        'teamTrustScores': teamTrustScores,
        'vendettaStagesByTeam': vendettaStagesByTeam,
        'activePacts': activePacts.map((p) => p.toJson()).toList(),
        'historicalPacts': historicalPacts.map((p) => p.toJson()).toList(),
        'betrayalHistory': betrayalHistory.map((b) => b.toJson()).toList(),
        'latestBetrayalAlert': latestBetrayalAlert?.toJson(),
        'latestRadioFeed': latestRadioFeed,
      };

  factory PelotonDiplomacyState.fromJson(Map<String, dynamic> json) {
    final rawTrust = json['teamTrustScores'] as Map<String, dynamic>? ?? {};
    final rawVendetta =
        json['vendettaStagesByTeam'] as Map<String, dynamic>? ?? {};
    return PelotonDiplomacyState(
      playerPelotonReputation:
          (json['playerPelotonReputation'] as num?)?.toDouble() ?? 72.0,
      teamTrustScores: rawTrust.map(
        (k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 65.0),
      ),
      vendettaStagesByTeam: rawVendetta.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      ),
      activePacts: (json['activePacts'] as List<dynamic>? ?? [])
          .map((e) => DiplomacyPact.fromJson(e as Map<String, dynamic>))
          .toList(),
      historicalPacts: (json['historicalPacts'] as List<dynamic>? ?? [])
          .map((e) => DiplomacyPact.fromJson(e as Map<String, dynamic>))
          .toList(),
      betrayalHistory: (json['betrayalHistory'] as List<dynamic>? ?? [])
          .map((e) => BetrayalEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestBetrayalAlert: json['latestBetrayalAlert'] != null
          ? BetrayalEvent.fromJson(
              json['latestBetrayalAlert'] as Map<String, dynamic>,
            )
          : null,
      latestRadioFeed: json['latestRadioFeed'] as String? ??
          'Brak aktywnych negocjacji na szosie.',
    );
  }
}

/// Wynik pojedynczego kroku symulacji dyplomacji peletonu.
class DiplomacyStepResult {
  final PelotonDiplomacyState nextState;
  final Map<String, TeamDiplomacyModifiers> modifiersByTeam;
  final List<BetrayalEvent> newBetrayals;
  final List<DiplomacyPact> newlyResolvedPacts;

  const DiplomacyStepResult({
    required this.nextState,
    required this.modifiersByTeam,
    this.newBetrayals = const [],
    this.newlyResolvedPacts = const [],
  });
}

/// Silnik Dyplomacji i Sojuszy na Szosie (`InRacePelotonDiplomacyEngine`).
///
/// Obsługuje negocjowanie paktów (`Stage for GC Deal`, `Anti-Leader Coalition`,
/// `Neutralization Truce`), egzekwowanie współpracy, wykrywanie zdrad
/// (`Betrayal!`) oraz długofalowe konsekwencje reputacyjne i wendety.
class InRacePelotonDiplomacyEngine {
  static const double minTrustToNegotiate = 25.0;
  static const double maxReputation = 100.0;
  static const double minReputation = 0.0;

  /// Ocenia i opcjonalnie zawiera pakt między inicjatorem a partnerem.
  static ({
    PactProposalOutcome outcome,
    PelotonDiplomacyState nextState,
  }) proposePact({
    required PelotonDiplomacyState state,
    required DiplomacyPactType type,
    required DiplomacyTeamContext initiator,
    required DiplomacyTeamContext partner,
    required double currentStageKm,
    required double totalStageKm,
    String? targetLeaderTeamId,
    bool isCrashOrHazardNeutralization = false,
  }) {
    if (initiator.teamId == partner.teamId) {
      return (
        outcome: const PactProposalOutcome(
          accepted: false,
          acceptanceScore: 0.0,
          createdPact: null,
          rationale: 'Nie można zawrzeć paktu wewnątrz własnej drużyny.',
          radioMessage: 'RADIO: Wybierz rywala z innej ekipy do negocjacji.',
        ),
        nextState: state,
      );
    }

    if (!partner.isInSameGroup) {
      return (
        outcome: PactProposalOutcome(
          accepted: false,
          acceptanceScore: 0.0,
          createdPact: null,
          rationale: '${partner.riderName} nie jedzie w tej samej grupie.',
          radioMessage:
              'RADIO: Brak kontaktu wzrokowego z ${partner.riderName} na szosie.',
        ),
        nextState: state,
      );
    }

    final bool alreadyHasSamePact = state.activePacts.any(
      (p) =>
          p.isActive &&
          p.type == type &&
          ((p.initiatorTeamId == initiator.teamId &&
                  p.partnerTeamId == partner.teamId) ||
              (p.initiatorTeamId == partner.teamId &&
                  p.partnerTeamId == initiator.teamId)),
    );
    if (alreadyHasSamePact) {
      return (
        outcome: PactProposalOutcome(
          accepted: false,
          acceptanceScore: 0.0,
          createdPact: null,
          rationale:
              'Taki pakt z ekipą ${partner.teamName} jest już aktywny.',
          radioMessage:
              'RADIO: ${partner.teamName} potwierdza, że układ nadal obowiązuje.',
        ),
        nextState: state,
      );
    }

    final double currentTrust = state.trustForTeam(partner.teamId);
    final int vendetta = state.vendettaForTeam(partner.teamId);

    // Aktywna wendeta blokuje pakty poza wyjątkowym rozejmem po kraksie.
    if (vendetta > 0 &&
        !(type == DiplomacyPactType.neutralizationTruce &&
            isCrashOrHazardNeutralization)) {
      final msg =
          'RADIO (${partner.teamName}): "Po tym, co zrobiliście, nie rozmawiamy!" '
          '(Wendeta: $vendetta et.)';
      return (
        outcome: PactProposalOutcome(
          accepted: false,
          acceptanceScore: 0.0,
          createdPact: null,
          rationale:
              'Aktywna wendeta po wcześniejszej zdradzie ($vendetta et.).',
          radioMessage: msg,
        ),
        nextState: state.copyWith(latestRadioFeed: msg),
      );
    }

    if (currentTrust < minTrustToNegotiate &&
        type != DiplomacyPactType.neutralizationTruce) {
      final msg =
          'RADIO (${partner.teamName}): Brak zaufania (${currentTrust.toStringAsFixed(0)}/100) — odrzucono.';
      return (
        outcome: PactProposalOutcome(
          accepted: false,
          acceptanceScore: currentTrust / 100.0,
          createdPact: null,
          rationale: 'Zbyt niskie zaufanie partnera do drużyny gracza.',
          radioMessage: msg,
        ),
        nextState: state.copyWith(latestRadioFeed: msg),
      );
    }

    final double kmRemaining = math.max(0.5, totalStageKm - currentStageKm);
    final double score = _computeAcceptanceScore(
      type: type,
      initiator: initiator,
      partner: partner,
      trustScore: currentTrust,
      pelotonReputation: state.playerPelotonReputation,
      kmRemaining: kmRemaining,
      isCrashOrHazardNeutralization: isCrashOrHazardNeutralization,
    );

    if (score < 0.50) {
      final String reason = _rejectionRationale(type, partner, kmRemaining);
      final String radio =
          'RADIO (${partner.teamName}): Odrzucono ${type.displayName} — $reason';
      return (
        outcome: PactProposalOutcome(
          accepted: false,
          acceptanceScore: score,
          createdPact: null,
          rationale: reason,
          radioMessage: radio,
        ),
        nextState: state.copyWith(latestRadioFeed: radio),
      );
    }

    final double durationKm = switch (type) {
      DiplomacyPactType.stageForGcDeal => kmRemaining,
      DiplomacyPactType.antiLeaderCoalition => math.min(kmRemaining, 35.0),
      DiplomacyPactType.neutralizationTruce =>
        isCrashOrHazardNeutralization ? math.min(kmRemaining, 12.0) : math.min(kmRemaining, 18.0),
    };

    final String pactId =
        '${type.name}_${initiator.teamId}_${partner.teamId}_${currentStageKm.toStringAsFixed(1)}';
    final DiplomacyPact newPact = DiplomacyPact(
      pactId: pactId,
      type: type,
      status: DiplomacyPactStatus.active,
      initiatorTeamId: initiator.teamId,
      initiatorTeamName: initiator.teamName,
      initiatorRiderId: initiator.riderId,
      partnerTeamId: partner.teamId,
      partnerTeamName: partner.teamName,
      partnerRiderId: partner.riderId,
      createdAtKm: currentStageKm,
      expiresAtKm: math.min(totalStageKm, currentStageKm + durationKm),
      cooperationBonusMultiplier: switch (type) {
        DiplomacyPactType.stageForGcDeal => 1.38,
        DiplomacyPactType.antiLeaderCoalition => 1.32,
        DiplomacyPactType.neutralizationTruce => 1.0,
      },
      blocksAttacks: type == DiplomacyPactType.neutralizationTruce,
      targetLeaderTeamId:
          type == DiplomacyPactType.antiLeaderCoalition ? targetLeaderTeamId : null,
      stageWinnerTeamId:
          type == DiplomacyPactType.stageForGcDeal ? partner.teamId : null,
    );

    final String radio =
        'RADIO (${currentStageKm.toStringAsFixed(1)} km): Zawarto ${type.displayName} '
        'z ${partner.riderName} (${partner.teamName})!';

    final nextState = state.copyWith(
      activePacts: [...state.activePacts, newPact],
      latestRadioFeed: radio,
    );

    return (
      outcome: PactProposalOutcome(
        accepted: true,
        acceptanceScore: score,
        createdPact: newPact,
        rationale: 'Warunki korzystne dla obu stron na tym odcinku etapu.',
        radioMessage: radio,
      ),
      nextState: nextState,
    );
  }

  /// Aktualizuje aktywne pakty w trakcie kroku symulacji, wykrywa zdrady
  /// oraz wylicza modyfikatory współpracy i agresji dla drużyn.
  static DiplomacyStepResult stepDiplomacy({
    required PelotonDiplomacyState state,
    required double currentStageKm,
    required double totalStageKm,
    required List<RiderDiplomacyActionObservation> observations,
  }) {
    final Map<String, RiderDiplomacyActionObservation> byRider = {
      for (final obs in observations) obs.riderId: obs,
    };

    final double kmToFinish = math.max(0.0, totalStageKm - currentStageKm);
    final List<DiplomacyPact> stillActive = [];
    final List<DiplomacyPact> resolved = [];
    final List<BetrayalEvent> newBetrayals = [];

    PelotonDiplomacyState workingState = state;

    for (final pact in state.activePacts) {
      if (!pact.isActive) {
        resolved.add(pact);
        continue;
      }

      final obsInitiator = byRider[pact.initiatorRiderId];
      final obsPartner = byRider[pact.partnerRiderId];

      // 1. Sprawdzenie zdrady ze strony inicjatora (lub partnera).
      final _BetrayalCheckResult? breach = _detectBreach(
        pact: pact,
        obsInitiator: obsInitiator,
        obsPartner: obsPartner,
        kmToFinish: kmToFinish,
      );

      if (breach != null) {
        final betrayedPact =
            pact.copyWith(status: DiplomacyPactStatus.betrayed);
        resolved.add(betrayedPact);

        final betrayal = _buildBetrayalEvent(
          pact: betrayedPact,
          betrayerTeamId: breach.betrayerTeamId,
          betrayerTeamName: breach.betrayerTeamName,
          victimTeamId: breach.victimTeamId,
          victimTeamName: breach.victimTeamName,
          reason: breach.reason,
          currentStageKm: currentStageKm,
        );
        newBetrayals.add(betrayal);
        workingState = _applyBetrayalConsequences(workingState, betrayal);
        continue;
      }

      // 2. Aktualizacja licznika niskich zmian (ostrzeżenie przed zdradą).
      int lowPullTicks = pact.consecutiveLowPullTicks;
      if (pact.type != DiplomacyPactType.neutralizationTruce &&
          obsInitiator != null &&
          obsInitiator.pullEffortRatio < 0.25) {
        lowPullTicks += 1;
      } else {
        lowPullTicks = 0;
      }

      // 3. Naturalne zakończenie lub dotrzymanie paktu.
      final bool reachedFinish = kmToFinish <= 0.05;
      final bool reachedExpiryKm = currentStageKm >= pact.expiresAtKm;

      if (reachedFinish || reachedExpiryKm) {
        final finalStatus = reachedFinish ||
                pact.type == DiplomacyPactType.neutralizationTruce ||
                pact.type == DiplomacyPactType.antiLeaderCoalition
            ? DiplomacyPactStatus.fulfilled
            : DiplomacyPactStatus.expired;
        final donePact = pact.copyWith(
          status: finalStatus,
          consecutiveLowPullTicks: lowPullTicks,
        );
        resolved.add(donePact);

        if (finalStatus == DiplomacyPactStatus.fulfilled) {
          workingState = _applyFulfilledBonus(workingState, donePact);
        }
        continue;
      }

      stillActive.add(
        pact.copyWith(consecutiveLowPullTicks: lowPullTicks),
      );
    }

    final updatedState = workingState.copyWith(
      activePacts: stillActive,
      historicalPacts: [...workingState.historicalPacts, ...resolved],
      betrayalHistory: [...workingState.betrayalHistory, ...newBetrayals],
      latestBetrayalAlert: newBetrayals.isNotEmpty
          ? newBetrayals.last
          : workingState.latestBetrayalAlert,
      latestRadioFeed: newBetrayals.isNotEmpty
          ? newBetrayals.last.radioHeadline
          : workingState.latestRadioFeed,
    );

    final modifiers = _computeTeamModifiers(
      state: updatedState,
      observations: observations,
    );

    return DiplomacyStepResult(
      nextState: updatedState,
      modifiersByTeam: modifiers,
      newBetrayals: newBetrayals,
      newlyResolvedPacts: resolved,
    );
  }

  /// Ręczne zerwanie aktywnego paktu przez gracza/ekipę ("Betrayal!").
  static ({
    BetrayalEvent event,
    PelotonDiplomacyState nextState,
  }) triggerManualBetrayal({
    required PelotonDiplomacyState state,
    required String pactId,
    required String betrayerTeamId,
    required double currentStageKm,
    BetrayalReason reason = BetrayalReason.manualPactBreach,
  }) {
    final pactIndex = state.activePacts.indexWhere((p) => p.pactId == pactId);
    if (pactIndex == -1) {
      throw ArgumentError('Nie znaleziono aktywnego paktu o ID: $pactId');
    }

    final pact = state.activePacts[pactIndex];
    final bool initiatorIsBetrayer = pact.initiatorTeamId == betrayerTeamId;
    final String betrayerName = initiatorIsBetrayer
        ? pact.initiatorTeamName
        : pact.partnerTeamName;
    final String victimId =
        initiatorIsBetrayer ? pact.partnerTeamId : pact.initiatorTeamId;
    final String victimName =
        initiatorIsBetrayer ? pact.partnerTeamName : pact.initiatorTeamName;

    final betrayedPact = pact.copyWith(status: DiplomacyPactStatus.betrayed);
    final betrayal = _buildBetrayalEvent(
      pact: betrayedPact,
      betrayerTeamId: betrayerTeamId,
      betrayerTeamName: betrayerName,
      victimTeamId: victimId,
      victimTeamName: victimName,
      reason: reason,
      currentStageKm: currentStageKm,
    );

    final remainingActive = [...state.activePacts]..removeAt(pactIndex);
    final updated = _applyBetrayalConsequences(state, betrayal).copyWith(
      activePacts: remainingActive,
      historicalPacts: [...state.historicalPacts, betrayedPact],
      betrayalHistory: [...state.betrayalHistory, betrayal],
      latestBetrayalAlert: betrayal,
      latestRadioFeed: betrayal.radioHeadline,
    );

    return (event: betrayal, nextState: updated);
  }

  /// Międzyetapowe wygaszanie wendet i powolna odbudowa zaufania.
  static PelotonDiplomacyState decayVendettasBetweenStages(
    PelotonDiplomacyState state,
  ) {
    final nextVendettas = <String, int>{};
    for (final entry in state.vendettaStagesByTeam.entries) {
      final remaining = entry.value - 1;
      if (remaining > 0) {
        nextVendettas[entry.key] = remaining;
      }
    }

    final nextTrust = <String, double>{};
    for (final entry in state.teamTrustScores.entries) {
      final hasVendetta = (nextVendettas[entry.key] ?? 0) > 0;
      final recovery = hasVendetta ? 1.5 : 3.5;
      final adjusted = entry.value < 60.0
          ? math.min(60.0, entry.value + recovery)
          : entry.value;
      nextTrust[entry.key] = adjusted;
    }

    return state.copyWith(
      vendettaStagesByTeam: nextVendettas,
      teamTrustScores: nextTrust,
      activePacts: const [],
      clearLatestBetrayalAlert: true,
    );
  }

  static double _computeAcceptanceScore({
    required DiplomacyPactType type,
    required DiplomacyTeamContext initiator,
    required DiplomacyTeamContext partner,
    required double trustScore,
    required double pelotonReputation,
    required double kmRemaining,
    required bool isCrashOrHazardNeutralization,
  }) {
    final double trustFactor = (trustScore / 100.0).clamp(0.0, 1.0);
    final double repFactor = (pelotonReputation / 100.0).clamp(0.0, 1.0);

    switch (type) {
      case DiplomacyPactType.stageForGcDeal:
        // Bliski rywal GC (Top 10 i < 3 min straty) nie pomoże konkurentowi w walce o generalkę.
        if (partner.gcPosition <= 10 && partner.gcGapToLeaderSeconds <= 180.0) {
          return 0.12;
        }
        // Partner bez realnych szans na podium GC chętnie odda pomoc za wygraną etapową.
        final double partnerNotGcThreat =
            partner.gcGapToLeaderSeconds > 180.0 ? 0.35 : 0.05;
        final double initiatorNeedsGc =
            initiator.gcPosition <= 10 ? 0.25 : 0.08;
        final double stageHunger = partner.hasStageWinAmbition ? 0.20 : 0.05;
        return (trustFactor * 0.25 +
                repFactor * 0.10 +
                partnerNotGcThreat +
                initiatorNeedsGc +
                stageHunger)
            .clamp(0.0, 1.0);

      case DiplomacyPactType.antiLeaderCoalition:
        if (partner.isRaceLeader) return 0.0;
        final double gapMotivation =
            partner.gcGapToLeaderSeconds > 10.0 &&
                    partner.gcGapToLeaderSeconds < 360.0
                ? 0.35
                : 0.15;
        final double aggro = partner.aggressionFactor * 0.25;
        final double timing = kmRemaining <= 65.0 ? 0.20 : 0.08;
        return (trustFactor * 0.20 +
                repFactor * 0.10 +
                gapMotivation +
                aggro +
                timing)
            .clamp(0.0, 1.0);

      case DiplomacyPactType.neutralizationTruce:
        final double safetyNeed = isCrashOrHazardNeutralization ? 0.55 : 0.22;
        final double diplomacyWeight = trustFactor * 0.25 + repFactor * 0.15;
        return (safetyNeed + diplomacyWeight).clamp(0.0, 1.0);
    }
  }

  static String _rejectionRationale(
    DiplomacyPactType type,
    DiplomacyTeamContext partner,
    double kmRemaining,
  ) {
    switch (type) {
      case DiplomacyPactType.stageForGcDeal:
        if (partner.gcGapToLeaderSeconds <= 180.0) {
          return '${partner.riderName} sam walczy o wysokie miejsce w GC.';
        }
        return 'Ekipa ${partner.teamName} nie widzi wystarczającej korzyści.';
      case DiplomacyPactType.antiLeaderCoalition:
        if (partner.isRaceLeader) {
          return 'Lider wyścigu nie dołączy do koalicji przeciwko sobie!';
        }
        if (kmRemaining > 65.0) {
          return 'Za daleko do mety na otwartą koalicję (${kmRemaining.toStringAsFixed(0)} km).';
        }
        return '${partner.teamName} woli zachować siły własnego lidera.';
      case DiplomacyPactType.neutralizationTruce:
        return '${partner.teamName} chce utrzymać presję i tempo w grupie.';
    }
  }

  static _BetrayalCheckResult? _detectBreach({
    required DiplomacyPact pact,
    required RiderDiplomacyActionObservation? obsInitiator,
    required RiderDiplomacyActionObservation? obsPartner,
    required double kmToFinish,
  }) {
    // Atak podczas rozejmu neutralizacyjnego.
    if (pact.type == DiplomacyPactType.neutralizationTruce) {
      if (obsInitiator != null && obsInitiator.didAttackThisStep) {
        return _BetrayalCheckResult(
          betrayerTeamId: pact.initiatorTeamId,
          betrayerTeamName: pact.initiatorTeamName,
          victimTeamId: pact.partnerTeamId,
          victimTeamName: pact.partnerTeamName,
          reason: BetrayalReason.attackedDuringTruce,
        );
      }
      if (obsPartner != null && obsPartner.didAttackThisStep) {
        return _BetrayalCheckResult(
          betrayerTeamId: pact.partnerTeamId,
          betrayerTeamName: pact.partnerTeamName,
          victimTeamId: pact.initiatorTeamId,
          victimTeamName: pact.initiatorTeamName,
          reason: BetrayalReason.attackedDuringTruce,
        );
      }
    }

    // Złamanie układu Stage for GC Deal: walka o finisz przez beneficjenta GC.
    if (pact.type == DiplomacyPactType.stageForGcDeal &&
        kmToFinish <= 1.2 &&
        obsInitiator != null &&
        obsInitiator.didSprintForStageFinish) {
      return _BetrayalCheckResult(
        betrayerTeamId: pact.initiatorTeamId,
        betrayerTeamName: pact.initiatorTeamName,
        victimTeamId: pact.partnerTeamId,
        victimTeamName: pact.partnerTeamName,
        reason: BetrayalReason.sprintedForPromisedStage,
      );
    }

    // Długotrwałe unikanie zmian w Stage for GC Deal lub Anti-Leader Coalition.
    if (pact.type != DiplomacyPactType.neutralizationTruce &&
        obsInitiator != null &&
        obsInitiator.pullEffortRatio < 0.25 &&
        pact.consecutiveLowPullTicks >= 2) {
      return _BetrayalCheckResult(
        betrayerTeamId: pact.initiatorTeamId,
        betrayerTeamName: pact.initiatorTeamName,
        victimTeamId: pact.partnerTeamId,
        victimTeamName: pact.partnerTeamName,
        reason: pact.type == DiplomacyPactType.antiLeaderCoalition
            ? BetrayalReason.sabotagedCoalition
            : BetrayalReason.refusedAgreedPulls,
      );
    }

    return null;
  }

  static BetrayalEvent _buildBetrayalEvent({
    required DiplomacyPact pact,
    required String betrayerTeamId,
    required String betrayerTeamName,
    required String victimTeamId,
    required String victimTeamName,
    required BetrayalReason reason,
    required double currentStageKm,
  }) {
    final BetrayalSeverity severity = switch (reason) {
      BetrayalReason.attackedDuringTruce => BetrayalSeverity.infamous,
      BetrayalReason.sprintedForPromisedStage => BetrayalSeverity.infamous,
      BetrayalReason.sabotagedCoalition => BetrayalSeverity.severe,
      BetrayalReason.manualPactBreach => BetrayalSeverity.severe,
      BetrayalReason.refusedAgreedPulls => BetrayalSeverity.moderate,
    };

    final double trustDelta = switch (severity) {
      BetrayalSeverity.moderate => -24.0,
      BetrayalSeverity.severe => -36.0,
      BetrayalSeverity.infamous => -48.0,
    };
    final double repDelta = switch (severity) {
      BetrayalSeverity.moderate => -10.0,
      BetrayalSeverity.severe => -18.0,
      BetrayalSeverity.infamous => -26.0,
    };
    final int vendettaStages = switch (severity) {
      BetrayalSeverity.moderate => 2,
      BetrayalSeverity.severe => 4,
      BetrayalSeverity.infamous => 6,
    };
    final double chaseBoost = switch (severity) {
      BetrayalSeverity.moderate => 1.25,
      BetrayalSeverity.severe => 1.42,
      BetrayalSeverity.infamous => 1.60,
    };

    final String headline =
        'BETRAYAL! (${currentStageKm.toStringAsFixed(1)} km): $betrayerTeamName '
        'złamał ${pact.type.displayName} (${reason.label}) przeciwko $victimTeamName! '
        'Wendeta na $vendettaStages et.';

    return BetrayalEvent(
      pactId: pact.pactId,
      pactType: pact.type,
      betrayerTeamId: betrayerTeamId,
      betrayerTeamName: betrayerTeamName,
      victimTeamId: victimTeamId,
      victimTeamName: victimTeamName,
      reason: reason,
      severity: severity,
      occurredAtKm: currentStageKm,
      victimTrustDelta: trustDelta,
      pelotonReputationDelta: repDelta,
      vendettaStagesAssigned: vendettaStages,
      rivalChaseAggressionBoost: chaseBoost,
      radioHeadline: headline,
    );
  }

  static PelotonDiplomacyState _applyBetrayalConsequences(
    PelotonDiplomacyState state,
    BetrayalEvent event,
  ) {
    final nextTrust = Map<String, double>.from(state.teamTrustScores);
    final oldTrust = nextTrust[event.victimTeamId] ?? 65.0;
    nextTrust[event.victimTeamId] =
        (oldTrust + event.victimTrustDelta).clamp(0.0, 100.0);

    // Inne ekipy w peletonie również tracą część zaufania po głośnej zdradzie.
    for (final key in nextTrust.keys.toList()) {
      if (key != event.victimTeamId) {
        nextTrust[key] =
            (nextTrust[key]! + event.pelotonReputationDelta * 0.35)
                .clamp(0.0, 100.0);
      }
    }

    final nextVendettas = Map<String, int>.from(state.vendettaStagesByTeam);
    nextVendettas[event.victimTeamId] = math.max(
      nextVendettas[event.victimTeamId] ?? 0,
      event.vendettaStagesAssigned,
    );

    final nextRep =
        (state.playerPelotonReputation + event.pelotonReputationDelta)
            .clamp(minReputation, maxReputation);

    return state.copyWith(
      playerPelotonReputation: nextRep,
      teamTrustScores: nextTrust,
      vendettaStagesByTeam: nextVendettas,
    );
  }

  static PelotonDiplomacyState _applyFulfilledBonus(
    PelotonDiplomacyState state,
    DiplomacyPact pact,
  ) {
    final nextTrust = Map<String, double>.from(state.teamTrustScores);
    final oldTrust = nextTrust[pact.partnerTeamId] ?? 65.0;
    nextTrust[pact.partnerTeamId] = (oldTrust + 9.0).clamp(0.0, 100.0);

    final nextRep = (state.playerPelotonReputation + 4.5)
        .clamp(minReputation, maxReputation);

    return state.copyWith(
      playerPelotonReputation: nextRep,
      teamTrustScores: nextTrust,
      latestRadioFeed:
          'RADIO: Pakt ${pact.type.displayName} z ${pact.partnerTeamName} dotrzymany (+9 zaufania).',
    );
  }

  static Map<String, TeamDiplomacyModifiers> _computeTeamModifiers({
    required PelotonDiplomacyState state,
    required List<RiderDiplomacyActionObservation> observations,
  }) {
    final teamIds = <String>{
      for (final o in observations) o.teamId,
      for (final p in state.activePacts) p.initiatorTeamId,
      for (final p in state.activePacts) p.partnerTeamId,
      ...state.vendettaStagesByTeam.keys,
    };

    final result = <String, TeamDiplomacyModifiers>{};
    for (final teamId in teamIds) {
      double pullMult = 1.0;
      bool suppressAttacks = false;
      bool antiLeaderBoost = false;
      double chaseHostility = 1.0;
      final bool hostile = state.isTeamHostile(teamId);

      for (final pact in state.activePacts) {
        if (!pact.isActive) continue;
        final bool involvesTeam =
            pact.initiatorTeamId == teamId || pact.partnerTeamId == teamId;
        if (!involvesTeam) continue;

        pullMult = math.max(pullMult, pact.cooperationBonusMultiplier);
        if (pact.blocksAttacks) {
          suppressAttacks = true;
        }
        if (pact.type == DiplomacyPactType.antiLeaderCoalition) {
          antiLeaderBoost = true;
        }
      }

      if (hostile) {
        chaseHostility = 1.45;
      }

      result[teamId] = TeamDiplomacyModifiers(
        teamId: teamId,
        pullCooperationMultiplier: pullMult,
        attacksSuppressed: suppressAttacks,
        antiLeaderChaseBoostActive: antiLeaderBoost,
        rivalChaseHostilityMultiplier: chaseHostility,
        refusesCooperationWithPlayer: hostile,
      );
    }

    return result;
  }
}

class _BetrayalCheckResult {
  final String betrayerTeamId;
  final String betrayerTeamName;
  final String victimTeamId;
  final String victimTeamName;
  final BetrayalReason reason;

  const _BetrayalCheckResult({
    required this.betrayerTeamId,
    required this.betrayerTeamName,
    required this.victimTeamId,
    required this.victimTeamName,
    required this.reason,
  });
}

/// Panel taktyczny Dyplomacji i Sojuszy na Szosie (`InRacePelotonDiplomacyPanel`).
///
/// Obsługuje responsywnie `390x844`, `1024x768` i `1600x900` przez [LayoutBuilder],
/// stosuje paletę [AppColors], typografię `Inter` oraz pełne stany
/// `hover`, `active`, `disabled` i `focus` na elementach sterujących.
class InRacePelotonDiplomacyPanel extends StatelessWidget {
  final PelotonDiplomacyState diplomacyState;
  final List<DiplomacyTeamContext> rivalCandidates;
  final String? selectedPartnerTeamId;
  final double currentStageKm;
  final ValueChanged<String>? onSelectPartnerTeam;
  final ValueChanged<DiplomacyPactType>? onProposePact;
  final ValueChanged<String>? onBetrayPact;
  final bool isInteractiveEnabled;

  const InRacePelotonDiplomacyPanel({
    super.key,
    required this.diplomacyState,
    required this.rivalCandidates,
    this.selectedPartnerTeamId,
    this.currentStageKm = 0.0,
    this.onSelectPartnerTeam,
    this.onProposePact,
    this.onBetrayPact,
    this.isInteractiveEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        final bool isWide = constraints.maxWidth >= 960;
        final bool hasBetrayal = diplomacyState.latestBetrayalAlert != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasBetrayal
                  ? AppColors.crimsonAlert.withValues(alpha: 0.85)
                  : const Color(0xFF2A2F3D),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact: isCompact),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                child: hasBetrayal
                    ? _buildBetrayalBanner(
                        diplomacyState.latestBetrayalAlert!,
                        key: ValueKey(
                          diplomacyState.latestBetrayalAlert!.pactId,
                        ),
                      )
                    : _buildRadioFeedBanner(
                        key: ValueKey(diplomacyState.latestRadioFeed),
                      ),
              ),
              const SizedBox(height: 14),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildNegotiationSection(isCompact: isCompact),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _buildActivePactsSection(isCompact: isCompact),
                    ),
                  ],
                )
              else ...[
                _buildNegotiationSection(isCompact: isCompact),
                const SizedBox(height: 14),
                _buildActivePactsSection(isCompact: isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final double rep = diplomacyState.playerPelotonReputation;
    final Color repColor = rep >= 65
        ? AppColors.statusSuccess
        : (rep >= 40 ? AppColors.amberWarning : AppColors.crimsonAlert);

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: diplomacyState.activePacts.isNotEmpty
                    ? AppColors.goldAccent
                    : AppColors.accentBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'DYPLOMACJA NA SZOSIE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _MetricBadge(
              label: 'KM',
              value: currentStageKm.toStringAsFixed(1),
              color: AppColors.accentBlue,
            ),
            _MetricBadge(
              label: 'REPUTACJA',
              value: '${rep.toStringAsFixed(0)}/100',
              color: repColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioFeedBanner({Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cell_tower_rounded,
            size: 16,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              diplomacyState.latestRadioFeed,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                letterSpacing: -0.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetrayalBanner(BetrayalEvent alert, {Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.crimsonAlert,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert.radioHeadline,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationSection({required bool isCompact}) {
    final DiplomacyTeamContext? selectedPartner = rivalCandidates.isEmpty
        ? null
        : rivalCandidates.firstWhere(
            (r) => r.teamId == selectedPartnerTeamId,
            orElse: () => rivalCandidates.first,
          );

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEGOCJACJE Z RYWALAMI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (rivalCandidates.isEmpty)
            const Text(
              'Brak rywali w zasięgu rozmów w tej grupie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rivalCandidates.map((rival) {
                final bool isSelected = selectedPartner?.teamId == rival.teamId;
                final int vendetta =
                    diplomacyState.vendettaForTeam(rival.teamId);
                final double trust = diplomacyState.trustForTeam(rival.teamId);

                return _InteractiveDiplomacyButton(
                  label: vendetta > 0
                      ? '${rival.teamName} (WENDETA $vendetta)'
                      : '${rival.teamName} (${trust.toStringAsFixed(0)}%)',
                  isSelected: isSelected,
                  accentColor: vendetta > 0
                      ? AppColors.crimsonAlert
                      : AppColors.goldAccent,
                  enabled: isInteractiveEnabled && onSelectPartnerTeam != null,
                  onPressed: () => onSelectPartnerTeam?.call(rival.teamId),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DiplomacyPactType.values.map((pactType) {
                final bool canPropose = isInteractiveEnabled &&
                    onProposePact != null &&
                    selectedPartner != null;
                return _InteractiveDiplomacyButton(
                  label: pactType.displayName,
                  subtitle: pactType.shortDescription,
                  isSelected: false,
                  accentColor: switch (pactType) {
                    DiplomacyPactType.stageForGcDeal => AppColors.goldAccent,
                    DiplomacyPactType.antiLeaderCoalition =>
                      AppColors.primaryAccent,
                    DiplomacyPactType.neutralizationTruce =>
                      AppColors.accentBlue,
                  },
                  enabled: canPropose,
                  onPressed: () => onProposePact?.call(pactType),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivePactsSection({required bool isCompact}) {
    final active = diplomacyState.activePacts;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AKTYWNE PAKTY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${active.length}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (active.isEmpty)
            const Text(
              'Brak aktywnych sojuszy na etapie.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: active.map((pact) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${pact.type.displayName} • ${pact.partnerTeamName}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'do ${pact.expiresAtKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Partner: ${pact.partnerRiderId} (${pact.partnerTeamName})',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (onBetrayPact != null)
                              _InteractiveDiplomacyButton(
                                label: 'Zdradź (Betrayal!)',
                                isSelected: false,
                                accentColor: AppColors.crimsonAlert,
                                enabled: isInteractiveEnabled,
                                onPressed: () =>
                                    onBetrayPact?.call(pact.pactId),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveDiplomacyButton extends StatefulWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveDiplomacyButton({
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveDiplomacyButton> createState() =>
      _InteractiveDiplomacyButtonState();
}

class _InteractiveDiplomacyButtonState
    extends State<_InteractiveDiplomacyButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final Color borderColor = !enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : (widget.isSelected || _isFocused
            ? widget.accentColor
            : (_isHovered
                ? widget.accentColor.withValues(alpha: 0.7)
                : const Color(0xFF2A2F3D)));

    final Color bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : (_isPressed
            ? widget.accentColor.withValues(alpha: 0.25)
            : (widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.18)
                : (_isHovered
                    ? AppColors.surfaceLight
                    : AppColors.surface)));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (hover) => setState(() => _isHovered = hover),
      onShowFocusHighlight: (focus) => setState(() => _isFocused = focus),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
