// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Model podziału przychodów z praw telewizyjnych w cyklu WorldTour.
enum BroadcastDistributionModel {
  /// Zrównoważony model WorldTour (35% równy podział, 35% wyniki UCI, 30% oglądalność).
  balancedWorldTour,

  /// Solidarnościowy model równouprawnienia (50% równy podział, 30% wyniki, 20% oglądalność).
  equalitarian,

  /// Model premiujący wynik sportowy (25% równy podział, 50% wyniki UCI, 25% oglądalność).
  meritWeighted,

  /// Model komercyjny zależny od oglądalności (20% równy podział, 30% wyniki, 50% oglądalność).
  commercialViewership;

  String get displayNamePl {
    switch (this) {
      case BroadcastDistributionModel.balancedWorldTour:
        return 'Standard WorldTour';
      case BroadcastDistributionModel.equalitarian:
        return 'Solidarnościowy';
      case BroadcastDistributionModel.meritWeighted:
        return 'Wynikowy UCI';
      case BroadcastDistributionModel.commercialViewership:
        return 'Komercyjny TV';
    }
  }

  String get descriptionPl {
    switch (this) {
      case BroadcastDistributionModel.balancedWorldTour:
        return '35% baza • 35% wyniki UCI • 30% oglądalność TV';
      case BroadcastDistributionModel.equalitarian:
        return '50% baza • 30% wyniki UCI • 20% oglądalność TV';
      case BroadcastDistributionModel.meritWeighted:
        return '25% baza • 50% wyniki UCI • 25% oglądalność TV';
      case BroadcastDistributionModel.commercialViewership:
        return '20% baza • 30% wyniki UCI • 50% oglądalność TV';
    }
  }

  double get equalShareWeight {
    switch (this) {
      case BroadcastDistributionModel.balancedWorldTour:
        return 0.35;
      case BroadcastDistributionModel.equalitarian:
        return 0.50;
      case BroadcastDistributionModel.meritWeighted:
        return 0.25;
      case BroadcastDistributionModel.commercialViewership:
        return 0.20;
    }
  }

  double get meritShareWeight {
    switch (this) {
      case BroadcastDistributionModel.balancedWorldTour:
        return 0.35;
      case BroadcastDistributionModel.equalitarian:
        return 0.30;
      case BroadcastDistributionModel.meritWeighted:
        return 0.50;
      case BroadcastDistributionModel.commercialViewership:
        return 0.30;
    }
  }

  double get viewershipShareWeight {
    switch (this) {
      case BroadcastDistributionModel.balancedWorldTour:
        return 0.30;
      case BroadcastDistributionModel.equalitarian:
        return 0.20;
      case BroadcastDistributionModel.meritWeighted:
        return 0.25;
      case BroadcastDistributionModel.commercialViewership:
        return 0.50;
    }
  }

  String toJson() => name;

  static BroadcastDistributionModel fromJson(String? value) {
    if (value == null) return BroadcastDistributionModel.balancedWorldTour;
    return BroadcastDistributionModel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BroadcastDistributionModel.balancedWorldTour,
    );
  }
}

/// Kategoria licencyjna drużyny w podziale praw telewizyjnych.
enum BroadcastTierCategory {
  worldTourTier1,
  proTeamWildcard;

  String get displayNamePl {
    switch (this) {
      case BroadcastTierCategory.worldTourTier1:
        return 'WorldTour';
      case BroadcastTierCategory.proTeamWildcard:
        return 'ProTeam (Dzika Karta)';
    }
  }

  double get basePoolMultiplier {
    switch (this) {
      case BroadcastTierCategory.worldTourTier1:
        return 1.0;
      case BroadcastTierCategory.proTeamWildcard:
        return 0.35;
    }
  }

  String toJson() => name;

  static BroadcastTierCategory fromJson(String? value) {
    if (value == null) return BroadcastTierCategory.worldTourTier1;
    return BroadcastTierCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BroadcastTierCategory.worldTourTier1,
    );
  }
}

/// Główny rynek medialny transmisji TV drużyny.
enum BroadcastMarketRegion {
  europeWest,
  europeNorthEast,
  americas,
  asiaPacific,
  globalStreaming;

  String get displayNamePl {
    switch (this) {
      case BroadcastMarketRegion.europeWest:
        return 'Europa Zachodnia';
      case BroadcastMarketRegion.europeNorthEast:
        return 'Europa Płn.-Wsch.';
      case BroadcastMarketRegion.americas:
        return 'Ameryki';
      case BroadcastMarketRegion.asiaPacific:
        return 'Azja i Pacyfik';
      case BroadcastMarketRegion.globalStreaming:
        return 'Streaming OTT';
    }
  }

  /// Wskaźnik wartości komercyjnej czasu antenowego na danym rynku.
  double get marketWeight {
    switch (this) {
      case BroadcastMarketRegion.europeWest:
        return 1.25;
      case BroadcastMarketRegion.europeNorthEast:
        return 0.95;
      case BroadcastMarketRegion.americas:
        return 1.15;
      case BroadcastMarketRegion.asiaPacific:
        return 1.05;
      case BroadcastMarketRegion.globalStreaming:
        return 1.20;
    }
  }

  String toJson() => name;

  static BroadcastMarketRegion fromJson(String? value) {
    if (value == null) return BroadcastMarketRegion.europeWest;
    return BroadcastMarketRegion.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BroadcastMarketRegion.europeWest,
    );
  }
}

double _sanitizeNonNegative(double value, {double fallback = 0.0}) {
  if (!value.isFinite || value < 0.0) return fallback;
  return value;
}

/// Dane wejściowe drużyny do wyliczenia udziału w przychodach z praw telewizyjnych.
class TeamBroadcastPerformanceInput {
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final bool isPlayerTeam;
  final BroadcastTierCategory tier;
  final double uciSeasonPoints;
  final int worldTourWins;
  final int grandTourStageWins;
  final int monumentWins;
  final int leaderJerseyDays;
  final double averageViewersMillions;
  final double peakViewersMillions;
  final double tvExposureMinutes;
  final double socialMediaEngagementIndex;
  final BroadcastMarketRegion primaryMarket;
  final bool isRelegationZone;

  const TeamBroadcastPerformanceInput({
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    this.isPlayerTeam = false,
    this.tier = BroadcastTierCategory.worldTourTier1,
    required this.uciSeasonPoints,
    this.worldTourWins = 0,
    this.grandTourStageWins = 0,
    this.monumentWins = 0,
    this.leaderJerseyDays = 0,
    required this.averageViewersMillions,
    this.peakViewersMillions = 0.0,
    required this.tvExposureMinutes,
    this.socialMediaEngagementIndex = 50.0,
    this.primaryMarket = BroadcastMarketRegion.europeWest,
    this.isRelegationZone = false,
  });

  double get safeUciPoints => _sanitizeNonNegative(uciSeasonPoints);
  int get safeWorldTourWins => worldTourWins < 0 ? 0 : worldTourWins;
  int get safeGrandTourStageWins =>
      grandTourStageWins < 0 ? 0 : grandTourStageWins;
  int get safeMonumentWins => monumentWins < 0 ? 0 : monumentWins;
  int get safeLeaderJerseyDays => leaderJerseyDays < 0 ? 0 : leaderJerseyDays;
  double get safeAvgViewers => _sanitizeNonNegative(averageViewersMillions);
  double get safePeakViewers =>
      math.max(safeAvgViewers, _sanitizeNonNegative(peakViewersMillions));
  double get safeTvExposureMinutes => _sanitizeNonNegative(tvExposureMinutes);
  double get safeSocialIndex =>
      _sanitizeNonNegative(socialMediaEngagementIndex).clamp(0.0, 100.0);

  /// Surowy wskaźnik osiągnięć sportowych używany do podziału puli wynikowej.
  double get rawMeritScore {
    final trophyScore = (safeWorldTourWins * 120.0) +
        (safeGrandTourStageWins * 180.0) +
        (safeMonumentWins * 450.0) +
        (safeLeaderJerseyDays * 65.0);
    return (safeUciPoints * 0.65) + trophyScore;
  }

  /// Surowy wskaźnik oglądalności TV i siły medialnej drużyny.
  double get rawViewershipScore {
    final marketWeightedSocial = safeSocialIndex * primaryMarket.marketWeight;
    return (safeAvgViewers * 100.0 * 0.45) +
        (safePeakViewers * 40.0 * 0.20) +
        (safeTvExposureMinutes * 0.35 * 0.25) +
        (marketWeightedSocial * 0.10);
  }

  /// Wskaźnik dla puli premiowej Wielkich Tourów i Monumentów.
  double get rawPrestigeBonusScore {
    return (safeGrandTourStageWins * 2.0) +
        (safeMonumentWins * 5.0) +
        (safeLeaderJerseyDays * 1.0);
  }

  TeamBroadcastPerformanceInput copyWith({
    String? teamId,
    String? teamName,
    String? teamShortCode,
    bool? isPlayerTeam,
    BroadcastTierCategory? tier,
    double? uciSeasonPoints,
    int? worldTourWins,
    int? grandTourStageWins,
    int? monumentWins,
    int? leaderJerseyDays,
    double? averageViewersMillions,
    double? peakViewersMillions,
    double? tvExposureMinutes,
    double? socialMediaEngagementIndex,
    BroadcastMarketRegion? primaryMarket,
    bool? isRelegationZone,
  }) {
    return TeamBroadcastPerformanceInput(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      isPlayerTeam: isPlayerTeam ?? this.isPlayerTeam,
      tier: tier ?? this.tier,
      uciSeasonPoints: uciSeasonPoints ?? this.uciSeasonPoints,
      worldTourWins: worldTourWins ?? this.worldTourWins,
      grandTourStageWins: grandTourStageWins ?? this.grandTourStageWins,
      monumentWins: monumentWins ?? this.monumentWins,
      leaderJerseyDays: leaderJerseyDays ?? this.leaderJerseyDays,
      averageViewersMillions:
          averageViewersMillions ?? this.averageViewersMillions,
      peakViewersMillions: peakViewersMillions ?? this.peakViewersMillions,
      tvExposureMinutes: tvExposureMinutes ?? this.tvExposureMinutes,
      socialMediaEngagementIndex:
          socialMediaEngagementIndex ?? this.socialMediaEngagementIndex,
      primaryMarket: primaryMarket ?? this.primaryMarket,
      isRelegationZone: isRelegationZone ?? this.isRelegationZone,
    );
  }

  Map<String, Object?> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'teamShortCode': teamShortCode,
        'isPlayerTeam': isPlayerTeam,
        'tier': tier.toJson(),
        'uciSeasonPoints': uciSeasonPoints,
        'worldTourWins': worldTourWins,
        'grandTourStageWins': grandTourStageWins,
        'monumentWins': monumentWins,
        'leaderJerseyDays': leaderJerseyDays,
        'averageViewersMillions': averageViewersMillions,
        'peakViewersMillions': peakViewersMillions,
        'tvExposureMinutes': tvExposureMinutes,
        'socialMediaEngagementIndex': socialMediaEngagementIndex,
        'primaryMarket': primaryMarket.toJson(),
        'isRelegationZone': isRelegationZone,
      };

  factory TeamBroadcastPerformanceInput.fromJson(Map<String, Object?> json) {
    return TeamBroadcastPerformanceInput(
      teamId: json['teamId'] as String? ?? 'unknown_team',
      teamName: json['teamName'] as String? ?? 'Unknown Team',
      teamShortCode: json['teamShortCode'] as String? ?? 'UNK',
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      tier: BroadcastTierCategory.fromJson(json['tier'] as String?),
      uciSeasonPoints: (json['uciSeasonPoints'] as num?)?.toDouble() ?? 0.0,
      worldTourWins: (json['worldTourWins'] as num?)?.toInt() ?? 0,
      grandTourStageWins: (json['grandTourStageWins'] as num?)?.toInt() ?? 0,
      monumentWins: (json['monumentWins'] as num?)?.toInt() ?? 0,
      leaderJerseyDays: (json['leaderJerseyDays'] as num?)?.toInt() ?? 0,
      averageViewersMillions:
          (json['averageViewersMillions'] as num?)?.toDouble() ?? 0.0,
      peakViewersMillions:
          (json['peakViewersMillions'] as num?)?.toDouble() ?? 0.0,
      tvExposureMinutes: (json['tvExposureMinutes'] as num?)?.toDouble() ?? 0.0,
      socialMediaEngagementIndex:
          (json['socialMediaEngagementIndex'] as num?)?.toDouble() ?? 50.0,
      primaryMarket:
          BroadcastMarketRegion.fromJson(json['primaryMarket'] as String?),
      isRelegationZone: json['isRelegationZone'] as bool? ?? false,
    );
  }
}

/// Konfiguracja puli przychodów z praw telewizyjnych na dany sezon WorldTour.
class BroadcastPoolConfiguration {
  final int seasonYear;
  final double totalWorldTourPoolEur;
  final BroadcastDistributionModel distributionModel;
  final double grandTourBonusPoolEur;
  final double wildcardReserveRatio;
  final double viewershipGrowthMultiplier;
  final double minimumGuaranteeFloorEur;
  final double maximumTeamCapRatio;

  const BroadcastPoolConfiguration({
    this.seasonYear = 2026,
    this.totalWorldTourPoolEur = 48000000.0,
    this.distributionModel = BroadcastDistributionModel.balancedWorldTour,
    this.grandTourBonusPoolEur = 12000000.0,
    this.wildcardReserveRatio = 0.08,
    this.viewershipGrowthMultiplier = 1.0,
    this.minimumGuaranteeFloorEur = 450000.0,
    this.maximumTeamCapRatio = 0.16,
  });

  double get safeBasePoolEur => _sanitizeNonNegative(totalWorldTourPoolEur);
  double get safeGrandTourBonusEur =>
      _sanitizeNonNegative(grandTourBonusPoolEur);
  double get safeGrowthMultiplier =>
      _sanitizeNonNegative(viewershipGrowthMultiplier, fallback: 1.0)
          .clamp(0.5, 2.0);
  double get safeWildcardRatio =>
      _sanitizeNonNegative(wildcardReserveRatio).clamp(0.0, 0.35);
  double get safeMinimumFloorEur =>
      _sanitizeNonNegative(minimumGuaranteeFloorEur);
  double get safeMaxTeamCapRatio =>
      _sanitizeNonNegative(maximumTeamCapRatio, fallback: 0.16)
          .clamp(0.08, 1.0);

  double get effectiveTotalPoolEur =>
      (safeBasePoolEur + safeGrandTourBonusEur) * safeGrowthMultiplier;

  BroadcastPoolConfiguration copyWith({
    int? seasonYear,
    double? totalWorldTourPoolEur,
    BroadcastDistributionModel? distributionModel,
    double? grandTourBonusPoolEur,
    double? wildcardReserveRatio,
    double? viewershipGrowthMultiplier,
    double? minimumGuaranteeFloorEur,
    double? maximumTeamCapRatio,
  }) {
    return BroadcastPoolConfiguration(
      seasonYear: seasonYear ?? this.seasonYear,
      totalWorldTourPoolEur:
          totalWorldTourPoolEur ?? this.totalWorldTourPoolEur,
      distributionModel: distributionModel ?? this.distributionModel,
      grandTourBonusPoolEur:
          grandTourBonusPoolEur ?? this.grandTourBonusPoolEur,
      wildcardReserveRatio: wildcardReserveRatio ?? this.wildcardReserveRatio,
      viewershipGrowthMultiplier:
          viewershipGrowthMultiplier ?? this.viewershipGrowthMultiplier,
      minimumGuaranteeFloorEur:
          minimumGuaranteeFloorEur ?? this.minimumGuaranteeFloorEur,
      maximumTeamCapRatio: maximumTeamCapRatio ?? this.maximumTeamCapRatio,
    );
  }

  Map<String, Object?> toJson() => {
        'seasonYear': seasonYear,
        'totalWorldTourPoolEur': totalWorldTourPoolEur,
        'distributionModel': distributionModel.toJson(),
        'grandTourBonusPoolEur': grandTourBonusPoolEur,
        'wildcardReserveRatio': wildcardReserveRatio,
        'viewershipGrowthMultiplier': viewershipGrowthMultiplier,
        'minimumGuaranteeFloorEur': minimumGuaranteeFloorEur,
        'maximumTeamCapRatio': maximumTeamCapRatio,
      };

  factory BroadcastPoolConfiguration.fromJson(Map<String, Object?> json) {
    return BroadcastPoolConfiguration(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      totalWorldTourPoolEur:
          (json['totalWorldTourPoolEur'] as num?)?.toDouble() ?? 48000000.0,
      distributionModel: BroadcastDistributionModel.fromJson(
        json['distributionModel'] as String?,
      ),
      grandTourBonusPoolEur:
          (json['grandTourBonusPoolEur'] as num?)?.toDouble() ?? 12000000.0,
      wildcardReserveRatio:
          (json['wildcardReserveRatio'] as num?)?.toDouble() ?? 0.08,
      viewershipGrowthMultiplier:
          (json['viewershipGrowthMultiplier'] as num?)?.toDouble() ?? 1.0,
      minimumGuaranteeFloorEur:
          (json['minimumGuaranteeFloorEur'] as num?)?.toDouble() ?? 450000.0,
      maximumTeamCapRatio:
          (json['maximumTeamCapRatio'] as num?)?.toDouble() ?? 0.16,
    );
  }
}

/// Szczegółowy udział pojedynczej drużyny w przychodach z praw TV.
class TeamBroadcastRevenueShare {
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final bool isPlayerTeam;
  final BroadcastTierCategory tier;
  final BroadcastMarketRegion primaryMarket;
  final double equalBasePayoutEur;
  final double meritPerformancePayoutEur;
  final double viewershipPayoutEur;
  final double grandTourAndMonumentBonusEur;
  final double totalPayoutEur;
  final double poolSharePercent;
  final double meritScoreNormalized;
  final double viewershipScoreNormalized;
  final double projectedQuarterlyTrancheEur;
  final int rankByRevenue;
  final double deltaVsLastSeasonEur;

  const TeamBroadcastRevenueShare({
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.isPlayerTeam,
    required this.tier,
    required this.primaryMarket,
    required this.equalBasePayoutEur,
    required this.meritPerformancePayoutEur,
    required this.viewershipPayoutEur,
    required this.grandTourAndMonumentBonusEur,
    required this.totalPayoutEur,
    required this.poolSharePercent,
    required this.meritScoreNormalized,
    required this.viewershipScoreNormalized,
    required this.projectedQuarterlyTrancheEur,
    required this.rankByRevenue,
    required this.deltaVsLastSeasonEur,
  });

  TeamBroadcastRevenueShare copyWith({
    int? rankByRevenue,
    double? totalPayoutEur,
    double? poolSharePercent,
    double? projectedQuarterlyTrancheEur,
    double? deltaVsLastSeasonEur,
  }) {
    final nextTotal = totalPayoutEur ?? this.totalPayoutEur;
    return TeamBroadcastRevenueShare(
      teamId: teamId,
      teamName: teamName,
      teamShortCode: teamShortCode,
      isPlayerTeam: isPlayerTeam,
      tier: tier,
      primaryMarket: primaryMarket,
      equalBasePayoutEur: equalBasePayoutEur,
      meritPerformancePayoutEur: meritPerformancePayoutEur,
      viewershipPayoutEur: viewershipPayoutEur,
      grandTourAndMonumentBonusEur: grandTourAndMonumentBonusEur,
      totalPayoutEur: nextTotal,
      poolSharePercent: poolSharePercent ?? this.poolSharePercent,
      meritScoreNormalized: meritScoreNormalized,
      viewershipScoreNormalized: viewershipScoreNormalized,
      projectedQuarterlyTrancheEur:
          projectedQuarterlyTrancheEur ?? (nextTotal / 4.0),
      rankByRevenue: rankByRevenue ?? this.rankByRevenue,
      deltaVsLastSeasonEur: deltaVsLastSeasonEur ?? this.deltaVsLastSeasonEur,
    );
  }

  Map<String, Object?> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'teamShortCode': teamShortCode,
        'isPlayerTeam': isPlayerTeam,
        'tier': tier.toJson(),
        'primaryMarket': primaryMarket.toJson(),
        'equalBasePayoutEur': equalBasePayoutEur,
        'meritPerformancePayoutEur': meritPerformancePayoutEur,
        'viewershipPayoutEur': viewershipPayoutEur,
        'grandTourAndMonumentBonusEur': grandTourAndMonumentBonusEur,
        'totalPayoutEur': totalPayoutEur,
        'poolSharePercent': poolSharePercent,
        'meritScoreNormalized': meritScoreNormalized,
        'viewershipScoreNormalized': viewershipScoreNormalized,
        'projectedQuarterlyTrancheEur': projectedQuarterlyTrancheEur,
        'rankByRevenue': rankByRevenue,
        'deltaVsLastSeasonEur': deltaVsLastSeasonEur,
      };

  factory TeamBroadcastRevenueShare.fromJson(Map<String, Object?> json) {
    return TeamBroadcastRevenueShare(
      teamId: json['teamId'] as String? ?? 'unknown_team',
      teamName: json['teamName'] as String? ?? 'Unknown Team',
      teamShortCode: json['teamShortCode'] as String? ?? 'UNK',
      isPlayerTeam: json['isPlayerTeam'] as bool? ?? false,
      tier: BroadcastTierCategory.fromJson(json['tier'] as String?),
      primaryMarket:
          BroadcastMarketRegion.fromJson(json['primaryMarket'] as String?),
      equalBasePayoutEur:
          (json['equalBasePayoutEur'] as num?)?.toDouble() ?? 0.0,
      meritPerformancePayoutEur:
          (json['meritPerformancePayoutEur'] as num?)?.toDouble() ?? 0.0,
      viewershipPayoutEur:
          (json['viewershipPayoutEur'] as num?)?.toDouble() ?? 0.0,
      grandTourAndMonumentBonusEur:
          (json['grandTourAndMonumentBonusEur'] as num?)?.toDouble() ?? 0.0,
      totalPayoutEur: (json['totalPayoutEur'] as num?)?.toDouble() ?? 0.0,
      poolSharePercent: (json['poolSharePercent'] as num?)?.toDouble() ?? 0.0,
      meritScoreNormalized:
          (json['meritScoreNormalized'] as num?)?.toDouble() ?? 0.0,
      viewershipScoreNormalized:
          (json['viewershipScoreNormalized'] as num?)?.toDouble() ?? 0.0,
      projectedQuarterlyTrancheEur:
          (json['projectedQuarterlyTrancheEur'] as num?)?.toDouble() ?? 0.0,
      rankByRevenue: (json['rankByRevenue'] as num?)?.toInt() ?? 0,
      deltaVsLastSeasonEur:
          (json['deltaVsLastSeasonEur'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Pełny raport sezonowego podziału przychodów z praw telewizyjnych WorldTour.
class SeasonBroadcastRevenueReport {
  final int seasonYear;
  final BroadcastPoolConfiguration config;
  final double totalDistributedEur;
  final double equalTrancheTotalEur;
  final double meritTrancheTotalEur;
  final double viewershipTrancheTotalEur;
  final double grandTourBonusTotalEur;
  final List<TeamBroadcastRevenueShare> teamShares;
  final TeamBroadcastRevenueShare? playerTeamShare;
  final double giniInequalityIndex;
  final double totalGlobalViewershipMillions;
  final String generatedAtIso;

  const SeasonBroadcastRevenueReport({
    required this.seasonYear,
    required this.config,
    required this.totalDistributedEur,
    required this.equalTrancheTotalEur,
    required this.meritTrancheTotalEur,
    required this.viewershipTrancheTotalEur,
    required this.grandTourBonusTotalEur,
    required this.teamShares,
    required this.playerTeamShare,
    required this.giniInequalityIndex,
    required this.totalGlobalViewershipMillions,
    required this.generatedAtIso,
  });

  Map<String, Object?> toJson() => {
        'seasonYear': seasonYear,
        'config': config.toJson(),
        'totalDistributedEur': totalDistributedEur,
        'equalTrancheTotalEur': equalTrancheTotalEur,
        'meritTrancheTotalEur': meritTrancheTotalEur,
        'viewershipTrancheTotalEur': viewershipTrancheTotalEur,
        'grandTourBonusTotalEur': grandTourBonusTotalEur,
        'teamShares': teamShares.map((e) => e.toJson()).toList(),
        'playerTeamShare': playerTeamShare?.toJson(),
        'giniInequalityIndex': giniInequalityIndex,
        'totalGlobalViewershipMillions': totalGlobalViewershipMillions,
        'generatedAtIso': generatedAtIso,
      };

  factory SeasonBroadcastRevenueReport.fromJson(Map<String, Object?> json) {
    final sharesRaw = json['teamShares'] as List<Object?>? ?? const [];
    final shares = sharesRaw
        .whereType<Map<String, Object?>>()
        .map(TeamBroadcastRevenueShare.fromJson)
        .toList();
    final playerRaw = json['playerTeamShare'] as Map<String, Object?>?;
    return SeasonBroadcastRevenueReport(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      config: BroadcastPoolConfiguration.fromJson(
        json['config'] as Map<String, Object?>? ?? const {},
      ),
      totalDistributedEur:
          (json['totalDistributedEur'] as num?)?.toDouble() ?? 0.0,
      equalTrancheTotalEur:
          (json['equalTrancheTotalEur'] as num?)?.toDouble() ?? 0.0,
      meritTrancheTotalEur:
          (json['meritTrancheTotalEur'] as num?)?.toDouble() ?? 0.0,
      viewershipTrancheTotalEur:
          (json['viewershipTrancheTotalEur'] as num?)?.toDouble() ?? 0.0,
      grandTourBonusTotalEur:
          (json['grandTourBonusTotalEur'] as num?)?.toDouble() ?? 0.0,
      teamShares: shares,
      playerTeamShare: playerRaw != null
          ? TeamBroadcastRevenueShare.fromJson(playerRaw)
          : null,
      giniInequalityIndex:
          (json['giniInequalityIndex'] as num?)?.toDouble() ?? 0.0,
      totalGlobalViewershipMillions:
          (json['totalGlobalViewershipMillions'] as num?)?.toDouble() ?? 0.0,
      generatedAtIso: json['generatedAtIso'] as String? ?? '',
    );
  }
}

/// Wynik symulacji "What-If" dodatkowej ekspozycji TV i punktów UCI dla drużyny.
class BroadcastWhatIfSimulationResult {
  final String teamId;
  final double baselinePayoutEur;
  final double projectedPayoutEur;
  final double netDeltaEur;
  final double extraExposureMinutes;
  final double extraUciPoints;
  final int baselineRank;
  final int projectedRank;

  const BroadcastWhatIfSimulationResult({
    required this.teamId,
    required this.baselinePayoutEur,
    required this.projectedPayoutEur,
    required this.netDeltaEur,
    required this.extraExposureMinutes,
    required this.extraUciPoints,
    required this.baselineRank,
    required this.projectedRank,
  });
}

/// Serwis wyliczający podział przychodów z praw telewizyjnych w cyklu WorldTour.
class TvBroadcastRightsRevenueSharingService {
  const TvBroadcastRightsRevenueSharingService();

  /// Oblicza pełny podział przychodów z praw TV dla wszystkich drużyn w sezonie.
  SeasonBroadcastRevenueReport calculateSeasonDistribution({
    required BroadcastPoolConfiguration config,
    required List<TeamBroadcastPerformanceInput> teams,
    Map<String, double> previousSeasonPayoutsEur = const {},
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc().toIso8601String();
    if (teams.isEmpty) {
      return SeasonBroadcastRevenueReport(
        seasonYear: config.seasonYear,
        config: config,
        totalDistributedEur: 0.0,
        equalTrancheTotalEur: 0.0,
        meritTrancheTotalEur: 0.0,
        viewershipTrancheTotalEur: 0.0,
        grandTourBonusTotalEur: 0.0,
        teamShares: const [],
        playerTeamShare: null,
        giniInequalityIndex: 0.0,
        totalGlobalViewershipMillions: 0.0,
        generatedAtIso: timestamp,
      );
    }

    final growth = config.safeGrowthMultiplier;
    final mainPool = config.safeBasePoolEur * growth;
    final gtBonusPool = config.safeGrandTourBonusEur * growth;
    final totalAvailablePool = mainPool + gtBonusPool;

    if (totalAvailablePool <= 0.0) {
      final zeroShares = [
        for (var i = 0; i < teams.length; i++)
          TeamBroadcastRevenueShare(
            teamId: teams[i].teamId,
            teamName: teams[i].teamName,
            teamShortCode: teams[i].teamShortCode,
            isPlayerTeam: teams[i].isPlayerTeam,
            tier: teams[i].tier,
            primaryMarket: teams[i].primaryMarket,
            equalBasePayoutEur: 0.0,
            meritPerformancePayoutEur: 0.0,
            viewershipPayoutEur: 0.0,
            grandTourAndMonumentBonusEur: 0.0,
            totalPayoutEur: 0.0,
            poolSharePercent: 0.0,
            meritScoreNormalized: 0.0,
            viewershipScoreNormalized: 0.0,
            projectedQuarterlyTrancheEur: 0.0,
            rankByRevenue: i + 1,
            deltaVsLastSeasonEur:
                -(previousSeasonPayoutsEur[teams[i].teamId] ?? 0.0),
          ),
      ];
      return SeasonBroadcastRevenueReport(
        seasonYear: config.seasonYear,
        config: config,
        totalDistributedEur: 0.0,
        equalTrancheTotalEur: 0.0,
        meritTrancheTotalEur: 0.0,
        viewershipTrancheTotalEur: 0.0,
        grandTourBonusTotalEur: 0.0,
        teamShares: zeroShares,
        playerTeamShare: zeroShares.cast<TeamBroadcastRevenueShare?>().firstWhere(
              (s) => s?.isPlayerTeam ?? false,
              orElse: () => null,
            ),
        giniInequalityIndex: 0.0,
        totalGlobalViewershipMillions: teams.fold<double>(
          0.0,
          (sum, t) => sum + t.safeAvgViewers,
        ),
        generatedAtIso: timestamp,
      );
    }

    final wtTeams = teams
        .where((t) => t.tier == BroadcastTierCategory.worldTourTier1)
        .toList();
    final proTeams = teams
        .where((t) => t.tier == BroadcastTierCategory.proTeamWildcard)
        .toList();

    final hasProTeams = proTeams.isNotEmpty && wtTeams.isNotEmpty;
    final wildcardReservePool =
        hasProTeams ? mainPool * config.safeWildcardRatio : 0.0;
    final wtMainPool = mainPool - wildcardReservePool;

    final totalEqualPool =
        wtMainPool * config.distributionModel.equalShareWeight +
            (hasProTeams
                ? wildcardReservePool *
                    config.distributionModel.equalShareWeight
                : 0.0);
    final totalMeritPool =
        wtMainPool * config.distributionModel.meritShareWeight +
            (hasProTeams
                ? wildcardReservePool *
                    config.distributionModel.meritShareWeight
                : 0.0);
    final totalViewershipPool =
        wtMainPool * config.distributionModel.viewershipShareWeight +
            (hasProTeams
                ? wildcardReservePool *
                    config.distributionModel.viewershipShareWeight
                : 0.0);

    // Sumy bazowe do normalizacji
    final totalMeritScoreAll = teams.fold<double>(
      0.0,
      (sum, t) => sum + t.rawMeritScore * t.tier.basePoolMultiplier,
    );
    final totalViewershipScoreAll = teams.fold<double>(
      0.0,
      (sum, t) => sum + t.rawViewershipScore * t.tier.basePoolMultiplier,
    );
    final totalPrestigeScoreAll = teams.fold<double>(
      0.0,
      (sum, t) => sum + t.rawPrestigeBonusScore,
    );

    final totalEqualWeight = teams.fold<double>(
      0.0,
      (sum, t) => sum + t.tier.basePoolMultiplier,
    );

    final maxMerit = teams.fold<double>(
      1.0,
      (m, t) => math.max(m, t.rawMeritScore),
    );
    final maxViewership = teams.fold<double>(
      1.0,
      (m, t) => math.max(m, t.rawViewershipScore),
    );

    final rawTotals = <double>[];
    final equalParts = <double>[];
    final meritParts = <double>[];
    final viewParts = <double>[];
    final gtBonusParts = <double>[];

    for (final team in teams) {
      final tierMult = team.tier.basePoolMultiplier;
      final equalPart = totalEqualWeight > 0.0
          ? totalEqualPool * (tierMult / totalEqualWeight)
          : totalEqualPool / teams.length;

      final meritPart = totalMeritScoreAll > 0.0
          ? totalMeritPool *
              ((team.rawMeritScore * tierMult) / totalMeritScoreAll)
          : totalMeritPool / teams.length;

      final viewPart = totalViewershipScoreAll > 0.0
          ? totalViewershipPool *
              ((team.rawViewershipScore * tierMult) / totalViewershipScoreAll)
          : totalViewershipPool / teams.length;

      final gtBonusPart = totalPrestigeScoreAll > 0.0
          ? gtBonusPool * (team.rawPrestigeBonusScore / totalPrestigeScoreAll)
          : (wtTeams.isNotEmpty &&
                  team.tier == BroadcastTierCategory.worldTourTier1)
              ? gtBonusPool / wtTeams.length
              : gtBonusPool / teams.length;

      equalParts.add(equalPart);
      meritParts.add(meritPart);
      viewParts.add(viewPart);
      gtBonusParts.add(gtBonusPart);
      rawTotals.add(equalPart + meritPart + viewPart + gtBonusPart);
    }

    // Zastosowanie limitu maksymalnego (anti-monopoly cap) oraz gwarantowanego minimum (floor)
    final adjustedTotals = _applyFloorAndCap(
      rawTotals: rawTotals,
      teams: teams,
      totalPool: totalAvailablePool,
      floorEur: config.safeMinimumFloorEur,
      capRatio: config.safeMaxTeamCapRatio,
    );

    final distributedSum = adjustedTotals.fold<double>(0.0, (s, v) => s + v);

    final unsortedShares = <TeamBroadcastRevenueShare>[];
    for (var i = 0; i < teams.length; i++) {
      final team = teams[i];
      final totalEur = adjustedTotals[i];
      final prevEur = previousSeasonPayoutsEur[team.teamId] ?? totalEur;
      final sharePct =
          distributedSum > 0.0 ? (totalEur / distributedSum) * 100.0 : 0.0;

      unsortedShares.add(
        TeamBroadcastRevenueShare(
          teamId: team.teamId,
          teamName: team.teamName,
          teamShortCode: team.teamShortCode,
          isPlayerTeam: team.isPlayerTeam,
          tier: team.tier,
          primaryMarket: team.primaryMarket,
          equalBasePayoutEur: equalParts[i],
          meritPerformancePayoutEur: meritParts[i],
          viewershipPayoutEur: viewParts[i],
          grandTourAndMonumentBonusEur: gtBonusParts[i],
          totalPayoutEur: totalEur,
          poolSharePercent: sharePct,
          meritScoreNormalized: (team.rawMeritScore / maxMerit).clamp(0.0, 1.0),
          viewershipScoreNormalized:
              (team.rawViewershipScore / maxViewership).clamp(0.0, 1.0),
          projectedQuarterlyTrancheEur: totalEur / 4.0,
          rankByRevenue: 0,
          deltaVsLastSeasonEur: totalEur - prevEur,
        ),
      );
    }

    unsortedShares.sort((a, b) => b.totalPayoutEur.compareTo(a.totalPayoutEur));

    final rankedShares = <TeamBroadcastRevenueShare>[
      for (var i = 0; i < unsortedShares.length; i++)
        unsortedShares[i].copyWith(rankByRevenue: i + 1),
    ];

    final playerShare = rankedShares
        .cast<TeamBroadcastRevenueShare?>()
        .firstWhere((s) => s?.isPlayerTeam ?? false, orElse: () => null);

    final gini = _calculateGiniIndex(
      rankedShares.map((s) => s.totalPayoutEur).toList(),
    );

    final globalViewership = teams.fold<double>(
      0.0,
      (sum, t) => sum + t.safeAvgViewers,
    );

    return SeasonBroadcastRevenueReport(
      seasonYear: config.seasonYear,
      config: config,
      totalDistributedEur: distributedSum,
      equalTrancheTotalEur: equalParts.fold<double>(0.0, (s, v) => s + v),
      meritTrancheTotalEur: meritParts.fold<double>(0.0, (s, v) => s + v),
      viewershipTrancheTotalEur: viewParts.fold<double>(0.0, (s, v) => s + v),
      grandTourBonusTotalEur: gtBonusParts.fold<double>(0.0, (s, v) => s + v),
      teamShares: rankedShares,
      playerTeamShare: playerShare,
      giniInequalityIndex: gini,
      totalGlobalViewershipMillions: globalViewership,
      generatedAtIso: timestamp,
    );
  }

  /// Symulacja wpływu dodatkowej ekspozycji TV i punktów UCI na wypłatę drużyny.
  BroadcastWhatIfSimulationResult simulateViewershipImpact({
    required String targetTeamId,
    required double extraExposureMinutes,
    required double extraUciPoints,
    int extraGrandTourStageWins = 0,
    required BroadcastPoolConfiguration config,
    required List<TeamBroadcastPerformanceInput> teams,
  }) {
    final safeExtraMinutes = _sanitizeNonNegative(extraExposureMinutes);
    final safeExtraPoints = _sanitizeNonNegative(extraUciPoints);
    final safeExtraStages =
        extraGrandTourStageWins < 0 ? 0 : extraGrandTourStageWins;

    final baseline = calculateSeasonDistribution(config: config, teams: teams);
    final baseShare = baseline.teamShares.cast<TeamBroadcastRevenueShare?>().firstWhere(
          (s) => s?.teamId == targetTeamId,
          orElse: () => null,
        );

    if (baseShare == null) {
      return BroadcastWhatIfSimulationResult(
        teamId: targetTeamId,
        baselinePayoutEur: 0.0,
        projectedPayoutEur: 0.0,
        netDeltaEur: 0.0,
        extraExposureMinutes: safeExtraMinutes,
        extraUciPoints: safeExtraPoints,
        baselineRank: 0,
        projectedRank: 0,
      );
    }

    final modifiedTeams = teams.map((t) {
      if (t.teamId != targetTeamId) return t;
      // Każde 60 minut dodatkowej ekspozycji w ucieczkach podbija średnią oglądalność o ~4%
      final viewerBoost = 1.0 + (safeExtraMinutes / 1500.0).clamp(0.0, 0.35);
      return t.copyWith(
        tvExposureMinutes: t.safeTvExposureMinutes + safeExtraMinutes,
        uciSeasonPoints: t.safeUciPoints + safeExtraPoints,
        grandTourStageWins: t.safeGrandTourStageWins + safeExtraStages,
        averageViewersMillions: t.safeAvgViewers * viewerBoost,
      );
    }).toList();

    final projected =
        calculateSeasonDistribution(config: config, teams: modifiedTeams);
    final projShare =
        projected.teamShares.cast<TeamBroadcastRevenueShare?>().firstWhere(
              (s) => s?.teamId == targetTeamId,
              orElse: () => null,
            );

    final projectedEur = projShare?.totalPayoutEur ?? baseShare.totalPayoutEur;
    final projectedRank = projShare?.rankByRevenue ?? baseShare.rankByRevenue;

    return BroadcastWhatIfSimulationResult(
      teamId: targetTeamId,
      baselinePayoutEur: baseShare.totalPayoutEur,
      projectedPayoutEur: projectedEur,
      netDeltaEur: projectedEur - baseShare.totalPayoutEur,
      extraExposureMinutes: safeExtraMinutes,
      extraUciPoints: safeExtraPoints,
      baselineRank: baseShare.rankByRevenue,
      projectedRank: projectedRank,
    );
  }

  List<double> _applyFloorAndCap({
    required List<double> rawTotals,
    required List<TeamBroadcastPerformanceInput> teams,
    required double totalPool,
    required double floorEur,
    required double capRatio,
  }) {
    if (rawTotals.isEmpty || totalPool <= 0.0) return rawTotals;
    final count = rawTotals.length;
    final adjusted = List<double>.from(rawTotals);

    final maxCapEur = totalPool * capRatio;
    final effectiveFloor = math.min(floorEur, totalPool / (count * 1.5));

    // 1. Egzekwowanie sufitu (anti-monopoly cap) z redystrybucją nadwyżki
    var excess = 0.0;
    final uncappedIndices = <int>[];
    for (var i = 0; i < count; i++) {
      if (adjusted[i] > maxCapEur) {
        excess += adjusted[i] - maxCapEur;
        adjusted[i] = maxCapEur;
      } else {
        uncappedIndices.add(i);
      }
    }
    if (excess > 0.0 && uncappedIndices.isNotEmpty) {
      final perUncapped = excess / uncappedIndices.length;
      for (final idx in uncappedIndices) {
        adjusted[idx] = math.min(maxCapEur, adjusted[idx] + perUncapped);
      }
    }

    // 2. Egzekwowanie gwarantowanego minimum dla drużyn WorldTour
    var deficit = 0.0;
    final donors = <int>[];
    for (var i = 0; i < count; i++) {
      final teamFloor = teams[i].tier == BroadcastTierCategory.worldTourTier1
          ? effectiveFloor
          : effectiveFloor * 0.35;
      if (adjusted[i] < teamFloor) {
        deficit += teamFloor - adjusted[i];
        adjusted[i] = teamFloor;
      } else if (adjusted[i] > teamFloor * 1.2) {
        donors.add(i);
      }
    }
    if (deficit > 0.0 && donors.isNotEmpty) {
      final donorSum = donors.fold<double>(0.0, (s, idx) => s + adjusted[idx]);
      if (donorSum > deficit) {
        for (final idx in donors) {
          adjusted[idx] -= deficit * (adjusted[idx] / donorSum);
        }
      }
    }

    // 3. Normalizacja końcowa dokładnie do sumy totalPool
    final currentSum = adjusted.fold<double>(0.0, (s, v) => s + v);
    if (currentSum > 0.0) {
      final scale = totalPool / currentSum;
      for (var i = 0; i < count; i++) {
        adjusted[i] *= scale;
      }
    }

    return adjusted;
  }

  double _calculateGiniIndex(List<double> values) {
    final n = values.length;
    if (n <= 1) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final sum = sorted.fold<double>(0.0, (s, v) => s + v);
    if (sum <= 0.0) return 0.0;

    var weightedSum = 0.0;
    for (var i = 0; i < n; i++) {
      weightedSum += (i + 1) * sorted[i];
    }
    final gini = ((2.0 * weightedSum) / (n * sum)) - ((n + 1.0) / n);
    return gini.clamp(0.0, 1.0);
  }

  /// Tworzy realistyczną stawkę 12 drużyn WorldTour + 2 ProTeam Wildcard do testów i podglądu.
  static List<TeamBroadcastPerformanceInput> createSampleWorldTourGrid() {
    return const [
      TeamBroadcastPerformanceInput(
        teamId: 'uae_emirates',
        teamName: 'UAE Team Emirates XRG',
        teamShortCode: 'UAD',
        uciSeasonPoints: 24600,
        worldTourWins: 38,
        grandTourStageWins: 11,
        monumentWins: 3,
        leaderJerseyDays: 34,
        averageViewersMillions: 4.85,
        peakViewersMillions: 11.4,
        tvExposureMinutes: 1420,
        socialMediaEngagementIndex: 96,
        primaryMarket: BroadcastMarketRegion.globalStreaming,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'visma_lab',
        teamName: 'Team Visma | Lease a Bike',
        teamShortCode: 'TVL',
        uciSeasonPoints: 20400,
        worldTourWins: 29,
        grandTourStageWins: 8,
        monumentWins: 1,
        leaderJerseyDays: 22,
        averageViewersMillions: 4.50,
        peakViewersMillions: 10.6,
        tvExposureMinutes: 1290,
        socialMediaEngagementIndex: 92,
        primaryMarket: BroadcastMarketRegion.europeWest,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'player_team',
        teamName: 'Polonia Pro Cycling',
        teamShortCode: 'POL',
        isPlayerTeam: true,
        uciSeasonPoints: 13850,
        worldTourWins: 16,
        grandTourStageWins: 4,
        monumentWins: 1,
        leaderJerseyDays: 11,
        averageViewersMillions: 3.15,
        peakViewersMillions: 7.8,
        tvExposureMinutes: 980,
        socialMediaEngagementIndex: 84,
        primaryMarket: BroadcastMarketRegion.europeNorthEast,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'alpecin_deceuninck',
        teamName: 'Alpecin-Deceuninck',
        teamShortCode: 'ADC',
        uciSeasonPoints: 16100,
        worldTourWins: 24,
        grandTourStageWins: 5,
        monumentWins: 2,
        leaderJerseyDays: 9,
        averageViewersMillions: 3.90,
        peakViewersMillions: 9.2,
        tvExposureMinutes: 1110,
        socialMediaEngagementIndex: 88,
        primaryMarket: BroadcastMarketRegion.europeWest,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'soudal_quickstep',
        teamName: 'Soudal Quick-Step',
        teamShortCode: 'SOQ',
        uciSeasonPoints: 15400,
        worldTourWins: 21,
        grandTourStageWins: 4,
        monumentWins: 1,
        leaderJerseyDays: 14,
        averageViewersMillions: 3.70,
        peakViewersMillions: 8.5,
        tvExposureMinutes: 1040,
        socialMediaEngagementIndex: 86,
        primaryMarket: BroadcastMarketRegion.europeWest,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'ineos_grenadiers',
        teamName: 'INEOS Grenadiers',
        teamShortCode: 'IGD',
        uciSeasonPoints: 12900,
        worldTourWins: 14,
        grandTourStageWins: 3,
        monumentWins: 0,
        leaderJerseyDays: 7,
        averageViewersMillions: 3.45,
        peakViewersMillions: 8.1,
        tvExposureMinutes: 920,
        socialMediaEngagementIndex: 81,
        primaryMarket: BroadcastMarketRegion.globalStreaming,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'lidl_trek',
        teamName: 'Lidl-Trek',
        teamShortCode: 'LTK',
        uciSeasonPoints: 14700,
        worldTourWins: 22,
        grandTourStageWins: 5,
        monumentWins: 0,
        leaderJerseyDays: 10,
        averageViewersMillions: 3.20,
        peakViewersMillions: 7.4,
        tvExposureMinutes: 960,
        socialMediaEngagementIndex: 80,
        primaryMarket: BroadcastMarketRegion.americas,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'red_bull_bora',
        teamName: 'Red Bull - BORA - hansgrohe',
        teamShortCode: 'RBH',
        uciSeasonPoints: 14100,
        worldTourWins: 17,
        grandTourStageWins: 4,
        monumentWins: 0,
        leaderJerseyDays: 12,
        averageViewersMillions: 3.35,
        peakViewersMillions: 7.9,
        tvExposureMinutes: 940,
        socialMediaEngagementIndex: 85,
        primaryMarket: BroadcastMarketRegion.europeWest,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'groupama_fdj',
        teamName: 'Groupama-FDJ',
        teamShortCode: 'GFC',
        uciSeasonPoints: 9800,
        worldTourWins: 10,
        grandTourStageWins: 2,
        monumentWins: 0,
        leaderJerseyDays: 4,
        averageViewersMillions: 2.80,
        peakViewersMillions: 6.7,
        tvExposureMinutes: 790,
        socialMediaEngagementIndex: 72,
        primaryMarket: BroadcastMarketRegion.europeWest,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'jayco_alula',
        teamName: 'Team Jayco AlUla',
        teamShortCode: 'JAY',
        uciSeasonPoints: 8900,
        worldTourWins: 9,
        grandTourStageWins: 2,
        monumentWins: 0,
        leaderJerseyDays: 2,
        averageViewersMillions: 2.10,
        peakViewersMillions: 5.1,
        tvExposureMinutes: 640,
        socialMediaEngagementIndex: 66,
        primaryMarket: BroadcastMarketRegion.asiaPacific,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'dsm_firmenich',
        teamName: 'Team dsm-firmenich PostNL',
        teamShortCode: 'DFP',
        uciSeasonPoints: 7400,
        worldTourWins: 7,
        grandTourStageWins: 1,
        monumentWins: 0,
        leaderJerseyDays: 1,
        averageViewersMillions: 1.85,
        peakViewersMillions: 4.3,
        tvExposureMinutes: 590,
        socialMediaEngagementIndex: 62,
        primaryMarket: BroadcastMarketRegion.europeWest,
        isRelegationZone: true,
      ),
      TeamBroadcastPerformanceInput(
        teamId: 'uno_x_wildcard',
        teamName: 'Uno-X Mobility',
        teamShortCode: 'UXM',
        tier: BroadcastTierCategory.proTeamWildcard,
        uciSeasonPoints: 6800,
        worldTourWins: 5,
        grandTourStageWins: 1,
        monumentWins: 0,
        leaderJerseyDays: 0,
        averageViewersMillions: 1.95,
        peakViewersMillions: 4.9,
        tvExposureMinutes: 820,
        socialMediaEngagementIndex: 74,
        primaryMarket: BroadcastMarketRegion.europeNorthEast,
      ),
    ];
  }
}

/// Stan Riverpod dla systemu podziału przychodów z praw telewizyjnych.
class TvBroadcastRevenueState {
  final BroadcastPoolConfiguration config;
  final List<TeamBroadcastPerformanceInput> teams;
  final SeasonBroadcastRevenueReport? latestReport;
  final Map<String, double> previousSeasonPayoutsEur;
  final String? selectedTeamId;
  final double whatIfExtraExposureMinutes;
  final double whatIfExtraUciPoints;
  final BroadcastWhatIfSimulationResult? whatIfResult;
  final bool isReadOnly;

  const TvBroadcastRevenueState({
    this.config = const BroadcastPoolConfiguration(),
    this.teams = const [],
    this.latestReport,
    this.previousSeasonPayoutsEur = const {},
    this.selectedTeamId,
    this.whatIfExtraExposureMinutes = 120.0,
    this.whatIfExtraUciPoints = 1500.0,
    this.whatIfResult,
    this.isReadOnly = false,
  });

  TvBroadcastRevenueState copyWith({
    BroadcastPoolConfiguration? config,
    List<TeamBroadcastPerformanceInput>? teams,
    SeasonBroadcastRevenueReport? latestReport,
    Map<String, double>? previousSeasonPayoutsEur,
    String? selectedTeamId,
    bool clearSelectedTeam = false,
    double? whatIfExtraExposureMinutes,
    double? whatIfExtraUciPoints,
    BroadcastWhatIfSimulationResult? whatIfResult,
    bool clearWhatIfResult = false,
    bool? isReadOnly,
  }) {
    return TvBroadcastRevenueState(
      config: config ?? this.config,
      teams: teams ?? this.teams,
      latestReport: latestReport ?? this.latestReport,
      previousSeasonPayoutsEur:
          previousSeasonPayoutsEur ?? this.previousSeasonPayoutsEur,
      selectedTeamId:
          clearSelectedTeam ? null : (selectedTeamId ?? this.selectedTeamId),
      whatIfExtraExposureMinutes:
          whatIfExtraExposureMinutes ?? this.whatIfExtraExposureMinutes,
      whatIfExtraUciPoints: whatIfExtraUciPoints ?? this.whatIfExtraUciPoints,
      whatIfResult:
          clearWhatIfResult ? null : (whatIfResult ?? this.whatIfResult),
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}

/// Kontroler stanu Riverpod dla modułu podziału praw TV WorldTour.
class TvBroadcastRevenueNotifier
    extends StateNotifier<TvBroadcastRevenueState> {
  final TvBroadcastRightsRevenueSharingService _service;

  TvBroadcastRevenueNotifier({
    TvBroadcastRightsRevenueSharingService service =
        const TvBroadcastRightsRevenueSharingService(),
    TvBroadcastRevenueState? initialState,
  })  : _service = service,
        super(initialState ?? const TvBroadcastRevenueState()) {
    if (state.teams.isNotEmpty && state.latestReport == null) {
      recalculate();
    }
  }

  void loadSampleWorldTourSeason() {
    final sampleTeams =
        TvBroadcastRightsRevenueSharingService.createSampleWorldTourGrid();
    final playerTeam = sampleTeams.firstWhere(
      (t) => t.isPlayerTeam,
      orElse: () => sampleTeams.first,
    );
    state = state.copyWith(
      teams: sampleTeams,
      selectedTeamId: playerTeam.teamId,
    );
    recalculate();
  }

  void setTeams(
    List<TeamBroadcastPerformanceInput> teams, {
    Map<String, double>? previousSeasonPayoutsEur,
  }) {
    final nextSelected = teams.any((t) => t.teamId == state.selectedTeamId)
        ? state.selectedTeamId
        : (teams.isNotEmpty
            ? teams
                .firstWhere(
                  (t) => t.isPlayerTeam,
                  orElse: () => teams.first,
                )
                .teamId
            : null);

    state = state.copyWith(
      teams: teams,
      previousSeasonPayoutsEur:
          previousSeasonPayoutsEur ?? state.previousSeasonPayoutsEur,
      selectedTeamId: nextSelected,
      clearSelectedTeam: nextSelected == null,
    );
    recalculate();
  }

  void setDistributionModel(BroadcastDistributionModel model) {
    if (state.isReadOnly) return;
    state = state.copyWith(
      config: state.config.copyWith(distributionModel: model),
    );
    recalculate();
  }

  void setViewershipGrowthMultiplier(double multiplier) {
    if (state.isReadOnly) return;
    state = state.copyWith(
      config: state.config.copyWith(
        viewershipGrowthMultiplier: multiplier.clamp(0.6, 1.8),
      ),
    );
    recalculate();
  }

  void setTotalPoolEur(double totalPoolEur) {
    if (state.isReadOnly) return;
    state = state.copyWith(
      config: state.config.copyWith(
        totalWorldTourPoolEur: totalPoolEur.clamp(1000000.0, 250000000.0),
      ),
    );
    recalculate();
  }

  void selectTeam(String? teamId) {
    state = state.copyWith(
      selectedTeamId: teamId,
      clearSelectedTeam: teamId == null,
    );
    _recomputeWhatIf();
  }

  void updateWhatIfSimulation({
    double? extraExposureMinutes,
    double? extraUciPoints,
  }) {
    if (state.isReadOnly) return;
    state = state.copyWith(
      whatIfExtraExposureMinutes:
          extraExposureMinutes ?? state.whatIfExtraExposureMinutes,
      whatIfExtraUciPoints: extraUciPoints ?? state.whatIfExtraUciPoints,
    );
    _recomputeWhatIf();
  }

  void setReadOnly(bool readOnly) {
    state = state.copyWith(isReadOnly: readOnly);
  }

  void recalculate() {
    final report = _service.calculateSeasonDistribution(
      config: state.config,
      teams: state.teams,
      previousSeasonPayoutsEur: state.previousSeasonPayoutsEur,
    );
    state = state.copyWith(latestReport: report);
    _recomputeWhatIf();
  }

  void _recomputeWhatIf() {
    final targetId = state.selectedTeamId;
    if (targetId == null || state.teams.isEmpty) {
      state = state.copyWith(clearWhatIfResult: true);
      return;
    }
    final result = _service.simulateViewershipImpact(
      targetTeamId: targetId,
      extraExposureMinutes: state.whatIfExtraExposureMinutes,
      extraUciPoints: state.whatIfExtraUciPoints,
      config: state.config,
      teams: state.teams,
    );
    state = state.copyWith(whatIfResult: result);
  }
}

final tvBroadcastRevenueProvider =
    StateNotifierProvider<TvBroadcastRevenueNotifier, TvBroadcastRevenueState>(
  (ref) => TvBroadcastRevenueNotifier()..loadSampleWorldTourSeason(),
);

/// Produkcyjny panel UI zarządzania podziałem przychodów z praw TV WorldTour.
class TvBroadcastRightsRevenuePanel extends ConsumerStatefulWidget {
  final bool compact;

  const TvBroadcastRightsRevenuePanel({
    super.key,
    this.compact = false,
  });

  @override
  ConsumerState<TvBroadcastRightsRevenuePanel> createState() =>
      _TvBroadcastRightsRevenuePanelState();
}

class _TvBroadcastRightsRevenuePanelState
    extends ConsumerState<TvBroadcastRightsRevenuePanel> {
  String? _hoveredModelId;
  String? _focusedModelId;
  String? _hoveredTeamId;
  String? _focusedTeamId;

  String _formatEur(double amount) {
    if (amount >= 1000000.0) {
      return '${(amount / 1000000.0).toStringAsFixed(2)} M €';
    }
    if (amount >= 1000.0) {
      return '${(amount / 1000.0).toStringAsFixed(0)} tys. €';
    }
    return '${amount.toStringAsFixed(0)} €';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tvBroadcastRevenueProvider);
    final notifier = ref.read(tvBroadcastRevenueProvider.notifier);
    final report = state.latestReport;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 800;
        final isMobile = width < 640;
        final isTablet = width >= 640 && width < 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(state, report, notifier, isMobile),
                const SizedBox(height: 16),
                if (report == null || report.teamShares.isEmpty)
                  _buildEmptyState(state, notifier)
                else ...[
                  _buildModelSelectorCard(state, notifier, isMobile),
                  const SizedBox(height: 16),
                  if (isMobile || isTablet || widget.compact) ...[
                    _buildSelectedTeamBreakdownCard(state, report, isMobile),
                    const SizedBox(height: 16),
                    _buildWhatIfSimulatorCard(state, notifier, isMobile),
                    const SizedBox(height: 16),
                    _buildLeaderboardCard(state, report, notifier, isMobile),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildSelectedTeamBreakdownCard(
                                state,
                                report,
                                false,
                              ),
                              const SizedBox(height: 16),
                              _buildWhatIfSimulatorCard(
                                state,
                                notifier,
                                false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 7,
                          child: _buildLeaderboardCard(
                            state,
                            report,
                            notifier,
                            false,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    TvBroadcastRevenueState state,
    SeasonBroadcastRevenueReport? report,
    TvBroadcastRevenueNotifier notifier,
    bool isMobile,
  ) {
    final totalPool = report?.totalDistributedEur ?? 0.0;
    final playerPayout = report?.playerTeamShare?.totalPayoutEur ?? 0.0;
    final gini = report?.giniInequalityIndex ?? 0.0;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
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
                      'Prawa Telewizyjne WorldTour ${state.config.seasonYear}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Podział przychodów wg oglądalności TV i wyników sportowych UCI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 12 : 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isReadOnly)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Text(
                    'TYLKO ODCZYT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiMetricTile(
                label: 'Całkowita Pula TV',
                value: _formatEur(totalPool),
                accentColor: AppColors.accentBlue,
              ),
              _KpiMetricTile(
                label: 'Wypłata Twojej Drużyny',
                value: _formatEur(playerPayout),
                accentColor: AppColors.goldAccent,
              ),
              _KpiMetricTile(
                label: 'Widownia Globalna',
                value:
                    '${(report?.totalGlobalViewershipMillions ?? 0.0).toStringAsFixed(1)} M',
                accentColor: AppColors.statusSuccess,
              ),
              _KpiMetricTile(
                label: 'Indeks Giniego (Balans)',
                value: gini.toStringAsFixed(3),
                accentColor: gini > 0.35
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelectorCard(
    TvBroadcastRevenueState state,
    TvBroadcastRevenueNotifier notifier,
    bool isMobile,
  ) {
    final disabled = state.isReadOnly;

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
            'Algorytm Podziału Puli Praw TV',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BroadcastDistributionModel.values.map((model) {
              final isSelected = state.config.distributionModel == model;
              final isHovered = _hoveredModelId == model.name;
              final isFocused = _focusedModelId == model.name;

              return FocusableActionDetector(
                enabled: !disabled,
                onShowHoverHighlight: (hover) {
                  setState(() => _hoveredModelId = hover ? model.name : null);
                },
                onShowFocusHighlight: (focus) {
                  setState(() => _focusedModelId = focus ? model.name : null);
                },
                child: Tooltip(
                  message: model.descriptionPl,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: disabled
                        ? null
                        : () => notifier.setDistributionModel(model),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: disabled
                            ? AppColors.surfaceLight.withValues(alpha: 0.4)
                            : isSelected
                                ? AppColors.primaryAccent.withValues(alpha: 0.28)
                                : isHovered
                                    ? AppColors.surfaceLight
                                    : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFocused
                              ? AppColors.goldAccent
                              : isSelected
                                  ? AppColors.primaryAccent
                                  : isHovered
                                      ? AppColors.accentBlue
                                          .withValues(alpha: 0.5)
                                      : AppColors.cardBorder,
                          width: isSelected || isFocused ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            model.displayNamePl,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: disabled
                                  ? AppColors.textSecondary
                                      .withValues(alpha: 0.5)
                                  : isSelected
                                      ? AppColors.goldAccent
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            model.descriptionPl,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: disabled
                                  ? AppColors.textSecondary
                                      .withValues(alpha: 0.4)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mnożnik koniunktury rynku TV',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${(state.config.safeGrowthMultiplier * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:
                  disabled ? AppColors.cardBorder : AppColors.accentBlue,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor:
                  disabled ? AppColors.textSecondary : AppColors.goldAccent,
            ),
            child: Slider(
              value: state.config.safeGrowthMultiplier.clamp(0.7, 1.5),
              min: 0.7,
              max: 1.5,
              divisions: 16,
              onChanged: disabled
                  ? null
                  : (v) => notifier.setViewershipGrowthMultiplier(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTeamBreakdownCard(
    TvBroadcastRevenueState state,
    SeasonBroadcastRevenueReport report,
    bool isMobile,
  ) {
    final share = report.teamShares.cast<TeamBroadcastRevenueShare?>().firstWhere(
          (s) => s?.teamId == state.selectedTeamId,
          orElse: () => report.playerTeamShare ?? report.teamShares.first,
        );
    if (share == null) return const SizedBox.shrink();

    final total = share.totalPayoutEur > 0 ? share.totalPayoutEur : 1.0;
    final eqRatio = (share.equalBasePayoutEur / total).clamp(0.0, 1.0);
    final meritRatio =
        (share.meritPerformancePayoutEur / total).clamp(0.0, 1.0);
    final viewRatio = (share.viewershipPayoutEur / total).clamp(0.0, 1.0);
    final gtRatio =
        (share.grandTourAndMonumentBonusEur / total).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: share.isPlayerTeam
              ? AppColors.goldAccent.withValues(alpha: 0.6)
              : AppColors.cardBorder,
          width: 1.0,
        ),
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
                      share.teamName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pozycja #${share.rankByRevenue} • ${share.tier.displayNamePl} • ${share.primaryMarket.displayNamePl}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatEur(share.totalPayoutEur),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (eqRatio > 0.0)
                    Expanded(
                      flex: math.max(1, (eqRatio * 1000).round()),
                      child: Container(color: AppColors.textSecondary),
                    ),
                  if (meritRatio > 0.0)
                    Expanded(
                      flex: math.max(1, (meritRatio * 1000).round()),
                      child: Container(color: AppColors.accentBlue),
                    ),
                  if (viewRatio > 0.0)
                    Expanded(
                      flex: math.max(1, (viewRatio * 1000).round()),
                      child: Container(color: AppColors.statusSuccess),
                    ),
                  if (gtRatio > 0.0)
                    Expanded(
                      flex: math.max(1, (gtRatio * 1000).round()),
                      child: Container(color: AppColors.goldAccent),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            color: AppColors.textSecondary,
            label: 'Równa baza licencyjna',
            value: _formatEur(share.equalBasePayoutEur),
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            color: AppColors.accentBlue,
            label: 'Premia za wyniki sportowe UCI',
            value: _formatEur(share.meritPerformancePayoutEur),
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            color: AppColors.statusSuccess,
            label: 'Udział z oglądalności i czasu TV',
            value: _formatEur(share.viewershipPayoutEur),
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            color: AppColors.goldAccent,
            label: 'Bonus Grand Tour & Monumenty',
            value: _formatEur(share.grandTourAndMonumentBonusEur),
          ),
          const Divider(color: AppColors.cardBorder, height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transza kwartalna (co 3 mies.)',
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
                _formatEur(share.projectedQuarterlyTrancheEur),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIfSimulatorCard(
    TvBroadcastRevenueState state,
    TvBroadcastRevenueNotifier notifier,
    bool isMobile,
  ) {
    final disabled = state.isReadOnly;
    final sim = state.whatIfResult;

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
            'Symulator Wpływu Ekspozycji TV i Punktów UCI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dodatkowy czas w ucieczce TV',
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
                '+${state.whatIfExtraExposureMinutes.toStringAsFixed(0)} min',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:
                  disabled ? AppColors.cardBorder : AppColors.statusSuccess,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor:
                  disabled ? AppColors.textSecondary : AppColors.statusSuccess,
            ),
            child: Slider(
              value: state.whatIfExtraExposureMinutes.clamp(0.0, 600.0),
              min: 0.0,
              max: 600.0,
              divisions: 12,
              onChanged: disabled
                  ? null
                  : (v) => notifier.updateWhatIfSimulation(
                        extraExposureMinutes: v,
                      ),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dodatkowe punkty UCI WorldTour',
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
                '+${state.whatIfExtraUciPoints.toStringAsFixed(0)} pkt',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:
                  disabled ? AppColors.cardBorder : AppColors.accentBlue,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor:
                  disabled ? AppColors.textSecondary : AppColors.accentBlue,
            ),
            child: Slider(
              value: state.whatIfExtraUciPoints.clamp(0.0, 6000.0),
              min: 0.0,
              max: 6000.0,
              divisions: 12,
              onChanged: disabled
                  ? null
                  : (v) => notifier.updateWhatIfSimulation(extraUciPoints: v),
            ),
          ),
          if (sim != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prognozowany zysk z praw TV',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Pozycja: #${sim.baselineRank} -> #${sim.projectedRank}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${_formatEur(sim.netDeltaEur)}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.statusSuccess,
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

  Widget _buildLeaderboardCard(
    TvBroadcastRevenueState state,
    SeasonBroadcastRevenueReport report,
    TvBroadcastRevenueNotifier notifier,
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ranking Wypłat z Praw TV WorldTour',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${report.teamShares.length} drużyn',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.teamShares.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = report.teamShares[index];
              final isSelected = state.selectedTeamId == item.teamId;
              final isHovered = _hoveredTeamId == item.teamId;
              final isFocused = _focusedTeamId == item.teamId;

              return FocusableActionDetector(
                onShowHoverHighlight: (h) {
                  setState(() => _hoveredTeamId = h ? item.teamId : null);
                },
                onShowFocusHighlight: (f) {
                  setState(() => _focusedTeamId = f ? item.teamId : null);
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => notifier.selectTeam(item.teamId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryAccent.withValues(alpha: 0.22)
                          : isHovered
                              ? AppColors.surfaceLight
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFocused
                            ? AppColors.goldAccent
                            : isSelected
                                ? AppColors.goldAccent
                                : item.isPlayerTeam
                                    ? AppColors.primaryAccent
                                    : AppColors.cardBorder,
                        width: isSelected || isFocused ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '#${item.rankByRevenue}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: item.rankByRevenue <= 3
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.teamName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: item.isPlayerTeam
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: item.isPlayerTeam
                                            ? AppColors.goldAccent
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (item.isPlayerTeam) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldAccent
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'TY',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.goldAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.tier.displayNamePl} • ${item.poolSharePercent.toStringAsFixed(1)}% puli',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatEur(item.totalPayoutEur),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    TvBroadcastRevenueState state,
    TvBroadcastRevenueNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.tv_off_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Brak danych drużyn dla bieżącego cyklu praw TV',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                state.isReadOnly ? null : notifier.loadSampleWorldTourSeason,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.surfaceLight,
              disabledForegroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Załaduj stawkę WorldTour',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _KpiMetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
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
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
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

class _BreakdownRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _BreakdownRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
