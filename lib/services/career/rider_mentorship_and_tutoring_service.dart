// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_skills.dart';

/// Obszar tematyczny programu mentoringowego między weteranem a neoprofesjonalistą.
enum MentorshipFocusArea {
  tacticalRaceIq,
  pelotonPositioningAndDrafting,
  bikeHandlingAndDescending,
  cobblesAndCrosswinds,
  holisticRoadCaptaincy;

  String toJson() => name;

  static MentorshipFocusArea fromJson(String value) {
    return MentorshipFocusArea.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MentorshipFocusArea.holisticRoadCaptaincy,
    );
  }

  String get label {
    switch (this) {
      case MentorshipFocusArea.tacticalRaceIq:
        return 'Taktyka Wyścigowa (Race IQ)';
      case MentorshipFocusArea.pelotonPositioningAndDrafting:
        return 'Jazda w Peletonie & Drafting';
      case MentorshipFocusArea.bikeHandlingAndDescending:
        return 'Technika Roweru & Zjazdy';
      case MentorshipFocusArea.cobblesAndCrosswinds:
        return 'Bruk & Wachlarze na Wietrze';
      case MentorshipFocusArea.holisticRoadCaptaincy:
        return 'Kompleksowy Road Captain';
    }
  }

  String get shortLabel {
    switch (this) {
      case MentorshipFocusArea.tacticalRaceIq:
        return 'Taktyka';
      case MentorshipFocusArea.pelotonPositioningAndDrafting:
        return 'Peleton';
      case MentorshipFocusArea.bikeHandlingAndDescending:
        return 'Technika';
      case MentorshipFocusArea.cobblesAndCrosswinds:
        return 'Bruk/Wiatr';
      case MentorshipFocusArea.holisticRoadCaptaincy:
        return 'Road Captain';
    }
  }

  Color get accentColor {
    switch (this) {
      case MentorshipFocusArea.tacticalRaceIq:
        return AppColors.goldAccent;
      case MentorshipFocusArea.pelotonPositioningAndDrafting:
        return AppColors.cyanAccent;
      case MentorshipFocusArea.bikeHandlingAndDescending:
        return AppColors.accentBlue;
      case MentorshipFocusArea.cobblesAndCrosswinds:
        return AppColors.amberWarning;
      case MentorshipFocusArea.holisticRoadCaptaincy:
        return AppColors.statusSuccess;
    }
  }
}

/// Status kwalifikacji kolarza do pełnienia roli mentora lub podopiecznego.
enum MentorshipEligibilityStatus {
  eligible,
  ineligibleAge,
  ineligibleSkills,
  alreadyAssigned,
  sameRider,
  differentTeam;

  String get label {
    switch (this) {
      case MentorshipEligibilityStatus.eligible:
        return 'Kwalifikuje się';
      case MentorshipEligibilityStatus.ineligibleAge:
        return 'Niespełniony wymóg wieku';
      case MentorshipEligibilityStatus.ineligibleSkills:
        return 'Zbyt niskie Race IQ / Bike Handling';
      case MentorshipEligibilityStatus.alreadyAssigned:
        return 'Aktywny w innym mentoringu';
      case MentorshipEligibilityStatus.sameRider:
        return 'Ten sam kolarz';
      case MentorshipEligibilityStatus.differentTeam:
        return 'Inna drużyna';
    }
  }
}

/// Ocena przydatności weterana jako mentora (>32 lat, wysokie raceIq i bikeHandling).
class MentorCandidateAssessment {
  final Rider rider;
  final int ageYears;
  final int raceIq;
  final int bikeHandling;
  final int mentorRating;
  final String tierLabel;
  final MentorshipEligibilityStatus status;
  final List<String> reasons;

  const MentorCandidateAssessment({
    required this.rider,
    required this.ageYears,
    required this.raceIq,
    required this.bikeHandling,
    required this.mentorRating,
    required this.tierLabel,
    required this.status,
    required this.reasons,
  });

  bool get isEligible => status == MentorshipEligibilityStatus.eligible;
}

/// Ocena przydatności młodego kolarza (docelowo 19-letniego neoprofesjonalisty) jako podopiecznego.
class MenteeCandidateAssessment {
  final Rider rider;
  final int ageYears;
  final bool isNeoPro19;
  final int potentialHeadroom;
  final double tacticalAndPelotonAverage;
  final MentorshipEligibilityStatus status;
  final List<String> reasons;

  const MenteeCandidateAssessment({
    required this.rider,
    required this.ageYears,
    required this.isNeoPro19,
    required this.potentialHeadroom,
    required this.tacticalAndPelotonAverage,
    required this.status,
    required this.reasons,
  });

  bool get isEligible => status == MentorshipEligibilityStatus.eligible;
}

/// Analiza zgodności pary Mentor-Podopieczny i przyspieszenia rozwoju (+40%).
class MentorshipPairCompatibility {
  final String mentorId;
  final String menteeId;
  final MentorshipFocusArea focusArea;
  final int compatibilityScore; // 0..100
  final double baseAccelerationMultiplier; // 1.40 (+40%)
  final double synergyBonusMultiplier; // 0.00..0.15
  final double effectiveDevelopmentMultiplier; // >= 1.40 dla kwalifikujących się par
  final bool sameSpecialization;
  final bool sameNationality;
  final Map<String, int> projectedSeasonalSkillGains;
  final String summary;

  const MentorshipPairCompatibility({
    required this.mentorId,
    required this.menteeId,
    required this.focusArea,
    required this.compatibilityScore,
    required this.baseAccelerationMultiplier,
    required this.synergyBonusMultiplier,
    required this.effectiveDevelopmentMultiplier,
    required this.sameSpecialization,
    required this.sameNationality,
    required this.projectedSeasonalSkillGains,
    required this.summary,
  });

  int get accelerationPercent =>
      ((effectiveDevelopmentMultiplier - 1.0) * 100.0).round();
}

/// Aktywne lub zakończone przypisanie mentora do neoprofesjonalisty.
class MentorshipAssignment {
  final String id;
  final String mentorId;
  final String menteeId;
  final MentorshipFocusArea focusArea;
  final DateTime assignedDate;
  final int targetDurationDays;
  final int completedDays;
  final double tacticalAccelerationBonus; // 0.40 (+40%)
  final double pelotonAccelerationBonus; // 0.40 (+40%)
  final double tacticalProgressBank;
  final double pelotonProgressBank;
  final int cumulativeSkillPointsGained;
  final int sessionsCompleted;
  final bool isActive;
  final DateTime? lastSessionDate;

  const MentorshipAssignment({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.focusArea,
    required this.assignedDate,
    this.targetDurationDays = 180,
    this.completedDays = 0,
    this.tacticalAccelerationBonus =
        RiderMentorshipAndTutoringService.tacticalAndPelotonAccelerationBoost,
    this.pelotonAccelerationBonus =
        RiderMentorshipAndTutoringService.tacticalAndPelotonAccelerationBoost,
    this.tacticalProgressBank = 0.0,
    this.pelotonProgressBank = 0.0,
    this.cumulativeSkillPointsGained = 0,
    this.sessionsCompleted = 0,
    this.isActive = true,
    this.lastSessionDate,
  });

  double get progressRatio => targetDurationDays <= 0
      ? 1.0
      : (completedDays / targetDurationDays).clamp(0.0, 1.0);

  MentorshipAssignment copyWith({
    String? id,
    String? mentorId,
    String? menteeId,
    MentorshipFocusArea? focusArea,
    DateTime? assignedDate,
    int? targetDurationDays,
    int? completedDays,
    double? tacticalAccelerationBonus,
    double? pelotonAccelerationBonus,
    double? tacticalProgressBank,
    double? pelotonProgressBank,
    int? cumulativeSkillPointsGained,
    int? sessionsCompleted,
    bool? isActive,
    DateTime? lastSessionDate,
  }) {
    return MentorshipAssignment(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      menteeId: menteeId ?? this.menteeId,
      focusArea: focusArea ?? this.focusArea,
      assignedDate: assignedDate ?? this.assignedDate,
      targetDurationDays: targetDurationDays ?? this.targetDurationDays,
      completedDays: completedDays ?? this.completedDays,
      tacticalAccelerationBonus:
          tacticalAccelerationBonus ?? this.tacticalAccelerationBonus,
      pelotonAccelerationBonus:
          pelotonAccelerationBonus ?? this.pelotonAccelerationBonus,
      tacticalProgressBank: tacticalProgressBank ?? this.tacticalProgressBank,
      pelotonProgressBank: pelotonProgressBank ?? this.pelotonProgressBank,
      cumulativeSkillPointsGained:
          cumulativeSkillPointsGained ?? this.cumulativeSkillPointsGained,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      isActive: isActive ?? this.isActive,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentorId': mentorId,
      'menteeId': menteeId,
      'focusArea': focusArea.toJson(),
      'assignedDate': assignedDate.toIso8601String(),
      'targetDurationDays': targetDurationDays,
      'completedDays': completedDays,
      'tacticalAccelerationBonus': tacticalAccelerationBonus,
      'pelotonAccelerationBonus': pelotonAccelerationBonus,
      'tacticalProgressBank': tacticalProgressBank,
      'pelotonProgressBank': pelotonProgressBank,
      'cumulativeSkillPointsGained': cumulativeSkillPointsGained,
      'sessionsCompleted': sessionsCompleted,
      'isActive': isActive,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
    };
  }

  factory MentorshipAssignment.fromJson(Map<String, dynamic> json) {
    return MentorshipAssignment(
      id: json['id'] as String,
      mentorId: json['mentorId'] as String,
      menteeId: json['menteeId'] as String,
      focusArea: MentorshipFocusArea.fromJson(json['focusArea'] as String),
      assignedDate: DateTime.parse(json['assignedDate'] as String),
      targetDurationDays: (json['targetDurationDays'] as num?)?.toInt() ?? 180,
      completedDays: (json['completedDays'] as num?)?.toInt() ?? 0,
      tacticalAccelerationBonus:
          (json['tacticalAccelerationBonus'] as num?)?.toDouble() ?? 0.40,
      pelotonAccelerationBonus:
          (json['pelotonAccelerationBonus'] as num?)?.toDouble() ?? 0.40,
      tacticalProgressBank:
          (json['tacticalProgressBank'] as num?)?.toDouble() ?? 0.0,
      pelotonProgressBank:
          (json['pelotonProgressBank'] as num?)?.toDouble() ?? 0.0,
      cumulativeSkillPointsGained:
          (json['cumulativeSkillPointsGained'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (json['sessionsCompleted'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      lastSessionDate: json['lastSessionDate'] != null
          ? DateTime.parse(json['lastSessionDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MentorshipAssignment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Wynik próby przypisania mentora (walidacja reguł bez rzucania wyjątków).
class MentorshipAssignmentResult {
  final bool success;
  final MentorshipAssignment? assignment;
  final MentorshipEligibilityStatus? failureReason;
  final String message;

  const MentorshipAssignmentResult({
    required this.success,
    this.assignment,
    this.failureReason,
    required this.message,
  });
}

/// Wynik kroku rozwoju neoprofesjonalisty w ramach mentoringu.
class MentorshipProgressStepResult {
  final MentorshipAssignment updatedAssignment;
  final Rider updatedMentee;
  final Map<String, int> skillDeltas;
  final int totalPointsGainedThisStep;
  final double appliedDevelopmentMultiplier;
  final String summaryNote;

  const MentorshipProgressStepResult({
    required this.updatedAssignment,
    required this.updatedMentee,
    required this.skillDeltas,
    required this.totalPointsGainedThisStep,
    required this.appliedDevelopmentMultiplier,
    required this.summaryNote,
  });
}

/// Zbiorczy raport tablicy mentoringowej dla całego składu drużyny.
class MentorshipBoardReport {
  final List<MentorCandidateAssessment> mentorAssessments;
  final List<MenteeCandidateAssessment> menteeAssessments;
  final List<MentorshipAssignment> activeAssignments;
  final int eligibleMentorCount;
  final int eligibleNeoProCount;
  final int totalSkillPointsTransferred;

  const MentorshipBoardReport({
    required this.mentorAssessments,
    required this.menteeAssessments,
    required this.activeAssignments,
    required this.eligibleMentorCount,
    required this.eligibleNeoProCount,
    required this.totalSkillPointsTransferred,
  });
}

/// System mentoringu i opieki weteranów nad neoprofesjonalistami.
///
/// Doświadczony weteran (`> 32` lat, wysokie `raceIq` i `bikeHandling`)
/// przypisany jako mentor dla 19-letniego neoprofesjonalisty przyspiesza
/// rozwój umiejętności taktycznych (`raceIq`) oraz jazdy w peletonie
/// (`bikeHandling`, `draftingEfficiency`, `cobbles`, `descending`) o 40%.
class RiderMentorshipAndTutoringService {
  const RiderMentorshipAndTutoringService();

  /// Minimalny wiek mentora: ściśle > 32 lat (czyli >= 33 lata).
  static const int minMentorAgeExclusive = 32;

  /// Minimalne progi umiejętności taktycznych i jazdy w peletonie dla mentora.
  static const int minMentorRaceIq = 75;
  static const int minMentorBikeHandling = 75;

  /// Docelowy wiek neoprofesjonalisty oraz maksymalny dopuszczalny wiek podopiecznego.
  static const int neoProTargetAge = 19;
  static const int maxMenteeAge = 21;
  static const int minMenteeAge = 18;

  /// Bazowe przyspieszenie rozwoju umiejętności taktycznych i peletonowych (+40%).
  static const double tacticalAndPelotonAccelerationBoost = 0.40;
  static const double baseAcceleratedMultiplier = 1.40;

  /// Oblicza dokładny wiek kolarza na podaną datę referencyjną.
  int calculateAgeYears(DateTime birthDate, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return math.max(0, age);
  }

  /// Ocenia kolarza jako potencjalnego mentora.
  MentorCandidateAssessment assessMentorCandidate(
    Rider rider, {
    DateTime? referenceDate,
    Set<String> activeMentorIds = const <String>{},
  }) {
    final ageYears =
        calculateAgeYears(rider.birthDate, referenceDate: referenceDate);
    final raceIq = rider.skills.raceIq;
    final bikeHandling = rider.skills.bikeHandling;
    final reasons = <String>[];

    MentorshipEligibilityStatus status = MentorshipEligibilityStatus.eligible;

    if (activeMentorIds.contains(rider.id)) {
      status = MentorshipEligibilityStatus.alreadyAssigned;
      reasons.add('Weteran prowadzi już aktywny program mentoringowy.');
    } else if (ageYears <= minMentorAgeExclusive) {
      status = MentorshipEligibilityStatus.ineligibleAge;
      reasons.add(
        'Wymagany wiek > $minMentorAgeExclusive lat (obecnie $ageYears lat).',
      );
    }

    if (raceIq < minMentorRaceIq || bikeHandling < minMentorBikeHandling) {
      if (status == MentorshipEligibilityStatus.eligible) {
        status = MentorshipEligibilityStatus.ineligibleSkills;
      }
      reasons.add(
        'Wymagane Race IQ >= $minMentorRaceIq i Bike Handling >= $minMentorBikeHandling '
        '(obecnie $raceIq / $bikeHandling).',
      );
    }

    if (reasons.isEmpty) {
      reasons.add(
        'Spełnia wymogi weterana ($ageYears lat, Race IQ $raceIq, Bike Handling $bikeHandling).',
      );
    }

    final experienceBonus = ((ageYears - minMentorAgeExclusive).clamp(0, 8)) * 1.5;
    final mentorRating = ((raceIq * 0.48) +
            (bikeHandling * 0.37) +
            (rider.skills.draftingEfficiency * 0.15) +
            experienceBonus)
        .round()
        .clamp(1, 99);

    final String tierLabel;
    if (mentorRating >= 90) {
      tierLabel = 'Legenda Peletonu';
    } else if (mentorRating >= 82) {
      tierLabel = 'Elitarny Road Captain';
    } else {
      tierLabel = 'Doświadczony Weteran';
    }

    return MentorCandidateAssessment(
      rider: rider,
      ageYears: ageYears,
      raceIq: raceIq,
      bikeHandling: bikeHandling,
      mentorRating: mentorRating,
      tierLabel: tierLabel,
      status: status,
      reasons: reasons,
    );
  }

  /// Ocenia kolarza jako potencjalnego neoprofesjonalistę (podopiecznego).
  MenteeCandidateAssessment assessMenteeCandidate(
    Rider rider, {
    DateTime? referenceDate,
    Set<String> activeMenteeIds = const <String>{},
  }) {
    final ageYears =
        calculateAgeYears(rider.birthDate, referenceDate: referenceDate);
    final isNeoPro19 = ageYears == neoProTargetAge;
    final reasons = <String>[];

    MentorshipEligibilityStatus status = MentorshipEligibilityStatus.eligible;
    if (activeMenteeIds.contains(rider.id)) {
      status = MentorshipEligibilityStatus.alreadyAssigned;
      reasons.add('Kolarz ma już przypisanego mentora.');
    } else if (ageYears < minMenteeAge || ageYears > maxMenteeAge) {
      status = MentorshipEligibilityStatus.ineligibleAge;
      reasons.add(
        'Program dla neoprofesjonalistów obejmuje wiek $minMenteeAge–$maxMenteeAge lat '
        '(docelowo $neoProTargetAge lat, obecnie $ageYears lat).',
      );
    }

    if (reasons.isEmpty) {
      reasons.add(
        isNeoPro19
            ? '19-letni neoprofesjonalista — maksymalna podatność na mentoring (+40%).'
            : 'Młody talent ($ageYears lat) — kwalifikuje się do przyspieszonego rozwoju (+40%).',
      );
    }

    final tacticalPelotonAvg = (rider.skills.raceIq +
            rider.skills.bikeHandling +
            rider.skills.draftingEfficiency +
            rider.skills.cobbles +
            rider.skills.descending) /
        5.0;

    return MenteeCandidateAssessment(
      rider: rider,
      ageYears: ageYears,
      isNeoPro19: isNeoPro19,
      potentialHeadroom: math.max(0, rider.potential - rider.overallRating),
      tacticalAndPelotonAverage: tacticalPelotonAvg,
      status: status,
      reasons: reasons,
    );
  }

  /// Wylicza zgodność pary i realny mnożnik przyspieszenia rozwoju taktycznego i peletonowego.
  MentorshipPairCompatibility evaluateCompatibility({
    required Rider mentor,
    required Rider mentee,
    MentorshipFocusArea focusArea = MentorshipFocusArea.holisticRoadCaptaincy,
    DateTime? referenceDate,
  }) {
    final mentorAssessment =
        assessMentorCandidate(mentor, referenceDate: referenceDate);
    final menteeAssessment =
        assessMenteeCandidate(mentee, referenceDate: referenceDate);

    final sameSpec = mentor.specialization == mentee.specialization;
    final sameNat =
        mentor.nationalityIso.toUpperCase() == mentee.nationalityIso.toUpperCase();

    final iqGap = math.max(0, mentor.skills.raceIq - mentee.skills.raceIq);
    final handlingGap =
        math.max(0, mentor.skills.bikeHandling - mentee.skills.bikeHandling);
    final draftingGap = math.max(
      0,
      mentor.skills.draftingEfficiency - mentee.skills.draftingEfficiency,
    );

    int score = 58;
    if (sameSpec) score += 16;
    if (sameNat) score += 10;
    if (menteeAssessment.isNeoPro19) score += 8;
    score += ((iqGap + handlingGap) / 10.0).round().clamp(0, 12);
    score += ((mentorAssessment.mentorRating - 75) * 0.25).round().clamp(0, 8);
    score = score.clamp(25, 100);

    double synergyBonus = 0.0;
    if (sameSpec) synergyBonus += 0.05;
    if (sameNat) synergyBonus += 0.03;

    final effectiveMultiplier =
        baseAcceleratedMultiplier + synergyBonus; // min 1.40 (+40%)

    final projectedGains = <String, int>{
      'raceIq': _projectSeasonalGain(iqGap, focusArea, isTactical: true),
      'bikeHandling':
          _projectSeasonalGain(handlingGap, focusArea, isHandling: true),
      'draftingEfficiency':
          _projectSeasonalGain(draftingGap, focusArea, isDrafting: true),
    };

    final summary =
        'Przyspieszenie rozwoju taktyki i jazdy w peletonie o '
        '${((effectiveMultiplier - 1.0) * 100).round()}% '
        '(${sameSpec ? 'zgodna specjalizacja' : 'transfer uniwersalny'}${sameNat ? ', wspólny język' : ''}).';

    return MentorshipPairCompatibility(
      mentorId: mentor.id,
      menteeId: mentee.id,
      focusArea: focusArea,
      compatibilityScore: score,
      baseAccelerationMultiplier: baseAcceleratedMultiplier,
      synergyBonusMultiplier: synergyBonus,
      effectiveDevelopmentMultiplier: effectiveMultiplier,
      sameSpecialization: sameSpec,
      sameNationality: sameNat,
      projectedSeasonalSkillGains: projectedGains,
      summary: summary,
    );
  }

  int _projectSeasonalGain(
    int gap,
    MentorshipFocusArea focusArea, {
    bool isTactical = false,
    bool isHandling = false,
    bool isDrafting = false,
  }) {
    if (gap <= 0) return 2;
    double base = 3.0 + (gap * 0.14);
    if (isTactical && focusArea == MentorshipFocusArea.tacticalRaceIq) {
      base *= 1.25;
    } else if (isHandling &&
        focusArea == MentorshipFocusArea.bikeHandlingAndDescending) {
      base *= 1.25;
    } else if (isDrafting &&
        focusArea == MentorshipFocusArea.pelotonPositioningAndDrafting) {
      base *= 1.25;
    }
    return base.round().clamp(2, 12);
  }

  /// Próbuje utworzyć przypisanie mentoringowe po walidacji wieku, umiejętności i przynależności.
  MentorshipAssignmentResult tryAssignMentor({
    required Rider mentor,
    required Rider mentee,
    required List<MentorshipAssignment> existingAssignments,
    MentorshipFocusArea focusArea = MentorshipFocusArea.holisticRoadCaptaincy,
    DateTime? assignedDate,
    int targetDurationDays = 180,
    bool requireSameTeam = true,
  }) {
    if (mentor.id == mentee.id) {
      return const MentorshipAssignmentResult(
        success: false,
        failureReason: MentorshipEligibilityStatus.sameRider,
        message: 'Kolarz nie może być mentorem dla samego siebie.',
      );
    }

    if (requireSameTeam && mentor.teamId != mentee.teamId) {
      return const MentorshipAssignmentResult(
        success: false,
        failureReason: MentorshipEligibilityStatus.differentTeam,
        message: 'Mentor i neoprofesjonalista muszą należeć do tej samej drużyny.',
      );
    }

    final activeMentorIds = existingAssignments
        .where((a) => a.isActive)
        .map((a) => a.mentorId)
        .toSet();
    final activeMenteeIds = existingAssignments
        .where((a) => a.isActive)
        .map((a) => a.menteeId)
        .toSet();

    final effectiveDate = assignedDate ?? DateTime.now();
    final mentorCheck = assessMentorCandidate(
      mentor,
      referenceDate: effectiveDate,
      activeMentorIds: activeMentorIds,
    );
    if (!mentorCheck.isEligible) {
      return MentorshipAssignmentResult(
        success: false,
        failureReason: mentorCheck.status,
        message: mentorCheck.reasons.join(' '),
      );
    }

    final menteeCheck = assessMenteeCandidate(
      mentee,
      referenceDate: effectiveDate,
      activeMenteeIds: activeMenteeIds,
    );
    if (!menteeCheck.isEligible) {
      return MentorshipAssignmentResult(
        success: false,
        failureReason: menteeCheck.status,
        message: menteeCheck.reasons.join(' '),
      );
    }

    final assignment = MentorshipAssignment(
      id: 'mentor_${mentor.id}_${mentee.id}_${effectiveDate.millisecondsSinceEpoch}',
      mentorId: mentor.id,
      menteeId: mentee.id,
      focusArea: focusArea,
      assignedDate: effectiveDate,
      targetDurationDays: math.max(30, targetDurationDays),
      tacticalAccelerationBonus: tacticalAndPelotonAccelerationBoost,
      pelotonAccelerationBonus: tacticalAndPelotonAccelerationBoost,
      isActive: true,
    );

    return MentorshipAssignmentResult(
      success: true,
      assignment: assignment,
      message:
          '${mentor.fullName} został mentorem dla ${mentee.fullName} (+40% rozwoju taktyki i jazdy w peletonie).',
    );
  }

  /// Oblicza przyspieszony o +40% przyrost umiejętności taktycznych i peletonowych
  /// w zadanym okresie treningowym lub wyścigowym.
  MentorshipProgressStepResult applyMentorshipDevelopmentTick({
    required MentorshipAssignment assignment,
    required Rider mentor,
    required Rider mentee,
    required int daysElapsed,
    bool racedTogether = false,
    DateTime? sessionDate,
  }) {
    if (!assignment.isActive || daysElapsed <= 0) {
      return MentorshipProgressStepResult(
        updatedAssignment: assignment,
        updatedMentee: mentee,
        skillDeltas: const <String, int>{},
        totalPointsGainedThisStep: 0,
        appliedDevelopmentMultiplier: 1.0,
        summaryNote: 'Mentoring nieaktywny lub brak dni do przetworzenia.',
      );
    }

    final compatibility = evaluateCompatibility(
      mentor: mentor,
      mentee: mentee,
      focusArea: assignment.focusArea,
      referenceDate: sessionDate ?? assignment.assignedDate,
    );

    // Bazowy postęp dzienny bez mentora ~0.045 pkt taktyki/peletonu dziennie;
    // z mentorem przyspiesza o +40% (mnożnik >= 1.40), a wspólne wyścigi dodają 35% impulsu.
    final raceFactor = racedTogether ? 1.35 : 1.0;
    final multiplier = compatibility.effectiveDevelopmentMultiplier;
    final baseDailyRate = 0.045 * daysElapsed * raceFactor;

    final tacticalGainRaw = baseDailyRate *
        multiplier *
        (assignment.focusArea == MentorshipFocusArea.tacticalRaceIq
            ? 1.25
            : 1.0);
    final pelotonGainRaw = baseDailyRate *
        multiplier *
        (assignment.focusArea ==
                MentorshipFocusArea.pelotonPositioningAndDrafting
            ? 1.25
            : 1.0);

    double newTacticalBank = assignment.tacticalProgressBank + tacticalGainRaw;
    double newPelotonBank = assignment.pelotonProgressBank + pelotonGainRaw;

    final int iqDelta = newTacticalBank.floor();
    newTacticalBank -= iqDelta;

    final int pelotonPoints = newPelotonBank.floor();
    newPelotonBank -= pelotonPoints;

    final deltas = <String, int>{};
    RiderSkills updatedSkills = mentee.skills;

    if (iqDelta > 0) {
      final targetCap = math.min(99, math.max(mentee.skills.raceIq, mentor.skills.raceIq));
      final nextIq = math.min(targetCap, mentee.skills.raceIq + iqDelta);
      final actualDelta = nextIq - mentee.skills.raceIq;
      if (actualDelta > 0) {
        updatedSkills = updatedSkills.copyWith(raceIq: nextIq);
        deltas['raceIq'] = actualDelta;
      }
    }

    if (pelotonPoints > 0) {
      updatedSkills = _distributePelotonPoints(
        skills: updatedSkills,
        mentorSkills: mentor.skills,
        points: pelotonPoints,
        focusArea: assignment.focusArea,
        deltasOut: deltas,
      );
    }

    final totalStepGain = deltas.values.fold<int>(0, (sum, v) => sum + v);
    final nextCompletedDays = assignment.completedDays + daysElapsed;
    final stillActive = nextCompletedDays < assignment.targetDurationDays;

    final updatedAssignment = assignment.copyWith(
      completedDays: nextCompletedDays,
      tacticalProgressBank: newTacticalBank,
      pelotonProgressBank: newPelotonBank,
      cumulativeSkillPointsGained:
          assignment.cumulativeSkillPointsGained + totalStepGain,
      sessionsCompleted: assignment.sessionsCompleted + 1,
      isActive: stillActive,
      lastSessionDate: sessionDate ?? DateTime.now(),
    );

    final updatedMentee = mentee.copyWith(skills: updatedSkills);

    final summaryNote = totalStepGain > 0
        ? '${mentee.fullName} zyskał +$totalStepGain pkt umiejętności dzięki opiece ${mentor.fullName} (tempo x${multiplier.toStringAsFixed(2)}).'
        : 'Sesja mentoringowa ukończona (+${daysElapsed}d, kumulacja wiedzy taktycznej w toku).';

    return MentorshipProgressStepResult(
      updatedAssignment: updatedAssignment,
      updatedMentee: updatedMentee,
      skillDeltas: deltas,
      totalPointsGainedThisStep: totalStepGain,
      appliedDevelopmentMultiplier: multiplier,
      summaryNote: summaryNote,
    );
  }

  RiderSkills _distributePelotonPoints({
    required RiderSkills skills,
    required RiderSkills mentorSkills,
    required int points,
    required MentorshipFocusArea focusArea,
    required Map<String, int> deltasOut,
  }) {
    var current = skills;
    final order = switch (focusArea) {
      MentorshipFocusArea.pelotonPositioningAndDrafting => [
          'draftingEfficiency',
          'bikeHandling',
          'cobbles',
          'descending',
        ],
      MentorshipFocusArea.bikeHandlingAndDescending => [
          'bikeHandling',
          'descending',
          'draftingEfficiency',
          'cobbles',
        ],
      MentorshipFocusArea.cobblesAndCrosswinds => [
          'cobbles',
          'bikeHandling',
          'draftingEfficiency',
          'descending',
        ],
      _ => [
          'bikeHandling',
          'draftingEfficiency',
          'descending',
          'cobbles',
        ],
    };

    for (var i = 0; i < points; i++) {
      final stat = order[i % order.length];
      switch (stat) {
        case 'bikeHandling':
          final cap = math.min(99, math.max(current.bikeHandling, mentorSkills.bikeHandling));
          if (current.bikeHandling < cap) {
            current = current.copyWith(bikeHandling: current.bikeHandling + 1);
            deltasOut['bikeHandling'] = (deltasOut['bikeHandling'] ?? 0) + 1;
          }
          break;
        case 'draftingEfficiency':
          final cap = math.min(
            99,
            math.max(current.draftingEfficiency, mentorSkills.draftingEfficiency),
          );
          if (current.draftingEfficiency < cap) {
            current = current.copyWith(
              draftingEfficiency: current.draftingEfficiency + 1,
            );
            deltasOut['draftingEfficiency'] =
                (deltasOut['draftingEfficiency'] ?? 0) + 1;
          }
          break;
        case 'descending':
          final cap = math.min(99, math.max(current.descending, mentorSkills.descending));
          if (current.descending < cap) {
            current = current.copyWith(descending: current.descending + 1);
            deltasOut['descending'] = (deltasOut['descending'] ?? 0) + 1;
          }
          break;
        case 'cobbles':
          final cap = math.min(99, math.max(current.cobbles, mentorSkills.cobbles));
          if (current.cobbles < cap) {
            current = current.copyWith(cobbles: current.cobbles + 1);
            deltasOut['cobbles'] = (deltasOut['cobbles'] ?? 0) + 1;
          }
          break;
      }
    }
    return current;
  }

  /// Zamyka aktywne przypisanie mentoringowe.
  List<MentorshipAssignment> terminateMentorship({
    required List<MentorshipAssignment> assignments,
    required String assignmentId,
  }) {
    return assignments
        .map((a) => a.id == assignmentId ? a.copyWith(isActive: false) : a)
        .toList();
  }

  /// Buduje kompletny raport tablicy mentoringowej dla składu drużyny.
  MentorshipBoardReport buildBoardReport({
    required List<Rider> roster,
    required List<MentorshipAssignment> activeAssignments,
    DateTime? referenceDate,
  }) {
    final activeMentorIds =
        activeAssignments.where((a) => a.isActive).map((a) => a.mentorId).toSet();
    final activeMenteeIds =
        activeAssignments.where((a) => a.isActive).map((a) => a.menteeId).toSet();

    final mentors = roster
        .map(
          (r) => assessMentorCandidate(
            r,
            referenceDate: referenceDate,
            activeMentorIds: activeMentorIds,
          ),
        )
        .where((a) => a.ageYears > minMentorAgeExclusive || a.isEligible)
        .toList()
      ..sort((a, b) => b.mentorRating.compareTo(a.mentorRating));

    final mentees = roster
        .map(
          (r) => assessMenteeCandidate(
            r,
            referenceDate: referenceDate,
            activeMenteeIds: activeMenteeIds,
          ),
        )
        .where((a) => a.ageYears <= maxMenteeAge)
        .toList()
      ..sort((a, b) => a.ageYears.compareTo(b.ageYears));

    final totalTransferred = activeAssignments.fold<int>(
      0,
      (sum, a) => sum + a.cumulativeSkillPointsGained,
    );

    return MentorshipBoardReport(
      mentorAssessments: mentors,
      menteeAssessments: mentees,
      activeAssignments: activeAssignments.where((a) => a.isActive).toList(),
      eligibleMentorCount: mentors.where((m) => m.isEligible).length,
      eligibleNeoProCount: mentees.where((m) => m.isEligible).length,
      totalSkillPointsTransferred: totalTransferred,
    );
  }
}

/// Produkcyjny, responsywny panel zarządzania mentoringiem weteranów i 19-letnich neoprofesjonalistów.
class RiderMentorshipAndTutoringPanel extends StatefulWidget {
  final List<Rider> roster;
  final List<MentorshipAssignment> initialAssignments;
  final ValueChanged<List<MentorshipAssignment>>? onAssignmentsChanged;
  final ValueChanged<Rider>? onMenteeProgressed;
  final RiderMentorshipAndTutoringService service;

  const RiderMentorshipAndTutoringPanel({
    super.key,
    required this.roster,
    this.initialAssignments = const <MentorshipAssignment>[],
    this.onAssignmentsChanged,
    this.onMenteeProgressed,
    this.service = const RiderMentorshipAndTutoringService(),
  });

  @override
  State<RiderMentorshipAndTutoringPanel> createState() =>
      _RiderMentorshipAndTutoringPanelState();
}

class _RiderMentorshipAndTutoringPanelState
    extends State<RiderMentorshipAndTutoringPanel> {
  late List<Rider> _roster;
  late List<MentorshipAssignment> _assignments;
  String? _selectedMentorId;
  String? _selectedMenteeId;
  MentorshipFocusArea _selectedFocus =
      MentorshipFocusArea.holisticRoadCaptaincy;
  String? _statusBanner;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _roster = List<Rider>.from(widget.roster);
    _assignments = List<MentorshipAssignment>.from(widget.initialAssignments);
    _autoSelectInitialCandidates();
  }

  @override
  void didUpdateWidget(covariant RiderMentorshipAndTutoringPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roster != widget.roster) {
      _roster = List<Rider>.from(widget.roster);
      _autoSelectInitialCandidates();
    }
  }

  void _autoSelectInitialCandidates() {
    final report = widget.service.buildBoardReport(
      roster: _roster,
      activeAssignments: _assignments,
    );
    if (_selectedMentorId == null ||
        !_roster.any((r) => r.id == _selectedMentorId)) {
      final eligibleMentor =
          report.mentorAssessments.where((m) => m.isEligible).firstOrNull;
      _selectedMentorId = eligibleMentor?.rider.id;
    }
    if (_selectedMenteeId == null ||
        !_roster.any((r) => r.id == _selectedMenteeId)) {
      final eligibleMentee =
          report.menteeAssessments.where((m) => m.isEligible).firstOrNull;
      _selectedMenteeId = eligibleMentee?.rider.id;
    }
  }

  Rider? _findRider(String? id) {
    if (id == null) return null;
    for (final rider in _roster) {
      if (rider.id == id) return rider;
    }
    return null;
  }

  void _handleAssignMentor() {
    final mentor = _findRider(_selectedMentorId);
    final mentee = _findRider(_selectedMenteeId);
    if (mentor == null || mentee == null) {
      setState(() {
        _statusBanner = 'Wybierz kwalifikującego się weterana oraz neoprofesjonalistę.';
        _statusIsError = true;
      });
      return;
    }

    final result = widget.service.tryAssignMentor(
      mentor: mentor,
      mentee: mentee,
      existingAssignments: _assignments,
      focusArea: _selectedFocus,
    );

    if (!result.success || result.assignment == null) {
      setState(() {
        _statusBanner = result.message;
        _statusIsError = true;
      });
      return;
    }

    setState(() {
      _assignments = [..._assignments, result.assignment!];
      _statusBanner = result.message;
      _statusIsError = false;
      _selectedMentorId = null;
      _selectedMenteeId = null;
      _autoSelectInitialCandidates();
    });
    widget.onAssignmentsChanged?.call(_assignments);
  }

  void _handleSimulateWeek(MentorshipAssignment assignment) {
    final mentor = _findRider(assignment.mentorId);
    final mentee = _findRider(assignment.menteeId);
    if (mentor == null || mentee == null) return;

    final step = widget.service.applyMentorshipDevelopmentTick(
      assignment: assignment,
      mentor: mentor,
      mentee: mentee,
      daysElapsed: 14,
      racedTogether: true,
    );

    setState(() {
      _assignments = _assignments
          .map((a) => a.id == assignment.id ? step.updatedAssignment : a)
          .toList();
      _roster = _roster
          .map((r) => r.id == mentee.id ? step.updatedMentee : r)
          .toList();
      _statusBanner = step.summaryNote;
      _statusIsError = false;
    });
    widget.onAssignmentsChanged?.call(_assignments);
    widget.onMenteeProgressed?.call(step.updatedMentee);
  }

  void _handleEndMentorship(String assignmentId) {
    setState(() {
      _assignments = widget.service.terminateMentorship(
        assignments: _assignments,
        assignmentId: assignmentId,
      );
      _statusBanner = 'Zakończono program mentoringowy.';
      _statusIsError = false;
      _autoSelectInitialCandidates();
    });
    widget.onAssignmentsChanged?.call(_assignments);
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.service.buildBoardReport(
      roster: _roster,
      activeAssignments: _assignments,
    );

    final selectedMentor = _findRider(_selectedMentorId);
    final selectedMentee = _findRider(_selectedMenteeId);
    final compatibility = (selectedMentor != null && selectedMentee != null)
        ? widget.service.evaluateCompatibility(
            mentor: selectedMentor,
            mentee: selectedMentee,
            focusArea: _selectedFocus,
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1150;
          final isTablet = width >= 720 && width < 1150;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(report, isCompact: width < 600),
                if (_statusBanner != null) ...[
                  const SizedBox(height: 12),
                  _buildStatusBanner(),
                ],
                const SizedBox(height: 16),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 10,
                        child: _buildMentorsColumn(report),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 12,
                        child: _buildPairingAndActiveColumn(
                          report,
                          compatibility,
                          selectedMentor,
                          selectedMentee,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 10,
                        child: _buildMenteesColumn(report),
                      ),
                    ],
                  )
                else if (isTablet)
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildMentorsColumn(report)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMenteesColumn(report)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPairingAndActiveColumn(
                        report,
                        compatibility,
                        selectedMentor,
                        selectedMentee,
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPairingAndActiveColumn(
                        report,
                        compatibility,
                        selectedMentor,
                        selectedMentee,
                      ),
                      const SizedBox(height: 16),
                      _buildMentorsColumn(report),
                      const SizedBox(height: 16),
                      _buildMenteesColumn(report),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(MentorshipBoardReport report, {required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
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
                      'Akademia Mentoringu Weteranów',
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
                      isCompact
                          ? 'Weterani >32 lat • +40% taktyka i peleton'
                          : 'Przypisanie weterana (>32 lat, wysokie Race IQ & Bike Handling) przyspiesza rozwój 19-letniego neoprofesjonalisty o +40%.',
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
              _StatPill(
                label: 'Weterani',
                value: '${report.eligibleMentorCount}',
                color: AppColors.goldAccent,
              ),
              _StatPill(
                label: 'Neo-Pro',
                value: '${report.eligibleNeoProCount}',
                color: AppColors.cyanAccent,
              ),
              _StatPill(
                label: 'Aktywne Pary',
                value: '${report.activeAssignments.length}',
                color: AppColors.statusSuccess,
              ),
              _StatPill(
                label: 'Transfer Pkt',
                value: '+${report.totalSkillPointsTransferred}',
                color: AppColors.accentBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color =
        _statusIsError ? AppColors.crimsonAlert : AppColors.statusSuccess;
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
            _statusIsError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusBanner!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorsColumn(MentorshipBoardReport report) {
    return _SectionCard(
      title: 'Kandydaci na Mentorów (>32 lat)',
      subtitle: 'Wymagane: wiek >32, Race IQ ≥75, Bike Handling ≥75',
      accentColor: AppColors.goldAccent,
      child: report.mentorAssessments.isEmpty
          ? const _EmptyPlaceholder(
              message: 'Brak weteranów powyżej 32. roku życia w kadrze.',
            )
          : Column(
              children: report.mentorAssessments.map((assessment) {
                final isSelected = _selectedMentorId == assessment.rider.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InteractiveCandidateCard(
                    selected: isSelected,
                    enabled: assessment.isEligible,
                    accentColor: AppColors.goldAccent,
                    onTap: assessment.isEligible
                        ? () => setState(
                              () => _selectedMentorId = assessment.rider.id,
                            )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                assessment.rider.fullName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _Badge(
                              text: '${assessment.ageYears} lat',
                              color: AppColors.goldAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${assessment.tierLabel} • OVR ${assessment.rider.overallRating}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MiniMetric(
                              label: 'Race IQ',
                              value: '${assessment.raceIq}',
                              highlight: assessment.raceIq >= 75,
                            ),
                            _MiniMetric(
                              label: 'Handling',
                              value: '${assessment.bikeHandling}',
                              highlight: assessment.bikeHandling >= 75,
                            ),
                            _MiniMetric(
                              label: 'Mentor',
                              value: '${assessment.mentorRating}',
                              highlight: true,
                            ),
                          ],
                        ),
                        if (!assessment.isEligible) ...[
                          const SizedBox(height: 6),
                          Text(
                            assessment.status.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.amberWarning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMenteesColumn(MentorshipBoardReport report) {
    return _SectionCard(
      title: 'Neoprofesjonaliści (19–21 lat)',
      subtitle: 'Priorytet: 19-letni debiutanci WorldTour/ProTeam',
      accentColor: AppColors.cyanAccent,
      child: report.menteeAssessments.isEmpty
          ? const _EmptyPlaceholder(
              message: 'Brak młodych kolarzy (≤21 lat) w bieżącym składzie.',
            )
          : Column(
              children: report.menteeAssessments.map((assessment) {
                final isSelected = _selectedMenteeId == assessment.rider.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _InteractiveCandidateCard(
                    selected: isSelected,
                    enabled: assessment.isEligible,
                    accentColor: AppColors.cyanAccent,
                    onTap: assessment.isEligible
                        ? () => setState(
                              () => _selectedMenteeId = assessment.rider.id,
                            )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                assessment.rider.fullName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _Badge(
                              text: assessment.isNeoPro19
                                  ? '19 lat • NEO-PRO'
                                  : '${assessment.ageYears} lat',
                              color: assessment.isNeoPro19
                                  ? AppColors.statusSuccess
                                  : AppColors.cyanAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Potencjał ${assessment.rider.potential} • OVR ${assessment.rider.overallRating}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _MiniMetric(
                              label: 'Race IQ',
                              value: '${assessment.rider.skills.raceIq}',
                            ),
                            _MiniMetric(
                              label: 'Handling',
                              value: '${assessment.rider.skills.bikeHandling}',
                            ),
                            _MiniMetric(
                              label: 'Drafting',
                              value:
                                  '${assessment.rider.skills.draftingEfficiency}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPairingAndActiveColumn(
    MentorshipBoardReport report,
    MentorshipPairCompatibility? compatibility,
    Rider? selectedMentor,
    Rider? selectedMentee,
  ) {
    final canAssign = selectedMentor != null && selectedMentee != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Konfigurator Przypisania (+40% Rozwoju)',
          subtitle: 'Wybierz profil szkolenia taktycznego i jazdy w peletonie',
          accentColor: AppColors.primaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MentorshipFocusArea.values.map((area) {
                  final active = _selectedFocus == area;
                  return _FocusAreaChip(
                    label: area.shortLabel,
                    selected: active,
                    accentColor: area.accentColor,
                    onTap: () => setState(() => _selectedFocus = area),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (compatibility != null &&
                  selectedMentor != null &&
                  selectedMentee != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${selectedMentor.fullName} → ${selectedMentee.fullName}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          _Badge(
                            text: '+${compatibility.accelerationPercent}% TEMPO',
                            color: AppColors.statusSuccess,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        compatibility.summary,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniMetric(
                            label: 'Zgodność',
                            value: '${compatibility.compatibilityScore}/100',
                            highlight: true,
                          ),
                          _MiniMetric(
                            label: 'Prognoza IQ',
                            value:
                                '+${compatibility.projectedSeasonalSkillGains['raceIq'] ?? 0}',
                            highlight: true,
                          ),
                          _MiniMetric(
                            label: 'Prognoza Peleton',
                            value:
                                '+${compatibility.projectedSeasonalSkillGains['bikeHandling'] ?? 0}',
                            highlight: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const _EmptyPlaceholder(
                  message:
                      'Wskaż dostępnego weterana i 19-letniego neoprofesjonalistę, aby zobaczyć prognozę +40%.',
                ),
              const SizedBox(height: 14),
              _ActionButton(
                label: 'Przypisz Mentora (+40% Taktyka & Peleton)',
                icon: Icons.link_rounded,
                enabled: canAssign,
                accentColor: AppColors.goldAccent,
                onPressed: canAssign ? _handleAssignMentor : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Aktywne Programy Mentoringowe',
          subtitle: 'Śledzenie postępów taktycznych i jazdy w peletonie',
          accentColor: AppColors.statusSuccess,
          child: report.activeAssignments.isEmpty
              ? const _EmptyPlaceholder(
                  message: 'Brak aktywnych par mentoringowych w tym momencie.',
                )
              : Column(
                  children: report.activeAssignments.map((assignment) {
                    final mentor = _findRider(assignment.mentorId);
                    final mentee = _findRider(assignment.menteeId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${mentor?.fullName ?? assignment.mentorId} → ${mentee?.fullName ?? assignment.menteeId}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                _Badge(
                                  text:
                                      '+${(assignment.tacticalAccelerationBonus * 100).round()}%',
                                  color: AppColors.statusSuccess,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${assignment.focusArea.label} • Dzień ${assignment.completedDays}/${assignment.targetDurationDays} • Zysk: +${assignment.cumulativeSkillPointsGained} pkt',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: assignment.progressRatio,
                                minHeight: 6,
                                backgroundColor: AppColors.background,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  assignment.focusArea.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SmallActionButton(
                                  label: 'Symuluj Blok (14 dni)',
                                  icon: Icons.fast_forward_rounded,
                                  color: AppColors.cyanAccent,
                                  onPressed: () =>
                                      _handleSimulateWeek(assignment),
                                ),
                                _SmallActionButton(
                                  label: 'Zakończ',
                                  icon: Icons.close_rounded,
                                  color: AppColors.crimsonAlert,
                                  onPressed: () =>
                                      _handleEndMentorship(assignment.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InteractiveCandidateCard extends StatefulWidget {
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget child;

  const _InteractiveCandidateCard({
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_InteractiveCandidateCard> createState() =>
      _InteractiveCandidateCardState();
}

class _InteractiveCandidateCardState extends State<_InteractiveCandidateCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : widget.selected
            ? widget.accentColor
            : _focused
                ? AppColors.cyanAccent
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.65)
                    : AppColors.cardBorder;

    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.16)
            : widget.selected
                ? widget.accentColor.withValues(alpha: 0.12)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLight.withValues(alpha: 0.85);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: widget.selected ? 1.5 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.6,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _FocusAreaChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FocusAreaChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FocusAreaChip> createState() => _FocusAreaChipState();
}

class _FocusAreaChipState extends State<_FocusAreaChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accentColor.withValues(alpha: 0.2)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected
                  ? widget.accentColor
                  : _focused
                      ? AppColors.cyanAccent
                      : AppColors.cardBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.selected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surfaceLight
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.85)
            : _hovered
                ? widget.accentColor
                : widget.accentColor.withValues(alpha: 0.9);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.cyanAccent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.enabled
                    ? AppColors.background
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.enabled
                        ? AppColors.background
                        : AppColors.textSecondary,
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

class _SmallActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_SmallActionButton> createState() => _SmallActionButtonState();
}

class _SmallActionButtonState extends State<_SmallActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.22)
                : widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused
                  ? AppColors.cyanAccent
                  : widget.color.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
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
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
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

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? AppColors.goldAccent.withValues(alpha: 0.35)
              : AppColors.cardBorder,
        ),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String message;

  const _EmptyPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
