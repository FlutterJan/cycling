// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_appearance.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/rider/rider_health.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_power_profile.dart';
import '../../models/rider/rider_skills.dart';
import '../widgets/contract_negotiation_chat_simulator.dart';

/// Priorytet przedłużenia kontraktu w Centrum Przedłużeń Kontraktów.
enum RenewalPriorityTier {
  leaders,
  keyDomestiques,
  u23Talents;

  String get label {
    switch (this) {
      case RenewalPriorityTier.leaders:
        return 'Liderzy';
      case RenewalPriorityTier.keyDomestiques:
        return 'Klucowi Pomocnicy';
      case RenewalPriorityTier.u23Talents:
        return 'Młode Talenty U23';
    }
  }

  String get shortLabel {
    switch (this) {
      case RenewalPriorityTier.leaders:
        return 'Liderzy';
      case RenewalPriorityTier.keyDomestiques:
        return 'Pomocnicy';
      case RenewalPriorityTier.u23Talents:
        return 'U23';
    }
  }

  String get subtitle {
    switch (this) {
      case RenewalPriorityTier.leaders:
        return 'Filary GC, klasyków i główni sprinterzy';
      case RenewalPriorityTier.keyDomestiques:
        return 'Super-domestiques, silniki pociągu i uciekinierzy';
      case RenewalPriorityTier.u23Talents:
        return 'Rozwojowi kolarze do 23. roku życia i Neo-Pro';
    }
  }

  Color get accentColor {
    switch (this) {
      case RenewalPriorityTier.leaders:
        return AppColors.goldAccent;
      case RenewalPriorityTier.keyDomestiques:
        return AppColors.accentBlue;
      case RenewalPriorityTier.u23Talents:
        return AppColors.statusSuccess;
    }
  }

  IconData get icon {
    switch (this) {
      case RenewalPriorityTier.leaders:
        return Icons.workspace_premium_rounded;
      case RenewalPriorityTier.keyDomestiques:
        return Icons.shield_rounded;
      case RenewalPriorityTier.u23Talents:
        return Icons.trending_up_rounded;
    }
  }
}

/// Status negocjacji przedłużenia kontraktu dla kolarza w War Roomie.
enum RenewalNegotiationState {
  expiring,
  negotiating,
  renewed,
  declined;

  String get label {
    switch (this) {
      case RenewalNegotiationState.expiring:
        return 'Wygasa 31 XII';
      case RenewalNegotiationState.negotiating:
        return 'W trakcie rozmów';
      case RenewalNegotiationState.renewed:
        return 'Przedłużono';
      case RenewalNegotiationState.declined:
        return 'Zerwano rozmowy';
    }
  }

  Color get badgeColor {
    switch (this) {
      case RenewalNegotiationState.expiring:
        return AppColors.amberWarning;
      case RenewalNegotiationState.negotiating:
        return AppColors.accentBlue;
      case RenewalNegotiationState.renewed:
        return AppColors.statusSuccess;
      case RenewalNegotiationState.declined:
        return AppColors.crimsonAlert;
    }
  }
}

/// Kryterium filtrowania statusu w Centrum Przedłużeń Kontraktów.
enum RenewalStatusFilter {
  all,
  actionRequired,
  renewed,
  declined;

  String get label {
    switch (this) {
      case RenewalStatusFilter.all:
        return 'Wszystkie';
      case RenewalStatusFilter.actionRequired:
        return 'Do przedłużenia';
      case RenewalStatusFilter.renewed:
        return 'Przedłużone';
      case RenewalStatusFilter.declined:
        return 'Zerwane';
    }
  }
}

/// Kryterium sortowania kolarzy na liście przedłużeń.
enum RenewalSortMode {
  priorityAndSalary,
  salaryDescending,
  potentialDescending,
  ageAscending;

  String get label {
    switch (this) {
      case RenewalSortMode.priorityAndSalary:
        return 'Priorytet + Pensja';
      case RenewalSortMode.salaryDescending:
        return 'Pensja malejąco';
      case RenewalSortMode.potentialDescending:
        return 'Potencjał malejąco';
      case RenewalSortMode.ageAscending:
        return 'Wiek rosnąco';
    }
  }
}

/// Wpis pojedynczego kolarza w Centrum Przedłużeń Kontraktów.
class RenewalCandidateEntry {
  final Rider rider;
  final RenewalPriorityTier priorityTier;
  final RenewalNegotiationState status;
  final int currentAnnualSalaryEur;
  final int projectedAnnualSalaryEur;
  final int proposedYears;
  final bool includedInForecast;
  final bool hasRivalInterest;
  final int marketDemandRaisePercent;

  const RenewalCandidateEntry({
    required this.rider,
    required this.priorityTier,
    required this.status,
    required this.currentAnnualSalaryEur,
    required this.projectedAnnualSalaryEur,
    required this.proposedYears,
    required this.includedInForecast,
    required this.hasRivalInterest,
    required this.marketDemandRaisePercent,
  });

  int get annualSalaryDeltaEur =>
      projectedAnnualSalaryEur - currentAnnualSalaryEur;

  int ageAtSeason(int seasonYear) =>
      math.max(18, seasonYear - rider.birthDate.year);

  RenewalCandidateEntry copyWith({
    Rider? rider,
    RenewalPriorityTier? priorityTier,
    RenewalNegotiationState? status,
    int? currentAnnualSalaryEur,
    int? projectedAnnualSalaryEur,
    int? proposedYears,
    bool? includedInForecast,
    bool? hasRivalInterest,
    int? marketDemandRaisePercent,
  }) {
    return RenewalCandidateEntry(
      rider: rider ?? this.rider,
      priorityTier: priorityTier ?? this.priorityTier,
      status: status ?? this.status,
      currentAnnualSalaryEur:
          currentAnnualSalaryEur ?? this.currentAnnualSalaryEur,
      projectedAnnualSalaryEur:
          projectedAnnualSalaryEur ?? this.projectedAnnualSalaryEur,
      proposedYears: proposedYears ?? this.proposedYears,
      includedInForecast: includedInForecast ?? this.includedInForecast,
      hasRivalInterest: hasRivalInterest ?? this.hasRivalInterest,
      marketDemandRaisePercent:
          marketDemandRaisePercent ?? this.marketDemandRaisePercent,
    );
  }
}

/// Podsumowanie prognozy budżetu płacowego na kolejny sezon.
class NextSeasonPayrollForecast {
  final int seasonYear;
  final int annualWageBudgetEur;
  final int currentSeasonPayrollEur;
  final int committedNextSeasonPayrollEur;
  final int renewedCommitmentsEur;
  final int projectedPendingRenewalsEur;
  final Map<RenewalPriorityTier, int> tierProjectedSpendEur;
  final int expiringCount;
  final int renewedCount;

  const NextSeasonPayrollForecast({
    required this.seasonYear,
    required this.annualWageBudgetEur,
    required this.currentSeasonPayrollEur,
    required this.committedNextSeasonPayrollEur,
    required this.renewedCommitmentsEur,
    required this.projectedPendingRenewalsEur,
    required this.tierProjectedSpendEur,
    required this.expiringCount,
    required this.renewedCount,
  });

  int get totalProjectedNextSeasonPayrollEur =>
      committedNextSeasonPayrollEur +
      renewedCommitmentsEur +
      projectedPendingRenewalsEur;

  int get remainingHeadroomEur =>
      annualWageBudgetEur - totalProjectedNextSeasonPayrollEur;

  bool get isOverBudget => remainingHeadroomEur < 0;

  double get budgetUtilizationRatio => annualWageBudgetEur <= 0
      ? 0.0
      : (totalProjectedNextSeasonPayrollEur / annualWageBudgetEur)
          .clamp(0.0, 2.0);

  int get payrollYoYDeltaEur =>
      totalProjectedNextSeasonPayrollEur - currentSeasonPayrollEur;
}

/// Wynik aktualizacji kontraktów przekazywany do warstwy nadrzędnej.
class ContractRenewalsOutcome {
  final int seasonYear;
  final List<RenewalCandidateEntry> entries;
  final NextSeasonPayrollForecast forecast;

  const ContractRenewalsOutcome({
    required this.seasonYear,
    required this.entries,
    required this.forecast,
  });
}

/// Kalkulator klasyfikacji priorytetów i prognozy budżetu płacowego na kolejny sezon.
class ContractRenewalsWarRoomCalculator {
  ContractRenewalsWarRoomCalculator._();

  /// Klasyfikuje kolarza do jednego z 3 priorytetów: Liderzy, Kluczowi Pomocnicy, Młode Talenty U23.
  static RenewalPriorityTier classifyPriority(
    Rider rider, {
    required int seasonYear,
  }) {
    final age = seasonYear - rider.birthDate.year;
    if (rider.contract.role == RiderRole.neoPro || age <= 23) {
      return RenewalPriorityTier.u23Talents;
    }
    if (rider.contract.role == RiderRole.teamLeader ||
        rider.contract.role == RiderRole.coLeader ||
        rider.contract.role == RiderRole.sprinter) {
      return RenewalPriorityTier.leaders;
    }
    return RenewalPriorityTier.keyDomestiques;
  }

  /// Szacuje oczekiwaną podwyżkę rynkową [%] przy przedłużeniu kontraktu.
  static int estimateMarketRaisePercent(
    Rider rider, {
    required RenewalPriorityTier tier,
  }) {
    final baseRaise = switch (tier) {
      RenewalPriorityTier.leaders => 14,
      RenewalPriorityTier.keyDomestiques => 9,
      RenewalPriorityTier.u23Talents => 24,
    };
    final potentialBonus = rider.potential >= 88
        ? 6
        : rider.potential >= 82
            ? 3
            : 0;
    return baseRaise + potentialBonus;
  }

  /// Buduje listę kandydatów do przedłużenia spośród wygasających kontraktów w danym sezonie.
  static List<RenewalCandidateEntry> buildEntries(
    List<Rider> roster, {
    required int seasonYear,
  }) {
    final expiringRiders = roster
        .where((r) => r.contract.isExpiring(seasonYear))
        .toList(growable: false);

    return expiringRiders.map((rider) {
      final tier = classifyPriority(rider, seasonYear: seasonYear);
      final currentAnnual = rider.contract.annualSalaryEur;
      final raisePct = estimateMarketRaisePercent(rider, tier: tier);
      final projectedAnnual =
          ((currentAnnual * (100 + raisePct)) / 100.0).round();
      final rivalInterest =
          rider.potential >= 84 || rider.careerPointsUci >= 1100;

      return RenewalCandidateEntry(
        rider: rider,
        priorityTier: tier,
        status: RenewalNegotiationState.expiring,
        currentAnnualSalaryEur: currentAnnual,
        projectedAnnualSalaryEur: projectedAnnual,
        proposedYears: tier == RenewalPriorityTier.u23Talents ? 3 : 2,
        includedInForecast: true,
        hasRivalInterest: rivalInterest,
        marketDemandRaisePercent: raisePct,
      );
    }).toList(growable: false);
  }

  /// Oblicza pełną prognozę budżetu płacowego na kolejny sezon (`seasonYear + 1`).
  static NextSeasonPayrollForecast computeForecast({
    required List<Rider> fullRoster,
    required List<RenewalCandidateEntry> entries,
    required int seasonYear,
    required int annualWageBudgetEur,
    double extraMarketBufferPercent = 0.0,
  }) {
    final currentSeasonPayroll = fullRoster.fold<int>(
      0,
      (sum, r) => sum + r.contract.annualSalaryEur,
    );

    final committedNextSeason = fullRoster
        .where((r) => !r.contract.isExpiring(seasonYear))
        .fold<int>(0, (sum, r) => sum + r.contract.annualSalaryEur);

    int renewedCommitments = 0;
    int projectedPending = 0;
    int expiringCount = 0;
    int renewedCount = 0;

    final tierTotals = <RenewalPriorityTier, int>{
      RenewalPriorityTier.leaders: 0,
      RenewalPriorityTier.keyDomestiques: 0,
      RenewalPriorityTier.u23Talents: 0,
    };

    for (final entry in entries) {
      if (entry.status == RenewalNegotiationState.renewed) {
        renewedCommitments += entry.projectedAnnualSalaryEur;
        renewedCount++;
        tierTotals[entry.priorityTier] =
            (tierTotals[entry.priorityTier] ?? 0) +
                entry.projectedAnnualSalaryEur;
      } else if (entry.status == RenewalNegotiationState.expiring ||
          entry.status == RenewalNegotiationState.negotiating) {
        expiringCount++;
        if (entry.includedInForecast) {
          final bufferedSalary = (entry.projectedAnnualSalaryEur *
                  (1.0 + extraMarketBufferPercent / 100.0))
              .round();
          projectedPending += bufferedSalary;
          tierTotals[entry.priorityTier] =
              (tierTotals[entry.priorityTier] ?? 0) + bufferedSalary;
        }
      }
    }

    return NextSeasonPayrollForecast(
      seasonYear: seasonYear,
      annualWageBudgetEur: annualWageBudgetEur,
      currentSeasonPayrollEur: currentSeasonPayroll,
      committedNextSeasonPayrollEur: committedNextSeason,
      renewedCommitmentsEur: renewedCommitments,
      projectedPendingRenewalsEur: projectedPending,
      tierProjectedSpendEur: Map<RenewalPriorityTier, int>.unmodifiable(
        tierTotals,
      ),
      expiringCount: expiringCount,
      renewedCount: renewedCount,
    );
  }

  /// Domyślna kadra zespołu z kontraktami wygasającymi i ważnymi na potrzeby trybu standalone.
  static List<Rider> buildDefaultRoster({int seasonYear = 2027}) {
    Rider makeRider({
      required String id,
      required String firstName,
      required String lastName,
      required String nat,
      required int birthYear,
      required RiderSpecialization spec,
      required RiderRole role,
      required int monthlySalaryEur,
      required int contractEndYear,
      required int potential,
      required int ftp,
      required int uciPoints,
    }) {
      return Rider(
        id: id,
        firstName: firstName,
        lastName: lastName,
        nationalityIso: nat,
        birthDate: DateTime(birthYear, 4, 12),
        potential: potential,
        specialization: spec,
        physiology: RiderPhysiology(
          heightCm: 179,
          weightKg: 67.5,
          bodyFatPercentage: 7.2,
          ftpWatts: ftp,
          wPrimeJoules: 23500,
          vo2Max: 81.0,
          maxHr: 193,
          restingHr: 39,
          lactateThresholdHr: 175,
          recoveryRate: 84.0,
          glycogenCapacityGrams: 540.0,
        ),
        powerProfile: RiderPowerProfile(
          watts5s: (ftp * 3.0).round(),
          watts15s: (ftp * 2.5).round(),
          watts30s: (ftp * 2.0).round(),
          watts1m: (ftp * 1.62).round(),
          watts3m: (ftp * 1.24).round(),
          watts5m: (ftp * 1.15).round(),
          watts20m: (ftp * 1.05).round(),
          watts60m: ftp,
        ),
        skills: const RiderSkills(
          cobbles: 76,
          descending: 80,
          bikeHandling: 81,
          aeroPositioning: 82,
          draftingEfficiency: 83,
          raceIq: 84,
          rainResistance: 78,
          heatTolerance: 77,
          timeTrialPositioning: 80,
        ),
        appearance: const RiderAppearance(
          faceShapeIndex: 1,
          skinToneHex: '#E0B59A',
          hairStyleIndex: 2,
          hairColorHex: '#3B2F2F',
          facialHairIndex: 0,
          glassesModelId: 'aero_shield',
          glassesLensColorHex: '#38BDF8',
          helmetModelId: 'aero_road',
          shoeColorHex: '#FFFFFF',
          sockHeightProportion: 0.72,
          bodyBuildType: BodyBuildType.allRounder,
        ),
        contract: RiderContract(
          teamId: 'team_obsidian',
          role: role,
          monthlySalaryEur: monthlySalaryEur,
          signingBonusEur: 15000,
          winBonusEur: 6000,
          releaseClauseEur: monthlySalaryEur * 24,
          contractEndYear: contractEndYear,
          morale: 82.0,
          leaderLoyalty: 84.0,
          requiredRacesIds: const ['tour_de_france'],
        ),
        health: const RiderHealth(
          acuteTrainingLoad: 44.0,
          chronicTrainingLoad: 68.0,
        ),
        careerPointsUci: uciPoints,
      );
    }

    return [
      // Wygasający Liderzy
      makeRider(
        id: 'war_leader_1',
        firstName: 'Michał',
        lastName: 'Kowalski',
        nat: 'POL',
        birthYear: 1999,
        spec: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        monthlySalaryEur: 115000,
        contractEndYear: seasonYear,
        potential: 92,
        ftp: 448,
        uciPoints: 2350,
      ),
      makeRider(
        id: 'war_leader_2',
        firstName: 'Lucas',
        lastName: 'Vandenberg',
        nat: 'BEL',
        birthYear: 1998,
        spec: RiderSpecialization.pureSprinter,
        role: RiderRole.sprinter,
        monthlySalaryEur: 82000,
        contractEndYear: seasonYear,
        potential: 89,
        ftp: 418,
        uciPoints: 1840,
      ),
      // Wygasający Kluczowi Pomocnicy
      makeRider(
        id: 'war_dom_1',
        firstName: 'Matteo',
        lastName: 'Bellini',
        nat: 'ITA',
        birthYear: 1997,
        spec: RiderSpecialization.domestiqueEngine,
        role: RiderRole.superDomestique,
        monthlySalaryEur: 42000,
        contractEndYear: seasonYear,
        potential: 84,
        ftp: 410,
        uciPoints: 890,
      ),
      makeRider(
        id: 'war_dom_2',
        firstName: 'Kasper',
        lastName: 'Lindqvist',
        nat: 'DEN',
        birthYear: 1996,
        spec: RiderSpecialization.classicCobbles,
        role: RiderRole.domestique,
        monthlySalaryEur: 28000,
        contractEndYear: seasonYear,
        potential: 80,
        ftp: 398,
        uciPoints: 540,
      ),
      // Wygasające Młode Talenty U23
      makeRider(
        id: 'war_u23_1',
        firstName: 'Kacper',
        lastName: 'Nowak',
        nat: 'POL',
        birthYear: seasonYear - 21,
        spec: RiderSpecialization.pureClimber,
        role: RiderRole.neoPro,
        monthlySalaryEur: 12000,
        contractEndYear: seasonYear,
        potential: 91,
        ftp: 402,
        uciPoints: 620,
      ),
      makeRider(
        id: 'war_u23_2',
        firstName: 'Théo',
        lastName: 'Marchand',
        nat: 'FRA',
        birthYear: seasonYear - 20,
        spec: RiderSpecialization.puncher,
        role: RiderRole.neoPro,
        monthlySalaryEur: 9500,
        contractEndYear: seasonYear,
        potential: 87,
        ftp: 388,
        uciPoints: 410,
      ),
      // Kolarze z ważnym kontraktem na kolejny sezon (baza płacowa)
      makeRider(
        id: 'war_committed_1',
        firstName: 'Jonas',
        lastName: 'Sorensen',
        nat: 'DEN',
        birthYear: 2000,
        spec: RiderSpecialization.timeTrialist,
        role: RiderRole.coLeader,
        monthlySalaryEur: 95000,
        contractEndYear: seasonYear + 2,
        potential: 88,
        ftp: 440,
        uciPoints: 1620,
      ),
      makeRider(
        id: 'war_committed_2',
        firstName: 'David',
        lastName: 'Alvarez',
        nat: 'ESP',
        birthYear: 1998,
        spec: RiderSpecialization.breakawaySpecialist,
        role: RiderRole.superDomestique,
        monthlySalaryEur: 48000,
        contractEndYear: seasonYear + 1,
        potential: 83,
        ftp: 412,
        uciPoints: 760,
      ),
    ];
  }
}

/// Ekran Centrum Przedłużeń Kontraktów (`ContractRenewalsWarRoomScreen`).
///
/// Prezentuje wygasające umowy w podziale na trzy priorytety:
/// - **Liderzy**
/// - **Klucowi Pomocnicy**
/// - **Młode Talenty U23**
///
/// Zawiera interaktywną prognozę budżetu płacowego na kolejny sezon oraz
/// przycisk natychmiastowych negocjacji uruchamiający symulator rozmów z agentem.
class ContractRenewalsWarRoomScreen extends ConsumerStatefulWidget {
  final List<Rider>? riders;
  final int seasonYear;
  final int annualWageBudgetEur;
  final bool isReadOnly;
  final ValueChanged<ContractRenewalsOutcome>? onContractsUpdated;
  final Duration negotiationReplyDelay;

  const ContractRenewalsWarRoomScreen({
    super.key,
    this.riders,
    this.seasonYear = 2027,
    this.annualWageBudgetEur = 6800000,
    this.isReadOnly = false,
    this.onContractsUpdated,
    this.negotiationReplyDelay = const Duration(milliseconds: 320),
  });

  @override
  ConsumerState<ContractRenewalsWarRoomScreen> createState() =>
      _ContractRenewalsWarRoomScreenState();
}

class _ContractRenewalsWarRoomScreenState
    extends ConsumerState<ContractRenewalsWarRoomScreen> {
  static const TextStyle _interBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  static const TextStyle _tabularBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  late List<Rider> _fullRoster;
  late List<RenewalCandidateEntry> _entries;
  RenewalPriorityTier? _selectedTierFilter;
  RenewalStatusFilter _statusFilter = RenewalStatusFilter.all;
  RenewalSortMode _sortMode = RenewalSortMode.priorityAndSalary;
  String _searchQuery = '';
  double _marketBufferPercent = 0.0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant ContractRenewalsWarRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riders != widget.riders ||
        oldWidget.seasonYear != widget.seasonYear) {
      _initData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initData() {
    _fullRoster = widget.riders ??
        ContractRenewalsWarRoomCalculator.buildDefaultRoster(
          seasonYear: widget.seasonYear,
        );
    _entries = ContractRenewalsWarRoomCalculator.buildEntries(
      _fullRoster,
      seasonYear: widget.seasonYear,
    );
  }

  NextSeasonPayrollForecast get _forecast {
    return ContractRenewalsWarRoomCalculator.computeForecast(
      fullRoster: _fullRoster,
      entries: _entries,
      seasonYear: widget.seasonYear,
      annualWageBudgetEur: widget.annualWageBudgetEur,
      extraMarketBufferPercent: _marketBufferPercent,
    );
  }

  void _notifyParent() {
    widget.onContractsUpdated?.call(
      ContractRenewalsOutcome(
        seasonYear: widget.seasonYear,
        entries: List<RenewalCandidateEntry>.unmodifiable(_entries),
        forecast: _forecast,
      ),
    );
  }

  void _toggleForecastInclusion(String riderId, bool included) {
    if (widget.isReadOnly) return;
    setState(() {
      _entries = _entries.map((entry) {
        if (entry.rider.id == riderId) {
          return entry.copyWith(includedInForecast: included);
        }
        return entry;
      }).toList(growable: false);
    });
    _notifyParent();
  }

  List<RenewalCandidateEntry> _filteredEntriesForTier(
    RenewalPriorityTier tier,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _entries.where((entry) {
      if (entry.priorityTier != tier) return false;

      final matchesStatus = switch (_statusFilter) {
        RenewalStatusFilter.all => true,
        RenewalStatusFilter.actionRequired =>
          entry.status == RenewalNegotiationState.expiring ||
              entry.status == RenewalNegotiationState.negotiating,
        RenewalStatusFilter.renewed =>
          entry.status == RenewalNegotiationState.renewed,
        RenewalStatusFilter.declined =>
          entry.status == RenewalNegotiationState.declined,
      };
      if (!matchesStatus) return false;

      if (query.isNotEmpty) {
        final fullName = entry.rider.fullName.toLowerCase();
        final nat = entry.rider.nationalityIso.toLowerCase();
        final spec = entry.rider.specialization.displayName.toLowerCase();
        if (!fullName.contains(query) &&
            !nat.contains(query) &&
            !spec.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList(growable: true);

    filtered.sort((a, b) {
      switch (_sortMode) {
        case RenewalSortMode.priorityAndSalary:
        case RenewalSortMode.salaryDescending:
          return b.projectedAnnualSalaryEur
              .compareTo(a.projectedAnnualSalaryEur);
        case RenewalSortMode.potentialDescending:
          return b.rider.potential.compareTo(a.rider.potential);
        case RenewalSortMode.ageAscending:
          return a
              .ageAtSeason(widget.seasonYear)
              .compareTo(b.ageAtSeason(widget.seasonYear));
      }
    });

    return filtered;
  }

  Future<void> _openInstantNegotiation(RenewalCandidateEntry entry) async {
    if (widget.isReadOnly) return;

    setState(() {
      _entries = _entries.map((item) {
        if (item.rider.id == entry.rider.id &&
            item.status == RenewalNegotiationState.expiring) {
          return item.copyWith(status: RenewalNegotiationState.negotiating);
        }
        return item;
      }).toList(growable: false);
    });

    final suggestedMonthly = (entry.projectedAnnualSalaryEur / 12).round();
    final initialDemand = ContractOfferTerms(
      monthlySalaryEur: suggestedMonthly,
      contractYears: entry.proposedYears,
      signingBonusEur: math.max(5000, entry.rider.contract.signingBonusEur),
      winBonusEur: math.max(2500, entry.rider.contract.winBonusEur),
      role: entry.rider.contract.role,
    );
    final initialOffer = ContractOfferTerms(
      monthlySalaryEur:
          math.max(3000, (entry.currentAnnualSalaryEur / 12).round()),
      contractYears: entry.proposedYears,
      signingBonusEur: entry.rider.contract.signingBonusEur,
      winBonusEur: entry.rider.contract.winBonusEur,
      role: entry.rider.contract.role,
    );

    final outcome = await showDialog<ContractNegotiationOutcome>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        ContractNegotiationOutcome? latestOutcome;
        final size = MediaQuery.sizeOf(dialogContext);
        final isCompact = size.width < 700;
        final dialogWidth = isCompact ? size.width - 24 : 840.0;
        final dialogHeight =
            isCompact ? math.min(size.height - 48, 700.0) : 640.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 24,
            vertical: isCompact ? 16 : 24,
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.handshake_rounded,
                        color: entry.priorityTier.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Natychmiastowe negocjacje — ${entry.rider.fullName}',
                          overflow: TextOverflow.ellipsis,
                          style: _interBase.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zamknij okno negocjacji',
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(latestOutcome),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ContractNegotiationChatSimulator(
                      rider: entry.rider,
                      initialAgentDemand: initialDemand,
                      initialManagerOffer: initialOffer,
                      agentReplyDelay: widget.negotiationReplyDelay,
                      onNegotiationComplete: (result) {
                        latestOutcome = result;
                        if (Navigator.of(dialogContext).canPop()) {
                          Navigator.of(dialogContext).pop(result);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (outcome != null) {
      setState(() {
        _entries = _entries.map((item) {
          if (item.rider.id != entry.rider.id) return item;
          if (outcome.status == ContractNegotiationStatus.accepted) {
            final newAnnual = outcome.finalTerms.monthlySalaryEur * 12;
            final updatedRider = item.rider.copyWith(
              contract: item.rider.contract.copyWith(
                monthlySalaryEur: outcome.finalTerms.monthlySalaryEur,
                signingBonusEur: outcome.finalTerms.signingBonusEur,
                winBonusEur: outcome.finalTerms.winBonusEur,
                role: outcome.finalTerms.role,
                contractEndYear:
                    widget.seasonYear + outcome.finalTerms.contractYears,
              ),
            );
            return item.copyWith(
              rider: updatedRider,
              status: RenewalNegotiationState.renewed,
              projectedAnnualSalaryEur: newAnnual,
              proposedYears: outcome.finalTerms.contractYears,
              includedInForecast: true,
            );
          } else if (outcome.status == ContractNegotiationStatus.walkedAway) {
            return item.copyWith(
              status: RenewalNegotiationState.declined,
              includedInForecast: false,
            );
          }
          return item;
        }).toList(growable: false);
      });
      _notifyParent();

      final snackText = outcome.status == ContractNegotiationStatus.accepted
          ? 'Przedłużono kontrakt: ${entry.rider.fullName} (${Formatters.formatCurrency(outcome.finalTerms.monthlySalaryEur * 12)}/rok).'
          : 'Agent ${entry.rider.fullName} przerwał rozmowy kontraktowe.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          content: Text(
            snackText,
            style: _interBase.copyWith(color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final forecast = _forecast;
    final visibleTiers = _selectedTierFilter != null
        ? <RenewalPriorityTier>[_selectedTierFilter!]
        : RenewalPriorityTier.values;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1280;
            final isTablet = width >= 760 && width < 1280;
            final horizontalPadding = width < 600 ? 12.0 : 20.0;

            return Column(
              children: [
                _buildHeader(context, forecast, isCompact: width < 700),
                Expanded(
                  child: isDesktop
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            12,
                            horizontalPadding,
                            16,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 380,
                                child: SingleChildScrollView(
                                  child: _buildForecastPanel(forecast),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildFilterBar(isCompact: false),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: _buildPrioritySections(
                                          visibleTiers: visibleTiers,
                                          columns: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            12,
                            horizontalPadding,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildForecastPanel(forecast),
                              const SizedBox(height: 14),
                              _buildFilterBar(isCompact: !isTablet),
                              const SizedBox(height: 14),
                              _buildPrioritySections(
                                visibleTiers: visibleTiers,
                                columns: isTablet ? 2 : 1,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    NextSeasonPayrollForecast forecast, {
    required bool isCompact,
  }) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canPop) ...[
                _InteractiveWarRoomIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Powrót',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Centrum Przedłużeń Kontraktów',
                      overflow: TextOverflow.ellipsis,
                      style: _interBase.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'War Room • Okno sezonowe ${widget.seasonYear}/${widget.seasonYear + 1}',
                      overflow: TextOverflow.ellipsis,
                      style: _interBase.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderStatPill(
                label: 'Wygasające',
                value: '${forecast.expiringCount}',
                color: AppColors.amberWarning,
              ),
              _HeaderStatPill(
                label: 'Przedłużone',
                value: '${forecast.renewedCount}',
                color: AppColors.statusSuccess,
              ),
              if (widget.isReadOnly)
                const _HeaderStatPill(
                  label: 'Tryb',
                  value: 'Podgląd',
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastPanel(NextSeasonPayrollForecast forecast) {
    final headroom = forecast.remainingHeadroomEur;
    final isOver = forecast.isOverBudget;
    final statusColor =
        isOver ? AppColors.crimsonAlert : AppColors.statusSuccess;

    final totalBudget = math.max(1, forecast.annualWageBudgetEur);
    final committedShare =
        (forecast.committedNextSeasonPayrollEur / totalBudget).clamp(0.0, 1.0);
    final renewedShare =
        (forecast.renewedCommitmentsEur / totalBudget).clamp(0.0, 1.0);
    final pendingShare =
        (forecast.projectedPendingRenewalsEur / totalBudget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver
              ? AppColors.crimsonAlert.withValues(alpha: 0.7)
              : AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prognoza Budżetu Płacowego ${widget.seasonYear + 1}',
                  style: _interBase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ForecastMetricTile(
                  label: 'Prognoza ${widget.seasonYear + 1}',
                  value: Formatters.formatCurrency(
                    forecast.totalProjectedNextSeasonPayrollEur,
                  ),
                  valueColor: isOver
                      ? AppColors.crimsonAlert
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ForecastMetricTile(
                  label: 'Limit płacowy',
                  value: Formatters.formatCurrency(
                    forecast.annualWageBudgetEur,
                  ),
                  valueColor: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOver
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOver
                        ? 'Przekroczenie limitu o ${Formatters.formatCurrency(headroom.abs())}'
                        : 'Wolny margines płacowy: ${Formatters.formatCurrency(headroom)}',
                    style: _tabularBase.copyWith(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Segmentowy pasek wykorzystania budżetu
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: LayoutBuilder(
                builder: (context, barConstraints) {
                  final maxW = barConstraints.maxWidth;
                  final wCommitted = maxW * committedShare;
                  final wRenewed =
                      math.min(maxW - wCommitted, maxW * renewedShare);
                  final wPending = math.min(
                    maxW - wCommitted - wRenewed,
                    maxW * pendingShare,
                  );
                  return Stack(
                    children: [
                      Container(color: AppColors.surfaceLight),
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            width: wCommitted,
                            color: AppColors.textSecondary,
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            width: wRenewed,
                            color: AppColors.statusSuccess,
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            width: wPending,
                            color: isOver
                                ? AppColors.crimsonAlert
                                : AppColors.goldAccent,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: AppColors.textSecondary,
                label:
                    'Ważne umowy (${Formatters.formatCurrency(forecast.committedNextSeasonPayrollEur)})',
              ),
              _LegendDot(
                color: AppColors.statusSuccess,
                label:
                    'Przedłużone (${Formatters.formatCurrency(forecast.renewedCommitmentsEur)})',
              ),
              _LegendDot(
                color: isOver ? AppColors.crimsonAlert : AppColors.goldAccent,
                label:
                    'Planowane (${Formatters.formatCurrency(forecast.projectedPendingRenewalsEur)})',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 12),
          Text(
            'Alokacja przedłużeń wg priorytetów',
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final tier in RenewalPriorityTier.values) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(tier.icon, size: 15, color: tier.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tier.label,
                      style: _interBase.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.formatCurrency(
                      forecast.tierProjectedSpendEur[tier] ?? 0,
                    ),
                    style: _tabularBase.copyWith(
                      color: tier.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bufor inflacji rynkowej (+${_marketBufferPercent.round()}%)',
                  style: _tabularBase.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'Sezon ${widget.seasonYear}: ${Formatters.formatCurrency(forecast.currentSeasonPayrollEur)}',
                style: _tabularBase.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _marketBufferPercent,
              min: -10,
              max: 25,
              divisions: 7,
              onChanged: widget.isReadOnly
                  ? null
                  : (val) => setState(() => _marketBufferPercent = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PriorityFilterChip(
                label: 'Wszystkie priorytety',
                isSelected: _selectedTierFilter == null,
                accentColor: AppColors.primaryAccent,
                onTap: () => setState(() => _selectedTierFilter = null),
              ),
              for (final tier in RenewalPriorityTier.values)
                _PriorityFilterChip(
                  key: ValueKey<String>('filter_tier_${tier.name}'),
                  label: tier.label,
                  isSelected: _selectedTierFilter == tier,
                  accentColor: tier.accentColor,
                  onTap: () => setState(() => _selectedTierFilter = tier),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 230,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: _interBase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj kolarza lub kraju...',
                    hintStyle: _interBase.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.borderColor,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.goldAccent,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  ),
                  child: DropdownButton<RenewalStatusFilter>(
                    value: _statusFilter,
                    dropdownColor: AppColors.surfaceLight,
                    style: _interBase.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    items: RenewalStatusFilter.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _statusFilter = val);
                    },
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  ),
                  child: DropdownButton<RenewalSortMode>(
                    value: _sortMode,
                    dropdownColor: AppColors.surfaceLight,
                    style: _interBase.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    items: RenewalSortMode.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sortMode = val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySections({
    required List<RenewalPriorityTier> visibleTiers,
    required int columns,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tier in visibleTiers) ...[
          _buildTierSection(tier, columns: columns),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTierSection(
    RenewalPriorityTier tier, {
    required int columns,
  }) {
    final entries = _filteredEntriesForTier(tier);
    final tierTotal = entries.fold<int>(
      0,
      (sum, e) => sum + e.projectedAnnualSalaryEur,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: tier.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tier.accentColor.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Icon(tier.icon, color: tier.accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tier.label} (${entries.length})',
                      style: _interBase.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tier.subtitle,
                      style: _interBase.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.formatCurrency(tierTotal),
                style: _tabularBase.copyWith(
                  color: tier.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
              ),
              child: Text(
                'Brak kolarzy spełniających kryteria w grupie ${tier.label}.',
                textAlign: TextAlign.center,
                style: _interBase.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          else if (columns == 1)
            Column(
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  _RiderRenewalCard(
                    entry: entries[i],
                    seasonYear: widget.seasonYear,
                    isReadOnly: widget.isReadOnly,
                    onToggleForecast: (val) =>
                        _toggleForecastInclusion(entries[i].rider.id, val),
                    onInstantNegotiate: () =>
                        _openInstantNegotiation(entries[i]),
                  ),
                  if (i < entries.length - 1) const SizedBox(height: 10),
                ],
              ],
            )
          else
            LayoutBuilder(
              builder: (context, gridConstraints) {
                final cardWidth = (gridConstraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in entries)
                      SizedBox(
                        width: cardWidth,
                        child: _RiderRenewalCard(
                          entry: entry,
                          seasonYear: widget.seasonYear,
                          isReadOnly: widget.isReadOnly,
                          onToggleForecast: (val) =>
                              _toggleForecastInclusion(entry.rider.id, val),
                          onInstantNegotiate: () =>
                              _openInstantNegotiation(entry),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RiderRenewalCard extends StatefulWidget {
  final RenewalCandidateEntry entry;
  final int seasonYear;
  final bool isReadOnly;
  final ValueChanged<bool> onToggleForecast;
  final VoidCallback onInstantNegotiate;

  const _RiderRenewalCard({
    required this.entry,
    required this.seasonYear,
    required this.isReadOnly,
    required this.onToggleForecast,
    required this.onInstantNegotiate,
  });

  @override
  State<_RiderRenewalCard> createState() => _RiderRenewalCardState();
}

class _RiderRenewalCardState extends State<_RiderRenewalCard> {
  bool _isHovered = false;

  static const TextStyle _interBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  static const TextStyle _tabularBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final rider = entry.rider;
    final isRenewed = entry.status == RenewalNegotiationState.renewed;
    final isDeclined = entry.status == RenewalNegotiationState.declined;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? entry.priorityTier.accentColor.withValues(alpha: 0.75)
                : AppTheme.borderColor,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: _interBase.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${rider.nationalityIso} • ${entry.ageAtSeason(widget.seasonYear)} lat • ${rider.specialization.displayName}',
                        overflow: TextOverflow.ellipsis,
                        style: _tabularBase.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: entry.status.badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: entry.status.badgeColor.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    entry.status.label,
                    style: _interBase.copyWith(
                      color: entry.status.badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniStatChip(
                  label: 'Potencjał',
                  value: '${rider.potential}',
                  color: AppColors.goldAccent,
                ),
                _MiniStatChip(
                  label: 'FTP',
                  value: '${rider.physiology.ftpWatts} W',
                  color: AppColors.accentBlue,
                ),
                _MiniStatChip(
                  label: 'UCI',
                  value: '${rider.careerPointsUci}',
                  color: AppColors.textPrimary,
                ),
                if (entry.hasRivalInterest && !isRenewed)
                  const _MiniStatChip(
                    label: 'Alert',
                    value: 'Oferta WT',
                    color: AppColors.crimsonAlert,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Obecna pensja / rok',
                          style: _interBase.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(
                            entry.currentAnnualSalaryEur,
                          ),
                          style: _tabularBase.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isRenewed
                              ? 'Nowy kontrakt (${entry.proposedYears} lata)'
                              : 'Prognoza (+${entry.marketDemandRaisePercent}%)',
                          style: _tabularBase.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(
                            entry.projectedAnnualSalaryEur,
                          ),
                          style: _tabularBase.copyWith(
                            color: isRenewed
                                ? AppColors.statusSuccess
                                : AppColors.goldAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, actionConstraints) {
                final isNarrowCard = actionConstraints.maxWidth < 340;
                final forecastToggle = (!isRenewed && !isDeclined)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: entry.includedInForecast,
                            activeThumbColor: AppColors.goldAccent,
                            activeTrackColor:
                                AppColors.goldAccent.withValues(alpha: 0.35),
                            onChanged: widget.isReadOnly
                                ? null
                                : widget.onToggleForecast,
                          ),
                          Flexible(
                            child: Text(
                              'W prognozie',
                              overflow: TextOverflow.ellipsis,
                              style: _interBase.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        isRenewed
                            ? 'Podpisano do ${widget.seasonYear + entry.proposedYears}'
                            : 'Agent odrzucił warunki',
                        overflow: TextOverflow.ellipsis,
                        style: _tabularBase.copyWith(
                          color: isRenewed
                              ? AppColors.statusSuccess
                              : AppColors.crimsonAlert,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );

                final negotiateBtn = _InstantNegotiationButton(
                  label: isRenewed
                      ? 'Przedłużono'
                      : isDeclined
                          ? 'Ponów rozmowy'
                          : 'Natychmiastowe negocjacje',
                  isEnabled: !widget.isReadOnly && !isRenewed,
                  isRenewed: isRenewed,
                  onPressed: widget.onInstantNegotiate,
                );

                if (isNarrowCard) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      forecastToggle,
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: negotiateBtn,
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: forecastToggle),
                    const SizedBox(width: 8),
                    negotiateBtn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InstantNegotiationButton extends StatefulWidget {
  final String label;
  final bool isEnabled;
  final bool isRenewed;
  final VoidCallback onPressed;

  const _InstantNegotiationButton({
    required this.label,
    required this.isEnabled,
    required this.isRenewed,
    required this.onPressed,
  });

  @override
  State<_InstantNegotiationButton> createState() =>
      _InstantNegotiationButtonState();
}

class _InstantNegotiationButtonState extends State<_InstantNegotiationButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.isEnabled
        ? (widget.isRenewed
            ? AppColors.statusSuccess.withValues(alpha: 0.16)
            : AppColors.surface)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.goldAccent.withValues(alpha: 0.22)
                : AppColors.primaryAccent;

    final borderColor = !widget.isEnabled
        ? (widget.isRenewed
            ? AppColors.statusSuccess.withValues(alpha: 0.5)
            : AppTheme.borderColor)
        : _focused || _hovered
            ? AppColors.goldAccent
            : AppColors.primaryAccent;

    final fgColor = !widget.isEnabled
        ? (widget.isRenewed
            ? AppColors.statusSuccess
            : AppColors.textSecondary)
        : AppColors.textPrimary;

    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown:
              widget.isEnabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp:
              widget.isEnabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              widget.isEnabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.isEnabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isRenewed
                      ? Icons.check_rounded
                      : Icons.handshake_rounded,
                  size: 15,
                  color: fgColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: fgColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class _InteractiveWarRoomIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _InteractiveWarRoomIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_InteractiveWarRoomIconButton> createState() =>
      _InteractiveWarRoomIconButtonState();
}

class _InteractiveWarRoomIconButtonState
    extends State<_InteractiveWarRoomIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? AppColors.goldAccent : AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _PriorityFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_PriorityFilterChip> createState() => _PriorityFilterChipState();
}

class _PriorityFilterChipState extends State<_PriorityFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.2)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected || _hovered
                  ? widget.accentColor
                  : AppTheme.borderColor,
              width: 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: widget.isSelected
                  ? widget.accentColor
                  : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderStatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ForecastMetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'Inter',
          letterSpacing: -0.2,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
