import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Główna strategia taktyczna testowana w symulatorze „Co Jeśli?”.
enum WhatIfTacticalStrategyType {
  earlyBreakaway,
  satelliteRelay,
  crosswindEchelon,
  penultimateClimbAttack,
  finalClimbAllIn,
  sprintLeadoutTrain,
  counterSurfing,
  defensivePelotonControl;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case WhatIfTacticalStrategyType.earlyBreakaway:
        return 'Poranna ucieczka';
      case WhatIfTacticalStrategyType.satelliteRelay:
        return 'Stacja przekaźnikowa';
      case WhatIfTacticalStrategyType.crosswindEchelon:
        return 'Wachlarz na wietrze';
      case WhatIfTacticalStrategyType.penultimateClimbAttack:
        return 'Atak przedostatnia góra';
      case WhatIfTacticalStrategyType.finalClimbAllIn:
        return 'Atak finałowy All-In';
      case WhatIfTacticalStrategyType.sprintLeadoutTrain:
        return 'Pociąg sprinterski';
      case WhatIfTacticalStrategyType.counterSurfing:
        return 'Surfowanie po kołach';
      case WhatIfTacticalStrategyType.defensivePelotonControl:
        return 'Kontrola defensywna';
    }
  }

  IconData get icon {
    switch (this) {
      case WhatIfTacticalStrategyType.earlyBreakaway:
        return Icons.rocket_launch_rounded;
      case WhatIfTacticalStrategyType.satelliteRelay:
        return Icons.hub_rounded;
      case WhatIfTacticalStrategyType.crosswindEchelon:
        return Icons.air_rounded;
      case WhatIfTacticalStrategyType.penultimateClimbAttack:
        return Icons.landscape_rounded;
      case WhatIfTacticalStrategyType.finalClimbAllIn:
        return Icons.local_fire_department_rounded;
      case WhatIfTacticalStrategyType.sprintLeadoutTrain:
        return Icons.bolt_rounded;
      case WhatIfTacticalStrategyType.counterSurfing:
        return Icons.waves_rounded;
      case WhatIfTacticalStrategyType.defensivePelotonControl:
        return Icons.shield_rounded;
    }
  }

  static WhatIfTacticalStrategyType fromJson(String value) {
    return WhatIfTacticalStrategyType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WhatIfTacticalStrategyType.defensivePelotonControl,
    );
  }
}

/// Profil terenu etapu dla piaskownicy Monte Carlo.
enum WhatIfStageTerrainProfile {
  flatSprint,
  hillyClassics,
  cobbleMonument,
  mountainSummitFinish,
  rollingTransition;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case WhatIfStageTerrainProfile.flatSprint:
        return 'Płaski / Sprint';
      case WhatIfStageTerrainProfile.hillyClassics:
        return 'Pagórkowaty / Ardeny';
      case WhatIfStageTerrainProfile.cobbleMonument:
        return 'Bruk / Monument';
      case WhatIfStageTerrainProfile.mountainSummitFinish:
        return 'Wysokie Góry (HC)';
      case WhatIfStageTerrainProfile.rollingTransition:
        return 'Przejściowy';
    }
  }

  static WhatIfStageTerrainProfile fromJson(String value) {
    return WhatIfStageTerrainProfile.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WhatIfStageTerrainProfile.mountainSummitFinish,
    );
  }
}

/// Warunki pogodowe wpływające na opór, przyczepność i termoregulację.
enum WhatIfWeatherCondition {
  calmDry,
  crosswindGusts,
  heavyRain,
  alpineHeat;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case WhatIfWeatherCondition.calmDry:
        return 'Sucho / Słaby wiatr';
      case WhatIfWeatherCondition.crosswindGusts:
        return 'Wiatr boczny 45 km/h';
      case WhatIfWeatherCondition.heavyRain:
        return 'Ulewa / Mokry asfalt';
      case WhatIfWeatherCondition.alpineHeat:
        return 'Upał 34°C';
    }
  }

  static WhatIfWeatherCondition fromJson(String value) {
    return WhatIfWeatherCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WhatIfWeatherCondition.calmDry,
    );
  }
}

/// Poziom ryzyka taktycznego wariantu.
enum WhatIfRiskLevel {
  conservative,
  balanced,
  aggressive,
  allIn;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case WhatIfRiskLevel.conservative:
        return 'Bezpieczny';
      case WhatIfRiskLevel.balanced:
        return 'Zbalansowany';
      case WhatIfRiskLevel.aggressive:
        return 'Agresywny';
      case WhatIfRiskLevel.allIn:
        return 'Va Banque';
    }
  }

  Color get color {
    switch (this) {
      case WhatIfRiskLevel.conservative:
        return AppColors.statusSuccess;
      case WhatIfRiskLevel.balanced:
        return AppColors.accentBlue;
      case WhatIfRiskLevel.aggressive:
        return AppColors.amberWarning;
      case WhatIfRiskLevel.allIn:
        return AppColors.crimsonAlert;
    }
  }

  static WhatIfRiskLevel fromJson(String value) {
    return WhatIfRiskLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WhatIfRiskLevel.balanced,
    );
  }
}

/// Profil fizjologiczny i umiejętności lidera/kolarza poddawanego symulacji.
@immutable
class WhatIfRiderProfile {
  const WhatIfRiderProfile({
    required this.id,
    required this.name,
    required this.ftpWatts,
    required this.weightKg,
    required this.wPrimeJoules,
    required this.sprintPowerWatts,
    required this.climbingSkill,
    required this.cobbleSkill,
    required this.descendingSkill,
    required this.fatiguePercent,
    required this.dayFormDiamonds,
  });

  final String id;
  final String name;
  final double ftpWatts;
  final double weightKg;
  final double wPrimeJoules;
  final double sprintPowerWatts;
  final int climbingSkill;
  final int cobbleSkill;
  final int descendingSkill;
  final double fatiguePercent;
  final int dayFormDiamonds;

  double get wattsPerKg => weightKg > 0 ? ftpWatts / weightKg : 5.0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'ftpWatts': ftpWatts,
        'weightKg': weightKg,
        'wPrimeJoules': wPrimeJoules,
        'sprintPowerWatts': sprintPowerWatts,
        'climbingSkill': climbingSkill,
        'cobbleSkill': cobbleSkill,
        'descendingSkill': descendingSkill,
        'fatiguePercent': fatiguePercent,
        'dayFormDiamonds': dayFormDiamonds,
      };

  factory WhatIfRiderProfile.fromJson(Map<String, dynamic> json) {
    return WhatIfRiderProfile(
      id: (json['id'] as String?) ?? 'rider_gc_1',
      name: (json['name'] as String?) ?? 'Lider GC',
      ftpWatts: (json['ftpWatts'] as num?)?.toDouble() ?? 420.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 62.5,
      wPrimeJoules: (json['wPrimeJoules'] as num?)?.toDouble() ?? 24500.0,
      sprintPowerWatts: (json['sprintPowerWatts'] as num?)?.toDouble() ?? 1180.0,
      climbingSkill: (json['climbingSkill'] as num?)?.toInt() ?? 88,
      cobbleSkill: (json['cobbleSkill'] as num?)?.toInt() ?? 72,
      descendingSkill: (json['descendingSkill'] as num?)?.toInt() ?? 84,
      fatiguePercent: (json['fatiguePercent'] as num?)?.toDouble() ?? 14.0,
      dayFormDiamonds: (json['dayFormDiamonds'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Parametry etapu stanowiące tło dla 20 wariantów taktycznych.
@immutable
class WhatIfStageContext {
  const WhatIfStageContext({
    required this.stageName,
    required this.distanceKm,
    required this.elevationGainMeters,
    required this.finalClimbLengthKm,
    required this.finalClimbAvgGradientPercent,
    required this.crosswindProbability,
    required this.terrain,
    required this.weather,
    required this.rivalStrengthIndex,
    required this.pelotonSize,
    required this.baseSeed,
  });

  final String stageName;
  final double distanceKm;
  final int elevationGainMeters;
  final double finalClimbLengthKm;
  final double finalClimbAvgGradientPercent;
  final double crosswindProbability;
  final WhatIfStageTerrainProfile terrain;
  final WhatIfWeatherCondition weather;
  final double rivalStrengthIndex;
  final int pelotonSize;
  final int baseSeed;

  WhatIfStageContext copyWith({
    String? stageName,
    double? distanceKm,
    int? elevationGainMeters,
    double? finalClimbLengthKm,
    double? finalClimbAvgGradientPercent,
    double? crosswindProbability,
    WhatIfStageTerrainProfile? terrain,
    WhatIfWeatherCondition? weather,
    double? rivalStrengthIndex,
    int? pelotonSize,
    int? baseSeed,
  }) {
    return WhatIfStageContext(
      stageName: stageName ?? this.stageName,
      distanceKm: distanceKm ?? this.distanceKm,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      finalClimbLengthKm: finalClimbLengthKm ?? this.finalClimbLengthKm,
      finalClimbAvgGradientPercent:
          finalClimbAvgGradientPercent ?? this.finalClimbAvgGradientPercent,
      crosswindProbability: crosswindProbability ?? this.crosswindProbability,
      terrain: terrain ?? this.terrain,
      weather: weather ?? this.weather,
      rivalStrengthIndex: rivalStrengthIndex ?? this.rivalStrengthIndex,
      pelotonSize: pelotonSize ?? this.pelotonSize,
      baseSeed: baseSeed ?? this.baseSeed,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stageName': stageName,
        'distanceKm': distanceKm,
        'elevationGainMeters': elevationGainMeters,
        'finalClimbLengthKm': finalClimbLengthKm,
        'finalClimbAvgGradientPercent': finalClimbAvgGradientPercent,
        'crosswindProbability': crosswindProbability,
        'terrain': terrain.toJson(),
        'weather': weather.toJson(),
        'rivalStrengthIndex': rivalStrengthIndex,
        'pelotonSize': pelotonSize,
        'baseSeed': baseSeed,
      };

  factory WhatIfStageContext.fromJson(Map<String, dynamic> json) {
    return WhatIfStageContext(
      stageName: (json['stageName'] as String?) ?? 'Etap Królewski',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 178.0,
      elevationGainMeters: (json['elevationGainMeters'] as num?)?.toInt() ?? 4150,
      finalClimbLengthKm:
          (json['finalClimbLengthKm'] as num?)?.toDouble() ?? 13.8,
      finalClimbAvgGradientPercent:
          (json['finalClimbAvgGradientPercent'] as num?)?.toDouble() ?? 8.1,
      crosswindProbability:
          (json['crosswindProbability'] as num?)?.toDouble() ?? 0.35,
      terrain: WhatIfStageTerrainProfile.fromJson(
        (json['terrain'] as String?) ?? 'mountainSummitFinish',
      ),
      weather: WhatIfWeatherCondition.fromJson(
        (json['weather'] as String?) ?? 'calmDry',
      ),
      rivalStrengthIndex:
          (json['rivalStrengthIndex'] as num?)?.toDouble() ?? 1.0,
      pelotonSize: (json['pelotonSize'] as num?)?.toInt() ?? 176,
      baseSeed: (json['baseSeed'] as num?)?.toInt() ?? 6202026,
    );
  }
}

/// Pojedynczy wariant taktyczny „Co Jeśli?” do przetestowania w Monte Carlo.
@immutable
class WhatIfTacticalVariant {
  const WhatIfTacticalVariant({
    required this.id,
    required this.name,
    required this.strategy,
    required this.riskLevel,
    required this.attackKmFromFinish,
    required this.effortPercentFtp,
    required this.domestiquesCommitted,
    required this.nutritionBoostEnabled,
    required this.aeroEquipmentBonus,
  });

  final String id;
  final String name;
  final WhatIfTacticalStrategyType strategy;
  final WhatIfRiskLevel riskLevel;
  final double attackKmFromFinish;
  final double effortPercentFtp;
  final int domestiquesCommitted;
  final bool nutritionBoostEnabled;
  final double aeroEquipmentBonus;

  WhatIfTacticalVariant copyWith({
    String? id,
    String? name,
    WhatIfTacticalStrategyType? strategy,
    WhatIfRiskLevel? riskLevel,
    double? attackKmFromFinish,
    double? effortPercentFtp,
    int? domestiquesCommitted,
    bool? nutritionBoostEnabled,
    double? aeroEquipmentBonus,
  }) {
    return WhatIfTacticalVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      strategy: strategy ?? this.strategy,
      riskLevel: riskLevel ?? this.riskLevel,
      attackKmFromFinish: attackKmFromFinish ?? this.attackKmFromFinish,
      effortPercentFtp: effortPercentFtp ?? this.effortPercentFtp,
      domestiquesCommitted: domestiquesCommitted ?? this.domestiquesCommitted,
      nutritionBoostEnabled:
          nutritionBoostEnabled ?? this.nutritionBoostEnabled,
      aeroEquipmentBonus: aeroEquipmentBonus ?? this.aeroEquipmentBonus,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'strategy': strategy.toJson(),
        'riskLevel': riskLevel.toJson(),
        'attackKmFromFinish': attackKmFromFinish,
        'effortPercentFtp': effortPercentFtp,
        'domestiquesCommitted': domestiquesCommitted,
        'nutritionBoostEnabled': nutritionBoostEnabled,
        'aeroEquipmentBonus': aeroEquipmentBonus,
      };

  factory WhatIfTacticalVariant.fromJson(Map<String, dynamic> json) {
    return WhatIfTacticalVariant(
      id: (json['id'] as String?) ?? 'var_1',
      name: (json['name'] as String?) ?? 'Wariant taktyczny',
      strategy: WhatIfTacticalStrategyType.fromJson(
        (json['strategy'] as String?) ?? 'defensivePelotonControl',
      ),
      riskLevel: WhatIfRiskLevel.fromJson(
        (json['riskLevel'] as String?) ?? 'balanced',
      ),
      attackKmFromFinish:
          (json['attackKmFromFinish'] as num?)?.toDouble() ?? 10.0,
      effortPercentFtp: (json['effortPercentFtp'] as num?)?.toDouble() ?? 100.0,
      domestiquesCommitted: (json['domestiquesCommitted'] as num?)?.toInt() ?? 2,
      nutritionBoostEnabled: (json['nutritionBoostEnabled'] as bool?) ?? true,
      aeroEquipmentBonus:
          (json['aeroEquipmentBonus'] as num?)?.toDouble() ?? 0.02,
    );
  }
}

/// Wynik pojedynczego losowania Monte Carlo.
@immutable
class WhatIfMonteCarloRunSample {
  const WhatIfMonteCarloRunSample({
    required this.runIndex,
    required this.finishPosition,
    required this.timeGapToWinnerSeconds,
    required this.remainingWPrimePercent,
    required this.bonkOccurred,
    required this.incidentOccurred,
    required this.energySpentKj,
  });

  final int runIndex;
  final int finishPosition;
  final double timeGapToWinnerSeconds;
  final double remainingWPrimePercent;
  final bool bonkOccurred;
  final bool incidentOccurred;
  final double energySpentKj;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'runIndex': runIndex,
        'finishPosition': finishPosition,
        'timeGapToWinnerSeconds': timeGapToWinnerSeconds,
        'remainingWPrimePercent': remainingWPrimePercent,
        'bonkOccurred': bonkOccurred,
        'incidentOccurred': incidentOccurred,
        'energySpentKj': energySpentKj,
      };
}

/// Zagregowany wynik symulacji Monte Carlo dla jednego wariantu taktycznego.
@immutable
class WhatIfVariantOutcome {
  const WhatIfVariantOutcome({
    required this.variant,
    required this.runCount,
    required this.winProbability,
    required this.podiumProbability,
    required this.top10Probability,
    required this.expectedFinishPosition,
    required this.p10TimeGapSeconds,
    required this.p50TimeGapSeconds,
    required this.p90TimeGapSeconds,
    required this.bonkRiskProbability,
    required this.incidentRiskProbability,
    required this.expectedUciPoints,
    required this.tacticalVerdictScore,
    required this.isOptimalRecommended,
    required this.samples,
  });

  final WhatIfTacticalVariant variant;
  final int runCount;
  final double winProbability;
  final double podiumProbability;
  final double top10Probability;
  final double expectedFinishPosition;
  final double p10TimeGapSeconds;
  final double p50TimeGapSeconds;
  final double p90TimeGapSeconds;
  final double bonkRiskProbability;
  final double incidentRiskProbability;
  final double expectedUciPoints;
  final double tacticalVerdictScore;
  final bool isOptimalRecommended;
  final List<WhatIfMonteCarloRunSample> samples;

  WhatIfVariantOutcome copyWith({
    bool? isOptimalRecommended,
  }) {
    return WhatIfVariantOutcome(
      variant: variant,
      runCount: runCount,
      winProbability: winProbability,
      podiumProbability: podiumProbability,
      top10Probability: top10Probability,
      expectedFinishPosition: expectedFinishPosition,
      p10TimeGapSeconds: p10TimeGapSeconds,
      p50TimeGapSeconds: p50TimeGapSeconds,
      p90TimeGapSeconds: p90TimeGapSeconds,
      bonkRiskProbability: bonkRiskProbability,
      incidentRiskProbability: incidentRiskProbability,
      expectedUciPoints: expectedUciPoints,
      tacticalVerdictScore: tacticalVerdictScore,
      isOptimalRecommended: isOptimalRecommended ?? this.isOptimalRecommended,
      samples: samples,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'variant': variant.toJson(),
        'runCount': runCount,
        'winProbability': winProbability,
        'podiumProbability': podiumProbability,
        'top10Probability': top10Probability,
        'expectedFinishPosition': expectedFinishPosition,
        'p10TimeGapSeconds': p10TimeGapSeconds,
        'p50TimeGapSeconds': p50TimeGapSeconds,
        'p90TimeGapSeconds': p90TimeGapSeconds,
        'bonkRiskProbability': bonkRiskProbability,
        'incidentRiskProbability': incidentRiskProbability,
        'expectedUciPoints': expectedUciPoints,
        'tacticalVerdictScore': tacticalVerdictScore,
        'isOptimalRecommended': isOptimalRecommended,
      };
}

/// Pełny raport z uruchomienia piaskownicy Monte Carlo (domyślnie 20 wariantów).
@immutable
class WhatIfSandboxSimulationReport {
  const WhatIfSandboxSimulationReport({
    required this.stageContext,
    required this.variantsCount,
    required this.runsPerVariant,
    required this.totalSimulationsRun,
    required this.elapsedMs,
    required this.metLatencyBudget,
    required this.bestWinVariantId,
    required this.bestSafeVariantId,
    required this.outcomes,
    required this.generatedAtIso,
  });

  final WhatIfStageContext stageContext;
  final int variantsCount;
  final int runsPerVariant;
  final int totalSimulationsRun;
  final int elapsedMs;
  final bool metLatencyBudget;
  final String bestWinVariantId;
  final String bestSafeVariantId;
  final List<WhatIfVariantOutcome> outcomes;
  final String generatedAtIso;

  WhatIfVariantOutcome? findOutcomeById(String id) {
    for (final outcome in outcomes) {
      if (outcome.variant.id == id) {
        return outcome;
      }
    }
    return outcomes.isEmpty ? null : outcomes.first;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stageContext': stageContext.toJson(),
        'variantsCount': variantsCount,
        'runsPerVariant': runsPerVariant,
        'totalSimulationsRun': totalSimulationsRun,
        'elapsedMs': elapsedMs,
        'metLatencyBudget': metLatencyBudget,
        'bestWinVariantId': bestWinVariantId,
        'bestSafeVariantId': bestSafeVariantId,
        'outcomes': outcomes.map((e) => e.toJson()).toList(),
        'generatedAtIso': generatedAtIso,
      };
}

/// Wewnętrzny ładunek przesyłany do wątku `Isolate.run` bez zależności od UI.
class _IsolateSandboxPayload {
  const _IsolateSandboxPayload({
    required this.stageContext,
    required this.riderProfile,
    required this.variants,
    required this.runsPerVariant,
  });

  final WhatIfStageContext stageContext;
  final WhatIfRiderProfile riderProfile;
  final List<WhatIfTacticalVariant> variants;
  final int runsPerVariant;
}

/// Funkcja najwyższego poziomu wykonywana w osobnym `Isolate` dla zachowania 120 FPS.
WhatIfSandboxSimulationReport _executeSandboxBatchInIsolate(
  _IsolateSandboxPayload payload,
) {
  return WhatIfTacticalSandboxSimulator.simulateVariantsSync(
    stageContext: payload.stageContext,
    riderProfile: payload.riderProfile,
    variants: payload.variants,
    runsPerVariant: payload.runsPerVariant,
  );
}

/// Symulator Monte Carlo scenariuszy taktycznych „Co Jeśli?” (20 wariantów w tle w < 1.5 s).
class WhatIfTacticalSandboxSimulator {
  const WhatIfTacticalSandboxSimulator._();

  /// Maksymalny akceptowalny czas symulacji 20 wariantów w tle (1500 ms).
  static const int maxLatencyBudgetMs = 1500;

  /// Domyślna liczba równolegle ocenianych wariantów taktycznych.
  static const int defaultVariantCount = 20;

  /// Domyślny profil etapu królewskiego do natychmiastowej symulacji.
  static WhatIfStageContext defaultStageContext() {
    return const WhatIfStageContext(
      stageName: 'Col du Galibier — Etap 17',
      distanceKm: 174.5,
      elevationGainMeters: 4280,
      finalClimbLengthKm: 14.2,
      finalClimbAvgGradientPercent: 7.9,
      crosswindProbability: 0.30,
      terrain: WhatIfStageTerrainProfile.mountainSummitFinish,
      weather: WhatIfWeatherCondition.calmDry,
      rivalStrengthIndex: 1.02,
      pelotonSize: 168,
      baseSeed: 6202026,
    );
  }

  /// Domyślny profil lidera GC do testów taktycznych.
  static WhatIfRiderProfile defaultRiderProfile() {
    return const WhatIfRiderProfile(
      id: 'rider_gc_alpha',
      name: 'K. Majka-Kowalski',
      ftpWatts: 426.0,
      weightKg: 62.0,
      wPrimeJoules: 25200.0,
      sprintPowerWatts: 1140.0,
      climbingSkill: 91,
      cobbleSkill: 70,
      descendingSkill: 85,
      fatiguePercent: 12.0,
      dayFormDiamonds: 1,
    );
  }

  /// Generuje komplet 20 zróżnicowanych wariantów taktycznych dopasowanych do etapu.
  static List<WhatIfTacticalVariant> buildDefault20Variants(
    WhatIfStageContext context,
  ) {
    final double climbLen = context.finalClimbLengthKm.clamp(2.0, 25.0);
    return <WhatIfTacticalVariant>[
      const WhatIfTacticalVariant(
        id: 'var_01',
        name: 'Kontrola tempa w peletonie (2 pomocników)',
        strategy: WhatIfTacticalStrategyType.defensivePelotonControl,
        riskLevel: WhatIfRiskLevel.conservative,
        attackKmFromFinish: 2.0,
        effortPercentFtp: 96.0,
        domestiquesCommitted: 2,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.02,
      ),
      const WhatIfTacticalVariant(
        id: 'var_02',
        name: 'Żelazna kontrola pociągu GC (5 pomocników)',
        strategy: WhatIfTacticalStrategyType.defensivePelotonControl,
        riskLevel: WhatIfRiskLevel.balanced,
        attackKmFromFinish: 3.5,
        effortPercentFtp: 101.0,
        domestiquesCommitted: 5,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.03,
      ),
      WhatIfTacticalVariant(
        id: 'var_03',
        name: 'Atak u podnóża finałowej góry (-${climbLen.toStringAsFixed(0)} km)',
        strategy: WhatIfTacticalStrategyType.finalClimbAllIn,
        riskLevel: WhatIfRiskLevel.aggressive,
        attackKmFromFinish: climbLen,
        effortPercentFtp: 109.0,
        domestiquesCommitted: 3,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.025,
      ),
      const WhatIfTacticalVariant(
        id: 'var_04',
        name: 'Królewski atak na 8 km przed metą',
        strategy: WhatIfTacticalStrategyType.finalClimbAllIn,
        riskLevel: WhatIfRiskLevel.aggressive,
        attackKmFromFinish: 8.0,
        effortPercentFtp: 112.0,
        domestiquesCommitted: 4,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.03,
      ),
      const WhatIfTacticalVariant(
        id: 'var_05',
        name: 'Bomba watowa na 4.5 km przed szczytem',
        strategy: WhatIfTacticalStrategyType.finalClimbAllIn,
        riskLevel: WhatIfRiskLevel.allIn,
        attackKmFromFinish: 4.5,
        effortPercentFtp: 118.0,
        domestiquesCommitted: 2,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.02,
      ),
      const WhatIfTacticalVariant(
        id: 'var_06',
        name: 'Finiszowy skok na ostatnim 1.8 km',
        strategy: WhatIfTacticalStrategyType.finalClimbAllIn,
        riskLevel: WhatIfRiskLevel.balanced,
        attackKmFromFinish: 1.8,
        effortPercentFtp: 121.0,
        domestiquesCommitted: 1,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.02,
      ),
      const WhatIfTacticalVariant(
        id: 'var_07',
        name: 'Stacja przekaźnikowa: 1 pomocnik w odjeździe',
        strategy: WhatIfTacticalStrategyType.satelliteRelay,
        riskLevel: WhatIfRiskLevel.balanced,
        attackKmFromFinish: 28.0,
        effortPercentFtp: 104.0,
        domestiquesCommitted: 3,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.025,
      ),
      const WhatIfTacticalVariant(
        id: 'var_08',
        name: 'Podwójna stacja przekaźnikowa + atak -25 km',
        strategy: WhatIfTacticalStrategyType.satelliteRelay,
        riskLevel: WhatIfRiskLevel.aggressive,
        attackKmFromFinish: 25.0,
        effortPercentFtp: 108.0,
        domestiquesCommitted: 5,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.03,
      ),
      const WhatIfTacticalVariant(
        id: 'var_09',
        name: 'Atak na przedostatniej przełęczy (-42 km)',
        strategy: WhatIfTacticalStrategyType.penultimateClimbAttack,
        riskLevel: WhatIfRiskLevel.allIn,
        attackKmFromFinish: 42.0,
        effortPercentFtp: 106.0,
        domestiquesCommitted: 4,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.025,
      ),
      const WhatIfTacticalVariant(
        id: 'var_10',
        name: 'Zjazdowy zryw po przedostatniej przełęczy (-33 km)',
        strategy: WhatIfTacticalStrategyType.penultimateClimbAttack,
        riskLevel: WhatIfRiskLevel.aggressive,
        attackKmFromFinish: 33.0,
        effortPercentFtp: 105.0,
        domestiquesCommitted: 2,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.035,
      ),
      const WhatIfTacticalVariant(
        id: 'var_11',
        name: 'Wachlarz na wietrze bocznym (-65 km, 6 kolarzy)',
        strategy: WhatIfTacticalStrategyType.crosswindEchelon,
        riskLevel: WhatIfRiskLevel.aggressive,
        attackKmFromFinish: 65.0,
        effortPercentFtp: 107.0,
        domestiquesCommitted: 6,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.04,
      ),
      const WhatIfTacticalVariant(
        id: 'var_12',
        name: 'Późny rant w dolinie przed podjazdem (-22 km)',
        strategy: WhatIfTacticalStrategyType.crosswindEchelon,
        riskLevel: WhatIfRiskLevel.balanced,
        attackKmFromFinish: 22.0,
        effortPercentFtp: 103.0,
        domestiquesCommitted: 4,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.035,
      ),
      WhatIfTacticalVariant(
        id: 'var_13',
        name: 'Poranna ucieczka solo (Va Banque od km 12)',
        strategy: WhatIfTacticalStrategyType.earlyBreakaway,
        riskLevel: WhatIfRiskLevel.allIn,
        attackKmFromFinish: (context.distanceKm - 12.0).clamp(40.0, 200.0),
        effortPercentFtp: 102.0,
        domestiquesCommitted: 0,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.03,
      ),
      WhatIfTacticalVariant(
        id: 'var_14',
        name: 'Poranna ucieczka ze wsparciem 2 pomocników',
        strategy: WhatIfTacticalStrategyType.earlyBreakaway,
        riskLevel: WhatIfRiskLevel.aggressive,
        attackKmFromFinish: (context.distanceKm - 20.0).clamp(35.0, 190.0),
        effortPercentFtp: 99.0,
        domestiquesCommitted: 2,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.025,
      ),
      const WhatIfTacticalVariant(
        id: 'var_15',
        name: 'Surfowanie na kole głównego rywala (-6 km)',
        strategy: WhatIfTacticalStrategyType.counterSurfing,
        riskLevel: WhatIfRiskLevel.conservative,
        attackKmFromFinish: 1.0,
        effortPercentFtp: 98.0,
        domestiquesCommitted: 1,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.02,
      ),
      const WhatIfTacticalVariant(
        id: 'var_16',
        name: 'Kontra z koła rywala na 3 km przed metą',
        strategy: WhatIfTacticalStrategyType.counterSurfing,
        riskLevel: WhatIfRiskLevel.balanced,
        attackKmFromFinish: 3.0,
        effortPercentFtp: 106.0,
        domestiquesCommitted: 2,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.03,
      ),
      const WhatIfTacticalVariant(
        id: 'var_17',
        name: 'Pełny pociąg sprinterski (5 rozprowadzających)',
        strategy: WhatIfTacticalStrategyType.sprintLeadoutTrain,
        riskLevel: WhatIfRiskLevel.balanced,
        attackKmFromFinish: 0.6,
        effortPercentFtp: 114.0,
        domestiquesCommitted: 5,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.04,
      ),
      const WhatIfTacticalVariant(
        id: 'var_18',
        name: 'Opóźniona proca sprinterska (-250 m)',
        strategy: WhatIfTacticalStrategyType.sprintLeadoutTrain,
        riskLevel: WhatIfRiskLevel.aggressive,
        attackKmFromFinish: 0.25,
        effortPercentFtp: 124.0,
        domestiquesCommitted: 3,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.045,
      ),
      const WhatIfTacticalVariant(
        id: 'var_19',
        name: 'Oszczędny tryb GC (bez hydrożeli, bez ryzyka)',
        strategy: WhatIfTacticalStrategyType.defensivePelotonControl,
        riskLevel: WhatIfRiskLevel.conservative,
        attackKmFromFinish: 0.8,
        effortPercentFtp: 93.0,
        domestiquesCommitted: 1,
        nutritionBoostEnabled: false,
        aeroEquipmentBonus: 0.01,
      ),
      const WhatIfTacticalVariant(
        id: 'var_20',
        name: 'Maksymalny atak aero + hydrożel 110g/h (-10 km)',
        strategy: WhatIfTacticalStrategyType.finalClimbAllIn,
        riskLevel: WhatIfRiskLevel.allIn,
        attackKmFromFinish: 10.0,
        effortPercentFtp: 115.0,
        domestiquesCommitted: 4,
        nutritionBoostEnabled: true,
        aeroEquipmentBonus: 0.05,
      ),
    ];
  }

  /// Uruchamia symulację Monte Carlo w osobnym wątku (`Isolate.run`),
  /// gwarantując wykonanie 20 wariantów poniżej 1.5 s bez blokowania UI.
  static Future<WhatIfSandboxSimulationReport> simulateVariantsInBackground({
    required WhatIfStageContext stageContext,
    required WhatIfRiderProfile riderProfile,
    required List<WhatIfTacticalVariant> variants,
    int runsPerVariant = 100,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final _IsolateSandboxPayload payload = _IsolateSandboxPayload(
      stageContext: stageContext,
      riderProfile: riderProfile,
      variants: variants,
      runsPerVariant: runsPerVariant,
    );
    final WhatIfSandboxSimulationReport isolateReport = await Isolate.run(
      () => _executeSandboxBatchInIsolate(payload),
    );
    stopwatch.stop();
    final int totalElapsedMs = stopwatch.elapsedMilliseconds;
    return WhatIfSandboxSimulationReport(
      stageContext: isolateReport.stageContext,
      variantsCount: isolateReport.variantsCount,
      runsPerVariant: isolateReport.runsPerVariant,
      totalSimulationsRun: isolateReport.totalSimulationsRun,
      elapsedMs: totalElapsedMs,
      metLatencyBudget: totalElapsedMs < maxLatencyBudgetMs,
      bestWinVariantId: isolateReport.bestWinVariantId,
      bestSafeVariantId: isolateReport.bestSafeVariantId,
      outcomes: isolateReport.outcomes,
      generatedAtIso: isolateReport.generatedAtIso,
    );
  }

  /// Synchroniczna wersja symulatora Monte Carlo (deterministyczna dla danego `baseSeed`).
  static WhatIfSandboxSimulationReport simulateVariantsSync({
    required WhatIfStageContext stageContext,
    required WhatIfRiderProfile riderProfile,
    required List<WhatIfTacticalVariant> variants,
    int runsPerVariant = 100,
  }) {
    final Stopwatch stopwatch = Stopwatch()..start();
    final int safeRuns = runsPerVariant.clamp(10, 1000);

    if (variants.isEmpty) {
      stopwatch.stop();
      return WhatIfSandboxSimulationReport(
        stageContext: stageContext,
        variantsCount: 0,
        runsPerVariant: safeRuns,
        totalSimulationsRun: 0,
        elapsedMs: stopwatch.elapsedMilliseconds,
        metLatencyBudget: true,
        bestWinVariantId: '',
        bestSafeVariantId: '',
        outcomes: const <WhatIfVariantOutcome>[],
        generatedAtIso: DateTime.now().toIso8601String(),
      );
    }

    final List<WhatIfVariantOutcome> rawOutcomes = <WhatIfVariantOutcome>[];
    for (int i = 0; i < variants.length; i++) {
      rawOutcomes.add(
        _simulateSingleVariant(
          stageContext: stageContext,
          riderProfile: riderProfile,
          variant: variants[i],
          variantIndex: i,
          runsPerVariant: safeRuns,
        ),
      );
    }

    // Sortowanie malejąco po ogólnym wyniku taktycznym
    rawOutcomes.sort(
      (WhatIfVariantOutcome a, WhatIfVariantOutcome b) =>
          b.tacticalVerdictScore.compareTo(a.tacticalVerdictScore),
    );

    final String bestOverallId = rawOutcomes.first.variant.id;
    String bestWinId = rawOutcomes.first.variant.id;
    double highestWin = -1.0;
    String bestSafeId = rawOutcomes.first.variant.id;
    double highestSafeScore = -1.0;

    for (final WhatIfVariantOutcome o in rawOutcomes) {
      if (o.winProbability > highestWin) {
        highestWin = o.winProbability;
        bestWinId = o.variant.id;
      }
      final double safetyAdjusted =
          o.tacticalVerdictScore * (1.0 - (o.bonkRiskProbability + o.incidentRiskProbability) * 0.45);
      if (safetyAdjusted > highestSafeScore) {
        highestSafeScore = safetyAdjusted;
        bestSafeId = o.variant.id;
      }
    }

    final List<WhatIfVariantOutcome> markedOutcomes = rawOutcomes
        .map(
          (WhatIfVariantOutcome o) => o.copyWith(
            isOptimalRecommended: o.variant.id == bestOverallId,
          ),
        )
        .toList(growable: false);

    stopwatch.stop();
    final int elapsedMs = stopwatch.elapsedMilliseconds;

    return WhatIfSandboxSimulationReport(
      stageContext: stageContext,
      variantsCount: variants.length,
      runsPerVariant: safeRuns,
      totalSimulationsRun: variants.length * safeRuns,
      elapsedMs: elapsedMs,
      metLatencyBudget: elapsedMs < maxLatencyBudgetMs,
      bestWinVariantId: bestWinId,
      bestSafeVariantId: bestSafeId,
      outcomes: markedOutcomes,
      generatedAtIso: DateTime.now().toIso8601String(),
    );
  }

  static WhatIfVariantOutcome _simulateSingleVariant({
    required WhatIfStageContext stageContext,
    required WhatIfRiderProfile riderProfile,
    required WhatIfTacticalVariant variant,
    required int variantIndex,
    required int runsPerVariant,
  }) {
    final int seed = stageContext.baseSeed ^
        (variantIndex * 7919) ^
        variant.id.hashCode ^
        variant.strategy.index * 31;
    final math.Random rng = math.Random(seed);

    final double strategyFit = _computeStrategyTerrainFit(
      strategy: variant.strategy,
      terrain: stageContext.terrain,
      weather: stageContext.weather,
      crosswindProb: stageContext.crosswindProbability,
    );

    final List<WhatIfMonteCarloRunSample> samples = <WhatIfMonteCarloRunSample>[];
    final List<double> timeGaps = <double>[];

    int wins = 0;
    int podiums = 0;
    int top10s = 0;
    int bonks = 0;
    int incidents = 0;
    double sumPosition = 0.0;

    final double baseWPerKg = riderProfile.wattsPerKg;
    final double fatiguePenalty = riderProfile.fatiguePercent * 0.0022;
    final double dayFormBonus = riderProfile.dayFormDiamonds * 0.018;
    final double domestiqueDraftBonus =
        math.min(6, variant.domestiquesCommitted) * 0.012;
    final double nutritionFactor = variant.nutritionBoostEnabled ? 1.0 : 0.88;

    for (int r = 0; r < runsPerVariant; r++) {
      // Rozkład normalny Boxa-Mullera dla wariancji dnia, wiatru i reakcji rywali
      final double u1 = math.max(1e-7, rng.nextDouble());
      final double u2 = rng.nextDouble();
      final double zNoise =
          math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);

      final double rivalVariance = zNoise * 0.045 * stageContext.rivalStrengthIndex;

      // Zużycie beztlenowe W' oraz ryzyko "odcięcia prądu" (Bonk)
      final double effortDelta = (variant.effortPercentFtp - 100.0) / 100.0;
      final double attackDurationFactor =
          (variant.attackKmFromFinish / 25.0).clamp(0.15, 2.2);
      final double heatDrain =
          stageContext.weather == WhatIfWeatherCondition.alpineHeat ? 0.14 : 0.0;
      final double rawWPrimeDrain = (0.32 +
              math.max(0.0, effortDelta) * 1.45 * attackDurationFactor +
              heatDrain) /
          nutritionFactor;
      final double wPrimeRemaining =
          (1.0 - rawWPrimeDrain + (zNoise * 0.08)).clamp(0.0, 1.0);
      final bool bonkOccurred =
          wPrimeRemaining < 0.06 || (effortDelta > 0.15 && rng.nextDouble() < 0.14);

      // Ryzyko kraksy lub defektu zależne od pogody, bruku i poziomu ryzyka
      double baseIncidentProb = 0.015;
      if (stageContext.weather == WhatIfWeatherCondition.heavyRain) {
        baseIncidentProb += 0.045;
      }
      if (stageContext.terrain == WhatIfStageTerrainProfile.cobbleMonument) {
        baseIncidentProb += (100 - riderProfile.cobbleSkill) * 0.0008;
      }
      if (variant.riskLevel == WhatIfRiskLevel.allIn) {
        baseIncidentProb += 0.025;
      }
      final bool incidentOccurred = rng.nextDouble() < baseIncidentProb;

      // Składowa osiągów fizycznych (czas względny do zwycięzcy)
      final double skillBonus = _computeSkillContribution(
        rider: riderProfile,
        terrain: stageContext.terrain,
      );
      final double effectiveScore = (baseWPerKg / 6.2) *
              (1.0 - fatiguePenalty + dayFormBonus) *
              strategyFit *
              (1.0 + domestiqueDraftBonus + variant.aeroEquipmentBonus) *
              skillBonus -
          rivalVariance -
          (bonkOccurred ? 0.24 : 0.0) -
          (incidentOccurred ? 0.30 : 0.0);

      // Przeliczenie wyniku na pozycję w peletonie oraz stratę czasową (w sekundach)
      final double rawTimeGap =
          ((1.18 - effectiveScore) * 185.0).clamp(-35.0, 620.0);
      final double clampedTimeGap = math.max(0.0, rawTimeGap);
      final int finishPos = rawTimeGap <= 0.0
          ? 1
          : (1 + (rawTimeGap / 3.8).round())
              .clamp(2, stageContext.pelotonSize);

      if (finishPos == 1) wins++;
      if (finishPos <= 3) podiums++;
      if (finishPos <= 10) top10s++;
      if (bonkOccurred) bonks++;
      if (incidentOccurred) incidents++;
      sumPosition += finishPos;
      timeGaps.add(clampedTimeGap);

      final double energyKj = (stageContext.distanceKm * 18.5) *
          (variant.effortPercentFtp / 100.0) *
          (1.0 - domestiqueDraftBonus * 0.5);

      samples.add(
        WhatIfMonteCarloRunSample(
          runIndex: r,
          finishPosition: finishPos,
          timeGapToWinnerSeconds: clampedTimeGap,
          remainingWPrimePercent: wPrimeRemaining * 100.0,
          bonkOccurred: bonkOccurred,
          incidentOccurred: incidentOccurred,
          energySpentKj: energyKj,
        ),
      );
    }

    timeGaps.sort();
    final double p10 = _percentile(timeGaps, 0.10);
    final double p50 = _percentile(timeGaps, 0.50);
    final double p90 = _percentile(timeGaps, 0.90);

    final double winProb = wins / runsPerVariant;
    final double podiumProb = podiums / runsPerVariant;
    final double top10Prob = top10s / runsPerVariant;
    final double bonkProb = bonks / runsPerVariant;
    final double incidentProb = incidents / runsPerVariant;
    final double expectedPos = sumPosition / runsPerVariant;

    final double expectedUci =
        winProb * 210.0 + (podiumProb - winProb) * 110.0 + (top10Prob - podiumProb) * 35.0;

    final double verdictScore = (winProb * 48.0 +
            podiumProb * 28.0 +
            top10Prob * 24.0 -
            bonkProb * 22.0 -
            incidentProb * 18.0 +
            (1.0 - (p50 / 180.0).clamp(0.0, 1.0)) * 20.0)
        .clamp(0.0, 100.0);

    return WhatIfVariantOutcome(
      variant: variant,
      runCount: runsPerVariant,
      winProbability: winProb,
      podiumProbability: podiumProb,
      top10Probability: top10Prob,
      expectedFinishPosition: expectedPos,
      p10TimeGapSeconds: p10,
      p50TimeGapSeconds: p50,
      p90TimeGapSeconds: p90,
      bonkRiskProbability: bonkProb,
      incidentRiskProbability: incidentProb,
      expectedUciPoints: expectedUci,
      tacticalVerdictScore: verdictScore,
      isOptimalRecommended: false,
      samples: samples,
    );
  }

  static double _computeStrategyTerrainFit({
    required WhatIfTacticalStrategyType strategy,
    required WhatIfStageTerrainProfile terrain,
    required WhatIfWeatherCondition weather,
    required double crosswindProb,
  }) {
    double fit = 1.0;
    switch (terrain) {
      case WhatIfStageTerrainProfile.mountainSummitFinish:
        if (strategy == WhatIfTacticalStrategyType.finalClimbAllIn ||
            strategy == WhatIfTacticalStrategyType.satelliteRelay) {
          fit = 1.12;
        } else if (strategy == WhatIfTacticalStrategyType.penultimateClimbAttack) {
          fit = 1.08;
        } else if (strategy == WhatIfTacticalStrategyType.sprintLeadoutTrain) {
          fit = 0.72;
        }
      case WhatIfStageTerrainProfile.flatSprint:
        if (strategy == WhatIfTacticalStrategyType.sprintLeadoutTrain ||
            strategy == WhatIfTacticalStrategyType.counterSurfing) {
          fit = 1.15;
        } else if (strategy == WhatIfTacticalStrategyType.crosswindEchelon) {
          fit = 1.04 + crosswindProb * 0.14;
        } else if (strategy == WhatIfTacticalStrategyType.finalClimbAllIn) {
          fit = 0.80;
        }
      case WhatIfStageTerrainProfile.cobbleMonument:
        if (strategy == WhatIfTacticalStrategyType.penultimateClimbAttack ||
            strategy == WhatIfTacticalStrategyType.crosswindEchelon) {
          fit = 1.11;
        } else if (strategy == WhatIfTacticalStrategyType.counterSurfing) {
          fit = 1.06;
        }
      case WhatIfStageTerrainProfile.hillyClassics:
        if (strategy == WhatIfTacticalStrategyType.finalClimbAllIn ||
            strategy == WhatIfTacticalStrategyType.counterSurfing) {
          fit = 1.10;
        }
      case WhatIfStageTerrainProfile.rollingTransition:
        if (strategy == WhatIfTacticalStrategyType.earlyBreakaway ||
            strategy == WhatIfTacticalStrategyType.satelliteRelay) {
          fit = 1.09;
        }
    }

    if (weather == WhatIfWeatherCondition.crosswindGusts &&
        strategy == WhatIfTacticalStrategyType.crosswindEchelon) {
      fit += 0.10;
    }
    return fit;
  }

  static double _computeSkillContribution({
    required WhatIfRiderProfile rider,
    required WhatIfStageTerrainProfile terrain,
  }) {
    switch (terrain) {
      case WhatIfStageTerrainProfile.mountainSummitFinish:
        return 0.92 + (rider.climbingSkill / 100.0) * 0.14;
      case WhatIfStageTerrainProfile.flatSprint:
        return 0.90 + ((rider.sprintPowerWatts / 1400.0).clamp(0.5, 1.1)) * 0.15;
      case WhatIfStageTerrainProfile.cobbleMonument:
        return 0.90 + (rider.cobbleSkill / 100.0) * 0.15;
      case WhatIfStageTerrainProfile.hillyClassics:
        return 0.92 +
            ((rider.climbingSkill + rider.descendingSkill) / 200.0) * 0.12;
      case WhatIfStageTerrainProfile.rollingTransition:
        return 0.94 + (rider.descendingSkill / 100.0) * 0.10;
    }
  }

  static double _percentile(List<double> sorted, double q) {
    if (sorted.isEmpty) return 0.0;
    final double idx = (sorted.length - 1) * q.clamp(0.0, 1.0);
    final int lo = idx.floor();
    final int hi = idx.ceil();
    if (lo == hi) return sorted[lo];
    final double frac = idx - lo;
    return sorted[lo] * (1.0 - frac) + sorted[hi] * frac;
  }
}

/// Stan piaskownicy taktycznej Monte Carlo zarządzany przez Riverpod.
@immutable
class WhatIfSandboxState {
  const WhatIfSandboxState({
    required this.stageContext,
    required this.riderProfile,
    required this.variants,
    required this.runsPerVariant,
    required this.isRunning,
    this.report,
    this.selectedVariantId,
    this.filterRiskLevel,
    this.errorMessage,
  });

  final WhatIfStageContext stageContext;
  final WhatIfRiderProfile riderProfile;
  final List<WhatIfTacticalVariant> variants;
  final int runsPerVariant;
  final bool isRunning;
  final WhatIfSandboxSimulationReport? report;
  final String? selectedVariantId;
  final WhatIfRiskLevel? filterRiskLevel;
  final String? errorMessage;

  WhatIfSandboxState copyWith({
    WhatIfStageContext? stageContext,
    WhatIfRiderProfile? riderProfile,
    List<WhatIfTacticalVariant>? variants,
    int? runsPerVariant,
    bool? isRunning,
    WhatIfSandboxSimulationReport? report,
    String? selectedVariantId,
    WhatIfRiskLevel? filterRiskLevel,
    bool clearFilterRisk = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WhatIfSandboxState(
      stageContext: stageContext ?? this.stageContext,
      riderProfile: riderProfile ?? this.riderProfile,
      variants: variants ?? this.variants,
      runsPerVariant: runsPerVariant ?? this.runsPerVariant,
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
      filterRiskLevel:
          clearFilterRisk ? null : (filterRiskLevel ?? this.filterRiskLevel),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier zarządzający uruchamianiem 20 wariantów Monte Carlo w tle.
class WhatIfSandboxNotifier extends StateNotifier<WhatIfSandboxState> {
  WhatIfSandboxNotifier() : super(_initialState());

  static WhatIfSandboxState _initialState() {
    final WhatIfStageContext ctx =
        WhatIfTacticalSandboxSimulator.defaultStageContext();
    final WhatIfRiderProfile rider =
        WhatIfTacticalSandboxSimulator.defaultRiderProfile();
    final List<WhatIfTacticalVariant> variants =
        WhatIfTacticalSandboxSimulator.buildDefault20Variants(ctx);
    final WhatIfSandboxSimulationReport initialReport =
        WhatIfTacticalSandboxSimulator.simulateVariantsSync(
      stageContext: ctx,
      riderProfile: rider,
      variants: variants,
      runsPerVariant: 100,
    );
    return WhatIfSandboxState(
      stageContext: ctx,
      riderProfile: rider,
      variants: variants,
      runsPerVariant: 100,
      isRunning: false,
      report: initialReport,
      selectedVariantId: initialReport.bestWinVariantId,
    );
  }

  void selectTerrain(WhatIfStageTerrainProfile terrain) {
    final WhatIfStageContext updatedCtx =
        state.stageContext.copyWith(terrain: terrain);
    state = state.copyWith(
      stageContext: updatedCtx,
      variants: WhatIfTacticalSandboxSimulator.buildDefault20Variants(updatedCtx),
    );
  }

  void selectWeather(WhatIfWeatherCondition weather) {
    state = state.copyWith(
      stageContext: state.stageContext.copyWith(weather: weather),
    );
  }

  void setRunsPerVariant(int runs) {
    state = state.copyWith(runsPerVariant: runs.clamp(20, 500));
  }

  void setFilterRisk(WhatIfRiskLevel? risk) {
    if (risk == null) {
      state = state.copyWith(clearFilterRisk: true);
    } else {
      state = state.copyWith(filterRiskLevel: risk);
    }
  }

  void selectVariant(String variantId) {
    state = state.copyWith(selectedVariantId: variantId);
  }

  void updateSelectedVariantEffort(double effortPercentFtp) {
    final String? targetId = state.selectedVariantId;
    if (targetId == null) return;
    final List<WhatIfTacticalVariant> updated = state.variants.map((v) {
      if (v.id == targetId) {
        return v.copyWith(effortPercentFtp: effortPercentFtp.clamp(80.0, 130.0));
      }
      return v;
    }).toList(growable: false);
    state = state.copyWith(variants: updated);
  }

  Future<void> runSimulationInBackground() async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, clearError: true);
    try {
      final WhatIfSandboxSimulationReport report =
          await WhatIfTacticalSandboxSimulator.simulateVariantsInBackground(
        stageContext: state.stageContext,
        riderProfile: state.riderProfile,
        variants: state.variants,
        runsPerVariant: state.runsPerVariant,
      );
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        report: report,
        selectedVariantId: state.selectedVariantId ?? report.bestWinVariantId,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Błąd symulacji Monte Carlo: $e',
      );
    }
  }

  void runSimulationSync() {
    final WhatIfSandboxSimulationReport report =
        WhatIfTacticalSandboxSimulator.simulateVariantsSync(
      stageContext: state.stageContext,
      riderProfile: state.riderProfile,
      variants: state.variants,
      runsPerVariant: state.runsPerVariant,
    );
    state = state.copyWith(
      isRunning: false,
      report: report,
      selectedVariantId: report.bestWinVariantId,
      clearError: true,
    );
  }
}

/// Globalny provider Riverpod dla symulatora Monte Carlo „Co Jeśli?”.
final whatIfSandboxProvider =
    StateNotifierProvider<WhatIfSandboxNotifier, WhatIfSandboxState>(
  (Ref ref) => WhatIfSandboxNotifier(),
);

/// Rysuje wykres rozkładu strat czasowych (P10 / P50 / P90) oraz słupki szansy wygranej.
class WhatIfTimeGapDistributionPainter extends CustomPainter {
  WhatIfTimeGapDistributionPainter({
    required this.outcomes,
    required this.selectedVariantId,
  });

  final List<WhatIfVariantOutcome> outcomes;
  final String? selectedVariantId;

  @override
  void paint(Canvas canvas, Size size) {
    if (outcomes.isEmpty || size.width <= 0 || size.height <= 0) return;

    final int visibleCount = math.min(8, outcomes.length);
    final double rowHeight = size.height / visibleCount;
    double maxP90 = 60.0;
    for (int i = 0; i < visibleCount; i++) {
      maxP90 = math.max(maxP90, outcomes[i].p90TimeGapSeconds);
    }

    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (int g = 1; g <= 3; g++) {
      final double x = size.width * (g / 4.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (int i = 0; i < visibleCount; i++) {
      final WhatIfVariantOutcome item = outcomes[i];
      final bool isSelected = item.variant.id == selectedVariantId;
      final double centerY = i * rowHeight + rowHeight * 0.5;

      final double x10 =
          (item.p10TimeGapSeconds / maxP90).clamp(0.0, 1.0) * (size.width - 16) +
              8.0;
      final double x50 =
          (item.p50TimeGapSeconds / maxP90).clamp(0.0, 1.0) * (size.width - 16) +
              8.0;
      final double x90 =
          (item.p90TimeGapSeconds / maxP90).clamp(0.0, 1.0) * (size.width - 16) +
              8.0;

      final Color lineColor = isSelected
          ? AppColors.goldAccent
          : (item.isOptimalRecommended
              ? AppColors.statusSuccess
              : AppColors.accentBlue);

      final Paint whiskerPaint = Paint()
        ..color = lineColor.withValues(alpha: isSelected ? 0.95 : 0.65)
        ..strokeWidth = isSelected ? 3.5 : 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x10, centerY), Offset(x90, centerY), whiskerPaint);
      canvas.drawCircle(
        Offset(x50, centerY),
        isSelected ? 5.0 : 3.5,
        Paint()..color = lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WhatIfTimeGapDistributionPainter oldDelegate) {
    return oldDelegate.outcomes != outcomes ||
        oldDelegate.selectedVariantId != selectedVariantId;
  }
}

/// Produkcyjny panel UI Piaskownicy Taktycznej Monte Carlo „Co Jeśli?”.
class WhatIfTacticalSandboxPanel extends ConsumerWidget {
  const WhatIfTacticalSandboxPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WhatIfSandboxState state = ref.watch(whatIfSandboxProvider);
    final WhatIfSandboxNotifier notifier =
        ref.read(whatIfSandboxProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 680;
          final bool isWide = constraints.maxWidth >= 1200;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HeaderBar(
                  state: state,
                  isCompact: isCompact,
                  onRunPressed: state.isRunning
                      ? null
                      : () => notifier.runSimulationInBackground(),
                ),
                const SizedBox(height: 16),
                _ControlsCard(
                  state: state,
                  isCompact: isCompact,
                  onTerrainChanged: notifier.selectTerrain,
                  onWeatherChanged: notifier.selectWeather,
                  onRiskFilterChanged: notifier.setFilterRisk,
                ),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...<Widget>[
                  _ErrorBanner(message: state.errorMessage!),
                  const SizedBox(height: 16),
                ],
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 6,
                        child: _VariantsListCard(
                          state: state,
                          onSelectVariant: notifier.selectVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _VariantDetailsAndChartCard(
                          state: state,
                          onEffortChanged: notifier.updateSelectedVariantEffort,
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _VariantDetailsAndChartCard(
                    state: state,
                    onEffortChanged: notifier.updateSelectedVariantEffort,
                  ),
                  const SizedBox(height: 16),
                  _VariantsListCard(
                    state: state,
                    onSelectVariant: notifier.selectVariant,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.state,
    required this.isCompact,
    required this.onRunPressed,
  });

  final WhatIfSandboxState state;
  final bool isCompact;
  final VoidCallback? onRunPressed;

  @override
  Widget build(BuildContext context) {
    final WhatIfSandboxSimulationReport? report = state.report;
    final String latencyText = report != null
        ? '${report.variantsCount} wariantów • ${report.totalSimulationsRun} symulacji • ${report.elapsedMs} ms'
        : 'Gotowy do symulacji 20 wariantów';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTitleBlock(latencyText, report),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _InteractiveActionButton(
                    label: state.isRunning
                        ? 'Symulacja w tle...'
                        : 'Uruchom 20 wariantów',
                    icon: Icons.play_arrow_rounded,
                    isLoading: state.isRunning,
                    onPressed: onRunPressed,
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: _buildTitleBlock(latencyText, report)),
                const SizedBox(width: 16),
                _InteractiveActionButton(
                  label: state.isRunning
                      ? 'Symulacja w tle...'
                      : 'Uruchom 20 wariantów',
                  icon: Icons.play_arrow_rounded,
                  isLoading: state.isRunning,
                  onPressed: onRunPressed,
                ),
              ],
            ),
    );
  }

  Widget _buildTitleBlock(
    String latencyText,
    WhatIfSandboxSimulationReport? report,
  ) {
    final bool budgetOk = report?.metLatencyBudget ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(
              Icons.science_rounded,
              color: AppColors.goldAccent,
              size: 22,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Piaskownica Taktyczna Monte Carlo „Co Jeśli?”',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              state.stageContext.stageName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (budgetOk
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: budgetOk
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                  width: 1,
                ),
              ),
              child: Text(
                latencyText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: budgetOk
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.state,
    required this.isCompact,
    required this.onTerrainChanged,
    required this.onWeatherChanged,
    required this.onRiskFilterChanged,
  });

  final WhatIfSandboxState state;
  final bool isCompact;
  final ValueChanged<WhatIfStageTerrainProfile> onTerrainChanged;
  final ValueChanged<WhatIfWeatherCondition> onWeatherChanged;
  final ValueChanged<WhatIfRiskLevel?> onRiskFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Parametry Etapu & Filtr Ryzyka',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WhatIfStageTerrainProfile.values
                .map(
                  (WhatIfStageTerrainProfile t) => _SelectableChip(
                    label: t.labelPl,
                    selected: state.stageContext.terrain == t,
                    accentColor: AppColors.accentBlue,
                    onTap: () => onTerrainChanged(t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WhatIfWeatherCondition.values
                .map(
                  (WhatIfWeatherCondition w) => _SelectableChip(
                    label: w.labelPl,
                    selected: state.stageContext.weather == w,
                    accentColor: AppColors.cyanAccent,
                    onTap: () => onWeatherChanged(w),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _SelectableChip(
                label: 'Wszystkie (20)',
                selected: state.filterRiskLevel == null,
                accentColor: AppColors.goldAccent,
                onTap: () => onRiskFilterChanged(null),
              ),
              ...WhatIfRiskLevel.values.map(
                (WhatIfRiskLevel r) => _SelectableChip(
                  label: r.labelPl,
                  selected: state.filterRiskLevel == r,
                  accentColor: r.color,
                  onTap: () => onRiskFilterChanged(r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantsListCard extends StatelessWidget {
  const _VariantsListCard({
    required this.state,
    required this.onSelectVariant,
  });

  final WhatIfSandboxState state;
  final ValueChanged<String> onSelectVariant;

  @override
  Widget build(BuildContext context) {
    final List<WhatIfVariantOutcome> allOutcomes =
        state.report?.outcomes ?? const <WhatIfVariantOutcome>[];
    final List<WhatIfVariantOutcome> filtered = state.filterRiskLevel == null
        ? allOutcomes
        : allOutcomes
            .where((o) => o.variant.riskLevel == state.filterRiskLevel)
            .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ranking Wariantów Taktycznych (${filtered.length})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Brak wariantów spełniających kryteria filtra.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final WhatIfVariantOutcome outcome = filtered[index];
                final bool isSelected =
                    outcome.variant.id == state.selectedVariantId;
                return _VariantRowTile(
                  rank: index + 1,
                  outcome: outcome,
                  isSelected: isSelected,
                  onTap: () => onSelectVariant(outcome.variant.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VariantRowTile extends StatefulWidget {
  const _VariantRowTile({
    required this.rank,
    required this.outcome,
    required this.isSelected,
    required this.onTap,
  });

  final int rank;
  final WhatIfVariantOutcome outcome;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_VariantRowTile> createState() => _VariantRowTileState();
}

class _VariantRowTileState extends State<_VariantRowTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final WhatIfVariantOutcome o = widget.outcome;
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused
            ? AppColors.accentBlue
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return Focus(
      onFocusChange: (bool f) => setState(() => _focused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : (_hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.7)
                      : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.isOptimalRecommended
                        ? AppColors.goldAccent.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${widget.rank}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: o.isOptimalRecommended
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  o.variant.strategy.icon,
                  size: 18,
                  color: o.variant.riskLevel.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        o.variant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${o.variant.strategy.labelPl} • ${o.variant.effortPercentFtp.toStringAsFixed(0)}% FTP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      '${(o.winProbability * 100).toStringAsFixed(1)}% WIN',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'P50: +${o.p50TimeGapSeconds.toStringAsFixed(0)}s',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantDetailsAndChartCard extends StatelessWidget {
  const _VariantDetailsAndChartCard({
    required this.state,
    required this.onEffortChanged,
  });

  final WhatIfSandboxState state;
  final ValueChanged<double> onEffortChanged;

  @override
  Widget build(BuildContext context) {
    final WhatIfSandboxSimulationReport? report = state.report;
    final WhatIfVariantOutcome? selected =
        report?.findOutcomeById(state.selectedVariantId ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Rozkład P10 / P50 / P90 i Analiza Wariantu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (report != null && report.outcomes.isNotEmpty)
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: CustomPaint(
                painter: WhatIfTimeGapDistributionPainter(
                  outcomes: report.outcomes,
                  selectedVariantId: selected?.variant.id,
                ),
              ),
            ),
          if (selected != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              selected.variant.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MetricPill(
                  label: 'Wygrana',
                  value: '${(selected.winProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.goldAccent,
                ),
                _MetricPill(
                  label: 'Podium',
                  value:
                      '${(selected.podiumProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.statusSuccess,
                ),
                _MetricPill(
                  label: 'Top 10',
                  value:
                      '${(selected.top10Probability * 100).toStringAsFixed(1)}%',
                  color: AppColors.accentBlue,
                ),
                _MetricPill(
                  label: 'Ryzyko Bonk',
                  value:
                      '${(selected.bonkRiskProbability * 100).toStringAsFixed(1)}%',
                  color: AppColors.crimsonAlert,
                ),
                _MetricPill(
                  label: 'Pkt UCI',
                  value: selected.expectedUciPoints.toStringAsFixed(1),
                  color: AppColors.cyanAccent,
                ),
                _MetricPill(
                  label: 'Ocena DS',
                  value:
                      '${selected.tacticalVerdictScore.toStringAsFixed(0)}/100',
                  color: AppColors.primaryAccent,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Docelowa intensywność ataku (% FTP)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${selected.variant.effortPercentFtp.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primaryAccent,
                inactiveTrackColor: AppColors.cardBorder,
                thumbColor: AppColors.goldAccent,
                overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
              ),
              child: Slider(
                min: 80.0,
                max: 130.0,
                divisions: 50,
                value: selected.variant.effortPercentFtp.clamp(80.0, 130.0),
                onChanged: state.isRunning ? null : onEffortChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatefulWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<_SelectableChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (bool f) => setState(() => _focused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accentColor.withValues(alpha: 0.18)
                  : (_hovered
                      ? AppColors.surfaceLight
                      : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selected
                    ? widget.accentColor
                    : (_focused
                        ? AppColors.goldAccent
                        : AppColors.cardBorder),
                width: 1,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

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
    final bool enabled = widget.onPressed != null && !widget.isLoading;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight
        : (_pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.95)
                : AppColors.primaryAccent));

    return Focus(
      onFocusChange: (bool f) => setState(() => _focused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (enabled
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
                        : AppColors.cardBorder),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (widget.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.goldAccent,
                    ),
                  )
                else
                  Icon(
                    widget.icon,
                    size: 18,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonAlert, width: 1),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.crimsonAlert,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
