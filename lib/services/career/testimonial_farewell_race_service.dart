// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/career/staff_member.dart';
import '../../models/rider/rider.dart';

/// Minimalny wiek kolarza wymagany do ogłoszenia pożegnalnego sezonu legendy.
const int kMinTestimonialFarewellAge = 36;

/// Klasa rangi zasług kolarza odchodzącego na sportową emeryturę.
enum FarewellLegendTier {
  clubIcon,
  pelotonVeteran,
  worldTourLegend,
  cyclingImmortal;

  String toJson() => name;

  static FarewellLegendTier fromJson(String value) {
    return FarewellLegendTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FarewellLegendTier.pelotonVeteran,
    );
  }

  String get label {
    switch (this) {
      case FarewellLegendTier.clubIcon:
        return 'Ikona Klubu';
      case FarewellLegendTier.pelotonVeteran:
        return 'Weteran Peletonu';
      case FarewellLegendTier.worldTourLegend:
        return 'Legenda WorldTour';
      case FarewellLegendTier.cyclingImmortal:
        return 'Nieśmiertelny Mistrz';
    }
  }

  Color get accentColor {
    switch (this) {
      case FarewellLegendTier.clubIcon:
        return AppColors.accentBlue;
      case FarewellLegendTier.pelotonVeteran:
        return AppColors.statusSuccess;
      case FarewellLegendTier.worldTourLegend:
        return AppColors.goldAccent;
      case FarewellLegendTier.cyclingImmortal:
        return AppColors.primaryAccent;
    }
  }
}

/// Etap procesu pożegnalnego sezonu i przejścia na emeryturę.
enum FarewellPhase {
  announcedFinalSeason,
  finalRaceScheduled,
  guardOfHonorPerformed,
  retiredPendingDsDecision,
  hiredAsSportsDirector,
  retiredToPrivateLife;

  String toJson() => name;

  static FarewellPhase fromJson(String value) {
    return FarewellPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => FarewellPhase.announcedFinalSeason,
    );
  }

  String get label {
    switch (this) {
      case FarewellPhase.announcedFinalSeason:
        return 'Ogłoszono Ostatni Sezon';
      case FarewellPhase.finalRaceScheduled:
        return 'Zaplanowano Wyścig Pożegnalny';
      case FarewellPhase.guardOfHonorPerformed:
        return 'Szpaler Honorowy Odbyty';
      case FarewellPhase.retiredPendingDsDecision:
        return 'Emerytura — Decyzja o Roli DS';
      case FarewellPhase.hiredAsSportsDirector:
        return 'Zatrudniony jako Dyrektor Sportowy';
      case FarewellPhase.retiredToPrivateLife:
        return 'Zakończono Karierę';
    }
  }

  Color get statusColor {
    switch (this) {
      case FarewellPhase.announcedFinalSeason:
        return AppColors.goldAccent;
      case FarewellPhase.finalRaceScheduled:
        return AppColors.cyanAccent;
      case FarewellPhase.guardOfHonorPerformed:
        return AppColors.amberWarning;
      case FarewellPhase.retiredPendingDsDecision:
        return AppColors.accentBlue;
      case FarewellPhase.hiredAsSportsDirector:
        return AppColors.statusSuccess;
      case FarewellPhase.retiredToPrivateLife:
        return AppColors.textSecondary;
    }
  }
}

/// Specjalna odznaka "Final Season" przyznawana kolarzowi w ostatnim sezonie kariery.
class FinalSeasonBadge {
  final String badgeCode;
  final String label;
  final int seasonYear;
  final FarewellLegendTier tier;
  final int yearsWithTeam;
  final int careerUciPoints;
  final String legendarySummary;

  const FinalSeasonBadge({
    this.badgeCode = 'FINAL_SEASON',
    this.label = 'Final Season',
    required this.seasonYear,
    required this.tier,
    required this.yearsWithTeam,
    required this.careerUciPoints,
    required this.legendarySummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'badgeCode': badgeCode,
      'label': label,
      'seasonYear': seasonYear,
      'tier': tier.toJson(),
      'yearsWithTeam': yearsWithTeam,
      'careerUciPoints': careerUciPoints,
      'legendarySummary': legendarySummary,
    };
  }

  factory FinalSeasonBadge.fromJson(Map<String, dynamic> json) {
    return FinalSeasonBadge(
      badgeCode: json['badgeCode'] as String? ?? 'FINAL_SEASON',
      label: json['label'] as String? ?? 'Final Season',
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      tier: FarewellLegendTier.fromJson(json['tier'] as String? ?? ''),
      yearsWithTeam: (json['yearsWithTeam'] as num?)?.toInt() ?? 1,
      careerUciPoints: (json['careerUciPoints'] as num?)?.toInt() ?? 0,
      legendarySummary: json['legendarySummary'] as String? ?? '',
    );
  }
}

/// Zdarzenie szpaleru honorowego peletonu na ostatnim wyścigu legendy.
class PelotonGuardOfHonorEvent {
  final String raceId;
  final String raceName;
  final String stageOrLocation;
  final DateTime eventDate;
  final int participatingPelotonCount;
  final int guardDurationSeconds;
  final double moraleBoostApplied;
  final int fanTributeIndex;
  final List<String> saluteQuotes;
  final String tributeSummary;

  const PelotonGuardOfHonorEvent({
    required this.raceId,
    required this.raceName,
    required this.stageOrLocation,
    required this.eventDate,
    required this.participatingPelotonCount,
    required this.guardDurationSeconds,
    required this.moraleBoostApplied,
    required this.fanTributeIndex,
    required this.saluteQuotes,
    required this.tributeSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'raceId': raceId,
      'raceName': raceName,
      'stageOrLocation': stageOrLocation,
      'eventDate': eventDate.toIso8601String(),
      'participatingPelotonCount': participatingPelotonCount,
      'guardDurationSeconds': guardDurationSeconds,
      'moraleBoostApplied': moraleBoostApplied,
      'fanTributeIndex': fanTributeIndex,
      'saluteQuotes': saluteQuotes,
      'tributeSummary': tributeSummary,
    };
  }

  factory PelotonGuardOfHonorEvent.fromJson(Map<String, dynamic> json) {
    return PelotonGuardOfHonorEvent(
      raceId: json['raceId'] as String? ?? '',
      raceName: json['raceName'] as String? ?? '',
      stageOrLocation: json['stageOrLocation'] as String? ?? '',
      eventDate: DateTime.tryParse(json['eventDate'] as String? ?? '') ??
          DateTime(2026, 10, 15),
      participatingPelotonCount:
          (json['participatingPelotonCount'] as num?)?.toInt() ?? 176,
      guardDurationSeconds:
          (json['guardDurationSeconds'] as num?)?.toInt() ?? 45,
      moraleBoostApplied:
          (json['moraleBoostApplied'] as num?)?.toDouble() ?? 12.0,
      fanTributeIndex: (json['fanTributeIndex'] as num?)?.toInt() ?? 90,
      saluteQuotes: (json['saluteQuotes'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      tributeSummary: json['tributeSummary'] as String? ?? '',
    );
  }
}

/// Oferta natychmiastowego zatrudnienia emerytowanej legendy jako Dyrektora Sportowego.
class SportsDirectorTransitionOffer {
  final String offerId;
  final String riderId;
  final String riderFullName;
  final SportsDirector proposedDirector;
  final int monthlySalaryEur;
  final int contractYears;
  final int signingBonusEur;
  final bool isLoyaltyDiscountApplied;
  final DateTime expiresOnDate;

  const SportsDirectorTransitionOffer({
    required this.offerId,
    required this.riderId,
    required this.riderFullName,
    required this.proposedDirector,
    required this.monthlySalaryEur,
    required this.contractYears,
    required this.signingBonusEur,
    required this.isLoyaltyDiscountApplied,
    required this.expiresOnDate,
  });

  int get totalContractValueEur =>
      (monthlySalaryEur * 12 * contractYears) + signingBonusEur;

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'riderId': riderId,
      'riderFullName': riderFullName,
      'proposedDirector': proposedDirector.toJson(),
      'monthlySalaryEur': monthlySalaryEur,
      'contractYears': contractYears,
      'signingBonusEur': signingBonusEur,
      'isLoyaltyDiscountApplied': isLoyaltyDiscountApplied,
      'expiresOnDate': expiresOnDate.toIso8601String(),
    };
  }

  factory SportsDirectorTransitionOffer.fromJson(Map<String, dynamic> json) {
    return SportsDirectorTransitionOffer(
      offerId: json['offerId'] as String? ?? '',
      riderId: json['riderId'] as String? ?? '',
      riderFullName: json['riderFullName'] as String? ?? '',
      proposedDirector: SportsDirector.fromJson(
        Map<String, dynamic>.from(
          json['proposedDirector'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      monthlySalaryEur: (json['monthlySalaryEur'] as num?)?.toInt() ?? 8000,
      contractYears: (json['contractYears'] as num?)?.toInt() ?? 2,
      signingBonusEur: (json['signingBonusEur'] as num?)?.toInt() ?? 0,
      isLoyaltyDiscountApplied:
          json['isLoyaltyDiscountApplied'] as bool? ?? false,
      expiresOnDate:
          DateTime.tryParse(json['expiresOnDate'] as String? ?? '') ??
              DateTime(2026, 12, 31),
    );
  }
}

/// Wynik sprawdzenia kwalifikacji kolarza do pożegnalnego sezonu legendy.
class FarewellEligibilityReport {
  final String riderId;
  final String riderFullName;
  final int ageYears;
  final int yearsWithTeam;
  final int careerUciPoints;
  final int overallRating;
  final bool isEligible;
  final FarewellLegendTier? recommendedTier;
  final List<String> reasons;

  const FarewellEligibilityReport({
    required this.riderId,
    required this.riderFullName,
    required this.ageYears,
    required this.yearsWithTeam,
    required this.careerUciPoints,
    required this.overallRating,
    required this.isEligible,
    required this.recommendedTier,
    required this.reasons,
  });
}

/// Wynik natychmiastowego zatrudnienia legendy jako Dyrektora Sportowego.
class FarewellDirectorHireResult {
  final FarewellLegendRecord updatedRecord;
  final SportsDirector hiredDirector;
  final int initialCostEur;

  const FarewellDirectorHireResult({
    required this.updatedRecord,
    required this.hiredDirector,
    required this.initialCostEur,
  });
}

/// Pełny rekord pożegnalnego sezonu i przejścia na emeryturę dla legendy peletonu.
class FarewellLegendRecord {
  final String riderId;
  final String riderFullName;
  final String nationalityIso;
  final int ageAtAnnouncement;
  final int seasonYear;
  final RiderSpecialization specialization;
  final int overallRating;
  final int careerPointsUci;
  final int yearsWithCurrentTeam;
  final FinalSeasonBadge badge;
  final FarewellPhase phase;
  final String? finalRaceId;
  final String? finalRaceName;
  final PelotonGuardOfHonorEvent? guardOfHonor;
  final SportsDirectorTransitionOffer? directorOffer;
  final SportsDirector? hiredDirector;
  final DateTime announcedAt;
  final DateTime? retiredAt;

  const FarewellLegendRecord({
    required this.riderId,
    required this.riderFullName,
    required this.nationalityIso,
    required this.ageAtAnnouncement,
    required this.seasonYear,
    required this.specialization,
    required this.overallRating,
    required this.careerPointsUci,
    required this.yearsWithCurrentTeam,
    required this.badge,
    required this.phase,
    this.finalRaceId,
    this.finalRaceName,
    this.guardOfHonor,
    this.directorOffer,
    this.hiredDirector,
    required this.announcedAt,
    this.retiredAt,
  });

  bool get hasFinalSeasonBadge => badge.badgeCode == 'FINAL_SEASON';
  bool get hasGuardOfHonor => guardOfHonor != null;
  bool get canHireAsSportsDirector =>
      phase == FarewellPhase.retiredPendingDsDecision && directorOffer != null;

  FarewellLegendRecord copyWith({
    FarewellPhase? phase,
    String? finalRaceId,
    String? finalRaceName,
    PelotonGuardOfHonorEvent? guardOfHonor,
    SportsDirectorTransitionOffer? directorOffer,
    SportsDirector? hiredDirector,
    DateTime? retiredAt,
  }) {
    return FarewellLegendRecord(
      riderId: riderId,
      riderFullName: riderFullName,
      nationalityIso: nationalityIso,
      ageAtAnnouncement: ageAtAnnouncement,
      seasonYear: seasonYear,
      specialization: specialization,
      overallRating: overallRating,
      careerPointsUci: careerPointsUci,
      yearsWithCurrentTeam: yearsWithCurrentTeam,
      badge: badge,
      phase: phase ?? this.phase,
      finalRaceId: finalRaceId ?? this.finalRaceId,
      finalRaceName: finalRaceName ?? this.finalRaceName,
      guardOfHonor: guardOfHonor ?? this.guardOfHonor,
      directorOffer: directorOffer ?? this.directorOffer,
      hiredDirector: hiredDirector ?? this.hiredDirector,
      announcedAt: announcedAt,
      retiredAt: retiredAt ?? this.retiredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderFullName': riderFullName,
      'nationalityIso': nationalityIso,
      'ageAtAnnouncement': ageAtAnnouncement,
      'seasonYear': seasonYear,
      'specialization': specialization.toJson(),
      'overallRating': overallRating,
      'careerPointsUci': careerPointsUci,
      'yearsWithCurrentTeam': yearsWithCurrentTeam,
      'badge': badge.toJson(),
      'phase': phase.toJson(),
      'finalRaceId': finalRaceId,
      'finalRaceName': finalRaceName,
      'guardOfHonor': guardOfHonor?.toJson(),
      'directorOffer': directorOffer?.toJson(),
      'hiredDirector': hiredDirector?.toJson(),
      'announcedAt': announcedAt.toIso8601String(),
      'retiredAt': retiredAt?.toIso8601String(),
    };
  }

  factory FarewellLegendRecord.fromJson(Map<String, dynamic> json) {
    return FarewellLegendRecord(
      riderId: json['riderId'] as String? ?? '',
      riderFullName: json['riderFullName'] as String? ?? '',
      nationalityIso: json['nationalityIso'] as String? ?? 'POL',
      ageAtAnnouncement:
          (json['ageAtAnnouncement'] as num?)?.toInt() ?? 36,
      seasonYear: (json['seasonYear'] as num?)?.toInt() ?? 2026,
      specialization: RiderSpecialization.fromJson(
        json['specialization'] as String? ?? '',
      ),
      overallRating: (json['overallRating'] as num?)?.toInt() ?? 75,
      careerPointsUci: (json['careerPointsUci'] as num?)?.toInt() ?? 0,
      yearsWithCurrentTeam:
          (json['yearsWithCurrentTeam'] as num?)?.toInt() ?? 1,
      badge: FinalSeasonBadge.fromJson(
        Map<String, dynamic>.from(
          json['badge'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      phase: FarewellPhase.fromJson(json['phase'] as String? ?? ''),
      finalRaceId: json['finalRaceId'] as String?,
      finalRaceName: json['finalRaceName'] as String?,
      guardOfHonor: json['guardOfHonor'] is Map
          ? PelotonGuardOfHonorEvent.fromJson(
              Map<String, dynamic>.from(json['guardOfHonor'] as Map),
            )
          : null,
      directorOffer: json['directorOffer'] is Map
          ? SportsDirectorTransitionOffer.fromJson(
              Map<String, dynamic>.from(json['directorOffer'] as Map),
            )
          : null,
      hiredDirector: json['hiredDirector'] is Map
          ? SportsDirector.fromJson(
              Map<String, dynamic>.from(json['hiredDirector'] as Map),
            )
          : null,
      announcedAt: DateTime.tryParse(json['announcedAt'] as String? ?? '') ??
          DateTime(2026, 1, 15),
      retiredAt: json['retiredAt'] != null
          ? DateTime.tryParse(json['retiredAt'] as String)
          : null,
    );
  }
}

/// Zbiorcze podsumowanie wszystkich pożegnalnych sezonów w zespole.
class FarewellSeasonAuditSummary {
  final int totalLegends;
  final int activeFinalSeasonCount;
  final int guardOfHonorCompletedCount;
  final int pendingDsDecisionCount;
  final int hiredAsDsCount;

  const FarewellSeasonAuditSummary({
    required this.totalLegends,
    required this.activeFinalSeasonCount,
    required this.guardOfHonorCompletedCount,
    required this.pendingDsDecisionCount,
    required this.hiredAsDsCount,
  });
}

/// Serwis obsługujący pożegnalny sezon i wyścig wieloletnich legend peletonu (>= 36 lat),
/// odznakę `Final Season`, szpaler honorowy peletonu oraz przejście do roli Dyrektora Sportowego.
class TestimonialFarewellRaceService {
  const TestimonialFarewellRaceService();

  /// Wylicza dokładny wiek kolarza w latach na podaną datę odniesienia.
  int calculateAgeAt(DateTime birthDate, DateTime referenceDate) {
    int age = referenceDate.year - birthDate.year;
    if (referenceDate.month < birthDate.month ||
        (referenceDate.month == birthDate.month &&
            referenceDate.day < birthDate.day)) {
      age--;
    }
    return math.max(0, age);
  }

  /// Określa rangę legendy na podstawie punktów UCI, OVR oraz stażu w drużynie.
  FarewellLegendTier classifyLegendTier({
    required int careerPointsUci,
    required int overallRating,
    required int yearsWithTeam,
  }) {
    if (careerPointsUci >= 12000 ||
        (careerPointsUci >= 8500 && overallRating >= 84)) {
      return FarewellLegendTier.cyclingImmortal;
    }
    if (careerPointsUci >= 4500 || overallRating >= 80) {
      return FarewellLegendTier.worldTourLegend;
    }
    if (yearsWithTeam >= 6) {
      return FarewellLegendTier.clubIcon;
    }
    return FarewellLegendTier.pelotonVeteran;
  }

  /// Weryfikuje czy kolarz kwalifikuje się do ogłoszenia pożegnalnego sezonu legendy.
  FarewellEligibilityReport evaluateEligibility(
    Rider rider, {
    DateTime? referenceDate,
    int yearsWithTeam = 1,
    int minimumMeritPoints = 0,
  }) {
    final now = referenceDate ?? DateTime.now();
    final ageYears = calculateAgeAt(rider.birthDate, now);
    final ovr = rider.overallRating;
    final reasons = <String>[];

    if (ageYears < kMinTestimonialFarewellAge) {
      reasons.add(
        'Wymagany wiek to minimum $kMinTestimonialFarewellAge lat (obecnie $ageYears).',
      );
    }
    if (rider.careerPointsUci < minimumMeritPoints) {
      reasons.add(
        'Niewystarczający dorobek punktowy UCI (${rider.careerPointsUci} < $minimumMeritPoints).',
      );
    }

    final isEligible =
        ageYears >= kMinTestimonialFarewellAge &&
        rider.careerPointsUci >= minimumMeritPoints;

    final tier = isEligible
        ? classifyLegendTier(
            careerPointsUci: rider.careerPointsUci,
            overallRating: ovr,
            yearsWithTeam: yearsWithTeam,
          )
        : null;

    if (isEligible && tier != null) {
      reasons.add(
        'Kwalifikacja potwierdzona: ${tier.label} ($ageYears lat, $yearsWithTeam lat w klubie).',
      );
    }

    return FarewellEligibilityReport(
      riderId: rider.id,
      riderFullName: rider.fullName,
      ageYears: ageYears,
      yearsWithTeam: yearsWithTeam,
      careerUciPoints: rider.careerPointsUci,
      overallRating: ovr,
      isEligible: isEligible,
      recommendedTier: tier,
      reasons: List<String>.unmodifiable(reasons),
    );
  }

  /// Ogłasza ostatni sezon kariery zasłużonego kolarza (>= 36 lat) i nadaje odznakę `Final Season`.
  FarewellLegendRecord announceFinalSeason(
    Rider rider, {
    required int seasonYear,
    int yearsWithTeam = 1,
    DateTime? announcedAt,
    String? finalRaceId,
    String? finalRaceName,
  }) {
    final date = announcedAt ?? DateTime(seasonYear, 1, 15);
    final report = evaluateEligibility(
      rider,
      referenceDate: date,
      yearsWithTeam: yearsWithTeam,
    );

    if (!report.isEligible || report.recommendedTier == null) {
      throw ArgumentError(
        'Kolarz ${rider.fullName} nie spełnia wymogów pożegnalnego sezonu '
        '(wiek ${report.ageYears} < $kMinTestimonialFarewellAge).',
      );
    }

    final safeYears = math.max(1, yearsWithTeam);
    final tier = report.recommendedTier!;
    final badge = FinalSeasonBadge(
      seasonYear: seasonYear,
      tier: tier,
      yearsWithTeam: safeYears,
      careerUciPoints: rider.careerPointsUci,
      legendarySummary:
          '${tier.label} • $safeYears lat w drużynie • ${rider.careerPointsUci} pkt UCI',
    );

    final hasScheduledRace =
        finalRaceId != null &&
        finalRaceId.trim().isNotEmpty &&
        finalRaceName != null &&
        finalRaceName.trim().isNotEmpty;

    return FarewellLegendRecord(
      riderId: rider.id,
      riderFullName: rider.fullName,
      nationalityIso: rider.nationalityIso,
      ageAtAnnouncement: report.ageYears,
      seasonYear: seasonYear,
      specialization: rider.specialization,
      overallRating: report.overallRating,
      careerPointsUci: rider.careerPointsUci,
      yearsWithCurrentTeam: safeYears,
      badge: badge,
      phase: hasScheduledRace
          ? FarewellPhase.finalRaceScheduled
          : FarewellPhase.announcedFinalSeason,
      finalRaceId: hasScheduledRace ? finalRaceId.trim() : null,
      finalRaceName: hasScheduledRace ? finalRaceName.trim() : null,
      announcedAt: date,
    );
  }

  /// Przypisuje ostatni, pożegnalny wyścig w kalendarzu kolarza.
  FarewellLegendRecord scheduleFinalRace(
    FarewellLegendRecord record, {
    required String raceId,
    required String raceName,
  }) {
    final trimmedId = raceId.trim();
    final trimmedName = raceName.trim();
    if (trimmedId.isEmpty || trimmedName.isEmpty) {
      throw ArgumentError('Identyfikator i nazwa ostatniego wyścigu nie mogą być puste.');
    }

    return record.copyWith(
      finalRaceId: trimmedId,
      finalRaceName: trimmedName,
      phase: record.phase == FarewellPhase.announcedFinalSeason
          ? FarewellPhase.finalRaceScheduled
          : record.phase,
    );
  }

  /// Przeprowadza ceremonię szpaleru honorowego peletonu na ostatnim wyścigu legendy.
  PelotonGuardOfHonorEvent buildGuardOfHonorEvent({
    required FarewellLegendRecord record,
    required String raceId,
    required String raceName,
    String stageOrLocation = 'Linia startu — KM 0.0',
    int pelotonSize = 176,
    DateTime? eventDate,
  }) {
    final clampedPeloton = pelotonSize.clamp(24, 220);
    final durationSeconds = switch (record.badge.tier) {
      FarewellLegendTier.cyclingImmortal => 75,
      FarewellLegendTier.worldTourLegend => 60,
      FarewellLegendTier.clubIcon => 50,
      FarewellLegendTier.pelotonVeteran => 40,
    };

    final moraleBoost = switch (record.badge.tier) {
      FarewellLegendTier.cyclingImmortal => 22.0,
      FarewellLegendTier.worldTourLegend => 18.0,
      FarewellLegendTier.clubIcon => 15.0,
      FarewellLegendTier.pelotonVeteran => 12.0,
    };

    final fanIndex = (72 +
            (record.careerPointsUci ~/ 600).clamp(0, 18) +
            record.yearsWithCurrentTeam.clamp(0, 10))
        .clamp(65, 100);

    final quotes = <String>[
      'Cały peleton ustawił się w dwuszeregu z uniesionymi kołami przed ${record.riderFullName}.',
      '„Jazda z Tobą ramię w ramię przez te lata była zaszczytem” — kapitanowie drużyn WorldTour.',
      'Kibice na trasie $raceName skandowali nazwisko legendy na ostatnich metrach przed startem.',
    ];

    return PelotonGuardOfHonorEvent(
      raceId: raceId,
      raceName: raceName,
      stageOrLocation: stageOrLocation,
      eventDate: eventDate ?? DateTime(record.seasonYear, 10, 12),
      participatingPelotonCount: clampedPeloton,
      guardDurationSeconds: durationSeconds,
      moraleBoostApplied: moraleBoost,
      fanTributeIndex: fanIndex,
      saluteQuotes: List<String>.unmodifiable(quotes),
      tributeSummary:
          '$clampedPeloton kolarzy utworzyło szpaler honorowy ($durationSeconds s) przed startem $raceName.',
    );
  }

  /// Rejestruje szpaler honorowy w rekordzie legendy.
  FarewellLegendRecord triggerPelotonGuardOfHonor(
    FarewellLegendRecord record, {
    String? raceId,
    String? raceName,
    String stageOrLocation = 'Linia startu — KM 0.0',
    int pelotonSize = 176,
    DateTime? eventDate,
  }) {
    final resolvedRaceId = (raceId ?? record.finalRaceId ?? 'final_race').trim();
    final resolvedRaceName =
        (raceName ?? record.finalRaceName ?? 'Il Lombardia — Wyścig Pożegnalny')
            .trim();

    final guard = buildGuardOfHonorEvent(
      record: record,
      raceId: resolvedRaceId,
      raceName: resolvedRaceName,
      stageOrLocation: stageOrLocation,
      pelotonSize: pelotonSize,
      eventDate: eventDate,
    );

    final nextPhase =
        (record.phase == FarewellPhase.announcedFinalSeason ||
            record.phase == FarewellPhase.finalRaceScheduled)
        ? FarewellPhase.guardOfHonorPerformed
        : record.phase;

    return record.copyWith(
      finalRaceId: resolvedRaceId,
      finalRaceName: resolvedRaceName,
      guardOfHonor: guard,
      phase: nextPhase,
    );
  }

  /// Mapuje specjalizację kolarza na filozofię taktyczną w wozie technicznym.
  DirectorTacticalPhilosophy mapSpecializationToPhilosophy(
    RiderSpecialization specialization,
  ) {
    switch (specialization) {
      case RiderSpecialization.gcClimber:
      case RiderSpecialization.pureClimber:
      case RiderSpecialization.timeTrialist:
        return DirectorTacticalPhilosophy.gcCalculator;
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        return DirectorTacticalPhilosophy.sprinterTrainSpecialist;
      case RiderSpecialization.breakawaySpecialist:
        return DirectorTacticalPhilosophy.breakawayGambler;
      case RiderSpecialization.classicCobbles:
      case RiderSpecialization.puncher:
        return DirectorTacticalPhilosophy.aggressiveAttacking;
      case RiderSpecialization.domestiqueEngine:
        return DirectorTacticalPhilosophy.cautiousDefensive;
    }
  }

  /// Konwertuje kończącego karierę kolarza w gotowego kandydata na Dyrektora Sportowego.
  SportsDirector buildSportsDirectorCandidate(
    Rider rider, {
    required FarewellLegendRecord record,
    int contractYears = 2,
    DateTime? retiredAt,
  }) {
    final retirementDate =
        retiredAt ?? DateTime(record.seasonYear, 10, 31);
    final age = calculateAgeAt(rider.birthDate, retirementDate);
    final tenureBonus = (record.yearsWithCurrentTeam * 1.4).round().clamp(0, 14);
    final ovrBonus = ((rider.overallRating - 70) * 0.45).round().clamp(0, 15);

    final tacticalInsight =
        (rider.skills.raceIq * 0.72 + 18 + tenureBonus * 0.6)
            .round()
            .clamp(55, 99);
    final convoyDriving =
        (rider.skills.bikeHandling * 0.55 +
                rider.skills.descending * 0.25 +
                16)
            .round()
            .clamp(52, 98);
    final charisma =
        (rider.contract.leaderLoyalty * 0.50 +
                rider.overallRating * 0.35 +
                12)
            .round()
            .clamp(55, 99);
    final radioClarity =
        (rider.skills.raceIq * 0.55 +
                rider.skills.draftingEfficiency * 0.25 +
                16)
            .round()
            .clamp(55, 98);

    final experienceLevel =
        ((tacticalInsight + convoyDriving + charisma + radioClarity) / 4.0)
            .round()
            .clamp(58, 97);

    final reputation =
        (58 +
                ovrBonus +
                (record.careerPointsUci ~/ 800).clamp(0, 22))
            .clamp(55, 99);

    final baseMonthlySalary =
        5500 + (experienceLevel * 75) + (reputation * 35);
    final loyaltyDiscount = record.yearsWithCurrentTeam >= 5 ? 0.85 : 1.0;
    final finalMonthlySalary =
        ((baseMonthlySalary * loyaltyDiscount) / 100).round() * 100;

    return SportsDirector(
      id: 'ds_legend_${rider.id}',
      firstName: rider.firstName,
      lastName: rider.lastName,
      nationalityIso: rider.nationalityIso,
      age: math.max(kMinTestimonialFarewellAge, age),
      experienceLevel: experienceLevel,
      monthlySalaryEur: finalMonthlySalary,
      contractEndYear: record.seasonYear + contractYears.clamp(1, 5),
      morale: 95.0,
      reputation: reputation,
      specialTraits: <String>[
        'Była Legenda Peletonu',
        'Odznaka Final Season (${record.seasonYear})',
        if (record.yearsWithCurrentTeam >= 5) 'Lojalność Klubowa',
      ],
      convoyCarDrivingSkill: convoyDriving,
      tacticalAiInsight: tacticalInsight,
      preRaceBriefingCharisma: charisma,
      radioCommunicationClarity: radioClarity,
      tacticalPhilosophy: mapSpecializationToPhilosophy(rider.specialization),
    );
  }

  /// Zamyka karierę zawodniczą i generuje natychmiastową ofertę objęcia funkcji Dyrektora Sportowego.
  FarewellLegendRecord completeCareerAndGenerateDsOffer(
    FarewellLegendRecord record,
    Rider rider, {
    int contractYears = 2,
    DateTime? retiredAt,
  }) {
    final safeYears = contractYears.clamp(1, 5);
    final retirementDate = retiredAt ?? DateTime(record.seasonYear, 10, 31);
    final director = buildSportsDirectorCandidate(
      rider,
      record: record,
      contractYears: safeYears,
      retiredAt: retirementDate,
    );

    final loyaltyDiscount = record.yearsWithCurrentTeam >= 5;
    final signingBonus = loyaltyDiscount
        ? 0
        : (director.monthlySalaryEur * 1.5).round();

    final offer = SportsDirectorTransitionOffer(
      offerId: 'ds_offer_${rider.id}_${record.seasonYear}',
      riderId: rider.id,
      riderFullName: rider.fullName,
      proposedDirector: director,
      monthlySalaryEur: director.monthlySalaryEur,
      contractYears: safeYears,
      signingBonusEur: signingBonus,
      isLoyaltyDiscountApplied: loyaltyDiscount,
      expiresOnDate: retirementDate.add(const Duration(days: 30)),
    );

    return record.copyWith(
      phase: FarewellPhase.retiredPendingDsDecision,
      directorOffer: offer,
      retiredAt: retirementDate,
    );
  }

  /// Natychmiast zatrudnia emerytowaną legendę na stanowisku Dyrektora Sportowego.
  FarewellDirectorHireResult hireLegendAsSportsDirector(
    FarewellLegendRecord record, {
    int? overrideSalaryEur,
    int? overrideContractYears,
  }) {
    final offer = record.directorOffer;
    if (offer == null ||
        record.phase != FarewellPhase.retiredPendingDsDecision) {
      throw StateError(
        'Brak aktywnej oferty przejścia na stanowisko Dyrektora Sportowego dla ${record.riderFullName}.',
      );
    }

    final base = offer.proposedDirector;
    final years = (overrideContractYears ?? offer.contractYears).clamp(1, 5);
    final salary = overrideSalaryEur != null && overrideSalaryEur >= 2000
        ? overrideSalaryEur
        : offer.monthlySalaryEur;

    final hired = SportsDirector(
      id: base.id,
      firstName: base.firstName,
      lastName: base.lastName,
      nationalityIso: base.nationalityIso,
      age: base.age,
      experienceLevel: base.experienceLevel,
      monthlySalaryEur: salary,
      contractEndYear: record.seasonYear + years,
      morale: 98.0,
      reputation: base.reputation,
      specialTraits: base.specialTraits,
      convoyCarDrivingSkill: base.convoyCarDrivingSkill,
      tacticalAiInsight: base.tacticalAiInsight,
      preRaceBriefingCharisma: base.preRaceBriefingCharisma,
      radioCommunicationClarity: base.radioCommunicationClarity,
      tacticalPhilosophy: base.tacticalPhilosophy,
    );

    final updated = record.copyWith(
      phase: FarewellPhase.hiredAsSportsDirector,
      hiredDirector: hired,
    );

    return FarewellDirectorHireResult(
      updatedRecord: updated,
      hiredDirector: hired,
      initialCostEur: offer.signingBonusEur + salary,
    );
  }

  /// Odrzuca ofertę pracy w sztabie — kolarz przechodzi na zasłużoną emeryturę poza sportem.
  FarewellLegendRecord declineSportsDirectorOffer(
    FarewellLegendRecord record,
  ) {
    if (record.phase == FarewellPhase.hiredAsSportsDirector) {
      return record;
    }
    return record.copyWith(
      phase: FarewellPhase.retiredToPrivateLife,
    );
  }

  /// Generuje zbiorcze statystyki wszystkich pożegnań legend w klubie.
  FarewellSeasonAuditSummary buildSummary(List<FarewellLegendRecord> records) {
    int activeFinalSeason = 0;
    int guardsCompleted = 0;
    int pendingDs = 0;
    int hiredDs = 0;

    for (final r in records) {
      if (r.phase == FarewellPhase.announcedFinalSeason ||
          r.phase == FarewellPhase.finalRaceScheduled ||
          r.phase == FarewellPhase.guardOfHonorPerformed) {
        activeFinalSeason++;
      }
      if (r.guardOfHonor != null) {
        guardsCompleted++;
      }
      if (r.phase == FarewellPhase.retiredPendingDsDecision) {
        pendingDs++;
      }
      if (r.phase == FarewellPhase.hiredAsSportsDirector) {
        hiredDs++;
      }
    }

    return FarewellSeasonAuditSummary(
      totalLegends: records.length,
      activeFinalSeasonCount: activeFinalSeason,
      guardOfHonorCompletedCount: guardsCompleted,
      pendingDsDecisionCount: pendingDs,
      hiredAsDsCount: hiredDs,
    );
  }
}

/// Produkcyjny, responsywny panel zarządzania pożegnalnym sezonem legend (`Final Season`),
/// szpalerem honorowym peletonu oraz natychmiastowym zatrudnieniem w roli Dyrektora Sportowego.
class TestimonialFarewellRacePanel extends StatefulWidget {
  final List<FarewellLegendRecord> records;
  final ValueChanged<FarewellLegendRecord>? onTriggerGuardOfHonor;
  final ValueChanged<FarewellLegendRecord>? onHireAsSportsDirector;
  final ValueChanged<FarewellLegendRecord>? onDeclineDirectorOffer;

  const TestimonialFarewellRacePanel({
    super.key,
    required this.records,
    this.onTriggerGuardOfHonor,
    this.onHireAsSportsDirector,
    this.onDeclineDirectorOffer,
  });

  @override
  State<TestimonialFarewellRacePanel> createState() =>
      _TestimonialFarewellRacePanelState();
}

class _TestimonialFarewellRacePanelState
    extends State<TestimonialFarewellRacePanel> {
  final TestimonialFarewellRaceService _service =
      const TestimonialFarewellRaceService();
  String? _selectedRiderId;

  FarewellLegendRecord? get _selectedRecord {
    if (widget.records.isEmpty) return null;
    if (_selectedRiderId == null) return widget.records.first;
    for (final record in widget.records) {
      if (record.riderId == _selectedRiderId) return record;
    }
    return widget.records.first;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _service.buildSummary(widget.records);
    final selected = _selectedRecord;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final isWide = constraints.maxWidth >= 1100;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isCompact ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FarewellHeaderBanner(
                  summary: summary,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                if (widget.records.isEmpty)
                  const _EmptyFarewellState()
                else if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 340,
                        child: _LegendsRosterColumn(
                          records: widget.records,
                          selectedRiderId: selected?.riderId,
                          onSelect: (id) =>
                              setState(() => _selectedRiderId = id),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: selected == null
                            ? const SizedBox.shrink()
                            : _LegendDetailWorkspace(
                                record: selected,
                                isCompact: false,
                                onTriggerGuardOfHonor:
                                    widget.onTriggerGuardOfHonor,
                                onHireAsSportsDirector:
                                    widget.onHireAsSportsDirector,
                                onDeclineDirectorOffer:
                                    widget.onDeclineDirectorOffer,
                              ),
                      ),
                    ],
                  )
                else ...[
                  _LegendsRosterColumn(
                    records: widget.records,
                    selectedRiderId: selected?.riderId,
                    onSelect: (id) => setState(() => _selectedRiderId = id),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 16),
                    _LegendDetailWorkspace(
                      record: selected,
                      isCompact: isCompact,
                      onTriggerGuardOfHonor: widget.onTriggerGuardOfHonor,
                      onHireAsSportsDirector: widget.onHireAsSportsDirector,
                      onDeclineDirectorOffer: widget.onDeclineDirectorOffer,
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FarewellHeaderBanner extends StatelessWidget {
  final FarewellSeasonAuditSummary summary;
  final bool isCompact;

  const _FarewellHeaderBanner({
    required this.summary,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: AppColors.goldAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pożegnanie Legend Peletonu',
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
                      'Final Season (≥36 lat) • Szpaler Honorowy • Przejście na DS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 11.5 : 12.5,
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
              _MetricChip(
                label: 'Legendy',
                value: '${summary.totalLegends}',
                color: AppColors.goldAccent,
              ),
              _MetricChip(
                label: 'Szpalery',
                value: '${summary.guardOfHonorCompletedCount}',
                color: AppColors.amberWarning,
              ),
              _MetricChip(
                label: 'Nowi DS',
                value: '${summary.hiredAsDsCount}',
                color: AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
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
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
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
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendsRosterColumn extends StatelessWidget {
  final List<FarewellLegendRecord> records;
  final String? selectedRiderId;
  final ValueChanged<String> onSelect;

  const _LegendsRosterColumn({
    required this.records,
    required this.selectedRiderId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < records.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _LegendSelectorCard(
            record: records[i],
            isSelected: records[i].riderId == selectedRiderId,
            onTap: () => onSelect(records[i].riderId),
          ),
        ],
      ],
    );
  }
}

class _LegendSelectorCard extends StatefulWidget {
  final FarewellLegendRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  const _LegendSelectorCard({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LegendSelectorCard> createState() => _LegendSelectorCardState();
}

class _LegendSelectorCardState extends State<_LegendSelectorCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? AppColors.goldAccent
        : _focused
        ? AppColors.accentBlue
        : _hovered
        ? AppColors.goldAccent.withValues(alpha: 0.55)
        : AppColors.cardBorder;

    final bgColor = widget.isSelected
        ? AppColors.surfaceLight
        : _pressed
        ? AppColors.surfaceLight.withValues(alpha: 0.85)
        : _hovered
        ? AppColors.surfaceLight.withValues(alpha: 0.65)
        : AppColors.surface;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
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
                  Expanded(
                    child: Text(
                      widget.record.riderFullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FinalSeasonPillBadge(
                    seasonYear: widget.record.seasonYear,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.record.ageAtAnnouncement} lat • ${widget.record.badge.tier.label} • ${widget.record.yearsWithCurrentTeam} lat w ekipie',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.record.phase.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.record.phase.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: widget.record.phase.statusColor,
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

class _FinalSeasonPillBadge extends StatelessWidget {
  final int seasonYear;

  const _FinalSeasonPillBadge({required this.seasonYear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        'FINAL SEASON $seasonYear',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: AppColors.goldAccent,
        ),
      ),
    );
  }
}

class _LegendDetailWorkspace extends StatelessWidget {
  final FarewellLegendRecord record;
  final bool isCompact;
  final ValueChanged<FarewellLegendRecord>? onTriggerGuardOfHonor;
  final ValueChanged<FarewellLegendRecord>? onHireAsSportsDirector;
  final ValueChanged<FarewellLegendRecord>? onDeclineDirectorOffer;

  const _LegendDetailWorkspace({
    required this.record,
    required this.isCompact,
    this.onTriggerGuardOfHonor,
    this.onHireAsSportsDirector,
    this.onDeclineDirectorOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GuardOfHonorSectionCard(
          record: record,
          isCompact: isCompact,
          onTriggerGuardOfHonor: onTriggerGuardOfHonor,
        ),
        const SizedBox(height: 14),
        _SportsDirectorTransitionCard(
          record: record,
          isCompact: isCompact,
          onHireAsSportsDirector: onHireAsSportsDirector,
          onDeclineDirectorOffer: onDeclineDirectorOffer,
        ),
      ],
    );
  }
}

class _GuardOfHonorSectionCard extends StatelessWidget {
  final FarewellLegendRecord record;
  final bool isCompact;
  final ValueChanged<FarewellLegendRecord>? onTriggerGuardOfHonor;

  const _GuardOfHonorSectionCard({
    required this.record,
    required this.isCompact,
    this.onTriggerGuardOfHonor,
  });

  @override
  Widget build(BuildContext context) {
    final guard = record.guardOfHonor;
    final canTrigger =
        guard == null && onTriggerGuardOfHonor != null;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
                  const Icon(
                    Icons.flag_rounded,
                    color: AppColors.amberWarning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Szpaler Honorowy Peletonu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 14.5 : 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              _FarewellActionButton(
                label: guard != null
                    ? 'Szpaler Odbyty'
                    : 'Rozpocznij Szpaler Honorowy',
                icon: guard != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.celebration_rounded,
                accentColor: AppColors.goldAccent,
                enabled: canTrigger,
                onPressed: canTrigger
                    ? () => onTriggerGuardOfHonor!(record)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (guard == null)
            Text(
              record.finalRaceName != null
                  ? 'Zaplanowany ostatni wyścig: ${record.finalRaceName}. Peleton odda hołd legendzie na linii startu.'
                  : 'Wyznacz ostatni wyścig w sezonie, aby peleton ustawił szpaler honorowy przed startem.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${guard.raceName} • ${guard.stageOrLocation}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    guard.tributeSummary,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetricChip(
                        label: 'Morale Ekipy',
                        value: '+${guard.moraleBoostApplied.toStringAsFixed(0)}%',
                        color: AppColors.statusSuccess,
                      ),
                      _MetricChip(
                        label: 'Hołd Kibiców',
                        value: '${guard.fanTributeIndex}/100',
                        color: AppColors.cyanAccent,
                      ),
                    ],
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

class _SportsDirectorTransitionCard extends StatelessWidget {
  final FarewellLegendRecord record;
  final bool isCompact;
  final ValueChanged<FarewellLegendRecord>? onHireAsSportsDirector;
  final ValueChanged<FarewellLegendRecord>? onDeclineDirectorOffer;

  const _SportsDirectorTransitionCard({
    required this.record,
    required this.isCompact,
    this.onHireAsSportsDirector,
    this.onDeclineDirectorOffer,
  });

  @override
  Widget build(BuildContext context) {
    final offer = record.directorOffer;
    final hired = record.hiredDirector;
    final ds = hired ?? offer?.proposedDirector;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
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
              const Icon(
                Icons.headset_mic_rounded,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Przejście do Sztabu — Dyrektor Sportowy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 14.5 : 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ds == null)
            const Text(
              'Oferta objęcia stanowiska Dyrektora Sportowego zostanie wygenerowana natychmiast po zakończeniu kariery zawodniczej.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'Taktyka AI',
                  value: '${ds.tacticalAiInsight}',
                  color: AppColors.goldAccent,
                ),
                _MetricChip(
                  label: 'Wóz Techniczny',
                  value: '${ds.convoyCarDrivingSkill}',
                  color: AppColors.accentBlue,
                ),
                _MetricChip(
                  label: 'Charyzma',
                  value: '${ds.preRaceBriefingCharisma}',
                  color: AppColors.cyanAccent,
                ),
                _MetricChip(
                  label: 'Pensja/mies.',
                  value: '€${ds.monthlySalaryEur}',
                  color: AppColors.statusSuccess,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Filozofia: ${ds.tacticalPhilosophy.displayName}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            if (hired != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusSuccess.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.statusSuccess,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${hired.fullName} objął funkcję Dyrektora Sportowego (kontrakt do ${hired.contractEndYear}).',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (record.phase == FarewellPhase.retiredToPrivateLife)
              const Text(
                'Kolarz odszedł na pełną emeryturę poza strukturami zespołu.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FarewellActionButton(
                    label: 'Zatrudnij jako Dyrektora Sportowego',
                    icon: Icons.person_add_alt_1_rounded,
                    accentColor: AppColors.statusSuccess,
                    enabled: record.canHireAsSportsDirector &&
                        onHireAsSportsDirector != null,
                    onPressed: record.canHireAsSportsDirector &&
                            onHireAsSportsDirector != null
                        ? () => onHireAsSportsDirector!(record)
                        : null,
                  ),
                  _FarewellActionButton(
                    label: 'Odrzuć Ofertę',
                    icon: Icons.close_rounded,
                    accentColor: AppColors.crimsonAlert,
                    enabled: record.canHireAsSportsDirector &&
                        onDeclineDirectorOffer != null,
                    onPressed: record.canHireAsSportsDirector &&
                            onDeclineDirectorOffer != null
                        ? () => onDeclineDirectorOffer!(record)
                        : null,
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _FarewellActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final VoidCallback? onPressed;

  const _FarewellActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_FarewellActionButton> createState() => _FarewellActionButtonState();
}

class _FarewellActionButtonState extends State<_FarewellActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null;
    final bgColor = !active
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
        ? widget.accentColor.withValues(alpha: 0.30)
        : _hovered
        ? widget.accentColor.withValues(alpha: 0.22)
        : widget.accentColor.withValues(alpha: 0.14);

    final borderColor = !active
        ? AppColors.cardBorder
        : _focused
        ? AppColors.accentBlue
        : widget.accentColor.withValues(alpha: _hovered ? 0.9 : 0.65);

    final fgColor = active ? widget.accentColor : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: active,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapUp: active ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTap: active ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFarewellState extends StatelessWidget {
  const _EmptyFarewellState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: AppColors.textSecondary,
            size: 32,
          ),
          SizedBox(height: 10),
          Text(
            'Brak kolarzy w pożegnalnym sezonie',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Gdy kolarz w wieku 36+ lat ogłosi swój ostatni sezon, pojawi się tutaj z odznaką Final Season.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
