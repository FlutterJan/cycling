// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../services/generators/fictional_brands_catalog.dart';
import 'scene_3d_math_projection.dart';

/// Typy dmuchanych bram wyścigowych (Inflatable Arches) na trasie.
enum InflatableArchType {
  /// Brama startowa na KM 0.0 (DÉPART / START).
  start,

  /// Zielona brama lotnej premii sprinterskiej (Sprint Intermédiaire).
  intermediateSprint,

  /// Brama premii górskiej w czerwone grochy (Col / KOM).
  komMountain,

  /// Czerwona brama 1 km do mety z wiszącym czerwonym trójkątem (Flamme Rouge).
  flammeRouge,
}

/// Konfiguracja geometrii i widoczności renderera bram dmuchanych oraz barierek.
class RoadsideBannersAndArchesConfig {
  final bool enabled;
  final double forwardVisibilityMeters;
  final double backwardVisibilityMeters;
  final double archSpanMeters;
  final double archHeightMeters;
  final double archTubeRadiusMeters;
  final double barrierSegmentLengthMeters;
  final double barrierHeightMeters;
  final double barrierLateralOffsetMeters;

  const RoadsideBannersAndArchesConfig({
    this.enabled = true,
    this.forwardVisibilityMeters = 320.0,
    this.backwardVisibilityMeters = 35.0,
    this.archSpanMeters = 9.2,
    this.archHeightMeters = 6.2,
    this.archTubeRadiusMeters = 0.85,
    this.barrierSegmentLengthMeters = 3.0,
    this.barrierHeightMeters = 1.15,
    this.barrierLateralOffsetMeters = 4.15,
  });
}

/// Zparsowane dane wizualne sponsora z [FictionalBrandsCatalog] gotowe do szybkiego rysowania 3D.
class RoadsideSponsorBanner {
  final String brandId;
  final String brandName;
  final String countryIso;
  final int prestige;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;

  const RoadsideSponsorBanner({
    required this.brandId,
    required this.brandName,
    required this.countryIso,
    required this.prestige,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
  });

  factory RoadsideSponsorBanner.fromFictionalBrand(FictionalBrand brand) {
    final primary = _parseHexColor(brand.primaryColorHex);
    final luminance = primary.computeLuminance();
    final textColor =
        luminance > 0.45 ? AppColors.background : AppColors.textPrimary;
    final accentColor =
        luminance > 0.45 ? AppColors.background.withValues(alpha: 0.85) : AppColors.goldAccent;

    return RoadsideSponsorBanner(
      brandId: brand.id,
      brandName: brand.name.toUpperCase(),
      countryIso: brand.countryIso,
      prestige: brand.prestige,
      primaryColor: primary,
      accentColor: accentColor,
      textColor: textColor,
    );
  }

  static Color _parseHexColor(String hex) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length == 6) {
      final parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    } else if (cleaned.length == 8) {
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return AppColors.primaryAccent;
  }
}

/// Instancja dmuchanej bramy 3D osadzonej w układzie współrzędnych trasy.
class RoadsideArchInstance3D {
  final String id;
  final InflatableArchType type;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final String primaryLabel;
  final String? secondaryLabel;
  final RoadsideSponsorBanner sponsor;
  final SegmentClassification? classification;

  const RoadsideArchInstance3D({
    required this.id,
    required this.type,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    required this.primaryLabel,
    this.secondaryLabel,
    required this.sponsor,
    this.classification,
  });
}

/// Instancja metalowej barierki ochronnej z banerem sponsora z [FictionalBrandsCatalog].
class RoadsideBarrierInstance3D {
  final String id;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final bool isRightSide;
  final double lengthMeters;
  final RoadsideSponsorBanner sponsor;

  const RoadsideBarrierInstance3D({
    required this.id,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    required this.isRightSide,
    this.lengthMeters = 3.0,
    required this.sponsor,
  });
}

/// Zbiorczy pakiet obiektów wygenerowanych dla etapu.
class StageRoadsideBannersAndArchesPack {
  final String stageId;
  final List<RoadsideArchInstance3D> arches;
  final List<RoadsideBarrierInstance3D> barriers;

  const StageRoadsideBannersAndArchesPack({
    required this.stageId,
    required this.arches,
    required this.barriers,
  });

  bool get isEmpty => arches.isEmpty && barriers.isEmpty;
}

/// Wysokowydajny renderer 3D dla dmuchanych bram wyścigowych (`Start`, `Sprint Intermédiaire`,
/// `Col / KOM`, `Flamme Rouge 1 km`) oraz barierek ochronnych z banerami sponsorów
/// pobieranych z [FictionalBrandsCatalog].
class RoadsideBannersAndArchesRenderer {
  final RoadsideBannersAndArchesConfig config;

  // Prealokowana paleta katalogu marek i cache TextPainter dla zachowania 60/120 FPS
  late final List<RoadsideSponsorBanner> _catalogBanners;
  final Map<String, TextPainter> _textPainterCache = {};

  // Prealokowane obiekty Paint (Zero-GC podczas renderowania klatek)
  late final Paint _fillPaint;
  late final Paint _strokePaint;
  late final Paint _shadowPaint;
  late final Paint _highlightPaint;
  late final Paint _metalPaint;
  late final Paint _blowerPaint;
  late final Paint _polkaDotPaint;

  StageRoadsideBannersAndArchesPack? _cachedPack;

  RoadsideBannersAndArchesRenderer({
    this.config = const RoadsideBannersAndArchesConfig(),
  }) {
    _catalogBanners = FictionalBrandsCatalog.allBrands
        .map(RoadsideSponsorBanner.fromFictionalBrand)
        .toList(growable: false);

    _fillPaint = Paint()..style = PaintingStyle.fill;
    _strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    _highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _metalPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    _blowerPaint = Paint()
      ..color = AppColors.amberWarning
      ..style = PaintingStyle.fill;
    _polkaDotPaint = Paint()
      ..color = AppColors.crimsonAlert
      ..style = PaintingStyle.fill;
  }

  /// Lista wszystkich sponsorów przeliczone z [FictionalBrandsCatalog].
  List<RoadsideSponsorBanner> get catalogBanners =>
      List.unmodifiable(_catalogBanners);

  /// Generuje komplet dmuchanych bram i korytarzy barierek dla podanego [RaceStage].
  StageRoadsideBannersAndArchesPack spawnForStage(
    RaceStage stage, {
    Vector3 Function(double distanceMeters)? worldPositionAt,
    RoadGeometryParameters Function(double distanceMeters)? geometryAt,
  }) {
    if (_cachedPack != null && _cachedPack!.stageId == stage.id) {
      return _cachedPack!;
    }

    final totalMeters = stage.totalDistanceKm * 1000.0;
    if (totalMeters <= 0.0 || _catalogBanners.isEmpty) {
      return StageRoadsideBannersAndArchesPack(
        stageId: stage.id,
        arches: const [],
        barriers: const [],
      );
    }

    final arches = <RoadsideArchInstance3D>[];
    final barriers = <RoadsideBarrierInstance3D>[];
    int sponsorCursor = 0;

    RoadsideSponsorBanner nextSponsor() {
      final banner = _catalogBanners[sponsorCursor % _catalogBanners.length];
      sponsorCursor++;
      return banner;
    }

    (Vector3 pos, Vector3 tangent, Vector3 right, Vector3 normal) resolveFrame(
      double distM,
    ) {
      final pos = worldPositionAt != null
          ? worldPositionAt(distM)
          : Vector3(
              0.0,
              _elevationAt(distM, stage.segments),
              distM,
            );
      final geom = geometryAt != null
          ? geometryAt(distM)
          : RoadGeometryParameters(
              gradientPercent: _gradientAt(distM, stage.segments),
            );
      final bearing = geom.roadBearingRadians;
      final slope = geom.slopeAngleRadians;
      final cosSlope = math.cos(slope);
      final sinSlope = math.sin(slope);

      final tangent = Vector3(
        math.sin(bearing) * cosSlope,
        sinSlope,
        math.cos(bearing) * cosSlope,
      )..normalize();

      final right = Vector3(
        math.cos(bearing),
        0.0,
        -math.sin(bearing),
      )..normalize();

      final normal = right.cross(tangent)..normalize();
      if (normal.y < 0) {
        normal.negate();
      }
      return (pos, tangent, right, normal);
    }

    // 1. Brama Startowa (KM 0.0)
    final startFrame = resolveFrame(0.0);
    arches.add(
      RoadsideArchInstance3D(
        id: '${stage.id}_arch_start',
        type: InflatableArchType.start,
        worldPosition: startFrame.$1,
        tangent: startFrame.$2,
        lateralRight: startFrame.$3,
        surfaceNormal: startFrame.$4,
        distanceAlongCourseMeters: 0.0,
        primaryLabel: 'START',
        secondaryLabel: 'KM 0.0 • ${stage.name.toUpperCase()}',
        sponsor: nextSponsor(),
      ),
    );
    _appendBarrierCorridor(
      barriers: barriers,
      stageId: stage.id,
      prefix: 'start',
      startMeters: 0.0,
      endMeters: math.min(180.0, totalMeters * 0.25),
      resolveFrame: resolveFrame,
      nextSponsor: nextSponsor,
    );

    // 2. Bramy Sprint Intermédiaire oraz Col / KOM na segmentach
    for (final seg in stage.segments) {
      final cls = seg.sprintOrKomClassification;
      if (cls == SegmentClassification.none ||
          cls == SegmentClassification.finishLine) {
        continue;
      }

      final archDist = seg.endKm * 1000.0;
      if (archDist <= 50.0 || archDist >= totalMeters - 200.0) continue;

      final frame = resolveFrame(archDist);
      if (cls == SegmentClassification.intermediateSprint) {
        arches.add(
          RoadsideArchInstance3D(
            id: '${stage.id}_arch_sprint_${seg.index}',
            type: InflatableArchType.intermediateSprint,
            worldPosition: frame.$1,
            tangent: frame.$2,
            lateralRight: frame.$3,
            surfaceNormal: frame.$4,
            distanceAlongCourseMeters: archDist,
            primaryLabel: 'SPRINT INTERMÉDIAIRE',
            secondaryLabel: 'KM ${seg.endKm.toStringAsFixed(1)}',
            sponsor: nextSponsor(),
            classification: cls,
          ),
        );
        _appendBarrierCorridor(
          barriers: barriers,
          stageId: stage.id,
          prefix: 'sprint_${seg.index}',
          startMeters: math.max(0.0, archDist - 75.0),
          endMeters: math.min(totalMeters, archDist + 45.0),
          resolveFrame: resolveFrame,
          nextSponsor: nextSponsor,
        );
      } else {
        final komTag = _komCategoryLabel(cls);
        arches.add(
          RoadsideArchInstance3D(
            id: '${stage.id}_arch_kom_${seg.index}',
            type: InflatableArchType.komMountain,
            worldPosition: frame.$1,
            tangent: frame.$2,
            lateralRight: frame.$3,
            surfaceNormal: frame.$4,
            distanceAlongCourseMeters: archDist,
            primaryLabel: 'COL / KOM',
            secondaryLabel: '$komTag • ${seg.endElevationM.round()} M',
            sponsor: nextSponsor(),
            classification: cls,
          ),
        );
        _appendBarrierCorridor(
          barriers: barriers,
          stageId: stage.id,
          prefix: 'kom_${seg.index}',
          startMeters: math.max(0.0, archDist - 60.0),
          endMeters: math.min(totalMeters, archDist + 30.0),
          resolveFrame: resolveFrame,
          nextSponsor: nextSponsor,
        );
      }
    }

    // 3. Brama Flamme Rouge (1 km do mety)
    if (totalMeters > 1500.0) {
      final flammeDist = totalMeters - 1000.0;
      final frame = resolveFrame(flammeDist);
      arches.add(
        RoadsideArchInstance3D(
          id: '${stage.id}_arch_flamme_rouge',
          type: InflatableArchType.flammeRouge,
          worldPosition: frame.$1,
          tangent: frame.$2,
          lateralRight: frame.$3,
          surfaceNormal: frame.$4,
          distanceAlongCourseMeters: flammeDist,
          primaryLabel: 'FLAMME ROUGE',
          secondaryLabel: '1 KM',
          sponsor: nextSponsor(),
        ),
      );
      _appendBarrierCorridor(
        barriers: barriers,
        stageId: stage.id,
        prefix: 'final_km',
        startMeters: flammeDist,
        endMeters: totalMeters,
        resolveFrame: resolveFrame,
        nextSponsor: nextSponsor,
      );
    }

    final pack = StageRoadsideBannersAndArchesPack(
      stageId: stage.id,
      arches: List.unmodifiable(arches),
      barriers: List.unmodifiable(barriers),
    );
    _cachedPack = pack;
    return pack;
  }

  void _appendBarrierCorridor({
    required List<RoadsideBarrierInstance3D> barriers,
    required String stageId,
    required String prefix,
    required double startMeters,
    required double endMeters,
    required (Vector3, Vector3, Vector3, Vector3) Function(double) resolveFrame,
    required RoadsideSponsorBanner Function() nextSponsor,
  }) {
    final step = math.max(1.5, config.barrierSegmentLengthMeters);
    int idx = 0;
    for (double d = startMeters; d < endMeters; d += step) {
      final frame = resolveFrame(d);
      final leftPos = frame.$1 - frame.$3 * config.barrierLateralOffsetMeters;
      final rightPos = frame.$1 + frame.$3 * config.barrierLateralOffsetMeters;

      barriers.add(
        RoadsideBarrierInstance3D(
          id: '${stageId}_bar_${prefix}_L_$idx',
          worldPosition: leftPos,
          tangent: frame.$2,
          lateralRight: frame.$3,
          surfaceNormal: frame.$4,
          distanceAlongCourseMeters: d,
          isRightSide: false,
          lengthMeters: step,
          sponsor: nextSponsor(),
        ),
      );

      barriers.add(
        RoadsideBarrierInstance3D(
          id: '${stageId}_bar_${prefix}_R_$idx',
          worldPosition: rightPos,
          tangent: frame.$2,
          lateralRight: frame.$3,
          surfaceNormal: frame.$4,
          distanceAlongCourseMeters: d,
          isRightSide: true,
          lengthMeters: step,
          sponsor: nextSponsor(),
        ),
      );
      idx++;
    }
  }

  /// Renderuje wszystkie widoczne w stożku kamery dmuchane bramy i barierki z banerami 3D.
  void render({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    List<RoadsideArchInstance3D> arches = const [],
    List<RoadsideBarrierInstance3D> barriers = const [],
    double elapsedAnimSeconds = 0.0,
    double? cameraDistanceMeters,
  }) {
    if (!config.enabled || (arches.isEmpty && barriers.isEmpty)) return;

    final eyePos = projection.cameraPosition;
    final drawQueue = <({double depthSq, VoidCallback draw})>[];

    // 1. Zbieranie i culling barierek ochronnych
    for (final barrier in barriers) {
      if (cameraDistanceMeters != null) {
        final delta = barrier.distanceAlongCourseMeters - cameraDistanceMeters;
        if (delta < -config.backwardVisibilityMeters ||
            delta > config.forwardVisibilityMeters) {
          continue;
        }
      }
      final diff = barrier.worldPosition - eyePos;
      final distSq = diff.length2;
      if (distSq >
          (config.forwardVisibilityMeters + 40.0) *
              (config.forwardVisibilityMeters + 40.0)) {
        continue;
      }
      final centerProj = projection.worldToScreen(barrier.worldPosition);
      if (!centerProj.isInFrontOfCamera) continue;
      if (centerProj.screenX < -180.0 ||
          centerProj.screenX > projection.viewportWidth + 180.0 ||
          centerProj.screenY < -180.0 ||
          centerProj.screenY > projection.viewportHeight + 180.0) {
        continue;
      }

      drawQueue.add((
        depthSq: distSq,
        draw: () => _drawBarrier3D(canvas, projection, barrier, distSq),
      ));
    }

    // 2. Zbieranie i culling dmuchanych bram
    for (final arch in arches) {
      if (cameraDistanceMeters != null) {
        final delta = arch.distanceAlongCourseMeters - cameraDistanceMeters;
        if (delta < -config.backwardVisibilityMeters ||
            delta > config.forwardVisibilityMeters + 80.0) {
          continue;
        }
      }
      final diff = arch.worldPosition - eyePos;
      final distSq = diff.length2;
      if (distSq >
          (config.forwardVisibilityMeters + 100.0) *
              (config.forwardVisibilityMeters + 100.0)) {
        continue;
      }
      final centerProj = projection.worldToScreen(arch.worldPosition);
      if (!centerProj.isInFrontOfCamera) continue;
      if (centerProj.screenX < -320.0 ||
          centerProj.screenX > projection.viewportWidth + 320.0 ||
          centerProj.screenY < -320.0 ||
          centerProj.screenY > projection.viewportHeight + 320.0) {
        continue;
      }

      drawQueue.add((
        depthSq: distSq,
        draw: () => _drawInflatableArch3D(
          canvas,
          projection,
          arch,
          elapsedAnimSeconds,
        ),
      ));
    }

    if (drawQueue.isEmpty) return;

    // 3. Painter's Algorithm (od najdalszych do najbliższych)
    drawQueue.sort((a, b) => b.depthSq.compareTo(a.depthSq));
    for (final cmd in drawQueue) {
      cmd.draw();
    }
  }

  /// Rysuje barierki ochronne 3D z naciągniętym banerem sponsora z [FictionalBrandsCatalog].
  void _drawBarrier3D(
    Canvas canvas,
    Scene3DMathProjection projection,
    RoadsideBarrierInstance3D barrier,
    double distSq,
  ) {
    final halfLen = barrier.lengthMeters * 0.48;
    final h = config.barrierHeightMeters;
    final bannerBottom = h * 0.16;
    final bannerTop = h * 0.90;

    final pStart = barrier.worldPosition - barrier.tangent * halfLen;
    final pEnd = barrier.worldPosition + barrier.tangent * halfLen;

    final b0 = projection.worldToScreen(pStart);
    final b1 = projection.worldToScreen(pEnd);
    final t0 = projection.worldToScreen(pStart + barrier.surfaceNormal * h);
    final t1 = projection.worldToScreen(pEnd + barrier.surfaceNormal * h);

    if (!b0.isInFrontOfCamera ||
        !b1.isInFrontOfCamera ||
        !t0.isInFrontOfCamera ||
        !t1.isInFrontOfCamera) {
      return;
    }

    final bb0 = projection.worldToScreen(
      pStart + barrier.surfaceNormal * bannerBottom,
    );
    final bb1 = projection.worldToScreen(
      pEnd + barrier.surfaceNormal * bannerBottom,
    );
    final bt0 = projection.worldToScreen(
      pStart + barrier.surfaceNormal * bannerTop,
    );
    final bt1 = projection.worldToScreen(
      pEnd + barrier.surfaceNormal * bannerTop,
    );

    // Cień barierki na asfalcie
    final shadowDir = barrier.isRightSide
        ? -barrier.lateralRight * 0.35
        : barrier.lateralRight * 0.35;
    final s0 = projection.worldToScreen(pStart + shadowDir);
    final s1 = projection.worldToScreen(pEnd + shadowDir);
    if (s0.isInFrontOfCamera && s1.isInFrontOfCamera) {
      final shadowPath = Path()
        ..moveTo(b0.screenX, b0.screenY)
        ..lineTo(b1.screenX, b1.screenY)
        ..lineTo(s1.screenX, s1.screenY)
        ..lineTo(s0.screenX, s0.screenY)
        ..close();
      canvas.drawPath(shadowPath, _shadowPaint);
    }

    // Stalowa rama i stopy barierki
    final postStroke = (t0.perspectiveScale * 0.25).clamp(1.0, 3.2);
    _metalPaint.strokeWidth = postStroke;
    canvas.drawLine(
      Offset(b0.screenX, b0.screenY),
      Offset(t0.screenX, t0.screenY),
      _metalPaint,
    );
    canvas.drawLine(
      Offset(b1.screenX, b1.screenY),
      Offset(t1.screenX, t1.screenY),
      _metalPaint,
    );
    canvas.drawLine(
      Offset(t0.screenX, t0.screenY),
      Offset(t1.screenX, t1.screenY),
      _metalPaint,
    );

    // Płachta banera sponsora z FictionalBrandsCatalog
    final bannerPath = Path()
      ..moveTo(bb0.screenX, bb0.screenY)
      ..lineTo(bb1.screenX, bb1.screenY)
      ..lineTo(bt1.screenX, bt1.screenY)
      ..lineTo(bt0.screenX, bt0.screenY)
      ..close();

    _fillPaint.color = barrier.sponsor.primaryColor;
    canvas.drawPath(bannerPath, _fillPaint);

    // Pasek akcentowy w górnej krawędzi banera
    final stripeTop0 = Offset.lerp(
      Offset(bt0.screenX, bt0.screenY),
      Offset(bb0.screenX, bb0.screenY),
      0.18,
    )!;
    final stripeTop1 = Offset.lerp(
      Offset(bt1.screenX, bt1.screenY),
      Offset(bb1.screenX, bb1.screenY),
      0.18,
    )!;
    final accentPath = Path()
      ..moveTo(bt0.screenX, bt0.screenY)
      ..lineTo(bt1.screenX, bt1.screenY)
      ..lineTo(stripeTop1.dx, stripeTop1.dy)
      ..lineTo(stripeTop0.dx, stripeTop0.dy)
      ..close();
    _fillPaint.color = barrier.sponsor.accentColor;
    canvas.drawPath(accentPath, _fillPaint);

    // Obramowanie banera
    _strokePaint
      ..color = AppColors.cardBorder
      ..strokeWidth = 0.8;
    canvas.drawPath(bannerPath, _strokePaint);

    // Napis nazwy marki (LOD: tylko gdy barierka jest wystarczająco blisko, < 95m)
    if (distSq < 95.0 * 95.0) {
      final quadW = (Offset(bb1.screenX, bb1.screenY) -
              Offset(bb0.screenX, bb0.screenY))
          .distance;
      final quadH = (Offset(bb0.screenX, bb0.screenY) -
              Offset(bt0.screenX, bt0.screenY))
          .distance;
      if (quadW > 22.0 && quadH > 8.0) {
        final center = Offset(
          (bb0.screenX + bb1.screenX + bt0.screenX + bt1.screenX) * 0.25,
          (bb0.screenY + bb1.screenY + bt0.screenY + bt1.screenY) * 0.25,
        );
        final angle = math.atan2(
          bt1.screenY - bt0.screenY,
          bt1.screenX - bt0.screenX,
        );
        final fontSize = (quadH * 0.52).clamp(6.0, 14.0);
        final tp = _getTextPainter(
          text: barrier.sponsor.brandName,
          fontSize: fontSize,
          color: barrier.sponsor.textColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        );
        if (tp.width <= quadW * 0.92) {
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(angle);
          tp.paint(canvas, Offset(-tp.width * 0.5, -tp.height * 0.5));
          canvas.restore();
        }
      }
    }
  }

  /// Rysuje w 3D dmuchaną bramę (Start, Sprint Intermédiaire, Col / KOM, Flamme Rouge).
  void _drawInflatableArch3D(
    Canvas canvas,
    Scene3DMathProjection projection,
    RoadsideArchInstance3D arch,
    double animSeconds,
  ) {
    final halfSpan = config.archSpanMeters * 0.5;
    final h = config.archHeightMeters;
    final tubeRadius = config.archTubeRadiusMeters;
    final depthHalf = tubeRadius * 0.55;

    // Subtelna pulsacja dmuchawy (0.985..1.015)
    final breathe = 1.0 + math.sin(animSeconds * 5.2) * 0.012;

    // 7 węzłów profilu bramy w przestrzeni 3D (podkowa / portal dmuchany)
    final localProfile = <(double lat, double up)>[
      (-halfSpan, 0.0),
      (-halfSpan, h * 0.68 * breathe),
      (-halfSpan * 0.62, h * 0.96 * breathe),
      (0.0, h * breathe),
      (halfSpan * 0.62, h * 0.96 * breathe),
      (halfSpan, h * 0.68 * breathe),
      (halfSpan, 0.0),
    ];

    final frontPts = <Offset>[];
    final backPts = <Offset>[];
    double avgScale = 0.0;

    for (final (lat, up) in localProfile) {
      final baseWorld = arch.worldPosition +
          arch.lateralRight * lat +
          arch.surfaceNormal * up;
      final frontProj =
          projection.worldToScreen(baseWorld - arch.tangent * depthHalf);
      final backProj =
          projection.worldToScreen(baseWorld + arch.tangent * depthHalf);
      if (!frontProj.isInFrontOfCamera || !backProj.isInFrontOfCamera) {
        return;
      }
      frontPts.add(Offset(frontProj.screenX, frontProj.screenY));
      backPts.add(Offset(backProj.screenX, backProj.screenY));
      avgScale += frontProj.perspectiveScale;
    }
    avgScale /= localProfile.length;

    final tubePx = (avgScale * tubeRadius * 1.15).clamp(4.0, 56.0);
    final colors = _archColorScheme(arch);

    // 1. Cień bramy rzucony na asfalt
    final shadowStart = projection.worldToScreen(
      arch.worldPosition - arch.lateralRight * halfSpan + arch.tangent * 0.4,
    );
    final shadowEnd = projection.worldToScreen(
      arch.worldPosition + arch.lateralRight * halfSpan + arch.tangent * 0.4,
    );
    if (shadowStart.isInFrontOfCamera && shadowEnd.isInFrontOfCamera) {
      _strokePaint
        ..color = Colors.black.withValues(alpha: 0.30)
        ..strokeWidth = (tubePx * 0.55).clamp(3.0, 26.0);
      canvas.drawLine(
        Offset(shadowStart.screenX, shadowStart.screenY),
        Offset(shadowEnd.screenX, shadowEnd.screenY),
        _strokePaint,
      );
    }

    // 2. Tylna warstwa dmuchanego łuku (efekt głębi 3D)
    final backPath = _buildSmoothArchPath(backPts);
    _strokePaint
      ..color = colors.shadowColor
      ..strokeWidth = tubePx * 0.96;
    canvas.drawPath(backPath, _strokePaint);

    // 3. Przednia główna warstwa dmuchanego łuku
    final frontPath = _buildSmoothArchPath(frontPts);
    _strokePaint
      ..color = colors.baseColor
      ..strokeWidth = tubePx;
    canvas.drawPath(frontPath, _strokePaint);

    // 4. Charakterystyczne wzory na łuku (grochy KOM, paski lub refleks)
    if (arch.type == InflatableArchType.komMountain) {
      _drawPolkaDotsAlongArch(canvas, frontPts, tubePx);
    } else {
      // Błyszczący refleks światła wzdłuż dmuchanego rękawa
      _highlightPaint.strokeWidth = (tubePx * 0.22).clamp(1.2, 10.0);
      canvas.drawPath(frontPath, _highlightPaint);
    }

    // 5. Skrzynka dmuchawy u podstawy lewego słupka
    final blowerCenter = frontPts.first;
    final blowerSize = (tubePx * 0.65).clamp(4.0, 26.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(blowerCenter.dx - blowerSize * 0.75, blowerCenter.dy - blowerSize * 0.45),
          width: blowerSize,
          height: blowerSize * 0.85,
        ),
        const Radius.circular(3.0),
      ),
      _blowerPaint,
    );

    // 6. Czerwony trójkąt Flamme Rouge zwisający ze szczytu bramy
    if (arch.type == InflatableArchType.flammeRouge) {
      _drawFlammeRougeTriangle(
        canvas,
        projection,
        arch,
        h * breathe,
        animSeconds,
        tubePx,
      );
    }

    // 7. Górna tablica / baner na koronie bramy (napis + sponsor)
    _drawArchCrownHeader(
      canvas: canvas,
      crownPos: frontPts[3],
      leftShoulder: frontPts[2],
      rightShoulder: frontPts[4],
      tubePx: tubePx,
      arch: arch,
      colors: colors,
    );
  }

  void _drawPolkaDotsAlongArch(
    Canvas canvas,
    List<Offset> pts,
    double tubePx,
  ) {
    final dotR = (tubePx * 0.24).clamp(1.5, 11.0);
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      for (int s = 1; s <= 3; s++) {
        final t = s / 4.0;
        final p = Offset.lerp(a, b, t)!;
        final jitter = (s.isEven ? 0.18 : -0.18) * tubePx;
        canvas.drawCircle(Offset(p.dx + jitter * 0.4, p.dy + jitter), dotR, _polkaDotPaint);
      }
    }
  }

  void _drawFlammeRougeTriangle(
    Canvas canvas,
    Scene3DMathProjection projection,
    RoadsideArchInstance3D arch,
    double crownHeightMeters,
    double animSeconds,
    double tubePx,
  ) {
    final swayMeters = math.sin(animSeconds * 3.4) * 0.16;
    final topLeftWorld = arch.worldPosition +
        arch.lateralRight * (-1.15) +
        arch.surfaceNormal * (crownHeightMeters - 0.35);
    final topRightWorld = arch.worldPosition +
        arch.lateralRight * 1.15 +
        arch.surfaceNormal * (crownHeightMeters - 0.35);
    final tipWorld = arch.worldPosition +
        arch.lateralRight * swayMeters +
        arch.surfaceNormal * (crownHeightMeters - 2.35) +
        arch.tangent * (swayMeters * 0.6);

    final pL = projection.worldToScreen(topLeftWorld);
    final pR = projection.worldToScreen(topRightWorld);
    final pTip = projection.worldToScreen(tipWorld);
    if (!pL.isInFrontOfCamera ||
        !pR.isInFrontOfCamera ||
        !pTip.isInFrontOfCamera) {
      return;
    }

    final trianglePath = Path()
      ..moveTo(pL.screenX, pL.screenY)
      ..lineTo(pR.screenX, pR.screenY)
      ..lineTo(pTip.screenX, pTip.screenY)
      ..close();

    _fillPaint.color = AppColors.crimsonAlert;
    canvas.drawPath(trianglePath, _fillPaint);

    _strokePaint
      ..color = AppColors.textPrimary
      ..strokeWidth = (tubePx * 0.08).clamp(1.0, 2.5);
    canvas.drawPath(trianglePath, _strokePaint);

    final triWidth = (pR.screenX - pL.screenX).abs();
    if (triWidth > 18.0) {
      final center = Offset(
        (pL.screenX + pR.screenX + pTip.screenX) / 3.0,
        (pL.screenY + pR.screenY + pTip.screenY) / 3.0,
      );
      final tp = _getTextPainter(
        text: '1 KM',
        fontSize: (triWidth * 0.24).clamp(7.0, 16.0),
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w900,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: tp.width + 6,
          height: tp.height + 2,
        ),
        _fillPaint..color = AppColors.crimsonAlert.withValues(alpha: 0.75),
      );
      tp.paint(canvas, Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5));
    }
  }

  void _drawArchCrownHeader({
    required Canvas canvas,
    required Offset crownPos,
    required Offset leftShoulder,
    required Offset rightShoulder,
    required double tubePx,
    required RoadsideArchInstance3D arch,
    required _ArchColorScheme colors,
  }) {
    final spanPx = (rightShoulder.dx - leftShoulder.dx).abs();
    if (spanPx < 28.0) return;

    final boardW = (spanPx * 0.72).clamp(36.0, 320.0);
    final boardH = (tubePx * 0.92).clamp(14.0, 48.0);
    final rect = Rect.fromCenter(
      center: crownPos,
      width: boardW,
      height: boardH,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6.0));

    _fillPaint.color = colors.headerBgColor;
    canvas.drawRRect(rrect, _fillPaint);

    _strokePaint
      ..color = colors.headerBorderColor
      ..strokeWidth = (tubePx * 0.09).clamp(1.0, 2.5);
    canvas.drawRRect(rrect, _strokePaint);

    final mainFontSize = (boardH * 0.42).clamp(7.0, 16.0);
    final mainTp = _getTextPainter(
      text: arch.primaryLabel,
      fontSize: mainFontSize,
      color: colors.headerTextColor,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );

    if (mainTp.width <= boardW * 0.92) {
      final hasSub = arch.secondaryLabel != null && boardH >= 24.0;
      final subTp = hasSub
          ? _getTextPainter(
              text: '${arch.secondaryLabel} • ${arch.sponsor.brandName}',
              fontSize: (boardH * 0.24).clamp(6.0, 11.0),
              color: colors.headerSubtextColor,
              fontWeight: FontWeight.w600,
            )
          : null;

      if (subTp != null && subTp.width <= boardW * 0.92) {
        mainTp.paint(
          canvas,
          Offset(crownPos.dx - mainTp.width * 0.5, crownPos.dy - mainTp.height * 0.85),
        );
        subTp.paint(
          canvas,
          Offset(crownPos.dx - subTp.width * 0.5, crownPos.dy + 1.5),
        );
      } else {
        mainTp.paint(
          canvas,
          Offset(crownPos.dx - mainTp.width * 0.5, crownPos.dy - mainTp.height * 0.5),
        );
      }
    }
  }

  Path _buildSmoothArchPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    return path;
  }

  _ArchColorScheme _archColorScheme(RoadsideArchInstance3D arch) {
    switch (arch.type) {
      case InflatableArchType.start:
        return const _ArchColorScheme(
          baseColor: AppColors.primaryAccent,
          shadowColor: Color(0xFF5A2B2A),
          headerBgColor: AppColors.surface,
          headerBorderColor: AppColors.goldAccent,
          headerTextColor: AppColors.goldAccent,
          headerSubtextColor: AppColors.textPrimary,
        );
      case InflatableArchType.intermediateSprint:
        return const _ArchColorScheme(
          baseColor: Color(0xFF047857),
          shadowColor: Color(0xFF064E3B),
          headerBgColor: Color(0xFF064E3B),
          headerBorderColor: AppColors.statusSuccess,
          headerTextColor: AppColors.textPrimary,
          headerSubtextColor: Color(0xFFA7F3D0),
        );
      case InflatableArchType.komMountain:
        return const _ArchColorScheme(
          baseColor: Color(0xFFF8FAFC),
          shadowColor: Color(0xFFCBD5E1),
          headerBgColor: AppColors.surface,
          headerBorderColor: AppColors.crimsonAlert,
          headerTextColor: AppColors.textPrimary,
          headerSubtextColor: AppColors.crimsonAlert,
        );
      case InflatableArchType.flammeRouge:
        return const _ArchColorScheme(
          baseColor: Color(0xFFDC2626),
          shadowColor: Color(0xFF991B1B),
          headerBgColor: Color(0xFF7F1D1D),
          headerBorderColor: AppColors.textPrimary,
          headerTextColor: AppColors.textPrimary,
          headerSubtextColor: AppColors.goldAccent,
        );
    }
  }

  TextPainter _getTextPainter({
    required String text,
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
    double letterSpacing = 0.0,
  }) {
    final quantizedSize = (fontSize * 2.0).roundToDouble() / 2.0;
    final key = '$text|$quantizedSize|${color.toARGB32()}|${fontWeight.value}|$letterSpacing';
    final cached = _textPainterCache[key];
    if (cached != null) return cached;

    if (_textPainterCache.length > 256) {
      _textPainterCache.clear();
    }

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: quantizedSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _textPainterCache[key] = tp;
    return tp;
  }

  String _komCategoryLabel(SegmentClassification cls) {
    switch (cls) {
      case SegmentClassification.horsCategorie:
        return 'HC';
      case SegmentClassification.cat1:
        return 'CAT 1';
      case SegmentClassification.cat2:
        return 'CAT 2';
      case SegmentClassification.cat3:
        return 'CAT 3';
      case SegmentClassification.cat4:
        return 'CAT 4';
      default:
        return 'KOM';
    }
  }

  double _elevationAt(double distMeters, List<StageSegment> segments) {
    final km = distMeters / 1000.0;
    for (final s in segments) {
      if (km >= s.startKm && km <= s.endKm) {
        final t = s.lengthKm > 0.0 ? ((km - s.startKm) / s.lengthKm) : 0.0;
        return s.startElevationM + (s.endElevationM - s.startElevationM) * t;
      }
    }
    return segments.isNotEmpty ? segments.last.endElevationM : 0.0;
  }

  double _gradientAt(double distMeters, List<StageSegment> segments) {
    final km = distMeters / 1000.0;
    for (final s in segments) {
      if (km >= s.startKm && km <= s.endKm) {
        return s.gradientPercent;
      }
    }
    return 0.0;
  }
}

class _ArchColorScheme {
  final Color baseColor;
  final Color shadowColor;
  final Color headerBgColor;
  final Color headerBorderColor;
  final Color headerTextColor;
  final Color headerSubtextColor;

  const _ArchColorScheme({
    required this.baseColor,
    required this.shadowColor,
    required this.headerBgColor,
    required this.headerBorderColor,
    required this.headerTextColor,
    required this.headerSubtextColor,
  });
}
