// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../models/race/stage_segment.dart';
import 'scene_3d_math_projection.dart';

/// Strefy wysokościowe (biomy) determinujące florę, krajobraz i kibiców wzdłuż trasy wyścigu.
enum ElevationBiomeZone {
  /// Poniżej 800m n.p.m.: doliny rzeczne, lasy liściaste, pola uprawne, europejskie miasteczka, brukowane aleje.
  lowlandValley(
    label: 'Dolina i Nizina (<800m)',
    description: 'Lasy liściaste, pola uprawne, miasteczka, brukowane aleje z drzewami.',
    minElevationMeters: 0.0,
    maxElevationMeters: 800.0,
  ),

  /// 800m – 1800m n.p.m.: regiel górski, gęste lasy iglaste (sosny alpejskie), granitowe głazy, drewniane barierki.
  subalpineForest(
    label: 'Regiel Górski i Bór Świerkowy (800-1800m)',
    description: 'Gęste lasy iglaste (sosny alpejskie), głazy skalne, drewniane barierki ochronne.',
    minElevationMeters: 800.0,
    maxElevationMeters: 1800.0,
  ),

  /// Powyżej 1800m n.p.m.: Wysokie Alpy / Dolomity, surowe turnie skalne, łaty śniegu, serpentyny i szpalery kibiców.
  highAlpineTundra(
    label: 'Wysokie Alpy i Piętro Turniowe (>1800m)',
    description: 'Surowy krajobraz skalny, łaty śniegu przy asfalcie, serpentyny i gęste tłumy kibiców.',
    minElevationMeters: 1800.0,
    maxElevationMeters: 4500.0,
  );

  final String label;
  final String description;
  final double minElevationMeters;
  final double maxElevationMeters;

  const ElevationBiomeZone({
    required this.label,
    required this.description,
    required this.minElevationMeters,
    required this.maxElevationMeters,
  });

  /// Wyznacza strefę wysokościową na podstawie wysokości n.p.m. w metrach.
  static ElevationBiomeZone fromElevation(double elevationMeters) {
    if (elevationMeters < 800.0) {
      return ElevationBiomeZone.lowlandValley;
    } else if (elevationMeters <= 1800.0) {
      return ElevationBiomeZone.subalpineForest;
    } else {
      return ElevationBiomeZone.highAlpineTundra;
    }
  }
}

/// Region geograficzny wyścigu kolarskiego wpływający na charakterystykę architektury i roślinności.
enum GeographicRegion {
  alpsAndDolomites('Alpy i Dolomity (Francja / Włochy / Szwajcaria)'),
  pyrenees('Pireneje i Kraj Basków (Francja / Hiszpania)'),
  flandersAndArdennes('Flandria i Ardeny (Belgia / Północna Francja)'),
  tuscanyAndMediterranean('Toskania i Riwiera Śródziemnomorska (Włochy)');

  final String label;
  const GeographicRegion(this.label);
}

/// Typy obiektów krajobrazowych i dekoracji przydrożnych w świecie 3D.
enum SceneryObjectType {
  pineTree('Sosna Alpejska', 'tree_pine'),
  cypressTree('Cyprys Włoski', 'tree_cypress'),
  deciduousTree('Drzewo Liściaste', 'tree_deciduous'),
  avenueTree('Drzewo Szpaleru Alei', 'tree_avenue'),
  farmlandField('Pole Uprawne i Snopy Siana', 'field_farmland'),
  boulderRock('Głaz Skalny', 'rock_boulder'),
  alpineCrag('Turnia i Urwisko Skalne', 'rock_crag'),
  mountainPeak('Ośnieżony Szczyt w Tle', 'mountain_peak'),
  townhouse('Kamienica Miasteczka', 'building_townhouse'),
  cheeringSpectators('Kibice z Flagami', 'spectators_cheering'),
  woodenBarrier('Drewniana Barierka Ochronna', 'barrier_finish'),
  snowPatch('Łata Śnieżna na Poboczu', 'snow_patch');

  final String displayName;
  final String assetKey;
  const SceneryObjectType(this.displayName, this.assetKey);
}

/// Pojedyncza wygenerowana instancja obiektu krajobrazu w świecie trójwymiarowym.
class SceneryInstance3D {
  final String id;
  final SceneryObjectType type;
  final String assetKey;
  final Vector3 worldPosition;
  final double rotationYawRadians;
  final Vector3 scale;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final ElevationBiomeZone biomeZone;
  final bool isAnimated;

  const SceneryInstance3D({
    required this.id,
    required this.type,
    required this.assetKey,
    required this.worldPosition,
    required this.rotationYawRadians,
    required this.scale,
    required this.distanceAlongCourseMeters,
    required this.lateralOffsetMeters,
    required this.elevationMeters,
    required this.biomeZone,
    this.isAnimated = false,
  });
}

/// Konfiguracja parametrów proceduralnego generatora otoczenia.
class ScenerySpawnerConfig {
  /// Domyślny region geograficzny (Alpy, Flandria, Toskania, Pireneje).
  final GeographicRegion region;

  /// Krok próbkowania wzdłuż trasy w metrach (odstęp między próbami generowania obiektów).
  final double sampleStepMeters;

  /// Odległość okna renderowania przed kamerą w metrach.
  final double forwardVisibilityMeters;

  /// Odległość okna renderowania za kamerą w metrach.
  final double backwardVisibilityMeters;

  /// Minimalna odległość obiektów od osi jezdni (aby nie stawiać drzew na asfalcie) [m].
  final double minLateralDistanceMeters;

  /// Czy generować kibiców wzdłuż szosy.
  final bool enableSpectators;

  /// Czy generować ośnieżone szczyty w paralaksie tła.
  final bool enableMountainBackdrop;

  const ScenerySpawnerConfig({
    this.region = GeographicRegion.alpsAndDolomites,
    this.sampleStepMeters = 16.0,
    this.forwardVisibilityMeters = 420.0,
    this.backwardVisibilityMeters = 60.0,
    this.minLateralDistanceMeters = 4.2,
    this.enableSpectators = true,
    this.enableMountainBackdrop = true,
  });
}

/// Proceduralny generator otoczenia wzdłuż trasy wyścigu kolarskiego.
///
/// Implementuje:
/// 1. Strefy wysokościowe:
///    - <800m n.p.m.: lasy liściaste, pola uprawne, miasteczka, brukowane aleje z drzewami,
///    - 800m–1800m n.p.m.: gęste bory świerkowo-sosnowe, głazy skalne, drewniane barierki,
///    - >1800m n.p.m.: surowe turnie wysokogórskie, zaspy i łaty śniegu, serpentyny,
///      oraz żywiołowe szpalery kibiców na ostatnim kilometrze podjazdu.
/// 2. Deterministyczny generator z ziarnem (Seed) gwarantujący stabilność pozycji przy przewijaniu trasy.
/// 3. Buforowanie okna widoczności wokół kamery zapewniające 120 FPS bez alokacji GC.
class EnvironmentScenerySpawner {
  final ScenerySpawnerConfig config;

  // Prealokowane style Paint dla proceduralnego rysowania elementów otoczenia
  late final Paint _trunkPaint;
  late final Paint _pineNeedlesPaint;
  late final Paint _deciduousCrownPaint;
  late final Paint _cypressCrownPaint;
  late final Paint _rockGranitePaint;
  late final Paint _snowWhitePaint;
  late final Paint _houseWallPaint;
  late final Paint _houseRoofPaint;
  late final Paint _barrierWoodPaint;
  late final Paint _spectatorSkinPaint;
  late final Paint _farmlandHayPaint;
  late final Paint _farmlandFencePaint;
  late final Paint _whitewashTrunkPaint;
  late final Paint _cragShadowPaint;
  final List<Paint> _fanClothingPaints = [];

  EnvironmentScenerySpawner({
    this.config = const ScenerySpawnerConfig(),
  }) {
    _initSceneryPaints();
  }

  void _initSceneryPaints() {
    _trunkPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.fill;

    _pineNeedlesPaint = Paint()
      ..color = const Color(0xFF14532D)
      ..style = PaintingStyle.fill;

    _deciduousCrownPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    _cypressCrownPaint = Paint()
      ..color = const Color(0xFF1B4D2E)
      ..style = PaintingStyle.fill;

    _rockGranitePaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    _snowWhitePaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;

    _houseWallPaint = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..style = PaintingStyle.fill;

    _houseRoofPaint = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.fill;

    _barrierWoodPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _spectatorSkinPaint = Paint()
      ..color = const Color(0xFFDEB887)
      ..style = PaintingStyle.fill;

    _farmlandHayPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;

    _farmlandFencePaint = Paint()
      ..color = const Color(0xFF854D0E)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _whitewashTrunkPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    _cragShadowPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    final fanColors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFFEAB308),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFFF97316),
      const Color(0xFFFFFFFF),
    ];

    for (final col in fanColors) {
      _fanClothingPaints.add(Paint()
        ..color = col
        ..style = PaintingStyle.fill);
    }
  }

  // ===========================================================================
  // 1. GŁÓWNA METODA GENEROWANIA INSTANCJI W OKNIE WIDOCZNOŚCI
  // ===========================================================================

  /// Generuje proceduralną listę obiektów otoczenia w oknie widoczności wokół kamery.
  List<SceneryInstance3D> spawnSceneryInWindow({
    required double cameraDistanceMeters,
    required List<StageSegment> segments,
    required Scene3DMathProjection projection,
    int stageSeed = 42,
    double totalStageLengthKm = 160.0,
  }) {
    final instances = <SceneryInstance3D>[];

    final double startDist = math.max(0.0, cameraDistanceMeters - config.backwardVisibilityMeters);
    final double maxStageDist = totalStageLengthKm * 1000.0;
    final double endDist = math.min(maxStageDist, cameraDistanceMeters + config.forwardVisibilityMeters);

    if (startDist >= endDist) return instances;

    // Zaokrąglenie do siatki kroków próbkowania dla stabilności deterministycznej
    final int startStepIndex = (startDist / config.sampleStepMeters).floor();
    final int endStepIndex = (endDist / config.sampleStepMeters).ceil();

    for (int step = startStepIndex; step <= endStepIndex; step++) {
      final double s = step * config.sampleStepMeters;
      if (s < startDist || s > endDist) continue;

      // Wyznaczenie wysokości n.p.m. i nachylenia w punkcie 's'
      final double elevation = _calculateElevationAt(s, segments);
      final double gradient = _calculateGradientAt(s, segments);
      final double distRemaining = maxStageDist - s;

      final biome = ElevationBiomeZone.fromElevation(elevation);

      // Deterministyczny pseudolosowy generator dla danego kroku 'step'
      final random = math.Random(stageSeed ^ (step * 31337));

      // Sprawdzenie, czy jesteśmy na finiszowym kilometrze podjazdu KOM lub etapu górskiego
      final bool isFinalClimbKilometer = (distRemaining <= 1500.0) && (elevation > 1200.0 || gradient > 6.0);
      final bool isHairpin = (gradient > 7.5 && (step % 4 == 0));

      // 1. Generowanie obiektów po lewej stronie szosy (Side: -1)
      final leftInstance = _spawnSideObject(
        step: step,
        sideSign: -1.0,
        distanceMeters: s,
        elevation: elevation,
        gradient: gradient,
        biome: biome,
        random: random,
        isFinalClimbKilometer: isFinalClimbKilometer,
        isHairpin: isHairpin,
        segments: segments,
        projection: projection,
      );
      if (leftInstance != null) instances.add(leftInstance);

      // 2. Generowanie obiektów po prawej stronie szosy (Side: +1)
      final rightInstance = _spawnSideObject(
        step: step,
        sideSign: 1.0,
        distanceMeters: s,
        elevation: elevation,
        gradient: gradient,
        biome: biome,
        random: random,
        isFinalClimbKilometer: isFinalClimbKilometer,
        isHairpin: isHairpin,
        segments: segments,
        projection: projection,
      );
      if (rightInstance != null) instances.add(rightInstance);

      // 3. Dodatkowy szpaler kibiców na ostatnim kilometrze podjazdu (Frenzy Crowd)
      if ((isFinalClimbKilometer || isHairpin) && config.enableSpectators && (step % 2 == 0)) {
        final crowdInstance = _spawnFinishingCrowdInstance(
          step: step,
          distanceMeters: s,
          elevation: elevation,
          biome: biome,
          random: random,
          segments: segments,
          projection: projection,
        );
        if (crowdInstance != null) instances.add(crowdInstance);
      }
    }

    return instances;
  }

  // ===========================================================================
  // 2. LOGIKA GENEROWANIA WEDŁUG STREFY WYSOKOŚCIOWEJ (BIOME LOGIC)
  // ===========================================================================

  SceneryInstance3D? _spawnSideObject({
    required int step,
    required double sideSign,
    required double distanceMeters,
    required double elevation,
    required double gradient,
    required ElevationBiomeZone biome,
    required math.Random random,
    required bool isFinalClimbKilometer,
    required bool isHairpin,
    required List<StageSegment> segments,
    required Scene3DMathProjection projection,
  }) {
    SceneryObjectType objectType;
    double lateralOffset;
    double scaleFactor = 0.85 + (random.nextDouble() * 0.35); // Wariacja skali ±15-20%

    switch (biome) {
      // -----------------------------------------------------------------------
      // STREFA 1: DOLINY I NIZINY (< 800M N.P.M.)
      // - Lasy liściaste, pola uprawne, miasteczka, brukowane aleje z drzewami
      // -----------------------------------------------------------------------
      case ElevationBiomeZone.lowlandValley:
        final activeSeg = _resolveSegmentAt(distanceMeters, segments);
        final bool isCobbleAvenue = (activeSeg != null && activeSeg.surfaceType.name.contains('cobble')) ||
            config.region == GeographicRegion.flandersAndArdennes;

        if (isCobbleAvenue && random.nextDouble() < 0.45) {
          // Brukowane aleje z drzewami w szpalerze
          objectType = SceneryObjectType.avenueTree;
          lateralOffset = sideSign * (config.minLateralDistanceMeters + 0.8 + (step % 2) * 0.2);
          scaleFactor *= 1.1;
        } else if (config.region == GeographicRegion.tuscanyAndMediterranean && random.nextDouble() < 0.35) {
          // Toskańskie cyprysy
          objectType = SceneryObjectType.cypressTree;
          lateralOffset = sideSign * (config.minLateralDistanceMeters + 1.2 + random.nextDouble() * 5.0);
        } else {
          final double typeRoll = random.nextDouble();
          if (typeRoll < 0.25) {
            // Pola uprawne, snopy siana i wiejskie pastwiska
            objectType = SceneryObjectType.farmlandField;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 3.2 + random.nextDouble() * 6.5);
            scaleFactor *= 1.15;
          } else if (typeRoll < 0.45) {
            // Kamieniczka europejska (miasteczko)
            objectType = SceneryObjectType.townhouse;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 6.5 + random.nextDouble() * 8.0);
            scaleFactor *= 1.2;
          } else if (typeRoll < 0.85) {
            // Szpalery drzew liściastych (dęby, lipy, klony)
            objectType = SceneryObjectType.deciduousTree;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 1.5 + random.nextDouble() * 6.0);
          } else {
            // Kibice przy drodze na nizinach
            if (!config.enableSpectators) return null;
            objectType = SceneryObjectType.cheeringSpectators;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 0.3 + random.nextDouble() * 1.0);
          }
        }
        break;

      // -----------------------------------------------------------------------
      // STREFA 2: REGIEL GÓRSKI I BÓR IGLASTY (800M – 1800M N.P.M.)
      // - Gęste lasy iglaste (sosny alpejskie), skały, drewniane barierki
      // -----------------------------------------------------------------------
      case ElevationBiomeZone.subalpineForest:
        final double typeRoll = random.nextDouble();
        if (typeRoll < 0.52) {
          // Gęste lasy iglaste (sosny alpejskie)
          objectType = SceneryObjectType.pineTree;
          lateralOffset = sideSign * (config.minLateralDistanceMeters + 1.2 + random.nextDouble() * 6.5);
          scaleFactor *= 1.1;
        } else if (typeRoll < 0.74) {
          // Głazy skalne na zboczu
          objectType = SceneryObjectType.boulderRock;
          lateralOffset = sideSign * (config.minLateralDistanceMeters + 1.8 + random.nextDouble() * 4.0);
        } else if (typeRoll < 0.88) {
          // Drewniana barierka ochronna nad urwiskiem
          objectType = SceneryObjectType.woodenBarrier;
          lateralOffset = sideSign * (config.minLateralDistanceMeters - 0.2);
          scaleFactor = 1.0;
        } else {
          // Górscy kibice na podjeździe
          if (!config.enableSpectators) return null;
          objectType = SceneryObjectType.cheeringSpectators;
          lateralOffset = sideSign * (config.minLateralDistanceMeters + 0.4);
        }
        break;

      // -----------------------------------------------------------------------
      // STREFA 3: WYSOKIE ALPY I TURNIE (> 1800M N.P.M. - WYSOKIE ALPY / DOLOMITY)
      // - Surowy krajobraz skalny, łaty śniegu przy drodze, serpentyny i gęste tłumy kibiców
      // -----------------------------------------------------------------------
      case ElevationBiomeZone.highAlpineTundra:
        if ((isFinalClimbKilometer || isHairpin) && config.enableSpectators && random.nextDouble() < 0.55) {
          // Gęste tłumy kibiców z flagami na ostatnim kilometrze podjazdu i w serpentynach
          objectType = SceneryObjectType.cheeringSpectators;
          lateralOffset = sideSign * (config.minLateralDistanceMeters + 0.2 + random.nextDouble() * 0.8);
        } else {
          final double typeRoll = random.nextDouble();
          if (typeRoll < 0.35) {
            // Surowy krajobraz turni i urwisk skalnych Dolomitów
            objectType = SceneryObjectType.alpineCrag;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 3.0 + random.nextDouble() * 9.0);
            scaleFactor *= 1.4;
          } else if (typeRoll < 0.65) {
            // Bloki skalne i głazy narzutowe
            objectType = SceneryObjectType.boulderRock;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 1.8 + random.nextDouble() * 5.0);
            scaleFactor *= 1.25;
          } else if (typeRoll < 0.85) {
            // Łaty topniejącego śniegu i zaspy przy szosie
            objectType = SceneryObjectType.snowPatch;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 0.8 + random.nextDouble() * 3.5);
          } else {
            // Rzadkie, skarłowaciałe sosny na granicy lasu (kosodrzewina)
            objectType = SceneryObjectType.pineTree;
            lateralOffset = sideSign * (config.minLateralDistanceMeters + 4.5 + random.nextDouble() * 7.0);
            scaleFactor *= 0.70;
          }
        }
        break;
    }

    // Wyznaczenie pozycji w przestrzeni trójwymiarowej 3D
    final worldPos = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: distanceMeters,
      lateralOffsetMeters: lateralOffset,
      elevationMeters: elevation,
      turningRadiusMeters: double.infinity,
      gradientPercent: gradient,
    );

    final double rotation = random.nextDouble() * 2.0 * math.pi;

    return SceneryInstance3D(
      id: 'scenery_${step}_${sideSign > 0 ? "r" : "l"}',
      type: objectType,
      assetKey: objectType.assetKey,
      worldPosition: worldPos,
      rotationYawRadians: rotation,
      scale: Vector3.all(scaleFactor),
      distanceAlongCourseMeters: distanceMeters,
      lateralOffsetMeters: lateralOffset,
      elevationMeters: elevation,
      biomeZone: biome,
      isAnimated: objectType == SceneryObjectType.cheeringSpectators,
    );
  }

  SceneryInstance3D? _spawnFinishingCrowdInstance({
    required int step,
    required double distanceMeters,
    required double elevation,
    required ElevationBiomeZone biome,
    required math.Random random,
    required List<StageSegment> segments,
    required Scene3DMathProjection projection,
  }) {
    // Kibice po przeciwległej stronie
    final double side = (random.nextBool()) ? 1.0 : -1.0;
    final double lateralOffset = side * (config.minLateralDistanceMeters + 0.3 + random.nextDouble() * 0.5);

    final worldPos = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: distanceMeters + (random.nextDouble() * 3.0),
      lateralOffsetMeters: lateralOffset,
      elevationMeters: elevation,
      turningRadiusMeters: double.infinity,
      gradientPercent: 7.0,
    );

    return SceneryInstance3D(
      id: 'finishing_fan_$step',
      type: SceneryObjectType.cheeringSpectators,
      assetKey: SceneryObjectType.cheeringSpectators.assetKey,
      worldPosition: worldPos,
      rotationYawRadians: (side > 0) ? -math.pi * 0.5 : math.pi * 0.5, // Kibice zwróceni twarzą do szosy
      scale: Vector3.all(0.9 + random.nextDouble() * 0.25),
      distanceAlongCourseMeters: distanceMeters,
      lateralOffsetMeters: lateralOffset,
      elevationMeters: elevation,
      biomeZone: biome,
      isAnimated: true,
    );
  }

  // ===========================================================================
  // 3. RENDEROWANIE INSTANCJI KRAJOBRAZU NA CANVAS 2D/3D
  // ===========================================================================

  /// Rysuje instancje krajobrazu na [Canvas] posortowane w porządku Back-to-Front.
  void renderSceneryInstances({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required List<SceneryInstance3D> instances,
    double animSeconds = 0.0,
  }) {
    if (instances.isEmpty) return;

    final eyePos = projection.cameraPosition;

    // 1. Obliczenie odległości od kamery i odrzucenie obiektów za plecami (Frustum Culling)
    final visibleList = <(SceneryInstance3D, ProjectedPoint3D, double)>[];

    for (final inst in instances) {
      final dist = (inst.worldPosition - eyePos).length;
      if (dist > config.forwardVisibilityMeters + 50.0) continue;

      final proj = projection.worldToScreen(inst.worldPosition);
      if (!proj.isInFrontOfCamera) continue;

      // Margines ekranowy dla dużych koron drzew i budynków
      const double margin = 180.0;
      if (proj.screenX < -margin ||
          proj.screenX > projection.viewportWidth + margin ||
          proj.screenY < -margin ||
          proj.screenY > projection.viewportHeight + margin) {
        continue;
      }

      visibleList.add((inst, proj, dist));
    }

    // 2. Sortowanie głębokości (Painter's Algorithm - najdalsze najpierw)
    visibleList.sort((a, b) => b.$3.compareTo(a.$3));

    // 3. Rysowanie poszczególnych obiektów
    for (final item in visibleList) {
      final inst = item.$1;
      final proj = item.$2;

      final pos = Offset(proj.screenX, proj.screenY);
      final double scale = (proj.perspectiveScale * 14.5 * inst.scale.x).clamp(0.2, 8.5);

      switch (inst.type) {
        case SceneryObjectType.pineTree:
          _drawPineTree3D(canvas, pos, scale);
          break;

        case SceneryObjectType.cypressTree:
          _drawCypressTree3D(canvas, pos, scale);
          break;

        case SceneryObjectType.deciduousTree:
          _drawDeciduousTree3D(canvas, pos, scale);
          break;

        case SceneryObjectType.avenueTree:
          _drawAvenueTree3D(canvas, pos, scale);
          break;

        case SceneryObjectType.farmlandField:
          _drawFarmlandField3D(canvas, pos, scale);
          break;

        case SceneryObjectType.boulderRock:
          _drawBoulderRock3D(canvas, pos, scale);
          break;

        case SceneryObjectType.alpineCrag:
          _drawAlpineCrag3D(canvas, pos, scale);
          break;

        case SceneryObjectType.snowPatch:
          _drawSnowPatch3D(canvas, pos, scale);
          break;

        case SceneryObjectType.townhouse:
          _drawTownhouse3D(canvas, pos, scale);
          break;

        case SceneryObjectType.cheeringSpectators:
          _drawSpectators3D(canvas, pos, scale, inst, animSeconds);
          break;

        case SceneryObjectType.woodenBarrier:
          _drawWoodenBarrier3D(canvas, pos, scale);
          break;

        case SceneryObjectType.mountainPeak:
          _drawMountainPeak3D(canvas, pos, scale);
          break;
      }
    }
  }

  // ===========================================================================
  // 4. WEKTOROWE RYSOWANIE POSZCZEGÓLNYCH ELEMENTÓW KRAJOBRAZU
  // ===========================================================================

  void _drawPineTree3D(Canvas canvas, Offset pos, double scale) {
    final double trunkW = 4.2 * scale;
    final double trunkH = 16.0 * scale;

    // Pień
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - trunkH * 0.5), width: trunkW, height: trunkH),
      _trunkPaint,
    );

    // Trzy stożki igliwia sosny alpejskiej
    final double r1 = 18.0 * scale;
    final double r2 = 14.0 * scale;
    final double r3 = 9.5 * scale;

    _drawConeTier(canvas, Offset(pos.dx, pos.dy - trunkH * 0.7), r1, 14.0 * scale, _pineNeedlesPaint);
    _drawConeTier(canvas, Offset(pos.dx, pos.dy - trunkH * 0.7 - (10.0 * scale)), r2, 12.0 * scale, _pineNeedlesPaint);
    _drawConeTier(canvas, Offset(pos.dx, pos.dy - trunkH * 0.7 - (19.0 * scale)), r3, 10.0 * scale, _pineNeedlesPaint);
  }

  void _drawCypressTree3D(Canvas canvas, Offset pos, double scale) {
    final double trunkH = 8.0 * scale;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - trunkH * 0.5), width: 3.0 * scale, height: trunkH),
      _trunkPaint,
    );

    // Smukła, pionowa korona cyprysu toskańskiego
    final crownRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - trunkH - (22.0 * scale)),
      width: 10.0 * scale,
      height: 44.0 * scale,
    );
    canvas.drawOval(crownRect, _cypressCrownPaint);
  }

  void _drawDeciduousTree3D(Canvas canvas, Offset pos, double scale) {
    final double trunkW = 5.5 * scale;
    final double trunkH = 18.0 * scale;

    // Pień
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - trunkH * 0.5), width: trunkW, height: trunkH),
      _trunkPaint,
    );

    // Rozłożysta okrągła korona dębu / lipy
    final double r = 20.0 * scale;
    canvas.drawCircle(Offset(pos.dx, pos.dy - trunkH - (12.0 * scale)), r, _deciduousCrownPaint);
    canvas.drawCircle(Offset(pos.dx - (6.0 * scale), pos.dy - trunkH - (8.0 * scale)), r * 0.75, _deciduousCrownPaint);
    canvas.drawCircle(Offset(pos.dx + (6.0 * scale), pos.dy - trunkH - (8.0 * scale)), r * 0.75, _deciduousCrownPaint);
  }

  void _drawAvenueTree3D(Canvas canvas, Offset pos, double scale) {
    final double trunkW = 3.6 * scale;
    final double trunkH = 22.0 * scale;

    // Bielona dolna połowa pnia (tradycyjna brukowana aleja europejska)
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - trunkH * 0.25), width: trunkW, height: trunkH * 0.5),
      _whitewashTrunkPaint,
    );
    // Ciemna górna połowa pnia
    canvas.drawRect(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - trunkH * 0.75), width: trunkW, height: trunkH * 0.5),
      _trunkPaint,
    );

    // Zgrabna, przycięta korona alei (Platan / Topola)
    final double crownW = 20.0 * scale;
    final double crownH = 26.0 * scale;
    final crownRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - trunkH - (crownH * 0.45)),
      width: crownW,
      height: crownH,
    );
    canvas.drawOval(crownRect, _deciduousCrownPaint);
  }

  void _drawFarmlandField3D(Canvas canvas, Offset pos, double scale) {
    // 1. Złoty snop / bela siana na polu uprawnym
    final double baleW = 16.0 * scale;
    final double baleH = 11.0 * scale;
    final baleRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - baleH * 0.5),
      width: baleW,
      height: baleH,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(baleRect, Radius.circular(2.5 * scale)), _farmlandHayPaint);

    // Przewiązka beli
    final bandPaint = Paint()
      ..color = const Color(0xFF92400E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawLine(Offset(pos.dx - baleW * 0.25, pos.dy - baleH), Offset(pos.dx - baleW * 0.25, pos.dy), bandPaint);
    canvas.drawLine(Offset(pos.dx + baleW * 0.25, pos.dy - baleH), Offset(pos.dx + baleW * 0.25, pos.dy), bandPaint);

    // 2. Drewniane ogrodzenie pastwiska
    final double fenceW = 26.0 * scale;
    final double fenceH = 6.0 * scale;
    _farmlandFencePaint.strokeWidth = 1.6 * scale;
    canvas.drawLine(Offset(pos.dx - fenceW * 0.5, pos.dy - fenceH), Offset(pos.dx + fenceW * 0.5, pos.dy - fenceH), _farmlandFencePaint);
    canvas.drawLine(Offset(pos.dx - fenceW * 0.5, pos.dy - fenceH * 0.45), Offset(pos.dx + fenceW * 0.5, pos.dy - fenceH * 0.45), _farmlandFencePaint);
    canvas.drawLine(Offset(pos.dx - fenceW * 0.4, pos.dy), Offset(pos.dx - fenceW * 0.4, pos.dy - fenceH * 1.15), _farmlandFencePaint);
    canvas.drawLine(Offset(pos.dx + fenceW * 0.4, pos.dy), Offset(pos.dx + fenceW * 0.4, pos.dy - fenceH * 1.15), _farmlandFencePaint);
  }

  void _drawBoulderRock3D(Canvas canvas, Offset pos, double scale) {
    final path = Path()
      ..moveTo(pos.dx - (14.0 * scale), pos.dy)
      ..lineTo(pos.dx - (10.0 * scale), pos.dy - (12.0 * scale))
      ..lineTo(pos.dx + (2.0 * scale), pos.dy - (16.0 * scale))
      ..lineTo(pos.dx + (15.0 * scale), pos.dy - (8.0 * scale))
      ..lineTo(pos.dx + (12.0 * scale), pos.dy)
      ..close();

    canvas.drawPath(path, _rockGranitePaint);
  }

  void _drawAlpineCrag3D(Canvas canvas, Offset pos, double scale) {
    final double w = 46.0 * scale;
    final double h = 52.0 * scale;

    // Główna potężna ściana turni skalnej (Dolomite Crag)
    final cragPath = Path()
      ..moveTo(pos.dx - w * 0.55, pos.dy)
      ..lineTo(pos.dx - w * 0.35, pos.dy - h * 0.75)
      ..lineTo(pos.dx - w * 0.10, pos.dy - h)
      ..lineTo(pos.dx + w * 0.15, pos.dy - h * 0.88)
      ..lineTo(pos.dx + w * 0.45, pos.dy - h * 0.65)
      ..lineTo(pos.dx + w * 0.55, pos.dy)
      ..close();
    canvas.drawPath(cragPath, _rockGranitePaint);

    // Cienie pionowych żlebów i pęknięć skalnych
    final shadowPath = Path()
      ..moveTo(pos.dx - w * 0.10, pos.dy - h)
      ..lineTo(pos.dx - w * 0.05, pos.dy - h * 0.45)
      ..lineTo(pos.dx + w * 0.08, pos.dy - h * 0.35)
      ..lineTo(pos.dx + w * 0.02, pos.dy)
      ..lineTo(pos.dx + w * 0.12, pos.dy)
      ..lineTo(pos.dx + w * 0.15, pos.dy - h * 0.88)
      ..close();
    canvas.drawPath(shadowPath, _cragShadowPaint);

    // Ośnieżona grań wierzchołkowa
    final ridgeSnowPath = Path()
      ..moveTo(pos.dx - w * 0.20, pos.dy - h * 0.85)
      ..lineTo(pos.dx - w * 0.10, pos.dy - h)
      ..lineTo(pos.dx + w * 0.05, pos.dy - h * 0.92)
      ..lineTo(pos.dx + w * 0.02, pos.dy - h * 0.82)
      ..close();
    canvas.drawPath(ridgeSnowPath, _snowWhitePaint);
  }

  void _drawSnowPatch3D(Canvas canvas, Offset pos, double scale) {
    // Miękka, zaokrąglona łata śnieżna przy poboczu
    final snowRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy - (2.5 * scale)),
      width: 32.0 * scale,
      height: 7.0 * scale,
    );
    canvas.drawOval(snowRect, _snowWhitePaint);
  }

  void _drawTownhouse3D(Canvas canvas, Offset pos, double scale) {
    final double w = 36.0 * scale;
    final double h = 32.0 * scale;

    // Ściany kamienicy
    final wallRect = Rect.fromCenter(center: Offset(pos.dx, pos.dy - h * 0.5), width: w, height: h);
    canvas.drawRect(wallRect, _houseWallPaint);

    // Dach dwuspadowy (terakota)
    final roofPath = Path()
      ..moveTo(pos.dx - (w * 0.58), pos.dy - h)
      ..lineTo(pos.dx, pos.dy - h - (16.0 * scale))
      ..lineTo(pos.dx + (w * 0.58), pos.dy - h)
      ..close();
    canvas.drawPath(roofPath, _houseRoofPaint);

    // Okna
    final windowPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx - (8.0 * scale), pos.dy - (h * 0.65)), width: 6.0 * scale, height: 7.0 * scale), windowPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx + (8.0 * scale), pos.dy - (h * 0.65)), width: 6.0 * scale, height: 7.0 * scale), windowPaint);
  }

  void _drawSpectators3D(Canvas canvas, Offset pos, double scale, SceneryInstance3D inst, double animSeconds) {
    // Grupa 2-3 kibiców
    final int fanCount = 2 + (inst.id.hashCode % 2);

    for (int i = 0; i < fanCount; i++) {
      final double xOffset = (i - (fanCount - 1) * 0.5) * (7.0 * scale);
      final paintIdx = (inst.id.hashCode + i).abs() % _fanClothingPaints.length;
      final fanCloth = _fanClothingPaints[paintIdx];

      final fanPos = Offset(pos.dx + xOffset, pos.dy);
      final double bodyH = 14.0 * scale;

      // Tułów kibica
      canvas.drawRect(
        Rect.fromCenter(center: Offset(fanPos.dx, fanPos.dy - bodyH * 0.5), width: 5.5 * scale, height: bodyH),
        fanCloth,
      );

      // Głowa
      canvas.drawCircle(Offset(fanPos.dx, fanPos.dy - bodyH - (3.0 * scale)), 2.8 * scale, _spectatorSkinPaint);

      // Machająca flaga narodowa
      if (inst.isAnimated && i == 0) {
        final double flagWave = math.sin((animSeconds * 8.0) + (inst.id.hashCode % 10)) * (4.0 * scale);
        final flagPaint = Paint()..color = const Color(0xFFEF4444);
        final polePaint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1.0 * scale;

        final poleBase = Offset(fanPos.dx + (2.5 * scale), fanPos.dy - bodyH * 0.6);
        final poleTop = Offset(fanPos.dx + (6.0 * scale), fanPos.dy - bodyH - (12.0 * scale));
        canvas.drawLine(poleBase, poleTop, polePaint);

        final flagPath = Path()
          ..moveTo(poleTop.dx, poleTop.dy)
          ..lineTo(poleTop.dx + (10.0 * scale), poleTop.dy + flagWave)
          ..lineTo(poleTop.dx + (8.0 * scale), poleTop.dy + (6.0 * scale) + flagWave)
          ..lineTo(poleTop.dx, poleTop.dy + (5.0 * scale))
          ..close();
        canvas.drawPath(flagPath, flagPaint);
      }
    }
  }

  void _drawWoodenBarrier3D(Canvas canvas, Offset pos, double scale) {
    final double barW = 28.0 * scale;
    final double barH = 7.0 * scale;

    _barrierWoodPaint.strokeWidth = 2.4 * scale;
    // Dwie poziome żerdzie
    canvas.drawLine(Offset(pos.dx - barW * 0.5, pos.dy - barH), Offset(pos.dx + barW * 0.5, pos.dy - barH), _barrierWoodPaint);
    canvas.drawLine(Offset(pos.dx - barW * 0.5, pos.dy - barH * 0.4), Offset(pos.dx + barW * 0.5, pos.dy - barH * 0.4), _barrierWoodPaint);

    // Słupki pionowe
    canvas.drawLine(Offset(pos.dx - barW * 0.4, pos.dy), Offset(pos.dx - barW * 0.4, pos.dy - barH * 1.1), _barrierWoodPaint);
    canvas.drawLine(Offset(pos.dx + barW * 0.4, pos.dy), Offset(pos.dx + barW * 0.4, pos.dy - barH * 1.1), _barrierWoodPaint);
  }

  void _drawMountainPeak3D(Canvas canvas, Offset pos, double scale) {
    final double peakW = 60.0 * scale;
    final double peakH = 45.0 * scale;

    final rockPath = Path()
      ..moveTo(pos.dx - peakW * 0.5, pos.dy)
      ..lineTo(pos.dx, pos.dy - peakH)
      ..lineTo(pos.dx + peakW * 0.5, pos.dy)
      ..close();
    canvas.drawPath(rockPath, _rockGranitePaint);

    // Ośnieżony wierzchołek
    final snowPath = Path()
      ..moveTo(pos.dx - (peakW * 0.16), pos.dy - (peakH * 0.68))
      ..lineTo(pos.dx, pos.dy - peakH)
      ..lineTo(pos.dx + (peakW * 0.16), pos.dy - (peakH * 0.68))
      ..lineTo(pos.dx, pos.dy - (peakH * 0.62))
      ..close();
    canvas.drawPath(snowPath, _snowWhitePaint);
  }

  void _drawConeTier(Canvas canvas, Offset center, double radius, double height, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..lineTo(center.dx, center.dy - height)
      ..lineTo(center.dx + radius, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  // ===========================================================================
  // 5. OBLICZENIA WYSOKOŚCI I GRADIENTU Z LISTY SEGMENTÓW
  // ===========================================================================

  StageSegment? _resolveSegmentAt(double distanceMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return null;
    final km = distanceMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg;
      }
    }
    return segments.last;
  }

  double _calculateElevationAt(double distanceMeters, List<StageSegment> segments) {
    if (segments.isEmpty) {
      // Domyślny profil wspinaczkowy jeśli brak segmentów
      return 450.0 + (distanceMeters * 0.045);
    }

    final double km = distanceMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        final double t = (seg.lengthKm > 0.001) ? ((km - seg.startKm) / seg.lengthKm).clamp(0.0, 1.0) : 0.0;
        return seg.startElevationM + (seg.endElevationM - seg.startElevationM) * t;
      }
    }

    return segments.last.endElevationM;
  }

  double _calculateGradientAt(double distanceMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 4.5;

    final double km = distanceMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg.gradientPercent;
      }
    }

    return segments.last.gradientPercent;
  }
}
