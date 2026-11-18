// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. REGIONY KIBICÓW, TYPY BANERÓW I KONFIGURACJA 3D
// =============================================================================

/// Wzór graficzny flagi regionu kolarskiego.
enum SpectatorFlagPattern {
  horizontalStripes,
  verticalStripes,
  nordicCross,
  ikurrinaDoubleCross,
  flandersLionEmblem,
  brittanyGwennHaDu,
}

/// Kultowe flagi regionów i nacji kolarskich widoczne przy trasach Grand Tourów i Klasyków.
enum SpectatorRegionFlag {
  flanders(
    code: 'VL',
    labelPl: 'Flandria',
    pattern: SpectatorFlagPattern.flandersLionEmblem,
    colors: <Color>[Color(0xFFFACC15), Color(0xFF111827), Color(0xFFDC2626)],
  ),
  basqueCountry(
    code: 'EUS',
    labelPl: 'Kraj Basków',
    pattern: SpectatorFlagPattern.ikurrinaDoubleCross,
    colors: <Color>[Color(0xFFD52B1E), Color(0xFF009B48), Color(0xFFF3F4F6)],
  ),
  brittany(
    code: 'BZH',
    labelPl: 'Bretania',
    pattern: SpectatorFlagPattern.brittanyGwennHaDu,
    colors: <Color>[Color(0xFF111827), Color(0xFFF3F4F6)],
  ),
  catalonia(
    code: 'CAT',
    labelPl: 'Katalonia',
    pattern: SpectatorFlagPattern.horizontalStripes,
    colors: <Color>[
      Color(0xFFFACC15),
      Color(0xFFDC2626),
      Color(0xFFFACC15),
      Color(0xFFDC2626),
      Color(0xFFFACC15),
    ],
  ),
  poland(
    code: 'PL',
    labelPl: 'Polska',
    pattern: SpectatorFlagPattern.horizontalStripes,
    colors: <Color>[Color(0xFFF3F4F6), Color(0xFFDC143C)],
  ),
  netherlands(
    code: 'NL',
    labelPl: 'Holandia',
    pattern: SpectatorFlagPattern.horizontalStripes,
    colors: <Color>[Color(0xFFAE1C28), Color(0xFFF3F4F6), Color(0xFF21468B)],
  ),
  slovenia(
    code: 'SI',
    labelPl: 'Słowenia',
    pattern: SpectatorFlagPattern.horizontalStripes,
    colors: <Color>[Color(0xFFF3F4F6), Color(0xFF005DA4), Color(0xFFED1C24)],
  ),
  denmark(
    code: 'DK',
    labelPl: 'Dania',
    pattern: SpectatorFlagPattern.nordicCross,
    colors: <Color>[Color(0xFFC8102E), Color(0xFFF3F4F6)],
  ),
  colombia(
    code: 'CO',
    labelPl: 'Kolumbia',
    pattern: SpectatorFlagPattern.horizontalStripes,
    colors: <Color>[Color(0xFFFCD116), Color(0xFF003893), Color(0xFFCE1126)],
  ),
  france(
    code: 'FR',
    labelPl: 'Francja',
    pattern: SpectatorFlagPattern.verticalStripes,
    colors: <Color>[Color(0xFF0055A4), Color(0xFFF3F4F6), Color(0xFFEF4135)],
  ),
  italy(
    code: 'IT',
    labelPl: 'Włochy',
    pattern: SpectatorFlagPattern.verticalStripes,
    colors: <Color>[Color(0xFF009246), Color(0xFFF3F4F6), Color(0xFFCE2B37)],
  );

  final String code;
  final String labelPl;
  final SpectatorFlagPattern pattern;
  final List<Color> colors;

  const SpectatorRegionFlag({
    required this.code,
    required this.labelPl,
    required this.pattern,
    required this.colors,
  });
}

/// Rodzaj proceduralnego elementu kibicowskiego przy trasie 3D.
enum SpectatorBannerKind {
  /// Ręcznie malowany transparent płócienny z nazwiskiem lidera gracza.
  handPaintedCloth(labelPl: 'Transparent płócienny'),

  /// Szeroki baner rozwieszony na barierkach z nazwiskiem i akcentem drużyny.
  overheadFenceTifo(labelPl: 'Baner na barierce'),

  /// Powiewająca na wietrze flaga regionu na teleskopowym maszcie.
  wavingRegionFlag(labelPl: 'Flaga regionu'),

  /// Kartonowa tabliczka trzymana przez kibica przy krawędzi asfaltu.
  cardboardCutoutSign(labelPl: 'Tabliczka kibica');

  final String labelPl;

  const SpectatorBannerKind({required this.labelPl});
}

/// Parametry wiatru napędzające fizykę łopotania flag i banerów 3D.
@immutable
class SpectatorBannerWindProfile {
  final double windSpeedMs;
  final double windDirectionRadians;
  final double gustTurbulence;

  const SpectatorBannerWindProfile({
    this.windSpeedMs = 5.5,
    this.windDirectionRadians = 0.65,
    this.gustTurbulence = 0.35,
  });

  SpectatorBannerWindProfile copyWith({
    double? windSpeedMs,
    double? windDirectionRadians,
    double? gustTurbulence,
  }) {
    return SpectatorBannerWindProfile(
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      windDirectionRadians: windDirectionRadians ?? this.windDirectionRadians,
      gustTurbulence: gustTurbulence ?? this.gustTurbulence,
    );
  }
}

/// Konfiguracja generatora i renderera proceduralnych banerów i flag kibiców 3D.
@immutable
class DynamicSpectatorBannerConfig {
  final bool enabled;
  final String leaderSurname;
  final String leaderFirstName;
  final Color leaderJerseyColor;
  final Color teamAccentColor;
  final SpectatorRegionFlag primaryRegion;
  final List<SpectatorRegionFlag> secondaryRegions;
  final double densityPer100m;
  final double minRenderDistanceMeters;
  final double maxRenderDistanceMeters;
  final bool enableClothWaveAnimation;
  final bool enableOverheadTifo;
  final int stageSeed;

  const DynamicSpectatorBannerConfig({
    this.enabled = true,
    this.leaderSurname = 'KOWALSKI',
    this.leaderFirstName = 'Jan',
    this.leaderJerseyColor = AppColors.goldAccent,
    this.teamAccentColor = AppColors.primaryAccent,
    this.primaryRegion = SpectatorRegionFlag.poland,
    this.secondaryRegions = const <SpectatorRegionFlag>[
      SpectatorRegionFlag.flanders,
      SpectatorRegionFlag.basqueCountry,
      SpectatorRegionFlag.france,
      SpectatorRegionFlag.slovenia,
    ],
    this.densityPer100m = 6.5,
    this.minRenderDistanceMeters = 1.8,
    this.maxRenderDistanceMeters = 210.0,
    this.enableClothWaveAnimation = true,
    this.enableOverheadTifo = true,
    this.stageSeed = 63401,
  });

  /// Zwraca bezpieczne, wielkie nazwisko lidera (z fallbackiem na wypadek pustego tekstu).
  String get normalizedLeaderSurname {
    final String trimmed = leaderSurname.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return 'LIDER';
    }
    if (trimmed.length > 16) {
      return trimmed.substring(0, 16);
    }
    return trimmed;
  }

  DynamicSpectatorBannerConfig copyWith({
    bool? enabled,
    String? leaderSurname,
    String? leaderFirstName,
    Color? leaderJerseyColor,
    Color? teamAccentColor,
    SpectatorRegionFlag? primaryRegion,
    List<SpectatorRegionFlag>? secondaryRegions,
    double? densityPer100m,
    double? minRenderDistanceMeters,
    double? maxRenderDistanceMeters,
    bool? enableClothWaveAnimation,
    bool? enableOverheadTifo,
    int? stageSeed,
  }) {
    return DynamicSpectatorBannerConfig(
      enabled: enabled ?? this.enabled,
      leaderSurname: leaderSurname ?? this.leaderSurname,
      leaderFirstName: leaderFirstName ?? this.leaderFirstName,
      leaderJerseyColor: leaderJerseyColor ?? this.leaderJerseyColor,
      teamAccentColor: teamAccentColor ?? this.teamAccentColor,
      primaryRegion: primaryRegion ?? this.primaryRegion,
      secondaryRegions: secondaryRegions ?? this.secondaryRegions,
      densityPer100m: densityPer100m ?? this.densityPer100m,
      minRenderDistanceMeters:
          minRenderDistanceMeters ?? this.minRenderDistanceMeters,
      maxRenderDistanceMeters:
          maxRenderDistanceMeters ?? this.maxRenderDistanceMeters,
      enableClothWaveAnimation:
          enableClothWaveAnimation ?? this.enableClothWaveAnimation,
      enableOverheadTifo: enableOverheadTifo ?? this.enableOverheadTifo,
      stageSeed: stageSeed ?? this.stageSeed,
    );
  }
}

/// Pojedynczy obiekt banera lub flagi osadzony w przestrzeni 3D wzdłuż trasy.
@immutable
class SpectatorBannerInstance3D {
  final String id;
  final SpectatorBannerKind kind;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final double heightAboveGroundMeters;
  final double widthMeters;
  final double heightMeters;
  final double poleHeightMeters;
  final double yawRadians;
  final SpectatorRegionFlag regionFlag;
  final String bannerText;
  final String subText;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final double wavePhaseOffset;

  const SpectatorBannerInstance3D({
    required this.id,
    required this.kind,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.elevationMeters,
    required this.heightAboveGroundMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.poleHeightMeters,
    required this.yawRadians,
    required this.regionFlag,
    required this.bannerText,
    required this.subText,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.wavePhaseOffset,
  });
}

/// Zestaw wygenerowanych banerów i flag dla etapu z szybkim wyszukiwaniem zakresu dystansu.
class DynamicSpectatorBannersPack {
  final List<SpectatorBannerInstance3D> instances;
  final String activeLeaderName;
  final SpectatorRegionFlag dominantRegion;

  DynamicSpectatorBannersPack({
    required List<SpectatorBannerInstance3D> instances,
    required this.activeLeaderName,
    required this.dominantRegion,
  }) : instances = List<SpectatorBannerInstance3D>.unmodifiable(instances);

  /// Szybkie wyszukiwanie obiektów w oknie `[minDist, maxDist]` za pomocą wyszukiwania binarnego.
  List<SpectatorBannerInstance3D> queryVisibleRange(
    double minDist,
    double maxDist,
  ) {
    if (instances.isEmpty || maxDist < minDist) {
      return const <SpectatorBannerInstance3D>[];
    }

    int lo = 0;
    int hi = instances.length;
    while (lo < hi) {
      final int mid = (lo + hi) >> 1;
      if (instances[mid].distanceMeters < minDist) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }

    final List<SpectatorBannerInstance3D> result =
        <SpectatorBannerInstance3D>[];
    for (int i = lo; i < instances.length; i++) {
      final SpectatorBannerInstance3D item = instances[i];
      if (item.distanceMeters > maxDist) {
        break;
      }
      result.add(item);
    }
    return result;
  }
}

/// Telemetria pojedynczej klatki renderowania banerów i flag kibiców.
@immutable
class SpectatorBannersTelemetry {
  final int totalGenerated;
  final int visibleInFrame;
  final int bannersRendered;
  final int flagsRendered;
  final String activeLeaderName;
  final SpectatorRegionFlag dominantRegion;

  const SpectatorBannersTelemetry({
    required this.totalGenerated,
    required this.visibleInFrame,
    required this.bannersRendered,
    required this.flagsRendered,
    required this.activeLeaderName,
    required this.dominantRegion,
  });

  static const SpectatorBannersTelemetry empty = SpectatorBannersTelemetry(
    totalGenerated: 0,
    visibleInFrame: 0,
    bannersRendered: 0,
    flagsRendered: 0,
    activeLeaderName: 'LIDER',
    dominantRegion: SpectatorRegionFlag.poland,
  );
}

// =============================================================================
// 2. GENERATOR PROCEDURALNY I RENDERER 3D CANVAS
// =============================================================================

/// Proceduralny generator i renderer 3D banerów kibiców z nazwiskiem lidera gracza
/// oraz powiewających flag regionów kolarskich.
class DynamicSpectatorBannersAndFlags3dRenderer {
  static const List<String> _cheerPrefixes = <String>[
    'ALLEZ',
    'GO',
    'VAI',
    'VAMOS',
    'DAWAJ',
    'HUP',
  ];

  static const List<String> _cheerSuffixes = <String>[
    'KING OF THE ROAD',
    'FULL GAS!',
    'CAPTAIN',
    'NO MERCY',
    '100% WATTS',
    'LEGEND',
  ];

  // Ograniczona pamięć podręczna TextPainter dla napisów na banerach (Zero-GC w pętli).
  final Map<String, TextPainter> _textPainterCache = <String, TextPainter>{};

  /// Generuje deterministyczny zestaw banerów i flag wzdłuż podanych segmentów trasy
  /// (lub w zadanym zakresie `[startDistanceMeters, endDistanceMeters]`).
  DynamicSpectatorBannersPack generateStageBanners({
    required DynamicSpectatorBannerConfig config,
    List<StageSegment> segments = const <StageSegment>[],
    double startDistanceMeters = 0.0,
    double endDistanceMeters = 5000.0,
    double roadHalfWidthMeters = 3.6,
  }) {
    final String leader = config.normalizedLeaderSurname;
    if (!config.enabled) {
      return DynamicSpectatorBannersPack(
        instances: const <SpectatorBannerInstance3D>[],
        activeLeaderName: leader,
        dominantRegion: config.primaryRegion,
      );
    }

    final math.Random rng = math.Random(config.stageSeed ^ leader.hashCode);
    final List<SpectatorBannerInstance3D> items = <SpectatorBannerInstance3D>[];

    final double safeStart = math.max(0.0, startDistanceMeters);
    final double safeEnd = math.max(safeStart + 50.0, endDistanceMeters);
    final double totalLength = safeEnd - safeStart;

    final double clampedDensity = config.densityPer100m.clamp(1.0, 20.0);
    final double baseSpacing = 100.0 / clampedDensity;

    final List<SpectatorRegionFlag> regionPool = <SpectatorRegionFlag>[
      config.primaryRegion,
      config.primaryRegion,
      config.primaryRegion,
      ...config.secondaryRegions,
    ];

    double cursor = safeStart + 8.0;
    int index = 0;

    while (cursor < safeEnd && index < 2500) {
      final StageSegment? seg = _findSegmentAt(segments, cursor);
      final double gradient = seg?.gradientPercent ?? 0.0;
      final bool isCobble = seg != null &&
          seg.surfaceType.name.startsWith('cobblestones');
      final bool isClimbOrHotspot = gradient.abs() >= 5.0 ||
          isCobble ||
          (totalLength - (cursor - safeStart)) < 600.0;

      // Na podjazdach, bruku i przy mecie zagęszczenie kibiców rośnie 1.6x.
      final double effectiveSpacing =
          isClimbOrHotspot ? baseSpacing * 0.62 : baseSpacing;

      final bool leftSide = rng.nextBool();
      final double sideSign = leftSide ? -1.0 : 1.0;
      final double lateral =
          sideSign * (roadHalfWidthMeters + 0.85 + rng.nextDouble() * 2.1);
      final double elevation =
          seg != null ? seg.startElevationM + gradient * 0.15 : 0.0;

      final SpectatorRegionFlag flag =
          regionPool[rng.nextInt(regionPool.length)];
      final SpectatorBannerKind kind = _pickKind(
        rng: rng,
        allowTifo: config.enableOverheadTifo,
        isHotspot: isClimbOrHotspot,
      );

      final String prefix =
          _cheerPrefixes[rng.nextInt(_cheerPrefixes.length)];
      final String suffix =
          _cheerSuffixes[rng.nextInt(_cheerSuffixes.length)];

      late final double widthM;
      late final double heightM;
      late final double heightAboveGroundM;
      late final double poleHeightM;
      late final String mainText;
      late final String subText;
      late final Color primaryCol;
      late final Color accentCol;
      late final Color textCol;

      switch (kind) {
        case SpectatorBannerKind.wavingRegionFlag:
          widthM = 1.35 + rng.nextDouble() * 0.55;
          heightM = widthM * 0.66;
          poleHeightM = 2.6 + rng.nextDouble() * 1.4;
          heightAboveGroundM = poleHeightM - heightM;
          mainText = flag.code;
          subText = leader;
          primaryCol = flag.colors.first;
          accentCol = flag.colors.length > 1
              ? flag.colors[1]
              : config.teamAccentColor;
          textCol = AppColors.textPrimary;
        case SpectatorBannerKind.handPaintedCloth:
          widthM = 2.4 + rng.nextDouble() * 1.2;
          heightM = 0.95 + rng.nextDouble() * 0.25;
          poleHeightM = 2.2;
          heightAboveGroundM = 1.15 + rng.nextDouble() * 0.45;
          mainText = '$prefix $leader!';
          subText = suffix;
          primaryCol = const Color(0xFFF3F4F6);
          accentCol = config.leaderJerseyColor;
          textCol = const Color(0xFF111827);
        case SpectatorBannerKind.overheadFenceTifo:
          widthM = 3.4 + rng.nextDouble() * 1.1;
          heightM = 0.88;
          poleHeightM = 0.0;
          heightAboveGroundM = 0.22;
          mainText = leader;
          subText = '${config.leaderFirstName.toUpperCase()} • $prefix!';
          primaryCol = config.teamAccentColor;
          accentCol = config.leaderJerseyColor;
          textCol = AppColors.textPrimary;
        case SpectatorBannerKind.cardboardCutoutSign:
          widthM = 0.95 + rng.nextDouble() * 0.35;
          heightM = 0.72;
          poleHeightM = 0.0;
          heightAboveGroundM = 1.45 + rng.nextDouble() * 0.35;
          mainText = leader;
          subText = '#1';
          primaryCol = AppColors.surfaceLight;
          accentCol = config.leaderJerseyColor;
          textCol = AppColors.goldAccent;
      }

      items.add(
        SpectatorBannerInstance3D(
          id: 'spec_banner_${index}_${cursor.toStringAsFixed(0)}',
          kind: kind,
          distanceMeters: cursor,
          lateralOffsetMeters: lateral,
          elevationMeters: elevation,
          heightAboveGroundMeters: heightAboveGroundM,
          widthMeters: widthM,
          heightMeters: heightM,
          poleHeightMeters: poleHeightM,
          yawRadians: leftSide ? 0.14 : -0.14,
          regionFlag: flag,
          bannerText: mainText,
          subText: subText,
          primaryColor: primaryCol,
          accentColor: accentCol,
          textColor: textCol,
          wavePhaseOffset: rng.nextDouble() * math.pi * 2.0,
        ),
      );

      cursor += effectiveSpacing * (0.65 + rng.nextDouble() * 0.75);
      index++;
    }

    items.sort(
      (SpectatorBannerInstance3D a, SpectatorBannerInstance3D b) =>
          a.distanceMeters.compareTo(b.distanceMeters),
    );

    return DynamicSpectatorBannersPack(
      instances: items,
      activeLeaderName: leader,
      dominantRegion: config.primaryRegion,
    );
  }

  SpectatorBannerKind _pickKind({
    required math.Random rng,
    required bool allowTifo,
    required bool isHotspot,
  }) {
    final double roll = rng.nextDouble();
    if (roll < 0.42) {
      return SpectatorBannerKind.wavingRegionFlag;
    }
    if (roll < 0.70) {
      return SpectatorBannerKind.handPaintedCloth;
    }
    if (allowTifo && (roll < 0.88 || isHotspot && roll < 0.92)) {
      return SpectatorBannerKind.overheadFenceTifo;
    }
    return SpectatorBannerKind.cardboardCutoutSign;
  }

  StageSegment? _findSegmentAt(List<StageSegment> segments, double distMeters) {
    if (segments.isEmpty) {
      return null;
    }
    final double distKm = distMeters / 1000.0;
    for (final StageSegment seg in segments) {
      if (distKm >= seg.startKm && distKm <= seg.endKm) {
        return seg;
      }
    }
    return segments.last;
  }

  /// Renderuje widoczne banery i flagi 3D na przekazanym [Canvas] używając rzutowania
  /// perspektywicznego [Scene3DMathProjection].
  SpectatorBannersTelemetry render({
    required Canvas canvas,
    required Size size,
    required Scene3DMathProjection projection,
    required DynamicSpectatorBannersPack pack,
    required DynamicSpectatorBannerConfig config,
    required double cameraDistanceMeters,
    required double animationTimeSeconds,
    SpectatorBannerWindProfile wind = const SpectatorBannerWindProfile(),
    RoadGeometryParameters roadGeometry = const RoadGeometryParameters(),
  }) {
    if (!config.enabled || pack.instances.isEmpty) {
      return SpectatorBannersTelemetry(
        totalGenerated: pack.instances.length,
        visibleInFrame: 0,
        bannersRendered: 0,
        flagsRendered: 0,
        activeLeaderName: pack.activeLeaderName,
        dominantRegion: pack.dominantRegion,
      );
    }

    final double minQuery =
        math.max(0.0, cameraDistanceMeters - 12.0);
    final double maxQuery =
        cameraDistanceMeters + config.maxRenderDistanceMeters;

    final List<SpectatorBannerInstance3D> candidates =
        pack.queryVisibleRange(minQuery, maxQuery);

    final List<_ProjectedBannerItem> projectedList = <_ProjectedBannerItem>[];

    for (final SpectatorBannerInstance3D item in candidates) {
      final Vector3 baseWorld = Scene3DMathProjection.courseToWorld3D(
        distanceMeters: item.distanceMeters - cameraDistanceMeters,
        lateralOffsetMeters: item.lateralOffsetMeters,
        elevationMeters: item.elevationMeters,
        turningRadiusMeters: roadGeometry.turningRadiusMeters,
        gradientPercent: roadGeometry.gradientPercent,
        baseBearingRadians: roadGeometry.roadBearingRadians,
        bankingAngleRadians: roadGeometry.bankingAngleRadians,
        verticalOffsetMeters: item.heightAboveGroundMeters,
      );

      final ProjectedPoint3D projectedCenter =
          projection.worldToScreen(baseWorld);
      if (!projectedCenter.isInFrontOfCamera) {
        continue;
      }
      if (projectedCenter.depthEye < config.minRenderDistanceMeters ||
          projectedCenter.depthEye > config.maxRenderDistanceMeters) {
        continue;
      }

      // Oblicz rzutowaną szerokość i wysokość w pikselach na podstawie skali perspektywicznej.
      final double pxPerMeter =
          (size.height * 0.42) / math.max(1.0, projectedCenter.depthEye);
      final double drawWidth = item.widthMeters * pxPerMeter;
      final double drawHeight = item.heightMeters * pxPerMeter;

      if (drawWidth < 4.0 || drawHeight < 3.0) {
        continue;
      }
      if (projectedCenter.screenX + drawWidth < -40.0 ||
          projectedCenter.screenX - drawWidth > size.width + 40.0 ||
          projectedCenter.screenY + drawHeight < -40.0 ||
          projectedCenter.screenY - drawHeight > size.height + 40.0) {
        continue;
      }

      projectedList.add(
        _ProjectedBannerItem(
          instance: item,
          projected: projectedCenter,
          drawWidth: drawWidth,
          drawHeight: drawHeight,
          pxPerMeter: pxPerMeter,
        ),
      );
    }

    // Sortowanie od najdalszych do najbliższych (Painter's Algorithm).
    projectedList.sort(
      (_ProjectedBannerItem a, _ProjectedBannerItem b) =>
          b.projected.depthEye.compareTo(a.projected.depthEye),
    );

    int bannersCount = 0;
    int flagsCount = 0;

    for (final _ProjectedBannerItem p in projectedList) {
      final double distanceFade = (1.0 -
              ((p.projected.depthEye - config.maxRenderDistanceMeters * 0.72) /
                  (config.maxRenderDistanceMeters * 0.28)))
          .clamp(0.0, 1.0);

      if (p.instance.kind == SpectatorBannerKind.wavingRegionFlag) {
        _drawWavingRegionFlag(
          canvas: canvas,
          item: p,
          animationTimeSeconds:
              config.enableClothWaveAnimation ? animationTimeSeconds : 0.0,
          wind: wind,
          opacity: distanceFade,
        );
        flagsCount++;
      } else {
        _drawLeaderBanner(
          canvas: canvas,
          item: p,
          animationTimeSeconds:
              config.enableClothWaveAnimation ? animationTimeSeconds : 0.0,
          wind: wind,
          opacity: distanceFade,
        );
        bannersCount++;
      }
    }

    return SpectatorBannersTelemetry(
      totalGenerated: pack.instances.length,
      visibleInFrame: projectedList.length,
      bannersRendered: bannersCount,
      flagsRendered: flagsCount,
      activeLeaderName: pack.activeLeaderName,
      dominantRegion: pack.dominantRegion,
    );
  }

  void _drawWavingRegionFlag({
    required Canvas canvas,
    required _ProjectedBannerItem item,
    required double animationTimeSeconds,
    required SpectatorBannerWindProfile wind,
    required double opacity,
  }) {
    final SpectatorBannerInstance3D inst = item.instance;
    final double cx = item.projected.screenX;
    final double topY = item.projected.screenY - item.drawHeight;
    final double w = item.drawWidth;
    final double h = item.drawHeight;
    final double poleH = inst.poleHeightMeters * item.pxPerMeter;

    // 1. Maszt teleskopowy
    final Paint polePaint = Paint()
      ..color = const Color(0xFFD1D5DB).withValues(alpha: 0.9 * opacity)
      ..strokeWidth = math.max(1.2, item.pxPerMeter * 0.045)
      ..strokeCap = StrokeCap.round;

    final double poleX = cx - w * 0.5;
    canvas.drawLine(
      Offset(poleX, topY + poleH),
      Offset(poleX, topY - 2.0),
      polePaint,
    );

    // 2. Powiewające płótno flagi w 6 segmentach fali
    const int strips = 6;
    final double stripW = w / strips;
    final double waveAmp =
        (0.04 + wind.windSpeedMs * 0.014) * h * (0.7 + wind.gustTurbulence);
    final double waveFreq = 3.2 + wind.windSpeedMs * 0.45;

    for (int i = 0; i < strips; i++) {
      final double t0 = i / strips;
      final double t1 = (i + 1) / strips;
      final double phase0 =
          animationTimeSeconds * waveFreq - t0 * 4.2 + inst.wavePhaseOffset;
      final double phase1 =
          animationTimeSeconds * waveFreq - t1 * 4.2 + inst.wavePhaseOffset;

      final double dy0 = math.sin(phase0) * waveAmp * t0;
      final double dy1 = math.sin(phase1) * waveAmp * t1;
      final double shade = 0.88 + 0.12 * math.cos(phase0);

      final Rect stripRect = Rect.fromLTWH(
        poleX + i * stripW,
        topY + (dy0 + dy1) * 0.5,
        stripW + 0.6,
        h,
      );

      _paintFlagPatternStrip(
        canvas: canvas,
        fullRect: Rect.fromLTWH(poleX, stripRect.top, w, h),
        clipRect: stripRect,
        flag: inst.regionFlag,
        shade: shade,
        opacity: opacity,
      );
    }

    // Obramowanie subtelne płótna przy bliskim dystansie
    if (w > 22.0) {
      final Paint borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.28 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(Rect.fromLTWH(poleX, topY, w, h), borderPaint);
    }
  }

  void _paintFlagPatternStrip({
    required Canvas canvas,
    required Rect fullRect,
    required Rect clipRect,
    required SpectatorRegionFlag flag,
    required double shade,
    required double opacity,
  }) {
    canvas.save();
    canvas.clipRect(clipRect);

    final List<Color> cols = flag.colors;
    Color applyShade(Color c) {
      final int r = ((c.r * 255.0) * shade).round().clamp(0, 255);
      final int g = ((c.g * 255.0) * shade).round().clamp(0, 255);
      final int b = ((c.b * 255.0) * shade).round().clamp(0, 255);
      return Color.fromARGB((opacity * 255).round().clamp(0, 255), r, g, b);
    }

    switch (flag.pattern) {
      case SpectatorFlagPattern.horizontalStripes:
        final double bandH = fullRect.height / cols.length;
        for (int b = 0; b < cols.length; b++) {
          canvas.drawRect(
            Rect.fromLTWH(
              fullRect.left,
              fullRect.top + b * bandH,
              fullRect.width,
              bandH + 0.5,
            ),
            Paint()..color = applyShade(cols[b]),
          );
        }
      case SpectatorFlagPattern.verticalStripes:
        final double bandW = fullRect.width / cols.length;
        for (int b = 0; b < cols.length; b++) {
          canvas.drawRect(
            Rect.fromLTWH(
              fullRect.left + b * bandW,
              fullRect.top,
              bandW + 0.5,
              fullRect.height,
            ),
            Paint()..color = applyShade(cols[b]),
          );
        }
      case SpectatorFlagPattern.nordicCross:
        canvas.drawRect(fullRect, Paint()..color = applyShade(cols[0]));
        final Paint crossPaint = Paint()..color = applyShade(cols[1]);
        canvas.drawRect(
          Rect.fromLTWH(
            fullRect.left,
            fullRect.top + fullRect.height * 0.40,
            fullRect.width,
            fullRect.height * 0.20,
          ),
          crossPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            fullRect.left + fullRect.width * 0.30,
            fullRect.top,
            fullRect.width * 0.16,
            fullRect.height,
          ),
          crossPaint,
        );
      case SpectatorFlagPattern.ikurrinaDoubleCross:
        canvas.drawRect(fullRect, Paint()..color = applyShade(cols[0]));
        final Paint greenDiag = Paint()
          ..color = applyShade(cols[1])
          ..strokeWidth = fullRect.height * 0.18;
        canvas.drawLine(fullRect.topLeft, fullRect.bottomRight, greenDiag);
        canvas.drawLine(fullRect.bottomLeft, fullRect.topRight, greenDiag);
        final Paint whiteCross = Paint()..color = applyShade(cols[2]);
        canvas.drawRect(
          Rect.fromLTWH(
            fullRect.left,
            fullRect.top + fullRect.height * 0.42,
            fullRect.width,
            fullRect.height * 0.16,
          ),
          whiteCross,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            fullRect.left + fullRect.width * 0.43,
            fullRect.top,
            fullRect.width * 0.14,
            fullRect.height,
          ),
          whiteCross,
        );
      case SpectatorFlagPattern.flandersLionEmblem:
        canvas.drawRect(fullRect, Paint()..color = applyShade(cols[0]));
        final Offset center = fullRect.center;
        final double emblemR = math.min(fullRect.width, fullRect.height) * 0.28;
        canvas.drawCircle(center, emblemR, Paint()..color = applyShade(cols[1]));
        canvas.drawCircle(
          center.translate(emblemR * 0.28, -emblemR * 0.15),
          emblemR * 0.24,
          Paint()..color = applyShade(cols[2]),
        );
      case SpectatorFlagPattern.brittanyGwennHaDu:
        const int stripeCount = 9;
        final double stripeH = fullRect.height / stripeCount;
        for (int s = 0; s < stripeCount; s++) {
          final Color col = s.isEven ? cols[0] : cols[1];
          canvas.drawRect(
            Rect.fromLTWH(
              fullRect.left,
              fullRect.top + s * stripeH,
              fullRect.width,
              stripeH + 0.5,
            ),
            Paint()..color = applyShade(col),
          );
        }
        final Rect canton = Rect.fromLTWH(
          fullRect.left,
          fullRect.top,
          fullRect.width * 0.42,
          fullRect.height * 0.48,
        );
        canvas.drawRect(canton, Paint()..color = applyShade(cols[1]));
        final Paint dotPaint = Paint()..color = applyShade(cols[0]);
        for (int r = 0; r < 2; r++) {
          for (int c = 0; c < 3; c++) {
            canvas.drawCircle(
              Offset(
                canton.left + canton.width * (0.22 + c * 0.28),
                canton.top + canton.height * (0.32 + r * 0.36),
              ),
              math.max(1.0, fullRect.height * 0.04),
              dotPaint,
            );
          }
        }
    }

    canvas.restore();
  }

  void _drawLeaderBanner({
    required Canvas canvas,
    required _ProjectedBannerItem item,
    required double animationTimeSeconds,
    required SpectatorBannerWindProfile wind,
    required double opacity,
  }) {
    final SpectatorBannerInstance3D inst = item.instance;
    final double w = item.drawWidth;
    final double h = item.drawHeight;
    final double waveY = inst.kind == SpectatorBannerKind.handPaintedCloth
        ? math.sin(
              animationTimeSeconds * (2.6 + wind.windSpeedMs * 0.3) +
                  inst.wavePhaseOffset,
            ) *
            (h * 0.06)
        : 0.0;

    final Rect rect = Rect.fromCenter(
      center: Offset(
        item.projected.screenX,
        item.projected.screenY - h * 0.5 + waveY,
      ),
      width: w,
      height: h,
    );

    // Słupki podtrzymujące transparent płócienny
    if (inst.kind == SpectatorBannerKind.handPaintedCloth) {
      final Paint stakePaint = Paint()
        ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.85 * opacity)
        ..strokeWidth = math.max(1.2, item.pxPerMeter * 0.04);
      final double stakeBottom = rect.bottom + h * 0.85;
      canvas.drawLine(
        Offset(rect.left + 2.0, rect.top),
        Offset(rect.left + 2.0, stakeBottom),
        stakePaint,
      );
      canvas.drawLine(
        Offset(rect.right - 2.0, rect.top),
        Offset(rect.right - 2.0, stakeBottom),
        stakePaint,
      );
    }

    final RRect cardRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.min(6.0, h * 0.14)),
    );

    // Tło banera
    canvas.drawRRect(
      cardRRect,
      Paint()..color = inst.primaryColor.withValues(alpha: 0.94 * opacity),
    );

    // Pasek akcentowy koszulki lidera
    final Rect accentStripe = Rect.fromLTWH(
      rect.left,
      rect.top,
      math.max(3.0, w * 0.06),
      rect.height,
    );
    canvas.save();
    canvas.clipRRect(cardRRect);
    canvas.drawRect(
      accentStripe,
      Paint()..color = inst.accentColor.withValues(alpha: opacity),
    );
    canvas.restore();

    // Obramowanie banera
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = inst.accentColor.withValues(alpha: 0.85 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, h * 0.045),
    );

    // Tekst nazwiska lidera gracza (renderowany gdy baner ma czytelną szerokość)
    if (w >= 34.0 && h >= 14.0) {
      final double fontSize = (h * 0.42).clamp(8.0, 26.0);
      final String cacheKey =
          '${inst.bannerText}_${fontSize.toStringAsFixed(0)}_${inst.textColor.toARGB32()}';

      final TextPainter tp = _textPainterCache.putIfAbsent(cacheKey, () {
        if (_textPainterCache.length > 180) {
          _textPainterCache.clear();
        }
        return TextPainter(
          text: TextSpan(
            text: inst.bannerText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: inst.textColor,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: w * 0.86);
      });

      tp.layout(maxWidth: w * 0.86);
      final Offset textPos = Offset(
        rect.left + (rect.width - tp.width) * 0.54,
        rect.top + (rect.height - tp.height) * 0.46,
      );

      if (opacity < 0.98) {
        canvas.saveLayer(
          rect,
          Paint()..color = Color.fromARGB((opacity * 255).round(), 255, 255, 255),
        );
        tp.paint(canvas, textPos);
        canvas.restore();
      } else {
        tp.paint(canvas, textPos);
      }
    }
  }
}

class _ProjectedBannerItem {
  final SpectatorBannerInstance3D instance;
  final ProjectedPoint3D projected;
  final double drawWidth;
  final double drawHeight;
  final double pxPerMeter;

  const _ProjectedBannerItem({
    required this.instance,
    required this.projected,
    required this.drawWidth,
    required this.drawHeight,
    required this.pxPerMeter,
  });
}

// =============================================================================
// 3. CUSTOM PAINTER PODGLĄDU 3D ORAZ RESPONSYWNY PANEL STEROWANIA
// =============================================================================

/// CustomPainter rysujący kompletną scenę 3D podjazdu z banerami lidera i flagami regionów.
class DynamicSpectatorBanners3dPainter extends CustomPainter {
  final DynamicSpectatorBannersAndFlags3dRenderer renderer;
  final DynamicSpectatorBannersPack pack;
  final DynamicSpectatorBannerConfig config;
  final SpectatorBannerWindProfile wind;
  final double cameraDistanceMeters;
  final double animationTimeSeconds;
  final ValueChanged<SpectatorBannersTelemetry>? onTelemetry;

  DynamicSpectatorBanners3dPainter({
    required this.renderer,
    required this.pack,
    required this.config,
    required this.wind,
    required this.cameraDistanceMeters,
    required this.animationTimeSeconds,
    this.onTelemetry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tło nieba i asfaltu dla autonomicznego podglądu 3D
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF0F1115), Color(0xFF181B22)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final Scene3DMathProjection projection = Scene3DMathProjection(
      viewportWidth: size.width,
      viewportHeight: size.height,
      fovYDegrees: 56.0,
    );

    const RoadGeometryParameters roadGeometry = RoadGeometryParameters(
      gradientPercent: 6.5,
      roadWidthMeters: 7.2,
    );

    final Vector3 camPos = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: 0.0,
      lateralOffsetMeters: 0.0,
      elevationMeters: 0.0,
      turningRadiusMeters: roadGeometry.turningRadiusMeters,
      gradientPercent: roadGeometry.gradientPercent,
      baseBearingRadians: roadGeometry.roadBearingRadians,
      bankingAngleRadians: roadGeometry.bankingAngleRadians,
      verticalOffsetMeters: 2.35,
    );
    final Vector3 camTarget = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: 28.0,
      lateralOffsetMeters: 0.0,
      elevationMeters: 0.0,
      turningRadiusMeters: roadGeometry.turningRadiusMeters,
      gradientPercent: roadGeometry.gradientPercent,
      baseBearingRadians: roadGeometry.roadBearingRadians,
      bankingAngleRadians: roadGeometry.bankingAngleRadians,
      verticalOffsetMeters: 1.25,
    );
    projection.setView(eye: camPos, target: camTarget);

    // Wstęga szosy
    _paintRoadRibbon(canvas, size, projection, roadGeometry);

    final SpectatorBannersTelemetry telemetry = renderer.render(
      canvas: canvas,
      size: size,
      projection: projection,
      pack: pack,
      config: config,
      cameraDistanceMeters: cameraDistanceMeters,
      animationTimeSeconds: animationTimeSeconds,
      wind: wind,
      roadGeometry: roadGeometry,
    );
    onTelemetry?.call(telemetry);
  }

  void _paintRoadRibbon(
    Canvas canvas,
    Size size,
    Scene3DMathProjection projection,
    RoadGeometryParameters roadGeometry,
  ) {
    final Path roadPath = Path();
    final List<Offset> leftPts = <Offset>[];
    final List<Offset> rightPts = <Offset>[];

    for (double d = 2.0; d <= 180.0; d += 8.0) {
      final ProjectedPoint3D l = projection.worldToScreen(
        Scene3DMathProjection.courseToWorld3D(
          distanceMeters: d,
          lateralOffsetMeters: -3.6,
          elevationMeters: 0.0,
          turningRadiusMeters: roadGeometry.turningRadiusMeters,
          gradientPercent: roadGeometry.gradientPercent,
          baseBearingRadians: roadGeometry.roadBearingRadians,
          bankingAngleRadians: roadGeometry.bankingAngleRadians,
        ),
      );
      final ProjectedPoint3D r = projection.worldToScreen(
        Scene3DMathProjection.courseToWorld3D(
          distanceMeters: d,
          lateralOffsetMeters: 3.6,
          elevationMeters: 0.0,
          turningRadiusMeters: roadGeometry.turningRadiusMeters,
          gradientPercent: roadGeometry.gradientPercent,
          baseBearingRadians: roadGeometry.roadBearingRadians,
          bankingAngleRadians: roadGeometry.bankingAngleRadians,
        ),
      );
      if (l.isInFrontOfCamera && r.isInFrontOfCamera) {
        leftPts.add(Offset(l.screenX, l.screenY));
        rightPts.add(Offset(r.screenX, r.screenY));
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

      canvas.drawPath(
        roadPath,
        Paint()..color = const Color(0xFF222630),
      );
      canvas.drawPath(
        roadPath,
        Paint()
          ..color = const Color(0xFF2A2F3D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DynamicSpectatorBanners3dPainter oldDelegate) {
    return oldDelegate.animationTimeSeconds != animationTimeSeconds ||
        oldDelegate.cameraDistanceMeters != cameraDistanceMeters ||
        oldDelegate.config != config ||
        oldDelegate.wind != wind ||
        oldDelegate.pack != pack;
  }
}

/// Produkcyjny, w pełni responsywny panel konfiguracji i podglądu 3D proceduralnych
/// banerów kibiców z nazwiskiem lidera gracza oraz flagami regionów.
class DynamicSpectatorBannersControlPanel extends StatefulWidget {
  final DynamicSpectatorBannerConfig initialConfig;
  final ValueChanged<DynamicSpectatorBannerConfig>? onConfigChanged;

  const DynamicSpectatorBannersControlPanel({
    super.key,
    this.initialConfig = const DynamicSpectatorBannerConfig(),
    this.onConfigChanged,
  });

  @override
  State<DynamicSpectatorBannersControlPanel> createState() =>
      _DynamicSpectatorBannersControlPanelState();
}

class _DynamicSpectatorBannersControlPanelState
    extends State<DynamicSpectatorBannersControlPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final TextEditingController _surnameController;
  final DynamicSpectatorBannersAndFlags3dRenderer _renderer =
      DynamicSpectatorBannersAndFlags3dRenderer();

  late DynamicSpectatorBannerConfig _config;
  late DynamicSpectatorBannersPack _pack;
  SpectatorBannerWindProfile _wind = const SpectatorBannerWindProfile();
  SpectatorBannersTelemetry _telemetry = SpectatorBannersTelemetry.empty;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _surnameController = TextEditingController(text: _config.leaderSurname);
    _rebuildPack();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _rebuildPack() {
    _pack = _renderer.generateStageBanners(
      config: _config,
      startDistanceMeters: 0.0,
      endDistanceMeters: 1500.0,
    );
  }

  void _updateConfig(DynamicSpectatorBannerConfig next) {
    setState(() {
      _config = next;
      _rebuildPack();
    });
    widget.onConfigChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 680;
          final bool isWide = constraints.maxWidth >= 980;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(isCompact),
                const SizedBox(height: 14),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 6, child: _buildViewportPreview(260)),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: _buildControlsColumn()),
                    ],
                  )
                else ...<Widget>[
                  _buildViewportPreview(isCompact ? 190 : 230),
                  const SizedBox(height: 14),
                  _buildControlsColumn(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAccent, width: 1),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Banery Kibiców i Flagi Regionów 3D',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Lider: ${_config.normalizedLeaderSurname} • Region: ${_config.primaryRegion.labelPl}',
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
        _BannerToggleChip(
          label: _config.enabled ? 'Aktywne 3D' : 'Wyłączone',
          selected: _config.enabled,
          onTap: () => _updateConfig(_config.copyWith(enabled: !_config.enabled)),
        ),
      ],
    );
  }

  Widget _buildViewportPreview(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (BuildContext context, _) {
                final double t = _animController.value * 12.0;
                return CustomPaint(
                  painter: DynamicSpectatorBanners3dPainter(
                    renderer: _renderer,
                    pack: _pack,
                    config: _config,
                    wind: _wind,
                    cameraDistanceMeters: (t * 8.0) % 900.0,
                    animationTimeSeconds: t,
                    onTelemetry: (SpectatorBannersTelemetry tel) {
                      _telemetry = tel;
                    },
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: Text(
                'Widoczne: ${_telemetry.visibleInFrame} | Banery: ${_telemetry.bannersRendered} | Flagi: ${_telemetry.flagsRendered}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsColumn() {
    final bool enabled = _config.enabled;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Nazwisko Lidera Gracza',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _surnameController,
            enabled: enabled,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: 'Np. KOWALSKI',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.goldAccent),
              ),
            ),
            onChanged: (String val) =>
                _updateConfig(_config.copyWith(leaderSurname: val)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dominująca Flaga Regionu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SpectatorRegionFlag.values.take(6).map((SpectatorRegionFlag flag) {
              return _BannerToggleChip(
                label: '${flag.code} • ${flag.labelPl}',
                selected: _config.primaryRegion == flag,
                enabled: enabled,
                onTap: () =>
                    _updateConfig(_config.copyWith(primaryRegion: flag)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _BannerToggleChip(
                label: 'Falowanie wiatrem',
                selected: _config.enableClothWaveAnimation,
                enabled: enabled,
                onTap: () => _updateConfig(
                  _config.copyWith(
                    enableClothWaveAnimation: !_config.enableClothWaveAnimation,
                  ),
                ),
              ),
              _BannerToggleChip(
                label: 'Banery na barierkach',
                selected: _config.enableOverheadTifo,
                enabled: enabled,
                onTap: () => _updateConfig(
                  _config.copyWith(
                    enableOverheadTifo: !_config.enableOverheadTifo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Text(
                'Wiatr:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _wind.windSpeedMs,
                  min: 0.0,
                  max: 16.0,
                  activeColor: AppColors.goldAccent,
                  inactiveColor: const Color(0xFF2A2F3D),
                  onChanged: enabled
                      ? (double v) {
                          setState(() {
                            _wind = _wind.copyWith(windSpeedMs: v);
                          });
                        }
                      : null,
                ),
              ),
              Text(
                '${_wind.windSpeedMs.toStringAsFixed(1)} m/s',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerToggleChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _BannerToggleChip({
    required this.label,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<_BannerToggleChip> createState() => _BannerToggleChipState();
}

class _BannerToggleChipState extends State<_BannerToggleChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled;
    final Color bgColor = !isEnabled
        ? AppColors.background.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : widget.selected
                ? AppColors.primaryAccent.withValues(alpha: 0.24)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    final Color borderColor = !isEnabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.45)
        : _focused
            ? AppColors.goldAccent
            : widget.selected
                ? AppColors.goldAccent
                : _hovered
                    ? AppColors.textSecondary
                    : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      enabled: isEnabled,
      onShowFocusHighlight: (bool f) => setState(() => _focused = f),
      onShowHoverHighlight: (bool h) => setState(() => _hovered = h),
      mouseCursor:
          isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _pressed = false) : null,
        onTap: isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: isEnabled
                  ? (widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)
                  : AppColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
