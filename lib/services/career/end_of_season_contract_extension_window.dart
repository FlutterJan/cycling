// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/staff_member.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Typ podmiotu objętego wrześniowym oknem przedłużeń kontraktów.
enum ExtensionTargetKind {
  rider,
  staff;

  String toJson() => name;

  static ExtensionTargetKind fromJson(String value) {
    return ExtensionTargetKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExtensionTargetKind.rider,
    );
  }

  String get label {
    switch (this) {
      case ExtensionTargetKind.rider:
        return 'Zawodnik';
      case ExtensionTargetKind.staff:
        return 'Sztab';
    }
  }
}

/// Aktualny status negocjacji przedłużenia wygasającego kontraktu.
enum ContractExtensionStatus {
  pendingReview,
  negotiating,
  extended,
  declinedToRenew,
  signedByRival;

  String toJson() => name;

  static ContractExtensionStatus fromJson(String value) {
    return ContractExtensionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ContractExtensionStatus.pendingReview,
    );
  }

  String get label {
    switch (this) {
      case ContractExtensionStatus.pendingReview:
        return 'Wygasa 31 XII';
      case ContractExtensionStatus.negotiating:
        return 'W negocjacjach';
      case ContractExtensionStatus.extended:
        return 'Przedłużono';
      case ContractExtensionStatus.declinedToRenew:
        return 'Odrzucono przedłużenie';
      case ContractExtensionStatus.signedByRival:
        return 'Przejęty przez rywala';
    }
  }

  bool get isTerminal =>
      this == ContractExtensionStatus.extended ||
      this == ContractExtensionStatus.declinedToRenew ||
      this == ContractExtensionStatus.signedByRival;
}

/// Nastawienie zawodnika lub członka sztabu do pozostania w drużynie.
enum NegotiationStance {
  loyalStay,
  wantsRaise,
  testingMarket,
  temptedByRival;

  String toJson() => name;

  static NegotiationStance fromJson(String value) {
    return NegotiationStance.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NegotiationStance.wantsRaise,
    );
  }

  String get label {
    switch (this) {
      case NegotiationStance.loyalStay:
        return 'Lojalny wobec zespołu';
      case NegotiationStance.wantsRaise:
        return 'Oczekuje podwyżki';
      case NegotiationStance.testingMarket:
        return 'Bada rynek transferowy';
      case NegotiationStance.temptedByRival:
        return 'Kuszony przez WorldTour';
    }
  }
}

/// Poziom pilności automatycznego powiadomienia o wstępnej ofercie rywala.
enum RivalOfferAlertSeverity {
  info,
  warning,
  critical;

  String toJson() => name;

  static RivalOfferAlertSeverity fromJson(String value) {
    return RivalOfferAlertSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RivalOfferAlertSeverity.warning,
    );
  }
}

/// Wstępna oferta złożona przez konkurencyjną ekipę UCI WorldTour.
class RivalWorldTourPreOffer {
  final String offerId;
  final String teamId;
  final String teamName;
  final String teamCountryIso;
  final int offeredMonthlySalaryEur;
  final int offeredYears;
  final int signingBonusEur;
  final String offeredRoleLabel;
  final int urgencyScore; // 1-100
  final DateTime submittedDate;
  final bool isHeadlineThreat;

  const RivalWorldTourPreOffer({
    required this.offerId,
    required this.teamId,
    required this.teamName,
    required this.teamCountryIso,
    required this.offeredMonthlySalaryEur,
    required this.offeredYears,
    required this.signingBonusEur,
    required this.offeredRoleLabel,
    required this.urgencyScore,
    required this.submittedDate,
    this.isHeadlineThreat = false,
  });

  int get annualSalaryEur => offeredMonthlySalaryEur * 12;

  RivalWorldTourPreOffer copyWith({
    String? offerId,
    String? teamId,
    String? teamName,
    String? teamCountryIso,
    int? offeredMonthlySalaryEur,
    int? offeredYears,
    int? signingBonusEur,
    String? offeredRoleLabel,
    int? urgencyScore,
    DateTime? submittedDate,
    bool? isHeadlineThreat,
  }) {
    return RivalWorldTourPreOffer(
      offerId: offerId ?? this.offerId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamCountryIso: teamCountryIso ?? this.teamCountryIso,
      offeredMonthlySalaryEur:
          offeredMonthlySalaryEur ?? this.offeredMonthlySalaryEur,
      offeredYears: offeredYears ?? this.offeredYears,
      signingBonusEur: signingBonusEur ?? this.signingBonusEur,
      offeredRoleLabel: offeredRoleLabel ?? this.offeredRoleLabel,
      urgencyScore: urgencyScore ?? this.urgencyScore,
      submittedDate: submittedDate ?? this.submittedDate,
      isHeadlineThreat: isHeadlineThreat ?? this.isHeadlineThreat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'teamId': teamId,
      'teamName': teamName,
      'teamCountryIso': teamCountryIso,
      'offeredMonthlySalaryEur': offeredMonthlySalaryEur,
      'offeredYears': offeredYears,
      'signingBonusEur': signingBonusEur,
      'offeredRoleLabel': offeredRoleLabel,
      'urgencyScore': urgencyScore,
      'submittedDate': submittedDate.toIso8601String(),
      'isHeadlineThreat': isHeadlineThreat,
    };
  }

  factory RivalWorldTourPreOffer.fromJson(Map<String, dynamic> json) {
    return RivalWorldTourPreOffer(
      offerId: json['offerId'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      teamCountryIso: (json['teamCountryIso'] as String?) ?? 'BEL',
      offeredMonthlySalaryEur:
          (json['offeredMonthlySalaryEur'] as num).toInt(),
      offeredYears: (json['offeredYears'] as num).toInt(),
      signingBonusEur: (json['signingBonusEur'] as num?)?.toInt() ?? 0,
      offeredRoleLabel:
          (json['offeredRoleLabel'] as String?) ?? 'Kontrakt WorldTour',
      urgencyScore: (json['urgencyScore'] as num?)?.toInt() ?? 50,
      submittedDate: DateTime.tryParse(
            (json['submittedDate'] as String?) ?? '',
          ) ??
          DateTime(2026, 9, 5),
      isHeadlineThreat: (json['isHeadlineThreat'] as bool?) ?? false,
    );
  }
}

/// Pozycja wygasającego kontraktu (zawodnika lub członka sztabu) w oknie wrześniowym.
class ExpiringContractEntry {
  final String entryId;
  final ExtensionTargetKind kind;
  final String fullName;
  final String nationalityIso;
  final int age;
  final String roleLabel;
  final int ratingOrLevel; // OVR (1-99) lub experienceLevel (1-100)
  final int currentMonthlySalaryEur;
  final int contractEndYear;
  final double morale;
  final double loyalty;
  final NegotiationStance stance;
  final ContractExtensionStatus status;
  final List<RivalWorldTourPreOffer> rivalOffers;
  final int proposedMonthlySalaryEur;
  final int proposedYears;
  final int proposedSigningBonusEur;
  final int counterOfferRounds;
  final String notes;

  const ExpiringContractEntry({
    required this.entryId,
    required this.kind,
    required this.fullName,
    required this.nationalityIso,
    required this.age,
    required this.roleLabel,
    required this.ratingOrLevel,
    required this.currentMonthlySalaryEur,
    required this.contractEndYear,
    required this.morale,
    required this.loyalty,
    required this.stance,
    this.status = ContractExtensionStatus.pendingReview,
    this.rivalOffers = const [],
    required this.proposedMonthlySalaryEur,
    this.proposedYears = 2,
    this.proposedSigningBonusEur = 0,
    this.counterOfferRounds = 0,
    this.notes = '',
  });

  bool get hasRivalOffers => rivalOffers.isNotEmpty;

  RivalWorldTourPreOffer? get highestRivalOffer {
    if (rivalOffers.isEmpty) return null;
    return rivalOffers.reduce(
      (a, b) => a.offeredMonthlySalaryEur >= b.offeredMonthlySalaryEur ? a : b,
    );
  }

  DateTime get expiryDate => DateTime(contractEndYear, 12, 31);

  int get currentAnnualSalaryEur => currentMonthlySalaryEur * 12;

  /// Rekomendowana miesięczna pensja do utrzymania kolarza/sztabowca w zespole.
  int get recommendedMatchSalaryEur {
    final rival = highestRivalOffer;
    if (rival == null) {
      final raiseMultiplier = stance == NegotiationStance.loyalStay ? 1.04 : 1.12;
      return ((currentMonthlySalaryEur * raiseMultiplier) / 500).round() * 500;
    }
    final loyaltyDiscount = loyalty >= 75.0 ? 0.96 : 1.02;
    final target = (rival.offeredMonthlySalaryEur * loyaltyDiscount).round();
    return math.max(
      currentMonthlySalaryEur,
      (target / 500).round() * 500,
    );
  }

  ExpiringContractEntry copyWith({
    String? entryId,
    ExtensionTargetKind? kind,
    String? fullName,
    String? nationalityIso,
    int? age,
    String? roleLabel,
    int? ratingOrLevel,
    int? currentMonthlySalaryEur,
    int? contractEndYear,
    double? morale,
    double? loyalty,
    NegotiationStance? stance,
    ContractExtensionStatus? status,
    List<RivalWorldTourPreOffer>? rivalOffers,
    int? proposedMonthlySalaryEur,
    int? proposedYears,
    int? proposedSigningBonusEur,
    int? counterOfferRounds,
    String? notes,
  }) {
    return ExpiringContractEntry(
      entryId: entryId ?? this.entryId,
      kind: kind ?? this.kind,
      fullName: fullName ?? this.fullName,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      age: age ?? this.age,
      roleLabel: roleLabel ?? this.roleLabel,
      ratingOrLevel: ratingOrLevel ?? this.ratingOrLevel,
      currentMonthlySalaryEur:
          currentMonthlySalaryEur ?? this.currentMonthlySalaryEur,
      contractEndYear: contractEndYear ?? this.contractEndYear,
      morale: morale ?? this.morale,
      loyalty: loyalty ?? this.loyalty,
      stance: stance ?? this.stance,
      status: status ?? this.status,
      rivalOffers: rivalOffers ?? this.rivalOffers,
      proposedMonthlySalaryEur:
          proposedMonthlySalaryEur ?? this.proposedMonthlySalaryEur,
      proposedYears: proposedYears ?? this.proposedYears,
      proposedSigningBonusEur:
          proposedSigningBonusEur ?? this.proposedSigningBonusEur,
      counterOfferRounds: counterOfferRounds ?? this.counterOfferRounds,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'kind': kind.toJson(),
      'fullName': fullName,
      'nationalityIso': nationalityIso,
      'age': age,
      'roleLabel': roleLabel,
      'ratingOrLevel': ratingOrLevel,
      'currentMonthlySalaryEur': currentMonthlySalaryEur,
      'contractEndYear': contractEndYear,
      'morale': morale,
      'loyalty': loyalty,
      'stance': stance.toJson(),
      'status': status.toJson(),
      'rivalOffers': rivalOffers.map((e) => e.toJson()).toList(),
      'proposedMonthlySalaryEur': proposedMonthlySalaryEur,
      'proposedYears': proposedYears,
      'proposedSigningBonusEur': proposedSigningBonusEur,
      'counterOfferRounds': counterOfferRounds,
      'notes': notes,
    };
  }

  factory ExpiringContractEntry.fromJson(Map<String, dynamic> json) {
    return ExpiringContractEntry(
      entryId: json['entryId'] as String,
      kind: ExtensionTargetKind.fromJson(json['kind'] as String),
      fullName: json['fullName'] as String,
      nationalityIso: (json['nationalityIso'] as String?) ?? 'POL',
      age: (json['age'] as num).toInt(),
      roleLabel: json['roleLabel'] as String,
      ratingOrLevel: (json['ratingOrLevel'] as num).toInt(),
      currentMonthlySalaryEur: (json['currentMonthlySalaryEur'] as num).toInt(),
      contractEndYear: (json['contractEndYear'] as num).toInt(),
      morale: (json['morale'] as num?)?.toDouble() ?? 75.0,
      loyalty: (json['loyalty'] as num?)?.toDouble() ?? 70.0,
      stance: NegotiationStance.fromJson(
        (json['stance'] as String?) ?? 'wantsRaise',
      ),
      status: ContractExtensionStatus.fromJson(
        (json['status'] as String?) ?? 'pendingReview',
      ),
      rivalOffers: (json['rivalOffers'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RivalWorldTourPreOffer.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      proposedMonthlySalaryEur:
          (json['proposedMonthlySalaryEur'] as num).toInt(),
      proposedYears: (json['proposedYears'] as num?)?.toInt() ?? 2,
      proposedSigningBonusEur:
          (json['proposedSigningBonusEur'] as num?)?.toInt() ?? 0,
      counterOfferRounds: (json['counterOfferRounds'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] as String?) ?? '',
    );
  }
}

/// Automatyczne powiadomienie o wstępnej ofercie złożonej przez inną ekipę WorldTour.
class RivalOfferAlert {
  final String alertId;
  final String entryId;
  final String targetName;
  final ExtensionTargetKind kind;
  final String rivalTeamName;
  final int rivalMonthlySalaryEur;
  final int currentMonthlySalaryEur;
  final double salaryDeltaPercent;
  final RivalOfferAlertSeverity severity;
  final String message;
  final bool isAcknowledged;

  const RivalOfferAlert({
    required this.alertId,
    required this.entryId,
    required this.targetName,
    required this.kind,
    required this.rivalTeamName,
    required this.rivalMonthlySalaryEur,
    required this.currentMonthlySalaryEur,
    required this.salaryDeltaPercent,
    required this.severity,
    required this.message,
    this.isAcknowledged = false,
  });

  RivalOfferAlert copyWith({bool? isAcknowledged}) {
    return RivalOfferAlert(
      alertId: alertId,
      entryId: entryId,
      targetName: targetName,
      kind: kind,
      rivalTeamName: rivalTeamName,
      rivalMonthlySalaryEur: rivalMonthlySalaryEur,
      currentMonthlySalaryEur: currentMonthlySalaryEur,
      salaryDeltaPercent: salaryDeltaPercent,
      severity: severity,
      message: message,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'entryId': entryId,
      'targetName': targetName,
      'kind': kind.toJson(),
      'rivalTeamName': rivalTeamName,
      'rivalMonthlySalaryEur': rivalMonthlySalaryEur,
      'currentMonthlySalaryEur': currentMonthlySalaryEur,
      'salaryDeltaPercent': salaryDeltaPercent,
      'severity': severity.toJson(),
      'message': message,
      'isAcknowledged': isAcknowledged,
    };
  }

  factory RivalOfferAlert.fromJson(Map<String, dynamic> json) {
    return RivalOfferAlert(
      alertId: json['alertId'] as String,
      entryId: json['entryId'] as String,
      targetName: json['targetName'] as String,
      kind: ExtensionTargetKind.fromJson(json['kind'] as String),
      rivalTeamName: json['rivalTeamName'] as String,
      rivalMonthlySalaryEur: (json['rivalMonthlySalaryEur'] as num).toInt(),
      currentMonthlySalaryEur: (json['currentMonthlySalaryEur'] as num).toInt(),
      salaryDeltaPercent: (json['salaryDeltaPercent'] as num).toDouble(),
      severity: RivalOfferAlertSeverity.fromJson(
        (json['severity'] as String?) ?? 'warning',
      ),
      message: json['message'] as String,
      isAcknowledged: (json['isAcknowledged'] as bool?) ?? false,
    );
  }
}

/// Wynik złożenia oferty przedłużenia kontraktu.
class ExtensionNegotiationOutcome {
  final bool valid;
  final bool accepted;
  final bool countered;
  final bool lostToRival;
  final String message;
  final ExpiringContractEntry updatedEntry;
  final int annualPayrollDeltaEur;
  final int signingBonusCostEur;

  const ExtensionNegotiationOutcome({
    required this.valid,
    required this.accepted,
    required this.countered,
    required this.lostToRival,
    required this.message,
    required this.updatedEntry,
    required this.annualPayrollDeltaEur,
    required this.signingBonusCostEur,
  });
}

/// Zbiorcze podsumowanie stanu wrześniowego okna przedłużeń kontraktów.
class SeptemberWindowSummary {
  final int expiringRidersCount;
  final int expiringStaffCount;
  final int totalExpiringCount;
  final int withRivalOffersCount;
  final int extendedCount;
  final int pendingCount;
  final int lostOrDeclinedCount;
  final int unacknowledgedAlertsCount;
  final int projectedAnnualPayrollDeltaEur;

  const SeptemberWindowSummary({
    required this.expiringRidersCount,
    required this.expiringStaffCount,
    required this.totalExpiringCount,
    required this.withRivalOffersCount,
    required this.extendedCount,
    required this.pendingCount,
    required this.lostOrDeclinedCount,
    required this.unacknowledgedAlertsCount,
    required this.projectedAnnualPayrollDeltaEur,
  });
}

/// Silnik logiki wrześniowego okna negocjacji przedłużeń kontraktów.
class EndOfSeasonContractExtensionWindow {
  const EndOfSeasonContractExtensionWindow();

  static const List<_RivalWorldTourClubSeed> _defaultWorldTourRivals = [
    _RivalWorldTourClubSeed('wt_uae', 'UAE Team Emirates XRG', 'ARE'),
    _RivalWorldTourClubSeed('wt_visma', 'Team Visma | Lease a Bike', 'NED'),
    _RivalWorldTourClubSeed('wt_ineos', 'INEOS Grenadiers', 'GBR'),
    _RivalWorldTourClubSeed('wt_soudal', 'Soudal Quick-Step', 'BEL'),
    _RivalWorldTourClubSeed('wt_bora', 'Red Bull - BORA - hansgrohe', 'GER'),
    _RivalWorldTourClubSeed('wt_lidl', 'Lidl - Trek', 'USA'),
    _RivalWorldTourClubSeed('wt_alpecin', 'Alpecin - Deceuninck', 'BEL'),
    _RivalWorldTourClubSeed('wt_ef', 'EF Education - EasyPost', 'USA'),
  ];

  /// Sprawdza, czy aktywne jest wrześniowe okno przedłużeń kontraktów.
  bool isSeptemberWindowOpen(DateTime currentDate) {
    return currentDate.month == DateTime.september;
  }

  /// Skanuje skład drużyny i sztab szkoleniowo-techniczny w poszukiwaniu umów
  /// wygasających 31 grudnia bieżącego roku oraz generuje wstępne oferty rywali WorldTour.
  List<ExpiringContractEntry> scanExpiringContracts({
    required int seasonYear,
    required List<Rider> riders,
    required List<StaffMember> staff,
    List<CyclingTeam> rivalTeams = const [],
    int? seed,
  }) {
    final rng = math.Random(seed ?? (seasonYear * 9137 + 42));
    final rivalPool = _buildRivalPool(rivalTeams);
    final entries = <ExpiringContractEntry>[];

    for (final rider in riders) {
      if (rider.contract.contractEndYear > seasonYear) continue;
      final rating = rider.overallRating;
      final rivalOffers = _generateRivalOffersForTarget(
        rng: rng,
        entryId: rider.id,
        ratingOrLevel: rating,
        currentMonthlySalaryEur: rider.contract.monthlySalaryEur,
        roleLabel: rider.specialization.displayName,
        loyalty: rider.contract.leaderLoyalty,
        seasonYear: seasonYear,
        rivalPool: rivalPool,
        isRider: true,
      );
      final stance = _determineStance(
        loyalty: rider.contract.leaderLoyalty,
        morale: rider.contract.morale,
        rivalOffers: rivalOffers,
      );
      final baseRecommended = _initialProposalSalary(
        currentMonthlySalaryEur: rider.contract.monthlySalaryEur,
        rivalOffers: rivalOffers,
        stance: stance,
      );

      entries.add(
        ExpiringContractEntry(
          entryId: rider.id,
          kind: ExtensionTargetKind.rider,
          fullName: rider.fullName,
          nationalityIso: rider.nationalityIso,
          age: rider.age,
          roleLabel: '${rider.contract.role.label} • ${rider.specialization.displayName}',
          ratingOrLevel: rating,
          currentMonthlySalaryEur: rider.contract.monthlySalaryEur,
          contractEndYear: rider.contract.contractEndYear,
          morale: rider.contract.morale,
          loyalty: rider.contract.leaderLoyalty,
          stance: stance,
          rivalOffers: rivalOffers,
          proposedMonthlySalaryEur: baseRecommended,
          proposedYears: rider.age >= 33 ? 1 : 2,
          proposedSigningBonusEur: (baseRecommended * 0.5).round(),
        ),
      );
    }

    for (final member in staff) {
      if (member.contractEndYear > seasonYear) continue;
      final level = member.experienceLevel;
      final rivalOffers = _generateRivalOffersForTarget(
        rng: rng,
        entryId: member.id,
        ratingOrLevel: level,
        currentMonthlySalaryEur: member.monthlySalaryEur,
        roleLabel: member.role.displayName,
        loyalty: member.morale,
        seasonYear: seasonYear,
        rivalPool: rivalPool,
        isRider: false,
      );
      final stance = _determineStance(
        loyalty: member.morale,
        morale: member.morale,
        rivalOffers: rivalOffers,
      );
      final baseRecommended = _initialProposalSalary(
        currentMonthlySalaryEur: member.monthlySalaryEur,
        rivalOffers: rivalOffers,
        stance: stance,
      );

      entries.add(
        ExpiringContractEntry(
          entryId: member.id,
          kind: ExtensionTargetKind.staff,
          fullName: member.fullName,
          nationalityIso: member.nationalityIso,
          age: member.age,
          roleLabel: member.role.displayName,
          ratingOrLevel: level,
          currentMonthlySalaryEur: member.monthlySalaryEur,
          contractEndYear: member.contractEndYear,
          morale: member.morale,
          loyalty: member.morale,
          stance: stance,
          rivalOffers: rivalOffers,
          proposedMonthlySalaryEur: baseRecommended,
          proposedYears: 2,
          proposedSigningBonusEur: (baseRecommended * 0.4).round(),
        ),
      );
    }

    entries.sort((a, b) {
      final aThreat = a.hasRivalOffers ? 1 : 0;
      final bThreat = b.hasRivalOffers ? 1 : 0;
      if (aThreat != bThreat) return bThreat.compareTo(aThreat);
      return b.ratingOrLevel.compareTo(a.ratingOrLevel);
    });

    return entries;
  }

  /// Buduje automatyczne powiadomienia o ofertach wstępnych od innych ekip WorldTour.
  List<RivalOfferAlert> buildAutomaticAlerts(
    List<ExpiringContractEntry> entries,
  ) {
    final alerts = <RivalOfferAlert>[];

    for (final entry in entries) {
      if (!entry.hasRivalOffers || entry.status.isTerminal) continue;
      final topOffer = entry.highestRivalOffer!;
      final baseSalary = math.max(1, entry.currentMonthlySalaryEur);
      final deltaPct =
          ((topOffer.offeredMonthlySalaryEur - baseSalary) / baseSalary) * 100.0;

      final severity = (entry.ratingOrLevel >= 82 || deltaPct >= 25.0)
          ? RivalOfferAlertSeverity.critical
          : (deltaPct >= 12.0
              ? RivalOfferAlertSeverity.warning
              : RivalOfferAlertSeverity.info);

      final kindLabel = entry.kind == ExtensionTargetKind.rider
          ? 'Kolarz'
          : 'Członek sztabu';

      alerts.add(
        RivalOfferAlert(
          alertId: 'alert_${entry.entryId}_${topOffer.teamId}',
          entryId: entry.entryId,
          targetName: entry.fullName,
          kind: entry.kind,
          rivalTeamName: topOffer.teamName,
          rivalMonthlySalaryEur: topOffer.offeredMonthlySalaryEur,
          currentMonthlySalaryEur: entry.currentMonthlySalaryEur,
          salaryDeltaPercent: deltaPct,
          severity: severity,
          message:
              '$kindLabel ${entry.fullName} otrzymał wstępną ofertę od ${topOffer.teamName} '
              '(${Formatters.formatCurrency(topOffer.offeredMonthlySalaryEur)}/mies., '
              '${topOffer.offeredYears} lat).',
        ),
      );
    }

    alerts.sort((a, b) {
      final sevDiff = b.severity.index.compareTo(a.severity.index);
      if (sevDiff != 0) return sevDiff;
      return b.salaryDeltaPercent.compareTo(a.salaryDeltaPercent);
    });

    return alerts;
  }

  /// Ocenia złożoną propozycję przedłużenia kontraktu i zwraca wynik negocjacji.
  ExtensionNegotiationOutcome evaluateExtensionProposal({
    required ExpiringContractEntry entry,
    required int offeredMonthlySalaryEur,
    required int offeredYears,
    required int signingBonusEur,
    required int availableBudgetEur,
  }) {
    if (entry.status.isTerminal) {
      return ExtensionNegotiationOutcome(
        valid: false,
        accepted: false,
        countered: false,
        lostToRival: entry.status == ContractExtensionStatus.signedByRival,
        message: 'Negocjacje dla ${entry.fullName} zostały już zakończone.',
        updatedEntry: entry,
        annualPayrollDeltaEur: 0,
        signingBonusCostEur: 0,
      );
    }

    if (offeredYears < 1 || offeredYears > 5 || offeredMonthlySalaryEur <= 0) {
      return ExtensionNegotiationOutcome(
        valid: false,
        accepted: false,
        countered: false,
        lostToRival: false,
        message: 'Nieprawidłowe parametry oferty (okres 1–5 lat, pensja > 0).',
        updatedEntry: entry,
        annualPayrollDeltaEur: 0,
        signingBonusCostEur: 0,
      );
    }

    final annualDelta =
        (offeredMonthlySalaryEur - entry.currentMonthlySalaryEur) * 12;
    final totalImmediateCommitment =
        signingBonusEur + math.max(0, annualDelta);

    if (totalImmediateCommitment > availableBudgetEur) {
      return ExtensionNegotiationOutcome(
        valid: false,
        accepted: false,
        countered: false,
        lostToRival: false,
        message:
            'Brak wystarczającego budżetu (${Formatters.formatCurrency(availableBudgetEur)}) na pokrycie premii i podwyżki.',
        updatedEntry: entry,
        annualPayrollDeltaEur: 0,
        signingBonusCostEur: 0,
      );
    }

    final targetSalary = entry.recommendedMatchSalaryEur;
    final effectiveMonthlyValue =
        offeredMonthlySalaryEur + (signingBonusEur / (offeredYears * 12)).round();
    final ratio = effectiveMonthlyValue / math.max(1, targetSalary);

    if (ratio >= 0.98) {
      final updated = entry.copyWith(
        status: ContractExtensionStatus.extended,
        currentMonthlySalaryEur: offeredMonthlySalaryEur,
        contractEndYear: entry.contractEndYear + offeredYears,
        proposedMonthlySalaryEur: offeredMonthlySalaryEur,
        proposedYears: offeredYears,
        proposedSigningBonusEur: signingBonusEur,
        morale: (entry.morale + 8.0).clamp(0.0, 100.0),
        notes:
            'Przedłużono o $offeredYears ${_yearsLabel(offeredYears)} za '
            '${Formatters.formatCurrency(offeredMonthlySalaryEur)}/mies.',
      );
      return ExtensionNegotiationOutcome(
        valid: true,
        accepted: true,
        countered: false,
        lostToRival: false,
        message:
            '${entry.fullName} zaakceptował przedłużenie umowy do 31 XII ${updated.contractEndYear}!',
        updatedEntry: updated,
        annualPayrollDeltaEur: annualDelta,
        signingBonusCostEur: signingBonusEur,
      );
    }

    if (ratio >= 0.84 && entry.counterOfferRounds < 2) {
      final counterSalary =
          (((targetSalary * 0.99) / 500).ceil() * 500).toInt();
      final updated = entry.copyWith(
        status: ContractExtensionStatus.negotiating,
        proposedMonthlySalaryEur: counterSalary,
        proposedYears: offeredYears,
        proposedSigningBonusEur: signingBonusEur,
        counterOfferRounds: entry.counterOfferRounds + 1,
        notes:
            'Agent oczekuje min. ${Formatters.formatCurrency(counterSalary)}/mies.',
      );
      return ExtensionNegotiationOutcome(
        valid: true,
        accepted: false,
        countered: true,
        lostToRival: false,
        message:
            '${entry.fullName} złożył kontrofertę: ${Formatters.formatCurrency(counterSalary)}/mies.',
        updatedEntry: updated,
        annualPayrollDeltaEur: 0,
        signingBonusCostEur: 0,
      );
    }

    final rival = entry.highestRivalOffer;
    if (rival != null && ratio < 0.78) {
      final updated = entry.copyWith(
        status: ContractExtensionStatus.signedByRival,
        notes: 'Podpisano przedwstępną umowę z ${rival.teamName}.',
      );
      return ExtensionNegotiationOutcome(
        valid: true,
        accepted: false,
        countered: false,
        lostToRival: true,
        message:
            '${entry.fullName} odrzucił niską ofertę i wybrał propozycję ${rival.teamName}.',
        updatedEntry: updated,
        annualPayrollDeltaEur: 0,
        signingBonusCostEur: 0,
      );
    }

    final updated = entry.copyWith(
      status: ContractExtensionStatus.negotiating,
      proposedMonthlySalaryEur: targetSalary,
      counterOfferRounds: entry.counterOfferRounds + 1,
      morale: (entry.morale - 4.0).clamp(0.0, 100.0),
      notes:
          'Oferta odrzucona. Wymagane ${Formatters.formatCurrency(targetSalary)}/mies.',
    );
    return ExtensionNegotiationOutcome(
      valid: true,
      accepted: false,
      countered: true,
      lostToRival: false,
      message:
          '${entry.fullName} nie przyjął propozycji — potrzebne wyższe wynagrodzenie.',
      updatedEntry: updated,
      annualPayrollDeltaEur: 0,
      signingBonusCostEur: 0,
    );
  }

  /// Wylicza podsumowanie liczbowe i finansowe całego okna wrześniowego.
  SeptemberWindowSummary computeSummary({
    required List<ExpiringContractEntry> entries,
    required List<RivalOfferAlert> alerts,
  }) {
    int ridersCount = 0;
    int staffCount = 0;
    int withRivals = 0;
    int extended = 0;
    int pending = 0;
    int lostOrDeclined = 0;
    int payrollDelta = 0;

    for (final e in entries) {
      if (e.kind == ExtensionTargetKind.rider) {
        ridersCount++;
      } else {
        staffCount++;
      }
      if (e.hasRivalOffers) withRivals++;
      if (e.status == ContractExtensionStatus.extended) {
        extended++;
        payrollDelta += (e.proposedMonthlySalaryEur - e.currentMonthlySalaryEur) * 12;
      } else if (e.status == ContractExtensionStatus.declinedToRenew ||
          e.status == ContractExtensionStatus.signedByRival) {
        lostOrDeclined++;
      } else {
        pending++;
      }
    }

    final unacknowledged = alerts.where((a) => !a.isAcknowledged).length;

    return SeptemberWindowSummary(
      expiringRidersCount: ridersCount,
      expiringStaffCount: staffCount,
      totalExpiringCount: entries.length,
      withRivalOffersCount: withRivals,
      extendedCount: extended,
      pendingCount: pending,
      lostOrDeclinedCount: lostOrDeclined,
      unacknowledgedAlertsCount: unacknowledged,
      projectedAnnualPayrollDeltaEur: payrollDelta,
    );
  }

  List<_RivalWorldTourClubSeed> _buildRivalPool(List<CyclingTeam> rivalTeams) {
    final wtTeams = rivalTeams
        .where((t) => t.division == TeamDivision.worldTour)
        .map((t) => _RivalWorldTourClubSeed(t.id, t.name, t.countryIso))
        .toList();
    return wtTeams.isNotEmpty ? wtTeams : _defaultWorldTourRivals;
  }

  List<RivalWorldTourPreOffer> _generateRivalOffersForTarget({
    required math.Random rng,
    required String entryId,
    required int ratingOrLevel,
    required int currentMonthlySalaryEur,
    required String roleLabel,
    required double loyalty,
    required int seasonYear,
    required List<_RivalWorldTourClubSeed> rivalPool,
    required bool isRider,
  }) {
    final baseInterestChance = isRider
        ? (ratingOrLevel >= 82
            ? 0.85
            : (ratingOrLevel >= 74 ? 0.55 : 0.25))
        : (ratingOrLevel >= 80
            ? 0.70
            : (ratingOrLevel >= 68 ? 0.40 : 0.15));

    if (rng.nextDouble() > baseInterestChance) {
      return const [];
    }

    final offerCount = (ratingOrLevel >= 84 && rng.nextDouble() < 0.45) ? 2 : 1;
    final shuffled = List<_RivalWorldTourClubSeed>.from(rivalPool)..shuffle(rng);
    final offers = <RivalWorldTourPreOffer>[];

    for (int i = 0; i < math.min(offerCount, shuffled.length); i++) {
      final club = shuffled[i];
      final premiumFactor = 1.08 + rng.nextDouble() * 0.27; // +8% .. +35%
      final rawSalary = (currentMonthlySalaryEur * premiumFactor).round();
      final roundedSalary = math.max(
        currentMonthlySalaryEur + 500,
        (rawSalary / 500).round() * 500,
      );
      final years = rng.nextBool() ? 2 : 3;
      final urgency = (65 + (ratingOrLevel - 70) + rng.nextInt(20))
          .clamp(35, 99);

      offers.add(
        RivalWorldTourPreOffer(
          offerId: 'offer_${entryId}_${club.id}',
          teamId: club.id,
          teamName: club.name,
          teamCountryIso: club.countryIso,
          offeredMonthlySalaryEur: roundedSalary,
          offeredYears: years,
          signingBonusEur: (roundedSalary * (0.4 + rng.nextDouble() * 0.6)).round(),
          offeredRoleLabel: roleLabel,
          urgencyScore: urgency,
          submittedDate: DateTime(seasonYear, 9, 1 + rng.nextInt(14)),
          isHeadlineThreat: ratingOrLevel >= 82 && loyalty < 80,
        ),
      );
    }

    offers.sort(
      (a, b) => b.offeredMonthlySalaryEur.compareTo(a.offeredMonthlySalaryEur),
    );
    return offers;
  }

  NegotiationStance _determineStance({
    required double loyalty,
    required double morale,
    required List<RivalWorldTourPreOffer> rivalOffers,
  }) {
    if (rivalOffers.isNotEmpty && loyalty < 68.0) {
      return NegotiationStance.temptedByRival;
    }
    if (rivalOffers.isNotEmpty) {
      return NegotiationStance.testingMarket;
    }
    if (loyalty >= 80.0 && morale >= 75.0) {
      return NegotiationStance.loyalStay;
    }
    return NegotiationStance.wantsRaise;
  }

  int _initialProposalSalary({
    required int currentMonthlySalaryEur,
    required List<RivalWorldTourPreOffer> rivalOffers,
    required NegotiationStance stance,
  }) {
    if (rivalOffers.isNotEmpty) {
      final top = rivalOffers.first.offeredMonthlySalaryEur;
      return math.max(currentMonthlySalaryEur, (top / 500).round() * 500);
    }
    final factor = stance == NegotiationStance.loyalStay ? 1.05 : 1.12;
    return (((currentMonthlySalaryEur * factor) / 500).round() * 500);
  }

  String _yearsLabel(int years) {
    if (years == 1) return 'rok';
    if (years >= 2 && years <= 4) return 'lata';
    return 'lat';
  }
}

class _RivalWorldTourClubSeed {
  final String id;
  final String name;
  final String countryIso;

  const _RivalWorldTourClubSeed(this.id, this.name, this.countryIso);
}

// =============================================================================
// RIVERPOD STATE & NOTIFIER
// =============================================================================

/// Stan okna negocjacji przedłużeń kontraktów we wrześniu.
class EndOfSeasonExtensionWindowState {
  final int seasonYear;
  final DateTime currentDate;
  final bool isWindowOpen;
  final List<ExpiringContractEntry> entries;
  final List<RivalOfferAlert> alerts;
  final String? selectedEntryId;
  final ExtensionTargetKind? filterKind;
  final bool onlyWithRivalOffers;
  final String searchQuery;
  final int availableBudgetEur;
  final String? lastOutcomeMessage;
  final bool lastOutcomeIsSuccess;

  const EndOfSeasonExtensionWindowState({
    required this.seasonYear,
    required this.currentDate,
    required this.isWindowOpen,
    this.entries = const [],
    this.alerts = const [],
    this.selectedEntryId,
    this.filterKind,
    this.onlyWithRivalOffers = false,
    this.searchQuery = '',
    this.availableBudgetEur = 1200000,
    this.lastOutcomeMessage,
    this.lastOutcomeIsSuccess = true,
  });

  factory EndOfSeasonExtensionWindowState.initial() {
    return EndOfSeasonExtensionWindowState(
      seasonYear: 2026,
      currentDate: DateTime(2026, 9, 10),
      isWindowOpen: true,
    );
  }

  ExpiringContractEntry? get selectedEntry {
    if (entries.isEmpty) return null;
    if (selectedEntryId == null) return entries.first;
    for (final e in entries) {
      if (e.entryId == selectedEntryId) return e;
    }
    return entries.first;
  }

  List<ExpiringContractEntry> get filteredEntries {
    final query = searchQuery.trim().toLowerCase();
    return entries.where((e) {
      if (filterKind != null && e.kind != filterKind) return false;
      if (onlyWithRivalOffers && !e.hasRivalOffers) return false;
      if (query.isNotEmpty) {
        final matchName = e.fullName.toLowerCase().contains(query);
        final matchRole = e.roleLabel.toLowerCase().contains(query);
        final matchRival = e.rivalOffers.any(
          (r) => r.teamName.toLowerCase().contains(query),
        );
        if (!matchName && !matchRole && !matchRival) return false;
      }
      return true;
    }).toList();
  }

  EndOfSeasonExtensionWindowState copyWith({
    int? seasonYear,
    DateTime? currentDate,
    bool? isWindowOpen,
    List<ExpiringContractEntry>? entries,
    List<RivalOfferAlert>? alerts,
    String? selectedEntryId,
    bool clearSelectedEntryId = false,
    ExtensionTargetKind? filterKind,
    bool clearFilterKind = false,
    bool? onlyWithRivalOffers,
    String? searchQuery,
    int? availableBudgetEur,
    String? lastOutcomeMessage,
    bool clearLastOutcomeMessage = false,
    bool? lastOutcomeIsSuccess,
  }) {
    return EndOfSeasonExtensionWindowState(
      seasonYear: seasonYear ?? this.seasonYear,
      currentDate: currentDate ?? this.currentDate,
      isWindowOpen: isWindowOpen ?? this.isWindowOpen,
      entries: entries ?? this.entries,
      alerts: alerts ?? this.alerts,
      selectedEntryId:
          clearSelectedEntryId ? null : (selectedEntryId ?? this.selectedEntryId),
      filterKind: clearFilterKind ? null : (filterKind ?? this.filterKind),
      onlyWithRivalOffers: onlyWithRivalOffers ?? this.onlyWithRivalOffers,
      searchQuery: searchQuery ?? this.searchQuery,
      availableBudgetEur: availableBudgetEur ?? this.availableBudgetEur,
      lastOutcomeMessage: clearLastOutcomeMessage
          ? null
          : (lastOutcomeMessage ?? this.lastOutcomeMessage),
      lastOutcomeIsSuccess: lastOutcomeIsSuccess ?? this.lastOutcomeIsSuccess,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonYear': seasonYear,
      'currentDate': currentDate.toIso8601String(),
      'isWindowOpen': isWindowOpen,
      'entries': entries.map((e) => e.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'selectedEntryId': selectedEntryId,
      'filterKind': filterKind?.toJson(),
      'onlyWithRivalOffers': onlyWithRivalOffers,
      'searchQuery': searchQuery,
      'availableBudgetEur': availableBudgetEur,
      'lastOutcomeMessage': lastOutcomeMessage,
      'lastOutcomeIsSuccess': lastOutcomeIsSuccess,
    };
  }

  factory EndOfSeasonExtensionWindowState.fromJson(Map<String, dynamic> json) {
    return EndOfSeasonExtensionWindowState(
      seasonYear: (json['seasonYear'] as num).toInt(),
      currentDate: DateTime.tryParse((json['currentDate'] as String?) ?? '') ??
          DateTime(2026, 9, 10),
      isWindowOpen: (json['isWindowOpen'] as bool?) ?? true,
      entries: (json['entries'] as List<dynamic>?)
              ?.map(
                (e) => ExpiringContractEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((a) => RivalOfferAlert.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedEntryId: json['selectedEntryId'] as String?,
      filterKind: json['filterKind'] != null
          ? ExtensionTargetKind.fromJson(json['filterKind'] as String)
          : null,
      onlyWithRivalOffers: (json['onlyWithRivalOffers'] as bool?) ?? false,
      searchQuery: (json['searchQuery'] as String?) ?? '',
      availableBudgetEur: (json['availableBudgetEur'] as num?)?.toInt() ?? 0,
      lastOutcomeMessage: json['lastOutcomeMessage'] as String?,
      lastOutcomeIsSuccess: (json['lastOutcomeIsSuccess'] as bool?) ?? true,
    );
  }
}

/// Kontroler stanu Riverpod dla wrześniowego okna przedłużeń kontraktów.
class EndOfSeasonExtensionWindowNotifier
    extends StateNotifier<EndOfSeasonExtensionWindowState> {
  final EndOfSeasonContractExtensionWindow _service;

  EndOfSeasonExtensionWindowNotifier({
    EndOfSeasonContractExtensionWindow? service,
    EndOfSeasonExtensionWindowState? initialState,
  })  : _service = service ?? const EndOfSeasonContractExtensionWindow(),
        super(initialState ?? EndOfSeasonExtensionWindowState.initial());

  void loadFromRoster({
    required int seasonYear,
    required DateTime currentDate,
    required List<Rider> riders,
    required List<StaffMember> staff,
    List<CyclingTeam> rivalTeams = const [],
    required int availableBudgetEur,
    int? seed,
    bool forceOpenWindow = false,
  }) {
    final entries = _service.scanExpiringContracts(
      seasonYear: seasonYear,
      riders: riders,
      staff: staff,
      rivalTeams: rivalTeams,
      seed: seed,
    );
    final alerts = _service.buildAutomaticAlerts(entries);
    state = EndOfSeasonExtensionWindowState(
      seasonYear: seasonYear,
      currentDate: currentDate,
      isWindowOpen: forceOpenWindow || _service.isSeptemberWindowOpen(currentDate),
      entries: entries,
      alerts: alerts,
      selectedEntryId: entries.isNotEmpty ? entries.first.entryId : null,
      availableBudgetEur: availableBudgetEur,
    );
  }

  void loadPrebuilt({
    required int seasonYear,
    required DateTime currentDate,
    required List<ExpiringContractEntry> entries,
    required int availableBudgetEur,
    bool forceOpenWindow = false,
  }) {
    final alerts = _service.buildAutomaticAlerts(entries);
    state = EndOfSeasonExtensionWindowState(
      seasonYear: seasonYear,
      currentDate: currentDate,
      isWindowOpen: forceOpenWindow || _service.isSeptemberWindowOpen(currentDate),
      entries: entries,
      alerts: alerts,
      selectedEntryId: entries.isNotEmpty ? entries.first.entryId : null,
      availableBudgetEur: availableBudgetEur,
    );
  }

  void selectEntry(String? entryId) {
    state = state.copyWith(
      selectedEntryId: entryId,
      clearLastOutcomeMessage: true,
    );
  }

  void setFilterKind(ExtensionTargetKind? kind) {
    if (kind == null) {
      state = state.copyWith(clearFilterKind: true);
    } else {
      state = state.copyWith(filterKind: kind);
    }
  }

  void toggleOnlyWithRivalOffers(bool value) {
    state = state.copyWith(onlyWithRivalOffers: value);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void acknowledgeAlert(String alertId) {
    final updatedAlerts = state.alerts
        .map((a) => a.alertId == alertId ? a.copyWith(isAcknowledged: true) : a)
        .toList();
    state = state.copyWith(alerts: updatedAlerts);
  }

  void acknowledgeAllAlerts() {
    final updatedAlerts =
        state.alerts.map((a) => a.copyWith(isAcknowledged: true)).toList();
    state = state.copyWith(alerts: updatedAlerts);
  }

  ExtensionNegotiationOutcome? submitExtensionOffer({
    required String entryId,
    required int monthlySalaryEur,
    required int years,
    required int signingBonusEur,
  }) {
    final idx = state.entries.indexWhere((e) => e.entryId == entryId);
    if (idx < 0) return null;

    final outcome = _service.evaluateExtensionProposal(
      entry: state.entries[idx],
      offeredMonthlySalaryEur: monthlySalaryEur,
      offeredYears: years,
      signingBonusEur: signingBonusEur,
      availableBudgetEur: state.availableBudgetEur,
    );

    final updatedEntries = List<ExpiringContractEntry>.from(state.entries);
    updatedEntries[idx] = outcome.updatedEntry;

    final updatedAlerts = outcome.updatedEntry.status.isTerminal
        ? state.alerts
            .map(
              (a) => a.entryId == entryId
                  ? a.copyWith(isAcknowledged: true)
                  : a,
            )
            .toList()
        : state.alerts;

    final int newBudget = outcome.accepted
        ? math.max<int>(
            0,
            state.availableBudgetEur -
                outcome.signingBonusCostEur -
                math.max<int>(0, outcome.annualPayrollDeltaEur),
          )
        : state.availableBudgetEur;

    state = state.copyWith(
      entries: updatedEntries,
      alerts: updatedAlerts,
      availableBudgetEur: newBudget,
      lastOutcomeMessage: outcome.message,
      lastOutcomeIsSuccess: outcome.accepted || outcome.countered,
    );

    return outcome;
  }

  ExtensionNegotiationOutcome? matchRivalOffer(String entryId) {
    final idx = state.entries.indexWhere((e) => e.entryId == entryId);
    if (idx < 0) return null;
    final entry = state.entries[idx];
    final topRival = entry.highestRivalOffer;
    final targetSalary = topRival != null
        ? topRival.offeredMonthlySalaryEur
        : entry.recommendedMatchSalaryEur;
    final years = topRival?.offeredYears ?? entry.proposedYears;
    final bonus = topRival?.signingBonusEur ?? entry.proposedSigningBonusEur;

    return submitExtensionOffer(
      entryId: entryId,
      monthlySalaryEur: targetSalary,
      years: years,
      signingBonusEur: bonus,
    );
  }

  void declineRenewal(String entryId) {
    final idx = state.entries.indexWhere((e) => e.entryId == entryId);
    if (idx < 0) return;
    final entry = state.entries[idx];
    if (entry.status.isTerminal) return;

    final updatedEntries = List<ExpiringContractEntry>.from(state.entries);
    updatedEntries[idx] = entry.copyWith(
      status: ContractExtensionStatus.declinedToRenew,
      notes: 'Zarząd zdecydował o nieprzedłużaniu umowy po 31 grudnia.',
    );

    final updatedAlerts = state.alerts
        .map((a) => a.entryId == entryId ? a.copyWith(isAcknowledged: true) : a)
        .toList();

    state = state.copyWith(
      entries: updatedEntries,
      alerts: updatedAlerts,
      lastOutcomeMessage:
          'Zrezygnowano z przedłużenia umowy dla ${entry.fullName}.',
      lastOutcomeIsSuccess: true,
    );
  }
}

final endOfSeasonExtensionWindowProvider = StateNotifierProvider<
    EndOfSeasonExtensionWindowNotifier, EndOfSeasonExtensionWindowState>(
  (ref) => EndOfSeasonExtensionWindowNotifier(),
);

// =============================================================================
// PRODUKCYJNY WIDOK UI: END OF SEASON CONTRACT EXTENSION WINDOW
// =============================================================================

/// Dedykowane okno negocjacji przedłużeń kontraktów we wrześniu.
class EndOfSeasonContractExtensionWindowPanel extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final VoidCallback? onClose;

  const EndOfSeasonContractExtensionWindowPanel({
    super.key,
    this.isReadOnly = false,
    this.onClose,
  });

  @override
  ConsumerState<EndOfSeasonContractExtensionWindowPanel> createState() =>
      _EndOfSeasonContractExtensionWindowPanelState();
}

class _EndOfSeasonContractExtensionWindowPanelState
    extends ConsumerState<EndOfSeasonContractExtensionWindowPanel> {
  final TextEditingController _searchController = TextEditingController();
  int? _draftSalary;
  int? _draftYears;
  int? _draftBonus;
  String? _draftForEntryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncDraft(ExpiringContractEntry? entry) {
    if (entry == null) return;
    if (_draftForEntryId != entry.entryId) {
      _draftForEntryId = entry.entryId;
      _draftSalary = entry.proposedMonthlySalaryEur;
      _draftYears = entry.proposedYears;
      _draftBonus = entry.proposedSigningBonusEur;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(endOfSeasonExtensionWindowProvider);
    final notifier = ref.read(endOfSeasonExtensionWindowProvider.notifier);
    const service = EndOfSeasonContractExtensionWindow();
    final summary = service.computeSummary(
      entries: state.entries,
      alerts: state.alerts,
    );
    final filtered = state.filteredEntries;
    final selected = state.selectedEntry;
    _syncDraft(selected);

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final isDesktop = constraints.maxWidth >= 1100;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, summary, isCompact),
                const SizedBox(height: 14),
                if (state.alerts.isNotEmpty) ...[
                  _buildRivalAlertsBanner(state, notifier, isCompact),
                  const SizedBox(height: 14),
                ],
                if (state.lastOutcomeMessage != null) ...[
                  _buildOutcomeToast(
                    state.lastOutcomeMessage!,
                    state.lastOutcomeIsSuccess,
                  ),
                  const SizedBox(height: 14),
                ],
                _buildFilterToolbar(state, notifier, isCompact),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  _buildEmptyState()
                else if (isDesktop || constraints.maxWidth >= 880)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildEntriesList(
                          filtered,
                          selected,
                          notifier,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: selected != null
                            ? _buildNegotiationDesk(
                                selected,
                                state,
                                notifier,
                                isCompact,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildEntriesList(filtered, selected, notifier),
                      if (selected != null) ...[
                        const SizedBox(height: 16),
                        _buildNegotiationDesk(
                          selected,
                          state,
                          notifier,
                          isCompact,
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    EndOfSeasonExtensionWindowState state,
    SeptemberWindowSummary summary,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
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
                      'Wrześniowe Okno Przedłużeń Kontraktów',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Umowy wygasające 31 grudnia ${state.seasonYear} • '
                      '${state.isWindowOpen ? "Okno negocjacyjne AKTYWNE" : "Podgląd poza wrześniem"}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onClose != null)
                _InteractiveIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Zamknij okno',
                  onTap: widget.onClose!,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiChip(
                label: 'Wygasające (31 XII)',
                value: '${summary.totalExpiringCount}',
                accent: AppColors.accentBlue,
              ),
              _KpiChip(
                label: 'Kolarze / Sztab',
                value:
                    '${summary.expiringRidersCount} / ${summary.expiringStaffCount}',
                accent: AppColors.textPrimary,
              ),
              _KpiChip(
                label: 'Oferty WorldTour',
                value: '${summary.withRivalOffersCount}',
                accent: summary.withRivalOffersCount > 0
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess,
              ),
              _KpiChip(
                label: 'Przedłużono',
                value: '${summary.extendedCount}',
                accent: AppColors.statusSuccess,
              ),
              _KpiChip(
                label: 'Budżet dostępny',
                value: Formatters.formatCurrency(state.availableBudgetEur),
                accent: AppColors.goldAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRivalAlertsBanner(
    EndOfSeasonExtensionWindowState state,
    EndOfSeasonExtensionWindowNotifier notifier,
    bool isCompact,
  ) {
    final unacked = state.alerts.where((a) => !a.isAcknowledged).toList();
    final visibleAlerts =
        (unacked.isNotEmpty ? unacked : state.alerts).take(3).toList();

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unacked.isNotEmpty
              ? AppColors.amberWarning.withValues(alpha: 0.65)
              : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: unacked.isNotEmpty
                    ? AppColors.amberWarning
                    : AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alerty Rynku WorldTour (${unacked.length} nowe / ${state.alerts.length} łącznie)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (unacked.isNotEmpty && !widget.isReadOnly)
                _InteractivePillButton(
                  label: 'Oznacz przeczytane',
                  onTap: notifier.acknowledgeAllAlerts,
                  accentColor: AppColors.amberWarning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...visibleAlerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _AlertRow(
                alert: alert,
                onSelectTarget: () {
                  notifier.selectEntry(alert.entryId);
                  if (!widget.isReadOnly) {
                    notifier.acknowledgeAlert(alert.alertId);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeToast(String message, bool isSuccess) {
    final color = isSuccess ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.warning_amber_rounded,
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
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar(
    EndOfSeasonExtensionWindowState state,
    EndOfSeasonExtensionWindowNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterChipButton(
            label: 'Wszyscy',
            selected: state.filterKind == null,
            onTap: () => notifier.setFilterKind(null),
          ),
          _FilterChipButton(
            label: 'Zawodnicy',
            selected: state.filterKind == ExtensionTargetKind.rider,
            onTap: () => notifier.setFilterKind(ExtensionTargetKind.rider),
          ),
          _FilterChipButton(
            label: 'Sztab',
            selected: state.filterKind == ExtensionTargetKind.staff,
            onTap: () => notifier.setFilterKind(ExtensionTargetKind.staff),
          ),
          _FilterChipButton(
            label: 'Z ofertą WorldTour',
            selected: state.onlyWithRivalOffers,
            accent: AppColors.amberWarning,
            onTap: () =>
                notifier.toggleOnlyWithRivalOffers(!state.onlyWithRivalOffers),
          ),
          SizedBox(
            width: isCompact ? double.infinity : 240,
            child: TextField(
              controller: _searchController,
              onChanged: notifier.setSearchQuery,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Szukaj nazwiska lub ekipy WT...',
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.goldAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 36,
            color: AppColors.statusSuccess,
          ),
          SizedBox(height: 10),
          Text(
            'Brak wygasających kontraktów spełniających kryteria',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Wszyscy zawodnicy i członkowie sztabu mają zabezpieczone umowy lub zmień filtry wyszukiwania.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(
    List<ExpiringContractEntry> entries,
    ExpiringContractEntry? selected,
    EndOfSeasonExtensionWindowNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpiringContractCard(
                entry: entry,
                isSelected: selected?.entryId == entry.entryId,
                onTap: () => notifier.selectEntry(entry.entryId),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildNegotiationDesk(
    ExpiringContractEntry entry,
    EndOfSeasonExtensionWindowState state,
    EndOfSeasonExtensionWindowNotifier notifier,
    bool isCompact,
  ) {
    final canAct = !widget.isReadOnly &&
        state.isWindowOpen &&
        !entry.status.isTerminal;

    final minSalary = math.max(2000, (entry.currentMonthlySalaryEur * 0.85).round());
    final maxSalary = math.max(
      minSalary + 5000,
      ((entry.highestRivalOffer?.offeredMonthlySalaryEur ??
                  entry.currentMonthlySalaryEur) *
              1.6)
          .round(),
    );
    final salaryValue = (_draftSalary ?? entry.proposedMonthlySalaryEur)
        .clamp(minSalary, maxSalary);
    final yearsValue = (_draftYears ?? entry.proposedYears).clamp(1, 5);
    final bonusValue = (_draftBonus ?? entry.proposedSigningBonusEur)
        .clamp(0, salaryValue * 3);

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
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
              _RatingBadge(
                value: entry.ratingOrLevel,
                isRider: entry.kind == ExtensionTargetKind.rider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.fullName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${entry.kind.label} • ${entry.roleLabel} • ${entry.age} lat',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: entry.status),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetricPill(
                label: 'Obecna pensja',
                value:
                    '${Formatters.formatCurrency(entry.currentMonthlySalaryEur)}/mies.',
              ),
              _MetricPill(
                label: 'Lojalność',
                value: '${entry.loyalty.round()}%',
              ),
              _MetricPill(
                label: 'Nastawienie',
                value: entry.stance.label,
              ),
            ],
          ),
          if (entry.hasRivalOffers) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.amberWarning.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.gavel_rounded,
                        size: 16,
                        color: AppColors.amberWarning,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Wstępne oferty konkurencji WorldTour',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amberWarning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...entry.rivalOffers.map(
                    (offer) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${offer.teamName} (${offer.teamCountryIso})',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${Formatters.formatCurrency(offer.offeredMonthlySalaryEur)}/m • ${offer.offeredYears} lat',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.amberWarning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Proponowana pensja miesięczna: ${Formatters.formatCurrency(salaryValue)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
          Slider(
            value: salaryValue.toDouble(),
            min: minSalary.toDouble(),
            max: maxSalary.toDouble(),
            divisions: math.max(1, ((maxSalary - minSalary) / 500).round()),
            activeColor: AppColors.goldAccent,
            inactiveColor: AppColors.cardBorder,
            onChanged: canAct
                ? (v) => setState(() {
                      _draftSalary = ((v / 500).round() * 500);
                    })
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Długość nowego kontraktu: $yearsValue lat (do 31 XII ${entry.contractEndYear + yearsValue})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 4, 5].map((y) {
              return _FilterChipButton(
                label: '$y ${_yearsLabel(y)}',
                selected: yearsValue == y,
                enabled: canAct,
                onTap: () => setState(() => _draftYears = y),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Premia za podpis: ${Formatters.formatCurrency(bonusValue)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
          Slider(
            value: bonusValue.toDouble(),
            min: 0,
            max: (salaryValue * 3).toDouble(),
            divisions: 12,
            activeColor: AppColors.accentBlue,
            inactiveColor: AppColors.cardBorder,
            onChanged: canAct
                ? (v) => setState(() {
                      _draftBonus = ((v / 500).round() * 500);
                    })
                : null,
          ),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.notes,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Złóż Ofertę Przedłużenia',
                icon: Icons.edit_document,
                enabled: canAct,
                backgroundColor: AppColors.primaryAccent,
                onPressed: () {
                  notifier.submitExtensionOffer(
                    entryId: entry.entryId,
                    monthlySalaryEur: salaryValue,
                    years: yearsValue,
                    signingBonusEur: bonusValue,
                  );
                },
              ),
              if (entry.hasRivalOffers)
                _ActionButton(
                  label: 'Wyrównaj Ofertę WorldTour',
                  icon: Icons.bolt_rounded,
                  enabled: canAct,
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: AppColors.background,
                  onPressed: () => notifier.matchRivalOffer(entry.entryId),
                ),
              _ActionButton(
                label: 'Rezygnuj z Przedłużenia',
                icon: Icons.cancel_outlined,
                enabled: canAct,
                outlined: true,
                backgroundColor: AppColors.crimsonAlert,
                onPressed: () => notifier.declineRenewal(entry.entryId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _yearsLabel(int y) {
    if (y == 1) return 'rok';
    if (y >= 2 && y <= 4) return 'lata';
    return 'lat';
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _KpiChip({
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
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatefulWidget {
  final RivalOfferAlert alert;
  final VoidCallback onSelectTarget;

  const _AlertRow({
    required this.alert,
    required this.onSelectTarget,
  });

  @override
  State<_AlertRow> createState() => _AlertRowState();
}

class _AlertRowState extends State<_AlertRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.alert.severity == RivalOfferAlertSeverity.critical
        ? AppColors.crimsonAlert
        : AppColors.amberWarning;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onSelectTarget,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surface.withValues(alpha: 0.9)
                : AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.alert.isAcknowledged
                  ? AppColors.cardBorder
                  : color.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.alert.isAcknowledged
                      ? AppColors.textSecondary
                      : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.alert.message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.alert.isAcknowledged
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiringContractCard extends StatefulWidget {
  final ExpiringContractEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExpiringContractCard({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ExpiringContractCard> createState() => _ExpiringContractCardState();
}

class _ExpiringContractCardState extends State<_ExpiringContractCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final topRival = entry.highestRivalOffer;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.75)
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (entry.hasRivalOffers && !entry.status.isTerminal
                      ? AppColors.amberWarning.withValues(alpha: 0.55)
                      : AppColors.cardBorder),
              width: widget.isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RatingBadge(
                    value: entry.ratingOrLevel,
                    isRider: entry.kind == ExtensionTargetKind.rider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.fullName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${entry.kind.label} • ${entry.roleLabel}',
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
                  const SizedBox(width: 8),
                  _StatusBadge(status: entry.status),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Obecnie: ${Formatters.formatCurrency(entry.currentMonthlySalaryEur)}/mies.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (topRival != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amberWarning.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.amberWarning.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '${topRival.teamName}: ${Formatters.formatCurrency(topRival.offeredMonthlySalaryEur)}/m',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.amberWarning,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final int value;
  final bool isRider;

  const _RatingBadge({required this.value, required this.isRider});

  @override
  Widget build(BuildContext context) {
    final color = value >= 82
        ? AppColors.goldAccent
        : (value >= 74 ? AppColors.accentBlue : AppColors.textSecondary);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
              height: 1.0,
            ),
          ),
          Text(
            isRider ? 'OVR' : 'LVL',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ContractExtensionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case ContractExtensionStatus.pendingReview:
        color = AppColors.accentBlue;
      case ContractExtensionStatus.negotiating:
        color = AppColors.amberWarning;
      case ContractExtensionStatus.extended:
        color = AppColors.statusSuccess;
      case ContractExtensionStatus.declinedToRenew:
      case ContractExtensionStatus.signedByRival:
        color = AppColors.crimsonAlert;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.accent = AppColors.goldAccent,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accent.withValues(alpha: 0.2)
                : (_hovered
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLight.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected ? widget.accent : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.enabled
                  ? (widget.selected ? widget.accent : AppColors.textPrimary)
                  : AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractivePillButton extends StatelessWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractivePillButton({
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accentColor.withValues(alpha: 0.45)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _InteractiveIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, color: AppColors.textSecondary, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool outlined;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.backgroundColor,
    required this.onPressed,
    this.outlined = false,
    this.foregroundColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: backgroundColor,
          disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.45),
          side: BorderSide(
            color: enabled
                ? backgroundColor.withValues(alpha: 0.65)
                : AppColors.cardBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: AppColors.surfaceLight,
        disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.45),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
