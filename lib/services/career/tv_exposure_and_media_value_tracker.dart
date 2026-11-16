// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/tour_race.dart';

/// Źródło ekspozycji telewizyjnej koszulki drużyny gracza w kamerze TV.
enum TvCameraExposureSource {
  /// Jazda w ucieczce dnia (kamera motocyklowa lub helikopter nad odjazdem).
  breakawayOfTheDay,

  /// Prowadzenie peletonu na czele głównej grupy (pociąg drużyny).
  pelotonFrontPulling,

  /// Ataki w górach i solowe akcje na podjazdach.
  mountainAttack,

  /// Dekoracja na podium po etapie lub wyścigu (koszulki, wywiady, ścianka sponsorska).
  podiumCeremony,

  /// Finisz sprinterski i ostatni kilometr (Flamme Rouge).
  sprintFinish,

  /// Ekspozycja koszulki lidera klasyfikacji (żółta, różowa, czerwona, grochy, zielona).
  leaderJerseySpotlight;

  String get displayNamePl {
    switch (this) {
      case TvCameraExposureSource.breakawayOfTheDay:
        return 'Jazda w ucieczce dnia';
      case TvCameraExposureSource.pelotonFrontPulling:
        return 'Prowadzenie peletonu';
      case TvCameraExposureSource.mountainAttack:
        return 'Ataki w górach';
      case TvCameraExposureSource.podiumCeremony:
        return 'Dekoracja na podium';
      case TvCameraExposureSource.sprintFinish:
        return 'Finisz sprinterski';
      case TvCameraExposureSource.leaderJerseySpotlight:
        return 'Koszulka lidera';
    }
  }

  /// Mnożnik jakości ujęcia i skupienia uwagi widza na logo sponsora.
  double get prominenceMultiplier {
    switch (this) {
      case TvCameraExposureSource.breakawayOfTheDay:
        return 1.20;
      case TvCameraExposureSource.pelotonFrontPulling:
        return 1.00;
      case TvCameraExposureSource.mountainAttack:
        return 1.65;
      case TvCameraExposureSource.podiumCeremony:
        return 2.40;
      case TvCameraExposureSource.sprintFinish:
        return 1.85;
      case TvCameraExposureSource.leaderJerseySpotlight:
        return 1.50;
    }
  }

  String toJson() => name;

  static TvCameraExposureSource fromJson(String value) {
    return TvCameraExposureSource.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TvCameraExposureSource.pelotonFrontPulling,
    );
  }
}

/// Ocena zwrotu z inwestycji (ROI) dla sponsora na podstawie ekwiwalentu reklamowego.
enum SponsorMediaRoiGrade {
  tierS,
  tierA,
  tierB,
  tierC,
  tierD;

  String get label {
    switch (this) {
      case SponsorMediaRoiGrade.tierS:
        return 'S (Fenomenalny ROI)';
      case SponsorMediaRoiGrade.tierA:
        return 'A (Wysoki ROI)';
      case SponsorMediaRoiGrade.tierB:
        return 'B (Solidny ROI)';
      case SponsorMediaRoiGrade.tierC:
        return 'C (Poniżej oczekiwań)';
      case SponsorMediaRoiGrade.tierD:
        return 'D (Krytycznie niski)';
    }
  }
}

/// Pojedyncza próbka ekspozycji koszulki w kamerze TV.
class TvExposureCameraSample {
  final TvCameraExposureSource source;
  final double durationSeconds;
  final int visibleTeamRidersCount;
  final bool isHeroCameraCloseUp;
  final bool hasLeaderJerseyVisible;
  final String? riderId;
  final String? riderName;
  final double? stageKilometer;

  const TvExposureCameraSample({
    required this.source,
    required this.durationSeconds,
    this.visibleTeamRidersCount = 1,
    this.isHeroCameraCloseUp = false,
    this.hasLeaderJerseyVisible = false,
    this.riderId,
    this.riderName,
    this.stageKilometer,
  });

  double get sanitizedDurationSeconds =>
      durationSeconds.isFinite && durationSeconds > 0.0 ? durationSeconds : 0.0;

  int get sanitizedRiderCount => visibleTeamRidersCount.clamp(1, 9);

  /// Efektywny czas ekspozycji uwzględniający liczbę widocznych kolarzy i zbliżenie kamery.
  double get weightedSeconds {
    final base = sanitizedDurationSeconds;
    if (base <= 0.0) return 0.0;

    final groupBonus = 1.0 + 0.22 * (sanitizedRiderCount - 1).clamp(0, 5);
    final closeUpBonus = isHeroCameraCloseUp ? 1.35 : 1.0;
    final jerseyBonus = hasLeaderJerseyVisible ? 1.25 : 1.0;

    return base *
        source.prominenceMultiplier *
        groupBonus *
        closeUpBonus *
        jerseyBonus;
  }
}

/// Zagregowane statystyki ekspozycji dla jednego źródła kamery TV.
class TvExposureSourceBreakdown {
  final TvCameraExposureSource source;
  final double rawSeconds;
  final double weightedSeconds;
  final double advertisingValueEur;
  final double advertisingValueMillionsEur;
  final double sharePercent;

  const TvExposureSourceBreakdown({
    required this.source,
    required this.rawSeconds,
    required this.weightedSeconds,
    required this.advertisingValueEur,
    required this.advertisingValueMillionsEur,
    required this.sharePercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'source': source.toJson(),
      'rawSeconds': rawSeconds,
      'weightedSeconds': weightedSeconds,
      'advertisingValueEur': advertisingValueEur,
      'advertisingValueMillionsEur': advertisingValueMillionsEur,
      'sharePercent': sharePercent,
    };
  }

  factory TvExposureSourceBreakdown.fromJson(Map<String, dynamic> json) {
    return TvExposureSourceBreakdown(
      source: TvCameraExposureSource.fromJson(
        (json['source'] as String?) ?? '',
      ),
      rawSeconds: (json['rawSeconds'] as num?)?.toDouble() ?? 0.0,
      weightedSeconds: (json['weightedSeconds'] as num?)?.toDouble() ?? 0.0,
      advertisingValueEur:
          (json['advertisingValueEur'] as num?)?.toDouble() ?? 0.0,
      advertisingValueMillionsEur:
          (json['advertisingValueMillionsEur'] as num?)?.toDouble() ?? 0.0,
      sharePercent: (json['sharePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Raport ekspozycji telewizyjnej i ekwiwalentu reklamowego po etapie lub wyścigu.
class StageTvExposureReport {
  final String stageId;
  final String raceName;
  final RaceCategory raceCategory;
  final String sponsorName;
  final double totalRawSeconds;
  final double totalWeightedSeconds;
  final double totalAdvertisingValueEur;
  final double totalAdvertisingValueMillionsEur;
  final Map<TvCameraExposureSource, TvExposureSourceBreakdown> sourceBreakdowns;
  final Map<String, double> riderSecondsMap;
  final String? topExposedRiderName;
  final DateTime recordedAt;

  const StageTvExposureReport({
    required this.stageId,
    required this.raceName,
    required this.raceCategory,
    required this.sponsorName,
    required this.totalRawSeconds,
    required this.totalWeightedSeconds,
    required this.totalAdvertisingValueEur,
    required this.totalAdvertisingValueMillionsEur,
    required this.sourceBreakdowns,
    required this.riderSecondsMap,
    this.topExposedRiderName,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'raceName': raceName,
      'raceCategory': raceCategory.toJson(),
      'sponsorName': sponsorName,
      'totalRawSeconds': totalRawSeconds,
      'totalWeightedSeconds': totalWeightedSeconds,
      'totalAdvertisingValueEur': totalAdvertisingValueEur,
      'totalAdvertisingValueMillionsEur': totalAdvertisingValueMillionsEur,
      'sourceBreakdowns': {
        for (final entry in sourceBreakdowns.entries)
          entry.key.toJson(): entry.value.toJson(),
      },
      'riderSecondsMap': riderSecondsMap,
      'topExposedRiderName': topExposedRiderName,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory StageTvExposureReport.fromJson(Map<String, dynamic> json) {
    final rawBreakdowns =
        (json['sourceBreakdowns'] as Map<String, dynamic>?) ?? const {};
    final breakdowns = <TvCameraExposureSource, TvExposureSourceBreakdown>{};
    for (final entry in rawBreakdowns.entries) {
      final src = TvCameraExposureSource.fromJson(entry.key);
      if (entry.value is Map<String, dynamic>) {
        breakdowns[src] = TvExposureSourceBreakdown.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    final rawRiderMap =
        (json['riderSecondsMap'] as Map<String, dynamic>?) ?? const {};
    final riderMap = <String, double>{
      for (final entry in rawRiderMap.entries)
        entry.key: (entry.value as num?)?.toDouble() ?? 0.0,
    };

    return StageTvExposureReport(
      stageId: (json['stageId'] as String?) ?? '',
      raceName: (json['raceName'] as String?) ?? '',
      raceCategory: RaceCategory.fromJson(
        (json['raceCategory'] as String?) ?? '',
      ),
      sponsorName: (json['sponsorName'] as String?) ?? '',
      totalRawSeconds: (json['totalRawSeconds'] as num?)?.toDouble() ?? 0.0,
      totalWeightedSeconds:
          (json['totalWeightedSeconds'] as num?)?.toDouble() ?? 0.0,
      totalAdvertisingValueEur:
          (json['totalAdvertisingValueEur'] as num?)?.toDouble() ?? 0.0,
      totalAdvertisingValueMillionsEur:
          (json['totalAdvertisingValueMillionsEur'] as num?)?.toDouble() ?? 0.0,
      sourceBreakdowns: Map.unmodifiable(breakdowns),
      riderSecondsMap: Map.unmodifiable(riderMap),
      topExposedRiderName: json['topExposedRiderName'] as String?,
      recordedAt:
          DateTime.tryParse((json['recordedAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// Sezonowe podsumowanie ekwiwalentu reklamowego sponsora i wskaźnika ROI.
class SeasonTvMediaValueSummary {
  final String sponsorName;
  final int annualSponsorBudgetEur;
  final int totalStagesTracked;
  final double totalRawSeconds;
  final double totalWeightedSeconds;
  final double totalAdvertisingValueEur;
  final double totalAdvertisingValueMillionsEur;
  final double roiMultiplier;
  final SponsorMediaRoiGrade roiGrade;
  final Map<TvCameraExposureSource, double> sourceTotalsSeconds;
  final Map<TvCameraExposureSource, double> sourceTotalsMillionsEur;
  final List<StageTvExposureReport> stageReports;

  const SeasonTvMediaValueSummary({
    required this.sponsorName,
    required this.annualSponsorBudgetEur,
    required this.totalStagesTracked,
    required this.totalRawSeconds,
    required this.totalWeightedSeconds,
    required this.totalAdvertisingValueEur,
    required this.totalAdvertisingValueMillionsEur,
    required this.roiMultiplier,
    required this.roiGrade,
    required this.sourceTotalsSeconds,
    required this.sourceTotalsMillionsEur,
    required this.stageReports,
  });
}

/// Serwis mierzący ekspozycję telewizyjną sponsora drużyny gracza oraz
/// przeliczający czas antenowy na ekwiwalent reklamowy (AVE) w milionach EUR.
class TvExposureAndMediaValueTracker {
  static const double _eurPerMillion = 1000000.0;

  final Map<TvCameraExposureSource, double> _rawSecondsBySource = {
    for (final source in TvCameraExposureSource.values) source: 0.0,
  };
  final Map<TvCameraExposureSource, double> _weightedSecondsBySource = {
    for (final source in TvCameraExposureSource.values) source: 0.0,
  };
  final Map<String, double> _secondsByRider = {};
  final List<StageTvExposureReport> _seasonHistory = [];

  TvExposureAndMediaValueTracker();

  /// Bazowa stawka ekwiwalentu reklamowego w EUR za 1 ważoną sekundę czasu antenowego.
  static double baseEurPerWeightedSecond(RaceCategory category) {
    switch (category) {
      case RaceCategory.grandTour:
        return 1650.0;
      case RaceCategory.monument:
        return 1150.0;
      case RaceCategory.worldTourStageRace:
        return 720.0;
      case RaceCategory.worldTourOneDay:
        return 680.0;
      case RaceCategory.proSeries:
        return 310.0;
      case RaceCategory.class1:
        return 125.0;
    }
  }

  /// Przelicza ważone sekundy ekspozycji na ekwiwalent reklamowy w EUR.
  static double calculateAdvertisingValueEur({
    required double weightedSeconds,
    required RaceCategory raceCategory,
    double reachMultiplier = 1.0,
  }) {
    if (!weightedSeconds.isFinite || weightedSeconds <= 0.0) return 0.0;
    final clampedReach =
        reachMultiplier.isFinite ? reachMultiplier.clamp(0.2, 3.0) : 1.0;
    return weightedSeconds *
        baseEurPerWeightedSecond(raceCategory) *
        clampedReach;
  }

  /// Przelicza ważone sekundy ekspozycji na ekwiwalent reklamowy w milionach EUR.
  static double calculateAdvertisingValueMillionsEur({
    required double weightedSeconds,
    required RaceCategory raceCategory,
    double reachMultiplier = 1.0,
  }) {
    return calculateAdvertisingValueEur(
          weightedSeconds: weightedSeconds,
          raceCategory: raceCategory,
          reachMultiplier: reachMultiplier,
        ) /
        _eurPerMillion;
  }

  /// Ocenia klasę ROI na podstawie stosunku AVE do rocznego budżetu sponsora.
  static SponsorMediaRoiGrade evaluateSponsorRoiGrade(double roiMultiplier) {
    if (!roiMultiplier.isFinite || roiMultiplier < 0.8) {
      return SponsorMediaRoiGrade.tierD;
    }
    if (roiMultiplier >= 3.0) return SponsorMediaRoiGrade.tierS;
    if (roiMultiplier >= 2.0) return SponsorMediaRoiGrade.tierA;
    if (roiMultiplier >= 1.25) return SponsorMediaRoiGrade.tierB;
    return SponsorMediaRoiGrade.tierC;
  }

  /// Łączna liczba surowych sekund ekspozycji na bieżącym etapie.
  double get currentStageRawSeconds =>
      _rawSecondsBySource.values.fold(0.0, (a, b) => a + b);

  /// Łączna liczba ważonych sekund ekspozycji na bieżącym etapie.
  double get currentStageWeightedSeconds =>
      _weightedSecondsBySource.values.fold(0.0, (a, b) => a + b);

  /// Niemodyfikowalna mapa surowych sekund wg źródła dla bieżącego etapu.
  Map<TvCameraExposureSource, double> get currentStageSecondsBySource =>
      Map.unmodifiable(_rawSecondsBySource);

  /// Historia raportów etapowych zarejestrowanych w sezonie.
  List<StageTvExposureReport> get seasonHistory =>
      List.unmodifiable(_seasonHistory);

  /// Rejestruje pojedynczą próbkę widoczności koszulki w kamerze TV.
  void recordSample(TvExposureCameraSample sample) {
    final raw = sample.sanitizedDurationSeconds;
    if (raw <= 0.0) return;

    final weighted = sample.weightedSeconds;
    _rawSecondsBySource[sample.source] =
        (_rawSecondsBySource[sample.source] ?? 0.0) + raw;
    _weightedSecondsBySource[sample.source] =
        (_weightedSecondsBySource[sample.source] ?? 0.0) + weighted;

    final riderLabel = sample.riderName?.trim();
    if (riderLabel != null && riderLabel.isNotEmpty) {
      _secondsByRider[riderLabel] = (_secondsByRider[riderLabel] ?? 0.0) + raw;
    }
  }

  /// Rejestruje tick symulacji wyścigu 3D na podstawie stanu taktycznego kolarzy gracza.
  void recordSimulationTick({
    required double deltaSeconds,
    bool isInBreakaway = false,
    bool isPullingPeloton = false,
    bool isMountainAttacking = false,
    bool isInFinalSprint = false,
    bool hasLeaderJersey = false,
    int visibleTeamRidersCount = 1,
    bool isHeroCameraCloseUp = false,
    String? activeRiderId,
    String? activeRiderName,
    double? stageKilometer,
  }) {
    if (!deltaSeconds.isFinite || deltaSeconds <= 0.0) return;

    if (isMountainAttacking) {
      recordSample(
        TvExposureCameraSample(
          source: TvCameraExposureSource.mountainAttack,
          durationSeconds: deltaSeconds,
          visibleTeamRidersCount: visibleTeamRidersCount,
          isHeroCameraCloseUp: true,
          hasLeaderJerseyVisible: hasLeaderJersey,
          riderId: activeRiderId,
          riderName: activeRiderName,
          stageKilometer: stageKilometer,
        ),
      );
      return;
    }

    if (isInFinalSprint) {
      recordSample(
        TvExposureCameraSample(
          source: TvCameraExposureSource.sprintFinish,
          durationSeconds: deltaSeconds,
          visibleTeamRidersCount: visibleTeamRidersCount,
          isHeroCameraCloseUp: isHeroCameraCloseUp,
          hasLeaderJerseyVisible: hasLeaderJersey,
          riderId: activeRiderId,
          riderName: activeRiderName,
          stageKilometer: stageKilometer,
        ),
      );
      return;
    }

    if (isInBreakaway) {
      recordSample(
        TvExposureCameraSample(
          source: TvCameraExposureSource.breakawayOfTheDay,
          durationSeconds: deltaSeconds,
          visibleTeamRidersCount: visibleTeamRidersCount,
          isHeroCameraCloseUp: isHeroCameraCloseUp,
          hasLeaderJerseyVisible: hasLeaderJersey,
          riderId: activeRiderId,
          riderName: activeRiderName,
          stageKilometer: stageKilometer,
        ),
      );
      return;
    }

    if (isPullingPeloton) {
      recordSample(
        TvExposureCameraSample(
          source: TvCameraExposureSource.pelotonFrontPulling,
          durationSeconds: deltaSeconds,
          visibleTeamRidersCount: visibleTeamRidersCount,
          isHeroCameraCloseUp: isHeroCameraCloseUp,
          hasLeaderJerseyVisible: hasLeaderJersey,
          riderId: activeRiderId,
          riderName: activeRiderName,
          stageKilometer: stageKilometer,
        ),
      );
      return;
    }

    if (hasLeaderJersey) {
      recordSample(
        TvExposureCameraSample(
          source: TvCameraExposureSource.leaderJerseySpotlight,
          durationSeconds: deltaSeconds,
          visibleTeamRidersCount: 1,
          isHeroCameraCloseUp: isHeroCameraCloseUp,
          hasLeaderJerseyVisible: true,
          riderId: activeRiderId,
          riderName: activeRiderName,
          stageKilometer: stageKilometer,
        ),
      );
    }
  }

  /// Rejestruje czas ekspozycji sponsora podczas dekoracji na podium po etapie.
  void recordPodiumCeremony({
    required double durationSeconds,
    String? riderId,
    String? riderName,
    bool hasLeaderJersey = true,
  }) {
    recordSample(
      TvExposureCameraSample(
        source: TvCameraExposureSource.podiumCeremony,
        durationSeconds: durationSeconds,
        visibleTeamRidersCount: 1,
        isHeroCameraCloseUp: true,
        hasLeaderJerseyVisible: hasLeaderJersey,
        riderId: riderId,
        riderName: riderName,
      ),
    );
  }

  /// Wylicza bieżący ekwiwalent reklamowy etapu w milionach EUR bez zamykania etapu.
  double previewCurrentStageMediaValueMillionsEur({
    required RaceCategory raceCategory,
    double reachMultiplier = 1.0,
  }) {
    return calculateAdvertisingValueMillionsEur(
      weightedSeconds: currentStageWeightedSeconds,
      raceCategory: raceCategory,
      reachMultiplier: reachMultiplier,
    );
  }

  /// Finalizuje etap, generuje [StageTvExposureReport], zapisuje go w historii
  /// i opcjonalnie zeruje liczniki przed kolejnym etapem.
  StageTvExposureReport finalizeStageReport({
    required String stageId,
    required String raceName,
    required RaceCategory raceCategory,
    required String sponsorName,
    double reachMultiplier = 1.0,
    bool resetAfterFinalize = true,
    DateTime? timestamp,
  }) {
    final totalRaw = currentStageRawSeconds;
    final totalWeighted = currentStageWeightedSeconds;
    final totalEur = calculateAdvertisingValueEur(
      weightedSeconds: totalWeighted,
      raceCategory: raceCategory,
      reachMultiplier: reachMultiplier,
    );
    final totalMillions = totalEur / _eurPerMillion;

    final breakdowns = <TvCameraExposureSource, TvExposureSourceBreakdown>{};
    for (final source in TvCameraExposureSource.values) {
      final rawSec = _rawSecondsBySource[source] ?? 0.0;
      final weightedSec = _weightedSecondsBySource[source] ?? 0.0;
      final sourceEur = calculateAdvertisingValueEur(
        weightedSeconds: weightedSec,
        raceCategory: raceCategory,
        reachMultiplier: reachMultiplier,
      );
      final share = totalRaw > 0.0 ? (rawSec / totalRaw) * 100.0 : 0.0;

      breakdowns[source] = TvExposureSourceBreakdown(
        source: source,
        rawSeconds: rawSec,
        weightedSeconds: weightedSec,
        advertisingValueEur: sourceEur,
        advertisingValueMillionsEur: sourceEur / _eurPerMillion,
        sharePercent: share.clamp(0.0, 100.0),
      );
    }

    String? topRider;
    double maxRiderSeconds = -1.0;
    for (final entry in _secondsByRider.entries) {
      if (entry.value > maxRiderSeconds) {
        maxRiderSeconds = entry.value;
        topRider = entry.key;
      }
    }

    final report = StageTvExposureReport(
      stageId: stageId,
      raceName: raceName,
      raceCategory: raceCategory,
      sponsorName: sponsorName,
      totalRawSeconds: totalRaw,
      totalWeightedSeconds: totalWeighted,
      totalAdvertisingValueEur: totalEur,
      totalAdvertisingValueMillionsEur: totalMillions,
      sourceBreakdowns: Map.unmodifiable(breakdowns),
      riderSecondsMap: Map.unmodifiable(Map<String, double>.from(_secondsByRider)),
      topExposedRiderName: topRider,
      recordedAt: timestamp ?? DateTime.now(),
    );

    _seasonHistory.add(report);
    if (resetAfterFinalize) {
      resetStage();
    }
    return report;
  }

  /// Zeruje liczniki bieżącego etapu.
  void resetStage() {
    for (final source in TvCameraExposureSource.values) {
      _rawSecondsBySource[source] = 0.0;
      _weightedSecondsBySource[source] = 0.0;
    }
    _secondsByRider.clear();
  }

  /// Czyści całą historię sezonu oraz bieżący etap.
  void clearAll() {
    resetStage();
    _seasonHistory.clear();
  }

  /// Agreguje dane z raportów etapowych w pełne podsumowanie sezonowe dla sponsora.
  static SeasonTvMediaValueSummary aggregateSeasonMediaValue({
    required String sponsorName,
    required int annualSponsorBudgetEur,
    required List<StageTvExposureReport> reports,
  }) {
    double totalRaw = 0.0;
    double totalWeighted = 0.0;
    double totalEur = 0.0;

    final sourceSec = <TvCameraExposureSource, double>{
      for (final source in TvCameraExposureSource.values) source: 0.0,
    };
    final sourceMil = <TvCameraExposureSource, double>{
      for (final source in TvCameraExposureSource.values) source: 0.0,
    };

    for (final report in reports) {
      totalRaw += report.totalRawSeconds;
      totalWeighted += report.totalWeightedSeconds;
      totalEur += report.totalAdvertisingValueEur;

      for (final entry in report.sourceBreakdowns.entries) {
        sourceSec[entry.key] =
            (sourceSec[entry.key] ?? 0.0) + entry.value.rawSeconds;
        sourceMil[entry.key] =
            (sourceMil[entry.key] ?? 0.0) +
            entry.value.advertisingValueMillionsEur;
      }
    }

    final totalMillions = totalEur / _eurPerMillion;
    final roi = annualSponsorBudgetEur > 0
        ? totalEur / annualSponsorBudgetEur
        : 0.0;

    return SeasonTvMediaValueSummary(
      sponsorName: sponsorName,
      annualSponsorBudgetEur: annualSponsorBudgetEur,
      totalStagesTracked: reports.length,
      totalRawSeconds: totalRaw,
      totalWeightedSeconds: totalWeighted,
      totalAdvertisingValueEur: totalEur,
      totalAdvertisingValueMillionsEur: totalMillions,
      roiMultiplier: roi,
      roiGrade: evaluateSponsorRoiGrade(roi),
      sourceTotalsSeconds: Map.unmodifiable(sourceSec),
      sourceTotalsMillionsEur: Map.unmodifiable(sourceMil),
      stageReports: List.unmodifiable(reports),
    );
  }
}

/// Responsywny panel telemetryczny ekspozycji TV i ekwiwalentu reklamowego (AVE)
/// zgodny z paletą [AppColors] i typografią `Inter`.
class TvExposureMediaValuePanel extends StatefulWidget {
  final StageTvExposureReport report;
  final int? annualSponsorBudgetEur;
  final ValueChanged<TvCameraExposureSource?>? onSourceSelected;
  final VoidCallback? onResetPressed;
  final bool isActionEnabled;

  const TvExposureMediaValuePanel({
    super.key,
    required this.report,
    this.annualSponsorBudgetEur,
    this.onSourceSelected,
    this.onResetPressed,
    this.isActionEnabled = true,
  });

  @override
  State<TvExposureMediaValuePanel> createState() =>
      _TvExposureMediaValuePanelState();
}

class _TvExposureMediaValuePanelState extends State<TvExposureMediaValuePanel> {
  TvCameraExposureSource? _selectedSource;
  TvCameraExposureSource? _hoveredSource;
  TvCameraExposureSource? _focusedSource;
  bool _isResetHovered = false;
  bool _isResetPressed = false;
  bool _isResetFocused = false;

  Color _colorForSource(TvCameraExposureSource source) {
    switch (source) {
      case TvCameraExposureSource.breakawayOfTheDay:
        return AppColors.accentBlue;
      case TvCameraExposureSource.pelotonFrontPulling:
        return AppColors.statusSuccess;
      case TvCameraExposureSource.mountainAttack:
        return AppColors.amberWarning;
      case TvCameraExposureSource.podiumCeremony:
        return AppColors.goldAccent;
      case TvCameraExposureSource.sprintFinish:
        return AppColors.primaryAccent;
      case TvCameraExposureSource.leaderJerseySpotlight:
        return AppColors.cyanAccent;
    }
  }

  String _formatDuration(double seconds) {
    final totalSec = math.max(0, seconds.round());
    final hours = totalSec ~/ 3600;
    final minutes = (totalSec % 3600) ~/ 60;
    final secs = totalSec % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours}h ${mm}m ${ss}s';
    }
    return '${mm}m ${ss}s';
  }

  void _handleSourceTap(TvCameraExposureSource source) {
    if (!widget.isActionEnabled) return;
    setState(() {
      _selectedSource = _selectedSource == source ? null : source;
    });
    widget.onSourceSelected?.call(_selectedSource);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final isWide = constraints.maxWidth >= 960;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 16),
              _buildKpiSummaryRow(isCompact, isWide),
              const SizedBox(height: 16),
              _buildSourceBreakdownList(isWide),
              if (widget.report.topExposedRiderName != null) ...[
                const SizedBox(height: 12),
                _buildTopRiderFooter(isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final sponsorBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
      ),
      child: Text(
        widget.report.sponsorName.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.goldAccent,
        ),
      ),
    );

    final resetButton = widget.onResetPressed == null
        ? const SizedBox.shrink()
        : FocusableActionDetector(
            enabled: widget.isActionEnabled,
            onShowHoverHighlight: (hovered) {
              setState(() => _isResetHovered = hovered);
            },
            onShowFocusHighlight: (focused) {
              setState(() => _isResetFocused = focused);
            },
            child: GestureDetector(
              onTapDown: widget.isActionEnabled
                  ? (_) => setState(() => _isResetPressed = true)
                  : null,
              onTapUp: widget.isActionEnabled
                  ? (_) => setState(() => _isResetPressed = false)
                  : null,
              onTapCancel: () => setState(() => _isResetPressed = false),
              onTap: widget.isActionEnabled ? widget.onResetPressed : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: !widget.isActionEnabled
                      ? AppColors.surfaceLight.withValues(alpha: 0.4)
                      : _isResetPressed
                          ? AppColors.primaryAccent
                          : _isResetHovered
                              ? AppColors.surfaceLight
                              : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isResetFocused
                        ? AppColors.goldAccent
                        : AppColors.cardBorder,
                    width: _isResetFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  'Resetuj etap',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.isActionEnabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.live_tv_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ekspozycja TV i Ekwiwalent Reklamowy',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              sponsorBadge,
              resetButton,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.live_tv_rounded,
          color: AppColors.goldAccent,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ekspozycja TV i Ekwiwalent Reklamowy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.report.raceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        sponsorBadge,
        if (widget.onResetPressed != null) ...[
          const SizedBox(width: 8),
          resetButton,
        ],
      ],
    );
  }

  Widget _buildKpiSummaryRow(bool isCompact, bool isWide) {
    final aveText =
        '${widget.report.totalAdvertisingValueMillionsEur.toStringAsFixed(2)} M EUR';
    final rawTimeText = _formatDuration(widget.report.totalRawSeconds);
    final budget = widget.annualSponsorBudgetEur;
    final roiValue = (budget != null && budget > 0)
        ? widget.report.totalAdvertisingValueEur / budget
        : null;

    final cards = <Widget>[
      _KpiTile(
        label: 'Ekwiwalent (AVE)',
        value: aveText,
        accentColor: AppColors.goldAccent,
      ),
      _KpiTile(
        label: 'Czas w kamerze TV',
        value: rawTimeText,
        accentColor: AppColors.accentBlue,
      ),
      if (roiValue != null)
        _KpiTile(
          label: 'Udział w budżecie ROI',
          value: '${(roiValue * 100).toStringAsFixed(1)}%',
          accentColor: AppColors.statusSuccess,
        ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildSourceBreakdownList(bool isWide) {
    final entries = TvCameraExposureSource.values
        .map((src) => widget.report.sourceBreakdowns[src])
        .whereType<TvExposureSourceBreakdown>()
        .toList();

    if (isWide && entries.length > 2) {
      final half = (entries.length / 2).ceil();
      final left = entries.sublist(0, half);
      final right = entries.sublist(half);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < left.length; i++) ...[
                  _buildSourceRow(left[i]),
                  if (i < left.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < right.length; i++) ...[
                  _buildSourceRow(right[i]),
                  if (i < right.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          _buildSourceRow(entries[i]),
          if (i < entries.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSourceRow(TvExposureSourceBreakdown item) {
    final isSelected = _selectedSource == item.source;
    final isHovered = _hoveredSource == item.source;
    final isFocused = _focusedSource == item.source;
    final accent = _colorForSource(item.source);
    final progressFactor = (item.sharePercent / 100.0).clamp(0.0, 1.0);

    return FocusableActionDetector(
      enabled: widget.isActionEnabled,
      onShowHoverHighlight: (hovered) {
        setState(() {
          _hoveredSource = hovered ? item.source : null;
        });
      },
      onShowFocusHighlight: (focused) {
        setState(() {
          _focusedSource = focused ? item.source : null;
        });
      },
      child: GestureDetector(
        onTap: widget.isActionEnabled ? () => _handleSourceTap(item.source) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: !widget.isActionEnabled
                ? AppColors.surfaceLight.withValues(alpha: 0.35)
                : isSelected
                    ? AppColors.surfaceLight
                    : isHovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.7)
                        : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accent
                  : isFocused
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
              width: (isSelected || isFocused) ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.source.displayNamePl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isActionEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.rawSeconds.round()}s • ${item.advertisingValueMillionsEur.toStringAsFixed(2)} M€',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 5,
                  child: Stack(
                    children: [
                      Container(color: AppColors.surfaceLight),
                      FractionallySizedBox(
                        widthFactor: progressFactor,
                        child: Container(color: accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRiderFooter(bool isCompact) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.goldAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Największa ekspozycja: ${widget.report.topExposedRiderName}',
              maxLines: isCompact ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
