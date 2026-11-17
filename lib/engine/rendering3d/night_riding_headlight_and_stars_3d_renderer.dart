// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';

// =============================================================================
// 1. PRESETY BIOMÓW NOCNYCH, TRYBY LAMPEK I KAMERY
// =============================================================================

/// Charakterystyka atmosferyczna i wizualna nocnej jazdy 3D.
enum NightRidingBiomePreset {
  transcontinentalNight(
    labelPl: 'Alpy Nocą — Przełęcz Stelvio',
    shortTag: 'ALPY',
    skyZenithColor: Color(0xFF03060D),
    skyHorizonColor: Color(0xFF0B1424),
    silhouetteColor: Color(0xFF070B12),
    asphaltBaseColor: Color(0xFF0D1017),
    asphaltShoulderColor: Color(0xFF080A0F),
    starVisibilityMultiplier: 1.0,
    defaultFogDensity: 0.14,
    horizonGlowColor: Color(0xFF152642),
  ),
  prairieBikepacking(
    labelPl: 'Preria Ultra — Droga Mleczna',
    shortTag: 'PRERIA',
    skyZenithColor: Color(0xFF02040A),
    skyHorizonColor: Color(0xFF09111E),
    silhouetteColor: Color(0xFF06080D),
    asphaltBaseColor: Color(0xFF0E1118),
    asphaltShoulderColor: Color(0xFF090B10),
    starVisibilityMultiplier: 1.25,
    defaultFogDensity: 0.05,
    horizonGlowColor: Color(0xFF132238),
  ),
  foggyMountainPass(
    labelPl: 'Mglista Przełęcz — Wysoka Wilgotność',
    shortTag: 'MGŁA',
    skyZenithColor: Color(0xFF080C14),
    skyHorizonColor: Color(0xFF172130),
    silhouetteColor: Color(0xFF0D131D),
    asphaltBaseColor: Color(0xFF11151E),
    asphaltShoulderColor: Color(0xFF0A0D14),
    starVisibilityMultiplier: 0.42,
    defaultFogDensity: 0.62,
    horizonGlowColor: Color(0xFF233044),
  ),
  dawnApproaching(
    labelPl: 'Przedświt 04:45 — Złoty Horyzont',
    shortTag: 'ŚWIT',
    skyZenithColor: Color(0xFF080E1D),
    skyHorizonColor: Color(0xFF28202B),
    silhouetteColor: Color(0xFF0E121B),
    asphaltBaseColor: Color(0xFF131720),
    asphaltShoulderColor: Color(0xFF0C0F16),
    starVisibilityMultiplier: 0.55,
    defaultFogDensity: 0.18,
    horizonGlowColor: Color(0xFF54352B),
  );

  final String labelPl;
  final String shortTag;
  final Color skyZenithColor;
  final Color skyHorizonColor;
  final Color silhouetteColor;
  final Color asphaltBaseColor;
  final Color asphaltShoulderColor;
  final double starVisibilityMultiplier;
  final double defaultFogDensity;
  final Color horizonGlowColor;

  const NightRidingBiomePreset({
    required this.labelPl,
    required this.shortTag,
    required this.skyZenithColor,
    required this.skyHorizonColor,
    required this.silhouetteColor,
    required this.asphaltBaseColor,
    required this.asphaltShoulderColor,
    required this.starVisibilityMultiplier,
    required this.defaultFogDensity,
    required this.horizonGlowColor,
  });
}

/// Tryb pracy przedniej lampki LED kolarza.
enum HeadlightBeamMode {
  off(
    labelPl: 'Wyłączona',
    shortTag: 'OFF',
    lumens: 0,
    rangeMeters: 0.0,
    spreadAngleRad: 0.0,
    coreIntensity: 0.0,
    powerDrawWatts: 0.0,
  ),
  eco(
    labelPl: 'Eko 350 lm',
    shortTag: 'EKO',
    lumens: 350,
    rangeMeters: 32.0,
    spreadAngleRad: 0.34,
    coreIntensity: 0.48,
    powerDrawWatts: 3.2,
  ),
  standard(
    labelPl: 'Standard 800 lm',
    shortTag: 'STD',
    lumens: 800,
    rangeMeters: 58.0,
    spreadAngleRad: 0.42,
    coreIntensity: 0.78,
    powerDrawWatts: 6.8,
  ),
  highBeam(
    labelPl: 'Długie 1600 lm',
    shortTag: 'MAX',
    lumens: 1600,
    rangeMeters: 108.0,
    spreadAngleRad: 0.48,
    coreIntensity: 1.0,
    powerDrawWatts: 13.5,
  ),
  daylightFlash(
    labelPl: 'Błysk Strobe',
    shortTag: 'FLASH',
    lumens: 600,
    rangeMeters: 44.0,
    spreadAngleRad: 0.38,
    coreIntensity: 0.85,
    powerDrawWatts: 2.4,
  );

  final String labelPl;
  final String shortTag;
  final int lumens;
  final double rangeMeters;
  final double spreadAngleRad;
  final double coreIntensity;
  final double powerDrawWatts;

  const HeadlightBeamMode({
    required this.labelPl,
    required this.shortTag,
    required this.lumens,
    required this.rangeMeters,
    required this.spreadAngleRad,
    required this.coreIntensity,
    required this.powerDrawWatts,
  });
}

/// Tryb pracy tylnego czerwonego światła ostrzegawczego.
enum TaillightPulseMode {
  off(
    labelPl: 'Wyłączone',
    shortTag: 'OFF',
    visibilityMeters: 0.0,
    basePowerWatts: 0.0,
  ),
  steady(
    labelPl: 'Stałe Czerwone',
    shortTag: 'STAŁE',
    visibilityMeters: 420.0,
    basePowerWatts: 0.8,
  ),
  pelotonPulse(
    labelPl: 'Puls Peletonu',
    shortTag: 'PULS',
    visibilityMeters: 580.0,
    basePowerWatts: 0.5,
  ),
  radarAlert(
    labelPl: 'Radar Varia',
    shortTag: 'RADAR',
    visibilityMeters: 850.0,
    basePowerWatts: 1.1,
  );

  final String labelPl;
  final String shortTag;
  final double visibilityMeters;
  final double basePowerWatts;

  const TaillightPulseMode({
    required this.labelPl,
    required this.shortTag,
    required this.visibilityMeters,
    required this.basePowerWatts,
  });
}

/// Tryb kamery 3D w scenie jazdy nocnej.
enum NightCameraViewMode {
  chaseBehind(
    labelPl: 'Pościg z Tyłu',
    shortTag: 'TYŁ',
  ),
  cockpitFront(
    labelPl: 'Kokpit z Przodu',
    shortTag: 'FPP',
  ),
  helicopterSide(
    labelPl: 'Boczny Lot',
    shortTag: 'BOK',
  );

  final String labelPl;
  final String shortTag;

  const NightCameraViewMode({
    required this.labelPl,
    required this.shortTag,
  });
}

// =============================================================================
// 2. KONFIGURACJA I MODELE SCENY 3D
// =============================================================================

/// Konfiguracja renderera jazdy nocnej 3D.
class NightRiding3dConfig {
  final NightRidingBiomePreset biomePreset;
  final HeadlightBeamMode headlightMode;
  final TaillightPulseMode taillightMode;
  final NightCameraViewMode cameraMode;
  final int starCount;
  final bool showStars;
  final bool showMilkyWay;
  final double milkyWayIntensity;
  final double fogDensity;
  final int headlightColorTempKelvin;
  final double beamRangeMultiplier;
  final bool enableDynamoFlicker;
  final bool showTelemetryHud;

  const NightRiding3dConfig({
    this.biomePreset = NightRidingBiomePreset.transcontinentalNight,
    this.headlightMode = HeadlightBeamMode.highBeam,
    this.taillightMode = TaillightPulseMode.pelotonPulse,
    this.cameraMode = NightCameraViewMode.chaseBehind,
    this.starCount = 260,
    this.showStars = true,
    this.showMilkyWay = true,
    this.milkyWayIntensity = 0.72,
    this.fogDensity = 0.14,
    this.headlightColorTempKelvin = 5800,
    this.beamRangeMultiplier = 1.0,
    this.enableDynamoFlicker = true,
    this.showTelemetryHud = true,
  });

  NightRiding3dConfig copyWith({
    NightRidingBiomePreset? biomePreset,
    HeadlightBeamMode? headlightMode,
    TaillightPulseMode? taillightMode,
    NightCameraViewMode? cameraMode,
    int? starCount,
    bool? showStars,
    bool? showMilkyWay,
    double? milkyWayIntensity,
    double? fogDensity,
    int? headlightColorTempKelvin,
    double? beamRangeMultiplier,
    bool? enableDynamoFlicker,
    bool? showTelemetryHud,
  }) {
    return NightRiding3dConfig(
      biomePreset: biomePreset ?? this.biomePreset,
      headlightMode: headlightMode ?? this.headlightMode,
      taillightMode: taillightMode ?? this.taillightMode,
      cameraMode: cameraMode ?? this.cameraMode,
      starCount: starCount ?? this.starCount,
      showStars: showStars ?? this.showStars,
      showMilkyWay: showMilkyWay ?? this.showMilkyWay,
      milkyWayIntensity: milkyWayIntensity ?? this.milkyWayIntensity,
      fogDensity: fogDensity ?? this.fogDensity,
      headlightColorTempKelvin:
          headlightColorTempKelvin ?? this.headlightColorTempKelvin,
      beamRangeMultiplier: beamRangeMultiplier ?? this.beamRangeMultiplier,
      enableDynamoFlicker: enableDynamoFlicker ?? this.enableDynamoFlicker,
      showTelemetryHud: showTelemetryHud ?? this.showTelemetryHud,
    );
  }
}

/// Pojedyncza gwiazda na nocnym nieboskłonie 3D.
class NightStar3D {
  final double azimuthRadians;
  final double elevationRadians;
  final double magnitude;
  final double radiusPx;
  final Color tintColor;
  final double twinklePhase;
  final double twinkleSpeed;
  final bool isMilkyWayBand;

  const NightStar3D({
    required this.azimuthRadians,
    required this.elevationRadians,
    required this.magnitude,
    required this.radiusPx,
    required this.tintColor,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.isMilkyWayBand,
  });
}

/// Kolarz wyposażony w przednią lampkę LED i tylne światło czerwone.
class NightRiderLightEmitter3D {
  final String riderId;
  final String name;
  final Color jerseyColor;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final double speedMs;
  final HeadlightBeamMode headlightMode;
  final TaillightPulseMode taillightMode;
  final double batteryPercent;
  final bool isPlayer;
  final double yawRadians;

  const NightRiderLightEmitter3D({
    required this.riderId,
    required this.name,
    required this.jerseyColor,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    this.elevationMeters = 0.0,
    this.speedMs = 9.5,
    this.headlightMode = HeadlightBeamMode.standard,
    this.taillightMode = TaillightPulseMode.pelotonPulse,
    this.batteryPercent = 88.0,
    this.isPlayer = false,
    this.yawRadians = 0.0,
  });

  NightRiderLightEmitter3D copyWith({
    double? distanceMeters,
    double? lateralOffsetMeters,
    double? elevationMeters,
    double? speedMs,
    HeadlightBeamMode? headlightMode,
    TaillightPulseMode? taillightMode,
    double? batteryPercent,
    double? yawRadians,
  }) {
    return NightRiderLightEmitter3D(
      riderId: riderId,
      name: name,
      jerseyColor: jerseyColor,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      speedMs: speedMs ?? this.speedMs,
      headlightMode: headlightMode ?? this.headlightMode,
      taillightMode: taillightMode ?? this.taillightMode,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isPlayer: isPlayer,
      yawRadians: yawRadians ?? this.yawRadians,
    );
  }
}

/// Przydrożny słupek odblaskowy reagujący na stożek przedniej lampki LED.
class NightRoadSignReflector3D {
  final double distanceMeters;
  final double lateralOffsetMeters;
  final bool isRightSide;
  final double heightMeters;

  const NightRoadSignReflector3D({
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    required this.isRightSide,
    this.heightMeters = 0.85,
  });
}

/// Zrzut telemetrii klatki renderera nocnego.
class NightRidingFrameTelemetry {
  final int activeHeadlightLumens;
  final double effectiveBeamRangeMeters;
  final double beamPeakLux;
  final int visibleStarsCount;
  final double ambientSkyLuminance;
  final double batteryRemainingPercent;
  final double dynamoOutputWatts;
  final double taillightVisibilityMeters;
  final int projectedRidersCount;
  final int illuminatedReflectorsCount;
  final double currentSpeedKmh;

  const NightRidingFrameTelemetry({
    required this.activeHeadlightLumens,
    required this.effectiveBeamRangeMeters,
    required this.beamPeakLux,
    required this.visibleStarsCount,
    required this.ambientSkyLuminance,
    required this.batteryRemainingPercent,
    required this.dynamoOutputWatts,
    required this.taillightVisibilityMeters,
    required this.projectedRidersCount,
    required this.illuminatedReflectorsCount,
    required this.currentSpeedKmh,
  });
}

// =============================================================================
// 3. SILNIK GEOMETRII I PROJEKCJI 3D JAZDY NOCNEJ
// =============================================================================

/// Silnik renderowania 3D jazdy nocnej: zarządza polem gwiazd, fizyką stożka
/// przedniej lampki LED, czerwonym światłem tylnym, odblaskami i projekcją 3D.
class NightRidingHeadlightAndStars3dRenderer {
  NightRiding3dConfig _config;
  double _elapsedSeconds = 0.0;
  double _cameraDistanceMeters = 0.0;
  double _roadCurvature = 0.0022;
  double _gradientPercent = 2.5;
  double _playerBatteryPercent = 86.0;
  double _dynamoOutputWatts = 5.4;

  late List<NightStar3D> _stars;
  final List<NightRiderLightEmitter3D> _riders = <NightRiderLightEmitter3D>[];
  final List<NightRoadSignReflector3D> _reflectors =
      <NightRoadSignReflector3D>[];
  NightRidingFrameTelemetry _latestTelemetry = const NightRidingFrameTelemetry(
    activeHeadlightLumens: 1600,
    effectiveBeamRangeMeters: 108.0,
    beamPeakLux: 142.0,
    visibleStarsCount: 260,
    ambientSkyLuminance: 0.04,
    batteryRemainingPercent: 86.0,
    dynamoOutputWatts: 5.4,
    taillightVisibilityMeters: 580.0,
    projectedRidersCount: 0,
    illuminatedReflectorsCount: 0,
    currentSpeedKmh: 34.2,
  );

  NightRidingHeadlightAndStars3dRenderer({
    NightRiding3dConfig config = const NightRiding3dConfig(),
    int seed = 520,
  }) : _config = config {
    _stars = _generateDeterministicStarfield(
      count: config.starCount,
      seed: seed,
    );
    _seedDefaultNightPeloton();
    _seedRoadsideReflectors();
    _recomputeTelemetry(projectedRiders: _riders.length, illuminatedRefs: 4);
  }

  NightRiding3dConfig get config => _config;
  double get elapsedSeconds => _elapsedSeconds;
  double get cameraDistanceMeters => _cameraDistanceMeters;
  double get roadCurvature => _roadCurvature;
  double get gradientPercent => _gradientPercent;
  List<NightStar3D> get stars => List<NightStar3D>.unmodifiable(_stars);
  List<NightRiderLightEmitter3D> get riders =>
      List<NightRiderLightEmitter3D>.unmodifiable(_riders);
  List<NightRoadSignReflector3D> get reflectors =>
      List<NightRoadSignReflector3D>.unmodifiable(_reflectors);
  NightRidingFrameTelemetry get latestTelemetry => _latestTelemetry;

  /// Aktualizuje konfigurację sceny i w razie zmiany liczby gwiazd przebudowuje nieboskłon.
  void updateConfig(NightRiding3dConfig newConfig) {
    final bool starCountChanged = newConfig.starCount != _config.starCount;
    _config = newConfig;
    if (starCountChanged) {
      _stars = _generateDeterministicStarfield(
        count: newConfig.starCount.clamp(0, 800),
        seed: 520,
      );
    }
    if (_riders.isNotEmpty) {
      _riders[0] = _riders[0].copyWith(
        headlightMode: newConfig.headlightMode,
        taillightMode: newConfig.taillightMode,
      );
    }
    _recomputeTelemetry(
      projectedRiders: _riders.length,
      illuminatedRefs: _countIlluminatedReflectors(),
    );
  }

  /// Ustawia stan baterii akumulatora (0–100%).
  void setBatteryPercent(double percent) {
    _playerBatteryPercent = percent.clamp(0.0, 100.0);
    if (_riders.isNotEmpty) {
      _riders[0] = _riders[0].copyWith(batteryPercent: _playerBatteryPercent);
    }
    _recomputeTelemetry(
      projectedRiders: _riders.length,
      illuminatedRefs: _countIlluminatedReflectors(),
    );
  }

  /// Zwraca kolor przedniej diody LED na podstawie temperatury barwowej w Kelwinach.
  Color get headlightKelvinColor {
    final int k = _config.headlightColorTempKelvin.clamp(3000, 7500);
    if (k < 4300) {
      return const Color(0xFFFFE4B5); // Ciepła biel halogenowa/LED
    } else if (k < 5600) {
      return const Color(0xFFF6F9FF); // Neutralna biel
    } else {
      return const Color(0xFFE0F2FE); // Zimna biel 6000K+
    }
  }

  /// Oblicza aktualną jasność przedniej lampki (uwzględniając błysk, dynamo i baterię).
  double computeHeadlightPulseFactor() {
    final HeadlightBeamMode mode = effectiveHeadlightMode;
    if (mode == HeadlightBeamMode.off) return 0.0;

    if (mode == HeadlightBeamMode.daylightFlash) {
      final double cycle = (_elapsedSeconds * 2.4) % 1.0;
      return (cycle < 0.18 || (cycle > 0.28 && cycle < 0.42)) ? 1.0 : 0.14;
    }

    if (_config.enableDynamoFlicker && _riders.isNotEmpty) {
      final double speedMs = _riders.first.speedMs;
      if (speedMs < 3.5) {
        final double ripple =
            0.82 + 0.18 * math.sin(_elapsedSeconds * 18.0).abs();
        return ripple;
      }
    }
    return 1.0;
  }

  /// Zwraca efektywny tryb przedniej lampki (wyłącza się, gdy bateria spadnie do 0%).
  HeadlightBeamMode get effectiveHeadlightMode {
    if (_playerBatteryPercent <= 0.05) {
      return HeadlightBeamMode.off;
    }
    return _config.headlightMode;
  }

  /// Oblicza intensywność tylnego czerwonego światła w bieżącej chwili [0.0..1.0].
  double computeTaillightPulseFactor(TaillightPulseMode mode, double phaseBias) {
    if (_playerBatteryPercent <= 0.05 && mode != TaillightPulseMode.off) {
      return 0.08;
    }
    switch (mode) {
      case TaillightPulseMode.off:
        return 0.0;
      case TaillightPulseMode.steady:
        return 0.92;
      case TaillightPulseMode.pelotonPulse:
        return 0.42 +
            0.58 *
                (0.5 + 0.5 * math.sin(_elapsedSeconds * 3.8 + phaseBias));
      case TaillightPulseMode.radarAlert:
        final double t = (_elapsedSeconds * 3.2 + phaseBias) % 1.0;
        if (t < 0.14 || (t > 0.22 && t < 0.36)) return 1.0;
        return 0.16;
    }
  }

  /// Przesuwa symulację o [dtSeconds] sekund.
  void advanceFrame(
    double dtSeconds, {
    double? speedMs,
    double? roadCurvature,
    double? gradientPercent,
  }) {
    final double clampedDt = dtSeconds.clamp(0.0, 0.25);
    _elapsedSeconds += clampedDt;

    if (roadCurvature != null) {
      _roadCurvature = roadCurvature.clamp(-0.025, 0.025);
    } else {
      // Łagodne kręte zakręty górskiej drogi
      _roadCurvature = 0.0028 * math.sin(_elapsedSeconds * 0.28);
    }

    if (gradientPercent != null) {
      _gradientPercent = gradientPercent.clamp(-18.0, 22.0);
    }

    final double baseSpeed = speedMs ??
        (_riders.isNotEmpty ? _riders.first.speedMs : 9.5).clamp(1.0, 28.0);
    _cameraDistanceMeters += baseSpeed * clampedDt;

    // Dynamo piasty generuje moc z prędkości, zasilając częściowo lampki
    _dynamoOutputWatts = (baseSpeed * 0.58).clamp(0.0, 9.2);
    final double totalDrawWatts =
        effectiveHeadlightMode.powerDrawWatts + _config.taillightMode.basePowerWatts;
    final double netDrainWatts = math.max(0.0, totalDrawWatts - _dynamoOutputWatts * 0.55);
    // Skala przyspieszona lekko na potrzeby podglądu (ok. 1% na ~35s przy 1600 lm)
    _playerBatteryPercent =
        (_playerBatteryPercent - netDrainWatts * clampedDt * 0.0032)
            .clamp(0.0, 100.0);

    for (int i = 0; i < _riders.length; i++) {
      final NightRiderLightEmitter3D r = _riders[i];
      final double rSpeed = i == 0 ? baseSpeed : r.speedMs;
      final double newDist = r.distanceMeters + rSpeed * clampedDt;
      if (i == 0) {
        _riders[i] = r.copyWith(
          distanceMeters: newDist,
          speedMs: rSpeed,
          batteryPercent: _playerBatteryPercent,
          headlightMode: _config.headlightMode,
          taillightMode: _config.taillightMode,
          yawRadians: _roadCurvature * 12.0,
        );
      } else {
        // Utrzymujemy peleton wokół gracza w oknie -12..+85 m
        double rel = newDist - _cameraDistanceMeters;
        double adjustedDist = newDist;
        if (rel > 95.0) {
          adjustedDist = _cameraDistanceMeters - 10.0;
        } else if (rel < -18.0) {
          adjustedDist = _cameraDistanceMeters + 85.0;
        }
        _riders[i] = r.copyWith(
          distanceMeters: adjustedDist,
          yawRadians: _roadCurvature * 10.0,
        );
      }
    }

    // Recykling słupków odblaskowych przed kamerą
    for (int i = 0; i < _reflectors.length; i++) {
      final NightRoadSignReflector3D ref = _reflectors[i];
      if (ref.distanceMeters < _cameraDistanceMeters - 4.0) {
        _reflectors[i] = NightRoadSignReflector3D(
          distanceMeters: ref.distanceMeters + 240.0,
          lateralOffsetMeters: ref.lateralOffsetMeters,
          isRightSide: ref.isRightSide,
          heightMeters: ref.heightMeters,
        );
      }
    }

    _recomputeTelemetry(
      projectedRiders: _riders.length,
      illuminatedRefs: _countIlluminatedReflectors(),
    );
  }

  /// Rzutuje punkt świata drogi (relatywny dystans przed kamerą, pozycja boczna, wysokość)
  /// na współrzędne ekranu 2D [Offset] oraz głębię `z`.
  ProjectedNightPoint3D? projectRoadRelativePoint({
    required double forwardMeters,
    required double lateralMeters,
    required double heightMeters,
    required Size viewportSize,
  }) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return null;

    // Uwzględniamy krzywiznę drogi: x_curve = 0.5 * curvature * d^2
    final double curveX = 0.5 * _roadCurvature * forwardMeters * forwardMeters;
    final double slopeY = (_gradientPercent / 100.0) * forwardMeters * 0.35;

    final Vector3 worldPos = Vector3(
      lateralMeters + curveX,
      heightMeters + slopeY,
      forwardMeters,
    );

    final Vector3 camPos;
    final double camPitch;
    final double camYaw;
    switch (_config.cameraMode) {
      case NightCameraViewMode.chaseBehind:
        camPos = Vector3(0.0, 2.25, -5.8);
        camPitch = -0.10;
        camYaw = 0.0;
        break;
      case NightCameraViewMode.cockpitFront:
        camPos = Vector3(0.0, 1.32, 0.35);
        camPitch = -0.05;
        camYaw = 0.0;
        break;
      case NightCameraViewMode.helicopterSide:
        camPos = Vector3(-9.5, 5.4, -7.5);
        camPitch = -0.24;
        camYaw = 0.42;
        break;
    }

    final Vector3 rel = worldPos - camPos;

    // Obrót wokół Y (yaw)
    final double cosY = math.cos(camYaw);
    final double sinY = math.sin(camYaw);
    final double x1 = rel.x * cosY - rel.z * sinY;
    final double z1 = rel.x * sinY + rel.z * cosY;

    // Obrót wokół X (pitch)
    final double cosP = math.cos(camPitch);
    final double sinP = math.sin(camPitch);
    final double y2 = rel.y * cosP - z1 * sinP;
    final double z2 = rel.y * sinP + z1 * cosP;

    if (z2 <= 0.35) return null;

    final double fovScale = viewportSize.height * 0.88;
    final double screenX = viewportSize.width * 0.5 + (x1 / z2) * fovScale;
    final double screenY = viewportSize.height * 0.46 - (y2 / z2) * fovScale;

    return ProjectedNightPoint3D(
      screenOffset: Offset(screenX, screenY),
      depthMeters: z2,
      scaleFactor: fovScale / z2,
    );
  }

  /// Oblicza współczynnik rozświetlenia punktu w przestrzeni przez stożek lampki gracza [0..1].
  double evaluateHeadlightIlluminationAt({
    required double forwardMeters,
    required double lateralMeters,
  }) {
    final HeadlightBeamMode mode = effectiveHeadlightMode;
    if (mode == HeadlightBeamMode.off) return 0.0;

    final double range = mode.rangeMeters * _config.beamRangeMultiplier;
    if (forwardMeters <= 0.4 || forwardMeters > range) return 0.0;

    final double curveCenter =
        0.5 * _roadCurvature * forwardMeters * forwardMeters;
    final double dx = (lateralMeters - curveCenter).abs();
    final double halfWidthAtDist =
        math.tan(mode.spreadAngleRad) * forwardMeters + 0.45;
    if (dx > halfWidthAtDist) return 0.0;

    final double distFactor =
        math.pow(1.0 - (forwardMeters / range), 1.45).toDouble();
    final double angularFactor =
        math.pow(1.0 - (dx / halfWidthAtDist), 1.6).toDouble();
    return (distFactor * angularFactor * mode.coreIntensity * computeHeadlightPulseFactor())
        .clamp(0.0, 1.0);
  }

  int _countIlluminatedReflectors() {
    int count = 0;
    for (final NightRoadSignReflector3D ref in _reflectors) {
      final double fwd = ref.distanceMeters - _cameraDistanceMeters;
      if (evaluateHeadlightIlluminationAt(
            forwardMeters: fwd,
            lateralMeters: ref.lateralOffsetMeters,
          ) >
          0.08) {
        count++;
      }
    }
    return count;
  }

  void _recomputeTelemetry({
    required int projectedRiders,
    required int illuminatedRefs,
  }) {
    final HeadlightBeamMode mode = effectiveHeadlightMode;
    final double effectiveRange =
        mode.rangeMeters * _config.beamRangeMultiplier;
    final double fogAttenuation = 1.0 - (_config.fogDensity.clamp(0.0, 1.0) * 0.45);
    final double peakLux = mode == HeadlightBeamMode.off
        ? 0.0
        : (mode.lumens * 0.088 * computeHeadlightPulseFactor() * fogAttenuation);

    final double starMult =
        _config.showStars ? _config.biomePreset.starVisibilityMultiplier : 0.0;
    final int visibleStars =
        (_stars.length * starMult * (1.0 - _config.fogDensity * 0.72))
            .round()
            .clamp(0, _stars.length);

    final double speedKmh =
        (_riders.isNotEmpty ? _riders.first.speedMs : 9.5) * 3.6;

    _latestTelemetry = NightRidingFrameTelemetry(
      activeHeadlightLumens: mode.lumens,
      effectiveBeamRangeMeters: effectiveRange * fogAttenuation,
      beamPeakLux: peakLux,
      visibleStarsCount: visibleStars,
      ambientSkyLuminance:
          _config.biomePreset == NightRidingBiomePreset.dawnApproaching
              ? 0.18
              : 0.04,
      batteryRemainingPercent: _playerBatteryPercent,
      dynamoOutputWatts: _dynamoOutputWatts,
      taillightVisibilityMeters: _config.taillightMode.visibilityMeters,
      projectedRidersCount: projectedRiders,
      illuminatedReflectorsCount: illuminatedRefs,
      currentSpeedKmh: speedKmh,
    );
  }

  List<NightStar3D> _generateDeterministicStarfield({
    required int count,
    required int seed,
  }) {
    final math.Random rng = math.Random(seed);
    final List<NightStar3D> generated = <NightStar3D>[];
    const List<Color> starTints = <Color>[
      Color(0xFFFFFFFF),
      Color(0xFFDCEBFF), // Błękitny olbrzym O/B
      Color(0xFFFFF1D6), // Żółty karzeł G
      Color(0xFFFFD8B0), // Pomarańczowy K
    ];

    for (int i = 0; i < count; i++) {
      final bool isMilkyWay = i % 3 == 0;
      final double azimuth = (rng.nextDouble() - 0.5) * math.pi * 1.45;
      double elevation;
      if (isMilkyWay) {
        // Skośne pasmo Drogi Mlecznej przez nieboskłon
        final double bandCenter = 0.24 + 0.18 * azimuth;
        elevation =
            (bandCenter + (rng.nextDouble() - 0.5) * 0.24).clamp(0.02, 0.78);
      } else {
        elevation = 0.02 + rng.nextDouble() * 0.76;
      }

      final double mag =
          isMilkyWay ? 0.25 + rng.nextDouble() * 0.55 : 0.35 + rng.nextDouble() * 0.65;
      final double radius =
          isMilkyWay ? 0.7 + rng.nextDouble() * 1.2 : 0.9 + rng.nextDouble() * 1.7;

      generated.add(
        NightStar3D(
          azimuthRadians: azimuth,
          elevationRadians: elevation,
          magnitude: mag,
          radiusPx: radius,
          tintColor: starTints[rng.nextInt(starTints.length)],
          twinklePhase: rng.nextDouble() * math.pi * 2.0,
          twinkleSpeed: 1.1 + rng.nextDouble() * 2.6,
          isMilkyWayBand: isMilkyWay,
        ),
      );
    }
    return generated;
  }

  void _seedDefaultNightPeloton() {
    _riders
      ..clear()
      ..addAll(<NightRiderLightEmitter3D>[
        NightRiderLightEmitter3D(
          riderId: 'player_leader',
          name: 'Lider Drużyny',
          jerseyColor: AppColors.goldAccent,
          distanceMeters: 0.0,
          lateralOffsetMeters: 0.0,
          speedMs: 9.5,
          headlightMode: _config.headlightMode,
          taillightMode: _config.taillightMode,
          batteryPercent: _playerBatteryPercent,
          isPlayer: true,
        ),
        const NightRiderLightEmitter3D(
          riderId: 'rival_1',
          name: 'K. Vauquelin',
          jerseyColor: AppColors.accentBlue,
          distanceMeters: 16.5,
          lateralOffsetMeters: -1.15,
          speedMs: 9.8,
          headlightMode: HeadlightBeamMode.standard,
          taillightMode: TaillightPulseMode.pelotonPulse,
        ),
        const NightRiderLightEmitter3D(
          riderId: 'rival_2',
          name: 'M. Jorgenson',
          jerseyColor: AppColors.statusSuccess,
          distanceMeters: 29.0,
          lateralOffsetMeters: 1.05,
          speedMs: 9.6,
          headlightMode: HeadlightBeamMode.highBeam,
          taillightMode: TaillightPulseMode.radarAlert,
        ),
        const NightRiderLightEmitter3D(
          riderId: 'rival_3',
          name: 'A. Yates',
          jerseyColor: AppColors.primaryAccent,
          distanceMeters: 46.0,
          lateralOffsetMeters: -0.45,
          speedMs: 9.9,
          headlightMode: HeadlightBeamMode.eco,
          taillightMode: TaillightPulseMode.steady,
        ),
      ]);
  }

  void _seedRoadsideReflectors() {
    _reflectors.clear();
    for (int i = 1; i <= 16; i++) {
      final double d = i * 15.0;
      _reflectors.add(
        NightRoadSignReflector3D(
          distanceMeters: d,
          lateralOffsetMeters: -3.9,
          isRightSide: false,
        ),
      );
      _reflectors.add(
        NightRoadSignReflector3D(
          distanceMeters: d,
          lateralOffsetMeters: 3.9,
          isRightSide: true,
        ),
      );
    }
  }
}

/// Wynik rzutowania punktu 3D na przestrzeń ekranu.
class ProjectedNightPoint3D {
  final Offset screenOffset;
  final double depthMeters;
  final double scaleFactor;

  const ProjectedNightPoint3D({
    required this.screenOffset,
    required this.depthMeters,
    required this.scaleFactor,
  });
}

// =============================================================================
// 4. CUSTOM PAINTER SCENY NOCNEJ 3D
// =============================================================================

/// Painter 3D renderujący nocny nieboskłon z gwiazdami, Drogę Mleczną, szosę,
/// stożek przedniej lampki LED, odblaski oraz czerwone światło tylne.
class NightRidingHeadlightAndStars3dPainter extends CustomPainter {
  final NightRidingHeadlightAndStars3dRenderer renderer;
  final double animationTick;

  const NightRidingHeadlightAndStars3dPainter({
    required this.renderer,
    required this.animationTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0) return;

    final NightRiding3dConfig cfg = renderer.config;
    final NightRidingBiomePreset biome = cfg.biomePreset;
    final double horizonY = size.height * 0.44;

    _paintNightSkyAndMilkyWay(canvas, size, horizonY, cfg, biome);
    _paintStars(canvas, size, horizonY, cfg, biome);
    _paintHorizonMountains(canvas, size, horizonY, biome);
    _paintNightRoadRibbon(canvas, size, biome);
    _paintRoadsideReflectors(canvas, size);
    _paintHeadlightConesAndRiders(canvas, size, cfg);
    _paintAtmosphericFogVeil(canvas, size, horizonY, cfg, biome);
  }

  void _paintNightSkyAndMilkyWay(
    Canvas canvas,
    Size size,
    double horizonY,
    NightRiding3dConfig cfg,
    NightRidingBiomePreset biome,
  ) {
    final Rect skyRect = Rect.fromLTWH(0, 0, size.width, horizonY + 32);
    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          biome.skyZenithColor,
          biome.skyHorizonColor,
          biome.horizonGlowColor,
        ],
        stops: const <double>[0.0, 0.72, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Subtelny sierp księżyca w prawej górnej części nieba
    final Offset moonCenter = Offset(size.width * 0.80, size.height * 0.12);
    final double moonAlpha =
        (0.85 - cfg.fogDensity * 0.65).clamp(0.15, 0.85);
    canvas.drawCircle(
      moonCenter,
      26.0,
      Paint()
        ..color = const Color(0xFFDBEAFE).withValues(alpha: moonAlpha * 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0),
    );
    canvas.saveLayer(
      Rect.fromCircle(center: moonCenter, radius: 18.0),
      Paint(),
    );
    canvas.drawCircle(
      moonCenter,
      11.5,
      Paint()
        ..color = const Color(0xFFF3F4F6).withValues(alpha: moonAlpha),
    );
    canvas.drawCircle(
      moonCenter + const Offset(-4.5, -2.5),
      10.2,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Pasmo Drogi Mlecznej
    if (cfg.showMilkyWay && cfg.milkyWayIntensity > 0.02) {
      final double mwAlpha =
          (cfg.milkyWayIntensity * (1.0 - cfg.fogDensity * 0.8))
              .clamp(0.0, 0.45);
      if (mwAlpha > 0.01) {
        canvas.save();
        canvas.translate(size.width * 0.5, horizonY * 0.48);
        canvas.rotate(-0.32);
        final Rect mwRect = Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 1.4,
          height: horizonY * 0.34,
        );
        final Paint mwPaint = Paint()
          ..shader = RadialGradient(
            radius: 0.75,
            colors: <Color>[
              const Color(0xFF93C5FD).withValues(alpha: mwAlpha * 0.35),
              const Color(0xFF6366F1).withValues(alpha: mwAlpha * 0.16),
              Colors.transparent,
            ],
          ).createShader(mwRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26.0);
        canvas.drawOval(mwRect, mwPaint);
        canvas.restore();
      }
    }
  }

  void _paintStars(
    Canvas canvas,
    Size size,
    double horizonY,
    NightRiding3dConfig cfg,
    NightRidingBiomePreset biome,
  ) {
    if (!cfg.showStars) return;
    final double fogFactor = (1.0 - cfg.fogDensity * 0.78).clamp(0.12, 1.0);
    final double yawOffset = renderer.roadCurvature * 16.0;
    final Paint starPaint = Paint()..style = PaintingStyle.fill;

    for (final NightStar3D star in renderer.stars) {
      final double normX =
          0.5 + ((star.azimuthRadians - yawOffset) / (math.pi * 1.15));
      if (normX < -0.05 || normX > 1.05) continue;

      final double normY = 1.0 - (star.elevationRadians / 0.82);
      final double sx = normX * size.width;
      final double sy = normY * horizonY;
      if (sy < 2.0 || sy > horizonY - 4.0) continue;

      final double twinkle = 0.65 +
          0.35 *
              math.sin(
                renderer.elapsedSeconds * star.twinkleSpeed + star.twinklePhase,
              );
      final double alpha = (star.magnitude *
              twinkle *
              biome.starVisibilityMultiplier *
              fogFactor)
          .clamp(0.05, 1.0);

      starPaint.color = star.tintColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(sx, sy), star.radiusPx, starPaint);

      if (star.magnitude > 0.82 && !star.isMilkyWayBand) {
        starPaint.color = star.tintColor.withValues(alpha: alpha * 0.28);
        canvas.drawCircle(Offset(sx, sy), star.radiusPx * 2.4, starPaint);
      }
    }
  }

  void _paintHorizonMountains(
    Canvas canvas,
    Size size,
    double horizonY,
    NightRidingBiomePreset biome,
  ) {
    final Path mountainPath = Path()..moveTo(0, horizonY + 12);
    const int segments = 12;
    for (int i = 0; i <= segments; i++) {
      final double t = i / segments;
      final double x = t * size.width;
      final double peakH = biome == NightRidingBiomePreset.prairieBikepacking
          ? 8.0 + 6.0 * math.sin(t * math.pi * 3.0)
          : 18.0 +
              26.0 * math.sin(t * math.pi * 2.4 + 0.6).abs() +
              12.0 * math.cos(t * math.pi * 5.2);
      mountainPath.lineTo(x, horizonY - peakH);
    }
    mountainPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(mountainPath, Paint()..color = biome.silhouetteColor);
  }

  void _paintNightRoadRibbon(
    Canvas canvas,
    Size size,
    NightRidingBiomePreset biome,
  ) {
    // Tło terenu po bokach drogi
    final double horizonY = size.height * 0.44;
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      Paint()..color = biome.asphaltShoulderColor,
    );

    const double roadHalfWidth = 3.6;
    const int sliceCount = 26;
    final List<double> distances = List<double>.generate(
      sliceCount + 1,
      (int i) => 1.5 + math.pow(i / sliceCount, 1.65) * 145.0,
    );

    final Path roadPath = Path();
    final List<Offset> leftPts = <Offset>[];
    final List<Offset> rightPts = <Offset>[];

    for (final double d in distances) {
      final ProjectedNightPoint3D? lPt = renderer.projectRoadRelativePoint(
        forwardMeters: d,
        lateralMeters: -roadHalfWidth,
        heightMeters: 0.0,
        viewportSize: size,
      );
      final ProjectedNightPoint3D? rPt = renderer.projectRoadRelativePoint(
        forwardMeters: d,
        lateralMeters: roadHalfWidth,
        heightMeters: 0.0,
        viewportSize: size,
      );
      if (lPt != null && rPt != null) {
        leftPts.add(lPt.screenOffset);
        rightPts.add(rPt.screenOffset);
      }
    }

    if (leftPts.length < 2) return;

    roadPath.moveTo(leftPts.first.dx, leftPts.first.dy);
    for (int i = 1; i < leftPts.length; i++) {
      roadPath.lineTo(leftPts[i].dx, leftPts[i].dy);
    }
    for (int i = rightPts.length - 1; i >= 0; i--) {
      roadPath.lineTo(rightPts[i].dx, rightPts[i].dy);
    }
    roadPath.close();

    canvas.drawPath(roadPath, Paint()..color = biome.asphaltBaseColor);

    // Przerywana linia środkowa i krawędzie drogi (rozświetlone przez lampkę)
    final double basePhase = renderer.cameraDistanceMeters % 10.0;
    final Paint linePaint = Paint()..style = PaintingStyle.stroke;

    for (double d = 2.0; d < 125.0; d += 5.0) {
      final double worldD = d + (10.0 - basePhase);
      final bool isDash = ((worldD / 5.0).floor() % 2) == 0;
      if (!isDash) continue;

      final ProjectedNightPoint3D? p1 = renderer.projectRoadRelativePoint(
        forwardMeters: d,
        lateralMeters: 0.0,
        heightMeters: 0.02,
        viewportSize: size,
      );
      final ProjectedNightPoint3D? p2 = renderer.projectRoadRelativePoint(
        forwardMeters: d + 2.4,
        lateralMeters: 0.0,
        heightMeters: 0.02,
        viewportSize: size,
      );
      if (p1 == null || p2 == null) continue;

      final double illum = renderer.evaluateHeadlightIlluminationAt(
        forwardMeters: d,
        lateralMeters: 0.0,
      );
      final double alpha = (0.14 + illum * 0.78).clamp(0.08, 0.95);
      linePaint
        ..color = AppColors.textPrimary.withValues(alpha: alpha)
        ..strokeWidth = (p1.scaleFactor * 0.11).clamp(1.0, 4.5);
      canvas.drawLine(p1.screenOffset, p2.screenOffset, linePaint);
    }
  }

  void _paintRoadsideReflectors(Canvas canvas, Size size) {
    for (final NightRoadSignReflector3D ref in renderer.reflectors) {
      final double fwd = ref.distanceMeters - renderer.cameraDistanceMeters;
      if (fwd < 1.5 || fwd > 130.0) continue;

      final ProjectedNightPoint3D? basePt = renderer.projectRoadRelativePoint(
        forwardMeters: fwd,
        lateralMeters: ref.lateralOffsetMeters,
        heightMeters: 0.0,
        viewportSize: size,
      );
      final ProjectedNightPoint3D? topPt = renderer.projectRoadRelativePoint(
        forwardMeters: fwd,
        lateralMeters: ref.lateralOffsetMeters,
        heightMeters: ref.heightMeters,
        viewportSize: size,
      );
      if (basePt == null || topPt == null) continue;

      final double illum = renderer.evaluateHeadlightIlluminationAt(
        forwardMeters: fwd,
        lateralMeters: ref.lateralOffsetMeters,
      );

      final Paint postPaint = Paint()
        ..color = const Color(0xFF1F2430)
        ..strokeWidth = (basePt.scaleFactor * 0.14).clamp(1.5, 5.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(basePt.screenOffset, topPt.screenOffset, postPaint);

      // Odblask na słupku (prawy: pomarańczowo-czerwony, lewy: biały)
      final Color reflectorColor = ref.isRightSide
          ? AppColors.amberWarning
          : const Color(0xFFF8FAFC);
      final double glowAlpha = (0.18 + illum * 0.82).clamp(0.15, 1.0);
      final double radius =
          ((basePt.scaleFactor * 0.11) * (1.0 + illum * 0.75)).clamp(1.5, 7.5);

      if (illum > 0.12) {
        canvas.drawCircle(
          topPt.screenOffset,
          radius * 2.4,
          Paint()
            ..color = reflectorColor.withValues(alpha: illum * 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
        );
      }
      canvas.drawCircle(
        topPt.screenOffset,
        radius,
        Paint()..color = reflectorColor.withValues(alpha: glowAlpha),
      );
    }
  }

  void _paintHeadlightConesAndRiders(
    Canvas canvas,
    Size size,
    NightRiding3dConfig cfg,
  ) {
    final List<NightRiderLightEmitter3D> sorted =
        List<NightRiderLightEmitter3D>.from(renderer.riders)
          ..sort(
            (NightRiderLightEmitter3D a, NightRiderLightEmitter3D b) =>
                b.distanceMeters.compareTo(a.distanceMeters),
          );

    for (final NightRiderLightEmitter3D rider in sorted) {
      final double fwd = rider.distanceMeters - renderer.cameraDistanceMeters;
      if (fwd < -3.0 || fwd > 125.0) continue;

      _paintRiderHeadlightCone(canvas, size, rider, fwd, cfg);
      _paintRiderBodyAndTaillight(canvas, size, rider, fwd);
    }
  }

  void _paintRiderHeadlightCone(
    Canvas canvas,
    Size size,
    NightRiderLightEmitter3D rider,
    double fwd,
    NightRiding3dConfig cfg,
  ) {
    final HeadlightBeamMode mode = rider.isPlayer
        ? renderer.effectiveHeadlightMode
        : rider.headlightMode;
    if (mode == HeadlightBeamMode.off) return;

    final double pulse =
        rider.isPlayer ? renderer.computeHeadlightPulseFactor() : 0.92;
    if (pulse <= 0.02) return;

    final double range = mode.rangeMeters * cfg.beamRangeMultiplier;
    final double startFwd = fwd + 0.75;
    final double endFwd = fwd + range;
    if (endFwd <= 1.0) return;

    final ProjectedNightPoint3D? emitterPt = renderer.projectRoadRelativePoint(
      forwardMeters: math.max(0.5, startFwd),
      lateralMeters: rider.lateralOffsetMeters,
      heightMeters: 1.02,
      viewportSize: size,
    );
    final ProjectedNightPoint3D? farCenterPt =
        renderer.projectRoadRelativePoint(
      forwardMeters: endFwd,
      lateralMeters: rider.lateralOffsetMeters,
      heightMeters: 0.04,
      viewportSize: size,
    );
    final double halfSpread = math.tan(mode.spreadAngleRad) * range;
    final ProjectedNightPoint3D? farLeftPt = renderer.projectRoadRelativePoint(
      forwardMeters: endFwd,
      lateralMeters: rider.lateralOffsetMeters - halfSpread,
      heightMeters: 0.02,
      viewportSize: size,
    );
    final ProjectedNightPoint3D? farRightPt = renderer.projectRoadRelativePoint(
      forwardMeters: endFwd,
      lateralMeters: rider.lateralOffsetMeters + halfSpread,
      heightMeters: 0.02,
      viewportSize: size,
    );

    if (emitterPt == null ||
        farCenterPt == null ||
        farLeftPt == null ||
        farRightPt == null) {
      return;
    }

    final Color ledColor = renderer.headlightKelvinColor;
    final double intensity = mode.coreIntensity * pulse;

    // 1. Zewnętrzny, szeroki stożek światła rozproszonego na asfalcie
    final Path wideConePath = Path()
      ..moveTo(emitterPt.screenOffset.dx, emitterPt.screenOffset.dy)
      ..lineTo(farLeftPt.screenOffset.dx, farLeftPt.screenOffset.dy)
      ..quadraticBezierTo(
        farCenterPt.screenOffset.dx,
        farCenterPt.screenOffset.dy + 14.0,
        farRightPt.screenOffset.dx,
        farRightPt.screenOffset.dy,
      )
      ..close();

    final Rect coneBounds = wideConePath.getBounds();
    if (!coneBounds.isEmpty) {
      final Paint wideConePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            ledColor.withValues(alpha: 0.34 * intensity),
            ledColor.withValues(alpha: 0.14 * intensity),
            ledColor.withValues(alpha: 0.0),
          ],
          stops: const <double>[0.0, 0.52, 1.0],
        ).createShader(coneBounds)
        ..blendMode = BlendMode.screen;
      canvas.drawPath(wideConePath, wideConePaint);
    }

    // 2. Wewnętrzny rdzeń wiązki LED (High-Intensity Core)
    final Offset innerLeft = Offset.lerp(
      farCenterPt.screenOffset,
      farLeftPt.screenOffset,
      0.38,
    )!;
    final Offset innerRight = Offset.lerp(
      farCenterPt.screenOffset,
      farRightPt.screenOffset,
      0.38,
    )!;
    final Path coreConePath = Path()
      ..moveTo(emitterPt.screenOffset.dx, emitterPt.screenOffset.dy)
      ..lineTo(innerLeft.dx, innerLeft.dy)
      ..lineTo(innerRight.dx, innerRight.dy)
      ..close();

    final Rect coreBounds = coreConePath.getBounds();
    if (!coreBounds.isEmpty) {
      final Paint corePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.56 * intensity),
            ledColor.withValues(alpha: 0.24 * intensity),
            Colors.transparent,
          ],
        ).createShader(coreBounds)
        ..blendMode = BlendMode.plus;
      canvas.drawPath(coreConePath, corePaint);
    }

    // 3. Wolumetryczne halo we mgle wokół soczewki LED
    if (cfg.fogDensity > 0.08) {
      canvas.drawCircle(
        emitterPt.screenOffset,
        (emitterPt.scaleFactor * 0.45 * (1.0 + cfg.fogDensity)).clamp(4.0, 34.0),
        Paint()
          ..color = ledColor.withValues(
            alpha: (0.28 * intensity * cfg.fogDensity).clamp(0.0, 0.45),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0),
      );
    }
  }

  void _paintRiderBodyAndTaillight(
    Canvas canvas,
    Size size,
    NightRiderLightEmitter3D rider,
    double fwd,
  ) {
    final ProjectedNightPoint3D? groundPt = renderer.projectRoadRelativePoint(
      forwardMeters: fwd,
      lateralMeters: rider.lateralOffsetMeters,
      heightMeters: 0.0,
      viewportSize: size,
    );
    final ProjectedNightPoint3D? saddlePt = renderer.projectRoadRelativePoint(
      forwardMeters: fwd - 0.22,
      lateralMeters: rider.lateralOffsetMeters,
      heightMeters: 0.88,
      viewportSize: size,
    );
    final ProjectedNightPoint3D? helmetPt = renderer.projectRoadRelativePoint(
      forwardMeters: fwd + 0.18,
      lateralMeters: rider.lateralOffsetMeters,
      heightMeters: 1.48,
      viewportSize: size,
    );

    if (groundPt == null || saddlePt == null || helmetPt == null) return;

    final double s = groundPt.scaleFactor;
    final double bodyWidth = (s * 0.42).clamp(3.0, 42.0);
    final double wheelRadius = (s * 0.34).clamp(2.0, 34.0);

    // Cień pod rowerem
    canvas.drawOval(
      Rect.fromCenter(
        center: groundPt.screenOffset,
        width: bodyWidth * 1.4,
        height: bodyWidth * 0.42,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    // Tylne koło i rama (ciemna sylwetka nocna)
    canvas.drawCircle(
      groundPt.screenOffset - Offset(0, wheelRadius * 0.5),
      wheelRadius * 0.55,
      Paint()
        ..color = const Color(0xFF151922)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (s * 0.05).clamp(1.2, 4.0),
    );

    // Tułów w koszulce z lekkim podświetleniem
    final Path torsoPath = Path()
      ..moveTo(
        saddlePt.screenOffset.dx - bodyWidth * 0.42,
        saddlePt.screenOffset.dy,
      )
      ..lineTo(
        saddlePt.screenOffset.dx + bodyWidth * 0.42,
        saddlePt.screenOffset.dy,
      )
      ..lineTo(
        helmetPt.screenOffset.dx + bodyWidth * 0.35,
        helmetPt.screenOffset.dy + bodyWidth * 0.25,
      )
      ..lineTo(
        helmetPt.screenOffset.dx - bodyWidth * 0.35,
        helmetPt.screenOffset.dy + bodyWidth * 0.25,
      )
      ..close();
    canvas.drawPath(
      torsoPath,
      Paint()
        ..color = Color.lerp(
          const Color(0xFF11141C),
          rider.jerseyColor,
          0.36,
        )!,
    );

    // Kask kolarza
    canvas.drawCircle(
      helmetPt.screenOffset,
      (bodyWidth * 0.34).clamp(2.0, 14.0),
      Paint()..color = const Color(0xFF1E2430),
    );

    // Czerwone światło tylne pod siodełkiem + odbicie na asfalcie
    final TaillightPulseMode tailMode =
        rider.isPlayer ? renderer.config.taillightMode : rider.taillightMode;
    if (tailMode != TaillightPulseMode.off) {
      final double tailPulse = renderer.computeTaillightPulseFactor(
        tailMode,
        rider.distanceMeters * 0.13,
      );
      if (tailPulse > 0.02) {
        final double ledRadius = (s * 0.065).clamp(2.2, 7.5);
        final Offset tailPos = saddlePt.screenOffset + Offset(0, ledRadius * 0.7);

        // Odbicie czerwonego światła na ciemnym asfalcie za rowerem
        canvas.drawOval(
          Rect.fromCenter(
            center: groundPt.screenOffset + Offset(0, wheelRadius * 0.45),
            width: bodyWidth * (1.2 + tailPulse * 0.7),
            height: bodyWidth * 0.65,
          ),
          Paint()
            ..color = AppColors.crimsonAlert.withValues(alpha: 0.28 * tailPulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
        );

        // Poświata (halo) czerwonego światła tylnego
        canvas.drawCircle(
          tailPos,
          ledRadius * (2.6 + tailPulse * 1.4),
          Paint()
            ..color = const Color(0xFFFF1744).withValues(alpha: 0.48 * tailPulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
        );

        // Jasny rdzeń diody tylnej
        canvas.drawCircle(
          tailPos,
          ledRadius,
          Paint()
            ..color = Color.lerp(
              AppColors.crimsonAlert,
              const Color(0xFFFFD6D6),
              tailPulse * 0.55,
            )!,
        );
      }
    }
  }

  void _paintAtmosphericFogVeil(
    Canvas canvas,
    Size size,
    double horizonY,
    NightRiding3dConfig cfg,
    NightRidingBiomePreset biome,
  ) {
    if (cfg.fogDensity <= 0.04) return;
    final double alpha = (cfg.fogDensity * 0.42).clamp(0.0, 0.36);
    final Rect fogRect = Rect.fromLTWH(0, horizonY - 40, size.width, 96);
    canvas.drawRect(
      fogRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            biome.horizonGlowColor.withValues(alpha: alpha),
            Colors.transparent,
          ],
        ).createShader(fogRect),
    );
  }

  @override
  bool shouldRepaint(covariant NightRidingHeadlightAndStars3dPainter oldDelegate) {
    return oldDelegate.animationTick != animationTick ||
        oldDelegate.renderer != renderer;
  }
}

// =============================================================================
// 5. RESPONSYWNY WIDGET VIEWPORTU 3D Z PEŁNYMI STANAMI INTERAKCJI
// =============================================================================

/// Produkcyjny viewport 3D jazdy nocnej z panelem sterowania lampkami,
/// kamerą, biomem, gwiazdami i telemetrią na żywo.
class NightRidingHeadlightAndStars3dViewportWidget extends StatefulWidget {
  final NightRidingHeadlightAndStars3dRenderer? renderer;
  final bool autoAnimate;
  final ValueChanged<NightRiding3dConfig>? onConfigChanged;

  const NightRidingHeadlightAndStars3dViewportWidget({
    super.key,
    this.renderer,
    this.autoAnimate = true,
    this.onConfigChanged,
  });

  @override
  State<NightRidingHeadlightAndStars3dViewportWidget> createState() =>
      _NightRidingHeadlightAndStars3dViewportWidgetState();
}

class _NightRidingHeadlightAndStars3dViewportWidgetState
    extends State<NightRidingHeadlightAndStars3dViewportWidget>
    with SingleTickerProviderStateMixin {
  late final NightRidingHeadlightAndStars3dRenderer _renderer;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double _animTick = 0.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _renderer = widget.renderer ?? NightRidingHeadlightAndStars3dRenderer();
    if (widget.autoAnimate) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _isPaused) {
      _lastElapsed = elapsed;
      return;
    }
    final double dt =
        (elapsed - _lastElapsed).inMicroseconds / Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    if (dt > 0.0 && dt < 0.5) {
      _renderer.advanceFrame(dt);
      setState(() {
        _animTick += dt;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _applyConfig(NightRiding3dConfig next) {
    setState(() {
      _renderer.updateConfig(next);
      _animTick += 0.001;
    });
    widget.onConfigChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final NightRiding3dConfig cfg = _renderer.config;
    final NightRidingFrameTelemetry telemetry = _renderer.latestTelemetry;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1024.0;
        final bool isMobile = width < 640.0;
        final bool isTablet = width >= 640.0 && width < 1160.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeaderBar(cfg, telemetry, isMobile),
              AspectRatio(
                aspectRatio: isMobile ? 16 / 10 : (isTablet ? 16 / 9 : 21 / 9),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CustomPaint(
                      painter: NightRidingHeadlightAndStars3dPainter(
                        renderer: _renderer,
                        animationTick: _animTick,
                      ),
                    ),
                    if (cfg.showTelemetryHud)
                      Positioned(
                        left: isMobile ? 10 : 16,
                        right: isMobile ? 10 : 16,
                        bottom: isMobile ? 10 : 14,
                        child: _buildTelemetryOverlay(telemetry, isMobile),
                      ),
                  ],
                ),
              ),
              _buildControlDeck(cfg, telemetry, isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar(
    NightRiding3dConfig cfg,
    NightRidingFrameTelemetry telemetry,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: telemetry.activeHeadlightLumens > 0
                      ? AppColors.accentBlue
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Jazda Nocna 3D • LED & Gwiazdy',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _NightInteractiveChipButton(
                label: _isPaused ? 'Wznów' : 'Pauza',
                icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                isActive: _isPaused,
                accentColor: AppColors.goldAccent,
                onPressed: () {
                  setState(() {
                    _isPaused = !_isPaused;
                  });
                },
              ),
              const SizedBox(width: 8),
              _NightInteractiveChipButton(
                label: cfg.showStars ? 'Gwiazdy ON' : 'Gwiazdy OFF',
                icon: Icons.auto_awesome_rounded,
                isActive: cfg.showStars,
                accentColor: AppColors.accentBlue,
                onPressed: () {
                  _applyConfig(cfg.copyWith(showStars: !cfg.showStars));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryOverlay(
    NightRidingFrameTelemetry t,
    bool isMobile,
  ) {
    final List<Widget> pills = <Widget>[
      _TelemetryBadge(
        label: 'STRUMIEŃ LED',
        value: '${t.activeHeadlightLumens} lm',
        accent: AppColors.accentBlue,
      ),
      _TelemetryBadge(
        label: 'ZASIĘG STOŻKA',
        value: '${t.effectiveBeamRangeMeters.toStringAsFixed(0)} m',
        accent: AppColors.cyanAccent,
      ),
      _TelemetryBadge(
        label: 'GWIAZDY',
        value: '${t.visibleStarsCount}',
        accent: AppColors.goldAccent,
      ),
      _TelemetryBadge(
        label: 'BATERIA',
        value: '${t.batteryRemainingPercent.toStringAsFixed(0)}%',
        accent: t.batteryRemainingPercent > 20.0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
      ),
      if (!isMobile)
        _TelemetryBadge(
          label: 'DYNAMO',
          value: '+${t.dynamoOutputWatts.toStringAsFixed(1)} W',
          accent: AppColors.statusSuccess,
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Wrap(
        spacing: isMobile ? 10 : 18,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: pills,
      ),
    );
  }

  Widget _buildControlDeck(
    NightRiding3dConfig cfg,
    NightRidingFrameTelemetry telemetry,
    bool isMobile,
    bool isTablet,
  ) {
    final bool batteryDepleted = telemetry.batteryRemainingPercent <= 0.05;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionRow(
            title: 'Przednia Lampka LED (Stożek)',
            children: HeadlightBeamMode.values.map((HeadlightBeamMode mode) {
              return _NightInteractiveChipButton(
                label: mode.shortTag,
                isActive: cfg.headlightMode == mode,
                isDisabled: batteryDepleted && mode != HeadlightBeamMode.off,
                accentColor: AppColors.accentBlue,
                onPressed: () {
                  _applyConfig(cfg.copyWith(headlightMode: mode));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          _buildSectionRow(
            title: 'Światło Tylne Czerwone',
            children: TaillightPulseMode.values.map((TaillightPulseMode mode) {
              return _NightInteractiveChipButton(
                label: mode.shortTag,
                isActive: cfg.taillightMode == mode,
                accentColor: AppColors.crimsonAlert,
                onPressed: () {
                  _applyConfig(cfg.copyWith(taillightMode: mode));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: <Widget>[
              _buildSectionRow(
                title: 'Biom Nocny',
                children: NightRidingBiomePreset.values
                    .map((NightRidingBiomePreset preset) {
                  return _NightInteractiveChipButton(
                    label: preset.shortTag,
                    isActive: cfg.biomePreset == preset,
                    accentColor: AppColors.goldAccent,
                    onPressed: () {
                      _applyConfig(
                        cfg.copyWith(
                          biomePreset: preset,
                          fogDensity: preset.defaultFogDensity,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              _buildSectionRow(
                title: 'Kamera 3D',
                children: NightCameraViewMode.values
                    .map((NightCameraViewMode cam) {
                  return _NightInteractiveChipButton(
                    label: cam.shortTag,
                    isActive: cfg.cameraMode == cam,
                    accentColor: AppColors.primaryAccent,
                    onPressed: () {
                      _applyConfig(cfg.copyWith(cameraMode: cam));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRow({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: children,
        ),
      ],
    );
  }
}

/// Telemetria pojedynczego parametru w nakładce HUD.
class _TelemetryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryBadge({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: accent,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Przycisk interaktywny z pełnymi stanami hover / active / disabled / focus.
class _NightInteractiveChipButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _NightInteractiveChipButton({
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onPressed,
    this.icon,
    this.isDisabled = false,
  });

  @override
  State<_NightInteractiveChipButton> createState() =>
      _NightInteractiveChipButtonState();
}

class _NightInteractiveChipButtonState
    extends State<_NightInteractiveChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled;
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (!enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.4);
      borderColor = const Color(0xFF2A2F3D).withValues(alpha: 0.5);
      textColor = AppColors.textSecondary.withValues(alpha: 0.45);
    } else if (widget.isActive) {
      bgColor = widget.accentColor.withValues(alpha: _isHovered ? 0.28 : 0.20);
      borderColor = widget.accentColor;
      textColor = AppColors.textPrimary;
    } else if (_isPressed) {
      bgColor = AppColors.surfaceLight;
      borderColor = widget.accentColor.withValues(alpha: 0.75);
      textColor = AppColors.textPrimary;
    } else if (_isHovered || _isFocused) {
      bgColor = AppColors.surfaceLight;
      borderColor = _isFocused
          ? AppColors.goldAccent
          : const Color(0xFF3B4254);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = AppColors.background;
      borderColor = const Color(0xFF2A2F3D);
      textColor = AppColors.textSecondary;
    }

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool hovered) {
        if (_isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      onShowFocusHighlight: (bool focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, size: 14, color: textColor),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                    color: textColor,
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
