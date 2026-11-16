import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Kategorie dorocznego plebiscytu Vélo d'Or (Złoty Rower) na koniec października.
enum VeloDorAwardCategory {
  /// Główna nagroda: Najlepszy Kolarz Świata (Vélo d'Or).
  worldBestRider,

  /// Najlepszy Góral Sezonu (Trophée du Grimpeur).
  bestClimber,

  /// Najlepszy Klasykowiec i Specjalista Monumentów (Trophée des Classiques).
  bestClassicsRider,

  /// Odkrycie Sezonu U23 (Trophée Espoir U23).
  u23Breakthrough,

  /// Menedżer Roku WorldTour / ProSeries (Directeur Sportif de l'Année).
  managerOfTheYear;

  String toJson() => name;

  static VeloDorAwardCategory fromJson(String value) {
    return VeloDorAwardCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => VeloDorAwardCategory.worldBestRider,
    );
  }

  String get displayName {
    switch (this) {
      case VeloDorAwardCategory.worldBestRider:
        return "Vélo d'Or — Najlepszy Kolarz Świata";
      case VeloDorAwardCategory.bestClimber:
        return 'Najlepszy Góral Roku';
      case VeloDorAwardCategory.bestClassicsRider:
        return 'Najlepszy Klasykowiec Roku';
      case VeloDorAwardCategory.u23Breakthrough:
        return 'Odkrycie Sezonu U23';
      case VeloDorAwardCategory.managerOfTheYear:
        return 'Menedżer Roku';
    }
  }

  String get shortLabel {
    switch (this) {
      case VeloDorAwardCategory.worldBestRider:
        return "Vélo d'Or";
      case VeloDorAwardCategory.bestClimber:
        return 'Góral Roku';
      case VeloDorAwardCategory.bestClassicsRider:
        return 'Klasykowiec';
      case VeloDorAwardCategory.u23Breakthrough:
        return 'Odkrycie U23';
      case VeloDorAwardCategory.managerOfTheYear:
        return 'Menedżer Roku';
    }
  }

  String get frenchSubtitle {
    switch (this) {
      case VeloDorAwardCategory.worldBestRider:
        return "Trophée Vélo d'Or Mondial";
      case VeloDorAwardCategory.bestClimber:
        return 'Trophée Bernard Hinault — Meilleur Grimpeur';
      case VeloDorAwardCategory.bestClassicsRider:
        return 'Trophée des Flandres & Monuments';
      case VeloDorAwardCategory.u23Breakthrough:
        return 'Trophée Révélation Espoir U23';
      case VeloDorAwardCategory.managerOfTheYear:
        return "Directeur Sportif de l'Année";
    }
  }

  String get trophyTitle {
    switch (this) {
      case VeloDorAwardCategory.worldBestRider:
        return 'Złoty Rower (24-karatowe złoto)';
      case VeloDorAwardCategory.bestClimber:
        return 'Kryształowy Szczyt & Złote Grochy';
      case VeloDorAwardCategory.bestClassicsRider:
        return 'Złota Kostka Bruku Monumentów';
      case VeloDorAwardCategory.u23Breakthrough:
        return 'Biała Statuetka Młodego Lwa';
      case VeloDorAwardCategory.managerOfTheYear:
        return 'Złote Koło Taktyczne Dyrektora';
    }
  }

  int get prestigeReward {
    switch (this) {
      case VeloDorAwardCategory.worldBestRider:
        return 120;
      case VeloDorAwardCategory.bestClimber:
        return 75;
      case VeloDorAwardCategory.bestClassicsRider:
        return 75;
      case VeloDorAwardCategory.u23Breakthrough:
        return 65;
      case VeloDorAwardCategory.managerOfTheYear:
        return 95;
    }
  }
}

/// Specyfikacja wręczanej statuetki na gali Vélo d'Or.
class VeloDorStatuetteSpec {
  final VeloDorAwardCategory category;
  final String trophyName;
  final String materialFinish;
  final String engravingLine;
  final int seasonYear;

  const VeloDorStatuetteSpec({
    required this.category,
    required this.trophyName,
    required this.materialFinish,
    required this.engravingLine,
    required this.seasonYear,
  });

  Map<String, dynamic> toJson() => {
        'category': category.toJson(),
        'trophyName': trophyName,
        'materialFinish': materialFinish,
        'engravingLine': engravingLine,
        'seasonYear': seasonYear,
      };

  factory VeloDorStatuetteSpec.fromJson(Map<String, dynamic> json) {
    return VeloDorStatuetteSpec(
      category: VeloDorAwardCategory.fromJson(
        (json['category'] as String?) ?? 'worldBestRider',
      ),
      trophyName: (json['trophyName'] as String?) ?? "Vélo d'Or",
      materialFinish: (json['materialFinish'] as String?) ?? '24k Gold',
      engravingLine: (json['engravingLine'] as String?) ?? '',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
    );
  }
}

/// Dane sezonowe kolarza oceniane przez międzynarodowe jury dziennikarzy Vélo d'Or.
class VeloDorRiderSeasonStats {
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final String nationalityIso;
  final int age;
  final RiderSpecialization specialization;
  final bool isPlayerTeam;
  final int uciPointsSeason;
  final int grandTourGcWins;
  final int grandTourPodiums;
  final int grandTourStageWins;
  final int monumentWins;
  final int monumentPodiums;
  final int worldTourClassicWins;
  final int worldTourStageRaceWins;
  final int komJerseyWins;
  final int mountainStageWins;
  final double peakClimbWPerKg;
  final bool worldChampionRoad;
  final bool worldChampionTt;
  final bool olympicGold;
  final int totalSeasonWins;
  final int overallRating;

  const VeloDorRiderSeasonStats({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.nationalityIso,
    required this.age,
    required this.specialization,
    this.isPlayerTeam = false,
    this.uciPointsSeason = 0,
    this.grandTourGcWins = 0,
    this.grandTourPodiums = 0,
    this.grandTourStageWins = 0,
    this.monumentWins = 0,
    this.monumentPodiums = 0,
    this.worldTourClassicWins = 0,
    this.worldTourStageRaceWins = 0,
    this.komJerseyWins = 0,
    this.mountainStageWins = 0,
    this.peakClimbWPerKg = 5.6,
    this.worldChampionRoad = false,
    this.worldChampionTt = false,
    this.olympicGold = false,
    this.totalSeasonWins = 0,
    this.overallRating = 75,
  });

  bool get isU23Eligible => age <= 23;

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamId': teamId,
        'teamName': teamName,
        'nationalityIso': nationalityIso,
        'age': age,
        'specialization': specialization.toJson(),
        'isPlayerTeam': isPlayerTeam,
        'uciPointsSeason': uciPointsSeason,
        'grandTourGcWins': grandTourGcWins,
        'grandTourPodiums': grandTourPodiums,
        'grandTourStageWins': grandTourStageWins,
        'monumentWins': monumentWins,
        'monumentPodiums': monumentPodiums,
        'worldTourClassicWins': worldTourClassicWins,
        'worldTourStageRaceWins': worldTourStageRaceWins,
        'komJerseyWins': komJerseyWins,
        'mountainStageWins': mountainStageWins,
        'peakClimbWPerKg': peakClimbWPerKg,
        'worldChampionRoad': worldChampionRoad,
        'worldChampionTt': worldChampionTt,
        'olympicGold': olympicGold,
        'totalSeasonWins': totalSeasonWins,
        'overallRating': overallRating,
      };

  factory VeloDorRiderSeasonStats.fromJson(Map<String, dynamic> json) {
    return VeloDorRiderSeasonStats(
      riderId: (json['riderId'] as String?) ?? '',
      riderName: (json['riderName'] as String?) ?? '',
      teamId: (json['teamId'] as String?) ?? '',
      teamName: (json['teamName'] as String?) ?? '',
      nationalityIso: (json['nationalityIso'] as String?) ?? 'INT',
      age: (json['age'] as num?)?.toInt() ?? 25,
      specialization: RiderSpecialization.fromJson(
        (json['specialization'] as String?) ?? 'domestiqueEngine',
      ),
      isPlayerTeam: (json['isPlayerTeam'] as bool?) ?? false,
      uciPointsSeason: (json['uciPointsSeason'] as num?)?.toInt() ?? 0,
      grandTourGcWins: (json['grandTourGcWins'] as num?)?.toInt() ?? 0,
      grandTourPodiums: (json['grandTourPodiums'] as num?)?.toInt() ?? 0,
      grandTourStageWins: (json['grandTourStageWins'] as num?)?.toInt() ?? 0,
      monumentWins: (json['monumentWins'] as num?)?.toInt() ?? 0,
      monumentPodiums: (json['monumentPodiums'] as num?)?.toInt() ?? 0,
      worldTourClassicWins: (json['worldTourClassicWins'] as num?)?.toInt() ?? 0,
      worldTourStageRaceWins:
          (json['worldTourStageRaceWins'] as num?)?.toInt() ?? 0,
      komJerseyWins: (json['komJerseyWins'] as num?)?.toInt() ?? 0,
      mountainStageWins: (json['mountainStageWins'] as num?)?.toInt() ?? 0,
      peakClimbWPerKg: (json['peakClimbWPerKg'] as num?)?.toDouble() ?? 5.6,
      worldChampionRoad: (json['worldChampionRoad'] as bool?) ?? false,
      worldChampionTt: (json['worldChampionTt'] as bool?) ?? false,
      olympicGold: (json['olympicGold'] as bool?) ?? false,
      totalSeasonWins: (json['totalSeasonWins'] as num?)?.toInt() ?? 0,
      overallRating: (json['overallRating'] as num?)?.toInt() ?? 75,
    );
  }
}

/// Kandydat do nagrody Menedżera Roku w plebiscycie Vélo d'Or.
class VeloDorManagerCandidate {
  final String managerId;
  final String managerName;
  final String teamId;
  final String teamName;
  final String nationalityIso;
  final TeamDivision division;
  final bool isPlayerTeam;
  final int teamUciPoints;
  final int totalSeasonWins;
  final int grandTourWins;
  final int monumentWins;
  final double sponsorObjectivesRatio; // 0.0 - 1.0
  final double budgetEfficiencyScore; // 0.0 - 100.0
  final double staffSynergyScore; // 0.0 - 100.0

  const VeloDorManagerCandidate({
    required this.managerId,
    required this.managerName,
    required this.teamId,
    required this.teamName,
    required this.nationalityIso,
    required this.division,
    this.isPlayerTeam = false,
    this.teamUciPoints = 0,
    this.totalSeasonWins = 0,
    this.grandTourWins = 0,
    this.monumentWins = 0,
    this.sponsorObjectivesRatio = 0.5,
    this.budgetEfficiencyScore = 60.0,
    this.staffSynergyScore = 70.0,
  });

  Map<String, dynamic> toJson() => {
        'managerId': managerId,
        'managerName': managerName,
        'teamId': teamId,
        'teamName': teamName,
        'nationalityIso': nationalityIso,
        'division': division.toJson(),
        'isPlayerTeam': isPlayerTeam,
        'teamUciPoints': teamUciPoints,
        'totalSeasonWins': totalSeasonWins,
        'grandTourWins': grandTourWins,
        'monumentWins': monumentWins,
        'sponsorObjectivesRatio': sponsorObjectivesRatio,
        'budgetEfficiencyScore': budgetEfficiencyScore,
        'staffSynergyScore': staffSynergyScore,
      };

  factory VeloDorManagerCandidate.fromJson(Map<String, dynamic> json) {
    return VeloDorManagerCandidate(
      managerId: (json['managerId'] as String?) ?? '',
      managerName: (json['managerName'] as String?) ?? '',
      teamId: (json['teamId'] as String?) ?? '',
      teamName: (json['teamName'] as String?) ?? '',
      nationalityIso: (json['nationalityIso'] as String?) ?? 'INT',
      division: TeamDivision.fromJson(
        (json['division'] as String?) ?? 'worldTour',
      ),
      isPlayerTeam: (json['isPlayerTeam'] as bool?) ?? false,
      teamUciPoints: (json['teamUciPoints'] as num?)?.toInt() ?? 0,
      totalSeasonWins: (json['totalSeasonWins'] as num?)?.toInt() ?? 0,
      grandTourWins: (json['grandTourWins'] as num?)?.toInt() ?? 0,
      monumentWins: (json['monumentWins'] as num?)?.toInt() ?? 0,
      sponsorObjectivesRatio:
          (json['sponsorObjectivesRatio'] as num?)?.toDouble() ?? 0.5,
      budgetEfficiencyScore:
          (json['budgetEfficiencyScore'] as num?)?.toDouble() ?? 60.0,
      staffSynergyScore:
          (json['staffSynergyScore'] as num?)?.toDouble() ?? 70.0,
    );
  }
}

/// Rozbicie głosów jury dziennikarzy i ekspertów kolarskich.
class VeloDorJuryVoteBreakdown {
  final double sportingResultsScore;
  final double prestigeMultiplierScore;
  final double journalistPanelVotes;
  final double peerDirectorsVotes;
  final double totalScore;
  final double voteSharePercent;

  const VeloDorJuryVoteBreakdown({
    required this.sportingResultsScore,
    required this.prestigeMultiplierScore,
    required this.journalistPanelVotes,
    required this.peerDirectorsVotes,
    required this.totalScore,
    required this.voteSharePercent,
  });

  Map<String, dynamic> toJson() => {
        'sportingResultsScore': sportingResultsScore,
        'prestigeMultiplierScore': prestigeMultiplierScore,
        'journalistPanelVotes': journalistPanelVotes,
        'peerDirectorsVotes': peerDirectorsVotes,
        'totalScore': totalScore,
        'voteSharePercent': voteSharePercent,
      };

  factory VeloDorJuryVoteBreakdown.fromJson(Map<String, dynamic> json) {
    return VeloDorJuryVoteBreakdown(
      sportingResultsScore:
          (json['sportingResultsScore'] as num?)?.toDouble() ?? 0.0,
      prestigeMultiplierScore:
          (json['prestigeMultiplierScore'] as num?)?.toDouble() ?? 0.0,
      journalistPanelVotes:
          (json['journalistPanelVotes'] as num?)?.toDouble() ?? 0.0,
      peerDirectorsVotes:
          (json['peerDirectorsVotes'] as num?)?.toDouble() ?? 0.0,
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
      voteSharePercent: (json['voteSharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Wynik pojedynczego nominowanego w danej kategorii plebiscytu Vélo d'Or.
class VeloDorNomineeResult {
  final int rank;
  final String candidateId;
  final String candidateName;
  final String teamId;
  final String teamName;
  final String nationalityIso;
  final bool isPlayerTeam;
  final String roleOrSpecialty;
  final VeloDorJuryVoteBreakdown voteBreakdown;
  final List<String> seasonHighlights;
  final VeloDorStatuetteSpec? statuetteSpec;

  const VeloDorNomineeResult({
    required this.rank,
    required this.candidateId,
    required this.candidateName,
    required this.teamId,
    required this.teamName,
    required this.nationalityIso,
    required this.isPlayerTeam,
    required this.roleOrSpecialty,
    required this.voteBreakdown,
    required this.seasonHighlights,
    this.statuetteSpec,
  });

  bool get isWinner => rank == 1;

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'candidateId': candidateId,
        'candidateName': candidateName,
        'teamId': teamId,
        'teamName': teamName,
        'nationalityIso': nationalityIso,
        'isPlayerTeam': isPlayerTeam,
        'roleOrSpecialty': roleOrSpecialty,
        'voteBreakdown': voteBreakdown.toJson(),
        'seasonHighlights': seasonHighlights,
        'statuetteSpec': statuetteSpec?.toJson(),
      };

  factory VeloDorNomineeResult.fromJson(Map<String, dynamic> json) {
    return VeloDorNomineeResult(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      candidateId: (json['candidateId'] as String?) ?? '',
      candidateName: (json['candidateName'] as String?) ?? '',
      teamId: (json['teamId'] as String?) ?? '',
      teamName: (json['teamName'] as String?) ?? '',
      nationalityIso: (json['nationalityIso'] as String?) ?? 'INT',
      isPlayerTeam: (json['isPlayerTeam'] as bool?) ?? false,
      roleOrSpecialty: (json['roleOrSpecialty'] as String?) ?? '',
      voteBreakdown: VeloDorJuryVoteBreakdown.fromJson(
        Map<String, dynamic>.from((json['voteBreakdown'] as Map?) ?? {}),
      ),
      seasonHighlights: ((json['seasonHighlights'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      statuetteSpec: json['statuetteSpec'] is Map
          ? VeloDorStatuetteSpec.fromJson(
              Map<String, dynamic>.from(json['statuetteSpec'] as Map),
            )
          : null,
    );
  }
}

/// Wyniki pojedynczej kategorii plebiscytu Vélo d'Or (zwycięzca + podium finalistów).
class VeloDorCategoryResult {
  final VeloDorAwardCategory category;
  final VeloDorNomineeResult? winner;
  final List<VeloDorNomineeResult> podiumFinalists;
  final int totalCandidatesEvaluated;
  final String ceremonyCitation;

  const VeloDorCategoryResult({
    required this.category,
    required this.winner,
    required this.podiumFinalists,
    required this.totalCandidatesEvaluated,
    required this.ceremonyCitation,
  });

  Map<String, dynamic> toJson() => {
        'category': category.toJson(),
        'winner': winner?.toJson(),
        'podiumFinalists': podiumFinalists.map((e) => e.toJson()).toList(),
        'totalCandidatesEvaluated': totalCandidatesEvaluated,
        'ceremonyCitation': ceremonyCitation,
      };

  factory VeloDorCategoryResult.fromJson(Map<String, dynamic> json) {
    return VeloDorCategoryResult(
      category: VeloDorAwardCategory.fromJson(
        (json['category'] as String?) ?? 'worldBestRider',
      ),
      winner: json['winner'] is Map
          ? VeloDorNomineeResult.fromJson(
              Map<String, dynamic>.from(json['winner'] as Map),
            )
          : null,
      podiumFinalists: ((json['podiumFinalists'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => VeloDorNomineeResult.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalCandidatesEvaluated:
          (json['totalCandidatesEvaluated'] as num?)?.toInt() ?? 0,
      ceremonyCitation: (json['ceremonyCitation'] as String?) ?? '',
    );
  }
}

/// Pełny protokół gali wręczenia statuetek Vélo d'Or na koniec października.
class VeloDorCeremonyReport {
  final int seasonYear;
  final DateTime ceremonyDate;
  final String venue;
  final bool isOfficialLateOctoberWindow;
  final Map<VeloDorAwardCategory, VeloDorCategoryResult> categoryResults;
  final int playerTeamAwardsWon;
  final int playerTeamPrestigeGain;
  final int playerTeamMoraleBoost;

  const VeloDorCeremonyReport({
    required this.seasonYear,
    required this.ceremonyDate,
    required this.venue,
    required this.isOfficialLateOctoberWindow,
    required this.categoryResults,
    required this.playerTeamAwardsWon,
    required this.playerTeamPrestigeGain,
    required this.playerTeamMoraleBoost,
  });

  VeloDorCategoryResult? resultFor(VeloDorAwardCategory category) =>
      categoryResults[category];

  List<VeloDorCategoryResult> get orderedCategories => VeloDorAwardCategory.values
      .map((c) => categoryResults[c])
      .whereType<VeloDorCategoryResult>()
      .toList();

  Map<String, dynamic> toJson() => {
        'seasonYear': seasonYear,
        'ceremonyDate': ceremonyDate.toIso8601String(),
        'venue': venue,
        'isOfficialLateOctoberWindow': isOfficialLateOctoberWindow,
        'categoryResults': categoryResults.map(
          (key, value) => MapEntry(key.toJson(), value.toJson()),
        ),
        'playerTeamAwardsWon': playerTeamAwardsWon,
        'playerTeamPrestigeGain': playerTeamPrestigeGain,
        'playerTeamMoraleBoost': playerTeamMoraleBoost,
      };

  factory VeloDorCeremonyReport.fromJson(Map<String, dynamic> json) {
    final rawMap = (json['categoryResults'] as Map?) ?? const {};
    final parsedCategories = <VeloDorAwardCategory, VeloDorCategoryResult>{};
    for (final entry in rawMap.entries) {
      if (entry.value is Map) {
        final category = VeloDorAwardCategory.fromJson(entry.key.toString());
        parsedCategories[category] = VeloDorCategoryResult.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    return VeloDorCeremonyReport(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      ceremonyDate: DateTime.tryParse((json['ceremonyDate'] as String?) ?? '') ??
          DateTime(2026, 10, 29, 20, 0),
      venue: (json['venue'] as String?) ?? 'Pavillon Gabriel, Paryż',
      isOfficialLateOctoberWindow:
          (json['isOfficialLateOctoberWindow'] as bool?) ?? true,
      categoryResults: parsedCategories,
      playerTeamAwardsWon:
          (json['playerTeamAwardsWon'] as num?)?.toInt() ?? 0,
      playerTeamPrestigeGain:
          (json['playerTeamPrestigeGain'] as num?)?.toInt() ?? 0,
      playerTeamMoraleBoost:
          (json['playerTeamMoraleBoost'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Doroczny plebiscyt Vélo d'Or (Złoty Rower) rozstrzygany pod koniec października.
class SeasonAwardsVeloDorCeremony {
  const SeasonAwardsVeloDorCeremony();

  /// Sprawdza, czy podana data przypada w oknie gali Vélo d'Or (25–31 października).
  static bool isLateOctoberCeremonyDate(DateTime date) {
    return date.month == 10 && date.day >= 25 && date.day <= 31;
  }

  /// Domyślna data uroczystej gali Vélo d'Or w Paryżu (29 października, 20:00).
  static DateTime defaultCeremonyDate(int seasonYear) {
    return DateTime(seasonYear, 10, 29, 20, 0);
  }

  /// Przeprowadza pełne głosowanie jury i generuje raport gali wręczenia statuetek.
  VeloDorCeremonyReport conductCeremony({
    required int seasonYear,
    DateTime? ceremonyDate,
    required List<VeloDorRiderSeasonStats> riderCandidates,
    required List<VeloDorManagerCandidate> managerCandidates,
    String venue = 'Pavillon Gabriel, Paryż',
  }) {
    final effectiveDate = ceremonyDate ?? defaultCeremonyDate(seasonYear);
    final isOfficialWindow = isLateOctoberCeremonyDate(effectiveDate);

    final worldBest = _evaluateRiderCategory(
      category: VeloDorAwardCategory.worldBestRider,
      seasonYear: seasonYear,
      candidates: riderCandidates,
      scorer: _scoreWorldBestRider,
      highlightsBuilder: _buildWorldBestHighlights,
    );

    final bestClimber = _evaluateRiderCategory(
      category: VeloDorAwardCategory.bestClimber,
      seasonYear: seasonYear,
      candidates: riderCandidates,
      scorer: _scoreBestClimber,
      highlightsBuilder: _buildClimberHighlights,
    );

    final bestClassics = _evaluateRiderCategory(
      category: VeloDorAwardCategory.bestClassicsRider,
      seasonYear: seasonYear,
      candidates: riderCandidates,
      scorer: _scoreBestClassicsRider,
      highlightsBuilder: _buildClassicsHighlights,
    );

    final u23Candidates =
        riderCandidates.where((c) => c.isU23Eligible).toList();
    final u23Breakthrough = _evaluateRiderCategory(
      category: VeloDorAwardCategory.u23Breakthrough,
      seasonYear: seasonYear,
      candidates: u23Candidates,
      scorer: _scoreU23Breakthrough,
      highlightsBuilder: _buildU23Highlights,
    );

    final managerAward = _evaluateManagerCategory(
      seasonYear: seasonYear,
      candidates: managerCandidates,
    );

    final results = <VeloDorAwardCategory, VeloDorCategoryResult>{
      VeloDorAwardCategory.worldBestRider: worldBest,
      VeloDorAwardCategory.bestClimber: bestClimber,
      VeloDorAwardCategory.bestClassicsRider: bestClassics,
      VeloDorAwardCategory.u23Breakthrough: u23Breakthrough,
      VeloDorAwardCategory.managerOfTheYear: managerAward,
    };

    int playerAwards = 0;
    int prestigeGain = 0;
    for (final entry in results.entries) {
      final winner = entry.value.winner;
      if (winner != null && winner.isPlayerTeam) {
        playerAwards++;
        prestigeGain += entry.key.prestigeReward;
      }
    }

    final moraleBoost = playerAwards > 0 ? math.min(25, 6 + playerAwards * 5) : 0;

    return VeloDorCeremonyReport(
      seasonYear: seasonYear,
      ceremonyDate: effectiveDate,
      venue: venue,
      isOfficialLateOctoberWindow: isOfficialWindow,
      categoryResults: results,
      playerTeamAwardsWon: playerAwards,
      playerTeamPrestigeGain: prestigeGain,
      playerTeamMoraleBoost: moraleBoost,
    );
  }

  /// Buduje kandydatów bezpośrednio z aktywnego zapisu kariery [CareerSave].
  VeloDorCeremonyReport conductCeremonyFromCareerSave(
    CareerSave save, {
    DateTime? ceremonyDate,
    String venue = 'Pavillon Gabriel, Paryż',
  }) {
    final riderToTeam = <String, CyclingTeam>{};
    for (final team in save.teams) {
      for (final riderId in team.rosterRiderIds) {
        riderToTeam[riderId] = team;
      }
    }

    final historyEntries = save.calendar.raceHistory.values.toList();
    final riderStatsMap = <String, _MutableCareerRaceAgg>{};
    final teamWinsMap = <String, _MutableTeamRaceAgg>{};

    for (final entry in historyEntries) {
      final race = save.calendar.getRaceById(entry.raceId);
      final riderAgg =
          riderStatsMap.putIfAbsent(entry.winnerRiderId, _MutableCareerRaceAgg.new);
      final teamAgg =
          teamWinsMap.putIfAbsent(entry.winnerTeamId, _MutableTeamRaceAgg.new);

      riderAgg.totalWins++;
      teamAgg.totalWins++;

      if (race != null) {
        switch (race.uciCategory) {
          case RaceCategory.grandTour:
            riderAgg.gtGcWins++;
            teamAgg.gtWins++;
            break;
          case RaceCategory.monument:
            riderAgg.monumentWins++;
            teamAgg.monumentWins++;
            break;
          case RaceCategory.worldTourStageRace:
            riderAgg.wtStageWins++;
            break;
          case RaceCategory.worldTourOneDay:
            riderAgg.wtClassicWins++;
            break;
          case RaceCategory.proSeries:
          case RaceCategory.class1:
            break;
        }
      }

      if (entry.mountainsWinnerRiderName != null) {
        for (final rider in save.riders) {
          if (rider.fullName == entry.mountainsWinnerRiderName) {
            riderStatsMap
                .putIfAbsent(rider.id, _MutableCareerRaceAgg.new)
                .komWins++;
          }
        }
      }
    }

    final riderCandidates = save.riders.map((rider) {
      final team = riderToTeam[rider.id];
      final agg = riderStatsMap[rider.id] ?? _MutableCareerRaceAgg();
      final weight =
          rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 68.0;
      final peakWPerKg = rider.powerProfile.watts20m / weight;

      return VeloDorRiderSeasonStats(
        riderId: rider.id,
        riderName: rider.fullName,
        teamId: team?.id ?? 'free_agent',
        teamName: team?.name ?? 'Wolny Agent',
        nationalityIso: rider.nationalityIso,
        age: rider.age,
        specialization: rider.specialization,
        isPlayerTeam: team?.id == save.playerTeamId,
        uciPointsSeason: rider.careerPointsUci,
        grandTourGcWins: agg.gtGcWins,
        grandTourStageWins: agg.gtGcWins > 0 ? agg.gtGcWins * 2 : 0,
        monumentWins: agg.monumentWins,
        worldTourClassicWins: agg.wtClassicWins,
        worldTourStageRaceWins: agg.wtStageWins,
        komJerseyWins: agg.komWins,
        mountainStageWins:
            rider.specialization == RiderSpecialization.pureClimber ||
                    rider.specialization == RiderSpecialization.gcClimber
                ? agg.gtGcWins + agg.wtStageWins
                : 0,
        peakClimbWPerKg: double.parse(peakWPerKg.toStringAsFixed(2)),
        totalSeasonWins: agg.totalWins,
        overallRating: rider.overallRating,
      );
    }).toList();

    final managerCandidates = save.teams.map((team) {
      final isPlayer = team.id == save.playerTeamId;
      final agg = teamWinsMap[team.id] ?? _MutableTeamRaceAgg();
      final objectivesRatio = team.sponsors.isEmpty
          ? 0.5
          : team.sponsors
                  .expand((s) => s.objectives)
                  .where((o) => o.isCompleted)
                  .length /
              math.max(
                1,
                team.sponsors.expand((s) => s.objectives).length,
              );

      final repBonus = isPlayer ? (save.managerReputation / 100.0) * 15.0 : 0.0;
      final budgetEfficiency =
          (55.0 + (team.uciPointsSeason / 450.0) + repBonus).clamp(35.0, 99.0);

      return VeloDorManagerCandidate(
        managerId: isPlayer ? 'player_manager' : 'ds_${team.id}',
        managerName:
            isPlayer ? save.playerManagerName : 'Dyrektor ${team.name}',
        teamId: team.id,
        teamName: team.name,
        nationalityIso: team.countryIso,
        division: team.division,
        isPlayerTeam: isPlayer,
        teamUciPoints: team.uciPointsSeason,
        totalSeasonWins: agg.totalWins,
        grandTourWins: agg.gtWins,
        monumentWins: agg.monumentWins,
        sponsorObjectivesRatio: objectivesRatio.clamp(0.0, 1.0),
        budgetEfficiencyScore: budgetEfficiency,
        staffSynergyScore: team.staff.averageStaffLevel,
      );
    }).toList();

    return conductCeremony(
      seasonYear: save.currentSeasonYear,
      ceremonyDate: ceremonyDate ??
          (isLateOctoberCeremonyDate(save.currentDate)
              ? save.currentDate
              : defaultCeremonyDate(save.currentSeasonYear)),
      riderCandidates: riderCandidates,
      managerCandidates: managerCandidates,
      venue: venue,
    );
  }

  /// Generuje przykładowy raport gali dla ekranów podglądu lub prezentacji UI.
  static VeloDorCeremonyReport generateSampleCeremonyReport({
    int seasonYear = 2026,
  }) {
    const ceremony = SeasonAwardsVeloDorCeremony();
    final riders = <VeloDorRiderSeasonStats>[
      const VeloDorRiderSeasonStats(
        riderId: 'r_pogacar',
        riderName: 'Tadej Kovačič',
        teamId: 'team_uae',
        teamName: 'Emirates Aero Pro',
        nationalityIso: 'SLO',
        age: 27,
        specialization: RiderSpecialization.gcClimber,
        uciPointsSeason: 6850,
        grandTourGcWins: 2,
        grandTourStageWins: 6,
        monumentWins: 2,
        worldTourStageRaceWins: 2,
        komJerseyWins: 1,
        mountainStageWins: 5,
        peakClimbWPerKg: 6.72,
        worldChampionRoad: true,
        totalSeasonWins: 21,
        overallRating: 97,
      ),
      const VeloDorRiderSeasonStats(
        riderId: 'r_player_leader',
        riderName: 'Michał Kowalski',
        teamId: 'team_player',
        teamName: 'Orzeł WorldTour Team',
        nationalityIso: 'POL',
        age: 25,
        specialization: RiderSpecialization.gcClimber,
        isPlayerTeam: true,
        uciPointsSeason: 4920,
        grandTourGcWins: 1,
        grandTourPodiums: 1,
        grandTourStageWins: 3,
        monumentPodiums: 2,
        worldTourStageRaceWins: 2,
        komJerseyWins: 1,
        mountainStageWins: 4,
        peakClimbWPerKg: 6.48,
        totalSeasonWins: 12,
        overallRating: 92,
      ),
      const VeloDorRiderSeasonStats(
        riderId: 'r_vinge',
        riderName: 'Jonas Lindholm',
        teamId: 'team_visma',
        teamName: 'Nordic Lease Lab',
        nationalityIso: 'DEN',
        age: 29,
        specialization: RiderSpecialization.pureClimber,
        uciPointsSeason: 4410,
        grandTourPodiums: 2,
        grandTourStageWins: 3,
        komJerseyWins: 2,
        mountainStageWins: 6,
        peakClimbWPerKg: 6.61,
        totalSeasonWins: 10,
        overallRating: 94,
      ),
      const VeloDorRiderSeasonStats(
        riderId: 'r_mvdp',
        riderName: 'Mathieu Van Der Berg',
        teamId: 'team_alpecin',
        teamName: 'Flanders Fenix Pro',
        nationalityIso: 'NED',
        age: 31,
        specialization: RiderSpecialization.classicCobbles,
        uciPointsSeason: 5120,
        monumentWins: 2,
        monumentPodiums: 1,
        worldTourClassicWins: 3,
        totalSeasonWins: 11,
        overallRating: 94,
      ),
      const VeloDorRiderSeasonStats(
        riderId: 'r_u23_star',
        riderName: 'Jakub Zieliński',
        teamId: 'team_player',
        teamName: 'Orzeł WorldTour Team',
        nationalityIso: 'POL',
        age: 21,
        specialization: RiderSpecialization.puncher,
        isPlayerTeam: true,
        uciPointsSeason: 2380,
        grandTourStageWins: 1,
        worldTourClassicWins: 1,
        worldTourStageRaceWins: 1,
        mountainStageWins: 1,
        peakClimbWPerKg: 6.18,
        totalSeasonWins: 7,
        overallRating: 85,
      ),
      const VeloDorRiderSeasonStats(
        riderId: 'r_u23_rival',
        riderName: 'Lucas Moreau',
        teamId: 'team_fdj',
        teamName: 'Hexagone Equipe',
        nationalityIso: 'FRA',
        age: 22,
        specialization: RiderSpecialization.pureClimber,
        uciPointsSeason: 1840,
        komJerseyWins: 1,
        mountainStageWins: 2,
        peakClimbWPerKg: 6.05,
        totalSeasonWins: 4,
        overallRating: 82,
      ),
    ];

    final managers = <VeloDorManagerCandidate>[
      const VeloDorManagerCandidate(
        managerId: 'mgr_player',
        managerName: 'Ty (Dyrektor Sportowy)',
        teamId: 'team_player',
        teamName: 'Orzeł WorldTour Team',
        nationalityIso: 'POL',
        division: TeamDivision.worldTour,
        isPlayerTeam: true,
        teamUciPoints: 14850,
        totalSeasonWins: 34,
        grandTourWins: 1,
        monumentWins: 1,
        sponsorObjectivesRatio: 0.95,
        budgetEfficiencyScore: 91.0,
        staffSynergyScore: 88.0,
      ),
      const VeloDorManagerCandidate(
        managerId: 'mgr_uae',
        managerName: 'Matteo Gianetti',
        teamId: 'team_uae',
        teamName: 'Emirates Aero Pro',
        nationalityIso: 'SUI',
        division: TeamDivision.worldTour,
        teamUciPoints: 16200,
        totalSeasonWins: 41,
        grandTourWins: 2,
        monumentWins: 2,
        sponsorObjectivesRatio: 0.85,
        budgetEfficiencyScore: 76.0,
        staffSynergyScore: 90.0,
      ),
      const VeloDorManagerCandidate(
        managerId: 'mgr_visma',
        managerName: 'Richard Plugge',
        teamId: 'team_visma',
        teamName: 'Nordic Lease Lab',
        nationalityIso: 'NED',
        division: TeamDivision.worldTour,
        teamUciPoints: 13400,
        totalSeasonWins: 28,
        grandTourWins: 0,
        monumentWins: 1,
        sponsorObjectivesRatio: 0.78,
        budgetEfficiencyScore: 82.0,
        staffSynergyScore: 86.0,
      ),
    ];

    return ceremony.conductCeremony(
      seasonYear: seasonYear,
      riderCandidates: riders,
      managerCandidates: managers,
    );
  }

  VeloDorCategoryResult _evaluateRiderCategory({
    required VeloDorAwardCategory category,
    required int seasonYear,
    required List<VeloDorRiderSeasonStats> candidates,
    required _RawScoreComponents Function(VeloDorRiderSeasonStats) scorer,
    required List<String> Function(VeloDorRiderSeasonStats) highlightsBuilder,
  }) {
    if (candidates.isEmpty) {
      return VeloDorCategoryResult(
        category: category,
        winner: null,
        podiumFinalists: const [],
        totalCandidatesEvaluated: 0,
        ceremonyCitation:
            'Brak kwalifikujących się kandydatów w sezonie $seasonYear.',
      );
    }

    final scored = candidates.map((c) {
      final raw = scorer(c);
      return _ScoredRiderEntry(candidate: c, raw: raw);
    }).toList()
      ..sort((a, b) {
        final cmp = b.raw.total.compareTo(a.raw.total);
        if (cmp != 0) return cmp;
        return b.candidate.uciPointsSeason.compareTo(a.candidate.uciPointsSeason);
      });

    final topPool = scored.take(5).toList();
    final topSum = topPool.fold<double>(0.0, (acc, e) => acc + math.max(1.0, e.raw.total));

    final finalists = <VeloDorNomineeResult>[];
    for (var i = 0; i < math.min(3, scored.length); i++) {
      final entry = scored[i];
      final rank = i + 1;
      final share = topSum > 0
          ? (math.max(1.0, entry.raw.total) / topSum * 100.0)
          : 0.0;

      final statuette = rank == 1
          ? VeloDorStatuetteSpec(
              category: category,
              trophyName: category.trophyTitle,
              materialFinish: category == VeloDorAwardCategory.worldBestRider
                  ? '24-karatowe złoto na podstawie z czarnego marmuru'
                  : 'Pozłacany brąz & kryształ optyczny',
              engravingLine:
                  '${entry.candidate.riderName.toUpperCase()} • ${category.shortLabel.toUpperCase()} $seasonYear',
              seasonYear: seasonYear,
            )
          : null;

      finalists.add(
        VeloDorNomineeResult(
          rank: rank,
          candidateId: entry.candidate.riderId,
          candidateName: entry.candidate.riderName,
          teamId: entry.candidate.teamId,
          teamName: entry.candidate.teamName,
          nationalityIso: entry.candidate.nationalityIso,
          isPlayerTeam: entry.candidate.isPlayerTeam,
          roleOrSpecialty: entry.candidate.specialization.displayName,
          voteBreakdown: VeloDorJuryVoteBreakdown(
            sportingResultsScore: entry.raw.sporting,
            prestigeMultiplierScore: entry.raw.prestige,
            journalistPanelVotes: entry.raw.journalists,
            peerDirectorsVotes: entry.raw.peers,
            totalScore: double.parse(entry.raw.total.toStringAsFixed(1)),
            voteSharePercent: double.parse(share.toStringAsFixed(1)),
          ),
          seasonHighlights: highlightsBuilder(entry.candidate),
          statuetteSpec: statuette,
        ),
      );
    }

    final winner = finalists.first;
    final citation =
        'Laureatem nagrody ${category.displayName} za sezon $seasonYear zostaje '
        '${winner.candidateName} (${winner.teamName}) z wynikiem '
        '${winner.voteBreakdown.voteSharePercent.toStringAsFixed(1)}% głosów jury.';

    return VeloDorCategoryResult(
      category: category,
      winner: winner,
      podiumFinalists: finalists,
      totalCandidatesEvaluated: candidates.length,
      ceremonyCitation: citation,
    );
  }

  VeloDorCategoryResult _evaluateManagerCategory({
    required int seasonYear,
    required List<VeloDorManagerCandidate> candidates,
  }) {
    if (candidates.isEmpty) {
      return VeloDorCategoryResult(
        category: VeloDorAwardCategory.managerOfTheYear,
        winner: null,
        podiumFinalists: const [],
        totalCandidatesEvaluated: 0,
        ceremonyCitation:
            'Brak kwalifikujących się dyrektorów sportowych w sezonie $seasonYear.',
      );
    }

    final scored = candidates.map((m) {
      final sporting = m.teamUciPoints * 0.04 +
          m.totalSeasonWins * 12.0 +
          m.grandTourWins * 180.0 +
          m.monumentWins * 110.0;
      final prestige = m.sponsorObjectivesRatio * 220.0 +
          m.budgetEfficiencyScore * 2.4 +
          m.staffSynergyScore * 1.3;
      final journalists = (sporting * 0.32 + prestige * 0.48);
      final peers = (m.budgetEfficiencyScore * 1.8 + m.totalSeasonWins * 5.5);
      return _ScoredManagerEntry(
        candidate: m,
        raw: _RawScoreComponents(
          sporting: sporting,
          prestige: prestige,
          journalists: journalists,
          peers: peers,
        ),
      );
    }).toList()
      ..sort((a, b) => b.raw.total.compareTo(a.raw.total));

    final topPool = scored.take(5).toList();
    final topSum = topPool.fold<double>(0.0, (acc, e) => acc + math.max(1.0, e.raw.total));

    final finalists = <VeloDorNomineeResult>[];
    for (var i = 0; i < math.min(3, scored.length); i++) {
      final entry = scored[i];
      final m = entry.candidate;
      final rank = i + 1;
      final share = topSum > 0
          ? (math.max(1.0, entry.raw.total) / topSum * 100.0)
          : 0.0;

      final highlights = <String>[
        '${m.totalSeasonWins} zwycięstw drużynowych (${m.teamUciPoints} pkt UCI)',
        if (m.grandTourWins > 0) '${m.grandTourWins}× Triumf w Wielkim Tourze',
        if (m.monumentWins > 0) '${m.monumentWins}× Wygrany Monument',
        'Realizacja celów sponsora: ${(m.sponsorObjectivesRatio * 100).round()}%',
      ];

      finalists.add(
        VeloDorNomineeResult(
          rank: rank,
          candidateId: m.managerId,
          candidateName: m.managerName,
          teamId: m.teamId,
          teamName: m.teamName,
          nationalityIso: m.nationalityIso,
          isPlayerTeam: m.isPlayerTeam,
          roleOrSpecialty: m.division.label,
          voteBreakdown: VeloDorJuryVoteBreakdown(
            sportingResultsScore: entry.raw.sporting,
            prestigeMultiplierScore: entry.raw.prestige,
            journalistPanelVotes: entry.raw.journalists,
            peerDirectorsVotes: entry.raw.peers,
            totalScore: double.parse(entry.raw.total.toStringAsFixed(1)),
            voteSharePercent: double.parse(share.toStringAsFixed(1)),
          ),
          seasonHighlights: highlights,
          statuetteSpec: rank == 1
              ? VeloDorStatuetteSpec(
                  category: VeloDorAwardCategory.managerOfTheYear,
                  trophyName: VeloDorAwardCategory.managerOfTheYear.trophyTitle,
                  materialFinish: 'Złoto szczotkowane & burgundowy kryształ',
                  engravingLine:
                      '${m.managerName.toUpperCase()} • ${m.teamName.toUpperCase()} $seasonYear',
                  seasonYear: seasonYear,
                )
              : null,
        ),
      );
    }

    final winner = finalists.first;
    return VeloDorCategoryResult(
      category: VeloDorAwardCategory.managerOfTheYear,
      winner: winner,
      podiumFinalists: finalists,
      totalCandidatesEvaluated: candidates.length,
      ceremonyCitation:
          'Statuetkę Menedżera Roku $seasonYear odbiera ${winner.candidateName} '
          '(${winner.teamName}) za wzorowe zarządzanie i wyniki zespołu.',
    );
  }

  _RawScoreComponents _scoreWorldBestRider(VeloDorRiderSeasonStats r) {
    final sporting = r.uciPointsSeason * 0.12 +
        r.grandTourGcWins * 520.0 +
        r.grandTourPodiums * 180.0 +
        r.grandTourStageWins * 55.0 +
        r.monumentWins * 280.0 +
        r.worldTourStageRaceWins * 130.0 +
        r.totalSeasonWins * 24.0;
    final prestige = (r.worldChampionRoad ? 340.0 : 0.0) +
        (r.worldChampionTt ? 180.0 : 0.0) +
        (r.olympicGold ? 290.0 : 0.0) +
        r.overallRating * 3.5;
    final journalists = sporting * 0.35 + prestige * 0.50;
    final peers = r.uciPointsSeason * 0.05 + r.overallRating * 2.5;
    return _RawScoreComponents(
      sporting: sporting,
      prestige: prestige,
      journalists: journalists,
      peers: peers,
    );
  }

  _RawScoreComponents _scoreBestClimber(VeloDorRiderSeasonStats r) {
    final specBonus = (r.specialization == RiderSpecialization.pureClimber ||
            r.specialization == RiderSpecialization.gcClimber)
        ? 180.0
        : 0.0;
    final sporting = r.komJerseyWins * 340.0 +
        r.mountainStageWins * 165.0 +
        r.grandTourGcWins * 260.0 +
        r.grandTourPodiums * 110.0 +
        r.uciPointsSeason * 0.05;
    final prestige =
        specBonus + (r.peakClimbWPerKg * 55.0) + r.overallRating * 1.5;
    final journalists = sporting * 0.40 + prestige * 0.40;
    final peers = r.peakClimbWPerKg * 30.0 + r.mountainStageWins * 45.0;
    return _RawScoreComponents(
      sporting: sporting,
      prestige: prestige,
      journalists: journalists,
      peers: peers,
    );
  }

  _RawScoreComponents _scoreBestClassicsRider(VeloDorRiderSeasonStats r) {
    final specBonus =
        (r.specialization == RiderSpecialization.classicCobbles ||
                r.specialization == RiderSpecialization.puncher)
            ? 190.0
            : 0.0;
    final sporting = r.monumentWins * 480.0 +
        r.monumentPodiums * 190.0 +
        r.worldTourClassicWins * 185.0 +
        r.uciPointsSeason * 0.06;
    final prestige = specBonus +
        (r.worldChampionRoad ? 240.0 : 0.0) +
        r.overallRating * 1.8;
    final journalists = sporting * 0.45 + prestige * 0.35;
    final peers = r.monumentWins * 120.0 + r.worldTourClassicWins * 50.0;
    return _RawScoreComponents(
      sporting: sporting,
      prestige: prestige,
      journalists: journalists,
      peers: peers,
    );
  }

  _RawScoreComponents _scoreU23Breakthrough(VeloDorRiderSeasonStats r) {
    final youthBonus = math.max(0, 24 - r.age) * 35.0;
    final sporting = r.uciPointsSeason * 0.14 +
        r.totalSeasonWins * 48.0 +
        r.grandTourGcWins * 360.0 +
        r.grandTourStageWins * 110.0 +
        r.monumentWins * 240.0 +
        r.worldTourStageRaceWins * 120.0;
    final prestige = youthBonus + r.overallRating * 3.0;
    final journalists = sporting * 0.40 + prestige * 0.40;
    final peers = r.totalSeasonWins * 22.0 + youthBonus;
    return _RawScoreComponents(
      sporting: sporting,
      prestige: prestige,
      journalists: journalists,
      peers: peers,
    );
  }

  List<String> _buildWorldBestHighlights(VeloDorRiderSeasonStats r) => [
        if (r.grandTourGcWins > 0) '${r.grandTourGcWins}× Zwycięstwo GC Grand Tour',
        if (r.monumentWins > 0) '${r.monumentWins}× Triumf w Monumencie',
        if (r.worldChampionRoad) 'Tęczowa Koszulka Mistrza Świata',
        if (r.olympicGold) 'Złoty Medal Olimpijski',
        '${r.totalSeasonWins} zwycięstw • ${r.uciPointsSeason} pkt UCI',
      ];

  List<String> _buildClimberHighlights(VeloDorRiderSeasonStats r) => [
        if (r.komJerseyWins > 0) '${r.komJerseyWins}× Koszulka Górska (KOM)',
        if (r.mountainStageWins > 0) '${r.mountainStageWins}× Wygrany etap górski',
        'Szczytowe tempo wspinaczki: ${r.peakClimbWPerKg.toStringAsFixed(2)} W/kg',
        if (r.grandTourGcWins > 0) '${r.grandTourGcWins}× Klasyfikacja Generalna GT',
      ];

  List<String> _buildClassicsHighlights(VeloDorRiderSeasonStats r) => [
        if (r.monumentWins > 0) '${r.monumentWins}× Zwycięstwo w Monumencie',
        if (r.monumentPodiums > 0) '${r.monumentPodiums}× Podium Monumentu',
        if (r.worldTourClassicWins > 0)
          '${r.worldTourClassicWins}× Klasyk WorldTour',
        if (r.worldChampionRoad) 'Mistrz Świata ze startu wspólnego',
      ];

  List<String> _buildU23Highlights(VeloDorRiderSeasonStats r) => [
        'Wiek: ${r.age} lat • OVR ${r.overallRating}',
        '${r.totalSeasonWins} zwycięstw w sezonie (${r.uciPointsSeason} pkt UCI)',
        if (r.grandTourStageWins > 0)
          '${r.grandTourStageWins}× Etap Grand Touru',
        if (r.worldTourClassicWins > 0)
          '${r.worldTourClassicWins}× Wygrany klasyk WorldTour',
      ];
}

class _RawScoreComponents {
  final double sporting;
  final double prestige;
  final double journalists;
  final double peers;

  const _RawScoreComponents({
    required this.sporting,
    required this.prestige,
    required this.journalists,
    required this.peers,
  });

  double get total => sporting + prestige + journalists + peers;
}

class _ScoredRiderEntry {
  final VeloDorRiderSeasonStats candidate;
  final _RawScoreComponents raw;

  const _ScoredRiderEntry({required this.candidate, required this.raw});
}

class _ScoredManagerEntry {
  final VeloDorManagerCandidate candidate;
  final _RawScoreComponents raw;

  const _ScoredManagerEntry({required this.candidate, required this.raw});
}

class _MutableCareerRaceAgg {
  int totalWins = 0;
  int gtGcWins = 0;
  int monumentWins = 0;
  int wtStageWins = 0;
  int wtClassicWins = 0;
  int komWins = 0;
}

class _MutableTeamRaceAgg {
  int totalWins = 0;
  int gtWins = 0;
  int monumentWins = 0;
}

/// Wektorowy painter złotej statuetki Vélo d'Or (Złoty Rower) na postumencie.
class VeloDorStatuettePainter extends CustomPainter {
  final double shimmerProgress;
  final VeloDorAwardCategory category;

  const VeloDorStatuettePainter({
    required this.shimmerProgress,
    required this.category,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blask sceniczny za statuetką
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.28 + 0.1 * shimmerProgress),
          AppColors.primaryAccent.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.42),
        radius: math.min(w, h) * 0.48,
      ));
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.42),
      math.min(w, h) * 0.48,
      haloPaint,
    );

    // Postument z czarnego marmuru i złotej tabliczki
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.74, w * 0.56, h * 0.18),
      const Radius.circular(6),
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF232732), Color(0xFF0B0D11)],
      ).createShader(baseRect.outerRect);
    canvas.drawRRect(baseRect, basePaint);

    final baseBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.goldAccent.withValues(alpha: 0.75);
    canvas.drawRRect(baseRect, baseBorder);

    // Złota tabliczka na postumencie
    final plaqueRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.79, w * 0.40, h * 0.08),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      plaqueRect,
      Paint()..color = AppColors.goldAccent.withValues(alpha: 0.9),
    );

    // Złoty rower (statuetka)
    final goldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.2, w * 0.032)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment(-1 + shimmerProgress * 2, -1),
        end: Alignment(1 + shimmerProgress * 2, 1),
        colors: const [
          Color(0xFFB38728),
          Color(0xFFFBF5B7),
          Color(0xFFD4AF37),
          Color(0xFFAA771C),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rearWheel = Offset(w * 0.32, h * 0.56);
    final frontWheel = Offset(w * 0.68, h * 0.56);
    final wheelRadius = math.min(w, h) * 0.145;

    canvas.drawCircle(rearWheel, wheelRadius, goldStroke);
    canvas.drawCircle(frontWheel, wheelRadius, goldStroke);

    final bb = Offset(w * 0.48, h * 0.56);
    final seatTop = Offset(w * 0.43, h * 0.35);
    final headTop = Offset(w * 0.61, h * 0.35);
    final handlebar = Offset(w * 0.67, h * 0.31);

    final framePath = Path()
      ..moveTo(rearWheel.dx, rearWheel.dy)
      ..lineTo(bb.dx, bb.dy)
      ..lineTo(seatTop.dx, seatTop.dy)
      ..close()
      ..moveTo(bb.dx, bb.dy)
      ..lineTo(headTop.dx, headTop.dy)
      ..lineTo(seatTop.dx, seatTop.dy)
      ..moveTo(frontWheel.dx, frontWheel.dy)
      ..lineTo(headTop.dx, headTop.dy)
      ..lineTo(handlebar.dx, handlebar.dy);

    canvas.drawPath(framePath, goldStroke);

    // Akcent kategorii na szczycie (np. gwiazdka/szczyt/bruki)
    final accentPaint = Paint()
      ..color = category == VeloDorAwardCategory.bestClimber
          ? AppColors.crimsonAlert
          : AppColors.goldAccent;
    canvas.drawCircle(Offset(w * 0.50, h * 0.21), w * 0.032, accentPaint);
  }

  @override
  bool shouldRepaint(covariant VeloDorStatuettePainter oldDelegate) {
    return oldDelegate.shimmerProgress != shimmerProgress ||
        oldDelegate.category != category;
  }
}

/// Interaktywny panel gali wręczenia statuetek Vélo d'Or (Złoty Rower).
class VeloDorCeremonyGalaWidget extends StatefulWidget {
  final VeloDorCeremonyReport report;
  final VeloDorAwardCategory initialCategory;
  final ValueChanged<VeloDorCategoryResult>? onPresentStatuette;

  const VeloDorCeremonyGalaWidget({
    super.key,
    required this.report,
    this.initialCategory = VeloDorAwardCategory.worldBestRider,
    this.onPresentStatuette,
  });

  @override
  State<VeloDorCeremonyGalaWidget> createState() =>
      _VeloDorCeremonyGalaWidgetState();
}

class _VeloDorCeremonyGalaWidgetState extends State<VeloDorCeremonyGalaWidget>
    with SingleTickerProviderStateMixin {
  late VeloDorAwardCategory _selectedCategory;
  late final AnimationController _shimmerController;
  final Set<VeloDorAwardCategory> _presentedCategories =
      <VeloDorAwardCategory>{};
  VeloDorAwardCategory? _hoveredCategory;
  bool _presentButtonHovered = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeResult = widget.report.resultFor(_selectedCategory);
    final isPresented = _presentedCategories.contains(_selectedCategory);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final isDesktopWide = constraints.maxWidth >= 1000;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              _buildCategorySelector(isCompact),
              const SizedBox(height: 18),
              if (activeResult == null || activeResult.winner == null)
                _buildEmptyState()
              else if (isDesktopWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildStatuetteShowcase(
                        activeResult,
                        isPresented,
                        isCompact,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 6,
                      child: _buildPodiumList(activeResult, isCompact),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatuetteShowcase(
                      activeResult,
                      isPresented,
                      isCompact,
                    ),
                    const SizedBox(height: 16),
                    _buildPodiumList(activeResult, isCompact),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "GALA VÉLO D'OR ${widget.report.seasonYear}",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 16 : 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldAccent,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.report.venue} • '
              '${widget.report.ceremonyDate.day}.${widget.report.ceremonyDate.month}.${widget.report.ceremonyDate.year}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.report.playerTeamAwardsWon > 0
                  ? AppColors.goldAccent.withValues(alpha: 0.65)
                  : AppTheme.borderColor,
            ),
          ),
          child: Text(
            'Nagrody drużyny: ${widget.report.playerTeamAwardsWon} • '
            '+${widget.report.playerTeamPrestigeGain} Prestiżu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.report.playerTeamAwardsWon > 0
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: VeloDorAwardCategory.values.map((category) {
        final isSelected = category == _selectedCategory;
        final isHovered = category == _hoveredCategory;
        final isPresented = _presentedCategories.contains(category);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredCategory = category),
          onExit: (_) => setState(() => _hoveredCategory = null),
          child: FocusableActionDetector(
            onShowFocusHighlight: (focused) {
              if (focused) setState(() => _hoveredCategory = category);
            },
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAccent.withValues(alpha: 0.25)
                      : isHovered
                          ? AppColors.surfaceLight
                          : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.goldAccent
                        : isHovered
                            ? AppColors.goldAccent.withValues(alpha: 0.45)
                            : AppTheme.borderColor,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresented
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_rounded,
                      size: 15,
                      color: isSelected || isPresented
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.shortLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
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
      }).toList(),
    );
  }

  Widget _buildStatuetteShowcase(
    VeloDorCategoryResult result,
    bool isPresented,
    bool isCompact,
  ) {
    final winner = result.winner!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            result.category.frenchSubtitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: isCompact ? 130 : 165,
            width: isCompact ? 160 : 210,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                return CustomPaint(
                  painter: VeloDorStatuettePainter(
                    shimmerProgress: _shimmerController.value,
                    category: result.category,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            winner.candidateName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 18 : 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${winner.teamName} • ${winner.nationalityIso}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: winner.isPlayerTeam
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (winner.statuetteSpec != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                winner.statuetteSpec!.engravingLine,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          const SizedBox(height: 14),
          MouseRegion(
            cursor: isPresented
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _presentButtonHovered = true),
            onExit: (_) => setState(() => _presentButtonHovered = false),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isPresented
                    ? null
                    : () {
                        setState(() {
                          _presentedCategories.add(result.category);
                        });
                        widget.onPresentStatuette?.call(result);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPresented
                      ? AppColors.surfaceLight
                      : _presentButtonHovered
                          ? AppColors.goldAccent.withValues(alpha: 0.9)
                          : AppColors.goldAccent,
                  foregroundColor: isPresented
                      ? AppColors.textSecondary
                      : Colors.black,
                  disabledBackgroundColor: AppColors.surfaceLight,
                  disabledForegroundColor: AppColors.statusSuccess,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isPresented
                      ? Icons.check_circle_rounded
                      : Icons.emoji_events_rounded,
                  size: 18,
                ),
                label: Text(
                  isPresented ? 'Statuetka Wręczona' : 'Wręcz Statuetkę',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumList(VeloDorCategoryResult result, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Wyniki Głosowania Jury (${result.totalCandidatesEvaluated} nominowanych)',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          result.ceremonyCitation,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...result.podiumFinalists.map(
          (nominee) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildNomineeRow(nominee, isCompact),
          ),
        ),
      ],
    );
  }

  Widget _buildNomineeRow(VeloDorNomineeResult nominee, bool isCompact) {
    final isFirst = nominee.rank == 1;
    final voteShare = nominee.voteBreakdown.voteSharePercent.clamp(0.0, 100.0);

    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: isFirst
            ? AppColors.goldAccent.withValues(alpha: 0.08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst
              ? AppColors.goldAccent.withValues(alpha: 0.65)
              : nominee.isPlayerTeam
                  ? AppColors.primaryAccent
                  : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isFirst ? AppColors.goldAccent : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${nominee.rank}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isFirst ? Colors.black : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nominee.candidateName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${nominee.teamName} • ${nominee.roleOrSpecialty}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${voteShare.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isFirst ? AppColors.goldAccent : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: voteShare / 100.0,
              minHeight: 5,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFirst ? AppColors.goldAccent : AppColors.accentBlue,
              ),
            ),
          ),
          if (nominee.seasonHighlights.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: nominee.seasonHighlights.take(3).map((h) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Center(
        child: Text(
          'Brak nominowanych kandydatów w wybranej kategorii.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
