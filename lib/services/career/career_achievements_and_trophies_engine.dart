import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Ranga osiągnięcia w systemie 60 Osiągnięć Menedżerskich i Kolarskich.
enum CareerAchievementTier {
  bronze,
  silver,
  gold,
  legendary;

  String toJson() => name;

  static CareerAchievementTier fromJson(String? value) {
    if (value == null) return CareerAchievementTier.bronze;
    return CareerAchievementTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CareerAchievementTier.bronze,
    );
  }

  String get labelPl {
    switch (this) {
      case CareerAchievementTier.bronze:
        return 'Brązowe';
      case CareerAchievementTier.silver:
        return 'Srebrne';
      case CareerAchievementTier.gold:
        return 'Złote';
      case CareerAchievementTier.legendary:
        return 'Legendarne';
    }
  }

  int get points {
    switch (this) {
      case CareerAchievementTier.bronze:
        return 15;
      case CareerAchievementTier.silver:
        return 30;
      case CareerAchievementTier.gold:
        return 60;
      case CareerAchievementTier.legendary:
        return 120;
    }
  }

  Color get color {
    switch (this) {
      case CareerAchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case CareerAchievementTier.silver:
        return const Color(0xFFC0C7D1);
      case CareerAchievementTier.gold:
        return AppColors.goldAccent;
      case CareerAchievementTier.legendary:
        return AppColors.cyanAccent;
    }
  }

  IconData get icon {
    switch (this) {
      case CareerAchievementTier.bronze:
        return Icons.workspace_premium_outlined;
      case CareerAchievementTier.silver:
        return Icons.workspace_premium_rounded;
      case CareerAchievementTier.gold:
        return Icons.emoji_events_rounded;
      case CareerAchievementTier.legendary:
        return Icons.auto_awesome_rounded;
    }
  }
}

/// Kategoria tematyczna osiągnięcia (6 kategorii x 10 osiągnięć = 60).
enum CareerAchievementCategory {
  grandToursAndStageRaces,
  monumentsAndClassics,
  tacticsAndRacecraft,
  managementAndFinance,
  equipmentAndPhysiology,
  beAProAndSpecialDisciplines;

  String toJson() => name;

  static CareerAchievementCategory fromJson(String? value) {
    if (value == null) return CareerAchievementCategory.grandToursAndStageRaces;
    return CareerAchievementCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CareerAchievementCategory.grandToursAndStageRaces,
    );
  }

  String get labelPl {
    switch (this) {
      case CareerAchievementCategory.grandToursAndStageRaces:
        return 'Wielkie Toury';
      case CareerAchievementCategory.monumentsAndClassics:
        return 'Monumenty i Klasyki';
      case CareerAchievementCategory.tacticsAndRacecraft:
        return 'Taktyka i Wyścig';
      case CareerAchievementCategory.managementAndFinance:
        return 'Zarządzanie i Finanse';
      case CareerAchievementCategory.equipmentAndPhysiology:
        return 'Sprzęt i Fizjologia';
      case CareerAchievementCategory.beAProAndSpecialDisciplines:
        return 'Be a Pro i Dyscypliny';
    }
  }

  IconData get icon {
    switch (this) {
      case CareerAchievementCategory.grandToursAndStageRaces:
        return Icons.terrain_rounded;
      case CareerAchievementCategory.monumentsAndClassics:
        return Icons.emoji_flags_rounded;
      case CareerAchievementCategory.tacticsAndRacecraft:
        return Icons.bolt_rounded;
      case CareerAchievementCategory.managementAndFinance:
        return Icons.account_balance_rounded;
      case CareerAchievementCategory.equipmentAndPhysiology:
        return Icons.science_rounded;
      case CareerAchievementCategory.beAProAndSpecialDisciplines:
        return Icons.stars_rounded;
    }
  }
}

/// Tryb filtrowania listy osiągnięć.
enum CareerAchievementFilterMode {
  all,
  unlocked,
  locked,
  inProgress,
  secret,
}

/// Typ wyścigu przekazywany w kontekście ewaluacji.
enum AchievementRaceTier {
  other,
  proSeries,
  worldTourClassic,
  worldTourStageRace,
  monument,
  grandTour,
  worldChampionships,
  olympicGames,
  cyclocrossWorldCup,
  gravelWorldSeries,
  velodromeHourRecord,
}

/// Definicja pojedynczego osiągnięcia z katalogu 60 wyzwań.
@immutable
class CareerAchievementDefinition {
  final String id;
  final int codeNumber;
  final String title;
  final String description;
  final CareerAchievementTier tier;
  final CareerAchievementCategory category;
  final IconData icon;
  final double targetValue;
  final bool isSecret;
  final String trophyLabel;

  const CareerAchievementDefinition({
    required this.id,
    required this.codeNumber,
    required this.title,
    required this.description,
    required this.tier,
    required this.category,
    required this.icon,
    this.targetValue = 1.0,
    this.isSecret = false,
    this.trophyLabel = '',
  });

  int get points => tier.points;
}

/// Postęp pojedynczego osiągnięcia w stanie kariery.
@immutable
class CareerAchievementProgress {
  final String achievementId;
  final double currentValue;
  final double targetValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int? unlockedSeasonYear;
  final String? unlockedRaceName;
  final String? unlockedByRiderName;
  final String? contextNote;
  final int timesTriggered;

  const CareerAchievementProgress({
    required this.achievementId,
    required this.currentValue,
    required this.targetValue,
    required this.isUnlocked,
    this.unlockedAt,
    this.unlockedSeasonYear,
    this.unlockedRaceName,
    this.unlockedByRiderName,
    this.contextNote,
    this.timesTriggered = 0,
  });

  double get progressRatio {
    if (isUnlocked) return 1.0;
    if (targetValue <= 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  bool get isInProgress => !isUnlocked && currentValue > 0;

  CareerAchievementProgress copyWith({
    double? currentValue,
    double? targetValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? unlockedSeasonYear,
    String? unlockedRaceName,
    String? unlockedByRiderName,
    String? contextNote,
    int? timesTriggered,
  }) {
    return CareerAchievementProgress(
      achievementId: achievementId,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockedSeasonYear: unlockedSeasonYear ?? this.unlockedSeasonYear,
      unlockedRaceName: unlockedRaceName ?? this.unlockedRaceName,
      unlockedByRiderName: unlockedByRiderName ?? this.unlockedByRiderName,
      contextNote: contextNote ?? this.contextNote,
      timesTriggered: timesTriggered ?? this.timesTriggered,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'unlockedSeasonYear': unlockedSeasonYear,
      'unlockedRaceName': unlockedRaceName,
      'unlockedByRiderName': unlockedByRiderName,
      'contextNote': contextNote,
      'timesTriggered': timesTriggered,
    };
  }

  factory CareerAchievementProgress.fromJson(Map<String, dynamic> json) {
    final unlockedAtRaw = json['unlockedAt'] as String?;
    return CareerAchievementProgress(
      achievementId: (json['achievementId'] as String?) ?? '',
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
      isUnlocked: (json['isUnlocked'] as bool?) ?? false,
      unlockedAt:
          unlockedAtRaw != null ? DateTime.tryParse(unlockedAtRaw) : null,
      unlockedSeasonYear: (json['unlockedSeasonYear'] as num?)?.toInt(),
      unlockedRaceName: json['unlockedRaceName'] as String?,
      unlockedByRiderName: json['unlockedByRiderName'] as String?,
      contextNote: json['contextNote'] as String?,
      timesTriggered: (json['timesTriggered'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Zdarzenie odblokowania osiągnięcia lub Platynowego Trofeum.
@immutable
class CareerTrophyUnlockEvent {
  final String achievementId;
  final String title;
  final String description;
  final CareerAchievementTier tier;
  final CareerAchievementCategory category;
  final int pointsAwarded;
  final bool isPlatinumTrophy;
  final DateTime unlockedAt;
  final int? seasonYear;
  final String? contextNote;

  const CareerTrophyUnlockEvent({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.tier,
    required this.category,
    required this.pointsAwarded,
    required this.isPlatinumTrophy,
    required this.unlockedAt,
    this.seasonYear,
    this.contextNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'title': title,
      'description': description,
      'tier': tier.toJson(),
      'category': category.toJson(),
      'pointsAwarded': pointsAwarded,
      'isPlatinumTrophy': isPlatinumTrophy,
      'unlockedAt': unlockedAt.toIso8601String(),
      'seasonYear': seasonYear,
      'contextNote': contextNote,
    };
  }

  factory CareerTrophyUnlockEvent.fromJson(Map<String, dynamic> json) {
    return CareerTrophyUnlockEvent(
      achievementId: (json['achievementId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      tier: CareerAchievementTier.fromJson(json['tier'] as String?),
      category: CareerAchievementCategory.fromJson(json['category'] as String?),
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt() ?? 0,
      isPlatinumTrophy: (json['isPlatinumTrophy'] as bool?) ?? false,
      unlockedAt: DateTime.tryParse((json['unlockedAt'] as String?) ?? '') ??
          DateTime.now(),
      seasonYear: (json['seasonYear'] as num?)?.toInt(),
      contextNote: json['contextNote'] as String?,
    );
  }
}

/// Status Platynowego Trofeum za ukończenie wszystkich 60 osiągnięć.
@immutable
class PlatinumTrophyRecord {
  static const String platinumId = 'platinum_cycling_immortal';
  static const String platinumTitle = 'Bóg Kolarstwa — Platynowe Trofeum';
  static const String platinumDescription =
      'Odblokowano wszystkie 60 Osiągnięć Menedżerskich i Kolarskich w Pro Peloton Manager.';
  static const int platinumBonusPoints = 500;

  final bool isUnlocked;
  final int unlockedCount;
  final int requiredCount;
  final int totalPointsEarned;
  final int maxPossiblePoints;
  final DateTime? unlockedAt;
  final int? unlockedSeasonYear;

  const PlatinumTrophyRecord({
    required this.isUnlocked,
    required this.unlockedCount,
    required this.requiredCount,
    required this.totalPointsEarned,
    required this.maxPossiblePoints,
    this.unlockedAt,
    this.unlockedSeasonYear,
  });

  double get progressRatio {
    if (requiredCount <= 0) return 0.0;
    return (unlockedCount / requiredCount).clamp(0.0, 1.0);
  }

  int get completionPercent => (progressRatio * 100).round();

  Map<String, dynamic> toJson() {
    return {
      'isUnlocked': isUnlocked,
      'unlockedCount': unlockedCount,
      'requiredCount': requiredCount,
      'totalPointsEarned': totalPointsEarned,
      'maxPossiblePoints': maxPossiblePoints,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'unlockedSeasonYear': unlockedSeasonYear,
    };
  }

  factory PlatinumTrophyRecord.fromJson(Map<String, dynamic> json) {
    final unlockedAtRaw = json['unlockedAt'] as String?;
    return PlatinumTrophyRecord(
      isUnlocked: (json['isUnlocked'] as bool?) ?? false,
      unlockedCount: (json['unlockedCount'] as num?)?.toInt() ?? 0,
      requiredCount: (json['requiredCount'] as num?)?.toInt() ?? 60,
      totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
      maxPossiblePoints: (json['maxPossiblePoints'] as num?)?.toInt() ?? 0,
      unlockedAt:
          unlockedAtRaw != null ? DateTime.tryParse(unlockedAtRaw) : null,
      unlockedSeasonYear: (json['unlockedSeasonYear'] as num?)?.toInt(),
    );
  }
}

/// Zbiorcze statystyki postępu wg rangi i kategorii.
@immutable
class CareerAchievementsSummary {
  final int totalCount;
  final int unlockedCount;
  final int inProgressCount;
  final int lockedCount;
  final int totalPointsEarned;
  final int maxPossiblePoints;
  final Map<CareerAchievementTier, int> unlockedByTier;
  final Map<CareerAchievementTier, int> totalByTier;
  final Map<CareerAchievementCategory, int> unlockedByCategory;
  final Map<CareerAchievementCategory, int> totalByCategory;
  final PlatinumTrophyRecord platinumTrophy;

  const CareerAchievementsSummary({
    required this.totalCount,
    required this.unlockedCount,
    required this.inProgressCount,
    required this.lockedCount,
    required this.totalPointsEarned,
    required this.maxPossiblePoints,
    required this.unlockedByTier,
    required this.totalByTier,
    required this.unlockedByCategory,
    required this.totalByCategory,
    required this.platinumTrophy,
  });
}

/// Dane wejściowe z wyścigu, sezonu, laboratorium lub kariery do ewaluacji osiągnięć.
@immutable
class CareerAchievementEvaluationInput {
  final DateTime? timestamp;
  final int seasonYear;
  final String? raceId;
  final String? raceName;
  final String? riderName;
  final AchievementRaceTier raceTier;

  // Wyniki wyścigowe
  final bool stageWon;
  final bool raceWonOverall;
  final bool podiumOverall;
  final bool isTimeTrial;
  final bool isTeamTimeTrial;
  final bool isSummitFinish;
  final bool isCobbleRace;
  final bool isSprintFinish;
  final bool isGravelRace;
  final double? winMarginSeconds;
  final int? photoFinishMarginMs;
  final double? soloAttackDistanceKm;
  final double? breakawayDistanceKm;
  final bool wonFromBreakaway;
  final bool wonAfterCrash;
  final int echelonSplitCount;
  final bool satelliteRelayExecuted;
  final bool bikeThrowWin;
  final bool combativityAwardWon;
  final bool wonWithLeadoutTrain;
  final bool wonWithoutRaceRadio;
  final bool wonInHeavyStorm;
  final bool wonGrandTourAllFourJerseys;
  final String? grandTourId;
  final String? monumentId;
  final bool isTripleCrownSeason;
  final bool wonWorldChampRoadRace;
  final bool wonWorldChampTimeTrial;
  final bool wonNationalChampionship;
  final bool wonU23FutureTour;
  final bool wonParallelFrontsSameDay;
  final int stageWinsInSingleGrandTour;

  // Zarządzanie, finanse, skauting
  final bool promotedToWorldTour;
  final bool customTeamFounded;
  final double? teamBudgetEur;
  final int? uciTeamRanking;
  final int consecutiveSponsorObjectivesMet;
  final double? transferProfitEur;
  final int activeScoutingRegions;
  final int maxedServiceCourseModules;
  final int cleanAntiDopingSeasons;
  final int veloDorWinnerCount;
  final int completedSeasonsCount;
  final bool wonWithU23PromoteRider;
  final bool survivedRelegationCycle;
  final bool signedMegaSponsor;

  // Sprzęt, aero i fizjologia
  final int windTunnelSessionsDelta;
  final bool skunkworksPrototypeWonRace;
  final double? peak20MinWkg;
  final double? peak5SecWatts;
  final double? riderVo2Max;
  final double? optimalCobbleTirePressureBar;
  final bool hydrogelAndKetonesUsed;
  final bool completedGrandTourZeroBonks;
  final bool wonAfterAltitudeCamp;
  final bool bikeFitCdaOptimizedBelow0200;
  final bool beatKomSegmentRecord;

  // Be a Pro i dyscypliny specjalne
  final int? proCyclistOvr;
  final bool proCyclistMonumentWin;
  final bool proCyclistGrandTourWin;
  final bool proCyclistWorldChamp;
  final bool olympicGoldMedalWon;
  final bool cyclocrossWorldChampWon;
  final bool gravelWorldSeriesWon;
  final double? hourRecordDistanceKm;
  final bool womensWorldTourTitleWon;
  final int historicScenariosGoldCount;

  const CareerAchievementEvaluationInput({
    this.timestamp,
    this.seasonYear = 2026,
    this.raceId,
    this.raceName,
    this.riderName,
    this.raceTier = AchievementRaceTier.other,
    this.stageWon = false,
    this.raceWonOverall = false,
    this.podiumOverall = false,
    this.isTimeTrial = false,
    this.isTeamTimeTrial = false,
    this.isSummitFinish = false,
    this.isCobbleRace = false,
    this.isSprintFinish = false,
    this.isGravelRace = false,
    this.winMarginSeconds,
    this.photoFinishMarginMs,
    this.soloAttackDistanceKm,
    this.breakawayDistanceKm,
    this.wonFromBreakaway = false,
    this.wonAfterCrash = false,
    this.echelonSplitCount = 0,
    this.satelliteRelayExecuted = false,
    this.bikeThrowWin = false,
    this.combativityAwardWon = false,
    this.wonWithLeadoutTrain = false,
    this.wonWithoutRaceRadio = false,
    this.wonInHeavyStorm = false,
    this.wonGrandTourAllFourJerseys = false,
    this.grandTourId,
    this.monumentId,
    this.isTripleCrownSeason = false,
    this.wonWorldChampRoadRace = false,
    this.wonWorldChampTimeTrial = false,
    this.wonNationalChampionship = false,
    this.wonU23FutureTour = false,
    this.wonParallelFrontsSameDay = false,
    this.stageWinsInSingleGrandTour = 0,
    this.promotedToWorldTour = false,
    this.customTeamFounded = false,
    this.teamBudgetEur,
    this.uciTeamRanking,
    this.consecutiveSponsorObjectivesMet = 0,
    this.transferProfitEur,
    this.activeScoutingRegions = 0,
    this.maxedServiceCourseModules = 0,
    this.cleanAntiDopingSeasons = 0,
    this.veloDorWinnerCount = 0,
    this.completedSeasonsCount = 0,
    this.wonWithU23PromoteRider = false,
    this.survivedRelegationCycle = false,
    this.signedMegaSponsor = false,
    this.windTunnelSessionsDelta = 0,
    this.skunkworksPrototypeWonRace = false,
    this.peak20MinWkg,
    this.peak5SecWatts,
    this.riderVo2Max,
    this.optimalCobbleTirePressureBar,
    this.hydrogelAndKetonesUsed = false,
    this.completedGrandTourZeroBonks = false,
    this.wonAfterAltitudeCamp = false,
    this.bikeFitCdaOptimizedBelow0200 = false,
    this.beatKomSegmentRecord = false,
    this.proCyclistOvr,
    this.proCyclistMonumentWin = false,
    this.proCyclistGrandTourWin = false,
    this.proCyclistWorldChamp = false,
    this.olympicGoldMedalWon = false,
    this.cyclocrossWorldChampWon = false,
    this.gravelWorldSeriesWon = false,
    this.hourRecordDistanceKm,
    this.womensWorldTourTitleWon = false,
    this.historicScenariosGoldCount = 0,
  });
}

/// Pełny stan systemu 60 osiągnięć i Platynowego Trofeum.
@immutable
class CareerAchievementsEngineState {
  final Map<String, CareerAchievementProgress> progressById;
  final List<CareerTrophyUnlockEvent> unlockHistory;
  final List<CareerTrophyUnlockEvent> pendingToastQueue;
  final PlatinumTrophyRecord platinumTrophy;
  final Map<String, double> cumulativeCounters;
  final Set<String> unlockedMonumentIds;
  final Set<String> unlockedGrandTourIds;

  const CareerAchievementsEngineState({
    required this.progressById,
    required this.unlockHistory,
    required this.pendingToastQueue,
    required this.platinumTrophy,
    required this.cumulativeCounters,
    required this.unlockedMonumentIds,
    required this.unlockedGrandTourIds,
  });

  factory CareerAchievementsEngineState.initial() {
    final map = <String, CareerAchievementProgress>{};
    for (final def in CareerAchievementsAndTrophiesEngine.catalog) {
      map[def.id] = CareerAchievementProgress(
        achievementId: def.id,
        currentValue: 0.0,
        targetValue: def.targetValue,
        isUnlocked: false,
      );
    }
    return CareerAchievementsEngineState(
      progressById: map,
      unlockHistory: const [],
      pendingToastQueue: const [],
      platinumTrophy: PlatinumTrophyRecord(
        isUnlocked: false,
        unlockedCount: 0,
        requiredCount: CareerAchievementsAndTrophiesEngine.totalAchievements,
        totalPointsEarned: 0,
        maxPossiblePoints:
            CareerAchievementsAndTrophiesEngine.maxBaseAchievementPoints,
      ),
      cumulativeCounters: const {},
      unlockedMonumentIds: const {},
      unlockedGrandTourIds: const {},
    );
  }

  CareerAchievementsEngineState copyWith({
    Map<String, CareerAchievementProgress>? progressById,
    List<CareerTrophyUnlockEvent>? unlockHistory,
    List<CareerTrophyUnlockEvent>? pendingToastQueue,
    PlatinumTrophyRecord? platinumTrophy,
    Map<String, double>? cumulativeCounters,
    Set<String>? unlockedMonumentIds,
    Set<String>? unlockedGrandTourIds,
  }) {
    return CareerAchievementsEngineState(
      progressById: progressById ?? this.progressById,
      unlockHistory: unlockHistory ?? this.unlockHistory,
      pendingToastQueue: pendingToastQueue ?? this.pendingToastQueue,
      platinumTrophy: platinumTrophy ?? this.platinumTrophy,
      cumulativeCounters: cumulativeCounters ?? this.cumulativeCounters,
      unlockedMonumentIds: unlockedMonumentIds ?? this.unlockedMonumentIds,
      unlockedGrandTourIds: unlockedGrandTourIds ?? this.unlockedGrandTourIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progressById': progressById.map((k, v) => MapEntry(k, v.toJson())),
      'unlockHistory': unlockHistory.map((e) => e.toJson()).toList(),
      'pendingToastQueue': pendingToastQueue.map((e) => e.toJson()).toList(),
      'platinumTrophy': platinumTrophy.toJson(),
      'cumulativeCounters': cumulativeCounters,
      'unlockedMonumentIds': unlockedMonumentIds.toList(),
      'unlockedGrandTourIds': unlockedGrandTourIds.toList(),
    };
  }

  factory CareerAchievementsEngineState.fromJson(Map<String, dynamic> json) {
    final initial = CareerAchievementsEngineState.initial();
    final mergedProgress =
        Map<String, CareerAchievementProgress>.from(initial.progressById);
    final rawProgress = json['progressById'] as Map<String, dynamic>?;
    if (rawProgress != null) {
      for (final entry in rawProgress.entries) {
        if (entry.value is Map<String, dynamic> &&
            mergedProgress.containsKey(entry.key)) {
          final parsed = CareerAchievementProgress.fromJson(
              entry.value as Map<String, dynamic>);
          final target = mergedProgress[entry.key]!.targetValue;
          mergedProgress[entry.key] = parsed.copyWith(targetValue: target);
        }
      }
    }

    final rawHistory = json['unlockHistory'] as List<dynamic>? ?? const [];
    final history = rawHistory
        .whereType<Map<String, dynamic>>()
        .map(CareerTrophyUnlockEvent.fromJson)
        .toList();

    final rawToasts = json['pendingToastQueue'] as List<dynamic>? ?? const [];
    final toasts = rawToasts
        .whereType<Map<String, dynamic>>()
        .map(CareerTrophyUnlockEvent.fromJson)
        .toList();

    final rawCounters =
        json['cumulativeCounters'] as Map<String, dynamic>? ?? const {};
    final counters = <String, double>{};
    for (final entry in rawCounters.entries) {
      if (entry.value is num) {
        counters[entry.key] = (entry.value as num).toDouble();
      }
    }

    final monuments = (json['unlockedMonumentIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toSet();
    final grandTours =
        (json['unlockedGrandTourIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toSet();

    final rawPlatinum = json['platinumTrophy'] as Map<String, dynamic>?;
    final platinum = rawPlatinum != null
        ? PlatinumTrophyRecord.fromJson(rawPlatinum)
        : CareerAchievementsAndTrophiesEngine.recomputePlatinum(mergedProgress);

    return CareerAchievementsEngineState(
      progressById: mergedProgress,
      unlockHistory: history,
      pendingToastQueue: toasts,
      platinumTrophy: platinum,
      cumulativeCounters: counters,
      unlockedMonumentIds: monuments,
      unlockedGrandTourIds: grandTours,
    );
  }
}

/// Wynik pojedynczego kroku ewaluacji osiągnięć.
@immutable
class CareerAchievementEvaluationResult {
  final CareerAchievementsEngineState nextState;
  final List<CareerTrophyUnlockEvent> newlyUnlocked;
  final bool platinumJustUnlocked;

  const CareerAchievementEvaluationResult({
    required this.nextState,
    required this.newlyUnlocked,
    required this.platinumJustUnlocked,
  });
}

/// Główny silnik 60 Osiągnięć Menedżerskich i Kolarskich z Platynowym Trofeum.
class CareerAchievementsAndTrophiesEngine {
  CareerAchievementsAndTrophiesEngine._();

  static const int totalAchievements = 60;

  static int get maxBaseAchievementPoints =>
      catalog.fold<int>(0, (sum, def) => sum + def.points);

  /// Kompletny katalog 60 unikalnych osiągnięć (6 kategorii x 10 osiągnięć).
  static const List<CareerAchievementDefinition> catalog = [
    // =========================================================================
    // 1. WIELKIE TOURY I ETAPÓWKI (10)
    // =========================================================================
    CareerAchievementDefinition(
      id: 'gt_first_stage_win',
      codeNumber: 1,
      title: 'Pierwszy Krok na Wielkiej Scenie',
      description: 'Wygraj swój pierwszy etap Wielkiego Touru.',
      tier: CareerAchievementTier.bronze,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.flag_rounded,
      trophyLabel: 'Medal Etapowy GT',
    ),
    CareerAchievementDefinition(
      id: 'gt_stage_hattrick',
      codeNumber: 2,
      title: 'Dominator Tygodnia',
      description: 'Wygraj co najmniej 3 etapy w jednym Wielkim Tourze.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.looks_3_rounded,
      targetValue: 3,
      trophyLabel: 'Srebrna Szprycha',
    ),
    CareerAchievementDefinition(
      id: 'gt_first_overall_win',
      codeNumber: 3,
      title: 'Żółty, Różowy lub Czerwony',
      description:
          'Wygraj klasyfikację generalną GC dowolnego Wielkiego Touru.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.emoji_events_rounded,
      trophyLabel: 'Puchar Wielkiego Touru',
    ),
    CareerAchievementDefinition(
      id: 'gt_all_three_grand_tours',
      codeNumber: 4,
      title: 'Kariera Wielkiego Szlema',
      description:
          'Zdobądź zwycięstwa GC we wszystkich 3 Wielkich Tourach (Tour, Giro, Vuelta).',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.military_tech_rounded,
      targetValue: 3,
      trophyLabel: 'Korona Trzech Tourów',
    ),
    CareerAchievementDefinition(
      id: 'gt_triple_crown_season',
      codeNumber: 5,
      title: 'Potrójna Korona Sezonu',
      description:
          'Wygraj 2 Wielkie Toury oraz Mistrzostwo Świata UCI w jednym sezonie.',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.workspace_premium_rounded,
      trophyLabel: 'Legenda Potrójnej Korony',
    ),
    CareerAchievementDefinition(
      id: 'gt_all_four_jerseys',
      codeNumber: 6,
      title: 'Absolutny Monopol',
      description:
          'Zdobądź jednocześnie koszulki GC, Punktową, Górską i Młodzieżową w jednym Wielkim Tourze.',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.checkroom_rounded,
      isSecret: true,
      trophyLabel: 'Tęczowa Szafa GT',
    ),
    CareerAchievementDefinition(
      id: 'gt_summit_hc_queen',
      codeNumber: 7,
      title: 'Król Królewskiego Etapu',
      description:
          'Wygraj górski etap z metą na szczycie w Wielkim Tourze.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.landscape_rounded,
      trophyLabel: 'Kryształ Alpejski',
    ),
    CareerAchievementDefinition(
      id: 'gt_podium_collector',
      codeNumber: 8,
      title: 'Stały Bywalec Podium',
      description: 'Zakończ Wielki Tour na podium GC 5 razy w karierze.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.leaderboard_rounded,
      targetValue: 5,
      trophyLabel: 'Złoty Stopień',
    ),
    CareerAchievementDefinition(
      id: 'gt_week_long_master',
      codeNumber: 9,
      title: 'Mistrz Tygodniówek',
      description: 'Wygraj 5 wyścigów etapowych WorldTour (np. Dauphine, PN).',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.calendar_view_week_rounded,
      targetValue: 5,
      trophyLabel: 'Puchar WorldTour',
    ),
    CareerAchievementDefinition(
      id: 'gt_millimeter_gc_win',
      codeNumber: 10,
      title: 'Złote 8 Sekund',
      description:
          'Wygraj wyścig wieloetapowy z przewagą mniejszą niż 10 sekund nad drugim kolarzem.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.grandToursAndStageRaces,
      icon: Icons.timer_rounded,
      isSecret: true,
      trophyLabel: 'Chronometr Mistrza',
    ),

    // =========================================================================
    // 2. MONUMENTY I KLASYKI (10)
    // =========================================================================
    CareerAchievementDefinition(
      id: 'mon_first_monument',
      codeNumber: 11,
      title: 'Pieczęć Monumentu',
      description: 'Wygraj swój pierwszy z pięciu kolarskich Monumentów.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.account_balance_outlined,
      trophyLabel: 'Kamień Monumentu',
    ),
    CareerAchievementDefinition(
      id: 'mon_all_five_monuments',
      codeNumber: 12,
      title: 'Pięć Klejnotów Korony',
      description:
          'Wygraj wszystkie 5 Monumentów: MSR, Ronde, Roubaix, LBL oraz Il Lombardia.',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.diamond_rounded,
      targetValue: 5,
      trophyLabel: 'Brylantowy Puchar',
    ),
    CareerAchievementDefinition(
      id: 'mon_roubaix_cobbles',
      codeNumber: 13,
      title: 'Władca Piekła Północy',
      description: 'Wygraj Paryż-Roubaix na sektorach bruku 5★.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.grid_on_rounded,
      trophyLabel: 'Kostka Bruku Roubaix',
    ),
    CareerAchievementDefinition(
      id: 'mon_flanders_berg',
      codeNumber: 14,
      title: 'Lew Flandrii',
      description: 'Wygraj Tour des Flandres na flandryjskich ściankach.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.shield_rounded,
      trophyLabel: 'Flaga Flandrii',
    ),
    CareerAchievementDefinition(
      id: 'mon_sanremo_poggio',
      codeNumber: 15,
      title: 'Cios na Poggio',
      description: 'Wygraj Mediolan-San Remo po 290 km ścigania.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.waves_rounded,
      trophyLabel: 'Laur Ligurii',
    ),
    CareerAchievementDefinition(
      id: 'mon_ardennes_liege',
      codeNumber: 16,
      title: 'Królowa Ardenów',
      description: 'Wygraj Liege-Bastogne-Liege.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.forest_rounded,
      trophyLabel: 'Trofeum Ardenów',
    ),
    CareerAchievementDefinition(
      id: 'mon_lombardia_leaves',
      codeNumber: 17,
      title: 'Klasyk Spadających Liści',
      description: 'Wygraj jesienny Monument Il Lombardia.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.eco_rounded,
      trophyLabel: 'Liść Como',
    ),
    CareerAchievementDefinition(
      id: 'mon_world_champ_rr',
      codeNumber: 18,
      title: 'Tęczowe Pasy',
      description:
          'Zdobądź złoty medal Mistrzostw Świata UCI w wyścigu ze startu wspólnego.',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.public_rounded,
      trophyLabel: 'Tęczowa Koszulka UCI',
    ),
    CareerAchievementDefinition(
      id: 'mon_world_champ_itt',
      codeNumber: 19,
      title: 'Najszybszy Przeciwko Czasowi',
      description:
          'Zdobądź złoty medal Mistrzostw Świata UCI w jeździe indywidualnej na czas.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.speed_rounded,
      trophyLabel: 'Tęczowy Chronometr',
    ),
    CareerAchievementDefinition(
      id: 'mon_classics_ten_wins',
      codeNumber: 20,
      title: 'Łowca Jednodniówek',
      description: 'Wygraj 10 klasyków WorldTour w trakcie kariery.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.monumentsAndClassics,
      icon: Icons.bolt_outlined,
      targetValue: 10,
      trophyLabel: 'Złota Odznaka Klasyków',
    ),

    // =========================================================================
    // 3. TAKTYKA I SZTUKA WYŚCIGU (10)
    // =========================================================================
    CareerAchievementDefinition(
      id: 'tac_echelon_master',
      codeNumber: 21,
      title: 'Mistrz Rantów',
      description:
          'Rozerwij peleton na co najmniej 3 wachlarze przy bocznym wietrze i wygraj etap.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.air_rounded,
      trophyLabel: 'Róża Wiatrów',
    ),
    CareerAchievementDefinition(
      id: 'tac_satellite_relay',
      codeNumber: 22,
      title: 'Stacja Przekaźnikowa',
      description:
          'Wykorzystaj pomocnika z ucieczki jako stację przekaźnikową dla lidera GC i wygraj etap.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.settings_input_antenna_rounded,
      trophyLabel: 'Sygnał Taktyczny',
    ),
    CareerAchievementDefinition(
      id: 'tac_solo_raid_50km',
      codeNumber: 23,
      title: 'Szaleńczy Rajd Solo',
      description:
          'Wygraj etap lub klasyk po samotnym ataku na minimum 50 km przed metą.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.directions_run_rounded,
      trophyLabel: 'Złoty Samotnik',
    ),
    CareerAchievementDefinition(
      id: 'tac_photo_finish_throw',
      codeNumber: 24,
      title: 'O Błysk Szprychy',
      description:
          'Wygraj sprint na fotofiniszu z różnicą <= 15 ms dzięki Rzutowi Rowerem (Bike Throw).',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.camera_alt_rounded,
      trophyLabel: 'Klatka Fotofiniszu',
    ),
    CareerAchievementDefinition(
      id: 'tac_sprint_train_perfection',
      codeNumber: 25,
      title: 'Kolej Ekspresowa',
      description:
          'Wygraj płaski finisz po idealnym rozprowadzeniu przez pociąg sprinterski.',
      tier: CareerAchievementTier.bronze,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.train_rounded,
      trophyLabel: 'Bilet Sprinterów',
    ),
    CareerAchievementDefinition(
      id: 'tac_breakaway_survival',
      codeNumber: 26,
      title: 'Ucieczka do Samej Mety',
      description:
          'Wygraj etap z porannej ucieczki po przejechaniu ponad 120 km na czele.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.near_me_rounded,
      trophyLabel: 'Czerwony Numer',
    ),
    CareerAchievementDefinition(
      id: 'tac_ttt_clockwork',
      codeNumber: 27,
      title: 'Szwajcarski Zegarek TTT',
      description: 'Wygraj drużynową jazdę na czas (TTT) w wyścigu WorldTour.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.groups_rounded,
      trophyLabel: 'Wachlarz Drużyny',
    ),
    CareerAchievementDefinition(
      id: 'tac_phoenix_after_crash',
      codeNumber: 28,
      title: 'Feniks z Asfaltu',
      description:
          'Wygraj etap mimo wcześniejszej kraksy swojego kolarza na tym samym etapie.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.local_fire_department_rounded,
      isSecret: true,
      trophyLabel: 'Serce Wojownika',
    ),
    CareerAchievementDefinition(
      id: 'tac_storm_warrior',
      codeNumber: 29,
      title: 'W Oku Cyklonu',
      description:
          'Wygraj etap lub klasyk rozgrywany w ulewnej burzy (Heavy Storm).',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.thunderstorm_rounded,
      trophyLabel: 'Piorun Szosy',
    ),
    CareerAchievementDefinition(
      id: 'tac_combativity_collector',
      codeNumber: 30,
      title: 'Nieustraszony Peletonu',
      description:
          'Zdobądź nagrodę Najaktywniejszego Kolarza Etapu (Combativity Award) 5 razy.',
      tier: CareerAchievementTier.bronze,
      category: CareerAchievementCategory.tacticsAndRacecraft,
      icon: Icons.whatshot_rounded,
      targetValue: 5,
      trophyLabel: 'Odznaka Waleczności',
    ),

    // =========================================================================
    // 4. ZARZĄDZANIE, SPONSORZY I FINANSE (10)
    // =========================================================================
    CareerAchievementDefinition(
      id: 'mgt_first_win',
      codeNumber: 31,
      title: 'Pierwszy Szampan Dyrektora',
      description: 'Odniesione pierwsze zwycięstwo drużyny w trybie kariery.',
      tier: CareerAchievementTier.bronze,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.celebration_rounded,
      trophyLabel: 'Korek od Szampana',
    ),
    CareerAchievementDefinition(
      id: 'mgt_fifty_wins',
      codeNumber: 32,
      title: 'Pół Setki Triumfów',
      description: 'Zgromadź 50 zwycięstw drużyny we wszystkich wyścigach.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.military_tech_outlined,
      targetValue: 50,
      trophyLabel: 'Srebrna Patera',
    ),
    CareerAchievementDefinition(
      id: 'mgt_hundred_wins',
      codeNumber: 33,
      title: 'Klub Stulatków',
      description: 'Zgromadź 100 zwycięstw drużyny w trakcie kariery.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.auto_graph_rounded,
      targetValue: 100,
      trophyLabel: 'Złota Księga Zwycięstw',
    ),
    CareerAchievementDefinition(
      id: 'mgt_worldtour_promotion',
      codeNumber: 34,
      title: 'Awans do Elity WorldTour',
      description:
          'Awansuj swoją drużyną z dywizji Continental/ProTeam do UCI WorldTour.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.trending_up_rounded,
      trophyLabel: 'Licencja WorldTour',
    ),
    CareerAchievementDefinition(
      id: 'mgt_uci_world_number_one',
      codeNumber: 35,
      title: 'Numer 1 na Świecie',
      description: 'Zajmij 1. miejsce w drużynowym rankingu UCI WorldRanking.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.looks_one_rounded,
      trophyLabel: 'Złoty Globus UCI',
    ),
    CareerAchievementDefinition(
      id: 'mgt_sponsor_streak_5',
      codeNumber: 36,
      title: 'Ulubieniec Sponsorów',
      description:
          'Zrealizuj 5 celów sponsorskich z rzędu i utrzymaj pełne zaufanie zarządu.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.handshake_rounded,
      targetValue: 5,
      trophyLabel: 'Złoty Kontrakt',
    ),
    CareerAchievementDefinition(
      id: 'mgt_service_course_hq_max',
      codeNumber: 37,
      title: 'Baza Kosmiczna Service Course',
      description:
          'Rozbuduj wszystkie 5 modułów bazy Service Course HQ do poziomu 5.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.apartment_rounded,
      targetValue: 5,
      trophyLabel: 'Klucz do Bazy HQ',
    ),
    CareerAchievementDefinition(
      id: 'mgt_u23_gem_promoted',
      codeNumber: 38,
      title: 'Szlif Diamentu z U23',
      description:
          'Wychowaj juniora z Akademii U23, awansuj go do pierwszej drużyny i wygraj nim wyścig.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.school_rounded,
      trophyLabel: 'Certyfikat Skauta',
    ),
    CareerAchievementDefinition(
      id: 'mgt_parallel_double_win',
      codeNumber: 39,
      title: 'Podwójne Uderzenie Frontów',
      description:
          'Wygraj tego samego dnia dwa różne wyścigi na Frontach A i B podzieloną kadrą.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.call_split_rounded,
      isSecret: true,
      trophyLabel: 'Medal Podwójnego Sztabu',
    ),
    CareerAchievementDefinition(
      id: 'mgt_dynasty_five_seasons',
      codeNumber: 40,
      title: 'Architekt Dynastii',
      description: 'Ukończ 5 pełnych sezonów kariery bez bankructwa i afer.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.managementAndFinance,
      icon: Icons.history_edu_rounded,
      targetValue: 5,
      trophyLabel: 'Kronika Pięciolecia',
    ),

    // =========================================================================
    // 5. SPRZĘT, TUNEL AERO I FIZJOLOGIA (10)
    // =========================================================================
    CareerAchievementDefinition(
      id: 'eqp_wind_tunnel_scientist',
      codeNumber: 41,
      title: 'Doktorat z Aerodynamiki',
      description:
          'Przeprowadź 10 sesji optymalizacji w Tunelu Aerodynamicznym.',
      tier: CareerAchievementTier.bronze,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.wind_power_rounded,
      targetValue: 10,
      trophyLabel: 'Model Tunelu Aero',
    ),
    CareerAchievementDefinition(
      id: 'eqp_sub_0200_cda',
      codeNumber: 42,
      title: 'Niewidzialny dla Wiatru',
      description:
          'Zoptymalizuj pozycję Bike Fit kolarza poniżej granicy CdA 0.200 m².',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.air_outlined,
      trophyLabel: 'Struga Laminarna',
    ),
    CareerAchievementDefinition(
      id: 'eqp_skunkworks_prototype_win',
      codeNumber: 43,
      title: 'Tajna Broń Skunkworks',
      description:
          'Wygraj kluczowy wyścig na tajnym prototypie z laboratorium Skunkworks Lab.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.biotech_rounded,
      trophyLabel: 'Blueprint Prototypu',
    ),
    CareerAchievementDefinition(
      id: 'eqp_cobble_pressure_sweetspot',
      codeNumber: 44,
      title: 'Perfekcyjne Ciśnienie Bruku',
      description:
          'Wygraj wyścig na bruku z optymalnie dobranym ciśnieniem opon (3.5–4.3 bar).',
      tier: CareerAchievementTier.bronze,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.tire_repair_rounded,
      trophyLabel: 'Manometr Mistrzów',
    ),
    CareerAchievementDefinition(
      id: 'eqp_mutant_wkg_65',
      codeNumber: 45,
      title: 'Bariera 6.5 W/kg',
      description:
          'Osiągnij w trakcie podjazdu 20-minutową moc progową >= 6.50 W/kg.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.flash_on_rounded,
      trophyLabel: 'Watomierz Złota',
    ),
    CareerAchievementDefinition(
      id: 'eqp_sprint_1600w',
      codeNumber: 46,
      title: 'Bomba 1600 Watów',
      description: 'Zarejestruj na finiszu szczytową moc 5s powyżej 1600 W.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.electric_bolt_rounded,
      trophyLabel: 'Kondensator Mocy',
    ),
    CareerAchievementDefinition(
      id: 'eqp_vo2max_90_club',
      codeNumber: 47,
      title: 'Klub VO2max 90+',
      description:
          'Przebadaj lub wytrenuj kolarza o wydolności tlenowej VO2max >= 90 ml/kg/min.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.monitor_heart_rounded,
      trophyLabel: 'Złote Płuca',
    ),
    CareerAchievementDefinition(
      id: 'eqp_hydrogel_ketones_science',
      codeNumber: 48,
      title: 'Nowoczesna Biochemia Peletonu',
      description:
          'Zastosuj plan żywieniowy High-Carb Hydrogel 110g/h i ketony regeneracyjne.',
      tier: CareerAchievementTier.bronze,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.local_drink_rounded,
      trophyLabel: 'Bidon Pro-Lab',
    ),
    CareerAchievementDefinition(
      id: 'eqp_zero_bonks_grand_tour',
      codeNumber: 49,
      title: 'Bez Odcięcia Prądu',
      description:
          'Ukończ 21-etapowy Wielki Tour bez ani jednego przypadku głodu glikogenowego (Bonk).',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.battery_charging_full_rounded,
      trophyLabel: 'Pełny Bak Glikogenu',
    ),
    CareerAchievementDefinition(
      id: 'eqp_kom_strava_record',
      codeNumber: 50,
      title: 'Nowy Rekord Świata KOM',
      description:
          'Pobij historyczny rekord wirtualnego segmentu KOM na legendarnym podjeździe.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.equipmentAndPhysiology,
      icon: Icons.emoji_nature_rounded,
      trophyLabel: 'Korona KOM',
    ),

    // =========================================================================
    // 6. BE A PRO I DYSCYPLINY SPECJALNE (10)
    // =========================================================================
    CareerAchievementDefinition(
      id: 'pro_ovr_90_legend',
      codeNumber: 51,
      title: 'Narodziny Galaktycznego Kolarza',
      description:
          'Osiągnij ocenę ogólną OVR >= 90 swoim własnym kolarzem w trybie Be a Pro.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.person_pin_rounded,
      trophyLabel: 'Złota Karta OVR 90+',
    ),
    CareerAchievementDefinition(
      id: 'pro_monument_hero',
      codeNumber: 52,
      title: 'Samotny Bohater Monumentu',
      description: 'Wygraj dowolny Monument w trybie Be a Pro.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.stars_rounded,
      trophyLabel: 'Statuetka Be a Pro',
    ),
    CareerAchievementDefinition(
      id: 'pro_grand_tour_emperor',
      codeNumber: 53,
      title: 'Cesarz Trzech Tygodni',
      description: 'Wygraj klasyfikację GC Wielkiego Touru w trybie Be a Pro.',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.emoji_events_outlined,
      trophyLabel: 'Korona Be a Pro',
    ),
    CareerAchievementDefinition(
      id: 'pro_olympic_gold',
      codeNumber: 54,
      title: 'Złoty Kask Olimpijski',
      description:
          'Zdobądź złoty medal Igrzysk Olimpijskich (bez radia wyścigowego!) i noś złoty kask.',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.looks_rounded,
      trophyLabel: 'Złoty Medal Olimpijski',
    ),
    CareerAchievementDefinition(
      id: 'pro_cx_winter_king',
      codeNumber: 55,
      title: 'Król Błota i Przełajów',
      description:
          'Zdobądź tytuł Mistrza Świata w Zimowym Pucharze Cyclo-Cross CX.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.terrain_outlined,
      trophyLabel: 'Tęczowy Puchar CX',
    ),
    CareerAchievementDefinition(
      id: 'pro_gravel_world_series',
      codeNumber: 56,
      title: 'Pionier Białych Szutrów',
      description:
          'Wygraj wyścig z cyklu UCI Gravel World Series bez wsparcia wozu technicznego.',
      tier: CareerAchievementTier.silver,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.explore_rounded,
      trophyLabel: 'Pył Sterrato',
    ),
    CareerAchievementDefinition(
      id: 'pro_uci_hour_record',
      codeNumber: 57,
      title: 'Władca Godziny na Welodromie',
      description:
          'Pobij Rekord Godzinny UCI przekraczając 56.000 km w 60 minut na welodromie 250 m.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.av_timer_rounded,
      trophyLabel: 'Ostre Koło Godziny',
    ),
    CareerAchievementDefinition(
      id: 'pro_womens_worldtour_queen',
      codeNumber: 58,
      title: 'Królowa Kobiecego WorldTouru',
      description:
          'Wygraj tytuł UCI Women\'s WorldTour lub Tour de France Femmes.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.female_rounded,
      trophyLabel: 'Trofeum WWT',
    ),
    CareerAchievementDefinition(
      id: 'pro_historic_scenarios_gold',
      codeNumber: 59,
      title: 'Mistrz Scenariuszy Historycznych',
      description:
          'Zdobądź złoty medal w co najmniej 5 Scenariuszach Historycznych i Wyzwaniach Taktycznych.',
      tier: CareerAchievementTier.gold,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.auto_stories_rounded,
      targetValue: 5,
      trophyLabel: 'Almanach Legend',
    ),
    CareerAchievementDefinition(
      id: 'pro_velo_dor_winner',
      codeNumber: 60,
      title: 'Zdobywca Złotego Roweru Vélo d\'Or',
      description:
          'Twój kolarz otrzymał statuetkę Vélo d\'Or na październikowej gali roku.',
      tier: CareerAchievementTier.legendary,
      category: CareerAchievementCategory.beAProAndSpecialDisciplines,
      icon: Icons.pedal_bike_rounded,
      trophyLabel: 'Statuetka Vélo d\'Or',
    ),
  ];

  static final Map<String, CareerAchievementDefinition> _catalogById = {
    for (final item in catalog) item.id: item,
  };

  static CareerAchievementDefinition? findById(String id) => _catalogById[id];

  /// Przelicza stan Platynowego Trofeum na podstawie mapy postępów.
  static PlatinumTrophyRecord recomputePlatinum(
    Map<String, CareerAchievementProgress> progressById, {
    DateTime? unlockedAt,
    int? unlockedSeasonYear,
    DateTime? existingUnlockedAt,
    int? existingSeasonYear,
  }) {
    int unlockedCount = 0;
    int pointsEarned = 0;

    for (final def in catalog) {
      final prog = progressById[def.id];
      if (prog != null && prog.isUnlocked) {
        unlockedCount++;
        pointsEarned += def.points;
      }
    }

    final isComplete = unlockedCount >= totalAchievements;
    if (isComplete) {
      pointsEarned += PlatinumTrophyRecord.platinumBonusPoints;
    }

    return PlatinumTrophyRecord(
      isUnlocked: isComplete,
      unlockedCount: unlockedCount,
      requiredCount: totalAchievements,
      totalPointsEarned: pointsEarned,
      maxPossiblePoints:
          maxBaseAchievementPoints + PlatinumTrophyRecord.platinumBonusPoints,
      unlockedAt: isComplete ? (existingUnlockedAt ?? unlockedAt) : null,
      unlockedSeasonYear:
          isComplete ? (existingSeasonYear ?? unlockedSeasonYear) : null,
    );
  }

  /// Ewaluuje zdarzenie z gry i zwraca nowy stan wraz z listą nowo odblokowanych trofeów.
  static CareerAchievementEvaluationResult evaluateEvent(
    CareerAchievementsEngineState state,
    CareerAchievementEvaluationInput input,
  ) {
    final now = input.timestamp ?? DateTime.now();
    final nextProgress =
        Map<String, CareerAchievementProgress>.from(state.progressById);
    final nextCounters = Map<String, double>.from(state.cumulativeCounters);
    final nextMonuments = Set<String>.from(state.unlockedMonumentIds);
    final nextGrandTours = Set<String>.from(state.unlockedGrandTourIds);
    final newlyUnlocked = <CareerTrophyUnlockEvent>[];

    void unlockOrAdvance(
      String id, {
      double? setValue,
      double addValue = 0.0,
      String? note,
    }) {
      final def = _catalogById[id];
      if (def == null) return;
      final current = nextProgress[id] ??
          CareerAchievementProgress(
            achievementId: id,
            currentValue: 0,
            targetValue: def.targetValue,
            isUnlocked: false,
          );

      double updatedVal = current.currentValue;
      if (setValue != null) {
        if (setValue > updatedVal) updatedVal = setValue;
      }
      if (addValue > 0) {
        updatedVal += addValue;
      }

      final clampedVal = updatedVal.clamp(0.0, def.targetValue);
      final shouldUnlock = clampedVal >= def.targetValue;

      if (!current.isUnlocked && shouldUnlock) {
        final resolvedNote = note ?? input.raceName;
        nextProgress[id] = current.copyWith(
          currentValue: def.targetValue,
          isUnlocked: true,
          unlockedAt: now,
          unlockedSeasonYear: input.seasonYear,
          unlockedRaceName: input.raceName,
          unlockedByRiderName: input.riderName,
          contextNote: resolvedNote,
          timesTriggered: current.timesTriggered + 1,
        );
        newlyUnlocked.add(
          CareerTrophyUnlockEvent(
            achievementId: def.id,
            title: def.title,
            description: def.description,
            tier: def.tier,
            category: def.category,
            pointsAwarded: def.points,
            isPlatinumTrophy: false,
            unlockedAt: now,
            seasonYear: input.seasonYear,
            contextNote: resolvedNote,
          ),
        );
      } else if (clampedVal > current.currentValue) {
        nextProgress[id] = current.copyWith(
          currentValue: clampedVal,
          contextNote: note ?? current.contextNote,
        );
      }
    }

    // -------------------------------------------------------------------------
    // 1. Wielkie Toury i Etapówki
    // -------------------------------------------------------------------------
    if (input.raceTier == AchievementRaceTier.grandTour && input.stageWon) {
      unlockOrAdvance('gt_first_stage_win', setValue: 1);
    }
    if (input.stageWinsInSingleGrandTour > 0) {
      unlockOrAdvance(
        'gt_stage_hattrick',
        setValue: input.stageWinsInSingleGrandTour.toDouble(),
      );
    }
    if (input.raceTier == AchievementRaceTier.grandTour &&
        input.raceWonOverall) {
      unlockOrAdvance('gt_first_overall_win', setValue: 1);
      final gtKey = (input.grandTourId ?? input.raceId ?? input.raceName ?? '')
          .toLowerCase();
      if (gtKey.contains('tour') || gtKey.contains('tdf')) {
        nextGrandTours.add('tdf');
      } else if (gtKey.contains('giro')) {
        nextGrandTours.add('giro');
      } else if (gtKey.contains('vuelta')) {
        nextGrandTours.add('vuelta');
      } else if (gtKey.isNotEmpty) {
        nextGrandTours.add(gtKey);
      }
      unlockOrAdvance(
        'gt_all_three_grand_tours',
        setValue: nextGrandTours.length.toDouble(),
      );
    }
    if (input.isTripleCrownSeason) {
      unlockOrAdvance('gt_triple_crown_season', setValue: 1);
    }
    if (input.wonGrandTourAllFourJerseys) {
      unlockOrAdvance('gt_all_four_jerseys', setValue: 1);
    }
    if (input.raceTier == AchievementRaceTier.grandTour &&
        input.stageWon &&
        input.isSummitFinish) {
      unlockOrAdvance('gt_summit_hc_queen', setValue: 1);
    }
    if (input.raceTier == AchievementRaceTier.grandTour &&
        (input.podiumOverall || input.raceWonOverall)) {
      unlockOrAdvance('gt_podium_collector', addValue: 1);
    }
    if (input.raceTier == AchievementRaceTier.worldTourStageRace &&
        input.raceWonOverall) {
      unlockOrAdvance('gt_week_long_master', addValue: 1);
    }
    if ((input.raceTier == AchievementRaceTier.grandTour ||
            input.raceTier == AchievementRaceTier.worldTourStageRace) &&
        input.raceWonOverall &&
        input.winMarginSeconds != null &&
        input.winMarginSeconds! > 0 &&
        input.winMarginSeconds! < 10.0) {
      unlockOrAdvance(
        'gt_millimeter_gc_win',
        setValue: 1,
        note: 'Przewaga: ${input.winMarginSeconds!.toStringAsFixed(1)} s',
      );
    }

    // -------------------------------------------------------------------------
    // 2. Monumenty i Klasyki
    // -------------------------------------------------------------------------
    if (input.raceTier == AchievementRaceTier.monument && input.raceWonOverall) {
      unlockOrAdvance('mon_first_monument', setValue: 1);
      final monKey =
          (input.monumentId ?? input.raceId ?? input.raceName ?? '').toLowerCase();
      if (monKey.contains('roubaix')) {
        nextMonuments.add('roubaix');
        unlockOrAdvance('mon_roubaix_cobbles', setValue: 1);
      }
      if (monKey.contains('flanders') || monKey.contains('ronde')) {
        nextMonuments.add('flanders');
        unlockOrAdvance('mon_flanders_berg', setValue: 1);
      }
      if (monKey.contains('sanremo') || monKey.contains('san_remo') || monKey.contains('msr')) {
        nextMonuments.add('sanremo');
        unlockOrAdvance('mon_sanremo_poggio', setValue: 1);
      }
      if (monKey.contains('liege') || monKey.contains('lbl')) {
        nextMonuments.add('liege');
        unlockOrAdvance('mon_ardennes_liege', setValue: 1);
      }
      if (monKey.contains('lombardia')) {
        nextMonuments.add('lombardia');
        unlockOrAdvance('mon_lombardia_leaves', setValue: 1);
      }
      unlockOrAdvance(
        'mon_all_five_monuments',
        setValue: nextMonuments.length.toDouble(),
      );
    }
    if (input.wonWorldChampRoadRace) {
      unlockOrAdvance('mon_world_champ_rr', setValue: 1);
    }
    if (input.wonWorldChampTimeTrial) {
      unlockOrAdvance('mon_world_champ_itt', setValue: 1);
    }
    if ((input.raceTier == AchievementRaceTier.worldTourClassic ||
            input.raceTier == AchievementRaceTier.monument) &&
        input.raceWonOverall) {
      unlockOrAdvance('mon_classics_ten_wins', addValue: 1);
    }

    // -------------------------------------------------------------------------
    // 3. Taktyka i Sztuka Wyścigu
    // -------------------------------------------------------------------------
    final anyWin = input.stageWon || input.raceWonOverall;
    if (anyWin && input.echelonSplitCount >= 3) {
      unlockOrAdvance('tac_echelon_master', setValue: 1);
    }
    if (anyWin && input.satelliteRelayExecuted) {
      unlockOrAdvance('tac_satellite_relay', setValue: 1);
    }
    if (anyWin &&
        input.soloAttackDistanceKm != null &&
        input.soloAttackDistanceKm! >= 50.0) {
      unlockOrAdvance(
        'tac_solo_raid_50km',
        setValue: 1,
        note: 'Atak solo ${input.soloAttackDistanceKm!.toStringAsFixed(0)} km',
      );
    }
    if (anyWin &&
        input.bikeThrowWin &&
        input.photoFinishMarginMs != null &&
        input.photoFinishMarginMs! <= 15) {
      unlockOrAdvance(
        'tac_photo_finish_throw',
        setValue: 1,
        note: 'Fotofinisz ${input.photoFinishMarginMs} ms',
      );
    }
    if (anyWin && input.isSprintFinish && input.wonWithLeadoutTrain) {
      unlockOrAdvance('tac_sprint_train_perfection', setValue: 1);
    }
    if (anyWin &&
        input.wonFromBreakaway &&
        (input.breakawayDistanceKm ?? 0) >= 120.0) {
      unlockOrAdvance('tac_breakaway_survival', setValue: 1);
    }
    if (anyWin &&
        input.isTeamTimeTrial &&
        (input.raceTier == AchievementRaceTier.grandTour ||
            input.raceTier == AchievementRaceTier.worldTourStageRace ||
            input.raceTier == AchievementRaceTier.worldChampionships)) {
      unlockOrAdvance('tac_ttt_clockwork', setValue: 1);
    }
    if (anyWin && input.wonAfterCrash) {
      unlockOrAdvance('tac_phoenix_after_crash', setValue: 1);
    }
    if (anyWin && input.wonInHeavyStorm) {
      unlockOrAdvance('tac_storm_warrior', setValue: 1);
    }
    if (input.combativityAwardWon) {
      unlockOrAdvance('tac_combativity_collector', addValue: 1);
    }

    // -------------------------------------------------------------------------
    // 4. Zarządzanie, Sponsorzy i Finanse
    // -------------------------------------------------------------------------
    if (anyWin) {
      final totalWins = (nextCounters['career_wins'] ?? 0) + 1;
      nextCounters['career_wins'] = totalWins;
      unlockOrAdvance('mgt_first_win', setValue: 1);
      unlockOrAdvance('mgt_fifty_wins', setValue: totalWins);
      unlockOrAdvance('mgt_hundred_wins', setValue: totalWins);
    }
    if (input.promotedToWorldTour) {
      unlockOrAdvance('mgt_worldtour_promotion', setValue: 1);
    }
    if (input.uciTeamRanking == 1) {
      unlockOrAdvance('mgt_uci_world_number_one', setValue: 1);
    }
    if (input.consecutiveSponsorObjectivesMet > 0) {
      unlockOrAdvance(
        'mgt_sponsor_streak_5',
        setValue: input.consecutiveSponsorObjectivesMet.toDouble(),
      );
    }
    if (input.maxedServiceCourseModules > 0) {
      unlockOrAdvance(
        'mgt_service_course_hq_max',
        setValue: input.maxedServiceCourseModules.toDouble(),
      );
    }
    if (anyWin && input.wonWithU23PromoteRider) {
      unlockOrAdvance('mgt_u23_gem_promoted', setValue: 1);
    }
    if (input.wonParallelFrontsSameDay) {
      unlockOrAdvance('mgt_parallel_double_win', setValue: 1);
    }
    if (input.completedSeasonsCount > 0) {
      unlockOrAdvance(
        'mgt_dynasty_five_seasons',
        setValue: input.completedSeasonsCount.toDouble(),
      );
    }

    // -------------------------------------------------------------------------
    // 5. Sprzęt, Tunel Aero i Fizjologia
    // -------------------------------------------------------------------------
    if (input.windTunnelSessionsDelta > 0) {
      unlockOrAdvance(
        'eqp_wind_tunnel_scientist',
        addValue: input.windTunnelSessionsDelta.toDouble(),
      );
    }
    if (input.bikeFitCdaOptimizedBelow0200) {
      unlockOrAdvance('eqp_sub_0200_cda', setValue: 1);
    }
    if (anyWin && input.skunkworksPrototypeWonRace) {
      unlockOrAdvance('eqp_skunkworks_prototype_win', setValue: 1);
    }
    if (anyWin &&
        input.isCobbleRace &&
        input.optimalCobbleTirePressureBar != null &&
        input.optimalCobbleTirePressureBar! >= 3.5 &&
        input.optimalCobbleTirePressureBar! <= 4.3) {
      unlockOrAdvance('eqp_cobble_pressure_sweetspot', setValue: 1);
    }
    if (input.peak20MinWkg != null && input.peak20MinWkg! >= 6.5) {
      unlockOrAdvance(
        'eqp_mutant_wkg_65',
        setValue: 1,
        note: '${input.peak20MinWkg!.toStringAsFixed(2)} W/kg (20m)',
      );
    }
    if (input.peak5SecWatts != null && input.peak5SecWatts! >= 1600.0) {
      unlockOrAdvance(
        'eqp_sprint_1600w',
        setValue: 1,
        note: '${input.peak5SecWatts!.toStringAsFixed(0)} W (5s)',
      );
    }
    if (input.riderVo2Max != null && input.riderVo2Max! >= 90.0) {
      unlockOrAdvance('eqp_vo2max_90_club', setValue: 1);
    }
    if (input.hydrogelAndKetonesUsed) {
      unlockOrAdvance('eqp_hydrogel_ketones_science', setValue: 1);
    }
    if (input.completedGrandTourZeroBonks) {
      unlockOrAdvance('eqp_zero_bonks_grand_tour', setValue: 1);
    }
    if (input.beatKomSegmentRecord) {
      unlockOrAdvance('eqp_kom_strava_record', setValue: 1);
    }

    // -------------------------------------------------------------------------
    // 6. Be a Pro i Dyscypliny Specjalne
    // -------------------------------------------------------------------------
    if (input.proCyclistOvr != null && input.proCyclistOvr! >= 90) {
      unlockOrAdvance('pro_ovr_90_legend', setValue: 1);
    }
    if (input.proCyclistMonumentWin) {
      unlockOrAdvance('pro_monument_hero', setValue: 1);
    }
    if (input.proCyclistGrandTourWin) {
      unlockOrAdvance('pro_grand_tour_emperor', setValue: 1);
    }
    if (input.olympicGoldMedalWon) {
      unlockOrAdvance('pro_olympic_gold', setValue: 1);
    }
    if (input.cyclocrossWorldChampWon) {
      unlockOrAdvance('pro_cx_winter_king', setValue: 1);
    }
    if (input.gravelWorldSeriesWon ||
        (input.raceTier == AchievementRaceTier.gravelWorldSeries &&
            input.raceWonOverall)) {
      unlockOrAdvance('pro_gravel_world_series', setValue: 1);
    }
    if (input.hourRecordDistanceKm != null &&
        input.hourRecordDistanceKm! >= 56.0) {
      unlockOrAdvance(
        'pro_uci_hour_record',
        setValue: 1,
        note: '${input.hourRecordDistanceKm!.toStringAsFixed(3)} km/h',
      );
    }
    if (input.womensWorldTourTitleWon) {
      unlockOrAdvance('pro_womens_worldtour_queen', setValue: 1);
    }
    if (input.historicScenariosGoldCount > 0) {
      unlockOrAdvance(
        'pro_historic_scenarios_gold',
        setValue: input.historicScenariosGoldCount.toDouble(),
      );
    }
    if (input.veloDorWinnerCount > 0) {
      unlockOrAdvance('pro_velo_dor_winner', setValue: 1);
    }

    // Przeliczenie Platynowego Trofeum
    final nextPlatinum = recomputePlatinum(
      nextProgress,
      unlockedAt: now,
      unlockedSeasonYear: input.seasonYear,
      existingUnlockedAt: state.platinumTrophy.unlockedAt,
      existingSeasonYear: state.platinumTrophy.unlockedSeasonYear,
    );

    final platinumJustUnlocked =
        !state.platinumTrophy.isUnlocked && nextPlatinum.isUnlocked;

    if (platinumJustUnlocked) {
      newlyUnlocked.add(
        CareerTrophyUnlockEvent(
          achievementId: PlatinumTrophyRecord.platinumId,
          title: PlatinumTrophyRecord.platinumTitle,
          description: PlatinumTrophyRecord.platinumDescription,
          tier: CareerAchievementTier.legendary,
          category: CareerAchievementCategory.beAProAndSpecialDisciplines,
          pointsAwarded: PlatinumTrophyRecord.platinumBonusPoints,
          isPlatinumTrophy: true,
          unlockedAt: now,
          seasonYear: input.seasonYear,
          contextNote: '60 / 60 Osiągnięć Odblokowanych',
        ),
      );
    }

    final nextState = state.copyWith(
      progressById: nextProgress,
      unlockHistory: [...state.unlockHistory, ...newlyUnlocked],
      pendingToastQueue: [...state.pendingToastQueue, ...newlyUnlocked],
      platinumTrophy: nextPlatinum,
      cumulativeCounters: nextCounters,
      unlockedMonumentIds: nextMonuments,
      unlockedGrandTourIds: nextGrandTours,
    );

    return CareerAchievementEvaluationResult(
      nextState: nextState,
      newlyUnlocked: newlyUnlocked,
      platinumJustUnlocked: platinumJustUnlocked,
    );
  }

  /// Ręcznie zwiększa postęp wskazanego osiągnięcia (np. z zewnętrznych modułów).
  static CareerAchievementEvaluationResult incrementAchievementProgress(
    CareerAchievementsEngineState state,
    String achievementId, {
    double delta = 1.0,
    int seasonYear = 2026,
    String? contextNote,
    DateTime? timestamp,
  }) {
    final def = _catalogById[achievementId];
    if (def == null) {
      return CareerAchievementEvaluationResult(
        nextState: state,
        newlyUnlocked: const [],
        platinumJustUnlocked: false,
      );
    }

    final now = timestamp ?? DateTime.now();
    final nextProgress =
        Map<String, CareerAchievementProgress>.from(state.progressById);
    final current = nextProgress[achievementId] ??
        CareerAchievementProgress(
          achievementId: achievementId,
          currentValue: 0,
          targetValue: def.targetValue,
          isUnlocked: false,
        );

    if (current.isUnlocked) {
      return CareerAchievementEvaluationResult(
        nextState: state,
        newlyUnlocked: const [],
        platinumJustUnlocked: false,
      );
    }

    final updatedVal = (current.currentValue + delta).clamp(0.0, def.targetValue);
    final unlockedNow = updatedVal >= def.targetValue;
    final newlyUnlocked = <CareerTrophyUnlockEvent>[];

    nextProgress[achievementId] = current.copyWith(
      currentValue: updatedVal,
      isUnlocked: unlockedNow,
      unlockedAt: unlockedNow ? now : null,
      unlockedSeasonYear: unlockedNow ? seasonYear : null,
      contextNote: contextNote ?? current.contextNote,
      timesTriggered: unlockedNow ? current.timesTriggered + 1 : 0,
    );

    if (unlockedNow) {
      newlyUnlocked.add(
        CareerTrophyUnlockEvent(
          achievementId: def.id,
          title: def.title,
          description: def.description,
          tier: def.tier,
          category: def.category,
          pointsAwarded: def.points,
          isPlatinumTrophy: false,
          unlockedAt: now,
          seasonYear: seasonYear,
          contextNote: contextNote,
        ),
      );
    }

    final nextPlatinum = recomputePlatinum(
      nextProgress,
      unlockedAt: now,
      unlockedSeasonYear: seasonYear,
      existingUnlockedAt: state.platinumTrophy.unlockedAt,
      existingSeasonYear: state.platinumTrophy.unlockedSeasonYear,
    );
    final platinumJustUnlocked =
        !state.platinumTrophy.isUnlocked && nextPlatinum.isUnlocked;

    if (platinumJustUnlocked) {
      newlyUnlocked.add(
        CareerTrophyUnlockEvent(
          achievementId: PlatinumTrophyRecord.platinumId,
          title: PlatinumTrophyRecord.platinumTitle,
          description: PlatinumTrophyRecord.platinumDescription,
          tier: CareerAchievementTier.legendary,
          category: CareerAchievementCategory.beAProAndSpecialDisciplines,
          pointsAwarded: PlatinumTrophyRecord.platinumBonusPoints,
          isPlatinumTrophy: true,
          unlockedAt: now,
          seasonYear: seasonYear,
          contextNote: '60 / 60 Osiągnięć Odblokowanych',
        ),
      );
    }

    final nextState = state.copyWith(
      progressById: nextProgress,
      unlockHistory: [...state.unlockHistory, ...newlyUnlocked],
      pendingToastQueue: [...state.pendingToastQueue, ...newlyUnlocked],
      platinumTrophy: nextPlatinum,
    );

    return CareerAchievementEvaluationResult(
      nextState: nextState,
      newlyUnlocked: newlyUnlocked,
      platinumJustUnlocked: platinumJustUnlocked,
    );
  }

  /// Wylicza podsumowanie statystyczne dla ekranu i HUD.
  static CareerAchievementsSummary summarize(
    CareerAchievementsEngineState state,
  ) {
    final unlockedByTier = <CareerAchievementTier, int>{
      for (final t in CareerAchievementTier.values) t: 0,
    };
    final totalByTier = <CareerAchievementTier, int>{
      for (final t in CareerAchievementTier.values) t: 0,
    };
    final unlockedByCategory = <CareerAchievementCategory, int>{
      for (final c in CareerAchievementCategory.values) c: 0,
    };
    final totalByCategory = <CareerAchievementCategory, int>{
      for (final c in CareerAchievementCategory.values) c: 0,
    };

    int unlockedCount = 0;
    int inProgressCount = 0;
    int lockedCount = 0;

    for (final def in catalog) {
      totalByTier[def.tier] = (totalByTier[def.tier] ?? 0) + 1;
      totalByCategory[def.category] = (totalByCategory[def.category] ?? 0) + 1;

      final prog = state.progressById[def.id];
      if (prog != null && prog.isUnlocked) {
        unlockedCount++;
        unlockedByTier[def.tier] = (unlockedByTier[def.tier] ?? 0) + 1;
        unlockedByCategory[def.category] =
            (unlockedByCategory[def.category] ?? 0) + 1;
      } else if (prog != null && prog.isInProgress) {
        inProgressCount++;
        lockedCount++;
      } else {
        lockedCount++;
      }
    }

    return CareerAchievementsSummary(
      totalCount: catalog.length,
      unlockedCount: unlockedCount,
      inProgressCount: inProgressCount,
      lockedCount: lockedCount,
      totalPointsEarned: state.platinumTrophy.totalPointsEarned,
      maxPossiblePoints: state.platinumTrophy.maxPossiblePoints,
      unlockedByTier: unlockedByTier,
      totalByTier: totalByTier,
      unlockedByCategory: unlockedByCategory,
      totalByCategory: totalByCategory,
      platinumTrophy: state.platinumTrophy,
    );
  }

  /// Filtruje katalog 60 osiągnięć wg kategorii, rangi, statusu oraz frazy wyszukiwania.
  static List<CareerAchievementDefinition> filterCatalog(
    CareerAchievementsEngineState state, {
    CareerAchievementCategory? category,
    CareerAchievementTier? tier,
    CareerAchievementFilterMode filterMode = CareerAchievementFilterMode.all,
    String searchQuery = '',
  }) {
    final q = searchQuery.trim().toLowerCase();
    return catalog.where((def) {
      if (category != null && def.category != category) return false;
      if (tier != null && def.tier != tier) return false;

      final prog = state.progressById[def.id];
      final isUnlocked = prog?.isUnlocked ?? false;
      final isInProgress = prog?.isInProgress ?? false;

      switch (filterMode) {
        case CareerAchievementFilterMode.all:
          break;
        case CareerAchievementFilterMode.unlocked:
          if (!isUnlocked) return false;
        case CareerAchievementFilterMode.locked:
          if (isUnlocked) return false;
        case CareerAchievementFilterMode.inProgress:
          if (!isInProgress) return false;
        case CareerAchievementFilterMode.secret:
          if (!def.isSecret) return false;
      }

      if (q.isNotEmpty) {
        final inTitle = def.title.toLowerCase().contains(q);
        final inDesc =
            (!def.isSecret || isUnlocked) &&
            def.description.toLowerCase().contains(q);
        final inTrophy = def.trophyLabel.toLowerCase().contains(q);
        if (!inTitle && !inDesc && !inTrophy) return false;
      }

      return true;
    }).toList(growable: false);
  }
}

/// Notifier Riverpod zarządzający stanem 60 Osiągnięć i Platynowego Trofeum.
class CareerAchievementsNotifier
    extends StateNotifier<CareerAchievementsEngineState> {
  CareerAchievementsNotifier([CareerAchievementsEngineState? initial])
      : super(initial ?? CareerAchievementsEngineState.initial());

  List<CareerTrophyUnlockEvent> evaluate(
    CareerAchievementEvaluationInput input,
  ) {
    final result =
        CareerAchievementsAndTrophiesEngine.evaluateEvent(state, input);
    state = result.nextState;
    return result.newlyUnlocked;
  }

  List<CareerTrophyUnlockEvent> incrementProgress(
    String achievementId, {
    double delta = 1.0,
    int seasonYear = 2026,
    String? contextNote,
  }) {
    final result =
        CareerAchievementsAndTrophiesEngine.incrementAchievementProgress(
      state,
      achievementId,
      delta: delta,
      seasonYear: seasonYear,
      contextNote: contextNote,
    );
    state = result.nextState;
    return result.newlyUnlocked;
  }

  CareerTrophyUnlockEvent? consumeNextToast() {
    if (state.pendingToastQueue.isEmpty) return null;
    final next = state.pendingToastQueue.first;
    state = state.copyWith(
      pendingToastQueue: state.pendingToastQueue.sublist(1),
    );
    return next;
  }

  void clearToastQueue() {
    if (state.pendingToastQueue.isEmpty) return;
    state = state.copyWith(pendingToastQueue: const []);
  }

  void importFromJson(Map<String, dynamic> json) {
    state = CareerAchievementsEngineState.fromJson(json);
  }

  Map<String, dynamic> exportToJson() => state.toJson();

  void resetProgress() {
    state = CareerAchievementsEngineState.initial();
  }
}

final careerAchievementsProvider = StateNotifierProvider<
    CareerAchievementsNotifier, CareerAchievementsEngineState>(
  (ref) => CareerAchievementsNotifier(),
);

/// Produkcyjny, responsywny panel przeglądu 60 Osiągnięć i Platynowego Trofeum.
class CareerAchievementsAndTrophiesPanel extends ConsumerStatefulWidget {
  final bool readOnly;
  final VoidCallback? onOpenPlatinumShowcase;

  const CareerAchievementsAndTrophiesPanel({
    super.key,
    this.readOnly = false,
    this.onOpenPlatinumShowcase,
  });

  @override
  ConsumerState<CareerAchievementsAndTrophiesPanel> createState() =>
      _CareerAchievementsAndTrophiesPanelState();
}

class _CareerAchievementsAndTrophiesPanelState
    extends ConsumerState<CareerAchievementsAndTrophiesPanel> {
  CareerAchievementCategory? _selectedCategory;
  CareerAchievementTier? _selectedTier;
  CareerAchievementFilterMode _filterMode = CareerAchievementFilterMode.all;
  String _searchQuery = '';
  String? _focusedAchievementId;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(careerAchievementsProvider);
    final summary = CareerAchievementsAndTrophiesEngine.summarize(engineState);
    final filtered = CareerAchievementsAndTrophiesEngine.filterCatalog(
      engineState,
      category: _selectedCategory,
      tier: _selectedTier,
      filterMode: _filterMode,
      searchQuery: _searchQuery,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 640;
        final isTablet = width >= 640 && width < 1100;
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlatinumTrophyHeaderCard(
                  summary: summary,
                  isMobile: isMobile,
                  readOnly: widget.readOnly,
                  onTapShowcase: widget.onOpenPlatinumShowcase,
                ),
                const SizedBox(height: 16),
                _FiltersToolbar(
                  searchController: _searchController,
                  selectedCategory: _selectedCategory,
                  selectedTier: _selectedTier,
                  filterMode: _filterMode,
                  isMobile: isMobile,
                  readOnly: widget.readOnly,
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  onCategoryChanged: (c) =>
                      setState(() => _selectedCategory = c),
                  onTierChanged: (t) => setState(() => _selectedTier = t),
                  onFilterModeChanged: (m) => setState(() => _filterMode = m),
                  onResetFilters: () {
                    _searchController.clear();
                    setState(() {
                      _selectedCategory = null;
                      _selectedTier = null;
                      _filterMode = CareerAchievementFilterMode.all;
                      _searchQuery = '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  _EmptyAchievementsState(
                    onReset: () {
                      _searchController.clear();
                      setState(() {
                        _selectedCategory = null;
                        _selectedTier = null;
                        _filterMode = CareerAchievementFilterMode.all;
                        _searchQuery = '';
                      });
                    },
                  )
                else
                  _AchievementsResponsiveGrid(
                    definitions: filtered,
                    engineState: engineState,
                    crossAxisCount: crossAxisCount,
                    focusedId: _focusedAchievementId,
                    readOnly: widget.readOnly,
                    onSelect: (id) {
                      setState(() {
                        _focusedAchievementId =
                            _focusedAchievementId == id ? null : id;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlatinumTrophyHeaderCard extends StatefulWidget {
  final CareerAchievementsSummary summary;
  final bool isMobile;
  final bool readOnly;
  final VoidCallback? onTapShowcase;

  const _PlatinumTrophyHeaderCard({
    required this.summary,
    required this.isMobile,
    required this.readOnly,
    this.onTapShowcase,
  });

  @override
  State<_PlatinumTrophyHeaderCard> createState() =>
      _PlatinumTrophyHeaderCardState();
}

class _PlatinumTrophyHeaderCardState extends State<_PlatinumTrophyHeaderCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final platinum = widget.summary.platinumTrophy;
    final accent =
        platinum.isUnlocked ? AppColors.cyanAccent : AppColors.goldAccent;
    final interactive = !widget.readOnly && widget.onTapShowcase != null;

    return FocusableActionDetector(
      enabled: interactive,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: interactive ? widget.onTapShowcase : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused || _hovered
                  ? accent
                  : (platinum.isUnlocked
                      ? AppColors.cyanAccent
                      : AppColors.cardBorder),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: Icon(
                      platinum.isUnlocked
                          ? Icons.auto_awesome_rounded
                          : Icons.emoji_events_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          PlatinumTrophyRecord.platinumTitle,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          platinum.isUnlocked
                              ? 'Platyna odblokowana! (+${PlatinumTrophyRecord.platinumBonusPoints} pkt)'
                              : 'Odblokuj wszystkie 60 osiągnięć, aby zdobyć Platynowe Trofeum',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isMobile) ...[
                    const SizedBox(width: 12),
                    _ScorePill(
                      label:
                          '${widget.summary.unlockedCount} / ${widget.summary.totalCount}',
                      sublabel: '${widget.summary.totalPointsEarned} pkt',
                      color: accent,
                    ),
                  ],
                ],
              ),
              if (widget.isMobile) ...[
                const SizedBox(height: 12),
                _ScorePill(
                  label:
                      '${widget.summary.unlockedCount} / ${widget.summary.totalCount} odblokowanych',
                  sublabel: '${widget.summary.totalPointsEarned} pkt',
                  color: accent,
                ),
              ],
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: platinum.progressRatio,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CareerAchievementTier.values.map((tier) {
                  final unlocked = widget.summary.unlockedByTier[tier] ?? 0;
                  final total = widget.summary.totalByTier[tier] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: tier.color.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '${tier.labelPl}: $unlocked/$total',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tier.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _ScorePill({
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final CareerAchievementCategory? selectedCategory;
  final CareerAchievementTier? selectedTier;
  final CareerAchievementFilterMode filterMode;
  final bool isMobile;
  final bool readOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CareerAchievementCategory?> onCategoryChanged;
  final ValueChanged<CareerAchievementTier?> onTierChanged;
  final ValueChanged<CareerAchievementFilterMode> onFilterModeChanged;
  final VoidCallback onResetFilters;

  const _FiltersToolbar({
    required this.searchController,
    required this.selectedCategory,
    required this.selectedTier,
    required this.filterMode,
    required this.isMobile,
    required this.readOnly,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onTierChanged,
    required this.onFilterModeChanged,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            enabled: !readOnly,
            onChanged: onSearchChanged,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj osiągnięcia lub trofeum...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 18,
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
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'Wszystkie',
                selected: filterMode == CareerAchievementFilterMode.all,
                disabled: readOnly,
                onTap: () => onFilterModeChanged(CareerAchievementFilterMode.all),
              ),
              _FilterChipButton(
                label: 'Odblokowane',
                selected: filterMode == CareerAchievementFilterMode.unlocked,
                disabled: readOnly,
                onTap: () =>
                    onFilterModeChanged(CareerAchievementFilterMode.unlocked),
              ),
              _FilterChipButton(
                label: 'W trakcie',
                selected: filterMode == CareerAchievementFilterMode.inProgress,
                disabled: readOnly,
                onTap: () =>
                    onFilterModeChanged(CareerAchievementFilterMode.inProgress),
              ),
              _FilterChipButton(
                label: 'Zablokowane',
                selected: filterMode == CareerAchievementFilterMode.locked,
                disabled: readOnly,
                onTap: () =>
                    onFilterModeChanged(CareerAchievementFilterMode.locked),
              ),
              _FilterChipButton(
                label: 'Sekretne',
                selected: filterMode == CareerAchievementFilterMode.secret,
                disabled: readOnly,
                onTap: () =>
                    onFilterModeChanged(CareerAchievementFilterMode.secret),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'Wszystkie kategorie',
                selected: selectedCategory == null,
                disabled: readOnly,
                onTap: () => onCategoryChanged(null),
              ),
              ...CareerAchievementCategory.values.map(
                (cat) => _FilterChipButton(
                  label: cat.labelPl,
                  selected: selectedCategory == cat,
                  disabled: readOnly,
                  onTap: () => onCategoryChanged(
                    selectedCategory == cat ? null : cat,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...CareerAchievementTier.values.map(
                (tier) => _FilterChipButton(
                  label: tier.labelPl,
                  selected: selectedTier == tier,
                  disabled: readOnly,
                  accentColor: tier.color,
                  onTap: () => onTierChanged(
                    selectedTier == tier ? null : tier,
                  ),
                ),
              ),
              if (selectedCategory != null ||
                  selectedTier != null ||
                  filterMode != CareerAchievementFilterMode.all ||
                  searchController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: readOnly ? null : onResetFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Wyczyść'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.disabled,
    this.accentColor = AppColors.goldAccent,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? widget.accentColor.withValues(alpha: 0.18)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.background);
    final border = widget.disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : widget.selected || _focused
            ? widget.accentColor
            : (_hovered
                ? AppColors.textSecondary.withValues(alpha: 0.6)
                : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: _pressed ? 0.96 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                color: widget.disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : (widget.selected
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

class _AchievementsResponsiveGrid extends StatelessWidget {
  final List<CareerAchievementDefinition> definitions;
  final CareerAchievementsEngineState engineState;
  final int crossAxisCount;
  final String? focusedId;
  final bool readOnly;
  final ValueChanged<String> onSelect;

  const _AchievementsResponsiveGrid({
    required this.definitions,
    required this.engineState,
    required this.crossAxisCount,
    required this.focusedId,
    required this.readOnly,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < definitions.length; i += crossAxisCount) {
      final slice = definitions.skip(i).take(crossAxisCount).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int col = 0; col < crossAxisCount; col++) ...[
                if (col > 0) const SizedBox(width: 12),
                Expanded(
                  child: col < slice.length
                      ? _AchievementCard(
                          definition: slice[col],
                          progress: engineState.progressById[slice[col].id] ??
                              CareerAchievementProgress(
                                achievementId: slice[col].id,
                                currentValue: 0,
                                targetValue: slice[col].targetValue,
                                isUnlocked: false,
                              ),
                          isSelected: focusedId == slice[col].id,
                          readOnly: readOnly,
                          onTap: () => onSelect(slice[col].id),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _AchievementCard extends StatefulWidget {
  final CareerAchievementDefinition definition;
  final CareerAchievementProgress progress;
  final bool isSelected;
  final bool readOnly;
  final VoidCallback onTap;

  const _AchievementCard({
    required this.definition,
    required this.progress,
    required this.isSelected,
    required this.readOnly,
    required this.onTap,
  });

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final prog = widget.progress;
    final tierColor = def.tier.color;
    final unlocked = prog.isUnlocked;
    final hideSecretDesc = def.isSecret && !unlocked;

    return FocusableActionDetector(
      enabled: !widget.readOnly,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown:
            widget.readOnly ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.readOnly ? null : widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: _pressed ? 0.985 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unlocked ? AppColors.surface : AppColors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected || _focused
                    ? tierColor
                    : (_hovered
                        ? tierColor.withValues(alpha: 0.65)
                        : (unlocked
                            ? tierColor.withValues(alpha: 0.45)
                            : AppColors.cardBorder)),
                width: widget.isSelected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? tierColor.withValues(alpha: 0.16)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: unlocked
                              ? tierColor.withValues(alpha: 0.5)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Icon(
                        hideSecretDesc ? Icons.lock_outline_rounded : def.icon,
                        color: unlocked ? tierColor : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${def.codeNumber.toString().padLeft(2, '0')} ${def.title}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: unlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${def.tier.labelPl} • ${def.points} pkt',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tierColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      unlocked
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: unlocked
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  hideSecretDesc
                      ? 'Sekretne osiągnięcie — odkryj w trakcie kariery.'
                      : def.description,
                  maxLines: widget.isSelected ? 6 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: prog.progressRatio,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      unlocked ? AppColors.statusSuccess : tierColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        def.trophyLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${prog.currentValue.toInt()} / ${prog.targetValue.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                if (widget.isSelected && prog.contextNote != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prog.contextNote!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.goldAccent,
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

class _EmptyAchievementsState extends StatelessWidget {
  final VoidCallback onReset;

  const _EmptyAchievementsState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak osiągnięć spełniających wybrane filtry.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onReset,
            child: const Text('Pokaż wszystkie 60 osiągnięć'),
          ),
        ],
      ),
    );
  }
}
