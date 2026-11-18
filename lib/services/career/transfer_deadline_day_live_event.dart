// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rider/rider_contract.dart';

/// Faza czasowa dnia zamknięcia okna transferowego (Transfer Deadline Day).
enum DeadlinePhase {
  openingHours,
  afternoonRush,
  goldenHour,
  finalMinutes,
  windowClosed;

  String toJson() => name;

  static DeadlinePhase fromJson(String value) {
    return DeadlinePhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeadlinePhase.openingHours,
    );
  }

  String get label {
    switch (this) {
      case DeadlinePhase.openingHours:
        return 'Otwarcie Dnia';
      case DeadlinePhase.afternoonRush:
        return 'Popołudniowa Gorączka';
      case DeadlinePhase.goldenHour:
        return 'Ostatnia Godzina';
      case DeadlinePhase.finalMinutes:
        return 'Finałowe Minuty!';
      case DeadlinePhase.windowClosed:
        return 'Okno Zamknięte';
    }
  }

  Color get accentColor {
    switch (this) {
      case DeadlinePhase.openingHours:
        return AppColors.accentBlue;
      case DeadlinePhase.afternoonRush:
        return AppColors.goldAccent;
      case DeadlinePhase.goldenHour:
        return AppColors.amberWarning;
      case DeadlinePhase.finalMinutes:
        return AppColors.crimsonAlert;
      case DeadlinePhase.windowClosed:
        return AppColors.textSecondary;
    }
  }
}

/// Rodzaj last-minute oferty nadesłanej przez agenta.
enum DeadlineOfferType {
  freeAgentBargain,
  lastMinutePoach,
  emergencyLoanOrRelease,
  biddingWarEscalation,
  mutualContractTermination;

  String toJson() => name;

  static DeadlineOfferType fromJson(String value) {
    return DeadlineOfferType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeadlineOfferType.freeAgentBargain,
    );
  }

  String get label {
    switch (this) {
      case DeadlineOfferType.freeAgentBargain:
        return 'Okazja Wolnego Agenta';
      case DeadlineOfferType.lastMinutePoach:
        return 'Przejęcie Last-Minute';
      case DeadlineOfferType.emergencyLoanOrRelease:
        return 'Klauzula Awaryjna';
      case DeadlineOfferType.biddingWarEscalation:
        return 'Wojna Ofertowa';
      case DeadlineOfferType.mutualContractTermination:
        return 'Rozwiązanie Kontraktu';
    }
  }

  Color get badgeColor {
    switch (this) {
      case DeadlineOfferType.freeAgentBargain:
        return AppColors.statusSuccess;
      case DeadlineOfferType.lastMinutePoach:
        return AppColors.goldAccent;
      case DeadlineOfferType.emergencyLoanOrRelease:
        return AppColors.accentBlue;
      case DeadlineOfferType.biddingWarEscalation:
        return AppColors.crimsonAlert;
      case DeadlineOfferType.mutualContractTermination:
        return AppColors.amberWarning;
    }
  }
}

/// Poziom pilności wygasającej oferty.
enum DeadlineOfferUrgency {
  standard,
  urgent,
  flashExpiring,
  critical;

  String toJson() => name;

  static DeadlineOfferUrgency fromJson(String value) {
    return DeadlineOfferUrgency.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeadlineOfferUrgency.standard,
    );
  }

  String get label {
    switch (this) {
      case DeadlineOfferUrgency.standard:
        return 'Standard';
      case DeadlineOfferUrgency.urgent:
        return 'Pilne';
      case DeadlineOfferUrgency.flashExpiring:
        return 'Wygasa Wkrótce';
      case DeadlineOfferUrgency.critical:
        return 'Krytyczne';
    }
  }

  Color get color {
    switch (this) {
      case DeadlineOfferUrgency.standard:
        return AppColors.accentBlue;
      case DeadlineOfferUrgency.urgent:
        return AppColors.goldAccent;
      case DeadlineOfferUrgency.flashExpiring:
        return AppColors.amberWarning;
      case DeadlineOfferUrgency.critical:
        return AppColors.crimsonAlert;
    }
  }
}

/// Status negocjacyjny oferty z ostatniej chwili.
enum DeadlineOfferStatus {
  pending,
  countered,
  accepted,
  rejected,
  expired,
  hijackedByRival;

  String toJson() => name;

  static DeadlineOfferStatus fromJson(String value) {
    return DeadlineOfferStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeadlineOfferStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case DeadlineOfferStatus.pending:
        return 'Oczekuje';
      case DeadlineOfferStatus.countered:
        return 'Kontroferta';
      case DeadlineOfferStatus.accepted:
        return 'Podpisano';
      case DeadlineOfferStatus.rejected:
        return 'Odrzucono';
      case DeadlineOfferStatus.expired:
        return 'Wygasła';
      case DeadlineOfferStatus.hijackedByRival:
        return 'Przejęty przez Rywala';
    }
  }

  Color get color {
    switch (this) {
      case DeadlineOfferStatus.pending:
        return AppColors.accentBlue;
      case DeadlineOfferStatus.countered:
        return AppColors.amberWarning;
      case DeadlineOfferStatus.accepted:
        return AppColors.statusSuccess;
      case DeadlineOfferStatus.rejected:
      case DeadlineOfferStatus.expired:
        return AppColors.textSecondary;
      case DeadlineOfferStatus.hijackedByRival:
        return AppColors.crimsonAlert;
    }
  }
}

/// Kategoria wpisu na pasku wiadomości na żywo (Live Ticker).
enum DeadlineTickerCategory {
  breakingDeal,
  agentLeak,
  rivalHijack,
  budgetAlert,
  medicalPassed,
  windowCountdown;

  String toJson() => name;

  static DeadlineTickerCategory fromJson(String value) {
    return DeadlineTickerCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeadlineTickerCategory.agentLeak,
    );
  }

  String get tag {
    switch (this) {
      case DeadlineTickerCategory.breakingDeal:
        return 'OFICJALNIE';
      case DeadlineTickerCategory.agentLeak:
        return 'PRZECIEK';
      case DeadlineTickerCategory.rivalHijack:
        return 'RYWAL';
      case DeadlineTickerCategory.budgetAlert:
        return 'BUDŻET';
      case DeadlineTickerCategory.medicalPassed:
        return 'BADANIA';
      case DeadlineTickerCategory.windowCountdown:
        return 'ZEGAR';
    }
  }

  Color get color {
    switch (this) {
      case DeadlineTickerCategory.breakingDeal:
        return AppColors.statusSuccess;
      case DeadlineTickerCategory.agentLeak:
        return AppColors.goldAccent;
      case DeadlineTickerCategory.rivalHijack:
        return AppColors.crimsonAlert;
      case DeadlineTickerCategory.budgetAlert:
        return AppColors.amberWarning;
      case DeadlineTickerCategory.medicalPassed:
        return AppColors.accentBlue;
      case DeadlineTickerCategory.windowCountdown:
        return AppColors.primaryAccent;
    }
  }
}

/// Specjalizacja kolarska zawodnika w ofercie deadline day.
enum DeadlineRiderSpecialty {
  gcClimber,
  sprinter,
  classicsPuncheur,
  timeTrialist,
  superDomestique,
  u23Wonderkid;

  String toJson() => name;

  static DeadlineRiderSpecialty fromJson(String value) {
    return DeadlineRiderSpecialty.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeadlineRiderSpecialty.superDomestique,
    );
  }

  String get label {
    switch (this) {
      case DeadlineRiderSpecialty.gcClimber:
        return 'Góral GC';
      case DeadlineRiderSpecialty.sprinter:
        return 'Sprinter';
      case DeadlineRiderSpecialty.classicsPuncheur:
        return 'Klasyki / Puncheur';
      case DeadlineRiderSpecialty.timeTrialist:
        return 'Czasowiec ITT';
      case DeadlineRiderSpecialty.superDomestique:
        return 'Super-Pomocnik';
      case DeadlineRiderSpecialty.u23Wonderkid:
        return 'Talent U23';
    }
  }
}

/// Profil agenta kolarskiego składającego ofertę w dniu zamknięcia okna.
class DeadlineAgentProfile {
  final String id;
  final String name;
  final String agencyName;
  final int reputation;
  final double aggressiveness;
  final double commissionPercent;

  const DeadlineAgentProfile({
    required this.id,
    required this.name,
    required this.agencyName,
    required this.reputation,
    required this.aggressiveness,
    required this.commissionPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'agencyName': agencyName,
      'reputation': reputation,
      'aggressiveness': aggressiveness,
      'commissionPercent': commissionPercent,
    };
  }

  factory DeadlineAgentProfile.fromJson(Map<String, dynamic> json) {
    return DeadlineAgentProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      agencyName: json['agencyName'] as String,
      reputation: (json['reputation'] as num).toInt(),
      aggressiveness: (json['aggressiveness'] as num).toDouble(),
      commissionPercent: (json['commissionPercent'] as num).toDouble(),
    );
  }
}

/// Last-minute oferta kontraktowa przedstawiona przez agenta na Transfer Deadline Day.
class LastMinuteAgentOffer {
  final String id;
  final String riderId;
  final String riderName;
  final String nationalityCode;
  final int age;
  final int overallRating;
  final DeadlineRiderSpecialty specialty;
  final String previousTeamName;
  final DeadlineAgentProfile agent;
  final DeadlineOfferType offerType;
  final RiderRole proposedRole;
  final int contractYears;
  final int annualSalaryEur;
  final int askingSalaryEur;
  final int marketValueEur;
  final int signingBonusEur;
  final int releaseBuyoutEur;
  final int uciPointsLastSeason;
  final int initialExpiryMinutes;
  final int remainingOfferMinutes;
  final DeadlineOfferUrgency urgency;
  final DeadlineOfferStatus status;
  final String agentPitch;
  final int competingClubsCount;
  final int rivalInterestScore;
  final bool isShortlisted;
  final int negotiationRounds;
  final int? lastCounterSalaryEur;
  final String? resolvedAtLabel;

  const LastMinuteAgentOffer({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.nationalityCode,
    required this.age,
    required this.overallRating,
    required this.specialty,
    required this.previousTeamName,
    required this.agent,
    required this.offerType,
    required this.proposedRole,
    required this.contractYears,
    required this.annualSalaryEur,
    required this.askingSalaryEur,
    required this.marketValueEur,
    required this.signingBonusEur,
    required this.releaseBuyoutEur,
    required this.uciPointsLastSeason,
    required this.initialExpiryMinutes,
    required this.remainingOfferMinutes,
    required this.urgency,
    required this.status,
    required this.agentPitch,
    required this.competingClubsCount,
    required this.rivalInterestScore,
    this.isShortlisted = false,
    this.negotiationRounds = 0,
    this.lastCounterSalaryEur,
    this.resolvedAtLabel,
  });

  bool get isActionable =>
      status == DeadlineOfferStatus.pending ||
      status == DeadlineOfferStatus.countered;

  bool get isExpiringSoon => isActionable && remainingOfferMinutes <= 30;

  int get totalFirstYearCostEur =>
      askingSalaryEur + signingBonusEur + releaseBuyoutEur;

  double get discountPercentage {
    if (marketValueEur <= 0) return 0.0;
    return ((marketValueEur - askingSalaryEur) / marketValueEur) * 100.0;
  }

  double get urgencyRatio {
    if (initialExpiryMinutes <= 0) return 0.0;
    return (remainingOfferMinutes / initialExpiryMinutes).clamp(0.0, 1.0);
  }

  LastMinuteAgentOffer copyWith({
    RiderRole? proposedRole,
    int? contractYears,
    int? annualSalaryEur,
    int? askingSalaryEur,
    int? signingBonusEur,
    int? remainingOfferMinutes,
    DeadlineOfferUrgency? urgency,
    DeadlineOfferStatus? status,
    String? agentPitch,
    int? competingClubsCount,
    int? rivalInterestScore,
    bool? isShortlisted,
    int? negotiationRounds,
    int? lastCounterSalaryEur,
    String? resolvedAtLabel,
  }) {
    return LastMinuteAgentOffer(
      id: id,
      riderId: riderId,
      riderName: riderName,
      nationalityCode: nationalityCode,
      age: age,
      overallRating: overallRating,
      specialty: specialty,
      previousTeamName: previousTeamName,
      agent: agent,
      offerType: offerType,
      proposedRole: proposedRole ?? this.proposedRole,
      contractYears: contractYears ?? this.contractYears,
      annualSalaryEur: annualSalaryEur ?? this.annualSalaryEur,
      askingSalaryEur: askingSalaryEur ?? this.askingSalaryEur,
      marketValueEur: marketValueEur,
      signingBonusEur: signingBonusEur ?? this.signingBonusEur,
      releaseBuyoutEur: releaseBuyoutEur,
      uciPointsLastSeason: uciPointsLastSeason,
      initialExpiryMinutes: initialExpiryMinutes,
      remainingOfferMinutes:
          remainingOfferMinutes ?? this.remainingOfferMinutes,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      agentPitch: agentPitch ?? this.agentPitch,
      competingClubsCount: competingClubsCount ?? this.competingClubsCount,
      rivalInterestScore: rivalInterestScore ?? this.rivalInterestScore,
      isShortlisted: isShortlisted ?? this.isShortlisted,
      negotiationRounds: negotiationRounds ?? this.negotiationRounds,
      lastCounterSalaryEur: lastCounterSalaryEur ?? this.lastCounterSalaryEur,
      resolvedAtLabel: resolvedAtLabel ?? this.resolvedAtLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'riderName': riderName,
      'nationalityCode': nationalityCode,
      'age': age,
      'overallRating': overallRating,
      'specialty': specialty.toJson(),
      'previousTeamName': previousTeamName,
      'agent': agent.toJson(),
      'offerType': offerType.toJson(),
      'proposedRole': proposedRole.toJson(),
      'contractYears': contractYears,
      'annualSalaryEur': annualSalaryEur,
      'askingSalaryEur': askingSalaryEur,
      'marketValueEur': marketValueEur,
      'signingBonusEur': signingBonusEur,
      'releaseBuyoutEur': releaseBuyoutEur,
      'uciPointsLastSeason': uciPointsLastSeason,
      'initialExpiryMinutes': initialExpiryMinutes,
      'remainingOfferMinutes': remainingOfferMinutes,
      'urgency': urgency.toJson(),
      'status': status.toJson(),
      'agentPitch': agentPitch,
      'competingClubsCount': competingClubsCount,
      'rivalInterestScore': rivalInterestScore,
      'isShortlisted': isShortlisted,
      'negotiationRounds': negotiationRounds,
      'lastCounterSalaryEur': lastCounterSalaryEur,
      'resolvedAtLabel': resolvedAtLabel,
    };
  }

  factory LastMinuteAgentOffer.fromJson(Map<String, dynamic> json) {
    return LastMinuteAgentOffer(
      id: json['id'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      nationalityCode: json['nationalityCode'] as String,
      age: (json['age'] as num).toInt(),
      overallRating: (json['overallRating'] as num).toInt(),
      specialty: DeadlineRiderSpecialty.fromJson(json['specialty'] as String),
      previousTeamName: json['previousTeamName'] as String,
      agent: DeadlineAgentProfile.fromJson(
        Map<String, dynamic>.from(json['agent'] as Map),
      ),
      offerType: DeadlineOfferType.fromJson(json['offerType'] as String),
      proposedRole: RiderRole.fromJson(json['proposedRole'] as String),
      contractYears: (json['contractYears'] as num).toInt(),
      annualSalaryEur: (json['annualSalaryEur'] as num).toInt(),
      askingSalaryEur: (json['askingSalaryEur'] as num).toInt(),
      marketValueEur: (json['marketValueEur'] as num).toInt(),
      signingBonusEur: (json['signingBonusEur'] as num).toInt(),
      releaseBuyoutEur: (json['releaseBuyoutEur'] as num).toInt(),
      uciPointsLastSeason: (json['uciPointsLastSeason'] as num).toInt(),
      initialExpiryMinutes: (json['initialExpiryMinutes'] as num).toInt(),
      remainingOfferMinutes: (json['remainingOfferMinutes'] as num).toInt(),
      urgency: DeadlineOfferUrgency.fromJson(json['urgency'] as String),
      status: DeadlineOfferStatus.fromJson(json['status'] as String),
      agentPitch: json['agentPitch'] as String,
      competingClubsCount: (json['competingClubsCount'] as num).toInt(),
      rivalInterestScore: (json['rivalInterestScore'] as num).toInt(),
      isShortlisted: json['isShortlisted'] as bool? ?? false,
      negotiationRounds: (json['negotiationRounds'] as num?)?.toInt() ?? 0,
      lastCounterSalaryEur: (json['lastCounterSalaryEur'] as num?)?.toInt(),
      resolvedAtLabel: json['resolvedAtLabel'] as String?,
    );
  }
}

/// Wiadomość na pasku informacji na żywo z dnia zamknięcia okna.
class DeadlineTickerItem {
  final String id;
  final String timestampLabel;
  final DeadlineTickerCategory category;
  final String headline;
  final String subtext;
  final bool isBreaking;

  const DeadlineTickerItem({
    required this.id,
    required this.timestampLabel,
    required this.category,
    required this.headline,
    required this.subtext,
    this.isBreaking = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestampLabel': timestampLabel,
      'category': category.toJson(),
      'headline': headline,
      'subtext': subtext,
      'isBreaking': isBreaking,
    };
  }

  factory DeadlineTickerItem.fromJson(Map<String, dynamic> json) {
    return DeadlineTickerItem(
      id: json['id'] as String,
      timestampLabel: json['timestampLabel'] as String,
      category: DeadlineTickerCategory.fromJson(json['category'] as String),
      headline: json['headline'] as String,
      subtext: json['subtext'] as String,
      isBreaking: json['isBreaking'] as bool? ?? false,
    );
  }
}

/// Sfinalizowany transfer podczas Transfer Deadline Day.
class CompletedDeadlineDeal {
  final String offerId;
  final String riderName;
  final RiderRole role;
  final int annualSalaryEur;
  final int signingBonusEur;
  final int releaseBuyoutEur;
  final int contractYears;
  final String completedAtLabel;
  final String dealTypeLabel;
  final String mediaReaction;
  final int savingsVsMarketEur;

  const CompletedDeadlineDeal({
    required this.offerId,
    required this.riderName,
    required this.role,
    required this.annualSalaryEur,
    required this.signingBonusEur,
    required this.releaseBuyoutEur,
    required this.contractYears,
    required this.completedAtLabel,
    required this.dealTypeLabel,
    required this.mediaReaction,
    required this.savingsVsMarketEur,
  });

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'riderName': riderName,
      'role': role.toJson(),
      'annualSalaryEur': annualSalaryEur,
      'signingBonusEur': signingBonusEur,
      'releaseBuyoutEur': releaseBuyoutEur,
      'contractYears': contractYears,
      'completedAtLabel': completedAtLabel,
      'dealTypeLabel': dealTypeLabel,
      'mediaReaction': mediaReaction,
      'savingsVsMarketEur': savingsVsMarketEur,
    };
  }

  factory CompletedDeadlineDeal.fromJson(Map<String, dynamic> json) {
    return CompletedDeadlineDeal(
      offerId: json['offerId'] as String,
      riderName: json['riderName'] as String,
      role: RiderRole.fromJson(json['role'] as String),
      annualSalaryEur: (json['annualSalaryEur'] as num).toInt(),
      signingBonusEur: (json['signingBonusEur'] as num).toInt(),
      releaseBuyoutEur: (json['releaseBuyoutEur'] as num).toInt(),
      contractYears: (json['contractYears'] as num).toInt(),
      completedAtLabel: json['completedAtLabel'] as String,
      dealTypeLabel: json['dealTypeLabel'] as String,
      mediaReaction: json['mediaReaction'] as String,
      savingsVsMarketEur: (json['savingsVsMarketEur'] as num).toInt(),
    );
  }
}

/// Konfiguracja startowa wydarzenia Transfer Deadline Day.
class TransferDeadlineDayConfig {
  final int seasonYear;
  final String windowName;
  final int totalDurationMinutes;
  final String teamName;
  final int availableTransferBudgetEur;
  final int availableWageBudgetEur;
  final int openRosterSlots;
  final int teamPrestigeScore;

  const TransferDeadlineDayConfig({
    this.seasonYear = 2026,
    this.windowName = 'UCI Transfer Deadline Day — 31 Grudnia',
    this.totalDurationMinutes = 720,
    this.teamName = 'Veloce Pro Cycling',
    this.availableTransferBudgetEur = 950000,
    this.availableWageBudgetEur = 1650000,
    this.openRosterSlots = 3,
    this.teamPrestigeScore = 82,
  });

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'windowName': windowName,
      'totalDurationMinutes': totalDurationMinutes,
      'teamName': teamName,
      'availableTransferBudgetEur': availableTransferBudgetEur,
      'availableWageBudgetEur': availableWageBudgetEur,
      'openRosterSlots': openRosterSlots,
      'teamPrestigeScore': teamPrestigeScore,
    };
  }

  factory TransferDeadlineDayConfig.fromJson(Map<String, dynamic> json) {
    return TransferDeadlineDayConfig(
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      windowName: json['windowName'] as String? ??
          'UCI Transfer Deadline Day — 31 Grudnia',
      totalDurationMinutes:
          (json['totalDurationMinutes'] as num?)?.toInt() ?? 720,
      teamName: json['teamName'] as String? ?? 'Veloce Pro Cycling',
      availableTransferBudgetEur:
          (json['availableTransferBudgetEur'] as num?)?.toInt() ?? 950000,
      availableWageBudgetEur:
          (json['availableWageBudgetEur'] as num?)?.toInt() ?? 1650000,
      openRosterSlots: (json['openRosterSlots'] as num?)?.toInt() ?? 3,
      teamPrestigeScore: (json['teamPrestigeScore'] as num?)?.toInt() ?? 82,
    );
  }
}

/// Raport podsumowujący wyniki drużyny po zamknięciu okna transferowego.
class DeadlineDaySummaryReport {
  final int totalDealsSigned;
  final int totalSpentWagesEur;
  final int totalSpentBonusesEur;
  final int totalMarketSavingsEur;
  final int rejectedOrExpiredCount;
  final int hijackedCount;
  final String windowGrade;
  final String mediaVerdict;

  const DeadlineDaySummaryReport({
    required this.totalDealsSigned,
    required this.totalSpentWagesEur,
    required this.totalSpentBonusesEur,
    required this.totalMarketSavingsEur,
    required this.rejectedOrExpiredCount,
    required this.hijackedCount,
    required this.windowGrade,
    required this.mediaVerdict,
  });
}

/// Kompletny stan wydarzenia na żywo Transfer Deadline Day.
class TransferDeadlineDayState {
  final TransferDeadlineDayConfig config;
  final int remainingWindowMinutes;
  final bool isLiveTicking;
  final int simulationSpeedMultiplier;
  final int remainingWageBudgetEur;
  final int remainingTransferBudgetEur;
  final int remainingRosterSlots;
  final List<LastMinuteAgentOffer> offers;
  final List<CompletedDeadlineDeal> completedDeals;
  final List<DeadlineTickerItem> tickerFeed;
  final String? selectedOfferId;
  final DeadlineOfferType? filterType;
  final bool onlyShortlisted;
  final String searchQuery;
  final String? lastActionFeedback;
  final int waveCounter;

  const TransferDeadlineDayState({
    required this.config,
    required this.remainingWindowMinutes,
    required this.isLiveTicking,
    required this.simulationSpeedMultiplier,
    required this.remainingWageBudgetEur,
    required this.remainingTransferBudgetEur,
    required this.remainingRosterSlots,
    required this.offers,
    required this.completedDeals,
    required this.tickerFeed,
    this.selectedOfferId,
    this.filterType,
    this.onlyShortlisted = false,
    this.searchQuery = '',
    this.lastActionFeedback,
    this.waveCounter = 0,
  });

  bool get isWindowClosed => remainingWindowMinutes <= 0;

  DeadlinePhase get currentPhase {
    if (remainingWindowMinutes <= 0) return DeadlinePhase.windowClosed;
    if (remainingWindowMinutes <= 20) return DeadlinePhase.finalMinutes;
    if (remainingWindowMinutes <= 60) return DeadlinePhase.goldenHour;
    if (remainingWindowMinutes <= config.totalDurationMinutes * 0.55) {
      return DeadlinePhase.afternoonRush;
    }
    return DeadlinePhase.openingHours;
  }

  String get formattedCountdown {
    final int clamped = math.max(0, remainingWindowMinutes);
    final int hours = clamped ~/ 60;
    final int mins = clamped % 60;
    return '${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m';
  }

  String get currentClockLabel {
    final int clamped =
        remainingWindowMinutes.clamp(0, config.totalDurationMinutes);
    final int elapsed = config.totalDurationMinutes - clamped;
    final int startTotalMinutes = (24 * 60) - config.totalDurationMinutes;
    final int currentTotal = (startTotalMinutes + elapsed).clamp(0, 24 * 60);
    final int hour = (currentTotal ~/ 60) % 24;
    final int minute = currentTotal % 60;
    if (clamped == 0) return '00:00';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  List<LastMinuteAgentOffer> get filteredOffers {
    final query = searchQuery.trim().toLowerCase();
    return offers.where((offer) {
      if (filterType != null && offer.offerType != filterType) {
        return false;
      }
      if (onlyShortlisted && !offer.isShortlisted) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchName = offer.riderName.toLowerCase().contains(query);
        final matchAgent = offer.agent.name.toLowerCase().contains(query);
        final matchTeam = offer.previousTeamName.toLowerCase().contains(query);
        final matchSpec = offer.specialty.label.toLowerCase().contains(query);
        if (!matchName && !matchAgent && !matchTeam && !matchSpec) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  LastMinuteAgentOffer? get selectedOffer {
    if (selectedOfferId == null) return null;
    for (final offer in offers) {
      if (offer.id == selectedOfferId) return offer;
    }
    return null;
  }

  int get activeOffersCount => offers.where((o) => o.isActionable).length;

  int get expiringSoonCount => offers.where((o) => o.isExpiringSoon).length;

  TransferDeadlineDayState copyWith({
    int? remainingWindowMinutes,
    bool? isLiveTicking,
    int? simulationSpeedMultiplier,
    int? remainingWageBudgetEur,
    int? remainingTransferBudgetEur,
    int? remainingRosterSlots,
    List<LastMinuteAgentOffer>? offers,
    List<CompletedDeadlineDeal>? completedDeals,
    List<DeadlineTickerItem>? tickerFeed,
    String? selectedOfferId,
    bool clearSelectedOffer = false,
    DeadlineOfferType? filterType,
    bool clearFilterType = false,
    bool? onlyShortlisted,
    String? searchQuery,
    String? lastActionFeedback,
    bool clearFeedback = false,
    int? waveCounter,
  }) {
    return TransferDeadlineDayState(
      config: config,
      remainingWindowMinutes:
          remainingWindowMinutes ?? this.remainingWindowMinutes,
      isLiveTicking: isLiveTicking ?? this.isLiveTicking,
      simulationSpeedMultiplier:
          simulationSpeedMultiplier ?? this.simulationSpeedMultiplier,
      remainingWageBudgetEur:
          remainingWageBudgetEur ?? this.remainingWageBudgetEur,
      remainingTransferBudgetEur:
          remainingTransferBudgetEur ?? this.remainingTransferBudgetEur,
      remainingRosterSlots: remainingRosterSlots ?? this.remainingRosterSlots,
      offers: offers ?? this.offers,
      completedDeals: completedDeals ?? this.completedDeals,
      tickerFeed: tickerFeed ?? this.tickerFeed,
      selectedOfferId:
          clearSelectedOffer ? null : (selectedOfferId ?? this.selectedOfferId),
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      onlyShortlisted: onlyShortlisted ?? this.onlyShortlisted,
      searchQuery: searchQuery ?? this.searchQuery,
      lastActionFeedback: clearFeedback
          ? null
          : (lastActionFeedback ?? this.lastActionFeedback),
      waveCounter: waveCounter ?? this.waveCounter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'config': config.toJson(),
      'remainingWindowMinutes': remainingWindowMinutes,
      'isLiveTicking': isLiveTicking,
      'simulationSpeedMultiplier': simulationSpeedMultiplier,
      'remainingWageBudgetEur': remainingWageBudgetEur,
      'remainingTransferBudgetEur': remainingTransferBudgetEur,
      'remainingRosterSlots': remainingRosterSlots,
      'offers': offers.map((e) => e.toJson()).toList(),
      'completedDeals': completedDeals.map((e) => e.toJson()).toList(),
      'tickerFeed': tickerFeed.map((e) => e.toJson()).toList(),
      'selectedOfferId': selectedOfferId,
      'filterType': filterType?.toJson(),
      'onlyShortlisted': onlyShortlisted,
      'searchQuery': searchQuery,
      'lastActionFeedback': lastActionFeedback,
      'waveCounter': waveCounter,
    };
  }

  factory TransferDeadlineDayState.fromJson(Map<String, dynamic> json) {
    return TransferDeadlineDayState(
      config: TransferDeadlineDayConfig.fromJson(
        Map<String, dynamic>.from(json['config'] as Map),
      ),
      remainingWindowMinutes: (json['remainingWindowMinutes'] as num).toInt(),
      isLiveTicking: json['isLiveTicking'] as bool? ?? false,
      simulationSpeedMultiplier:
          (json['simulationSpeedMultiplier'] as num?)?.toInt() ?? 1,
      remainingWageBudgetEur: (json['remainingWageBudgetEur'] as num).toInt(),
      remainingTransferBudgetEur:
          (json['remainingTransferBudgetEur'] as num).toInt(),
      remainingRosterSlots: (json['remainingRosterSlots'] as num).toInt(),
      offers: (json['offers'] as List<dynamic>)
          .map(
            (e) => LastMinuteAgentOffer.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      completedDeals: (json['completedDeals'] as List<dynamic>)
          .map(
            (e) => CompletedDeadlineDeal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      tickerFeed: (json['tickerFeed'] as List<dynamic>)
          .map(
            (e) => DeadlineTickerItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      selectedOfferId: json['selectedOfferId'] as String?,
      filterType: json['filterType'] != null
          ? DeadlineOfferType.fromJson(json['filterType'] as String)
          : null,
      onlyShortlisted: json['onlyShortlisted'] as bool? ?? false,
      searchQuery: json['searchQuery'] as String? ?? '',
      lastActionFeedback: json['lastActionFeedback'] as String?,
      waveCounter: (json['waveCounter'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Silnik biznesowy wydarzenia Transfer Deadline Day z odliczaniem godzinowym
/// oraz dynamicznymi ofertami last-minute składanymi przez agentów kolarskich.
class TransferDeadlineDayLiveEventService {
  const TransferDeadlineDayLiveEventService();

  static const List<DeadlineAgentProfile> _agentsPool = [
    DeadlineAgentProfile(
      id: 'ag_vermeulen',
      name: 'Karel Vermeulen',
      agencyName: 'Flanders Pro Management',
      reputation: 91,
      aggressiveness: 0.72,
      commissionPercent: 8.5,
    ),
    DeadlineAgentProfile(
      id: 'ag_rossi',
      name: 'Elena Rossi',
      agencyName: 'Milano Corsa Agency',
      reputation: 88,
      aggressiveness: 0.55,
      commissionPercent: 7.0,
    ),
    DeadlineAgentProfile(
      id: 'ag_moreau',
      name: 'Jean-Luc Moreau',
      agencyName: 'Hexagone Peloton',
      reputation: 79,
      aggressiveness: 0.42,
      commissionPercent: 6.5,
    ),
    DeadlineAgentProfile(
      id: 'ag_kowalski',
      name: 'Marek Kowalski',
      agencyName: 'Central Euro Sports',
      reputation: 84,
      aggressiveness: 0.61,
      commissionPercent: 7.5,
    ),
  ];

  /// Tworzy początkowy stan wydarzenia Transfer Deadline Day.
  TransferDeadlineDayState createInitialState({
    TransferDeadlineDayConfig config = const TransferDeadlineDayConfig(),
    int seed = 2026,
  }) {
    final rng = math.Random(seed);
    final initialOffers = _buildInitialOffers(rng, config);
    final initialTicker = <DeadlineTickerItem>[
      DeadlineTickerItem(
        id: 'tk_open_1',
        timestampLabel: '12:00',
        category: DeadlineTickerCategory.windowCountdown,
        headline: 'Otwarto ostatnie 12 godzin okna UCI!',
        subtext:
            'Agenci zasypują skrzynki dyrektorów sportowych ofertami last-minute dla ${config.teamName}.',
        isBreaking: true,
      ),
      const DeadlineTickerItem(
        id: 'tk_open_2',
        timestampLabel: '12:04',
        category: DeadlineTickerCategory.agentLeak,
        headline:
            'Gorące telefony od Karel Vermeulen & Milano Corsa Agency',
        subtext:
            'Kilku kolarzy z kończącymi się umowami szuka miejsca w składzie przed północą.',
      ),
    ];

    return TransferDeadlineDayState(
      config: config,
      remainingWindowMinutes: config.totalDurationMinutes,
      isLiveTicking: false,
      simulationSpeedMultiplier: 1,
      remainingWageBudgetEur: config.availableWageBudgetEur,
      remainingTransferBudgetEur: config.availableTransferBudgetEur,
      remainingRosterSlots: config.openRosterSlots,
      offers: initialOffers,
      completedDeals: const [],
      tickerFeed: initialTicker,
      selectedOfferId: initialOffers.isNotEmpty ? initialOffers.first.id : null,
      waveCounter: 1,
    );
  }

  /// Przesuwa zegar okna transferowego o zadaną liczbę minut, aktualizuje czasy wygaśnięcia,
  /// symuluje ruchy rywali i generuje nowe fale ofert last-minute.
  TransferDeadlineDayState advanceTime(
    TransferDeadlineDayState state, {
    int minutes = 15,
    int? seed,
  }) {
    if (state.isWindowClosed || minutes <= 0) {
      return state;
    }

    final rng = math.Random(
      seed ?? (state.remainingWindowMinutes * 31 + state.waveCounter * 17),
    );
    final int nextRemaining = math.max(0, state.remainingWindowMinutes - minutes);
    final String clockLabel = state
        .copyWith(remainingWindowMinutes: nextRemaining)
        .currentClockLabel;

    final List<DeadlineTickerItem> newTicker = List.of(state.tickerFeed);
    final List<LastMinuteAgentOffer> updatedOffers = [];

    for (final offer in state.offers) {
      if (!offer.isActionable) {
        updatedOffers.add(offer);
        continue;
      }

      if (nextRemaining == 0) {
        updatedOffers.add(
          offer.copyWith(
            remainingOfferMinutes: 0,
            status: DeadlineOfferStatus.expired,
            resolvedAtLabel: '00:00',
          ),
        );
        continue;
      }

      final int nextOfferMin = math.max(0, offer.remainingOfferMinutes - minutes);
      if (nextOfferMin == 0) {
        updatedOffers.add(
          offer.copyWith(
            remainingOfferMinutes: 0,
            status: DeadlineOfferStatus.expired,
            resolvedAtLabel: clockLabel,
          ),
        );
        newTicker.insert(
          0,
          DeadlineTickerItem(
            id: 'tk_exp_${offer.id}_$nextRemaining',
            timestampLabel: clockLabel,
            category: DeadlineTickerCategory.agentLeak,
            headline: 'Wygasła oferta: ${offer.riderName}',
            subtext:
                'Agent ${offer.agent.name} wycofał propozycję z powodu braku decyzji.',
          ),
        );
        continue;
      }

      // Szansa na podkupienie przez rywala przy wysokim zainteresowaniu
      final double hijackRoll = rng.nextDouble();
      final double hijackThreshold =
          (offer.competingClubsCount * 0.035) +
              (offer.rivalInterestScore / 1000.0);
      if (offer.competingClubsCount >= 2 &&
          nextOfferMin <= 45 &&
          hijackRoll < hijackThreshold) {
        updatedOffers.add(
          offer.copyWith(
            remainingOfferMinutes: 0,
            status: DeadlineOfferStatus.hijackedByRival,
            resolvedAtLabel: clockLabel,
          ),
        );
        newTicker.insert(
          0,
          DeadlineTickerItem(
            id: 'tk_hijack_${offer.id}_$nextRemaining',
            timestampLabel: clockLabel,
            category: DeadlineTickerCategory.rivalHijack,
            headline: 'RYWAL PRZEJĄŁ CEL: ${offer.riderName}!',
            subtext:
                'Konkurencyjna ekipa WorldTour zamknęła kontrakt przed naszym nosem.',
            isBreaking: true,
          ),
        );
        continue;
      }

      // W ostatnich 90 minutach agenci czasem obniżają stawkę z desperacji
      int adjustedAsking = offer.askingSalaryEur;
      String updatedPitch = offer.agentPitch;
      if (nextRemaining <= 90 &&
          offer.offerType == DeadlineOfferType.freeAgentBargain &&
          offer.negotiationRounds == 0 &&
          rng.nextDouble() < 0.35) {
        adjustedAsking = (offer.askingSalaryEur * 0.92).round();
        updatedPitch =
            'Czas ucieka! Mój klient zgadza się zejść z oczekiwań o 8%, jeśli podpiszemy teraz.';
      }

      final DeadlineOfferUrgency nextUrgency = _computeUrgency(nextOfferMin);
      updatedOffers.add(
        offer.copyWith(
          remainingOfferMinutes: nextOfferMin,
          askingSalaryEur: adjustedAsking,
          agentPitch: updatedPitch,
          urgency: nextUrgency,
        ),
      );
    }

    // Powiadomienia fazowe zegara
    final previousPhase = state.currentPhase;
    final nextPhase = state
        .copyWith(remainingWindowMinutes: nextRemaining)
        .currentPhase;
    if (previousPhase != nextPhase) {
      newTicker.insert(
        0,
        DeadlineTickerItem(
          id: 'tk_phase_${nextPhase.name}_$nextRemaining',
          timestampLabel: clockLabel,
          category: DeadlineTickerCategory.windowCountdown,
          headline: nextRemaining == 0
              ? 'ZAMKNIĘCIE OKNA TRANSFEROWEGO UCI!'
              : 'Nowa faza: ${nextPhase.label}',
          subtext: nextRemaining == 0
              ? 'System rejestracji kontraktów UCI został zablokowany o północy.'
              : 'Pozostało ${_formatMinutesCompact(nextRemaining)} do zamknięcia okna.',
          isBreaking: true,
        ),
      );
    }

    // Generowanie nowej fali last-minute ofert w trakcie dnia
    int nextWave = state.waveCounter;
    final int activeCount = updatedOffers.where((o) => o.isActionable).length;
    if (nextRemaining > 10 &&
        (activeCount < 4 || (nextRemaining % 120 < minutes))) {
      final newOffer = _generateDynamicLastMinuteOffer(
        rng: rng,
        waveIndex: nextWave + 1,
        remainingWindowMinutes: nextRemaining,
      );
      updatedOffers.insert(0, newOffer);
      nextWave += 1;
      newTicker.insert(
        0,
        DeadlineTickerItem(
          id: 'tk_new_${newOffer.id}',
          timestampLabel: clockLabel,
          category: DeadlineTickerCategory.agentLeak,
          headline: 'Nowa oferta last-minute: ${newOffer.riderName}',
          subtext:
              '${newOffer.agent.name} (${newOffer.agent.agencyName}) proponuje ${newOffer.specialty.label} (OVR ${newOffer.overallRating}).',
          isBreaking: newOffer.urgency == DeadlineOfferUrgency.critical,
        ),
      );
    }

    return state.copyWith(
      remainingWindowMinutes: nextRemaining,
      isLiveTicking: nextRemaining == 0 ? false : state.isLiveTicking,
      offers: updatedOffers,
      tickerFeed: newTicker.take(30).toList(),
      waveCounter: nextWave,
    );
  }

  /// Natychmiastowa akceptacja warunków agenta i rejestracja kontraktu przed północą.
  TransferDeadlineDayState acceptOffer(
    TransferDeadlineDayState state,
    String offerId,
  ) {
    if (state.isWindowClosed) {
      return state.copyWith(
        lastActionFeedback:
            'Okno transferowe jest już zamknięte — nie można rejestrować kontraktów.',
      );
    }

    final index = state.offers.indexWhere((o) => o.id == offerId);
    if (index == -1) return state;

    final offer = state.offers[index];
    if (!offer.isActionable) {
      return state.copyWith(
        lastActionFeedback:
            'Oferta dla ${offer.riderName} nie jest już aktywna (${offer.status.label}).',
      );
    }

    if (state.remainingRosterSlots <= 0) {
      return state.copyWith(
        lastActionFeedback:
            'Brak wolnych miejsc w składzie UCI. Zwolnij etat lub odrzuć ofertę.',
      );
    }

    final int requiredTransferFunds =
        offer.signingBonusEur + offer.releaseBuyoutEur;
    if (offer.askingSalaryEur > state.remainingWageBudgetEur) {
      return state.copyWith(
        lastActionFeedback:
            'Niewystarczający budżet płacowy na pensję ${_formatEur(offer.askingSalaryEur)}.',
      );
    }
    if (requiredTransferFunds > state.remainingTransferBudgetEur) {
      return state.copyWith(
        lastActionFeedback:
            'Brak środków transferowych na bonus i wykup (${_formatEur(requiredTransferFunds)}).',
      );
    }

    final String clockLabel = state.currentClockLabel;
    final updatedOffer = offer.copyWith(
      status: DeadlineOfferStatus.accepted,
      annualSalaryEur: offer.askingSalaryEur,
      resolvedAtLabel: clockLabel,
    );

    final updatedOffers = List<LastMinuteAgentOffer>.of(state.offers);
    updatedOffers[index] = updatedOffer;

    final int savings = offer.marketValueEur - offer.askingSalaryEur;
    final deal = CompletedDeadlineDeal(
      offerId: offer.id,
      riderName: offer.riderName,
      role: offer.proposedRole,
      annualSalaryEur: offer.askingSalaryEur,
      signingBonusEur: offer.signingBonusEur,
      releaseBuyoutEur: offer.releaseBuyoutEur,
      contractYears: offer.contractYears,
      completedAtLabel: clockLabel,
      dealTypeLabel: offer.offerType.label,
      mediaReaction: savings >= 50000
          ? 'Majstersztyk negocjacyjny! Podpisano poniżej wartości rynkowej.'
          : 'Solidne wzmocnienie składu rzutem na taśmę.',
      savingsVsMarketEur: savings,
    );

    final newTicker = <DeadlineTickerItem>[
      DeadlineTickerItem(
        id: 'tk_deal_${offer.id}_$clockLabel',
        timestampLabel: clockLabel,
        category: DeadlineTickerCategory.breakingDeal,
        headline:
            'DONE DEAL! ${offer.riderName} w ${state.config.teamName}!',
        subtext:
            'Kontrakt na ${offer.contractYears} lata (${_formatEur(offer.askingSalaryEur)}/rok, rola: ${offer.proposedRole.label}).',
        isBreaking: true,
      ),
      ...state.tickerFeed,
    ];

    return state.copyWith(
      remainingWageBudgetEur:
          state.remainingWageBudgetEur - offer.askingSalaryEur,
      remainingTransferBudgetEur:
          state.remainingTransferBudgetEur - requiredTransferFunds,
      remainingRosterSlots: state.remainingRosterSlots - 1,
      offers: updatedOffers,
      completedDeals: [deal, ...state.completedDeals],
      tickerFeed: newTicker.take(30).toList(),
      lastActionFeedback:
          'Zarejestrowano kontrakt ${offer.riderName} w systemie UCI o $clockLabel!',
    );
  }

  /// Złożenie kontroferty agentowi w trakcie trwania Deadline Day.
  TransferDeadlineDayState submitCounterOffer(
    TransferDeadlineDayState state, {
    required String offerId,
    required int counterSalaryEur,
    required int counterYears,
    required RiderRole counterRole,
    int? seed,
  }) {
    if (state.isWindowClosed) {
      return state.copyWith(
        lastActionFeedback:
            'Okno zamknięte — negocjacje zostały przerwane o północy.',
      );
    }

    final index = state.offers.indexWhere((o) => o.id == offerId);
    if (index == -1) return state;

    final offer = state.offers[index];
    if (!offer.isActionable) return state;

    if (counterSalaryEur > state.remainingWageBudgetEur) {
      return state.copyWith(
        lastActionFeedback:
            'Twoja kontroferta przekracza dostępny budżet płacowy.',
      );
    }

    final int clampedYears = counterYears.clamp(1, 4);
    final double salaryRatio = counterSalaryEur / math.max(1, offer.askingSalaryEur);
    final String clockLabel = state.currentClockLabel;
    final rng = math.Random(
      seed ?? (offer.id.hashCode ^ counterSalaryEur ^ state.remainingWindowMinutes),
    );

    // Im bliżej północy, tym większa presja na agenta
    final double deadlineDesperationBonus =
        state.remainingWindowMinutes <= 60 ? 0.08 : 0.0;
    final double prestigeBonus =
        (state.config.teamPrestigeScore - 75) * 0.0025;
    final double effectiveRatio =
        salaryRatio + deadlineDesperationBonus + prestigeBonus;

    final updatedOffers = List<LastMinuteAgentOffer>.of(state.offers);
    final newTicker = List<DeadlineTickerItem>.of(state.tickerFeed);

    // Zbyt niska oferta -> agent zrywa rozmowy
    if (salaryRatio < 0.65 || (offer.negotiationRounds >= 3 && effectiveRatio < 0.88)) {
      updatedOffers[index] = offer.copyWith(
        status: DeadlineOfferStatus.rejected,
        lastCounterSalaryEur: counterSalaryEur,
        negotiationRounds: offer.negotiationRounds + 1,
        agentPitch:
            'To obraźliwa propozycja jak na ostatnie godziny okna. Zamykamy temat.',
        resolvedAtLabel: clockLabel,
      );
      newTicker.insert(
        0,
        DeadlineTickerItem(
          id: 'tk_walk_${offer.id}_$clockLabel',
          timestampLabel: clockLabel,
          category: DeadlineTickerCategory.agentLeak,
          headline: 'Fiasko rozmów ws. ${offer.riderName}',
          subtext:
              'Agent ${offer.agent.name} odrzucił kontrofertę ${_formatEur(counterSalaryEur)}.',
        ),
      );
      return state.copyWith(
        offers: updatedOffers,
        tickerFeed: newTicker.take(30).toList(),
        lastActionFeedback:
            '${offer.agent.name} zerwał negocjacje w sprawie ${offer.riderName}.',
      );
    }

    // Akceptacja kontroferty
    if (effectiveRatio >= 0.94 ||
        (effectiveRatio >= 0.87 && rng.nextDouble() < 0.45)) {
      final int requiredTransferFunds =
          offer.signingBonusEur + offer.releaseBuyoutEur;
      if (state.remainingRosterSlots <= 0 ||
          requiredTransferFunds > state.remainingTransferBudgetEur) {
        return state.copyWith(
          lastActionFeedback:
              'Agent zgodził się na warunki, ale brakuje miejsc lub budżetu na wykup.',
        );
      }

      updatedOffers[index] = offer.copyWith(
        status: DeadlineOfferStatus.accepted,
        proposedRole: counterRole,
        contractYears: clampedYears,
        annualSalaryEur: counterSalaryEur,
        askingSalaryEur: counterSalaryEur,
        lastCounterSalaryEur: counterSalaryEur,
        negotiationRounds: offer.negotiationRounds + 1,
        agentPitch: 'Zgoda! Wysyłamy skany dokumentów do komisarzy UCI.',
        resolvedAtLabel: clockLabel,
      );

      final int savings = offer.marketValueEur - counterSalaryEur;
      final deal = CompletedDeadlineDeal(
        offerId: offer.id,
        riderName: offer.riderName,
        role: counterRole,
        annualSalaryEur: counterSalaryEur,
        signingBonusEur: offer.signingBonusEur,
        releaseBuyoutEur: offer.releaseBuyoutEur,
        contractYears: clampedYears,
        completedAtLabel: clockLabel,
        dealTypeLabel: '${offer.offerType.label} (Po negocjacjach)',
        mediaReaction: savings >= 40000
            ? 'Świetnie zbita cena w ostatniej chwili!'
            : 'Udany kompromis przed zamknięciem okna.',
        savingsVsMarketEur: savings,
      );

      newTicker.insert(
        0,
        DeadlineTickerItem(
          id: 'tk_cnt_acc_${offer.id}_$clockLabel',
          timestampLabel: clockLabel,
          category: DeadlineTickerCategory.breakingDeal,
          headline: 'KOMPROMIS! ${offer.riderName} podpisuje!',
          subtext:
              'Negocjacje zakończone sukcesem przy ${_formatEur(counterSalaryEur)}/rok.',
          isBreaking: true,
        ),
      );

      return state.copyWith(
        remainingWageBudgetEur:
            state.remainingWageBudgetEur - counterSalaryEur,
        remainingTransferBudgetEur:
            state.remainingTransferBudgetEur - requiredTransferFunds,
        remainingRosterSlots: state.remainingRosterSlots - 1,
        offers: updatedOffers,
        completedDeals: [deal, ...state.completedDeals],
        tickerFeed: newTicker.take(30).toList(),
        lastActionFeedback:
            'Kontroferta przyjęta! ${offer.riderName} dołącza do ${state.config.teamName}.',
      );
    }

    // Kontroferta agenta — spotkanie w połowie drogi
    final int midpoint = ((offer.askingSalaryEur + counterSalaryEur) / 2).round();
    final int nextAsking = math.max(counterSalaryEur + 10000, midpoint);
    updatedOffers[index] = offer.copyWith(
      status: DeadlineOfferStatus.countered,
      askingSalaryEur: nextAsking,
      proposedRole: counterRole,
      contractYears: clampedYears,
      lastCounterSalaryEur: counterSalaryEur,
      negotiationRounds: offer.negotiationRounds + 1,
      agentPitch:
          'Możemy zejść do ${_formatEur(nextAsking)}/rok przy roli ${counterRole.label}. Zegar tyka!',
    );

    return state.copyWith(
      offers: updatedOffers,
      lastActionFeedback:
          '${offer.agent.name} obniżył żądania dla ${offer.riderName} do ${_formatEur(nextAsking)}.',
    );
  }

  /// Odrzucenie oferty agenta.
  TransferDeadlineDayState rejectOffer(
    TransferDeadlineDayState state,
    String offerId,
  ) {
    final index = state.offers.indexWhere((o) => o.id == offerId);
    if (index == -1) return state;
    final offer = state.offers[index];
    if (!offer.isActionable) return state;

    final updatedOffers = List<LastMinuteAgentOffer>.of(state.offers);
    updatedOffers[index] = offer.copyWith(
      status: DeadlineOfferStatus.rejected,
      resolvedAtLabel: state.currentClockLabel,
    );

    return state.copyWith(
      offers: updatedOffers,
      lastActionFeedback: 'Odrzucono ofertę dla ${offer.riderName}.',
    );
  }

  /// Przypina lub odpina ofertę na liście obserwowanej.
  TransferDeadlineDayState toggleShortlist(
    TransferDeadlineDayState state,
    String offerId,
  ) {
    final index = state.offers.indexWhere((o) => o.id == offerId);
    if (index == -1) return state;

    final updatedOffers = List<LastMinuteAgentOffer>.of(state.offers);
    final current = updatedOffers[index];
    updatedOffers[index] = current.copyWith(
      isShortlisted: !current.isShortlisted,
    );
    return state.copyWith(offers: updatedOffers);
  }

  /// Generuje raport końcowy po zamknięciu okna transferowego.
  DeadlineDaySummaryReport buildSummaryReport(TransferDeadlineDayState state) {
    final deals = state.completedDeals;
    final int totalWages =
        deals.fold(0, (sum, d) => sum + d.annualSalaryEur);
    final int totalBonuses = deals.fold(
      0,
      (sum, d) => sum + d.signingBonusEur + d.releaseBuyoutEur,
    );
    final int totalSavings =
        deals.fold(0, (sum, d) => sum + d.savingsVsMarketEur);
    final int rejectedOrExpired = state.offers
        .where(
          (o) =>
              o.status == DeadlineOfferStatus.rejected ||
              o.status == DeadlineOfferStatus.expired,
        )
        .length;
    final int hijacked = state.offers
        .where((o) => o.status == DeadlineOfferStatus.hijackedByRival)
        .length;

    String grade = 'C';
    String verdict = 'Spokojne zamknięcie okna bez większych fajerwerków.';
    if (deals.isNotEmpty && totalSavings >= 100000 && hijacked == 0) {
      grade = 'S';
      verdict =
          'Fenomenalne Deadline Day! Zespół wzmocniony znacznie poniżej wartości rynkowej.';
    } else if (deals.length >= 2 || (deals.isNotEmpty && totalSavings > 0)) {
      grade = 'A';
      verdict =
          'Bardzo skuteczne manewry w ostatnich godzinach okna transferowego.';
    } else if (deals.isNotEmpty) {
      grade = 'B';
      verdict = 'Udało się dopiąć potrzebne wzmocnienie przed północą.';
    } else if (hijacked >= 2) {
      grade = 'D';
      verdict =
          'Rywale sprzątnęli kluczowe cele sprzed nosa zarządu.';
    }

    return DeadlineDaySummaryReport(
      totalDealsSigned: deals.length,
      totalSpentWagesEur: totalWages,
      totalSpentBonusesEur: totalBonuses,
      totalMarketSavingsEur: totalSavings,
      rejectedOrExpiredCount: rejectedOrExpired,
      hijackedCount: hijacked,
      windowGrade: grade,
      mediaVerdict: verdict,
    );
  }

  List<LastMinuteAgentOffer> _buildInitialOffers(
    math.Random rng,
    TransferDeadlineDayConfig config,
  ) {
    return [
      LastMinuteAgentOffer(
        id: 'dl_offer_1',
        riderId: 'r_van_der_berg',
        riderName: 'Jasper Van Der Berg',
        nationalityCode: 'NED',
        age: 26,
        overallRating: 82,
        specialty: DeadlineRiderSpecialty.classicsPuncheur,
        previousTeamName: 'Lowlands Lotto',
        agent: _agentsPool[0],
        offerType: DeadlineOfferType.freeAgentBargain,
        proposedRole: RiderRole.coLeader,
        contractYears: 2,
        annualSalaryEur: 420000,
        askingSalaryEur: 360000,
        marketValueEur: 480000,
        signingBonusEur: 35000,
        releaseBuyoutEur: 0,
        uciPointsLastSeason: 645,
        initialExpiryMinutes: 150,
        remainingOfferMinutes: 150,
        urgency: DeadlineOfferUrgency.urgent,
        status: DeadlineOfferStatus.pending,
        agentPitch:
            'Rozwiązaliśmy wczoraj kontrakt za porozumieniem stron. Jasper chce jechać bruki w Waszych barwach — zejdzie z pensji, jeśli domkniemy to szybko.',
        competingClubsCount: 2,
        rivalInterestScore: 74,
      ),
      LastMinuteAgentOffer(
        id: 'dl_offer_2',
        riderId: 'r_martinez_leo',
        riderName: 'Mateo Martínez',
        nationalityCode: 'COL',
        age: 24,
        overallRating: 80,
        specialty: DeadlineRiderSpecialty.gcClimber,
        previousTeamName: 'Andes Mountain Pro',
        agent: _agentsPool[1],
        offerType: DeadlineOfferType.emergencyLoanOrRelease,
        proposedRole: RiderRole.superDomestique,
        contractYears: 3,
        annualSalaryEur: 310000,
        askingSalaryEur: 310000,
        marketValueEur: 390000,
        signingBonusEur: 25000,
        releaseBuyoutEur: 120000,
        uciPointsLastSeason: 510,
        initialExpiryMinutes: 180,
        remainingOfferMinutes: 180,
        urgency: DeadlineOfferUrgency.standard,
        status: DeadlineOfferStatus.pending,
        agentPitch:
            'Ekipa Mateo straciła sponsora i aktywowała klauzulę wykupu. Świetny góral na trzeci tydzień Grand Touru.',
        competingClubsCount: 3,
        rivalInterestScore: 81,
      ),
      LastMinuteAgentOffer(
        id: 'dl_offer_3',
        riderId: 'r_zielinski_jan',
        riderName: 'Szymon Zieliński',
        nationalityCode: 'POL',
        age: 21,
        overallRating: 76,
        specialty: DeadlineRiderSpecialty.u23Wonderkid,
        previousTeamName: 'Vistula Development U23',
        agent: _agentsPool[3],
        offerType: DeadlineOfferType.lastMinutePoach,
        proposedRole: RiderRole.neoPro,
        contractYears: 3,
        annualSalaryEur: 145000,
        askingSalaryEur: 145000,
        marketValueEur: 210000,
        signingBonusEur: 15000,
        releaseBuyoutEur: 40000,
        uciPointsLastSeason: 285,
        initialExpiryMinutes: 95,
        remainingOfferMinutes: 95,
        urgency: DeadlineOfferUrgency.urgent,
        status: DeadlineOfferStatus.pending,
        agentPitch:
            'Szymon ma w ręku ofertę z ProTeamu, ale woli od razu wejść do WorldTouru. Decyzja potrzebna w ciągu półtorej godziny.',
        competingClubsCount: 2,
        rivalInterestScore: 68,
      ),
      LastMinuteAgentOffer(
        id: 'dl_offer_4',
        riderId: 'r_dubois_theo',
        riderName: 'Théo Dubois',
        nationalityCode: 'FRA',
        age: 29,
        overallRating: 84,
        specialty: DeadlineRiderSpecialty.sprinter,
        previousTeamName: 'Bretagne Énergie',
        agent: _agentsPool[2],
        offerType: DeadlineOfferType.biddingWarEscalation,
        proposedRole: RiderRole.sprinter,
        contractYears: 2,
        annualSalaryEur: 580000,
        askingSalaryEur: 620000,
        marketValueEur: 650000,
        signingBonusEur: 60000,
        releaseBuyoutEur: 150000,
        uciPointsLastSeason: 890,
        initialExpiryMinutes: 60,
        remainingOfferMinutes: 60,
        urgency: DeadlineOfferUrgency.flashExpiring,
        status: DeadlineOfferStatus.pending,
        agentPitch:
            'Dwie drużyny WT właśnie przebiły bazę! Jeśli dacie mu status głównego sprintera i szybki podpis, Théo wybiera Was.',
        competingClubsCount: 4,
        rivalInterestScore: 92,
      ),
      LastMinuteAgentOffer(
        id: 'dl_offer_5',
        riderId: 'r_sorensen_mikkel',
        riderName: 'Mikkel Sørensen',
        nationalityCode: 'DEN',
        age: 28,
        overallRating: 78,
        specialty: DeadlineRiderSpecialty.timeTrialist,
        previousTeamName: 'Nordic Aero Team',
        agent: _agentsPool[0 + rng.nextInt(2)],
        offerType: DeadlineOfferType.mutualContractTermination,
        proposedRole: RiderRole.domestique,
        contractYears: 2,
        annualSalaryEur: 220000,
        askingSalaryEur: 195000,
        marketValueEur: 260000,
        signingBonusEur: 10000,
        releaseBuyoutEur: 0,
        uciPointsLastSeason: 340,
        initialExpiryMinutes: 210,
        remainingOfferMinutes: 210,
        urgency: DeadlineOfferUrgency.standard,
        status: DeadlineOfferStatus.pending,
        agentPitch:
            'Specjalista od jazdy na wietrze i rozprowadzania pociągu. Bez kwoty odstępnego, dostępny od ręki.',
        competingClubsCount: 1,
        rivalInterestScore: 45,
      ),
    ];
  }

  LastMinuteAgentOffer _generateDynamicLastMinuteOffer({
    required math.Random rng,
    required int waveIndex,
    required int remainingWindowMinutes,
  }) {
    const candidates = [
      (
        'Luca Bellini',
        'ITA',
        25,
        79,
        DeadlineRiderSpecialty.classicsPuncheur,
        'Toscana Cycling',
        RiderRole.breakawaySpecialist,
        290000,
        360000
      ),
      (
        'Benjamín Rojas',
        'CHI',
        23,
        77,
        DeadlineRiderSpecialty.gcClimber,
        'Pacifico Continental',
        RiderRole.domestique,
        185000,
        250000
      ),
      (
        'Oliver Wright',
        'GBR',
        30,
        81,
        DeadlineRiderSpecialty.superDomestique,
        'Albion Pro Squad',
        RiderRole.superDomestique,
        340000,
        430000
      ),
      (
        'Nils Lindqvist',
        'SWE',
        22,
        75,
        DeadlineRiderSpecialty.timeTrialist,
        'Scandia Development',
        RiderRole.neoPro,
        130000,
        190000
      ),
    ];

    final pick = candidates[(waveIndex + rng.nextInt(candidates.length)) %
        candidates.length];
    final agent = _agentsPool[rng.nextInt(_agentsPool.length)];
    final int expiry = math.min(
      remainingWindowMinutes,
      remainingWindowMinutes <= 60 ? 35 : 75 + rng.nextInt(45),
    );
    final int offerTypeIdx = rng.nextInt(DeadlineOfferType.values.length);
    final offerType = DeadlineOfferType.values[offerTypeIdx];

    return LastMinuteAgentOffer(
      id: 'dl_wave_${waveIndex}_$remainingWindowMinutes',
      riderId: 'r_wave_$waveIndex',
      riderName: pick.$1,
      nationalityCode: pick.$2,
      age: pick.$3,
      overallRating: pick.$4,
      specialty: pick.$5,
      previousTeamName: pick.$6,
      agent: agent,
      offerType: offerType,
      proposedRole: pick.$7,
      contractYears: 1 + rng.nextInt(3),
      annualSalaryEur: pick.$8,
      askingSalaryEur: pick.$8,
      marketValueEur: pick.$9,
      signingBonusEur: (pick.$8 * 0.08).round(),
      releaseBuyoutEur:
          offerType == DeadlineOfferType.freeAgentBargain ? 0 : 45000,
      uciPointsLastSeason: 240 + rng.nextInt(420),
      initialExpiryMinutes: math.max(15, expiry),
      remainingOfferMinutes: math.max(15, expiry),
      urgency: _computeUrgency(expiry),
      status: DeadlineOfferStatus.pending,
      agentPitch: remainingWindowMinutes <= 60
          ? 'Ostatni dzwonek przed północą! Klient zaakceptuje szybki podpis w ciągu najbliższych minut.'
          : 'Świeża propozycja na biurko dyrektora — rynek przyspiesza z każdą godziną.',
      competingClubsCount: 1 + rng.nextInt(3),
      rivalInterestScore: 50 + rng.nextInt(40),
    );
  }

  DeadlineOfferUrgency _computeUrgency(int remainingMinutes) {
    if (remainingMinutes <= 20) return DeadlineOfferUrgency.critical;
    if (remainingMinutes <= 45) return DeadlineOfferUrgency.flashExpiring;
    if (remainingMinutes <= 100) return DeadlineOfferUrgency.urgent;
    return DeadlineOfferUrgency.standard;
  }

  static String _formatMinutesCompact(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  static String _formatEur(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final revIdx = str.length - i;
      buf.write(str[i]);
      if (revIdx > 1 && revIdx % 3 == 1) {
        buf.write(' ');
      }
    }
    final prefix = amount < 0 ? '-' : '';
    return '$prefix€${buf.toString()}';
  }
}

/// Kontroler Riverpod zarządzający odliczaniem na żywo i negocjacjami Deadline Day.
class TransferDeadlineDayNotifier
    extends StateNotifier<TransferDeadlineDayState> {
  final TransferDeadlineDayLiveEventService _service;
  Timer? _liveTimer;

  TransferDeadlineDayNotifier({
    TransferDeadlineDayLiveEventService? service,
    TransferDeadlineDayConfig? config,
    int seed = 2026,
  })  : _service = service ?? const TransferDeadlineDayLiveEventService(),
        super(
          (service ?? const TransferDeadlineDayLiveEventService())
              .createInitialState(
            config: config ?? const TransferDeadlineDayConfig(),
            seed: seed,
          ),
        );

  void startLiveClock() {
    if (state.isWindowClosed || state.isLiveTicking) return;
    state = state.copyWith(isLiveTicking: true, clearFeedback: true);
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (state.isWindowClosed) {
        pauseLiveClock();
        return;
      }
      final stepMinutes = 5 * state.simulationSpeedMultiplier;
      state = _service.advanceTime(state, minutes: stepMinutes);
      if (state.isWindowClosed) {
        _liveTimer?.cancel();
        _liveTimer = null;
      }
    });
  }

  void pauseLiveClock() {
    _liveTimer?.cancel();
    _liveTimer = null;
    if (state.isLiveTicking) {
      state = state.copyWith(isLiveTicking: false);
    }
  }

  void toggleLiveClock() {
    if (state.isLiveTicking) {
      pauseLiveClock();
    } else {
      startLiveClock();
    }
  }

  void setSpeedMultiplier(int multiplier) {
    final valid = multiplier.clamp(1, 5);
    state = state.copyWith(simulationSpeedMultiplier: valid);
  }

  void advanceMinutes(int minutes) {
    state = _service.advanceTime(state, minutes: minutes);
    if (state.isWindowClosed) {
      _liveTimer?.cancel();
      _liveTimer = null;
    }
  }

  void selectOffer(String? offerId) {
    state = state.copyWith(
      selectedOfferId: offerId,
      clearSelectedOffer: offerId == null,
      clearFeedback: true,
    );
  }

  void acceptOffer(String offerId) {
    state = _service.acceptOffer(state, offerId);
  }

  void submitCounterOffer({
    required String offerId,
    required int counterSalaryEur,
    required int counterYears,
    required RiderRole counterRole,
  }) {
    state = _service.submitCounterOffer(
      state,
      offerId: offerId,
      counterSalaryEur: counterSalaryEur,
      counterYears: counterYears,
      counterRole: counterRole,
    );
  }

  void rejectOffer(String offerId) {
    state = _service.rejectOffer(state, offerId);
  }

  void toggleShortlist(String offerId) {
    state = _service.toggleShortlist(state, offerId);
  }

  void setFilterType(DeadlineOfferType? type) {
    state = state.copyWith(
      filterType: type,
      clearFilterType: type == null,
    );
  }

  void setOnlyShortlisted(bool value) {
    state = state.copyWith(onlyShortlisted: value);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetEvent({TransferDeadlineDayConfig? config, int seed = 2026}) {
    pauseLiveClock();
    state = _service.createInitialState(
      config: config ?? state.config,
      seed: seed,
    );
  }

  DeadlineDaySummaryReport getSummaryReport() =>
      _service.buildSummaryReport(state);

  @override
  void dispose() {
    _liveTimer?.cancel();
    _liveTimer = null;
    super.dispose();
  }
}

final transferDeadlineDayProvider = StateNotifierProvider.autoDispose<
    TransferDeadlineDayNotifier, TransferDeadlineDayState>(
  (ref) => TransferDeadlineDayNotifier(),
);

/// Główny responsywny panel UI wydarzenia Transfer Deadline Day.
///
/// Obsługuje układy `390x844` (mobile), `1024x768` (tablet) oraz `1600x900` (desktop)
/// z pełnymi stanami `hover` / `active` / `disabled` / `focus` oraz paletą [AppColors].
class TransferDeadlineDayPanel extends ConsumerStatefulWidget {
  final bool showAppBarHeader;

  const TransferDeadlineDayPanel({
    super.key,
    this.showAppBarHeader = true,
  });

  @override
  ConsumerState<TransferDeadlineDayPanel> createState() =>
      _TransferDeadlineDayPanelState();
}

class _TransferDeadlineDayPanelState
    extends ConsumerState<TransferDeadlineDayPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final TextEditingController _searchController;
  int _counterSalaryEur = 300000;
  int _counterYears = 2;
  RiderRole _counterRole = RiderRole.domestique;
  String? _syncedOfferId;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _syncNegotiationControls(LastMinuteAgentOffer? offer) {
    if (offer == null || _syncedOfferId == offer.id) return;
    _syncedOfferId = offer.id;
    _counterSalaryEur = (offer.askingSalaryEur * 0.92).round();
    _counterYears = offer.contractYears;
    _counterRole = offer.proposedRole;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferDeadlineDayProvider);
    final notifier = ref.read(transferDeadlineDayProvider.notifier);
    final selectedOffer = state.selectedOffer;
    _syncNegotiationControls(selectedOffer);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isDesktop = width >= 1200;
          final bool isTablet = width >= 760 && width < 1200;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showAppBarHeader)
                _DeadlineCountdownHeader(
                  state: state,
                  pulseAnimation: _pulseController,
                  isCompact: width < 760,
                  onToggleLive: notifier.toggleLiveClock,
                  onAdvanceHour: () => notifier.advanceMinutes(60),
                  onAdvance15Min: () => notifier.advanceMinutes(15),
                  onSelectSpeed: notifier.setSpeedMultiplier,
                  onReset: () => notifier.resetEvent(),
                ),
              if (state.lastActionFeedback != null)
                _FeedbackBanner(message: state.lastActionFeedback!),
              Expanded(
                child: isDesktop
                    ? _buildDesktopLayout(state, notifier, selectedOffer)
                    : isTablet
                        ? _buildTabletLayout(state, notifier, selectedOffer)
                        : _buildMobileLayout(state, notifier, selectedOffer),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    TransferDeadlineDayState state,
    TransferDeadlineDayNotifier notifier,
    LastMinuteAgentOffer? selectedOffer,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _OffersInboxCard(
              state: state,
              searchController: _searchController,
              onSearchChanged: notifier.setSearchQuery,
              onFilterChanged: notifier.setFilterType,
              onShortlistFilterToggled: notifier.setOnlyShortlisted,
              onSelectOffer: notifier.selectOffer,
              onToggleShortlist: notifier.toggleShortlist,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: _NegotiationDeskCard(
              state: state,
              offer: selectedOffer,
              counterSalaryEur: _counterSalaryEur,
              counterYears: _counterYears,
              counterRole: _counterRole,
              onSalaryChanged: (val) => setState(() => _counterSalaryEur = val),
              onYearsChanged: (val) => setState(() => _counterYears = val),
              onRoleChanged: (val) => setState(() => _counterRole = val),
              onAccept: () {
                if (selectedOffer != null) {
                  notifier.acceptOffer(selectedOffer.id);
                }
              },
              onCounter: () {
                if (selectedOffer != null) {
                  notifier.submitCounterOffer(
                    offerId: selectedOffer.id,
                    counterSalaryEur: _counterSalaryEur,
                    counterYears: _counterYears,
                    counterRole: _counterRole,
                  );
                }
              },
              onReject: () {
                if (selectedOffer != null) {
                  notifier.rejectOffer(selectedOffer.id);
                }
              },
              summaryReport: notifier.getSummaryReport(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _LiveTickerAndDealsColumn(
              state: state,
              pulseAnimation: _pulseController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    TransferDeadlineDayState state,
    TransferDeadlineDayNotifier notifier,
    LastMinuteAgentOffer? selectedOffer,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _OffersInboxCard(
              state: state,
              searchController: _searchController,
              onSearchChanged: notifier.setSearchQuery,
              onFilterChanged: notifier.setFilterType,
              onShortlistFilterToggled: notifier.setOnlyShortlisted,
              onSelectOffer: notifier.selectOffer,
              onToggleShortlist: notifier.toggleShortlist,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NegotiationDeskCard(
                    state: state,
                    offer: selectedOffer,
                    counterSalaryEur: _counterSalaryEur,
                    counterYears: _counterYears,
                    counterRole: _counterRole,
                    isScrollableParent: true,
                    onSalaryChanged: (val) =>
                        setState(() => _counterSalaryEur = val),
                    onYearsChanged: (val) =>
                        setState(() => _counterYears = val),
                    onRoleChanged: (val) => setState(() => _counterRole = val),
                    onAccept: () {
                      if (selectedOffer != null) {
                        notifier.acceptOffer(selectedOffer.id);
                      }
                    },
                    onCounter: () {
                      if (selectedOffer != null) {
                        notifier.submitCounterOffer(
                          offerId: selectedOffer.id,
                          counterSalaryEur: _counterSalaryEur,
                          counterYears: _counterYears,
                          counterRole: _counterRole,
                        );
                      }
                    },
                    onReject: () {
                      if (selectedOffer != null) {
                        notifier.rejectOffer(selectedOffer.id);
                      }
                    },
                    summaryReport: notifier.getSummaryReport(),
                  ),
                  const SizedBox(height: 12),
                  _LiveTickerAndDealsColumn(
                    state: state,
                    pulseAnimation: _pulseController,
                    fixedHeight: 340,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    TransferDeadlineDayState state,
    TransferDeadlineDayNotifier notifier,
    LastMinuteAgentOffer? selectedOffer,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OffersInboxCard(
            state: state,
            searchController: _searchController,
            fixedHeight: 360,
            onSearchChanged: notifier.setSearchQuery,
            onFilterChanged: notifier.setFilterType,
            onShortlistFilterToggled: notifier.setOnlyShortlisted,
            onSelectOffer: notifier.selectOffer,
            onToggleShortlist: notifier.toggleShortlist,
          ),
          const SizedBox(height: 12),
          _NegotiationDeskCard(
            state: state,
            offer: selectedOffer,
            counterSalaryEur: _counterSalaryEur,
            counterYears: _counterYears,
            counterRole: _counterRole,
            isScrollableParent: true,
            onSalaryChanged: (val) => setState(() => _counterSalaryEur = val),
            onYearsChanged: (val) => setState(() => _counterYears = val),
            onRoleChanged: (val) => setState(() => _counterRole = val),
            onAccept: () {
              if (selectedOffer != null) {
                notifier.acceptOffer(selectedOffer.id);
              }
            },
            onCounter: () {
              if (selectedOffer != null) {
                notifier.submitCounterOffer(
                  offerId: selectedOffer.id,
                  counterSalaryEur: _counterSalaryEur,
                  counterYears: _counterYears,
                  counterRole: _counterRole,
                );
              }
            },
            onReject: () {
              if (selectedOffer != null) {
                notifier.rejectOffer(selectedOffer.id);
              }
            },
            summaryReport: notifier.getSummaryReport(),
          ),
          const SizedBox(height: 12),
          _LiveTickerAndDealsColumn(
            state: state,
            pulseAnimation: _pulseController,
            fixedHeight: 320,
          ),
        ],
      ),
    );
  }
}

class _DeadlineCountdownHeader extends StatelessWidget {
  final TransferDeadlineDayState state;
  final Animation<double> pulseAnimation;
  final bool isCompact;
  final VoidCallback onToggleLive;
  final VoidCallback onAdvanceHour;
  final VoidCallback onAdvance15Min;
  final ValueChanged<int> onSelectSpeed;
  final VoidCallback onReset;

  const _DeadlineCountdownHeader({
    required this.state,
    required this.pulseAnimation,
    required this.isCompact,
    required this.onToggleLive,
    required this.onAdvanceHour,
    required this.onAdvance15Min,
    required this.onSelectSpeed,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final phase = state.currentPhase;
    return Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        isCompact ? 12 : 16,
        isCompact ? 12 : 16,
        0,
      ),
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isWindowClosed
              ? AppColors.cardBorder
              : phase.accentColor.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, _) {
                  final double glow =
                      state.isWindowClosed ? 0.25 : 0.45 + 0.55 * pulseAnimation.value;
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: phase.accentColor.withValues(alpha: glow),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.config.windowName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.config.teamName} • Faza: ${phase.label} • Zegar ${state.currentClockLabel}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HeaderMetricPill(
                label: 'DO ZAMKNIĘCIA',
                value: state.formattedCountdown,
                accentColor: phase.accentColor,
              ),
              _HeaderMetricPill(
                label: 'BUDŻET PŁAC',
                value: TransferDeadlineDayLiveEventService._formatEur(
                  state.remainingWageBudgetEur,
                ),
                accentColor: AppColors.statusSuccess,
              ),
              _HeaderMetricPill(
                label: 'WYKUPY / BONUSY',
                value: TransferDeadlineDayLiveEventService._formatEur(
                  state.remainingTransferBudgetEur,
                ),
                accentColor: AppColors.accentBlue,
              ),
              _HeaderMetricPill(
                label: 'WOLNE MIEJSCA',
                value: '${state.remainingRosterSlots}',
                accentColor: state.remainingRosterSlots > 0
                    ? AppColors.goldAccent
                    : AppColors.crimsonAlert,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DeadlineInteractiveButton(
                label: state.isLiveTicking ? 'Pauza' : 'Start Live',
                icon: state.isLiveTicking ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                disabled: state.isWindowClosed,
                onPressed: onToggleLive,
              ),
              _DeadlineInteractiveButton(
                label: '+15 min',
                icon: Icons.fast_forward,
                disabled: state.isWindowClosed,
                onPressed: onAdvance15Min,
              ),
              _DeadlineInteractiveButton(
                label: '+1 godz',
                icon: Icons.skip_next,
                disabled: state.isWindowClosed,
                onPressed: onAdvanceHour,
              ),
              _SpeedSelectorGroup(
                currentSpeed: state.simulationSpeedMultiplier,
                disabled: state.isWindowClosed,
                onSelected: onSelectSpeed,
              ),
              _DeadlineInteractiveButton(
                label: 'Reset',
                icon: Icons.refresh,
                onPressed: onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _HeaderMetricPill({
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
        border: Border.all(color: AppTheme.borderColor, width: 1),
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
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedSelectorGroup extends StatelessWidget {
  final int currentSpeed;
  final bool disabled;
  final ValueChanged<int> onSelected;

  const _SpeedSelectorGroup({
    required this.currentSpeed,
    required this.disabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [1, 2, 5].map((speed) {
          final bool active = currentSpeed == speed;
          return InkWell(
            onTap: disabled ? null : () => onSelected(speed),
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.goldAccent.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${speed}x',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: disabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : active
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;

  const _FeedbackBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppColors.goldAccent, size: 18),
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
}

class _OffersInboxCard extends StatelessWidget {
  final TransferDeadlineDayState state;
  final TextEditingController searchController;
  final double? fixedHeight;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DeadlineOfferType?> onFilterChanged;
  final ValueChanged<bool> onShortlistFilterToggled;
  final ValueChanged<String> onSelectOffer;
  final ValueChanged<String> onToggleShortlist;

  const _OffersInboxCard({
    required this.state,
    required this.searchController,
    this.fixedHeight,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onShortlistFilterToggled,
    required this.onSelectOffer,
    required this.onToggleShortlist,
  });

  @override
  Widget build(BuildContext context) {
    final offers = state.filteredOffers;
    final card = Container(
      height: fixedHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.flash_on,
                  color: AppColors.goldAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Oferty Agentów (${state.activeOffersCount} aktywne)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _DeadlineFilterChip(
                  label: 'Obserwowane',
                  selected: state.onlyShortlisted,
                  onTap: () => onShortlistFilterToggled(!state.onlyShortlisted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Szukaj kolarza, agenta lub specjalizacji...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.goldAccent),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _DeadlineFilterChip(
                  label: 'Wszystkie',
                  selected: state.filterType == null,
                  onTap: () => onFilterChanged(null),
                ),
                const SizedBox(width: 6),
                ...DeadlineOfferType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _DeadlineFilterChip(
                      label: type.label,
                      selected: state.filterType == type,
                      onTap: () => onFilterChanged(
                        state.filterType == type ? null : type,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: offers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Brak ofert spełniających wybrane kryteria.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: offers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final offer = offers[idx];
                      final bool isSelected =
                          offer.id == state.selectedOfferId;
                      return _OfferListTile(
                        offer: offer,
                        isSelected: isSelected,
                        onTap: () => onSelectOffer(offer.id),
                        onToggleShortlist: () => onToggleShortlist(offer.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
    return card;
  }
}

class _OfferListTile extends StatefulWidget {
  final LastMinuteAgentOffer offer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleShortlist;

  const _OfferListTile({
    required this.offer,
    required this.isSelected,
    required this.onTap,
    required this.onToggleShortlist,
  });

  @override
  State<_OfferListTile> createState() => _OfferListTileState();
}

class _OfferListTileState extends State<_OfferListTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _isFocused
            ? AppColors.accentBlue
            : _isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppTheme.borderColor;

    return Focus(
      onFocusChange: (val) => setState(() => _isFocused = val),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : _isHovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.65)
                      : AppColors.background.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: offer.offerType.badgeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OVR ${offer.overallRating}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: offer.offerType.badgeColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${offer.riderName} (${offer.nationalityCode}, ${offer.age} l.)',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onToggleShortlist,
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: 'Obserwuj ofertę',
                      icon: Icon(
                        offer.isShortlisted ? Icons.star : Icons.star_border,
                        color: offer.isShortlisted
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      offer.specialty.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '• ${TransferDeadlineDayLiveEventService._formatEur(offer.askingSalaryEur)}/rok',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: offer.status.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        offer.isActionable
                            ? 'Wygasa za ${offer.remainingOfferMinutes}m'
                            : offer.status.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: offer.isActionable
                              ? offer.urgency.color
                              : offer.status.color,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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

class _NegotiationDeskCard extends StatelessWidget {
  final TransferDeadlineDayState state;
  final LastMinuteAgentOffer? offer;
  final int counterSalaryEur;
  final int counterYears;
  final RiderRole counterRole;
  final bool isScrollableParent;
  final ValueChanged<int> onSalaryChanged;
  final ValueChanged<int> onYearsChanged;
  final ValueChanged<RiderRole> onRoleChanged;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onReject;
  final DeadlineDaySummaryReport summaryReport;

  const _NegotiationDeskCard({
    required this.state,
    required this.offer,
    required this.counterSalaryEur,
    required this.counterYears,
    required this.counterRole,
    this.isScrollableParent = false,
    required this.onSalaryChanged,
    required this.onYearsChanged,
    required this.onRoleChanged,
    required this.onAccept,
    required this.onCounter,
    required this.onReject,
    required this.summaryReport,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isWindowClosed)
          _WindowClosedSummaryBanner(report: summaryReport),
        if (offer == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Wybierz ofertę agenta z listy po lewej, aby rozpocząć negocjacje last-minute.',
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
          _buildOfferDetailBody(offer!),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: isScrollableParent
          ? content
          : SingleChildScrollView(child: content),
    );
  }

  Widget _buildOfferDetailBody(LastMinuteAgentOffer selected) {
    final bool canNegotiate = !state.isWindowClosed && selected.isActionable;
    final int minSlider = math.max(80000, (selected.askingSalaryEur * 0.6).round());
    final int maxSlider = math.max(
      minSlider + 50000,
      (selected.askingSalaryEur * 1.25).round(),
    );
    final int clampedCounter = counterSalaryEur.clamp(minSlider, maxSlider);

    return Column(
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
                    selected.riderName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${selected.specialty.label} • Poprzednio: ${selected.previousTeamName} • ${selected.uciPointsLastSeason} pkt UCI',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected.status.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected.status.color.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                selected.isActionable
                    ? 'Pozostało ${selected.remainingOfferMinutes}m'
                    : selected.status.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected.isActionable
                      ? selected.urgency.color
                      : selected.status.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.record_voice_over,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${selected.agent.name} (${selected.agent.agencyName})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                  Text(
                    'Rywale: ${selected.competingClubsCount}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amberWarning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '"${selected.agentPitch}"',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeaderMetricPill(
              label: 'ŻĄDANA PENSJA',
              value:
                  '${TransferDeadlineDayLiveEventService._formatEur(selected.askingSalaryEur)}/rok',
              accentColor: AppColors.textPrimary,
            ),
            _HeaderMetricPill(
              label: 'WARTOŚĆ RYNKOWA',
              value: TransferDeadlineDayLiveEventService._formatEur(
                selected.marketValueEur,
              ),
              accentColor: AppColors.accentBlue,
            ),
            _HeaderMetricPill(
              label: 'BONUS + WYKUP',
              value: TransferDeadlineDayLiveEventService._formatEur(
                selected.signingBonusEur + selected.releaseBuyoutEur,
              ),
              accentColor: AppColors.amberWarning,
            ),
            _HeaderMetricPill(
              label: 'RÓŻNICA VS RYNEK',
              value: '${selected.discountPercentage.toStringAsFixed(1)}%',
              accentColor: selected.discountPercentage >= 0
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.borderColor),
        const SizedBox(height: 14),
        const Text(
          'Stół Negocjacyjny (Kontroferta)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Proponowana pensja roczna:',
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
              TransferDeadlineDayLiveEventService._formatEur(clampedCounter),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: clampedCounter.toDouble(),
            min: minSlider.toDouble(),
            max: maxSlider.toDouble(),
            divisions: 20,
            onChanged: canNegotiate
                ? (v) => onSalaryChanged((v / 5000).round() * 5000)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButtonHideUnderline(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 230),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButton<RiderRole>(
                  value: counterRole,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceLight,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  items: RiderRole.values
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: canNegotiate
                      ? (role) {
                          if (role != null) onRoleChanged(role);
                        }
                      : null,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [1, 2, 3, 4].map((yrs) {
                final bool active = counterYears == yrs;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _DeadlineFilterChip(
                    label: '$yrs l.',
                    selected: active,
                    onTap: canNegotiate ? () => onYearsChanged(yrs) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DeadlineInteractiveButton(
              label: 'Podpisz Natychmiast',
              icon: Icons.verified,
              isPrimary: true,
              disabled: !canNegotiate,
              onPressed: onAccept,
            ),
            _DeadlineInteractiveButton(
              label: 'Wyślij Kontrofertę',
              icon: Icons.handshake,
              disabled: !canNegotiate,
              onPressed: onCounter,
            ),
            _DeadlineInteractiveButton(
              label: 'Odrzuć',
              icon: Icons.close,
              isDanger: true,
              disabled: !canNegotiate,
              onPressed: onReject,
            ),
          ],
        ),
      ],
    );
  }
}

class _WindowClosedSummaryBanner extends StatelessWidget {
  final DeadlineDaySummaryReport report;

  const _WindowClosedSummaryBanner({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'OCENA OKNA: ${report.windowGrade}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Podpisano ${report.totalDealsSigned} kontraktów • Oszczędność ${TransferDeadlineDayLiveEventService._formatEur(report.totalMarketSavingsEur)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.mediaVerdict,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTickerAndDealsColumn extends StatelessWidget {
  final TransferDeadlineDayState state;
  final Animation<double> pulseAnimation;
  final double? fixedHeight;

  const _LiveTickerAndDealsColumn({
    required this.state,
    required this.pulseAnimation,
    this.fixedHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: fixedHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, _) => Icon(
                    Icons.sensors,
                    size: 18,
                    color: state.isWindowClosed
                        ? AppColors.textSecondary
                        : AppColors.crimsonAlert.withValues(
                            alpha: 0.45 + 0.55 * pulseAnimation.value,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pasek Transferowy Na Żywo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            flex: 3,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.tickerFeed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = state.tickerFeed[idx];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.isBreaking
                          ? item.category.color.withValues(alpha: 0.45)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  item.category.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.category.tag,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: item.category.color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.timestampLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.headline,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtext,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Text(
              'Zamknięte Kontrakty (${state.completedDeals.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.statusSuccess,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: state.completedDeals.isEmpty
                ? const Center(
                    child: Text(
                      'Brak sfinalizowanych umów.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: state.completedDeals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final deal = state.completedDeals[idx];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                AppColors.statusSuccess.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.statusSuccess,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${deal.riderName} (${deal.contractYears} l.)',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${deal.role.label} • ${TransferDeadlineDayLiveEventService._formatEur(deal.annualSalaryEur)}/rok',
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
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _DeadlineFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_DeadlineFilterChip> createState() => _DeadlineFilterChipState();
}

class _DeadlineFilterChipState extends State<_DeadlineFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null;
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.35)
                  : _hovered && !disabled
                      ? AppColors.surfaceLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.selected
                    ? AppColors.goldAccent
                    : _focused
                        ? AppColors.accentBlue
                        : AppTheme.borderColor,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : widget.selected
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

class _DeadlineInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDanger;
  final bool disabled;
  final VoidCallback onPressed;

  const _DeadlineInteractiveButton({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.isDanger = false,
    this.disabled = false,
    required this.onPressed,
  });

  @override
  State<_DeadlineInteractiveButton> createState() =>
      _DeadlineInteractiveButtonState();
}

class _DeadlineInteractiveButtonState
    extends State<_DeadlineInteractiveButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : widget.isDanger
            ? AppColors.crimsonAlert.withValues(alpha: 0.16)
            : AppColors.surfaceLight;
    final Color bg = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
            ? baseBg.withValues(alpha: 0.78)
            : _hovered
                ? baseBg.withValues(alpha: 0.92)
                : baseBg;
    final Color borderColor = widget.disabled
        ? AppTheme.borderColor
        : _focused
            ? AppColors.accentBlue
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.65)
                : widget.isDanger
                    ? AppColors.crimsonAlert.withValues(alpha: 0.5)
                    : AppTheme.borderColor;
    final Color fgColor = widget.disabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isDanger
            ? AppColors.crimsonAlert
            : AppColors.textPrimary;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: InkWell(
            onTap: widget.disabled ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 16, color: fgColor),
                  const SizedBox(width: 7),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
