import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/lactate_and_lab_profile.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_power_profile.dart';
import '../generators/rider_procedural_generator.dart';
import 'scouting_and_youth_academy_service.dart';

/// 8 kluczowych regionów kolarskich świata dla siatek skautingowych.
enum ScoutingRegionId {
  sloveniaBalkans,
  flandersBelgium,
  colombiaAndes,
  france,
  italy,
  scandinavia,
  ukAustralia,
  iberianPeninsula;

  String toJson() => name;

  static ScoutingRegionId fromJson(String value) {
    return ScoutingRegionId.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScoutingRegionId.flandersBelgium,
    );
  }

  String get label {
    switch (this) {
      case ScoutingRegionId.sloveniaBalkans:
        return 'Słowenia / Bałkany';
      case ScoutingRegionId.flandersBelgium:
        return 'Flandria / Belgia';
      case ScoutingRegionId.colombiaAndes:
        return 'Kolumbia / Andy';
      case ScoutingRegionId.france:
        return 'Francja';
      case ScoutingRegionId.italy:
        return 'Włochy';
      case ScoutingRegionId.scandinavia:
        return 'Skandynawia';
      case ScoutingRegionId.ukAustralia:
        return 'Wielka Brytania / Australia';
      case ScoutingRegionId.iberianPeninsula:
        return 'Półwysep Iberyjski';
    }
  }

  String get shortLabel {
    switch (this) {
      case ScoutingRegionId.sloveniaBalkans:
        return 'Bałkany';
      case ScoutingRegionId.flandersBelgium:
        return 'Flandria';
      case ScoutingRegionId.colombiaAndes:
        return 'Andy';
      case ScoutingRegionId.france:
        return 'Francja';
      case ScoutingRegionId.italy:
        return 'Włochy';
      case ScoutingRegionId.scandinavia:
        return 'Skandynawia';
      case ScoutingRegionId.ukAustralia:
        return 'UK / AUS';
      case ScoutingRegionId.iberianPeninsula:
        return 'Iberia';
    }
  }

  String get regionCode {
    switch (this) {
      case ScoutingRegionId.sloveniaBalkans:
        return 'SLO';
      case ScoutingRegionId.flandersBelgium:
        return 'FLA';
      case ScoutingRegionId.colombiaAndes:
        return 'AND';
      case ScoutingRegionId.france:
        return 'FRA';
      case ScoutingRegionId.italy:
        return 'ITA';
      case ScoutingRegionId.scandinavia:
        return 'SCA';
      case ScoutingRegionId.ukAustralia:
        return 'ANZ';
      case ScoutingRegionId.iberianPeninsula:
        return 'IBE';
    }
  }

  List<String> get primaryNationalities {
    switch (this) {
      case ScoutingRegionId.sloveniaBalkans:
        return const ['SLO', 'AUT', 'SVK', 'CZE'];
      case ScoutingRegionId.flandersBelgium:
        return const ['BEL', 'NED'];
      case ScoutingRegionId.colombiaAndes:
        return const ['COL', 'ECU'];
      case ScoutingRegionId.france:
        return const ['FRA'];
      case ScoutingRegionId.italy:
        return const ['ITA'];
      case ScoutingRegionId.scandinavia:
        return const ['DEN', 'NOR'];
      case ScoutingRegionId.ukAustralia:
        return const ['GBR', 'AUS', 'NZL', 'IRL'];
      case ScoutingRegionId.iberianPeninsula:
        return const ['ESP', 'POR'];
    }
  }

  String get specialtySummary {
    switch (this) {
      case ScoutingRegionId.sloveniaBalkans:
        return 'Wszechstronni liderzy GC, eksplozywni górale i puncherzy';
      case ScoutingRegionId.flandersBelgium:
        return 'Specjaliści od bruku, rantów na wietrze i klasyków';
      case ScoutingRegionId.colombiaAndes:
        return 'Czyści górale <58 kg z wysokim W/kg i adaptacją do wysokości';
      case ScoutingRegionId.france:
        return 'Puncherzy, harcownicy ucieczek i techniczni zjazdowcy';
      case ScoutingRegionId.italy:
        return 'Kolarze wyścigów jednodniowych, puncherzy i szybcy finiszierzy';
      case ScoutingRegionId.scandinavia:
        return 'Czasowcy TT, silniki aero i specjaliści od deszczu i chłodu';
      case ScoutingRegionId.ukAustralia:
        return 'Torowi czasowcy, pociągi aero i metodyczni kolarze GC';
      case ScoutingRegionId.iberianPeninsula:
        return 'Górale etapowi, specjaliści na upał i wyścigi 3-tygodniowe';
    }
  }

  Color get accentColor {
    switch (this) {
      case ScoutingRegionId.sloveniaBalkans:
        return AppColors.cyanAccent;
      case ScoutingRegionId.flandersBelgium:
        return AppColors.goldAccent;
      case ScoutingRegionId.colombiaAndes:
        return AppColors.amberWarning;
      case ScoutingRegionId.france:
        return AppColors.accentBlue;
      case ScoutingRegionId.italy:
        return AppColors.statusSuccess;
      case ScoutingRegionId.scandinavia:
        return const Color(0xFF60A5FA);
      case ScoutingRegionId.ukAustralia:
        return AppColors.primaryAccent;
      case ScoutingRegionId.iberianPeninsula:
        return const Color(0xFFF97316);
    }
  }
}

/// Poziom rozbudowy regionalnej siatki skautingowej.
enum ScoutingNetworkTier {
  outpost,
  regionalHub,
  eliteAcademyPartner;

  String toJson() => name;

  static ScoutingNetworkTier fromJson(String value) {
    return ScoutingNetworkTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ScoutingNetworkTier.outpost,
    );
  }

  int get level {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return 1;
      case ScoutingNetworkTier.regionalHub:
        return 2;
      case ScoutingNetworkTier.eliteAcademyPartner:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return 'Poziom 1 • Posterunek Lokalny';
      case ScoutingNetworkTier.regionalHub:
        return 'Poziom 2 • Centrum Regionalne';
      case ScoutingNetworkTier.eliteAcademyPartner:
        return 'Poziom 3 • Elitarna Akademia Partnerska';
    }
  }

  String get shortLabel {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return 'L1 Posterunek';
      case ScoutingNetworkTier.regionalHub:
        return 'L2 Centrum';
      case ScoutingNetworkTier.eliteAcademyPartner:
        return 'L3 Akademia';
    }
  }

  double get monthlyCostMultiplier {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return 1.0;
      case ScoutingNetworkTier.regionalHub:
        return 1.65;
      case ScoutingNetworkTier.eliteAcademyPartner:
        return 2.4;
    }
  }

  int get prospectsPerSweep {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return 2;
      case ScoutingNetworkTier.regionalHub:
        return 3;
      case ScoutingNetworkTier.eliteAcademyPartner:
        return 4;
    }
  }

  double get generationalBonusChance {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return 0.0;
      case ScoutingNetworkTier.regionalHub:
        return 0.03;
      case ScoutingNetworkTier.eliteAcademyPartner:
        return 0.07;
    }
  }

  int get potentialCeilingBoost {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return 0;
      case ScoutingNetworkTier.regionalHub:
        return 2;
      case ScoutingNetworkTier.eliteAcademyPartner:
        return 4;
    }
  }

  ScoutingNetworkTier? get nextTier {
    switch (this) {
      case ScoutingNetworkTier.outpost:
        return ScoutingNetworkTier.regionalHub;
      case ScoutingNetworkTier.regionalHub:
        return ScoutingNetworkTier.eliteAcademyPartner;
      case ScoutingNetworkTier.eliteAcademyPartner:
        return null;
    }
  }
}

/// Profil fizjologiczny i taktyczny talentów generowanych w danym regionie.
class RegionalSpecializationProfile {
  final ScoutingRegionId regionId;
  final Map<RiderSpecialization, double> specializationWeights;
  final double minWeightKg;
  final double maxWeightKg;
  final double minHeightCm;
  final double maxHeightCm;
  final int cobblesBonus;
  final int descendingBonus;
  final int bikeHandlingBonus;
  final int aeroBonus;
  final int draftingBonus;
  final int rainResistanceBonus;
  final int heatToleranceBonus;
  final int timeTrialBonus;
  final int raceIqBonus;
  final double ftpWkgMultiplier;
  final double recoveryBonus;
  final int baseSetupCostEur;
  final int baseMonthlyUpkeepEur;
  final List<ScoutingSource> preferredSources;
  final String scoutingNarrative;

  const RegionalSpecializationProfile({
    required this.regionId,
    required this.specializationWeights,
    required this.minWeightKg,
    required this.maxWeightKg,
    required this.minHeightCm,
    required this.maxHeightCm,
    this.cobblesBonus = 0,
    this.descendingBonus = 0,
    this.bikeHandlingBonus = 0,
    this.aeroBonus = 0,
    this.draftingBonus = 0,
    this.rainResistanceBonus = 0,
    this.heatToleranceBonus = 0,
    this.timeTrialBonus = 0,
    this.raceIqBonus = 0,
    this.ftpWkgMultiplier = 1.0,
    this.recoveryBonus = 0.0,
    required this.baseSetupCostEur,
    required this.baseMonthlyUpkeepEur,
    required this.preferredSources,
    required this.scoutingNarrative,
  });

  List<RiderSpecialization> get topSpecializations {
    final entries = specializationWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList(growable: false);
  }
}

/// Stan pojedynczego węzła regionalnej siatki skautingowej.
class RegionalScoutingNetworkNode {
  final ScoutingRegionId regionId;
  final bool isActive;
  final ScoutingNetworkTier tier;
  final int networkXp;
  final int totalProspectsDiscovered;
  final int assignedScoutSkill;
  final DateTime? lastSweepDate;
  final List<String> discoveredProspectIds;

  const RegionalScoutingNetworkNode({
    required this.regionId,
    required this.isActive,
    required this.tier,
    required this.networkXp,
    required this.totalProspectsDiscovered,
    required this.assignedScoutSkill,
    this.lastSweepDate,
    this.discoveredProspectIds = const [],
  });

  RegionalSpecializationProfile get profile =>
      RegionalScoutingNetworksService.profileFor(regionId);

  int get monthlyUpkeepEur => isActive
      ? (profile.baseMonthlyUpkeepEur * tier.monthlyCostMultiplier).round()
      : 0;

  int get nextUpgradeCostEur {
    final next = tier.nextTier;
    if (next == null) return 0;
    return (profile.baseSetupCostEur * (next.level * 1.15)).round();
  }

  double get effectivenessScore {
    if (!isActive) return 0.0;
    final skillFactor = (assignedScoutSkill.clamp(40, 99) - 40) / 59.0;
    final xpFactor = (networkXp.clamp(0, 1000) / 1000.0);
    final tierFactor = tier.level / 3.0;
    return (0.45 * skillFactor + 0.35 * tierFactor + 0.20 * xpFactor)
        .clamp(0.1, 1.0);
  }

  RegionalScoutingNetworkNode copyWith({
    ScoutingRegionId? regionId,
    bool? isActive,
    ScoutingNetworkTier? tier,
    int? networkXp,
    int? totalProspectsDiscovered,
    int? assignedScoutSkill,
    DateTime? lastSweepDate,
    List<String>? discoveredProspectIds,
  }) {
    return RegionalScoutingNetworkNode(
      regionId: regionId ?? this.regionId,
      isActive: isActive ?? this.isActive,
      tier: tier ?? this.tier,
      networkXp: networkXp ?? this.networkXp,
      totalProspectsDiscovered:
          totalProspectsDiscovered ?? this.totalProspectsDiscovered,
      assignedScoutSkill: assignedScoutSkill ?? this.assignedScoutSkill,
      lastSweepDate: lastSweepDate ?? this.lastSweepDate,
      discoveredProspectIds:
          discoveredProspectIds ?? this.discoveredProspectIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'regionId': regionId.toJson(),
        'isActive': isActive,
        'tier': tier.toJson(),
        'networkXp': networkXp,
        'totalProspectsDiscovered': totalProspectsDiscovered,
        'assignedScoutSkill': assignedScoutSkill,
        'lastSweepDate': lastSweepDate?.toIso8601String(),
        'discoveredProspectIds': discoveredProspectIds,
      };

  factory RegionalScoutingNetworkNode.fromJson(Map<String, dynamic> json) {
    return RegionalScoutingNetworkNode(
      regionId: ScoutingRegionId.fromJson(json['regionId'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? false,
      tier: ScoutingNetworkTier.fromJson(json['tier'] as String? ?? ''),
      networkXp: (json['networkXp'] as num?)?.toInt() ?? 0,
      totalProspectsDiscovered:
          (json['totalProspectsDiscovered'] as num?)?.toInt() ?? 0,
      assignedScoutSkill: (json['assignedScoutSkill'] as num?)?.toInt() ?? 70,
      lastSweepDate: json['lastSweepDate'] != null
          ? DateTime.tryParse(json['lastSweepDate'] as String)
          : null,
      discoveredProspectIds:
          (json['discoveredProspectIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(growable: false),
    );
  }
}

/// Raport pojedynczego przeszukania rynku młodzieżowego w regionie.
class RegionalTalentDiscoveryResult {
  final ScoutingRegionId regionId;
  final List<ScoutedProspect> prospects;
  final int networkXpGained;
  final int sweepCostEur;
  final String summaryHeadline;
  final DateTime generatedAt;

  const RegionalTalentDiscoveryResult({
    required this.regionId,
    required this.prospects,
    required this.networkXpGained,
    required this.sweepCostEur,
    required this.summaryHeadline,
    required this.generatedAt,
  });
}

/// Wynik operacji na siatce skautingowej (aktywacja, rozbudowa, misja).
class NetworkOperationResult {
  final bool success;
  final String message;
  final int costEur;
  final RegionalScoutingNetworkState state;

  const NetworkOperationResult({
    required this.success,
    required this.message,
    required this.costEur,
    required this.state,
  });
}

/// Zbiorczy stan wszystkich 8 regionalnych siatek skautingowych.
class RegionalScoutingNetworkState {
  final Map<ScoutingRegionId, RegionalScoutingNetworkNode> nodes;
  final List<ScoutedProspect> regionalProspectPool;
  final RegionalTalentDiscoveryResult? lastDiscoveryResult;

  const RegionalScoutingNetworkState({
    required this.nodes,
    this.regionalProspectPool = const [],
    this.lastDiscoveryResult,
  });

  int get activeNetworkCount =>
      nodes.values.where((node) => node.isActive).length;

  int get totalMonthlyUpkeepEur => nodes.values
      .fold<int>(0, (sum, node) => sum + node.monthlyUpkeepEur);

  RegionalScoutingNetworkNode nodeFor(ScoutingRegionId regionId) {
    return nodes[regionId] ??
        RegionalScoutingNetworkNode(
          regionId: regionId,
          isActive: false,
          tier: ScoutingNetworkTier.outpost,
          networkXp: 0,
          totalProspectsDiscovered: 0,
          assignedScoutSkill: 70,
        );
  }

  RegionalScoutingNetworkState copyWith({
    Map<ScoutingRegionId, RegionalScoutingNetworkNode>? nodes,
    List<ScoutedProspect>? regionalProspectPool,
    RegionalTalentDiscoveryResult? lastDiscoveryResult,
  }) {
    return RegionalScoutingNetworkState(
      nodes: nodes ?? this.nodes,
      regionalProspectPool: regionalProspectPool ?? this.regionalProspectPool,
      lastDiscoveryResult: lastDiscoveryResult ?? this.lastDiscoveryResult,
    );
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((key, value) => MapEntry(key.toJson(), value.toJson())),
        'regionalProspectPool':
            regionalProspectPool.map((p) => p.toJson()).toList(growable: false),
      };

  factory RegionalScoutingNetworkState.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as Map<String, dynamic>? ?? const {};
    final parsedNodes = <ScoutingRegionId, RegionalScoutingNetworkNode>{};
    for (final region in ScoutingRegionId.values) {
      final entry = rawNodes[region.toJson()] as Map<String, dynamic>?;
      parsedNodes[region] = entry != null
          ? RegionalScoutingNetworkNode.fromJson(entry)
          : RegionalScoutingNetworkNode(
              regionId: region,
              isActive: false,
              tier: ScoutingNetworkTier.outpost,
              networkXp: 0,
              totalProspectsDiscovered: 0,
              assignedScoutSkill: 70,
            );
    }

    final rawPool =
        json['regionalProspectPool'] as List<dynamic>? ?? const [];
    final parsedPool = rawPool
        .whereType<Map<String, dynamic>>()
        .map(ScoutedProspect.fromJson)
        .toList(growable: false);

    return RegionalScoutingNetworkState(
      nodes: Map<ScoutingRegionId, RegionalScoutingNetworkNode>.unmodifiable(
        parsedNodes,
      ),
      regionalProspectPool: List<ScoutedProspect>.unmodifiable(parsedPool),
    );
  }
}

/// Serwis zarządzający 8 regionalnymi siatkami skautingowymi i generowaniem
/// wyspecjalizowanych talentów U19/U23 z całego świata.
class RegionalScoutingNetworksService {
  RegionalScoutingNetworksService._();

  static final math.Random _defaultRandom = math.Random();

  /// Katalog 8 wyspecjalizowanych profili regionalnych.
  static const Map<ScoutingRegionId, RegionalSpecializationProfile>
      regionProfiles = {
    ScoutingRegionId.sloveniaBalkans: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.sloveniaBalkans,
      specializationWeights: {
        RiderSpecialization.gcClimber: 0.36,
        RiderSpecialization.puncher: 0.28,
        RiderSpecialization.timeTrialist: 0.16,
        RiderSpecialization.pureClimber: 0.12,
        RiderSpecialization.breakawaySpecialist: 0.08,
      },
      minWeightKg: 60.0,
      maxWeightKg: 68.5,
      minHeightCm: 173.0,
      maxHeightCm: 184.0,
      descendingBonus: 7,
      bikeHandlingBonus: 6,
      timeTrialBonus: 5,
      raceIqBonus: 8,
      ftpWkgMultiplier: 1.04,
      recoveryBonus: 0.06,
      baseSetupCostEur: 85000,
      baseMonthlyUpkeepEur: 14500,
      preferredSources: [
        ScoutingSource.juniorU19,
        ScoutingSource.espoirsU23,
        ScoutingSource.mtbGravelCrossover,
      ],
      scoutingNarrative:
          'Alpejska szkoła słoweńska: fenomenalne W/kg na stromych ściankach, agresywny styl jazdy i wysoka wszechstronność GT.',
    ),
    ScoutingRegionId.flandersBelgium: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.flandersBelgium,
      specializationWeights: {
        RiderSpecialization.classicCobbles: 0.44,
        RiderSpecialization.versatileSprinter: 0.22,
        RiderSpecialization.breakawaySpecialist: 0.16,
        RiderSpecialization.puncher: 0.12,
        RiderSpecialization.timeTrialist: 0.06,
      },
      minWeightKg: 70.0,
      maxWeightKg: 81.5,
      minHeightCm: 178.0,
      maxHeightCm: 191.0,
      cobblesBonus: 16,
      bikeHandlingBonus: 12,
      draftingBonus: 10,
      rainResistanceBonus: 14,
      raceIqBonus: 7,
      baseSetupCostEur: 95000,
      baseMonthlyUpkeepEur: 16000,
      preferredSources: [
        ScoutingSource.juniorU19,
        ScoutingSource.localAmateurCriterium,
        ScoutingSource.espoirsU23,
      ],
      scoutingNarrative:
          'Królewska szkoła Flandrii: specjaliści od bruku, rantów w bocznym wietrze, deszczu i brutalnych interwałów na bergach.',
    ),
    ScoutingRegionId.colombiaAndes: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.colombiaAndes,
      specializationWeights: {
        RiderSpecialization.pureClimber: 0.62,
        RiderSpecialization.gcClimber: 0.24,
        RiderSpecialization.puncher: 0.08,
        RiderSpecialization.breakawaySpecialist: 0.06,
      },
      minWeightKg: 49.5,
      maxWeightKg: 57.6,
      minHeightCm: 160.0,
      maxHeightCm: 172.0,
      descendingBonus: 5,
      heatToleranceBonus: 12,
      raceIqBonus: 4,
      ftpWkgMultiplier: 1.07,
      recoveryBonus: 0.05,
      baseSetupCostEur: 75000,
      baseMonthlyUpkeepEur: 12500,
      preferredSources: [
        ScoutingSource.localAmateurCriterium,
        ScoutingSource.espoirsU23,
        ScoutingSource.juniorU19,
      ],
      scoutingNarrative:
          'Wysokogórskie doliny Andów (>2500 m n.p.m.): ultra-lekcy czyści górale poniżej 58 kg o wrodzonej odporności na hipoksję.',
    ),
    ScoutingRegionId.france: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.france,
      specializationWeights: {
        RiderSpecialization.puncher: 0.30,
        RiderSpecialization.breakawaySpecialist: 0.25,
        RiderSpecialization.gcClimber: 0.20,
        RiderSpecialization.versatileSprinter: 0.15,
        RiderSpecialization.classicCobbles: 0.10,
      },
      minWeightKg: 62.0,
      maxWeightKg: 74.0,
      minHeightCm: 172.0,
      maxHeightCm: 185.0,
      descendingBonus: 9,
      bikeHandlingBonus: 7,
      raceIqBonus: 9,
      rainResistanceBonus: 5,
      baseSetupCostEur: 90000,
      baseMonthlyUpkeepEur: 15000,
      preferredSources: [
        ScoutingSource.espoirsU23,
        ScoutingSource.juniorU19,
        ScoutingSource.mtbGravelCrossover,
      ],
      scoutingNarrative:
          'Francuskie kluby DN1 i Puchar Narodów: sprytni harcownicy, dynamiczni puncherzy i śmiali zjazdowcy.',
    ),
    ScoutingRegionId.italy: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.italy,
      specializationWeights: {
        RiderSpecialization.puncher: 0.28,
        RiderSpecialization.versatileSprinter: 0.26,
        RiderSpecialization.pureSprinter: 0.18,
        RiderSpecialization.gcClimber: 0.16,
        RiderSpecialization.classicCobbles: 0.12,
      },
      minWeightKg: 63.0,
      maxWeightKg: 77.0,
      minHeightCm: 171.0,
      maxHeightCm: 185.0,
      descendingBonus: 10,
      bikeHandlingBonus: 10,
      draftingBonus: 8,
      heatToleranceBonus: 7,
      raceIqBonus: 8,
      baseSetupCostEur: 88000,
      baseMonthlyUpkeepEur: 14800,
      preferredSources: [
        ScoutingSource.espoirsU23,
        ScoutingSource.juniorU19,
        ScoutingSource.localAmateurCriterium,
      ],
      scoutingNarrative:
          'Włoska tradycja Strade Bianche i Baby Giro: perfekcyjna technika w peletonie, szybki finisz z małej grupy i zjazdy.',
    ),
    ScoutingRegionId.scandinavia: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.scandinavia,
      specializationWeights: {
        RiderSpecialization.timeTrialist: 0.34,
        RiderSpecialization.domestiqueEngine: 0.22,
        RiderSpecialization.classicCobbles: 0.20,
        RiderSpecialization.gcClimber: 0.14,
        RiderSpecialization.pureSprinter: 0.10,
      },
      minWeightKg: 68.0,
      maxWeightKg: 80.5,
      minHeightCm: 179.0,
      maxHeightCm: 193.0,
      aeroBonus: 12,
      timeTrialBonus: 14,
      rainResistanceBonus: 12,
      draftingBonus: 8,
      ftpWkgMultiplier: 1.02,
      baseSetupCostEur: 82000,
      baseMonthlyUpkeepEur: 14000,
      preferredSources: [
        ScoutingSource.juniorU19,
        ScoutingSource.zwiftAcademyVirtual,
        ScoutingSource.espoirsU23,
      ],
      scoutingNarrative:
          'Nordyckie silniki wattowe: wysoka moc bezwzględna FTP, doskonała pozycja TT i pełna odporność na wiatr i deszcz.',
    ),
    ScoutingRegionId.ukAustralia: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.ukAustralia,
      specializationWeights: {
        RiderSpecialization.timeTrialist: 0.30,
        RiderSpecialization.pureSprinter: 0.24,
        RiderSpecialization.gcClimber: 0.22,
        RiderSpecialization.domestiqueEngine: 0.14,
        RiderSpecialization.versatileSprinter: 0.10,
      },
      minWeightKg: 65.0,
      maxWeightKg: 79.0,
      minHeightCm: 175.0,
      maxHeightCm: 189.0,
      aeroBonus: 14,
      timeTrialBonus: 12,
      draftingBonus: 10,
      heatToleranceBonus: 6,
      raceIqBonus: 6,
      baseSetupCostEur: 92000,
      baseMonthlyUpkeepEur: 15500,
      preferredSources: [
        ScoutingSource.zwiftAcademyVirtual,
        ScoutingSource.espoirsU23,
        ScoutingSource.juniorU19,
      ],
      scoutingNarrative:
          'Akademie torowe British Cycling i Australii: perfekcyjna aerodynamika, pociągi sprinterskie i trening oparty na danych.',
    ),
    ScoutingRegionId.iberianPeninsula: RegionalSpecializationProfile(
      regionId: ScoutingRegionId.iberianPeninsula,
      specializationWeights: {
        RiderSpecialization.gcClimber: 0.38,
        RiderSpecialization.pureClimber: 0.30,
        RiderSpecialization.puncher: 0.18,
        RiderSpecialization.breakawaySpecialist: 0.14,
      },
      minWeightKg: 57.5,
      maxWeightKg: 66.5,
      minHeightCm: 168.0,
      maxHeightCm: 180.0,
      heatToleranceBonus: 14,
      descendingBonus: 6,
      raceIqBonus: 6,
      ftpWkgMultiplier: 1.03,
      recoveryBonus: 0.08,
      baseSetupCostEur: 80000,
      baseMonthlyUpkeepEur: 13500,
      preferredSources: [
        ScoutingSource.espoirsU23,
        ScoutingSource.juniorU19,
        ScoutingSource.localAmateurCriterium,
      ],
      scoutingNarrative:
          'Pireneje i Sierra Nevada: wytrzymali górale etapowi odporni na 40-stopniowy upał i trzytygodniowe Grand Toury.',
    ),
  };

  /// Zwraca profil specjalizacji dla wybranego regionu.
  static RegionalSpecializationProfile profileFor(ScoutingRegionId regionId) {
    return regionProfiles[regionId]!;
  }

  /// Tworzy początkowy stan wszystkich 8 siatek regionalnych.
  static RegionalScoutingNetworkState createInitialState({
    List<ScoutingRegionId> initialActiveRegions = const [
      ScoutingRegionId.flandersBelgium,
    ],
    int defaultScoutSkill = 74,
  }) {
    final nodes = <ScoutingRegionId, RegionalScoutingNetworkNode>{};
    for (final region in ScoutingRegionId.values) {
      final active = initialActiveRegions.contains(region);
      nodes[region] = RegionalScoutingNetworkNode(
        regionId: region,
        isActive: active,
        tier: ScoutingNetworkTier.outpost,
        networkXp: active ? 120 : 0,
        totalProspectsDiscovered: 0,
        assignedScoutSkill: defaultScoutSkill.clamp(40, 99),
      );
    }
    return RegionalScoutingNetworkState(
      nodes: Map<ScoutingRegionId, RegionalScoutingNetworkNode>.unmodifiable(
        nodes,
      ),
    );
  }

  /// Aktywuje wybraną siatkę regionalną po weryfikacji budżetu.
  static NetworkOperationResult activateRegion({
    required RegionalScoutingNetworkState state,
    required ScoutingRegionId regionId,
    required int availableBudgetEur,
    int scoutSkill = 74,
  }) {
    final current = state.nodeFor(regionId);
    if (current.isActive) {
      return NetworkOperationResult(
        success: false,
        message: 'Siatka ${regionId.label} jest już aktywna.',
        costEur: 0,
        state: state,
      );
    }

    final setupCost = profileFor(regionId).baseSetupCostEur;
    if (availableBudgetEur < setupCost) {
      return NetworkOperationResult(
        success: false,
        message:
            'Brak środków na otwarcie siatki ${regionId.label} (wymagane ${Formatters.formatCurrency(setupCost)}).',
        costEur: 0,
        state: state,
      );
    }

    final updatedNodes =
        Map<ScoutingRegionId, RegionalScoutingNetworkNode>.from(state.nodes);
    updatedNodes[regionId] = current.copyWith(
      isActive: true,
      assignedScoutSkill: scoutSkill.clamp(40, 99),
      networkXp: math.max(current.networkXp, 50),
    );

    return NetworkOperationResult(
      success: true,
      message: 'Otwarto siatkę skautingową: ${regionId.label}.',
      costEur: setupCost,
      state: state.copyWith(
        nodes:
            Map<ScoutingRegionId, RegionalScoutingNetworkNode>.unmodifiable(
          updatedNodes,
        ),
      ),
    );
  }

  /// Dezaktywuje siatkę regionalną (zatrzymuje koszty miesięczne, zachowuje XP).
  static NetworkOperationResult deactivateRegion({
    required RegionalScoutingNetworkState state,
    required ScoutingRegionId regionId,
  }) {
    final current = state.nodeFor(regionId);
    if (!current.isActive) {
      return NetworkOperationResult(
        success: false,
        message: 'Siatka ${regionId.label} jest już nieaktywna.',
        costEur: 0,
        state: state,
      );
    }

    final updatedNodes =
        Map<ScoutingRegionId, RegionalScoutingNetworkNode>.from(state.nodes);
    updatedNodes[regionId] = current.copyWith(isActive: false);

    return NetworkOperationResult(
      success: true,
      message: 'Zawieszono działalność siatki ${regionId.label}.',
      costEur: 0,
      state: state.copyWith(
        nodes:
            Map<ScoutingRegionId, RegionalScoutingNetworkNode>.unmodifiable(
          updatedNodes,
        ),
      ),
    );
  }

  /// Podnosi poziom siatki regionalnej na wyższy (Outpost -> Hub -> Elite Academy).
  static NetworkOperationResult upgradeRegionTier({
    required RegionalScoutingNetworkState state,
    required ScoutingRegionId regionId,
    required int availableBudgetEur,
  }) {
    final current = state.nodeFor(regionId);
    if (!current.isActive) {
      return NetworkOperationResult(
        success: false,
        message: 'Najpierw aktywuj siatkę ${regionId.label}, aby ją rozbudować.',
        costEur: 0,
        state: state,
      );
    }

    final nextTier = current.tier.nextTier;
    if (nextTier == null) {
      return NetworkOperationResult(
        success: false,
        message: 'Siatka ${regionId.label} osiągnęła już maksymalny poziom.',
        costEur: 0,
        state: state,
      );
    }

    final cost = current.nextUpgradeCostEur;
    if (availableBudgetEur < cost) {
      return NetworkOperationResult(
        success: false,
        message:
            'Niewystarczający budżet na rozbudowę (${Formatters.formatCurrency(cost)}).',
        costEur: 0,
        state: state,
      );
    }

    final updatedNodes =
        Map<ScoutingRegionId, RegionalScoutingNetworkNode>.from(state.nodes);
    updatedNodes[regionId] = current.copyWith(
      tier: nextTier,
      networkXp: (current.networkXp + 150).clamp(0, 1000),
    );

    return NetworkOperationResult(
      success: true,
      message: 'Rozbudowano ${regionId.label} do: ${nextTier.shortLabel}.',
      costEur: cost,
      state: state.copyWith(
        nodes:
            Map<ScoutingRegionId, RegionalScoutingNetworkNode>.unmodifiable(
          updatedNodes,
        ),
      ),
    );
  }

  /// Aktualizuje ocenę umiejętności głównego skauta przypisanego do regionu.
  static RegionalScoutingNetworkState assignScoutSkill({
    required RegionalScoutingNetworkState state,
    required ScoutingRegionId regionId,
    required int scoutSkill,
  }) {
    final current = state.nodeFor(regionId);
    final updatedNodes =
        Map<ScoutingRegionId, RegionalScoutingNetworkNode>.from(state.nodes);
    updatedNodes[regionId] = current.copyWith(
      assignedScoutSkill: scoutSkill.clamp(40, 99),
    );
    return state.copyWith(
      nodes: Map<ScoutingRegionId, RegionalScoutingNetworkNode>.unmodifiable(
        updatedNodes,
      ),
    );
  }

  /// Przeprowadza regionalną akcję skautingową w wybranym regionie i zwraca odkryte talenty.
  static NetworkOperationResult runRegionalScoutingSweep({
    required RegionalScoutingNetworkState state,
    required ScoutingRegionId regionId,
    required int seasonYear,
    required DateTime currentDate,
    int availableBudgetEur = 10000000,
    int sweepFeeEur = 12000,
    math.Random? random,
  }) {
    final node = state.nodeFor(regionId);
    if (!node.isActive) {
      return NetworkOperationResult(
        success: false,
        message: 'Region ${regionId.label} jest nieaktywny.',
        costEur: 0,
        state: state,
      );
    }

    if (availableBudgetEur < sweepFeeEur) {
      return NetworkOperationResult(
        success: false,
        message:
            'Brak budżetu na ekspedycję skautingową (${Formatters.formatCurrency(sweepFeeEur)}).',
        costEur: 0,
        state: state,
      );
    }

    final rng = random ?? _defaultRandom;
    final count = node.tier.prospectsPerSweep;
    final discovered = <ScoutedProspect>[];
    final newIds = <String>[...node.discoveredProspectIds];

    for (int i = 0; i < count; i++) {
      final prospect = generateRegionalProspect(
        regionId: regionId,
        seasonYear: seasonYear,
        tier: node.tier,
        scoutSkill: node.assignedScoutSkill,
        random: rng,
      );
      discovered.add(prospect);
      newIds.add(prospect.id);
    }

    final xpGained = 45 + count * 15;
    final updatedNodes =
        Map<ScoutingRegionId, RegionalScoutingNetworkNode>.from(state.nodes);
    updatedNodes[regionId] = node.copyWith(
      networkXp: (node.networkXp + xpGained).clamp(0, 1000),
      totalProspectsDiscovered: node.totalProspectsDiscovered + discovered.length,
      lastSweepDate: currentDate,
      discoveredProspectIds: List<String>.unmodifiable(newIds),
    );

    final updatedPool = <ScoutedProspect>[
      ...discovered,
      ...state.regionalProspectPool,
    ];

    final discoveryResult = RegionalTalentDiscoveryResult(
      regionId: regionId,
      prospects: List<ScoutedProspect>.unmodifiable(discovered),
      networkXpGained: xpGained,
      sweepCostEur: sweepFeeEur,
      summaryHeadline:
          'Raport z regionu ${regionId.label}: odkryto ${discovered.length} talentów.',
      generatedAt: currentDate,
    );

    return NetworkOperationResult(
      success: true,
      message: discoveryResult.summaryHeadline,
      costEur: sweepFeeEur,
      state: state.copyWith(
        nodes:
            Map<ScoutingRegionId, RegionalScoutingNetworkNode>.unmodifiable(
          updatedNodes,
        ),
        regionalProspectPool: List<ScoutedProspect>.unmodifiable(updatedPool),
        lastDiscoveryResult: discoveryResult,
      ),
    );
  }

  /// Uruchamia miesięczny przegląd dla wszystkich aktywnych siatek jednocześnie.
  static RegionalScoutingNetworkState runGlobalMonthlySweep({
    required RegionalScoutingNetworkState state,
    required int seasonYear,
    required DateTime currentDate,
    math.Random? random,
  }) {
    var workingState = state;
    final rng = random ?? _defaultRandom;
    for (final region in ScoutingRegionId.values) {
      if (workingState.nodeFor(region).isActive) {
        final result = runRegionalScoutingSweep(
          state: workingState,
          regionId: region,
          seasonYear: seasonYear,
          currentDate: currentDate,
          availableBudgetEur: 100000000,
          sweepFeeEur: 0,
          random: rng,
        );
        workingState = result.state;
      }
    }
    return workingState;
  }

  /// Generuje pojedynczego młodego adepta zgodnie z profilem fizjologicznym
  /// i taktycznym wybranego regionu świata.
  static ScoutedProspect generateRegionalProspect({
    required ScoutingRegionId regionId,
    required int seasonYear,
    ScoutingNetworkTier tier = ScoutingNetworkTier.outpost,
    int scoutSkill = 74,
    math.Random? random,
  }) {
    final rng = random ?? _defaultRandom;
    final profile = profileFor(regionId);
    final nationality = regionId.primaryNationalities[
        rng.nextInt(regionId.primaryNationalities.length)];
    final specialization =
        _pickWeightedSpecialization(profile.specializationWeights, rng);

    final scoutingTier = _rollScoutingTier(tier, scoutSkill, rng);

    final baseRider = RiderProceduralGenerator.generateNeoProTalent(
      currentSeasonYear: seasonYear,
      tier: scoutingTier,
      preferredNationality: nationality,
      preferredSpecialization: specialization,
      random: rng,
    );

    final specializedRider = _applyRegionalSpecialization(
      rider: baseRider,
      profile: profile,
      tier: tier,
      rng: rng,
    );

    final source = profile.preferredSources[
        rng.nextInt(profile.preferredSources.length)];

    // Im lepszy skaut i poziom siatki, tym mniejsza mgła wojny na starcie
    final initialStage =
        (tier == ScoutingNetworkTier.eliteAcademyPartner && scoutSkill >= 85)
            ? ScoutingDiscoveryStage.scoutedByObserver
            : ScoutingDiscoveryStage.rawTalent;

    final ftpError =
        initialStage == ScoutingDiscoveryStage.scoutedByObserver ? 10 : 28;
    final vo2Error =
        initialStage == ScoutingDiscoveryStage.scoutedByObserver ? 2.0 : 5.5;
    final potError =
        initialStage == ScoutingDiscoveryStage.scoutedByObserver ? 4 : 10;

    final realFtp = (specializedRider.powerProfile.watts20m * 0.95).round();
    final realVo2 = specializedRider.physiology.vo2Max;
    final realPot = specializedRider.potential;

    final minFtp = math.max(180, realFtp - rng.nextInt(ftpError + 1));
    final maxFtp = realFtp + rng.nextInt(ftpError + 1);
    final minVo2 = math.max(58.0, realVo2 - rng.nextDouble() * vo2Error);
    final maxVo2 = math.min(96.0, realVo2 + rng.nextDouble() * vo2Error);
    final minPot = math.max(55, realPot - rng.nextInt(potError + 1));
    final maxPot = math.min(99, realPot + rng.nextInt(potError + 1));

    final report = _buildRegionalScoutReport(
      regionId: regionId,
      rider: specializedRider,
      source: source,
    );

    return ScoutedProspect(
      id: 'reg_${regionId.regionCode.toLowerCase()}_${specializedRider.id}',
      firstName: specializedRider.firstName,
      lastName: specializedRider.lastName,
      nationalityIso: specializedRider.nationalityIso,
      age: specializedRider.age,
      source: source,
      discoveryStage: initialStage,
      estimatedMinFtpWatts: minFtp,
      estimatedMaxFtpWatts: maxFtp,
      estimatedMinVo2Max: minVo2,
      estimatedMaxVo2Max: maxVo2,
      estimatedMinPotential: minPot,
      estimatedMaxPotential: maxPot,
      probableSpecialization: specializedRider.specialization,
      scoutReport: report,
      trueRider: specializedRider,
    );
  }

  static RiderSpecialization _pickWeightedSpecialization(
    Map<RiderSpecialization, double> weights,
    math.Random rng,
  ) {
    final total = weights.values.fold<double>(0.0, (a, b) => a + b);
    if (total <= 0) return RiderSpecialization.domestiqueEngine;
    double roll = rng.nextDouble() * total;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) return entry.key;
    }
    return weights.keys.last;
  }

  static ScoutingTier _rollScoutingTier(
    ScoutingNetworkTier networkTier,
    int scoutSkill,
    math.Random rng,
  ) {
    final skillBonus = ((scoutSkill - 70).clamp(0, 30)) / 30.0 * 0.04;
    final genChance =
        0.04 + networkTier.generationalBonusChance + skillBonus * 0.5;
    final wtChance = 0.20 + networkTier.level * 0.05 + skillBonus;
    final roll = rng.nextDouble();

    if (roll < genChance) return ScoutingTier.generationalTalent;
    if (roll < genChance + wtChance) return ScoutingTier.worldTourProspect;
    if (roll < 0.72) return ScoutingTier.solidPro;
    return ScoutingTier.continentalHopeful;
  }

  static Rider _applyRegionalSpecialization({
    required Rider rider,
    required RegionalSpecializationProfile profile,
    required ScoutingNetworkTier tier,
    required math.Random rng,
  }) {
    // Zakres masy i wzrostu z zachowaniem ścisłych limitów regionalnych (np. Kolumbia < 58 kg)
    final double targetWeight = _lerpDouble(
      profile.minWeightKg,
      profile.maxWeightKg,
      rng.nextDouble(),
    );
    final double clampedWeight = double.parse(
      targetWeight
          .clamp(profile.minWeightKg, profile.maxWeightKg)
          .toStringAsFixed(1),
    );

    final double targetHeight = double.parse(
      _lerpDouble(profile.minHeightCm, profile.maxHeightCm, rng.nextDouble())
          .toStringAsFixed(1),
    );

    // Przeskalowanie mocy tak, aby zachować lub wzmocnić realistyczne W/kg regionu
    final double origWeight =
        rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 68.0;
    final double weightRatio = (clampedWeight / origWeight).clamp(0.76, 1.18);

    // Dla lekkich górali z Andów zachowujemy wyższy W/kg zamiast liniowego cięcia watów
    final double powerScale =
        (weightRatio * 0.55 + 0.45) * profile.ftpWkgMultiplier;

    final int newWatts20m =
        (rider.powerProfile.watts20m * powerScale).round().clamp(240, 490);
    final int newWatts60m =
        (rider.powerProfile.watts60m * powerScale).round().clamp(215, 460);
    final int newWatts5m =
        (rider.powerProfile.watts5m * powerScale).round().clamp(290, 580);
    final int newWatts3m =
        (rider.powerProfile.watts3m * powerScale).round().clamp(320, 640);
    final int newWatts1m =
        (rider.powerProfile.watts1m * (weightRatio * 0.45 + 0.55))
            .round()
            .clamp(420, 960);

    // Dla Flandrii i cięższych klasykowców zachowujemy moc eksplozywną na bruku
    final double sprintScale =
        profile.regionId == ScoutingRegionId.flandersBelgium
            ? 1.06
            : (weightRatio * 0.65 + 0.35);

    final int newWatts5s =
        (rider.powerProfile.watts5s * sprintScale).round().clamp(820, 1850);
    final int newWatts15s =
        (rider.powerProfile.watts15s * sprintScale).round().clamp(720, 1550);
    final int newWatts30s =
        (rider.powerProfile.watts30s * sprintScale).round().clamp(580, 1280);

    final newPower = RiderPowerProfile(
      watts5s: newWatts5s,
      watts15s: newWatts15s,
      watts30s: newWatts30s,
      watts1m: newWatts1m,
      watts3m: newWatts3m,
      watts5m: newWatts5m,
      watts20m: newWatts20m,
      watts60m: newWatts60m,
    );

    final int newFtp = (newWatts20m * 0.95).round();
    final double newVo2 = (rider.physiology.vo2Max * profile.ftpWkgMultiplier)
        .clamp(62.0, 94.0);

    final updatedPhysiologyBase = rider.physiology.copyWith(
      heightCm: targetHeight,
      weightKg: clampedWeight,
      ftpWatts: newFtp,
      vo2Max: double.parse(newVo2.toStringAsFixed(1)),
      recoveryRate:
          (rider.physiology.recoveryRate + profile.recoveryBonus).clamp(0.7, 1.35),
    );

    final labProfile = LactateAndLabProfile.fromPhysiology(
      updatedPhysiologyBase,
      specialization: rider.specialization,
      powerProfile: newPower,
    );
    final finalPhysiology = updatedPhysiologyBase.copyWith(
      labProfile: labProfile,
    );

    final s = rider.skills;
    final newSkills = s.copyWith(
      cobbles: (s.cobbles + profile.cobblesBonus).clamp(30, 99),
      descending: (s.descending + profile.descendingBonus).clamp(35, 99),
      bikeHandling: (s.bikeHandling + profile.bikeHandlingBonus).clamp(35, 99),
      aeroPositioning: (s.aeroPositioning + profile.aeroBonus).clamp(35, 99),
      draftingEfficiency:
          (s.draftingEfficiency + profile.draftingBonus).clamp(35, 99),
      rainResistance:
          (s.rainResistance + profile.rainResistanceBonus).clamp(30, 99),
      heatTolerance:
          (s.heatTolerance + profile.heatToleranceBonus).clamp(30, 99),
      timeTrialPositioning:
          (s.timeTrialPositioning + profile.timeTrialBonus).clamp(30, 99),
      raceIq: (s.raceIq + profile.raceIqBonus).clamp(35, 99),
    );

    final boostedPotential =
        (rider.potential + tier.potentialCeilingBoost).clamp(65, 99);

    return Rider(
      id: rider.id,
      firstName: rider.firstName,
      lastName: rider.lastName,
      nationalityIso: rider.nationalityIso,
      birthDate: rider.birthDate,
      potential: boostedPotential,
      specialization: rider.specialization,
      physiology: finalPhysiology,
      powerProfile: newPower,
      skills: newSkills,
      appearance: rider.appearance,
      contract: rider.contract,
      health: rider.health,
      careerPointsUci: rider.careerPointsUci,
    );
  }

  static String _buildRegionalScoutReport({
    required ScoutingRegionId regionId,
    required Rider rider,
    required ScoutingSource source,
  }) {
    final weightStr = rider.physiology.weightKg.toStringAsFixed(1);
    final wkg = rider.physiology.wattsPerKg.toStringAsFixed(2);
    switch (regionId) {
      case ScoutingRegionId.colombiaAndes:
        return 'Raport z Andów (${source.badgeLabel}): lekki góral ($weightStr kg, ~$wkg W/kg), naturalna adaptacja wysokościowa.';
      case ScoutingRegionId.flandersBelgium:
        return 'Raport z Flandrii (${source.badgeLabel}): twardy klasykowiec na bruk (${rider.skills.cobbles}/99) i ranty na wietrze.';
      case ScoutingRegionId.sloveniaBalkans:
        return 'Raport ze Słowenii (${source.badgeLabel}): dynamiczny profil GC/Puncher ($weightStr kg, ${rider.specialization.displayName}).';
      case ScoutingRegionId.scandinavia:
        return 'Raport ze Skandynawii (${source.badgeLabel}): mocny silnik TT (${rider.skills.timeTrialPositioning}/99) i odporność na deszcz.';
      case ScoutingRegionId.ukAustralia:
        return 'Raport UK/AUS (${source.badgeLabel}): zdyscyplinowana aerodynamika (${rider.skills.aeroPositioning}/99) i torowa dynamika.';
      case ScoutingRegionId.iberianPeninsula:
        return 'Raport z Iberii (${source.badgeLabel}): góral na długie etapy i upały (odporność na ciepło ${rider.skills.heatTolerance}/99).';
      case ScoutingRegionId.france:
        return 'Raport z Francji (${source.badgeLabel}): aktywny harcownik i puncher (Race IQ ${rider.skills.raceIq}/99).';
      case ScoutingRegionId.italy:
        return 'Raport z Włoch (${source.badgeLabel}): świetne prowadzenie roweru (${rider.skills.bikeHandling}/99) i szybki finisz.';
    }
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Kontroler Riverpod zarządzający stanem siatek regionalnych.
class RegionalScoutingNetworkNotifier
    extends StateNotifier<RegionalScoutingNetworkState> {
  RegionalScoutingNetworkNotifier()
      : super(RegionalScoutingNetworksService.createInitialState());

  NetworkOperationResult activateRegion(
    ScoutingRegionId regionId, {
    required int availableBudgetEur,
    int scoutSkill = 74,
  }) {
    final result = RegionalScoutingNetworksService.activateRegion(
      state: state,
      regionId: regionId,
      availableBudgetEur: availableBudgetEur,
      scoutSkill: scoutSkill,
    );
    state = result.state;
    return result;
  }

  NetworkOperationResult deactivateRegion(ScoutingRegionId regionId) {
    final result = RegionalScoutingNetworksService.deactivateRegion(
      state: state,
      regionId: regionId,
    );
    state = result.state;
    return result;
  }

  NetworkOperationResult upgradeRegion(
    ScoutingRegionId regionId, {
    required int availableBudgetEur,
  }) {
    final result = RegionalScoutingNetworksService.upgradeRegionTier(
      state: state,
      regionId: regionId,
      availableBudgetEur: availableBudgetEur,
    );
    state = result.state;
    return result;
  }

  NetworkOperationResult sweepRegion(
    ScoutingRegionId regionId, {
    required int seasonYear,
    required DateTime currentDate,
    required int availableBudgetEur,
  }) {
    final result = RegionalScoutingNetworksService.runRegionalScoutingSweep(
      state: state,
      regionId: regionId,
      seasonYear: seasonYear,
      currentDate: currentDate,
      availableBudgetEur: availableBudgetEur,
    );
    state = result.state;
    return result;
  }
}

final regionalScoutingNetworkProvider = StateNotifierProvider<
    RegionalScoutingNetworkNotifier, RegionalScoutingNetworkState>(
  (ref) => RegionalScoutingNetworkNotifier(),
);

/// Responsywny panel UI zarządzania 8 regionalnymi siatkami skautingowymi.
/// Obsługuje rozdzielczości 390x844 (mobile), 1024x768 (tablet) i 1600x900 (desktop).
class RegionalScoutingNetworksPanel extends StatefulWidget {
  final RegionalScoutingNetworkState state;
  final int availableBudgetEur;
  final ValueChanged<ScoutingRegionId>? onActivateRegion;
  final ValueChanged<ScoutingRegionId>? onDeactivateRegion;
  final ValueChanged<ScoutingRegionId>? onUpgradeRegion;
  final ValueChanged<ScoutingRegionId>? onSweepRegion;
  final ValueChanged<ScoutedProspect>? onSelectProspect;

  const RegionalScoutingNetworksPanel({
    super.key,
    required this.state,
    required this.availableBudgetEur,
    this.onActivateRegion,
    this.onDeactivateRegion,
    this.onUpgradeRegion,
    this.onSweepRegion,
    this.onSelectProspect,
  });

  @override
  State<RegionalScoutingNetworksPanel> createState() =>
      _RegionalScoutingNetworksPanelState();
}

class _RegionalScoutingNetworksPanelState
    extends State<RegionalScoutingNetworksPanel> {
  ScoutingRegionId _selectedRegion = ScoutingRegionId.flandersBelgium;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1200;
        final isTablet = width >= 760 && width < 1200;

        return Container(
          color: AppColors.background,
          padding: EdgeInsets.all(isDesktop ? 20 : 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBar(isCompact: !isDesktop && !isTablet),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildRegionsGrid(crossAxisCount: 2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _buildSelectedRegionInspector(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _buildRegionalProspectsFeed(),
                      ),
                    ],
                  )
                else if (isTablet)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRegionsGrid(crossAxisCount: 4),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildSelectedRegionInspector()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildRegionalProspectsFeed()),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRegionsGrid(crossAxisCount: 2),
                      const SizedBox(height: 16),
                      _buildSelectedRegionInspector(),
                      const SizedBox(height: 16),
                      _buildRegionalProspectsFeed(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar({required bool isCompact}) {
    final activeCount = widget.state.activeNetworkCount;
    final upkeep = widget.state.totalMonthlyUpkeepEur;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'REGIONALNE SIATKI SKAUTINGOWE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '8 globalnych ośrodków kolarskich ze specjalizacją fizjologiczną',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 12 : 13,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatPill(
                label: 'Aktywne siatki',
                value: '$activeCount / 8',
                accent: AppColors.goldAccent,
              ),
              _StatPill(
                label: 'Koszt / mies.',
                value: Formatters.formatCurrency(upkeep),
                accent: AppColors.accentBlue,
              ),
              _StatPill(
                label: 'Budżet',
                value: Formatters.formatCurrency(widget.availableBudgetEur),
                accent: AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegionsGrid({required int crossAxisCount}) {
    const regions = ScoutingRegionId.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: regions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: crossAxisCount >= 4 ? 1.35 : 1.55,
      ),
      itemBuilder: (context, index) {
        final region = regions[index];
        final node = widget.state.nodeFor(region);
        final isSelected = region == _selectedRegion;

        return _RegionNetworkCard(
          region: region,
          node: node,
          isSelected: isSelected,
          onTap: () => setState(() => _selectedRegion = region),
        );
      },
    );
  }

  Widget _buildSelectedRegionInspector() {
    final node = widget.state.nodeFor(_selectedRegion);
    final profile = RegionalScoutingNetworksService.profileFor(_selectedRegion);
    final nextTier = node.tier.nextTier;
    final canAffordSetup =
        widget.availableBudgetEur >= profile.baseSetupCostEur;
    final canAffordUpgrade =
        nextTier != null && widget.availableBudgetEur >= node.nextUpgradeCostEur;
    final canAffordSweep = widget.availableBudgetEur >= 12000;

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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedRegion.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedRegion.accentColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _selectedRegion.regionCode,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _selectedRegion.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedRegion.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.scoutingNarrative,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(
                text:
                    'Masa: ${profile.minWeightKg.toStringAsFixed(0)}–${profile.maxWeightKg.toStringAsFixed(1)} kg',
                color: AppColors.goldAccent,
              ),
              _TagChip(
                text: 'Poziom: ${node.tier.shortLabel}',
                color: AppColors.accentBlue,
              ),
              _TagChip(
                text: 'Skaut: ${node.assignedScoutSkill}/99',
                color: AppColors.statusSuccess,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'DOMINUJĄCE PROFILE TALENTÓW',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.topSpecializations
                .map(
                  (spec) => _TagChip(
                    text: spec.displayName,
                    color: AppColors.textPrimary,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!node.isActive)
                _InteractiveActionButton(
                  label:
                      'Otwórz siatkę (${Formatters.formatCurrency(profile.baseSetupCostEur)})',
                  icon: Icons.add_location_alt_outlined,
                  accent: AppColors.statusSuccess,
                  enabled: canAffordSetup && widget.onActivateRegion != null,
                  onPressed: () => widget.onActivateRegion?.call(_selectedRegion),
                )
              else ...[
                _InteractiveActionButton(
                  label: 'Ekspedycja skautingowa (12 000 €)',
                  icon: Icons.radar,
                  accent: AppColors.goldAccent,
                  enabled: canAffordSweep && widget.onSweepRegion != null,
                  onPressed: () => widget.onSweepRegion?.call(_selectedRegion),
                ),
                if (nextTier != null)
                  _InteractiveActionButton(
                    label:
                        'Awans: ${nextTier.shortLabel} (${Formatters.formatCurrency(node.nextUpgradeCostEur)})',
                    icon: Icons.upgrade,
                    accent: AppColors.accentBlue,
                    enabled: canAffordUpgrade && widget.onUpgradeRegion != null,
                    onPressed: () =>
                        widget.onUpgradeRegion?.call(_selectedRegion),
                  ),
                _InteractiveActionButton(
                  label: 'Zawieś siatkę',
                  icon: Icons.pause_circle_outline,
                  accent: AppColors.crimsonAlert,
                  enabled: widget.onDeactivateRegion != null,
                  onPressed: () =>
                      widget.onDeactivateRegion?.call(_selectedRegion),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalProspectsFeed() {
    final regionProspects = widget.state.regionalProspectPool
        .where((p) => p.id.startsWith('reg_${_selectedRegion.regionCode.toLowerCase()}_'))
        .toList(growable: false);

    final displayList = regionProspects.isNotEmpty
        ? regionProspects
        : widget.state.regionalProspectPool.take(6).toList(growable: false);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'ODKRYTE TALENTY REGIONALNE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${displayList.length} poz.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (displayList.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak raportów w puli. Uruchom ekspedycję skautingową w aktywnym regionie.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: displayList
                  .take(6)
                  .map(
                    (prospect) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProspectListTile(
                        prospect: prospect,
                        onTap: widget.onSelectProspect != null
                            ? () => widget.onSelectProspect!(prospect)
                            : null,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _RegionNetworkCard extends StatefulWidget {
  final ScoutingRegionId region;
  final RegionalScoutingNetworkNode node;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegionNetworkCard({
    required this.region,
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RegionNetworkCard> createState() => _RegionNetworkCardState();
}

class _RegionNetworkCardState extends State<_RegionNetworkCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? widget.region.accentColor
            : _isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.6)
                : AppColors.cardBorder;

    final bgColor = _isPressed
        ? AppColors.surface
        : (widget.isSelected || _isHovered)
            ? AppColors.surfaceLight
            : AppColors.surface;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.region.regionCode,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.region.accentColor,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.node.isActive
                            ? AppColors.statusSuccess
                            : AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.region.shortLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.node.isActive
                      ? '${widget.node.tier.shortLabel} • ${widget.node.totalProspectsDiscovered} tal.'
                      : 'Nieaktywna',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: widget.node.isActive
                        ? AppColors.textSecondary
                        : AppColors.textSecondary.withValues(alpha: 0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.enabled
        ? widget.accent
        : AppColors.textSecondary.withValues(alpha: 0.4);

    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _isPressed
            ? widget.accent.withValues(alpha: 0.28)
            : _isHovered
                ? widget.accent.withValues(alpha: 0.20)
                : widget.accent.withValues(alpha: 0.12);

    return Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? AppColors.goldAccent
                    : effectiveColor.withValues(alpha: 0.65),
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: effectiveColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _ProspectListTile extends StatefulWidget {
  final ScoutedProspect prospect;
  final VoidCallback? onTap;

  const _ProspectListTile({
    required this.prospect,
    this.onTap,
  });

  @override
  State<_ProspectListTile> createState() => _ProspectListTileState();
}

class _ProspectListTileState extends State<_ProspectListTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final rider = widget.prospect.trueRider;
    final specLabel =
        widget.prospect.probableSpecialization?.displayName ?? 'Prospekt';
    final weightLabel = '${rider.physiology.weightKg.toStringAsFixed(1)} kg';

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? AppColors.goldAccent
                    : _isHovered
                        ? AppColors.accentBlue.withValues(alpha: 0.6)
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
                        '${widget.prospect.fullName} (${widget.prospect.nationalityIso}, ${widget.prospect.age} l.)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      weightLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$specLabel • Potencjał ${widget.prospect.potentialDisplay}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
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
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color color;

  const _TagChip({
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
        border: Border.all(color: AppColors.cardBorder),
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
