// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import 'dynamic_skybox_and_lighting_painter.dart';
import 'scene_3d_math_projection.dart';

/// Poziom jakości renderowania cieni chmur i promieni słonecznych (God Rays).
enum CloudShadowQuality {
  /// Pełna jakość: wielowarstwowe cienie na szosie i zboczach, miękkie przejścia oraz wolumetryczne promienie.
  high,

  /// Zrównoważona jakość: cienie na szosie i zboczach oraz uproszczone smugi światła.
  balanced,

  /// Tryb 120 FPS: szybkie plamy cienia na asfalcie bez promieni wolumetrycznych.
  performance,
}

/// Konfiguracja warstwy przesuwających się cieni chmur i promieni słonecznych [CloudShadowsAndSunbeamsPainter].
class CloudShadowsAndSunbeamsConfig {
  final bool enableRoadShadows;
  final bool enableHillsideShadows;
  final bool enableSunbeams;
  final CloudShadowQuality quality;
  final double? cloudCoverageOverride;
  final double shadowOpacityScale;
  final double sunbeamIntensityScale;
  final double maxRenderDistanceMeters;
  final int patchCount;

  const CloudShadowsAndSunbeamsConfig({
    this.enableRoadShadows = true,
    this.enableHillsideShadows = true,
    this.enableSunbeams = true,
    this.quality = CloudShadowQuality.high,
    this.cloudCoverageOverride,
    this.shadowOpacityScale = 1.0,
    this.sunbeamIntensityScale = 1.0,
    this.maxRenderDistanceMeters = 420.0,
    this.patchCount = 14,
  });

  CloudShadowsAndSunbeamsConfig copyWith({
    bool? enableRoadShadows,
    bool? enableHillsideShadows,
    bool? enableSunbeams,
    CloudShadowQuality? quality,
    double? cloudCoverageOverride,
    bool clearCoverageOverride = false,
    double? shadowOpacityScale,
    double? sunbeamIntensityScale,
    double? maxRenderDistanceMeters,
    int? patchCount,
  }) {
    return CloudShadowsAndSunbeamsConfig(
      enableRoadShadows: enableRoadShadows ?? this.enableRoadShadows,
      enableHillsideShadows: enableHillsideShadows ?? this.enableHillsideShadows,
      enableSunbeams: enableSunbeams ?? this.enableSunbeams,
      quality: quality ?? this.quality,
      cloudCoverageOverride: clearCoverageOverride
          ? null
          : (cloudCoverageOverride ?? this.cloudCoverageOverride),
      shadowOpacityScale: shadowOpacityScale ?? this.shadowOpacityScale,
      sunbeamIntensityScale: sunbeamIntensityScale ?? this.sunbeamIntensityScale,
      maxRenderDistanceMeters: maxRenderDistanceMeters ?? this.maxRenderDistanceMeters,
      patchCount: patchCount ?? this.patchCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CloudShadowsAndSunbeamsConfig &&
        other.enableRoadShadows == enableRoadShadows &&
        other.enableHillsideShadows == enableHillsideShadows &&
        other.enableSunbeams == enableSunbeams &&
        other.quality == quality &&
        other.cloudCoverageOverride == cloudCoverageOverride &&
        other.shadowOpacityScale == shadowOpacityScale &&
        other.sunbeamIntensityScale == sunbeamIntensityScale &&
        other.maxRenderDistanceMeters == maxRenderDistanceMeters &&
        other.patchCount == patchCount;
  }

  @override
  int get hashCode => Object.hash(
        enableRoadShadows,
        enableHillsideShadows,
        enableSunbeams,
        quality,
        cloudCoverageOverride,
        shadowOpacityScale,
        sunbeamIntensityScale,
        maxRenderDistanceMeters,
        patchCount,
      );
}

/// Wektor wiatru napędzający przesuwanie się chmur i rzucanych przez nie cieni w przestrzeni świata X-Z.
class CloudWindVector {
  /// Prędkość wiatru w metrach na sekundę [m/s].
  final double windSpeedMs;

  /// Azymut kierunku, W KTÓRY wieje wiatr w płaszczyźnie X-Z [rad] (0 = +Z, pi/2 = +X).
  final double windDirectionRadians;

  /// Pułap chmur nad terenem w metrach [m].
  final double cloudAltitudeMeters;

  const CloudWindVector({
    this.windSpeedMs = 6.5,
    this.windDirectionRadians = math.pi * 0.35,
    this.cloudAltitudeMeters = 950.0,
  });

  /// Składowa prędkości przesuwania cieni w osi X [m/s].
  double get velocityX => math.sin(windDirectionRadians) * windSpeedMs.clamp(0.0, 45.0);

  /// Składowa prędkości przesuwania cieni w osi Z [m/s].
  double get velocityZ => math.cos(windDirectionRadians) * windSpeedMs.clamp(0.0, 45.0);

  /// Prędkość wiatru w km/h.
  double get windSpeedKmh => windSpeedMs.clamp(0.0, 45.0) * 3.6;

  CloudWindVector copyWith({
    double? windSpeedMs,
    double? windDirectionRadians,
    double? cloudAltitudeMeters,
  }) {
    return CloudWindVector(
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      windDirectionRadians: windDirectionRadians ?? this.windDirectionRadians,
      cloudAltitudeMeters: cloudAltitudeMeters ?? this.cloudAltitudeMeters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CloudWindVector &&
        other.windSpeedMs == windSpeedMs &&
        other.windDirectionRadians == windDirectionRadians &&
        other.cloudAltitudeMeters == cloudAltitudeMeters;
  }

  @override
  int get hashCode => Object.hash(windSpeedMs, windDirectionRadians, cloudAltitudeMeters);
}

/// Pojedyncza plama cienia chmury w periodycznej siatce świata.
class CloudShadowPatch {
  final int id;
  final double baseWorldX;
  final double baseWorldZ;
  final double radiusLongitudinalMeters;
  final double radiusLateralMeters;
  final double rotationRadians;
  final double coreDensity;
  final double softness;

  const CloudShadowPatch({
    required this.id,
    required this.baseWorldX,
    required this.baseWorldZ,
    required this.radiusLongitudinalMeters,
    required this.radiusLateralMeters,
    required this.rotationRadians,
    required this.coreDensity,
    required this.softness,
  });
}

/// Wynik lokalnej próbki cienia chmury w punkcie świata (szosa, zbocze lub pozycja kolarza).
class LocalCloudShadowSample {
  /// Natężenie cienia chmury w punkcie [0.0 = pełne słońce, 1.0 = głęboki cień].
  final double shadowIntensity;

  /// Mnożnik jasności asfaltu [0.55..1.10], gdzie < 1.0 przyciemnia nawierzchnię w cieniu.
  final double asphaltBrightnessMultiplier;

  /// Natężenie prześwitu / promienia słonecznego na krawędzi chmury [0.0..1.0].
  final double sunbeamFactor;

  /// Lokalna zmiana temperatury odczuwalnej [°C] (ujemna w cieniu, lekko dodatnia w prześwicie).
  final double apparentTemperatureDeltaCelsius;

  const LocalCloudShadowSample({
    required this.shadowIntensity,
    required this.asphaltBrightnessMultiplier,
    required this.sunbeamFactor,
    required this.apparentTemperatureDeltaCelsius,
  });
}

/// Wpływ cienia chmury na konkretnego kolarza (jasność lokalnego asfaltu i temperatura odczuwalna).
class RiderCloudThermalImpact {
  final int riderIndex;
  final double distanceMeters;
  final LocalCloudShadowSample sample;
  final double effectiveApparentTempCelsius;

  const RiderCloudThermalImpact({
    required this.riderIndex,
    required this.distanceMeters,
    required this.sample,
    required this.effectiveApparentTempCelsius,
  });

  bool get isInCloudShadow => sample.shadowIntensity >= 0.25;
  bool get isInSunbeam => sample.sunbeamFactor >= 0.35;
}

/// Zbiorcza telemetria warstwy cieni chmur i promieni słonecznych dla UI/diagnostyki.
class CloudShadowsTelemetry {
  final int activePatchCount;
  final int sunbeamShaftCount;
  final double averageRoadShadowIntensity;
  final double averageAsphaltBrightness;
  final double minRiderTempDeltaC;
  final double maxRiderTempDeltaC;
  final double windSpeedKmh;
  final double effectiveCloudCoverage;

  const CloudShadowsTelemetry({
    required this.activePatchCount,
    required this.sunbeamShaftCount,
    required this.averageRoadShadowIntensity,
    required this.averageAsphaltBrightness,
    required this.minRiderTempDeltaC,
    required this.maxRiderTempDeltaC,
    required this.windSpeedKmh,
    required this.effectiveCloudCoverage,
  });
}

/// Deterministyczny ewaluator pola cieni chmur, jasności asfaltu i temperatury odczuwalnej kolarzy.
class CloudShadowFieldEvaluator {
  /// Rozmiar powtarzalnego kafelka świata [m] w osi X i Z.
  static const double worldTileSizeMeters = 840.0;

  CloudShadowFieldEvaluator._();

  /// Wyznacza bazowe zachmurzenie [0.0..1.0] na podstawie pogody lub nadpisania z konfiguracji.
  static double resolveEffectiveCoverage(
    WeatherCondition weather, {
    double? coverageOverride,
  }) {
    if (coverageOverride != null) {
      return coverageOverride.clamp(0.0, 1.0);
    }
    switch (weather) {
      case WeatherCondition.sunny:
        return 0.24;
      case WeatherCondition.extremeHeat:
        return 0.14;
      case WeatherCondition.crosswindGale:
        return 0.52;
      case WeatherCondition.overcast:
        return 0.78;
      case WeatherCondition.lightRain:
        return 0.85;
      case WeatherCondition.heavyStorm:
        return 0.94;
    }
  }

  /// Generuje deterministyczną listę plam cieni chmur dla zadanego ziarna [seed] i [patchCount].
  static List<CloudShadowPatch> generatePatches({
    required int seed,
    int patchCount = 14,
  }) {
    final int safeCount = patchCount.clamp(4, 32);
    final math.Random rng = math.Random(seed ^ 0x5A17C10D);
    final List<CloudShadowPatch> patches = <CloudShadowPatch>[];

    for (int i = 0; i < safeCount; i++) {
      final double baseX = (rng.nextDouble() - 0.5) * worldTileSizeMeters;
      final double baseZ = (rng.nextDouble() - 0.5) * worldTileSizeMeters;
      final double rx = 38.0 + rng.nextDouble() * 88.0;
      final double rz = 26.0 + rng.nextDouble() * 74.0;
      final double rot = rng.nextDouble() * math.pi;
      final double density = 0.42 + rng.nextDouble() * 0.52;
      final double softness = 0.28 + rng.nextDouble() * 0.45;
      patches.add(
        CloudShadowPatch(
          id: i,
          baseWorldX: baseX,
          baseWorldZ: baseZ,
          radiusLongitudinalMeters: rx,
          radiusLateralMeters: rz,
          rotationRadians: rot,
          coreDensity: density,
          softness: softness,
        ),
      );
    }
    return patches;
  }

  /// Wylicza aktualną pozycję plamy cienia w kafelku otaczającym punkt odniesienia `(refX, refZ)`.
  static Offset computeWrappedPatchCenter({
    required CloudShadowPatch patch,
    required CloudWindVector wind,
    required double elapsedSeconds,
    required double refX,
    required double refZ,
  }) {
    final double rawX = patch.baseWorldX + wind.velocityX * elapsedSeconds;
    final double rawZ = patch.baseWorldZ + wind.velocityZ * elapsedSeconds;

    final double wrappedX = _wrapAround(rawX, refX, worldTileSizeMeters);
    final double wrappedZ = _wrapAround(rawZ, refZ, worldTileSizeMeters);
    return Offset(wrappedX, wrappedZ);
  }

  static double _wrapAround(double value, double center, double period) {
    final double half = period * 0.5;
    double rel = (value - center + half) % period;
    if (rel < 0.0) rel += period;
    return center - half + rel;
  }

  /// Oblicza lokalną próbkę cienia chmury, jasności asfaltu i delty temperatury w punkcie `(worldX, worldZ)`.
  static LocalCloudShadowSample evaluateShadowAtWorldPoint({
    required double worldX,
    required double worldZ,
    required double elapsedSeconds,
    required CloudWindVector wind,
    required WeatherCondition weather,
    required StageTimeOfDay timeOfDay,
    int seed = 263,
    int patchCount = 14,
    double? coverageOverride,
    List<CloudShadowPatch>? precomputedPatches,
  }) {
    final double coverage = resolveEffectiveCoverage(
      weather,
      coverageOverride: coverageOverride,
    );
    final List<CloudShadowPatch> patches = precomputedPatches ??
        generatePatches(seed: seed, patchCount: patchCount);

    final int activePatches = (patches.length * (0.25 + coverage * 0.75))
        .round()
        .clamp(1, patches.length);

    double accumulatedShadow = 0.0;
    double edgeProximity = 0.0;

    for (int i = 0; i < activePatches; i++) {
      final CloudShadowPatch p = patches[i];
      final Offset center = computeWrappedPatchCenter(
        patch: p,
        wind: wind,
        elapsedSeconds: elapsedSeconds,
        refX: worldX,
        refZ: worldZ,
      );

      final double dx = worldX - center.dx;
      final double dz = worldZ - center.dy;
      final double cosR = math.cos(p.rotationRadians);
      final double sinR = math.sin(p.rotationRadians);

      final double localX = dx * cosR + dz * sinR;
      final double localZ = -dx * sinR + dz * cosR;

      final double nx = localX / p.radiusLateralMeters;
      final double nz = localZ / p.radiusLongitudinalMeters;
      final double distSq = nx * nx + nz * nz;

      if (distSq < 1.35) {
        final double dist = math.sqrt(distSq);
        // Płynne przejście Gaussa wewnątrz plamy cienia.
        final double falloff = math.exp(-distSq * (1.85 - p.softness * 0.75));
        final double contribution =
            (falloff * p.coreDensity * (0.45 + coverage * 0.55)).clamp(0.0, 1.0);
        accumulatedShadow =
            1.0 - (1.0 - accumulatedShadow) * (1.0 - contribution);

        // Krawędź chmury (dystans ~0.75..1.18) sprzyja powstawaniu smug promieni (crepuscular rays).
        if (dist >= 0.65 && dist <= 1.22) {
          final double ring = 1.0 - ((dist - 0.92).abs() / 0.30).clamp(0.0, 1.0);
          if (ring > edgeProximity) {
            edgeProximity = ring;
          }
        }
      }
    }

    // W nocy brak cieni słonecznych i promieni.
    final double solarDayFactor = _computeSolarDayFactor(timeOfDay);
    final double effectiveShadow = (accumulatedShadow * solarDayFactor).clamp(0.0, 1.0);

    // Prześwit (sunbeam) jest najsilniejszy przy umiarkowanym zachmurzeniu na krawędziach chmur.
    final double brokenCloudFactor =
        (1.0 - (coverage - 0.45).abs() * 1.45).clamp(0.0, 1.0);
    final double sunbeamFactor =
        (edgeProximity * brokenCloudFactor * (1.0 - effectiveShadow * 0.65) * solarDayFactor)
            .clamp(0.0, 1.0);

    // Jasność asfaltu: w pełnym cieniu spada do ~0.58, w prześwicie lekki kontrast do 1.06.
    final double asphaltBrightness =
        (1.0 - effectiveShadow * 0.42 + sunbeamFactor * 0.06).clamp(0.54, 1.08);

    // Temperatura odczuwalna kolarza: cień chmury chłodzi o max -4.2°C w pełnym słońcu/upale,
    // a bezpośredni promień w prześwicie może podnieść odczuwalną o +0.6°C.
    final double maxCooling = weather == WeatherCondition.extremeHeat
        ? 4.4
        : (weather == WeatherCondition.sunny ? 3.8 : 2.2);
    final double tempDelta =
        (-effectiveShadow * maxCooling * solarDayFactor) +
            (sunbeamFactor * 0.6 * solarDayFactor);

    return LocalCloudShadowSample(
      shadowIntensity: effectiveShadow,
      asphaltBrightnessMultiplier: asphaltBrightness,
      sunbeamFactor: sunbeamFactor,
      apparentTemperatureDeltaCelsius: tempDelta,
    );
  }

  /// Wylicza wpływ chmur na listę pozycji kolarzy w układzie trasy [CoursePosition].
  static List<RiderCloudThermalImpact> evaluateRidersThermalAndBrightness({
    required List<CoursePosition> riderPositions,
    required RoadGeometryParameters roadGeometry,
    required double elapsedSeconds,
    required CloudWindVector wind,
    required WeatherCondition weather,
    required StageTimeOfDay timeOfDay,
    double baseAmbientTempCelsius = 22.0,
    int seed = 263,
    int patchCount = 14,
    double? coverageOverride,
  }) {
    if (riderPositions.isEmpty) return const [];
    final List<CloudShadowPatch> patches =
        generatePatches(seed: seed, patchCount: patchCount);
    final List<RiderCloudThermalImpact> results = <RiderCloudThermalImpact>[];

    for (int i = 0; i < riderPositions.length; i++) {
      final CoursePosition pos = riderPositions[i];
      final Vector3 worldPos = _courseToWorld(pos, roadGeometry);
      final LocalCloudShadowSample sample = evaluateShadowAtWorldPoint(
        worldX: worldPos.x,
        worldZ: worldPos.z,
        elapsedSeconds: elapsedSeconds,
        wind: wind,
        weather: weather,
        timeOfDay: timeOfDay,
        seed: seed,
        patchCount: patchCount,
        coverageOverride: coverageOverride,
        precomputedPatches: patches,
      );
      results.add(
        RiderCloudThermalImpact(
          riderIndex: i,
          distanceMeters: pos.distanceMeters,
          sample: sample,
          effectiveApparentTempCelsius:
              baseAmbientTempCelsius + sample.apparentTemperatureDeltaCelsius,
        ),
      );
    }
    return results;
  }

  /// Wylicza zbiorczą telemetrię dla bieżącej klatki.
  static CloudShadowsTelemetry computeTelemetry({
    required double cameraCourseDistanceMeters,
    required RoadGeometryParameters roadGeometry,
    required double elapsedSeconds,
    required CloudWindVector wind,
    required WeatherCondition weather,
    required StageTimeOfDay timeOfDay,
    CloudShadowsAndSunbeamsConfig config = const CloudShadowsAndSunbeamsConfig(),
    List<CoursePosition> riderPositions = const [],
    double baseAmbientTempCelsius = 22.0,
    int seed = 263,
  }) {
    final double coverage = resolveEffectiveCoverage(
      weather,
      coverageOverride: config.cloudCoverageOverride,
    );
    final List<CloudShadowPatch> patches =
        generatePatches(seed: seed, patchCount: config.patchCount);
    final int activePatches = (patches.length * (0.25 + coverage * 0.75))
        .round()
        .clamp(1, patches.length);

    double sumShadow = 0.0;
    double sumBrightness = 0.0;
    const int roadSampleCount = 8;

    for (int i = 0; i < roadSampleCount; i++) {
      final double dist =
          cameraCourseDistanceMeters + (i / roadSampleCount) * config.maxRenderDistanceMeters * 0.7;
      final Vector3 w = _courseToWorld(
        CoursePosition(
          distanceMeters: dist,
          lateralOffsetMeters: 0.0,
          elevationMeters: 0.0,
        ),
        roadGeometry,
      );
      final LocalCloudShadowSample s = evaluateShadowAtWorldPoint(
        worldX: w.x,
        worldZ: w.z,
        elapsedSeconds: elapsedSeconds,
        wind: wind,
        weather: weather,
        timeOfDay: timeOfDay,
        seed: seed,
        patchCount: config.patchCount,
        coverageOverride: config.cloudCoverageOverride,
        precomputedPatches: patches,
      );
      sumShadow += s.shadowIntensity;
      sumBrightness += s.asphaltBrightnessMultiplier;
    }

    final List<RiderCloudThermalImpact> riderImpacts =
        evaluateRidersThermalAndBrightness(
      riderPositions: riderPositions,
      roadGeometry: roadGeometry,
      elapsedSeconds: elapsedSeconds,
      wind: wind,
      weather: weather,
      timeOfDay: timeOfDay,
      baseAmbientTempCelsius: baseAmbientTempCelsius,
      seed: seed,
      patchCount: config.patchCount,
      coverageOverride: config.cloudCoverageOverride,
    );

    double minTempDelta = 0.0;
    double maxTempDelta = 0.0;
    if (riderImpacts.isNotEmpty) {
      minTempDelta = riderImpacts.first.sample.apparentTemperatureDeltaCelsius;
      maxTempDelta = minTempDelta;
      for (final RiderCloudThermalImpact r in riderImpacts) {
        final double d = r.sample.apparentTemperatureDeltaCelsius;
        if (d < minTempDelta) minTempDelta = d;
        if (d > maxTempDelta) maxTempDelta = d;
      }
    } else {
      final LocalCloudShadowSample centerSample = evaluateShadowAtWorldPoint(
        worldX: 0.0,
        worldZ: cameraCourseDistanceMeters + 35.0,
        elapsedSeconds: elapsedSeconds,
        wind: wind,
        weather: weather,
        timeOfDay: timeOfDay,
        seed: seed,
        patchCount: config.patchCount,
        coverageOverride: config.cloudCoverageOverride,
        precomputedPatches: patches,
      );
      minTempDelta = centerSample.apparentTemperatureDeltaCelsius;
      maxTempDelta = centerSample.apparentTemperatureDeltaCelsius;
    }

    final double solarDayFactor = _computeSolarDayFactor(timeOfDay);
    final int sunbeamCount = (config.enableSunbeams &&
            config.quality != CloudShadowQuality.performance &&
            solarDayFactor > 0.15)
        ? (3 + (coverage * 4).round()).clamp(2, 7)
        : 0;

    return CloudShadowsTelemetry(
      activePatchCount: activePatches,
      sunbeamShaftCount: sunbeamCount,
      averageRoadShadowIntensity: sumShadow / roadSampleCount,
      averageAsphaltBrightness: sumBrightness / roadSampleCount,
      minRiderTempDeltaC: minTempDelta,
      maxRiderTempDeltaC: maxTempDelta,
      windSpeedKmh: wind.windSpeedKmh,
      effectiveCloudCoverage: coverage,
    );
  }

  static Vector3 _courseToWorld(
    CoursePosition pos,
    RoadGeometryParameters roadGeo,
  ) {
    return Scene3DMathProjection.courseToWorld3D(
      distanceMeters: pos.distanceMeters,
      lateralOffsetMeters: pos.lateralOffsetMeters,
      elevationMeters: pos.elevationMeters,
      turningRadiusMeters: roadGeo.turningRadiusMeters,
      gradientPercent: roadGeo.gradientPercent,
      baseBearingRadians: roadGeo.roadBearingRadians,
      bankingAngleRadians: roadGeo.bankingAngleRadians,
      verticalOffsetMeters: pos.verticalOffsetMeters,
    );
  }

  static double _computeSolarDayFactor(StageTimeOfDay timeOfDay) {
    final double h = timeOfDay.decimalHours;
    if (h < 5.5 || h >= 20.5) return 0.0;
    if (h < 7.0) return ((h - 5.5) / 1.5).clamp(0.0, 1.0);
    if (h > 19.0) return ((20.5 - h) / 1.5).clamp(0.0, 1.0);
    return 1.0;
  }
}

/// Painter 3D rysujący warstwę przesuwających się cieni chmur po szosie i zboczach gór
/// oraz wolumetrycznych promieni słonecznych (God Rays) w silniku wyścigu 3D.
class CloudShadowsAndSunbeamsPainter extends CustomPainter {
  final Scene3DMathProjection? projection;
  final double cameraCourseDistanceMeters;
  final double cameraElevationMeters;
  final RoadGeometryParameters roadGeometry;
  final StageTimeOfDay timeOfDay;
  final WeatherCondition weatherCondition;
  final CloudWindVector windVector;
  final CloudShadowsAndSunbeamsConfig config;
  final double elapsedSeconds;
  final int seed;

  // Prealokowane obiekty Paint i Path w celu eliminacji alokacji GC w pętli 60/120 FPS.
  static final Paint _hillShadowPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _roadPenumbraPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _roadUmbraPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _roadSunlitBoostPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _sunbeamPaint = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.screen;
  static final Path _reusableQuadPath = Path();

  const CloudShadowsAndSunbeamsPainter({
    this.projection,
    this.cameraCourseDistanceMeters = 0.0,
    this.cameraElevationMeters = 100.0,
    this.roadGeometry = const RoadGeometryParameters(),
    this.timeOfDay = const StageTimeOfDay.morningStart(),
    this.weatherCondition = WeatherCondition.sunny,
    this.windVector = const CloudWindVector(),
    this.config = const CloudShadowsAndSunbeamsConfig(),
    this.elapsedSeconds = 0.0,
    this.seed = 263,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0) return;

    final double solarDayFactor =
        CloudShadowFieldEvaluator._computeSolarDayFactor(timeOfDay);
    if (solarDayFactor <= 0.01) return;

    final double coverage = CloudShadowFieldEvaluator.resolveEffectiveCoverage(
      weatherCondition,
      coverageOverride: config.cloudCoverageOverride,
    );
    final List<CloudShadowPatch> patches = CloudShadowFieldEvaluator.generatePatches(
      seed: seed,
      patchCount: config.patchCount,
    );

    if (config.enableHillsideShadows) {
      _paintHillsideCloudShadows(
        canvas: canvas,
        size: size,
        patches: patches,
        coverage: coverage,
        solarDayFactor: solarDayFactor,
      );
    }

    if (config.enableRoadShadows) {
      _paintRoadAsphaltCloudShadows(
        canvas: canvas,
        size: size,
        patches: patches,
        coverage: coverage,
        solarDayFactor: solarDayFactor,
      );
    }

    if (config.enableSunbeams && config.quality != CloudShadowQuality.performance) {
      _paintVolumetricSunbeams(
        canvas: canvas,
        size: size,
        coverage: coverage,
        solarDayFactor: solarDayFactor,
      );
    }
  }

  void _paintHillsideCloudShadows({
    required Canvas canvas,
    required Size size,
    required List<CloudShadowPatch> patches,
    required double coverage,
    required double solarDayFactor,
  }) {
    final Scene3DMathProjection? proj = projection;
    final double opacityBase =
        (0.18 + coverage * 0.24) * config.shadowOpacityScale.clamp(0.0, 2.0) * solarDayFactor;

    if (proj == null) {
      _paintFallbackHillsideBands(canvas, size, opacityBase);
      return;
    }

    final int steps = config.quality == CloudShadowQuality.high ? 12 : 8;
    final double stepDist = config.maxRenderDistanceMeters / steps;
    final double halfRoad = roadGeometry.roadWidthMeters * 0.5;

    for (int side = -1; side <= 1; side += 2) {
      for (int i = 0; i < steps; i++) {
        final double d0 = cameraCourseDistanceMeters + 12.0 + i * stepDist;
        final double d1 = d0 + stepDist;
        final double dMid = (d0 + d1) * 0.5;

        final double innerLat = side * (halfRoad + 4.0);
        final double outerLat = side * (halfRoad + 72.0);
        final double midLat = side * (halfRoad + 36.0);

        final Vector3 midWorld = CloudShadowFieldEvaluator._courseToWorld(
          CoursePosition(
            distanceMeters: dMid,
            lateralOffsetMeters: midLat,
            elevationMeters: cameraElevationMeters + 14.0,
          ),
          roadGeometry,
        );

        final LocalCloudShadowSample sample =
            CloudShadowFieldEvaluator.evaluateShadowAtWorldPoint(
          worldX: midWorld.x,
          worldZ: midWorld.z,
          elapsedSeconds: elapsedSeconds,
          wind: windVector,
          weather: weatherCondition,
          timeOfDay: timeOfDay,
          seed: seed,
          patchCount: config.patchCount,
          coverageOverride: config.cloudCoverageOverride,
          precomputedPatches: patches,
        );

        if (sample.shadowIntensity < 0.08) continue;

        final ProjectedPoint3D p00 = proj.worldToScreen(
          CloudShadowFieldEvaluator._courseToWorld(
            CoursePosition(
              distanceMeters: d0,
              lateralOffsetMeters: innerLat,
              elevationMeters: cameraElevationMeters + 1.0,
            ),
            roadGeometry,
          ),
        );
        final ProjectedPoint3D p01 = proj.worldToScreen(
          CloudShadowFieldEvaluator._courseToWorld(
            CoursePosition(
              distanceMeters: d0,
              lateralOffsetMeters: outerLat,
              elevationMeters: cameraElevationMeters + 28.0,
            ),
            roadGeometry,
          ),
        );
        final ProjectedPoint3D p11 = proj.worldToScreen(
          CloudShadowFieldEvaluator._courseToWorld(
            CoursePosition(
              distanceMeters: d1,
              lateralOffsetMeters: outerLat,
              elevationMeters: cameraElevationMeters + 28.0,
            ),
            roadGeometry,
          ),
        );
        final ProjectedPoint3D p10 = proj.worldToScreen(
          CloudShadowFieldEvaluator._courseToWorld(
            CoursePosition(
              distanceMeters: d1,
              lateralOffsetMeters: innerLat,
              elevationMeters: cameraElevationMeters + 1.0,
            ),
            roadGeometry,
          ),
        );

        if (!p00.isInFrontOfCamera &&
            !p01.isInFrontOfCamera &&
            !p11.isInFrontOfCamera &&
            !p10.isInFrontOfCamera) {
          continue;
        }

        final double distFade =
            (1.0 - (i / steps) * 0.55).clamp(0.25, 1.0);
        final double alpha =
            (sample.shadowIntensity * opacityBase * distFade).clamp(0.0, 0.52);

        _reusableQuadPath
          ..reset()
          ..moveTo(p00.screenX, p00.screenY)
          ..lineTo(p01.screenX, p01.screenY)
          ..lineTo(p11.screenX, p11.screenY)
          ..lineTo(p10.screenX, p10.screenY)
          ..close();

        _hillShadowPaint.color = const Color(0xFF0B111E).withValues(alpha: alpha);
        canvas.drawPath(_reusableQuadPath, _hillShadowPaint);
      }
    }
  }

  void _paintFallbackHillsideBands(
    Canvas canvas,
    Size size,
    double opacityBase,
  ) {
    final double driftX =
        ((windVector.velocityX * elapsedSeconds * 12.0) % (size.width * 1.4));
    for (int i = 0; i < 3; i++) {
      final double cx = ((i * size.width * 0.42 + driftX) % (size.width * 1.3)) -
          size.width * 0.15;
      final double cy = size.height * (0.36 + i * 0.05);
      final Rect rect = Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.48,
        height: size.height * 0.12,
      );
      _hillShadowPaint.color =
          const Color(0xFF0B111E).withValues(alpha: (opacityBase * 0.65).clamp(0.0, 0.35));
      canvas.drawOval(rect, _hillShadowPaint);
    }
  }

  void _paintRoadAsphaltCloudShadows({
    required Canvas canvas,
    required Size size,
    required List<CloudShadowPatch> patches,
    required double coverage,
    required double solarDayFactor,
  }) {
    final Scene3DMathProjection? proj = projection;
    if (proj == null) {
      _paintFallbackRoadPatches(canvas, size, coverage, solarDayFactor);
      return;
    }

    final int slices = config.quality == CloudShadowQuality.high
        ? 18
        : (config.quality == CloudShadowQuality.balanced ? 12 : 8);
    final double stepMeters = config.maxRenderDistanceMeters / slices;
    final double halfRoad = roadGeometry.roadWidthMeters * 0.52;

    for (int i = 0; i < slices; i++) {
      final double d0 = cameraCourseDistanceMeters + 2.0 + i * stepMeters;
      final double d1 = d0 + stepMeters;
      final double dMid = (d0 + d1) * 0.5;

      final Vector3 midWorld = CloudShadowFieldEvaluator._courseToWorld(
        CoursePosition(
          distanceMeters: dMid,
          lateralOffsetMeters: 0.0,
          elevationMeters: cameraElevationMeters,
        ),
        roadGeometry,
      );

      final LocalCloudShadowSample sample =
          CloudShadowFieldEvaluator.evaluateShadowAtWorldPoint(
        worldX: midWorld.x,
        worldZ: midWorld.z,
        elapsedSeconds: elapsedSeconds,
        wind: windVector,
        weather: weatherCondition,
        timeOfDay: timeOfDay,
        seed: seed,
        patchCount: config.patchCount,
        coverageOverride: config.cloudCoverageOverride,
        precomputedPatches: patches,
      );

      if (sample.shadowIntensity < 0.06 && sample.sunbeamFactor < 0.20) {
        continue;
      }

      final ProjectedPoint3D pL0 = proj.worldToScreen(
        CloudShadowFieldEvaluator._courseToWorld(
          CoursePosition(
            distanceMeters: d0,
            lateralOffsetMeters: -halfRoad,
            elevationMeters: cameraElevationMeters,
          ),
          roadGeometry,
        ),
      );
      final ProjectedPoint3D pR0 = proj.worldToScreen(
        CloudShadowFieldEvaluator._courseToWorld(
          CoursePosition(
            distanceMeters: d0,
            lateralOffsetMeters: halfRoad,
            elevationMeters: cameraElevationMeters,
          ),
          roadGeometry,
        ),
      );
      final ProjectedPoint3D pR1 = proj.worldToScreen(
        CloudShadowFieldEvaluator._courseToWorld(
          CoursePosition(
            distanceMeters: d1,
            lateralOffsetMeters: halfRoad,
            elevationMeters: cameraElevationMeters,
          ),
          roadGeometry,
        ),
      );
      final ProjectedPoint3D pL1 = proj.worldToScreen(
        CloudShadowFieldEvaluator._courseToWorld(
          CoursePosition(
            distanceMeters: d1,
            lateralOffsetMeters: -halfRoad,
            elevationMeters: cameraElevationMeters,
          ),
          roadGeometry,
        ),
      );

      if (!pL0.isInFrontOfCamera &&
          !pR0.isInFrontOfCamera &&
          !pR1.isInFrontOfCamera &&
          !pL1.isInFrontOfCamera) {
        continue;
      }

      _reusableQuadPath
        ..reset()
        ..moveTo(pL0.screenX, pL0.screenY)
        ..lineTo(pR0.screenX, pR0.screenY)
        ..lineTo(pR1.screenX, pR1.screenY)
        ..lineTo(pL1.screenX, pL1.screenY)
        ..close();

      final double distFade = (1.0 - (i / slices) * 0.45).clamp(0.3, 1.0);
      if (sample.shadowIntensity >= 0.06) {
        final double darknessAlpha = ((1.0 - sample.asphaltBrightnessMultiplier) *
                1.05 *
                config.shadowOpacityScale *
                distFade)
            .clamp(0.0, 0.54);
        _roadPenumbraPaint.color =
            const Color(0xFF0A0D14).withValues(alpha: darknessAlpha * 0.65);
        canvas.drawPath(_reusableQuadPath, _roadPenumbraPaint);

        if (config.quality != CloudShadowQuality.performance &&
            sample.shadowIntensity > 0.35) {
          _roadUmbraPaint.color =
              const Color(0xFF06080D).withValues(alpha: darknessAlpha * 0.48);
          canvas.drawPath(_reusableQuadPath, _roadUmbraPaint);
        }
      } else if (sample.sunbeamFactor >= 0.20) {
        final double boostAlpha =
            (sample.sunbeamFactor * 0.14 * config.sunbeamIntensityScale * distFade)
                .clamp(0.0, 0.18);
        _roadSunlitBoostPaint.color =
            const Color(0xFFFDE68A).withValues(alpha: boostAlpha);
        canvas.drawPath(_reusableQuadPath, _roadSunlitBoostPaint);
      }
    }
  }

  void _paintFallbackRoadPatches(
    Canvas canvas,
    Size size,
    double coverage,
    double solarDayFactor,
  ) {
    final double driftX =
        ((windVector.velocityX * elapsedSeconds * 16.0) % (size.width * 1.4));
    final double baseAlpha =
        (0.16 + coverage * 0.22) * config.shadowOpacityScale * solarDayFactor;

    for (int i = 0; i < 4; i++) {
      final double t = i / 4.0;
      final double y = size.height * (0.52 + t * 0.38);
      final double w = size.width * (0.28 + t * 0.25);
      final double cx = ((size.width * (0.22 + i * 0.26) + driftX) %
              (size.width * 1.25)) -
          size.width * 0.12;
      _roadUmbraPaint.color =
          const Color(0xFF090C12).withValues(alpha: baseAlpha.clamp(0.0, 0.45));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, y), width: w, height: size.height * 0.09),
        _roadUmbraPaint,
      );
    }
  }

  void _paintVolumetricSunbeams({
    required Canvas canvas,
    required Size size,
    required double coverage,
    required double solarDayFactor,
  }) {
    final SunLightState sunState = DynamicSkyboxAndLightingPainter.computeSunLightState(
      timeOfDay: timeOfDay,
      weatherCondition: weatherCondition,
      elapsedSeconds: elapsedSeconds,
    );

    final double brokenFactor =
        (1.0 - (coverage - 0.45).abs() * 1.4).clamp(0.15, 1.0);
    final double masterAlpha =
        (0.13 * brokenFactor * config.sunbeamIntensityScale * solarDayFactor)
            .clamp(0.0, 0.26);
    if (masterAlpha <= 0.01) return;

    final int shaftCount = config.quality == CloudShadowQuality.high ? 5 : 3;
    final double sunX = size.width * (0.2 + sunState.sunDirectionWorld.x * 0.6);
    final double sunY = -size.height * 0.08;
    final double windShift = windVector.velocityX * elapsedSeconds * 9.5;
    final Color beamTint = timeOfDay.phase == StageLightingPhase.goldenHour
        ? AppColors.goldAccent
        : const Color(0xFFFDE68A);

    for (int i = 0; i < shaftCount; i++) {
      final double phase = (i / shaftCount) * math.pi * 2.0;
      final double baseTargetX =
          ((size.width * (0.12 + i * 0.21) + windShift) % (size.width * 1.2)) -
              size.width * 0.1;
      final double pulse = 0.72 + 0.28 * math.sin(elapsedSeconds * 0.45 + phase);
      final double topHalfWidth = size.width * (0.018 + (i % 2) * 0.01);
      final double bottomHalfWidth = size.width * (0.075 + (i % 3) * 0.024);

      _reusableQuadPath
        ..reset()
        ..moveTo(sunX - topHalfWidth, sunY)
        ..lineTo(sunX + topHalfWidth, sunY)
        ..lineTo(baseTargetX + bottomHalfWidth, size.height * 0.88)
        ..lineTo(baseTargetX - bottomHalfWidth, size.height * 0.88)
        ..close();

      _sunbeamPaint.shader = ui.Gradient.linear(
        Offset(sunX, 0.0),
        Offset(baseTargetX, size.height * 0.88),
        <Color>[
          beamTint.withValues(alpha: (masterAlpha * pulse).clamp(0.0, 0.28)),
          beamTint.withValues(alpha: (masterAlpha * 0.45 * pulse).clamp(0.0, 0.14)),
          beamTint.withValues(alpha: 0.0),
        ],
        const <double>[0.0, 0.55, 1.0],
      );

      canvas.drawPath(_reusableQuadPath, _sunbeamPaint);
    }
    _sunbeamPaint.shader = null;
  }

  @override
  bool shouldRepaint(covariant CloudShadowsAndSunbeamsPainter oldDelegate) {
    return oldDelegate.projection != projection ||
        oldDelegate.cameraCourseDistanceMeters != cameraCourseDistanceMeters ||
        oldDelegate.cameraElevationMeters != cameraElevationMeters ||
        oldDelegate.roadGeometry.turningRadiusMeters != roadGeometry.turningRadiusMeters ||
        oldDelegate.roadGeometry.gradientPercent != roadGeometry.gradientPercent ||
        oldDelegate.roadGeometry.roadBearingRadians != roadGeometry.roadBearingRadians ||
        oldDelegate.timeOfDay != timeOfDay ||
        oldDelegate.weatherCondition != weatherCondition ||
        oldDelegate.windVector != windVector ||
        oldDelegate.config != config ||
        (oldDelegate.elapsedSeconds - elapsedSeconds).abs() > 0.008 ||
        oldDelegate.seed != seed;
  }
}

/// Responsywny panel sterowania i telemetrii cieni chmur oraz promieni słonecznych
/// przystosowany do rozdzielczości `390x844`, `1024x768` oraz `1600x900`.
class CloudShadowsAndSunbeamsControlPanel extends StatefulWidget {
  final CloudShadowsAndSunbeamsConfig config;
  final CloudWindVector windVector;
  final CloudShadowsTelemetry telemetry;
  final ValueChanged<CloudShadowsAndSunbeamsConfig> onConfigChanged;
  final ValueChanged<CloudWindVector>? onWindChanged;
  final bool enabled;

  const CloudShadowsAndSunbeamsControlPanel({
    super.key,
    required this.config,
    required this.windVector,
    required this.telemetry,
    required this.onConfigChanged,
    this.onWindChanged,
    this.enabled = true,
  });

  @override
  State<CloudShadowsAndSunbeamsControlPanel> createState() =>
      _CloudShadowsAndSunbeamsControlPanelState();
}

class _CloudShadowsAndSunbeamsControlPanelState
    extends State<CloudShadowsAndSunbeamsControlPanel> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 460.0;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
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
                _buildFeatureToggles(isCompact),
                if (widget.onWindChanged != null) ...[
                  const SizedBox(height: 10),
                  _buildWindSlider(),
                ],
                const SizedBox(height: 12),
                _buildTelemetryRow(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final int brightnessPct = (widget.telemetry.averageAsphaltBrightness * 100).round();
    return Row(
      children: [
        const Icon(Icons.wb_cloudy_outlined, color: AppColors.goldAccent, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cienie Chmur i Promienie 3D',
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
            'Asfalt $brightnessPct%',
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
      children: [
        _CloudActionPill(
          label: 'High',
          selected: widget.config.quality == CloudShadowQuality.high,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(quality: CloudShadowQuality.high),
          ),
        ),
        _CloudActionPill(
          label: 'Balanced',
          selected: widget.config.quality == CloudShadowQuality.balanced,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(quality: CloudShadowQuality.balanced),
          ),
        ),
        _CloudActionPill(
          label: isCompact ? '120 FPS' : 'Performance',
          selected: widget.config.quality == CloudShadowQuality.performance,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(quality: CloudShadowQuality.performance),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggles(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CloudActionPill(
          label: 'Szosa',
          selected: widget.config.enableRoadShadows,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(enableRoadShadows: !widget.config.enableRoadShadows),
          ),
        ),
        _CloudActionPill(
          label: 'Zbocza gór',
          selected: widget.config.enableHillsideShadows,
          enabled: widget.enabled,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(
              enableHillsideShadows: !widget.config.enableHillsideShadows,
            ),
          ),
        ),
        _CloudActionPill(
          label: isCompact ? 'Promienie' : 'Promienie Słońca',
          selected: widget.config.enableSunbeams,
          enabled: widget.enabled &&
              widget.config.quality != CloudShadowQuality.performance,
          onTap: () => widget.onConfigChanged(
            widget.config.copyWith(enableSunbeams: !widget.config.enableSunbeams),
          ),
        ),
      ],
    );
  }

  Widget _buildWindSlider() {
    final double windMs = widget.windVector.windSpeedMs.clamp(0.0, 25.0);
    return Row(
      children: [
        const Text(
          'Wiatr',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
              trackHeight: 3.0,
            ),
            child: Slider(
              value: windMs,
              min: 0.0,
              max: 25.0,
              onChanged: widget.enabled
                  ? (val) => widget.onWindChanged?.call(
                        widget.windVector.copyWith(windSpeedMs: val),
                      )
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '${widget.windVector.windSpeedKmh.round()} km/h',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryRow(bool isCompact) {
    final String tempDeltaStr =
        '${widget.telemetry.minRiderTempDeltaC.toStringAsFixed(1)}°C';
    return Wrap(
      spacing: isCompact ? 6 : 10,
      runSpacing: 6,
      children: [
        _CloudTelemetryChip(
          label: 'Plamy',
          value: '${widget.telemetry.activePatchCount}',
          accent: AppColors.accentBlue,
        ),
        _CloudTelemetryChip(
          label: 'Promienie',
          value: '${widget.telemetry.sunbeamShaftCount}',
          accent: AppColors.goldAccent,
        ),
        _CloudTelemetryChip(
          label: 'ΔTemp Kolarza',
          value: tempDeltaStr,
          accent: AppColors.statusSuccess,
        ),
      ],
    );
  }
}

class _CloudActionPill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _CloudActionPill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_CloudActionPill> createState() => _CloudActionPillState();
}

class _CloudActionPillState extends State<_CloudActionPill> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = !widget.enabled
        ? AppColors.background
        : widget.selected
            ? AppColors.primaryAccent.withValues(alpha: _pressed ? 0.95 : 0.85)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.65));

    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.75)
            : (_hovered ? AppColors.accentBlue : const Color(0xFF2A2F3D)));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: widget.enabled
                  ? (widget.selected ? AppColors.textPrimary : AppColors.textSecondary)
                  : AppColors.textSecondary.withValues(alpha: 0.45),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudTelemetryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _CloudTelemetryChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
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
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [ui.FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
