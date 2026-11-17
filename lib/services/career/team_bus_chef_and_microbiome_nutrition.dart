import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Poziom doświadczenia i renomy Szefa Kuchni Drużyny.
enum TeamChefTier {
  rookieCook,
  proTourChef,
  worldTourCulinaryDirector,
  michelinSportsNutritionist;

  String toJson() => name;

  static TeamChefTier fromJson(String value) {
    return TeamChefTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TeamChefTier.proTourChef,
    );
  }

  String get displayName {
    switch (this) {
      case TeamChefTier.rookieCook:
        return 'Kucharz Kontynentalny';
      case TeamChefTier.proTourChef:
        return 'Szef Kuchni ProTeam';
      case TeamChefTier.worldTourCulinaryDirector:
        return 'Dyrektor Kulinarny WorldTour';
      case TeamChefTier.michelinSportsNutritionist:
        return 'Mistrz Kuchni & Dietetyk Sportowy';
    }
  }

  int get stars {
    switch (this) {
      case TeamChefTier.rookieCook:
        return 2;
      case TeamChefTier.proTourChef:
        return 3;
      case TeamChefTier.worldTourCulinaryDirector:
        return 4;
      case TeamChefTier.michelinSportsNutritionist:
        return 5;
    }
  }

  double get glycogenSynthesisMultiplier {
    switch (this) {
      case TeamChefTier.rookieCook:
        return 1.00;
      case TeamChefTier.proTourChef:
        return 1.06;
      case TeamChefTier.worldTourCulinaryDirector:
        return 1.12;
      case TeamChefTier.michelinSportsNutritionist:
        return 1.18;
    }
  }

  double get giToleranceBonus {
    switch (this) {
      case TeamChefTier.rookieCook:
        return 0.0;
      case TeamChefTier.proTourChef:
        return 4.0;
      case TeamChefTier.worldTourCulinaryDirector:
        return 9.0;
      case TeamChefTier.michelinSportsNutritionist:
        return 15.0;
    }
  }

  Color get badgeColor {
    switch (this) {
      case TeamChefTier.rookieCook:
        return AppColors.textSecondary;
      case TeamChefTier.proTourChef:
        return AppColors.accentBlue;
      case TeamChefTier.worldTourCulinaryDirector:
        return AppColors.primaryAccent;
      case TeamChefTier.michelinSportsNutritionist:
        return AppColors.goldAccent;
    }
  }
}

/// Standard zaplecza kuchennego w autobusie lub ciężarówce drużyny.
enum KitchenBusEquipmentTier {
  standardHotelCatering,
  mobileKitchenVan,
  proTourCulinaryTruck,
  worldTourMetabolicBus;

  String toJson() => name;

  static KitchenBusEquipmentTier fromJson(String value) {
    return KitchenBusEquipmentTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => KitchenBusEquipmentTier.proTourCulinaryTruck,
    );
  }

  String get displayName {
    switch (this) {
      case KitchenBusEquipmentTier.standardHotelCatering:
        return 'Catering Hotelowy (Podstawowy)';
      case KitchenBusEquipmentTier.mobileKitchenVan:
        return 'Mobilna Kuchnia Van';
      case KitchenBusEquipmentTier.proTourCulinaryTruck:
        return 'Ciężarówka Kulinarna ProTour';
      case KitchenBusEquipmentTier.worldTourMetabolicBus:
        return 'Autobus Metaboliczny WorldTour';
    }
  }

  String get shortLabel {
    switch (this) {
      case KitchenBusEquipmentTier.standardHotelCatering:
        return 'Hotel';
      case KitchenBusEquipmentTier.mobileKitchenVan:
        return 'Van';
      case KitchenBusEquipmentTier.proTourCulinaryTruck:
        return 'Truck Pro';
      case KitchenBusEquipmentTier.worldTourMetabolicBus:
        return 'Metabolic Bus';
    }
  }

  double get dailyOperatingCostEur {
    switch (this) {
      case KitchenBusEquipmentTier.standardHotelCatering:
        return 850.0;
      case KitchenBusEquipmentTier.mobileKitchenVan:
        return 1450.0;
      case KitchenBusEquipmentTier.proTourCulinaryTruck:
        return 2300.0;
      case KitchenBusEquipmentTier.worldTourMetabolicBus:
        return 3400.0;
    }
  }

  double get foodSafetyHygieneScore {
    switch (this) {
      case KitchenBusEquipmentTier.standardHotelCatering:
        return 72.0;
      case KitchenBusEquipmentTier.mobileKitchenVan:
        return 84.0;
      case KitchenBusEquipmentTier.proTourCulinaryTruck:
        return 93.0;
      case KitchenBusEquipmentTier.worldTourMetabolicBus:
        return 99.0;
    }
  }

  double get macroPrecisionBonus {
    switch (this) {
      case KitchenBusEquipmentTier.standardHotelCatering:
        return 0.94;
      case KitchenBusEquipmentTier.mobileKitchenVan:
        return 1.00;
      case KitchenBusEquipmentTier.proTourCulinaryTruck:
        return 1.05;
      case KitchenBusEquipmentTier.worldTourMetabolicBus:
        return 1.11;
    }
  }

  double get probioticFermentationBonus {
    switch (this) {
      case KitchenBusEquipmentTier.standardHotelCatering:
        return 0.0;
      case KitchenBusEquipmentTier.mobileKitchenVan:
        return 1.5;
      case KitchenBusEquipmentTier.proTourCulinaryTruck:
        return 3.5;
      case KitchenBusEquipmentTier.worldTourMetabolicBus:
        return 6.0;
    }
  }
}

/// Pora posiłku w harmonogramie dnia wyścigowego.
enum MealPeriodType {
  breakfastPreStage,
  onBikeFueling,
  postStageRecoveryShake,
  teamBusDinner,
  lateEveningCaseinSnack;

  String toJson() => name;

  static MealPeriodType fromJson(String value) {
    return MealPeriodType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MealPeriodType.teamBusDinner,
    );
  }

  String get displayName {
    switch (this) {
      case MealPeriodType.breakfastPreStage:
        return 'Śniadanie Przedstartowe (-3h)';
      case MealPeriodType.onBikeFueling:
        return 'Żywienie na Trasie (Żele/Bidony)';
      case MealPeriodType.postStageRecoveryShake:
        return 'Szejk Okna Anabolicznego (+20m)';
      case MealPeriodType.teamBusDinner:
        return 'Kolacja w Autobusie Drużyny';
      case MealPeriodType.lateEveningCaseinSnack:
        return 'Nocna Kazeina & Probiotyki';
    }
  }
}

/// Strategia menu dobrana indywidualnie dla kolarza.
enum NutritionMenuStrategy {
  highCarbGlycogenLoad,
  balancedEndurance,
  gutMicrobiomeProbioticReset,
  weightCutDeficit,
  restDaySupercompensation;

  String toJson() => name;

  static NutritionMenuStrategy fromJson(String value) {
    return NutritionMenuStrategy.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NutritionMenuStrategy.balancedEndurance,
    );
  }

  String get displayName {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return 'Ładowanie Węglowodanowe (11 g/kg)';
      case NutritionMenuStrategy.balancedEndurance:
        return 'Bilans Wytrzymałościowy (8 g/kg)';
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return 'Reset Mikrobiomu & Probiotyki';
      case NutritionMenuStrategy.weightCutDeficit:
        return 'Redukcja Masy (-450 kcal)';
      case NutritionMenuStrategy.restDaySupercompensation:
        return 'Superkompensacja Dnia Przerwy';
    }
  }

  String get shortLabel {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return 'High-Carb';
      case NutritionMenuStrategy.balancedEndurance:
        return 'Zbilansowana';
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return 'Mikrobiom+';
      case NutritionMenuStrategy.weightCutDeficit:
        return 'Redukcja';
      case NutritionMenuStrategy.restDaySupercompensation:
        return 'Superkomp.';
    }
  }

  double get targetCarbsPerKg {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return 11.2;
      case NutritionMenuStrategy.balancedEndurance:
        return 8.2;
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return 7.4;
      case NutritionMenuStrategy.weightCutDeficit:
        return 5.6;
      case NutritionMenuStrategy.restDaySupercompensation:
        return 9.6;
    }
  }

  double get targetProteinPerKg {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return 1.9;
      case NutritionMenuStrategy.balancedEndurance:
        return 2.0;
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return 2.1;
      case NutritionMenuStrategy.weightCutDeficit:
        return 2.4;
      case NutritionMenuStrategy.restDaySupercompensation:
        return 2.0;
    }
  }

  double get targetFatPerKg {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return 0.9;
      case NutritionMenuStrategy.balancedEndurance:
        return 1.1;
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return 1.25;
      case NutritionMenuStrategy.weightCutDeficit:
        return 0.85;
      case NutritionMenuStrategy.restDaySupercompensation:
        return 1.05;
    }
  }

  double get calorieAdjustmentKcal {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return 420.0;
      case NutritionMenuStrategy.balancedEndurance:
        return 50.0;
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return -50.0;
      case NutritionMenuStrategy.weightCutDeficit:
        return -450.0;
      case NutritionMenuStrategy.restDaySupercompensation:
        return 680.0;
    }
  }

  double get microbiomeDeltaBase {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return -1.8;
      case NutritionMenuStrategy.balancedEndurance:
        return 0.8;
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return 7.5;
      case NutritionMenuStrategy.weightCutDeficit:
        return -0.6;
      case NutritionMenuStrategy.restDaySupercompensation:
        return 2.2;
    }
  }

  Color get accentColor {
    switch (this) {
      case NutritionMenuStrategy.highCarbGlycogenLoad:
        return AppColors.amberWarning;
      case NutritionMenuStrategy.balancedEndurance:
        return AppColors.accentBlue;
      case NutritionMenuStrategy.gutMicrobiomeProbioticReset:
        return AppColors.statusSuccess;
      case NutritionMenuStrategy.weightCutDeficit:
        return AppColors.primaryAccent;
      case NutritionMenuStrategy.restDaySupercompensation:
        return AppColors.goldAccent;
    }
  }
}

/// Stan zdrowia mikrobiomu jelitowego kolarza.
enum MicrobiomeHealthState {
  optimalDiversity,
  balancedFlora,
  mildDysbiosis,
  acuteGiDistress;

  String toJson() => name;

  static MicrobiomeHealthState fromJson(String value) {
    return MicrobiomeHealthState.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MicrobiomeHealthState.balancedFlora,
    );
  }

  String get displayName {
    switch (this) {
      case MicrobiomeHealthState.optimalDiversity:
        return 'Optymalna Flora (110+ g/h CHO)';
      case MicrobiomeHealthState.balancedFlora:
        return 'Stabilny Mikrobiom';
      case MicrobiomeHealthState.mildDysbiosis:
        return 'Łagodna Dysbioza (Spadek Wchłaniania)';
      case MicrobiomeHealthState.acuteGiDistress:
        return 'Ostre Problemy Żołądkowe (GI)';
    }
  }

  Color get statusColor {
    switch (this) {
      case MicrobiomeHealthState.optimalDiversity:
        return AppColors.statusSuccess;
      case MicrobiomeHealthState.balancedFlora:
        return AppColors.accentBlue;
      case MicrobiomeHealthState.mildDysbiosis:
        return AppColors.amberWarning;
      case MicrobiomeHealthState.acuteGiDistress:
        return AppColors.crimsonAlert;
    }
  }
}

/// Profil Szefa Kuchni zatrudnionego w drużynie.
@immutable
class TeamChefProfile {
  final String id;
  final String name;
  final String nationality;
  final TeamChefTier tier;
  final int culinarySkill;
  final int sportsNutritionKnowledge;
  final int microbiomeExpertise;
  final double dailySalaryEur;
  final String signatureDish;
  final double moraleBonus;

  const TeamChefProfile({
    required this.id,
    required this.name,
    required this.nationality,
    required this.tier,
    required this.culinarySkill,
    required this.sportsNutritionKnowledge,
    required this.microbiomeExpertise,
    required this.dailySalaryEur,
    required this.signatureDish,
    required this.moraleBonus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nationality': nationality,
        'tier': tier.toJson(),
        'culinarySkill': culinarySkill,
        'sportsNutritionKnowledge': sportsNutritionKnowledge,
        'microbiomeExpertise': microbiomeExpertise,
        'dailySalaryEur': dailySalaryEur,
        'signatureDish': signatureDish,
        'moraleBonus': moraleBonus,
      };

  factory TeamChefProfile.fromJson(Map<String, dynamic> json) {
    return TeamChefProfile(
      id: json['id'] as String? ?? 'chef_default',
      name: json['name'] as String? ?? 'Lorenzo Bellini',
      nationality: json['nationality'] as String? ?? 'ITA',
      tier: TeamChefTier.fromJson(json['tier'] as String? ?? 'proTourChef'),
      culinarySkill: (json['culinarySkill'] as num?)?.toInt() ?? 80,
      sportsNutritionKnowledge:
          (json['sportsNutritionKnowledge'] as num?)?.toInt() ?? 82,
      microbiomeExpertise: (json['microbiomeExpertise'] as num?)?.toInt() ?? 78,
      dailySalaryEur: (json['dailySalaryEur'] as num?)?.toDouble() ?? 620.0,
      signatureDish: json['signatureDish'] as String? ??
          'Risotto z szafranem & sok z wiśni Montmorency',
      moraleBonus: (json['moraleBonus'] as num?)?.toDouble() ?? 4.0,
    );
  }
}

/// Profil żywieniowy pojedynczego kolarza przed nocną regeneracją.
@immutable
class RiderNutritionalProfile {
  final String riderId;
  final String riderName;
  final String role;
  final double bodyWeightKg;
  final double targetRaceWeightKg;
  final double stageExpenditureKcal;
  final double glycogenStorePercent;
  final double glycogenCapacityG;
  final double microbiomeDiversityIndex;
  final int gutTrainingLevel;
  final NutritionMenuStrategy assignedStrategy;
  final bool dailyProbioticCourseActive;

  const RiderNutritionalProfile({
    required this.riderId,
    required this.riderName,
    required this.role,
    required this.bodyWeightKg,
    required this.targetRaceWeightKg,
    required this.stageExpenditureKcal,
    required this.glycogenStorePercent,
    required this.glycogenCapacityG,
    required this.microbiomeDiversityIndex,
    required this.gutTrainingLevel,
    required this.assignedStrategy,
    required this.dailyProbioticCourseActive,
  });

  double get basalMetabolicRateKcal =>
      (24.2 * bodyWeightKg + 210.0).clamp(1350.0, 2500.0);

  RiderNutritionalProfile copyWith({
    String? riderId,
    String? riderName,
    String? role,
    double? bodyWeightKg,
    double? targetRaceWeightKg,
    double? stageExpenditureKcal,
    double? glycogenStorePercent,
    double? glycogenCapacityG,
    double? microbiomeDiversityIndex,
    int? gutTrainingLevel,
    NutritionMenuStrategy? assignedStrategy,
    bool? dailyProbioticCourseActive,
  }) {
    return RiderNutritionalProfile(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      role: role ?? this.role,
      bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
      targetRaceWeightKg: targetRaceWeightKg ?? this.targetRaceWeightKg,
      stageExpenditureKcal: stageExpenditureKcal ?? this.stageExpenditureKcal,
      glycogenStorePercent: glycogenStorePercent ?? this.glycogenStorePercent,
      glycogenCapacityG: glycogenCapacityG ?? this.glycogenCapacityG,
      microbiomeDiversityIndex:
          microbiomeDiversityIndex ?? this.microbiomeDiversityIndex,
      gutTrainingLevel: gutTrainingLevel ?? this.gutTrainingLevel,
      assignedStrategy: assignedStrategy ?? this.assignedStrategy,
      dailyProbioticCourseActive:
          dailyProbioticCourseActive ?? this.dailyProbioticCourseActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'role': role,
        'bodyWeightKg': bodyWeightKg,
        'targetRaceWeightKg': targetRaceWeightKg,
        'stageExpenditureKcal': stageExpenditureKcal,
        'glycogenStorePercent': glycogenStorePercent,
        'glycogenCapacityG': glycogenCapacityG,
        'microbiomeDiversityIndex': microbiomeDiversityIndex,
        'gutTrainingLevel': gutTrainingLevel,
        'assignedStrategy': assignedStrategy.toJson(),
        'dailyProbioticCourseActive': dailyProbioticCourseActive,
      };

  factory RiderNutritionalProfile.fromJson(Map<String, dynamic> json) {
    return RiderNutritionalProfile(
      riderId: json['riderId'] as String? ?? 'r_0',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      role: json['role'] as String? ?? 'Pomocnik',
      bodyWeightKg: (json['bodyWeightKg'] as num?)?.toDouble() ?? 68.0,
      targetRaceWeightKg:
          (json['targetRaceWeightKg'] as num?)?.toDouble() ?? 67.5,
      stageExpenditureKcal:
          (json['stageExpenditureKcal'] as num?)?.toDouble() ?? 3800.0,
      glycogenStorePercent:
          (json['glycogenStorePercent'] as num?)?.toDouble() ?? 52.0,
      glycogenCapacityG:
          (json['glycogenCapacityG'] as num?)?.toDouble() ?? 620.0,
      microbiomeDiversityIndex:
          (json['microbiomeDiversityIndex'] as num?)?.toDouble() ?? 78.0,
      gutTrainingLevel: (json['gutTrainingLevel'] as num?)?.toInt() ?? 75,
      assignedStrategy: NutritionMenuStrategy.fromJson(
        json['assignedStrategy'] as String? ?? 'balancedEndurance',
      ),
      dailyProbioticCourseActive:
          json['dailyProbioticCourseActive'] as bool? ?? false,
    );
  }
}

/// Bilans kaloryczny i makroskładnikowy wyliczony dla kolarza.
@immutable
class CaloricBalanceCalculation {
  final double bmrKcal;
  final double stageBurnKcal;
  final double recoveryThermogenesisKcal;
  final double totalDailyExpenditureKcal;
  final double plannedIntakeKcal;
  final double netCaloricBalanceKcal;
  final double carbsGrams;
  final double proteinGrams;
  final double fatGrams;
  final double carbsPerKg;
  final double proteinPerKg;
  final double estimatedWeightDeltaKgPerWeek;
  final bool relativeEnergyDeficiencyRisk;

  const CaloricBalanceCalculation({
    required this.bmrKcal,
    required this.stageBurnKcal,
    required this.recoveryThermogenesisKcal,
    required this.totalDailyExpenditureKcal,
    required this.plannedIntakeKcal,
    required this.netCaloricBalanceKcal,
    required this.carbsGrams,
    required this.proteinGrams,
    required this.fatGrams,
    required this.carbsPerKg,
    required this.proteinPerKg,
    required this.estimatedWeightDeltaKgPerWeek,
    required this.relativeEnergyDeficiencyRisk,
  });
}

/// Raport nocnej odbudowy glikogenu i kondycji mikrobiomu dla kolarza.
@immutable
class GlycogenAndMicrobiomeRecoveryReport {
  final String riderId;
  final String riderName;
  final CaloricBalanceCalculation caloricBalance;
  final double startingGlycogenPercent;
  final double endingGlycogenPercent;
  final double glycogenRestoredGrams;
  final double nextStageAvailabilityScore;
  final double microbiomeBefore;
  final double microbiomeAfter;
  final MicrobiomeHealthState microbiomeState;
  final double giDistressRiskPercent;
  final double maxOnBikeCarbAbsorptionGPerHour;
  final double moraleDelta;
  final double weightDeltaKg;
  final List<String> chefNotes;

  const GlycogenAndMicrobiomeRecoveryReport({
    required this.riderId,
    required this.riderName,
    required this.caloricBalance,
    required this.startingGlycogenPercent,
    required this.endingGlycogenPercent,
    required this.glycogenRestoredGrams,
    required this.nextStageAvailabilityScore,
    required this.microbiomeBefore,
    required this.microbiomeAfter,
    required this.microbiomeState,
    required this.giDistressRiskPercent,
    required this.maxOnBikeCarbAbsorptionGPerHour,
    required this.moraleDelta,
    required this.weightDeltaKg,
    required this.chefNotes,
  });
}

/// Zbiorcze podsumowanie cateringu drużyny po dniu wyścigowym lub dniu przerwy.
@immutable
class TeamDailyCateringSummary {
  final int dayIndex;
  final String stageName;
  final bool isRestDay;
  final double totalCateringCostEur;
  final double averageGlycogenPercent;
  final double averageMicrobiomeIndex;
  final int ridersAtBonkRisk;
  final int ridersWithRedSWarning;
  final double teamMoraleDelta;
  final List<GlycogenAndMicrobiomeRecoveryReport> reports;

  const TeamDailyCateringSummary({
    required this.dayIndex,
    required this.stageName,
    required this.isRestDay,
    required this.totalCateringCostEur,
    required this.averageGlycogenPercent,
    required this.averageMicrobiomeIndex,
    required this.ridersAtBonkRisk,
    required this.ridersWithRedSWarning,
    required this.teamMoraleDelta,
    required this.reports,
  });
}

/// Katalog Szefów Kuchni oraz główny serwis obliczeniowy bilansu kalorycznego,
/// odbudowy glikogenu i zarządzania mikrobiomem w autobusie drużyny.
class TeamBusChefAndMicrobiomeNutritionService {
  const TeamBusChefAndMicrobiomeNutritionService();

  static const List<TeamChefProfile> availableChefsCatalog = [
    TeamChefProfile(
      id: 'chef_lorenzo',
      name: 'Lorenzo Bellini',
      nationality: 'ITA',
      tier: TeamChefTier.michelinSportsNutritionist,
      culinarySkill: 96,
      sportsNutritionKnowledge: 95,
      microbiomeExpertise: 92,
      dailySalaryEur: 1180.0,
      signatureDish: 'Risotto z szafranem, burakiem & sok z wiśni Montmorency',
      moraleBonus: 8.5,
    ),
    TeamChefProfile(
      id: 'chef_claire',
      name: 'Claire Moreau',
      nationality: 'FRA',
      tier: TeamChefTier.worldTourCulinaryDirector,
      culinarySkill: 91,
      sportsNutritionKnowledge: 89,
      microbiomeExpertise: 90,
      dailySalaryEur: 860.0,
      signatureDish: 'Komosa ryżowa, łosoś atlantycki & kefir probiotyczny',
      moraleBonus: 6.2,
    ),
    TeamChefProfile(
      id: 'chef_henrik',
      name: 'Henrik Lindqvist',
      nationality: 'DEN',
      tier: TeamChefTier.proTourChef,
      culinarySkill: 84,
      sportsNutritionKnowledge: 85,
      microbiomeExpertise: 79,
      dailySalaryEur: 580.0,
      signatureDish: 'Owsianka fermentowana z jagodami & omlet białkowy',
      moraleBonus: 4.0,
    ),
    TeamChefProfile(
      id: 'chef_tomasz',
      name: 'Tomasz Zieliński',
      nationality: 'POL',
      tier: TeamChefTier.rookieCook,
      culinarySkill: 74,
      sportsNutritionKnowledge: 72,
      microbiomeExpertise: 68,
      dailySalaryEur: 360.0,
      signatureDish: 'Makaron pełnoziarnisty z kurczakiem & zakwasem buraczanym',
      moraleBonus: 2.0,
    ),
  ];

  static List<RiderNutritionalProfile> createDefaultGrandTourRoster() {
    return const [
      RiderNutritionalProfile(
        riderId: 'rider_gc_1',
        riderName: 'Janek Kowalski',
        role: 'Lider GC',
        bodyWeightKg: 61.5,
        targetRaceWeightKg: 61.0,
        stageExpenditureKcal: 4950.0,
        glycogenStorePercent: 34.0,
        glycogenCapacityG: 590.0,
        microbiomeDiversityIndex: 84.0,
        gutTrainingLevel: 88,
        assignedStrategy: NutritionMenuStrategy.highCarbGlycogenLoad,
        dailyProbioticCourseActive: true,
      ),
      RiderNutritionalProfile(
        riderId: 'rider_climber_2',
        riderName: 'Mateo Bernal',
        role: 'Góral #2',
        bodyWeightKg: 58.2,
        targetRaceWeightKg: 58.0,
        stageExpenditureKcal: 4680.0,
        glycogenStorePercent: 41.0,
        glycogenCapacityG: 560.0,
        microbiomeDiversityIndex: 73.0,
        gutTrainingLevel: 76,
        assignedStrategy: NutritionMenuStrategy.balancedEndurance,
        dailyProbioticCourseActive: false,
      ),
      RiderNutritionalProfile(
        riderId: 'rider_sprinter_3',
        riderName: 'Luca De Vries',
        role: 'Sprinter',
        bodyWeightKg: 76.4,
        targetRaceWeightKg: 75.5,
        stageExpenditureKcal: 3620.0,
        glycogenStorePercent: 62.0,
        glycogenCapacityG: 710.0,
        microbiomeDiversityIndex: 66.0,
        gutTrainingLevel: 72,
        assignedStrategy: NutritionMenuStrategy.weightCutDeficit,
        dailyProbioticCourseActive: false,
      ),
      RiderNutritionalProfile(
        riderId: 'rider_leadout_4',
        riderName: 'Sander Van Dijk',
        role: 'Rozprowadzający',
        bodyWeightKg: 74.0,
        targetRaceWeightKg: 74.0,
        stageExpenditureKcal: 4120.0,
        glycogenStorePercent: 55.0,
        glycogenCapacityG: 685.0,
        microbiomeDiversityIndex: 81.0,
        gutTrainingLevel: 82,
        assignedStrategy: NutritionMenuStrategy.balancedEndurance,
        dailyProbioticCourseActive: true,
      ),
      RiderNutritionalProfile(
        riderId: 'rider_rouleur_5',
        riderName: 'Kasper Nielsen',
        role: 'Rouleur / Silnik',
        bodyWeightKg: 78.5,
        targetRaceWeightKg: 78.0,
        stageExpenditureKcal: 5340.0,
        glycogenStorePercent: 28.0,
        glycogenCapacityG: 740.0,
        microbiomeDiversityIndex: 59.0,
        gutTrainingLevel: 65,
        assignedStrategy: NutritionMenuStrategy.gutMicrobiomeProbioticReset,
        dailyProbioticCourseActive: true,
      ),
      RiderNutritionalProfile(
        riderId: 'rider_dom_6',
        riderName: 'Piotr Nowak',
        role: 'Pomocnik Górski',
        bodyWeightKg: 65.8,
        targetRaceWeightKg: 65.5,
        stageExpenditureKcal: 4410.0,
        glycogenStorePercent: 48.0,
        glycogenCapacityG: 625.0,
        microbiomeDiversityIndex: 77.0,
        gutTrainingLevel: 79,
        assignedStrategy: NutritionMenuStrategy.balancedEndurance,
        dailyProbioticCourseActive: false,
      ),
    ];
  }

  /// Wylicza precyzyjny bilans energetyczny i makroskładniki na podstawie wydatku
  /// etapowego, BMR, termogenezy powysiłkowej oraz wybranej strategii menu.
  CaloricBalanceCalculation calculateCaloricBalance(
    RiderNutritionalProfile rider,
    TeamChefProfile chef,
    KitchenBusEquipmentTier kitchen, {
    required bool isRestDay,
  }) {
    final double bmrKcal = rider.basalMetabolicRateKcal;
    // W dzień przerwy lekki rozjazd Coffee Ride spala ok. 480 kcal.
    final double stageBurnKcal =
        isRestDay ? 480.0 : math.max(0.0, rider.stageExpenditureKcal);
    final double recoveryThermogenesisKcal = stageBurnKcal * 0.095;
    final double totalDailyExpenditureKcal =
        bmrKcal + stageBurnKcal + recoveryThermogenesisKcal;

    final double strategyBias = rider.assignedStrategy.calorieAdjustmentKcal;
    final double precisionFactor = kitchen.macroPrecisionBonus;
    final double plannedIntakeKcal = math.max(
      1750.0,
      totalDailyExpenditureKcal + (strategyBias * precisionFactor),
    );

    final double netCaloricBalanceKcal =
        plannedIntakeKcal - totalDailyExpenditureKcal;

    final double carbsPerKg = rider.assignedStrategy.targetCarbsPerKg;
    final double proteinPerKg = rider.assignedStrategy.targetProteinPerKg;

    double carbsGrams = carbsPerKg * rider.bodyWeightKg;
    final double proteinGrams = proteinPerKg * rider.bodyWeightKg;

    // Skalujemy węglowodany przy wysokich wydatkach na górskich etapach (>4500 kcal)
    final double kcalFromChoAndPro = carbsGrams * 4.0 + proteinGrams * 4.0;
    if (plannedIntakeKcal > kcalFromChoAndPro + 450.0) {
      final double remainingForChoAndFat =
          plannedIntakeKcal - kcalFromChoAndPro;
      final double fatBudgetKcal = math.min(
        rider.assignedStrategy.targetFatPerKg * rider.bodyWeightKg * 9.0,
        remainingForChoAndFat * 0.45,
      );
      final double extraChoKcal = math.max(0.0, remainingForChoAndFat - fatBudgetKcal);
      carbsGrams += extraChoKcal / 4.0;
    }

    final double fatKcal = math.max(
      320.0,
      plannedIntakeKcal - (carbsGrams * 4.0 + proteinGrams * 4.0),
    );
    final double fatGrams = fatKcal / 9.0;
    final double effectiveCarbsPerKg = carbsGrams / math.max(40.0, rider.bodyWeightKg);

    // 7700 kcal ~ 1 kg tkanki, w trakcie wyścigu część to woda i glikogen.
    final double estimatedWeightDeltaKgPerWeek =
        (netCaloricBalanceKcal * 7.0) / 7700.0;

    final bool redSRisk =
        netCaloricBalanceKcal < -420.0 ||
        (effectiveCarbsPerKg < 5.5 && !isRestDay);

    return CaloricBalanceCalculation(
      bmrKcal: bmrKcal,
      stageBurnKcal: stageBurnKcal,
      recoveryThermogenesisKcal: recoveryThermogenesisKcal,
      totalDailyExpenditureKcal: totalDailyExpenditureKcal,
      plannedIntakeKcal: plannedIntakeKcal,
      netCaloricBalanceKcal: netCaloricBalanceKcal,
      carbsGrams: carbsGrams,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbsPerKg: effectiveCarbsPerKg,
      proteinPerKg: proteinPerKg,
      estimatedWeightDeltaKgPerWeek: estimatedWeightDeltaKgPerWeek,
      relativeEnergyDeficiencyRisk: redSRisk,
    );
  }

  /// Symuluje nocną odbudowę glikogenu mięśniowego/wątrobowego oraz reakcję
  /// mikrobiomu jelitowego na wybrane menu i suplementację probiotyczną.
  GlycogenAndMicrobiomeRecoveryReport simulateOvernightRecovery(
    RiderNutritionalProfile rider,
    TeamChefProfile chef,
    KitchenBusEquipmentTier kitchen, {
    required bool isRestDay,
  }) {
    final CaloricBalanceCalculation balance = calculateCaloricBalance(
      rider,
      chef,
      kitchen,
      isRestDay: isRestDay,
    );

    final double microbiomeBefore = rider.microbiomeDiversityIndex.clamp(0.0, 100.0);
    double microbiomeDelta = rider.assignedStrategy.microbiomeDeltaBase;

    if (rider.dailyProbioticCourseActive) {
      microbiomeDelta += 4.2 + (chef.microbiomeExpertise / 100.0) * 3.0;
    }
    microbiomeDelta += kitchen.probioticFermentationBonus * 0.45;

    // Duże obciążenie węglowodanami przy niskim wytrenowaniu jelit obniża florę
    if (rider.assignedStrategy == NutritionMenuStrategy.highCarbGlycogenLoad &&
        rider.gutTrainingLevel < 75 &&
        !rider.dailyProbioticCourseActive) {
      microbiomeDelta -= 2.4;
    }

    final double microbiomeAfter =
        (microbiomeBefore + microbiomeDelta).clamp(15.0, 100.0);

    final MicrobiomeHealthState microbiomeState =
        _classifyMicrobiomeState(microbiomeAfter);

    // Efektywność wchłaniania węglowodanów zależy od stanu mikrobiomu i wiedzy szefa.
    final double gutAbsorptionEfficiency =
        (0.72 + (microbiomeAfter / 100.0) * 0.28).clamp(0.65, 1.05);
    final double chefSkillFactor =
        chef.tier.glycogenSynthesisMultiplier *
        (0.95 + (chef.sportsNutritionKnowledge / 100.0) * 0.08);
    final double restDayMultiplier = isRestDay ? 1.24 : 1.0;

    final double startingGlycogen = rider.glycogenStorePercent.clamp(0.0, 100.0);
    final double deficitToFullG =
        ((100.0 - startingGlycogen) / 100.0) * rider.glycogenCapacityG;

    // Ok. 48–62% spożytych węglowodanów trafia bezpośrednio do odbudowy glikogenu w oknie 14h
    final double rawSynthesisCapacityG =
        balance.carbsGrams *
        0.54 *
        gutAbsorptionEfficiency *
        chefSkillFactor *
        restDayMultiplier *
        (balance.netCaloricBalanceKcal < -400.0 ? 0.78 : 1.0);

    final double restoredG = math.min(deficitToFullG, rawSynthesisCapacityG);
    final double restoredPct =
        (restoredG / math.max(300.0, rider.glycogenCapacityG)) * 100.0;
    final double endingGlycogen =
        (startingGlycogen + restoredPct).clamp(10.0, 100.0);

    final double giDistressRisk = _computeGiDistressRisk(
      rider: rider,
      microbiomeAfter: microbiomeAfter,
      chef: chef,
      kitchen: kitchen,
      carbsPerKg: balance.carbsPerKg,
    );

    final double maxCarbAbsorption = (62.0 +
            (rider.gutTrainingLevel / 100.0) * 28.0 +
            (microbiomeAfter / 100.0) * 24.0 +
            (chef.tier.giToleranceBonus * 0.4))
        .clamp(55.0, 125.0);

    final double nextStageAvailability = (endingGlycogen * 0.65 +
            microbiomeAfter * 0.20 +
            (100.0 - giDistressRisk) * 0.15)
        .clamp(15.0, 100.0);

    double moraleDelta = chef.moraleBonus * 0.35;
    if (rider.assignedStrategy == NutritionMenuStrategy.weightCutDeficit) {
      moraleDelta -= 2.2;
    } else if (endingGlycogen >= 92.0) {
      moraleDelta += 2.5;
    }
    if (balance.relativeEnergyDeficiencyRisk) {
      moraleDelta -= 3.5;
    }

    final double weightDeltaKg =
        (balance.netCaloricBalanceKcal / 7700.0) +
        (restoredG * 0.0024); // każdy gram glikogenu wiąże ~2.4-3g wody

    final List<String> notes = _buildChefNotes(
      rider: rider,
      balance: balance,
      endingGlycogen: endingGlycogen,
      microbiomeAfter: microbiomeAfter,
      giDistressRisk: giDistressRisk,
      isRestDay: isRestDay,
    );

    return GlycogenAndMicrobiomeRecoveryReport(
      riderId: rider.riderId,
      riderName: rider.riderName,
      caloricBalance: balance,
      startingGlycogenPercent: startingGlycogen,
      endingGlycogenPercent: endingGlycogen,
      glycogenRestoredGrams: restoredG,
      nextStageAvailabilityScore: nextStageAvailability,
      microbiomeBefore: microbiomeBefore,
      microbiomeAfter: microbiomeAfter,
      microbiomeState: microbiomeState,
      giDistressRiskPercent: giDistressRisk,
      maxOnBikeCarbAbsorptionGPerHour: maxCarbAbsorption,
      moraleDelta: moraleDelta,
      weightDeltaKg: weightDeltaKg,
      chefNotes: notes,
    );
  }

  /// Przetwarza cały skład drużyny na dany dzień i zwraca raport zbiorczy.
  TeamDailyCateringSummary processTeamDayCatering({
    required int dayIndex,
    required String stageName,
    required bool isRestDay,
    required TeamChefProfile chef,
    required KitchenBusEquipmentTier kitchen,
    required List<RiderNutritionalProfile> roster,
  }) {
    if (roster.isEmpty) {
      return TeamDailyCateringSummary(
        dayIndex: dayIndex,
        stageName: stageName,
        isRestDay: isRestDay,
        totalCateringCostEur: chef.dailySalaryEur + kitchen.dailyOperatingCostEur,
        averageGlycogenPercent: 0.0,
        averageMicrobiomeIndex: 0.0,
        ridersAtBonkRisk: 0,
        ridersWithRedSWarning: 0,
        teamMoraleDelta: 0.0,
        reports: const [],
      );
    }

    final List<GlycogenAndMicrobiomeRecoveryReport> reports = roster
        .map(
          (r) => simulateOvernightRecovery(
            r,
            chef,
            kitchen,
            isRestDay: isRestDay,
          ),
        )
        .toList();

    final double avgGlycogen = reports
            .map((r) => r.endingGlycogenPercent)
            .reduce((a, b) => a + b) /
        reports.length;
    final double avgMicrobiome =
        reports.map((r) => r.microbiomeAfter).reduce((a, b) => a + b) /
            reports.length;
    final int bonkRiskCount =
        reports.where((r) => r.endingGlycogenPercent < 70.0).length;
    final int redSCount = reports
        .where((r) => r.caloricBalance.relativeEnergyDeficiencyRisk)
        .length;
    final double avgMorale =
        reports.map((r) => r.moraleDelta).reduce((a, b) => a + b) /
            reports.length;

    final int probioticCoursesCount =
        roster.where((r) => r.dailyProbioticCourseActive).length;
    final double foodIngredientsCost = roster.length * 145.0 +
        probioticCoursesCount * 42.0 +
        (isRestDay ? 220.0 : 0.0);

    final double totalCost = chef.dailySalaryEur +
        kitchen.dailyOperatingCostEur +
        foodIngredientsCost;

    return TeamDailyCateringSummary(
      dayIndex: dayIndex,
      stageName: stageName,
      isRestDay: isRestDay,
      totalCateringCostEur: totalCost,
      averageGlycogenPercent: avgGlycogen,
      averageMicrobiomeIndex: avgMicrobiome,
      ridersAtBonkRisk: bonkRiskCount,
      ridersWithRedSWarning: redSCount,
      teamMoraleDelta: avgMorale,
      reports: reports,
    );
  }

  /// Dobiera optymalną strategię żywieniową i probiotykę dla każdego kolarza.
  List<RiderNutritionalProfile> autoOptimizeRosterMenu(
    List<RiderNutritionalProfile> roster, {
    required bool isRestDay,
  }) {
    return roster.map((rider) {
      if (rider.microbiomeDiversityIndex < 68.0) {
        return rider.copyWith(
          assignedStrategy: NutritionMenuStrategy.gutMicrobiomeProbioticReset,
          dailyProbioticCourseActive: true,
        );
      }
      if (isRestDay && rider.glycogenStorePercent < 78.0) {
        return rider.copyWith(
          assignedStrategy: NutritionMenuStrategy.restDaySupercompensation,
          dailyProbioticCourseActive: true,
        );
      }
      if (rider.glycogenStorePercent < 50.0 ||
          rider.stageExpenditureKcal > 4600.0) {
        return rider.copyWith(
          assignedStrategy: NutritionMenuStrategy.highCarbGlycogenLoad,
          dailyProbioticCourseActive: rider.microbiomeDiversityIndex < 80.0,
        );
      }
      if (rider.bodyWeightKg - rider.targetRaceWeightKg >= 0.7 &&
          rider.glycogenStorePercent >= 60.0) {
        return rider.copyWith(
          assignedStrategy: NutritionMenuStrategy.weightCutDeficit,
        );
      }
      return rider.copyWith(
        assignedStrategy: NutritionMenuStrategy.balancedEndurance,
      );
    }).toList();
  }

  MicrobiomeHealthState _classifyMicrobiomeState(double index) {
    if (index >= 85.0) return MicrobiomeHealthState.optimalDiversity;
    if (index >= 68.0) return MicrobiomeHealthState.balancedFlora;
    if (index >= 50.0) return MicrobiomeHealthState.mildDysbiosis;
    return MicrobiomeHealthState.acuteGiDistress;
  }

  double _computeGiDistressRisk({
    required RiderNutritionalProfile rider,
    required double microbiomeAfter,
    required TeamChefProfile chef,
    required KitchenBusEquipmentTier kitchen,
    required double carbsPerKg,
  }) {
    double risk = 18.0;
    risk += math.max(0.0, (75.0 - microbiomeAfter) * 0.55);
    risk += math.max(0.0, (carbsPerKg - 9.0) * 3.8);
    risk += math.max(0.0, (80 - rider.gutTrainingLevel) * 0.25);
    risk -= chef.tier.giToleranceBonus * 0.65;
    risk -= (kitchen.foodSafetyHygieneScore - 70.0) * 0.35;
    if (rider.dailyProbioticCourseActive) {
      risk -= 5.5;
    }
    return risk.clamp(2.0, 68.0);
  }

  List<String> _buildChefNotes({
    required RiderNutritionalProfile rider,
    required CaloricBalanceCalculation balance,
    required double endingGlycogen,
    required double microbiomeAfter,
    required double giDistressRisk,
    required bool isRestDay,
  }) {
    final List<String> notes = [];
    if (endingGlycogen >= 93.0) {
      notes.add(
        'Pełna odbudowa glikogenu (${endingGlycogen.toStringAsFixed(0)}%) — kolarz gotowy na maksymalny wysiłek.',
      );
    } else if (endingGlycogen < 70.0) {
      notes.add(
        'Ostrzeżenie: niski zapas glikogenu (${endingGlycogen.toStringAsFixed(0)}%)! Zwiększ podaż węglowodanów.',
      );
    }
    if (balance.relativeEnergyDeficiencyRisk) {
      notes.add(
        'Uwaga RED-S: głęboki deficyt (${balance.netCaloricBalanceKcal.toStringAsFixed(0)} kcal) grozi spadkiem odporności.',
      );
    }
    if (microbiomeAfter < 65.0) {
      notes.add(
        'Dysbioza jelitowa (${microbiomeAfter.toStringAsFixed(0)}/100) ogranicza wchłanianie żeli na trasie.',
      );
    } else if (rider.dailyProbioticCourseActive) {
      notes.add(
        'Kuracja probiotyczna stabilizuje mikrobiom (${microbiomeAfter.toStringAsFixed(0)}/100).',
      );
    }
    if (giDistressRisk > 25.0) {
      notes.add(
        'Podwyższone ryzyko problemów żołądkowych (${giDistressRisk.toStringAsFixed(0)}%) przy wysokim tempie.',
      );
    }
    if (isRestDay &&
        rider.assignedStrategy ==
            NutritionMenuStrategy.restDaySupercompensation) {
      notes.add('Dzień przerwy wykorzystany na superkompensację glikogenu.');
    }
    if (notes.isEmpty) {
      notes.add('Bilans makroskładników i regeneracja przebiegają prawidłowo.');
    }
    return notes;
  }
}

/// Stan Riverpod modułu Szefa Kuchni i Mikrobiomu.
@immutable
class TeamBusChefNutritionState {
  final TeamChefProfile activeChef;
  final KitchenBusEquipmentTier kitchenTier;
  final int dayIndex;
  final String stageName;
  final bool isRestDay;
  final List<RiderNutritionalProfile> roster;
  final String? selectedRiderId;
  final TeamDailyCateringSummary lastSummary;

  const TeamBusChefNutritionState({
    required this.activeChef,
    required this.kitchenTier,
    required this.dayIndex,
    required this.stageName,
    required this.isRestDay,
    required this.roster,
    required this.selectedRiderId,
    required this.lastSummary,
  });

  TeamBusChefNutritionState copyWith({
    TeamChefProfile? activeChef,
    KitchenBusEquipmentTier? kitchenTier,
    int? dayIndex,
    String? stageName,
    bool? isRestDay,
    List<RiderNutritionalProfile>? roster,
    String? selectedRiderId,
    TeamDailyCateringSummary? lastSummary,
  }) {
    return TeamBusChefNutritionState(
      activeChef: activeChef ?? this.activeChef,
      kitchenTier: kitchenTier ?? this.kitchenTier,
      dayIndex: dayIndex ?? this.dayIndex,
      stageName: stageName ?? this.stageName,
      isRestDay: isRestDay ?? this.isRestDay,
      roster: roster ?? this.roster,
      selectedRiderId: selectedRiderId ?? this.selectedRiderId,
      lastSummary: lastSummary ?? this.lastSummary,
    );
  }
}

class TeamBusChefNutritionNotifier
    extends StateNotifier<TeamBusChefNutritionState> {
  final TeamBusChefAndMicrobiomeNutritionService _service;

  TeamBusChefNutritionNotifier({
    TeamBusChefAndMicrobiomeNutritionService service =
        const TeamBusChefAndMicrobiomeNutritionService(),
  })  : _service = service,
        super(_createInitialState(service));

  static TeamBusChefNutritionState _createInitialState(
    TeamBusChefAndMicrobiomeNutritionService service,
  ) {
    final chef = TeamBusChefAndMicrobiomeNutritionService.availableChefsCatalog.first;
    const kitchen = KitchenBusEquipmentTier.proTourCulinaryTruck;
    final roster =
        TeamBusChefAndMicrobiomeNutritionService.createDefaultGrandTourRoster();
    final summary = service.processTeamDayCatering(
      dayIndex: 14,
      stageName: 'Etap 14: Pau → Saint-Lary-Soulan (Pla d\'Adet)',
      isRestDay: false,
      chef: chef,
      kitchen: kitchen,
      roster: roster,
    );
    return TeamBusChefNutritionState(
      activeChef: chef,
      kitchenTier: kitchen,
      dayIndex: 14,
      stageName: 'Etap 14: Pau → Saint-Lary-Soulan (Pla d\'Adet)',
      isRestDay: false,
      roster: roster,
      selectedRiderId: roster.first.riderId,
      lastSummary: summary,
    );
  }

  void _recalculate() {
    final summary = _service.processTeamDayCatering(
      dayIndex: state.dayIndex,
      stageName: state.stageName,
      isRestDay: state.isRestDay,
      chef: state.activeChef,
      kitchen: state.kitchenTier,
      roster: state.roster,
    );
    state = state.copyWith(lastSummary: summary);
  }

  void selectChef(TeamChefProfile chef) {
    state = state.copyWith(activeChef: chef);
    _recalculate();
  }

  void setKitchenTier(KitchenBusEquipmentTier tier) {
    state = state.copyWith(kitchenTier: tier);
    _recalculate();
  }

  void selectRider(String riderId) {
    state = state.copyWith(selectedRiderId: riderId);
  }

  void toggleRestDay(bool isRestDay) {
    state = state.copyWith(isRestDay: isRestDay);
    _recalculate();
  }

  void setRiderStrategy(String riderId, NutritionMenuStrategy strategy) {
    final updated = state.roster
        .map(
          (r) => r.riderId == riderId ? r.copyWith(assignedStrategy: strategy) : r,
        )
        .toList();
    state = state.copyWith(roster: updated);
    _recalculate();
  }

  void toggleProbioticCourse(String riderId) {
    final updated = state.roster
        .map(
          (r) => r.riderId == riderId
              ? r.copyWith(
                  dailyProbioticCourseActive: !r.dailyProbioticCourseActive,
                )
              : r,
        )
        .toList();
    state = state.copyWith(roster: updated);
    _recalculate();
  }

  void autoOptimizeMenu() {
    final optimized = _service.autoOptimizeRosterMenu(
      state.roster,
      isRestDay: state.isRestDay,
    );
    state = state.copyWith(roster: optimized);
    _recalculate();
  }

  /// Zatwierdza nocną regenerację i przenosi wyliczone wartości glikogenu oraz
  /// mikrobiomu do kolejnego dnia wyścigu.
  void commitOvernightRecovery() {
    final reportsById = {
      for (final rep in state.lastSummary.reports) rep.riderId: rep,
    };
    final nextRoster = state.roster.map((r) {
      final rep = reportsById[r.riderId];
      if (rep == null) return r;
      return r.copyWith(
        glycogenStorePercent: rep.endingGlycogenPercent,
        microbiomeDiversityIndex: rep.microbiomeAfter,
        bodyWeightKg: (r.bodyWeightKg + rep.weightDeltaKg).clamp(50.0, 95.0),
      );
    }).toList();

    final nextDay = state.dayIndex + 1;
    state = state.copyWith(
      dayIndex: nextDay,
      stageName: 'Etap $nextDay: Kolejny dzień rywalizacji',
      roster: nextRoster,
    );
    _recalculate();
  }
}

final teamBusChefNutritionProvider = StateNotifierProvider<
    TeamBusChefNutritionNotifier, TeamBusChefNutritionState>(
  (ref) => TeamBusChefNutritionNotifier(),
);

/// Produkcyjny panel UI Szefa Kuchni Drużyny, bilansu kalorycznego i regeneracji glikogenu.
/// Responsywny dla 390x844 (mobile), 1024x768 (tablet) oraz 1600x900 (desktop).
class TeamBusChefAndMicrobiomeNutritionPanel extends ConsumerWidget {
  const TeamBusChefAndMicrobiomeNutritionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamBusChefNutritionProvider);
    final notifier = ref.read(teamBusChefNutritionProvider.notifier);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool isDesktop = width >= 1180;
          final bool isCompact = width < 640;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderControlCard(
                  state: state,
                  isCompact: isCompact,
                  onChefSelected: notifier.selectChef,
                  onKitchenSelected: notifier.setKitchenTier,
                  onRestDayToggled: notifier.toggleRestDay,
                  onAutoOptimize: notifier.autoOptimizeMenu,
                  onCommitRecovery: notifier.commitOvernightRecovery,
                ),
                const SizedBox(height: 16),
                _KpiSummaryRow(
                  summary: state.lastSummary,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _RosterNutritionListCard(
                          state: state,
                          onSelectRider: notifier.selectRider,
                          onStrategyChanged: notifier.setRiderStrategy,
                          onToggleProbiotic: notifier.toggleProbioticCourse,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _SelectedRiderDetailCard(state: state),
                      ),
                    ],
                  )
                else ...[
                  _RosterNutritionListCard(
                    state: state,
                    onSelectRider: notifier.selectRider,
                    onStrategyChanged: notifier.setRiderStrategy,
                    onToggleProbiotic: notifier.toggleProbioticCourse,
                  ),
                  const SizedBox(height: 16),
                  _SelectedRiderDetailCard(state: state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderControlCard extends StatelessWidget {
  final TeamBusChefNutritionState state;
  final bool isCompact;
  final ValueChanged<TeamChefProfile> onChefSelected;
  final ValueChanged<KitchenBusEquipmentTier> onKitchenSelected;
  final ValueChanged<bool> onRestDayToggled;
  final VoidCallback onAutoOptimize;
  final VoidCallback onCommitRecovery;

  const _HeaderControlCard({
    required this.state,
    required this.isCompact,
    required this.onChefSelected,
    required this.onKitchenSelected,
    required this.onRestDayToggled,
    required this.onAutoOptimize,
    required this.onCommitRecovery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.restaurant_menu_rounded,
                        color: AppColors.goldAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'SZEF KUCHNI DRUŻYNY & MIKROBIOM',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: isCompact ? 15 : 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.stageName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InteractiveActionButton(
                    label: state.isRestDay ? 'Dzień Przerwy: TAK' : 'Dzień Etapowy',
                    icon: Icons.hotel_rounded,
                    isActive: state.isRestDay,
                    accentColor: AppColors.goldAccent,
                    onTap: () => onRestDayToggled(!state.isRestDay),
                  ),
                  _InteractiveActionButton(
                    label: 'Auto-Optymalizuj Menu',
                    icon: Icons.auto_fix_high_rounded,
                    isActive: false,
                    accentColor: AppColors.accentBlue,
                    onTap: onAutoOptimize,
                  ),
                  _InteractiveActionButton(
                    label: 'Zatwierdź Regenerację',
                    icon: Icons.check_circle_outline_rounded,
                    isActive: true,
                    accentColor: AppColors.statusSuccess,
                    onTap: onCommitRecovery,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 340,
                child: _ChefSelectorBox(
                  activeChef: state.activeChef,
                  onSelected: onChefSelected,
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : 320,
                child: _KitchenTierSelectorBox(
                  activeTier: state.kitchenTier,
                  onSelected: onKitchenSelected,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChefSelectorBox extends StatelessWidget {
  final TeamChefProfile activeChef;
  final ValueChanged<TeamChefProfile> onSelected;

  const _ChefSelectorBox({
    required this.activeChef,
    required this.onSelected,
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeChef.id,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          items: TeamBusChefAndMicrobiomeNutritionService.availableChefsCatalog
              .map(
                (chef) => DropdownMenuItem<String>(
                  value: chef.id,
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: chef.tier.badgeColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${chef.name} (${chef.nationality}) — ${chef.tier.displayName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final found = TeamBusChefAndMicrobiomeNutritionService
                .availableChefsCatalog
                .firstWhere((c) => c.id == id);
            onSelected(found);
          },
        ),
      ),
    );
  }
}

class _KitchenTierSelectorBox extends StatelessWidget {
  final KitchenBusEquipmentTier activeTier;
  final ValueChanged<KitchenBusEquipmentTier> onSelected;

  const _KitchenTierSelectorBox({
    required this.activeTier,
    required this.onSelected,
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<KitchenBusEquipmentTier>(
          value: activeTier,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          items: KitchenBusEquipmentTier.values
              .map(
                (tier) => DropdownMenuItem<KitchenBusEquipmentTier>(
                  value: tier,
                  child: Text(
                    '${tier.displayName} (${Formatters.formatCurrency(tier.dailyOperatingCostEur)}/d)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (tier) {
            if (tier != null) onSelected(tier);
          },
        ),
      ),
    );
  }
}

class _KpiSummaryRow extends StatelessWidget {
  final TeamDailyCateringSummary summary;
  final bool isCompact;

  const _KpiSummaryRow({
    required this.summary,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiTile(
        label: 'Śr. Glikogen Rano',
        value: '${summary.averageGlycogenPercent.toStringAsFixed(1)}%',
        accent: summary.averageGlycogenPercent >= 85
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.bolt_rounded,
      ),
      _KpiTile(
        label: 'Śr. Mikrobiom',
        value: '${summary.averageMicrobiomeIndex.toStringAsFixed(1)}/100',
        accent: summary.averageMicrobiomeIndex >= 75
            ? AppColors.cyanAccent
            : AppColors.amberWarning,
        icon: Icons.biotech_rounded,
      ),
      _KpiTile(
        label: 'Koszt Cateringu',
        value: Formatters.formatCurrency(summary.totalCateringCostEur),
        accent: AppColors.goldAccent,
        icon: Icons.euro_rounded,
      ),
      _KpiTile(
        label: 'Alerty Bonk / RED-S',
        value: '${summary.ridersAtBonkRisk} / ${summary.ridersWithRedSWarning}',
        accent: (summary.ridersAtBonkRisk + summary.ridersWithRedSWarning) == 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.warning_amber_rounded,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
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

class _RosterNutritionListCard extends StatelessWidget {
  final TeamBusChefNutritionState state;
  final ValueChanged<String> onSelectRider;
  final void Function(String riderId, NutritionMenuStrategy strategy)
      onStrategyChanged;
  final ValueChanged<String> onToggleProbiotic;

  const _RosterNutritionListCard({
    required this.state,
    required this.onSelectRider,
    required this.onStrategyChanged,
    required this.onToggleProbiotic,
  });

  @override
  Widget build(BuildContext context) {
    final reportsById = {
      for (final rep in state.lastSummary.reports) rep.riderId: rep,
    };

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
          const Text(
            'PLAN POSIŁKÓW KOLARZY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final rider in state.roster) ...[
            _RiderNutritionRow(
              rider: rider,
              report: reportsById[rider.riderId],
              isSelected: rider.riderId == state.selectedRiderId,
              onTap: () => onSelectRider(rider.riderId),
              onStrategyChanged: (s) => onStrategyChanged(rider.riderId, s),
              onToggleProbiotic: () => onToggleProbiotic(rider.riderId),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RiderNutritionRow extends StatefulWidget {
  final RiderNutritionalProfile rider;
  final GlycogenAndMicrobiomeRecoveryReport? report;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<NutritionMenuStrategy> onStrategyChanged;
  final VoidCallback onToggleProbiotic;

  const _RiderNutritionRow({
    required this.rider,
    required this.report,
    required this.isSelected,
    required this.onTap,
    required this.onStrategyChanged,
    required this.onToggleProbiotic,
  });

  @override
  State<_RiderNutritionRow> createState() => _RiderNutritionRowState();
}

class _RiderNutritionRowState extends State<_RiderNutritionRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final rep = widget.report;
    final double endGlycogen = rep?.endingGlycogenPercent ?? widget.rider.glycogenStorePercent;
    final double netKcal = rep?.caloricBalance.netCaloricBalanceKcal ?? 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : (_hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.65)
                      : AppColors.background.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : (_focused ? AppColors.accentBlue : AppColors.cardBorder),
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          widget.rider.riderName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.rider.role} • ${widget.rider.bodyWeightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${netKcal >= 0 ? '+' : ''}${netKcal.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: netKcal < -500
                            ? AppColors.crimsonAlert
                            : (netKcal >= 0
                                ? AppColors.statusSuccess
                                : AppColors.amberWarning),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (endGlycogen / 100.0).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: AppColors.background,
                    color: endGlycogen >= 85
                        ? AppColors.statusSuccess
                        : (endGlycogen >= 65
                            ? AppColors.amberWarning
                            : AppColors.crimsonAlert),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 235),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<NutritionMenuStrategy>(
                            value: widget.rider.assignedStrategy,
                            dropdownColor: AppColors.surfaceLight,
                            isDense: true,
                            isExpanded: true,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                            items: NutritionMenuStrategy.values
                                .map(
                                  (s) => DropdownMenuItem<NutritionMenuStrategy>(
                                    value: s,
                                    child: Text(
                                      s.displayName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (s) {
                              if (s != null) widget.onStrategyChanged(s);
                            },
                          ),
                        ),
                      ),
                    ),
                    _InteractiveActionButton(
                      label: widget.rider.dailyProbioticCourseActive
                          ? 'Probiotyk: WŁ'
                          : 'Probiotyk: WYŁ',
                      icon: Icons.vaccines_rounded,
                      isActive: widget.rider.dailyProbioticCourseActive,
                      accentColor: AppColors.statusSuccess,
                      onTap: widget.onToggleProbiotic,
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

class _SelectedRiderDetailCard extends StatelessWidget {
  final TeamBusChefNutritionState state;

  const _SelectedRiderDetailCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final report = state.lastSummary.reports.firstWhere(
      (r) => r.riderId == state.selectedRiderId,
      orElse: () => state.lastSummary.reports.first,
    );
    final bal = report.caloricBalance;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'RAPORT METABOLICZNY: ${report.riderName.toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: report.microbiomeState.statusColor
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.microbiomeState.displayName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: report.microbiomeState.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MetricLine(
            label: 'Całkowite zużycie energii (BMR + Etap)',
            value: '${bal.totalDailyExpenditureKcal.toStringAsFixed(0)} kcal',
          ),
          _MetricLine(
            label: 'Planowana podaż z kuchni autobusu',
            value: '${bal.plannedIntakeKcal.toStringAsFixed(0)} kcal',
          ),
          _MetricLine(
            label: 'Makroskładniki (CHO / PRO / FAT)',
            value:
                '${bal.carbsGrams.toStringAsFixed(0)}g / ${bal.proteinGrams.toStringAsFixed(0)}g / ${bal.fatGrams.toStringAsFixed(0)}g',
          ),
          _MetricLine(
            label: 'Odbudowa glikogenu nocą',
            value:
                '${report.startingGlycogenPercent.toStringAsFixed(0)}% → ${report.endingGlycogenPercent.toStringAsFixed(0)}% (+${report.glycogenRestoredGrams.toStringAsFixed(0)}g)',
          ),
          _MetricLine(
            label: 'Limit wchłaniania CHO na trasie',
            value:
                '${report.maxOnBikeCarbAbsorptionGPerHour.toStringAsFixed(0)} g/h (ryzyko GI: ${report.giDistressRiskPercent.toStringAsFixed(0)}%)',
          ),
          const SizedBox(height: 12),
          const Text(
            'NOTATKI SZEFA KUCHNI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 8),
          for (final note in report.chefNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
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

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetricLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
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
  final bool isActive;
  final Color accentColor;
  final VoidCallback? onTap;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
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
    final bool disabled = widget.onTap == null;
    final Color borderColor = disabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (widget.isActive || _focused
            ? widget.accentColor
            : (_hovered ? widget.accentColor.withValues(alpha: 0.7) : AppColors.cardBorder));

    final Color bgColor = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (widget.isActive
            ? widget.accentColor.withValues(alpha: _pressed ? 0.30 : 0.18)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.7)));

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: disabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : (widget.isActive
                          ? widget.accentColor
                          : AppColors.textPrimary),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: disabled
                        ? AppColors.textSecondary.withValues(alpha: 0.5)
                        : AppColors.textPrimary,
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
