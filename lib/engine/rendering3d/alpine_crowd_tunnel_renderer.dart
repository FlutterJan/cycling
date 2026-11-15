// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TYPY NARODOWE, FLARY I KONFIGURACJA TUNELU KIBICÓW
// =============================================================================

/// Narodowe barwy koszulek oraz flag kibiców na alpejskich i pirenejskich przełęczach.
enum CrowdTunnelNationJersey {
  netherlands(
    code: 'NL',
    labelPl: 'Holandia',
    primaryColor: Color(0xFFF97316),
    secondaryColor: Color(0xFFEA580C),
    flagBands: <Color>[Color(0xFFAE1C28), Color(0xFFF3F4F6), Color(0xFF21468B)],
  ),
  belgium(
    code: 'BE',
    labelPl: 'Belgia',
    primaryColor: Color(0xFF0EA5E9),
    secondaryColor: Color(0xFF181B22),
    flagBands: <Color>[Color(0xFF181B22), Color(0xFFFACC15), Color(0xFFEF4444)],
  ),
  france(
    code: 'FR',
    labelPl: 'Francja',
    primaryColor: Color(0xFF2563EB),
    secondaryColor: Color(0xFFF3F4F6),
    flagBands: <Color>[Color(0xFF0055A4), Color(0xFFF3F4F6), Color(0xFFEF4135)],
  ),
  italy(
    code: 'IT',
    labelPl: 'Włochy',
    primaryColor: Color(0xFF0284C7),
    secondaryColor: Color(0xFFF3F4F6),
    flagBands: <Color>[Color(0xFF009246), Color(0xFFF3F4F6), Color(0xFFCE2B37)],
  ),
  slovenia(
    code: 'SI',
    labelPl: 'Słowenia',
    primaryColor: Color(0xFF06B6D4),
    secondaryColor: Color(0xFF2563EB),
    flagBands: <Color>[Color(0xFFF3F4F6), Color(0xFF005DA4), Color(0xFFED1C24)],
  ),
  spain(
    code: 'ES',
    labelPl: 'Hiszpania',
    primaryColor: Color(0xFFDC2626),
    secondaryColor: Color(0xFFFACC15),
    flagBands: <Color>[Color(0xFFAA151B), Color(0xFFF1BF00), Color(0xFFAA151B)],
  ),
  poland(
    code: 'PL',
    labelPl: 'Polska',
    primaryColor: Color(0xFFF3F4F6),
    secondaryColor: Color(0xFFDC2626),
    flagBands: <Color>[Color(0xFFF3F4F6), Color(0xFFDC143C)],
  ),
  colombia(
    code: 'CO',
    labelPl: 'Kolumbia',
    primaryColor: Color(0xFFFACC15),
    secondaryColor: Color(0xFF1D4ED8),
    flagBands: <Color>[Color(0xFFFCD116), Color(0xFF003893), Color(0xFFCE1126)],
  ),
  denmark(
    code: 'DK',
    labelPl: 'Dania',
    primaryColor: Color(0xFFDC2626),
    secondaryColor: Color(0xFFF3F4F6),
    flagBands: <Color>[Color(0xFFC8102E), Color(0xFFF3F4F6), Color(0xFFC8102E)],
  ),
  basque(
    code: 'EUS',
    labelPl: 'Kraj Basków',
    primaryColor: Color(0xFF10B981),
    secondaryColor: Color(0xFFDC2626),
    flagBands: <Color>[Color(0xFFD52B1E), Color(0xFF009B48), Color(0xFFF3F4F6)],
  );

  final String code;
  final String labelPl;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> flagBands;

  const CrowdTunnelNationJersey({
    required this.code,
    required this.labelPl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.flagBands,
  });
}

/// Kolor dymu z rac/flar odpalanych przez kibiców w tunelu górskim.
enum CrowdTunnelFlareColor {
  orange(
    labelPl: 'Pomarańczowa',
    coreColor: Color(0xFFFF7A00),
    midColor: Color(0xFFF97316),
    plumeColor: Color(0xFFFB923C),
  ),
  red(
    labelPl: 'Czerwona',
    coreColor: Color(0xFFFF3B30),
    midColor: Color(0xFFEF4444),
    plumeColor: Color(0xFFF87171),
  );

  final String labelPl;
  final Color coreColor;
  final Color midColor;
  final Color plumeColor;

  const CrowdTunnelFlareColor({
    required this.labelPl,
    required this.coreColor,
    required this.midColor,
    required this.plumeColor,
  });
}

/// Konfiguracja efektu "Tunelu Kibiców" na stromych podjazdach (>8%).
class AlpineCrowdTunnelConfig {
  /// Czy efekt tunelu kibiców jest aktywny.
  final bool enabled;

  /// Minimalne nachylenie podjazdu [%], powyżej którego tworzy się tunel kibiców (domyślnie >8%).
  final double minGradientPercent;

  /// Szerokość zawężonego korytarza przejazdu przed odsuwaniem się kibiców [m].
  final double corridorWidthMeters;

  /// Standardowa połowa szerokości szosy poza strefą zwężenia [m].
  final double standardRoadHalfWidthMeters;

  /// Dystans przed kołem lidera [m], na którym kibice zaczynają się rozstępować.
  final double partingTriggerAheadMeters;

  /// Dystans tuż przed kołem lidera [m], przy którym kibice osiągają pełne odsunięcie.
  final double partingPeakDistanceMeters;

  /// Docelowa połowa szerokości korytarza [m] po odsunięciu się kibiców przed kolarzem.
  final double partingClearanceHalfWidthMeters;

  /// Zasięg generowania tunelu przed kamerą [m].
  final double forwardVisibilityMeters;

  /// Zasięg generowania tunelu za kamerą [m].
  final double backwardVisibilityMeters;

  /// Odstęp podłużny między kolejnymi kibicami w pierwszym rzędzie [m].
  final double spectatorSpacingMeters;

  /// Liczba rzędów kibiców po każdej stronie szosy (1..4).
  final int maxRowsPerSide;

  /// Czy renderować flagi narodowe na drzewcach.
  final bool enableFlags;

  /// Czy renderować flary oraz kłęby dymu w kolorze pomarańczowym i czerwonym.
  final bool enableFlareSmoke;

  /// Czy rysować subtelną linię wskazującą zawężony korytarz 2.8 m.
  final bool showCorridorBoundsGuide;

  const AlpineCrowdTunnelConfig({
    this.enabled = true,
    this.minGradientPercent = 8.0,
    this.corridorWidthMeters = 2.8,
    this.standardRoadHalfWidthMeters = 3.6,
    this.partingTriggerAheadMeters = 14.0,
    this.partingPeakDistanceMeters = 2.2,
    this.partingClearanceHalfWidthMeters = 2.05,
    this.forwardVisibilityMeters = 180.0,
    this.backwardVisibilityMeters = 25.0,
    this.spectatorSpacingMeters = 1.15,
    this.maxRowsPerSide = 3,
    this.enableFlags = true,
    this.enableFlareSmoke = true,
    this.showCorridorBoundsGuide = true,
  });

  /// Połowa szerokości zawężonego korytarza przejazdu (domyślnie 1.40 m dla 2.8 m).
  double get corridorHalfWidthMeters => corridorWidthMeters * 0.5;

  AlpineCrowdTunnelConfig copyWith({
    bool? enabled,
    double? minGradientPercent,
    double? corridorWidthMeters,
    double? standardRoadHalfWidthMeters,
    double? partingTriggerAheadMeters,
    double? partingPeakDistanceMeters,
    double? partingClearanceHalfWidthMeters,
    double? forwardVisibilityMeters,
    double? backwardVisibilityMeters,
    double? spectatorSpacingMeters,
    int? maxRowsPerSide,
    bool? enableFlags,
    bool? enableFlareSmoke,
    bool? showCorridorBoundsGuide,
  }) {
    return AlpineCrowdTunnelConfig(
      enabled: enabled ?? this.enabled,
      minGradientPercent: minGradientPercent ?? this.minGradientPercent,
      corridorWidthMeters: corridorWidthMeters ?? this.corridorWidthMeters,
      standardRoadHalfWidthMeters:
          standardRoadHalfWidthMeters ?? this.standardRoadHalfWidthMeters,
      partingTriggerAheadMeters:
          partingTriggerAheadMeters ?? this.partingTriggerAheadMeters,
      partingPeakDistanceMeters:
          partingPeakDistanceMeters ?? this.partingPeakDistanceMeters,
      partingClearanceHalfWidthMeters:
          partingClearanceHalfWidthMeters ?? this.partingClearanceHalfWidthMeters,
      forwardVisibilityMeters:
          forwardVisibilityMeters ?? this.forwardVisibilityMeters,
      backwardVisibilityMeters:
          backwardVisibilityMeters ?? this.backwardVisibilityMeters,
      spectatorSpacingMeters:
          spectatorSpacingMeters ?? this.spectatorSpacingMeters,
      maxRowsPerSide: maxRowsPerSide ?? this.maxRowsPerSide,
      enableFlags: enableFlags ?? this.enableFlags,
      enableFlareSmoke: enableFlareSmoke ?? this.enableFlareSmoke,
      showCorridorBoundsGuide:
          showCorridorBoundsGuide ?? this.showCorridorBoundsGuide,
    );
  }
}

// =============================================================================
// 2. MODELE STREFY TUNELU, KIBICÓW I ROZSTĘPOWANIA PRZED KOŁEM LIDERA
// =============================================================================

/// Odcinek trasy o nachyleniu > 8%, na którym pojawia się Tunel Kibiców.
class AlpineCrowdTunnelZone {
  final String id;
  final double startDistanceMeters;
  final double endDistanceMeters;
  final double averageGradientPercent;
  final double maxGradientPercent;
  final SegmentClassification peakClassification;

  const AlpineCrowdTunnelZone({
    required this.id,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.averageGradientPercent,
    required this.maxGradientPercent,
    required this.peakClassification,
  });

  double get lengthMeters => math.max(0.0, endDistanceMeters - startDistanceMeters);

  bool containsDistance(double distanceMeters) =>
      distanceMeters >= startDistanceMeters && distanceMeters <= endDistanceMeters;
}

/// Pojedynczy kibic w gęstym alpejskim szpalerze.
class AlpineCrowdTunnelSpectator3D {
  final String id;
  final double distanceMeters;
  final double baseLateralOffsetMeters;
  final double elevationMeters;
  final bool isRightSide;
  final int rowIndex;
  final CrowdTunnelNationJersey nation;
  final bool hasFlag;
  final double flagPoleHeightMeters;
  final bool hasFlare;
  final CrowdTunnelFlareColor? flareColor;
  final double heightMeters;
  final double animationPhase;
  final double leanInFactor;

  const AlpineCrowdTunnelSpectator3D({
    required this.id,
    required this.distanceMeters,
    required this.baseLateralOffsetMeters,
    required this.elevationMeters,
    required this.isRightSide,
    required this.rowIndex,
    required this.nation,
    required this.hasFlag,
    required this.flagPoleHeightMeters,
    required this.hasFlare,
    required this.flareColor,
    required this.heightMeters,
    required this.animationPhase,
    required this.leanInFactor,
  });
}

/// Wynik obliczenia dynamicznego odsunięcia widza przed nadjeżdżającym kołem lidera.
class CrowdSpectatorPartingResult {
  /// Efektywna odległość poprzeczna widza od osi jezdni [m].
  final double effectiveLateralOffsetMeters;

  /// Stopień odsunięcia widza w zakresie [0.0 = stoi w tunelu 2.8 m, 1.0 = w pełni odsunięty].
  final double partingAmount;

  /// Całkowita szerokość przejezdnego korytarza na wysokości tego widza [m].
  final double corridorWidthAtSpectatorMeters;

  const CrowdSpectatorPartingResult({
    required this.effectiveLateralOffsetMeters,
    required this.partingAmount,
    required this.corridorWidthAtSpectatorMeters,
  });
}

/// Zbiorcza telemetria bieżącej klatki Tunelu Kibiców do HUD i panelu sterowania.
class AlpineCrowdTunnelTelemetry {
  final bool isTunnelActive;
  final double currentGradientPercent;
  final double activeCorridorWidthMeters;
  final int visibleSpectatorsCount;
  final int activeFlagsCount;
  final int activeFlaresCount;
  final int partingSpectatorsCount;

  const AlpineCrowdTunnelTelemetry({
    required this.isTunnelActive,
    required this.currentGradientPercent,
    required this.activeCorridorWidthMeters,
    required this.visibleSpectatorsCount,
    required this.activeFlagsCount,
    required this.activeFlaresCount,
    required this.partingSpectatorsCount,
  });

  const AlpineCrowdTunnelTelemetry.inactive({this.currentGradientPercent = 0.0})
      : isTunnelActive = false,
        activeCorridorWidthMeters = 7.2,
        visibleSpectatorsCount = 0,
        activeFlagsCount = 0,
        activeFlaresCount = 0,
        partingSpectatorsCount = 0;
}

/// Callback przekształcający pozycję na trasie w pełną pozę 3D na powierzchni drogi.
typedef TunnelCoursePoseResolver = Cyclist3DPose Function({
  required CoursePosition coursePosition,
  required RoadGeometryParameters roadGeometry,
});

// =============================================================================
// 3. GŁÓWNY RENDERER 3D EFEKTU "TUNELU KIBICÓW"
// =============================================================================

/// Renderer 3D efektu "Tunelu Kibiców" (`AlpineCrowdTunnelRenderer`) na stromych podjazdach (>8%).
///
/// Odpowiada za:
/// - Wykrywanie stromych odcinków (>8%) z [RaceStage] oraz deterministyczne generowanie
///   wielorzędowego tłumu kibiców w koszulkach narodowych, z flagami i flarami.
/// - Zawężenie korytarza przejazdu do `2.8 m` (połowa szerokości `1.40 m`) przed czołem wyścigu.
/// - Dynamiczne rozstępowanie się widzów tuż przed przednim kołem lidera oraz utrzymanie
///   bezpiecznego przejazdu dla mijających kolarzy.
/// - Rysowanie 3D z sortowaniem głębokości (Painter's Algorithm): kibice, powiewające
///   flagi narodowe oraz kłęby pomarańczowego/czerwonego dymu z flar unoszone wiatrem.
class AlpineCrowdTunnelRenderer {
  final AlpineCrowdTunnelConfig config;

  AlpineCrowdTunnelRenderer({
    this.config = const AlpineCrowdTunnelConfig(),
  });

  /// Wykrywa i scala sąsiednie segmenty etapu o nachyleniu większym niż [minGradientPercent].
  static List<AlpineCrowdTunnelZone> detectSteepTunnelZones(
    RaceStage stage, {
    double minGradientPercent = 8.0,
  }) {
    final List<AlpineCrowdTunnelZone> zones = <AlpineCrowdTunnelZone>[];
    if (stage.segments.isEmpty) {
      return zones;
    }

    double? activeStartM;
    double activeEndM = 0.0;
    double weightedGradSum = 0.0;
    double activeLenM = 0.0;
    double maxGrad = 0.0;
    SegmentClassification peakClass = SegmentClassification.none;
    int zoneCounter = 0;

    void flushZone() {
      if (activeStartM == null || activeLenM <= 0.0) {
        activeStartM = null;
        return;
      }
      zoneCounter += 1;
      zones.add(
        AlpineCrowdTunnelZone(
          id: 'tunnel_zone_$zoneCounter',
          startDistanceMeters: activeStartM!,
          endDistanceMeters: activeEndM,
          averageGradientPercent: weightedGradSum / activeLenM,
          maxGradientPercent: maxGrad,
          peakClassification: peakClass,
        ),
      );
      activeStartM = null;
      weightedGradSum = 0.0;
      activeLenM = 0.0;
      maxGrad = 0.0;
      peakClass = SegmentClassification.none;
    }

    for (final StageSegment seg in stage.segments) {
      final double segStartM = seg.startKm * 1000.0;
      final double segLenM = seg.lengthKm * 1000.0;
      final double segEndM = segStartM + segLenM;
      final double grad = seg.gradientPercent;

      if (grad > minGradientPercent && segLenM > 0.0) {
        activeStartM ??= segStartM;
        activeEndM = segEndM;
        weightedGradSum += grad * segLenM;
        activeLenM += segLenM;
        if (grad > maxGrad) {
          maxGrad = grad;
        }
        if (seg.sprintOrKomClassification.index > peakClass.index) {
          peakClass = seg.sprintOrKomClassification;
        }
      } else {
        flushZone();
      }
    }
    flushZone();
    return zones;
  }

  /// Sprawdza, czy na danym nachyleniu (>8%) aktywny jest Tunel Kibiców.
  bool isSteepTunnelActiveForGradient(double gradientPercent) =>
      config.enabled && gradientPercent > config.minGradientPercent;

  /// Zwraca szerokość przejezdnego korytarza [m] na dystansie [distanceMeters].
  ///
  /// Domyślnie na stromych odcinkach (>8%) wynosi `2.8 m`, a tuż przed kołem lidera
  /// rozszerza się płynnie, gdy widzowie odsuwają się na boki.
  double computeCorridorWidthAtDistance({
    required double distanceMeters,
    required double gradientPercent,
    required double leaderFrontWheelDistanceMeters,
    List<double> riderDistancesMeters = const <double>[],
  }) {
    if (!isSteepTunnelActiveForGradient(gradientPercent)) {
      return config.standardRoadHalfWidthMeters * 2.0;
    }

    final double parting = _computePartingFactor(
      spectatorDistanceMeters: distanceMeters,
      leaderFrontWheelDistanceMeters: leaderFrontWheelDistanceMeters,
      riderDistancesMeters: riderDistancesMeters,
    );
    final double halfWidth = _lerpDouble(
      config.corridorHalfWidthMeters,
      config.partingClearanceHalfWidthMeters,
      parting,
    );
    return halfWidth * 2.0;
  }

  /// Oblicza efektywne odsunięcie poprzeczne pojedynczego widza tuż przed kołem lidera.
  CrowdSpectatorPartingResult computeSpectatorParting({
    required AlpineCrowdTunnelSpectator3D spectator,
    required double leaderFrontWheelDistanceMeters,
    List<double> riderDistancesMeters = const <double>[],
  }) {
    final double parting = _computePartingFactor(
      spectatorDistanceMeters: spectator.distanceMeters,
      leaderFrontWheelDistanceMeters: leaderFrontWheelDistanceMeters,
      riderDistancesMeters: riderDistancesMeters,
    );

    final double sign = spectator.isRightSide ? 1.0 : -1.0;
    // W pierwszym rzędzie kibice potrafią lekko wychylać się do wnętrza korytarza 2.8 m,
    // ale przed kołem lidera cofają się proporcjonalnie mocniej niż dalsze rzędy.
    final double rowAttenuation = switch (spectator.rowIndex) {
      0 => 1.0,
      1 => 0.65,
      _ => 0.35,
    };
    final double baseAbs = spectator.baseLateralOffsetMeters.abs();
    final double leanOffset =
        spectator.rowIndex == 0 ? (spectator.leanInFactor * 0.08 * (1.0 - parting)) : 0.0;
    final double extraStepBack =
        (config.partingClearanceHalfWidthMeters - config.corridorHalfWidthMeters) *
            parting *
            rowAttenuation;

    final double effectiveAbs = math.max(
      config.corridorHalfWidthMeters - 0.1,
      baseAbs - leanOffset + extraStepBack,
    );

    final double frontRowAbs = _lerpDouble(
      config.corridorHalfWidthMeters,
      config.partingClearanceHalfWidthMeters,
      parting,
    );

    return CrowdSpectatorPartingResult(
      effectiveLateralOffsetMeters: sign * effectiveAbs,
      partingAmount: parting,
      corridorWidthAtSpectatorMeters: frontRowAbs * 2.0,
    );
  }

  /// Generuje deterministycznie tłum kibiców, flag i flar dla widocznego okna trasy.
  List<AlpineCrowdTunnelSpectator3D> buildVisibleSpectators({
    required double cameraCourseDistanceMeters,
    required double currentGradientPercent,
    required double Function(double distanceMeters) elevationAtDistance,
    List<AlpineCrowdTunnelZone> zones = const <AlpineCrowdTunnelZone>[],
  }) {
    if (!config.enabled) {
      return const <AlpineCrowdTunnelSpectator3D>[];
    }

    final double minDist =
        math.max(0.0, cameraCourseDistanceMeters - config.backwardVisibilityMeters);
    final double maxDist =
        cameraCourseDistanceMeters + config.forwardVisibilityMeters;

    final List<AlpineCrowdTunnelSpectator3D> result =
        <AlpineCrowdTunnelSpectator3D>[];

    final double step = math.max(0.75, config.spectatorSpacingMeters);
    final int startIndex = (minDist / step).floor();
    final int endIndex = (maxDist / step).ceil();
    final int rows = config.maxRowsPerSide.clamp(1, 4);

    for (int idx = startIndex; idx <= endIndex; idx++) {
      final double distM = idx * step;
      if (distM < minDist || distM > maxDist) continue;

      final bool inZone = zones.isNotEmpty
          ? zones.any((AlpineCrowdTunnelZone z) => z.containsDistance(distM))
          : currentGradientPercent > config.minGradientPercent;
      if (!inZone) continue;

      final double elevM = elevationAtDistance(distM);

      for (int side = 0; side < 2; side++) {
        final bool isRight = side == 1;
        final double sign = isRight ? 1.0 : -1.0;

        for (int row = 0; row < rows; row++) {
          final int seed = _hashInts(idx, side * 17 + row * 53, 180);
          // W 2. i 3. rzędzie drobna szansa przerwy dla naturalności tłumu.
          if (row >= 2 && (seed % 5 == 0)) continue;

          final double jitterLongitudinal = ((seed % 100) / 100.0 - 0.5) * 0.42;
          final double specDist = distM + jitterLongitudinal;

          const double rowDepthSpacing = 0.62;
          final double jitterLateral = (((seed >> 4) % 100) / 100.0) * 0.16;
          final double baseLateral = sign *
              (config.corridorHalfWidthMeters + row * rowDepthSpacing + jitterLateral);

          final CrowdTunnelNationJersey nation = CrowdTunnelNationJersey
              .values[(seed >> 2) % CrowdTunnelNationJersey.values.length];

          final bool hasFlag =
              config.enableFlags && ((seed >> 7) % (row == 0 ? 7 : 5) == 0);
          final double flagPoleHeight =
              1.95 + (((seed >> 10) % 100) / 100.0) * 0.85;

          // Flary częściej w gęstych skupiskach po obu stronach korytarza.
          final bool hasFlare =
              config.enableFlareSmoke && ((seed >> 9) % 11 == 0) && row <= 1;
          final CrowdTunnelFlareColor? flareColor = hasFlare
              ? ((seed >> 13) % 2 == 0
                  ? CrowdTunnelFlareColor.orange
                  : CrowdTunnelFlareColor.red)
              : null;

          final double heightM = 1.66 + (((seed >> 6) % 100) / 100.0) * 0.24;
          final double phase = (((seed >> 3) % 360) * math.pi) / 180.0;
          final double leanIn = ((seed >> 11) % 100) / 100.0;

          result.add(
            AlpineCrowdTunnelSpectator3D(
              id: 'spec_${idx}_${side}_$row',
              distanceMeters: specDist,
              baseLateralOffsetMeters: baseLateral,
              elevationMeters: elevM,
              isRightSide: isRight,
              rowIndex: row,
              nation: nation,
              hasFlag: hasFlag,
              flagPoleHeightMeters: flagPoleHeight,
              hasFlare: hasFlare,
              flareColor: flareColor,
              heightMeters: heightM,
              animationPhase: phase,
              leanInFactor: leanIn,
            ),
          );
        }
      }
    }

    return result;
  }

  /// Renderuje pełny Tunel Kibiców na płótnie 3D i zwraca telemetrię klatki.
  AlpineCrowdTunnelTelemetry paint({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required RoadGeometryParameters roadGeometry,
    required double cameraCourseDistanceMeters,
    required double leaderFrontWheelDistanceMeters,
    required double elapsedSeconds,
    required double Function(double distanceMeters) elevationAtDistance,
    List<AlpineCrowdTunnelZone> zones = const <AlpineCrowdTunnelZone>[],
    List<double> riderDistancesMeters = const <double>[],
    double windDirectionDegrees = 250.0,
    double windSpeedMs = 4.5,
    TunnelCoursePoseResolver? poseResolver,
  }) {
    if (!config.enabled || size.width <= 0.0 || size.height <= 0.0) {
      return AlpineCrowdTunnelTelemetry.inactive(
        currentGradientPercent: roadGeometry.gradientPercent,
      );
    }

    final List<AlpineCrowdTunnelSpectator3D> spectators = buildVisibleSpectators(
      cameraCourseDistanceMeters: cameraCourseDistanceMeters,
      currentGradientPercent: roadGeometry.gradientPercent,
      elevationAtDistance: elevationAtDistance,
      zones: zones,
    );

    if (spectators.isEmpty) {
      return AlpineCrowdTunnelTelemetry.inactive(
        currentGradientPercent: roadGeometry.gradientPercent,
      );
    }

    final TunnelCoursePoseResolver resolvePose =
        poseResolver ?? Scene3DMathProjection.courseToCyclistPose;

    if (config.showCorridorBoundsGuide) {
      _paintCorridorBoundsGuide(
        canvas: canvas,
        projection: projection,
        roadGeometry: roadGeometry,
        cameraCourseDistanceMeters: cameraCourseDistanceMeters,
        leaderFrontWheelDistanceMeters: leaderFrontWheelDistanceMeters,
        riderDistancesMeters: riderDistancesMeters,
        elevationAtDistance: elevationAtDistance,
        resolvePose: resolvePose,
      );
    }

    final List<_ProjectedTunnelElement> drawQueue = <_ProjectedTunnelElement>[];
    int flagsCount = 0;
    int flaresCount = 0;
    int partingCount = 0;

    final double windRad = windDirectionDegrees * math.pi / 180.0;
    final Vector3 windVector = Vector3(
      math.sin(windRad) * windSpeedMs,
      0.0,
      math.cos(windRad) * windSpeedMs,
    );

    for (final AlpineCrowdTunnelSpectator3D spec in spectators) {
      final CrowdSpectatorPartingResult partingResult = computeSpectatorParting(
        spectator: spec,
        leaderFrontWheelDistanceMeters: leaderFrontWheelDistanceMeters,
        riderDistancesMeters: riderDistancesMeters,
      );
      if (partingResult.partingAmount > 0.08) {
        partingCount++;
      }

      final Cyclist3DPose basePose = resolvePose(
        coursePosition: CoursePosition(
          distanceMeters: spec.distanceMeters,
          lateralOffsetMeters: partingResult.effectiveLateralOffsetMeters,
          elevationMeters: spec.elevationMeters,
          verticalOffsetMeters: 0.0,
        ),
        roadGeometry: roadGeometry,
      );

      final ProjectedPoint3D feetProj =
          projection.worldToScreen(basePose.position);
      if (!feetProj.isInFrontOfCamera) continue;

      final double jumpBounce =
          math.max(0.0, math.sin(elapsedSeconds * 5.2 + spec.animationPhase)) *
              0.08;
      final Vector3 headWorld = basePose.position +
          basePose.surfaceNormal * (spec.heightMeters + jumpBounce);
      final ProjectedPoint3D headProj = projection.worldToScreen(headWorld);
      if (!headProj.isInFrontOfCamera) continue;

      // Frustum margin check
      if (feetProj.screenX < -120.0 ||
          feetProj.screenX > size.width + 120.0 ||
          feetProj.screenY < -160.0 ||
          feetProj.screenY > size.height + 160.0) {
        continue;
      }

      if (spec.hasFlag) flagsCount++;
      if (spec.hasFlare) flaresCount++;

      drawQueue.add(
        _ProjectedTunnelElement(
          depthEye: feetProj.depthEye,
          draw: (Canvas c) => _drawSpectatorWithProps(
            canvas: c,
            projection: projection,
            spec: spec,
            basePose: basePose,
            feetProj: feetProj,
            headProj: headProj,
            partingAmount: partingResult.partingAmount,
            elapsedSeconds: elapsedSeconds,
            windVector: windVector,
          ),
        ),
      );

      if (spec.hasFlare && spec.flareColor != null) {
        final Vector3 flareTipWorld = basePose.position +
            basePose.surfaceNormal * (spec.heightMeters * 0.92 + jumpBounce) -
            basePose.lateralRight * (spec.isRightSide ? 0.25 : -0.25);

        _enqueueFlareSmokePuffs(
          drawQueue: drawQueue,
          projection: projection,
          flareOrigin: flareTipWorld,
          flareColor: spec.flareColor!,
          elapsedSeconds: elapsedSeconds,
          animationPhase: spec.animationPhase,
          windVector: windVector,
        );
      }
    }

    // Painter's Algorithm: najdalsze obiekty rysowane jako pierwsze.
    drawQueue.sort(
      (_ProjectedTunnelElement a, _ProjectedTunnelElement b) =>
          b.depthEye.compareTo(a.depthEye),
    );
    for (final _ProjectedTunnelElement element in drawQueue) {
      element.draw(canvas);
    }

    final double currentCorridor = computeCorridorWidthAtDistance(
      distanceMeters:
          leaderFrontWheelDistanceMeters + config.partingTriggerAheadMeters + 2.0,
      gradientPercent: roadGeometry.gradientPercent,
      leaderFrontWheelDistanceMeters: leaderFrontWheelDistanceMeters,
      riderDistancesMeters: riderDistancesMeters,
    );

    return AlpineCrowdTunnelTelemetry(
      isTunnelActive: true,
      currentGradientPercent: roadGeometry.gradientPercent,
      activeCorridorWidthMeters: currentCorridor,
      visibleSpectatorsCount: spectators.length,
      activeFlagsCount: flagsCount,
      activeFlaresCount: flaresCount,
      partingSpectatorsCount: partingCount,
    );
  }

  // ===========================================================================
  // 4. WEWNĘTRZNA LOGIKA ROZSTĘPOWANIA I RYSOWANIA 3D
  // ===========================================================================

  double _computePartingFactor({
    required double spectatorDistanceMeters,
    required double leaderFrontWheelDistanceMeters,
    required List<double> riderDistancesMeters,
  }) {
    double maxParting = 0.0;

    // 1. Rozstępowanie się kibiców tuż przed przednim kołem lidera.
    final double deltaAhead =
        spectatorDistanceMeters - leaderFrontWheelDistanceMeters;
    if (deltaAhead >= -3.5 && deltaAhead <= config.partingTriggerAheadMeters) {
      if (deltaAhead <= config.partingPeakDistanceMeters) {
        maxParting = 1.0;
      } else {
        final double span = math.max(
          0.5,
          config.partingTriggerAheadMeters - config.partingPeakDistanceMeters,
        );
        final double t =
            ((config.partingTriggerAheadMeters - deltaAhead) / span).clamp(0.0, 1.0);
        // Płynne przyspieszenie rozstępowania w ostatniej chwili przed kołem.
        maxParting = t * t * (3.0 - 2.0 * t);
      }
    }

    // 2. Utrzymanie odsunięcia, gdy przez strefę przejeżdżają kolejni kolarze peletonu.
    for (final double riderDist in riderDistancesMeters) {
      final double d = spectatorDistanceMeters - riderDist;
      if (d >= -3.0 && d <= 5.5) {
        final double localFactor =
            d <= 1.5 ? 1.0 : (1.0 - (d - 1.5) / 4.0).clamp(0.0, 1.0);
        if (localFactor > maxParting) {
          maxParting = localFactor;
        }
      }
    }

    return maxParting.clamp(0.0, 1.0);
  }

  void _paintCorridorBoundsGuide({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required RoadGeometryParameters roadGeometry,
    required double cameraCourseDistanceMeters,
    required double leaderFrontWheelDistanceMeters,
    required List<double> riderDistancesMeters,
    required double Function(double distanceMeters) elevationAtDistance,
    required TunnelCoursePoseResolver resolvePose,
  }) {
    final double startM =
        math.max(0.0, cameraCourseDistanceMeters - 10.0);
    final double endM = cameraCourseDistanceMeters + 90.0;
    const double sampleStep = 4.0;

    final Path leftEdge = Path();
    final Path rightEdge = Path();
    bool hasLeft = false;
    bool hasRight = false;

    for (double d = startM; d <= endM; d += sampleStep) {
      final double width = computeCorridorWidthAtDistance(
        distanceMeters: d,
        gradientPercent: roadGeometry.gradientPercent,
        leaderFrontWheelDistanceMeters: leaderFrontWheelDistanceMeters,
        riderDistancesMeters: riderDistancesMeters,
      );
      final double halfW = width * 0.5;
      final double elev = elevationAtDistance(d);

      final Cyclist3DPose leftPose = resolvePose(
        coursePosition: CoursePosition(
          distanceMeters: d,
          lateralOffsetMeters: -halfW,
          elevationMeters: elev,
        ),
        roadGeometry: roadGeometry,
      );
      final Cyclist3DPose rightPose = resolvePose(
        coursePosition: CoursePosition(
          distanceMeters: d,
          lateralOffsetMeters: halfW,
          elevationMeters: elev,
        ),
        roadGeometry: roadGeometry,
      );

      final ProjectedPoint3D lp = projection.worldToScreen(leftPose.position);
      final ProjectedPoint3D rp = projection.worldToScreen(rightPose.position);

      if (lp.isInFrontOfCamera) {
        if (!hasLeft) {
          leftEdge.moveTo(lp.screenX, lp.screenY);
          hasLeft = true;
        } else {
          leftEdge.lineTo(lp.screenX, lp.screenY);
        }
      }
      if (rp.isInFrontOfCamera) {
        if (!hasRight) {
          rightEdge.moveTo(rp.screenX, rp.screenY);
          hasRight = true;
        } else {
          rightEdge.lineTo(rp.screenX, rp.screenY);
        }
      }
    }

    final Paint corridorPaint = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    if (hasLeft) canvas.drawPath(leftEdge, corridorPaint);
    if (hasRight) canvas.drawPath(rightEdge, corridorPaint);
  }

  void _drawSpectatorWithProps({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required AlpineCrowdTunnelSpectator3D spec,
    required Cyclist3DPose basePose,
    required ProjectedPoint3D feetProj,
    required ProjectedPoint3D headProj,
    required double partingAmount,
    required double elapsedSeconds,
    required Vector3 windVector,
  }) {
    final double pixelHeight =
        (feetProj.screenY - headProj.screenY).abs().clamp(8.0, 220.0);
    final double bodyWidth = (pixelHeight * 0.32).clamp(3.0, 68.0);
    final double depthFade =
        (1.0 - (feetProj.depthEye / 220.0)).clamp(0.28, 1.0);

    // 1. Miękki cień kontaktowy pod stopami kibica.
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.34 * depthFade);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(feetProj.screenX, feetProj.screenY),
        width: bodyWidth * 1.15,
        height: bodyWidth * 0.38,
      ),
      shadowPaint,
    );

    // 2. Nogi (ciemne spodnie).
    final double hipY = feetProj.screenY - pixelHeight * 0.44;
    final double shoulderY = feetProj.screenY - pixelHeight * 0.78;
    final double headRadius = (pixelHeight * 0.105).clamp(1.6, 18.0);
    final double headY = shoulderY - headRadius * 1.15;

    final Paint legPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.92 * depthFade)
      ..strokeWidth = (bodyWidth * 0.28).clamp(1.2, 14.0)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(feetProj.screenX - bodyWidth * 0.2, feetProj.screenY),
      Offset(feetProj.screenX - bodyWidth * 0.14, hipY),
      legPaint,
    );
    canvas.drawLine(
      Offset(feetProj.screenX + bodyWidth * 0.2, feetProj.screenY),
      Offset(feetProj.screenX + bodyWidth * 0.14, hipY),
      legPaint,
    );

    // 3. Tułów w koszulce narodowej.
    final RRect torsoRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        feetProj.screenX - bodyWidth * 0.45,
        shoulderY,
        feetProj.screenX + bodyWidth * 0.45,
        hipY,
      ),
      Radius.circular((bodyWidth * 0.18).clamp(1.0, 6.0)),
    );
    final Paint jerseyPaint = Paint()
      ..color = spec.nation.primaryColor.withValues(alpha: depthFade);
    canvas.drawRRect(torsoRect, jerseyPaint);

    // Narodowy pas na piersi dla lepszej czytelności barw.
    if (pixelHeight > 20.0) {
      final Paint stripePaint = Paint()
        ..color = spec.nation.secondaryColor.withValues(alpha: 0.9 * depthFade);
      canvas.drawRect(
        Rect.fromLTRB(
          feetProj.screenX - bodyWidth * 0.43,
          shoulderY + (hipY - shoulderY) * 0.35,
          feetProj.screenX + bodyWidth * 0.43,
          shoulderY + (hipY - shoulderY) * 0.56,
        ),
        stripePaint,
      );
    }

    // 4. Uniesione / wiwatujące ramiona (kiedy rozstępuje się przed liderem, lekki gest cofnięcia).
    final double armWave =
        math.sin(elapsedSeconds * 7.5 + spec.animationPhase) *
            bodyWidth *
            0.25 *
            (1.0 - partingAmount * 0.4);
    final Paint armPaint = Paint()
      ..color = spec.nation.primaryColor.withValues(alpha: 0.95 * depthFade)
      ..strokeWidth = (bodyWidth * 0.2).clamp(1.0, 10.0)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(feetProj.screenX - bodyWidth * 0.42, shoulderY + 2.0),
      Offset(
        feetProj.screenX - bodyWidth * 0.72 + armWave,
        shoulderY - pixelHeight * 0.18,
      ),
      armPaint,
    );
    canvas.drawLine(
      Offset(feetProj.screenX + bodyWidth * 0.42, shoulderY + 2.0),
      Offset(
        feetProj.screenX + bodyWidth * 0.72 - armWave,
        shoulderY - pixelHeight * 0.18,
      ),
      armPaint,
    );

    // 5. Głowa kibica.
    final Paint skinPaint = Paint()
      ..color = const Color(0xFFE5B89B).withValues(alpha: depthFade);
    canvas.drawCircle(
      Offset(feetProj.screenX, headY),
      headRadius,
      skinPaint,
    );

    // 6. Flaga narodowa na drzewcu.
    if (spec.hasFlag && pixelHeight > 14.0) {
      _drawNationalFlag(
        canvas: canvas,
        projection: projection,
        spec: spec,
        basePose: basePose,
        handScreenPos: Offset(
          feetProj.screenX + (spec.isRightSide ? -bodyWidth * 0.65 : bodyWidth * 0.65),
          shoulderY - pixelHeight * 0.15,
        ),
        depthFade: depthFade,
        elapsedSeconds: elapsedSeconds,
        windVector: windVector,
      );
    }

    // 7. Płonąca raca / flara w dłoni kibica.
    if (spec.hasFlare && spec.flareColor != null) {
      final Offset flareScreenPos = Offset(
        feetProj.screenX + (spec.isRightSide ? -bodyWidth * 0.72 : bodyWidth * 0.72),
        shoulderY - pixelHeight * 0.22,
      );
      final double glowRadius = (bodyWidth * 0.55).clamp(3.0, 24.0);
      final Paint coreGlow = Paint()
        ..color = spec.flareColor!.coreColor.withValues(alpha: 0.9 * depthFade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(flareScreenPos, glowRadius, coreGlow);
      canvas.drawCircle(
        flareScreenPos,
        glowRadius * 0.36,
        Paint()..color = Colors.white.withValues(alpha: 0.95 * depthFade),
      );
    }
  }

  void _drawNationalFlag({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required AlpineCrowdTunnelSpectator3D spec,
    required Cyclist3DPose basePose,
    required Offset handScreenPos,
    required double depthFade,
    required double elapsedSeconds,
    required Vector3 windVector,
  }) {
    final Vector3 poleBase =
        basePose.position + basePose.surfaceNormal * (spec.heightMeters * 0.85);
    final Vector3 poleTip =
        poleBase + basePose.surfaceNormal * spec.flagPoleHeightMeters;
    final ProjectedPoint3D tipProj = projection.worldToScreen(poleTip);
    if (!tipProj.isInFrontOfCamera) return;

    final Paint polePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.85 * depthFade)
      ..strokeWidth = (1.6 * tipProj.perspectiveScale).clamp(0.8, 3.0);
    canvas.drawLine(
      handScreenPos,
      Offset(tipProj.screenX, tipProj.screenY),
      polePaint,
    );

    final double flagW =
        (26.0 * tipProj.perspectiveScale).clamp(6.0, 58.0);
    final double flagH = flagW * 0.62;
    final double flutter =
        math.sin(elapsedSeconds * 9.0 + spec.animationPhase) * flagH * 0.22;
    final double windDirSign =
        windVector.x >= 0 ? 1.0 : -1.0;

    final Offset topPole = Offset(tipProj.screenX, tipProj.screenY);
    final List<Color> bands = spec.nation.flagBands;
    final double bandHeight = flagH / bands.length;

    for (int i = 0; i < bands.length; i++) {
      final double y0 = topPole.dy + i * bandHeight;
      final double y1 = y0 + bandHeight;
      final Path bandPath = Path()
        ..moveTo(topPole.dx, y0)
        ..quadraticBezierTo(
          topPole.dx + windDirSign * flagW * 0.5,
          y0 + flutter * 0.6,
          topPole.dx + windDirSign * flagW,
          y0 + flutter,
        )
        ..lineTo(topPole.dx + windDirSign * flagW, y1 + flutter)
        ..quadraticBezierTo(
          topPole.dx + windDirSign * flagW * 0.5,
          y1 + flutter * 0.6,
          topPole.dx,
          y1,
        )
        ..close();

      canvas.drawPath(
        bandPath,
        Paint()..color = bands[i].withValues(alpha: 0.92 * depthFade),
      );
    }
  }

  void _enqueueFlareSmokePuffs({
    required List<_ProjectedTunnelElement> drawQueue,
    required Scene3DMathProjection projection,
    required Vector3 flareOrigin,
    required CrowdTunnelFlareColor flareColor,
    required double elapsedSeconds,
    required double animationPhase,
    required Vector3 windVector,
  }) {
    const int puffsPerFlare = 7;
    for (int i = 0; i < puffsPerFlare; i++) {
      final double life =
          ((elapsedSeconds * 0.45 + animationPhase + i / puffsPerFlare) % 1.0);
      final double riseMeters = 0.25 + life * 4.2;
      final double driftX =
          windVector.x * life * 0.75 + math.sin(life * 6.0 + i) * 0.28;
      final double driftZ =
          windVector.z * life * 0.75 + math.cos(life * 5.0 + i) * 0.25;

      final Vector3 puffWorld = flareOrigin + Vector3(driftX, riseMeters, driftZ);
      final ProjectedPoint3D puffProj = projection.worldToScreen(puffWorld);
      if (!puffProj.isInFrontOfCamera) continue;

      final double radiusPx =
          ((0.35 + life * 1.15) * 24.0 * puffProj.perspectiveScale)
              .clamp(4.0, 96.0);
      final double alpha =
          (math.sin(life * math.pi) * 0.46).clamp(0.0, 0.48);
      if (alpha <= 0.02) continue;

      final Color puffColor = Color.lerp(
            flareColor.midColor,
            flareColor.plumeColor,
            life,
          ) ??
          flareColor.plumeColor;

      drawQueue.add(
        _ProjectedTunnelElement(
          depthEye: puffProj.depthEye,
          draw: (Canvas c) {
            final Paint puffPaint = Paint()
              ..color = puffColor.withValues(alpha: alpha)
              ..maskFilter = MaskFilter.blur(
                BlurStyle.normal,
                (radiusPx * 0.35).clamp(2.0, 18.0),
              );
            c.drawCircle(
              Offset(puffProj.screenX, puffProj.screenY),
              radiusPx,
              puffPaint,
            );
          },
        ),
      );
    }
  }

  static int _hashInts(int a, int b, int c) {
    int h = 0x811C9DC5;
    h = (h ^ a) * 0x01000193;
    h = (h ^ b) * 0x01000193;
    h = (h ^ c) * 0x01000193;
    return h & 0x7FFFFFFF;
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class _ProjectedTunnelElement {
  final double depthEye;
  final void Function(Canvas canvas) draw;

  const _ProjectedTunnelElement({
    required this.depthEye,
    required this.draw,
  });
}

// =============================================================================
// 4. INTERAKTYWNY PANEL STEROWANIA I TELEMETRII TUNELU KIBICÓW (HUD / UI)
// =============================================================================

/// Responsywny panel sterowania i telemetrii efektu "Tunelu Kibiców" w palecie [AppColors]
/// z obsługą stanów `hover`, `active`, `disabled` i `focus` dla rozdzielczości 390x844 / 1024x768 / 1600x900.
class AlpineCrowdTunnelControlPanel extends StatelessWidget {
  final AlpineCrowdTunnelConfig config;
  final AlpineCrowdTunnelTelemetry telemetry;
  final ValueChanged<AlpineCrowdTunnelConfig> onConfigChanged;

  const AlpineCrowdTunnelControlPanel({
    super.key,
    required this.config,
    required this.telemetry,
    required this.onConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 520.0;
        final bool isWide = constraints.maxWidth >= 980.0;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: telemetry.isTunnelActive
                  ? AppColors.amberWarning.withValues(alpha: 0.65)
                  : AppColors.cardBorder,
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(isCompact),
              const SizedBox(height: 12.0),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: _buildTelemetryGrid(isCompact)),
                    const SizedBox(width: 16.0),
                    Expanded(flex: 2, child: _buildToggleControls()),
                  ],
                )
              else ...<Widget>[
                _buildTelemetryGrid(isCompact),
                const SizedBox(height: 12.0),
                _buildToggleControls(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final bool active = telemetry.isTunnelActive;
    final Color badgeColor =
        active ? AppColors.amberWarning : AppColors.textSecondary;

    return Row(
      children: <Widget>[
        Container(
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            'TUNEL KIBICÓW (>8% NACHYLENIA)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 12.5 : 14.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: active
                ? AppColors.amberWarning.withValues(alpha: 0.18)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: active ? AppColors.amberWarning : AppColors.cardBorder,
            ),
          ),
          child: Text(
            active ? 'AKTYWNY' : 'OCZEKUJE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: active ? AppColors.amberWarning : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryGrid(bool isCompact) {
    final List<Widget> metrics = <Widget>[
      _TunnelMetricTile(
        label: 'Nachylenie',
        value: '${telemetry.currentGradientPercent.toStringAsFixed(1)}%',
        accent: telemetry.currentGradientPercent > config.minGradientPercent
            ? AppColors.crimsonAlert
            : AppColors.textPrimary,
      ),
      _TunnelMetricTile(
        label: 'Korytarz',
        value: '${telemetry.activeCorridorWidthMeters.toStringAsFixed(1)} m',
        accent: telemetry.isTunnelActive
            ? AppColors.goldAccent
            : AppColors.textPrimary,
      ),
      _TunnelMetricTile(
        label: 'Kibice / Flagi',
        value:
            '${telemetry.visibleSpectatorsCount} / ${telemetry.activeFlagsCount}',
        accent: AppColors.accentBlue,
      ),
      _TunnelMetricTile(
        label: 'Flary / Odstęp',
        value:
            '${telemetry.activeFlaresCount} / ${telemetry.partingSpectatorsCount}',
        accent: AppColors.amberWarning,
      ),
    ];

    return GridView.count(
      crossAxisCount: isCompact ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      childAspectRatio: isCompact ? 2.15 : 1.75,
      children: metrics,
    );
  }

  Widget _buildToggleControls() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: <Widget>[
        _TunnelActionChip(
          label: 'Tunel 2.8m',
          icon: Icons.groups_rounded,
          isActive: config.enabled,
          isDisabled: false,
          onTap: () => onConfigChanged(
            config.copyWith(enabled: !config.enabled),
          ),
        ),
        _TunnelActionChip(
          label: 'Flagi',
          icon: Icons.flag_rounded,
          isActive: config.enableFlags,
          isDisabled: !config.enabled,
          onTap: () => onConfigChanged(
            config.copyWith(enableFlags: !config.enableFlags),
          ),
        ),
        _TunnelActionChip(
          label: 'Dym z Flar',
          icon: Icons.local_fire_department_rounded,
          isActive: config.enableFlareSmoke,
          isDisabled: !config.enabled,
          onTap: () => onConfigChanged(
            config.copyWith(enableFlareSmoke: !config.enableFlareSmoke),
          ),
        ),
        _TunnelActionChip(
          label: 'Linia Korytarza',
          icon: Icons.straighten_rounded,
          isActive: config.showCorridorBoundsGuide,
          isDisabled: !config.enabled,
          onTap: () => onConfigChanged(
            config.copyWith(
              showCorridorBoundsGuide: !config.showCorridorBoundsGuide,
            ),
          ),
        ),
      ],
    );
  }
}

class _TunnelMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TunnelMetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.0,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2.0),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TunnelActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _TunnelActionChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_TunnelActionChip> createState() => _TunnelActionChipState();
}

class _TunnelActionChipState extends State<_TunnelActionChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.isDisabled;
    final bool active = widget.isActive && !disabled;

    Color bgColor = AppColors.surfaceLight;
    Color borderColor = AppColors.cardBorder;
    Color fgColor = AppColors.textSecondary;

    if (disabled) {
      bgColor = AppColors.surface.withValues(alpha: 0.6);
      borderColor = AppColors.cardBorder.withValues(alpha: 0.4);
      fgColor = AppColors.textSecondary.withValues(alpha: 0.4);
    } else if (active) {
      bgColor = _isPressed
          ? AppColors.primaryAccent.withValues(alpha: 0.45)
          : _isHovered
              ? AppColors.primaryAccent.withValues(alpha: 0.35)
              : AppColors.primaryAccent.withValues(alpha: 0.24);
      borderColor = _isFocused ? AppColors.goldAccent : AppColors.primaryAccent;
      fgColor = AppColors.textPrimary;
    } else {
      bgColor = _isPressed
          ? AppColors.surface
          : _isHovered
              ? AppColors.surfaceLight.withValues(alpha: 0.9)
              : AppColors.surfaceLight;
      borderColor = _isFocused
          ? AppColors.goldAccent
          : _isHovered
              ? AppColors.textSecondary.withValues(alpha: 0.6)
              : AppColors.cardBorder;
      fgColor = _isHovered ? AppColors.textPrimary : AppColors.textSecondary;
    }

    return FocusableActionDetector(
      enabled: !disabled,
      onShowFocusHighlight: (bool focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      onShowHoverHighlight: (bool hovered) {
        if (_isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _isPressed = false),
          onTapCancel: disabled ? null : () => setState(() => _isPressed = false),
          onTap: disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(widget.icon, size: 15.0, color: fgColor),
                const SizedBox(width: 6.0),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.0,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                    color: fgColor,
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
