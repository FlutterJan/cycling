import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/race/uci_commissaire_rulebook_and_var_model.dart';

/// Poziom oceny odchylenia toru jazdy sprintera w analizie VAR.
enum SprintDeviationZoneLevel {
  clean,
  warning,
  violation;

  String get displayNamePl {
    switch (this) {
      case SprintDeviationZoneLevel.clean:
        return 'Tor stabilny';
      case SprintDeviationZoneLevel.warning:
        return 'Granica tolerancji';
      case SprintDeviationZoneLevel.violation:
        return 'Zajechanie drogi';
    }
  }
}

/// Tor jazdy pojedynczego sprintera na ostatnich 200 m etapu.
class SprintVarRiderTrack {
  final String riderId;
  final String riderName;
  final String teamName;
  final int bibNumber;
  final Color jerseyColor;
  final int finishingPosition;
  final bool isSuspect;
  final bool isVictim;
  final List<SprintVarFrameSample> samples;

  const SprintVarRiderTrack({
    required this.riderId,
    required this.riderName,
    required this.teamName,
    required this.bibNumber,
    required this.jerseyColor,
    required this.finishingPosition,
    this.isSuspect = false,
    this.isVictim = false,
    this.samples = const [],
  });

  SprintVarRiderTrack copyWith({
    String? riderId,
    String? riderName,
    String? teamName,
    int? bibNumber,
    Color? jerseyColor,
    int? finishingPosition,
    bool? isSuspect,
    bool? isVictim,
    List<SprintVarFrameSample>? samples,
  }) {
    return SprintVarRiderTrack(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamName: teamName ?? this.teamName,
      bibNumber: bibNumber ?? this.bibNumber,
      jerseyColor: jerseyColor ?? this.jerseyColor,
      finishingPosition: finishingPosition ?? this.finishingPosition,
      isSuspect: isSuspect ?? this.isSuspect,
      isVictim: isVictim ?? this.isVictim,
      samples: samples ?? this.samples,
    );
  }

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'teamName': teamName,
        'bibNumber': bibNumber,
        'jerseyColor': jerseyColor.toARGB32(),
        'finishingPosition': finishingPosition,
        'isSuspect': isSuspect,
        'isVictim': isVictim,
        'samples': samples.map((s) => s.toJson()).toList(),
      };

  factory SprintVarRiderTrack.fromJson(Map<String, dynamic> json) {
    final rawSamples = json['samples'] as List<dynamic>? ?? const [];
    return SprintVarRiderTrack(
      riderId: json['riderId'] as String? ?? '',
      riderName: json['riderName'] as String? ?? '',
      teamName: json['teamName'] as String? ?? '',
      bibNumber: (json['bibNumber'] as num?)?.toInt() ?? 1,
      jerseyColor: Color(
        (json['jerseyColor'] as num?)?.toInt() ??
            AppColors.accentBlue.toARGB32(),
      ),
      finishingPosition: (json['finishingPosition'] as num?)?.toInt() ?? 1,
      isSuspect: json['isSuspect'] as bool? ?? false,
      isVictim: json['isVictim'] as bool? ?? false,
      samples: rawSamples
          .whereType<Map<String, dynamic>>()
          .map(SprintVarFrameSample.fromJson)
          .toList(),
    );
  }
}

/// Kompletny zestaw danych dla inspektora powtórki VAR z lotu ptaka.
class SprintVarOverheadReplayData {
  final String incidentId;
  final String stageId;
  final String stageName;
  final double roadWidthMeters;
  final double deviationToleranceMeters;
  final SprintVarCameraAngle activeCamera;
  final List<SprintVarCameraAngle> availableCameras;
  final List<SprintVarRiderTrack> tracks;
  final SprintVarIncidentInput? incidentInput;
  final SprintVarVerdict? initialVerdict;
  final String notesPl;

  const SprintVarOverheadReplayData({
    required this.incidentId,
    required this.stageId,
    required this.stageName,
    this.roadWidthMeters = 8.0,
    this.deviationToleranceMeters = 0.85,
    this.activeCamera = SprintVarCameraAngle.overheadHelicopter,
    this.availableCameras = const [
      SprintVarCameraAngle.overheadHelicopter,
      SprintVarCameraAngle.finishLineHeadOn,
      SprintVarCameraAngle.rearPelotonCam,
      SprintVarCameraAngle.sideBarrierTracking,
    ],
    this.tracks = const [],
    this.incidentInput,
    this.initialVerdict,
    this.notesPl = '',
  });

  SprintVarOverheadReplayData copyWith({
    String? incidentId,
    String? stageId,
    String? stageName,
    double? roadWidthMeters,
    double? deviationToleranceMeters,
    SprintVarCameraAngle? activeCamera,
    List<SprintVarCameraAngle>? availableCameras,
    List<SprintVarRiderTrack>? tracks,
    SprintVarIncidentInput? incidentInput,
    SprintVarVerdict? initialVerdict,
    String? notesPl,
  }) {
    return SprintVarOverheadReplayData(
      incidentId: incidentId ?? this.incidentId,
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      deviationToleranceMeters:
          deviationToleranceMeters ?? this.deviationToleranceMeters,
      activeCamera: activeCamera ?? this.activeCamera,
      availableCameras: availableCameras ?? this.availableCameras,
      tracks: tracks ?? this.tracks,
      incidentInput: incidentInput ?? this.incidentInput,
      initialVerdict: initialVerdict ?? this.initialVerdict,
      notesPl: notesPl ?? this.notesPl,
    );
  }

  Map<String, dynamic> toJson() => {
        'incidentId': incidentId,
        'stageId': stageId,
        'stageName': stageName,
        'roadWidthMeters': roadWidthMeters,
        'deviationToleranceMeters': deviationToleranceMeters,
        'activeCamera': activeCamera.toJson(),
        'availableCameras': availableCameras.map((c) => c.toJson()).toList(),
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'initialVerdict': initialVerdict?.toJson(),
        'notesPl': notesPl,
      };

  factory SprintVarOverheadReplayData.fromJson(Map<String, dynamic> json) {
    final rawCams = json['availableCameras'] as List<dynamic>? ?? const [];
    final rawTracks = json['tracks'] as List<dynamic>? ?? const [];
    final rawVerdict = json['initialVerdict'];
    return SprintVarOverheadReplayData(
      incidentId: json['incidentId'] as String? ?? '',
      stageId: json['stageId'] as String? ?? '',
      stageName: json['stageName'] as String? ?? '',
      roadWidthMeters:
          (json['roadWidthMeters'] as num?)?.toDouble() ?? 8.0,
      deviationToleranceMeters:
          (json['deviationToleranceMeters'] as num?)?.toDouble() ?? 0.85,
      activeCamera: SprintVarCameraAngle.fromJson(
        json['activeCamera'] as String? ?? 'overheadHelicopter',
      ),
      availableCameras: rawCams
          .map((e) => SprintVarCameraAngle.fromJson(e.toString()))
          .toList(),
      tracks: rawTracks
          .whereType<Map<String, dynamic>>()
          .map(SprintVarRiderTrack.fromJson)
          .toList(),
      initialVerdict: rawVerdict is Map<String, dynamic>
          ? SprintVarVerdict.fromJson(rawVerdict)
          : null,
      notesPl: json['notesPl'] as String? ?? '',
    );
  }

  /// Pusty zestaw danych do obsługi stanu braku incydentu.
  factory SprintVarOverheadReplayData.empty() {
    return const SprintVarOverheadReplayData(
      incidentId: 'EMPTY',
      stageId: 'none',
      stageName: 'Brak zapisanego finiszu',
      tracks: [],
      notesPl: 'Brak zarejestrowanych próbek toru jazdy na ostatnich 200 m.',
    );
  }

  /// Demonstracyjny scenariusz z wyraźnym zajechaniem drogi na ostatnich 75 m.
  factory SprintVarOverheadReplayData.demoIrregularSprint() {
    const suspectSamples = [
      SprintVarFrameSample(
        timestampSeconds: 0.0,
        distanceToFinishMeters: 200.0,
        lateralPositionMeters: 3.10,
        speedKmh: 66.2,
        nearestRivalClearanceMeters: 1.65,
      ),
      SprintVarFrameSample(
        timestampSeconds: 2.2,
        distanceToFinishMeters: 160.0,
        lateralPositionMeters: 3.15,
        speedKmh: 68.5,
        nearestRivalClearanceMeters: 1.45,
      ),
      SprintVarFrameSample(
        timestampSeconds: 4.3,
        distanceToFinishMeters: 120.0,
        lateralPositionMeters: 3.25,
        speedKmh: 71.4,
        nearestRivalClearanceMeters: 1.15,
      ),
      SprintVarFrameSample(
        timestampSeconds: 6.1,
        distanceToFinishMeters: 85.0,
        lateralPositionMeters: 3.70,
        speedKmh: 73.1,
        nearestRivalClearanceMeters: 0.72,
      ),
      SprintVarFrameSample(
        timestampSeconds: 7.4,
        distanceToFinishMeters: 60.0,
        lateralPositionMeters: 4.65,
        speedKmh: 73.8,
        nearestRivalClearanceMeters: 0.28,
      ),
      SprintVarFrameSample(
        timestampSeconds: 8.9,
        distanceToFinishMeters: 30.0,
        lateralPositionMeters: 4.95,
        speedKmh: 72.9,
        nearestRivalClearanceMeters: 0.34,
      ),
      SprintVarFrameSample(
        timestampSeconds: 10.4,
        distanceToFinishMeters: 0.0,
        lateralPositionMeters: 4.88,
        speedKmh: 71.5,
        nearestRivalClearanceMeters: 0.48,
      ),
    ];

    const victimSamples = [
      SprintVarFrameSample(
        timestampSeconds: 0.0,
        distanceToFinishMeters: 200.0,
        lateralPositionMeters: 4.75,
        speedKmh: 66.0,
        nearestRivalClearanceMeters: 1.65,
      ),
      SprintVarFrameSample(
        timestampSeconds: 2.2,
        distanceToFinishMeters: 160.0,
        lateralPositionMeters: 4.60,
        speedKmh: 68.9,
        nearestRivalClearanceMeters: 1.45,
      ),
      SprintVarFrameSample(
        timestampSeconds: 4.3,
        distanceToFinishMeters: 120.0,
        lateralPositionMeters: 4.40,
        speedKmh: 71.8,
        nearestRivalClearanceMeters: 1.15,
      ),
      SprintVarFrameSample(
        timestampSeconds: 6.1,
        distanceToFinishMeters: 85.0,
        lateralPositionMeters: 4.42,
        speedKmh: 73.5,
        nearestRivalClearanceMeters: 0.72,
      ),
      SprintVarFrameSample(
        timestampSeconds: 7.4,
        distanceToFinishMeters: 60.0,
        lateralPositionMeters: 4.95,
        speedKmh: 67.2,
        nearestRivalClearanceMeters: 0.28,
      ),
      SprintVarFrameSample(
        timestampSeconds: 8.9,
        distanceToFinishMeters: 30.0,
        lateralPositionMeters: 5.30,
        speedKmh: 68.4,
        nearestRivalClearanceMeters: 0.34,
      ),
      SprintVarFrameSample(
        timestampSeconds: 10.4,
        distanceToFinishMeters: 0.0,
        lateralPositionMeters: 5.36,
        speedKmh: 69.1,
        nearestRivalClearanceMeters: 0.48,
      ),
    ];

    const thirdRiderSamples = [
      SprintVarFrameSample(
        timestampSeconds: 0.0,
        distanceToFinishMeters: 200.0,
        lateralPositionMeters: 1.85,
        speedKmh: 65.8,
        nearestRivalClearanceMeters: 1.25,
      ),
      SprintVarFrameSample(
        timestampSeconds: 4.3,
        distanceToFinishMeters: 120.0,
        lateralPositionMeters: 1.75,
        speedKmh: 70.6,
        nearestRivalClearanceMeters: 1.50,
      ),
      SprintVarFrameSample(
        timestampSeconds: 7.4,
        distanceToFinishMeters: 60.0,
        lateralPositionMeters: 1.65,
        speedKmh: 72.1,
        nearestRivalClearanceMeters: 2.80,
      ),
      SprintVarFrameSample(
        timestampSeconds: 10.4,
        distanceToFinishMeters: 0.0,
        lateralPositionMeters: 1.60,
        speedKmh: 70.9,
        nearestRivalClearanceMeters: 3.10,
      ),
    ];

    const input = SprintVarIncidentInput(
      incidentId: 'VAR-2025-TDF-04',
      stageId: 'tdf_stage_04',
      riderId: 'rider_suspect_11',
      riderName: 'M. Van Der Sprint',
      teamId: 'team_crimson',
      finishingPosition: 1,
      groupEndPosition: 34,
      roadWidthMeters: 8.0,
      trajectorySamples: suspectSamples,
      availableCameras: [
        SprintVarCameraAngle.overheadHelicopter,
        SprintVarCameraAngle.finishLineHeadOn,
        SprintVarCameraAngle.rearPelotonCam,
      ],
      rivalForcedToBrake: true,
    );

    return const SprintVarOverheadReplayData(
      incidentId: 'VAR-2025-TDF-04',
      stageId: 'tdf_stage_04',
      stageName: 'Etap 4 • Finisz płaski (200 m)',
      roadWidthMeters: 8.0,
      deviationToleranceMeters: 0.85,
      activeCamera: SprintVarCameraAngle.overheadHelicopter,
      incidentInput: input,
      notesPl:
          'Podejrzenie gwałtownego zjechania na prawą stronę na ostatnich 60 m i zamknięcia toru jazdy rywalowi.',
      tracks: [
        SprintVarRiderTrack(
          riderId: 'rider_suspect_11',
          riderName: 'M. Van Der Sprint',
          teamName: 'Crimson Pro Cycling',
          bibNumber: 11,
          jerseyColor: AppColors.goldAccent,
          finishingPosition: 1,
          isSuspect: true,
          samples: suspectSamples,
        ),
        SprintVarRiderTrack(
          riderId: 'rider_victim_42',
          riderName: 'L. Kowalski',
          teamName: 'Nordic Aero Team',
          bibNumber: 42,
          jerseyColor: AppColors.accentBlue,
          finishingPosition: 3,
          isVictim: true,
          samples: victimSamples,
        ),
        SprintVarRiderTrack(
          riderId: 'rider_clean_07',
          riderName: 'J. Moreau',
          teamName: 'Alpinia WorldTour',
          bibNumber: 7,
          jerseyColor: AppColors.statusSuccess,
          finishingPosition: 2,
          samples: thirdRiderSamples,
        ),
      ],
    );
  }

  /// Demonstracyjny scenariusz czystego sprintu bez zajechania drogi.
  factory SprintVarOverheadReplayData.demoCleanSprint() {
    const leadSamples = [
      SprintVarFrameSample(
        timestampSeconds: 0.0,
        distanceToFinishMeters: 200.0,
        lateralPositionMeters: 3.40,
        speedKmh: 67.0,
        nearestRivalClearanceMeters: 1.50,
      ),
      SprintVarFrameSample(
        timestampSeconds: 5.0,
        distanceToFinishMeters: 100.0,
        lateralPositionMeters: 3.55,
        speedKmh: 72.8,
        nearestRivalClearanceMeters: 1.42,
      ),
      SprintVarFrameSample(
        timestampSeconds: 10.0,
        distanceToFinishMeters: 0.0,
        lateralPositionMeters: 3.62,
        speedKmh: 71.9,
        nearestRivalClearanceMeters: 1.38,
      ),
    ];

    const challengerSamples = [
      SprintVarFrameSample(
        timestampSeconds: 0.0,
        distanceToFinishMeters: 200.0,
        lateralPositionMeters: 4.95,
        speedKmh: 66.8,
        nearestRivalClearanceMeters: 1.50,
      ),
      SprintVarFrameSample(
        timestampSeconds: 5.0,
        distanceToFinishMeters: 100.0,
        lateralPositionMeters: 5.05,
        speedKmh: 72.2,
        nearestRivalClearanceMeters: 1.42,
      ),
      SprintVarFrameSample(
        timestampSeconds: 10.0,
        distanceToFinishMeters: 0.0,
        lateralPositionMeters: 5.00,
        speedKmh: 71.4,
        nearestRivalClearanceMeters: 1.38,
      ),
    ];

    const input = SprintVarIncidentInput(
      incidentId: 'VAR-2025-CLEAN-01',
      stageId: 'paris_nice_02',
      riderId: 'rider_clean_01',
      riderName: 'A. Vermeulen',
      teamId: 'team_aqua',
      finishingPosition: 1,
      groupEndPosition: 28,
      roadWidthMeters: 8.0,
      trajectorySamples: leadSamples,
    );

    return const SprintVarOverheadReplayData(
      incidentId: 'VAR-2025-CLEAN-01',
      stageId: 'paris_nice_02',
      stageName: 'Etap 2 • Czysty finisz sprinterski',
      roadWidthMeters: 8.0,
      deviationToleranceMeters: 0.85,
      activeCamera: SprintVarCameraAngle.overheadHelicopter,
      incidentInput: input,
      notesPl: 'Równoległy pojedynek sprinterów z zachowaniem bezpiecznego odstępu.',
      tracks: [
        SprintVarRiderTrack(
          riderId: 'rider_clean_01',
          riderName: 'A. Vermeulen',
          teamName: 'Aqua Blue Pro',
          bibNumber: 21,
          jerseyColor: AppColors.goldAccent,
          finishingPosition: 1,
          isSuspect: true,
          samples: leadSamples,
        ),
        SprintVarRiderTrack(
          riderId: 'rider_clean_02',
          riderName: 'P. Zieliński',
          teamName: 'Baltic Cycling',
          bibNumber: 54,
          jerseyColor: AppColors.accentBlue,
          finishingPosition: 2,
          samples: challengerSamples,
        ),
      ],
    );
  }
}

/// Wynik interpolacji próbki wideo na zadanej odległości do mety.
class SprintVarInterpolatedPoint {
  final double distanceToFinishMeters;
  final double lateralPositionMeters;
  final double speedKmh;
  final double nearestRivalClearanceMeters;
  final double deviationFromBaselineMeters;
  final double lateralVelocityMps;
  final SprintDeviationZoneLevel zoneLevel;

  const SprintVarInterpolatedPoint({
    required this.distanceToFinishMeters,
    required this.lateralPositionMeters,
    required this.speedKmh,
    required this.nearestRivalClearanceMeters,
    required this.deviationFromBaselineMeters,
    required this.lateralVelocityMps,
    required this.zoneLevel,
  });
}

/// Podsumowanie metryk odchylenia toru jazdy na ostatnich 200 m.
class SprintVarTrackSummary {
  final double maxDeviationMeters;
  final double peakDeviationDistanceMeters;
  final double peakLateralVelocityMps;
  final double minClearanceMeters;
  final SprintDeviationZoneLevel worstZone;

  const SprintVarTrackSummary({
    required this.maxDeviationMeters,
    required this.peakDeviationDistanceMeters,
    required this.peakLateralVelocityMps,
    required this.minClearanceMeters,
    required this.worstZone,
  });
}

/// Kalkulator interpolacji, odchyleń toru i oceny strefy VAR na ostatnich 200 m.
class SprintVarOverheadCalculator {
  const SprintVarOverheadCalculator._();

  static const double sprintWindowMeters = 200.0;

  static SprintDeviationZoneLevel classifyDeviation({
    required double deviationMeters,
    required double toleranceMeters,
  }) {
    final safeTol = math.max(0.25, toleranceMeters);
    if (deviationMeters > safeTol) {
      return SprintDeviationZoneLevel.violation;
    }
    if (deviationMeters > safeTol * 0.72) {
      return SprintDeviationZoneLevel.warning;
    }
    return SprintDeviationZoneLevel.clean;
  }

  static List<SprintVarFrameSample> sortedByDistanceDesc(
    List<SprintVarFrameSample> samples,
  ) {
    final copy = List<SprintVarFrameSample>.from(samples);
    copy.sort(
      (a, b) => b.distanceToFinishMeters.compareTo(a.distanceToFinishMeters),
    );
    return copy;
  }

  static SprintVarInterpolatedPoint interpolateAtDistance({
    required List<SprintVarFrameSample> samples,
    required double distanceToFinishMeters,
    required double toleranceMeters,
  }) {
    if (samples.isEmpty) {
      return SprintVarInterpolatedPoint(
        distanceToFinishMeters: distanceToFinishMeters,
        lateralPositionMeters: 4.0,
        speedKmh: 0.0,
        nearestRivalClearanceMeters: 2.0,
        deviationFromBaselineMeters: 0.0,
        lateralVelocityMps: 0.0,
        zoneLevel: SprintDeviationZoneLevel.clean,
      );
    }

    final sorted = sortedByDistanceDesc(samples);
    final baselineLat = sorted.first.lateralPositionMeters;
    final clampedDist = distanceToFinishMeters.clamp(0.0, sprintWindowMeters);

    if (sorted.length == 1 || clampedDist >= sorted.first.distanceToFinishMeters) {
      final first = sorted.first;
      const dev = 0.0;
      return SprintVarInterpolatedPoint(
        distanceToFinishMeters: clampedDist,
        lateralPositionMeters: first.lateralPositionMeters,
        speedKmh: first.speedKmh,
        nearestRivalClearanceMeters: first.nearestRivalClearanceMeters,
        deviationFromBaselineMeters: dev,
        lateralVelocityMps: 0.0,
        zoneLevel: SprintDeviationZoneLevel.clean,
      );
    }

    if (clampedDist <= sorted.last.distanceToFinishMeters) {
      final last = sorted.last;
      final dev = (last.lateralPositionMeters - baselineLat).abs();
      double latVel = 0.0;
      if (sorted.length >= 2) {
        final prev = sorted[sorted.length - 2];
        final dt = (last.timestampSeconds - prev.timestampSeconds).abs();
        if (dt > 0.001) {
          latVel =
              (last.lateralPositionMeters - prev.lateralPositionMeters).abs() /
                  dt;
        }
      }
      return SprintVarInterpolatedPoint(
        distanceToFinishMeters: clampedDist,
        lateralPositionMeters: last.lateralPositionMeters,
        speedKmh: last.speedKmh,
        nearestRivalClearanceMeters: last.nearestRivalClearanceMeters,
        deviationFromBaselineMeters: dev,
        lateralVelocityMps: latVel,
        zoneLevel: classifyDeviation(
          deviationMeters: dev,
          toleranceMeters: toleranceMeters,
        ),
      );
    }

    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      if (clampedDist <= a.distanceToFinishMeters &&
          clampedDist >= b.distanceToFinishMeters) {
        final span = a.distanceToFinishMeters - b.distanceToFinishMeters;
        final t = span > 0.0001
            ? ((a.distanceToFinishMeters - clampedDist) / span).clamp(0.0, 1.0)
            : 0.0;
        final lat = a.lateralPositionMeters +
            (b.lateralPositionMeters - a.lateralPositionMeters) * t;
        final spd = a.speedKmh + (b.speedKmh - a.speedKmh) * t;
        final clr = a.nearestRivalClearanceMeters +
            (b.nearestRivalClearanceMeters - a.nearestRivalClearanceMeters) * t;
        final dt = (b.timestampSeconds - a.timestampSeconds).abs();
        final latVel = dt > 0.001
            ? (b.lateralPositionMeters - a.lateralPositionMeters).abs() / dt
            : 0.0;
        final dev = (lat - baselineLat).abs();
        return SprintVarInterpolatedPoint(
          distanceToFinishMeters: clampedDist,
          lateralPositionMeters: lat,
          speedKmh: spd,
          nearestRivalClearanceMeters: clr,
          deviationFromBaselineMeters: dev,
          lateralVelocityMps: latVel,
          zoneLevel: classifyDeviation(
            deviationMeters: dev,
            toleranceMeters: toleranceMeters,
          ),
        );
      }
    }

    final fallback = sorted.last;
    final dev = (fallback.lateralPositionMeters - baselineLat).abs();
    return SprintVarInterpolatedPoint(
      distanceToFinishMeters: clampedDist,
      lateralPositionMeters: fallback.lateralPositionMeters,
      speedKmh: fallback.speedKmh,
      nearestRivalClearanceMeters: fallback.nearestRivalClearanceMeters,
      deviationFromBaselineMeters: dev,
      lateralVelocityMps: 0.0,
      zoneLevel: classifyDeviation(
        deviationMeters: dev,
        toleranceMeters: toleranceMeters,
      ),
    );
  }

  static SprintVarTrackSummary summarizeTrack({
    required SprintVarRiderTrack track,
    required double toleranceMeters,
  }) {
    final sorted = sortedByDistanceDesc(track.samples);
    if (sorted.isEmpty) {
      return const SprintVarTrackSummary(
        maxDeviationMeters: 0.0,
        peakDeviationDistanceMeters: 0.0,
        peakLateralVelocityMps: 0.0,
        minClearanceMeters: 2.0,
        worstZone: SprintDeviationZoneLevel.clean,
      );
    }

    final baseline = sorted.first.lateralPositionMeters;
    double maxDev = 0.0;
    double peakDist = sorted.first.distanceToFinishMeters;
    double peakLatVel = 0.0;
    double minClr = sorted.first.nearestRivalClearanceMeters;

    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      final dev = (s.lateralPositionMeters - baseline).abs();
      if (dev > maxDev) {
        maxDev = dev;
        peakDist = s.distanceToFinishMeters;
      }
      if (s.nearestRivalClearanceMeters < minClr) {
        minClr = s.nearestRivalClearanceMeters;
      }
      if (i > 0) {
        final prev = sorted[i - 1];
        final dt = (s.timestampSeconds - prev.timestampSeconds).abs();
        if (dt > 0.001) {
          final v =
              (s.lateralPositionMeters - prev.lateralPositionMeters).abs() / dt;
          if (v > peakLatVel) {
            peakLatVel = v;
          }
        }
      }
    }

    return SprintVarTrackSummary(
      maxDeviationMeters: maxDev,
      peakDeviationDistanceMeters: peakDist,
      peakLateralVelocityMps: peakLatVel,
      minClearanceMeters: minClr,
      worstZone: classifyDeviation(
        deviationMeters: maxDev,
        toleranceMeters: toleranceMeters,
      ),
    );
  }
}

/// Malarz widoku z lotu ptaka ostatnich 200 m z narysowanymi liniami toru sprinterów.
class SprintVarOverheadTrackPainter extends CustomPainter {
  final SprintVarOverheadReplayData data;
  final double currentDistanceMeters;
  final String? selectedRiderId;
  final bool showToleranceCorridor;
  final bool showRivalGapCaliper;
  final bool showDistanceGrid;

  const SprintVarOverheadTrackPainter({
    required this.data,
    required this.currentDistanceMeters,
    this.selectedRiderId,
    this.showToleranceCorridor = true,
    this.showRivalGapCaliper = true,
    this.showDistanceGrid = true,
  });

  static const double _padLeft = 36.0;
  static const double _padRight = 24.0;
  static const double _padTop = 26.0;
  static const double _padBottom = 26.0;

  double _xForDistance(double distMeters, double roadWidthPx) {
    // 200 m po lewej -> 0 m (Meta) po prawej.
    final norm =
        (SprintVarOverheadCalculator.sprintWindowMeters - distMeters) /
            SprintVarOverheadCalculator.sprintWindowMeters;
    return _padLeft + norm.clamp(0.0, 1.0) * roadWidthPx;
  }

  double _yForLateral(double lateralMeters, double roadHeightPx) {
    final norm = (lateralMeters / math.max(2.0, data.roadWidthMeters))
        .clamp(0.0, 1.0);
    return _padTop + norm * roadHeightPx;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final roadWidthPx = math.max(10.0, size.width - _padLeft - _padRight);
    final roadHeightPx = math.max(10.0, size.height - _padTop - _padBottom);
    final roadRect = Rect.fromLTWH(_padLeft, _padTop, roadWidthPx, roadHeightPx);

    // Tło poza jezdnią.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    // Asfalt drogi.
    final asphaltPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF161922),
          Color(0xFF1D222E),
          Color(0xFF161922),
        ],
      ).createShader(roadRect);
    canvas.drawRect(roadRect, asphaltPaint);

    // Siatka odległości co 25 m / 50 m.
    if (showDistanceGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF2A2F3D).withValues(alpha: 0.65)
        ..strokeWidth = 1.0;
      const distances = [200.0, 175.0, 150.0, 125.0, 100.0, 75.0, 50.0, 25.0, 0.0];
      for (final d in distances) {
        final x = _xForDistance(d, roadWidthPx);
        canvas.drawLine(
          Offset(x, _padTop),
          Offset(x, _padTop + roadHeightPx),
          gridPaint,
        );
        if (d % 50 == 0) {
          final label = d == 0 ? 'META' : '${d.toInt()}m';
          _drawText(
            canvas,
            label,
            Offset(x - 14, 6),
            d == 0 ? AppColors.goldAccent : AppColors.textSecondary,
            fontSize: 10,
            bold: d == 0,
          );
        }
      }

      // Przerywane linie pasów jezdni co 2.0 m.
      final lanePaint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.16)
        ..strokeWidth = 1.0;
      for (var lat = 2.0; lat < data.roadWidthMeters; lat += 2.0) {
        final y = _yForLateral(lat, roadHeightPx);
        for (var x = _padLeft; x < _padLeft + roadWidthPx; x += 18) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 9, _padLeft + roadWidthPx), y),
            lanePaint,
          );
        }
      }
    }

    // Linia mety (szachownica 0 m).
    final finishX = _xForDistance(0.0, roadWidthPx);
    const squareSize = 6.0;
    final numRows = (roadHeightPx / squareSize).ceil();
    for (var r = 0; r < numRows; r++) {
      final y = _padTop + r * squareSize;
      final h = math.min(squareSize, _padTop + roadHeightPx - y);
      canvas.drawRect(
        Rect.fromLTWH(finishX - 4, y, 4, h),
        Paint()
          ..color = r.isEven ? AppColors.textPrimary : const Color(0xFF181B22),
      );
      canvas.drawRect(
        Rect.fromLTWH(finishX, y, 4, h),
        Paint()
          ..color = r.isOdd ? AppColors.textPrimary : const Color(0xFF181B22),
      );
    }

    // Barierki górna i dolna.
    final barrierPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 3.0;
    canvas.drawLine(
      const Offset(_padLeft, _padTop),
      Offset(_padLeft + roadWidthPx, _padTop),
      barrierPaint,
    );
    canvas.drawLine(
      Offset(_padLeft, _padTop + roadHeightPx),
      Offset(_padLeft + roadWidthPx, _padTop + roadHeightPx),
      barrierPaint,
    );

    // Korytarz tolerancji dla kolarza głównego / podejrzanego.
    final focusTrack = _findFocusTrack();
    if (showToleranceCorridor &&
        focusTrack != null &&
        focusTrack.samples.isNotEmpty) {
      final sorted =
          SprintVarOverheadCalculator.sortedByDistanceDesc(focusTrack.samples);
      final baseLat = sorted.first.lateralPositionMeters;
      final topY = _yForLateral(
        baseLat - data.deviationToleranceMeters,
        roadHeightPx,
      );
      final bottomY = _yForLateral(
        baseLat + data.deviationToleranceMeters,
        roadHeightPx,
      );
      final corridorRect = Rect.fromLTRB(
        _padLeft,
        topY,
        _padLeft + roadWidthPx,
        bottomY,
      );
      canvas.drawRect(
        corridorRect,
        Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.08),
      );
      final borderCorridorPaint = Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.35)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(_padLeft, topY),
        Offset(_padLeft + roadWidthPx, topY),
        borderCorridorPaint,
      );
      canvas.drawLine(
        Offset(_padLeft, bottomY),
        Offset(_padLeft + roadWidthPx, bottomY),
        borderCorridorPaint,
      );

      // Oś bazowa sprzed zmiany toru.
      final baseY = _yForLateral(baseLat, roadHeightPx);
      canvas.drawLine(
        Offset(_padLeft, baseY),
        Offset(_padLeft + roadWidthPx, baseY),
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.35)
          ..strokeWidth = 1.0,
      );
    }

    // Rysowanie linii toru jazdy każdego sprintera.
    for (final track in data.tracks) {
      _paintRiderTrajectory(canvas, track, roadWidthPx, roadHeightPx);
    }

    // Pionowa linia aktualnej klatki powtórki.
    final playheadX = _xForDistance(currentDistanceMeters, roadWidthPx);
    canvas.drawLine(
      Offset(playheadX, _padTop - 4),
      Offset(playheadX, _padTop + roadHeightPx + 4),
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.75)
        ..strokeWidth = 1.5,
    );

    // Suwmiarka odstępu między podejrzanym a poszkodowanym / najbliższym rywalem.
    if (showRivalGapCaliper && focusTrack != null && data.tracks.length >= 2) {
      _paintGapCaliper(canvas, focusTrack, roadWidthPx, roadHeightPx);
    }

    // Ikony kolarzy w aktualnym momencie powtórki.
    for (final track in data.tracks) {
      _paintRiderMarkerAtPlayhead(canvas, track, roadWidthPx, roadHeightPx);
    }

    // Nakładka celownika kamery VAR w prawym dolnym rogu jezdni.
    _drawText(
      canvas,
      'CAM: ${data.activeCamera.displayNamePl}',
      Offset(_padLeft + 8, _padTop + roadHeightPx + 6),
      AppColors.cyanAccent.withValues(alpha: 0.85),
      fontSize: 10,
      bold: true,
    );
  }

  SprintVarRiderTrack? _findFocusTrack() {
    if (data.tracks.isEmpty) return null;
    if (selectedRiderId != null) {
      for (final t in data.tracks) {
        if (t.riderId == selectedRiderId) return t;
      }
    }
    for (final t in data.tracks) {
      if (t.isSuspect) return t;
    }
    return data.tracks.first;
  }

  void _paintRiderTrajectory(
    Canvas canvas,
    SprintVarRiderTrack track,
    double roadWidthPx,
    double roadHeightPx,
  ) {
    final sorted =
        SprintVarOverheadCalculator.sortedByDistanceDesc(track.samples);
    if (sorted.length < 2) return;

    final isHighlighted =
        track.isSuspect || track.riderId == selectedRiderId || track.isVictim;
    final baseline = sorted.first.lateralPositionMeters;

    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      final p1 = Offset(
        _xForDistance(a.distanceToFinishMeters, roadWidthPx),
        _yForLateral(a.lateralPositionMeters, roadHeightPx),
      );
      final p2 = Offset(
        _xForDistance(b.distanceToFinishMeters, roadWidthPx),
        _yForLateral(b.lateralPositionMeters, roadHeightPx),
      );

      Color segColor = track.jerseyColor;
      if (track.isSuspect) {
        final dev = math.max(
          (a.lateralPositionMeters - baseline).abs(),
          (b.lateralPositionMeters - baseline).abs(),
        );
        final level = SprintVarOverheadCalculator.classifyDeviation(
          deviationMeters: dev,
          toleranceMeters: data.deviationToleranceMeters,
        );
        switch (level) {
          case SprintDeviationZoneLevel.clean:
            segColor = AppColors.statusSuccess;
            break;
          case SprintDeviationZoneLevel.warning:
            segColor = AppColors.amberWarning;
            break;
          case SprintDeviationZoneLevel.violation:
            segColor = AppColors.crimsonAlert;
            break;
        }
      }

      // Poświata pod aktywną ścieżką.
      if (isHighlighted) {
        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = segColor.withValues(alpha: 0.25)
            ..strokeWidth = 7.0
            ..strokeCap = StrokeCap.round,
        );
      }

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = segColor.withValues(alpha: isHighlighted ? 0.95 : 0.65)
          ..strokeWidth = isHighlighted ? 3.2 : 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintGapCaliper(
    Canvas canvas,
    SprintVarRiderTrack focusTrack,
    double roadWidthPx,
    double roadHeightPx,
  ) {
    final focusPoint = SprintVarOverheadCalculator.interpolateAtDistance(
      samples: focusTrack.samples,
      distanceToFinishMeters: currentDistanceMeters,
      toleranceMeters: data.deviationToleranceMeters,
    );

    SprintVarRiderTrack? nearestTrack;
    double bestLatDiff = double.infinity;
    SprintVarInterpolatedPoint? nearestPoint;

    for (final other in data.tracks) {
      if (other.riderId == focusTrack.riderId || other.samples.isEmpty) {
        continue;
      }
      final pt = SprintVarOverheadCalculator.interpolateAtDistance(
        samples: other.samples,
        distanceToFinishMeters: currentDistanceMeters,
        toleranceMeters: data.deviationToleranceMeters,
      );
      final diff =
          (pt.lateralPositionMeters - focusPoint.lateralPositionMeters).abs();
      if (diff < bestLatDiff) {
        bestLatDiff = diff;
        nearestTrack = other;
        nearestPoint = pt;
      }
    }

    if (nearestTrack == null || nearestPoint == null) return;

    final x = _xForDistance(currentDistanceMeters, roadWidthPx);
    final y1 = _yForLateral(focusPoint.lateralPositionMeters, roadHeightPx);
    final y2 = _yForLateral(nearestPoint.lateralPositionMeters, roadHeightPx);

    final caliperColor = bestLatDiff < 0.45
        ? AppColors.crimsonAlert
        : bestLatDiff < 0.85
            ? AppColors.amberWarning
            : AppColors.cyanAccent;

    canvas.drawLine(
      Offset(x, y1),
      Offset(x, y2),
      Paint()
        ..color = caliperColor
        ..strokeWidth = 2.0,
    );
    _drawText(
      canvas,
      '${bestLatDiff.toStringAsFixed(2)} m',
      Offset(x + 8, (y1 + y2) / 2 - 7),
      caliperColor,
      fontSize: 10,
      bold: true,
    );
  }

  void _paintRiderMarkerAtPlayhead(
    Canvas canvas,
    SprintVarRiderTrack track,
    double roadWidthPx,
    double roadHeightPx,
  ) {
    if (track.samples.isEmpty) return;
    final pt = SprintVarOverheadCalculator.interpolateAtDistance(
      samples: track.samples,
      distanceToFinishMeters: currentDistanceMeters,
      toleranceMeters: data.deviationToleranceMeters,
    );
    final cx = _xForDistance(currentDistanceMeters, roadWidthPx);
    final cy = _yForLateral(pt.lateralPositionMeters, roadHeightPx);
    final isSelected = track.riderId == selectedRiderId || track.isSuspect;

    if (isSelected) {
      canvas.drawCircle(
        Offset(cx, cy),
        12.0,
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        12.0,
        Paint()
          ..color = AppColors.goldAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Sylwetka roweru z góry (kapsuła pozioma).
    final bikeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      bikeRect,
      Paint()..color = track.jerseyColor,
    );
    canvas.drawRRect(
      bikeRect,
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Numer startowy nad kolarzem.
    _drawText(
      canvas,
      '#${track.bibNumber}',
      Offset(cx - 10, cy - 19),
      isSelected ? AppColors.goldAccent : AppColors.textPrimary,
      fontSize: 10,
      bold: isSelected,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    double fontSize = 11,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant SprintVarOverheadTrackPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.currentDistanceMeters != currentDistanceMeters ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.showToleranceCorridor != showToleranceCorridor ||
        oldDelegate.showRivalGapCaliper != showRivalGapCaliper ||
        oldDelegate.showDistanceGrid != showDistanceGrid;
  }
}

/// Produkcyjne narzędzie powtórki wideo z lotu ptaka (`VAR Sprint Deviation Inspector`).
class SprintVarOverheadReplayInspector extends StatefulWidget {
  final SprintVarOverheadReplayData data;
  final UciRulebookEdition? rulebook;
  final bool isReadOnly;
  final ValueChanged<SprintVarVerdict>? onVerdictConfirmed;
  final VoidCallback? onAppealRequested;
  final VoidCallback? onClose;

  const SprintVarOverheadReplayInspector({
    super.key,
    required this.data,
    this.rulebook,
    this.isReadOnly = false,
    this.onVerdictConfirmed,
    this.onAppealRequested,
    this.onClose,
  });

  @override
  State<SprintVarOverheadReplayInspector> createState() =>
      _SprintVarOverheadReplayInspectorState();
}

class _SprintVarOverheadReplayInspectorState
    extends State<SprintVarOverheadReplayInspector> {
  static const List<double> _speedOptions = [0.25, 0.5, 1.0, 2.0];

  late SprintVarCameraAngle _activeCamera;
  late String? _selectedRiderId;
  late SprintVarVerdict? _activeVerdict;
  double _currentDistanceMeters =
      SprintVarOverheadCalculator.sprintWindowMeters;
  double _playbackSpeed = 0.5;
  bool _isPlaying = false;
  bool _showToleranceCorridor = true;
  bool _showRivalGapCaliper = true;
  bool _showDistanceGrid = true;
  Timer? _playbackTimer;

  final FocusNode _keyboardFocusNode =
      FocusNode(debugLabel: 'SprintVarInspectorKeyboard');

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant SprintVarOverheadReplayInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.incidentId != widget.data.incidentId ||
        oldWidget.data.tracks.length != widget.data.tracks.length) {
      _stopPlayback();
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _activeCamera = widget.data.activeCamera;
    _selectedRiderId = _resolveInitialRiderId();
    _currentDistanceMeters = SprintVarOverheadCalculator.sprintWindowMeters;
    _activeVerdict = _computeInitialVerdict();
  }

  String? _resolveInitialRiderId() {
    if (widget.data.tracks.isEmpty) return null;
    for (final t in widget.data.tracks) {
      if (t.isSuspect) return t.riderId;
    }
    return widget.data.tracks.first.riderId;
  }

  SprintVarVerdict? _computeInitialVerdict() {
    if (widget.data.initialVerdict != null) {
      return widget.data.initialVerdict;
    }
    final input = widget.data.incidentInput;
    if (input == null) return null;
    final rb = widget.rulebook ?? UciRulebookEdition.baseline();
    return const SprintDeviationVarAnalyzer().analyze(
      input: input,
      rulebook: rb,
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (widget.data.tracks.isEmpty) return;
    if (_isPlaying) {
      _stopPlayback();
    } else {
      if (_currentDistanceMeters <= 0.5) {
        _currentDistanceMeters = SprintVarOverheadCalculator.sprintWindowMeters;
      }
      setState(() => _isPlaying = true);
      _playbackTimer?.cancel();
      _playbackTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) {
          if (!mounted) return;
          // ~20 m/s bazowo (~72 km/h) * speed * 0.05 s
          final step = 20.0 * _playbackSpeed * 0.05;
          final nextDist = _currentDistanceMeters - step;
          if (nextDist <= 0.0) {
            setState(() {
              _currentDistanceMeters = 0.0;
              _isPlaying = false;
            });
            _playbackTimer?.cancel();
            _playbackTimer = null;
          } else {
            setState(() => _currentDistanceMeters = nextDist);
          }
        },
      );
    }
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (_isPlaying && mounted) {
      setState(() => _isPlaying = false);
    } else {
      _isPlaying = false;
    }
  }

  void _stepDistance(double deltaMeters) {
    if (widget.data.tracks.isEmpty) return;
    _stopPlayback();
    setState(() {
      _currentDistanceMeters = (_currentDistanceMeters + deltaMeters).clamp(
        0.0,
        SprintVarOverheadCalculator.sprintWindowMeters,
      );
    });
  }

  void _jumpToPeakDeviation() {
    final track = _selectedTrack;
    if (track == null || track.samples.isEmpty) return;
    _stopPlayback();
    final summary = SprintVarOverheadCalculator.summarizeTrack(
      track: track,
      toleranceMeters: widget.data.deviationToleranceMeters,
    );
    setState(() {
      _currentDistanceMeters = summary.peakDeviationDistanceMeters.clamp(
        0.0,
        SprintVarOverheadCalculator.sprintWindowMeters,
      );
    });
  }

  void _applyCommissaireDecision(SprintVarVerdictStatus newStatus) {
    if (widget.isReadOnly || _activeVerdict == null) return;
    final current = _activeVerdict!;
    UciCardType card = UciCardType.none;
    int finalPos = current.originalPosition;
    int fine = 0;
    int pts = 0;
    String rationale;

    switch (newStatus) {
      case SprintVarVerdictStatus.cleanSprint:
        rationale =
            'Kolegium Sędziów VAR zatwierdziło czysty tor jazdy na ostatnich 200 m.';
        break;
      case SprintVarVerdictStatus.warningIssued:
        fine = 200;
        rationale =
            'Oficjalne ostrzeżenie za odchylenie toru bez spowodowania hamowania rywala.';
        break;
      case SprintVarVerdictStatus.yellowCardAndRelegated:
        card = UciCardType.yellow;
        finalPos = math.max(
          current.originalPosition + 1,
          widget.data.incidentInput?.groupEndPosition ?? 25,
        );
        fine = 500;
        pts = 25;
        rationale =
            'Zajechanie drogi rywalowi na ostatnich 200 m: żółta kartka UCI i relegacja na koniec grupy.';
        break;
      case SprintVarVerdictStatus.disqualified:
        card = UciCardType.redDisqualification;
        finalPos = 999;
        fine = 1000;
        pts = 50;
        rationale =
            'Rażące naruszenie bezpieczeństwa sprintu — dyskwalifikacja (DSQ).';
        break;
      case SprintVarVerdictStatus.underReview:
        rationale = 'Incydent pozostaje w trakcie analizy VAR.';
        break;
    }

    final updated = current.copyWith(
      status: newStatus,
      cardIssued: card,
      finalPosition: finalPos,
      fineChf: fine,
      uciPointsDeducted: pts,
      rationalePl: rationale,
    );
    setState(() => _activeVerdict = updated);
    widget.onVerdictConfirmed?.call(updated);
  }

  SprintVarRiderTrack? get _selectedTrack {
    if (widget.data.tracks.isEmpty) return null;
    if (_selectedRiderId != null) {
      for (final t in widget.data.tracks) {
        if (t.riderId == _selectedRiderId) return t;
      }
    }
    return widget.data.tracks.first;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _stepDistance(-5.0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _stepDistance(5.0);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final hasTracks = widget.data.tracks.isNotEmpty;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            final isWideDesktop = constraints.maxWidth >= 1120;

            return Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isCompact),
                  const SizedBox(height: 12),
                  if (!hasTracks)
                    _buildEmptyState()
                  else if (isWideDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildOverheadViewport(height: 320),
                              const SizedBox(height: 12),
                              _buildPlaybackControls(isCompact: false),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRiderSelectorAndTelemetry(isCompact: false),
                              const SizedBox(height: 12),
                              _buildVerdictPanel(isCompact: false),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOverheadViewport(height: isCompact ? 230 : 280),
                        const SizedBox(height: 12),
                        _buildPlaybackControls(isCompact: isCompact),
                        const SizedBox(height: 12),
                        _buildRiderSelectorAndTelemetry(isCompact: isCompact),
                        const SizedBox(height: 12),
                        _buildVerdictPanel(isCompact: isCompact),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final titleRow = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.videocam_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VAR Sprint Deviation Inspector',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${widget.data.stageName} • Tolerancja ±${widget.data.deviationToleranceMeters.toStringAsFixed(2)} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final trailingActions = <Widget>[
      if (widget.isReadOnly)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Text(
            'TYLKO PODGLĄD',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      if (widget.onClose != null) ...[
        if (widget.isReadOnly) const SizedBox(width: 8),
        _VarActionButton(
          label: 'Zamknij',
          icon: Icons.close_rounded,
          onPressed: widget.onClose,
          compact: true,
        ),
      ],
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleRow,
          if (trailingActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: trailingActions,
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleRow),
        ...trailingActions,
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_off_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Brak danych powtórki VAR dla ostatnich 200 m',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.data.notesPl.isNotEmpty
                ? widget.data.notesPl
                : 'Zarejestruj finisz sprinterski, aby przeanalizować tor jazdy kolarzy.',
            textAlign: TextAlign.center,
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

  Widget _buildOverheadViewport({required double height}) {
    final effectiveData = widget.data.copyWith(activeCamera: _activeCamera);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.data.availableCameras.map((cam) {
                    final selected = cam == _activeCamera;
                    return _VarFilterChip(
                      label: _shortCameraLabel(cam),
                      selected: selected,
                      onSelected: (_) => setState(() => _activeCamera = cam),
                    );
                  }).toList(),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _VarFilterChip(
                      label: 'Korytarz',
                      selected: _showToleranceCorridor,
                      onSelected: (v) =>
                          setState(() => _showToleranceCorridor = v),
                    ),
                    _VarFilterChip(
                      label: 'Odstęp',
                      selected: _showRivalGapCaliper,
                      onSelected: (v) =>
                          setState(() => _showRivalGapCaliper = v),
                    ),
                    _VarFilterChip(
                      label: 'Siatka',
                      selected: _showDistanceGrid,
                      onSelected: (v) => setState(() => _showDistanceGrid = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: SprintVarOverheadTrackPainter(
                  data: effectiveData,
                  currentDistanceMeters: _currentDistanceMeters,
                  selectedRiderId: _selectedRiderId,
                  showToleranceCorridor: _showToleranceCorridor,
                  showRivalGapCaliper: _showRivalGapCaliper,
                  showDistanceGrid: _showDistanceGrid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortCameraLabel(SprintVarCameraAngle cam) {
    switch (cam) {
      case SprintVarCameraAngle.overheadHelicopter:
        return 'Helikopter';
      case SprintVarCameraAngle.finishLineHeadOn:
        return 'Linia mety';
      case SprintVarCameraAngle.rearPelotonCam:
        return 'Motocykl';
      case SprintVarCameraAngle.sideBarrierTracking:
        return 'Barierki';
    }
  }

  Widget _buildPlaybackControls({required bool isCompact}) {
    final sliderValue =
        SprintVarOverheadCalculator.sprintWindowMeters - _currentDistanceMeters;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '200 m',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${_currentDistanceMeters.toStringAsFixed(1)} m do mety',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Text(
                '0 m',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: sliderValue.clamp(
                0.0,
                SprintVarOverheadCalculator.sprintWindowMeters,
              ),
              min: 0.0,
              max: SprintVarOverheadCalculator.sprintWindowMeters,
              onChanged: (v) {
                _stopPlayback();
                setState(() {
                  _currentDistanceMeters =
                      SprintVarOverheadCalculator.sprintWindowMeters - v;
                });
              },
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _VarActionButton(
                    label: '-5m',
                    icon: Icons.fast_rewind_rounded,
                    onPressed: () => _stepDistance(5.0),
                    compact: true,
                  ),
                  _VarActionButton(
                    label: _isPlaying ? 'Pauza' : 'Odtwórz',
                    icon: _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    isPrimary: true,
                    onPressed: _togglePlayPause,
                    compact: true,
                  ),
                  _VarActionButton(
                    label: '+5m',
                    icon: Icons.fast_forward_rounded,
                    onPressed: () => _stepDistance(-5.0),
                    compact: true,
                  ),
                  _VarActionButton(
                    label: isCompact ? 'Szczyt' : 'Max odchylenie',
                    icon: Icons.crisis_alert_rounded,
                    onPressed: _jumpToPeakDeviation,
                    compact: true,
                  ),
                ],
              ),
              Wrap(
                spacing: 4,
                children: _speedOptions.map((spd) {
                  return _VarFilterChip(
                    label: '${spd}x',
                    selected: _playbackSpeed == spd,
                    onSelected: (_) => setState(() => _playbackSpeed = spd),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderSelectorAndTelemetry({required bool isCompact}) {
    final track = _selectedTrack;
    if (track == null) return const SizedBox.shrink();

    final point = SprintVarOverheadCalculator.interpolateAtDistance(
      samples: track.samples,
      distanceToFinishMeters: _currentDistanceMeters,
      toleranceMeters: widget.data.deviationToleranceMeters,
    );
    final summary = SprintVarOverheadCalculator.summarizeTrack(
      track: track,
      toleranceMeters: widget.data.deviationToleranceMeters,
    );

    final zoneColor = _zoneColor(point.zoneLevel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'TORY JAZDY SPRINTERÓW',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.data.tracks.map((t) {
              final isSelected = t.riderId == track.riderId;
              return _VarFilterChip(
                label: '#${t.bibNumber} ${t.riderName}',
                selected: isSelected,
                accentColor: t.jerseyColor,
                onSelected: (_) => setState(() => _selectedRiderId = t.riderId),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TelemetryMetricTile(
                label: 'Odchylenie (teraz)',
                value:
                    '${point.deviationFromBaselineMeters.toStringAsFixed(2)} m',
                accent: zoneColor,
                compact: isCompact,
              ),
              _TelemetryMetricTile(
                label: 'Max odchylenie',
                value: '${summary.maxDeviationMeters.toStringAsFixed(2)} m',
                accent: _zoneColor(summary.worstZone),
                compact: isCompact,
              ),
              _TelemetryMetricTile(
                label: 'Odstęp do rywala',
                value:
                    '${point.nearestRivalClearanceMeters.toStringAsFixed(2)} m',
                accent: point.nearestRivalClearanceMeters < 0.45
                    ? AppColors.crimsonAlert
                    : AppColors.accentBlue,
                compact: isCompact,
              ),
              _TelemetryMetricTile(
                label: 'Prędkość / Boczna',
                value:
                    '${point.speedKmh.toStringAsFixed(1)} km/h (${point.lateralVelocityMps.toStringAsFixed(2)} m/s)',
                accent: AppColors.textPrimary,
                compact: isCompact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictPanel({required bool isCompact}) {
    final verdict = _activeVerdict;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'WERDYKT KOLEGIUM VAR',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (verdict != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _verdictColor(verdict.status).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _verdictColor(verdict.status).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Pewność ${(verdict.varConfidenceScore * 100).round()}%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _verdictColor(verdict.status),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (verdict == null)
            Text(
              widget.data.notesPl.isNotEmpty
                  ? widget.data.notesPl
                  : 'Wybierz incydent sprinterski z analizą VAR, aby wydać werdykt.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            Text(
              verdict.status.displayNamePl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isCompact ? 14 : 15,
                fontWeight: FontWeight.w700,
                color: _verdictColor(verdict.status),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              verdict.rationalePl,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _MiniTag(
                  label: 'Ocena linii: ${verdict.lineHoldingScore.round()}/100',
                ),
                _MiniTag(
                  label:
                      'Pozycja: #${verdict.originalPosition} → #${verdict.finalPosition}',
                ),
                if (verdict.fineChf > 0)
                  _MiniTag(label: 'Grzywna: ${verdict.fineChf} CHF'),
                if (verdict.cardIssued != UciCardType.none)
                  _MiniTag(
                    label: verdict.cardIssued == UciCardType.yellow
                        ? 'Żółta kartka UCI'
                        : 'Czerwona kartka DSQ',
                    color: verdict.cardIssued == UciCardType.yellow
                        ? AppColors.amberWarning
                        : AppColors.crimsonAlert,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _VarActionButton(
                  label: 'Czysty sprint',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: widget.isReadOnly
                      ? null
                      : () => _applyCommissaireDecision(
                            SprintVarVerdictStatus.cleanSprint,
                          ),
                  compact: true,
                ),
                _VarActionButton(
                  label: 'Ostrzeżenie',
                  icon: Icons.warning_amber_rounded,
                  onPressed: widget.isReadOnly
                      ? null
                      : () => _applyCommissaireDecision(
                            SprintVarVerdictStatus.warningIssued,
                          ),
                  compact: true,
                ),
                _VarActionButton(
                  label: 'Relegacja + Kartka',
                  icon: Icons.gavel_rounded,
                  isDanger: true,
                  onPressed: widget.isReadOnly
                      ? null
                      : () => _applyCommissaireDecision(
                            SprintVarVerdictStatus.yellowCardAndRelegated,
                          ),
                  compact: true,
                ),
                if (verdict.isAppealable)
                  _VarActionButton(
                    label: 'Złóż odwołanie',
                    icon: Icons.policy_outlined,
                    onPressed:
                        widget.isReadOnly ? null : widget.onAppealRequested,
                    compact: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _zoneColor(SprintDeviationZoneLevel level) {
    switch (level) {
      case SprintDeviationZoneLevel.clean:
        return AppColors.statusSuccess;
      case SprintDeviationZoneLevel.warning:
        return AppColors.amberWarning;
      case SprintDeviationZoneLevel.violation:
        return AppColors.crimsonAlert;
    }
  }

  Color _verdictColor(SprintVarVerdictStatus status) {
    switch (status) {
      case SprintVarVerdictStatus.cleanSprint:
        return AppColors.statusSuccess;
      case SprintVarVerdictStatus.underReview:
        return AppColors.accentBlue;
      case SprintVarVerdictStatus.warningIssued:
        return AppColors.amberWarning;
      case SprintVarVerdictStatus.yellowCardAndRelegated:
      case SprintVarVerdictStatus.disqualified:
        return AppColors.crimsonAlert;
    }
  }
}

class _TelemetryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool compact;

  const _TelemetryMetricTile({
    required this.label,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
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
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({
    required this.label,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _VarFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color? accentColor;
  final ValueChanged<bool> onSelected;

  const _VarFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accentColor,
  });

  @override
  State<_VarFilterChip> createState() => _VarFilterChipState();
}

class _VarFilterChipState extends State<_VarFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.accentColor ?? AppColors.goldAccent;
    final bg = widget.selected
        ? activeColor.withValues(alpha: _pressed ? 0.28 : 0.18)
        : (_hovered
            ? AppColors.surfaceLight
            : AppColors.surface);
    final borderColor = _focused
        ? AppColors.cyanAccent
        : widget.selected
            ? activeColor
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () => widget.onSelected(!widget.selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VarActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDanger;
  final bool compact;

  const _VarActionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
    this.compact = false,
  });

  @override
  State<_VarActionButton> createState() => _VarActionButtonState();
}

class _VarActionButtonState extends State<_VarActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final baseAccent = widget.isDanger
        ? AppColors.crimsonAlert
        : widget.isPrimary
            ? AppColors.goldAccent
            : AppColors.primaryAccent;

    final Color bg;
    if (!enabled) {
      bg = AppColors.surface.withValues(alpha: 0.5);
    } else if (widget.isPrimary || widget.isDanger) {
      bg = baseAccent.withValues(
        alpha: _pressed ? 0.35 : (_hovered ? 0.28 : 0.2),
      );
    } else {
      bg = _pressed
          ? AppColors.cardBorder
          : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    }

    final borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.cyanAccent
            : (widget.isPrimary || widget.isDanger)
                ? baseAccent
                : (_hovered ? AppColors.textSecondary : AppColors.cardBorder);

    final fg = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : (widget.isPrimary || widget.isDanger)
            ? baseAccent
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
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
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
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
