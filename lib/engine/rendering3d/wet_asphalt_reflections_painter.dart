// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import 'peloton_3d_canvas_engine.dart';
import 'scene_3d_math_projection.dart';

/// Poziom jakości renderowania odbić na mokrym asfalcie.
enum WetAsphaltReflectionQuality {
  /// Pełne odbicia sylwetek, koszulek liderów, kałuż z falami i suchych kolein peletonu.
  high,

  /// Zrównoważone odbicia koszulek, kałuże bez drobnych fal i suche koleiny.
  balanced,

  /// Tryb wydajnościowy 120 FPS: przyciemniony mokry asfalt, główne koleiny i uproszczone odbicia.
  performance,
}

/// Konfiguracja parametrów wizualnych i wydajnościowych [WetAsphaltReflectionsPainter].
class WetAsphaltReflectionsConfig {
  final WetAsphaltReflectionQuality quality;
  final bool enableDarkenedAsphalt;
  final bool enablePuddles;
  final bool enableRiderReflections;
  final bool enablePelotonDryRuts;
  final bool enableRainRipples;
  final double maxReflectionDistanceMeters;
  final double maxPuddleDistanceMeters;
  final double puddleDensityScale;
  final double reflectionIntensityScale;

  const WetAsphaltReflectionsConfig({
    this.quality = WetAsphaltReflectionQuality.high,
    this.enableDarkenedAsphalt = true,
    this.enablePuddles = true,
    this.enableRiderReflections = true,
    this.enablePelotonDryRuts = true,
    this.enableRainRipples = true,
    this.maxReflectionDistanceMeters = 120.0,
    this.maxPuddleDistanceMeters = 155.0,
    this.puddleDensityScale = 1.0,
    this.reflectionIntensityScale = 1.0,
  });

  WetAsphaltReflectionsConfig copyWith({
    WetAsphaltReflectionQuality? quality,
    bool? enableDarkenedAsphalt,
    bool? enablePuddles,
    bool? enableRiderReflections,
    bool? enablePelotonDryRuts,
    bool? enableRainRipples,
    double? maxReflectionDistanceMeters,
    double? maxPuddleDistanceMeters,
    double? puddleDensityScale,
    double? reflectionIntensityScale,
  }) {
    return WetAsphaltReflectionsConfig(
      quality: quality ?? this.quality,
      enableDarkenedAsphalt: enableDarkenedAsphalt ?? this.enableDarkenedAsphalt,
      enablePuddles: enablePuddles ?? this.enablePuddles,
      enableRiderReflections: enableRiderReflections ?? this.enableRiderReflections,
      enablePelotonDryRuts: enablePelotonDryRuts ?? this.enablePelotonDryRuts,
      enableRainRipples: enableRainRipples ?? this.enableRainRipples,
      maxReflectionDistanceMeters: maxReflectionDistanceMeters ?? this.maxReflectionDistanceMeters,
      maxPuddleDistanceMeters: maxPuddleDistanceMeters ?? this.maxPuddleDistanceMeters,
      puddleDensityScale: puddleDensityScale ?? this.puddleDensityScale,
      reflectionIntensityScale: reflectionIntensityScale ?? this.reflectionIntensityScale,
    );
  }
}

/// Stan wilgotności i oświetlenia nawierzchni dla efektu mokrego asfaltu.
class WetAsphaltSurfaceState {
  /// Stopień zawilgocenia jezdni [0.0 = suchy asfalt, 1.0 = ulewa / tafla wody].
  final double wetness;

  /// Aktualna intensywność opadu deszczu [0.0 = brak opadu (po deszczu), 1.0 = ulewa].
  final double rainIntensity;

  /// Czas animacji w sekundach (napędza zmarszczki na kałużach i migotanie odbić).
  final double animationTimeSeconds;

  /// Kolor nieba przy horyzoncie odbijany w kałużach.
  final Color skyHorizonColor;

  /// Kolor zenitu nieba odbijany w wodzie.
  final Color skyZenithColor;

  /// Znormalizowany wektor kierunku światła słonecznego/rozproszonego.
  final Vector3 sunDirection;

  const WetAsphaltSurfaceState({
    required this.wetness,
    this.rainIntensity = 0.0,
    this.animationTimeSeconds = 0.0,
    this.skyHorizonColor = const Color(0xFF475569),
    this.skyZenithColor = const Color(0xFF1E293B),
    required this.sunDirection,
  });

  factory WetAsphaltSurfaceState.dry() {
    return WetAsphaltSurfaceState(
      wetness: 0.0,
      rainIntensity: 0.0,
      sunDirection: Vector3(0.3, 0.85, 0.4).normalized(),
    );
  }

  bool get isWet => wetness > 0.02;

  WetAsphaltSurfaceState copyWith({
    double? wetness,
    double? rainIntensity,
    double? animationTimeSeconds,
    Color? skyHorizonColor,
    Color? skyZenithColor,
    Vector3? sunDirection,
  }) {
    return WetAsphaltSurfaceState(
      wetness: wetness ?? this.wetness,
      rainIntensity: rainIntensity ?? this.rainIntensity,
      animationTimeSeconds: animationTimeSeconds ?? this.animationTimeSeconds,
      skyHorizonColor: skyHorizonColor ?? this.skyHorizonColor,
      skyZenithColor: skyZenithColor ?? this.skyZenithColor,
      sunDirection: sunDirection ?? this.sunDirection,
    );
  }
}

/// Dane pojedynczej kałuży na powierzchni szosy w przestrzeni 3D.
class WetAsphaltPuddle {
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double lengthMeters;
  final double widthMeters;
  final double depthFactor;
  final int seed;

  const WetAsphaltPuddle({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.lengthMeters,
    required this.widthMeters,
    required this.depthFactor,
    required this.seed,
  });
}

/// Pas suchej lub półsuchej koleiny wyjeżdżonej przez przejeżdżający peleton.
class PelotonTireRutTrack {
  /// Poprzeczne przesunięcie środka koleiny względem osi drogi [m].
  final double lateralOffsetMeters;

  /// Szerokość wyjeżdżonego pasa suchego asfaltu [m].
  final double widthMeters;

  /// Stopień osuszenia nawierzchni w koleinie [0.0 = mokra, 1.0 = wyraźnie wysuszona].
  final double drynessFactor;

  /// Dystans początkowy śladu [m].
  final double startDistanceMeters;

  /// Dystans końcowy śladu [m].
  final double endDistanceMeters;

  const PelotonTireRutTrack({
    required this.lateralOffsetMeters,
    required this.widthMeters,
    required this.drynessFactor,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
  });
}

/// Dane kolarza potrzebne do wyrenderowania jego lustrzanego odbicia w kałuży i na mokrym asfalcie.
class WetAsphaltRiderReflectionInput {
  final String riderId;
  final Vector3 baseWorldPosition;
  final Vector3 roadTangent;
  final Vector3 roadRight;
  final Vector3 roadNormal;
  final Color jerseyColor;
  final LeaderJerseyType leaderJersey;
  final double leanAngleRadians;
  final double riderHeightMeters;
  final double lateralOffsetMeters;
  final double distanceMeters;
  final double speedMs;
  final bool isStanding;
  final bool isAeroTuck;
  final bool isCrashed;
  final bool isPlayerRider;

  const WetAsphaltRiderReflectionInput({
    required this.riderId,
    required this.baseWorldPosition,
    required this.roadTangent,
    required this.roadRight,
    required this.roadNormal,
    required this.jerseyColor,
    this.leaderJersey = LeaderJerseyType.none,
    this.leanAngleRadians = 0.0,
    this.riderHeightMeters = 1.48,
    this.lateralOffsetMeters = 0.0,
    this.distanceMeters = 0.0,
    this.speedMs = 11.0,
    this.isStanding = false,
    this.isAeroTuck = false,
    this.isCrashed = false,
    this.isPlayerRider = false,
  });

  /// Buduje dane odbicia z modelu silnika [Peloton3dRiderRenderData] oraz próbki drogi [Peloton3dRoadNode].
  factory WetAsphaltRiderReflectionInput.fromPeloton3d({
    required Peloton3dRiderRenderData rider,
    required Peloton3dRoadNode roadNode,
  }) {
    final Vector3 basePos = roadNode.center + (roadNode.right * rider.lateralOffsetMeters);
    final bool isAero = !rider.isStanding && (rider.isSprinting || rider.speedMs > 14.5);
    final double height = rider.isCrashed
        ? 0.40
        : (rider.isStanding ? 1.66 : (isAero ? 1.24 : 1.48));

    return WetAsphaltRiderReflectionInput(
      riderId: rider.riderId,
      baseWorldPosition: basePos,
      roadTangent: roadNode.tangent,
      roadRight: roadNode.right,
      roadNormal: roadNode.normal,
      jerseyColor: rider.jerseyColor,
      leaderJersey: rider.leaderJersey,
      leanAngleRadians: rider.leanAngleRad,
      riderHeightMeters: height,
      lateralOffsetMeters: rider.lateralOffsetMeters,
      distanceMeters: rider.distanceMeters,
      speedMs: rider.speedMs,
      isStanding: rider.isStanding,
      isAeroTuck: isAero,
      isCrashed: rider.isCrashed,
      isPlayerRider: rider.isPlayerRider,
    );
  }
}

/// Telemetria z ostatniej klatki renderowania efektu mokrego asfaltu.
class WetAsphaltTelemetry {
  final int darkenedRoadQuads;
  final int puddlesRendered;
  final int riderReflectionsRendered;
  final int dryRutSegmentsRendered;
  final double effectiveWetness;

  const WetAsphaltTelemetry({
    this.darkenedRoadQuads = 0,
    this.puddlesRendered = 0,
    this.riderReflectionsRendered = 0,
    this.dryRutSegmentsRendered = 0,
    this.effectiveWetness = 0.0,
  });
}

/// Śledzi i akumuluje suche koleiny wyjeżdżane przez przejeżdżający peleton.
class PelotonTireRutTracker {
  static const int _laneCount = 15;
  static const double _roadHalfWidthMeters = 3.6;

  final List<double> _laneDryness = List<double>.filled(_laneCount, 0.0);

  /// Aktualizuje stan kolein w kolejnych pasach szerokości jezdni na podstawie pozycji kolarzy.
  void update({
    required double deltaSeconds,
    required List<WetAsphaltRiderReflectionInput> riders,
    required double rainIntensity,
    required double wetness,
  }) {
    if (deltaSeconds <= 0.0 || wetness <= 0.02) {
      for (int i = 0; i < _laneCount; i++) {
        _laneDryness[i] = 0.0;
      }
      return;
    }

    // Stopniowe ponowne zamakanie kolein podczas deszczu lub bardzo powolne parowanie po deszczu.
    final double rewetRate = rainIntensity > 0.05
        ? 0.06 + 0.16 * rainIntensity.clamp(0.0, 1.0)
        : 0.015;
    for (int i = 0; i < _laneCount; i++) {
      _laneDryness[i] = (_laneDryness[i] - rewetRate * deltaSeconds).clamp(0.0, 1.0);
    }

    // Każdy aktywny kolarz osusza pas pod oponami i sąsiednie pasy w niewielkim stopniu.
    for (final rider in riders) {
      if (rider.isCrashed) continue;
      final double normalized =
          ((rider.lateralOffsetMeters + _roadHalfWidthMeters) / (_roadHalfWidthMeters * 2.0))
              .clamp(0.0, 0.999);
      final int laneIdx = (normalized * _laneCount).floor().clamp(0, _laneCount - 1);
      final double speedFactor = (rider.speedMs / 12.0).clamp(0.5, 1.6);
      final double dryBoost = 0.34 * speedFactor * deltaSeconds;

      _laneDryness[laneIdx] = (_laneDryness[laneIdx] + dryBoost).clamp(0.0, 1.0);
      if (laneIdx > 0) {
        _laneDryness[laneIdx - 1] = (_laneDryness[laneIdx - 1] + dryBoost * 0.35).clamp(0.0, 1.0);
      }
      if (laneIdx + 1 < _laneCount) {
        _laneDryness[laneIdx + 1] = (_laneDryness[laneIdx + 1] + dryBoost * 0.35).clamp(0.0, 1.0);
      }
    }
  }

  /// Zwraca listę aktywnych pasów suchych kolein dla zadanego zakresu dystansu trasy.
  List<PelotonTireRutTrack> buildActiveTracks({
    required double startDistanceMeters,
    required double endDistanceMeters,
    double roadHalfWidthMeters = _roadHalfWidthMeters,
  }) {
    if (endDistanceMeters <= startDistanceMeters) return const [];
    final double laneWidth = (roadHalfWidthMeters * 2.0) / _laneCount;
    final List<PelotonTireRutTrack> tracks = <PelotonTireRutTrack>[];

    for (int i = 0; i < _laneCount; i++) {
      final double dryness = _laneDryness[i];
      if (dryness < 0.08) continue;

      final double lat = -roadHalfWidthMeters + (i + 0.5) * laneWidth;
      tracks.add(
        PelotonTireRutTrack(
          lateralOffsetMeters: lat,
          widthMeters: laneWidth * 0.85,
          drynessFactor: dryness,
          startDistanceMeters: startDistanceMeters,
          endDistanceMeters: endDistanceMeters,
        ),
      );
    }
    return tracks;
  }

  /// Bezstanowo wylicza przybliżone koleiny z bieżącego rozkładu peletonu.
  static List<PelotonTireRutTrack> computeStatelessRuts({
    required List<WetAsphaltRiderReflectionInput> riders,
    required List<Peloton3dRoadNode> roadNodes,
    required double wetness,
  }) {
    if (wetness <= 0.02 || roadNodes.length < 2 || riders.isEmpty) {
      return const [];
    }

    final List<int> counts = List<int>.filled(_laneCount, 0);
    double minDist = double.infinity;
    double maxDist = -double.infinity;

    for (final r in riders) {
      if (r.isCrashed) continue;
      if (r.distanceMeters < minDist) minDist = r.distanceMeters;
      if (r.distanceMeters > maxDist) maxDist = r.distanceMeters;

      final double normalized =
          ((r.lateralOffsetMeters + _roadHalfWidthMeters) / (_roadHalfWidthMeters * 2.0))
              .clamp(0.0, 0.999);
      final int lane = (normalized * _laneCount).floor().clamp(0, _laneCount - 1);
      counts[lane]++;
    }

    if (!minDist.isFinite || !maxDist.isFinite) return const [];

    final double roadStart = roadNodes.first.distanceMeters;
    final double roadEnd = roadNodes.last.distanceMeters;
    final double rutStart = math.max(roadStart, minDist - 55.0);
    final double rutEnd = math.min(roadEnd, maxDist + 2.0);
    if (rutEnd <= rutStart) return const [];

    const double laneWidth = (_roadHalfWidthMeters * 2.0) / _laneCount;
    final List<PelotonTireRutTrack> result = <PelotonTireRutTrack>[];

    for (int i = 0; i < _laneCount; i++) {
      final int c = counts[i];
      if (c == 0) continue;
      final double dryness = (0.28 + c * 0.16).clamp(0.0, 0.92);
      final double lat = -_roadHalfWidthMeters + (i + 0.5) * laneWidth;
      result.add(
        PelotonTireRutTrack(
          lateralOffsetMeters: lat,
          widthMeters: laneWidth * 0.82,
          drynessFactor: dryness,
          startDistanceMeters: rutStart,
          endDistanceMeters: rutEnd,
        ),
      );
    }

    return result;
  }
}

/// Painter i silnik renderowania mokrego asfaltu 3D:
/// - przyciemniona, połyskująca tekstura mokrej jezdni,
/// - proceduralne kałuże z falami od kropel deszczu i odbiciem nieba,
/// - lustrzane odbicia sylwetek kolarzy i kolorowych koszulek w kałużach,
/// - suche koleiny zostawiane przez przejeżdżający peleton.
class WetAsphaltReflectionsPainter extends CustomPainter {
  final Scene3DMathProjection projection;
  final List<Peloton3dRoadNode> roadNodes;
  final List<WetAsphaltRiderReflectionInput> riders;
  final WetAsphaltSurfaceState surfaceState;
  final WetAsphaltReflectionsConfig config;
  final List<PelotonTireRutTrack>? customDryRuts;

  WetAsphaltTelemetry _lastTelemetry = const WetAsphaltTelemetry();
  WetAsphaltTelemetry get lastTelemetry => _lastTelemetry;

  // Zcache'owane obiekty Paint dla 120 FPS bez alokacji w pętli klatki.
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _shaderPaint = Paint()..style = PaintingStyle.fill;
  final Path _scratchPath = Path();

  WetAsphaltReflectionsPainter({
    required this.projection,
    required this.roadNodes,
    required this.riders,
    required this.surfaceState,
    this.config = const WetAsphaltReflectionsConfig(),
    this.customDryRuts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _lastTelemetry = renderWetAsphaltPass(
      canvas: canvas,
      size: size,
      projection: projection,
      roadNodes: roadNodes,
      riders: riders,
      surfaceState: surfaceState,
      customDryRuts: customDryRuts,
    );
  }

  /// Główny przebieg renderowania warstwy mokrego asfaltu, kałuż, kolein i odbić kolarzy.
  ///
  /// Może być wywoływany bezpośrednio z [Peloton3dCanvasEngine] bez tworzenia nowego [CustomPainter].
  WetAsphaltTelemetry renderWetAsphaltPass({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<Peloton3dRoadNode> roadNodes,
    required List<WetAsphaltRiderReflectionInput> riders,
    required WetAsphaltSurfaceState surfaceState,
    List<PelotonTireRutTrack>? customDryRuts,
  }) {
    final double wetness = surfaceState.wetness.clamp(0.0, 1.0);
    if (wetness <= 0.02 || roadNodes.length < 2 || size.isEmpty) {
      return const WetAsphaltTelemetry();
    }

    int darkenedQuads = 0;
    int puddlesDrawn = 0;
    int reflectionsDrawn = 0;
    int rutsDrawn = 0;

    // 1. Ciemniejsza tekstura mokrej jezdni z połyskiem nieba.
    if (config.enableDarkenedAsphalt) {
      darkenedQuads = _renderDarkenedWetRoadOverlay(
        canvas: canvas,
        size: size,
        projection: projection,
        roadNodes: roadNodes,
        surfaceState: surfaceState,
        wetness: wetness,
      );
    }

    // 2. Wyliczenie suchych kolein zostawianych przez przejeżdżający peleton.
    final List<PelotonTireRutTrack> ruts = config.enablePelotonDryRuts
        ? (customDryRuts ??
            PelotonTireRutTracker.computeStatelessRuts(
              riders: riders,
              roadNodes: roadNodes,
              wetness: wetness,
            ))
        : const <PelotonTireRutTrack>[];

    // 3. Generacja kałuż na widocznych odcinkach szosy.
    final List<WetAsphaltPuddle> puddles = config.enablePuddles
        ? generatePuddlesForRoadNodes(
            roadNodes: roadNodes,
            wetness: wetness,
            densityScale: config.puddleDensityScale,
          )
        : const <WetAsphaltPuddle>[];

    // 4. Renderowanie kałuż (z pominięciem lub tłumieniem w miejscu suchych kolein).
    if (puddles.isNotEmpty) {
      puddlesDrawn = _renderPuddles(
        canvas: canvas,
        size: size,
        projection: projection,
        roadNodes: roadNodes,
        puddles: puddles,
        dryRuts: ruts,
        surfaceState: surfaceState,
        wetness: wetness,
      );
    }

    // 5. Renderowanie suchych kolein peletonu na mokrym asfalcie.
    if (ruts.isNotEmpty) {
      rutsDrawn = _renderDryPelotonRuts(
        canvas: canvas,
        size: size,
        projection: projection,
        roadNodes: roadNodes,
        ruts: ruts,
        wetness: wetness,
      );
    }

    // 6. Lustrzane odbicia sylwetek kolarzy i kolorowych koszulek w kałużach oraz na mokrym filmie.
    if (config.enableRiderReflections && riders.isNotEmpty) {
      reflectionsDrawn = _renderRiderReflections(
        canvas: canvas,
        size: size,
        projection: projection,
        riders: riders,
        puddles: puddles,
        dryRuts: ruts,
        surfaceState: surfaceState,
        wetness: wetness,
      );
    }

    return WetAsphaltTelemetry(
      darkenedRoadQuads: darkenedQuads,
      puddlesRendered: puddlesDrawn,
      riderReflectionsRendered: reflectionsDrawn,
      dryRutSegmentsRendered: rutsDrawn,
      effectiveWetness: wetness,
    );
  }

  /// Nakłada przyciemnioną, mokrą teksturę asfaltu oraz kierunkowy połysk (specular sheen).
  int _renderDarkenedWetRoadOverlay({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<Peloton3dRoadNode> roadNodes,
    required WetAsphaltSurfaceState surfaceState,
    required double wetness,
  }) {
    int count = 0;
    final Vector3 camDiff = projection.cameraTarget - projection.cameraPosition;
    final Vector3 camForward = camDiff.length2 > 1e-6 ? camDiff.normalized() : Vector3(0.0, 0.0, 1.0);

    for (int i = roadNodes.length - 2; i >= 0; i--) {
      final Peloton3dRoadNode a = roadNodes[i];
      final Peloton3dRoadNode b = roadNodes[i + 1];

      // Szuter chłonie wodę bez efektu lustrzanego filmu asfaltowego.
      if (a.surfaceType == SegmentSurfaceType.gravelStrade) continue;

      final double halfWa = a.roadWidthMeters * 0.5;
      final double halfWb = b.roadWidthMeters * 0.5;

      final pALeft = projection.worldToScreen(a.center - a.right * halfWa + a.normal * 0.003);
      final pARight = projection.worldToScreen(a.center + a.right * halfWa + a.normal * 0.003);
      final pBLeft = projection.worldToScreen(b.center - b.right * halfWb + b.normal * 0.003);
      final pBRight = projection.worldToScreen(b.center + b.right * halfWb + b.normal * 0.003);

      if (!pALeft.isInFrontOfCamera &&
          !pARight.isInFrontOfCamera &&
          !pBLeft.isInFrontOfCamera &&
          !pBRight.isInFrontOfCamera) {
        continue;
      }
      if (!_isAnyQuadVertexInViewport(pALeft, pARight, pBRight, pBLeft, size)) continue;

      // Im płytszy kąt patrzenia na drogę, tym silniejszy efekt odbicia Fresnela na mokrym filmie.
      final double grazing = (1.0 - camForward.dot(a.normal).abs()).clamp(0.25, 1.0);
      final bool isCobble = _isCobble(a.surfaceType);

      final Color wetDarkTint = isCobble
          ? const Color(0xFF141820)
          : Color.lerp(
              const Color(0xFF0E121A),
              surfaceState.skyZenithColor,
              0.18 * grazing,
            )!;

      final double darkenAlpha = ((isCobble ? 0.28 : 0.44) * wetness).clamp(0.0, 0.56);

      _scratchPath
        ..reset()
        ..moveTo(pALeft.screenX, pALeft.screenY)
        ..lineTo(pARight.screenX, pARight.screenY)
        ..lineTo(pBRight.screenX, pBRight.screenY)
        ..lineTo(pBLeft.screenX, pBLeft.screenY)
        ..close();

      _fillPaint.color = wetDarkTint.withValues(alpha: darkenAlpha);
      canvas.drawPath(_scratchPath, _fillPaint);
      count++;

      // Drobne ziarno mokrego asfaltu i błyski wody na bliskim planie.
      if (config.quality != WetAsphaltReflectionQuality.performance &&
          pALeft.depthEye < 48.0 &&
          !isCobble) {
        _drawWetAsphaltMicroGrain(
          canvas: canvas,
          projection: projection,
          a: a,
          b: b,
          halfWa: halfWa,
          halfWb: halfWb,
          segmentIndex: i,
          wetness: wetness,
          skyColor: surfaceState.skyHorizonColor,
        );
      }
    }

    return count;
  }

  void _drawWetAsphaltMicroGrain({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Peloton3dRoadNode a,
    required Peloton3dRoadNode b,
    required double halfWa,
    required double halfWb,
    required int segmentIndex,
    required double wetness,
    required Color skyColor,
  }) {
    final int hash = _hashInt(segmentIndex * 73856093);
    final double latFrac = ((hash % 100) / 100.0 - 0.5) * 1.4;
    final p1 = projection.worldToScreen(
      a.center + a.right * (halfWa * latFrac) + a.normal * 0.005,
    );
    final p2 = projection.worldToScreen(
      b.center + b.right * (halfWb * latFrac) + b.normal * 0.005,
    );
    if (!p1.isInFrontOfCamera || !p2.isInFrontOfCamera) return;

    _strokePaint
      ..color = skyColor.withValues(alpha: (0.14 * wetness).clamp(0.02, 0.22))
      ..strokeWidth = (1.6 * p1.perspectiveScale).clamp(0.6, 3.0);
    canvas.drawLine(Offset(p1.screenX, p1.screenY), Offset(p2.screenX, p2.screenY), _strokePaint);
  }

  /// Deterministycznie generuje kałuże wzdłuż widocznych węzłów trasy.
  static List<WetAsphaltPuddle> generatePuddlesForRoadNodes({
    required List<Peloton3dRoadNode> roadNodes,
    required double wetness,
    double densityScale = 1.0,
  }) {
    if (wetness < 0.12 || roadNodes.length < 2 || densityScale <= 0.0) {
      return const [];
    }

    final List<WetAsphaltPuddle> puddles = <WetAsphaltPuddle>[];
    final double minDist = roadNodes.first.distanceMeters;
    final double maxDist = roadNodes.last.distanceMeters;

    // Kałuże rozmieszczone w deterministycznej siatce co 9 m.
    const double cellStepMeters = 9.0;
    final int startCell = (minDist / cellStepMeters).floor();
    final int endCell = (maxDist / cellStepMeters).ceil();

    for (int cell = startCell; cell <= endCell; cell++) {
      final int seed = _hashInt(cell * 19349663);
      final double cellDist = cell * cellStepMeters + ((seed % 100) / 100.0) * 5.0;
      if (cellDist < minDist || cellDist > maxDist) continue;

      final Peloton3dRoadNode? node = _findNearestNode(roadNodes, cellDist);
      if (node == null || node.surfaceType == SegmentSurfaceType.gravelStrade) continue;

      // Na stromych podjazdach/zjazdach woda spływa — mniej kałuż.
      final double slopeDrain = (1.0 - (node.gradientPercent.abs() / 9.5)).clamp(0.15, 1.0);
      final double spawnThreshold = (0.38 * wetness * densityScale * slopeDrain).clamp(0.0, 0.85);
      final double roll = ((seed >> 8) % 1000) / 1000.0;
      if (roll > spawnThreshold) continue;

      final double halfW = node.roadWidthMeters * 0.5;
      // Kałuże najczęściej gromadzą się bliżej krawędzi lub w lekkich koleinach szosy.
      final double sideSign = ((seed >> 16) & 1) == 0 ? -1.0 : 1.0;
      final double latMag = 0.45 + (((seed >> 18) % 100) / 100.0) * (halfW - 1.25).clamp(0.5, 2.5);
      final double lat = (sideSign * latMag).clamp(-(halfW - 0.6), halfW - 0.6);

      final double lengthM = (1.8 + (((seed >> 22) % 100) / 100.0) * 3.4) * (0.65 + 0.35 * wetness);
      final double widthM = (0.9 + (((seed >> 26) % 100) / 100.0) * 1.45) * (0.65 + 0.35 * wetness);
      final double depthFactor = (0.45 + 0.55 * wetness).clamp(0.0, 1.0);

      puddles.add(
        WetAsphaltPuddle(
          distanceMeters: cellDist,
          lateralOffsetMeters: lat,
          lengthMeters: lengthM,
          widthMeters: widthM,
          depthFactor: depthFactor,
          seed: seed,
        ),
      );
    }

    return puddles;
  }

  int _renderPuddles({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<Peloton3dRoadNode> roadNodes,
    required List<WetAsphaltPuddle> puddles,
    required List<PelotonTireRutTrack> dryRuts,
    required WetAsphaltSurfaceState surfaceState,
    required double wetness,
  }) {
    int count = 0;

    for (final puddle in puddles) {
      final Peloton3dRoadNode? node = _findNearestNode(roadNodes, puddle.distanceMeters);
      if (node == null) continue;

      final Vector3 puddleCenter =
          node.center + node.right * puddle.lateralOffsetMeters + node.normal * 0.006;

      final double distToCam = (puddleCenter - projection.cameraPosition).length;
      if (distToCam > config.maxPuddleDistanceMeters) continue;

      // Jeśli przez kałużę przechodzi mocno wysuszona koleina, woda w tym miejscu jest rozbita.
      double rutSuppression = 1.0;
      for (final rut in dryRuts) {
        if (puddle.distanceMeters >= rut.startDistanceMeters &&
            puddle.distanceMeters <= rut.endDistanceMeters) {
          final double dLat = (puddle.lateralOffsetMeters - rut.lateralOffsetMeters).abs();
          if (dLat < (puddle.widthMeters * 0.45 + rut.widthMeters * 0.5)) {
            rutSuppression = math.min(rutSuppression, (1.0 - rut.drynessFactor * 0.65).clamp(0.25, 1.0));
          }
        }
      }

      final int segments = config.quality == WetAsphaltReflectionQuality.high ? 14 : 10;
      _scratchPath.reset();
      double minX = double.infinity;
      double maxX = -double.infinity;
      double minY = double.infinity;
      double maxY = -double.infinity;
      int validPts = 0;

      for (int s = 0; s < segments; s++) {
        final double theta = (s / segments) * math.pi * 2.0;
        final double wobble = 1.0 +
            0.16 * math.sin(theta * 2.0 + (puddle.seed % 7)) +
            0.09 * math.cos(theta * 3.0 - (puddle.seed % 5));
        final double localForward = math.cos(theta) * puddle.lengthMeters * 0.5 * wobble;
        final double localRight = math.sin(theta) * puddle.widthMeters * 0.5 * wobble;

        final Vector3 worldPt = puddleCenter +
            node.tangent * localForward +
            node.right * localRight;
        final proj = projection.worldToScreen(worldPt);
        if (!proj.isInFrontOfCamera) continue;

        if (validPts == 0) {
          _scratchPath.moveTo(proj.screenX, proj.screenY);
        } else {
          _scratchPath.lineTo(proj.screenX, proj.screenY);
        }
        validPts++;
        if (proj.screenX < minX) minX = proj.screenX;
        if (proj.screenX > maxX) maxX = proj.screenX;
        if (proj.screenY < minY) minY = proj.screenY;
        if (proj.screenY > maxY) maxY = proj.screenY;
      }

      if (validPts < 4) continue;
      _scratchPath.close();

      final Rect bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
      if (bounds.right < 0 || bounds.left > size.width || bounds.bottom < 0 || bounds.top > size.height) {
        continue;
      }

      final double distFade = (1.0 - (distToCam / config.maxPuddleDistanceMeters)).clamp(0.15, 1.0);
      final double alpha = (0.58 * puddle.depthFactor * rutSuppression * distFade).clamp(0.08, 0.72);

      // Lustrzane wypełnienie kałuży odbijające gradient nieba.
      _shaderPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(const Color(0xFF0A0E15), surfaceState.skyZenithColor, 0.52)!
              .withValues(alpha: alpha),
          Color.lerp(const Color(0xFF131A26), surfaceState.skyHorizonColor, 0.60)!
              .withValues(alpha: (alpha * 0.90).clamp(0.05, 0.68)),
        ],
      ).createShader(bounds);
      canvas.drawPath(_scratchPath, _shaderPaint);
      _shaderPaint.shader = null;

      // Cienka krawędź menisku wody (specular rim).
      _strokePaint
        ..color = surfaceState.skyHorizonColor.withValues(alpha: (0.28 * distFade * wetness).clamp(0.03, 0.32))
        ..strokeWidth = 1.0;
      canvas.drawPath(_scratchPath, _strokePaint);

      // Koncentryczne kręgi na kałuży od kropel deszczu.
      if (config.enableRainRipples &&
          config.quality == WetAsphaltReflectionQuality.high &&
          surfaceState.rainIntensity > 0.12 &&
          distToCam < 55.0) {
        _drawPuddleRainRipples(
          canvas: canvas,
          projection: projection,
          puddleCenter: puddleCenter,
          node: node,
          puddle: puddle,
          rainIntensity: surfaceState.rainIntensity,
          timeSec: surfaceState.animationTimeSeconds,
          skyColor: surfaceState.skyHorizonColor,
        );
      }

      count++;
    }

    return count;
  }

  void _drawPuddleRainRipples({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 puddleCenter,
    required Peloton3dRoadNode node,
    required WetAsphaltPuddle puddle,
    required double rainIntensity,
    required double timeSec,
    required Color skyColor,
  }) {
    final double phase = (timeSec * 1.9 + (puddle.seed % 13) * 0.17) % 1.0;
    final double rippleRadius = 0.08 + phase * math.min(puddle.widthMeters, puddle.lengthMeters) * 0.28;
    final double alpha = ((1.0 - phase) * 0.34 * rainIntensity).clamp(0.0, 0.35);
    if (alpha <= 0.02) return;

    final pCenter = projection.worldToScreen(puddleCenter);
    final pEdgeX = projection.worldToScreen(puddleCenter + node.right * rippleRadius);
    final pEdgeZ = projection.worldToScreen(puddleCenter + node.tangent * rippleRadius);
    if (!pCenter.isInFrontOfCamera || !pEdgeX.isInFrontOfCamera || !pEdgeZ.isInFrontOfCamera) {
      return;
    }

    final double rx = (pEdgeX.screenX - pCenter.screenX).abs().clamp(2.0, 28.0);
    final double ry = ((pEdgeZ.screenY - pCenter.screenY).abs() * 0.85).clamp(1.2, 14.0);

    _strokePaint
      ..color = skyColor.withValues(alpha: alpha)
      ..strokeWidth = 0.9;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pCenter.screenX, pCenter.screenY), width: rx * 2.0, height: ry * 2.0),
      _strokePaint,
    );
  }

  /// Renderuje suche koleiny zostawiane przez koła przejeżdżającego peletonu.
  int _renderDryPelotonRuts({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<Peloton3dRoadNode> roadNodes,
    required List<PelotonTireRutTrack> ruts,
    required double wetness,
  }) {
    int count = 0;

    for (final rut in ruts) {
      if (rut.drynessFactor <= 0.05) continue;
      final double halfRutW = rut.widthMeters * 0.5;

      for (int i = roadNodes.length - 2; i >= 0; i--) {
        final Peloton3dRoadNode a = roadNodes[i];
        final Peloton3dRoadNode b = roadNodes[i + 1];

        if (b.distanceMeters < rut.startDistanceMeters || a.distanceMeters > rut.endDistanceMeters) {
          continue;
        }
        if (a.surfaceType == SegmentSurfaceType.gravelStrade) continue;

        final Vector3 centerA = a.center + a.right * rut.lateralOffsetMeters + a.normal * 0.008;
        final Vector3 centerB = b.center + b.right * rut.lateralOffsetMeters + b.normal * 0.008;

        final pAL = projection.worldToScreen(centerA - a.right * halfRutW);
        final pAR = projection.worldToScreen(centerA + a.right * halfRutW);
        final pBL = projection.worldToScreen(centerB - b.right * halfRutW);
        final pBR = projection.worldToScreen(centerB + b.right * halfRutW);

        if (!pAL.isInFrontOfCamera && !pAR.isInFrontOfCamera && !pBL.isInFrontOfCamera && !pBR.isInFrontOfCamera) {
          continue;
        }
        if (!_isAnyQuadVertexInViewport(pAL, pAR, pBR, pBL, size)) continue;

        final double dryAlpha = (0.48 * rut.drynessFactor * wetness).clamp(0.04, 0.54);
        const Color dryMatteAsphalt = Color(0xFF313744);

        _scratchPath
          ..reset()
          ..moveTo(pAL.screenX, pAL.screenY)
          ..lineTo(pAR.screenX, pAR.screenY)
          ..lineTo(pBR.screenX, pBR.screenY)
          ..lineTo(pBL.screenX, pBL.screenY)
          ..close();

        _fillPaint.color = dryMatteAsphalt.withValues(alpha: dryAlpha);
        canvas.drawPath(_scratchPath, _fillPaint);
        count++;
      }
    }

    return count;
  }

  /// Renderuje lustrzane odbicia sylwetek kolarzy oraz ich kolorowych koszulek w kałużach i mokrym asfalcie.
  int _renderRiderReflections({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<WetAsphaltRiderReflectionInput> riders,
    required List<WetAsphaltPuddle> puddles,
    required List<PelotonTireRutTrack> dryRuts,
    required WetAsphaltSurfaceState surfaceState,
    required double wetness,
  }) {
    int count = 0;

    for (final rider in riders) {
      final double distToCam = (rider.baseWorldPosition - projection.cameraPosition).length;
      if (distToCam > config.maxReflectionDistanceMeters) continue;

      final double distFade =
          (1.0 - (distToCam / config.maxReflectionDistanceMeters)).clamp(0.0, 1.0);

      // Sprawdzenie, czy kolarz jedzie przez kałużę (wyraźniejsze, lustrzane odbicie)
      // czy po zwykłym mokrym filmie asfaltu (bardziej rozmyte).
      final double puddleOverlap = _computePuddleOverlapFactor(rider, puddles);
      final double dryRutPenalty = _computeDryRutPenalty(rider, dryRuts);

      final double baseClarity =
          ((0.26 + 0.56 * puddleOverlap) * wetness * (1.0 - 0.55 * dryRutPenalty) * distFade * config.reflectionIntensityScale)
              .clamp(0.0, 0.78);
      if (baseClarity < 0.03) continue;

      final Vector3 groundWorld = rider.baseWorldPosition + rider.roadNormal * 0.01;
      final double leanSide = math.sin(rider.leanAngleRadians) * 0.35;

      // Punkty odbicia lustrzanego pod płaszczyzną asfaltu (odbicie wzdłuż odwróconej normalnej -roadNormal).
      final Vector3 wheelReflectWorld =
          groundWorld - rider.roadNormal * 0.36 + rider.roadRight * (leanSide * 0.3);
      final Vector3 torsoReflectWorld =
          groundWorld - rider.roadNormal * (rider.riderHeightMeters * 0.66) + rider.roadRight * leanSide;
      final Vector3 headReflectWorld =
          groundWorld - rider.roadNormal * (rider.riderHeightMeters * 0.96) + rider.roadRight * (leanSide * 1.15);

      final pGround = projection.worldToScreen(groundWorld);
      final pWheel = projection.worldToScreen(wheelReflectWorld);
      final pTorso = projection.worldToScreen(torsoReflectWorld);
      final pHead = projection.worldToScreen(headReflectWorld);

      if (!pGround.isInFrontOfCamera || !pTorso.isInFrontOfCamera) continue;

      // Poziome falowanie odbicia od wiatru/kropel deszczu w kałuży.
      final double waveJitter = puddleOverlap > 0.1
          ? math.sin(surfaceState.animationTimeSeconds * 7.5 + rider.distanceMeters * 0.8) *
              (1.2 + 2.2 * surfaceState.rainIntensity)
          : 0.0;

      final double totalHeight = (pHead.screenY - pGround.screenY).abs().clamp(8.0, 96.0);
      final double jerseyWidth = (pGround.perspectiveScale * 0.52).clamp(3.0, 26.0);

      if (pGround.screenX + jerseyWidth < 0 ||
          pGround.screenX - jerseyWidth > size.width ||
          pGround.screenY > size.height ||
          pGround.screenY + totalHeight < 0) {
        continue;
      }

      // 1. Odbicie kół i ramy roweru (ciemna sylwetka tuż pod oponami).
      final Rect bikeRect = Rect.fromLTWH(
        pGround.screenX - jerseyWidth * 0.24,
        pGround.screenY,
        (jerseyWidth * 0.48).clamp(1.6, 12.0),
        (pWheel.screenY - pGround.screenY).abs().clamp(4.0, totalHeight * 0.45),
      );
      _shaderPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0A0D12).withValues(alpha: (baseClarity * 0.72).clamp(0.0, 0.55)),
          const Color(0xFF0A0D12).withValues(alpha: 0.0),
        ],
      ).createShader(bikeRect);
      canvas.drawOval(bikeRect, _shaderPaint);
      _shaderPaint.shader = null;

      // 2. Odbicie kolorowej koszulki kolarza (lub koszulki lidera klasyfikacji).
      final Color resolvedJersey = _resolveReflectionJerseyColor(
        baseJersey: rider.jerseyColor,
        leaderJersey: rider.leaderJersey,
      );
      final Color waterTintedJersey = Color.lerp(
        resolvedJersey,
        surfaceState.skyHorizonColor,
        puddleOverlap > 0.25 ? 0.22 : 0.42,
      )!;

      final double torsoTopY = pGround.screenY + totalHeight * 0.28;
      final double torsoHeight = (totalHeight * 0.52).clamp(5.0, 56.0);
      final Rect jerseyRect = Rect.fromLTWH(
        pTorso.screenX - jerseyWidth * 0.5 + waveJitter,
        torsoTopY,
        jerseyWidth,
        torsoHeight,
      );

      _shaderPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waterTintedJersey.withValues(alpha: (baseClarity * 0.82).clamp(0.0, 0.62)),
          waterTintedJersey.withValues(alpha: (baseClarity * 0.42).clamp(0.0, 0.34)),
          waterTintedJersey.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(jerseyRect);
      canvas.drawOval(jerseyRect, _shaderPaint);
      _shaderPaint.shader = null;

      // Akcent tęczowy / grochy KOM w odbiciu dla koszulek specjalnych w trybie wysokiej jakości.
      if (config.quality == WetAsphaltReflectionQuality.high &&
          puddleOverlap > 0.2 &&
          rider.leaderJersey != LeaderJerseyType.none) {
        _drawSpecialJerseyReflectionAccent(
          canvas: canvas,
          jerseyRect: jerseyRect,
          leaderJersey: rider.leaderJersey,
          clarity: baseClarity,
        );
      }

      // 3. Odbicie kasku na samym dole odwróconej sylwetki.
      if (config.quality != WetAsphaltReflectionQuality.performance) {
        final double helmetRadius = (jerseyWidth * 0.26).clamp(1.2, 6.5);
        _fillPaint.color = const Color(0xFF1A202C).withValues(alpha: (baseClarity * 0.38).clamp(0.0, 0.30));
        canvas.drawCircle(
          Offset(pHead.screenX + waveJitter * 1.2, pGround.screenY + totalHeight * 0.86),
          helmetRadius,
          _fillPaint,
        );
      }

      count++;
    }

    return count;
  }

  void _drawSpecialJerseyReflectionAccent({
    required Canvas canvas,
    required Rect jerseyRect,
    required LeaderJerseyType leaderJersey,
    required double clarity,
  }) {
    final double alpha = (clarity * 0.48).clamp(0.02, 0.38);
    if (leaderJersey == LeaderJerseyType.polkaDot) {
      _fillPaint.color = const Color(0xFFEF4444).withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(jerseyRect.center.dx - jerseyRect.width * 0.18, jerseyRect.center.dy),
        (jerseyRect.width * 0.14).clamp(1.0, 3.5),
        _fillPaint,
      );
      canvas.drawCircle(
        Offset(jerseyRect.center.dx + jerseyRect.width * 0.16, jerseyRect.center.dy + jerseyRect.height * 0.15),
        (jerseyRect.width * 0.12).clamp(1.0, 3.0),
        _fillPaint,
      );
    } else if (leaderJersey == LeaderJerseyType.rainbow) {
      const List<Color> uciBands = [
        Color(0xFF38BDF8),
        Color(0xFFEF4444),
        Color(0xFF111827),
        Color(0xFFFACC15),
        Color(0xFF10B981),
      ];
      final double bandW = jerseyRect.width / uciBands.length;
      for (int i = 0; i < uciBands.length; i++) {
        _fillPaint.color = uciBands[i].withValues(alpha: alpha);
        canvas.drawRect(
          Rect.fromLTWH(
            jerseyRect.left + i * bandW,
            jerseyRect.center.dy - 1.5,
            bandW,
            3.0,
          ),
          _fillPaint,
        );
      }
    }
  }

  static Color _resolveReflectionJerseyColor({
    required Color baseJersey,
    required LeaderJerseyType leaderJersey,
  }) {
    switch (leaderJersey) {
      case LeaderJerseyType.yellow:
        return AppColors.goldAccent;
      case LeaderJerseyType.green:
        return AppColors.statusSuccess;
      case LeaderJerseyType.polkaDot:
      case LeaderJerseyType.white:
      case LeaderJerseyType.rainbow:
        return const Color(0xFFF3F4F6);
      case LeaderJerseyType.none:
        return baseJersey;
    }
  }

  static double _computePuddleOverlapFactor(
    WetAsphaltRiderReflectionInput rider,
    List<WetAsphaltPuddle> puddles,
  ) {
    double best = 0.0;
    for (final puddle in puddles) {
      final double dDist = (rider.distanceMeters - puddle.distanceMeters).abs();
      final double dLat = (rider.lateralOffsetMeters - puddle.lateralOffsetMeters).abs();
      final double rx = puddle.lengthMeters * 0.65;
      final double rz = puddle.widthMeters * 0.65;
      if (dDist > rx || dLat > rz) continue;

      final double normDist = math.sqrt((dDist / rx) * (dDist / rx) + (dLat / rz) * (dLat / rz));
      final double overlap = (1.0 - normDist).clamp(0.0, 1.0);
      if (overlap > best) best = overlap;
    }
    return best;
  }

  static double _computeDryRutPenalty(
    WetAsphaltRiderReflectionInput rider,
    List<PelotonTireRutTrack> ruts,
  ) {
    double maxPenalty = 0.0;
    for (final rut in ruts) {
      if (rider.distanceMeters < rut.startDistanceMeters ||
          rider.distanceMeters > rut.endDistanceMeters) {
        continue;
      }
      final double dLat = (rider.lateralOffsetMeters - rut.lateralOffsetMeters).abs();
      if (dLat <= rut.widthMeters * 0.65) {
        if (rut.drynessFactor > maxPenalty) {
          maxPenalty = rut.drynessFactor;
        }
      }
    }
    return maxPenalty;
  }

  static Peloton3dRoadNode? _findNearestNode(List<Peloton3dRoadNode> nodes, double distanceMeters) {
    if (nodes.isEmpty) return null;
    int low = 0;
    int high = nodes.length - 1;
    while (low < high) {
      final int mid = (low + high) >> 1;
      if (nodes[mid].distanceMeters < distanceMeters) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (low > 0 &&
        (nodes[low - 1].distanceMeters - distanceMeters).abs() <
            (nodes[low].distanceMeters - distanceMeters).abs()) {
      return nodes[low - 1];
    }
    return nodes[low];
  }

  static bool _isCobble(SegmentSurfaceType type) {
    return type == SegmentSurfaceType.cobblestonesSector1 ||
        type == SegmentSurfaceType.cobblestonesSector2 ||
        type == SegmentSurfaceType.cobblestonesSector3 ||
        type == SegmentSurfaceType.cobblestonesSector4 ||
        type == SegmentSurfaceType.cobblestonesSector5;
  }

  static bool _isAnyQuadVertexInViewport(
    ProjectedPoint3D p1,
    ProjectedPoint3D p2,
    ProjectedPoint3D p3,
    ProjectedPoint3D p4,
    Size size,
  ) {
    final double minX = math.min(math.min(p1.screenX, p2.screenX), math.min(p3.screenX, p4.screenX));
    final double maxX = math.max(math.max(p1.screenX, p2.screenX), math.max(p3.screenX, p4.screenX));
    final double minY = math.min(math.min(p1.screenY, p2.screenY), math.min(p3.screenY, p4.screenY));
    final double maxY = math.max(math.max(p1.screenY, p2.screenY), math.max(p3.screenY, p4.screenY));
    return maxX >= -20.0 && minX <= size.width + 20.0 && maxY >= -20.0 && minY <= size.height + 20.0;
  }

  static int _hashInt(int x) {
    int h = x;
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    h = (h >> 16) ^ h;
    return h & 0x7fffffff;
  }

  @override
  bool shouldRepaint(covariant WetAsphaltReflectionsPainter oldDelegate) {
    return oldDelegate.surfaceState.wetness != surfaceState.wetness ||
        oldDelegate.surfaceState.rainIntensity != surfaceState.rainIntensity ||
        oldDelegate.surfaceState.animationTimeSeconds != surfaceState.animationTimeSeconds ||
        oldDelegate.riders.length != riders.length ||
        oldDelegate.roadNodes.length != roadNodes.length ||
        oldDelegate.config.quality != config.quality ||
        oldDelegate.config.enablePuddles != config.enablePuddles ||
        oldDelegate.config.enableRiderReflections != config.enableRiderReflections ||
        oldDelegate.config.enablePelotonDryRuts != config.enablePelotonDryRuts;
  }
}

/// Responsywny panel sterowania i telemetrii efektu mokrego asfaltu [WetAsphaltReflectionsPainter]
/// przystosowany do rozdzielczości `390x844`, `1024x768` oraz `1600x900`.
class WetAsphaltReflectionsControlPanel extends StatefulWidget {
  final WetAsphaltSurfaceState surfaceState;
  final WetAsphaltReflectionsConfig config;
  final WetAsphaltTelemetry telemetry;
  final ValueChanged<WetAsphaltReflectionsConfig> onConfigChanged;
  final ValueChanged<double>? onWetnessChanged;
  final bool enabled;

  const WetAsphaltReflectionsControlPanel({
    super.key,
    required this.surfaceState,
    required this.config,
    required this.telemetry,
    required this.onConfigChanged,
    this.onWetnessChanged,
    this.enabled = true,
  });

  @override
  State<WetAsphaltReflectionsControlPanel> createState() =>
      _WetAsphaltReflectionsControlPanelState();
}

class _WetAsphaltReflectionsControlPanelState
    extends State<WetAsphaltReflectionsControlPanel> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 460.0;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.45,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                _buildQualitySelector(isCompact),
                const SizedBox(height: 12),
                _buildToggleChips(isCompact),
                if (widget.onWetnessChanged != null) ...[
                  const SizedBox(height: 10),
                  _buildWetnessSlider(),
                ],
                const SizedBox(height: 10),
                _buildTelemetryRow(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      children: [
        const Icon(Icons.water_drop_outlined, color: AppColors.goldAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mokry Asfalt i Odbicia 3D',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: Text(
            '${(widget.surfaceState.wetness * 100).round()}%',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySelector(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WetAsphaltReflectionQuality.values.map((q) {
        final bool isSelected = widget.config.quality == q;
        final String label = switch (q) {
          WetAsphaltReflectionQuality.high => 'Ultra (Odbicia + Fale)',
          WetAsphaltReflectionQuality.balanced => 'Zbalansowany',
          WetAsphaltReflectionQuality.performance => '120 FPS',
        };
        return _WetAsphaltActionPill(
          label: label,
          selected: isSelected,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(widget.config.copyWith(quality: q)),
        );
      }).toList(),
    );
  }

  Widget _buildToggleChips(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _WetAsphaltActionPill(
          label: 'Kałuże',
          selected: widget.config.enablePuddles,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(enablePuddles: !widget.config.enablePuddles),
          ),
        ),
        _WetAsphaltActionPill(
          label: 'Odbicia Koszulek',
          selected: widget.config.enableRiderReflections,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(enableRiderReflections: !widget.config.enableRiderReflections),
          ),
        ),
        _WetAsphaltActionPill(
          label: 'Suche Koleiny',
          selected: widget.config.enablePelotonDryRuts,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(enablePelotonDryRuts: !widget.config.enablePelotonDryRuts),
          ),
        ),
      ],
    );
  }

  Widget _buildWetnessSlider() {
    return Row(
      children: [
        const Text(
          'Wilgoć:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
            ),
            child: Slider(
              value: widget.surfaceState.wetness.clamp(0.0, 1.0),
              onChanged: widget.enabled ? widget.onWetnessChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryRow(bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _TelemetryChip(label: 'Kałuże', value: '${widget.telemetry.puddlesRendered}'),
        _TelemetryChip(label: 'Odbicia', value: '${widget.telemetry.riderReflectionsRendered}'),
        _TelemetryChip(label: 'Koleiny', value: '${widget.telemetry.dryRutSegmentsRendered}'),
      ],
    );
  }
}

class _WetAsphaltActionPill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _WetAsphaltActionPill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_WetAsphaltActionPill> createState() => _WetAsphaltActionPillState();
}

class _WetAsphaltActionPillState extends State<_WetAsphaltActionPill> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = !widget.enabled
        ? AppColors.surface
        : widget.selected
            ? (_pressed ? AppColors.primaryAccent : AppColors.primaryAccent.withValues(alpha: 0.85))
            : (_hovered ? AppColors.surfaceLight : AppColors.background);

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected ? AppColors.goldAccent : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFeatures: [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
