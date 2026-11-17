// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// =============================================================================
// 1. ENUMY I MODELE KONFIGURACJI SCENY METY 3D
// =============================================================================

/// Tryby kamery 3D w strefie mety, fotoreporterów i opiekunów.
enum FinishLineCameraMode {
  /// Ujęcie teleobiektywem zza linii mety na wprost finiszujących kolarzy.
  frontTelephoto(
    labelPl: 'Teleobiektyw (Przód)',
    shortLabel: 'Przód',
    icon: Icons.camera_alt_rounded,
  ),

  /// Niskie ujęcie z boksu fotoreporterów (+14 m za kreską).
  pressPitLowAngle(
    labelPl: 'Boks Fotoreporterów',
    shortLabel: 'Prasa',
    icon: Icons.flash_on_rounded,
  ),

  /// Widok na korytarz opiekunów (Soigneurs) i strefę regeneracji (+55 m).
  soigneurCorridor(
    labelPl: 'Strefa Opiekunów',
    shortLabel: 'Opiekunowie',
    icon: Icons.medical_services_rounded,
  ),

  /// Ujęcie z helikoptera obejmujące całą strefę mety i konfetti.
  helicopterOverhead(
    labelPl: 'Helikopter TV',
    shortLabel: 'Helikopter',
    icon: Icons.airplanemode_active_rounded,
  );

  final String labelPl;
  final String shortLabel;
  final IconData icon;

  const FinishLineCameraMode({
    required this.labelPl,
    required this.shortLabel,
    required this.icon,
  });
}

/// Motyw kolorystyczny konfetti na mecie w zależności od rangi wyścigu.
enum FinishConfettiTheme {
  championshipGold(
    labelPl: 'Złoto Mistrzowskie',
    colors: <Color>[
      AppColors.goldAccent,
      AppColors.textPrimary,
      AppColors.primaryAccent,
      Color(0xFFFDE68A),
    ],
  ),
  grandTourYellow(
    labelPl: 'Żółty Grand Tour',
    colors: <Color>[
      Color(0xFFFACC15),
      Color(0xFFFEF08A),
      AppColors.textPrimary,
      Color(0xFF181B22),
    ],
  ),
  giroPink(
    labelPl: 'Różowy Klasyk',
    colors: <Color>[
      Color(0xFFF472B6),
      Color(0xFFFBCFE8),
      AppColors.textPrimary,
      AppColors.goldAccent,
    ],
  ),
  telemetryCyan(
    labelPl: 'Puchar Świata',
    colors: <Color>[
      AppColors.cyanAccent,
      AppColors.accentBlue,
      AppColors.textPrimary,
      AppColors.goldAccent,
    ],
  );

  final String labelPl;
  final List<Color> colors;

  const FinishConfettiTheme({
    required this.labelPl,
    required this.colors,
  });
}

/// Rola fotografa w strefie prasowej za linią mety.
enum PhotographerStance {
  kneelingTelephoto,
  standingPress,
  elevatedPlatform,
}

/// Rola opiekuna (soigneura) w strefie regeneracji za metą.
enum SoigneurActionRole {
  holdingBidon,
  holdingMusette,
  holdingIceTowel,
  catchingRider,
}

/// Konfiguracja strefy mety 3D (fotoreporterzy, konfetti, strefa opiekunów).
class FinishLineZoneConfig {
  final double roadWidthMeters;
  final double pressZoneStartMeters;
  final double pressZoneEndMeters;
  final double soigneurZoneStartMeters;
  final double soigneurZoneEndMeters;
  final int photographerCount;
  final int soigneurCount;
  final int maxConfettiParticles;
  final double lateralWindMs;
  final FinishConfettiTheme confettiTheme;
  final String stageTitle;

  const FinishLineZoneConfig({
    this.roadWidthMeters = 7.6,
    this.pressZoneStartMeters = 8.0,
    this.pressZoneEndMeters = 34.0,
    this.soigneurZoneStartMeters = 38.0,
    this.soigneurZoneEndMeters = 115.0,
    this.photographerCount = 18,
    this.soigneurCount = 14,
    this.maxConfettiParticles = 240,
    this.lateralWindMs = 1.4,
    this.confettiTheme = FinishConfettiTheme.championshipGold,
    this.stageTitle = 'FINAŁ ETAPU • LINIA METY',
  });

  FinishLineZoneConfig copyWith({
    double? roadWidthMeters,
    double? pressZoneStartMeters,
    double? pressZoneEndMeters,
    double? soigneurZoneStartMeters,
    double? soigneurZoneEndMeters,
    int? photographerCount,
    int? soigneurCount,
    int? maxConfettiParticles,
    double? lateralWindMs,
    FinishConfettiTheme? confettiTheme,
    String? stageTitle,
  }) {
    return FinishLineZoneConfig(
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      pressZoneStartMeters: pressZoneStartMeters ?? this.pressZoneStartMeters,
      pressZoneEndMeters: pressZoneEndMeters ?? this.pressZoneEndMeters,
      soigneurZoneStartMeters:
          soigneurZoneStartMeters ?? this.soigneurZoneStartMeters,
      soigneurZoneEndMeters:
          soigneurZoneEndMeters ?? this.soigneurZoneEndMeters,
      photographerCount: photographerCount ?? this.photographerCount,
      soigneurCount: soigneurCount ?? this.soigneurCount,
      maxConfettiParticles: maxConfettiParticles ?? this.maxConfettiParticles,
      lateralWindMs: lateralWindMs ?? this.lateralWindMs,
      confettiTheme: confettiTheme ?? this.confettiTheme,
      stageTitle: stageTitle ?? this.stageTitle,
    );
  }
}

// =============================================================================
// 2. OBIEKTY 3D W STREFIE METY
// =============================================================================

/// Pojedynczy fotoreporter w boksie prasowym za linią mety.
class Photographer3D {
  final String id;
  final vm.Vector3 position;
  final PhotographerStance stance;
  final Color vestColor;
  final double yawAngleRad;
  final double flashCooldownSeconds;
  final double lastFlashIntensity;

  const Photographer3D({
    required this.id,
    required this.position,
    required this.stance,
    required this.vestColor,
    required this.yawAngleRad,
    this.flashCooldownSeconds = 0.0,
    this.lastFlashIntensity = 0.0,
  });

  Photographer3D copyWith({
    double? flashCooldownSeconds,
    double? lastFlashIntensity,
    double? yawAngleRad,
  }) {
    return Photographer3D(
      id: id,
      position: position,
      stance: stance,
      vestColor: vestColor,
      yawAngleRad: yawAngleRad ?? this.yawAngleRad,
      flashCooldownSeconds: flashCooldownSeconds ?? this.flashCooldownSeconds,
      lastFlashIntensity: lastFlashIntensity ?? this.lastFlashIntensity,
    );
  }
}

/// Błysk flesza aparatu w przestrzeni 3D.
class CameraFlashBurst3D {
  final vm.Vector3 position;
  final double ageSeconds;
  final double durationSeconds;
  final double peakIntensity;

  const CameraFlashBurst3D({
    required this.position,
    required this.ageSeconds,
    this.durationSeconds = 0.24,
    this.peakIntensity = 1.0,
  });

  bool get isExpired => ageSeconds >= durationSeconds;

  double get currentIntensity {
    if (isExpired) return 0.0;
    final double t = (ageSeconds / durationSeconds).clamp(0.0, 1.0);
    // Szybki pik błysku i wykładniczy zanik
    return peakIntensity * math.pow(1.0 - t, 2.4).toDouble();
  }

  CameraFlashBurst3D advance(double dt) {
    return CameraFlashBurst3D(
      position: position,
      ageSeconds: ageSeconds + dt,
      durationSeconds: durationSeconds,
      peakIntensity: peakIntensity,
    );
  }
}

/// Pojedyncza cząsteczka konfetti 3D z pełną fizyką opadania i wirowania.
class ConfettiParticle3D {
  final vm.Vector3 position;
  final vm.Vector3 velocity;
  final double pitchRad;
  final double yawRad;
  final double rollRad;
  final double spinPitchSpeed;
  final double spinYawSpeed;
  final double widthMeters;
  final double heightMeters;
  final Color color;
  final bool isSettled;
  final double flutterPhase;

  const ConfettiParticle3D({
    required this.position,
    required this.velocity,
    required this.pitchRad,
    required this.yawRad,
    required this.rollRad,
    required this.spinPitchSpeed,
    required this.spinYawSpeed,
    required this.widthMeters,
    required this.heightMeters,
    required this.color,
    this.isSettled = false,
    this.flutterPhase = 0.0,
  });

  ConfettiParticle3D step(double dt, double lateralWindMs) {
    if (isSettled) {
      return this;
    }

    const double gravity = 5.4;
    const double drag = 1.85;

    final double nextFlutter = flutterPhase + dt * 7.5;
    final double flutterLateral = math.sin(nextFlutter) * 1.1;

    final double vx =
        velocity.x + ((lateralWindMs + flutterLateral - velocity.x) * drag * dt);
    final double vy = (velocity.y - gravity * dt).clamp(-2.8, 18.0);
    final double vz = velocity.z * (1.0 - drag * 0.65 * dt).clamp(0.0, 1.0);

    final double nx = position.x + vx * dt;
    final double ny = position.y + vy * dt;
    final double nz = position.z + vz * dt;

    if (ny <= 0.02) {
      return ConfettiParticle3D(
        position: vm.Vector3(nx, 0.02, nz),
        velocity: vm.Vector3.zero(),
        pitchRad: 0.0,
        yawRad: yawRad,
        rollRad: rollRad,
        spinPitchSpeed: 0.0,
        spinYawSpeed: 0.0,
        widthMeters: widthMeters,
        heightMeters: heightMeters,
        color: color,
        isSettled: true,
        flutterPhase: nextFlutter,
      );
    }

    return ConfettiParticle3D(
      position: vm.Vector3(nx, ny, nz),
      velocity: vm.Vector3(vx, vy, vz),
      pitchRad: pitchRad + spinPitchSpeed * dt,
      yawRad: yawRad + spinYawSpeed * dt,
      rollRad: rollRad + (spinPitchSpeed * 0.5) * dt,
      spinPitchSpeed: spinPitchSpeed,
      spinYawSpeed: spinYawSpeed,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
      color: color,
      isSettled: false,
      flutterPhase: nextFlutter,
    );
  }
}

/// Opiekun drużyny (Soigneur) czekający na kolarzy za strefą fotografów.
class Soigneur3D {
  final String id;
  final String teamCode;
  final vm.Vector3 position;
  final Color jacketColor;
  final Color accentColor;
  final SoigneurActionRole role;
  final double wavePhase;

  const Soigneur3D({
    required this.id,
    required this.teamCode,
    required this.position,
    required this.jacketColor,
    required this.accentColor,
    required this.role,
    this.wavePhase = 0.0,
  });

  Soigneur3D advance(double dt) {
    return Soigneur3D(
      id: id,
      teamCode: teamCode,
      position: position,
      jacketColor: jacketColor,
      accentColor: accentColor,
      role: role,
      wavePhase: wavePhase + dt * 3.2,
    );
  }
}

/// Kolarz przekraczający linię mety i zwalniający w strefie opiekunów.
class FinishZoneRider3D {
  final String id;
  final String name;
  final double distanceFromFinishMeters;
  final double lateralOffsetMeters;
  final double speedMs;
  final Color jerseyColor;
  final Color secondaryColor;
  final bool isWinner;
  final bool isSaluting;
  final double crankAngleRad;

  const FinishZoneRider3D({
    required this.id,
    required this.name,
    required this.distanceFromFinishMeters,
    required this.lateralOffsetMeters,
    required this.speedMs,
    required this.jerseyColor,
    required this.secondaryColor,
    this.isWinner = false,
    this.isSaluting = false,
    this.crankAngleRad = 0.0,
  });

  FinishZoneRider3D step(double dt) {
    // Wyhamowywanie po minięciu mety, aż do zatrzymania w strefie opiekunów
    double nextSpeed = speedMs;
    if (distanceFromFinishMeters > 6.0) {
      final double decel = distanceFromFinishMeters > 35.0 ? 2.6 : 1.4;
      nextSpeed = math.max(1.2, speedMs - decel * dt);
    }
    if (distanceFromFinishMeters > 96.0) {
      nextSpeed = 0.0;
    }

    double nextDist = distanceFromFinishMeters + nextSpeed * dt;
    if (nextDist > 125.0) {
      // Pętla demonstracyjna po pełnym wyhamowaniu i odbiorze bidonu
      nextDist = -18.0;
      nextSpeed = isWinner ? 17.5 : 16.2;
    }

    // Zjazd lekko ku krawędzi w strefie opiekunów
    double nextLat = lateralOffsetMeters;
    if (nextDist > 42.0 && nextDist < 100.0) {
      final double targetLat = isWinner ? -2.2 : (lateralOffsetMeters >= 0 ? 2.3 : -2.3);
      nextLat = lateralOffsetMeters + (targetLat - lateralOffsetMeters) * dt * 0.9;
    } else if (nextDist < 0.0) {
      nextLat = isWinner ? 0.0 : lateralOffsetMeters;
    }

    final bool salutingNow = isWinner && nextDist >= -4.0 && nextDist <= 22.0;

    return FinishZoneRider3D(
      id: id,
      name: name,
      distanceFromFinishMeters: nextDist,
      lateralOffsetMeters: nextLat,
      speedMs: nextSpeed,
      jerseyColor: jerseyColor,
      secondaryColor: secondaryColor,
      isWinner: isWinner,
      isSaluting: salutingNow,
      crankAngleRad: crankAngleRad + nextSpeed * dt * 1.8,
    );
  }
}

/// Telemetria bieżącej klatki strefy mety 3D.
class FinishLineZoneTelemetry {
  final int activeConfettiCount;
  final int settledConfettiCount;
  final int activeFlashesCount;
  final int totalFlashesTriggered;
  final int photographersCount;
  final int soigneursCount;
  final double winnerDistanceMeters;
  final bool confettiCannonFired;

  const FinishLineZoneTelemetry({
    required this.activeConfettiCount,
    required this.settledConfettiCount,
    required this.activeFlashesCount,
    required this.totalFlashesTriggered,
    required this.photographersCount,
    required this.soigneursCount,
    required this.winnerDistanceMeters,
    required this.confettiCannonFired,
  });
}

// =============================================================================
// 3. SILNIK SYMULACJI STREFY METY 3D
// =============================================================================

/// Silnik zarządzający fotoreporterami, błyskami fleszy, konfetti i strefą opiekunów w 3D.
class FinishLineConfettiAndPhotographers3dEngine {
  FinishLineZoneConfig config;
  final math.Random _rng;

  List<Photographer3D> photographers = <Photographer3D>[];
  List<Soigneur3D> soigneurs = <Soigneur3D>[];
  List<ConfettiParticle3D> confetti = <ConfettiParticle3D>[];
  List<CameraFlashBurst3D> flashes = <CameraFlashBurst3D>[];
  List<FinishZoneRider3D> riders = <FinishZoneRider3D>[];

  double elapsedSeconds = 0.0;
  int totalFlashesTriggered = 0;
  bool _cannonFiredForCurrentLap = false;

  FinishLineConfettiAndPhotographers3dEngine({
    this.config = const FinishLineZoneConfig(),
    int seed = 531,
  }) : _rng = math.Random(seed) {
    _initializeScene();
  }

  void updateConfig(FinishLineZoneConfig nextConfig) {
    final bool rebuildActors =
        nextConfig.photographerCount != config.photographerCount ||
            nextConfig.soigneurCount != config.soigneurCount ||
            nextConfig.roadWidthMeters != config.roadWidthMeters;
    config = nextConfig;
    if (rebuildActors) {
      _initializePhotographers();
      _initializeSoigneurs();
    }
  }

  void _initializeScene() {
    _initializePhotographers();
    _initializeSoigneurs();
    _initializeDemoRiders();
    triggerConfettiCannonBurst(count: 140);
  }

  void _initializePhotographers() {
    final List<Photographer3D> list = <Photographer3D>[];
    final double halfRoad = config.roadWidthMeters * 0.5;
    final int count = config.photographerCount;

    for (int i = 0; i < count; i++) {
      final double t = count <= 1 ? 0.5 : i / (count - 1);
      final double z = config.pressZoneStartMeters +
          t * (config.pressZoneEndMeters - config.pressZoneStartMeters);
      final bool isLeft = i % 2 == 0;
      final bool isCenterPen = i < 4;

      final double x = isCenterPen
          ? -1.6 + (i * 1.05)
          : (isLeft ? -(halfRoad + 0.85) : (halfRoad + 0.85));
      final double y = isCenterPen ? 0.0 : (i % 5 == 0 ? 0.85 : 0.0);

      final PhotographerStance stance = isCenterPen
          ? PhotographerStance.kneelingTelephoto
          : (y > 0.1
              ? PhotographerStance.elevatedPlatform
              : PhotographerStance.standingPress);

      list.add(
        Photographer3D(
          id: 'photo_$i',
          position: vm.Vector3(x, y, isCenterPen ? config.pressZoneEndMeters : z),
          stance: stance,
          vestColor: i % 3 == 0
              ? const Color(0xFFF97316)
              : (i % 3 == 1 ? const Color(0xFFEAB308) : AppColors.cyanAccent),
          yawAngleRad: isCenterPen ? math.pi : (isLeft ? math.pi * 0.72 : -math.pi * 0.72),
          flashCooldownSeconds: _rng.nextDouble() * 0.6,
        ),
      );
    }
    photographers = list;
  }

  void _initializeSoigneurs() {
    final List<Soigneur3D> list = <Soigneur3D>[];
    final double halfRoad = config.roadWidthMeters * 0.5;
    final int count = config.soigneurCount;

    final List<(String, Color, Color)> teamKits = <(String, Color, Color)>[
      ('PRO', AppColors.primaryAccent, AppColors.goldAccent),
      ('SKY', AppColors.accentBlue, AppColors.textPrimary),
      ('EMR', AppColors.statusSuccess, AppColors.goldAccent),
      ('VLT', AppColors.amberWarning, const Color(0xFF181B22)),
    ];

    for (int i = 0; i < count; i++) {
      final double t = count <= 1 ? 0.5 : i / (count - 1);
      final double z = config.soigneurZoneStartMeters +
          t * (config.soigneurZoneEndMeters - config.soigneurZoneStartMeters);
      final bool isLeft = i % 2 == 0;
      final double x = isLeft ? -(halfRoad - 0.35) : (halfRoad - 0.35);
      final (String code, Color jacket, Color accent) =
          teamKits[i % teamKits.length];

      list.add(
        Soigneur3D(
          id: 'soig_$i',
          teamCode: code,
          position: vm.Vector3(x, 0.0, z),
          jacketColor: jacket,
          accentColor: accent,
          role: SoigneurActionRole
              .values[i % SoigneurActionRole.values.length],
          wavePhase: i * 0.7,
        ),
      );
    }
    soigneurs = list;
  }

  void _initializeDemoRiders() {
    riders = <FinishZoneRider3D>[
      const FinishZoneRider3D(
        id: 'rider_winner',
        name: 'K. Majka',
        distanceFromFinishMeters: -6.0,
        lateralOffsetMeters: 0.0,
        speedMs: 17.8,
        jerseyColor: AppColors.goldAccent,
        secondaryColor: AppColors.primaryAccent,
        isWinner: true,
      ),
      const FinishZoneRider3D(
        id: 'rider_2',
        name: 'M. Van der Berg',
        distanceFromFinishMeters: -11.5,
        lateralOffsetMeters: 1.45,
        speedMs: 17.2,
        jerseyColor: AppColors.accentBlue,
        secondaryColor: AppColors.textPrimary,
      ),
      const FinishZoneRider3D(
        id: 'rider_3',
        name: 'L. Moretti',
        distanceFromFinishMeters: -14.2,
        lateralOffsetMeters: -1.35,
        speedMs: 16.9,
        jerseyColor: AppColors.primaryAccent,
        secondaryColor: AppColors.goldAccent,
      ),
      const FinishZoneRider3D(
        id: 'rider_4',
        name: 'J. Dubois',
        distanceFromFinishMeters: 44.0,
        lateralOffsetMeters: 2.1,
        speedMs: 4.5,
        jerseyColor: AppColors.statusSuccess,
        secondaryColor: AppColors.textPrimary,
      ),
    ];
  }

  /// Wystrzeliwuje salwę konfetti z obu armat przy bramie mety (`z = 0.0 m`).
  void triggerConfettiCannonBurst({int count = 110}) {
    final double halfRoad = config.roadWidthMeters * 0.5;
    final List<Color> palette = config.confettiTheme.colors;
    final List<ConfettiParticle3D> next = List<ConfettiParticle3D>.from(confetti);

    for (int i = 0; i < count; i++) {
      final bool fromLeftCannon = i % 2 == 0;
      final double originX = fromLeftCannon ? -(halfRoad + 0.3) : (halfRoad + 0.3);
      final double inwardVx =
          (fromLeftCannon ? 1.0 : -1.0) * (2.6 + _rng.nextDouble() * 4.5);

      next.add(
        ConfettiParticle3D(
          position: vm.Vector3(
            originX + (_rng.nextDouble() - 0.5) * 0.4,
            1.6 + _rng.nextDouble() * 1.4,
            (_rng.nextDouble() - 0.5) * 1.6,
          ),
          velocity: vm.Vector3(
            inwardVx,
            5.8 + _rng.nextDouble() * 5.2,
            (_rng.nextDouble() - 0.3) * 4.2,
          ),
          pitchRad: _rng.nextDouble() * math.pi * 2,
          yawRad: _rng.nextDouble() * math.pi * 2,
          rollRad: _rng.nextDouble() * math.pi * 2,
          spinPitchSpeed: (_rng.nextDouble() - 0.5) * 14.0,
          spinYawSpeed: (_rng.nextDouble() - 0.5) * 12.0,
          widthMeters: 0.08 + _rng.nextDouble() * 0.08,
          heightMeters: 0.04 + _rng.nextDouble() * 0.05,
          color: palette[_rng.nextInt(palette.length)],
          flutterPhase: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }

    if (next.length > config.maxConfettiParticles) {
      next.removeRange(0, next.length - config.maxConfettiParticles);
    }
    confetti = next;
  }

  /// Wyzwala serię błysków aparatów fotoreporterów.
  void triggerPhotographerFlashVolley({int bursts = 5}) {
    if (photographers.isEmpty) return;
    final List<CameraFlashBurst3D> nextFlashes =
        List<CameraFlashBurst3D>.from(flashes);
    for (int i = 0; i < bursts; i++) {
      final Photographer3D p =
          photographers[_rng.nextInt(photographers.length)];
      nextFlashes.add(
        CameraFlashBurst3D(
          position: vm.Vector3(p.position.x, p.position.y + 1.35, p.position.z),
          ageSeconds: 0.0,
          durationSeconds: 0.22 + _rng.nextDouble() * 0.08,
          peakIntensity: 0.85 + _rng.nextDouble() * 0.15,
        ),
      );
      totalFlashesTriggered++;
    }
    flashes = nextFlashes;
  }

  /// Główny krok symulacji 3D strefy mety.
  void step(double dt) {
    final double clampedDt = dt.clamp(0.0, 0.05);
    elapsedSeconds += clampedDt;

    // 1. Kolarze i automatyczne wyzwalanie konfetti przy przekroczeniu kreski
    final List<FinishZoneRider3D> nextRiders = <FinishZoneRider3D>[];
    double winnerZ = 0.0;
    for (final FinishZoneRider3D r in riders) {
      final FinishZoneRider3D updated = r.step(clampedDt);
      if (updated.isWinner) {
        winnerZ = updated.distanceFromFinishMeters;
        if (r.distanceFromFinishMeters < 0.0 &&
            updated.distanceFromFinishMeters >= 0.0 &&
            !_cannonFiredForCurrentLap) {
          _cannonFiredForCurrentLap = true;
          triggerConfettiCannonBurst(count: 130);
          triggerPhotographerFlashVolley(bursts: 7);
        } else if (updated.distanceFromFinishMeters < -5.0) {
          _cannonFiredForCurrentLap = false;
        }
      }
      nextRiders.add(updated);
    }
    riders = nextRiders;

    // 2. Fotoreporterzy i automatyczne błyski gdy kolarze są w strefie [-4..+30 m]
    final bool ridersInPhotoZone =
        winnerZ >= -4.0 && winnerZ <= config.pressZoneEndMeters;
    final List<Photographer3D> nextPhotographers = <Photographer3D>[];
    final List<CameraFlashBurst3D> nextFlashes = flashes
        .map((CameraFlashBurst3D f) => f.advance(clampedDt))
        .where((CameraFlashBurst3D f) => !f.isExpired)
        .toList();

    for (final Photographer3D p in photographers) {
      double cooldown = p.flashCooldownSeconds - clampedDt;
      double flashIntensity = math.max(0.0, p.lastFlashIntensity - clampedDt * 4.5);

      if (ridersInPhotoZone && cooldown <= 0.0) {
        if (_rng.nextDouble() < 0.42) {
          nextFlashes.add(
            CameraFlashBurst3D(
              position:
                  vm.Vector3(p.position.x, p.position.y + 1.32, p.position.z),
              ageSeconds: 0.0,
            ),
          );
          totalFlashesTriggered++;
          flashIntensity = 1.0;
        }
        cooldown = 0.28 + _rng.nextDouble() * 0.55;
      }

      nextPhotographers.add(
        p.copyWith(
          flashCooldownSeconds: cooldown,
          lastFlashIntensity: flashIntensity,
        ),
      );
    }
    photographers = nextPhotographers;
    flashes = nextFlashes;

    // 3. Fizyka konfetti 3D
    confetti = confetti
        .map((ConfettiParticle3D c) => c.step(clampedDt, config.lateralWindMs))
        .toList();

    // 4. Animacja opiekunów (Soigneurs)
    soigneurs = soigneurs.map((Soigneur3D s) => s.advance(clampedDt)).toList();
  }

  FinishLineZoneTelemetry get telemetry {
    int settled = 0;
    for (final ConfettiParticle3D c in confetti) {
      if (c.isSettled) settled++;
    }
    double winnerDist = 0.0;
    for (final FinishZoneRider3D r in riders) {
      if (r.isWinner) {
        winnerDist = r.distanceFromFinishMeters;
        break;
      }
    }
    return FinishLineZoneTelemetry(
      activeConfettiCount: confetti.length - settled,
      settledConfettiCount: settled,
      activeFlashesCount: flashes.length,
      totalFlashesTriggered: totalFlashesTriggered,
      photographersCount: photographers.length,
      soigneursCount: soigneurs.length,
      winnerDistanceMeters: winnerDist,
      confettiCannonFired: _cannonFiredForCurrentLap,
    );
  }
}

// =============================================================================
// 4. RZUTNIK 3D I PAINTER STREFY METY
// =============================================================================

/// Wewnętrzny rzutowany punkt 2D z głębokością Z w układzie kamery.
class _ProjectedPoint {
  final Offset offset;
  final double depth;
  final double scale;

  const _ProjectedPoint({
    required this.offset,
    required this.depth,
    required this.scale,
  });
}

/// Element kolejki malowania sortowany od najdalszego (Painter's algorithm).
class _DepthRenderItem {
  final double depth;
  final void Function(Canvas canvas) draw;

  const _DepthRenderItem({
    required this.depth,
    required this.draw,
  });
}

/// Painter 3D renderujący linię mety, bramę, fotoreporterów z fleszami, konfetti i strefę opiekunów.
class FinishLineConfettiAndPhotographers3dPainter extends CustomPainter {
  final FinishLineConfettiAndPhotographers3dEngine engine;
  final FinishLineCameraMode cameraMode;

  FinishLineConfettiAndPhotographers3dPainter({
    required this.engine,
    required this.cameraMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0) return;

    final vm.Matrix4 viewMatrix = _buildCameraViewMatrix();
    final double focalLength = size.height * 0.92;

    // 1. Niebo i tło horyzontu
    _paintSkyAndBackdrop(canvas, size);

    // 2. Wstęga szosy, linia mety i strefy pobocza (press pen & soigneur corridor)
    _paintRoadAndFinishZones(canvas, size, viewMatrix, focalLength);

    // 3. Brama mety z zegarem
    _paintFinishGantryArch(canvas, size, viewMatrix, focalLength);

    // 4. Kolejka 3D sortowana głębokością Z (barierki, fotoreporterzy, opiekunowie, kolarze, konfetti, flesze)
    final List<_DepthRenderItem> items = <_DepthRenderItem>[];

    // Fotoreporterzy
    for (final Photographer3D p in engine.photographers) {
      final _ProjectedPoint? proj =
          _project(p.position, viewMatrix, size, focalLength);
      if (proj == null) continue;
      items.add(
        _DepthRenderItem(
          depth: proj.depth,
          draw: (Canvas c) => _drawPhotographer3D(c, proj, p),
        ),
      );
    }

    // Opiekunowie (Soigneurs)
    for (final Soigneur3D s in engine.soigneurs) {
      final _ProjectedPoint? proj =
          _project(s.position, viewMatrix, size, focalLength);
      if (proj == null) continue;
      items.add(
        _DepthRenderItem(
          depth: proj.depth,
          draw: (Canvas c) => _drawSoigneur3D(c, proj, s),
        ),
      );
    }

    // Kolarze
    for (final FinishZoneRider3D r in engine.riders) {
      final vm.Vector3 pos =
          vm.Vector3(r.lateralOffsetMeters, 0.0, r.distanceFromFinishMeters);
      final _ProjectedPoint? proj = _project(pos, viewMatrix, size, focalLength);
      if (proj == null) continue;
      items.add(
        _DepthRenderItem(
          depth: proj.depth,
          draw: (Canvas c) => _drawRider3D(c, proj, r),
        ),
      );
    }

    // Konfetti 3D
    for (final ConfettiParticle3D conf in engine.confetti) {
      final _ProjectedPoint? proj =
          _project(conf.position, viewMatrix, size, focalLength);
      if (proj == null) continue;
      items.add(
        _DepthRenderItem(
          depth: proj.depth,
          draw: (Canvas c) => _drawConfetti3D(c, proj, conf),
        ),
      );
    }

    // Błyski fleszy
    for (final CameraFlashBurst3D flash in engine.flashes) {
      final _ProjectedPoint? proj =
          _project(flash.position, viewMatrix, size, focalLength);
      if (proj == null) continue;
      items.add(
        _DepthRenderItem(
          depth: proj.depth - 0.2,
          draw: (Canvas c) => _drawFlashBurst3D(c, proj, flash),
        ),
      );
    }

    items.sort((_DepthRenderItem a, _DepthRenderItem b) =>
        b.depth.compareTo(a.depth));
    for (final _DepthRenderItem item in items) {
      item.draw(canvas);
    }
  }

  vm.Matrix4 _buildCameraViewMatrix() {
    late final vm.Vector3 eye;
    late final vm.Vector3 target;

    switch (cameraMode) {
      case FinishLineCameraMode.frontTelephoto:
        eye = vm.Vector3(0.0, 2.35, 34.0);
        target = vm.Vector3(0.0, 1.1, -6.0);
        break;
      case FinishLineCameraMode.pressPitLowAngle:
        eye = vm.Vector3(-4.2, 1.45, 21.0);
        target = vm.Vector3(0.3, 1.25, 0.0);
        break;
      case FinishLineCameraMode.soigneurCorridor:
        eye = vm.Vector3(4.4, 3.2, 28.0);
        target = vm.Vector3(0.0, 1.0, 72.0);
        break;
      case FinishLineCameraMode.helicopterOverhead:
        eye = vm.Vector3(14.0, 22.0, -18.0);
        target = vm.Vector3(0.0, 0.0, 32.0);
        break;
    }

    return vm.makeViewMatrix(eye, target, vm.Vector3(0.0, 1.0, 0.0));
  }

  _ProjectedPoint? _project(
    vm.Vector3 worldPos,
    vm.Matrix4 viewMatrix,
    Size size,
    double focalLength,
  ) {
    final vm.Vector3 cam = viewMatrix.transformed3(worldPos);
    // W OpenGL / vector_math kamera patrzy wzdłuż osi -Z
    final double depth = -cam.z;
    if (depth <= 0.6 || depth > 260.0) {
      return null;
    }
    final double invDepth = 1.0 / depth;
    final double px = size.width * 0.5 + (cam.x * focalLength * invDepth);
    final double py = size.height * 0.52 - (cam.y * focalLength * invDepth);
    if (px < -180 || px > size.width + 180 || py < -180 || py > size.height + 180) {
      return null;
    }
    return _ProjectedPoint(
      offset: Offset(px, py),
      depth: depth,
      scale: focalLength * invDepth,
    );
  }

  void _paintSkyAndBackdrop(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF0A0D14),
          Color(0xFF151C28),
          Color(0xFF1E2433),
        ],
      ).createShader(full);
    canvas.drawRect(full, skyPaint);

    // Linia horyzontu i trybuny miejskie w tle
    final double horizonY = size.height * 0.44;
    final Paint horizonGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.15),
        radius: 0.9,
        colors: <Color>[
          AppColors.goldAccent.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(full);
    canvas.drawRect(full, horizonGlow);

    final Paint groundPaint = Paint()..color = const Color(0xFF12161E);
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      groundPaint,
    );
  }

  void _paintRoadAndFinishZones(
    Canvas canvas,
    Size size,
    vm.Matrix4 viewMatrix,
    double focalLength,
  ) {
    final double halfRoad = engine.config.roadWidthMeters * 0.5;
    const double zStart = -24.0;
    const double zEnd = 128.0;
    const double step = 4.0;

    final Paint asphaltPaint = Paint()..color = const Color(0xFF232834);
    final Paint pressFloorPaint = Paint()
      ..color = AppColors.primaryAccent.withValues(alpha: 0.22);
    final Paint soigneurFloorPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.18);
    final Paint linePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.72)
      ..strokeWidth = 1.6;

    for (double z = zStart; z < zEnd; z += step) {
      final double zNext = z + step;
      final _ProjectedPoint? bl = _project(
          vm.Vector3(-halfRoad, 0.0, z), viewMatrix, size, focalLength);
      final _ProjectedPoint? br = _project(
          vm.Vector3(halfRoad, 0.0, z), viewMatrix, size, focalLength);
      final _ProjectedPoint? tl = _project(
          vm.Vector3(-halfRoad, 0.0, zNext), viewMatrix, size, focalLength);
      final _ProjectedPoint? tr = _project(
          vm.Vector3(halfRoad, 0.0, zNext), viewMatrix, size, focalLength);
      if (bl == null || br == null || tl == null || tr == null) continue;

      final Path quad = Path()
        ..moveTo(bl.offset.dx, bl.offset.dy)
        ..lineTo(br.offset.dx, br.offset.dy)
        ..lineTo(tr.offset.dx, tr.offset.dy)
        ..lineTo(tl.offset.dx, tl.offset.dy)
        ..close();

      canvas.drawPath(quad, asphaltPaint);

      // Wyróżnienie strefy prasy i strefy opiekunów na nawierzchni
      if (z >= engine.config.pressZoneStartMeters &&
          z < engine.config.pressZoneEndMeters) {
        canvas.drawPath(quad, pressFloorPaint);
      } else if (z >= engine.config.soigneurZoneStartMeters &&
          z < engine.config.soigneurZoneEndMeters) {
        canvas.drawPath(quad, soigneurFloorPaint);
      }

      // Białe linie krawędziowe
      canvas.drawLine(bl.offset, tl.offset, linePaint);
      canvas.drawLine(br.offset, tr.offset, linePaint);
    }

    // Szachownica linii mety na z = 0.0 m
    const int checkerCols = 12;
    final double colW = engine.config.roadWidthMeters / checkerCols;
    for (int i = 0; i < checkerCols; i++) {
      final double x0 = -halfRoad + i * colW;
      final double x1 = x0 + colW;
      final _ProjectedPoint? p00 =
          _project(vm.Vector3(x0, 0.01, -0.45), viewMatrix, size, focalLength);
      final _ProjectedPoint? p10 =
          _project(vm.Vector3(x1, 0.01, -0.45), viewMatrix, size, focalLength);
      final _ProjectedPoint? p11 =
          _project(vm.Vector3(x1, 0.01, 0.45), viewMatrix, size, focalLength);
      final _ProjectedPoint? p01 =
          _project(vm.Vector3(x0, 0.01, 0.45), viewMatrix, size, focalLength);
      if (p00 == null || p10 == null || p11 == null || p01 == null) continue;

      final Path cell = Path()
        ..moveTo(p00.offset.dx, p00.offset.dy)
        ..lineTo(p10.offset.dx, p10.offset.dy)
        ..lineTo(p11.offset.dx, p11.offset.dy)
        ..lineTo(p01.offset.dx, p01.offset.dy)
        ..close();
      canvas.drawPath(
        cell,
        Paint()
          ..color = i.isEven ? AppColors.textPrimary : const Color(0xFF111318),
      );
    }
  }

  void _paintFinishGantryArch(
    Canvas canvas,
    Size size,
    vm.Matrix4 viewMatrix,
    double focalLength,
  ) {
    final double halfRoad = engine.config.roadWidthMeters * 0.5 + 0.4;
    const double archHeight = 5.2;

    final _ProjectedPoint? lb =
        _project(vm.Vector3(-halfRoad, 0.0, 0.0), viewMatrix, size, focalLength);
    final _ProjectedPoint? lt = _project(
        vm.Vector3(-halfRoad, archHeight, 0.0), viewMatrix, size, focalLength);
    final _ProjectedPoint? rb =
        _project(vm.Vector3(halfRoad, 0.0, 0.0), viewMatrix, size, focalLength);
    final _ProjectedPoint? rt = _project(
        vm.Vector3(halfRoad, archHeight, 0.0), viewMatrix, size, focalLength);

    if (lb == null || lt == null || rb == null || rt == null) return;

    final Paint pillarPaint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = (0.35 * lb.scale).clamp(4.0, 18.0)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(lb.offset, lt.offset, pillarPaint);
    canvas.drawLine(rb.offset, rt.offset, pillarPaint);

    // Belka główna bramy z akcentem burgundu i złota
    final double bannerDrop = (0.95 * lt.scale).clamp(10.0, 34.0);
    final Path banner = Path()
      ..moveTo(lt.offset.dx, lt.offset.dy)
      ..lineTo(rt.offset.dx, rt.offset.dy)
      ..lineTo(rt.offset.dx, rt.offset.dy + bannerDrop)
      ..lineTo(lt.offset.dx, lt.offset.dy + bannerDrop)
      ..close();

    canvas.drawPath(banner, Paint()..color = AppColors.primaryAccent);
    canvas.drawPath(
      banner,
      Paint()
        ..color = AppColors.goldAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Napis "META / FINISH" na belce bramy
    final Offset center = Offset(
      (lt.offset.dx + rt.offset.dx) * 0.5,
      (lt.offset.dy + rt.offset.dy) * 0.5 + bannerDrop * 0.5,
    );
    final double fontSize = (bannerDrop * 0.45).clamp(8.0, 16.0);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'FINISH • META',
        style: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width * 0.5, tp.height * 0.5));
  }

  void _drawPhotographer3D(
    Canvas canvas,
    _ProjectedPoint proj,
    Photographer3D p,
  ) {
    final double s = proj.scale.clamp(4.0, 48.0);
    final double bodyH =
        (p.stance == PhotographerStance.kneelingTelephoto ? 1.1 : 1.65) * s;
    final double bodyW = 0.52 * s;

    // Podest jeśli stoi na podwyższeniu
    if (p.stance == PhotographerStance.elevatedPlatform) {
      canvas.drawRect(
        Rect.fromCenter(
          center: proj.offset + Offset(0, 0.25 * s),
          width: bodyW * 1.6,
          height: 0.45 * s,
        ),
        Paint()..color = AppColors.cardBorder,
      );
    }

    // Tułów w kamizelce prasowej
    final RRect torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        proj.offset.dx - bodyW * 0.5,
        proj.offset.dy - bodyH,
        bodyW,
        bodyH * 0.68,
      ),
      Radius.circular(0.12 * s),
    );
    canvas.drawRRect(torso, Paint()..color = p.vestColor);

    // Głowa
    final Offset headCenter =
        Offset(proj.offset.dx, proj.offset.dy - bodyH - 0.16 * s);
    canvas.drawCircle(
      headCenter,
      (0.18 * s).clamp(2.0, 10.0),
      Paint()..color = const Color(0xFFE5C4A1),
    );

    // Teleobiektyw aparatu skierowany w stronę mety
    final double lensDir = p.yawAngleRad >= 0 ? -1.0 : 1.0;
    final Offset camStart =
        Offset(proj.offset.dx, proj.offset.dy - bodyH * 0.88);
    final Offset camEnd = camStart + Offset(lensDir * 0.42 * s, 0.05 * s);
    canvas.drawLine(
      camStart,
      camEnd,
      Paint()
        ..color = const Color(0xFF111318)
        ..strokeWidth = (0.14 * s).clamp(2.0, 7.0)
        ..strokeCap = StrokeCap.round,
    );

    // Delikatna poświata na obiektywie przy świeżym błysku
    if (p.lastFlashIntensity > 0.05) {
      canvas.drawCircle(
        camEnd,
        (0.28 * s).clamp(3.0, 14.0),
        Paint()
          ..color = Colors.white.withValues(alpha: p.lastFlashIntensity * 0.85),
      );
    }
  }

  void _drawSoigneur3D(
    Canvas canvas,
    _ProjectedPoint proj,
    Soigneur3D sgn,
  ) {
    final double s = proj.scale.clamp(4.0, 48.0);
    final double bodyH = 1.72 * s;
    final double bodyW = 0.54 * s;

    // Kurtka opiekuna drużyny
    final RRect torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        proj.offset.dx - bodyW * 0.5,
        proj.offset.dy - bodyH,
        bodyW,
        bodyH * 0.65,
      ),
      Radius.circular(0.12 * s),
    );
    canvas.drawRRect(torso, Paint()..color = sgn.jacketColor);

    // Głowa
    canvas.drawCircle(
      Offset(proj.offset.dx, proj.offset.dy - bodyH - 0.18 * s),
      (0.18 * s).clamp(2.0, 10.0),
      Paint()..color = const Color(0xFFE2BFA0),
    );

    // Wyciągnięte ramię z bidonem / musette / ręcznikiem z lodem
    final double wave = math.sin(sgn.wavePhase) * 0.12 * s;
    final Offset handPos = Offset(
      proj.offset.dx + (sgn.position.x < 0 ? 0.38 * s : -0.38 * s),
      proj.offset.dy - bodyH * 0.72 + wave,
    );
    canvas.drawLine(
      Offset(proj.offset.dx, proj.offset.dy - bodyH * 0.82),
      handPos,
      Paint()
        ..color = sgn.jacketColor
        ..strokeWidth = (0.11 * s).clamp(1.5, 5.0)
        ..strokeCap = StrokeCap.round,
    );

    // Rekwizyt w dłoni opiekuna
    final Color propColor = switch (sgn.role) {
      SoigneurActionRole.holdingBidon => AppColors.cyanAccent,
      SoigneurActionRole.holdingMusette => AppColors.goldAccent,
      SoigneurActionRole.holdingIceTowel => AppColors.textPrimary,
      SoigneurActionRole.catchingRider => AppColors.statusSuccess,
    };
    canvas.drawCircle(
      handPos,
      (0.13 * s).clamp(2.0, 6.5),
      Paint()..color = propColor,
    );
  }

  void _drawRider3D(
    Canvas canvas,
    _ProjectedPoint proj,
    FinishZoneRider3D rider,
  ) {
    final double s = proj.scale.clamp(5.0, 56.0);
    final Offset base = proj.offset;

    // Cień pod rowerem
    canvas.drawOval(
      Rect.fromCenter(center: base, width: 0.75 * s, height: 0.22 * s),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Koła i rama
    final double wheelR = (0.34 * s).clamp(3.0, 18.0);
    canvas.drawCircle(
      base - Offset(0, wheelR),
      wheelR,
      Paint()
        ..color = const Color(0xFF0F1115)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (0.07 * s).clamp(1.5, 4.0),
    );

    // Sylwetka kolarza
    final double torsoH = 0.88 * s;
    final double torsoW = 0.48 * s;
    final Offset hip = base - Offset(0, wheelR * 1.7);
    final Offset shoulder = hip - Offset(0, torsoH * 0.75);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: (hip + shoulder) * 0.5,
          width: torsoW,
          height: torsoH,
        ),
        Radius.circular(0.14 * s),
      ),
      Paint()..color = rider.jerseyColor,
    );

    // Kask
    canvas.drawCircle(
      shoulder - Offset(0, 0.22 * s),
      (0.19 * s).clamp(2.5, 11.0),
      Paint()..color = rider.secondaryColor,
    );

    // Gest zwycięstwa (uniesione ręce) przy linii mety
    if (rider.isSaluting) {
      final Paint armPaint = Paint()
        ..color = rider.jerseyColor
        ..strokeWidth = (0.11 * s).clamp(1.8, 5.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        shoulder + Offset(-torsoW * 0.45, 0),
        shoulder + Offset(-torsoW * 0.85, -0.58 * s),
        armPaint,
      );
      canvas.drawLine(
        shoulder + Offset(torsoW * 0.45, 0),
        shoulder + Offset(torsoW * 0.85, -0.58 * s),
        armPaint,
      );
    }
  }

  void _drawConfetti3D(
    Canvas canvas,
    _ProjectedPoint proj,
    ConfettiParticle3D conf,
  ) {
    final double s = proj.scale.clamp(6.0, 48.0);
    final double w = (conf.widthMeters * s).clamp(2.2, 14.0);
    final double h =
        (conf.heightMeters * s * (0.35 + 0.65 * math.cos(conf.pitchRad).abs()))
            .clamp(1.5, 10.0);

    canvas.save();
    canvas.translate(proj.offset.dx, proj.offset.dy);
    canvas.rotate(conf.rollRad);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      Paint()..color = conf.color.withValues(alpha: conf.isSettled ? 0.75 : 0.95),
    );
    canvas.restore();
  }

  void _drawFlashBurst3D(
    Canvas canvas,
    _ProjectedPoint proj,
    CameraFlashBurst3D flash,
  ) {
    final double alpha = flash.currentIntensity.clamp(0.0, 1.0);
    if (alpha <= 0.02) return;
    final double radius = (proj.scale * 1.15).clamp(12.0, 72.0);
    final Rect rect = Rect.fromCircle(center: proj.offset, radius: radius);

    final Paint burstPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: alpha * 0.95),
          AppColors.goldAccent.withValues(alpha: alpha * 0.45),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawCircle(proj.offset, radius, burstPaint);
  }

  @override
  bool shouldRepaint(
          covariant FinishLineConfettiAndPhotographers3dPainter oldDelegate) =>
      true;
}

// =============================================================================
// 5. PRODUKCYJNY WIDŻET INTERAKTYWNY 3D + PANEL KONTROLNY
// =============================================================================

/// Interaktywna scena 3D strefy mety: fotoreporterzy, konfetti i strefa opiekunów.
class FinishLineConfettiAndPhotographers3dPanel extends StatefulWidget {
  final FinishLineZoneConfig initialConfig;
  final FinishLineCameraMode initialCameraMode;
  final bool autoPlay;

  const FinishLineConfettiAndPhotographers3dPanel({
    super.key,
    this.initialConfig = const FinishLineZoneConfig(),
    this.initialCameraMode = FinishLineCameraMode.frontTelephoto,
    this.autoPlay = true,
  });

  @override
  State<FinishLineConfettiAndPhotographers3dPanel> createState() =>
      _FinishLineConfettiAndPhotographers3dPanelState();
}

class _FinishLineConfettiAndPhotographers3dPanelState
    extends State<FinishLineConfettiAndPhotographers3dPanel>
    with SingleTickerProviderStateMixin {
  late final FinishLineConfettiAndPhotographers3dEngine _engine;
  late final AnimationController _ticker;
  late FinishLineCameraMode _cameraMode;
  late FinishConfettiTheme _confettiTheme;
  late double _windMs;
  bool _isPlaying = true;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _engine = FinishLineConfettiAndPhotographers3dEngine(
      config: widget.initialConfig,
    );
    _cameraMode = widget.initialCameraMode;
    _confettiTheme = widget.initialConfig.confettiTheme;
    _windMs = widget.initialConfig.lateralWindMs;
    _isPlaying = widget.autoPlay;

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onAnimationTick);

    if (_isPlaying) {
      _ticker.repeat();
    }
  }

  void _onAnimationTick() {
    if (!_isPlaying) return;
    final Duration now = _ticker.lastElapsedDuration ?? Duration.zero;
    double dt = (now - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = now;
    if (dt <= 0.0 || dt > 0.1) {
      dt = 1.0 / 60.0;
    }
    _engine.step(dt);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.removeListener(_onAnimationTick);
    _ticker.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _lastTick = Duration.zero;
        _ticker.repeat();
      } else {
        _ticker.stop();
      }
    });
  }

  void _fireConfetti() {
    _engine.triggerConfettiCannonBurst(count: 110);
    setState(() {});
  }

  void _fireFlashes() {
    _engine.triggerPhotographerFlashVolley(bursts: 6);
    setState(() {});
  }

  void _selectConfettiTheme(FinishConfettiTheme theme) {
    setState(() {
      _confettiTheme = theme;
      _engine.updateConfig(_engine.config.copyWith(confettiTheme: theme));
      _engine.triggerConfettiCannonBurst(count: 80);
    });
  }

  void _updateWind(double nextWind) {
    setState(() {
      _windMs = nextWind;
      _engine.updateConfig(_engine.config.copyWith(lateralWindMs: nextWind));
    });
  }

  @override
  Widget build(BuildContext context) {
    final FinishLineZoneTelemetry telemetry = _engine.telemetry;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCompact = constraints.maxWidth < 720;
          final bool isDesktopWide = constraints.maxWidth >= 1120;

          if (isDesktopWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: _buildViewport3D(telemetry, isCompact: false),
                ),
                Container(width: 1.0, color: AppTheme.borderColor),
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildControlsAndTelemetry(telemetry),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: isCompact ? 260 : 340,
                  child: _buildViewport3D(telemetry, isCompact: isCompact),
                ),
                Container(height: 1.0, color: AppTheme.borderColor),
                Padding(
                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                  child: _buildControlsAndTelemetry(telemetry),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewport3D(
    FinishLineZoneTelemetry telemetry, {
    required bool isCompact,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(
          painter: FinishLineConfettiAndPhotographers3dPainter(
            engine: _engine,
            cameraMode: _cameraMode,
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.flag_rounded,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCompact
                          ? 'META 3D'
                          : _engine.config.stageTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'Lider: ${telemetry.winnerDistanceMeters >= 0 ? '+' : ''}${telemetry.winnerDistanceMeters.toStringAsFixed(1)} m',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyanAccent,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlsAndTelemetry(FinishLineZoneTelemetry telemetry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'STREFY METY 3D',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FinishLineCameraMode.values.map((FinishLineCameraMode mode) {
            final bool selected = mode == _cameraMode;
            return _InteractiveActionChip(
              label: mode.shortLabel,
              icon: mode.icon,
              selected: selected,
              onPressed: () {
                setState(() => _cameraMode = mode);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _InteractivePrimaryButton(
                label: 'Armata Konfetti',
                icon: Icons.celebration_rounded,
                accentColor: AppColors.goldAccent,
                onPressed: _fireConfetti,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InteractivePrimaryButton(
                label: 'Flesze Prasy',
                icon: Icons.flash_on_rounded,
                accentColor: AppColors.primaryAccent,
                onPressed: _fireFlashes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _InteractivePrimaryButton(
          label: _isPlaying ? 'Pauza Symulacji' : 'Wznów Symulację',
          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          accentColor: AppColors.surfaceLight,
          textColor: AppColors.textPrimary,
          onPressed: _togglePlayPause,
        ),
        const SizedBox(height: 16),
        const Text(
          'MOTYW KONFETTI',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FinishConfettiTheme.values.map((FinishConfettiTheme theme) {
            return _InteractiveActionChip(
              label: theme.labelPl,
              icon: Icons.palette_rounded,
              selected: theme == _confettiTheme,
              onPressed: () => _selectConfettiTheme(theme),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Expanded(
              child: Text(
                'Wiatr boczny na mecie',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_windMs.toStringAsFixed(1)} m/s',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentBlue,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.goldAccent,
            overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
          ),
          child: Slider(
            value: _windMs,
            min: -6.0,
            max: 6.0,
            divisions: 24,
            onChanged: _updateWind,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: <Widget>[
              _TelemetryRow(
                label: 'Fotoreporterzy w boksie',
                value: '${telemetry.photographersCount}',
                valueColor: AppColors.textPrimary,
              ),
              const SizedBox(height: 6),
              _TelemetryRow(
                label: 'Błyski fleszy (aktywne / suma)',
                value:
                    '${telemetry.activeFlashesCount} / ${telemetry.totalFlashesTriggered}',
                valueColor: AppColors.goldAccent,
              ),
              const SizedBox(height: 6),
              _TelemetryRow(
                label: 'Konfetti (w locie / na asfalcie)',
                value:
                    '${telemetry.activeConfettiCount} / ${telemetry.settledConfettiCount}',
                valueColor: AppColors.cyanAccent,
              ),
              const SizedBox(height: 6),
              _TelemetryRow(
                label: 'Opiekunowie (strefa +38..115 m)',
                value: '${telemetry.soigneursCount}',
                valueColor: AppColors.statusSuccess,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  const _InteractiveActionChip({
    required this.label,
    required this.icon,
    required this.selected,
    this.onPressed,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.primaryAccent
            : _pressed
                ? AppColors.surfaceLight
                : _hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.surface;
    final Color borderColor = _focused
        ? AppColors.cyanAccent
        : widget.selected
            ? AppColors.goldAccent
            : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool h) => setState(() => _hovered = h),
      onShowFocusHighlight: (bool f) => setState(() => _focused = f),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 14,
                color: !enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : widget.selected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: !enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractivePrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const _InteractivePrimaryButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.textColor = const Color(0xFF0F1115),
    this.onPressed,
  });

  @override
  State<_InteractivePrimaryButton> createState() =>
      _InteractivePrimaryButtonState();
}

class _InteractivePrimaryButtonState extends State<_InteractivePrimaryButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color effectiveBg = !enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.78)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.92)
                : widget.accentColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (bool h) => setState(() => _hovered = h),
      onShowFocusHighlight: (bool f) => setState(() => _focused = f),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.cyanAccent : AppTheme.borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 16,
                color: !enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : widget.textColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: !enabled
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : widget.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
