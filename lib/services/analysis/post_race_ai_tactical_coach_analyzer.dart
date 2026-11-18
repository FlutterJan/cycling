import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// 1. MODELE DANYCH WEJŚCIOWYCH I ENUMY TAKTYCZNE
// ============================================================================

/// Rola taktyczna kolarza w analizowanym etapie.
enum TacticalCoachRiderRole {
  gcLeader,
  sprinter,
  puncheur,
  climber,
  domestique,
  breakawaySpecialist,
}

/// Ocena ogólna wykonania planu taktycznego przez kolarza.
enum TacticalCoachGrade {
  s,
  a,
  b,
  c,
  d,
  f,
}

/// Werdykt jakościowy pojedynczego ataku z zasobów beztlenowych W'.
enum AttackTimingVerdict {
  optimal,
  wellTimed,
  risky,
  poorlyTimedHeadwind,
  emptyTankBlowup,
}

/// Kategoria rekomendacji taktycznej generowanej przez Analityka AI.
enum TacticalInsightCategory {
  windProtection,
  wPrimeTiming,
  echelonPositioning,
  pacingDiscipline,
}

/// Poziom ważności wniosku taktycznego.
enum TacticalInsightSeverity {
  critical,
  warning,
  positive,
  tip,
}

/// Filtr zakładek w panelu Analityka Taktycznego AI.
enum TacticalCoachPanelTab {
  overview,
  windLoss,
  attackTiming,
}

/// Pojedyncza próbka telemetrii po wyścigu używana przez Analityka AI.
class PostRaceTelemetrySample {
  final double timestampSeconds;
  final double distanceMeters;
  final double speedMs;
  final int powerWatts;
  final int heartRateBpm;
  final double gradientPercent;
  final double wPrimeJoules;
  final double wPrimeRatio;
  final bool isDrafting;
  final double draftingSavingsPercent;
  final double windSpeedKmh;
  final double windAngleDegrees;
  final bool isEchelonZone;
  final bool isInGutter;
  final bool isAttacking;
  final bool isPlannedPull;
  final int groupIndex;

  const PostRaceTelemetrySample({
    required this.timestampSeconds,
    required this.distanceMeters,
    required this.speedMs,
    required this.powerWatts,
    this.heartRateBpm = 145,
    this.gradientPercent = 0.0,
    required this.wPrimeJoules,
    required this.wPrimeRatio,
    required this.isDrafting,
    required this.draftingSavingsPercent,
    this.windSpeedKmh = 12.0,
    this.windAngleDegrees = 0.0,
    this.isEchelonZone = false,
    this.isInGutter = false,
    this.isAttacking = false,
    this.isPlannedPull = false,
    this.groupIndex = 1,
  });

  double get distanceKm => distanceMeters / 1000.0;
  double get speedKmh => speedMs * 3.6;

  /// Składowa wiatru czołowego (dodatnia = pod wiatr, ujemna = w plecy) [km/h].
  double get headwindComponentKmh {
    final double rad = windAngleDegrees * math.pi / 180.0;
    return windSpeedKmh * math.cos(rad);
  }

  /// Składowa wiatru bocznego [km/h].
  double get crosswindComponentKmh {
    final double rad = windAngleDegrees * math.pi / 180.0;
    return (windSpeedKmh * math.sin(rad)).abs();
  }

  Map<String, dynamic> toJson() => {
        'timestampSeconds': timestampSeconds,
        'distanceMeters': distanceMeters,
        'speedMs': speedMs,
        'powerWatts': powerWatts,
        'heartRateBpm': heartRateBpm,
        'gradientPercent': gradientPercent,
        'wPrimeJoules': wPrimeJoules,
        'wPrimeRatio': wPrimeRatio,
        'isDrafting': isDrafting,
        'draftingSavingsPercent': draftingSavingsPercent,
        'windSpeedKmh': windSpeedKmh,
        'windAngleDegrees': windAngleDegrees,
        'isEchelonZone': isEchelonZone,
        'isInGutter': isInGutter,
        'isAttacking': isAttacking,
        'isPlannedPull': isPlannedPull,
        'groupIndex': groupIndex,
      };

  factory PostRaceTelemetrySample.fromJson(Map<String, dynamic> json) {
    return PostRaceTelemetrySample(
      timestampSeconds: (json['timestampSeconds'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      speedMs: (json['speedMs'] as num?)?.toDouble() ?? 0.0,
      powerWatts: (json['powerWatts'] as num?)?.toInt() ?? 0,
      heartRateBpm: (json['heartRateBpm'] as num?)?.toInt() ?? 145,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      wPrimeJoules: (json['wPrimeJoules'] as num?)?.toDouble() ?? 0.0,
      wPrimeRatio:
          ((json['wPrimeRatio'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 1.0),
      isDrafting: json['isDrafting'] as bool? ?? true,
      draftingSavingsPercent:
          (json['draftingSavingsPercent'] as num?)?.toDouble() ?? 30.0,
      windSpeedKmh: (json['windSpeedKmh'] as num?)?.toDouble() ?? 12.0,
      windAngleDegrees: (json['windAngleDegrees'] as num?)?.toDouble() ?? 0.0,
      isEchelonZone: json['isEchelonZone'] as bool? ?? false,
      isInGutter: json['isInGutter'] as bool? ?? false,
      isAttacking: json['isAttacking'] as bool? ?? false,
      isPlannedPull: json['isPlannedPull'] as bool? ?? false,
      groupIndex: (json['groupIndex'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Profil kolarza i kontekst etapu przekazywany do Analityka Taktycznego AI.
class PostRaceCoachAnalysisInput {
  final String riderId;
  final String riderName;
  final TacticalCoachRiderRole role;
  final int ftpWatts;
  final double maxWPrimeJoules;
  final double weightKg;
  final String stageName;
  final double totalStageDistanceKm;
  final int finishPosition;
  final List<PostRaceTelemetrySample> samples;

  const PostRaceCoachAnalysisInput({
    required this.riderId,
    required this.riderName,
    required this.role,
    required this.ftpWatts,
    required this.maxWPrimeJoules,
    required this.weightKg,
    required this.stageName,
    required this.totalStageDistanceKm,
    this.finishPosition = 1,
    required this.samples,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'role': role.name,
        'ftpWatts': ftpWatts,
        'maxWPrimeJoules': maxWPrimeJoules,
        'weightKg': weightKg,
        'stageName': stageName,
        'totalStageDistanceKm': totalStageDistanceKm,
        'finishPosition': finishPosition,
        'samples': samples.map((s) => s.toJson()).toList(),
      };

  factory PostRaceCoachAnalysisInput.fromJson(Map<String, dynamic> json) {
    final String roleName =
        json['role'] as String? ?? TacticalCoachRiderRole.gcLeader.name;
    final TacticalCoachRiderRole parsedRole = TacticalCoachRiderRole.values
        .firstWhere(
          (r) => r.name == roleName,
          orElse: () => TacticalCoachRiderRole.gcLeader,
        );
    final List<dynamic> rawSamples =
        json['samples'] as List<dynamic>? ?? const [];
    return PostRaceCoachAnalysisInput(
      riderId: json['riderId'] as String? ?? 'unknown',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      role: parsedRole,
      ftpWatts: (json['ftpWatts'] as num?)?.toInt() ?? 380,
      maxWPrimeJoules:
          (json['maxWPrimeJoules'] as num?)?.toDouble() ?? 22000.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 68.0,
      stageName: json['stageName'] as String? ?? 'Etap',
      totalStageDistanceKm:
          (json['totalStageDistanceKm'] as num?)?.toDouble() ?? 160.0,
      finishPosition: (json['finishPosition'] as num?)?.toInt() ?? 1,
      samples: rawSamples
          .whereType<Map<String, dynamic>>()
          .map(PostRaceTelemetrySample.fromJson)
          .toList(),
    );
  }
}

// ============================================================================
// 2. MODELE WYNIKOWE ANALIZY AI
// ============================================================================

/// Pojedynczy odcinek nieoptymalnej ekspozycji na wiatr i straty watów.
class WindExposureSegment {
  final double startKm;
  final double endKm;
  final double durationSeconds;
  final double averageWastedWatts;
  final double wastedEnergyKj;
  final double averageCrosswindKmh;
  final double averageDraftingPercent;
  final bool occurredInEchelon;
  final bool occurredInGutter;
  final String diagnosis;

  const WindExposureSegment({
    required this.startKm,
    required this.endKm,
    required this.durationSeconds,
    required this.averageWastedWatts,
    required this.wastedEnergyKj,
    required this.averageCrosswindKmh,
    required this.averageDraftingPercent,
    required this.occurredInEchelon,
    required this.occurredInGutter,
    required this.diagnosis,
  });

  Map<String, dynamic> toJson() => {
        'startKm': startKm,
        'endKm': endKm,
        'durationSeconds': durationSeconds,
        'averageWastedWatts': averageWastedWatts,
        'wastedEnergyKj': wastedEnergyKj,
        'averageCrosswindKmh': averageCrosswindKmh,
        'averageDraftingPercent': averageDraftingPercent,
        'occurredInEchelon': occurredInEchelon,
        'occurredInGutter': occurredInGutter,
        'diagnosis': diagnosis,
      };

  factory WindExposureSegment.fromJson(Map<String, dynamic> json) {
    return WindExposureSegment(
      startKm: (json['startKm'] as num?)?.toDouble() ?? 0.0,
      endKm: (json['endKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      averageWastedWatts:
          (json['averageWastedWatts'] as num?)?.toDouble() ?? 0.0,
      wastedEnergyKj: (json['wastedEnergyKj'] as num?)?.toDouble() ?? 0.0,
      averageCrosswindKmh:
          (json['averageCrosswindKmh'] as num?)?.toDouble() ?? 0.0,
      averageDraftingPercent:
          (json['averageDraftingPercent'] as num?)?.toDouble() ?? 0.0,
      occurredInEchelon: json['occurredInEchelon'] as bool? ?? false,
      occurredInGutter: json['occurredInGutter'] as bool? ?? false,
      diagnosis: json['diagnosis'] as String? ?? '',
    );
  }
}

/// Zbiorcze podsumowanie strat aerodynamicznych na wietrze.
class WindAeroEfficiencySummary {
  final double totalWastedEnergyKj;
  final double averageWastedWattsWhenExposed;
  final double exposedDurationSeconds;
  final double shelteredPercentOfStage;
  final double equivalentFtpMinutesWasted;
  final int gutterExposureCount;
  final List<WindExposureSegment> topMistakeSegments;

  const WindAeroEfficiencySummary({
    required this.totalWastedEnergyKj,
    required this.averageWastedWattsWhenExposed,
    required this.exposedDurationSeconds,
    required this.shelteredPercentOfStage,
    required this.equivalentFtpMinutesWasted,
    required this.gutterExposureCount,
    required this.topMistakeSegments,
  });

  Map<String, dynamic> toJson() => {
        'totalWastedEnergyKj': totalWastedEnergyKj,
        'averageWastedWattsWhenExposed': averageWastedWattsWhenExposed,
        'exposedDurationSeconds': exposedDurationSeconds,
        'shelteredPercentOfStage': shelteredPercentOfStage,
        'equivalentFtpMinutesWasted': equivalentFtpMinutesWasted,
        'gutterExposureCount': gutterExposureCount,
        'topMistakeSegments':
            topMistakeSegments.map((s) => s.toJson()).toList(),
      };

  factory WindAeroEfficiencySummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> segs =
        json['topMistakeSegments'] as List<dynamic>? ?? const [];
    return WindAeroEfficiencySummary(
      totalWastedEnergyKj:
          (json['totalWastedEnergyKj'] as num?)?.toDouble() ?? 0.0,
      averageWastedWattsWhenExposed:
          (json['averageWastedWattsWhenExposed'] as num?)?.toDouble() ?? 0.0,
      exposedDurationSeconds:
          (json['exposedDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      shelteredPercentOfStage:
          (json['shelteredPercentOfStage'] as num?)?.toDouble() ?? 100.0,
      equivalentFtpMinutesWasted:
          (json['equivalentFtpMinutesWasted'] as num?)?.toDouble() ?? 0.0,
      gutterExposureCount: (json['gutterExposureCount'] as num?)?.toInt() ?? 0,
      topMistakeSegments: segs
          .whereType<Map<String, dynamic>>()
          .map(WindExposureSegment.fromJson)
          .toList(),
    );
  }
}

/// Ocena pojedynczego ataku z wykorzystaniem zasobu W'.
class AttackTimingEvaluation {
  final int attackIndex;
  final double startKm;
  final double endKm;
  final double distanceToFinishKm;
  final double durationSeconds;
  final int peakWatts;
  final int averageWatts;
  final double preAttackWPrimeRatio;
  final double minWPrimeRatioDuringAttack;
  final double averageGradientPercent;
  final double headwindComponentKmh;
  final bool causedWPrimeBlowup;
  final double timingScore;
  final AttackTimingVerdict verdict;
  final String coachingNote;

  const AttackTimingEvaluation({
    required this.attackIndex,
    required this.startKm,
    required this.endKm,
    required this.distanceToFinishKm,
    required this.durationSeconds,
    required this.peakWatts,
    required this.averageWatts,
    required this.preAttackWPrimeRatio,
    required this.minWPrimeRatioDuringAttack,
    required this.averageGradientPercent,
    required this.headwindComponentKmh,
    required this.causedWPrimeBlowup,
    required this.timingScore,
    required this.verdict,
    required this.coachingNote,
  });

  Map<String, dynamic> toJson() => {
        'attackIndex': attackIndex,
        'startKm': startKm,
        'endKm': endKm,
        'distanceToFinishKm': distanceToFinishKm,
        'durationSeconds': durationSeconds,
        'peakWatts': peakWatts,
        'averageWatts': averageWatts,
        'preAttackWPrimeRatio': preAttackWPrimeRatio,
        'minWPrimeRatioDuringAttack': minWPrimeRatioDuringAttack,
        'averageGradientPercent': averageGradientPercent,
        'headwindComponentKmh': headwindComponentKmh,
        'causedWPrimeBlowup': causedWPrimeBlowup,
        'timingScore': timingScore,
        'verdict': verdict.name,
        'coachingNote': coachingNote,
      };

  factory AttackTimingEvaluation.fromJson(Map<String, dynamic> json) {
    final String verdictName =
        json['verdict'] as String? ?? AttackTimingVerdict.risky.name;
    final AttackTimingVerdict parsedVerdict = AttackTimingVerdict.values
        .firstWhere(
          (v) => v.name == verdictName,
          orElse: () => AttackTimingVerdict.risky,
        );
    return AttackTimingEvaluation(
      attackIndex: (json['attackIndex'] as num?)?.toInt() ?? 1,
      startKm: (json['startKm'] as num?)?.toDouble() ?? 0.0,
      endKm: (json['endKm'] as num?)?.toDouble() ?? 0.0,
      distanceToFinishKm:
          (json['distanceToFinishKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
      peakWatts: (json['peakWatts'] as num?)?.toInt() ?? 0,
      averageWatts: (json['averageWatts'] as num?)?.toInt() ?? 0,
      preAttackWPrimeRatio:
          (json['preAttackWPrimeRatio'] as num?)?.toDouble() ?? 0.0,
      minWPrimeRatioDuringAttack:
          (json['minWPrimeRatioDuringAttack'] as num?)?.toDouble() ?? 0.0,
      averageGradientPercent:
          (json['averageGradientPercent'] as num?)?.toDouble() ?? 0.0,
      headwindComponentKmh:
          (json['headwindComponentKmh'] as num?)?.toDouble() ?? 0.0,
      causedWPrimeBlowup: json['causedWPrimeBlowup'] as bool? ?? false,
      timingScore: (json['timingScore'] as num?)?.toDouble() ?? 50.0,
      verdict: parsedVerdict,
      coachingNote: json['coachingNote'] as String? ?? '',
    );
  }
}

/// Zbiorcze podsumowanie zarządzania energią beztlenową W' podczas ataków.
class WPrimeAttackTimingSummary {
  final int totalAttacks;
  final int optimalAttacks;
  final int poorlyTimedAttacks;
  final int blowupCount;
  final double averagePreAttackWPrimePercent;
  final double averageTimingScore;
  final List<AttackTimingEvaluation> attacks;

  const WPrimeAttackTimingSummary({
    required this.totalAttacks,
    required this.optimalAttacks,
    required this.poorlyTimedAttacks,
    required this.blowupCount,
    required this.averagePreAttackWPrimePercent,
    required this.averageTimingScore,
    required this.attacks,
  });

  Map<String, dynamic> toJson() => {
        'totalAttacks': totalAttacks,
        'optimalAttacks': optimalAttacks,
        'poorlyTimedAttacks': poorlyTimedAttacks,
        'blowupCount': blowupCount,
        'averagePreAttackWPrimePercent': averagePreAttackWPrimePercent,
        'averageTimingScore': averageTimingScore,
        'attacks': attacks.map((a) => a.toJson()).toList(),
      };

  factory WPrimeAttackTimingSummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawAttacks =
        json['attacks'] as List<dynamic>? ?? const [];
    return WPrimeAttackTimingSummary(
      totalAttacks: (json['totalAttacks'] as num?)?.toInt() ?? 0,
      optimalAttacks: (json['optimalAttacks'] as num?)?.toInt() ?? 0,
      poorlyTimedAttacks: (json['poorlyTimedAttacks'] as num?)?.toInt() ?? 0,
      blowupCount: (json['blowupCount'] as num?)?.toInt() ?? 0,
      averagePreAttackWPrimePercent:
          (json['averagePreAttackWPrimePercent'] as num?)?.toDouble() ?? 0.0,
      averageTimingScore:
          (json['averageTimingScore'] as num?)?.toDouble() ?? 100.0,
      attacks: rawAttacks
          .whereType<Map<String, dynamic>>()
          .map(AttackTimingEvaluation.fromJson)
          .toList(),
    );
  }
}

/// Konkretna wskazówka taktyczna wygenerowana przez Analityka AI.
class TacticalCoachingInsight {
  final String id;
  final TacticalInsightCategory category;
  final TacticalInsightSeverity severity;
  final String title;
  final String description;
  final String impactMetricLabel;
  final String nextStageAction;

  const TacticalCoachingInsight({
    required this.id,
    required this.category,
    required this.severity,
    required this.title,
    required this.description,
    required this.impactMetricLabel,
    required this.nextStageAction,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'severity': severity.name,
        'title': title,
        'description': description,
        'impactMetricLabel': impactMetricLabel,
        'nextStageAction': nextStageAction,
      };

  factory TacticalCoachingInsight.fromJson(Map<String, dynamic> json) {
    final String catName = json['category'] as String? ??
        TacticalInsightCategory.windProtection.name;
    final String sevName =
        json['severity'] as String? ?? TacticalInsightSeverity.tip.name;
    return TacticalCoachingInsight(
      id: json['id'] as String? ?? 'insight',
      category: TacticalInsightCategory.values.firstWhere(
        (c) => c.name == catName,
        orElse: () => TacticalInsightCategory.windProtection,
      ),
      severity: TacticalInsightSeverity.values.firstWhere(
        (s) => s.name == sevName,
        orElse: () => TacticalInsightSeverity.tip,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      impactMetricLabel: json['impactMetricLabel'] as String? ?? '',
      nextStageAction: json['nextStageAction'] as String? ?? '',
    );
  }
}

/// Pełny raport Analityka Taktycznego AI po wyścigu.
class PostRaceTacticalCoachReport {
  final String riderId;
  final String riderName;
  final String stageName;
  final TacticalCoachRiderRole role;
  final double overallTacticalScore;
  final TacticalCoachGrade grade;
  final String executiveVerdict;
  final WindAeroEfficiencySummary windSummary;
  final WPrimeAttackTimingSummary attackSummary;
  final List<TacticalCoachingInsight> insights;

  const PostRaceTacticalCoachReport({
    required this.riderId,
    required this.riderName,
    required this.stageName,
    required this.role,
    required this.overallTacticalScore,
    required this.grade,
    required this.executiveVerdict,
    required this.windSummary,
    required this.attackSummary,
    required this.insights,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'stageName': stageName,
        'role': role.name,
        'overallTacticalScore': overallTacticalScore,
        'grade': grade.name,
        'executiveVerdict': executiveVerdict,
        'windSummary': windSummary.toJson(),
        'attackSummary': attackSummary.toJson(),
        'insights': insights.map((i) => i.toJson()).toList(),
      };

  factory PostRaceTacticalCoachReport.fromJson(Map<String, dynamic> json) {
    final String roleName =
        json['role'] as String? ?? TacticalCoachRiderRole.gcLeader.name;
    final String gradeName =
        json['grade'] as String? ?? TacticalCoachGrade.b.name;
    final List<dynamic> rawInsights =
        json['insights'] as List<dynamic>? ?? const [];
    return PostRaceTacticalCoachReport(
      riderId: json['riderId'] as String? ?? 'unknown',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      stageName: json['stageName'] as String? ?? 'Etap',
      role: TacticalCoachRiderRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => TacticalCoachRiderRole.gcLeader,
      ),
      overallTacticalScore:
          (json['overallTacticalScore'] as num?)?.toDouble() ?? 75.0,
      grade: TacticalCoachGrade.values.firstWhere(
        (g) => g.name == gradeName,
        orElse: () => TacticalCoachGrade.b,
      ),
      executiveVerdict: json['executiveVerdict'] as String? ?? '',
      windSummary: WindAeroEfficiencySummary.fromJson(
        json['windSummary'] as Map<String, dynamic>? ?? const {},
      ),
      attackSummary: WPrimeAttackTimingSummary.fromJson(
        json['attackSummary'] as Map<String, dynamic>? ?? const {},
      ),
      insights: rawInsights
          .whereType<Map<String, dynamic>>()
          .map(TacticalCoachingInsight.fromJson)
          .toList(),
    );
  }
}

// ============================================================================
// 3. SILNIK ANALITYKA TAKTYCZNEGO AI PO WYŚCIGU
// ============================================================================

/// Analityk Taktyczny AI po Wyścigu analizujący stracone waty na wietrze
/// oraz timing ataków z zasobów beztlenowych W'.
class PostRaceAiTacticalCoachAnalyzer {
  const PostRaceAiTacticalCoachAnalyzer();

  /// Analizuje telemetrię pojedynczego kolarza po zakończeniu etapu.
  PostRaceTacticalCoachReport analyzeStage(PostRaceCoachAnalysisInput input) {
    final List<PostRaceTelemetrySample> sorted = List.of(input.samples)
      ..sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));

    if (sorted.isEmpty) {
      return _buildEmptyTelemetryReport(input);
    }

    final int safeFtp = math.max(150, input.ftpWatts);
    final double safeMaxWPrime = math.max(5000.0, input.maxWPrimeJoules);
    final double stageKm = math.max(
      input.totalStageDistanceKm,
      sorted.last.distanceKm,
    );

    final WindAeroEfficiencySummary windSummary = _analyzeWindLosses(
      samples: sorted,
      ftpWatts: safeFtp,
      role: input.role,
    );

    final WPrimeAttackTimingSummary attackSummary = _analyzeWPrimeAttacks(
      samples: sorted,
      ftpWatts: safeFtp,
      maxWPrimeJoules: safeMaxWPrime,
      totalStageKm: stageKm,
    );

    final double overallScore = _computeOverallScore(
      windSummary: windSummary,
      attackSummary: attackSummary,
      role: input.role,
    );

    final TacticalCoachGrade grade = _scoreToGrade(overallScore);

    final List<TacticalCoachingInsight> insights = _generateInsights(
      input: input,
      windSummary: windSummary,
      attackSummary: attackSummary,
      overallScore: overallScore,
    );

    final String verdict = _buildExecutiveVerdict(
      riderName: input.riderName,
      grade: grade,
      windSummary: windSummary,
      attackSummary: attackSummary,
    );

    return PostRaceTacticalCoachReport(
      riderId: input.riderId,
      riderName: input.riderName,
      stageName: input.stageName,
      role: input.role,
      overallTacticalScore: overallScore,
      grade: grade,
      executiveVerdict: verdict,
      windSummary: windSummary,
      attackSummary: attackSummary,
      insights: insights,
    );
  }

  /// Analizuje całą drużynę i sortuje raporty od najniższej oceny (priorytet coachingu).
  List<PostRaceTacticalCoachReport> analyzeTeam(
    List<PostRaceCoachAnalysisInput> inputs,
  ) {
    final List<PostRaceTacticalCoachReport> reports =
        inputs.map(analyzeStage).toList();
    reports.sort(
      (a, b) => a.overallTacticalScore.compareTo(b.overallTacticalScore),
    );
    return reports;
  }

  WindAeroEfficiencySummary _analyzeWindLosses({
    required List<PostRaceTelemetrySample> samples,
    required int ftpWatts,
    required TacticalCoachRiderRole role,
  }) {
    final double targetDraftPercent = _targetDraftThreshold(role);
    double totalDuration = 0.0;
    double shelteredDuration = 0.0;
    double exposedDuration = 0.0;
    double totalWastedJoules = 0.0;
    int gutterCount = 0;

    final List<WindExposureSegment> mistakeSegments = [];

    bool inSegment = false;
    double segStartKm = 0.0;
    double segEndKm = 0.0;
    double segDuration = 0.0;
    double segWastedJoules = 0.0;
    double segCrosswindSum = 0.0;
    double segDraftSum = 0.0;
    int segSampleCount = 0;
    bool segEchelon = false;
    bool segGutter = false;

    void finalizeSegment() {
      if (!inSegment || segDuration < 4.0 || segSampleCount == 0) {
        inSegment = false;
        return;
      }
      final double avgWastedW = segWastedJoules / segDuration;
      final double wastedKj = segWastedJoules / 1000.0;
      if (wastedKj >= 0.4) {
        final double avgCross = segCrosswindSum / segSampleCount;
        final double avgDraft = segDraftSum / segSampleCount;
        mistakeSegments.add(
          WindExposureSegment(
            startKm: segStartKm,
            endKm: math.max(segStartKm, segEndKm),
            durationSeconds: segDuration,
            averageWastedWatts: avgWastedW,
            wastedEnergyKj: wastedKj,
            averageCrosswindKmh: avgCross,
            averageDraftingPercent: avgDraft,
            occurredInEchelon: segEchelon,
            occurredInGutter: segGutter,
            diagnosis: _buildWindSegmentDiagnosis(
              occurredInGutter: segGutter,
              occurredInEchelon: segEchelon,
              avgCrosswindKmh: avgCross,
              avgDraftPercent: avgDraft,
              wastedKj: wastedKj,
            ),
          ),
        );
      }
      inSegment = false;
    }

    for (int i = 0; i < samples.length; i++) {
      final PostRaceTelemetrySample s = samples[i];
      final double dt = _sampleDt(samples, i);
      totalDuration += dt;

      // Na stromych podjazdach (>= 5.5%) opór aero ma mniejsze znaczenie niż grawitacja.
      final bool isAeroRelevant = s.speedKmh >= 24.0 && s.gradientPercent < 5.5;
      final bool isIntentionalEffort = s.isAttacking || s.isPlannedPull;
      final double effectiveTargetDraft =
          s.isEchelonZone ? math.min(targetDraftPercent, 22.0) : targetDraftPercent;

      final bool isUnnecessarilyExposed = isAeroRelevant &&
          !isIntentionalEffort &&
          (!s.isDrafting ||
              s.draftingSavingsPercent < effectiveTargetDraft ||
              s.isInGutter);

      if (!isUnnecessarilyExposed) {
        shelteredDuration += dt;
        finalizeSegment();
        continue;
      }

      final double draftDeficitFraction = ((effectiveTargetDraft -
                  (s.isDrafting ? s.draftingSavingsPercent : 0.0)) /
              100.0)
          .clamp(0.05, 0.45);
      final double windMultiplier =
          1.0 + (s.crosswindComponentKmh / 45.0) + (s.isInGutter ? 0.25 : 0.0);
      final double wastedWatts =
          (s.powerWatts * draftDeficitFraction * windMultiplier)
              .clamp(8.0, 220.0);
      final double stepJoules = wastedWatts * dt;

      exposedDuration += dt;
      totalWastedJoules += stepJoules;
      if (s.isInGutter) {
        gutterCount++;
      }

      if (!inSegment) {
        inSegment = true;
        segStartKm = s.distanceKm;
        segEndKm = s.distanceKm;
        segDuration = dt;
        segWastedJoules = stepJoules;
        segCrosswindSum = s.crosswindComponentKmh;
        segDraftSum = s.isDrafting ? s.draftingSavingsPercent : 0.0;
        segSampleCount = 1;
        segEchelon = s.isEchelonZone;
        segGutter = s.isInGutter;
      } else {
        segEndKm = s.distanceKm;
        segDuration += dt;
        segWastedJoules += stepJoules;
        segCrosswindSum += s.crosswindComponentKmh;
        segDraftSum += s.isDrafting ? s.draftingSavingsPercent : 0.0;
        segSampleCount++;
        segEchelon = segEchelon || s.isEchelonZone;
        segGutter = segGutter || s.isInGutter;
      }
    }
    finalizeSegment();

    mistakeSegments.sort((a, b) => b.wastedEnergyKj.compareTo(a.wastedEnergyKj));

    final double totalWastedKj = totalWastedJoules / 1000.0;
    final double avgWastedWatts =
        exposedDuration > 0.0 ? totalWastedJoules / exposedDuration : 0.0;
    final double shelteredPct = totalDuration > 0.0
        ? ((shelteredDuration / totalDuration) * 100.0).clamp(0.0, 100.0)
        : 100.0;
    final double equivFtpMinutes =
        ftpWatts > 0 ? (totalWastedJoules / (ftpWatts * 60.0)) : 0.0;

    return WindAeroEfficiencySummary(
      totalWastedEnergyKj: totalWastedKj,
      averageWastedWattsWhenExposed: avgWastedWatts,
      exposedDurationSeconds: exposedDuration,
      shelteredPercentOfStage: shelteredPct,
      equivalentFtpMinutesWasted: equivFtpMinutes,
      gutterExposureCount: gutterCount,
      topMistakeSegments: mistakeSegments.take(4).toList(),
    );
  }

  WPrimeAttackTimingSummary _analyzeWPrimeAttacks({
    required List<PostRaceTelemetrySample> samples,
    required int ftpWatts,
    required double maxWPrimeJoules,
    required double totalStageKm,
  }) {
    final List<AttackTimingEvaluation> attacks = [];
    final int surgeThresholdWatts = (ftpWatts * 1.22).round();

    bool inAttack = false;
    int startIdx = 0;
    double preAttackWPrimeRatio = 1.0;

    void closeAttack(int endIdx) {
      if (!inAttack || endIdx < startIdx) {
        inAttack = false;
        return;
      }
      double duration = 0.0;
      int peakWatts = 0;
      double powerSum = 0.0;
      double gradSum = 0.0;
      double headwindSum = 0.0;
      double minWPrimeRatio = 1.0;
      int count = 0;

      for (int k = startIdx; k <= endIdx; k++) {
        final PostRaceTelemetrySample p = samples[k];
        final double dt = _sampleDt(samples, k);
        duration += dt;
        if (p.powerWatts > peakWatts) peakWatts = p.powerWatts;
        powerSum += p.powerWatts;
        gradSum += p.gradientPercent;
        headwindSum += p.headwindComponentKmh;
        if (p.wPrimeRatio < minWPrimeRatio) {
          minWPrimeRatio = p.wPrimeRatio;
        }
        count++;
      }

      inAttack = false;
      if (duration < 4.0 || count == 0) return;

      final double startKm = samples[startIdx].distanceKm;
      final double endKm = samples[endIdx].distanceKm;
      final double distToFinish = math.max(0.0, totalStageKm - startKm);
      final int avgWatts = (powerSum / count).round();
      final double avgGrad = gradSum / count;
      final double avgHeadwind = headwindSum / count;

      // Sprawdź, czy po ataku nastąpiło odcięcie (W' <= 4% i spadek mocy < 72% FTP).
      bool bonkedAfter = minWPrimeRatio <= 0.04;
      if (!bonkedAfter && endIdx + 1 < samples.length) {
        final int lookaheadEnd = math.min(samples.length - 1, endIdx + 4);
        for (int k = endIdx + 1; k <= lookaheadEnd; k++) {
          if (samples[k].wPrimeRatio <= 0.05 &&
              samples[k].powerWatts < (ftpWatts * 0.72)) {
            bonkedAfter = true;
            break;
          }
        }
      }

      final _AttackEvaluationScore eval = _evaluateSingleAttack(
        preWPrimeRatio: preAttackWPrimeRatio,
        minWPrimeRatio: minWPrimeRatio,
        avgGrad: avgGrad,
        avgHeadwindKmh: avgHeadwind,
        distToFinishKm: distToFinish,
        bonkedAfter: bonkedAfter,
      );

      attacks.add(
        AttackTimingEvaluation(
          attackIndex: attacks.length + 1,
          startKm: startKm,
          endKm: math.max(startKm, endKm),
          distanceToFinishKm: distToFinish,
          durationSeconds: duration,
          peakWatts: peakWatts,
          averageWatts: avgWatts,
          preAttackWPrimeRatio: preAttackWPrimeRatio,
          minWPrimeRatioDuringAttack: minWPrimeRatio,
          averageGradientPercent: avgGrad,
          headwindComponentKmh: avgHeadwind,
          causedWPrimeBlowup: bonkedAfter,
          timingScore: eval.score,
          verdict: eval.verdict,
          coachingNote: eval.note,
        ),
      );
    }

    for (int i = 0; i < samples.length; i++) {
      final PostRaceTelemetrySample s = samples[i];
      final bool isSurge =
          s.isAttacking || (s.powerWatts >= surgeThresholdWatts && !s.isDrafting);

      if (isSurge && !inAttack) {
        inAttack = true;
        startIdx = i;
        preAttackWPrimeRatio = i > 0
            ? samples[i - 1].wPrimeRatio
            : (s.wPrimeRatio > 0 ? s.wPrimeRatio : (s.wPrimeJoules / maxWPrimeJoules).clamp(0.0, 1.0));
      } else if (!isSurge && inAttack) {
        closeAttack(i - 1);
      }
    }
    if (inAttack) {
      closeAttack(samples.length - 1);
    }

    if (attacks.isEmpty) {
      return const WPrimeAttackTimingSummary(
        totalAttacks: 0,
        optimalAttacks: 0,
        poorlyTimedAttacks: 0,
        blowupCount: 0,
        averagePreAttackWPrimePercent: 0.0,
        averageTimingScore: 88.0,
        attacks: [],
      );
    }

    int optimalCount = 0;
    int poorCount = 0;
    int blowupCount = 0;
    double preSum = 0.0;
    double scoreSum = 0.0;

    for (final AttackTimingEvaluation a in attacks) {
      if (a.verdict == AttackTimingVerdict.optimal ||
          a.verdict == AttackTimingVerdict.wellTimed) {
        optimalCount++;
      } else if (a.verdict == AttackTimingVerdict.poorlyTimedHeadwind ||
          a.verdict == AttackTimingVerdict.emptyTankBlowup) {
        poorCount++;
      }
      if (a.causedWPrimeBlowup) blowupCount++;
      preSum += a.preAttackWPrimeRatio * 100.0;
      scoreSum += a.timingScore;
    }

    return WPrimeAttackTimingSummary(
      totalAttacks: attacks.length,
      optimalAttacks: optimalCount,
      poorlyTimedAttacks: poorCount,
      blowupCount: blowupCount,
      averagePreAttackWPrimePercent: preSum / attacks.length,
      averageTimingScore: scoreSum / attacks.length,
      attacks: attacks,
    );
  }

  _AttackEvaluationScore _evaluateSingleAttack({
    required double preWPrimeRatio,
    required double minWPrimeRatio,
    required double avgGrad,
    required double avgHeadwindKmh,
    required double distToFinishKm,
    required bool bonkedAfter,
  }) {
    double score = 78.0;

    // 1. Poziom naładowania W' przed atakiem
    if (preWPrimeRatio >= 0.78) {
      score += 14.0;
    } else if (preWPrimeRatio >= 0.55) {
      score += 4.0;
    } else if (preWPrimeRatio < 0.35) {
      score -= 32.0;
    } else {
      score -= 14.0;
    }

    // 2. Wiatr czołowy vs podjazd
    final bool isHeadwindFlat = avgGrad < 2.0 && avgHeadwindKmh >= 15.0;
    if (avgGrad >= 5.5) {
      score += 10.0;
    } else if (isHeadwindFlat) {
      score -= 26.0;
    }

    // 3. Dystans do mety
    if (distToFinishKm <= 25.0) {
      score += 6.0;
    } else if (distToFinishKm > 85.0) {
      score -= 10.0;
    }

    // 4. Odcięcie beztlenowe po ataku
    if (bonkedAfter) {
      score -= 28.0;
    } else if (minWPrimeRatio >= 0.15) {
      score += 4.0;
    }

    final double clamped = score.clamp(5.0, 100.0);

    if (bonkedAfter && preWPrimeRatio < 0.45) {
      return _AttackEvaluationScore(
        score: clamped,
        verdict: AttackTimingVerdict.emptyTankBlowup,
        note:
            'Atak odpalony przy zbyt niskim W\' (${(preWPrimeRatio * 100).round()}%) — całkowite odcięcie beztlenowe.',
      );
    }
    if (isHeadwindFlat) {
      return _AttackEvaluationScore(
        score: clamped,
        verdict: AttackTimingVerdict.poorlyTimedHeadwind,
        note:
            'Atak na płaskim pod wiatr (${avgHeadwindKmh.toStringAsFixed(0)} km/h) spalił W\' bez stworzenia selekcji.',
      );
    }
    if (bonkedAfter) {
      return _AttackEvaluationScore(
        score: clamped,
        verdict: AttackTimingVerdict.emptyTankBlowup,
        note:
            'Zbyt długie przetrzymanie ponad CP wyzerowało baterię W\' i zablokowało końcówkę.',
      );
    }
    if (clamped >= 86.0) {
      return _AttackEvaluationScore(
        score: clamped,
        verdict: AttackTimingVerdict.optimal,
        note:
            'Wzór timingu: pełne W\' (${(preWPrimeRatio * 100).round()}%) i wysoka selekcja na nachyleniu ${avgGrad.toStringAsFixed(1)}%.',
      );
    }
    if (clamped >= 68.0) {
      return _AttackEvaluationScore(
        score: clamped,
        verdict: AttackTimingVerdict.wellTimed,
        note:
            'Dobry moment przyspieszenia z bezpiecznym marginesem regeneracji W\'.',
      );
    }
    return _AttackEvaluationScore(
      score: clamped,
      verdict: AttackTimingVerdict.risky,
      note:
          'Ryzykowny skok przy częściowo rozładowanym W\' (${(preWPrimeRatio * 100).round()}%).',
    );
  }

  double _computeOverallScore({
    required WindAeroEfficiencySummary windSummary,
    required WPrimeAttackTimingSummary attackSummary,
    required TacticalCoachRiderRole role,
  }) {
    // Kara za marnowanie watów na wietrze (szczególnie surowa dla liderów GC i sprinterów)
    final double roleWindSensitivity = switch (role) {
      TacticalCoachRiderRole.gcLeader => 1.25,
      TacticalCoachRiderRole.sprinter => 1.30,
      TacticalCoachRiderRole.climber => 1.15,
      TacticalCoachRiderRole.puncheur => 1.05,
      TacticalCoachRiderRole.breakawaySpecialist => 0.70,
      TacticalCoachRiderRole.domestique => 0.75,
    };

    final double windPenalty =
        (windSummary.totalWastedEnergyKj * 0.42 * roleWindSensitivity) +
            (windSummary.gutterExposureCount * 1.5);
    final double windScore = (100.0 - windPenalty).clamp(15.0, 100.0);

    final double combined = attackSummary.totalAttacks == 0
        ? (windScore * 0.75 + attackSummary.averageTimingScore * 0.25)
        : (windScore * 0.48 + attackSummary.averageTimingScore * 0.52);

    return combined.clamp(0.0, 100.0);
  }

  TacticalCoachGrade _scoreToGrade(double score) {
    if (score >= 92.0) return TacticalCoachGrade.s;
    if (score >= 82.0) return TacticalCoachGrade.a;
    if (score >= 70.0) return TacticalCoachGrade.b;
    if (score >= 56.0) return TacticalCoachGrade.c;
    if (score >= 42.0) return TacticalCoachGrade.d;
    return TacticalCoachGrade.f;
  }

  List<TacticalCoachingInsight> _generateInsights({
    required PostRaceCoachAnalysisInput input,
    required WindAeroEfficiencySummary windSummary,
    required WPrimeAttackTimingSummary attackSummary,
    required double overallScore,
  }) {
    final List<TacticalCoachingInsight> list = [];

    if (windSummary.totalWastedEnergyKj >= 25.0) {
      list.add(
        TacticalCoachingInsight(
          id: 'wind_heavy_loss',
          category: TacticalInsightCategory.windProtection,
          severity: TacticalInsightSeverity.critical,
          title: 'Wysokie straty energii na wietrze',
          description:
              '${input.riderName} stracił ${windSummary.totalWastedEnergyKj.toStringAsFixed(1)} kJ '
              '(${windSummary.equivalentFtpMinutesWasted.toStringAsFixed(1)} min pracy na FTP) '
              'przez jazdę poza cieniem aerodynamicznym.',
          impactMetricLabel:
              '-${windSummary.totalWastedEnergyKj.toStringAsFixed(1)} kJ',
          nextStageAction:
              'Utrzymuj pozycję w top 25 peletonu i przypisz pomocnika do ochrony przed wiatrem.',
        ),
      );
    } else if (windSummary.totalWastedEnergyKj >= 10.0) {
      list.add(
        TacticalCoachingInsight(
          id: 'wind_moderate_loss',
          category: TacticalInsightCategory.windProtection,
          severity: TacticalInsightSeverity.warning,
          title: 'Umiarkowana ekspozycja wiatrowa',
          description:
              'Kolarz spędził ${(windSummary.exposedDurationSeconds / 60.0).toStringAsFixed(1)} min '
              'na wietrze przy średniej stracie ${windSummary.averageWastedWattsWhenExposed.toStringAsFixed(0)} W.',
          impactMetricLabel:
              '-${windSummary.averageWastedWattsWhenExposed.toStringAsFixed(0)} W śr.',
          nextStageAction:
              'Skróć czas powrotu na koło po zjazdach i strefach bufetu.',
        ),
      );
    } else {
      list.add(
        TacticalCoachingInsight(
          id: 'wind_optimal_shelter',
          category: TacticalInsightCategory.windProtection,
          severity: TacticalInsightSeverity.positive,
          title: 'Wzorowe krycie w peletonie',
          description:
              'Aż ${windSummary.shelteredPercentOfStage.toStringAsFixed(1)}% etapu przejechane w cieniu aerodynamicznym.',
          impactMetricLabel:
              '${windSummary.shelteredPercentOfStage.toStringAsFixed(0)}% w cieniu',
          nextStageAction:
              'Utrzymaj ten sam schemat ustawienia przed finałowym podjazdem.',
        ),
      );
    }

    if (windSummary.gutterExposureCount > 0) {
      list.add(
        TacticalCoachingInsight(
          id: 'echelon_gutter_alert',
          category: TacticalInsightCategory.echelonPositioning,
          severity: TacticalInsightSeverity.critical,
          title: 'Zepchnięcie pod krawężnik (Gutter)',
          description:
              'Wykryto ${windSummary.gutterExposureCount} próbek jazdy na skraju rantu bez ochrony bocznej.',
          impactMetricLabel: '${windSummary.gutterExposureCount}x w rancie',
          nextStageAction:
              'Włącz rozkaz wysokiej czujności na 5 km przed strefami wiatru bocznego.',
        ),
      );
    }

    if (attackSummary.blowupCount > 0) {
      list.add(
        TacticalCoachingInsight(
          id: 'w_prime_blowup',
          category: TacticalInsightCategory.wPrimeTiming,
          severity: TacticalInsightSeverity.critical,
          title: 'Wyzerowanie baterii beztlenowej W\'',
          description:
              'Odnotowano ${attackSummary.blowupCount} odcięcia po atakach (średni zapas przed skokiem: '
              '${attackSummary.averagePreAttackWPrimePercent.toStringAsFixed(0)}%).',
          impactMetricLabel: '${attackSummary.blowupCount}x odcięcie W\'',
          nextStageAction:
              'Inicjuj ataki dopiero przy W\' >= 75% i kończ skok przed spadkiem poniżej 15%.',
        ),
      );
    } else if (attackSummary.optimalAttacks > 0) {
      list.add(
        TacticalCoachingInsight(
          id: 'w_prime_optimal_timing',
          category: TacticalInsightCategory.wPrimeTiming,
          severity: TacticalInsightSeverity.positive,
          title: 'Precyzyjny timing ataków z W\'',
          description:
              '${attackSummary.optimalAttacks} z ${attackSummary.totalAttacks} ataków wykonano przy wysokim W\' '
              '(${attackSummary.averagePreAttackWPrimePercent.toStringAsFixed(0)}%) i w optymalnym terenie.',
          impactMetricLabel:
              '${attackSummary.averageTimingScore.toStringAsFixed(0)}/100 pkt',
          nextStageAction:
              'Kontynuuj cierpliwe czekanie na nachylenie >6% przed odpaleniem ataku.',
        ),
      );
    } else if (attackSummary.totalAttacks == 0 && overallScore >= 70.0) {
      list.add(
        const TacticalCoachingInsight(
          id: 'pacing_disciplined',
          category: TacticalInsightCategory.pacingDiscipline,
          severity: TacticalInsightSeverity.tip,
          title: 'Zdyscyplinowana jazda ekonomiczna',
          description:
              'Brak niepotrzebnych zrywów beztlenowych pozwolił zachować pełną rezerwę W\' na finisz.',
          impactMetricLabel: '0 zbędnych skoków',
          nextStageAction:
              'Wykorzystaj zaoszczędzone W\' na mocniejszy finisz lub kontratak w górach.',
        ),
      );
    }

    return list;
  }

  String _buildExecutiveVerdict({
    required String riderName,
    required TacticalCoachGrade grade,
    required WindAeroEfficiencySummary windSummary,
    required WPrimeAttackTimingSummary attackSummary,
  }) {
    return switch (grade) {
      TacticalCoachGrade.s =>
        '$riderName pojechał wzorowy taktycznie etap: minimalne straty na wietrze (${windSummary.totalWastedEnergyKj.toStringAsFixed(1)} kJ) i bezbłędne zarządzanie W\'.',
      TacticalCoachGrade.a =>
        'Bardzo dobra dyscyplina taktyczna ($riderName). Niewielkie rezerwy do poprawy w ustawieniu przed wiatrem.',
      TacticalCoachGrade.b =>
        'Solidny przejazd, choć stracono ${windSummary.totalWastedEnergyKj.toStringAsFixed(1)} kJ na wietrze lub zbyt wcześnie zużyto W\'.',
      TacticalCoachGrade.c =>
        'Przeciętna realizacja taktyki: widoczne błędy pozycjonowania na wietrze i nierówny timing ataków W\'.',
      TacticalCoachGrade.d =>
        'Kosztowny taktycznie etap dla $riderName — duże straty wiatrowe (${windSummary.totalWastedEnergyKj.toStringAsFixed(1)} kJ) osłabiły końcówkę.',
      TacticalCoachGrade.f =>
        'Krytyczne błędy taktyczne: wysokie straty na wietrze i ${attackSummary.blowupCount} odcięć W\' zniweczyły potencjał fizyczny.',
    };
  }

  String _buildWindSegmentDiagnosis({
    required bool occurredInGutter,
    required bool occurredInEchelon,
    required double avgCrosswindKmh,
    required double avgDraftPercent,
    required double wastedKj,
  }) {
    if (occurredInGutter) {
      return 'Zepchnięcie do krawężnika na wietrze bocznym ${avgCrosswindKmh.toStringAsFixed(0)} km/h (strata ${wastedKj.toStringAsFixed(1)} kJ).';
    }
    if (occurredInEchelon) {
      return 'Jazda na nieosłoniętym boku wachlarza (draft ${avgDraftPercent.toStringAsFixed(0)}%, strata ${wastedKj.toStringAsFixed(1)} kJ).';
    }
    return 'Długa ekspozycja poza tunelem aero (draft ${avgDraftPercent.toStringAsFixed(0)}%, strata ${wastedKj.toStringAsFixed(1)} kJ).';
  }

  double _targetDraftThreshold(TacticalCoachRiderRole role) {
    return switch (role) {
      TacticalCoachRiderRole.sprinter => 34.0,
      TacticalCoachRiderRole.gcLeader => 30.0,
      TacticalCoachRiderRole.climber => 28.0,
      TacticalCoachRiderRole.puncheur => 28.0,
      TacticalCoachRiderRole.breakawaySpecialist => 20.0,
      TacticalCoachRiderRole.domestique => 22.0,
    };
  }

  double _sampleDt(List<PostRaceTelemetrySample> samples, int index) {
    if (samples.length <= 1) return 1.0;
    if (index == 0) {
      return (samples[1].timestampSeconds - samples[0].timestampSeconds)
          .clamp(0.5, 30.0);
    }
    return (samples[index].timestampSeconds -
            samples[index - 1].timestampSeconds)
        .clamp(0.5, 30.0);
  }

  PostRaceTacticalCoachReport _buildEmptyTelemetryReport(
    PostRaceCoachAnalysisInput input,
  ) {
    return PostRaceTacticalCoachReport(
      riderId: input.riderId,
      riderName: input.riderName,
      stageName: input.stageName,
      role: input.role,
      overallTacticalScore: 0.0,
      grade: TacticalCoachGrade.f,
      executiveVerdict:
          'Brak próbek telemetrii dla ${input.riderName} na etapie ${input.stageName}.',
      windSummary: const WindAeroEfficiencySummary(
        totalWastedEnergyKj: 0.0,
        averageWastedWattsWhenExposed: 0.0,
        exposedDurationSeconds: 0.0,
        shelteredPercentOfStage: 0.0,
        equivalentFtpMinutesWasted: 0.0,
        gutterExposureCount: 0,
        topMistakeSegments: [],
      ),
      attackSummary: const WPrimeAttackTimingSummary(
        totalAttacks: 0,
        optimalAttacks: 0,
        poorlyTimedAttacks: 0,
        blowupCount: 0,
        averagePreAttackWPrimePercent: 0.0,
        averageTimingScore: 0.0,
        attacks: [],
      ),
      insights: const [],
    );
  }
}

class _AttackEvaluationScore {
  final double score;
  final AttackTimingVerdict verdict;
  final String note;

  const _AttackEvaluationScore({
    required this.score,
    required this.verdict,
    required this.note,
  });
}

// ============================================================================
// 4. STAN I NOTIFIER RIVERPOD
// ============================================================================

/// Stan modułu Analityka Taktycznego AI po wyścigu.
class PostRaceAiTacticalCoachState {
  final List<PostRaceTacticalCoachReport> reports;
  final int selectedRiderIndex;
  final TacticalCoachPanelTab activeTab;
  final bool isAnalyzing;

  const PostRaceAiTacticalCoachState({
    required this.reports,
    this.selectedRiderIndex = 0,
    this.activeTab = TacticalCoachPanelTab.overview,
    this.isAnalyzing = false,
  });

  PostRaceTacticalCoachReport? get selectedReport {
    if (reports.isEmpty) return null;
    final int safeIndex = selectedRiderIndex.clamp(0, reports.length - 1);
    return reports[safeIndex];
  }

  PostRaceAiTacticalCoachState copyWith({
    List<PostRaceTacticalCoachReport>? reports,
    int? selectedRiderIndex,
    TacticalCoachPanelTab? activeTab,
    bool? isAnalyzing,
  }) {
    return PostRaceAiTacticalCoachState(
      reports: reports ?? this.reports,
      selectedRiderIndex: selectedRiderIndex ?? this.selectedRiderIndex,
      activeTab: activeTab ?? this.activeTab,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}

/// Notifier zarządzający analizą taktyczną po etapie.
class PostRaceAiTacticalCoachNotifier
    extends StateNotifier<PostRaceAiTacticalCoachState> {
  final PostRaceAiTacticalCoachAnalyzer _analyzer;

  PostRaceAiTacticalCoachNotifier({
    PostRaceAiTacticalCoachAnalyzer? analyzer,
    List<PostRaceTacticalCoachReport> initialReports = const [],
  })  : _analyzer = analyzer ?? const PostRaceAiTacticalCoachAnalyzer(),
        super(PostRaceAiTacticalCoachState(reports: initialReports));

  void analyzeTeamStage(List<PostRaceCoachAnalysisInput> inputs) {
    state = state.copyWith(isAnalyzing: true);
    final List<PostRaceTacticalCoachReport> reports =
        _analyzer.analyzeTeam(inputs);
    state = state.copyWith(
      reports: reports,
      selectedRiderIndex: 0,
      isAnalyzing: false,
    );
  }

  void selectRider(int index) {
    if (state.reports.isEmpty) return;
    state = state.copyWith(
      selectedRiderIndex: index.clamp(0, state.reports.length - 1),
    );
  }

  void selectTab(TacticalCoachPanelTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void clearReports() {
    state = const PostRaceAiTacticalCoachState(reports: []);
  }
}

final postRaceAiTacticalCoachAnalyzerProvider =
    Provider<PostRaceAiTacticalCoachAnalyzer>(
  (ref) => const PostRaceAiTacticalCoachAnalyzer(),
);

final postRaceAiTacticalCoachProvider = StateNotifierProvider<
    PostRaceAiTacticalCoachNotifier, PostRaceAiTacticalCoachState>((ref) {
  return PostRaceAiTacticalCoachNotifier(
    analyzer: ref.watch(postRaceAiTacticalCoachAnalyzerProvider),
  );
});

// ============================================================================
// 5. RESPONSYWNY PANEL UI ANALITYKA TAKTYCZNEGO AI
// ============================================================================

/// Interaktywny panel raportu Analityka Taktycznego AI po wyścigu.
class PostRaceAiTacticalCoachPanel extends StatefulWidget {
  final PostRaceTacticalCoachReport? report;
  final bool isDisabled;
  final ValueChanged<TacticalCoachPanelTab>? onTabChanged;
  final VoidCallback? onExportReport;

  const PostRaceAiTacticalCoachPanel({
    super.key,
    required this.report,
    this.isDisabled = false,
    this.onTabChanged,
    this.onExportReport,
  });

  @override
  State<PostRaceAiTacticalCoachPanel> createState() =>
      _PostRaceAiTacticalCoachPanelState();
}

class _PostRaceAiTacticalCoachPanelState
    extends State<PostRaceAiTacticalCoachPanel> {
  TacticalCoachPanelTab _activeTab = TacticalCoachPanelTab.overview;
  bool _exportHovered = false;
  bool _exportFocused = false;

  @override
  Widget build(BuildContext context) {
    final PostRaceTacticalCoachReport? report = widget.report;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 520;
        final bool isWide = constraints.maxWidth >= 960;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: report == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(report, isCompact),
                      const SizedBox(height: 14),
                      _buildTabBar(isCompact),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: _buildTabContent(report, isCompact, isWide),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: AppColors.textSecondary,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              'Brak danych telemetrycznych do analizy AI',
              textAlign: TextAlign.center,
              style: _interStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ukończ etap, aby Analityk AI ocenił straty wiatrowe i timing ataków W\'.',
              textAlign: TextAlign.center,
              style: _interStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PostRaceTacticalCoachReport report, bool isCompact) {
    final Color gradeColor = _gradeColor(report.grade);
    final Widget gradeBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gradeColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gradeColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            report.grade.name.toUpperCase(),
            style: _interStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: gradeColor,
              tabular: true,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${report.overallTacticalScore.toStringAsFixed(0)}/100',
            style: _interStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              tabular: true,
            ),
          ),
        ],
      ),
    );

    final Widget exportButton = FocusableActionDetector(
      enabled: !widget.isDisabled && widget.onExportReport != null,
      onShowHoverHighlight: (v) => setState(() => _exportHovered = v),
      onShowFocusHighlight: (v) => setState(() => _exportFocused = v),
      child: InkWell(
        onTap: widget.isDisabled ? null : widget.onExportReport,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? AppColors.surfaceLight.withValues(alpha: 0.4)
                : (_exportHovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.25)
                    : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _exportFocused
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.ios_share_rounded,
                size: 15,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              Text(
                'Eksportuj',
                style: _interStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

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
                    'ANALITYK TAKTYCZNY AI — ${report.riderName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _interStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.stageName} • Rola: ${_roleLabel(report.role)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _interStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            gradeBadge,
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                report.executiveVerdict,
                style: _interStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (widget.onExportReport != null) ...[
              const SizedBox(width: 10),
              exportButton,
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isCompact) {
    final List<({TacticalCoachPanelTab tab, String label, IconData icon})> tabs = [
      (
        tab: TacticalCoachPanelTab.overview,
        label: 'Podsumowanie',
        icon: Icons.dashboard_outlined,
      ),
      (
        tab: TacticalCoachPanelTab.windLoss,
        label: 'Straty na wietrze',
        icon: Icons.air_rounded,
      ),
      (
        tab: TacticalCoachPanelTab.attackTiming,
        label: 'Timing ataków W\'',
        icon: Icons.bolt_rounded,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tabs.map((item) {
        final bool selected = _activeTab == item.tab;
        return _CoachTabPill(
          label: item.label,
          icon: item.icon,
          selected: selected,
          disabled: widget.isDisabled,
          compact: isCompact,
          onTap: () {
            setState(() => _activeTab = item.tab);
            widget.onTabChanged?.call(item.tab);
          },
        );
      }).toList(),
    );
  }

  Widget _buildTabContent(
    PostRaceTacticalCoachReport report,
    bool isCompact,
    bool isWide,
  ) {
    switch (_activeTab) {
      case TacticalCoachPanelTab.overview:
        return _buildOverviewTab(report, isCompact, isWide);
      case TacticalCoachPanelTab.windLoss:
        return _buildWindLossTab(report);
      case TacticalCoachPanelTab.attackTiming:
        return _buildAttackTimingTab(report);
    }
  }

  Widget _buildOverviewTab(
    PostRaceTacticalCoachReport report,
    bool isCompact,
    bool isWide,
  ) {
    final List<Widget> kpis = [
      _buildKpiBox(
        title: 'Stracone na wietrze',
        value:
            '${report.windSummary.totalWastedEnergyKj.toStringAsFixed(1)} kJ',
        subtitle:
            '${report.windSummary.equivalentFtpMinutesWasted.toStringAsFixed(1)} min FTP',
        accent: report.windSummary.totalWastedEnergyKj >= 25
            ? AppColors.crimsonAlert
            : AppColors.accentBlue,
      ),
      _buildKpiBox(
        title: 'Jazda w cieniu',
        value:
            '${report.windSummary.shelteredPercentOfStage.toStringAsFixed(0)}%',
        subtitle:
            '${report.windSummary.gutterExposureCount}x na skraju rantu',
        accent: AppColors.statusSuccess,
      ),
      _buildKpiBox(
        title: 'Ataki z W\'',
        value:
            '${report.attackSummary.optimalAttacks}/${report.attackSummary.totalAttacks}',
        subtitle:
            'Śr. start W\': ${report.attackSummary.averagePreAttackWPrimePercent.toStringAsFixed(0)}%',
        accent: AppColors.goldAccent,
      ),
    ];

    return Column(
      key: const ValueKey('overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompact)
          Column(
            children: kpis
                .map(
                  (k) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(width: double.infinity, child: k),
                  ),
                )
                .toList(),
          )
        else
          Row(
            children: kpis
                .map(
                  (k) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: k,
                    ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 14),
        Text(
          'KLUCZOWE WNIOSKI TRENERA AI',
          style: _interStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (report.insights.isEmpty)
          Text(
            'Brak uwag taktycznych.',
            style: _interStyle(fontSize: 13, color: AppColors.textSecondary),
          )
        else if (isWide)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: report.insights
                .map(
                  (ins) => SizedBox(
                    width: 420,
                    child: _buildInsightCard(ins),
                  ),
                )
                .toList(),
          )
        else
          Column(
            children: report.insights
                .map(
                  (ins) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildInsightCard(ins),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildWindLossTab(PostRaceTacticalCoachReport report) {
    final WindAeroEfficiencySummary wind = report.windSummary;
    return Column(
      key: const ValueKey('windLoss'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Najbardziej kosztowne odcinki na wietrze (${wind.topMistakeSegments.length})',
          style: _interStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (wind.topMistakeSegments.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              'Brak istotnych odcinków z niepotrzebną stratą watów na wietrze.',
              style: _interStyle(fontSize: 13, color: AppColors.statusSuccess),
            ),
          )
        else
          ...wind.topMistakeSegments.map(
            (seg) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: seg.occurredInGutter
                      ? AppColors.crimsonAlert.withValues(alpha: 0.6)
                      : AppTheme.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'km ${seg.startKm.toStringAsFixed(1)} – ${seg.endKm.toStringAsFixed(1)} (${seg.durationSeconds.toStringAsFixed(0)} s)',
                          style: _interStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            tabular: true,
                          ),
                        ),
                      ),
                      Text(
                        '-${seg.wastedEnergyKj.toStringAsFixed(1)} kJ • ${seg.averageWastedWatts.toStringAsFixed(0)} W',
                        style: _interStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberWarning,
                          tabular: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seg.diagnosis,
                    style: _interStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttackTimingTab(PostRaceTacticalCoachReport report) {
    final WPrimeAttackTimingSummary atk = report.attackSummary;
    return Column(
      key: const ValueKey('attackTiming'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ocena prób ataku z zasobów W\' (${atk.totalAttacks})',
          style: _interStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (atk.attacks.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              'Kolarz nie podejmował ataków powyżej 122% FTP na tym etapie.',
              style: _interStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          ...atk.attacks.map((a) {
            final Color vColor = _verdictColor(a.verdict);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: vColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Atak #${a.attackIndex} • km ${a.startKm.toStringAsFixed(1)} (${a.distanceToFinishKm.toStringAsFixed(1)} km do mety)',
                          style: _interStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            tabular: true,
                          ),
                        ),
                      ),
                      Text(
                        '${a.timingScore.toStringAsFixed(0)} pkt',
                        style: _interStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: vColor,
                          tabular: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Szczyt ${a.peakWatts} W • W\' start: ${(a.preAttackWPrimeRatio * 100).toStringAsFixed(0)}% → min ${(a.minWPrimeRatioDuringAttack * 100).toStringAsFixed(0)}%',
                    style: _interStyle(
                      fontSize: 12,
                      color: AppColors.cyanAccent,
                      tabular: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.coachingNote,
                    style: _interStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildKpiBox({
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _interStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: _interStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
              tabular: true,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: _interStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              tabular: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(TacticalCoachingInsight insight) {
    final Color sevColor = switch (insight.severity) {
      TacticalInsightSeverity.critical => AppColors.crimsonAlert,
      TacticalInsightSeverity.warning => AppColors.amberWarning,
      TacticalInsightSeverity.positive => AppColors.statusSuccess,
      TacticalInsightSeverity.tip => AppColors.accentBlue,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sevColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.title,
                  style: _interStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sevColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.impactMetricLabel,
                  style: _interStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sevColor,
                    tabular: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            insight.description,
            style: _interStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Zalecenie: ${insight.nextStageAction}',
            style: _interStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.goldAccent,
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(TacticalCoachGrade grade) {
    return switch (grade) {
      TacticalCoachGrade.s => AppColors.goldAccent,
      TacticalCoachGrade.a => AppColors.statusSuccess,
      TacticalCoachGrade.b => AppColors.accentBlue,
      TacticalCoachGrade.c => AppColors.amberWarning,
      TacticalCoachGrade.d => AppColors.powerZone5,
      TacticalCoachGrade.f => AppColors.crimsonAlert,
    };
  }

  Color _verdictColor(AttackTimingVerdict verdict) {
    return switch (verdict) {
      AttackTimingVerdict.optimal => AppColors.goldAccent,
      AttackTimingVerdict.wellTimed => AppColors.statusSuccess,
      AttackTimingVerdict.risky => AppColors.amberWarning,
      AttackTimingVerdict.poorlyTimedHeadwind => AppColors.powerZone5,
      AttackTimingVerdict.emptyTankBlowup => AppColors.crimsonAlert,
    };
  }

  String _roleLabel(TacticalCoachRiderRole role) {
    return switch (role) {
      TacticalCoachRiderRole.gcLeader => 'Lider GC',
      TacticalCoachRiderRole.sprinter => 'Sprinter',
      TacticalCoachRiderRole.puncheur => 'Puncheur',
      TacticalCoachRiderRole.climber => 'Góral',
      TacticalCoachRiderRole.domestique => 'Pomocnik',
      TacticalCoachRiderRole.breakawaySpecialist => 'Uciekinier',
    };
  }

  TextStyle _interStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    required Color color,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      letterSpacing: -0.2,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }
}

class _CoachTabPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final bool compact;
  final VoidCallback onTap;

  const _CoachTabPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.disabled,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_CoachTabPill> createState() => _CoachTabPillState();
}

class _CoachTabPillState extends State<_CoachTabPill> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.45 : 0.32)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.7));

    final Color border = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.primaryAccent
            : AppTheme.borderColor;

    final Color fg = widget.disabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.goldAccent
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
