// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_physiology.dart';

/// Stałe progowe i fizjologiczne modelu przetrenowania oraz wypalenia sezonowego.
class OvertrainingThresholds {
  OvertrainingThresholds._();

  /// Granica głębokiego ujemnego bilansu stresowego (TSB < -35).
  static const double unsafeTsbThreshold = -35.0;

  /// Próg ostrzegawczy funkcjonalnego przeciążenia (TSB < -25).
  static const double warningTsbThreshold = -25.0;

  /// Liczba dni z TSB < -35, powyżej której (> 14 dni) uruchamia się OTS.
  static const int consecutiveUnsafeDaysTrigger = 14;

  /// Maksymalna bezpieczna liczba dni wyścigowych w sezonie (powyżej > 85 dni -> wypalenie).
  static const int maxSafeRaceDaysPerSeason = 85;

  /// Próg ostrzegawczy liczby dni wyścigowych w sezonie.
  static const int warningRaceDaysThreshold = 75;

  /// Tłumienie tętna maksymalnego w zespole przetrenowania parasympatycznego [BPM].
  static const int parasympatheticMaxHrSuppressionBpm = 15;

  /// Spadek mocy progowej FTP w zespole przetrenowania parasympatycznego (8%).
  static const double parasympatheticFtpDropFraction = 0.08;

  /// Minimalne bezpieczne tętno maksymalne po zastosowaniu kary [BPM].
  static const int minimumEffectiveMaxHrBpm = 120;

  /// Minimalne bezpieczne FTP po zastosowaniu kary [W].
  static const int minimumEffectiveFtpWatts = 100;

  /// Liczba dni regeneracji z dodatnim TSB potrzebna do wyjścia z zespołu przetrenowania.
  static const int recoveryDaysRequiredToClearSyndrome = 10;
}

/// Poziom ciężkości przeciążenia treningowego i wypalenia kolarza.
enum OvertrainingSeverity {
  optimal,
  functionalOverreaching,
  nonFunctionalOverreaching,
  parasympatheticOvertraining,
  seasonalBurnout;

  String toJson() => name;

  static OvertrainingSeverity fromJson(String value) {
    return OvertrainingSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OvertrainingSeverity.optimal,
    );
  }

  /// Czy pełny zespół przetrenowania parasympatycznego (-15 BPM MaxHR, -8% FTP) jest aktywny.
  bool get isSyndromeActive =>
      this == OvertrainingSeverity.parasympatheticOvertraining ||
      this == OvertrainingSeverity.seasonalBurnout;

  String get labelPl {
    switch (this) {
      case OvertrainingSeverity.optimal:
        return 'Równowaga Fizjologiczna';
      case OvertrainingSeverity.functionalOverreaching:
        return 'Przeciążenie Funkcjonalne';
      case OvertrainingSeverity.nonFunctionalOverreaching:
        return 'Przeciążenie Niefunkcjonalne';
      case OvertrainingSeverity.parasympatheticOvertraining:
        return 'Przetrenowanie Parasympatyczne';
      case OvertrainingSeverity.seasonalBurnout:
        return 'Wypalenie Sezonowe (OTS)';
    }
  }

  String get shortCode {
    switch (this) {
      case OvertrainingSeverity.optimal:
        return 'OPT';
      case OvertrainingSeverity.functionalOverreaching:
        return 'FO';
      case OvertrainingSeverity.nonFunctionalOverreaching:
        return 'NFO';
      case OvertrainingSeverity.parasympatheticOvertraining:
        return 'OTS';
      case OvertrainingSeverity.seasonalBurnout:
        return 'BURN';
    }
  }
}

/// Bezpośrednia przyczyna wywołania zespołu przetrenowania lub ostrzeżenia.
enum OvertrainingTriggerReason {
  none,
  prolongedDeepNegativeTsb,
  excessiveSeasonRaceDays,
  dualLoadAndRaceBurnout;

  String toJson() => name;

  static OvertrainingTriggerReason fromJson(String value) {
    return OvertrainingTriggerReason.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => OvertrainingTriggerReason.none,
    );
  }

  String get labelPl {
    switch (this) {
      case OvertrainingTriggerReason.none:
        return 'Brak przekroczeń progów bezpieczeństwa';
      case OvertrainingTriggerReason.prolongedDeepNegativeTsb:
        return 'TSB < -35 utrzymywane przez ponad 14 dni';
      case OvertrainingTriggerReason.excessiveSeasonRaceDays:
        return 'Przekroczony limit >85 dni wyścigowych w sezonie';
      case OvertrainingTriggerReason.dualLoadAndRaceBurnout:
        return 'Kumulacja: TSB < -35 (>14 dni) oraz >85 dni wyścigowych';
    }
  }
}

/// Zalecana interwencja medyczno-treningowa po diagnozie przetrenowania.
enum BurnoutRecoveryIntervention {
  completeOffBikeRest,
  activeZone1Recovery,
  seasonEndShutdown,
  medicalHormonalScreening;

  String toJson() => name;

  static BurnoutRecoveryIntervention fromJson(String value) {
    return BurnoutRecoveryIntervention.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BurnoutRecoveryIntervention.activeZone1Recovery,
    );
  }

  String get labelPl {
    switch (this) {
      case BurnoutRecoveryIntervention.completeOffBikeRest:
        return 'Całkowity odpoczynek bez roweru (7–14 dni)';
      case BurnoutRecoveryIntervention.activeZone1Recovery:
        return 'Rozjazdy regeneracyjne Z1 (<55% FTP)';
      case BurnoutRecoveryIntervention.seasonEndShutdown:
        return 'Zakończenie startów i roztrenowanie posezonowe';
      case BurnoutRecoveryIntervention.medicalHormonalScreening:
        return 'Panel hormonalny (kortyzol/testosteron) i kontrola HRV';
    }
  }
}

/// Dzienny stan śledzenia obciążenia i wypalenia konkretnego kolarza w karierze.
class RiderBurnoutTrackerState {
  final String riderId;
  final int consecutiveDeepNegativeTsbDays;
  final int seasonRaceDaysCount;
  final bool parasympatheticSyndromeActive;
  final int recoveryDaysCompleted;
  final DateTime? lastEvaluatedDate;
  final List<double> recentTsbHistory;

  const RiderBurnoutTrackerState({
    required this.riderId,
    this.consecutiveDeepNegativeTsbDays = 0,
    this.seasonRaceDaysCount = 0,
    this.parasympatheticSyndromeActive = false,
    this.recoveryDaysCompleted = 0,
    this.lastEvaluatedDate,
    this.recentTsbHistory = const <double>[],
  });

  RiderBurnoutTrackerState copyWith({
    String? riderId,
    int? consecutiveDeepNegativeTsbDays,
    int? seasonRaceDaysCount,
    bool? parasympatheticSyndromeActive,
    int? recoveryDaysCompleted,
    DateTime? lastEvaluatedDate,
    bool clearLastEvaluatedDate = false,
    List<double>? recentTsbHistory,
  }) {
    return RiderBurnoutTrackerState(
      riderId: riderId ?? this.riderId,
      consecutiveDeepNegativeTsbDays:
          consecutiveDeepNegativeTsbDays ?? this.consecutiveDeepNegativeTsbDays,
      seasonRaceDaysCount: seasonRaceDaysCount ?? this.seasonRaceDaysCount,
      parasympatheticSyndromeActive:
          parasympatheticSyndromeActive ?? this.parasympatheticSyndromeActive,
      recoveryDaysCompleted:
          recoveryDaysCompleted ?? this.recoveryDaysCompleted,
      lastEvaluatedDate: clearLastEvaluatedDate
          ? null
          : (lastEvaluatedDate ?? this.lastEvaluatedDate),
      recentTsbHistory: recentTsbHistory ?? this.recentTsbHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'consecutiveDeepNegativeTsbDays': consecutiveDeepNegativeTsbDays,
      'seasonRaceDaysCount': seasonRaceDaysCount,
      'parasympatheticSyndromeActive': parasympatheticSyndromeActive,
      'recoveryDaysCompleted': recoveryDaysCompleted,
      'lastEvaluatedDate': lastEvaluatedDate?.toIso8601String(),
      'recentTsbHistory': recentTsbHistory,
    };
  }

  factory RiderBurnoutTrackerState.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['recentTsbHistory'] as List<dynamic>? ?? const [];
    return RiderBurnoutTrackerState(
      riderId: json['riderId'] as String,
      consecutiveDeepNegativeTsbDays:
          (json['consecutiveDeepNegativeTsbDays'] as num?)?.toInt() ?? 0,
      seasonRaceDaysCount:
          (json['seasonRaceDaysCount'] as num?)?.toInt() ?? 0,
      parasympatheticSyndromeActive:
          json['parasympatheticSyndromeActive'] as bool? ?? false,
      recoveryDaysCompleted:
          (json['recoveryDaysCompleted'] as num?)?.toInt() ?? 0,
      lastEvaluatedDate: json['lastEvaluatedDate'] != null
          ? DateTime.parse(json['lastEvaluatedDate'] as String)
          : null,
      recentTsbHistory:
          rawHistory.map((e) => (e as num).toDouble()).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RiderBurnoutTrackerState) return false;
    if (other.riderId != riderId ||
        other.consecutiveDeepNegativeTsbDays !=
            consecutiveDeepNegativeTsbDays ||
        other.seasonRaceDaysCount != seasonRaceDaysCount ||
        other.parasympatheticSyndromeActive != parasympatheticSyndromeActive ||
        other.recoveryDaysCompleted != recoveryDaysCompleted ||
        other.lastEvaluatedDate != lastEvaluatedDate ||
        other.recentTsbHistory.length != recentTsbHistory.length) {
      return false;
    }
    for (int i = 0; i < recentTsbHistory.length; i++) {
      if (other.recentTsbHistory[i] != recentTsbHistory[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        riderId,
        consecutiveDeepNegativeTsbDays,
        seasonRaceDaysCount,
        parasympatheticSyndromeActive,
        recoveryDaysCompleted,
        lastEvaluatedDate,
        Object.hashAll(recentTsbHistory),
      );
}

/// Pełny raport diagnostyczny przetrenowania i wypalenia kolarza.
class OvertrainingDiagnosisReport {
  final String riderId;
  final String riderName;
  final OvertrainingSeverity severity;
  final OvertrainingTriggerReason triggerReason;
  final bool parasympatheticSyndromeTriggered;
  final double currentTsb;
  final int consecutiveDaysBelowTsbLimit;
  final int seasonRaceDays;
  final int baselineMaxHrBpm;
  final int effectiveMaxHrBpm;
  final int maxHrSuppressionBpm;
  final int baselineFtpWatts;
  final int effectiveFtpWatts;
  final double ftpDropPercentage;
  final double effectiveWattsPerKg;
  final int restingHrDeltaBpm;
  final double burnoutRiskScore;
  final int recommendedRestDays;
  final List<BurnoutRecoveryIntervention> recommendedInterventions;
  final String clinicalSummaryPl;
  final DateTime diagnosedAt;

  const OvertrainingDiagnosisReport({
    required this.riderId,
    required this.riderName,
    required this.severity,
    required this.triggerReason,
    required this.parasympatheticSyndromeTriggered,
    required this.currentTsb,
    required this.consecutiveDaysBelowTsbLimit,
    required this.seasonRaceDays,
    required this.baselineMaxHrBpm,
    required this.effectiveMaxHrBpm,
    required this.maxHrSuppressionBpm,
    required this.baselineFtpWatts,
    required this.effectiveFtpWatts,
    required this.ftpDropPercentage,
    required this.effectiveWattsPerKg,
    required this.restingHrDeltaBpm,
    required this.burnoutRiskScore,
    required this.recommendedRestDays,
    required this.recommendedInterventions,
    required this.clinicalSummaryPl,
    required this.diagnosedAt,
  });

  /// Nakłada wyliczone tłumienie tętna (-15 BPM) i spadek FTP (-8%) na model fizjologii.
  RiderPhysiology applyToPhysiology(RiderPhysiology physiology) {
    if (!parasympatheticSyndromeTriggered) {
      return physiology;
    }
    final suppressedMaxHr = math.max(
      OvertrainingThresholds.minimumEffectiveMaxHrBpm,
      physiology.maxHr - maxHrSuppressionBpm,
    );
    final reducedFtp = math.max(
      OvertrainingThresholds.minimumEffectiveFtpWatts,
      (physiology.ftpWatts * (1.0 - ftpDropPercentage)).round(),
    );
    final adjustedRestingHr =
        math.max(32, physiology.restingHr + restingHrDeltaBpm);
    final adjustedLactateHr = math.min(
      suppressedMaxHr - 5,
      math.max(adjustedRestingHr + 20, physiology.lactateThresholdHr - 8),
    );

    return physiology.copyWith(
      maxHr: suppressedMaxHr,
      ftpWatts: reducedFtp,
      restingHr: adjustedRestingHr,
      lactateThresholdHr: adjustedLactateHr,
    );
  }

  /// Zwraca kopię kolarza ze zmodyfikowaną fizjologią w razie aktywnego zespołu OTS.
  Rider applyToRider(Rider rider) {
    if (!parasympatheticSyndromeTriggered) {
      return rider;
    }
    return rider.copyWith(
      physiology: applyToPhysiology(rider.physiology),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'severity': severity.toJson(),
      'triggerReason': triggerReason.toJson(),
      'parasympatheticSyndromeTriggered': parasympatheticSyndromeTriggered,
      'currentTsb': currentTsb,
      'consecutiveDaysBelowTsbLimit': consecutiveDaysBelowTsbLimit,
      'seasonRaceDays': seasonRaceDays,
      'baselineMaxHrBpm': baselineMaxHrBpm,
      'effectiveMaxHrBpm': effectiveMaxHrBpm,
      'maxHrSuppressionBpm': maxHrSuppressionBpm,
      'baselineFtpWatts': baselineFtpWatts,
      'effectiveFtpWatts': effectiveFtpWatts,
      'ftpDropPercentage': ftpDropPercentage,
      'effectiveWattsPerKg': effectiveWattsPerKg,
      'restingHrDeltaBpm': restingHrDeltaBpm,
      'burnoutRiskScore': burnoutRiskScore,
      'recommendedRestDays': recommendedRestDays,
      'recommendedInterventions':
          recommendedInterventions.map((e) => e.toJson()).toList(),
      'clinicalSummaryPl': clinicalSummaryPl,
      'diagnosedAt': diagnosedAt.toIso8601String(),
    };
  }

  factory OvertrainingDiagnosisReport.fromJson(Map<String, dynamic> json) {
    final rawInterventions =
        json['recommendedInterventions'] as List<dynamic>? ?? const [];
    return OvertrainingDiagnosisReport(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      severity: OvertrainingSeverity.fromJson(json['severity'] as String),
      triggerReason: OvertrainingTriggerReason.fromJson(
        json['triggerReason'] as String,
      ),
      parasympatheticSyndromeTriggered:
          json['parasympatheticSyndromeTriggered'] as bool,
      currentTsb: (json['currentTsb'] as num).toDouble(),
      consecutiveDaysBelowTsbLimit:
          (json['consecutiveDaysBelowTsbLimit'] as num).toInt(),
      seasonRaceDays: (json['seasonRaceDays'] as num).toInt(),
      baselineMaxHrBpm: (json['baselineMaxHrBpm'] as num).toInt(),
      effectiveMaxHrBpm: (json['effectiveMaxHrBpm'] as num).toInt(),
      maxHrSuppressionBpm: (json['maxHrSuppressionBpm'] as num).toInt(),
      baselineFtpWatts: (json['baselineFtpWatts'] as num).toInt(),
      effectiveFtpWatts: (json['effectiveFtpWatts'] as num).toInt(),
      ftpDropPercentage: (json['ftpDropPercentage'] as num).toDouble(),
      effectiveWattsPerKg: (json['effectiveWattsPerKg'] as num).toDouble(),
      restingHrDeltaBpm: (json['restingHrDeltaBpm'] as num).toInt(),
      burnoutRiskScore: (json['burnoutRiskScore'] as num).toDouble(),
      recommendedRestDays: (json['recommendedRestDays'] as num).toInt(),
      recommendedInterventions: rawInterventions
          .map((e) => BurnoutRecoveryIntervention.fromJson(e as String))
          .toList(growable: false),
      clinicalSummaryPl: json['clinicalSummaryPl'] as String,
      diagnosedAt: DateTime.parse(json['diagnosedAt'] as String),
    );
  }
}

/// Zbiorczy audyt przetrenowania dla całego składu drużyny.
class TeamOvertrainingAuditSummary {
  final int totalRidersEvaluated;
  final int affectedRidersCount;
  final int warningRidersCount;
  final int healthyRidersCount;
  final List<OvertrainingDiagnosisReport> reports;

  const TeamOvertrainingAuditSummary({
    required this.totalRidersEvaluated,
    required this.affectedRidersCount,
    required this.warningRidersCount,
    required this.healthyRidersCount,
    required this.reports,
  });

  List<OvertrainingDiagnosisReport> get syndromeReports =>
      reports.where((r) => r.parasympatheticSyndromeTriggered).toList();
}

/// Zaawansowany model przetrenowania parasympatycznego i wypalenia sezonowego.
///
/// Przekroczenie bezpiecznego obciążenia treningowego (`TSB < -35` przez ponad
/// 14 dni lub `>85` dni wyścigowych w sezonie) wywołuje zespół przetrenowania
/// parasympatycznego: tłumienie tętna maksymalnego o `15 BPM` oraz spadek FTP o `8%`.
class OvertrainingAndBurnoutDiagnostics {
  const OvertrainingAndBurnoutDiagnostics();

  /// Przeprowadza pełną diagnozę stanu kolarza na podstawie obciążenia TSB i dni wyścigowych.
  OvertrainingDiagnosisReport evaluateRider({
    required Rider rider,
    required int consecutiveDaysBelowTsbLimit,
    required int seasonRaceDays,
    double? currentTsbOverride,
    bool forceSyndromeActive = false,
    DateTime? evaluationDate,
  }) {
    final safeConsecutiveDays = math.max(0, consecutiveDaysBelowTsbLimit);
    final safeRaceDays = math.max(0, seasonRaceDays);
    final currentTsb =
        currentTsbOverride ?? rider.health.trainingStressBalance;
    final diagnosedAt = evaluationDate ?? DateTime.now();

    final tsbTriggered =
        safeConsecutiveDays > OvertrainingThresholds.consecutiveUnsafeDaysTrigger;
    final raceDaysTriggered =
        safeRaceDays > OvertrainingThresholds.maxSafeRaceDaysPerSeason;
    final syndromeTriggered =
        tsbTriggered || raceDaysTriggered || forceSyndromeActive;

    final triggerReason = _resolveTriggerReason(
      tsbTriggered: tsbTriggered,
      raceDaysTriggered: raceDaysTriggered,
    );

    final severity = _resolveSeverity(
      syndromeTriggered: syndromeTriggered,
      tsbTriggered: tsbTriggered,
      raceDaysTriggered: raceDaysTriggered,
      currentTsb: currentTsb,
      consecutiveDaysBelowLimit: safeConsecutiveDays,
      seasonRaceDays: safeRaceDays,
    );

    final maxHrSuppression = syndromeTriggered
        ? OvertrainingThresholds.parasympatheticMaxHrSuppressionBpm
        : 0;
    final ftpDropFraction = syndromeTriggered
        ? OvertrainingThresholds.parasympatheticFtpDropFraction
        : 0.0;

    final baselineMaxHr = rider.physiology.maxHr;
    final effectiveMaxHr = syndromeTriggered
        ? math.max(
            OvertrainingThresholds.minimumEffectiveMaxHrBpm,
            baselineMaxHr - maxHrSuppression,
          )
        : baselineMaxHr;

    final baselineFtp = rider.physiology.ftpWatts;
    final effectiveFtp = syndromeTriggered
        ? math.max(
            OvertrainingThresholds.minimumEffectiveFtpWatts,
            (baselineFtp * (1.0 - ftpDropFraction)).round(),
          )
        : baselineFtp;

    final weightKg =
        rider.physiology.weightKg > 0.0 ? rider.physiology.weightKg : 70.0;
    final effectiveWPerKg = effectiveFtp / weightKg;

    // W zespole parasympatycznym dominacja nerwu błędnego obniża tętno spoczynkowe.
    final restingHrDelta = syndromeTriggered ? -4 : 0;

    final riskScore = _computeBurnoutRiskScore(
      currentTsb: currentTsb,
      consecutiveDaysBelowLimit: safeConsecutiveDays,
      seasonRaceDays: safeRaceDays,
      syndromeTriggered: syndromeTriggered,
    );

    final recommendedRestDays = _computeRecommendedRestDays(
      severity: severity,
      consecutiveDaysBelowLimit: safeConsecutiveDays,
      seasonRaceDays: safeRaceDays,
    );

    final interventions = _buildRecommendedInterventions(
      severity: severity,
      raceDaysTriggered: raceDaysTriggered,
    );

    final summaryPl = _buildClinicalSummaryPl(
      riderName: rider.fullName,
      severity: severity,
      triggerReason: triggerReason,
      effectiveMaxHr: effectiveMaxHr,
      baselineMaxHr: baselineMaxHr,
      effectiveFtp: effectiveFtp,
      baselineFtp: baselineFtp,
      consecutiveDaysBelowLimit: safeConsecutiveDays,
      seasonRaceDays: safeRaceDays,
      recommendedRestDays: recommendedRestDays,
    );

    return OvertrainingDiagnosisReport(
      riderId: rider.id,
      riderName: rider.fullName,
      severity: severity,
      triggerReason: triggerReason,
      parasympatheticSyndromeTriggered: syndromeTriggered,
      currentTsb: currentTsb,
      consecutiveDaysBelowTsbLimit: safeConsecutiveDays,
      seasonRaceDays: safeRaceDays,
      baselineMaxHrBpm: baselineMaxHr,
      effectiveMaxHrBpm: effectiveMaxHr,
      maxHrSuppressionBpm: maxHrSuppression,
      baselineFtpWatts: baselineFtp,
      effectiveFtpWatts: effectiveFtp,
      ftpDropPercentage: ftpDropFraction,
      effectiveWattsPerKg: effectiveWPerKg,
      restingHrDeltaBpm: restingHrDelta,
      burnoutRiskScore: riskScore,
      recommendedRestDays: recommendedRestDays,
      recommendedInterventions: interventions,
      clinicalSummaryPl: summaryPl,
      diagnosedAt: diagnosedAt,
    );
  }

  /// Aktualizuje dzienny stan śledzenia obciążenia (TSB i dni wyścigowe) kolarza.
  RiderBurnoutTrackerState recordDailyTelemetry({
    required RiderBurnoutTrackerState state,
    required double tsb,
    required bool racedToday,
    DateTime? date,
  }) {
    final nextRaceDays =
        state.seasonRaceDaysCount + (racedToday ? 1 : 0);

    int nextConsecutiveDeepTsbDays;
    if (tsb < OvertrainingThresholds.unsafeTsbThreshold) {
      nextConsecutiveDeepTsbDays = state.consecutiveDeepNegativeTsbDays + 1;
    } else if (tsb >= -20.0) {
      nextConsecutiveDeepTsbDays = 0;
    } else {
      // Strefa przejściowa [-35, -20): stopniowy spadek licznika przeciążenia.
      nextConsecutiveDeepTsbDays =
          math.max(0, state.consecutiveDeepNegativeTsbDays - 1);
    }

    final triggersMet = nextConsecutiveDeepTsbDays >
            OvertrainingThresholds.consecutiveUnsafeDaysTrigger ||
        nextRaceDays > OvertrainingThresholds.maxSafeRaceDaysPerSeason;

    int nextRecoveryDays = state.recoveryDaysCompleted;
    bool nextSyndromeActive = state.parasympatheticSyndromeActive || triggersMet;

    if (state.parasympatheticSyndromeActive && !triggersMet) {
      if (tsb >= 0.0 && !racedToday) {
        nextRecoveryDays += 1;
      } else {
        nextRecoveryDays = math.max(0, nextRecoveryDays - 1);
      }

      if (nextRecoveryDays >=
              OvertrainingThresholds.recoveryDaysRequiredToClearSyndrome &&
          nextRaceDays <= OvertrainingThresholds.maxSafeRaceDaysPerSeason) {
        nextSyndromeActive = false;
        nextRecoveryDays = 0;
      }
    } else if (triggersMet) {
      nextRecoveryDays = 0;
    }

    final updatedHistory = <double>[
      ...state.recentTsbHistory,
      tsb,
    ];
    final trimmedHistory = updatedHistory.length > 30
        ? updatedHistory.sublist(updatedHistory.length - 30)
        : updatedHistory;

    return state.copyWith(
      consecutiveDeepNegativeTsbDays: nextConsecutiveDeepTsbDays,
      seasonRaceDaysCount: nextRaceDays,
      parasympatheticSyndromeActive: nextSyndromeActive,
      recoveryDaysCompleted: nextRecoveryDays,
      lastEvaluatedDate: date ?? DateTime.now(),
      recentTsbHistory: trimmedHistory,
    );
  }

  /// Resetuje licznik dni wyścigowych i historię przeciążenia przy przejściu do nowego sezonu.
  RiderBurnoutTrackerState resetForNewSeason(RiderBurnoutTrackerState state) {
    return state.copyWith(
      consecutiveDeepNegativeTsbDays: 0,
      seasonRaceDaysCount: 0,
      parasympatheticSyndromeActive: false,
      recoveryDaysCompleted: 0,
      recentTsbHistory: const <double>[],
    );
  }

  /// Diagnozuje kolarza bezpośrednio na podstawie zapisanego stanu trackera kariery.
  OvertrainingDiagnosisReport evaluateFromTracker({
    required Rider rider,
    required RiderBurnoutTrackerState tracker,
    DateTime? evaluationDate,
  }) {
    final latestTsb = tracker.recentTsbHistory.isNotEmpty
        ? tracker.recentTsbHistory.last
        : rider.health.trainingStressBalance;

    return evaluateRider(
      rider: rider,
      consecutiveDaysBelowTsbLimit: tracker.consecutiveDeepNegativeTsbDays,
      seasonRaceDays: tracker.seasonRaceDaysCount,
      currentTsbOverride: latestTsb,
      forceSyndromeActive: tracker.parasympatheticSyndromeActive,
      evaluationDate: evaluationDate,
    );
  }

  /// Przeprowadza audyt całego składu drużyny i sortuje raporty od najbardziej zagrożonych.
  TeamOvertrainingAuditSummary auditSquad({
    required List<Rider> riders,
    required Map<String, RiderBurnoutTrackerState> trackers,
    DateTime? evaluationDate,
  }) {
    final reports = <OvertrainingDiagnosisReport>[];
    int affected = 0;
    int warning = 0;
    int healthy = 0;

    for (final rider in riders) {
      final tracker =
          trackers[rider.id] ?? RiderBurnoutTrackerState(riderId: rider.id);
      final report = evaluateFromTracker(
        rider: rider,
        tracker: tracker,
        evaluationDate: evaluationDate,
      );
      reports.add(report);

      if (report.parasympatheticSyndromeTriggered) {
        affected += 1;
      } else if (report.severity ==
              OvertrainingSeverity.nonFunctionalOverreaching ||
          report.severity == OvertrainingSeverity.functionalOverreaching) {
        warning += 1;
      } else {
        healthy += 1;
      }
    }

    reports.sort((a, b) => b.burnoutRiskScore.compareTo(a.burnoutRiskScore));

    return TeamOvertrainingAuditSummary(
      totalRidersEvaluated: riders.length,
      affectedRidersCount: affected,
      warningRidersCount: warning,
      healthyRidersCount: healthy,
      reports: List<OvertrainingDiagnosisReport>.unmodifiable(reports),
    );
  }

  /// Nakłada kary zespołu przetrenowania parasympatycznego (-15 BPM MaxHR, -8% FTP) na kolarza.
  Rider applyParasympatheticPenaltyToRider(
    Rider rider,
    OvertrainingDiagnosisReport report,
  ) {
    return report.applyToRider(rider);
  }

  OvertrainingTriggerReason _resolveTriggerReason({
    required bool tsbTriggered,
    required bool raceDaysTriggered,
  }) {
    if (tsbTriggered && raceDaysTriggered) {
      return OvertrainingTriggerReason.dualLoadAndRaceBurnout;
    }
    if (tsbTriggered) {
      return OvertrainingTriggerReason.prolongedDeepNegativeTsb;
    }
    if (raceDaysTriggered) {
      return OvertrainingTriggerReason.excessiveSeasonRaceDays;
    }
    return OvertrainingTriggerReason.none;
  }

  OvertrainingSeverity _resolveSeverity({
    required bool syndromeTriggered,
    required bool tsbTriggered,
    required bool raceDaysTriggered,
    required double currentTsb,
    required int consecutiveDaysBelowLimit,
    required int seasonRaceDays,
  }) {
    if (syndromeTriggered) {
      if (raceDaysTriggered && !tsbTriggered) {
        return OvertrainingSeverity.seasonalBurnout;
      }
      return OvertrainingSeverity.parasympatheticOvertraining;
    }

    if ((currentTsb < OvertrainingThresholds.unsafeTsbThreshold &&
            consecutiveDaysBelowLimit >= 7) ||
        seasonRaceDays >= OvertrainingThresholds.warningRaceDaysThreshold ||
        currentTsb < -45.0) {
      return OvertrainingSeverity.nonFunctionalOverreaching;
    }

    if (currentTsb < OvertrainingThresholds.warningTsbThreshold ||
        consecutiveDaysBelowLimit >= 3 ||
        seasonRaceDays >= 65) {
      return OvertrainingSeverity.functionalOverreaching;
    }

    return OvertrainingSeverity.optimal;
  }

  double _computeBurnoutRiskScore({
    required double currentTsb,
    required int consecutiveDaysBelowLimit,
    required int seasonRaceDays,
    required bool syndromeTriggered,
  }) {
    final tsbStreakRatio = (consecutiveDaysBelowLimit /
            (OvertrainingThresholds.consecutiveUnsafeDaysTrigger + 1))
        .clamp(0.0, 1.3);
    final raceDaysRatio =
        (seasonRaceDays / OvertrainingThresholds.maxSafeRaceDaysPerSeason)
            .clamp(0.0, 1.3);
    final acuteTsbStress = currentTsb < 0
        ? ((-currentTsb) / 50.0).clamp(0.0, 1.2)
        : 0.0;

    final rawScore =
        (tsbStreakRatio * 42.0) + (raceDaysRatio * 38.0) + (acuteTsbStress * 20.0);
    if (syndromeTriggered) {
      return math.max(85.0, rawScore).clamp(0.0, 100.0);
    }
    return rawScore.clamp(0.0, 84.0);
  }

  int _computeRecommendedRestDays({
    required OvertrainingSeverity severity,
    required int consecutiveDaysBelowLimit,
    required int seasonRaceDays,
  }) {
    switch (severity) {
      case OvertrainingSeverity.optimal:
        return 0;
      case OvertrainingSeverity.functionalOverreaching:
        return 3;
      case OvertrainingSeverity.nonFunctionalOverreaching:
        return 7;
      case OvertrainingSeverity.parasympatheticOvertraining:
        return math.min(21, 10 + (consecutiveDaysBelowLimit - 14).clamp(1, 11));
      case OvertrainingSeverity.seasonalBurnout:
        return math.min(28, 14 + (seasonRaceDays - 85).clamp(1, 14));
    }
  }

  List<BurnoutRecoveryIntervention> _buildRecommendedInterventions({
    required OvertrainingSeverity severity,
    required bool raceDaysTriggered,
  }) {
    switch (severity) {
      case OvertrainingSeverity.optimal:
        return const <BurnoutRecoveryIntervention>[];
      case OvertrainingSeverity.functionalOverreaching:
        return const <BurnoutRecoveryIntervention>[
          BurnoutRecoveryIntervention.activeZone1Recovery,
        ];
      case OvertrainingSeverity.nonFunctionalOverreaching:
        return const <BurnoutRecoveryIntervention>[
          BurnoutRecoveryIntervention.activeZone1Recovery,
          BurnoutRecoveryIntervention.medicalHormonalScreening,
        ];
      case OvertrainingSeverity.parasympatheticOvertraining:
        return <BurnoutRecoveryIntervention>[
          BurnoutRecoveryIntervention.completeOffBikeRest,
          BurnoutRecoveryIntervention.medicalHormonalScreening,
          if (raceDaysTriggered) BurnoutRecoveryIntervention.seasonEndShutdown,
        ];
      case OvertrainingSeverity.seasonalBurnout:
        return const <BurnoutRecoveryIntervention>[
          BurnoutRecoveryIntervention.seasonEndShutdown,
          BurnoutRecoveryIntervention.completeOffBikeRest,
          BurnoutRecoveryIntervention.medicalHormonalScreening,
        ];
    }
  }

  String _buildClinicalSummaryPl({
    required String riderName,
    required OvertrainingSeverity severity,
    required OvertrainingTriggerReason triggerReason,
    required int effectiveMaxHr,
    required int baselineMaxHr,
    required int effectiveFtp,
    required int baselineFtp,
    required int consecutiveDaysBelowLimit,
    required int seasonRaceDays,
    required int recommendedRestDays,
  }) {
    if (!severity.isSyndromeActive) {
      if (severity == OvertrainingSeverity.optimal) {
        return '$riderName: obciążenie treningowe pod kontrolą ($seasonRaceDays/85 dni wyścigowych).';
      }
      return '$riderName: ${severity.labelPl} — seria $consecutiveDaysBelowLimit dni z TSB < -35, '
          '$seasonRaceDays/85 dni wyścigowych. Zalecane $recommendedRestDays dni regeneracji.';
    }

    return '$riderName: AKTYWNY ZESPÓŁ PRZETRENOWANIA PARASYMPATYCZNEGO (${triggerReason.labelPl}). '
        'Tętno maksymalne stłumione: $baselineMaxHr -> $effectiveMaxHr BPM (-15 BPM), '
        'FTP obniżone: $baselineFtp -> $effectiveFtp W (-8%). '
        'Wymagane min. $recommendedRestDays dni pełnej regeneracji.';
  }
}

/// Filtry widoku panelu diagnostyki przetrenowania.
enum OvertrainingPanelFilter {
  all,
  syndromeOnly,
  warningsOnly,
  optimalOnly;

  String get labelPl {
    switch (this) {
      case OvertrainingPanelFilter.all:
        return 'Wszyscy';
      case OvertrainingPanelFilter.syndromeOnly:
        return 'Przetrenowanie (OTS)';
      case OvertrainingPanelFilter.warningsOnly:
        return 'Ostrzeżenia';
      case OvertrainingPanelFilter.optimalOnly:
        return 'Optymalni';
    }
  }
}

/// Responsywny panel diagnostyki przetrenowania i wypalenia dla Centrum Medycznego.
class OvertrainingAndBurnoutDiagnosticsPanel extends StatefulWidget {
  final TeamOvertrainingAuditSummary auditSummary;
  final ValueChanged<OvertrainingDiagnosisReport>? onApplyRecoveryProtocol;
  final bool actionsEnabled;

  const OvertrainingAndBurnoutDiagnosticsPanel({
    super.key,
    required this.auditSummary,
    this.onApplyRecoveryProtocol,
    this.actionsEnabled = true,
  });

  @override
  State<OvertrainingAndBurnoutDiagnosticsPanel> createState() =>
      _OvertrainingAndBurnoutDiagnosticsPanelState();
}

class _OvertrainingAndBurnoutDiagnosticsPanelState
    extends State<OvertrainingAndBurnoutDiagnosticsPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  OvertrainingPanelFilter _selectedFilter = OvertrainingPanelFilter.all;
  String? _hoveredReportId;
  String? _focusedReportId;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  List<OvertrainingDiagnosisReport> get _filteredReports {
    final reports = widget.auditSummary.reports;
    switch (_selectedFilter) {
      case OvertrainingPanelFilter.all:
        return reports;
      case OvertrainingPanelFilter.syndromeOnly:
        return reports
            .where((r) => r.parasympatheticSyndromeTriggered)
            .toList(growable: false);
      case OvertrainingPanelFilter.warningsOnly:
        return reports
            .where(
              (r) =>
                  r.severity == OvertrainingSeverity.functionalOverreaching ||
                  r.severity == OvertrainingSeverity.nonFunctionalOverreaching,
            )
            .toList(growable: false);
      case OvertrainingPanelFilter.optimalOnly:
        return reports
            .where((r) => r.severity == OvertrainingSeverity.optimal)
            .toList(growable: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;
          final isWide = constraints.maxWidth >= 1100;
          final reports = _filteredReports;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
            ),
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 16),
                _buildSummaryKpis(isCompact),
                const SizedBox(height: 14),
                _buildFilterBar(),
                const SizedBox(height: 16),
                if (reports.isEmpty)
                  _buildEmptyState()
                else if (isWide)
                  _buildDesktopGrid(reports)
                else
                  _buildCompactList(reports, isCompact),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.6),
            ),
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diagnostyka Przetrenowania i Wypalenia (OTS)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Progi bezpieczeństwa: TSB < -35 przez >14 dni lub >85 dni wyścigowych (-15 BPM MaxHR, -8% FTP)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryKpis(bool isCompact) {
    final summary = widget.auditSummary;
    final items = [
      _KpiItem(
        label: 'Przebadani',
        value: '${summary.totalRidersEvaluated}',
        accent: AppColors.accentBlue,
      ),
      _KpiItem(
        label: 'Zespół OTS',
        value: '${summary.affectedRidersCount}',
        accent: AppColors.crimsonAlert,
      ),
      _KpiItem(
        label: 'Ostrzeżenia',
        value: '${summary.warningRidersCount}',
        accent: AppColors.amberWarning,
      ),
      _KpiItem(
        label: 'Optymalni',
        value: '${summary.healthyRidersCount}',
        accent: AppColors.statusSuccess,
      ),
    ];

    if (isCompact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => SizedBox(
                width: 160,
                child: _buildKpiCard(item),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildKpiCard(item),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKpiCard(_KpiItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: item.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: OvertrainingPanelFilter.values.map((filter) {
        final isSelected = _selectedFilter == filter;
        return _InteractiveFilterChip(
          label: filter.labelPl,
          selected: isSelected,
          onPressed: () {
            setState(() {
              _selectedFilter = filter;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: const Center(
        child: Text(
          'Brak kolarzy spełniających wybrane kryteria diagnostyczne.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGrid(List<OvertrainingDiagnosisReport> reports) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: reports.map((report) {
        return SizedBox(
          width: 480,
          child: _buildReportCard(report, false),
        );
      }).toList(),
    );
  }

  Widget _buildCompactList(
    List<OvertrainingDiagnosisReport> reports,
    bool isCompact,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: reports
          .map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildReportCard(report, isCompact),
            ),
          )
          .toList(),
    );
  }

  Widget _buildReportCard(
    OvertrainingDiagnosisReport report,
    bool isCompact,
  ) {
    final severityColor = _colorForSeverity(report.severity);
    final isHovered = _hoveredReportId == report.riderId;
    final isFocused = _focusedReportId == report.riderId;
    final canTriggerRecovery = widget.actionsEnabled &&
        widget.onApplyRecoveryProtocol != null &&
        report.severity != OvertrainingSeverity.optimal;

    return FocusableActionDetector(
      onShowHoverHighlight: (hovered) {
        setState(() {
          _hoveredReportId = hovered ? report.riderId : null;
        });
      },
      onShowFocusHighlight: (focused) {
        setState(() {
          _focusedReportId = focused ? report.riderId : null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: isHovered ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFocused
                ? AppColors.goldAccent
                : report.parasympatheticSyndromeTriggered
                    ? AppColors.crimsonAlert.withValues(alpha: 0.75)
                    : const Color(0xFF2A2F3D),
            width: isFocused ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.riderName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: severityColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    report.severity.shortCode,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildMetricPill(
                  'TSB',
                  report.currentTsb.toStringAsFixed(1),
                  report.currentTsb < OvertrainingThresholds.unsafeTsbThreshold
                      ? AppColors.crimsonAlert
                      : AppColors.textPrimary,
                ),
                _buildMetricPill(
                  'TSB<-35',
                  '${report.consecutiveDaysBelowTsbLimit}d / 14d',
                  report.consecutiveDaysBelowTsbLimit > 14
                      ? AppColors.crimsonAlert
                      : AppColors.textSecondary,
                ),
                _buildMetricPill(
                  'Wyścigi',
                  '${report.seasonRaceDays} / 85d',
                  report.seasonRaceDays > 85
                      ? AppColors.crimsonAlert
                      : AppColors.textSecondary,
                ),
                _buildMetricPill(
                  'MaxHR',
                  '${report.effectiveMaxHrBpm} BPM',
                  report.maxHrSuppressionBpm > 0
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                ),
                _buildMetricPill(
                  'FTP',
                  '${report.effectiveFtpWatts} W',
                  report.ftpDropPercentage > 0
                      ? AppColors.crimsonAlert
                      : AppColors.statusSuccess,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.clinicalSummaryPl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _RecoveryActionButton(
                enabled: canTriggerRecovery,
                recommendedDays: report.recommendedRestDays,
                onPressed: canTriggerRecovery
                    ? () => widget.onApplyRecoveryProtocol?.call(report)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Inter', fontSize: 11),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForSeverity(OvertrainingSeverity severity) {
    switch (severity) {
      case OvertrainingSeverity.optimal:
        return AppColors.statusSuccess;
      case OvertrainingSeverity.functionalOverreaching:
        return AppColors.accentBlue;
      case OvertrainingSeverity.nonFunctionalOverreaching:
        return AppColors.amberWarning;
      case OvertrainingSeverity.parasympatheticOvertraining:
      case OvertrainingSeverity.seasonalBurnout:
        return AppColors.crimsonAlert;
    }
  }
}

class _KpiItem {
  final String label;
  final String value;
  final Color accent;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.primaryAccent
        : _pressed
            ? AppColors.surfaceLight
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : widget.selected
                      ? AppColors.goldAccent.withValues(alpha: 0.7)
                      : const Color(0xFF2A2F3D),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
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

class _RecoveryActionButton extends StatefulWidget {
  final bool enabled;
  final int recommendedDays;
  final VoidCallback? onPressed;

  const _RecoveryActionButton({
    required this.enabled,
    required this.recommendedDays,
    required this.onPressed,
  });

  @override
  State<_RecoveryActionButton> createState() => _RecoveryActionButtonState();
}

class _RecoveryActionButtonState extends State<_RecoveryActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onPressed != null;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.primaryAccent
                : AppColors.primaryAccent.withValues(alpha: 0.9);

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : enabled
                      ? AppColors.goldAccent.withValues(alpha: 0.5)
                      : const Color(0xFF2A2F3D),
            ),
          ),
          child: Text(
            enabled
                ? 'Zastosuj Regenerację (${widget.recommendedDays}d)'
                : 'Brak interwencji',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
