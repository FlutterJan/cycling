// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';

/// Dywizja zaprzyjaźnionej drużyny przyjmującej juniora na wypożyczenie.
enum LoanPartnerDivision {
  /// Drużyna drugiej dywizji UCI ProTeam (kalendarz ProSeries, wyścigi WT z dziką kartą).
  proTeam,

  /// Drużyna trzeciej dywizji UCI Continental (dużo dni wyścigowych, rola lidera).
  continental;

  String toJson() => name;

  static LoanPartnerDivision fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return LoanPartnerDivision.proTeam;
    }
    return LoanPartnerDivision.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LoanPartnerDivision.proTeam,
    );
  }

  String get label {
    switch (this) {
      case LoanPartnerDivision.proTeam:
        return 'UCI ProTeam';
      case LoanPartnerDivision.continental:
        return 'UCI Continental';
    }
  }

  /// Bazowy mnożnik tempa rozwoju statystyk w trakcie sezonu na wypożyczeniu.
  double get developmentMultiplier {
    switch (this) {
      case LoanPartnerDivision.proTeam:
        return 1.65;
      case LoanPartnerDivision.continental:
        return 1.45;
    }
  }

  /// Minimalna gwarantowana liczba dni wyścigowych w sezonie.
  int get baselineRaceDays {
    switch (this) {
      case LoanPartnerDivision.proTeam:
        return 54;
      case LoanPartnerDivision.continental:
        return 62;
    }
  }
}

/// Status kontraktu wypożyczenia młodego kolarza.
enum LoanContractStatus {
  proposed,
  active,
  recalledEarly,
  completed,
  cancelled;

  String toJson() => name;

  static LoanContractStatus fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return LoanContractStatus.active;
    }
    return LoanContractStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LoanContractStatus.active,
    );
  }

  String get label {
    switch (this) {
      case LoanContractStatus.proposed:
        return 'Propozycja';
      case LoanContractStatus.active:
        return 'Aktywne (1 sezon)';
      case LoanContractStatus.recalledEarly:
        return 'Ściągnięty awaryjnie';
      case LoanContractStatus.completed:
        return 'Zakończone';
      case LoanContractStatus.cancelled:
        return 'Anulowane';
    }
  }
}

/// Klauzula wcześniejszego ściągnięcia zawodnika z wypożyczenia.
enum LoanRecallClauseType {
  /// Natychmiastowe ściągnięcie w razie plagi kontuzji w kadrze WorldTour (0 EUR kary).
  emergencyInjuryRecall,

  /// Standardowe 14-dniowe wypowiedzenie z niewielką opłatą administracyjną.
  mutualNotice14Days,

  /// Sztywne wypożyczenie na pełny sezon bez możliwości wcześniejszego powrotu.
  lockedFullSeason;

  String toJson() => name;

  static LoanRecallClauseType fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return LoanRecallClauseType.emergencyInjuryRecall;
    }
    return LoanRecallClauseType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LoanRecallClauseType.emergencyInjuryRecall,
    );
  }

  String get label {
    switch (this) {
      case LoanRecallClauseType.emergencyInjuryRecall:
        return 'Natychmiastowy powrót (plaga kontuzji)';
      case LoanRecallClauseType.mutualNotice14Days:
        return 'Wypowiedzenie 14 dni (opłata 15 000 €)';
      case LoanRecallClauseType.lockedFullSeason:
        return 'Pełny sezon bez powrotu (+10% rozwoju)';
    }
  }

  String get shortBadge {
    switch (this) {
      case LoanRecallClauseType.emergencyInjuryRecall:
        return 'INSTANT RECALL';
      case LoanRecallClauseType.mutualNotice14Days:
        return '14D NOTICE';
      case LoanRecallClauseType.lockedFullSeason:
        return 'LOCKED 1Y';
    }
  }
}

/// Główny cel szkoleniowy podczas rocznego wypożyczenia.
enum LoanDevelopmentFocus {
  stageRacingGc,
  sprintAndLeadout,
  cobblesAndClassics,
  mountainDomestique,
  allRounderRaceIq;

  String toJson() => name;

  static LoanDevelopmentFocus fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return LoanDevelopmentFocus.allRounderRaceIq;
    }
    return LoanDevelopmentFocus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LoanDevelopmentFocus.allRounderRaceIq,
    );
  }

  String get label {
    switch (this) {
      case LoanDevelopmentFocus.stageRacingGc:
        return 'Etapówki i Jazda po GC';
      case LoanDevelopmentFocus.sprintAndLeadout:
        return 'Sprint i Rozprowadzanie';
      case LoanDevelopmentFocus.cobblesAndClassics:
        return 'Klasyki i Bruki';
      case LoanDevelopmentFocus.mountainDomestique:
        return 'Górski Pomocnik';
      case LoanDevelopmentFocus.allRounderRaceIq:
        return 'Wszechstronność & Race IQ';
    }
  }
}

/// Filtr widoku panelu wypożyczeń.
enum LoanPanelFilter {
  all,
  eligibleJuniors,
  activeLoans,
  partnerClubs;

  String get label {
    switch (this) {
      case LoanPanelFilter.all:
        return 'Wszystko';
      case LoanPanelFilter.eligibleJuniors:
        return 'Juniorzy WT';
      case LoanPanelFilter.activeLoans:
        return 'Na wypożyczeniu';
      case LoanPanelFilter.partnerClubs:
        return 'Kluby Partnerskie';
    }
  }
}

/// Profil zaprzyjaźnionej drużyny ProTeam lub Continental.
class PartnerClubProfile {
  final String id;
  final String name;
  final String shortCode;
  final String countryIso;
  final LoanPartnerDivision division;
  final int friendshipScore; // 0-100
  final int availableRosterSlots;
  final int guaranteedRaceDays;
  final int coachingQuality; // 1-100
  final LoanDevelopmentFocus calendarFocus;
  final int salarySharePercent; // 30-85%

  const PartnerClubProfile({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.countryIso,
    required this.division,
    required this.friendshipScore,
    required this.availableRosterSlots,
    required this.guaranteedRaceDays,
    required this.coachingQuality,
    required this.calendarFocus,
    required this.salarySharePercent,
  });

  bool get hasOpenSlot => availableRosterSlots > 0;

  PartnerClubProfile copyWith({
    String? id,
    String? name,
    String? shortCode,
    String? countryIso,
    LoanPartnerDivision? division,
    int? friendshipScore,
    int? availableRosterSlots,
    int? guaranteedRaceDays,
    int? coachingQuality,
    LoanDevelopmentFocus? calendarFocus,
    int? salarySharePercent,
  }) {
    return PartnerClubProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
      countryIso: countryIso ?? this.countryIso,
      division: division ?? this.division,
      friendshipScore: friendshipScore ?? this.friendshipScore,
      availableRosterSlots: availableRosterSlots ?? this.availableRosterSlots,
      guaranteedRaceDays: guaranteedRaceDays ?? this.guaranteedRaceDays,
      coachingQuality: coachingQuality ?? this.coachingQuality,
      calendarFocus: calendarFocus ?? this.calendarFocus,
      salarySharePercent: salarySharePercent ?? this.salarySharePercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortCode': shortCode,
      'countryIso': countryIso,
      'division': division.toJson(),
      'friendshipScore': friendshipScore,
      'availableRosterSlots': availableRosterSlots,
      'guaranteedRaceDays': guaranteedRaceDays,
      'coachingQuality': coachingQuality,
      'calendarFocus': calendarFocus.toJson(),
      'salarySharePercent': salarySharePercent,
    };
  }

  factory PartnerClubProfile.fromJson(Map<String, dynamic> json) {
    return PartnerClubProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      shortCode: json['shortCode'] as String? ?? 'PRT',
      countryIso: json['countryIso'] as String? ?? 'BE',
      division: LoanPartnerDivision.fromJson(json['division'] as String?),
      friendshipScore: (json['friendshipScore'] as num?)?.toInt() ?? 70,
      availableRosterSlots:
          (json['availableRosterSlots'] as num?)?.toInt() ?? 2,
      guaranteedRaceDays: (json['guaranteedRaceDays'] as num?)?.toInt() ?? 55,
      coachingQuality: (json['coachingQuality'] as num?)?.toInt() ?? 75,
      calendarFocus: LoanDevelopmentFocus.fromJson(
        json['calendarFocus'] as String?,
      ),
      salarySharePercent: (json['salarySharePercent'] as num?)?.toInt() ?? 60,
    );
  }
}

/// Kandydat z 28-osobowej kadry WorldTour kwalifikujący się do wypożyczenia.
class JuniorLoanCandidate {
  final String riderId;
  final String fullName;
  final int age;
  final String nationalityIso;
  final RiderSpecialization specialization;
  final double overallRating;
  final int potential;
  final int projectedWtRaceDays;
  final int currentRaceIq;
  final int currentFtpWatts;
  final int annualSalaryEur;
  final bool isInjured;
  final bool isCurrentlyOnLoan;

  const JuniorLoanCandidate({
    required this.riderId,
    required this.fullName,
    required this.age,
    required this.nationalityIso,
    required this.specialization,
    required this.overallRating,
    required this.potential,
    required this.projectedWtRaceDays,
    required this.currentRaceIq,
    required this.currentFtpWatts,
    required this.annualSalaryEur,
    this.isInjured = false,
    this.isCurrentlyOnLoan = false,
  });

  /// Junior marnuje się na ławce rezerwowych, gdy ma < 25 dni wyścigowych w WT.
  bool get isBenchStagnating => projectedWtRaceDays < 25;

  /// Kwalifikuje się do wypożyczenia rozwojowego (wiek <= 22, zdrowy, nie na wypożyczeniu).
  bool get isEligibleForLoan =>
      age <= 22 && !isInjured && !isCurrentlyOnLoan;

  int get developmentHeadroom => math.max(0, potential - overallRating.round());

  JuniorLoanCandidate copyWith({
    String? riderId,
    String? fullName,
    int? age,
    String? nationalityIso,
    RiderSpecialization? specialization,
    double? overallRating,
    int? potential,
    int? projectedWtRaceDays,
    int? currentRaceIq,
    int? currentFtpWatts,
    int? annualSalaryEur,
    bool? isInjured,
    bool? isCurrentlyOnLoan,
  }) {
    return JuniorLoanCandidate(
      riderId: riderId ?? this.riderId,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      nationalityIso: nationalityIso ?? this.nationalityIso,
      specialization: specialization ?? this.specialization,
      overallRating: overallRating ?? this.overallRating,
      potential: potential ?? this.potential,
      projectedWtRaceDays: projectedWtRaceDays ?? this.projectedWtRaceDays,
      currentRaceIq: currentRaceIq ?? this.currentRaceIq,
      currentFtpWatts: currentFtpWatts ?? this.currentFtpWatts,
      annualSalaryEur: annualSalaryEur ?? this.annualSalaryEur,
      isInjured: isInjured ?? this.isInjured,
      isCurrentlyOnLoan: isCurrentlyOnLoan ?? this.isCurrentlyOnLoan,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'fullName': fullName,
      'age': age,
      'nationalityIso': nationalityIso,
      'specialization': specialization.toJson(),
      'overallRating': overallRating,
      'potential': potential,
      'projectedWtRaceDays': projectedWtRaceDays,
      'currentRaceIq': currentRaceIq,
      'currentFtpWatts': currentFtpWatts,
      'annualSalaryEur': annualSalaryEur,
      'isInjured': isInjured,
      'isCurrentlyOnLoan': isCurrentlyOnLoan,
    };
  }

  factory JuniorLoanCandidate.fromJson(Map<String, dynamic> json) {
    return JuniorLoanCandidate(
      riderId: json['riderId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 19,
      nationalityIso: json['nationalityIso'] as String? ?? 'PL',
      specialization: RiderSpecialization.fromJson(
        json['specialization'] as String? ?? 'domestiqueEngine',
      ),
      overallRating: (json['overallRating'] as num?)?.toDouble() ?? 68.0,
      potential: (json['potential'] as num?)?.toInt() ?? 86,
      projectedWtRaceDays: (json['projectedWtRaceDays'] as num?)?.toInt() ?? 12,
      currentRaceIq: (json['currentRaceIq'] as num?)?.toInt() ?? 64,
      currentFtpWatts: (json['currentFtpWatts'] as num?)?.toInt() ?? 385,
      annualSalaryEur: (json['annualSalaryEur'] as num?)?.toInt() ?? 55000,
      isInjured: json['isInjured'] as bool? ?? false,
      isCurrentlyOnLoan: json['isCurrentlyOnLoan'] as bool? ?? false,
    );
  }
}

/// Aktywna lub historyczna umowa wypożyczenia juniora na 1 sezon.
class JuniorLoanAgreement {
  final String loanId;
  final String riderId;
  final String riderName;
  final int riderAge;
  final String partnerClubId;
  final String partnerClubName;
  final LoanPartnerDivision partnerDivision;
  final int seasonYear;
  final int elapsedSeasonDays;
  final int targetSeasonDays;
  final LoanRecallClauseType recallClause;
  final LoanDevelopmentFocus developmentFocus;
  final LoanContractStatus status;
  final int salaryCoveredByPartnerPercent;
  final int guaranteedRaceDays;
  final int accumulatedRaceDays;
  final double accumulatedOvrGain;
  final int accumulatedRaceIqGain;
  final int accumulatedFtpGainWatts;
  final int recallFeeEur;
  final String? recalledReason;

  const JuniorLoanAgreement({
    required this.loanId,
    required this.riderId,
    required this.riderName,
    required this.riderAge,
    required this.partnerClubId,
    required this.partnerClubName,
    required this.partnerDivision,
    required this.seasonYear,
    this.elapsedSeasonDays = 0,
    this.targetSeasonDays = 240,
    required this.recallClause,
    required this.developmentFocus,
    required this.status,
    required this.salaryCoveredByPartnerPercent,
    required this.guaranteedRaceDays,
    this.accumulatedRaceDays = 0,
    this.accumulatedOvrGain = 0.0,
    this.accumulatedRaceIqGain = 0,
    this.accumulatedFtpGainWatts = 0,
    this.recallFeeEur = 0,
    this.recalledReason,
  });

  double get progressRatio {
    if (targetSeasonDays <= 0) return 1.0;
    return (elapsedSeasonDays / targetSeasonDays).clamp(0.0, 1.0);
  }

  bool get canInstantRecall =>
      status == LoanContractStatus.active &&
      recallClause != LoanRecallClauseType.lockedFullSeason;

  int get remainingProjectedRaceDays =>
      math.max(0, guaranteedRaceDays - accumulatedRaceDays);

  JuniorLoanAgreement copyWith({
    String? loanId,
    String? riderId,
    String? riderName,
    int? riderAge,
    String? partnerClubId,
    String? partnerClubName,
    LoanPartnerDivision? partnerDivision,
    int? seasonYear,
    int? elapsedSeasonDays,
    int? targetSeasonDays,
    LoanRecallClauseType? recallClause,
    LoanDevelopmentFocus? developmentFocus,
    LoanContractStatus? status,
    int? salaryCoveredByPartnerPercent,
    int? guaranteedRaceDays,
    int? accumulatedRaceDays,
    double? accumulatedOvrGain,
    int? accumulatedRaceIqGain,
    int? accumulatedFtpGainWatts,
    int? recallFeeEur,
    String? recalledReason,
  }) {
    return JuniorLoanAgreement(
      loanId: loanId ?? this.loanId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      riderAge: riderAge ?? this.riderAge,
      partnerClubId: partnerClubId ?? this.partnerClubId,
      partnerClubName: partnerClubName ?? this.partnerClubName,
      partnerDivision: partnerDivision ?? this.partnerDivision,
      seasonYear: seasonYear ?? this.seasonYear,
      elapsedSeasonDays: elapsedSeasonDays ?? this.elapsedSeasonDays,
      targetSeasonDays: targetSeasonDays ?? this.targetSeasonDays,
      recallClause: recallClause ?? this.recallClause,
      developmentFocus: developmentFocus ?? this.developmentFocus,
      status: status ?? this.status,
      salaryCoveredByPartnerPercent:
          salaryCoveredByPartnerPercent ?? this.salaryCoveredByPartnerPercent,
      guaranteedRaceDays: guaranteedRaceDays ?? this.guaranteedRaceDays,
      accumulatedRaceDays: accumulatedRaceDays ?? this.accumulatedRaceDays,
      accumulatedOvrGain: accumulatedOvrGain ?? this.accumulatedOvrGain,
      accumulatedRaceIqGain:
          accumulatedRaceIqGain ?? this.accumulatedRaceIqGain,
      accumulatedFtpGainWatts:
          accumulatedFtpGainWatts ?? this.accumulatedFtpGainWatts,
      recallFeeEur: recallFeeEur ?? this.recallFeeEur,
      recalledReason: recalledReason ?? this.recalledReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'riderId': riderId,
      'riderName': riderName,
      'riderAge': riderAge,
      'partnerClubId': partnerClubId,
      'partnerClubName': partnerClubName,
      'partnerDivision': partnerDivision.toJson(),
      'seasonYear': seasonYear,
      'elapsedSeasonDays': elapsedSeasonDays,
      'targetSeasonDays': targetSeasonDays,
      'recallClause': recallClause.toJson(),
      'developmentFocus': developmentFocus.toJson(),
      'status': status.toJson(),
      'salaryCoveredByPartnerPercent': salaryCoveredByPartnerPercent,
      'guaranteedRaceDays': guaranteedRaceDays,
      'accumulatedRaceDays': accumulatedRaceDays,
      'accumulatedOvrGain': accumulatedOvrGain,
      'accumulatedRaceIqGain': accumulatedRaceIqGain,
      'accumulatedFtpGainWatts': accumulatedFtpGainWatts,
      'recallFeeEur': recallFeeEur,
      'recalledReason': recalledReason,
    };
  }

  factory JuniorLoanAgreement.fromJson(Map<String, dynamic> json) {
    return JuniorLoanAgreement(
      loanId: json['loanId'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      riderAge: (json['riderAge'] as num?)?.toInt() ?? 19,
      partnerClubId: json['partnerClubId'] as String? ?? '',
      partnerClubName: json['partnerClubName'] as String? ?? '',
      partnerDivision: LoanPartnerDivision.fromJson(
        json['partnerDivision'] as String?,
      ),
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      elapsedSeasonDays: (json['elapsedSeasonDays'] as num?)?.toInt() ?? 0,
      targetSeasonDays: (json['targetSeasonDays'] as num?)?.toInt() ?? 240,
      recallClause: LoanRecallClauseType.fromJson(
        json['recallClause'] as String?,
      ),
      developmentFocus: LoanDevelopmentFocus.fromJson(
        json['developmentFocus'] as String?,
      ),
      status: LoanContractStatus.fromJson(json['status'] as String?),
      salaryCoveredByPartnerPercent:
          (json['salaryCoveredByPartnerPercent'] as num?)?.toInt() ?? 60,
      guaranteedRaceDays: (json['guaranteedRaceDays'] as num?)?.toInt() ?? 56,
      accumulatedRaceDays: (json['accumulatedRaceDays'] as num?)?.toInt() ?? 0,
      accumulatedOvrGain:
          (json['accumulatedOvrGain'] as num?)?.toDouble() ?? 0.0,
      accumulatedRaceIqGain:
          (json['accumulatedRaceIqGain'] as num?)?.toInt() ?? 0,
      accumulatedFtpGainWatts:
          (json['accumulatedFtpGainWatts'] as num?)?.toInt() ?? 0,
      recallFeeEur: (json['recallFeeEur'] as num?)?.toInt() ?? 0,
      recalledReason: json['recalledReason'] as String?,
    );
  }
}

/// Porównanie prognozowanego rozwoju juniora: ławka rezerwowych WT vs wypożyczenie.
class LoanProgressionComparison {
  final int benchProjectedRaceDays;
  final int loanProjectedRaceDays;
  final double benchProjectedOvrGain;
  final double loanProjectedOvrGain;
  final int benchProjectedRaceIqGain;
  final int loanProjectedRaceIqGain;
  final int benchProjectedFtpGain;
  final int loanProjectedFtpGain;
  final int salarySavedEur;
  final double netDevelopmentAdvantagePercent;

  const LoanProgressionComparison({
    required this.benchProjectedRaceDays,
    required this.loanProjectedRaceDays,
    required this.benchProjectedOvrGain,
    required this.loanProjectedOvrGain,
    required this.benchProjectedRaceIqGain,
    required this.loanProjectedRaceIqGain,
    required this.benchProjectedFtpGain,
    required this.loanProjectedFtpGain,
    required this.salarySavedEur,
    required this.netDevelopmentAdvantagePercent,
  });
}

/// Audyt kadry WorldTour pod kątem tłoku na liście startowej i plagi kontuzji.
class JuniorLoanRosterAudit {
  final int wtRosterSize;
  final int maxWtRosterLimit;
  final int injuredWtRidersCount;
  final int healthyAvailableWtRiders;
  final int activeLoansCount;
  final int benchStagnatingJuniorsCount;
  final bool isInjuryPlagueActive;
  final String recommendedAction;

  const JuniorLoanRosterAudit({
    required this.wtRosterSize,
    this.maxWtRosterLimit = 28,
    required this.injuredWtRidersCount,
    required this.healthyAvailableWtRiders,
    required this.activeLoansCount,
    required this.benchStagnatingJuniorsCount,
    required this.isInjuryPlagueActive,
    required this.recommendedAction,
  });
}

/// Wynik operacji na systemie wypożyczeń.
class LoanOperationResult {
  final bool success;
  final String message;
  final JuniorLoanAgreement? agreement;
  final JuniorLoanCandidate? updatedCandidate;
  final int financialDeltaEur;

  const LoanOperationResult({
    required this.success,
    required this.message,
    this.agreement,
    this.updatedCandidate,
    this.financialDeltaEur = 0,
  });
}

/// Serwis zarządzający wypożyczaniem młodych talentów do zaprzyjaźnionych
/// drużyn UCI ProTeam oraz UCI Continental z opcją natychmiastowego ściągnięcia.
class JuniorDevelopmentLoanSystemService {
  const JuniorDevelopmentLoanSystemService();

  static const int worldTourMaxRosterSize = 28;
  static const int injuryPlagueThresholdCount = 4;
  static const int minimumHealthyWtThreshold = 23;

  /// Domyślna lista zaprzyjaźnionych drużyn partnerskich ProTeam i Continental.
  List<PartnerClubProfile> createDefaultPartnerClubs() {
    return const [
      PartnerClubProfile(
        id: 'partner_euskadi_pt',
        name: 'Euskadi Taldea ProTeam',
        shortCode: 'EUS',
        countryIso: 'ES',
        division: LoanPartnerDivision.proTeam,
        friendshipScore: 88,
        availableRosterSlots: 3,
        guaranteedRaceDays: 58,
        coachingQuality: 82,
        calendarFocus: LoanDevelopmentFocus.stageRacingGc,
        salarySharePercent: 65,
      ),
      PartnerClubProfile(
        id: 'partner_vlaanderen_pt',
        name: 'Vlaanderen Baloise Pro',
        shortCode: 'VLA',
        countryIso: 'BE',
        division: LoanPartnerDivision.proTeam,
        friendshipScore: 84,
        availableRosterSlots: 2,
        guaranteedRaceDays: 60,
        coachingQuality: 85,
        calendarFocus: LoanDevelopmentFocus.cobblesAndClassics,
        salarySharePercent: 70,
      ),
      PartnerClubProfile(
        id: 'partner_polonia_conti',
        name: 'Voster Polonia Development',
        shortCode: 'VPD',
        countryIso: 'PL',
        division: LoanPartnerDivision.continental,
        friendshipScore: 94,
        availableRosterSlots: 4,
        guaranteedRaceDays: 66,
        coachingQuality: 74,
        calendarFocus: LoanDevelopmentFocus.allRounderRaceIq,
        salarySharePercent: 55,
      ),
      PartnerClubProfile(
        id: 'partner_dolomiti_pt',
        name: 'Dolomiti Bardiani ProTeam',
        shortCode: 'DOL',
        countryIso: 'IT',
        division: LoanPartnerDivision.proTeam,
        friendshipScore: 79,
        availableRosterSlots: 2,
        guaranteedRaceDays: 55,
        coachingQuality: 80,
        calendarFocus: LoanDevelopmentFocus.mountainDomestique,
        salarySharePercent: 60,
      ),
      PartnerClubProfile(
        id: 'partner_bretagne_conti',
        name: 'Bretagne Armorique U23/CT',
        shortCode: 'BRE',
        countryIso: 'FR',
        division: LoanPartnerDivision.continental,
        friendshipScore: 82,
        availableRosterSlots: 3,
        guaranteedRaceDays: 64,
        coachingQuality: 76,
        calendarFocus: LoanDevelopmentFocus.sprintAndLeadout,
        salarySharePercent: 50,
      ),
    ];
  }

  /// Analizuje 28-osobową kadrę WorldTour, wykrywa brak miejsc startowych dla
  /// juniorów oraz ewentualną plagę kontuzji wymagającą ściągnięcia z wypożyczenia.
  JuniorLoanRosterAudit auditWorldTourRoster({
    required int wtRosterSize,
    required int injuredCount,
    required List<JuniorLoanCandidate> juniors,
    required List<JuniorLoanAgreement> agreements,
  }) {
    final safeRoster = wtRosterSize.clamp(0, 40);
    final safeInjured = injuredCount.clamp(0, safeRoster);
    final activeLoans = agreements
        .where((a) => a.status == LoanContractStatus.active)
        .toList();
    final healthyAvailable =
        math.max(0, safeRoster - safeInjured - activeLoans.length);
    final benchStagnating = juniors
        .where((j) => !j.isCurrentlyOnLoan && j.isBenchStagnating)
        .length;

    final injuryPlague = safeInjured >= injuryPlagueThresholdCount ||
        healthyAvailable < minimumHealthyWtThreshold;

    final String recommendation;
    if (injuryPlague && activeLoans.any((a) => a.canInstantRecall)) {
      recommendation =
          'ALERT KONTUZJI ($safeInjured kontuzjowanych): Natychmiast ściągnij wypożyczonego juniora, aby uzupełnić składy startowe WT.';
    } else if (benchStagnating > 0 && safeRoster >= worldTourMaxRosterSize) {
      recommendation =
          'Kadra 28/28 przepełniona: $benchStagnating juniorów traci formę na ławce. Wypożycz ich na 1 sezon do ProTeam.';
    } else if (activeLoans.isNotEmpty) {
      recommendation =
          '${activeLoans.length} talent(y) zbierają cenne kilometry wyścigowe na wypożyczeniu.';
    } else {
      recommendation =
          'Kadra zbalansowana. Monitoruj liczbę dni wyścigowych juniorów.';
    }

    return JuniorLoanRosterAudit(
      wtRosterSize: safeRoster,
      maxWtRosterLimit: worldTourMaxRosterSize,
      injuredWtRidersCount: safeInjured,
      healthyAvailableWtRiders: healthyAvailable,
      activeLoansCount: activeLoans.length,
      benchStagnatingJuniorsCount: benchStagnating,
      isInjuryPlagueActive: injuryPlague,
      recommendedAction: recommendation,
    );
  }

  /// Wylicza prognozę rozwoju: ławka rezerwowych w WorldTour vs 1-sezonowe wypożyczenie.
  LoanProgressionComparison compareLoanVsBench({
    required JuniorLoanCandidate candidate,
    required PartnerClubProfile partner,
    required LoanDevelopmentFocus focus,
    LoanRecallClauseType recallClause =
        LoanRecallClauseType.emergencyInjuryRecall,
  }) {
    final headroomFactor =
        (candidate.developmentHeadroom / 18.0).clamp(0.45, 1.35);
    final ageBonus = candidate.age <= 19
        ? 1.20
        : candidate.age == 20
            ? 1.10
            : 1.0;

    // Na ławce rezerwowych w 28-osobowym składzie WT rozwój jest mocno ograniczony.
    final benchDays = candidate.projectedWtRaceDays.clamp(0, 85);
    final benchOvrGain = double.parse(
      ((0.35 + (benchDays / 45.0) * 0.55) * headroomFactor).clamp(0.2, 1.4).toStringAsFixed(2),
    );
    final benchIqGain = math.max(1, (benchDays / 10.0).round());
    final benchFtpGain = math.max(2, (benchDays * 0.25).round());

    // Na wypożyczeniu w zaprzyjaźnionym ProTeam / Continental kolarz jedzie regularnie.
    final focusAlignmentBonus = partner.calendarFocus == focus ? 1.15 : 1.0;
    final lockedBonus =
        recallClause == LoanRecallClauseType.lockedFullSeason ? 1.10 : 1.0;
    final coachingFactor = 0.8 + (partner.coachingQuality / 100.0) * 0.35;

    final loanDays = partner.guaranteedRaceDays;
    final loanOvrGain = double.parse(
      (1.45 *
              partner.division.developmentMultiplier *
              headroomFactor *
              ageBonus *
              focusAlignmentBonus *
              lockedBonus *
              coachingFactor)
          .clamp(1.2, 5.5)
          .toStringAsFixed(2),
    );
    final loanIqGain = math.max(
      3,
      ((loanDays / 9.0) * focusAlignmentBonus).round(),
    );
    final loanFtpGain = math.max(
      6,
      ((loanDays * 0.22) * coachingFactor * ageBonus).round(),
    );

    final salarySaved =
        ((candidate.annualSalaryEur * partner.salarySharePercent) / 100.0)
            .round();
    final netAdvantagePercent = benchOvrGain > 0
        ? double.parse(
            (((loanOvrGain - benchOvrGain) / benchOvrGain) * 100.0)
                .toStringAsFixed(1),
          )
        : 100.0;

    return LoanProgressionComparison(
      benchProjectedRaceDays: benchDays,
      loanProjectedRaceDays: loanDays,
      benchProjectedOvrGain: benchOvrGain,
      loanProjectedOvrGain: loanOvrGain,
      benchProjectedRaceIqGain: benchIqGain,
      loanProjectedRaceIqGain: loanIqGain,
      benchProjectedFtpGain: benchFtpGain,
      loanProjectedFtpGain: loanFtpGain,
      salarySavedEur: salarySaved,
      netDevelopmentAdvantagePercent: netAdvantagePercent,
    );
  }

  /// Wysyła młodego kolarza na 1-sezonowe wypożyczenie do wybranego klubu partnerskiego.
  LoanOperationResult createLoanAgreement({
    required JuniorLoanCandidate candidate,
    required PartnerClubProfile partner,
    required LoanDevelopmentFocus focus,
    required LoanRecallClauseType recallClause,
    required int seasonYear,
  }) {
    if (candidate.isCurrentlyOnLoan) {
      return LoanOperationResult(
        success: false,
        message: '${candidate.fullName} jest już na aktywnym wypożyczeniu.',
      );
    }
    if (candidate.isInjured) {
      return LoanOperationResult(
        success: false,
        message:
            '${candidate.fullName} leczy kontuzję i nie przejdzie testów medycznych przed wypożyczeniem.',
      );
    }
    if (candidate.age > 22) {
      return LoanOperationResult(
        success: false,
        message:
            '${candidate.fullName} ma ${candidate.age} lat — system wypożyczeń rozwojowych obejmuje talenty do 22. roku życia.',
      );
    }
    if (!partner.hasOpenSlot) {
      return LoanOperationResult(
        success: false,
        message:
            '${partner.name} nie ma obecnie wolnych miejsc w kadrze na wypożyczenie.',
      );
    }

    final agreement = JuniorLoanAgreement(
      loanId: 'loan_${candidate.riderId}_${partner.id}_$seasonYear',
      riderId: candidate.riderId,
      riderName: candidate.fullName,
      riderAge: candidate.age,
      partnerClubId: partner.id,
      partnerClubName: partner.name,
      partnerDivision: partner.division,
      seasonYear: seasonYear,
      elapsedSeasonDays: 0,
      targetSeasonDays: 240,
      recallClause: recallClause,
      developmentFocus: focus,
      status: LoanContractStatus.active,
      salaryCoveredByPartnerPercent: partner.salarySharePercent,
      guaranteedRaceDays: partner.guaranteedRaceDays,
    );

    final updatedCandidate = candidate.copyWith(isCurrentlyOnLoan: true);
    final savedSalary =
        ((candidate.annualSalaryEur * partner.salarySharePercent) / 100.0)
            .round();

    return LoanOperationResult(
      success: true,
      message:
          'Wypożyczono ${candidate.fullName} (${candidate.age} l.) do ${partner.name} (${partner.division.label}) na 1 sezon.',
      agreement: agreement,
      updatedCandidate: updatedCandidate,
      financialDeltaEur: savedSalary,
    );
  }

  /// Symuluje upływ dni sezonu na wypożyczeniu (np. 30 dni) i nalicza progres statystyk.
  LoanOperationResult simulateLoanProgressTick({
    required JuniorLoanAgreement agreement,
    required JuniorLoanCandidate candidate,
    required PartnerClubProfile partner,
    int daysElapsed = 30,
  }) {
    if (agreement.status != LoanContractStatus.active) {
      return LoanOperationResult(
        success: false,
        message: 'Wypożyczenie ${agreement.riderName} nie jest aktywne.',
        agreement: agreement,
        updatedCandidate: candidate,
      );
    }

    final safeDays = daysElapsed.clamp(1, 240);
    final newElapsed =
        (agreement.elapsedSeasonDays + safeDays).clamp(0, agreement.targetSeasonDays);
    final stepFraction = safeDays / agreement.targetSeasonDays;

    final comparison = compareLoanVsBench(
      candidate: candidate,
      partner: partner,
      focus: agreement.developmentFocus,
      recallClause: agreement.recallClause,
    );

    final addedRaceDays = math.max(
      1,
      (comparison.loanProjectedRaceDays * stepFraction).round(),
    );
    final addedOvr = double.parse(
      (comparison.loanProjectedOvrGain * stepFraction).toStringAsFixed(2),
    );
    final addedIq = math.max(
      0,
      (comparison.loanProjectedRaceIqGain * stepFraction).round(),
    );
    final addedFtp = math.max(
      1,
      (comparison.loanProjectedFtpGain * stepFraction).round(),
    );

    final isFinished = newElapsed >= agreement.targetSeasonDays;
    final nextStatus =
        isFinished ? LoanContractStatus.completed : LoanContractStatus.active;

    final updatedAgreement = agreement.copyWith(
      elapsedSeasonDays: newElapsed,
      status: nextStatus,
      accumulatedRaceDays: math.min(
        agreement.guaranteedRaceDays + 6,
        agreement.accumulatedRaceDays + addedRaceDays,
      ),
      accumulatedOvrGain: double.parse(
        (agreement.accumulatedOvrGain + addedOvr).toStringAsFixed(2),
      ),
      accumulatedRaceIqGain: agreement.accumulatedRaceIqGain + addedIq,
      accumulatedFtpGainWatts: agreement.accumulatedFtpGainWatts + addedFtp,
    );

    final updatedCandidate = candidate.copyWith(
      overallRating: double.parse(
        (candidate.overallRating + addedOvr)
            .clamp(40.0, candidate.potential.toDouble())
            .toStringAsFixed(2),
      ),
      currentRaceIq: (candidate.currentRaceIq + addedIq).clamp(1, 99),
      currentFtpWatts: candidate.currentFtpWatts + addedFtp,
      isCurrentlyOnLoan: !isFinished,
    );

    return LoanOperationResult(
      success: true,
      message: isFinished
          ? '${candidate.fullName} ukończył 1-sezonowe wypożyczenie (+${updatedAgreement.accumulatedOvrGain.toStringAsFixed(1)} OVR, ${updatedAgreement.accumulatedRaceDays} dni wyścigowych).'
          : '${candidate.fullName} zaliczył +$addedRaceDays dni wyścigowych w ${partner.shortCode} (+${addedOvr.toStringAsFixed(2)} OVR).',
      agreement: updatedAgreement,
      updatedCandidate: updatedCandidate,
    );
  }

  /// Natychmiastowe ściągnięcie juniora z wypożyczenia (np. w razie plagi kontuzji).
  LoanOperationResult recallRiderFromLoan({
    required JuniorLoanAgreement agreement,
    required JuniorLoanCandidate candidate,
    required JuniorLoanRosterAudit rosterAudit,
    String reason = 'Plaga kontuzji w kadrze WorldTour',
  }) {
    if (agreement.status != LoanContractStatus.active) {
      return const LoanOperationResult(
        success: false,
        message: 'Nie można ściągnąć — umowa nie jest aktywna.',
      );
    }
    if (agreement.recallClause == LoanRecallClauseType.lockedFullSeason) {
      return LoanOperationResult(
        success: false,
        message:
            'Umowa z ${agreement.partnerClubName} jest zablokowana na pełny sezon bez klauzuli powrotu.',
      );
    }

    int feeEur = 0;
    if (agreement.recallClause == LoanRecallClauseType.mutualNotice14Days &&
        !rosterAudit.isInjuryPlagueActive) {
      feeEur = 15000;
    }

    final updatedAgreement = agreement.copyWith(
      status: LoanContractStatus.recalledEarly,
      recallFeeEur: feeEur,
      recalledReason: reason,
    );

    final updatedCandidate = candidate.copyWith(isCurrentlyOnLoan: false);

    return LoanOperationResult(
      success: true,
      message: feeEur == 0
          ? 'Natychmiastowo ściągnięto ${candidate.fullName} z ${agreement.partnerClubName} (0 € kary — klauzula kryzysowa).'
          : 'Ściągnięto ${candidate.fullName} z ${agreement.partnerClubName} (opłata zerwania: $feeEur €).',
      agreement: updatedAgreement,
      updatedCandidate: updatedCandidate,
      financialDeltaEur: -feeEur,
    );
  }
}

/// Niemutowalny stan systemu wypożyczeń młodych talentów.
class JuniorLoanSystemState {
  final int seasonYear;
  final int wtRosterSize;
  final int injuredWtCount;
  final List<PartnerClubProfile> partnerClubs;
  final List<JuniorLoanCandidate> candidates;
  final List<JuniorLoanAgreement> agreements;
  final String? selectedCandidateId;
  final String? selectedPartnerId;
  final LoanDevelopmentFocus selectedFocus;
  final LoanRecallClauseType selectedRecallClause;
  final LoanPanelFilter activeFilter;
  final String? lastFeedbackMessage;
  final bool lastFeedbackIsError;

  const JuniorLoanSystemState({
    required this.seasonYear,
    required this.wtRosterSize,
    required this.injuredWtCount,
    required this.partnerClubs,
    required this.candidates,
    required this.agreements,
    this.selectedCandidateId,
    this.selectedPartnerId,
    this.selectedFocus = LoanDevelopmentFocus.allRounderRaceIq,
    this.selectedRecallClause = LoanRecallClauseType.emergencyInjuryRecall,
    this.activeFilter = LoanPanelFilter.all,
    this.lastFeedbackMessage,
    this.lastFeedbackIsError = false,
  });

  JuniorLoanCandidate? get selectedCandidate {
    if (selectedCandidateId == null) return null;
    for (final c in candidates) {
      if (c.riderId == selectedCandidateId) return c;
    }
    return null;
  }

  PartnerClubProfile? get selectedPartner {
    if (selectedPartnerId == null) return null;
    for (final p in partnerClubs) {
      if (p.id == selectedPartnerId) return p;
    }
    return null;
  }

  JuniorLoanSystemState copyWith({
    int? seasonYear,
    int? wtRosterSize,
    int? injuredWtCount,
    List<PartnerClubProfile>? partnerClubs,
    List<JuniorLoanCandidate>? candidates,
    List<JuniorLoanAgreement>? agreements,
    String? selectedCandidateId,
    String? selectedPartnerId,
    LoanDevelopmentFocus? selectedFocus,
    LoanRecallClauseType? selectedRecallClause,
    LoanPanelFilter? activeFilter,
    String? lastFeedbackMessage,
    bool? lastFeedbackIsError,
  }) {
    return JuniorLoanSystemState(
      seasonYear: seasonYear ?? this.seasonYear,
      wtRosterSize: wtRosterSize ?? this.wtRosterSize,
      injuredWtCount: injuredWtCount ?? this.injuredWtCount,
      partnerClubs: partnerClubs ?? this.partnerClubs,
      candidates: candidates ?? this.candidates,
      agreements: agreements ?? this.agreements,
      selectedCandidateId: selectedCandidateId ?? this.selectedCandidateId,
      selectedPartnerId: selectedPartnerId ?? this.selectedPartnerId,
      selectedFocus: selectedFocus ?? this.selectedFocus,
      selectedRecallClause: selectedRecallClause ?? this.selectedRecallClause,
      activeFilter: activeFilter ?? this.activeFilter,
      lastFeedbackMessage: lastFeedbackMessage ?? this.lastFeedbackMessage,
      lastFeedbackIsError: lastFeedbackIsError ?? this.lastFeedbackIsError,
    );
  }
}

/// Kontroler Riverpod dla systemu wypożyczeń młodych talentów.
class JuniorLoanSystemNotifier extends StateNotifier<JuniorLoanSystemState> {
  final JuniorDevelopmentLoanSystemService _service;

  JuniorLoanSystemNotifier(this._service) : super(_createInitialState(_service));

  static JuniorLoanSystemState _createInitialState(
    JuniorDevelopmentLoanSystemService service,
  ) {
    final partners = service.createDefaultPartnerClubs();
    const candidates = [
      JuniorLoanCandidate(
        riderId: 'jr_19_kowalski',
        fullName: 'Kacper Kowalski',
        age: 19,
        nationalityIso: 'PL',
        specialization: RiderSpecialization.gcClimber,
        overallRating: 69.0,
        potential: 89,
        projectedWtRaceDays: 11,
        currentRaceIq: 62,
        currentFtpWatts: 392,
        annualSalaryEur: 58000,
      ),
      JuniorLoanCandidate(
        riderId: 'jr_19_vermeulen',
        fullName: 'Lars Vermeulen',
        age: 19,
        nationalityIso: 'BE',
        specialization: RiderSpecialization.classicCobbles,
        overallRating: 68.5,
        potential: 86,
        projectedWtRaceDays: 14,
        currentRaceIq: 65,
        currentFtpWatts: 405,
        annualSalaryEur: 54000,
      ),
      JuniorLoanCandidate(
        riderId: 'jr_20_moretti',
        fullName: 'Matteo Moretti',
        age: 20,
        nationalityIso: 'IT',
        specialization: RiderSpecialization.pureSprinter,
        overallRating: 71.0,
        potential: 87,
        projectedWtRaceDays: 18,
        currentRaceIq: 66,
        currentFtpWatts: 380,
        annualSalaryEur: 64000,
        isCurrentlyOnLoan: true,
      ),
      JuniorLoanCandidate(
        riderId: 'jr_21_delacroix',
        fullName: 'Théo Delacroix',
        age: 21,
        nationalityIso: 'FR',
        specialization: RiderSpecialization.puncher,
        overallRating: 72.5,
        potential: 85,
        projectedWtRaceDays: 29,
        currentRaceIq: 70,
        currentFtpWatts: 412,
        annualSalaryEur: 72000,
      ),
    ];

    const initialAgreement = JuniorLoanAgreement(
      loanId: 'loan_jr_20_moretti_partner_bretagne_conti_2026',
      riderId: 'jr_20_moretti',
      riderName: 'Matteo Moretti',
      riderAge: 20,
      partnerClubId: 'partner_bretagne_conti',
      partnerClubName: 'Bretagne Armorique U23/CT',
      partnerDivision: LoanPartnerDivision.continental,
      seasonYear: 2026,
      elapsedSeasonDays: 60,
      targetSeasonDays: 240,
      recallClause: LoanRecallClauseType.emergencyInjuryRecall,
      developmentFocus: LoanDevelopmentFocus.sprintAndLeadout,
      status: LoanContractStatus.active,
      salaryCoveredByPartnerPercent: 50,
      guaranteedRaceDays: 64,
      accumulatedRaceDays: 16,
      accumulatedOvrGain: 0.65,
      accumulatedRaceIqGain: 2,
      accumulatedFtpGainWatts: 4,
    );

    return JuniorLoanSystemState(
      seasonYear: 2026,
      wtRosterSize: 28,
      injuredWtCount: 1,
      partnerClubs: partners,
      candidates: candidates,
      agreements: const [initialAgreement],
      selectedCandidateId: 'jr_19_kowalski',
      selectedPartnerId: partners.first.id,
      selectedFocus: LoanDevelopmentFocus.stageRacingGc,
    );
  }

  JuniorLoanRosterAudit get currentAudit => _service.auditWorldTourRoster(
        wtRosterSize: state.wtRosterSize,
        injuredCount: state.injuredWtCount,
        juniors: state.candidates,
        agreements: state.agreements,
      );

  void selectCandidate(String riderId) {
    state = state.copyWith(selectedCandidateId: riderId);
  }

  void selectPartner(String partnerId) {
    state = state.copyWith(selectedPartnerId: partnerId);
  }

  void setDevelopmentFocus(LoanDevelopmentFocus focus) {
    state = state.copyWith(selectedFocus: focus);
  }

  void setRecallClause(LoanRecallClauseType clause) {
    state = state.copyWith(selectedRecallClause: clause);
  }

  void setFilter(LoanPanelFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void toggleInjuryPlagueSimulation() {
    final nextInjured = state.injuredWtCount >= 4 ? 1 : 5;
    state = state.copyWith(
      injuredWtCount: nextInjured,
      lastFeedbackMessage: nextInjured >= 4
          ? 'Plaga kontuzji w WorldTour ($nextInjured kolarzy)! Możesz natychmiast ściągnąć juniorów z wypożyczenia.'
          : 'Sytuacja zdrowotna w kadrze WorldTour ustabilizowana (1 kontuzjowany).',
      lastFeedbackIsError: false,
    );
  }

  void sendSelectedJuniorOnLoan() {
    final candidate = state.selectedCandidate;
    final partner = state.selectedPartner;
    if (candidate == null || partner == null) {
      state = state.copyWith(
        lastFeedbackMessage: 'Wybierz juniora oraz drużynę partnerską.',
        lastFeedbackIsError: true,
      );
      return;
    }

    final result = _service.createLoanAgreement(
      candidate: candidate,
      partner: partner,
      focus: state.selectedFocus,
      recallClause: state.selectedRecallClause,
      seasonYear: state.seasonYear,
    );

    if (!result.success ||
        result.agreement == null ||
        result.updatedCandidate == null) {
      state = state.copyWith(
        lastFeedbackMessage: result.message,
        lastFeedbackIsError: true,
      );
      return;
    }

    final updatedCandidates = state.candidates
        .map((c) => c.riderId == candidate.riderId ? result.updatedCandidate! : c)
        .toList();
    final updatedPartners = state.partnerClubs
        .map(
          (p) => p.id == partner.id
              ? p.copyWith(
                  availableRosterSlots:
                      math.max(0, p.availableRosterSlots - 1),
                )
              : p,
        )
        .toList();

    state = state.copyWith(
      candidates: updatedCandidates,
      partnerClubs: updatedPartners,
      agreements: [result.agreement!, ...state.agreements],
      lastFeedbackMessage: result.message,
      lastFeedbackIsError: false,
    );
  }

  void advanceActiveLoansMonth() {
    final active = state.agreements
        .where((a) => a.status == LoanContractStatus.active)
        .toList();
    if (active.isEmpty) {
      state = state.copyWith(
        lastFeedbackMessage: 'Brak aktywnych wypożyczeń do symulacji.',
        lastFeedbackIsError: true,
      );
      return;
    }

    var updatedCandidates = List<JuniorLoanCandidate>.from(state.candidates);
    var updatedAgreements = List<JuniorLoanAgreement>.from(state.agreements);
    int progressedCount = 0;

    for (final loan in active) {
      final candidateIdx =
          updatedCandidates.indexWhere((c) => c.riderId == loan.riderId);
      final partnerIdx =
          state.partnerClubs.indexWhere((p) => p.id == loan.partnerClubId);
      if (candidateIdx < 0 || partnerIdx < 0) continue;

      final res = _service.simulateLoanProgressTick(
        agreement: loan,
        candidate: updatedCandidates[candidateIdx],
        partner: state.partnerClubs[partnerIdx],
        daysElapsed: 30,
      );

      if (res.success &&
          res.agreement != null &&
          res.updatedCandidate != null) {
        updatedCandidates[candidateIdx] = res.updatedCandidate!;
        final loanIdx =
            updatedAgreements.indexWhere((a) => a.loanId == loan.loanId);
        if (loanIdx >= 0) {
          updatedAgreements[loanIdx] = res.agreement!;
        }
        progressedCount++;
      }
    }

    state = state.copyWith(
      candidates: updatedCandidates,
      agreements: updatedAgreements,
      lastFeedbackMessage:
          'Zasymulowano 30 dni wyścigowych dla $progressedCount wypożyczonych juniorów.',
      lastFeedbackIsError: false,
    );
  }

  void recallLoanById(String loanId) {
    final loanIdx = state.agreements.indexWhere((a) => a.loanId == loanId);
    if (loanIdx < 0) return;
    final loan = state.agreements[loanIdx];
    final candidateIdx =
        state.candidates.indexWhere((c) => c.riderId == loan.riderId);
    if (candidateIdx < 0) return;

    final res = _service.recallRiderFromLoan(
      agreement: loan,
      candidate: state.candidates[candidateIdx],
      rosterAudit: currentAudit,
    );

    if (!res.success ||
        res.agreement == null ||
        res.updatedCandidate == null) {
      state = state.copyWith(
        lastFeedbackMessage: res.message,
        lastFeedbackIsError: true,
      );
      return;
    }

    final updatedAgreements = List<JuniorLoanAgreement>.from(state.agreements);
    updatedAgreements[loanIdx] = res.agreement!;

    final updatedCandidates = List<JuniorLoanCandidate>.from(state.candidates);
    updatedCandidates[candidateIdx] = res.updatedCandidate!;

    final updatedPartners = state.partnerClubs
        .map(
          (p) => p.id == loan.partnerClubId
              ? p.copyWith(availableRosterSlots: p.availableRosterSlots + 1)
              : p,
        )
        .toList();

    state = state.copyWith(
      agreements: updatedAgreements,
      candidates: updatedCandidates,
      partnerClubs: updatedPartners,
      lastFeedbackMessage: res.message,
      lastFeedbackIsError: false,
    );
  }
}

final juniorDevelopmentLoanServiceProvider =
    Provider<JuniorDevelopmentLoanSystemService>(
  (ref) => const JuniorDevelopmentLoanSystemService(),
);

final juniorDevelopmentLoanProvider = StateNotifierProvider<
    JuniorLoanSystemNotifier, JuniorLoanSystemState>(
  (ref) => JuniorLoanSystemNotifier(
    ref.watch(juniorDevelopmentLoanServiceProvider),
  ),
);

/// Interaktywny przycisk z pełnymi stanami hover / active / disabled / focus.
class _LoanInteractiveButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool isPrimary;

  const _LoanInteractiveButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.accentColor = AppColors.primaryAccent,
    this.isPrimary = true,
  });

  @override
  State<_LoanInteractiveButton> createState() => _LoanInteractiveButtonState();
}

class _LoanInteractiveButtonState extends State<_LoanInteractiveButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final baseBg = widget.isPrimary ? widget.accentColor : AppColors.surfaceLight;
    final bgColor = !isEnabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _isPressed
            ? baseBg.withValues(alpha: 0.8)
            : _isHovered
                ? baseBg.withValues(alpha: 0.92)
                : baseBg;

    final borderColor = !isEnabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.goldAccent
            : _isHovered
                ? AppColors.textPrimary.withValues(alpha: 0.4)
                : widget.isPrimary
                    ? widget.accentColor
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowFocusHighlight: (focused) {
        if (mounted) setState(() => _isFocused = focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{},
      child: MouseRegion(
        cursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        onEnter: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTapDown: isEnabled
              ? (_) {
                  if (mounted) setState(() => _isPressed = true);
                }
              : null,
          onTapUp: isEnabled
              ? (_) {
                  if (mounted) setState(() => _isPressed = false);
                  widget.onPressed?.call();
                }
              : null,
          onTapCancel: () {
            if (mounted) setState(() => _isPressed = false);
          },
          child: AnimatedScale(
            scale: _isPressed && isEnabled ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
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

/// Interaktywna karta wyboru z pełnymi stanami hover/active/focus.
class _LoanSelectableTile extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;
  final Color accentColor;

  const _LoanSelectableTile({
    required this.isSelected,
    required this.onTap,
    required this.child,
    this.accentColor = AppColors.goldAccent,
  });

  @override
  State<_LoanSelectableTile> createState() => _LoanSelectableTileState();
}

class _LoanSelectableTileState extends State<_LoanSelectableTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.accentColor
        : _focused
            ? AppColors.accentBlue
            : _hovered
                ? AppColors.textSecondary
                : AppColors.cardBorder;

    return FocusableActionDetector(
      onShowFocusHighlight: (f) {
        if (mounted) setState(() => _focused = f);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (mounted) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (mounted) setState(() => _hovered = false);
        },
        child: GestureDetector(
          onTapDown: (_) {
            if (mounted) setState(() => _pressed = true);
          },
          onTapUp: (_) {
            if (mounted) setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () {
            if (mounted) setState(() => _pressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.99 : 1.0,
              _pressed ? 0.99 : 1.0,
              1.0,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.surfaceLight
                  : _hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.7)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _focused ? 1.5 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Produkcyjny panel zarządzania wypożyczeniami młodych talentów do ProTeam i Continental.
class JuniorDevelopmentLoanSystemPanel extends ConsumerWidget {
  const JuniorDevelopmentLoanSystemPanel({super.key});

  static const TextStyle _baseText = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle _tabularStat = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(juniorDevelopmentLoanProvider);
    final notifier = ref.read(juniorDevelopmentLoanProvider.notifier);
    final service = ref.watch(juniorDevelopmentLoanServiceProvider);
    final audit = service.auditWorldTourRoster(
      wtRosterSize: state.wtRosterSize,
      injuredCount: state.injuredWtCount,
      juniors: state.candidates,
      agreements: state.agreements,
    );

    return Container(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 700;
          final isDesktop = width >= 1200;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, state, audit, notifier, isMobile),
                const SizedBox(height: 16),
                if (state.lastFeedbackMessage != null) ...[
                  _buildFeedbackBanner(
                    state.lastFeedbackMessage!,
                    state.lastFeedbackIsError,
                  ),
                  const SizedBox(height: 16),
                ],
                _buildFilterBar(state, notifier),
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildLeftColumn(state, notifier, audit),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _buildPartnersColumn(state, notifier),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _buildComparisonAndActionColumn(
                          state,
                          notifier,
                          service,
                        ),
                      ),
                    ],
                  )
                else if (!isMobile)
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildLeftColumn(state, notifier, audit),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPartnersColumn(state, notifier),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildComparisonAndActionColumn(
                        state,
                        notifier,
                        service,
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildLeftColumn(state, notifier, audit),
                      const SizedBox(height: 16),
                      _buildPartnersColumn(state, notifier),
                      const SizedBox(height: 16),
                      _buildComparisonAndActionColumn(
                        state,
                        notifier,
                        service,
                      ),
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
    BuildContext context,
    JuniorLoanSystemState state,
    JuniorLoanRosterAudit audit,
    JuniorLoanSystemNotifier notifier,
    bool isMobile,
  ) {
    final badgeColor = audit.isInjuryPlagueActive
        ? AppColors.crimsonAlert
        : AppColors.goldAccent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: audit.isInjuryPlagueActive
              ? AppColors.crimsonAlert
              : AppColors.cardBorder,
        ),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryAccent),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
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
                          'System Wypożyczeń Młodych Talentów',
                          style: _baseText.copyWith(
                            fontSize: isMobile ? 16 : 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '1-sezonowe wypożyczenia do ProTeam / Continental z klauzulą powrotu',
                          style: _baseText.copyWith(
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
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricPill(
                    'Kadra WT',
                    '${audit.wtRosterSize}/${audit.maxWtRosterLimit}',
                    AppColors.accentBlue,
                  ),
                  _buildMetricPill(
                    'Kontuzje',
                    '${audit.injuredWtRidersCount}',
                    badgeColor,
                  ),
                  _buildMetricPill(
                    'Wypożyczeni',
                    '${audit.activeLoansCount}',
                    AppColors.statusSuccess,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: audit.isInjuryPlagueActive
                    ? AppColors.crimsonAlert.withValues(alpha: 0.7)
                    : AppColors.cardBorder,
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      audit.isInjuryPlagueActive
                          ? Icons.medical_services_rounded
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        audit.recommendedAction,
                        style: _baseText.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _LoanInteractiveButton(
                      label: audit.isInjuryPlagueActive
                          ? 'Zakończ plagę kontuzji'
                          : 'Symuluj plagę kontuzji',
                      icon: Icons.healing_rounded,
                      isPrimary: false,
                      accentColor: AppColors.crimsonAlert,
                      onPressed: notifier.toggleInjuryPlagueSimulation,
                    ),
                    _LoanInteractiveButton(
                      label: 'Symuluj +30 dni',
                      icon: Icons.fast_forward_rounded,
                      isPrimary: false,
                      accentColor: AppColors.accentBlue,
                      onPressed: state.agreements.any(
                        (a) => a.status == LoanContractStatus.active,
                      )
                          ? notifier.advanceActiveLoansMonth
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: _baseText.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: _tabularStat.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(String message, bool isError) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: _baseText.copyWith(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    JuniorLoanSystemState state,
    JuniorLoanSystemNotifier notifier,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LoanPanelFilter.values.map((filter) {
        final selected = state.activeFilter == filter;
        return ChoiceChip(
          label: Text(
            filter.label,
            style: _baseText.copyWith(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color:
                  selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          selected: selected,
          selectedColor: AppColors.primaryAccent,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: selected ? AppColors.goldAccent : AppColors.cardBorder,
          ),
          onSelected: (_) => notifier.setFilter(filter),
        );
      }).toList(),
    );
  }

  Widget _buildLeftColumn(
    JuniorLoanSystemState state,
    JuniorLoanSystemNotifier notifier,
    JuniorLoanRosterAudit audit,
  ) {
    final showJuniors = state.activeFilter == LoanPanelFilter.all ||
        state.activeFilter == LoanPanelFilter.eligibleJuniors;
    final showLoans = state.activeFilter == LoanPanelFilter.all ||
        state.activeFilter == LoanPanelFilter.activeLoans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showJuniors) ...[
          _buildSectionCard(
            title: 'Młode Talenty w Kadrze WT (≤ 22 lat)',
            icon: Icons.person_search_rounded,
            child: Column(
              children: state.candidates.map((c) {
                final isSelected = state.selectedCandidateId == c.riderId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LoanSelectableTile(
                    isSelected: isSelected,
                    onTap: () => notifier.selectCandidate(c.riderId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${c.fullName} (${c.age} l., ${c.nationalityIso})',
                                style: _baseText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: c.isCurrentlyOnLoan
                                    ? AppColors.accentBlue.withValues(alpha: 0.18)
                                    : c.isBenchStagnating
                                        ? AppColors.amberWarning
                                            .withValues(alpha: 0.18)
                                        : AppColors.statusSuccess
                                            .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c.isCurrentlyOnLoan
                                    ? 'NA WYPOŻYCZENIU'
                                    : c.isBenchStagnating
                                        ? 'ŁAWKA (${c.projectedWtRaceDays} dni)'
                                        : 'AKTYWNY WT',
                                style: _tabularStat.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: c.isCurrentlyOnLoan
                                      ? AppColors.accentBlue
                                      : c.isBenchStagnating
                                          ? AppColors.amberWarning
                                          : AppColors.statusSuccess,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${c.specialization.displayName} • OVR ${c.overallRating.toStringAsFixed(1)} / POT ${c.potential} • FTP ${c.currentFtpWatts} W',
                          style: _tabularStat.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (showLoans)
          _buildSectionCard(
            title: 'Aktywne i Zakończone Wypożyczenia',
            icon: Icons.assignment_turned_in_rounded,
            child: state.agreements.isEmpty
                ? Text(
                    'Brak aktywnych wypożyczeń w bieżącym sezonie.',
                    style: _baseText.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Column(
                    children: state.agreements.map((loan) {
                      final isActive = loan.status == LoanContractStatus.active;
                      final canRecall =
                          isActive && loan.canInstantRecall;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive && audit.isInjuryPlagueActive
                                ? AppColors.crimsonAlert
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${loan.riderName} → ${loan.partnerClubName}',
                                    style: _baseText.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  loan.status.label,
                                  style: _baseText.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? AppColors.statusSuccess
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dni wyścigowe: ${loan.accumulatedRaceDays}/${loan.guaranteedRaceDays} • OVR +${loan.accumulatedOvrGain.toStringAsFixed(2)} • Race IQ +${loan.accumulatedRaceIqGain} • FTP +${loan.accumulatedFtpGainWatts} W',
                              style: _tabularStat.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: loan.progressRatio,
                                minHeight: 6,
                                backgroundColor: AppColors.background,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isActive
                                      ? AppColors.goldAccent
                                      : AppColors.statusSuccess,
                                ),
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: _LoanInteractiveButton(
                                  label: audit.isInjuryPlagueActive
                                      ? 'Ściągnij natychmiast (0 € — plaga kontuzji)'
                                      : 'Ściągnij przedwcześnie z wypożyczenia',
                                  icon: Icons.keyboard_return_rounded,
                                  accentColor: audit.isInjuryPlagueActive
                                      ? AppColors.crimsonAlert
                                      : AppColors.primaryAccent,
                                  onPressed: canRecall
                                      ? () =>
                                          notifier.recallLoanById(loan.loanId)
                                      : null,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
      ],
    );
  }

  Widget _buildPartnersColumn(
    JuniorLoanSystemState state,
    JuniorLoanSystemNotifier notifier,
  ) {
    if (state.activeFilter != LoanPanelFilter.all &&
        state.activeFilter != LoanPanelFilter.partnerClubs) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      title: 'Zaprzyjaźnione Drużyny ProTeam & Continental',
      icon: Icons.handshake_rounded,
      child: Column(
        children: state.partnerClubs.map((p) {
          final isSelected = state.selectedPartnerId == p.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LoanSelectableTile(
              isSelected: isSelected,
              accentColor: AppColors.accentBlue,
              onTap: () => notifier.selectPartner(p.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${p.name} (${p.countryIso})',
                          style: _baseText.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: p.division == LoanPartnerDivision.proTeam
                              ? AppColors.goldAccent.withValues(alpha: 0.16)
                              : AppColors.accentBlue.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.division.label,
                          style: _baseText.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: p.division == LoanPartnerDivision.proTeam
                                ? AppColors.goldAccent
                                : AppColors.accentBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gwarantowane dni: ${p.guaranteedRaceDays} • Pokrycie pensji: ${p.salarySharePercent}% • Wolne miejsca: ${p.availableRosterSlots}',
                    style: _tabularStat.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Priorytet: ${p.calendarFocus.label} • Relacja: ${p.friendshipScore}/100',
                    style: _tabularStat.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComparisonAndActionColumn(
    JuniorLoanSystemState state,
    JuniorLoanSystemNotifier notifier,
    JuniorDevelopmentLoanSystemService service,
  ) {
    final candidate = state.selectedCandidate;
    final partner = state.selectedPartner;

    final comparison = (candidate != null && partner != null)
        ? service.compareLoanVsBench(
            candidate: candidate,
            partner: partner,
            focus: state.selectedFocus,
            recallClause: state.selectedRecallClause,
          )
        : null;

    final canSend = candidate != null &&
        partner != null &&
        candidate.isEligibleForLoan &&
        partner.hasOpenSlot;

    return _buildSectionCard(
      title: 'Symulacja Rozwoju i Warunki Wypożyczenia',
      icon: Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cel szkoleniowy',
            style: _baseText.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: LoanDevelopmentFocus.values.map((focus) {
              final selected = state.selectedFocus == focus;
              return ChoiceChip(
                label: Text(
                  focus.label,
                  style: _baseText.copyWith(fontSize: 11.5),
                ),
                selected: selected,
                selectedColor: AppColors.primaryAccent,
                backgroundColor: AppColors.surfaceLight,
                side: BorderSide(
                  color: selected ? AppColors.goldAccent : AppColors.cardBorder,
                ),
                onSelected: (_) => notifier.setDevelopmentFocus(focus),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Klauzula powrotu do WorldTour',
            style: _baseText.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ...LoanRecallClauseType.values.map((clause) {
            final selected = state.selectedRecallClause == clause;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _LoanSelectableTile(
                isSelected: selected,
                accentColor: AppColors.goldAccent,
                onTap: () => notifier.setRecallClause(clause),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: selected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clause.label,
                        style: _baseText.copyWith(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (comparison != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Ławka WT vs Wypożyczenie',
                          style: _baseText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${comparison.netDevelopmentAdvantagePercent.toStringAsFixed(0)}% szybciej',
                        style: _tabularStat.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildComparisonRow(
                    'Dni wyścigowe',
                    '${comparison.benchProjectedRaceDays} dni',
                    '${comparison.loanProjectedRaceDays} dni',
                  ),
                  _buildComparisonRow(
                    'Przyrost OVR',
                    '+${comparison.benchProjectedOvrGain.toStringAsFixed(2)}',
                    '+${comparison.loanProjectedOvrGain.toStringAsFixed(2)}',
                  ),
                  _buildComparisonRow(
                    'Race IQ',
                    '+${comparison.benchProjectedRaceIqGain}',
                    '+${comparison.loanProjectedRaceIqGain}',
                  ),
                  _buildComparisonRow(
                    'FTP (W)',
                    '+${comparison.benchProjectedFtpGain} W',
                    '+${comparison.loanProjectedFtpGain} W',
                  ),
                  _buildComparisonRow(
                    'Oszczędność pensji',
                    '0 €',
                    '${comparison.salarySavedEur} €',
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _LoanInteractiveButton(
            label: canSend
                ? 'Wypożycz ${candidate.fullName} na 1 sezon'
                : 'Wybierz kwalifikującego się juniora',
            icon: Icons.send_rounded,
            accentColor: AppColors.primaryAccent,
            onPressed: canSend ? notifier.sendSelectedJuniorOnLoan : null,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String bench, String loan) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: _baseText.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              bench,
              textAlign: TextAlign.right,
              style: _tabularStat.copyWith(
                fontSize: 12,
                color: AppColors.amberWarning,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              loan,
              textAlign: TextAlign.right,
              style: _tabularStat.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.statusSuccess,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: _baseText.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
