// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Kategoria produktu w oficjalnym sklepie klubowym drużyny.
enum MerchandiseCategory {
  proReplicaJersey,
  specialEditionJersey,
  bibShortsAndKit,
  casualSupporterWear,
  teamCapsAndSocks,
  waterBottlesAndAccessories,
  scaleModelBikes;

  String get displayNamePl {
    switch (this) {
      case MerchandiseCategory.proReplicaJersey:
        return 'Replika Koszulki Pro';
      case MerchandiseCategory.specialEditionJersey:
        return 'Edycja Limitowana';
      case MerchandiseCategory.bibShortsAndKit:
        return 'Spodenki i Komplet';
      case MerchandiseCategory.casualSupporterWear:
        return 'Odzież Kibica';
      case MerchandiseCategory.teamCapsAndSocks:
        return 'Czapeczki i Skarpety';
      case MerchandiseCategory.waterBottlesAndAccessories:
        return 'Bidony i Akcesoria';
      case MerchandiseCategory.scaleModelBikes:
        return 'Modele Rowerów';
    }
  }

  IconData get icon {
    switch (this) {
      case MerchandiseCategory.proReplicaJersey:
        return Icons.checkroom_rounded;
      case MerchandiseCategory.specialEditionJersey:
        return Icons.auto_awesome_rounded;
      case MerchandiseCategory.bibShortsAndKit:
        return Icons.dry_cleaning_rounded;
      case MerchandiseCategory.casualSupporterWear:
        return Icons.shopping_bag_rounded;
      case MerchandiseCategory.teamCapsAndSocks:
        return Icons.sports_baseball_rounded;
      case MerchandiseCategory.waterBottlesAndAccessories:
        return Icons.local_drink_rounded;
      case MerchandiseCategory.scaleModelBikes:
        return Icons.pedal_bike_rounded;
    }
  }

  double get baseDemandWeight {
    switch (this) {
      case MerchandiseCategory.proReplicaJersey:
        return 1.35;
      case MerchandiseCategory.specialEditionJersey:
        return 0.85;
      case MerchandiseCategory.bibShortsAndKit:
        return 0.72;
      case MerchandiseCategory.casualSupporterWear:
        return 0.95;
      case MerchandiseCategory.teamCapsAndSocks:
        return 1.65;
      case MerchandiseCategory.waterBottlesAndAccessories:
        return 1.85;
      case MerchandiseCategory.scaleModelBikes:
        return 0.30;
    }
  }

  String toJson() => name;

  static MerchandiseCategory fromJson(String? value) {
    if (value == null) return MerchandiseCategory.proReplicaJersey;
    return MerchandiseCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MerchandiseCategory.proReplicaJersey,
    );
  }
}

/// Poziom jakości i pozycjonowania cenowego produktów sklepu.
enum MerchandiseQualityTier {
  budgetSupporter,
  proAeroReplica,
  collectorAuthentic;

  String get displayNamePl {
    switch (this) {
      case MerchandiseQualityTier.budgetSupporter:
        return 'Supporter';
      case MerchandiseQualityTier.proAeroReplica:
        return 'Pro Aero';
      case MerchandiseQualityTier.collectorAuthentic:
        return 'Authentic';
    }
  }

  double get costMultiplier {
    switch (this) {
      case MerchandiseQualityTier.budgetSupporter:
        return 0.78;
      case MerchandiseQualityTier.proAeroReplica:
        return 1.0;
      case MerchandiseQualityTier.collectorAuthentic:
        return 1.38;
    }
  }

  double get demandMultiplier {
    switch (this) {
      case MerchandiseQualityTier.budgetSupporter:
        return 1.24;
      case MerchandiseQualityTier.proAeroReplica:
        return 1.0;
      case MerchandiseQualityTier.collectorAuthentic:
        return 0.74;
    }
  }

  double get priceAnchorMultiplier {
    switch (this) {
      case MerchandiseQualityTier.budgetSupporter:
        return 0.80;
      case MerchandiseQualityTier.proAeroReplica:
        return 1.0;
      case MerchandiseQualityTier.collectorAuthentic:
        return 1.45;
    }
  }

  String toJson() => name;

  static MerchandiseQualityTier fromJson(String? value) {
    if (value == null) return MerchandiseQualityTier.proAeroReplica;
    return MerchandiseQualityTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MerchandiseQualityTier.proAeroReplica,
    );
  }
}

/// Poziom globalnego fanklubu drużyny.
enum FanClubTier {
  localSupporters,
  nationalPeloton,
  continentalFollowing,
  globalPelotonBrand;

  String get displayNamePl {
    switch (this) {
      case FanClubTier.localSupporters:
        return 'Lokalny Klub Kibica';
      case FanClubTier.nationalPeloton:
        return 'Ogólnokrajowa Baza';
      case FanClubTier.continentalFollowing:
        return 'Kontynentalny Fanklub';
      case FanClubTier.globalPelotonBrand:
        return 'Globalna Marka WorldTour';
    }
  }

  Color get badgeColor {
    switch (this) {
      case FanClubTier.localSupporters:
        return AppColors.textSecondary;
      case FanClubTier.nationalPeloton:
        return AppColors.accentBlue;
      case FanClubTier.continentalFollowing:
        return AppColors.statusSuccess;
      case FanClubTier.globalPelotonBrand:
        return AppColors.goldAccent;
    }
  }

  static FanClubTier fromFanCount(int fans) {
    if (fans >= 350000) return FanClubTier.globalPelotonBrand;
    if (fans >= 100000) return FanClubTier.continentalFollowing;
    if (fans >= 25000) return FanClubTier.nationalPeloton;
    return FanClubTier.localSupporters;
  }
}

/// Skala strefy kibica (Fan Zone) organizowanej przy wyścigach.
enum FanZoneEventTier {
  roadsidePopUp,
  villageDepartPavilion,
  summitFanPark,
  grandTourFanzoneHub;

  String get displayNamePl {
    switch (this) {
      case FanZoneEventTier.roadsidePopUp:
        return 'Mobilne Stoisko';
      case FanZoneEventTier.villageDepartPavilion:
        return 'Pawilon Village Départ';
      case FanZoneEventTier.summitFanPark:
        return 'Fan Park na Przełęczy';
      case FanZoneEventTier.grandTourFanzoneHub:
        return 'Główny Hub Grand Tour';
    }
  }

  double get setupCostEur {
    switch (this) {
      case FanZoneEventTier.roadsidePopUp:
        return 4500.0;
      case FanZoneEventTier.villageDepartPavilion:
        return 14500.0;
      case FanZoneEventTier.summitFanPark:
        return 26000.0;
      case FanZoneEventTier.grandTourFanzoneHub:
        return 48000.0;
    }
  }

  int get baseAttendance {
    switch (this) {
      case FanZoneEventTier.roadsidePopUp:
        return 1400;
      case FanZoneEventTier.villageDepartPavilion:
        return 4200;
      case FanZoneEventTier.summitFanPark:
        return 8800;
      case FanZoneEventTier.grandTourFanzoneHub:
        return 17500;
    }
  }

  double get merchandiseBoostMultiplier {
    switch (this) {
      case FanZoneEventTier.roadsidePopUp:
        return 1.12;
      case FanZoneEventTier.villageDepartPavilion:
        return 1.28;
      case FanZoneEventTier.summitFanPark:
        return 1.45;
      case FanZoneEventTier.grandTourFanzoneHub:
        return 1.75;
    }
  }

  double get hospitalitySpendPerFanEur {
    switch (this) {
      case FanZoneEventTier.roadsidePopUp:
        return 4.2;
      case FanZoneEventTier.villageDepartPavilion:
        return 7.5;
      case FanZoneEventTier.summitFanPark:
        return 6.8;
      case FanZoneEventTier.grandTourFanzoneHub:
        return 9.4;
    }
  }

  String toJson() => name;

  static FanZoneEventTier fromJson(String? value) {
    if (value == null) return FanZoneEventTier.villageDepartPavilion;
    return FanZoneEventTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FanZoneEventTier.villageDepartPavilion,
    );
  }
}

/// Specyfikacja pojedynczego produktu w sklepie klubowym.
class MerchandiseProductSpec {
  const MerchandiseProductSpec({
    required this.id,
    required this.name,
    required this.category,
    required this.qualityTier,
    required this.retailPriceEur,
    required this.unitProductionCostEur,
    required this.stockUnits,
    this.unitsSoldSeason = 0,
    this.active = true,
    this.featuredRiderId,
    this.featuredRiderName,
    this.hypeMultiplier = 1.0,
  });

  final String id;
  final String name;
  final MerchandiseCategory category;
  final MerchandiseQualityTier qualityTier;
  final double retailPriceEur;
  final double unitProductionCostEur;
  final int stockUnits;
  final int unitsSoldSeason;
  final bool active;
  final String? featuredRiderId;
  final String? featuredRiderName;
  final double hypeMultiplier;

  double get unitGrossMarginEur => retailPriceEur - unitProductionCostEur;

  double get marginPercent =>
      retailPriceEur > 0 ? (unitGrossMarginEur / retailPriceEur) * 100.0 : 0.0;

  double get grossRevenueEur => unitsSoldSeason * retailPriceEur;

  double get netProfitEur => unitsSoldSeason * unitGrossMarginEur;

  MerchandiseProductSpec copyWith({
    String? id,
    String? name,
    MerchandiseCategory? category,
    MerchandiseQualityTier? qualityTier,
    double? retailPriceEur,
    double? unitProductionCostEur,
    int? stockUnits,
    int? unitsSoldSeason,
    bool? active,
    String? featuredRiderId,
    String? featuredRiderName,
    double? hypeMultiplier,
  }) {
    return MerchandiseProductSpec(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      qualityTier: qualityTier ?? this.qualityTier,
      retailPriceEur: retailPriceEur ?? this.retailPriceEur,
      unitProductionCostEur:
          unitProductionCostEur ?? this.unitProductionCostEur,
      stockUnits: stockUnits ?? this.stockUnits,
      unitsSoldSeason: unitsSoldSeason ?? this.unitsSoldSeason,
      active: active ?? this.active,
      featuredRiderId: featuredRiderId ?? this.featuredRiderId,
      featuredRiderName: featuredRiderName ?? this.featuredRiderName,
      hypeMultiplier: hypeMultiplier ?? this.hypeMultiplier,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.toJson(),
        'qualityTier': qualityTier.toJson(),
        'retailPriceEur': retailPriceEur,
        'unitProductionCostEur': unitProductionCostEur,
        'stockUnits': stockUnits,
        'unitsSoldSeason': unitsSoldSeason,
        'active': active,
        'featuredRiderId': featuredRiderId,
        'featuredRiderName': featuredRiderName,
        'hypeMultiplier': hypeMultiplier,
      };

  factory MerchandiseProductSpec.fromJson(Map<String, dynamic> json) {
    return MerchandiseProductSpec(
      id: (json['id'] as String?) ?? 'prod_unknown',
      name: (json['name'] as String?) ?? 'Produkt Klubowy',
      category: MerchandiseCategory.fromJson(json['category'] as String?),
      qualityTier:
          MerchandiseQualityTier.fromJson(json['qualityTier'] as String?),
      retailPriceEur: ((json['retailPriceEur'] as num?) ?? 50.0).toDouble(),
      unitProductionCostEur:
          ((json['unitProductionCostEur'] as num?) ?? 20.0).toDouble(),
      stockUnits: ((json['stockUnits'] as num?) ?? 0).toInt(),
      unitsSoldSeason: ((json['unitsSoldSeason'] as num?) ?? 0).toInt(),
      active: (json['active'] as bool?) ?? true,
      featuredRiderId: json['featuredRiderId'] as String?,
      featuredRiderName: json['featuredRiderName'] as String?,
      hypeMultiplier: ((json['hypeMultiplier'] as num?) ?? 1.0).toDouble(),
    );
  }
}

/// Stan bazy kibiców i płatnego fanklubu drużyny.
class FanClubMembershipSnapshot {
  const FanClubMembershipSnapshot({
    required this.totalFanBase,
    required this.paidClubMembers,
    required this.annualMembershipFeeEur,
    required this.fanEngagementIndex,
    required this.regionalSupporters,
  });

  final int totalFanBase;
  final int paidClubMembers;
  final double annualMembershipFeeEur;
  final double fanEngagementIndex;
  final Map<String, int> regionalSupporters;

  FanClubTier get tier => FanClubTier.fromFanCount(totalFanBase);

  double get annualMembershipRevenueEur =>
      paidClubMembers * annualMembershipFeeEur;

  double get monthlyMembershipRevenueEur => annualMembershipRevenueEur / 12.0;

  double get conversionRatePercent =>
      totalFanBase > 0 ? (paidClubMembers / totalFanBase) * 100.0 : 0.0;

  FanClubMembershipSnapshot copyWith({
    int? totalFanBase,
    int? paidClubMembers,
    double? annualMembershipFeeEur,
    double? fanEngagementIndex,
    Map<String, int>? regionalSupporters,
  }) {
    return FanClubMembershipSnapshot(
      totalFanBase: totalFanBase ?? this.totalFanBase,
      paidClubMembers: paidClubMembers ?? this.paidClubMembers,
      annualMembershipFeeEur:
          annualMembershipFeeEur ?? this.annualMembershipFeeEur,
      fanEngagementIndex: fanEngagementIndex ?? this.fanEngagementIndex,
      regionalSupporters: regionalSupporters ?? this.regionalSupporters,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalFanBase': totalFanBase,
        'paidClubMembers': paidClubMembers,
        'annualMembershipFeeEur': annualMembershipFeeEur,
        'fanEngagementIndex': fanEngagementIndex,
        'regionalSupporters': regionalSupporters,
      };

  factory FanClubMembershipSnapshot.fromJson(Map<String, dynamic> json) {
    final rawRegions =
        (json['regionalSupporters'] as Map<String, dynamic>?) ?? const {};
    return FanClubMembershipSnapshot(
      totalFanBase: ((json['totalFanBase'] as num?) ?? 42000).toInt(),
      paidClubMembers: ((json['paidClubMembers'] as num?) ?? 3150).toInt(),
      annualMembershipFeeEur:
          ((json['annualMembershipFeeEur'] as num?) ?? 45.0).toDouble(),
      fanEngagementIndex:
          ((json['fanEngagementIndex'] as num?) ?? 68.0).toDouble(),
      regionalSupporters: rawRegions.map(
        (key, value) => MapEntry(key, ((value as num?) ?? 0).toInt()),
      ),
    );
  }
}

/// Aktywacja strefy kibica (Fan Zone) na wybranym wyścigu.
class FanZoneActivation {
  const FanZoneActivation({
    required this.id,
    required this.raceName,
    required this.stageOrLocation,
    required this.countryCode,
    required this.eventTier,
    required this.setupCostEur,
    required this.expectedAttendance,
    this.actualAttendance = 0,
    required this.merchandiseBoostMultiplier,
    this.ticketAndHospitalityRevenueEur = 0.0,
    this.merchandiseSalesEur = 0.0,
    this.newFansGained = 0,
    this.executed = false,
    this.satisfactionScore = 0.0,
  });

  final String id;
  final String raceName;
  final String stageOrLocation;
  final String countryCode;
  final FanZoneEventTier eventTier;
  final double setupCostEur;
  final int expectedAttendance;
  final int actualAttendance;
  final double merchandiseBoostMultiplier;
  final double ticketAndHospitalityRevenueEur;
  final double merchandiseSalesEur;
  final int newFansGained;
  final bool executed;
  final double satisfactionScore;

  double get totalRevenueEur =>
      ticketAndHospitalityRevenueEur + merchandiseSalesEur;

  double get netProfitEur => totalRevenueEur - setupCostEur;

  double get roiPercent =>
      setupCostEur > 0 ? (netProfitEur / setupCostEur) * 100.0 : 0.0;

  FanZoneActivation copyWith({
    String? id,
    String? raceName,
    String? stageOrLocation,
    String? countryCode,
    FanZoneEventTier? eventTier,
    double? setupCostEur,
    int? expectedAttendance,
    int? actualAttendance,
    double? merchandiseBoostMultiplier,
    double? ticketAndHospitalityRevenueEur,
    double? merchandiseSalesEur,
    int? newFansGained,
    bool? executed,
    double? satisfactionScore,
  }) {
    return FanZoneActivation(
      id: id ?? this.id,
      raceName: raceName ?? this.raceName,
      stageOrLocation: stageOrLocation ?? this.stageOrLocation,
      countryCode: countryCode ?? this.countryCode,
      eventTier: eventTier ?? this.eventTier,
      setupCostEur: setupCostEur ?? this.setupCostEur,
      expectedAttendance: expectedAttendance ?? this.expectedAttendance,
      actualAttendance: actualAttendance ?? this.actualAttendance,
      merchandiseBoostMultiplier:
          merchandiseBoostMultiplier ?? this.merchandiseBoostMultiplier,
      ticketAndHospitalityRevenueEur:
          ticketAndHospitalityRevenueEur ?? this.ticketAndHospitalityRevenueEur,
      merchandiseSalesEur: merchandiseSalesEur ?? this.merchandiseSalesEur,
      newFansGained: newFansGained ?? this.newFansGained,
      executed: executed ?? this.executed,
      satisfactionScore: satisfactionScore ?? this.satisfactionScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'raceName': raceName,
        'stageOrLocation': stageOrLocation,
        'countryCode': countryCode,
        'eventTier': eventTier.toJson(),
        'setupCostEur': setupCostEur,
        'expectedAttendance': expectedAttendance,
        'actualAttendance': actualAttendance,
        'merchandiseBoostMultiplier': merchandiseBoostMultiplier,
        'ticketAndHospitalityRevenueEur': ticketAndHospitalityRevenueEur,
        'merchandiseSalesEur': merchandiseSalesEur,
        'newFansGained': newFansGained,
        'executed': executed,
        'satisfactionScore': satisfactionScore,
      };

  factory FanZoneActivation.fromJson(Map<String, dynamic> json) {
    return FanZoneActivation(
      id: (json['id'] as String?) ?? 'fz_unknown',
      raceName: (json['raceName'] as String?) ?? 'Wyścig WorldTour',
      stageOrLocation: (json['stageOrLocation'] as String?) ?? 'Meta',
      countryCode: (json['countryCode'] as String?) ?? 'FR',
      eventTier: FanZoneEventTier.fromJson(json['eventTier'] as String?),
      setupCostEur: ((json['setupCostEur'] as num?) ?? 10000.0).toDouble(),
      expectedAttendance: ((json['expectedAttendance'] as num?) ?? 3000).toInt(),
      actualAttendance: ((json['actualAttendance'] as num?) ?? 0).toInt(),
      merchandiseBoostMultiplier:
          ((json['merchandiseBoostMultiplier'] as num?) ?? 1.2).toDouble(),
      ticketAndHospitalityRevenueEur:
          ((json['ticketAndHospitalityRevenueEur'] as num?) ?? 0.0).toDouble(),
      merchandiseSalesEur:
          ((json['merchandiseSalesEur'] as num?) ?? 0.0).toDouble(),
      newFansGained: ((json['newFansGained'] as num?) ?? 0).toInt(),
      executed: (json['executed'] as bool?) ?? false,
      satisfactionScore:
          ((json['satisfactionScore'] as num?) ?? 0.0).toDouble(),
    );
  }
}

/// Popyt na repliki koszulek generowany przez gwiazdy składu.
class StarRiderJerseyDemand {
  const StarRiderJerseyDemand({
    required this.riderId,
    required this.riderName,
    required this.nationality,
    required this.popularityScore,
    this.recentWins = 0,
    this.isWearingLeaderJersey = false,
    required this.estimatedReplicaSharePercent,
    required this.seasonUnitsSold,
    required this.seasonRevenueEur,
  });

  final String riderId;
  final String riderName;
  final String nationality;
  final double popularityScore;
  final int recentWins;
  final bool isWearingLeaderJersey;
  final double estimatedReplicaSharePercent;
  final int seasonUnitsSold;
  final double seasonRevenueEur;

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'nationality': nationality,
        'popularityScore': popularityScore,
        'recentWins': recentWins,
        'isWearingLeaderJersey': isWearingLeaderJersey,
        'estimatedReplicaSharePercent': estimatedReplicaSharePercent,
        'seasonUnitsSold': seasonUnitsSold,
        'seasonRevenueEur': seasonRevenueEur,
      };

  factory StarRiderJerseyDemand.fromJson(Map<String, dynamic> json) {
    return StarRiderJerseyDemand(
      riderId: (json['riderId'] as String?) ?? 'rider_1',
      riderName: (json['riderName'] as String?) ?? 'Kolarz',
      nationality: (json['nationality'] as String?) ?? 'PL',
      popularityScore: ((json['popularityScore'] as num?) ?? 50.0).toDouble(),
      recentWins: ((json['recentWins'] as num?) ?? 0).toInt(),
      isWearingLeaderJersey: (json['isWearingLeaderJersey'] as bool?) ?? false,
      estimatedReplicaSharePercent:
          ((json['estimatedReplicaSharePercent'] as num?) ?? 20.0).toDouble(),
      seasonUnitsSold: ((json['seasonUnitsSold'] as num?) ?? 0).toInt(),
      seasonRevenueEur:
          ((json['seasonRevenueEur'] as num?) ?? 0.0).toDouble(),
    );
  }
}

/// Miesięczny wpis w księdze przychodów komercyjnych kibiców.
class MonthlyMerchandiseLedgerEntry {
  const MonthlyMerchandiseLedgerEntry({
    required this.monthIndex,
    required this.monthLabel,
    required this.storeRevenueEur,
    required this.fanClubRevenueEur,
    required this.fanZoneRevenueEur,
    required this.productionAndLogisticsCostEur,
    required this.netProfitEur,
    required this.unitsSold,
  });

  final int monthIndex;
  final String monthLabel;
  final double storeRevenueEur;
  final double fanClubRevenueEur;
  final double fanZoneRevenueEur;
  final double productionAndLogisticsCostEur;
  final double netProfitEur;
  final int unitsSold;

  double get grossRevenueEur =>
      storeRevenueEur + fanClubRevenueEur + fanZoneRevenueEur;
}

/// Zbiorczy raport przychodów ze sklepu klubowego, replik i stref kibica.
class MerchandiseRevenueReport {
  const MerchandiseRevenueReport({
    required this.seasonYear,
    required this.teamName,
    required this.totalStoreRevenueEur,
    required this.totalFanClubRevenueEur,
    required this.totalFanZoneRevenueEur,
    required this.totalCostsEur,
    required this.totalUnitsSold,
    required this.averageMarginPercent,
    required this.topSellingCategory,
    required this.topSellingRiderName,
    required this.fanClubTier,
  });

  final int seasonYear;
  final String teamName;
  final double totalStoreRevenueEur;
  final double totalFanClubRevenueEur;
  final double totalFanZoneRevenueEur;
  final double totalCostsEur;
  final int totalUnitsSold;
  final double averageMarginPercent;
  final MerchandiseCategory topSellingCategory;
  final String topSellingRiderName;
  final FanClubTier fanClubTier;

  double get totalGrossRevenueEur =>
      totalStoreRevenueEur + totalFanClubRevenueEur + totalFanZoneRevenueEur;

  double get totalNetProfitEur => totalGrossRevenueEur - totalCostsEur;
}

/// Wynik pojedynczego cyklu sprzedaży miesięcznej w sklepie.
class MonthlyStoreCycleOutcome {
  const MonthlyStoreCycleOutcome({
    required this.updatedCatalog,
    required this.ledgerEntry,
    required this.updatedFanClub,
  });

  final List<MerchandiseProductSpec> updatedCatalog;
  final MonthlyMerchandiseLedgerEntry ledgerEntry;
  final FanClubMembershipSnapshot updatedFanClub;
}

/// Główny serwis obliczeniowy przychodów ze sklepu klubowego, replik i Fan Zones.
class TeamMerchandiseAndFanClubRevenueService {
  const TeamMerchandiseAndFanClubRevenueService();

  static const List<String> _monthNamesPl = [
    'Sty',
    'Lut',
    'Mar',
    'Kwi',
    'Maj',
    'Cze',
    'Lip',
    'Sie',
    'Wrz',
    'Paź',
    'Lis',
    'Gru',
  ];

  /// Tworzy domyślny, zbalansowany katalog sklepu klubowego dla drużyny.
  List<MerchandiseProductSpec> createDefaultCatalog({
    required String teamName,
    double teamPrestige = 68.0,
  }) {
    final prestigeFactor = (0.85 + (teamPrestige.clamp(0.0, 100.0) / 250.0));
    return [
      MerchandiseProductSpec(
        id: 'merch_pro_jersey',
        name: '$teamName Pro Aero Jersey 2026',
        category: MerchandiseCategory.proReplicaJersey,
        qualityTier: MerchandiseQualityTier.proAeroReplica,
        retailPriceEur: (95.0 * prestigeFactor).roundToDouble(),
        unitProductionCostEur: 34.0,
        stockUnits: 1400,
        unitsSoldSeason: 820,
        featuredRiderId: 'rider_leader_1',
        featuredRiderName: 'K. Majewski',
        hypeMultiplier: 1.25,
      ),
      MerchandiseProductSpec(
        id: 'merch_gt_special',
        name: '$teamName Grand Tour Edition Jersey',
        category: MerchandiseCategory.specialEditionJersey,
        qualityTier: MerchandiseQualityTier.collectorAuthentic,
        retailPriceEur: (139.0 * prestigeFactor).roundToDouble(),
        unitProductionCostEur: 49.0,
        stockUnits: 480,
        unitsSoldSeason: 310,
        featuredRiderId: 'rider_sprinter_2',
        featuredRiderName: 'L. Van Der Berg',
        hypeMultiplier: 1.45,
      ),
      MerchandiseProductSpec(
        id: 'merch_bib_kit',
        name: '$teamName Team Bib Shorts Pro',
        category: MerchandiseCategory.bibShortsAndKit,
        qualityTier: MerchandiseQualityTier.proAeroReplica,
        retailPriceEur: 118.0,
        unitProductionCostEur: 44.0,
        stockUnits: 620,
        unitsSoldSeason: 290,
      ),
      MerchandiseProductSpec(
        id: 'merch_hoodie',
        name: '$teamName Paddock Team Hoodie',
        category: MerchandiseCategory.casualSupporterWear,
        qualityTier: MerchandiseQualityTier.budgetSupporter,
        retailPriceEur: 68.0,
        unitProductionCostEur: 24.0,
        stockUnits: 900,
        unitsSoldSeason: 540,
      ),
      MerchandiseProductSpec(
        id: 'merch_caps_socks',
        name: '$teamName Peloton Cap & Aero Socks',
        category: MerchandiseCategory.teamCapsAndSocks,
        qualityTier: MerchandiseQualityTier.budgetSupporter,
        retailPriceEur: 26.0,
        unitProductionCostEur: 7.5,
        stockUnits: 2400,
        unitsSoldSeason: 1680,
      ),
      MerchandiseProductSpec(
        id: 'merch_bidon',
        name: '$teamName Fly Team Bidon 550ml',
        category: MerchandiseCategory.waterBottlesAndAccessories,
        qualityTier: MerchandiseQualityTier.budgetSupporter,
        retailPriceEur: 14.0,
        unitProductionCostEur: 3.2,
        stockUnits: 3800,
        unitsSoldSeason: 2450,
      ),
      MerchandiseProductSpec(
        id: 'merch_scale_bike',
        name: '$teamName Team Carbon Bike 1:8 Model',
        category: MerchandiseCategory.scaleModelBikes,
        qualityTier: MerchandiseQualityTier.collectorAuthentic,
        retailPriceEur: 165.0,
        unitProductionCostEur: 68.0,
        stockUnits: 180,
        unitsSoldSeason: 95,
      ),
    ];
  }

  /// Oblicza koszt domówienia partii produktu z rabatem wolumenowym.
  double calculateRestockCost({
    required MerchandiseProductSpec product,
    required int quantity,
  }) {
    if (quantity <= 0) return 0.0;
    double discount = 1.0;
    if (quantity >= 2000) {
      discount = 0.84;
    } else if (quantity >= 500) {
      discount = 0.91;
    } else if (quantity >= 200) {
      discount = 0.96;
    }
    return product.unitProductionCostEur * quantity * discount;
  }

  /// Oblicza elastyczność cenową popytu przy zmianie ceny detalicznej.
  double estimatePriceElasticityMultiplier({
    required MerchandiseCategory category,
    required MerchandiseQualityTier tier,
    required double retailPriceEur,
  }) {
    final referencePrice = _referencePriceFor(category) * tier.priceAnchorMultiplier;
    if (referencePrice <= 0 || retailPriceEur <= 0) return 0.0;
    final ratio = retailPriceEur / referencePrice;
    // Cena poniżej referencyjnej zwiększa popyt, powyżej — tłumi wykładniczo.
    final elasticity = math.pow(ratio, -1.35).toDouble();
    return elasticity.clamp(0.18, 2.15);
  }

  double _referencePriceFor(MerchandiseCategory category) {
    switch (category) {
      case MerchandiseCategory.proReplicaJersey:
        return 95.0;
      case MerchandiseCategory.specialEditionJersey:
        return 125.0;
      case MerchandiseCategory.bibShortsAndKit:
        return 115.0;
      case MerchandiseCategory.casualSupporterWear:
        return 68.0;
      case MerchandiseCategory.teamCapsAndSocks:
        return 26.0;
      case MerchandiseCategory.waterBottlesAndAccessories:
        return 14.0;
      case MerchandiseCategory.scaleModelBikes:
        return 160.0;
    }
  }

  /// Symuluje miesięczny cykl sprzedaży sklepu i składek fanklubu.
  MonthlyStoreCycleOutcome simulateMonthlyCycle({
    required int monthIndex,
    required List<MerchandiseProductSpec> catalog,
    required FanClubMembershipSnapshot fanClub,
    required double teamPrestige,
    required double recentWinHype,
    double activeFanZoneBoost = 1.0,
  }) {
    final clampedMonth = monthIndex.clamp(1, 12);
    final clampedPrestige = teamPrestige.clamp(0.0, 100.0);
    final clampedHype = recentWinHype.clamp(0.0, 2.0);

    // Sezonowość kolarska: szczyt w maju (Giro), lipcu (TdF) i sierpniu/wrześniu.
    const seasonalCurve = <int, double>{
      1: 0.65,
      2: 0.78,
      3: 0.95,
      4: 1.12,
      5: 1.25,
      6: 1.18,
      7: 1.48,
      8: 1.28,
      9: 1.14,
      10: 0.88,
      11: 0.68,
      12: 1.08, // Zakupy świąteczne
    };
    final seasonFactor = seasonalCurve[clampedMonth] ?? 1.0;

    final fanDemandBase = math.sqrt(math.max(1000, fanClub.totalFanBase)) / 18.0;
    final prestigeMultiplier = 0.70 + (clampedPrestige / 100.0) * 0.75;
    final engagementMultiplier =
        0.75 + (fanClub.fanEngagementIndex.clamp(0.0, 100.0) / 100.0) * 0.55;
    final hypeMultiplier = 1.0 + (clampedHype * 0.35);

    double storeRevenue = 0.0;
    double productionCost = 0.0;
    int totalUnits = 0;

    final updatedCatalog = <MerchandiseProductSpec>[];
    for (final product in catalog) {
      if (!product.active || product.stockUnits <= 0) {
        updatedCatalog.add(product);
        continue;
      }

      final priceElasticity = estimatePriceElasticityMultiplier(
        category: product.category,
        tier: product.qualityTier,
        retailPriceEur: product.retailPriceEur,
      );

      final rawUnits = fanDemandBase *
          product.category.baseDemandWeight *
          product.qualityTier.demandMultiplier *
          prestigeMultiplier *
          engagementMultiplier *
          hypeMultiplier *
          product.hypeMultiplier *
          seasonFactor *
          activeFanZoneBoost *
          priceElasticity;

      final soldUnits = rawUnits.round().clamp(0, product.stockUnits);
      storeRevenue += soldUnits * product.retailPriceEur;
      productionCost += soldUnits * product.unitProductionCostEur;
      totalUnits += soldUnits;

      updatedCatalog.add(
        product.copyWith(
          stockUnits: product.stockUnits - soldUnits,
          unitsSoldSeason: product.unitsSoldSeason + soldUnits,
        ),
      );
    }

    // Przychód ze składek członkowskich fanklubu (miesięczna transza).
    final fanClubMonthly = fanClub.monthlyMembershipRevenueEur;
    // Koszt obsługi fanklubu (~14% przychodu ze składek) + wysyłka (2.8 EUR/szt.).
    final fulfillmentAndClubCost =
        productionCost + (totalUnits * 2.8) + (fanClubMonthly * 0.14);
    final netProfit = (storeRevenue + fanClubMonthly) - fulfillmentAndClubCost;

    // Organiczny przyrost bazy kibiców po dobrym miesiącu.
    final organicFanGain =
        ((clampedPrestige * 8.5) * (1.0 + clampedHype * 0.5)).round();
    final updatedFanClub = fanClub.copyWith(
      totalFanBase: fanClub.totalFanBase + organicFanGain,
      paidClubMembers: fanClub.paidClubMembers + (organicFanGain * 0.07).round(),
    );

    final entry = MonthlyMerchandiseLedgerEntry(
      monthIndex: clampedMonth,
      monthLabel: _monthNamesPl[clampedMonth - 1],
      storeRevenueEur: storeRevenue,
      fanClubRevenueEur: fanClubMonthly,
      fanZoneRevenueEur: 0.0,
      productionAndLogisticsCostEur: fulfillmentAndClubCost,
      netProfitEur: netProfit,
      unitsSold: totalUnits,
    );

    return MonthlyStoreCycleOutcome(
      updatedCatalog: updatedCatalog,
      ledgerEntry: entry,
      updatedFanClub: updatedFanClub,
    );
  }

  /// Oblicza wynik finansowy i frekwencyjny strefy kibica (Fan Zone) na wyścigu.
  FanZoneActivation evaluateAndExecuteFanZone({
    required FanZoneActivation activation,
    required FanClubMembershipSnapshot fanClub,
    required double teamPrestige,
    required bool hadStagePodiumOrWin,
  }) {
    if (activation.executed) return activation;

    final prestigeFactor = 0.78 + (teamPrestige.clamp(0.0, 100.0) / 140.0);
    final engagementFactor =
        0.82 + (fanClub.fanEngagementIndex.clamp(0.0, 100.0) / 220.0);
    final podiumBonus = hadStagePodiumOrWin ? 1.24 : 1.0;

    final attendance = (activation.expectedAttendance *
            prestigeFactor *
            engagementFactor *
            podiumBonus)
        .round()
        .clamp(250, 60000);

    final hospitalityRevenue =
        attendance * activation.eventTier.hospitalitySpendPerFanEur;

    // Średni wydatek na gadżety w strefie kibica rośnie przy sukcesach.
    final avgMerchSpendPerVisitor =
        (9.5 * activation.eventTier.merchandiseBoostMultiplier) *
            (hadStagePodiumOrWin ? 1.22 : 1.0);
    final merchSales = attendance * avgMerchSpendPerVisitor * 0.42;

    final newFans = (attendance * (hadStagePodiumOrWin ? 0.16 : 0.09)).round();
    final satisfaction = (72.0 +
            (teamPrestige * 0.15) +
            (hadStagePodiumOrWin ? 11.0 : 0.0))
        .clamp(40.0, 99.0);

    return activation.copyWith(
      actualAttendance: attendance,
      ticketAndHospitalityRevenueEur: hospitalityRevenue,
      merchandiseSalesEur: merchSales,
      newFansGained: newFans,
      executed: true,
      satisfactionScore: satisfaction,
    );
  }

  /// Aktualizuje bazę kibiców po wyniku sportowym (zwycięstwo, podium, lider).
  FanClubMembershipSnapshot applyRaceResultFanImpact({
    required FanClubMembershipSnapshot current,
    required String regionCode,
    required int newFans,
    required double engagementDelta,
  }) {
    final updatedTotal = math.max(1000, current.totalFanBase + newFans);
    final updatedPaid = math.max(
      100,
      current.paidClubMembers + (newFans * 0.085).round(),
    );
    final updatedEngagement =
        (current.fanEngagementIndex + engagementDelta).clamp(15.0, 100.0);

    final updatedRegions = Map<String, int>.from(current.regionalSupporters);
    updatedRegions[regionCode] =
        math.max(0, (updatedRegions[regionCode] ?? 0) + newFans);

    return current.copyWith(
      totalFanBase: updatedTotal,
      paidClubMembers: updatedPaid,
      fanEngagementIndex: updatedEngagement,
      regionalSupporters: updatedRegions,
    );
  }

  /// Wylicza udział gwiazd zespołu w sprzedaży replik koszulek.
  List<StarRiderJerseyDemand> computeStarRiderDemand({
    required List<StarRiderJerseyDemand> riders,
    required int totalReplicaUnitsSold,
    required double avgReplicaPriceEur,
  }) {
    if (riders.isEmpty) return const [];

    final weights = riders.map((r) {
      final winFactor = 1.0 + (r.recentWins * 0.18);
      final jerseyBonus = r.isWearingLeaderJersey ? 1.45 : 1.0;
      return math.max(1.0, r.popularityScore) * winFactor * jerseyBonus;
    }).toList();

    final sumWeights = weights.fold<double>(0.0, (a, b) => a + b);
    if (sumWeights <= 0) return riders;

    final result = <StarRiderJerseyDemand>[];
    for (int i = 0; i < riders.length; i++) {
      final r = riders[i];
      final share = weights[i] / sumWeights;
      final units = (totalReplicaUnitsSold * share).round();
      result.add(
        StarRiderJerseyDemand(
          riderId: r.riderId,
          riderName: r.riderName,
          nationality: r.nationality,
          popularityScore: r.popularityScore,
          recentWins: r.recentWins,
          isWearingLeaderJersey: r.isWearingLeaderJersey,
          estimatedReplicaSharePercent: share * 100.0,
          seasonUnitsSold: units,
          seasonRevenueEur: units * avgReplicaPriceEur,
        ),
      );
    }

    result.sort(
      (a, b) => b.estimatedReplicaSharePercent
          .compareTo(a.estimatedReplicaSharePercent),
    );
    return result;
  }

  /// Generuje zbiorczy raport sezonu dla ekranu finansów i karty UI.
  MerchandiseRevenueReport buildSeasonReport({
    required int seasonYear,
    required String teamName,
    required List<MerchandiseProductSpec> catalog,
    required FanClubMembershipSnapshot fanClub,
    required List<FanZoneActivation> fanZones,
    required List<StarRiderJerseyDemand> starRiders,
  }) {
    double storeRev = 0.0;
    double storeCosts = 0.0;
    int totalUnits = 0;

    final categoryRevenue = <MerchandiseCategory, double>{};
    for (final p in catalog) {
      storeRev += p.grossRevenueEur;
      storeCosts += p.unitsSoldSeason * (p.unitProductionCostEur + 2.8);
      totalUnits += p.unitsSoldSeason;
      categoryRevenue[p.category] =
          (categoryRevenue[p.category] ?? 0.0) + p.grossRevenueEur;
    }

    double fanZoneRev = 0.0;
    double fanZoneCost = 0.0;
    for (final fz in fanZones) {
      if (fz.executed) {
        fanZoneRev += fz.totalRevenueEur;
        fanZoneCost += fz.setupCostEur;
      } else {
        fanZoneCost += fz.setupCostEur * 0.25; // Zaliczka rezerwacyjna
      }
    }

    final fanClubRev = fanClub.annualMembershipRevenueEur;
    final fanClubCost = fanClubRev * 0.14;

    final avgMargin = storeRev > 0
        ? ((storeRev - storeCosts) / storeRev) * 100.0
        : 0.0;

    MerchandiseCategory topCat = MerchandiseCategory.proReplicaJersey;
    double topCatRev = -1.0;
    categoryRevenue.forEach((cat, rev) {
      if (rev > topCatRev) {
        topCatRev = rev;
        topCat = cat;
      }
    });

    final topRider = starRiders.isNotEmpty
        ? starRiders.first.riderName
        : 'Brak lidera sprzedaży';

    return MerchandiseRevenueReport(
      seasonYear: seasonYear,
      teamName: teamName,
      totalStoreRevenueEur: storeRev,
      totalFanClubRevenueEur: fanClubRev,
      totalFanZoneRevenueEur: fanZoneRev,
      totalCostsEur: storeCosts + fanZoneCost + fanClubCost,
      totalUnitsSold: totalUnits,
      averageMarginPercent: avgMargin.clamp(0.0, 99.0),
      topSellingCategory: topCat,
      topSellingRiderName: topRider,
      fanClubTier: fanClub.tier,
    );
  }
}

/// Stan zarządzania sklepem klubowym, fanklubem i strefami kibica.
class TeamMerchandiseAndFanClubState {
  const TeamMerchandiseAndFanClubState({
    required this.seasonYear,
    required this.currentMonth,
    required this.teamName,
    required this.teamPrestige,
    required this.catalog,
    required this.fanClub,
    required this.fanZones,
    required this.starRiders,
    required this.monthlyLedger,
    required this.report,
    this.lastNotification,
  });

  final int seasonYear;
  final int currentMonth;
  final String teamName;
  final double teamPrestige;
  final List<MerchandiseProductSpec> catalog;
  final FanClubMembershipSnapshot fanClub;
  final List<FanZoneActivation> fanZones;
  final List<StarRiderJerseyDemand> starRiders;
  final List<MonthlyMerchandiseLedgerEntry> monthlyLedger;
  final MerchandiseRevenueReport report;
  final String? lastNotification;

  TeamMerchandiseAndFanClubState copyWith({
    int? seasonYear,
    int? currentMonth,
    String? teamName,
    double? teamPrestige,
    List<MerchandiseProductSpec>? catalog,
    FanClubMembershipSnapshot? fanClub,
    List<FanZoneActivation>? fanZones,
    List<StarRiderJerseyDemand>? starRiders,
    List<MonthlyMerchandiseLedgerEntry>? monthlyLedger,
    MerchandiseRevenueReport? report,
    String? lastNotification,
    bool clearNotification = false,
  }) {
    return TeamMerchandiseAndFanClubState(
      seasonYear: seasonYear ?? this.seasonYear,
      currentMonth: currentMonth ?? this.currentMonth,
      teamName: teamName ?? this.teamName,
      teamPrestige: teamPrestige ?? this.teamPrestige,
      catalog: catalog ?? this.catalog,
      fanClub: fanClub ?? this.fanClub,
      fanZones: fanZones ?? this.fanZones,
      starRiders: starRiders ?? this.starRiders,
      monthlyLedger: monthlyLedger ?? this.monthlyLedger,
      report: report ?? this.report,
      lastNotification: clearNotification
          ? null
          : (lastNotification ?? this.lastNotification),
    );
  }
}

/// Kontroler Riverpod dla przychodów ze sklepu klubowego, replik i Fan Zones.
class TeamMerchandiseAndFanClubNotifier
    extends StateNotifier<TeamMerchandiseAndFanClubState> {
  TeamMerchandiseAndFanClubNotifier({
    TeamMerchandiseAndFanClubRevenueService? service,
  })  : _service = service ?? const TeamMerchandiseAndFanClubRevenueService(),
        super(_createInitialState(
            service ?? const TeamMerchandiseAndFanClubRevenueService()));

  final TeamMerchandiseAndFanClubRevenueService _service;

  static TeamMerchandiseAndFanClubState _createInitialState(
    TeamMerchandiseAndFanClubRevenueService service,
  ) {
    const teamName = 'Veloce Orlen Pro Cycling';
    const prestige = 76.0;
    final catalog = service.createDefaultCatalog(
      teamName: teamName,
      teamPrestige: prestige,
    );
    const fanClub = FanClubMembershipSnapshot(
      totalFanBase: 148500,
      paidClubMembers: 11420,
      annualMembershipFeeEur: 49.0,
      fanEngagementIndex: 78.5,
      regionalSupporters: {
        'PL': 58400,
        'BE': 24100,
        'FR': 22900,
        'IT': 18600,
        'ES': 11200,
        'Global': 13300,
      },
    );

    final initialFanZones = [
      const FanZoneActivation(
        id: 'fz_flanders',
        raceName: 'Ronde van Vlaanderen',
        stageOrLocation: 'Oude Kwaremont',
        countryCode: 'BE',
        eventTier: FanZoneEventTier.summitFanPark,
        setupCostEur: 26000.0,
        expectedAttendance: 8800,
        actualAttendance: 10240,
        merchandiseBoostMultiplier: 1.45,
        ticketAndHospitalityRevenueEur: 69632.0,
        merchandiseSalesEur: 52100.0,
        newFansGained: 1420,
        executed: true,
        satisfactionScore: 89.5,
      ),
      const FanZoneActivation(
        id: 'fz_tdf_alpe',
        raceName: 'Tour de France',
        stageOrLocation: 'Alpe d\'Huez — Zakręt 7',
        countryCode: 'FR',
        eventTier: FanZoneEventTier.grandTourFanzoneHub,
        setupCostEur: 48000.0,
        expectedAttendance: 17500,
        merchandiseBoostMultiplier: 1.75,
      ),
      const FanZoneActivation(
        id: 'fz_tdp_krakow',
        raceName: 'Tour de Pologne',
        stageOrLocation: 'Kraków Błonia — Meta',
        countryCode: 'PL',
        eventTier: FanZoneEventTier.villageDepartPavilion,
        setupCostEur: 14500.0,
        expectedAttendance: 4200,
        merchandiseBoostMultiplier: 1.28,
      ),
    ];

    const seedRiders = [
      StarRiderJerseyDemand(
        riderId: 'rider_leader_1',
        riderName: 'Kacper Majewski',
        nationality: 'PL',
        popularityScore: 88.0,
        recentWins: 3,
        isWearingLeaderJersey: true,
        estimatedReplicaSharePercent: 45.0,
        seasonUnitsSold: 508,
        seasonRevenueEur: 55880.0,
      ),
      StarRiderJerseyDemand(
        riderId: 'rider_sprinter_2',
        riderName: 'Lucas Van Der Berg',
        nationality: 'BE',
        popularityScore: 79.0,
        recentWins: 4,
        isWearingLeaderJersey: false,
        estimatedReplicaSharePercent: 34.0,
        seasonUnitsSold: 384,
        seasonRevenueEur: 42240.0,
      ),
      StarRiderJerseyDemand(
        riderId: 'rider_climber_3',
        riderName: 'Matteo Bellini',
        nationality: 'IT',
        popularityScore: 67.0,
        recentWins: 1,
        isWearingLeaderJersey: false,
        estimatedReplicaSharePercent: 21.0,
        seasonUnitsSold: 238,
        seasonRevenueEur: 26180.0,
      ),
    ];

    final starRiders = service.computeStarRiderDemand(
      riders: seedRiders,
      totalReplicaUnitsSold: 1130,
      avgReplicaPriceEur: 108.0,
    );

    const initialLedger = [
      MonthlyMerchandiseLedgerEntry(
        monthIndex: 3,
        monthLabel: 'Mar',
        storeRevenueEur: 68400.0,
        fanClubRevenueEur: 46631.0,
        fanZoneRevenueEur: 0.0,
        productionAndLogisticsCostEur: 31200.0,
        netProfitEur: 83831.0,
        unitsSold: 1210,
      ),
      MonthlyMerchandiseLedgerEntry(
        monthIndex: 4,
        monthLabel: 'Kwi',
        storeRevenueEur: 94200.0,
        fanClubRevenueEur: 46631.0,
        fanZoneRevenueEur: 121732.0,
        productionAndLogisticsCostEur: 66800.0,
        netProfitEur: 195763.0,
        unitsSold: 1645,
      ),
    ];

    final report = service.buildSeasonReport(
      seasonYear: 2026,
      teamName: teamName,
      catalog: catalog,
      fanClub: fanClub,
      fanZones: initialFanZones,
      starRiders: starRiders,
    );

    return TeamMerchandiseAndFanClubState(
      seasonYear: 2026,
      currentMonth: 5,
      teamName: teamName,
      teamPrestige: prestige,
      catalog: catalog,
      fanClub: fanClub,
      fanZones: initialFanZones,
      starRiders: starRiders,
      monthlyLedger: initialLedger,
      report: report,
    );
  }

  void _rebuildWith({
    List<MerchandiseProductSpec>? catalog,
    FanClubMembershipSnapshot? fanClub,
    List<FanZoneActivation>? fanZones,
    List<StarRiderJerseyDemand>? starRiders,
    List<MonthlyMerchandiseLedgerEntry>? monthlyLedger,
    int? currentMonth,
    String? notification,
  }) {
    final nextCatalog = catalog ?? state.catalog;
    final nextFanClub = fanClub ?? state.fanClub;
    final nextFanZones = fanZones ?? state.fanZones;

    final replicaUnits = nextCatalog
        .where((p) =>
            p.category == MerchandiseCategory.proReplicaJersey ||
            p.category == MerchandiseCategory.specialEditionJersey)
        .fold<int>(0, (sum, p) => sum + p.unitsSoldSeason);

    final nextRiders = _service.computeStarRiderDemand(
      riders: starRiders ?? state.starRiders,
      totalReplicaUnitsSold: replicaUnits,
      avgReplicaPriceEur: 108.0,
    );

    final nextReport = _service.buildSeasonReport(
      seasonYear: state.seasonYear,
      teamName: state.teamName,
      catalog: nextCatalog,
      fanClub: nextFanClub,
      fanZones: nextFanZones,
      starRiders: nextRiders,
    );

    state = state.copyWith(
      currentMonth: currentMonth ?? state.currentMonth,
      catalog: nextCatalog,
      fanClub: nextFanClub,
      fanZones: nextFanZones,
      starRiders: nextRiders,
      monthlyLedger: monthlyLedger ?? state.monthlyLedger,
      report: nextReport,
      lastNotification: notification,
    );
  }

  /// Domawia partię produktu do magazynu sklepu.
  void restockProduct(String productId, int quantity) {
    if (quantity <= 0) return;
    double cost = 0.0;
    String productName = '';
    final updated = state.catalog.map((p) {
      if (p.id != productId) return p;
      cost = _service.calculateRestockCost(product: p, quantity: quantity);
      productName = p.name;
      return p.copyWith(stockUnits: p.stockUnits + quantity);
    }).toList();

    _rebuildWith(
      catalog: updated,
      notification:
          'Domówiono $quantity szt. ($productName) za €${cost.toStringAsFixed(0)}.',
    );
  }

  /// Włącza lub wstrzymuje sprzedaż produktu w sklepie.
  void toggleProductActive(String productId) {
    final updated = state.catalog.map((p) {
      if (p.id != productId) return p;
      return p.copyWith(active: !p.active);
    }).toList();
    _rebuildWith(catalog: updated);
  }

  /// Aktualizuje cenę detaliczną produktu (zabezpieczoną przed sprzedażą poniżej kosztu).
  void updateProductPrice(String productId, double newPriceEur) {
    final updated = state.catalog.map((p) {
      if (p.id != productId) return p;
      final minPrice = (p.unitProductionCostEur * 1.15).ceilToDouble();
      final maxPrice = (p.unitProductionCostEur * 6.5).ceilToDouble();
      final clamped = newPriceEur.clamp(minPrice, maxPrice);
      return p.copyWith(retailPriceEur: clamped);
    }).toList();
    _rebuildWith(catalog: updated);
  }

  /// Planuje nową strefę kibica (Fan Zone) na wyścig.
  void scheduleFanZone({
    required String raceName,
    required String location,
    required String countryCode,
    required FanZoneEventTier tier,
  }) {
    final trimmedRace = raceName.trim();
    final trimmedLocation = location.trim();
    if (trimmedRace.isEmpty || trimmedLocation.isEmpty) return;

    final newZone = FanZoneActivation(
      id: 'fz_${DateTime.now().microsecondsSinceEpoch}',
      raceName: trimmedRace,
      stageOrLocation: trimmedLocation,
      countryCode: countryCode.trim().isEmpty ? 'EU' : countryCode.trim(),
      eventTier: tier,
      setupCostEur: tier.setupCostEur,
      expectedAttendance: tier.baseAttendance,
      merchandiseBoostMultiplier: tier.merchandiseBoostMultiplier,
    );

    _rebuildWith(
      fanZones: [newZone, ...state.fanZones],
      notification:
          'Zaplanowano strefę kibica: $trimmedRace (${tier.displayNamePl}).',
    );
  }

  /// Realizuje zaplanowaną strefę kibica i księguje jej przychody oraz nowych fanów.
  void executeFanZone(String fanZoneId, {bool hadStagePodiumOrWin = true}) {
    FanZoneActivation? executedZone;
    final updatedZones = state.fanZones.map((fz) {
      if (fz.id != fanZoneId || fz.executed) return fz;
      executedZone = _service.evaluateAndExecuteFanZone(
        activation: fz,
        fanClub: state.fanClub,
        teamPrestige: state.teamPrestige,
        hadStagePodiumOrWin: hadStagePodiumOrWin,
      );
      return executedZone!;
    }).toList();

    if (executedZone == null) return;

    final updatedFanClub = _service.applyRaceResultFanImpact(
      current: state.fanClub,
      regionCode: executedZone!.countryCode,
      newFans: executedZone!.newFansGained,
      engagementDelta: hadStagePodiumOrWin ? 2.4 : 1.1,
    );

    _rebuildWith(
      fanZones: updatedZones,
      fanClub: updatedFanClub,
      notification:
          'Fan Zone ${executedZone!.raceName}: ${executedZone!.actualAttendance} kibiców, zysk netto €${executedZone!.netProfitEur.toStringAsFixed(0)}.',
    );
  }

  /// Uruchamia miesięczny cykl sprzedaży sklepu i fanklubu.
  void runMonthlyStoreCycle({double recentWinHype = 0.65}) {
    final activeBoost = state.fanZones
        .where((fz) => fz.executed)
        .fold<double>(
          1.0,
          (maxBoost, fz) => math.max(maxBoost, fz.merchandiseBoostMultiplier),
        );

    final outcome = _service.simulateMonthlyCycle(
      monthIndex: state.currentMonth,
      catalog: state.catalog,
      fanClub: state.fanClub,
      teamPrestige: state.teamPrestige,
      recentWinHype: recentWinHype,
      activeFanZoneBoost: activeBoost > 1.0 ? 1.0 + (activeBoost - 1.0) * 0.45 : 1.0,
    );

    final nextMonth = state.currentMonth >= 12 ? 1 : state.currentMonth + 1;
    _rebuildWith(
      currentMonth: nextMonth,
      catalog: outcome.updatedCatalog,
      fanClub: outcome.updatedFanClub,
      monthlyLedger: [...state.monthlyLedger, outcome.ledgerEntry],
      notification:
          'Rozliczono ${outcome.ledgerEntry.monthLabel}: sprzedano ${outcome.ledgerEntry.unitsSold} szt., zysk netto €${outcome.ledgerEntry.netProfitEur.toStringAsFixed(0)}.',
    );
  }

  /// Wypuszcza limitowaną edycję koszulki po sukcesie sportowym.
  void launchSpecialEditionDrop({
    required String editionTitle,
    required String riderId,
    required String riderName,
  }) {
    final id = 'merch_drop_${DateTime.now().microsecondsSinceEpoch}';
    final drop = MerchandiseProductSpec(
      id: id,
      name: editionTitle.trim().isEmpty
          ? '${state.teamName} Victory Limited Jersey'
          : editionTitle.trim(),
      category: MerchandiseCategory.specialEditionJersey,
      qualityTier: MerchandiseQualityTier.collectorAuthentic,
      retailPriceEur: 149.0,
      unitProductionCostEur: 52.0,
      stockUnits: 600,
      unitsSoldSeason: 0,
      featuredRiderId: riderId,
      featuredRiderName: riderName,
      hypeMultiplier: 1.75,
    );

    _rebuildWith(
      catalog: [drop, ...state.catalog],
      notification: 'Wydano edycję limitowaną: ${drop.name} (600 szt.).',
    );
  }

  /// Aktualizuje roczną składkę członkowską oficjalnego fanklubu.
  void updateMembershipFee(double newFeeEur) {
    final clamped = newFeeEur.clamp(19.0, 149.0);
    // Wyższa składka lekko obniża konwersję, niższa ją podnosi.
    final baseMembers = (state.fanClub.totalFanBase * 0.078).round();
    final priceFactor = math.pow(49.0 / clamped, 0.55).toDouble();
    final adjustedMembers = (baseMembers * priceFactor).round().clamp(150, state.fanClub.totalFanBase);

    _rebuildWith(
      fanClub: state.fanClub.copyWith(
        annualMembershipFeeEur: clamped,
        paidClubMembers: adjustedMembers,
      ),
    );
  }
}

final teamMerchandiseAndFanClubServiceProvider =
    Provider<TeamMerchandiseAndFanClubRevenueService>(
  (ref) => const TeamMerchandiseAndFanClubRevenueService(),
);

final teamMerchandiseAndFanClubProvider = StateNotifierProvider<
    TeamMerchandiseAndFanClubNotifier, TeamMerchandiseAndFanClubState>(
  (ref) => TeamMerchandiseAndFanClubNotifier(
    service: ref.watch(teamMerchandiseAndFanClubServiceProvider),
  ),
);

/// Produkcyjny, responsywny panel zarządzania Sklepem Klubowym, Replikami i Fan Zones.
class TeamMerchandiseAndFanClubPanel extends ConsumerStatefulWidget {
  const TeamMerchandiseAndFanClubPanel({super.key});

  @override
  ConsumerState<TeamMerchandiseAndFanClubPanel> createState() =>
      _TeamMerchandiseAndFanClubPanelState();
}

class _TeamMerchandiseAndFanClubPanelState
    extends ConsumerState<TeamMerchandiseAndFanClubPanel> {
  int _selectedTab = 0;
  final TextEditingController _raceNameCtrl =
      TextEditingController(text: 'Vuelta a España');
  final TextEditingController _locationCtrl =
      TextEditingController(text: 'Alto de l\'Angliru');
  FanZoneEventTier _newZoneTier = FanZoneEventTier.summitFanPark;

  static const TextStyle _tabularText = TextStyle(
    fontFamily: 'Inter',
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  void dispose() {
    _raceNameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _formatEur(double value) {
    final absVal = value.abs().round();
    final str = absVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return '${value < 0 ? '-' : ''}€$buffer';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamMerchandiseAndFanClubProvider);
    final notifier = ref.read(teamMerchandiseAndFanClubProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 640;
        final isTablet = width >= 640 && width < 1100;

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, notifier, isMobile),
                const SizedBox(height: 16),
                _buildKpiRow(state, isMobile, isTablet),
                if (state.lastNotification != null) ...[
                  const SizedBox(height: 12),
                  _buildNotificationBanner(state.lastNotification!),
                ],
                const SizedBox(height: 16),
                _buildTabBar(isMobile),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _selectedTab == 0
                      ? _buildStoreTab(state, notifier, isMobile, isTablet)
                      : _selectedTab == 1
                          ? _buildFanZonesTab(
                              state, notifier, isMobile, isTablet)
                          : _buildFanClubAndLedgerTab(
                              state, notifier, isMobile, isTablet),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    TeamMerchandiseAndFanClubState state,
    TeamMerchandiseAndFanClubNotifier notifier,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
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
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sklep Klubowy, Repliki & Fan Zones',
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
                      '${state.teamName} • Sezon ${state.seasonYear} • Prestiż ${state.teamPrestige.round()}/100',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
            children: [
              _InteractiveActionButton(
                label: 'Limitowany Drop',
                icon: Icons.auto_awesome_rounded,
                accentColor: AppColors.goldAccent,
                onPressed: () {
                  final topRider = state.starRiders.isNotEmpty
                      ? state.starRiders.first
                      : null;
                  notifier.launchSpecialEditionDrop(
                    editionTitle:
                        '${state.teamName} Mountain Stage Gold Edition',
                    riderId: topRider?.riderId ?? 'rider_leader_1',
                    riderName: topRider?.riderName ?? 'Lider Zespołu',
                  );
                },
              ),
              _InteractiveActionButton(
                label: 'Rozlicz Miesiąc (${state.currentMonth}/12)',
                icon: Icons.calendar_month_rounded,
                accentColor: AppColors.statusSuccess,
                filled: true,
                onPressed: () => notifier.runMonthlyStoreCycle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    TeamMerchandiseAndFanClubState state,
    bool isMobile,
    bool isTablet,
  ) {
    final report = state.report;
    final cards = [
      _KpiMetricCard(
        title: 'Przychód Całkowity',
        value: _formatEur(report.totalGrossRevenueEur),
        subtitle: 'Netto: ${_formatEur(report.totalNetProfitEur)}',
        icon: Icons.account_balance_wallet_rounded,
        accent: AppColors.goldAccent,
      ),
      _KpiMetricCard(
        title: 'Sklep & Repliki',
        value: _formatEur(report.totalStoreRevenueEur),
        subtitle:
            '${report.totalUnitsSold} szt. • Marża ${report.averageMarginPercent.toStringAsFixed(1)}%',
        icon: Icons.checkroom_rounded,
        accent: AppColors.accentBlue,
      ),
      _KpiMetricCard(
        title: 'Baza Kibiców & Klub',
        value: '${(state.fanClub.totalFanBase / 1000).toStringAsFixed(1)}k',
        subtitle:
            '${state.fanClub.paidClubMembers} członków • ${_formatEur(report.totalFanClubRevenueEur)}/rok',
        icon: Icons.groups_rounded,
        accent: AppColors.statusSuccess,
      ),
      _KpiMetricCard(
        title: 'Strefy Kibica (Fan Zones)',
        value: _formatEur(report.totalFanZoneRevenueEur),
        subtitle:
            '${state.fanZones.where((z) => z.executed).length}/${state.fanZones.length} zrealizowanych',
        icon: Icons.festival_rounded,
        accent: AppColors.primaryAccent,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
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

  Widget _buildNotificationBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded,
              color: AppColors.goldAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    const tabs = [
      (label: 'Sklep & Repliki', icon: Icons.checkroom_rounded),
      (label: 'Strefy Kibica (Fan Zones)', icon: Icons.festival_rounded),
      (label: 'Fanklub & Księga', icon: Icons.analytics_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (int i = 0; i < tabs.length; i++)
            _InteractiveTabChip(
              label: tabs[i].label,
              icon: tabs[i].icon,
              selected: _selectedTab == i,
              compact: isMobile,
              onTap: () => setState(() => _selectedTab = i),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreTab(
    TeamMerchandiseAndFanClubState state,
    TeamMerchandiseAndFanClubNotifier notifier,
    bool isMobile,
    bool isTablet,
  ) {
    final catalogWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < state.catalog.length; i++) ...[
          _ProductRowCard(
            product: state.catalog[i],
            formatEur: _formatEur,
            isMobile: isMobile,
            onToggleActive: () =>
                notifier.toggleProductActive(state.catalog[i].id),
            onRestock: () => notifier.restockProduct(state.catalog[i].id, 250),
            onPriceStep: (delta) => notifier.updateProductPrice(
              state.catalog[i].id,
              state.catalog[i].retailPriceEur + delta,
            ),
          ),
          if (i < state.catalog.length - 1) const SizedBox(height: 10),
        ],
      ],
    );

    final starRidersCard = _buildStarRiderDemandCard(state);

    if (isMobile || isTablet) {
      return Column(
        key: const ValueKey('tab_store'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          catalogWidget,
          const SizedBox(height: 16),
          starRidersCard,
        ],
      );
    }

    return Row(
      key: const ValueKey('tab_store'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: catalogWidget),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: starRidersCard),
      ],
    );
  }

  Widget _buildStarRiderDemandCard(TeamMerchandiseAndFanClubState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.goldAccent, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Popyt na Repliki Gwiazd',
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
          for (final rider in state.starRiders) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rider.isWearingLeaderJersey
                      ? AppColors.goldAccent.withValues(alpha: 0.6)
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
                          '${rider.riderName} (${rider.nationality})',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${rider.estimatedReplicaSharePercent.toStringAsFixed(1)}%',
                        style: _tabularText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (rider.estimatedReplicaSharePercent / 100.0)
                          .clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      color: rider.isWearingLeaderJersey
                          ? AppColors.goldAccent
                          : AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${rider.seasonUnitsSold} replik • ${_formatEur(rider.seasonRevenueEur)} • Wygrane: ${rider.recentWins}',
                    style: _tabularText.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFanZonesTab(
    TeamMerchandiseAndFanClubState state,
    TeamMerchandiseAndFanClubNotifier notifier,
    bool isMobile,
    bool isTablet,
  ) {
    final plannerCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zaplanuj Nową Strefę Kibica',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 220,
                child: _buildDarkTextField(_raceNameCtrl, 'Wyścig'),
              ),
              SizedBox(
                width: isMobile ? double.infinity : 220,
                child: _buildDarkTextField(_locationCtrl, 'Lokalizacja / Przełęcz'),
              ),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButton<FanZoneEventTier>(
                    value: _newZoneTier,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    items: FanZoneEventTier.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              '${t.displayNamePl} (${_formatEur(t.setupCostEur)})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _newZoneTier = val);
                      }
                    },
                  ),
                ),
              ),
              _InteractiveActionButton(
                label: 'Dodaj Fan Zone',
                icon: Icons.add_location_alt_rounded,
                accentColor: AppColors.goldAccent,
                filled: true,
                onPressed: () {
                  notifier.scheduleFanZone(
                    raceName: _raceNameCtrl.text,
                    location: _locationCtrl.text,
                    countryCode: 'ES',
                    tier: _newZoneTier,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      key: const ValueKey('tab_fanzones'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        plannerCard,
        const SizedBox(height: 14),
        for (final fz in state.fanZones) ...[
          _FanZoneCard(
            zone: fz,
            formatEur: _formatEur,
            isMobile: isMobile,
            onExecute: fz.executed
                ? null
                : () => notifier.executeFanZone(fz.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildDarkTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFanClubAndLedgerTab(
    TeamMerchandiseAndFanClubState state,
    TeamMerchandiseAndFanClubNotifier notifier,
    bool isMobile,
    bool isTablet,
  ) {
    final clubCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.fanClub.tier.displayNamePl,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: state.fanClub.tier.badgeColor,
                  ),
                ),
              ),
              Text(
                'Zaangażowanie: ${state.fanClub.fanEngagementIndex.toStringAsFixed(1)}%',
                style: _tabularText.copyWith(
                  fontSize: 12.5,
                  color: AppColors.statusSuccess,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Roczna składka fanklubu: ${_formatEur(state.fanClub.annualMembershipFeeEur)} '
            '(Członkowie: ${state.fanClub.paidClubMembers})',
            style: _tabularText.copyWith(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          Slider(
            value: state.fanClub.annualMembershipFeeEur.clamp(19.0, 149.0),
            min: 19.0,
            max: 149.0,
            divisions: 26,
            activeColor: AppColors.goldAccent,
            inactiveColor: AppColors.surfaceLight,
            onChanged: (val) => notifier.updateMembershipFee(val.roundToDouble()),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.fanClub.regionalSupporters.entries.map((entry) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '${entry.key}: ${(entry.value / 1000).toStringAsFixed(1)}k',
                  style: _tabularText.copyWith(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    final ledgerCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Księga Przychodów Miesięcznych',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in state.monthlyLedger.reversed) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      entry.monthLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.unitsSold} szt. • Sklep ${_formatEur(entry.storeRevenueEur)}',
                      style: _tabularText.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '+${_formatEur(entry.netProfitEur)}',
                    style: _tabularText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: entry.netProfitEur >= 0
                          ? AppColors.statusSuccess
                          : AppColors.crimsonAlert,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Column(
      key: const ValueKey('tab_fanclub'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        clubCard,
        const SizedBox(height: 14),
        ledgerCard,
      ],
    );
  }
}

class _KpiMetricCard extends StatefulWidget {
  const _KpiMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  State<_KpiMetricCard> createState() => _KpiMetricCardState();
}

class _KpiMetricCardState extends State<_KpiMetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.65)
                : AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: widget.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontFeatures: [FontFeature.tabularFigures()],
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontFeatures: [FontFeature.tabularFigures()],
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveTabChip extends StatefulWidget {
  const _InteractiveTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_InteractiveTabChip> createState() => _InteractiveTabChipState();
}

class _InteractiveTabChipState extends State<_InteractiveTabChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent
        : (_hovered ? AppColors.surfaceLight : Colors.transparent);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.primaryAccent : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
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
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight:
                          widget.selected ? FontWeight.w700 : FontWeight.w500,
                      color: widget.selected
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

class _InteractiveActionButton extends StatefulWidget {
  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;
  final bool filled;

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
    final disabled = widget.onPressed == null;
    final bg = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.filled
            ? (_hovered
                ? widget.accentColor.withValues(alpha: 0.9)
                : widget.accentColor)
            : (_hovered ? AppColors.surfaceLight : AppColors.surface);

    final fg = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.filled
            ? AppColors.background
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (disabled
                        ? AppColors.cardBorder
                        : widget.accentColor.withValues(alpha: 0.7)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: fg),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: fg,
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

class _ProductRowCard extends StatelessWidget {
  const _ProductRowCard({
    required this.product,
    required this.formatEur,
    required this.isMobile,
    required this.onToggleActive,
    required this.onRestock,
    required this.onPriceStep,
  });

  final MerchandiseProductSpec product;
  final String Function(double) formatEur;
  final bool isMobile;
  final VoidCallback onToggleActive;
  final VoidCallback onRestock;
  final void Function(double delta) onPriceStep;

  @override
  Widget build(BuildContext context) {
    final stockLow = product.stockUnits < 250;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.active
              ? AppColors.cardBorder
              : AppColors.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                product.category.icon,
                color: product.active
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
                      product.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: product.active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${product.category.displayNamePl} • ${product.qualityTier.displayNamePl} • Marża ${product.marginPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: product.active,
                activeThumbColor: AppColors.statusSuccess,
                onChanged: (_) => onToggleActive(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Magazyn: ${product.stockUnits} szt. • Sprzedano: ${product.unitsSoldSeason} • Przychód: ${formatEur(product.grossRevenueEur)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 12,
                  color:
                      stockLow ? AppColors.amberWarning : AppColors.textSecondary,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InteractiveActionButton(
                    label: '-5€',
                    icon: Icons.remove_rounded,
                    accentColor: AppColors.textSecondary,
                    onPressed: () => onPriceStep(-5.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      formatEur(product.retailPriceEur),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _InteractiveActionButton(
                    label: '+5€',
                    icon: Icons.add_rounded,
                    accentColor: AppColors.textSecondary,
                    onPressed: () => onPriceStep(5.0),
                  ),
                  _InteractiveActionButton(
                    label: '+250 szt.',
                    icon: Icons.inventory_2_rounded,
                    accentColor: AppColors.accentBlue,
                    onPressed: onRestock,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FanZoneCard extends StatelessWidget {
  const _FanZoneCard({
    required this.zone,
    required this.formatEur,
    required this.isMobile,
    required this.onExecute,
  });

  final FanZoneActivation zone;
  final String Function(double) formatEur;
  final bool isMobile;
  final VoidCallback? onExecute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: zone.executed
              ? AppColors.statusSuccess.withValues(alpha: 0.45)
              : AppColors.cardBorder,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${zone.raceName} — ${zone.stageOrLocation} (${zone.countryCode})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                zone.executed
                    ? '${zone.eventTier.displayNamePl} • Frekwencja: ${zone.actualAttendance} • Przychód: ${formatEur(zone.totalRevenueEur)} • Zysk netto: ${formatEur(zone.netProfitEur)}'
                    : '${zone.eventTier.displayNamePl} • Koszt: ${formatEur(zone.setupCostEur)} • Szac. frekwencja: ${zone.expectedAttendance}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          _InteractiveActionButton(
            label: zone.executed ? 'Zrealizowano' : 'Uruchom Fan Zone',
            icon: zone.executed
                ? Icons.check_circle_rounded
                : Icons.play_arrow_rounded,
            accentColor: AppColors.statusSuccess,
            filled: !zone.executed,
            onPressed: onExecute,
          ),
        ],
      ),
    );
  }
}
