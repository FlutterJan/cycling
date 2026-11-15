// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import 'camera_rig_controller.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. KLASYFIKACJA SEKTORÓW BRUKU (1–5 GWIAZDEK) I KONFIGURACJA FX
// =============================================================================

/// Poziom trudności sektora bruku (1–5 gwiazdek) w klasykach typu Paris-Roubaix.
enum CobblestoneSectorDifficulty {
  oneStar(
    stars: 1,
    labelPl: '1★ Łatwy bruk',
    exampleSector: 'Troisvilles (łatwy odcinek)',
    baseFrequencyHz: 18.0,
    verticalAmplitudeMm: 2.2,
    lateralAmplitudeMm: 1.0,
    rollAmplitudeDeg: 0.45,
    dustIntensity: 0.25,
    stringOutFactor: 0.28,
    crownWidthMeters: 1.65,
  ),
  twoStars(
    stars: 2,
    labelPl: '2★ Średni bruk',
    exampleSector: 'Quiévy à Saint-Python',
    baseFrequencyHz: 23.0,
    verticalAmplitudeMm: 3.8,
    lateralAmplitudeMm: 1.8,
    rollAmplitudeDeg: 0.85,
    dustIntensity: 0.45,
    stringOutFactor: 0.48,
    crownWidthMeters: 1.40,
  ),
  threeStars(
    stars: 3,
    labelPl: '3★ Trudny bruk',
    exampleSector: 'Hornaing à Wandignies',
    baseFrequencyHz: 29.0,
    verticalAmplitudeMm: 6.2,
    lateralAmplitudeMm: 3.1,
    rollAmplitudeDeg: 1.45,
    dustIntensity: 0.65,
    stringOutFactor: 0.70,
    crownWidthMeters: 1.15,
  ),
  fourStars(
    stars: 4,
    labelPl: '4★ Bardzo trudny bruk',
    exampleSector: 'Mons-en-Pévèle',
    baseFrequencyHz: 35.0,
    verticalAmplitudeMm: 9.4,
    lateralAmplitudeMm: 4.8,
    rollAmplitudeDeg: 2.20,
    dustIntensity: 0.85,
    stringOutFactor: 0.88,
    crownWidthMeters: 0.95,
  ),
  fiveStars(
    stars: 5,
    labelPl: '5★ Piekielny bruk',
    exampleSector: "Trouée d'Arenberg / Carrefour de l'Arbre",
    baseFrequencyHz: 42.0,
    verticalAmplitudeMm: 13.5,
    lateralAmplitudeMm: 7.2,
    rollAmplitudeDeg: 3.25,
    dustIntensity: 1.00,
    stringOutFactor: 1.00,
    crownWidthMeters: 0.80,
  );

  final int stars;
  final String labelPl;
  final String exampleSector;
  final double baseFrequencyHz;
  final double verticalAmplitudeMm;
  final double lateralAmplitudeMm;
  final double rollAmplitudeDeg;
  final double dustIntensity;
  final double stringOutFactor;
  final double crownWidthMeters;

  const CobblestoneSectorDifficulty({
    required this.stars,
    required this.labelPl,
    required this.exampleSector,
    required this.baseFrequencyHz,
    required this.verticalAmplitudeMm,
    required this.lateralAmplitudeMm,
    required this.rollAmplitudeDeg,
    required this.dustIntensity,
    required this.stringOutFactor,
    required this.crownWidthMeters,
  });

  /// Mapuje typ nawierzchni etapu na trudność bruku (null dla asfaltu/szutru/betonu).
  static CobblestoneSectorDifficulty? fromSurfaceType(
    SegmentSurfaceType surfaceType,
  ) {
    switch (surfaceType) {
      case SegmentSurfaceType.cobblestonesSector1:
        return CobblestoneSectorDifficulty.oneStar;
      case SegmentSurfaceType.cobblestonesSector2:
        return CobblestoneSectorDifficulty.twoStars;
      case SegmentSurfaceType.cobblestonesSector3:
        return CobblestoneSectorDifficulty.threeStars;
      case SegmentSurfaceType.cobblestonesSector4:
        return CobblestoneSectorDifficulty.fourStars;
      case SegmentSurfaceType.cobblestonesSector5:
        return CobblestoneSectorDifficulty.fiveStars;
      case SegmentSurfaceType.smoothAsphalt:
      case SegmentSurfaceType.roughAsphalt:
      case SegmentSurfaceType.gravelStrade:
      case SegmentSurfaceType.concrete:
        return null;
    }
  }

  /// Zwraca poziom trudności dla liczby gwiazdek [1..5] (wartości poza zakresem są klamrowane).
  static CobblestoneSectorDifficulty fromStars(int stars) {
    final int clamped = stars.clamp(1, 5);
    return CobblestoneSectorDifficulty.values[clamped - 1];
  }
}

/// Konfiguracja efektu drgań kamery, kierownicy, kurzu i szyku gęsiego na bruku.
class CobblestoneVibrationConfig {
  final bool enabled;
  final double vibrationIntensityScale;
  final double handlebarChatterScale;
  final double cameraShakeScale;
  final bool enableDustPlume;
  final int maxDustParticles;
  final bool enablePelotonStringOut;
  final double crownCenterOffsetMeters;
  final double tirePressureBar;
  final bool isWetCobbles;

  const CobblestoneVibrationConfig({
    this.enabled = true,
    this.vibrationIntensityScale = 1.0,
    this.handlebarChatterScale = 1.0,
    this.cameraShakeScale = 1.0,
    this.enableDustPlume = true,
    this.maxDustParticles = 180,
    this.enablePelotonStringOut = true,
    this.crownCenterOffsetMeters = 0.0,
    this.tirePressureBar = 3.8,
    this.isWetCobbles = false,
  });

  CobblestoneVibrationConfig copyWith({
    bool? enabled,
    double? vibrationIntensityScale,
    double? handlebarChatterScale,
    double? cameraShakeScale,
    bool? enableDustPlume,
    int? maxDustParticles,
    bool? enablePelotonStringOut,
    double? crownCenterOffsetMeters,
    double? tirePressureBar,
    bool? isWetCobbles,
  }) {
    return CobblestoneVibrationConfig(
      enabled: enabled ?? this.enabled,
      vibrationIntensityScale:
          vibrationIntensityScale ?? this.vibrationIntensityScale,
      handlebarChatterScale:
          handlebarChatterScale ?? this.handlebarChatterScale,
      cameraShakeScale: cameraShakeScale ?? this.cameraShakeScale,
      enableDustPlume: enableDustPlume ?? this.enableDustPlume,
      maxDustParticles: maxDustParticles ?? this.maxDustParticles,
      enablePelotonStringOut:
          enablePelotonStringOut ?? this.enablePelotonStringOut,
      crownCenterOffsetMeters:
          crownCenterOffsetMeters ?? this.crownCenterOffsetMeters,
      tirePressureBar: tirePressureBar ?? this.tirePressureBar,
      isWetCobbles: isWetCobbles ?? this.isWetCobbles,
    );
  }
}

// =============================================================================
// 2. MODELE WEJŚCIOWE I WYJŚCIOWE KLATKI FX
// =============================================================================

/// Dane pojedynczego kolarza potrzebne do wyliczenia kurzu i rozciągania grupy na bruku.
class CobblestoneRiderInput {
  final String riderId;
  final double progressMeters;
  final double lateralOffsetMeters;
  final double speedKmh;
  final double cobbleSkill; // 0.0 - 100.0
  final bool isAttacking;
  final Vector3 worldPosition;

  const CobblestoneRiderInput({
    required this.riderId,
    required this.progressMeters,
    required this.lateralOffsetMeters,
    required this.speedKmh,
    this.cobbleSkill = 70.0,
    this.isAttacking = false,
    required this.worldPosition,
  });
}

/// Mikro-wstrząsy kamery 3D oraz offset 2D ekranu w danej klatce.
class CobblestoneCameraImpulse {
  final Vector3 cameraPositionOffset;
  final Vector3 cameraLookAtOffset;
  final double rollJitterRadians;
  final double fovPulseDegrees;
  final Offset screenShakeOffsetPx;

  const CobblestoneCameraImpulse({
    required this.cameraPositionOffset,
    required this.cameraLookAtOffset,
    required this.rollJitterRadians,
    required this.fovPulseDegrees,
    required this.screenShakeOffsetPx,
  });

  static final CobblestoneCameraImpulse zero = CobblestoneCameraImpulse(
    cameraPositionOffset: Vector3.zero(),
    cameraLookAtOffset: Vector3.zero(),
    rollJitterRadians: 0.0,
    fovPulseDegrees: 0.0,
    screenShakeOffsetPx: Offset.zero,
  );
}

/// Mikro-wstrząsy o wysokiej częstotliwości przekazywane na kierownicę i widelec.
class HandlebarMicroVibration {
  final double verticalOffsetMm;
  final double horizontalOffsetMm;
  final double rollAngleRadians;
  final double pitchAngleRadians;
  final double dominantFrequencyHz;
  final double forkChatterIntensity; // 0.0 - 1.0

  const HandlebarMicroVibration({
    required this.verticalOffsetMm,
    required this.horizontalOffsetMm,
    required this.rollAngleRadians,
    required this.pitchAngleRadians,
    required this.dominantFrequencyHz,
    required this.forkChatterIntensity,
  });

  static const HandlebarMicroVibration zero = HandlebarMicroVibration(
    verticalOffsetMm: 0.0,
    horizontalOffsetMm: 0.0,
    rollAngleRadians: 0.0,
    pitchAngleRadians: 0.0,
    dominantFrequencyHz: 0.0,
    forkChatterIntensity: 0.0,
  );
}

/// Pojedyncza cząsteczka kurzu unoszącego się nad peletonem na bruku.
class CobblestoneDustParticle {
  Vector3 position;
  Vector3 velocity;
  double radiusMeters;
  double opacity;
  double ageSeconds;
  final double lifetimeSeconds;
  final Color color;

  CobblestoneDustParticle({
    required this.position,
    required this.velocity,
    required this.radiusMeters,
    required this.opacity,
    required this.ageSeconds,
    required this.lifetimeSeconds,
    required this.color,
  });

  bool get isExpired => ageSeconds >= lifetimeSeconds;
}

/// Wyliczone przesunięcie kolarza podczas rozciągania grupy w pojedynczy wężyk na koronie bruku.
class PelotonStringOutDisplacement {
  final String riderId;
  final double targetLateralOffsetMeters;
  final double longitudinalStretchMeters;
  final int fileOrderIndex;
  final bool isOnCobbleCrown;

  const PelotonStringOutDisplacement({
    required this.riderId,
    required this.targetLateralOffsetMeters,
    required this.longitudinalStretchMeters,
    required this.fileOrderIndex,
    required this.isOnCobbleCrown,
  });
}

/// Kompletny stan efektu bruku w pojedynczej klatce symulacji/renderowania.
class CobblestoneFxFrameState {
  final bool isActive;
  final CobblestoneSectorDifficulty? difficulty;
  final CobblestoneCameraImpulse cameraImpulse;
  final HandlebarMicroVibration handlebarVibration;
  final List<CobblestoneDustParticle> dustParticles;
  final Map<String, PelotonStringOutDisplacement> stringOutDisplacements;
  final double pelotonFileLengthMeters;
  final double averageCrownAlignment; // 0.0 - 1.0
  final int activeDustCount;

  const CobblestoneFxFrameState({
    required this.isActive,
    required this.difficulty,
    required this.cameraImpulse,
    required this.handlebarVibration,
    required this.dustParticles,
    required this.stringOutDisplacements,
    required this.pelotonFileLengthMeters,
    required this.averageCrownAlignment,
    required this.activeDustCount,
  });

  static final CobblestoneFxFrameState inactive = CobblestoneFxFrameState(
    isActive: false,
    difficulty: null,
    cameraImpulse: CobblestoneCameraImpulse.zero,
    handlebarVibration: HandlebarMicroVibration.zero,
    dustParticles: const <CobblestoneDustParticle>[],
    stringOutDisplacements: const <String, PelotonStringOutDisplacement>{},
    pelotonFileLengthMeters: 0.0,
    averageCrownAlignment: 0.0,
    activeDustCount: 0,
  );
}

// =============================================================================
// 3. GŁÓWNY SILNIK EFEKTU BRUKU: CobblestoneVibrationCameraFx
// =============================================================================

/// Silnik efektów kamery, mikro-drgań kierownicy, kurzu i szyku gęsiego na sektorach bruku (1★–5★).
class CobblestoneVibrationCameraFx {
  CobblestoneVibrationConfig _config;
  final math.Random _rng;
  final List<CobblestoneDustParticle> _dustPool = <CobblestoneDustParticle>[];

  double _elapsedSeconds = 0.0;
  double _smoothFadeFactor = 0.0;
  double _dustSpawnAccumulator = 0.0;

  static const List<Color> _dryDustPalette = <Color>[
    Color(0xFFD6C7B2),
    Color(0xFFC4B299),
    Color(0xFFB5A186),
    Color(0xFFE0D4C3),
  ];

  CobblestoneVibrationCameraFx({
    CobblestoneVibrationConfig config = const CobblestoneVibrationConfig(),
    int randomSeed = 1896,
  })  : _config = config,
        _rng = math.Random(randomSeed);

  CobblestoneVibrationConfig get config => _config;
  double get smoothFadeFactor => _smoothFadeFactor;
  List<CobblestoneDustParticle> get dustParticles =>
      List<CobblestoneDustParticle>.unmodifiable(_dustPool);

  void updateConfig(CobblestoneVibrationConfig newConfig) {
    _config = newConfig;
  }

  /// Resetuje pulę cząsteczek kurzu i wygasza drgania (np. po opuszczeniu etapu).
  void reset() {
    _dustPool.clear();
    _elapsedSeconds = 0.0;
    _smoothFadeFactor = 0.0;
    _dustSpawnAccumulator = 0.0;
  }

  /// Aktualizuje stan efektu bruku dla bieżącej klatki.
  CobblestoneFxFrameState step({
    required double dtSeconds,
    required SegmentSurfaceType surfaceType,
    required double focalRiderSpeedKmh,
    required RaceCameraMode cameraMode,
    bool isFirstPersonCockpit = false,
    List<CobblestoneRiderInput> riders = const <CobblestoneRiderInput>[],
    double windLateralMps = 1.2,
    double windHeadTailMps = 0.0,
  }) {
    final double dt = dtSeconds.clamp(0.0, 0.1);
    _elapsedSeconds += dt;

    final CobblestoneSectorDifficulty? difficulty = _config.enabled
        ? CobblestoneSectorDifficulty.fromSurfaceType(surfaceType)
        : null;

    // Płynne wchodzenie i wychodzenie z sektora bruku (ok. 280 ms)
    final double targetFade = difficulty != null ? 1.0 : 0.0;
    final double fadeStep = dt * 4.2;
    if (_smoothFadeFactor < targetFade) {
      _smoothFadeFactor = math.min(1.0, _smoothFadeFactor + fadeStep);
    } else if (_smoothFadeFactor > targetFade) {
      _smoothFadeFactor = math.max(0.0, _smoothFadeFactor - fadeStep);
    }

    // Aktualizuj istniejący kurz nawet po zjeździe z bruku aż opadnie
    _updateDustParticles(
      dt: dt,
      windLateralMps: windLateralMps,
      windHeadTailMps: windHeadTailMps,
    );

    if (difficulty == null && _smoothFadeFactor <= 0.001) {
      return CobblestoneFxFrameState(
        isActive: false,
        difficulty: null,
        cameraImpulse: CobblestoneCameraImpulse.zero,
        handlebarVibration: HandlebarMicroVibration.zero,
        dustParticles: List<CobblestoneDustParticle>.unmodifiable(_dustPool),
        stringOutDisplacements: const <String, PelotonStringOutDisplacement>{},
        pelotonFileLengthMeters: 0.0,
        averageCrownAlignment: 0.0,
        activeDustCount: _dustPool.length,
      );
    }

    final CobblestoneSectorDifficulty activeDiff =
        difficulty ?? CobblestoneSectorDifficulty.oneStar;
    final double safeSpeedKmh = focalRiderSpeedKmh.clamp(0.0, 75.0);
    final double speedNorm = (safeSpeedKmh / 42.0).clamp(0.15, 1.55);

    // Wyższe ciśnienie w oponach (> 4.5 bar) wzmacnia podskoki na bruku; niskie (~3.2 bar) tłumi
    final double pressureFactor =
        (0.78 + (_config.tirePressureBar.clamp(2.5, 6.5) - 2.5) * 0.11)
            .clamp(0.75, 1.25);

    final double masterIntensity =
        _smoothFadeFactor *
        _config.vibrationIntensityScale.clamp(0.0, 2.0) *
        pressureFactor;

    final HandlebarMicroVibration handlebar = _computeHandlebarVibration(
      difficulty: activeDiff,
      speedNorm: speedNorm,
      masterIntensity: masterIntensity,
    );

    final CobblestoneCameraImpulse cameraImpulse = _computeCameraImpulse(
      difficulty: activeDiff,
      handlebar: handlebar,
      cameraMode: cameraMode,
      isFirstPersonCockpit: isFirstPersonCockpit,
      masterIntensity: masterIntensity,
    );

    if (_config.enableDustPlume && difficulty != null && !_config.isWetCobbles) {
      _emitDustParticles(
        dt: dt,
        difficulty: activeDiff,
        riders: riders,
      );
    }

    final _StringOutComputation stringOut = _computePelotonStringOut(
      difficulty: activeDiff,
      riders: riders,
      speedNorm: speedNorm,
    );

    return CobblestoneFxFrameState(
      isActive: difficulty != null || _smoothFadeFactor > 0.001,
      difficulty: difficulty,
      cameraImpulse: cameraImpulse,
      handlebarVibration: handlebar,
      dustParticles: List<CobblestoneDustParticle>.unmodifiable(_dustPool),
      stringOutDisplacements: stringOut.displacements,
      pelotonFileLengthMeters: stringOut.fileLengthMeters,
      averageCrownAlignment: stringOut.averageCrownAlignment,
      activeDustCount: _dustPool.length,
    );
  }

  HandlebarMicroVibration _computeHandlebarVibration({
    required CobblestoneSectorDifficulty difficulty,
    required double speedNorm,
    required double masterIntensity,
  }) {
    final double freqHz =
        (difficulty.baseFrequencyHz * (0.65 + 0.45 * speedNorm))
            .clamp(12.0, 52.0);
    final double omega = 2.0 * math.pi * freqHz;
    final double t = _elapsedSeconds;

    // Wieloharmoniczny sygnał kostki brukowej + nieregularne uderzenia krawędzi kamieni
    final double h1 = math.sin(omega * t);
    final double h2 = 0.55 * math.sin(omega * 1.93 * t + 0.85);
    final double h3 = 0.30 * math.cos(omega * 3.11 * t + 2.10);
    final double stoneGapImpact =
        math.pow((math.sin(omega * 0.47 * t + 1.3)).abs(), 4.0).toDouble() *
            (math.sin(omega * 2.4 * t) >= 0 ? 1.0 : -1.0);

    final double compositeVertical = (h1 + h2 + h3 + 0.65 * stoneGapImpact) / 2.2;
    final double compositeLateral =
        (math.cos(omega * 0.87 * t + 0.4) +
            0.5 * math.sin(omega * 1.71 * t + 1.9)) /
        1.5;

    final double barScale = _config.handlebarChatterScale.clamp(0.0, 2.0);
    final double verticalMm =
        compositeVertical * difficulty.verticalAmplitudeMm * masterIntensity * barScale;
    final double horizontalMm =
        compositeLateral * difficulty.lateralAmplitudeMm * masterIntensity * barScale;

    final double rollRad =
        (compositeLateral * difficulty.rollAmplitudeDeg * math.pi / 180.0) *
            masterIntensity *
            barScale;
    final double pitchRad =
        (compositeVertical *
                (difficulty.rollAmplitudeDeg * 0.65) *
                math.pi /
                180.0) *
            masterIntensity *
            barScale;

    final double chatterIntensity =
        ((difficulty.stars / 5.0) * speedNorm * masterIntensity * barScale)
            .clamp(0.0, 1.0);

    return HandlebarMicroVibration(
      verticalOffsetMm: verticalMm,
      horizontalOffsetMm: horizontalMm,
      rollAngleRadians: rollRad,
      pitchAngleRadians: pitchRad,
      dominantFrequencyHz: freqHz,
      forkChatterIntensity: chatterIntensity,
    );
  }

  CobblestoneCameraImpulse _computeCameraImpulse({
    required CobblestoneSectorDifficulty difficulty,
    required HandlebarMicroVibration handlebar,
    required RaceCameraMode cameraMode,
    required bool isFirstPersonCockpit,
    required double masterIntensity,
  }) {
    // Tłumienie zależne od typu kamery
    final double modeFactor;
    if (isFirstPersonCockpit) {
      modeFactor = 1.00; // Bezpośrednie drgania na kokpicie FPP
    } else {
      switch (cameraMode) {
        case RaceCameraMode.chaseCam:
          modeFactor = 0.62;
          break;
        case RaceCameraMode.motoTvCam:
          modeFactor = 0.44;
          break;
        case RaceCameraMode.heliCam:
          modeFactor = 0.08;
          break;
        case RaceCameraMode.finishLineCam:
          modeFactor = 0.14;
          break;
      }
    }

    final double camScale =
        modeFactor * _config.cameraShakeScale.clamp(0.0, 2.0);

    // Przeliczenie mm z widelca na metry w przestrzeni świata 3D (z lekkim wzmocnieniem percepcyjnym)
    final double posY = (handlebar.verticalOffsetMm / 1000.0) * 2.4 * camScale;
    final double posX = (handlebar.horizontalOffsetMm / 1000.0) * 2.1 * camScale;
    final double posZ =
        (math.sin(_elapsedSeconds * 31.0) * 0.004 * difficulty.stars) *
            masterIntensity *
            camScale;

    final Vector3 posOffset = Vector3(posX, posY, posZ);
    final Vector3 lookAtOffset = Vector3(
      posX * 1.85,
      posY * 2.25,
      0.0,
    );

    final double rollJitter = handlebar.rollAngleRadians * 0.55 * camScale;
    final double fovPulse =
        (0.18 * difficulty.stars * handlebar.forkChatterIntensity * camScale)
            .clamp(0.0, 1.6);

    final double screenX =
        handlebar.horizontalOffsetMm * 0.85 * camScale;
    final double screenY =
        handlebar.verticalOffsetMm * 0.95 * camScale;

    return CobblestoneCameraImpulse(
      cameraPositionOffset: posOffset,
      cameraLookAtOffset: lookAtOffset,
      rollJitterRadians: rollJitter,
      fovPulseDegrees: fovPulse,
      screenShakeOffsetPx: Offset(screenX, screenY),
    );
  }

  void _emitDustParticles({
    required double dt,
    required CobblestoneSectorDifficulty difficulty,
    required List<CobblestoneRiderInput> riders,
  }) {
    if (riders.isEmpty || _dustPool.length >= _config.maxDustParticles) {
      return;
    }

    final double spawnRatePerSec =
        (16.0 + difficulty.stars * 18.0) * difficulty.dustIntensity;
    _dustSpawnAccumulator += dt * spawnRatePerSec;

    final int toSpawn = _dustSpawnAccumulator.floor();
    if (toSpawn <= 0) return;
    _dustSpawnAccumulator -= toSpawn;

    final int available = _config.maxDustParticles - _dustPool.length;
    final int count = math.min(toSpawn, available);

    for (int i = 0; i < count; i++) {
      final CobblestoneRiderInput rider = riders[_rng.nextInt(riders.length)];
      if (rider.speedKmh < 8.0) continue;

      final double speedFactor = (rider.speedKmh / 40.0).clamp(0.3, 1.5);
      final double spreadX = (_rng.nextDouble() - 0.5) * 0.65;
      final double spreadZ = -0.35 - _rng.nextDouble() * 0.9;

      final Vector3 spawnPos = Vector3(
        rider.worldPosition.x + spreadX,
        rider.worldPosition.y + 0.08 + _rng.nextDouble() * 0.16,
        rider.worldPosition.z + spreadZ,
      );

      final Vector3 velocity = Vector3(
        (_rng.nextDouble() - 0.5) * 0.8,
        (0.55 + _rng.nextDouble() * 1.15) * difficulty.dustIntensity * speedFactor,
        (_rng.nextDouble() - 0.5) * 0.6,
      );

      final Color baseColor =
          _dryDustPalette[_rng.nextInt(_dryDustPalette.length)];
      final double lifetime = 0.9 + _rng.nextDouble() * 1.3;

      _dustPool.add(
        CobblestoneDustParticle(
          position: spawnPos,
          velocity: velocity,
          radiusMeters: 0.22 + _rng.nextDouble() * 0.35 * difficulty.dustIntensity,
          opacity: (0.28 + 0.34 * difficulty.dustIntensity).clamp(0.15, 0.72),
          ageSeconds: 0.0,
          lifetimeSeconds: lifetime,
          color: baseColor,
        ),
      );
    }
  }

  void _updateDustParticles({
    required double dt,
    required double windLateralMps,
    required double windHeadTailMps,
  }) {
    if (_dustPool.isEmpty) return;

    for (int i = _dustPool.length - 1; i >= 0; i--) {
      final CobblestoneDustParticle p = _dustPool[i];
      p.ageSeconds += dt;
      if (p.isExpired) {
        _dustPool.removeAt(i);
        continue;
      }

      // Wiatr i turbulencja unoszą chmurę kurzu nad peletonem
      p.velocity.x += (windLateralMps * 0.45 - p.velocity.x * 0.35) * dt;
      p.velocity.z += (windHeadTailMps * 0.35 - p.velocity.z * 0.35) * dt;
      p.velocity.y = math.max(0.08, p.velocity.y - 0.22 * dt);

      p.position.addScaled(p.velocity, dt);
      p.radiusMeters += dt * 0.68;

      final double lifeProgress = (p.ageSeconds / p.lifetimeSeconds).clamp(0.0, 1.0);
      p.opacity = (1.0 - lifeProgress) * 0.52;
    }
  }

  _StringOutComputation _computePelotonStringOut({
    required CobblestoneSectorDifficulty difficulty,
    required List<CobblestoneRiderInput> riders,
    required double speedNorm,
  }) {
    if (!_config.enablePelotonStringOut || riders.isEmpty) {
      return const _StringOutComputation(
        displacements: <String, PelotonStringOutDisplacement>{},
        fileLengthMeters: 0.0,
        averageCrownAlignment: 0.0,
      );
    }

    // Sortujemy od czoła grupy do końca peletonu
    final List<CobblestoneRiderInput> sorted =
        List<CobblestoneRiderInput>.from(riders)
          ..sort((CobblestoneRiderInput a, CobblestoneRiderInput b) =>
              b.progressMeters.compareTo(a.progressMeters));

    final double stringOut =
        (difficulty.stringOutFactor * (0.75 + 0.25 * speedNorm)).clamp(0.0, 1.0);
    final double halfCrown = difficulty.crownWidthMeters * 0.5;
    final double crownCenter = _config.crownCenterOffsetMeters;

    final Map<String, PelotonStringOutDisplacement> result =
        <String, PelotonStringOutDisplacement>{};

    double minStretchProgress = double.infinity;
    double maxStretchProgress = double.negativeInfinity;
    double crownAlignmentSum = 0.0;

    for (int i = 0; i < sorted.length; i++) {
      final CobblestoneRiderInput r = sorted[i];
      // Im wyższa trudność (4★–5★), tym bardziej grupa zjeżdża do pojedynczego wężyka na koronie bruku
      final double snakeWave =
          math.sin(i * 0.85 + _elapsedSeconds * 1.4) * halfCrown * (1.0 - 0.68 * stringOut);
      final double desiredOnCrown = crownCenter + snakeWave;

      // Lepsi brukarze (cobbleSkill) szybciej i pewniej trzymają koronę bruku
      final double skillWeight = (0.45 + 0.55 * (r.cobbleSkill.clamp(0.0, 100.0) / 100.0));
      final double blend = (stringOut * skillWeight).clamp(0.0, 1.0);

      final double targetLateral =
          r.lateralOffsetMeters + (desiredOnCrown - r.lateralOffsetMeters) * blend;

      // Rozciąganie podłużne grupy (efekt akordeonu i jazdy gęsiego)
      final double spacingPerRiderMeters = 0.45 + 1.35 * stringOut;
      final double stretchMeters = i * spacingPerRiderMeters * (r.isAttacking ? 0.65 : 1.0);

      final double distFromCrown = (targetLateral - crownCenter).abs();
      final bool onCrown = distFromCrown <= halfCrown + 0.15;
      final double riderAlign =
          (1.0 - (distFromCrown / math.max(0.5, halfCrown * 2.5))).clamp(0.0, 1.0);
      crownAlignmentSum += riderAlign;

      final double effectiveProgress = r.progressMeters - stretchMeters;
      if (effectiveProgress < minStretchProgress) {
        minStretchProgress = effectiveProgress;
      }
      if (effectiveProgress > maxStretchProgress) {
        maxStretchProgress = effectiveProgress;
      }

      result[r.riderId] = PelotonStringOutDisplacement(
        riderId: r.riderId,
        targetLateralOffsetMeters: targetLateral,
        longitudinalStretchMeters: stretchMeters,
        fileOrderIndex: i,
        isOnCobbleCrown: onCrown,
      );
    }

    final double totalLength = sorted.length <= 1
        ? 0.0
        : math.max(0.0, maxStretchProgress - minStretchProgress);

    return _StringOutComputation(
      displacements: result,
      fileLengthMeters: totalLength,
      averageCrownAlignment:
          (crownAlignmentSum / sorted.length).clamp(0.0, 1.0),
    );
  }
}

class _StringOutComputation {
  final Map<String, PelotonStringOutDisplacement> displacements;
  final double fileLengthMeters;
  final double averageCrownAlignment;

  const _StringOutComputation({
    required this.displacements,
    required this.fileLengthMeters,
    required this.averageCrownAlignment,
  });
}

// =============================================================================
// 4. PAINTER KURZU NAD PELETONEM I MIKRO-DRGAŃ NA EKRANIE 3D
// =============================================================================

/// Painter renderujący chmury kurzu unoszącego się nad peletonem oraz subtelne smugi drgań.
class CobblestoneDustAndChatterPainter extends CustomPainter {
  final CobblestoneFxFrameState frameState;
  final Scene3DMathProjection projection;

  const CobblestoneDustAndChatterPainter({
    required this.frameState,
    required this.projection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!frameState.isActive && frameState.dustParticles.isEmpty) return;

    // 1. Renderuj cząsteczki kurzu w przestrzeni 3D rzutowane na ekran
    final List<CobblestoneDustParticle> sorted =
        List<CobblestoneDustParticle>.from(frameState.dustParticles);

    for (final CobblestoneDustParticle p in sorted) {
      final ProjectedPoint3D projected = projection.worldToScreen(p.position);
      if (!projected.isInFrontOfCamera || !projected.isInViewport) continue;

      final double screenRadius =
          (p.radiusMeters * projected.perspectiveScale * 18.0).clamp(3.0, 72.0);
      final Offset center = Offset(projected.screenX, projected.screenY);

      final Paint dustPaint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            p.color.withValues(alpha: p.opacity * 0.72),
            p.color.withValues(alpha: p.opacity * 0.28),
            p.color.withValues(alpha: 0.0),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: screenRadius));

      canvas.drawCircle(center, screenRadius, dustPaint);
    }

    // 2. Subtelna winieta drgań na brzegach ekranu dla sektorów 3★–5★
    final CobblestoneSectorDifficulty? diff = frameState.difficulty;
    if (diff != null && diff.stars >= 3 && frameState.isActive) {
      final double intensity =
          ((diff.stars - 2) / 3.0) * frameState.handlebarVibration.forkChatterIntensity;
      if (intensity > 0.05) {
        final Paint edgePaint = Paint()
          ..shader = RadialGradient(
            radius: 1.05,
            colors: <Color>[
              Colors.transparent,
              AppColors.background.withValues(alpha: (0.18 * intensity).clamp(0.0, 0.28)),
            ],
            stops: const <double>[0.72, 1.0],
          ).createShader(Offset.zero & size);
        canvas.drawRect(Offset.zero & size, edgePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CobblestoneDustAndChatterPainter oldDelegate) {
    return oldDelegate.frameState != frameState;
  }
}

// =============================================================================
// 5. PANEL TELEMETRII I STEROWANIA EFEKTEM BRUKU (AAA UI)
// =============================================================================

/// Interaktywny panel podglądu i konfiguracji efektu drgań kamery/roweru na bruku.
class CobblestoneVibrationControlPanel extends StatefulWidget {
  final CobblestoneVibrationConfig config;
  final CobblestoneFxFrameState frameState;
  final CobblestoneSectorDifficulty selectedDifficulty;
  final ValueChanged<CobblestoneVibrationConfig> onConfigChanged;
  final ValueChanged<CobblestoneSectorDifficulty> onDifficultySelected;
  final bool enabled;

  const CobblestoneVibrationControlPanel({
    super.key,
    required this.config,
    required this.frameState,
    required this.selectedDifficulty,
    required this.onConfigChanged,
    required this.onDifficultySelected,
    this.enabled = true,
  });

  @override
  State<CobblestoneVibrationControlPanel> createState() =>
      _CobblestoneVibrationControlPanelState();
}

class _CobblestoneVibrationControlPanelState
    extends State<CobblestoneVibrationControlPanel> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 460;
        final bool isWide = constraints.maxWidth >= 900;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.55,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeader(isCompact),
                const SizedBox(height: 14),
                _buildStarSelector(isCompact),
                const SizedBox(height: 14),
                _buildTelemetryGrid(isCompact, isWide),
                const SizedBox(height: 14),
                _buildToggleRow(isCompact),
                const SizedBox(height: 12),
                _buildIntensitySlider(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final bool isActive = widget.config.enabled && widget.enabled;
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.goldAccent : const Color(0xFF2A2F3D),
            ),
          ),
          child: Icon(
            Icons.vibration_rounded,
            size: 18,
            color: isActive ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Sektor Bruku — Fizyka Kamery i Kierownicy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.selectedDifficulty.exampleSector,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _InteractiveTogglePill(
          label: isActive ? 'AKTYWNY' : 'WYŁ.',
          selected: isActive,
          enabled: widget.enabled,
          accentColor: AppColors.goldAccent,
          onTap: () {
            widget.onConfigChanged(
              widget.config.copyWith(enabled: !widget.config.enabled),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStarSelector(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CobblestoneSectorDifficulty.values.map((
        CobblestoneSectorDifficulty diff,
      ) {
        final bool isSelected = widget.selectedDifficulty == diff;
        return _InteractiveTogglePill(
          label: isCompact ? '${diff.stars}★' : diff.labelPl,
          selected: isSelected,
          enabled: widget.enabled,
          accentColor: diff.stars >= 4
              ? AppColors.primaryAccent
              : AppColors.goldAccent,
          onTap: () => widget.onDifficultySelected(diff),
        );
      }).toList(),
    );
  }

  Widget _buildTelemetryGrid(bool isCompact, bool isWide) {
    final HandlebarMicroVibration bar = widget.frameState.handlebarVibration;
    final List<_TelemetryMetricItem> metrics = <_TelemetryMetricItem>[
      _TelemetryMetricItem(
        label: 'Częstotliwość',
        value: '${bar.dominantFrequencyHz.toStringAsFixed(1)} Hz',
        accent: AppColors.accentBlue,
      ),
      _TelemetryMetricItem(
        label: 'Skok widelca',
        value: '${bar.verticalOffsetMm.abs().toStringAsFixed(1)} mm',
        accent: AppColors.amberWarning,
      ),
      _TelemetryMetricItem(
        label: 'Kurz nad grupą',
        value: '${widget.frameState.activeDustCount} cz.',
        accent: AppColors.goldAccent,
      ),
      _TelemetryMetricItem(
        label: 'Wężyk (korona)',
        value:
            '${widget.frameState.pelotonFileLengthMeters.toStringAsFixed(0)} m (${(widget.frameState.averageCrownAlignment * 100).round()}%)',
        accent: AppColors.statusSuccess,
      ),
    ];

    final int columns = isWide ? 4 : 2;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        const double gap = 8.0;
        final double itemWidth =
            (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics.map((_TelemetryMetricItem m) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2F3D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      m.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        letterSpacing: -0.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                        color: m.accent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildToggleRow(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _InteractiveTogglePill(
          label: 'Chmura kurzu',
          selected: widget.config.enableDustPlume,
          enabled: widget.enabled && widget.config.enabled,
          accentColor: AppColors.goldAccent,
          onTap: () {
            widget.onConfigChanged(
              widget.config.copyWith(
                enableDustPlume: !widget.config.enableDustPlume,
              ),
            );
          },
        ),
        _InteractiveTogglePill(
          label: 'Wężyk na koronie bruku',
          selected: widget.config.enablePelotonStringOut,
          enabled: widget.enabled && widget.config.enabled,
          accentColor: AppColors.accentBlue,
          onTap: () {
            widget.onConfigChanged(
              widget.config.copyWith(
                enablePelotonStringOut: !widget.config.enablePelotonStringOut,
              ),
            );
          },
        ),
        _InteractiveTogglePill(
          label: 'Mokry bruk (brak kurzu)',
          selected: widget.config.isWetCobbles,
          enabled: widget.enabled && widget.config.enabled,
          accentColor: AppColors.cyanAccent,
          onTap: () {
            widget.onConfigChanged(
              widget.config.copyWith(
                isWetCobbles: !widget.config.isWetCobbles,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIntensitySlider() {
    final bool canEdit = widget.enabled && widget.config.enabled;
    return Row(
      children: <Widget>[
        const Text(
          'Intensywność drgań',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
              disabledActiveTrackColor: AppColors.textSecondary,
              disabledThumbColor: AppColors.textSecondary,
            ),
            child: Slider(
              value: widget.config.vibrationIntensityScale.clamp(0.0, 2.0),
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: canEdit
                  ? (double value) {
                      widget.onConfigChanged(
                        widget.config.copyWith(vibrationIntensityScale: value),
                      );
                    }
                  : null,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(widget.config.vibrationIntensityScale * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TelemetryMetricItem {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryMetricItem({
    required this.label,
    required this.value,
    required this.accent,
  });
}

class _InteractiveTogglePill extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveTogglePill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveTogglePill> createState() => _InteractiveTogglePillState();
}

class _InteractiveTogglePillState extends State<_InteractiveTogglePill> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = !widget.enabled
        ? AppColors.background
        : widget.selected
            ? widget.accentColor.withValues(alpha: _isPressed ? 0.28 : 0.18)
            : (_isHovered ? AppColors.surfaceLight : AppColors.background);

    final Color border = !widget.enabled
        ? const Color(0xFF2A2F3D)
        : _isFocused
            ? AppColors.cyanAccent
            : widget.selected
                ? widget.accentColor
                : (_isHovered
                    ? AppColors.textSecondary
                    : const Color(0xFF2A2F3D));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (bool value) => setState(() => _isHovered = value),
      onShowFocusHighlight: (bool value) => setState(() => _isFocused = value),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: _isFocused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.2,
              color: !widget.enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : (widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
