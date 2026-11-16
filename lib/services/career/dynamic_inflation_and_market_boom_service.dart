// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';

/// Faza cyklu makroekonomicznego rynku kolarskiego w latach 2026–2040.
enum MarketMacroCyclePhase {
  organicGrowth,
  investmentBoom,
  techArmsRace,
  consolidationPlateau,
  goldenEraPeak;

  String toJson() => name;

  static MarketMacroCyclePhase fromJson(String value) {
    return MarketMacroCyclePhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MarketMacroCyclePhase.organicGrowth,
    );
  }

  String get label {
    switch (this) {
      case MarketMacroCyclePhase.organicGrowth:
        return 'Wzrost organiczny';
      case MarketMacroCyclePhase.investmentBoom:
        return 'Boom inwestycyjny';
      case MarketMacroCyclePhase.techArmsRace:
        return 'Wyścig zbrojeń Tech & Aero';
      case MarketMacroCyclePhase.consolidationPlateau:
        return 'Konsolidacja rynku';
      case MarketMacroCyclePhase.goldenEraPeak:
        return 'Złota Era WorldTour';
    }
  }

  Color get accentColor {
    switch (this) {
      case MarketMacroCyclePhase.organicGrowth:
        return AppColors.accentBlue;
      case MarketMacroCyclePhase.investmentBoom:
        return AppColors.statusSuccess;
      case MarketMacroCyclePhase.techArmsRace:
        return AppColors.cyanAccent;
      case MarketMacroCyclePhase.consolidationPlateau:
        return AppColors.amberWarning;
      case MarketMacroCyclePhase.goldenEraPeak:
        return AppColors.goldAccent;
    }
  }
}

/// Archetyp gigantycznego sponsora wchodzącego do zawodowego peletonu.
enum MegaSponsorArchetype {
  sovereignWealthFund,
  bigTechGiant,
  privateEquitySyndicate,
  globalAiCloudConsortium,
  cleanEnergyConglomerate,
  aerospaceAndMobility;

  String toJson() => name;

  static MegaSponsorArchetype fromJson(String value) {
    return MegaSponsorArchetype.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MegaSponsorArchetype.bigTechGiant,
    );
  }

  String get label {
    switch (this) {
      case MegaSponsorArchetype.sovereignWealthFund:
        return 'Fundusz Inwestycyjny / Sovereign Fund';
      case MegaSponsorArchetype.bigTechGiant:
        return 'Koncern Technologiczny Big Tech';
      case MegaSponsorArchetype.privateEquitySyndicate:
        return 'Konsorcjum Private Equity';
      case MegaSponsorArchetype.globalAiCloudConsortium:
        return 'Gigant AI & Cloud Computing';
      case MegaSponsorArchetype.cleanEnergyConglomerate:
        return 'Konglomerat Czystej Energii';
      case MegaSponsorArchetype.aerospaceAndMobility:
        return 'Lotnictwo i Mobilność Przyszłości';
    }
  }

  SponsorIndustry get defaultIndustry {
    switch (this) {
      case MegaSponsorArchetype.sovereignWealthFund:
      case MegaSponsorArchetype.privateEquitySyndicate:
        return SponsorIndustry.finance;
      case MegaSponsorArchetype.bigTechGiant:
      case MegaSponsorArchetype.globalAiCloudConsortium:
        return SponsorIndustry.tech;
      case MegaSponsorArchetype.cleanEnergyConglomerate:
        return SponsorIndustry.energy;
      case MegaSponsorArchetype.aerospaceAndMobility:
        return SponsorIndustry.automotive;
    }
  }
}

/// Zdarzenie wejścia nowego gigantycznego sponsora do świata kolarstwa.
class MegaSponsorEntryEvent {
  final String id;
  final int seasonYear;
  final String sponsorName;
  final MegaSponsorArchetype archetype;
  final SponsorIndustry industry;
  final String? targetTeamId;
  final String targetTeamName;
  final int annualCommitmentEur;
  final int contractYears;
  final double budgetMultiplierImpact;
  final String headline;
  final String marketSummary;

  const MegaSponsorEntryEvent({
    required this.id,
    required this.seasonYear,
    required this.sponsorName,
    required this.archetype,
    required this.industry,
    this.targetTeamId,
    required this.targetTeamName,
    required this.annualCommitmentEur,
    required this.contractYears,
    required this.budgetMultiplierImpact,
    required this.headline,
    required this.marketSummary,
  });

  int get totalContractValueEur => annualCommitmentEur * contractYears;

  MegaSponsorEntryEvent copyWith({
    String? id,
    int? seasonYear,
    String? sponsorName,
    MegaSponsorArchetype? archetype,
    SponsorIndustry? industry,
    String? targetTeamId,
    String? targetTeamName,
    int? annualCommitmentEur,
    int? contractYears,
    double? budgetMultiplierImpact,
    String? headline,
    String? marketSummary,
  }) {
    return MegaSponsorEntryEvent(
      id: id ?? this.id,
      seasonYear: seasonYear ?? this.seasonYear,
      sponsorName: sponsorName ?? this.sponsorName,
      archetype: archetype ?? this.archetype,
      industry: industry ?? this.industry,
      targetTeamId: targetTeamId ?? this.targetTeamId,
      targetTeamName: targetTeamName ?? this.targetTeamName,
      annualCommitmentEur: annualCommitmentEur ?? this.annualCommitmentEur,
      contractYears: contractYears ?? this.contractYears,
      budgetMultiplierImpact:
          budgetMultiplierImpact ?? this.budgetMultiplierImpact,
      headline: headline ?? this.headline,
      marketSummary: marketSummary ?? this.marketSummary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonYear': seasonYear,
      'sponsorName': sponsorName,
      'archetype': archetype.toJson(),
      'industry': industry.toJson(),
      'targetTeamId': targetTeamId,
      'targetTeamName': targetTeamName,
      'annualCommitmentEur': annualCommitmentEur,
      'contractYears': contractYears,
      'budgetMultiplierImpact': budgetMultiplierImpact,
      'headline': headline,
      'marketSummary': marketSummary,
    };
  }

  factory MegaSponsorEntryEvent.fromJson(Map<String, dynamic> json) {
    return MegaSponsorEntryEvent(
      id: json['id'] as String,
      seasonYear: (json['seasonYear'] as num).toInt(),
      sponsorName: json['sponsorName'] as String,
      archetype: MegaSponsorArchetype.fromJson(json['archetype'] as String),
      industry: SponsorIndustry.fromJson(json['industry'] as String),
      targetTeamId: json['targetTeamId'] as String?,
      targetTeamName: json['targetTeamName'] as String,
      annualCommitmentEur: (json['annualCommitmentEur'] as num).toInt(),
      contractYears: (json['contractYears'] as num).toInt(),
      budgetMultiplierImpact:
          (json['budgetMultiplierImpact'] as num).toDouble(),
      headline: json['headline'] as String,
      marketSummary: json['marketSummary'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MegaSponsorEntryEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Rynkowe widełki budżetowe dla danej dywizji UCI w konkretnym roku.
class DivisionBudgetBenchmark {
  final TeamDivision division;
  final int seasonYear;
  final int averageBudgetEur;
  final int medianBudgetEur;
  final int topQuartileBudgetEur;
  final int minimumViableBudgetEur;
  final int superTeamCeilingBudgetEur;
  final double annualGrowthRatePercent;

  const DivisionBudgetBenchmark({
    required this.division,
    required this.seasonYear,
    required this.averageBudgetEur,
    required this.medianBudgetEur,
    required this.topQuartileBudgetEur,
    required this.minimumViableBudgetEur,
    required this.superTeamCeilingBudgetEur,
    required this.annualGrowthRatePercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'division': division.toJson(),
      'seasonYear': seasonYear,
      'averageBudgetEur': averageBudgetEur,
      'medianBudgetEur': medianBudgetEur,
      'topQuartileBudgetEur': topQuartileBudgetEur,
      'minimumViableBudgetEur': minimumViableBudgetEur,
      'superTeamCeilingBudgetEur': superTeamCeilingBudgetEur,
      'annualGrowthRatePercent': annualGrowthRatePercent,
    };
  }

  factory DivisionBudgetBenchmark.fromJson(Map<String, dynamic> json) {
    return DivisionBudgetBenchmark(
      division: TeamDivision.fromJson(json['division'] as String),
      seasonYear: (json['seasonYear'] as num).toInt(),
      averageBudgetEur: (json['averageBudgetEur'] as num).toInt(),
      medianBudgetEur: (json['medianBudgetEur'] as num).toInt(),
      topQuartileBudgetEur: (json['topQuartileBudgetEur'] as num).toInt(),
      minimumViableBudgetEur: (json['minimumViableBudgetEur'] as num).toInt(),
      superTeamCeilingBudgetEur:
          (json['superTeamCeilingBudgetEur'] as num).toInt(),
      annualGrowthRatePercent:
          (json['annualGrowthRatePercent'] as num).toDouble(),
    );
  }
}

/// Pełny obraz makroekonomiczny świata kolarstwa dla pojedynczego sezonu.
class SeasonMacroEconomySnapshot {
  final int seasonYear;
  final MarketMacroCyclePhase cyclePhase;
  final double annualInflationRatePercent;
  final double cumulativeInflationMultiplier;
  final double salaryInflationMultiplier;
  final double transferFeeInflationMultiplier;
  final double prizePoolInflationMultiplier;
  final double equipmentCostInflationMultiplier;
  final double marketBoomIndex; // 0.0 - 100.0
  final Map<TeamDivision, DivisionBudgetBenchmark> divisionBenchmarks;
  final List<MegaSponsorEntryEvent> activeMegaSponsors;
  final List<MegaSponsorEntryEvent> newEntrantsThisSeason;

  const SeasonMacroEconomySnapshot({
    required this.seasonYear,
    required this.cyclePhase,
    required this.annualInflationRatePercent,
    required this.cumulativeInflationMultiplier,
    required this.salaryInflationMultiplier,
    required this.transferFeeInflationMultiplier,
    required this.prizePoolInflationMultiplier,
    required this.equipmentCostInflationMultiplier,
    required this.marketBoomIndex,
    required this.divisionBenchmarks,
    required this.activeMegaSponsors,
    required this.newEntrantsThisSeason,
  });

  int get worldTourAverageBudgetEur =>
      divisionBenchmarks[TeamDivision.worldTour]?.averageBudgetEur ??
      DynamicInflationAndMarketBoomService.baseWorldTourAvgBudgetEur;

  int get proTeamAverageBudgetEur =>
      divisionBenchmarks[TeamDivision.proTeam]?.averageBudgetEur ??
      DynamicInflationAndMarketBoomService.baseProTeamAvgBudgetEur;

  int get continentalAverageBudgetEur =>
      divisionBenchmarks[TeamDivision.continental]?.averageBudgetEur ??
      DynamicInflationAndMarketBoomService.baseContinentalAvgBudgetEur;

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'cyclePhase': cyclePhase.toJson(),
      'annualInflationRatePercent': annualInflationRatePercent,
      'cumulativeInflationMultiplier': cumulativeInflationMultiplier,
      'salaryInflationMultiplier': salaryInflationMultiplier,
      'transferFeeInflationMultiplier': transferFeeInflationMultiplier,
      'prizePoolInflationMultiplier': prizePoolInflationMultiplier,
      'equipmentCostInflationMultiplier': equipmentCostInflationMultiplier,
      'marketBoomIndex': marketBoomIndex,
      'divisionBenchmarks': {
        for (final entry in divisionBenchmarks.entries)
          entry.key.toJson(): entry.value.toJson(),
      },
      'activeMegaSponsors':
          activeMegaSponsors.map((e) => e.toJson()).toList(),
      'newEntrantsThisSeason':
          newEntrantsThisSeason.map((e) => e.toJson()).toList(),
    };
  }

  factory SeasonMacroEconomySnapshot.fromJson(Map<String, dynamic> json) {
    final rawBenchmarks =
        json['divisionBenchmarks'] as Map<String, dynamic>? ?? const {};
    return SeasonMacroEconomySnapshot(
      seasonYear: (json['seasonYear'] as num).toInt(),
      cyclePhase: MarketMacroCyclePhase.fromJson(json['cyclePhase'] as String),
      annualInflationRatePercent:
          (json['annualInflationRatePercent'] as num).toDouble(),
      cumulativeInflationMultiplier:
          (json['cumulativeInflationMultiplier'] as num).toDouble(),
      salaryInflationMultiplier:
          (json['salaryInflationMultiplier'] as num).toDouble(),
      transferFeeInflationMultiplier:
          (json['transferFeeInflationMultiplier'] as num).toDouble(),
      prizePoolInflationMultiplier:
          (json['prizePoolInflationMultiplier'] as num).toDouble(),
      equipmentCostInflationMultiplier:
          (json['equipmentCostInflationMultiplier'] as num).toDouble(),
      marketBoomIndex: (json['marketBoomIndex'] as num).toDouble(),
      divisionBenchmarks: {
        for (final entry in rawBenchmarks.entries)
          TeamDivision.fromJson(entry.key): DivisionBudgetBenchmark.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
      activeMegaSponsors: (json['activeMegaSponsors'] as List<dynamic>? ?? [])
          .map((e) => MegaSponsorEntryEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      newEntrantsThisSeason:
          (json['newEntrantsThisSeason'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    MegaSponsorEntryEvent.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

/// Wynik waloryzacji budżetu i kosztów pojedynczej drużyny na nowy sezon.
class TeamEconomyAdjustmentResult {
  final CyclingTeam updatedTeam;
  final int previousAnnualIncomeEur;
  final int newAnnualIncomeEur;
  final int previousMonthlyBurnRateEur;
  final int newMonthlyBurnRateEur;
  final double budgetGrowthPercent;
  final MegaSponsorEntryEvent? awardedMegaSponsor;

  const TeamEconomyAdjustmentResult({
    required this.updatedTeam,
    required this.previousAnnualIncomeEur,
    required this.newAnnualIncomeEur,
    required this.previousMonthlyBurnRateEur,
    required this.newMonthlyBurnRateEur,
    required this.budgetGrowthPercent,
    this.awardedMegaSponsor,
  });

  int get netAnnualIncomeDeltaEur =>
      newAnnualIncomeEur - previousAnnualIncomeEur;
}

/// Ocena konkurencyjności budżetu drużyny gracza na tle rynku w danym sezonie.
class PlayerMarketCompetitivenessReport {
  final int seasonYear;
  final TeamDivision division;
  final int playerAnnualBudgetEur;
  final int divisionAverageBudgetEur;
  final int divisionTopQuartileBudgetEur;
  final int gapToAverageEur;
  final double relativeStrengthRatio;
  final int estimatedBudgetPercentile;
  final String tierClassification;
  final String strategicRecommendation;

  const PlayerMarketCompetitivenessReport({
    required this.seasonYear,
    required this.division,
    required this.playerAnnualBudgetEur,
    required this.divisionAverageBudgetEur,
    required this.divisionTopQuartileBudgetEur,
    required this.gapToAverageEur,
    required this.relativeStrengthRatio,
    required this.estimatedBudgetPercentile,
    required this.tierClassification,
    required this.strategicRecommendation,
  });

  bool get isAboveDivisionAverage => playerAnnualBudgetEur >= divisionAverageBudgetEur;
}

class _CuratedMegaSponsorTemplate {
  final int targetYear;
  final String sponsorName;
  final MegaSponsorArchetype archetype;
  final int base2026CommitmentEur;
  final int contractYears;
  final double impactMultiplier;
  final String headline;
  final String marketSummary;

  const _CuratedMegaSponsorTemplate({
    required this.targetYear,
    required this.sponsorName,
    required this.archetype,
    required this.base2026CommitmentEur,
    required this.contractYears,
    required this.impactMultiplier,
    required this.headline,
    required this.marketSummary,
  });
}

/// Wieloletni model ekonomiczny świata kolarstwa (2026–2040).
///
/// Symuluje inflację kosztów płacowych, transferowych i operacyjnych oraz wejścia
/// gigantycznych sponsorów (funduszy inwestycyjnych i koncernów technologicznych)
/// podnoszących średnie budżety ekip WorldTour, ProTeam i Continental.
class DynamicInflationAndMarketBoomService {
  static const int baseYear = 2026;
  static const int horizonEndYear = 2040;

  static const int baseWorldTourAvgBudgetEur = 24000000;
  static const int baseProTeamAvgBudgetEur = 6800000;
  static const int baseContinentalAvgBudgetEur = 1250000;

  static const List<_CuratedMegaSponsorTemplate> _megaSponsorCatalog = [
    _CuratedMegaSponsorTemplate(
      targetYear: 2027,
      sponsorName: 'Aurelia Sovereign Capital',
      archetype: MegaSponsorArchetype.sovereignWealthFund,
      base2026CommitmentEur: 36000000,
      contractYears: 5,
      impactMultiplier: 0.065,
      headline:
          'Aurelia Sovereign Capital wchodzi do WorldTour z rekordowym pakietem!',
      marketSummary:
          'Bliskowschodni fundusz majątkowy podwaja stawkę w wyścigu o liderów GC i podbija średnie płace w peletonie.',
    ),
    _CuratedMegaSponsorTemplate(
      targetYear: 2028,
      sponsorName: 'Kinetix Quantum Cloud',
      archetype: MegaSponsorArchetype.globalAiCloudConsortium,
      base2026CommitmentEur: 39000000,
      contractYears: 4,
      impactMultiplier: 0.075,
      headline:
          'Kinetix Quantum Cloud inwestuje w telemetrię AI i własną ekipę WorldTour.',
      marketSummary:
          'Koncern chmurowy uruchamia laboratorium aero i finansuje wielomilionowe wykupy kontraktów sprinterów i górali.',
    ),
    _CuratedMegaSponsorTemplate(
      targetYear: 2030,
      sponsorName: 'Helios CleanGrid Holdings',
      archetype: MegaSponsorArchetype.cleanEnergyConglomerate,
      base2026CommitmentEur: 42000000,
      contractYears: 6,
      impactMultiplier: 0.080,
      headline:
          'Helios CleanGrid otwiera nową erę zielonego finansowania w Tour de France.',
      marketSummary:
          'Globalny gigant OZE wchodzi jako sponsor tytularny, windując budżety topowych ekip powyżej 45 mln EUR.',
    ),
    _CuratedMegaSponsorTemplate(
      targetYear: 2031,
      sponsorName: 'Vanguardia Private Equity',
      archetype: MegaSponsorArchetype.privateEquitySyndicate,
      base2026CommitmentEur: 34000000,
      contractYears: 4,
      impactMultiplier: 0.060,
      headline:
          'Konsorcjum Vanguardia Private Equity przejmuje licencję WorldTour.',
      marketSummary:
          'Napływ kapitału private equity wymusza reformę praw mediowych i zwiększa pule nagród w Monumentach.',
    ),
    _CuratedMegaSponsorTemplate(
      targetYear: 2033,
      sponsorName: 'Stratos AeroDynamics Corp',
      archetype: MegaSponsorArchetype.aerospaceAndMobility,
      base2026CommitmentEur: 45000000,
      contractYears: 5,
      impactMultiplier: 0.085,
      headline:
          'Stratos AeroDynamics przenosi technologię kosmiczną i budżet F1 do peletonu.',
      marketSummary:
          'Wyścig zbrojeń R&D przyspiesza: koszty tuneli aero i kontraktów gwiazd rosną o ponad 11% rok do roku.',
    ),
    _CuratedMegaSponsorTemplate(
      targetYear: 2035,
      sponsorName: 'NexaSphere Big Tech',
      archetype: MegaSponsorArchetype.bigTechGiant,
      base2026CommitmentEur: 48000000,
      contractYears: 5,
      impactMultiplier: 0.090,
      headline:
          'NexaSphere Big Tech podpisuje największy kontrakt w historii kolarstwa.',
      marketSummary:
          'Globalna platforma technologiczna podnosi poprzeczkę finansową WorldTour i aktywuje masowy skauting U23.',
    ),
    _CuratedMegaSponsorTemplate(
      targetYear: 2037,
      sponsorName: 'Nordic Horizon Sovereign Fund',
      archetype: MegaSponsorArchetype.sovereignWealthFund,
      base2026CommitmentEur: 44000000,
      contractYears: 4,
      impactMultiplier: 0.070,
      headline:
          'Nordic Horizon Sovereign Fund dołącza do elity sponsorów WorldTour.',
      marketSummary:
          'Skandynawski fundusz stabilizuje rynek długoterminowymi gwarancjami płacowymi i premiami za klasyki.',
    ),
    _CuratedMegaSponsorTemplate(
      targetYear: 2039,
      sponsorName: 'OmegaCore Neural Systems',
      archetype: MegaSponsorArchetype.globalAiCloudConsortium,
      base2026CommitmentEur: 52000000,
      contractYears: 5,
      impactMultiplier: 0.095,
      headline:
          'OmegaCore Neural Systems ustanawia rekordowy sufit budżetowy Złotej Ery.',
      marketSummary:
          'Średni budżet ekipy WorldTour przekracza dwukrotność poziomu z 2026 roku, a rynek transferowy osiąga szczyt.',
    ),
  ];

  const DynamicInflationAndMarketBoomService();

  /// Symuluje wieloletnią trajektorię ekonomiczną w zadanym przedziale lat (domyślnie 2026–2040).
  List<SeasonMacroEconomySnapshot> simulateMultiYearTrajectory({
    int startYear = baseYear,
    int endYear = horizonEndYear,
    int? seed,
  }) {
    final normalizedStart = math.min(startYear, endYear);
    final normalizedEnd = math.max(startYear, endYear);

    final List<SeasonMacroEconomySnapshot> trajectory = [];
    final List<MegaSponsorEntryEvent> cumulativeSponsors = [];

    for (int year = normalizedStart; year <= normalizedEnd; year++) {
      final snapshot = evaluateSeasonEconomy(
        seasonYear: year,
        priorMegaSponsors: cumulativeSponsors,
        seed: seed,
      );
      trajectory.add(snapshot);
      cumulativeSponsors
        ..clear()
        ..addAll(snapshot.activeMegaSponsors);
    }

    return List.unmodifiable(trajectory);
  }

  /// Wylicza pełny stan makroekonomiczny dla pojedynczego roku kariery.
  SeasonMacroEconomySnapshot evaluateSeasonEconomy({
    required int seasonYear,
    List<MegaSponsorEntryEvent> priorMegaSponsors = const [],
    int? seed,
  }) {
    final effectiveYear = seasonYear.clamp(baseYear, horizonEndYear + 10);
    final yearsElapsed = math.max(0, effectiveYear - baseYear);
    final rng = math.Random((seed ?? 20260401) + effectiveYear * 97);

    // Zbieramy aktywnych mega-sponsorów z poprzednich lat (których kontrakt nadal trwa)
    final activeSponsors = <MegaSponsorEntryEvent>[
      for (final sponsor in priorMegaSponsors)
        if (effectiveYear < sponsor.seasonYear + sponsor.contractYears)
          sponsor,
    ];

    // Sprawdzamy, czy w tym roku wchodzi nowy gigant z katalogu (lub dynamicznie po 2040)
    final newEntrants = <MegaSponsorEntryEvent>[];
    for (final template in _megaSponsorCatalog) {
      if (template.targetYear == effectiveYear) {
        final alreadyActive = activeSponsors.any(
          (s) => s.sponsorName == template.sponsorName,
        );
        if (!alreadyActive) {
          final yearScale = _baseInflationCurve(yearsElapsed);
          final variance = 0.96 + rng.nextDouble() * 0.10;
          final commitmentEur = _roundToNearest(
            template.base2026CommitmentEur * yearScale * variance,
            500000,
          );
          final event = MegaSponsorEntryEvent(
            id: 'mega_${effectiveYear}_${template.sponsorName.toLowerCase().replaceAll(' ', '_')}',
            seasonYear: effectiveYear,
            sponsorName: template.sponsorName,
            archetype: template.archetype,
            industry: template.archetype.defaultIndustry,
            targetTeamName: _pickHeadlineTargetTeamName(effectiveYear, rng),
            annualCommitmentEur: commitmentEur,
            contractYears: template.contractYears,
            budgetMultiplierImpact: template.impactMultiplier,
            headline: template.headline,
            marketSummary: template.marketSummary,
          );
          newEntrants.add(event);
          activeSponsors.add(event);
        }
      }
    }

    // Dodatkowy dynamiczny boom od aktywnych gigantów na rynku
    double sponsorBoomBoost = 0.0;
    for (final sponsor in activeSponsors) {
      sponsorBoomBoost += sponsor.budgetMultiplierImpact;
    }

    final cyclePhase = _resolveCyclePhase(effectiveYear, activeSponsors.length);
    final baseCurve = _baseInflationCurve(yearsElapsed);
    final phaseMultiplier = _phaseFactor(cyclePhase);

    final cumulativeInflationMultiplier = double.parse(
      (baseCurve * (1.0 + sponsorBoomBoost * 0.65) * phaseMultiplier)
          .toStringAsFixed(4),
    );

    final prevCurve = yearsElapsed == 0
        ? 1.0
        : _baseInflationCurve(yearsElapsed - 1) *
            (1.0 + math.max(0.0, sponsorBoomBoost - 0.04) * 0.65);

    final annualInflationRatePercent = yearsElapsed == 0
        ? 2.8
        : double.parse(
            (((cumulativeInflationMultiplier / math.max(0.5, prevCurve)) -
                        1.0) *
                    100.0)
                .clamp(1.8, 16.5)
                .toStringAsFixed(2),
          );

    // Płace kolarzy i opłaty transferowe rosną szybciej niż ogólne CPI podczas boomu
    final salaryInflationMultiplier = double.parse(
      (cumulativeInflationMultiplier * (1.0 + sponsorBoomBoost * 0.25))
          .toStringAsFixed(4),
    );
    final transferFeeInflationMultiplier = double.parse(
      (cumulativeInflationMultiplier * (1.05 + sponsorBoomBoost * 0.40))
          .toStringAsFixed(4),
    );
    final prizePoolInflationMultiplier = double.parse(
      (1.0 + (cumulativeInflationMultiplier - 1.0) * 0.72).toStringAsFixed(4),
    );
    final equipmentCostInflationMultiplier = double.parse(
      (1.0 + (cumulativeInflationMultiplier - 1.0) * 0.85).toStringAsFixed(4),
    );

    final marketBoomIndex = double.parse(
      (35.0 +
              yearsElapsed * 2.4 +
              activeSponsors.length * 7.5 +
              (cyclePhase == MarketMacroCyclePhase.goldenEraPeak ? 10.0 : 0.0))
          .clamp(0.0, 100.0)
          .toStringAsFixed(1),
    );

    final wtAvg = _roundToNearest(
      baseWorldTourAvgBudgetEur *
          cumulativeInflationMultiplier *
          (1.0 + sponsorBoomBoost * 0.35),
      100000,
    );
    final ptAvg = _roundToNearest(
      baseProTeamAvgBudgetEur *
          cumulativeInflationMultiplier *
          (1.0 + sponsorBoomBoost * 0.18),
      50000,
    );
    final contAvg = _roundToNearest(
      baseContinentalAvgBudgetEur *
          (1.0 + (cumulativeInflationMultiplier - 1.0) * 0.75),
      25000,
    );

    final benchmarks = <TeamDivision, DivisionBudgetBenchmark>{
      TeamDivision.worldTour: DivisionBudgetBenchmark(
        division: TeamDivision.worldTour,
        seasonYear: effectiveYear,
        averageBudgetEur: wtAvg,
        medianBudgetEur: _roundToNearest(wtAvg * 0.89, 100000),
        topQuartileBudgetEur: _roundToNearest(wtAvg * 1.42, 100000),
        minimumViableBudgetEur: _roundToNearest(wtAvg * 0.54, 100000),
        superTeamCeilingBudgetEur: _roundToNearest(wtAvg * 2.05, 250000),
        annualGrowthRatePercent: annualInflationRatePercent,
      ),
      TeamDivision.proTeam: DivisionBudgetBenchmark(
        division: TeamDivision.proTeam,
        seasonYear: effectiveYear,
        averageBudgetEur: ptAvg,
        medianBudgetEur: _roundToNearest(ptAvg * 0.90, 50000),
        topQuartileBudgetEur: _roundToNearest(ptAvg * 1.48, 50000),
        minimumViableBudgetEur: _roundToNearest(ptAvg * 0.50, 50000),
        superTeamCeilingBudgetEur: _roundToNearest(ptAvg * 1.95, 100000),
        annualGrowthRatePercent:
            double.parse((annualInflationRatePercent * 0.85).toStringAsFixed(2)),
      ),
      TeamDivision.continental: DivisionBudgetBenchmark(
        division: TeamDivision.continental,
        seasonYear: effectiveYear,
        averageBudgetEur: contAvg,
        medianBudgetEur: _roundToNearest(contAvg * 0.88, 25000),
        topQuartileBudgetEur: _roundToNearest(contAvg * 1.38, 25000),
        minimumViableBudgetEur: _roundToNearest(contAvg * 0.45, 25000),
        superTeamCeilingBudgetEur: _roundToNearest(contAvg * 1.85, 50000),
        annualGrowthRatePercent:
            double.parse((annualInflationRatePercent * 0.65).toStringAsFixed(2)),
      ),
    };

    return SeasonMacroEconomySnapshot(
      seasonYear: effectiveYear,
      cyclePhase: cyclePhase,
      annualInflationRatePercent: annualInflationRatePercent,
      cumulativeInflationMultiplier: cumulativeInflationMultiplier,
      salaryInflationMultiplier: salaryInflationMultiplier,
      transferFeeInflationMultiplier: transferFeeInflationMultiplier,
      prizePoolInflationMultiplier: prizePoolInflationMultiplier,
      equipmentCostInflationMultiplier: equipmentCostInflationMultiplier,
      marketBoomIndex: marketBoomIndex,
      divisionBenchmarks: Map.unmodifiable(benchmarks),
      activeMegaSponsors: List.unmodifiable(activeSponsors),
      newEntrantsThisSeason: List.unmodifiable(newEntrants),
    );
  }

  /// Waloryzuje budżety sponsorów i koszty utrzymania listy drużyn na nowy sezon.
  List<TeamEconomyAdjustmentResult> applyEconomyToTeams({
    required List<CyclingTeam> teams,
    required SeasonMacroEconomySnapshot snapshot,
    String? playerTeamId,
  }) {
    if (teams.isEmpty) return const [];

    final annualRate = snapshot.annualInflationRatePercent / 100.0;
    final wtFactor = 1.0 + annualRate;
    final ptFactor = 1.0 + annualRate * 0.82;
    final contFactor = 1.0 + annualRate * 0.60;

    // Wybieramy potencjalnych beneficjentów nowych mega-sponsorów spośród ekip AI WorldTour
    final aiWorldTourCandidates = teams
        .where(
          (t) =>
              t.division == TeamDivision.worldTour &&
              t.id != playerTeamId,
        )
        .toList();

    final assignedEntrants = <String, MegaSponsorEntryEvent>{};
    for (int i = 0; i < snapshot.newEntrantsThisSeason.length; i++) {
      if (aiWorldTourCandidates.isEmpty) break;
      final entrant = snapshot.newEntrantsThisSeason[i];
      final target = aiWorldTourCandidates[
          (snapshot.seasonYear + i) % aiWorldTourCandidates.length];
      assignedEntrants[target.id] = entrant.copyWith(
        targetTeamId: target.id,
        targetTeamName: target.name,
      );
    }

    final results = <TeamEconomyAdjustmentResult>[];
    for (final team in teams) {
      final previousIncome = team.annualSponsorIncomeEur;
      final previousBurn = team.monthlyBurnRateEur;

      final divisionFactor = switch (team.division) {
        TeamDivision.worldTour => wtFactor,
        TeamDivision.proTeam => ptFactor,
        TeamDivision.continental => contFactor,
      };

      final megaSponsor = assignedEntrants[team.id];
      final updatedSponsors = <SponsorContract>[];

      for (int idx = 0; idx < team.sponsors.length; idx++) {
        final sponsor = team.sponsors[idx];
        if (idx == 0 && megaSponsor != null) {
          updatedSponsors.add(
            sponsor.copyWith(
              companyName: megaSponsor.sponsorName,
              industry: megaSponsor.industry,
              annualBudgetEur: math.max(
                sponsor.annualBudgetEur,
                megaSponsor.annualCommitmentEur,
              ),
              contractDurationYears: megaSponsor.contractYears,
              sponsorSatisfaction:
                  math.max(sponsor.sponsorSatisfaction, 82.0),
            ),
          );
        } else {
          final scaledBudget = _roundToNearest(
            sponsor.annualBudgetEur * divisionFactor,
            10000,
          );
          updatedSponsors.add(
            sponsor.copyWith(annualBudgetEur: scaledBudget),
          );
        }
      }

      final updatedBikeDeal = team.bikeDeal.copyWith(
        annualCashContributionEur: _roundToNearest(
          team.bikeDeal.annualCashContributionEur *
              (1.0 + annualRate * 0.70),
          10000,
        ),
      );

      final burnMultiplier = megaSponsor != null
          ? (1.0 + annualRate * 1.35)
          : (1.0 + annualRate * 0.85);
      final updatedBurnRate = _roundToNearest(
        previousBurn * burnMultiplier,
        5000,
      );

      final updatedTeam = team.copyWith(
        monthlyBurnRateEur: updatedBurnRate,
        bikeDeal: updatedBikeDeal,
        sponsors: updatedSponsors,
      );

      final newIncome = updatedTeam.annualSponsorIncomeEur;
      final growthPct = previousIncome > 0
          ? ((newIncome - previousIncome) / previousIncome) * 100.0
          : 0.0;

      results.add(
        TeamEconomyAdjustmentResult(
          updatedTeam: updatedTeam,
          previousAnnualIncomeEur: previousIncome,
          newAnnualIncomeEur: newIncome,
          previousMonthlyBurnRateEur: previousBurn,
          newMonthlyBurnRateEur: updatedBurnRate,
          budgetGrowthPercent: double.parse(growthPct.toStringAsFixed(2)),
          awardedMegaSponsor: megaSponsor,
        ),
      );
    }

    return List.unmodifiable(results);
  }

  /// Skaluje kwotę bazową z 2026 roku do realiów wskazanego roku kariery.
  int scaleAmountForYear({
    required int baseAmount2026Eur,
    required int seasonYear,
    bool isSalary = false,
    bool isTransferFee = false,
    int? seed,
  }) {
    if (baseAmount2026Eur <= 0) return 0;
    final snapshot = evaluateSeasonEconomy(
      seasonYear: seasonYear,
      seed: seed,
    );
    final double multiplier;
    if (isTransferFee) {
      multiplier = snapshot.transferFeeInflationMultiplier;
    } else if (isSalary) {
      multiplier = snapshot.salaryInflationMultiplier;
    } else {
      multiplier = snapshot.cumulativeInflationMultiplier;
    }
    return _roundToNearest(baseAmount2026Eur * multiplier, 1000);
  }

  /// Ocenia pozycję budżetową drużyny gracza względem średniej dywizji w danym roku.
  PlayerMarketCompetitivenessReport evaluatePlayerCompetitiveness({
    required CyclingTeam playerTeam,
    required SeasonMacroEconomySnapshot snapshot,
  }) {
    final benchmark = snapshot.divisionBenchmarks[playerTeam.division] ??
        snapshot.divisionBenchmarks[TeamDivision.worldTour]!;

    final playerBudget = playerTeam.annualSponsorIncomeEur;
    final avgBudget = math.max(1, benchmark.averageBudgetEur);
    final gap = playerBudget - avgBudget;
    final ratio = playerBudget / avgBudget;

    final int percentile = (50.0 + (ratio - 1.0) * 42.0)
        .round()
        .clamp(4, 99);

    final String tier;
    final String recommendation;
    if (ratio >= 1.38) {
      tier = 'Super-Team (Top 15%)';
      recommendation =
          'Budżet wyprzedza inflację rynkową — możesz agresywnie licytować liderów GC i inwestować w tunel aero.';
    } else if (ratio >= 0.95) {
      tier = 'Konkurencyjny środek stawki';
      recommendation =
          'Finanse nadążają za boomem WorldTour. Szukaj długoletnich kontraktów z młodymi talentami U23 przed kolejną falą inflacji płac.';
    } else if (ratio >= 0.65) {
      tier = 'Presja inflacyjna (Poniżej średniej)';
      recommendation =
          'Rosnące budżety funduszy inwestycyjnych zwiększają dystans do czołówki. Priorytetem jest wysoka ekspozycja TV i renegocjacja sponsora tytularnego.';
    } else {
      tier = 'Strefa zagrożenia budżetowego';
      recommendation =
          'Budżet odstaje od realiów ${snapshot.seasonYear} r. Bez nowego partnera technologicznego lub awansu w rankingu UCI grozi utrata liderów.';
    }

    return PlayerMarketCompetitivenessReport(
      seasonYear: snapshot.seasonYear,
      division: playerTeam.division,
      playerAnnualBudgetEur: playerBudget,
      divisionAverageBudgetEur: avgBudget,
      divisionTopQuartileBudgetEur: benchmark.topQuartileBudgetEur,
      gapToAverageEur: gap,
      relativeStrengthRatio: double.parse(ratio.toStringAsFixed(2)),
      estimatedBudgetPercentile: percentile,
      tierClassification: tier,
      strategicRecommendation: recommendation,
    );
  }

  /// Generuje zwięzłe podsumowanie ekonomiczne sezonu do skrzynki lub prasy.
  String generateMarketNewsSummary(SeasonMacroEconomySnapshot snapshot) {
    final wtAvg = Formatters.formatCompactCurrency(
      snapshot.worldTourAverageBudgetEur,
    );
    final ptAvg = Formatters.formatCompactCurrency(
      snapshot.proTeamAverageBudgetEur,
    );

    if (snapshot.newEntrantsThisSeason.isNotEmpty) {
      final entrant = snapshot.newEntrantsThisSeason.first;
      return '${entrant.headline} Średni budżet WorldTour w ${snapshot.seasonYear} r. wzrósł do $wtAvg (ProTeam: $ptAvg, inflacja +${snapshot.annualInflationRatePercent.toStringAsFixed(1)}%).';
    }

    return 'Raport ekonomiczny UCI ${snapshot.seasonYear}: faza "${snapshot.cyclePhase.label}". Średni budżet WorldTour wynosi $wtAvg, a indeks koniunktury rynku osiągnął ${snapshot.marketBoomIndex.toStringAsFixed(0)}/100.';
  }

  double _baseInflationCurve(int yearsElapsed) {
    if (yearsElapsed <= 0) return 1.0;
    // Bazowa inflacja 3.4% rocznie + lekka akceleracja w dekadzie 2030s
    return math.pow(1.034, yearsElapsed).toDouble();
  }

  MarketMacroCyclePhase _resolveCyclePhase(int year, int activeMegaCount) {
    if (year >= 2038 || activeMegaCount >= 4) {
      return MarketMacroCyclePhase.goldenEraPeak;
    }
    if (year >= 2033) {
      return MarketMacroCyclePhase.techArmsRace;
    }
    if (year == 2032 || year == 2036) {
      return MarketMacroCyclePhase.consolidationPlateau;
    }
    if (year >= 2027) {
      return MarketMacroCyclePhase.investmentBoom;
    }
    return MarketMacroCyclePhase.organicGrowth;
  }

  double _phaseFactor(MarketMacroCyclePhase phase) {
    switch (phase) {
      case MarketMacroCyclePhase.organicGrowth:
        return 1.00;
      case MarketMacroCyclePhase.investmentBoom:
        return 1.04;
      case MarketMacroCyclePhase.techArmsRace:
        return 1.08;
      case MarketMacroCyclePhase.consolidationPlateau:
        return 1.03;
      case MarketMacroCyclePhase.goldenEraPeak:
        return 1.12;
    }
  }

  String _pickHeadlineTargetTeamName(int year, math.Random rng) {
    const names = [
      'Alpecin-Deceuninck Project',
      'Team Visma Horizon',
      'Ineos Future Lab',
      'UAE Emirates Aero',
      'Lidl-Trek Quantum',
      'Red Bull Bora Vanguard',
      'Soudal Quick-Step Nova',
      'Movistar Iberia Tech',
    ];
    return names[(year + rng.nextInt(names.length)) % names.length];
  }

  int _roundToNearest(double value, int step) {
    if (step <= 0) return value.round();
    return ((value / step).round()) * step;
  }
}

/// Responsywny panel analityczny modelu ekonomicznego 2026–2040.
///
/// Prezentuje trajektorię budżetów WorldTour/ProTeam, wskaźniki inflacji
/// oraz wejścia gigantycznych sponsorów z pełnymi stanami interakcji UI.
class DynamicInflationMarketBoomPanel extends StatefulWidget {
  final int initialSelectedYear;
  final CyclingTeam? playerTeam;
  final DynamicInflationAndMarketBoomService service;
  final ValueChanged<SeasonMacroEconomySnapshot>? onYearSelected;

  const DynamicInflationMarketBoomPanel({
    super.key,
    this.initialSelectedYear = DynamicInflationAndMarketBoomService.baseYear,
    this.playerTeam,
    this.service = const DynamicInflationAndMarketBoomService(),
    this.onYearSelected,
  });

  @override
  State<DynamicInflationMarketBoomPanel> createState() =>
      _DynamicInflationMarketBoomPanelState();
}

class _DynamicInflationMarketBoomPanelState
    extends State<DynamicInflationMarketBoomPanel> {
  late List<SeasonMacroEconomySnapshot> _trajectory;
  late int _selectedYear;
  int _seedOffset = 0;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialSelectedYear.clamp(
      DynamicInflationAndMarketBoomService.baseYear,
      DynamicInflationAndMarketBoomService.horizonEndYear,
    );
    _rebuildTrajectory();
  }

  void _rebuildTrajectory() {
    _trajectory = widget.service.simulateMultiYearTrajectory(
      startYear: DynamicInflationAndMarketBoomService.baseYear,
      endYear: DynamicInflationAndMarketBoomService.horizonEndYear,
      seed: 20260401 + _seedOffset * 131,
    );
  }

  SeasonMacroEconomySnapshot get _currentSnapshot {
    return _trajectory.firstWhere(
      (s) => s.seasonYear == _selectedYear,
      orElse: () => _trajectory.first,
    );
  }

  void _selectYear(int year) {
    final clamped = year.clamp(
      DynamicInflationAndMarketBoomService.baseYear,
      DynamicInflationAndMarketBoomService.horizonEndYear,
    );
    if (clamped == _selectedYear) return;
    setState(() {
      _selectedYear = clamped;
    });
    widget.onYearSelected?.call(_currentSnapshot);
  }

  void _cycleSimulationScenario() {
    setState(() {
      _seedOffset++;
      _rebuildTrajectory();
    });
    widget.onYearSelected?.call(_currentSnapshot);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _currentSnapshot;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final isWideDesktop = constraints.maxWidth >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(snapshot, isCompact),
              const SizedBox(height: 16),
              _buildYearTimelineStrip(isCompact),
              const SizedBox(height: 16),
              _buildKpiRow(snapshot, isCompact),
              const SizedBox(height: 16),
              if (isWideDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildTrajectoryChartCard(snapshot),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _buildMegaSponsorsCard(snapshot),
                    ),
                  ],
                )
              else ...[
                _buildTrajectoryChartCard(snapshot),
                const SizedBox(height: 16),
                _buildMegaSponsorsCard(snapshot),
              ],
              if (widget.playerTeam != null) ...[
                const SizedBox(height: 16),
                _buildPlayerCompetitivenessBanner(snapshot, isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(SeasonMacroEconomySnapshot snapshot, bool isCompact) {
    final phaseColor = snapshot.cyclePhase.accentColor;

    return Wrap(
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
                  Icons.trending_up_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Ekonomia Świata Kolarstwa (2026–2040)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: phaseColor.withValues(alpha: 0.45)),
              ),
              child: Text(
                'Sezon ${snapshot.seasonYear} • ${snapshot.cyclePhase.label}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: phaseColor,
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InteractiveActionPill(
              icon: Icons.chevron_left_rounded,
              label: 'Poprzedni',
              enabled:
                  _selectedYear > DynamicInflationAndMarketBoomService.baseYear,
              onPressed: () => _selectYear(_selectedYear - 1),
            ),
            _InteractiveActionPill(
              icon: Icons.chevron_right_rounded,
              label: 'Następny',
              enabled: _selectedYear <
                  DynamicInflationAndMarketBoomService.horizonEndYear,
              onPressed: () => _selectYear(_selectedYear + 1),
            ),
            _InteractiveActionPill(
              icon: Icons.auto_graph_rounded,
              label: 'Symuluj wariant',
              enabled: true,
              isPrimary: true,
              onPressed: _cycleSimulationScenario,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearTimelineStrip(bool isCompact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in _trajectory) ...[
            _YearChipButton(
              year: item.seasonYear,
              isSelected: item.seasonYear == _selectedYear,
              hasNewMegaSponsor: item.newEntrantsThisSeason.isNotEmpty,
              onPressed: () => _selectYear(item.seasonYear),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow(SeasonMacroEconomySnapshot snapshot, bool isCompact) {
    final cards = [
      _EconomyKpiCard(
        title: 'Śr. Budżet WorldTour',
        value: Formatters.formatCompactCurrency(
          snapshot.worldTourAverageBudgetEur,
        ),
        subtitle:
            '+${snapshot.annualInflationRatePercent.toStringAsFixed(1)}% r/r',
        accent: AppColors.goldAccent,
      ),
      _EconomyKpiCard(
        title: 'Śr. Budżet ProTeam',
        value: Formatters.formatCompactCurrency(
          snapshot.proTeamAverageBudgetEur,
        ),
        subtitle:
            'x${snapshot.cumulativeInflationMultiplier.toStringAsFixed(2)} vs 2026',
        accent: AppColors.accentBlue,
      ),
      _EconomyKpiCard(
        title: 'Indeks Płac & Transferów',
        value:
            'x${snapshot.transferFeeInflationMultiplier.toStringAsFixed(2)}',
        subtitle:
            'Płace: x${snapshot.salaryInflationMultiplier.toStringAsFixed(2)}',
        accent: AppColors.cyanAccent,
      ),
      _EconomyKpiCard(
        title: 'Boom Rynkowy UCI',
        value: '${snapshot.marketBoomIndex.toStringAsFixed(0)}/100',
        subtitle: '${snapshot.activeMegaSponsors.length} mega-sponsorów',
        accent: AppColors.statusSuccess,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
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

  Widget _buildTrajectoryChartCard(SeasonMacroEconomySnapshot snapshot) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Trajektoria Średnich Budżetów WorldTour',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '2026–2040',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: _BudgetTrajectoryChartPainter(
                trajectory: _trajectory,
                selectedYear: snapshot.seasonYear,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.service.generateMarketNewsSummary(snapshot),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMegaSponsorsCard(SeasonMacroEconomySnapshot snapshot) {
    final sponsors = snapshot.activeMegaSponsors;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktywni Giganci Sponsorsyjni',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sponsors.length} aktywnych',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sponsors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'W sezonie otwarcia 2026 rynek opiera się na tradycyjnych sponsorach. Pierwsze fundusze inwestycyjne i giganci Tech wejdą do WorldTour od 2027 r.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < sponsors.length; i++) ...[
                  _MegaSponsorListTile(
                    sponsor: sponsors[i],
                    isNewThisSeason:
                        sponsors[i].seasonYear == snapshot.seasonYear,
                  ),
                  if (i < sponsors.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCompetitivenessBanner(
    SeasonMacroEconomySnapshot snapshot,
    bool isCompact,
  ) {
    final report = widget.service.evaluatePlayerCompetitiveness(
      playerTeam: widget.playerTeam!,
      snapshot: snapshot,
    );
    final statusColor = report.isAboveDivisionAverage
        ? AppColors.statusSuccess
        : AppColors.amberWarning;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Pozycja ${widget.playerTeam!.name}: ${report.tierClassification}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              Text(
                'Percentyl: ${report.estimatedBudgetPercentile}% • Średnia: ${Formatters.formatCompactCurrency(report.divisionAverageBudgetEur)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.strategicRecommendation,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EconomyKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  const _EconomyKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _YearChipButton extends StatefulWidget {
  final int year;
  final bool isSelected;
  final bool hasNewMegaSponsor;
  final VoidCallback onPressed;

  const _YearChipButton({
    required this.year,
    required this.isSelected,
    required this.hasNewMegaSponsor,
    required this.onPressed,
  });

  @override
  State<_YearChipButton> createState() => _YearChipButtonState();
}

class _YearChipButtonState extends State<_YearChipButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.primaryAccent
        : _pressed
            ? AppColors.cardBorder
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
            ? AppColors.accentBlue
            : widget.hasNewMegaSponsor
                ? AppColors.goldAccent.withValues(alpha: 0.45)
                : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.year}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (widget.hasNewMegaSponsor) ...[
                const SizedBox(width: 5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.goldAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _InteractiveActionPill({
    required this.icon,
    required this.label,
    required this.enabled,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionPill> createState() => _InteractiveActionPillState();
}

class _InteractiveActionPillState extends State<_InteractiveActionPill> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;

    final Color bgColor;
    if (!widget.enabled) {
      bgColor = AppColors.background;
    } else if (_pressed) {
      bgColor = baseColor.withValues(alpha: 0.72);
    } else if (_hovered) {
      bgColor = baseColor.withValues(alpha: 0.90);
    } else {
      bgColor = baseColor;
    }

    final borderColor = !widget.enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : _hovered
                ? AppColors.goldAccent.withValues(alpha: 0.65)
                : const Color(0xFF2A2F3D);

    final fgColor = widget.enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.45);

    return FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowHoverHighlight: (val) => setState(() => _hovered = val),
      onShowFocusHighlight: (val) => setState(() => _focused = val),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: fgColor),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MegaSponsorListTile extends StatelessWidget {
  final MegaSponsorEntryEvent sponsor;
  final bool isNewThisSeason;

  const _MegaSponsorListTile({
    required this.sponsor,
    required this.isNewThisSeason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNewThisSeason
              ? AppColors.goldAccent.withValues(alpha: 0.65)
              : const Color(0xFF2A2F3D),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isNewThisSeason
                  ? AppColors.goldAccent
                  : AppColors.statusSuccess,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sponsor.sponsorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sponsor.archetype.label} • Od ${sponsor.seasonYear}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${Formatters.formatCompactCurrency(sponsor.annualCommitmentEur)}/rok',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '+${(sponsor.budgetMultiplierImpact * 100).toStringAsFixed(1)}% rynek',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.statusSuccess,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetTrajectoryChartPainter extends CustomPainter {
  final List<SeasonMacroEconomySnapshot> trajectory;
  final int selectedYear;

  const _BudgetTrajectoryChartPainter({
    required this.trajectory,
    required this.selectedYear,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trajectory.isEmpty || size.width <= 0 || size.height <= 0) return;

    const double padLeft = 10;
    const double padRight = 10;
    const double padTop = 14;
    const double padBottom = 18;
    final chartWidth = math.max(1.0, size.width - padLeft - padRight);
    final chartHeight = math.max(1.0, size.height - padTop - padBottom);

    int minBudget = trajectory.first.worldTourAverageBudgetEur;
    int maxBudget = trajectory.first.worldTourAverageBudgetEur;
    for (final s in trajectory) {
      if (s.worldTourAverageBudgetEur < minBudget) {
        minBudget = s.worldTourAverageBudgetEur;
      }
      if (s.worldTourAverageBudgetEur > maxBudget) {
        maxBudget = s.worldTourAverageBudgetEur;
      }
    }
    final range = math.max(1, maxBudget - minBudget);

    // Siatka pozioma
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;
    for (int g = 0; g <= 3; g++) {
      final y = padTop + chartHeight * (g / 3.0);
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(padLeft + chartWidth, y),
        gridPaint,
      );
    }

    final points = <Offset>[];
    for (int i = 0; i < trajectory.length; i++) {
      final t = trajectory.length == 1 ? 0.0 : i / (trajectory.length - 1);
      final x = padLeft + t * chartWidth;
      final normY =
          (trajectory[i].worldTourAverageBudgetEur - minBudget) / range;
      final y = padTop + chartHeight * (1.0 - normY);
      points.add(Offset(x, y));
    }

    // Wypełnienie gradientowe pod krzywą
    final fillPath = Path()..moveTo(points.first.dx, padTop + chartHeight);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath
      ..lineTo(points.last.dx, padTop + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.30),
          AppColors.goldAccent.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(padLeft, padTop, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // Linia główna
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    final linePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Punkty wejścia mega-sponsorów i punkt wybrany
    for (int i = 0; i < trajectory.length; i++) {
      final item = trajectory[i];
      final pt = points[i];
      final isSelected = item.seasonYear == selectedYear;
      final hasEntrant = item.newEntrantsThisSeason.isNotEmpty;

      if (isSelected) {
        canvas.drawCircle(
          pt,
          7.5,
          Paint()..color = AppColors.goldAccent.withValues(alpha: 0.28),
        );
        canvas.drawCircle(
          pt,
          4.5,
          Paint()..color = AppColors.textPrimary,
        );
      } else if (hasEntrant) {
        canvas.drawCircle(
          pt,
          3.5,
          Paint()..color = AppColors.statusSuccess,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetTrajectoryChartPainter oldDelegate) {
    return oldDelegate.selectedYear != selectedYear ||
        oldDelegate.trajectory != trajectory;
  }
}
