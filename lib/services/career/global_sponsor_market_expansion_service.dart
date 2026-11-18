// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/race/global_exotic_tours_expansion_model.dart';
import '../../models/team/sponsor_contract.dart';

/// Główny region rynków wschodzących dla ekspansji sponsorskiej zespołu.
enum EmergingSponsorRegion {
  asia,
  africa,
  middleEast;

  String toJson() => name;

  static EmergingSponsorRegion fromJson(String value) {
    return EmergingSponsorRegion.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmergingSponsorRegion.asia,
    );
  }

  String get label {
    switch (this) {
      case EmergingSponsorRegion.asia:
        return 'Azja';
      case EmergingSponsorRegion.africa:
        return 'Afryka';
      case EmergingSponsorRegion.middleEast:
        return 'Bliski Wschód';
    }
  }

  String get fullTitle {
    switch (this) {
      case EmergingSponsorRegion.asia:
        return 'Azja & Pacyfik';
      case EmergingSponsorRegion.africa:
        return 'Afryka Wschodnia & Płd.';
      case EmergingSponsorRegion.middleEast:
        return 'Bliski Wschód & Zatoka';
    }
  }

  IconData get icon {
    switch (this) {
      case EmergingSponsorRegion.asia:
        return Icons.temple_buddhist_rounded;
      case EmergingSponsorRegion.africa:
        return Icons.terrain_rounded;
      case EmergingSponsorRegion.middleEast:
        return Icons.wb_sunny_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case EmergingSponsorRegion.asia:
        return AppColors.accentBlue;
      case EmergingSponsorRegion.africa:
        return AppColors.statusSuccess;
      case EmergingSponsorRegion.middleEast:
        return AppColors.goldAccent;
    }
  }
}

/// Podregion geograficzny koncentracji kapitału i wyścigów pozaeuropejskich.
enum EmergingMarketSubHub {
  southeastAsia,
  eastAndCentralAsia,
  eastAfrica,
  southernAndNorthAfrica,
  gulfCooperationCouncil;

  String toJson() => name;

  static EmergingMarketSubHub fromJson(String value) {
    return EmergingMarketSubHub.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmergingMarketSubHub.southeastAsia,
    );
  }

  String get label {
    switch (this) {
      case EmergingMarketSubHub.southeastAsia:
        return 'Azja Płd.-Wsch. (Kuala Lumpur / Singapur)';
      case EmergingMarketSubHub.eastAndCentralAsia:
        return 'Azja Wsch. i Centr. (Tokio / Astana)';
      case EmergingMarketSubHub.eastAfrica:
        return 'Afryka Wschodnia (Kigali / Nairobi)';
      case EmergingMarketSubHub.southernAndNorthAfrica:
        return 'Afryka Płd. i Płn. (Kapsztad / Casablanca)';
      case EmergingMarketSubHub.gulfCooperationCouncil:
        return 'Zatoka Perska (AlUla / Maskat / Dubaj)';
    }
  }

  EmergingSponsorRegion get parentRegion {
    switch (this) {
      case EmergingMarketSubHub.southeastAsia:
      case EmergingMarketSubHub.eastAndCentralAsia:
        return EmergingSponsorRegion.asia;
      case EmergingMarketSubHub.eastAfrica:
      case EmergingMarketSubHub.southernAndNorthAfrica:
        return EmergingSponsorRegion.africa;
      case EmergingMarketSubHub.gulfCooperationCouncil:
        return EmergingSponsorRegion.middleEast;
    }
  }
}

/// Sektor gospodarki reprezentowany przez sponsora z rynku wschodzącego.
enum EmergingSponsorSector {
  sovereignTourism,
  telecomAndFintech,
  cleanEnergyAndAviation,
  miningAndLogistics,
  techAndMobility;

  String toJson() => name;

  static EmergingSponsorSector fromJson(String value) {
    return EmergingSponsorSector.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EmergingSponsorSector.sovereignTourism,
    );
  }

  String get label {
    switch (this) {
      case EmergingSponsorSector.sovereignTourism:
        return 'Turystyka & Fundusz Narodowy';
      case EmergingSponsorSector.telecomAndFintech:
        return 'Telekomunikacja & Fintech';
      case EmergingSponsorSector.cleanEnergyAndAviation:
        return 'Czysta Energia & Lotnictwo';
      case EmergingSponsorSector.miningAndLogistics:
        return 'Logistyka & Surowce';
      case EmergingSponsorSector.techAndMobility:
        return 'Technologie & Mobilność';
    }
  }

  SponsorIndustry get mappedSponsorIndustry {
    switch (this) {
      case EmergingSponsorSector.sovereignTourism:
        return SponsorIndustry.finance;
      case EmergingSponsorSector.telecomAndFintech:
        return SponsorIndustry.tech;
      case EmergingSponsorSector.cleanEnergyAndAviation:
        return SponsorIndustry.airlines;
      case EmergingSponsorSector.miningAndLogistics:
        return SponsorIndustry.energy;
      case EmergingSponsorSector.techAndMobility:
        return SponsorIndustry.automotive;
    }
  }

  IconData get icon {
    switch (this) {
      case EmergingSponsorSector.sovereignTourism:
        return Icons.public_rounded;
      case EmergingSponsorSector.telecomAndFintech:
        return Icons.cell_tower_rounded;
      case EmergingSponsorSector.cleanEnergyAndAviation:
        return Icons.flight_takeoff_rounded;
      case EmergingSponsorSector.miningAndLogistics:
        return Icons.local_shipping_rounded;
      case EmergingSponsorSector.techAndMobility:
        return Icons.memory_rounded;
    }
  }
}

/// Poziom zakorzenienia i rozpoznawalności zespołu na danym rynku wschodzącym.
enum MarketPresenceTier {
  unexplored,
  scouting,
  regionalPartner,
  strategicAlliance,
  flagshipTitle;

  String toJson() => name;

  static MarketPresenceTier fromJson(String value) {
    return MarketPresenceTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MarketPresenceTier.unexplored,
    );
  }

  String get label {
    switch (this) {
      case MarketPresenceTier.unexplored:
        return 'Rynek Nieodkryty';
      case MarketPresenceTier.scouting:
        return 'Rozpoznanie Rynku';
      case MarketPresenceTier.regionalPartner:
        return 'Partner Regionalny';
      case MarketPresenceTier.strategicAlliance:
        return 'Sojusz Strategiczny';
      case MarketPresenceTier.flagshipTitle:
        return 'Sponsor Tytularny Rynku';
    }
  }

  double get commercialBonusMultiplier {
    switch (this) {
      case MarketPresenceTier.unexplored:
        return 1.00;
      case MarketPresenceTier.scouting:
        return 1.08;
      case MarketPresenceTier.regionalPartner:
        return 1.18;
      case MarketPresenceTier.strategicAlliance:
        return 1.32;
      case MarketPresenceTier.flagshipTitle:
        return 1.50;
    }
  }

  static MarketPresenceTier fromPenetration(double penetration) {
    if (penetration >= 80.0) return MarketPresenceTier.flagshipTitle;
    if (penetration >= 55.0) return MarketPresenceTier.strategicAlliance;
    if (penetration >= 30.0) return MarketPresenceTier.regionalPartner;
    if (penetration >= 10.0) return MarketPresenceTier.scouting;
    return MarketPresenceTier.unexplored;
  }
}

/// Typ aktywacji marketingowo-sportowej na rynku wschodzącym.
enum RegionalActivationType {
  exoticTourWildcardStart,
  localTalentDevelopmentCamp,
  hospitalityAndVipSummit,
  jerseyLocalizationPatch,
  youthCyclingAcademyGrant;

  String toJson() => name;

  static RegionalActivationType fromJson(String value) {
    return RegionalActivationType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RegionalActivationType.exoticTourWildcardStart,
    );
  }

  String get label {
    switch (this) {
      case RegionalActivationType.exoticTourWildcardStart:
        return 'Start w Tourze Eksportowym UCI';
      case RegionalActivationType.localTalentDevelopmentCamp:
        return 'Obóz Skautingowy Talentów';
      case RegionalActivationType.hospitalityAndVipSummit:
        return 'Szczyt Biznesowy & VIP';
      case RegionalActivationType.jerseyLocalizationPatch:
        return 'Lokalizacja Stroju & Media';
      case RegionalActivationType.youthCyclingAcademyGrant:
        return 'Grant Akademii Kolarskiej';
    }
  }
}

/// Wynik negocjacji kontraktu z nowym sponsorem z rynku wschodzącego.
enum SponsorNegotiationOutcomeStatus {
  accepted,
  counterOffer,
  rejected,
  insufficientPrestige,
  alreadySigned;

  String toJson() => name;

  static SponsorNegotiationOutcomeStatus fromJson(String value) {
    return SponsorNegotiationOutcomeStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorNegotiationOutcomeStatus.counterOffer,
    );
  }
}

/// Profil ekonomiczno-medialny danego rynku wschodzącego.
class EmergingMarketRegionProfile {
  final EmergingSponsorRegion region;
  final List<EmergingMarketSubHub> subHubs;
  final double marketGrowthRatePercent;
  final double mediaBroadcastReachMillions;
  final double baseCommercialMultiplier;
  final double fanbasePenetration;
  final MarketPresenceTier presenceTier;
  final List<ExoticTourId> linkedExoticTours;
  final int activeLocalRidersCount;
  final int completedActivationsCount;
  final bool isScouted;

  const EmergingMarketRegionProfile({
    required this.region,
    required this.subHubs,
    required this.marketGrowthRatePercent,
    required this.mediaBroadcastReachMillions,
    required this.baseCommercialMultiplier,
    required this.fanbasePenetration,
    required this.presenceTier,
    required this.linkedExoticTours,
    required this.activeLocalRidersCount,
    required this.completedActivationsCount,
    required this.isScouted,
  });

  double get effectiveCommercialMultiplier =>
      baseCommercialMultiplier * presenceTier.commercialBonusMultiplier;

  EmergingMarketRegionProfile copyWith({
    EmergingSponsorRegion? region,
    List<EmergingMarketSubHub>? subHubs,
    double? marketGrowthRatePercent,
    double? mediaBroadcastReachMillions,
    double? baseCommercialMultiplier,
    double? fanbasePenetration,
    MarketPresenceTier? presenceTier,
    List<ExoticTourId>? linkedExoticTours,
    int? activeLocalRidersCount,
    int? completedActivationsCount,
    bool? isScouted,
  }) {
    final nextPenetration =
        (fanbasePenetration ?? this.fanbasePenetration).clamp(0.0, 100.0);
    return EmergingMarketRegionProfile(
      region: region ?? this.region,
      subHubs: subHubs ?? this.subHubs,
      marketGrowthRatePercent:
          marketGrowthRatePercent ?? this.marketGrowthRatePercent,
      mediaBroadcastReachMillions:
          mediaBroadcastReachMillions ?? this.mediaBroadcastReachMillions,
      baseCommercialMultiplier:
          baseCommercialMultiplier ?? this.baseCommercialMultiplier,
      fanbasePenetration: nextPenetration,
      presenceTier:
          presenceTier ?? MarketPresenceTier.fromPenetration(nextPenetration),
      linkedExoticTours: linkedExoticTours ?? this.linkedExoticTours,
      activeLocalRidersCount:
          activeLocalRidersCount ?? this.activeLocalRidersCount,
      completedActivationsCount:
          completedActivationsCount ?? this.completedActivationsCount,
      isScouted: isScouted ?? this.isScouted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region.toJson(),
      'subHubs': subHubs.map((e) => e.toJson()).toList(),
      'marketGrowthRatePercent': marketGrowthRatePercent,
      'mediaBroadcastReachMillions': mediaBroadcastReachMillions,
      'baseCommercialMultiplier': baseCommercialMultiplier,
      'fanbasePenetration': fanbasePenetration,
      'presenceTier': presenceTier.toJson(),
      'linkedExoticTours': linkedExoticTours.map((e) => e.toJson()).toList(),
      'activeLocalRidersCount': activeLocalRidersCount,
      'completedActivationsCount': completedActivationsCount,
      'isScouted': isScouted,
    };
  }

  factory EmergingMarketRegionProfile.fromJson(Map<String, dynamic> json) {
    return EmergingMarketRegionProfile(
      region: EmergingSponsorRegion.fromJson(json['region'] as String),
      subHubs: (json['subHubs'] as List<dynamic>)
          .map((e) => EmergingMarketSubHub.fromJson(e as String))
          .toList(),
      marketGrowthRatePercent:
          (json['marketGrowthRatePercent'] as num).toDouble(),
      mediaBroadcastReachMillions:
          (json['mediaBroadcastReachMillions'] as num).toDouble(),
      baseCommercialMultiplier:
          (json['baseCommercialMultiplier'] as num).toDouble(),
      fanbasePenetration: (json['fanbasePenetration'] as num).toDouble(),
      presenceTier:
          MarketPresenceTier.fromJson(json['presenceTier'] as String),
      linkedExoticTours: (json['linkedExoticTours'] as List<dynamic>)
          .map((e) => ExoticTourId.fromJson(e as String))
          .toList(),
      activeLocalRidersCount: (json['activeLocalRidersCount'] as num).toInt(),
      completedActivationsCount:
          (json['completedActivationsCount'] as num).toInt(),
      isScouted: json['isScouted'] as bool? ?? false,
    );
  }
}

/// Oferta sponsorska z rynku wschodzącego gotowa do negocjacji i podpisania.
class EmergingMarketSponsorOffer {
  final String id;
  final String companyName;
  final String countryName;
  final String countryCode;
  final EmergingSponsorRegion region;
  final EmergingMarketSubHub subHub;
  final EmergingSponsorSector sector;
  final SponsorTier sponsorTier;
  final SponsorIndustry mappedIndustry;
  final int annualBudgetEur;
  final int signingBonusEur;
  final int contractDurationYears;
  final double requiredTeamPrestige;
  final double requiredRegionalPresence;
  final bool requiresLocalRiderInRoster;
  final ExoticTourId? preferredExoticTour;
  final int exoticRaceStageWinBonusEur;
  final double mediaExposureTarget;
  final List<SponsorObjective> objectives;
  final String culturalExpectationsNote;
  final int offerExpiresInDays;
  final bool isNegotiated;
  final double negotiatedBudgetBoostPercent;

  const EmergingMarketSponsorOffer({
    required this.id,
    required this.companyName,
    required this.countryName,
    required this.countryCode,
    required this.region,
    required this.subHub,
    required this.sector,
    required this.sponsorTier,
    required this.mappedIndustry,
    required this.annualBudgetEur,
    required this.signingBonusEur,
    required this.contractDurationYears,
    required this.requiredTeamPrestige,
    required this.requiredRegionalPresence,
    required this.requiresLocalRiderInRoster,
    required this.preferredExoticTour,
    required this.exoticRaceStageWinBonusEur,
    required this.mediaExposureTarget,
    required this.objectives,
    required this.culturalExpectationsNote,
    required this.offerExpiresInDays,
    this.isNegotiated = false,
    this.negotiatedBudgetBoostPercent = 0.0,
  });

  int get effectiveAnnualBudgetEur =>
      (annualBudgetEur * (1.0 + negotiatedBudgetBoostPercent / 100.0)).round();

  int get totalContractValueEur =>
      effectiveAnnualBudgetEur * contractDurationYears + signingBonusEur;

  /// Konwertuje ofertę z rynku wschodzącego na standardowy `SponsorContract`.
  SponsorContract toSponsorContract() {
    return SponsorContract(
      id: id,
      companyName: companyName,
      industry: mappedIndustry,
      sponsorTier: sponsorTier,
      annualBudgetEur: effectiveAnnualBudgetEur,
      contractDurationYears: contractDurationYears,
      sponsorSatisfaction: 78.0,
      objectives: objectives,
    );
  }

  EmergingMarketSponsorOffer copyWith({
    String? id,
    String? companyName,
    String? countryName,
    String? countryCode,
    EmergingSponsorRegion? region,
    EmergingMarketSubHub? subHub,
    EmergingSponsorSector? sector,
    SponsorTier? sponsorTier,
    SponsorIndustry? mappedIndustry,
    int? annualBudgetEur,
    int? signingBonusEur,
    int? contractDurationYears,
    double? requiredTeamPrestige,
    double? requiredRegionalPresence,
    bool? requiresLocalRiderInRoster,
    ExoticTourId? preferredExoticTour,
    int? exoticRaceStageWinBonusEur,
    double? mediaExposureTarget,
    List<SponsorObjective>? objectives,
    String? culturalExpectationsNote,
    int? offerExpiresInDays,
    bool? isNegotiated,
    double? negotiatedBudgetBoostPercent,
  }) {
    return EmergingMarketSponsorOffer(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      countryName: countryName ?? this.countryName,
      countryCode: countryCode ?? this.countryCode,
      region: region ?? this.region,
      subHub: subHub ?? this.subHub,
      sector: sector ?? this.sector,
      sponsorTier: sponsorTier ?? this.sponsorTier,
      mappedIndustry: mappedIndustry ?? this.mappedIndustry,
      annualBudgetEur: annualBudgetEur ?? this.annualBudgetEur,
      signingBonusEur: signingBonusEur ?? this.signingBonusEur,
      contractDurationYears:
          contractDurationYears ?? this.contractDurationYears,
      requiredTeamPrestige: requiredTeamPrestige ?? this.requiredTeamPrestige,
      requiredRegionalPresence:
          requiredRegionalPresence ?? this.requiredRegionalPresence,
      requiresLocalRiderInRoster:
          requiresLocalRiderInRoster ?? this.requiresLocalRiderInRoster,
      preferredExoticTour: preferredExoticTour ?? this.preferredExoticTour,
      exoticRaceStageWinBonusEur:
          exoticRaceStageWinBonusEur ?? this.exoticRaceStageWinBonusEur,
      mediaExposureTarget: mediaExposureTarget ?? this.mediaExposureTarget,
      objectives: objectives ?? this.objectives,
      culturalExpectationsNote:
          culturalExpectationsNote ?? this.culturalExpectationsNote,
      offerExpiresInDays: offerExpiresInDays ?? this.offerExpiresInDays,
      isNegotiated: isNegotiated ?? this.isNegotiated,
      negotiatedBudgetBoostPercent:
          negotiatedBudgetBoostPercent ?? this.negotiatedBudgetBoostPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'countryName': countryName,
      'countryCode': countryCode,
      'region': region.toJson(),
      'subHub': subHub.toJson(),
      'sector': sector.toJson(),
      'sponsorTier': sponsorTier.toJson(),
      'mappedIndustry': mappedIndustry.toJson(),
      'annualBudgetEur': annualBudgetEur,
      'signingBonusEur': signingBonusEur,
      'contractDurationYears': contractDurationYears,
      'requiredTeamPrestige': requiredTeamPrestige,
      'requiredRegionalPresence': requiredRegionalPresence,
      'requiresLocalRiderInRoster': requiresLocalRiderInRoster,
      'preferredExoticTour': preferredExoticTour?.toJson(),
      'exoticRaceStageWinBonusEur': exoticRaceStageWinBonusEur,
      'mediaExposureTarget': mediaExposureTarget,
      'objectives': objectives.map((o) => o.toJson()).toList(),
      'culturalExpectationsNote': culturalExpectationsNote,
      'offerExpiresInDays': offerExpiresInDays,
      'isNegotiated': isNegotiated,
      'negotiatedBudgetBoostPercent': negotiatedBudgetBoostPercent,
    };
  }

  factory EmergingMarketSponsorOffer.fromJson(Map<String, dynamic> json) {
    return EmergingMarketSponsorOffer(
      id: json['id'] as String,
      companyName: json['companyName'] as String,
      countryName: json['countryName'] as String,
      countryCode: json['countryCode'] as String,
      region: EmergingSponsorRegion.fromJson(json['region'] as String),
      subHub: EmergingMarketSubHub.fromJson(json['subHub'] as String),
      sector: EmergingSponsorSector.fromJson(json['sector'] as String),
      sponsorTier: SponsorTier.fromJson(json['sponsorTier'] as String),
      mappedIndustry:
          SponsorIndustry.fromJson(json['mappedIndustry'] as String),
      annualBudgetEur: (json['annualBudgetEur'] as num).toInt(),
      signingBonusEur: (json['signingBonusEur'] as num).toInt(),
      contractDurationYears: (json['contractDurationYears'] as num).toInt(),
      requiredTeamPrestige: (json['requiredTeamPrestige'] as num).toDouble(),
      requiredRegionalPresence:
          (json['requiredRegionalPresence'] as num).toDouble(),
      requiresLocalRiderInRoster:
          json['requiresLocalRiderInRoster'] as bool? ?? false,
      preferredExoticTour: json['preferredExoticTour'] != null
          ? ExoticTourId.fromJson(json['preferredExoticTour'] as String)
          : null,
      exoticRaceStageWinBonusEur:
          (json['exoticRaceStageWinBonusEur'] as num).toInt(),
      mediaExposureTarget: (json['mediaExposureTarget'] as num).toDouble(),
      objectives: (json['objectives'] as List<dynamic>)
          .map((e) => SponsorObjective.fromJson(e as Map<String, dynamic>))
          .toList(),
      culturalExpectationsNote: json['culturalExpectationsNote'] as String,
      offerExpiresInDays: (json['offerExpiresInDays'] as num).toInt(),
      isNegotiated: json['isNegotiated'] as bool? ?? false,
      negotiatedBudgetBoostPercent:
          (json['negotiatedBudgetBoostPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergingMarketSponsorOffer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Aktywnie podpisany kontrakt ze sponsorem z rynku wschodzącego.
class ActiveEmergingSponsorContract {
  final String offerId;
  final SponsorContract contract;
  final EmergingSponsorRegion region;
  final EmergingMarketSubHub subHub;
  final EmergingSponsorSector sector;
  final String countryCode;
  final ExoticTourId? preferredExoticTour;
  final int exoticRaceStageWinBonusEur;
  final double culturalComplianceScore;
  final double regionalMediaExposureEarned;
  final int earnedExoticBonusesEur;
  final int signedAtSeasonDay;
  final int remainingYears;

  const ActiveEmergingSponsorContract({
    required this.offerId,
    required this.contract,
    required this.region,
    required this.subHub,
    required this.sector,
    required this.countryCode,
    required this.preferredExoticTour,
    required this.exoticRaceStageWinBonusEur,
    required this.culturalComplianceScore,
    required this.regionalMediaExposureEarned,
    required this.earnedExoticBonusesEur,
    required this.signedAtSeasonDay,
    required this.remainingYears,
  });

  ActiveEmergingSponsorContract copyWith({
    String? offerId,
    SponsorContract? contract,
    EmergingSponsorRegion? region,
    EmergingMarketSubHub? subHub,
    EmergingSponsorSector? sector,
    String? countryCode,
    ExoticTourId? preferredExoticTour,
    int? exoticRaceStageWinBonusEur,
    double? culturalComplianceScore,
    double? regionalMediaExposureEarned,
    int? earnedExoticBonusesEur,
    int? signedAtSeasonDay,
    int? remainingYears,
  }) {
    return ActiveEmergingSponsorContract(
      offerId: offerId ?? this.offerId,
      contract: contract ?? this.contract,
      region: region ?? this.region,
      subHub: subHub ?? this.subHub,
      sector: sector ?? this.sector,
      countryCode: countryCode ?? this.countryCode,
      preferredExoticTour: preferredExoticTour ?? this.preferredExoticTour,
      exoticRaceStageWinBonusEur:
          exoticRaceStageWinBonusEur ?? this.exoticRaceStageWinBonusEur,
      culturalComplianceScore:
          (culturalComplianceScore ?? this.culturalComplianceScore)
              .clamp(0.0, 100.0),
      regionalMediaExposureEarned:
          regionalMediaExposureEarned ?? this.regionalMediaExposureEarned,
      earnedExoticBonusesEur:
          earnedExoticBonusesEur ?? this.earnedExoticBonusesEur,
      signedAtSeasonDay: signedAtSeasonDay ?? this.signedAtSeasonDay,
      remainingYears: remainingYears ?? this.remainingYears,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'contract': contract.toJson(),
      'region': region.toJson(),
      'subHub': subHub.toJson(),
      'sector': sector.toJson(),
      'countryCode': countryCode,
      'preferredExoticTour': preferredExoticTour?.toJson(),
      'exoticRaceStageWinBonusEur': exoticRaceStageWinBonusEur,
      'culturalComplianceScore': culturalComplianceScore,
      'regionalMediaExposureEarned': regionalMediaExposureEarned,
      'earnedExoticBonusesEur': earnedExoticBonusesEur,
      'signedAtSeasonDay': signedAtSeasonDay,
      'remainingYears': remainingYears,
    };
  }

  factory ActiveEmergingSponsorContract.fromJson(Map<String, dynamic> json) {
    return ActiveEmergingSponsorContract(
      offerId: json['offerId'] as String,
      contract:
          SponsorContract.fromJson(json['contract'] as Map<String, dynamic>),
      region: EmergingSponsorRegion.fromJson(json['region'] as String),
      subHub: EmergingMarketSubHub.fromJson(json['subHub'] as String),
      sector: EmergingSponsorSector.fromJson(json['sector'] as String),
      countryCode: json['countryCode'] as String,
      preferredExoticTour: json['preferredExoticTour'] != null
          ? ExoticTourId.fromJson(json['preferredExoticTour'] as String)
          : null,
      exoticRaceStageWinBonusEur:
          (json['exoticRaceStageWinBonusEur'] as num).toInt(),
      culturalComplianceScore:
          (json['culturalComplianceScore'] as num).toDouble(),
      regionalMediaExposureEarned:
          (json['regionalMediaExposureEarned'] as num).toDouble(),
      earnedExoticBonusesEur: (json['earnedExoticBonusesEur'] as num).toInt(),
      signedAtSeasonDay: (json['signedAtSeasonDay'] as num).toInt(),
      remainingYears: (json['remainingYears'] as num).toInt(),
    );
  }
}

/// Regionalna misja aktywacji budująca obecność na rynku wschodzącym.
class RegionalActivationMission {
  final String id;
  final String title;
  final String description;
  final EmergingSponsorRegion region;
  final RegionalActivationType type;
  final int costEur;
  final int durationDays;
  final double presenceGain;
  final double satisfactionGain;
  final double commercialMultiplierBoost;
  final bool isCompleted;
  final bool isInProgress;
  final int daysRemaining;

  const RegionalActivationMission({
    required this.id,
    required this.title,
    required this.description,
    required this.region,
    required this.type,
    required this.costEur,
    required this.durationDays,
    required this.presenceGain,
    required this.satisfactionGain,
    required this.commercialMultiplierBoost,
    this.isCompleted = false,
    this.isInProgress = false,
    this.daysRemaining = 0,
  });

  RegionalActivationMission copyWith({
    String? id,
    String? title,
    String? description,
    EmergingSponsorRegion? region,
    RegionalActivationType? type,
    int? costEur,
    int? durationDays,
    double? presenceGain,
    double? satisfactionGain,
    double? commercialMultiplierBoost,
    bool? isCompleted,
    bool? isInProgress,
    int? daysRemaining,
  }) {
    return RegionalActivationMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      region: region ?? this.region,
      type: type ?? this.type,
      costEur: costEur ?? this.costEur,
      durationDays: durationDays ?? this.durationDays,
      presenceGain: presenceGain ?? this.presenceGain,
      satisfactionGain: satisfactionGain ?? this.satisfactionGain,
      commercialMultiplierBoost:
          commercialMultiplierBoost ?? this.commercialMultiplierBoost,
      isCompleted: isCompleted ?? this.isCompleted,
      isInProgress: isInProgress ?? this.isInProgress,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'region': region.toJson(),
      'type': type.toJson(),
      'costEur': costEur,
      'durationDays': durationDays,
      'presenceGain': presenceGain,
      'satisfactionGain': satisfactionGain,
      'commercialMultiplierBoost': commercialMultiplierBoost,
      'isCompleted': isCompleted,
      'isInProgress': isInProgress,
      'daysRemaining': daysRemaining,
    };
  }

  factory RegionalActivationMission.fromJson(Map<String, dynamic> json) {
    return RegionalActivationMission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      region: EmergingSponsorRegion.fromJson(json['region'] as String),
      type: RegionalActivationType.fromJson(json['type'] as String),
      costEur: (json['costEur'] as num).toInt(),
      durationDays: (json['durationDays'] as num).toInt(),
      presenceGain: (json['presenceGain'] as num).toDouble(),
      satisfactionGain: (json['satisfactionGain'] as num).toDouble(),
      commercialMultiplierBoost:
          (json['commercialMultiplierBoost'] as num).toDouble(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isInProgress: json['isInProgress'] as bool? ?? false,
      daysRemaining: (json['daysRemaining'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Raport kwalifikacji zespołu do podpisania oferty z rynku wschodzącego.
class OfferEligibilityReport {
  final bool isEligible;
  final List<String> unmetReasons;

  const OfferEligibilityReport({
    required this.isEligible,
    required this.unmetReasons,
  });
}

/// Wynik negocjacji kontraktu z wybranym sponsorem.
class EmergingMarketNegotiationResult {
  final SponsorNegotiationOutcomeStatus status;
  final String message;
  final int proposedAnnualBudgetEur;
  final double acceptanceProbability;
  final ActiveEmergingSponsorContract? signedContract;

  const EmergingMarketNegotiationResult({
    required this.status,
    required this.message,
    required this.proposedAnnualBudgetEur,
    required this.acceptanceProbability,
    this.signedContract,
  });
}

/// Zbiorcze podsumowanie portfela sponsorów z rynków wschodzących.
class GlobalSponsorMarketSummary {
  final int totalEmergingAnnualRevenueEur;
  final int totalEarnedBonusesEur;
  final int activeContractsCount;
  final double averageSatisfaction;
  final double globalExpansionIndex;
  final EmergingSponsorRegion? strongestRegion;
  final Map<EmergingSponsorRegion, int> revenueByRegion;

  const GlobalSponsorMarketSummary({
    required this.totalEmergingAnnualRevenueEur,
    required this.totalEarnedBonusesEur,
    required this.activeContractsCount,
    required this.averageSatisfaction,
    required this.globalExpansionIndex,
    required this.strongestRegion,
    required this.revenueByRegion,
  });
}

/// Główny serwis logiki biznesowej systemu sponsorów z rynków wschodzących
/// (Azja, Afryka, Bliski Wschód).
class GlobalSponsorMarketExpansionService {
  const GlobalSponsorMarketExpansionService();

  static const int maxActiveEmergingContracts = 4;
  static const int scoutingMissionCostEur = 45000;

  /// Buduje domyślne profile wszystkich 3 rynków wschodzących.
  Map<EmergingSponsorRegion, EmergingMarketRegionProfile>
      buildDefaultRegionProfiles() {
    return {
      EmergingSponsorRegion.asia: const EmergingMarketRegionProfile(
        region: EmergingSponsorRegion.asia,
        subHubs: [
          EmergingMarketSubHub.southeastAsia,
          EmergingMarketSubHub.eastAndCentralAsia,
        ],
        marketGrowthRatePercent: 18.4,
        mediaBroadcastReachMillions: 142.5,
        baseCommercialMultiplier: 1.08,
        fanbasePenetration: 16.0,
        presenceTier: MarketPresenceTier.scouting,
        linkedExoticTours: [ExoticTourId.tourDeLangkawi],
        activeLocalRidersCount: 1,
        completedActivationsCount: 0,
        isScouted: true,
      ),
      EmergingSponsorRegion.africa: const EmergingMarketRegionProfile(
        region: EmergingSponsorRegion.africa,
        subHubs: [
          EmergingMarketSubHub.eastAfrica,
          EmergingMarketSubHub.southernAndNorthAfrica,
        ],
        marketGrowthRatePercent: 26.2,
        mediaBroadcastReachMillions: 68.0,
        baseCommercialMultiplier: 1.04,
        fanbasePenetration: 12.0,
        presenceTier: MarketPresenceTier.scouting,
        linkedExoticTours: [ExoticTourId.tourDuRwanda],
        activeLocalRidersCount: 0,
        completedActivationsCount: 0,
        isScouted: true,
      ),
      EmergingSponsorRegion.middleEast: const EmergingMarketRegionProfile(
        region: EmergingSponsorRegion.middleEast,
        subHubs: [EmergingMarketSubHub.gulfCooperationCouncil],
        marketGrowthRatePercent: 22.8,
        mediaBroadcastReachMillions: 94.0,
        baseCommercialMultiplier: 1.24,
        fanbasePenetration: 8.0,
        presenceTier: MarketPresenceTier.unexplored,
        linkedExoticTours: [
          ExoticTourId.tourOfOman,
          ExoticTourId.alUlaTour,
        ],
        activeLocalRidersCount: 0,
        completedActivationsCount: 0,
        isScouted: false,
      ),
    };
  }

  /// Generuje katalog ofert sponsorskich z rynków wschodzących.
  List<EmergingMarketSponsorOffer> generateMarketOffers({
    required double teamPrestige,
    required Map<EmergingSponsorRegion, EmergingMarketRegionProfile>
        regionProfiles,
  }) {
    final asiaMult =
        regionProfiles[EmergingSponsorRegion.asia]?.effectiveCommercialMultiplier ??
            1.08;
    final africaMult = regionProfiles[EmergingSponsorRegion.africa]
            ?.effectiveCommercialMultiplier ??
        1.04;
    final middleEastMult = regionProfiles[EmergingSponsorRegion.middleEast]
            ?.effectiveCommercialMultiplier ??
        1.24;

    final prestigeScale = (0.85 + (teamPrestige.clamp(0.0, 100.0) / 100.0) * 0.45);

    int scaledBudget(int baseEur, double regionMult) {
      final raw = baseEur * regionMult * prestigeScale;
      return ((raw / 5000).round() * 5000).clamp(50000, 18000000);
    }

    return [
      // AZJA
      EmergingMarketSponsorOffer(
        id: 'emg_asia_petronas_green',
        companyName: 'Petronas Green Mobility',
        countryName: 'Malezja',
        countryCode: 'MY',
        region: EmergingSponsorRegion.asia,
        subHub: EmergingMarketSubHub.southeastAsia,
        sector: EmergingSponsorSector.cleanEnergyAndAviation,
        sponsorTier: SponsorTier.titleSecondary,
        mappedIndustry: SponsorIndustry.energy,
        annualBudgetEur: scaledBudget(1850000, asiaMult),
        signingBonusEur: 240000,
        contractDurationYears: 2,
        requiredTeamPrestige: 52.0,
        requiredRegionalPresence: 15.0,
        requiresLocalRiderInRoster: false,
        preferredExoticTour: ExoticTourId.tourDeLangkawi,
        exoticRaceStageWinBonusEur: 75000,
        mediaExposureTarget: 42.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_langkawi_top5',
            description: 'Zajmij miejsce w Top 5 GC na Tour de Langkawi',
            bonusPaymentEur: 140000,
            importance: ObjectiveImportance.high,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
          SponsorObjective(
            id: 'obj_asia_sprint',
            description: 'Wygraj etap sprinterski w Azji lub ProSeries',
            bonusPaymentEur: 85000,
            importance: ObjectiveImportance.medium,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
        ],
        culturalExpectationsNote:
            'Priorytet: obecność medialna w Kuala Lumpur i promocja zeroemisyjnej floty.',
        offerExpiresInDays: 28,
      ),
      EmergingMarketSponsorOffer(
        id: 'emg_asia_rakuten_fintech',
        companyName: 'Rakuten Pay APAC',
        countryName: 'Japonia',
        countryCode: 'JP',
        region: EmergingSponsorRegion.asia,
        subHub: EmergingMarketSubHub.eastAndCentralAsia,
        sector: EmergingSponsorSector.telecomAndFintech,
        sponsorTier: SponsorTier.majorPartner,
        mappedIndustry: SponsorIndustry.tech,
        annualBudgetEur: scaledBudget(1150000, asiaMult),
        signingBonusEur: 125000,
        contractDurationYears: 2,
        requiredTeamPrestige: 44.0,
        requiredRegionalPresence: 10.0,
        requiresLocalRiderInRoster: false,
        preferredExoticTour: ExoticTourId.tourDeLangkawi,
        exoticRaceStageWinBonusEur: 50000,
        mediaExposureTarget: 35.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_asia_media',
            description: 'Osiągnij 35 pkt ekspozycji medialnej w regionie APAC',
            bonusPaymentEur: 95000,
            importance: ObjectiveImportance.medium,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 35,
          ),
        ],
        culturalExpectationsNote:
            'Kultura precyzji i danych: nacisk na regularne raporty telemetrii oraz brak kar sędziowskich.',
        offerExpiresInDays: 35,
      ),
      EmergingMarketSponsorOffer(
        id: 'emg_asia_shimano_asia',
        companyName: 'Shimano APAC Performance',
        countryName: 'Singapur',
        countryCode: 'SG',
        region: EmergingSponsorRegion.asia,
        subHub: EmergingMarketSubHub.southeastAsia,
        sector: EmergingSponsorSector.techAndMobility,
        sponsorTier: SponsorTier.technicalSupplier,
        mappedIndustry: SponsorIndustry.apparel,
        annualBudgetEur: scaledBudget(740000, asiaMult),
        signingBonusEur: 80000,
        contractDurationYears: 3,
        requiredTeamPrestige: 35.0,
        requiredRegionalPresence: 5.0,
        requiresLocalRiderInRoster: false,
        preferredExoticTour: null,
        exoticRaceStageWinBonusEur: 35000,
        mediaExposureTarget: 24.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_asia_tech_podium',
            description: 'Zdobądź 3 miejsca na podium etapów w sezonie',
            bonusPaymentEur: 65000,
            importance: ObjectiveImportance.low,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 3,
          ),
        ],
        culturalExpectationsNote:
            'Dostawca komponentów i wsparcie serwisowe na wyścigach pozaeuropejskich.',
        offerExpiresInDays: 42,
      ),

      // AFRYKA
      EmergingMarketSponsorOffer(
        id: 'emg_africa_visit_rwanda',
        companyName: 'Visit Rwanda Horizons',
        countryName: 'Rwanda',
        countryCode: 'RW',
        region: EmergingSponsorRegion.africa,
        subHub: EmergingMarketSubHub.eastAfrica,
        sector: EmergingSponsorSector.sovereignTourism,
        sponsorTier: SponsorTier.titleSecondary,
        mappedIndustry: SponsorIndustry.airlines,
        annualBudgetEur: scaledBudget(1450000, africaMult),
        signingBonusEur: 190000,
        contractDurationYears: 3,
        requiredTeamPrestige: 48.0,
        requiredRegionalPresence: 12.0,
        requiresLocalRiderInRoster: false,
        preferredExoticTour: ExoticTourId.tourDuRwanda,
        exoticRaceStageWinBonusEur: 70000,
        mediaExposureTarget: 40.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_rwanda_mur_kigali',
            description: 'Wygraj etap z podjazdem na Mur de Kigali w Tour du Rwanda',
            bonusPaymentEur: 130000,
            importance: ObjectiveImportance.critical,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
          SponsorObjective(
            id: 'obj_africa_academy',
            description: 'Zrealizuj 1 misję rozwoju talentów w Afryce Wschodniej',
            bonusPaymentEur: 60000,
            importance: ObjectiveImportance.medium,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
        ],
        culturalExpectationsNote:
            'Kluczowa widoczność logo na rękawku koszulki oraz zaangażowanie w rozwój kolarstwa w Kigali.',
        offerExpiresInDays: 30,
      ),
      EmergingMarketSponsorOffer(
        id: 'emg_africa_mtn_qhubeka',
        companyName: 'MTN Qhubeka Connect',
        countryName: 'RPA',
        countryCode: 'ZA',
        region: EmergingSponsorRegion.africa,
        subHub: EmergingMarketSubHub.southernAndNorthAfrica,
        sector: EmergingSponsorSector.telecomAndFintech,
        sponsorTier: SponsorTier.majorPartner,
        mappedIndustry: SponsorIndustry.tech,
        annualBudgetEur: scaledBudget(960000, africaMult),
        signingBonusEur: 110000,
        contractDurationYears: 2,
        requiredTeamPrestige: 38.0,
        requiredRegionalPresence: 8.0,
        requiresLocalRiderInRoster: true,
        preferredExoticTour: ExoticTourId.tourDuRwanda,
        exoticRaceStageWinBonusEur: 45000,
        mediaExposureTarget: 28.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_africa_breakaway',
            description: 'Przejedź 400 km w ucieczkach w wyścigach UCI',
            bonusPaymentEur: 75000,
            importance: ObjectiveImportance.medium,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 400,
          ),
        ],
        culturalExpectationsNote:
            'Wymaga przynajmniej 1 kolarza z Afryki w kadrze oraz aktywnej jazdy w odjazdach.',
        offerExpiresInDays: 25,
      ),

      // BLISKI WSCHÓD
      EmergingMarketSponsorOffer(
        id: 'emg_me_alula_heritage',
        companyName: 'AlUla Heritage Authority',
        countryName: 'Arabia Saudyjska',
        countryCode: 'SA',
        region: EmergingSponsorRegion.middleEast,
        subHub: EmergingMarketSubHub.gulfCooperationCouncil,
        sector: EmergingSponsorSector.sovereignTourism,
        sponsorTier: SponsorTier.titlePrimary,
        mappedIndustry: SponsorIndustry.finance,
        annualBudgetEur: scaledBudget(3400000, middleEastMult),
        signingBonusEur: 550000,
        contractDurationYears: 3,
        requiredTeamPrestige: 68.0,
        requiredRegionalPresence: 25.0,
        requiresLocalRiderInRoster: false,
        preferredExoticTour: ExoticTourId.alUlaTour,
        exoticRaceStageWinBonusEur: 150000,
        mediaExposureTarget: 65.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_alula_gc_win',
            description: 'Wygraj klasyfikację generalną lub etap królewski AlUla Tour',
            bonusPaymentEur: 320000,
            importance: ObjectiveImportance.critical,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
          SponsorObjective(
            id: 'obj_me_gt_top10',
            description: 'Zajmij Top 10 w klasyfikacji generalnej Grand Tour',
            bonusPaymentEur: 280000,
            importance: ObjectiveImportance.high,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
        ],
        culturalExpectationsNote:
            'Najwyższy budżet w regionie Zatoki. Wymaga pełnej obecności VIP na AlUla Tour i wysokiego prestiżu drużyny.',
        offerExpiresInDays: 21,
      ),
      EmergingMarketSponsorOffer(
        id: 'emg_me_oman_energy',
        companyName: 'Oman Hydrogen Ventures',
        countryName: 'Oman',
        countryCode: 'OM',
        region: EmergingSponsorRegion.middleEast,
        subHub: EmergingMarketSubHub.gulfCooperationCouncil,
        sector: EmergingSponsorSector.cleanEnergyAndAviation,
        sponsorTier: SponsorTier.majorPartner,
        mappedIndustry: SponsorIndustry.energy,
        annualBudgetEur: scaledBudget(1650000, middleEastMult),
        signingBonusEur: 210000,
        contractDurationYears: 2,
        requiredTeamPrestige: 50.0,
        requiredRegionalPresence: 10.0,
        requiresLocalRiderInRoster: false,
        preferredExoticTour: ExoticTourId.tourOfOman,
        exoticRaceStageWinBonusEur: 85000,
        mediaExposureTarget: 45.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_oman_green_mountain',
            description: 'Zdobądź podium na etapie Green Mountain w Tour of Oman',
            bonusPaymentEur: 160000,
            importance: ObjectiveImportance.high,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
        ],
        culturalExpectationsNote:
            'Silny nacisk na wspinaczkę na Jabal Al Akhdhar oraz zrównoważony wizerunek energetyczny.',
        offerExpiresInDays: 32,
      ),
      EmergingMarketSponsorOffer(
        id: 'emg_me_dp_world_logistics',
        companyName: 'DP World Express Cargo',
        countryName: 'ZEA',
        countryCode: 'AE',
        region: EmergingSponsorRegion.middleEast,
        subHub: EmergingMarketSubHub.gulfCooperationCouncil,
        sector: EmergingSponsorSector.miningAndLogistics,
        sponsorTier: SponsorTier.majorPartner,
        mappedIndustry: SponsorIndustry.automotive,
        annualBudgetEur: scaledBudget(1380000, middleEastMult),
        signingBonusEur: 160000,
        contractDurationYears: 2,
        requiredTeamPrestige: 46.0,
        requiredRegionalPresence: 5.0,
        requiresLocalRiderInRoster: false,
        preferredExoticTour: ExoticTourId.tourOfOman,
        exoticRaceStageWinBonusEur: 60000,
        mediaExposureTarget: 38.0,
        objectives: const [
          SponsorObjective(
            id: 'obj_me_ttt_echelon',
            description: 'Ukończ w Top 5 na wietrznym etapie lub TTT w Zatoce',
            bonusPaymentEur: 110000,
            importance: ObjectiveImportance.medium,
            isCompleted: false,
            currentProgress: 0,
            targetProgress: 1,
          ),
        ],
        culturalExpectationsNote:
            'Partner logistyczny zapewniający redukcję kosztów transportu sprzętu na wyścigi zamorskie.',
        offerExpiresInDays: 38,
      ),
    ];
  }

  /// Tworzy domyślną listę misji aktywacyjnych w 3 regionach.
  List<RegionalActivationMission> buildDefaultActivationMissions() {
    return const [
      RegionalActivationMission(
        id: 'act_asia_kl_summit',
        title: 'Szczyt Biznesowy w Kuala Lumpur',
        description:
            'Spotkanie z zarządami firm APAC i prezentacja stroju przed Tour de Langkawi.',
        region: EmergingSponsorRegion.asia,
        type: RegionalActivationType.hospitalityAndVipSummit,
        costEur: 60000,
        durationDays: 7,
        presenceGain: 14.0,
        satisfactionGain: 6.0,
        commercialMultiplierBoost: 0.05,
      ),
      RegionalActivationMission(
        id: 'act_asia_talent_camp',
        title: 'Obóz Skautingowy Azja Płd.-Wsch.',
        description:
            'Testy wydolnościowe VO2max dla 12 młodych kolarzy z Malezji, Japonii i Indonezji.',
        region: EmergingSponsorRegion.asia,
        type: RegionalActivationType.localTalentDevelopmentCamp,
        costEur: 85000,
        durationDays: 10,
        presenceGain: 18.0,
        satisfactionGain: 8.0,
        commercialMultiplierBoost: 0.07,
      ),
      RegionalActivationMission(
        id: 'act_africa_kigali_academy',
        title: 'Grant Akademii Kolarskiej w Kigali',
        description:
            'Wsparcie sprzętowe lokalnego centrum treningowego na wysokości 1500 m n.p.m.',
        region: EmergingSponsorRegion.africa,
        type: RegionalActivationType.youthCyclingAcademyGrant,
        costEur: 55000,
        durationDays: 8,
        presenceGain: 16.0,
        satisfactionGain: 9.0,
        commercialMultiplierBoost: 0.06,
      ),
      RegionalActivationMission(
        id: 'act_africa_jersey_patch',
        title: 'Lokalizacja Stroju & Kampania East Africa',
        description:
            'Specjalna edycja koszulki na Tour du Rwanda zwiększająca zasięg medialny o 25%.',
        region: EmergingSponsorRegion.africa,
        type: RegionalActivationType.jerseyLocalizationPatch,
        costEur: 40000,
        durationDays: 5,
        presenceGain: 12.0,
        satisfactionGain: 5.5,
        commercialMultiplierBoost: 0.04,
      ),
      RegionalActivationMission(
        id: 'act_me_alula_wildcard',
        title: 'Delegacja & Obóz Aklimatyzacyjny AlUla',
        description:
            'Oficjalna delegacja zespołu na Bliski Wschód otwierająca rozmowy z funduszami Zatoki.',
        region: EmergingSponsorRegion.middleEast,
        type: RegionalActivationType.exoticTourWildcardStart,
        costEur: 95000,
        durationDays: 9,
        presenceGain: 20.0,
        satisfactionGain: 7.5,
        commercialMultiplierBoost: 0.08,
      ),
      RegionalActivationMission(
        id: 'act_me_dubai_vip',
        title: 'Forum Inwestorskie Zatoki Perskiej',
        description:
            'Prezentacja celów Grand Tour dla partnerów z ZEA, Omanu i Arabii Saudyjskiej.',
        region: EmergingSponsorRegion.middleEast,
        type: RegionalActivationType.hospitalityAndVipSummit,
        costEur: 110000,
        durationDays: 6,
        presenceGain: 17.0,
        satisfactionGain: 8.5,
        commercialMultiplierBoost: 0.07,
      ),
    ];
  }

  /// Sprawdza, czy zespół spełnia wymagania do podpisania danej oferty.
  OfferEligibilityReport evaluateOfferEligibility({
    required EmergingMarketSponsorOffer offer,
    required double teamPrestige,
    required EmergingMarketRegionProfile regionProfile,
    required int activeContractsCount,
    required bool alreadySignedOffer,
  }) {
    final reasons = <String>[];

    if (alreadySignedOffer) {
      reasons.add('Ten sponsor jest już zakontraktowany.');
    }
    if (activeContractsCount >= maxActiveEmergingContracts) {
      reasons.add(
        'Osiągnięto limit $maxActiveEmergingContracts aktywnych sponsorów z rynków wschodzących.',
      );
    }
    if (!regionProfile.isScouted) {
      reasons.add('Rynek ${offer.region.label} wymaga najpierw rozpoznania.');
    }
    if (teamPrestige < offer.requiredTeamPrestige) {
      reasons.add(
        'Wymagany prestiż zespołu: ${offer.requiredTeamPrestige.toStringAsFixed(0)} '
        '(obecnie ${teamPrestige.toStringAsFixed(0)}).',
      );
    }
    if (regionProfile.fanbasePenetration < offer.requiredRegionalPresence) {
      reasons.add(
        'Wymagana obecność w regionie: ${offer.requiredRegionalPresence.toStringAsFixed(0)}% '
        '(obecnie ${regionProfile.fanbasePenetration.toStringAsFixed(0)}%).',
      );
    }
    if (offer.requiresLocalRiderInRoster &&
        regionProfile.activeLocalRidersCount <= 0) {
      reasons.add(
        'Wymagany min. 1 kolarz z regionu ${offer.region.label} w składzie.',
      );
    }

    return OfferEligibilityReport(
      isEligible: reasons.isEmpty,
      unmetReasons: reasons,
    );
  }

  /// Oblicza szansę powodzenia negocjacji (0.05 – 0.96) dla zadanego żądania podwyżki %.
  double computeNegotiationAcceptanceProbability({
    required EmergingMarketSponsorOffer offer,
    required double requestedBudgetBoostPercent,
    required double teamPrestige,
    required EmergingMarketRegionProfile regionProfile,
  }) {
    final safeBoost = requestedBudgetBoostPercent.clamp(0.0, 25.0);
    final prestigeBuffer =
        ((teamPrestige - offer.requiredTeamPrestige) * 0.008).clamp(-0.15, 0.22);
    final presenceBuffer =
        ((regionProfile.fanbasePenetration - offer.requiredRegionalPresence) *
                0.006)
            .clamp(-0.10, 0.18);
    final localRiderBonus =
        regionProfile.activeLocalRidersCount > 0 ? 0.07 : 0.0;

    final penalty = (safeBoost / 25.0) * 0.58;
    final raw = 0.88 + prestigeBuffer + presenceBuffer + localRiderBonus - penalty;
    return raw.clamp(0.05, 0.96);
  }

  /// Przeprowadza deterministyczne lub losowe negocjacje oferty z rynku wschodzącego.
  EmergingMarketNegotiationResult negotiateOffer({
    required EmergingMarketSponsorOffer offer,
    required double requestedBudgetBoostPercent,
    required double teamPrestige,
    required EmergingMarketRegionProfile regionProfile,
    required int activeContractsCount,
    required bool alreadySignedOffer,
    required int currentSeasonDay,
    math.Random? rng,
  }) {
    final eligibility = evaluateOfferEligibility(
      offer: offer,
      teamPrestige: teamPrestige,
      regionProfile: regionProfile,
      activeContractsCount: activeContractsCount,
      alreadySignedOffer: alreadySignedOffer,
    );

    if (!eligibility.isEligible) {
      final status = alreadySignedOffer
          ? SponsorNegotiationOutcomeStatus.alreadySigned
          : SponsorNegotiationOutcomeStatus.insufficientPrestige;
      return EmergingMarketNegotiationResult(
        status: status,
        message: eligibility.unmetReasons.first,
        proposedAnnualBudgetEur: offer.effectiveAnnualBudgetEur,
        acceptanceProbability: 0.0,
      );
    }

    final safeBoost = requestedBudgetBoostPercent.clamp(0.0, 25.0);
    final probability = computeNegotiationAcceptanceProbability(
      offer: offer,
      requestedBudgetBoostPercent: safeBoost,
      teamPrestige: teamPrestige,
      regionProfile: regionProfile,
    );

    final proposedBudget =
        (offer.annualBudgetEur * (1.0 + safeBoost / 100.0)).round();
    final roll = (rng ?? math.Random()).nextDouble();

    if (roll <= probability) {
      final updatedOffer = offer.copyWith(
        isNegotiated: true,
        negotiatedBudgetBoostPercent: safeBoost,
      );
      final signed = buildSignedContract(
        offer: updatedOffer,
        currentSeasonDay: currentSeasonDay,
      );
      return EmergingMarketNegotiationResult(
        status: SponsorNegotiationOutcomeStatus.accepted,
        message:
            'Zarząd ${offer.companyName} zaakceptował warunki (${Formatters.formatCurrency(proposedBudget)}/rok)!',
        proposedAnnualBudgetEur: proposedBudget,
        acceptanceProbability: probability,
        signedContract: signed,
      );
    }

    if (roll <= (probability + 0.24).clamp(0.0, 0.98)) {
      final counterBoost = (safeBoost * 0.5).clamp(0.0, 12.5);
      final counterBudget =
          (offer.annualBudgetEur * (1.0 + counterBoost / 100.0)).round();
      return EmergingMarketNegotiationResult(
        status: SponsorNegotiationOutcomeStatus.counterOffer,
        message:
            'Kontroferta ${offer.companyName}: proponują ${Formatters.formatCurrency(counterBudget)}/rok (+${counterBoost.toStringAsFixed(1)}%).',
        proposedAnnualBudgetEur: counterBudget,
        acceptanceProbability: probability,
      );
    }

    return EmergingMarketNegotiationResult(
      status: SponsorNegotiationOutcomeStatus.rejected,
      message:
          '${offer.companyName} odrzuciło żądanie +${safeBoost.toStringAsFixed(0)}%. Obniż oczekiwania lub wzmocnij obecność w regionie.',
      proposedAnnualBudgetEur: offer.effectiveAnnualBudgetEur,
      acceptanceProbability: probability,
    );
  }

  /// Tworzy aktywny kontrakt sponsorski na podstawie zaakceptowanej oferty.
  ActiveEmergingSponsorContract buildSignedContract({
    required EmergingMarketSponsorOffer offer,
    required int currentSeasonDay,
  }) {
    return ActiveEmergingSponsorContract(
      offerId: offer.id,
      contract: offer.toSponsorContract(),
      region: offer.region,
      subHub: offer.subHub,
      sector: offer.sector,
      countryCode: offer.countryCode,
      preferredExoticTour: offer.preferredExoticTour,
      exoticRaceStageWinBonusEur: offer.exoticRaceStageWinBonusEur,
      culturalComplianceScore: 80.0,
      regionalMediaExposureEarned: 0.0,
      earnedExoticBonusesEur: 0,
      signedAtSeasonDay: currentSeasonDay,
      remainingYears: offer.contractDurationYears,
    );
  }

  /// Rejestruje wynik sportowy w wyścigu pozaeuropejskim i aktualizuje kontrakty oraz region.
  ({
    EmergingMarketRegionProfile updatedRegion,
    List<ActiveEmergingSponsorContract> updatedContracts,
    int totalBonusAwardedEur,
  }) recordExoticTourResult({
    required ExoticTourId tourId,
    required int stageWins,
    required int bestGcRank,
    required EmergingMarketRegionProfile regionProfile,
    required List<ActiveEmergingSponsorContract> contracts,
  }) {
    final safeStageWins = stageWins < 0 ? 0 : stageWins;
    final safeGcRank = bestGcRank < 1 ? 1 : bestGcRank;

    final gcPresenceGain = safeGcRank <= 3
        ? 11.0
        : (safeGcRank <= 10 ? 6.5 : 3.0);
    final presenceGain = gcPresenceGain + safeStageWins * 4.0;
    final mediaGain = 10.0 + safeStageWins * 6.0 + (safeGcRank <= 5 ? 8.0 : 2.0);

    final updatedRegion = regionProfile.copyWith(
      fanbasePenetration: regionProfile.fanbasePenetration + presenceGain,
      isScouted: true,
    );

    int totalBonusAwardedEur = 0;
    final updatedContracts = <ActiveEmergingSponsorContract>[];

    for (final active in contracts) {
      if (active.region != regionProfile.region) {
        updatedContracts.add(active);
        continue;
      }

      final matchesPreferredTour = active.preferredExoticTour == tourId;
      final stageBonus = matchesPreferredTour
          ? safeStageWins * active.exoticRaceStageWinBonusEur
          : 0;
      totalBonusAwardedEur += stageBonus;

      final satisfactionBoost =
          (matchesPreferredTour ? 6.5 : 3.0) + safeStageWins * 2.5;

      final updatedObjectives = active.contract.objectives.map((obj) {
        if (obj.isCompleted) return obj;
        if (tourId == ExoticTourId.tourDeLangkawi &&
            obj.id == 'obj_langkawi_top5' &&
            safeGcRank <= 5) {
          totalBonusAwardedEur += obj.bonusPaymentEur;
          return obj.copyWith(isCompleted: true, currentProgress: 1);
        }
        if (tourId == ExoticTourId.tourDuRwanda &&
            obj.id == 'obj_rwanda_mur_kigali' &&
            safeStageWins > 0) {
          totalBonusAwardedEur += obj.bonusPaymentEur;
          return obj.copyWith(isCompleted: true, currentProgress: 1);
        }
        if (tourId == ExoticTourId.alUlaTour &&
            obj.id == 'obj_alula_gc_win' &&
            (safeGcRank == 1 || safeStageWins > 0)) {
          totalBonusAwardedEur += obj.bonusPaymentEur;
          return obj.copyWith(isCompleted: true, currentProgress: 1);
        }
        if (tourId == ExoticTourId.tourOfOman &&
            obj.id == 'obj_oman_green_mountain' &&
            (safeGcRank <= 3 || safeStageWins > 0)) {
          totalBonusAwardedEur += obj.bonusPaymentEur;
          return obj.copyWith(isCompleted: true, currentProgress: 1);
        }
        return obj;
      }).toList();

      updatedContracts.add(
        active.copyWith(
          contract: active.contract.copyWith(
            sponsorSatisfaction:
                (active.contract.sponsorSatisfaction + satisfactionBoost)
                    .clamp(0.0, 100.0),
            objectives: updatedObjectives,
          ),
          culturalComplianceScore: active.culturalComplianceScore + 4.0,
          regionalMediaExposureEarned:
              active.regionalMediaExposureEarned + mediaGain,
          earnedExoticBonusesEur: active.earnedExoticBonusesEur + stageBonus,
        ),
      );
    }

    return (
      updatedRegion: updatedRegion,
      updatedContracts: updatedContracts,
      totalBonusAwardedEur: totalBonusAwardedEur,
    );
  }

  /// Wylicza zbiorcze podsumowanie ekspansji sponsorskiej na rynkach wschodzących.
  GlobalSponsorMarketSummary computeMarketSummary({
    required Map<EmergingSponsorRegion, EmergingMarketRegionProfile>
        regionProfiles,
    required List<ActiveEmergingSponsorContract> activeContracts,
  }) {
    final revenueByRegion = <EmergingSponsorRegion, int>{
      for (final region in EmergingSponsorRegion.values) region: 0,
    };

    int totalAnnualRevenue = 0;
    int totalBonuses = 0;
    double satisfactionSum = 0.0;

    for (final item in activeContracts) {
      totalAnnualRevenue += item.contract.annualBudgetEur;
      totalBonuses +=
          item.earnedExoticBonusesEur + item.contract.totalEarnedBonusesEur;
      satisfactionSum += item.contract.sponsorSatisfaction;
      revenueByRegion[item.region] =
          (revenueByRegion[item.region] ?? 0) + item.contract.annualBudgetEur;
    }

    final avgSatisfaction = activeContracts.isEmpty
        ? 0.0
        : (satisfactionSum / activeContracts.length).clamp(0.0, 100.0);

    double avgPenetration = 0.0;
    EmergingSponsorRegion? strongest;
    double bestPenetration = -1.0;

    for (final profile in regionProfiles.values) {
      avgPenetration += profile.fanbasePenetration;
      if (profile.fanbasePenetration > bestPenetration) {
        bestPenetration = profile.fanbasePenetration;
        strongest = profile.region;
      }
    }
    if (regionProfiles.isNotEmpty) {
      avgPenetration /= regionProfiles.length;
    }

    final expansionIndex =
        (avgPenetration * 0.65 + (activeContracts.length / maxActiveEmergingContracts) * 35.0)
            .clamp(0.0, 100.0);

    return GlobalSponsorMarketSummary(
      totalEmergingAnnualRevenueEur: totalAnnualRevenue,
      totalEarnedBonusesEur: totalBonuses,
      activeContractsCount: activeContracts.length,
      averageSatisfaction: avgSatisfaction,
      globalExpansionIndex: expansionIndex,
      strongestRegion: strongest,
      revenueByRegion: revenueByRegion,
    );
  }
}

/// Stan modułu ekspansji sponsorów z rynków wschodzących zarządzany przez Riverpod.
class GlobalSponsorMarketState {
  final double teamPrestige;
  final int teamAvailableBudgetEur;
  final int currentSeasonDay;
  final EmergingSponsorRegion selectedRegion;
  final EmergingSponsorSector? filterSector;
  final Map<EmergingSponsorRegion, EmergingMarketRegionProfile> regionProfiles;
  final List<EmergingMarketSponsorOffer> availableOffers;
  final List<ActiveEmergingSponsorContract> activeContracts;
  final List<RegionalActivationMission> activationMissions;
  final String? lastActionBanner;
  final bool lastActionIsError;

  const GlobalSponsorMarketState({
    required this.teamPrestige,
    required this.teamAvailableBudgetEur,
    required this.currentSeasonDay,
    required this.selectedRegion,
    required this.filterSector,
    required this.regionProfiles,
    required this.availableOffers,
    required this.activeContracts,
    required this.activationMissions,
    this.lastActionBanner,
    this.lastActionIsError = false,
  });

  factory GlobalSponsorMarketState.initial({
    double teamPrestige = 58.0,
    int teamAvailableBudgetEur = 650000,
    int currentSeasonDay = 14,
  }) {
    const service = GlobalSponsorMarketExpansionService();
    final regions = service.buildDefaultRegionProfiles();
    final offers = service.generateMarketOffers(
      teamPrestige: teamPrestige,
      regionProfiles: regions,
    );
    final missions = service.buildDefaultActivationMissions();

    return GlobalSponsorMarketState(
      teamPrestige: teamPrestige,
      teamAvailableBudgetEur: teamAvailableBudgetEur,
      currentSeasonDay: currentSeasonDay,
      selectedRegion: EmergingSponsorRegion.asia,
      filterSector: null,
      regionProfiles: regions,
      availableOffers: offers,
      activeContracts: const [],
      activationMissions: missions,
    );
  }

  List<EmergingMarketSponsorOffer> get filteredOffers {
    final signedIds = activeContracts.map((e) => e.offerId).toSet();
    return availableOffers.where((offer) {
      if (signedIds.contains(offer.id)) return false;
      if (offer.region != selectedRegion) return false;
      if (filterSector != null && offer.sector != filterSector) return false;
      return true;
    }).toList();
  }

  List<RegionalActivationMission> get filteredMissions {
    return activationMissions
        .where((m) => m.region == selectedRegion)
        .toList();
  }

  GlobalSponsorMarketSummary get summary {
    const service = GlobalSponsorMarketExpansionService();
    return service.computeMarketSummary(
      regionProfiles: regionProfiles,
      activeContracts: activeContracts,
    );
  }

  GlobalSponsorMarketState copyWith({
    double? teamPrestige,
    int? teamAvailableBudgetEur,
    int? currentSeasonDay,
    EmergingSponsorRegion? selectedRegion,
    EmergingSponsorSector? filterSector,
    bool clearFilterSector = false,
    Map<EmergingSponsorRegion, EmergingMarketRegionProfile>? regionProfiles,
    List<EmergingMarketSponsorOffer>? availableOffers,
    List<ActiveEmergingSponsorContract>? activeContracts,
    List<RegionalActivationMission>? activationMissions,
    String? lastActionBanner,
    bool clearLastActionBanner = false,
    bool? lastActionIsError,
  }) {
    return GlobalSponsorMarketState(
      teamPrestige: teamPrestige ?? this.teamPrestige,
      teamAvailableBudgetEur:
          teamAvailableBudgetEur ?? this.teamAvailableBudgetEur,
      currentSeasonDay: currentSeasonDay ?? this.currentSeasonDay,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      filterSector:
          clearFilterSector ? null : (filterSector ?? this.filterSector),
      regionProfiles: regionProfiles ?? this.regionProfiles,
      availableOffers: availableOffers ?? this.availableOffers,
      activeContracts: activeContracts ?? this.activeContracts,
      activationMissions: activationMissions ?? this.activationMissions,
      lastActionBanner: clearLastActionBanner
          ? null
          : (lastActionBanner ?? this.lastActionBanner),
      lastActionIsError: lastActionIsError ?? this.lastActionIsError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamPrestige': teamPrestige,
      'teamAvailableBudgetEur': teamAvailableBudgetEur,
      'currentSeasonDay': currentSeasonDay,
      'selectedRegion': selectedRegion.toJson(),
      'filterSector': filterSector?.toJson(),
      'regionProfiles': {
        for (final entry in regionProfiles.entries)
          entry.key.toJson(): entry.value.toJson(),
      },
      'availableOffers': availableOffers.map((e) => e.toJson()).toList(),
      'activeContracts': activeContracts.map((e) => e.toJson()).toList(),
      'activationMissions': activationMissions.map((e) => e.toJson()).toList(),
    };
  }

  factory GlobalSponsorMarketState.fromJson(Map<String, dynamic> json) {
    final rawRegions = json['regionProfiles'] as Map<String, dynamic>;
    final parsedRegions = <EmergingSponsorRegion, EmergingMarketRegionProfile>{
      for (final entry in rawRegions.entries)
        EmergingSponsorRegion.fromJson(entry.key):
            EmergingMarketRegionProfile.fromJson(
          entry.value as Map<String, dynamic>,
        ),
    };

    return GlobalSponsorMarketState(
      teamPrestige: (json['teamPrestige'] as num).toDouble(),
      teamAvailableBudgetEur: (json['teamAvailableBudgetEur'] as num).toInt(),
      currentSeasonDay: (json['currentSeasonDay'] as num).toInt(),
      selectedRegion:
          EmergingSponsorRegion.fromJson(json['selectedRegion'] as String),
      filterSector: json['filterSector'] != null
          ? EmergingSponsorSector.fromJson(json['filterSector'] as String)
          : null,
      regionProfiles: parsedRegions,
      availableOffers: (json['availableOffers'] as List<dynamic>)
          .map(
            (e) =>
                EmergingMarketSponsorOffer.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      activeContracts: (json['activeContracts'] as List<dynamic>)
          .map(
            (e) => ActiveEmergingSponsorContract.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      activationMissions: (json['activationMissions'] as List<dynamic>)
          .map(
            (e) =>
                RegionalActivationMission.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

/// Kontroler stanu Riverpod dla systemu sponsorów z rynków wschodzących.
class GlobalSponsorMarketNotifier
    extends StateNotifier<GlobalSponsorMarketState> {
  final GlobalSponsorMarketExpansionService _service;

  GlobalSponsorMarketNotifier({
    GlobalSponsorMarketExpansionService? service,
    GlobalSponsorMarketState? initialState,
  })  : _service = service ?? const GlobalSponsorMarketExpansionService(),
        super(initialState ?? GlobalSponsorMarketState.initial());

  void selectRegion(EmergingSponsorRegion region) {
    state = state.copyWith(
      selectedRegion: region,
      clearLastActionBanner: true,
    );
  }

  void setFilterSector(EmergingSponsorSector? sector) {
    if (sector == null) {
      state = state.copyWith(clearFilterSector: true);
    } else {
      state = state.copyWith(filterSector: sector);
    }
  }

  /// Otwiera rozpoznanie nieodkrytego rynku (np. Bliskiego Wschodu) za stałą opłatą.
  bool scoutRegion(EmergingSponsorRegion region) {
    final profile = state.regionProfiles[region];
    if (profile == null) return false;
    if (profile.isScouted) {
      state = state.copyWith(
        lastActionBanner: 'Rynek ${region.label} został już rozpoznany.',
        lastActionIsError: false,
      );
      return true;
    }

    const cost = GlobalSponsorMarketExpansionService.scoutingMissionCostEur;
    if (state.teamAvailableBudgetEur < cost) {
      state = state.copyWith(
        lastActionBanner:
            'Brak środków (${Formatters.formatCurrency(cost)}) na rozpoznanie rynku ${region.label}.',
        lastActionIsError: true,
      );
      return false;
    }

    final updatedRegions =
        Map<EmergingSponsorRegion, EmergingMarketRegionProfile>.from(
      state.regionProfiles,
    );
    updatedRegions[region] = profile.copyWith(
      isScouted: true,
      fanbasePenetration: math.max(profile.fanbasePenetration, 12.0),
    );

    final refreshedOffers = _service.generateMarketOffers(
      teamPrestige: state.teamPrestige,
      regionProfiles: updatedRegions,
    );

    state = state.copyWith(
      teamAvailableBudgetEur: state.teamAvailableBudgetEur - cost,
      regionProfiles: updatedRegions,
      availableOffers: refreshedOffers,
      lastActionBanner:
          'Otwarto biuro skautingowe w regionie ${region.label}. Nowe oferty sponsorskie są dostępne!',
      lastActionIsError: false,
    );
    return true;
  }

  /// Negocjuje ofertę sponsorską z opcjonalnym żądaniem wyższego budżetu.
  EmergingMarketNegotiationResult negotiateAndMaybeSign({
    required String offerId,
    required double requestedBudgetBoostPercent,
    math.Random? rng,
  }) {
    final offerIndex = state.availableOffers.indexWhere((o) => o.id == offerId);
    if (offerIndex < 0) {
      return const EmergingMarketNegotiationResult(
        status: SponsorNegotiationOutcomeStatus.rejected,
        message: 'Nie znaleziono wskazanej oferty sponsorskiej.',
        proposedAnnualBudgetEur: 0,
        acceptanceProbability: 0.0,
      );
    }

    final offer = state.availableOffers[offerIndex];
    final profile = state.regionProfiles[offer.region]!;
    final alreadySigned =
        state.activeContracts.any((c) => c.offerId == offer.id);

    final result = _service.negotiateOffer(
      offer: offer,
      requestedBudgetBoostPercent: requestedBudgetBoostPercent,
      teamPrestige: state.teamPrestige,
      regionProfile: profile,
      activeContractsCount: state.activeContracts.length,
      alreadySignedOffer: alreadySigned,
      currentSeasonDay: state.currentSeasonDay,
      rng: rng,
    );

    if (result.status == SponsorNegotiationOutcomeStatus.accepted &&
        result.signedContract != null) {
      final updatedRegions =
          Map<EmergingSponsorRegion, EmergingMarketRegionProfile>.from(
        state.regionProfiles,
      );
      updatedRegions[offer.region] = profile.copyWith(
        fanbasePenetration: profile.fanbasePenetration + 8.0,
      );

      state = state.copyWith(
        teamAvailableBudgetEur:
            state.teamAvailableBudgetEur + offer.signingBonusEur,
        activeContracts: [...state.activeContracts, result.signedContract!],
        regionProfiles: updatedRegions,
        lastActionBanner: result.message,
        lastActionIsError: false,
      );
    } else if (result.status == SponsorNegotiationOutcomeStatus.counterOffer) {
      final counterBoost =
          (requestedBudgetBoostPercent * 0.5).clamp(0.0, 12.5);
      final updatedOffers = List<EmergingMarketSponsorOffer>.from(
        state.availableOffers,
      );
      updatedOffers[offerIndex] = offer.copyWith(
        isNegotiated: true,
        negotiatedBudgetBoostPercent: counterBoost,
      );
      state = state.copyWith(
        availableOffers: updatedOffers,
        lastActionBanner: result.message,
        lastActionIsError: false,
      );
    } else {
      state = state.copyWith(
        lastActionBanner: result.message,
        lastActionIsError: true,
      );
    }

    return result;
  }

  /// Podpisuje ofertę bezpośrednio na aktualnie widocznych warunkach.
  bool signOfferDirectly(String offerId) {
    final offerIndex = state.availableOffers.indexWhere((o) => o.id == offerId);
    if (offerIndex < 0) return false;
    final offer = state.availableOffers[offerIndex];
    final profile = state.regionProfiles[offer.region]!;
    final alreadySigned =
        state.activeContracts.any((c) => c.offerId == offer.id);

    final eligibility = _service.evaluateOfferEligibility(
      offer: offer,
      teamPrestige: state.teamPrestige,
      regionProfile: profile,
      activeContractsCount: state.activeContracts.length,
      alreadySignedOffer: alreadySigned,
    );

    if (!eligibility.isEligible) {
      state = state.copyWith(
        lastActionBanner: eligibility.unmetReasons.first,
        lastActionIsError: true,
      );
      return false;
    }

    final signed = _service.buildSignedContract(
      offer: offer,
      currentSeasonDay: state.currentSeasonDay,
    );

    final updatedRegions =
        Map<EmergingSponsorRegion, EmergingMarketRegionProfile>.from(
      state.regionProfiles,
    );
    updatedRegions[offer.region] = profile.copyWith(
      fanbasePenetration: profile.fanbasePenetration + 8.0,
    );

    state = state.copyWith(
      teamAvailableBudgetEur:
          state.teamAvailableBudgetEur + offer.signingBonusEur,
      activeContracts: [...state.activeContracts, signed],
      regionProfiles: updatedRegions,
      lastActionBanner:
          'Podpisano kontrakt z ${offer.companyName} (+${Formatters.formatCurrency(offer.signingBonusEur)} premii za podpis).',
      lastActionIsError: false,
    );
    return true;
  }

  /// Rozpoczyna regionalną misję aktywacyjną.
  bool startActivationMission(String missionId) {
    final idx = state.activationMissions.indexWhere((m) => m.id == missionId);
    if (idx < 0) return false;
    final mission = state.activationMissions[idx];

    if (mission.isCompleted || mission.isInProgress) {
      return false;
    }

    if (state.teamAvailableBudgetEur < mission.costEur) {
      state = state.copyWith(
        lastActionBanner:
            'Brak środków (${Formatters.formatCurrency(mission.costEur)}) na misję "${mission.title}".',
        lastActionIsError: true,
      );
      return false;
    }

    final updatedMissions =
        List<RegionalActivationMission>.from(state.activationMissions);
    updatedMissions[idx] = mission.copyWith(
      isInProgress: true,
      daysRemaining: mission.durationDays,
    );

    state = state.copyWith(
      teamAvailableBudgetEur: state.teamAvailableBudgetEur - mission.costEur,
      activationMissions: updatedMissions,
      lastActionBanner:
          'Rozpoczęto aktywację "${mission.title}" (${mission.durationDays} dni).',
      lastActionIsError: false,
    );
    return true;
  }

  /// Posuwa kalendarz o `days` dni, finalizując misje aktywacyjne.
  void advanceDays(int days) {
    if (days <= 0) return;

    final updatedRegions =
        Map<EmergingSponsorRegion, EmergingMarketRegionProfile>.from(
      state.regionProfiles,
    );
    var updatedContracts =
        List<ActiveEmergingSponsorContract>.from(state.activeContracts);
    final updatedMissions = <RegionalActivationMission>[];

    for (final mission in state.activationMissions) {
      if (!mission.isInProgress) {
        updatedMissions.add(mission);
        continue;
      }

      final remaining = mission.daysRemaining - days;
      if (remaining > 0) {
        updatedMissions.add(mission.copyWith(daysRemaining: remaining));
      } else {
        updatedMissions.add(
          mission.copyWith(
            isInProgress: false,
            isCompleted: true,
            daysRemaining: 0,
          ),
        );

        final region = updatedRegions[mission.region];
        if (region != null) {
          updatedRegions[mission.region] = region.copyWith(
            fanbasePenetration: region.fanbasePenetration + mission.presenceGain,
            baseCommercialMultiplier: region.baseCommercialMultiplier +
                mission.commercialMultiplierBoost,
            completedActivationsCount: region.completedActivationsCount + 1,
            isScouted: true,
          );
        }

        updatedContracts = updatedContracts.map((c) {
          if (c.region != mission.region) return c;
          return c.copyWith(
            contract: c.contract.copyWith(
              sponsorSatisfaction: (c.contract.sponsorSatisfaction +
                      mission.satisfactionGain)
                  .clamp(0.0, 100.0),
            ),
          );
        }).toList();
      }
    }

    state = state.copyWith(
      currentSeasonDay: state.currentSeasonDay + days,
      regionProfiles: updatedRegions,
      activeContracts: updatedContracts,
      activationMissions: updatedMissions,
    );
  }

  /// Zapisuje wynik wyścigu z serii Global Exotic Tours i wypłaca premie sponsorskie.
  int recordExoticTourPerformance({
    required ExoticTourId tourId,
    required int stageWins,
    required int bestGcRank,
  }) {
    final targetRegion = switch (tourId) {
      ExoticTourId.tourDeLangkawi => EmergingSponsorRegion.asia,
      ExoticTourId.tourDuRwanda => EmergingSponsorRegion.africa,
      ExoticTourId.tourOfOman ||
      ExoticTourId.alUlaTour =>
        EmergingSponsorRegion.middleEast,
    };

    final regionProfile = state.regionProfiles[targetRegion]!;
    final result = _service.recordExoticTourResult(
      tourId: tourId,
      stageWins: stageWins,
      bestGcRank: bestGcRank,
      regionProfile: regionProfile,
      contracts: state.activeContracts,
    );

    final updatedRegions =
        Map<EmergingSponsorRegion, EmergingMarketRegionProfile>.from(
      state.regionProfiles,
    );
    updatedRegions[targetRegion] = result.updatedRegion;

    state = state.copyWith(
      teamAvailableBudgetEur:
          state.teamAvailableBudgetEur + result.totalBonusAwardedEur,
      regionProfiles: updatedRegions,
      activeContracts: result.updatedContracts,
      lastActionBanner: result.totalBonusAwardedEur > 0
          ? 'Premia z rynku ${targetRegion.label}: +${Formatters.formatCurrency(result.totalBonusAwardedEur)}!'
          : 'Wzrosła rozpoznawalność w regionie ${targetRegion.label} po starcie w ${tourId.name}.',
      lastActionIsError: false,
    );

    return result.totalBonusAwardedEur;
  }
}

final globalSponsorMarketServiceProvider =
    Provider<GlobalSponsorMarketExpansionService>((ref) {
  return const GlobalSponsorMarketExpansionService();
});

final globalSponsorMarketProvider = StateNotifierProvider<
    GlobalSponsorMarketNotifier, GlobalSponsorMarketState>((ref) {
  final service = ref.watch(globalSponsorMarketServiceProvider);
  return GlobalSponsorMarketNotifier(service: service);
});

final globalEmergingSponsorRevenueProvider = Provider<int>((ref) {
  final marketState = ref.watch(globalSponsorMarketProvider);
  return marketState.summary.totalEmergingAnnualRevenueEur;
});

/// Produkcyjny panel UI systemu sponsorów z rynków wschodzących (Azja, Afryka, Bliski Wschód).
class GlobalSponsorMarketExpansionPanel extends ConsumerStatefulWidget {
  const GlobalSponsorMarketExpansionPanel({super.key});

  @override
  ConsumerState<GlobalSponsorMarketExpansionPanel> createState() =>
      _GlobalSponsorMarketExpansionPanelState();
}

class _GlobalSponsorMarketExpansionPanelState
    extends ConsumerState<GlobalSponsorMarketExpansionPanel> {
  final Map<String, double> _negotiationBoostDrafts = {};
  String? _expandedNegotiationOfferId;

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(globalSponsorMarketProvider);
    final notifier = ref.read(globalSponsorMarketProvider.notifier);
    final summary = marketState.summary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 640;
          final isDesktop = constraints.maxWidth >= 1120;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(marketState, summary, isMobile),
                const SizedBox(height: 16),
                if (marketState.lastActionBanner != null) ...[
                  _buildFeedbackBanner(
                    message: marketState.lastActionBanner!,
                    isError: marketState.lastActionIsError,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildRegionsSection(
                  marketState: marketState,
                  notifier: notifier,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 20),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildOffersSection(
                          marketState: marketState,
                          notifier: notifier,
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildActiveContractsSection(marketState, isMobile),
                            const SizedBox(height: 20),
                            _buildActivationsSection(
                              marketState: marketState,
                              notifier: notifier,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildOffersSection(
                    marketState: marketState,
                    notifier: notifier,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 16),
                  _buildActiveContractsSection(marketState, isMobile),
                  const SizedBox(height: 16),
                  _buildActivationsSection(
                    marketState: marketState,
                    notifier: notifier,
                    isMobile: isMobile,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    GlobalSponsorMarketState state,
    GlobalSponsorMarketSummary summary,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.public_rounded,
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
                          'Ekspansja Sponsorów: Rynki Wschodzące',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Azja, Afryka i Bliski Wschód • Budżet operacyjny: ${Formatters.formatCurrency(state.teamAvailableBudgetEur)}',
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
              _buildHeaderBadge(
                label: 'Indeks Ekspansji',
                value: '${summary.globalExpansionIndex.toStringAsFixed(0)}/100',
                color: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricChip(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Roczny przychód',
                value: Formatters.formatCurrency(
                  summary.totalEmergingAnnualRevenueEur,
                ),
                accent: AppColors.statusSuccess,
              ),
              _buildMetricChip(
                icon: Icons.handshake_rounded,
                label: 'Aktywne kontrakty',
                value:
                    '${summary.activeContractsCount}/${GlobalSponsorMarketExpansionService.maxActiveEmergingContracts}',
                accent: AppColors.accentBlue,
              ),
              _buildMetricChip(
                icon: Icons.emoji_events_rounded,
                label: 'Premie egzotyczne',
                value: Formatters.formatCurrency(summary.totalEarnedBonusesEur),
                accent: AppColors.goldAccent,
              ),
              _buildMetricChip(
                icon: Icons.stars_rounded,
                label: 'Prestiż drużyny',
                value: state.teamPrestige.toStringAsFixed(0),
                accent: AppColors.primaryAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Column(
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
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required String message,
    required bool isError,
  }) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
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
        ],
      ),
    );
  }

  Widget _buildRegionsSection({
    required GlobalSponsorMarketState marketState,
    required GlobalSponsorMarketNotifier notifier,
    required bool isMobile,
  }) {
    final cards = EmergingSponsorRegion.values.map((region) {
      final profile = marketState.regionProfiles[region]!;
      final isSelected = marketState.selectedRegion == region;
      return _InteractiveRegionCard(
        profile: profile,
        isSelected: isSelected,
        onSelect: () => notifier.selectRegion(region),
        onScout: () => notifier.scoutRegion(region),
      );
    }).toList();

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildOffersSection({
    required GlobalSponsorMarketState marketState,
    required GlobalSponsorMarketNotifier notifier,
    required bool isMobile,
  }) {
    final offers = marketState.filteredOffers;
    final regionProfile =
        marketState.regionProfiles[marketState.selectedRegion]!;
    const service = GlobalSponsorMarketExpansionService();

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Oferty Sponsorskie — ${marketState.selectedRegion.label}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Mnożnik rynku: x${regionProfile.effectiveCommercialMultiplier.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: marketState.selectedRegion.accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPillButton(
                  label: 'Wszystkie sektory',
                  isSelected: marketState.filterSector == null,
                  onTap: () => notifier.setFilterSector(null),
                ),
                const SizedBox(width: 8),
                for (final sector in EmergingSponsorSector.values) ...[
                  _FilterPillButton(
                    label: sector.label,
                    isSelected: marketState.filterSector == sector,
                    onTap: () => notifier.setFilterSector(sector),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (offers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Center(
                child: Text(
                  'Brak wolnych ofert w tym filtrze. Zmień sektor lub rozwiń inny region.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (final offer in offers) ...[
                  Builder(
                    builder: (context) {
                      final eligibility = service.evaluateOfferEligibility(
                        offer: offer,
                        teamPrestige: marketState.teamPrestige,
                        regionProfile: regionProfile,
                        activeContractsCount:
                            marketState.activeContracts.length,
                        alreadySignedOffer: marketState.activeContracts
                            .any((c) => c.offerId == offer.id),
                      );
                      final draftBoost =
                          _negotiationBoostDrafts[offer.id] ?? 10.0;
                      final winProb =
                          service.computeNegotiationAcceptanceProbability(
                        offer: offer,
                        requestedBudgetBoostPercent: draftBoost,
                        teamPrestige: marketState.teamPrestige,
                        regionProfile: regionProfile,
                      );
                      final isNegotiating =
                          _expandedNegotiationOfferId == offer.id;

                      return _OfferCard(
                        offer: offer,
                        eligibility: eligibility,
                        isNegotiating: isNegotiating,
                        draftBoostPercent: draftBoost,
                        acceptanceProbability: winProb,
                        onToggleNegotiate: () {
                          setState(() {
                            _expandedNegotiationOfferId =
                                isNegotiating ? null : offer.id;
                          });
                        },
                        onBoostChanged: (val) {
                          setState(() {
                            _negotiationBoostDrafts[offer.id] = val;
                          });
                        },
                        onSubmitNegotiation: () {
                          notifier.negotiateAndMaybeSign(
                            offerId: offer.id,
                            requestedBudgetBoostPercent: draftBoost,
                          );
                        },
                        onSignDirect: () => notifier.signOfferDirectly(offer.id),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActiveContractsSection(
    GlobalSponsorMarketState marketState,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktywni Sponsorzy Wschodzący',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (marketState.activeContracts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak podpisanych kontraktów pozaeuropejskich. Wybierz ofertę i rozpocznij ekspansję.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: [
                for (final active in marketState.activeContracts) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              active.region.icon,
                              size: 16,
                              color: active.region.accentColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${active.contract.companyName} (${active.countryCode})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${Formatters.formatCurrency(active.contract.annualBudgetEur)}/r',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusSuccess,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Satysfakcja: ${active.contract.sponsorSatisfaction.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              'Premie: ${Formatters.formatCurrency(active.earnedExoticBonusesEur)}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.goldAccent,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActivationsSection({
    required GlobalSponsorMarketState marketState,
    required GlobalSponsorMarketNotifier notifier,
    required bool isMobile,
  }) {
    final missions = marketState.filteredMissions;
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktywacje Regionalne — ${marketState.selectedRegion.label}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final mission in missions) ...[
            _ActivationMissionCard(
              mission: mission,
              canAfford: marketState.teamAvailableBudgetEur >= mission.costEur,
              onLaunch: () => notifier.startActivationMission(mission.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _InteractiveRegionCard extends StatefulWidget {
  final EmergingMarketRegionProfile profile;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onScout;

  const _InteractiveRegionCard({
    required this.profile,
    required this.isSelected,
    required this.onSelect,
    required this.onScout,
  });

  @override
  State<_InteractiveRegionCard> createState() => _InteractiveRegionCardState();
}

class _InteractiveRegionCardState extends State<_InteractiveRegionCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.profile.region.accentColor;
    final borderColor = widget.isSelected
        ? accent
        : (_isHovered || _isFocused
            ? accent.withValues(alpha: 0.65)
            : AppColors.cardBorder);

    return Focus(
      onFocusChange: (val) => setState(() => _isFocused = val),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: _isPressed
                ? Matrix4.diagonal3Values(0.99, 0.99, 1.0)
                : Matrix4.identity(),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.profile.region.icon, color: accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.profile.region.fullTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${widget.profile.marketGrowthRatePercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.profile.presenceTier.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.profile.fanbasePenetration / 100.0,
                    minHeight: 6,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Obecność: ${widget.profile.fanbasePenetration.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (!widget.profile.isScouted)
                      _ActionPillButton(
                        label: 'Rozpoznaj (45k €)',
                        color: AppColors.goldAccent,
                        enabled: true,
                        onTap: widget.onScout,
                      )
                    else
                      Text(
                        '${widget.profile.mediaBroadcastReachMillions.toStringAsFixed(0)}M widzów',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
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

class _OfferCard extends StatelessWidget {
  final EmergingMarketSponsorOffer offer;
  final OfferEligibilityReport eligibility;
  final bool isNegotiating;
  final double draftBoostPercent;
  final double acceptanceProbability;
  final VoidCallback onToggleNegotiate;
  final ValueChanged<double> onBoostChanged;
  final VoidCallback onSubmitNegotiation;
  final VoidCallback onSignDirect;

  const _OfferCard({
    required this.offer,
    required this.eligibility,
    required this.isNegotiating,
    required this.draftBoostPercent,
    required this.acceptanceProbability,
    required this.onToggleNegotiate,
    required this.onBoostChanged,
    required this.onSubmitNegotiation,
    required this.onSignDirect,
  });

  @override
  Widget build(BuildContext context) {
    final regionAccent = offer.region.accentColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: eligibility.isEligible
              ? AppColors.cardBorder
              : AppColors.cardBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(offer.sector.icon, size: 18, color: regionAccent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.companyName} (${offer.countryCode})',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${offer.countryName} • ${offer.sector.label}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${Formatters.formatCurrency(offer.effectiveAnnualBudgetEur)} / rok',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusSuccess,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'Premia: +${Formatters.formatCurrency(offer.signingBonusEur)} • ${offer.contractDurationYears} lata',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            offer.culturalExpectationsNote,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (!eligibility.isEligible) ...[
            const SizedBox(height: 8),
            Text(
              eligibility.unmetReasons.first,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.amberWarning,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionPillButton(
                label: 'Podpisz teraz',
                color: AppColors.statusSuccess,
                enabled: eligibility.isEligible,
                onTap: onSignDirect,
              ),
              _ActionPillButton(
                label: isNegotiating ? 'Ukryj negocjacje' : 'Negocjuj budżet',
                color: AppColors.accentBlue,
                enabled: eligibility.isEligible,
                onTap: onToggleNegotiate,
              ),
            ],
          ),
          if (isNegotiating && eligibility.isEligible) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Żądana podwyżka: +${draftBoostPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'Szansa zgody: ${(acceptanceProbability * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: acceptanceProbability >= 0.6
                              ? AppColors.statusSuccess
                              : AppColors.amberWarning,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: draftBoostPercent,
                    min: 0,
                    max: 25,
                    divisions: 25,
                    activeColor: AppColors.goldAccent,
                    inactiveColor: AppColors.cardBorder,
                    onChanged: onBoostChanged,
                  ),
                  _ActionPillButton(
                    label: 'Wyślij ofertę negocjacyjną',
                    color: AppColors.goldAccent,
                    enabled: true,
                    onTap: onSubmitNegotiation,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivationMissionCard extends StatelessWidget {
  final RegionalActivationMission mission;
  final bool canAfford;
  final VoidCallback onLaunch;

  const _ActivationMissionCard({
    required this.mission,
    required this.canAfford,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = mission.isCompleted
        ? 'Ukończono'
        : (mission.isInProgress
            ? 'W toku (${mission.daysRemaining} dni)'
            : 'Uruchom (${Formatters.formatCurrency(mission.costEur)})');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mission.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mission.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '+${mission.presenceGain.toStringAsFixed(0)}% obecności',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.statusSuccess,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              _ActionPillButton(
                label: statusLabel,
                color: mission.isCompleted
                    ? AppColors.statusSuccess
                    : AppColors.primaryAccent,
                enabled:
                    !mission.isCompleted && !mission.isInProgress && canAfford,
                onTap: onLaunch,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPillButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPillButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterPillButton> createState() => _FilterPillButtonState();
}

class _FilterPillButtonState extends State<_FilterPillButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AppColors.primaryAccent
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused || widget.isSelected
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPillButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionPillButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.enabled ? widget.color : AppColors.textSecondary;
    final bgAlpha = !widget.enabled
        ? 0.08
        : (_pressed ? 0.30 : (_hovered ? 0.22 : 0.14));

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              widget.enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: bgAlpha),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : effectiveColor.withValues(
                        alpha: widget.enabled ? 0.55 : 0.25,
                      ),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.enabled
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
