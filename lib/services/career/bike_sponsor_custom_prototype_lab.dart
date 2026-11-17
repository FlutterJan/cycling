// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/team/bike_manufacturer_deal.dart';

/// Kategoria tajnego prototypu inżynieryjnego w Skunkworks Lab.
enum SkunkworksPrototypeCategory {
  aeroTtFrame,
  ultralightClimbingChassis,
  cobbleSuspensionCockpit,
  ceramicDrivetrainWax,
  carbonMonocoqueWheelset;

  String toJson() => name;

  static SkunkworksPrototypeCategory fromJson(String value) {
    return SkunkworksPrototypeCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkunkworksPrototypeCategory.aeroTtFrame,
    );
  }

  String get label {
    switch (this) {
      case SkunkworksPrototypeCategory.aeroTtFrame:
        return 'Rama Aero / TT';
      case SkunkworksPrototypeCategory.ultralightClimbingChassis:
        return 'Ultralekka Rama Górska';
      case SkunkworksPrototypeCategory.cobbleSuspensionCockpit:
        return 'Kokpit & Widelec Brukowy';
      case SkunkworksPrototypeCategory.ceramicDrivetrainWax:
        return 'Napęd Ceramiczny PTFE';
      case SkunkworksPrototypeCategory.carbonMonocoqueWheelset:
        return 'Koła Monocoque Aero';
    }
  }

  String get codePrefix {
    switch (this) {
      case SkunkworksPrototypeCategory.aeroTtFrame:
        return 'AERO';
      case SkunkworksPrototypeCategory.ultralightClimbingChassis:
        return 'SL';
      case SkunkworksPrototypeCategory.cobbleSuspensionCockpit:
        return 'PAVE';
      case SkunkworksPrototypeCategory.ceramicDrivetrainWax:
        return 'WATT';
      case SkunkworksPrototypeCategory.carbonMonocoqueWheelset:
        return 'DISC';
    }
  }

  IconData get icon {
    switch (this) {
      case SkunkworksPrototypeCategory.aeroTtFrame:
        return Icons.air_rounded;
      case SkunkworksPrototypeCategory.ultralightClimbingChassis:
        return Icons.landscape_rounded;
      case SkunkworksPrototypeCategory.cobbleSuspensionCockpit:
        return Icons.vibration_rounded;
      case SkunkworksPrototypeCategory.ceramicDrivetrainWax:
        return Icons.settings_suggest_rounded;
      case SkunkworksPrototypeCategory.carbonMonocoqueWheelset:
        return Icons.tire_repair_rounded;
    }
  }
}

/// Ranga kluczowego wyścigu docelowego dla prototypu Skunkworks.
enum SkunkworksTargetRaceTier {
  grandTour,
  monumentClassic,
  worldChampionshipItt,
  olympicGames;

  String toJson() => name;

  static SkunkworksTargetRaceTier fromJson(String value) {
    return SkunkworksTargetRaceTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkunkworksTargetRaceTier.grandTour,
    );
  }

  String get label {
    switch (this) {
      case SkunkworksTargetRaceTier.grandTour:
        return 'Wielki Tour';
      case SkunkworksTargetRaceTier.monumentClassic:
        return 'Monument';
      case SkunkworksTargetRaceTier.worldChampionshipItt:
        return 'MŚ ITT';
      case SkunkworksTargetRaceTier.olympicGames:
        return 'Igrzyska Olimpijskie';
    }
  }

  double get prestigeMultiplier {
    switch (this) {
      case SkunkworksTargetRaceTier.grandTour:
        return 1.35;
      case SkunkworksTargetRaceTier.monumentClassic:
        return 1.25;
      case SkunkworksTargetRaceTier.worldChampionshipItt:
        return 1.30;
      case SkunkworksTargetRaceTier.olympicGames:
        return 1.50;
    }
  }
}

/// Faza cyklu rozwojowego prototypu w tajnym laboratorium.
enum SkunkworksPrototypePhase {
  cadConcept,
  windTunnelTesting,
  secretFieldValidation,
  raceReadyHomologated,
  deployedInRace,
  scrapped;

  String toJson() => name;

  static SkunkworksPrototypePhase fromJson(String value) {
    return SkunkworksPrototypePhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkunkworksPrototypePhase.cadConcept,
    );
  }

  String get label {
    switch (this) {
      case SkunkworksPrototypePhase.cadConcept:
        return 'Koncepcja CAD';
      case SkunkworksPrototypePhase.windTunnelTesting:
        return 'Tunel Aero';
      case SkunkworksPrototypePhase.secretFieldValidation:
        return 'Tajne Testy Szosowe';
      case SkunkworksPrototypePhase.raceReadyHomologated:
        return 'Homologacja UCI OK';
      case SkunkworksPrototypePhase.deployedInRace:
        return 'Wdrożony na Wyścig';
      case SkunkworksPrototypePhase.scrapped:
        return 'Wycofany';
    }
  }

  bool get isActiveDevelopment {
    return this == SkunkworksPrototypePhase.cadConcept ||
        this == SkunkworksPrototypePhase.windTunnelTesting ||
        this == SkunkworksPrototypePhase.secretFieldValidation;
  }

  bool get isRaceUsable {
    return this == SkunkworksPrototypePhase.raceReadyHomologated ||
        this == SkunkworksPrototypePhase.deployedInRace;
  }
}

/// Poziom tajności projektu przed rywalami i prasą.
enum SkunkworksSecrecyLevel {
  topSecret,
  restricted,
  leakedToPress;

  String toJson() => name;

  static SkunkworksSecrecyLevel fromJson(String value) {
    return SkunkworksSecrecyLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SkunkworksSecrecyLevel.topSecret,
    );
  }

  String get label {
    switch (this) {
      case SkunkworksSecrecyLevel.topSecret:
        return 'Ściśle Tajne';
      case SkunkworksSecrecyLevel.restricted:
        return 'Poufne';
      case SkunkworksSecrecyLevel.leakedToPress:
        return 'Wyciek do Prasy';
    }
  }

  Color get color {
    switch (this) {
      case SkunkworksSecrecyLevel.topSecret:
        return AppColors.cyanAccent;
      case SkunkworksSecrecyLevel.restricted:
        return AppColors.amberWarning;
      case SkunkworksSecrecyLevel.leakedToPress:
        return AppColors.crimsonAlert;
    }
  }
}

/// Specyfikacja pojedynczego tajnego prototypu w Skunkworks Lab.
class SkunkworksPrototypeSpec {
  final String id;
  final String codename;
  final String manufacturerId;
  final String manufacturerName;
  final SkunkworksPrototypeCategory category;
  final SkunkworksTargetRaceTier targetRaceTier;
  final String targetRaceName;
  final SkunkworksPrototypePhase phase;
  final SkunkworksSecrecyLevel secrecyLevel;
  final double cdaDeltaPercent;
  final int weightDeltaGrams;
  final double drivetrainWattSavings;
  final double vibrationDampingBonusPercent;
  final double stiffnessToWeightRatio;
  final double failureRiskPercent;
  final double uciComplianceMarginPercent;
  final double developmentProgress;
  final int windTunnelHoursLogged;
  final int windTunnelHoursRequired;
  final int budgetAllocatedEur;
  final int totalCostEur;
  final String assignedLeadRiderId;
  final String assignedLeadRiderName;
  final bool isPrototypeActiveForRace;
  final int cadBlueprintSeed;
  final String engineeringNotes;

  const SkunkworksPrototypeSpec({
    required this.id,
    required this.codename,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.category,
    required this.targetRaceTier,
    required this.targetRaceName,
    required this.phase,
    required this.secrecyLevel,
    required this.cdaDeltaPercent,
    required this.weightDeltaGrams,
    required this.drivetrainWattSavings,
    required this.vibrationDampingBonusPercent,
    required this.stiffnessToWeightRatio,
    required this.failureRiskPercent,
    required this.uciComplianceMarginPercent,
    required this.developmentProgress,
    required this.windTunnelHoursLogged,
    required this.windTunnelHoursRequired,
    required this.budgetAllocatedEur,
    required this.totalCostEur,
    required this.assignedLeadRiderId,
    required this.assignedLeadRiderName,
    required this.isPrototypeActiveForRace,
    required this.cadBlueprintSeed,
    required this.engineeringNotes,
  });

  /// Szacowany łączny zysk mocy przy 45 km/h (aero + napęd + tłumienie).
  double get estimatedWattsSavedAt45Kmh {
    // 45 km/h (~12.5 m/s): typowy opór aero to ~320 W; redukcja CdA o 1% ≈ 3.2 W.
    final double aeroWatts = (-cdaDeltaPercent).clamp(0.0, 15.0) * 3.2;
    final double cobbleWatts =
        vibrationDampingBonusPercent.clamp(0.0, 40.0) * 0.25;
    return aeroWatts + drivetrainWattSavings + cobbleWatts;
  }

  /// Czy prototyp spełnia wymogi homologacji UCI (>= 100%).
  bool get isUciCompliant => uciComplianceMarginPercent >= 100.0;

  /// Czy można wysłać prototyp na homologację UCI.
  bool get canSubmitForUciHomologation =>
      phase == SkunkworksPrototypePhase.secretFieldValidation &&
      developmentProgress >= 0.85;

  SkunkworksPrototypeSpec copyWith({
    String? id,
    String? codename,
    String? manufacturerId,
    String? manufacturerName,
    SkunkworksPrototypeCategory? category,
    SkunkworksTargetRaceTier? targetRaceTier,
    String? targetRaceName,
    SkunkworksPrototypePhase? phase,
    SkunkworksSecrecyLevel? secrecyLevel,
    double? cdaDeltaPercent,
    int? weightDeltaGrams,
    double? drivetrainWattSavings,
    double? vibrationDampingBonusPercent,
    double? stiffnessToWeightRatio,
    double? failureRiskPercent,
    double? uciComplianceMarginPercent,
    double? developmentProgress,
    int? windTunnelHoursLogged,
    int? windTunnelHoursRequired,
    int? budgetAllocatedEur,
    int? totalCostEur,
    String? assignedLeadRiderId,
    String? assignedLeadRiderName,
    bool? isPrototypeActiveForRace,
    int? cadBlueprintSeed,
    String? engineeringNotes,
  }) {
    return SkunkworksPrototypeSpec(
      id: id ?? this.id,
      codename: codename ?? this.codename,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      category: category ?? this.category,
      targetRaceTier: targetRaceTier ?? this.targetRaceTier,
      targetRaceName: targetRaceName ?? this.targetRaceName,
      phase: phase ?? this.phase,
      secrecyLevel: secrecyLevel ?? this.secrecyLevel,
      cdaDeltaPercent: cdaDeltaPercent ?? this.cdaDeltaPercent,
      weightDeltaGrams: weightDeltaGrams ?? this.weightDeltaGrams,
      drivetrainWattSavings:
          drivetrainWattSavings ?? this.drivetrainWattSavings,
      vibrationDampingBonusPercent:
          vibrationDampingBonusPercent ?? this.vibrationDampingBonusPercent,
      stiffnessToWeightRatio:
          stiffnessToWeightRatio ?? this.stiffnessToWeightRatio,
      failureRiskPercent: failureRiskPercent ?? this.failureRiskPercent,
      uciComplianceMarginPercent:
          uciComplianceMarginPercent ?? this.uciComplianceMarginPercent,
      developmentProgress: developmentProgress ?? this.developmentProgress,
      windTunnelHoursLogged:
          windTunnelHoursLogged ?? this.windTunnelHoursLogged,
      windTunnelHoursRequired:
          windTunnelHoursRequired ?? this.windTunnelHoursRequired,
      budgetAllocatedEur: budgetAllocatedEur ?? this.budgetAllocatedEur,
      totalCostEur: totalCostEur ?? this.totalCostEur,
      assignedLeadRiderId: assignedLeadRiderId ?? this.assignedLeadRiderId,
      assignedLeadRiderName:
          assignedLeadRiderName ?? this.assignedLeadRiderName,
      isPrototypeActiveForRace:
          isPrototypeActiveForRace ?? this.isPrototypeActiveForRace,
      cadBlueprintSeed: cadBlueprintSeed ?? this.cadBlueprintSeed,
      engineeringNotes: engineeringNotes ?? this.engineeringNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codename': codename,
      'manufacturerId': manufacturerId,
      'manufacturerName': manufacturerName,
      'category': category.toJson(),
      'targetRaceTier': targetRaceTier.toJson(),
      'targetRaceName': targetRaceName,
      'phase': phase.toJson(),
      'secrecyLevel': secrecyLevel.toJson(),
      'cdaDeltaPercent': cdaDeltaPercent,
      'weightDeltaGrams': weightDeltaGrams,
      'drivetrainWattSavings': drivetrainWattSavings,
      'vibrationDampingBonusPercent': vibrationDampingBonusPercent,
      'stiffnessToWeightRatio': stiffnessToWeightRatio,
      'failureRiskPercent': failureRiskPercent,
      'uciComplianceMarginPercent': uciComplianceMarginPercent,
      'developmentProgress': developmentProgress,
      'windTunnelHoursLogged': windTunnelHoursLogged,
      'windTunnelHoursRequired': windTunnelHoursRequired,
      'budgetAllocatedEur': budgetAllocatedEur,
      'totalCostEur': totalCostEur,
      'assignedLeadRiderId': assignedLeadRiderId,
      'assignedLeadRiderName': assignedLeadRiderName,
      'isPrototypeActiveForRace': isPrototypeActiveForRace,
      'cadBlueprintSeed': cadBlueprintSeed,
      'engineeringNotes': engineeringNotes,
    };
  }

  factory SkunkworksPrototypeSpec.fromJson(Map<String, dynamic> json) {
    return SkunkworksPrototypeSpec(
      id: json['id'] as String,
      codename: json['codename'] as String,
      manufacturerId: json['manufacturerId'] as String,
      manufacturerName: json['manufacturerName'] as String,
      category: SkunkworksPrototypeCategory.fromJson(
        json['category'] as String? ?? 'aeroTtFrame',
      ),
      targetRaceTier: SkunkworksTargetRaceTier.fromJson(
        json['targetRaceTier'] as String? ?? 'grandTour',
      ),
      targetRaceName: json['targetRaceName'] as String? ?? 'Tour de France',
      phase: SkunkworksPrototypePhase.fromJson(
        json['phase'] as String? ?? 'cadConcept',
      ),
      secrecyLevel: SkunkworksSecrecyLevel.fromJson(
        json['secrecyLevel'] as String? ?? 'topSecret',
      ),
      cdaDeltaPercent: (json['cdaDeltaPercent'] as num?)?.toDouble() ?? 0.0,
      weightDeltaGrams: (json['weightDeltaGrams'] as num?)?.toInt() ?? 0,
      drivetrainWattSavings:
          (json['drivetrainWattSavings'] as num?)?.toDouble() ?? 0.0,
      vibrationDampingBonusPercent:
          (json['vibrationDampingBonusPercent'] as num?)?.toDouble() ?? 0.0,
      stiffnessToWeightRatio:
          (json['stiffnessToWeightRatio'] as num?)?.toDouble() ?? 100.0,
      failureRiskPercent:
          (json['failureRiskPercent'] as num?)?.toDouble() ?? 10.0,
      uciComplianceMarginPercent:
          (json['uciComplianceMarginPercent'] as num?)?.toDouble() ?? 100.0,
      developmentProgress:
          (json['developmentProgress'] as num?)?.toDouble() ?? 0.0,
      windTunnelHoursLogged:
          (json['windTunnelHoursLogged'] as num?)?.toInt() ?? 0,
      windTunnelHoursRequired:
          (json['windTunnelHoursRequired'] as num?)?.toInt() ?? 40,
      budgetAllocatedEur:
          (json['budgetAllocatedEur'] as num?)?.toInt() ?? 0,
      totalCostEur: (json['totalCostEur'] as num?)?.toInt() ?? 0,
      assignedLeadRiderId: json['assignedLeadRiderId'] as String? ?? '',
      assignedLeadRiderName: json['assignedLeadRiderName'] as String? ?? '',
      isPrototypeActiveForRace:
          json['isPrototypeActiveForRace'] as bool? ?? false,
      cadBlueprintSeed: (json['cadBlueprintSeed'] as num?)?.toInt() ?? 1,
      engineeringNotes: json['engineeringNotes'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkunkworksPrototypeSpec &&
        other.id == id &&
        other.codename == codename &&
        other.phase == phase &&
        other.secrecyLevel == secrecyLevel &&
        other.developmentProgress == developmentProgress &&
        other.windTunnelHoursLogged == windTunnelHoursLogged &&
        other.isPrototypeActiveForRace == isPrototypeActiveForRace;
  }

  @override
  int get hashCode => Object.hash(
        id,
        codename,
        phase,
        secrecyLevel,
        developmentProgress,
        windTunnelHoursLogged,
        isPrototypeActiveForRace,
      );
}

/// Wpis telemetrii inżynieryjnej w dzienniku Skunkworks Lab.
class SkunkworksLabTelemetryLog {
  final String id;
  final String prototypeId;
  final String timestampLabel;
  final String title;
  final String detail;
  final bool isAlert;

  const SkunkworksLabTelemetryLog({
    required this.id,
    required this.prototypeId,
    required this.timestampLabel,
    required this.title,
    required this.detail,
    this.isAlert = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'prototypeId': prototypeId,
        'timestampLabel': timestampLabel,
        'title': title,
        'detail': detail,
        'isAlert': isAlert,
      };

  factory SkunkworksLabTelemetryLog.fromJson(Map<String, dynamic> json) {
    return SkunkworksLabTelemetryLog(
      id: json['id'] as String,
      prototypeId: json['prototypeId'] as String,
      timestampLabel: json['timestampLabel'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      isAlert: json['isAlert'] as bool? ?? false,
    );
  }
}

/// Wynik wdrożenia prototypu Skunkworks na kluczowy wyścig.
class SkunkworksRaceDeploymentOutcome {
  final String prototypeId;
  final String codename;
  final String targetRaceName;
  final double wattsSavedAt45Kmh;
  final double estimatedTimeGainSeconds;
  final bool mechanicalReliabilityPassed;
  final bool uciInspectionPassed;
  final int sponsorPrestigeDelta;
  final String summaryMessage;

  const SkunkworksRaceDeploymentOutcome({
    required this.prototypeId,
    required this.codename,
    required this.targetRaceName,
    required this.wattsSavedAt45Kmh,
    required this.estimatedTimeGainSeconds,
    required this.mechanicalReliabilityPassed,
    required this.uciInspectionPassed,
    required this.sponsorPrestigeDelta,
    required this.summaryMessage,
  });
}

/// Stan tajnego laboratorium Skunkworks Lab.
class SkunkworksLabState {
  final int labSecurityLevel;
  final String activeManufacturerId;
  final String activeManufacturerName;
  final int manufacturerRndLevel;
  final int availableRndBudgetEur;
  final List<SkunkworksPrototypeSpec> prototypes;
  final String? selectedPrototypeId;
  final List<SkunkworksLabTelemetryLog> telemetryLogs;
  final int completedDeploymentsCount;
  final int leakedProjectsCount;
  final SkunkworksRaceDeploymentOutcome? lastDeploymentOutcome;
  final bool isProcessing;
  final String? lastErrorMessage;

  const SkunkworksLabState({
    required this.labSecurityLevel,
    required this.activeManufacturerId,
    required this.activeManufacturerName,
    required this.manufacturerRndLevel,
    required this.availableRndBudgetEur,
    required this.prototypes,
    this.selectedPrototypeId,
    required this.telemetryLogs,
    this.completedDeploymentsCount = 0,
    this.leakedProjectsCount = 0,
    this.lastDeploymentOutcome,
    this.isProcessing = false,
    this.lastErrorMessage,
  });

  SkunkworksPrototypeSpec? get selectedPrototype {
    if (prototypes.isEmpty) return null;
    if (selectedPrototypeId == null) return prototypes.first;
    return prototypes.firstWhere(
      (p) => p.id == selectedPrototypeId,
      orElse: () => prototypes.first,
    );
  }

  int get activePrototypesCount => prototypes
      .where((p) => p.phase != SkunkworksPrototypePhase.scrapped)
      .length;

  int get raceReadyCount =>
      prototypes.where((p) => p.phase.isRaceUsable).length;

  SkunkworksLabState copyWith({
    int? labSecurityLevel,
    String? activeManufacturerId,
    String? activeManufacturerName,
    int? manufacturerRndLevel,
    int? availableRndBudgetEur,
    List<SkunkworksPrototypeSpec>? prototypes,
    String? selectedPrototypeId,
    List<SkunkworksLabTelemetryLog>? telemetryLogs,
    int? completedDeploymentsCount,
    int? leakedProjectsCount,
    SkunkworksRaceDeploymentOutcome? lastDeploymentOutcome,
    bool clearDeploymentOutcome = false,
    bool? isProcessing,
    String? lastErrorMessage,
    bool clearError = false,
  }) {
    return SkunkworksLabState(
      labSecurityLevel: labSecurityLevel ?? this.labSecurityLevel,
      activeManufacturerId: activeManufacturerId ?? this.activeManufacturerId,
      activeManufacturerName:
          activeManufacturerName ?? this.activeManufacturerName,
      manufacturerRndLevel: manufacturerRndLevel ?? this.manufacturerRndLevel,
      availableRndBudgetEur:
          availableRndBudgetEur ?? this.availableRndBudgetEur,
      prototypes: prototypes != null
          ? List<SkunkworksPrototypeSpec>.unmodifiable(prototypes)
          : this.prototypes,
      selectedPrototypeId: selectedPrototypeId ?? this.selectedPrototypeId,
      telemetryLogs: telemetryLogs != null
          ? List<SkunkworksLabTelemetryLog>.unmodifiable(telemetryLogs)
          : this.telemetryLogs,
      completedDeploymentsCount:
          completedDeploymentsCount ?? this.completedDeploymentsCount,
      leakedProjectsCount: leakedProjectsCount ?? this.leakedProjectsCount,
      lastDeploymentOutcome: clearDeploymentOutcome
          ? null
          : (lastDeploymentOutcome ?? this.lastDeploymentOutcome),
      isProcessing: isProcessing ?? this.isProcessing,
      lastErrorMessage:
          clearError ? null : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }
}

/// Serwis domenowy tajnego laboratorium prototypów Skunkworks Lab.
class BikeSponsorCustomPrototypeLabService {
  const BikeSponsorCustomPrototypeLabService();

  static const int windTunnelSessionCostEur = 35000;
  static const int fieldValidationCostEur = 25000;
  static const int uciHomologationCostEur = 18000;
  static const int securityUpgradeBaseCostEur = 90000;

  /// Tworzy początkowy zestaw prototypów dla aktywnej umowy z producentem.
  SkunkworksLabState createInitialState({
    BikeManufacturerDeal? deal,
    int initialBudgetEur = 680000,
    int labSecurityLevel = 2,
  }) {
    final String mId = deal?.manufacturerId ?? 'veloce_works';
    final String mName = deal?.manufacturerName ?? 'Veloce Works R&D';
    final int rndLevel = (deal?.researchAndDevelopmentLevel ?? 82).clamp(1, 100);

    final p1 = SkunkworksPrototypeSpec(
      id: 'skunk_aero_tdf_01',
      codename: 'Project Kestrel-X',
      manufacturerId: mId,
      manufacturerName: mName,
      category: SkunkworksPrototypeCategory.aeroTtFrame,
      targetRaceTier: SkunkworksTargetRaceTier.grandTour,
      targetRaceName: 'Tour de France — Etap 21 ITT',
      phase: SkunkworksPrototypePhase.windTunnelTesting,
      secrecyLevel: SkunkworksSecrecyLevel.topSecret,
      cdaDeltaPercent: -3.4,
      weightDeltaGrams: -110,
      drivetrainWattSavings: 1.8,
      vibrationDampingBonusPercent: 4.0,
      stiffnessToWeightRatio: 118.4,
      failureRiskPercent: 8.5,
      uciComplianceMarginPercent: 98.2,
      developmentProgress: 0.45,
      windTunnelHoursLogged: 18,
      windTunnelHoursRequired: 40,
      budgetAllocatedEur: 185000,
      totalCostEur: 240000,
      assignedLeadRiderId: 'rider_leader_gc',
      assignedLeadRiderName: 'Lider GC #1',
      isPrototypeActiveForRace: false,
      cadBlueprintSeed: 4091,
      engineeringNotes:
          'Profil rury podsiodłowej Kamm-tail 8:1 z ukrytą komorą widelca.',
    );

    final p2 = SkunkworksPrototypeSpec(
      id: 'skunk_pave_roubaix_02',
      codename: 'Pavé-Damp Mk.IV',
      manufacturerId: mId,
      manufacturerName: mName,
      category: SkunkworksPrototypeCategory.cobbleSuspensionCockpit,
      targetRaceTier: SkunkworksTargetRaceTier.monumentClassic,
      targetRaceName: 'Paris-Roubaix',
      phase: SkunkworksPrototypePhase.secretFieldValidation,
      secrecyLevel: SkunkworksSecrecyLevel.restricted,
      cdaDeltaPercent: -1.1,
      weightDeltaGrams: 65,
      drivetrainWattSavings: 1.2,
      vibrationDampingBonusPercent: 24.5,
      stiffnessToWeightRatio: 109.0,
      failureRiskPercent: 5.0,
      uciComplianceMarginPercent: 102.5,
      developmentProgress: 0.88,
      windTunnelHoursLogged: 28,
      windTunnelHoursRequired: 30,
      budgetAllocatedEur: 140000,
      totalCostEur: 165000,
      assignedLeadRiderId: 'rider_cobble_captain',
      assignedLeadRiderName: 'Kapitan Klasyków',
      isPrototypeActiveForRace: false,
      cadBlueprintSeed: 7723,
      engineeringNotes:
          'Elastomerowy tłumik osi sterowej 12 mm testowany nocą na Arenbergu.',
    );

    final logs = <SkunkworksLabTelemetryLog>[
      SkunkworksLabTelemetryLog(
        id: 'log_init_1',
        prototypeId: p1.id,
        timestampLabel: 'T-14d',
        title: 'Sesja CFD #4 zakończona',
        detail:
            'Kestrel-X osiągnął -3.4% CdA przy kącie natarcia wiatru 7.5°.',
      ),
      SkunkworksLabTelemetryLog(
        id: 'log_init_2',
        prototypeId: p2.id,
        timestampLabel: 'T-3d',
        title: 'Nocny przejazd Arenberg',
        detail:
            'Redukcja drgań kierownicy o 24.5% przy ciśnieniu 3.6 bar bez utraty sztywności.',
      ),
    ];

    return SkunkworksLabState(
      labSecurityLevel: labSecurityLevel.clamp(1, 5),
      activeManufacturerId: mId,
      activeManufacturerName: mName,
      manufacturerRndLevel: rndLevel,
      availableRndBudgetEur: initialBudgetEur,
      prototypes: List<SkunkworksPrototypeSpec>.unmodifiable([p1, p2]),
      selectedPrototypeId: p1.id,
      telemetryLogs: List<SkunkworksLabTelemetryLog>.unmodifiable(logs),
    );
  }

  /// Zleca nowy tajny projekt prototypu dla wybranego wyścigu.
  SkunkworksLabState commissionPrototype({
    required SkunkworksLabState state,
    required String codename,
    required SkunkworksPrototypeCategory category,
    required SkunkworksTargetRaceTier targetRaceTier,
    required String targetRaceName,
    required String leadRiderId,
    required String leadRiderName,
    int seed = 1337,
  }) {
    final trimmedName = codename.trim();
    if (trimmedName.isEmpty) {
      return state.copyWith(
        lastErrorMessage: 'Podaj kryptonim nowego prototypu.',
      );
    }

    final int setupCost = _commissionCostFor(category, targetRaceTier);
    if (state.availableRndBudgetEur < setupCost) {
      return state.copyWith(
        lastErrorMessage:
            'Niewystarczający budżet R&D (wymagane ${Formatters.formatCurrency(setupCost)}).',
      );
    }

    final rng = math.Random(seed ^ trimmedName.hashCode);
    final double rndFactor = 0.85 + (state.manufacturerRndLevel / 100.0) * 0.35;

    final double baseCda = switch (category) {
      SkunkworksPrototypeCategory.aeroTtFrame => -2.8 * rndFactor,
      SkunkworksPrototypeCategory.carbonMonocoqueWheelset => -2.1 * rndFactor,
      SkunkworksPrototypeCategory.cobbleSuspensionCockpit => -0.8 * rndFactor,
      SkunkworksPrototypeCategory.ultralightClimbingChassis => -0.6 * rndFactor,
      SkunkworksPrototypeCategory.ceramicDrivetrainWax => -0.2 * rndFactor,
    };

    final int baseWeight = switch (category) {
      SkunkworksPrototypeCategory.ultralightClimbingChassis =>
        (-280 * rndFactor).round(),
      SkunkworksPrototypeCategory.carbonMonocoqueWheelset =>
        (-130 * rndFactor).round(),
      SkunkworksPrototypeCategory.aeroTtFrame => (-75 * rndFactor).round(),
      SkunkworksPrototypeCategory.ceramicDrivetrainWax => -18,
      SkunkworksPrototypeCategory.cobbleSuspensionCockpit => 45,
    };

    final double baseWatts = switch (category) {
      SkunkworksPrototypeCategory.ceramicDrivetrainWax => 5.6 * rndFactor,
      SkunkworksPrototypeCategory.carbonMonocoqueWheelset => 2.4 * rndFactor,
      SkunkworksPrototypeCategory.aeroTtFrame => 1.5 * rndFactor,
      SkunkworksPrototypeCategory.ultralightClimbingChassis => 0.8,
      SkunkworksPrototypeCategory.cobbleSuspensionCockpit => 1.1,
    };

    final double baseDamping = switch (category) {
      SkunkworksPrototypeCategory.cobbleSuspensionCockpit => 21.0 * rndFactor,
      SkunkworksPrototypeCategory.carbonMonocoqueWheelset => 7.5,
      _ => 3.5,
    };

    final String id =
        'skunk_${category.codePrefix.toLowerCase()}_${state.prototypes.length + 1}_${rng.nextInt(900) + 100}';

    final newProto = SkunkworksPrototypeSpec(
      id: id,
      codename: trimmedName,
      manufacturerId: state.activeManufacturerId,
      manufacturerName: state.activeManufacturerName,
      category: category,
      targetRaceTier: targetRaceTier,
      targetRaceName: targetRaceName.trim().isEmpty
          ? targetRaceTier.label
          : targetRaceName.trim(),
      phase: SkunkworksPrototypePhase.cadConcept,
      secrecyLevel: SkunkworksSecrecyLevel.topSecret,
      cdaDeltaPercent: double.parse(baseCda.toStringAsFixed(2)),
      weightDeltaGrams: baseWeight,
      drivetrainWattSavings: double.parse(baseWatts.toStringAsFixed(2)),
      vibrationDampingBonusPercent: double.parse(baseDamping.toStringAsFixed(1)),
      stiffnessToWeightRatio:
          double.parse((106.0 + rng.nextDouble() * 14.0).toStringAsFixed(1)),
      failureRiskPercent: 14.0,
      uciComplianceMarginPercent:
          category == SkunkworksPrototypeCategory.aeroTtFrame ? 96.5 : 101.0,
      developmentProgress: 0.12,
      windTunnelHoursLogged: 0,
      windTunnelHoursRequired: 36,
      budgetAllocatedEur: setupCost,
      totalCostEur: setupCost + 110000,
      assignedLeadRiderId: leadRiderId,
      assignedLeadRiderName: leadRiderName,
      isPrototypeActiveForRace: false,
      cadBlueprintSeed: 1000 + rng.nextInt(8999),
      engineeringNotes:
          'Projekt zlecony dla $targetRaceName przez ${state.activeManufacturerName}.',
    );

    final log = SkunkworksLabTelemetryLog(
      id: 'log_${DateTime.now().microsecondsSinceEpoch}',
      prototypeId: newProto.id,
      timestampLabel: 'TERAZ',
      title: 'Otwarto projekt ${newProto.codename}',
      detail:
          'Alokacja ${Formatters.formatCurrency(setupCost)} na geometrię CAD (${category.label}).',
    );

    return state.copyWith(
      availableRndBudgetEur: state.availableRndBudgetEur - setupCost,
      prototypes: [...state.prototypes, newProto],
      selectedPrototypeId: newProto.id,
      telemetryLogs: [log, ...state.telemetryLogs].take(30).toList(),
      clearError: true,
    );
  }

  /// Przeprowadza sesję w tunelu aerodynamicznym lub komorze testowej.
  SkunkworksLabState runWindTunnelSession({
    required SkunkworksLabState state,
    required String prototypeId,
    int hours = 10,
    int seed = 42,
  }) {
    final idx = state.prototypes.indexWhere((p) => p.id == prototypeId);
    if (idx < 0) {
      return state.copyWith(lastErrorMessage: 'Nie znaleziono prototypu.');
    }

    final proto = state.prototypes[idx];
    if (!proto.phase.isActiveDevelopment) {
      return state.copyWith(
        lastErrorMessage:
            'Prototyp ${proto.codename} nie znajduje się już w fazie testów.',
      );
    }

    if (state.availableRndBudgetEur < windTunnelSessionCostEur) {
      return state.copyWith(
        lastErrorMessage:
            'Brak środków na sesję w tunelu aero (${Formatters.formatCurrency(windTunnelSessionCostEur)}).',
      );
    }

    final rng = math.Random(seed ^ proto.windTunnelHoursLogged);
    final double rndBoost = 0.9 + (state.manufacturerRndLevel / 100.0) * 0.3;
    final int newHours = proto.windTunnelHoursLogged + hours;
    final double progressGain = (hours / proto.windTunnelHoursRequired) * 0.65;
    final double newProgress =
        (proto.developmentProgress + progressGain).clamp(0.0, 0.92);

    final double extraCda = proto.category ==
                SkunkworksPrototypeCategory.aeroTtFrame ||
            proto.category == SkunkworksPrototypeCategory.carbonMonocoqueWheelset
        ? -0.28 * rndBoost
        : -0.08 * rndBoost;
    final double extraWatts =
        proto.category == SkunkworksPrototypeCategory.ceramicDrivetrainWax
            ? 0.55 * rndBoost
            : 0.15;
    final double newRisk =
        (proto.failureRiskPercent - (2.4 + rng.nextDouble() * 1.2))
            .clamp(1.2, 25.0);

    final SkunkworksPrototypePhase nextPhase =
        proto.phase == SkunkworksPrototypePhase.cadConcept
            ? SkunkworksPrototypePhase.windTunnelTesting
            : proto.phase;

    final updated = proto.copyWith(
      phase: nextPhase,
      windTunnelHoursLogged: newHours,
      developmentProgress: double.parse(newProgress.toStringAsFixed(2)),
      cdaDeltaPercent: double.parse(
        (proto.cdaDeltaPercent + extraCda).toStringAsFixed(2),
      ),
      drivetrainWattSavings: double.parse(
        (proto.drivetrainWattSavings + extraWatts).toStringAsFixed(2),
      ),
      failureRiskPercent: double.parse(newRisk.toStringAsFixed(1)),
      budgetAllocatedEur:
          proto.budgetAllocatedEur + windTunnelSessionCostEur,
    );

    final updatedList = [...state.prototypes]..[idx] = updated;
    final log = SkunkworksLabTelemetryLog(
      id: 'log_wt_${updated.id}_$newHours',
      prototypeId: updated.id,
      timestampLabel: 'TUNEL +${hours}h',
      title: 'Optymalizacja CFD ${updated.codename}',
      detail:
          'CdA: ${updated.cdaDeltaPercent.toStringAsFixed(2)}% | Oszczędność przy 45 km/h: ${updated.estimatedWattsSavedAt45Kmh.toStringAsFixed(1)} W.',
    );

    return state.copyWith(
      availableRndBudgetEur:
          state.availableRndBudgetEur - windTunnelSessionCostEur,
      prototypes: updatedList,
      telemetryLogs: [log, ...state.telemetryLogs].take(30).toList(),
      clearError: true,
    );
  }

  /// Przeprowadza nocne tajne testy szosowe z udziałem lidera drużyny.
  SkunkworksLabState runSecretFieldTest({
    required SkunkworksLabState state,
    required String prototypeId,
    int seed = 99,
  }) {
    final idx = state.prototypes.indexWhere((p) => p.id == prototypeId);
    if (idx < 0) {
      return state.copyWith(lastErrorMessage: 'Nie znaleziono prototypu.');
    }

    final proto = state.prototypes[idx];
    if (!proto.phase.isActiveDevelopment) {
      return state.copyWith(
        lastErrorMessage: 'Prototyp jest już poza fazą testów szosowych.',
      );
    }

    if (state.availableRndBudgetEur < fieldValidationCostEur) {
      return state.copyWith(
        lastErrorMessage:
            'Brak budżetu na tajne testy szosowe (${Formatters.formatCurrency(fieldValidationCostEur)}).',
      );
    }

    final rng = math.Random(seed ^ proto.cadBlueprintSeed);
    // Ryzyko wycieku zależy od poziomu bezpieczeństwa laboratorium.
    final double leakProbability =
        (0.28 - (state.labSecurityLevel * 0.05)).clamp(0.03, 0.30);
    final bool leaked = rng.nextDouble() < leakProbability &&
        proto.secrecyLevel != SkunkworksSecrecyLevel.leakedToPress;

    final double newProgress =
        (proto.developmentProgress + 0.30).clamp(0.0, 1.0);
    final double newRisk = (proto.failureRiskPercent - 2.8).clamp(0.8, 25.0);
    final double newUciMargin =
        (proto.uciComplianceMarginPercent + 2.5).clamp(90.0, 108.0);

    final updated = proto.copyWith(
      phase: SkunkworksPrototypePhase.secretFieldValidation,
      secrecyLevel:
          leaked ? SkunkworksSecrecyLevel.leakedToPress : proto.secrecyLevel,
      developmentProgress: double.parse(newProgress.toStringAsFixed(2)),
      failureRiskPercent: double.parse(newRisk.toStringAsFixed(1)),
      uciComplianceMarginPercent: double.parse(newUciMargin.toStringAsFixed(1)),
      budgetAllocatedEur: proto.budgetAllocatedEur + fieldValidationCostEur,
    );

    final updatedList = [...state.prototypes]..[idx] = updated;
    final log = SkunkworksLabTelemetryLog(
      id: 'log_field_${updated.id}_${updated.budgetAllocatedEur}',
      prototypeId: updated.id,
      timestampLabel: 'SZOSA',
      title: leaked
          ? 'ALERT: Zdjęcia szpiegowskie ${updated.codename}!'
          : 'Tajny test szosowy ${updated.codename}',
      detail: leaked
          ? 'Paparazzi sfotografowali prototyp na treningu. Rywale analizują projekt!'
          : 'Walidacja z ${updated.assignedLeadRiderName}: ryzyko awarii spadło do ${updated.failureRiskPercent.toStringAsFixed(1)}%.',
      isAlert: leaked,
    );

    return state.copyWith(
      availableRndBudgetEur:
          state.availableRndBudgetEur - fieldValidationCostEur,
      prototypes: updatedList,
      leakedProjectsCount:
          leaked ? state.leakedProjectsCount + 1 : state.leakedProjectsCount,
      telemetryLogs: [log, ...state.telemetryLogs].take(30).toList(),
      clearError: true,
    );
  }

  /// Zgłasza prototyp do homologacji UCI (wymagane min. 85% postępu).
  SkunkworksLabState submitUciHomologation({
    required SkunkworksLabState state,
    required String prototypeId,
  }) {
    final idx = state.prototypes.indexWhere((p) => p.id == prototypeId);
    if (idx < 0) {
      return state.copyWith(lastErrorMessage: 'Nie znaleziono prototypu.');
    }

    final proto = state.prototypes[idx];
    if (proto.developmentProgress < 0.85) {
      return state.copyWith(
        lastErrorMessage:
            'Homologacja UCI wymaga minimum 85% ukończenia prac rozwojowych.',
      );
    }
    if (state.availableRndBudgetEur < uciHomologationCostEur) {
      return state.copyWith(
        lastErrorMessage:
            'Brak środków na certyfikację UCI (${Formatters.formatCurrency(uciHomologationCostEur)}).',
      );
    }

    final double tunedUciMargin = math.max(proto.uciComplianceMarginPercent, 100.5);
    final updated = proto.copyWith(
      phase: SkunkworksPrototypePhase.raceReadyHomologated,
      developmentProgress: 1.0,
      uciComplianceMarginPercent: double.parse(tunedUciMargin.toStringAsFixed(1)),
      budgetAllocatedEur: proto.budgetAllocatedEur + uciHomologationCostEur,
    );

    final updatedList = [...state.prototypes]..[idx] = updated;
    final log = SkunkworksLabTelemetryLog(
      id: 'log_uci_${updated.id}',
      prototypeId: updated.id,
      timestampLabel: 'UCI OK',
      title: 'Naklejka homologacyjna UCI przyznana',
      detail:
          '${updated.codename} zatwierdzony do startu w ${updated.targetRaceName}.',
    );

    return state.copyWith(
      availableRndBudgetEur:
          state.availableRndBudgetEur - uciHomologationCostEur,
      prototypes: updatedList,
      telemetryLogs: [log, ...state.telemetryLogs].take(30).toList(),
      clearError: true,
    );
  }

  /// Wdraża zatwierdzony prototyp na kluczowy wyścig i wylicza zysk czasowy.
  SkunkworksLabState deployForKeyRace({
    required SkunkworksLabState state,
    required String prototypeId,
    int seed = 2026,
  }) {
    final idx = state.prototypes.indexWhere((p) => p.id == prototypeId);
    if (idx < 0) {
      return state.copyWith(lastErrorMessage: 'Nie znaleziono prototypu.');
    }

    final proto = state.prototypes[idx];
    if (proto.phase != SkunkworksPrototypePhase.raceReadyHomologated &&
        proto.phase != SkunkworksPrototypePhase.deployedInRace) {
      return state.copyWith(
        lastErrorMessage:
            'Najpierw ukończ testy i uzyskaj homologację UCI dla ${proto.codename}.',
      );
    }

    final rng = math.Random(seed ^ proto.cadBlueprintSeed);
    final bool reliabilityPassed =
        (rng.nextDouble() * 100.0) >= proto.failureRiskPercent;
    final bool uciPassed = proto.isUciCompliant;

    final double wattsSaved = proto.estimatedWattsSavedAt45Kmh;
    // Zysk czasowy: ok. 2.1 s na 1 W na dystansie 40 km ITT / kluczowego finału.
    final double timeGain = reliabilityPassed
        ? double.parse((wattsSaved * 2.15).toStringAsFixed(1))
        : 0.0;

    final int prestigeDelta = reliabilityPassed && uciPassed
        ? (12 * proto.targetRaceTier.prestigeMultiplier).round()
        : -6;

    final outcome = SkunkworksRaceDeploymentOutcome(
      prototypeId: proto.id,
      codename: proto.codename,
      targetRaceName: proto.targetRaceName,
      wattsSavedAt45Kmh: double.parse(wattsSaved.toStringAsFixed(1)),
      estimatedTimeGainSeconds: timeGain,
      mechanicalReliabilityPassed: reliabilityPassed,
      uciInspectionPassed: uciPassed,
      sponsorPrestigeDelta: prestigeDelta,
      summaryMessage: reliabilityPassed
          ? '${proto.codename} przyniósł +${wattsSaved.toStringAsFixed(1)} W oszczędności (~${timeGain.toStringAsFixed(1)} s zysku) w ${proto.targetRaceName}.'
          : 'Mikropęknięcie osłony podczas wyścigu zniwelowało zysk prototypu ${proto.codename}.',
    );

    final updated = proto.copyWith(
      phase: SkunkworksPrototypePhase.deployedInRace,
      isPrototypeActiveForRace: true,
    );
    final updatedList = [...state.prototypes]..[idx] = updated;

    final log = SkunkworksLabTelemetryLog(
      id: 'log_deploy_${updated.id}_${state.completedDeploymentsCount}',
      prototypeId: updated.id,
      timestampLabel: 'WYŚCIG',
      title: 'Wdrożenie: ${updated.codename}',
      detail: outcome.summaryMessage,
      isAlert: !reliabilityPassed,
    );

    return state.copyWith(
      prototypes: updatedList,
      completedDeploymentsCount: state.completedDeploymentsCount + 1,
      lastDeploymentOutcome: outcome,
      telemetryLogs: [log, ...state.telemetryLogs].take(30).toList(),
      clearError: true,
    );
  }

  /// Podnosi poziom bezpieczeństwa i kontrwywiadu Skunkworks Lab (poziom 1-5).
  SkunkworksLabState upgradeLabSecurity(SkunkworksLabState state) {
    if (state.labSecurityLevel >= 5) {
      return state.copyWith(
        lastErrorMessage: 'Laboratorium osiągnęło maksymalny poziom tajności (5/5).',
      );
    }

    final int cost = securityUpgradeBaseCostEur * state.labSecurityLevel;
    if (state.availableRndBudgetEur < cost) {
      return state.copyWith(
        lastErrorMessage:
            'Brak środków na rozbudowę zabezpieczeń (${Formatters.formatCurrency(cost)}).',
      );
    }

    final int nextLevel = state.labSecurityLevel + 1;
    final log = SkunkworksLabTelemetryLog(
      id: 'log_sec_$nextLevel',
      prototypeId: state.selectedPrototypeId ?? 'lab',
      timestampLabel: 'OCHRONA',
      title: 'Poziom Tajności podniesiony do $nextLevel/5',
      detail: 'Zainstalowano ekrany akustyczne i prywatną strefę testową.',
    );

    return state.copyWith(
      labSecurityLevel: nextLevel,
      availableRndBudgetEur: state.availableRndBudgetEur - cost,
      telemetryLogs: [log, ...state.telemetryLogs].take(30).toList(),
      clearError: true,
    );
  }

  /// Wycofuje prototyp z dalszego rozwoju.
  SkunkworksLabState scrapPrototype({
    required SkunkworksLabState state,
    required String prototypeId,
  }) {
    final idx = state.prototypes.indexWhere((p) => p.id == prototypeId);
    if (idx < 0) return state;

    final proto = state.prototypes[idx];
    final updated = proto.copyWith(
      phase: SkunkworksPrototypePhase.scrapped,
      isPrototypeActiveForRace: false,
    );
    final updatedList = [...state.prototypes]..[idx] = updated;

    final log = SkunkworksLabTelemetryLog(
      id: 'log_scrap_${updated.id}',
      prototypeId: updated.id,
      timestampLabel: 'ARCHIWUM',
      title: 'Zdekomisjowano ${updated.codename}',
      detail: 'Dokumentacja CAD została zarchiwizowana w sejfie R&D.',
    );

    return state.copyWith(
      prototypes: updatedList,
      telemetryLogs: [log, ...state.telemetryLogs].take(30).toList(),
      clearError: true,
    );
  }
}

/// Notifier Riverpod zarządzający stanem Skunkworks Lab.
class SkunkworksLabNotifier extends StateNotifier<SkunkworksLabState> {
  final BikeSponsorCustomPrototypeLabService _service;

  SkunkworksLabNotifier({
    BikeSponsorCustomPrototypeLabService service =
        const BikeSponsorCustomPrototypeLabService(),
    BikeManufacturerDeal? deal,
  })  : _service = service,
        super(service.createInitialState(deal: deal));

  void selectPrototype(String prototypeId) {
    state = state.copyWith(
      selectedPrototypeId: prototypeId,
      clearError: true,
    );
  }

  void commissionPrototype({
    required String codename,
    required SkunkworksPrototypeCategory category,
    required SkunkworksTargetRaceTier targetRaceTier,
    required String targetRaceName,
    String leadRiderId = 'rider_leader_gc',
    String leadRiderName = 'Lider Drużyny #1',
  }) {
    state = _service.commissionPrototype(
      state: state,
      codename: codename,
      category: category,
      targetRaceTier: targetRaceTier,
      targetRaceName: targetRaceName,
      leadRiderId: leadRiderId,
      leadRiderName: leadRiderName,
    );
  }

  void runWindTunnelSession(String prototypeId, {int hours = 10}) {
    state = _service.runWindTunnelSession(
      state: state,
      prototypeId: prototypeId,
      hours: hours,
    );
  }

  void runSecretFieldTest(String prototypeId) {
    state = _service.runSecretFieldTest(
      state: state,
      prototypeId: prototypeId,
    );
  }

  void submitUciHomologation(String prototypeId) {
    state = _service.submitUciHomologation(
      state: state,
      prototypeId: prototypeId,
    );
  }

  void deployForKeyRace(String prototypeId) {
    state = _service.deployForKeyRace(
      state: state,
      prototypeId: prototypeId,
    );
  }

  void upgradeLabSecurity() {
    state = _service.upgradeLabSecurity(state);
  }

  void scrapPrototype(String prototypeId) {
    state = _service.scrapPrototype(
      state: state,
      prototypeId: prototypeId,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final skunkworksLabProvider =
    StateNotifierProvider<SkunkworksLabNotifier, SkunkworksLabState>(
  (ref) => SkunkworksLabNotifier(),
);

int _commissionCostFor(
  SkunkworksPrototypeCategory category,
  SkunkworksTargetRaceTier tier,
) {
  final int base = switch (category) {
    SkunkworksPrototypeCategory.aeroTtFrame => 95000,
    SkunkworksPrototypeCategory.ultralightClimbingChassis => 85000,
    SkunkworksPrototypeCategory.cobbleSuspensionCockpit => 65000,
    SkunkworksPrototypeCategory.ceramicDrivetrainWax => 45000,
    SkunkworksPrototypeCategory.carbonMonocoqueWheelset => 75000,
  };
  return (base * tier.prestigeMultiplier).round();
}

/// Główny panel UI tajnego laboratorium prototypów Skunkworks Lab.
class SkunkworksLabPanel extends ConsumerStatefulWidget {
  const SkunkworksLabPanel({super.key});

  @override
  ConsumerState<SkunkworksLabPanel> createState() => _SkunkworksLabPanelState();
}

class _SkunkworksLabPanelState extends ConsumerState<SkunkworksLabPanel> {
  final TextEditingController _codenameController =
      TextEditingController(text: 'Project Specter-V2');
  final TextEditingController _raceNameController =
      TextEditingController(text: 'Tour de France');
  SkunkworksPrototypeCategory _selectedCategory =
      SkunkworksPrototypeCategory.aeroTtFrame;
  SkunkworksTargetRaceTier _selectedTier = SkunkworksTargetRaceTier.grandTour;
  bool _showNewProjectForm = false;

  @override
  void dispose() {
    _codenameController.dispose();
    _raceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labState = ref.watch(skunkworksLabProvider);
    final notifier = ref.read(skunkworksLabProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isCompact = width < 720;
          final bool isWide = width >= 1240;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(labState, notifier, isCompact),
                if (labState.lastErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildAlertBanner(
                    message: labState.lastErrorMessage!,
                    color: AppColors.crimsonAlert,
                    icon: Icons.warning_amber_rounded,
                    onDismiss: notifier.clearError,
                  ),
                ],
                if (labState.lastDeploymentOutcome != null) ...[
                  const SizedBox(height: 12),
                  _buildAlertBanner(
                    message: labState.lastDeploymentOutcome!.summaryMessage,
                    color: labState.lastDeploymentOutcome!
                            .mechanicalReliabilityPassed
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                    icon: Icons.verified_rounded,
                  ),
                ],
                if (_showNewProjectForm) ...[
                  const SizedBox(height: 16),
                  _buildCommissionForm(notifier, isCompact),
                ],
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildPrototypeListCard(labState, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _buildSelectedPrototypeDetail(
                          labState,
                          notifier,
                          isCompact,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildTelemetryFeedCard(labState),
                      ),
                    ],
                  )
                else if (!isCompact)
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildPrototypeListCard(labState, notifier),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: _buildSelectedPrototypeDetail(
                              labState,
                              notifier,
                              isCompact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTelemetryFeedCard(labState),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildPrototypeListCard(labState, notifier),
                      const SizedBox(height: 12),
                      _buildSelectedPrototypeDetail(
                        labState,
                        notifier,
                        isCompact,
                      ),
                      const SizedBox(height: 12),
                      _buildTelemetryFeedCard(labState),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    SkunkworksLabState state,
    SkunkworksLabNotifier notifier,
    bool isCompact,
  ) {
    final int securityUpgradeCost =
        BikeSponsorCustomPrototypeLabService.securityUpgradeBaseCostEur *
            state.labSecurityLevel;
    final bool canUpgradeSecurity =
        state.labSecurityLevel < 5 &&
        state.availableRndBudgetEur >= securityUpgradeCost;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.goldAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SKUNKWORKS LAB — TAJNE R&D',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.activeManufacturerName} • Poziom R&D ${state.manufacturerRndLevel}/100',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetricBadge(
                label: 'BUDŻET R&D',
                value: Formatters.formatCurrency(state.availableRndBudgetEur),
                accentColor: AppColors.goldAccent,
              ),
              _MetricBadge(
                label: 'TAJNOŚĆ LAB',
                value: 'LVL ${state.labSecurityLevel}/5',
                accentColor: AppColors.cyanAccent,
              ),
              _SkunkworksInteractiveButton(
                label: state.labSecurityLevel >= 5
                    ? 'Maks. Ochrona'
                    : 'Ochrona +1 (${Formatters.formatCurrency(securityUpgradeCost)})',
                icon: Icons.shield_outlined,
                enabled: canUpgradeSecurity,
                accentColor: AppColors.accentBlue,
                onPressed: notifier.upgradeLabSecurity,
              ),
              _SkunkworksInteractiveButton(
                label: _showNewProjectForm ? 'Zamknij Formularz' : 'Nowy Prototyp',
                icon: _showNewProjectForm ? Icons.close_rounded : Icons.add_rounded,
                enabled: true,
                accentColor: AppColors.primaryAccent,
                onPressed: () {
                  setState(() {
                    _showNewProjectForm = !_showNewProjectForm;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner({
    required String message,
    required Color color,
    required IconData icon,
    VoidCallback? onDismiss,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textSecondary,
              tooltip: 'Zamknij',
            ),
        ],
      ),
    );
  }

  Widget _buildCommissionForm(
    SkunkworksLabNotifier notifier,
    bool isCompact,
  ) {
    final int estimatedCost =
        _commissionCostFor(_selectedCategory, _selectedTier);

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zleć Nowy Tajny Prototyp',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 230,
                child: TextField(
                  controller: _codenameController,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kryptonim projektu',
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 230,
                child: TextField(
                  controller: _raceNameController,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kluczowy wyścig docelowy',
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
              DropdownButton<SkunkworksPrototypeCategory>(
                value: _selectedCategory,
                dropdownColor: AppColors.surface,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                items: SkunkworksPrototypeCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              DropdownButton<SkunkworksTargetRaceTier>(
                value: _selectedTier,
                dropdownColor: AppColors.surface,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                items: SkunkworksTargetRaceTier.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTier = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Koszt uruchomienia CAD: ${Formatters.formatCurrency(estimatedCost)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _SkunkworksInteractiveButton(
                label: 'Rozpocznij Projekt',
                icon: Icons.rocket_launch_rounded,
                enabled: true,
                accentColor: AppColors.goldAccent,
                onPressed: () {
                  notifier.commissionPrototype(
                    codename: _codenameController.text,
                    category: _selectedCategory,
                    targetRaceTier: _selectedTier,
                    targetRaceName: _raceNameController.text,
                  );
                  setState(() => _showNewProjectForm = false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypeListCard(
    SkunkworksLabState state,
    SkunkworksLabNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Aktywne Projekty',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${state.activePrototypesCount} aktywne',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.prototypes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Brak zleconych prototypów. Utwórz nowy projekt R&D.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...state.prototypes.map((proto) {
              final bool isSelected = state.selectedPrototype?.id == proto.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PrototypeSelectorTile(
                  prototype: proto,
                  selected: isSelected,
                  onTap: () => notifier.selectPrototype(proto.id),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSelectedPrototypeDetail(
    SkunkworksLabState state,
    SkunkworksLabNotifier notifier,
    bool isCompact,
  ) {
    final proto = state.selectedPrototype;
    if (proto == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.0),
        ),
        child: const Center(
          child: Text(
            'Wybierz prototyp z listy, aby wyświetlić telemetrię inżynieryjną.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final bool canWindTunnel = proto.phase.isActiveDevelopment &&
        state.availableRndBudgetEur >=
            BikeSponsorCustomPrototypeLabService.windTunnelSessionCostEur;
    final bool canFieldTest = proto.phase.isActiveDevelopment &&
        state.availableRndBudgetEur >=
            BikeSponsorCustomPrototypeLabService.fieldValidationCostEur;
    final bool canHomologate = proto.canSubmitForUciHomologation &&
        state.availableRndBudgetEur >=
            BikeSponsorCustomPrototypeLabService.uciHomologationCostEur;
    final bool canDeploy =
        proto.phase == SkunkworksPrototypePhase.raceReadyHomologated ||
            proto.phase == SkunkworksPrototypePhase.deployedInRace;
    final bool canScrap = proto.phase != SkunkworksPrototypePhase.scrapped;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(proto.category.icon, color: AppColors.goldAccent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proto.codename,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${proto.category.label} • Cel: ${proto.targetRaceName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: proto.secrecyLevel.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: proto.secrecyLevel.color.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  proto.secrecyLevel.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: proto.secrecyLevel.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Faza: ${proto.phase.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(proto.developmentProgress * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: proto.developmentProgress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                proto.phase == SkunkworksPrototypePhase.scrapped
                    ? AppColors.crimsonAlert
                    : AppColors.cyanAccent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TelemetryStatBox(
                label: 'Zysk przy 45 km/h',
                value: '+${proto.estimatedWattsSavedAt45Kmh.toStringAsFixed(1)} W',
                color: AppColors.statusSuccess,
              ),
              _TelemetryStatBox(
                label: 'Delta CdA',
                value: '${proto.cdaDeltaPercent.toStringAsFixed(2)}%',
                color: AppColors.cyanAccent,
              ),
              _TelemetryStatBox(
                label: 'Masa',
                value:
                    '${proto.weightDeltaGrams >= 0 ? '+' : ''}${proto.weightDeltaGrams} g',
                color: AppColors.accentBlue,
              ),
              _TelemetryStatBox(
                label: 'Ryzyko awarii',
                value: '${proto.failureRiskPercent.toStringAsFixed(1)}%',
                color: proto.failureRiskPercent > 10
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess,
              ),
              _TelemetryStatBox(
                label: 'Margin UCI',
                value: '${proto.uciComplianceMarginPercent.toStringAsFixed(1)}%',
                color: proto.isUciCompliant
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _TelemetryStatBox(
                label: 'Tunel Aero',
                value:
                    '${proto.windTunnelHoursLogged}/${proto.windTunnelHoursRequired} h',
                color: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              proto.engineeringNotes,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SkunkworksInteractiveButton(
                label: 'Tunel Aero (+10h)',
                icon: Icons.wind_power_rounded,
                enabled: canWindTunnel,
                accentColor: AppColors.cyanAccent,
                onPressed: () => notifier.runWindTunnelSession(proto.id),
              ),
              _SkunkworksInteractiveButton(
                label: 'Tajny Test Szosowy',
                icon: Icons.nightlight_round,
                enabled: canFieldTest,
                accentColor: AppColors.accentBlue,
                onPressed: () => notifier.runSecretFieldTest(proto.id),
              ),
              _SkunkworksInteractiveButton(
                label: 'Homologacja UCI',
                icon: Icons.verified_user_rounded,
                enabled: canHomologate,
                accentColor: AppColors.statusSuccess,
                onPressed: () => notifier.submitUciHomologation(proto.id),
              ),
              _SkunkworksInteractiveButton(
                label: 'Wdróż na Wyścig',
                icon: Icons.flag_rounded,
                enabled: canDeploy,
                accentColor: AppColors.goldAccent,
                onPressed: () => notifier.deployForKeyRace(proto.id),
              ),
              _SkunkworksInteractiveButton(
                label: 'Wycofaj',
                icon: Icons.delete_outline_rounded,
                enabled: canScrap,
                accentColor: AppColors.crimsonAlert,
                onPressed: () => notifier.scrapPrototype(proto.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryFeedCard(SkunkworksLabState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dziennik Telemetrii Lab',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (state.telemetryLogs.isEmpty)
            const Text(
              'Brak zarejestrowanych pomiarów.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...state.telemetryLogs.take(6).map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: log.isAlert
                        ? AppColors.crimsonAlert.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            log.title,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: log.isAlert
                                  ? AppColors.crimsonAlert
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          log.timestampLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.detail,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeSelectorTile extends StatefulWidget {
  final SkunkworksPrototypeSpec prototype;
  final bool selected;
  final VoidCallback onTap;

  const _PrototypeSelectorTile({
    required this.prototype,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PrototypeSelectorTile> createState() => _PrototypeSelectorTileState();
}

class _PrototypeSelectorTileState extends State<_PrototypeSelectorTile> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.selected
        ? AppColors.goldAccent
        : (_isFocused
            ? AppColors.cyanAccent
            : (_isHovered ? AppColors.textSecondary : AppColors.cardBorder));

    final Color bgColor = widget.selected
        ? AppColors.surfaceLight
        : (_isPressed
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : (_isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.55)
                : AppColors.background));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
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
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: widget.selected ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              Icon(
                widget.prototype.category.icon,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.prototype.codename,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.prototype.phase.label} • ${(widget.prototype.developmentProgress * 100).round()}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${widget.prototype.estimatedWattsSavedAt45Kmh.toStringAsFixed(1)}W',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkunkworksInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _SkunkworksInteractiveButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_SkunkworksInteractiveButton> createState() =>
      _SkunkworksInteractiveButtonState();
}

class _SkunkworksInteractiveButtonState
    extends State<_SkunkworksInteractiveButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled;
    final Color fgColor = active
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.45);
    final Color bgColor = !active
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : (_isPressed
            ? widget.accentColor.withValues(alpha: 0.35)
            : (_isHovered
                ? widget.accentColor.withValues(alpha: 0.25)
                : widget.accentColor.withValues(alpha: 0.15)));
    final Color borderColor = !active
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (_isFocused
            ? AppColors.cyanAccent
            : widget.accentColor.withValues(alpha: _isHovered ? 0.9 : 0.55));

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (active) widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: active ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: active ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: active ? () => setState(() => _isPressed = false) : null,
          onTap: active ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: active ? widget.accentColor : fgColor,
                ),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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
