// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';

/// Archetyp dziennikarza kolarskiego definiujący jego styl pracy i siłę oddziaływania.
enum JournalistArchetype {
  insiderScoop,
  investigativeReporter,
  tabloidSensationalist,
  analyticsColumnist,
  broadcasterPundit;

  String toJson() => name;

  static JournalistArchetype fromJson(String value) {
    return JournalistArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => JournalistArchetype.insiderScoop,
    );
  }

  String get label {
    switch (this) {
      case JournalistArchetype.insiderScoop:
        return 'Insider Transferowy';
      case JournalistArchetype.investigativeReporter:
        return 'Dziennikarz Śledczy';
      case JournalistArchetype.tabloidSensationalist:
        return 'Łowca Sensacji';
      case JournalistArchetype.analyticsColumnist:
        return 'Analityk & Dane';
      case JournalistArchetype.broadcasterPundit:
        return 'Ekspert TV';
    }
  }
}

/// Redakcja / medium kolarskie powiązane z dziennikarzem.
enum JournalistAffiliation {
  cyclingnews,
  sporza,
  lequipe,
  gazzetta,
  escapeCollective,
  wielerFlits,
  lanterneRouge;

  String toJson() => name;

  static JournalistAffiliation fromJson(String value) {
    return JournalistAffiliation.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => JournalistAffiliation.cyclingnews,
    );
  }

  String get displayName {
    switch (this) {
      case JournalistAffiliation.cyclingnews:
        return 'Cyclingnews';
      case JournalistAffiliation.sporza:
        return 'Sporza';
      case JournalistAffiliation.lequipe:
        return "L'Équipe";
      case JournalistAffiliation.gazzetta:
        return 'La Gazzetta';
      case JournalistAffiliation.escapeCollective:
        return 'Escape Collective';
      case JournalistAffiliation.wielerFlits:
        return 'WielerFlits';
      case JournalistAffiliation.lanterneRouge:
        return 'Lanterne Rouge';
    }
  }
}

/// Poziom wiarygodności przecieku transferowego.
enum RumorVeracityTier {
  baseless,
  speculative,
  credible,
  confirmedLeak,
  smokescreen;

  String toJson() => name;

  static RumorVeracityTier fromJson(String value) {
    return RumorVeracityTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RumorVeracityTier.speculative,
    );
  }

  String get label {
    switch (this) {
      case RumorVeracityTier.baseless:
        return 'Czysta Spekulacja';
      case RumorVeracityTier.speculative:
        return 'Niepotwierdzone';
      case RumorVeracityTier.credible:
        return 'Wiarygodne Źródło';
      case RumorVeracityTier.confirmedLeak:
        return 'Gorący Przeciek';
      case RumorVeracityTier.smokescreen:
        return 'Zasłona Dymna';
    }
  }

  Color get badgeColor {
    switch (this) {
      case RumorVeracityTier.baseless:
        return AppColors.textSecondary;
      case RumorVeracityTier.speculative:
        return AppColors.amberWarning;
      case RumorVeracityTier.credible:
        return AppColors.accentBlue;
      case RumorVeracityTier.confirmedLeak:
        return AppColors.crimsonAlert;
      case RumorVeracityTier.smokescreen:
        return AppColors.goldAccent;
    }
  }
}

/// Aktualny status plotki transferowej w obiegu medialnym.
enum RumorStatus {
  active,
  denied,
  confirmed,
  expired,
  smokescreenRevealed;

  String toJson() => name;

  static RumorStatus fromJson(String value) {
    return RumorStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RumorStatus.active,
    );
  }

  String get label {
    switch (this) {
      case RumorStatus.active:
        return 'Aktywna';
      case RumorStatus.denied:
        return 'Zdementowana';
      case RumorStatus.confirmed:
        return 'Potwierdzona';
      case RumorStatus.expired:
        return 'Wygasła';
      case RumorStatus.smokescreenRevealed:
        return 'Zdemaskowana';
    }
  }
}

/// Reakcja menedżera na plotkę transferową.
enum RumorActionType {
  none,
  deny,
  confirm,
  noComment,
  plantSmokescreen;

  String toJson() => name;

  static RumorActionType fromJson(String value) {
    return RumorActionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RumorActionType.none,
    );
  }
}

/// Cel strategiczny budowania zasłony dymnej na rynku transferowym.
enum SmokescreenObjective {
  protectRealTarget,
  inflateRivalCost,
  divertMediaPressure,
  testLockerRoomLoyalty;

  String toJson() => name;

  static SmokescreenObjective fromJson(String value) {
    return SmokescreenObjective.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SmokescreenObjective.protectRealTarget,
    );
  }

  String get label {
    switch (this) {
      case SmokescreenObjective.protectRealTarget:
        return 'Ukryj prawdziwy cel';
      case SmokescreenObjective.inflateRivalCost:
        return 'Podbij cenę rywalom';
      case SmokescreenObjective.divertMediaPressure:
        return 'Odwróć uwagę mediów';
      case SmokescreenObjective.testLockerRoomLoyalty:
        return 'Testuj lojalność szatni';
    }
  }

  String get description {
    switch (this) {
      case SmokescreenObjective.protectRealTarget:
        return 'Odciąga skautów rywali od właściwego kolarza (-12% konkurencji w negocjacjach).';
      case SmokescreenObjective.inflateRivalCost:
        return 'Zmusza rywali WorldTour do przepłacania za fałszywy cel (+15% żądań płacowych).';
      case SmokescreenObjective.divertMediaPressure:
        return 'Przekierowuje presję prasy z kryzysu wyników na głośny temat transferowy.';
      case SmokescreenObjective.testLockerRoomLoyalty:
        return 'Ujawnia reakcję obecnych liderów i pomocników na rzekomą konkurencję.';
    }
  }
}

/// Profil dziennikarza kolarskiego śledzącego rynek WorldTour/ProSeries.
class CyclingJournalist {
  final String id;
  final String name;
  final String handle;
  final JournalistAffiliation affiliation;
  final JournalistArchetype archetype;
  final int credibilityRating; // 1-100
  final int reachScore; // 1-100
  final int relationshipWithPlayer; // -100..+100
  final List<String> specializationTags;
  final bool isVerified;

  const CyclingJournalist({
    required this.id,
    required this.name,
    required this.handle,
    required this.affiliation,
    required this.archetype,
    required this.credibilityRating,
    required this.reachScore,
    required this.relationshipWithPlayer,
    required this.specializationTags,
    this.isVerified = true,
  });

  CyclingJournalist copyWith({
    String? id,
    String? name,
    String? handle,
    JournalistAffiliation? affiliation,
    JournalistArchetype? archetype,
    int? credibilityRating,
    int? reachScore,
    int? relationshipWithPlayer,
    List<String>? specializationTags,
    bool? isVerified,
  }) {
    return CyclingJournalist(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      affiliation: affiliation ?? this.affiliation,
      archetype: archetype ?? this.archetype,
      credibilityRating: (credibilityRating ?? this.credibilityRating).clamp(1, 100),
      reachScore: (reachScore ?? this.reachScore).clamp(1, 100),
      relationshipWithPlayer:
          (relationshipWithPlayer ?? this.relationshipWithPlayer).clamp(-100, 100),
      specializationTags: specializationTags ?? this.specializationTags,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'affiliation': affiliation.toJson(),
      'archetype': archetype.toJson(),
      'credibilityRating': credibilityRating,
      'reachScore': reachScore,
      'relationshipWithPlayer': relationshipWithPlayer,
      'specializationTags': specializationTags,
      'isVerified': isVerified,
    };
  }

  factory CyclingJournalist.fromJson(Map<String, dynamic> json) {
    return CyclingJournalist(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String,
      affiliation: JournalistAffiliation.fromJson(json['affiliation'] as String),
      archetype: JournalistArchetype.fromJson(json['archetype'] as String),
      credibilityRating: (json['credibilityRating'] as num).toInt().clamp(1, 100),
      reachScore: (json['reachScore'] as num).toInt().clamp(1, 100),
      relationshipWithPlayer:
          (json['relationshipWithPlayer'] as num).toInt().clamp(-100, 100),
      specializationTags: (json['specializationTags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }
}

/// Pojedyncza plotka lub przeciek w obiegu Transfer Rumor Mill.
class TransferRumor {
  final String id;
  final String targetRiderId;
  final String targetRiderName;
  final RiderRole targetRiderRole;
  final String sourceTeamId;
  final String sourceTeamName;
  final String rumoredDestinationTeamId;
  final String rumoredDestinationTeamName;
  final String journalistId;
  final String journalistName;
  final String journalistHandle;
  final int credibilityAtPublish;
  final RumorVeracityTier veracity;
  final RumorStatus status;
  final RumorActionType playerResponse;
  final String headline;
  final String body;
  final DateTime createdDate;
  final DateTime expiresDate;
  final bool isPlayerTeamInvolved;
  final bool isSmokescreen;
  final SmokescreenObjective? smokescreenObjective;
  final int estimatedSalaryEur;
  final int marketHeatDelta;
  final bool moraleImpactApplied;

  const TransferRumor({
    required this.id,
    required this.targetRiderId,
    required this.targetRiderName,
    required this.targetRiderRole,
    required this.sourceTeamId,
    required this.sourceTeamName,
    required this.rumoredDestinationTeamId,
    required this.rumoredDestinationTeamName,
    required this.journalistId,
    required this.journalistName,
    required this.journalistHandle,
    required this.credibilityAtPublish,
    required this.veracity,
    required this.status,
    required this.playerResponse,
    required this.headline,
    required this.body,
    required this.createdDate,
    required this.expiresDate,
    required this.isPlayerTeamInvolved,
    this.isSmokescreen = false,
    this.smokescreenObjective,
    required this.estimatedSalaryEur,
    required this.marketHeatDelta,
    this.moraleImpactApplied = false,
  });

  bool get isActionable =>
      status == RumorStatus.active &&
      isPlayerTeamInvolved &&
      playerResponse == RumorActionType.none;

  TransferRumor copyWith({
    String? id,
    String? targetRiderId,
    String? targetRiderName,
    RiderRole? targetRiderRole,
    String? sourceTeamId,
    String? sourceTeamName,
    String? rumoredDestinationTeamId,
    String? rumoredDestinationTeamName,
    String? journalistId,
    String? journalistName,
    String? journalistHandle,
    int? credibilityAtPublish,
    RumorVeracityTier? veracity,
    RumorStatus? status,
    RumorActionType? playerResponse,
    String? headline,
    String? body,
    DateTime? createdDate,
    DateTime? expiresDate,
    bool? isPlayerTeamInvolved,
    bool? isSmokescreen,
    SmokescreenObjective? smokescreenObjective,
    int? estimatedSalaryEur,
    int? marketHeatDelta,
    bool? moraleImpactApplied,
  }) {
    return TransferRumor(
      id: id ?? this.id,
      targetRiderId: targetRiderId ?? this.targetRiderId,
      targetRiderName: targetRiderName ?? this.targetRiderName,
      targetRiderRole: targetRiderRole ?? this.targetRiderRole,
      sourceTeamId: sourceTeamId ?? this.sourceTeamId,
      sourceTeamName: sourceTeamName ?? this.sourceTeamName,
      rumoredDestinationTeamId:
          rumoredDestinationTeamId ?? this.rumoredDestinationTeamId,
      rumoredDestinationTeamName:
          rumoredDestinationTeamName ?? this.rumoredDestinationTeamName,
      journalistId: journalistId ?? this.journalistId,
      journalistName: journalistName ?? this.journalistName,
      journalistHandle: journalistHandle ?? this.journalistHandle,
      credibilityAtPublish: credibilityAtPublish ?? this.credibilityAtPublish,
      veracity: veracity ?? this.veracity,
      status: status ?? this.status,
      playerResponse: playerResponse ?? this.playerResponse,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      createdDate: createdDate ?? this.createdDate,
      expiresDate: expiresDate ?? this.expiresDate,
      isPlayerTeamInvolved: isPlayerTeamInvolved ?? this.isPlayerTeamInvolved,
      isSmokescreen: isSmokescreen ?? this.isSmokescreen,
      smokescreenObjective: smokescreenObjective ?? this.smokescreenObjective,
      estimatedSalaryEur: estimatedSalaryEur ?? this.estimatedSalaryEur,
      marketHeatDelta: marketHeatDelta ?? this.marketHeatDelta,
      moraleImpactApplied: moraleImpactApplied ?? this.moraleImpactApplied,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetRiderId': targetRiderId,
      'targetRiderName': targetRiderName,
      'targetRiderRole': targetRiderRole.toJson(),
      'sourceTeamId': sourceTeamId,
      'sourceTeamName': sourceTeamName,
      'rumoredDestinationTeamId': rumoredDestinationTeamId,
      'rumoredDestinationTeamName': rumoredDestinationTeamName,
      'journalistId': journalistId,
      'journalistName': journalistName,
      'journalistHandle': journalistHandle,
      'credibilityAtPublish': credibilityAtPublish,
      'veracity': veracity.toJson(),
      'status': status.toJson(),
      'playerResponse': playerResponse.toJson(),
      'headline': headline,
      'body': body,
      'createdDate': createdDate.toIso8601String(),
      'expiresDate': expiresDate.toIso8601String(),
      'isPlayerTeamInvolved': isPlayerTeamInvolved,
      'isSmokescreen': isSmokescreen,
      'smokescreenObjective': smokescreenObjective?.toJson(),
      'estimatedSalaryEur': estimatedSalaryEur,
      'marketHeatDelta': marketHeatDelta,
      'moraleImpactApplied': moraleImpactApplied,
    };
  }

  factory TransferRumor.fromJson(Map<String, dynamic> json) {
    return TransferRumor(
      id: json['id'] as String,
      targetRiderId: json['targetRiderId'] as String,
      targetRiderName: json['targetRiderName'] as String,
      targetRiderRole: RiderRole.fromJson(json['targetRiderRole'] as String),
      sourceTeamId: json['sourceTeamId'] as String,
      sourceTeamName: json['sourceTeamName'] as String,
      rumoredDestinationTeamId: json['rumoredDestinationTeamId'] as String,
      rumoredDestinationTeamName: json['rumoredDestinationTeamName'] as String,
      journalistId: json['journalistId'] as String,
      journalistName: json['journalistName'] as String,
      journalistHandle: json['journalistHandle'] as String,
      credibilityAtPublish: (json['credibilityAtPublish'] as num).toInt(),
      veracity: RumorVeracityTier.fromJson(json['veracity'] as String),
      status: RumorStatus.fromJson(json['status'] as String),
      playerResponse: RumorActionType.fromJson(json['playerResponse'] as String),
      headline: json['headline'] as String,
      body: json['body'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      expiresDate: DateTime.parse(json['expiresDate'] as String),
      isPlayerTeamInvolved: json['isPlayerTeamInvolved'] as bool? ?? false,
      isSmokescreen: json['isSmokescreen'] as bool? ?? false,
      smokescreenObjective: json['smokescreenObjective'] != null
          ? SmokescreenObjective.fromJson(
              json['smokescreenObjective'] as String)
          : null,
      estimatedSalaryEur: (json['estimatedSalaryEur'] as num).toInt(),
      marketHeatDelta: (json['marketHeatDelta'] as num).toInt(),
      moraleImpactApplied: json['moraleImpactApplied'] as bool? ?? false,
    );
  }
}

/// Zapis wpływu plotki transferowej na morale i lojalność obecnego zawodnika.
class MoraleImpactEntry {
  final String riderId;
  final String riderName;
  final RiderRole riderRole;
  final double deltaMorale;
  final double deltaLoyalty;
  final String reason;
  final String triggeredByRumorId;
  final DateTime date;

  const MoraleImpactEntry({
    required this.riderId,
    required this.riderName,
    required this.riderRole,
    required this.deltaMorale,
    required this.deltaLoyalty,
    required this.reason,
    required this.triggeredByRumorId,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'riderRole': riderRole.toJson(),
      'deltaMorale': deltaMorale,
      'deltaLoyalty': deltaLoyalty,
      'reason': reason,
      'triggeredByRumorId': triggeredByRumorId,
      'date': date.toIso8601String(),
    };
  }

  factory MoraleImpactEntry.fromJson(Map<String, dynamic> json) {
    return MoraleImpactEntry(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      riderRole: RiderRole.fromJson(json['riderRole'] as String),
      deltaMorale: (json['deltaMorale'] as num).toDouble(),
      deltaLoyalty: (json['deltaLoyalty'] as num).toDouble(),
      reason: json['reason'] as String,
      triggeredByRumorId: json['triggeredByRumorId'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

/// Aktywna kampania zasłony dymnej zbudowana przez menedżera z pomocą dziennikarza.
class SmokescreenCampaign {
  final String id;
  final String decoyRiderId;
  final String decoyRiderName;
  final String? realTargetRiderId;
  final String? realTargetRiderName;
  final SmokescreenObjective objective;
  final String plantedJournalistId;
  final String linkedRumorId;
  final DateTime createdDate;
  final int durationDays;
  final int remainingDays;
  final double mediaDistractionPct; // 0-100
  final double rivalBidInflationPct; // 0-35
  final bool isActive;
  final int credibilityPenaltyOnExposure;

  const SmokescreenCampaign({
    required this.id,
    required this.decoyRiderId,
    required this.decoyRiderName,
    this.realTargetRiderId,
    this.realTargetRiderName,
    required this.objective,
    required this.plantedJournalistId,
    required this.linkedRumorId,
    required this.createdDate,
    required this.durationDays,
    required this.remainingDays,
    required this.mediaDistractionPct,
    required this.rivalBidInflationPct,
    required this.isActive,
    required this.credibilityPenaltyOnExposure,
  });

  SmokescreenCampaign copyWith({
    String? id,
    String? decoyRiderId,
    String? decoyRiderName,
    String? realTargetRiderId,
    String? realTargetRiderName,
    SmokescreenObjective? objective,
    String? plantedJournalistId,
    String? linkedRumorId,
    DateTime? createdDate,
    int? durationDays,
    int? remainingDays,
    double? mediaDistractionPct,
    double? rivalBidInflationPct,
    bool? isActive,
    int? credibilityPenaltyOnExposure,
  }) {
    return SmokescreenCampaign(
      id: id ?? this.id,
      decoyRiderId: decoyRiderId ?? this.decoyRiderId,
      decoyRiderName: decoyRiderName ?? this.decoyRiderName,
      realTargetRiderId: realTargetRiderId ?? this.realTargetRiderId,
      realTargetRiderName: realTargetRiderName ?? this.realTargetRiderName,
      objective: objective ?? this.objective,
      plantedJournalistId: plantedJournalistId ?? this.plantedJournalistId,
      linkedRumorId: linkedRumorId ?? this.linkedRumorId,
      createdDate: createdDate ?? this.createdDate,
      durationDays: durationDays ?? this.durationDays,
      remainingDays: remainingDays ?? this.remainingDays,
      mediaDistractionPct: mediaDistractionPct ?? this.mediaDistractionPct,
      rivalBidInflationPct: rivalBidInflationPct ?? this.rivalBidInflationPct,
      isActive: isActive ?? this.isActive,
      credibilityPenaltyOnExposure:
          credibilityPenaltyOnExposure ?? this.credibilityPenaltyOnExposure,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'decoyRiderId': decoyRiderId,
      'decoyRiderName': decoyRiderName,
      'realTargetRiderId': realTargetRiderId,
      'realTargetRiderName': realTargetRiderName,
      'objective': objective.toJson(),
      'plantedJournalistId': plantedJournalistId,
      'linkedRumorId': linkedRumorId,
      'createdDate': createdDate.toIso8601String(),
      'durationDays': durationDays,
      'remainingDays': remainingDays,
      'mediaDistractionPct': mediaDistractionPct,
      'rivalBidInflationPct': rivalBidInflationPct,
      'isActive': isActive,
      'credibilityPenaltyOnExposure': credibilityPenaltyOnExposure,
    };
  }

  factory SmokescreenCampaign.fromJson(Map<String, dynamic> json) {
    return SmokescreenCampaign(
      id: json['id'] as String,
      decoyRiderId: json['decoyRiderId'] as String,
      decoyRiderName: json['decoyRiderName'] as String,
      realTargetRiderId: json['realTargetRiderId'] as String?,
      realTargetRiderName: json['realTargetRiderName'] as String?,
      objective: SmokescreenObjective.fromJson(json['objective'] as String),
      plantedJournalistId: json['plantedJournalistId'] as String,
      linkedRumorId: json['linkedRumorId'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      durationDays: (json['durationDays'] as num).toInt(),
      remainingDays: (json['remainingDays'] as num).toInt(),
      mediaDistractionPct: (json['mediaDistractionPct'] as num).toDouble(),
      rivalBidInflationPct: (json['rivalBidInflationPct'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? false,
      credibilityPenaltyOnExposure:
          (json['credibilityPenaltyOnExposure'] as num).toInt(),
    );
  }
}

/// Wynik reakcji menedżera na plotkę (dementi, potwierdzenie, brak komentarza).
class RumorResponseOutcome {
  final TransferRumor updatedRumor;
  final int journalistRelationshipDelta;
  final int mediaCredibilityDelta;
  final int marketHeatDelta;
  final List<MoraleImpactEntry> teamMoraleImpacts;
  final List<Rider> updatedSquad;
  final String summaryMessage;

  const RumorResponseOutcome({
    required this.updatedRumor,
    required this.journalistRelationshipDelta,
    required this.mediaCredibilityDelta,
    required this.marketHeatDelta,
    required this.teamMoraleImpacts,
    required this.updatedSquad,
    required this.summaryMessage,
  });
}

/// Wynik dziennego cyklu Transfer Rumor Mill.
class DailyRumorTickResult {
  final TransferRumorMillState nextState;
  final List<TransferRumor> newlyPublishedRumors;
  final List<MoraleImpactEntry> moraleImpacts;
  final List<Rider> updatedPlayerSquad;

  const DailyRumorTickResult({
    required this.nextState,
    required this.newlyPublishedRumors,
    required this.moraleImpacts,
    required this.updatedPlayerSquad,
  });
}

/// Zbiorczy stan systemu Transfer Rumor Mill i relacji z dziennikarzami.
class TransferRumorMillState {
  final List<CyclingJournalist> journalists;
  final List<TransferRumor> activeRumors;
  final List<TransferRumor> archivedRumors;
  final List<SmokescreenCampaign> smokescreens;
  final List<MoraleImpactEntry> moraleHistory;
  final int mediaCredibilityScore; // 0-100
  final int marketHeatIndex; // 0-100
  final DateTime? lastTickDate;

  const TransferRumorMillState({
    required this.journalists,
    required this.activeRumors,
    required this.archivedRumors,
    required this.smokescreens,
    required this.moraleHistory,
    required this.mediaCredibilityScore,
    required this.marketHeatIndex,
    this.lastTickDate,
  });

  factory TransferRumorMillState.initial() {
    return TransferRumorMillState(
      journalists: TransferRumorMillAndJournalistsService.createDefaultJournalists(),
      activeRumors: const [],
      archivedRumors: const [],
      smokescreens: const [],
      moraleHistory: const [],
      mediaCredibilityScore: 72,
      marketHeatIndex: 35,
      lastTickDate: null,
    );
  }

  List<SmokescreenCampaign> get activeSmokescreens =>
      smokescreens.where((s) => s.isActive).toList(growable: false);

  TransferRumorMillState copyWith({
    List<CyclingJournalist>? journalists,
    List<TransferRumor>? activeRumors,
    List<TransferRumor>? archivedRumors,
    List<SmokescreenCampaign>? smokescreens,
    List<MoraleImpactEntry>? moraleHistory,
    int? mediaCredibilityScore,
    int? marketHeatIndex,
    DateTime? lastTickDate,
  }) {
    return TransferRumorMillState(
      journalists: journalists ?? this.journalists,
      activeRumors: activeRumors ?? this.activeRumors,
      archivedRumors: archivedRumors ?? this.archivedRumors,
      smokescreens: smokescreens ?? this.smokescreens,
      moraleHistory: moraleHistory ?? this.moraleHistory,
      mediaCredibilityScore:
          (mediaCredibilityScore ?? this.mediaCredibilityScore).clamp(0, 100),
      marketHeatIndex: (marketHeatIndex ?? this.marketHeatIndex).clamp(0, 100),
      lastTickDate: lastTickDate ?? this.lastTickDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'journalists': journalists.map((e) => e.toJson()).toList(),
      'activeRumors': activeRumors.map((e) => e.toJson()).toList(),
      'archivedRumors': archivedRumors.map((e) => e.toJson()).toList(),
      'smokescreens': smokescreens.map((e) => e.toJson()).toList(),
      'moraleHistory': moraleHistory.map((e) => e.toJson()).toList(),
      'mediaCredibilityScore': mediaCredibilityScore,
      'marketHeatIndex': marketHeatIndex,
      'lastTickDate': lastTickDate?.toIso8601String(),
    };
  }

  factory TransferRumorMillState.fromJson(Map<String, dynamic> json) {
    return TransferRumorMillState(
      journalists: (json['journalists'] as List<dynamic>? ?? [])
          .map((e) => CyclingJournalist.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeRumors: (json['activeRumors'] as List<dynamic>? ?? [])
          .map((e) => TransferRumor.fromJson(e as Map<String, dynamic>))
          .toList(),
      archivedRumors: (json['archivedRumors'] as List<dynamic>? ?? [])
          .map((e) => TransferRumor.fromJson(e as Map<String, dynamic>))
          .toList(),
      smokescreens: (json['smokescreens'] as List<dynamic>? ?? [])
          .map((e) => SmokescreenCampaign.fromJson(e as Map<String, dynamic>))
          .toList(),
      moraleHistory: (json['moraleHistory'] as List<dynamic>? ?? [])
          .map((e) => MoraleImpactEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaCredibilityScore:
          (json['mediaCredibilityScore'] as num?)?.toInt().clamp(0, 100) ?? 72,
      marketHeatIndex:
          (json['marketHeatIndex'] as num?)?.toInt().clamp(0, 100) ?? 35,
      lastTickDate: json['lastTickDate'] != null
          ? DateTime.parse(json['lastTickDate'] as String)
          : null,
    );
  }
}

/// Główny serwis obsługujący dziennikarzy kolarskich, przecieki transferowe,
/// zasłonę dymną na rynku oraz wpływ plotek na morale obecnych zawodników.
class TransferRumorMillAndJournalistsService {
  const TransferRumorMillAndJournalistsService();

  /// Tworzy domyślną redakcję 8 dziennikarzy kolarskich o zróżnicowanej wiarygodności i zasięgu.
  static List<CyclingJournalist> createDefaultJournalists() {
    return const [
      CyclingJournalist(
        id: 'j_daniel_benson',
        name: 'Daniel Vermeer',
        handle: '@VermeerCycling',
        affiliation: JournalistAffiliation.cyclingnews,
        archetype: JournalistArchetype.insiderScoop,
        credibilityRating: 91,
        reachScore: 94,
        relationshipWithPlayer: 18,
        specializationTags: ['WorldTour', 'Kontrakty', 'GC'],
      ),
      CyclingJournalist(
        id: 'j_renaud_sporza',
        name: 'Renaud De Smet',
        handle: '@DeSmetSporza',
        affiliation: JournalistAffiliation.sporza,
        archetype: JournalistArchetype.broadcasterPundit,
        credibilityRating: 86,
        reachScore: 89,
        relationshipWithPlayer: 10,
        specializationTags: ['Flandria', 'Klasyki', 'Sprinterzy'],
      ),
      CyclingJournalist(
        id: 'j_claire_lequipe',
        name: 'Claire Moreau',
        handle: '@CMoreau_Lequipe',
        affiliation: JournalistAffiliation.lequipe,
        archetype: JournalistArchetype.investigativeReporter,
        credibilityRating: 88,
        reachScore: 92,
        relationshipWithPlayer: 4,
        specializationTags: ['Tour de France', 'Budżety', 'Sponsorzy'],
      ),
      CyclingJournalist(
        id: 'j_marco_gazzetta',
        name: 'Marco Bellini',
        handle: '@BelliniGazzetta',
        affiliation: JournalistAffiliation.gazzetta,
        archetype: JournalistArchetype.tabloidSensationalist,
        credibilityRating: 52,
        reachScore: 87,
        relationshipWithPlayer: -6,
        specializationTags: ['Giro', 'Sensacje', 'Przecieki'],
      ),
      CyclingJournalist(
        id: 'j_benji_lr',
        name: 'Lucas Naessens',
        handle: '@LanterneScoops',
        affiliation: JournalistAffiliation.lanterneRouge,
        archetype: JournalistArchetype.analyticsColumnist,
        credibilityRating: 79,
        reachScore: 76,
        relationshipWithPlayer: 22,
        specializationTags: ['W/kg', 'Taktyka', 'U23'],
      ),
      CyclingJournalist(
        id: 'j_bram_wf',
        name: 'Bram Van Der Berg',
        handle: '@BramWielerFlits',
        affiliation: JournalistAffiliation.wielerFlits,
        archetype: JournalistArchetype.insiderScoop,
        credibilityRating: 84,
        reachScore: 81,
        relationshipWithPlayer: 12,
        specializationTags: ['Benelux', 'Transfery', 'Sprzęt'],
      ),
      CyclingJournalist(
        id: 'j_elena_escape',
        name: 'Elena Kowalczyk',
        handle: '@ElenaEscape',
        affiliation: JournalistAffiliation.escapeCollective,
        archetype: JournalistArchetype.investigativeReporter,
        credibilityRating: 90,
        reachScore: 74,
        relationshipWithPlayer: 25,
        specializationTags: ['Śledztwa', 'Płace', 'UCI'],
      ),
      CyclingJournalist(
        id: 'j_fabio_rumor',
        name: 'Fabio Corsi',
        handle: '@CorsiMercato',
        affiliation: JournalistAffiliation.gazzetta,
        archetype: JournalistArchetype.tabloidSensationalist,
        credibilityRating: 41,
        reachScore: 79,
        relationshipWithPlayer: 0,
        specializationTags: ['Mercato', 'Bomba', 'Plotki'],
      ),
    ];
  }

  /// Dzienna aktualizacja młynka plotek transferowych: wygaszanie starych plotek,
  /// postęp zasłon dymnych, generowanie nowych przecieków i aplikacja wpływu na morale.
  DailyRumorTickResult tickDailyRumorMill({
    required TransferRumorMillState currentState,
    required DateTime currentDate,
    required CyclingTeam playerTeam,
    required List<Rider> playerSquad,
    required List<CyclingTeam> allTeams,
    required List<Rider> marketRiders,
    int? randomSeed,
  }) {
    final rng = math.Random(
      randomSeed ??
          (currentDate.millisecondsSinceEpoch ~/ 86400000) ^
              playerTeam.id.hashCode,
    );

    final stillActive = <TransferRumor>[];
    final newlyArchived = List<TransferRumor>.from(currentState.archivedRumors);

    for (final rumor in currentState.activeRumors) {
      if (rumor.expiresDate.isBefore(currentDate)) {
        newlyArchived.add(rumor.copyWith(status: RumorStatus.expired));
      } else {
        stillActive.add(rumor);
      }
    }

    // Aktualizacja czasu trwania aktywnych zasłon dymnych
    final updatedSmokescreens = <SmokescreenCampaign>[];
    for (final campaign in currentState.smokescreens) {
      if (!campaign.isActive) {
        updatedSmokescreens.add(campaign);
        continue;
      }
      final nextRemaining = campaign.remainingDays - 1;
      if (nextRemaining <= 0) {
        updatedSmokescreens.add(
          campaign.copyWith(remainingDays: 0, isActive: false),
        );
      } else {
        updatedSmokescreens.add(
          campaign.copyWith(
            remainingDays: nextRemaining,
            mediaDistractionPct:
                (campaign.mediaDistractionPct * 0.94).clamp(10.0, 100.0),
          ),
        );
      }
    }

    // Prawdopodobieństwo nowego przecieku zależy od okresu transferowego (sierpień-październik) i marketHeatIndex
    final isTransferWindowHot =
        currentDate.month >= 7 && currentDate.month <= 10;
    final baseChance = isTransferWindowHot ? 0.55 : 0.25;
    final heatBoost = currentState.marketHeatIndex / 250.0;
    final spawnRoll = rng.nextDouble();

    final newRumors = <TransferRumor>[];
    final newMoraleEntries = <MoraleImpactEntry>[];
    var workingSquad = List<Rider>.from(playerSquad);

    if (stillActive.length < 12 &&
        spawnRoll < (baseChance + heatBoost).clamp(0.15, 0.85) &&
        currentState.journalists.isNotEmpty &&
        marketRiders.isNotEmpty &&
        allTeams.isNotEmpty) {
      final candidate = _generateOrganicRumor(
        rng: rng,
        currentDate: currentDate,
        journalists: currentState.journalists,
        playerTeam: playerTeam,
        playerSquad: workingSquad,
        allTeams: allTeams,
        marketRiders: marketRiders,
        existingActiveRumors: stillActive,
      );
      if (candidate != null) {
        final impacts = computeMoraleImpactsForRumor(
          rumor: candidate,
          playerTeamId: playerTeam.id,
          playerSquad: workingSquad,
          journalist: _findJournalist(
            currentState.journalists,
            candidate.journalistId,
          ),
          date: currentDate,
        );
        workingSquad = applyMoraleImpactsToRoster(
          squad: workingSquad,
          impacts: impacts,
        );
        newMoraleEntries.addAll(impacts);
        final finalizedRumor = candidate.copyWith(
          moraleImpactApplied: impacts.isNotEmpty,
        );
        stillActive.insert(0, finalizedRumor);
        newRumors.add(finalizedRumor);
      }
    }

    // Zbieramy bieżący heat index
    final heatDelta = newRumors.fold<int>(0, (sum, r) => sum + r.marketHeatDelta);
    final nextHeat = (currentState.marketHeatIndex - 2 + heatDelta).clamp(10, 100);

    // Ograniczenie archiwum do ostatnich 60 wpisów dla ekonomii pamięci
    final trimmedArchive = newlyArchived.length > 60
        ? newlyArchived.sublist(newlyArchived.length - 60)
        : newlyArchived;
    final combinedMoraleHistory = [
      ...newMoraleEntries,
      ...currentState.moraleHistory,
    ];
    final trimmedMorale = combinedMoraleHistory.length > 80
        ? combinedMoraleHistory.sublist(0, 80)
        : combinedMoraleHistory;

    final nextState = currentState.copyWith(
      activeRumors: stillActive,
      archivedRumors: trimmedArchive,
      smokescreens: updatedSmokescreens,
      moraleHistory: trimmedMorale,
      marketHeatIndex: nextHeat,
      lastTickDate: currentDate,
    );

    return DailyRumorTickResult(
      nextState: nextState,
      newlyPublishedRumors: newRumors,
      moraleImpacts: newMoraleEntries,
      updatedPlayerSquad: workingSquad,
    );
  }

  /// Buduje zasłonę dymną (Smokescreen) poprzez celowy przeciek fałszywego celu
  /// do wybranego dziennikarza, aby chronić prawdziwy transfer lub podbić koszty rywali.
  ({
    TransferRumorMillState nextState,
    SmokescreenCampaign campaign,
    TransferRumor plantedRumor,
    List<MoraleImpactEntry> moraleImpacts,
    List<Rider> updatedSquad,
  }) plantSmokescreen({
    required TransferRumorMillState currentState,
    required DateTime currentDate,
    required CyclingTeam playerTeam,
    required List<Rider> playerSquad,
    required Rider decoyRider,
    Rider? realTargetRider,
    required String decoyCurrentTeamName,
    required CyclingJournalist journalist,
    required SmokescreenObjective objective,
    int durationDays = 10,
  }) {
    final safeDuration = durationDays.clamp(3, 21);
    final rumorId =
        'rumor_smoke_${currentDate.millisecondsSinceEpoch}_${decoyRider.id}';
    final campaignId =
        'smoke_${currentDate.millisecondsSinceEpoch}_${decoyRider.id}';

    // Skuteczność zasłony zależy od zasięgu dziennikarza i wiarygodności gracza w mediach
    final reachFactor = journalist.reachScore / 100.0;
    final credFactor = currentState.mediaCredibilityScore / 100.0;
    final distractionPct =
        (35.0 + 40.0 * reachFactor + 20.0 * credFactor).clamp(25.0, 96.0);
    final inflationPct = objective == SmokescreenObjective.inflateRivalCost
        ? (10.0 + 18.0 * reachFactor).clamp(8.0, 30.0)
        : (4.0 + 10.0 * reachFactor).clamp(3.0, 16.0);

    final estimatedSalary =
        (decoyRider.contract.annualSalaryEur * 1.15).round().clamp(60000, 8000000);

    final headline = _buildSmokescreenHeadline(
      decoyName: decoyRider.fullName,
      teamName: playerTeam.name,
      objective: objective,
    );
    final body =
        '${journalist.name} (${journalist.affiliation.displayName}) donosi o '
        'zaawansowanych rozmowach ${playerTeam.name} z ${decoyRider.fullName}. '
        'Źródła z otoczenia klubu sugerują ofertę rzędu '
        '${(estimatedSalary / 1000).round()} tys. EUR rocznie.';

    final plantedRumor = TransferRumor(
      id: rumorId,
      targetRiderId: decoyRider.id,
      targetRiderName: decoyRider.fullName,
      targetRiderRole: decoyRider.contract.role,
      sourceTeamId: decoyRider.contract.teamId,
      sourceTeamName: decoyCurrentTeamName,
      rumoredDestinationTeamId: playerTeam.id,
      rumoredDestinationTeamName: playerTeam.name,
      journalistId: journalist.id,
      journalistName: journalist.name,
      journalistHandle: journalist.handle,
      credibilityAtPublish: journalist.credibilityRating,
      veracity: RumorVeracityTier.smokescreen,
      status: RumorStatus.active,
      playerResponse: RumorActionType.plantSmokescreen,
      headline: headline,
      body: body,
      createdDate: currentDate,
      expiresDate: currentDate.add(Duration(days: safeDuration)),
      isPlayerTeamInvolved: true,
      isSmokescreen: true,
      smokescreenObjective: objective,
      estimatedSalaryEur: estimatedSalary,
      marketHeatDelta: 14,
      moraleImpactApplied: false,
    );

    final campaign = SmokescreenCampaign(
      id: campaignId,
      decoyRiderId: decoyRider.id,
      decoyRiderName: decoyRider.fullName,
      realTargetRiderId: realTargetRider?.id,
      realTargetRiderName: realTargetRider?.fullName,
      objective: objective,
      plantedJournalistId: journalist.id,
      linkedRumorId: rumorId,
      createdDate: currentDate,
      durationDays: safeDuration,
      remainingDays: safeDuration,
      mediaDistractionPct: distractionPct,
      rivalBidInflationPct: inflationPct,
      isActive: true,
      credibilityPenaltyOnExposure:
          journalist.archetype == JournalistArchetype.investigativeReporter
              ? 12
              : 7,
    );

    // Zasłona dymna wywołuje lekki niepokój w szatni, jeśli gracz nie uprzedził zawodników
    final rawImpacts = computeMoraleImpactsForRumor(
      rumor: plantedRumor,
      playerTeamId: playerTeam.id,
      playerSquad: playerSquad,
      journalist: journalist,
      date: currentDate,
      dampeningFactor: objective == SmokescreenObjective.testLockerRoomLoyalty
          ? 1.0
          : 0.45,
    );
    final updatedSquad = applyMoraleImpactsToRoster(
      squad: playerSquad,
      impacts: rawImpacts,
    );

    // Dziennikarz dostaje ekskluzywny przeciek (+relacja), ale jeśli to zasłona, rośnie ryzyko
    final updatedJournalists = currentState.journalists.map((j) {
      if (j.id == journalist.id) {
        return j.copyWith(
          relationshipWithPlayer: j.relationshipWithPlayer + 6,
        );
      }
      return j;
    }).toList(growable: false);

    final nextState = currentState.copyWith(
      journalists: updatedJournalists,
      activeRumors: [
        plantedRumor.copyWith(moraleImpactApplied: rawImpacts.isNotEmpty),
        ...currentState.activeRumors,
      ],
      smokescreens: [campaign, ...currentState.smokescreens],
      moraleHistory: [...rawImpacts, ...currentState.moraleHistory],
      marketHeatIndex: currentState.marketHeatIndex + 12,
      mediaCredibilityScore: currentState.mediaCredibilityScore - 2,
    );

    return (
      nextState: nextState,
      campaign: campaign,
      plantedRumor: plantedRumor,
      moraleImpacts: rawImpacts,
      updatedSquad: updatedSquad,
    );
  }

  /// Reakcja menedżera na plotkę: zdementowanie, potwierdzenie lub brak komentarza.
  ({TransferRumorMillState nextState, RumorResponseOutcome outcome})
      respondToRumor({
    required TransferRumorMillState currentState,
    required String rumorId,
    required RumorActionType action,
    required CyclingTeam playerTeam,
    required List<Rider> playerSquad,
    required DateTime currentDate,
  }) {
    final rumorIndex =
        currentState.activeRumors.indexWhere((r) => r.id == rumorId);
    if (rumorIndex == -1) {
      final fallback = TransferRumor(
        id: rumorId,
        targetRiderId: '',
        targetRiderName: 'Nieznany',
        targetRiderRole: RiderRole.domestique,
        sourceTeamId: '',
        sourceTeamName: '',
        rumoredDestinationTeamId: '',
        rumoredDestinationTeamName: '',
        journalistId: '',
        journalistName: '',
        journalistHandle: '',
        credibilityAtPublish: 50,
        veracity: RumorVeracityTier.speculative,
        status: RumorStatus.expired,
        playerResponse: action,
        headline: 'Plotka niedostępna',
        body: '',
        createdDate: currentDate,
        expiresDate: currentDate,
        isPlayerTeamInvolved: false,
        estimatedSalaryEur: 0,
        marketHeatDelta: 0,
      );
      return (
        nextState: currentState,
        outcome: RumorResponseOutcome(
          updatedRumor: fallback,
          journalistRelationshipDelta: 0,
          mediaCredibilityDelta: 0,
          marketHeatDelta: 0,
          teamMoraleImpacts: const [],
          updatedSquad: playerSquad,
          summaryMessage: 'Plotka wygasła lub nie istnieje.',
        ),
      );
    }

    final rumor = currentState.activeRumors[rumorIndex];
    final journalist =
        _findJournalist(currentState.journalists, rumor.journalistId);

    var relationshipDelta = 0;
    var credibilityDelta = 0;
    var heatDelta = 0;
    var nextStatus = rumor.status;
    final recoveryImpacts = <MoraleImpactEntry>[];
    String summary;

    switch (action) {
      case RumorActionType.deny:
        nextStatus = RumorStatus.denied;
        if (rumor.veracity == RumorVeracityTier.confirmedLeak ||
            rumor.veracity == RumorVeracityTier.credible) {
          // Dementi prawdziwego przecieku psuje relację z dziennikarzem, ale uspokaja szatnię
          relationshipDelta = -8;
          credibilityDelta = -4;
          heatDelta = -5;
          summary =
              'Stanowczo zdementowałeś doniesienia ${rumor.journalistName}. '
              'Szatnia odetchnęła z ulgą, choć insiderzy są sceptyczni.';
        } else {
          // Zbicie fałszywej plotki wzmacnia autorytet menedżera
          relationshipDelta = -2;
          credibilityDelta = 5;
          heatDelta = -8;
          summary =
              'Skutecznie uciąłeś spekulacje wokół ${rumor.targetRiderName}. '
              'Twoja wiarygodność w mediach wzrosła.';
        }

        // Uspokojenie zawodników dotkniętych plotką
        for (final rider in playerSquad) {
          if (_isRoleThreatenedByRumor(
              rider, rumor, playerTeam.id)) {
            recoveryImpacts.add(
              MoraleImpactEntry(
                riderId: rider.id,
                riderName: rider.fullName,
                riderRole: rider.contract.role,
                deltaMorale: 4.5,
                deltaLoyalty: 2.5,
                reason: 'Dementi klubu ws. ${rumor.targetRiderName} uspokoiło nastroje.',
                triggeredByRumorId: rumor.id,
                date: currentDate,
              ),
            );
          } else if (rider.id == rumor.targetRiderId &&
              rumor.sourceTeamId == playerTeam.id) {
            recoveryImpacts.add(
              MoraleImpactEntry(
                riderId: rider.id,
                riderName: rider.fullName,
                riderRole: rider.contract.role,
                deltaMorale: 3.5,
                deltaLoyalty: 3.0,
                reason: 'Klub publicznie potwierdził zaufanie i brak planów sprzedaży.',
                triggeredByRumorId: rumor.id,
                date: currentDate,
              ),
            );
          }
        }
        break;

      case RumorActionType.confirm:
        nextStatus = RumorStatus.confirmed;
        relationshipDelta = 10;
        credibilityDelta = rumor.isSmokescreen ? -6 : 4;
        heatDelta = 15;
        summary =
            'Potwierdziłeś zainteresowanie wokół ${rumor.targetRiderName}. '
            'Rynek transferowy rozgrzał się do czerwoności.';

        for (final rider in playerSquad) {
          if (_isRoleThreatenedByRumor(rider, rumor, playerTeam.id)) {
            recoveryImpacts.add(
              MoraleImpactEntry(
                riderId: rider.id,
                riderName: rider.fullName,
                riderRole: rider.contract.role,
                deltaMorale: -7.5,
                deltaLoyalty: -5.0,
                reason:
                    'Publiczne potwierdzenie rozmów z ${rumor.targetRiderName} zagraża pozycji w zespole.',
                triggeredByRumorId: rumor.id,
                date: currentDate,
              ),
            );
          }
        }
        break;

      case RumorActionType.noComment:
        relationshipDelta = -1;
        credibilityDelta = 0;
        heatDelta = 4;
        summary =
            'Odmówiłeś komentarza w sprawie ${rumor.targetRiderName}. '
            'Spekulacje w mediach nadal krążą.';
        for (final rider in playerSquad) {
          if (_isRoleThreatenedByRumor(rider, rumor, playerTeam.id)) {
            recoveryImpacts.add(
              MoraleImpactEntry(
                riderId: rider.id,
                riderName: rider.fullName,
                riderRole: rider.contract.role,
                deltaMorale: -1.5,
                deltaLoyalty: -1.0,
                reason: 'Brak jasnego stanowiska zarządu budzi niepewność.',
                triggeredByRumorId: rumor.id,
                date: currentDate,
              ),
            );
          }
        }
        break;

      case RumorActionType.none:
      case RumorActionType.plantSmokescreen:
        summary = 'Brak nowej akcji medialnej.';
        break;
    }

    final updatedRumor = rumor.copyWith(
      status: nextStatus,
      playerResponse: action,
    );

    final updatedSquad = applyMoraleImpactsToRoster(
      squad: playerSquad,
      impacts: recoveryImpacts,
    );

    final updatedJournalists = currentState.journalists.map((j) {
      if (journalist != null && j.id == journalist.id) {
        return j.copyWith(
          relationshipWithPlayer: j.relationshipWithPlayer + relationshipDelta,
        );
      }
      return j;
    }).toList(growable: false);

    final nextActive = List<TransferRumor>.from(currentState.activeRumors);
    final nextArchive = List<TransferRumor>.from(currentState.archivedRumors);
    if (nextStatus == RumorStatus.denied || nextStatus == RumorStatus.confirmed) {
      nextActive.removeAt(rumorIndex);
      nextArchive.insert(0, updatedRumor);
    } else {
      nextActive[rumorIndex] = updatedRumor;
    }

    final nextState = currentState.copyWith(
      journalists: updatedJournalists,
      activeRumors: nextActive,
      archivedRumors: nextArchive,
      moraleHistory: [...recoveryImpacts, ...currentState.moraleHistory],
      mediaCredibilityScore:
          currentState.mediaCredibilityScore + credibilityDelta,
      marketHeatIndex: currentState.marketHeatIndex + heatDelta,
    );

    return (
      nextState: nextState,
      outcome: RumorResponseOutcome(
        updatedRumor: updatedRumor,
        journalistRelationshipDelta: relationshipDelta,
        mediaCredibilityDelta: credibilityDelta,
        marketHeatDelta: heatDelta,
        teamMoraleImpacts: recoveryImpacts,
        updatedSquad: updatedSquad,
        summaryMessage: summary,
      ),
    );
  }

  /// Wylicza wpływ plotki transferowej na morale obecnych zawodników drużyny gracza.
  List<MoraleImpactEntry> computeMoraleImpactsForRumor({
    required TransferRumor rumor,
    required String playerTeamId,
    required List<Rider> playerSquad,
    CyclingJournalist? journalist,
    required DateTime date,
    double dampeningFactor = 1.0,
  }) {
    if (!rumor.isPlayerTeamInvolved || playerSquad.isEmpty) {
      return const [];
    }

    final reachScale = ((journalist?.reachScore ?? 70) / 100.0);
    final credScale = (rumor.credibilityAtPublish / 100.0);
    final intensity = (0.5 + 0.5 * reachScale * credScale) * dampeningFactor;

    final impacts = <MoraleImpactEntry>[];

    for (final rider in playerSquad) {
      // Przypadek 1: Kolarz gracza łączony z odejściem do rywala
      if (rider.id == rumor.targetRiderId &&
          rumor.sourceTeamId == playerTeamId) {
        final deltaMorale = (-3.5 * intensity).clamp(-10.0, -0.5);
        final deltaLoyalty = (-4.0 * intensity).clamp(-12.0, -0.5);
        impacts.add(
          MoraleImpactEntry(
            riderId: rider.id,
            riderName: rider.fullName,
            riderRole: rider.contract.role,
            deltaMorale: double.parse(deltaMorale.toStringAsFixed(1)),
            deltaLoyalty: double.parse(deltaLoyalty.toStringAsFixed(1)),
            reason:
                'Plotka o transferze do ${rumor.rumoredDestinationTeamName} destabilizuje koncentrację.',
            triggeredByRumorId: rumor.id,
            date: date,
          ),
        );
        continue;
      }

      // Przypadek 2: Rywal o tej samej roli łączony z przyjściem do zespołu gracza
      if (_isRoleThreatenedByRumor(rider, rumor, playerTeamId)) {
        final isLeaderRole = rider.contract.role == RiderRole.teamLeader ||
            rider.contract.role == RiderRole.sprinter;
        final baseHit = isLeaderRole ? -6.0 : -3.5;
        final deltaMorale = (baseHit * intensity).clamp(-12.0, -0.5);
        final deltaLoyalty = ((baseHit * 0.75) * intensity).clamp(-10.0, -0.5);
        impacts.add(
          MoraleImpactEntry(
            riderId: rider.id,
            riderName: rider.fullName,
            riderRole: rider.contract.role,
            deltaMorale: double.parse(deltaMorale.toStringAsFixed(1)),
            deltaLoyalty: double.parse(deltaLoyalty.toStringAsFixed(1)),
            reason:
                'Doniesienia o transferze ${rumor.targetRiderName} (${rumor.targetRiderRole.label}) zagrażają statusowi w składzie.',
            triggeredByRumorId: rumor.id,
            date: date,
          ),
        );
      } else if (rumor.rumoredDestinationTeamId == playerTeamId &&
          rumor.targetRiderRole == RiderRole.superDomestique &&
          rider.contract.role == RiderRole.teamLeader) {
        // Sprowadzenie super-pomocnika podnosi morale lidera!
        final boost = (3.0 * intensity).clamp(0.5, 6.0);
        impacts.add(
          MoraleImpactEntry(
            riderId: rider.id,
            riderName: rider.fullName,
            riderRole: rider.contract.role,
            deltaMorale: double.parse(boost.toStringAsFixed(1)),
            deltaLoyalty: double.parse((boost * 0.5).toStringAsFixed(1)),
            reason:
                'Plotki o wzmocnieniu wsparcia (${rumor.targetRiderName}) cieszą lidera zespołu.',
            triggeredByRumorId: rumor.id,
            date: date,
          ),
        );
      }
    }

    return impacts;
  }

  /// Aplikuje listę zmian morale i lojalności na niemutowalną listę zawodników.
  List<Rider> applyMoraleImpactsToRoster({
    required List<Rider> squad,
    required List<MoraleImpactEntry> impacts,
  }) {
    if (impacts.isEmpty) return squad;

    final impactByRider = <String, ({double morale, double loyalty})>{};
    for (final entry in impacts) {
      final prev = impactByRider[entry.riderId];
      impactByRider[entry.riderId] = (
        morale: (prev?.morale ?? 0.0) + entry.deltaMorale,
        loyalty: (prev?.loyalty ?? 0.0) + entry.deltaLoyalty,
      );
    }

    return squad.map((rider) {
      final delta = impactByRider[rider.id];
      if (delta == null) return rider;
      final nextMorale =
          (rider.contract.morale + delta.morale).clamp(0.0, 100.0);
      final nextLoyalty =
          (rider.contract.leaderLoyalty + delta.loyalty).clamp(0.0, 100.0);
      return rider.copyWith(
        contract: rider.contract.copyWith(
          morale: nextMorale,
          leaderLoyalty: nextLoyalty,
        ),
      );
    }).toList(growable: false);
  }

  /// Zwraca bonus negocjacyjny (0.0 - 15.0 pkt) dla prawdziwego celu transferowego,
  /// jeśli aktywna zasłona dymna skutecznie odwraca uwagę rywali.
  double calculateSmokescreenNegotiationBonus({
    required TransferRumorMillState state,
    required String targetRiderId,
  }) {
    var totalBonus = 0.0;
    for (final smoke in state.activeSmokescreens) {
      if (smoke.objective == SmokescreenObjective.protectRealTarget &&
          smoke.realTargetRiderId == targetRiderId) {
        totalBonus += smoke.mediaDistractionPct * 0.14;
      } else if (smoke.objective == SmokescreenObjective.divertMediaPressure) {
        totalBonus += smoke.mediaDistractionPct * 0.05;
      }
    }
    return totalBonus.clamp(0.0, 15.0);
  }

  bool _isRoleThreatenedByRumor(
    Rider rider,
    TransferRumor rumor,
    String playerTeamId,
  ) {
    if (rumor.rumoredDestinationTeamId != playerTeamId) return false;
    if (rider.id == rumor.targetRiderId) return false;

    final incoming = rumor.targetRiderRole;
    final current = rider.contract.role;

    if (incoming == current &&
        (current == RiderRole.teamLeader ||
            current == RiderRole.coLeader ||
            current == RiderRole.sprinter)) {
      return true;
    }
    if (incoming == RiderRole.teamLeader && current == RiderRole.coLeader) {
      return true;
    }
    return false;
  }

  CyclingJournalist? _findJournalist(
    List<CyclingJournalist> journalists,
    String journalistId,
  ) {
    for (final j in journalists) {
      if (j.id == journalistId) return j;
    }
    return null;
  }

  TransferRumor? _generateOrganicRumor({
    required math.Random rng,
    required DateTime currentDate,
    required List<CyclingJournalist> journalists,
    required CyclingTeam playerTeam,
    required List<Rider> playerSquad,
    required List<CyclingTeam> allTeams,
    required List<Rider> marketRiders,
    required List<TransferRumor> existingActiveRumors,
  }) {
    final journalist = journalists[rng.nextInt(journalists.length)];
    final involvePlayer = rng.nextDouble() < 0.65;

    Rider? chosenRider;
    String sourceTeamId = 'free_agent';
    String sourceTeamName = 'Wolny Agent';
    String destTeamId = playerTeam.id;
    String destTeamName = playerTeam.name;

    final rivalTeams =
        allTeams.where((t) => t.id != playerTeam.id).toList(growable: false);

    if (involvePlayer && playerSquad.isNotEmpty && rng.nextDouble() < 0.38 && rivalTeams.isNotEmpty) {
      // Kolarz gracza łączony z odejściem (preferowani z wygasającym kontraktem lub niższym morale)
      final sorted = List<Rider>.from(playerSquad)
        ..sort((a, b) => a.contract.morale.compareTo(b.contract.morale));
      chosenRider = sorted[rng.nextInt(math.min(3, sorted.length))];
      sourceTeamId = playerTeam.id;
      sourceTeamName = playerTeam.name;
      final dest = rivalTeams[rng.nextInt(rivalTeams.length)];
      destTeamId = dest.id;
      destTeamName = dest.name;
    } else {
      // Kolarz z rynku łączony z drużyną gracza lub rywalem
      final pool = marketRiders
          .where((r) =>
              !existingActiveRumors.any((er) => er.targetRiderId == r.id))
          .toList(growable: false);
      if (pool.isEmpty) return null;
      chosenRider = pool[rng.nextInt(pool.length)];
      sourceTeamId = chosenRider.contract.teamId;
      sourceTeamName = allTeams
          .where((t) => t.id == sourceTeamId)
          .map((t) => t.name)
          .firstOrNull ??
          'Rynek Transferowy';

      if (involvePlayer) {
        destTeamId = playerTeam.id;
        destTeamName = playerTeam.name;
      } else if (rivalTeams.isNotEmpty) {
        final dest = rivalTeams[rng.nextInt(rivalTeams.length)];
        destTeamId = dest.id;
        destTeamName = dest.name;
      }
    }

    final veracity = _rollVeracity(rng, journalist);
    final salaryEst =
        (chosenRider.contract.annualSalaryEur * (1.05 + rng.nextDouble() * 0.35))
            .round()
            .clamp(50000, 9000000);

    final isOutgoingFromPlayer = sourceTeamId == playerTeam.id;
    final headline = isOutgoingFromPlayer
        ? 'Przeciek: ${chosenRider.fullName} na celowniku $destTeamName!'
        : '$destTeamName sonduje transfer ${chosenRider.fullName}';

    final body =
        'Według ${journalist.name} (${journalist.affiliation.displayName}) '
        '${chosenRider.fullName} (${chosenRider.contract.role.label}) prowadzi '
        'rozmowy z $destTeamName. Szacowana wartość umowy: '
        '${(salaryEst / 1000).round()} tys. EUR/rok.';

    return TransferRumor(
      id: 'rumor_${currentDate.millisecondsSinceEpoch}_${chosenRider.id}',
      targetRiderId: chosenRider.id,
      targetRiderName: chosenRider.fullName,
      targetRiderRole: chosenRider.contract.role,
      sourceTeamId: sourceTeamId,
      sourceTeamName: sourceTeamName,
      rumoredDestinationTeamId: destTeamId,
      rumoredDestinationTeamName: destTeamName,
      journalistId: journalist.id,
      journalistName: journalist.name,
      journalistHandle: journalist.handle,
      credibilityAtPublish: journalist.credibilityRating,
      veracity: veracity,
      status: RumorStatus.active,
      playerResponse: RumorActionType.none,
      headline: headline,
      body: body,
      createdDate: currentDate,
      expiresDate: currentDate.add(Duration(days: 5 + rng.nextInt(6))),
      isPlayerTeamInvolved:
          destTeamId == playerTeam.id || sourceTeamId == playerTeam.id,
      estimatedSalaryEur: salaryEst,
      marketHeatDelta: 4 + (journalist.reachScore ~/ 20),
    );
  }

  RumorVeracityTier _rollVeracity(
    math.Random rng,
    CyclingJournalist journalist,
  ) {
    final score = journalist.credibilityRating + rng.nextInt(25) - 12;
    if (score >= 88) return RumorVeracityTier.confirmedLeak;
    if (score >= 70) return RumorVeracityTier.credible;
    if (score >= 50) return RumorVeracityTier.speculative;
    return RumorVeracityTier.baseless;
  }

  String _buildSmokescreenHeadline({
    required String decoyName,
    required String teamName,
    required SmokescreenObjective objective,
  }) {
    switch (objective) {
      case SmokescreenObjective.protectRealTarget:
        return 'BREAKING: $teamName blisko sensacyjnego podpisania $decoyName?';
      case SmokescreenObjective.inflateRivalCost:
        return 'Licytacja o $decoyName! $teamName wchodzi do gry z wysoką ofertą';
      case SmokescreenObjective.divertMediaPressure:
        return 'Nowy lider w $teamName? Przeciek ws. $decoyName rozgrzewa media';
      case SmokescreenObjective.testLockerRoomLoyalty:
        return 'Czy $decoyName zastąpi obecnego lidera $teamName?';
    }
  }
}

/// Kontroler stanu Riverpod dla systemu Transfer Rumor Mill.
class TransferRumorMillNotifier extends StateNotifier<TransferRumorMillState> {
  final TransferRumorMillAndJournalistsService _service;

  TransferRumorMillNotifier({
    TransferRumorMillAndJournalistsService? service,
    TransferRumorMillState? initialState,
  })  : _service = service ?? const TransferRumorMillAndJournalistsService(),
        super(initialState ?? TransferRumorMillState.initial());

  DailyRumorTickResult tickDaily({
    required DateTime currentDate,
    required CyclingTeam playerTeam,
    required List<Rider> playerSquad,
    required List<CyclingTeam> allTeams,
    required List<Rider> marketRiders,
    int? randomSeed,
  }) {
    final result = _service.tickDailyRumorMill(
      currentState: state,
      currentDate: currentDate,
      playerTeam: playerTeam,
      playerSquad: playerSquad,
      allTeams: allTeams,
      marketRiders: marketRiders,
      randomSeed: randomSeed,
    );
    state = result.nextState;
    return result;
  }

  RumorResponseOutcome respond({
    required String rumorId,
    required RumorActionType action,
    required CyclingTeam playerTeam,
    required List<Rider> playerSquad,
    required DateTime currentDate,
  }) {
    final res = _service.respondToRumor(
      currentState: state,
      rumorId: rumorId,
      action: action,
      playerTeam: playerTeam,
      playerSquad: playerSquad,
      currentDate: currentDate,
    );
    state = res.nextState;
    return res.outcome;
  }

  ({
    SmokescreenCampaign campaign,
    TransferRumor plantedRumor,
    List<MoraleImpactEntry> moraleImpacts,
    List<Rider> updatedSquad,
  }) launchSmokescreen({
    required DateTime currentDate,
    required CyclingTeam playerTeam,
    required List<Rider> playerSquad,
    required Rider decoyRider,
    Rider? realTargetRider,
    required String decoyCurrentTeamName,
    required CyclingJournalist journalist,
    required SmokescreenObjective objective,
    int durationDays = 10,
  }) {
    final res = _service.plantSmokescreen(
      currentState: state,
      currentDate: currentDate,
      playerTeam: playerTeam,
      playerSquad: playerSquad,
      decoyRider: decoyRider,
      realTargetRider: realTargetRider,
      decoyCurrentTeamName: decoyCurrentTeamName,
      journalist: journalist,
      objective: objective,
      durationDays: durationDays,
    );
    state = res.nextState;
    return (
      campaign: res.campaign,
      plantedRumor: res.plantedRumor,
      moraleImpacts: res.moraleImpacts,
      updatedSquad: res.updatedSquad,
    );
  }

  void resetState() {
    state = TransferRumorMillState.initial();
  }
}

final transferRumorMillProvider =
    StateNotifierProvider<TransferRumorMillNotifier, TransferRumorMillState>(
  (ref) => TransferRumorMillNotifier(),
);

enum _RumorPanelTab { rumors, smokescreen, journalists, morale }

/// Responsywny panel zarządzania systemem Transfer Rumor Mill, dziennikarzami i zasłoną dymną.
class TransferRumorMillPanel extends ConsumerStatefulWidget {
  final CyclingTeam? playerTeam;
  final List<Rider> playerSquad;
  final List<Rider> marketCandidates;
  final DateTime? currentDate;
  final ValueChanged<List<Rider>>? onSquadUpdated;

  const TransferRumorMillPanel({
    super.key,
    this.playerTeam,
    this.playerSquad = const [],
    this.marketCandidates = const [],
    this.currentDate,
    this.onSquadUpdated,
  });

  @override
  ConsumerState<TransferRumorMillPanel> createState() =>
      _TransferRumorMillPanelState();
}

class _TransferRumorMillPanelState
    extends ConsumerState<TransferRumorMillPanel> {
  _RumorPanelTab _activeTab = _RumorPanelTab.rumors;
  String? _selectedDecoyId;
  String? _selectedRealTargetId;
  String? _selectedJournalistId;
  SmokescreenObjective _selectedObjective =
      SmokescreenObjective.protectRealTarget;
  String? _feedbackBanner;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferRumorMillProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(state, isCompact),
              const SizedBox(height: 14),
              _buildTabBar(isCompact),
              if (_feedbackBanner != null) ...[
                const SizedBox(height: 12),
                _buildFeedbackBanner(_feedbackBanner!),
              ],
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: _buildActiveTabContent(
                  state: state,
                  isCompact: isCompact,
                  isTablet: isTablet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(TransferRumorMillState state, bool isCompact) {
    final metrics = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _MetricPill(
          label: 'Wiarygodność',
          value: '${state.mediaCredibilityScore}%',
          color: state.mediaCredibilityScore >= 70
              ? AppColors.statusSuccess
              : AppColors.amberWarning,
        ),
        _MetricPill(
          label: 'Temperatura Rynku',
          value: '${state.marketHeatIndex}/100',
          color: state.marketHeatIndex >= 70
              ? AppColors.crimsonAlert
              : AppColors.accentBlue,
        ),
        _MetricPill(
          label: 'Zasłony Dymne',
          value: '${state.activeSmokescreens.length}',
          color: AppColors.goldAccent,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer Rumor Mill',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Przecieki transferowe, dziennikarze i zasłony dymne',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          metrics,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer Rumor Mill & Przecieki',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Zarządzaj plotkami, relacjami z prasą i reakcją szatni',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        metrics,
      ],
    );
  }

  Widget _buildTabBar(bool isCompact) {
    final tabs = [
      (_RumorPanelTab.rumors, 'Przecieki', Icons.newspaper_rounded),
      (_RumorPanelTab.smokescreen, 'Zasłona Dymna', Icons.visibility_off_rounded),
      (_RumorPanelTab.journalists, 'Dziennikarze', Icons.mic_rounded),
      (_RumorPanelTab.morale, 'Morale Szatni', Icons.groups_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _InteractiveChipButton(
              label: tab.$2,
              icon: tab.$3,
              selected: isSelected,
              compact: isCompact,
              onPressed: () => setState(() => _activeTab = tab.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.goldAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _feedbackBanner = null),
            icon: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.textSecondary),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent({
    required TransferRumorMillState state,
    required bool isCompact,
    required bool isTablet,
  }) {
    switch (_activeTab) {
      case _RumorPanelTab.rumors:
        return _buildRumorsTab(state, isCompact);
      case _RumorPanelTab.smokescreen:
        return _buildSmokescreenTab(state, isCompact, isTablet);
      case _RumorPanelTab.journalists:
        return _buildJournalistsTab(state, isCompact, isTablet);
      case _RumorPanelTab.morale:
        return _buildMoraleTab(state);
    }
  }

  Widget _buildRumorsTab(TransferRumorMillState state, bool isCompact) {
    if (state.activeRumors.isEmpty) {
      return const _EmptyStateCard(
        key: ValueKey('empty_rumors'),
        icon: Icons.campaign_outlined,
        title: 'Cisza na rynku transferowym',
        subtitle:
            'Brak aktywnych przecieków. Rozbuduj zasłonę dymną lub poczekaj na kolejne doniesienia dziennikarzy.',
      );
    }

    return Column(
      key: const ValueKey('rumors_list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.activeRumors.map((rumor) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RumorCard(
            rumor: rumor,
            isCompact: isCompact,
            canAct: rumor.isActionable && widget.playerTeam != null,
            onAction: (action) => _handleRumorAction(rumor, action),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmokescreenTab(
    TransferRumorMillState state,
    bool isCompact,
    bool isTablet,
  ) {
    final candidates = widget.marketCandidates;
    final journalists = state.journalists;
    final canLaunch = widget.playerTeam != null &&
        candidates.isNotEmpty &&
        journalists.isNotEmpty &&
        _selectedDecoyId != null &&
        _selectedJournalistId != null;

    final selectedDecoy = candidates
        .where((r) => r.id == _selectedDecoyId)
        .firstOrNull ??
        candidates.firstOrNull;
    final selectedJournalist = journalists
        .where((j) => j.id == _selectedJournalistId)
        .firstOrNull ??
        journalists.firstOrNull;

    if (_selectedDecoyId == null && selectedDecoy != null) {
      _selectedDecoyId = selectedDecoy.id;
    }
    if (_selectedJournalistId == null && selectedJournalist != null) {
      _selectedJournalistId = selectedJournalist.id;
    }

    return Container(
      key: const ValueKey('smokescreen_tab'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfigurator Zasłony Dymnej',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedObjective.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (candidates.isEmpty)
            const Text(
              'Brak dostępnych kandydatów z rynku do stworzenia przynęty.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.amberWarning,
              ),
            )
          else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isCompact ? double.infinity : (isTablet ? 260 : 300),
                  child: _DarkDropdownField<String>(
                    label: 'Cel-przynęta (Zasłona)',
                    value: _selectedDecoyId,
                    items: candidates
                        .map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                '${r.fullName} (${r.contract.role.label})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDecoyId = v),
                  ),
                ),
                SizedBox(
                  width: isCompact ? double.infinity : (isTablet ? 260 : 300),
                  child: _DarkDropdownField<String?>(
                    label: 'Prawdziwy cel (opcjonalnie)',
                    value: _selectedRealTargetId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Brak konkretnego celu'),
                      ),
                      ...candidates
                          .where((r) => r.id != _selectedDecoyId)
                          .map((r) => DropdownMenuItem<String?>(
                                value: r.id,
                                child: Text(
                                  r.fullName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                    ],
                    onChanged: (v) => setState(() => _selectedRealTargetId = v),
                  ),
                ),
                SizedBox(
                  width: isCompact ? double.infinity : (isTablet ? 260 : 300),
                  child: _DarkDropdownField<String>(
                    label: 'Dziennikarz do przecieku',
                    value: _selectedJournalistId,
                    items: journalists
                        .map((j) => DropdownMenuItem(
                              value: j.id,
                              child: Text(
                                '${j.name} (${j.reachScore} zasięgu)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedJournalistId = v),
                  ),
                ),
                SizedBox(
                  width: isCompact ? double.infinity : (isTablet ? 260 : 300),
                  child: _DarkDropdownField<SmokescreenObjective>(
                    label: 'Cel strategiczny',
                    value: _selectedObjective,
                    items: SmokescreenObjective.values
                        .map((o) => DropdownMenuItem(
                              value: o,
                              child: Text(o.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedObjective = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PrimaryActionButton(
              label: 'Wypuść Przeciek (Zasłona Dymna)',
              icon: Icons.send_rounded,
              enabled: canLaunch,
              onPressed: canLaunch
                  ? () => _launchSmokescreen(
                        decoy: selectedDecoy!,
                        realTarget: candidates
                            .where((r) => r.id == _selectedRealTargetId)
                            .firstOrNull,
                        journalist: selectedJournalist!,
                      )
                  : null,
            ),
          ],
          if (state.activeSmokescreens.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Aktywne Kampanie Dezinformacyjne',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...state.activeSmokescreens.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off_rounded,
                        color: AppColors.goldAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Przynęta: ${s.decoyRiderName} (${s.objective.label})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Skuteczność: ${s.mediaDistractionPct.round()}% • Pozostało: ${s.remainingDays} dni',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJournalistsTab(
    TransferRumorMillState state,
    bool isCompact,
    bool isTablet,
  ) {
    final crossAxisCount = isCompact ? 1 : (isTablet ? 2 : 3);
    return GridView.builder(
      key: const ValueKey('journalists_grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 152,
      ),
      itemCount: state.journalists.length,
      itemBuilder: (context, index) {
        final j = state.journalists[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      j.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      j.affiliation.displayName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${j.handle} • ${j.archetype.label}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniStat(
                      label: 'Wiaryg.', value: '${j.credibilityRating}'),
                  _MiniStat(label: 'Zasięg', value: '${j.reachScore}'),
                  _MiniStat(
                    label: 'Relacja',
                    value:
                        '${j.relationshipWithPlayer >= 0 ? '+' : ''}${j.relationshipWithPlayer}',
                    color: j.relationshipWithPlayer >= 0
                        ? AppColors.statusSuccess
                        : AppColors.crimsonAlert,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoraleTab(TransferRumorMillState state) {
    if (state.moraleHistory.isEmpty) {
      return const _EmptyStateCard(
        key: ValueKey('empty_morale'),
        icon: Icons.sentiment_satisfied_alt_rounded,
        title: 'Spokój w szatni',
        subtitle:
            'Żadna z plotek transferowych nie wpłynęła jeszcze na morale ani lojalność zawodników.',
      );
    }

    return Column(
      key: const ValueKey('morale_list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.moraleHistory.take(15).map((entry) {
        final positive = entry.deltaMorale >= 0;
        final color =
            positive ? AppColors.statusSuccess : AppColors.crimsonAlert;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Icon(
                positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.riderName} (${entry.riderRole.label})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.reason,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${positive ? '+' : ''}${entry.deltaMorale.toStringAsFixed(1)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _handleRumorAction(TransferRumor rumor, RumorActionType action) {
    final team = widget.playerTeam;
    if (team == null) return;
    final outcome = ref.read(transferRumorMillProvider.notifier).respond(
          rumorId: rumor.id,
          action: action,
          playerTeam: team,
          playerSquad: widget.playerSquad,
          currentDate: widget.currentDate ?? DateTime.now(),
        );
    widget.onSquadUpdated?.call(outcome.updatedSquad);
    setState(() => _feedbackBanner = outcome.summaryMessage);
  }

  void _launchSmokescreen({
    required Rider decoy,
    Rider? realTarget,
    required CyclingJournalist journalist,
  }) {
    final team = widget.playerTeam;
    if (team == null) return;
    final res = ref.read(transferRumorMillProvider.notifier).launchSmokescreen(
          currentDate: widget.currentDate ?? DateTime.now(),
          playerTeam: team,
          playerSquad: widget.playerSquad,
          decoyRider: decoy,
          realTargetRider: realTarget,
          decoyCurrentTeamName: decoy.contract.teamId,
          journalist: journalist,
          objective: _selectedObjective,
        );
    widget.onSquadUpdated?.call(res.updatedSquad);
    setState(() {
      _feedbackBanner =
          'Zasłona dymna ws. ${decoy.fullName} wypuszczona przez ${journalist.handle}.';
      _activeTab = _RumorPanelTab.rumors;
    });
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
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

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  const _InteractiveChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent
        : (_pressed
            ? AppColors.surfaceLight
            : (_hovered ? AppColors.surfaceLight : AppColors.surface));
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : (_focused ? AppColors.accentBlue : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RumorCard extends StatelessWidget {
  final TransferRumor rumor;
  final bool isCompact;
  final bool canAct;
  final ValueChanged<RumorActionType> onAction;

  const _RumorCard({
    required this.rumor,
    required this.isCompact,
    required this.canAct,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rumor.veracity.badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: rumor.veracity.badgeColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  rumor.veracity.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rumor.veracity.badgeColor,
                  ),
                ),
              ),
              Text(
                '${rumor.journalistName} (${rumor.journalistHandle})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                ),
              ),
              Text(
                '• Wiarygodność: ${rumor.credibilityAtPublish}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rumor.headline,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rumor.body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (canAct) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PrimaryActionButton(
                  label: 'Zdementuj',
                  icon: Icons.cancel_outlined,
                  enabled: true,
                  onPressed: () => onAction(RumorActionType.deny),
                ),
                _PrimaryActionButton(
                  label: 'Potwierdź',
                  icon: Icons.check_circle_outline_rounded,
                  enabled: true,
                  accent: AppColors.statusSuccess,
                  onPressed: () => onAction(RumorActionType.confirm),
                ),
                _PrimaryActionButton(
                  label: 'Bez komentarza',
                  icon: Icons.more_horiz_rounded,
                  enabled: true,
                  accent: AppColors.textSecondary,
                  onPressed: () => onAction(RumorActionType.noComment),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color? accent;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    this.accent,
    this.onPressed,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseAccent = widget.accent ?? AppColors.primaryAccent;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseAccent.withValues(alpha: 0.85)
            : (_hovered
                ? baseAccent.withValues(alpha: 0.35)
                : baseAccent.withValues(alpha: 0.2)));
    final borderColor = !widget.enabled
        ? AppTheme.borderColor
        : (_focused ? AppColors.goldAccent : baseAccent.withValues(alpha: 0.7));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              widget.enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DarkDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.goldAccent),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
