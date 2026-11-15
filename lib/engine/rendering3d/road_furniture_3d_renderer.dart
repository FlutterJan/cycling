// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TYPY INFRASTRUKTURY TRASY I MAREK SPONSORÓW
// =============================================================================

/// Typy obiektów infrastruktury przydrożnej i scenografii wyścigu kolarskiego (Road Furniture).
enum RoadFurnitureType {
  /// Metalowa barierka ochronna z naciągniętym banerem reklamowym sponsora.
  crowdBarrierWithBanner('Barierka z Banerem Sponsora', 3.0),

  /// Przydrożna tablica odliczania dystansu do mety (20 km, 10 km, 5 km, 3 km).
  distanceCountdownBoard('Tablica Odliczania Dystansu', 4.5),

  /// Słynna dmuchana czerwona brama Flamme Rouge (1 km do mety) z trójkątnym proporcem.
  flammeRougeArch('Brama Dmuchana Flamme Rouge (1 km)', 9.0),

  /// Zielona brama lotnej premii sprinterskiej (Intermediate Sprint) z czujnikami pomiaru czasu.
  intermediateSprintArch('Brama Lotnej Premii (Zielona)', 9.0),

  /// Brama premii górskiej KOM w czerwone grochy (GPM / King of the Mountains).
  komMountainArch('Brama Premii Górskiej (Grochy)', 9.0),

  /// Główna brama linii mety z telebimem, zegarem LED i fotokomórką (Finish Line Gantry).
  finishLineGantry('Główna Brama Mety z Fotokomórką', 11.0),

  /// Szachownica linii mety namalowana na asfalcie wraz z gumowym najazdem na pętlę transpondera.
  finishCheckeredLine('Szachownica Linii Mety na Asfalcie', 8.5),

  /// Wieża fotokomórki i sędziowskiej kamery liniowej (Photo-Finish Tower).
  finishPhotoFinishTower('Wieża Fotokomórki Sędziowskiej', 3.5),

  /// Zadaszona trybuna VIP ze szpalerem siedzeń dla gości honorowych i banerami hospitality.
  finishVipGrandstand('Trybuna VIP i Sektor Prasowy', 18.0),

  /// Ścianka dekoracji podium z podium zwycięzców etapu (za linią mety).
  finishPodiumBackdrop('Ścianka Podium i Ceremonia Mety', 12.0);

  final String displayName;
  final double defaultWidthMeters;

  const RoadFurnitureType(this.displayName, this.defaultWidthMeters);

  /// Czy element jest bramą bramownicową rozpiętą nad całą szerokością jezdni.
  bool get isOverheadArch =>
      this == RoadFurnitureType.flammeRougeArch ||
      this == RoadFurnitureType.intermediateSprintArch ||
      this == RoadFurnitureType.komMountainArch ||
      this == RoadFurnitureType.finishLineGantry;

  /// Czy element należy do strefy bezpośredniej linii mety.
  bool get isFinishZone =>
      this == RoadFurnitureType.finishLineGantry ||
      this == RoadFurnitureType.finishCheckeredLine ||
      this == RoadFurnitureType.finishPhotoFinishTower ||
      this == RoadFurnitureType.finishVipGrandstand ||
      this == RoadFurnitureType.finishPodiumBackdrop;
}

/// Oficjalne marki sponsorów wyścigów WorldTour i Grand Tourów (barwy i typografia).
enum SponsorBrand {
  shimano(
    name: 'SHIMANO',
    primaryColor: Color(0xFF005696),
    textColor: Colors.white,
    accentColor: Color(0xFF38BDF8),
  ),
  skoda(
    name: 'ŠKODA',
    primaryColor: Color(0xFF047857),
    textColor: Colors.white,
    accentColor: Color(0xFF10B981),
  ),
  continental(
    name: 'CONTINENTAL',
    primaryColor: Color(0xFFEA580C),
    textColor: Colors.black,
    accentColor: Color(0xFFFBBF24),
  ),
  tissot(
    name: 'TISSOT',
    primaryColor: Color(0xFFDC2626),
    textColor: Colors.white,
    accentColor: Color(0xFFFFFFFF),
  ),
  santini(
    name: 'SANTINI',
    primaryColor: Color(0xFF0F172A),
    textColor: Colors.white,
    accentColor: Color(0xFF06B6D4),
  ),
  lcl(
    name: 'LCL',
    primaryColor: Color(0xFFFFD700),
    textColor: Color(0xFF0F172A),
    accentColor: Color(0xFF1E3A8A),
  ),
  carrefour(
    name: 'CARREFOUR',
    primaryColor: Color(0xFFFFFFFF),
    textColor: Color(0xFFEF4444),
    accentColor: Color(0xFF3B82F6),
  );

  final String name;
  final Color primaryColor;
  final Color textColor;
  final Color accentColor;

  const SponsorBrand({
    required this.name,
    required this.primaryColor,
    required this.textColor,
    required this.accentColor,
  });
}

// =============================================================================
// 2. MODEL POJEDYNCZEGO OBIEKTU INFRASTRUKTURY W ŚWIECIE 3D
// =============================================================================

/// Instancja obiektu infrastruktury przydrożnej umieszczona na trasie wyścigu.
class RoadFurnitureInstance3D {
  final String id;
  final RoadFurnitureType type;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final double scale;
  final SponsorBrand sponsor;
  final String? customLabel;
  final SegmentClassification? classification;
  final double rotationYawRadians;

  const RoadFurnitureInstance3D({
    required this.id,
    required this.type,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    required this.lateralOffsetMeters,
    required this.elevationMeters,
    this.scale = 1.0,
    this.sponsor = SponsorBrand.shimano,
    this.customLabel,
    this.classification,
    this.rotationYawRadians = 0.0,
  });
}

// =============================================================================
// 3. KONFIGURACJA GENERATORA I RENDERERA INFRASTRUKTURY
// =============================================================================

/// Parametry konfiguracyjne renderowania infrastruktury szosowej 3D.
class RoadFurnitureConfig {
  /// Czy moduł renderera jest włączony.
  final bool enabled;

  /// Zasięg widoczności obiektów przed kamerą w metrach [m].
  final double forwardVisibilityMeters;

  /// Zasięg widoczności obiektów za plecami kamery [m].
  final double backwardVisibilityMeters;

  /// Długość szpaleru barierek przed i za linią mety w metrach [m].
  final double finishBarriersLengthMeters;

  /// Długość szpaleru barierek na szczytach górskich KOM [m].
  final double komBarriersLengthMeters;

  /// Długość szpaleru barierek przy lotnych premiach [m].
  final double sprintBarriersLengthMeters;

  /// Długość pojedynczego modułu barierki ochronnej [m].
  final double barrierModuleSpacingMeters;

  /// Czy renderować trybuny VIP w strefie mety.
  final bool enableVipGrandstands;

  /// Czy renderować wieże fotokomórki i sędziowskie kamery liniowe.
  final bool enablePhotoFinishTowers;

  /// Czy renderować tablice odliczania dystansu (20, 10, 5, 3 km).
  final bool enableCountdownBoards;

  /// Czy renderować czerwoną bramę Flamme Rouge (1 km).
  final bool enableFlammeRouge;

  const RoadFurnitureConfig({
    this.enabled = true,
    this.forwardVisibilityMeters = 380.0,
    this.backwardVisibilityMeters = 70.0,
    this.finishBarriersLengthMeters = 1200.0,
    this.komBarriersLengthMeters = 240.0,
    this.sprintBarriersLengthMeters = 200.0,
    this.barrierModuleSpacingMeters = 3.0,
    this.enableVipGrandstands = true,
    this.enablePhotoFinishTowers = true,
    this.enableCountdownBoards = true,
    this.enableFlammeRouge = true,
  });
}

// =============================================================================
// 4. GŁÓWNY MODUŁ RENDERUJĄCY INFRASTRUKTURĘ TRASY 3D
// =============================================================================

/// Zaawansowany moduł renderujący w przestrzeni 3D pełną infrastrukturę trasy:
/// - Banery reklamowe na metalowych barierkach (Shimano, Škoda, Continental, Tissot, Santini, LCL),
/// - Tablice odliczające dystans do mety (20 km, 10 km, 5 km, 3 km - UCI safety zone),
/// - Dmuchaną czerwoną bramę *Flamme Rouge (1 km)* z trójkątnym proporcem,
/// - Zielone bramy lotnych premii (Intermediate Sprint) ze szmaragdowymi pylonami,
/// - Bramy premii górskich KOM (Cat 4, Cat 3, Cat 2, Cat 1, Hors Catégorie) w czerwone grochy,
/// - Pełną scenografię linii mety: bramownicę z zegarem LED i fotokomórką, szachownicę na asfalcie,
///   zadaszone trybuny VIP z gośćmi honorowymi oraz wieże sędziowskich kamer liniowych.
class RoadFurniture3DRenderer {
  final RoadFurnitureConfig config;

  // Prealokowane obiekty farb malarskich dla gwarancji 120 FPS Zero-GC
  late final Paint _trussMetalPaint;
  late final Paint _trussHighlightPaint;
  late final Paint _trussShadowPaint;
  late final Paint _barrierMetalPaint;
  late final Paint _barrierFootPaint;
  late final Paint _flammeRougeArchPaint;
  late final Paint _flammeRougeGlowPaint;
  late final Paint _flammeRougePennantPaint;
  late final Paint _blowerBoxPaint;
  late final Paint _greenSprintArchPaint;
  late final Paint _polkaWhiteArchPaint;
  late final Paint _polkaDotRedPaint;
  late final Paint _gantryLedPanelPaint;
  late final Paint _gantryGoldBorderPaint;
  late final Paint _finishCheckeredBlackPaint;
  late final Paint _finishCheckeredWhitePaint;
  late final Paint _cableProtectorYellowPaint;
  late final Paint _vipRoofCanopyPaint;
  late final Paint _vipStandPlankPaint;
  late final Paint _countdownNavyPaint;
  late final Paint _countdownYellowBorderPaint;
  late final Paint _photoFinishLensPaint;

  // Bufor wygenerowanych obiektów dla aktywnego etapu
  List<RoadFurnitureInstance3D> _cachedStageFurniture = const [];
  String? _lastStageId;

  RoadFurniture3DRenderer({
    this.config = const RoadFurnitureConfig(),
  }) {
    _initPaintCache();
  }

  void _initPaintCache() {
    _trussMetalPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    _trussHighlightPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _trussShadowPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    _barrierMetalPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _barrierFootPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;

    _flammeRougeArchPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.fill;

    _flammeRougeGlowPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _flammeRougePennantPaint = Paint()
      ..color = const Color(0xFFB91C1C)
      ..style = PaintingStyle.fill;

    _blowerBoxPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;

    _greenSprintArchPaint = Paint()
      ..color = const Color(0xFF047857)
      ..style = PaintingStyle.fill;

    _polkaWhiteArchPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    _polkaDotRedPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    _gantryLedPanelPaint = Paint()
      ..color = const Color(0xFF05070B)
      ..style = PaintingStyle.fill;

    _gantryGoldBorderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    _finishCheckeredBlackPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    _finishCheckeredWhitePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    _cableProtectorYellowPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    _vipRoofCanopyPaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;

    _vipStandPlankPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.fill;

    _countdownNavyPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    _countdownYellowBorderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _photoFinishLensPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
  }

  // ===========================================================================
  // 5. GENEROWANIE INFRASTRUKTURY ETAPU (PROCEDURAL SPAWNER)
  // ===========================================================================

  /// Tworzy lub zwraca z bufora kompletną infrastrukturę przydrożną dla danego etapu.
  List<RoadFurnitureInstance3D> spawnFurnitureForStage({
    required RaceStage stage,
    List<StageSegment>? segments,
  }) {
    if (!config.enabled) return const [];

    final activeSegments = segments ?? stage.segments;
    final totalStageDistMeters = stage.totalDistanceKm * 1000.0;

    if (_lastStageId == stage.id && _cachedStageFurniture.isNotEmpty) {
      return _cachedStageFurniture;
    }

    final items = <RoadFurnitureInstance3D>[];
    int entityCounter = 0;

    // Lista sponsorów do cyklicznego naprzemiennego nanoszenia na barierki
    final sponsorCycle = [
      SponsorBrand.shimano,
      SponsorBrand.skoda,
      SponsorBrand.continental,
      SponsorBrand.tissot,
      SponsorBrand.santini,
      SponsorBrand.lcl,
    ];

    // -------------------------------------------------------------------------
    // A. TABLICE ODLICZANIA DYSTANSU DO METY (20 KM, 10 KM, 5 KM, 3 KM)
    // -------------------------------------------------------------------------
    if (config.enableCountdownBoards && totalStageDistMeters > 22000.0) {
      final countdowns = [
        (20000.0, '20 KM'),
        (10000.0, '10 KM'),
        (5000.0, '5 KM'),
        (3000.0, '3 KM'),
      ];

      for (final (remainingDist, shortTag) in countdowns) {
        final distAlongCourse = totalStageDistMeters - remainingDist;
        if (distAlongCourse <= 0) continue;

        final elevation =
            _calculateElevationAt(distAlongCourse, activeSegments);
        final gradient = _calculateGradientAt(distAlongCourse, activeSegments);

        // Umieszczamy tablicę po prawej stronie jezdni (+4.8m)
        final worldPos = Scene3DMathProjection.courseToWorld3D(
          distanceMeters: distAlongCourse,
          lateralOffsetMeters: 4.8,
          elevationMeters: elevation,
          turningRadiusMeters: double.infinity,
          gradientPercent: gradient,
        );

        items.add(RoadFurnitureInstance3D(
          id: 'countdown_${entityCounter++}',
          type: RoadFurnitureType.distanceCountdownBoard,
          worldPosition: worldPos,
          tangent: Vector3(0.0, gradient * 0.01, 1.0)..normalize(),
          lateralRight: Vector3(1.0, 0.0, 0.0),
          surfaceNormal: Vector3(0.0, 1.0, 0.0),
          distanceAlongCourseMeters: distAlongCourse,
          lateralOffsetMeters: 4.8,
          elevationMeters: elevation,
          customLabel: shortTag,
          sponsor: remainingDist == 3000.0
              ? SponsorBrand.tissot
              : SponsorBrand.shimano,
        ));
      }
    }

    // -------------------------------------------------------------------------
    // B. DMUCHANA CZERWONA BRAMA FLAMME ROUGE (DOKŁADNIE 1.0 KM DO METY)
    // -------------------------------------------------------------------------
    if (config.enableFlammeRouge && totalStageDistMeters > 1500.0) {
      final flammeRougeDist = totalStageDistMeters - 1000.0;
      final elevation = _calculateElevationAt(flammeRougeDist, activeSegments);
      final gradient = _calculateGradientAt(flammeRougeDist, activeSegments);

      final worldPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: flammeRougeDist,
        lateralOffsetMeters: 0.0, // Wycentrowana nad osią jezdni
        elevationMeters: elevation,
        turningRadiusMeters: double.infinity,
        gradientPercent: gradient,
      );

      items.add(RoadFurnitureInstance3D(
        id: 'flamme_rouge_${entityCounter++}',
        type: RoadFurnitureType.flammeRougeArch,
        worldPosition: worldPos,
        tangent: Vector3(0.0, gradient * 0.01, 1.0)..normalize(),
        lateralRight: Vector3(1.0, 0.0, 0.0),
        surfaceNormal: Vector3(0.0, 1.0, 0.0),
        distanceAlongCourseMeters: flammeRougeDist,
        lateralOffsetMeters: 0.0,
        elevationMeters: elevation,
        customLabel: '1 KM',
        sponsor: SponsorBrand.tissot,
      ));
    }

    // -------------------------------------------------------------------------
    // C. BRAMY LOTNYCH PREMII ORAZ PREMII GÓRSKICH WZDŁUŻ ETAPU
    // -------------------------------------------------------------------------
    for (final seg in activeSegments) {
      final classification = seg.sprintOrKomClassification;
      if (classification == SegmentClassification.none) continue;

      final double markerDistMeters = seg.endKm * 1000.0;
      final double elevation = seg.endElevationM;
      final double gradient = seg.gradientPercent;

      // C1. Brama lotnej premii sprinterskiej (Intermediate Sprint)
      if (classification == SegmentClassification.intermediateSprint) {
        final worldPos = Scene3DMathProjection.courseToWorld3D(
          distanceMeters: markerDistMeters,
          lateralOffsetMeters: 0.0,
          elevationMeters: elevation,
          turningRadiusMeters: double.infinity,
          gradientPercent: gradient,
        );

        items.add(RoadFurnitureInstance3D(
          id: 'sprint_arch_${entityCounter++}',
          type: RoadFurnitureType.intermediateSprintArch,
          worldPosition: worldPos,
          tangent: Vector3(0.0, gradient * 0.01, 1.0)..normalize(),
          lateralRight: Vector3(1.0, 0.0, 0.0),
          surfaceNormal: Vector3(0.0, 1.0, 0.0),
          distanceAlongCourseMeters: markerDistMeters,
          lateralOffsetMeters: 0.0,
          elevationMeters: elevation,
          classification: classification,
          customLabel: 'SPRINT INTERMÉDIAIRE',
          sponsor: SponsorBrand.skoda,
        ));

        // Barierki reklamowe wokół lotnej premii (120m przed, 40m po)
        _spawnBarrierCorridor(
          items: items,
          activeSegments: activeSegments,
          startDistMeters: math.max(0.0, markerDistMeters - 120.0),
          endDistMeters: markerDistMeters + 40.0,
          sponsorCycle: sponsorCycle,
          idPrefix: 'sprint_barr',
        );
      }

      // C2. Brama premii górskiej KOM (Cat 4, Cat 3, Cat 2, Cat 1, Hors Catégorie)
      else if (classification == SegmentClassification.cat4 ||
          classification == SegmentClassification.cat3 ||
          classification == SegmentClassification.cat2 ||
          classification == SegmentClassification.cat1 ||
          classification == SegmentClassification.horsCategorie) {
        final worldPos = Scene3DMathProjection.courseToWorld3D(
          distanceMeters: markerDistMeters,
          lateralOffsetMeters: 0.0,
          elevationMeters: elevation,
          turningRadiusMeters: double.infinity,
          gradientPercent: gradient,
        );

        final label = _formatKomLabel(classification, elevation);

        items.add(RoadFurnitureInstance3D(
          id: 'kom_arch_${entityCounter++}',
          type: RoadFurnitureType.komMountainArch,
          worldPosition: worldPos,
          tangent: Vector3(0.0, gradient * 0.01, 1.0)..normalize(),
          lateralRight: Vector3(1.0, 0.0, 0.0),
          surfaceNormal: Vector3(0.0, 1.0, 0.0),
          distanceAlongCourseMeters: markerDistMeters,
          lateralOffsetMeters: 0.0,
          elevationMeters: elevation,
          classification: classification,
          customLabel: label,
          sponsor: SponsorBrand.carrefour,
        ));

        // Barierki ochronne na szczycie górskim
        _spawnBarrierCorridor(
          items: items,
          activeSegments: activeSegments,
          startDistMeters: math.max(
              0.0, markerDistMeters - config.komBarriersLengthMeters * 0.7),
          endDistMeters:
              markerDistMeters + (config.komBarriersLengthMeters * 0.3),
          sponsorCycle: sponsorCycle,
          idPrefix: 'kom_barr',
        );
      }
    }

    // -------------------------------------------------------------------------
    // D. PEŁNA SCENOGRAFIA LINII METY (FINISH LINE SCENERY COMPLEX)
    // -------------------------------------------------------------------------
    final double finishDist = totalStageDistMeters;
    final double finishElevation =
        _calculateElevationAt(finishDist, activeSegments);
    final double finishGradient =
        _calculateGradientAt(finishDist, activeSegments);

    // D1. Główna brama mety (Finish Line Gantry)
    final gantryPos = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: finishDist,
      lateralOffsetMeters: 0.0,
      elevationMeters: finishElevation,
      turningRadiusMeters: double.infinity,
      gradientPercent: finishGradient,
    );

    items.add(RoadFurnitureInstance3D(
      id: 'finish_gantry_${entityCounter++}',
      type: RoadFurnitureType.finishLineGantry,
      worldPosition: gantryPos,
      tangent: Vector3(0.0, finishGradient * 0.01, 1.0)..normalize(),
      lateralRight: Vector3(1.0, 0.0, 0.0),
      surfaceNormal: Vector3(0.0, 1.0, 0.0),
      distanceAlongCourseMeters: finishDist,
      lateralOffsetMeters: 0.0,
      elevationMeters: finishElevation,
      customLabel: 'ARRIVÉE / FINISH',
      sponsor: SponsorBrand.tissot,
    ));

    // D2. Szachownica mety na asfalcie
    items.add(RoadFurnitureInstance3D(
      id: 'finish_checkered_${entityCounter++}',
      type: RoadFurnitureType.finishCheckeredLine,
      worldPosition: gantryPos,
      tangent: Vector3(0.0, finishGradient * 0.01, 1.0)..normalize(),
      lateralRight: Vector3(1.0, 0.0, 0.0),
      surfaceNormal: Vector3(0.0, 1.0, 0.0),
      distanceAlongCourseMeters: finishDist,
      lateralOffsetMeters: 0.0,
      elevationMeters: finishElevation,
      sponsor: SponsorBrand.tissot,
    ));

    // D3. Wieże fotokomórki po obu stronach kreski mety (+/- 4.6m)
    if (config.enablePhotoFinishTowers) {
      for (final side in [-4.6, 4.6]) {
        final towerPos = Scene3DMathProjection.courseToWorld3D(
          distanceMeters: finishDist,
          lateralOffsetMeters: side,
          elevationMeters: finishElevation,
          turningRadiusMeters: double.infinity,
          gradientPercent: finishGradient,
        );

        items.add(RoadFurnitureInstance3D(
          id: 'finish_tower_${side > 0 ? "r" : "l"}_${entityCounter++}',
          type: RoadFurnitureType.finishPhotoFinishTower,
          worldPosition: towerPos,
          tangent: Vector3(0.0, finishGradient * 0.01, 1.0)..normalize(),
          lateralRight: Vector3(1.0, 0.0, 0.0),
          surfaceNormal: Vector3(0.0, 1.0, 0.0),
          distanceAlongCourseMeters: finishDist,
          lateralOffsetMeters: side,
          elevationMeters: finishElevation,
          sponsor: SponsorBrand.tissot,
        ));
      }
    }

    // D4. Zadaszone trybuny VIP wzdłuż finiszu (-85m do +25m względem kreski)
    if (config.enableVipGrandstands) {
      // Lewa trybuna VIP
      final standLeftPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: finishDist - 30.0,
        lateralOffsetMeters: -7.5,
        elevationMeters: finishElevation,
        turningRadiusMeters: double.infinity,
        gradientPercent: finishGradient,
      );

      items.add(RoadFurnitureInstance3D(
        id: 'vip_stand_left_${entityCounter++}',
        type: RoadFurnitureType.finishVipGrandstand,
        worldPosition: standLeftPos,
        tangent: Vector3(0.0, finishGradient * 0.01, 1.0)..normalize(),
        lateralRight: Vector3(1.0, 0.0, 0.0),
        surfaceNormal: Vector3(0.0, 1.0, 0.0),
        distanceAlongCourseMeters: finishDist - 30.0,
        lateralOffsetMeters: -7.5,
        elevationMeters: finishElevation,
        customLabel: 'CLUB TOUR DE FRANCE - VIP',
        sponsor: SponsorBrand.lcl,
      ));

      // Prawa trybuna VIP
      final standRightPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: finishDist - 30.0,
        lateralOffsetMeters: 7.5,
        elevationMeters: finishElevation,
        turningRadiusMeters: double.infinity,
        gradientPercent: finishGradient,
      );

      items.add(RoadFurnitureInstance3D(
        id: 'vip_stand_right_${entityCounter++}',
        type: RoadFurnitureType.finishVipGrandstand,
        worldPosition: standRightPos,
        tangent: Vector3(0.0, finishGradient * 0.01, 1.0)..normalize(),
        lateralRight: Vector3(1.0, 0.0, 0.0),
        surfaceNormal: Vector3(0.0, 1.0, 0.0),
        distanceAlongCourseMeters: finishDist - 30.0,
        lateralOffsetMeters: 7.5,
        elevationMeters: finishElevation,
        customLabel: 'OFFICIAL HOSPITALITY',
        sponsor: SponsorBrand.tissot,
      ));
    }

    // D5. Ścianka podium za linią mety (+45m za kreską)
    final podiumPos = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: finishDist + 45.0,
      lateralOffsetMeters: 0.0,
      elevationMeters: finishElevation,
      turningRadiusMeters: double.infinity,
      gradientPercent: finishGradient,
    );

    items.add(RoadFurnitureInstance3D(
      id: 'finish_podium_${entityCounter++}',
      type: RoadFurnitureType.finishPodiumBackdrop,
      worldPosition: podiumPos,
      tangent: Vector3(0.0, finishGradient * 0.01, 1.0)..normalize(),
      lateralRight: Vector3(1.0, 0.0, 0.0),
      surfaceNormal: Vector3(0.0, 1.0, 0.0),
      distanceAlongCourseMeters: finishDist + 45.0,
      lateralOffsetMeters: 0.0,
      elevationMeters: finishElevation,
      customLabel: 'CEREMONIE PROTOCOLAIRE',
      sponsor: SponsorBrand.lcl,
    ));

    // D6. Ciągły korytarz barierek ze sponsorami na ostatnim kilometrze mety
    final double finishBarrierStart =
        math.max(0.0, finishDist - config.finishBarriersLengthMeters);
    final double finishBarrierEnd = finishDist + 150.0;

    _spawnBarrierCorridor(
      items: items,
      activeSegments: activeSegments,
      startDistMeters: finishBarrierStart,
      endDistMeters: finishBarrierEnd,
      sponsorCycle: sponsorCycle,
      idPrefix: 'fin_barr',
    );

    _cachedStageFurniture = items;
    _lastStageId = stage.id;
    return items;
  }

  /// Pomocnik generujący szpaler metalowych barierek po obu stronach szosy.
  void _spawnBarrierCorridor({
    required List<RoadFurnitureInstance3D> items,
    required List<StageSegment> activeSegments,
    required double startDistMeters,
    required double endDistMeters,
    required List<SponsorBrand> sponsorCycle,
    required String idPrefix,
  }) {
    final double step = config.barrierModuleSpacingMeters;
    int index = 0;

    for (double s = startDistMeters; s <= endDistMeters; s += step) {
      final elevation = _calculateElevationAt(s, activeSegments);
      final gradient = _calculateGradientAt(s, activeSegments);
      final sponsor = sponsorCycle[(index ~/ 2) % sponsorCycle.length];

      // Lewa barierka (-4.2m)
      final leftPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: s,
        lateralOffsetMeters: -4.2,
        elevationMeters: elevation,
        turningRadiusMeters: double.infinity,
        gradientPercent: gradient,
      );

      items.add(RoadFurnitureInstance3D(
        id: '${idPrefix}_l_$index',
        type: RoadFurnitureType.crowdBarrierWithBanner,
        worldPosition: leftPos,
        tangent: Vector3(0.0, gradient * 0.01, 1.0)..normalize(),
        lateralRight: Vector3(1.0, 0.0, 0.0),
        surfaceNormal: Vector3(0.0, 1.0, 0.0),
        distanceAlongCourseMeters: s,
        lateralOffsetMeters: -4.2,
        elevationMeters: elevation,
        sponsor: sponsor,
      ));

      // Prawa barierka (+4.2m)
      final rightPos = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: s,
        lateralOffsetMeters: 4.2,
        elevationMeters: elevation,
        turningRadiusMeters: double.infinity,
        gradientPercent: gradient,
      );

      items.add(RoadFurnitureInstance3D(
        id: '${idPrefix}_r_$index',
        type: RoadFurnitureType.crowdBarrierWithBanner,
        worldPosition: rightPos,
        tangent: Vector3(0.0, gradient * 0.01, 1.0)..normalize(),
        lateralRight: Vector3(1.0, 0.0, 0.0),
        surfaceNormal: Vector3(0.0, 1.0, 0.0),
        distanceAlongCourseMeters: s,
        lateralOffsetMeters: 4.2,
        elevationMeters: elevation,
        sponsor: sponsor,
      ));

      index++;
    }
  }

  // ===========================================================================
  // 6. FILTROWANIE OKNA WIDOCZNOŚCI I FRUSTUM CULLING
  // ===========================================================================

  /// Pobiera listę obiektów infrastruktury znajdujących się w oknie widoczności wokół kamery.
  List<RoadFurnitureInstance3D> getFurnitureInWindow({
    required List<RoadFurnitureInstance3D> allFurniture,
    required double cameraDistanceMeters,
    double? customWindowLength,
  }) {
    if (allFurniture.isEmpty) return const [];

    final windowForward = customWindowLength ?? config.forwardVisibilityMeters;
    final minM = cameraDistanceMeters - config.backwardVisibilityMeters;
    final maxM = cameraDistanceMeters + windowForward;

    return allFurniture.where((item) {
      return item.distanceAlongCourseMeters >= minM &&
          item.distanceAlongCourseMeters <= maxM;
    }).toList();
  }

  // ===========================================================================
  // 7. GŁÓWNA METODA RENDEROWANIA INFRASTRUKTURY NA CANVAS
  // ===========================================================================

  /// Renderuje widoczną infrastrukturę przydrożną na obiekcie [Canvas] z sortowaniem głębokości.
  void renderRoadFurniture({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required List<RoadFurnitureInstance3D> instances,
    double elapsedAnimSeconds = 0.0,
    Duration? stageElapsedTime,
  }) {
    if (!config.enabled || instances.isEmpty) return;

    final eyePos = projection.cameraPosition;
    final visibleItems =
        <(RoadFurnitureInstance3D, ProjectedPoint3D, double)>[];

    // Krok 1: Frustum Culling i rzutowanie 3D
    for (final item in instances) {
      final dist = (item.worldPosition - eyePos).length;
      if (dist > config.forwardVisibilityMeters + 60.0) continue;

      final proj = projection.worldToScreen(item.worldPosition);
      if (!proj.isInFrontOfCamera) continue;

      // Margines ekranowy dla szerokich bramownic i trybun VIP
      const double screenMargin = 220.0;
      if (proj.screenX < -screenMargin ||
          proj.screenX > projection.viewportWidth + screenMargin ||
          proj.screenY < -screenMargin ||
          proj.screenY > projection.viewportHeight + screenMargin) {
        continue;
      }

      visibleItems.add((item, proj, dist));
    }

    if (visibleItems.isEmpty) return;

    // Krok 2: Painter's Algorithm - sortowanie od najdalszych do najbliższych
    visibleItems.sort((a, b) => b.$3.compareTo(a.$3));

    // Krok 3: Rysowanie poszczególnych obiektów infrastruktury
    for (final (item, proj, _) in visibleItems) {
      final double scale =
          (proj.perspectiveScale * 14.0 * item.scale).clamp(0.15, 6.5);
      final center = Offset(proj.screenX, proj.screenY);

      switch (item.type) {
        case RoadFurnitureType.crowdBarrierWithBanner:
          _drawCrowdBarrierWithBanner(canvas, center, scale, item);
          break;

        case RoadFurnitureType.distanceCountdownBoard:
          _drawDistanceCountdownBoard(canvas, center, scale, item);
          break;

        case RoadFurnitureType.flammeRougeArch:
          _drawFlammeRougeArch(canvas, center, scale, item, elapsedAnimSeconds);
          break;

        case RoadFurnitureType.intermediateSprintArch:
          _drawIntermediateSprintArch(canvas, center, scale, item);
          break;

        case RoadFurnitureType.komMountainArch:
          _drawKomMountainArch(canvas, center, scale, item);
          break;

        case RoadFurnitureType.finishLineGantry:
          _drawFinishLineGantry(canvas, center, scale, item, stageElapsedTime,
              elapsedAnimSeconds);
          break;

        case RoadFurnitureType.finishCheckeredLine:
          _drawFinishCheckeredLine(canvas, center, scale, item);
          break;

        case RoadFurnitureType.finishPhotoFinishTower:
          _drawPhotoFinishTower(canvas, center, scale, item);
          break;

        case RoadFurnitureType.finishVipGrandstand:
          _drawVipGrandstand(canvas, center, scale, item, elapsedAnimSeconds);
          break;

        case RoadFurnitureType.finishPodiumBackdrop:
          _drawPodiumBackdrop(canvas, center, scale, item);
          break;
      }
    }
  }

  // ===========================================================================
  // 8. RENDERERY GEOMETRII POSZCZEGÓLNYCH ELEMENTÓW
  // ===========================================================================

  /// A. Metalowa barierka ochronna z banerem reklamowym sponsora
  void _drawCrowdBarrierWithBanner(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
  ) {
    final double width = 34.0 * scale;
    final double height = 18.0 * scale;
    final double halfW = width * 0.5;

    // 1. Metalowe nóżki barierki (trójkątne podstawy stabilizujące)
    final footPaint = _barrierFootPaint;
    canvas.drawRect(
        Rect.fromLTWH(
            pos.dx - halfW - 2.0 * scale, pos.dy, 5.0 * scale, 3.0 * scale),
        footPaint);
    canvas.drawRect(
        Rect.fromLTWH(
            pos.dx + halfW - 3.0 * scale, pos.dy, 5.0 * scale, 3.0 * scale),
        footPaint);

    // 2. Stalowa rama barierki
    final framePath = Path()
      ..moveTo(pos.dx - halfW, pos.dy)
      ..lineTo(pos.dx - halfW, pos.dy - height)
      ..lineTo(pos.dx + halfW, pos.dy - height)
      ..lineTo(pos.dx + halfW, pos.dy);
    canvas.drawPath(framePath,
        _barrierMetalPaint..strokeWidth = math.max(1.0, 1.4 * scale));

    // 3. Tkanina banera sponsora napięta wewnątrz ramy
    final bannerRect = Rect.fromLTRB(
      pos.dx - halfW + 1.5 * scale,
      pos.dy - height + 2.0 * scale,
      pos.dx + halfW - 1.5 * scale,
      pos.dy - 1.5 * scale,
    );

    final bannerPaint = Paint()
      ..color = item.sponsor.primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(bannerRect, Radius.circular(2.0 * scale)),
        bannerPaint);

    // 4. Dolny akcent barwny sponsora
    final accentPaint = Paint()
      ..color = item.sponsor.accentColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(bannerRect.left, bannerRect.bottom - 2.5 * scale,
          bannerRect.right, bannerRect.bottom),
      accentPaint,
    );

    // 5. Typografia sponsora na banerze (czytelna przy skali > 0.45)
    if (scale >= 0.45) {
      final namePainter = TextPainter(
        text: TextSpan(
          text: item.sponsor.name,
          style: TextStyle(
            color: item.sponsor.textColor,
            fontSize: (6.5 * scale).clamp(5.0, 11.0),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      namePainter.paint(
        canvas,
        Offset(pos.dx - (namePainter.width * 0.5),
            bannerRect.center.dy - (namePainter.height * 0.5)),
      );
    }
  }

  /// B. Tablica odliczania dystansu (20 km, 10 km, 5 km, 3 km)
  void _drawDistanceCountdownBoard(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
  ) {
    final double postH = 42.0 * scale;
    final double boardW = 38.0 * scale;
    final double boardH = 28.0 * scale;

    // 1. Aluminiowy słup nośny
    canvas.drawLine(
      pos,
      Offset(pos.dx, pos.dy - postH),
      _trussShadowPaint..strokeWidth = 3.5 * scale,
    );
    canvas.drawLine(
      pos,
      Offset(pos.dx, pos.dy - postH),
      _trussMetalPaint..strokeWidth = 2.4 * scale,
    );

    // 2. Tablica ostrzegawcza w kolorystyce granat/złoto
    final boardRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - postH),
      width: boardW,
      height: boardH,
    );

    final rrect =
        RRect.fromRectAndRadius(boardRect, Radius.circular(3.5 * scale));
    canvas.drawRRect(rrect, _countdownNavyPaint);
    canvas.drawRRect(rrect,
        _countdownYellowBorderPaint..strokeWidth = math.max(1.0, 1.8 * scale));

    // 3. Duży napis dystansu (np. "20 KM", "3 KM")
    final textPainter = TextPainter(
      text: TextSpan(
        text: item.customLabel ?? '5 KM',
        style: TextStyle(
          color: const Color(0xFFFFD700),
          fontSize: (11.0 * scale).clamp(7.0, 18.0),
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(boardRect.center.dx - textPainter.width * 0.5,
          boardRect.top + 3.0 * scale),
    );

    // 4. Dolny napis pomocniczy ("UCI" lub "FINISH")
    if (scale >= 0.5) {
      final subPainter = TextPainter(
        text: TextSpan(
          text: (item.customLabel?.contains('3') ?? false)
              ? 'SAFETY'
              : 'TO GO >>',
          style: TextStyle(
            color: Colors.white,
            fontSize: (5.5 * scale).clamp(4.0, 9.0),
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      subPainter.paint(
        canvas,
        Offset(boardRect.center.dx - subPainter.width * 0.5,
            boardRect.bottom - subPainter.height - 2.5 * scale),
      );
    }
  }

  /// C. Dmuchana czerwona brama Flamme Rouge (1 km)
  void _drawFlammeRougeArch(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
    double animSeconds,
  ) {
    final double archW = 100.0 * scale;
    final double archH = 65.0 * scale;
    final double tubeThick = 12.0 * scale;

    final double leftX = pos.dx - (archW * 0.5);
    final double rightX = pos.dx + (archW * 0.5);
    final double topY = pos.dy - archH;

    // 1. Podstawy dmuchawy i agregaty prądotwórcze po obu stronach drogi
    final boxW = 14.0 * scale;
    final boxH = 9.0 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(leftX - boxW * 0.5, pos.dy - boxH, boxW, boxH),
          Radius.circular(2.0 * scale)),
      _blowerBoxPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(rightX - boxW * 0.5, pos.dy - boxH, boxW, boxH),
          Radius.circular(2.0 * scale)),
      _blowerBoxPaint,
    );

    // 2. Łuk dmuchany Flamme Rouge (płynny łuk Beziera ze zmienną grubością tuby)
    final archPath = Path()
      ..moveTo(leftX, pos.dy)
      ..lineTo(leftX, topY + tubeThick)
      ..cubicTo(leftX, topY, rightX, topY, rightX, topY + tubeThick)
      ..lineTo(rightX, pos.dy)
      ..lineTo(rightX - tubeThick, pos.dy)
      ..lineTo(rightX - tubeThick, topY + tubeThick * 1.5)
      ..cubicTo(rightX - tubeThick, topY + tubeThick, leftX + tubeThick,
          topY + tubeThick, leftX + tubeThick, topY + tubeThick * 1.5)
      ..lineTo(leftX + tubeThick, pos.dy)
      ..close();

    canvas.drawPath(archPath, _flammeRougeArchPaint);
    canvas.drawPath(archPath,
        _flammeRougeGlowPaint..strokeWidth = math.max(1.0, 1.2 * scale));

    // 3. Słynny czerwony trójkątny proporzec "Flamme Rouge" wiszący pośrodku łuku
    final double sway = math.sin(animSeconds * 3.5) * (1.2 * scale);
    final double pennantTopY = topY + tubeThick * 1.2;
    final double pennantH = 22.0 * scale;
    final double pennantHalfW = 9.0 * scale;

    final pennantPath = Path()
      ..moveTo(pos.dx - pennantHalfW, pennantTopY)
      ..lineTo(pos.dx + pennantHalfW, pennantTopY)
      ..lineTo(pos.dx + sway, pennantTopY + pennantH)
      ..close();

    canvas.drawPath(pennantPath, _flammeRougePennantPaint);

    // 4. Biały napis "1 KM" na proporcu
    if (scale >= 0.4) {
      final kmPainter = TextPainter(
        text: TextSpan(
          text: '1 KM',
          style: TextStyle(
            color: Colors.white,
            fontSize: (7.5 * scale).clamp(5.0, 12.0),
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      kmPainter.paint(
        canvas,
        Offset(pos.dx - kmPainter.width * 0.5, pennantTopY + 3.0 * scale),
      );
    }
  }

  /// D. Zielona brama lotnej premii sprinterskiej (Intermediate Sprint)
  void _drawIntermediateSprintArch(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
  ) {
    final double archW = 94.0 * scale;
    final double archH = 58.0 * scale;
    final double halfW = archW * 0.5;

    // 1. Zielone pylony konstrukcyjne
    final pylonW = 8.0 * scale;
    canvas.drawRect(
        Rect.fromLTWH(pos.dx - halfW, pos.dy - archH, pylonW, archH),
        _greenSprintArchPaint);
    canvas.drawRect(
        Rect.fromLTWH(pos.dx + halfW - pylonW, pos.dy - archH, pylonW, archH),
        _greenSprintArchPaint);

    // 2. Belka poprzeczna z zieloną tablicą
    final crossBeamRect =
        Rect.fromLTWH(pos.dx - halfW, pos.dy - archH, archW, 14.0 * scale);
    canvas.drawRect(crossBeamRect, _greenSprintArchPaint);

    // 3. Szmaragdowy napis "SPRINT INTERMÉDIAIRE"
    if (scale >= 0.35) {
      final titlePainter = TextPainter(
        text: TextSpan(
          text: item.customLabel ?? 'SPRINT',
          style: TextStyle(
            color: Colors.white,
            fontSize: (7.0 * scale).clamp(5.0, 11.0),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      titlePainter.paint(
        canvas,
        Offset(pos.dx - titlePainter.width * 0.5,
            crossBeamRect.center.dy - titlePainter.height * 0.5),
      );
    }

    // 4. Zielona linia premii na nawierzchni asfaltu
    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromCenter(center: pos, width: archW * 0.85, height: 3.5 * scale),
        linePaint);
  }

  /// E. Brama premii górskiej KOM w czerwone grochy (Górski Szczyt)
  void _drawKomMountainArch(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
  ) {
    final double archW = 94.0 * scale;
    final double archH = 60.0 * scale;
    final double halfW = archW * 0.5;

    // 1. Biała konstrukcja bramy
    final beamH = 15.0 * scale;
    final crossRect =
        Rect.fromLTWH(pos.dx - halfW, pos.dy - archH, archW, beamH);
    canvas.drawRect(crossRect, _polkaWhiteArchPaint);

    // 2. Proceduralne czerwone grochy na belce
    final dotR = 2.2 * scale;
    final dotCount = (archW / (dotR * 3.8)).floor();
    for (int i = 0; i < dotCount; i++) {
      final dx = (pos.dx - halfW) + (i * dotR * 3.8) + (dotR * 2.0);
      canvas.drawCircle(
          Offset(dx, crossRect.top + dotR * 1.5), dotR, _polkaDotRedPaint);
      canvas.drawCircle(Offset(dx + dotR * 1.8, crossRect.bottom - dotR * 1.5),
          dotR, _polkaDotRedPaint);
    }

    // Pylony pionowe z grochami
    final pylonW = 8.0 * scale;
    canvas.drawRect(
        Rect.fromLTWH(pos.dx - halfW, pos.dy - archH, pylonW, archH),
        _polkaWhiteArchPaint);
    canvas.drawRect(
        Rect.fromLTWH(pos.dx + halfW - pylonW, pos.dy - archH, pylonW, archH),
        _polkaWhiteArchPaint);

    // 3. Etykieta kategorii premii (np. "COL DU TOURMALET - HC")
    if (scale >= 0.38) {
      final komPainter = TextPainter(
        text: TextSpan(
          text: item.customLabel ?? 'GPM KOM',
          style: TextStyle(
            color: const Color(0xFFEF4444),
            fontSize: (6.5 * scale).clamp(4.5, 10.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      komPainter.paint(
        canvas,
        Offset(pos.dx - komPainter.width * 0.5,
            crossRect.center.dy - komPainter.height * 0.5),
      );
    }

    // 4. Linia premii górskiej na asfalcie
    canvas.drawRect(
        Rect.fromCenter(center: pos, width: archW * 0.85, height: 3.5 * scale),
        _polkaDotRedPaint);
  }

  /// F. Główna brama mety z zegarem LED i fotokomórką (Finish Line Gantry)
  void _drawFinishLineGantry(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
    Duration? stageElapsedTime,
    double animSeconds,
  ) {
    final double archW = 118.0 * scale;
    final double archH = 76.0 * scale;
    final double halfW = archW * 0.5;

    // 1. Aluminiowa konstrukcja kratownicowa (Truss Structure)
    final pylonW = 10.0 * scale;
    final leftX = pos.dx - halfW;
    final rightX = pos.dx + halfW;
    final topY = pos.dy - archH;

    // Pylony boczne
    canvas.drawRect(
        Rect.fromLTWH(leftX, topY, pylonW, archH), _trussShadowPaint);
    canvas.drawRect(
        Rect.fromLTWH(rightX - pylonW, topY, pylonW, archH), _trussShadowPaint);
    canvas.drawRect(
        Rect.fromLTWH(leftX, topY, pylonW, archH), _trussMetalPaint);
    canvas.drawRect(
        Rect.fromLTWH(rightX - pylonW, topY, pylonW, archH), _trussMetalPaint);

    // Przekątne kratownicy
    for (double y = topY; y < pos.dy - 10.0 * scale; y += 14.0 * scale) {
      canvas.drawLine(Offset(leftX, y),
          Offset(leftX + pylonW, y + 14.0 * scale), _trussHighlightPaint);
      canvas.drawLine(Offset(rightX - pylonW, y),
          Offset(rightX, y + 14.0 * scale), _trussHighlightPaint);
    }

    // 2. Główna belka poprzeczna bramy
    final beamH = 22.0 * scale;
    final beamRect = Rect.fromLTWH(leftX, topY, archW, beamH);
    canvas.drawRect(beamRect, _gantryLedPanelPaint);
    canvas.drawRect(beamRect, _gantryGoldBorderPaint);

    // 3. Centralny szyld "ARRIVÉE / FINISH"
    final finishTitlePainter = TextPainter(
      text: const TextSpan(
        text: 'ARRIVÉE',
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 10.0,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    finishTitlePainter.paint(
      canvas,
      Offset(pos.dx - finishTitlePainter.width * 0.5, topY + 2.5 * scale),
    );

    // 4. Cyfrowy zegar LED czasu etapu (np. "04:18:32")
    final elapsedText = _formatElapsedTime(stageElapsedTime, animSeconds);
    final clockPainter = TextPainter(
      text: TextSpan(
        text: elapsedText,
        style: TextStyle(
          color: const Color(0xFFF97316),
          fontSize: (9.5 * scale).clamp(6.0, 14.0),
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    clockPainter.paint(
      canvas,
      Offset(pos.dx - clockPainter.width * 0.5,
          topY + beamH - clockPainter.height - 2.5 * scale),
    );

    // 5. Fotokomórka Tissot podwieszona pod środkiem belki
    final photoBoxW = 12.0 * scale;
    final photoBoxH = 6.0 * scale;
    final photoRect = Rect.fromCenter(
      center: Offset(pos.dx, topY + beamH + photoBoxH * 0.5),
      width: photoBoxW,
      height: photoBoxH,
    );
    canvas.drawRect(photoRect, _photoFinishLensPaint);
    canvas.drawCircle(
        photoRect.center, 1.8 * scale, Paint()..color = Colors.white);
  }

  /// G. Szachownica linii mety namalowana na asfalcie
  void _drawFinishCheckeredLine(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
  ) {
    final double lineWidth = 80.0 * scale;
    final double lineDepth = 5.5 * scale;
    final double squareSize = 5.0 * scale;

    final left = pos.dx - (lineWidth * 0.5);
    final countX = (lineWidth / squareSize).floor();

    // Dwa rzędy naprzemiennych kwadratów czarno-białej szachownicy
    for (int col = 0; col < countX; col++) {
      final x = left + (col * squareSize);
      // Rząd 1
      canvas.drawRect(
        Rect.fromLTWH(x, pos.dy - lineDepth, squareSize, lineDepth * 0.5),
        col % 2 == 0 ? _finishCheckeredBlackPaint : _finishCheckeredWhitePaint,
      );
      // Rząd 2
      canvas.drawRect(
        Rect.fromLTWH(x, pos.dy - lineDepth * 0.5, squareSize, lineDepth * 0.5),
        col % 2 == 1 ? _finishCheckeredBlackPaint : _finishCheckeredWhitePaint,
      );
    }

    // Żółty gumowy ochraniacz kabla fotokomórki i transpondera
    canvas.drawRect(
      Rect.fromLTWH(left, pos.dy, lineWidth, 1.6 * scale),
      _cableProtectorYellowPaint,
    );
  }

  /// H. Wieża fotokomórki (Photo-Finish Tower)
  void _drawPhotoFinishTower(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
  ) {
    final double towerW = 16.0 * scale;
    final double towerH = 50.0 * scale;

    final towerRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - towerH * 0.5),
      width: towerW,
      height: towerH,
    );

    // Kratownica wieży
    canvas.drawRect(towerRect, _trussShadowPaint);
    canvas.drawRect(towerRect, _trussMetalPaint);

    // Kabina operatora fotokomórki na szczycie wieży
    final cabinRect = Rect.fromLTWH(
        pos.dx - towerW * 0.6, pos.dy - towerH, towerW * 1.2, 14.0 * scale);
    canvas.drawRect(cabinRect, Paint()..color = const Color(0xFFDC2626));

    // Obiektyw kamery skierowany na kreskę
    canvas.drawCircle(
      Offset(
          pos.dx +
              (item.lateralOffsetMeters > 0 ? -towerW * 0.5 : towerW * 0.5),
          pos.dy - towerH + 7.0 * scale),
      2.5 * scale,
      _photoFinishLensPaint,
    );
  }

  /// I. Zadaszona trybuna VIP ze szpalerem siedzeń
  void _drawVipGrandstand(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
    double animSeconds,
  ) {
    final double standW = 80.0 * scale;
    final double standH = 48.0 * scale;

    final standRect =
        Rect.fromLTWH(pos.dx - standW * 0.5, pos.dy - standH, standW, standH);

    // 1. Zadaszenie z tkaniny (Awning Canopy)
    final canopyRect = Rect.fromLTWH(
        standRect.left, standRect.top - 6.0 * scale, standW, 10.0 * scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(canopyRect, Radius.circular(3.0 * scale)),
        _vipRoofCanopyPaint);

    // 2. Poziomy schodkowe trybuny (3 piętra)
    for (int tier = 0; tier < 3; tier++) {
      final tierY = standRect.top + 8.0 * scale + (tier * 11.0 * scale);
      final plankRect = Rect.fromLTWH(standRect.left + (tier * 3.0 * scale),
          tierY, standW - (tier * 6.0 * scale), 7.0 * scale);
      canvas.drawRect(plankRect, _vipStandPlankPaint);

      // Proceduralni goście VIP w rzędzie
      const guestColors = [
        Color(0xFFE2E8F0),
        Color(0xFF38BDF8),
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
      ];
      const guestCount = 6;
      for (int g = 0; g < guestCount; g++) {
        final gx = plankRect.left + 5.0 * scale + (g * 11.5 * scale);
        final gy = tierY - 3.5 * scale;
        canvas.drawCircle(Offset(gx, gy), 2.2 * scale,
            Paint()..color = guestColors[(g + tier) % guestColors.length]);
      }
    }

    // 3. Frontowy baner hospitality ("CLUB VIP")
    final bannerRect = Rect.fromLTWH(
        standRect.left, standRect.bottom - 10.0 * scale, standW, 10.0 * scale);
    canvas.drawRect(bannerRect, Paint()..color = const Color(0xFF0F172A));

    if (scale >= 0.4) {
      final vipPainter = TextPainter(
        text: TextSpan(
          text: item.customLabel ?? 'VIP HOSPITALITY',
          style: TextStyle(
            color: const Color(0xFFFFD700),
            fontSize: (5.5 * scale).clamp(4.0, 9.0),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      vipPainter.paint(
        canvas,
        Offset(pos.dx - vipPainter.width * 0.5,
            bannerRect.center.dy - vipPainter.height * 0.5),
      );
    }
  }

  /// J. Ścianka dekoracji podium za metą
  void _drawPodiumBackdrop(
    Canvas canvas,
    Offset pos,
    double scale,
    RoadFurnitureInstance3D item,
  ) {
    final double backdropW = 60.0 * scale;
    final double backdropH = 34.0 * scale;

    final wallRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - backdropH * 0.5),
      width: backdropW,
      height: backdropH,
    );

    // Ścianka sponsorska
    canvas.drawRRect(
        RRect.fromRectAndRadius(wallRect, Radius.circular(3.0 * scale)),
        Paint()..color = const Color(0xFF0C101A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(wallRect, Radius.circular(3.0 * scale)),
        _gantryGoldBorderPaint);

    // Stopnie podium (1st, 2nd, 3rd)
    final stepH = 5.0 * scale;
    final stepW = 12.0 * scale;
    // 2nd
    canvas.drawRect(
        Rect.fromLTWH(
            pos.dx - stepW * 1.5, pos.dy - stepH * 1.5, stepW, stepH * 1.5),
        _trussShadowPaint);
    // 1st (najwyższy)
    canvas.drawRect(
        Rect.fromLTWH(
            pos.dx - stepW * 0.5, pos.dy - stepH * 2.2, stepW, stepH * 2.2),
        _gantryGoldBorderPaint);
    // 3rd
    canvas.drawRect(
        Rect.fromLTWH(pos.dx + stepW * 0.5, pos.dy - stepH, stepW, stepH),
        _trussShadowPaint);

    if (scale >= 0.4) {
      final pPainter = TextPainter(
        text: const TextSpan(
          text: 'PODIUM',
          style: TextStyle(
              color: Colors.white,
              fontSize: 7.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      pPainter.paint(canvas,
          Offset(pos.dx - pPainter.width * 0.5, wallRect.top + 4.0 * scale));
    }
  }

  // ===========================================================================
  // 9. METODY POMOCNICZE FORMOWANIA ETYKIET I TELEMETRII
  // ===========================================================================

  String _formatKomLabel(
      SegmentClassification classification, double elevationMeters) {
    final altText = 'ALT. ${elevationMeters.round()}M';
    switch (classification) {
      case SegmentClassification.cat4:
        return 'CÔTE 4e CAT ($altText)';
      case SegmentClassification.cat3:
        return 'COL 3e CAT ($altText)';
      case SegmentClassification.cat2:
        return 'COL 2e CAT ($altText)';
      case SegmentClassification.cat1:
        return 'COL 1re CAT ($altText)';
      case SegmentClassification.horsCategorie:
        return 'HORS CATÉGORIE - HC ($altText)';
      default:
        return 'GPM ($altText)';
    }
  }

  String _formatElapsedTime(Duration? stageElapsedTime, double animSeconds) {
    if (stageElapsedTime != null) {
      final h = stageElapsedTime.inHours.toString().padLeft(2, '0');
      final m = (stageElapsedTime.inMinutes % 60).toString().padLeft(2, '0');
      final s = (stageElapsedTime.inSeconds % 60).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }

    final totalSec = (14400.0 + animSeconds).floor();
    final h = (totalSec ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double _calculateElevationAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 450.0;
    final km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        final len = math.max(0.001, seg.endKm - seg.startKm);
        final t = ((km - seg.startKm) / len).clamp(0.0, 1.0);
        return seg.startElevationM +
            (seg.endElevationM - seg.startElevationM) * t;
      }
    }
    return segments.last.endElevationM;
  }

  double _calculateGradientAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 3.5;
    final km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg.gradientPercent;
      }
    }
    return segments.last.gradientPercent;
  }
}
