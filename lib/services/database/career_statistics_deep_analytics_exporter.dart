// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import '../../models/team/cycling_team.dart';

/// Wersja schematu eksportowanego zestawu danych analitycznych kariery.
const String kCareerAnalyticsExportSchemaVersion = '1.0.0';

/// Format pliku wyjściowego dla eksportu danych analitycznych kariery.
enum AnalyticsExportFormat {
  csv,
  json,
  csvAndJsonBundle;

  String toJson() => name;

  static AnalyticsExportFormat fromJson(String value) {
    return AnalyticsExportFormat.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AnalyticsExportFormat.csvAndJsonBundle,
    );
  }

  String get labelPl {
    switch (this) {
      case AnalyticsExportFormat.csv:
        return 'CSV (Arkusz / BI)';
      case AnalyticsExportFormat.json:
        return 'JSON (Strukturalny)';
      case AnalyticsExportFormat.csvAndJsonBundle:
        return 'Pakiet CSV + JSON';
    }
  }
}

/// Zakres tabel i metryk uwzględnianych w eksporcie analitycznym.
enum AnalyticsDatasetScope {
  fullCareer,
  seasonProgression,
  ridersAndPhysiology,
  raceResultsAndPalmares,
  financesAndRoi,
  teamStandingsAndSponsors;

  String toJson() => name;

  static AnalyticsDatasetScope fromJson(String value) {
    return AnalyticsDatasetScope.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AnalyticsDatasetScope.fullCareer,
    );
  }

  String get labelPl {
    switch (this) {
      case AnalyticsDatasetScope.fullCareer:
        return 'Pełna kariera (Wszystkie tabele)';
      case AnalyticsDatasetScope.seasonProgression:
        return 'Progresja wieloletnia sezonów';
      case AnalyticsDatasetScope.ridersAndPhysiology:
        return 'Kolarze, fizjologia i ROI';
      case AnalyticsDatasetScope.raceResultsAndPalmares:
        return 'Wyniki wyścigów i Palmares';
      case AnalyticsDatasetScope.financesAndRoi:
        return 'Finanse i struktura kosztów';
      case AnalyticsDatasetScope.teamStandingsAndSponsors:
        return 'Ranking drużyn i sponsorzy';
    }
  }
}

/// Separator kolumn w plikach CSV.
enum CsvDelimiter {
  comma(',', 'Przecinek (,)'),
  semicolon(';', 'Średnik (;) — Excel PL'),
  tab('\t', 'Tabulator (TSV)');

  final String symbol;
  final String labelPl;

  const CsvDelimiter(this.symbol, this.labelPl);

  String toJson() => name;

  static CsvDelimiter fromJson(String value) {
    return CsvDelimiter.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CsvDelimiter.comma,
    );
  }
}

/// Konfiguracja procesu eksportu danych analitycznych z wieloletniej kariery.
class CareerAnalyticsExportConfig {
  final AnalyticsExportFormat format;
  final AnalyticsDatasetScope scope;
  final CsvDelimiter delimiter;
  final bool includeBomForExcel;
  final bool includeMetadataHeader;
  final bool prettyPrintJson;
  final bool playerTeamOnly;
  final bool anonymizeRivalNames;
  final int? seasonYearFrom;
  final int? seasonYearTo;

  const CareerAnalyticsExportConfig({
    this.format = AnalyticsExportFormat.csvAndJsonBundle,
    this.scope = AnalyticsDatasetScope.fullCareer,
    this.delimiter = CsvDelimiter.comma,
    this.includeBomForExcel = true,
    this.includeMetadataHeader = true,
    this.prettyPrintJson = true,
    this.playerTeamOnly = false,
    this.anonymizeRivalNames = false,
    this.seasonYearFrom,
    this.seasonYearTo,
  });

  CareerAnalyticsExportConfig copyWith({
    AnalyticsExportFormat? format,
    AnalyticsDatasetScope? scope,
    CsvDelimiter? delimiter,
    bool? includeBomForExcel,
    bool? includeMetadataHeader,
    bool? prettyPrintJson,
    bool? playerTeamOnly,
    bool? anonymizeRivalNames,
    int? seasonYearFrom,
    int? seasonYearTo,
    bool clearSeasonYearFrom = false,
    bool clearSeasonYearTo = false,
  }) {
    return CareerAnalyticsExportConfig(
      format: format ?? this.format,
      scope: scope ?? this.scope,
      delimiter: delimiter ?? this.delimiter,
      includeBomForExcel: includeBomForExcel ?? this.includeBomForExcel,
      includeMetadataHeader:
          includeMetadataHeader ?? this.includeMetadataHeader,
      prettyPrintJson: prettyPrintJson ?? this.prettyPrintJson,
      playerTeamOnly: playerTeamOnly ?? this.playerTeamOnly,
      anonymizeRivalNames: anonymizeRivalNames ?? this.anonymizeRivalNames,
      seasonYearFrom:
          clearSeasonYearFrom ? null : (seasonYearFrom ?? this.seasonYearFrom),
      seasonYearTo:
          clearSeasonYearTo ? null : (seasonYearTo ?? this.seasonYearTo),
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format.toJson(),
        'scope': scope.toJson(),
        'delimiter': delimiter.toJson(),
        'includeBomForExcel': includeBomForExcel,
        'includeMetadataHeader': includeMetadataHeader,
        'prettyPrintJson': prettyPrintJson,
        'playerTeamOnly': playerTeamOnly,
        'anonymizeRivalNames': anonymizeRivalNames,
        'seasonYearFrom': seasonYearFrom,
        'seasonYearTo': seasonYearTo,
      };

  factory CareerAnalyticsExportConfig.fromJson(Map<String, dynamic> json) {
    return CareerAnalyticsExportConfig(
      format: AnalyticsExportFormat.fromJson(
        json['format'] as String? ?? 'csvAndJsonBundle',
      ),
      scope: AnalyticsDatasetScope.fromJson(
        json['scope'] as String? ?? 'fullCareer',
      ),
      delimiter: CsvDelimiter.fromJson(
        json['delimiter'] as String? ?? 'comma',
      ),
      includeBomForExcel: json['includeBomForExcel'] as bool? ?? true,
      includeMetadataHeader: json['includeMetadataHeader'] as bool? ?? true,
      prettyPrintJson: json['prettyPrintJson'] as bool? ?? true,
      playerTeamOnly: json['playerTeamOnly'] as bool? ?? false,
      anonymizeRivalNames: json['anonymizeRivalNames'] as bool? ?? false,
      seasonYearFrom: (json['seasonYearFrom'] as num?)?.toInt(),
      seasonYearTo: (json['seasonYearTo'] as num?)?.toInt(),
    );
  }
}

/// Zbiorczy wiersz analityczny pojedynczego sezonu w wieloletniej karierze.
class SeasonAnalyticsSnapshot {
  final int seasonYear;
  final String teamId;
  final String teamName;
  final String divisionName;
  final int uciPoints;
  final int winsCount;
  final int podiumsCount;
  final int racesCompleted;
  final int totalIncomeEur;
  final int totalExpensesEur;
  final int netCashflowEur;
  final int cashBalanceEur;
  final double averageRosterAge;
  final double averageRosterFtpW;
  final double averageRosterVo2Max;
  final int managerReputation;

  const SeasonAnalyticsSnapshot({
    required this.seasonYear,
    required this.teamId,
    required this.teamName,
    required this.divisionName,
    required this.uciPoints,
    required this.winsCount,
    required this.podiumsCount,
    required this.racesCompleted,
    required this.totalIncomeEur,
    required this.totalExpensesEur,
    required this.netCashflowEur,
    required this.cashBalanceEur,
    required this.averageRosterAge,
    required this.averageRosterFtpW,
    required this.averageRosterVo2Max,
    required this.managerReputation,
  });

  double get roiFinanceRatio {
    if (totalExpensesEur <= 0) return 0.0;
    return totalIncomeEur / totalExpensesEur;
  }

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'teamId': teamId,
        'teamName': teamName,
        'divisionName': divisionName,
        'uciPoints': uciPoints,
        'winsCount': winsCount,
        'podiumsCount': podiumsCount,
        'racesCompleted': racesCompleted,
        'totalIncomeEur': totalIncomeEur,
        'totalExpensesEur': totalExpensesEur,
        'netCashflowEur': netCashflowEur,
        'cashBalanceEur': cashBalanceEur,
        'roiFinanceRatio': double.parse(roiFinanceRatio.toStringAsFixed(3)),
        'averageRosterAge': double.parse(averageRosterAge.toStringAsFixed(2)),
        'averageRosterFtpW': double.parse(averageRosterFtpW.toStringAsFixed(1)),
        'averageRosterVo2Max':
            double.parse(averageRosterVo2Max.toStringAsFixed(1)),
        'managerReputation': managerReputation,
      };

  factory SeasonAnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return SeasonAnalyticsSnapshot(
      seasonYear: (json['seasonYear'] as num).toInt(),
      teamId: json['teamId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      divisionName: json['divisionName'] as String? ?? '',
      uciPoints: (json['uciPoints'] as num?)?.toInt() ?? 0,
      winsCount: (json['winsCount'] as num?)?.toInt() ?? 0,
      podiumsCount: (json['podiumsCount'] as num?)?.toInt() ?? 0,
      racesCompleted: (json['racesCompleted'] as num?)?.toInt() ?? 0,
      totalIncomeEur: (json['totalIncomeEur'] as num?)?.toInt() ?? 0,
      totalExpensesEur: (json['totalExpensesEur'] as num?)?.toInt() ?? 0,
      netCashflowEur: (json['netCashflowEur'] as num?)?.toInt() ?? 0,
      cashBalanceEur: (json['cashBalanceEur'] as num?)?.toInt() ?? 0,
      averageRosterAge: (json['averageRosterAge'] as num?)?.toDouble() ?? 0.0,
      averageRosterFtpW: (json['averageRosterFtpW'] as num?)?.toDouble() ?? 0.0,
      averageRosterVo2Max:
          (json['averageRosterVo2Max'] as num?)?.toDouble() ?? 0.0,
      managerReputation: (json['managerReputation'] as num?)?.toInt() ?? 50,
    );
  }
}

/// Wiersz analityczny kolarza z metrykami wydolnościowymi oraz zwrotem z inwestycji (ROI).
class RiderCareerAnalyticsRow {
  final String riderId;
  final String fullName;
  final String nationalityIso;
  final int age;
  final String specialization;
  final String role;
  final String teamId;
  final String teamName;
  final int ftpWatts;
  final double weightKg;
  final double wattsPerKg;
  final double vo2Max;
  final double formCtl;
  final double fatigueAtl;
  final int potential;
  final int careerPointsUci;
  final int annualSalaryEur;
  final int contractEndYear;
  final double morale;
  final double roiPointsPer100kEur;

  const RiderCareerAnalyticsRow({
    required this.riderId,
    required this.fullName,
    required this.nationalityIso,
    required this.age,
    required this.specialization,
    required this.role,
    required this.teamId,
    required this.teamName,
    required this.ftpWatts,
    required this.weightKg,
    required this.wattsPerKg,
    required this.vo2Max,
    required this.formCtl,
    required this.fatigueAtl,
    required this.potential,
    required this.careerPointsUci,
    required this.annualSalaryEur,
    required this.contractEndYear,
    required this.morale,
    required this.roiPointsPer100kEur,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'fullName': fullName,
        'nationalityIso': nationalityIso,
        'age': age,
        'specialization': specialization,
        'role': role,
        'teamId': teamId,
        'teamName': teamName,
        'ftpWatts': ftpWatts,
        'weightKg': double.parse(weightKg.toStringAsFixed(1)),
        'wattsPerKg': double.parse(wattsPerKg.toStringAsFixed(2)),
        'vo2Max': double.parse(vo2Max.toStringAsFixed(1)),
        'formCtl': double.parse(formCtl.toStringAsFixed(1)),
        'fatigueAtl': double.parse(fatigueAtl.toStringAsFixed(1)),
        'potential': potential,
        'careerPointsUci': careerPointsUci,
        'annualSalaryEur': annualSalaryEur,
        'contractEndYear': contractEndYear,
        'morale': double.parse(morale.toStringAsFixed(1)),
        'roiPointsPer100kEur':
            double.parse(roiPointsPer100kEur.toStringAsFixed(2)),
      };
}

/// Wiersz analityczny historycznego wyniku wyścigu z palmares kariery.
class RacePalmaresAnalyticsRow {
  final String raceId;
  final String raceName;
  final int seasonYear;
  final String completedDateIso;
  final String winnerRiderId;
  final String winnerRiderName;
  final String winnerTeamId;
  final String winnerTeamName;
  final int winnerTotalTimeSeconds;
  final String pointsWinner;
  final String mountainsWinner;
  final String youthWinner;
  final String teamWinner;
  final bool isPlayerTeamWin;

  const RacePalmaresAnalyticsRow({
    required this.raceId,
    required this.raceName,
    required this.seasonYear,
    required this.completedDateIso,
    required this.winnerRiderId,
    required this.winnerRiderName,
    required this.winnerTeamId,
    required this.winnerTeamName,
    required this.winnerTotalTimeSeconds,
    required this.pointsWinner,
    required this.mountainsWinner,
    required this.youthWinner,
    required this.teamWinner,
    required this.isPlayerTeamWin,
  });

  Map<String, dynamic> toJson() => {
        'raceId': raceId,
        'raceName': raceName,
        'seasonYear': seasonYear,
        'completedDateIso': completedDateIso,
        'winnerRiderId': winnerRiderId,
        'winnerRiderName': winnerRiderName,
        'winnerTeamId': winnerTeamId,
        'winnerTeamName': winnerTeamName,
        'winnerTotalTimeSeconds': winnerTotalTimeSeconds,
        'pointsWinner': pointsWinner,
        'mountainsWinner': mountainsWinner,
        'youthWinner': youthWinner,
        'teamWinner': teamWinner,
        'isPlayerTeamWin': isPlayerTeamWin,
      };
}

/// Wiersz analityczny struktury przychodów i kosztów według kategorii księgowej.
class FinanceCategoryAnalyticsRow {
  final int seasonYear;
  final String category;
  final String categoryLabel;
  final bool isIncome;
  final int transactionCount;
  final int totalAmountEur;
  final double sharePercent;

  const FinanceCategoryAnalyticsRow({
    required this.seasonYear,
    required this.category,
    required this.categoryLabel,
    required this.isIncome,
    required this.transactionCount,
    required this.totalAmountEur,
    required this.sharePercent,
  });

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'category': category,
        'categoryLabel': categoryLabel,
        'isIncome': isIncome,
        'transactionCount': transactionCount,
        'totalAmountEur': totalAmountEur,
        'sharePercent': double.parse(sharePercent.toStringAsFixed(2)),
      };
}

/// Wiersz analityczny pozycji drużyny, jej finansów i punktów UCI.
class TeamStandingAnalyticsRow {
  final int rank;
  final String teamId;
  final String teamName;
  final String division;
  final String countryIso;
  final int uciPointsSeason;
  final int rosterSize;
  final int cashBalanceEur;
  final int annualSponsorIncomeEur;
  final int monthlyBurnRateEur;
  final double runwayMonths;
  final double averageStaffLevel;
  final bool isPlayerTeam;

  const TeamStandingAnalyticsRow({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.division,
    required this.countryIso,
    required this.uciPointsSeason,
    required this.rosterSize,
    required this.cashBalanceEur,
    required this.annualSponsorIncomeEur,
    required this.monthlyBurnRateEur,
    required this.runwayMonths,
    required this.averageStaffLevel,
    required this.isPlayerTeam,
  });

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'teamId': teamId,
        'teamName': teamName,
        'division': division,
        'countryIso': countryIso,
        'uciPointsSeason': uciPointsSeason,
        'rosterSize': rosterSize,
        'cashBalanceEur': cashBalanceEur,
        'annualSponsorIncomeEur': annualSponsorIncomeEur,
        'monthlyBurnRateEur': monthlyBurnRateEur,
        'runwayMonths': double.parse(runwayMonths.toStringAsFixed(1)),
        'averageStaffLevel': double.parse(averageStaffLevel.toStringAsFixed(1)),
        'isPlayerTeam': isPlayerTeam,
      };
}

/// Zagregowane wskaźniki KPI z całej wieloletniej kariery.
class CareerAnalyticsSummaryMetrics {
  final int seasonsTracked;
  final int totalRacesInPalmares;
  final int playerTeamWins;
  final int totalRidersExported;
  final int totalTeamsExported;
  final int cumulativeIncomeEur;
  final int cumulativeExpensesEur;
  final int cumulativeNetEur;
  final double averageRosterWPerKg;
  final int trophiesCount;

  const CareerAnalyticsSummaryMetrics({
    required this.seasonsTracked,
    required this.totalRacesInPalmares,
    required this.playerTeamWins,
    required this.totalRidersExported,
    required this.totalTeamsExported,
    required this.cumulativeIncomeEur,
    required this.cumulativeExpensesEur,
    required this.cumulativeNetEur,
    required this.averageRosterWPerKg,
    required this.trophiesCount,
  });

  Map<String, dynamic> toJson() => {
        'seasonsTracked': seasonsTracked,
        'totalRacesInPalmares': totalRacesInPalmares,
        'playerTeamWins': playerTeamWins,
        'totalRidersExported': totalRidersExported,
        'totalTeamsExported': totalTeamsExported,
        'cumulativeIncomeEur': cumulativeIncomeEur,
        'cumulativeExpensesEur': cumulativeExpensesEur,
        'cumulativeNetEur': cumulativeNetEur,
        'averageRosterWPerKg':
            double.parse(averageRosterWPerKg.toStringAsFixed(2)),
        'trophiesCount': trophiesCount,
      };
}

/// Kompletny zestaw danych analitycznych wyekstrahowany z wieloletniej kariery.
class CareerAnalyticsDataset {
  final String schemaVersion;
  final String saveId;
  final String saveName;
  final String playerManagerName;
  final String playerTeamId;
  final String playerTeamName;
  final int currentSeasonYear;
  final DateTime exportedAt;
  final CareerAnalyticsExportConfig config;
  final CareerAnalyticsSummaryMetrics summaryMetrics;
  final List<SeasonAnalyticsSnapshot> seasons;
  final List<RiderCareerAnalyticsRow> riders;
  final List<RacePalmaresAnalyticsRow> racePalmares;
  final List<FinanceCategoryAnalyticsRow> financeBreakdown;
  final List<TeamStandingAnalyticsRow> teamStandings;
  final List<String> trophiesWon;

  const CareerAnalyticsDataset({
    required this.schemaVersion,
    required this.saveId,
    required this.saveName,
    required this.playerManagerName,
    required this.playerTeamId,
    required this.playerTeamName,
    required this.currentSeasonYear,
    required this.exportedAt,
    required this.config,
    required this.summaryMetrics,
    required this.seasons,
    required this.riders,
    required this.racePalmares,
    required this.financeBreakdown,
    required this.teamStandings,
    required this.trophiesWon,
  });

  int get totalRowCount =>
      seasons.length +
      riders.length +
      racePalmares.length +
      financeBreakdown.length +
      teamStandings.length;
}

/// Pojedynczy wygenerowany artefakt eksportowy (plik CSV lub JSON w pamięci).
class ExportedAnalyticsArtifact {
  final String fileName;
  final AnalyticsExportFormat format;
  final AnalyticsDatasetScope scope;
  final String content;
  final int byteSize;
  final int rowCount;
  final String checksumFnv1a64;
  final DateTime generatedAt;

  const ExportedAnalyticsArtifact({
    required this.fileName,
    required this.format,
    required this.scope,
    required this.content,
    required this.byteSize,
    required this.rowCount,
    required this.checksumFnv1a64,
    required this.generatedAt,
  });
}

/// Końcowy wynik operacji eksportu danych analitycznych kariery.
class CareerAnalyticsExportResult {
  final bool success;
  final CareerAnalyticsDataset dataset;
  final List<ExportedAnalyticsArtifact> artifacts;
  final String summaryMessage;
  final List<String> warnings;
  final int durationMs;

  const CareerAnalyticsExportResult({
    required this.success,
    required this.dataset,
    required this.artifacts,
    required this.summaryMessage,
    this.warnings = const [],
    required this.durationMs,
  });
}

/// Produkcyjny eksporter danych analitycznych CSV/JSON z wieloletniej kariery.
///
/// Obsługuje ekstrakcję metryk sezonowych, wydolnościowych i finansowych (ROI),
/// eksport zgodny z RFC 4180 (opcjonalny BOM dla Excela, wybór separatora) oraz
/// strukturalny JSON z sumą kontrolną FNV-1a 64-bit.
class CareerStatisticsDeepAnalyticsExporter {
  const CareerStatisticsDeepAnalyticsExporter();

  /// Ekstrahuje zestaw danych analitycznych z [CareerSave] oraz opcjonalnych
  /// historycznych snapshotów z poprzednich sezonów kariery.
  CareerAnalyticsDataset extractDataset(
    CareerSave save, {
    CareerAnalyticsExportConfig config = const CareerAnalyticsExportConfig(),
    List<SeasonAnalyticsSnapshot> historicalSnapshots = const [],
    DateTime? nowOverride,
  }) {
    final exportedAt = nowOverride ?? DateTime.now();
    final playerTeam = save.playerTeam;
    final teamLookup = <String, CyclingTeam>{
      for (final team in save.teams) team.id: team,
    };

    String resolveTeamName(String teamId, String fallbackName) {
      if (config.anonymizeRivalNames && teamId != save.playerTeamId) {
        return 'Rival_Team_${teamId.hashCode.abs() % 1000}';
      }
      return teamLookup[teamId]?.name ?? fallbackName;
    }

    String resolveRiderName(String riderId, String originalName) {
      if (config.anonymizeRivalNames) {
        final rider = save.getRiderById(riderId);
        if (rider != null && rider.contract.teamId != save.playerTeamId) {
          return 'Rider_${riderId.hashCode.abs() % 10000}';
        }
      }
      return originalName;
    }

    bool inSeasonRange(int year) {
      if (config.seasonYearFrom != null && year < config.seasonYearFrom!) {
        return false;
      }
      if (config.seasonYearTo != null && year > config.seasonYearTo!) {
        return false;
      }
      return true;
    }

    // 1. Przetwarzanie snapshotów wieloletnich + bieżącego sezonu
    final seasonMap = <int, SeasonAnalyticsSnapshot>{};
    for (final snap in historicalSnapshots) {
      if (inSeasonRange(snap.seasonYear)) {
        seasonMap[snap.seasonYear] = snap;
      }
    }

    if (inSeasonRange(save.currentSeasonYear) &&
        !seasonMap.containsKey(save.currentSeasonYear)) {
      seasonMap[save.currentSeasonYear] = _buildCurrentSeasonSnapshot(
        save: save,
        playerTeam: playerTeam,
      );
    }

    final seasons = seasonMap.values.toList()
      ..sort((a, b) => a.seasonYear.compareTo(b.seasonYear));

    // 2. Kolarze i ROI
    final filteredRiders = save.riders.where((rider) {
      if (config.playerTeamOnly && rider.contract.teamId != save.playerTeamId) {
        return false;
      }
      return true;
    }).toList();

    final riderRows = filteredRiders.map((rider) {
      final teamName = resolveTeamName(
        rider.contract.teamId,
        rider.contract.teamId,
      );
      final annualSalary = rider.contract.monthlySalaryEur * 12;
      final roi = annualSalary > 0
          ? (rider.careerPointsUci / (annualSalary / 100000.0))
          : 0.0;
      return RiderCareerAnalyticsRow(
        riderId: rider.id,
        fullName: resolveRiderName(rider.id, rider.fullName),
        nationalityIso: rider.nationalityIso,
        age: rider.age,
        specialization: rider.specialization.name,
        role: rider.contract.role.name,
        teamId: rider.contract.teamId,
        teamName: teamName,
        ftpWatts: rider.physiology.ftpWatts,
        weightKg: rider.physiology.weightKg,
        wattsPerKg: rider.physiology.wattsPerKg,
        vo2Max: rider.physiology.vo2Max,
        formCtl: rider.physiology.form,
        fatigueAtl: rider.physiology.fatigue,
        potential: rider.potential,
        careerPointsUci: rider.careerPointsUci,
        annualSalaryEur: annualSalary,
        contractEndYear: rider.contract.contractEndYear,
        morale: rider.contract.morale,
        roiPointsPer100kEur: roi,
      );
    }).toList()
      ..sort((a, b) => b.careerPointsUci.compareTo(a.careerPointsUci));

    // 3. Wyniki wyścigów i Palmares
    final palmaresRows = <RacePalmaresAnalyticsRow>[];
    for (final entry in save.calendar.raceHistory.values) {
      if (!inSeasonRange(entry.seasonYear)) continue;
      final isPlayerWin = entry.winnerTeamId == save.playerTeamId;
      if (config.playerTeamOnly && !isPlayerWin) continue;

      palmaresRows.add(
        RacePalmaresAnalyticsRow(
          raceId: entry.raceId,
          raceName: entry.raceName,
          seasonYear: entry.seasonYear,
          completedDateIso: entry.completedDate.toIso8601String().split('T').first,
          winnerRiderId: entry.winnerRiderId,
          winnerRiderName:
              resolveRiderName(entry.winnerRiderId, entry.winnerRiderName),
          winnerTeamId: entry.winnerTeamId,
          winnerTeamName:
              resolveTeamName(entry.winnerTeamId, entry.winnerTeamName),
          winnerTotalTimeSeconds: entry.winnerTotalTimeSeconds,
          pointsWinner: entry.pointsWinnerRiderName ?? '-',
          mountainsWinner: entry.mountainsWinnerRiderName ?? '-',
          youthWinner: entry.youthWinnerRiderName ?? '-',
          teamWinner: entry.teamWinnerName ?? '-',
          isPlayerTeamWin: isPlayerWin,
        ),
      );
    }
    palmaresRows.sort((a, b) {
      final yearCmp = b.seasonYear.compareTo(a.seasonYear);
      if (yearCmp != 0) return yearCmp;
      return b.completedDateIso.compareTo(a.completedDateIso);
    });

    // 4. Struktura finansowa wg sezonów i kategorii
    final financeRows = _buildFinanceBreakdown(
      save.financeLedger,
      seasonYearFrom: config.seasonYearFrom,
      seasonYearTo: config.seasonYearTo,
    );

    // 5. Ranking drużyn i sponsorów
    final sortedTeams = List<CyclingTeam>.from(save.teams)
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));
    final teamRows = <TeamStandingAnalyticsRow>[];
    for (int i = 0; i < sortedTeams.length; i++) {
      final team = sortedTeams[i];
      final isPlayer = team.id == save.playerTeamId;
      if (config.playerTeamOnly && !isPlayer) continue;
      teamRows.add(
        TeamStandingAnalyticsRow(
          rank: i + 1,
          teamId: team.id,
          teamName: resolveTeamName(team.id, team.name),
          division: team.division.name,
          countryIso: team.countryIso,
          uciPointsSeason: team.uciPointsSeason,
          rosterSize: team.rosterRiderIds.length,
          cashBalanceEur: team.cashBalanceEur,
          annualSponsorIncomeEur: team.annualSponsorIncomeEur,
          monthlyBurnRateEur: team.monthlyBurnRateEur,
          runwayMonths: team.runwayMonths,
          averageStaffLevel: team.staff.averageStaffLevel,
          isPlayerTeam: isPlayer,
        ),
      );
    }

    // 6. Podsumowanie KPI
    int cumulativeIncome = 0;
    int cumulativeExpenses = 0;
    for (final s in seasons) {
      cumulativeIncome += s.totalIncomeEur;
      cumulativeExpenses += s.totalExpensesEur;
    }

    final avgWPerKg = riderRows.isEmpty
        ? 0.0
        : riderRows.map((r) => r.wattsPerKg).reduce((a, b) => a + b) /
            riderRows.length;

    final summary = CareerAnalyticsSummaryMetrics(
      seasonsTracked: seasons.length,
      totalRacesInPalmares: palmaresRows.length,
      playerTeamWins: palmaresRows.where((r) => r.isPlayerTeamWin).length,
      totalRidersExported: riderRows.length,
      totalTeamsExported: teamRows.length,
      cumulativeIncomeEur: cumulativeIncome,
      cumulativeExpensesEur: cumulativeExpenses,
      cumulativeNetEur: cumulativeIncome - cumulativeExpenses,
      averageRosterWPerKg: avgWPerKg,
      trophiesCount: save.trophiesWon.length,
    );

    return CareerAnalyticsDataset(
      schemaVersion: kCareerAnalyticsExportSchemaVersion,
      saveId: save.id,
      saveName: save.saveName,
      playerManagerName: save.playerManagerName,
      playerTeamId: save.playerTeamId,
      playerTeamName: playerTeam.name,
      currentSeasonYear: save.currentSeasonYear,
      exportedAt: exportedAt,
      config: config,
      summaryMetrics: summary,
      seasons: seasons,
      riders: riderRows,
      racePalmares: palmaresRows,
      financeBreakdown: financeRows,
      teamStandings: teamRows,
      trophiesWon: List<String>.from(save.trophiesWon),
    );
  }

  /// Generuje kompletny plik CSV zgodny ze standardem RFC 4180.
  String exportToCsv(
    CareerAnalyticsDataset dataset, {
    CareerAnalyticsExportConfig? configOverride,
  }) {
    final cfg = configOverride ?? dataset.config;
    final sep = cfg.delimiter.symbol;
    final buffer = StringBuffer();

    if (cfg.includeBomForExcel) {
      buffer.write('\uFEFF');
    }

    if (cfg.includeMetadataHeader) {
      buffer.writeln(
        '# Pro Peloton Manager — Deep Career Analytics Export (Schema ${dataset.schemaVersion})',
      );
      buffer.writeln(
        '# Save: ${_escapeCsv(dataset.saveName, sep)} | Manager: ${_escapeCsv(dataset.playerManagerName, sep)} | Team: ${_escapeCsv(dataset.playerTeamName, sep)} | Season: ${dataset.currentSeasonYear}',
      );
      buffer.writeln(
        '# ExportedAt: ${dataset.exportedAt.toIso8601String()} | Scope: ${cfg.scope.name}',
      );
    }

    void writeRow(List<Object?> cells) {
      buffer.writeln(
        cells.map((c) => _escapeCsv(c?.toString() ?? '', sep)).join(sep),
      );
    }

    final scope = cfg.scope;
    final includeAll = scope == AnalyticsDatasetScope.fullCareer;

    if (includeAll || scope == AnalyticsDatasetScope.seasonProgression) {
      if (includeAll) buffer.writeln('# SECTION: SEASONS');
      writeRow([
        'season_year',
        'team_id',
        'team_name',
        'division',
        'uci_points',
        'wins_count',
        'podiums_count',
        'races_completed',
        'total_income_eur',
        'total_expenses_eur',
        'net_cashflow_eur',
        'cash_balance_eur',
        'roi_finance_ratio',
        'avg_roster_age',
        'avg_roster_ftp_w',
        'avg_roster_vo2max',
        'manager_reputation',
      ]);
      for (final s in dataset.seasons) {
        writeRow([
          s.seasonYear,
          s.teamId,
          s.teamName,
          s.divisionName,
          s.uciPoints,
          s.winsCount,
          s.podiumsCount,
          s.racesCompleted,
          s.totalIncomeEur,
          s.totalExpensesEur,
          s.netCashflowEur,
          s.cashBalanceEur,
          s.roiFinanceRatio.toStringAsFixed(3),
          s.averageRosterAge.toStringAsFixed(2),
          s.averageRosterFtpW.toStringAsFixed(1),
          s.averageRosterVo2Max.toStringAsFixed(1),
          s.managerReputation,
        ]);
      }
      if (includeAll) buffer.writeln();
    }

    if (includeAll || scope == AnalyticsDatasetScope.ridersAndPhysiology) {
      if (includeAll) buffer.writeln('# SECTION: RIDERS_AND_ROI');
      writeRow([
        'rider_id',
        'full_name',
        'nationality_iso',
        'age',
        'specialization',
        'role',
        'team_id',
        'team_name',
        'ftp_watts',
        'weight_kg',
        'watts_per_kg',
        'vo2_max',
        'form_ctl',
        'fatigue_atl',
        'potential',
        'career_points_uci',
        'annual_salary_eur',
        'contract_end_year',
        'morale',
        'roi_points_per_100k_eur',
      ]);
      for (final r in dataset.riders) {
        writeRow([
          r.riderId,
          r.fullName,
          r.nationalityIso,
          r.age,
          r.specialization,
          r.role,
          r.teamId,
          r.teamName,
          r.ftpWatts,
          r.weightKg.toStringAsFixed(1),
          r.wattsPerKg.toStringAsFixed(2),
          r.vo2Max.toStringAsFixed(1),
          r.formCtl.toStringAsFixed(1),
          r.fatigueAtl.toStringAsFixed(1),
          r.potential,
          r.careerPointsUci,
          r.annualSalaryEur,
          r.contractEndYear,
          r.morale.toStringAsFixed(1),
          r.roiPointsPer100kEur.toStringAsFixed(2),
        ]);
      }
      if (includeAll) buffer.writeln();
    }

    if (includeAll || scope == AnalyticsDatasetScope.raceResultsAndPalmares) {
      if (includeAll) buffer.writeln('# SECTION: RACE_PALMARES');
      writeRow([
        'race_id',
        'race_name',
        'season_year',
        'completed_date',
        'winner_rider_id',
        'winner_rider_name',
        'winner_team_id',
        'winner_team_name',
        'winner_total_time_s',
        'points_winner',
        'mountains_winner',
        'youth_winner',
        'team_winner',
        'is_player_team_win',
      ]);
      for (final p in dataset.racePalmares) {
        writeRow([
          p.raceId,
          p.raceName,
          p.seasonYear,
          p.completedDateIso,
          p.winnerRiderId,
          p.winnerRiderName,
          p.winnerTeamId,
          p.winnerTeamName,
          p.winnerTotalTimeSeconds,
          p.pointsWinner,
          p.mountainsWinner,
          p.youthWinner,
          p.teamWinner,
          p.isPlayerTeamWin,
        ]);
      }
      if (includeAll) buffer.writeln();
    }

    if (includeAll || scope == AnalyticsDatasetScope.financesAndRoi) {
      if (includeAll) buffer.writeln('# SECTION: FINANCE_BREAKDOWN');
      writeRow([
        'season_year',
        'category',
        'category_label',
        'is_income',
        'transaction_count',
        'total_amount_eur',
        'share_percent',
      ]);
      for (final f in dataset.financeBreakdown) {
        writeRow([
          f.seasonYear,
          f.category,
          f.categoryLabel,
          f.isIncome,
          f.transactionCount,
          f.totalAmountEur,
          f.sharePercent.toStringAsFixed(2),
        ]);
      }
      if (includeAll) buffer.writeln();
    }

    if (includeAll || scope == AnalyticsDatasetScope.teamStandingsAndSponsors) {
      if (includeAll) buffer.writeln('# SECTION: TEAM_STANDINGS');
      writeRow([
        'rank',
        'team_id',
        'team_name',
        'division',
        'country_iso',
        'uci_points_season',
        'roster_size',
        'cash_balance_eur',
        'annual_sponsor_income_eur',
        'monthly_burn_rate_eur',
        'runway_months',
        'avg_staff_level',
        'is_player_team',
      ]);
      for (final t in dataset.teamStandings) {
        writeRow([
          t.rank,
          t.teamId,
          t.teamName,
          t.division,
          t.countryIso,
          t.uciPointsSeason,
          t.rosterSize,
          t.cashBalanceEur,
          t.annualSponsorIncomeEur,
          t.monthlyBurnRateEur,
          t.runwayMonths.toStringAsFixed(1),
          t.averageStaffLevel.toStringAsFixed(1),
          t.isPlayerTeam,
        ]);
      }
    }

    return buffer.toString();
  }

  /// Generuje strukturalny dokument JSON zawierający metadane, KPI oraz tabele
  /// zgodne z wybranym zakresem [AnalyticsDatasetScope].
  String exportToJson(
    CareerAnalyticsDataset dataset, {
    CareerAnalyticsExportConfig? configOverride,
  }) {
    final cfg = configOverride ?? dataset.config;
    final scope = cfg.scope;
    final includeAll = scope == AnalyticsDatasetScope.fullCareer;

    final payload = <String, dynamic>{
      'schemaVersion': dataset.schemaVersion,
      'exportedAt': dataset.exportedAt.toIso8601String(),
      'career': {
        'saveId': dataset.saveId,
        'saveName': dataset.saveName,
        'playerManagerName': dataset.playerManagerName,
        'playerTeamId': dataset.playerTeamId,
        'playerTeamName': dataset.playerTeamName,
        'currentSeasonYear': dataset.currentSeasonYear,
        'trophiesWon': dataset.trophiesWon,
      },
      'exportConfig': cfg.toJson(),
      'summaryMetrics': dataset.summaryMetrics.toJson(),
      'datasets': <String, dynamic>{
        if (includeAll || scope == AnalyticsDatasetScope.seasonProgression)
          'seasons': dataset.seasons.map((e) => e.toJson()).toList(),
        if (includeAll || scope == AnalyticsDatasetScope.ridersAndPhysiology)
          'riders': dataset.riders.map((e) => e.toJson()).toList(),
        if (includeAll || scope == AnalyticsDatasetScope.raceResultsAndPalmares)
          'racePalmares': dataset.racePalmares.map((e) => e.toJson()).toList(),
        if (includeAll || scope == AnalyticsDatasetScope.financesAndRoi)
          'financeBreakdown':
              dataset.financeBreakdown.map((e) => e.toJson()).toList(),
        if (includeAll ||
            scope == AnalyticsDatasetScope.teamStandingsAndSponsors)
          'teamStandings':
              dataset.teamStandings.map((e) => e.toJson()).toList(),
      },
    };

    final rawJson = cfg.prettyPrintJson
        ? const JsonEncoder.withIndent('  ').convert(payload)
        : jsonEncode(payload);
    final checksum = computeFnv1a64(rawJson);

    final envelope = <String, dynamic>{
      'checksumFnv1a64': checksum,
      ...payload,
    };

    return cfg.prettyPrintJson
        ? const JsonEncoder.withIndent('  ').convert(envelope)
        : jsonEncode(envelope);
  }

  /// Wykonuje pełny proces ekstrakcji oraz generacji artefaktów CSV/JSON.
  CareerAnalyticsExportResult exportCareerAnalytics(
    CareerSave save, {
    CareerAnalyticsExportConfig config = const CareerAnalyticsExportConfig(),
    List<SeasonAnalyticsSnapshot> historicalSnapshots = const [],
    DateTime? nowOverride,
  }) {
    final stopwatch = Stopwatch()..start();
    final now = nowOverride ?? DateTime.now();
    final warnings = <String>[];

    final dataset = extractDataset(
      save,
      config: config,
      historicalSnapshots: historicalSnapshots,
      nowOverride: now,
    );

    if (dataset.racePalmares.isEmpty) {
      warnings.add(
        'Brak ukończonych wyścigów w historii kariery dla wybranego zakresu lat.',
      );
    }
    if (dataset.financeBreakdown.isEmpty) {
      warnings.add(
        'Księga finansowa jest pusta dla wybranego zakresu sezonów.',
      );
    }

    final artifacts = <ExportedAnalyticsArtifact>[];
    final safeBaseName = _sanitizeFileName(
      '${save.saveName}_${config.scope.name}_${save.currentSeasonYear}',
    );

    if (config.format == AnalyticsExportFormat.csv ||
        config.format == AnalyticsExportFormat.csvAndJsonBundle) {
      final csvContent = exportToCsv(dataset, configOverride: config);
      artifacts.add(
        ExportedAnalyticsArtifact(
          fileName: '$safeBaseName.csv',
          format: AnalyticsExportFormat.csv,
          scope: config.scope,
          content: csvContent,
          byteSize: utf8.encode(csvContent).length,
          rowCount: _countRowsForScope(dataset, config.scope),
          checksumFnv1a64: computeFnv1a64(csvContent),
          generatedAt: now,
        ),
      );
    }

    if (config.format == AnalyticsExportFormat.json ||
        config.format == AnalyticsExportFormat.csvAndJsonBundle) {
      final jsonContent = exportToJson(dataset, configOverride: config);
      artifacts.add(
        ExportedAnalyticsArtifact(
          fileName: '$safeBaseName.json',
          format: AnalyticsExportFormat.json,
          scope: config.scope,
          content: jsonContent,
          byteSize: utf8.encode(jsonContent).length,
          rowCount: _countRowsForScope(dataset, config.scope),
          checksumFnv1a64: computeFnv1a64(jsonContent),
          generatedAt: now,
        ),
      );
    }

    stopwatch.stop();
    final totalBytes = artifacts.fold<int>(0, (acc, a) => acc + a.byteSize);
    final summaryMessage =
        'Wyeksportowano ${artifacts.length} plik(i) (${(totalBytes / 1024).toStringAsFixed(1)} KB) '
        'dla ${dataset.seasons.length} sezonów, ${dataset.riders.length} kolarzy '
        'i ${dataset.racePalmares.length} wyścigów.';

    return CareerAnalyticsExportResult(
      success: artifacts.isNotEmpty,
      dataset: dataset,
      artifacts: artifacts,
      summaryMessage: summaryMessage,
      warnings: warnings,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Zapisuje wygenerowane artefakty na dysku w katalogu [targetDirectory].
  Future<List<String>> writeArtifactsToDirectory(
    CareerAnalyticsExportResult result,
    Directory targetDirectory,
  ) async {
    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final writtenPaths = <String>[];
    for (final artifact in result.artifacts) {
      final separator = Platform.pathSeparator;
      final filePath = '${targetDirectory.path}$separator${artifact.fileName}';
      final file = File(filePath);
      await file.writeAsString(artifact.content, encoding: utf8);
      writtenPaths.add(file.path);
    }
    return writtenPaths;
  }

  /// Oblicza deterministyczną 64-bitową sumę kontrolną FNV-1a w zapisie szesnastkowym.
  String computeFnv1a64(String input) {
    final bytes = utf8.encode(input);
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = (BigInt.one << 64) - BigInt.one;

    for (final byte in bytes) {
      hash = (hash ^ BigInt.from(byte)) & mask;
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  SeasonAnalyticsSnapshot _buildCurrentSeasonSnapshot({
    required CareerSave save,
    required CyclingTeam playerTeam,
  }) {
    final seasonLedger = save.financeLedger
        .where((e) => e.date.year == save.currentSeasonYear)
        .toList();

    int income = 0;
    int expenses = 0;
    for (final entry in seasonLedger) {
      if (entry.amountEur >= 0) {
        income += entry.amountEur;
      } else {
        expenses += entry.amountEur.abs();
      }
    }

    final seasonRaces = save.calendar.raceHistory.values
        .where((r) => r.seasonYear == save.currentSeasonYear)
        .toList();
    final winsCount =
        seasonRaces.where((r) => r.winnerTeamId == save.playerTeamId).length;

    final roster = save.playerRoster;
    final avgAge = roster.isEmpty
        ? 0.0
        : roster.map((r) => r.age).reduce((a, b) => a + b) / roster.length;
    final avgFtp = roster.isEmpty
        ? 0.0
        : roster.map((r) => r.physiology.ftpWatts).reduce((a, b) => a + b) /
            roster.length;
    final avgVo2 = roster.isEmpty
        ? 0.0
        : roster.map((r) => r.physiology.vo2Max).reduce((a, b) => a + b) /
            roster.length;

    return SeasonAnalyticsSnapshot(
      seasonYear: save.currentSeasonYear,
      teamId: playerTeam.id,
      teamName: playerTeam.name,
      divisionName: playerTeam.division.label,
      uciPoints: playerTeam.uciPointsSeason,
      winsCount: winsCount,
      podiumsCount: winsCount,
      racesCompleted: save.calendar.completedRaceIds.length,
      totalIncomeEur: income,
      totalExpensesEur: expenses,
      netCashflowEur: income - expenses,
      cashBalanceEur: playerTeam.cashBalanceEur,
      averageRosterAge: avgAge,
      averageRosterFtpW: avgFtp,
      averageRosterVo2Max: avgVo2,
      managerReputation: save.managerReputation,
    );
  }

  List<FinanceCategoryAnalyticsRow> _buildFinanceBreakdown(
    List<CareerFinanceLedgerEntry> ledger, {
    int? seasonYearFrom,
    int? seasonYearTo,
  }) {
    final grouped = <int, Map<FinanceCategory, List<CareerFinanceLedgerEntry>>>{};
    final seasonTotals = <int, int>{};

    for (final entry in ledger) {
      final year = entry.date.year;
      if (seasonYearFrom != null && year < seasonYearFrom) continue;
      if (seasonYearTo != null && year > seasonYearTo) continue;

      grouped
          .putIfAbsent(year, () => <FinanceCategory, List<CareerFinanceLedgerEntry>>{})
          .putIfAbsent(entry.category, () => <CareerFinanceLedgerEntry>[])
          .add(entry);

      seasonTotals[year] = (seasonTotals[year] ?? 0) + entry.amountEur.abs();
    }

    final rows = <FinanceCategoryAnalyticsRow>[];
    final sortedYears = grouped.keys.toList()..sort();
    for (final year in sortedYears) {
      final yearTotalAbs = seasonTotals[year] ?? 0;
      final byCat = grouped[year]!;
      for (final catEntry in byCat.entries) {
        final entries = catEntry.value;
        final totalEur = entries.fold<int>(0, (acc, e) => acc + e.amountEur);
        final share = yearTotalAbs > 0
            ? (totalEur.abs() / yearTotalAbs) * 100.0
            : 0.0;

        rows.add(
          FinanceCategoryAnalyticsRow(
            seasonYear: year,
            category: catEntry.key.name,
            categoryLabel: catEntry.key.label,
            isIncome: totalEur >= 0,
            transactionCount: entries.length,
            totalAmountEur: totalEur,
            sharePercent: share,
          ),
        );
      }
    }

    rows.sort((a, b) {
      final yearCmp = b.seasonYear.compareTo(a.seasonYear);
      if (yearCmp != 0) return yearCmp;
      return b.totalAmountEur.abs().compareTo(a.totalAmountEur.abs());
    });
    return rows;
  }

  int _countRowsForScope(
    CareerAnalyticsDataset dataset,
    AnalyticsDatasetScope scope,
  ) {
    switch (scope) {
      case AnalyticsDatasetScope.fullCareer:
        return dataset.totalRowCount;
      case AnalyticsDatasetScope.seasonProgression:
        return dataset.seasons.length;
      case AnalyticsDatasetScope.ridersAndPhysiology:
        return dataset.riders.length;
      case AnalyticsDatasetScope.raceResultsAndPalmares:
        return dataset.racePalmares.length;
      case AnalyticsDatasetScope.financesAndRoi:
        return dataset.financeBreakdown.length;
      case AnalyticsDatasetScope.teamStandingsAndSponsors:
        return dataset.teamStandings.length;
    }
  }

  String _escapeCsv(String value, String delimiter) {
    final needsQuotes = value.contains(delimiter) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _sanitizeFileName(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'career_analytics_export' : cleaned;
  }
}

/// Stan Riverpod dla eksportera danych analitycznych kariery.
class CareerAnalyticsExporterState {
  final CareerAnalyticsExportConfig config;
  final bool isExporting;
  final CareerAnalyticsExportResult? lastResult;
  final List<String> lastWrittenPaths;
  final String? errorMessage;
  final List<CareerAnalyticsExportResult> exportHistory;

  const CareerAnalyticsExporterState({
    this.config = const CareerAnalyticsExportConfig(),
    this.isExporting = false,
    this.lastResult,
    this.lastWrittenPaths = const [],
    this.errorMessage,
    this.exportHistory = const [],
  });

  CareerAnalyticsExporterState copyWith({
    CareerAnalyticsExportConfig? config,
    bool? isExporting,
    CareerAnalyticsExportResult? lastResult,
    List<String>? lastWrittenPaths,
    String? errorMessage,
    bool clearError = false,
    List<CareerAnalyticsExportResult>? exportHistory,
  }) {
    return CareerAnalyticsExporterState(
      config: config ?? this.config,
      isExporting: isExporting ?? this.isExporting,
      lastResult: lastResult ?? this.lastResult,
      lastWrittenPaths: lastWrittenPaths ?? this.lastWrittenPaths,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportHistory: exportHistory ?? this.exportHistory,
    );
  }
}

/// Notifier zarządzający konfiguracją oraz historią eksportów CSV/JSON.
class CareerAnalyticsExporterNotifier
    extends StateNotifier<CareerAnalyticsExporterState> {
  final CareerStatisticsDeepAnalyticsExporter _exporter;

  CareerAnalyticsExporterNotifier({
    CareerStatisticsDeepAnalyticsExporter exporter =
        const CareerStatisticsDeepAnalyticsExporter(),
  })  : _exporter = exporter,
        super(const CareerAnalyticsExporterState());

  void setFormat(AnalyticsExportFormat format) {
    state = state.copyWith(
      config: state.config.copyWith(format: format),
      clearError: true,
    );
  }

  void setScope(AnalyticsDatasetScope scope) {
    state = state.copyWith(
      config: state.config.copyWith(scope: scope),
      clearError: true,
    );
  }

  void setDelimiter(CsvDelimiter delimiter) {
    state = state.copyWith(
      config: state.config.copyWith(delimiter: delimiter),
      clearError: true,
    );
  }

  void toggleIncludeBomForExcel(bool value) {
    state = state.copyWith(
      config: state.config.copyWith(includeBomForExcel: value),
    );
  }

  void toggleIncludeMetadataHeader(bool value) {
    state = state.copyWith(
      config: state.config.copyWith(includeMetadataHeader: value),
    );
  }

  void togglePrettyPrintJson(bool value) {
    state = state.copyWith(
      config: state.config.copyWith(prettyPrintJson: value),
    );
  }

  void togglePlayerTeamOnly(bool value) {
    state = state.copyWith(
      config: state.config.copyWith(playerTeamOnly: value),
    );
  }

  void toggleAnonymizeRivalNames(bool value) {
    state = state.copyWith(
      config: state.config.copyWith(anonymizeRivalNames: value),
    );
  }

  void setSeasonRange({int? fromYear, int? toYear}) {
    state = state.copyWith(
      config: state.config.copyWith(
        seasonYearFrom: fromYear,
        seasonYearTo: toYear,
        clearSeasonYearFrom: fromYear == null,
        clearSeasonYearTo: toYear == null,
      ),
    );
  }

  /// Uruchamia eksport w pamięci na podstawie przekazanego zapisu kariery.
  CareerAnalyticsExportResult runExport(
    CareerSave save, {
    List<SeasonAnalyticsSnapshot> historicalSnapshots = const [],
  }) {
    state = state.copyWith(isExporting: true, clearError: true);
    try {
      final result = _exporter.exportCareerAnalytics(
        save,
        config: state.config,
        historicalSnapshots: historicalSnapshots,
      );
      final updatedHistory = [
        result,
        ...state.exportHistory.take(9),
      ];
      state = state.copyWith(
        isExporting: false,
        lastResult: result,
        exportHistory: updatedHistory,
      );
      return result;
    } catch (error) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Błąd podczas generowania eksportu: $error',
      );
      rethrow;
    }
  }

  /// Zapisuje wygenerowane artefakty z ostatniego eksportu do wskazanego katalogu.
  Future<List<String>> saveLastExportToDirectory(Directory directory) async {
    final last = state.lastResult;
    if (last == null) {
      throw StateError('Brak wygenerowanego eksportu do zapisania.');
    }
    final paths = await _exporter.writeArtifactsToDirectory(last, directory);
    state = state.copyWith(lastWrittenPaths: paths);
    return paths;
  }

  void clearHistory() {
    state = state.copyWith(
      exportHistory: const [],
      lastWrittenPaths: const [],
      clearError: true,
    );
  }
}

/// Globalny provider eksportera danych analitycznych kariery.
final careerAnalyticsExporterProvider = StateNotifierProvider<
    CareerAnalyticsExporterNotifier, CareerAnalyticsExporterState>(
  (ref) => CareerAnalyticsExporterNotifier(),
);

/// Produkcyjny panel UI do konfiguracji, podglądu i eksportu danych analitycznych
/// CSV/JSON z wieloletniej kariery menedżerskiej.
class CareerStatisticsDeepAnalyticsExporterPanel extends ConsumerStatefulWidget {
  final CareerSave careerSave;
  final List<SeasonAnalyticsSnapshot> historicalSnapshots;
  final ValueChanged<CareerAnalyticsExportResult>? onExportCompleted;

  const CareerStatisticsDeepAnalyticsExporterPanel({
    super.key,
    required this.careerSave,
    this.historicalSnapshots = const [],
    this.onExportCompleted,
  });

  @override
  ConsumerState<CareerStatisticsDeepAnalyticsExporterPanel> createState() =>
      _CareerStatisticsDeepAnalyticsExporterPanelState();
}

class _CareerStatisticsDeepAnalyticsExporterPanelState
    extends ConsumerState<CareerStatisticsDeepAnalyticsExporterPanel> {
  int _selectedArtifactIndex = 0;
  bool _copiedFeedback = false;

  void _triggerExport() {
    final notifier = ref.read(careerAnalyticsExporterProvider.notifier);
    final result = notifier.runExport(
      widget.careerSave,
      historicalSnapshots: widget.historicalSnapshots,
    );
    setState(() {
      _selectedArtifactIndex = 0;
      _copiedFeedback = false;
    });
    widget.onExportCompleted?.call(result);
  }

  Future<void> _copyActiveArtifact(ExportedAnalyticsArtifact artifact) async {
    await Clipboard.setData(ClipboardData(text: artifact.content));
    if (!mounted) return;
    setState(() {
      _copiedFeedback = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(careerAnalyticsExporterProvider);
    final notifier = ref.read(careerAnalyticsExporterProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 720;
        final isWide = width >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, isCompact),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildConfigurationCard(
                          state,
                          notifier,
                          isCompact,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _buildPreviewAndResultsCard(state, isCompact),
                      ),
                    ],
                  )
                else ...[
                  _buildConfigurationCard(state, notifier, isCompact),
                  const SizedBox(height: 16),
                  _buildPreviewAndResultsCard(state, isCompact),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(CareerAnalyticsExporterState state, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryAccent, width: 1),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
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
                      'Eksporter Analityczny Kariery (CSV / JSON)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.careerSave.saveName} • Sezon ${widget.careerSave.currentSeasonYear} • ${widget.careerSave.playerTeam.name}',
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
          _InteractiveActionButton(
            label: state.isExporting ? 'Generowanie...' : 'Eksportuj Dane BI',
            icon: Icons.download_rounded,
            isPrimary: true,
            enabled: !state.isExporting,
            onPressed: _triggerExport,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationCard(
    CareerAnalyticsExporterState state,
    CareerAnalyticsExporterNotifier notifier,
    bool isCompact,
  ) {
    final cfg = state.config;
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfiguracja Eksportu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Format wyjściowy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AnalyticsExportFormat.values.map((format) {
              return _InteractiveSelectChip(
                label: format.labelPl,
                selected: cfg.format == format,
                onTap: () => notifier.setFormat(format),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Zakres danych analitycznych',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AnalyticsDatasetScope.values.map((scope) {
              return _InteractiveSelectChip(
                label: scope.labelPl,
                selected: cfg.scope == scope,
                onTap: () => notifier.setScope(scope),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Separator kolumn CSV',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CsvDelimiter.values.map((delimiter) {
              final csvEnabled = cfg.format != AnalyticsExportFormat.json;
              return _InteractiveSelectChip(
                label: delimiter.labelPl,
                selected: cfg.delimiter == delimiter,
                enabled: csvEnabled,
                onTap: () => notifier.setDelimiter(delimiter),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 12),
          _InteractiveToggleRow(
            title: 'UTF-8 BOM dla Microsoft Excel',
            subtitle: 'Zapobiega krzakom polskich znaków w Excelu',
            value: cfg.includeBomForExcel,
            enabled: cfg.format != AnalyticsExportFormat.json,
            onChanged: notifier.toggleIncludeBomForExcel,
          ),
          _InteractiveToggleRow(
            title: 'Nagłówek metadanych CSV',
            subtitle: 'Dodaje linie komentarza z nazwą zapisu i datą',
            value: cfg.includeMetadataHeader,
            enabled: cfg.format != AnalyticsExportFormat.json,
            onChanged: notifier.toggleIncludeMetadataHeader,
          ),
          _InteractiveToggleRow(
            title: 'Czytelne formatowanie JSON (Pretty Print)',
            subtitle: 'Wcięcia 2-spacjowe dla audytu i skryptów BI',
            value: cfg.prettyPrintJson,
            enabled: cfg.format != AnalyticsExportFormat.csv,
            onChanged: notifier.togglePrettyPrintJson,
          ),
          _InteractiveToggleRow(
            title: 'Tylko drużyna gracza',
            subtitle: 'Filtruje kolarzy i palmares wyłącznie do Twojej ekipy',
            value: cfg.playerTeamOnly,
            onChanged: notifier.togglePlayerTeamOnly,
          ),
          _InteractiveToggleRow(
            title: 'Anonimizuj rywali AI',
            subtitle: 'Zastępuje nazwy rywali identyfikatorami hash',
            value: cfg.anonymizeRivalNames,
            onChanged: notifier.toggleAnonymizeRivalNames,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewAndResultsCard(
    CareerAnalyticsExporterState state,
    bool isCompact,
  ) {
    final result = state.lastResult;
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
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
              const Expanded(
                child: Text(
                  'Podgląd Artefaktów i Metryki',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (result != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.statusSuccess),
                  ),
                  child: Text(
                    '${result.durationMs} ms',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.crimsonAlert),
              ),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.crimsonAlert,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (result == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: 36,
                    color: AppColors.accentBlue,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Kliknij „Eksportuj Dane BI”, aby wygenerować paczkę CSV/JSON.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Eksport zawiera dane sezonowe, fizjologię kolarzy, ROI płacowe oraz księgę finansową.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildKpiStrip(result.dataset),
            const SizedBox(height: 12),
            Text(
              result.summaryMessage,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...result.warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: AppColors.amberWarning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          w,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.amberWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(result.artifacts.length, (index) {
                final artifact = result.artifacts[index];
                return _InteractiveSelectChip(
                  label:
                      '${artifact.format == AnalyticsExportFormat.csv ? "CSV" : "JSON"} (${(artifact.byteSize / 1024).toStringAsFixed(1)} KB)',
                  selected: _selectedArtifactIndex == index,
                  onTap: () {
                    setState(() {
                      _selectedArtifactIndex = index;
                      _copiedFeedback = false;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            if (result.artifacts.isNotEmpty)
              _buildArtifactPreview(
                result.artifacts[_selectedArtifactIndex
                    .clamp(0, result.artifacts.length - 1)],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiStrip(CareerAnalyticsDataset dataset) {
    final m = dataset.summaryMetrics;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _KpiMetricTile(label: 'Sezony', value: '${m.seasonsTracked}'),
        _KpiMetricTile(label: 'Kolarze', value: '${m.totalRidersExported}'),
        _KpiMetricTile(label: 'Wyścigi', value: '${m.totalRacesInPalmares}'),
        _KpiMetricTile(
          label: 'Śr. W/kg',
          value: m.averageRosterWPerKg.toStringAsFixed(2),
        ),
      ],
    );
  }

  Widget _buildArtifactPreview(ExportedAnalyticsArtifact artifact) {
    final previewLines = artifact.content.split('\n').take(18).join('\n');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artifact.fileName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'FNV-1a64: ${artifact.checksumFnv1a64} • Wiersze: ${artifact.rowCount}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              _InteractiveActionButton(
                label: _copiedFeedback ? 'Skopiowano' : 'Kopiuj treść',
                icon: _copiedFeedback ? Icons.check_rounded : Icons.copy_rounded,
                isPrimary: false,
                enabled: true,
                onPressed: () => _copyActiveArtifact(artifact),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                previewLines,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.accentBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _KpiMetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.goldAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
            ? baseColor.withValues(alpha: 0.78)
            : _hovered
                ? (widget.isPrimary
                    ? AppColors.primaryAccent.withValues(alpha: 0.9)
                    : AppColors.cardBorder)
                : baseColor;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : (widget.isPrimary ? AppColors.goldAccent : AppColors.cardBorder);

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.enabled
                      ? (widget.isPrimary
                          ? AppColors.textPrimary
                          : AppColors.goldAccent)
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
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

class _InteractiveSelectChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _InteractiveSelectChip({
    required this.label,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<_InteractiveSelectChip> createState() => _InteractiveSelectChipState();
}

class _InteractiveSelectChipState extends State<_InteractiveSelectChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.85 : 0.28)
            : _hovered
                ? AppColors.cardBorder
                : AppColors.surfaceLight;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.35)
        : _focused
            ? AppColors.accentBlue
            : widget.selected
                ? AppColors.goldAccent
                : AppColors.cardBorder;

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: !widget.enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : widget.selected
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveToggleRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _InteractiveToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<_InteractiveToggleRow> createState() => _InteractiveToggleRowState();
}

class _InteractiveToggleRowState extends State<_InteractiveToggleRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? AppColors.surfaceLight
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.accentBlue : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary.withValues(alpha: 0.45),
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: widget.enabled
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.value,
                  onChanged: widget.enabled ? widget.onChanged : null,
                  activeThumbColor: AppColors.goldAccent,
                  activeTrackColor: AppColors.primaryAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
