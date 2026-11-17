import 'dart:math' as math;

import '../equipment/frame_model.dart';
import 'bike_manufacturer_deal.dart';

/// Poziom infrastruktury produkcyjno-badawczej własnej marki rowerowej klubu.
enum ManufacturingFacilityTier {
  /// Warsztat prototypowy Skunkworks: małe serie, 1 licencja zewnętrzna.
  skunkworksWorkshop,

  /// Manufaktura karbonu z własnym autoklawem: do 3 licencji zewnętrznych.
  carbonBoutiqueLab,

  /// Fabryka R&D poziomu WorldTour z tunelem CFD: do 6 licencji zewnętrznych.
  worldTourRdFactory,

  /// Globalny producent OEM ze sprzedażą detaliczną: do 12 licencji zewnętrznych.
  globalOemPowerhouse;

  String toJson() => name;

  static ManufacturingFacilityTier fromJson(String value) {
    return ManufacturingFacilityTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ManufacturingFacilityTier.skunkworksWorkshop,
    );
  }

  String get displayNamePl {
    switch (this) {
      case ManufacturingFacilityTier.skunkworksWorkshop:
        return 'Warsztat Prototypowy Skunkworks';
      case ManufacturingFacilityTier.carbonBoutiqueLab:
        return 'Manufaktura Karbonu (Autoklaw)';
      case ManufacturingFacilityTier.worldTourRdFactory:
        return 'Fabryka R&D WorldTour (Tunel CFD)';
      case ManufacturingFacilityTier.globalOemPowerhouse:
        return 'Globalny Producent OEM & Retail';
    }
  }

  String get displayNameEn {
    switch (this) {
      case ManufacturingFacilityTier.skunkworksWorkshop:
        return 'Skunkworks Prototype Workshop';
      case ManufacturingFacilityTier.carbonBoutiqueLab:
        return 'Carbon Boutique Lab';
      case ManufacturingFacilityTier.worldTourRdFactory:
        return 'WorldTour R&D Factory';
      case ManufacturingFacilityTier.globalOemPowerhouse:
        return 'Global OEM Powerhouse';
    }
  }

  int get maxExternalLicenses {
    switch (this) {
      case ManufacturingFacilityTier.skunkworksWorkshop:
        return 1;
      case ManufacturingFacilityTier.carbonBoutiqueLab:
        return 3;
      case ManufacturingFacilityTier.worldTourRdFactory:
        return 6;
      case ManufacturingFacilityTier.globalOemPowerhouse:
        return 12;
    }
  }

  int get annualFrameCapacity {
    switch (this) {
      case ManufacturingFacilityTier.skunkworksWorkshop:
        return 140;
      case ManufacturingFacilityTier.carbonBoutiqueLab:
        return 420;
      case ManufacturingFacilityTier.worldTourRdFactory:
        return 1200;
      case ManufacturingFacilityTier.globalOemPowerhouse:
        return 4500;
    }
  }

  int get quarterlyFixedOpexEur {
    switch (this) {
      case ManufacturingFacilityTier.skunkworksWorkshop:
        return 65000;
      case ManufacturingFacilityTier.carbonBoutiqueLab:
        return 185000;
      case ManufacturingFacilityTier.worldTourRdFactory:
        return 460000;
      case ManufacturingFacilityTier.globalOemPowerhouse:
        return 1150000;
    }
  }

  int get upgradeCostEur {
    switch (this) {
      case ManufacturingFacilityTier.skunkworksWorkshop:
        return 350000;
      case ManufacturingFacilityTier.carbonBoutiqueLab:
        return 1200000;
      case ManufacturingFacilityTier.worldTourRdFactory:
        return 3400000;
      case ManufacturingFacilityTier.globalOemPowerhouse:
        return 7500000;
    }
  }

  double get retailMultiplier {
    switch (this) {
      case ManufacturingFacilityTier.skunkworksWorkshop:
        return 0.15;
      case ManufacturingFacilityTier.carbonBoutiqueLab:
        return 0.45;
      case ManufacturingFacilityTier.worldTourRdFactory:
        return 1.0;
      case ManufacturingFacilityTier.globalOemPowerhouse:
        return 2.4;
    }
  }
}

/// Klasa włókna węglowego stosowanego w laminacie ramy.
enum CarbonLayupGrade {
  standardModulusT700,
  highModulusT800,
  ultraHighModulusT1100,
  aerospacePitchFiber;

  String toJson() => name;

  static CarbonLayupGrade fromJson(String value) {
    return CarbonLayupGrade.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CarbonLayupGrade.highModulusT800,
    );
  }

  String get displayNamePl {
    switch (this) {
      case CarbonLayupGrade.standardModulusT700:
        return 'Toray T700 Standard';
      case CarbonLayupGrade.highModulusT800:
        return 'Toray T800 High-Modulus';
      case CarbonLayupGrade.ultraHighModulusT1100:
        return 'Toray T1100G Ultra-HM';
      case CarbonLayupGrade.aerospacePitchFiber:
        return 'Włókno Pitch + Grafen R&D';
    }
  }

  double get manufacturingCostMultiplier {
    switch (this) {
      case CarbonLayupGrade.standardModulusT700:
        return 0.80;
      case CarbonLayupGrade.highModulusT800:
        return 1.00;
      case CarbonLayupGrade.ultraHighModulusT1100:
        return 1.35;
      case CarbonLayupGrade.aerospacePitchFiber:
        return 1.85;
    }
  }

  double get stiffnessBonus {
    switch (this) {
      case CarbonLayupGrade.standardModulusT700:
        return 0.0;
      case CarbonLayupGrade.highModulusT800:
        return 0.12;
      case CarbonLayupGrade.ultraHighModulusT1100:
        return 0.25;
      case CarbonLayupGrade.aerospacePitchFiber:
        return 0.38;
    }
  }
}

/// Kierunek prac badawczo-rozwojowych (R&D) nad projektem ramy.
enum RdProjectFocus {
  aeroTubeProfiles,
  ultralightLayup,
  bbStiffnessTransfer,
  cobbleIsoCompliance;

  String toJson() => name;

  static RdProjectFocus fromJson(String value) {
    return RdProjectFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RdProjectFocus.aeroTubeProfiles,
    );
  }

  String get displayNamePl {
    switch (this) {
      case RdProjectFocus.aeroTubeProfiles:
        return 'Profile Aero & Tunel CFD';
      case RdProjectFocus.ultralightLayup:
        return 'Optymalizacja Masy Laminatu';
      case RdProjectFocus.bbStiffnessTransfer:
        return 'Sztywność Suportu i Transfer Mocy';
      case RdProjectFocus.cobbleIsoCompliance:
        return 'Tłumienie Drgań Iso-Compliance';
    }
  }
}

/// Status projektu R&D nad nową generacją ramy.
enum RdProjectStatus {
  queued,
  inProgress,
  windTunnelValidation,
  homologated,
  cancelled;

  String toJson() => name;

  static RdProjectStatus fromJson(String value) {
    return RdProjectStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RdProjectStatus.queued,
    );
  }
}

/// Status kontraktu licencyjnego i dostaw sprzętu dla zewnętrznej ekipy.
enum BrandLicenseDealStatus {
  negotiating,
  active,
  expiring,
  terminated;

  String toJson() => name;

  static BrandLicenseDealStatus fromJson(String value) {
    return BrandLicenseDealStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BrandLicenseDealStatus.active,
    );
  }
}

/// Segment docelowy odbiorcy sprzętu produkowanego przez markę klubu.
enum TeamFrameTargetDivision {
  worldTour,
  proTeam,
  continental,
  retailConsumer;

  String toJson() => name;

  static TeamFrameTargetDivision fromJson(String value) {
    return TeamFrameTargetDivision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TeamFrameTargetDivision.proTeam,
    );
  }

  String get displayNamePl {
    switch (this) {
      case TeamFrameTargetDivision.worldTour:
        return 'UCI WorldTeam';
      case TeamFrameTargetDivision.proTeam:
        return 'UCI ProTeam';
      case TeamFrameTargetDivision.continental:
        return 'UCI Continental';
      case TeamFrameTargetDivision.retailConsumer:
        return 'Rynek Detaliczny (Konsumenci)';
    }
  }
}

/// Projekt techniczny (blueprint) własnej ramy produkowanej przez zespół.
class InHouseFrameBlueprint {
  final String blueprintId;
  final String modelName;
  final FrameCategory category;
  final CarbonLayupGrade carbonGrade;
  final int weightGrams;
  final double aeroCdaModifier;
  final double stiffnessToWeightIndex;
  final double comfortCompliance;
  final int unitManufacturingCostEur;
  final int wholesalePriceEur;
  final int retailMsrpEur;
  final bool uciHomologated;
  final int rdGeneration;
  final String primaryColorHex;
  final String mesh3dAssetPath;

  const InHouseFrameBlueprint({
    required this.blueprintId,
    required this.modelName,
    required this.category,
    required this.carbonGrade,
    required this.weightGrams,
    required this.aeroCdaModifier,
    required this.stiffnessToWeightIndex,
    required this.comfortCompliance,
    required this.unitManufacturingCostEur,
    required this.wholesalePriceEur,
    required this.retailMsrpEur,
    required this.uciHomologated,
    required this.rdGeneration,
    required this.primaryColorHex,
    required this.mesh3dAssetPath,
  });

  /// Marża hurtowa (sprzedaż ram innym ekipom) na jednej sztuce w EUR.
  int get wholesaleGrossMarginEur => wholesalePriceEur - unitManufacturingCostEur;

  /// Marża detaliczna (sprzedaż konsumentom) na jednej sztuce w EUR.
  int get retailGrossMarginEur => retailMsrpEur - unitManufacturingCostEur;

  /// Konwertuje blueprint na standardowy model [FrameModel] używany w wyścigach 3D i fizyce.
  FrameModel toFrameModel(String brandId) {
    return FrameModel(
      id: blueprintId,
      brandId: brandId,
      name: modelName,
      category: category,
      weightGrams: weightGrams,
      aeroCdaModifier: aeroCdaModifier,
      stiffnessToWeightIndex: stiffnessToWeightIndex,
      comfortCompliance: comfortCompliance,
      priceEur: retailMsrpEur,
      mesh3dAssetPath: mesh3dAssetPath,
      primaryColorHex: primaryColorHex,
    );
  }

  InHouseFrameBlueprint copyWith({
    String? blueprintId,
    String? modelName,
    FrameCategory? category,
    CarbonLayupGrade? carbonGrade,
    int? weightGrams,
    double? aeroCdaModifier,
    double? stiffnessToWeightIndex,
    double? comfortCompliance,
    int? unitManufacturingCostEur,
    int? wholesalePriceEur,
    int? retailMsrpEur,
    bool? uciHomologated,
    int? rdGeneration,
    String? primaryColorHex,
    String? mesh3dAssetPath,
  }) {
    return InHouseFrameBlueprint(
      blueprintId: blueprintId ?? this.blueprintId,
      modelName: modelName ?? this.modelName,
      category: category ?? this.category,
      carbonGrade: carbonGrade ?? this.carbonGrade,
      weightGrams: weightGrams ?? this.weightGrams,
      aeroCdaModifier: aeroCdaModifier ?? this.aeroCdaModifier,
      stiffnessToWeightIndex: stiffnessToWeightIndex ?? this.stiffnessToWeightIndex,
      comfortCompliance: comfortCompliance ?? this.comfortCompliance,
      unitManufacturingCostEur: unitManufacturingCostEur ?? this.unitManufacturingCostEur,
      wholesalePriceEur: wholesalePriceEur ?? this.wholesalePriceEur,
      retailMsrpEur: retailMsrpEur ?? this.retailMsrpEur,
      uciHomologated: uciHomologated ?? this.uciHomologated,
      rdGeneration: rdGeneration ?? this.rdGeneration,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      mesh3dAssetPath: mesh3dAssetPath ?? this.mesh3dAssetPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blueprintId': blueprintId,
      'modelName': modelName,
      'category': category.toJson(),
      'carbonGrade': carbonGrade.toJson(),
      'weightGrams': weightGrams,
      'aeroCdaModifier': aeroCdaModifier,
      'stiffnessToWeightIndex': stiffnessToWeightIndex,
      'comfortCompliance': comfortCompliance,
      'unitManufacturingCostEur': unitManufacturingCostEur,
      'wholesalePriceEur': wholesalePriceEur,
      'retailMsrpEur': retailMsrpEur,
      'uciHomologated': uciHomologated,
      'rdGeneration': rdGeneration,
      'primaryColorHex': primaryColorHex,
      'mesh3dAssetPath': mesh3dAssetPath,
    };
  }

  factory InHouseFrameBlueprint.fromJson(Map<String, dynamic> json) {
    return InHouseFrameBlueprint(
      blueprintId: json['blueprintId'] as String,
      modelName: json['modelName'] as String,
      category: FrameCategory.fromJson(json['category'] as String? ?? 'allRounder'),
      carbonGrade: CarbonLayupGrade.fromJson(json['carbonGrade'] as String? ?? 'highModulusT800'),
      weightGrams: (json['weightGrams'] as num).toInt(),
      aeroCdaModifier: (json['aeroCdaModifier'] as num).toDouble(),
      stiffnessToWeightIndex: (json['stiffnessToWeightIndex'] as num).toDouble(),
      comfortCompliance: (json['comfortCompliance'] as num).toDouble(),
      unitManufacturingCostEur: (json['unitManufacturingCostEur'] as num).toInt(),
      wholesalePriceEur: (json['wholesalePriceEur'] as num).toInt(),
      retailMsrpEur: (json['retailMsrpEur'] as num).toInt(),
      uciHomologated: json['uciHomologated'] as bool? ?? false,
      rdGeneration: (json['rdGeneration'] as num?)?.toInt() ?? 1,
      primaryColorHex: json['primaryColorHex'] as String? ?? '#8E4A49',
      mesh3dAssetPath: json['mesh3dAssetPath'] as String? ?? 'assets/3d/bikes/road_pro_frame.glb',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InHouseFrameBlueprint &&
        other.blueprintId == blueprintId &&
        other.modelName == modelName &&
        other.category == category &&
        other.carbonGrade == carbonGrade &&
        other.weightGrams == weightGrams &&
        other.aeroCdaModifier == aeroCdaModifier &&
        other.stiffnessToWeightIndex == stiffnessToWeightIndex &&
        other.comfortCompliance == comfortCompliance &&
        other.unitManufacturingCostEur == unitManufacturingCostEur &&
        other.wholesalePriceEur == wholesalePriceEur &&
        other.retailMsrpEur == retailMsrpEur &&
        other.uciHomologated == uciHomologated &&
        other.rdGeneration == rdGeneration &&
        other.primaryColorHex == primaryColorHex &&
        other.mesh3dAssetPath == mesh3dAssetPath;
  }

  @override
  int get hashCode => Object.hash(
        blueprintId,
        modelName,
        category,
        carbonGrade,
        weightGrams,
        aeroCdaModifier,
        stiffnessToWeightIndex,
        comfortCompliance,
        unitManufacturingCostEur,
        wholesalePriceEur,
        retailMsrpEur,
        uciHomologated,
        rdGeneration,
        primaryColorHex,
        mesh3dAssetPath,
      );
}

/// Projekt badawczo-rozwojowy (R&D) ulepszający wybrany blueprint ramy.
class BrandRdResearchProject {
  final String projectId;
  final String title;
  final String targetBlueprintId;
  final RdProjectFocus focus;
  final RdProjectStatus status;
  final int investedBudgetEur;
  final int totalRequiredBudgetEur;
  final double progressRatio;
  final int expectedWeightDeltaGrams;
  final double expectedCdaDelta;
  final double expectedStiffnessDelta;
  final double expectedComplianceDelta;
  final int estimatedDaysRemaining;

  const BrandRdResearchProject({
    required this.projectId,
    required this.title,
    required this.targetBlueprintId,
    required this.focus,
    required this.status,
    required this.investedBudgetEur,
    required this.totalRequiredBudgetEur,
    required this.progressRatio,
    required this.expectedWeightDeltaGrams,
    required this.expectedCdaDelta,
    required this.expectedStiffnessDelta,
    required this.expectedComplianceDelta,
    required this.estimatedDaysRemaining,
  });

  bool get isCompleted => status == RdProjectStatus.homologated || progressRatio >= 1.0;

  int get remainingBudgetEur => math.max(0, totalRequiredBudgetEur - investedBudgetEur);

  BrandRdResearchProject copyWith({
    String? projectId,
    String? title,
    String? targetBlueprintId,
    RdProjectFocus? focus,
    RdProjectStatus? status,
    int? investedBudgetEur,
    int? totalRequiredBudgetEur,
    double? progressRatio,
    int? expectedWeightDeltaGrams,
    double? expectedCdaDelta,
    double? expectedStiffnessDelta,
    double? expectedComplianceDelta,
    int? estimatedDaysRemaining,
  }) {
    return BrandRdResearchProject(
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      targetBlueprintId: targetBlueprintId ?? this.targetBlueprintId,
      focus: focus ?? this.focus,
      status: status ?? this.status,
      investedBudgetEur: investedBudgetEur ?? this.investedBudgetEur,
      totalRequiredBudgetEur: totalRequiredBudgetEur ?? this.totalRequiredBudgetEur,
      progressRatio: progressRatio ?? this.progressRatio,
      expectedWeightDeltaGrams: expectedWeightDeltaGrams ?? this.expectedWeightDeltaGrams,
      expectedCdaDelta: expectedCdaDelta ?? this.expectedCdaDelta,
      expectedStiffnessDelta: expectedStiffnessDelta ?? this.expectedStiffnessDelta,
      expectedComplianceDelta: expectedComplianceDelta ?? this.expectedComplianceDelta,
      estimatedDaysRemaining: estimatedDaysRemaining ?? this.estimatedDaysRemaining,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'title': title,
      'targetBlueprintId': targetBlueprintId,
      'focus': focus.toJson(),
      'status': status.toJson(),
      'investedBudgetEur': investedBudgetEur,
      'totalRequiredBudgetEur': totalRequiredBudgetEur,
      'progressRatio': progressRatio,
      'expectedWeightDeltaGrams': expectedWeightDeltaGrams,
      'expectedCdaDelta': expectedCdaDelta,
      'expectedStiffnessDelta': expectedStiffnessDelta,
      'expectedComplianceDelta': expectedComplianceDelta,
      'estimatedDaysRemaining': estimatedDaysRemaining,
    };
  }

  factory BrandRdResearchProject.fromJson(Map<String, dynamic> json) {
    return BrandRdResearchProject(
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      targetBlueprintId: json['targetBlueprintId'] as String,
      focus: RdProjectFocus.fromJson(json['focus'] as String? ?? 'aeroTubeProfiles'),
      status: RdProjectStatus.fromJson(json['status'] as String? ?? 'inProgress'),
      investedBudgetEur: (json['investedBudgetEur'] as num).toInt(),
      totalRequiredBudgetEur: (json['totalRequiredBudgetEur'] as num).toInt(),
      progressRatio: (json['progressRatio'] as num).toDouble().clamp(0.0, 1.0),
      expectedWeightDeltaGrams: (json['expectedWeightDeltaGrams'] as num).toInt(),
      expectedCdaDelta: (json['expectedCdaDelta'] as num).toDouble(),
      expectedStiffnessDelta: (json['expectedStiffnessDelta'] as num).toDouble(),
      expectedComplianceDelta: (json['expectedComplianceDelta'] as num).toDouble(),
      estimatedDaysRemaining: (json['estimatedDaysRemaining'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrandRdResearchProject &&
        other.projectId == projectId &&
        other.title == title &&
        other.targetBlueprintId == targetBlueprintId &&
        other.focus == focus &&
        other.status == status &&
        other.investedBudgetEur == investedBudgetEur &&
        other.totalRequiredBudgetEur == totalRequiredBudgetEur &&
        other.progressRatio == progressRatio &&
        other.expectedWeightDeltaGrams == expectedWeightDeltaGrams &&
        other.expectedCdaDelta == expectedCdaDelta &&
        other.expectedStiffnessDelta == expectedStiffnessDelta &&
        other.expectedComplianceDelta == expectedComplianceDelta &&
        other.estimatedDaysRemaining == estimatedDaysRemaining;
  }

  @override
  int get hashCode => Object.hash(
        projectId,
        title,
        targetBlueprintId,
        focus,
        status,
        investedBudgetEur,
        totalRequiredBudgetEur,
        progressRatio,
        expectedWeightDeltaGrams,
        expectedCdaDelta,
        expectedStiffnessDelta,
        expectedComplianceDelta,
        estimatedDaysRemaining,
      );
}

/// Kontrakt licencyjny i dostawy ram podpisany z inną drużyną kolarską.
class ExternalTeamLicenseContract {
  final String contractId;
  final String partnerTeamId;
  final String partnerTeamName;
  final TeamFrameTargetDivision targetDivision;
  final String suppliedBlueprintId;
  final int annualLicenseFeeEur;
  final int framesOrderedPerSeason;
  final int pricePerFrameEur;
  final int royaltyPerWorldTourWinEur;
  final int yearsRemaining;
  final BrandLicenseDealStatus status;
  final double satisfactionScore;

  const ExternalTeamLicenseContract({
    required this.contractId,
    required this.partnerTeamId,
    required this.partnerTeamName,
    required this.targetDivision,
    required this.suppliedBlueprintId,
    required this.annualLicenseFeeEur,
    required this.framesOrderedPerSeason,
    required this.pricePerFrameEur,
    required this.royaltyPerWorldTourWinEur,
    required this.yearsRemaining,
    required this.status,
    required this.satisfactionScore,
  });

  /// Łączna roczna wartość przychodu z licencji i dostaw ram dla tej ekipy.
  int get totalAnnualRevenueEur =>
      annualLicenseFeeEur + (framesOrderedPerSeason * pricePerFrameEur);

  bool get isActive =>
      status == BrandLicenseDealStatus.active || status == BrandLicenseDealStatus.expiring;

  bool get isExpiring => yearsRemaining <= 1 || status == BrandLicenseDealStatus.expiring;

  ExternalTeamLicenseContract copyWith({
    String? contractId,
    String? partnerTeamId,
    String? partnerTeamName,
    TeamFrameTargetDivision? targetDivision,
    String? suppliedBlueprintId,
    int? annualLicenseFeeEur,
    int? framesOrderedPerSeason,
    int? pricePerFrameEur,
    int? royaltyPerWorldTourWinEur,
    int? yearsRemaining,
    BrandLicenseDealStatus? status,
    double? satisfactionScore,
  }) {
    return ExternalTeamLicenseContract(
      contractId: contractId ?? this.contractId,
      partnerTeamId: partnerTeamId ?? this.partnerTeamId,
      partnerTeamName: partnerTeamName ?? this.partnerTeamName,
      targetDivision: targetDivision ?? this.targetDivision,
      suppliedBlueprintId: suppliedBlueprintId ?? this.suppliedBlueprintId,
      annualLicenseFeeEur: annualLicenseFeeEur ?? this.annualLicenseFeeEur,
      framesOrderedPerSeason: framesOrderedPerSeason ?? this.framesOrderedPerSeason,
      pricePerFrameEur: pricePerFrameEur ?? this.pricePerFrameEur,
      royaltyPerWorldTourWinEur: royaltyPerWorldTourWinEur ?? this.royaltyPerWorldTourWinEur,
      yearsRemaining: yearsRemaining ?? this.yearsRemaining,
      status: status ?? this.status,
      satisfactionScore: satisfactionScore ?? this.satisfactionScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'partnerTeamId': partnerTeamId,
      'partnerTeamName': partnerTeamName,
      'targetDivision': targetDivision.toJson(),
      'suppliedBlueprintId': suppliedBlueprintId,
      'annualLicenseFeeEur': annualLicenseFeeEur,
      'framesOrderedPerSeason': framesOrderedPerSeason,
      'pricePerFrameEur': pricePerFrameEur,
      'royaltyPerWorldTourWinEur': royaltyPerWorldTourWinEur,
      'yearsRemaining': yearsRemaining,
      'status': status.toJson(),
      'satisfactionScore': satisfactionScore,
    };
  }

  factory ExternalTeamLicenseContract.fromJson(Map<String, dynamic> json) {
    return ExternalTeamLicenseContract(
      contractId: json['contractId'] as String,
      partnerTeamId: json['partnerTeamId'] as String,
      partnerTeamName: json['partnerTeamName'] as String,
      targetDivision:
          TeamFrameTargetDivision.fromJson(json['targetDivision'] as String? ?? 'proTeam'),
      suppliedBlueprintId: json['suppliedBlueprintId'] as String,
      annualLicenseFeeEur: (json['annualLicenseFeeEur'] as num).toInt(),
      framesOrderedPerSeason: (json['framesOrderedPerSeason'] as num).toInt(),
      pricePerFrameEur: (json['pricePerFrameEur'] as num).toInt(),
      royaltyPerWorldTourWinEur: (json['royaltyPerWorldTourWinEur'] as num?)?.toInt() ?? 0,
      yearsRemaining: (json['yearsRemaining'] as num).toInt(),
      status: BrandLicenseDealStatus.fromJson(json['status'] as String? ?? 'active'),
      satisfactionScore: (json['satisfactionScore'] as num?)?.toDouble() ?? 80.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExternalTeamLicenseContract &&
        other.contractId == contractId &&
        other.partnerTeamId == partnerTeamId &&
        other.partnerTeamName == partnerTeamName &&
        other.targetDivision == targetDivision &&
        other.suppliedBlueprintId == suppliedBlueprintId &&
        other.annualLicenseFeeEur == annualLicenseFeeEur &&
        other.framesOrderedPerSeason == framesOrderedPerSeason &&
        other.pricePerFrameEur == pricePerFrameEur &&
        other.royaltyPerWorldTourWinEur == royaltyPerWorldTourWinEur &&
        other.yearsRemaining == yearsRemaining &&
        other.status == status &&
        other.satisfactionScore == satisfactionScore;
  }

  @override
  int get hashCode => Object.hash(
        contractId,
        partnerTeamId,
        partnerTeamName,
        targetDivision,
        suppliedBlueprintId,
        annualLicenseFeeEur,
        framesOrderedPerSeason,
        pricePerFrameEur,
        royaltyPerWorldTourWinEur,
        yearsRemaining,
        status,
        satisfactionScore,
      );
}

/// Kwartalny raport finansowo-produkcyjny własnej marki rowerowej klubu.
class BrandManufacturingQuarterlyReport {
  final int seasonYear;
  final int quarter;
  final int framesProduced;
  final int framesSoldToTeams;
  final int framesSoldRetail;
  final int licenseRevenueEur;
  final int frameSalesRevenueEur;
  final int retailRevenueEur;
  final int manufacturingCostEur;
  final int rdExpenseEur;
  final int facilityOpexEur;
  final int netProfitEur;
  final double brandPrestigeDelta;

  const BrandManufacturingQuarterlyReport({
    required this.seasonYear,
    required this.quarter,
    required this.framesProduced,
    required this.framesSoldToTeams,
    required this.framesSoldRetail,
    required this.licenseRevenueEur,
    required this.frameSalesRevenueEur,
    required this.retailRevenueEur,
    required this.manufacturingCostEur,
    required this.rdExpenseEur,
    required this.facilityOpexEur,
    required this.netProfitEur,
    required this.brandPrestigeDelta,
  });

  int get totalGrossRevenueEur => licenseRevenueEur + frameSalesRevenueEur + retailRevenueEur;

  int get totalCostsEur => manufacturingCostEur + rdExpenseEur + facilityOpexEur;

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'quarter': quarter,
      'framesProduced': framesProduced,
      'framesSoldToTeams': framesSoldToTeams,
      'framesSoldRetail': framesSoldRetail,
      'licenseRevenueEur': licenseRevenueEur,
      'frameSalesRevenueEur': frameSalesRevenueEur,
      'retailRevenueEur': retailRevenueEur,
      'manufacturingCostEur': manufacturingCostEur,
      'rdExpenseEur': rdExpenseEur,
      'facilityOpexEur': facilityOpexEur,
      'netProfitEur': netProfitEur,
      'brandPrestigeDelta': brandPrestigeDelta,
    };
  }

  factory BrandManufacturingQuarterlyReport.fromJson(Map<String, dynamic> json) {
    return BrandManufacturingQuarterlyReport(
      seasonYear: (json['seasonYear'] as num).toInt(),
      quarter: (json['quarter'] as num).toInt(),
      framesProduced: (json['framesProduced'] as num).toInt(),
      framesSoldToTeams: (json['framesSoldToTeams'] as num).toInt(),
      framesSoldRetail: (json['framesSoldRetail'] as num).toInt(),
      licenseRevenueEur: (json['licenseRevenueEur'] as num).toInt(),
      frameSalesRevenueEur: (json['frameSalesRevenueEur'] as num).toInt(),
      retailRevenueEur: (json['retailRevenueEur'] as num).toInt(),
      manufacturingCostEur: (json['manufacturingCostEur'] as num).toInt(),
      rdExpenseEur: (json['rdExpenseEur'] as num).toInt(),
      facilityOpexEur: (json['facilityOpexEur'] as num).toInt(),
      netProfitEur: (json['netProfitEur'] as num).toInt(),
      brandPrestigeDelta: (json['brandPrestigeDelta'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BrandManufacturingQuarterlyReport &&
        other.seasonYear == seasonYear &&
        other.quarter == quarter &&
        other.framesProduced == framesProduced &&
        other.framesSoldToTeams == framesSoldToTeams &&
        other.framesSoldRetail == framesSoldRetail &&
        other.licenseRevenueEur == licenseRevenueEur &&
        other.frameSalesRevenueEur == frameSalesRevenueEur &&
        other.retailRevenueEur == retailRevenueEur &&
        other.manufacturingCostEur == manufacturingCostEur &&
        other.rdExpenseEur == rdExpenseEur &&
        other.facilityOpexEur == facilityOpexEur &&
        other.netProfitEur == netProfitEur &&
        other.brandPrestigeDelta == brandPrestigeDelta;
  }

  @override
  int get hashCode => Object.hash(
        seasonYear,
        quarter,
        framesProduced,
        framesSoldToTeams,
        framesSoldRetail,
        licenseRevenueEur,
        frameSalesRevenueEur,
        retailRevenueEur,
        manufacturingCostEur,
        rdExpenseEur,
        facilityOpexEur,
        netProfitEur,
        brandPrestigeDelta,
      );
}

/// Wynik operacji na modelu własnej marki rowerowej z ewentualnym komunikatem błędu.
class BrandOperationResult {
  final bool success;
  final String message;
  final InHouseBikeBrandModel model;
  final int cashDeltaEur;

  const BrandOperationResult({
    required this.success,
    required this.message,
    required this.model,
    this.cashDeltaEur = 0,
  });
}

/// Model Własnej Marki Rowerowej Klubu pozwalający przekształcić zespół kolarski
/// w producenta sprzętu R&D sprzedającego licencje i ramy innym ekipom oraz konsumentom.
class InHouseBikeBrandModel {
  final String brandId;
  final String ownerTeamId;
  final String ownerTeamName;
  final String brandName;
  final String brandTagline;
  final String primaryColorHex;
  final String secondaryColorHex;
  final int foundedSeasonYear;
  final ManufacturingFacilityTier facilityTier;
  final double prestigeScore; // 0.0 - 100.0
  final int rdEngineeringLevel; // 1 - 100
  final int framesProducedThisSeason;
  final double retailConsumerDemandIndex; // 0.5 - 2.5
  final int brandEquityValueEur;
  final List<InHouseFrameBlueprint> blueprints;
  final List<BrandRdResearchProject> activeRdProjects;
  final List<ExternalTeamLicenseContract> licenseContracts;
  final List<BrandManufacturingQuarterlyReport> quarterlyReports;

  const InHouseBikeBrandModel({
    required this.brandId,
    required this.ownerTeamId,
    required this.ownerTeamName,
    required this.brandName,
    required this.brandTagline,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.foundedSeasonYear,
    required this.facilityTier,
    required this.prestigeScore,
    required this.rdEngineeringLevel,
    required this.framesProducedThisSeason,
    required this.retailConsumerDemandIndex,
    required this.brandEquityValueEur,
    required this.blueprints,
    required this.activeRdProjects,
    required this.licenseContracts,
    required this.quarterlyReports,
  });

  /// Tworzy startowy model własnej marki rowerowej dla zespołu wchodzącego w produkcję R&D.
  factory InHouseBikeBrandModel.createStarter({
    required String brandId,
    required String ownerTeamId,
    required String ownerTeamName,
    required String brandName,
    required int seasonYear,
    String brandTagline = 'Engineered in the Peloton',
    String primaryColorHex = '#8E4A49',
    String secondaryColorHex = '#D4AF37',
  }) {
    final starterAllRounder = InHouseFrameBlueprint(
      blueprintId: '${brandId}_sl_allrounder',
      modelName: '$brandName SL-01',
      category: FrameCategory.allRounder,
      carbonGrade: CarbonLayupGrade.highModulusT800,
      weightGrams: 745,
      aeroCdaModifier: -0.008,
      stiffnessToWeightIndex: 1.82,
      comfortCompliance: 0.74,
      unitManufacturingCostEur: 1250,
      wholesalePriceEur: 2650,
      retailMsrpEur: 5400,
      uciHomologated: true,
      rdGeneration: 1,
      primaryColorHex: primaryColorHex,
      mesh3dAssetPath: 'assets/3d/bikes/road_pro_frame.glb',
    );

    final starterAero = InHouseFrameBlueprint(
      blueprintId: '${brandId}_aero_v1',
      modelName: '$brandName Aero-X1',
      category: FrameCategory.aero,
      carbonGrade: CarbonLayupGrade.highModulusT800,
      weightGrams: 890,
      aeroCdaModifier: -0.017,
      stiffnessToWeightIndex: 1.94,
      comfortCompliance: 0.58,
      unitManufacturingCostEur: 1420,
      wholesalePriceEur: 2950,
      retailMsrpEur: 6100,
      uciHomologated: true,
      rdGeneration: 1,
      primaryColorHex: primaryColorHex,
      mesh3dAssetPath: 'assets/3d/bikes/aero_pro_frame.glb',
    );

    return InHouseBikeBrandModel(
      brandId: brandId,
      ownerTeamId: ownerTeamId,
      ownerTeamName: ownerTeamName,
      brandName: brandName,
      brandTagline: brandTagline,
      primaryColorHex: primaryColorHex,
      secondaryColorHex: secondaryColorHex,
      foundedSeasonYear: seasonYear,
      facilityTier: ManufacturingFacilityTier.skunkworksWorkshop,
      prestigeScore: 42.0,
      rdEngineeringLevel: 68,
      framesProducedThisSeason: 0,
      retailConsumerDemandIndex: 1.0,
      brandEquityValueEur: 850000,
      blueprints: List<InHouseFrameBlueprint>.unmodifiable([starterAllRounder, starterAero]),
      activeRdProjects: const [],
      licenseContracts: const [],
      quarterlyReports: const [],
    );
  }

  /// Prestiż marki w skali 1-5 gwiazdek dla kompatybilności z systemem sponsorskim.
  int get prestigeStars => ((prestigeScore / 20.0).ceil()).clamp(1, 5);

  /// Maksymalna roczna zdolność produkcyjna ram wynikająca z poziomu fabryki.
  int get annualProductionCapacityFrames => facilityTier.annualFrameCapacity;

  /// Pozostała roczna zdolność produkcyjna w bieżącym sezonie.
  int get remainingProductionCapacity =>
      math.max(0, annualProductionCapacityFrames - framesProducedThisSeason);

  /// Aktywne kontrakty licencyjne z innymi drużynami.
  List<ExternalTeamLicenseContract> get activeLicenseContracts =>
      licenseContracts.where((c) => c.isActive).toList(growable: false);

  /// Liczba wolnych slotów na licencje zewnętrzne.
  int get availableLicenseSlots =>
      math.max(0, facilityTier.maxExternalLicenses - activeLicenseContracts.length);

  /// Łączne roczne przychody zakontraktowane z zewnętrznych licencji i dostaw ram.
  int get contractedAnnualLicenseRevenueEur =>
      activeLicenseContracts.fold(0, (sum, c) => sum + c.totalAnnualRevenueEur);

  /// Liczba homologowanych przez UCI modeli ram gotowych do wyścigów.
  List<InHouseFrameBlueprint> get homologatedBlueprints =>
      blueprints.where((b) => b.uciHomologated).toList(growable: false);

  /// Generuje odpowiednik [BikeManufacturerDeal], aby własny zespół mógł używać
  /// swoich ram w systemie sprzętu i symulacji bez płacenia zewnętrznemu producentowi.
  BikeManufacturerDeal asOwnTeamManufacturerDeal() {
    return BikeManufacturerDeal(
      manufacturerId: brandId,
      manufacturerName: brandName,
      prestigeLevel: prestigeStars,
      annualCashContributionEur: 0,
      freeBikesQuota: 120,
      researchAndDevelopmentLevel: rdEngineeringLevel,
      suppliedFrameIds: homologatedBlueprints.map((b) => b.blueprintId).toList(growable: false),
      suppliedWheelsetIds: const [],
      contractYearsLeft: 99,
      minimumUciRankingRequired: 999,
    );
  }

  /// Rozbudowuje fabrykę do wyższego poziomu [nextTier], jeśli zespół posiada wymagany budżet.
  BrandOperationResult upgradeFacility({
    required ManufacturingFacilityTier nextTier,
    required int availableTeamCashEur,
  }) {
    if (nextTier.index <= facilityTier.index) {
      return BrandOperationResult(
        success: false,
        message: 'Wybrany poziom fabryki nie jest wyższy od obecnego.',
        model: this,
      );
    }

    final cost = nextTier.upgradeCostEur;
    if (availableTeamCashEur < cost) {
      return BrandOperationResult(
        success: false,
        message: 'Niewystarczające środki na rozbudowę fabryki (wymagane €$cost).',
        model: this,
      );
    }

    final updated = copyWith(
      facilityTier: nextTier,
      rdEngineeringLevel: math.min(100, rdEngineeringLevel + 6),
      prestigeScore: math.min(100.0, prestigeScore + 5.5),
      brandEquityValueEur: brandEquityValueEur + (cost * 0.75).round(),
    );

    return BrandOperationResult(
      success: true,
      message: 'Rozbudowano infrastrukturę do: ${nextTier.displayNamePl}.',
      model: updated,
      cashDeltaEur: -cost,
    );
  }

  /// Rozpoczyna nowy projekt R&D dla wskazanego blueprintu ramy.
  BrandOperationResult startRdProject({
    required String projectId,
    required String title,
    required String targetBlueprintId,
    required RdProjectFocus focus,
    required int budgetEur,
    required int availableTeamCashEur,
  }) {
    final targetExists = blueprints.any((b) => b.blueprintId == targetBlueprintId);
    if (!targetExists) {
      return BrandOperationResult(
        success: false,
        message: 'Nie znaleziono docelowego blueprintu ramy.',
        model: this,
      );
    }
    if (budgetEur <= 0 || availableTeamCashEur < budgetEur) {
      return BrandOperationResult(
        success: false,
        message: 'Niewystarczający budżet na uruchomienie projektu R&D.',
        model: this,
      );
    }

    final int weightDelta;
    final double cdaDelta;
    final double stiffnessDelta;
    final double complianceDelta;

    switch (focus) {
      case RdProjectFocus.aeroTubeProfiles:
        weightDelta = -10;
        cdaDelta = -0.004;
        stiffnessDelta = 0.03;
        complianceDelta = 0.0;
        break;
      case RdProjectFocus.ultralightLayup:
        weightDelta = -42;
        cdaDelta = 0.0;
        stiffnessDelta = 0.02;
        complianceDelta = 0.01;
        break;
      case RdProjectFocus.bbStiffnessTransfer:
        weightDelta = -8;
        cdaDelta = -0.001;
        stiffnessDelta = 0.14;
        complianceDelta = -0.01;
        break;
      case RdProjectFocus.cobbleIsoCompliance:
        weightDelta = 5;
        cdaDelta = 0.0;
        stiffnessDelta = 0.01;
        complianceDelta = 0.09;
        break;
    }

    final project = BrandRdResearchProject(
      projectId: projectId,
      title: title,
      targetBlueprintId: targetBlueprintId,
      focus: focus,
      status: RdProjectStatus.inProgress,
      investedBudgetEur: budgetEur,
      totalRequiredBudgetEur: budgetEur,
      progressRatio: 0.0,
      expectedWeightDeltaGrams: weightDelta,
      expectedCdaDelta: cdaDelta,
      expectedStiffnessDelta: stiffnessDelta,
      expectedComplianceDelta: complianceDelta,
      estimatedDaysRemaining: math.max(14, (65 - (rdEngineeringLevel * 0.4)).round()),
    );

    return BrandOperationResult(
      success: true,
      message: 'Rozpoczęto projekt R&D: $title.',
      model: copyWith(activeRdProjects: [...activeRdProjects, project]),
      cashDeltaEur: -budgetEur,
    );
  }

  /// Przesuwa aktywne projekty R&D o [daysElapsed] dni i aplikuje ukończone ulepszenia do ram.
  InHouseBikeBrandModel advanceRdProjects(int daysElapsed) {
    if (daysElapsed <= 0 || activeRdProjects.isEmpty) return this;

    final updatedBlueprints = List<InHouseFrameBlueprint>.from(blueprints);
    final updatedProjects = <BrandRdResearchProject>[];
    double prestigeGain = 0.0;
    int rdGain = 0;

    final speedFactor = 0.75 + (rdEngineeringLevel / 100.0) * 0.65;

    for (final project in activeRdProjects) {
      if (project.isCompleted || project.status == RdProjectStatus.cancelled) {
        updatedProjects.add(project);
        continue;
      }

      final totalDays = math.max(1, project.estimatedDaysRemaining);
      final deltaProgress = (daysElapsed * speedFactor) / totalDays;
      final nextProgress = (project.progressRatio + deltaProgress).clamp(0.0, 1.0);
      final nextDays = math.max(0, project.estimatedDaysRemaining - daysElapsed);

      if (nextProgress >= 1.0) {
        final idx = updatedBlueprints.indexWhere(
          (b) => b.blueprintId == project.targetBlueprintId,
        );
        if (idx != -1) {
          final current = updatedBlueprints[idx];
          updatedBlueprints[idx] = current.copyWith(
            weightGrams: math.max(580, current.weightGrams + project.expectedWeightDeltaGrams),
            aeroCdaModifier:
                double.parse((current.aeroCdaModifier + project.expectedCdaDelta).toStringAsFixed(4)),
            stiffnessToWeightIndex: double.parse(
              (current.stiffnessToWeightIndex + project.expectedStiffnessDelta)
                  .clamp(1.0, 2.8)
                  .toStringAsFixed(2),
            ),
            comfortCompliance: double.parse(
              (current.comfortCompliance + project.expectedComplianceDelta)
                  .clamp(0.2, 1.0)
                  .toStringAsFixed(2),
            ),
            rdGeneration: current.rdGeneration + 1,
          );
          prestigeGain += 2.5;
          rdGain += 1;
        }
        updatedProjects.add(
          project.copyWith(
            progressRatio: 1.0,
            estimatedDaysRemaining: 0,
            status: RdProjectStatus.homologated,
          ),
        );
      } else {
        final nextStatus = nextProgress >= 0.8
            ? RdProjectStatus.windTunnelValidation
            : RdProjectStatus.inProgress;
        updatedProjects.add(
          project.copyWith(
            progressRatio: nextProgress,
            estimatedDaysRemaining: nextDays,
            status: nextStatus,
          ),
        );
      }
    }

    return copyWith(
      blueprints: updatedBlueprints,
      activeRdProjects: updatedProjects,
      prestigeScore: math.min(100.0, prestigeScore + prestigeGain),
      rdEngineeringLevel: math.min(100, rdEngineeringLevel + rdGain),
    );
  }

  /// Podpisuje kontrakt licencyjny i dostawy ram z zewnętrzną ekipą.
  BrandOperationResult signLicenseContract(ExternalTeamLicenseContract contract) {
    if (availableLicenseSlots <= 0) {
      return BrandOperationResult(
        success: false,
        message: 'Brak wolnych slotów licencyjnych — rozbuduj fabrykę.',
        model: this,
      );
    }

    final blueprint = blueprints.cast<InHouseFrameBlueprint?>().firstWhere(
          (b) => b?.blueprintId == contract.suppliedBlueprintId,
          orElse: () => null,
        );
    if (blueprint == null || !blueprint.uciHomologated) {
      return BrandOperationResult(
        success: false,
        message: 'Wybrana rama nie posiada ważnej homologacji UCI.',
        model: this,
      );
    }

    if (contract.framesOrderedPerSeason > remainingProductionCapacity) {
      return BrandOperationResult(
        success: false,
        message: 'Zamówienie przekracza dostępną roczną zdolność produkcyjną fabryki.',
        model: this,
      );
    }

    return BrandOperationResult(
      success: true,
      message: 'Podpisano kontrakt licencyjny z ${contract.partnerTeamName}.',
      model: copyWith(
        licenseContracts: [...licenseContracts, contract],
        prestigeScore: math.min(100.0, prestigeScore + 1.5),
      ),
    );
  }

  /// Symuluje zamknięcie kwartału produkcyjno-sprzedażowego i generuje raport finansowy.
  BrandOperationResult simulateQuarterFinancials({
    required int seasonYear,
    required int quarter,
    required int ownTeamFramesConsumed,
    int partnerWorldTourWins = 0,
  }) {
    final activeDeals = activeLicenseContracts;
    int teamFramesSold = 0;
    int licenseFees = 0;
    int teamSalesRev = 0;
    int productionCost = 0;

    for (final deal in activeDeals) {
      final quarterlyFrames = (deal.framesOrderedPerSeason / 4.0).round();
      final blueprint = blueprints.cast<InHouseFrameBlueprint?>().firstWhere(
            (b) => b?.blueprintId == deal.suppliedBlueprintId,
            orElse: () => blueprints.isNotEmpty ? blueprints.first : null,
          );
      final unitCost = blueprint?.unitManufacturingCostEur ?? 1300;
      teamFramesSold += quarterlyFrames;
      licenseFees += (deal.annualLicenseFeeEur / 4.0).round() +
          (partnerWorldTourWins * deal.royaltyPerWorldTourWinEur);
      teamSalesRev += quarterlyFrames * deal.pricePerFrameEur;
      productionCost += quarterlyFrames * unitCost;
    }

    final ownUnitCost =
        blueprints.isNotEmpty ? blueprints.first.unitManufacturingCostEur : 1300;
    productionCost += math.max(0, ownTeamFramesConsumed) * ownUnitCost;

    final int retailCapacityRemaining = math.max(
      0,
      ((annualProductionCapacityFrames / 4.0).round() - teamFramesSold - ownTeamFramesConsumed),
    );
    final int estimatedRetailDemand = (60 *
            facilityTier.retailMultiplier *
            retailConsumerDemandIndex *
            (0.5 + prestigeScore / 100.0))
        .round();
    final int retailSold = math.min(retailCapacityRemaining, estimatedRetailDemand);

    final int avgRetailPrice = blueprints.isEmpty
        ? 5500
        : (blueprints.fold<int>(0, (s, b) => s + b.retailMsrpEur) / blueprints.length).round();
    final int retailRev = retailSold * avgRetailPrice;
    productionCost += retailSold * ownUnitCost;

    final int facilityOpex = facilityTier.quarterlyFixedOpexEur;
    final int rdExpense = activeRdProjects
        .where((p) => !p.isCompleted && p.status != RdProjectStatus.cancelled)
        .fold<int>(0, (sum, p) => sum + (p.totalRequiredBudgetEur * 0.1).round());

    final int netProfit =
        (licenseFees + teamSalesRev + retailRev) - (productionCost + rdExpense + facilityOpex);

    final double prestigeDelta = (partnerWorldTourWins * 1.2) + (activeDeals.length * 0.4);
    final int totalProduced = teamFramesSold + retailSold + math.max(0, ownTeamFramesConsumed);

    final report = BrandManufacturingQuarterlyReport(
      seasonYear: seasonYear,
      quarter: quarter.clamp(1, 4),
      framesProduced: totalProduced,
      framesSoldToTeams: teamFramesSold,
      framesSoldRetail: retailSold,
      licenseRevenueEur: licenseFees,
      frameSalesRevenueEur: teamSalesRev,
      retailRevenueEur: retailRev,
      manufacturingCostEur: productionCost,
      rdExpenseEur: rdExpense,
      facilityOpexEur: facilityOpex,
      netProfitEur: netProfit,
      brandPrestigeDelta: double.parse(prestigeDelta.toStringAsFixed(2)),
    );

    final updated = copyWith(
      framesProducedThisSeason: framesProducedThisSeason + totalProduced,
      prestigeScore: math.min(100.0, prestigeScore + prestigeDelta),
      brandEquityValueEur: math.max(250000, brandEquityValueEur + (netProfit * 0.4).round()),
      quarterlyReports: [...quarterlyReports, report],
    );

    return BrandOperationResult(
      success: true,
      message: 'Zamknięto Q$quarter/$seasonYear dla marki $brandName (zysk netto: €$netProfit).',
      model: updated,
      cashDeltaEur: netProfit,
    );
  }

  InHouseBikeBrandModel copyWith({
    String? brandId,
    String? ownerTeamId,
    String? ownerTeamName,
    String? brandName,
    String? brandTagline,
    String? primaryColorHex,
    String? secondaryColorHex,
    int? foundedSeasonYear,
    ManufacturingFacilityTier? facilityTier,
    double? prestigeScore,
    int? rdEngineeringLevel,
    int? framesProducedThisSeason,
    double? retailConsumerDemandIndex,
    int? brandEquityValueEur,
    List<InHouseFrameBlueprint>? blueprints,
    List<BrandRdResearchProject>? activeRdProjects,
    List<ExternalTeamLicenseContract>? licenseContracts,
    List<BrandManufacturingQuarterlyReport>? quarterlyReports,
  }) {
    return InHouseBikeBrandModel(
      brandId: brandId ?? this.brandId,
      ownerTeamId: ownerTeamId ?? this.ownerTeamId,
      ownerTeamName: ownerTeamName ?? this.ownerTeamName,
      brandName: brandName ?? this.brandName,
      brandTagline: brandTagline ?? this.brandTagline,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      foundedSeasonYear: foundedSeasonYear ?? this.foundedSeasonYear,
      facilityTier: facilityTier ?? this.facilityTier,
      prestigeScore: prestigeScore ?? this.prestigeScore,
      rdEngineeringLevel: rdEngineeringLevel ?? this.rdEngineeringLevel,
      framesProducedThisSeason: framesProducedThisSeason ?? this.framesProducedThisSeason,
      retailConsumerDemandIndex: retailConsumerDemandIndex ?? this.retailConsumerDemandIndex,
      brandEquityValueEur: brandEquityValueEur ?? this.brandEquityValueEur,
      blueprints: blueprints != null
          ? List<InHouseFrameBlueprint>.unmodifiable(blueprints)
          : this.blueprints,
      activeRdProjects: activeRdProjects != null
          ? List<BrandRdResearchProject>.unmodifiable(activeRdProjects)
          : this.activeRdProjects,
      licenseContracts: licenseContracts != null
          ? List<ExternalTeamLicenseContract>.unmodifiable(licenseContracts)
          : this.licenseContracts,
      quarterlyReports: quarterlyReports != null
          ? List<BrandManufacturingQuarterlyReport>.unmodifiable(quarterlyReports)
          : this.quarterlyReports,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandId': brandId,
      'ownerTeamId': ownerTeamId,
      'ownerTeamName': ownerTeamName,
      'brandName': brandName,
      'brandTagline': brandTagline,
      'primaryColorHex': primaryColorHex,
      'secondaryColorHex': secondaryColorHex,
      'foundedSeasonYear': foundedSeasonYear,
      'facilityTier': facilityTier.toJson(),
      'prestigeScore': prestigeScore,
      'rdEngineeringLevel': rdEngineeringLevel,
      'framesProducedThisSeason': framesProducedThisSeason,
      'retailConsumerDemandIndex': retailConsumerDemandIndex,
      'brandEquityValueEur': brandEquityValueEur,
      'blueprints': blueprints.map((e) => e.toJson()).toList(growable: false),
      'activeRdProjects': activeRdProjects.map((e) => e.toJson()).toList(growable: false),
      'licenseContracts': licenseContracts.map((e) => e.toJson()).toList(growable: false),
      'quarterlyReports': quarterlyReports.map((e) => e.toJson()).toList(growable: false),
    };
  }

  factory InHouseBikeBrandModel.fromJson(Map<String, dynamic> json) {
    return InHouseBikeBrandModel(
      brandId: json['brandId'] as String,
      ownerTeamId: json['ownerTeamId'] as String,
      ownerTeamName: json['ownerTeamName'] as String,
      brandName: json['brandName'] as String,
      brandTagline: json['brandTagline'] as String? ?? 'Engineered in the Peloton',
      primaryColorHex: json['primaryColorHex'] as String? ?? '#8E4A49',
      secondaryColorHex: json['secondaryColorHex'] as String? ?? '#D4AF37',
      foundedSeasonYear: (json['foundedSeasonYear'] as num).toInt(),
      facilityTier: ManufacturingFacilityTier.fromJson(
        json['facilityTier'] as String? ?? 'skunkworksWorkshop',
      ),
      prestigeScore: (json['prestigeScore'] as num).toDouble().clamp(0.0, 100.0),
      rdEngineeringLevel: (json['rdEngineeringLevel'] as num).toInt().clamp(1, 100),
      framesProducedThisSeason: (json['framesProducedThisSeason'] as num?)?.toInt() ?? 0,
      retailConsumerDemandIndex:
          (json['retailConsumerDemandIndex'] as num?)?.toDouble() ?? 1.0,
      brandEquityValueEur: (json['brandEquityValueEur'] as num?)?.toInt() ?? 500000,
      blueprints: (json['blueprints'] as List<dynamic>?)
              ?.map((e) => InHouseFrameBlueprint.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      activeRdProjects: (json['activeRdProjects'] as List<dynamic>?)
              ?.map((e) => BrandRdResearchProject.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      licenseContracts: (json['licenseContracts'] as List<dynamic>?)
              ?.map((e) => ExternalTeamLicenseContract.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      quarterlyReports: (json['quarterlyReports'] as List<dynamic>?)
              ?.map(
                (e) =>
                    BrandManufacturingQuarterlyReport.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InHouseBikeBrandModel) return false;
    if (other.brandId != brandId ||
        other.ownerTeamId != ownerTeamId ||
        other.ownerTeamName != ownerTeamName ||
        other.brandName != brandName ||
        other.brandTagline != brandTagline ||
        other.primaryColorHex != primaryColorHex ||
        other.secondaryColorHex != secondaryColorHex ||
        other.foundedSeasonYear != foundedSeasonYear ||
        other.facilityTier != facilityTier ||
        other.prestigeScore != prestigeScore ||
        other.rdEngineeringLevel != rdEngineeringLevel ||
        other.framesProducedThisSeason != framesProducedThisSeason ||
        other.retailConsumerDemandIndex != retailConsumerDemandIndex ||
        other.brandEquityValueEur != brandEquityValueEur ||
        other.blueprints.length != blueprints.length ||
        other.activeRdProjects.length != activeRdProjects.length ||
        other.licenseContracts.length != licenseContracts.length ||
        other.quarterlyReports.length != quarterlyReports.length) {
      return false;
    }
    for (int i = 0; i < blueprints.length; i++) {
      if (other.blueprints[i] != blueprints[i]) return false;
    }
    for (int i = 0; i < activeRdProjects.length; i++) {
      if (other.activeRdProjects[i] != activeRdProjects[i]) return false;
    }
    for (int i = 0; i < licenseContracts.length; i++) {
      if (other.licenseContracts[i] != licenseContracts[i]) return false;
    }
    for (int i = 0; i < quarterlyReports.length; i++) {
      if (other.quarterlyReports[i] != quarterlyReports[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        brandId,
        ownerTeamId,
        ownerTeamName,
        brandName,
        brandTagline,
        primaryColorHex,
        secondaryColorHex,
        foundedSeasonYear,
        facilityTier,
        prestigeScore,
        rdEngineeringLevel,
        framesProducedThisSeason,
        retailConsumerDemandIndex,
        brandEquityValueEur,
        Object.hashAll(blueprints),
        Object.hashAll(activeRdProjects),
        Object.hashAll(licenseContracts),
        Object.hashAll(quarterlyReports),
      );

  @override
  String toString() {
    return 'InHouseBikeBrandModel($brandName, tier: ${facilityTier.name}, prestige: ${prestigeScore.toStringAsFixed(1)}, licenses: ${activeLicenseContracts.length}/${facilityTier.maxExternalLicenses})';
  }
}
