// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Status walki o utrzymanie licencji UCI WorldTour lub awans z UCI ProTeam.
enum RelegationStatus {
  /// Bezpieczna strefa WorldTour (miejsca 1-14) - stabilna przewaga punktowa
  safeWorldTour('Bezpieczny WorldTour', 'Safe WorldTour', '#10B981'),

  /// Strefa bezpośredniego zagrożenia (miejsca 15-18) - tuż nad czerwoną linią
  relegationThreatened('Zagrożony Spadkiem', 'Danger Zone (On the Bubble)', '#F59E0B'),

  /// Strefa spadkowa poniżej 18. miejsca (miejsca 19-20+) - utrata licencji WorldTour!
  relegationZone('Strefa Spadku (ProTeam)', 'Relegation Zone', '#EF4444'),

  /// Ekipa ProTeam na miejscu dającym awans do WorldTour (top 18 rankingu 3-letniego)
  proTeamPromotionZone('Miejsce Awansu do WorldTour', 'Promotion Spot to WorldTour', '#38BDF8'),

  /// Ekipa ProTeam walcząca o automatyczną dziką kartę na Wielkie Toury (top 2 sezonu)
  proTeamWildcardZone('Strefa Dzikiej Karty Grand Tour', 'Grand Tour Wildcard Spot', '#D4AF37'),

  /// Środek stawki ProTeam bez bezpośrednich szans na awans
  proTeamMidfield('Stabilny ProTeam', 'ProTeam Midfield', '#9CA3AF');

  final String polishLabel;
  final String englishLabel;
  final String colorHex;

  const RelegationStatus(this.polishLabel, this.englishLabel, this.colorHex);

  String toJson() => name;

  static RelegationStatus fromJson(String value) {
    return RelegationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RelegationStatus.safeWorldTour,
    );
  }
}

/// Poziom pilności taktycznej walki o punkty w sezonie.
enum TacticalUrgency {
  /// Spokojny komfort punktowy, skupienie na prestiżowych zwycięstwach etapowych
  low('Niski', 'Low Urgency'),

  /// Umiarkowana czujność, warto zbierać punkty w wyścigach 1.Pro
  moderate('Umiarkowany', 'Moderate Caution'),

  /// Wysoka presja, konieczność rotacji liderów na wyścigi jednodniowe 1.1
  critical('Krytyczny', 'High Relegation Alarm'),

  /// Maksymalny stan alarmowy: walka o przetrwanie licencji za wszelką cenę!
  maximumSurviveOrDie('Alarm Maksymalny - Walka o Przetrwanie', 'Maximum Survive or Die');

  final String polishLabel;
  final String englishLabel;

  const TacticalUrgency(this.polishLabel, this.englishLabel);
}

/// Pojedynczy wkład kolarza w bilans punktowy drużyny w danym sezonie.
class RiderPointContribution {
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final int seasonPoints;
  final int rankInTeam;
  final bool isCountedInTop20;
  final int pointsToNextRank;

  const RiderPointContribution({
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.seasonPoints,
    required this.rankInTeam,
    required this.isCountedInTop20,
    required this.pointsToNextRank,
  });

  Map<String, dynamic> toJson() => {
    'riderId': riderId,
    'riderName': riderName,
    'nationalityIso': nationalityIso,
    'seasonPoints': seasonPoints,
    'rankInTeam': rankInTeam,
    'isCountedInTop20': isCountedInTop20,
    'pointsToNextRank': pointsToNextRank,
  };

  factory RiderPointContribution.fromJson(Map<String, dynamic> json) =>
      RiderPointContribution(
        riderId: json['riderId'] as String,
        riderName: json['riderName'] as String,
        nationalityIso: json['nationalityIso'] as String,
        seasonPoints: (json['seasonPoints'] as num).toInt(),
        rankInTeam: (json['rankInTeam'] as num).toInt(),
        isCountedInTop20: json['isCountedInTop20'] as bool,
        pointsToNextRank: (json['pointsToNextRank'] as num).toInt(),
      );
}

/// Zestawienie oficjalnej reguły UCI: punkty zdobyte przez 20 najlepszych kolarzy drużyny ("Rule of 20").
class TeamTop20Breakdown {
  final String teamId;
  final String teamName;
  final int year;
  final int countedTop20Points;
  final int grossAllRidersPoints;
  final int wastedPoints;
  final List<RiderPointContribution> contributingRiders;
  final int cutoffRiderPoints;
  final int nextChallengerPoints;
  final int pointsToBreakIntoTop20;

  const TeamTop20Breakdown({
    required this.teamId,
    required this.teamName,
    required this.year,
    required this.countedTop20Points,
    required this.grossAllRidersPoints,
    required this.wastedPoints,
    required this.contributingRiders,
    required this.cutoffRiderPoints,
    required this.nextChallengerPoints,
    required this.pointsToBreakIntoTop20,
  });

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'teamName': teamName,
    'year': year,
    'countedTop20Points': countedTop20Points,
    'grossAllRidersPoints': grossAllRidersPoints,
    'wastedPoints': wastedPoints,
    'contributingRiders': contributingRiders.map((r) => r.toJson()).toList(),
    'cutoffRiderPoints': cutoffRiderPoints,
    'nextChallengerPoints': nextChallengerPoints,
    'pointsToBreakIntoTop20': pointsToBreakIntoTop20,
  };

  factory TeamTop20Breakdown.fromJson(Map<String, dynamic> json) => TeamTop20Breakdown(
    teamId: json['teamId'] as String,
    teamName: json['teamName'] as String,
    year: (json['year'] as num).toInt(),
    countedTop20Points: (json['countedTop20Points'] as num).toInt(),
    grossAllRidersPoints: (json['grossAllRidersPoints'] as num).toInt(),
    wastedPoints: (json['wastedPoints'] as num).toInt(),
    contributingRiders: (json['contributingRiders'] as List<dynamic>)
        .map((e) => RiderPointContribution.fromJson(e as Map<String, dynamic>))
        .toList(),
    cutoffRiderPoints: (json['cutoffRiderPoints'] as num).toInt(),
    nextChallengerPoints: (json['nextChallengerPoints'] as num).toInt(),
    pointsToBreakIntoTop20: (json['pointsToBreakIntoTop20'] as num).toInt(),
  );
}

/// 3-letni bilans punktowy drużyny w bieżącym cyklu licencyjnym UCI.
class TeamTriennialRecord {
  final String teamId;
  final String teamName;
  final String countryIso;
  final TeamDivision division;
  final int year1Points;
  final int year2Points;
  final int year3Points;
  final Map<int, TeamTop20Breakdown> yearlyBreakdowns;

  const TeamTriennialRecord({
    required this.teamId,
    required this.teamName,
    required this.countryIso,
    required this.division,
    this.year1Points = 0,
    this.year2Points = 0,
    this.year3Points = 0,
    Map<int, TeamTop20Breakdown>? yearlyBreakdowns,
  }) : yearlyBreakdowns = yearlyBreakdowns ?? const {};

  /// Łączna suma punktów top 20 kolarzy z całego 3-letniego cyklu
  int get totalCyclePoints => year1Points + year2Points + year3Points;

  TeamTriennialRecord copyWith({
    String? teamId,
    String? teamName,
    String? countryIso,
    TeamDivision? division,
    int? year1Points,
    int? year2Points,
    int? year3Points,
    Map<int, TeamTop20Breakdown>? yearlyBreakdowns,
  }) {
    return TeamTriennialRecord(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      countryIso: countryIso ?? this.countryIso,
      division: division ?? this.division,
      year1Points: year1Points ?? this.year1Points,
      year2Points: year2Points ?? this.year2Points,
      year3Points: year3Points ?? this.year3Points,
      yearlyBreakdowns: yearlyBreakdowns ?? this.yearlyBreakdowns,
    );
  }

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'teamName': teamName,
    'countryIso': countryIso,
    'division': division.toJson(),
    'year1Points': year1Points,
    'year2Points': year2Points,
    'year3Points': year3Points,
    'yearlyBreakdowns': yearlyBreakdowns.map((k, v) => MapEntry(k.toString(), v.toJson())),
  };

  factory TeamTriennialRecord.fromJson(Map<String, dynamic> json) {
    final breakdowns = <int, TeamTop20Breakdown>{};
    if (json['yearlyBreakdowns'] != null) {
      final map = json['yearlyBreakdowns'] as Map<String, dynamic>;
      map.forEach((k, v) {
        final parsedYear = int.tryParse(k);
        if (parsedYear != null) {
          breakdowns[parsedYear] = TeamTop20Breakdown.fromJson(v as Map<String, dynamic>);
        }
      });
    }

    return TeamTriennialRecord(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      countryIso: json['countryIso'] as String? ?? 'FRA',
      division: TeamDivision.fromJson(json['division'] as String),
      year1Points: (json['year1Points'] as num?)?.toInt() ?? 0,
      year2Points: (json['year2Points'] as num?)?.toInt() ?? 0,
      year3Points: (json['year3Points'] as num?)?.toInt() ?? 0,
      yearlyBreakdowns: breakdowns,
    );
  }
}

/// Wpis w oficjalnej tabeli "Relegation Battle" (Walka o utrzymanie licencji WorldTour).
class RelegationBattleTableEntry {
  final int rank;
  final String teamId;
  final String teamName;
  final String countryIso;
  final TeamDivision division;
  final int year1Points;
  final int year2Points;
  final int year3Points;
  final int totalCyclePoints;
  final int currentSeasonPoints;
  final int bufferOrDeficitTo18th;
  final RelegationStatus relegationStatus;
  final String statusLabel;
  final bool isPlayerTeam;

  const RelegationBattleTableEntry({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.countryIso,
    required this.division,
    required this.year1Points,
    required this.year2Points,
    required this.year3Points,
    required this.totalCyclePoints,
    required this.currentSeasonPoints,
    required this.bufferOrDeficitTo18th,
    required this.relegationStatus,
    required this.statusLabel,
    this.isPlayerTeam = false,
  });

  /// Czy drużyna znajduje się w bezpiecznej strefie WorldTour (miejsca 1-18)
  bool get isInWorldTourZone => rank <= 18;

  /// Czy drużyna ma zagrożoną licencję lub spada (miejsca 15-20)
  bool get isThreatenedOrRelegated => rank >= 15 && rank <= 22;

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'teamId': teamId,
    'teamName': teamName,
    'countryIso': countryIso,
    'division': division.toJson(),
    'year1Points': year1Points,
    'year2Points': year2Points,
    'year3Points': year3Points,
    'totalCyclePoints': totalCyclePoints,
    'currentSeasonPoints': currentSeasonPoints,
    'bufferOrDeficitTo18th': bufferOrDeficitTo18th,
    'relegationStatus': relegationStatus.toJson(),
    'statusLabel': statusLabel,
    'isPlayerTeam': isPlayerTeam,
  };

  factory RelegationBattleTableEntry.fromJson(Map<String, dynamic> json) =>
      RelegationBattleTableEntry(
        rank: (json['rank'] as num).toInt(),
        teamId: json['teamId'] as String,
        teamName: json['teamName'] as String,
        countryIso: json['countryIso'] as String,
        division: TeamDivision.fromJson(json['division'] as String),
        year1Points: (json['year1Points'] as num).toInt(),
        year2Points: (json['year2Points'] as num).toInt(),
        year3Points: (json['year3Points'] as num).toInt(),
        totalCyclePoints: (json['totalCyclePoints'] as num).toInt(),
        currentSeasonPoints: (json['currentSeasonPoints'] as num).toInt(),
        bufferOrDeficitTo18th: (json['bufferOrDeficitTo18th'] as num).toInt(),
        relegationStatus: RelegationStatus.fromJson(json['relegationStatus'] as String),
        statusLabel: json['statusLabel'] as String,
        isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      );
}

/// Diagnoza strategiczna i analiza ryzyka spadku dla menedżera drużyny.
class RelegationRiskAnalysis {
  final String teamId;
  final String teamName;
  final int currentRank;
  final TeamDivision division;
  final int totalCyclePoints;
  final int gapToSafety;
  final RelegationStatus relegationStatus;
  final TacticalUrgency tacticalUrgency;
  final String summaryHeadline;
  final String tacticalAdvice;
  final String top20ThresholdInsight;
  final int remainingTargetPointsNeeded;

  const RelegationRiskAnalysis({
    required this.teamId,
    required this.teamName,
    required this.currentRank,
    required this.division,
    required this.totalCyclePoints,
    required this.gapToSafety,
    required this.relegationStatus,
    required this.tacticalUrgency,
    required this.summaryHeadline,
    required this.tacticalAdvice,
    required this.top20ThresholdInsight,
    required this.remainingTargetPointsNeeded,
  });
}

/// Rekomendacja wyścigu do taktycznego "ciułania punktów" UCI (Point Hunting).
class PointHuntingRecommendation {
  final String raceId;
  final String raceName;
  final RaceCategory category;
  final String categoryCode;
  final String countryIso;
  final int month;
  final double distanceKm;
  final String terrainProfile;
  final int winnerUciPoints;
  final int top10PotentialPoints;
  final String fieldDifficulty;
  final String tacticalReason;
  final List<String> recommendedRiderProfiles;

  const PointHuntingRecommendation({
    required this.raceId,
    required this.raceName,
    required this.category,
    required this.categoryCode,
    required this.countryIso,
    required this.month,
    required this.distanceKm,
    required this.terrainProfile,
    required this.winnerUciPoints,
    required this.top10PotentialPoints,
    required this.fieldDifficulty,
    required this.tacticalReason,
    required this.recommendedRiderProfiles,
  });
}

/// Oficjalne podsumowanie i decyzje licencyjne na koniec 3-letniego cyklu WorldTour.
class TriennialCycleOutcome {
  final int cycleStartYear;
  final int cycleEndYear;
  final List<RelegationBattleTableEntry> finalRankings;
  final List<String> awardedWorldTourTeamIds;
  final List<String> promotedToWorldTourTeamIds;
  final List<String> relegatedToProTeamTeamIds;
  final List<String> mandatoryGrandTourWildcardTeamIds;
  final bool didPlayerTeamSurviveOrPromote;
  final String officialUciAnnouncement;

  const TriennialCycleOutcome({
    required this.cycleStartYear,
    required this.cycleEndYear,
    required this.finalRankings,
    required this.awardedWorldTourTeamIds,
    required this.promotedToWorldTourTeamIds,
    required this.relegatedToProTeamTeamIds,
    required this.mandatoryGrandTourWildcardTeamIds,
    required this.didPlayerTeamSurviveOrPromote,
    required this.officialUciAnnouncement,
  });
}

/// Trwały stan 3-letniego cyklu licencyjnego z pełną serializacją JSON do zapisu kariery.
class UciTriennialCycleState {
  final String cycleId;
  final int startYear;
  final int endYear;
  final int currentYear;
  final Map<String, TeamTriennialRecord> teamRecords;

  UciTriennialCycleState({
    required this.cycleId,
    required this.startYear,
    required this.endYear,
    required this.currentYear,
    Map<String, TeamTriennialRecord>? teamRecords,
  }) : teamRecords = teamRecords ?? {};

  /// Numer roku w 3-letnim cyklu (1, 2 lub 3)
  int get cycleYearIndex => (currentYear - startYear + 1).clamp(1, 3);

  /// Czy bieżący rok jest decydującym 3. rokiem cyklu (Rok Licencyjny)
  bool get isDecisionYear => currentYear >= endYear;

  Map<String, dynamic> toJson() => {
    'cycleId': cycleId,
    'startYear': startYear,
    'endYear': endYear,
    'currentYear': currentYear,
    'teamRecords': teamRecords.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory UciTriennialCycleState.fromJson(Map<String, dynamic> json) {
    final records = <String, TeamTriennialRecord>{};
    if (json['teamRecords'] != null) {
      final map = json['teamRecords'] as Map<String, dynamic>;
      map.forEach((k, v) {
        records[k] = TeamTriennialRecord.fromJson(v as Map<String, dynamic>);
      });
    }

    return UciTriennialCycleState(
      cycleId: json['cycleId'] as String,
      startYear: (json['startYear'] as num).toInt(),
      endYear: (json['endYear'] as num).toInt(),
      currentYear: (json['currentYear'] as num).toInt(),
      teamRecords: records,
    );
  }
}

/// Serwis zarządzający autentycznym 3-letnim cyklem licencyjnym UCI WorldTour
/// oraz tabelą walki o przetrwanie ("Relegation Battle").
class UciPromotionRelegationCycleService {
  final UciTriennialCycleState state;

  UciPromotionRelegationCycleService({UciTriennialCycleState? state})
      : state = state ?? createDefaultCycleState(currentYear: 2026);

  /// Tworzy domyślny stan 3-letniego cyklu (np. 2026-2028).
  static UciTriennialCycleState createDefaultCycleState({required int currentYear}) {
    // Obliczenie granic cyklu 3-letniego (np. 2026-2028, 2029-2031)
    const cycleBase = 2026;
    final cycleOffset = ((currentYear - cycleBase) / 3).floor() * 3;
    final startYear = cycleBase + cycleOffset;
    final endYear = startYear + 2;

    return UciTriennialCycleState(
      cycleId: 'cycle_${startYear}_$endYear',
      startYear: startYear,
      endYear: endYear,
      currentYear: currentYear,
    );
  }

  // ===========================================================================
  // 1. REGUŁA TOP 20 KOLARZY UCI ("RULE OF 20")
  // ===========================================================================

  /// Oblicza sumę punktów zdobytych przez topowych 20 kolarzy drużyny w danym sezonie.
  /// Punkty 21. i kolejnych kolarzy są ignorowane w oficjalnym rankingu UCI!
  TeamTop20Breakdown calculateTeamTop20Points({
    required String teamId,
    required String teamName,
    required int year,
    required Map<String, int> riderSeasonPoints,
    List<Rider>? roster,
  }) {
    // 1. Złożenie listy wszystkich punktujących kolarzy
    final List<_ScoredRider> scoredList = [];

    riderSeasonPoints.forEach((riderId, pts) {
      String name = 'Kolarz $riderId';
      String nationality = 'FRA';

      if (roster != null) {
        final match = roster.where((r) => r.id == riderId);
        if (match.isNotEmpty) {
          name = match.first.fullName;
          nationality = match.first.nationalityIso;
        }
      }

      scoredList.add(_ScoredRider(
        riderId: riderId,
        name: name,
        nationalityIso: nationality,
        points: pts,
      ));
    });

    // 2. Sortowanie kolarzy od największej do najmniejszej liczby punktów
    scoredList.sort((a, b) => b.points.compareTo(a.points));

    int countedTop20 = 0;
    int grossAll = 0;
    final List<RiderPointContribution> contributions = [];

    for (int i = 0; i < scoredList.length; i++) {
      final entry = scoredList[i];
      final rankInTeam = i + 1;
      final bool isTop20 = rankInTeam <= 20;

      grossAll += entry.points;
      if (isTop20) {
        countedTop20 += entry.points;
      }

      final pointsToNext = i > 0 ? (scoredList[i - 1].points - entry.points) : 0;

      contributions.add(RiderPointContribution(
        riderId: entry.riderId,
        riderName: entry.name,
        nationalityIso: entry.nationalityIso,
        seasonPoints: entry.points,
        rankInTeam: rankInTeam,
        isCountedInTop20: isTop20,
        pointsToNextRank: math.max(0, pointsToNext),
      ));
    }

    final wasted = grossAll - countedTop20;
    final cutoffPoints = contributions.length >= 20 ? contributions[19].seasonPoints : 0;
    final challengerPoints = contributions.length >= 21 ? contributions[20].seasonPoints : 0;
    final pointsToBreakIn = contributions.length >= 21 ? (cutoffPoints - challengerPoints + 1) : 0;

    return TeamTop20Breakdown(
      teamId: teamId,
      teamName: teamName,
      year: year,
      countedTop20Points: countedTop20,
      grossAllRidersPoints: grossAll,
      wastedPoints: wasted,
      contributingRiders: contributions,
      cutoffRiderPoints: cutoffPoints,
      nextChallengerPoints: challengerPoints,
      pointsToBreakIntoTop20: math.max(0, pointsToBreakIn),
    );
  }

  /// Aktualizuje bilans punktowy danej ekipy w bieżącym roku cyklu.
  void recordSeasonPointsForTeam({
    required String teamId,
    required String teamName,
    required String countryIso,
    required TeamDivision division,
    required int year,
    required TeamTop20Breakdown breakdown,
  }) {
    final record = state.teamRecords[teamId] ??
        TeamTriennialRecord(
          teamId: teamId,
          teamName: teamName,
          countryIso: countryIso,
          division: division,
        );

    final updatedBreakdowns = Map<int, TeamTop20Breakdown>.from(record.yearlyBreakdowns);
    updatedBreakdowns[year] = breakdown;

    final cycleYearIndex = (year - state.startYear + 1).clamp(1, 3);
    int y1 = record.year1Points;
    int y2 = record.year2Points;
    int y3 = record.year3Points;

    if (cycleYearIndex == 1) {
      y1 = breakdown.countedTop20Points;
    } else if (cycleYearIndex == 2) {
      y2 = breakdown.countedTop20Points;
    } else if (cycleYearIndex == 3) {
      y3 = breakdown.countedTop20Points;
    }

    state.teamRecords[teamId] = record.copyWith(
      teamName: teamName,
      countryIso: countryIso,
      division: division,
      year1Points: y1,
      year2Points: y2,
      year3Points: y3,
      yearlyBreakdowns: updatedBreakdowns,
    );
  }

  // ===========================================================================
  // 2. TABELA WALKI O PRZETRWANIE ("RELEGATION BATTLE TABLE")
  // ===========================================================================

  /// Generuje oficjalną tabelę "Relegation Battle" ze wszystkimi zespołami WorldTour i ProTeam.
  List<RelegationBattleTableEntry> generateRelegationBattleTable({
    required int currentYear,
    String? playerTeamId,
  }) {
    if (state.teamRecords.isEmpty) {
      return [];
    }

    // 1. Sortowanie drużyn według sumy punktów 3-letniego cyklu
    final sortedRecords = state.teamRecords.values.toList()
      ..sort((a, b) => b.totalCyclePoints.compareTo(a.totalCyclePoints));

    // 2. Wyznaczenie progu 18. miejsca (bezpieczna granica WorldTour)
    final int safeCutoffPoints = sortedRecords.length >= 18
        ? sortedRecords[17].totalCyclePoints
        : (sortedRecords.isNotEmpty ? sortedRecords.last.totalCyclePoints : 0);

    final List<RelegationBattleTableEntry> table = [];

    for (int i = 0; i < sortedRecords.length; i++) {
      final rec = sortedRecords[i];
      final rank = i + 1;
      final int bufferOrDeficit = rec.totalCyclePoints - safeCutoffPoints;

      // Wyznaczanie statusu
      final status = _determineTeamStatus(rank, rec.division);
      final statusLabel = _formatStatusLabel(rank, bufferOrDeficit, rec.division);

      final cycleYearIdx = (currentYear - state.startYear + 1).clamp(1, 3);
      final currentSeasonPts = cycleYearIdx == 1
          ? rec.year1Points
          : (cycleYearIdx == 2 ? rec.year2Points : rec.year3Points);

      table.add(RelegationBattleTableEntry(
        rank: rank,
        teamId: rec.teamId,
        teamName: rec.teamName,
        countryIso: rec.countryIso,
        division: rec.division,
        year1Points: rec.year1Points,
        year2Points: rec.year2Points,
        year3Points: rec.year3Points,
        totalCyclePoints: rec.totalCyclePoints,
        currentSeasonPoints: currentSeasonPts,
        bufferOrDeficitTo18th: bufferOrDeficit,
        relegationStatus: status,
        statusLabel: statusLabel,
        isPlayerTeam: rec.teamId == playerTeamId,
      ));
    }

    return table;
  }

  static RelegationStatus _determineTeamStatus(int rank, TeamDivision division) {
    if (division == TeamDivision.worldTour) {
      if (rank <= 14) return RelegationStatus.safeWorldTour;
      if (rank <= 18) return RelegationStatus.relegationThreatened;
      return RelegationStatus.relegationZone;
    } else {
      if (rank <= 18) return RelegationStatus.proTeamPromotionZone;
      if (rank <= 20) return RelegationStatus.proTeamWildcardZone;
      return RelegationStatus.proTeamMidfield;
    }
  }

  static String _formatStatusLabel(int rank, int buffer, TeamDivision division) {
    if (division == TeamDivision.worldTour) {
      if (rank <= 14) {
        return 'Bezpieczny (+$buffer pkt)';
      } else if (rank <= 18) {
        return 'Zagrożony (+$buffer pkt nad kreską)';
      } else {
        return 'Strefa Spadku ($buffer pkt do bezpiecznego 18. miejsca)';
      }
    } else {
      if (rank <= 18) {
        return 'AWANS DO WORLDTOUR (+$buffer pkt)';
      } else if (rank <= 20) {
        return 'Dzika karta Grand Tour ($buffer pkt do awansu)';
      } else {
        return 'ProTeam ($buffer pkt)';
      }
    }
  }

  // ===========================================================================
  // 3. DIAGNOZA STRATEGICZNA DLA MENEDŻERA (RELEGATION RISK ANALYSIS)
  // ===========================================================================

  /// Przeprowadza dogłębną analizę sytuacji drużyny i rekomenduje strategię punktową.
  RelegationRiskAnalysis getRelegationRiskAnalysis({
    required String teamId,
    required int currentYear,
  }) {
    final table = generateRelegationBattleTable(currentYear: currentYear);
    final entryIndex = table.indexWhere((e) => e.teamId == teamId);

    if (entryIndex == -1) {
      return RelegationRiskAnalysis(
        teamId: teamId,
        teamName: 'Twoja Drużyna',
        currentRank: 1,
        division: TeamDivision.worldTour,
        totalCyclePoints: 0,
        gapToSafety: 0,
        relegationStatus: RelegationStatus.safeWorldTour,
        tacticalUrgency: TacticalUrgency.low,
        summaryHeadline: 'Brak danych punktowych w bieżącym cyklu',
        tacticalAdvice: 'Kontynuuj standardowy plan wyścigowy.',
        top20ThresholdInsight: 'Wszyscy kolarze zdobywają punkty do rankingu.',
        remainingTargetPointsNeeded: 0,
      );
    }

    final entry = table[entryIndex];
    final bool isDecidingYear = state.isDecisionYear;

    TacticalUrgency urgency;
    String headline;
    String advice;

    if (entry.division == TeamDivision.worldTour) {
      if (entry.rank <= 14) {
        urgency = TacticalUrgency.low;
        headline = 'Stabilna pozycja WorldTour (${entry.rank}. miejsce)';
        advice = 'Twoja przewaga punktowa (${entry.bufferOrDeficitTo18th} pkt) pozwala na skupienie się na wygranych etapowych w WorldTourze bez presji na ciułanie punktów.';
      } else if (entry.rank <= 18) {
        urgency = isDecidingYear ? TacticalUrgency.critical : TacticalUrgency.moderate;
        headline = 'Strefa Zagrożenia Spadkiem (${entry.rank}. miejsce)';
        advice = 'Przewaga nad 19. miejscem wynosi zaledwie ${entry.bufferOrDeficitTo18th} pkt! Wyślij drugą linię liderów na wyścigi jednodniowe 1.Pro w Belgii i Francji, aby zabezpieczyć licencję przed finałem sezonu.';
      } else {
        urgency = TacticalUrgency.maximumSurviveOrDie;
        headline = 'ALARM! Strefa Spadku do ProTeam (${entry.rank}. miejsce)';
        advice = 'Tracisz ${entry.bufferOrDeficitTo18th.abs()} pkt do bezpiecznego 18. miejsca! Natychmiast przekieruj wszystkich dynamicznych kolarzy i sprinterów na wyścigi 1.Pro i 1.1. 2. miejsce we włoskim klasyku daje więcej punktów niż 14. lokata w Tour de France!';
      }
    } else {
      // ProTeam
      if (entry.rank <= 18) {
        urgency = TacticalUrgency.critical;
        headline = 'Sensacyjny awans do WorldTour na wyciągnięcie ręki! (${entry.rank}. miejsce)';
        advice = 'Jesteś w top 18 rankingu 3-letniego! Utrzymanie tej pozycji zapewni licencję WorldTour na kolejne 3 sezony. Walcz o każdy punkt w wyścigach etapowych 2.Pro.';
      } else {
        urgency = TacticalUrgency.moderate;
        headline = 'Walka o Dzikie Karty Grand Tour (${entry.rank}. miejsce)';
        advice = 'Jeśli nie awansujesz do WorldTouru, celuj w top 2 rocznego rankingu ProTeam, co gwarantuje automatyczny start w Tour de France, Giro i Vuelcie.';
      }
    }

    // Insight o progu 20 kolarza
    final record = state.teamRecords[teamId];
    final breakdown = record?.yearlyBreakdowns[currentYear];
    String thresholdInsight = 'Wszyscy kolarze zdobywają punkty.';

    if (breakdown != null && breakdown.contributingRiders.length > 20) {
      final r20 = breakdown.cutoffRiderPoints;
      final r21 = breakdown.nextChallengerPoints;
      final diff = breakdown.pointsToBreakIntoTop20;
      thresholdInsight = 'Próg punktowy 20. kolarza w Twojej ekipie wynosi $r20 pkt. Kolarz na 21. miejscu ma $r21 pkt (brakuje mu $diff pkt, aby jego punkty zaczęły zasilać oficjalny ranking UCI zespołu).';
    }

    final targetNeeded = entry.bufferOrDeficitTo18th < 0
        ? entry.bufferOrDeficitTo18th.abs() + 100
        : 0;

    return RelegationRiskAnalysis(
      teamId: teamId,
      teamName: entry.teamName,
      currentRank: entry.rank,
      division: entry.division,
      totalCyclePoints: entry.totalCyclePoints,
      gapToSafety: entry.bufferOrDeficitTo18th,
      relegationStatus: entry.relegationStatus,
      tacticalUrgency: urgency,
      summaryHeadline: headline,
      tacticalAdvice: advice,
      top20ThresholdInsight: thresholdInsight,
      remainingTargetPointsNeeded: targetNeeded,
    );
  }

  // ===========================================================================
  // 4. STRATEGIA "CIUŁANIA PUNKTÓW" (POINT HUNTING RECOMMENDATIONS)
  // ===========================================================================

  /// Zwraca listę rekomendowanych wyścigów kategorii 1.Pro / 1.1 o wysokim stosunku punktów do trudności stawki.
  List<PointHuntingRecommendation> getPointHuntingRecommendations({
    required int currentMonth,
    String? terrainFocus,
  }) {
    final allRaces = _getCuratedPointHuntingRaces();

    // Filtrowanie wyścigów na dany miesiąc i kolejne miesiące sezonu
    return allRaces.where((r) {
      final bool monthMatch = r.month >= currentMonth;
      final bool terrainMatch = terrainFocus == null ||
          r.terrainProfile.toLowerCase().contains(terrainFocus.toLowerCase());
      return monthMatch && terrainMatch;
    }).toList();
  }

  static List<PointHuntingRecommendation> _getCuratedPointHuntingRaces() {
    return const [
      PointHuntingRecommendation(
        raceId: 'race_kbk_pro',
        raceName: 'Kuurne-Bruxelles-Kuurne',
        category: RaceCategory.proSeries,
        categoryCode: '1.Pro',
        countryIso: 'BEL',
        month: 3,
        distanceKm: 196.0,
        terrainProfile: 'Bruki i pagórki, finisz ze zredukowanego peletonu',
        winnerUciPoints: 200,
        top10PotentialPoints: 550,
        fieldDifficulty: 'Umiarkowana (wielu faworytów odpoczywa po Omloop)',
        tacticalReason: '200 pkt za zwycięstwo! Doskonała okazja dla szybkiego sprintera radzącego sobie na brukach.',
        recommendedRiderProfiles: ['Sprinter z wysokim brukiem', 'Klasykowiec'],
      ),
      PointHuntingRecommendation(
        raceId: 'race_gp_denain',
        raceName: 'Grand Prix de Denain',
        category: RaceCategory.proSeries,
        categoryCode: '1.Pro',
        countryIso: 'FRA',
        month: 3,
        distanceKm: 200.0,
        terrainProfile: 'Północne sektory brukowe, płasko',
        winnerUciPoints: 200,
        top10PotentialPoints: 500,
        fieldDifficulty: 'Średnia',
        tacticalReason: 'Mniejsza obsada ekip WorldTouru otwiera szansę na wysokie punkty dla pomocników.',
        recommendedRiderProfiles: ['Klasykowiec brukowy', 'Pociąg sprinterski'],
      ),
      PointHuntingRecommendation(
        raceId: 'race_brabantse_pijl',
        raceName: 'De Brabantse Pijl',
        category: RaceCategory.proSeries,
        categoryCode: '1.Pro',
        countryIso: 'BEL',
        month: 4,
        distanceKm: 205.0,
        terrainProfile: 'Krótkie, strome ścianki flamandzkie (Punch)',
        winnerUciPoints: 200,
        top10PotentialPoints: 520,
        fieldDifficulty: 'Średnio-Wysoka',
        tacticalReason: 'Pomost między brukami a Ardenami. Finisz pod górkę dla puncheura.',
        recommendedRiderProfiles: ['Puncheur', 'All-rounder z mocnym zrywem'],
      ),
      PointHuntingRecommendation(
        raceId: 'race_tro_bro_leon',
        raceName: 'Tro-Bro Léon ("Piekło Bretanii")',
        category: RaceCategory.proSeries,
        categoryCode: '1.Pro',
        countryIso: 'FRA',
        month: 5,
        distanceKm: 204.0,
        terrainProfile: 'Szutry bretońskie (Ribinoù), wiatr, wąskie drogi',
        winnerUciPoints: 200,
        top10PotentialPoints: 480,
        fieldDifficulty: 'Średnia (lokalna specyfika nawierzchni)',
        tacticalReason: 'Wyścig premiujący spryt i pozycjonowanie na szutrach, łatwiej o punkty niż w Giro.',
        recommendedRiderProfiles: ['Specjalista od szutrów', 'Wytrzymały uciekinier'],
      ),
      PointHuntingRecommendation(
        raceId: 'race_circuit_wallonie',
        raceName: 'Circuit de Wallonie',
        category: RaceCategory.class1,
        categoryCode: '1.1',
        countryIso: 'BEL',
        month: 5,
        distanceKm: 191.0,
        terrainProfile: 'Pofałdowany teren, finisz dla peletonu',
        winnerUciPoints: 125,
        top10PotentialPoints: 340,
        fieldDifficulty: 'Niska (głównie ekipy ProTeam i Continental)',
        tacticalReason: 'Kluczowy wyścig do zgarnięcia 125 pkt za 1. miejsce przy braku największych gwiazd WorldTouru.',
        recommendedRiderProfiles: ['Sprinter', 'Puncheur'],
      ),
      PointHuntingRecommendation(
        raceId: 'race_gp_fourmies',
        raceName: 'Grand Prix de Fourmies',
        category: RaceCategory.proSeries,
        categoryCode: '1.Pro',
        countryIso: 'FRA',
        month: 9,
        distanceKm: 205.0,
        terrainProfile: 'Płaska runda sprinterska',
        winnerUciPoints: 200,
        top10PotentialPoints: 560,
        fieldDifficulty: 'Średnia',
        tacticalReason: 'Wrześniowy raj dla sprinterów. 3 kolarzy w top 10 gwarantuje ponad 250 cennych punktów UCI!',
        recommendedRiderProfiles: ['Czysty sprinter', 'Rozprowadzający'],
      ),
      PointHuntingRecommendation(
        raceId: 'race_tour_vendee',
        raceName: 'Tour de Vendée',
        category: RaceCategory.class1,
        categoryCode: '1.1',
        countryIso: 'FRA',
        month: 10,
        distanceKm: 207.0,
        terrainProfile: 'Płasko i wietrznie',
        winnerUciPoints: 125,
        top10PotentialPoints: 350,
        fieldDifficulty: 'Niska (koniec sezonu, zmęczenie peletonu)',
        tacticalReason: 'Ostatnia szansa na uratowanie licencji WorldTour przed zamknięciem 3-letniego cyklu!',
        recommendedRiderProfiles: ['Sprinter', 'Kolarz o wysokiej regeneracji'],
      ),
      PointHuntingRecommendation(
        raceId: 'race_coppa_bernocchi',
        raceName: 'Coppa Bernocchi',
        category: RaceCategory.proSeries,
        categoryCode: '1.Pro',
        countryIso: 'ITA',
        month: 10,
        distanceKm: 187.0,
        terrainProfile: 'Włoskie pagórki i płaski dojazd do Legnano',
        winnerUciPoints: 200,
        top10PotentialPoints: 500,
        fieldDifficulty: 'Średnia',
        tacticalReason: 'Trittico Lombardo: idealna trasa do zrobienia przewagi nad rywalami w strefie spadkowej.',
        recommendedRiderProfiles: ['All-rounder', 'Sprinter z odpornością na pagórki'],
      ),
    ];
  }

  // ===========================================================================
  // 5. DECYZJE LICENCYJNE NA KONIEC 3-LETNIEGO CYKLU (PROMOTION / RELEGATION)
  // ===========================================================================

  /// Przeprowadza oficjalne przyznanie licencji WorldTour na kolejny 3-letni cykl
  /// na podstawie sumy punktów top 20 kolarzy z 3 ostatnich sezonów.
  TriennialCycleOutcome evaluateTriennialCycleDecisions({
    required int finalYear,
    String? playerTeamId,
  }) {
    final table = generateRelegationBattleTable(
      currentYear: finalYear,
      playerTeamId: playerTeamId,
    );

    // 1. Wyłonienie 18 ekip z prawem do licencji WorldTour
    final top18Entries = table.take(18).toList();
    final List<String> awardedWorldTourIds = top18Entries.map((e) => e.teamId).toList();

    // 2. Wyłonienie awansujących (ekipy ProTeam, które weszły do top 18)
    final promotedIds = top18Entries
        .where((e) => e.division == TeamDivision.proTeam)
        .map((e) => e.teamId)
        .toList();

    // 3. Wyłonienie spadających (ekipy WorldTour, które spadły na miejsca 19+)
    final relegatedIds = table
        .skip(18)
        .where((e) => e.division == TeamDivision.worldTour)
        .map((e) => e.teamId)
        .toList();

    // 4. Wyłonienie dzikich kart na Grand Toury (2 najlepsze ekipy ProTeam w rocznym rankingu)
    final proTeamsSortedBySeason = table
        .where((e) => e.division == TeamDivision.proTeam && !promotedIds.contains(e.teamId))
        .toList()
      ..sort((a, b) => b.currentSeasonPoints.compareTo(a.currentSeasonPoints));

    final wildcardIds = proTeamsSortedBySeason.take(2).map((e) => e.teamId).toList();

    // 5. Status drużyny gracza
    bool playerSuccess = false;
    if (playerTeamId != null) {
      final playerEntry = table.where((e) => e.teamId == playerTeamId);
      if (playerEntry.isNotEmpty) {
        playerSuccess = playerEntry.first.rank <= 18;
      }
    }

    final announcement = _generateUciAnnouncement(
      startYear: state.startYear,
      endYear: state.endYear,
      promotedCount: promotedIds.length,
      relegatedCount: relegatedIds.length,
      playerSuccess: playerSuccess,
    );

    return TriennialCycleOutcome(
      cycleStartYear: state.startYear,
      cycleEndYear: state.endYear,
      finalRankings: table,
      awardedWorldTourTeamIds: awardedWorldTourIds,
      promotedToWorldTourTeamIds: promotedIds,
      relegatedToProTeamTeamIds: relegatedIds,
      mandatoryGrandTourWildcardTeamIds: wildcardIds,
      didPlayerTeamSurviveOrPromote: playerSuccess,
      officialUciAnnouncement: announcement,
    );
  }

  static String _generateUciAnnouncement({
    required int startYear,
    required int endYear,
    required int promotedCount,
    required int relegatedCount,
    required bool playerSuccess,
  }) {
    return 'OFICJALNY KOMUNIKAT KOMISJI LICENCYJNEJ UCI • CYKL $startYear–$endYear\n\n'
        'Zakończył się 3-letni cykl rankingowy UCI WorldTour. Zgodnie z regulaminem, 18 najlepszych zespołów '
        'w 3-letnim rankingu sumy punktów 20 najlepszych kolarzy otrzymało licencje UCI WorldTour na kolejny 3-letni okres.\n'
        '• Liczba awansów do WorldTour: $promotedCount\n'
        '• Liczba spadków do ProTeam: $relegatedCount\n'
        '${playerSuccess ? "Status Twojej Drużyny: ZWYCIĘSTWO! Licencja WorldTour została pomyślnie obroniona / zdobyta!" : "Status Twojej Drużyny: Drużyna znalazła się poniżej 18. miejsca i traci status WorldTour."}';
  }
}

class _ScoredRider {
  final String riderId;
  final String name;
  final String nationalityIso;
  final int points;

  const _ScoredRider({
    required this.riderId,
    required this.name,
    required this.nationalityIso,
    required this.points,
  });
}
