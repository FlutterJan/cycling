// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/utils/performance_profiler_overlay.dart';
import '../../models/race/stage_segment.dart';
import '../../services/career/cyclist_olympic_and_world_champion_custom_gear.dart';
import '../../state/race_simulation_notifier.dart';
import 'camera_rig_controller.dart';
import 'cyclist_3d_pose_animator.dart';
import 'scene_3d_math_projection.dart';

/// Poziomy szczegółowości (Level of Detail - LOD) dla kolarzy w peletonie.
enum PelotonLodLevel {
  /// Kolarze blisko kamery (<30m): pełny detal (animacja nóg 2-bone IK, szprychy, tarcze hamulcowe, bidony, okulary).
  fullDetail(
    maxDistanceMeters: 30.0,
    label: 'Pełny Detal (LOD 0)',
    description: 'Kinematyka nóg IK, szprychy, tarcze hamulcowe 160mm, bidon, aero-okulary, kołysanie roweru.',
  ),

  /// Środek peletonu (30-100m): średni detal (sylwetka, barwy koszulki, kask, koła bez IK).
  mediumDetail(
    maxDistanceMeters: 100.0,
    label: 'Średni Detal (LOD 1)',
    description: 'Zoptymalizowana sylwetka, barwy zespołu, kask, obręcze kół, uproszczona faza pedałowania.',
  ),

  /// Daleki plan (>100m): uproszczona sylwetka 3D z cieniem na asfalcie.
  distantSilhouette(
    maxDistanceMeters: double.infinity,
    label: 'Daleki Plan / Sylwetka (LOD 2)',
    description: 'Błyskawiczne billboardy kapsułowe 3D z barwą koszulki i owalnym cieniem na asfalcie.',
  );

  final double maxDistanceMeters;
  final String label;
  final String description;

  const PelotonLodLevel({
    required this.maxDistanceMeters,
    required this.label,
    required this.description,
  });
}

/// Konfiguracja parametrów i progów wydajnościowych renderera peletonu.
class PelotonRendererConfig {
  /// Maksymalny zasięg dla LOD 0 (pełny detal) w metrach.
  final double lod0MaxDistanceMeters;

  /// Maksymalny zasięg dla LOD 1 (średni detal) w metrach.
  final double lod1MaxDistanceMeters;

  /// Maksymalny zasięg renderowania kolarzy (powyżej kolarze są w pełni ucinani) [m].
  final double maxRenderDistanceMeters;

  /// Czy włączone jest obcinanie bryłą widzenia kamery (Frustum Culling).
  final bool enableFrustumCulling;

  /// Czy włączone jest sortowanie głębokości (Painter's Algorithm Back-to-Front).
  final bool enableDepthSorting;

  /// Czy renderować cienie kontaktowe kolarzy na asfalcie.
  final bool enableContactShadows;

  /// Czy renderować strugi aerodynamiczne (Drafting Streamlines) dla kolarzy w tunelu aero.
  final bool enableAeroStreams;

  /// Czy wyświetlać etykiety z watami i nazwiskiem nad głowami kolarzy.
  final bool enableOverheadTags;

  /// Maksymalna odległość kamery, do której wyświetlane są etykiety tekstowe [m].
  final double maxTagDistanceMeters;

  const PelotonRendererConfig({
    this.lod0MaxDistanceMeters = 30.0,
    this.lod1MaxDistanceMeters = 100.0,
    this.maxRenderDistanceMeters = 380.0,
    this.enableFrustumCulling = true,
    this.enableDepthSorting = true,
    this.enableContactShadows = true,
    this.enableAeroStreams = true,
    this.enableOverheadTags = true,
    this.maxTagDistanceMeters = 65.0,
  });
}

/// Pojedynczy element kolejki renderowania wyliczony w danej klatce animacji.
class PelotonRenderItem {
  final RiderPositionSnapshot snapshot;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 right;
  final Vector3 up;
  final double cameraDistance;
  final PelotonLodLevel lodLevel;
  final ProjectedPoint3D projectedCenter;
  final double screenScale;
  final bool isVisibleInFrustum;
  final AnimatedCyclistPose3D? animatedPose;
  final Color jerseyColor;
  final ChampionGear3dVisualSpec? championGearSpec;

  const PelotonRenderItem({
    required this.snapshot,
    required this.worldPosition,
    required this.tangent,
    required this.right,
    required this.up,
    required this.cameraDistance,
    required this.lodLevel,
    required this.projectedCenter,
    required this.screenScale,
    required this.isVisibleInFrustum,
    this.animatedPose,
    required this.jerseyColor,
    this.championGearSpec,
  });
}

/// Statystyki wydajnościowe pojedynczej klatki renderowania peletonu.
class PelotonRenderStats {
  /// Łączna liczba kolarzy przekazana do renderera (np. 176 kolarzy peletonu).
  final int totalRiders;

  /// Liczba kolarzy faktycznie wyrenderowanych na ekranie.
  final int renderedCount;

  /// Liczba kolarzy uciętych przez Frustum Culling lub maksymalny dystans.
  final int culledCount;

  /// Liczba kolarzy w trybie pełnego detalu LOD 0 (<30m).
  final int lod0Count;

  /// Liczba kolarzy w trybie średniego detalu LOD 1 (30-100m).
  final int lod1Count;

  /// Liczba kolarzy w trybie dalekiego planu LOD 2 (>100m).
  final int lod2Count;

  /// Czas sortowania i transformacji geometrii [µs].
  final int prepareTimeMicroseconds;

  /// Czas rysowania na Canvas [µs].
  final int drawTimeMicroseconds;

  const PelotonRenderStats({
    required this.totalRiders,
    required this.renderedCount,
    required this.culledCount,
    required this.lod0Count,
    required this.lod1Count,
    required this.lod2Count,
    required this.prepareTimeMicroseconds,
    required this.drawTimeMicroseconds,
  });

  /// Szacowany czas klatki w milisekundach.
  double get totalFrameTimeMs => (prepareTimeMicroseconds + drawTimeMicroseconds) / 1000.0;
}

/// Zaawansowany silnik instancjonowanego renderowania peletonu (do 176 kolarzy w 120 FPS).
///
/// Zapewnia:
/// - Sortowanie od najdalszych do najbliższych kolarzy (Painter's Algorithm),
/// - 3-poziomowy system LOD z dedykowanymi profilami geometrii,
/// - Obcinanie bryłą widzenia (Frustum Culling),
/// - Pule prealokowanych obiektów [Paint] i [Path] bez alokacji w pętli 120 FPS.
class PelotonInstancedRenderer {
  final PelotonRendererConfig config;

  /// Animator kinematyki kolarzy (dla LOD 0 i LOD 1).
  final Cyclist3DPoseAnimator _poseAnimator = Cyclist3DPoseAnimator();

  // Pula pamięci podręcznej stylów Paint (zapobiega alokacjom GC w pętli 120 FPS)
  final Map<String, Paint> _jerseyPaintCache = {};
  final Map<String, Color> _colorParseCache = {};

  // Statyczne pędzle bazowe
  late final Paint _shadowPaint;
  late final Paint _tirePaint;
  late final Paint _aluBrakePaint;
  late final Paint _rotorMetalPaint;
  late final Paint _skinPaint;
  late final Paint _shortsPaint;
  late final Paint _bidonPaint;
  late final Paint _glassesPaint;
  late final Paint _aeroStreamPaint;

  // Ostatnie zarejestrowane statystyki klatki
  PelotonRenderStats _lastStats = const PelotonRenderStats(
    totalRiders: 0,
    renderedCount: 0,
    culledCount: 0,
    lod0Count: 0,
    lod1Count: 0,
    lod2Count: 0,
    prepareTimeMicroseconds: 0,
    drawTimeMicroseconds: 0,
  );

  PelotonRenderStats get lastStats => _lastStats;

  PelotonInstancedRenderer({
    this.config = const PelotonRendererConfig(),
  }) {
    _initStaticPaints();
  }

  void _initStaticPaints() {
    _shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.fill;

    _tirePaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _aluBrakePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke;

    _rotorMetalPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke;

    _skinPaint = Paint()
      ..color = const Color(0xFFDEB887)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _shortsPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    _bidonPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    _glassesPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    _aeroStreamPaint = Paint()
      ..color = const Color(0x7700E5FF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  // ===========================================================================
  // 1. ETAP PRZYGOTOWANIA: TRANSFORMACJA, CULLING, LOD I SORTOWANIE Z-BUFFER
  // ===========================================================================

  /// Przetwarza listę kolarzy, obcina niewidoczne obiekty, wyznacza LOD i sortuje
  /// kolarzy w porządku Back-to-Front (najdalsi najpierw) dla algorytmu malarskiego.
  List<PelotonRenderItem> prepareDrawList({
    required List<RiderPositionSnapshot> riders,
    required Scene3DMathProjection projection,
    required CameraRigController cameraController,
    List<StageSegment> segments = const [],
    double dtSeconds = 0.00833, // Domyślnie 1/120s
    Map<String, ChampionGear3dVisualSpec>? championGearSpecs,
  }) {
    final stopwatch = Stopwatch()..start();

    final items = <PelotonRenderItem>[];
    int lod0 = 0;
    int lod1 = 0;
    int lod2 = 0;
    int culled = 0;

    final eyePos = projection.cameraPosition;

    for (final rider in riders) {
      // 1. Wyznaczenie pozycji w przestrzeni trójwymiarowej 3D
      final coursePos = _calculateRiderWorldPosition(rider, segments, projection);
      final worldPos = coursePos.position;

      // 2. Odległość od oka kamery
      final distToCamera = (worldPos - eyePos).length;

      // Sprawdzenie maksymalnego zasięgu renderowania
      if (distToCamera > config.maxRenderDistanceMeters) {
        culled++;
        continue;
      }

      // 3. Obcinanie bryłą widzenia kamery (Frustum Culling)
      // Promień sfery otaczającej kolarza z rowerem wynosi ~1.35m
      if (config.enableFrustumCulling && !projection.isSphereInFrustum(worldPos, 1.35)) {
        culled++;
        continue;
      }

      // 4. Rzutowanie na płaszczyznę ekranu
      final proj = projection.worldToScreen(worldPos);
      if (!proj.isInFrontOfCamera) {
        culled++;
        continue;
      }

      // Sprawdzenie marginesu ekranu (kolarz częściowo widoczny przy krawędziach kadru)
      const double screenMargin = 160.0;
      final bool isNearScreen = proj.screenX >= -screenMargin &&
          proj.screenX <= projection.viewportWidth + screenMargin &&
          proj.screenY >= -screenMargin &&
          proj.screenY <= projection.viewportHeight + screenMargin;

      if (!isNearScreen) {
        culled++;
        continue;
      }

      // 5. Klasyfikacja Level of Detail (LOD)
      final PelotonLodLevel lod;
      if (distToCamera <= config.lod0MaxDistanceMeters) {
        lod = PelotonLodLevel.fullDetail;
        lod0++;
      } else if (distToCamera <= config.lod1MaxDistanceMeters) {
        lod = PelotonLodLevel.mediumDetail;
        lod1++;
      } else {
        lod = PelotonLodLevel.distantSilhouette;
        lod2++;
      }

      // 6. Animacja pozy kolarza (tylko dla LOD 0 oraz LOD 1)
      AnimatedCyclistPose3D? pose;
      if (lod == PelotonLodLevel.fullDetail || lod == PelotonLodLevel.mediumDetail) {
        pose = _poseAnimator.update(
          dtSeconds,
          CyclistTelemetryInput(
            riderId: rider.riderId,
            speedMs: rider.speedMs,
            powerWatts: rider.powerWatts,
            cadenceRpm: rider.cadenceRpm,
            gradientPercent: rider.currentGradientPercent,
            turningRadiusMeters: double.infinity,
            isStanding: rider.currentGradientPercent > 7.5 && rider.speedKmh < 24.0,
            isSprinting: rider.powerWatts > 750,
          ),
        );
      }

      final jerseyColor = _resolveJerseyColor(rider.teamJerseyHexColor);

      items.add(PelotonRenderItem(
        snapshot: rider,
        worldPosition: worldPos,
        tangent: coursePos.tangent,
        right: coursePos.lateralRight,
        up: coursePos.surfaceNormal,
        cameraDistance: distToCamera,
        lodLevel: lod,
        projectedCenter: proj,
        screenScale: proj.perspectiveScale,
        isVisibleInFrustum: true,
        animatedPose: pose,
        jerseyColor: jerseyColor,
        championGearSpec: championGearSpecs?[rider.riderId],
      ));
    }

    // 7. Sortowanie głębokości (Depth Sorting - Painter's Algorithm Back-to-Front)
    // Najdalsi kolarze (o największym cameraDistance) są na początku listy i rysowani jako pierwsi.
    if (config.enableDepthSorting) {
      items.sort((a, b) => b.cameraDistance.compareTo(a.cameraDistance));
    }

    stopwatch.stop();

    _lastStats = PelotonRenderStats(
      totalRiders: riders.length,
      renderedCount: items.length,
      culledCount: culled,
      lod0Count: lod0,
      lod1Count: lod1,
      lod2Count: lod2,
      prepareTimeMicroseconds: stopwatch.elapsedMicroseconds,
      drawTimeMicroseconds: 0,
    );

    PerformanceTelemetryRegistry.instance.updateLodStats(
      lod0: lod0,
      lod1: lod1,
      lod2: lod2,
      culled: culled,
    );

    return items;
  }

  // ===========================================================================
  // 2. GŁÓWNA PĘTLA RENDEROWANIA NA CANVAS 2D/3D
  // ===========================================================================

  /// Renderuje wszystkich przygotowanych i posortowanych kolarzy na obiekcie [Canvas].
  void renderPeloton({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required List<PelotonRenderItem> renderItems,
  }) {
    final stopwatch = Stopwatch()..start();

    // Faza 1: Cienie kontaktowe kolarzy na nawierzchni szosy (rysujemy pod kolarzami)
    if (config.enableContactShadows) {
      for (final item in renderItems) {
        _drawContactShadow(canvas, item);
      }
    }

    // Faza 2: Ciała kolarzy i rowery według ich poziomów LOD (posortowane Back-to-Front)
    for (final item in renderItems) {
      switch (item.lodLevel) {
        case PelotonLodLevel.fullDetail:
          _drawLod0FullDetail(canvas, item, projection);
          break;

        case PelotonLodLevel.mediumDetail:
          _drawLod1MediumDetail(canvas, item, projection);
          break;

        case PelotonLodLevel.distantSilhouette:
          _drawLod2DistantSilhouette(canvas, item, projection);
          break;
      }

      // Faza 3: Strugi aerodynamiczne dla kolarzy w tunelu draftingu
      if (config.enableAeroStreams && item.snapshot.isDrafting && item.cameraDistance < 75.0) {
        _drawAeroDraftingStream(canvas, item);
      }
    }

    // Faza 4: Etykiety telemetryczne z watami i nazwiskiem kolarza (LOD 0 oraz kolarz gracza)
    if (config.enableOverheadTags) {
      for (final item in renderItems) {
        if ((item.cameraDistance <= config.maxTagDistanceMeters && item.lodLevel == PelotonLodLevel.fullDetail) ||
            item.snapshot.isPlayerRider) {
          _drawOverheadTag(canvas, item);
        }
      }
    }

    stopwatch.stop();

    // Aktualizacja statystyk z czasem rysowania
    _lastStats = PelotonRenderStats(
      totalRiders: _lastStats.totalRiders,
      renderedCount: _lastStats.renderedCount,
      culledCount: _lastStats.culledCount,
      lod0Count: _lastStats.lod0Count,
      lod1Count: _lastStats.lod1Count,
      lod2Count: _lastStats.lod2Count,
      prepareTimeMicroseconds: _lastStats.prepareTimeMicroseconds,
      drawTimeMicroseconds: stopwatch.elapsedMicroseconds,
    );
  }

  // ===========================================================================
  // 3. LOD 0: PEŁNY DETAL (<30M) - ANATOMIA, SZPRYCHY, TARCZE, BIDON, OKULARY
  // ===========================================================================

  void _drawLod0FullDetail(
    Canvas canvas,
    PelotonRenderItem item,
    Scene3DMathProjection projection,
  ) {
    final pos = Offset(item.projectedCenter.screenX, item.projectedCenter.screenY);
    final scale = (item.screenScale * 14.5).clamp(1.2, 7.5);
    final pose = item.animatedPose;

    final jerseyPaint = _getJerseyPaint(item.snapshot.teamJerseyHexColor);

    // Kąt kołysania roweru i przechyłu w zakręcie
    final double totalRollRad = ((pose?.bikeLeanAngleDegrees ?? 0.0) + (pose?.bikeSwayAngleDegrees ?? 0.0)) * math.pi / 180.0;

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(totalRollRad);

    final double wheelR = 14.0 * scale;
    final double wheelBase = 34.0 * scale;

    // 1. Koła z oponami, szprychami i tarczami hamulcowymi
    _tirePaint.strokeWidth = 3.6 * scale;
    final rearHub = Offset(-wheelBase * 0.46, -wheelR);
    final frontHub = Offset(wheelBase * 0.46, -wheelR);

    // Obręcze i opony
    canvas.drawCircle(rearHub, wheelR, _tirePaint);
    canvas.drawCircle(frontHub, wheelR, _tirePaint);

    // Tarcze hamulcowe Shimano Dura-Ace 160mm (srebrzyste dyski przy piastach)
    final double rotorR = 4.2 * scale;
    _rotorMetalPaint.strokeWidth = 1.4 * scale;
    canvas.drawCircle(rearHub, rotorR, _rotorMetalPaint);
    canvas.drawCircle(frontHub, rotorR, _rotorMetalPaint);

    // Szprychy (promieniste linie kół)
    _aluBrakePaint.strokeWidth = 0.8 * scale;
    for (int s = 0; s < 6; s++) {
      final double spokeAngle = s * math.pi / 3.0;
      final dx = math.cos(spokeAngle) * wheelR;
      final dy = math.sin(spokeAngle) * wheelR;
      canvas.drawLine(rearHub, rearHub + Offset(dx, dy), _aluBrakePaint);
      canvas.drawLine(frontHub, frontHub + Offset(dx, dy), _aluBrakePaint);
    }

    // 2. Rama roweru (trójkąt karbonowy z rurami)
    final bb = Offset(0.0, -wheelR + (2.0 * scale));
    final saddleCluster = Offset(-wheelBase * 0.16, -wheelR - (23.0 * scale));
    final headCluster = Offset(wheelBase * 0.28, -wheelR - (21.0 * scale));
    final gear = item.championGearSpec;

    final Color frameColor = gear != null && gear.hasCustomGear
        ? _resolveJerseyColor(gear.framePrimaryHex)
        : const Color(0xFF1E293B);
    final framePaint = Paint()
      ..color = frameColor
      ..strokeWidth = 3.2 * scale
      ..style = PaintingStyle.stroke;

    canvas.drawLine(rearHub, bb, framePaint);
    canvas.drawLine(rearHub, saddleCluster, framePaint);
    canvas.drawLine(bb, saddleCluster, framePaint);
    canvas.drawLine(bb, headCluster, framePaint);
    canvas.drawLine(saddleCluster, headCluster, framePaint);
    canvas.drawLine(headCluster, frontHub, framePaint);

    // Tęczowe pasy UCI na rurze podsiodłowej dla Mistrza Świata
    if (gear != null && gear.hasSeatTubeRainbowBands) {
      const bands = ChampionGear3dVisualSpec.uciRainbowBandHexes;
      for (int i = 0; i < bands.length; i++) {
        final t0 = 0.35 + i * 0.06;
        final t1 = t0 + 0.05;
        final p0 = Offset.lerp(bb, saddleCluster, t0)!;
        final p1 = Offset.lerp(bb, saddleCluster, t1)!;
        canvas.drawLine(
          p0,
          p1,
          Paint()
            ..color = _resolveJerseyColor(bands[i])
            ..strokeWidth = 3.6 * scale
            ..style = PaintingStyle.stroke,
        );
      }
    }

    // Złote detale na ramie dla Mistrza Olimpijskiego
    if (gear != null && gear.hasGoldFrameDetails) {
      final goldDetailPaint = Paint()
        ..color = _resolveJerseyColor(gear.frameAccentHex)
        ..strokeWidth = 1.6 * scale
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset.lerp(saddleCluster, headCluster, 0.2)!,
        Offset.lerp(saddleCluster, headCluster, 0.8)!,
        goldDetailPaint,
      );
      canvas.drawLine(
        Offset.lerp(headCluster, frontHub, 0.25)!,
        Offset.lerp(headCluster, frontHub, 0.75)!,
        goldDetailPaint,
      );
    }

    // 3. Bidon w koszyku na dolnej rurze (Water Bottle)
    final bidonCenter = bb + (headCluster - bb) * 0.45;
    final bidonRect = Rect.fromCenter(
      center: Offset(bidonCenter.dx, bidonCenter.dy - (1.5 * scale)),
      width: 4.5 * scale,
      height: 9.0 * scale,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(bidonRect, Radius.circular(2.0 * scale)), _bidonPaint);

    // 4. Kierownica z klamkomanetkami (Handlebar Drops) + owijka mistrzowska
    final barTop = headCluster + Offset(3.5 * scale, -5.5 * scale);
    if (gear != null && gear.hasCustomGear) {
      canvas.drawLine(
        headCluster,
        barTop,
        Paint()
          ..color = _resolveJerseyColor(gear.handlebarTapeHex)
          ..strokeWidth = 2.6 * scale
          ..strokeCap = StrokeCap.round,
      );
    } else {
      _aluBrakePaint.strokeWidth = 2.2 * scale;
      canvas.drawLine(headCluster, barTop, _aluBrakePaint);
    }

    // 5. Pedały i obrót korby
    final double crankAngle = pose?.crankAngleRadians ?? 0.0;
    final double crankR = 6.2 * scale;
    final rightPedal = bb + Offset(math.cos(crankAngle) * crankR, math.sin(crankAngle) * crankR);
    final leftPedal = bb + Offset(math.cos(crankAngle + math.pi) * crankR, math.sin(crankAngle + math.pi) * crankR);

    // 6. Nogi kolarza (2-bone analytical kinematics)
    final hip = saddleCluster + Offset(2.0 * scale, -5.0 * scale);
    _skinPaint.strokeWidth = 2.6 * scale;

    // Prawa noga (z widocznym udem i łydką)
    final kneeR = Offset(
      (hip.dx + rightPedal.dx) * 0.5 + (4.0 * scale),
      (hip.dy + rightPedal.dy) * 0.5 - (3.0 * scale),
    );
    canvas.drawLine(hip, kneeR, _skinPaint);
    canvas.drawLine(kneeR, rightPedal, _skinPaint);

    // Lewa noga
    final kneeL = Offset(
      (hip.dx + leftPedal.dx) * 0.5 - (3.0 * scale),
      (hip.dy + leftPedal.dy) * 0.5 - (3.0 * scale),
    );
    canvas.drawLine(hip, kneeL, _skinPaint);
    canvas.drawLine(kneeL, leftPedal, _skinPaint);

    // Spodenki kolarskie (Bib Shorts)
    final shortsPath = Path()
      ..moveTo(hip.dx - 2.0 * scale, hip.dy)
      ..lineTo(kneeR.dx - 1.0 * scale, kneeR.dy - 3.0 * scale)
      ..lineTo(kneeL.dx + 1.0 * scale, kneeL.dy - 3.0 * scale)
      ..close();
    canvas.drawPath(shortsPath, _shortsPaint);

    // 7. Tułów w koszulce zespołowej (Team Jersey)
    final chest = Offset(headCluster.dx - (6.0 * scale), headCluster.dy - (13.0 * scale));
    final torsoPath = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(chest.dx - (2.0 * scale), chest.dy)
      ..lineTo(chest.dx + (4.0 * scale), chest.dy + (8.0 * scale))
      ..close();
    canvas.drawPath(torsoPath, jerseyPaint);

    // Ręce oparte na klamkomanetkach
    canvas.drawLine(chest, barTop, _skinPaint);

    // 8. Głowa, kask i okulary aerodynamiczne (z uwzględnieniem sprzętu mistrzowskiego)
    if (gear != null && gear.hasCustomGear) {
      final shoePaint = Paint()
        ..color = _resolveJerseyColor(gear.shoesHex)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: rightPedal, width: 5.0 * scale, height: 2.8 * scale),
        shoePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: leftPedal, width: 5.0 * scale, height: 2.8 * scale),
        shoePaint,
      );
    }

    final head = Offset(chest.dx + (5.0 * scale), chest.dy - (9.0 * scale));
    final helmetRect = Rect.fromCenter(center: head, width: 12.0 * scale, height: 8.5 * scale);
    final Paint helmetPaint = gear != null && gear.hasCustomGear
        ? _getJerseyPaint(gear.helmetPrimaryHex)
        : jerseyPaint;
    canvas.drawOval(helmetRect, helmetPaint);
    if (gear != null && gear.hasHelmetRainbowBand) {
      const bands = ChampionGear3dVisualSpec.uciRainbowBandHexes;
      final segW = helmetRect.width / bands.length;
      for (int i = 0; i < bands.length; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            helmetRect.left + i * segW,
            helmetRect.bottom - 2.2 * scale,
            segW,
            1.8 * scale,
          ),
          _getJerseyPaint(bands[i]),
        );
      }
    }

    // Okulary kolarskie (Aero Shield Glasses)
    final glassesRect = Rect.fromCenter(
      center: Offset(head.dx + (4.0 * scale), head.dy + (1.0 * scale)),
      width: 4.5 * scale,
      height: 3.2 * scale,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(glassesRect, Radius.circular(1.0 * scale)), _glassesPaint);

    canvas.restore();
  }

  // ===========================================================================
  // 4. LOD 1: ŚREDNI DETAL (30-100M) - SYLWETKA, BARWY KOSZULKI, KASK, KOŁA
  // ===========================================================================

  void _drawLod1MediumDetail(
    Canvas canvas,
    PelotonRenderItem item,
    Scene3DMathProjection projection,
  ) {
    final pos = Offset(item.projectedCenter.screenX, item.projectedCenter.screenY);
    final scale = (item.screenScale * 14.5).clamp(0.6, 2.2);
    final jerseyPaint = _getJerseyPaint(item.snapshot.teamJerseyHexColor);

    final double wheelR = 12.0 * scale;
    final double wheelBase = 28.0 * scale;

    // Uproszczone koła bez szprych i tarcz
    _tirePaint.strokeWidth = 2.4 * scale;
    canvas.drawCircle(Offset(pos.dx - wheelBase * 0.45, pos.dy - wheelR), wheelR, _tirePaint);
    canvas.drawCircle(Offset(pos.dx + wheelBase * 0.45, pos.dy - wheelR), wheelR, _tirePaint);

    // Prosta rama i tułów
    final bb = Offset(pos.dx, pos.dy - wheelR);
    final seat = Offset(pos.dx - wheelBase * 0.15, pos.dy - wheelR - (18.0 * scale));
    final head = Offset(pos.dx + wheelBase * 0.22, pos.dy - wheelR - (16.0 * scale));

    final gear = item.championGearSpec;
    final framePaint = Paint()
      ..color = gear != null && gear.hasCustomGear
          ? _resolveJerseyColor(gear.framePrimaryHex)
          : const Color(0xFF1E293B)
      ..strokeWidth = 2.4 * scale;

    canvas.drawLine(bb, seat, framePaint);
    canvas.drawLine(bb, head, framePaint);
    canvas.drawLine(seat, head, framePaint);

    // Pedałowanie (uproszczone 2 linie nóg)
    final double crankAngle = item.animatedPose?.crankAngleRadians ?? 0.0;
    final double crankR = 5.0 * scale;
    final pedalR = bb + Offset(math.cos(crankAngle) * crankR, math.sin(crankAngle) * crankR);
    _skinPaint.strokeWidth = 2.0 * scale;
    canvas.drawLine(seat, pedalR, _skinPaint);

    // Koszulka zespołu (plama barwna)
    final chest = Offset(head.dx - (4.0 * scale), head.dy - (9.0 * scale));
    canvas.drawCircle(chest, 5.5 * scale, jerseyPaint);

    // Kask w barwach zespołu lub mistrzowski (Złoty Olimpijski / Biały z tęczą MŚ)
    final helmet = Offset(chest.dx + (3.0 * scale), chest.dy - (6.0 * scale));
    final Paint helmetPaint = gear != null && gear.hasCustomGear
        ? _getJerseyPaint(gear.helmetPrimaryHex)
        : jerseyPaint;
    canvas.drawOval(Rect.fromCenter(center: helmet, width: 8.0 * scale, height: 6.0 * scale), helmetPaint);
  }

  // ===========================================================================
  // 5. LOD 2: DALEKI PLAN (>100M) - UPROSZCZONA SYLWETKA 3D Z CIENIEM
  // ===========================================================================

  void _drawLod2DistantSilhouette(
    Canvas canvas,
    PelotonRenderItem item,
    Scene3DMathProjection projection,
  ) {
    final pos = Offset(item.projectedCenter.screenX, item.projectedCenter.screenY);
    final scale = (item.screenScale * 14.5).clamp(0.25, 0.75);
    final jerseyPaint = _getJerseyPaint(item.snapshot.teamJerseyHexColor);

    // Sylwetka kolarza jako zwarty wielokąt 3D (kapsuła aero)
    final double h = 18.0 * scale;
    final double w = 8.0 * scale;

    final capsuleRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - h * 0.5),
      width: w,
      height: h,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(capsuleRect, Radius.circular(w * 0.4)), jerseyPaint);

    // Ciemna podstawa koła / ramy
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - (2.0 * scale)), width: w * 1.2, height: 3.5 * scale),
      _tirePaint,
    );
  }

  // ===========================================================================
  // 6. EFEKTY DODATKOWE: CIENIE, STRUGI AERO, ETYKIETY
  // ===========================================================================

  void _drawContactShadow(Canvas canvas, PelotonRenderItem item) {
    final pos = Offset(item.projectedCenter.screenX, item.projectedCenter.screenY);
    final scale = (item.screenScale * 14.5).clamp(0.2, 5.0);

    // Elipsa cienia na asfalcie pod rowerem
    final shadowRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy + (1.2 * scale)),
      width: 28.0 * scale,
      height: 6.5 * scale,
    );
    canvas.drawOval(shadowRect, _shadowPaint);
  }

  void _drawAeroDraftingStream(Canvas canvas, PelotonRenderItem item) {
    final pos = Offset(item.projectedCenter.screenX, item.projectedCenter.screenY);
    final scale = (item.screenScale * 14.5).clamp(0.5, 4.0);

    final double streamLength = 38.0 * scale;
    _aeroStreamPaint.strokeWidth = 1.6 * scale;

    // Dwie aerodynamiczne strugi zawirowań powietrza za plecami kolarza
    for (int dir = -1; dir <= 1; dir += 2) {
      final streamPath = Path()
        ..moveTo(pos.dx + (6.0 * scale * dir), pos.dy - (16.0 * scale))
        ..quadraticBezierTo(
          pos.dx + (10.0 * scale * dir),
          pos.dy - (28.0 * scale),
          pos.dx + (2.0 * scale * dir),
          pos.dy - streamLength,
        );
      canvas.drawPath(streamPath, _aeroStreamPaint);
    }
  }

  void _drawOverheadTag(Canvas canvas, PelotonRenderItem item) {
    final pos = Offset(item.projectedCenter.screenX, item.projectedCenter.screenY);
    final scale = (item.screenScale * 14.5).clamp(0.5, 3.0);
    final double tagY = pos.dy - (46.0 * scale);

    final isPlayer = item.snapshot.isPlayerRider;
    final textSpan = TextSpan(
      text: '${item.snapshot.riderName} • ${item.snapshot.powerWatts}W',
      style: TextStyle(
        color: isPlayer ? const Color(0xFFFFD700) : Colors.white,
        fontSize: (9.5 * scale).clamp(7.5, 12.0),
        fontWeight: isPlayer ? FontWeight.w900 : FontWeight.w700,
        backgroundColor: const Color(0xCC000000),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(pos.dx - textPainter.width * 0.5, tagY));
  }

  // ===========================================================================
  // 7. POMOCNICZE TRANSFORMACJE TRASY I KOLORÓW
  // ===========================================================================

  Cyclist3DPose _calculateRiderWorldPosition(
    RiderPositionSnapshot rider,
    List<StageSegment> segments,
    Scene3DMathProjection projection,
  ) {
    // Odczyt promienia łuku drogi dla aktualnego segmentu
    double radius = double.infinity;
    if (segments.isNotEmpty && rider.currentSegmentIndex < segments.length) {
      // Dla standardowych odcinków prosta, łuki można definiować w segmentach
      radius = double.infinity;
    }

    return Scene3DMathProjection.courseToCyclistPose(
      coursePosition: CoursePosition(
        distanceMeters: rider.distanceCoveredMeters,
        lateralOffsetMeters: rider.lateralOffsetRoadMeters,
        elevationMeters: rider.elevationMeters,
      ),
      roadGeometry: RoadGeometryParameters(
        turningRadiusMeters: radius,
        gradientPercent: rider.currentGradientPercent,
        speedMs: rider.speedMs,
      ),
    );
  }

  Paint _getJerseyPaint(String hexColor) {
    final cached = _jerseyPaintCache[hexColor];
    if (cached != null) return cached;

    final color = _resolveJerseyColor(hexColor);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    _jerseyPaintCache[hexColor] = paint;
    return paint;
  }

  Color _resolveJerseyColor(String hexColor) {
    final cached = _colorParseCache[hexColor];
    if (cached != null) return cached;

    Color parsed;
    try {
      String clean = hexColor.replaceAll('#', '').trim();
      if (clean.length == 6) clean = 'FF$clean';
      parsed = Color(int.parse(clean, radix: 16));
    } catch (_) {
      parsed = const Color(0xFFD97706);
    }

    _colorParseCache[hexColor] = parsed;
    return parsed;
  }
}
