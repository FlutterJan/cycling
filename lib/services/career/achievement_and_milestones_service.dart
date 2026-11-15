import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/career_save.dart';
import '../../models/team/cycling_team.dart';

/// Ranga osiągnięcia / kamienia milowego kariery menedżera.
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinumLegend;

  String toJson() => name;

  static AchievementTier fromJson(String value) {
    return AchievementTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AchievementTier.bronze,
    );
  }

  String get label {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinumLegend:
        return 'Platinum Legend';
    }
  }

  int get points {
    switch (this) {
      case AchievementTier.bronze:
        return 15;
      case AchievementTier.silver:
        return 30;
      case AchievementTier.gold:
        return 60;
      case AchievementTier.platinumLegend:
        return 120;
    }
  }

  Color get badgeColor {
    switch (this) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C7D1);
      case AchievementTier.gold:
        return AppColors.goldAccent;
      case AchievementTier.platinumLegend:
        return AppColors.cyanAccent;
    }
  }

  IconData get tierIcon {
    switch (this) {
      case AchievementTier.bronze:
        return Icons.workspace_premium_outlined;
      case AchievementTier.silver:
        return Icons.workspace_premium_rounded;
      case AchievementTier.gold:
        return Icons.emoji_events_rounded;
      case AchievementTier.platinumLegend:
        return Icons.auto_awesome_rounded;
    }
  }
}

/// Kategoria wyzwania kolarskiego.
enum AchievementCategory {
  tactics,
  monumentsAndTours,
  equipmentAndAero,
  physiologyAndTraining,
  managementAndLegacy;

  String get label {
    switch (this) {
      case AchievementCategory.tactics:
        return 'Taktyka i Wyścig';
      case AchievementCategory.monumentsAndTours:
        return 'Monumenty i Wielkie Toury';
      case AchievementCategory.equipmentAndAero:
        return 'Sprzęt i Tunel Aero';
      case AchievementCategory.physiologyAndTraining:
        return 'Fizjologia i Trening';
      case AchievementCategory.managementAndLegacy:
        return 'Zarządzanie i Dziedzictwo';
    }
  }
}

/// Definicja pojedynczego osiągnięcia lub kamienia milowego kariery.
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final AchievementTier tier;
  final AchievementCategory category;
  final IconData icon;
  final double targetValue;
  final bool isSecret;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.category,
    required this.icon,
    this.targetValue = 1.0,
    this.isSecret = false,
  });

  int get points => tier.points;
}

/// Rekord postępu i odblokowania konkretnego osiągnięcia.
class AchievementProgressRecord {
  final String achievementId;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double currentValue;
  final double targetValue;
  final int? unlockedSeasonYear;
  final String? contextNote;

  const AchievementProgressRecord({
    required this.achievementId,
    required this.isUnlocked,
    this.unlockedAt,
    required this.currentValue,
    required this.targetValue,
    this.unlockedSeasonYear,
    this.contextNote,
  });

  double get progressRatio {
    if (targetValue <= 0) return isUnlocked ? 1.0 : 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  AchievementProgressRecord copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? currentValue,
    double? targetValue,
    int? unlockedSeasonYear,
    String? contextNote,
  }) {
    return AchievementProgressRecord(
      achievementId: achievementId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unlockedSeasonYear: unlockedSeasonYear ?? this.unlockedSeasonYear,
      contextNote: contextNote ?? this.contextNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'currentValue': currentValue,
      'targetValue': targetValue,
      'unlockedSeasonYear': unlockedSeasonYear,
      'contextNote': contextNote,
    };
  }

  factory AchievementProgressRecord.fromJson(Map<String, dynamic> json) {
    return AchievementProgressRecord(
      achievementId: json['achievementId'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
      unlockedSeasonYear: (json['unlockedSeasonYear'] as num?)?.toInt(),
      contextNote: json['contextNote'] as String?,
    );
  }
}

/// Zdarzenie emitowane w momencie odblokowania osiągnięcia (dla Toast UI i logów).
class AchievementUnlockEvent {
  final AchievementDefinition achievement;
  final DateTime unlockedAt;
  final int seasonYear;
  final String? contextLabel;

  const AchievementUnlockEvent({
    required this.achievement,
    required this.unlockedAt,
    required this.seasonYear,
    this.contextLabel,
  });
}

/// Dane wejściowe z zakończenia etapu do automatycznej ewaluacji osiągnięć.
class StageEvaluationContext {
  final String raceId;
  final String raceName;
  final bool stageWon;
  final bool isGrandTourStage;
  final bool isMonument;
  final bool isCobbleMonument;
  final bool isStradeBiancheOrGravel;
  final bool isMountainSummitFinish;
  final bool isTimeTrial;
  final bool isTeamTimeTrial;
  final bool isSprintFinish;
  final bool isRainy;
  final bool isHighAltitudeAbove2000m;
  final double soloAttackDistanceKm;
  final bool echelonSplitAchieved;
  final int gapOverGcRivalSeconds;
  final int bikeChanges;
  final int teammateTop10Count;
  final bool wonFromBreakaway;
  final bool wonWithNegativeSplit;
  final bool wonOnDescentAttack;
  final bool wonWithZeroCrashes;
  final bool bonkAvoidedWithZeroDeficit;
  final double peakPowerWatts;
  final double? peakWPerKg20Min;
  final double stageAverageSpeedKmh;
  final double? winningMarginSeconds;
  final bool? wonByPhotoFinish;
  final double? bestTestedCdaM2;
  final bool optimalTirePressureApplied;
  final bool aeroWaxChainApplied;

  const StageEvaluationContext({
    this.raceId = '',
    this.raceName = '',
    this.stageWon = false,
    this.isGrandTourStage = false,
    this.isMonument = false,
    this.isCobbleMonument = false,
    this.isStradeBiancheOrGravel = false,
    this.isMountainSummitFinish = false,
    this.isTimeTrial = false,
    this.isTeamTimeTrial = false,
    this.isSprintFinish = false,
    this.isRainy = false,
    this.isHighAltitudeAbove2000m = false,
    this.soloAttackDistanceKm = 0.0,
    this.echelonSplitAchieved = false,
    this.gapOverGcRivalSeconds = 0,
    this.bikeChanges = 0,
    this.teammateTop10Count = 0,
    this.wonFromBreakaway = false,
    this.wonWithNegativeSplit = false,
    this.wonOnDescentAttack = false,
    this.wonWithZeroCrashes = true,
    this.bonkAvoidedWithZeroDeficit = false,
    this.peakPowerWatts = 0.0,
    this.peakWPerKg20Min,
    this.stageAverageSpeedKmh = 0.0,
    this.winningMarginSeconds,
    this.wonByPhotoFinish,
    this.bestTestedCdaM2,
    this.optimalTirePressureApplied = false,
    this.aeroWaxChainApplied = false,
  });
}

/// Dane wejściowe z podsumowania sezonu do automatycznej ewaluacji osiągnięć.
class SeasonEvaluationContext {
  final int seasonYear;
  final TeamDivision startedDivision;
  final TeamDivision currentDivision;
  final bool promotedToProTeam;
  final bool promotedToWorldTour;
  final int seasonTotalWins;
  final int grandTourGcWins;
  final int grandTourPointsJerseys;
  final int grandTourKomJerseys;
  final int grandTourYouthJerseys;
  final bool wonAllThreeGrandToursInCareer;
  final Set<String> distinctMonumentIdsWon;
  final int worldChampionshipRoadWins;
  final int worldChampionshipTtWins;
  final int olympicGoldWins;
  final int nationalChampionshipWins;
  final int worldTourStageRaceGcWins;
  final double sponsorObjectivesCompletedRatio;
  final int youthAcademyGraduatesPromoted;
  final int youthAcademyGraduateRaceWins;
  final int altitudeCampsCompleted;
  final int totalSeasonsCompleted;
  final bool cleanBiologicalPassportAllSeason;
  final double? bestTimeTrialCdaM2;
  final bool zeroInjuriesInGrandTour;

  const SeasonEvaluationContext({
    required this.seasonYear,
    this.startedDivision = TeamDivision.continental,
    this.currentDivision = TeamDivision.worldTour,
    this.promotedToProTeam = false,
    this.promotedToWorldTour = false,
    this.seasonTotalWins = 0,
    this.grandTourGcWins = 0,
    this.grandTourPointsJerseys = 0,
    this.grandTourKomJerseys = 0,
    this.grandTourYouthJerseys = 0,
    this.wonAllThreeGrandToursInCareer = false,
    this.distinctMonumentIdsWon = const {},
    this.worldChampionshipRoadWins = 0,
    this.worldChampionshipTtWins = 0,
    this.olympicGoldWins = 0,
    this.nationalChampionshipWins = 0,
    this.worldTourStageRaceGcWins = 0,
    this.sponsorObjectivesCompletedRatio = 0.0,
    this.youthAcademyGraduatesPromoted = 0,
    this.youthAcademyGraduateRaceWins = 0,
    this.altitudeCampsCompleted = 0,
    this.totalSeasonsCompleted = 1,
    this.cleanBiologicalPassportAllSeason = true,
    this.bestTimeTrialCdaM2,
    this.zeroInjuriesInGrandTour = false,
  });
}

/// Skumulowane statystyki kariery wykorzystywane przez serwis osiągnięć.
class CareerAchievementMetrics {
  final int totalStageAndRaceWins;
  final int grandTourStageWins;
  final int grandTourGcWins;
  final int monumentsWonCount;
  final int worldTourStageRaceGcWins;
  final int sprintStageWins;
  final int timeTrialWins;
  final int mountainStageWins;
  final int breakawayWins;
  final int altitudeCampsCompleted;
  final int youthGraduatesPromoted;
  final int youthGraduateWins;
  final double? bestTimeTrialCdaM2;
  final TeamDivision startingDivision;
  final bool everPromotedToWorldTour;
  final bool wonAllThreeGrandTours;
  final Set<String> distinctMonumentIdsWon;
  final int worldRoadChampionTitles;
  final int worldTtChampionTitles;
  final int olympicGoldMedals;
  final int nationalChampionTitles;
  final int grandTourPointsJerseys;
  final int grandTourKomJerseys;
  final int grandTourYouthJerseys;
  final int seasonsCompleted;

  const CareerAchievementMetrics({
    this.totalStageAndRaceWins = 0,
    this.grandTourStageWins = 0,
    this.grandTourGcWins = 0,
    this.monumentsWonCount = 0,
    this.worldTourStageRaceGcWins = 0,
    this.sprintStageWins = 0,
    this.timeTrialWins = 0,
    this.mountainStageWins = 0,
    this.breakawayWins = 0,
    this.altitudeCampsCompleted = 0,
    this.youthGraduatesPromoted = 0,
    this.youthGraduateWins = 0,
    this.bestTimeTrialCdaM2,
    this.startingDivision = TeamDivision.continental,
    this.everPromotedToWorldTour = false,
    this.wonAllThreeGrandTours = false,
    this.distinctMonumentIdsWon = const {},
    this.worldRoadChampionTitles = 0,
    this.worldTtChampionTitles = 0,
    this.olympicGoldMedals = 0,
    this.nationalChampionTitles = 0,
    this.grandTourPointsJerseys = 0,
    this.grandTourKomJerseys = 0,
    this.grandTourYouthJerseys = 0,
    this.seasonsCompleted = 0,
  });

  CareerAchievementMetrics copyWith({
    int? totalStageAndRaceWins,
    int? grandTourStageWins,
    int? grandTourGcWins,
    int? monumentsWonCount,
    int? worldTourStageRaceGcWins,
    int? sprintStageWins,
    int? timeTrialWins,
    int? mountainStageWins,
    int? breakawayWins,
    int? altitudeCampsCompleted,
    int? youthGraduatesPromoted,
    int? youthGraduateWins,
    double? bestTimeTrialCdaM2,
    TeamDivision? startingDivision,
    bool? everPromotedToWorldTour,
    bool? wonAllThreeGrandTours,
    Set<String>? distinctMonumentIdsWon,
    int? worldRoadChampionTitles,
    int? worldTtChampionTitles,
    int? olympicGoldMedals,
    int? nationalChampionTitles,
    int? grandTourPointsJerseys,
    int? grandTourKomJerseys,
    int? grandTourYouthJerseys,
    int? seasonsCompleted,
  }) {
    return CareerAchievementMetrics(
      totalStageAndRaceWins:
          totalStageAndRaceWins ?? this.totalStageAndRaceWins,
      grandTourStageWins: grandTourStageWins ?? this.grandTourStageWins,
      grandTourGcWins: grandTourGcWins ?? this.grandTourGcWins,
      monumentsWonCount: monumentsWonCount ?? this.monumentsWonCount,
      worldTourStageRaceGcWins:
          worldTourStageRaceGcWins ?? this.worldTourStageRaceGcWins,
      sprintStageWins: sprintStageWins ?? this.sprintStageWins,
      timeTrialWins: timeTrialWins ?? this.timeTrialWins,
      mountainStageWins: mountainStageWins ?? this.mountainStageWins,
      breakawayWins: breakawayWins ?? this.breakawayWins,
      altitudeCampsCompleted:
          altitudeCampsCompleted ?? this.altitudeCampsCompleted,
      youthGraduatesPromoted:
          youthGraduatesPromoted ?? this.youthGraduatesPromoted,
      youthGraduateWins: youthGraduateWins ?? this.youthGraduateWins,
      bestTimeTrialCdaM2: bestTimeTrialCdaM2 ?? this.bestTimeTrialCdaM2,
      startingDivision: startingDivision ?? this.startingDivision,
      everPromotedToWorldTour:
          everPromotedToWorldTour ?? this.everPromotedToWorldTour,
      wonAllThreeGrandTours:
          wonAllThreeGrandTours ?? this.wonAllThreeGrandTours,
      distinctMonumentIdsWon:
          distinctMonumentIdsWon ?? this.distinctMonumentIdsWon,
      worldRoadChampionTitles:
          worldRoadChampionTitles ?? this.worldRoadChampionTitles,
      worldTtChampionTitles:
          worldTtChampionTitles ?? this.worldTtChampionTitles,
      olympicGoldMedals: olympicGoldMedals ?? this.olympicGoldMedals,
      nationalChampionTitles:
          nationalChampionTitles ?? this.nationalChampionTitles,
      grandTourPointsJerseys:
          grandTourPointsJerseys ?? this.grandTourPointsJerseys,
      grandTourKomJerseys: grandTourKomJerseys ?? this.grandTourKomJerseys,
      grandTourYouthJerseys:
          grandTourYouthJerseys ?? this.grandTourYouthJerseys,
      seasonsCompleted: seasonsCompleted ?? this.seasonsCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStageAndRaceWins': totalStageAndRaceWins,
      'grandTourStageWins': grandTourStageWins,
      'grandTourGcWins': grandTourGcWins,
      'monumentsWonCount': monumentsWonCount,
      'worldTourStageRaceGcWins': worldTourStageRaceGcWins,
      'sprintStageWins': sprintStageWins,
      'timeTrialWins': timeTrialWins,
      'mountainStageWins': mountainStageWins,
      'breakawayWins': breakawayWins,
      'altitudeCampsCompleted': altitudeCampsCompleted,
      'youthGraduatesPromoted': youthGraduatesPromoted,
      'youthGraduateWins': youthGraduateWins,
      'bestTimeTrialCdaM2': bestTimeTrialCdaM2,
      'startingDivision': startingDivision.toJson(),
      'everPromotedToWorldTour': everPromotedToWorldTour,
      'wonAllThreeGrandTours': wonAllThreeGrandTours,
      'distinctMonumentIdsWon': distinctMonumentIdsWon.toList(),
      'worldRoadChampionTitles': worldRoadChampionTitles,
      'worldTtChampionTitles': worldTtChampionTitles,
      'olympicGoldMedals': olympicGoldMedals,
      'nationalChampionTitles': nationalChampionTitles,
      'grandTourPointsJerseys': grandTourPointsJerseys,
      'grandTourKomJerseys': grandTourKomJerseys,
      'grandTourYouthJerseys': grandTourYouthJerseys,
      'seasonsCompleted': seasonsCompleted,
    };
  }

  factory CareerAchievementMetrics.fromJson(Map<String, dynamic> json) {
    return CareerAchievementMetrics(
      totalStageAndRaceWins:
          (json['totalStageAndRaceWins'] as num?)?.toInt() ?? 0,
      grandTourStageWins: (json['grandTourStageWins'] as num?)?.toInt() ?? 0,
      grandTourGcWins: (json['grandTourGcWins'] as num?)?.toInt() ?? 0,
      monumentsWonCount: (json['monumentsWonCount'] as num?)?.toInt() ?? 0,
      worldTourStageRaceGcWins:
          (json['worldTourStageRaceGcWins'] as num?)?.toInt() ?? 0,
      sprintStageWins: (json['sprintStageWins'] as num?)?.toInt() ?? 0,
      timeTrialWins: (json['timeTrialWins'] as num?)?.toInt() ?? 0,
      mountainStageWins: (json['mountainStageWins'] as num?)?.toInt() ?? 0,
      breakawayWins: (json['breakawayWins'] as num?)?.toInt() ?? 0,
      altitudeCampsCompleted:
          (json['altitudeCampsCompleted'] as num?)?.toInt() ?? 0,
      youthGraduatesPromoted:
          (json['youthGraduatesPromoted'] as num?)?.toInt() ?? 0,
      youthGraduateWins: (json['youthGraduateWins'] as num?)?.toInt() ?? 0,
      bestTimeTrialCdaM2: (json['bestTimeTrialCdaM2'] as num?)?.toDouble(),
      startingDivision: json['startingDivision'] != null
          ? TeamDivision.fromJson(json['startingDivision'] as String)
          : TeamDivision.continental,
      everPromotedToWorldTour:
          json['everPromotedToWorldTour'] as bool? ?? false,
      wonAllThreeGrandTours: json['wonAllThreeGrandTours'] as bool? ?? false,
      distinctMonumentIdsWon:
          (json['distinctMonumentIdsWon'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              const {},
      worldRoadChampionTitles:
          (json['worldRoadChampionTitles'] as num?)?.toInt() ?? 0,
      worldTtChampionTitles:
          (json['worldTtChampionTitles'] as num?)?.toInt() ?? 0,
      olympicGoldMedals: (json['olympicGoldMedals'] as num?)?.toInt() ?? 0,
      nationalChampionTitles:
          (json['nationalChampionTitles'] as num?)?.toInt() ?? 0,
      grandTourPointsJerseys:
          (json['grandTourPointsJerseys'] as num?)?.toInt() ?? 0,
      grandTourKomJerseys: (json['grandTourKomJerseys'] as num?)?.toInt() ?? 0,
      grandTourYouthJerseys:
          (json['grandTourYouthJerseys'] as num?)?.toInt() ?? 0,
      seasonsCompleted: (json['seasonsCompleted'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Serwis zarządzający 45 osiągnięciami i kamieniami milowymi kariery menedżera.
///
/// Obsługuje 4 rangi (`Bronze`, `Silver`, `Gold`, `Platinum Legend`),
/// automatyczną ewaluację po każdym etapie i na koniec sezonu oraz strumień
/// zdarzeń odblokowania dla animowanego banera powiadomień (Toast).
class AchievementAndMilestonesService {
  static const int totalAchievementsCount = 45;

  final StreamController<AchievementUnlockEvent> _unlockController =
      StreamController<AchievementUnlockEvent>.broadcast();

  final Map<String, AchievementProgressRecord> _records = {};
  CareerAchievementMetrics _metrics = const CareerAchievementMetrics();

  AchievementAndMilestonesService() {
    for (final def in definitions) {
      _records[def.id] = AchievementProgressRecord(
        achievementId: def.id,
        isUnlocked: false,
        currentValue: 0.0,
        targetValue: def.targetValue,
      );
    }
  }

  /// Strumień zdarzeń odblokowania osiągnięć (np. do wyświetlania Toasta).
  Stream<AchievementUnlockEvent> get unlockStream => _unlockController.stream;

  /// Aktualne skumulowane metryki kariery.
  CareerAchievementMetrics get metrics => _metrics;

  /// Mapa wszystkich rekordów postępu (tylko do odczytu).
  Map<String, AchievementProgressRecord> get progressRecords =>
      Map.unmodifiable(_records);

  /// Pełny katalog 45 zdefiniowanych osiągnięć menedżerskich i kolarskich.
  static final List<AchievementDefinition> definitions = List.unmodifiable([
    // =========================================================================
    // BRONZE (15 osiągnięć — pierwsze kroki i podstawy rzemiosła)
    // =========================================================================
    const AchievementDefinition(
      id: 'first_victory',
      title: 'Pierwsze Trofeum',
      description: 'Zdobądź pierwsze zwycięstwo etapowe lub klasyk w karierze.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.emoji_events_rounded,
    ),
    const AchievementDefinition(
      id: 'sprint_train_debut',
      title: 'Pociąg Sprinterski',
      description: 'Wygraj etap płaski po finiszu z peletonu.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.tactics,
      icon: Icons.bolt_rounded,
    ),
    const AchievementDefinition(
      id: 'breakaway_survivor',
      title: 'Uciekinier Dnia',
      description: 'Wygraj etap będąc w ucieczce dnia od wczesnych kilometrów.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.tactics,
      icon: Icons.directions_bike_rounded,
    ),
    const AchievementDefinition(
      id: 'photo_finish_millimeter',
      title: 'O Błysk Szprychy',
      description: 'Wygraj etap różnicą mniejszą niż 0.1 sekundy na fotofiniszu.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.tactics,
      icon: Icons.timer_rounded,
    ),
    const AchievementDefinition(
      id: 'tire_pressure_guru',
      title: 'Ciśnienie pod Kontrolą',
      description:
          'Zastosuj optymalne ciśnienie opon przed etapem i zakończ bez defektu.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.equipmentAndAero,
      icon: Icons.tire_repair_rounded,
    ),
    const AchievementDefinition(
      id: 'waxed_chain_efficiency',
      title: 'Woskowany Napęd',
      description:
          'Przygotuj rower z woskowanym łańcuchem i wygraj dowolny etap.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.equipmentAndAero,
      icon: Icons.settings_rounded,
    ),
    const AchievementDefinition(
      id: 'clean_sheet_no_crashes',
      title: 'Bezpieczny Peleton',
      description:
          'Wygraj deszczowy etap bez ani jednej kraksy w swojej drużynie.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.tactics,
      icon: Icons.shield_rounded,
    ),
    const AchievementDefinition(
      id: 'watt_bomb_1400',
      title: 'Bomba Watowa 1400W',
      description:
          'Wygeneruj kolarzem ponad 1400 W mocy szczytowej na finiszu etapu.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.physiologyAndTraining,
      icon: Icons.flash_on_rounded,
    ),
    const AchievementDefinition(
      id: 'zero_bonk_feeding',
      title: 'Mistrz Żywienia',
      description:
          'Ukończ zwycięski etap bez dopuszczenia do odcięcia glikogenu (bonk).',
      tier: AchievementTier.bronze,
      category: AchievementCategory.physiologyAndTraining,
      icon: Icons.local_cafe_rounded,
    ),
    const AchievementDefinition(
      id: 'first_altitude_camp',
      title: 'Powietrze Wysokich Gór',
      description: 'Zorganizuj i ukończ pierwsze zgrupowanie wysokogórskie.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.physiologyAndTraining,
      icon: Icons.terrain_rounded,
    ),
    const AchievementDefinition(
      id: 'youth_academy_promotion',
      title: 'Łowca Talentów',
      description:
          'Awansuj wychowanka z akademii U23 do pierwszego zespołu.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.school_rounded,
    ),
    const AchievementDefinition(
      id: 'service_course_upgrade',
      title: 'Baza Logistyczna Pro',
      description: 'Rozbuduj Service Course co najmniej do poziomu 3.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.equipmentAndAero,
      icon: Icons.warehouse_rounded,
      targetValue: 3.0,
    ),
    const AchievementDefinition(
      id: 'wind_tunnel_level_3',
      title: 'Inżynier Aerodynamiki',
      description: 'Rozbuduj Tunel Aerodynamiczny co najmniej do poziomu 3.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.equipmentAndAero,
      icon: Icons.air_rounded,
      targetValue: 3.0,
    ),
    const AchievementDefinition(
      id: 'medical_center_level_3',
      title: 'Klinika WorldTour',
      description: 'Rozbuduj Centrum Medyczne co najmniej do poziomu 3.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.physiologyAndTraining,
      icon: Icons.medical_services_rounded,
      targetValue: 3.0,
    ),
    const AchievementDefinition(
      id: 'ten_career_wins',
      title: 'Dziesiątka na Koncie',
      description: 'Zdobądź łącznie 10 zwycięstw drużynowych w karierze.',
      tier: AchievementTier.bronze,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.looks_one_rounded,
      targetValue: 10.0,
    ),

    // =========================================================================
    // SILVER (14 osiągnięć — mistrzowska taktyka i stabilność WorldTour)
    // =========================================================================
    const AchievementDefinition(
      id: 'solo_from_afar',
      title: 'Solo z Daleka',
      description:
          'Wygraj etap po samotnym ataku z dystansu ponad 50 km przed metą.',
      tier: AchievementTier.silver,
      category: AchievementCategory.tactics,
      icon: Icons.trending_up_rounded,
      targetValue: 50.0,
    ),
    const AchievementDefinition(
      id: 'echelon_master',
      title: 'Mistrz Rantów',
      description:
          'Rozerwij peleton na bocznym wietrze i przyjedź z przewagą ponad 2 minut nad głównym rywalem GC.',
      tier: AchievementTier.silver,
      category: AchievementCategory.tactics,
      icon: Icons.cyclone_rounded,
      targetValue: 120.0,
    ),
    const AchievementDefinition(
      id: 'descent_daredevil',
      title: 'Kamikadze na Zjeździe',
      description:
          'Wygraj etap górski po decydującym ataku na zjeździe.',
      tier: AchievementTier.silver,
      category: AchievementCategory.tactics,
      icon: Icons.south_east_rounded,
    ),
    const AchievementDefinition(
      id: 'negative_split_tt',
      title: 'Szwajcarski Zegarek',
      description:
          'Wygraj jazdę indywidualną na czas stosując taktykę negative split.',
      tier: AchievementTier.silver,
      category: AchievementCategory.tactics,
      icon: Icons.av_timer_rounded,
    ),
    const AchievementDefinition(
      id: 'ttt_harmony',
      title: 'Maszyna Czasowa TTT',
      description: 'Wygraj drużynową jazdę na czas (TTT).',
      tier: AchievementTier.silver,
      category: AchievementCategory.tactics,
      icon: Icons.groups_rounded,
    ),
    const AchievementDefinition(
      id: 'summit_queen_stage',
      title: 'Król Szczytów 2000m+',
      description:
          'Wygraj królewski etap górski z metą powyżej 2000 m n.p.m.',
      tier: AchievementTier.silver,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.landscape_rounded,
    ),
    const AchievementDefinition(
      id: 'strade_bianche_dust',
      title: 'Białe Drogi Toskanii',
      description: 'Zwycięż w klasyku szutrowym w stylu Strade Bianche.',
      tier: AchievementTier.silver,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.route_rounded,
    ),
    const AchievementDefinition(
      id: 'three_riders_top10',
      title: 'Dominacja Drużynowa',
      description:
          'Wprowadź co najmniej 3 kolarzy swojej drużyny do Top 10 jednego etapu.',
      tier: AchievementTier.silver,
      category: AchievementCategory.tactics,
      icon: Icons.diversity_3_rounded,
      targetValue: 3.0,
    ),
    const AchievementDefinition(
      id: 'stable_finances_2m',
      title: 'Stabilne Finanse',
      description: 'Utrzymuj ponad €2,000,000 na koncie drużyny.',
      tier: AchievementTier.silver,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.account_balance_wallet_rounded,
      targetValue: 2000000.0,
    ),
    const AchievementDefinition(
      id: 'national_champion_factory',
      title: 'Mistrzowie Krajowi',
      description: 'Zdobądź co najmniej 3 tytuły Mistrza Kraju w karierze.',
      tier: AchievementTier.silver,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.flag_rounded,
      targetValue: 3.0,
    ),
    const AchievementDefinition(
      id: 'academy_winner',
      title: 'Złoty Wychowanek',
      description:
          'Wychowanek Twojej akademii U23 wygrywa swój pierwszy zawodowy wyścig.',
      tier: AchievementTier.silver,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.star_half_rounded,
    ),
    const AchievementDefinition(
      id: 'high_speed_47_kmh',
      title: 'Ponad 47 km/h Średniej',
      description:
          'Wygraj etap ze średnią prędkością powyżej 47.0 km/h.',
      tier: AchievementTier.silver,
      category: AchievementCategory.equipmentAndAero,
      icon: Icons.speed_rounded,
      targetValue: 47.0,
    ),
    const AchievementDefinition(
      id: 'sponsor_perfection',
      title: 'Ulubieniec Sponsorów',
      description:
          'Zrealizuj 100% celów sponsorskich w trakcie jednego sezonu.',
      tier: AchievementTier.silver,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.handshake_rounded,
    ),
    const AchievementDefinition(
      id: 'elite_reputation_75',
      title: 'Elita WorldTour',
      description: 'Osiągnij reputację menedżerską 75+.',
      tier: AchievementTier.silver,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.military_tech_rounded,
      targetValue: 75.0,
    ),

    // =========================================================================
    // GOLD (10 osiągnięć — wielkie wyczyny i mistrzowska inżynieria)
    // =========================================================================
    const AchievementDefinition(
      id: 'king_of_hell_north',
      title: 'Król Piekła Północy',
      description:
          'Wygraj brukowany Monument w deszczu bez ani jednej wymiany roweru.',
      tier: AchievementTier.gold,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.thunderstorm_rounded,
    ),
    const AchievementDefinition(
      id: 'watt_engineer_cda',
      title: 'Inżynier Watów',
      description:
          'Osiągnij w tunelu aerodynamicznym współczynnik CdA < 0.190 m² dla kolarza czasowego.',
      tier: AchievementTier.gold,
      category: AchievementCategory.equipmentAndAero,
      icon: Icons.science_rounded,
    ),
    const AchievementDefinition(
      id: 'gt_stage_hat_trick',
      title: 'Hat-Trick Wielkiego Touru',
      description:
          'Wygraj co najmniej 3 etapy w jednym Wielkim Tourze lub w karierze GT.',
      tier: AchievementTier.gold,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.filter_3_rounded,
      targetValue: 3.0,
    ),
    const AchievementDefinition(
      id: 'first_grand_tour_gc',
      title: 'Żółta, Różowa lub Czerwona',
      description: 'Wygraj klasyfikację generalną (GC) Wielkiego Touru.',
      tier: AchievementTier.gold,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.looks_one_outlined,
    ),
    const AchievementDefinition(
      id: 'green_jersey_master',
      title: 'Król Punktów GT',
      description: 'Zdobądź klasyfikację punktową Wielkiego Touru.',
      tier: AchievementTier.gold,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.confirmation_number_rounded,
    ),
    const AchievementDefinition(
      id: 'kom_polka_dot',
      title: 'Orzeł Gór GT',
      description: 'Zdobądź klasyfikację górską (KOM) Wielkiego Touru.',
      tier: AchievementTier.gold,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.filter_hdr_rounded,
    ),
    const AchievementDefinition(
      id: 'rainbow_jersey_road',
      title: 'Tęczowa Koszulka UCI',
      description:
          'Twój kolarz zostaje Mistrzem Świata ze startu wspólnego.',
      tier: AchievementTier.gold,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.public_rounded,
    ),
    const AchievementDefinition(
      id: 'wt_stage_race_collector',
      title: 'Dominator Tygodniówek',
      description:
          'Wygraj 5 klasyfikacji generalnych wyścigów etapowych WorldTour.',
      tier: AchievementTier.gold,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.calendar_month_rounded,
      targetValue: 5.0,
    ),
    const AchievementDefinition(
      id: 'physiological_monster_63',
      title: 'Fenomen 6.3 W/kg',
      description:
          'Uzyskaj w trakcie etapu 20-minutową moc powyżej 6.3 W/kg.',
      tier: AchievementTier.gold,
      category: AchievementCategory.physiologyAndTraining,
      icon: Icons.monitor_heart_rounded,
      targetValue: 6.3,
    ),
    const AchievementDefinition(
      id: 'clean_sport_ambassador',
      title: 'Czysty Paszport Biologiczny',
      description:
          'Ukończ cały sezon bez żadnych nieprawidłowości w paszporcie biologicznym.',
      tier: AchievementTier.gold,
      category: AchievementCategory.physiologyAndTraining,
      icon: Icons.verified_user_rounded,
    ),

    // =========================================================================
    // PLATINUM LEGEND (6 osiągnięć — absolutna legenda kolarstwa)
    // =========================================================================
    const AchievementDefinition(
      id: 'from_zero_to_worldtour',
      title: 'Od Zera do WorldTouru',
      description:
          'Awansuj własnym zespołem z dywizji Continental do WorldTour i wygraj Wielki Tour.',
      tier: AchievementTier.platinumLegend,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.rocket_launch_rounded,
    ),
    const AchievementDefinition(
      id: 'all_five_monuments',
      title: 'Kolekcjoner 5 Monumentów',
      description:
          'Wygraj wszystkie pięć Monumentów kolarstwa (MSR, RVV, PR, LBL, Lombardia).',
      tier: AchievementTier.platinumLegend,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.diamond_rounded,
      targetValue: 5.0,
    ),
    const AchievementDefinition(
      id: 'triple_grand_tour_crown',
      title: 'Potrójna Korona Grand Tourów',
      description:
          'Zdobądź klasyfikację generalną Tour de France, Giro d’Italia oraz Vuelta a España.',
      tier: AchievementTier.platinumLegend,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.stars_rounded,
    ),
    const AchievementDefinition(
      id: 'olympic_and_world_double',
      title: 'Złoto Olimpijskie i Tęcza',
      description:
          'Zdobądź jednocześnie Złoty Medal Olimpijski oraz Tęczową Koszulkę MŚ.',
      tier: AchievementTier.platinumLegend,
      category: AchievementCategory.monumentsAndTours,
      icon: Icons.workspace_premium_rounded,
    ),
    const AchievementDefinition(
      id: 'century_of_victories',
      title: 'Setka Zwycięstw',
      description: 'Osiągnij 100 zwycięstw drużynowych w karierze menedżera.',
      tier: AchievementTier.platinumLegend,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.looks_two_rounded,
      targetValue: 100.0,
    ),
    const AchievementDefinition(
      id: 'hall_of_fame_100_rep',
      title: 'Nieśmiertelny Dyrektor Sportowy',
      description:
          'Osiągnij maksymalną reputację menedżerską 100/100 i komplet infrastruktury poziomu 5.',
      tier: AchievementTier.platinumLegend,
      category: AchievementCategory.managementAndLegacy,
      icon: Icons.auto_awesome_rounded,
      targetValue: 100.0,
    ),
  ]);

  static final Map<String, AchievementDefinition> _definitionById = {
    for (final d in definitions) d.id: d,
  };

  /// Wyszukuje definicję osiągnięcia po ID.
  static AchievementDefinition? getDefinition(String id) => _definitionById[id];

  /// Liczba odblokowanych osiągnięć.
  int get unlockedCount =>
      _records.values.where((r) => r.isUnlocked).length;

  /// Suma zdobytych punktów za odblokowane osiągnięcia.
  int get totalPoints {
    var sum = 0;
    for (final record in _records.values) {
      if (record.isUnlocked) {
        sum += _definitionById[record.achievementId]?.points ?? 0;
      }
    }
    return sum;
  }

  /// Maksymalna możliwa liczba punktów (45 osiągnięć).
  int get maxPossiblePoints =>
      definitions.fold(0, (sum, d) => sum + d.points);

  /// Procent ukończenia wszystkich osiągnięć (0.0 – 1.0).
  double get completionRatio =>
      definitions.isEmpty ? 0.0 : unlockedCount / definitions.length;

  /// Sprawdza czy konkretne osiągnięcie jest odblokowane.
  bool isUnlocked(String achievementId) =>
      _records[achievementId]?.isUnlocked ?? false;

  /// Ewaluacja automatyczna po zakończeniu etapu / wyścigu jednodniowego.
  List<AchievementUnlockEvent> evaluateAfterStage({
    required CareerSave save,
    required StageEvaluationContext stageContext,
    CareerAchievementMetrics? metricsOverride,
  }) {
    final now = save.currentDate;
    final seasonYear = save.currentSeasonYear;
    final unlockedNow = <AchievementUnlockEvent>[];

    if (metricsOverride != null) {
      _metrics = metricsOverride;
    } else if (stageContext.stageWon) {
      _metrics = _metrics.copyWith(
        totalStageAndRaceWins: _metrics.totalStageAndRaceWins + 1,
        grandTourStageWins: _metrics.grandTourStageWins +
            (stageContext.isGrandTourStage ? 1 : 0),
        monumentsWonCount:
            _metrics.monumentsWonCount + (stageContext.isMonument ? 1 : 0),
        sprintStageWins:
            _metrics.sprintStageWins + (stageContext.isSprintFinish ? 1 : 0),
        timeTrialWins:
            _metrics.timeTrialWins + (stageContext.isTimeTrial ? 1 : 0),
        mountainStageWins: _metrics.mountainStageWins +
            (stageContext.isMountainSummitFinish ? 1 : 0),
        breakawayWins:
            _metrics.breakawayWins + (stageContext.wonFromBreakaway ? 1 : 0),
        bestTimeTrialCdaM2: stageContext.bestTestedCdaM2 ??
            _metrics.bestTimeTrialCdaM2,
      );
    } else if (stageContext.bestTestedCdaM2 != null) {
      final currentBest = _metrics.bestTimeTrialCdaM2;
      if (currentBest == null || stageContext.bestTestedCdaM2! < currentBest) {
        _metrics =
            _metrics.copyWith(bestTimeTrialCdaM2: stageContext.bestTestedCdaM2);
      }
    }

    void check(
      String id,
      bool condition, {
      double? progress,
      String? note,
    }) {
      final event = _evaluateSingle(
        id: id,
        condition: condition,
        progressValue: progress,
        now: now,
        seasonYear: seasonYear,
        contextLabel: note ??
            (stageContext.raceName.isNotEmpty
                ? stageContext.raceName
                : 'Etap sezonu $seasonYear'),
      );
      if (event != null) unlockedNow.add(event);
    }

    // Taktyka & Etapy
    check(
      'first_victory',
      stageContext.stageWon ||
          save.trophiesWon.isNotEmpty ||
          _metrics.totalStageAndRaceWins >= 1,
    );
    check(
      'sprint_train_debut',
      stageContext.stageWon && stageContext.isSprintFinish,
    );
    check(
      'breakaway_survivor',
      stageContext.stageWon && stageContext.wonFromBreakaway,
    );
    check(
      'photo_finish_millimeter',
      stageContext.stageWon &&
          ((stageContext.wonByPhotoFinish ?? false) ||
              (stageContext.winningMarginSeconds != null &&
                  stageContext.winningMarginSeconds! > 0 &&
                  stageContext.winningMarginSeconds! < 0.1)),
    );
    check(
      'tire_pressure_guru',
      stageContext.optimalTirePressureApplied &&
          stageContext.bikeChanges == 0 &&
          stageContext.wonWithZeroCrashes,
    );
    check(
      'waxed_chain_efficiency',
      stageContext.stageWon && stageContext.aeroWaxChainApplied,
    );
    check(
      'clean_sheet_no_crashes',
      stageContext.stageWon &&
          stageContext.isRainy &&
          stageContext.wonWithZeroCrashes,
    );
    check(
      'watt_bomb_1400',
      stageContext.peakPowerWatts >= 1400.0,
      progress: stageContext.peakPowerWatts >= 1400.0 ? 1.0 : 0.0,
    );
    check(
      'zero_bonk_feeding',
      stageContext.stageWon && stageContext.bonkAvoidedWithZeroDeficit,
    );
    check(
      'solo_from_afar',
      stageContext.stageWon && stageContext.soloAttackDistanceKm > 50.0,
      progress: stageContext.soloAttackDistanceKm,
    );
    check(
      'echelon_master',
      stageContext.echelonSplitAchieved &&
          stageContext.gapOverGcRivalSeconds > 120,
      progress: stageContext.echelonSplitAchieved
          ? stageContext.gapOverGcRivalSeconds.toDouble()
          : 0.0,
    );
    check(
      'descent_daredevil',
      stageContext.stageWon && stageContext.wonOnDescentAttack,
    );
    check(
      'negative_split_tt',
      stageContext.stageWon &&
          stageContext.isTimeTrial &&
          stageContext.wonWithNegativeSplit,
    );
    check(
      'ttt_harmony',
      stageContext.stageWon && stageContext.isTeamTimeTrial,
    );
    check(
      'summit_queen_stage',
      stageContext.stageWon &&
          stageContext.isMountainSummitFinish &&
          stageContext.isHighAltitudeAbove2000m,
    );
    check(
      'strade_bianche_dust',
      stageContext.stageWon && stageContext.isStradeBiancheOrGravel,
    );
    check(
      'three_riders_top10',
      stageContext.teammateTop10Count >= 3,
      progress: stageContext.teammateTop10Count.toDouble(),
    );
    check(
      'high_speed_47_kmh',
      stageContext.stageWon && stageContext.stageAverageSpeedKmh > 47.0,
      progress: stageContext.stageAverageSpeedKmh,
    );
    check(
      'king_of_hell_north',
      stageContext.stageWon &&
          stageContext.isCobbleMonument &&
          stageContext.isRainy &&
          stageContext.bikeChanges == 0,
    );
    check(
      'physiological_monster_63',
      (stageContext.peakWPerKg20Min ?? 0.0) > 6.3,
      progress: stageContext.peakWPerKg20Min,
    );
    check(
      'gt_stage_hat_trick',
      _metrics.grandTourStageWins >= 3,
      progress: _metrics.grandTourStageWins.toDouble(),
    );

    // Sprzęt, CdA & Klub
    final cda = stageContext.bestTestedCdaM2 ?? _metrics.bestTimeTrialCdaM2;
    if (cda != null) {
      check(
        'watt_engineer_cda',
        cda < 0.190,
        note: 'Tunel Aero: CdA ${cda.toStringAsFixed(3)} m²',
      );
    }

    _evaluateClubInfrastructureAndLegacy(save, now, seasonYear, unlockedNow);
    return unlockedNow;
  }

  /// Ewaluacja automatyczna po zakończeniu sezonu.
  List<AchievementUnlockEvent> evaluateAfterSeason({
    required CareerSave save,
    required SeasonEvaluationContext seasonContext,
    CareerAchievementMetrics? metricsOverride,
  }) {
    final now = save.currentDate;
    final seasonYear = seasonContext.seasonYear;
    final unlockedNow = <AchievementUnlockEvent>[];

    if (metricsOverride != null) {
      _metrics = metricsOverride;
    } else {
      final mergedMonuments = {
        ..._metrics.distinctMonumentIdsWon,
        ...seasonContext.distinctMonumentIdsWon,
      };
      _metrics = _metrics.copyWith(
        totalStageAndRaceWins:
            _metrics.totalStageAndRaceWins + seasonContext.seasonTotalWins,
        grandTourGcWins:
            _metrics.grandTourGcWins + seasonContext.grandTourGcWins,
        worldTourStageRaceGcWins: _metrics.worldTourStageRaceGcWins +
            seasonContext.worldTourStageRaceGcWins,
        altitudeCampsCompleted: _metrics.altitudeCampsCompleted +
            seasonContext.altitudeCampsCompleted,
        youthGraduatesPromoted: _metrics.youthGraduatesPromoted +
            seasonContext.youthAcademyGraduatesPromoted,
        youthGraduateWins: _metrics.youthGraduateWins +
            seasonContext.youthAcademyGraduateRaceWins,
        bestTimeTrialCdaM2:
            seasonContext.bestTimeTrialCdaM2 ?? _metrics.bestTimeTrialCdaM2,
        startingDivision: seasonContext.startedDivision,
        everPromotedToWorldTour: _metrics.everPromotedToWorldTour ||
            seasonContext.promotedToWorldTour ||
            (seasonContext.startedDivision == TeamDivision.continental &&
                seasonContext.currentDivision == TeamDivision.worldTour),
        wonAllThreeGrandTours: _metrics.wonAllThreeGrandTours ||
            seasonContext.wonAllThreeGrandToursInCareer,
        distinctMonumentIdsWon: mergedMonuments,
        monumentsWonCount: mergedMonuments.length,
        worldRoadChampionTitles: _metrics.worldRoadChampionTitles +
            seasonContext.worldChampionshipRoadWins,
        worldTtChampionTitles: _metrics.worldTtChampionTitles +
            seasonContext.worldChampionshipTtWins,
        olympicGoldMedals:
            _metrics.olympicGoldMedals + seasonContext.olympicGoldWins,
        nationalChampionTitles: _metrics.nationalChampionTitles +
            seasonContext.nationalChampionshipWins,
        grandTourPointsJerseys: _metrics.grandTourPointsJerseys +
            seasonContext.grandTourPointsJerseys,
        grandTourKomJerseys:
            _metrics.grandTourKomJerseys + seasonContext.grandTourKomJerseys,
        grandTourYouthJerseys: _metrics.grandTourYouthJerseys +
            seasonContext.grandTourYouthJerseys,
        seasonsCompleted: seasonContext.totalSeasonsCompleted,
      );
    }

    void check(
      String id,
      bool condition, {
      double? progress,
      String? note,
    }) {
      final event = _evaluateSingle(
        id: id,
        condition: condition,
        progressValue: progress,
        now: now,
        seasonYear: seasonYear,
        contextLabel: note ?? 'Podsumowanie sezonu $seasonYear',
      );
      if (event != null) unlockedNow.add(event);
    }

    check(
      'first_altitude_camp',
      _metrics.altitudeCampsCompleted >= 1,
      progress: _metrics.altitudeCampsCompleted.toDouble(),
    );
    check(
      'youth_academy_promotion',
      _metrics.youthGraduatesPromoted >= 1,
      progress: _metrics.youthGraduatesPromoted.toDouble(),
    );
    check(
      'academy_winner',
      _metrics.youthGraduateWins >= 1,
      progress: _metrics.youthGraduateWins.toDouble(),
    );
    check(
      'national_champion_factory',
      _metrics.nationalChampionTitles >= 3,
      progress: _metrics.nationalChampionTitles.toDouble(),
    );
    check(
      'sponsor_perfection',
      seasonContext.sponsorObjectivesCompletedRatio >= 1.0,
    );
    check(
      'first_grand_tour_gc',
      _metrics.grandTourGcWins >= 1,
      progress: _metrics.grandTourGcWins.toDouble(),
    );
    check(
      'green_jersey_master',
      _metrics.grandTourPointsJerseys >= 1,
    );
    check(
      'kom_polka_dot',
      _metrics.grandTourKomJerseys >= 1,
    );
    check(
      'rainbow_jersey_road',
      _metrics.worldRoadChampionTitles >= 1,
    );
    check(
      'wt_stage_race_collector',
      _metrics.worldTourStageRaceGcWins >= 5,
      progress: _metrics.worldTourStageRaceGcWins.toDouble(),
    );
    check(
      'clean_sport_ambassador',
      seasonContext.cleanBiologicalPassportAllSeason,
    );

    final cda = seasonContext.bestTimeTrialCdaM2 ?? _metrics.bestTimeTrialCdaM2;
    if (cda != null) {
      check('watt_engineer_cda', cda < 0.190);
    }

    // Platinum Legend
    final startedContinental =
        _metrics.startingDivision == TeamDivision.continental ||
            seasonContext.startedDivision == TeamDivision.continental;
    final reachedWorldTour = _metrics.everPromotedToWorldTour ||
        seasonContext.currentDivision == TeamDivision.worldTour;
    check(
      'from_zero_to_worldtour',
      startedContinental && reachedWorldTour && _metrics.grandTourGcWins >= 1,
      note: 'Awans z Continental do WorldTour + wygrany Wielki Tour',
    );
    check(
      'all_five_monuments',
      _metrics.distinctMonumentIdsWon.length >= 5,
      progress: _metrics.distinctMonumentIdsWon.length.toDouble(),
    );
    check(
      'triple_grand_tour_crown',
      _metrics.wonAllThreeGrandTours,
    );
    check(
      'olympic_and_world_double',
      _metrics.olympicGoldMedals >= 1 && _metrics.worldRoadChampionTitles >= 1,
    );

    _evaluateClubInfrastructureAndLegacy(save, now, seasonYear, unlockedNow);
    return unlockedNow;
  }

  /// Ewaluacja stanu klubu i tunelu aerodynamicznego (np. bezpośrednio po teście CdA lub rozbudowie bazy).
  List<AchievementUnlockEvent> evaluateClubAndAero({
    required CareerSave save,
    double? testedCdaM2,
  }) {
    final unlockedNow = <AchievementUnlockEvent>[];
    if (testedCdaM2 != null) {
      final currentBest = _metrics.bestTimeTrialCdaM2;
      if (currentBest == null || testedCdaM2 < currentBest) {
        _metrics = _metrics.copyWith(bestTimeTrialCdaM2: testedCdaM2);
      }
      final cdaEvent = _evaluateSingle(
        id: 'watt_engineer_cda',
        condition: testedCdaM2 < 0.190,
        now: save.currentDate,
        seasonYear: save.currentSeasonYear,
        contextLabel: 'Tunel Aero: CdA ${testedCdaM2.toStringAsFixed(3)} m²',
      );
      if (cdaEvent != null) unlockedNow.add(cdaEvent);
    }

    _evaluateClubInfrastructureAndLegacy(
      save,
      save.currentDate,
      save.currentSeasonYear,
      unlockedNow,
    );
    return unlockedNow;
  }

  void _evaluateClubInfrastructureAndLegacy(
    CareerSave save,
    DateTime now,
    int seasonYear,
    List<AchievementUnlockEvent> unlockedNow,
  ) {
    void check(String id, bool condition, {double? progress}) {
      final event = _evaluateSingle(
        id: id,
        condition: condition,
        progressValue: progress,
        now: now,
        seasonYear: seasonYear,
        contextLabel: save.playerTeam.name,
      );
      if (event != null) unlockedNow.add(event);
    }

    check(
      'service_course_upgrade',
      save.serviceCourseLevel >= 3,
      progress: save.serviceCourseLevel.toDouble(),
    );
    check(
      'wind_tunnel_level_3',
      save.windTunnelLevel >= 3,
      progress: save.windTunnelLevel.toDouble(),
    );
    check(
      'medical_center_level_3',
      save.medicalCenterLevel >= 3,
      progress: save.medicalCenterLevel.toDouble(),
    );
    check(
      'stable_finances_2m',
      save.playerTeam.cashBalanceEur >= 2000000,
      progress: save.playerTeam.cashBalanceEur.toDouble(),
    );
    check(
      'elite_reputation_75',
      save.managerReputation >= 75,
      progress: save.managerReputation.toDouble(),
    );
    check(
      'ten_career_wins',
      _metrics.totalStageAndRaceWins >= 10,
      progress: _metrics.totalStageAndRaceWins.toDouble(),
    );
    check(
      'century_of_victories',
      _metrics.totalStageAndRaceWins >= 100,
      progress: _metrics.totalStageAndRaceWins.toDouble(),
    );
    check(
      'hall_of_fame_100_rep',
      save.managerReputation >= 100 &&
          save.serviceCourseLevel >= 5 &&
          save.windTunnelLevel >= 5 &&
          save.medicalCenterLevel >= 5,
      progress: save.managerReputation.toDouble(),
    );
  }

  AchievementUnlockEvent? _evaluateSingle({
    required String id,
    required bool condition,
    double? progressValue,
    required DateTime now,
    required int seasonYear,
    String? contextLabel,
  }) {
    final def = _definitionById[id];
    final existing = _records[id];
    if (def == null || existing == null) return null;

    if (existing.isUnlocked) return null;

    final nextProgress = progressValue != null
        ? (progressValue > existing.currentValue
            ? progressValue
            : existing.currentValue)
        : (condition ? def.targetValue : existing.currentValue);

    if (!condition) {
      if (nextProgress != existing.currentValue) {
        _records[id] = existing.copyWith(currentValue: nextProgress);
      }
      return null;
    }

    _records[id] = existing.copyWith(
      isUnlocked: true,
      unlockedAt: now,
      currentValue: def.targetValue,
      unlockedSeasonYear: seasonYear,
      contextNote: contextLabel,
    );

    final event = AchievementUnlockEvent(
      achievement: def,
      unlockedAt: now,
      seasonYear: seasonYear,
      contextLabel: contextLabel,
    );
    if (!_unlockController.isClosed) {
      _unlockController.add(event);
    }
    return event;
  }

  /// Ręczne odblokowanie osiągnięcia (np. z poziomu zdarzeń specjalnych lub testów).
  AchievementUnlockEvent? triggerUnlock(
    String achievementId, {
    int seasonYear = 2026,
    DateTime? timestamp,
    String? contextLabel,
  }) {
    return _evaluateSingle(
      id: achievementId,
      condition: true,
      now: timestamp ?? DateTime.now(),
      seasonYear: seasonYear,
      contextLabel: contextLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': _metrics.toJson(),
      'records': {
        for (final entry in _records.entries) entry.key: entry.value.toJson(),
      },
    };
  }

  void loadFromJson(Map<String, dynamic> json) {
    if (json['metrics'] is Map<String, dynamic>) {
      _metrics = CareerAchievementMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>,
      );
    }
    if (json['records'] is Map<String, dynamic>) {
      final rawRecords = json['records'] as Map<String, dynamic>;
      for (final entry in rawRecords.entries) {
        if (entry.value is Map<String, dynamic> &&
            _definitionById.containsKey(entry.key)) {
          _records[entry.key] = AchievementProgressRecord.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }
  }

  void dispose() {
    _unlockController.close();
  }
}

/// Globalny provider serwisu osiągnięć i kamieni milowych.
final achievementServiceProvider =
    Provider<AchievementAndMilestonesService>((ref) {
  final service = AchievementAndMilestonesService();
  ref.onDispose(service.dispose);
  return service;
});

/// Reaktywny strumień zdarzeń odblokowania osiągnięć dla warstwy Toast UI.
final achievementUnlockStreamProvider =
    StreamProvider<AchievementUnlockEvent>((ref) {
  final service = ref.watch(achievementServiceProvider);
  return service.unlockStream;
});
