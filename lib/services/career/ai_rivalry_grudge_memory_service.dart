// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Poziom relacji między dwoma kolarzami w peletonie w skali od -100 do +100.
enum PelotonRelationshipPolarity {
  bloodFeud,
  activeGrudge,
  coldFriction,
  neutral,
  mutualRespect,
  trustedAlly,
  pelotonBrotherhood;

  String toJson() => name;

  static PelotonRelationshipPolarity fromJson(String value) {
    return PelotonRelationshipPolarity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PelotonRelationshipPolarity.neutral,
    );
  }

  /// Wyznacza kategorię relacji na podstawie punktacji [-100.0, 100.0].
  static PelotonRelationshipPolarity fromScore(double score) {
    if (score <= -65.0) return PelotonRelationshipPolarity.bloodFeud;
    if (score <= -25.0) return PelotonRelationshipPolarity.activeGrudge;
    if (score <= -5.0) return PelotonRelationshipPolarity.coldFriction;
    if (score < 5.0) return PelotonRelationshipPolarity.neutral;
    if (score < 25.0) return PelotonRelationshipPolarity.mutualRespect;
    if (score < 65.0) return PelotonRelationshipPolarity.trustedAlly;
    return PelotonRelationshipPolarity.pelotonBrotherhood;
  }

  String get label {
    switch (this) {
      case PelotonRelationshipPolarity.bloodFeud:
        return 'Krwawa Wendeta';
      case PelotonRelationshipPolarity.activeGrudge:
        return 'Głęboki Uraz';
      case PelotonRelationshipPolarity.coldFriction:
        return 'Chłodny Dystans';
      case PelotonRelationshipPolarity.neutral:
        return 'Neutralność';
      case PelotonRelationshipPolarity.mutualRespect:
        return 'Wzajemny Szacunek';
      case PelotonRelationshipPolarity.trustedAlly:
        return 'Zaufany Sojusznik';
      case PelotonRelationshipPolarity.pelotonBrotherhood:
        return 'Braterstwo Szosy';
    }
  }

  String get shortLabel {
    switch (this) {
      case PelotonRelationshipPolarity.bloodFeud:
        return 'Wendeta';
      case PelotonRelationshipPolarity.activeGrudge:
        return 'Uraz';
      case PelotonRelationshipPolarity.coldFriction:
        return 'Tarcie';
      case PelotonRelationshipPolarity.neutral:
        return 'Neutral';
      case PelotonRelationshipPolarity.mutualRespect:
        return 'Szacunek';
      case PelotonRelationshipPolarity.trustedAlly:
        return 'Sojusznik';
      case PelotonRelationshipPolarity.pelotonBrotherhood:
        return 'Braterstwo';
    }
  }

  Color get accentColor {
    switch (this) {
      case PelotonRelationshipPolarity.bloodFeud:
        return AppColors.crimsonAlert;
      case PelotonRelationshipPolarity.activeGrudge:
        return AppColors.primaryAccent;
      case PelotonRelationshipPolarity.coldFriction:
        return AppColors.amberWarning;
      case PelotonRelationshipPolarity.neutral:
        return AppColors.textSecondary;
      case PelotonRelationshipPolarity.mutualRespect:
        return AppColors.accentBlue;
      case PelotonRelationshipPolarity.trustedAlly:
        return AppColors.statusSuccess;
      case PelotonRelationshipPolarity.pelotonBrotherhood:
        return AppColors.goldAccent;
    }
  }

  IconData get icon {
    switch (this) {
      case PelotonRelationshipPolarity.bloodFeud:
        return Icons.local_fire_department_rounded;
      case PelotonRelationshipPolarity.activeGrudge:
        return Icons.warning_amber_rounded;
      case PelotonRelationshipPolarity.coldFriction:
        return Icons.ac_unit_rounded;
      case PelotonRelationshipPolarity.neutral:
        return Icons.remove_circle_outline_rounded;
      case PelotonRelationshipPolarity.mutualRespect:
        return Icons.thumb_up_alt_outlined;
      case PelotonRelationshipPolarity.trustedAlly:
        return Icons.handshake_rounded;
      case PelotonRelationshipPolarity.pelotonBrotherhood:
        return Icons.workspace_premium_rounded;
    }
  }

  bool get isNegative =>
      this == PelotonRelationshipPolarity.bloodFeud ||
      this == PelotonRelationshipPolarity.activeGrudge ||
      this == PelotonRelationshipPolarity.coldFriction;

  bool get isPositive =>
      this == PelotonRelationshipPolarity.mutualRespect ||
      this == PelotonRelationshipPolarity.trustedAlly ||
      this == PelotonRelationshipPolarity.pelotonBrotherhood;
}

/// Typ zdarzenia szosowego lub medialnego zapisywanego w pamięci długoterminowej.
enum RelationshipIncidentType {
  breakawayBetrayal,
  dangerousSprintDeviation,
  unprovokedChaseDown,
  gcLeaderAttackInFeedZone,
  wheelsuckingSteal,
  publicMediaInsult,
  sharedBreakawayWork,
  bottleOrWheelShare,
  formerTeammateBond,
  sportsmanlikeWaitAfterCrash,
  leadoutFavor,
  podiumRespect;

  String toJson() => name;

  static RelationshipIncidentType fromJson(String value) {
    return RelationshipIncidentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RelationshipIncidentType.sharedBreakawayWork,
    );
  }

  String get label {
    switch (this) {
      case RelationshipIncidentType.breakawayBetrayal:
        return 'Zdrada w ucieczce';
      case RelationshipIncidentType.dangerousSprintDeviation:
        return 'Zajechanie drogi w sprincie';
      case RelationshipIncidentType.unprovokedChaseDown:
        return 'Skasowanie ataku bez powodu';
      case RelationshipIncidentType.gcLeaderAttackInFeedZone:
        return 'Atak w strefie bufetu / po defekcie';
      case RelationshipIncidentType.wheelsuckingSteal:
        return 'Jazda na kole i ogranie na mecie';
      case RelationshipIncidentType.publicMediaInsult:
        return 'Ostra krytyka w mediach';
      case RelationshipIncidentType.sharedBreakawayWork:
        return 'Harmonijna praca w odjeździe';
      case RelationshipIncidentType.bottleOrWheelShare:
        return 'Oddanie koła lub bidonu w kryzysie';
      case RelationshipIncidentType.formerTeammateBond:
        return 'Więź byłych kolegów z drużyny';
      case RelationshipIncidentType.sportsmanlikeWaitAfterCrash:
        return 'Fair play — poczekanie po kraksie';
      case RelationshipIncidentType.leadoutFavor:
        return 'Osłona przed wiatrem / rozprowadzenie';
      case RelationshipIncidentType.podiumRespect:
        return 'Publiczne uznanie po etapie';
    }
  }

  /// Domyślna zmiana punktacji relacji dla danego typu zdarzenia.
  double get defaultScoreDelta {
    switch (this) {
      case RelationshipIncidentType.breakawayBetrayal:
        return -28.0;
      case RelationshipIncidentType.dangerousSprintDeviation:
        return -36.0;
      case RelationshipIncidentType.unprovokedChaseDown:
        return -18.0;
      case RelationshipIncidentType.gcLeaderAttackInFeedZone:
        return -32.0;
      case RelationshipIncidentType.wheelsuckingSteal:
        return -22.0;
      case RelationshipIncidentType.publicMediaInsult:
        return -15.0;
      case RelationshipIncidentType.sharedBreakawayWork:
        return 16.0;
      case RelationshipIncidentType.bottleOrWheelShare:
        return 26.0;
      case RelationshipIncidentType.formerTeammateBond:
        return 22.0;
      case RelationshipIncidentType.sportsmanlikeWaitAfterCrash:
        return 30.0;
      case RelationshipIncidentType.leadoutFavor:
        return 20.0;
      case RelationshipIncidentType.podiumRespect:
        return 12.0;
    }
  }

  bool get isGrudgeEvent => defaultScoreDelta < 0;
}

/// Pojedyncze zapamiętane zdarzenie z historii relacji między dwoma kolarzami.
class PelotonMemoryEvent {
  final String id;
  final int seasonYear;
  final int? stageNumber;
  final String raceId;
  final String raceName;
  final RelationshipIncidentType incidentType;
  final double scoreDelta;
  final String description;
  final DateTime recordedAt;
  final bool isHistoricalArchive;

  const PelotonMemoryEvent({
    required this.id,
    required this.seasonYear,
    this.stageNumber,
    required this.raceId,
    required this.raceName,
    required this.incidentType,
    required this.scoreDelta,
    required this.description,
    required this.recordedAt,
    this.isHistoricalArchive = false,
  });

  PelotonMemoryEvent copyWith({
    String? id,
    int? seasonYear,
    int? stageNumber,
    String? raceId,
    String? raceName,
    RelationshipIncidentType? incidentType,
    double? scoreDelta,
    String? description,
    DateTime? recordedAt,
    bool? isHistoricalArchive,
  }) {
    return PelotonMemoryEvent(
      id: id ?? this.id,
      seasonYear: seasonYear ?? this.seasonYear,
      stageNumber: stageNumber ?? this.stageNumber,
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      incidentType: incidentType ?? this.incidentType,
      scoreDelta: scoreDelta ?? this.scoreDelta,
      description: description ?? this.description,
      recordedAt: recordedAt ?? this.recordedAt,
      isHistoricalArchive: isHistoricalArchive ?? this.isHistoricalArchive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonYear': seasonYear,
      'stageNumber': stageNumber,
      'raceId': raceId,
      'raceName': raceName,
      'incidentType': incidentType.toJson(),
      'scoreDelta': scoreDelta,
      'description': description,
      'recordedAt': recordedAt.toIso8601String(),
      'isHistoricalArchive': isHistoricalArchive,
    };
  }

  factory PelotonMemoryEvent.fromJson(Map<String, dynamic> json) {
    return PelotonMemoryEvent(
      id: json['id'] as String? ?? '',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      stageNumber: (json['stageNumber'] as num?)?.toInt(),
      raceId: json['raceId'] as String? ?? 'unknown_race',
      raceName: json['raceName'] as String? ?? 'Wyścig UCI',
      incidentType: RelationshipIncidentType.fromJson(
        json['incidentType'] as String? ?? 'sharedBreakawayWork',
      ),
      scoreDelta: (json['scoreDelta'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime(2026, 1, 1),
      isHistoricalArchive: json['isHistoricalArchive'] as bool? ?? false,
    );
  }
}

/// Długoterminowa więź (uraz lub przyjaźń) pomiędzy parą kolarzy.
class RiderRelationshipBond {
  final String bondKey;
  final String riderAId;
  final String riderBId;
  final String riderAName;
  final String riderBName;
  final String riderATeam;
  final String riderBTeam;
  final double score; // [-100.0, +100.0]
  final List<PelotonMemoryEvent> events;
  final DateTime lastInteractionDate;
  final int lastSeasonYear;
  final int totalGrudgeIncidents;
  final int totalFriendshipIncidents;

  const RiderRelationshipBond({
    required this.bondKey,
    required this.riderAId,
    required this.riderBId,
    required this.riderAName,
    required this.riderBName,
    required this.riderATeam,
    required this.riderBTeam,
    required this.score,
    required this.events,
    required this.lastInteractionDate,
    required this.lastSeasonYear,
    required this.totalGrudgeIncidents,
    required this.totalFriendshipIncidents,
  });

  PelotonRelationshipPolarity get polarity =>
      PelotonRelationshipPolarity.fromScore(score);

  bool get vendettaActive => score <= -50.0;

  bool get alliancePactReady => score >= 45.0;

  bool involvesRider(String riderId) =>
      riderAId == riderId || riderBId == riderId;

  String counterpartyNameFor(String riderId) =>
      riderAId == riderId ? riderBName : riderAName;

  String counterpartyIdFor(String riderId) =>
      riderAId == riderId ? riderBId : riderAId;

  RiderRelationshipBond copyWith({
    String? bondKey,
    String? riderAId,
    String? riderBId,
    String? riderAName,
    String? riderBName,
    String? riderATeam,
    String? riderBTeam,
    double? score,
    List<PelotonMemoryEvent>? events,
    DateTime? lastInteractionDate,
    int? lastSeasonYear,
    int? totalGrudgeIncidents,
    int? totalFriendshipIncidents,
  }) {
    return RiderRelationshipBond(
      bondKey: bondKey ?? this.bondKey,
      riderAId: riderAId ?? this.riderAId,
      riderBId: riderBId ?? this.riderBId,
      riderAName: riderAName ?? this.riderAName,
      riderBName: riderBName ?? this.riderBName,
      riderATeam: riderATeam ?? this.riderATeam,
      riderBTeam: riderBTeam ?? this.riderBTeam,
      score: score ?? this.score,
      events: events ?? this.events,
      lastInteractionDate: lastInteractionDate ?? this.lastInteractionDate,
      lastSeasonYear: lastSeasonYear ?? this.lastSeasonYear,
      totalGrudgeIncidents: totalGrudgeIncidents ?? this.totalGrudgeIncidents,
      totalFriendshipIncidents:
          totalFriendshipIncidents ?? this.totalFriendshipIncidents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bondKey': bondKey,
      'riderAId': riderAId,
      'riderBId': riderBId,
      'riderAName': riderAName,
      'riderBName': riderBName,
      'riderATeam': riderATeam,
      'riderBTeam': riderBTeam,
      'score': score,
      'events': events.map((e) => e.toJson()).toList(),
      'lastInteractionDate': lastInteractionDate.toIso8601String(),
      'lastSeasonYear': lastSeasonYear,
      'totalGrudgeIncidents': totalGrudgeIncidents,
      'totalFriendshipIncidents': totalFriendshipIncidents,
    };
  }

  factory RiderRelationshipBond.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>? ?? const [];
    return RiderRelationshipBond(
      bondKey: json['bondKey'] as String? ?? '',
      riderAId: json['riderAId'] as String? ?? '',
      riderBId: json['riderBId'] as String? ?? '',
      riderAName: json['riderAName'] as String? ?? 'Kolarz A',
      riderBName: json['riderBName'] as String? ?? 'Kolarz B',
      riderATeam: json['riderATeam'] as String? ?? 'Niezrzeszony',
      riderBTeam: json['riderBTeam'] as String? ?? 'Niezrzeszony',
      score: ((json['score'] as num?)?.toDouble() ?? 0.0).clamp(-100.0, 100.0),
      events: rawEvents
          .whereType<Map<String, dynamic>>()
          .map(PelotonMemoryEvent.fromJson)
          .toList(),
      lastInteractionDate:
          DateTime.tryParse(json['lastInteractionDate'] as String? ?? '') ??
              DateTime(2026, 1, 1),
      lastSeasonYear: (json['lastSeasonYear'] as num?)?.toInt() ?? 2026,
      totalGrudgeIncidents: (json['totalGrudgeIncidents'] as num?)?.toInt() ?? 0,
      totalFriendshipIncidents:
          (json['totalFriendshipIncidents'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Modyfikatory zachowań taktycznych AI wynikające z pamięci urazów i przyjaźni.
class AiRivalryTacticalModifiers {
  final double relationshipScore;
  final PelotonRelationshipPolarity polarity;
  final double chaseAggressionMultiplier; // 0.80 .. 1.45
  final double breakawayCooperationFactor; // 0.00 .. 1.00
  final double diplomacyAcceptanceBonus; // -0.50 .. +0.35
  final double sprintBlockingRisk; // 0.00 .. 0.35
  final bool transferVetoRisk;
  final double transferSalaryDiscountFactor; // 0.00 .. 0.12
  final String summaryLabel;

  const AiRivalryTacticalModifiers({
    required this.relationshipScore,
    required this.polarity,
    required this.chaseAggressionMultiplier,
    required this.breakawayCooperationFactor,
    required this.diplomacyAcceptanceBonus,
    required this.sprintBlockingRisk,
    required this.transferVetoRisk,
    required this.transferSalaryDiscountFactor,
    required this.summaryLabel,
  });

  static const AiRivalryTacticalModifiers neutral = AiRivalryTacticalModifiers(
    relationshipScore: 0.0,
    polarity: PelotonRelationshipPolarity.neutral,
    chaseAggressionMultiplier: 1.0,
    breakawayCooperationFactor: 0.65,
    diplomacyAcceptanceBonus: 0.0,
    sprintBlockingRisk: 0.02,
    transferVetoRisk: false,
    transferSalaryDiscountFactor: 0.0,
    summaryLabel: 'Standardowa rywalizacja sportowa bez osobistych zaszłości.',
  );
}

/// Raport z międzysezonowego wygaszania pamięci relacji.
class PelotonMemorySeasonDecayReport {
  final int fromSeasonYear;
  final int toSeasonYear;
  final int evaluatedBondsCount;
  final int archivedEventsCount;
  final int prunedNeutralBondsCount;
  final int survivingVendettasCount;
  final int survivingAlliancesCount;

  const PelotonMemorySeasonDecayReport({
    required this.fromSeasonYear,
    required this.toSeasonYear,
    required this.evaluatedBondsCount,
    required this.archivedEventsCount,
    required this.prunedNeutralBondsCount,
    required this.survivingVendettasCount,
    required this.survivingAlliancesCount,
  });
}

/// Audyt zgodności składu drużyny pod kątem ukrytych wendet i przyjaźni.
class TeamRosterCompatibilityReport {
  final double averagePairwiseScore;
  final double chemistryModifier; // -15.0 .. +15.0
  final List<RiderRelationshipBond> toxicConflicts;
  final List<RiderRelationshipBond> goldenDuos;

  const TeamRosterCompatibilityReport({
    required this.averagePairwiseScore,
    required this.chemistryModifier,
    required this.toxicConflicts,
    required this.goldenDuos,
  });
}

/// Pełny stan systemu długoterminowej pamięci urazów i przyjaźni.
class AiRivalryGrudgeMemoryState {
  final Map<String, RiderRelationshipBond> bonds;
  final int currentSeasonYear;
  final int totalRecordedEvents;
  final DateTime lastUpdatedAt;

  const AiRivalryGrudgeMemoryState({
    required this.bonds,
    required this.currentSeasonYear,
    required this.totalRecordedEvents,
    required this.lastUpdatedAt,
  });

  factory AiRivalryGrudgeMemoryState.empty({int seasonYear = 2026}) {
    return AiRivalryGrudgeMemoryState(
      bonds: const {},
      currentSeasonYear: seasonYear,
      totalRecordedEvents: 0,
      lastUpdatedAt: DateTime(seasonYear, 1, 1),
    );
  }

  int get activeVendettasCount =>
      bonds.values.where((b) => b.vendettaActive).length;

  int get activeAlliancesCount =>
      bonds.values.where((b) => b.alliancePactReady).length;

  int get activeGrudgesCount =>
      bonds.values.where((b) => b.polarity.isNegative).length;

  int get activeFriendshipsCount =>
      bonds.values.where((b) => b.polarity.isPositive).length;

  AiRivalryGrudgeMemoryState copyWith({
    Map<String, RiderRelationshipBond>? bonds,
    int? currentSeasonYear,
    int? totalRecordedEvents,
    DateTime? lastUpdatedAt,
  }) {
    return AiRivalryGrudgeMemoryState(
      bonds: bonds ?? this.bonds,
      currentSeasonYear: currentSeasonYear ?? this.currentSeasonYear,
      totalRecordedEvents: totalRecordedEvents ?? this.totalRecordedEvents,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentSeasonYear': currentSeasonYear,
      'totalRecordedEvents': totalRecordedEvents,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'bonds': bonds.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory AiRivalryGrudgeMemoryState.fromJson(Map<String, dynamic> json) {
    final rawBonds = json['bonds'] as Map<String, dynamic>? ?? const {};
    final parsedBonds = <String, RiderRelationshipBond>{};
    for (final entry in rawBonds.entries) {
      if (entry.value is Map<String, dynamic>) {
        parsedBonds[entry.key] =
            RiderRelationshipBond.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    return AiRivalryGrudgeMemoryState(
      bonds: parsedBonds,
      currentSeasonYear: (json['currentSeasonYear'] as num?)?.toInt() ?? 2026,
      totalRecordedEvents: (json['totalRecordedEvents'] as num?)?.toInt() ?? 0,
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt'] as String? ?? '') ??
              DateTime(2026, 1, 1),
    );
  }
}

/// Serwis zarządzający długoterminową pamięcią urazów i przyjaźni w peletonie.
class AiRivalryGrudgeMemoryService {
  const AiRivalryGrudgeMemoryService();

  /// Zwraca kanoniczny, symetryczny klucz pary kolarzy niezależny od kolejności ID.
  static String canonicalBondKey(String riderAId, String riderBId) {
    if (riderAId.compareTo(riderBId) <= 0) {
      return '${riderAId}__$riderBId';
    }
    return '${riderBId}__$riderAId';
  }

  /// Rejestruje nowy incydent szosowy lub medialny pomiędzy dwoma kolarzami.
  AiRivalryGrudgeMemoryState recordIncident(
    AiRivalryGrudgeMemoryState state, {
    required String riderAId,
    required String riderBId,
    required String riderAName,
    required String riderBName,
    required String riderATeam,
    required String riderBTeam,
    required RelationshipIncidentType incidentType,
    required String raceId,
    required String raceName,
    int? stageNumber,
    double? customScoreDelta,
    String? customDescription,
    DateTime? timestamp,
  }) {
    if (riderAId.trim().isEmpty ||
        riderBId.trim().isEmpty ||
        riderAId == riderBId) {
      return state;
    }

    final isASortedFirst = riderAId.compareTo(riderBId) <= 0;
    final firstId = isASortedFirst ? riderAId : riderBId;
    final secondId = isASortedFirst ? riderBId : riderAId;
    final firstName = isASortedFirst ? riderAName : riderBName;
    final secondName = isASortedFirst ? riderBName : riderAName;
    final firstTeam = isASortedFirst ? riderATeam : riderBTeam;
    final secondTeam = isASortedFirst ? riderBTeam : riderATeam;

    final key = canonicalBondKey(firstId, secondId);
    final now = timestamp ?? DateTime.now();
    final delta = customScoreDelta ?? incidentType.defaultScoreDelta;
    final existing = state.bonds[key];

    final event = PelotonMemoryEvent(
      id: '${key}_${state.totalRecordedEvents + 1}_${now.millisecondsSinceEpoch}',
      seasonYear: state.currentSeasonYear,
      stageNumber: stageNumber,
      raceId: raceId,
      raceName: raceName,
      incidentType: incidentType,
      scoreDelta: delta,
      description: customDescription ??
          '${incidentType.label} podczas $raceName'
              '${stageNumber != null ? ' (Etap $stageNumber)' : ''}.',
      recordedAt: now,
    );

    final updatedScore = ((existing?.score ?? 0.0) + delta).clamp(-100.0, 100.0);
    final isGrudge = delta < 0;
    final isFriendship = delta > 0;

    final updatedBond = RiderRelationshipBond(
      bondKey: key,
      riderAId: firstId,
      riderBId: secondId,
      riderAName: firstName,
      riderBName: secondName,
      riderATeam: firstTeam,
      riderBTeam: secondTeam,
      score: updatedScore,
      events: [event, ...?existing?.events].take(40).toList(),
      lastInteractionDate: now,
      lastSeasonYear: state.currentSeasonYear,
      totalGrudgeIncidents:
          (existing?.totalGrudgeIncidents ?? 0) + (isGrudge ? 1 : 0),
      totalFriendshipIncidents:
          (existing?.totalFriendshipIncidents ?? 0) + (isFriendship ? 1 : 0),
    );

    final nextBonds = Map<String, RiderRelationshipBond>.from(state.bonds)
      ..[key] = updatedBond;

    return state.copyWith(
      bonds: nextBonds,
      totalRecordedEvents: state.totalRecordedEvents + 1,
      lastUpdatedAt: now,
    );
  }

  /// Oblicza modyfikatory taktyczne AI w trakcie wyścigu, dyplomacji i transferów.
  AiRivalryTacticalModifiers evaluateTacticalModifiers(
    AiRivalryGrudgeMemoryState state, {
    required String observerRiderId,
    required String targetRiderId,
  }) {
    if (observerRiderId == targetRiderId) {
      return AiRivalryTacticalModifiers.neutral;
    }

    final key = canonicalBondKey(observerRiderId, targetRiderId);
    final bond = state.bonds[key];
    if (bond == null) {
      return AiRivalryTacticalModifiers.neutral;
    }

    final s = bond.score;
    final polarity = bond.polarity;

    // Agresja pościgowa: przy głębokim urazie AI spala dodatkowe W', by skasować rywala.
    final double chaseMultiplier;
    if (s <= -65.0) {
      chaseMultiplier = 1.45;
    } else if (s < 0) {
      chaseMultiplier = 1.0 + ((-s / 65.0) * 0.35);
    } else {
      chaseMultiplier = 1.0 - ((s / 100.0) * 0.20);
    }

    // Chęć dawania zmian w ucieczce: 0.05 przy wendecie, 0.98 przy braterstwie.
    final double cooperation =
        ((s + 100.0) / 200.0 * 0.93 + 0.05).clamp(0.05, 0.98);

    // Bonus do akceptacji paktów dyplomatycznych (InRacePelotonDiplomacyEngine).
    final double diplomacyBonus =
        s < 0 ? (s / 100.0) * 0.50 : (s / 100.0) * 0.35;

    // Ryzyko agresywnej obrony toru w sprincie.
    final double sprintBlockRisk =
        s < -20.0 ? ((-s - 20.0) / 80.0 * 0.33 + 0.02).clamp(0.02, 0.35) : 0.02;

    final bool transferVeto = s <= -60.0;
    final double salaryDiscount =
        s >= 60.0 ? ((s - 60.0) / 40.0 * 0.06 + 0.06).clamp(0.0, 0.12) : 0.0;

    final String summary;
    switch (polarity) {
      case PelotonRelationshipPolarity.bloodFeud:
        summary =
            'Otwarta wendeta: AI bezwzględnie kasuje ataki rywala, odmawia zmian i blokuje transfer do jednej ekipy.';
      case PelotonRelationshipPolarity.activeGrudge:
        summary =
            'Głęboki uraz: wzmożona agresja w pościgu i niska szansa na zawarcie paktu w ucieczce.';
      case PelotonRelationshipPolarity.coldFriction:
        summary =
            'Chłodne relacje: ograniczone zaufanie przy zmianach w odjeździe.';
      case PelotonRelationshipPolarity.neutral:
        summary =
            'Standardowa rywalizacja sportowa bez osobistych zaszłości.';
      case PelotonRelationshipPolarity.mutualRespect:
        summary =
            'Wzajemny szacunek: płynniejsza współpraca w grupie i wyższa szansa na pakt.';
      case PelotonRelationshipPolarity.trustedAlly:
        summary =
            'Zaufany sojusznik: chętnie dzieli zmiany i rzadziej kasuje kontrataki.';
      case PelotonRelationshipPolarity.pelotonBrotherhood:
        summary =
            'Braterstwo szosy: maksymalne wsparcie w ucieczce i gotowość do jazdy w jednej ekipie z rabatem płacowym.';
    }

    return AiRivalryTacticalModifiers(
      relationshipScore: s,
      polarity: polarity,
      chaseAggressionMultiplier:
          double.parse(chaseMultiplier.toStringAsFixed(2)),
      breakawayCooperationFactor: double.parse(cooperation.toStringAsFixed(2)),
      diplomacyAcceptanceBonus:
          double.parse(diplomacyBonus.toStringAsFixed(2)),
      sprintBlockingRisk: double.parse(sprintBlockRisk.toStringAsFixed(2)),
      transferVetoRisk: transferVeto,
      transferSalaryDiscountFactor:
          double.parse(salaryDiscount.toStringAsFixed(2)),
      summaryLabel: summary,
    );
  }

  /// Wygasza pamięć relacji przy przejściu między sezonami.
  /// Głębokie wendety wygasają znacznie wolniej (8%/sezon) niż drobne tarcia (22%/sezon).
  ({
    AiRivalryGrudgeMemoryState nextState,
    PelotonMemorySeasonDecayReport report,
  }) applySeasonTransitionDecay(
    AiRivalryGrudgeMemoryState state, {
    required int newSeasonYear,
  }) {
    final fromYear = state.currentSeasonYear;
    if (newSeasonYear <= fromYear) {
      return (
        nextState: state,
        report: PelotonMemorySeasonDecayReport(
          fromSeasonYear: fromYear,
          toSeasonYear: newSeasonYear,
          evaluatedBondsCount: state.bonds.length,
          archivedEventsCount: 0,
          prunedNeutralBondsCount: 0,
          survivingVendettasCount: state.activeVendettasCount,
          survivingAlliancesCount: state.activeAlliancesCount,
        ),
      );
    }

    final yearsElapsed = math.max(1, newSeasonYear - fromYear);
    final updatedBonds = <String, RiderRelationshipBond>{};
    int archivedEventsCount = 0;
    int prunedNeutralBondsCount = 0;

    for (final entry in state.bonds.entries) {
      final bond = entry.value;
      final double annualRetentionRate;
      if (bond.score <= -65.0) {
        annualRetentionRate = 0.92; // Krwawa wendeta pamiętana latami
      } else if (bond.score < 0) {
        annualRetentionRate = 0.82;
      } else if (bond.score >= 65.0) {
        annualRetentionRate = 0.90; // Braterstwo szosy trwałe
      } else {
        annualRetentionRate = 0.85;
      }

      final decayedScore =
          bond.score * math.pow(annualRetentionRate, yearsElapsed);

      final updatedEvents = bond.events.map((event) {
        final ageYears = newSeasonYear - event.seasonYear;
        if (!event.isHistoricalArchive && ageYears >= 3) {
          archivedEventsCount++;
          return event.copyWith(isHistoricalArchive: true);
        }
        return event;
      }).toList();

      final hasRecentEvents = updatedEvents.any((e) => !e.isHistoricalArchive);
      if (decayedScore.abs() < 2.5 && !hasRecentEvents) {
        prunedNeutralBondsCount++;
        continue;
      }

      updatedBonds[entry.key] = bond.copyWith(
        score: double.parse(decayedScore.toStringAsFixed(1)),
        events: updatedEvents,
      );
    }

    final nextState = state.copyWith(
      bonds: updatedBonds,
      currentSeasonYear: newSeasonYear,
      lastUpdatedAt: DateTime(newSeasonYear, 1, 1),
    );

    return (
      nextState: nextState,
      report: PelotonMemorySeasonDecayReport(
        fromSeasonYear: fromYear,
        toSeasonYear: newSeasonYear,
        evaluatedBondsCount: state.bonds.length,
        archivedEventsCount: archivedEventsCount,
        prunedNeutralBondsCount: prunedNeutralBondsCount,
        survivingVendettasCount: nextState.activeVendettasCount,
        survivingAlliancesCount: nextState.activeAlliancesCount,
      ),
    );
  }

  /// Zwraca wszystkie relacje powiązane z konkretnym kolarzem, posortowane wg siły więzi.
  List<RiderRelationshipBond> getBondsForRider(
    AiRivalryGrudgeMemoryState state,
    String riderId,
  ) {
    final list =
        state.bonds.values.where((b) => b.involvesRider(riderId)).toList();
    list.sort((a, b) => b.score.abs().compareTo(a.score.abs()));
    return list;
  }

  /// Zwraca listę najsilniejszych wendet i urazów w peletonie.
  List<RiderRelationshipBond> getTopRivalries(
    AiRivalryGrudgeMemoryState state, {
    int limit = 10,
  }) {
    final list = state.bonds.values.where((b) => b.score < 0).toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    return list.take(limit).toList();
  }

  /// Zwraca listę najsilniejszych przyjaźni i sojuszy w peletonie.
  List<RiderRelationshipBond> getTopFriendships(
    AiRivalryGrudgeMemoryState state, {
    int limit = 10,
  }) {
    final list = state.bonds.values.where((b) => b.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list.take(limit).toList();
  }

  /// Ocenia zgodność wybranego składu drużyny (wykrywa toksyczne konflikty i zgrane duety).
  TeamRosterCompatibilityReport evaluateTeamRosterCompatibility(
    AiRivalryGrudgeMemoryState state,
    List<String> rosterRiderIds,
  ) {
    if (rosterRiderIds.length < 2) {
      return const TeamRosterCompatibilityReport(
        averagePairwiseScore: 0.0,
        chemistryModifier: 0.0,
        toxicConflicts: [],
        goldenDuos: [],
      );
    }

    final uniqueIds = rosterRiderIds.toSet().toList();
    final toxic = <RiderRelationshipBond>[];
    final golden = <RiderRelationshipBond>[];
    double sum = 0.0;
    int pairCount = 0;

    for (int i = 0; i < uniqueIds.length; i++) {
      for (int j = i + 1; j < uniqueIds.length; j++) {
        pairCount++;
        final key = canonicalBondKey(uniqueIds[i], uniqueIds[j]);
        final bond = state.bonds[key];
        if (bond != null) {
          sum += bond.score;
          if (bond.score <= -45.0) {
            toxic.add(bond);
          } else if (bond.score >= 45.0) {
            golden.add(bond);
          }
        }
      }
    }

    final avg = pairCount == 0 ? 0.0 : sum / pairCount;
    final modifier =
        ((avg / 10.0) + (golden.length * 1.5) - (toxic.length * 4.5))
            .clamp(-15.0, 15.0);

    return TeamRosterCompatibilityReport(
      averagePairwiseScore: double.parse(avg.toStringAsFixed(1)),
      chemistryModifier: double.parse(modifier.toStringAsFixed(1)),
      toxicConflicts: toxic,
      goldenDuos: golden,
    );
  }

  /// Tworzy realistyczny zestaw początkowych urazów i przyjaźni WorldTour.
  AiRivalryGrudgeMemoryState createSeededDemoState({int seasonYear = 2026}) {
    var state = AiRivalryGrudgeMemoryState.empty(seasonYear: seasonYear);
    state = recordIncident(
      state,
      riderAId: 'rider_kwiatek_01',
      riderBId: 'rider_vander_02',
      riderAName: 'M. Kwiatkowski',
      riderBName: 'J. Van Der Berg',
      riderATeam: 'Ineos Grenadiers',
      riderBTeam: 'Alpecin-Deceuninck',
      incidentType: RelationshipIncidentType.dangerousSprintDeviation,
      raceId: 'tour_of_flanders',
      raceName: 'Ronde van Vlaanderen',
      customScoreDelta: -42.0,
      customDescription:
          'Ostre zajechanie drogi przy barierkach na ostatnich 150 metrach w Oudenaarde.',
      timestamp: DateTime(seasonYear, 4, 5),
    );
    state = recordIncident(
      state,
      riderAId: 'rider_kwiatek_01',
      riderBId: 'rider_vander_02',
      riderAName: 'M. Kwiatkowski',
      riderBName: 'J. Van Der Berg',
      riderATeam: 'Ineos Grenadiers',
      riderBTeam: 'Alpecin-Deceuninck',
      incidentType: RelationshipIncidentType.publicMediaInsult,
      raceId: 'paris_roubaix',
      raceName: 'Paris-Roubaix',
      customScoreDelta: -26.0,
      customDescription:
          'Wypowiedź dla L\'Équipe oskarżająca o celową blokadę przed Carrefour de l\'Arbre.',
      timestamp: DateTime(seasonYear, 4, 12),
    );
    state = recordIncident(
      state,
      riderAId: 'rider_pogacar_03',
      riderBId: 'rider_vinge_04',
      riderAName: 'T. Pogačar',
      riderBName: 'J. Vingegaard',
      riderATeam: 'UAE Team Emirates',
      riderBTeam: 'Visma | Lease a Bike',
      incidentType: RelationshipIncidentType.sportsmanlikeWaitAfterCrash,
      raceId: 'tour_de_france',
      raceName: 'Tour de France',
      stageNumber: 18,
      customScoreDelta: 34.0,
      customDescription:
          'Zwolnienie na zjeździe z Col de Spandelles i podanie ręki po upadku rywala.',
      timestamp: DateTime(seasonYear, 7, 21),
    );
    state = recordIncident(
      state,
      riderAId: 'rider_pogacar_03',
      riderBId: 'rider_mohoric_05',
      riderAName: 'T. Pogačar',
      riderBName: 'M. Mohorič',
      riderATeam: 'UAE Team Emirates',
      riderBTeam: 'Bahrain Victorious',
      incidentType: RelationshipIncidentType.bottleOrWheelShare,
      raceId: 'strade_bianche',
      raceName: 'Strade Bianche',
      customScoreDelta: 38.0,
      customDescription:
          'Oddanie własnego przedniego koła na sektorze Monte Sante Marie i wspólny trening w Słowenii.',
      timestamp: DateTime(seasonYear, 3, 7),
    );
    state = recordIncident(
      state,
      riderAId: 'rider_philipsen_06',
      riderBId: 'rider_merlier_07',
      riderAName: 'J. Philipsen',
      riderBName: 'T. Merlier',
      riderATeam: 'Alpecin-Deceuninck',
      riderBTeam: 'Soudal Quick-Step',
      incidentType: RelationshipIncidentType.wheelsuckingSteal,
      raceId: 'scheldeprijs',
      raceName: 'Scheldeprijs',
      customScoreDelta: -34.0,
      customDescription:
          'Przesiedzenie całego finału na kole pociągu rywala i wyskok na ostatnich 80 metrach.',
      timestamp: DateTime(seasonYear, 4, 8),
    );
    return state;
  }
}

/// Notifier Riverpod zarządzający pamięcią urazów i przyjaźni w peletonie.
class AiRivalryGrudgeMemoryNotifier
    extends StateNotifier<AiRivalryGrudgeMemoryState> {
  final AiRivalryGrudgeMemoryService _service;

  AiRivalryGrudgeMemoryNotifier({
    AiRivalryGrudgeMemoryService service = const AiRivalryGrudgeMemoryService(),
    AiRivalryGrudgeMemoryState? initialState,
  })  : _service = service,
        super(initialState ?? service.createSeededDemoState());

  void recordIncident({
    required String riderAId,
    required String riderBId,
    required String riderAName,
    required String riderBName,
    required String riderATeam,
    required String riderBTeam,
    required RelationshipIncidentType incidentType,
    required String raceId,
    required String raceName,
    int? stageNumber,
    double? customScoreDelta,
    String? customDescription,
  }) {
    state = _service.recordIncident(
      state,
      riderAId: riderAId,
      riderBId: riderBId,
      riderAName: riderAName,
      riderBName: riderBName,
      riderATeam: riderATeam,
      riderBTeam: riderBTeam,
      incidentType: incidentType,
      raceId: raceId,
      raceName: raceName,
      stageNumber: stageNumber,
      customScoreDelta: customScoreDelta,
      customDescription: customDescription,
    );
  }

  PelotonMemorySeasonDecayReport advanceSeasonYear(int newSeasonYear) {
    final result = _service.applySeasonTransitionDecay(
      state,
      newSeasonYear: newSeasonYear,
    );
    state = result.nextState;
    return result.report;
  }

  AiRivalryTacticalModifiers evaluateModifiers(
    String observerRiderId,
    String targetRiderId,
  ) {
    return _service.evaluateTacticalModifiers(
      state,
      observerRiderId: observerRiderId,
      targetRiderId: targetRiderId,
    );
  }

  void restoreState(AiRivalryGrudgeMemoryState restored) {
    state = restored;
  }

  void resetToDemo() {
    state = _service.createSeededDemoState(
      seasonYear: state.currentSeasonYear,
    );
  }
}

final aiRivalryGrudgeMemoryProvider = StateNotifierProvider<
    AiRivalryGrudgeMemoryNotifier, AiRivalryGrudgeMemoryState>(
  (ref) => AiRivalryGrudgeMemoryNotifier(),
);

/// Zakładka filtrowania listy relacji w panelu UI.
enum RivalryMemoryFilterTab {
  all,
  grudges,
  friendships;

  String get label {
    switch (this) {
      case RivalryMemoryFilterTab.all:
        return 'Wszystkie';
      case RivalryMemoryFilterTab.grudges:
        return 'Urazy i Wendety';
      case RivalryMemoryFilterTab.friendships:
        return 'Przyjaźnie i Sojusze';
    }
  }
}

/// Responsywny panel UI prezentujący długoterminową pamięć urazów i przyjaźni w peletonie.
class AiRivalryGrudgeMemoryPanel extends ConsumerStatefulWidget {
  const AiRivalryGrudgeMemoryPanel({super.key});

  @override
  ConsumerState<AiRivalryGrudgeMemoryPanel> createState() =>
      _AiRivalryGrudgeMemoryPanelState();
}

class _AiRivalryGrudgeMemoryPanelState
    extends ConsumerState<AiRivalryGrudgeMemoryPanel> {
  RivalryMemoryFilterTab _activeFilter = RivalryMemoryFilterTab.all;
  String _searchQuery = '';
  String? _selectedBondKey;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<RiderRelationshipBond> _filteredBonds(
    AiRivalryGrudgeMemoryState memoryState,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = memoryState.bonds.values.where((bond) {
      if (_activeFilter == RivalryMemoryFilterTab.grudges &&
          !bond.polarity.isNegative) {
        return false;
      }
      if (_activeFilter == RivalryMemoryFilterTab.friendships &&
          !bond.polarity.isPositive) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = bond.riderAName.toLowerCase().contains(query) ||
            bond.riderBName.toLowerCase().contains(query) ||
            bond.riderATeam.toLowerCase().contains(query) ||
            bond.riderBTeam.toLowerCase().contains(query);
        if (!matchesName) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.score.abs().compareTo(a.score.abs()));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final memoryState = ref.watch(aiRivalryGrudgeMemoryProvider);
    final bonds = _filteredBonds(memoryState);
    final selectedBond = _selectedBondKey != null
        ? memoryState.bonds[_selectedBondKey!]
        : (bonds.isNotEmpty ? bonds.first : null);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final isCompact = constraints.maxWidth < 520;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(memoryState, isCompact),
                const SizedBox(height: 16),
                _buildControlsRow(isCompact),
                const SizedBox(height: 16),
                if (bonds.isEmpty)
                  _buildEmptyState()
                else if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildBondsList(bonds, selectedBond?.bondKey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: selectedBond != null
                            ? _buildBondDetailsCard(selectedBond, memoryState)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildBondsList(bonds, selectedBond?.bondKey),
                      if (selectedBond != null) ...[
                        const SizedBox(height: 16),
                        _buildBondDetailsCard(selectedBond, memoryState),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    AiRivalryGrudgeMemoryState memoryState,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pamięć Urazów i Przyjaźni Peletonu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 15 : 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sezon ${memoryState.currentSeasonYear} • ${memoryState.totalRecordedEvents} zapisanych zdarzeń',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                label: 'Wendety',
                value: '${memoryState.activeVendettasCount}',
                color: AppColors.crimsonAlert,
              ),
              _StatPill(
                label: 'Sojusze',
                value: '${memoryState.activeAlliancesCount}',
                color: AppColors.statusSuccess,
              ),
              _InteractiveActionButton(
                icon: Icons.fast_forward_rounded,
                label: 'Wygaszenie Sezonu',
                onPressed: () {
                  ref
                      .read(aiRivalryGrudgeMemoryProvider.notifier)
                      .advanceSeasonYear(memoryState.currentSeasonYear + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(bool isCompact) {
    final filterButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RivalryMemoryFilterTab.values.map((tab) {
        final isSelected = _activeFilter == tab;
        return _FilterChipButton(
          label: tab.label,
          selected: isSelected,
          onTap: () => setState(() => _activeFilter = tab),
        );
      }).toList(),
    );

    final searchField = SizedBox(
      width: isCompact ? double.infinity : 260,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Szukaj kolarza lub drużyny...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Wyczyść wyszukiwanie',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.4),
          ),
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterButtons,
          const SizedBox(height: 10),
          searchField,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: filterButtons),
        const SizedBox(width: 12),
        searchField,
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'Brak zapisanych relacji dla wybranych kryteriów.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Incydenty na trasie wyścigów automatycznie pojawią się w kronice peletonu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBondsList(
    List<RiderRelationshipBond> bonds,
    String? selectedKey,
  ) {
    return Column(
      children: bonds.map((bond) {
        final isSelected = bond.bondKey == selectedKey;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _BondListCard(
            bond: bond,
            selected: isSelected,
            onTap: () => setState(() => _selectedBondKey = bond.bondKey),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBondDetailsCard(
    RiderRelationshipBond bond,
    AiRivalryGrudgeMemoryState state,
  ) {
    final modifiers = const AiRivalryGrudgeMemoryService()
        .evaluateTacticalModifiers(
      state,
      observerRiderId: bond.riderAId,
      targetRiderId: bond.riderBId,
    );
    final polarityColor = bond.polarity.accentColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bond.polarity.icon, color: polarityColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${bond.riderAName} ↔ ${bond.riderBName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: polarityColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: polarityColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '${bond.score >= 0 ? '+' : ''}${bond.score.toStringAsFixed(0)} pkt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: polarityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${bond.riderATeam}  vs  ${bond.riderBTeam} • ${bond.polarity.label}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WPŁYW TAKTYCZNY AI NA SZOSIE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  modifiers.summaryLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ModifierBadge(
                      label: 'Agresja pościgu',
                      value: 'x${modifiers.chaseAggressionMultiplier.toStringAsFixed(2)}',
                      color: modifiers.chaseAggressionMultiplier > 1.1
                          ? AppColors.crimsonAlert
                          : AppColors.accentBlue,
                    ),
                    _ModifierBadge(
                      label: 'Zmiany w ucieczce',
                      value:
                          '${(modifiers.breakawayCooperationFactor * 100).round()}%',
                      color: modifiers.breakawayCooperationFactor < 0.35
                          ? AppColors.amberWarning
                          : AppColors.statusSuccess,
                    ),
                    _ModifierBadge(
                      label: 'Dyplomacja',
                      value:
                          '${modifiers.diplomacyAcceptanceBonus >= 0 ? '+' : ''}${(modifiers.diplomacyAcceptanceBonus * 100).round()}%',
                      color: modifiers.diplomacyAcceptanceBonus < 0
                          ? AppColors.crimsonAlert
                          : AppColors.statusSuccess,
                    ),
                    if (modifiers.transferVetoRisk)
                      const _ModifierBadge(
                        label: 'Transfer',
                        value: 'WETO EKIPY',
                        color: AppColors.crimsonAlert,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'KRONIKA ZDARZEŃ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...bond.events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      event.scoreDelta < 0
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      size: 16,
                      color: event.scoreDelta < 0
                          ? AppColors.crimsonAlert
                          : AppColors.statusSuccess,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.incidentType.label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${event.seasonYear}${event.isHistoricalArchive ? ' (Archiwum)' : ''}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.description,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
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
          ),
        ],
      ),
    );
  }
}

class _BondListCard extends StatefulWidget {
  final RiderRelationshipBond bond;
  final bool selected;
  final VoidCallback onTap;

  const _BondListCard({
    required this.bond,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BondListCard> createState() => _BondListCardState();
}

class _BondListCardState extends State<_BondListCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final polarityColor = widget.bond.polarity.accentColor;
    final borderColor = widget.selected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? polarityColor.withValues(alpha: 0.65)
                : AppColors.cardBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        onFocusChange: (value) => setState(() => _focused = value),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.surfaceLight
                    : _hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.7)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: widget.selected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: polarityColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.bond.polarity.icon,
                      color: polarityColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.bond.riderAName} ↔ ${widget.bond.riderBName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.bond.polarity.shortLabel} • ${widget.bond.events.length} zdarzeń',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.bond.score >= 0 ? '+' : ''}${widget.bond.score.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: polarityColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.primaryAccent
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.selected
                  ? AppColors.goldAccent.withValues(alpha: 0.7)
                  : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.surface
                : _hovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.85)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: disabled
                  ? AppColors.cardBorder
                  : AppColors.goldAccent.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: disabled ? AppColors.textSecondary : AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      disabled ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
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

class _ModifierBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ModifierBadge({
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
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
