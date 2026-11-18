// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Typ imprezy mistrzowskiej prowadzonej przez Selekcjonera Reprezentacji Narodowej.
enum NationalChampionshipEventType {
  uciRoadWorldChampionships,
  uciIttWorldChampionships,
  olympicRoadRace,
  olympicTimeTrial;

  String get displayNamePl {
    switch (this) {
      case NationalChampionshipEventType.uciRoadWorldChampionships:
        return 'MŚ UCI — Start Wspólny';
      case NationalChampionshipEventType.uciIttWorldChampionships:
        return 'MŚ UCI — Jazda na Czas';
      case NationalChampionshipEventType.olympicRoadRace:
        return 'Igrzyska Olimpijskie — Szosa';
      case NationalChampionshipEventType.olympicTimeTrial:
        return 'Igrzyska Olimpijskie — Czasówka';
    }
  }

  String get shortBadgePl {
    switch (this) {
      case NationalChampionshipEventType.uciRoadWorldChampionships:
        return 'MŚ SZOSA';
      case NationalChampionshipEventType.uciIttWorldChampionships:
        return 'MŚ ITT';
      case NationalChampionshipEventType.olympicRoadRace:
        return 'IO SZOSA';
      case NationalChampionshipEventType.olympicTimeTrial:
        return 'IO ITT';
    }
  }

  bool get isTimeTrial =>
      this == NationalChampionshipEventType.uciIttWorldChampionships ||
      this == NationalChampionshipEventType.olympicTimeTrial;

  bool get isOlympic =>
      this == NationalChampionshipEventType.olympicRoadRace ||
      this == NationalChampionshipEventType.olympicTimeTrial;

  int get uciWinnerPoints => isOlympic ? 900 : 800;

  String toJson() => name;

  static NationalChampionshipEventType fromJson(String? value) {
    if (value == null) {
      return NationalChampionshipEventType.uciRoadWorldChampionships;
    }
    return NationalChampionshipEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NationalChampionshipEventType.uciRoadWorldChampionships,
    );
  }
}

/// Profil trasy mistrzostw wpływający na wagę atrybutów kolarzy.
enum NationalTeamCourseProfile {
  flatSprinters,
  puncheurClassics,
  alpineMountain,
  technicalTimeTrial;

  String get displayNamePl {
    switch (this) {
      case NationalTeamCourseProfile.flatSprinters:
        return 'Płaska / Sprinterska';
      case NationalTeamCourseProfile.puncheurClassics:
        return 'Klasyczna / Ścianki';
      case NationalTeamCourseProfile.alpineMountain:
        return 'Górska / Wysokogórska';
      case NationalTeamCourseProfile.technicalTimeTrial:
        return 'Techniczna Czasówka';
    }
  }

  int get defaultDistanceKm {
    switch (this) {
      case NationalTeamCourseProfile.flatSprinters:
        return 258;
      case NationalTeamCourseProfile.puncheurClassics:
        return 268;
      case NationalTeamCourseProfile.alpineMountain:
        return 274;
      case NationalTeamCourseProfile.technicalTimeTrial:
        return 46;
    }
  }

  int get defaultElevationGainM {
    switch (this) {
      case NationalTeamCourseProfile.flatSprinters:
        return 1450;
      case NationalTeamCourseProfile.puncheurClassics:
        return 3650;
      case NationalTeamCourseProfile.alpineMountain:
        return 5200;
      case NationalTeamCourseProfile.technicalTimeTrial:
        return 420;
    }
  }

  String toJson() => name;

  static NationalTeamCourseProfile fromJson(String? value) {
    if (value == null) return NationalTeamCourseProfile.puncheurClassics;
    return NationalTeamCourseProfile.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NationalTeamCourseProfile.puncheurClassics,
    );
  }
}

/// Rola taktyczna kolarza w kadrze narodowej.
enum NationalRiderTacticalRole {
  protectedLeader,
  coLeader,
  superDomestique,
  roadCaptain,
  leadoutAndTempo,
  reserveAlternate;

  String get displayNamePl {
    switch (this) {
      case NationalRiderTacticalRole.protectedLeader:
        return 'Lider Kadry';
      case NationalRiderTacticalRole.coLeader:
        return 'Wicelider';
      case NationalRiderTacticalRole.superDomestique:
        return 'Super-Pomocnik';
      case NationalRiderTacticalRole.roadCaptain:
        return 'Kapitan Szosowy';
      case NationalRiderTacticalRole.leadoutAndTempo:
        return 'Pociąg / Tempo';
      case NationalRiderTacticalRole.reserveAlternate:
        return 'Rezerwowy';
    }
  }

  bool get isLeadershipRole =>
      this == NationalRiderTacticalRole.protectedLeader ||
      this == NationalRiderTacticalRole.coLeader;

  String toJson() => name;

  static NationalRiderTacticalRole fromJson(String? value) {
    if (value == null) return NationalRiderTacticalRole.superDomestique;
    return NationalRiderTacticalRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NationalRiderTacticalRole.superDomestique,
    );
  }
}

/// Koszyk kwot startowych UCI przyznawany federacji na podstawie rankingu narodów.
enum FederationQuotaTier {
  elitePowerhouse,
  strongContender,
  challenger,
  developing;

  String get displayNamePl {
    switch (this) {
      case FederationQuotaTier.elitePowerhouse:
        return 'Potęga UCI (Top 10)';
      case FederationQuotaTier.strongContender:
        return 'Czołówka UCI (11–20)';
      case FederationQuotaTier.challenger:
        return 'Pretendent (21–35)';
      case FederationQuotaTier.developing:
        return 'Rozwijająca się (36+)';
    }
  }

  int maxStartersFor(NationalChampionshipEventType event) {
    switch (event) {
      case NationalChampionshipEventType.uciRoadWorldChampionships:
        switch (this) {
          case FederationQuotaTier.elitePowerhouse:
            return 8;
          case FederationQuotaTier.strongContender:
            return 6;
          case FederationQuotaTier.challenger:
            return 4;
          case FederationQuotaTier.developing:
            return 2;
        }
      case NationalChampionshipEventType.olympicRoadRace:
        switch (this) {
          case FederationQuotaTier.elitePowerhouse:
            return 4;
          case FederationQuotaTier.strongContender:
            return 3;
          case FederationQuotaTier.challenger:
            return 2;
          case FederationQuotaTier.developing:
            return 1;
        }
      case NationalChampionshipEventType.uciIttWorldChampionships:
      case NationalChampionshipEventType.olympicTimeTrial:
        switch (this) {
          case FederationQuotaTier.elitePowerhouse:
          case FederationQuotaTier.strongContender:
            return 2;
          case FederationQuotaTier.challenger:
          case FederationQuotaTier.developing:
            return 1;
        }
    }
  }

  int get maxReserves {
    switch (this) {
      case FederationQuotaTier.elitePowerhouse:
        return 2;
      case FederationQuotaTier.strongContender:
      case FederationQuotaTier.challenger:
        return 1;
      case FederationQuotaTier.developing:
        return 1;
    }
  }

  String toJson() => name;

  static FederationQuotaTier fromJson(String? value) {
    if (value == null) return FederationQuotaTier.strongContender;
    return FederationQuotaTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FederationQuotaTier.strongContender,
    );
  }
}

/// Zdobyty medal w finale Mistrzostw Świata lub Igrzysk Olimpijskich.
enum ChampionshipMedal {
  none,
  gold,
  silver,
  bronze;

  String get displayNamePl {
    switch (this) {
      case ChampionshipMedal.none:
        return 'Poza podium';
      case ChampionshipMedal.gold:
        return 'Złoty Medal';
      case ChampionshipMedal.silver:
        return 'Srebrny Medal';
      case ChampionshipMedal.bronze:
        return 'Brązowy Medal';
    }
  }

  String toJson() => name;

  static ChampionshipMedal fromJson(String? value) {
    if (value == null) return ChampionshipMedal.none;
    return ChampionshipMedal.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ChampionshipMedal.none,
    );
  }
}

/// Filtr listy kandydatów w panelu selekcjonera.
enum CandidatePoolFilter {
  all,
  selectedOnly,
  conflictsOnly;

  String get displayNamePl {
    switch (this) {
      case CandidatePoolFilter.all:
        return 'Wszyscy';
      case CandidatePoolFilter.selectedOnly:
        return 'Powołani';
      case CandidatePoolFilter.conflictsOnly:
        return 'Konflikty';
    }
  }
}

/// Kandydat do reprezentacji narodowej z ligowych grup WorldTour / ProTeam.
@immutable
class NationalSelectionRiderCandidate {
  const NationalSelectionRiderCandidate({
    required this.riderId,
    required this.fullName,
    required this.tradeTeamName,
    required this.nationalityCode,
    required this.age,
    required this.flatRating,
    required this.mountainRating,
    required this.puncheurRating,
    required this.timeTrialRating,
    required this.sprintRating,
    required this.staminaRating,
    required this.tacticalIq,
    required this.seasonUciPoints,
    required this.currentFormScore,
    required this.fatigueScore,
    required this.morale,
    required this.egoLevel,
    this.isInjured = false,
    this.hasClubConflict = false,
    this.rivalRiderIds = const [],
  });

  final String riderId;
  final String fullName;
  final String tradeTeamName;
  final String nationalityCode;
  final int age;
  final double flatRating;
  final double mountainRating;
  final double puncheurRating;
  final double timeTrialRating;
  final double sprintRating;
  final double staminaRating;
  final double tacticalIq;
  final int seasonUciPoints;
  final double currentFormScore;
  final double fatigueScore;
  final double morale;
  final double egoLevel;
  final bool isInjured;
  final bool hasClubConflict;
  final List<String> rivalRiderIds;

  /// Oblicza dopasowanie profilu kolarza (0–100) pod wybraną trasę.
  double courseSuitabilityScore(NationalTeamCourseProfile profile) {
    final flat = _clampRating(flatRating);
    final mtn = _clampRating(mountainRating);
    final punch = _clampRating(puncheurRating);
    final tt = _clampRating(timeTrialRating);
    final spr = _clampRating(sprintRating);
    final stam = _clampRating(staminaRating);

    switch (profile) {
      case NationalTeamCourseProfile.flatSprinters:
        return 0.40 * spr + 0.30 * flat + 0.15 * stam + 0.15 * punch;
      case NationalTeamCourseProfile.puncheurClassics:
        return 0.42 * punch + 0.23 * stam + 0.20 * mtn + 0.15 * spr;
      case NationalTeamCourseProfile.alpineMountain:
        return 0.50 * mtn + 0.25 * stam + 0.15 * punch + 0.10 * tt;
      case NationalTeamCourseProfile.technicalTimeTrial:
        return 0.62 * tt + 0.23 * flat + 0.15 * stam;
    }
  }

  /// Łączna wartość selekcyjna uwzględniająca formę, zmęczenie i kontuzje.
  double overallSelectionScore(
    NationalChampionshipEventType event,
    NationalTeamCourseProfile profile,
  ) {
    if (isInjured) return 0.0;
    final effectiveProfile = event.isTimeTrial
        ? NationalTeamCourseProfile.technicalTimeTrial
        : profile;
    final baseSuitability = courseSuitabilityScore(effectiveProfile);
    final formFactor = (_clampRating(currentFormScore) - 50.0) * 0.22;
    final fatiguePenalty = math.max(0.0, _clampRating(fatigueScore) - 45.0) * 0.28;
    final conflictPenalty = hasClubConflict ? 4.5 : 0.0;
    return (baseSuitability + formFactor - fatiguePenalty - conflictPenalty)
        .clamp(0.0, 100.0);
  }

  NationalSelectionRiderCandidate copyWith({
    String? riderId,
    String? fullName,
    String? tradeTeamName,
    String? nationalityCode,
    int? age,
    double? flatRating,
    double? mountainRating,
    double? puncheurRating,
    double? timeTrialRating,
    double? sprintRating,
    double? staminaRating,
    double? tacticalIq,
    int? seasonUciPoints,
    double? currentFormScore,
    double? fatigueScore,
    double? morale,
    double? egoLevel,
    bool? isInjured,
    bool? hasClubConflict,
    List<String>? rivalRiderIds,
  }) {
    return NationalSelectionRiderCandidate(
      riderId: riderId ?? this.riderId,
      fullName: fullName ?? this.fullName,
      tradeTeamName: tradeTeamName ?? this.tradeTeamName,
      nationalityCode: nationalityCode ?? this.nationalityCode,
      age: age ?? this.age,
      flatRating: flatRating ?? this.flatRating,
      mountainRating: mountainRating ?? this.mountainRating,
      puncheurRating: puncheurRating ?? this.puncheurRating,
      timeTrialRating: timeTrialRating ?? this.timeTrialRating,
      sprintRating: sprintRating ?? this.sprintRating,
      staminaRating: staminaRating ?? this.staminaRating,
      tacticalIq: tacticalIq ?? this.tacticalIq,
      seasonUciPoints: seasonUciPoints ?? this.seasonUciPoints,
      currentFormScore: currentFormScore ?? this.currentFormScore,
      fatigueScore: fatigueScore ?? this.fatigueScore,
      morale: morale ?? this.morale,
      egoLevel: egoLevel ?? this.egoLevel,
      isInjured: isInjured ?? this.isInjured,
      hasClubConflict: hasClubConflict ?? this.hasClubConflict,
      rivalRiderIds: rivalRiderIds ?? this.rivalRiderIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'fullName': fullName,
        'tradeTeamName': tradeTeamName,
        'nationalityCode': nationalityCode,
        'age': age,
        'flatRating': flatRating,
        'mountainRating': mountainRating,
        'puncheurRating': puncheurRating,
        'timeTrialRating': timeTrialRating,
        'sprintRating': sprintRating,
        'staminaRating': staminaRating,
        'tacticalIq': tacticalIq,
        'seasonUciPoints': seasonUciPoints,
        'currentFormScore': currentFormScore,
        'fatigueScore': fatigueScore,
        'morale': morale,
        'egoLevel': egoLevel,
        'isInjured': isInjured,
        'hasClubConflict': hasClubConflict,
        'rivalRiderIds': rivalRiderIds,
      };

  factory NationalSelectionRiderCandidate.fromJson(Map<String, dynamic> json) {
    final rivalsRaw = json['rivalRiderIds'];
    final rivals = rivalsRaw is List
        ? rivalsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    return NationalSelectionRiderCandidate(
      riderId: (json['riderId'] ?? '').toString(),
      fullName: (json['fullName'] ?? 'Nieznany Kolarz').toString(),
      tradeTeamName: (json['tradeTeamName'] ?? 'Niezrzeszony').toString(),
      nationalityCode: (json['nationalityCode'] ?? 'POL').toString(),
      age: (json['age'] as num?)?.toInt() ?? 26,
      flatRating: _safeDouble(json['flatRating'], 70.0),
      mountainRating: _safeDouble(json['mountainRating'], 70.0),
      puncheurRating: _safeDouble(json['puncheurRating'], 70.0),
      timeTrialRating: _safeDouble(json['timeTrialRating'], 70.0),
      sprintRating: _safeDouble(json['sprintRating'], 68.0),
      staminaRating: _safeDouble(json['staminaRating'], 72.0),
      tacticalIq: _safeDouble(json['tacticalIq'], 72.0),
      seasonUciPoints: (json['seasonUciPoints'] as num?)?.toInt() ?? 0,
      currentFormScore: _safeDouble(json['currentFormScore'], 75.0),
      fatigueScore: _safeDouble(json['fatigueScore'], 25.0),
      morale: _safeDouble(json['morale'], 75.0),
      egoLevel: _safeDouble(json['egoLevel'], 45.0),
      isInjured: json['isInjured'] == true,
      hasClubConflict: json['hasClubConflict'] == true,
      rivalRiderIds: rivals,
    );
  }
}

/// Przydział miejsc startowych i budżetu federacji krajowej.
@immutable
class NationalFederationQuotaAllocation {
  const NationalFederationQuotaAllocation({
    required this.nationCode,
    required this.nationNamePl,
    required this.uciNationRank,
    required this.quotaTier,
    required this.federationBudgetEur,
    required this.federationPrestige,
  });

  final String nationCode;
  final String nationNamePl;
  final int uciNationRank;
  final FederationQuotaTier quotaTier;
  final double federationBudgetEur;
  final double federationPrestige;

  int maxStartersFor(NationalChampionshipEventType event) =>
      quotaTier.maxStartersFor(event);

  int get maxReserves => quotaTier.maxReserves;

  NationalFederationQuotaAllocation copyWith({
    String? nationCode,
    String? nationNamePl,
    int? uciNationRank,
    FederationQuotaTier? quotaTier,
    double? federationBudgetEur,
    double? federationPrestige,
  }) {
    return NationalFederationQuotaAllocation(
      nationCode: nationCode ?? this.nationCode,
      nationNamePl: nationNamePl ?? this.nationNamePl,
      uciNationRank: uciNationRank ?? this.uciNationRank,
      quotaTier: quotaTier ?? this.quotaTier,
      federationBudgetEur: federationBudgetEur ?? this.federationBudgetEur,
      federationPrestige: federationPrestige ?? this.federationPrestige,
    );
  }

  Map<String, dynamic> toJson() => {
        'nationCode': nationCode,
        'nationNamePl': nationNamePl,
        'uciNationRank': uciNationRank,
        'quotaTier': quotaTier.toJson(),
        'federationBudgetEur': federationBudgetEur,
        'federationPrestige': federationPrestige,
      };

  factory NationalFederationQuotaAllocation.fromJson(
    Map<String, dynamic> json,
  ) {
    return NationalFederationQuotaAllocation(
      nationCode: (json['nationCode'] ?? 'POL').toString(),
      nationNamePl: (json['nationNamePl'] ?? 'Polska').toString(),
      uciNationRank: (json['uciNationRank'] as num?)?.toInt() ?? 12,
      quotaTier: FederationQuotaTier.fromJson(json['quotaTier']?.toString()),
      federationBudgetEur: _safeDouble(json['federationBudgetEur'], 250000.0),
      federationPrestige: _safeDouble(json['federationPrestige'], 72.0),
    );
  }
}

/// Wpis powołanego kolarza w kadrze narodowej.
@immutable
class NationalSquadSelectionEntry {
  const NationalSquadSelectionEntry({
    required this.riderId,
    required this.role,
    this.isReserve = false,
    this.isIttStarter = false,
  });

  final String riderId;
  final NationalRiderTacticalRole role;
  final bool isReserve;
  final bool isIttStarter;

  NationalSquadSelectionEntry copyWith({
    String? riderId,
    NationalRiderTacticalRole? role,
    bool? isReserve,
    bool? isIttStarter,
  }) {
    return NationalSquadSelectionEntry(
      riderId: riderId ?? this.riderId,
      role: role ?? this.role,
      isReserve: isReserve ?? this.isReserve,
      isIttStarter: isIttStarter ?? this.isIttStarter,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'role': role.toJson(),
        'isReserve': isReserve,
        'isIttStarter': isIttStarter,
      };

  factory NationalSquadSelectionEntry.fromJson(Map<String, dynamic> json) {
    return NationalSquadSelectionEntry(
      riderId: (json['riderId'] ?? '').toString(),
      role: NationalRiderTacticalRole.fromJson(json['role']?.toString()),
      isReserve: json['isReserve'] == true,
      isIttStarter: json['isIttStarter'] == true,
    );
  }
}

/// Raport spójności taktycznej i chemii szatni kadry narodowej.
@immutable
class NationalTeamChemistryReport {
  const NationalTeamChemistryReport({
    required this.cohesionScore,
    required this.tacticalBalanceScore,
    required this.egoConflictCount,
    required this.tradeTeamConflictCount,
    required this.rivalryCount,
    required this.warnings,
    required this.strengths,
    required this.isEligibleToStart,
  });

  final double cohesionScore;
  final double tacticalBalanceScore;
  final int egoConflictCount;
  final int tradeTeamConflictCount;
  final int rivalryCount;
  final List<String> warnings;
  final List<String> strengths;
  final bool isEligibleToStart;
}

/// Wynik indywidualny kolarza w symulowanym finale MŚ / IO.
@immutable
class NationalRiderRaceOutcome {
  const NationalRiderRaceOutcome({
    required this.riderId,
    required this.fullName,
    required this.role,
    required this.finishPosition,
    required this.timeGapSeconds,
  });

  final String riderId;
  final String fullName;
  final NationalRiderTacticalRole role;
  final int finishPosition;
  final int timeGapSeconds;

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'fullName': fullName,
        'role': role.toJson(),
        'finishPosition': finishPosition,
        'timeGapSeconds': timeGapSeconds,
      };

  factory NationalRiderRaceOutcome.fromJson(Map<String, dynamic> json) {
    return NationalRiderRaceOutcome(
      riderId: (json['riderId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      role: NationalRiderTacticalRole.fromJson(json['role']?.toString()),
      finishPosition: (json['finishPosition'] as num?)?.toInt() ?? 50,
      timeGapSeconds: (json['timeGapSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Wynik kampanii Mistrzostw Świata lub Igrzysk Olimpijskich.
@immutable
class NationalChampionshipSimulationResult {
  const NationalChampionshipSimulationResult({
    required this.seasonYear,
    required this.eventType,
    required this.courseProfile,
    required this.nationCode,
    required this.bestFinishPosition,
    required this.medalWon,
    required this.rainbowJerseyWinnerName,
    required this.cohesionAtStart,
    required this.tacticalSummaryPl,
    required this.riderPlacements,
    required this.federationTrustDelta,
    required this.uciNationPointsEarned,
  });

  final int seasonYear;
  final NationalChampionshipEventType eventType;
  final NationalTeamCourseProfile courseProfile;
  final String nationCode;
  final int bestFinishPosition;
  final ChampionshipMedal medalWon;
  final String? rainbowJerseyWinnerName;
  final double cohesionAtStart;
  final String tacticalSummaryPl;
  final List<NationalRiderRaceOutcome> riderPlacements;
  final double federationTrustDelta;
  final int uciNationPointsEarned;

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'eventType': eventType.toJson(),
        'courseProfile': courseProfile.toJson(),
        'nationCode': nationCode,
        'bestFinishPosition': bestFinishPosition,
        'medalWon': medalWon.toJson(),
        'rainbowJerseyWinnerName': rainbowJerseyWinnerName,
        'cohesionAtStart': cohesionAtStart,
        'tacticalSummaryPl': tacticalSummaryPl,
        'riderPlacements': riderPlacements.map((e) => e.toJson()).toList(),
        'federationTrustDelta': federationTrustDelta,
        'uciNationPointsEarned': uciNationPointsEarned,
      };

  factory NationalChampionshipSimulationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawPlacements = json['riderPlacements'];
    final placements = rawPlacements is List
        ? rawPlacements
            .whereType<Map<String, dynamic>>()
            .map(NationalRiderRaceOutcome.fromJson)
            .toList()
        : const <NationalRiderRaceOutcome>[];
    return NationalChampionshipSimulationResult(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      eventType: NationalChampionshipEventType.fromJson(
        json['eventType']?.toString(),
      ),
      courseProfile: NationalTeamCourseProfile.fromJson(
        json['courseProfile']?.toString(),
      ),
      nationCode: (json['nationCode'] ?? 'POL').toString(),
      bestFinishPosition: (json['bestFinishPosition'] as num?)?.toInt() ?? 15,
      medalWon: ChampionshipMedal.fromJson(json['medalWon']?.toString()),
      rainbowJerseyWinnerName: json['rainbowJerseyWinnerName']?.toString(),
      cohesionAtStart: _safeDouble(json['cohesionAtStart'], 70.0),
      tacticalSummaryPl: (json['tacticalSummaryPl'] ?? '').toString(),
      riderPlacements: placements,
      federationTrustDelta: _safeDouble(json['federationTrustDelta'], 0.0),
      uciNationPointsEarned:
          (json['uciNationPointsEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Pełny stan trybu Selekcjonera Reprezentacji Narodowej.
@immutable
class NationalChampionshipCampaignState {
  const NationalChampionshipCampaignState({
    required this.seasonYear,
    required this.eventType,
    required this.courseProfile,
    required this.courseDistanceKm,
    required this.elevationGainMeters,
    required this.quota,
    required this.candidatePool,
    required this.selectedSquad,
    required this.federationTrust,
    required this.mediaPressure,
    this.isSelectionLocked = false,
    this.lastSimulationResult,
    this.history = const [],
    this.statusBannerPl,
  });

  final int seasonYear;
  final NationalChampionshipEventType eventType;
  final NationalTeamCourseProfile courseProfile;
  final int courseDistanceKm;
  final int elevationGainMeters;
  final NationalFederationQuotaAllocation quota;
  final List<NationalSelectionRiderCandidate> candidatePool;
  final List<NationalSquadSelectionEntry> selectedSquad;
  final double federationTrust;
  final double mediaPressure;
  final bool isSelectionLocked;
  final NationalChampionshipSimulationResult? lastSimulationResult;
  final List<NationalChampionshipSimulationResult> history;
  final String? statusBannerPl;

  int get activeMaxStarters => quota.maxStartersFor(eventType);

  List<NationalSquadSelectionEntry> get activeStarters =>
      selectedSquad.where((e) => !e.isReserve).toList();

  List<NationalSquadSelectionEntry> get reserves =>
      selectedSquad.where((e) => e.isReserve).toList();

  int get ittStarterCount => selectedSquad.where((e) => e.isIttStarter).length;

  NationalSelectionRiderCandidate? findCandidate(String riderId) {
    for (final c in candidatePool) {
      if (c.riderId == riderId) return c;
    }
    return null;
  }

  NationalSquadSelectionEntry? findSelection(String riderId) {
    for (final s in selectedSquad) {
      if (s.riderId == riderId) return s;
    }
    return null;
  }

  NationalChampionshipCampaignState copyWith({
    int? seasonYear,
    NationalChampionshipEventType? eventType,
    NationalTeamCourseProfile? courseProfile,
    int? courseDistanceKm,
    int? elevationGainMeters,
    NationalFederationQuotaAllocation? quota,
    List<NationalSelectionRiderCandidate>? candidatePool,
    List<NationalSquadSelectionEntry>? selectedSquad,
    double? federationTrust,
    double? mediaPressure,
    bool? isSelectionLocked,
    NationalChampionshipSimulationResult? lastSimulationResult,
    bool clearLastSimulation = false,
    List<NationalChampionshipSimulationResult>? history,
    String? statusBannerPl,
    bool clearStatusBanner = false,
  }) {
    return NationalChampionshipCampaignState(
      seasonYear: seasonYear ?? this.seasonYear,
      eventType: eventType ?? this.eventType,
      courseProfile: courseProfile ?? this.courseProfile,
      courseDistanceKm: courseDistanceKm ?? this.courseDistanceKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      quota: quota ?? this.quota,
      candidatePool: candidatePool ?? this.candidatePool,
      selectedSquad: selectedSquad ?? this.selectedSquad,
      federationTrust: federationTrust ?? this.federationTrust,
      mediaPressure: mediaPressure ?? this.mediaPressure,
      isSelectionLocked: isSelectionLocked ?? this.isSelectionLocked,
      lastSimulationResult: clearLastSimulation
          ? null
          : (lastSimulationResult ?? this.lastSimulationResult),
      history: history ?? this.history,
      statusBannerPl:
          clearStatusBanner ? null : (statusBannerPl ?? this.statusBannerPl),
    );
  }

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'eventType': eventType.toJson(),
        'courseProfile': courseProfile.toJson(),
        'courseDistanceKm': courseDistanceKm,
        'elevationGainMeters': elevationGainMeters,
        'quota': quota.toJson(),
        'candidatePool': candidatePool.map((e) => e.toJson()).toList(),
        'selectedSquad': selectedSquad.map((e) => e.toJson()).toList(),
        'federationTrust': federationTrust,
        'mediaPressure': mediaPressure,
        'isSelectionLocked': isSelectionLocked,
        'lastSimulationResult': lastSimulationResult?.toJson(),
        'history': history.map((e) => e.toJson()).toList(),
        'statusBannerPl': statusBannerPl,
      };

  factory NationalChampionshipCampaignState.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawCandidates = json['candidatePool'];
    final candidates = rawCandidates is List
        ? rawCandidates
            .whereType<Map<String, dynamic>>()
            .map(NationalSelectionRiderCandidate.fromJson)
            .toList()
        : const <NationalSelectionRiderCandidate>[];

    final rawSelected = json['selectedSquad'];
    final selected = rawSelected is List
        ? rawSelected
            .whereType<Map<String, dynamic>>()
            .map(NationalSquadSelectionEntry.fromJson)
            .toList()
        : const <NationalSquadSelectionEntry>[];

    final rawHistory = json['history'];
    final history = rawHistory is List
        ? rawHistory
            .whereType<Map<String, dynamic>>()
            .map(NationalChampionshipSimulationResult.fromJson)
            .toList()
        : const <NationalChampionshipSimulationResult>[];

    final lastSimRaw = json['lastSimulationResult'];

    return NationalChampionshipCampaignState(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      eventType: NationalChampionshipEventType.fromJson(
        json['eventType']?.toString(),
      ),
      courseProfile: NationalTeamCourseProfile.fromJson(
        json['courseProfile']?.toString(),
      ),
      courseDistanceKm: (json['courseDistanceKm'] as num?)?.toInt() ?? 268,
      elevationGainMeters:
          (json['elevationGainMeters'] as num?)?.toInt() ?? 3650,
      quota: json['quota'] is Map<String, dynamic>
          ? NationalFederationQuotaAllocation.fromJson(
              json['quota'] as Map<String, dynamic>,
            )
          : NationalFederationTeamManagerService.createPolandQuota(),
      candidatePool: candidates,
      selectedSquad: selected,
      federationTrust: _safeDouble(json['federationTrust'], 74.0),
      mediaPressure: _safeDouble(json['mediaPressure'], 48.0),
      isSelectionLocked: json['isSelectionLocked'] == true,
      lastSimulationResult: lastSimRaw is Map<String, dynamic>
          ? NationalChampionshipSimulationResult.fromJson(lastSimRaw)
          : null,
      history: history,
      statusBannerPl: json['statusBannerPl']?.toString(),
    );
  }
}

/// Główny serwis logiki Selekcjonera Reprezentacji Narodowej (MŚ i IO).
class NationalFederationTeamManagerService {
  const NationalFederationTeamManagerService();

  static const double clubReleaseNegotiationCostEur = 18000.0;

  /// Ocenia spójność taktyczną, konflikty ego, rywalizacje klubowe i kwalifikację składu.
  NationalTeamChemistryReport evaluateSquadChemistry(
    NationalChampionshipCampaignState state,
  ) {
    final starters = state.activeStarters;
    final warnings = <String>[];
    final strengths = <String>[];

    if (starters.isEmpty) {
      return const NationalTeamChemistryReport(
        cohesionScore: 0.0,
        tacticalBalanceScore: 0.0,
        egoConflictCount: 0,
        tradeTeamConflictCount: 0,
        rivalryCount: 0,
        warnings: ['Brak powołanych kolarzy w składzie startowym.'],
        strengths: [],
        isEligibleToStart: false,
      );
    }

    var cohesion = 78.0;
    var balance = 72.0;
    var egoConflicts = 0;
    var clubConflicts = 0;
    var rivalryCount = 0;
    var leaderCount = 0;
    var domestiqueCount = 0;
    var hasInjuredStarter = false;

    final starterIds = starters.map((e) => e.riderId).toSet();
    final seenRivalryPairs = <String>{};

    for (final entry in starters) {
      final candidate = state.findCandidate(entry.riderId);
      if (candidate == null) continue;

      if (candidate.isInjured) {
        hasInjuredStarter = true;
        cohesion -= 25.0;
        warnings.add('${candidate.fullName} ma aktywną kontuzję — ryzyko DNF.');
      }

      if (candidate.hasClubConflict) {
        clubConflicts++;
        cohesion -= 6.0;
        warnings.add(
          '${candidate.fullName}: sprzeciw grupy ${candidate.tradeTeamName} (wymaga negocjacji).',
        );
      }

      if (entry.role.isLeadershipRole) {
        leaderCount++;
      } else if (entry.role != NationalRiderTacticalRole.reserveAlternate) {
        domestiqueCount++;
      }

      // Konflikt ego: gwiazda z wysokim ego zepchnięta do roli czystego pomocnika.
      if (candidate.egoLevel >= 78.0 && !entry.role.isLeadershipRole) {
        egoConflicts++;
        cohesion -= 12.0;
        warnings.add(
          'Konflikt ego: ${candidate.fullName} (Ego ${candidate.egoLevel.round()}) oczekuje roli lidera.',
        );
      }

      // Rywalizacja z innymi powołanymi kolarzami z przeciwnych grup WorldTour.
      for (final rivalId in candidate.rivalRiderIds) {
        if (starterIds.contains(rivalId)) {
          final pairKey = entry.riderId.compareTo(rivalId) < 0
              ? '${entry.riderId}::$rivalId'
              : '$rivalId::${entry.riderId}';
          if (seenRivalryPairs.add(pairKey)) {
            rivalryCount++;
            cohesion -= 10.0;
            final rivalName =
                state.findCandidate(rivalId)?.fullName ?? rivalId;
            warnings.add(
              'Napięcie międzyklubowe: ${candidate.fullName} vs $rivalName.',
            );
          }
        }
      }
    }

    if (leaderCount == 0) {
      balance -= 24.0;
      warnings.add('Brak wyznaczonego Lidera Kadry (Protected Leader).');
    } else if (leaderCount > 2 && !state.eventType.isTimeTrial) {
      balance -= 14.0;
      warnings.add('Zbyt wielu liderów ($leaderCount) rozmywa hierarchię na finiszu.');
    } else {
      balance += 12.0;
      strengths.add('Jasna hierarchia liderów ($leaderCount) gotowa na finał.');
    }

    if (!state.eventType.isTimeTrial && starters.length >= 3) {
      if (domestiqueCount >= 2) {
        balance += 14.0;
        strengths.add('Solidne zaplecze pomocników ($domestiqueCount) do kontroli ucieczek.');
      } else {
        balance -= 10.0;
        warnings.add('Zbyt mało pomocników do zamykania odjazdów w końcówce.');
      }
    }

    final hasRoadCaptain = starters.any(
      (e) => e.role == NationalRiderTacticalRole.roadCaptain,
    );
    if (hasRoadCaptain) {
      cohesion += 6.0;
      strengths.add('Doświadczony Kapitan Szosowy spina taktykę bez radia wyścigowego.');
    }

    if (starters.length > state.activeMaxStarters) {
      warnings.add(
        'Przekroczono limit miejsc UCI (${starters.length}/${state.activeMaxStarters}).',
      );
    }

    final finalCohesion = cohesion.clamp(0.0, 100.0);
    final finalBalance = balance.clamp(0.0, 100.0);
    final isEligible = !hasInjuredStarter &&
        starters.isNotEmpty &&
        starters.length <= state.activeMaxStarters &&
        leaderCount >= 1;

    return NationalTeamChemistryReport(
      cohesionScore: finalCohesion,
      tacticalBalanceScore: finalBalance,
      egoConflictCount: egoConflicts,
      tradeTeamConflictCount: clubConflicts,
      rivalryCount: rivalryCount,
      warnings: warnings,
      strengths: strengths,
      isEligibleToStart: isEligible,
    );
  }

  /// Automatycznie dobiera optymalną kadrę pod aktualną imprezę i profil trasy.
  NationalChampionshipCampaignState autoSelectOptimalSquad(
    NationalChampionshipCampaignState state,
  ) {
    if (state.isSelectionLocked) {
      return state.copyWith(
        statusBannerPl: 'Powołania są zablokowane — odblokuj, aby zmienić skład.',
      );
    }

    final eligible = state.candidatePool.where((c) => !c.isInjured).toList()
      ..sort((a, b) {
        final scoreB = b.overallSelectionScore(
          state.eventType,
          state.courseProfile,
        );
        final scoreA = a.overallSelectionScore(
          state.eventType,
          state.courseProfile,
        );
        return scoreB.compareTo(scoreA);
      });

    final maxStarters = state.activeMaxStarters;
    final maxReserves = state.quota.maxReserves;
    final newSquad = <NationalSquadSelectionEntry>[];

    for (var i = 0; i < eligible.length && i < maxStarters; i++) {
      final candidate = eligible[i];
      final NationalRiderTacticalRole role;
      if (i == 0) {
        role = NationalRiderTacticalRole.protectedLeader;
      } else if (i == 1 && (maxStarters >= 4 || candidate.egoLevel >= 72.0)) {
        role = NationalRiderTacticalRole.coLeader;
      } else if (i == 2 && candidate.tacticalIq >= 78.0) {
        role = NationalRiderTacticalRole.roadCaptain;
      } else if (state.courseProfile == NationalTeamCourseProfile.flatSprinters) {
        role = NationalRiderTacticalRole.leadoutAndTempo;
      } else {
        role = NationalRiderTacticalRole.superDomestique;
      }

      newSquad.add(
        NationalSquadSelectionEntry(
          riderId: candidate.riderId,
          role: role,
          isReserve: false,
          isIttStarter: state.eventType.isTimeTrial && i < maxStarters,
        ),
      );
    }

    for (var i = maxStarters;
        i < eligible.length && i < maxStarters + maxReserves;
        i++) {
      newSquad.add(
        NationalSquadSelectionEntry(
          riderId: eligible[i].riderId,
          role: NationalRiderTacticalRole.reserveAlternate,
          isReserve: true,
        ),
      );
    }

    return state.copyWith(
      selectedSquad: newSquad,
      statusBannerPl:
          'Auto-selekcja ukończona: powołano ${newSquad.where((e) => !e.isReserve).length}/$maxStarters starterów.',
    );
  }

  /// Dodaje lub usuwa kolarza z kadry narodowej z poszanowaniem limitu miejsc UCI.
  NationalChampionshipCampaignState toggleRiderSelection(
    NationalChampionshipCampaignState state,
    String riderId,
  ) {
    if (state.isSelectionLocked) {
      return state.copyWith(
        statusBannerPl: 'Skład jest zablokowany przed startem.',
      );
    }
    final candidate = state.findCandidate(riderId);
    if (candidate == null) return state;

    final existing = state.findSelection(riderId);
    final updated = List<NationalSquadSelectionEntry>.from(state.selectedSquad);

    if (existing != null) {
      updated.removeWhere((e) => e.riderId == riderId);
      return state.copyWith(
        selectedSquad: updated,
        statusBannerPl: 'Usunięto ${candidate.fullName} z kadry.',
      );
    }

    final currentStarters = state.activeStarters.length;
    if (currentStarters < state.activeMaxStarters) {
      final hasLeader = state.activeStarters.any(
        (e) => e.role == NationalRiderTacticalRole.protectedLeader,
      );
      updated.add(
        NationalSquadSelectionEntry(
          riderId: riderId,
          role: hasLeader
              ? NationalRiderTacticalRole.superDomestique
              : NationalRiderTacticalRole.protectedLeader,
          isReserve: false,
          isIttStarter: state.eventType.isTimeTrial,
        ),
      );
      return state.copyWith(
        selectedSquad: updated,
        statusBannerPl: 'Powołano ${candidate.fullName} do podstawowej kadry.',
      );
    }

    if (state.reserves.length < state.quota.maxReserves) {
      updated.add(
        NationalSquadSelectionEntry(
          riderId: riderId,
          role: NationalRiderTacticalRole.reserveAlternate,
          isReserve: true,
        ),
      );
      return state.copyWith(
        selectedSquad: updated,
        statusBannerPl:
            'Limit starterów pełny — dodano ${candidate.fullName} jako rezerwowego.',
      );
    }

    return state.copyWith(
      statusBannerPl:
          'Limit powołań (${state.activeMaxStarters} + ${state.quota.maxReserves} rez.) został osiągnięty.',
    );
  }

  /// Zmienia rolę taktyczną powołanego kolarza.
  NationalChampionshipCampaignState assignRiderRole(
    NationalChampionshipCampaignState state,
    String riderId,
    NationalRiderTacticalRole newRole,
  ) {
    if (state.isSelectionLocked) return state;

    final updated = state.selectedSquad.map((entry) {
      if (entry.riderId != riderId) return entry;
      return entry.copyWith(
        role: newRole,
        isReserve: newRole == NationalRiderTacticalRole.reserveAlternate,
      );
    }).toList();

    return state.copyWith(
      selectedSquad: updated,
      statusBannerPl: 'Zaktualizowano rolę taktyczną: ${newRole.displayNamePl}.',
    );
  }

  /// Negocjuje z grupą zawodową zwolnienie kolarza na zgrupowanie kadry.
  NationalChampionshipCampaignState resolveClubReleaseNegotiation(
    NationalChampionshipCampaignState state,
    String riderId,
  ) {
    final candidate = state.findCandidate(riderId);
    if (candidate == null || !candidate.hasClubConflict) return state;

    if (state.quota.federationBudgetEur < clubReleaseNegotiationCostEur) {
      return state.copyWith(
        statusBannerPl:
            'Niewystarczający budżet federacji na rekompensatę ubezpieczeniową.',
      );
    }

    final updatedPool = state.candidatePool.map((c) {
      if (c.riderId != riderId) return c;
      return c.copyWith(
        hasClubConflict: false,
        morale: (c.morale + 6.0).clamp(0.0, 100.0),
      );
    }).toList();

    return state.copyWith(
      candidatePool: updatedPool,
      quota: state.quota.copyWith(
        federationBudgetEur:
            state.quota.federationBudgetEur - clubReleaseNegotiationCostEur,
      ),
      statusBannerPl:
          'Porozumienie z ${candidate.tradeTeamName}: ${candidate.fullName} zwolniony na kadrę.',
    );
  }

  /// Zmienia typ imprezy lub profil trasy i dostosowuje wybrane miejsca startowe.
  NationalChampionshipCampaignState switchEventAndCourse(
    NationalChampionshipCampaignState state, {
    NationalChampionshipEventType? eventType,
    NationalTeamCourseProfile? courseProfile,
  }) {
    final nextEvent = eventType ?? state.eventType;
    final nextProfile = nextEvent.isTimeTrial
        ? NationalTeamCourseProfile.technicalTimeTrial
        : (courseProfile ?? state.courseProfile);

    final nextMaxStarters = state.quota.maxStartersFor(nextEvent);
    var adjustedSquad = List<NationalSquadSelectionEntry>.from(
      state.selectedSquad,
    );
    var starterCount = 0;
    adjustedSquad = adjustedSquad.map((entry) {
      if (!entry.isReserve) {
        starterCount++;
        if (starterCount > nextMaxStarters) {
          return entry.copyWith(
            isReserve: true,
            role: NationalRiderTacticalRole.reserveAlternate,
            isIttStarter: false,
          );
        }
      }
      return entry;
    }).toList();

    return state.copyWith(
      eventType: nextEvent,
      courseProfile: nextProfile,
      courseDistanceKm: nextProfile.defaultDistanceKm,
      elevationGainMeters: nextProfile.defaultElevationGainM,
      selectedSquad: adjustedSquad,
      isSelectionLocked: false,
      statusBannerPl:
          'Zmieniono zawody: ${nextEvent.displayNamePl} (${nextProfile.displayNamePl}).',
    );
  }

  /// Blokuje lub odblokowuje listę powołań przed odprawą techniczną UCI.
  NationalChampionshipCampaignState setSelectionLocked(
    NationalChampionshipCampaignState state,
    bool locked,
  ) {
    if (locked) {
      final chemistry = evaluateSquadChemistry(state);
      if (!chemistry.isEligibleToStart) {
        return state.copyWith(
          statusBannerPl:
              'Nie można zatwierdzić składu: ${chemistry.warnings.isNotEmpty ? chemistry.warnings.first : "sprawdź wymagania UCI"}.',
        );
      }
    }
    return state.copyWith(
      isSelectionLocked: locked,
      statusBannerPl: locked
          ? 'Oficjalna lista startowa zgłoszona do komisarzy UCI.'
          : 'Odblokowano listę powołań do korekty.',
    );
  }

  /// Deterministyczna symulacja finału Mistrzostw Świata lub Igrzysk Olimpijskich.
  NationalChampionshipCampaignState simulateChampionshipRace(
    NationalChampionshipCampaignState state, {
    int? deterministicSeed,
  }) {
    final chemistry = evaluateSquadChemistry(state);
    if (!chemistry.isEligibleToStart) {
      return state.copyWith(
        statusBannerPl:
            'Start zablokowany: ${chemistry.warnings.isNotEmpty ? chemistry.warnings.first : "niekompletny skład"}.',
      );
    }

    final starters = state.activeStarters;
    final rng = math.Random(
      deterministicSeed ??
          (state.seasonYear * 31 +
              state.eventType.index * 17 +
              state.courseProfile.index * 13 +
              starters.length),
    );

    final cohesionBonus = (chemistry.cohesionScore - 65.0) * 0.14;
    final balanceBonus = (chemistry.tacticalBalanceScore - 65.0) * 0.10;
    final outcomes = <NationalRiderRaceOutcome>[];

    for (final entry in starters) {
      final candidate = state.findCandidate(entry.riderId);
      if (candidate == null) continue;

      final suitability = candidate.overallSelectionScore(
        state.eventType,
        state.courseProfile,
      );
      final roleMultiplier = entry.role == NationalRiderTacticalRole.protectedLeader
          ? 1.04
          : (entry.role == NationalRiderTacticalRole.coLeader ? 1.01 : 0.94);

      final raceDayVariance = (rng.nextDouble() * 8.0) - 3.5;
      final effectiveScore =
          (suitability * roleMultiplier) + cohesionBonus + balanceBonus + raceDayVariance;

      // Mapowanie 0..100 -> pozycja 1..95 (elita światowa zaczyna się od ~86+ dla złota).
      final rawPosition = (102.0 - effectiveScore * 1.08).round().clamp(1, 110);
      final gapSec = rawPosition == 1 ? 0 : ((rawPosition - 1) * 7 + rng.nextInt(5));

      outcomes.add(
        NationalRiderRaceOutcome(
          riderId: candidate.riderId,
          fullName: candidate.fullName,
          role: entry.role,
          finishPosition: rawPosition,
          timeGapSeconds: gapSec,
        ),
      );
    }

    outcomes.sort((a, b) => a.finishPosition.compareTo(b.finishPosition));
    final best = outcomes.first;
    final medal = switch (best.finishPosition) {
      1 => ChampionshipMedal.gold,
      2 => ChampionshipMedal.silver,
      3 => ChampionshipMedal.bronze,
      _ => ChampionshipMedal.none,
    };

    final trustDelta = switch (medal) {
      ChampionshipMedal.gold => 14.0,
      ChampionshipMedal.silver => 9.0,
      ChampionshipMedal.bronze => 6.0,
      ChampionshipMedal.none => best.finishPosition <= 10 ? 2.5 : -4.0,
    };

    final uciPoints = best.finishPosition <= 15
        ? ((state.eventType.uciWinnerPoints * (16 - best.finishPosition)) / 15)
            .round()
        : 25;

    final summaryPl = switch (medal) {
      ChampionshipMedal.gold =>
        'Historyczny triumf! ${best.fullName} zdobywa złoto (${state.eventType.displayNamePl})!',
      ChampionshipMedal.silver =>
        'Srebrny medal dla ${best.fullName} po zaciętym finiszu z najlepszymi.',
      ChampionshipMedal.bronze =>
        'Brązowy krążek wywalczony przez ${best.fullName} przy wsparciu kadry.',
      ChampionshipMedal.none =>
        'Najwyższe miejsce: #${best.finishPosition} (${best.fullName}). Wnioski przed kolejnym cyklem.',
    };

    final result = NationalChampionshipSimulationResult(
      seasonYear: state.seasonYear,
      eventType: state.eventType,
      courseProfile: state.courseProfile,
      nationCode: state.quota.nationCode,
      bestFinishPosition: best.finishPosition,
      medalWon: medal,
      rainbowJerseyWinnerName:
          medal == ChampionshipMedal.gold && !state.eventType.isOlympic
              ? best.fullName
              : null,
      cohesionAtStart: chemistry.cohesionScore,
      tacticalSummaryPl: summaryPl,
      riderPlacements: outcomes,
      federationTrustDelta: trustDelta,
      uciNationPointsEarned: uciPoints,
    );

    return state.copyWith(
      isSelectionLocked: true,
      lastSimulationResult: result,
      history: [result, ...state.history],
      federationTrust: (state.federationTrust + trustDelta).clamp(0.0, 100.0),
      statusBannerPl: summaryPl,
    );
  }

  /// Tworzy domyślną kampanię selekcjonera Polski.
  static NationalFederationQuotaAllocation createPolandQuota() {
    return const NationalFederationQuotaAllocation(
      nationCode: 'POL',
      nationNamePl: 'Polska',
      uciNationRank: 11,
      quotaTier: FederationQuotaTier.strongContender,
      federationBudgetEur: 280000.0,
      federationPrestige: 76.0,
    );
  }

  /// Zestaw gotowych nacji do wyboru lub testów symulacji.
  static List<NationalChampionshipCampaignState> createSampleNationPresets() {
    return [
      createDefaultPolandCampaign(),
      _createBelgiumCampaign(),
      _createSloveniaCampaign(),
    ];
  }

  static NationalChampionshipCampaignState createDefaultPolandCampaign() {
    final pool = <NationalSelectionRiderCandidate>[
      const NationalSelectionRiderCandidate(
        riderId: 'pol_kwiatkowski',
        fullName: 'Michał Kwiatkowski',
        tradeTeamName: 'INEOS Grenadiers',
        nationalityCode: 'POL',
        age: 35,
        flatRating: 80,
        mountainRating: 78,
        puncheurRating: 85,
        timeTrialRating: 82,
        sprintRating: 75,
        staminaRating: 84,
        tacticalIq: 92,
        seasonUciPoints: 1420,
        currentFormScore: 84,
        fatigueScore: 22,
        morale: 86,
        egoLevel: 68,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'pol_majka',
        fullName: 'Rafał Majka',
        tradeTeamName: 'UAE Team Emirates',
        nationalityCode: 'POL',
        age: 36,
        flatRating: 72,
        mountainRating: 84,
        puncheurRating: 79,
        timeTrialRating: 70,
        sprintRating: 64,
        staminaRating: 83,
        tacticalIq: 87,
        seasonUciPoints: 1180,
        currentFormScore: 81,
        fatigueScore: 30,
        morale: 82,
        egoLevel: 64,
        hasClubConflict: true,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'pol_aniszkiewicz',
        fullName: 'Stanisław Aniołkowski',
        tradeTeamName: 'Cofidis',
        nationalityCode: 'POL',
        age: 29,
        flatRating: 82,
        mountainRating: 61,
        puncheurRating: 74,
        timeTrialRating: 68,
        sprintRating: 85,
        staminaRating: 79,
        tacticalIq: 77,
        seasonUciPoints: 960,
        currentFormScore: 83,
        fatigueScore: 24,
        morale: 84,
        egoLevel: 74,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'pol_bodnar_jr',
        fullName: 'Filip Maciejuk',
        tradeTeamName: 'Red Bull - BORA',
        nationalityCode: 'POL',
        age: 26,
        flatRating: 83,
        mountainRating: 65,
        puncheurRating: 73,
        timeTrialRating: 83,
        sprintRating: 70,
        staminaRating: 82,
        tacticalIq: 79,
        seasonUciPoints: 740,
        currentFormScore: 79,
        fatigueScore: 20,
        morale: 80,
        egoLevel: 48,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'pol_gradek',
        fullName: 'Kamil Gradek',
        tradeTeamName: 'Bahrain Victorious',
        nationalityCode: 'POL',
        age: 35,
        flatRating: 80,
        mountainRating: 63,
        puncheurRating: 71,
        timeTrialRating: 79,
        sprintRating: 68,
        staminaRating: 81,
        tacticalIq: 84,
        seasonUciPoints: 520,
        currentFormScore: 76,
        fatigueScore: 26,
        morale: 78,
        egoLevel: 38,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'pol_pomorski',
        fullName: 'Michał Pomorski',
        tradeTeamName: 'Mazowsze Serce Polski',
        nationalityCode: 'POL',
        age: 23,
        flatRating: 76,
        mountainRating: 72,
        puncheurRating: 77,
        timeTrialRating: 73,
        sprintRating: 74,
        staminaRating: 78,
        tacticalIq: 74,
        seasonUciPoints: 410,
        currentFormScore: 82,
        fatigueScore: 18,
        morale: 88,
        egoLevel: 42,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'pol_sajnok',
        fullName: 'Szymon Sajnok',
        tradeTeamName: 'Q36.5 Pro Cycling',
        nationalityCode: 'POL',
        age: 28,
        flatRating: 79,
        mountainRating: 58,
        puncheurRating: 72,
        timeTrialRating: 71,
        sprintRating: 81,
        staminaRating: 75,
        tacticalIq: 75,
        seasonUciPoints: 485,
        currentFormScore: 74,
        fatigueScore: 28,
        morale: 76,
        egoLevel: 55,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'pol_wisniowski',
        fullName: 'Łukasz Wiśniowski',
        tradeTeamName: 'Bahrain Victorious',
        nationalityCode: 'POL',
        age: 34,
        flatRating: 78,
        mountainRating: 60,
        puncheurRating: 74,
        timeTrialRating: 72,
        sprintRating: 69,
        staminaRating: 80,
        tacticalIq: 81,
        seasonUciPoints: 350,
        currentFormScore: 71,
        fatigueScore: 34,
        morale: 72,
        egoLevel: 40,
        isInjured: true,
      ),
    ];

    final baseState = NationalChampionshipCampaignState(
      seasonYear: 2026,
      eventType: NationalChampionshipEventType.uciRoadWorldChampionships,
      courseProfile: NationalTeamCourseProfile.puncheurClassics,
      courseDistanceKm:
          NationalTeamCourseProfile.puncheurClassics.defaultDistanceKm,
      elevationGainMeters:
          NationalTeamCourseProfile.puncheurClassics.defaultElevationGainM,
      quota: createPolandQuota(),
      candidatePool: pool,
      selectedSquad: const [],
      federationTrust: 76.0,
      mediaPressure: 52.0,
    );

    return const NationalFederationTeamManagerService()
        .autoSelectOptimalSquad(baseState);
  }

  static NationalChampionshipCampaignState _createBelgiumCampaign() {
    final pool = <NationalSelectionRiderCandidate>[
      const NationalSelectionRiderCandidate(
        riderId: 'bel_remco',
        fullName: 'Remco Evenepoel',
        tradeTeamName: 'Soudal Quick-Step',
        nationalityCode: 'BEL',
        age: 26,
        flatRating: 86,
        mountainRating: 89,
        puncheurRating: 91,
        timeTrialRating: 95,
        sprintRating: 76,
        staminaRating: 90,
        tacticalIq: 86,
        seasonUciPoints: 4650,
        currentFormScore: 91,
        fatigueScore: 20,
        morale: 90,
        egoLevel: 88,
        rivalRiderIds: ['bel_wout'],
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'bel_wout',
        fullName: 'Wout van Aert',
        tradeTeamName: 'Visma | Lease a Bike',
        nationalityCode: 'BEL',
        age: 31,
        flatRating: 90,
        mountainRating: 81,
        puncheurRating: 90,
        timeTrialRating: 89,
        sprintRating: 88,
        staminaRating: 91,
        tacticalIq: 89,
        seasonUciPoints: 3920,
        currentFormScore: 88,
        fatigueScore: 24,
        morale: 85,
        egoLevel: 84,
        rivalRiderIds: ['bel_remco'],
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'bel_philipsen',
        fullName: 'Jasper Philipsen',
        tradeTeamName: 'Alpecin-Deceuninck',
        nationalityCode: 'BEL',
        age: 28,
        flatRating: 86,
        mountainRating: 64,
        puncheurRating: 82,
        timeTrialRating: 71,
        sprintRating: 94,
        staminaRating: 84,
        tacticalIq: 82,
        seasonUciPoints: 3410,
        currentFormScore: 87,
        fatigueScore: 22,
        morale: 86,
        egoLevel: 80,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'bel_stuyven',
        fullName: 'Jasper Stuyven',
        tradeTeamName: 'Lidl-Trek',
        nationalityCode: 'BEL',
        age: 33,
        flatRating: 84,
        mountainRating: 70,
        puncheurRating: 83,
        timeTrialRating: 76,
        sprintRating: 79,
        staminaRating: 86,
        tacticalIq: 89,
        seasonUciPoints: 1620,
        currentFormScore: 80,
        fatigueScore: 26,
        morale: 82,
        egoLevel: 46,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'bel_wellens',
        fullName: 'Tim Wellens',
        tradeTeamName: 'UAE Team Emirates',
        nationalityCode: 'BEL',
        age: 34,
        flatRating: 81,
        mountainRating: 78,
        puncheurRating: 84,
        timeTrialRating: 77,
        sprintRating: 73,
        staminaRating: 85,
        tacticalIq: 86,
        seasonUciPoints: 1490,
        currentFormScore: 82,
        fatigueScore: 25,
        morale: 84,
        egoLevel: 50,
      ),
    ];

    final base = NationalChampionshipCampaignState(
      seasonYear: 2026,
      eventType: NationalChampionshipEventType.uciRoadWorldChampionships,
      courseProfile: NationalTeamCourseProfile.puncheurClassics,
      courseDistanceKm:
          NationalTeamCourseProfile.puncheurClassics.defaultDistanceKm,
      elevationGainMeters:
          NationalTeamCourseProfile.puncheurClassics.defaultElevationGainM,
      quota: const NationalFederationQuotaAllocation(
        nationCode: 'BEL',
        nationNamePl: 'Belgia',
        uciNationRank: 1,
        quotaTier: FederationQuotaTier.elitePowerhouse,
        federationBudgetEur: 620000.0,
        federationPrestige: 95.0,
      ),
      candidatePool: pool,
      selectedSquad: const [],
      federationTrust: 82.0,
      mediaPressure: 88.0,
    );

    return const NationalFederationTeamManagerService()
        .autoSelectOptimalSquad(base);
  }

  static NationalChampionshipCampaignState _createSloveniaCampaign() {
    final pool = <NationalSelectionRiderCandidate>[
      const NationalSelectionRiderCandidate(
        riderId: 'slo_pogacar',
        fullName: 'Tadej Pogačar',
        tradeTeamName: 'UAE Team Emirates',
        nationalityCode: 'SLO',
        age: 27,
        flatRating: 86,
        mountainRating: 96,
        puncheurRating: 95,
        timeTrialRating: 90,
        sprintRating: 83,
        staminaRating: 94,
        tacticalIq: 91,
        seasonUciPoints: 6200,
        currentFormScore: 93,
        fatigueScore: 18,
        morale: 94,
        egoLevel: 82,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'slo_roglic',
        fullName: 'Primož Roglič',
        tradeTeamName: 'Red Bull - BORA',
        nationalityCode: 'SLO',
        age: 36,
        flatRating: 83,
        mountainRating: 92,
        puncheurRating: 90,
        timeTrialRating: 91,
        sprintRating: 80,
        staminaRating: 89,
        tacticalIq: 88,
        seasonUciPoints: 3800,
        currentFormScore: 86,
        fatigueScore: 26,
        morale: 84,
        egoLevel: 80,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'slo_mohoric',
        fullName: 'Matej Mohorič',
        tradeTeamName: 'Bahrain Victorious',
        nationalityCode: 'SLO',
        age: 31,
        flatRating: 85,
        mountainRating: 78,
        puncheurRating: 85,
        timeTrialRating: 80,
        sprintRating: 80,
        staminaRating: 88,
        tacticalIq: 92,
        seasonUciPoints: 2150,
        currentFormScore: 84,
        fatigueScore: 22,
        morale: 86,
        egoLevel: 58,
      ),
      const NationalSelectionRiderCandidate(
        riderId: 'slo_tratnik',
        fullName: 'Jan Tratnik',
        tradeTeamName: 'Red Bull - BORA',
        nationalityCode: 'SLO',
        age: 36,
        flatRating: 84,
        mountainRating: 76,
        puncheurRating: 82,
        timeTrialRating: 83,
        sprintRating: 72,
        staminaRating: 86,
        tacticalIq: 87,
        seasonUciPoints: 1320,
        currentFormScore: 82,
        fatigueScore: 24,
        morale: 85,
        egoLevel: 44,
      ),
    ];

    final base = NationalChampionshipCampaignState(
      seasonYear: 2026,
      eventType: NationalChampionshipEventType.uciRoadWorldChampionships,
      courseProfile: NationalTeamCourseProfile.alpineMountain,
      courseDistanceKm:
          NationalTeamCourseProfile.alpineMountain.defaultDistanceKm,
      elevationGainMeters:
          NationalTeamCourseProfile.alpineMountain.defaultElevationGainM,
      quota: const NationalFederationQuotaAllocation(
        nationCode: 'SLO',
        nationNamePl: 'Słowenia',
        uciNationRank: 2,
        quotaTier: FederationQuotaTier.elitePowerhouse,
        federationBudgetEur: 490000.0,
        federationPrestige: 92.0,
      ),
      candidatePool: pool,
      selectedSquad: const [],
      federationTrust: 88.0,
      mediaPressure: 79.0,
    );

    return const NationalFederationTeamManagerService()
        .autoSelectOptimalSquad(base);
  }
}

/// Kontroler Riverpod zarządzający stanem trybu Selekcjonera Reprezentacji Narodowej.
class NationalFederationTeamManagerNotifier
    extends StateNotifier<NationalChampionshipCampaignState> {
  NationalFederationTeamManagerNotifier({
    NationalFederationTeamManagerService service =
        const NationalFederationTeamManagerService(),
    NationalChampionshipCampaignState? initialState,
  })  : _service = service,
        super(
          initialState ??
              NationalFederationTeamManagerService.createDefaultPolandCampaign(),
        );

  final NationalFederationTeamManagerService _service;

  void switchNationPreset(NationalChampionshipCampaignState preset) {
    state = preset;
  }

  void switchEvent(NationalChampionshipEventType eventType) {
    state = _service.switchEventAndCourse(state, eventType: eventType);
  }

  void switchCourseProfile(NationalTeamCourseProfile courseProfile) {
    state = _service.switchEventAndCourse(state, courseProfile: courseProfile);
  }

  void autoSelectOptimalSquad() {
    state = _service.autoSelectOptimalSquad(state);
  }

  void toggleRiderSelection(String riderId) {
    state = _service.toggleRiderSelection(state, riderId);
  }

  void assignRiderRole(String riderId, NationalRiderTacticalRole role) {
    state = _service.assignRiderRole(state, riderId, role);
  }

  void resolveClubRelease(String riderId) {
    state = _service.resolveClubReleaseNegotiation(state, riderId);
  }

  void setSelectionLocked(bool locked) {
    state = _service.setSelectionLocked(state, locked);
  }

  void simulateChampionship({int? deterministicSeed}) {
    state = _service.simulateChampionshipRace(
      state,
      deterministicSeed: deterministicSeed,
    );
  }
}

final nationalFederationManagerProvider = StateNotifierProvider<
    NationalFederationTeamManagerNotifier, NationalChampionshipCampaignState>(
  (ref) => NationalFederationTeamManagerNotifier(),
);

final nationalSquadChemistryProvider =
    Provider<NationalTeamChemistryReport>((ref) {
  final state = ref.watch(nationalFederationManagerProvider);
  return const NationalFederationTeamManagerService()
      .evaluateSquadChemistry(state);
});

/// Panel UI Selekcjonera Reprezentacji Narodowej na MŚ i IO (responsywny 390x844 / 1024x768 / 1600x900).
class NationalFederationTeamManagerPanel extends ConsumerStatefulWidget {
  const NationalFederationTeamManagerPanel({
    super.key,
    this.isReadOnly = false,
  });

  final bool isReadOnly;

  @override
  ConsumerState<NationalFederationTeamManagerPanel> createState() =>
      _NationalFederationTeamManagerPanelState();
}

class _NationalFederationTeamManagerPanelState
    extends ConsumerState<NationalFederationTeamManagerPanel> {
  CandidatePoolFilter _filter = CandidatePoolFilter.all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nationalFederationManagerProvider);
    final chemistry = ref.watch(nationalSquadChemistryProvider);
    final notifier = ref.read(nationalFederationManagerProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1200;
          final isTablet = width >= 720 && width < 1200;
          final padding = width < 520 ? 12.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, notifier, width < 640),
                const SizedBox(height: 16),
                if (state.statusBannerPl != null) ...[
                  _buildStatusBanner(state.statusBannerPl!),
                  const SizedBox(height: 16),
                ],
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildCandidatePoolCard(state, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildChemistryAndTacticsCard(
                              state,
                              chemistry,
                              notifier,
                            ),
                            if (state.lastSimulationResult != null) ...[
                              const SizedBox(height: 16),
                              _buildSimulationResultCard(
                                state.lastSimulationResult!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                else if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildCandidatePoolCard(state, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildChemistryAndTacticsCard(
                              state,
                              chemistry,
                              notifier,
                            ),
                            if (state.lastSimulationResult != null) ...[
                              const SizedBox(height: 16),
                              _buildSimulationResultCard(
                                state.lastSimulationResult!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildChemistryAndTacticsCard(state, chemistry, notifier),
                      if (state.lastSimulationResult != null) ...[
                        const SizedBox(height: 16),
                        _buildSimulationResultCard(state.lastSimulationResult!),
                      ],
                      const SizedBox(height: 16),
                      _buildCandidatePoolCard(state, notifier),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    NationalChampionshipCampaignState state,
    NationalFederationTeamManagerNotifier notifier,
    bool isCompact,
  ) {
    final presets =
        NationalFederationTeamManagerService.createSampleNationPresets();

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.goldAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selekcjoner Reprezentacji Narodowej',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${state.quota.nationNamePl} (${state.quota.nationCode}) • Rank UCI #${state.quota.uciNationRank} • Sezon ${state.seasonYear}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
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
                  _MetricChip(
                    label: 'Zaufanie Związku',
                    value: '${state.federationTrust.round()}%',
                    accent: AppColors.statusSuccess,
                  ),
                  _MetricChip(
                    label: 'Budżet Kadry',
                    value:
                        '${(state.quota.federationBudgetEur / 1000).round()}k €',
                    accent: AppColors.accentBlue,
                  ),
                  _MetricChip(
                    label: 'Limit UCI',
                    value:
                        '${state.activeStarters.length}/${state.activeMaxStarters}',
                    accent: AppColors.goldAccent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in presets)
                _InteractiveChipButton(
                  label: '${preset.quota.nationNamePl} (${preset.quota.nationCode})',
                  isSelected: state.quota.nationCode == preset.quota.nationCode,
                  isDisabled: widget.isReadOnly,
                  onTap: () => notifier.switchNationPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final event in NationalChampionshipEventType.values)
                _InteractiveChipButton(
                  label: event.shortBadgePl,
                  isSelected: state.eventType == event,
                  isDisabled: widget.isReadOnly,
                  accentColor: AppColors.goldAccent,
                  onTap: () => notifier.switchEvent(event),
                ),
            ],
          ),
          if (!state.eventType.isTimeTrial) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final profile in NationalTeamCourseProfile.values)
                  if (profile != NationalTeamCourseProfile.technicalTimeTrial)
                    _InteractiveChipButton(
                      label: profile.displayNamePl,
                      isSelected: state.courseProfile == profile,
                      isDisabled: widget.isReadOnly,
                      accentColor: AppColors.accentBlue,
                      onTap: () => notifier.switchCourseProfile(profile),
                    ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Trasa: ${state.courseDistanceKm} km • Przewyższenie: ${state.elevationGainMeters} m • ${state.quota.quotaTier.displayNamePl}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String message) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatePoolCard(
    NationalChampionshipCampaignState state,
    NationalFederationTeamManagerNotifier notifier,
  ) {
    final filtered = state.candidatePool.where((c) {
      final isSelected = state.findSelection(c.riderId) != null;
      if (_filter == CandidatePoolFilter.selectedOnly && !isSelected) {
        return false;
      }
      if (_filter == CandidatePoolFilter.conflictsOnly &&
          !c.hasClubConflict &&
          !c.isInjured) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        return c.fullName.toLowerCase().contains(q) ||
            c.tradeTeamName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Pula Kandydatów (${filtered.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final f in CandidatePoolFilter.values)
                    _InteractiveChipButton(
                      label: f.displayNamePl,
                      isSelected: _filter == f,
                      isDisabled: false,
                      onTap: () => setState(() => _filter = f),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: !widget.isReadOnly,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj kolarza lub ekipy WorldTour...',
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
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak kandydatów spełniających kryteria.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (final candidate in filtered) ...[
                  _CandidateRowTile(
                    candidate: candidate,
                    selection: state.findSelection(candidate.riderId),
                    suitability: candidate.overallSelectionScore(
                      state.eventType,
                      state.courseProfile,
                    ),
                    isLocked: state.isSelectionLocked || widget.isReadOnly,
                    onToggleSelect: () =>
                        notifier.toggleRiderSelection(candidate.riderId),
                    onRoleChanged: (role) =>
                        notifier.assignRiderRole(candidate.riderId, role),
                    onResolveClubConflict: () =>
                        notifier.resolveClubRelease(candidate.riderId),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildChemistryAndTacticsCard(
    NationalChampionshipCampaignState state,
    NationalTeamChemistryReport chemistry,
    NationalFederationTeamManagerNotifier notifier,
  ) {
    final cohesionColor = chemistry.cohesionScore >= 75
        ? AppColors.statusSuccess
        : (chemistry.cohesionScore >= 55
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Chemia Kadry & Taktyka',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cohesionColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cohesionColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Spójność ${chemistry.cohesionScore.round()}/100',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cohesionColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressStatBar(
            label: 'Równowaga Taktyczna',
            value: chemistry.tacticalBalanceScore,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 8),
          _ProgressStatBar(
            label: 'Presja Mediów',
            value: state.mediaPressure,
            color: AppColors.primaryAccent,
          ),
          const SizedBox(height: 12),
          if (chemistry.warnings.isNotEmpty) ...[
            for (final warning in chemistry.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.amberWarning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        warning,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.amberWarning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (chemistry.strengths.isNotEmpty) ...[
            for (final strength in chemistry.strengths)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.statusSuccess,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        strength,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Auto-Selekcja',
                icon: Icons.auto_awesome_rounded,
                isPrimary: false,
                isDisabled: state.isSelectionLocked || widget.isReadOnly,
                onTap: notifier.autoSelectOptimalSquad,
              ),
              _ActionButton(
                label: state.isSelectionLocked
                    ? 'Odblokuj Skład'
                    : 'Zatwierdź Listę UCI',
                icon: state.isSelectionLocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                isPrimary: false,
                isDisabled: widget.isReadOnly ||
                    (!state.isSelectionLocked && !chemistry.isEligibleToStart),
                onTap: () => notifier.setSelectionLocked(!state.isSelectionLocked),
              ),
              _ActionButton(
                label: 'Symuluj Finał',
                icon: Icons.flag_rounded,
                isPrimary: true,
                isDisabled: widget.isReadOnly || !chemistry.isEligibleToStart,
                onTap: notifier.simulateChampionship,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationResultCard(
    NationalChampionshipSimulationResult result,
  ) {
    final medalColor = switch (result.medalWon) {
      ChampionshipMedal.gold => AppColors.goldAccent,
      ChampionshipMedal.silver => AppColors.textPrimary,
      ChampionshipMedal.bronze => AppColors.amberWarning,
      ChampionshipMedal.none => AppColors.accentBlue,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: medalColor.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_rounded, color: medalColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Wynik: ${result.medalWon.displayNamePl} (#${result.bestFinishPosition})',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: medalColor,
                  ),
                ),
              ),
              Text(
                '+${result.uciNationPointsEarned} pkt UCI',
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
          Text(
            result.tacticalSummaryPl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          if (result.rainbowJerseyWinnerName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.goldAccent),
              ),
              child: Text(
                'Tęczowa Koszulka Mistrza Świata: ${result.rainbowJerseyWinnerName}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (final placement in result.riderPlacements.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '#${placement.finishPosition}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${placement.fullName} (${placement.role.displayNamePl})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    placement.timeGapSeconds == 0
                        ? 'Zwycięzca'
                        : '+${placement.timeGapSeconds}s',
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
    );
  }
}

class _CandidateRowTile extends StatefulWidget {
  const _CandidateRowTile({
    required this.candidate,
    required this.selection,
    required this.suitability,
    required this.isLocked,
    required this.onToggleSelect,
    required this.onRoleChanged,
    required this.onResolveClubConflict,
  });

  final NationalSelectionRiderCandidate candidate;
  final NationalSquadSelectionEntry? selection;
  final double suitability;
  final bool isLocked;
  final VoidCallback onToggleSelect;
  final ValueChanged<NationalRiderTacticalRole> onRoleChanged;
  final VoidCallback onResolveClubConflict;

  @override
  State<_CandidateRowTile> createState() => _CandidateRowTileState();
}

class _CandidateRowTileState extends State<_CandidateRowTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selection != null;
    final c = widget.candidate;
    final borderColor = isSelected
        ? AppColors.goldAccent.withValues(alpha: 0.7)
        : (_isHovered ? AppColors.accentBlue : AppColors.cardBorder);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceLight
              : (_isHovered
                  ? AppColors.surfaceLight.withValues(alpha: 0.65)
                  : AppColors.background),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.fullName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.tradeTeamName} • Forma ${c.currentFormScore.round()}% • Ego ${c.egoLevel.round()}',
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OVR ${widget.suitability.round()}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentBlue,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _InteractiveChipButton(
                  label: isSelected
                      ? (widget.selection!.isReserve ? 'Rezerwa' : 'W kadrze')
                      : 'Powołaj',
                  isSelected: isSelected,
                  isDisabled: widget.isLocked || c.isInjured,
                  accentColor: AppColors.goldAccent,
                  onTap: widget.onToggleSelect,
                ),
              ],
            ),
            if (c.isInjured || c.hasClubConflict || isSelected) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (c.isInjured)
                    const Text(
                      'Kontuzja wykluczająca start',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.crimsonAlert,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (c.hasClubConflict)
                    _InteractiveChipButton(
                      label: 'Wykup zwolnienie (18k €)',
                      isSelected: false,
                      isDisabled: widget.isLocked,
                      accentColor: AppColors.amberWarning,
                      onTap: widget.onResolveClubConflict,
                    ),
                  if (isSelected && !widget.selection!.isReserve)
                    DropdownButton<NationalRiderTacticalRole>(
                      value: widget.selection!.role,
                      dropdownColor: AppColors.surfaceLight,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      items: NationalRiderTacticalRole.values
                          .where(
                            (r) =>
                                r != NationalRiderTacticalRole.reserveAlternate,
                          )
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.displayNamePl),
                            ),
                          )
                          .toList(),
                      onChanged: widget.isLocked
                          ? null
                          : (role) {
                              if (role != null) widget.onRoleChanged(role);
                            },
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStatBar extends StatelessWidget {
  const _ProgressStatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${clamped.round()}%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped / 100.0,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _InteractiveChipButton extends StatefulWidget {
  const _InteractiveChipButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
    this.accentColor = AppColors.primaryAccent,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _isPressed ? 0.34 : 0.22)
            : (_isHovered
                ? AppColors.surfaceLight
                : AppColors.background);

    final border = widget.isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (_isFocused
            ? AppColors.accentBlue
            : (widget.isSelected
                ? widget.accentColor
                : (_isHovered
                    ? widget.accentColor.withValues(alpha: 0.6)
                    : AppColors.cardBorder)));

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : (widget.isSelected
                        ? widget.accentColor
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : (_isPressed
            ? baseColor.withValues(alpha: 0.75)
            : (_isHovered ? baseColor.withValues(alpha: 0.9) : baseColor));
    final border = _isFocused
        ? AppColors.accentBlue
        : (widget.isPrimary && !widget.isDisabled
            ? AppColors.goldAccent.withValues(alpha: 0.65)
            : AppColors.cardBorder);

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: widget.isDisabled
              ? null
              : (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isDisabled
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.textPrimary,
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

double _clampRating(double value) {
  if (value.isNaN || value.isInfinite) return 50.0;
  return value.clamp(0.0, 100.0);
}

double _safeDouble(dynamic value, double fallback) {
  if (value is num && value.isFinite) return value.toDouble();
  return fallback;
}
