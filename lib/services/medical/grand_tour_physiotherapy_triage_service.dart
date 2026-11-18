// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/medical/grand_tour_nightly_hrv_and_physio_model.dart';

/// Rodzaj zabiegu fizjoterapeutycznego / regeneracyjnego przydzielanego po etapie Wielkiego Touru.
enum PhysiotherapyTreatmentType {
  /// Głęboki Masaż Powięziowy — redukuje kinazę kreatynową (CK) o 25%.
  deepFasciaMassage,

  /// Terapia Tecar / Ultradźwięki — przyspiesza gojenie stłuczeń i urazów po kraksie.
  tecarAndUltrasound,

  /// Krioterapia Ogólnoustrojowa — podnosi nocne HRV o +12 ms.
  wholeBodyCryotherapy;

  String get labelPl {
    switch (this) {
      case PhysiotherapyTreatmentType.deepFasciaMassage:
        return 'Głęboki Masaż Powięziowy';
      case PhysiotherapyTreatmentType.tecarAndUltrasound:
        return 'Terapia Tecar / Ultradźwięki';
      case PhysiotherapyTreatmentType.wholeBodyCryotherapy:
        return 'Krioterapia Ogólnoustrojowa';
    }
  }

  String get shortEffectPl {
    switch (this) {
      case PhysiotherapyTreatmentType.deepFasciaMassage:
        return '-25% CK (U/L)';
      case PhysiotherapyTreatmentType.tecarAndUltrasound:
        return 'Gojenie stłuczeń x2';
      case PhysiotherapyTreatmentType.wholeBodyCryotherapy:
        return '+12 ms HRV';
    }
  }

  String get clinicalMechanismPl {
    switch (this) {
      case PhysiotherapyTreatmentType.deepFasciaMassage:
        return 'Manualne rozluźnienie powięzi i drenaż mięśniowy: redukuje powysiłkowe CK o 25% i łagodzi DOMS.';
      case PhysiotherapyTreatmentType.tecarAndUltrasound:
        return 'Fala radiowa Tecar 448 kHz + ultradźwięki: przyspiesza resorpcję krwiaków i gojenie stłuczeń po kraksie.';
      case PhysiotherapyTreatmentType.wholeBodyCryotherapy:
        return 'Ekspozycja w kriokomorze (-110°C): aktywuje nerw błędny i podnosi nocne HRV o +12 ms.';
    }
  }

  int get defaultDurationMinutes {
    switch (this) {
      case PhysiotherapyTreatmentType.deepFasciaMassage:
        return 45;
      case PhysiotherapyTreatmentType.tecarAndUltrasound:
        return 40;
      case PhysiotherapyTreatmentType.wholeBodyCryotherapy:
        return 25;
    }
  }

  int get materialCostEur {
    switch (this) {
      case PhysiotherapyTreatmentType.deepFasciaMassage:
        return 45;
      case PhysiotherapyTreatmentType.tecarAndUltrasound:
        return 95;
      case PhysiotherapyTreatmentType.wholeBodyCryotherapy:
        return 110;
    }
  }

  String toJson() => name;

  static PhysiotherapyTreatmentType fromJson(String value) {
    return PhysiotherapyTreatmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PhysiotherapyTreatmentType.deepFasciaMassage,
    );
  }
}

/// Rola taktyczna kolarza w składzie na Wielki Tour (wpływa na priorytet czarteru i triażu).
enum GrandTourTriageRole {
  gcLeader,
  sprinterLeader,
  mountainDomestique,
  roadCaptain,
  rouleurDomestique;

  String get labelPl {
    switch (this) {
      case GrandTourTriageRole.gcLeader:
        return 'Lider GC';
      case GrandTourTriageRole.sprinterLeader:
        return 'Lider Sprintu';
      case GrandTourTriageRole.mountainDomestique:
        return 'Góral Pomocnik';
      case GrandTourTriageRole.roadCaptain:
        return 'Kapitan Drogi';
      case GrandTourTriageRole.rouleurDomestique:
        return 'Pomocnik';
    }
  }

  bool get isProtectedLeader =>
      this == GrandTourTriageRole.gcLeader ||
      this == GrandTourTriageRole.sprinterLeader;

  String toJson() => name;

  static GrandTourTriageRole fromJson(String value) {
    return GrandTourTriageRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GrandTourTriageRole.rouleurDomestique,
    );
  }
}

/// Decyzja logistyczna dotycząca transferu między metą etapu a hotelem.
enum TransferTransportDecision {
  /// Standardowy 4-godzinny transfer autokarem drużynowym (bez dodatkowych kosztów).
  fourHourTeamBus,

  /// Wykupienie czarteru lotniczego dla liderów (lub całej grupy) — daje +2 godziny snu.
  airCharterForLeaders;

  String get labelPl {
    switch (this) {
      case TransferTransportDecision.fourHourTeamBus:
        return 'Transfer Autobusem (4h)';
      case TransferTransportDecision.airCharterForLeaders:
        return 'Czarter Lotniczy (+2h snu liderów)';
    }
  }

  String toJson() => name;

  static TransferTransportDecision fromJson(String value) {
    return TransferTransportDecision.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransferTransportDecision.fourHourTeamBus,
    );
  }
}

/// Profil kolarza po etapie na potrzeby wieczornego triażu fizjoterapeutycznego.
class RiderPostStageTriageInput {
  final String riderId;
  final String riderName;
  final GrandTourTriageRole role;
  final double currentHrvMs;
  final double baselineHrvMs;
  final double currentCkUL;
  final double currentReadinessScore;
  final double plannedSleepHoursWithBus;
  final bool crashedOnStage;
  final int contusionHealingDaysRemaining;
  final double contusionPainPenalty;

  const RiderPostStageTriageInput({
    required this.riderId,
    required this.riderName,
    required this.role,
    required this.currentHrvMs,
    required this.baselineHrvMs,
    required this.currentCkUL,
    required this.currentReadinessScore,
    required this.plannedSleepHoursWithBus,
    this.crashedOnStage = false,
    this.contusionHealingDaysRemaining = 0,
    this.contusionPainPenalty = 0.0,
  });

  bool get needsTraumaCare =>
      crashedOnStage || contusionHealingDaysRemaining > 0;

  bool get hasHighCkAlert => currentCkUL >= 850.0;

  bool get hasSuppressedHrv => currentHrvMs < baselineHrvMs * 0.88;

  RiderPostStageTriageInput copyWith({
    String? riderId,
    String? riderName,
    GrandTourTriageRole? role,
    double? currentHrvMs,
    double? baselineHrvMs,
    double? currentCkUL,
    double? currentReadinessScore,
    double? plannedSleepHoursWithBus,
    bool? crashedOnStage,
    int? contusionHealingDaysRemaining,
    double? contusionPainPenalty,
  }) {
    return RiderPostStageTriageInput(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      role: role ?? this.role,
      currentHrvMs: currentHrvMs ?? this.currentHrvMs,
      baselineHrvMs: baselineHrvMs ?? this.baselineHrvMs,
      currentCkUL: currentCkUL ?? this.currentCkUL,
      currentReadinessScore:
          currentReadinessScore ?? this.currentReadinessScore,
      plannedSleepHoursWithBus:
          plannedSleepHoursWithBus ?? this.plannedSleepHoursWithBus,
      crashedOnStage: crashedOnStage ?? this.crashedOnStage,
      contusionHealingDaysRemaining:
          contusionHealingDaysRemaining ?? this.contusionHealingDaysRemaining,
      contusionPainPenalty: contusionPainPenalty ?? this.contusionPainPenalty,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'role': role.toJson(),
        'currentHrvMs': currentHrvMs,
        'baselineHrvMs': baselineHrvMs,
        'currentCkUL': currentCkUL,
        'currentReadinessScore': currentReadinessScore,
        'plannedSleepHoursWithBus': plannedSleepHoursWithBus,
        'crashedOnStage': crashedOnStage,
        'contusionHealingDaysRemaining': contusionHealingDaysRemaining,
        'contusionPainPenalty': contusionPainPenalty,
      };

  factory RiderPostStageTriageInput.fromJson(Map<String, dynamic> json) {
    return RiderPostStageTriageInput(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      role: GrandTourTriageRole.fromJson(json['role'] as String),
      currentHrvMs: (json['currentHrvMs'] as num).toDouble(),
      baselineHrvMs: (json['baselineHrvMs'] as num).toDouble(),
      currentCkUL: (json['currentCkUL'] as num).toDouble(),
      currentReadinessScore:
          (json['currentReadinessScore'] as num).toDouble(),
      plannedSleepHoursWithBus:
          (json['plannedSleepHoursWithBus'] as num).toDouble(),
      crashedOnStage: json['crashedOnStage'] as bool? ?? false,
      contusionHealingDaysRemaining:
          (json['contusionHealingDaysRemaining'] as num?)?.toInt() ?? 0,
      contusionPainPenalty:
          (json['contusionPainPenalty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Przydział konkretnego zabiegu oraz specjalisty do kolarza.
class PhysiotherapyTreatmentAssignment {
  final String riderId;
  final PhysiotherapyTreatmentType treatment;
  final int specialistSlotIndex;
  final int durationMinutes;

  const PhysiotherapyTreatmentAssignment({
    required this.riderId,
    required this.treatment,
    required this.specialistSlotIndex,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'treatment': treatment.toJson(),
        'specialistSlotIndex': specialistSlotIndex,
        'durationMinutes': durationMinutes,
      };

  factory PhysiotherapyTreatmentAssignment.fromJson(Map<String, dynamic> json) {
    return PhysiotherapyTreatmentAssignment(
      riderId: json['riderId'] as String,
      treatment: PhysiotherapyTreatmentType.fromJson(json['treatment'] as String),
      specialistSlotIndex: (json['specialistSlotIndex'] as num).toInt(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhysiotherapyTreatmentAssignment &&
        other.riderId == riderId &&
        other.treatment == treatment &&
        other.specialistSlotIndex == specialistSlotIndex &&
        other.durationMinutes == durationMinutes;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        treatment,
        specialistSlotIndex,
        durationMinutes,
      );
}

/// Konfiguracja zasobów sztabu medycznego oraz logistyki transferu po etapie.
class PhysiotherapyTriageConfig {
  final int stageDay;
  final int specialistCount;
  final int minutesPerSpecialist;
  final int busTransferMinutes;
  final int charterFlightCostEur;
  final double charterSleepBonusHours;
  final double specialistSkillMultiplier;

  const PhysiotherapyTriageConfig({
    this.stageDay = 1,
    this.specialistCount = 3,
    this.minutesPerSpecialist = 110,
    this.busTransferMinutes = 240,
    this.charterFlightCostEur = 18500,
    this.charterSleepBonusHours = 2.0,
    this.specialistSkillMultiplier = 1.0,
  });

  int get totalSpecialistMinutes =>
      math.max(0, specialistCount) * math.max(0, minutesPerSpecialist);

  PhysiotherapyTriageConfig copyWith({
    int? stageDay,
    int? specialistCount,
    int? minutesPerSpecialist,
    int? busTransferMinutes,
    int? charterFlightCostEur,
    double? charterSleepBonusHours,
    double? specialistSkillMultiplier,
  }) {
    return PhysiotherapyTriageConfig(
      stageDay: stageDay ?? this.stageDay,
      specialistCount: specialistCount ?? this.specialistCount,
      minutesPerSpecialist: minutesPerSpecialist ?? this.minutesPerSpecialist,
      busTransferMinutes: busTransferMinutes ?? this.busTransferMinutes,
      charterFlightCostEur: charterFlightCostEur ?? this.charterFlightCostEur,
      charterSleepBonusHours:
          charterSleepBonusHours ?? this.charterSleepBonusHours,
      specialistSkillMultiplier:
          specialistSkillMultiplier ?? this.specialistSkillMultiplier,
    );
  }

  Map<String, dynamic> toJson() => {
        'stageDay': stageDay,
        'specialistCount': specialistCount,
        'minutesPerSpecialist': minutesPerSpecialist,
        'busTransferMinutes': busTransferMinutes,
        'charterFlightCostEur': charterFlightCostEur,
        'charterSleepBonusHours': charterSleepBonusHours,
        'specialistSkillMultiplier': specialistSkillMultiplier,
      };

  factory PhysiotherapyTriageConfig.fromJson(Map<String, dynamic> json) {
    return PhysiotherapyTriageConfig(
      stageDay: (json['stageDay'] as num?)?.toInt() ?? 1,
      specialistCount: (json['specialistCount'] as num?)?.toInt() ?? 3,
      minutesPerSpecialist:
          (json['minutesPerSpecialist'] as num?)?.toInt() ?? 110,
      busTransferMinutes:
          (json['busTransferMinutes'] as num?)?.toInt() ?? 240,
      charterFlightCostEur:
          (json['charterFlightCostEur'] as num?)?.toInt() ?? 18500,
      charterSleepBonusHours:
          (json['charterSleepBonusHours'] as num?)?.toDouble() ?? 2.0,
      specialistSkillMultiplier:
          (json['specialistSkillMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Zprognozowany wynik nocnej regeneracji kolarza po zastosowaniu triażu i logistyki snu.
class RiderTriageRecoveryOutcome {
  final String riderId;
  final String riderName;
  final GrandTourTriageRole role;
  final List<PhysiotherapyTreatmentType> appliedTreatments;
  final bool receivedCharterFlightSleepBonus;
  final double initialCkUL;
  final double projectedCkUL;
  final double ckReductionPercent;
  final double initialHrvMs;
  final double projectedHrvMs;
  final double hrvDeltaMs;
  final double initialSleepHours;
  final double projectedSleepHours;
  final double sleepBonusHours;
  final int initialContusionDays;
  final int projectedContusionDays;
  final double initialReadinessScore;
  final double projectedReadinessScore;
  final double readinessDelta;
  final int specialistMinutesSpent;

  const RiderTriageRecoveryOutcome({
    required this.riderId,
    required this.riderName,
    required this.role,
    required this.appliedTreatments,
    required this.receivedCharterFlightSleepBonus,
    required this.initialCkUL,
    required this.projectedCkUL,
    required this.ckReductionPercent,
    required this.initialHrvMs,
    required this.projectedHrvMs,
    required this.hrvDeltaMs,
    required this.initialSleepHours,
    required this.projectedSleepHours,
    required this.sleepBonusHours,
    required this.initialContusionDays,
    required this.projectedContusionDays,
    required this.initialReadinessScore,
    required this.projectedReadinessScore,
    required this.readinessDelta,
    required this.specialistMinutesSpent,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'role': role.toJson(),
        'appliedTreatments': appliedTreatments.map((e) => e.toJson()).toList(),
        'receivedCharterFlightSleepBonus': receivedCharterFlightSleepBonus,
        'initialCkUL': initialCkUL,
        'projectedCkUL': projectedCkUL,
        'ckReductionPercent': ckReductionPercent,
        'initialHrvMs': initialHrvMs,
        'projectedHrvMs': projectedHrvMs,
        'hrvDeltaMs': hrvDeltaMs,
        'initialSleepHours': initialSleepHours,
        'projectedSleepHours': projectedSleepHours,
        'sleepBonusHours': sleepBonusHours,
        'initialContusionDays': initialContusionDays,
        'projectedContusionDays': projectedContusionDays,
        'initialReadinessScore': initialReadinessScore,
        'projectedReadinessScore': projectedReadinessScore,
        'readinessDelta': readinessDelta,
        'specialistMinutesSpent': specialistMinutesSpent,
      };

  factory RiderTriageRecoveryOutcome.fromJson(Map<String, dynamic> json) {
    return RiderTriageRecoveryOutcome(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      role: GrandTourTriageRole.fromJson(json['role'] as String),
      appliedTreatments: (json['appliedTreatments'] as List<dynamic>)
          .map((e) => PhysiotherapyTreatmentType.fromJson(e as String))
          .toList(),
      receivedCharterFlightSleepBonus:
          json['receivedCharterFlightSleepBonus'] as bool? ?? false,
      initialCkUL: (json['initialCkUL'] as num).toDouble(),
      projectedCkUL: (json['projectedCkUL'] as num).toDouble(),
      ckReductionPercent: (json['ckReductionPercent'] as num).toDouble(),
      initialHrvMs: (json['initialHrvMs'] as num).toDouble(),
      projectedHrvMs: (json['projectedHrvMs'] as num).toDouble(),
      hrvDeltaMs: (json['hrvDeltaMs'] as num).toDouble(),
      initialSleepHours: (json['initialSleepHours'] as num).toDouble(),
      projectedSleepHours: (json['projectedSleepHours'] as num).toDouble(),
      sleepBonusHours: (json['sleepBonusHours'] as num).toDouble(),
      initialContusionDays: (json['initialContusionDays'] as num).toInt(),
      projectedContusionDays: (json['projectedContusionDays'] as num).toInt(),
      initialReadinessScore:
          (json['initialReadinessScore'] as num).toDouble(),
      projectedReadinessScore:
          (json['projectedReadinessScore'] as num).toDouble(),
      readinessDelta: (json['readinessDelta'] as num).toDouble(),
      specialistMinutesSpent:
          (json['specialistMinutesSpent'] as num).toInt(),
    );
  }
}

/// Zbiorczy raport wykonania wieczornego triażu fizjoterapeutycznego i logistyki snu.
class GrandTourPhysiotherapyTriageReport {
  final int stageDay;
  final TransferTransportDecision transportDecision;
  final int totalSpecialistMinutesAvailable;
  final int totalSpecialistMinutesUsed;
  final int totalTreatmentCostEur;
  final int charterCostEur;
  final int totalCostEur;
  final double averageTeamReadinessBefore;
  final double averageTeamReadinessAfter;
  final double averageTeamHrvDeltaMs;
  final double averageTeamCkReductionPct;
  final List<RiderTriageRecoveryOutcome> riderOutcomes;
  final String medicalSummaryPl;

  const GrandTourPhysiotherapyTriageReport({
    required this.stageDay,
    required this.transportDecision,
    required this.totalSpecialistMinutesAvailable,
    required this.totalSpecialistMinutesUsed,
    required this.totalTreatmentCostEur,
    required this.charterCostEur,
    required this.totalCostEur,
    required this.averageTeamReadinessBefore,
    required this.averageTeamReadinessAfter,
    required this.averageTeamHrvDeltaMs,
    required this.averageTeamCkReductionPct,
    required this.riderOutcomes,
    required this.medicalSummaryPl,
  });

  int get remainingSpecialistMinutes =>
      math.max(0, totalSpecialistMinutesAvailable - totalSpecialistMinutesUsed);

  Map<String, dynamic> toJson() => {
        'stageDay': stageDay,
        'transportDecision': transportDecision.toJson(),
        'totalSpecialistMinutesAvailable': totalSpecialistMinutesAvailable,
        'totalSpecialistMinutesUsed': totalSpecialistMinutesUsed,
        'totalTreatmentCostEur': totalTreatmentCostEur,
        'charterCostEur': charterCostEur,
        'totalCostEur': totalCostEur,
        'averageTeamReadinessBefore': averageTeamReadinessBefore,
        'averageTeamReadinessAfter': averageTeamReadinessAfter,
        'averageTeamHrvDeltaMs': averageTeamHrvDeltaMs,
        'averageTeamCkReductionPct': averageTeamCkReductionPct,
        'riderOutcomes': riderOutcomes.map((e) => e.toJson()).toList(),
        'medicalSummaryPl': medicalSummaryPl,
      };
}

/// Serwis codziennego zarządzania fizjoterapią i logistyką snu po etapie Wielkiego Touru.
///
/// Po każdym etapie gracz przydziela ograniczony czas swoich fizjoterapeutów i osteopatów
/// (domyślnie 3 specjalistów na 8 kolarzy) do zabiegów:
/// - **Głęboki Masaż Powięziowy** (redukuje CK o 25%),
/// - **Terapia Tecar / Ultradźwięki** (przyspiesza gojenie stłuczeń po kraksie),
/// - **Krioterapia Ogólnoustrojowa** (podnosi nocne HRV o +12 ms),
/// oraz podejmuje decyzję o wykupieniu czarteru lotniczego zamiast 4-godzinnego
/// transferu autobusem, dając liderom +2 godziny snu.
class GrandTourPhysiotherapyTriageService {
  static const double deepMassageCkReductionRatio = 0.25;
  static const double cryotherapyHrvBoostMs = 12.0;
  static const double charterSleepBonusHoursDefault = 2.0;
  static const int standardBusTransferMinutes = 240;

  const GrandTourPhysiotherapyTriageService();

  /// Sprawdza, czy można przydzielić kolejny zabieg bez przekroczenia czasu pracy sztabu
  /// oraz bez duplikowania tego samego zabiegu u jednego kolarza.
  ({bool allowed, String? reasonPl}) canAssignTreatment({
    required String riderId,
    required PhysiotherapyTreatmentType treatment,
    required List<PhysiotherapyTreatmentAssignment> currentAssignments,
    required PhysiotherapyTriageConfig config,
  }) {
    final alreadyHasTreatment = currentAssignments.any(
      (a) => a.riderId == riderId && a.treatment == treatment,
    );
    if (alreadyHasTreatment) {
      return (
        allowed: false,
        reasonPl: 'Kolarz ma już zaplanowany zabieg ${treatment.labelPl}.',
      );
    }

    final usedMinutes = currentAssignments.fold<int>(
      0,
      (sum, a) => sum + a.durationMinutes,
    );
    final neededMinutes = treatment.defaultDurationMinutes;

    if (usedMinutes + neededMinutes > config.totalSpecialistMinutes) {
      return (
        allowed: false,
        reasonPl:
            'Brak wolnego czasu fizjoterapeutów (pozostało ${math.max(0, config.totalSpecialistMinutes - usedMinutes)} min, wymagane $neededMinutes min).',
      );
    }

    return (allowed: true, reasonPl: null);
  }

  /// Wybiera indeks specjalisty o najmniejszym bieżącym obciążeniu minutowym.
  int pickLeastLoadedSpecialistIndex({
    required List<PhysiotherapyTreatmentAssignment> currentAssignments,
    required int specialistCount,
  }) {
    if (specialistCount <= 1) return 0;
    final loads = List<int>.filled(specialistCount, 0);
    for (final a in currentAssignments) {
      final idx = a.specialistSlotIndex.clamp(0, specialistCount - 1);
      loads[idx] += a.durationMinutes;
    }
    int bestIndex = 0;
    for (int i = 1; i < loads.length; i++) {
      if (loads[i] < loads[bestIndex]) {
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  /// Automatycznie przydziela optymalny triaż fizjoterapeutyczny dla 8-osobowego składu:
  /// 1) Stłuczenia po kraksie -> Terapia Tecar / Ultradźwięki
  /// 2) Wysokie CK (>= 850 U/L) lub liderzy -> Głęboki Masaż Powięziowy (-25% CK)
  /// 3) Obniżone HRV lub liderzy przed kluczowymi etapami -> Krioterapia (+12 ms HRV)
  List<PhysiotherapyTreatmentAssignment> autoAssignOptimalTriage({
    required List<RiderPostStageTriageInput> squad,
    required PhysiotherapyTriageConfig config,
  }) {
    if (squad.isEmpty || config.totalSpecialistMinutes <= 0) {
      return const [];
    }

    final assignments = <PhysiotherapyTreatmentAssignment>[];
    final sortedByPriority = List<RiderPostStageTriageInput>.from(squad)
      ..sort((a, b) {
        final aScore = _riderTriagePriorityScore(a);
        final bScore = _riderTriagePriorityScore(b);
        return bScore.compareTo(aScore);
      });

    // Krok 1: Pilna terapia Tecar / Ultradźwięki dla kolarzy po kraksie
    for (final rider in sortedByPriority) {
      if (!rider.needsTraumaCare) continue;
      final check = canAssignTreatment(
        riderId: rider.riderId,
        treatment: PhysiotherapyTreatmentType.tecarAndUltrasound,
        currentAssignments: assignments,
        config: config,
      );
      if (check.allowed) {
        assignments.add(
          PhysiotherapyTreatmentAssignment(
            riderId: rider.riderId,
            treatment: PhysiotherapyTreatmentType.tecarAndUltrasound,
            specialistSlotIndex: pickLeastLoadedSpecialistIndex(
              currentAssignments: assignments,
              specialistCount: config.specialistCount,
            ),
            durationMinutes:
                PhysiotherapyTreatmentType.tecarAndUltrasound.defaultDurationMinutes,
          ),
        );
      }
    }

    // Krok 2: Głęboki Masaż Powięziowy (-25% CK) dla liderów i wysokiego CK
    for (final rider in sortedByPriority) {
      if (!rider.role.isProtectedLeader && !rider.hasHighCkAlert) continue;
      final check = canAssignTreatment(
        riderId: rider.riderId,
        treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
        currentAssignments: assignments,
        config: config,
      );
      if (check.allowed) {
        assignments.add(
          PhysiotherapyTreatmentAssignment(
            riderId: rider.riderId,
            treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
            specialistSlotIndex: pickLeastLoadedSpecialistIndex(
              currentAssignments: assignments,
              specialistCount: config.specialistCount,
            ),
            durationMinutes:
                PhysiotherapyTreatmentType.deepFasciaMassage.defaultDurationMinutes,
          ),
        );
      }
    }

    // Krok 3: Krioterapia Ogólnoustrojowa (+12 ms HRV) dla liderów i niskiego HRV
    for (final rider in sortedByPriority) {
      if (!rider.role.isProtectedLeader && !rider.hasSuppressedHrv) continue;
      final check = canAssignTreatment(
        riderId: rider.riderId,
        treatment: PhysiotherapyTreatmentType.wholeBodyCryotherapy,
        currentAssignments: assignments,
        config: config,
      );
      if (check.allowed) {
        assignments.add(
          PhysiotherapyTreatmentAssignment(
            riderId: rider.riderId,
            treatment: PhysiotherapyTreatmentType.wholeBodyCryotherapy,
            specialistSlotIndex: pickLeastLoadedSpecialistIndex(
              currentAssignments: assignments,
              specialistCount: config.specialistCount,
            ),
            durationMinutes: PhysiotherapyTreatmentType
                .wholeBodyCryotherapy.defaultDurationMinutes,
          ),
        );
      }
    }

    // Krok 4: Dopełnienie pozostałego czasu sztabu masażem dla pozostałych kolarzy
    for (final rider in sortedByPriority) {
      final check = canAssignTreatment(
        riderId: rider.riderId,
        treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
        currentAssignments: assignments,
        config: config,
      );
      if (check.allowed) {
        assignments.add(
          PhysiotherapyTreatmentAssignment(
            riderId: rider.riderId,
            treatment: PhysiotherapyTreatmentType.deepFasciaMassage,
            specialistSlotIndex: pickLeastLoadedSpecialistIndex(
              currentAssignments: assignments,
              specialistCount: config.specialistCount,
            ),
            durationMinutes:
                PhysiotherapyTreatmentType.deepFasciaMassage.defaultDurationMinutes,
          ),
        );
      }
    }

    return List.unmodifiable(assignments);
  }

  /// Oblicza zaktualizowany wpływ transferu na sen w zależności od wyboru autokaru lub czarteru.
  BusTransferSleepImpact resolveTransferLogistics({
    required BusTransferSleepImpact baseBusTransfer,
    required TransferTransportDecision decision,
  }) {
    if (decision == TransferTransportDecision.fourHourTeamBus) {
      return baseBusTransfer;
    }

    // Czarter lotniczy skraca 4-godzinny transfer do szybkiego przelotu (~55 min łącznie),
    // umożliwiając przyjazd do hotelu o ~19:15 i brak opóźnionej kolacji (+2h snu liderów).
    return baseBusTransfer.copyWith(
      transferDurationMinutes: math.min(55, baseBusTransfer.transferDurationMinutes),
      hotelArrivalHourDecimal:
          math.min(19.25, baseBusTransfer.hotelArrivalHourDecimal),
      dinnerDelayMinutes: 0,
      roomNoiseOrHeatDisturbance:
          (baseBusTransfer.roomNoiseOrHeatDisturbance * 0.6).clamp(0.0, 1.0),
    );
  }

  /// Ewaluuje pełny wieczorny triaż i zwraca szczegółowy raport regeneracji drużyny.
  GrandTourPhysiotherapyTriageReport evaluateTriagePlan({
    required List<RiderPostStageTriageInput> squad,
    required List<PhysiotherapyTreatmentAssignment> assignments,
    required TransferTransportDecision transportDecision,
    required PhysiotherapyTriageConfig config,
    int availableBudgetEur = 1000000,
    Set<String>? charterPriorityRiderIds,
  }) {
    final effectiveTransport =
        transportDecision == TransferTransportDecision.airCharterForLeaders &&
                availableBudgetEur >= config.charterFlightCostEur
            ? TransferTransportDecision.airCharterForLeaders
            : TransferTransportDecision.fourHourTeamBus;

    final outcomes = <RiderTriageRecoveryOutcome>[];
    int totalUsedMinutes = 0;
    int totalTreatmentCost = 0;

    for (final rider in squad) {
      final riderAssignments =
          assignments.where((a) => a.riderId == rider.riderId).toList();
      final appliedTypes =
          riderAssignments.map((a) => a.treatment).toList(growable: false);
      final riderMinutes = riderAssignments.fold<int>(
        0,
        (sum, a) => sum + a.durationMinutes,
      );
      totalUsedMinutes += riderMinutes;
      totalTreatmentCost += appliedTypes.fold<int>(
        0,
        (sum, t) => sum + t.materialCostEur,
      );

      final hasMassage =
          appliedTypes.contains(PhysiotherapyTreatmentType.deepFasciaMassage);
      final hasTecar =
          appliedTypes.contains(PhysiotherapyTreatmentType.tecarAndUltrasound);
      final hasCryo = appliedTypes
          .contains(PhysiotherapyTreatmentType.wholeBodyCryotherapy);

      // 1. CK: Głęboki masaż powięziowy redukuje kinazę kreatynową o 25%.
      final ckReductionRatio =
          hasMassage ? deepMassageCkReductionRatio : 0.0;
      final projectedCk = (rider.currentCkUL * (1.0 - ckReductionRatio))
          .clamp(70.0, 3200.0);
      final ckReductionPct = rider.currentCkUL > 0
          ? ((rider.currentCkUL - projectedCk) / rider.currentCkUL) * 100.0
          : 0.0;

      // 2. Czarter lotniczy: +2 godziny snu dla liderów (lub wskazanych kolarzy).
      final getsCharterBonus =
          effectiveTransport == TransferTransportDecision.airCharterForLeaders &&
              (charterPriorityRiderIds != null
                  ? charterPriorityRiderIds.contains(rider.riderId)
                  : rider.role.isProtectedLeader);

      final sleepBonusHours =
          getsCharterBonus ? config.charterSleepBonusHours : 0.0;
      final projectedSleepHours =
          (rider.plannedSleepHoursWithBus + sleepBonusHours).clamp(4.5, 10.5);

      // 3. Krioterapia Ogólnoustrojowa: +12 ms do nocnego HRV (+ bonus ze snu po czarterze).
      final cryoHrvGain = hasCryo ? cryotherapyHrvBoostMs : 0.0;
      final sleepHrvGain = getsCharterBonus ? 4.5 : 0.0;
      final massageHrvGain = hasMassage ? 2.5 : 0.0;
      final totalHrvDelta = cryoHrvGain + sleepHrvGain + massageHrvGain;
      final projectedHrv =
          (rider.currentHrvMs + totalHrvDelta).clamp(18.0, 195.0);

      // 4. Terapia Tecar / Ultradźwięki: przyspiesza gojenie stłuczeń po kraksie.
      int projectedContusionDays = rider.contusionHealingDaysRemaining;
      double painReliefBonus = 0.0;
      if (rider.needsTraumaCare && hasTecar) {
        if (rider.contusionHealingDaysRemaining > 0) {
          projectedContusionDays = math.max(
            0,
            (rider.contusionHealingDaysRemaining / 2.0).floor(),
          );
        }
        painReliefBonus =
            (rider.contusionPainPenalty * 0.65).clamp(2.5, 10.0);
      }

      // 5. Zbiorczy wpływ na gotowość (Readiness 0-100).
      final ckReadinessGain = hasMassage ? 6.5 : 0.0;
      final cryoReadinessGain = hasCryo ? 6.0 : 0.0;
      final tecarReadinessGain =
          (rider.needsTraumaCare && hasTecar) ? 7.0 + painReliefBonus * 0.35 : 0.0;
      final sleepReadinessGain = getsCharterBonus ? 8.5 : 0.0;

      final projectedReadiness = (rider.currentReadinessScore +
              ckReadinessGain +
              cryoReadinessGain +
              tecarReadinessGain +
              sleepReadinessGain)
          .clamp(5.0, 99.0);

      outcomes.add(
        RiderTriageRecoveryOutcome(
          riderId: rider.riderId,
          riderName: rider.riderName,
          role: rider.role,
          appliedTreatments: appliedTypes,
          receivedCharterFlightSleepBonus: getsCharterBonus,
          initialCkUL: _round1(rider.currentCkUL),
          projectedCkUL: _round1(projectedCk),
          ckReductionPercent: _round1(ckReductionPct),
          initialHrvMs: _round1(rider.currentHrvMs),
          projectedHrvMs: _round1(projectedHrv),
          hrvDeltaMs: _round1(projectedHrv - rider.currentHrvMs),
          initialSleepHours: _round1(rider.plannedSleepHoursWithBus),
          projectedSleepHours: _round1(projectedSleepHours),
          sleepBonusHours: _round1(sleepBonusHours),
          initialContusionDays: rider.contusionHealingDaysRemaining,
          projectedContusionDays: projectedContusionDays,
          initialReadinessScore: _round1(rider.currentReadinessScore),
          projectedReadinessScore: _round1(projectedReadiness),
          readinessDelta:
              _round1(projectedReadiness - rider.currentReadinessScore),
          specialistMinutesSpent: riderMinutes,
        ),
      );
    }

    final count = outcomes.isEmpty ? 1 : outcomes.length;
    final avgBefore = outcomes.fold<double>(
          0.0,
          (sum, o) => sum + o.initialReadinessScore,
        ) /
        count;
    final avgAfter = outcomes.fold<double>(
          0.0,
          (sum, o) => sum + o.projectedReadinessScore,
        ) /
        count;
    final avgHrvDelta = outcomes.fold<double>(
          0.0,
          (sum, o) => sum + o.hrvDeltaMs,
        ) /
        count;
    final avgCkPct = outcomes.fold<double>(
          0.0,
          (sum, o) => sum + o.ckReductionPercent,
        ) /
        count;

    final charterCost =
        effectiveTransport == TransferTransportDecision.airCharterForLeaders
            ? config.charterFlightCostEur
            : 0;

    final summaryBuffer = StringBuffer()
      ..write('Triaż etapu ${config.stageDay}: ')
      ..write(
          'Wykorzystano $totalUsedMinutes/${config.totalSpecialistMinutes} min sztabu. ')
      ..write(
          'Gotowość drużyny: ${avgBefore.toStringAsFixed(1)} → ${avgAfter.toStringAsFixed(1)}/100. ');
    if (effectiveTransport == TransferTransportDecision.airCharterForLeaders) {
      summaryBuffer.write(
          'Czarter lotniczy zapewnił liderom +${config.charterSleepBonusHours.toStringAsFixed(1)}h snu.');
    } else {
      summaryBuffer.write('Wybrano 4-godzinny transfer autokarem.');
    }

    return GrandTourPhysiotherapyTriageReport(
      stageDay: config.stageDay,
      transportDecision: effectiveTransport,
      totalSpecialistMinutesAvailable: config.totalSpecialistMinutes,
      totalSpecialistMinutesUsed: totalUsedMinutes,
      totalTreatmentCostEur: totalTreatmentCost,
      charterCostEur: charterCost,
      totalCostEur: totalTreatmentCost + charterCost,
      averageTeamReadinessBefore: _round1(avgBefore),
      averageTeamReadinessAfter: _round1(avgAfter),
      averageTeamHrvDeltaMs: _round1(avgHrvDelta),
      averageTeamCkReductionPct: _round1(avgCkPct),
      riderOutcomes: List.unmodifiable(outcomes),
      medicalSummaryPl: summaryBuffer.toString(),
    );
  }

  /// Konwertuje wyniki raportu porannego [GrandTourTeamMorningReport] na listę wejść do triażu.
  static List<RiderPostStageTriageInput> fromMorningReport({
    required GrandTourTeamMorningReport report,
    required Map<String, RiderBaselineBiomarkers> baselines,
    Map<String, GrandTourTriageRole> rolesByRiderId = const {},
    Set<String> crashedRiderIds = const {},
    Map<String, int> contusionDaysByRiderId = const {},
  }) {
    return report.rosterSamples.map((sample) {
      final baseline = baselines[sample.riderId];
      final crashed = crashedRiderIds.contains(sample.riderId);
      final contusionDays =
          contusionDaysByRiderId[sample.riderId] ?? (crashed ? 3 : 0);
      return RiderPostStageTriageInput(
        riderId: sample.riderId,
        riderName: sample.riderName,
        role: rolesByRiderId[sample.riderId] ??
            GrandTourTriageRole.rouleurDomestique,
        currentHrvMs: sample.hrvRmssdMs,
        baselineHrvMs: baseline?.baselineHrvRmssdMs ?? 78.0,
        currentCkUL: sample.creatineKinaseUL,
        currentReadinessScore: sample.readinessScore,
        plannedSleepHoursWithBus: sample.totalSleepHours,
        crashedOnStage: crashed,
        contusionHealingDaysRemaining: contusionDays,
        contusionPainPenalty: crashed ? 8.5 : 0.0,
      );
    }).toList(growable: false);
  }

  double _riderTriagePriorityScore(RiderPostStageTriageInput rider) {
    double score = 0.0;
    if (rider.role == GrandTourTriageRole.gcLeader) score += 45.0;
    if (rider.role == GrandTourTriageRole.sprinterLeader) score += 35.0;
    if (rider.needsTraumaCare) score += 40.0;
    if (rider.hasHighCkAlert) score += 20.0;
    if (rider.hasSuppressedHrv) score += 18.0;
    score += (100.0 - rider.currentReadinessScore) * 0.4;
    return score;
  }

  static double _round1(double v) => double.parse(v.toStringAsFixed(1));
}

/// Stan Riverpod dla wieczornego triażu fizjoterapeutycznego i logistyki snu.
class GrandTourPhysiotherapyTriageState {
  final PhysiotherapyTriageConfig config;
  final List<RiderPostStageTriageInput> squad;
  final List<PhysiotherapyTreatmentAssignment> assignments;
  final TransferTransportDecision transportDecision;
  final int availableBudgetEur;
  final GrandTourPhysiotherapyTriageReport? lastCommittedReport;
  final String? lastErrorMessage;

  const GrandTourPhysiotherapyTriageState({
    required this.config,
    required this.squad,
    required this.assignments,
    required this.transportDecision,
    required this.availableBudgetEur,
    this.lastCommittedReport,
    this.lastErrorMessage,
  });

  factory GrandTourPhysiotherapyTriageState.demo({
    int stageDay = 12,
    int availableBudgetEur = 120000,
  }) {
    final squad = <RiderPostStageTriageInput>[
      const RiderPostStageTriageInput(
        riderId: 'r1',
        riderName: 'K. Majka-Nowak',
        role: GrandTourTriageRole.gcLeader,
        currentHrvMs: 64.0,
        baselineHrvMs: 82.0,
        currentCkUL: 1120.0,
        currentReadinessScore: 61.5,
        plannedSleepHoursWithBus: 6.1,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r2',
        riderName: 'M. Kowalski',
        role: GrandTourTriageRole.sprinterLeader,
        currentHrvMs: 69.0,
        baselineHrvMs: 79.0,
        currentCkUL: 780.0,
        currentReadinessScore: 68.0,
        plannedSleepHoursWithBus: 6.2,
        crashedOnStage: true,
        contusionHealingDaysRemaining: 4,
        contusionPainPenalty: 9.0,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r3',
        riderName: 'L. Van Der Berg',
        role: GrandTourTriageRole.mountainDomestique,
        currentHrvMs: 61.0,
        baselineHrvMs: 76.0,
        currentCkUL: 980.0,
        currentReadinessScore: 63.0,
        plannedSleepHoursWithBus: 6.0,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r4',
        riderName: 'A. Moretti',
        role: GrandTourTriageRole.mountainDomestique,
        currentHrvMs: 72.0,
        baselineHrvMs: 78.0,
        currentCkUL: 860.0,
        currentReadinessScore: 70.0,
        plannedSleepHoursWithBus: 6.3,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r5',
        riderName: 'P. Zieliński',
        role: GrandTourTriageRole.roadCaptain,
        currentHrvMs: 68.0,
        baselineHrvMs: 74.0,
        currentCkUL: 690.0,
        currentReadinessScore: 72.5,
        plannedSleepHoursWithBus: 6.4,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r6',
        riderName: 'J. Lefèvre',
        role: GrandTourTriageRole.rouleurDomestique,
        currentHrvMs: 66.0,
        baselineHrvMs: 75.0,
        currentCkUL: 910.0,
        currentReadinessScore: 65.0,
        plannedSleepHoursWithBus: 6.1,
        crashedOnStage: true,
        contusionHealingDaysRemaining: 2,
        contusionPainPenalty: 6.5,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r7',
        riderName: 'T. Lindqvist',
        role: GrandTourTriageRole.rouleurDomestique,
        currentHrvMs: 75.0,
        baselineHrvMs: 77.0,
        currentCkUL: 610.0,
        currentReadinessScore: 76.0,
        plannedSleepHoursWithBus: 6.3,
      ),
      const RiderPostStageTriageInput(
        riderId: 'r8',
        riderName: 'D. Serrano',
        role: GrandTourTriageRole.rouleurDomestique,
        currentHrvMs: 71.0,
        baselineHrvMs: 76.0,
        currentCkUL: 650.0,
        currentReadinessScore: 74.0,
        plannedSleepHoursWithBus: 6.2,
      ),
    ];

    return GrandTourPhysiotherapyTriageState(
      config: PhysiotherapyTriageConfig(stageDay: stageDay),
      squad: squad,
      assignments: const [],
      transportDecision: TransferTransportDecision.fourHourTeamBus,
      availableBudgetEur: availableBudgetEur,
    );
  }

  int get usedSpecialistMinutes =>
      assignments.fold<int>(0, (sum, a) => sum + a.durationMinutes);

  int get remainingSpecialistMinutes =>
      math.max(0, config.totalSpecialistMinutes - usedSpecialistMinutes);

  bool get canAffordCharter => availableBudgetEur >= config.charterFlightCostEur;

  GrandTourPhysiotherapyTriageState copyWith({
    PhysiotherapyTriageConfig? config,
    List<RiderPostStageTriageInput>? squad,
    List<PhysiotherapyTreatmentAssignment>? assignments,
    TransferTransportDecision? transportDecision,
    int? availableBudgetEur,
    GrandTourPhysiotherapyTriageReport? lastCommittedReport,
    bool clearCommittedReport = false,
    String? lastErrorMessage,
    bool clearError = false,
  }) {
    return GrandTourPhysiotherapyTriageState(
      config: config ?? this.config,
      squad: squad ?? this.squad,
      assignments: assignments ?? this.assignments,
      transportDecision: transportDecision ?? this.transportDecision,
      availableBudgetEur: availableBudgetEur ?? this.availableBudgetEur,
      lastCommittedReport: clearCommittedReport
          ? null
          : (lastCommittedReport ?? this.lastCommittedReport),
      lastErrorMessage:
          clearError ? null : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }
}

/// Kontroler stanu triażu fizjoterapeutycznego i logistyki snu.
class GrandTourPhysiotherapyTriageNotifier
    extends StateNotifier<GrandTourPhysiotherapyTriageState> {
  final GrandTourPhysiotherapyTriageService _service;

  GrandTourPhysiotherapyTriageNotifier({
    GrandTourPhysiotherapyTriageService service =
        const GrandTourPhysiotherapyTriageService(),
    GrandTourPhysiotherapyTriageState? initialState,
  })  : _service = service,
        super(initialState ?? GrandTourPhysiotherapyTriageState.demo());

  void toggleTreatment({
    required String riderId,
    required PhysiotherapyTreatmentType treatment,
  }) {
    final existingIdx = state.assignments.indexWhere(
      (a) => a.riderId == riderId && a.treatment == treatment,
    );

    if (existingIdx >= 0) {
      final updated = List<PhysiotherapyTreatmentAssignment>.from(
        state.assignments,
      )..removeAt(existingIdx);
      state = state.copyWith(
        assignments: List.unmodifiable(updated),
        clearError: true,
      );
      return;
    }

    final check = _service.canAssignTreatment(
      riderId: riderId,
      treatment: treatment,
      currentAssignments: state.assignments,
      config: state.config,
    );

    if (!check.allowed) {
      state = state.copyWith(lastErrorMessage: check.reasonPl);
      return;
    }

    final specialistIdx = _service.pickLeastLoadedSpecialistIndex(
      currentAssignments: state.assignments,
      specialistCount: state.config.specialistCount,
    );

    final updated = List<PhysiotherapyTreatmentAssignment>.from(
      state.assignments,
    )..add(
        PhysiotherapyTreatmentAssignment(
          riderId: riderId,
          treatment: treatment,
          specialistSlotIndex: specialistIdx,
          durationMinutes: treatment.defaultDurationMinutes,
        ),
      );

    state = state.copyWith(
      assignments: List.unmodifiable(updated),
      clearError: true,
    );
  }

  void setTransportDecision(TransferTransportDecision decision) {
    if (decision == TransferTransportDecision.airCharterForLeaders &&
        !state.canAffordCharter) {
      state = state.copyWith(
        lastErrorMessage:
            'Niewystarczający budżet na czarter lotniczy (${state.config.charterFlightCostEur} €).',
      );
      return;
    }
    state = state.copyWith(
      transportDecision: decision,
      clearError: true,
    );
  }

  void applyAutoTriage() {
    final auto = _service.autoAssignOptimalTriage(
      squad: state.squad,
      config: state.config,
    );
    state = state.copyWith(
      assignments: auto,
      clearError: true,
    );
  }

  void clearAllAssignments() {
    state = state.copyWith(
      assignments: const [],
      clearError: true,
      clearCommittedReport: true,
    );
  }

  GrandTourPhysiotherapyTriageReport previewReport() {
    return _service.evaluateTriagePlan(
      squad: state.squad,
      assignments: state.assignments,
      transportDecision: state.transportDecision,
      config: state.config,
      availableBudgetEur: state.availableBudgetEur,
    );
  }

  GrandTourPhysiotherapyTriageReport commitTriagePlan() {
    final report = previewReport();
    final remainingBudget =
        math.max(0, state.availableBudgetEur - report.totalCostEur);
    state = state.copyWith(
      availableBudgetEur: remainingBudget,
      lastCommittedReport: report,
      clearError: true,
    );
    return report;
  }
}

final grandTourPhysiotherapyTriageServiceProvider =
    Provider<GrandTourPhysiotherapyTriageService>(
  (ref) => const GrandTourPhysiotherapyTriageService(),
);

final grandTourPhysiotherapyTriageProvider = StateNotifierProvider<
    GrandTourPhysiotherapyTriageNotifier, GrandTourPhysiotherapyTriageState>(
  (ref) => GrandTourPhysiotherapyTriageNotifier(
    service: ref.watch(grandTourPhysiotherapyTriageServiceProvider),
  ),
);

/// Responsywny panel triażu fizjoterapeutycznego i logistyki snu (390x844 / 1024x768 / 1600x900).
class GrandTourPhysiotherapyTriagePanel extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final ValueChanged<GrandTourPhysiotherapyTriageReport>? onPlanCommitted;

  const GrandTourPhysiotherapyTriagePanel({
    super.key,
    this.isReadOnly = false,
    this.onPlanCommitted,
  });

  @override
  ConsumerState<GrandTourPhysiotherapyTriagePanel> createState() =>
      _GrandTourPhysiotherapyTriagePanelState();
}

class _GrandTourPhysiotherapyTriagePanelState
    extends ConsumerState<GrandTourPhysiotherapyTriagePanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(grandTourPhysiotherapyTriageProvider);
    final notifier = ref.read(grandTourPhysiotherapyTriageProvider.notifier);
    final preview = notifier.previewReport();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 680;
        final isWide = width >= 1180;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, preview, isCompact),
                const SizedBox(height: 16),
                _buildLogisticsCard(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.lastErrorMessage != null) ...[
                  _buildErrorBanner(state.lastErrorMessage!),
                  const SizedBox(height: 12),
                ],
                _buildActionToolbar(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.squad.isEmpty)
                  _buildEmptySquadCard()
                else if (isWide)
                  _buildWideRosterGrid(state, preview, notifier)
                else
                  _buildStackedRosterList(state, preview, notifier, isCompact),
                if (state.lastCommittedReport != null) ...[
                  const SizedBox(height: 16),
                  _buildCommittedSummary(state.lastCommittedReport!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    GrandTourPhysiotherapyTriageState state,
    GrandTourPhysiotherapyTriageReport preview,
    bool isCompact,
  ) {
    final used = state.usedSpecialistMinutes;
    final total = state.config.totalSpecialistMinutes;
    final ratio = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.medical_services_rounded,
                    color: AppColors.goldAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Triaż Fizjoterapii — Etap ${state.config.stageDay}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '${state.config.specialistCount} specjalistów • $used / $total min',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                ratio > 0.9 ? AppColors.amberWarning : AppColors.statusSuccess,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _metricChip(
                label: 'Gotowość',
                value:
                    '${preview.averageTeamReadinessBefore.toStringAsFixed(1)} → ${preview.averageTeamReadinessAfter.toStringAsFixed(1)}',
                color: AppColors.statusSuccess,
              ),
              _metricChip(
                label: 'Śr. HRV',
                value: '+${preview.averageTeamHrvDeltaMs.toStringAsFixed(1)} ms',
                color: AppColors.cyanAccent,
              ),
              _metricChip(
                label: 'Redukcja CK',
                value: '-${preview.averageTeamCkReductionPct.toStringAsFixed(1)}%',
                color: AppColors.goldAccent,
              ),
              _metricChip(
                label: 'Budżet',
                value: '${state.availableBudgetEur} €',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLogisticsCard(
    GrandTourPhysiotherapyTriageState state,
    GrandTourPhysiotherapyTriageNotifier notifier,
    bool isCompact,
  ) {
    final isCharter =
        state.transportDecision == TransferTransportDecision.airCharterForLeaders;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCharter ? AppColors.goldAccent : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logistyka Transferu i Snu po Etapie',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TriageInteractiveButton(
                label: 'Autobus Drużyny (4h • 0 €)',
                isActive: !isCharter,
                isDisabled: widget.isReadOnly,
                activeColor: AppColors.primaryAccent,
                onTap: () => notifier.setTransportDecision(
                  TransferTransportDecision.fourHourTeamBus,
                ),
              ),
              _TriageInteractiveButton(
                label:
                    'Czarter Lotniczy Liderów (+2h snu • ${state.config.charterFlightCostEur} €)',
                isActive: isCharter,
                isDisabled: widget.isReadOnly || !state.canAffordCharter,
                activeColor: AppColors.goldAccent,
                onTap: () => notifier.setTransportDecision(
                  TransferTransportDecision.airCharterForLeaders,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(
    GrandTourPhysiotherapyTriageState state,
    GrandTourPhysiotherapyTriageNotifier notifier,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _TriageInteractiveButton(
              label: 'Auto-Przydział Sztabu',
              isActive: false,
              isDisabled: widget.isReadOnly || state.squad.isEmpty,
              activeColor: AppColors.accentBlue,
              icon: Icons.auto_fix_high_rounded,
              onTap: notifier.applyAutoTriage,
            ),
            _TriageInteractiveButton(
              label: 'Wyczyść Przydziały',
              isActive: false,
              isDisabled: widget.isReadOnly || state.assignments.isEmpty,
              activeColor: AppColors.crimsonAlert,
              icon: Icons.refresh_rounded,
              onTap: notifier.clearAllAssignments,
            ),
          ],
        ),
        _TriageInteractiveButton(
          label: 'Zatwierdź Plan Nocy',
          isActive: true,
          isDisabled: widget.isReadOnly || state.squad.isEmpty,
          activeColor: AppColors.statusSuccess,
          icon: Icons.check_circle_outline_rounded,
          onTap: () {
            final report = notifier.commitTriagePlan();
            widget.onPlanCommitted?.call(report);
          },
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonAlert),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.crimsonAlert,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySquadCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(
        child: Text(
          'Brak kolarzy w składzie do nocnego triażu.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildWideRosterGrid(
    GrandTourPhysiotherapyTriageState state,
    GrandTourPhysiotherapyTriageReport preview,
    GrandTourPhysiotherapyTriageNotifier notifier,
  ) {
    final rows = <Widget>[];
    for (int i = 0; i < state.squad.length; i += 2) {
      final first = state.squad[i];
      final firstOutcome = preview.riderOutcomes[i];
      final second = i + 1 < state.squad.length ? state.squad[i + 1] : null;
      final secondOutcome =
          i + 1 < preview.riderOutcomes.length ? preview.riderOutcomes[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRiderCard(
                  rider: first,
                  outcome: firstOutcome,
                  state: state,
                  notifier: notifier,
                  isCompact: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: second != null && secondOutcome != null
                    ? _buildRiderCard(
                        rider: second,
                        outcome: secondOutcome,
                        state: state,
                        notifier: notifier,
                        isCompact: false,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildStackedRosterList(
    GrandTourPhysiotherapyTriageState state,
    GrandTourPhysiotherapyTriageReport preview,
    GrandTourPhysiotherapyTriageNotifier notifier,
    bool isCompact,
  ) {
    return Column(
      children: [
        for (int i = 0; i < state.squad.length; i++) ...[
          _buildRiderCard(
            rider: state.squad[i],
            outcome: preview.riderOutcomes[i],
            state: state,
            notifier: notifier,
            isCompact: isCompact,
          ),
          if (i < state.squad.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildRiderCard({
    required RiderPostStageTriageInput rider,
    required RiderTriageRecoveryOutcome outcome,
    required GrandTourPhysiotherapyTriageState state,
    required GrandTourPhysiotherapyTriageNotifier notifier,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rider.needsTraumaCare
              ? AppColors.amberWarning
              : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      rider.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: rider.role.isProtectedLeader
                          ? AppColors.goldAccent.withValues(alpha: 0.16)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rider.role.labelPl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: rider.role.isProtectedLeader
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Gotowość ${outcome.initialReadinessScore.toStringAsFixed(0)} → ${outcome.projectedReadinessScore.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _metricChip(
                label: 'CK',
                value:
                    '${outcome.initialCkUL.toStringAsFixed(0)} → ${outcome.projectedCkUL.toStringAsFixed(0)} U/L',
                color: rider.hasHighCkAlert
                    ? AppColors.amberWarning
                    : AppColors.textPrimary,
              ),
              _metricChip(
                label: 'HRV',
                value:
                    '${outcome.initialHrvMs.toStringAsFixed(0)} → ${outcome.projectedHrvMs.toStringAsFixed(0)} ms',
                color: AppColors.cyanAccent,
              ),
              _metricChip(
                label: 'Sen',
                value:
                    '${outcome.projectedSleepHours.toStringAsFixed(1)}h${outcome.receivedCharterFlightSleepBonus ? ' (+2h czarter)' : ''}',
                color: outcome.receivedCharterFlightSleepBonus
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              if (rider.needsTraumaCare)
                _metricChip(
                  label: 'Stłuczenia',
                  value:
                      '${outcome.initialContusionDays}d → ${outcome.projectedContusionDays}d',
                  color: AppColors.amberWarning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PhysiotherapyTreatmentType.values.map((treatment) {
              final isSelected = outcome.appliedTreatments.contains(treatment);
              final canAdd = state.remainingSpecialistMinutes >=
                  treatment.defaultDurationMinutes;
              final isDisabled =
                  widget.isReadOnly || (!isSelected && !canAdd);

              return _TriageInteractiveButton(
                label:
                    '${treatment.labelPl} (${treatment.shortEffectPl}, ${treatment.defaultDurationMinutes}m)',
                isActive: isSelected,
                isDisabled: isDisabled,
                activeColor: _treatmentColor(treatment),
                onTap: () => notifier.toggleTreatment(
                  riderId: rider.riderId,
                  treatment: treatment,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _treatmentColor(PhysiotherapyTreatmentType type) {
    switch (type) {
      case PhysiotherapyTreatmentType.deepFasciaMassage:
        return AppColors.primaryAccent;
      case PhysiotherapyTreatmentType.tecarAndUltrasound:
        return AppColors.amberWarning;
      case PhysiotherapyTreatmentType.wholeBodyCryotherapy:
        return AppColors.accentBlue;
    }
  }

  Widget _buildCommittedSummary(GrandTourPhysiotherapyTriageReport report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusSuccess),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppColors.statusSuccess,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${report.medicalSummaryPl} Koszt całkowity: ${report.totalCostEur} €.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriageInteractiveButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDisabled;
  final Color activeColor;
  final IconData? icon;
  final VoidCallback onTap;

  const _TriageInteractiveButton({
    required this.label,
    required this.isActive,
    required this.isDisabled,
    required this.activeColor,
    required this.onTap,
    this.icon,
  });

  @override
  State<_TriageInteractiveButton> createState() =>
      _TriageInteractiveButtonState();
}

class _TriageInteractiveButtonState extends State<_TriageInteractiveButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isActive
            ? widget.activeColor.withValues(alpha: 0.24)
            : (_isHovered
                ? AppColors.surfaceLight
                : AppColors.surface);

    final borderColor = widget.isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : widget.isActive
            ? widget.activeColor
            : (_isFocused || _isHovered
                ? AppColors.goldAccent
                : AppColors.cardBorder);

    final textColor = widget.isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isActive ? AppColors.textPrimary : AppColors.textSecondary);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isDisabled ? null : widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 15, color: textColor),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight:
                            widget.isActive ? FontWeight.w700 : FontWeight.w500,
                        color: textColor,
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
