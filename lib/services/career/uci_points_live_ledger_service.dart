// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../../engine/simulation/stage_results_calculator.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import 'uci_promotion_relegation_cycle_service.dart';

/// Źródło przyznania punktów UCI w księdze punktowej na żywo.
enum UciPointAwardSource {
  oneDayRaceFinish('Wyścig jednodniowy', 'One-Day Race'),
  stageFinish('Wynik etapu', 'Stage Finish'),
  generalClassification('Klasyfikacja generalna', 'General Classification'),
  leaderJerseyDay('Koszulka lidera (dzień)', 'Leader Jersey Day'),
  secondaryClassification('Klasyfikacja poboczna', 'Secondary Classification');

  final String polishLabel;
  final String englishLabel;

  const UciPointAwardSource(this.polishLabel, this.englishLabel);

  String toJson() => name;

  static UciPointAwardSource fromJson(String value) {
    return UciPointAwardSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UciPointAwardSource.oneDayRaceFinish,
    );
  }
}

/// Pojedynczy, niezmienny wpis księgowy w księdze punktów UCI.
class UciLedgerEntry {
  final String entryId;
  final int seasonYear;
  final DateTime awardedAt;
  final String raceId;
  final String raceName;
  final RaceCategory raceCategory;
  final int? stageNumber;
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final UciPointAwardSource source;
  final int? rank;
  final int points;
  final String description;

  const UciLedgerEntry({
    required this.entryId,
    required this.seasonYear,
    required this.awardedAt,
    required this.raceId,
    required this.raceName,
    required this.raceCategory,
    this.stageNumber,
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.source,
    this.rank,
    required this.points,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'seasonYear': seasonYear,
        'awardedAt': awardedAt.toIso8601String(),
        'raceId': raceId,
        'raceName': raceName,
        'raceCategory': raceCategory.toJson(),
        'stageNumber': stageNumber,
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'teamName': teamName,
        'source': source.toJson(),
        'rank': rank,
        'points': points,
        'description': description,
      };

  factory UciLedgerEntry.fromJson(Map<String, dynamic> json) {
    return UciLedgerEntry(
      entryId: json['entryId'] as String,
      seasonYear: (json['seasonYear'] as num).toInt(),
      awardedAt: DateTime.parse(json['awardedAt'] as String),
      raceId: json['raceId'] as String,
      raceName: json['raceName'] as String,
      raceCategory: RaceCategory.fromJson(json['raceCategory'] as String),
      stageNumber: (json['stageNumber'] as num?)?.toInt(),
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      source: UciPointAwardSource.fromJson(json['source'] as String),
      rank: (json['rank'] as num?)?.toInt(),
      points: (json['points'] as num).toInt(),
      description: json['description'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UciLedgerEntry && other.entryId == entryId;
  }

  @override
  int get hashCode => entryId.hashCode;
}

/// Wpis w rankingu indywidualnym UCI aktualizowanym na żywo.
class UciIndividualRankingEntry {
  final int rank;
  final String riderId;
  final String riderName;
  final String nationalityIso;
  final String teamId;
  final String teamName;
  final int seasonPoints;
  final int careerPoints;
  final int oneDayPoints;
  final int stagePoints;
  final int gcPoints;
  final int jerseyDayPoints;

  const UciIndividualRankingEntry({
    required this.rank,
    required this.riderId,
    required this.riderName,
    required this.nationalityIso,
    required this.teamId,
    required this.teamName,
    required this.seasonPoints,
    required this.careerPoints,
    this.oneDayPoints = 0,
    this.stagePoints = 0,
    this.gcPoints = 0,
    this.jerseyDayPoints = 0,
  });

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'riderId': riderId,
        'riderName': riderName,
        'nationalityIso': nationalityIso,
        'teamId': teamId,
        'teamName': teamName,
        'seasonPoints': seasonPoints,
        'careerPoints': careerPoints,
        'oneDayPoints': oneDayPoints,
        'stagePoints': stagePoints,
        'gcPoints': gcPoints,
        'jerseyDayPoints': jerseyDayPoints,
      };

  factory UciIndividualRankingEntry.fromJson(Map<String, dynamic> json) {
    return UciIndividualRankingEntry(
      rank: (json['rank'] as num).toInt(),
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityIso: json['nationalityIso'] as String? ?? 'FRA',
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      seasonPoints: (json['seasonPoints'] as num).toInt(),
      careerPoints: (json['careerPoints'] as num).toInt(),
      oneDayPoints: (json['oneDayPoints'] as num?)?.toInt() ?? 0,
      stagePoints: (json['stagePoints'] as num?)?.toInt() ?? 0,
      gcPoints: (json['gcPoints'] as num?)?.toInt() ?? 0,
      jerseyDayPoints: (json['jerseyDayPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Wynik pojedynczej operacji księgowania punktów UCI z natychmiastowym odświeżeniem obu rankingów.
class UciLiveLedgerBatchResult {
  final List<UciLedgerEntry> awardedEntries;
  final int totalPointsAwarded;
  final Map<String, int> pointsByRider;
  final Map<String, int> pointsByTeam;
  final List<Rider> updatedRiders;
  final List<CyclingTeam> updatedTeams;
  final List<UciIndividualRankingEntry> individualRanking;
  final List<RelegationBattleTableEntry> triennialTable;

  const UciLiveLedgerBatchResult({
    required this.awardedEntries,
    required this.totalPointsAwarded,
    required this.pointsByRider,
    required this.pointsByTeam,
    required this.updatedRiders,
    required this.updatedTeams,
    required this.individualRanking,
    required this.triennialTable,
  });
}

/// Trwały stan księgi punktów UCI wraz z mapami bieżącego sezonu i cyklem 3-letnim.
class UciPointsLedgerState {
  final int seasonYear;
  final List<UciLedgerEntry> entries;
  final Map<String, int> riderSeasonPoints;
  final Map<String, Map<UciPointAwardSource, int>> riderPointsBySource;
  final Map<String, String> riderTeamIdMap;
  final Map<String, String> riderNameMap;
  final UciTriennialCycleState triennialCycleState;

  UciPointsLedgerState({
    required this.seasonYear,
    List<UciLedgerEntry>? entries,
    Map<String, int>? riderSeasonPoints,
    Map<String, Map<UciPointAwardSource, int>>? riderPointsBySource,
    Map<String, String>? riderTeamIdMap,
    Map<String, String>? riderNameMap,
    UciTriennialCycleState? triennialCycleState,
  })  : entries = entries ?? [],
        riderSeasonPoints = riderSeasonPoints ?? {},
        riderPointsBySource = riderPointsBySource ?? {},
        riderTeamIdMap = riderTeamIdMap ?? {},
        riderNameMap = riderNameMap ?? {},
        triennialCycleState = triennialCycleState ??
            UciPromotionRelegationCycleService.createDefaultCycleState(
              currentYear: seasonYear,
            );

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'entries': entries.map((e) => e.toJson()).toList(),
        'riderSeasonPoints': riderSeasonPoints,
        'riderPointsBySource': riderPointsBySource.map(
          (riderId, srcMap) => MapEntry(
            riderId,
            srcMap.map((src, pts) => MapEntry(src.toJson(), pts)),
          ),
        ),
        'riderTeamIdMap': riderTeamIdMap,
        'riderNameMap': riderNameMap,
        'triennialCycleState': triennialCycleState.toJson(),
      };

  factory UciPointsLedgerState.fromJson(Map<String, dynamic> json) {
    final parsedEntries = (json['entries'] as List<dynamic>? ?? const [])
        .map((e) => UciLedgerEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final parsedRiderPts = <String, int>{};
    (json['riderSeasonPoints'] as Map<String, dynamic>? ?? const {}).forEach(
      (k, v) => parsedRiderPts[k] = (v as num).toInt(),
    );

    final parsedBySource = <String, Map<UciPointAwardSource, int>>{};
    (json['riderPointsBySource'] as Map<String, dynamic>? ?? const {}).forEach(
      (riderId, rawMap) {
        final inner = <UciPointAwardSource, int>{};
        (rawMap as Map<String, dynamic>).forEach((srcKey, ptsVal) {
          inner[UciPointAwardSource.fromJson(srcKey)] = (ptsVal as num).toInt();
        });
        parsedBySource[riderId] = inner;
      },
    );

    final parsedTeamMap = <String, String>{};
    (json['riderTeamIdMap'] as Map<String, dynamic>? ?? const {}).forEach(
      (k, v) => parsedTeamMap[k] = v.toString(),
    );

    final parsedNameMap = <String, String>{};
    (json['riderNameMap'] as Map<String, dynamic>? ?? const {}).forEach(
      (k, v) => parsedNameMap[k] = v.toString(),
    );

    final year = (json['seasonYear'] as num?)?.toInt() ?? 2026;
    final triennial = json['triennialCycleState'] != null
        ? UciTriennialCycleState.fromJson(
            json['triennialCycleState'] as Map<String, dynamic>,
          )
        : UciPromotionRelegationCycleService.createDefaultCycleState(
            currentYear: year,
          );

    return UciPointsLedgerState(
      seasonYear: year,
      entries: parsedEntries,
      riderSeasonPoints: parsedRiderPts,
      riderPointsBySource: parsedBySource,
      riderTeamIdMap: parsedTeamMap,
      riderNameMap: parsedNameMap,
      triennialCycleState: triennial,
    );
  }
}

/// Księga punktów UCI działająca w trybie na żywo:
/// - przypisuje punkty UCI za miejsca 1–60 w wyścigach jednodniowych,
/// - przypisuje punkty za etapy, klasyfikację generalną (1–60) oraz każdy dzień w koszulce lidera,
/// - natychmiast aktualizuje ranking indywidualny UCI oraz 3-letni ranking licencyjny WorldTour.
class UciPointsLiveLedgerService {
  final UciPointsLedgerState state;
  final UciPromotionRelegationCycleService _triennialService;
  final Set<String> _recordedEntryIds = <String>{};

  UciPointsLiveLedgerService({UciPointsLedgerState? state})
      : state = state ?? UciPointsLedgerState(seasonYear: 2026),
        _triennialService = UciPromotionRelegationCycleService(
          state: (state ?? UciPointsLedgerState(seasonYear: 2026))
              .triennialCycleState,
        ) {
    for (final entry in this.state.entries) {
      _recordedEntryIds.add(entry.entryId);
    }
  }

  /// Udostępnia usługę cyklu 3-letniego z tym samym współdzielonym stanem.
  UciPromotionRelegationCycleService get triennialService => _triennialService;

  // ===========================================================================
  // 1. TABELE PUNKTOWE UCI (MIEJSCA 1–60, ETAPY, GENERALKA, KOSZULKA LIDERA)
  // ===========================================================================

  /// Zwraca liczbę punktów UCI za miejsce [rank] (1–60) w wyścigu jednodniowym.
  static int oneDayPointsForRank(RaceCategory category, int rank) {
    if (rank < 1 || rank > 60) return 0;

    switch (category) {
      case RaceCategory.monument:
        return _monumentOneDayPoints(rank);
      case RaceCategory.worldTourOneDay:
        return _worldTourOneDayPoints(rank);
      case RaceCategory.proSeries:
        return _proSeriesOneDayPoints(rank);
      case RaceCategory.class1:
        return _class1OneDayPoints(rank);
      case RaceCategory.grandTour:
      case RaceCategory.worldTourStageRace:
        // Gdyby wyścig jednodniowy miał przypisaną kategorię etapową, stosujemy skalę WT 1-dniową
        return _worldTourOneDayPoints(rank);
    }
  }

  /// Zwraca liczbę punktów UCI za miejsce [rank] na pojedynczym etapie wyścigu wieloetapowego.
  static int stagePointsForRank(RaceCategory category, int rank) {
    if (rank < 1 || rank > 60) return 0;

    switch (category) {
      case RaceCategory.grandTour:
        const gtStage = [
          210, 150, 110, 90, 70, 55, 45, 40, 35, 30, 25, 20, 15, 10, 5,
        ];
        return rank <= gtStage.length ? gtStage[rank - 1] : 0;
      case RaceCategory.worldTourStageRace:
        const wtStage = [60, 40, 30, 25, 20, 15, 10, 8, 5, 2];
        return rank <= wtStage.length ? wtStage[rank - 1] : 0;
      case RaceCategory.proSeries:
        const proStage = [20, 15, 10, 5, 3];
        return rank <= proStage.length ? proStage[rank - 1] : 0;
      case RaceCategory.class1:
        const c1Stage = [14, 5, 3];
        return rank <= c1Stage.length ? c1Stage[rank - 1] : 0;
      case RaceCategory.monument:
      case RaceCategory.worldTourOneDay:
        return 0;
    }
  }

  /// Zwraca liczbę punktów UCI za miejsce [rank] (1–60) w klasyfikacji generalnej (GC).
  static int gcPointsForRank(RaceCategory category, int rank) {
    if (rank < 1 || rank > 60) return 0;

    switch (category) {
      case RaceCategory.grandTour:
        return _grandTourGcPoints(rank);
      case RaceCategory.worldTourStageRace:
        return _worldTourGcPoints(rank);
      case RaceCategory.proSeries:
        return _proSeriesOneDayPoints(rank);
      case RaceCategory.class1:
        return _class1OneDayPoints(rank);
      case RaceCategory.monument:
      case RaceCategory.worldTourOneDay:
        return oneDayPointsForRank(category, rank);
    }
  }

  /// Zwraca premię punktów UCI za każdy dzień noszenia koszulki lidera klasyfikacji generalnej.
  static int leaderJerseyDayPoints(RaceCategory category) {
    switch (category) {
      case RaceCategory.grandTour:
        return 25;
      case RaceCategory.worldTourStageRace:
        return 10;
      case RaceCategory.proSeries:
        return 5;
      case RaceCategory.class1:
        return 3;
      case RaceCategory.monument:
      case RaceCategory.worldTourOneDay:
        return 0;
    }
  }

  static int _monumentOneDayPoints(int rank) {
    const top15 = [
      800, 640, 520, 440, 360, 280, 240, 200, 160, 135, 110, 95, 85, 65, 55,
    ];
    if (rank <= top15.length) return top15[rank - 1];
    if (rank <= 20) return 50;
    if (rank <= 30) return 30;
    if (rank <= 50) return 15;
    if (rank <= 55) return 10;
    return 5; // 56–60
  }

  static int _worldTourOneDayPoints(int rank) {
    const top15 = [
      400, 320, 260, 220, 180, 140, 120, 100, 80, 68, 56, 48, 40, 32, 28,
    ];
    if (rank <= top15.length) return top15[rank - 1];
    if (rank <= 20) return 24;
    if (rank <= 30) return 16;
    if (rank <= 50) return 8;
    if (rank <= 55) return 4;
    return 2; // 56–60
  }

  static int _proSeriesOneDayPoints(int rank) {
    const top15 = [
      200, 150, 125, 100, 85, 70, 60, 50, 40, 35, 30, 25, 20, 15, 10,
    ];
    if (rank <= top15.length) return top15[rank - 1];
    if (rank <= 30) return 5;
    if (rank <= 40) return 3;
    if (rank <= 50) return 2;
    return 1; // 51–60
  }

  static int _class1OneDayPoints(int rank) {
    const top15 = [
      125, 85, 70, 60, 50, 40, 35, 30, 25, 20, 15, 10, 7, 5, 4,
    ];
    if (rank <= top15.length) return top15[rank - 1];
    if (rank <= 25) return 3;
    if (rank <= 40) return 2;
    return 1; // 41–60
  }

  static int _grandTourGcPoints(int rank) {
    const top20 = [
      1000, 800, 675, 575, 475, 400, 325, 275, 225, 175,
      150, 130, 115, 100, 90, 80, 70, 60, 50, 45,
    ];
    if (rank <= top20.length) return top20[rank - 1];
    if (rank <= 25) return 35;
    if (rank <= 30) return 25;
    if (rank <= 40) return 15;
    if (rank <= 50) return 10;
    return 5; // 51–60
  }

  static int _worldTourGcPoints(int rank) {
    const top15 = [
      500, 400, 325, 275, 225, 175, 150, 125, 100, 85, 70, 60, 50, 40, 35,
    ];
    if (rank <= top15.length) return top15[rank - 1];
    if (rank <= 20) return 30;
    if (rank <= 30) return 20;
    if (rank <= 50) return 10;
    return 5; // 51–60
  }

  // ===========================================================================
  // 2. KSIĘGOWANIE PUNKTÓW NA ŻYWO I NATYCHMIASTOWA SYNCHRONIZACJA RANKINGÓW
  // ===========================================================================

  /// Księguje wyniki wyścigu jednodniowego (miejsca 1–60) z natychmiastową aktualizacją rankingów.
  UciLiveLedgerBatchResult recordOneDayRaceFinish({
    required TourRace race,
    required List<OfficialRiderStageResult> results,
    required List<Rider> riders,
    required List<CyclingTeam> teams,
    DateTime? awardedAt,
    String? playerTeamId,
  }) {
    final timestamp = awardedAt ?? DateTime.now();
    final teamNames = {for (final t in teams) t.id: t.name};
    final newEntries = <UciLedgerEntry>[];

    for (final res in results) {
      if (res.isDnf || res.isEliminatedOtl) continue;
      if (res.rank < 1 || res.rank > 60) continue;

      final pts = oneDayPointsForRank(race.uciCategory, res.rank);
      if (pts <= 0) continue;

      final entryId =
          '${state.seasonYear}_${race.id}_oneday_${res.riderId}_${res.rank}';
      if (_recordedEntryIds.contains(entryId)) continue;

      newEntries.add(
        UciLedgerEntry(
          entryId: entryId,
          seasonYear: state.seasonYear,
          awardedAt: timestamp,
          raceId: race.id,
          raceName: race.name,
          raceCategory: race.uciCategory,
          riderId: res.riderId,
          riderName: res.riderName,
          teamId: res.teamId,
          teamName: teamNames[res.teamId] ?? res.teamId,
          source: UciPointAwardSource.oneDayRaceFinish,
          rank: res.rank,
          points: pts,
          description: '${res.rank}. miejsce w ${race.name}',
        ),
      );
    }

    return _commitEntriesAndSync(
      newEntries: newEntries,
      riders: riders,
      teams: teams,
      playerTeamId: playerTeamId,
    );
  }

  /// Księguje wyniki etapu wyścigu wieloetapowego oraz opcjonalnie punktację za koszulkę lidera.
  UciLiveLedgerBatchResult recordStageFinish({
    required TourRace race,
    required int stageNumber,
    required List<OfficialRiderStageResult> stageResults,
    required List<Rider> riders,
    required List<CyclingTeam> teams,
    String? gcLeaderRiderId,
    String? gcLeaderRiderName,
    String? gcLeaderTeamId,
    DateTime? awardedAt,
    String? playerTeamId,
  }) {
    final timestamp = awardedAt ?? DateTime.now();
    final teamNames = {for (final t in teams) t.id: t.name};
    final newEntries = <UciLedgerEntry>[];

    for (final res in stageResults) {
      if (res.isDnf || res.isEliminatedOtl) continue;
      if (res.rank < 1 || res.rank > 60) continue;

      final pts = stagePointsForRank(race.uciCategory, res.rank);
      if (pts <= 0) continue;

      final entryId =
          '${state.seasonYear}_${race.id}_s${stageNumber}_stage_${res.riderId}';
      if (_recordedEntryIds.contains(entryId)) continue;

      newEntries.add(
        UciLedgerEntry(
          entryId: entryId,
          seasonYear: state.seasonYear,
          awardedAt: timestamp,
          raceId: race.id,
          raceName: race.name,
          raceCategory: race.uciCategory,
          stageNumber: stageNumber,
          riderId: res.riderId,
          riderName: res.riderName,
          teamId: res.teamId,
          teamName: teamNames[res.teamId] ?? res.teamId,
          source: UciPointAwardSource.stageFinish,
          rank: res.rank,
          points: pts,
          description:
              '${res.rank}. miejsce na etapie $stageNumber. ${race.name}',
        ),
      );
    }

    if (gcLeaderRiderId != null && gcLeaderTeamId != null) {
      final jerseyPts = leaderJerseyDayPoints(race.uciCategory);
      if (jerseyPts > 0) {
        final entryId =
            '${state.seasonYear}_${race.id}_s${stageNumber}_jersey_$gcLeaderRiderId';
        if (!_recordedEntryIds.contains(entryId)) {
          final riderMatch = riders.where((r) => r.id == gcLeaderRiderId);
          final resolvedName = gcLeaderRiderName ??
              (riderMatch.isNotEmpty
                  ? riderMatch.first.fullName
                  : gcLeaderRiderId);

          newEntries.add(
            UciLedgerEntry(
              entryId: entryId,
              seasonYear: state.seasonYear,
              awardedAt: timestamp,
              raceId: race.id,
              raceName: race.name,
              raceCategory: race.uciCategory,
              stageNumber: stageNumber,
              riderId: gcLeaderRiderId,
              riderName: resolvedName,
              teamId: gcLeaderTeamId,
              teamName: teamNames[gcLeaderTeamId] ?? gcLeaderTeamId,
              source: UciPointAwardSource.leaderJerseyDay,
              points: jerseyPts,
              description:
                  'Koszulka lidera po etapie $stageNumber. ${race.name}',
            ),
          );
        }
      }
    }

    return _commitEntriesAndSync(
      newEntries: newEntries,
      riders: riders,
      teams: teams,
      playerTeamId: playerTeamId,
    );
  }

  /// Księguje indywidualny dzień noszenia koszulki lidera klasyfikacji generalnej.
  UciLiveLedgerBatchResult recordLeaderJerseyDay({
    required TourRace race,
    required int stageNumber,
    required String leaderRiderId,
    required String leaderRiderName,
    required String leaderTeamId,
    required List<Rider> riders,
    required List<CyclingTeam> teams,
    DateTime? awardedAt,
    String? playerTeamId,
  }) {
    final timestamp = awardedAt ?? DateTime.now();
    final jerseyPts = leaderJerseyDayPoints(race.uciCategory);
    if (jerseyPts <= 0) {
      return _emptyBatch(riders: riders, teams: teams, playerTeamId: playerTeamId);
    }

    final entryId =
        '${state.seasonYear}_${race.id}_s${stageNumber}_jersey_$leaderRiderId';
    if (_recordedEntryIds.contains(entryId)) {
      return _emptyBatch(riders: riders, teams: teams, playerTeamId: playerTeamId);
    }

    final teamNames = {for (final t in teams) t.id: t.name};
    final entry = UciLedgerEntry(
      entryId: entryId,
      seasonYear: state.seasonYear,
      awardedAt: timestamp,
      raceId: race.id,
      raceName: race.name,
      raceCategory: race.uciCategory,
      stageNumber: stageNumber,
      riderId: leaderRiderId,
      riderName: leaderRiderName,
      teamId: leaderTeamId,
      teamName: teamNames[leaderTeamId] ?? leaderTeamId,
      source: UciPointAwardSource.leaderJerseyDay,
      points: jerseyPts,
      description: 'Dzień w koszulce lidera (etap $stageNumber. ${race.name})',
    );

    return _commitEntriesAndSync(
      newEntries: [entry],
      riders: riders,
      teams: teams,
      playerTeamId: playerTeamId,
    );
  }

  /// Księguje końcową klasyfikację generalną (GC) wyścigu wieloetapowego dla miejsc 1–60.
  UciLiveLedgerBatchResult recordGeneralClassificationFinish({
    required TourRace race,
    required List<RiderClassificationEntry> generalClassification,
    required List<Rider> riders,
    required List<CyclingTeam> teams,
    DateTime? awardedAt,
    String? playerTeamId,
  }) {
    final timestamp = awardedAt ?? DateTime.now();
    final teamNames = {for (final t in teams) t.id: t.name};
    final newEntries = <UciLedgerEntry>[];

    for (final gcEntry in generalClassification) {
      if (gcEntry.rank < 1 || gcEntry.rank > 60) continue;

      final pts = gcPointsForRank(race.uciCategory, gcEntry.rank);
      if (pts <= 0) continue;

      final entryId =
          '${state.seasonYear}_${race.id}_gc_${gcEntry.riderId}_${gcEntry.rank}';
      if (_recordedEntryIds.contains(entryId)) continue;

      newEntries.add(
        UciLedgerEntry(
          entryId: entryId,
          seasonYear: state.seasonYear,
          awardedAt: timestamp,
          raceId: race.id,
          raceName: race.name,
          raceCategory: race.uciCategory,
          riderId: gcEntry.riderId,
          riderName: gcEntry.riderName,
          teamId: gcEntry.teamId,
          teamName: teamNames[gcEntry.teamId] ?? gcEntry.teamId,
          source: UciPointAwardSource.generalClassification,
          rank: gcEntry.rank,
          points: pts,
          description: '${gcEntry.rank}. miejsce w GC ${race.name}',
        ),
      );
    }

    return _commitEntriesAndSync(
      newEntries: newEntries,
      riders: riders,
      teams: teams,
      playerTeamId: playerTeamId,
    );
  }

  /// Zapisuje nowe wpisy, aktualizuje `Rider.careerPointsUci`, `CyclingTeam.uciPointsSeason`
  /// oraz natychmiast przelicza ranking indywidualny i 3-letni ranking licencyjny.
  UciLiveLedgerBatchResult _commitEntriesAndSync({
    required List<UciLedgerEntry> newEntries,
    required List<Rider> riders,
    required List<CyclingTeam> teams,
    String? playerTeamId,
  }) {
    if (newEntries.isEmpty) {
      return _emptyBatch(riders: riders, teams: teams, playerTeamId: playerTeamId);
    }

    final pointsByRider = <String, int>{};
    final pointsByTeam = <String, int>{};
    final affectedTeamIds = <String>{};
    int totalAwarded = 0;

    for (final entry in newEntries) {
      _recordedEntryIds.add(entry.entryId);
      state.entries.add(entry);

      totalAwarded += entry.points;
      pointsByRider[entry.riderId] =
          (pointsByRider[entry.riderId] ?? 0) + entry.points;
      pointsByTeam[entry.teamId] =
          (pointsByTeam[entry.teamId] ?? 0) + entry.points;
      affectedTeamIds.add(entry.teamId);

      state.riderSeasonPoints[entry.riderId] =
          (state.riderSeasonPoints[entry.riderId] ?? 0) + entry.points;

      final srcMap = state.riderPointsBySource.putIfAbsent(
        entry.riderId,
        () => <UciPointAwardSource, int>{},
      );
      srcMap[entry.source] = (srcMap[entry.source] ?? 0) + entry.points;

      state.riderTeamIdMap[entry.riderId] = entry.teamId;
      state.riderNameMap[entry.riderId] = entry.riderName;
    }

    // 1. Natychmiastowa aktualizacja punktów kariery na modelach kolarzy
    final updatedRiders = riders.map((rider) {
      final delta = pointsByRider[rider.id];
      if (delta == null || delta == 0) return rider;
      return rider.copyWith(careerPointsUci: rider.careerPointsUci + delta);
    }).toList();

    // 2. Natychmiastowe przeliczenie reguły Top-20 i aktualizacja 3-letniego cyklu licencyjnego
    final updatedTeams = List<CyclingTeam>.from(teams);
    for (int i = 0; i < updatedTeams.length; i++) {
      final team = updatedTeams[i];
      if (!affectedTeamIds.contains(team.id) &&
          !state.triennialCycleState.teamRecords.containsKey(team.id)) {
        // Rejestrujemy drużynę w tabeli 3-letniej jeśli jeszcze jej tam nie było
        final emptyBreakdown = _triennialService.calculateTeamTop20Points(
          teamId: team.id,
          teamName: team.name,
          year: state.seasonYear,
          riderSeasonPoints: const {},
          roster: updatedRiders,
        );
        _triennialService.recordSeasonPointsForTeam(
          teamId: team.id,
          teamName: team.name,
          countryIso: team.countryIso,
          division: team.division,
          year: state.seasonYear,
          breakdown: emptyBreakdown,
        );
        continue;
      }

      if (!affectedTeamIds.contains(team.id)) continue;

      final teamRiderPoints = _collectSeasonPointsForTeam(team, updatedRiders);
      final breakdown = _triennialService.calculateTeamTop20Points(
        teamId: team.id,
        teamName: team.name,
        year: state.seasonYear,
        riderSeasonPoints: teamRiderPoints,
        roster: updatedRiders,
      );

      _triennialService.recordSeasonPointsForTeam(
        teamId: team.id,
        teamName: team.name,
        countryIso: team.countryIso,
        division: team.division,
        year: state.seasonYear,
        breakdown: breakdown,
      );

      updatedTeams[i] = team.copyWith(
        uciPointsSeason: breakdown.countedTop20Points,
      );
    }

    final individualRanking = getIndividualRanking(
      riders: updatedRiders,
      teams: updatedTeams,
    );
    final triennialTable = getTriennialLicenseRanking(
      playerTeamId: playerTeamId,
    );

    return UciLiveLedgerBatchResult(
      awardedEntries: List<UciLedgerEntry>.unmodifiable(newEntries),
      totalPointsAwarded: totalAwarded,
      pointsByRider: Map<String, int>.unmodifiable(pointsByRider),
      pointsByTeam: Map<String, int>.unmodifiable(pointsByTeam),
      updatedRiders: updatedRiders,
      updatedTeams: updatedTeams,
      individualRanking: individualRanking,
      triennialTable: triennialTable,
    );
  }

  UciLiveLedgerBatchResult _emptyBatch({
    required List<Rider> riders,
    required List<CyclingTeam> teams,
    String? playerTeamId,
  }) {
    return UciLiveLedgerBatchResult(
      awardedEntries: const [],
      totalPointsAwarded: 0,
      pointsByRider: const {},
      pointsByTeam: const {},
      updatedRiders: riders,
      updatedTeams: teams,
      individualRanking: getIndividualRanking(riders: riders, teams: teams),
      triennialTable: getTriennialLicenseRanking(playerTeamId: playerTeamId),
    );
  }

  Map<String, int> _collectSeasonPointsForTeam(
    CyclingTeam team,
    List<Rider> riders,
  ) {
    final result = <String, int>{};
    final rosterSet = team.rosterRiderIds.toSet();

    for (final entry in state.riderSeasonPoints.entries) {
      final riderId = entry.key;
      final recordedTeamId = state.riderTeamIdMap[riderId];
      if (rosterSet.contains(riderId) || recordedTeamId == team.id) {
        result[riderId] = entry.value;
      }
    }

    return result;
  }

  // ===========================================================================
  // 3. ODCZYT RANKINGÓW NA ŻYWO I PRZEJŚCIE SEZONU
  // ===========================================================================

  /// Zwraca aktualny ranking indywidualny UCI posortowany malejąco po punktach sezonu.
  List<UciIndividualRankingEntry> getIndividualRanking({
    List<Rider> riders = const [],
    List<CyclingTeam> teams = const [],
    int? limit,
  }) {
    final riderById = {for (final r in riders) r.id: r};
    final teamById = {for (final t in teams) t.id: t};

    final allRiderIds = <String>{
      ...state.riderSeasonPoints.keys,
      ...riderById.keys,
    };

    final unsorted = <UciIndividualRankingEntry>[];
    for (final riderId in allRiderIds) {
      final seasonPts = state.riderSeasonPoints[riderId] ?? 0;
      final rider = riderById[riderId];
      if (seasonPts == 0 && rider == null) continue;

      String teamId = state.riderTeamIdMap[riderId] ?? '';
      if (teamId.isEmpty && teams.isNotEmpty) {
        for (final t in teams) {
          if (t.rosterRiderIds.contains(riderId)) {
            teamId = t.id;
            break;
          }
        }
      }

      final srcMap = state.riderPointsBySource[riderId] ?? const {};

      unsorted.add(
        UciIndividualRankingEntry(
          rank: 0,
          riderId: riderId,
          riderName: rider?.fullName ?? state.riderNameMap[riderId] ?? riderId,
          nationalityIso: rider?.nationalityIso ?? 'FRA',
          teamId: teamId,
          teamName: teamById[teamId]?.name ?? teamId,
          seasonPoints: seasonPts,
          careerPoints: rider?.careerPointsUci ?? seasonPts,
          oneDayPoints: srcMap[UciPointAwardSource.oneDayRaceFinish] ?? 0,
          stagePoints: srcMap[UciPointAwardSource.stageFinish] ?? 0,
          gcPoints: srcMap[UciPointAwardSource.generalClassification] ?? 0,
          jerseyDayPoints: srcMap[UciPointAwardSource.leaderJerseyDay] ?? 0,
        ),
      );
    }

    unsorted.sort((a, b) {
      final bySeason = b.seasonPoints.compareTo(a.seasonPoints);
      if (bySeason != 0) return bySeason;
      final byCareer = b.careerPoints.compareTo(a.careerPoints);
      if (byCareer != 0) return byCareer;
      return a.riderId.compareTo(b.riderId);
    });

    final count = limit != null ? math.min(limit, unsorted.length) : unsorted.length;
    final ranked = <UciIndividualRankingEntry>[];
    for (int i = 0; i < count; i++) {
      final item = unsorted[i];
      ranked.add(
        UciIndividualRankingEntry(
          rank: i + 1,
          riderId: item.riderId,
          riderName: item.riderName,
          nationalityIso: item.nationalityIso,
          teamId: item.teamId,
          teamName: item.teamName,
          seasonPoints: item.seasonPoints,
          careerPoints: item.careerPoints,
          oneDayPoints: item.oneDayPoints,
          stagePoints: item.stagePoints,
          gcPoints: item.gcPoints,
          jerseyDayPoints: item.jerseyDayPoints,
        ),
      );
    }
    return ranked;
  }

  /// Zwraca aktualny 3-letni ranking licencyjny UCI WorldTour ("Relegation Battle").
  List<RelegationBattleTableEntry> getTriennialLicenseRanking({
    String? playerTeamId,
  }) {
    return _triennialService.generateRelegationBattleTable(
      currentYear: state.seasonYear,
      playerTeamId: playerTeamId,
    );
  }

  /// Zwraca wszystkie wpisy księgi dla konkretnego kolarza.
  List<UciLedgerEntry> getEntriesForRider(String riderId) {
    return state.entries.where((e) => e.riderId == riderId).toList();
  }

  /// Zwraca wszystkie wpisy księgi dla konkretnego wyścigu.
  List<UciLedgerEntry> getEntriesForRace(String raceId, {int? seasonYear}) {
    return state.entries.where((e) {
      final raceMatch = e.raceId == raceId;
      final yearMatch = seasonYear == null || e.seasonYear == seasonYear;
      return raceMatch && yearMatch;
    }).toList();
  }

  /// Przełącza księgę na nowy sezon (zeruje punkty bieżącego sezonu, zachowuje historię księgi
  /// i otwiera kolejny rok w 3-letnim cyklu licencyjnym).
  UciPointsLiveLedgerService advanceToNextSeason(int newSeasonYear) {
    final nextCycleState = newSeasonYear > state.triennialCycleState.endYear
        ? UciPromotionRelegationCycleService.createDefaultCycleState(
            currentYear: newSeasonYear,
          )
        : UciTriennialCycleState(
            cycleId: state.triennialCycleState.cycleId,
            startYear: state.triennialCycleState.startYear,
            endYear: state.triennialCycleState.endYear,
            currentYear: newSeasonYear,
            teamRecords: Map<String, TeamTriennialRecord>.from(
              state.triennialCycleState.teamRecords,
            ),
          );

    return UciPointsLiveLedgerService(
      state: UciPointsLedgerState(
        seasonYear: newSeasonYear,
        entries: List<UciLedgerEntry>.from(state.entries),
        riderSeasonPoints: {},
        riderPointsBySource: {},
        riderTeamIdMap: Map<String, String>.from(state.riderTeamIdMap),
        riderNameMap: Map<String, String>.from(state.riderNameMap),
        triennialCycleState: nextCycleState,
      ),
    );
  }
}
