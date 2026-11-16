import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/pro_cyclist_career_state.dart';

/// Dostępne miasta bazowe (rezydencje) dla kolarza w trybie Be a Pro.
enum CyclistResidenceCity {
  girona,
  andorra,
  livigno,
  monaco,
  flanders,
  sierraNevada;

  String toJson() => name;

  static CyclistResidenceCity fromJson(String value) {
    return CyclistResidenceCity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CyclistResidenceCity.girona,
    );
  }

  String get displayName {
    switch (this) {
      case CyclistResidenceCity.girona:
        return 'Girona';
      case CyclistResidenceCity.andorra:
        return 'Andora (Ordino)';
      case CyclistResidenceCity.livigno:
        return 'Livigno';
      case CyclistResidenceCity.monaco:
        return 'Monako';
      case CyclistResidenceCity.flanders:
        return 'Flandria (Oudenaarde)';
      case CyclistResidenceCity.sierraNevada:
        return 'Sierra Nevada';
    }
  }
}

/// Specyfikacja miejsca zamieszkania kolarza wraz z bonusami fizjologicznymi i podatkowymi.
class ResidenceOfferSpec {
  final String id;
  final CyclistResidenceCity city;
  final String title;
  final String country;
  final int altitudeMeters;
  final int purchasePriceEur;
  final int monthlyRentEur;
  final int monthlyUpkeepEur;
  final double enduranceTrainingBonusPercent;
  final double altitudeHematocritBonusPercent;
  final double cobbleAndWindTrainingBonusPercent;
  final double fameGainMultiplier;
  final double taxReductionPercent;
  final double recoveryBonusPercent;
  final ProCyclistPropertyCategory propertyCategory;
  final String summary;
  final Color accentColor;

  const ResidenceOfferSpec({
    required this.id,
    required this.city,
    required this.title,
    required this.country,
    required this.altitudeMeters,
    required this.purchasePriceEur,
    required this.monthlyRentEur,
    required this.monthlyUpkeepEur,
    this.enduranceTrainingBonusPercent = 0.0,
    this.altitudeHematocritBonusPercent = 0.0,
    this.cobbleAndWindTrainingBonusPercent = 0.0,
    this.fameGainMultiplier = 1.0,
    this.taxReductionPercent = 0.0,
    this.recoveryBonusPercent = 0.0,
    required this.propertyCategory,
    required this.summary,
    required this.accentColor,
  });

  ProCyclistRealEstate toRealEstate(DateTime purchasedDate) {
    return ProCyclistRealEstate(
      id: id,
      name: title,
      location: '${city.displayName}, $country',
      altitudeMeters: altitudeMeters,
      category: propertyCategory,
      purchasePriceEur: purchasePriceEur,
      monthlyUpkeepEur: monthlyUpkeepEur,
      recoveryBonusPercent: recoveryBonusPercent,
      altitudeAcclimatizationBonus: altitudeHematocritBonusPercent,
      taxShieldPercent: taxReductionPercent,
      purchasedDate: purchasedDate,
      isPrimaryResidence: true,
    );
  }
}

/// Identyfikatory prywatnego sprzętu treningowego i regeneracyjnego.
enum LifestyleUpgradeId {
  hypoxicTent,
  hyperbaricChamber,
  smartCryoRecovery,
  personalWattbikeLab;

  String toJson() => name;

  static LifestyleUpgradeId fromJson(String value) {
    return LifestyleUpgradeId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LifestyleUpgradeId.hypoxicTent,
    );
  }
}

/// Specyfikacja prywatnego zakupu sprzętowego (np. namiot hipoksyjny).
class LifestyleUpgradeSpec {
  final LifestyleUpgradeId id;
  final String name;
  final String subtitle;
  final int purchasePriceEur;
  final int monthlyMaintenanceEur;
  final double hematocritAdaptationBonusPercent;
  final double recoveryBonusPercent;
  final double thresholdTrainingBonusPercent;
  final double overtrainingRiskReductionPercent;
  final ProCyclistEquipmentCategory equipmentCategory;
  final Color accentColor;

  const LifestyleUpgradeSpec({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.purchasePriceEur,
    required this.monthlyMaintenanceEur,
    this.hematocritAdaptationBonusPercent = 0.0,
    this.recoveryBonusPercent = 0.0,
    this.thresholdTrainingBonusPercent = 0.0,
    this.overtrainingRiskReductionPercent = 0.0,
    required this.equipmentCategory,
    required this.accentColor,
  });

  ProCyclistPrivateEquipment toPrivateEquipment(DateTime purchasedDate) {
    return ProCyclistPrivateEquipment(
      id: 'upgrade_${id.name}',
      name: name,
      brand: 'ProLab Custom',
      category: equipmentCategory,
      purchasePriceEur: purchasePriceEur,
      recoveryBonusPercent: recoveryBonusPercent,
      trainingXpBonusPercent:
          thresholdTrainingBonusPercent + hematocritAdaptationBonusPercent,
      purchasedDate: purchasedDate,
      isEquipped: true,
    );
  }
}

/// Role osobistego sztabu prywatnego zatrudnianego z pensji kolarza.
enum PersonalSupportStaffRole {
  personalDietitian,
  personalOsteopath,
  personalMentalCoach,
  personalChef;

  String toJson() => name;

  static PersonalSupportStaffRole fromJson(String value) {
    return PersonalSupportStaffRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PersonalSupportStaffRole.personalDietitian,
    );
  }
}

/// Specyfikacja członka osobistego sztabu kolarza.
class PersonalSupportStaffSpec {
  final PersonalSupportStaffRole role;
  final String title;
  final String specialtySummary;
  final int monthlySalaryEur;
  final int signingFeeEur;
  final double recoveryBonusPercent;
  final double glycogenEfficiencyBonusPercent;
  final double injuryRiskReductionPercent;
  final double mentalResilienceBonusPercent;
  final Color accentColor;

  const PersonalSupportStaffSpec({
    required this.role,
    required this.title,
    required this.specialtySummary,
    required this.monthlySalaryEur,
    required this.signingFeeEur,
    this.recoveryBonusPercent = 0.0,
    this.glycogenEfficiencyBonusPercent = 0.0,
    this.injuryRiskReductionPercent = 0.0,
    this.mentalResilienceBonusPercent = 0.0,
    required this.accentColor,
  });
}

/// Sloty indywidualnych kontraktów reklamowych kolarza (każdy osobno).
enum PersonalSponsorSlotCategory {
  shoes,
  eyewear,
  watch;

  String toJson() => name;

  static PersonalSponsorSlotCategory fromJson(String value) {
    return PersonalSponsorSlotCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PersonalSponsorSlotCategory.shoes,
    );
  }

  String get label {
    switch (this) {
      case PersonalSponsorSlotCategory.shoes:
        return 'Buty kolarskie';
      case PersonalSponsorSlotCategory.eyewear:
        return 'Okulary';
      case PersonalSponsorSlotCategory.watch:
        return 'Zegarek / Wearable';
    }
  }
}

/// Oferta indywidualnego kontraktu reklamowego w wybranym slocie.
class PersonalSponsorOfferSpec {
  final String sponsorId;
  final String brandName;
  final PersonalSponsorSlotCategory slotCategory;
  final int monthlyRetainerEur;
  final int winBonusEur;
  final double minFameRequired;
  final ProCyclistCareerTier minTierRequired;
  final int contractYears;
  final double monthlyFameBoost;
  final String description;

  const PersonalSponsorOfferSpec({
    required this.sponsorId,
    required this.brandName,
    required this.slotCategory,
    required this.monthlyRetainerEur,
    required this.winBonusEur,
    required this.minFameRequired,
    required this.minTierRequired,
    required this.contractYears,
    required this.monthlyFameBoost,
    required this.description,
  });

  ProCyclistPersonalSponsor toPersonalSponsor(int currentYear) {
    return ProCyclistPersonalSponsor(
      sponsorId: sponsorId,
      brandName: brandName,
      categoryLabel: slotCategory.label,
      monthlyRetainerEur: monthlyRetainerEur,
      winBonusEur: winBonusEur,
      minFameRequired: minFameRequired,
      contractEndYear: currentYear + contractYears,
    );
  }
}

/// Kategorie instrumentów inwestycyjnych dla nadwyżek finansowych kolarza.
enum WealthInvestmentType {
  globalEtfIndex,
  sovereignBonds,
  gironaRentalApartment,
  pelotonCoffeeRoastery;

  String toJson() => name;

  static WealthInvestmentType fromJson(String value) {
    return WealthInvestmentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => WealthInvestmentType.globalEtfIndex,
    );
  }
}

/// Specyfikacja instrumentu inwestycyjnego.
class WealthInvestmentSpec {
  final WealthInvestmentType type;
  final String name;
  final String riskLabel;
  final int minInvestmentEur;
  final double annualYieldPercent;
  final double monthlyFameBonus;
  final String description;
  final Color accentColor;

  const WealthInvestmentSpec({
    required this.type,
    required this.name,
    required this.riskLabel,
    required this.minInvestmentEur,
    required this.annualYieldPercent,
    this.monthlyFameBonus = 0.0,
    required this.description,
    required this.accentColor,
  });
}

/// Pozycja w portfelu inwestycyjnym kolarza.
class WealthInvestmentHolding {
  final WealthInvestmentType type;
  final int investedPrincipalEur;
  final int accruedReturnEur;
  final DateTime openedDate;

  const WealthInvestmentHolding({
    required this.type,
    required this.investedPrincipalEur,
    this.accruedReturnEur = 0,
    required this.openedDate,
  });

  int get totalValueEur => investedPrincipalEur + accruedReturnEur;

  WealthInvestmentHolding copyWith({
    WealthInvestmentType? type,
    int? investedPrincipalEur,
    int? accruedReturnEur,
    DateTime? openedDate,
  }) {
    return WealthInvestmentHolding(
      type: type ?? this.type,
      investedPrincipalEur: investedPrincipalEur ?? this.investedPrincipalEur,
      accruedReturnEur: accruedReturnEur ?? this.accruedReturnEur,
      openedDate: openedDate ?? this.openedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'investedPrincipalEur': investedPrincipalEur,
      'accruedReturnEur': accruedReturnEur,
      'openedDate': openedDate.toIso8601String(),
    };
  }

  factory WealthInvestmentHolding.fromJson(Map<String, dynamic> json) {
    return WealthInvestmentHolding(
      type: WealthInvestmentType.fromJson(json['type'] as String),
      investedPrincipalEur: (json['investedPrincipalEur'] as num).toInt(),
      accruedReturnEur: (json['accruedReturnEur'] as num?)?.toInt() ?? 0,
      openedDate: DateTime.parse(json['openedDate'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WealthInvestmentHolding &&
        other.type == type &&
        other.investedPrincipalEur == investedPrincipalEur &&
        other.accruedReturnEur == accruedReturnEur;
  }

  @override
  int get hashCode =>
      Object.hash(type, investedPrincipalEur, accruedReturnEur);
}

/// Zbiorczy raport aktywnych premii wynikających z życia prywatnego kolarza.
class LifestyleBonusSummary {
  final CyclistResidenceCity activeCity;
  final bool isResidenceOwned;
  final double enduranceTrainingBonusPercent;
  final double altitudeHematocritBonusPercent;
  final double cobbleAndWindTrainingBonusPercent;
  final double thresholdTrainingBonusPercent;
  final double recoveryBonusPercent;
  final double glycogenEfficiencyBonusPercent;
  final double injuryRiskReductionPercent;
  final double fameGainMultiplier;
  final double effectiveTaxRatePercent;
  final int grossMonthlyIncomeEur;
  final int estimatedMonthlyTaxEur;
  final int monthlyLifestyleExpensesEur;
  final int estimatedMonthlyInvestmentYieldEur;
  final int projectedMonthlyNetCashflowEur;
  final int totalInvestmentPortfolioEur;
  final int totalNetWorthEur;

  const LifestyleBonusSummary({
    required this.activeCity,
    required this.isResidenceOwned,
    required this.enduranceTrainingBonusPercent,
    required this.altitudeHematocritBonusPercent,
    required this.cobbleAndWindTrainingBonusPercent,
    required this.thresholdTrainingBonusPercent,
    required this.recoveryBonusPercent,
    required this.glycogenEfficiencyBonusPercent,
    required this.injuryRiskReductionPercent,
    required this.fameGainMultiplier,
    required this.effectiveTaxRatePercent,
    required this.grossMonthlyIncomeEur,
    required this.estimatedMonthlyTaxEur,
    required this.monthlyLifestyleExpensesEur,
    required this.estimatedMonthlyInvestmentYieldEur,
    required this.projectedMonthlyNetCashflowEur,
    required this.totalInvestmentPortfolioEur,
    required this.totalNetWorthEur,
  });
}

/// Stan modułu życia prywatnego i zarządzania majątkiem kolarza.
class ProCyclistLifestyleState {
  final CyclistResidenceCity activeCity;
  final Set<LifestyleUpgradeId> ownedUpgrades;
  final Set<PersonalSupportStaffRole> hiredStaff;
  final Map<PersonalSponsorSlotCategory, ProCyclistPersonalSponsor>
      activeSponsorsBySlot;
  final List<WealthInvestmentHolding> investments;
  final int lastMonthlyTaxPaidEur;
  final int lastMonthlyInvestmentYieldEur;
  final List<String> recentTransactions;

  const ProCyclistLifestyleState({
    this.activeCity = CyclistResidenceCity.girona,
    this.ownedUpgrades = const {},
    this.hiredStaff = const {},
    this.activeSponsorsBySlot = const {},
    this.investments = const [],
    this.lastMonthlyTaxPaidEur = 0,
    this.lastMonthlyInvestmentYieldEur = 0,
    this.recentTransactions = const [],
  });

  ProCyclistLifestyleState copyWith({
    CyclistResidenceCity? activeCity,
    Set<LifestyleUpgradeId>? ownedUpgrades,
    Set<PersonalSupportStaffRole>? hiredStaff,
    Map<PersonalSponsorSlotCategory, ProCyclistPersonalSponsor>?
        activeSponsorsBySlot,
    List<WealthInvestmentHolding>? investments,
    int? lastMonthlyTaxPaidEur,
    int? lastMonthlyInvestmentYieldEur,
    List<String>? recentTransactions,
  }) {
    return ProCyclistLifestyleState(
      activeCity: activeCity ?? this.activeCity,
      ownedUpgrades: ownedUpgrades ?? this.ownedUpgrades,
      hiredStaff: hiredStaff ?? this.hiredStaff,
      activeSponsorsBySlot: activeSponsorsBySlot ?? this.activeSponsorsBySlot,
      investments: investments ?? this.investments,
      lastMonthlyTaxPaidEur:
          lastMonthlyTaxPaidEur ?? this.lastMonthlyTaxPaidEur,
      lastMonthlyInvestmentYieldEur:
          lastMonthlyInvestmentYieldEur ?? this.lastMonthlyInvestmentYieldEur,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeCity': activeCity.toJson(),
      'ownedUpgrades': ownedUpgrades.map((e) => e.toJson()).toList(),
      'hiredStaff': hiredStaff.map((e) => e.toJson()).toList(),
      'activeSponsorsBySlot': activeSponsorsBySlot.map(
        (key, value) => MapEntry(key.toJson(), value.toJson()),
      ),
      'investments': investments.map((e) => e.toJson()).toList(),
      'lastMonthlyTaxPaidEur': lastMonthlyTaxPaidEur,
      'lastMonthlyInvestmentYieldEur': lastMonthlyInvestmentYieldEur,
      'recentTransactions': recentTransactions,
    };
  }

  factory ProCyclistLifestyleState.fromJson(Map<String, dynamic> json) {
    final upgradesRaw = json['ownedUpgrades'] as List<dynamic>? ?? const [];
    final staffRaw = json['hiredStaff'] as List<dynamic>? ?? const [];
    final sponsorsRaw =
        json['activeSponsorsBySlot'] as Map<String, dynamic>? ?? const {};
    final investmentsRaw = json['investments'] as List<dynamic>? ?? const [];
    final logsRaw = json['recentTransactions'] as List<dynamic>? ?? const [];

    return ProCyclistLifestyleState(
      activeCity: CyclistResidenceCity.fromJson(
        json['activeCity'] as String? ?? 'girona',
      ),
      ownedUpgrades: upgradesRaw
          .map((e) => LifestyleUpgradeId.fromJson(e as String))
          .toSet(),
      hiredStaff: staffRaw
          .map((e) => PersonalSupportStaffRole.fromJson(e as String))
          .toSet(),
      activeSponsorsBySlot: sponsorsRaw.map(
        (key, value) => MapEntry(
          PersonalSponsorSlotCategory.fromJson(key),
          ProCyclistPersonalSponsor.fromJson(value as Map<String, dynamic>),
        ),
      ),
      investments: investmentsRaw
          .map(
            (e) => WealthInvestmentHolding.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      lastMonthlyTaxPaidEur:
          (json['lastMonthlyTaxPaidEur'] as num?)?.toInt() ?? 0,
      lastMonthlyInvestmentYieldEur:
          (json['lastMonthlyInvestmentYieldEur'] as num?)?.toInt() ?? 0,
      recentTransactions: logsRaw.map((e) => e as String).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProCyclistLifestyleState &&
        other.activeCity == activeCity &&
        other.ownedUpgrades.length == ownedUpgrades.length &&
        other.hiredStaff.length == hiredStaff.length &&
        other.activeSponsorsBySlot.length == activeSponsorsBySlot.length &&
        other.investments.length == investments.length;
  }

  @override
  int get hashCode => Object.hash(
        activeCity,
        ownedUpgrades.length,
        hiredStaff.length,
        activeSponsorsBySlot.length,
        investments.length,
      );
}

/// Wynik operacji finansowej lub zmiany stylu życia kolarza.
class LifestyleTransactionResult {
  final bool success;
  final String message;
  final ProCyclistCareerState careerState;
  final ProCyclistLifestyleState lifestyleState;

  const LifestyleTransactionResult({
    required this.success,
    required this.message,
    required this.careerState,
    required this.lifestyleState,
  });
}

/// Główny serwis zarządzania życiem prywatnym, rezydencją, sztabem, sponsorami i inwestycjami kolarza.
class ProCyclistLifestyleAndWealthService {
  ProCyclistLifestyleAndWealthService._();

  static const double baseIncomeTaxRatePercent = 38.0;

  static const List<ResidenceOfferSpec> residenceCatalog = [
    ResidenceOfferSpec(
      id: 'res_girona_barri_vell',
      city: CyclistResidenceCity.girona,
      title: 'Apartament Barri Vell, Girona',
      country: 'Hiszpania',
      altitudeMeters: 70,
      purchasePriceEur: 420000,
      monthlyRentEur: 1850,
      monthlyUpkeepEur: 420,
      enduranceTrainingBonusPercent: 10.0,
      recoveryBonusPercent: 4.0,
      fameGainMultiplier: 1.08,
      taxReductionPercent: 0.0,
      propertyCategory: ProCyclistPropertyCategory.apartment,
      summary:
          'Mekka światowego peletonu. Idealny klimat cały rok, podjazdy Rocacorba i +10% do treningu wytrzymałościowego.',
      accentColor: AppColors.statusSuccess,
    ),
    ResidenceOfferSpec(
      id: 'res_andorra_ordino',
      city: CyclistResidenceCity.andorra,
      title: 'Chalet Ordino-Arcalís, Andora',
      country: 'Andora',
      altitudeMeters: 2000,
      purchasePriceEur: 780000,
      monthlyRentEur: 3100,
      monthlyUpkeepEur: 680,
      enduranceTrainingBonusPercent: 4.0,
      altitudeHematocritBonusPercent: 4.5,
      recoveryBonusPercent: 2.0,
      fameGainMultiplier: 1.05,
      taxReductionPercent: 26.0,
      propertyCategory: ProCyclistPropertyCategory.mountainChalet,
      summary:
          '2000 m n.p.m. — stała adaptacja wysokogórska hematokrytu (+4.5%) oraz korzystny reżim podatkowy Pirenejów.',
      accentColor: AppColors.accentBlue,
    ),
    ResidenceOfferSpec(
      id: 'res_livigno_alps',
      city: CyclistResidenceCity.livigno,
      title: 'Baza Treningowa Mottolino, Livigno',
      country: 'Włochy',
      altitudeMeters: 2000,
      purchasePriceEur: 640000,
      monthlyRentEur: 2500,
      monthlyUpkeepEur: 550,
      enduranceTrainingBonusPercent: 5.0,
      altitudeHematocritBonusPercent: 4.5,
      recoveryBonusPercent: 3.0,
      fameGainMultiplier: 1.02,
      taxReductionPercent: 12.0,
      propertyCategory: ProCyclistPropertyCategory.mountainChalet,
      summary:
          'Alpejska stolica wysokościowa 2000 m n.p.m. — stała stymulacja hematokrytu i dostęp do Stelvio oraz Gavia.',
      accentColor: AppColors.cyanAccent,
    ),
    ResidenceOfferSpec(
      id: 'res_monaco_fontvieille',
      city: CyclistResidenceCity.monaco,
      title: 'Penthouse Fontvieille, Monako',
      country: 'Monako',
      altitudeMeters: 45,
      purchasePriceEur: 1850000,
      monthlyRentEur: 6800,
      monthlyUpkeepEur: 1450,
      enduranceTrainingBonusPercent: 6.0,
      recoveryBonusPercent: 5.0,
      fameGainMultiplier: 1.25,
      taxReductionPercent: 35.0,
      propertyCategory: ProCyclistPropertyCategory.taxHavenPenthouse,
      summary:
          'Prestiż medialny (+25% sławy), rówieśnicy z czołówki WorldTour oraz najniższe podatki (-35 pp od pensji).',
      accentColor: AppColors.goldAccent,
    ),
    ResidenceOfferSpec(
      id: 'res_flanders_oudenaarde',
      city: CyclistResidenceCity.flanders,
      title: 'Dworek Koppenberg, Flandria',
      country: 'Belgia',
      altitudeMeters: 30,
      purchasePriceEur: 490000,
      monthlyRentEur: 1950,
      monthlyUpkeepEur: 490,
      enduranceTrainingBonusPercent: 5.0,
      cobbleAndWindTrainingBonusPercent: 15.0,
      recoveryBonusPercent: 2.0,
      fameGainMultiplier: 1.10,
      taxReductionPercent: 0.0,
      propertyCategory: ProCyclistPropertyCategory.trainingBase,
      summary:
          'Codzienny trening na brukach Oude Kwaremont i wietrze bocznym Morza Północnego (+15% bruku i wiatru).',
      accentColor: AppColors.amberWarning,
    ),
    ResidenceOfferSpec(
      id: 'res_sierra_nevada',
      city: CyclistResidenceCity.sierraNevada,
      title: 'Apartament CAR 2320 m, Sierra Nevada',
      country: 'Hiszpania',
      altitudeMeters: 2320,
      purchasePriceEur: 560000,
      monthlyRentEur: 2200,
      monthlyUpkeepEur: 480,
      enduranceTrainingBonusPercent: 3.0,
      altitudeHematocritBonusPercent: 5.0,
      recoveryBonusPercent: 2.5,
      fameGainMultiplier: 1.0,
      taxReductionPercent: 0.0,
      propertyCategory: ProCyclistPropertyCategory.mountainChalet,
      summary:
          'Najwyżej położona całoroczna baza w Europie (2320 m n.p.m.) dająca maksymalną adaptację wysokogórską.',
      accentColor: AppColors.primaryAccent,
    ),
  ];

  static const List<LifestyleUpgradeSpec> upgradeCatalog = [
    LifestyleUpgradeSpec(
      id: LifestyleUpgradeId.hypoxicTent,
      name: 'Prywatny Namiot Hipoksyjny Pro',
      subtitle:
          'Symulacja snu na 2800 m n.p.m. — +3.5% adaptacji hematokrytu nawet w Gironie lub Flandrii.',
      purchasePriceEur: 9500,
      monthlyMaintenanceEur: 180,
      hematocritAdaptationBonusPercent: 3.5,
      recoveryBonusPercent: 1.0,
      equipmentCategory: ProCyclistEquipmentCategory.recoveryTech,
      accentColor: AppColors.accentBlue,
    ),
    LifestyleUpgradeSpec(
      id: LifestyleUpgradeId.hyperbaricChamber,
      name: 'Domowa Komora Normobaryczna',
      subtitle:
          'Przyspiesza nocną odbudowę tkanek i usuwanie stanu zapalnego po wyścigach (+6.0% regeneracji).',
      purchasePriceEur: 28000,
      monthlyMaintenanceEur: 340,
      recoveryBonusPercent: 6.0,
      overtrainingRiskReductionPercent: 10.0,
      equipmentCategory: ProCyclistEquipmentCategory.recoveryTech,
      accentColor: AppColors.cyanAccent,
    ),
    LifestyleUpgradeSpec(
      id: LifestyleUpgradeId.smartCryoRecovery,
      name: 'System Kriosauny i Kompresji Smart',
      subtitle:
          'Codzienna terapia zimnem i drenaż limfatyczny nóg (+4.5% regeneracji, -15% ryzyka przetrenowania).',
      purchasePriceEur: 14500,
      monthlyMaintenanceEur: 210,
      recoveryBonusPercent: 4.5,
      overtrainingRiskReductionPercent: 15.0,
      equipmentCategory: ProCyclistEquipmentCategory.recoveryTech,
      accentColor: AppColors.statusSuccess,
    ),
    LifestyleUpgradeSpec(
      id: LifestyleUpgradeId.personalWattbikeLab,
      name: 'Domowe Lab & Analizator Mleczanu',
      subtitle:
          'Precyzyjne testy LT1/LT2 co tydzień i trenażer Smart (+8.0% efektywności treningu progowego).',
      purchasePriceEur: 12000,
      monthlyMaintenanceEur: 150,
      thresholdTrainingBonusPercent: 8.0,
      equipmentCategory: ProCyclistEquipmentCategory.labDiagnostics,
      accentColor: AppColors.goldAccent,
    ),
  ];

  static const List<PersonalSupportStaffSpec> staffCatalog = [
    PersonalSupportStaffSpec(
      role: PersonalSupportStaffRole.personalDietitian,
      title: 'Osobisty Dietetyk Sportowy',
      specialtySummary:
          'Indywidualne protokoły 120 g węglowodanów/h, periodyzacja glikogenu (+10%) i optymalna waga startowa.',
      monthlySalaryEur: 2400,
      signingFeeEur: 1500,
      recoveryBonusPercent: 5.0,
      glycogenEfficiencyBonusPercent: 10.0,
      accentColor: AppColors.statusSuccess,
    ),
    PersonalSupportStaffSpec(
      role: PersonalSupportStaffRole.personalOsteopath,
      title: 'Osobisty Osteopata i Fizjoterapeuta',
      specialtySummary:
          'Cotygodniowa terapia powięziowa i korekcja symetrii na rowerze (+8% regeneracji, -30% ryzyka kontuzji).',
      monthlySalaryEur: 2800,
      signingFeeEur: 1800,
      recoveryBonusPercent: 8.0,
      injuryRiskReductionPercent: 30.0,
      accentColor: AppColors.accentBlue,
    ),
    PersonalSupportStaffSpec(
      role: PersonalSupportStaffRole.personalMentalCoach,
      title: 'Trener Mentalny i Strateg',
      specialtySummary:
          'Praca nad opanowaniem w finałach Monumentów i odpornością na presję mediów (+12% odporności mentalnej).',
      monthlySalaryEur: 1900,
      signingFeeEur: 1000,
      mentalResilienceBonusPercent: 12.0,
      accentColor: AppColors.goldAccent,
    ),
    PersonalSupportStaffSpec(
      role: PersonalSupportStaffRole.personalChef,
      title: 'Prywatny Kucharz Kolarski',
      specialtySummary:
          'Świeże posiłki o dokładnym makro i zerowy stres logistyczny w bazie domowej (+4% regeneracji).',
      monthlySalaryEur: 3200,
      signingFeeEur: 1200,
      recoveryBonusPercent: 4.0,
      glycogenEfficiencyBonusPercent: 4.0,
      accentColor: AppColors.amberWarning,
    ),
  ];

  static const List<PersonalSponsorOfferSpec> personalSponsorCatalog = [
    // Slot: Buty kolarskie
    PersonalSponsorOfferSpec(
      sponsorId: 'shoe_velo_carbon',
      brandName: 'VeloCorsa Carbon',
      slotCategory: PersonalSponsorSlotCategory.shoes,
      monthlyRetainerEur: 900,
      winBonusEur: 2500,
      minFameRequired: 5.0,
      minTierRequired: ProCyclistCareerTier.continentalPro,
      contractYears: 2,
      monthlyFameBoost: 0.25,
      description:
          'Włoskie buty szosowe z podeszwą 12K — pierwszy indywidualny kontrakt obuwniczy.',
    ),
    PersonalSponsorOfferSpec(
      sponsorId: 'shoe_apex_aero',
      brandName: 'Apex Aero Pro',
      slotCategory: PersonalSponsorSlotCategory.shoes,
      monthlyRetainerEur: 2800,
      winBonusEur: 7500,
      minFameRequired: 35.0,
      minTierRequired: ProCyclistCareerTier.worldTourDomestique,
      contractYears: 2,
      monthlyFameBoost: 0.55,
      description:
          'Ultralight 185 g w stylu WorldTour — wysoka premia za wygrane etapy i klasyki.',
    ),
    PersonalSponsorOfferSpec(
      sponsorId: 'shoe_kronos_bespoke',
      brandName: 'Kronos Bespoke Atelier',
      slotCategory: PersonalSponsorSlotCategory.shoes,
      monthlyRetainerEur: 6200,
      winBonusEur: 18000,
      minFameRequired: 68.0,
      minTierRequired: ProCyclistCareerTier.worldTourLeader,
      contractYears: 3,
      monthlyFameBoost: 0.90,
      description:
          'Odlewy 3D stopy na miarę dla liderów Grand Tourów i gwiazd peletonu.',
    ),
    // Slot: Okulary
    PersonalSponsorOfferSpec(
      sponsorId: 'eye_solaris_optic',
      brandName: 'Solaris Optic',
      slotCategory: PersonalSponsorSlotCategory.eyewear,
      monthlyRetainerEur: 750,
      winBonusEur: 2000,
      minFameRequired: 4.0,
      minTierRequired: ProCyclistCareerTier.u23Continental,
      contractYears: 1,
      monthlyFameBoost: 0.20,
      description:
          'Panoramiczne soczewki fotochromowe dostępne już od dywizji U23.',
    ),
    PersonalSponsorOfferSpec(
      sponsorId: 'eye_alpine_prism',
      brandName: 'Alpine Prism Lab',
      slotCategory: PersonalSponsorSlotCategory.eyewear,
      monthlyRetainerEur: 2400,
      winBonusEur: 6500,
      minFameRequired: 30.0,
      minTierRequired: ProCyclistCareerTier.proTeam,
      contractYears: 2,
      monthlyFameBoost: 0.50,
      description:
          'Kontrakt na okulary wyścigowe widoczne na każdym zbliżeniu kamery TV.',
    ),
    PersonalSponsorOfferSpec(
      sponsorId: 'eye_aurelia_signature',
      brandName: 'Aurelia Signature Line',
      slotCategory: PersonalSponsorSlotCategory.eyewear,
      monthlyRetainerEur: 5500,
      winBonusEur: 15000,
      minFameRequired: 62.0,
      minTierRequired: ProCyclistCareerTier.worldTourCoLeader,
      contractYears: 3,
      monthlyFameBoost: 0.85,
      description:
          'Limitowana linia sygnowana nazwiskiem kolarza ze złotymi oprawkami.',
    ),
    // Slot: Zegarek / Wearable
    PersonalSponsorOfferSpec(
      sponsorId: 'watch_pulse_biometrics',
      brandName: 'Pulse Biometrics Band',
      slotCategory: PersonalSponsorSlotCategory.watch,
      monthlyRetainerEur: 1100,
      winBonusEur: 3000,
      minFameRequired: 12.0,
      minTierRequired: ProCyclistCareerTier.continentalPro,
      contractYears: 2,
      monthlyFameBoost: 0.30,
      description:
          'Opaska regeneracyjna i telemetryczna noszona 24/7 na wywiadach i podium.',
    ),
    PersonalSponsorOfferSpec(
      sponsorId: 'watch_helvetia_chrono',
      brandName: 'Helvetia Chronomètre',
      slotCategory: PersonalSponsorSlotCategory.watch,
      monthlyRetainerEur: 4200,
      winBonusEur: 12000,
      minFameRequired: 45.0,
      minTierRequired: ProCyclistCareerTier.worldTourCoLeader,
      contractYears: 2,
      monthlyFameBoost: 0.75,
      description:
          'Szwajcarski chronograf mechaniczny prezentowany podczas dekoracji na podium.',
    ),
    PersonalSponsorOfferSpec(
      sponsorId: 'watch_geneve_tourbillon',
      brandName: 'Genève Tourbillon Prestige',
      slotCategory: PersonalSponsorSlotCategory.watch,
      monthlyRetainerEur: 9500,
      winBonusEur: 28000,
      minFameRequired: 78.0,
      minTierRequired: ProCyclistCareerTier.worldTourLeader,
      contractYears: 3,
      monthlyFameBoost: 1.20,
      description:
          'Najwyższa półka luksusowego zegarmistrzostwa dla ikon światowego kolarstwa.',
    ),
  ];

  static const List<WealthInvestmentSpec> investmentCatalog = [
    WealthInvestmentSpec(
      type: WealthInvestmentType.sovereignBonds,
      name: 'Obligacje Skarbowe EUR',
      riskLabel: 'Niskie ryzyko',
      minInvestmentEur: 5000,
      annualYieldPercent: 3.6,
      description:
          'Bezpieczna lokata kapitału chroniąca oszczędności przed inflacją.',
      accentColor: AppColors.accentBlue,
    ),
    WealthInvestmentSpec(
      type: WealthInvestmentType.globalEtfIndex,
      name: 'Globalny Indeks ETF Akcji',
      riskLabel: 'Umiarkowane ryzyko',
      minInvestmentEur: 10000,
      annualYieldPercent: 6.4,
      description:
          'Szeroki portfel globalnych spółek budujący majątek na życie po karierze.',
      accentColor: AppColors.statusSuccess,
    ),
    WealthInvestmentSpec(
      type: WealthInvestmentType.gironaRentalApartment,
      name: 'Nieruchomość Inwestycyjna (Girona)',
      riskLabel: 'Stabilny dochód pasywny',
      minInvestmentEur: 120000,
      annualYieldPercent: 7.5,
      description:
          'Apartament wynajmowany innym kolarzom WorldTour w trakcie sezonu.',
      accentColor: AppColors.goldAccent,
    ),
    WealthInvestmentSpec(
      type: WealthInvestmentType.pelotonCoffeeRoastery,
      name: 'Sieć Kawiarni Peloton Coffee Lab',
      riskLabel: 'Wzrost & Marka osobista',
      minInvestmentEur: 45000,
      annualYieldPercent: 9.2,
      monthlyFameBonus: 0.35,
      description:
          'Kolarskie espresso bary w Europie generujące zysk i dodatkową rozpoznawalność.',
      accentColor: AppColors.amberWarning,
    ),
  ];

  static ResidenceOfferSpec getResidenceSpec(CyclistResidenceCity city) {
    return residenceCatalog.firstWhere(
      (spec) => spec.city == city,
      orElse: () => residenceCatalog.first,
    );
  }

  static LifestyleUpgradeSpec getUpgradeSpec(LifestyleUpgradeId id) {
    return upgradeCatalog.firstWhere(
      (spec) => spec.id == id,
      orElse: () => upgradeCatalog.first,
    );
  }

  static PersonalSupportStaffSpec getStaffSpec(PersonalSupportStaffRole role) {
    return staffCatalog.firstWhere(
      (spec) => spec.role == role,
      orElse: () => staffCatalog.first,
    );
  }

  static WealthInvestmentSpec getInvestmentSpec(WealthInvestmentType type) {
    return investmentCatalog.firstWhere(
      (spec) => spec.type == type,
      orElse: () => investmentCatalog.first,
    );
  }

  static bool isResidenceOwned(
    ProCyclistCareerState career,
    CyclistResidenceCity city,
  ) {
    final spec = getResidenceSpec(city);
    return career.ownedProperties.any((prop) => prop.id == spec.id);
  }

  static List<String> _prependLog(List<String> existing, String entry) {
    return [entry, ...existing].take(20).toList();
  }

  /// Zmienia aktywne miejsce zamieszkania na wynajem lub kupuje nieruchomość na własność.
  static LifestyleTransactionResult selectOrBuyResidence({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
    required CyclistResidenceCity city,
    required bool buyProperty,
  }) {
    final spec = getResidenceSpec(city);
    final alreadyOwned = isResidenceOwned(careerState, city);

    if (!buyProperty) {
      if (lifestyleState.activeCity == city) {
        return LifestyleTransactionResult(
          success: false,
          message: 'Już mieszkasz w ${spec.city.displayName}.',
          careerState: careerState,
          lifestyleState: lifestyleState,
        );
      }

      if (!alreadyOwned && careerState.privateBalanceEur < spec.monthlyRentEur) {
        return LifestyleTransactionResult(
          success: false,
          message:
              'Za mało środków na pierwszy czynsz (${Formatters.formatCurrency(spec.monthlyRentEur)}).',
          careerState: careerState,
          lifestyleState: lifestyleState,
        );
      }

      final upfrontCost = alreadyOwned ? 0 : spec.monthlyRentEur;
      final updatedProperties = careerState.ownedProperties
          .map(
            (p) => p.copyWith(isPrimaryResidence: p.id == spec.id),
          )
          .toList();

      final updatedCareer = careerState.copyWith(
        privateBalanceEur: careerState.privateBalanceEur - upfrontCost,
        ownedProperties: updatedProperties,
      );
      final updatedLifestyle = lifestyleState.copyWith(
        activeCity: city,
        recentTransactions: _prependLog(
          lifestyleState.recentTransactions,
          alreadyOwned
              ? 'Przeprowadzka do własnej nieruchomości: ${spec.city.displayName}'
              : 'Wynajem rezydencji w ${spec.city.displayName} (-${Formatters.formatCurrency(upfrontCost)})',
        ),
      );

      return LifestyleTransactionResult(
        success: true,
        message: alreadyOwned
            ? 'Przeniesiono bazę domową do własnej nieruchomości w ${spec.city.displayName}.'
            : 'Wynajęto rezydencję w ${spec.city.displayName}.',
        careerState: updatedCareer,
        lifestyleState: updatedLifestyle,
      );
    }

    if (alreadyOwned) {
      final updatedProperties = careerState.ownedProperties
          .map((p) => p.copyWith(isPrimaryResidence: p.id == spec.id))
          .toList();
      return LifestyleTransactionResult(
        success: true,
        message:
            'Posiadasz już nieruchomość w ${spec.city.displayName} — ustawiono jako główną bazę.',
        careerState: careerState.copyWith(ownedProperties: updatedProperties),
        lifestyleState: lifestyleState.copyWith(activeCity: city),
      );
    }

    if (careerState.privateBalanceEur < spec.purchasePriceEur) {
      return LifestyleTransactionResult(
        success: false,
        message:
            'Niewystarczające środki na zakup (${Formatters.formatCurrency(spec.purchasePriceEur)}).',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final updatedProperties = [
      ...careerState.ownedProperties
          .map((p) => p.copyWith(isPrimaryResidence: false)),
      spec.toRealEstate(careerState.currentDate),
    ];

    final updatedCareer = careerState.copyWith(
      privateBalanceEur: careerState.privateBalanceEur - spec.purchasePriceEur,
      ownedProperties: updatedProperties,
    );
    final updatedLifestyle = lifestyleState.copyWith(
      activeCity: city,
      recentTransactions: _prependLog(
        lifestyleState.recentTransactions,
        'Zakup nieruchomości: ${spec.title} (-${Formatters.formatCurrency(spec.purchasePriceEur)})',
      ),
    );

    return LifestyleTransactionResult(
      success: true,
      message: 'Kupiono ${spec.title} i ustawiono jako główną rezydencję.',
      careerState: updatedCareer,
      lifestyleState: updatedLifestyle,
    );
  }

  /// Zakup prywatnego sprzętu treningowego/regeneracyjnego (np. namiotu hipoksyjnego).
  static LifestyleTransactionResult purchaseUpgrade({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
    required LifestyleUpgradeId upgradeId,
  }) {
    if (lifestyleState.ownedUpgrades.contains(upgradeId)) {
      return LifestyleTransactionResult(
        success: false,
        message: 'Ten element wyposażenia jest już w Twojej bazie.',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final spec = getUpgradeSpec(upgradeId);
    if (careerState.privateBalanceEur < spec.purchasePriceEur) {
      return LifestyleTransactionResult(
        success: false,
        message:
            'Brak środków na zakup ${spec.name} (${Formatters.formatCurrency(spec.purchasePriceEur)}).',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final equipment = spec.toPrivateEquipment(careerState.currentDate);
    final updatedCareer = careerState.copyWith(
      privateBalanceEur: careerState.privateBalanceEur - spec.purchasePriceEur,
      ownedPrivateEquipment: [...careerState.ownedPrivateEquipment, equipment],
    );

    final updatedLifestyle = lifestyleState.copyWith(
      ownedUpgrades: {...lifestyleState.ownedUpgrades, upgradeId},
      recentTransactions: _prependLog(
        lifestyleState.recentTransactions,
        'Zakup sprzętu: ${spec.name} (-${Formatters.formatCurrency(spec.purchasePriceEur)})',
      ),
    );

    return LifestyleTransactionResult(
      success: true,
      message: 'Zainstalowano ${spec.name} w prywatnej bazie.',
      careerState: updatedCareer,
      lifestyleState: updatedLifestyle,
    );
  }

  /// Zatrudnienie lub zwolnienie osobistego specjalisty (np. dietetyka, osteopaty).
  static LifestyleTransactionResult togglePersonalStaff({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
    required PersonalSupportStaffRole role,
  }) {
    final spec = getStaffSpec(role);
    final isHired = lifestyleState.hiredStaff.contains(role);

    if (isHired) {
      final updatedStaff = Set<PersonalSupportStaffRole>.from(
        lifestyleState.hiredStaff,
      )..remove(role);
      return LifestyleTransactionResult(
        success: true,
        message: 'Zakończono współpracę: ${spec.title}.',
        careerState: careerState,
        lifestyleState: lifestyleState.copyWith(
          hiredStaff: updatedStaff,
          recentTransactions: _prependLog(
            lifestyleState.recentTransactions,
            'Rozwiązano umowę: ${spec.title}',
          ),
        ),
      );
    }

    if (careerState.privateBalanceEur < spec.signingFeeEur) {
      return LifestyleTransactionResult(
        success: false,
        message:
            'Brak środków na opłatę startową (${Formatters.formatCurrency(spec.signingFeeEur)}).',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final updatedCareer = careerState.copyWith(
      privateBalanceEur: careerState.privateBalanceEur - spec.signingFeeEur,
    );
    final updatedLifestyle = lifestyleState.copyWith(
      hiredStaff: {...lifestyleState.hiredStaff, role},
      recentTransactions: _prependLog(
        lifestyleState.recentTransactions,
        'Zatrudniono: ${spec.title} (-${Formatters.formatCurrency(spec.signingFeeEur)})',
      ),
    );

    return LifestyleTransactionResult(
      success: true,
      message: 'Zatrudniono: ${spec.title}.',
      careerState: updatedCareer,
      lifestyleState: updatedLifestyle,
    );
  }

  /// Podpisanie indywidualnego kontraktu reklamowego w dedykowanym slocie (buty, okulary, zegarek).
  static LifestyleTransactionResult signPersonalSponsor({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
    required String sponsorId,
  }) {
    final offer = personalSponsorCatalog.firstWhere(
      (o) => o.sponsorId == sponsorId,
      orElse: () => throw ArgumentError('Nieznany sponsor: $sponsorId'),
    );

    if (careerState.fameScore < offer.minFameRequired) {
      return LifestyleTransactionResult(
        success: false,
        message:
            'Wymagana rozpoznawalność: ${offer.minFameRequired.toStringAsFixed(0)} pkt (aktualnie ${careerState.fameScore.toStringAsFixed(1)}).',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    if (careerState.careerTier.rankIndex < offer.minTierRequired.rankIndex) {
      return LifestyleTransactionResult(
        success: false,
        message:
            'Wymagana ranga kariery: ${offer.minTierRequired.label}.',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final existingInSlot =
        lifestyleState.activeSponsorsBySlot[offer.slotCategory];
    if (existingInSlot?.sponsorId == offer.sponsorId) {
      return LifestyleTransactionResult(
        success: false,
        message: 'Ten kontrakt reklamowy jest już aktywny.',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final newSponsor = offer.toPersonalSponsor(careerState.seasonYear);
    final updatedMap =
        Map<PersonalSponsorSlotCategory, ProCyclistPersonalSponsor>.from(
      lifestyleState.activeSponsorsBySlot,
    )..[offer.slotCategory] = newSponsor;

    final updatedSponsorsList = updatedMap.values.toList();
    final updatedCareer = careerState.copyWith(
      activePersonalSponsors: updatedSponsorsList,
    );

    final updatedLifestyle = lifestyleState.copyWith(
      activeSponsorsBySlot: updatedMap,
      recentTransactions: _prependLog(
        lifestyleState.recentTransactions,
        'Kontrakt [${offer.slotCategory.label}]: ${offer.brandName} (+${Formatters.formatCurrency(offer.monthlyRetainerEur)}/mies.)',
      ),
    );

    return LifestyleTransactionResult(
      success: true,
      message:
          'Podpisano kontrakt z ${offer.brandName} (${offer.slotCategory.label}).',
      careerState: updatedCareer,
      lifestyleState: updatedLifestyle,
    );
  }

  /// Inwestycja zarobionej gotówki w wybrany instrument finansowy.
  static LifestyleTransactionResult investSavings({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
    required WealthInvestmentType type,
    required int amountEur,
  }) {
    final spec = getInvestmentSpec(type);
    if (amountEur <= 0) {
      return LifestyleTransactionResult(
        success: false,
        message: 'Kwota inwestycji musi być dodatnia.',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final existingIdx =
        lifestyleState.investments.indexWhere((inv) => inv.type == type);
    if (existingIdx == -1 && amountEur < spec.minInvestmentEur) {
      return LifestyleTransactionResult(
        success: false,
        message:
            'Minimalna pierwsza wpłata to ${Formatters.formatCurrency(spec.minInvestmentEur)}.',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    if (careerState.privateBalanceEur < amountEur) {
      return LifestyleTransactionResult(
        success: false,
        message: 'Niewystarczające środki na koncie prywatnym.',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final updatedInvestments = List<WealthInvestmentHolding>.from(
      lifestyleState.investments,
    );
    if (existingIdx >= 0) {
      final current = updatedInvestments[existingIdx];
      updatedInvestments[existingIdx] = current.copyWith(
        investedPrincipalEur: current.investedPrincipalEur + amountEur,
      );
    } else {
      updatedInvestments.add(
        WealthInvestmentHolding(
          type: type,
          investedPrincipalEur: amountEur,
          openedDate: careerState.currentDate,
        ),
      );
    }

    final updatedCareer = careerState.copyWith(
      privateBalanceEur: careerState.privateBalanceEur - amountEur,
    );
    final updatedLifestyle = lifestyleState.copyWith(
      investments: updatedInvestments,
      recentTransactions: _prependLog(
        lifestyleState.recentTransactions,
        'Inwestycja ${spec.name}: ${Formatters.formatCurrency(amountEur)}',
      ),
    );

    return LifestyleTransactionResult(
      success: true,
      message:
          'Zainwestowano ${Formatters.formatCurrency(amountEur)} w ${spec.name}.',
      careerState: updatedCareer,
      lifestyleState: updatedLifestyle,
    );
  }

  /// Wypłata całości lub części środków z wybranego instrumentu inwestycyjnego.
  static LifestyleTransactionResult liquidateInvestment({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
    required WealthInvestmentType type,
  }) {
    final idx = lifestyleState.investments.indexWhere((e) => e.type == type);
    if (idx == -1) {
      return LifestyleTransactionResult(
        success: false,
        message: 'Brak aktywnej pozycji w tym instrumencie.',
        careerState: careerState,
        lifestyleState: lifestyleState,
      );
    }

    final holding = lifestyleState.investments[idx];
    final payoutEur = holding.totalValueEur;
    final spec = getInvestmentSpec(type);
    final updatedInvestments = List<WealthInvestmentHolding>.from(
      lifestyleState.investments,
    )..removeAt(idx);

    final updatedCareer = careerState.copyWith(
      privateBalanceEur: careerState.privateBalanceEur + payoutEur,
    );
    final updatedLifestyle = lifestyleState.copyWith(
      investments: updatedInvestments,
      recentTransactions: _prependLog(
        lifestyleState.recentTransactions,
        'Wypłata z ${spec.name}: +${Formatters.formatCurrency(payoutEur)}',
      ),
    );

    return LifestyleTransactionResult(
      success: true,
      message:
          'Wypłacono ${Formatters.formatCurrency(payoutEur)} na konto prywatne.',
      careerState: updatedCareer,
      lifestyleState: updatedLifestyle,
    );
  }

  /// Miesięczne rozliczenie pensji, podatków, sponsorów, kosztów życia i zysków z inwestycji.
  static LifestyleTransactionResult processMonthlyFinances({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
  }) {
    final summary = computeBonusSummary(
      careerState: careerState,
      lifestyleState: lifestyleState,
    );

    double totalInvestmentFameBoost = 0.0;
    final updatedInvestments = <WealthInvestmentHolding>[];
    int totalYieldEur = 0;

    for (final holding in lifestyleState.investments) {
      final spec = getInvestmentSpec(holding.type);
      final monthlyYield =
          ((holding.totalValueEur * (spec.annualYieldPercent / 100.0)) / 12.0)
              .round();
      totalYieldEur += monthlyYield;
      totalInvestmentFameBoost += spec.monthlyFameBonus;
      updatedInvestments.add(
        holding.copyWith(
          accruedReturnEur: holding.accruedReturnEur + monthlyYield,
        ),
      );
    }

    double sponsorFameBoost = 0.0;
    for (final sponsor in lifestyleState.activeSponsorsBySlot.values) {
      final specMatch = personalSponsorCatalog
          .where((o) => o.sponsorId == sponsor.sponsorId);
      if (specMatch.isNotEmpty) {
        sponsorFameBoost += specMatch.first.monthlyFameBoost;
      }
    }

    final netCashDelta = summary.grossMonthlyIncomeEur -
        summary.estimatedMonthlyTaxEur -
        summary.monthlyLifestyleExpensesEur;

    final updatedBalance = careerState.privateBalanceEur + netCashDelta;
    final newFameScore = (careerState.fameScore +
            (sponsorFameBoost + totalInvestmentFameBoost) *
                summary.fameGainMultiplier)
        .clamp(0.0, 100.0);

    final updatedCareer = careerState.copyWith(
      privateBalanceEur: updatedBalance,
      careerEarningsEur: careerState.careerEarningsEur +
          math.max(0, summary.grossMonthlyIncomeEur - summary.estimatedMonthlyTaxEur),
      fameScore: newFameScore,
    );

    final updatedLifestyle = lifestyleState.copyWith(
      investments: updatedInvestments,
      lastMonthlyTaxPaidEur: summary.estimatedMonthlyTaxEur,
      lastMonthlyInvestmentYieldEur: totalYieldEur,
      recentTransactions: _prependLog(
        lifestyleState.recentTransactions,
        'Rozliczenie miesięczne: ${netCashDelta >= 0 ? '+' : ''}${Formatters.formatCurrency(netCashDelta)} (podatek -${Formatters.formatCurrency(summary.estimatedMonthlyTaxEur)}, zysk inwest. +${Formatters.formatCurrency(totalYieldEur)})',
      ),
    );

    return LifestyleTransactionResult(
      success: true,
      message: 'Zamknięto miesiąc rozliczeniowy.',
      careerState: updatedCareer,
      lifestyleState: updatedLifestyle,
    );
  }

  /// Wylicza zagregowane premie fizjologiczne, treningowe i finansowe kolarza.
  static LifestyleBonusSummary computeBonusSummary({
    required ProCyclistCareerState careerState,
    required ProCyclistLifestyleState lifestyleState,
  }) {
    final resSpec = getResidenceSpec(lifestyleState.activeCity);
    final ownsActiveCity =
        isResidenceOwned(careerState, lifestyleState.activeCity);

    double upgradeHematocrit = 0.0;
    double upgradeRecovery = 0.0;
    double upgradeThreshold = 0.0;
    int upgradeMaintenanceEur = 0;

    for (final id in lifestyleState.ownedUpgrades) {
      final spec = getUpgradeSpec(id);
      upgradeHematocrit += spec.hematocritAdaptationBonusPercent;
      upgradeRecovery += spec.recoveryBonusPercent;
      upgradeThreshold += spec.thresholdTrainingBonusPercent;
      upgradeMaintenanceEur += spec.monthlyMaintenanceEur;
    }

    double staffRecovery = 0.0;
    double staffGlycogen = 0.0;
    double staffInjuryReduction = 0.0;
    int staffSalariesEur = 0;

    for (final role in lifestyleState.hiredStaff) {
      final spec = getStaffSpec(role);
      staffRecovery += spec.recoveryBonusPercent;
      staffGlycogen += spec.glycogenEfficiencyBonusPercent;
      staffInjuryReduction += spec.injuryRiskReductionPercent;
      staffSalariesEur += spec.monthlySalaryEur;
    }

    // Namiot hipoksyjny + baza wysokogórska mają łagodny sufit fizjologiczny (max 7.5%).
    final totalHematocritBonus = math.min(
      7.5,
      resSpec.altitudeHematocritBonusPercent + upgradeHematocrit,
    );

    final effectiveTaxRate = math.max(
      3.0,
      baseIncomeTaxRatePercent - resSpec.taxReductionPercent,
    );

    final sponsorIncomeEur = lifestyleState.activeSponsorsBySlot.values
        .fold<int>(0, (sum, s) => sum + s.monthlyRetainerEur);

    final grossIncomeEur =
        careerState.playerRider.contract.monthlySalaryEur + sponsorIncomeEur;
    final estimatedTaxEur =
        (grossIncomeEur * (effectiveTaxRate / 100.0)).round();

    final housingCostEur =
        ownsActiveCity ? resSpec.monthlyUpkeepEur : resSpec.monthlyRentEur;
    final otherOwnedUpkeepEur = careerState.ownedProperties
        .where((p) => p.id != resSpec.id)
        .fold<int>(0, (sum, p) => sum + p.monthlyUpkeepEur);

    final totalExpensesEur = housingCostEur +
        otherOwnedUpkeepEur +
        upgradeMaintenanceEur +
        staffSalariesEur +
        careerState.monthlyLivingExpensesEur;

    int portfolioValueEur = 0;
    int monthlyInvestmentYieldEur = 0;
    for (final holding in lifestyleState.investments) {
      final spec = getInvestmentSpec(holding.type);
      portfolioValueEur += holding.totalValueEur;
      monthlyInvestmentYieldEur +=
          ((holding.totalValueEur * (spec.annualYieldPercent / 100.0)) / 12.0)
              .round();
    }

    final netCashflowEur =
        grossIncomeEur - estimatedTaxEur - totalExpensesEur;

    final totalNetWorthEur =
        careerState.totalNetWorthEur + portfolioValueEur;

    return LifestyleBonusSummary(
      activeCity: lifestyleState.activeCity,
      isResidenceOwned: ownsActiveCity,
      enduranceTrainingBonusPercent: resSpec.enduranceTrainingBonusPercent,
      altitudeHematocritBonusPercent: totalHematocritBonus,
      cobbleAndWindTrainingBonusPercent:
          resSpec.cobbleAndWindTrainingBonusPercent,
      thresholdTrainingBonusPercent: upgradeThreshold,
      recoveryBonusPercent:
          resSpec.recoveryBonusPercent + upgradeRecovery + staffRecovery,
      glycogenEfficiencyBonusPercent: staffGlycogen,
      injuryRiskReductionPercent: staffInjuryReduction,
      fameGainMultiplier: resSpec.fameGainMultiplier,
      effectiveTaxRatePercent: effectiveTaxRate,
      grossMonthlyIncomeEur: grossIncomeEur,
      estimatedMonthlyTaxEur: estimatedTaxEur,
      monthlyLifestyleExpensesEur: totalExpensesEur,
      estimatedMonthlyInvestmentYieldEur: monthlyInvestmentYieldEur,
      projectedMonthlyNetCashflowEur: netCashflowEur,
      totalInvestmentPortfolioEur: portfolioValueEur,
      totalNetWorthEur: totalNetWorthEur,
    );
  }
}

/// Połączony stan sesji dla Riverpod obsługujący karierę Be a Pro i moduł Lifestyle.
class ProCyclistLifestyleSessionState {
  final ProCyclistCareerState careerState;
  final ProCyclistLifestyleState lifestyleState;
  final String? lastFeedbackMessage;
  final bool lastFeedbackSuccess;

  const ProCyclistLifestyleSessionState({
    required this.careerState,
    required this.lifestyleState,
    this.lastFeedbackMessage,
    this.lastFeedbackSuccess = true,
  });

  LifestyleBonusSummary get bonusSummary =>
      ProCyclistLifestyleAndWealthService.computeBonusSummary(
        careerState: careerState,
        lifestyleState: lifestyleState,
      );

  ProCyclistLifestyleSessionState copyWith({
    ProCyclistCareerState? careerState,
    ProCyclistLifestyleState? lifestyleState,
    String? lastFeedbackMessage,
    bool? lastFeedbackSuccess,
  }) {
    return ProCyclistLifestyleSessionState(
      careerState: careerState ?? this.careerState,
      lifestyleState: lifestyleState ?? this.lifestyleState,
      lastFeedbackMessage: lastFeedbackMessage,
      lastFeedbackSuccess: lastFeedbackSuccess ?? this.lastFeedbackSuccess,
    );
  }
}

/// Kontroler stanu życia prywatnego i majątku kolarza.
class ProCyclistLifestyleNotifier
    extends StateNotifier<ProCyclistLifestyleSessionState> {
  ProCyclistLifestyleNotifier({
    required ProCyclistCareerState initialCareer,
    ProCyclistLifestyleState initialLifestyle =
        const ProCyclistLifestyleState(),
  }) : super(
          ProCyclistLifestyleSessionState(
            careerState: initialCareer,
            lifestyleState: initialLifestyle,
          ),
        );

  void _applyResult(LifestyleTransactionResult result) {
    state = state.copyWith(
      careerState: result.careerState,
      lifestyleState: result.lifestyleState,
      lastFeedbackMessage: result.message,
      lastFeedbackSuccess: result.success,
    );
  }

  void selectOrBuyResidence(
    CyclistResidenceCity city, {
    required bool buyProperty,
  }) {
    _applyResult(
      ProCyclistLifestyleAndWealthService.selectOrBuyResidence(
        careerState: state.careerState,
        lifestyleState: state.lifestyleState,
        city: city,
        buyProperty: buyProperty,
      ),
    );
  }

  void purchaseUpgrade(LifestyleUpgradeId upgradeId) {
    _applyResult(
      ProCyclistLifestyleAndWealthService.purchaseUpgrade(
        careerState: state.careerState,
        lifestyleState: state.lifestyleState,
        upgradeId: upgradeId,
      ),
    );
  }

  void togglePersonalStaff(PersonalSupportStaffRole role) {
    _applyResult(
      ProCyclistLifestyleAndWealthService.togglePersonalStaff(
        careerState: state.careerState,
        lifestyleState: state.lifestyleState,
        role: role,
      ),
    );
  }

  void signPersonalSponsor(String sponsorId) {
    _applyResult(
      ProCyclistLifestyleAndWealthService.signPersonalSponsor(
        careerState: state.careerState,
        lifestyleState: state.lifestyleState,
        sponsorId: sponsorId,
      ),
    );
  }

  void investSavings(WealthInvestmentType type, int amountEur) {
    _applyResult(
      ProCyclistLifestyleAndWealthService.investSavings(
        careerState: state.careerState,
        lifestyleState: state.lifestyleState,
        type: type,
        amountEur: amountEur,
      ),
    );
  }

  void liquidateInvestment(WealthInvestmentType type) {
    _applyResult(
      ProCyclistLifestyleAndWealthService.liquidateInvestment(
        careerState: state.careerState,
        lifestyleState: state.lifestyleState,
        type: type,
      ),
    );
  }

  void processMonthlyFinances() {
    _applyResult(
      ProCyclistLifestyleAndWealthService.processMonthlyFinances(
        careerState: state.careerState,
        lifestyleState: state.lifestyleState,
      ),
    );
  }
}

/// Zakładki głównego panelu życia prywatnego i inwestycji kolarza.
enum LifestyleWealthTab {
  residence('Rezydencja'),
  gearAndStaff('Sprzęt & Sztab'),
  sponsors('Sponsorzy'),
  wealth('Inwestycje');

  const LifestyleWealthTab(this.label);
  final String label;
}

/// Produkcyjny, responsywny panel UI systemu życia prywatnego i inwestowania pensji kolarza.
class ProCyclistLifestyleAndWealthPanel extends StatefulWidget {
  final ProCyclistLifestyleSessionState session;
  final void Function(CyclistResidenceCity city, bool buyProperty)
      onSelectOrBuyResidence;
  final void Function(LifestyleUpgradeId upgradeId) onPurchaseUpgrade;
  final void Function(PersonalSupportStaffRole role) onToggleStaff;
  final void Function(String sponsorId) onSignSponsor;
  final void Function(WealthInvestmentType type, int amountEur) onInvest;
  final void Function(WealthInvestmentType type) onLiquidateInvestment;
  final VoidCallback onProcessMonth;

  const ProCyclistLifestyleAndWealthPanel({
    super.key,
    required this.session,
    required this.onSelectOrBuyResidence,
    required this.onPurchaseUpgrade,
    required this.onToggleStaff,
    required this.onSignSponsor,
    required this.onInvest,
    required this.onLiquidateInvestment,
    required this.onProcessMonth,
  });

  @override
  State<ProCyclistLifestyleAndWealthPanel> createState() =>
      _ProCyclistLifestyleAndWealthPanelState();
}

class _ProCyclistLifestyleAndWealthPanelState
    extends State<ProCyclistLifestyleAndWealthPanel> {
  LifestyleWealthTab _activeTab = LifestyleWealthTab.residence;
  PersonalSponsorSlotCategory _selectedSponsorSlot =
      PersonalSponsorSlotCategory.shoes;

  @override
  Widget build(BuildContext context) {
    final summary = widget.session.bonusSummary;
    final career = widget.session.careerState;
    final lifestyle = widget.session.lifestyleState;

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 680;
          final isDesktopWide = constraints.maxWidth >= 1200;
          final horizontalPadding = isMobile ? 12.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderSummaryCard(
                  career: career,
                  summary: summary,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 12),
                if (widget.session.lastFeedbackMessage != null) ...[
                  _buildFeedbackBanner(
                    message: widget.session.lastFeedbackMessage!,
                    isSuccess: widget.session.lastFeedbackSuccess,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildTabBar(isMobile: isMobile),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: KeyedSubtree(
                    key: ValueKey<LifestyleWealthTab>(_activeTab),
                    child: _buildActiveTabContent(
                      career: career,
                      lifestyle: lifestyle,
                      summary: summary,
                      isMobile: isMobile,
                      isDesktopWide: isDesktopWide,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSummaryCard({
    required ProCyclistCareerState career,
    required LifestyleBonusSummary summary,
    required bool isMobile,
  }) {
    final kpis = [
      _KpiItem(
        label: 'KONTO PRYWATNE',
        value: Formatters.formatCurrency(career.privateBalanceEur),
        color: AppColors.goldAccent,
      ),
      _KpiItem(
        label: 'BILANS / MIES.',
        value:
            '${summary.projectedMonthlyNetCashflowEur >= 0 ? '+' : ''}${Formatters.formatCurrency(summary.projectedMonthlyNetCashflowEur)}',
        color: summary.projectedMonthlyNetCashflowEur >= 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
      ),
      _KpiItem(
        label: 'ADAPTACJA WYS.',
        value: '+${summary.altitudeHematocritBonusPercent.toStringAsFixed(1)}%',
        color: AppColors.accentBlue,
      ),
      _KpiItem(
        label: 'REGENERACJA',
        value: '+${summary.recoveryBonusPercent.toStringAsFixed(1)}%',
        color: AppColors.cyanAccent,
      ),
      _KpiItem(
        label: 'PODATEK EFEKT.',
        value: '${summary.effectiveTaxRatePercent.toStringAsFixed(0)}%',
        color: AppColors.amberWarning,
      ),
      _KpiItem(
        label: 'SŁAWA',
        value: '${career.fameScore.toStringAsFixed(1)} pkt',
        color: AppColors.textPrimary,
      ),
    ];

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
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ŻYCIE PRYWATNE & MAJĄTEK KOLARZA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Baza: ${summary.activeCity.displayName} • Majątek netto ${Formatters.formatCompactCurrency(summary.totalNetWorthEur)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              _InteractiveActionButton(
                label: 'Rozlicz miesiąc',
                icon: Icons.calendar_month_rounded,
                accentColor: AppColors.primaryAccent,
                onPressed: widget.onProcessMonth,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kpis.map((item) {
              return Container(
                width: isMobile ? 156 : 178,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: item.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required String message,
    required bool isSuccess,
  }) {
    final borderColor =
        isSuccess ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: borderColor,
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
        ],
      ),
    );
  }

  Widget _buildTabBar({required bool isMobile}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LifestyleWealthTab.values.map((tab) {
        final isSelected = _activeTab == tab;
        return _InteractiveActionButton(
          label: tab.label,
          accentColor:
              isSelected ? AppColors.goldAccent : AppColors.surfaceLight,
          isSelected: isSelected,
          compact: isMobile,
          onPressed: () {
            setState(() => _activeTab = tab);
          },
        );
      }).toList(),
    );
  }

  Widget _buildActiveTabContent({
    required ProCyclistCareerState career,
    required ProCyclistLifestyleState lifestyle,
    required LifestyleBonusSummary summary,
    required bool isMobile,
    required bool isDesktopWide,
  }) {
    switch (_activeTab) {
      case LifestyleWealthTab.residence:
        return _buildResidenceGrid(
          career: career,
          lifestyle: lifestyle,
          isMobile: isMobile,
          isDesktopWide: isDesktopWide,
        );
      case LifestyleWealthTab.gearAndStaff:
        return _buildGearAndStaffSection(
          career: career,
          lifestyle: lifestyle,
          isMobile: isMobile,
        );
      case LifestyleWealthTab.sponsors:
        return _buildSponsorsSection(
          career: career,
          lifestyle: lifestyle,
          isMobile: isMobile,
        );
      case LifestyleWealthTab.wealth:
        return _buildWealthSection(
          career: career,
          lifestyle: lifestyle,
          summary: summary,
          isMobile: isMobile,
        );
    }
  }

  Widget _buildResidenceGrid({
    required ProCyclistCareerState career,
    required ProCyclistLifestyleState lifestyle,
    required bool isMobile,
    required bool isDesktopWide,
  }) {
    final crossAxisCount = isMobile ? 1 : (isDesktopWide ? 3 : 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              ProCyclistLifestyleAndWealthService.residenceCatalog.map((spec) {
            final isActive = lifestyle.activeCity == spec.city;
            final isOwned =
                ProCyclistLifestyleAndWealthService.isResidenceOwned(
              career,
              spec.city,
            );
            final canAffordRent =
                career.privateBalanceEur >= spec.monthlyRentEur;
            final canAffordBuy =
                career.privateBalanceEur >= spec.purchasePriceEur;

            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? spec.accentColor : AppColors.cardBorder,
                    width: isActive ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spec.city.displayName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label: isActive
                              ? 'AKTYWNA BAZA'
                              : (isOwned
                                  ? 'WŁASNOŚĆ'
                                  : '${spec.altitudeMeters} m n.p.m.'),
                          color: isActive
                              ? spec.accentColor
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${spec.title} • ${spec.altitudeMeters} m n.p.m.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      spec.summary,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (spec.enduranceTrainingBonusPercent > 0)
                          _BonusTag(
                            text:
                                '+${spec.enduranceTrainingBonusPercent.toStringAsFixed(0)}% Wytrzymałość',
                            color: AppColors.statusSuccess,
                          ),
                        if (spec.altitudeHematocritBonusPercent > 0)
                          _BonusTag(
                            text:
                                '+${spec.altitudeHematocritBonusPercent.toStringAsFixed(1)}% Hematokryt',
                            color: AppColors.accentBlue,
                          ),
                        if (spec.cobbleAndWindTrainingBonusPercent > 0)
                          _BonusTag(
                            text:
                                '+${spec.cobbleAndWindTrainingBonusPercent.toStringAsFixed(0)}% Bruk & Wiatr',
                            color: AppColors.amberWarning,
                          ),
                        if (spec.taxReductionPercent > 0)
                          _BonusTag(
                            text:
                                '-${spec.taxReductionPercent.toStringAsFixed(0)} pp Podatek',
                            color: AppColors.goldAccent,
                          ),
                        if (spec.fameGainMultiplier > 1.0)
                          _BonusTag(
                            text:
                                '+${((spec.fameGainMultiplier - 1.0) * 100).round()}% Sława',
                            color: AppColors.cyanAccent,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InteractiveActionButton(
                          label: isOwned
                              ? (isActive ? 'Aktywna' : 'Przenieś tutaj')
                              : 'Wynajmij ${Formatters.formatCurrency(spec.monthlyRentEur)}/m',
                          accentColor: AppColors.surfaceLight,
                          disabled: isActive || (!isOwned && !canAffordRent),
                          compact: true,
                          onPressed: () => widget.onSelectOrBuyResidence(
                            spec.city,
                            false,
                          ),
                        ),
                        if (!isOwned)
                          _InteractiveActionButton(
                            label:
                                'Kup ${Formatters.formatCompactCurrency(spec.purchasePriceEur)}',
                            accentColor: AppColors.goldAccent,
                            disabled: !canAffordBuy,
                            compact: true,
                            onPressed: () => widget.onSelectOrBuyResidence(
                              spec.city,
                              true,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGearAndStaffSection({
    required ProCyclistCareerState career,
    required ProCyclistLifestyleState lifestyle,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRYWATNY SPRZĘT HIPOKSYJNY I REGENERACYJNY',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              ProCyclistLifestyleAndWealthService.upgradeCatalog.map((spec) {
            final isOwned = lifestyle.ownedUpgrades.contains(spec.id);
            final canAfford = career.privateBalanceEur >= spec.purchasePriceEur;

            return SizedBox(
              width: isMobile ? double.infinity : 370,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOwned ? spec.accentColor : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spec.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label: isOwned
                              ? 'ZAINSTALOWANO'
                              : Formatters.formatCurrency(
                                  spec.purchasePriceEur,
                                ),
                          color: isOwned ? spec.accentColor : AppColors.goldAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InteractiveActionButton(
                      label: isOwned
                          ? 'Aktywne (utrzymanie ${Formatters.formatCurrency(spec.monthlyMaintenanceEur)}/m)'
                          : 'Kup za ${Formatters.formatCurrency(spec.purchasePriceEur)}',
                      accentColor: spec.accentColor,
                      disabled: isOwned || !canAfford,
                      compact: true,
                      onPressed: () => widget.onPurchaseUpgrade(spec.id),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'OSOBISTY SZTAB PRYWATNY (DIETETYK, OSTEOPATA, TRENER)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ProCyclistLifestyleAndWealthService.staffCatalog.map((spec) {
            final isHired = lifestyle.hiredStaff.contains(spec.role);
            final canAfford = career.privateBalanceEur >= spec.signingFeeEur;

            return SizedBox(
              width: isMobile ? double.infinity : 370,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHired ? spec.accentColor : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spec.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label: isHired
                              ? 'ZATRUDNIONY'
                              : '${Formatters.formatCurrency(spec.monthlySalaryEur)}/m',
                          color: isHired ? spec.accentColor : AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.specialtySummary,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InteractiveActionButton(
                      label: isHired
                          ? 'Zwolnij specjalistę'
                          : 'Zatrudnij (opłata ${Formatters.formatCurrency(spec.signingFeeEur)})',
                      accentColor: isHired
                          ? AppColors.crimsonAlert
                          : spec.accentColor,
                      disabled: !isHired && !canAfford,
                      compact: true,
                      onPressed: () => widget.onToggleStaff(spec.role),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSponsorsSection({
    required ProCyclistCareerState career,
    required ProCyclistLifestyleState lifestyle,
    required bool isMobile,
  }) {
    final slotOffers = ProCyclistLifestyleAndWealthService.personalSponsorCatalog
        .where((o) => o.slotCategory == _selectedSponsorSlot)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PersonalSponsorSlotCategory.values.map((slot) {
            final active = lifestyle.activeSponsorsBySlot[slot];
            final isSelected = _selectedSponsorSlot == slot;
            return _InteractiveActionButton(
              label: active == null
                  ? '${slot.label} (Wolny)'
                  : '${slot.label}: ${active.brandName}',
              accentColor:
                  isSelected ? AppColors.goldAccent : AppColors.surfaceLight,
              isSelected: isSelected,
              compact: isMobile,
              onPressed: () => setState(() => _selectedSponsorSlot = slot),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slotOffers.map((offer) {
            final activeInSlot =
                lifestyle.activeSponsorsBySlot[offer.slotCategory];
            final isCurrent = activeInSlot?.sponsorId == offer.sponsorId;
            final meetsFame = career.fameScore >= offer.minFameRequired;
            final meetsTier =
                career.careerTier.rankIndex >= offer.minTierRequired.rankIndex;
            final eligible = meetsFame && meetsTier;

            return SizedBox(
              width: isMobile ? double.infinity : 360,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrent
                        ? AppColors.goldAccent
                        : AppColors.cardBorder,
                    width: isCurrent ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.brandName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label: isCurrent
                              ? 'AKTYWNY'
                              : '+${Formatters.formatCurrency(offer.monthlyRetainerEur)}/m',
                          color: isCurrent
                              ? AppColors.goldAccent
                              : AppColors.statusSuccess,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _BonusTag(
                          text:
                              'Premia za win: ${Formatters.formatCurrency(offer.winBonusEur)}',
                          color: AppColors.goldAccent,
                        ),
                        _BonusTag(
                          text:
                              'Sława min: ${offer.minFameRequired.toStringAsFixed(0)}',
                          color: meetsFame
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                        ),
                        _BonusTag(
                          text: offer.minTierRequired.label,
                          color: meetsTier
                              ? AppColors.accentBlue
                              : AppColors.crimsonAlert,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InteractiveActionButton(
                      label: isCurrent
                          ? 'Kontrakt podpisany'
                          : (eligible ? 'Podpisz kontrakt' : 'Wymagania niespełnione'),
                      accentColor: AppColors.goldAccent,
                      disabled: isCurrent || !eligible,
                      compact: true,
                      onPressed: () => widget.onSignSponsor(offer.sponsorId),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWealthSection({
    required ProCyclistCareerState career,
    required ProCyclistLifestyleState lifestyle,
    required LifestyleBonusSummary summary,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              ProCyclistLifestyleAndWealthService.investmentCatalog.map((spec) {
            final holdingMatch =
                lifestyle.investments.where((e) => e.type == spec.type);
            final holding = holdingMatch.isEmpty ? null : holdingMatch.first;
            final investAmount = spec.minInvestmentEur;
            final canInvest = career.privateBalanceEur >= investAmount;

            return SizedBox(
              width: isMobile ? double.infinity : 370,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: holding != null
                        ? spec.accentColor
                        : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spec.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label:
                              '${spec.annualYieldPercent.toStringAsFixed(1)}% / rok',
                          color: spec.accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spec.riskLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      spec.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      holding == null
                          ? 'Brak pozycji • min. ${Formatters.formatCurrency(investAmount)}'
                          : 'Wartość pozycji: ${Formatters.formatCurrency(holding.totalValueEur)} (zysk ${Formatters.formatCurrency(holding.accruedReturnEur)})',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: holding == null
                            ? AppColors.textSecondary
                            : AppColors.statusSuccess,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InteractiveActionButton(
                          label:
                              'Wpłać ${Formatters.formatCompactCurrency(investAmount)}',
                          accentColor: spec.accentColor,
                          disabled: !canInvest,
                          compact: true,
                          onPressed: () =>
                              widget.onInvest(spec.type, investAmount),
                        ),
                        if (holding != null)
                          _InteractiveActionButton(
                            label: 'Wypłać całość',
                            accentColor: AppColors.surfaceLight,
                            compact: true,
                            onPressed: () =>
                                widget.onLiquidateInvestment(spec.type),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HISTORIA OPERACJI • PORTFEL ${Formatters.formatCurrency(summary.totalInvestmentPortfolioEur)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(height: 8),
              if (lifestyle.recentTransactions.isEmpty)
                const Text(
                  'Brak zapisanych operacji w bieżącym sezonie.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...lifestyle.recentTransactions.take(6).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $entry',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final Color color;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _BonusTag extends StatelessWidget {
  final String text;
  final Color color;

  const _BonusTag({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color accentColor;
  final bool disabled;
  final bool isSelected;
  final bool compact;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    this.icon,
    required this.accentColor,
    this.disabled = false,
    this.isSelected = false,
    this.compact = false,
    required this.onPressed,
  });

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
    final isDisabled = widget.disabled;
    final bgColor = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.24)
            : _pressed
                ? widget.accentColor.withValues(alpha: 0.3)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.22)
                    : widget.accentColor.withValues(alpha: 0.14);

    final borderColor = isDisabled
        ? AppColors.cardBorder
        : _focused
            ? AppColors.goldAccent
            : widget.isSelected || _hovered
                ? widget.accentColor
                : widget.accentColor.withValues(alpha: 0.5);

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: isDisabled
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? AppColors.textSecondary
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
