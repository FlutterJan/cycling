import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/organizer/race_organizer_empire_model.dart';

/// Typ strefy zagrożenia na trasie wyścigu wymagającej zabezpieczenia inżynieryjnego i marshali.
enum CourseHazardZoneType {
  finalSprintChute,
  technicalHairpinDescent,
  roundaboutTrafficIsland,
  cobbleSectorApproach,
  alpineCliffDropoff,
  railwayOrBridgeBottleneck;

  String toJson() => name;

  static CourseHazardZoneType fromJson(String value) {
    return CourseHazardZoneType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CourseHazardZoneType.roundaboutTrafficIsland,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CourseHazardZoneType.finalSprintChute:
        return 'Korytarz Finiszu Sprinterskiego';
      case CourseHazardZoneType.technicalHairpinDescent:
        return 'Techniczna Serpentyna Zjazdowa';
      case CourseHazardZoneType.roundaboutTrafficIsland:
        return 'Rondo i Wysepka Drogowa';
      case CourseHazardZoneType.cobbleSectorApproach:
        return 'Dojazd do Sektora Bruku';
      case CourseHazardZoneType.alpineCliffDropoff:
        return 'Przepaść Alpejska / Urwisko';
      case CourseHazardZoneType.railwayOrBridgeBottleneck:
        return 'Przejazd Kolejowy / Wąski Mostek';
    }
  }

  String get shortTag {
    switch (this) {
      case CourseHazardZoneType.finalSprintChute:
        return 'SPRINT';
      case CourseHazardZoneType.technicalHairpinDescent:
        return 'ZJAZD';
      case CourseHazardZoneType.roundaboutTrafficIsland:
        return 'RONDO';
      case CourseHazardZoneType.cobbleSectorApproach:
        return 'BRUK';
      case CourseHazardZoneType.alpineCliffDropoff:
        return 'URWISKO';
      case CourseHazardZoneType.railwayOrBridgeBottleneck:
        return 'ZWĘŻENIE';
    }
  }

  /// Bazowe ryzyko kraksy (0–100) wynikające z geometrii miejsca.
  double get baseGeometricRisk {
    switch (this) {
      case CourseHazardZoneType.finalSprintChute:
        return 84.0;
      case CourseHazardZoneType.technicalHairpinDescent:
        return 78.0;
      case CourseHazardZoneType.roundaboutTrafficIsland:
        return 72.0;
      case CourseHazardZoneType.cobbleSectorApproach:
        return 66.0;
      case CourseHazardZoneType.alpineCliffDropoff:
        return 88.0;
      case CourseHazardZoneType.railwayOrBridgeBottleneck:
        return 62.0;
    }
  }

  /// Czy strefa jest objęta bezwzględnym priorytetem protokołu UCI SafeR dla poduszek Boplan / siatek.
  bool get requiresHighEnergyAbsorption {
    return this == CourseHazardZoneType.finalSprintChute ||
        this == CourseHazardZoneType.technicalHairpinDescent ||
        this == CourseHazardZoneType.alpineCliffDropoff;
  }
}

/// System barier ochronnych lub siatek asekuracyjnych instalowanych w strefie.
enum SafetyBarrierSystemType {
  none,
  standardMetalCrowds,
  boplanAirCushion,
  catchNetAndFoamMattress;

  String toJson() => name;

  static SafetyBarrierSystemType fromJson(String value) {
    return SafetyBarrierSystemType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SafetyBarrierSystemType.standardMetalCrowds,
    );
  }

  String get displayNamePl {
    switch (this) {
      case SafetyBarrierSystemType.none:
        return 'Brak Barier (Taśma Ostrzegawcza)';
      case SafetyBarrierSystemType.standardMetalCrowds:
        return 'Standardowe Barierki Metalowe';
      case SafetyBarrierSystemType.boplanAirCushion:
        return 'Boplan Air-Cushion Barriers';
      case SafetyBarrierSystemType.catchNetAndFoamMattress:
        return 'Siatki Asekuracyjne + Materace';
    }
  }

  String get shortTag {
    switch (this) {
      case SafetyBarrierSystemType.none:
        return 'BRAK';
      case SafetyBarrierSystemType.standardMetalCrowds:
        return 'METAL';
      case SafetyBarrierSystemType.boplanAirCushion:
        return 'BOPLAN';
      case SafetyBarrierSystemType.catchNetAndFoamMattress:
        return 'SIATKA';
    }
  }

  /// Koszt instalacji za każdy 1 metr strefy (EUR).
  double get costPerMeterEur {
    switch (this) {
      case SafetyBarrierSystemType.none:
        return 2.0;
      case SafetyBarrierSystemType.standardMetalCrowds:
        return 18.0;
      case SafetyBarrierSystemType.boplanAirCushion:
        return 74.0;
      case SafetyBarrierSystemType.catchNetAndFoamMattress:
        return 58.0;
    }
  }

  /// Bazowa skuteczność absorpcji energii uderzenia i utrzymania peletonu na trasie (0.0–1.0).
  double effectivenessForZone(CourseHazardZoneType zoneType) {
    switch (this) {
      case SafetyBarrierSystemType.none:
        return 0.04;
      case SafetyBarrierSystemType.standardMetalCrowds:
        // Twarde metalowe barierki na szybkim finiszu lub zjeździe mają ograniczoną ochronę.
        if (zoneType == CourseHazardZoneType.finalSprintChute) return 0.38;
        if (zoneType == CourseHazardZoneType.alpineCliffDropoff) return 0.28;
        if (zoneType == CourseHazardZoneType.technicalHairpinDescent) return 0.34;
        return 0.62;
      case SafetyBarrierSystemType.boplanAirCushion:
        if (zoneType == CourseHazardZoneType.finalSprintChute) return 0.94;
        if (zoneType == CourseHazardZoneType.roundaboutTrafficIsland) return 0.88;
        if (zoneType == CourseHazardZoneType.cobbleSectorApproach) return 0.86;
        if (zoneType == CourseHazardZoneType.technicalHairpinDescent) return 0.82;
        if (zoneType == CourseHazardZoneType.railwayOrBridgeBottleneck) {
          return 0.85;
        }
        return 0.72;
      case SafetyBarrierSystemType.catchNetAndFoamMattress:
        if (zoneType == CourseHazardZoneType.alpineCliffDropoff) return 0.95;
        if (zoneType == CourseHazardZoneType.technicalHairpinDescent) return 0.92;
        if (zoneType == CourseHazardZoneType.roundaboutTrafficIsland) return 0.70;
        if (zoneType == CourseHazardZoneType.finalSprintChute) return 0.56;
        return 0.74;
    }
  }
}

/// Gęstość rozstawienia marshali i sygnalizacji dźwiękowo-świetlnej w strefie.
enum MarshalDeploymentDensity {
  minimal,
  standard,
  uciProSafeR;

  String toJson() => name;

  static MarshalDeploymentDensity fromJson(String value) {
    return MarshalDeploymentDensity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MarshalDeploymentDensity.standard,
    );
  }

  String get displayNamePl {
    switch (this) {
      case MarshalDeploymentDensity.minimal:
        return 'Minimalna (1–2 Marshali)';
      case MarshalDeploymentDensity.standard:
        return 'Standardowa (3–5 Marshali)';
      case MarshalDeploymentDensity.uciProSafeR:
        return 'Protokół UCI SafeR (6+ i Moto)';
    }
  }

  String get shortTag {
    switch (this) {
      case MarshalDeploymentDensity.minimal:
        return 'MIN';
      case MarshalDeploymentDensity.standard:
        return 'STD';
      case MarshalDeploymentDensity.uciProSafeR:
        return 'SAFER';
    }
  }

  /// Liczba marshali przypadająca na 100 m strefy (minimum wg skali).
  int get baseMarshalsCount {
    switch (this) {
      case MarshalDeploymentDensity.minimal:
        return 2;
      case MarshalDeploymentDensity.standard:
        return 5;
      case MarshalDeploymentDensity.uciProSafeR:
        return 9;
    }
  }

  /// Koszt obsługi jednego marshala na dzień wyścigowy (EUR).
  int get costPerMarshalEur => 260;

  /// Redukcja ryzyka błędu nawigacyjnego lub wtargnięcia kibiców (0.0–1.0).
  double get humanRiskMitigation {
    switch (this) {
      case MarshalDeploymentDensity.minimal:
        return 0.18;
      case MarshalDeploymentDensity.standard:
        return 0.54;
      case MarshalDeploymentDensity.uciProSafeR:
        return 0.88;
    }
  }
}

/// Ocena zgodności planu bezpieczeństwa trasy z regulaminem UCI SafeR.
enum SafetyAuditComplianceGrade {
  criticalFailure,
  substandardWarning,
  uciCompliant,
  safeRGoldCertified;

  String toJson() => name;

  static SafetyAuditComplianceGrade fromJson(String value) {
    return SafetyAuditComplianceGrade.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SafetyAuditComplianceGrade.substandardWarning,
    );
  }

  String get displayNamePl {
    switch (this) {
      case SafetyAuditComplianceGrade.criticalFailure:
        return 'Krytyczne Braki — Ryzyko Odwołania';
      case SafetyAuditComplianceGrade.substandardWarning:
        return 'Ostrzeżenie UCI SafeR';
      case SafetyAuditComplianceGrade.uciCompliant:
        return 'Zatwierdzono (Standard UCI)';
      case SafetyAuditComplianceGrade.safeRGoldCertified:
        return 'Certyfikat SafeR Gold';
    }
  }
}

/// Pojedyncza strefa niebezpieczna na trasie etapu wraz z przypisanym zabezpieczeniem.
class CourseHazardZone {
  final String zoneId;
  final String name;
  final double kilometerMark;
  final int lengthMeters;
  final CourseHazardZoneType zoneType;
  final double expectedPelotonSpeedKmh;
  final double crowdDensityIndex;
  final double cliffExposureSeverity;
  final SafetyBarrierSystemType assignedBarrier;
  final MarshalDeploymentDensity assignedMarshalDensity;
  final bool hasLedWarningTotem;

  const CourseHazardZone({
    required this.zoneId,
    required this.name,
    required this.kilometerMark,
    required this.lengthMeters,
    required this.zoneType,
    required this.expectedPelotonSpeedKmh,
    this.crowdDensityIndex = 0.5,
    this.cliffExposureSeverity = 0.0,
    this.assignedBarrier = SafetyBarrierSystemType.standardMetalCrowds,
    this.assignedMarshalDensity = MarshalDeploymentDensity.standard,
    this.hasLedWarningTotem = false,
  });

  /// Bazowe ryzyko strefy (0–100) przed zastosowaniem barier i marshali.
  double get baselineHazardRisk {
    final speedFactor = ((expectedPelotonSpeedKmh - 35.0) / 45.0).clamp(0.0, 1.0);
    final crowdFactor = crowdDensityIndex.clamp(0.0, 1.0);
    final cliffFactor = cliffExposureSeverity.clamp(0.0, 1.0);
    final raw = zoneType.baseGeometricRisk * 0.62 +
        speedFactor * 22.0 +
        crowdFactor * 10.0 +
        cliffFactor * 14.0;
    return raw.clamp(12.0, 99.0);
  }

  /// Liczba modułów Boplan (2 m każdy) potrzebna przy wyborze `boplanAirCushion`.
  int get boplanUnitsRequired {
    if (assignedBarrier != SafetyBarrierSystemType.boplanAirCushion) return 0;
    return (lengthMeters / 2.0).ceil();
  }

  /// Metry bieżące siatek asekuracyjnych przy wyborze `catchNetAndFoamMattress`.
  int get catchNetMetersRequired {
    if (assignedBarrier != SafetyBarrierSystemType.catchNetAndFoamMattress) {
      return 0;
    }
    return lengthMeters;
  }

  /// Liczba marshali w strefie skalowana długością odcinka.
  int get marshalCount {
    final lengthScale = math.max(1, (lengthMeters / 180.0).ceil());
    return assignedMarshalDensity.baseMarshalsCount + (lengthScale - 1) * 2;
  }

  /// Całkowity koszt zabezpieczenia tej strefy (EUR).
  int get deploymentCostEur {
    final barrierCost = (lengthMeters * assignedBarrier.costPerMeterEur).round();
    final marshalCost = marshalCount * assignedMarshalDensity.costPerMarshalEur;
    final totemCost = hasLedWarningTotem ? 1450 : 0;
    return barrierCost + marshalCost + totemCost;
  }

  /// Procentowa redukcja dotkliwości ewentualnej kraksy dzięki dobranym środkom (0–100%).
  double get severityReductionPct {
    final barrierEff = assignedBarrier.effectivenessForZone(zoneType);
    final marshalEff = assignedMarshalDensity.humanRiskMitigation;
    final totemBonus = hasLedWarningTotem ? 0.08 : 0.0;
    final combined = (barrierEff * 0.68 + marshalEff * 0.24 + totemBonus).clamp(0.02, 0.96);
    return combined * 100.0;
  }

  /// Rezydualne ryzyko poważnego wypadku po zastosowaniu zabezpieczeń (0–100).
  double get residualCrashRisk {
    final reductionRatio = severityReductionPct / 100.0;
    return (baselineHazardRisk * (1.0 - reductionRatio * 0.88)).clamp(2.0, 98.0);
  }

  /// Czy strefa spełnia minimalne wytyczne UCI SafeR.
  bool get isUciMinimumMet {
    if (zoneType == CourseHazardZoneType.finalSprintChute) {
      return assignedBarrier == SafetyBarrierSystemType.boplanAirCushion &&
          assignedMarshalDensity != MarshalDeploymentDensity.minimal;
    }
    if (zoneType == CourseHazardZoneType.alpineCliffDropoff) {
      return assignedBarrier == SafetyBarrierSystemType.catchNetAndFoamMattress &&
          assignedMarshalDensity != MarshalDeploymentDensity.minimal;
    }
    if (zoneType == CourseHazardZoneType.technicalHairpinDescent) {
      return (assignedBarrier == SafetyBarrierSystemType.catchNetAndFoamMattress ||
              assignedBarrier == SafetyBarrierSystemType.boplanAirCushion) &&
          assignedMarshalDensity != MarshalDeploymentDensity.minimal;
    }
    if (zoneType == CourseHazardZoneType.roundaboutTrafficIsland) {
      return assignedBarrier != SafetyBarrierSystemType.none &&
          (assignedMarshalDensity == MarshalDeploymentDensity.uciProSafeR ||
              hasLedWarningTotem);
    }
    return assignedBarrier != SafetyBarrierSystemType.none &&
        assignedMarshalDensity != MarshalDeploymentDensity.minimal;
  }

  CourseHazardZone copyWith({
    String? zoneId,
    String? name,
    double? kilometerMark,
    int? lengthMeters,
    CourseHazardZoneType? zoneType,
    double? expectedPelotonSpeedKmh,
    double? crowdDensityIndex,
    double? cliffExposureSeverity,
    SafetyBarrierSystemType? assignedBarrier,
    MarshalDeploymentDensity? assignedMarshalDensity,
    bool? hasLedWarningTotem,
  }) {
    return CourseHazardZone(
      zoneId: zoneId ?? this.zoneId,
      name: name ?? this.name,
      kilometerMark: kilometerMark ?? this.kilometerMark,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      zoneType: zoneType ?? this.zoneType,
      expectedPelotonSpeedKmh:
          expectedPelotonSpeedKmh ?? this.expectedPelotonSpeedKmh,
      crowdDensityIndex: crowdDensityIndex ?? this.crowdDensityIndex,
      cliffExposureSeverity:
          cliffExposureSeverity ?? this.cliffExposureSeverity,
      assignedBarrier: assignedBarrier ?? this.assignedBarrier,
      assignedMarshalDensity:
          assignedMarshalDensity ?? this.assignedMarshalDensity,
      hasLedWarningTotem: hasLedWarningTotem ?? this.hasLedWarningTotem,
    );
  }

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'name': name,
        'kilometerMark': kilometerMark,
        'lengthMeters': lengthMeters,
        'zoneType': zoneType.toJson(),
        'expectedPelotonSpeedKmh': expectedPelotonSpeedKmh,
        'crowdDensityIndex': crowdDensityIndex,
        'cliffExposureSeverity': cliffExposureSeverity,
        'assignedBarrier': assignedBarrier.toJson(),
        'assignedMarshalDensity': assignedMarshalDensity.toJson(),
        'hasLedWarningTotem': hasLedWarningTotem,
      };

  factory CourseHazardZone.fromJson(Map<String, dynamic> json) {
    return CourseHazardZone(
      zoneId: json['zoneId'] as String? ?? 'zone_unknown',
      name: json['name'] as String? ?? 'Strefa Trasy',
      kilometerMark: (json['kilometerMark'] as num?)?.toDouble() ?? 0.0,
      lengthMeters: (json['lengthMeters'] as num?)?.toInt() ?? 150,
      zoneType: CourseHazardZoneType.fromJson(
        json['zoneType'] as String? ?? 'roundaboutTrafficIsland',
      ),
      expectedPelotonSpeedKmh:
          (json['expectedPelotonSpeedKmh'] as num?)?.toDouble() ?? 50.0,
      crowdDensityIndex:
          (json['crowdDensityIndex'] as num?)?.toDouble() ?? 0.5,
      cliffExposureSeverity:
          (json['cliffExposureSeverity'] as num?)?.toDouble() ?? 0.0,
      assignedBarrier: SafetyBarrierSystemType.fromJson(
        json['assignedBarrier'] as String? ?? 'standardMetalCrowds',
      ),
      assignedMarshalDensity: MarshalDeploymentDensity.fromJson(
        json['assignedMarshalDensity'] as String? ?? 'standard',
      ),
      hasLedWarningTotem: json['hasLedWarningTotem'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseHazardZone &&
          runtimeType == other.runtimeType &&
          zoneId == other.zoneId &&
          name == other.name &&
          kilometerMark == other.kilometerMark &&
          lengthMeters == other.lengthMeters &&
          zoneType == other.zoneType &&
          expectedPelotonSpeedKmh == other.expectedPelotonSpeedKmh &&
          crowdDensityIndex == other.crowdDensityIndex &&
          cliffExposureSeverity == other.cliffExposureSeverity &&
          assignedBarrier == other.assignedBarrier &&
          assignedMarshalDensity == other.assignedMarshalDensity &&
          hasLedWarningTotem == other.hasLedWarningTotem;

  @override
  int get hashCode => Object.hash(
        zoneId,
        name,
        kilometerMark,
        lengthMeters,
        zoneType,
        expectedPelotonSpeedKmh,
        crowdDensityIndex,
        cliffExposureSeverity,
        assignedBarrier,
        assignedMarshalDensity,
        hasLedWarningTotem,
      );
}

/// Magazyn sprzętu bezpieczeństwa dostępnego dla organizatora wyścigu.
class SafetyEquipmentInventory {
  final int boplanAirCushionUnits;
  final int catchNetMeters;
  final int metalBarrierUnits;
  final int trainedMarshalsPool;
  final int ledWarningTotems;

  const SafetyEquipmentInventory({
    required this.boplanAirCushionUnits,
    required this.catchNetMeters,
    required this.metalBarrierUnits,
    required this.trainedMarshalsPool,
    required this.ledWarningTotems,
  });

  Map<String, dynamic> toJson() => {
        'boplanAirCushionUnits': boplanAirCushionUnits,
        'catchNetMeters': catchNetMeters,
        'metalBarrierUnits': metalBarrierUnits,
        'trainedMarshalsPool': trainedMarshalsPool,
        'ledWarningTotems': ledWarningTotems,
      };

  factory SafetyEquipmentInventory.fromJson(Map<String, dynamic> json) {
    return SafetyEquipmentInventory(
      boplanAirCushionUnits:
          (json['boplanAirCushionUnits'] as num?)?.toInt() ?? 400,
      catchNetMeters: (json['catchNetMeters'] as num?)?.toInt() ?? 600,
      metalBarrierUnits: (json['metalBarrierUnits'] as num?)?.toInt() ?? 1200,
      trainedMarshalsPool:
          (json['trainedMarshalsPool'] as num?)?.toInt() ?? 60,
      ledWarningTotems: (json['ledWarningTotems'] as num?)?.toInt() ?? 8,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyEquipmentInventory &&
          runtimeType == other.runtimeType &&
          boplanAirCushionUnits == other.boplanAirCushionUnits &&
          catchNetMeters == other.catchNetMeters &&
          metalBarrierUnits == other.metalBarrierUnits &&
          trainedMarshalsPool == other.trainedMarshalsPool &&
          ledWarningTotems == other.ledWarningTotems;

  @override
  int get hashCode => Object.hash(
        boplanAirCushionUnits,
        catchNetMeters,
        metalBarrierUnits,
        trainedMarshalsPool,
        ledWarningTotems,
      );
}

/// Raport audytu bezpieczeństwa trasy wygenerowany przez komisję UCI SafeR.
class CourseSafetyAuditReport {
  final String raceId;
  final String raceName;
  final int stageNumber;
  final int totalZones;
  final int uciCompliantZones;
  final double overallSafetyScore;
  final double averageCrashRiskPct;
  final double injurySeverityReductionPct;
  final int totalDeploymentCostEur;
  final int totalMarshalsAssigned;
  final int totalBoplanUnitsUsed;
  final int totalCatchNetMetersUsed;
  final int totalLedTotemsUsed;
  final SafetyAuditComplianceGrade complianceGrade;
  final int uciFineRiskEur;
  final double prestigeDelta;
  final double cpaRiderApprovalScore;
  final List<String> criticalWarnings;
  final List<String> recommendations;

  const CourseSafetyAuditReport({
    required this.raceId,
    required this.raceName,
    required this.stageNumber,
    required this.totalZones,
    required this.uciCompliantZones,
    required this.overallSafetyScore,
    required this.averageCrashRiskPct,
    required this.injurySeverityReductionPct,
    required this.totalDeploymentCostEur,
    required this.totalMarshalsAssigned,
    required this.totalBoplanUnitsUsed,
    required this.totalCatchNetMetersUsed,
    required this.totalLedTotemsUsed,
    required this.complianceGrade,
    required this.uciFineRiskEur,
    required this.prestigeDelta,
    required this.cpaRiderApprovalScore,
    required this.criticalWarnings,
    required this.recommendations,
  });

  bool get isReadyForStart =>
      complianceGrade == SafetyAuditComplianceGrade.uciCompliant ||
      complianceGrade == SafetyAuditComplianceGrade.safeRGoldCertified;
}

/// Wynik wdrożenia planu bezpieczeństwa do księgi budżetowej i portfela wyścigu (#513).
class SafetyPlanLedgerIntegrationResult {
  final OrganizerBudgetLedger updatedLedger;
  final ManagedRacePortfolioItem updatedRace;
  final CourseSafetyAuditReport auditReport;
  final OrganizerLedgerEntry? entryRecorded;
  final String messagePl;

  const SafetyPlanLedgerIntegrationResult({
    required this.updatedLedger,
    required this.updatedRace,
    required this.auditReport,
    this.entryRecorded,
    required this.messagePl,
  });
}

/// Główny serwis planowania barier ochronnych (`Boplan Air-Cushion`), siatek i marshali na trasie.
class CourseSafetyBarriersAndMarshalsPlanner {
  const CourseSafetyBarriersAndMarshalsPlanner();

  /// Tworzy realistyczny zestaw 6 kluczowych stref zagrożenia na etapie WorldTour.
  static List<CourseHazardZone> createDefaultStageHazardZones() {
    return const [
      CourseHazardZone(
        zoneId: 'zone_km42_cobbles',
        name: 'Zwężenie przed Sektorem Bruku',
        kilometerMark: 42.5,
        lengthMeters: 220,
        zoneType: CourseHazardZoneType.cobbleSectorApproach,
        expectedPelotonSpeedKmh: 54.0,
        crowdDensityIndex: 0.72,
        assignedBarrier: SafetyBarrierSystemType.standardMetalCrowds,
        assignedMarshalDensity: MarshalDeploymentDensity.standard,
      ),
      CourseHazardZone(
        zoneId: 'zone_km88_roundabout',
        name: 'Rondo w Dolinie (Wysepka)',
        kilometerMark: 88.0,
        lengthMeters: 140,
        zoneType: CourseHazardZoneType.roundaboutTrafficIsland,
        expectedPelotonSpeedKmh: 58.0,
        crowdDensityIndex: 0.45,
        assignedBarrier: SafetyBarrierSystemType.standardMetalCrowds,
        assignedMarshalDensity: MarshalDeploymentDensity.minimal,
      ),
      CourseHazardZone(
        zoneId: 'zone_km124_cliff',
        name: 'Przełęcz — Półka Skalna',
        kilometerMark: 124.5,
        lengthMeters: 300,
        zoneType: CourseHazardZoneType.alpineCliffDropoff,
        expectedPelotonSpeedKmh: 62.0,
        crowdDensityIndex: 0.35,
        cliffExposureSeverity: 0.92,
        assignedBarrier: SafetyBarrierSystemType.none,
        assignedMarshalDensity: MarshalDeploymentDensity.minimal,
      ),
      CourseHazardZone(
        zoneId: 'zone_km146_hairpin',
        name: 'Serpentyny Zjazdowe (3 Nawroty)',
        kilometerMark: 146.0,
        lengthMeters: 260,
        zoneType: CourseHazardZoneType.technicalHairpinDescent,
        expectedPelotonSpeedKmh: 76.0,
        crowdDensityIndex: 0.40,
        cliffExposureSeverity: 0.65,
        assignedBarrier: SafetyBarrierSystemType.standardMetalCrowds,
        assignedMarshalDensity: MarshalDeploymentDensity.standard,
      ),
      CourseHazardZone(
        zoneId: 'zone_km169_bridge',
        name: 'Wąski Mostek Kolejowy (5 km do mety)',
        kilometerMark: 169.5,
        lengthMeters: 160,
        zoneType: CourseHazardZoneType.railwayOrBridgeBottleneck,
        expectedPelotonSpeedKmh: 63.0,
        crowdDensityIndex: 0.65,
        assignedBarrier: SafetyBarrierSystemType.standardMetalCrowds,
        assignedMarshalDensity: MarshalDeploymentDensity.standard,
      ),
      CourseHazardZone(
        zoneId: 'zone_km175_sprint',
        name: 'Ostatnie 400 m — Korytarz Finiszu',
        kilometerMark: 175.6,
        lengthMeters: 400,
        zoneType: CourseHazardZoneType.finalSprintChute,
        expectedPelotonSpeedKmh: 74.0,
        crowdDensityIndex: 0.96,
        assignedBarrier: SafetyBarrierSystemType.standardMetalCrowds,
        assignedMarshalDensity: MarshalDeploymentDensity.standard,
      ),
    ];
  }

  static SafetyEquipmentInventory createDefaultInventory() {
    return const SafetyEquipmentInventory(
      boplanAirCushionUnits: 520,
      catchNetMeters: 800,
      metalBarrierUnits: 1400,
      trainedMarshalsPool: 72,
      ledWarningTotems: 8,
    );
  }

  /// Przeprowadza pełny audyt bezpieczeństwa stref na etapie oraz weryfikuje budżet i magazyn.
  CourseSafetyAuditReport auditCourseSafety({
    required String raceId,
    required String raceName,
    required int stageNumber,
    required List<CourseHazardZone> zones,
    SafetyEquipmentInventory? inventory,
    int? availableBudgetEur,
  }) {
    if (zones.isEmpty) {
      return CourseSafetyAuditReport(
        raceId: raceId,
        raceName: raceName,
        stageNumber: stageNumber,
        totalZones: 0,
        uciCompliantZones: 0,
        overallSafetyScore: 100.0,
        averageCrashRiskPct: 0.0,
        injurySeverityReductionPct: 0.0,
        totalDeploymentCostEur: 0,
        totalMarshalsAssigned: 0,
        totalBoplanUnitsUsed: 0,
        totalCatchNetMetersUsed: 0,
        totalLedTotemsUsed: 0,
        complianceGrade: SafetyAuditComplianceGrade.uciCompliant,
        uciFineRiskEur: 0,
        prestigeDelta: 0.0,
        cpaRiderApprovalScore: 95.0,
        criticalWarnings: const [],
        recommendations: const ['Brak zdefiniowanych stref zagrożenia na etapie.'],
      );
    }

    var compliantCount = 0;
    var sumRisk = 0.0;
    var sumReduction = 0.0;
    var totalCost = 0;
    var totalMarshals = 0;
    var totalBoplan = 0;
    var totalCatchNet = 0;
    var totalLedTotems = 0;

    final warnings = <String>[];
    final recommendations = <String>[];

    for (final zone in zones) {
      if (zone.isUciMinimumMet) {
        compliantCount++;
      } else {
        warnings.add(
          'KM ${zone.kilometerMark.toStringAsFixed(1)} (${zone.name}): nie spełnia normy UCI SafeR.',
        );
      }

      sumRisk += zone.residualCrashRisk;
      sumReduction += zone.severityReductionPct;
      totalCost += zone.deploymentCostEur;
      totalMarshals += zone.marshalCount;
      totalBoplan += zone.boplanUnitsRequired;
      totalCatchNet += zone.catchNetMetersRequired;
      if (zone.hasLedWarningTotem) totalLedTotems++;

      if (zone.zoneType == CourseHazardZoneType.finalSprintChute &&
          zone.assignedBarrier != SafetyBarrierSystemType.boplanAirCushion) {
        recommendations.add(
          'Zastąp barierki na finiszu (${zone.name}) systemem Boplan Air-Cushion Barriers.',
        );
      } else if ((zone.zoneType == CourseHazardZoneType.alpineCliffDropoff ||
              zone.zoneType == CourseHazardZoneType.technicalHairpinDescent) &&
          zone.assignedBarrier == SafetyBarrierSystemType.none) {
        recommendations.add(
          'Zainstaluj siatki asekuracyjne i materace w strefie ${zone.name}.',
        );
      } else if (zone.zoneType == CourseHazardZoneType.roundaboutTrafficIsland &&
          !zone.hasLedWarningTotem) {
        recommendations.add(
          'Dodaj totem ostrzegawczy LED na rondzie (${zone.name}).',
        );
      }
    }

    if (inventory != null) {
      if (totalBoplan > inventory.boplanAirCushionUnits) {
        warnings.add(
          'Przekroczono stan magazynowy Boplan ($totalBoplan / ${inventory.boplanAirCushionUnits} szt.).',
        );
      }
      if (totalCatchNet > inventory.catchNetMeters) {
        warnings.add(
          'Brak wystarczającej długości siatek ($totalCatchNet / ${inventory.catchNetMeters} m).',
        );
      }
      if (totalMarshals > inventory.trainedMarshalsPool) {
        warnings.add(
          'Zapotrzebowanie na marshali ($totalMarshals) przekracza pulę (${inventory.trainedMarshalsPool}).',
        );
      }
      if (totalLedTotems > inventory.ledWarningTotems) {
        warnings.add(
          'Zapotrzebowanie na totemy LED ($totalLedTotems) przekracza magazyn (${inventory.ledWarningTotems}).',
        );
      }
    }

    if (availableBudgetEur != null && totalCost > availableBudgetEur) {
      warnings.add(
        'Koszt planu ($totalCost €) przekracza limit budżetu bezpieczeństwa ($availableBudgetEur €).',
      );
    }

    final avgRisk = sumRisk / zones.length;
    final avgReduction = sumReduction / zones.length;
    final complianceRatio = compliantCount / zones.length;
    final overallScore = (100.0 - avgRisk * 0.72 + complianceRatio * 24.0)
        .clamp(10.0, 100.0);

    final SafetyAuditComplianceGrade grade;
    final int fineRisk;
    final double prestigeDelta;

    final hasCriticalSprintViolation = zones.any(
      (z) =>
          z.zoneType == CourseHazardZoneType.finalSprintChute &&
          z.assignedBarrier == SafetyBarrierSystemType.none,
    );
    final hasCriticalCliffViolation = zones.any(
      (z) =>
          z.zoneType == CourseHazardZoneType.alpineCliffDropoff &&
          z.assignedBarrier == SafetyBarrierSystemType.none,
    );

    if (hasCriticalSprintViolation ||
        hasCriticalCliffViolation ||
        complianceRatio < 0.50 ||
        overallScore < 52.0) {
      grade = SafetyAuditComplianceGrade.criticalFailure;
      fineRisk = 45000;
      prestigeDelta = -4.5;
    } else if (complianceRatio < 1.0 || overallScore < 72.0) {
      grade = SafetyAuditComplianceGrade.substandardWarning;
      fineRisk = 12500;
      prestigeDelta = -1.2;
    } else if (overallScore >= 87.0 &&
        zones.every((z) => z.assignedMarshalDensity != MarshalDeploymentDensity.minimal)) {
      grade = SafetyAuditComplianceGrade.safeRGoldCertified;
      fineRisk = 0;
      prestigeDelta = 2.4;
    } else {
      grade = SafetyAuditComplianceGrade.uciCompliant;
      fineRisk = 0;
      prestigeDelta = 0.8;
    }

    final cpaApproval = (overallScore * 0.78 + complianceRatio * 22.0).clamp(15.0, 100.0);

    return CourseSafetyAuditReport(
      raceId: raceId,
      raceName: raceName,
      stageNumber: stageNumber,
      totalZones: zones.length,
      uciCompliantZones: compliantCount,
      overallSafetyScore: overallScore,
      averageCrashRiskPct: avgRisk,
      injurySeverityReductionPct: avgReduction,
      totalDeploymentCostEur: totalCost,
      totalMarshalsAssigned: totalMarshals,
      totalBoplanUnitsUsed: totalBoplan,
      totalCatchNetMetersUsed: totalCatchNet,
      totalLedTotemsUsed: totalLedTotems,
      complianceGrade: grade,
      uciFineRiskEur: fineRisk,
      prestigeDelta: prestigeDelta,
      cpaRiderApprovalScore: cpaApproval,
      criticalWarnings: warnings,
      recommendations: recommendations,
    );
  }

  /// Automatycznie dobiera optymalny układ barier Boplan, siatek i marshali w ramach limitu budżetu.
  List<CourseHazardZone> autoOptimizeSafeRDeployment({
    required List<CourseHazardZone> zones,
    required int maxBudgetEur,
    bool prioritizeFinishAndDescents = true,
  }) {
    if (zones.isEmpty) return const [];

    // Krok 1: Sortujemy indeksy stref wg priorytetu ryzyka i znaczenia dla UCI SafeR.
    final indexed = List.generate(zones.length, (i) => i);
    indexed.sort((a, b) {
      final za = zones[a];
      final zb = zones[b];
      final scoreA = za.baselineHazardRisk +
          (prioritizeFinishAndDescents && za.zoneType.requiresHighEnergyAbsorption
              ? 35.0
              : 0.0);
      final scoreB = zb.baselineHazardRisk +
          (prioritizeFinishAndDescents && zb.zoneType.requiresHighEnergyAbsorption
              ? 35.0
              : 0.0);
      return scoreB.compareTo(scoreA);
    });

    // Krok 2: Startujemy z bazowej bezpiecznej konfiguracji minimalnej.
    final working = zones
        .map(
          (z) => z.copyWith(
            assignedBarrier: SafetyBarrierSystemType.standardMetalCrowds,
            assignedMarshalDensity: MarshalDeploymentDensity.standard,
            hasLedWarningTotem: false,
          ),
        )
        .toList();

    int currentTotalCost() =>
        working.fold<int>(0, (sum, z) => sum + z.deploymentCostEur);

    // Krok 3: Ulepszamy strefy od najwyższego priorytetu, dopóki mieścimy się w budżecie.
    for (final idx in indexed) {
      final zone = working[idx];
      final SafetyBarrierSystemType targetBarrier;
      switch (zone.zoneType) {
        case CourseHazardZoneType.finalSprintChute:
        case CourseHazardZoneType.roundaboutTrafficIsland:
        case CourseHazardZoneType.cobbleSectorApproach:
        case CourseHazardZoneType.railwayOrBridgeBottleneck:
          targetBarrier = SafetyBarrierSystemType.boplanAirCushion;
          break;
        case CourseHazardZoneType.alpineCliffDropoff:
        case CourseHazardZoneType.technicalHairpinDescent:
          targetBarrier = SafetyBarrierSystemType.catchNetAndFoamMattress;
          break;
      }

      final upgradedBarrier = zone.copyWith(assignedBarrier: targetBarrier);
      final deltaBarrier = upgradedBarrier.deploymentCostEur - zone.deploymentCostEur;
      if (currentTotalCost() + deltaBarrier <= maxBudgetEur) {
        working[idx] = upgradedBarrier;
      }
    }

    // Krok 4: Jeśli został budżet, podnosimy gęstość marshali i dodajemy totemy LED na kluczowych punktach.
    for (final idx in indexed) {
      final zone = working[idx];
      final withTotem = zone.copyWith(hasLedWarningTotem: true);
      final deltaTotem = withTotem.deploymentCostEur - zone.deploymentCostEur;
      if (!zone.hasLedWarningTotem &&
          (zone.zoneType == CourseHazardZoneType.roundaboutTrafficIsland ||
              zone.zoneType == CourseHazardZoneType.railwayOrBridgeBottleneck ||
              zone.zoneType == CourseHazardZoneType.finalSprintChute) &&
          currentTotalCost() + deltaTotem <= maxBudgetEur) {
        working[idx] = withTotem;
      }

      final currentZone = working[idx];
      final withProMarshals = currentZone.copyWith(
        assignedMarshalDensity: MarshalDeploymentDensity.uciProSafeR,
      );
      final deltaMarshals =
          withProMarshals.deploymentCostEur - currentZone.deploymentCostEur;
      if (currentTotalCost() + deltaMarshals <= maxBudgetEur) {
        working[idx] = withProMarshals;
      }
    }

    return working;
  }

  /// Księguje koszt planu bezpieczeństwa w budżecie organizatora i aktualizuje oceny wyścigu (#513).
  SafetyPlanLedgerIntegrationResult applySafetyPlanToEmpire({
    required OrganizerBudgetLedger ledger,
    required ManagedRacePortfolioItem race,
    required CourseSafetyAuditReport auditReport,
    required int seasonYear,
  }) {
    final cost = auditReport.totalDeploymentCostEur;
    if (cost > ledger.liquidCashEur) {
      return SafetyPlanLedgerIntegrationResult(
        updatedLedger: ledger,
        updatedRace: race,
        auditReport: auditReport,
        messagePl:
            'Niewystarczająca gotówka (${ledger.liquidCashEur} €) na plan bezpieczeństwa ($cost €).',
      );
    }

    final entry = OrganizerLedgerEntry(
      entryId: 'safety_${race.raceId}_s${auditReport.stageNumber}_$seasonYear',
      description:
          'Plan bezpieczeństwa SafeR (${race.raceName} Etap ${auditReport.stageNumber})',
      category: OrganizerCashflowCategory.safetyAndLogistics,
      amountEur: cost,
      seasonYear: seasonYear,
      relatedRaceId: race.raceId,
    );

    final updatedLedger = ledger.copyWith(
      liquidCashEur: ledger.liquidCashEur - cost,
      totalExpensesYtdEur: ledger.totalExpensesYtdEur + cost,
      recentTransactions: [entry, ...ledger.recentTransactions],
    );

    final newSafetyRating =
        ((race.safetyRatingScore * 0.35) + (auditReport.overallSafetyScore * 0.65))
            .clamp(20.0, 100.0);
    final newCompliance =
        (race.uciComplianceScore + auditReport.prestigeDelta).clamp(30.0, 100.0);

    final updatedRace = race.copyWith(
      safetyRatingScore: newSafetyRating,
      uciComplianceScore: newCompliance,
    );

    return SafetyPlanLedgerIntegrationResult(
      updatedLedger: updatedLedger,
      updatedRace: updatedRace,
      auditReport: auditReport,
      entryRecorded: entry,
      messagePl:
          'Zatwierdzono plan bezpieczeństwa (${auditReport.complianceGrade.displayNamePl}) za $cost €.',
    );
  }
}

/// Stan Riverpod dla planera barier Boplan, siatek i marshali.
class CourseSafetyPlannerState {
  final String raceId;
  final String raceName;
  final int stageNumber;
  final List<CourseHazardZone> zones;
  final String? selectedZoneId;
  final SafetyEquipmentInventory inventory;
  final int budgetCapEur;
  final CourseSafetyAuditReport auditReport;
  final String? lastStatusMessage;

  const CourseSafetyPlannerState({
    required this.raceId,
    required this.raceName,
    required this.stageNumber,
    required this.zones,
    required this.selectedZoneId,
    required this.inventory,
    required this.budgetCapEur,
    required this.auditReport,
    this.lastStatusMessage,
  });

  CourseHazardZone? get selectedZone {
    if (zones.isEmpty) return null;
    if (selectedZoneId == null) return zones.first;
    return zones.firstWhere(
      (z) => z.zoneId == selectedZoneId,
      orElse: () => zones.first,
    );
  }

  CourseSafetyPlannerState copyWith({
    String? raceId,
    String? raceName,
    int? stageNumber,
    List<CourseHazardZone>? zones,
    String? selectedZoneId,
    SafetyEquipmentInventory? inventory,
    int? budgetCapEur,
    CourseSafetyAuditReport? auditReport,
    String? lastStatusMessage,
  }) {
    return CourseSafetyPlannerState(
      raceId: raceId ?? this.raceId,
      raceName: raceName ?? this.raceName,
      stageNumber: stageNumber ?? this.stageNumber,
      zones: zones ?? this.zones,
      selectedZoneId: selectedZoneId ?? this.selectedZoneId,
      inventory: inventory ?? this.inventory,
      budgetCapEur: budgetCapEur ?? this.budgetCapEur,
      auditReport: auditReport ?? this.auditReport,
      lastStatusMessage: lastStatusMessage,
    );
  }
}

class CourseSafetyPlannerNotifier extends StateNotifier<CourseSafetyPlannerState> {
  final CourseSafetyBarriersAndMarshalsPlanner _planner;

  CourseSafetyPlannerNotifier({
    CourseSafetyBarriersAndMarshalsPlanner planner =
        const CourseSafetyBarriersAndMarshalsPlanner(),
  })  : _planner = planner,
        super(_buildInitialState(planner));

  static CourseSafetyPlannerState _buildInitialState(
    CourseSafetyBarriersAndMarshalsPlanner planner,
  ) {
    final zones = CourseSafetyBarriersAndMarshalsPlanner.createDefaultStageHazardZones();
    final inventory = CourseSafetyBarriersAndMarshalsPlanner.createDefaultInventory();
    const budgetCap = 95000;
    final report = planner.auditCourseSafety(
      raceId: 'race_grande_boucle_2uwt',
      raceName: 'Tour de France',
      stageNumber: 14,
      zones: zones,
      inventory: inventory,
      availableBudgetEur: budgetCap,
    );
    return CourseSafetyPlannerState(
      raceId: 'race_grande_boucle_2uwt',
      raceName: 'Tour de France',
      stageNumber: 14,
      zones: zones,
      selectedZoneId: zones.last.zoneId,
      inventory: inventory,
      budgetCapEur: budgetCap,
      auditReport: report,
    );
  }

  void _recalculate(
    List<CourseHazardZone> updatedZones, {
    int? budgetCapEur,
    String? statusMessage,
  }) {
    final cap = budgetCapEur ?? state.budgetCapEur;
    final report = _planner.auditCourseSafety(
      raceId: state.raceId,
      raceName: state.raceName,
      stageNumber: state.stageNumber,
      zones: updatedZones,
      inventory: state.inventory,
      availableBudgetEur: cap,
    );
    state = state.copyWith(
      zones: updatedZones,
      budgetCapEur: cap,
      auditReport: report,
      lastStatusMessage: statusMessage,
    );
  }

  void selectZone(String zoneId) {
    state = state.copyWith(selectedZoneId: zoneId, lastStatusMessage: null);
  }

  void updateZoneBarrier(String zoneId, SafetyBarrierSystemType barrier) {
    final updated = state.zones
        .map((z) => z.zoneId == zoneId ? z.copyWith(assignedBarrier: barrier) : z)
        .toList();
    _recalculate(
      updated,
      statusMessage: 'Zaktualizowano system barier: ${barrier.displayNamePl}.',
    );
  }

  void updateZoneMarshals(String zoneId, MarshalDeploymentDensity density) {
    final updated = state.zones
        .map(
          (z) => z.zoneId == zoneId
              ? z.copyWith(assignedMarshalDensity: density)
              : z,
        )
        .toList();
    _recalculate(
      updated,
      statusMessage: 'Zmieniono obstawę marshali: ${density.displayNamePl}.',
    );
  }

  void toggleZoneLedTotem(String zoneId) {
    final updated = state.zones
        .map(
          (z) => z.zoneId == zoneId
              ? z.copyWith(hasLedWarningTotem: !z.hasLedWarningTotem)
              : z,
        )
        .toList();
    _recalculate(
      updated,
      statusMessage: 'Przełączono totem ostrzegawczy LED w strefie.',
    );
  }

  void setBudgetCap(int budgetCapEur) {
    final clamped = budgetCapEur.clamp(25000, 250000);
    _recalculate(state.zones, budgetCapEur: clamped);
  }

  void applyAutoSafeROptimization() {
    final optimized = _planner.autoOptimizeSafeRDeployment(
      zones: state.zones,
      maxBudgetEur: state.budgetCapEur,
    );
    _recalculate(
      optimized,
      statusMessage:
          'Zastosowano automatyczną optymalizację UCI SafeR w ramach budżetu.',
    );
  }

  void resetToBaseline() {
    final baseline =
        CourseSafetyBarriersAndMarshalsPlanner.createDefaultStageHazardZones();
    _recalculate(
      baseline,
      statusMessage: 'Przywrócono bazowy układ zabezpieczeń etapu.',
    );
  }
}

final courseSafetyPlannerProvider =
    StateNotifierProvider<CourseSafetyPlannerNotifier, CourseSafetyPlannerState>(
  (ref) => CourseSafetyPlannerNotifier(),
);

/// Główny panel UI planowania barier ochronnych (`Boplan Air-Cushion Barriers`), siatek i marshali.
class CourseSafetyBarriersAndMarshalsPanel extends ConsumerStatefulWidget {
  final VoidCallback? onPlanApproved;

  const CourseSafetyBarriersAndMarshalsPanel({
    super.key,
    this.onPlanApproved,
  });

  @override
  ConsumerState<CourseSafetyBarriersAndMarshalsPanel> createState() =>
      _CourseSafetyBarriersAndMarshalsPanelState();
}

class _CourseSafetyBarriersAndMarshalsPanelState
    extends ConsumerState<CourseSafetyBarriersAndMarshalsPanel> {
  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(courseSafetyPlannerProvider);
    final notifier = ref.read(courseSafetyPlannerProvider.notifier);
    final report = state.auditReport;
    final selectedZone = state.selectedZone;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;
          final isWideDesktop = constraints.maxWidth >= 1180;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, report, notifier, isMobile),
                const SizedBox(height: 16),
                _buildRouteSafetyProfileCard(state, notifier, isMobile),
                const SizedBox(height: 16),
                if (isWideDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildZonesListCard(state, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            if (selectedZone != null)
                              _buildZoneConfiguratorCard(
                                selectedZone,
                                notifier,
                                isMobile,
                              ),
                            const SizedBox(height: 16),
                            _buildAuditSummaryCard(state, report),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildZonesListCard(state, notifier),
                  const SizedBox(height: 16),
                  if (selectedZone != null)
                    _buildZoneConfiguratorCard(
                      selectedZone,
                      notifier,
                      isMobile,
                    ),
                  const SizedBox(height: 16),
                  _buildAuditSummaryCard(state, report),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    CourseSafetyPlannerState state,
    CourseSafetyAuditReport report,
    CourseSafetyPlannerNotifier notifier,
    bool isMobile,
  ) {
    final gradeColor = _gradeColor(report.complianceGrade);

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 540,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryAccent),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.goldAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planer Barier Boplan, Siatek i Marshali',
                            style: _baseInter.copyWith(
                              fontSize: isMobile ? 16 : 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${state.raceName} • Etap ${state.stageNumber} • Protokół UCI SafeR',
                            style: _baseInter.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gradeColor),
                ),
                child: Text(
                  report.complianceGrade.displayNamePl,
                  style: _baseInter.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gradeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                label: 'Indeks SafeR',
                value: '${report.overallSafetyScore.toStringAsFixed(1)}/100',
                accentColor: gradeColor,
              ),
              _MetricPill(
                label: 'Koszt / Limit',
                value:
                    '${_formatEur(report.totalDeploymentCostEur)} / ${_formatEur(state.budgetCapEur)}',
                accentColor: report.totalDeploymentCostEur > state.budgetCapEur
                    ? AppColors.crimsonAlert
                    : AppColors.accentBlue,
              ),
              _MetricPill(
                label: 'Boplan Units',
                value:
                    '${report.totalBoplanUnitsUsed}/${state.inventory.boplanAirCushionUnits}',
                accentColor: AppColors.goldAccent,
              ),
              _MetricPill(
                label: 'Marshale',
                value:
                    '${report.totalMarshalsAssigned}/${state.inventory.trainedMarshalsPool}',
                accentColor: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InteractiveActionButton(
                label: 'Auto-Optymalizacja SafeR',
                icon: Icons.auto_fix_high,
                accentColor: AppColors.goldAccent,
                isPrimary: true,
                onPressed: notifier.applyAutoSafeROptimization,
              ),
              _InteractiveActionButton(
                label: 'Resetuj Układ',
                icon: Icons.restart_alt,
                accentColor: AppColors.textSecondary,
                onPressed: notifier.resetToBaseline,
              ),
              _InteractiveActionButton(
                label: 'Zatwierdź Plan',
                icon: Icons.verified_outlined,
                accentColor: AppColors.statusSuccess,
                enabled: report.isReadyForStart && widget.onPlanApproved != null,
                onPressed: widget.onPlanApproved,
              ),
            ],
          ),
          if (state.lastStatusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              state.lastStatusMessage!,
              style: _baseInter.copyWith(
                fontSize: 12,
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteSafetyProfileCard(
    CourseSafetyPlannerState state,
    CourseSafetyPlannerNotifier notifier,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                size: 18,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mapa Stref Zagrożenia na Trasie (KM 0 – 176)',
                  style: _baseInter.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(
              painter: CourseSafetyProfilePainter(
                zones: state.zones,
                selectedZoneId: state.selectedZoneId,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.zones.map((zone) {
              final isSelected = zone.zoneId == state.selectedZone?.zoneId;
              return _InteractiveZoneChip(
                label: 'KM ${zone.kilometerMark.toStringAsFixed(0)} ${zone.zoneType.shortTag}',
                isSelected: isSelected,
                isCompliant: zone.isUciMinimumMet,
                onTap: () => notifier.selectZone(zone.zoneId),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesListCard(
    CourseSafetyPlannerState state,
    CourseSafetyPlannerNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strefy Krytyczne Etapu (${state.zones.length})',
            style: _baseInter.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...state.zones.map((zone) {
            final isSelected = zone.zoneId == state.selectedZone?.zoneId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HazardZoneListTile(
                zone: zone,
                isSelected: isSelected,
                onTap: () => notifier.selectZone(zone.zoneId),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildZoneConfiguratorCard(
    CourseHazardZone zone,
    CourseSafetyPlannerNotifier notifier,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: _baseInter.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'KM ${zone.kilometerMark.toStringAsFixed(1)} • ${zone.lengthMeters} m • Prędkość ~${zone.expectedPelotonSpeedKmh.toStringAsFixed(0)} km/h',
                      style: _baseInter.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (zone.isUciMinimumMet
                          ? AppColors.statusSuccess
                          : AppColors.amberWarning)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: zone.isUciMinimumMet
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                  ),
                ),
                child: Text(
                  zone.isUciMinimumMet ? 'Norma UCI OK' : 'Wymaga Poprawy',
                  style: _baseInter.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: zone.isUciMinimumMet
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '1. System Barier Ochronnych / Siatek',
            style: _baseInter.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...SafetyBarrierSystemType.values.map((barrier) {
            final isSelected = zone.assignedBarrier == barrier;
            final effPct = (barrier.effectivenessForZone(zone.zoneType) * 100)
                .round();
            final estCost = (zone.lengthMeters * barrier.costPerMeterEur).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SelectableOptionCard(
                title: barrier.displayNamePl,
                subtitle: 'Skuteczność absorpcji: $effPct% • Bariery: ${_formatEur(estCost)}',
                isSelected: isSelected,
                accentColor: barrier == SafetyBarrierSystemType.boplanAirCushion
                    ? AppColors.goldAccent
                    : AppColors.accentBlue,
                onTap: () => notifier.updateZoneBarrier(zone.zoneId, barrier),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(
            '2. Obsada Marshali i Sygnalizacja',
            style: _baseInter.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MarshalDeploymentDensity.values.map((density) {
              final isSelected = zone.assignedMarshalDensity == density;
              return _InteractiveZoneChip(
                label: density.displayNamePl,
                isSelected: isSelected,
                isCompliant: density != MarshalDeploymentDensity.minimal,
                onTap: () => notifier.updateZoneMarshals(zone.zoneId, density),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _SelectableOptionCard(
            title: 'Totem Ostrzegawczy LED + Syrena Akustyczna',
            subtitle: 'Redukuje ryzyko kolizji z wysepkami (+8% ochrony, +1 450 €)',
            isSelected: zone.hasLedWarningTotem,
            accentColor: AppColors.cyanAccent,
            onTap: () => notifier.toggleZoneLedTotem(zone.zoneId),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetricPill(
                label: 'Ryzyko Rezydualne',
                value: '${zone.residualCrashRisk.toStringAsFixed(1)}%',
                accentColor: zone.residualCrashRisk > 35
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
              ),
              _MetricPill(
                label: 'Redukcja Urazów',
                value: '-${zone.severityReductionPct.toStringAsFixed(0)}%',
                accentColor: AppColors.accentBlue,
              ),
              _MetricPill(
                label: 'Koszt Strefy',
                value: _formatEur(zone.deploymentCostEur),
                accentColor: AppColors.goldAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSummaryCard(
    CourseSafetyPlannerState state,
    CourseSafetyAuditReport report,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audyt Komisji UCI SafeR & Związek Zawodowy CPA',
            style: _baseInter.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                label: 'Aprobata CPA',
                value: '${report.cpaRiderApprovalScore.toStringAsFixed(0)}%',
                accentColor: AppColors.statusSuccess,
              ),
              _MetricPill(
                label: 'Siatki Asekuracyjne',
                value:
                    '${report.totalCatchNetMetersUsed}/${state.inventory.catchNetMeters} m',
                accentColor: AppColors.accentBlue,
              ),
              _MetricPill(
                label: 'Ryzyko Kary UCI',
                value: _formatEur(report.uciFineRiskEur),
                accentColor: report.uciFineRiskEur > 0
                    ? AppColors.crimsonAlert
                    : AppColors.statusSuccess,
              ),
            ],
          ),
          if (report.criticalWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...report.criticalWarnings.take(3).map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.crimsonAlert,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            w,
                            style: _baseInter.copyWith(
                              fontSize: 12,
                              color: AppColors.crimsonAlert,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (report.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...report.recommendations.take(3).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 15,
                          color: AppColors.goldAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r,
                            style: _baseInter.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Color _gradeColor(SafetyAuditComplianceGrade grade) {
    switch (grade) {
      case SafetyAuditComplianceGrade.criticalFailure:
        return AppColors.crimsonAlert;
      case SafetyAuditComplianceGrade.substandardWarning:
        return AppColors.amberWarning;
      case SafetyAuditComplianceGrade.uciCompliant:
        return AppColors.statusSuccess;
      case SafetyAuditComplianceGrade.safeRGoldCertified:
        return AppColors.goldAccent;
    }
  }

  static String _formatEur(int amount) {
    final s = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final revIdx = s.length - i;
      buffer.write(s[i]);
      if (revIdx > 1 && revIdx % 3 == 1) {
        buffer.write(' ');
      }
    }
    return '${amount < 0 ? '-' : ''}${buffer.toString()} €';
  }
}

/// Rysuje schemat trasy z punktami stref zagrożenia, poziomem ryzyka i statusem Boplan/Siatek.
class CourseSafetyProfilePainter extends CustomPainter {
  final List<CourseHazardZone> zones;
  final String? selectedZoneId;

  const CourseSafetyProfilePainter({
    required this.zones,
    this.selectedZoneId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final baselineY = size.height * 0.65;
    canvas.drawLine(
      Offset(16, baselineY),
      Offset(size.width - 16, baselineY),
      trackPaint,
    );

    if (zones.isEmpty) return;
    final maxKm = math.max(
      180.0,
      zones.map((z) => z.kilometerMark).reduce(math.max),
    );

    for (final zone in zones) {
      final ratio = (zone.kilometerMark / maxKm).clamp(0.0, 1.0);
      final x = 16 + ratio * (size.width - 32);
      final isSelected = zone.zoneId == selectedZoneId;

      final barColor = zone.isUciMinimumMet
          ? (zone.assignedBarrier == SafetyBarrierSystemType.boplanAirCushion
              ? AppColors.goldAccent
              : AppColors.statusSuccess)
          : AppColors.crimsonAlert;

      final riskHeight = (zone.residualCrashRisk / 100.0) * (baselineY - 14);
      final barPaint = Paint()
        ..color = barColor.withValues(alpha: isSelected ? 0.95 : 0.68)
        ..strokeWidth = isSelected ? 8.0 : 5.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, baselineY),
        Offset(x, baselineY - riskHeight),
        barPaint,
      );

      if (isSelected) {
        final ringPaint = Paint()
          ..color = AppColors.goldAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset(x, baselineY), 8.0, ringPaint);
      }

      final dotPaint = Paint()..color = barColor;
      canvas.drawCircle(Offset(x, baselineY), 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CourseSafetyProfilePainter oldDelegate) {
    return oldDelegate.zones != zones ||
        oldDelegate.selectedZoneId != selectedZoneId;
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MetricPill({
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
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
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
  final Color accentColor;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.isPrimary = false,
    this.enabled = true,
    this.onPressed,
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
    final isDisabled = !widget.enabled || widget.onPressed == null;
    final bgColor = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isPrimary
            ? widget.accentColor.withValues(alpha: _pressed ? 0.34 : _hovered ? 0.28 : 0.2)
            : AppColors.surfaceLight.withValues(alpha: _hovered ? 0.95 : 0.75);
    final borderColor = isDisabled
        ? AppColors.cardBorder
        : _focused
            ? AppColors.goldAccent
            : _hovered
                ? widget.accentColor
                : widget.isPrimary
                    ? widget.accentColor.withValues(alpha: 0.75)
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
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
                color: isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : widget.accentColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDisabled
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.textPrimary,
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

class _InteractiveZoneChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isCompliant;
  final VoidCallback onTap;

  const _InteractiveZoneChip({
    required this.label,
    required this.isSelected,
    required this.isCompliant,
    required this.onTap,
  });

  @override
  State<_InteractiveZoneChip> createState() => _InteractiveZoneChipState();
}

class _InteractiveZoneChipState extends State<_InteractiveZoneChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        widget.isCompliant ? AppColors.statusSuccess : AppColors.amberWarning;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withValues(alpha: 0.2)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.isSelected
                      ? activeColor
                      : AppColors.cardBorder,
              width: widget.isSelected || _focused ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: widget.isSelected ? activeColor : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HazardZoneListTile extends StatefulWidget {
  final CourseHazardZone zone;
  final bool isSelected;
  final VoidCallback onTap;

  const _HazardZoneListTile({
    required this.zone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_HazardZoneListTile> createState() => _HazardZoneListTileState();
}

class _HazardZoneListTileState extends State<_HazardZoneListTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.zone.isUciMinimumMet
        ? AppColors.statusSuccess
        : AppColors.crimsonAlert;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.65)
                    : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.isSelected
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
              width: widget.isSelected || _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.zone.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'KM ${widget.zone.kilometerMark.toStringAsFixed(1)} • ${widget.zone.assignedBarrier.shortTag} • ${widget.zone.marshalCount} marshali',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.zone.residualCrashRisk.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableOptionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _SelectableOptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_SelectableOptionCard> createState() => _SelectableOptionCardState();
}

class _SelectableOptionCardState extends State<_SelectableOptionCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.14)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.isSelected
                      ? widget.accentColor
                      : AppColors.cardBorder,
              width: widget.isSelected || _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: widget.isSelected
                    ? widget.accentColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
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
            ],
          ),
        ),
      ),
    );
  }
}
