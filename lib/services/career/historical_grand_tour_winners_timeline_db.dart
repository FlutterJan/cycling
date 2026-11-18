// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Kategoria wyścigu w wieloletniej bazie historycznej.
enum TimelineRaceCategory {
  grandTour('Wielki Tour', 'Grand Tour', AppColors.goldAccent),
  monument('Monument', 'Monument', AppColors.accentBlue),
  worldChampionship(
    'Mistrzostwa Świata',
    'World Championship',
    AppColors.statusSuccess,
  );

  final String polishLabel;
  final String englishLabel;
  final Color accentColor;

  const TimelineRaceCategory(
    this.polishLabel,
    this.englishLabel,
    this.accentColor,
  );

  String toJson() => name;

  static TimelineRaceCategory fromJson(String value) {
    return TimelineRaceCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TimelineRaceCategory.grandTour,
    );
  }
}

/// Identyfikator wyścigu indeksowanego w bazie `HistoricalGrandTourWinnersTimelineDb`.
enum HistoricalTimelineRaceId {
  giroDItalia(
    'giro_d_italia',
    "Giro d'Italia",
    'ITA',
    TimelineRaceCategory.grandTour,
    AppColors.crimsonAlert,
    0,
  ),
  tourDeFrance(
    'tour_de_france',
    'Tour de France',
    'FRA',
    TimelineRaceCategory.grandTour,
    AppColors.goldAccent,
    1,
  ),
  vueltaAEspana(
    'vuelta_a_espana',
    'Vuelta a España',
    'ESP',
    TimelineRaceCategory.grandTour,
    AppColors.primaryAccent,
    2,
  ),
  milanoSanremo(
    'milano_sanremo',
    'Milano-Sanremo',
    'ITA',
    TimelineRaceCategory.monument,
    AppColors.accentBlue,
    3,
  ),
  rondeVanVlaanderen(
    'ronde_van_vlaanderen',
    'Ronde van Vlaanderen',
    'BEL',
    TimelineRaceCategory.monument,
    AppColors.amberWarning,
    4,
  ),
  parisRoubaix(
    'paris_roubaix',
    'Paris-Roubaix',
    'FRA',
    TimelineRaceCategory.monument,
    AppColors.primaryAccent,
    5,
  ),
  liegeBastogneLiege(
    'liege_bastogne_liege',
    'Liège-Bastogne-Liège',
    'BEL',
    TimelineRaceCategory.monument,
    AppColors.statusSuccess,
    6,
  ),
  ilLombardia(
    'il_lombardia',
    'Il Lombardia',
    'ITA',
    TimelineRaceCategory.monument,
    AppColors.cyanAccent,
    7,
  ),
  worldChampionshipRoadRace(
    'uci_worlds_road_race',
    'Mistrzostwa Świata UCI (Ze startu wspólnego)',
    'UCI',
    TimelineRaceCategory.worldChampionship,
    AppColors.goldAccent,
    8,
  ),
  worldChampionshipTimeTrial(
    'uci_worlds_time_trial',
    'Mistrzostwa Świata UCI (ITT)',
    'UCI',
    TimelineRaceCategory.worldChampionship,
    AppColors.accentBlue,
    9,
  );

  final String key;
  final String displayName;
  final String hostCountryCode;
  final TimelineRaceCategory category;
  final Color badgeColor;
  final int sortOrder;

  const HistoricalTimelineRaceId(
    this.key,
    this.displayName,
    this.hostCountryCode,
    this.category,
    this.badgeColor,
    this.sortOrder,
  );

  bool get countsTowardsTripleCrown =>
      this == HistoricalTimelineRaceId.giroDItalia ||
      this == HistoricalTimelineRaceId.tourDeFrance ||
      this == HistoricalTimelineRaceId.worldChampionshipRoadRace;

  String toJson() => name;

  static HistoricalTimelineRaceId fromJson(String value) {
    return HistoricalTimelineRaceId.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.key.toLowerCase() == value.toLowerCase(),
      orElse: () => HistoricalTimelineRaceId.tourDeFrance,
    );
  }
}

/// Pojedynczy wpis zwycięzcy Wielkiego Touru, Monumentu lub Mistrzostw Świata.
class HistoricalRaceWinnerEntry {
  final String id;
  final int year;
  final HistoricalTimelineRaceId raceId;
  final String riderId;
  final String riderName;
  final String countryCode;
  final String countryName;
  final String teamId;
  final String teamName;
  final int? winningMarginSeconds;
  final double? averageSpeedKmh;
  final bool isPlayerTeam;
  final bool isPlayerRider;
  final String? editionNotes;

  const HistoricalRaceWinnerEntry({
    required this.id,
    required this.year,
    required this.raceId,
    required this.riderId,
    required this.riderName,
    required this.countryCode,
    required this.countryName,
    required this.teamId,
    required this.teamName,
    this.winningMarginSeconds,
    this.averageSpeedKmh,
    this.isPlayerTeam = false,
    this.isPlayerRider = false,
    this.editionNotes,
  });

  /// Klucz kanoniczny identyfikujący kolarza w detekcji Potrójnej Korony.
  String get canonicalRiderKey {
    final trimmedId = riderId.trim().toLowerCase();
    if (trimmedId.isNotEmpty) {
      return trimmedId;
    }
    return riderName.trim().toLowerCase();
  }

  HistoricalRaceWinnerEntry copyWith({
    String? id,
    int? year,
    HistoricalTimelineRaceId? raceId,
    String? riderId,
    String? riderName,
    String? countryCode,
    String? countryName,
    String? teamId,
    String? teamName,
    int? winningMarginSeconds,
    double? averageSpeedKmh,
    bool? isPlayerTeam,
    bool? isPlayerRider,
    String? editionNotes,
  }) {
    return HistoricalRaceWinnerEntry(
      id: id ?? this.id,
      year: year ?? this.year,
      raceId: raceId ?? this.raceId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      winningMarginSeconds: winningMarginSeconds ?? this.winningMarginSeconds,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      isPlayerTeam: isPlayerTeam ?? this.isPlayerTeam,
      isPlayerRider: isPlayerRider ?? this.isPlayerRider,
      editionNotes: editionNotes ?? this.editionNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'year': year,
        'raceId': raceId.toJson(),
        'riderId': riderId,
        'riderName': riderName,
        'countryCode': countryCode,
        'countryName': countryName,
        'teamId': teamId,
        'teamName': teamName,
        'winningMarginSeconds': winningMarginSeconds,
        'averageSpeedKmh': averageSpeedKmh,
        'isPlayerTeam': isPlayerTeam,
        'isPlayerRider': isPlayerRider,
        'editionNotes': editionNotes,
      };

  factory HistoricalRaceWinnerEntry.fromJson(Map<String, dynamic> json) {
    return HistoricalRaceWinnerEntry(
      id: json['id'] as String? ?? '',
      year: (json['year'] as num).toInt(),
      raceId: HistoricalTimelineRaceId.fromJson(json['raceId'] as String),
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String,
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      teamId: json['teamId'] as String? ?? '',
      teamName: json['teamName'] as String,
      winningMarginSeconds: (json['winningMarginSeconds'] as num?)?.toInt(),
      averageSpeedKmh: (json['averageSpeedKmh'] as num?)?.toDouble(),
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      isPlayerRider: json['isPlayerRider'] as bool? ?? false,
      editionNotes: json['editionNotes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoricalRaceWinnerEntry &&
        other.id == id &&
        other.year == year &&
        other.raceId == raceId &&
        other.riderId == riderId &&
        other.riderName == riderName &&
        other.countryCode == countryCode &&
        other.teamId == teamId &&
        other.teamName == teamName &&
        other.isPlayerTeam == isPlayerTeam &&
        other.isPlayerRider == isPlayerRider;
  }

  @override
  int get hashCode => Object.hash(
        id,
        year,
        raceId,
        riderId,
        riderName,
        countryCode,
        teamId,
        teamName,
        isPlayerTeam,
        isPlayerRider,
      );
}

/// Rekord zdobywcy Potrójnej Korony Kolarstwa (Giro + Tour + MŚ w jednym roku).
class TripleCrownWinnerRecord {
  final int year;
  final String riderId;
  final String riderName;
  final String countryCode;
  final String countryName;
  final String teamId;
  final String teamName;
  final HistoricalRaceWinnerEntry giroEntry;
  final HistoricalRaceWinnerEntry tourEntry;
  final HistoricalRaceWinnerEntry worldsRoadEntry;
  final int totalTimelineWinsInYear;

  const TripleCrownWinnerRecord({
    required this.year,
    required this.riderId,
    required this.riderName,
    required this.countryCode,
    required this.countryName,
    required this.teamId,
    required this.teamName,
    required this.giroEntry,
    required this.tourEntry,
    required this.worldsRoadEntry,
    required this.totalTimelineWinsInYear,
  });

  bool get isPlayerManaged =>
      giroEntry.isPlayerTeam ||
      tourEntry.isPlayerTeam ||
      worldsRoadEntry.isPlayerTeam ||
      giroEntry.isPlayerRider ||
      tourEntry.isPlayerRider ||
      worldsRoadEntry.isPlayerRider;

  Map<String, dynamic> toJson() => {
        'year': year,
        'riderId': riderId,
        'riderName': riderName,
        'countryCode': countryCode,
        'countryName': countryName,
        'teamId': teamId,
        'teamName': teamName,
        'giroEntry': giroEntry.toJson(),
        'tourEntry': tourEntry.toJson(),
        'worldsRoadEntry': worldsRoadEntry.toJson(),
        'totalTimelineWinsInYear': totalTimelineWinsInYear,
      };

  factory TripleCrownWinnerRecord.fromJson(Map<String, dynamic> json) {
    return TripleCrownWinnerRecord(
      year: (json['year'] as num).toInt(),
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      giroEntry: HistoricalRaceWinnerEntry.fromJson(
        json['giroEntry'] as Map<String, dynamic>,
      ),
      tourEntry: HistoricalRaceWinnerEntry.fromJson(
        json['tourEntry'] as Map<String, dynamic>,
      ),
      worldsRoadEntry: HistoricalRaceWinnerEntry.fromJson(
        json['worldsRoadEntry'] as Map<String, dynamic>,
      ),
      totalTimelineWinsInYear:
          (json['totalTimelineWinsInYear'] as num).toInt(),
    );
  }
}

/// Zgrupowany widok pojedynczego sezonu w bazie historycznej.
class YearTimelineSnapshot {
  final int year;
  final List<HistoricalRaceWinnerEntry> entries;
  final List<TripleCrownWinnerRecord> tripleCrownWinners;

  const YearTimelineSnapshot({
    required this.year,
    required this.entries,
    required this.tripleCrownWinners,
  });

  bool get hasTripleCrown => tripleCrownWinners.isNotEmpty;
}

/// Kryteria filtrowania wieloletniej bazy zwycięzców.
class TimelineFilterCriteria {
  final String? countryQuery;
  final String? teamQuery;
  final String? riderQuery;
  final TimelineRaceCategory? category;
  final HistoricalTimelineRaceId? raceId;
  final int? minYear;
  final int? maxYear;
  final bool onlyTripleCrownWinners;
  final bool onlySinceCareerStart;
  final bool onlyPlayerAchievements;

  const TimelineFilterCriteria({
    this.countryQuery,
    this.teamQuery,
    this.riderQuery,
    this.category,
    this.raceId,
    this.minYear,
    this.maxYear,
    this.onlyTripleCrownWinners = false,
    this.onlySinceCareerStart = false,
    this.onlyPlayerAchievements = false,
  });

  bool get hasActiveFilters =>
      (countryQuery != null && countryQuery!.trim().isNotEmpty) ||
      (teamQuery != null && teamQuery!.trim().isNotEmpty) ||
      (riderQuery != null && riderQuery!.trim().isNotEmpty) ||
      category != null ||
      raceId != null ||
      minYear != null ||
      maxYear != null ||
      onlyTripleCrownWinners ||
      onlySinceCareerStart ||
      onlyPlayerAchievements;

  TimelineFilterCriteria copyWith({
    String? countryQuery,
    bool clearCountryQuery = false,
    String? teamQuery,
    bool clearTeamQuery = false,
    String? riderQuery,
    bool clearRiderQuery = false,
    TimelineRaceCategory? category,
    bool clearCategory = false,
    HistoricalTimelineRaceId? raceId,
    bool clearRaceId = false,
    int? minYear,
    bool clearMinYear = false,
    int? maxYear,
    bool clearMaxYear = false,
    bool? onlyTripleCrownWinners,
    bool? onlySinceCareerStart,
    bool? onlyPlayerAchievements,
  }) {
    return TimelineFilterCriteria(
      countryQuery:
          clearCountryQuery ? null : (countryQuery ?? this.countryQuery),
      teamQuery: clearTeamQuery ? null : (teamQuery ?? this.teamQuery),
      riderQuery: clearRiderQuery ? null : (riderQuery ?? this.riderQuery),
      category: clearCategory ? null : (category ?? this.category),
      raceId: clearRaceId ? null : (raceId ?? this.raceId),
      minYear: clearMinYear ? null : (minYear ?? this.minYear),
      maxYear: clearMaxYear ? null : (maxYear ?? this.maxYear),
      onlyTripleCrownWinners:
          onlyTripleCrownWinners ?? this.onlyTripleCrownWinners,
      onlySinceCareerStart: onlySinceCareerStart ?? this.onlySinceCareerStart,
      onlyPlayerAchievements:
          onlyPlayerAchievements ?? this.onlyPlayerAchievements,
    );
  }

  Map<String, dynamic> toJson() => {
        'countryQuery': countryQuery,
        'teamQuery': teamQuery,
        'riderQuery': riderQuery,
        'category': category?.toJson(),
        'raceId': raceId?.toJson(),
        'minYear': minYear,
        'maxYear': maxYear,
        'onlyTripleCrownWinners': onlyTripleCrownWinners,
        'onlySinceCareerStart': onlySinceCareerStart,
        'onlyPlayerAchievements': onlyPlayerAchievements,
      };

  factory TimelineFilterCriteria.fromJson(Map<String, dynamic> json) {
    return TimelineFilterCriteria(
      countryQuery: json['countryQuery'] as String?,
      teamQuery: json['teamQuery'] as String?,
      riderQuery: json['riderQuery'] as String?,
      category: json['category'] != null
          ? TimelineRaceCategory.fromJson(json['category'] as String)
          : null,
      raceId: json['raceId'] != null
          ? HistoricalTimelineRaceId.fromJson(json['raceId'] as String)
          : null,
      minYear: (json['minYear'] as num?)?.toInt(),
      maxYear: (json['maxYear'] as num?)?.toInt(),
      onlyTripleCrownWinners: json['onlyTripleCrownWinners'] as bool? ?? false,
      onlySinceCareerStart: json['onlySinceCareerStart'] as bool? ?? false,
      onlyPlayerAchievements: json['onlyPlayerAchievements'] as bool? ?? false,
    );
  }
}

/// Podsumowanie dorobku (Palmarès) pojedynczego kolarza w bazie historycznej.
class RiderPalmaresSummary {
  final String riderId;
  final String riderName;
  final String countryCode;
  final String countryName;
  final int totalWins;
  final int grandTourWins;
  final int monumentWins;
  final int worldChampionshipWins;
  final List<int> tripleCrownYears;
  final List<HistoricalRaceWinnerEntry> entries;

  const RiderPalmaresSummary({
    required this.riderId,
    required this.riderName,
    required this.countryCode,
    required this.countryName,
    required this.totalWins,
    required this.grandTourWins,
    required this.monumentWins,
    required this.worldChampionshipWins,
    required this.tripleCrownYears,
    required this.entries,
  });

  bool get isTripleCrownLegend => tripleCrownYears.isNotEmpty;
}

/// Zagregowane statystyki bazy zwycięzców (lub aktualnie przefiltrowanego widoku).
class TimelineDbStatistics {
  final int totalEntries;
  final int totalSeasons;
  final int grandTourCount;
  final int monumentCount;
  final int worldChampionshipCount;
  final int tripleCrownCount;
  final List<String> availableCountries;
  final List<String> availableTeams;
  final List<String> availableRiders;
  final Map<String, int> winsByCountry;
  final Map<String, int> winsByTeam;

  const TimelineDbStatistics({
    required this.totalEntries,
    required this.totalSeasons,
    required this.grandTourCount,
    required this.monumentCount,
    required this.worldChampionshipCount,
    required this.tripleCrownCount,
    required this.availableCountries,
    required this.availableTeams,
    required this.availableRiders,
    required this.winsByCountry,
    required this.winsByTeam,
  });
}

/// Pełna wieloletnia baza zwycięzców Wielkich Tourów, Monumentów i Mistrzostw
/// Świata od roku startu kariery z filtrowaniem po kraju, drużynie i kolarzu
/// oraz automatycznym wykrywaniem zdobywców Potrójnej Korony Kolarstwa.
class HistoricalGrandTourWinnersTimelineDb {
  final int careerStartYear;
  final Map<String, HistoricalRaceWinnerEntry> _entriesByRaceYear = {};

  HistoricalGrandTourWinnersTimelineDb({
    this.careerStartYear = 2026,
    Iterable<HistoricalRaceWinnerEntry>? initialEntries,
  }) {
    if (initialEntries != null) {
      recordWinners(initialEntries);
    }
  }

  /// Tworzy bazę wypełnioną historycznymi legendami Potrójnej Korony (1974, 1987,
  /// 2024) oraz ostatnimi edycjami poprzedzającymi start kariery.
  factory HistoricalGrandTourWinnersTimelineDb.withDefaultHistory({
    int careerStartYear = 2026,
  }) {
    final db = HistoricalGrandTourWinnersTimelineDb(
      careerStartYear: careerStartYear,
    );
    db.recordWinners(_defaultHistoricalBaselineEntries);
    return db;
  }

  /// Tworzy pustą bazę gotową do zapełnienia od [careerStartYear].
  factory HistoricalGrandTourWinnersTimelineDb.empty({
    int careerStartYear = 2026,
  }) {
    return HistoricalGrandTourWinnersTimelineDb(
      careerStartYear: careerStartYear,
    );
  }

  static String _raceYearKey(int year, HistoricalTimelineRaceId raceId) =>
      '${year}_${raceId.key}';

  /// Dodaje lub aktualizuje zwycięzcę danego wyścigu w konkretnym roku.
  void recordWinner(HistoricalRaceWinnerEntry entry) {
    if (entry.year < 1900) {
      throw ArgumentError.value(
        entry.year,
        'entry.year',
        'Rok wyścigu nie może być wcześniejszy niż 1900.',
      );
    }
    if (entry.riderName.trim().isEmpty) {
      throw ArgumentError.value(
        entry.riderName,
        'entry.riderName',
        'Nazwisko kolarza nie może być puste.',
      );
    }
    if (entry.countryCode.trim().isEmpty) {
      throw ArgumentError.value(
        entry.countryCode,
        'entry.countryCode',
        'Kod kraju nie może być pusty.',
      );
    }
    if (entry.teamName.trim().isEmpty) {
      throw ArgumentError.value(
        entry.teamName,
        'entry.teamName',
        'Nazwa drużyny nie może być pusta.',
      );
    }

    final normalizedEntry = entry.id.trim().isEmpty
        ? entry.copyWith(id: _raceYearKey(entry.year, entry.raceId))
        : entry;

    _entriesByRaceYear[_raceYearKey(entry.year, entry.raceId)] =
        normalizedEntry;
  }

  /// Masowo rejestruje wpisy zwycięzców.
  void recordWinners(Iterable<HistoricalRaceWinnerEntry> entries) {
    for (final entry in entries) {
      recordWinner(entry);
    }
  }

  /// Usuwa wpis dla podanego roku i wyścigu.
  bool removeWinner(int year, HistoricalTimelineRaceId raceId) {
    return _entriesByRaceYear.remove(_raceYearKey(year, raceId)) != null;
  }

  /// Czyści wszystkie zapisane rekordy.
  void clearAll() {
    _entriesByRaceYear.clear();
  }

  /// Zwraca wszystkie wpisy posortowane malejąco po roku i rosnąco po wyścigu.
  List<HistoricalRaceWinnerEntry> get allEntries {
    final list = _entriesByRaceYear.values.toList()..sort(_compareEntries);
    return List.unmodifiable(list);
  }

  /// Zwraca wyłącznie wpisy z lat `>= careerStartYear`.
  List<HistoricalRaceWinnerEntry> get careerEntries {
    return query(const TimelineFilterCriteria(onlySinceCareerStart: true));
  }

  static int _compareEntries(
    HistoricalRaceWinnerEntry a,
    HistoricalRaceWinnerEntry b,
  ) {
    final yearCmp = b.year.compareTo(a.year);
    if (yearCmp != 0) return yearCmp;
    return a.raceId.sortOrder.compareTo(b.raceId.sortOrder);
  }

  /// Automatycznie wykrywa wszystkich zdobywców Potrójnej Korony Kolarstwa
  /// (Giro d'Italia + Tour de France + Mistrzostwa Świata ze startu wspólnego
  /// w tym samym roku kalendarzowym).
  List<TripleCrownWinnerRecord> detectTripleCrownWinners({int? year}) {
    final entriesByYear = <int, List<HistoricalRaceWinnerEntry>>{};
    for (final entry in _entriesByRaceYear.values) {
      if (year != null && entry.year != year) continue;
      entriesByYear.putIfAbsent(entry.year, () => []).add(entry);
    }

    final results = <TripleCrownWinnerRecord>[];
    final sortedYears = entriesByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final seasonYear in sortedYears) {
      final seasonEntries = entriesByYear[seasonYear]!;
      HistoricalRaceWinnerEntry? giro;
      HistoricalRaceWinnerEntry? tour;
      HistoricalRaceWinnerEntry? worldsRoad;

      for (final entry in seasonEntries) {
        switch (entry.raceId) {
          case HistoricalTimelineRaceId.giroDItalia:
            giro = entry;
            break;
          case HistoricalTimelineRaceId.tourDeFrance:
            tour = entry;
            break;
          case HistoricalTimelineRaceId.worldChampionshipRoadRace:
            worldsRoad = entry;
            break;
          default:
            break;
        }
      }

      if (giro == null || tour == null || worldsRoad == null) {
        continue;
      }

      final sameRider =
          _isSameRider(giro, tour) && _isSameRider(tour, worldsRoad);
      if (!sameRider) {
        continue;
      }

      final totalWinsThatYear = seasonEntries
          .where((e) => _isSameRider(e, worldsRoad!))
          .length;

      results.add(
        TripleCrownWinnerRecord(
          year: seasonYear,
          riderId: worldsRoad.riderId.isNotEmpty
              ? worldsRoad.riderId
              : tour.riderId,
          riderName: worldsRoad.riderName,
          countryCode: worldsRoad.countryCode,
          countryName: worldsRoad.countryName,
          teamId: tour.teamId.isNotEmpty ? tour.teamId : giro.teamId,
          teamName: tour.teamName.isNotEmpty ? tour.teamName : giro.teamName,
          giroEntry: giro,
          tourEntry: tour,
          worldsRoadEntry: worldsRoad,
          totalTimelineWinsInYear: totalWinsThatYear,
        ),
      );
    }

    return List.unmodifiable(results);
  }

  bool _isSameRider(HistoricalRaceWinnerEntry a, HistoricalRaceWinnerEntry b) {
    final idA = a.riderId.trim().toLowerCase();
    final idB = b.riderId.trim().toLowerCase();
    if (idA.isNotEmpty && idB.isNotEmpty && idA == idB) {
      return true;
    }
    return a.riderName.trim().toLowerCase() == b.riderName.trim().toLowerCase();
  }

  bool _matchesRiderIdentifier(
    HistoricalRaceWinnerEntry entry,
    String riderIdentifier,
  ) {
    final normalized = riderIdentifier.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return entry.riderId.trim().toLowerCase() == normalized ||
        entry.riderName.trim().toLowerCase() == normalized;
  }

  /// Sprawdza, czy kolarz zdobył Potrójną Koronę w podanym roku [year].
  bool isTripleCrownWinnerInYear(String riderIdentifier, int year) {
    final records = detectTripleCrownWinners(year: year);
    for (final record in records) {
      if (record.riderId.trim().toLowerCase() ==
              riderIdentifier.trim().toLowerCase() ||
          record.riderName.trim().toLowerCase() ==
              riderIdentifier.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  /// Sprawdza, czy kolarz kiedykolwiek zdobył Potrójną Koronę.
  bool isCareerTripleCrownLegend(String riderIdentifier) {
    final records = detectTripleCrownWinners();
    for (final record in records) {
      if (record.riderId.trim().toLowerCase() ==
              riderIdentifier.trim().toLowerCase() ||
          record.riderName.trim().toLowerCase() ==
              riderIdentifier.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  /// Filtruje bazę po kraju, drużynie, kolarzu, kategorii, roku i Potrójnej Koronie.
  List<HistoricalRaceWinnerEntry> query(TimelineFilterCriteria criteria) {
    final tripleCrownByYear = <int, Set<String>>{};
    if (criteria.onlyTripleCrownWinners) {
      for (final record in detectTripleCrownWinners()) {
        tripleCrownByYear
            .putIfAbsent(record.year, () => <String>{})
            .add(record.riderName.trim().toLowerCase());
      }
    }

    final countryNeedle = criteria.countryQuery?.trim().toLowerCase();
    final teamNeedle = criteria.teamQuery?.trim().toLowerCase();
    final riderNeedle = criteria.riderQuery?.trim().toLowerCase();

    final filtered = _entriesByRaceYear.values.where((entry) {
      if (criteria.onlySinceCareerStart && entry.year < careerStartYear) {
        return false;
      }
      if (criteria.minYear != null && entry.year < criteria.minYear!) {
        return false;
      }
      if (criteria.maxYear != null && entry.year > criteria.maxYear!) {
        return false;
      }
      if (criteria.category != null &&
          entry.raceId.category != criteria.category) {
        return false;
      }
      if (criteria.raceId != null && entry.raceId != criteria.raceId) {
        return false;
      }
      if (criteria.onlyPlayerAchievements &&
          !entry.isPlayerTeam &&
          !entry.isPlayerRider) {
        return false;
      }
      if (countryNeedle != null && countryNeedle.isNotEmpty) {
        final codeMatch =
            entry.countryCode.toLowerCase().contains(countryNeedle);
        final nameMatch =
            entry.countryName.toLowerCase().contains(countryNeedle);
        if (!codeMatch && !nameMatch) return false;
      }
      if (teamNeedle != null && teamNeedle.isNotEmpty) {
        final idMatch = entry.teamId.toLowerCase().contains(teamNeedle);
        final nameMatch = entry.teamName.toLowerCase().contains(teamNeedle);
        if (!idMatch && !nameMatch) return false;
      }
      if (riderNeedle != null && riderNeedle.isNotEmpty) {
        final idMatch = entry.riderId.toLowerCase().contains(riderNeedle);
        final nameMatch = entry.riderName.toLowerCase().contains(riderNeedle);
        if (!idMatch && !nameMatch) return false;
      }
      if (criteria.onlyTripleCrownWinners) {
        final winnersInYear = tripleCrownByYear[entry.year];
        if (winnersInYear == null ||
            !winnersInYear.contains(entry.riderName.trim().toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList()
      ..sort(_compareEntries);

    return List.unmodifiable(filtered);
  }

  /// Buduje oś czasu pogrupowaną rocznikami (od najnowszego).
  List<YearTimelineSnapshot> buildYearlyTimeline([
    TimelineFilterCriteria criteria = const TimelineFilterCriteria(),
  ]) {
    final filtered = query(criteria);
    final grouped = <int, List<HistoricalRaceWinnerEntry>>{};
    for (final entry in filtered) {
      grouped.putIfAbsent(entry.year, () => []).add(entry);
    }

    final allTripleCrowns = detectTripleCrownWinners();
    final sortedYears = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return List.unmodifiable(
      sortedYears.map((year) {
        final yearEntries = grouped[year]!..sort(_compareEntries);
        final yearTripleCrowns = allTripleCrowns
            .where((tc) => tc.year == year)
            .where(
              (tc) => yearEntries.any(
                (e) =>
                    e.riderName.trim().toLowerCase() ==
                    tc.riderName.trim().toLowerCase(),
              ),
            )
            .toList();

        return YearTimelineSnapshot(
          year: year,
          entries: List.unmodifiable(yearEntries),
          tripleCrownWinners: List.unmodifiable(yearTripleCrowns),
        );
      }),
    );
  }

  /// Zwraca pełny palmarès wskazanego kolarza w bazie.
  RiderPalmaresSummary? getRiderPalmares(String riderIdentifier) {
    final matching = allEntries
        .where((e) => _matchesRiderIdentifier(e, riderIdentifier))
        .toList();
    if (matching.isEmpty) return null;

    final first = matching.first;
    final tripleCrownYears = detectTripleCrownWinners()
        .where(
          (tc) =>
              tc.riderId.trim().toLowerCase() ==
                  riderIdentifier.trim().toLowerCase() ||
              tc.riderName.trim().toLowerCase() ==
                  riderIdentifier.trim().toLowerCase(),
        )
        .map((tc) => tc.year)
        .toList();

    return RiderPalmaresSummary(
      riderId: first.riderId,
      riderName: first.riderName,
      countryCode: first.countryCode,
      countryName: first.countryName,
      totalWins: matching.length,
      grandTourWins: matching
          .where((e) => e.raceId.category == TimelineRaceCategory.grandTour)
          .length,
      monumentWins: matching
          .where((e) => e.raceId.category == TimelineRaceCategory.monument)
          .length,
      worldChampionshipWins: matching
          .where(
            (e) => e.raceId.category == TimelineRaceCategory.worldChampionship,
          )
          .length,
      tripleCrownYears: List.unmodifiable(tripleCrownYears),
      entries: List.unmodifiable(matching),
    );
  }

  /// Oblicza statystyki dla całej bazy lub wybranego filtra.
  TimelineDbStatistics computeStatistics([
    TimelineFilterCriteria criteria = const TimelineFilterCriteria(),
  ]) {
    final entries = query(criteria);
    final seasons = <int>{};
    final countries = <String>{};
    final teams = <String>{};
    final riders = <String>{};
    final winsByCountry = <String, int>{};
    final winsByTeam = <String, int>{};

    var gtCount = 0;
    var monCount = 0;
    var wcCount = 0;

    for (final entry in entries) {
      seasons.add(entry.year);
      countries.add(entry.countryCode);
      teams.add(entry.teamName);
      riders.add(entry.riderName);
      winsByCountry[entry.countryCode] =
          (winsByCountry[entry.countryCode] ?? 0) + 1;
      winsByTeam[entry.teamName] = (winsByTeam[entry.teamName] ?? 0) + 1;

      switch (entry.raceId.category) {
        case TimelineRaceCategory.grandTour:
          gtCount++;
          break;
        case TimelineRaceCategory.monument:
          monCount++;
          break;
        case TimelineRaceCategory.worldChampionship:
          wcCount++;
          break;
      }
    }

    final tripleCrowns = detectTripleCrownWinners().where((tc) {
      if (criteria.onlySinceCareerStart && tc.year < careerStartYear) {
        return false;
      }
      if (criteria.minYear != null && tc.year < criteria.minYear!) return false;
      if (criteria.maxYear != null && tc.year > criteria.maxYear!) return false;
      return entries.any(
        (e) =>
            e.year == tc.year &&
            e.riderName.trim().toLowerCase() ==
                tc.riderName.trim().toLowerCase(),
      );
    }).length;

    return TimelineDbStatistics(
      totalEntries: entries.length,
      totalSeasons: seasons.length,
      grandTourCount: gtCount,
      monumentCount: monCount,
      worldChampionshipCount: wcCount,
      tripleCrownCount: tripleCrowns,
      availableCountries: List.unmodifiable(countries.toList()..sort()),
      availableTeams: List.unmodifiable(teams.toList()..sort()),
      availableRiders: List.unmodifiable(riders.toList()..sort()),
      winsByCountry: Map.unmodifiable(winsByCountry),
      winsByTeam: Map.unmodifiable(winsByTeam),
    );
  }

  Map<String, dynamic> toJson() => {
        'careerStartYear': careerStartYear,
        'entries': allEntries.map((e) => e.toJson()).toList(),
      };

  factory HistoricalGrandTourWinnersTimelineDb.fromJson(
    Map<String, dynamic> json,
  ) {
    final startYear = (json['careerStartYear'] as num?)?.toInt() ?? 2026;
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];
    final entries = rawEntries
        .map(
          (item) => HistoricalRaceWinnerEntry.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    return HistoricalGrandTourWinnersTimelineDb(
      careerStartYear: startYear,
      initialEntries: entries,
    );
  }

  static const List<HistoricalRaceWinnerEntry> _defaultHistoricalBaselineEntries =
      [
    // 1974 — Eddy Merckx (Potrójna Korona)
    HistoricalRaceWinnerEntry(
      id: '1974_giro_d_italia',
      year: 1974,
      raceId: HistoricalTimelineRaceId.giroDItalia,
      riderId: 'legend_eddy_merckx',
      riderName: 'Eddy Merckx',
      countryCode: 'BEL',
      countryName: 'Belgia',
      teamId: 'team_molteni',
      teamName: 'Molteni',
      winningMarginSeconds: 12,
      editionNotes: 'Piąte zwycięstwo w Giro d\'Italia',
    ),
    HistoricalRaceWinnerEntry(
      id: '1974_tour_de_france',
      year: 1974,
      raceId: HistoricalTimelineRaceId.tourDeFrance,
      riderId: 'legend_eddy_merckx',
      riderName: 'Eddy Merckx',
      countryCode: 'BEL',
      countryName: 'Belgia',
      teamId: 'team_molteni',
      teamName: 'Molteni',
      winningMarginSeconds: 484,
      editionNotes: 'Piąty triumf w Tour de France',
    ),
    HistoricalRaceWinnerEntry(
      id: '1974_uci_worlds_road_race',
      year: 1974,
      raceId: HistoricalTimelineRaceId.worldChampionshipRoadRace,
      riderId: 'legend_eddy_merckx',
      riderName: 'Eddy Merckx',
      countryCode: 'BEL',
      countryName: 'Belgia',
      teamId: 'team_molteni',
      teamName: 'Molteni',
      editionNotes: 'Montreal — pierwsza Potrójna Korona w historii',
    ),
    // 1987 — Stephen Roche (Potrójna Korona)
    HistoricalRaceWinnerEntry(
      id: '1987_giro_d_italia',
      year: 1987,
      raceId: HistoricalTimelineRaceId.giroDItalia,
      riderId: 'legend_stephen_roche',
      riderName: 'Stephen Roche',
      countryCode: 'IRL',
      countryName: 'Irlandia',
      teamId: 'team_carrera_jeans',
      teamName: 'Carrera Jeans-Vagabond',
      winningMarginSeconds: 220,
    ),
    HistoricalRaceWinnerEntry(
      id: '1987_tour_de_france',
      year: 1987,
      raceId: HistoricalTimelineRaceId.tourDeFrance,
      riderId: 'legend_stephen_roche',
      riderName: 'Stephen Roche',
      countryCode: 'IRL',
      countryName: 'Irlandia',
      teamId: 'team_carrera_jeans',
      teamName: 'Carrera Jeans-Vagabond',
      winningMarginSeconds: 40,
    ),
    HistoricalRaceWinnerEntry(
      id: '1987_uci_worlds_road_race',
      year: 1987,
      raceId: HistoricalTimelineRaceId.worldChampionshipRoadRace,
      riderId: 'legend_stephen_roche',
      riderName: 'Stephen Roche',
      countryCode: 'IRL',
      countryName: 'Irlandia',
      teamId: 'team_carrera_jeans',
      teamName: 'Carrera Jeans-Vagabond',
      editionNotes: 'Villach — druga Potrójna Korona w historii',
    ),
    // 2024 — Tadej Pogačar (Potrójna Korona + Monumenty) & reszta sezonu
    HistoricalRaceWinnerEntry(
      id: '2024_giro_d_italia',
      year: 2024,
      raceId: HistoricalTimelineRaceId.giroDItalia,
      riderId: 'rider_tadej_pogacar',
      riderName: 'Tadej Pogačar',
      countryCode: 'SLO',
      countryName: 'Słowenia',
      teamId: 'team_uae_emirates',
      teamName: 'UAE Team Emirates',
      winningMarginSeconds: 596,
      editionNotes: '6 zwycięstw etapowych i dominacja w Różowej Koszulce',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_tour_de_france',
      year: 2024,
      raceId: HistoricalTimelineRaceId.tourDeFrance,
      riderId: 'rider_tadej_pogacar',
      riderName: 'Tadej Pogačar',
      countryCode: 'SLO',
      countryName: 'Słowenia',
      teamId: 'team_uae_emirates',
      teamName: 'UAE Team Emirates',
      winningMarginSeconds: 377,
      editionNotes: 'Nicea — dublet Giro-Tour',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_vuelta_a_espana',
      year: 2024,
      raceId: HistoricalTimelineRaceId.vueltaAEspana,
      riderId: 'rider_primoz_roglic',
      riderName: 'Primož Roglič',
      countryCode: 'SLO',
      countryName: 'Słowenia',
      teamId: 'team_red_bull_bora',
      teamName: 'Red Bull - BORA - hansgrohe',
      winningMarginSeconds: 156,
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_milano_sanremo',
      year: 2024,
      raceId: HistoricalTimelineRaceId.milanoSanremo,
      riderId: 'rider_jasper_philipsen',
      riderName: 'Jasper Philipsen',
      countryCode: 'BEL',
      countryName: 'Belgia',
      teamId: 'team_alpecin_deceuninck',
      teamName: 'Alpecin-Deceuninck',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_ronde_van_vlaanderen',
      year: 2024,
      raceId: HistoricalTimelineRaceId.rondeVanVlaanderen,
      riderId: 'rider_mathieu_van_der_poel',
      riderName: 'Mathieu van der Poel',
      countryCode: 'NED',
      countryName: 'Holandia',
      teamId: 'team_alpecin_deceuninck',
      teamName: 'Alpecin-Deceuninck',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_paris_roubaix',
      year: 2024,
      raceId: HistoricalTimelineRaceId.parisRoubaix,
      riderId: 'rider_mathieu_van_der_poel',
      riderName: 'Mathieu van der Poel',
      countryCode: 'NED',
      countryName: 'Holandia',
      teamId: 'team_alpecin_deceuninck',
      teamName: 'Alpecin-Deceuninck',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_liege_bastogne_liege',
      year: 2024,
      raceId: HistoricalTimelineRaceId.liegeBastogneLiege,
      riderId: 'rider_tadej_pogacar',
      riderName: 'Tadej Pogačar',
      countryCode: 'SLO',
      countryName: 'Słowenia',
      teamId: 'team_uae_emirates',
      teamName: 'UAE Team Emirates',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_il_lombardia',
      year: 2024,
      raceId: HistoricalTimelineRaceId.ilLombardia,
      riderId: 'rider_tadej_pogacar',
      riderName: 'Tadej Pogačar',
      countryCode: 'SLO',
      countryName: 'Słowenia',
      teamId: 'team_uae_emirates',
      teamName: 'UAE Team Emirates',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_uci_worlds_road_race',
      year: 2024,
      raceId: HistoricalTimelineRaceId.worldChampionshipRoadRace,
      riderId: 'rider_tadej_pogacar',
      riderName: 'Tadej Pogačar',
      countryCode: 'SLO',
      countryName: 'Słowenia',
      teamId: 'team_uae_emirates',
      teamName: 'UAE Team Emirates',
      editionNotes: 'Zurych — 100 km ucieczki po Potrójną Koronę',
    ),
    HistoricalRaceWinnerEntry(
      id: '2024_uci_worlds_time_trial',
      year: 2024,
      raceId: HistoricalTimelineRaceId.worldChampionshipTimeTrial,
      riderId: 'rider_remco_evenepoel',
      riderName: 'Remco Evenepoel',
      countryCode: 'BEL',
      countryName: 'Belgia',
      teamId: 'team_soudal_quick_step',
      teamName: 'Soudal Quick-Step',
    ),
  ];
}

/// Stan Riverpod dla osi czasu historycznych zwycięzców.
class HistoricalTimelineState {
  final int careerStartYear;
  final List<HistoricalRaceWinnerEntry> entries;
  final TimelineFilterCriteria filter;
  final int? selectedYear;
  final String? selectedRiderIdentifier;
  final bool isReadOnly;

  const HistoricalTimelineState({
    required this.careerStartYear,
    required this.entries,
    this.filter = const TimelineFilterCriteria(),
    this.selectedYear,
    this.selectedRiderIdentifier,
    this.isReadOnly = false,
  });

  HistoricalGrandTourWinnersTimelineDb buildDatabase() {
    return HistoricalGrandTourWinnersTimelineDb(
      careerStartYear: careerStartYear,
      initialEntries: entries,
    );
  }

  HistoricalTimelineState copyWith({
    int? careerStartYear,
    List<HistoricalRaceWinnerEntry>? entries,
    TimelineFilterCriteria? filter,
    int? selectedYear,
    bool clearSelectedYear = false,
    String? selectedRiderIdentifier,
    bool clearSelectedRider = false,
    bool? isReadOnly,
  }) {
    return HistoricalTimelineState(
      careerStartYear: careerStartYear ?? this.careerStartYear,
      entries: entries ?? this.entries,
      filter: filter ?? this.filter,
      selectedYear:
          clearSelectedYear ? null : (selectedYear ?? this.selectedYear),
      selectedRiderIdentifier: clearSelectedRider
          ? null
          : (selectedRiderIdentifier ?? this.selectedRiderIdentifier),
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}

/// Notifier zarządzający wieloletnią bazą zwycięzców oraz filtrami UI.
class HistoricalGrandTourWinnersTimelineNotifier
    extends StateNotifier<HistoricalTimelineState> {
  HistoricalGrandTourWinnersTimelineNotifier({
    int careerStartYear = 2026,
    bool includeDefaultHistory = true,
    bool isReadOnly = false,
  }) : super(
          HistoricalTimelineState(
            careerStartYear: careerStartYear,
            entries: includeDefaultHistory
                ? HistoricalGrandTourWinnersTimelineDb.withDefaultHistory(
                    careerStartYear: careerStartYear,
                  ).allEntries
                : const [],
            isReadOnly: isReadOnly,
          ),
        );

  void recordWinner(HistoricalRaceWinnerEntry entry) {
    if (state.isReadOnly) return;
    final db = state.buildDatabase()..recordWinner(entry);
    state = state.copyWith(entries: db.allEntries);
  }

  void recordWinners(Iterable<HistoricalRaceWinnerEntry> entries) {
    if (state.isReadOnly) return;
    final db = state.buildDatabase()..recordWinners(entries);
    state = state.copyWith(entries: db.allEntries);
  }

  void removeWinner(int year, HistoricalTimelineRaceId raceId) {
    if (state.isReadOnly) return;
    final db = state.buildDatabase()..removeWinner(year, raceId);
    state = state.copyWith(entries: db.allEntries);
  }

  void updateFilter(TimelineFilterCriteria newFilter) {
    state = state.copyWith(filter: newFilter);
  }

  void setCountryFilter(String? query) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        countryQuery: query,
        clearCountryQuery: query == null || query.trim().isEmpty,
      ),
    );
  }

  void setTeamFilter(String? query) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        teamQuery: query,
        clearTeamQuery: query == null || query.trim().isEmpty,
      ),
    );
  }

  void setRiderFilter(String? query) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        riderQuery: query,
        clearRiderQuery: query == null || query.trim().isEmpty,
      ),
    );
  }

  void setCategoryFilter(TimelineRaceCategory? category) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        category: category,
        clearCategory: category == null,
      ),
    );
  }

  void toggleTripleCrownOnly() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        onlyTripleCrownWinners: !state.filter.onlyTripleCrownWinners,
      ),
    );
  }

  void toggleCareerStartOnly() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        onlySinceCareerStart: !state.filter.onlySinceCareerStart,
      ),
    );
  }

  void resetFilters() {
    state = state.copyWith(filter: const TimelineFilterCriteria());
  }

  void selectRider(String? riderIdentifier) {
    state = state.copyWith(
      selectedRiderIdentifier: riderIdentifier,
      clearSelectedRider: riderIdentifier == null,
    );
  }

  void setReadOnly(bool readOnly) {
    state = state.copyWith(isReadOnly: readOnly);
  }
}

/// Główny provider bazy zwycięzców Wielkich Tourów, Monumentów i MŚ.
final historicalGrandTourWinnersTimelineProvider = StateNotifierProvider<
    HistoricalGrandTourWinnersTimelineNotifier, HistoricalTimelineState>(
  (ref) => HistoricalGrandTourWinnersTimelineNotifier(),
);

/// Produkcyjny panel UI prezentujący wieloletnią bazę zwycięzców, filtry
/// po kraju, drużynie i kolarzu oraz wyróżnienie Potrójnej Korony Kolarstwa.
class HistoricalGrandTourWinnersTimelinePanel extends ConsumerStatefulWidget {
  final bool isReadOnly;

  const HistoricalGrandTourWinnersTimelinePanel({
    super.key,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<HistoricalGrandTourWinnersTimelinePanel> createState() =>
      _HistoricalGrandTourWinnersTimelinePanelState();
}

class _HistoricalGrandTourWinnersTimelinePanelState
    extends ConsumerState<HistoricalGrandTourWinnersTimelinePanel> {
  late final TextEditingController _riderController;
  late final TextEditingController _teamController;
  late final TextEditingController _countryController;
  final FocusNode _riderFocus = FocusNode();
  final FocusNode _teamFocus = FocusNode();
  final FocusNode _countryFocus = FocusNode();
  String? _hoveredEntryId;

  @override
  void initState() {
    super.initState();
    _riderController = TextEditingController();
    _teamController = TextEditingController();
    _countryController = TextEditingController();
  }

  @override
  void dispose() {
    _riderController.dispose();
    _teamController.dispose();
    _countryController.dispose();
    _riderFocus.dispose();
    _teamFocus.dispose();
    _countryFocus.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    _riderController.clear();
    _teamController.clear();
    _countryController.clear();
    ref
        .read(historicalGrandTourWinnersTimelineProvider.notifier)
        .resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(historicalGrandTourWinnersTimelineProvider);
    final notifier =
        ref.read(historicalGrandTourWinnersTimelineProvider.notifier);
    final db = timelineState.buildDatabase();
    final filter = timelineState.filter;
    final stats = db.computeStatistics(filter);
    final yearlyTimeline = db.buildYearlyTimeline(filter);
    final allTripleCrowns = db.detectTripleCrownWinners();
    final isDisabled = widget.isReadOnly || timelineState.isReadOnly;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final isWide = constraints.maxWidth >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(
                  context: context,
                  stats: stats,
                  careerStartYear: timelineState.careerStartYear,
                  hasActiveFilters: filter.hasActiveFilters,
                  isCompact: isCompact,
                  isDisabled: isDisabled,
                ),
                const SizedBox(height: 16),
                if (allTripleCrowns.isNotEmpty) ...[
                  _buildTripleCrownHallOfFame(
                    allTripleCrowns: allTripleCrowns,
                    isCompact: isCompact,
                    isDisabled: isDisabled,
                    onSelectRider: (riderName) {
                      if (isDisabled) return;
                      _riderController.text = riderName;
                      notifier.setRiderFilter(riderName);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                _buildFiltersCard(
                  filter: filter,
                  notifier: notifier,
                  isCompact: isCompact,
                  isWide: isWide,
                  isDisabled: isDisabled,
                ),
                const SizedBox(height: 16),
                if (yearlyTimeline.isEmpty)
                  _buildEmptyState(
                    hasActiveFilters: filter.hasActiveFilters,
                    isDisabled: isDisabled,
                  )
                else
                  ...yearlyTimeline.map(
                    (snapshot) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildYearCard(
                        snapshot: snapshot,
                        isCompact: isCompact,
                        isWide: isWide,
                        isDisabled: isDisabled,
                        notifier: notifier,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required TimelineDbStatistics stats,
    required int careerStartYear,
    required bool hasActiveFilters,
    required bool isCompact,
    required bool isDisabled,
  }) {
    final badges = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatPill(
          label: 'Start kariery: $careerStartYear',
          color: AppColors.accentBlue,
        ),
        _StatPill(
          label: 'Triumfy: ${stats.totalEntries}',
          color: AppColors.statusSuccess,
        ),
        _StatPill(
          label: 'Potrójna Korona: ${stats.tripleCrownCount}',
          color: AppColors.goldAccent,
        ),
        if (hasActiveFilters)
          _InteractiveActionChip(
            label: 'Wyczyść filtry',
            icon: Icons.filter_alt_off_rounded,
            accentColor: AppColors.primaryAccent,
            isDisabled: isDisabled,
            onTap: _clearAllFilters,
          ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kronika Zwycięzców GT, Monumentów i MŚ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pełne archiwum wieloletnie z detekcją Potrójnej Korony (Giro + Tour + MŚ).',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                badges,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kronika Zwycięzców GT, Monumentów i MŚ',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Baza historyczna od roku startu kariery z automatycznym oznaczaniem Potrójnej Korony Kolarstwa.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                badges,
              ],
            ),
    );
  }

  Widget _buildTripleCrownHallOfFame({
    required List<TripleCrownWinnerRecord> allTripleCrowns,
    required bool isCompact,
    required bool isDisabled,
    required ValueChanged<String> onSelectRider,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aleja Zdobywców Potrójnej Korony (Giro + Tour + MŚ)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allTripleCrowns.map((tc) {
              return _InteractiveActionChip(
                label: '${tc.year} • ${tc.riderName} (${tc.countryCode})',
                icon: Icons.emoji_events_rounded,
                accentColor: AppColors.goldAccent,
                isDisabled: isDisabled,
                onTap: () => onSelectRider(tc.riderName),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard({
    required TimelineFilterCriteria filter,
    required HistoricalGrandTourWinnersTimelineNotifier notifier,
    required bool isCompact,
    required bool isWide,
    required bool isDisabled,
  }) {
    final fields = [
      _buildFilterTextField(
        controller: _riderController,
        focusNode: _riderFocus,
        label: 'Kolarz',
        hint: 'np. Pogačar, Merckx',
        icon: Icons.person_search_rounded,
        isDisabled: isDisabled,
        onChanged: notifier.setRiderFilter,
      ),
      _buildFilterTextField(
        controller: _teamController,
        focusNode: _teamFocus,
        label: 'Drużyna',
        hint: 'np. UAE Team Emirates',
        icon: Icons.groups_rounded,
        isDisabled: isDisabled,
        onChanged: notifier.setTeamFilter,
      ),
      _buildFilterTextField(
        controller: _countryController,
        focusNode: _countryFocus,
        label: 'Kraj (kod lub nazwa)',
        hint: 'np. SLO, BEL, Polska',
        icon: Icons.flag_rounded,
        isDisabled: isDisabled,
        onChanged: notifier.setCountryFilter,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact)
            Column(
              children: [
                fields[0],
                const SizedBox(height: 10),
                fields[1],
                const SizedBox(height: 10),
                fields[2],
              ],
            )
          else
            Row(
              children: [
                Expanded(child: fields[0]),
                const SizedBox(width: 12),
                Expanded(child: fields[1]),
                const SizedBox(width: 12),
                Expanded(child: fields[2]),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'Wszystkie',
                isSelected: filter.category == null,
                isDisabled: isDisabled,
                accentColor: AppColors.textPrimary,
                onTap: () => notifier.setCategoryFilter(null),
              ),
              ...TimelineRaceCategory.values.map(
                (cat) => _FilterChipButton(
                  label: cat.polishLabel,
                  isSelected: filter.category == cat,
                  isDisabled: isDisabled,
                  accentColor: cat.accentColor,
                  onTap: () => notifier.setCategoryFilter(
                    filter.category == cat ? null : cat,
                  ),
                ),
              ),
              _FilterChipButton(
                label: 'Tylko Potrójna Korona',
                isSelected: filter.onlyTripleCrownWinners,
                isDisabled: isDisabled,
                accentColor: AppColors.goldAccent,
                onTap: notifier.toggleTripleCrownOnly,
              ),
              _FilterChipButton(
                label: 'Od roku startu kariery',
                isSelected: filter.onlySinceCareerStart,
                isDisabled: isDisabled,
                accentColor: AppColors.accentBlue,
                onTap: notifier.toggleCareerStartOnly,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDisabled,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: !isDisabled,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceLight,
        isDense: true,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary.withValues(alpha: 0.65),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.cardBorder.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildYearCard({
    required YearTimelineSnapshot snapshot,
    required bool isCompact,
    required bool isWide,
    required bool isDisabled,
    required HistoricalGrandTourWinnersTimelineNotifier notifier,
  }) {
    final tripleCrownRiderNames = snapshot.tripleCrownWinners
        .map((tc) => tc.riderName.trim().toLowerCase())
        .toSet();

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: snapshot.hasTripleCrown
              ? AppColors.goldAccent.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '${snapshot.year}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (snapshot.hasTripleCrown)
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: snapshot.tripleCrownWinners
                        .map(
                          (tc) => _StatPill(
                            label: 'POTRÓJNA KORONA: ${tc.riderName}',
                            color: AppColors.goldAccent,
                          ),
                        )
                        .toList(),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    'Zwycięzców: ${snapshot.entries.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: snapshot.entries.map((entry) {
              final isTripleCrownRider = tripleCrownRiderNames
                  .contains(entry.riderName.trim().toLowerCase());
              final isHovered = _hoveredEntryId == entry.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MouseRegion(
                  onEnter: isDisabled
                      ? null
                      : (_) => setState(() => _hoveredEntryId = entry.id),
                  onExit: isDisabled
                      ? null
                      : (_) => setState(() {
                            if (_hoveredEntryId == entry.id) {
                              _hoveredEntryId = null;
                            }
                          }),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isDisabled
                        ? null
                        : () => notifier.selectRider(entry.riderName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10 : 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? AppColors.surfaceLight.withValues(alpha: 0.95)
                            : AppColors.surfaceLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTripleCrownRider
                              ? AppColors.goldAccent.withValues(alpha: 0.55)
                              : isHovered
                                  ? AppColors.accentBlue.withValues(alpha: 0.6)
                                  : AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: isCompact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RaceBadge(raceId: entry.raceId),
                                    ),
                                    if (isTripleCrownRider) ...[
                                      const SizedBox(width: 8),
                                      const _TripleCrownMiniTag(),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${entry.riderName} (${entry.countryCode})',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.teamName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: isWide ? 270 : 210,
                                  child: _RaceBadge(raceId: entry.raceId),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    entry.riderName,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatPill(
                                  label: entry.countryCode,
                                  color: AppColors.accentBlue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    entry.teamName,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isTripleCrownRider) ...[
                                  const SizedBox(width: 8),
                                  const _TripleCrownMiniTag(),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool hasActiveFilters,
    required bool isDisabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 34,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak wyników spełniających kryteria filtrowania',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Zmień filtr kraju, drużyny lub kolarza, aby wyświetlić zwycięzców.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 14),
            _InteractiveActionChip(
              label: 'Resetuj wszystkie filtry',
              icon: Icons.refresh_rounded,
              accentColor: AppColors.goldAccent,
              isDisabled: isDisabled,
              onTap: _clearAllFilters,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _RaceBadge extends StatelessWidget {
  final HistoricalTimelineRaceId raceId;

  const _RaceBadge({required this.raceId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: raceId.badgeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            raceId.displayName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TripleCrownMiniTag extends StatelessWidget {
  const _TripleCrownMiniTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 13,
            color: AppColors.goldAccent,
          ),
          SizedBox(width: 4),
          Text(
            'POTRÓJNA KORONA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.22)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final borderColor = widget.isSelected || _focused
        ? widget.accentColor
        : _hovered
            ? AppColors.textSecondary.withValues(alpha: 0.5)
            : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? AppColors.surfaceLight.withValues(alpha: 0.35)
                : bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.isDisabled
                  ? AppColors.cardBorder.withValues(alpha: 0.4)
                  : borderColor,
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : widget.isSelected
                      ? widget.accentColor
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveActionChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.22)
                : widget.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? widget.accentColor
                  : widget.accentColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : widget.accentColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isDisabled
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : widget.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
