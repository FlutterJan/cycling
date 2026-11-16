// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TYPY MEDIÓW, KATEGORII I KONFIGURACJI NAPISÓW NA ASFALCIE
// =============================================================================

/// Technika wykonania napisu kibicowskiego na nawierzchni podjazdu górskiego.
enum AsphaltGraffitiMedium {
  /// Trwała farba drogowa/lateksowa malowana wałkiem lub szablonem.
  latexPaint(
    labelPl: 'Farba drogowa',
    baseOpacity: 0.88,
    strokeBoost: 1.15,
  ),

  /// Sypka kreda asfaltowa nanoszona przez kibiców w dniu etapu.
  sidewalkChalk(
    labelPl: 'Kreda asfaltowa',
    baseOpacity: 0.68,
    strokeBoost: 0.92,
  );

  final String labelPl;
  final double baseOpacity;
  final double strokeBoost;

  const AsphaltGraffitiMedium({
    required this.labelPl,
    required this.baseOpacity,
    required this.strokeBoost,
  });
}

/// Kategoria semantyczna napisu na asfalcie.
enum AsphaltGraffitiCategory {
  /// Klasyczne hasła kolarskie: `ALLEZ!`, `VAI!`, `GO!`.
  iconicSlogan(labelPl: 'Hasło kibiców'),

  /// Nazwisko aktualnego lidera klasyfikacji generalnej (GC).
  gcLeader(labelPl: 'Lider GC'),

  /// Nazwisko faworyta etapu górskiego.
  stageFavorite(labelPl: 'Faworyt etapu');

  final String labelPl;

  const AsphaltGraffitiCategory({required this.labelPl});
}

/// Konfiguracja generatora i renderera napisów na asfalcie [AsphaltChalkGraffitiRenderer].
class AsphaltChalkGraffitiConfig {
  /// Czy warstwa napisów na podjazdach jest aktywna.
  final bool enabled;

  /// Czy generować napisy na podjazdach 1. kategorii (`Cat 1`).
  final bool enableCat1Climbs;

  /// Czy generować napisy na podjazdach poza kategorią (`HC`).
  final bool enableHcClimbs;

  /// Czy nanosić ślady przetarcia opon peletonu i wozów technicznych na farbie.
  final bool showTireWearStreaks;

  /// Czy rysować drobinki pyłu kredowego wokół napisów z kredy.
  final bool showChalkDustSpeckles;

  /// Maksymalny dystans przed kamerą [m], w którym napisy są rzutowane.
  final double maxRenderDistanceMeters;

  /// Minimalny dystans przed kamerą [m], poniżej którego napisy są odrzucane.
  final double minRenderDistanceMeters;

  /// Średni odstęp pomiędzy kolejnymi napisami na podjazdach Cat 1 [m].
  final double cat1SpacingMeters;

  /// Średni odstęp pomiędzy kolejnymi napisami na podjazdach HC [m].
  final double hcSpacingMeters;

  /// Połowa bezpiecznej szerokości jezdni dostępnej na napisy [m].
  final double roadHalfWidthMeters;

  /// Globalny mnożnik krycia napisów (0.0 - 1.0).
  final double opacityScale;

  /// Współczynnik zmoknięcia asfaltu (0.0 = suchy, 1.0 = ulewa rozmywająca kredę).
  final double wetAsphaltFadeFactor;

  /// Deterministyczne ziarno generatora dla etapu.
  final int stageSeed;

  const AsphaltChalkGraffitiConfig({
    this.enabled = true,
    this.enableCat1Climbs = true,
    this.enableHcClimbs = true,
    this.showTireWearStreaks = true,
    this.showChalkDustSpeckles = true,
    this.maxRenderDistanceMeters = 180.0,
    this.minRenderDistanceMeters = 2.0,
    this.cat1SpacingMeters = 26.0,
    this.hcSpacingMeters = 16.0,
    this.roadHalfWidthMeters = 3.2,
    this.opacityScale = 1.0,
    this.wetAsphaltFadeFactor = 0.0,
    this.stageSeed = 202607,
  });

  AsphaltChalkGraffitiConfig copyWith({
    bool? enabled,
    bool? enableCat1Climbs,
    bool? enableHcClimbs,
    bool? showTireWearStreaks,
    bool? showChalkDustSpeckles,
    double? maxRenderDistanceMeters,
    double? minRenderDistanceMeters,
    double? cat1SpacingMeters,
    double? hcSpacingMeters,
    double? roadHalfWidthMeters,
    double? opacityScale,
    double? wetAsphaltFadeFactor,
    int? stageSeed,
  }) {
    return AsphaltChalkGraffitiConfig(
      enabled: enabled ?? this.enabled,
      enableCat1Climbs: enableCat1Climbs ?? this.enableCat1Climbs,
      enableHcClimbs: enableHcClimbs ?? this.enableHcClimbs,
      showTireWearStreaks: showTireWearStreaks ?? this.showTireWearStreaks,
      showChalkDustSpeckles:
          showChalkDustSpeckles ?? this.showChalkDustSpeckles,
      maxRenderDistanceMeters:
          maxRenderDistanceMeters ?? this.maxRenderDistanceMeters,
      minRenderDistanceMeters:
          minRenderDistanceMeters ?? this.minRenderDistanceMeters,
      cat1SpacingMeters: cat1SpacingMeters ?? this.cat1SpacingMeters,
      hcSpacingMeters: hcSpacingMeters ?? this.hcSpacingMeters,
      roadHalfWidthMeters: roadHalfWidthMeters ?? this.roadHalfWidthMeters,
      opacityScale: opacityScale ?? this.opacityScale,
      wetAsphaltFadeFactor: wetAsphaltFadeFactor ?? this.wetAsphaltFadeFactor,
      stageSeed: stageSeed ?? this.stageSeed,
    );
  }
}

// =============================================================================
// 2. MODELE STREF PODJAZDÓW CAT 1 / HC I RZUTOWANYCH NAPISÓW 3D
// =============================================================================

/// Strefa podjazdu górskiego Cat 1 lub HC, na której pojawiają się napisy na asfalcie.
class AsphaltGraffitiClimbZone {
  final String id;
  final String name;
  final double startDistanceMeters;
  final double endDistanceMeters;
  final SegmentClassification classification;
  final double averageGradientPercent;
  final double maxGradientPercent;

  const AsphaltGraffitiClimbZone({
    required this.id,
    required this.name,
    required this.startDistanceMeters,
    required this.endDistanceMeters,
    required this.classification,
    required this.averageGradientPercent,
    required this.maxGradientPercent,
  });

  double get lengthMeters =>
      math.max(0.0, endDistanceMeters - startDistanceMeters);

  bool containsDistance(double distanceMeters) =>
      distanceMeters >= startDistanceMeters &&
      distanceMeters <= endDistanceMeters;
}

/// Pojedynczy napis malowany farbą lub kredą osadzony w układzie trasy 3D.
class AsphaltChalkGraffitiDecal {
  final String id;
  final String text;
  final AsphaltGraffitiCategory category;
  final AsphaltGraffitiMedium medium;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final double widthMeters;
  final double heightMeters;
  final double yawAngleRadians;
  final Color primaryColor;
  final Color outlineColor;
  final double weatheringOpacity;
  final int tireWearSeed;
  final SegmentClassification climbClassification;

  const AsphaltChalkGraffitiDecal({
    required this.id,
    required this.text,
    required this.category,
    required this.medium,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.elevationMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.yawAngleRadians,
    required this.primaryColor,
    required this.outlineColor,
    required this.weatheringOpacity,
    required this.tireWearSeed,
    required this.climbClassification,
  });
}

/// Wynik rzutowania perspektywicznego napisu 3D na powierzchnię asfaltu w przestrzeni ekranu.
class ProjectedGraffitiDecal {
  final AsphaltChalkGraffitiDecal decal;
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final Offset center;
  final double depthEye;
  final double perspectiveScale;
  final double effectiveOpacity;
  final double localPixelWidth;
  final double localPixelHeight;
  final Float64List homographyMatrix4;

  const ProjectedGraffitiDecal({
    required this.decal,
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.center,
    required this.depthEye,
    required this.perspectiveScale,
    required this.effectiveOpacity,
    required this.localPixelWidth,
    required this.localPixelHeight,
    required this.homographyMatrix4,
  });
}

/// Telemetria pojedynczej klatki renderowania napisów na asfalcie.
class AsphaltChalkGraffitiTelemetry {
  final bool isActiveZone;
  final SegmentClassification activeClimbClassification;
  final String activeZoneName;
  final int totalDecalsInWindow;
  final int renderedDecalsCount;
  final int gcLeaderDecalsCount;
  final int favoriteDecalsCount;
  final int sloganDecalsCount;
  final double averageDepthMeters;

  const AsphaltChalkGraffitiTelemetry({
    required this.isActiveZone,
    required this.activeClimbClassification,
    required this.activeZoneName,
    required this.totalDecalsInWindow,
    required this.renderedDecalsCount,
    required this.gcLeaderDecalsCount,
    required this.favoriteDecalsCount,
    required this.sloganDecalsCount,
    required this.averageDepthMeters,
  });

  const AsphaltChalkGraffitiTelemetry.inactive()
      : isActiveZone = false,
        activeClimbClassification = SegmentClassification.none,
        activeZoneName = '',
        totalDecalsInWindow = 0,
        renderedDecalsCount = 0,
        gcLeaderDecalsCount = 0,
        favoriteDecalsCount = 0,
        sloganDecalsCount = 0,
        averageDepthMeters = 0.0;
}

/// Sygnatura funkcji wyznaczającej 3D pozę na powierzchni drogi.
typedef GraffitiCoursePoseResolver = Cyclist3DPose Function({
  required CoursePosition coursePosition,
  required RoadGeometryParameters roadGeometry,
});

// =============================================================================
// 3. GENERATOR I RENDERER 3D NAPISÓW FARBĄ I KREDĄ NA ASFALCIE
// =============================================================================

/// Generator i renderer 3D napisów malowanych farbą i kredą na asfalcie
/// podczas górskich podjazdów `Cat 1` oraz `HC` (`Hors Catégorie`).
///
/// Generuje deterministycznie rozmieszczone napisy `ALLEZ!`, `VAI!`, `GO!` oraz
/// dynamicznie wstawiane nazwiska aktualnego lidera klasyfikacji generalnej (GC)
/// i faworytów etapu, a następnie rzutuje je w pełnej perspektywie 3D na płaszczyznę szosy
/// za pomocą homografii macierzowej `4x4`.
class AsphaltChalkGraffitiRenderer {
  /// Klasyczne hasła kibiców malowane na alpejskich i pirenejskich przełęczach.
  static const List<String> iconicSlogans = <String>[
    'ALLEZ!',
    'VAI!',
    'GO!',
  ];

  static const List<Color> _paintPalette = <Color>[
    Color(0xFFF8FAFC), // Biała farba drogowa
    Color(0xFFFACC15), // Żółty akcent Tour
    Color(0xFFF97316), // Pomarańczowy holenderski / alpejski
    Color(0xFFEF4444), // Czerwień w grochy KOM
    Color(0xFF38BDF8), // Błękit górski
  ];

  static const List<Color> _chalkPalette = <Color>[
    Color(0xFFF3F4F6), // Kreda biała
    Color(0xFFFDE047), // Kreda żółta
    Color(0xFFF472B6), // Kreda różowa (Giro)
    Color(0xFF67E8F9), // Kreda błękitna
    Color(0xFFFB923C), // Kreda pomarańczowa
  ];

  final AsphaltChalkGraffitiConfig config;

  const AsphaltChalkGraffitiRenderer({
    this.config = const AsphaltChalkGraffitiConfig(),
  });

  /// Sprawdza, czy dana klasyfikacja segmentu kwalifikuje się do napisów (`Cat 1` lub `HC`).
  static bool isSupportedClimbClassification(
    SegmentClassification classification, {
    bool includeCat1 = true,
    bool includeHc = true,
  }) {
    if (classification == SegmentClassification.cat1 && includeCat1) {
      return true;
    }
    if (classification == SegmentClassification.horsCategorie && includeHc) {
      return true;
    }
    return false;
  }

  /// Wykrywa strefy podjazdów górskich `Cat 1` i `HC` z listy segmentów etapu [stage].
  ///
  /// Scala sąsiadujące segmenty oznaczone jako `cat1` lub `horsCategorie` w spójne strefy,
  /// na których rozkładane są napisy na asfalcie.
  static List<AsphaltGraffitiClimbZone> detectMountainClimbZones(
    RaceStage stage, {
    bool includeCat1 = true,
    bool includeHc = true,
  }) {
    final List<AsphaltGraffitiClimbZone> zones = <AsphaltGraffitiClimbZone>[];
    if (stage.segments.isEmpty) {
      return zones;
    }

    double? activeStartM;
    double activeEndM = 0.0;
    double weightedGradSum = 0.0;
    double activeLenM = 0.0;
    double maxGrad = 0.0;
    SegmentClassification? activeClass;
    int zoneCounter = 0;

    void flushZone() {
      if (activeStartM == null || activeLenM <= 0.0 || activeClass == null) {
        activeStartM = null;
        activeClass = null;
        return;
      }
      zoneCounter += 1;
      final String catLabel =
          activeClass == SegmentClassification.horsCategorie ? 'HC' : 'Cat 1';
      zones.add(
        AsphaltGraffitiClimbZone(
          id: 'graffiti_climb_$zoneCounter',
          name: '$catLabel Climb #$zoneCounter',
          startDistanceMeters: activeStartM!,
          endDistanceMeters: activeEndM,
          classification: activeClass!,
          averageGradientPercent: weightedGradSum / activeLenM,
          maxGradientPercent: maxGrad,
        ),
      );
      activeStartM = null;
      activeClass = null;
      weightedGradSum = 0.0;
      activeLenM = 0.0;
      maxGrad = 0.0;
    }

    for (final StageSegment seg in stage.segments) {
      final double segStartM = seg.startKm * 1000.0;
      final double segLenM = seg.lengthKm * 1000.0;
      final double segEndM = segStartM + segLenM;
      final bool supported = isSupportedClimbClassification(
        seg.sprintOrKomClassification,
        includeCat1: includeCat1,
        includeHc: includeHc,
      );

      if (supported && segLenM > 0.0) {
        if (activeClass != null &&
            activeClass != seg.sprintOrKomClassification) {
          flushZone();
        }
        activeStartM ??= segStartM;
        activeEndM = segEndM;
        activeClass = seg.sprintOrKomClassification;
        final double grad = seg.gradientPercent;
        weightedGradSum += grad * segLenM;
        activeLenM += segLenM;
        if (grad > maxGrad) {
          maxGrad = grad;
        }
      } else {
        flushZone();
      }
    }
    flushZone();
    return zones;
  }

  /// Wyodrębnia wielkie nazwisko kolarza z pełnego imienia i nazwiska.
  ///
  /// Obsługuje partykuły nazwiskowe (np. `van der`, `de`, `di`) oraz puste ciągi.
  static String extractRiderSurname(String fullName) {
    final String trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final List<String> parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first.toUpperCase();
    }
    // Obsługa wieloczłonowych nazwisk typu "Mathieu van der Poel" / "Wout van Aert"
    const Set<String> particles = <String>{
      'van',
      'der',
      'den',
      'de',
      'la',
      'le',
      'di',
      'da',
      'del',
      'dos',
    };
    int startIdx = parts.length - 1;
    while (startIdx > 1 && particles.contains(parts[startIdx - 1].toLowerCase())) {
      startIdx--;
    }
    return parts.sublist(startIdx).join(' ').toUpperCase();
  }

  /// Generuje deterministyczną listę napisów na asfalcie dla wybranej strefy podjazdu Cat 1 / HC.
  List<AsphaltChalkGraffitiDecal> generateDecalsForZone({
    required AsphaltGraffitiClimbZone zone,
    required double Function(double distanceMeters) elevationAtDistance,
    String? gcLeaderName,
    List<String> stageFavoriteNames = const <String>[],
    int? seedOverride,
  }) {
    if (!config.enabled) {
      return const <AsphaltChalkGraffitiDecal>[];
    }
    if (!isSupportedClimbClassification(
      zone.classification,
      includeCat1: config.enableCat1Climbs,
      includeHc: config.enableHcClimbs,
    )) {
      return const <AsphaltChalkGraffitiDecal>[];
    }
    if (zone.lengthMeters <= 0.0) {
      return const <AsphaltChalkGraffitiDecal>[];
    }

    final String leaderSurname =
        gcLeaderName != null ? extractRiderSurname(gcLeaderName) : '';
    final List<String> favoriteSurnames = stageFavoriteNames
        .map(extractRiderSurname)
        .where((s) => s.isNotEmpty && s != leaderSurname)
        .toSet()
        .toList();

    final bool isHc =
        zone.classification == SegmentClassification.horsCategorie;
    final double baseSpacing =
        isHc ? config.hcSpacingMeters : config.cat1SpacingMeters;
    final double spacing = math.max(8.0, baseSpacing);

    final int zoneSeed = (seedOverride ?? config.stageSeed) ^
        zone.startDistanceMeters.round() ^
        (zone.classification.index * 7919);
    final math.Random rng = math.Random(zoneSeed);

    final List<AsphaltChalkGraffitiDecal> decals = <AsphaltChalkGraffitiDecal>[];
    double cursor = zone.startDistanceMeters + math.min(6.0, zone.lengthMeters * 0.15);
    int index = 0;

    while (cursor < zone.endDistanceMeters - 2.0) {
      final double progress = zone.lengthMeters > 0.0
          ? ((cursor - zone.startDistanceMeters) / zone.lengthMeters)
              .clamp(0.0, 1.0)
          : 0.0;

      // Wybór kategorii na podstawie progresu podjazdu i dostępnych nazwisk
      final AsphaltGraffitiCategory category = _pickCategory(
        index: index,
        rng: rng,
        hasGcLeader: leaderSurname.isNotEmpty,
        hasFavorites: favoriteSurnames.isNotEmpty,
      );

      final String text = _buildGraffitiText(
        category: category,
        index: index,
        rng: rng,
        leaderSurname: leaderSurname,
        favoriteSurnames: favoriteSurnames,
      );

      final AsphaltGraffitiMedium medium = (index % 3 == 0 ||
              category == AsphaltGraffitiCategory.gcLeader)
          ? AsphaltGraffitiMedium.latexPaint
          : AsphaltGraffitiMedium.sidewalkChalk;

      final Color primaryColor = _pickDecalColor(
        category: category,
        medium: medium,
        rng: rng,
      );

      final double widthMeters =
          (1.6 + text.length * 0.22).clamp(2.0, config.roadHalfWidthMeters * 1.85);
      final double heightMeters = 0.72 + rng.nextDouble() * 0.38;

      final double maxLat =
          math.max(0.2, config.roadHalfWidthMeters - widthMeters * 0.45);
      final double lateralOffset = (rng.nextDouble() * 2.0 - 1.0) * maxLat;
      final double yawAngle = (rng.nextDouble() * 2.0 - 1.0) * 0.22;

      // Większa gęstość na ostatnich 35% podjazdu HC/Cat1
      final double densityBoost = progress > 0.65 ? 0.78 : 1.0;
      final double weathering = 0.74 + rng.nextDouble() * 0.26;

      decals.add(
        AsphaltChalkGraffitiDecal(
          id: '${zone.id}_decal_$index',
          text: text,
          category: category,
          medium: medium,
          distanceMeters: cursor,
          lateralOffsetMeters: lateralOffset,
          elevationMeters: elevationAtDistance(cursor),
          widthMeters: widthMeters,
          heightMeters: heightMeters,
          yawAngleRadians: yawAngle,
          primaryColor: primaryColor,
          outlineColor: const Color(0xFF0F1115),
          weatheringOpacity: weathering,
          tireWearSeed: rng.nextInt(100000),
          climbClassification: zone.classification,
        ),
      );

      index++;
      cursor += spacing * densityBoost * (0.8 + rng.nextDouble() * 0.4);
    }

    return decals;
  }

  /// Zwraca listę widocznych napisów przed kamerą w zadanym oknie dystansu.
  List<AsphaltChalkGraffitiDecal> buildVisibleDecals({
    required double cameraCourseDistanceMeters,
    required double Function(double distanceMeters) elevationAtDistance,
    List<AsphaltGraffitiClimbZone> zones = const <AsphaltGraffitiClimbZone>[],
    SegmentClassification? fallbackClassification,
    String? gcLeaderName,
    List<String> stageFavoriteNames = const <String>[],
  }) {
    if (!config.enabled) {
      return const <AsphaltChalkGraffitiDecal>[];
    }

    final double minDist =
        cameraCourseDistanceMeters + config.minRenderDistanceMeters;
    final double maxDist =
        cameraCourseDistanceMeters + config.maxRenderDistanceMeters;

    List<AsphaltGraffitiClimbZone> effectiveZones = zones;
    if (effectiveZones.isEmpty &&
        fallbackClassification != null &&
        isSupportedClimbClassification(
          fallbackClassification,
          includeCat1: config.enableCat1Climbs,
          includeHc: config.enableHcClimbs,
        )) {
      effectiveZones = <AsphaltGraffitiClimbZone>[
        AsphaltGraffitiClimbZone(
          id: 'active_climb_window',
          name: fallbackClassification == SegmentClassification.horsCategorie
              ? 'Hors Catégorie'
              : 'Cat 1 Climb',
          startDistanceMeters: math.max(0.0, cameraCourseDistanceMeters - 20.0),
          endDistanceMeters: maxDist + 40.0,
          classification: fallbackClassification,
          averageGradientPercent: 9.0,
          maxGradientPercent: 12.0,
        ),
      ];
    }

    final List<AsphaltChalkGraffitiDecal> visible = <AsphaltChalkGraffitiDecal>[];
    for (final AsphaltGraffitiClimbZone zone in effectiveZones) {
      if (zone.endDistanceMeters < minDist ||
          zone.startDistanceMeters > maxDist) {
        continue;
      }
      final List<AsphaltChalkGraffitiDecal> zoneDecals = generateDecalsForZone(
        zone: zone,
        elevationAtDistance: elevationAtDistance,
        gcLeaderName: gcLeaderName,
        stageFavoriteNames: stageFavoriteNames,
      );
      for (final AsphaltChalkGraffitiDecal decal in zoneDecals) {
        if (decal.distanceMeters >= minDist && decal.distanceMeters <= maxDist) {
          visible.add(decal);
        }
      }
    }
    return visible;
  }

  /// Rzutuje pojedynczy napis 3D na płaszczyznę asfaltu i wylicza macierz homografii `4x4`.
  ///
  /// Zwraca `null`, gdy którykolwiek róg znajduje się za kamerą, poza buforem ekranu
  /// lub gdy rzutowany czworokąt ulega degeneracji.
  ProjectedGraffitiDecal? projectDecalToScreen({
    required AsphaltChalkGraffitiDecal decal,
    required Size viewportSize,
    required Scene3DMathProjection projection,
    required RoadGeometryParameters roadGeometry,
    GraffitiCoursePoseResolver? poseResolver,
  }) {
    if (viewportSize.width <= 0.0 || viewportSize.height <= 0.0) {
      return null;
    }

    final GraffitiCoursePoseResolver resolvePose =
        poseResolver ?? Scene3DMathProjection.courseToCyclistPose;

    final Cyclist3DPose centerPose = resolvePose(
      coursePosition: CoursePosition(
        distanceMeters: decal.distanceMeters,
        lateralOffsetMeters: decal.lateralOffsetMeters,
        elevationMeters: decal.elevationMeters,
        verticalOffsetMeters: 0.015,
      ),
      roadGeometry: roadGeometry,
    );

    final double cosYaw = math.cos(decal.yawAngleRadians);
    final double sinYaw = math.sin(decal.yawAngleRadians);

    // Oś U (szerokość napisu w poprzek jezdni), Oś V (wysokość napisu wzdłuż drogi)
    final Vector3 uAxis =
        centerPose.lateralRight * cosYaw + centerPose.tangent * sinYaw;
    final Vector3 vAxis =
        -centerPose.tangent * cosYaw + centerPose.lateralRight * sinYaw;

    final double halfW = decal.widthMeters * 0.5;
    final double halfH = decal.heightMeters * 0.5;

    final Vector3 worldTL =
        centerPose.position - uAxis * halfW - vAxis * halfH;
    final Vector3 worldTR =
        centerPose.position + uAxis * halfW - vAxis * halfH;
    final Vector3 worldBR =
        centerPose.position + uAxis * halfW + vAxis * halfH;
    final Vector3 worldBL =
        centerPose.position - uAxis * halfW + vAxis * halfH;

    final ProjectedPoint3D pTL = projection.worldToScreen(worldTL);
    final ProjectedPoint3D pTR = projection.worldToScreen(worldTR);
    final ProjectedPoint3D pBR = projection.worldToScreen(worldBR);
    final ProjectedPoint3D pBL = projection.worldToScreen(worldBL);
    final ProjectedPoint3D pCenter =
        projection.worldToScreen(centerPose.position);

    if (!pTL.isInFrontOfCamera ||
        !pTR.isInFrontOfCamera ||
        !pBR.isInFrontOfCamera ||
        !pBL.isInFrontOfCamera ||
        !pCenter.isInFrontOfCamera) {
      return null;
    }

    if (pCenter.depthEye < config.minRenderDistanceMeters ||
        pCenter.depthEye > config.maxRenderDistanceMeters) {
      return null;
    }

    const double margin = 260.0;
    final List<ProjectedPoint3D> corners = <ProjectedPoint3D>[pTL, pTR, pBR, pBL];
    bool anyInside = false;
    for (final ProjectedPoint3D c in corners) {
      if (c.screenX >= -margin &&
          c.screenX <= viewportSize.width + margin &&
          c.screenY >= -margin &&
          c.screenY <= viewportSize.height + margin) {
        anyInside = true;
        break;
      }
    }
    if (!anyInside) {
      return null;
    }

    final Offset oTL = Offset(pTL.screenX, pTL.screenY);
    final Offset oTR = Offset(pTR.screenX, pTR.screenY);
    final Offset oBR = Offset(pBR.screenX, pBR.screenY);
    final Offset oBL = Offset(pBL.screenX, pBL.screenY);

    // Weryfikacja pola rzutowanego czworokąta, aby uniknąć osobliwości przy ostrym kącie
    final double area2 = ((oTR.dx - oTL.dx) * (oBR.dy - oTL.dy) -
            (oTR.dy - oTL.dy) * (oBR.dx - oTL.dx))
        .abs();
    if (area2 < 8.0) {
      return null;
    }

    const double localW = 320.0;
    const double localH = 110.0;
    final Float64List? matrix = _computeQuadHomographyMatrix4(
      srcWidth: localW,
      srcHeight: localH,
      p0: oTL,
      p1: oTR,
      p2: oBR,
      p3: oBL,
    );
    if (matrix == null) {
      return null;
    }

    final double distanceFade = (1.0 -
            ((pCenter.depthEye - config.maxRenderDistanceMeters * 0.55) /
                    (config.maxRenderDistanceMeters * 0.45))
                .clamp(0.0, 1.0))
        .clamp(0.0, 1.0);

    final double wetnessMultiplier = decal.medium ==
            AsphaltGraffitiMedium.sidewalkChalk
        ? (1.0 - config.wetAsphaltFadeFactor * 0.55).clamp(0.2, 1.0)
        : (1.0 - config.wetAsphaltFadeFactor * 0.18).clamp(0.5, 1.0);

    final double effectiveOpacity = (decal.medium.baseOpacity *
            decal.weatheringOpacity *
            config.opacityScale *
            distanceFade *
            wetnessMultiplier)
        .clamp(0.0, 1.0);

    if (effectiveOpacity <= 0.03) {
      return null;
    }

    return ProjectedGraffitiDecal(
      decal: decal,
      topLeft: oTL,
      topRight: oTR,
      bottomRight: oBR,
      bottomLeft: oBL,
      center: Offset(pCenter.screenX, pCenter.screenY),
      depthEye: pCenter.depthEye,
      perspectiveScale: pCenter.perspectiveScale,
      effectiveOpacity: effectiveOpacity,
      localPixelWidth: localW,
      localPixelHeight: localH,
      homographyMatrix4: matrix,
    );
  }

  /// Renderuje napisy malowane farbą i kredą na warstwie drogi `Canvas`.
  AsphaltChalkGraffitiTelemetry paint({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required RoadGeometryParameters roadGeometry,
    required double cameraCourseDistanceMeters,
    required double Function(double distanceMeters) elevationAtDistance,
    List<AsphaltGraffitiClimbZone> zones = const <AsphaltGraffitiClimbZone>[],
    SegmentClassification? fallbackClassification,
    String? gcLeaderName,
    List<String> stageFavoriteNames = const <String>[],
    GraffitiCoursePoseResolver? poseResolver,
  }) {
    if (!config.enabled || size.width <= 0.0 || size.height <= 0.0) {
      return const AsphaltChalkGraffitiTelemetry.inactive();
    }

    final List<AsphaltChalkGraffitiDecal> decals = buildVisibleDecals(
      cameraCourseDistanceMeters: cameraCourseDistanceMeters,
      elevationAtDistance: elevationAtDistance,
      zones: zones,
      fallbackClassification: fallbackClassification,
      gcLeaderName: gcLeaderName,
      stageFavoriteNames: stageFavoriteNames,
    );

    if (decals.isEmpty) {
      return const AsphaltChalkGraffitiTelemetry.inactive();
    }

    final List<ProjectedGraffitiDecal> projectedList =
        <ProjectedGraffitiDecal>[];
    for (final AsphaltChalkGraffitiDecal decal in decals) {
      final ProjectedGraffitiDecal? proj = projectDecalToScreen(
        decal: decal,
        viewportSize: size,
        projection: projection,
        roadGeometry: roadGeometry,
        poseResolver: poseResolver,
      );
      if (proj != null) {
        projectedList.add(proj);
      }
    }

    if (projectedList.isEmpty) {
      return AsphaltChalkGraffitiTelemetry(
        isActiveZone: true,
        activeClimbClassification: decals.first.climbClassification,
        activeZoneName: _resolveZoneName(zones, decals.first),
        totalDecalsInWindow: decals.length,
        renderedDecalsCount: 0,
        gcLeaderDecalsCount: 0,
        favoriteDecalsCount: 0,
        sloganDecalsCount: 0,
        averageDepthMeters: 0.0,
      );
    }

    // Sortowanie od najdalszego do najbliższego (Painter's Algorithm)
    projectedList.sort((a, b) => b.depthEye.compareTo(a.depthEye));

    int gcCount = 0;
    int favCount = 0;
    int sloganCount = 0;
    double depthSum = 0.0;

    for (final ProjectedGraffitiDecal item in projectedList) {
      _paintProjectedDecal(canvas, item);
      depthSum += item.depthEye;
      switch (item.decal.category) {
        case AsphaltGraffitiCategory.gcLeader:
          gcCount++;
          break;
        case AsphaltGraffitiCategory.stageFavorite:
          favCount++;
          break;
        case AsphaltGraffitiCategory.iconicSlogan:
          sloganCount++;
          break;
      }
    }

    return AsphaltChalkGraffitiTelemetry(
      isActiveZone: true,
      activeClimbClassification: projectedList.first.decal.climbClassification,
      activeZoneName: _resolveZoneName(zones, projectedList.first.decal),
      totalDecalsInWindow: decals.length,
      renderedDecalsCount: projectedList.length,
      gcLeaderDecalsCount: gcCount,
      favoriteDecalsCount: favCount,
      sloganDecalsCount: sloganCount,
      averageDepthMeters: depthSum / projectedList.length,
    );
  }

  String _resolveZoneName(
    List<AsphaltGraffitiClimbZone> zones,
    AsphaltChalkGraffitiDecal decal,
  ) {
    for (final AsphaltGraffitiClimbZone z in zones) {
      if (z.containsDistance(decal.distanceMeters)) {
        return z.name;
      }
    }
    return decal.climbClassification == SegmentClassification.horsCategorie
        ? 'Hors Catégorie'
        : 'Cat 1 Climb';
  }

  void _paintProjectedDecal(Canvas canvas, ProjectedGraffitiDecal item) {
    final AsphaltChalkGraffitiDecal decal = item.decal;
    final double w = item.localPixelWidth;
    final double h = item.localPixelHeight;

    canvas.save();
    canvas.transform(item.homographyMatrix4);

    // 1. Delikatne kropki pyłu kredowego lub rozbryzgów pędzla na asfalcie
    if (config.showChalkDustSpeckles &&
        decal.medium == AsphaltGraffitiMedium.sidewalkChalk) {
      _paintChalkDustSpeckles(
        canvas: canvas,
        width: w,
        height: h,
        color: decal.primaryColor.withValues(alpha: item.effectiveOpacity * 0.35),
        seed: decal.tireWearSeed,
      );
    }

    // 2. Podkreślenie / pasek pędzla pod nazwiskiem lidera GC
    if (decal.category == AsphaltGraffitiCategory.gcLeader) {
      final Paint underlinePaint = Paint()
        ..color = decal.primaryColor.withValues(alpha: item.effectiveOpacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * 0.10, h * 0.88),
        Offset(w * 0.90, h * 0.88),
        underlinePaint,
      );
    }

    // 3. Główny napis rzutowany w płaszczyźnie szosy
    final double fontSize = _computeAdaptiveFontSize(decal.text, w, h);

    // Ciemna obwódka wtopienia w asfalt (dla czytelności)
    final TextPainter outlinePainter = TextPainter(
      text: TextSpan(
        text: decal.text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = decal.medium == AsphaltGraffitiMedium.latexPaint
                ? 7.0
                : 4.5
            ..strokeJoin = StrokeJoin.round
            ..color = decal.outlineColor
                .withValues(alpha: item.effectiveOpacity * 0.45),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: w);

    final TextPainter fillPainter = TextPainter(
      text: TextSpan(
        text: decal.text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 3.0,
          color: decal.primaryColor.withValues(alpha: item.effectiveOpacity),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: w);

    final Offset textOffset = Offset(
      (w - fillPainter.width) * 0.5,
      (h - fillPainter.height) * 0.44,
    );

    outlinePainter.paint(canvas, textOffset);
    fillPainter.paint(canvas, textOffset);

    // 4. Przetarcia od opon rowerów i samochodów technicznych
    if (config.showTireWearStreaks) {
      _paintTireWearStreaks(
        canvas: canvas,
        width: w,
        height: h,
        opacity: item.effectiveOpacity,
        seed: decal.tireWearSeed,
      );
    }

    canvas.restore();
  }

  double _computeAdaptiveFontSize(String text, double w, double h) {
    final int len = math.max(3, text.length);
    final double byWidth = (w * 0.88) / (len * 0.66);
    final double byHeight = h * 0.66;
    return math.min(byWidth, byHeight).clamp(24.0, 68.0);
  }

  void _paintChalkDustSpeckles({
    required Canvas canvas,
    required double width,
    required double height,
    required Color color,
    required int seed,
  }) {
    final math.Random rng = math.Random(seed ^ 0x5F3759DF);
    final Paint speckPaint = Paint()..color = color;
    for (int i = 0; i < 18; i++) {
      final double x = rng.nextDouble() * width;
      final double y = rng.nextDouble() * height;
      final double r = 1.2 + rng.nextDouble() * 2.4;
      canvas.drawCircle(Offset(x, y), r, speckPaint);
    }
  }

  void _paintTireWearStreaks({
    required Canvas canvas,
    required double width,
    required double height,
    required double opacity,
    required int seed,
  }) {
    final math.Random rng = math.Random(seed ^ 0x9E3779B9);
    final Paint streakPaint = Paint()
      ..color = const Color(0xFF1F242D).withValues(alpha: opacity * 0.42)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    final int trackCount = 2 + (rng.nextInt(2));
    for (int i = 0; i < trackCount; i++) {
      final double xBase = width * (0.22 + rng.nextDouble() * 0.56);
      final double skew = (rng.nextDouble() - 0.5) * 14.0;
      canvas.drawLine(
        Offset(xBase, 0.0),
        Offset(xBase + skew, height),
        streakPaint,
      );
    }
  }

  AsphaltGraffitiCategory _pickCategory({
    required int index,
    required math.Random rng,
    required bool hasGcLeader,
    required bool hasFavorites,
  }) {
    if (hasGcLeader && index % 4 == 1) {
      return AsphaltGraffitiCategory.gcLeader;
    }
    if (hasFavorites && index % 4 == 3) {
      return AsphaltGraffitiCategory.stageFavorite;
    }
    final double roll = rng.nextDouble();
    if (hasGcLeader && roll < 0.24) {
      return AsphaltGraffitiCategory.gcLeader;
    }
    if (hasFavorites && roll < 0.46) {
      return AsphaltGraffitiCategory.stageFavorite;
    }
    return AsphaltGraffitiCategory.iconicSlogan;
  }

  String _buildGraffitiText({
    required AsphaltGraffitiCategory category,
    required int index,
    required math.Random rng,
    required String leaderSurname,
    required List<String> favoriteSurnames,
  }) {
    switch (category) {
      case AsphaltGraffitiCategory.gcLeader:
        if (leaderSurname.isEmpty) {
          return iconicSlogans[index % iconicSlogans.length];
        }
        final int variant = rng.nextInt(3);
        if (variant == 0) return leaderSurname;
        if (variant == 1) return 'ALLEZ $leaderSurname!';
        return 'GO $leaderSurname!';
      case AsphaltGraffitiCategory.stageFavorite:
        if (favoriteSurnames.isEmpty) {
          return iconicSlogans[index % iconicSlogans.length];
        }
        final String fav = favoriteSurnames[index % favoriteSurnames.length];
        final int variant = rng.nextInt(3);
        if (variant == 0) return fav;
        if (variant == 1) return 'VAI $fav!';
        return 'ALLEZ $fav!';
      case AsphaltGraffitiCategory.iconicSlogan:
        return iconicSlogans[index % iconicSlogans.length];
    }
  }

  Color _pickDecalColor({
    required AsphaltGraffitiCategory category,
    required AsphaltGraffitiMedium medium,
    required math.Random rng,
  }) {
    if (category == AsphaltGraffitiCategory.gcLeader) {
      // Lider GC wyróżniony kolorem żółtym Tour lub białym
      return rng.nextDouble() < 0.65
          ? const Color(0xFFFACC15)
          : const Color(0xFFF8FAFC);
    }
    final List<Color> palette = medium == AsphaltGraffitiMedium.latexPaint
        ? _paintPalette
        : _chalkPalette;
    return palette[rng.nextInt(palette.length)];
  }

  /// Wylicza dokładną macierz homografii projekcyjnej `4x4` (column-major) mapującą
  /// lokalny prostokąt `[0, srcWidth] x [0, srcHeight]` na rzutowany czworokąt `(p0, p1, p2, p3)`.
  static Float64List? _computeQuadHomographyMatrix4({
    required double srcWidth,
    required double srcHeight,
    required Offset p0,
    required Offset p1,
    required Offset p2,
    required Offset p3,
  }) {
    if (srcWidth <= 0.0 || srcHeight <= 0.0) {
      return null;
    }
    final double x0 = p0.dx;
    final double y0 = p0.dy;
    final double x1 = p1.dx;
    final double y1 = p1.dy;
    final double x2 = p2.dx;
    final double y2 = p2.dy;
    final double x3 = p3.dx;
    final double y3 = p3.dy;

    final double dx1 = x1 - x2;
    final double dy1 = y1 - y2;
    final double dx2 = x3 - x2;
    final double dy2 = y3 - y2;
    final double sx = x0 - x1 + x2 - x3;
    final double sy = y0 - y1 + y2 - y3;

    final double denom = dx1 * dy2 - dx2 * dy1;
    if (denom.abs() < 1e-6) {
      return null;
    }

    final double g = (sx * dy2 - sy * dx2) / denom;
    final double h = (dx1 * sy - dy1 * sx) / denom;

    final double a = (x1 - x0 + g * x1) / srcWidth;
    final double b = (x3 - x0 + h * x3) / srcHeight;
    final double c = x0;

    final double d = (y1 - y0 + g * y1) / srcWidth;
    final double e = (y3 - y0 + h * y3) / srcHeight;
    final double f = y0;

    final double gp = g / srcWidth;
    final double hp = h / srcHeight;

    // Column-major 4x4 matrix dla Canvas.transform
    return Float64List.fromList(<double>[
      a, d, 0.0, gp,
      b, e, 0.0, hp,
      0.0, 0.0, 1.0, 0.0,
      c, f, 0.0, 1.0,
    ]);
  }
}

// =============================================================================
// 4. PRODUKCYJNY PANEL KONTROLNY I PODGLĄD 3D NAPISÓW NA ASFALCIE
// =============================================================================

/// Interaktywny panel konfiguracji i podglądu 3D generatora napisów na asfalcie
/// (`AsphaltChalkGraffitiRenderer`) zgodny z paletą `AppColors`, czcionką `Inter`
/// i responsywnością `390x844` / `1024x768` / `1600x900`.
class AsphaltChalkGraffitiControlPanel extends StatefulWidget {
  final AsphaltChalkGraffitiConfig initialConfig;
  final String initialGcLeaderName;
  final List<String> initialFavoriteNames;
  final ValueChanged<AsphaltChalkGraffitiConfig>? onConfigChanged;

  const AsphaltChalkGraffitiControlPanel({
    super.key,
    this.initialConfig = const AsphaltChalkGraffitiConfig(),
    this.initialGcLeaderName = 'Tadej Pogačar',
    this.initialFavoriteNames = const <String>[
      'Jonas Vingegaard',
      'Remco Evenepoel',
      'Rafał Majka',
    ],
    this.onConfigChanged,
  });

  @override
  State<AsphaltChalkGraffitiControlPanel> createState() =>
      _AsphaltChalkGraffitiControlPanelState();
}

class _AsphaltChalkGraffitiControlPanelState
    extends State<AsphaltChalkGraffitiControlPanel> {
  late AsphaltChalkGraffitiConfig _config;
  late String _gcLeaderName;
  late List<String> _favorites;
  SegmentClassification _previewCategory = SegmentClassification.horsCategorie;
  double _cameraDistanceM = 40.0;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _gcLeaderName = widget.initialGcLeaderName;
    _favorites = List<String>.from(widget.initialFavoriteNames);
  }

  void _updateConfig(AsphaltChalkGraffitiConfig next) {
    setState(() {
      _config = next;
    });
    widget.onConfigChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 680.0;
        final bool isWide = constraints.maxWidth >= 1120.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 14.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildHeader(isCompact),
              const SizedBox(height: 16.0),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 5, child: _buildPreviewViewport()),
                    const SizedBox(width: 20.0),
                    Expanded(flex: 6, child: _buildControlsColumn(isCompact)),
                  ],
                )
              else ...<Widget>[
                _buildPreviewViewport(),
                const SizedBox(height: 16.0),
                _buildControlsColumn(isCompact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12.0,
      runSpacing: 10.0,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.45)),
              ),
              child: const Icon(
                Icons.brush_rounded,
                color: AppColors.goldAccent,
                size: 18.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Napisy na Asfalcie 3D (Cat 1 / HC)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15.0 : 17.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  const Text(
                    'Perspektywiczne napisy farbą i kredą: ALLEZ!, VAI!, GO! oraz lider GC',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _GraffitiActionChip(
          label: _config.enabled ? 'Aktywne' : 'Wyłączone',
          isActive: _config.enabled,
          accentColor: _config.enabled ? AppColors.statusSuccess : AppColors.textSecondary,
          onPressed: () =>
              _updateConfig(_config.copyWith(enabled: !_config.enabled)),
        ),
      ],
    );
  }

  Widget _buildPreviewViewport() {
    final AsphaltChalkGraffitiRenderer renderer =
        AsphaltChalkGraffitiRenderer(config: _config);

    return Container(
      height: 220.0,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _GraffitiRoadPreviewPainter(
                renderer: renderer,
                classification: _previewCategory,
                cameraDistanceM: _cameraDistanceM,
                gcLeaderName: _gcLeaderName,
                favoriteNames: _favorites,
              ),
            ),
          ),
          Positioned(
            top: 10.0,
            left: 10.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: Text(
                _previewCategory == SegmentClassification.horsCategorie
                    ? 'HC • 10.4% • ${_cameraDistanceM.toStringAsFixed(0)} m'
                    : 'CAT 1 • 8.2% • ${_cameraDistanceM.toStringAsFixed(0)} m',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: <ui.FontFeature>[ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsColumn(bool isCompact) {
    final bool enabled = _config.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: <Widget>[
            _GraffitiActionChip(
              label: 'Hors Catégorie (HC)',
              isActive: _previewCategory == SegmentClassification.horsCategorie,
              enabled: enabled,
              accentColor: AppColors.crimsonAlert,
              onPressed: () {
                setState(() {
                  _previewCategory = SegmentClassification.horsCategorie;
                });
              },
            ),
            _GraffitiActionChip(
              label: 'Kategoria 1 (Cat 1)',
              isActive: _previewCategory == SegmentClassification.cat1,
              enabled: enabled,
              accentColor: AppColors.amberWarning,
              onPressed: () {
                setState(() {
                  _previewCategory = SegmentClassification.cat1;
                });
              },
            ),
            _GraffitiActionChip(
              label: 'Ślady opon',
              isActive: _config.showTireWearStreaks,
              enabled: enabled,
              accentColor: AppColors.accentBlue,
              onPressed: () => _updateConfig(
                _config.copyWith(
                    showTireWearStreaks: !_config.showTireWearStreaks),
              ),
            ),
            _GraffitiActionChip(
              label: 'Pył kredowy',
              isActive: _config.showChalkDustSpeckles,
              enabled: enabled,
              accentColor: AppColors.cyanAccent,
              onPressed: () => _updateConfig(
                _config.copyWith(
                    showChalkDustSpeckles: !_config.showChalkDustSpeckles),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),
        _buildSliderRow(
          label: 'Krycie farby / kredy',
          valueLabel: '${(_config.opacityScale * 100).round()}%',
          value: _config.opacityScale,
          min: 0.2,
          max: 1.0,
          enabled: enabled,
          onChanged: (double v) =>
              _updateConfig(_config.copyWith(opacityScale: v)),
        ),
        const SizedBox(height: 8.0),
        _buildSliderRow(
          label: 'Przesunięcie kamery na podjeździe',
          valueLabel: '${_cameraDistanceM.toStringAsFixed(0)} m',
          value: _cameraDistanceM,
          min: 10.0,
          max: 160.0,
          enabled: enabled,
          onChanged: (double v) {
            setState(() {
              _cameraDistanceM = v;
            });
          },
        ),
        const SizedBox(height: 10.0),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 6.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const Text(
                'Lider GC:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                AsphaltChalkGraffitiRenderer.extractRiderSurname(_gcLeaderName),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                ),
              ),
              const Text(
                '• Faworyci:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _favorites
                    .map(AsphaltChalkGraffitiRenderer.extractRiderSurname)
                    .join(', '),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueLabel,
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
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  color:
                      enabled ? AppColors.textSecondary : AppColors.textMuted,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                fontFeatures: const <ui.FontFeature>[
                  ui.FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor:
                enabled ? AppColors.primaryAccent : const Color(0xFF2A2F3D),
            inactiveTrackColor: const Color(0xFF2A2F3D),
            thumbColor:
                enabled ? AppColors.goldAccent : AppColors.textSecondary,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
            trackHeight: 3.0,
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

class _GraffitiActionChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _GraffitiActionChip({
    required this.label,
    required this.isActive,
    this.enabled = true,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_GraffitiActionChip> createState() => _GraffitiActionChipState();
}

class _GraffitiActionChipState extends State<_GraffitiActionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final Color borderColor = !enabled
        ? const Color(0xFF2A2F3D)
        : _focused
            ? AppColors.goldAccent
            : widget.isActive
                ? widget.accentColor
                : _hovered
                    ? AppColors.textSecondary
                    : const Color(0xFF2A2F3D);

    final Color bgColor = !enabled
        ? AppColors.surface
        : widget.isActive
            ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.97 : 1.0,
              _pressed ? 0.97 : 1.0,
              1.0,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.0,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: !enabled
                    ? AppColors.textMuted.withValues(alpha: 0.45)
                    : widget.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GraffitiRoadPreviewPainter extends CustomPainter {
  final AsphaltChalkGraffitiRenderer renderer;
  final SegmentClassification classification;
  final double cameraDistanceM;
  final String gcLeaderName;
  final List<String> favoriteNames;

  const _GraffitiRoadPreviewPainter({
    required this.renderer,
    required this.classification,
    required this.cameraDistanceM,
    required this.gcLeaderName,
    required this.favoriteNames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double grad =
        classification == SegmentClassification.horsCategorie ? 10.4 : 8.2;
    final RoadGeometryParameters road = RoadGeometryParameters(
      gradientPercent: grad,
      roadWidthMeters: 7.2,
    );

    double elevationAt(double d) => d * (grad / 100.0);

    final Cyclist3DPose camAnchor = Scene3DMathProjection.courseToCyclistPose(
      coursePosition: CoursePosition(
        distanceMeters: cameraDistanceM,
        lateralOffsetMeters: 0.0,
        elevationMeters: elevationAt(cameraDistanceM),
      ),
      roadGeometry: road,
    );

    final Vector3 camPos = camAnchor.position +
        camAnchor.surfaceNormal * 3.4 -
        camAnchor.tangent * 2.0;
    final Vector3 camTarget = camAnchor.position +
        camAnchor.tangent * 28.0 +
        camAnchor.surfaceNormal * 0.6;

    final Scene3DMathProjection projection = Scene3DMathProjection(
      viewportWidth: size.width,
      viewportHeight: size.height,
    );
    projection.setView(
      eye: camPos,
      target: camTarget,
      up: Vector3(0.0, 1.0, 0.0),
    );

    // Tło nieba alpejskiego i asfaltu szosy
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF151922), Color(0xFF0F1115)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Wstęga szosy w 3D
    final Path roadPath = Path();
    final List<Offset> leftPts = <Offset>[];
    final List<Offset> rightPts = <Offset>[];
    for (int i = 0; i <= 20; i++) {
      final double d = cameraDistanceM + 3.0 + i * 6.5;
      final Cyclist3DPose lPose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: CoursePosition(
          distanceMeters: d,
          lateralOffsetMeters: -3.6,
          elevationMeters: elevationAt(d),
        ),
        roadGeometry: road,
      );
      final Cyclist3DPose rPose = Scene3DMathProjection.courseToCyclistPose(
        coursePosition: CoursePosition(
          distanceMeters: d,
          lateralOffsetMeters: 3.6,
          elevationMeters: elevationAt(d),
        ),
        roadGeometry: road,
      );
      final ProjectedPoint3D lp = projection.worldToScreen(lPose.position);
      final ProjectedPoint3D rp = projection.worldToScreen(rPose.position);
      if (lp.isInFrontOfCamera && rp.isInFrontOfCamera) {
        leftPts.add(Offset(lp.screenX, lp.screenY));
        rightPts.add(Offset(rp.screenX, rp.screenY));
      }
    }

    if (leftPts.length >= 2) {
      roadPath.moveTo(leftPts.first.dx, leftPts.first.dy);
      for (int i = 1; i < leftPts.length; i++) {
        roadPath.lineTo(leftPts[i].dx, leftPts[i].dy);
      }
      for (int i = rightPts.length - 1; i >= 0; i--) {
        roadPath.lineTo(rightPts[i].dx, rightPts[i].dy);
      }
      roadPath.close();
      canvas.drawPath(roadPath, Paint()..color = const Color(0xFF262A34));

      final Paint edgePaint = Paint()
        ..color = const Color(0xFFF3F4F6).withValues(alpha: 0.35)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < leftPts.length - 1; i++) {
        canvas.drawLine(leftPts[i], leftPts[i + 1], edgePaint);
        canvas.drawLine(rightPts[i], rightPts[i + 1], edgePaint);
      }
    }

    renderer.paint(
      canvas: canvas,
      size: size,
      projection: projection,
      roadGeometry: road,
      cameraCourseDistanceMeters: cameraDistanceM,
      elevationAtDistance: elevationAt,
      fallbackClassification: classification,
      gcLeaderName: gcLeaderName,
      stageFavoriteNames: favoriteNames,
    );
  }

  @override
  bool shouldRepaint(covariant _GraffitiRoadPreviewPainter oldDelegate) {
    return oldDelegate.renderer.config != renderer.config ||
        oldDelegate.classification != classification ||
        oldDelegate.cameraDistanceM != cameraDistanceM ||
        oldDelegate.gcLeaderName != gcLeaderName;
  }
}
