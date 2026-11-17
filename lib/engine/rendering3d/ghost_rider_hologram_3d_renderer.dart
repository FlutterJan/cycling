// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TRYBY DYSCYPLINY, STYLE HOLOGRAMU I STATUS POJEDYNKU RAMIĘ W RAMIĘ
// =============================================================================

/// Dyscyplina, w której wyświetlany jest złoty hologram rekordzisty trasy.
enum GhostHologramDiscipline {
  individualTimeTrial(
    labelPl: 'Jazda na czas (ITT)',
    shortTag: 'ITT',
    icon: Icons.timer_outlined,
  ),
  velodromeHourRecord(
    labelPl: 'Rekord Godzinny (Tor)',
    shortTag: '1H TOR',
    icon: Icons.track_changes_rounded,
  ),
  komClimb(
    labelPl: 'Podjazd KOM',
    shortTag: 'KOM',
    icon: Icons.landscape_rounded,
  );

  final String labelPl;
  final String shortTag;
  final IconData icon;

  const GhostHologramDiscipline({
    required this.labelPl,
    required this.shortTag,
    required this.icon,
  });

  String toJson() => name;

  static GhostHologramDiscipline fromJson(String value) {
    return GhostHologramDiscipline.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => GhostHologramDiscipline.individualTimeTrial,
    );
  }
}

/// Styl wizualny półprzezroczystego złotego hologramu w silniku 3D.
enum GhostHologramVisualStyle {
  goldenWireframe(
    labelPl: 'Złoty Hologram',
    descriptionPl: 'Półprzezroczyste złoto #D4AF37 z liniami skanowania',
  ),
  telemetryPulse(
    labelPl: 'Puls Telemetryczny',
    descriptionPl: 'Złoty rdzeń z obrysem telemetrii #00E5FF',
  ),
  minimalSilhouette(
    labelPl: 'Subtelna Sylwetka',
    descriptionPl: 'Dyskretna sylwetka bez linii skanowania',
  );

  final String labelPl;
  final String descriptionPl;

  const GhostHologramVisualStyle({
    required this.labelPl,
    required this.descriptionPl,
  });
}

/// Status pojedynku ramię w ramię z historycznym rekordzistą trasy.
enum GhostHologramSideBySideStatus {
  aheadOfPlayer('DUCH Z PRZODU', AppColors.crimsonAlert),
  neckAndNeck('RAMIĘ W RAMIĘ', AppColors.goldAccent),
  behindPlayer('MASZ PRZEWAGĘ', AppColors.statusSuccess),
  standby('OCZEKIWANIE', AppColors.textSecondary);

  final String labelPl;
  final Color accentColor;

  const GhostHologramSideBySideStatus(this.labelPl, this.accentColor);
}

// =============================================================================
// 2. MODELE DANYCH HISTORYCZNEGO PRZEJAZDU I KONFIGURACJA HOLOGRAMU
// =============================================================================

/// Pojedyncza próbka historycznego przejazdu rekordzisty trasy.
@immutable
class GhostRiderHistoricalSample {
  final double elapsedSeconds;
  final double distanceMeters;
  final double speedMs;
  final double powerWatts;
  final double cadenceRpm;
  final double lateralOffsetMeters;
  final double gradientPercent;
  final bool isStanding;
  final double leanAngleRadians;

  const GhostRiderHistoricalSample({
    required this.elapsedSeconds,
    required this.distanceMeters,
    required this.speedMs,
    required this.powerWatts,
    required this.cadenceRpm,
    this.lateralOffsetMeters = 0.0,
    this.gradientPercent = 0.0,
    this.isStanding = false,
    this.leanAngleRadians = 0.0,
  });

  /// Liniowa interpolacja pomiędzy dwiema próbkami telemetrycznymi.
  static GhostRiderHistoricalSample lerp(
    GhostRiderHistoricalSample a,
    GhostRiderHistoricalSample b,
    double t,
  ) {
    final double clampedT = t.clamp(0.0, 1.0);
    return GhostRiderHistoricalSample(
      elapsedSeconds:
          a.elapsedSeconds + (b.elapsedSeconds - a.elapsedSeconds) * clampedT,
      distanceMeters:
          a.distanceMeters + (b.distanceMeters - a.distanceMeters) * clampedT,
      speedMs: a.speedMs + (b.speedMs - a.speedMs) * clampedT,
      powerWatts: a.powerWatts + (b.powerWatts - a.powerWatts) * clampedT,
      cadenceRpm: a.cadenceRpm + (b.cadenceRpm - a.cadenceRpm) * clampedT,
      lateralOffsetMeters:
          a.lateralOffsetMeters +
          (b.lateralOffsetMeters - a.lateralOffsetMeters) * clampedT,
      gradientPercent:
          a.gradientPercent + (b.gradientPercent - a.gradientPercent) * clampedT,
      isStanding: clampedT < 0.5 ? a.isStanding : b.isStanding,
      leanAngleRadians:
          a.leanAngleRadians +
          (b.leanAngleRadians - a.leanAngleRadians) * clampedT,
    );
  }

  Map<String, dynamic> toJson() => {
    'elapsedSeconds': elapsedSeconds,
    'distanceMeters': distanceMeters,
    'speedMs': speedMs,
    'powerWatts': powerWatts,
    'cadenceRpm': cadenceRpm,
    'lateralOffsetMeters': lateralOffsetMeters,
    'gradientPercent': gradientPercent,
    'isStanding': isStanding,
    'leanAngleRadians': leanAngleRadians,
  };

  factory GhostRiderHistoricalSample.fromJson(Map<String, dynamic> json) {
    return GhostRiderHistoricalSample(
      elapsedSeconds: (json['elapsedSeconds'] as num).toDouble(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      speedMs: (json['speedMs'] as num).toDouble(),
      powerWatts: (json['powerWatts'] as num).toDouble(),
      cadenceRpm: (json['cadenceRpm'] as num).toDouble(),
      lateralOffsetMeters:
          (json['lateralOffsetMeters'] as num?)?.toDouble() ?? 0.0,
      gradientPercent: (json['gradientPercent'] as num?)?.toDouble() ?? 0.0,
      isStanding: json['isStanding'] as bool? ?? false,
      leanAngleRadians: (json['leanAngleRadians'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Profil historycznego rekordu trasy używany przez [GhostRiderHologram3dRenderer].
@immutable
class GhostRiderRecordProfile {
  final String recordId;
  final String riderName;
  final String teamCode;
  final int recordYear;
  final GhostHologramDiscipline discipline;
  final String courseOrSegmentName;
  final double totalDistanceMeters;
  final double targetTimeSeconds;
  final double averageSpeedKmh;
  final double averagePowerWatts;
  final List<GhostRiderHistoricalSample> samples;

  const GhostRiderRecordProfile({
    required this.recordId,
    required this.riderName,
    required this.teamCode,
    required this.recordYear,
    required this.discipline,
    required this.courseOrSegmentName,
    required this.totalDistanceMeters,
    required this.targetTimeSeconds,
    required this.averageSpeedKmh,
    required this.averagePowerWatts,
    required this.samples,
  });

  /// Preset: Mistrzostwa Świata ITT.
  factory GhostRiderRecordProfile.ittWorldChampionshipPreset() {
    const double totalDist = 42500.0;
    const double targetTime = 2850.0; // 47:30 (~53.68 km/h)
    const double avgSpeedMs = totalDist / targetTime;
    return GhostRiderRecordProfile(
      recordId: 'itt_wc_zurich_record',
      riderName: 'R. Evenepoel',
      teamCode: 'SOQ',
      recordYear: 2024,
      discipline: GhostHologramDiscipline.individualTimeTrial,
      courseOrSegmentName: 'Mistrzostwa Świata ITT • 42.5 km',
      totalDistanceMeters: totalDist,
      targetTimeSeconds: targetTime,
      averageSpeedKmh: avgSpeedMs * 3.6,
      averagePowerWatts: 445.0,
      samples: List<GhostRiderHistoricalSample>.generate(12, (int i) {
        final double frac = i / 11.0;
        final double t = targetTime * frac;
        final double speedVariation = math.sin(frac * math.pi * 3.0) * 0.65;
        final double speedMs = avgSpeedMs + speedVariation;
        return GhostRiderHistoricalSample(
          elapsedSeconds: t,
          distanceMeters: totalDist * frac,
          speedMs: speedMs,
          powerWatts: 445.0 + math.sin(frac * math.pi * 3.0) * 18.0,
          cadenceRpm: 96.0 + math.cos(frac * math.pi * 2.0) * 2.0,
          lateralOffsetMeters: -0.55,
          gradientPercent: math.sin(frac * math.pi * 2.0) * 1.4,
          isStanding: false,
          leanAngleRadians: 0.0,
        );
      }),
    );
  }

  /// Preset: Rekord Godzinny UCI na welodromie w Grenchen (56.792 km).
  factory GhostRiderRecordProfile.velodromeHourRecordPreset() {
    const double totalDist = 56792.0;
    const double targetTime = 3600.0;
    const double avgSpeedMs = totalDist / targetTime;
    return GhostRiderRecordProfile(
      recordId: 'uci_hour_record_grenchen',
      riderName: 'F. Ganna',
      teamCode: 'IGD',
      recordYear: 2022,
      discipline: GhostHologramDiscipline.velodromeHourRecord,
      courseOrSegmentName: 'Rekord Godzinny UCI • Grenchen 250m',
      totalDistanceMeters: totalDist,
      targetTimeSeconds: targetTime,
      averageSpeedKmh: avgSpeedMs * 3.6,
      averagePowerWatts: 462.0,
      samples: List<GhostRiderHistoricalSample>.generate(16, (int i) {
        final double frac = i / 15.0;
        final double t = targetTime * frac;
        final double negativeSplit = (frac - 0.5) * 0.35;
        return GhostRiderHistoricalSample(
          elapsedSeconds: t,
          distanceMeters: totalDist * frac,
          speedMs: avgSpeedMs + negativeSplit,
          powerWatts: 462.0 + negativeSplit * 22.0,
          cadenceRpm: 102.0,
          lateralOffsetMeters: -0.85,
          gradientPercent: 0.0,
          isStanding: false,
          leanAngleRadians: 0.38,
        );
      }),
    );
  }

  /// Preset: Rekord podjazdu KOM na Alpe d'Huez (13.8 km, 8.1%).
  factory GhostRiderRecordProfile.alpeDhuezKomPreset() {
    const double totalDist = 13800.0;
    const double targetTime = 2255.0; // 37:35
    const double avgSpeedMs = totalDist / targetTime;
    return GhostRiderRecordProfile(
      recordId: 'kom_alpe_dhuez_record',
      riderName: 'M. Pantani',
      teamCode: 'MER',
      recordYear: 1997,
      discipline: GhostHologramDiscipline.komClimb,
      courseOrSegmentName: 'Alpe d\'Huez KOM • 13.8 km (8.1%)',
      totalDistanceMeters: totalDist,
      targetTimeSeconds: targetTime,
      averageSpeedKmh: avgSpeedMs * 3.6,
      averagePowerWatts: 418.0,
      samples: List<GhostRiderHistoricalSample>.generate(14, (int i) {
        final double frac = i / 13.0;
        final double t = targetTime * frac;
        final bool steepSection = frac > 0.15 && frac < 0.72;
        final double speedMs = avgSpeedMs + (steepSection ? -0.45 : 0.65);
        return GhostRiderHistoricalSample(
          elapsedSeconds: t,
          distanceMeters: totalDist * frac,
          speedMs: speedMs,
          powerWatts: steepSection ? 432.0 : 405.0,
          cadenceRpm: steepSection ? 78.0 : 88.0,
          lateralOffsetMeters: 0.75,
          gradientPercent: steepSection ? 9.6 : 6.8,
          isStanding: steepSection && (i % 2 == 1),
          leanAngleRadians: 0.0,
        );
      }),
    );
  }

  Map<String, dynamic> toJson() => {
    'recordId': recordId,
    'riderName': riderName,
    'teamCode': teamCode,
    'recordYear': recordYear,
    'discipline': discipline.toJson(),
    'courseOrSegmentName': courseOrSegmentName,
    'totalDistanceMeters': totalDistanceMeters,
    'targetTimeSeconds': targetTimeSeconds,
    'averageSpeedKmh': averageSpeedKmh,
    'averagePowerWatts': averagePowerWatts,
    'samples': samples.map((e) => e.toJson()).toList(),
  };

  factory GhostRiderRecordProfile.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSamples =
        json['samples'] as List<dynamic>? ?? const [];
    return GhostRiderRecordProfile(
      recordId: json['recordId'] as String,
      riderName: json['riderName'] as String,
      teamCode: json['teamCode'] as String? ?? 'REC',
      recordYear: (json['recordYear'] as num?)?.toInt() ?? 2024,
      discipline: GhostHologramDiscipline.fromJson(
        json['discipline'] as String? ?? 'individualTimeTrial',
      ),
      courseOrSegmentName: json['courseOrSegmentName'] as String? ?? '',
      totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
      targetTimeSeconds: (json['targetTimeSeconds'] as num).toDouble(),
      averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
      averagePowerWatts: (json['averagePowerWatts'] as num).toDouble(),
      samples: rawSamples
          .map(
            (e) =>
                GhostRiderHistoricalSample.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

/// Konfiguracja wizualna i zachowania złotego hologramu rekordzisty trasy.
@immutable
class GhostRiderHologramConfig {
  final bool enabled;
  final GhostHologramVisualStyle visualStyle;
  final double baseOpacity;
  final bool showScanlines;
  final bool showGroundTrailRibbon;
  final bool showFloatingCrownTag;
  final bool showDeltaGapLine;
  final double proximityFadeMeters;
  final double lateralLaneOffsetMeters;
  final double maxVisibleRangeMeters;

  const GhostRiderHologramConfig({
    this.enabled = true,
    this.visualStyle = GhostHologramVisualStyle.goldenWireframe,
    this.baseOpacity = 0.54,
    this.showScanlines = true,
    this.showGroundTrailRibbon = true,
    this.showFloatingCrownTag = true,
    this.showDeltaGapLine = true,
    this.proximityFadeMeters = 1.2,
    this.lateralLaneOffsetMeters = 1.15,
    this.maxVisibleRangeMeters = 240.0,
  });

  GhostRiderHologramConfig copyWith({
    bool? enabled,
    GhostHologramVisualStyle? visualStyle,
    double? baseOpacity,
    bool? showScanlines,
    bool? showGroundTrailRibbon,
    bool? showFloatingCrownTag,
    bool? showDeltaGapLine,
    double? proximityFadeMeters,
    double? lateralLaneOffsetMeters,
    double? maxVisibleRangeMeters,
  }) {
    return GhostRiderHologramConfig(
      enabled: enabled ?? this.enabled,
      visualStyle: visualStyle ?? this.visualStyle,
      baseOpacity: (baseOpacity ?? this.baseOpacity).clamp(0.15, 0.85),
      showScanlines: showScanlines ?? this.showScanlines,
      showGroundTrailRibbon:
          showGroundTrailRibbon ?? this.showGroundTrailRibbon,
      showFloatingCrownTag: showFloatingCrownTag ?? this.showFloatingCrownTag,
      showDeltaGapLine: showDeltaGapLine ?? this.showDeltaGapLine,
      proximityFadeMeters: proximityFadeMeters ?? this.proximityFadeMeters,
      lateralLaneOffsetMeters:
          lateralLaneOffsetMeters ?? this.lateralLaneOffsetMeters,
      maxVisibleRangeMeters:
          maxVisibleRangeMeters ?? this.maxVisibleRangeMeters,
    );
  }
}

/// Próbka śladu świetlnego ciągnącego się za hologramem na asfalcie/parkiecie.
@immutable
class GhostTrailSample {
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final double alphaFactor;

  const GhostTrailSample({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.elevationMeters,
    required this.alphaFactor,
  });
}

/// Dane wejściowe pojedynczej klatki symulacji dla [GhostRiderHologram3dRenderer].
@immutable
class GhostRiderHologramFrameInput {
  final double playerDistanceMeters;
  final double playerElapsedSeconds;
  final double playerSpeedMs;
  final double playerLateralOffsetMeters;
  final double playerElevationMeters;
  final double playerGradientPercent;
  final double animationTimeSeconds;
  final bool isVelodrome;
  final double velodromeTrackLengthMeters;
  final double velodromeBankingAngleRadians;

  const GhostRiderHologramFrameInput({
    required this.playerDistanceMeters,
    required this.playerElapsedSeconds,
    required this.playerSpeedMs,
    this.playerLateralOffsetMeters = 0.0,
    this.playerElevationMeters = 0.0,
    this.playerGradientPercent = 0.0,
    this.animationTimeSeconds = 0.0,
    this.isVelodrome = false,
    this.velodromeTrackLengthMeters = 250.0,
    this.velodromeBankingAngleRadians = 0.733, // ~42 deg
  });
}

/// Wyliczony stan klatki złotego hologramu gotowy do rzutowania i rysowania w 3D.
@immutable
class GhostRiderHologramFrameState {
  final bool isVisible;
  final GhostHologramDiscipline discipline;
  final String recordHolderName;
  final String recordHolderTeamCode;
  final int recordYear;
  final double ghostDistanceMeters;
  final double ghostTrackWrappedDistanceMeters;
  final double ghostLateralOffsetMeters;
  final double ghostElevationMeters;
  final double ghostSpeedMs;
  final double ghostPowerWatts;
  final double ghostCadenceRpm;
  final double ghostCrankAngleRadians;
  final double ghostLeanAngleRadians;
  final bool isGhostStanding;
  final double distanceGapMeters;
  final double timeDeltaSeconds;
  final GhostHologramSideBySideStatus sideBySideStatus;
  final double effectiveOpacity;
  final double scanlinePhase;
  final List<GhostTrailSample> trailSamples;

  const GhostRiderHologramFrameState({
    required this.isVisible,
    required this.discipline,
    required this.recordHolderName,
    required this.recordHolderTeamCode,
    required this.recordYear,
    required this.ghostDistanceMeters,
    required this.ghostTrackWrappedDistanceMeters,
    required this.ghostLateralOffsetMeters,
    required this.ghostElevationMeters,
    required this.ghostSpeedMs,
    required this.ghostPowerWatts,
    required this.ghostCadenceRpm,
    required this.ghostCrankAngleRadians,
    required this.ghostLeanAngleRadians,
    required this.isGhostStanding,
    required this.distanceGapMeters,
    required this.timeDeltaSeconds,
    required this.sideBySideStatus,
    required this.effectiveOpacity,
    required this.scanlinePhase,
    required this.trailSamples,
  });
}

// =============================================================================
// 3. GŁÓWNY SILNIK INTERPOLACJI I RENDERER 3D ZŁOTEGO HOLOGRAMU
// =============================================================================

/// Silnik renderowania półprzezroczystego złotego hologramu rekordzisty trasy 3D.
///
/// Obsługuje:
/// - Jazdę indywidualną na czas (ITT) z pozycją aero i pełnym dyskiem tylnym,
/// - Próbę Rekordu Godzinnego na welodromie 250 m z zawijaniem okrążeń i przechyłem wirażu,
/// - Podjazdy KOM z dynamiczną kadencją, jazdą na stojąco i koroną rekordzisty.
class GhostRiderHologram3dRenderer {
  GhostRiderRecordProfile _recordProfile;
  GhostRiderHologramConfig _config;

  GhostRiderHologram3dRenderer({
    required GhostRiderRecordProfile recordProfile,
    GhostRiderHologramConfig config = const GhostRiderHologramConfig(),
  }) : _recordProfile = recordProfile,
       _config = config;

  GhostRiderRecordProfile get recordProfile => _recordProfile;
  GhostRiderHologramConfig get config => _config;

  void updateProfile(GhostRiderRecordProfile profile) {
    _recordProfile = profile;
  }

  void updateConfig(GhostRiderHologramConfig config) {
    _config = config;
  }

  /// Wylicza próbkę historyczną rekordzisty w zadanym czasie [elapsedSeconds].
  GhostRiderHistoricalSample sampleAtElapsedTime(double elapsedSeconds) {
    final List<GhostRiderHistoricalSample> samples = _recordProfile.samples;
    final double clampedTime = elapsedSeconds.clamp(
      0.0,
      math.max(0.001, _recordProfile.targetTimeSeconds),
    );

    if (samples.isEmpty) {
      final double targetTime = math.max(1.0, _recordProfile.targetTimeSeconds);
      final double avgSpeed = _recordProfile.totalDistanceMeters / targetTime;
      return GhostRiderHistoricalSample(
        elapsedSeconds: clampedTime,
        distanceMeters: avgSpeed * clampedTime,
        speedMs: avgSpeed,
        powerWatts: _recordProfile.averagePowerWatts,
        cadenceRpm:
            _recordProfile.discipline ==
                GhostHologramDiscipline.velodromeHourRecord
            ? 102.0
            : 92.0,
      );
    }

    if (clampedTime <= samples.first.elapsedSeconds) {
      return samples.first;
    }
    if (clampedTime >= samples.last.elapsedSeconds) {
      return samples.last;
    }

    int low = 0;
    int high = samples.length - 1;
    while (low + 1 < high) {
      final int mid = (low + high) >> 1;
      if (samples[mid].elapsedSeconds <= clampedTime) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final GhostRiderHistoricalSample a = samples[low];
    final GhostRiderHistoricalSample b = samples[high];
    final double span = b.elapsedSeconds - a.elapsedSeconds;
    if (span <= 1e-6) {
      return a;
    }
    final double t = (clampedTime - a.elapsedSeconds) / span;
    return GhostRiderHistoricalSample.lerp(a, b, t);
  }

  /// Szacuje historyczny czas przejazdu rekordzisty na dystansie [distanceMeters].
  double estimateElapsedAtDistance(double distanceMeters) {
    final List<GhostRiderHistoricalSample> samples = _recordProfile.samples;
    final double clampedDist = distanceMeters.clamp(
      0.0,
      math.max(0.001, _recordProfile.totalDistanceMeters),
    );

    if (samples.isEmpty) {
      final double totalDist = math.max(1.0, _recordProfile.totalDistanceMeters);
      return (clampedDist / totalDist) * _recordProfile.targetTimeSeconds;
    }

    if (clampedDist <= samples.first.distanceMeters) {
      return samples.first.elapsedSeconds;
    }
    if (clampedDist >= samples.last.distanceMeters) {
      return samples.last.elapsedSeconds;
    }

    int low = 0;
    int high = samples.length - 1;
    while (low + 1 < high) {
      final int mid = (low + high) >> 1;
      if (samples[mid].distanceMeters <= clampedDist) {
        low = mid;
      } else {
        high = mid;
      }
    }

    final GhostRiderHistoricalSample a = samples[low];
    final GhostRiderHistoricalSample b = samples[high];
    final double span = b.distanceMeters - a.distanceMeters;
    if (span <= 1e-6) {
      return a.elapsedSeconds;
    }
    final double t = (clampedDist - a.distanceMeters) / span;
    return a.elapsedSeconds + (b.elapsedSeconds - a.elapsedSeconds) * t;
  }

  /// Oblicza kompletny stan klatki 3D hologramu dla bieżącej pozycji gracza.
  GhostRiderHologramFrameState evaluateFrame(
    GhostRiderHologramFrameInput input,
  ) {
    if (!_config.enabled) {
      return GhostRiderHologramFrameState(
        isVisible: false,
        discipline: _recordProfile.discipline,
        recordHolderName: _recordProfile.riderName,
        recordHolderTeamCode: _recordProfile.teamCode,
        recordYear: _recordProfile.recordYear,
        ghostDistanceMeters: 0.0,
        ghostTrackWrappedDistanceMeters: 0.0,
        ghostLateralOffsetMeters: 0.0,
        ghostElevationMeters: input.playerElevationMeters,
        ghostSpeedMs: 0.0,
        ghostPowerWatts: 0.0,
        ghostCadenceRpm: 0.0,
        ghostCrankAngleRadians: 0.0,
        ghostLeanAngleRadians: 0.0,
        isGhostStanding: false,
        distanceGapMeters: 0.0,
        timeDeltaSeconds: 0.0,
        sideBySideStatus: GhostHologramSideBySideStatus.standby,
        effectiveOpacity: 0.0,
        scanlinePhase: 0.0,
        trailSamples: const [],
      );
    }

    final GhostRiderHistoricalSample ghostSample = sampleAtElapsedTime(
      input.playerElapsedSeconds,
    );

    final double distanceGapMeters =
        ghostSample.distanceMeters - input.playerDistanceMeters;
    final double ghostElapsedAtPlayerDist = estimateElapsedAtDistance(
      input.playerDistanceMeters,
    );
    // Dodatnia delta = gracz jedzie wolniej od rekordu; ujemna = gracz ma przewagę.
    final double timeDeltaSeconds =
        input.playerElapsedSeconds - ghostElapsedAtPlayerDist;

    final GhostHologramSideBySideStatus status;
    if (input.playerElapsedSeconds <= 0.1 && input.playerDistanceMeters <= 0.5) {
      status = GhostHologramSideBySideStatus.standby;
    } else if (distanceGapMeters.abs() <= 2.5 || timeDeltaSeconds.abs() <= 0.25) {
      status = GhostHologramSideBySideStatus.neckAndNeck;
    } else if (distanceGapMeters > 0.0) {
      status = GhostHologramSideBySideStatus.aheadOfPlayer;
    } else {
      status = GhostHologramSideBySideStatus.behindPlayer;
    }

    // Delikatne odsunięcie toru jazdy podczas walki ramię w ramię,
    // aby złoty hologram nie nakładał się bezpośrednio na kolarza gracza.
    double resolvedLateralOffset = ghostSample.lateralOffsetMeters;
    final double lateralDiff =
        resolvedLateralOffset - input.playerLateralOffsetMeters;
    if (distanceGapMeters.abs() < 6.0 && lateralDiff.abs() < 0.85) {
      final double sign = lateralDiff >= 0.0 ? 1.0 : -1.0;
      resolvedLateralOffset =
          input.playerLateralOffsetMeters +
          sign * _config.lateralLaneOffsetMeters;
    }

    // Zawijanie okrążeń na welodromie (np. 250 m).
    final double trackLen = math.max(50.0, input.velodromeTrackLengthMeters);
    final double wrappedDist = input.isVelodrome
        ? (ghostSample.distanceMeters % trackLen)
        : ghostSample.distanceMeters;

    // Płynna wysokość względna wzdłuż gradientu.
    final double gradeTan = input.playerGradientPercent / 100.0;
    final double ghostElevation =
        input.playerElevationMeters + distanceGapMeters * gradeTan;

    // Wygaszenie przy przekroczeniu maksymalnego zasięgu lub zbyt bliskim nakładaniu.
    final double absGap = distanceGapMeters.abs();
    final bool withinRange = absGap <= _config.maxVisibleRangeMeters;
    double opacity = _config.baseOpacity;
    if (!withinRange) {
      opacity = 0.0;
    } else {
      final double distanceFactor =
          1.0 -
          ((absGap - _config.maxVisibleRangeMeters * 0.65) /
                  (_config.maxVisibleRangeMeters * 0.35))
              .clamp(0.0, 1.0);
      opacity *= distanceFactor;
      if (absGap < _config.proximityFadeMeters && lateralDiff.abs() < 0.45) {
        opacity *= 0.72;
      }
      // Subtelne pulsowanie hologramu (~1.6 Hz).
      final double pulse =
          0.92 + 0.08 * math.sin(input.animationTimeSeconds * 3.2);
      opacity = (opacity * pulse).clamp(0.0, 0.9);
    }

    final double crankFreqRadPerSec =
        (ghostSample.cadenceRpm / 60.0) * math.pi * 2.0;
    final double crankAngle =
        (input.animationTimeSeconds * crankFreqRadPerSec) % (math.pi * 2.0);
    final double leanAngle = input.isVelodrome
        ? input.velodromeBankingAngleRadians * 0.55
        : ghostSample.leanAngleRadians;

    // Generowanie śladu świetlnego za hologramem (ostatnie 14 m).
    final List<GhostTrailSample> trail = <GhostTrailSample>[];
    if (_config.showGroundTrailRibbon && withinRange) {
      const int segments = 7;
      for (int i = 0; i <= segments; i++) {
        final double frac = i / segments;
        final double backDist = frac * 14.0;
        final double sampleDist = ghostSample.distanceMeters - backDist;
        trail.add(
          GhostTrailSample(
            distanceMeters: sampleDist,
            lateralOffsetMeters: resolvedLateralOffset,
            elevationMeters: ghostElevation - backDist * gradeTan,
            alphaFactor: (1.0 - frac) * 0.75,
          ),
        );
      }
    }

    return GhostRiderHologramFrameState(
      isVisible: withinRange && opacity > 0.02,
      discipline: _recordProfile.discipline,
      recordHolderName: _recordProfile.riderName,
      recordHolderTeamCode: _recordProfile.teamCode,
      recordYear: _recordProfile.recordYear,
      ghostDistanceMeters: ghostSample.distanceMeters,
      ghostTrackWrappedDistanceMeters: wrappedDist,
      ghostLateralOffsetMeters: resolvedLateralOffset,
      ghostElevationMeters: ghostElevation,
      ghostSpeedMs: ghostSample.speedMs,
      ghostPowerWatts: ghostSample.powerWatts,
      ghostCadenceRpm: ghostSample.cadenceRpm,
      ghostCrankAngleRadians: crankAngle,
      ghostLeanAngleRadians: leanAngle,
      isGhostStanding: ghostSample.isStanding,
      distanceGapMeters: distanceGapMeters,
      timeDeltaSeconds: timeDeltaSeconds,
      sideBySideStatus: status,
      effectiveOpacity: opacity,
      scanlinePhase: (input.animationTimeSeconds * 1.4) % 1.0,
      trailSamples: trail,
    );
  }

  /// Rysuje półprzezroczysty złoty hologram kolarza w przestrzeni 3D
  /// za pomocą aktywnej macierzy [Scene3DMathProjection].
  void paintGhostRider3d({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required GhostRiderHologramFrameState state,
    required Vector3 ghostWorldBase,
    Vector3? playerWorldBase,
  }) {
    if (!state.isVisible || state.effectiveOpacity <= 0.01) {
      return;
    }

    final ProjectedPoint3D baseProj = projection.worldToScreen(ghostWorldBase);
    if (!baseProj.isInFrontOfCamera || baseProj.depthEye <= 0.4) {
      return;
    }

    final double alpha = state.effectiveOpacity;
    const Color goldCore = AppColors.goldAccent;
    final Color edgeHighlight =
        _config.visualStyle == GhostHologramVisualStyle.telemetryPulse
        ? AppColors.cyanAccent
        : const Color(0xFFFFF3C4);

    // 1. Złoty ślad na nawierzchni za hologramem.
    if (_config.showGroundTrailRibbon && state.trailSamples.length >= 2) {
      _paintGroundTrailRibbon(
        canvas: canvas,
        projection: projection,
        ghostWorldBase: ghostWorldBase,
        state: state,
        goldCore: goldCore,
        alpha: alpha,
      );
    }

    // 2. Linia porównawcza ramię w ramię z graczem.
    if (_config.showDeltaGapLine &&
        playerWorldBase != null &&
        state.distanceGapMeters.abs() <= 28.0) {
      _paintSideBySideDeltaLine(
        canvas: canvas,
        projection: projection,
        playerWorldBase: playerWorldBase,
        ghostWorldBase: ghostWorldBase,
        state: state,
        alpha: alpha,
      );
    }

    // 3. Rzutowanie kluczowych punktów roweru i sylwetki 3D hologramu.
    final double lean = state.ghostLeanAngleRadians;
    final double leanSin = math.sin(lean);
    final double rock = state.isGhostStanding
        ? math.sin(state.ghostCrankAngleRadians) * 0.11
        : 0.0;
    final double totalLeanSin = math.sin(lean + rock);
    final double totalLeanCos = math.cos(lean + rock);

    Vector3 localToWorld(double dx, double dy, double dz) {
      final double rx = dx * totalLeanCos + dy * totalLeanSin;
      final double ry = -dx * totalLeanSin + dy * totalLeanCos;
      return Vector3(
        ghostWorldBase.x + rx,
        ghostWorldBase.y + ry,
        ghostWorldBase.z + dz,
      );
    }

    // Punkty roweru i kolarza w lokalnym układzie 3D (w metrach).
    final bool isAero =
        state.discipline == GhostHologramDiscipline.individualTimeTrial ||
        state.discipline == GhostHologramDiscipline.velodromeHourRecord;

    final Offset? rearWheel = _projectOffset(
      projection,
      localToWorld(0.0, 0.34, -0.50),
    );
    final Offset? frontWheel = _projectOffset(
      projection,
      localToWorld(0.0, 0.34, 0.52),
    );
    final Offset? bottomBracket = _projectOffset(
      projection,
      localToWorld(0.0, 0.28, -0.04),
    );
    final Offset? saddle = _projectOffset(
      projection,
      localToWorld(0.0, state.isGhostStanding ? 1.02 : 0.94, -0.24),
    );
    final Offset? headTube = _projectOffset(
      projection,
      localToWorld(0.0, 0.84, 0.38),
    );
    final Offset? hip = _projectOffset(
      projection,
      localToWorld(
        -leanSin * 0.06,
        state.isGhostStanding ? 1.10 : 1.01,
        isAero ? -0.14 : -0.22,
      ),
    );
    final Offset? shoulder = _projectOffset(
      projection,
      localToWorld(
        rock * 0.35,
        isAero ? 1.08 : (state.isGhostStanding ? 1.38 : 1.24),
        isAero ? 0.30 : 0.18,
      ),
    );
    final Offset? helmet = _projectOffset(
      projection,
      localToWorld(
        rock * 0.25,
        isAero ? 1.20 : (state.isGhostStanding ? 1.54 : 1.40),
        isAero ? 0.42 : 0.26,
      ),
    );
    final Offset? hands = _projectOffset(
      projection,
      localToWorld(0.0, isAero ? 0.93 : 0.90, isAero ? 0.56 : 0.44),
    );

    if (rearWheel == null ||
        frontWheel == null ||
        bottomBracket == null ||
        saddle == null ||
        headTube == null ||
        hip == null ||
        shoulder == null ||
        helmet == null ||
        hands == null) {
      return;
    }

    final double wheelRadiusPx =
        (baseProj.perspectiveScale * 18.0).clamp(4.0, 48.0);
    final double strokeWidth =
        (baseProj.perspectiveScale * 2.1).clamp(1.2, 4.5);

    // Złota poświata pod oponami na asfalcie.
    final Paint shadowGlowPaint = Paint()
      ..color = goldCore.withValues(alpha: alpha * 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          (rearWheel.dx + frontWheel.dx) * 0.5,
          math.max(rearWheel.dy, frontWheel.dy) + wheelRadiusPx * 0.92,
        ),
        width: (frontWheel - rearWheel).distance + wheelRadiusPx * 1.6,
        height: math.max(5.0, wheelRadiusPx * 0.48),
      ),
      shadowGlowPaint,
    );

    // Warstwa główna hologramu + opcjonalny puls krawędziowy.
    final Paint glowStroke = Paint()
      ..color = goldCore.withValues(alpha: alpha * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final Paint coreStroke = Paint()
      ..color = edgeHighlight.withValues(alpha: alpha * 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fillHologram = Paint()
      ..color = goldCore.withValues(alpha: alpha * 0.34)
      ..style = PaintingStyle.fill;

    // Koła (pełny dysk tylny w ITT lub torze, szprychy w podjeździe KOM).
    if (isAero) {
      canvas.drawCircle(
        rearWheel,
        wheelRadiusPx,
        Paint()
          ..color = goldCore.withValues(alpha: alpha * 0.24)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawCircle(rearWheel, wheelRadiusPx, glowStroke);
    canvas.drawCircle(rearWheel, wheelRadiusPx, coreStroke);
    canvas.drawCircle(frontWheel, wheelRadiusPx, glowStroke);
    canvas.drawCircle(frontWheel, wheelRadiusPx, coreStroke);

    // Rama roweru.
    final Path framePath = Path()
      ..moveTo(rearWheel.dx, rearWheel.dy)
      ..lineTo(bottomBracket.dx, bottomBracket.dy)
      ..lineTo(saddle.dx, saddle.dy)
      ..close()
      ..moveTo(bottomBracket.dx, bottomBracket.dy)
      ..lineTo(headTube.dx, headTube.dy)
      ..lineTo(saddle.dx, saddle.dy)
      ..moveTo(headTube.dx, headTube.dy)
      ..lineTo(frontWheel.dx, frontWheel.dy);

    canvas.drawPath(framePath, glowStroke);
    canvas.drawPath(framePath, coreStroke);

    // Korba i dwusegmentowe nogi napędzane kadencją.
    const double crankR = 0.172;
    const double rightFootX = 0.11;
    final double rightFootY =
        0.28 - math.sin(state.ghostCrankAngleRadians) * crankR;
    final double rightFootZ =
        -0.04 + math.cos(state.ghostCrankAngleRadians) * crankR;
    final Offset? rightFoot = _projectOffset(
      projection,
      localToWorld(rightFootX, rightFootY, rightFootZ),
    );
    final Offset? rightKnee = _projectOffset(
      projection,
      localToWorld(
        0.10,
        (rightFootY + (state.isGhostStanding ? 1.05 : 0.96)) * 0.52,
        rightFootZ + 0.18,
      ),
    );

    if (rightFoot != null && rightKnee != null) {
      final Path legPath = Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(rightKnee.dx, rightKnee.dy)
        ..lineTo(rightFoot.dx, rightFoot.dy);
      canvas.drawPath(
        legPath,
        Paint()
          ..color = goldCore.withValues(alpha: alpha * 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 1.45
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Tułów, ręce i kask aero/szosowy.
    final Path riderBody = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(shoulder.dx, shoulder.dy)
      ..lineTo(hands.dx, hands.dy)
      ..lineTo(headTube.dx, headTube.dy)
      ..close();
    canvas.drawPath(riderBody, fillHologram);
    canvas.drawPath(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(shoulder.dx, shoulder.dy)
        ..lineTo(hands.dx, hands.dy),
      glowStroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(shoulder.dx, shoulder.dy)
        ..lineTo(hands.dx, hands.dy),
      coreStroke,
    );

    // Kask (wydłużony kształt aero w ITT/torze).
    final double helmetRadius = (wheelRadiusPx * 0.34).clamp(3.0, 14.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: helmet,
        width: helmetRadius * (isAero ? 2.4 : 1.85),
        height: helmetRadius * 1.55,
      ),
      fillHologram,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: helmet,
        width: helmetRadius * (isAero ? 2.4 : 1.85),
        height: helmetRadius * 1.55,
      ),
      coreStroke,
    );

    // 4. Holograficzne linie skanowania (Scanlines) w stylu Złotego Hologramu.
    if (_config.showScanlines &&
        _config.visualStyle != GhostHologramVisualStyle.minimalSilhouette) {
      _paintHologramScanlines(
        canvas: canvas,
        center: Offset(
          (rearWheel.dx + frontWheel.dx + helmet.dx) / 3.0,
          (helmet.dy + rearWheel.dy) * 0.5,
        ),
        width: (frontWheel.dx - rearWheel.dx).abs() + wheelRadiusPx * 2.2,
        height: (rearWheel.dy - helmet.dy).abs() + wheelRadiusPx * 1.4,
        phase: state.scanlinePhase,
        color: edgeHighlight.withValues(alpha: alpha * 0.42),
      );
    }

    // 5. Pływająca etykieta rekordzisty z koroną i deltą czasową.
    if (_config.showFloatingCrownTag) {
      _paintFloatingCrownTag(
        canvas: canvas,
        anchor: Offset(helmet.dx, helmet.dy - helmetRadius * 2.2),
        state: state,
        alpha: alpha,
      );
    }
  }

  void _paintGroundTrailRibbon({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 ghostWorldBase,
    required GhostRiderHologramFrameState state,
    required Color goldCore,
    required double alpha,
  }) {
    final List<Offset> points = <Offset>[];
    for (final GhostTrailSample sample in state.trailSamples) {
      final double dz = sample.distanceMeters - state.ghostDistanceMeters;
      final double dx =
          sample.lateralOffsetMeters - state.ghostLateralOffsetMeters;
      final double dy = sample.elevationMeters - state.ghostElevationMeters;
      final Offset? pt = _projectOffset(
        projection,
        Vector3(
          ghostWorldBase.x + dx,
          ghostWorldBase.y + dy + 0.02,
          ghostWorldBase.z + dz,
        ),
      );
      if (pt != null) {
        points.add(pt);
      }
    }
    if (points.length < 2) return;

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final Paint trailPaint = Paint()
      ..shader = ui.Gradient.linear(
        points.first,
        points.last,
        <Color>[
          goldCore.withValues(alpha: alpha * 0.72),
          goldCore.withValues(alpha: 0.0),
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, trailPaint);
  }

  void _paintSideBySideDeltaLine({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 playerWorldBase,
    required Vector3 ghostWorldBase,
    required GhostRiderHologramFrameState state,
    required double alpha,
  }) {
    final Offset? p1 = _projectOffset(
      projection,
      Vector3(playerWorldBase.x, playerWorldBase.y + 0.04, playerWorldBase.z),
    );
    final Offset? p2 = _projectOffset(
      projection,
      Vector3(ghostWorldBase.x, ghostWorldBase.y + 0.04, ghostWorldBase.z),
    );
    if (p1 == null || p2 == null) return;

    final Paint linePaint = Paint()
      ..color = state.sideBySideStatus.accentColor.withValues(
        alpha: alpha * 0.65,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawLine(p1, p2, linePaint);
  }

  void _paintHologramScanlines({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required double phase,
    required Color color,
  }) {
    final double left = center.dx - width * 0.5;
    final double right = center.dx + width * 0.5;
    final double top = center.dy - height * 0.5;
    final Paint scanPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const int lineCount = 6;
    for (int i = 0; i < lineCount; i++) {
      final double yFrac = ((i / lineCount) + phase) % 1.0;
      final double y = top + height * yFrac;
      canvas.drawLine(Offset(left, y), Offset(right, y), scanPaint);
    }
  }

  void _paintFloatingCrownTag({
    required Canvas canvas,
    required Offset anchor,
    required GhostRiderHologramFrameState state,
    required double alpha,
  }) {
    final String sign = state.timeDeltaSeconds >= 0.0 ? '+' : '';
    final String deltaText = '$sign${state.timeDeltaSeconds.toStringAsFixed(1)}s';
    final String label =
        '★ ${state.recordHolderName} (${state.recordYear})  $deltaText';

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.goldAccent.withValues(
            alpha: (alpha + 0.35).clamp(0.0, 1.0),
          ),
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const double padX = 8.0;
    const double padY = 4.0;
    final RRect badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(anchor.dx, anchor.dy - textPainter.height * 0.5 - 6.0),
        width: textPainter.width + padX * 2,
        height: textPainter.height + padY * 2,
      ),
      const Radius.circular(8.0),
    );

    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = AppColors.background.withValues(
          alpha: (alpha + 0.3).clamp(0.0, 0.88),
        ),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = AppColors.goldAccent.withValues(
          alpha: (alpha + 0.25).clamp(0.0, 0.9),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(
      canvas,
      Offset(badgeRect.left + padX, badgeRect.top + padY),
    );
  }

  Offset? _projectOffset(Scene3DMathProjection projection, Vector3 world) {
    final ProjectedPoint3D p = projection.worldToScreen(world);
    if (!p.isInFrontOfCamera || p.depthEye <= 0.25) {
      return null;
    }
    return Offset(p.screenX, p.screenY);
  }
}

// =============================================================================
// 4. PODGLĄD CANVAS 3D I PANEL STEROWANIA HOLOGRAMEM
// =============================================================================

/// Dedykowany [CustomPainter] prezentujący pojedynek 3D ramię w ramię
/// pomiędzy kolarzem gracza a złotym hologramem rekordzisty trasy.
class GhostRiderHologram3dPainter extends CustomPainter {
  final GhostRiderHologram3dRenderer renderer;
  final GhostRiderHologramFrameInput frameInput;
  final GhostRiderHologramFrameState frameState;

  GhostRiderHologram3dPainter({
    required this.renderer,
    required this.frameInput,
    required this.frameState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0) return;

    // Tło nieba / hali welodromu.
    final bool isVelodrome = frameInput.isVelodrome;
    final Paint bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0.0, size.height),
        <Color>[
          isVelodrome ? const Color(0xFF141822) : const Color(0xFF0F1115),
          const Color(0xFF181B22),
        ],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    final Scene3DMathProjection projection = Scene3DMathProjection(
      viewportWidth: size.width,
      viewportHeight: size.height,
      fovYDegrees: 56.0,
    );

    // Kamera pościgowa za kolarzem gracza.
    final Vector3 camPos = Vector3(
      frameInput.playerLateralOffsetMeters * 0.4,
      2.15,
      -5.6,
    );
    final Vector3 camTarget = Vector3(
      frameInput.playerLateralOffsetMeters * 0.2,
      0.95,
      8.0,
    );
    projection.updateCamera(
      Camera3DConfig(position: camPos, target: camTarget, fovYDegrees: 56.0),
      viewportWidth: size.width,
      viewportHeight: size.height,
    );

    // Rysowanie wstęgi szosy / parkietu welodromu.
    _paintRoadSurface(canvas, size, projection, isVelodrome);

    // Rysowanie kolarza gracza (solidny model w barwach drużyny).
    final Vector3 playerWorld = Vector3(
      frameInput.playerLateralOffsetMeters,
      0.0,
      0.0,
    );
    _paintPlayerRider(
      canvas: canvas,
      projection: projection,
      playerWorld: playerWorld,
      animationTime: frameInput.animationTimeSeconds,
      speedMs: frameInput.playerSpeedMs,
      isVelodrome: isVelodrome,
    );

    // Rysowanie złotego hologramu rekordzisty ramię w ramię.
    final double clampedZ = frameState.distanceGapMeters.clamp(-18.0, 45.0);
    final Vector3 ghostWorld = Vector3(
      frameState.ghostLateralOffsetMeters,
      clampedZ * (frameInput.playerGradientPercent / 100.0) * 0.25,
      clampedZ,
    );

    renderer.paintGhostRider3d(
      canvas: canvas,
      size: size,
      projection: projection,
      state: frameState,
      ghostWorldBase: ghostWorld,
      playerWorldBase: playerWorld,
    );
  }

  void _paintRoadSurface(
    Canvas canvas,
    Size size,
    Scene3DMathProjection projection,
    bool isVelodrome,
  ) {
    final List<Offset> leftPts = <Offset>[];
    final List<Offset> rightPts = <Offset>[];
    final List<Offset> centerPts = <Offset>[];

    const double halfWidth = 3.6;
    for (int i = 0; i <= 16; i++) {
      final double z = -2.0 + i * 4.2;
      final ProjectedPoint3D l = projection.worldToScreen(
        Vector3(-halfWidth, 0.0, z),
      );
      final ProjectedPoint3D r = projection.worldToScreen(
        Vector3(halfWidth, 0.0, z),
      );
      final ProjectedPoint3D c = projection.worldToScreen(Vector3(0.0, 0.0, z));
      if (l.isInFrontOfCamera && r.isInFrontOfCamera && c.isInFrontOfCamera) {
        leftPts.add(Offset(l.screenX, l.screenY));
        rightPts.add(Offset(r.screenX, r.screenY));
        centerPts.add(Offset(c.screenX, c.screenY));
      }
    }

    if (leftPts.length < 2) return;

    final Path roadPath = Path()..moveTo(leftPts.first.dx, leftPts.first.dy);
    for (int i = 1; i < leftPts.length; i++) {
      roadPath.lineTo(leftPts[i].dx, leftPts[i].dy);
    }
    for (int i = rightPts.length - 1; i >= 0; i--) {
      roadPath.lineTo(rightPts[i].dx, rightPts[i].dy);
    }
    roadPath.close();

    canvas.drawPath(
      roadPath,
      Paint()
        ..color = isVelodrome
            ? const Color(0xFF473321)
            : const Color(0xFF1D212A),
    );

    // Krawędzie drogi / linie pomiarowe toru.
    final Paint edgePaint = Paint()
      ..color = isVelodrome
          ? AppColors.accentBlue.withValues(alpha: 0.65)
          : AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (int i = 0; i < leftPts.length - 1; i++) {
      canvas.drawLine(leftPts[i], leftPts[i + 1], edgePaint);
      canvas.drawLine(rightPts[i], rightPts[i + 1], edgePaint);
      if (i % 2 == 0) {
        canvas.drawLine(
          centerPts[i],
          centerPts[i + 1],
          Paint()
            ..color = isVelodrome
                ? AppColors.crimsonAlert.withValues(alpha: 0.55)
                : AppColors.textSecondary.withValues(alpha: 0.35)
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  void _paintPlayerRider({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 playerWorld,
    required double animationTime,
    required double speedMs,
    required bool isVelodrome,
  }) {
    final ProjectedPoint3D base = projection.worldToScreen(playerWorld);
    final ProjectedPoint3D rw = projection.worldToScreen(
      Vector3(playerWorld.x, 0.34, playerWorld.z - 0.50),
    );
    final ProjectedPoint3D fw = projection.worldToScreen(
      Vector3(playerWorld.x, 0.34, playerWorld.z + 0.52),
    );
    final ProjectedPoint3D bb = projection.worldToScreen(
      Vector3(playerWorld.x, 0.28, playerWorld.z - 0.04),
    );
    final ProjectedPoint3D saddle = projection.worldToScreen(
      Vector3(playerWorld.x, 0.94, playerWorld.z - 0.24),
    );
    final ProjectedPoint3D headTube = projection.worldToScreen(
      Vector3(playerWorld.x, 0.84, playerWorld.z + 0.38),
    );
    final ProjectedPoint3D shoulder = projection.worldToScreen(
      Vector3(playerWorld.x, 1.18, playerWorld.z + 0.22),
    );
    final ProjectedPoint3D helmet = projection.worldToScreen(
      Vector3(playerWorld.x, 1.32, playerWorld.z + 0.32),
    );

    if (!base.isInFrontOfCamera || !rw.isInFrontOfCamera || !fw.isInFrontOfCamera) {
      return;
    }

    final double wheelR = (base.perspectiveScale * 18.0).clamp(5.0, 44.0);
    final Paint bikePaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(rw.screenX, rw.screenY), wheelR, bikePaint);
    canvas.drawCircle(Offset(fw.screenX, fw.screenY), wheelR, bikePaint);

    final Path frame = Path()
      ..moveTo(rw.screenX, rw.screenY)
      ..lineTo(bb.screenX, bb.screenY)
      ..lineTo(saddle.screenX, saddle.screenY)
      ..close()
      ..moveTo(bb.screenX, bb.screenY)
      ..lineTo(headTube.screenX, headTube.screenY)
      ..lineTo(saddle.screenX, saddle.screenY)
      ..moveTo(headTube.screenX, headTube.screenY)
      ..lineTo(fw.screenX, fw.screenY);
    canvas.drawPath(frame, bikePaint);

    // Koszulka gracza (burgund #8E4A49).
    final Paint jerseyPaint = Paint()
      ..color = AppColors.primaryAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(saddle.screenX, saddle.screenY),
      Offset(shoulder.screenX, shoulder.screenY),
      jerseyPaint,
    );
    canvas.drawLine(
      Offset(shoulder.screenX, shoulder.screenY),
      Offset(headTube.screenX, headTube.screenY),
      Paint()
        ..color = AppColors.textSecondary
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(helmet.screenX, helmet.screenY),
      (wheelR * 0.32).clamp(4.0, 12.0),
      Paint()..color = isVelodrome ? AppColors.accentBlue : AppColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant GhostRiderHologram3dPainter oldDelegate) {
    return oldDelegate.frameInput != frameInput ||
        oldDelegate.frameState != frameState;
  }
}

/// Responsywny panel sterowania i podglądu 3D złotego hologramu rekordzisty.
class GhostRiderHologramControlPanel extends StatefulWidget {
  final GhostRiderRecordProfile? initialProfile;
  final GhostRiderHologramConfig initialConfig;
  final ValueChanged<GhostRiderHologramConfig>? onConfigChanged;
  final ValueChanged<GhostRiderRecordProfile>? onProfileChanged;

  const GhostRiderHologramControlPanel({
    super.key,
    this.initialProfile,
    this.initialConfig = const GhostRiderHologramConfig(),
    this.onConfigChanged,
    this.onProfileChanged,
  });

  @override
  State<GhostRiderHologramControlPanel> createState() =>
      _GhostRiderHologramControlPanelState();
}

class _GhostRiderHologramControlPanelState
    extends State<GhostRiderHologramControlPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _simController;
  late GhostRiderRecordProfile _activeProfile;
  late GhostRiderHologramConfig _config;
  late GhostRiderHologram3dRenderer _renderer;

  bool _isPlaying = true;
  double _elapsedSeconds = 22.0;
  double _playerPowerDeltaWatts = 4.0;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _activeProfile =
        widget.initialProfile ??
        GhostRiderRecordProfile.ittWorldChampionshipPreset();
    _config = widget.initialConfig;
    _renderer = GhostRiderHologram3dRenderer(
      recordProfile: _activeProfile,
      config: _config,
    );
    _simController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onAnimationTick);
    _simController.repeat();
  }

  void _onAnimationTick() {
    final DateTime now = DateTime.now();
    final double dt =
        (now.difference(_lastTick).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastTick = now;
    if (_isPlaying && mounted) {
      setState(() {
        _elapsedSeconds = (_elapsedSeconds + dt) % 120.0;
      });
    }
  }

  @override
  void dispose() {
    _simController.removeListener(_onAnimationTick);
    _simController.dispose();
    super.dispose();
  }

  void _selectDiscipline(GhostHologramDiscipline discipline) {
    final GhostRiderRecordProfile profile = switch (discipline) {
      GhostHologramDiscipline.individualTimeTrial =>
        GhostRiderRecordProfile.ittWorldChampionshipPreset(),
      GhostHologramDiscipline.velodromeHourRecord =>
        GhostRiderRecordProfile.velodromeHourRecordPreset(),
      GhostHologramDiscipline.komClimb =>
        GhostRiderRecordProfile.alpeDhuezKomPreset(),
    };
    setState(() {
      _activeProfile = profile;
      _renderer.updateProfile(profile);
    });
    widget.onProfileChanged?.call(profile);
  }

  void _updateConfig(GhostRiderHologramConfig next) {
    setState(() {
      _config = next;
      _renderer.updateConfig(next);
    });
    widget.onConfigChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final GhostRiderHistoricalSample ghostSample = _renderer
        .sampleAtElapsedTime(_elapsedSeconds);
    final double playerSpeedOffset = _playerPowerDeltaWatts * 0.015;
    final double playerDistance =
        (ghostSample.distanceMeters +
                _elapsedSeconds * playerSpeedOffset * 0.35)
            .clamp(0.0, _activeProfile.totalDistanceMeters);

    final GhostRiderHologramFrameInput frameInput =
        GhostRiderHologramFrameInput(
          playerDistanceMeters: playerDistance,
          playerElapsedSeconds: _elapsedSeconds,
          playerSpeedMs: ghostSample.speedMs + playerSpeedOffset,
          playerLateralOffsetMeters: -0.65,
          playerElevationMeters: 120.0,
          playerGradientPercent: ghostSample.gradientPercent,
          animationTimeSeconds: _elapsedSeconds,
          isVelodrome:
              _activeProfile.discipline ==
              GhostHologramDiscipline.velodromeHourRecord,
        );
    final GhostRiderHologramFrameState frameState = _renderer.evaluateFrame(
      frameInput,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 560;
        final bool isWide = constraints.maxWidth >= 960;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                _buildDisciplineSelector(isCompact),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: _buildViewportCard(frameInput, frameState, 260),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildControlsColumn(frameState),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _buildViewportCard(
                    frameInput,
                    frameState,
                    isCompact ? 190 : 230,
                  ),
                  const SizedBox(height: 12),
                  _buildControlsColumn(frameState),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final Widget titleBlock = Row(
      mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.goldAccent,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Złoty Hologram Rekordzisty 3D',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                _activeProfile.courseOrSegmentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget toggleChip = _InteractiveActionChip(
      label: _config.enabled ? 'HOLOGRAM WŁ.' : 'HOLOGRAM WYŁ.',
      icon: _config.enabled
          ? Icons.visibility_rounded
          : Icons.visibility_off_rounded,
      isSelected: _config.enabled,
      accentColor: AppColors.goldAccent,
      onTap: () => _updateConfig(_config.copyWith(enabled: !_config.enabled)),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          titleBlock,
          const SizedBox(height: 10),
          toggleChip,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(child: titleBlock),
        const SizedBox(width: 12),
        toggleChip,
      ],
    );
  }

  Widget _buildDisciplineSelector(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GhostHologramDiscipline.values.map((
        GhostHologramDiscipline discipline,
      ) {
        final bool selected = _activeProfile.discipline == discipline;
        return _InteractiveActionChip(
          label: isCompact ? discipline.shortTag : discipline.labelPl,
          icon: discipline.icon,
          isSelected: selected,
          accentColor: AppColors.goldAccent,
          onTap: () => _selectDiscipline(discipline),
        );
      }).toList(),
    );
  }

  Widget _buildViewportCard(
    GhostRiderHologramFrameInput frameInput,
    GhostRiderHologramFrameState frameState,
    double height,
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            painter: GhostRiderHologram3dPainter(
              renderer: _renderer,
              frameInput: frameInput,
              frameState: frameState,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: frameState.sideBySideStatus.accentColor.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              child: Text(
                frameState.sideBySideStatus.labelPl,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: frameState.sideBySideStatus.accentColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: _InteractiveActionChip(
              label: _isPlaying ? 'Pauza' : 'Wznów',
              icon: _isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              isSelected: _isPlaying,
              accentColor: AppColors.primaryAccent,
              onTap: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsColumn(GhostRiderHologramFrameState frameState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildTelemetryGrid(frameState),
          const SizedBox(height: 12),
          const Text(
            'Styl wizualny hologramu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: GhostHologramVisualStyle.values.map((
              GhostHologramVisualStyle style,
            ) {
              return _InteractiveActionChip(
                label: style.labelPl,
                icon: Icons.layers_outlined,
                isSelected: _config.visualStyle == style,
                enabled: _config.enabled,
                accentColor: AppColors.goldAccent,
                onTap: () => _updateConfig(_config.copyWith(visualStyle: style)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            label: 'Przezroczystość',
            valueText: '${(_config.baseOpacity * 100).round()}%',
            value: _config.baseOpacity,
            min: 0.15,
            max: 0.85,
            enabled: _config.enabled,
            onChanged: (double v) =>
                _updateConfig(_config.copyWith(baseOpacity: v)),
          ),
          const SizedBox(height: 6),
          _buildSliderRow(
            label: 'Różnica mocy gracza',
            valueText:
                '${_playerPowerDeltaWatts >= 0 ? '+' : ''}${_playerPowerDeltaWatts.round()} W',
            value: _playerPowerDeltaWatts,
            min: -40.0,
            max: 40.0,
            enabled: _config.enabled,
            onChanged: (double v) {
              setState(() {
                _playerPowerDeltaWatts = v;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid(GhostRiderHologramFrameState frameState) {
    final String sign = frameState.timeDeltaSeconds >= 0.0 ? '+' : '';
    final String gapSign = frameState.distanceGapMeters >= 0.0 ? '+' : '';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _TelemetryCell(
          label: 'Rekordzista',
          value: '${frameState.recordHolderName} (${frameState.recordYear})',
          accent: AppColors.goldAccent,
        ),
        _TelemetryCell(
          label: 'Delta czasu',
          value: '$sign${frameState.timeDeltaSeconds.toStringAsFixed(1)} s',
          accent: frameState.sideBySideStatus.accentColor,
        ),
        _TelemetryCell(
          label: 'Dystans do ducha',
          value: '$gapSign${frameState.distanceGapMeters.toStringAsFixed(1)} m',
          accent: AppColors.textPrimary,
        ),
        _TelemetryCell(
          label: 'Tempo ducha',
          value:
              '${(frameState.ghostSpeedMs * 3.6).toStringAsFixed(1)} km/h • ${frameState.ghostPowerWatts.round()} W',
          accent: AppColors.accentBlue,
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: enabled
                    ? AppColors.textSecondary
                    : AppColors.textSecondary.withValues(alpha: 0.45),
                letterSpacing: -0.2,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? AppColors.goldAccent
                    : AppColors.textSecondary.withValues(alpha: 0.45),
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppTheme.borderColor,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
            disabledActiveTrackColor: AppTheme.borderColor,
            disabledThumbColor: AppColors.textSecondary,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryCell({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interaktywny przycisk wyboru z pełnymi stanami hover / active / disabled / focus.
class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveActionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.enabled = true,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.45)
        : _isFocused
        ? AppColors.accentBlue
        : widget.isSelected
        ? widget.accentColor
        : _isHovered
        ? widget.accentColor.withValues(alpha: 0.65)
        : AppTheme.borderColor;

    final Color bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.isSelected
        ? widget.accentColor.withValues(alpha: _isPressed ? 0.28 : 0.18)
        : _isHovered
        ? AppColors.surfaceLight
        : AppColors.surface;

    final Color fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isSelected
        ? widget.accentColor
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (bool focused) {
        if (mounted) {
          setState(() => _isFocused = focused);
        }
      },
      onShowHoverHighlight: (bool hovered) {
        if (mounted) {
          setState(() => _isHovered = hovered);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            if (enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onTap : null,
        child: MouseRegion(
          cursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: fgColor,
                    letterSpacing: -0.2,
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
