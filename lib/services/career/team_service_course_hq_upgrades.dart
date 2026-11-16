import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Identyfikatory 5 modułów budynków Bazy Logistycznej Zespołu (Service Course HQ).
enum ServiceCourseModuleId {
  windTunnel,
  hypoxiaCenter,
  recoveryBusFleet,
  drivetrainWaxWorkshop,
  scoutingAcademy;

  String toJson() => name;

  static ServiceCourseModuleId fromJson(String value) {
    return ServiceCourseModuleId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ServiceCourseModuleId.windTunnel,
    );
  }

  String get title {
    switch (this) {
      case ServiceCourseModuleId.windTunnel:
        return 'Własny Tunel Aerodynamiczny';
      case ServiceCourseModuleId.hypoxiaCenter:
        return 'Centrum Hipoksji i Komór Niskociśnieniowych';
      case ServiceCourseModuleId.recoveryBusFleet:
        return 'Flota Autobusów Regeneracyjnych';
      case ServiceCourseModuleId.drivetrainWaxWorkshop:
        return 'Warsztat Woskowania Napędów';
      case ServiceCourseModuleId.scoutingAcademy:
        return 'Akademia Skautingu';
    }
  }

  String get shortTitle {
    switch (this) {
      case ServiceCourseModuleId.windTunnel:
        return 'Tunel Aero';
      case ServiceCourseModuleId.hypoxiaCenter:
        return 'Centrum Hipoksji';
      case ServiceCourseModuleId.recoveryBusFleet:
        return 'Flota Autobusów';
      case ServiceCourseModuleId.drivetrainWaxWorkshop:
        return 'Warsztat Wosku';
      case ServiceCourseModuleId.scoutingAcademy:
        return 'Akademia Skautingu';
    }
  }

  String get categoryTag {
    switch (this) {
      case ServiceCourseModuleId.windTunnel:
        return 'AERO & R&D';
      case ServiceCourseModuleId.hypoxiaCenter:
        return 'FIZJOLOGIA';
      case ServiceCourseModuleId.recoveryBusFleet:
        return 'REGENERACJA';
      case ServiceCourseModuleId.drivetrainWaxWorkshop:
        return 'MECHANIKA';
      case ServiceCourseModuleId.scoutingAcademy:
        return 'SKAUTING';
    }
  }

  String get summary {
    switch (this) {
      case ServiceCourseModuleId.windTunnel:
        return 'Stała redukcja oporu aerodynamicznego CdA kolarzy i tańsze sesje bike-fittingu.';
      case ServiceCourseModuleId.hypoxiaCenter:
        return 'Szybsza aklimatyzacja wysokogórska, wyższy pułap VO2max i mniejsze straty mocy powyżej 2000 m.';
      case ServiceCourseModuleId.recoveryBusFleet:
        return 'Lepsza regeneracja nocna między etapami, mniejszy stres podróży i odporność w 3. tygodniu GT.';
      case ServiceCourseModuleId.drivetrainWaxWorkshop:
        return 'Ultradźwiękowe woskowanie łańcuchów oszczędzające waty i zmniejszające zużycie napędu.';
      case ServiceCourseModuleId.scoutingAcademy:
        return 'Dokładniejsze raporty skautingowe, szybsze odkrywanie atrybutów oraz szybszy rozwój talentów U23.';
    }
  }

  Color get accentColor {
    switch (this) {
      case ServiceCourseModuleId.windTunnel:
        return AppColors.cyanAccent;
      case ServiceCourseModuleId.hypoxiaCenter:
        return AppColors.amberWarning;
      case ServiceCourseModuleId.recoveryBusFleet:
        return AppColors.statusSuccess;
      case ServiceCourseModuleId.drivetrainWaxWorkshop:
        return AppColors.goldAccent;
      case ServiceCourseModuleId.scoutingAcademy:
        return AppColors.accentBlue;
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCourseModuleId.windTunnel:
        return Icons.air_rounded;
      case ServiceCourseModuleId.hypoxiaCenter:
        return Icons.landscape_rounded;
      case ServiceCourseModuleId.recoveryBusFleet:
        return Icons.directions_bus_filled_rounded;
      case ServiceCourseModuleId.drivetrainWaxWorkshop:
        return Icons.build_circle_rounded;
      case ServiceCourseModuleId.scoutingAcademy:
        return Icons.travel_explore_rounded;
    }
  }
}

/// Specyfikacja pojedynczego poziomu (1–5) rozbudowy modułu Service Course HQ.
class ServiceCourseModuleLevelSpec {
  const ServiceCourseModuleLevelSpec({
    required this.level,
    required this.tierName,
    required this.buildCostEur,
    required this.annualUpkeepEur,
    required this.constructionDays,
    required this.primaryBonusLabel,
    required this.primaryBonusValue,
    required this.secondaryBonusLabel,
    required this.secondaryBonusValue,
    required this.description,
  });

  final int level;
  final String tierName;
  final int buildCostEur;
  final int annualUpkeepEur;
  final int constructionDays;
  final String primaryBonusLabel;
  final double primaryBonusValue;
  final String secondaryBonusLabel;
  final double secondaryBonusValue;
  final String description;
}

/// Pełna definicja katalogowa modułu Bazy Logistycznej Zespołu.
class ServiceCourseModuleDefinition {
  const ServiceCourseModuleDefinition({
    required this.id,
    required this.levels,
  });

  final ServiceCourseModuleId id;
  final List<ServiceCourseModuleLevelSpec> levels;

  int get maxLevel => levels.length;

  ServiceCourseModuleLevelSpec? specForLevel(int level) {
    if (level < 1 || level > levels.length) return null;
    return levels[level - 1];
  }
}

/// Bieżący stan pojedynczego modułu budynku w bazie drużyny.
class ServiceCourseModuleState {
  const ServiceCourseModuleState({
    required this.moduleId,
    this.currentLevel = 0,
    this.isUnderConstruction = false,
    this.targetLevel,
    this.remainingConstructionDays = 0,
    this.totalConstructionDays = 0,
    this.totalInvestedEur = 0,
  });

  final ServiceCourseModuleId moduleId;
  final int currentLevel;
  final bool isUnderConstruction;
  final int? targetLevel;
  final int remainingConstructionDays;
  final int totalConstructionDays;
  final int totalInvestedEur;

  double get constructionProgress {
    if (!isUnderConstruction || totalConstructionDays <= 0) {
      return 0.0;
    }
    final completed = totalConstructionDays - remainingConstructionDays;
    return (completed / totalConstructionDays).clamp(0.0, 1.0);
  }

  ServiceCourseModuleState copyWith({
    int? currentLevel,
    bool? isUnderConstruction,
    int? targetLevel,
    bool clearTargetLevel = false,
    int? remainingConstructionDays,
    int? totalConstructionDays,
    int? totalInvestedEur,
  }) {
    return ServiceCourseModuleState(
      moduleId: moduleId,
      currentLevel: currentLevel ?? this.currentLevel,
      isUnderConstruction: isUnderConstruction ?? this.isUnderConstruction,
      targetLevel: clearTargetLevel ? null : (targetLevel ?? this.targetLevel),
      remainingConstructionDays:
          remainingConstructionDays ?? this.remainingConstructionDays,
      totalConstructionDays:
          totalConstructionDays ?? this.totalConstructionDays,
      totalInvestedEur: totalInvestedEur ?? this.totalInvestedEur,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'moduleId': moduleId.toJson(),
      'currentLevel': currentLevel,
      'isUnderConstruction': isUnderConstruction,
      'targetLevel': targetLevel,
      'remainingConstructionDays': remainingConstructionDays,
      'totalConstructionDays': totalConstructionDays,
      'totalInvestedEur': totalInvestedEur,
    };
  }

  factory ServiceCourseModuleState.fromJson(Map<String, dynamic> json) {
    final moduleId = ServiceCourseModuleId.fromJson(
      (json['moduleId'] as String?) ?? 'windTunnel',
    );
    final rawLevel = (json['currentLevel'] as num?)?.toInt() ?? 0;
    return ServiceCourseModuleState(
      moduleId: moduleId,
      currentLevel: rawLevel.clamp(0, 5),
      isUnderConstruction: (json['isUnderConstruction'] as bool?) ?? false,
      targetLevel: (json['targetLevel'] as num?)?.toInt(),
      remainingConstructionDays:
          math.max(0, (json['remainingConstructionDays'] as num?)?.toInt() ?? 0),
      totalConstructionDays:
          math.max(0, (json['totalConstructionDays'] as num?)?.toInt() ?? 0),
      totalInvestedEur:
          math.max(0, (json['totalInvestedEur'] as num?)?.toInt() ?? 0),
    );
  }
}

/// Zbiorcze, stałe bonusy kariery wynikające z poziomu rozbudowy Service Course HQ.
class ServiceCourseCareerBonuses {
  const ServiceCourseCareerBonuses({
    required this.cdaReductionPercent,
    required this.windTunnelTestCostDiscountPercent,
    required this.altitudeAcclimatizationBonusPercent,
    required this.hypoxiaPenaltyMitigationPercent,
    required this.postStageRecoveryBonusPercent,
    required this.grandTourWeek3ResilienceBonusPercent,
    required this.drivetrainWattsSaved,
    required this.equipmentWearReductionPercent,
    required this.scoutingAccuracyBonusPercent,
    required this.u23PotentialGrowthBonusPercent,
    required this.totalAnnualUpkeepEur,
    required this.hqPrestigeScore,
    required this.hqTierLabel,
  });

  final double cdaReductionPercent;
  final double windTunnelTestCostDiscountPercent;
  final double altitudeAcclimatizationBonusPercent;
  final double hypoxiaPenaltyMitigationPercent;
  final double postStageRecoveryBonusPercent;
  final double grandTourWeek3ResilienceBonusPercent;
  final double drivetrainWattsSaved;
  final double equipmentWearReductionPercent;
  final double scoutingAccuracyBonusPercent;
  final double u23PotentialGrowthBonusPercent;
  final int totalAnnualUpkeepEur;
  final int hqPrestigeScore;
  final String hqTierLabel;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cdaReductionPercent': cdaReductionPercent,
      'windTunnelTestCostDiscountPercent': windTunnelTestCostDiscountPercent,
      'altitudeAcclimatizationBonusPercent': altitudeAcclimatizationBonusPercent,
      'hypoxiaPenaltyMitigationPercent': hypoxiaPenaltyMitigationPercent,
      'postStageRecoveryBonusPercent': postStageRecoveryBonusPercent,
      'grandTourWeek3ResilienceBonusPercent':
          grandTourWeek3ResilienceBonusPercent,
      'drivetrainWattsSaved': drivetrainWattsSaved,
      'equipmentWearReductionPercent': equipmentWearReductionPercent,
      'scoutingAccuracyBonusPercent': scoutingAccuracyBonusPercent,
      'u23PotentialGrowthBonusPercent': u23PotentialGrowthBonusPercent,
      'totalAnnualUpkeepEur': totalAnnualUpkeepEur,
      'hqPrestigeScore': hqPrestigeScore,
      'hqTierLabel': hqTierLabel,
    };
  }

  factory ServiceCourseCareerBonuses.fromJson(Map<String, dynamic> json) {
    return ServiceCourseCareerBonuses(
      cdaReductionPercent:
          (json['cdaReductionPercent'] as num?)?.toDouble() ?? 0.0,
      windTunnelTestCostDiscountPercent:
          (json['windTunnelTestCostDiscountPercent'] as num?)?.toDouble() ??
              0.0,
      altitudeAcclimatizationBonusPercent:
          (json['altitudeAcclimatizationBonusPercent'] as num?)?.toDouble() ??
              0.0,
      hypoxiaPenaltyMitigationPercent:
          (json['hypoxiaPenaltyMitigationPercent'] as num?)?.toDouble() ?? 0.0,
      postStageRecoveryBonusPercent:
          (json['postStageRecoveryBonusPercent'] as num?)?.toDouble() ?? 0.0,
      grandTourWeek3ResilienceBonusPercent:
          (json['grandTourWeek3ResilienceBonusPercent'] as num?)?.toDouble() ??
              0.0,
      drivetrainWattsSaved:
          (json['drivetrainWattsSaved'] as num?)?.toDouble() ?? 0.0,
      equipmentWearReductionPercent:
          (json['equipmentWearReductionPercent'] as num?)?.toDouble() ?? 0.0,
      scoutingAccuracyBonusPercent:
          (json['scoutingAccuracyBonusPercent'] as num?)?.toDouble() ?? 0.0,
      u23PotentialGrowthBonusPercent:
          (json['u23PotentialGrowthBonusPercent'] as num?)?.toDouble() ?? 0.0,
      totalAnnualUpkeepEur:
          (json['totalAnnualUpkeepEur'] as num?)?.toInt() ?? 0,
      hqPrestigeScore: (json['hqPrestigeScore'] as num?)?.toInt() ?? 0,
      hqTierLabel:
          (json['hqTierLabel'] as String?) ?? 'Baza Podstawowa',
    );
  }
}

/// Wpis w dzienniku inwestycji i rozbudowy Bazy Logistycznej.
class ServiceCourseUpgradeEvent {
  const ServiceCourseUpgradeEvent({
    required this.moduleId,
    required this.fromLevel,
    required this.toLevel,
    required this.costEur,
    required this.eventType,
    required this.timestampIso,
    required this.summary,
  });

  final ServiceCourseModuleId moduleId;
  final int fromLevel;
  final int toLevel;
  final int costEur;
  final String eventType;
  final String timestampIso;
  final String summary;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'moduleId': moduleId.toJson(),
      'fromLevel': fromLevel,
      'toLevel': toLevel,
      'costEur': costEur,
      'eventType': eventType,
      'timestampIso': timestampIso,
      'summary': summary,
    };
  }

  factory ServiceCourseUpgradeEvent.fromJson(Map<String, dynamic> json) {
    return ServiceCourseUpgradeEvent(
      moduleId: ServiceCourseModuleId.fromJson(
        (json['moduleId'] as String?) ?? 'windTunnel',
      ),
      fromLevel: (json['fromLevel'] as num?)?.toInt() ?? 0,
      toLevel: (json['toLevel'] as num?)?.toInt() ?? 1,
      costEur: (json['costEur'] as num?)?.toInt() ?? 0,
      eventType: (json['eventType'] as String?) ?? 'started',
      timestampIso: (json['timestampIso'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
    );
  }
}

/// Wynik walidacji możliwości rozpoczęcia rozbudowy modułu.
class ServiceCourseUpgradeValidation {
  const ServiceCourseUpgradeValidation({
    required this.canUpgrade,
    this.reason,
    this.nextLevel,
    this.requiredBudgetEur = 0,
    this.constructionDays = 0,
  });

  final bool canUpgrade;
  final String? reason;
  final int? nextLevel;
  final int requiredBudgetEur;
  final int constructionDays;
}

/// Wynik operacji na bazie Service Course HQ (rozbudowa lub anulowanie).
class ServiceCourseUpgradeResult {
  const ServiceCourseUpgradeResult({
    required this.success,
    required this.state,
    required this.message,
  });

  final bool success;
  final TeamServiceCourseHqState state;
  final String message;
}

/// Pełny stan Bazy Logistycznej Zespołu (Service Course HQ).
class TeamServiceCourseHqState {
  const TeamServiceCourseHqState({
    required this.teamName,
    required this.availableBudgetEur,
    required this.modules,
    this.upgradeHistory = const <ServiceCourseUpgradeEvent>[],
  });

  final String teamName;
  final int availableBudgetEur;
  final Map<ServiceCourseModuleId, ServiceCourseModuleState> modules;
  final List<ServiceCourseUpgradeEvent> upgradeHistory;

  ServiceCourseModuleState moduleState(ServiceCourseModuleId id) {
    return modules[id] ?? ServiceCourseModuleState(moduleId: id);
  }

  ServiceCourseCareerBonuses get bonuses =>
      TeamServiceCourseHqUpgrades.computeCareerBonuses(this);

  int get totalFacilityValueEur => modules.values.fold<int>(
        0,
        (sum, item) => sum + item.totalInvestedEur,
      );

  int get activeConstructionsCount =>
      modules.values.where((m) => m.isUnderConstruction).length;

  int get totalLevelsBuilt =>
      modules.values.fold<int>(0, (sum, m) => sum + m.currentLevel);

  double get averageLevel {
    if (modules.isEmpty) return 0.0;
    return totalLevelsBuilt / ServiceCourseModuleId.values.length;
  }

  TeamServiceCourseHqState copyWith({
    String? teamName,
    int? availableBudgetEur,
    Map<ServiceCourseModuleId, ServiceCourseModuleState>? modules,
    List<ServiceCourseUpgradeEvent>? upgradeHistory,
  }) {
    return TeamServiceCourseHqState(
      teamName: teamName ?? this.teamName,
      availableBudgetEur: availableBudgetEur ?? this.availableBudgetEur,
      modules: modules ?? this.modules,
      upgradeHistory: upgradeHistory ?? this.upgradeHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'teamName': teamName,
      'availableBudgetEur': availableBudgetEur,
      'modules': modules.map(
        (key, value) => MapEntry(key.toJson(), value.toJson()),
      ),
      'upgradeHistory': upgradeHistory.map((e) => e.toJson()).toList(),
    };
  }

  factory TeamServiceCourseHqState.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'] as Map<String, dynamic>? ?? const {};
    final parsedModules = <ServiceCourseModuleId, ServiceCourseModuleState>{};
    for (final id in ServiceCourseModuleId.values) {
      final entry = rawModules[id.toJson()];
      if (entry is Map<String, dynamic>) {
        parsedModules[id] = ServiceCourseModuleState.fromJson(entry);
      } else {
        parsedModules[id] = ServiceCourseModuleState(moduleId: id);
      }
    }
    final rawHistory = json['upgradeHistory'] as List<dynamic>? ?? const [];
    final history = rawHistory
        .whereType<Map<String, dynamic>>()
        .map(ServiceCourseUpgradeEvent.fromJson)
        .toList();
    return TeamServiceCourseHqState(
      teamName: (json['teamName'] as String?) ?? 'Pro Peloton Team',
      availableBudgetEur:
          math.max(0, (json['availableBudgetEur'] as num?)?.toInt() ?? 0),
      modules: parsedModules,
      upgradeHistory: history,
    );
  }
}

/// Serwis zarządzający rozbudową 5 modułów Bazy Logistycznej Zespołu (Service Course HQ).
class TeamServiceCourseHqUpgrades {
  TeamServiceCourseHqUpgrades._();

  static const int maxModuleLevel = 5;

  /// Katalog wszystkich 5 modułów budynków i ich 5 poziomów rozbudowy.
  static const List<ServiceCourseModuleDefinition> catalog =
      <ServiceCourseModuleDefinition>[
    ServiceCourseModuleDefinition(
      id: ServiceCourseModuleId.windTunnel,
      levels: <ServiceCourseModuleLevelSpec>[
        ServiceCourseModuleLevelSpec(
          level: 1,
          tierName: 'Stanowisko Pomiaru Pozycji',
          buildCostEur: 350000,
          annualUpkeepEur: 35000,
          constructionDays: 21,
          primaryBonusLabel: 'Redukcja CdA',
          primaryBonusValue: 0.6,
          secondaryBonusLabel: 'Zniżka testów aero',
          secondaryBonusValue: 10.0,
          description:
              'Podstawowa komora pomiarowa do weryfikacji pozycji czasowych i kąta łokci.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 2,
          tierName: 'Kanał Przepływu Laminarnego',
          buildCostEur: 650000,
          annualUpkeepEur: 65000,
          constructionDays: 28,
          primaryBonusLabel: 'Redukcja CdA',
          primaryBonusValue: 1.2,
          secondaryBonusLabel: 'Zniżka testów aero',
          secondaryBonusValue: 20.0,
          description:
              'Symulacja wiatru bocznego ±15° oraz testy kasków i kombinezonów czasowych.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 3,
          tierName: 'Tunel z Obrotową Platformą Yaw',
          buildCostEur: 1100000,
          annualUpkeepEur: 105000,
          constructionDays: 35,
          primaryBonusLabel: 'Redukcja CdA',
          primaryBonusValue: 1.9,
          secondaryBonusLabel: 'Zniżka testów aero',
          secondaryBonusValue: 30.0,
          description:
              'Dynamiczny pomiar oporu kół karbonowych i ram aero przy zmiennym kącie wiatru.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 4,
          tierName: 'Centrum CFD i Skanowania 3D',
          buildCostEur: 1750000,
          annualUpkeepEur: 160000,
          constructionDays: 45,
          primaryBonusLabel: 'Redukcja CdA',
          primaryBonusValue: 2.7,
          secondaryBonusLabel: 'Zniżka testów aero',
          secondaryBonusValue: 40.0,
          description:
              'Skanowanie laserowe sylwetki każdego kolarza i druk 3D spersonalizowanych kokpitów TT.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 5,
          tierName: 'Kompleks Aero WorldTour Elite',
          buildCostEur: 2600000,
          annualUpkeepEur: 240000,
          constructionDays: 60,
          primaryBonusLabel: 'Redukcja CdA',
          primaryBonusValue: 3.5,
          secondaryBonusLabel: 'Zniżka testów aero',
          secondaryBonusValue: 50.0,
          description:
              'Pełnoskalowy tunel aero klasy F1 dostępny 24/7 dla liderów GC i pociągu sprinterskiego.',
        ),
      ],
    ),
    ServiceCourseModuleDefinition(
      id: ServiceCourseModuleId.hypoxiaCenter,
      levels: <ServiceCourseModuleLevelSpec>[
        ServiceCourseModuleLevelSpec(
          level: 1,
          tierName: 'Namioty Hipoksyjne Bazy',
          buildCostEur: 280000,
          annualUpkeepEur: 28000,
          constructionDays: 18,
          primaryBonusLabel: 'Aklimatyzacja wysokogórska',
          primaryBonusValue: 5.0,
          secondaryBonusLabel: 'Ochrona przed hipoksją >2000m',
          secondaryBonusValue: 6.0,
          description:
              'Przenośne generatory azotu obniżające stężenie tlenu podczas snu kolarzy.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 2,
          tierName: 'Apartamenty Wysokościowe 2500m',
          buildCostEur: 520000,
          annualUpkeepEur: 52000,
          constructionDays: 25,
          primaryBonusLabel: 'Aklimatyzacja wysokogórska',
          primaryBonusValue: 10.0,
          secondaryBonusLabel: 'Ochrona przed hipoksją >2000m',
          secondaryBonusValue: 12.0,
          description:
              'Stałe pokoje niskociśnieniowe przyspieszające produkcję erytropoetyny przed Grand Tourami.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 3,
          tierName: 'Komora Wysiłkowa z Klimatyzacją',
          buildCostEur: 900000,
          annualUpkeepEur: 90000,
          constructionDays: 32,
          primaryBonusLabel: 'Aklimatyzacja wysokogórska',
          primaryBonusValue: 15.0,
          secondaryBonusLabel: 'Ochrona przed hipoksją >2000m',
          secondaryBonusValue: 18.0,
          description:
              'Trenażery w komorze symulującej przełęcze 2800 m n.p.m. oraz upał do 42°C.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 4,
          tierName: 'Laboratorium Hemoglobiny i VO2',
          buildCostEur: 1450000,
          annualUpkeepEur: 140000,
          constructionDays: 42,
          primaryBonusLabel: 'Aklimatyzacja wysokogórska',
          primaryBonusValue: 20.0,
          secondaryBonusLabel: 'Ochrona przed hipoksją >2000m',
          secondaryBonusValue: 24.0,
          description:
              'Precyzyjne monitorowanie masy hemoglobiny i indywidualne okna szczytu formy po zgrupowaniach.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 5,
          tierName: 'Instytut Fizjologii Alpejskiej',
          buildCostEur: 2200000,
          annualUpkeepEur: 210000,
          constructionDays: 55,
          primaryBonusLabel: 'Aklimatyzacja wysokogórska',
          primaryBonusValue: 25.0,
          secondaryBonusLabel: 'Ochrona przed hipoksją >2000m',
          secondaryBonusValue: 30.0,
          description:
              'Kompleks hipoksyjno-termiczny redukujący spadek mocy na najwyższych przełęczach HC.',
        ),
      ],
    ),
    ServiceCourseModuleDefinition(
      id: ServiceCourseModuleId.recoveryBusFleet,
      levels: <ServiceCourseModuleLevelSpec>[
        ServiceCourseModuleLevelSpec(
          level: 1,
          tierName: 'Autobus Zespołowy Standard',
          buildCostEur: 300000,
          annualUpkeepEur: 32000,
          constructionDays: 14,
          primaryBonusLabel: 'Regeneracja po etapie',
          primaryBonusValue: 4.0,
          secondaryBonusLabel: 'Odporność w 3. tyg. GT',
          secondaryBonusValue: 3.0,
          description:
              'Komfortowe fotele z odchylanym oparciem, prysznice i podstawowe koktajle białkowe.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 2,
          tierName: 'Autobus z Kabiną Krio i Masażem',
          buildCostEur: 580000,
          annualUpkeepEur: 60000,
          constructionDays: 22,
          primaryBonusLabel: 'Regeneracja po etapie',
          primaryBonusValue: 8.0,
          secondaryBonusLabel: 'Odporność w 3. tyg. GT',
          secondaryBonusValue: 6.0,
          description:
              'Wbudowane wanny lodowe, systemy kompresji nóg i oddzielne stanowiska fizjoterapeutów.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 3,
          tierName: 'Drugi Autobus i Wóz Kuchenny',
          buildCostEur: 980000,
          annualUpkeepEur: 98000,
          constructionDays: 30,
          primaryBonusLabel: 'Regeneracja po etapie',
          primaryBonusValue: 12.0,
          secondaryBonusLabel: 'Odporność w 3. tyg. GT',
          secondaryBonusValue: 9.0,
          description:
              'Mobilna kuchnia drużynowa z szefem kuchni przygotowującym posiłki o precyzyjnym bilansie węglowodanów.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 4,
          tierName: 'Flota Sypialna i Ciężarówka Serwisowa',
          buildCostEur: 1500000,
          annualUpkeepEur: 145000,
          constructionDays: 40,
          primaryBonusLabel: 'Regeneracja po etapie',
          primaryBonusValue: 16.0,
          secondaryBonusLabel: 'Odporność w 3. tyg. GT',
          secondaryBonusValue: 12.0,
          description:
              'Własne materace z termoregulacją przewożone między hotelami zapewniające idealny sen na GT.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 5,
          tierName: 'Mobilne Centrum Regeneracji WorldTour',
          buildCostEur: 2300000,
          annualUpkeepEur: 220000,
          constructionDays: 50,
          primaryBonusLabel: 'Regeneracja po etapie',
          primaryBonusValue: 20.0,
          secondaryBonusLabel: 'Odporność w 3. tyg. GT',
          secondaryBonusValue: 15.0,
          description:
              'Pełna flota autobusów sypialno-regeneracyjnych z własnym gabinetem USG i krioterapią.',
        ),
      ],
    ),
    ServiceCourseModuleDefinition(
      id: ServiceCourseModuleId.drivetrainWaxWorkshop,
      levels: <ServiceCourseModuleLevelSpec>[
        ServiceCourseModuleLevelSpec(
          level: 1,
          tierName: 'Stanowisko Woskowania na Gorąco',
          buildCostEur: 180000,
          annualUpkeepEur: 18000,
          constructionDays: 14,
          primaryBonusLabel: 'Oszczędność napędu',
          primaryBonusValue: 1.0,
          secondaryBonusLabel: 'Mniejsze zużycie części',
          secondaryBonusValue: 7.0,
          description:
              'Kąpiele parafinowe z dodatkiem PTFE dla podstawowej redukcji tarcia ogniw łańcucha.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 2,
          tierName: 'Myjki Ultradźwiękowe Napędów',
          buildCostEur: 360000,
          annualUpkeepEur: 34000,
          constructionDays: 20,
          primaryBonusLabel: 'Oszczędność napędu',
          primaryBonusValue: 1.8,
          secondaryBonusLabel: 'Mniejsze zużycie części',
          secondaryBonusValue: 14.0,
          description:
              'Głębokie odtłuszczanie nowych łańcuchów przed aplikacją mieszanki woskowej z grafenem.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 3,
          tierName: 'Laboratorium Łożysk Ceramicznych',
          buildCostEur: 620000,
          annualUpkeepEur: 58000,
          constructionDays: 28,
          primaryBonusLabel: 'Oszczędność napędu',
          primaryBonusValue: 2.7,
          secondaryBonusLabel: 'Mniejsze zużycie części',
          secondaryBonusValue: 21.0,
          description:
              'Ręczne pasowanie łożysk suportu, piast i powiększonych wózków przerzutki OSPW.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 4,
          tierName: 'Strefa Czysta i Testy Tarcia',
          buildCostEur: 1050000,
          annualUpkeepEur: 95000,
          constructionDays: 36,
          primaryBonusLabel: 'Oszczędność napędu',
          primaryBonusValue: 3.6,
          secondaryBonusLabel: 'Mniejsze zużycie części',
          secondaryBonusValue: 28.0,
          description:
              'Stanowisko pomiarowe strat mechanicznych dobierające wosk pod deszcz, bruk lub upał.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 5,
          tierName: 'Centrum Nanowosków Pro-Lab',
          buildCostEur: 1650000,
          annualUpkeepEur: 145000,
          constructionDays: 45,
          primaryBonusLabel: 'Oszczędność napędu',
          primaryBonusValue: 4.5,
          secondaryBonusLabel: 'Mniejsze zużycie części',
          secondaryBonusValue: 35.0,
          description:
              'Autorska formuła wosku wolframowo-grafenowego dająca do 4.5 W przewagi na każdym etapie.',
        ),
      ],
    ),
    ServiceCourseModuleDefinition(
      id: ServiceCourseModuleId.scoutingAcademy,
      levels: <ServiceCourseModuleLevelSpec>[
        ServiceCourseModuleLevelSpec(
          level: 1,
          tierName: 'Biuro Analiz i Skautingu',
          buildCostEur: 240000,
          annualUpkeepEur: 24000,
          constructionDays: 16,
          primaryBonusLabel: 'Precyzja skautingu',
          primaryBonusValue: 5.0,
          secondaryBonusLabel: 'Rozwój talentów U23',
          secondaryBonusValue: 3.5,
          description:
              'Cyfrowa baza wyników juniorów i szybsze odkrywanie ukrytych profili mocy.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 2,
          tierName: 'Sieć Obserwatorów U23',
          buildCostEur: 480000,
          annualUpkeepEur: 48000,
          constructionDays: 24,
          primaryBonusLabel: 'Precyzja skautingu',
          primaryBonusValue: 10.0,
          secondaryBonusLabel: 'Rozwój talentów U23',
          secondaryBonusValue: 7.0,
          description:
              'Stali skauci na wyścigach Giro Next Gen, Tour de l\'Avenir i Paris-Roubaix Espoirs.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 3,
          tierName: 'Centrum Szkoleniowe Devo',
          buildCostEur: 850000,
          annualUpkeepEur: 85000,
          constructionDays: 32,
          primaryBonusLabel: 'Precyzja skautingu',
          primaryBonusValue: 15.0,
          secondaryBonusLabel: 'Rozwój talentów U23',
          secondaryBonusValue: 10.5,
          description:
              'Własny kampus dla młodzieżowców z dostępem do dietetyka, trenera mocy i testów mleczanu.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 4,
          tierName: 'Globalna Akademia Talentów',
          buildCostEur: 1400000,
          annualUpkeepEur: 135000,
          constructionDays: 42,
          primaryBonusLabel: 'Precyzja skautingu',
          primaryBonusValue: 20.0,
          secondaryBonusLabel: 'Rozwój talentów U23',
          secondaryBonusValue: 14.0,
          description:
              'Programy stypendialne w Andach, Flandrii i Skandynawii wyławiające przyszłych zwycięzców GT.',
        ),
        ServiceCourseModuleLevelSpec(
          level: 5,
          tierName: 'Kuźnia Mistrzów WorldTour',
          buildCostEur: 2100000,
          annualUpkeepEur: 195000,
          constructionDays: 52,
          primaryBonusLabel: 'Precyzja skautingu',
          primaryBonusValue: 25.0,
          secondaryBonusLabel: 'Rozwój talentów U23',
          secondaryBonusValue: 18.0,
          description:
              'Elitarna akademia skautingowo-rozwojowa gwarantująca najwyższą precyzję oceny potencjału.',
        ),
      ],
    ),
  ];

  static ServiceCourseModuleDefinition definitionFor(
    ServiceCourseModuleId moduleId,
  ) {
    return catalog.firstWhere((item) => item.id == moduleId);
  }

  /// Tworzy początkowy stan Bazy Logistycznej Zespołu.
  static TeamServiceCourseHqState initialState({
    String teamName = 'Apex Cycling WorldTour',
    int availableBudgetEur = 4500000,
    Map<ServiceCourseModuleId, int>? initialLevels,
  }) {
    final modules = <ServiceCourseModuleId, ServiceCourseModuleState>{};
    for (final id in ServiceCourseModuleId.values) {
      final level = (initialLevels?[id] ?? 0).clamp(0, maxModuleLevel);
      var invested = 0;
      final def = definitionFor(id);
      for (var lvl = 1; lvl <= level; lvl++) {
        invested += def.specForLevel(lvl)?.buildCostEur ?? 0;
      }
      modules[id] = ServiceCourseModuleState(
        moduleId: id,
        currentLevel: level,
        totalInvestedEur: invested,
      );
    }
    return TeamServiceCourseHqState(
      teamName: teamName,
      availableBudgetEur: math.max(0, availableBudgetEur),
      modules: modules,
    );
  }

  /// Sprawdza, czy moduł może rozpocząć rozbudowę do kolejnego poziomu.
  static ServiceCourseUpgradeValidation canStartUpgrade(
    TeamServiceCourseHqState state,
    ServiceCourseModuleId moduleId,
  ) {
    final moduleState = state.moduleState(moduleId);
    final definition = definitionFor(moduleId);

    if (moduleState.isUnderConstruction) {
      return const ServiceCourseUpgradeValidation(
        canUpgrade: false,
        reason: 'Rozbudowa tego modułu jest już w toku.',
      );
    }

    if (moduleState.currentLevel >= definition.maxLevel) {
      return const ServiceCourseUpgradeValidation(
        canUpgrade: false,
        reason: 'Osiągnięto maksymalny poziom 5/5.',
      );
    }

    final nextLevel = moduleState.currentLevel + 1;
    final nextSpec = definition.specForLevel(nextLevel);
    if (nextSpec == null) {
      return const ServiceCourseUpgradeValidation(
        canUpgrade: false,
        reason: 'Brak specyfikacji kolejnego poziomu.',
      );
    }

    if (state.availableBudgetEur < nextSpec.buildCostEur) {
      return ServiceCourseUpgradeValidation(
        canUpgrade: false,
        reason:
            'Niewystarczający budżet (wymagane ${Formatters.formatCurrency(nextSpec.buildCostEur)}).',
        nextLevel: nextLevel,
        requiredBudgetEur: nextSpec.buildCostEur,
        constructionDays: nextSpec.constructionDays,
      );
    }

    return ServiceCourseUpgradeValidation(
      canUpgrade: true,
      nextLevel: nextLevel,
      requiredBudgetEur: nextSpec.buildCostEur,
      constructionDays: nextSpec.constructionDays,
    );
  }

  /// Rozpoczyna budowę/rozbudowę wybranego modułu i pobiera koszt z budżetu.
  static ServiceCourseUpgradeResult startUpgrade(
    TeamServiceCourseHqState state,
    ServiceCourseModuleId moduleId, {
    DateTime? currentDate,
  }) {
    final validation = canStartUpgrade(state, moduleId);
    if (!validation.canUpgrade || validation.nextLevel == null) {
      return ServiceCourseUpgradeResult(
        success: false,
        state: state,
        message: validation.reason ?? 'Nie można rozpocząć rozbudowy.',
      );
    }

    final targetLevel = validation.nextLevel!;
    final cost = validation.requiredBudgetEur;
    final days = validation.constructionDays;
    final currentModule = state.moduleState(moduleId);

    final updatedModules =
        Map<ServiceCourseModuleId, ServiceCourseModuleState>.from(state.modules);
    updatedModules[moduleId] = currentModule.copyWith(
      isUnderConstruction: true,
      targetLevel: targetLevel,
      remainingConstructionDays: days,
      totalConstructionDays: days,
      totalInvestedEur: currentModule.totalInvestedEur + cost,
    );

    final timestamp = (currentDate ?? DateTime.now()).toIso8601String();
    final event = ServiceCourseUpgradeEvent(
      moduleId: moduleId,
      fromLevel: currentModule.currentLevel,
      toLevel: targetLevel,
      costEur: cost,
      eventType: 'started',
      timestampIso: timestamp,
      summary:
          'Rozpoczęto budowę ${moduleId.shortTitle} (Poz. $targetLevel) za ${Formatters.formatCurrency(cost)} ($days dni).',
    );

    final nextState = state.copyWith(
      availableBudgetEur: state.availableBudgetEur - cost,
      modules: updatedModules,
      upgradeHistory: <ServiceCourseUpgradeEvent>[
        event,
        ...state.upgradeHistory,
      ],
    );

    return ServiceCourseUpgradeResult(
      success: true,
      state: nextState,
      message: event.summary,
    );
  }

  /// Przesuwa czas trwania wszystkich aktywnych budów o [days] dni kariery.
  static TeamServiceCourseHqState advanceConstructionDays(
    TeamServiceCourseHqState state,
    int days, {
    DateTime? currentDate,
  }) {
    if (days <= 0 || state.activeConstructionsCount == 0) {
      return state;
    }

    final updatedModules =
        Map<ServiceCourseModuleId, ServiceCourseModuleState>.from(state.modules);
    final newEvents = <ServiceCourseUpgradeEvent>[];
    final timestamp = (currentDate ?? DateTime.now()).toIso8601String();

    for (final entry in state.modules.entries) {
      final mod = entry.value;
      if (!mod.isUnderConstruction) continue;

      final remaining = math.max(0, mod.remainingConstructionDays - days);
      if (remaining == 0) {
        final completedLevel =
            (mod.targetLevel ?? (mod.currentLevel + 1)).clamp(1, maxModuleLevel);
        updatedModules[entry.key] = mod.copyWith(
          currentLevel: completedLevel,
          isUnderConstruction: false,
          clearTargetLevel: true,
          remainingConstructionDays: 0,
          totalConstructionDays: 0,
        );
        newEvents.add(
          ServiceCourseUpgradeEvent(
            moduleId: entry.key,
            fromLevel: mod.currentLevel,
            toLevel: completedLevel,
            costEur: 0,
            eventType: 'completed',
            timestampIso: timestamp,
            summary:
                'Ukończono rozbudowę ${entry.key.shortTitle} do poziomu $completedLevel/5.',
          ),
        );
      } else {
        updatedModules[entry.key] = mod.copyWith(
          remainingConstructionDays: remaining,
        );
      }
    }

    return state.copyWith(
      modules: updatedModules,
      upgradeHistory: <ServiceCourseUpgradeEvent>[
        ...newEvents,
        ...state.upgradeHistory,
      ],
    );
  }

  /// Anuluje trwającą budowę modułu ze zwrotem części poniesionych kosztów.
  static ServiceCourseUpgradeResult cancelConstruction(
    TeamServiceCourseHqState state,
    ServiceCourseModuleId moduleId, {
    double refundRatio = 0.5,
    DateTime? currentDate,
  }) {
    final mod = state.moduleState(moduleId);
    if (!mod.isUnderConstruction || mod.targetLevel == null) {
      return ServiceCourseUpgradeResult(
        success: false,
        state: state,
        message: 'Ten moduł nie jest obecnie w trakcie rozbudowy.',
      );
    }

    final clampedRatio = refundRatio.clamp(0.0, 1.0);
    final spec = definitionFor(moduleId).specForLevel(mod.targetLevel!);
    final buildCost = spec?.buildCostEur ?? 0;
    final refundEur = (buildCost * clampedRatio).round();

    final updatedModules =
        Map<ServiceCourseModuleId, ServiceCourseModuleState>.from(state.modules);
    updatedModules[moduleId] = mod.copyWith(
      isUnderConstruction: false,
      clearTargetLevel: true,
      remainingConstructionDays: 0,
      totalConstructionDays: 0,
      totalInvestedEur: math.max(0, mod.totalInvestedEur - buildCost),
    );

    final event = ServiceCourseUpgradeEvent(
      moduleId: moduleId,
      fromLevel: mod.currentLevel,
      toLevel: mod.targetLevel!,
      costEur: -refundEur,
      eventType: 'cancelled',
      timestampIso: (currentDate ?? DateTime.now()).toIso8601String(),
      summary:
          'Anulowano budowę ${moduleId.shortTitle} (Poz. ${mod.targetLevel}). Zwrot: ${Formatters.formatCurrency(refundEur)}.',
    );

    return ServiceCourseUpgradeResult(
      success: true,
      state: state.copyWith(
        availableBudgetEur: state.availableBudgetEur + refundEur,
        modules: updatedModules,
        upgradeHistory: <ServiceCourseUpgradeEvent>[
          event,
          ...state.upgradeHistory,
        ],
      ),
      message: event.summary,
    );
  }

  /// Wylicza zagregowane stałe bonusy kariery na podstawie aktualnych poziomów budynków.
  static ServiceCourseCareerBonuses computeCareerBonuses(
    TeamServiceCourseHqState state,
  ) {
    final windSpec = _activeSpec(state, ServiceCourseModuleId.windTunnel);
    final hypoxiaSpec = _activeSpec(state, ServiceCourseModuleId.hypoxiaCenter);
    final busSpec = _activeSpec(state, ServiceCourseModuleId.recoveryBusFleet);
    final waxSpec =
        _activeSpec(state, ServiceCourseModuleId.drivetrainWaxWorkshop);
    final scoutSpec =
        _activeSpec(state, ServiceCourseModuleId.scoutingAcademy);

    final totalUpkeep = (windSpec?.annualUpkeepEur ?? 0) +
        (hypoxiaSpec?.annualUpkeepEur ?? 0) +
        (busSpec?.annualUpkeepEur ?? 0) +
        (waxSpec?.annualUpkeepEur ?? 0) +
        (scoutSpec?.annualUpkeepEur ?? 0);

    final totalLevels = state.totalLevelsBuilt;
    final maxTotalLevels =
        ServiceCourseModuleId.values.length * maxModuleLevel;
    final prestigeScore =
        ((totalLevels / maxTotalLevels) * 100.0).round().clamp(0, 100);

    final tierLabel = _tierLabelForPrestige(prestigeScore);

    return ServiceCourseCareerBonuses(
      cdaReductionPercent: windSpec?.primaryBonusValue ?? 0.0,
      windTunnelTestCostDiscountPercent: windSpec?.secondaryBonusValue ?? 0.0,
      altitudeAcclimatizationBonusPercent:
          hypoxiaSpec?.primaryBonusValue ?? 0.0,
      hypoxiaPenaltyMitigationPercent: hypoxiaSpec?.secondaryBonusValue ?? 0.0,
      postStageRecoveryBonusPercent: busSpec?.primaryBonusValue ?? 0.0,
      grandTourWeek3ResilienceBonusPercent: busSpec?.secondaryBonusValue ?? 0.0,
      drivetrainWattsSaved: waxSpec?.primaryBonusValue ?? 0.0,
      equipmentWearReductionPercent: waxSpec?.secondaryBonusValue ?? 0.0,
      scoutingAccuracyBonusPercent: scoutSpec?.primaryBonusValue ?? 0.0,
      u23PotentialGrowthBonusPercent: scoutSpec?.secondaryBonusValue ?? 0.0,
      totalAnnualUpkeepEur: totalUpkeep,
      hqPrestigeScore: prestigeScore,
      hqTierLabel: tierLabel,
    );
  }

  /// Miesięczny koszt utrzymania wszystkich aktywnych modułów Service Course HQ.
  static int calculateMonthlyUpkeepEur(TeamServiceCourseHqState state) {
    final annual = computeCareerBonuses(state).totalAnnualUpkeepEur;
    return (annual / 12.0).round();
  }

  static ServiceCourseModuleLevelSpec? _activeSpec(
    TeamServiceCourseHqState state,
    ServiceCourseModuleId id,
  ) {
    final level = state.moduleState(id).currentLevel;
    if (level <= 0) return null;
    return definitionFor(id).specForLevel(level);
  }

  static String _tierLabelForPrestige(int score) {
    if (score >= 85) return 'Super-Team HQ';
    if (score >= 60) return 'Kompleks WorldTour';
    if (score >= 35) return 'Centrum ProTeam';
    if (score >= 12) return 'Baza Kontynentalna';
    return 'Baza Podstawowa';
  }
}

/// Kontroler Riverpod zarządzający stanem Bazy Logistycznej Zespołu.
class TeamServiceCourseHqNotifier
    extends StateNotifier<TeamServiceCourseHqState> {
  TeamServiceCourseHqNotifier({
    TeamServiceCourseHqState? initialState,
  }) : super(initialState ?? TeamServiceCourseHqUpgrades.initialState());

  ServiceCourseUpgradeResult startUpgrade(
    ServiceCourseModuleId moduleId, {
    DateTime? currentDate,
  }) {
    final result = TeamServiceCourseHqUpgrades.startUpgrade(
      state,
      moduleId,
      currentDate: currentDate,
    );
    if (result.success) {
      state = result.state;
    }
    return result;
  }

  void advanceDays(int days, {DateTime? currentDate}) {
    state = TeamServiceCourseHqUpgrades.advanceConstructionDays(
      state,
      days,
      currentDate: currentDate,
    );
  }

  ServiceCourseUpgradeResult cancelConstruction(
    ServiceCourseModuleId moduleId, {
    DateTime? currentDate,
  }) {
    final result = TeamServiceCourseHqUpgrades.cancelConstruction(
      state,
      moduleId,
      currentDate: currentDate,
    );
    if (result.success) {
      state = result.state;
    }
    return result;
  }

  void addBudget(int amountEur) {
    if (amountEur == 0) return;
    state = state.copyWith(
      availableBudgetEur: math.max(0, state.availableBudgetEur + amountEur),
    );
  }

  void loadState(TeamServiceCourseHqState newState) {
    state = newState;
  }
}

final teamServiceCourseHqProvider = StateNotifierProvider<
    TeamServiceCourseHqNotifier, TeamServiceCourseHqState>(
  (ref) => TeamServiceCourseHqNotifier(),
);

/// Responsywny panel UI zarządzania rozbudową Bazy Logistycznej Zespołu (`Service Course HQ`).
class TeamServiceCourseHqPanel extends StatefulWidget {
  const TeamServiceCourseHqPanel({
    super.key,
    this.initialState,
    this.onStateChanged,
  });

  final TeamServiceCourseHqState? initialState;
  final ValueChanged<TeamServiceCourseHqState>? onStateChanged;

  @override
  State<TeamServiceCourseHqPanel> createState() =>
      _TeamServiceCourseHqPanelState();
}

class _TeamServiceCourseHqPanelState extends State<TeamServiceCourseHqPanel> {
  late TeamServiceCourseHqState _state;
  ServiceCourseModuleId _selectedModuleId = ServiceCourseModuleId.windTunnel;
  String? _statusFeedback;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState ?? TeamServiceCourseHqUpgrades.initialState();
  }

  @override
  void didUpdateWidget(covariant TeamServiceCourseHqPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialState != null &&
        widget.initialState != oldWidget.initialState) {
      _state = widget.initialState!;
    }
  }

  void _applyState(
    TeamServiceCourseHqState nextState, {
    String? feedback,
    bool isError = false,
  }) {
    setState(() {
      _state = nextState;
      _statusFeedback = feedback;
      _feedbackIsError = isError;
    });
    widget.onStateChanged?.call(nextState);
  }

  void _handleStartUpgrade(ServiceCourseModuleId moduleId) {
    final result = TeamServiceCourseHqUpgrades.startUpgrade(_state, moduleId);
    _applyState(
      result.state,
      feedback: result.message,
      isError: !result.success,
    );
  }

  void _handleCancelConstruction(ServiceCourseModuleId moduleId) {
    final result =
        TeamServiceCourseHqUpgrades.cancelConstruction(_state, moduleId);
    _applyState(
      result.state,
      feedback: result.message,
      isError: !result.success,
    );
  }

  void _handleAdvanceDays(int days) {
    if (_state.activeConstructionsCount == 0) {
      setState(() {
        _statusFeedback = 'Brak aktywnych budów do przyspieszenia.';
        _feedbackIsError = true;
      });
      return;
    }
    final nextState =
        TeamServiceCourseHqUpgrades.advanceConstructionDays(_state, days);
    _applyState(
      nextState,
      feedback: 'Zasymulowano postęp prac o +$days dni kariery.',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bonuses = _state.bonuses;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 680;
          final isDesktop = width >= 1120;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _HqHeaderBanner(
                  state: _state,
                  bonuses: bonuses,
                  isMobile: isMobile,
                  onAdvance7Days: () => _handleAdvanceDays(7),
                ),
                if (_statusFeedback != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _StatusToastStrip(
                    message: _statusFeedback!,
                    isError: _feedbackIsError,
                    onDismiss: () => setState(() => _statusFeedback = null),
                  ),
                ],
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 7,
                        child: _ModulesGridSection(
                          state: _state,
                          selectedModuleId: _selectedModuleId,
                          crossAxisCount: 2,
                          onSelectModule: (id) =>
                              setState(() => _selectedModuleId = id),
                          onStartUpgrade: _handleStartUpgrade,
                          onCancelConstruction: _handleCancelConstruction,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: <Widget>[
                            _SelectedModuleInspectorCard(
                              state: _state,
                              moduleId: _selectedModuleId,
                              onStartUpgrade: () =>
                                  _handleStartUpgrade(_selectedModuleId),
                              onCancelConstruction: () =>
                                  _handleCancelConstruction(_selectedModuleId),
                            ),
                            const SizedBox(height: 16),
                            _CareerBonusesSummaryCard(bonuses: bonuses),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _ModulesGridSection(
                    state: _state,
                    selectedModuleId: _selectedModuleId,
                    crossAxisCount: isMobile ? 1 : 2,
                    onSelectModule: (id) =>
                        setState(() => _selectedModuleId = id),
                    onStartUpgrade: _handleStartUpgrade,
                    onCancelConstruction: _handleCancelConstruction,
                  ),
                  const SizedBox(height: 16),
                  _SelectedModuleInspectorCard(
                    state: _state,
                    moduleId: _selectedModuleId,
                    onStartUpgrade: () =>
                        _handleStartUpgrade(_selectedModuleId),
                    onCancelConstruction: () =>
                        _handleCancelConstruction(_selectedModuleId),
                  ),
                  const SizedBox(height: 16),
                  _CareerBonusesSummaryCard(bonuses: bonuses),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HqHeaderBanner extends StatelessWidget {
  const _HqHeaderBanner({
    required this.state,
    required this.bonuses,
    required this.isMobile,
    required this.onAdvance7Days,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseCareerBonuses bonuses;
  final bool isMobile;
  final VoidCallback onAdvance7Days;

  @override
  Widget build(BuildContext context) {
    final hasActiveBuild = state.activeConstructionsCount > 0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.goldAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'SERVICE COURSE HQ',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: AppColors.goldAccent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Baza Logistyczna: ${state.teamName}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _HqActionButton(
                label: hasActiveBuild
                    ? 'Symuluj +7 dni (${state.activeConstructionsCount} bud.)'
                    : 'Brak aktywnych budów',
                icon: Icons.fast_forward_rounded,
                enabled: hasActiveBuild,
                accentColor: AppColors.cyanAccent,
                onPressed: onAdvance7Days,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _HeaderMetricPill(
                label: 'Budżet inwestycyjny',
                value: Formatters.formatCurrency(state.availableBudgetEur),
                color: AppColors.statusSuccess,
              ),
              _HeaderMetricPill(
                label: 'Klasa Bazy',
                value: '${bonuses.hqTierLabel} (${bonuses.hqPrestigeScore}/100)',
                color: AppColors.goldAccent,
              ),
              _HeaderMetricPill(
                label: 'Wartość obiektów',
                value: Formatters.formatCurrency(state.totalFacilityValueEur),
                color: AppColors.accentBlue,
              ),
              _HeaderMetricPill(
                label: 'Utrzymanie / mies.',
                value: Formatters.formatCurrency(
                  TeamServiceCourseHqUpgrades.calculateMonthlyUpkeepEur(state),
                ),
                color: AppColors.amberWarning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetricPill extends StatelessWidget {
  const _HeaderMetricPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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

class _StatusToastStrip extends StatelessWidget {
  const _StatusToastStrip({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tone = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: tone,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Zamknij powiadomienie',
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _ModulesGridSection extends StatelessWidget {
  const _ModulesGridSection({
    required this.state,
    required this.selectedModuleId,
    required this.crossAxisCount,
    required this.onSelectModule,
    required this.onStartUpgrade,
    required this.onCancelConstruction,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseModuleId selectedModuleId;
  final int crossAxisCount;
  final ValueChanged<ServiceCourseModuleId> onSelectModule;
  final ValueChanged<ServiceCourseModuleId> onStartUpgrade;
  final ValueChanged<ServiceCourseModuleId> onCancelConstruction;

  @override
  Widget build(BuildContext context) {
    const definitions = TeamServiceCourseHqUpgrades.catalog;

    if (crossAxisCount == 1) {
      return Column(
        children: <Widget>[
          for (var i = 0; i < definitions.length; i++) ...<Widget>[
            _ModuleBuildingCard(
              definition: definitions[i],
              moduleState: state.moduleState(definitions[i].id),
              validation: TeamServiceCourseHqUpgrades.canStartUpgrade(
                state,
                definitions[i].id,
              ),
              isSelected: selectedModuleId == definitions[i].id,
              onSelect: () => onSelectModule(definitions[i].id),
              onStartUpgrade: () => onStartUpgrade(definitions[i].id),
              onCancelConstruction: () =>
                  onCancelConstruction(definitions[i].id),
            ),
            if (i < definitions.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < definitions.length; i += 2) {
      final left = definitions[i];
      final right = i + 1 < definitions.length ? definitions[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _ModuleBuildingCard(
                  definition: left,
                  moduleState: state.moduleState(left.id),
                  validation: TeamServiceCourseHqUpgrades.canStartUpgrade(
                    state,
                    left.id,
                  ),
                  isSelected: selectedModuleId == left.id,
                  onSelect: () => onSelectModule(left.id),
                  onStartUpgrade: () => onStartUpgrade(left.id),
                  onCancelConstruction: () => onCancelConstruction(left.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? _ModuleBuildingCard(
                        definition: right,
                        moduleState: state.moduleState(right.id),
                        validation: TeamServiceCourseHqUpgrades.canStartUpgrade(
                          state,
                          right.id,
                        ),
                        isSelected: selectedModuleId == right.id,
                        onSelect: () => onSelectModule(right.id),
                        onStartUpgrade: () => onStartUpgrade(right.id),
                        onCancelConstruction: () =>
                            onCancelConstruction(right.id),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < definitions.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }
}

class _ModuleBuildingCard extends StatefulWidget {
  const _ModuleBuildingCard({
    required this.definition,
    required this.moduleState,
    required this.validation,
    required this.isSelected,
    required this.onSelect,
    required this.onStartUpgrade,
    required this.onCancelConstruction,
  });

  final ServiceCourseModuleDefinition definition;
  final ServiceCourseModuleState moduleState;
  final ServiceCourseUpgradeValidation validation;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onStartUpgrade;
  final VoidCallback onCancelConstruction;

  @override
  State<_ModuleBuildingCard> createState() => _ModuleBuildingCardState();
}

class _ModuleBuildingCardState extends State<_ModuleBuildingCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.definition.id;
    final accent = id.accentColor;
    final currentLevel = widget.moduleState.currentLevel;
    final nextSpec = currentLevel < widget.definition.maxLevel
        ? widget.definition.specForLevel(currentLevel + 1)
        : null;
    final isUnderConstruction = widget.moduleState.isUnderConstruction;

    final borderColor = widget.isSelected
        ? accent
        : _isFocused
            ? AppColors.goldAccent
            : _isHovered
                ? accent.withValues(alpha: 0.65)
                : const Color(0xFF2A2F3D);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: GestureDetector(
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : _isHovered
                      ? const Color(0xFF1D212B)
                      : AppColors.surface,
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
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(id.icon, color: accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            id.categoryTag,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9,
                              color: accent,
                            ),
                          ),
                          Text(
                            id.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: currentLevel > 0
                            ? accent.withValues(alpha: 0.16)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentLevel > 0
                              ? accent.withValues(alpha: 0.45)
                              : const Color(0xFF2A2F3D),
                        ),
                      ),
                      child: Text(
                        'Poz. $currentLevel/${widget.definition.maxLevel}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: currentLevel > 0
                              ? accent
                              : AppColors.textSecondary,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  id.summary,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _LevelSegmentsBar(
                  currentLevel: currentLevel,
                  maxLevel: widget.definition.maxLevel,
                  targetLevel: widget.moduleState.targetLevel,
                  accentColor: accent,
                ),
                const SizedBox(height: 12),
                if (isUnderConstruction) ...<Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Budowa Poz. ${widget.moduleState.targetLevel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amberWarning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pozostało ${widget.moduleState.remainingConstructionDays} dni',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: widget.moduleState.constructionProgress,
                      minHeight: 7,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.amberWarning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _HqActionButton(
                    label: 'Anuluj budowę (zwrot 50%)',
                    icon: Icons.cancel_outlined,
                    enabled: true,
                    accentColor: AppColors.crimsonAlert,
                    onPressed: widget.onCancelConstruction,
                  ),
                ] else if (nextSpec != null) ...<Widget>[
                  _HqActionButton(
                    label:
                        'Rozbuduj Poz. ${nextSpec.level} • ${Formatters.formatCurrency(nextSpec.buildCostEur)}',
                    icon: Icons.upgrade_rounded,
                    enabled: widget.validation.canUpgrade,
                    accentColor: accent,
                    disabledHint: widget.validation.reason,
                    onPressed: widget.onStartUpgrade,
                  ),
                ] else ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppColors.goldAccent,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Maksymalny poziom WorldTour Elite',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
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

class _LevelSegmentsBar extends StatelessWidget {
  const _LevelSegmentsBar({
    required this.currentLevel,
    required this.maxLevel,
    required this.targetLevel,
    required this.accentColor,
  });

  final int currentLevel;
  final int maxLevel;
  final int? targetLevel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(maxLevel, (index) {
        final levelNum = index + 1;
        final isBuilt = levelNum <= currentLevel;
        final isTarget = targetLevel == levelNum;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index < maxLevel - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isBuilt
                  ? accentColor
                  : isTarget
                      ? AppColors.amberWarning
                      : AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isBuilt
                    ? accentColor
                    : isTarget
                        ? AppColors.amberWarning
                        : const Color(0xFF2A2F3D),
                width: 0.8,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SelectedModuleInspectorCard extends StatelessWidget {
  const _SelectedModuleInspectorCard({
    required this.state,
    required this.moduleId,
    required this.onStartUpgrade,
    required this.onCancelConstruction,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseModuleId moduleId;
  final VoidCallback onStartUpgrade;
  final VoidCallback onCancelConstruction;

  @override
  Widget build(BuildContext context) {
    final definition = TeamServiceCourseHqUpgrades.definitionFor(moduleId);
    final modState = state.moduleState(moduleId);
    final validation =
        TeamServiceCourseHqUpgrades.canStartUpgrade(state, moduleId);
    final accent = moduleId.accentColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(moduleId.icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plan Rozbudowy: ${moduleId.title}',
                  style: const TextStyle(
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
          for (final spec in definition.levels) ...<Widget>[
            _ModuleLevelRoadmapRow(
              spec: spec,
              isBuilt: spec.level <= modState.currentLevel,
              isCurrent: spec.level == modState.currentLevel,
              isUnderConstruction:
                  modState.isUnderConstruction &&
                  modState.targetLevel == spec.level,
              accentColor: accent,
            ),
            if (spec.level < definition.maxLevel) const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          if (modState.isUnderConstruction)
            _HqActionButton(
              label:
                  'Anuluj rozbudowę Poz. ${modState.targetLevel} (zwrot 50%)',
              icon: Icons.cancel_rounded,
              enabled: true,
              accentColor: AppColors.crimsonAlert,
              onPressed: onCancelConstruction,
            )
          else if (modState.currentLevel < definition.maxLevel)
            _HqActionButton(
              label:
                  'Zatwierdź budowę Poz. ${modState.currentLevel + 1} (${validation.constructionDays} dni)',
              icon: Icons.engineering_rounded,
              enabled: validation.canUpgrade,
              accentColor: accent,
              disabledHint: validation.reason,
              onPressed: onStartUpgrade,
            ),
        ],
      ),
    );
  }
}

class _ModuleLevelRoadmapRow extends StatelessWidget {
  const _ModuleLevelRoadmapRow({
    required this.spec,
    required this.isBuilt,
    required this.isCurrent,
    required this.isUnderConstruction,
    required this.accentColor,
  });

  final ServiceCourseModuleLevelSpec spec;
  final bool isBuilt;
  final bool isCurrent;
  final bool isUnderConstruction;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final rowBorder = isUnderConstruction
        ? AppColors.amberWarning
        : isCurrent
            ? accentColor
            : const Color(0xFF2A2F3D);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isBuilt
            ? accentColor.withValues(alpha: 0.08)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Poz. ${spec.level} — ${spec.tierName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isBuilt ? accentColor : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isBuilt
                    ? 'AKTYWNY'
                    : isUnderConstruction
                        ? 'W BUDOWIE'
                        : Formatters.formatCurrency(spec.buildCostEur),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isBuilt
                      ? AppColors.statusSuccess
                      : isUnderConstruction
                          ? AppColors.amberWarning
                          : AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${spec.primaryBonusLabel}: +${spec.primaryBonusValue.toStringAsFixed(1)} | '
            '${spec.secondaryBonusLabel}: +${spec.secondaryBonusValue.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerBonusesSummaryCard extends StatelessWidget {
  const _CareerBonusesSummaryCard({required this.bonuses});

  final ServiceCourseCareerBonuses bonuses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.auto_graph_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aktywne Stałe Bonusy Kariery',
                  maxLines: 1,
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
          _BonusMetricRow(
            label: 'Redukcja oporu aero CdA',
            value: '-${bonuses.cdaReductionPercent.toStringAsFixed(1)}%',
            color: AppColors.cyanAccent,
          ),
          _BonusMetricRow(
            label: 'Aklimatyzacja wysokogórska',
            value:
                '+${bonuses.altitudeAcclimatizationBonusPercent.toStringAsFixed(1)}%',
            color: AppColors.amberWarning,
          ),
          _BonusMetricRow(
            label: 'Regeneracja po etapie',
            value:
                '+${bonuses.postStageRecoveryBonusPercent.toStringAsFixed(1)}%',
            color: AppColors.statusSuccess,
          ),
          _BonusMetricRow(
            label: 'Oszczędność watów (wosk)',
            value: '+${bonuses.drivetrainWattsSaved.toStringAsFixed(1)} W',
            color: AppColors.goldAccent,
          ),
          _BonusMetricRow(
            label: 'Precyzja skautingu / U23',
            value:
                '+${bonuses.scoutingAccuracyBonusPercent.toStringAsFixed(0)}% / +${bonuses.u23PotentialGrowthBonusPercent.toStringAsFixed(1)}%',
            color: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }
}

class _BonusMetricRow extends StatelessWidget {
  const _BonusMetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
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

class _HqActionButton extends StatefulWidget {
  const _HqActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
    this.disabledHint,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;
  final String? disabledHint;

  @override
  State<_HqActionButton> createState() => _HqActionButtonState();
}

class _HqActionButtonState extends State<_HqActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.background
        : _isPressed
            ? widget.accentColor.withValues(alpha: 0.32)
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.24)
                : widget.accentColor.withValues(alpha: 0.16);

    final borderColor = !widget.enabled
        ? const Color(0xFF2A2F3D)
        : _isFocused
            ? AppColors.goldAccent
            : widget.accentColor.withValues(alpha: 0.65);

    final fgColor =
        widget.enabled ? AppColors.textPrimary : AppColors.textSecondary;

    final button = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: widget.enabled
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.enabled
                      ? widget.accentColor
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.enabled && widget.disabledHint != null) {
      return Tooltip(
        message: widget.disabledHint!,
        child: button,
      );
    }
    return button;
  }
}
