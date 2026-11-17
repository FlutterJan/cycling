import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Cztery główne gałęzie rozwoju menedżera i pasywnych perków.
enum ManagerSkillBranch {
  tacticsAndRacecraft(
    'Taktyka & Szosa',
    'Taktyka',
    'Dowodzenie radiem, czytanie ucieczek, ranty na wietrze i rozprowadzanie sprinterów.',
    Icons.route_rounded,
    AppColors.accentBlue,
  ),
  physiologyAndTraining(
    'Fizjologia & Trening',
    'Fizjologia',
    'Szczyty formy, regeneracja po etapach, odporność w 3. tygodniu GT i prewencja kontuzji.',
    Icons.monitor_heart_rounded,
    AppColors.statusSuccess,
  ),
  scoutingAndYouth(
    'Skauting & Akademia',
    'Skauting',
    'Szybsze odkrywanie talentów U19/U23, tańsze misje skautów i dokładniejsze raporty potencjału.',
    Icons.travel_explore_rounded,
    AppColors.cyanAccent,
  ),
  financeAndNegotiation(
    'Finanse & Negocjacje',
    'Finanse',
    'Lepsze kontrakty sponsorskie, niższe żądania płacowe, zniżki transferowe i stabilność szatni.',
    Icons.account_balance_rounded,
    AppColors.goldAccent,
  );

  final String title;
  final String shortTitle;
  final String description;
  final IconData icon;
  final Color accentColor;

  const ManagerSkillBranch(
    this.title,
    this.shortTitle,
    this.description,
    this.icon,
    this.accentColor,
  );

  String toJson() => name;

  static ManagerSkillBranch fromJson(String value) {
    return ManagerSkillBranch.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ManagerSkillBranch.tacticsAndRacecraft,
    );
  }
}

/// Poziom głębokości węzła w drzewku umiejętności menedżera.
enum ManagerPerkTier {
  tier1Foundation('Poziom I · Fundament', 1),
  tier2Specialist('Poziom II · Specjalizacja', 2),
  tier3Mastery('Poziom III · Mistrzostwo', 3),
  tier4Signature('Poziom IV · Sygnatura Pasywna', 4);

  final String label;
  final int tierIndex;

  const ManagerPerkTier(this.label, this.tierIndex);
}

/// Aktualny status węzła na podstawie poziomu menedżera, wymagań wstępnych i punktów.
enum ManagerSkillNodeState {
  locked('Zablokowane'),
  available('Dostępne'),
  partiallyUnlocked('W trakcie rozwoju'),
  maxed('Opanowane');

  final String label;
  const ManagerSkillNodeState(this.label);
}

/// Źródło punktów doświadczenia (XP) menedżera.
enum ManagerXpSource {
  raceWin('Zwycięstwo etapowe / wyścig'),
  podiumFinish('Podium klasyfikacji'),
  grandTourStage('Etap Wielkiego Touru'),
  monumentTop5('Top 5 Monumentu'),
  sponsorObjective('Cel sponsorski'),
  youthPromotion('Awans juniora U23'),
  seasonCompletion('Zamknięcie sezonu'),
  manualGrant('Premia dyrektorska');

  final String label;
  const ManagerXpSource(this.label);

  String toJson() => name;

  static ManagerXpSource fromJson(String value) {
    return ManagerXpSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ManagerXpSource.raceWin,
    );
  }
}

/// Zsumowane pasywne modyfikatory wynikające z odblokowanych perków menedżera.
class ManagerSkillPerkEffects {
  final double raceTacticalExecutionBonusPct;
  final double echelonPositioningBonusPct;
  final double sprintLeadoutTimingBonusPct;
  final double breakawaySuccessRateBonusPct;
  final double trainingEffectivenessBonusPct;
  final double postStageRecoveryBonusPct;
  final double thirdWeekGtResilienceBonusPct;
  final double injuryRiskReductionPct;
  final double scoutingSpeedBonusPct;
  final double scoutingCostDiscountPct;
  final double u23DevelopmentRateBonusPct;
  final int potentialRevealAccuracyBonus;
  final double sponsorRevenueBonusPct;
  final double riderSalaryDiscountPct;
  final double transferFeeDiscountPct;
  final double moraleStabilityBonus;
  final List<String> activeSignaturePerks;

  const ManagerSkillPerkEffects({
    this.raceTacticalExecutionBonusPct = 0.0,
    this.echelonPositioningBonusPct = 0.0,
    this.sprintLeadoutTimingBonusPct = 0.0,
    this.breakawaySuccessRateBonusPct = 0.0,
    this.trainingEffectivenessBonusPct = 0.0,
    this.postStageRecoveryBonusPct = 0.0,
    this.thirdWeekGtResilienceBonusPct = 0.0,
    this.injuryRiskReductionPct = 0.0,
    this.scoutingSpeedBonusPct = 0.0,
    this.scoutingCostDiscountPct = 0.0,
    this.u23DevelopmentRateBonusPct = 0.0,
    this.potentialRevealAccuracyBonus = 0,
    this.sponsorRevenueBonusPct = 0.0,
    this.riderSalaryDiscountPct = 0.0,
    this.transferFeeDiscountPct = 0.0,
    this.moraleStabilityBonus = 0.0,
    this.activeSignaturePerks = const <String>[],
  });

  static const ManagerSkillPerkEffects zero = ManagerSkillPerkEffects();

  ManagerSkillPerkEffects operator +(ManagerSkillPerkEffects other) {
    return ManagerSkillPerkEffects(
      raceTacticalExecutionBonusPct:
          raceTacticalExecutionBonusPct + other.raceTacticalExecutionBonusPct,
      echelonPositioningBonusPct:
          echelonPositioningBonusPct + other.echelonPositioningBonusPct,
      sprintLeadoutTimingBonusPct:
          sprintLeadoutTimingBonusPct + other.sprintLeadoutTimingBonusPct,
      breakawaySuccessRateBonusPct:
          breakawaySuccessRateBonusPct + other.breakawaySuccessRateBonusPct,
      trainingEffectivenessBonusPct:
          trainingEffectivenessBonusPct + other.trainingEffectivenessBonusPct,
      postStageRecoveryBonusPct:
          postStageRecoveryBonusPct + other.postStageRecoveryBonusPct,
      thirdWeekGtResilienceBonusPct:
          thirdWeekGtResilienceBonusPct + other.thirdWeekGtResilienceBonusPct,
      injuryRiskReductionPct:
          injuryRiskReductionPct + other.injuryRiskReductionPct,
      scoutingSpeedBonusPct:
          scoutingSpeedBonusPct + other.scoutingSpeedBonusPct,
      scoutingCostDiscountPct:
          scoutingCostDiscountPct + other.scoutingCostDiscountPct,
      u23DevelopmentRateBonusPct:
          u23DevelopmentRateBonusPct + other.u23DevelopmentRateBonusPct,
      potentialRevealAccuracyBonus:
          potentialRevealAccuracyBonus + other.potentialRevealAccuracyBonus,
      sponsorRevenueBonusPct:
          sponsorRevenueBonusPct + other.sponsorRevenueBonusPct,
      riderSalaryDiscountPct:
          riderSalaryDiscountPct + other.riderSalaryDiscountPct,
      transferFeeDiscountPct:
          transferFeeDiscountPct + other.transferFeeDiscountPct,
      moraleStabilityBonus: moraleStabilityBonus + other.moraleStabilityBonus,
      activeSignaturePerks: <String>[
        ...activeSignaturePerks,
        ...other.activeSignaturePerks,
      ],
    );
  }

  ManagerSkillPerkEffects scaled(int rank) {
    if (rank <= 0) return zero;
    return ManagerSkillPerkEffects(
      raceTacticalExecutionBonusPct: raceTacticalExecutionBonusPct * rank,
      echelonPositioningBonusPct: echelonPositioningBonusPct * rank,
      sprintLeadoutTimingBonusPct: sprintLeadoutTimingBonusPct * rank,
      breakawaySuccessRateBonusPct: breakawaySuccessRateBonusPct * rank,
      trainingEffectivenessBonusPct: trainingEffectivenessBonusPct * rank,
      postStageRecoveryBonusPct: postStageRecoveryBonusPct * rank,
      thirdWeekGtResilienceBonusPct: thirdWeekGtResilienceBonusPct * rank,
      injuryRiskReductionPct: injuryRiskReductionPct * rank,
      scoutingSpeedBonusPct: scoutingSpeedBonusPct * rank,
      scoutingCostDiscountPct: scoutingCostDiscountPct * rank,
      u23DevelopmentRateBonusPct: u23DevelopmentRateBonusPct * rank,
      potentialRevealAccuracyBonus: potentialRevealAccuracyBonus * rank,
      sponsorRevenueBonusPct: sponsorRevenueBonusPct * rank,
      riderSalaryDiscountPct: riderSalaryDiscountPct * rank,
      transferFeeDiscountPct: transferFeeDiscountPct * rank,
      moraleStabilityBonus: moraleStabilityBonus * rank,
      activeSignaturePerks: activeSignaturePerks,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'raceTacticalExecutionBonusPct': raceTacticalExecutionBonusPct,
      'echelonPositioningBonusPct': echelonPositioningBonusPct,
      'sprintLeadoutTimingBonusPct': sprintLeadoutTimingBonusPct,
      'breakawaySuccessRateBonusPct': breakawaySuccessRateBonusPct,
      'trainingEffectivenessBonusPct': trainingEffectivenessBonusPct,
      'postStageRecoveryBonusPct': postStageRecoveryBonusPct,
      'thirdWeekGtResilienceBonusPct': thirdWeekGtResilienceBonusPct,
      'injuryRiskReductionPct': injuryRiskReductionPct,
      'scoutingSpeedBonusPct': scoutingSpeedBonusPct,
      'scoutingCostDiscountPct': scoutingCostDiscountPct,
      'u23DevelopmentRateBonusPct': u23DevelopmentRateBonusPct,
      'potentialRevealAccuracyBonus': potentialRevealAccuracyBonus,
      'sponsorRevenueBonusPct': sponsorRevenueBonusPct,
      'riderSalaryDiscountPct': riderSalaryDiscountPct,
      'transferFeeDiscountPct': transferFeeDiscountPct,
      'moraleStabilityBonus': moraleStabilityBonus,
      'activeSignaturePerks': activeSignaturePerks,
    };
  }

  factory ManagerSkillPerkEffects.fromJson(Map<String, dynamic> json) {
    return ManagerSkillPerkEffects(
      raceTacticalExecutionBonusPct:
          (json['raceTacticalExecutionBonusPct'] as num?)?.toDouble() ?? 0.0,
      echelonPositioningBonusPct:
          (json['echelonPositioningBonusPct'] as num?)?.toDouble() ?? 0.0,
      sprintLeadoutTimingBonusPct:
          (json['sprintLeadoutTimingBonusPct'] as num?)?.toDouble() ?? 0.0,
      breakawaySuccessRateBonusPct:
          (json['breakawaySuccessRateBonusPct'] as num?)?.toDouble() ?? 0.0,
      trainingEffectivenessBonusPct:
          (json['trainingEffectivenessBonusPct'] as num?)?.toDouble() ?? 0.0,
      postStageRecoveryBonusPct:
          (json['postStageRecoveryBonusPct'] as num?)?.toDouble() ?? 0.0,
      thirdWeekGtResilienceBonusPct:
          (json['thirdWeekGtResilienceBonusPct'] as num?)?.toDouble() ?? 0.0,
      injuryRiskReductionPct:
          (json['injuryRiskReductionPct'] as num?)?.toDouble() ?? 0.0,
      scoutingSpeedBonusPct:
          (json['scoutingSpeedBonusPct'] as num?)?.toDouble() ?? 0.0,
      scoutingCostDiscountPct:
          (json['scoutingCostDiscountPct'] as num?)?.toDouble() ?? 0.0,
      u23DevelopmentRateBonusPct:
          (json['u23DevelopmentRateBonusPct'] as num?)?.toDouble() ?? 0.0,
      potentialRevealAccuracyBonus:
          (json['potentialRevealAccuracyBonus'] as num?)?.toInt() ?? 0,
      sponsorRevenueBonusPct:
          (json['sponsorRevenueBonusPct'] as num?)?.toDouble() ?? 0.0,
      riderSalaryDiscountPct:
          (json['riderSalaryDiscountPct'] as num?)?.toDouble() ?? 0.0,
      transferFeeDiscountPct:
          (json['transferFeeDiscountPct'] as num?)?.toDouble() ?? 0.0,
      moraleStabilityBonus:
          (json['moraleStabilityBonus'] as num?)?.toDouble() ?? 0.0,
      activeSignaturePerks: (json['activeSignaturePerks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
    );
  }
}

/// Definicja pojedynczego węzła w drzewku umiejętności menedżera.
class ManagerSkillNodeDefinition {
  final String id;
  final ManagerSkillBranch branch;
  final ManagerPerkTier tier;
  final int laneColumn; // 0 (lewy), 1 (środkowy), 2 (prawy) w obrębie gałęzi
  final String title;
  final String shortTitle;
  final String description;
  final String passiveEffectSummary;
  final int maxRank;
  final int pointCostPerRank;
  final List<String> prerequisiteNodeIds;
  final int requiredManagerLevel;
  final bool isSignatureCapstone;
  final IconData icon;
  final ManagerSkillPerkEffects perRankEffects;

  const ManagerSkillNodeDefinition({
    required this.id,
    required this.branch,
    required this.tier,
    required this.laneColumn,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.passiveEffectSummary,
    required this.maxRank,
    required this.pointCostPerRank,
    required this.prerequisiteNodeIds,
    required this.requiredManagerLevel,
    this.isSignatureCapstone = false,
    required this.icon,
    required this.perRankEffects,
  });
}

/// Wpis w dzienniku zdobytego doświadczenia menedżera.
class ManagerXpEventRecord {
  final String id;
  final ManagerXpSource source;
  final String title;
  final int xpEarned;
  final String timestampIso;

  const ManagerXpEventRecord({
    required this.id,
    required this.source,
    required this.title,
    required this.xpEarned,
    required this.timestampIso,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'source': source.toJson(),
      'title': title,
      'xpEarned': xpEarned,
      'timestampIso': timestampIso,
    };
  }

  factory ManagerXpEventRecord.fromJson(Map<String, dynamic> json) {
    return ManagerXpEventRecord(
      id: json['id']?.toString() ?? '',
      source: ManagerXpSource.fromJson(json['source']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
      timestampIso: json['timestampIso']?.toString() ?? '',
    );
  }
}

/// Pełny stan drzewka umiejętności i pasywnych perków menedżera.
class ManagerSkillTreeState {
  final int managerLevel;
  final int currentXp;
  final int totalXpEarned;
  final int availableSkillPoints;
  final int spentSkillPoints;
  final Map<String, int> unlockedRanks;
  final int respecCount;
  final ManagerSkillBranch? selectedBranchFilter;
  final String? selectedNodeId;
  final List<ManagerXpEventRecord> recentXpLog;

  const ManagerSkillTreeState({
    required this.managerLevel,
    required this.currentXp,
    required this.totalXpEarned,
    required this.availableSkillPoints,
    required this.spentSkillPoints,
    required this.unlockedRanks,
    required this.respecCount,
    this.selectedBranchFilter,
    this.selectedNodeId,
    this.recentXpLog = const <ManagerXpEventRecord>[],
  });

  factory ManagerSkillTreeState.initial() {
    return const ManagerSkillTreeState(
      managerLevel: 1,
      currentXp: 0,
      totalXpEarned: 0,
      availableSkillPoints: 2,
      spentSkillPoints: 0,
      unlockedRanks: <String, int>{},
      respecCount: 0,
      selectedBranchFilter: null,
      selectedNodeId: 'tac_radio_discipline',
      recentXpLog: <ManagerXpEventRecord>[],
    );
  }

  int get xpForNextLevel =>
      ManagerSkillTreePerksService.xpRequiredForLevel(managerLevel);

  double get levelProgressRatio {
    final req = xpForNextLevel;
    if (req <= 0) return 1.0;
    return (currentXp / req).clamp(0.0, 1.0);
  }

  ManagerSkillPerkEffects get aggregateEffects =>
      ManagerSkillTreePerksService.computeAggregateEffects(unlockedRanks);

  int get unlockedNodeCount =>
      unlockedRanks.values.where((rank) => rank > 0).length;

  int get currentUnlockedRanks =>
      unlockedRanks.values.fold<int>(0, (sum, r) => sum + r);

  int get totalPossibleRanks => ManagerSkillTreeCatalog.nodes
      .fold<int>(0, (sum, node) => sum + node.maxRank);

  int rankOf(String nodeId) => unlockedRanks[nodeId] ?? 0;

  ManagerSkillTreeState copyWith({
    int? managerLevel,
    int? currentXp,
    int? totalXpEarned,
    int? availableSkillPoints,
    int? spentSkillPoints,
    Map<String, int>? unlockedRanks,
    int? respecCount,
    ManagerSkillBranch? selectedBranchFilter,
    bool clearBranchFilter = false,
    String? selectedNodeId,
    bool clearSelectedNode = false,
    List<ManagerXpEventRecord>? recentXpLog,
  }) {
    return ManagerSkillTreeState(
      managerLevel: managerLevel ?? this.managerLevel,
      currentXp: currentXp ?? this.currentXp,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      availableSkillPoints: availableSkillPoints ?? this.availableSkillPoints,
      spentSkillPoints: spentSkillPoints ?? this.spentSkillPoints,
      unlockedRanks: unlockedRanks ?? this.unlockedRanks,
      respecCount: respecCount ?? this.respecCount,
      selectedBranchFilter: clearBranchFilter
          ? null
          : (selectedBranchFilter ?? this.selectedBranchFilter),
      selectedNodeId:
          clearSelectedNode ? null : (selectedNodeId ?? this.selectedNodeId),
      recentXpLog: recentXpLog ?? this.recentXpLog,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'managerLevel': managerLevel,
      'currentXp': currentXp,
      'totalXpEarned': totalXpEarned,
      'availableSkillPoints': availableSkillPoints,
      'spentSkillPoints': spentSkillPoints,
      'unlockedRanks': unlockedRanks,
      'respecCount': respecCount,
      'selectedBranchFilter': selectedBranchFilter?.toJson(),
      'selectedNodeId': selectedNodeId,
      'recentXpLog': recentXpLog.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory ManagerSkillTreeState.fromJson(Map<String, dynamic> json) {
    final rawRanks = json['unlockedRanks'] as Map<String, dynamic>? ?? const {};
    final parsedRanks = <String, int>{};
    for (final entry in rawRanks.entries) {
      final v = (entry.value as num?)?.toInt() ?? 0;
      if (v > 0 && ManagerSkillTreeCatalog.byId(entry.key) != null) {
        parsedRanks[entry.key] = v;
      }
    }
    final rawBranch = json['selectedBranchFilter']?.toString();
    return ManagerSkillTreeState(
      managerLevel: ((json['managerLevel'] as num?)?.toInt() ?? 1).clamp(1, 50),
      currentXp: math.max(0, (json['currentXp'] as num?)?.toInt() ?? 0),
      totalXpEarned: math.max(0, (json['totalXpEarned'] as num?)?.toInt() ?? 0),
      availableSkillPoints:
          math.max(0, (json['availableSkillPoints'] as num?)?.toInt() ?? 0),
      spentSkillPoints:
          math.max(0, (json['spentSkillPoints'] as num?)?.toInt() ?? 0),
      unlockedRanks: parsedRanks,
      respecCount: math.max(0, (json['respecCount'] as num?)?.toInt() ?? 0),
      selectedBranchFilter:
          rawBranch != null ? ManagerSkillBranch.fromJson(rawBranch) : null,
      selectedNodeId: json['selectedNodeId']?.toString(),
      recentXpLog: (json['recentXpLog'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ManagerXpEventRecord.fromJson)
              .toList(growable: false) ??
          const <ManagerXpEventRecord>[],
    );
  }
}

/// Wynik operacji odblokowania kolejnego poziomu umiejętności.
class SkillUnlockResult {
  final bool success;
  final String message;
  final ManagerSkillTreeState state;
  final String? unlockedNodeId;
  final int newRank;

  const SkillUnlockResult({
    required this.success,
    required this.message,
    required this.state,
    this.unlockedNodeId,
    this.newRank = 0,
  });
}

/// Kompletny katalog 20 węzłów (4 gałęzie x 5 węzłów) drzewka umiejętności menedżera.
class ManagerSkillTreeCatalog {
  ManagerSkillTreeCatalog._();

  static const List<ManagerSkillNodeDefinition> nodes =
      <ManagerSkillNodeDefinition>[
    // 1. TAKTYKA & SZOSA
    ManagerSkillNodeDefinition(
      id: 'tac_radio_discipline',
      branch: ManagerSkillBranch.tacticsAndRacecraft,
      tier: ManagerPerkTier.tier1Foundation,
      laneColumn: 1,
      title: 'Dyscyplina Radia Wyścigowego',
      shortTitle: 'Radio Wyścigowe',
      description:
          'Zwięzłe i precyzyjne komendy przez słuchawkę skracają czas reakcji kolarzy na ataki rywali.',
      passiveEffectSummary: '+2.5% skuteczności rozkazów taktycznych / poziom',
      maxRank: 3,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>[],
      requiredManagerLevel: 1,
      icon: Icons.headset_mic_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        raceTacticalExecutionBonusPct: 2.5,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'tac_crosswind_echelons',
      branch: ManagerSkillBranch.tacticsAndRacecraft,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 0,
      title: 'Mistrzostwo Wachlarzy na Wietrze',
      shortTitle: 'Ranty & Wiatr',
      description:
          'Zespół automatycznie ustawia się po nawietrznej stronie szosy na 2 km przed odsłoniętym sektorem.',
      passiveEffectSummary: '+4.0% pozycjonowania w rantach / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['tac_radio_discipline'],
      requiredManagerLevel: 3,
      icon: Icons.air_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        echelonPositioningBonusPct: 4.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'tac_sprint_leadout_sync',
      branch: ManagerSkillBranch.tacticsAndRacecraft,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 2,
      title: 'Synchronizacja Pociągu Sprinterskiego',
      shortTitle: 'Pociąg Sprinterski',
      description:
          'Płynne zmiany rozprowadzających na ostatnich 2500 m zwiększają zachowanie pędu w procach aero.',
      passiveEffectSummary: '+3.5% timingu rozprowadzania / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['tac_radio_discipline'],
      requiredManagerLevel: 3,
      icon: Icons.bolt_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        sprintLeadoutTimingBonusPct: 3.5,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'tac_breakaway_calculus',
      branch: ManagerSkillBranch.tacticsAndRacecraft,
      tier: ManagerPerkTier.tier3Mastery,
      laneColumn: 1,
      title: 'Kalkulator Odjazdów i Zjazdów',
      shortTitle: 'Czytanie Odjazdów',
      description:
          'Bezbłędne wyczucie momentu zawiązania ucieczki dnia i utrzymania równowagi tempa na zjazdach.',
      passiveEffectSummary: '+4.5% szans powodzenia ucieczek / poziom',
      maxRank: 2,
      pointCostPerRank: 2,
      prerequisiteNodeIds: <String>[
        'tac_crosswind_echelons',
        'tac_sprint_leadout_sync',
      ],
      requiredManagerLevel: 6,
      icon: Icons.alt_route_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        breakawaySuccessRateBonusPct: 4.5,
        raceTacticalExecutionBonusPct: 1.5,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'tac_signature_maestro',
      branch: ManagerSkillBranch.tacticsAndRacecraft,
      tier: ManagerPerkTier.tier4Signature,
      laneColumn: 1,
      title: 'Sygnatura: Szachista Peletonu',
      shortTitle: 'Szachista Peletonu',
      description:
          'Pasywny perk mistrzowski: kolarze zachowują spokój pod presją finałowych 10 km, zyskując premię taktyczną i stabilne morale.',
      passiveEffectSummary:
          '+6.0% taktyki, +4.0% rantów, +4.0% sprintu, +5 pkt morale',
      maxRank: 1,
      pointCostPerRank: 3,
      prerequisiteNodeIds: <String>['tac_breakaway_calculus'],
      requiredManagerLevel: 10,
      isSignatureCapstone: true,
      icon: Icons.workspace_premium_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        raceTacticalExecutionBonusPct: 6.0,
        echelonPositioningBonusPct: 4.0,
        sprintLeadoutTimingBonusPct: 4.0,
        moraleStabilityBonus: 5.0,
        activeSignaturePerks: <String>['Szachista Peletonu'],
      ),
    ),

    // 2. FIZJOLOGIA & TRENING
    ManagerSkillNodeDefinition(
      id: 'phy_periodization_basics',
      branch: ManagerSkillBranch.physiologyAndTraining,
      tier: ManagerPerkTier.tier1Foundation,
      laneColumn: 1,
      title: 'Periodyzacja Bloków Treningowych',
      shortTitle: 'Bloki Treningowe',
      description:
          'Precyzyjne dobieranie obciążeń TSS pozwala szybciej budować formę bez ryzyka przetrenowania.',
      passiveEffectSummary: '+3.0% efektywności treningu / poziom',
      maxRank: 3,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>[],
      requiredManagerLevel: 1,
      icon: Icons.fitness_center_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        trainingEffectivenessBonusPct: 3.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'phy_overnight_recovery',
      branch: ManagerSkillBranch.physiologyAndTraining,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 0,
      title: 'Protokół Regeneracji Nocnej',
      shortTitle: 'Regeneracja Nocna',
      description:
          'Optymalizacja snu, masaży i żywienia węglowodanowego przyspiesza odbudowę glikogenu po etapie.',
      passiveEffectSummary: '+4.0% regeneracji międzyetapowej / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['phy_periodization_basics'],
      requiredManagerLevel: 3,
      icon: Icons.nightlight_round,
      perRankEffects: ManagerSkillPerkEffects(
        postStageRecoveryBonusPct: 4.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'phy_injury_prevention',
      branch: ManagerSkillBranch.physiologyAndTraining,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 2,
      title: 'Profilaktyka Przeciążeniowa',
      shortTitle: 'Prewencja Kontuzji',
      description:
          'Regularny monitoring mikrourazów i bike-fittingu ogranicza ryzyko kontuzji oraz wypalenia.',
      passiveEffectSummary: '-6.0% ryzyka kontuzji i chorób / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['phy_periodization_basics'],
      requiredManagerLevel: 3,
      icon: Icons.health_and_safety_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        injuryRiskReductionPct: 6.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'phy_third_week_gt_engine',
      branch: ManagerSkillBranch.physiologyAndTraining,
      tier: ManagerPerkTier.tier3Mastery,
      laneColumn: 1,
      title: 'Wytrzymałość Trzeciego Tygodnia GT',
      shortTitle: '3. Tydzień GT',
      description:
          'Specjalistyczna adaptacja metaboliczna chroniąca moc progową FTP na etapach 15–21 Wielkich Tourów.',
      passiveEffectSummary: '+5.0% odporności w 3. tygodniu GT / poziom',
      maxRank: 2,
      pointCostPerRank: 2,
      prerequisiteNodeIds: <String>[
        'phy_overnight_recovery',
        'phy_injury_prevention',
      ],
      requiredManagerLevel: 6,
      icon: Icons.terrain_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        thirdWeekGtResilienceBonusPct: 5.0,
        postStageRecoveryBonusPct: 2.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'phy_signature_grand_tour_lab',
      branch: ManagerSkillBranch.physiologyAndTraining,
      tier: ManagerPerkTier.tier4Signature,
      laneColumn: 1,
      title: 'Sygnatura: Architekt Szczytu Formy',
      shortTitle: 'Architekt Szczytu',
      description:
          'Pasywny perk mistrzowski: cała drużyna wchodzi w Wielkie Toury i Monumenty z wyższą odpornością na zmęczenie.',
      passiveEffectSummary:
          '+6.0% treningu, +6.0% regeneracji, +6.0% odporności GT',
      maxRank: 1,
      pointCostPerRank: 3,
      prerequisiteNodeIds: <String>['phy_third_week_gt_engine'],
      requiredManagerLevel: 10,
      isSignatureCapstone: true,
      icon: Icons.science_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        trainingEffectivenessBonusPct: 6.0,
        postStageRecoveryBonusPct: 6.0,
        thirdWeekGtResilienceBonusPct: 6.0,
        activeSignaturePerks: <String>['Architekt Szczytu Formy'],
      ),
    ),

    // 3. SKAUTING & AKADEMIA
    ManagerSkillNodeDefinition(
      id: 'sct_talent_radar',
      branch: ManagerSkillBranch.scoutingAndYouth,
      tier: ManagerPerkTier.tier1Foundation,
      laneColumn: 1,
      title: 'Radar Skautingu Regionalnego',
      shortTitle: 'Radar Skautingu',
      description:
          'Sprawniejsza logistyka obserwatorów skraca czas potrzebny na zebranie raportów o kolarzach.',
      passiveEffectSummary: '+5.0% szybkości raportów skautingu / poziom',
      maxRank: 3,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>[],
      requiredManagerLevel: 1,
      icon: Icons.radar_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        scoutingSpeedBonusPct: 5.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'sct_budget_network',
      branch: ManagerSkillBranch.scoutingAndYouth,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 0,
      title: 'Ekonomia Siatki Obserwatorów',
      shortTitle: 'Tańszy Skauting',
      description:
          'Stałe umowy z lokalnymi klubami juniorskim znacząco obniżają koszty wysłania skautów w świat.',
      passiveEffectSummary: '-6.0% kosztów misji skautingowych / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['sct_talent_radar'],
      requiredManagerLevel: 3,
      icon: Icons.savings_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        scoutingCostDiscountPct: 6.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'sct_u23_pipeline',
      branch: ManagerSkillBranch.scoutingAndYouth,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 2,
      title: 'Akcelerator Akademii U23',
      shortTitle: 'Rozwój U23',
      description:
          'Indywidualne ścieżki mentorów dla neoprofesjonalistów przyspieszają progres atrybutów młodzieży.',
      passiveEffectSummary: '+6.0% tempa rozwoju kolarzy U23 / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['sct_talent_radar'],
      requiredManagerLevel: 3,
      icon: Icons.school_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        u23DevelopmentRateBonusPct: 6.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'sct_hidden_gem_eye',
      branch: ManagerSkillBranch.scoutingAndYouth,
      tier: ManagerPerkTier.tier3Mastery,
      laneColumn: 1,
      title: 'Oko do Nieoszlifowanych Diamentów',
      shortTitle: 'Ocena Potencjału',
      description:
          'Zwiększona precyzja oceny sufitu VO2max i ukrytych cech mentalnych w pierwszym raporcie skauta.',
      passiveEffectSummary: '+3 pkt dokładności oceny potencjału / poziom',
      maxRank: 2,
      pointCostPerRank: 2,
      prerequisiteNodeIds: <String>[
        'sct_budget_network',
        'sct_u23_pipeline',
      ],
      requiredManagerLevel: 6,
      icon: Icons.diamond_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        potentialRevealAccuracyBonus: 3,
        scoutingSpeedBonusPct: 3.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'sct_signature_golden_generation',
      branch: ManagerSkillBranch.scoutingAndYouth,
      tier: ManagerPerkTier.tier4Signature,
      laneColumn: 1,
      title: 'Sygnatura: Złote Pokolenie',
      shortTitle: 'Złote Pokolenie',
      description:
          'Pasywny perk mistrzowski: Twoja akademia staje się magnesem na talenty z całego świata i szybciej szlifuje przyszłych mistrzów.',
      passiveEffectSummary:
          '+10% rozwoju U23, +8% szybkości skautingu, +4 pkt precyzji',
      maxRank: 1,
      pointCostPerRank: 3,
      prerequisiteNodeIds: <String>['sct_hidden_gem_eye'],
      requiredManagerLevel: 10,
      isSignatureCapstone: true,
      icon: Icons.auto_awesome_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        u23DevelopmentRateBonusPct: 10.0,
        scoutingSpeedBonusPct: 8.0,
        potentialRevealAccuracyBonus: 4,
        activeSignaturePerks: <String>['Złote Pokolenie'],
      ),
    ),

    // 4. FINANSE & NEGOCJACJE
    ManagerSkillNodeDefinition(
      id: 'fin_sponsor_pitch',
      branch: ManagerSkillBranch.financeAndNegotiation,
      tier: ManagerPerkTier.tier1Foundation,
      laneColumn: 1,
      title: 'Profesjonalne Prezentacje Sponsorskie',
      shortTitle: 'Oferty Sponsorskie',
      description:
          'Lepsze raporty ROI i widoczności TV podnoszą bazowe wyceny kontraktów ze sponsorami tytularnymi.',
      passiveEffectSummary: '+3.0% przychodów od sponsorów / poziom',
      maxRank: 3,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>[],
      requiredManagerLevel: 1,
      icon: Icons.handshake_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        sponsorRevenueBonusPct: 3.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'fin_wage_structure',
      branch: ManagerSkillBranch.financeAndNegotiation,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 0,
      title: 'Twarda Struktura Płacowa',
      shortTitle: 'Kontrola Płac',
      description:
          'Umiejętne wykorzystanie premii za wyniki obniża stałe wymagania płacowe przy przedłużaniu umów.',
      passiveEffectSummary: '-2.5% żądań płacowych kolarzy / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['fin_sponsor_pitch'],
      requiredManagerLevel: 3,
      icon: Icons.payments_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        riderSalaryDiscountPct: 2.5,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'fin_transfer_leverage',
      branch: ManagerSkillBranch.financeAndNegotiation,
      tier: ManagerPerkTier.tier2Specialist,
      laneColumn: 2,
      title: 'Dźwignia na Rynku Transferowym',
      shortTitle: 'Negocjacje Wykupu',
      description:
          'Relacje z agentami pozwalają obniżać klauzule wykupu i prowizje przy transferach gotówkowych.',
      passiveEffectSummary: '-4.0% kosztów wykupu transferów / poziom',
      maxRank: 2,
      pointCostPerRank: 1,
      prerequisiteNodeIds: <String>['fin_sponsor_pitch'],
      requiredManagerLevel: 3,
      icon: Icons.currency_exchange_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        transferFeeDiscountPct: 4.0,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'fin_locker_room_harmony',
      branch: ManagerSkillBranch.financeAndNegotiation,
      tier: ManagerPerkTier.tier3Mastery,
      laneColumn: 1,
      title: 'Dyplomacja Szatni i Liderów',
      shortTitle: 'Harmonia Szatni',
      description:
          'Sprawiedliwy podział ról na Wielkie Toury łagodzi ego gwiazd i stabilizuje morale całego składu.',
      passiveEffectSummary: '+4.0 pkt stabilności morale / poziom',
      maxRank: 2,
      pointCostPerRank: 2,
      prerequisiteNodeIds: <String>[
        'fin_wage_structure',
        'fin_transfer_leverage',
      ],
      requiredManagerLevel: 6,
      icon: Icons.groups_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        moraleStabilityBonus: 4.0,
        sponsorRevenueBonusPct: 1.5,
      ),
    ),
    ManagerSkillNodeDefinition(
      id: 'fin_signature_dynasty_ceo',
      branch: ManagerSkillBranch.financeAndNegotiation,
      tier: ManagerPerkTier.tier4Signature,
      laneColumn: 1,
      title: 'Sygnatura: Magnat WorldTouru',
      shortTitle: 'Magnat WorldTouru',
      description:
          'Pasywny perk mistrzowski: globalni sponsorzy zabiegają o miejsce na Twojej koszulce, a budżet klubu zyskuje żelazną stabilność.',
      passiveEffectSummary:
          '+7.0% przychodów sponsorskich, -4.0% płac, -5.0% transferów',
      maxRank: 1,
      pointCostPerRank: 3,
      prerequisiteNodeIds: <String>['fin_locker_room_harmony'],
      requiredManagerLevel: 10,
      isSignatureCapstone: true,
      icon: Icons.monetization_on_rounded,
      perRankEffects: ManagerSkillPerkEffects(
        sponsorRevenueBonusPct: 7.0,
        riderSalaryDiscountPct: 4.0,
        transferFeeDiscountPct: 5.0,
        activeSignaturePerks: <String>['Magnat WorldTouru'],
      ),
    ),
  ];

  static final Map<String, ManagerSkillNodeDefinition> _nodeIndex =
      <String, ManagerSkillNodeDefinition>{
    for (final node in nodes) node.id: node,
  };

  static ManagerSkillNodeDefinition? byId(String id) => _nodeIndex[id];

  static List<ManagerSkillNodeDefinition> byBranch(ManagerSkillBranch branch) {
    return nodes.where((n) => n.branch == branch).toList(growable: false);
  }
}

/// Bezstanowy, deterministyczny serwis drzewka umiejętności i pasywnych perków menedżera.
class ManagerSkillTreePerksService {
  ManagerSkillTreePerksService._();

  static const int maxManagerLevel = 50;

  /// Krzywa wymaganego XP do awansu na kolejny poziom menedżera.
  static int xpRequiredForLevel(int level) {
    final safeLevel = level.clamp(1, maxManagerLevel);
    return 1000 + (safeLevel - 1) * 350;
  }

  /// Przyznaje punkty XP menedżerowi, obsługując wielokrotne awanse poziomów.
  static ManagerSkillTreeState awardExperience(
    ManagerSkillTreeState state, {
    required int xp,
    required ManagerXpSource source,
    required String title,
    DateTime? timestamp,
  }) {
    if (xp <= 0) return state;

    var level = state.managerLevel.clamp(1, maxManagerLevel);
    var currentXp = state.currentXp + xp;
    var gainedSkillPoints = 0;

    while (level < maxManagerLevel && currentXp >= xpRequiredForLevel(level)) {
      currentXp -= xpRequiredForLevel(level);
      level += 1;
      // Co 5. poziom menedżer otrzymuje dodatkowy bonusowy punkt umiejętności.
      gainedSkillPoints += (level % 5 == 0) ? 2 : 1;
    }

    if (level >= maxManagerLevel) {
      currentXp = math.min(currentXp, xpRequiredForLevel(maxManagerLevel));
    }

    final event = ManagerXpEventRecord(
      id: 'xp_${(timestamp ?? DateTime.now()).microsecondsSinceEpoch}',
      source: source,
      title: title,
      xpEarned: xp,
      timestampIso: (timestamp ?? DateTime.now()).toIso8601String(),
    );

    final updatedLog = <ManagerXpEventRecord>[
      event,
      ...state.recentXpLog.take(19),
    ];

    return state.copyWith(
      managerLevel: level,
      currentXp: currentXp,
      totalXpEarned: state.totalXpEarned + xp,
      availableSkillPoints: state.availableSkillPoints + gainedSkillPoints,
      recentXpLog: updatedLog,
    );
  }

  /// Określa bieżący stan węzła w drzewku dla zadanego stanu menedżera.
  static ManagerSkillNodeState getNodeStatus(
    ManagerSkillTreeState state,
    ManagerSkillNodeDefinition node,
  ) {
    final currentRank = state.rankOf(node.id);
    if (currentRank >= node.maxRank) {
      return ManagerSkillNodeState.maxed;
    }
    if (currentRank > 0) {
      return ManagerSkillNodeState.partiallyUnlocked;
    }
    if (state.managerLevel < node.requiredManagerLevel) {
      return ManagerSkillNodeState.locked;
    }
    for (final prereqId in node.prerequisiteNodeIds) {
      if (state.rankOf(prereqId) < 1) {
        return ManagerSkillNodeState.locked;
      }
    }
    return ManagerSkillNodeState.available;
  }

  /// Zwraca powód zablokowania lub braku możliwości ulepszenia węzła, albo null jeśli można ulepszyć.
  static String? unlockBlockerReason(
    ManagerSkillTreeState state,
    String nodeId,
  ) {
    final node = ManagerSkillTreeCatalog.byId(nodeId);
    if (node == null) return 'Nieznany węzeł umiejętności.';

    final currentRank = state.rankOf(nodeId);
    if (currentRank >= node.maxRank) {
      return 'Osiągnięto maksymalny poziom (${node.maxRank}/${node.maxRank}).';
    }
    if (state.managerLevel < node.requiredManagerLevel) {
      return 'Wymagany Poziom Menedżera: ${node.requiredManagerLevel}.';
    }
    for (final prereqId in node.prerequisiteNodeIds) {
      if (state.rankOf(prereqId) < 1) {
        final prereq = ManagerSkillTreeCatalog.byId(prereqId);
        return 'Odblokuj najpierw: ${prereq?.shortTitle ?? prereqId}.';
      }
    }
    if (state.availableSkillPoints < node.pointCostPerRank) {
      return 'Brak punktów umiejętności (wymagane ${node.pointCostPerRank} pkt).';
    }
    return null;
  }

  static bool canUnlockNode(ManagerSkillTreeState state, String nodeId) {
    return unlockBlockerReason(state, nodeId) == null;
  }

  /// Odblokowuje kolejny poziom wybranego węzła umiejętności.
  static SkillUnlockResult unlockSkillRank(
    ManagerSkillTreeState state,
    String nodeId,
  ) {
    final node = ManagerSkillTreeCatalog.byId(nodeId);
    if (node == null) {
      return SkillUnlockResult(
        success: false,
        message: 'Nie znaleziono węzła umiejętności.',
        state: state,
      );
    }

    final blocker = unlockBlockerReason(state, nodeId);
    if (blocker != null) {
      return SkillUnlockResult(
        success: false,
        message: blocker,
        state: state,
      );
    }

    final nextRank = state.rankOf(nodeId) + 1;
    final updatedRanks = Map<String, int>.from(state.unlockedRanks)
      ..[nodeId] = nextRank;

    final updatedState = state.copyWith(
      availableSkillPoints: state.availableSkillPoints - node.pointCostPerRank,
      spentSkillPoints: state.spentSkillPoints + node.pointCostPerRank,
      unlockedRanks: updatedRanks,
      selectedNodeId: nodeId,
    );

    return SkillUnlockResult(
      success: true,
      message:
          'Odblokowano: ${node.shortTitle} (poziom $nextRank/${node.maxRank}).',
      state: updatedState,
      unlockedNodeId: nodeId,
      newRank: nextRank,
    );
  }

  /// Resetuje całe drzewko, zwracając wszystkie wydane punkty umiejętności.
  static ManagerSkillTreeState refundAllSkills(ManagerSkillTreeState state) {
    if (state.spentSkillPoints == 0 && state.unlockedRanks.isEmpty) {
      return state;
    }
    var refundedPoints = 0;
    for (final entry in state.unlockedRanks.entries) {
      final node = ManagerSkillTreeCatalog.byId(entry.key);
      if (node != null) {
        refundedPoints += entry.value * node.pointCostPerRank;
      }
    }
    return state.copyWith(
      availableSkillPoints: state.availableSkillPoints + refundedPoints,
      spentSkillPoints: 0,
      unlockedRanks: const <String, int>{},
      respecCount: state.respecCount + 1,
    );
  }

  /// Wylicza skumulowane efekty wszystkich odblokowanych perków.
  static ManagerSkillPerkEffects computeAggregateEffects(
    Map<String, int> unlockedRanks,
  ) {
    var total = ManagerSkillPerkEffects.zero;
    for (final entry in unlockedRanks.entries) {
      if (entry.value <= 0) continue;
      final node = ManagerSkillTreeCatalog.byId(entry.key);
      if (node == null) continue;
      final clampedRank = entry.value.clamp(0, node.maxRank);
      total = total + node.perRankEffects.scaled(clampedRank);
    }
    return total;
  }

  /// Zwraca maksymalnie 3 rekomendowane kolejne węzły możliwe do ulepszenia.
  static List<ManagerSkillNodeDefinition> recommendedNextNodes(
    ManagerSkillTreeState state,
  ) {
    final candidates = ManagerSkillTreeCatalog.nodes
        .where((node) => canUnlockNode(state, node.id))
        .toList(growable: false);
    if (candidates.length <= 3) return candidates;
    return candidates.take(3).toList(growable: false);
  }
}

/// Kontroler Riverpod zarządzający drzewkiem umiejętności i perkami menedżera.
class ManagerSkillTreeNotifier extends StateNotifier<ManagerSkillTreeState> {
  ManagerSkillTreeNotifier([ManagerSkillTreeState? initialState])
      : super(initialState ?? ManagerSkillTreeState.initial());

  void selectBranch(ManagerSkillBranch? branch) {
    if (branch == null) {
      state = state.copyWith(clearBranchFilter: true);
    } else {
      final firstInBranch = ManagerSkillTreeCatalog.byBranch(branch).first.id;
      state = state.copyWith(
        selectedBranchFilter: branch,
        selectedNodeId: firstInBranch,
      );
    }
  }

  void selectNode(String nodeId) {
    if (ManagerSkillTreeCatalog.byId(nodeId) == null) return;
    state = state.copyWith(selectedNodeId: nodeId);
  }

  SkillUnlockResult unlockNode(String nodeId) {
    final result = ManagerSkillTreePerksService.unlockSkillRank(state, nodeId);
    if (result.success) {
      state = result.state;
    }
    return result;
  }

  void grantXp({
    required int xp,
    required ManagerXpSource source,
    required String title,
  }) {
    state = ManagerSkillTreePerksService.awardExperience(
      state,
      xp: xp,
      source: source,
      title: title,
    );
  }

  void respecTree() {
    state = ManagerSkillTreePerksService.refundAllSkills(state);
  }

  void loadFromJson(Map<String, dynamic> json) {
    state = ManagerSkillTreeState.fromJson(json);
  }

  void resetToInitial() {
    state = ManagerSkillTreeState.initial();
  }
}

final managerSkillTreeProvider =
    StateNotifierProvider<ManagerSkillTreeNotifier, ManagerSkillTreeState>(
  (ref) => ManagerSkillTreeNotifier(),
);

final managerPassivePerksProvider = Provider<ManagerSkillPerkEffects>((ref) {
  final treeState = ref.watch(managerSkillTreeProvider);
  return treeState.aggregateEffects;
});

/// Interaktywny panel drzewka umiejętności i pasywnych perków menedżera.
class ManagerSkillTreePerksPanel extends ConsumerStatefulWidget {
  const ManagerSkillTreePerksPanel({super.key});

  @override
  ConsumerState<ManagerSkillTreePerksPanel> createState() =>
      _ManagerSkillTreePerksPanelState();
}

class _ManagerSkillTreePerksPanelState
    extends ConsumerState<ManagerSkillTreePerksPanel> {
  String? _statusBannerMessage;
  bool _statusBannerIsError = false;

  void _handleUnlock(String nodeId) {
    final result =
        ref.read(managerSkillTreeProvider.notifier).unlockNode(nodeId);
    setState(() {
      _statusBannerMessage = result.message;
      _statusBannerIsError = !result.success;
    });
  }

  Future<void> _confirmRespec() async {
    final state = ref.read(managerSkillTreeProvider);
    if (state.spentSkillPoints == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor, width: 1),
          ),
          title: const Text(
            'Resetować drzewko umiejętności?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Wszystkie wydane punkty (${state.spentSkillPoints} pkt) wrócą do puli dostępnych punktów menedżera.',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Anuluj',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Resetuj punkty',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ref.read(managerSkillTreeProvider.notifier).respecTree();
      setState(() {
        _statusBannerMessage =
            'Zresetowano drzewko. Punkty wróciły do puli menedżera.';
        _statusBannerIsError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final treeState = ref.watch(managerSkillTreeProvider);
    final selectedNode = ManagerSkillTreeCatalog.byId(
          treeState.selectedNodeId ?? '',
        ) ??
        ManagerSkillTreeCatalog.nodes.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 720;
        final isDesktop = width >= 1180;

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
                _HeaderOverviewCard(
                  state: treeState,
                  isMobile: isMobile,
                  onRespec: _confirmRespec,
                ),
                if (_statusBannerMessage != null) ...[
                  const SizedBox(height: 12),
                  _StatusFeedbackBanner(
                    message: _statusBannerMessage!,
                    isError: _statusBannerIsError,
                    onDismiss: () =>
                        setState(() => _statusBannerMessage = null),
                  ),
                ],
                const SizedBox(height: 16),
                _BranchFilterStrip(
                  selectedBranch: treeState.selectedBranchFilter,
                  state: treeState,
                  onSelectBranch: (branch) {
                    ref
                        .read(managerSkillTreeProvider.notifier)
                        .selectBranch(branch);
                  },
                ),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _TreeCanvasArea(
                          state: treeState,
                          isMobile: false,
                          onSelectNode: (id) => ref
                              .read(managerSkillTreeProvider.notifier)
                              .selectNode(id),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _NodeInspectorCard(
                              state: treeState,
                              node: selectedNode,
                              onUnlock: () => _handleUnlock(selectedNode.id),
                            ),
                            const SizedBox(height: 16),
                            _PassivePerksSummaryCard(
                              effects: treeState.aggregateEffects,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _TreeCanvasArea(
                    state: treeState,
                    isMobile: isMobile,
                    onSelectNode: (id) => ref
                        .read(managerSkillTreeProvider.notifier)
                        .selectNode(id),
                  ),
                  const SizedBox(height: 16),
                  _NodeInspectorCard(
                    state: treeState,
                    node: selectedNode,
                    onUnlock: () => _handleUnlock(selectedNode.id),
                  ),
                  const SizedBox(height: 16),
                  _PassivePerksSummaryCard(
                    effects: treeState.aggregateEffects,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderOverviewCard extends StatelessWidget {
  final ManagerSkillTreeState state;
  final bool isMobile;
  final VoidCallback onRespec;

  const _HeaderOverviewCard({
    required this.state,
    required this.isMobile,
    required this.onRespec,
  });

  @override
  Widget build(BuildContext context) {
    final xpBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars_rounded,
            color: AppColors.goldAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DOSTĘPNE PUNKTY',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '${state.availableSkillPoints} SP',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final respecButton = _InteractiveActionButton(
      label: 'Reset (${state.spentSkillPoints})',
      icon: Icons.restart_alt_rounded,
      enabled: state.spentSkillPoints > 0,
      accentColor: AppColors.primaryAccent,
      onPressed: onRespec,
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
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
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryAccent),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${state.managerLevel}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drzewko Umiejętności Menedżera',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Poziom ${state.managerLevel} · ${state.currentUnlockedRanks}/${state.totalPossibleRanks} rang odblokowanych',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  xpBadge,
                  respecButton,
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: state.levelProgressRatio),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.goldAccent,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${state.currentXp} / ${state.xpForNextLevel} XP',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusFeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _StatusFeedbackBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchFilterStrip extends StatelessWidget {
  final ManagerSkillBranch? selectedBranch;
  final ManagerSkillTreeState state;
  final ValueChanged<ManagerSkillBranch?> onSelectBranch;

  const _BranchFilterStrip({
    required this.selectedBranch,
    required this.state,
    required this.onSelectBranch,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BranchChip(
            label: 'Wszystkie gałęzie',
            icon: Icons.hub_rounded,
            accentColor: AppColors.primaryAccent,
            selected: selectedBranch == null,
            onTap: () => onSelectBranch(null),
          ),
          const SizedBox(width: 8),
          for (final branch in ManagerSkillBranch.values) ...[
            _BranchChip(
              label: branch.shortTitle,
              icon: branch.icon,
              accentColor: branch.accentColor,
              selected: selectedBranch == branch,
              onTap: () => onSelectBranch(branch),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _BranchChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  const _BranchChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_BranchChip> createState() => _BranchChipState();
}

class _BranchChipState extends State<_BranchChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: 0.22)
        : _pressed
            ? AppColors.surfaceLight
            : _hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.85)
                : AppColors.surface;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? widget.accentColor
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.6)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                color: widget.selected
                    ? widget.accentColor
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
    );
  }
}

class _TreeCanvasArea extends StatelessWidget {
  final ManagerSkillTreeState state;
  final bool isMobile;
  final ValueChanged<String> onSelectNode;

  const _TreeCanvasArea({
    required this.state,
    required this.isMobile,
    required this.onSelectNode,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBranches = state.selectedBranchFilter != null
        ? <ManagerSkillBranch>[state.selectedBranchFilter!]
        : ManagerSkillBranch.values;

    return Column(
      children: [
        for (final branch in visibleBranches) ...[
          _BranchSkillTreeCard(
            branch: branch,
            state: state,
            isMobile: isMobile,
            onSelectNode: onSelectNode,
          ),
          if (branch != visibleBranches.last) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _BranchSkillTreeCard extends StatelessWidget {
  final ManagerSkillBranch branch;
  final ManagerSkillTreeState state;
  final bool isMobile;
  final ValueChanged<String> onSelectNode;

  const _BranchSkillTreeCard({
    required this.branch,
    required this.state,
    required this.isMobile,
    required this.onSelectNode,
  });

  @override
  Widget build(BuildContext context) {
    final branchNodes = ManagerSkillTreeCatalog.byBranch(branch);
    final tier1 = branchNodes
        .where((n) => n.tier == ManagerPerkTier.tier1Foundation)
        .toList();
    final tier2 = branchNodes
        .where((n) => n.tier == ManagerPerkTier.tier2Specialist)
        .toList();
    final tier3 = branchNodes
        .where((n) => n.tier == ManagerPerkTier.tier3Mastery)
        .toList();
    final tier4 = branchNodes
        .where((n) => n.tier == ManagerPerkTier.tier4Signature)
        .toList();

    final unlockedInBranch = branchNodes.fold<int>(
      0,
      (sum, node) => sum + state.rankOf(node.id),
    );
    final maxInBranch = branchNodes.fold<int>(
      0,
      (sum, node) => sum + node.maxRank,
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: branch.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(branch.icon, color: branch.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      branch.description,
                      maxLines: 2,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  '$unlockedInBranch/$maxInBranch',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: branch.accentColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomPaint(
            painter: _BranchDependencyPainter(
              branchNodes: branchNodes,
              state: state,
              branchColor: branch.accentColor,
            ),
            child: Column(
              children: [
                if (tier1.isNotEmpty)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 260,
                      ),
                      child: _SkillNodeTile(
                        node: tier1.first,
                        state: state,
                        onTap: () => onSelectNode(tier1.first.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (tier2.isNotEmpty)
                  Row(
                    children: [
                      for (var i = 0; i < tier2.length; i++) ...[
                        Expanded(
                          child: _SkillNodeTile(
                            node: tier2[i],
                            state: state,
                            onTap: () => onSelectNode(tier2[i].id),
                          ),
                        ),
                        if (i < tier2.length - 1) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                const SizedBox(height: 16),
                if (tier3.isNotEmpty)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 260,
                      ),
                      child: _SkillNodeTile(
                        node: tier3.first,
                        state: state,
                        onTap: () => onSelectNode(tier3.first.id),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (tier4.isNotEmpty)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 290,
                      ),
                      child: _SkillNodeTile(
                        node: tier4.first,
                        state: state,
                        onTap: () => onSelectNode(tier4.first.id),
                      ),
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

class _BranchDependencyPainter extends CustomPainter {
  final List<ManagerSkillNodeDefinition> branchNodes;
  final ManagerSkillTreeState state;
  final Color branchColor;

  const _BranchDependencyPainter({
    required this.branchNodes,
    required this.state,
    required this.branchColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rowYs = <double>[
      size.height * 0.12,
      size.height * 0.37,
      size.height * 0.63,
      size.height * 0.88,
    ];

    final centerX = size.width * 0.5;
    final leftX = size.width * 0.25;
    final rightX = size.width * 0.75;

    final t1Active =
        branchNodes.any((n) => n.tier == ManagerPerkTier.tier1Foundation && state.rankOf(n.id) > 0);
    final t2LeftActive = branchNodes.any(
      (n) =>
          n.tier == ManagerPerkTier.tier2Specialist &&
          n.laneColumn == 0 &&
          state.rankOf(n.id) > 0,
    );
    final t2RightActive = branchNodes.any(
      (n) =>
          n.tier == ManagerPerkTier.tier2Specialist &&
          n.laneColumn == 2 &&
          state.rankOf(n.id) > 0,
    );
    final t3Active =
        branchNodes.any((n) => n.tier == ManagerPerkTier.tier3Mastery && state.rankOf(n.id) > 0);

    _drawLink(canvas, Offset(centerX, rowYs[0]), Offset(leftX, rowYs[1]),
        t1Active);
    _drawLink(canvas, Offset(centerX, rowYs[0]), Offset(rightX, rowYs[1]),
        t1Active);
    _drawLink(canvas, Offset(leftX, rowYs[1]), Offset(centerX, rowYs[2]),
        t2LeftActive);
    _drawLink(canvas, Offset(rightX, rowYs[1]), Offset(centerX, rowYs[2]),
        t2RightActive);
    _drawLink(canvas, Offset(centerX, rowYs[2]), Offset(centerX, rowYs[3]),
        t3Active);
  }

  void _drawLink(Canvas canvas, Offset start, Offset end, bool active) {
    final paint = Paint()
      ..color = active
          ? branchColor.withValues(alpha: 0.7)
          : AppTheme.borderColor.withValues(alpha: 0.8)
      ..strokeWidth = active ? 2.2 : 1.4
      ..style = PaintingStyle.stroke;

    final midY = (start.dy + end.dy) / 2;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BranchDependencyPainter oldDelegate) {
    return oldDelegate.state.unlockedRanks != state.unlockedRanks ||
        oldDelegate.branchColor != branchColor;
  }
}

class _SkillNodeTile extends StatefulWidget {
  final ManagerSkillNodeDefinition node;
  final ManagerSkillTreeState state;
  final VoidCallback onTap;

  const _SkillNodeTile({
    required this.node,
    required this.state,
    required this.onTap,
  });

  @override
  State<_SkillNodeTile> createState() => _SkillNodeTileState();
}

class _SkillNodeTileState extends State<_SkillNodeTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final rank = widget.state.rankOf(widget.node.id);
    final status =
        ManagerSkillTreePerksService.getNodeStatus(widget.state, widget.node);
    final isSelected = widget.state.selectedNodeId == widget.node.id;
    final isLocked = status == ManagerSkillNodeState.locked;
    final isMaxed = status == ManagerSkillNodeState.maxed;

    final accent = widget.node.isSignatureCapstone
        ? AppColors.goldAccent
        : widget.node.branch.accentColor;

    final bgColor = _pressed
        ? AppColors.surfaceLight
        : isSelected
            ? accent.withValues(alpha: 0.18)
            : _hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : AppColors.background.withValues(alpha: 0.85);

    final borderColor = _focused
        ? AppColors.goldAccent
        : isSelected
            ? accent
            : isMaxed
                ? accent.withValues(alpha: 0.85)
                : _hovered
                    ? accent.withValues(alpha: 0.6)
                    : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected || _focused ? 1.6 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: isLocked ? 0.62 : 1.0,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? AppColors.surfaceLight
                        : accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isLocked ? AppTheme.borderColor : accent,
                    ),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_outline_rounded : widget.node.icon,
                    size: 17,
                    color: isLocked ? AppColors.textSecondary : accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.node.shortTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.node.tier.label.split('·').first.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMaxed
                        ? accent.withValues(alpha: 0.22)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$rank/${widget.node.maxRank}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isMaxed ? accent : AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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

class _NodeInspectorCard extends StatelessWidget {
  final ManagerSkillTreeState state;
  final ManagerSkillNodeDefinition node;
  final VoidCallback onUnlock;

  const _NodeInspectorCard({
    required this.state,
    required this.node,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final rank = state.rankOf(node.id);
    final status = ManagerSkillTreePerksService.getNodeStatus(state, node);
    final blocker =
        ManagerSkillTreePerksService.unlockBlockerReason(state, node.id);
    final canUnlock = blocker == null;
    final accent =
        node.isSignatureCapstone ? AppColors.goldAccent : node.branch.accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent),
                ),
                child: Icon(node.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.tier.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            node.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EFEKT PASYWNY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  node.passiveEffectSummary,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InspectorMetaPill(
                label: 'Ranga: $rank/${node.maxRank}',
                color: accent,
              ),
              _InspectorMetaPill(
                label: 'Koszt: ${node.pointCostPerRank} SP',
                color: AppColors.goldAccent,
              ),
              _InspectorMetaPill(
                label: 'Wym. Poz.: ${node.requiredManagerLevel}',
                color: state.managerLevel >= node.requiredManagerLevel
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _InspectorMetaPill(
                label: status.label,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (blocker != null) ...[
            const SizedBox(height: 12),
            Text(
              blocker,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.amberWarning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _InteractiveActionButton(
              label: rank >= node.maxRank
                  ? 'Maksymalna ranga'
                  : 'Odblokuj rangę (${node.pointCostPerRank} SP)',
              icon: rank >= node.maxRank
                  ? Icons.verified_rounded
                  : Icons.upgrade_rounded,
              enabled: canUnlock,
              accentColor: accent,
              onPressed: onUnlock,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorMetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InspectorMetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

class _PassivePerksSummaryCard extends StatelessWidget {
  final ManagerSkillPerkEffects effects;

  const _PassivePerksSummaryCard({required this.effects});

  @override
  Widget build(BuildContext context) {
    final rows = <_PerkMetricEntry>[
      _PerkMetricEntry(
        'Taktyka & Rozkazy',
        '+${effects.raceTacticalExecutionBonusPct.toStringAsFixed(1)}%',
        AppColors.accentBlue,
      ),
      _PerkMetricEntry(
        'Ranty na wietrze',
        '+${effects.echelonPositioningBonusPct.toStringAsFixed(1)}%',
        AppColors.accentBlue,
      ),
      _PerkMetricEntry(
        'Trening & Regeneracja',
        '+${(effects.trainingEffectivenessBonusPct + effects.postStageRecoveryBonusPct).toStringAsFixed(1)}%',
        AppColors.statusSuccess,
      ),
      _PerkMetricEntry(
        'Odporność 3. tyg. GT',
        '+${effects.thirdWeekGtResilienceBonusPct.toStringAsFixed(1)}%',
        AppColors.statusSuccess,
      ),
      _PerkMetricEntry(
        'Skauting & Rozwój U23',
        '+${(effects.scoutingSpeedBonusPct + effects.u23DevelopmentRateBonusPct).toStringAsFixed(1)}%',
        AppColors.cyanAccent,
      ),
      _PerkMetricEntry(
        'Przychody Sponsorów',
        '+${effects.sponsorRevenueBonusPct.toStringAsFixed(1)}%',
        AppColors.goldAccent,
      ),
      _PerkMetricEntry(
        'Oszczędność Płac',
        '-${effects.riderSalaryDiscountPct.toStringAsFixed(1)}%',
        AppColors.goldAccent,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aktywne Perki Pasywne',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: row.color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (effects.activeSignaturePerks.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppTheme.borderColor, height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final perk in effects.activeSignaturePerks)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldAccent),
                    ),
                    child: Text(
                      perk,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PerkMetricEntry {
  final String label;
  final String value;
  final Color color;

  const _PerkMetricEntry(this.label, this.value, this.color);
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.72)
            : _hovered
                ? widget.accentColor
                : widget.accentColor.withValues(alpha: 0.88);
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.enabled
            ? widget.accentColor
            : AppTheme.borderColor;
    final fgColor = widget.enabled ? Colors.white : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 17, color: fgColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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
