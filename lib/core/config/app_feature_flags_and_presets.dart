import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';

/// Identyfikator presetu realizmu rozgrywki w centralnym rejestrze.
enum GameplayRealismPresetId {
  arcade(
    id: 'arcade',
    displayName: 'Arcade / Swobodny',
    shortLabel: 'Arcade',
    badgeColor: AppColors.accentBlue,
    icon: Icons.bolt_rounded,
  ),
  balancedWorldTour(
    id: 'balanced_world_tour',
    displayName: 'WorldTour Standard',
    shortLabel: 'WorldTour',
    badgeColor: AppColors.statusSuccess,
    icon: Icons.directions_bike_rounded,
  ),
  proSimulation(
    id: 'pro_simulation',
    displayName: 'Pro Simulation',
    shortLabel: 'Pro Sim',
    badgeColor: AppColors.goldAccent,
    icon: Icons.analytics_rounded,
  ),
  ironmanHardcore(
    id: 'ironman_hardcore',
    displayName: 'Ironman Hardcore',
    shortLabel: 'Ironman',
    badgeColor: AppColors.crimsonAlert,
    icon: Icons.shield_rounded,
  ),
  goldenEraRetro(
    id: 'golden_era_retro',
    displayName: 'Złota Era Retro',
    shortLabel: 'Retro',
    badgeColor: AppColors.amberWarning,
    icon: Icons.history_edu_rounded,
  ),
  custom(
    id: 'custom',
    displayName: 'Własna Konfiguracja',
    shortLabel: 'Custom',
    badgeColor: AppColors.primaryAccent,
    icon: Icons.tune_rounded,
  );

  final String id;
  final String displayName;
  final String shortLabel;
  final Color badgeColor;
  final IconData icon;

  const GameplayRealismPresetId({
    required this.id,
    required this.displayName,
    required this.shortLabel,
    required this.badgeColor,
    required this.icon,
  });

  static GameplayRealismPresetId fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return GameplayRealismPresetId.balancedWorldTour;
    }
    final normalized = value.trim().toLowerCase();
    return GameplayRealismPresetId.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == normalized ||
          e.id.toLowerCase() == normalized,
      orElse: () => GameplayRealismPresetId.balancedWorldTour,
    );
  }
}

/// Tryb widoczności telemetrii mocy i parametrów fizjologicznych podczas etapu.
enum TelemetryVisibilityMode {
  fullLive(
    displayName: 'Pełna Telemetria Live',
    description: 'Widoczne waty, W\', LT1/LT2, tętno oraz wskaźnik CdA na żywo.',
    realismPoints: 0,
  ),
  delayedRadio(
    displayName: 'Opóźniona przez Radio',
    description: 'Dane własne z lekkim opóźnieniem; brak dokładnego W\' rywali.',
    realismPoints: 4,
  ),
  rpeAndHeartRateOnly(
    displayName: 'Tętno i Skala RPE',
    description: 'Brak miernika mocy; decyzje na podstawie tętna i odczucia wysiłku.',
    realismPoints: 8,
  ),
  blindClassic(
    displayName: 'Klasyczna (Bez Elektroniki)',
    description: 'Zero czujników i radia wyścigowego — czysta obserwacja peletonu.',
    realismPoints: 12,
  );

  final String displayName;
  final String description;
  final int realismPoints;

  const TelemetryVisibilityMode({
    required this.displayName,
    required this.description,
    required this.realismPoints,
  });

  static TelemetryVisibilityMode fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return TelemetryVisibilityMode.fullLive;
    }
    final normalized = value.trim().toLowerCase();
    return TelemetryVisibilityMode.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => TelemetryVisibilityMode.fullLive,
    );
  }
}

/// Poziom mgły wojny skautingu kolarzy rywali i talentów U23.
enum ScoutingFogOfWarMode {
  transparent(
    displayName: 'Pełna Jawność',
    description: 'Wszystkie atrybuty i profile VO2max/VLaMax widoczne od razu.',
    realismPoints: 0,
  ),
  partialEstimate(
    displayName: 'Szacunki Skautów',
    description: 'Atrybuty rywali podawane jako przedziały do czasu obserwacji.',
    realismPoints: 5,
  ),
  strictFogOfWar(
    displayName: 'Ścisła Mgła Wojny',
    description: 'Wymagane raporty skautów i testy laboratoryjne do odkrycia ocen.',
    realismPoints: 10,
  );

  final String displayName;
  final String description;
  final int realismPoints;

  const ScoutingFogOfWarMode({
    required this.displayName,
    required this.description,
    required this.realismPoints,
  });

  static ScoutingFogOfWarMode fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return ScoutingFogOfWarMode.partialEstimate;
    }
    final normalized = value.trim().toLowerCase();
    return ScoutingFogOfWarMode.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => ScoutingFogOfWarMode.partialEstimate,
    );
  }
}

/// Surowość sędziów UCI i analizy VAR podczas sprintów i pościgów.
enum UciCommissaireStrictness {
  lenient(
    displayName: 'Pobłażliwi Sędziowie',
    description: 'Tolerancja dla Sticky Bottle i drobnych zjazdów ze sprintu.',
    realismPoints: 0,
  ),
  standard(
    displayName: 'Standard UCI',
    description: 'Klasyczne kary czasowe, relegacje i grzywny w CHF.',
    realismPoints: 4,
  ),
  strictVar(
    displayName: 'Rygorystyczni + Sprint VAR',
    description: 'Pełna analiza wideo odchyleń toru jazdy i żółte kartki UCI.',
    realismPoints: 8,
  );

  final String displayName;
  final String description;
  final int realismPoints;

  const UciCommissaireStrictness({
    required this.displayName,
    required this.description,
    required this.realismPoints,
  });

  static UciCommissaireStrictness fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return UciCommissaireStrictness.standard;
    }
    final normalized = value.trim().toLowerCase();
    return UciCommissaireStrictness.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => UciCommissaireStrictness.standard,
    );
  }
}

/// Tryb integralności zapisu gry.
enum SaveIntegrityMode {
  standardMultiSlot(
    displayName: 'Standard (Wiele Slotów)',
    description: 'Swobodny zapis i wczytywanie na wielu slotach kariery.',
    realismPoints: 0,
  ),
  ironmanSingleSlot(
    displayName: 'Ironman (Auto-Zapis)',
    description: 'Jeden slot z ciągłym auto-zapisem po każdym etapie i decyzji.',
    realismPoints: 10,
  );

  final String displayName;
  final String description;
  final int realismPoints;

  const SaveIntegrityMode({
    required this.displayName,
    required this.description,
    required this.realismPoints,
  });

  static SaveIntegrityMode fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return SaveIntegrityMode.standardMultiSlot;
    }
    final normalized = value.trim().toLowerCase();
    return SaveIntegrityMode.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => SaveIntegrityMode.standardMultiSlot,
    );
  }
}

/// Kategoria flag realizmu w rejestrze i interfejsie użytkownika.
enum FeatureFlagCategory {
  physicsAndEnvironment(
    displayName: 'Fizyka i Środowisko',
    icon: Icons.air_rounded,
    accentColor: AppColors.accentBlue,
  ),
  physiologyAndTelemetry(
    displayName: 'Fizjologia i Telemetria',
    icon: Icons.monitor_heart_rounded,
    accentColor: AppColors.statusSuccess,
  ),
  tacticsAndAi(
    displayName: 'Taktyka i AI Peletonu',
    icon: Icons.groups_rounded,
    accentColor: AppColors.goldAccent,
  ),
  rulesAndLogistics(
    displayName: 'Przepisy UCI i Logistyka',
    icon: Icons.gavel_rounded,
    accentColor: AppColors.amberWarning,
  ),
  careerAndEconomy(
    displayName: 'Kariera, Finanse i Zapis',
    icon: Icons.account_balance_rounded,
    accentColor: AppColors.primaryAccent,
  );

  final String displayName;
  final IconData icon;
  final Color accentColor;

  const FeatureFlagCategory({
    required this.displayName,
    required this.icon,
    required this.accentColor,
  });
}

/// Niemutowalny model wszystkich flag i mnożników realizmu rozgrywki.
@immutable
class GameplayRealismFlags {
  // Fizyka i środowisko
  final bool enableCrosswindEchelons;
  final bool enableRoadHazardsAndSpectators;
  final bool enableExtremeWeatherProtocol;
  final bool enableEquipmentWearAndPunctures;
  final double crashFrequencyMultiplier;
  final double weatherSeverityMultiplier;

  // Fizjologia i telemetria
  final bool enableDailyDayFormVariance;
  final bool enableHeatAndAltitudeStress;
  final bool enableNutritionAndBonking;
  final TelemetryVisibilityMode telemetryVisibility;
  final double fatigueAccumulationMultiplier;

  // Taktyka i AI peletonu
  final bool enablePelotonDiplomacyAndBetrayal;
  final bool enableUnwrittenPelotonEtiquette;
  final bool enableDirectRiderSteering;
  final double aiTacticalAggressionMultiplier;

  // Przepisy UCI i logistyka
  final UciCommissaireStrictness uciStrictness;
  final bool enableDynamicRuleEvolution;
  final bool enableTeamBusWarmupAndConvoy;

  // Kariera, finanse i zapis
  final ScoutingFogOfWarMode scoutingFogOfWar;
  final SaveIntegrityMode saveIntegrity;
  final bool enableSponsorPressureAndFiring;
  final bool enableTransferRumorsAndPoaching;
  final double economyDifficultyMultiplier;

  const GameplayRealismFlags({
    required this.enableCrosswindEchelons,
    required this.enableRoadHazardsAndSpectators,
    required this.enableExtremeWeatherProtocol,
    required this.enableEquipmentWearAndPunctures,
    required this.crashFrequencyMultiplier,
    required this.weatherSeverityMultiplier,
    required this.enableDailyDayFormVariance,
    required this.enableHeatAndAltitudeStress,
    required this.enableNutritionAndBonking,
    required this.telemetryVisibility,
    required this.fatigueAccumulationMultiplier,
    required this.enablePelotonDiplomacyAndBetrayal,
    required this.enableUnwrittenPelotonEtiquette,
    required this.enableDirectRiderSteering,
    required this.aiTacticalAggressionMultiplier,
    required this.uciStrictness,
    required this.enableDynamicRuleEvolution,
    required this.enableTeamBusWarmupAndConvoy,
    required this.scoutingFogOfWar,
    required this.saveIntegrity,
    required this.enableSponsorPressureAndFiring,
    required this.enableTransferRumorsAndPoaching,
    required this.economyDifficultyMultiplier,
  });

  /// Domyślna konfiguracja WorldTour Standard.
  factory GameplayRealismFlags.balancedDefault() {
    return const GameplayRealismFlags(
      enableCrosswindEchelons: true,
      enableRoadHazardsAndSpectators: true,
      enableExtremeWeatherProtocol: true,
      enableEquipmentWearAndPunctures: true,
      crashFrequencyMultiplier: 1.0,
      weatherSeverityMultiplier: 1.0,
      enableDailyDayFormVariance: true,
      enableHeatAndAltitudeStress: true,
      enableNutritionAndBonking: true,
      telemetryVisibility: TelemetryVisibilityMode.fullLive,
      fatigueAccumulationMultiplier: 1.0,
      enablePelotonDiplomacyAndBetrayal: true,
      enableUnwrittenPelotonEtiquette: true,
      enableDirectRiderSteering: true,
      aiTacticalAggressionMultiplier: 1.0,
      uciStrictness: UciCommissaireStrictness.standard,
      enableDynamicRuleEvolution: true,
      enableTeamBusWarmupAndConvoy: true,
      scoutingFogOfWar: ScoutingFogOfWarMode.partialEstimate,
      saveIntegrity: SaveIntegrityMode.standardMultiSlot,
      enableSponsorPressureAndFiring: true,
      enableTransferRumorsAndPoaching: true,
      economyDifficultyMultiplier: 1.0,
    );
  }

  /// Wyliczony wskaźnik realizmu w skali 0–100.
  int get realismScore {
    var score = 0;
    if (enableCrosswindEchelons) score += 5;
    if (enableRoadHazardsAndSpectators) score += 4;
    if (enableExtremeWeatherProtocol) score += 4;
    if (enableEquipmentWearAndPunctures) score += 5;
    if (enableDailyDayFormVariance) score += 5;
    if (enableHeatAndAltitudeStress) score += 5;
    if (enableNutritionAndBonking) score += 6;
    if (enablePelotonDiplomacyAndBetrayal) score += 4;
    if (enableUnwrittenPelotonEtiquette) score += 4;
    if (enableDynamicRuleEvolution) score += 3;
    if (enableTeamBusWarmupAndConvoy) score += 3;
    if (enableSponsorPressureAndFiring) score += 4;
    if (enableTransferRumorsAndPoaching) score += 3;

    score += telemetryVisibility.realismPoints;
    score += uciStrictness.realismPoints;
    score += scoutingFogOfWar.realismPoints;
    score += saveIntegrity.realismPoints;

    // Bonus za mnożniki >= 1.0
    if (crashFrequencyMultiplier >= 1.0) {
      score += ((crashFrequencyMultiplier - 1.0) * 3).round().clamp(0, 3);
    }
    if (fatigueAccumulationMultiplier >= 1.0) {
      score += ((fatigueAccumulationMultiplier - 1.0) * 4).round().clamp(0, 3);
    }
    if (aiTacticalAggressionMultiplier >= 1.0) {
      score += ((aiTacticalAggressionMultiplier - 1.0) * 3).round().clamp(0, 2);
    }
    if (economyDifficultyMultiplier >= 1.0) {
      score += ((economyDifficultyMultiplier - 1.0) * 3).round().clamp(0, 2);
    }

    return score.clamp(0, 100);
  }

  /// Etykieta poziomu trudności wynikająca z aktualnego wskaźnika realizmu.
  String get difficultyLabel {
    final s = realismScore;
    if (s < 30) return 'Swobodny';
    if (s < 58) return 'Zbalansowany';
    if (s < 78) return 'Symulacyjny';
    if (s < 90) return 'Hardcore';
    return 'Ekstremalny';
  }

  GameplayRealismFlags copyWith({
    bool? enableCrosswindEchelons,
    bool? enableRoadHazardsAndSpectators,
    bool? enableExtremeWeatherProtocol,
    bool? enableEquipmentWearAndPunctures,
    double? crashFrequencyMultiplier,
    double? weatherSeverityMultiplier,
    bool? enableDailyDayFormVariance,
    bool? enableHeatAndAltitudeStress,
    bool? enableNutritionAndBonking,
    TelemetryVisibilityMode? telemetryVisibility,
    double? fatigueAccumulationMultiplier,
    bool? enablePelotonDiplomacyAndBetrayal,
    bool? enableUnwrittenPelotonEtiquette,
    bool? enableDirectRiderSteering,
    double? aiTacticalAggressionMultiplier,
    UciCommissaireStrictness? uciStrictness,
    bool? enableDynamicRuleEvolution,
    bool? enableTeamBusWarmupAndConvoy,
    ScoutingFogOfWarMode? scoutingFogOfWar,
    SaveIntegrityMode? saveIntegrity,
    bool? enableSponsorPressureAndFiring,
    bool? enableTransferRumorsAndPoaching,
    double? economyDifficultyMultiplier,
  }) {
    return GameplayRealismFlags(
      enableCrosswindEchelons:
          enableCrosswindEchelons ?? this.enableCrosswindEchelons,
      enableRoadHazardsAndSpectators:
          enableRoadHazardsAndSpectators ?? this.enableRoadHazardsAndSpectators,
      enableExtremeWeatherProtocol:
          enableExtremeWeatherProtocol ?? this.enableExtremeWeatherProtocol,
      enableEquipmentWearAndPunctures:
          enableEquipmentWearAndPunctures ??
          this.enableEquipmentWearAndPunctures,
      crashFrequencyMultiplier: (crashFrequencyMultiplier ??
              this.crashFrequencyMultiplier)
          .clamp(0.0, 2.5)
          .toDouble(),
      weatherSeverityMultiplier: (weatherSeverityMultiplier ??
              this.weatherSeverityMultiplier)
          .clamp(0.25, 2.0)
          .toDouble(),
      enableDailyDayFormVariance:
          enableDailyDayFormVariance ?? this.enableDailyDayFormVariance,
      enableHeatAndAltitudeStress:
          enableHeatAndAltitudeStress ?? this.enableHeatAndAltitudeStress,
      enableNutritionAndBonking:
          enableNutritionAndBonking ?? this.enableNutritionAndBonking,
      telemetryVisibility: telemetryVisibility ?? this.telemetryVisibility,
      fatigueAccumulationMultiplier: (fatigueAccumulationMultiplier ??
              this.fatigueAccumulationMultiplier)
          .clamp(0.5, 2.0)
          .toDouble(),
      enablePelotonDiplomacyAndBetrayal:
          enablePelotonDiplomacyAndBetrayal ??
          this.enablePelotonDiplomacyAndBetrayal,
      enableUnwrittenPelotonEtiquette:
          enableUnwrittenPelotonEtiquette ??
          this.enableUnwrittenPelotonEtiquette,
      enableDirectRiderSteering:
          enableDirectRiderSteering ?? this.enableDirectRiderSteering,
      aiTacticalAggressionMultiplier: (aiTacticalAggressionMultiplier ??
              this.aiTacticalAggressionMultiplier)
          .clamp(0.5, 1.8)
          .toDouble(),
      uciStrictness: uciStrictness ?? this.uciStrictness,
      enableDynamicRuleEvolution:
          enableDynamicRuleEvolution ?? this.enableDynamicRuleEvolution,
      enableTeamBusWarmupAndConvoy:
          enableTeamBusWarmupAndConvoy ?? this.enableTeamBusWarmupAndConvoy,
      scoutingFogOfWar: scoutingFogOfWar ?? this.scoutingFogOfWar,
      saveIntegrity: saveIntegrity ?? this.saveIntegrity,
      enableSponsorPressureAndFiring:
          enableSponsorPressureAndFiring ?? this.enableSponsorPressureAndFiring,
      enableTransferRumorsAndPoaching:
          enableTransferRumorsAndPoaching ??
          this.enableTransferRumorsAndPoaching,
      economyDifficultyMultiplier: (economyDifficultyMultiplier ??
              this.economyDifficultyMultiplier)
          .clamp(0.5, 2.0)
          .toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enableCrosswindEchelons': enableCrosswindEchelons,
      'enableRoadHazardsAndSpectators': enableRoadHazardsAndSpectators,
      'enableExtremeWeatherProtocol': enableExtremeWeatherProtocol,
      'enableEquipmentWearAndPunctures': enableEquipmentWearAndPunctures,
      'crashFrequencyMultiplier': crashFrequencyMultiplier,
      'weatherSeverityMultiplier': weatherSeverityMultiplier,
      'enableDailyDayFormVariance': enableDailyDayFormVariance,
      'enableHeatAndAltitudeStress': enableHeatAndAltitudeStress,
      'enableNutritionAndBonking': enableNutritionAndBonking,
      'telemetryVisibility': telemetryVisibility.name,
      'fatigueAccumulationMultiplier': fatigueAccumulationMultiplier,
      'enablePelotonDiplomacyAndBetrayal': enablePelotonDiplomacyAndBetrayal,
      'enableUnwrittenPelotonEtiquette': enableUnwrittenPelotonEtiquette,
      'enableDirectRiderSteering': enableDirectRiderSteering,
      'aiTacticalAggressionMultiplier': aiTacticalAggressionMultiplier,
      'uciStrictness': uciStrictness.name,
      'enableDynamicRuleEvolution': enableDynamicRuleEvolution,
      'enableTeamBusWarmupAndConvoy': enableTeamBusWarmupAndConvoy,
      'scoutingFogOfWar': scoutingFogOfWar.name,
      'saveIntegrity': saveIntegrity.name,
      'enableSponsorPressureAndFiring': enableSponsorPressureAndFiring,
      'enableTransferRumorsAndPoaching': enableTransferRumorsAndPoaching,
      'economyDifficultyMultiplier': economyDifficultyMultiplier,
    };
  }

  factory GameplayRealismFlags.fromJson(Map<String, dynamic> json) {
    final defaults = GameplayRealismFlags.balancedDefault();
    bool readBool(String key, bool fallback) {
      final raw = json[key];
      return raw is bool ? raw : fallback;
    }

    double readDouble(String key, double fallback, double min, double max) {
      final raw = json[key];
      if (raw is num && raw.isFinite) {
        return raw.toDouble().clamp(min, max).toDouble();
      }
      return fallback;
    }

    return GameplayRealismFlags(
      enableCrosswindEchelons: readBool(
        'enableCrosswindEchelons',
        defaults.enableCrosswindEchelons,
      ),
      enableRoadHazardsAndSpectators: readBool(
        'enableRoadHazardsAndSpectators',
        defaults.enableRoadHazardsAndSpectators,
      ),
      enableExtremeWeatherProtocol: readBool(
        'enableExtremeWeatherProtocol',
        defaults.enableExtremeWeatherProtocol,
      ),
      enableEquipmentWearAndPunctures: readBool(
        'enableEquipmentWearAndPunctures',
        defaults.enableEquipmentWearAndPunctures,
      ),
      crashFrequencyMultiplier: readDouble(
        'crashFrequencyMultiplier',
        defaults.crashFrequencyMultiplier,
        0.0,
        2.5,
      ),
      weatherSeverityMultiplier: readDouble(
        'weatherSeverityMultiplier',
        defaults.weatherSeverityMultiplier,
        0.25,
        2.0,
      ),
      enableDailyDayFormVariance: readBool(
        'enableDailyDayFormVariance',
        defaults.enableDailyDayFormVariance,
      ),
      enableHeatAndAltitudeStress: readBool(
        'enableHeatAndAltitudeStress',
        defaults.enableHeatAndAltitudeStress,
      ),
      enableNutritionAndBonking: readBool(
        'enableNutritionAndBonking',
        defaults.enableNutritionAndBonking,
      ),
      telemetryVisibility: TelemetryVisibilityMode.fromJson(
        json['telemetryVisibility']?.toString(),
      ),
      fatigueAccumulationMultiplier: readDouble(
        'fatigueAccumulationMultiplier',
        defaults.fatigueAccumulationMultiplier,
        0.5,
        2.0,
      ),
      enablePelotonDiplomacyAndBetrayal: readBool(
        'enablePelotonDiplomacyAndBetrayal',
        defaults.enablePelotonDiplomacyAndBetrayal,
      ),
      enableUnwrittenPelotonEtiquette: readBool(
        'enableUnwrittenPelotonEtiquette',
        defaults.enableUnwrittenPelotonEtiquette,
      ),
      enableDirectRiderSteering: readBool(
        'enableDirectRiderSteering',
        defaults.enableDirectRiderSteering,
      ),
      aiTacticalAggressionMultiplier: readDouble(
        'aiTacticalAggressionMultiplier',
        defaults.aiTacticalAggressionMultiplier,
        0.5,
        1.8,
      ),
      uciStrictness: UciCommissaireStrictness.fromJson(
        json['uciStrictness']?.toString(),
      ),
      enableDynamicRuleEvolution: readBool(
        'enableDynamicRuleEvolution',
        defaults.enableDynamicRuleEvolution,
      ),
      enableTeamBusWarmupAndConvoy: readBool(
        'enableTeamBusWarmupAndConvoy',
        defaults.enableTeamBusWarmupAndConvoy,
      ),
      scoutingFogOfWar: ScoutingFogOfWarMode.fromJson(
        json['scoutingFogOfWar']?.toString(),
      ),
      saveIntegrity: SaveIntegrityMode.fromJson(
        json['saveIntegrity']?.toString(),
      ),
      enableSponsorPressureAndFiring: readBool(
        'enableSponsorPressureAndFiring',
        defaults.enableSponsorPressureAndFiring,
      ),
      enableTransferRumorsAndPoaching: readBool(
        'enableTransferRumorsAndPoaching',
        defaults.enableTransferRumorsAndPoaching,
      ),
      economyDifficultyMultiplier: readDouble(
        'economyDifficultyMultiplier',
        defaults.economyDifficultyMultiplier,
        0.5,
        2.0,
      ),
    );
  }

  /// Zwraca wartość flagi logicznej po kluczu lub `null`, jeśli klucz nie istnieje.
  bool? getBoolFlag(String key) {
    switch (key) {
      case 'enableCrosswindEchelons':
        return enableCrosswindEchelons;
      case 'enableRoadHazardsAndSpectators':
        return enableRoadHazardsAndSpectators;
      case 'enableExtremeWeatherProtocol':
        return enableExtremeWeatherProtocol;
      case 'enableEquipmentWearAndPunctures':
        return enableEquipmentWearAndPunctures;
      case 'enableDailyDayFormVariance':
        return enableDailyDayFormVariance;
      case 'enableHeatAndAltitudeStress':
        return enableHeatAndAltitudeStress;
      case 'enableNutritionAndBonking':
        return enableNutritionAndBonking;
      case 'enablePelotonDiplomacyAndBetrayal':
        return enablePelotonDiplomacyAndBetrayal;
      case 'enableUnwrittenPelotonEtiquette':
        return enableUnwrittenPelotonEtiquette;
      case 'enableDirectRiderSteering':
        return enableDirectRiderSteering;
      case 'enableDynamicRuleEvolution':
        return enableDynamicRuleEvolution;
      case 'enableTeamBusWarmupAndConvoy':
        return enableTeamBusWarmupAndConvoy;
      case 'enableSponsorPressureAndFiring':
        return enableSponsorPressureAndFiring;
      case 'enableTransferRumorsAndPoaching':
        return enableTransferRumorsAndPoaching;
      default:
        return null;
    }
  }

  /// Tworzy kopię ze zmienioną flagą logiczną wskazaną przez [key].
  GameplayRealismFlags withBoolFlag(String key, bool value) {
    switch (key) {
      case 'enableCrosswindEchelons':
        return copyWith(enableCrosswindEchelons: value);
      case 'enableRoadHazardsAndSpectators':
        return copyWith(enableRoadHazardsAndSpectators: value);
      case 'enableExtremeWeatherProtocol':
        return copyWith(enableExtremeWeatherProtocol: value);
      case 'enableEquipmentWearAndPunctures':
        return copyWith(enableEquipmentWearAndPunctures: value);
      case 'enableDailyDayFormVariance':
        return copyWith(enableDailyDayFormVariance: value);
      case 'enableHeatAndAltitudeStress':
        return copyWith(enableHeatAndAltitudeStress: value);
      case 'enableNutritionAndBonking':
        return copyWith(enableNutritionAndBonking: value);
      case 'enablePelotonDiplomacyAndBetrayal':
        return copyWith(enablePelotonDiplomacyAndBetrayal: value);
      case 'enableUnwrittenPelotonEtiquette':
        return copyWith(enableUnwrittenPelotonEtiquette: value);
      case 'enableDirectRiderSteering':
        return copyWith(enableDirectRiderSteering: value);
      case 'enableDynamicRuleEvolution':
        return copyWith(enableDynamicRuleEvolution: value);
      case 'enableTeamBusWarmupAndConvoy':
        return copyWith(enableTeamBusWarmupAndConvoy: value);
      case 'enableSponsorPressureAndFiring':
        return copyWith(enableSponsorPressureAndFiring: value);
      case 'enableTransferRumorsAndPoaching':
        return copyWith(enableTransferRumorsAndPoaching: value);
      default:
        return this;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameplayRealismFlags &&
        other.enableCrosswindEchelons == enableCrosswindEchelons &&
        other.enableRoadHazardsAndSpectators ==
            enableRoadHazardsAndSpectators &&
        other.enableExtremeWeatherProtocol == enableExtremeWeatherProtocol &&
        other.enableEquipmentWearAndPunctures ==
            enableEquipmentWearAndPunctures &&
        (other.crashFrequencyMultiplier - crashFrequencyMultiplier).abs() <
            1e-6 &&
        (other.weatherSeverityMultiplier - weatherSeverityMultiplier).abs() <
            1e-6 &&
        other.enableDailyDayFormVariance == enableDailyDayFormVariance &&
        other.enableHeatAndAltitudeStress == enableHeatAndAltitudeStress &&
        other.enableNutritionAndBonking == enableNutritionAndBonking &&
        other.telemetryVisibility == telemetryVisibility &&
        (other.fatigueAccumulationMultiplier - fatigueAccumulationMultiplier)
                .abs() <
            1e-6 &&
        other.enablePelotonDiplomacyAndBetrayal ==
            enablePelotonDiplomacyAndBetrayal &&
        other.enableUnwrittenPelotonEtiquette ==
            enableUnwrittenPelotonEtiquette &&
        other.enableDirectRiderSteering == enableDirectRiderSteering &&
        (other.aiTacticalAggressionMultiplier -
                    aiTacticalAggressionMultiplier)
                .abs() <
            1e-6 &&
        other.uciStrictness == uciStrictness &&
        other.enableDynamicRuleEvolution == enableDynamicRuleEvolution &&
        other.enableTeamBusWarmupAndConvoy == enableTeamBusWarmupAndConvoy &&
        other.scoutingFogOfWar == scoutingFogOfWar &&
        other.saveIntegrity == saveIntegrity &&
        other.enableSponsorPressureAndFiring ==
            enableSponsorPressureAndFiring &&
        other.enableTransferRumorsAndPoaching ==
            enableTransferRumorsAndPoaching &&
        (other.economyDifficultyMultiplier - economyDifficultyMultiplier)
                .abs() <
            1e-6;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    enableCrosswindEchelons,
    enableRoadHazardsAndSpectators,
    enableExtremeWeatherProtocol,
    enableEquipmentWearAndPunctures,
    crashFrequencyMultiplier.toStringAsFixed(2),
    weatherSeverityMultiplier.toStringAsFixed(2),
    enableDailyDayFormVariance,
    enableHeatAndAltitudeStress,
    enableNutritionAndBonking,
    telemetryVisibility,
    fatigueAccumulationMultiplier.toStringAsFixed(2),
    enablePelotonDiplomacyAndBetrayal,
    enableUnwrittenPelotonEtiquette,
    enableDirectRiderSteering,
    aiTacticalAggressionMultiplier.toStringAsFixed(2),
    uciStrictness,
    enableDynamicRuleEvolution,
    enableTeamBusWarmupAndConvoy,
    scoutingFogOfWar,
    saveIntegrity,
    enableSponsorPressureAndFiring,
    enableTransferRumorsAndPoaching,
    economyDifficultyMultiplier.toStringAsFixed(2),
  ]);
}

/// Pełna definicja presetu realizmu z opisem i grupą docelową.
@immutable
class RealismPresetDefinition {
  final GameplayRealismPresetId id;
  final String name;
  final String subtitle;
  final String description;
  final String recommendedFor;
  final Color badgeColor;
  final IconData icon;
  final GameplayRealismFlags flags;

  const RealismPresetDefinition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.recommendedFor,
    required this.badgeColor,
    required this.icon,
    required this.flags,
  });
}

/// Metadane pojedynczej flagi logicznej w katalogu rejestru.
@immutable
class FeatureFlagMetadata {
  final String key;
  final String title;
  final String description;
  final FeatureFlagCategory category;
  final int realismImpactPoints;
  final bool isHardcoreRecommended;

  const FeatureFlagMetadata({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    required this.realismImpactPoints,
    this.isHardcoreRecommended = true,
  });
}

/// Różnica pomiędzy aktualną konfiguracją a wybranym presetem bazowym.
@immutable
class RealismFlagDiffEntry {
  final String key;
  final String title;
  final String presetValue;
  final String currentValue;

  const RealismFlagDiffEntry({
    required this.key,
    required this.title,
    required this.presetValue,
    required this.currentValue,
  });
}

/// Raport walidacji spójności wybranej konfiguracji realizmu.
@immutable
class RealismConfigValidationResult {
  final bool isValid;
  final List<String> warnings;

  const RealismConfigValidationResult({
    required this.isValid,
    required this.warnings,
  });
}

/// Centralny rejestr presetów oraz flag realizmu rozgrywki.
class AppFeatureFlagsAndPresets {
  AppFeatureFlagsAndPresets._();

  static final List<RealismPresetDefinition> presets =
      List<RealismPresetDefinition>.unmodifiable(<RealismPresetDefinition>[
        const RealismPresetDefinition(
          id: GameplayRealismPresetId.arcade,
          name: 'Arcade / Swobodny',
          subtitle: 'Szybka rozgrywka bez kar i mgły wojny',
          description:
              'Wyłącza kraksy z kibicami, mgłę skautingu i restrykcje UCI VAR. Idealny do testowania taktyki i krótkich sesji.',
          recommendedFor: 'Nowi menedżerowie i szybkie wyścigi',
          badgeColor: AppColors.accentBlue,
          icon: Icons.bolt_rounded,
          flags: GameplayRealismFlags(
            enableCrosswindEchelons: true,
            enableRoadHazardsAndSpectators: false,
            enableExtremeWeatherProtocol: false,
            enableEquipmentWearAndPunctures: false,
            crashFrequencyMultiplier: 0.35,
            weatherSeverityMultiplier: 0.65,
            enableDailyDayFormVariance: false,
            enableHeatAndAltitudeStress: false,
            enableNutritionAndBonking: false,
            telemetryVisibility: TelemetryVisibilityMode.fullLive,
            fatigueAccumulationMultiplier: 0.75,
            enablePelotonDiplomacyAndBetrayal: false,
            enableUnwrittenPelotonEtiquette: false,
            enableDirectRiderSteering: true,
            aiTacticalAggressionMultiplier: 0.85,
            uciStrictness: UciCommissaireStrictness.lenient,
            enableDynamicRuleEvolution: false,
            enableTeamBusWarmupAndConvoy: false,
            scoutingFogOfWar: ScoutingFogOfWarMode.transparent,
            saveIntegrity: SaveIntegrityMode.standardMultiSlot,
            enableSponsorPressureAndFiring: false,
            enableTransferRumorsAndPoaching: false,
            economyDifficultyMultiplier: 0.75,
          ),
        ),
        RealismPresetDefinition(
          id: GameplayRealismPresetId.balancedWorldTour,
          name: 'WorldTour Standard',
          subtitle: 'Domyślny balans symulacji i menedżera',
          description:
              'Pełna fizyka wachlarzy, żywienia, dyspozycji dnia i sędziów UCI przy zachowaniu czytelnej telemetrii i elastycznych zapisów.',
          recommendedFor: 'Większość kampanii WorldTour i ProSeries',
          badgeColor: AppColors.statusSuccess,
          icon: Icons.directions_bike_rounded,
          flags: GameplayRealismFlags.balancedDefault(),
        ),
        const RealismPresetDefinition(
          id: GameplayRealismPresetId.proSimulation,
          name: 'Pro Simulation',
          subtitle: 'Autentyczna taktyka, VAR i mgła skautingu',
          description:
              'Wprowadza opóźnioną telemetrię radiową, ścisłą mgłę wojny na rynku transferowym oraz rygorystyczne kontrole UCI Sprint VAR.',
          recommendedFor: 'Doświadczeni dyrektorzy sportowi (DS)',
          badgeColor: AppColors.goldAccent,
          icon: Icons.analytics_rounded,
          flags: GameplayRealismFlags(
            enableCrosswindEchelons: true,
            enableRoadHazardsAndSpectators: true,
            enableExtremeWeatherProtocol: true,
            enableEquipmentWearAndPunctures: true,
            crashFrequencyMultiplier: 1.15,
            weatherSeverityMultiplier: 1.2,
            enableDailyDayFormVariance: true,
            enableHeatAndAltitudeStress: true,
            enableNutritionAndBonking: true,
            telemetryVisibility: TelemetryVisibilityMode.delayedRadio,
            fatigueAccumulationMultiplier: 1.15,
            enablePelotonDiplomacyAndBetrayal: true,
            enableUnwrittenPelotonEtiquette: true,
            enableDirectRiderSteering: true,
            aiTacticalAggressionMultiplier: 1.2,
            uciStrictness: UciCommissaireStrictness.strictVar,
            enableDynamicRuleEvolution: true,
            enableTeamBusWarmupAndConvoy: true,
            scoutingFogOfWar: ScoutingFogOfWarMode.strictFogOfWar,
            saveIntegrity: SaveIntegrityMode.standardMultiSlot,
            enableSponsorPressureAndFiring: true,
            enableTransferRumorsAndPoaching: true,
            economyDifficultyMultiplier: 1.15,
          ),
        ),
        const RealismPresetDefinition(
          id: GameplayRealismPresetId.ironmanHardcore,
          name: 'Ironman Hardcore',
          subtitle: 'Bez miernika mocy, 1 slot auto-zapisu',
          description:
              'Maksymalny realizm: jazda na tętno i skalę RPE, bezlitosna ekonomia sponsorów, pełna podatność na pogodę i brak cofania zapisu.',
          recommendedFor: 'Weterani szukający bezkompromisowego wyzwania',
          badgeColor: AppColors.crimsonAlert,
          icon: Icons.shield_rounded,
          flags: GameplayRealismFlags(
            enableCrosswindEchelons: true,
            enableRoadHazardsAndSpectators: true,
            enableExtremeWeatherProtocol: true,
            enableEquipmentWearAndPunctures: true,
            crashFrequencyMultiplier: 1.35,
            weatherSeverityMultiplier: 1.4,
            enableDailyDayFormVariance: true,
            enableHeatAndAltitudeStress: true,
            enableNutritionAndBonking: true,
            telemetryVisibility: TelemetryVisibilityMode.rpeAndHeartRateOnly,
            fatigueAccumulationMultiplier: 1.25,
            enablePelotonDiplomacyAndBetrayal: true,
            enableUnwrittenPelotonEtiquette: true,
            enableDirectRiderSteering: true,
            aiTacticalAggressionMultiplier: 1.35,
            uciStrictness: UciCommissaireStrictness.strictVar,
            enableDynamicRuleEvolution: true,
            enableTeamBusWarmupAndConvoy: true,
            scoutingFogOfWar: ScoutingFogOfWarMode.strictFogOfWar,
            saveIntegrity: SaveIntegrityMode.ironmanSingleSlot,
            enableSponsorPressureAndFiring: true,
            enableTransferRumorsAndPoaching: true,
            economyDifficultyMultiplier: 1.35,
          ),
        ),
        const RealismPresetDefinition(
          id: GameplayRealismPresetId.goldenEraRetro,
          name: 'Złota Era Retro',
          subtitle: 'Kolarstwo bez elektroniki, radia i watomierzy',
          description:
              'Konfiguracja inspirowana dekadami 1970–2015: zero telemetrii elektronicznej, niepisana etykieta peletonu i klasyczne defekty.',
          recommendedFor: 'Tryb historyczny Golden Era',
          badgeColor: AppColors.amberWarning,
          icon: Icons.history_edu_rounded,
          flags: GameplayRealismFlags(
            enableCrosswindEchelons: true,
            enableRoadHazardsAndSpectators: true,
            enableExtremeWeatherProtocol: false,
            enableEquipmentWearAndPunctures: true,
            crashFrequencyMultiplier: 1.2,
            weatherSeverityMultiplier: 1.25,
            enableDailyDayFormVariance: true,
            enableHeatAndAltitudeStress: true,
            enableNutritionAndBonking: true,
            telemetryVisibility: TelemetryVisibilityMode.blindClassic,
            fatigueAccumulationMultiplier: 1.15,
            enablePelotonDiplomacyAndBetrayal: true,
            enableUnwrittenPelotonEtiquette: true,
            enableDirectRiderSteering: false,
            aiTacticalAggressionMultiplier: 1.1,
            uciStrictness: UciCommissaireStrictness.lenient,
            enableDynamicRuleEvolution: false,
            enableTeamBusWarmupAndConvoy: false,
            scoutingFogOfWar: ScoutingFogOfWarMode.strictFogOfWar,
            saveIntegrity: SaveIntegrityMode.standardMultiSlot,
            enableSponsorPressureAndFiring: true,
            enableTransferRumorsAndPoaching: false,
            economyDifficultyMultiplier: 1.0,
          ),
        ),
      ]);

  static final List<FeatureFlagMetadata> flagCatalog =
      List<FeatureFlagMetadata>.unmodifiable(<FeatureFlagMetadata>[
        const FeatureFlagMetadata(
          key: 'enableCrosswindEchelons',
          title: 'Wachlarze na wietrze bocznym',
          description:
              'Rwie peleton na otwartych odcinkach powyżej 25 km/h wiatru bocznego.',
          category: FeatureFlagCategory.physicsAndEnvironment,
          realismImpactPoints: 5,
        ),
        const FeatureFlagMetadata(
          key: 'enableRoadHazardsAndSpectators',
          title: 'Zagrożenia drogowe i kibice',
          description:
              'Wysepki z pachołkami, przejazdy kolejowe, plamy oleju i kibice na podjazdach.',
          category: FeatureFlagCategory.physicsAndEnvironment,
          realismImpactPoints: 4,
        ),
        const FeatureFlagMetadata(
          key: 'enableExtremeWeatherProtocol',
          title: 'Protokół ekstremalnej pogody UCI',
          description:
              'Neutralizacja, skracanie lub objazd etapu przy burzy, śnieżycy lub upale >40°C.',
          category: FeatureFlagCategory.physicsAndEnvironment,
          realismImpactPoints: 4,
        ),
        const FeatureFlagMetadata(
          key: 'enableEquipmentWearAndPunctures',
          title: 'Zużycie sprzętu i przebicia opon',
          description:
              'Wpływ wosku łańcucha, ciśnienia opon i sektorów brukowych na defekty.',
          category: FeatureFlagCategory.physicsAndEnvironment,
          realismImpactPoints: 5,
        ),
        const FeatureFlagMetadata(
          key: 'enableDailyDayFormVariance',
          title: 'Dyspozycja dnia „The Legs”',
          description:
              'Dzienna wariancja formy od -3 do +3 diamentów odkrywana po 30 km etapu.',
          category: FeatureFlagCategory.physiologyAndTelemetry,
          realismImpactPoints: 5,
        ),
        const FeatureFlagMetadata(
          key: 'enableHeatAndAltitudeStress',
          title: 'Stres cieplny i wysokość >1500 m',
          description:
              'Wymaga aklimatyzacji wysokościowej oraz chłodzenia Ice Socks w upale.',
          category: FeatureFlagCategory.physiologyAndTelemetry,
          realismImpactPoints: 5,
        ),
        const FeatureFlagMetadata(
          key: 'enableNutritionAndBonking',
          title: 'Gospodarka glikogenem i „ściana”',
          description:
              'Konieczność dowożenia bidonów oraz żeli węglowodanowych z wozu.',
          category: FeatureFlagCategory.physiologyAndTelemetry,
          realismImpactPoints: 6,
        ),
        const FeatureFlagMetadata(
          key: 'enablePelotonDiplomacyAndBetrayal',
          title: 'Dyplomacja i sojusze na szosie',
          description:
              'Pakty Stage-for-GC między dyrektorami sportowymi oraz konsekwencje zdrady.',
          category: FeatureFlagCategory.tacticsAndAi,
          realismImpactPoints: 4,
        ),
        const FeatureFlagMetadata(
          key: 'enableUnwrittenPelotonEtiquette',
          title: 'Niepisane zasady peletonu',
          description:
              'Wstrzymanie ataków przy kraksie lidera poza finałem i przerwy Nature Break.',
          category: FeatureFlagCategory.tacticsAndAi,
          realismImpactPoints: 4,
        ),
        const FeatureFlagMetadata(
          key: 'enableDirectRiderSteering',
          title: 'Bezpośrednie sterowanie kolarzem',
          description:
              'Ręczne manewrowanie W/S/A/D w peletonie i skok na koło rywala.',
          category: FeatureFlagCategory.tacticsAndAi,
          realismImpactPoints: 0,
          isHardcoreRecommended: false,
        ),
        const FeatureFlagMetadata(
          key: 'enableDynamicRuleEvolution',
          title: 'Ewolucja regulaminów UCI',
          description:
              'Coroczne zmiany limitów wagi roweru, szerokości kierownic i stref bufetu.',
          category: FeatureFlagCategory.rulesAndLogistics,
          realismImpactPoints: 3,
        ),
        const FeatureFlagMetadata(
          key: 'enableTeamBusWarmupAndConvoy',
          title: 'Autobus drużyny i protokół rozgrzewki',
          description:
              'Zarządzanie rozgrzewką VO2 Priming przed ITT i logistyką wozów technicznych.',
          category: FeatureFlagCategory.rulesAndLogistics,
          realismImpactPoints: 3,
        ),
        const FeatureFlagMetadata(
          key: 'enableSponsorPressureAndFiring',
          title: 'Presja sponsorów i zwolnienia',
          description:
              'Ryzyko utraty kontraktu menedżerskiego po niezrealizowaniu celów sezonu.',
          category: FeatureFlagCategory.careerAndEconomy,
          realismImpactPoints: 4,
        ),
        const FeatureFlagMetadata(
          key: 'enableTransferRumorsAndPoaching',
          title: 'Plotki transferowe i podkupywanie',
          description:
              'Dynamiczna giełda medialna oraz wykup kontraktów kolarzy przez rywali.',
          category: FeatureFlagCategory.careerAndEconomy,
          realismImpactPoints: 3,
        ),
      ]);

  /// Zwraca definicję presetu po identyfikatorze (dla `custom` zwraca standardowy opis z bazowymi flagami).
  static RealismPresetDefinition presetById(GameplayRealismPresetId id) {
    if (id == GameplayRealismPresetId.custom) {
      return RealismPresetDefinition(
        id: GameplayRealismPresetId.custom,
        name: 'Własna Konfiguracja',
        subtitle: 'Indywidualnie dobrane flagi realizmu',
        description:
            'Niestandardowy zestaw reguł fizyki, telemetrii, sędziów UCI i ekonomii.',
        recommendedFor: 'Menedżerowie tworzący własne zasady ligi lub kariery',
        badgeColor: AppColors.primaryAccent,
        icon: Icons.tune_rounded,
        flags: GameplayRealismFlags.balancedDefault(),
      );
    }
    return presets.firstWhere(
      (p) => p.id == id,
      orElse: () => presets[1],
    );
  }

  /// Wykrywa czy podane flagi odpowiadają w 100% któremuś z predefiniowanych presetów.
  static GameplayRealismPresetId detectMatchingPreset(
    GameplayRealismFlags flags,
  ) {
    for (final preset in presets) {
      if (preset.flags == flags) {
        return preset.id;
      }
    }
    return GameplayRealismPresetId.custom;
  }

  /// Zwraca listę różnic pomiędzy aktualnymi flagami a wskazanym presetem.
  static List<RealismFlagDiffEntry> diffFromPreset(
    GameplayRealismFlags current,
    GameplayRealismPresetId baselineId,
  ) {
    final baseline = presetById(baselineId).flags;
    final diffs = <RealismFlagDiffEntry>[];

    for (final meta in flagCatalog) {
      final baseVal = baseline.getBoolFlag(meta.key);
      final currVal = current.getBoolFlag(meta.key);
      if (baseVal != null && currVal != null && baseVal != currVal) {
        diffs.add(
          RealismFlagDiffEntry(
            key: meta.key,
            title: meta.title,
            presetValue: baseVal ? 'Wł.' : 'Wył.',
            currentValue: currVal ? 'Wł.' : 'Wył.',
          ),
        );
      }
    }

    if (baseline.telemetryVisibility != current.telemetryVisibility) {
      diffs.add(
        RealismFlagDiffEntry(
          key: 'telemetryVisibility',
          title: 'Widoczność telemetrii',
          presetValue: baseline.telemetryVisibility.displayName,
          currentValue: current.telemetryVisibility.displayName,
        ),
      );
    }
    if (baseline.uciStrictness != current.uciStrictness) {
      diffs.add(
        RealismFlagDiffEntry(
          key: 'uciStrictness',
          title: 'Surowość sędziów UCI',
          presetValue: baseline.uciStrictness.displayName,
          currentValue: current.uciStrictness.displayName,
        ),
      );
    }
    if (baseline.scoutingFogOfWar != current.scoutingFogOfWar) {
      diffs.add(
        RealismFlagDiffEntry(
          key: 'scoutingFogOfWar',
          title: 'Mgła wojny skautingu',
          presetValue: baseline.scoutingFogOfWar.displayName,
          currentValue: current.scoutingFogOfWar.displayName,
        ),
      );
    }
    if (baseline.saveIntegrity != current.saveIntegrity) {
      diffs.add(
        RealismFlagDiffEntry(
          key: 'saveIntegrity',
          title: 'Integralność zapisu',
          presetValue: baseline.saveIntegrity.displayName,
          currentValue: current.saveIntegrity.displayName,
        ),
      );
    }

    return diffs;
  }

  /// Waliduje spójność logiczną konfiguracji i zwraca ewentualne ostrzeżenia.
  static RealismConfigValidationResult validateFlags(
    GameplayRealismFlags flags,
  ) {
    final warnings = <String>[];

    if (flags.saveIntegrity == SaveIntegrityMode.ironmanSingleSlot &&
        flags.realismScore < 45) {
      warnings.add(
        'Tryb Ironman przy niskim realizmie (<45 pkt) nie odblokowuje osiągnięć Hardcore.',
      );
    }
    if (!flags.enableEquipmentWearAndPunctures &&
        flags.crashFrequencyMultiplier > 1.5) {
      warnings.add(
        'Wysoki mnożnik kraks bez aktywnego zużycia opon może generować nienaturalne zdarzenia.',
      );
    }
    if (flags.telemetryVisibility == TelemetryVisibilityMode.blindClassic &&
        flags.enableTeamBusWarmupAndConvoy) {
      warnings.add(
        'Tryb bez elektroniki wyłącza podgląd trenażerów Smart podczas rozgrzewki w autobusie.',
      );
    }

    return RealismConfigValidationResult(
      isValid: warnings.isEmpty,
      warnings: List<String>.unmodifiable(warnings),
    );
  }
}

/// Stan centralnego rejestru flag realizmu przechowywany w Riverpod.
@immutable
class AppFeatureFlagsState {
  final GameplayRealismPresetId activePresetId;
  final GameplayRealismFlags flags;
  final bool isLockedInActiveCareer;
  final DateTime? lastUpdatedAt;

  const AppFeatureFlagsState({
    required this.activePresetId,
    required this.flags,
    required this.isLockedInActiveCareer,
    this.lastUpdatedAt,
  });

  factory AppFeatureFlagsState.initial() {
    return AppFeatureFlagsState(
      activePresetId: GameplayRealismPresetId.balancedWorldTour,
      flags: GameplayRealismFlags.balancedDefault(),
      isLockedInActiveCareer: false,
      lastUpdatedAt: null,
    );
  }

  AppFeatureFlagsState copyWith({
    GameplayRealismPresetId? activePresetId,
    GameplayRealismFlags? flags,
    bool? isLockedInActiveCareer,
    DateTime? lastUpdatedAt,
  }) {
    return AppFeatureFlagsState(
      activePresetId: activePresetId ?? this.activePresetId,
      flags: flags ?? this.flags,
      isLockedInActiveCareer:
          isLockedInActiveCareer ?? this.isLockedInActiveCareer,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'activePresetId': activePresetId.id,
      'flags': flags.toJson(),
      'isLockedInActiveCareer': isLockedInActiveCareer,
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  factory AppFeatureFlagsState.fromJson(Map<String, dynamic> json) {
    final rawFlags = json['flags'];
    final parsedFlags = rawFlags is Map<String, dynamic>
        ? GameplayRealismFlags.fromJson(rawFlags)
        : GameplayRealismFlags.balancedDefault();
    final detectedPreset = AppFeatureFlagsAndPresets.detectMatchingPreset(
      parsedFlags,
    );
    final rawDate = json['lastUpdatedAt']?.toString();
    return AppFeatureFlagsState(
      activePresetId: json['activePresetId'] != null
          ? GameplayRealismPresetId.fromJson(json['activePresetId'].toString())
          : detectedPreset,
      flags: parsedFlags,
      isLockedInActiveCareer: json['isLockedInActiveCareer'] == true,
      lastUpdatedAt: rawDate != null ? DateTime.tryParse(rawDate) : null,
    );
  }
}

/// Kontroler Riverpod zarządzający konfiguracją realizmu rozgrywki.
class AppFeatureFlagsNotifier extends StateNotifier<AppFeatureFlagsState> {
  AppFeatureFlagsNotifier() : super(AppFeatureFlagsState.initial());

  /// Nakłada wybrany preset realizmu, jeśli konfiguracja nie jest zablokowana.
  bool applyPreset(GameplayRealismPresetId presetId) {
    if (state.isLockedInActiveCareer) return false;
    final definition = AppFeatureFlagsAndPresets.presetById(presetId);
    state = state.copyWith(
      activePresetId: definition.id,
      flags: definition.flags,
      lastUpdatedAt: DateTime.now(),
    );
    return true;
  }

  /// Aktualizuje wybrane pola flag i automatycznie wykrywa dopasowanie presetu.
  bool updateFlags(
    GameplayRealismFlags Function(GameplayRealismFlags current) updater,
  ) {
    if (state.isLockedInActiveCareer) return false;
    final updated = updater(state.flags);
    final matchedPreset = AppFeatureFlagsAndPresets.detectMatchingPreset(
      updated,
    );
    state = state.copyWith(
      activePresetId: matchedPreset,
      flags: updated,
      lastUpdatedAt: DateTime.now(),
    );
    return true;
  }

  /// Przełącza pojedynczą flagę logiczną po jej kluczu katalogowym.
  bool toggleBooleanFlag(String key, bool value) {
    return updateFlags((current) => current.withBoolFlag(key, value));
  }

  /// Przywraca flagi aktywnego presetu (lub WorldTour Standard dla trybu Custom).
  bool resetToPresetDefaults() {
    if (state.isLockedInActiveCareer) return false;
    final targetId = state.activePresetId == GameplayRealismPresetId.custom
        ? GameplayRealismPresetId.balancedWorldTour
        : state.activePresetId;
    return applyPreset(targetId);
  }

  /// Blokuje lub odblokowuje edycję realizmu w aktywnej karierze (np. Ironman).
  void setCareerLock(bool locked) {
    state = state.copyWith(
      isLockedInActiveCareer: locked,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Odtwarza stan rejestru ze zserializowanego zapisu JSON.
  void loadFromJson(Map<String, dynamic> json) {
    state = AppFeatureFlagsState.fromJson(json);
  }
}

/// Główny provider stanu rejestru flag i presetów realizmu.
final appFeatureFlagsProvider =
    StateNotifierProvider<AppFeatureFlagsNotifier, AppFeatureFlagsState>(
      (ref) => AppFeatureFlagsNotifier(),
    );

/// Provider skrótowy zwracający aktualne flagi realizmu.
final activeRealismFlagsProvider = Provider<GameplayRealismFlags>(
  (ref) => ref.watch(appFeatureFlagsProvider.select((s) => s.flags)),
);

/// Provider zwracający bieżący wskaźnik realizmu (0–100).
final activeRealismScoreProvider = Provider<int>(
  (ref) => ref.watch(activeRealismFlagsProvider.select((f) => f.realismScore)),
);

/// Responsywny panel podglądu i konfiguracji centralnego rejestru realizmu.
class AppFeatureFlagsAndPresetsPanel extends ConsumerStatefulWidget {
  const AppFeatureFlagsAndPresetsPanel({super.key});

  @override
  ConsumerState<AppFeatureFlagsAndPresetsPanel> createState() =>
      _AppFeatureFlagsAndPresetsPanelState();
}

class _AppFeatureFlagsAndPresetsPanelState
    extends ConsumerState<AppFeatureFlagsAndPresetsPanel> {
  FeatureFlagCategory _selectedCategory =
      FeatureFlagCategory.physicsAndEnvironment;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appFeatureFlagsProvider);
    final notifier = ref.read(appFeatureFlagsProvider.notifier);
    final validation = AppFeatureFlagsAndPresets.validateFlags(state.flags);
    final isLocked = state.isLockedInActiveCareer;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 640;
        final isWide = width >= 1100;
        final crossAxisCount = isWide ? 3 : (isCompact ? 1 : 2);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(state, notifier, isCompact, isLocked),
                if (validation.warnings.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildValidationBanner(validation.warnings),
                ],
                const SizedBox(height: 16),
                _buildPresetsGrid(
                  state: state,
                  notifier: notifier,
                  crossAxisCount: crossAxisCount,
                  isLocked: isLocked,
                ),
                const SizedBox(height: 18),
                _buildCategorySelector(isCompact),
                const SizedBox(height: 12),
                _buildCategoryFlagsList(
                  state: state,
                  notifier: notifier,
                  isCompact: isCompact,
                  isLocked: isLocked,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    AppFeatureFlagsState state,
    AppFeatureFlagsNotifier notifier,
    bool isCompact,
    bool isLocked,
  ) {
    final score = state.flags.realismScore;
    final scoreColor = score >= 80
        ? AppColors.crimsonAlert
        : score >= 55
        ? AppColors.goldAccent
        : AppColors.statusSuccess;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Rejestr Realizmu Rozgrywki',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Preset: ${state.activePresetId.displayName} • ${state.flags.difficultyLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.2,
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
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'REALIZM ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    '$score/100',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _InteractiveActionButton(
              label: isLocked ? 'Zablokowane' : 'Resetuj',
              icon: isLocked ? Icons.lock_rounded : Icons.refresh_rounded,
              enabled: !isLocked,
              onPressed: notifier.resetToPresetDefaults,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValidationBanner(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.amberWarning.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.amberWarning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: warnings
                  .map(
                    (w) => Text(
                      w,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsGrid({
    required AppFeatureFlagsState state,
    required AppFeatureFlagsNotifier notifier,
    required int crossAxisCount,
    required bool isLocked,
  }) {
    final presets = AppFeatureFlagsAndPresets.presets;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: presets.map((preset) {
            final isSelected = state.activePresetId == preset.id;
            return SizedBox(
              width: itemWidth,
              child: _PresetCard(
                preset: preset,
                isSelected: isSelected,
                enabled: !isLocked,
                onTap: () => notifier.applyPreset(preset.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategorySelector(bool isCompact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FeatureFlagCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CategoryTabChip(
              category: category,
              isSelected: isSelected,
              compact: isCompact,
              onTap: () => setState(() => _selectedCategory = category),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryFlagsList({
    required AppFeatureFlagsState state,
    required AppFeatureFlagsNotifier notifier,
    required bool isCompact,
    required bool isLocked,
  }) {
    final flagsInCategory = AppFeatureFlagsAndPresets.flagCatalog
        .where((meta) => meta.category == _selectedCategory)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: flagsInCategory.map((meta) {
          final currentVal = state.flags.getBoolFlag(meta.key) ?? false;
          return _FlagToggleRow(
            metadata: meta,
            value: currentVal,
            enabled: !isLocked,
            onChanged: (next) => notifier.toggleBooleanFlag(meta.key, next),
          );
        }).toList(),
      ),
    );
  }
}

class _PresetCard extends StatefulWidget {
  final RealismPresetDefinition preset;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<_PresetCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.preset.badgeColor
        : _focused
        ? AppColors.accentBlue
        : _hovered && widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : const Color(0xFF2A2F3D);

    final bgColor = widget.isSelected
        ? AppColors.surfaceLight
        : _hovered && widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.65)
        : AppColors.surface;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.55,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        widget.preset.icon,
                        size: 18,
                        color: widget.preset.badgeColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.preset.badgeColor.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.preset.flags.realismScore}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: widget.preset.badgeColor,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.preset.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTabChip extends StatefulWidget {
  final FeatureFlagCategory category;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _CategoryTabChip({
    required this.category,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_CategoryTabChip> createState() => _CategoryTabChipState();
}

class _CategoryTabChipState extends State<_CategoryTabChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.category.accentColor
        : _focused
        ? AppColors.accentBlue
        : _hovered
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.category.accentColor.withValues(alpha: 0.16)
                  : _hovered
                  ? AppColors.surfaceLight
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.category.icon,
                  size: 16,
                  color: widget.isSelected
                      ? widget.category.accentColor
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.category.displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    letterSpacing: -0.2,
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

class _FlagToggleRow extends StatefulWidget {
  final FeatureFlagMetadata metadata;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _FlagToggleRow({
    required this.metadata,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_FlagToggleRow> createState() => _FlagToggleRowState();
}

class _FlagToggleRowState extends State<_FlagToggleRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered && widget.enabled
              ? AppColors.surfaceLight
              : AppColors.background.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.metadata.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.metadata.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: widget.value,
              activeThumbColor: AppColors.goldAccent,
              activeTrackColor: AppColors.primaryAccent,
              onChanged: widget.enabled ? widget.onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _hovered && widget.enabled
                    ? AppColors.surfaceLight
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focused
                      ? AppColors.accentBlue
                      : const Color(0xFF2A2F3D),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(widget.icon, size: 15, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
