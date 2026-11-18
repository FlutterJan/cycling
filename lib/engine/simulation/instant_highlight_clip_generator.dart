// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'key_moments_detector.dart';
import 'stage_replay_recorder.dart';

// ============================================================================
// 1. ENUMERACJE TELEWIZYJNEGO GENERATORA SKRÓTÓW 45s
// ============================================================================

/// Rola narracyjna pojedynczego klipu w 45-sekundowym skrócie telewizyjnym.
enum HighlightSegmentRole {
  /// Krótkie otwarcie z zapowiedzią etapu lub błyskiem finału.
  coldOpen,

  /// Zawiązanie ucieczki dnia i kontrola peletonu.
  breakawayStory,

  /// Przełomowy moment taktyczny (wachlarze, ranty, atak zespołu).
  tacticalTurningPoint,

  /// Kluczowa trudność terenowa (góra HC/Cat 1, sektor brukowy).
  keyClimbOrSector,

  /// Dramatyczne zdarzenie (kraksa, defekt lidera, pogoń).
  dramaticIncident,

  /// Kulminacja etapu — ostatni kilometr, sprint lub samotny finisz.
  finalSprintClimax,

  /// Krótka migawka z podium i klasyfikacją generalną.
  podiumOutro;

  String toJson() => name;

  static HighlightSegmentRole fromJson(String value) {
    return HighlightSegmentRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HighlightSegmentRole.tacticalTurningPoint,
    );
  }

  String get label {
    switch (this) {
      case HighlightSegmentRole.coldOpen:
        return 'Otwarcie TV';
      case HighlightSegmentRole.breakawayStory:
        return 'Ucieczka dnia';
      case HighlightSegmentRole.tacticalTurningPoint:
        return 'Zwrot taktyczny';
      case HighlightSegmentRole.keyClimbOrSector:
        return 'Kluczowy sektor';
      case HighlightSegmentRole.dramaticIncident:
        return 'Dramat na trasie';
      case HighlightSegmentRole.finalSprintClimax:
        return 'Finał etapu';
      case HighlightSegmentRole.podiumOutro:
        return 'Podium i GC';
    }
  }

  Color get accentColor {
    switch (this) {
      case HighlightSegmentRole.coldOpen:
        return AppColors.accentBlue;
      case HighlightSegmentRole.breakawayStory:
        return AppColors.statusSuccess;
      case HighlightSegmentRole.tacticalTurningPoint:
        return AppColors.cyanAccent;
      case HighlightSegmentRole.keyClimbOrSector:
        return AppColors.amberWarning;
      case HighlightSegmentRole.dramaticIncident:
        return AppColors.crimsonAlert;
      case HighlightSegmentRole.finalSprintClimax:
        return AppColors.goldAccent;
      case HighlightSegmentRole.podiumOutro:
        return AppColors.primaryAccent;
    }
  }
}

/// Profil kamery telewizyjnej przypisany do ujęcia w skrócie.
enum BroadcastCameraAngle {
  helicopter,
  motoLead,
  finishLineOverhead,
  pelotonBumper,
  teamCarFollow,
  droneTracking;

  String toJson() => name;

  static BroadcastCameraAngle fromJson(String value) {
    return BroadcastCameraAngle.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BroadcastCameraAngle.helicopter,
    );
  }

  String get hudTag {
    switch (this) {
      case BroadcastCameraAngle.helicopter:
        return 'HELI CAM';
      case BroadcastCameraAngle.motoLead:
        return 'MOTO 1';
      case BroadcastCameraAngle.finishLineOverhead:
        return 'META OVERHEAD';
      case BroadcastCameraAngle.pelotonBumper:
        return 'ON-BIKE CAM';
      case BroadcastCameraAngle.teamCarFollow:
        return 'WOZ DS';
      case BroadcastCameraAngle.droneTracking:
        return 'DRON FPV';
    }
  }
}

/// Rodzaj przejścia montażowego między kolejnymi ujęciami.
enum HighlightTransitionType {
  whooshCut,
  crossDissolve,
  wipeGoldBar,
  slamZoom;

  String toJson() => name;

  static HighlightTransitionType fromJson(String value) {
    return HighlightTransitionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => HighlightTransitionType.whooshCut,
    );
  }

  String get label {
    switch (this) {
      case HighlightTransitionType.whooshCut:
        return 'Dynamic Cut';
      case HighlightTransitionType.crossDissolve:
        return 'Dissolve';
      case HighlightTransitionType.wipeGoldBar:
        return 'Gold Wipe';
      case HighlightTransitionType.slamZoom:
        return 'Slam Zoom';
    }
  }
}

/// Kategoria oprawy dźwiękowej na osi czasu skrótu.
enum BroadcastAudioCueMood {
  introSting,
  steadyPulse,
  tensionBuild,
  climaxRoar,
  podiumAnthem;

  String toJson() => name;

  static BroadcastAudioCueMood fromJson(String value) {
    return BroadcastAudioCueMood.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BroadcastAudioCueMood.steadyPulse,
    );
  }

  String get label {
    switch (this) {
      case BroadcastAudioCueMood.introSting:
        return 'Czołówka TV';
      case BroadcastAudioCueMood.steadyPulse:
        return 'Rytm peletonu';
      case BroadcastAudioCueMood.tensionBuild:
        return 'Narastanie napięcia';
      case BroadcastAudioCueMood.climaxRoar:
        return 'Ryki tłumu na mecie';
      case BroadcastAudioCueMood.podiumAnthem:
        return 'Fanfara podium';
    }
  }
}

// ============================================================================
// 2. MODELE DANYCH SKRÓTU TELEWIZYJNEGO
// ============================================================================

/// Dane dolnej belki telewizyjnej (Lower-Third) dla konkretnego klipu.
class HighlightTvLowerThird {
  final String primaryTitle;
  final String secondarySubtitle;
  final String badgeText;
  final double? riderSpeedKmh;
  final int? riderPowerWatts;
  final double? gradientPercent;

  const HighlightTvLowerThird({
    required this.primaryTitle,
    required this.secondarySubtitle,
    required this.badgeText,
    this.riderSpeedKmh,
    this.riderPowerWatts,
    this.gradientPercent,
  });

  Map<String, dynamic> toJson() => {
        'primaryTitle': primaryTitle,
        'secondarySubtitle': secondarySubtitle,
        'badgeText': badgeText,
        'riderSpeedKmh': riderSpeedKmh,
        'riderPowerWatts': riderPowerWatts,
        'gradientPercent': gradientPercent,
      };

  factory HighlightTvLowerThird.fromJson(Map<String, dynamic> json) {
    return HighlightTvLowerThird(
      primaryTitle: json['primaryTitle'] as String? ?? 'PELETON',
      secondarySubtitle: json['secondarySubtitle'] as String? ?? '',
      badgeText: json['badgeText'] as String? ?? 'LIVE',
      riderSpeedKmh: (json['riderSpeedKmh'] as num?)?.toDouble(),
      riderPowerWatts: (json['riderPowerWatts'] as num?)?.toInt(),
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble(),
    );
  }
}

/// Punkt wskazówki dźwiękowej i intensywności emocjonalnej w trakcie 45s.
class BroadcastPacingCue {
  final double timelineSecond;
  final double excitementLevel;
  final BroadcastAudioCueMood mood;

  const BroadcastPacingCue({
    required this.timelineSecond,
    required this.excitementLevel,
    required this.mood,
  });

  Map<String, dynamic> toJson() => {
        'timelineSecond': timelineSecond,
        'excitementLevel': excitementLevel,
        'mood': mood.toJson(),
      };

  factory BroadcastPacingCue.fromJson(Map<String, dynamic> json) {
    return BroadcastPacingCue(
      timelineSecond: (json['timelineSecond'] as num?)?.toDouble() ?? 0.0,
      excitementLevel: (json['excitementLevel'] as num?)?.toDouble() ?? 0.5,
      mood: BroadcastAudioCueMood.fromJson(
        json['mood'] as String? ?? BroadcastAudioCueMood.steadyPulse.name,
      ),
    );
  }
}

/// Pojedyncze zmontowane ujęcie wchodzące w skład 45-sekundowego skrótu.
class HighlightClipSegment {
  final String id;
  final int orderIndex;
  final HighlightSegmentRole role;
  final BroadcastCameraAngle cameraAngle;
  final HighlightTransitionType transitionIn;
  final String title;
  final String commentaryLine;
  final String commentaryTag;
  final double kilometerMark;
  final double remainingKm;
  final double stageTimestampSeconds;
  final double startTimelineSecond;
  final double endTimelineSecond;
  final double dramaScore;
  final double gradientPercent;
  final bool hasCobbles;
  final String? featuredRiderId;
  final String? featuredRiderName;
  final HighlightTvLowerThird lowerThird;
  final List<ReplayFrameSnapshot> sourceFrames;

  const HighlightClipSegment({
    required this.id,
    required this.orderIndex,
    required this.role,
    required this.cameraAngle,
    required this.transitionIn,
    required this.title,
    required this.commentaryLine,
    required this.commentaryTag,
    required this.kilometerMark,
    required this.remainingKm,
    required this.stageTimestampSeconds,
    required this.startTimelineSecond,
    required this.endTimelineSecond,
    required this.dramaScore,
    this.gradientPercent = 0.0,
    this.hasCobbles = false,
    this.featuredRiderId,
    this.featuredRiderName,
    required this.lowerThird,
    this.sourceFrames = const [],
  });

  double get durationSeconds =>
      math.max(0.0, endTimelineSecond - startTimelineSecond);

  String get formattedTimelineWindow =>
      '${_formatSec(startTimelineSecond)} - ${_formatSec(endTimelineSecond)}';

  static String _formatSec(double value) {
    final total = value.round().clamp(0, 3599);
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  HighlightClipSegment copyWith({
    int? orderIndex,
    double? startTimelineSecond,
    double? endTimelineSecond,
  }) {
    return HighlightClipSegment(
      id: id,
      orderIndex: orderIndex ?? this.orderIndex,
      role: role,
      cameraAngle: cameraAngle,
      transitionIn: transitionIn,
      title: title,
      commentaryLine: commentaryLine,
      commentaryTag: commentaryTag,
      kilometerMark: kilometerMark,
      remainingKm: remainingKm,
      stageTimestampSeconds: stageTimestampSeconds,
      startTimelineSecond: startTimelineSecond ?? this.startTimelineSecond,
      endTimelineSecond: endTimelineSecond ?? this.endTimelineSecond,
      dramaScore: dramaScore,
      gradientPercent: gradientPercent,
      hasCobbles: hasCobbles,
      featuredRiderId: featuredRiderId,
      featuredRiderName: featuredRiderName,
      lowerThird: lowerThird,
      sourceFrames: sourceFrames,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderIndex': orderIndex,
        'role': role.toJson(),
        'cameraAngle': cameraAngle.toJson(),
        'transitionIn': transitionIn.toJson(),
        'title': title,
        'commentaryLine': commentaryLine,
        'commentaryTag': commentaryTag,
        'kilometerMark': kilometerMark,
        'remainingKm': remainingKm,
        'stageTimestampSeconds': stageTimestampSeconds,
        'startTimelineSecond': startTimelineSecond,
        'endTimelineSecond': endTimelineSecond,
        'dramaScore': dramaScore,
        'gradientPercent': gradientPercent,
        'hasCobbles': hasCobbles,
        'featuredRiderId': featuredRiderId,
        'featuredRiderName': featuredRiderName,
        'lowerThird': lowerThird.toJson(),
      };

  factory HighlightClipSegment.fromJson(Map<String, dynamic> json) {
    return HighlightClipSegment(
      id: json['id'] as String? ?? 'seg_0',
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      role: HighlightSegmentRole.fromJson(
        json['role'] as String? ?? HighlightSegmentRole.tacticalTurningPoint.name,
      ),
      cameraAngle: BroadcastCameraAngle.fromJson(
        json['cameraAngle'] as String? ?? BroadcastCameraAngle.helicopter.name,
      ),
      transitionIn: HighlightTransitionType.fromJson(
        json['transitionIn'] as String? ?? HighlightTransitionType.whooshCut.name,
      ),
      title: json['title'] as String? ?? 'Kluczowy moment',
      commentaryLine: json['commentaryLine'] as String? ?? '',
      commentaryTag: json['commentaryTag'] as String? ?? 'HIGHLIGHT',
      kilometerMark: (json['kilometerMark'] as num?)?.toDouble() ?? 0.0,
      remainingKm: (json['remainingKm'] as num?)?.toDouble() ?? 0.0,
      stageTimestampSeconds:
          (json['stageTimestampSeconds'] as num?)?.toDouble() ?? 0.0,
      startTimelineSecond:
          (json['startTimelineSecond'] as num?)?.toDouble() ?? 0.0,
      endTimelineSecond:
          (json['endTimelineSecond'] as num?)?.toDouble() ?? 5.0,
      dramaScore: (json['dramaScore'] as num?)?.toDouble() ?? 50.0,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      hasCobbles: json['hasCobbles'] as bool? ?? false,
      featuredRiderId: json['featuredRiderId'] as String?,
      featuredRiderName: json['featuredRiderName'] as String?,
      lowerThird: HighlightTvLowerThird.fromJson(
        (json['lowerThird'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

/// Kandydat na ujęcie przekazywany bezpośrednio do generatora skrótów.
class HighlightCandidateMoment {
  final String id;
  final HighlightSegmentRole role;
  final String title;
  final String description;
  final double kilometerMark;
  final double stageTimestampSeconds;
  final double baseDramaScore;
  final BroadcastCameraAngle preferredCamera;
  final double gradientPercent;
  final bool hasCobbles;
  final String? riderId;
  final String? riderName;
  final double? riderSpeedKmh;
  final int? riderPowerWatts;
  final List<ReplayFrameSnapshot> frames;

  const HighlightCandidateMoment({
    required this.id,
    required this.role,
    required this.title,
    required this.description,
    required this.kilometerMark,
    required this.stageTimestampSeconds,
    required this.baseDramaScore,
    this.preferredCamera = BroadcastCameraAngle.helicopter,
    this.gradientPercent = 0.0,
    this.hasCobbles = false,
    this.riderId,
    this.riderName,
    this.riderSpeedKmh,
    this.riderPowerWatts,
    this.frames = const [],
  });
}

/// Konfiguracja montażu automatycznego skrótu telewizyjnego.
class HighlightGeneratorConfig {
  /// Docelowa długość skrótu telewizyjnego (domyślnie dokładnie 45.0 s).
  final double targetTotalDurationSeconds;

  /// Maksymalna liczba zmontowanych segmentów w jednym skrócie.
  final int maxSegmentsCount;

  /// Minimalna odległość w kilometrach między kolejnymi ujęciami (deduplikacja).
  final double minKilometerSeparation;

  /// Czy dołączać krótką czołówkę otwarcia oraz planszę podium.
  final bool includeBroadcastBookends;

  /// Nazwa stacji / przekazu TV wyświetlana w rogu ekranu.
  final String broadcastNetworkName;

  const HighlightGeneratorConfig({
    this.targetTotalDurationSeconds = 45.0,
    this.maxSegmentsCount = 7,
    this.minKilometerSeparation = 1.5,
    this.includeBroadcastBookends = true,
    this.broadcastNetworkName = 'EUROSPORT HD • WORLD FEED',
  });
}

/// Kompletny, wygenerowany 45-sekundowy skrót telewizyjny z etapu.
class InstantHighlightReel {
  final String reelId;
  final String stageId;
  final String raceName;
  final String stageName;
  final int stageNumber;
  final double stageDistanceKm;
  final String stageTypeLabel;
  final String winnerName;
  final String winnerTeamName;
  final String gcLeaderName;
  final String broadcastNetworkName;
  final double totalDurationSeconds;
  final double averageDramaScore;
  final DateTime generatedAt;
  final List<HighlightClipSegment> segments;
  final List<BroadcastPacingCue> pacingCurve;

  const InstantHighlightReel({
    required this.reelId,
    required this.stageId,
    required this.raceName,
    required this.stageName,
    required this.stageNumber,
    required this.stageDistanceKm,
    required this.stageTypeLabel,
    required this.winnerName,
    required this.winnerTeamName,
    required this.gcLeaderName,
    required this.broadcastNetworkName,
    required this.totalDurationSeconds,
    required this.averageDramaScore,
    required this.generatedAt,
    required this.segments,
    required this.pacingCurve,
  });

  bool get isEmpty => segments.isEmpty;

  /// Zwraca segment aktywny dla podanej sekundy odtwarzania.
  HighlightClipSegment? segmentAt(double timelineSeconds) {
    if (segments.isEmpty) return null;
    final clamped = timelineSeconds.clamp(0.0, totalDurationSeconds);
    for (final segment in segments) {
      if (clamped >= segment.startTimelineSecond &&
          clamped <= segment.endTimelineSecond) {
        return segment;
      }
    }
    return segments.last;
  }

  /// Eksportuje czytelny skrypt montażowy (EDL / scenariusz lektora).
  String exportBroadcastScriptSummary() {
    final buffer = StringBuffer();
    buffer.writeln(
      '=== $broadcastNetworkName | SKRÓT ETAPU $stageNumber: $stageName ===',
    );
    buffer.writeln(
      'Wyścig: $raceName (${stageDistanceKm.toStringAsFixed(1)} km) | Zwycięzca: $winnerName ($winnerTeamName)',
    );
    buffer.writeln(
      'Czas całkowity: ${totalDurationSeconds.toStringAsFixed(1)}s | Śr. dramatyzm: ${averageDramaScore.toStringAsFixed(0)}/100',
    );
    buffer.writeln('---');
    for (final seg in segments) {
      buffer.writeln(
        '[${seg.formattedTimelineWindow}] (${seg.durationSeconds.toStringAsFixed(1)}s) '
        '[${seg.cameraAngle.hudTag}] KM ${seg.kilometerMark.toStringAsFixed(1)} — ${seg.title}',
      );
      buffer.writeln('  Lektor: "${seg.commentaryLine}"');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'reelId': reelId,
        'stageId': stageId,
        'raceName': raceName,
        'stageName': stageName,
        'stageNumber': stageNumber,
        'stageDistanceKm': stageDistanceKm,
        'stageTypeLabel': stageTypeLabel,
        'winnerName': winnerName,
        'winnerTeamName': winnerTeamName,
        'gcLeaderName': gcLeaderName,
        'broadcastNetworkName': broadcastNetworkName,
        'totalDurationSeconds': totalDurationSeconds,
        'averageDramaScore': averageDramaScore,
        'generatedAt': generatedAt.toIso8601String(),
        'segments': segments.map((s) => s.toJson()).toList(),
        'pacingCurve': pacingCurve.map((p) => p.toJson()).toList(),
      };

  factory InstantHighlightReel.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'] as List<dynamic>? ?? const [];
    final rawPacing = json['pacingCurve'] as List<dynamic>? ?? const [];
    return InstantHighlightReel(
      reelId: json['reelId'] as String? ?? 'reel_0',
      stageId: json['stageId'] as String? ?? 'stage_1',
      raceName: json['raceName'] as String? ?? 'WorldTour',
      stageName: json['stageName'] as String? ?? 'Etap',
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 1,
      stageDistanceKm: (json['stageDistanceKm'] as num?)?.toDouble() ?? 150.0,
      stageTypeLabel: json['stageTypeLabel'] as String? ?? 'Etap płaski',
      winnerName: json['winnerName'] as String? ?? 'Zwycięzca etapu',
      winnerTeamName: json['winnerTeamName'] as String? ?? 'Pro Team',
      gcLeaderName: json['gcLeaderName'] as String? ?? 'Lider GC',
      broadcastNetworkName: json['broadcastNetworkName'] as String? ??
          'EUROSPORT HD • WORLD FEED',
      totalDurationSeconds:
          (json['totalDurationSeconds'] as num?)?.toDouble() ?? 45.0,
      averageDramaScore:
          (json['averageDramaScore'] as num?)?.toDouble() ?? 75.0,
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      segments: rawSegments
          .map((e) => HighlightClipSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      pacingCurve: rawPacing
          .map((e) => BroadcastPacingCue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ============================================================================
// 3. SILNIK MONTAŻU AUTOMATYCZNYCH 45-SEKUNDOWYCH SKRÓTÓW
// ============================================================================

/// Silnik reżyserii i montażu automatycznego 45-sekundowego skrótu telewizyjnego
/// na podstawie kluczowych momentów (`KeyMomentsDetector`) oraz klatek (`StageReplayRecorder`).
class InstantHighlightClipGenerator {
  final HighlightGeneratorConfig config;

  const InstantHighlightClipGenerator({
    this.config = const HighlightGeneratorConfig(),
  });

  /// Generuje kompletny 45-sekundowy skrót telewizyjny po zakończeniu etapu.
  InstantHighlightReel generatePostStageReel({
    required String stageId,
    required String raceName,
    required String stageName,
    required int stageNumber,
    required double stageDistanceKm,
    required String stageTypeLabel,
    required String winnerName,
    required String winnerTeamName,
    required String gcLeaderName,
    List<KeyMomentTrigger> keyMoments = const [],
    List<ReplayClip> replayClips = const [],
    List<ReplayFrameSnapshot> finalKilometerFrames = const [],
    List<HighlightCandidateMoment> customCandidates = const [],
    DateTime? generatedAt,
  }) {
    final safeDistance = math.max(1.0, stageDistanceKm);
    final candidates = <HighlightCandidateMoment>[
      ...customCandidates,
      ..._convertKeyMoments(keyMoments, safeDistance),
      ..._convertReplayClips(replayClips, safeDistance),
    ];

    if (finalKilometerFrames.isNotEmpty) {
      candidates.add(
        _buildFinalKmCandidateFromFrames(
          frames: finalKilometerFrames,
          stageDistanceKm: safeDistance,
          winnerName: winnerName,
        ),
      );
    }

    // Jeśli brak jakichkolwiek zdarzeń (np. spokojny etap symulowany ekspresowo),
    // budujemy bazowy zestaw narracyjny z otwarcia, ucieczki i finiszu.
    if (candidates.isEmpty) {
      candidates.addAll(
        _buildFallbackNarrativeCandidates(
          stageDistanceKm: safeDistance,
          stageName: stageName,
          winnerName: winnerName,
          gcLeaderName: gcLeaderName,
        ),
      );
    }

    final deduplicated = _deduplicateCandidates(
      candidates,
      minKmGap: config.minKilometerSeparation,
    );

    final selected = _selectEditorialLineup(
      deduplicated: deduplicated,
      stageDistanceKm: safeDistance,
      stageName: stageName,
      winnerName: winnerName,
      winnerTeamName: winnerTeamName,
      gcLeaderName: gcLeaderName,
    );

    final timedSegments = _allocateExactTimeBudget(
      candidates: selected,
      targetSeconds: config.targetTotalDurationSeconds,
      stageDistanceKm: safeDistance,
      winnerName: winnerName,
      winnerTeamName: winnerTeamName,
      gcLeaderName: gcLeaderName,
    );

    final totalDuration = timedSegments.isEmpty
        ? config.targetTotalDurationSeconds
        : timedSegments.last.endTimelineSecond;

    final avgDrama = timedSegments.isEmpty
        ? 0.0
        : timedSegments.fold<double>(0.0, (sum, s) => sum + s.dramaScore) /
            timedSegments.length;

    final pacing = _buildPacingCurve(timedSegments);

    return InstantHighlightReel(
      reelId: 'reel_${stageId}_${(generatedAt ?? DateTime.now()).millisecondsSinceEpoch}',
      stageId: stageId,
      raceName: raceName,
      stageName: stageName,
      stageNumber: stageNumber,
      stageDistanceKm: safeDistance,
      stageTypeLabel: stageTypeLabel,
      winnerName: winnerName,
      winnerTeamName: winnerTeamName,
      gcLeaderName: gcLeaderName,
      broadcastNetworkName: config.broadcastNetworkName,
      totalDurationSeconds: totalDuration,
      averageDramaScore: avgDrama,
      generatedAt: generatedAt ?? DateTime.now(),
      segments: timedSegments,
      pacingCurve: pacing,
    );
  }

  List<HighlightCandidateMoment> _convertKeyMoments(
    List<KeyMomentTrigger> triggers,
    double stageDistanceKm,
  ) {
    final result = <HighlightCandidateMoment>[];
    for (var i = 0; i < triggers.length; i++) {
      final t = triggers[i];
      final role = _mapKeyMomentRole(t.type);
      final drama = _scoreKeyMoment(t.type);
      final camera = _mapCameraString(t.recommendedCameraMode, role);
      result.add(
        HighlightCandidateMoment(
          id: 'km_${i}_${t.triggerKey}',
          role: role,
          title: t.title,
          description: t.description,
          kilometerMark: t.kilometerMark.clamp(0.0, stageDistanceKm),
          stageTimestampSeconds: (t.kilometerMark / 42.0) * 3600.0,
          baseDramaScore: drama,
          preferredCamera: camera,
          hasCobbles: t.type == KeyMomentType.challengingCobbles,
          gradientPercent: t.type == KeyMomentType.decisiveClimb ||
                  t.type == KeyMomentType.gcLeaderAttack
              ? 8.4
              : 0.8,
          riderId: t.relatedRiderId,
          riderName: t.relatedRiderName,
        ),
      );
    }
    return result;
  }

  List<HighlightCandidateMoment> _convertReplayClips(
    List<ReplayClip> clips,
    double stageDistanceKm,
  ) {
    final result = <HighlightCandidateMoment>[];
    for (final clip in clips) {
      if (clip.frames.isEmpty && clip.endDistanceKm <= 0) continue;
      final role = _mapReplayClipRole(clip.type);
      final midFrame =
          clip.frames.isNotEmpty ? clip.frames[clip.frames.length ~/ 2] : null;
      final leadRider =
          midFrame != null && midFrame.riders.isNotEmpty ? midFrame.riders.first : null;
      result.add(
        HighlightCandidateMoment(
          id: 'rc_${clip.id}',
          role: role,
          title: clip.title,
          description: clip.description,
          kilometerMark: clip.endDistanceKm.clamp(0.0, stageDistanceKm),
          stageTimestampSeconds: clip.startTimestampSeconds,
          baseDramaScore: _scoreReplayClip(clip.type),
          preferredCamera: role == HighlightSegmentRole.finalSprintClimax
              ? BroadcastCameraAngle.finishLineOverhead
              : BroadcastCameraAngle.motoLead,
          gradientPercent: midFrame?.currentGradientPercent ?? 0.0,
          hasCobbles: clip.type == ReplayClipType.cobbleSector,
          riderId: leadRider?.riderId,
          riderName: midFrame?.leadRiderName,
          riderSpeedKmh: leadRider?.speedKmh,
          riderPowerWatts: leadRider?.powerWatts,
          frames: clip.frames,
        ),
      );
    }
    return result;
  }

  HighlightCandidateMoment _buildFinalKmCandidateFromFrames({
    required List<ReplayFrameSnapshot> frames,
    required double stageDistanceKm,
    required String winnerName,
  }) {
    final last = frames.last;
    final topRider = last.riders.isNotEmpty ? last.riders.first : null;
    return HighlightCandidateMoment(
      id: 'final_km_frames',
      role: HighlightSegmentRole.finalSprintClimax,
      title: 'Ostatni kilometr — Walka o zwycięstwo',
      description:
          '$winnerName rozstrzyga losy etapu na finałowej prostej przy ogromnej prędkości.',
      kilometerMark: stageDistanceKm,
      stageTimestampSeconds: last.timestampSeconds,
      baseDramaScore: 98.0,
      preferredCamera: BroadcastCameraAngle.finishLineOverhead,
      gradientPercent: last.currentGradientPercent,
      riderId: topRider?.riderId,
      riderName: winnerName,
      riderSpeedKmh: topRider?.speedKmh ?? 66.4,
      riderPowerWatts: topRider?.powerWatts ?? 1180,
      frames: frames,
    );
  }

  List<HighlightCandidateMoment> _buildFallbackNarrativeCandidates({
    required double stageDistanceKm,
    required String stageName,
    required String winnerName,
    required String gcLeaderName,
  }) {
    return [
      HighlightCandidateMoment(
        id: 'fallback_breakaway',
        role: HighlightSegmentRole.breakawayStory,
        title: 'Zawiązanie ucieczki dnia',
        description:
            'Pierwsze kilometry etapu $stageName przynoszą szybki odjazd śmiałków.',
        kilometerMark: math.min(stageDistanceKm * 0.12, 18.0),
        stageTimestampSeconds: 1250.0,
        baseDramaScore: 62.0,
        preferredCamera: BroadcastCameraAngle.helicopter,
        riderSpeedKmh: 46.2,
      ),
      HighlightCandidateMoment(
        id: 'fallback_tempo',
        role: HighlightSegmentRole.tacticalTurningPoint,
        title: 'Peleton podkręca tempo przed finałem',
        description:
            'Drużyny faworytów ustawiają pociągi na czele grupy zasadniczej.',
        kilometerMark: stageDistanceKm * 0.78,
        stageTimestampSeconds: 11200.0,
        baseDramaScore: 76.0,
        preferredCamera: BroadcastCameraAngle.motoLead,
        riderName: gcLeaderName,
        riderSpeedKmh: 51.8,
      ),
      HighlightCandidateMoment(
        id: 'fallback_finish',
        role: HighlightSegmentRole.finalSprintClimax,
        title: 'Finisz etapu — Triumf $winnerName',
        description:
            '$winnerName przekracza linię mety jako pierwszy po pasjonującej końcówce.',
        kilometerMark: stageDistanceKm,
        stageTimestampSeconds: 14800.0,
        baseDramaScore: 96.0,
        preferredCamera: BroadcastCameraAngle.finishLineOverhead,
        riderName: winnerName,
        riderSpeedKmh: 65.5,
        riderPowerWatts: 1140,
      ),
    ];
  }

  List<HighlightCandidateMoment> _deduplicateCandidates(
    List<HighlightCandidateMoment> raw, {
    required double minKmGap,
  }) {
    // Sortujemy od najwyższego dramatyzmu, aby w razie nakładania zachować lepsze ujęcie.
    final sortedByDrama = List<HighlightCandidateMoment>.from(raw)
      ..sort((a, b) => b.baseDramaScore.compareTo(a.baseDramaScore));

    final kept = <HighlightCandidateMoment>[];
    for (final candidate in sortedByDrama) {
      final hasConflict = kept.any(
        (existing) =>
            existing.role == candidate.role &&
            (existing.kilometerMark - candidate.kilometerMark).abs() < minKmGap,
      );
      if (!hasConflict) {
        kept.add(candidate);
      }
    }

    // Przywracamy chronologiczny porządek etapu.
    kept.sort((a, b) => a.kilometerMark.compareTo(b.kilometerMark));
    return kept;
  }

  List<HighlightCandidateMoment> _selectEditorialLineup({
    required List<HighlightCandidateMoment> deduplicated,
    required double stageDistanceKm,
    required String stageName,
    required String winnerName,
    required String winnerTeamName,
    required String gcLeaderName,
  }) {
    final maxMiddle =
        math.max(2, config.maxSegmentsCount - (config.includeBroadcastBookends ? 2 : 0));

    final middlePool = deduplicated
        .where(
          (c) =>
              c.role != HighlightSegmentRole.coldOpen &&
              c.role != HighlightSegmentRole.podiumOutro,
        )
        .toList();

    // Upewniamy się, że mamy kulminację finałową.
    final hasClimax = middlePool.any(
      (c) => c.role == HighlightSegmentRole.finalSprintClimax,
    );
    if (!hasClimax) {
      middlePool.add(
        HighlightCandidateMoment(
          id: 'auto_climax',
          role: HighlightSegmentRole.finalSprintClimax,
          title: 'Finałowy kilometr — Zwycięstwo $winnerName',
          description:
              '$winnerName ($winnerTeamName) wygrywa etap $stageName na ostatnich metrach.',
          kilometerMark: stageDistanceKm,
          stageTimestampSeconds: 14400.0,
          baseDramaScore: 97.0,
          preferredCamera: BroadcastCameraAngle.finishLineOverhead,
          riderName: winnerName,
          riderSpeedKmh: 64.8,
          riderPowerWatts: 1120,
        ),
      );
    }

    // Wybieramy top N według dramatyzmu, a następnie układamy chronologicznie.
    middlePool.sort((a, b) => b.baseDramaScore.compareTo(a.baseDramaScore));
    final chosenMiddle = middlePool.take(maxMiddle).toList()
      ..sort((a, b) => a.kilometerMark.compareTo(b.kilometerMark));

    if (!config.includeBroadcastBookends) {
      return chosenMiddle;
    }

    final coldOpen = HighlightCandidateMoment(
      id: 'bookend_cold_open',
      role: HighlightSegmentRole.coldOpen,
      title: 'Czołówka transmisji: $stageName',
      description:
          'Najważniejsze emocje etapu o długości ${stageDistanceKm.toStringAsFixed(1)} km w 45 sekund.',
      kilometerMark: 0.0,
      stageTimestampSeconds: 0.0,
      baseDramaScore: 70.0,
      preferredCamera: BroadcastCameraAngle.helicopter,
      riderName: gcLeaderName,
    );

    final podiumOutro = HighlightCandidateMoment(
      id: 'bookend_podium_outro',
      role: HighlightSegmentRole.podiumOutro,
      title: 'Ceremonia podium i klasyfikacja GC',
      description:
          '$winnerName triumfuje na etapie, a $gcLeaderName broni pozycji lidera klasyfikacji generalnej.',
      kilometerMark: stageDistanceKm,
      stageTimestampSeconds: 15000.0,
      baseDramaScore: 74.0,
      preferredCamera: BroadcastCameraAngle.droneTracking,
      riderName: winnerName,
    );

    return [coldOpen, ...chosenMiddle, podiumOutro];
  }

  List<HighlightClipSegment> _allocateExactTimeBudget({
    required List<HighlightCandidateMoment> candidates,
    required double targetSeconds,
    required double stageDistanceKm,
    required String winnerName,
    required String winnerTeamName,
    required String gcLeaderName,
  }) {
    if (candidates.isEmpty) return const [];

    // Bazowe wagi czasowe gwarantujące dynamiczny rytm TV (finał najdłuższy).
    final rawWeights = candidates.map((c) {
      switch (c.role) {
        case HighlightSegmentRole.coldOpen:
          return 4.0;
        case HighlightSegmentRole.breakawayStory:
          return 5.5;
        case HighlightSegmentRole.tacticalTurningPoint:
          return 6.5;
        case HighlightSegmentRole.keyClimbOrSector:
          return 7.5;
        case HighlightSegmentRole.dramaticIncident:
          return 7.0;
        case HighlightSegmentRole.finalSprintClimax:
          return 11.5;
        case HighlightSegmentRole.podiumOutro:
          return 4.5;
      }
    }).toList();

    final weightSum = rawWeights.fold<double>(0.0, (sum, w) => sum + w);
    final scale = weightSum > 0 ? targetSeconds / weightSum : 1.0;

    final segments = <HighlightClipSegment>[];
    var cursor = 0.0;

    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      final isLast = i == candidates.length - 1;
      final duration = isLast
          ? math.max(1.0, targetSeconds - cursor)
          : double.parse((rawWeights[i] * scale).toStringAsFixed(2));
      final end = isLast ? targetSeconds : cursor + duration;

      final remainingKm = math.max(0.0, stageDistanceKm - c.kilometerMark);
      final transition = _pickTransition(c.role, i);
      final lowerThird = _buildLowerThird(
        candidate: c,
        remainingKm: remainingKm,
        winnerName: winnerName,
        winnerTeamName: winnerTeamName,
        gcLeaderName: gcLeaderName,
      );

      segments.add(
        HighlightClipSegment(
          id: c.id,
          orderIndex: i,
          role: c.role,
          cameraAngle: c.preferredCamera,
          transitionIn: transition,
          title: c.title,
          commentaryLine: c.description,
          commentaryTag: c.role.label.toUpperCase(),
          kilometerMark: c.kilometerMark,
          remainingKm: remainingKm,
          stageTimestampSeconds: c.stageTimestampSeconds,
          startTimelineSecond: double.parse(cursor.toStringAsFixed(2)),
          endTimelineSecond: double.parse(end.toStringAsFixed(2)),
          dramaScore: c.baseDramaScore.clamp(0.0, 100.0),
          gradientPercent: c.gradientPercent,
          hasCobbles: c.hasCobbles,
          featuredRiderId: c.riderId,
          featuredRiderName: c.riderName,
          lowerThird: lowerThird,
          sourceFrames: c.frames,
        ),
      );
      cursor = end;
    }

    return segments;
  }

  HighlightTvLowerThird _buildLowerThird({
    required HighlightCandidateMoment candidate,
    required double remainingKm,
    required String winnerName,
    required String winnerTeamName,
    required String gcLeaderName,
  }) {
    final riderLabel = candidate.riderName ??
        (candidate.role == HighlightSegmentRole.podiumOutro
            ? winnerName
            : gcLeaderName);

    final badge = candidate.role == HighlightSegmentRole.finalSprintClimax
        ? 'META'
        : candidate.role == HighlightSegmentRole.coldOpen
            ? 'INTRO'
            : '${remainingKm.toStringAsFixed(1)} KM DO METY';

    final subtitle = candidate.role == HighlightSegmentRole.podiumOutro
        ? '$winnerTeamName • Zwycięzca etapu'
        : candidate.title;

    return HighlightTvLowerThird(
      primaryTitle: riderLabel.toUpperCase(),
      secondarySubtitle: subtitle,
      badgeText: badge,
      riderSpeedKmh: candidate.riderSpeedKmh,
      riderPowerWatts: candidate.riderPowerWatts,
      gradientPercent:
          candidate.gradientPercent.abs() >= 1.5 ? candidate.gradientPercent : null,
    );
  }

  List<BroadcastPacingCue> _buildPacingCurve(
    List<HighlightClipSegment> segments,
  ) {
    final cues = <BroadcastPacingCue>[];
    for (final seg in segments) {
      final mood = switch (seg.role) {
        HighlightSegmentRole.coldOpen => BroadcastAudioCueMood.introSting,
        HighlightSegmentRole.breakawayStory => BroadcastAudioCueMood.steadyPulse,
        HighlightSegmentRole.tacticalTurningPoint =>
          BroadcastAudioCueMood.tensionBuild,
        HighlightSegmentRole.keyClimbOrSector =>
          BroadcastAudioCueMood.tensionBuild,
        HighlightSegmentRole.dramaticIncident =>
          BroadcastAudioCueMood.tensionBuild,
        HighlightSegmentRole.finalSprintClimax =>
          BroadcastAudioCueMood.climaxRoar,
        HighlightSegmentRole.podiumOutro => BroadcastAudioCueMood.podiumAnthem,
      };
      cues.add(
        BroadcastPacingCue(
          timelineSecond: seg.startTimelineSecond,
          excitementLevel: (seg.dramaScore / 100.0).clamp(0.2, 1.0),
          mood: mood,
        ),
      );
    }
    return cues;
  }

  HighlightSegmentRole _mapKeyMomentRole(KeyMomentType type) {
    switch (type) {
      case KeyMomentType.breakawayFormation:
        return HighlightSegmentRole.breakawayStory;
      case KeyMomentType.challengingCobbles:
      case KeyMomentType.decisiveClimb:
        return HighlightSegmentRole.keyClimbOrSector;
      case KeyMomentType.severeCrosswindEchelon:
      case KeyMomentType.gcLeaderAttack:
        return HighlightSegmentRole.tacticalTurningPoint;
      case KeyMomentType.playerRiderIncident:
        return HighlightSegmentRole.dramaticIncident;
      case KeyMomentType.finaleFinal5Km:
        return HighlightSegmentRole.finalSprintClimax;
    }
  }

  HighlightSegmentRole _mapReplayClipRole(ReplayClipType type) {
    switch (type) {
      case ReplayClipType.finalKilometer:
        return HighlightSegmentRole.finalSprintClimax;
      case ReplayClipType.gcAttack:
      case ReplayClipType.echelonAttack:
        return HighlightSegmentRole.tacticalTurningPoint;
      case ReplayClipType.cobbleSector:
        return HighlightSegmentRole.keyClimbOrSector;
      case ReplayClipType.incident:
        return HighlightSegmentRole.dramaticIncident;
    }
  }

  double _scoreKeyMoment(KeyMomentType type) {
    switch (type) {
      case KeyMomentType.breakawayFormation:
        return 60.0;
      case KeyMomentType.challengingCobbles:
        return 82.0;
      case KeyMomentType.severeCrosswindEchelon:
        return 84.0;
      case KeyMomentType.gcLeaderAttack:
        return 90.0;
      case KeyMomentType.decisiveClimb:
        return 83.0;
      case KeyMomentType.playerRiderIncident:
        return 87.0;
      case KeyMomentType.finaleFinal5Km:
        return 94.0;
    }
  }

  double _scoreReplayClip(ReplayClipType type) {
    switch (type) {
      case ReplayClipType.finalKilometer:
        return 99.0;
      case ReplayClipType.gcAttack:
        return 91.0;
      case ReplayClipType.echelonAttack:
        return 85.0;
      case ReplayClipType.cobbleSector:
        return 82.0;
      case ReplayClipType.incident:
        return 88.0;
    }
  }

  BroadcastCameraAngle _mapCameraString(
    String rawMode,
    HighlightSegmentRole role,
  ) {
    final normalized = rawMode.toLowerCase();
    if (normalized.contains('heli')) return BroadcastCameraAngle.helicopter;
    if (normalized.contains('moto')) return BroadcastCameraAngle.motoLead;
    if (normalized.contains('cockpit')) {
      return BroadcastCameraAngle.pelotonBumper;
    }
    if (normalized.contains('team')) return BroadcastCameraAngle.teamCarFollow;
    if (role == HighlightSegmentRole.finalSprintClimax) {
      return BroadcastCameraAngle.finishLineOverhead;
    }
    return BroadcastCameraAngle.helicopter;
  }

  HighlightTransitionType _pickTransition(
    HighlightSegmentRole role,
    int index,
  ) {
    if (index == 0) return HighlightTransitionType.crossDissolve;
    switch (role) {
      case HighlightSegmentRole.finalSprintClimax:
        return HighlightTransitionType.slamZoom;
      case HighlightSegmentRole.podiumOutro:
        return HighlightTransitionType.wipeGoldBar;
      case HighlightSegmentRole.coldOpen:
        return HighlightTransitionType.crossDissolve;
      default:
        return HighlightTransitionType.whooshCut;
    }
  }
}

// ============================================================================
// 4. ZARZĄDZANIE STANEM RIVERPOD
// ============================================================================

/// Stan odtwarzacza i generatora 45-sekundowych skrótów po etapie.
class InstantHighlightClipGeneratorState {
  final InstantHighlightReel? reel;
  final bool isGenerating;
  final bool isPlaying;
  final double playbackPositionSeconds;
  final double playbackSpeed;
  final bool showTvGraphics;
  final bool isMuted;
  final String? lastActionMessage;
  final String? errorMessage;

  const InstantHighlightClipGeneratorState({
    this.reel,
    this.isGenerating = false,
    this.isPlaying = false,
    this.playbackPositionSeconds = 0.0,
    this.playbackSpeed = 1.0,
    this.showTvGraphics = true,
    this.isMuted = false,
    this.lastActionMessage,
    this.errorMessage,
  });

  bool get hasReel => reel != null && !reel!.isEmpty;

  HighlightClipSegment? get activeSegment =>
      reel?.segmentAt(playbackPositionSeconds);

  double get totalDurationSeconds => reel?.totalDurationSeconds ?? 45.0;

  double get normalizedProgress => totalDurationSeconds > 0
      ? (playbackPositionSeconds / totalDurationSeconds).clamp(0.0, 1.0)
      : 0.0;

  InstantHighlightClipGeneratorState copyWith({
    InstantHighlightReel? reel,
    bool clearReel = false,
    bool? isGenerating,
    bool? isPlaying,
    double? playbackPositionSeconds,
    double? playbackSpeed,
    bool? showTvGraphics,
    bool? isMuted,
    String? lastActionMessage,
    bool clearLastActionMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return InstantHighlightClipGeneratorState(
      reel: clearReel ? null : (reel ?? this.reel),
      isGenerating: isGenerating ?? this.isGenerating,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackPositionSeconds:
          playbackPositionSeconds ?? this.playbackPositionSeconds,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      showTvGraphics: showTvGraphics ?? this.showTvGraphics,
      isMuted: isMuted ?? this.isMuted,
      lastActionMessage: clearLastActionMessage
          ? null
          : (lastActionMessage ?? this.lastActionMessage),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Kontroler Riverpod zarządzający montażem i odtwarzaniem skrótu 45s.
class InstantHighlightClipGeneratorNotifier
    extends StateNotifier<InstantHighlightClipGeneratorState> {
  final InstantHighlightClipGenerator _generator;
  Timer? _playbackTimer;

  InstantHighlightClipGeneratorNotifier({
    InstantHighlightClipGenerator? generator,
  })  : _generator = generator ?? const InstantHighlightClipGenerator(),
        super(const InstantHighlightClipGeneratorState());

  /// Generuje nowy 45-sekundowy skrót telewizyjny z danych etapu.
  void generateFromStageData({
    required String stageId,
    required String raceName,
    required String stageName,
    required int stageNumber,
    required double stageDistanceKm,
    required String stageTypeLabel,
    required String winnerName,
    required String winnerTeamName,
    required String gcLeaderName,
    List<KeyMomentTrigger> keyMoments = const [],
    List<ReplayClip> replayClips = const [],
    List<ReplayFrameSnapshot> finalKilometerFrames = const [],
    List<HighlightCandidateMoment> customCandidates = const [],
    bool autoPlay = false,
  }) {
    stop();
    state = state.copyWith(
      isGenerating: true,
      clearErrorMessage: true,
      clearLastActionMessage: true,
    );

    final reel = _generator.generatePostStageReel(
      stageId: stageId,
      raceName: raceName,
      stageName: stageName,
      stageNumber: stageNumber,
      stageDistanceKm: stageDistanceKm,
      stageTypeLabel: stageTypeLabel,
      winnerName: winnerName,
      winnerTeamName: winnerTeamName,
      gcLeaderName: gcLeaderName,
      keyMoments: keyMoments,
      replayClips: replayClips,
      finalKilometerFrames: finalKilometerFrames,
      customCandidates: customCandidates,
    );

    state = state.copyWith(
      reel: reel,
      isGenerating: false,
      playbackPositionSeconds: 0.0,
      lastActionMessage:
          'Zmontowano ${reel.segments.length} ujęć w ${reel.totalDurationSeconds.toStringAsFixed(0)}s skrócie TV.',
    );

    if (autoPlay) {
      play();
    }
  }

  /// Wczytuje gotowy obiekt `InstantHighlightReel`.
  void loadReel(InstantHighlightReel reel) {
    stop();
    state = state.copyWith(
      reel: reel,
      isGenerating: false,
      playbackPositionSeconds: 0.0,
      clearErrorMessage: true,
    );
  }

  void togglePlayPause() {
    if (!state.hasReel) return;
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (!state.hasReel) return;
    if (state.playbackPositionSeconds >= state.totalDurationSeconds) {
      state = state.copyWith(playbackPositionSeconds: 0.0);
    }
    _playbackTimer?.cancel();
    state = state.copyWith(isPlaying: true);
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _onTick(0.05),
    );
  }

  void pause() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }

  void stop() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    state = state.copyWith(
      isPlaying: false,
      playbackPositionSeconds: 0.0,
    );
  }

  void seekTo(double seconds) {
    if (!state.hasReel) return;
    final clamped = seconds.clamp(0.0, state.totalDurationSeconds);
    state = state.copyWith(playbackPositionSeconds: clamped);
  }

  void jumpToSegment(int segmentIndex) {
    final reel = state.reel;
    if (reel == null ||
        segmentIndex < 0 ||
        segmentIndex >= reel.segments.length) {
      return;
    }
    seekTo(reel.segments[segmentIndex].startTimelineSecond);
  }

  void stepSegment(int delta) {
    final reel = state.reel;
    if (reel == null || reel.segments.isEmpty) return;
    final current = state.activeSegment;
    final currentIdx = current?.orderIndex ?? 0;
    final nextIdx = (currentIdx + delta).clamp(0, reel.segments.length - 1);
    jumpToSegment(nextIdx);
  }

  void setPlaybackSpeed(double speed) {
    final clamped = speed.clamp(0.5, 2.0);
    state = state.copyWith(playbackSpeed: clamped);
  }

  void toggleTvGraphics() {
    state = state.copyWith(showTvGraphics: !state.showTvGraphics);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void clear() {
    stop();
    state = const InstantHighlightClipGeneratorState();
  }

  void _onTick(double dtSeconds) {
    if (!state.isPlaying || !state.hasReel) return;
    final next = state.playbackPositionSeconds + (dtSeconds * state.playbackSpeed);
    if (next >= state.totalDurationSeconds) {
      _playbackTimer?.cancel();
      _playbackTimer = null;
      state = state.copyWith(
        isPlaying: false,
        playbackPositionSeconds: state.totalDurationSeconds,
      );
      return;
    }
    state = state.copyWith(playbackPositionSeconds: next);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

final instantHighlightClipGeneratorProvider = StateNotifierProvider<
    InstantHighlightClipGeneratorNotifier, InstantHighlightClipGeneratorState>(
  (ref) => InstantHighlightClipGeneratorNotifier(),
);

// ============================================================================
// 5. WIDOK ODTWARZACZA SKRÓTÓW TELEWIZYJNYCH 45s (UI AAA)
// ============================================================================

/// Interaktywny panel odtwarzacza automatycznych 45-sekundowych skrótów TV po etapie.
class InstantHighlightClipPlayerPanel extends ConsumerStatefulWidget {
  final InstantHighlightReel? initialReel;
  final VoidCallback? onGenerateSampleRequested;
  final ValueChanged<String>? onExportScript;
  final bool isEnabled;

  const InstantHighlightClipPlayerPanel({
    super.key,
    this.initialReel,
    this.onGenerateSampleRequested,
    this.onExportScript,
    this.isEnabled = true,
  });

  @override
  ConsumerState<InstantHighlightClipPlayerPanel> createState() =>
      _InstantHighlightClipPlayerPanelState();
}

class _InstantHighlightClipPlayerPanelState
    extends ConsumerState<InstantHighlightClipPlayerPanel> {
  int? _hoveredSegmentIndex;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReel;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(instantHighlightClipGeneratorProvider.notifier).loadReel(initial);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(instantHighlightClipGeneratorProvider);
    final notifier = ref.read(instantHighlightClipGeneratorProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = width < 680;
        final isDesktopWide = width >= 1150;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(state, notifier, isCompact),
              const SizedBox(height: 12),
              if (!state.hasReel)
                _buildEmptyState(notifier, isCompact)
              else if (isDesktopWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildPlayerColumn(state, notifier, isCompact),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildSegmentCueList(state, notifier),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlayerColumn(state, notifier, isCompact),
                    const SizedBox(height: 14),
                    _buildSegmentCueList(state, notifier),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    InstantHighlightClipGeneratorState state,
    InstantHighlightClipGeneratorNotifier notifier,
    bool isCompact,
  ) {
    final reel = state.reel;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reel != null
                        ? 'Skrót TV 45s • ${reel.stageName}'
                        : 'Generator Skrótów TV 45s',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    reel != null
                        ? '${reel.raceName} • ${reel.segments.length} ujęć • Dramatyzm ${reel.averageDramaScore.toStringAsFixed(0)}/100'
                        : 'Automatyczny montaż najważniejszych momentów po etapie',
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
          ],
        ),
        if (reel != null)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ActionPillButton(
                icon: state.showTvGraphics
                    ? Icons.subtitles_rounded
                    : Icons.subtitles_off_rounded,
                label: isCompact ? 'TV HUD' : 'Grafika TV',
                isActive: state.showTvGraphics,
                isEnabled: widget.isEnabled,
                onTap: notifier.toggleTvGraphics,
              ),
              _ActionPillButton(
                icon: Icons.description_outlined,
                label: isCompact ? 'Skrypt' : 'Eksportuj skrypt',
                isEnabled: widget.isEnabled,
                onTap: () {
                  final script = reel.exportBroadcastScriptSummary();
                  Clipboard.setData(ClipboardData(text: script));
                  widget.onExportScript?.call(script);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState(
    InstantHighlightClipGeneratorNotifier notifier,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.movie_creation_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak wygenerowanego skrótu telewizyjnego',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Po zakończeniu etapu reżyser AI automatycznie wybierze najciekawsze ataki, kraksy i finisz, składając 45-sekundowy materiał z oprawą TV.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.onGenerateSampleRequested != null) ...[
            const SizedBox(height: 16),
            _ActionPillButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Wygeneruj skrót etapu',
              isActive: true,
              isEnabled: widget.isEnabled,
              onTap: widget.onGenerateSampleRequested!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerColumn(
    InstantHighlightClipGeneratorState state,
    InstantHighlightClipGeneratorNotifier notifier,
    bool isCompact,
  ) {
    final reel = state.reel!;
    final activeSeg = state.activeSegment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: BroadcastHighlightViewportPainter(
                      reel: reel,
                      activeSegment: activeSeg,
                      playbackPositionSeconds: state.playbackPositionSeconds,
                    ),
                  ),
                  if (state.showTvGraphics && activeSeg != null)
                    _buildTvHudOverlay(reel, activeSeg, state, isCompact),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildMultiSegmentTimeline(reel, state, notifier),
        const SizedBox(height: 10),
        _buildTransportControls(state, notifier, isCompact),
      ],
    );
  }

  Widget _buildTvHudOverlay(
    InstantHighlightReel reel,
    HighlightClipSegment segment,
    InstantHighlightClipGeneratorState state,
    bool isCompact,
  ) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.65),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: state.isPlaying
                            ? AppColors.crimsonAlert
                            : AppColors.goldAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${segment.cameraAngle.hudTag} • KM ${segment.kilometerMark.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_formatClock(state.playbackPositionSeconds)} / ${_formatClock(reel.totalDurationSeconds)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            child: Container(
              key: ValueKey<String>(segment.id),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 12,
                vertical: isCompact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: segment.role.accentColor.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: segment.role.accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      segment.lowerThird.badgeText,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          segment.lowerThird.primaryTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          segment.commentaryLine,
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
                  if (segment.lowerThird.riderSpeedKmh != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${segment.lowerThird.riderSpeedKmh!.toStringAsFixed(1)} km/h',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyanAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSegmentTimeline(
    InstantHighlightReel reel,
    InstantHighlightClipGeneratorState state,
    InstantHighlightClipGeneratorNotifier notifier,
  ) {
    final total = math.max(1.0, reel.totalDurationSeconds);
    final activeSeg = state.activeSegment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 22,
          child: Row(
            children: reel.segments.map((seg) {
              final flexValue =
                  math.max(1, ((seg.durationSeconds / total) * 1000).round());
              final isSelected = activeSeg?.id == seg.id;
              final isHovered = _hoveredSegmentIndex == seg.orderIndex;

              return Expanded(
                flex: flexValue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: MouseRegion(
                    onEnter: (_) =>
                        setState(() => _hoveredSegmentIndex = seg.orderIndex),
                    onExit: (_) => setState(() => _hoveredSegmentIndex = null),
                    cursor: widget.isEnabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.forbidden,
                    child: InkWell(
                      onTap: widget.isEnabled
                          ? () => notifier.jumpToSegment(seg.orderIndex)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: seg.role.accentColor.withValues(
                            alpha: isSelected ? 0.95 : (isHovered ? 0.7 : 0.35),
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${seg.durationSeconds.toStringAsFixed(0)}s',
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.black
                                : AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.goldAccent,
          ),
          child: Slider(
            value: state.playbackPositionSeconds.clamp(0.0, total),
            min: 0.0,
            max: total,
            onChanged: widget.isEnabled ? notifier.seekTo : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTransportControls(
    InstantHighlightClipGeneratorState state,
    InstantHighlightClipGeneratorNotifier notifier,
    bool isCompact,
  ) {
    final speeds = [0.5, 1.0, 1.5, 2.0];
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ActionPillButton(
              icon: Icons.skip_previous_rounded,
              label: '',
              isEnabled: widget.isEnabled,
              onTap: () => notifier.stepSegment(-1),
            ),
            _ActionPillButton(
              icon: state.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              label: state.isPlaying ? 'Pauza' : 'Odtwórz',
              isActive: state.isPlaying,
              isEnabled: widget.isEnabled,
              onTap: notifier.togglePlayPause,
            ),
            _ActionPillButton(
              icon: Icons.skip_next_rounded,
              label: '',
              isEnabled: widget.isEnabled,
              onTap: () => notifier.stepSegment(1),
            ),
            _ActionPillButton(
              icon: Icons.replay_rounded,
              label: isCompact ? '' : 'Od początku',
              isEnabled: widget.isEnabled,
              onTap: () {
                notifier.seekTo(0.0);
                notifier.play();
              },
            ),
          ],
        ),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: speeds.map((spd) {
            final selected = (state.playbackSpeed - spd).abs() < 0.05;
            return _ActionPillButton(
              icon: null,
              label: '${spd}x',
              isActive: selected,
              isEnabled: widget.isEnabled,
              onTap: () => notifier.setPlaybackSpeed(spd),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSegmentCueList(
    InstantHighlightClipGeneratorState state,
    InstantHighlightClipGeneratorNotifier notifier,
  ) {
    final reel = state.reel!;
    final activeId = state.activeSegment?.id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Lista ujęć montażowych (45s)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...reel.segments.map((seg) {
            final isActive = seg.id == activeId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _SegmentCueTile(
                segment: seg,
                isActive: isActive,
                isEnabled: widget.isEnabled,
                onTap: () => notifier.jumpToSegment(seg.orderIndex),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatClock(double seconds) {
    final total = seconds.round().clamp(0, 3599);
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _SegmentCueTile extends StatefulWidget {
  final HighlightClipSegment segment;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _SegmentCueTile({
    required this.segment,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_SegmentCueTile> createState() => _SegmentCueTileState();
}

class _SegmentCueTileState extends State<_SegmentCueTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final seg = widget.segment;
    final borderColor = widget.isActive
        ? seg.role.accentColor
        : (_isFocused
            ? AppColors.goldAccent
            : (_isHovered ? AppColors.textSecondary : AppColors.cardBorder));

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: InkWell(
          onTap: widget.isEnabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.surfaceLight
                  : (_isHovered
                      ? AppColors.surface.withValues(alpha: 0.9)
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: seg.role.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            seg.formattedTimelineWindow,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              seg.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 2),
                      Text(
                        '${seg.cameraAngle.hudTag} • KM ${seg.kilometerMark.toStringAsFixed(1)} • ${seg.durationSeconds.toStringAsFixed(1)}s',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
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

class _ActionPillButton extends StatefulWidget {
  final IconData? icon;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ActionPillButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  State<_ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<_ActionPillButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.isEnabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : (widget.isActive
            ? AppColors.primaryAccent
            : (_isHovered ? AppColors.surfaceLight : AppColors.background));

    final borderColor = !widget.isEnabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (_isFocused
            ? AppColors.goldAccent
            : (widget.isActive
                ? AppColors.goldAccent
                : (_isHovered ? AppColors.textSecondary : AppColors.cardBorder)));

    final fgColor = !widget.isEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (widget.isActive ? Colors.white : AppColors.textPrimary);

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: InkWell(
          onTap: widget.isEnabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.label.isEmpty ? 8 : 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null)
                  Icon(widget.icon, size: 16, color: fgColor),
                if (widget.icon != null && widget.label.isNotEmpty)
                  const SizedBox(width: 6),
                if (widget.label.isNotEmpty)
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

// ============================================================================
// 6. PAINTER SCENY TELEWIZYJNEJ SKRÓTU 45s
// ============================================================================

/// Rysuje dynamiczną scenę transmisji TV z profilem terenu, kolarzami i kamerą.
class BroadcastHighlightViewportPainter extends CustomPainter {
  final InstantHighlightReel reel;
  final HighlightClipSegment? activeSegment;
  final double playbackPositionSeconds;

  const BroadcastHighlightViewportPainter({
    required this.reel,
    required this.activeSegment,
    required this.playbackPositionSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF101725),
          Color(0xFF161D2B),
          Color(0xFF0F1115),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final seg = activeSegment;
    final segProgress = seg != null && seg.durationSeconds > 0
        ? ((playbackPositionSeconds - seg.startTimelineSecond) /
                seg.durationSeconds)
            .clamp(0.0, 1.0)
        : 0.0;

    // Rysowanie sylwetki profilu terenu w tle.
    final terrainPath = Path()..moveTo(0, size.height);
    final gradSlope = (seg?.gradientPercent ?? 2.0).clamp(-8.0, 14.0);
    for (var i = 0; i <= 24; i++) {
      final t = i / 24.0;
      final x = size.width * t;
      final wave = math.sin(t * math.pi * 2.5 + (seg?.orderIndex ?? 0)) * 12.0;
      final slopeOffset = (0.5 - t) * gradSlope * 3.5;
      final y = size.height * 0.64 + wave + slopeOffset;
      terrainPath.lineTo(x, y);
    }
    terrainPath
      ..lineTo(size.width, size.height)
      ..close();

    final terrainPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.55);
    canvas.drawPath(terrainPath, terrainPaint);

    // Szosa na dole kadru.
    final roadTop = size.height * 0.72;
    final roadPaint = Paint()..color = const Color(0xFF202531);
    canvas.drawRect(
      Rect.fromLTWH(0, roadTop, size.width, size.height - roadTop),
      roadPaint,
    );

    final accentColor = seg?.role.accentColor ?? AppColors.goldAccent;
    final centerLinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.45)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(0, roadTop + 14),
      Offset(size.width, roadTop + 14),
      centerLinePaint,
    );

    // Kolarze poruszający się w kadrze w rytmie playbackPositionSeconds.
    final leadX = size.width * (0.22 + segProgress * 0.56);
    final riderY = roadTop + 10;
    final pelotonPaint = Paint()..color = AppColors.accentBlue;
    for (var i = 0; i < 6; i++) {
      final rx = (leadX - 28 - i * 18).clamp(16.0, size.width - 16);
      final ry = riderY + (i.isEven ? -3.0 : 4.0);
      canvas.drawCircle(Offset(rx, ry), 4.0, pelotonPaint);
    }

    // Lider ujęcia w złotej poświacie.
    canvas.drawCircle(
      Offset(leadX, riderY),
      9.0,
      Paint()..color = accentColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      Offset(leadX, riderY),
      5.0,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant BroadcastHighlightViewportPainter oldDelegate) {
    return oldDelegate.playbackPositionSeconds != playbackPositionSeconds ||
        oldDelegate.activeSegment?.id != activeSegment?.id ||
        oldDelegate.reel.reelId != reel.reelId;
  }
}
