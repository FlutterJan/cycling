// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/esports/uci_cycling_esports_world_model.dart';

// =============================================================================
// 1. PRESETY ŚWIATÓW E-SPORTS, TRYBY KAMERY I KONFIGURACJA RENDERERA 3D
// =============================================================================

/// Preset wizualny neonowo-szklanego świata UCI Cycling Esports.
enum EsportsCyberWorldPreset {
  cyberVelodrome(
    theme: VirtualWorldTheme.cyberVelodrome,
    labelPl: 'Cyber-Welodrom Neon',
    shortTag: 'CYBER-VELO',
    primaryNeon: AppColors.cyanAccent,
    secondaryNeon: AppColors.accentBlue,
    accentGold: AppColors.goldAccent,
    trackWidthMeters: 8.4,
    defaultBankingRadians: 0.36,
    glassOpacity: 0.24,
  ),
  glasgowCircuit(
    theme: VirtualWorldTheme.glasgowUciCircuit,
    labelPl: 'Glasgow UCI Virtual',
    shortTag: 'GLASGOW',
    primaryNeon: AppColors.accentBlue,
    secondaryNeon: AppColors.statusSuccess,
    accentGold: AppColors.goldAccent,
    trackWidthMeters: 7.6,
    defaultBankingRadians: 0.08,
    glassOpacity: 0.20,
  ),
  watopiaAlps(
    theme: VirtualWorldTheme.watopiaAlps,
    labelPl: 'Alpy Wirtualne',
    shortTag: 'WATOPIA',
    primaryNeon: AppColors.statusSuccess,
    secondaryNeon: AppColors.cyanAccent,
    accentGold: AppColors.goldAccent,
    trackWidthMeters: 7.2,
    defaultBankingRadians: 0.04,
    glassOpacity: 0.18,
  ),
  abuDhabiLoop(
    theme: VirtualWorldTheme.abuDhabiDesertLoop,
    labelPl: 'Abu Dhabi Yas Marina',
    shortTag: 'YAS MARINA',
    primaryNeon: AppColors.goldAccent,
    secondaryNeon: AppColors.amberWarning,
    accentGold: AppColors.cyanAccent,
    trackWidthMeters: 9.0,
    defaultBankingRadians: 0.10,
    glassOpacity: 0.26,
  ),
  tokyoNeonCrit(
    theme: VirtualWorldTheme.tokyoNeonCrit,
    labelPl: 'Tokio Neon Crit',
    shortTag: 'TOKIO CRIT',
    primaryNeon: AppColors.powerZone7,
    secondaryNeon: AppColors.cyanAccent,
    accentGold: AppColors.goldAccent,
    trackWidthMeters: 8.0,
    defaultBankingRadians: 0.14,
    glassOpacity: 0.28,
  );

  final VirtualWorldTheme theme;
  final String labelPl;
  final String shortTag;
  final Color primaryNeon;
  final Color secondaryNeon;
  final Color accentGold;
  final double trackWidthMeters;
  final double defaultBankingRadians;
  final double glassOpacity;

  const EsportsCyberWorldPreset({
    required this.theme,
    required this.labelPl,
    required this.shortTag,
    required this.primaryNeon,
    required this.secondaryNeon,
    required this.accentGold,
    required this.trackWidthMeters,
    required this.defaultBankingRadians,
    required this.glassOpacity,
  });

  static EsportsCyberWorldPreset fromTheme(VirtualWorldTheme theme) {
    return EsportsCyberWorldPreset.values.firstWhere(
      (preset) => preset.theme == theme,
      orElse: () => EsportsCyberWorldPreset.cyberVelodrome,
    );
  }
}

/// Tryb kamery 3D w neonowo-szklanym świecie e-Sports.
enum EsportsCyberCameraMode {
  chaseCam(
    labelPl: 'Pościgowa (Chase)',
    shortTag: 'CHASE',
    icon: Icons.videocam_rounded,
  ),
  helicamDrone(
    labelPl: 'Dron TV (Helicam)',
    shortTag: 'DRONE',
    icon: Icons.flight_rounded,
  ),
  tracksideNeon(
    labelPl: 'Torowa (Trackside)',
    shortTag: 'TRACK',
    icon: Icons.stadium_rounded,
  ),
  powerUpOrbit(
    labelPl: 'Orbita Power-Up',
    shortTag: 'ORBIT',
    icon: Icons.auto_awesome_rounded,
  );

  final String labelPl;
  final String shortTag;
  final IconData icon;

  const EsportsCyberCameraMode({
    required this.labelPl,
    required this.shortTag,
    required this.icon,
  });
}

/// Konfiguracja renderera 3D e-Sports.
@immutable
class EsportsCyberVelodromeConfig {
  final EsportsCyberWorldPreset worldPreset;
  final EsportsCyberCameraMode cameraMode;
  final bool showPowerUpHolograms;
  final bool showWkgBars;
  final bool showGlassRoadReflections;
  final bool showEliminationLaser;
  final bool showCyberGridSky;
  final double hologramScanSpeed;
  final double fovDegrees;
  final double drawDistanceMeters;

  const EsportsCyberVelodromeConfig({
    this.worldPreset = EsportsCyberWorldPreset.cyberVelodrome,
    this.cameraMode = EsportsCyberCameraMode.chaseCam,
    this.showPowerUpHolograms = true,
    this.showWkgBars = true,
    this.showGlassRoadReflections = true,
    this.showEliminationLaser = true,
    this.showCyberGridSky = true,
    this.hologramScanSpeed = 1.8,
    this.fovDegrees = 58.0,
    this.drawDistanceMeters = 180.0,
  });

  EsportsCyberVelodromeConfig copyWith({
    EsportsCyberWorldPreset? worldPreset,
    EsportsCyberCameraMode? cameraMode,
    bool? showPowerUpHolograms,
    bool? showWkgBars,
    bool? showGlassRoadReflections,
    bool? showEliminationLaser,
    bool? showCyberGridSky,
    double? hologramScanSpeed,
    double? fovDegrees,
    double? drawDistanceMeters,
  }) {
    return EsportsCyberVelodromeConfig(
      worldPreset: worldPreset ?? this.worldPreset,
      cameraMode: cameraMode ?? this.cameraMode,
      showPowerUpHolograms: showPowerUpHolograms ?? this.showPowerUpHolograms,
      showWkgBars: showWkgBars ?? this.showWkgBars,
      showGlassRoadReflections:
          showGlassRoadReflections ?? this.showGlassRoadReflections,
      showEliminationLaser: showEliminationLaser ?? this.showEliminationLaser,
      showCyberGridSky: showCyberGridSky ?? this.showCyberGridSky,
      hologramScanSpeed: hologramScanSpeed ?? this.hologramScanSpeed,
      fovDegrees: fovDegrees ?? this.fovDegrees,
      drawDistanceMeters: drawDistanceMeters ?? this.drawDistanceMeters,
    );
  }
}

// =============================================================================
// 2. MODELE SCENY 3D: HOLOGRAMY POWER-UPÓW, KOLARZE I SŁUPKI W/KG
// =============================================================================

/// Trójwymiarowy hologram Power-Upa unoszący się nad szklanym torem e-Sports.
@immutable
class EsportsPowerUpHologram3D {
  final String id;
  final EsportsPowerUpType powerUpType;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final double heightAboveTrackMeters;
  final double rotationRadians;
  final double pulsePhase;
  final bool isCollected;
  final String? activeForRiderId;

  const EsportsPowerUpHologram3D({
    required this.id,
    required this.powerUpType,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    this.elevationMeters = 0.0,
    this.heightAboveTrackMeters = 2.1,
    this.rotationRadians = 0.0,
    this.pulsePhase = 0.0,
    this.isCollected = false,
    this.activeForRiderId,
  });

  EsportsPowerUpHologram3D copyWith({
    String? id,
    EsportsPowerUpType? powerUpType,
    double? distanceMeters,
    double? lateralOffsetMeters,
    double? elevationMeters,
    double? heightAboveTrackMeters,
    double? rotationRadians,
    double? pulsePhase,
    bool? isCollected,
    String? activeForRiderId,
  }) {
    return EsportsPowerUpHologram3D(
      id: id ?? this.id,
      powerUpType: powerUpType ?? this.powerUpType,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      heightAboveTrackMeters:
          heightAboveTrackMeters ?? this.heightAboveTrackMeters,
      rotationRadians: rotationRadians ?? this.rotationRadians,
      pulsePhase: pulsePhase ?? this.pulsePhase,
      isCollected: isCollected ?? this.isCollected,
      activeForRiderId: activeForRiderId ?? this.activeForRiderId,
    );
  }
}

/// Awatar kolarza 3D w świecie e-Sports wraz z telemetrią $\text{W/kg}$ i Power-Upem.
@immutable
class EsportsCyberRider3D {
  final String riderId;
  final String riderName;
  final String teamTag;
  final double distanceMeters;
  final double lateralOffsetMeters;
  final double elevationMeters;
  final double speedMs;
  final double wattsPerKg;
  final double powerWatts;
  final int heartRateBpm;
  final int cadenceRpm;
  final EsportsPowerUpType? activePowerUp;
  final EsportsPowerUpSlotState powerUpSlotState;
  final double powerUpRemainingSeconds;
  final bool isPlayerRider;
  final bool isEliminationDanger;
  final EsportsAvatarVerdict verdict;
  final Color jerseyColor;
  final Color neonTrailColor;

  const EsportsCyberRider3D({
    required this.riderId,
    required this.riderName,
    required this.teamTag,
    required this.distanceMeters,
    required this.lateralOffsetMeters,
    this.elevationMeters = 0.0,
    required this.speedMs,
    required this.wattsPerKg,
    required this.powerWatts,
    this.heartRateBpm = 172,
    this.cadenceRpm = 96,
    this.activePowerUp,
    this.powerUpSlotState = EsportsPowerUpSlotState.empty,
    this.powerUpRemainingSeconds = 0.0,
    this.isPlayerRider = false,
    this.isEliminationDanger = false,
    this.verdict = EsportsAvatarVerdict.active,
    this.jerseyColor = AppColors.accentBlue,
    this.neonTrailColor = AppColors.cyanAccent,
  });

  EsportsCyberRider3D copyWith({
    String? riderId,
    String? riderName,
    String? teamTag,
    double? distanceMeters,
    double? lateralOffsetMeters,
    double? elevationMeters,
    double? speedMs,
    double? wattsPerKg,
    double? powerWatts,
    int? heartRateBpm,
    int? cadenceRpm,
    EsportsPowerUpType? activePowerUp,
    EsportsPowerUpSlotState? powerUpSlotState,
    double? powerUpRemainingSeconds,
    bool? isPlayerRider,
    bool? isEliminationDanger,
    EsportsAvatarVerdict? verdict,
    Color? jerseyColor,
    Color? neonTrailColor,
  }) {
    return EsportsCyberRider3D(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      teamTag: teamTag ?? this.teamTag,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      lateralOffsetMeters: lateralOffsetMeters ?? this.lateralOffsetMeters,
      elevationMeters: elevationMeters ?? this.elevationMeters,
      speedMs: speedMs ?? this.speedMs,
      wattsPerKg: wattsPerKg ?? this.wattsPerKg,
      powerWatts: powerWatts ?? this.powerWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      activePowerUp: activePowerUp ?? this.activePowerUp,
      powerUpSlotState: powerUpSlotState ?? this.powerUpSlotState,
      powerUpRemainingSeconds:
          powerUpRemainingSeconds ?? this.powerUpRemainingSeconds,
      isPlayerRider: isPlayerRider ?? this.isPlayerRider,
      isEliminationDanger: isEliminationDanger ?? this.isEliminationDanger,
      verdict: verdict ?? this.verdict,
      jerseyColor: jerseyColor ?? this.jerseyColor,
      neonTrailColor: neonTrailColor ?? this.neonTrailColor,
    );
  }
}

/// Neonowo-szklana brama lub strefa eliminacji na trasie 3D.
@immutable
class EsportsCyberGate3D {
  final String id;
  final String label;
  final double distanceMeters;
  final double elevationMeters;
  final Color gateColor;
  final bool isEliminationGate;

  const EsportsCyberGate3D({
    required this.id,
    required this.label,
    required this.distanceMeters,
    this.elevationMeters = 0.0,
    this.gateColor = AppColors.cyanAccent,
    this.isEliminationGate = false,
  });
}

/// Dane wejściowe pojedynczej klatki renderera 3D e-Sports.
@immutable
class EsportsCyberVelodromeFrameInput {
  final EsportsCyberWorldPreset worldPreset;
  final EsportsCyberCameraMode cameraMode;
  final double playerDistanceMeters;
  final double elapsedSeconds;
  final double eliminationCountdownSeconds;
  final List<EsportsCyberRider3D> riders;
  final List<EsportsPowerUpHologram3D> powerUpHolograms;
  final List<EsportsCyberGate3D> gates;
  final double trackGradientPercent;
  final double trackBankingRadians;
  final double trackCurvatureRadius;

  const EsportsCyberVelodromeFrameInput({
    this.worldPreset = EsportsCyberWorldPreset.cyberVelodrome,
    this.cameraMode = EsportsCyberCameraMode.chaseCam,
    this.playerDistanceMeters = 0.0,
    this.elapsedSeconds = 0.0,
    this.eliminationCountdownSeconds = 45.0,
    this.riders = const [],
    this.powerUpHolograms = const [],
    this.gates = const [],
    this.trackGradientPercent = 0.0,
    this.trackBankingRadians = 0.25,
    this.trackCurvatureRadius = 180.0,
  });
}

/// Zbiorcza telemetria wyrenderowanej klatki 3D e-Sports.
@immutable
class EsportsCyberVelodromeTelemetry {
  final int visibleRidersCount;
  final int visibleHologramsCount;
  final double averageWkg;
  final double leaderWkg;
  final double playerWkg;
  final int activePowerUpsCount;
  final int eliminationDangerCount;
  final int projectedDrawCalls;
  final double frameRenderTimeMs;

  const EsportsCyberVelodromeTelemetry({
    required this.visibleRidersCount,
    required this.visibleHologramsCount,
    required this.averageWkg,
    required this.leaderWkg,
    required this.playerWkg,
    required this.activePowerUpsCount,
    required this.eliminationDangerCount,
    required this.projectedDrawCalls,
    required this.frameRenderTimeMs,
  });

  static const EsportsCyberVelodromeTelemetry empty =
      EsportsCyberVelodromeTelemetry(
    visibleRidersCount: 0,
    visibleHologramsCount: 0,
    averageWkg: 0.0,
    leaderWkg: 0.0,
    playerWkg: 0.0,
    activePowerUpsCount: 0,
    eliminationDangerCount: 0,
    projectedDrawCalls: 0,
    frameRenderTimeMs: 0.0,
  );
}

/// Rzutowany na ekran obszar interakcji z hologramem Power-Upa.
@immutable
class ProjectedPowerUpHitbox {
  final Rect rect;
  final EsportsPowerUpHologram3D hologram;
  final double depthMeters;

  const ProjectedPowerUpHitbox({
    required this.rect,
    required this.hologram,
    required this.depthMeters,
  });
}

/// Rzutowany na ekran słupek $\text{W/kg}$ przypisany do kolarza.
@immutable
class ProjectedRiderWkgBar {
  final EsportsCyberRider3D rider;
  final Offset screenAnchor;
  final double barHeightPx;
  final double scale;
  final Color barColor;
  final Rect hitbox;

  const ProjectedRiderWkgBar({
    required this.rider,
    required this.screenAnchor,
    required this.barHeightPx,
    required this.scale,
    required this.barColor,
    required this.hitbox,
  });
}

/// Wynik rzutowania punktu 3D na powierzchnię ekranu 2D.
@immutable
class CyberProjectedPoint {
  final Offset offset;
  final double depthMeters;
  final double scale;
  final bool isVisible;

  const CyberProjectedPoint({
    required this.offset,
    required this.depthMeters,
    required this.scale,
    required this.isVisible,
  });

  static const CyberProjectedPoint hidden = CyberProjectedPoint(
    offset: Offset.zero,
    depthMeters: -1.0,
    scale: 0.0,
    isVisible: false,
  );
}

// =============================================================================
// 3. SILNIK MATEMATYKI 3D I GENERATOR SCENY E-SPORTS
// =============================================================================

/// Silnik obliczeń 3D, kolorowania słupków $\text{W/kg}$ i hologramów Power-Upów.
class EsportsCyberVelodromeAndHologram3dEngine {
  const EsportsCyberVelodromeAndHologram3dEngine();

  /// Zwraca kolor neonowego słupka na podstawie intensywności $\text{W/kg}$.
  static Color computeWkgBarColor(double wattsPerKg) {
    if (wattsPerKg >= 6.5) {
      return AppColors.powerZone7; // Neuromuscular / Watt Bomb
    }
    if (wattsPerKg >= 5.6) {
      return AppColors.crimsonAlert; // Beztlenowy atak Z6
    }
    if (wattsPerKg >= 4.8) {
      return AppColors.amberWarning; // VO2Max Z5
    }
    if (wattsPerKg >= 4.0) {
      return AppColors.goldAccent; // Próg FTP Z4
    }
    if (wattsPerKg >= 3.1) {
      return AppColors.statusSuccess; // Tempo Z3
    }
    return AppColors.cyanAccent; // Baza / Draft Z1-Z2
  }

  /// Zwraca kolor oraz ikonę hologramu dla danego typu Power-Upa e-Sports.
  static Color computePowerUpHologramColor(EsportsPowerUpType type) {
    switch (type) {
      case EsportsPowerUpType.aeroHelmet:
        return AppColors.cyanAccent;
      case EsportsPowerUpType.featherweight:
        return AppColors.statusSuccess;
      case EsportsPowerUpType.burrito:
        return AppColors.amberWarning;
      case EsportsPowerUpType.draftBoost:
        return AppColors.accentBlue;
      case EsportsPowerUpType.steamroller:
        return AppColors.powerZone7;
    }
  }

  /// Krótki kod Power-Upa wyświetlany na 3D hologramie.
  static String powerUpShortCode(EsportsPowerUpType type) {
    switch (type) {
      case EsportsPowerUpType.aeroHelmet:
        return 'AERO';
      case EsportsPowerUpType.featherweight:
        return 'FEATHER';
      case EsportsPowerUpType.burrito:
        return 'BURRITO';
      case EsportsPowerUpType.draftBoost:
        return 'DRAFT+';
      case EsportsPowerUpType.steamroller:
        return 'STEAM';
    }
  }

  /// Wylicza wysokość toru na danym dystansie z uwzględnieniem nachylenia i krzywizny.
  static double trackElevationAt(
    double distanceMeters,
    EsportsCyberVelodromeFrameInput input,
  ) {
    final double delta = distanceMeters - input.playerDistanceMeters;
    final double slopeRise = delta * (input.trackGradientPercent / 100.0);
    final double undulation = math.sin(distanceMeters * 0.035) * 0.45;
    return slopeRise + undulation;
  }

  /// Wylicza boczne przesunięcie osi toru wynikające z promienia zakrętu.
  static double trackCenterXAt(
    double distanceMeters,
    EsportsCyberVelodromeFrameInput input,
  ) {
    final double delta = distanceMeters - input.playerDistanceMeters;
    final double radius = input.trackCurvatureRadius.abs() < 25.0
        ? 25.0
        : input.trackCurvatureRadius;
    final double curveSign = input.trackCurvatureRadius >= 0 ? 1.0 : -1.0;
    return curveSign * (delta * delta) / (2.0 * radius);
  }

  /// Wyznacza pozycję i punkt patrzenia kamery 3D w zależności od trybu.
  static ({Vector3 position, Vector3 target}) computeCameraRig({
    required EsportsCyberVelodromeFrameInput input,
    required EsportsCyberVelodromeConfig config,
  }) {
    final double playerDist = input.playerDistanceMeters;
    final double baseX = trackCenterXAt(playerDist, input);
    final double baseY = trackElevationAt(playerDist, input);

    switch (config.cameraMode) {
      case EsportsCyberCameraMode.chaseCam:
        return (
          position: Vector3(baseX - 0.6, baseY + 3.2, -9.2),
          target: Vector3(
            trackCenterXAt(playerDist + 26.0, input),
            trackElevationAt(playerDist + 26.0, input) + 1.1,
            26.0,
          ),
        );
      case EsportsCyberCameraMode.helicamDrone:
        return (
          position: Vector3(baseX + 11.5, baseY + 12.5, -14.0),
          target: Vector3(
            trackCenterXAt(playerDist + 20.0, input),
            trackElevationAt(playerDist + 20.0, input) + 0.8,
            20.0,
          ),
        );
      case EsportsCyberCameraMode.tracksideNeon:
        return (
          position: Vector3(baseX - 6.8, baseY + 1.75, 4.5),
          target: Vector3(
            trackCenterXAt(playerDist + 16.0, input),
            trackElevationAt(playerDist + 16.0, input) + 1.0,
            16.0,
          ),
        );
      case EsportsCyberCameraMode.powerUpOrbit:
        final double orbitAngle = input.elapsedSeconds * 0.75;
        return (
          position: Vector3(
            baseX + math.sin(orbitAngle) * 7.5,
            baseY + 4.4,
            -math.cos(orbitAngle) * 7.5 + 4.0,
          ),
          target: Vector3(
            trackCenterXAt(playerDist + 12.0, input),
            trackElevationAt(playerDist + 12.0, input) + 1.4,
            12.0,
          ),
        );
    }
  }

  /// Rzutuje punkt świata 3D (względem dystansu gracza) na płaszczyznę ekranu 2D.
  static CyberProjectedPoint projectWorldPoint({
    required Vector3 worldPoint,
    required Vector3 cameraPos,
    required Vector3 cameraTarget,
    required Size viewportSize,
    required double fovDegrees,
    double nearClip = 0.6,
    double farClip = 240.0,
  }) {
    final Vector3 forward = (cameraTarget - cameraPos);
    if (forward.length2 < 1e-6) {
      return CyberProjectedPoint.hidden;
    }
    forward.normalize();

    final Vector3 worldUp = Vector3(0.0, 1.0, 0.0);
    Vector3 right = forward.cross(worldUp);
    if (right.length2 < 1e-6) {
      right = Vector3(1.0, 0.0, 0.0);
    } else {
      right.normalize();
    }
    final Vector3 up = right.cross(forward)..normalize();

    final Vector3 rel = worldPoint - cameraPos;
    final double camZ = rel.dot(forward);
    if (camZ <= nearClip || camZ >= farClip) {
      return CyberProjectedPoint.hidden;
    }

    final double camX = rel.dot(right);
    final double camY = rel.dot(up);

    final double fovRad = fovDegrees * math.pi / 180.0;
    final double focalLength =
        (viewportSize.height * 0.5) / math.tan(fovRad * 0.5);

    final double scale = focalLength / camZ;
    final double screenX = viewportSize.width * 0.5 + camX * scale;
    final double screenY = viewportSize.height * 0.5 - camY * scale;

    if (screenX < -viewportSize.width * 0.6 ||
        screenX > viewportSize.width * 1.6 ||
        screenY < -viewportSize.height * 0.6 ||
        screenY > viewportSize.height * 1.6) {
      return CyberProjectedPoint.hidden;
    }

    return CyberProjectedPoint(
      offset: Offset(screenX, screenY),
      depthMeters: camZ,
      scale: scale,
      isVisible: true,
    );
  }

  /// Oblicza telemetrię klatki 3D na podstawie danych wejściowych.
  static EsportsCyberVelodromeTelemetry computeTelemetry({
    required EsportsCyberVelodromeFrameInput input,
    required EsportsCyberVelodromeConfig config,
    double frameRenderTimeMs = 1.4,
    int projectedDrawCalls = 0,
  }) {
    final activeRiders = input.riders
        .where((r) =>
            (r.distanceMeters - input.playerDistanceMeters).abs() <=
            config.drawDistanceMeters)
        .toList(growable: false);

    final visibleHolograms = input.powerUpHolograms
        .where((h) =>
            !h.isCollected &&
            h.distanceMeters - input.playerDistanceMeters >= -4.0 &&
            h.distanceMeters - input.playerDistanceMeters <=
                config.drawDistanceMeters)
        .toList(growable: false);

    double sumWkg = 0.0;
    double leaderWkg = 0.0;
    double playerWkg = 0.0;
    int activePowerUps = 0;
    int dangerCount = 0;

    for (final rider in activeRiders) {
      sumWkg += rider.wattsPerKg;
      if (rider.wattsPerKg > leaderWkg) {
        leaderWkg = rider.wattsPerKg;
      }
      if (rider.isPlayerRider) {
        playerWkg = rider.wattsPerKg;
      }
      if (rider.activePowerUp != null && rider.powerUpRemainingSeconds > 0.0) {
        activePowerUps++;
      }
      if (rider.isEliminationDanger) {
        dangerCount++;
      }
    }

    return EsportsCyberVelodromeTelemetry(
      visibleRidersCount: activeRiders.length,
      visibleHologramsCount: visibleHolograms.length,
      averageWkg: activeRiders.isEmpty ? 0.0 : sumWkg / activeRiders.length,
      leaderWkg: leaderWkg,
      playerWkg: playerWkg,
      activePowerUpsCount: activePowerUps,
      eliminationDangerCount: dangerCount,
      projectedDrawCalls: projectedDrawCalls,
      frameRenderTimeMs: frameRenderTimeMs,
    );
  }

  /// Tworzy realistyczną, dynamiczną klatkę demonstracyjną wyścigu e-Sports.
  static EsportsCyberVelodromeFrameInput buildDemoFrameInput({
    required double elapsedSeconds,
    EsportsCyberWorldPreset worldPreset = EsportsCyberWorldPreset.cyberVelodrome,
    EsportsCyberCameraMode cameraMode = EsportsCyberCameraMode.chaseCam,
    EsportsPowerUpType? activePlayerPowerUp,
    double activePowerUpRemainingSeconds = 0.0,
  }) {
    final double baseDist = 1200.0 + elapsedSeconds * 13.8;
    final double countdown = 60.0 - (elapsedSeconds % 60.0);

    final List<EsportsCyberRider3D> riders = [
      EsportsCyberRider3D(
        riderId: 'player-1',
        riderName: 'M. Kowalski',
        teamTag: 'PRO',
        distanceMeters: baseDist + 4.5,
        lateralOffsetMeters: -0.45 + math.sin(elapsedSeconds * 1.1) * 0.35,
        speedMs: 14.2,
        wattsPerKg: 5.85 + math.sin(elapsedSeconds * 2.1) * 0.45,
        powerWatts: 410 + math.sin(elapsedSeconds * 2.1) * 32,
        heartRateBpm: 181,
        cadenceRpm: 101,
        activePowerUp: activePlayerPowerUp,
        powerUpSlotState: activePlayerPowerUp != null
            ? EsportsPowerUpSlotState.active
            : EsportsPowerUpSlotState.ready,
        powerUpRemainingSeconds: activePowerUpRemainingSeconds,
        isPlayerRider: true,
        jerseyColor: AppColors.goldAccent,
        neonTrailColor: worldPreset.primaryNeon,
      ),
      EsportsCyberRider3D(
        riderId: 'rival-1',
        riderName: 'J. Vine',
        teamTag: 'UAE',
        distanceMeters: baseDist + 14.2 + math.cos(elapsedSeconds * 0.8) * 1.6,
        lateralOffsetMeters: 0.75,
        speedMs: 14.4,
        wattsPerKg: 6.22 + math.cos(elapsedSeconds * 1.6) * 0.35,
        powerWatts: 435,
        heartRateBpm: 184,
        cadenceRpm: 103,
        activePowerUp: EsportsPowerUpType.featherweight,
        powerUpSlotState: EsportsPowerUpSlotState.active,
        powerUpRemainingSeconds: 8.4,
        jerseyColor: AppColors.crimsonAlert,
        neonTrailColor: AppColors.crimsonAlert,
      ),
      EsportsCyberRider3D(
        riderId: 'rival-2',
        riderName: 'O. Osborn',
        teamTag: 'GBR',
        distanceMeters: baseDist + 10.6,
        lateralOffsetMeters: -1.35,
        speedMs: 14.1,
        wattsPerKg: 5.45,
        powerWatts: 382,
        heartRateBpm: 176,
        cadenceRpm: 98,
        activePowerUp: EsportsPowerUpType.aeroHelmet,
        powerUpSlotState: EsportsPowerUpSlotState.active,
        powerUpRemainingSeconds: 5.2,
        jerseyColor: AppColors.accentBlue,
        neonTrailColor: AppColors.accentBlue,
      ),
      EsportsCyberRider3D(
        riderId: 'rival-3',
        riderName: 'F. Vergallito',
        teamTag: 'ADC',
        distanceMeters: baseDist + 21.5,
        lateralOffsetMeters: 0.15,
        speedMs: 14.6,
        wattsPerKg: 6.65,
        powerWatts: 452,
        heartRateBpm: 187,
        cadenceRpm: 105,
        jerseyColor: AppColors.powerZone7,
        neonTrailColor: AppColors.powerZone7,
      ),
      EsportsCyberRider3D(
        riderId: 'rival-4',
        riderName: 'B. Bøe',
        teamTag: 'NOR',
        distanceMeters: baseDist + 0.8,
        lateralOffsetMeters: 1.95,
        speedMs: 13.7,
        wattsPerKg: 4.32,
        powerWatts: 308,
        heartRateBpm: 169,
        cadenceRpm: 92,
        isEliminationDanger: countdown < 18.0,
        jerseyColor: AppColors.statusSuccess,
        neonTrailColor: AppColors.amberWarning,
      ),
      EsportsCyberRider3D(
        riderId: 'rival-5',
        riderName: 'L. Cavagna',
        teamTag: 'FRA',
        distanceMeters: baseDist + 31.0,
        lateralOffsetMeters: -0.85,
        speedMs: 14.8,
        wattsPerKg: 5.95,
        powerWatts: 446,
        heartRateBpm: 182,
        cadenceRpm: 99,
        jerseyColor: AppColors.cyanAccent,
        neonTrailColor: AppColors.cyanAccent,
      ),
    ];

    final double holoBase = (baseDist / 45.0).floor() * 45.0 + 38.0;
    final List<EsportsPowerUpHologram3D> holograms = [
      EsportsPowerUpHologram3D(
        id: 'holo-aero',
        powerUpType: EsportsPowerUpType.aeroHelmet,
        distanceMeters: holoBase,
        lateralOffsetMeters: -1.1,
        rotationRadians: elapsedSeconds * 1.9,
        pulsePhase: elapsedSeconds * 3.1,
      ),
      EsportsPowerUpHologram3D(
        id: 'holo-feather',
        powerUpType: EsportsPowerUpType.featherweight,
        distanceMeters: holoBase + 26.0,
        lateralOffsetMeters: 1.35,
        rotationRadians: elapsedSeconds * 2.2 + 1.0,
        pulsePhase: elapsedSeconds * 2.8 + 0.7,
      ),
      EsportsPowerUpHologram3D(
        id: 'holo-burrito',
        powerUpType: EsportsPowerUpType.burrito,
        distanceMeters: holoBase + 54.0,
        lateralOffsetMeters: 0.0,
        rotationRadians: elapsedSeconds * 1.7 + 2.1,
        pulsePhase: elapsedSeconds * 3.4 + 1.4,
      ),
      EsportsPowerUpHologram3D(
        id: 'holo-steam',
        powerUpType: EsportsPowerUpType.steamroller,
        distanceMeters: holoBase + 84.0,
        lateralOffsetMeters: -1.6,
        rotationRadians: elapsedSeconds * 2.4 + 0.5,
        pulsePhase: elapsedSeconds * 2.9 + 2.1,
      ),
    ];

    final List<EsportsCyberGate3D> gates = [
      EsportsCyberGate3D(
        id: 'gate-sprint',
        label: 'NEON SPRINT +25 PTS',
        distanceMeters: holoBase + 36.0,
        gateColor: worldPreset.primaryNeon,
      ),
      EsportsCyberGate3D(
        id: 'gate-elim',
        label: 'STREFA ELIMINACJI 60s',
        distanceMeters: holoBase + 98.0,
        gateColor: AppColors.crimsonAlert,
        isEliminationGate: true,
      ),
    ];

    return EsportsCyberVelodromeFrameInput(
      worldPreset: worldPreset,
      cameraMode: cameraMode,
      playerDistanceMeters: baseDist,
      elapsedSeconds: elapsedSeconds,
      eliminationCountdownSeconds: countdown,
      riders: riders,
      powerUpHolograms: holograms,
      gates: gates,
      trackGradientPercent: math.sin(elapsedSeconds * 0.25) * 4.5,
      trackBankingRadians: worldPreset.defaultBankingRadians,
      trackCurvatureRadius: 150.0 + math.cos(elapsedSeconds * 0.18) * 60.0,
    );
  }
}

// =============================================================================
// 4. CUSTOM PAINTER: NEONOWO-SZKLANY ŚWIAT 3D, HOLOGRAMY I SŁUPKI W/KG
// =============================================================================

/// Painter 3D renderujący neonowo-szklany tor e-Sports, hologramy Power-Upów
/// oraz trójwymiarowe słupki $\text{W/kg}$ nad kolarzami.
class EsportsCyberVelodromeAndHologram3dPainter extends CustomPainter {
  final EsportsCyberVelodromeFrameInput input;
  final EsportsCyberVelodromeConfig config;
  final String? hoveredHologramId;
  final String? selectedHologramId;
  final String? hoveredRiderId;
  final String? selectedRiderId;
  final void Function(
    List<ProjectedPowerUpHitbox> hologramHitboxes,
    List<ProjectedRiderWkgBar> wkgBars,
    EsportsCyberVelodromeTelemetry telemetry,
  )? onFrameProjected;

  const EsportsCyberVelodromeAndHologram3dPainter({
    required this.input,
    required this.config,
    this.hoveredHologramId,
    this.selectedHologramId,
    this.hoveredRiderId,
    this.selectedRiderId,
    this.onFrameProjected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final stopwatch = Stopwatch()..start();
    int drawCalls = 0;

    final preset = config.worldPreset;
    final rig = EsportsCyberVelodromeAndHologram3dEngine.computeCameraRig(
      input: input,
      config: config,
    );

    // 1. Tło kosmiczno-neonowe
    _drawCyberBackground(canvas, size, preset);
    drawCalls++;

    // 2. Siatka nieba / kopuła cyber-welodromu
    if (config.showCyberGridSky) {
      drawCalls += _drawCyberSkyGrid(canvas, size, preset, rig);
    }

    // 3. Szklano-neonowa wstęga toru
    drawCalls += _drawNeonGlassTrack(canvas, size, preset, rig);

    // 4. Bramy neonowe i linia eliminacji
    drawCalls += _drawCyberGates(canvas, size, preset, rig);

    // 5. Zbieranie obiektów do sortowania głębokości (Malowanie od najdalszych)
    final List<_DepthSortableItem> depthQueue = [];
    final List<ProjectedPowerUpHitbox> hologramHitboxes = [];
    final List<ProjectedRiderWkgBar> wkgBars = [];

    for (final rider in input.riders) {
      final relZ = rider.distanceMeters - input.playerDistanceMeters;
      if (relZ < -5.0 || relZ > config.drawDistanceMeters) continue;

      final double roadX =
          EsportsCyberVelodromeAndHologram3dEngine.trackCenterXAt(
        rider.distanceMeters,
        input,
      );
      final double roadY =
          EsportsCyberVelodromeAndHologram3dEngine.trackElevationAt(
        rider.distanceMeters,
        input,
      );
      final double bankOffsetY =
          rider.lateralOffsetMeters.abs() * math.sin(input.trackBankingRadians) * 0.45;

      final worldPos = Vector3(
        roadX + rider.lateralOffsetMeters,
        roadY + rider.elevationMeters + bankOffsetY,
        relZ,
      );

      final projected =
          EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: worldPos,
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );

      if (!projected.isVisible) continue;

      depthQueue.add(
        _DepthSortableItem(
          depthMeters: projected.depthMeters,
          draw: () {
            final bar = _drawCyberRiderAndWkgBar(
              canvas: canvas,
              size: size,
              rider: rider,
              worldPos: worldPos,
              projectedBase: projected,
              rig: rig,
              preset: preset,
            );
            if (bar != null) {
              wkgBars.add(bar);
            }
          },
        ),
      );
    }

    if (config.showPowerUpHolograms) {
      for (final hologram in input.powerUpHolograms) {
        if (hologram.isCollected) continue;
        final relZ = hologram.distanceMeters - input.playerDistanceMeters;
        if (relZ < -4.0 || relZ > config.drawDistanceMeters) continue;

        final double roadX =
            EsportsCyberVelodromeAndHologram3dEngine.trackCenterXAt(
          hologram.distanceMeters,
          input,
        );
        final double roadY =
            EsportsCyberVelodromeAndHologram3dEngine.trackElevationAt(
          hologram.distanceMeters,
          input,
        );

        final basePos = Vector3(
          roadX + hologram.lateralOffsetMeters,
          roadY + hologram.elevationMeters,
          relZ,
        );
        final floatY = hologram.heightAboveTrackMeters +
            math.sin(hologram.pulsePhase * config.hologramScanSpeed) * 0.24;
        final holoCenter = Vector3(
          basePos.x,
          basePos.y + floatY,
          basePos.z,
        );

        final projectedCenter =
            EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
          worldPoint: holoCenter,
          cameraPos: rig.position,
          cameraTarget: rig.target,
          viewportSize: size,
          fovDegrees: config.fovDegrees,
        );
        final projectedFoot =
            EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
          worldPoint: basePos,
          cameraPos: rig.position,
          cameraTarget: rig.target,
          viewportSize: size,
          fovDegrees: config.fovDegrees,
        );

        if (!projectedCenter.isVisible) continue;

        depthQueue.add(
          _DepthSortableItem(
            depthMeters: projectedCenter.depthMeters,
            draw: () {
              final hitbox = _drawPowerUpHologram3D(
                canvas: canvas,
                hologram: hologram,
                centerWorld: holoCenter,
                projectedCenter: projectedCenter,
                projectedFoot: projectedFoot,
                rig: rig,
                size: size,
              );
              if (hitbox != null) {
                hologramHitboxes.add(hitbox);
              }
            },
          ),
        );
      }
    }

    // Sortowanie od najdalszych do najbliższych (Painter's Algorithm)
    depthQueue.sort((a, b) => b.depthMeters.compareTo(a.depthMeters));
    for (final item in depthQueue) {
      item.draw();
      drawCalls += 2;
    }

    // 6. Subtelna winieta i linia skanowania HUD
    _drawNeonVignette(canvas, size, preset);
    drawCalls++;

    stopwatch.stop();
    final double frameMs = stopwatch.elapsedMicroseconds / 1000.0;

    if (onFrameProjected != null) {
      final telemetry =
          EsportsCyberVelodromeAndHologram3dEngine.computeTelemetry(
        input: input,
        config: config,
        frameRenderTimeMs: frameMs,
        projectedDrawCalls: drawCalls,
      );
      onFrameProjected!(hologramHitboxes, wkgBars, telemetry);
    }
  }

  void _drawCyberBackground(
    Canvas canvas,
    Size size,
    EsportsCyberWorldPreset preset,
  ) {
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height),
        [
          AppColors.background,
          Color.lerp(AppColors.surface, preset.primaryNeon, 0.08)!,
          AppColors.background,
        ],
        const [0.0, 0.46, 1.0],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Poświata horyzontu
    final horizonGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.43),
        size.width * 0.55,
        [
          preset.primaryNeon.withValues(alpha: 0.16),
          preset.secondaryNeon.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRect(Offset.zero & size, horizonGlow);
  }

  int _drawCyberSkyGrid(
    Canvas canvas,
    Size size,
    EsportsCyberWorldPreset preset,
    ({Vector3 position, Vector3 target}) rig,
  ) {
    int calls = 0;
    final ribPaint = Paint()
      ..color = preset.primaryNeon.withValues(alpha: 0.12)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    // Żebra kopuły welodromu lub łuki cyber-horyzontu wzdłuż trasy
    const double step = 22.0;
    final double startZ = ((input.playerDistanceMeters / step).floor() * step) -
        input.playerDistanceMeters;

    for (double z = startZ; z < config.drawDistanceMeters; z += step) {
      if (z < 2.0) continue;
      final double absDist = input.playerDistanceMeters + z;
      final double cx =
          EsportsCyberVelodromeAndHologram3dEngine.trackCenterXAt(absDist, input);
      final double cy =
          EsportsCyberVelodromeAndHologram3dEngine.trackElevationAt(
              absDist, input);

      final path = Path();
      bool started = false;
      const int arcSegments = 10;
      const double archRadius = 11.5;

      for (int i = 0; i <= arcSegments; i++) {
        final double angle = math.pi * (i / arcSegments);
        final double px = cx - math.cos(angle) * archRadius;
        final double py = cy + math.sin(angle) * archRadius * 0.72;
        final pt = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
          worldPoint: Vector3(px, py, z),
          cameraPos: rig.position,
          cameraTarget: rig.target,
          viewportSize: size,
          fovDegrees: config.fovDegrees,
        );
        if (!pt.isVisible) continue;
        if (!started) {
          path.moveTo(pt.offset.dx, pt.offset.dy);
          started = true;
        } else {
          path.lineTo(pt.offset.dx, pt.offset.dy);
        }
      }

      if (started) {
        final double fade = (1.0 - (z / config.drawDistanceMeters)).clamp(0.0, 1.0);
        ribPaint.color = preset.primaryNeon.withValues(alpha: 0.16 * fade);
        canvas.drawPath(path, ribPaint);
        calls++;
      }
    }
    return calls;
  }

  int _drawNeonGlassTrack(
    Canvas canvas,
    Size size,
    EsportsCyberWorldPreset preset,
    ({Vector3 position, Vector3 target}) rig,
  ) {
    int calls = 0;
    final double halfWidth = preset.trackWidthMeters * 0.5;
    final double bankingLift =
        math.sin(input.trackBankingRadians) * halfWidth * 0.42;

    const double sliceStep = 6.0;
    final List<double> zSlices = [];
    for (double z = -2.0; z <= config.drawDistanceMeters; z += sliceStep) {
      zSlices.add(z);
    }

    // Budowa pasów szklanej nawierzchni od najdalszych do najbliższych
    for (int i = zSlices.length - 2; i >= 0; i--) {
      final double z0 = zSlices[i];
      final double z1 = zSlices[i + 1];

      final double d0 = input.playerDistanceMeters + z0;
      final double d1 = input.playerDistanceMeters + z1;

      final double cx0 =
          EsportsCyberVelodromeAndHologram3dEngine.trackCenterXAt(d0, input);
      final double cy0 =
          EsportsCyberVelodromeAndHologram3dEngine.trackElevationAt(d0, input);
      final double cx1 =
          EsportsCyberVelodromeAndHologram3dEngine.trackCenterXAt(d1, input);
      final double cy1 =
          EsportsCyberVelodromeAndHologram3dEngine.trackElevationAt(d1, input);

      final p0L = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx0 - halfWidth, cy0 + bankingLift * 0.3, z0),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );
      final p0R = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx0 + halfWidth, cy0 + bankingLift, z0),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );
      final p1R = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx1 + halfWidth, cy1 + bankingLift, z1),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );
      final p1L = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx1 - halfWidth, cy1 + bankingLift * 0.3, z1),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );

      if (!p0L.isVisible || !p0R.isVisible || !p1R.isVisible || !p1L.isVisible) {
        continue;
      }

      final double depthFade =
          (1.0 - (z0 / config.drawDistanceMeters)).clamp(0.08, 1.0);

      final quad = Path()
        ..moveTo(p0L.offset.dx, p0L.offset.dy)
        ..lineTo(p0R.offset.dx, p0R.offset.dy)
        ..lineTo(p1R.offset.dx, p1R.offset.dy)
        ..lineTo(p1L.offset.dx, p1L.offset.dy)
        ..close();

      // Półprzezroczyste szkło nawierzchni
      final glassPaint = Paint()
        ..shader = ui.Gradient.linear(
          p0L.offset,
          p0R.offset,
          [
            preset.primaryNeon
                .withValues(alpha: preset.glassOpacity * 0.55 * depthFade),
            AppColors.surfaceLight.withValues(alpha: 0.72 * depthFade),
            preset.secondaryNeon
                .withValues(alpha: preset.glassOpacity * 0.65 * depthFade),
          ],
          const [0.0, 0.5, 1.0],
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(quad, glassPaint);

      // Szklane odbicie światła wzdłuż środka pasa
      if (config.showGlassRoadReflections) {
        final center0 = Offset.lerp(p0L.offset, p0R.offset, 0.5)!;
        final center1 = Offset.lerp(p1L.offset, p1R.offset, 0.5)!;
        final centerLinePaint = Paint()
          ..color = preset.primaryNeon.withValues(alpha: 0.25 * depthFade)
          ..strokeWidth = (1.6 * depthFade).clamp(0.6, 2.2);
        canvas.drawLine(center0, center1, centerLinePaint);
      }

      // Poprzeczna linia siatki co 12 m
      if ((d0 / sliceStep).round().isEven) {
        final crossPaint = Paint()
          ..color = preset.primaryNeon.withValues(alpha: 0.18 * depthFade)
          ..strokeWidth = 1.0;
        canvas.drawLine(p0L.offset, p0R.offset, crossPaint);
      }

      // Neonowe barierki / szyny krawędziowe
      final railGlowPaint = Paint()
        ..color = preset.primaryNeon.withValues(alpha: 0.85 * depthFade)
        ..strokeWidth = (2.6 * depthFade).clamp(1.0, 3.2);
      canvas.drawLine(p0L.offset, p1L.offset, railGlowPaint);
      canvas.drawLine(p0R.offset, p1R.offset, railGlowPaint);

      calls += 3;
    }

    return calls;
  }

  int _drawCyberGates(
    Canvas canvas,
    Size size,
    EsportsCyberWorldPreset preset,
    ({Vector3 position, Vector3 target}) rig,
  ) {
    int calls = 0;
    final double halfWidth = preset.trackWidthMeters * 0.52;

    for (final gate in input.gates) {
      final double relZ = gate.distanceMeters - input.playerDistanceMeters;
      if (relZ < 0.5 || relZ > config.drawDistanceMeters) continue;

      final double cx = EsportsCyberVelodromeAndHologram3dEngine.trackCenterXAt(
        gate.distanceMeters,
        input,
      );
      final double cy =
          EsportsCyberVelodromeAndHologram3dEngine.trackElevationAt(
        gate.distanceMeters,
        input,
      );

      final leftBase =
          EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx - halfWidth, cy, relZ),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );
      final leftTop = EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx - halfWidth, cy + 4.4, relZ),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );
      final rightTop =
          EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx + halfWidth, cy + 4.4, relZ),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );
      final rightBase =
          EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
        worldPoint: Vector3(cx + halfWidth, cy, relZ),
        cameraPos: rig.position,
        cameraTarget: rig.target,
        viewportSize: size,
        fovDegrees: config.fovDegrees,
      );

      if (!leftBase.isVisible ||
          !leftTop.isVisible ||
          !rightTop.isVisible ||
          !rightBase.isVisible) {
        continue;
      }

      final double fade =
          (1.0 - (relZ / config.drawDistanceMeters)).clamp(0.15, 1.0);
      final Color gateColor = gate.isEliminationGate && !config.showEliminationLaser
          ? preset.secondaryNeon
          : gate.gateColor;

      final archPath = Path()
        ..moveTo(leftBase.offset.dx, leftBase.offset.dy)
        ..lineTo(leftTop.offset.dx, leftTop.offset.dy)
        ..lineTo(rightTop.offset.dx, rightTop.offset.dy)
        ..lineTo(rightBase.offset.dx, rightBase.offset.dy);

      final glowPaint = Paint()
        ..color = gateColor.withValues(alpha: 0.25 * fade)
        ..strokeWidth = 7.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(archPath, glowPaint);

      final corePaint = Paint()
        ..color = gateColor.withValues(alpha: 0.92 * fade)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(archPath, corePaint);

      // Półprzezroczysta belka napisu bramy
      final topCenter = Offset.lerp(leftTop.offset, rightTop.offset, 0.5)!;
      if (relZ < 115.0) {
        _drawTagPill(
          canvas: canvas,
          center: topCenter + const Offset(0, -10),
          text: gate.label,
          borderColor: gateColor.withValues(alpha: fade),
          textColor: AppColors.textPrimary.withValues(alpha: fade),
          fontSize: (10.5 * fade).clamp(8.0, 11.0),
        );
      }

      // Laser eliminacji na nawierzchni, jeśli aktywny
      if (gate.isEliminationGate &&
          config.showEliminationLaser &&
          input.eliminationCountdownSeconds <= 20.0) {
        final laserPaint = Paint()
          ..color = AppColors.crimsonAlert.withValues(alpha: 0.85 * fade)
          ..strokeWidth = 3.0;
        canvas.drawLine(leftBase.offset, rightBase.offset, laserPaint);
      }

      calls += 2;
    }

    return calls;
  }

  ProjectedPowerUpHitbox? _drawPowerUpHologram3D({
    required Canvas canvas,
    required EsportsPowerUpHologram3D hologram,
    required Vector3 centerWorld,
    required CyberProjectedPoint projectedCenter,
    required CyberProjectedPoint projectedFoot,
    required ({Vector3 position, Vector3 target}) rig,
    required Size size,
  }) {
    final Color holoColor =
        EsportsCyberVelodromeAndHologram3dEngine.computePowerUpHologramColor(
      hologram.powerUpType,
    );
    final bool isHovered = hoveredHologramId == hologram.id;
    final bool isSelected = selectedHologramId == hologram.id;

    final double radiusWorld = isHovered || isSelected ? 0.92 : 0.78;
    final double rot = hologram.rotationRadians;

    // 6 wierzchołków oktaedru 3D w przestrzeni świata
    final List<Vector3> verticesWorld = [
      centerWorld + Vector3(0, radiusWorld * 1.35, 0), // góra
      centerWorld + Vector3(0, -radiusWorld * 1.35, 0), // dół
      centerWorld +
          Vector3(
            math.cos(rot) * radiusWorld,
            0,
            math.sin(rot) * radiusWorld,
          ),
      centerWorld +
          Vector3(
            -math.sin(rot) * radiusWorld,
            0,
            math.cos(rot) * radiusWorld,
          ),
      centerWorld +
          Vector3(
            -math.cos(rot) * radiusWorld,
            0,
            -math.sin(rot) * radiusWorld,
          ),
      centerWorld +
          Vector3(
            math.sin(rot) * radiusWorld,
            0,
            -math.cos(rot) * radiusWorld,
          ),
    ];

    final List<CyberProjectedPoint> pts = verticesWorld
        .map(
          (v) => EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
            worldPoint: v,
            cameraPos: rig.position,
            cameraTarget: rig.target,
            viewportSize: size,
            fovDegrees: config.fovDegrees,
          ),
        )
        .toList(growable: false);

    if (pts.any((p) => !p.isVisible)) return null;

    // Pionowy promień rzutnika z nawierzchni
    if (projectedFoot.isVisible) {
      final beamPaint = Paint()
        ..shader = ui.Gradient.linear(
          projectedFoot.offset,
          projectedCenter.offset,
          [
            holoColor.withValues(alpha: 0.45),
            holoColor.withValues(alpha: 0.05),
          ],
        )
        ..strokeWidth = (projectedCenter.scale * 0.14).clamp(1.2, 6.0);
      canvas.drawLine(projectedFoot.offset, projectedCenter.offset, beamPaint);

      final ringRx = (projectedFoot.scale * 0.72).clamp(6.0, 28.0);
      final ringRy = ringRx * 0.34;
      canvas.drawOval(
        Rect.fromCenter(
          center: projectedFoot.offset,
          width: ringRx * 2,
          height: ringRy * 2,
        ),
        Paint()
          ..color = holoColor.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Poświata rdzenia hologramu
    final double screenRadius =
        (projectedCenter.scale * radiusWorld).clamp(10.0, 48.0);
    final auraPaint = Paint()
      ..shader = ui.Gradient.radial(
        projectedCenter.offset,
        screenRadius * 1.5,
        [
          holoColor.withValues(alpha: isHovered || isSelected ? 0.55 : 0.35),
          holoColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(projectedCenter.offset, screenRadius * 1.5, auraPaint);

    // Krawędzie 3D oktaedru
    final edgePaint = Paint()
      ..color = holoColor.withValues(alpha: isHovered || isSelected ? 1.0 : 0.9)
      ..strokeWidth = isHovered || isSelected ? 2.2 : 1.5
      ..style = PaintingStyle.stroke;

    const List<List<int>> edges = [
      [0, 2],
      [0, 3],
      [0, 4],
      [0, 5],
      [1, 2],
      [1, 3],
      [1, 4],
      [1, 5],
      [2, 3],
      [3, 4],
      [4, 5],
      [5, 2],
    ];

    for (final e in edges) {
      canvas.drawLine(pts[e[0]].offset, pts[e[1]].offset, edgePaint);
    }

    // Etykieta Power-Upa nad hologramem
    final String code =
        EsportsCyberVelodromeAndHologram3dEngine.powerUpShortCode(
      hologram.powerUpType,
    );
    _drawTagPill(
      canvas: canvas,
      center: projectedCenter.offset - Offset(0, screenRadius + 14),
      text: code,
      borderColor: holoColor,
      textColor: AppColors.textPrimary,
      fontSize: (screenRadius * 0.44).clamp(8.5, 11.5),
    );

    final rect = Rect.fromCenter(
      center: projectedCenter.offset,
      width: screenRadius * 2.2,
      height: screenRadius * 2.5,
    );

    return ProjectedPowerUpHitbox(
      rect: rect,
      hologram: hologram,
      depthMeters: projectedCenter.depthMeters,
    );
  }

  ProjectedRiderWkgBar? _drawCyberRiderAndWkgBar({
    required Canvas canvas,
    required Size size,
    required EsportsCyberRider3D rider,
    required Vector3 worldPos,
    required CyberProjectedPoint projectedBase,
    required ({Vector3 position, Vector3 target}) rig,
    required EsportsCyberWorldPreset preset,
  }) {
    final double scalePx = projectedBase.scale;
    final double bikeHeightPx = (scalePx * 1.45).clamp(12.0, 96.0);
    final double bikeWidthPx = bikeHeightPx * 0.62;

    final bool isHovered = hoveredRiderId == rider.riderId;
    final bool isSelected = selectedRiderId == rider.riderId;

    // 1. Neonowy ślad aerodynamiczny za kolarzem
    final tailWorld = Vector3(
      worldPos.x,
      worldPos.y + 0.35,
      worldPos.z - 4.2,
    );
    final tailProjected =
        EsportsCyberVelodromeAndHologram3dEngine.projectWorldPoint(
      worldPoint: tailWorld,
      cameraPos: rig.position,
      cameraTarget: rig.target,
      viewportSize: size,
      fovDegrees: config.fovDegrees,
    );
    if (tailProjected.isVisible) {
      final trailPaint = Paint()
        ..shader = ui.Gradient.linear(
          tailProjected.offset,
          projectedBase.offset,
          [
            rider.neonTrailColor.withValues(alpha: 0.0),
            rider.neonTrailColor.withValues(alpha: rider.isPlayerRider ? 0.7 : 0.42),
          ],
        )
        ..strokeWidth = (bikeHeightPx * 0.14).clamp(1.5, 6.0)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(tailProjected.offset, projectedBase.offset, trailPaint);
    }

    // 2. Koła dyskowe i rama neonowa
    final Offset base = projectedBase.offset;
    final double wheelR = (bikeHeightPx * 0.24).clamp(3.0, 20.0);
    final Paint wheelPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final Paint wheelRimPaint = Paint()
      ..color = rider.isPlayerRider ? AppColors.goldAccent : rider.neonTrailColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (bikeHeightPx * 0.045).clamp(1.0, 2.4);

    final Offset rearWheel = base + Offset(-bikeWidthPx * 0.22, -wheelR);
    final Offset frontWheel = base + Offset(bikeWidthPx * 0.22, -wheelR * 1.05);

    canvas.drawCircle(rearWheel, wheelR, wheelPaint);
    canvas.drawCircle(rearWheel, wheelR, wheelRimPaint);
    canvas.drawCircle(frontWheel, wheelR * 0.92, wheelPaint);
    canvas.drawCircle(frontWheel, wheelR * 0.92, wheelRimPaint);

    // 3. Sylwetka kolarza w pozycji aero
    final Offset hip = base + Offset(-bikeWidthPx * 0.12, -bikeHeightPx * 0.56);
    final Offset shoulder =
        base + Offset(bikeWidthPx * 0.14, -bikeHeightPx * 0.80);
    final Offset helmet =
        base + Offset(bikeWidthPx * 0.22, -bikeHeightPx * 0.93);

    final Paint torsoPaint = Paint()
      ..color = rider.jerseyColor
      ..strokeWidth = (bikeWidthPx * 0.34).clamp(3.0, 18.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(hip, shoulder, torsoPaint);

    // Kask
    canvas.drawCircle(
      helmet,
      (bikeHeightPx * 0.12).clamp(2.5, 10.0),
      Paint()
        ..color = rider.isPlayerRider
            ? AppColors.goldAccent
            : AppColors.textPrimary,
    );

    // 4. Pierścień aktywnego Power-Upa wokół awatara
    if (rider.activePowerUp != null && rider.powerUpRemainingSeconds > 0.0) {
      final Color pColor =
          EsportsCyberVelodromeAndHologram3dEngine.computePowerUpHologramColor(
        rider.activePowerUp!,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: base - Offset(0, wheelR * 0.3),
          width: bikeWidthPx * 1.45,
          height: wheelR * 1.2,
        ),
        Paint()
          ..color = pColor.withValues(alpha: 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // 5. Trójwymiarowy słupek W/kg nad kolarzem
    if (!config.showWkgBars) {
      return null;
    }

    final Color wkgColor = rider.isEliminationDanger
        ? AppColors.crimsonAlert
        : EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(
            rider.wattsPerKg,
          );

    final double normalizedWkg = ((rider.wattsPerKg - 1.5) / 6.5).clamp(0.15, 1.0);
    final double barMaxHeight = (bikeHeightPx * 1.25).clamp(26.0, 88.0);
    final double barFillHeight = barMaxHeight * normalizedWkg;
    final double barWidth = (bikeWidthPx * 0.28).clamp(8.0, 18.0);

    final Offset barBottomCenter =
        base - Offset(0, bikeHeightPx * 1.12);
    final Rect bgBarRect = Rect.fromLTWH(
      barBottomCenter.dx - barWidth * 0.5,
      barBottomCenter.dy - barMaxHeight,
      barWidth,
      barMaxHeight,
    );
    final Rect fillBarRect = Rect.fromLTWH(
      barBottomCenter.dx - barWidth * 0.5,
      barBottomCenter.dy - barFillHeight,
      barWidth,
      barFillHeight,
    );

    // Szklany kontener słupka W/kg
    final RRect bgRRect =
        RRect.fromRectAndRadius(bgBarRect, const Radius.circular(4));
    canvas.drawRRect(
      bgRRect,
      Paint()..color = AppColors.surface.withValues(alpha: 0.78),
    );

    // Wypełnienie neonowe słupka W/kg
    final RRect fillRRect =
        RRect.fromRectAndRadius(fillBarRect, const Radius.circular(4));
    canvas.drawRRect(
      fillRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          fillBarRect.bottomCenter,
          fillBarRect.topCenter,
          [
            wkgColor.withValues(alpha: 0.65),
            wkgColor,
          ],
        ),
    );

    canvas.drawRRect(
      bgRRect,
      Paint()
        ..color = (isHovered || isSelected || rider.isPlayerRider)
            ? AppColors.goldAccent
            : wkgColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered || isSelected ? 1.8 : 1.0,
    );

    // Etykieta liczbowa W/kg
    final String wkgLabel = '${rider.wattsPerKg.toStringAsFixed(1)} W/kg';
    final String titleLabel =
        rider.isPlayerRider ? 'TY • $wkgLabel' : '${rider.teamTag} • $wkgLabel';

    _drawTagPill(
      canvas: canvas,
      center: Offset(barBottomCenter.dx, bgBarRect.top - 12),
      text: titleLabel,
      borderColor: rider.isPlayerRider ? AppColors.goldAccent : wkgColor,
      textColor: AppColors.textPrimary,
      fontSize: (bikeHeightPx * 0.19).clamp(8.5, 11.0),
    );

    final hitbox = Rect.fromCenter(
      center: base - Offset(0, bikeHeightPx * 0.9),
      width: math.max(bikeWidthPx * 1.4, 34.0),
      height: bikeHeightPx * 2.1,
    );

    return ProjectedRiderWkgBar(
      rider: rider,
      screenAnchor: barBottomCenter,
      barHeightPx: barFillHeight,
      scale: projectedBase.scale,
      barColor: wkgColor,
      hitbox: hitbox,
    );
  }

  void _drawTagPill({
    required Canvas canvas,
    required Offset center,
    required String text,
    required Color borderColor,
    required Color textColor,
    required double fontSize,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    const double padX = 6.0;
    const double padY = 3.0;
    final rect = Rect.fromCenter(
      center: center,
      width: textPainter.width + padX * 2,
      height: textPainter.height + padY * 2,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    canvas.drawRRect(
      rrect,
      Paint()..color = AppColors.background.withValues(alpha: 0.84),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    textPainter.paint(
      canvas,
      Offset(rect.left + padX, rect.top + padY),
    );
  }

  void _drawNeonVignette(
    Canvas canvas,
    Size size,
    EsportsCyberWorldPreset preset,
  ) {
    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.5),
        size.longestSide * 0.72,
        [
          Colors.transparent,
          AppColors.background.withValues(alpha: 0.45),
        ],
        const [0.65, 1.0],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(
    covariant EsportsCyberVelodromeAndHologram3dPainter oldDelegate,
  ) {
    return oldDelegate.input != input ||
        oldDelegate.config != config ||
        oldDelegate.hoveredHologramId != hoveredHologramId ||
        oldDelegate.selectedHologramId != selectedHologramId ||
        oldDelegate.hoveredRiderId != hoveredRiderId ||
        oldDelegate.selectedRiderId != selectedRiderId;
  }
}

class _DepthSortableItem {
  final double depthMeters;
  final VoidCallback draw;

  const _DepthSortableItem({
    required this.depthMeters,
    required this.draw,
  });
}

// =============================================================================
// 5. RESPONSYWNY WIDGET VIEWPORTU 3D Z PEŁNYMI STANAMI INTERAKCJI
// =============================================================================

/// Interaktywny, neonowo-szklany viewport 3D światów e-Sports z hologramami
/// Power-Upów, słupkami $\text{W/kg}$ oraz pełną responsywnością (390/1024/1600).
class EsportsCyberVelodromeViewportWidget extends StatefulWidget {
  final EsportsCyberVelodromeConfig initialConfig;
  final EsportsCyberVelodromeFrameInput? externalFrameInput;
  final bool autoAnimate;
  final ValueChanged<EsportsPowerUpType>? onTriggerPowerUp;

  const EsportsCyberVelodromeViewportWidget({
    super.key,
    this.initialConfig = const EsportsCyberVelodromeConfig(),
    this.externalFrameInput,
    this.autoAnimate = true,
    this.onTriggerPowerUp,
  });

  @override
  State<EsportsCyberVelodromeViewportWidget> createState() =>
      _EsportsCyberVelodromeViewportWidgetState();
}

class _EsportsCyberVelodromeViewportWidgetState
    extends State<EsportsCyberVelodromeViewportWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickerController;
  late EsportsCyberVelodromeConfig _config;
  bool _isPlaying = true;
  double _elapsedSeconds = 1.8;

  EsportsPowerUpType _readyPowerUp = EsportsPowerUpType.aeroHelmet;
  EsportsPowerUpType? _activePowerUp;
  double _activePowerUpRemaining = 0.0;

  String? _hoveredHologramId;
  String? _selectedHologramId;
  String? _hoveredRiderId;
  String? _selectedRiderId;

  List<ProjectedPowerUpHitbox> _lastHologramHitboxes = const [];
  List<ProjectedRiderWkgBar> _lastWkgBars = const [];
  EsportsCyberVelodromeTelemetry _telemetry =
      EsportsCyberVelodromeTelemetry.empty;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _isPlaying = widget.autoAnimate;

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onTick);

    if (_isPlaying && widget.externalFrameInput == null) {
      _tickerController.repeat();
    }
  }

  void _onTick() {
    if (!mounted || !_isPlaying || widget.externalFrameInput != null) return;
    setState(() {
      _elapsedSeconds += 0.016;
      if (_activePowerUpRemaining > 0.0) {
        _activePowerUpRemaining =
            (_activePowerUpRemaining - 0.016).clamp(0.0, 30.0);
        if (_activePowerUpRemaining <= 0.0) {
          _activePowerUp = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _tickerController.removeListener(_onTick);
    _tickerController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _tickerController.repeat();
      } else {
        _tickerController.stop();
      }
    });
  }

  void _activatePowerUp() {
    if (_activePowerUp != null && _activePowerUpRemaining > 0.0) return;
    final triggered = _readyPowerUp;
    setState(() {
      _activePowerUp = triggered;
      _activePowerUpRemaining = 12.0;
      const values = EsportsPowerUpType.values;
      _readyPowerUp = values[(triggered.index + 1) % values.length];
    });
    widget.onTriggerPowerUp?.call(triggered);
  }

  void _handleCanvasHover(Offset localPos) {
    String? nextHolo;
    for (final hb in _lastHologramHitboxes) {
      if (hb.rect.contains(localPos)) {
        nextHolo = hb.hologram.id;
        break;
      }
    }
    String? nextRider;
    if (nextHolo == null) {
      for (final bar in _lastWkgBars) {
        if (bar.hitbox.contains(localPos)) {
          nextRider = bar.rider.riderId;
          break;
        }
      }
    }
    if (nextHolo != _hoveredHologramId || nextRider != _hoveredRiderId) {
      setState(() {
        _hoveredHologramId = nextHolo;
        _hoveredRiderId = nextRider;
      });
    }
  }

  void _handleCanvasTap(Offset localPos) {
    for (final hb in _lastHologramHitboxes) {
      if (hb.rect.contains(localPos)) {
        setState(() {
          _selectedHologramId =
              _selectedHologramId == hb.hologram.id ? null : hb.hologram.id;
          _selectedRiderId = null;
        });
        return;
      }
    }
    for (final bar in _lastWkgBars) {
      if (bar.hitbox.contains(localPos)) {
        setState(() {
          _selectedRiderId =
              _selectedRiderId == bar.rider.riderId ? null : bar.rider.riderId;
          _selectedHologramId = null;
        });
        return;
      }
    }
    setState(() {
      _selectedHologramId = null;
      _selectedRiderId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final frameInput = widget.externalFrameInput ??
        EsportsCyberVelodromeAndHologram3dEngine.buildDemoFrameInput(
          elapsedSeconds: _elapsedSeconds,
          worldPreset: _config.worldPreset,
          cameraMode: _config.cameraMode,
          activePlayerPowerUp: _activePowerUp,
          activePowerUpRemainingSeconds: _activePowerUpRemaining,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1024.0;
        final bool isCompact = width < 640.0;
        final bool isWide = width >= 1180.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeaderBar(isCompact),
              SizedBox(
                height: isCompact ? 260 : (isWide ? 420 : 340),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MouseRegion(
                      onHover: (event) => _handleCanvasHover(event.localPosition),
                      onExit: (_) {
                        if (_hoveredHologramId != null ||
                            _hoveredRiderId != null) {
                          setState(() {
                            _hoveredHologramId = null;
                            _hoveredRiderId = null;
                          });
                        }
                      },
                      cursor: (_hoveredHologramId != null ||
                              _hoveredRiderId != null)
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) =>
                            _handleCanvasTap(details.localPosition),
                        child: CustomPaint(
                          painter: EsportsCyberVelodromeAndHologram3dPainter(
                            input: frameInput,
                            config: _config,
                            hoveredHologramId: _hoveredHologramId,
                            selectedHologramId: _selectedHologramId,
                            hoveredRiderId: _hoveredRiderId,
                            selectedRiderId: _selectedRiderId,
                            onFrameProjected: (holos, bars, telemetry) {
                              _lastHologramHitboxes = holos;
                              _lastWkgBars = bars;
                              _telemetry = telemetry;
                            },
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: _buildHudOverlay(frameInput, isCompact),
                    ),
                    if (_selectedHologramId != null || _selectedRiderId != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _buildInspectorBadge(frameInput),
                      ),
                  ],
                ),
              ),
              _buildControlsFooter(isCompact, isWide),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar(bool isCompact) {
    final preset = _config.worldPreset;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: preset.primaryNeon,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'UCI E-SPORTS 3D • ${preset.labelPl.toUpperCase()}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _CyberActionButton(
                label: _isPlaying ? 'Pauza' : 'Wznów',
                icon: _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                accentColor: preset.primaryNeon,
                isActive: _isPlaying,
                onPressed: widget.externalFrameInput == null
                    ? _togglePlayback
                    : null,
              ),
              _CyberActionButton(
                label: _activePowerUp != null
                    ? 'Aktywny (${_activePowerUpRemaining.toStringAsFixed(0)}s)'
                    : 'Użyj: ${EsportsCyberVelodromeAndHologram3dEngine.powerUpShortCode(_readyPowerUp)}',
                icon: Icons.bolt_rounded,
                accentColor: AppColors.goldAccent,
                isActive: _activePowerUp != null,
                onPressed: _activePowerUp == null ? _activatePowerUp : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHudOverlay(
    EsportsCyberVelodromeFrameInput frameInput,
    bool isCompact,
  ) {
    final countdown = frameInput.eliminationCountdownSeconds;
    final bool dangerTimer = countdown <= 15.0;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _config.worldPreset.primaryNeon.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ŚR. W/KG: ${_telemetry.averageWkg.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                Text(
                  'LIDER: ${_telemetry.leaderWkg.toStringAsFixed(2)} W/kg',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: dangerTimer
                  ? AppColors.crimsonAlert
                  : AppTheme.borderColor,
            ),
          ),
          child: Text(
            'ELIMINACJA: ${countdown.toStringAsFixed(1)} s',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: dangerTimer
                  ? AppColors.crimsonAlert
                  : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectorBadge(EsportsCyberVelodromeFrameInput frameInput) {
    String title = '';
    String subtitle = '';
    Color accent = AppColors.cyanAccent;

    if (_selectedHologramId != null) {
      final holo = frameInput.powerUpHolograms.firstWhere(
        (h) => h.id == _selectedHologramId,
        orElse: () => frameInput.powerUpHolograms.first,
      );
      title = holo.powerUpType.displayName;
      subtitle =
          'Dystans: ${holo.distanceMeters.toStringAsFixed(0)} m • Tor: ${holo.lateralOffsetMeters.toStringAsFixed(1)} m';
      accent = EsportsCyberVelodromeAndHologram3dEngine.computePowerUpHologramColor(
        holo.powerUpType,
      );
    } else if (_selectedRiderId != null) {
      final rider = frameInput.riders.firstWhere(
        (r) => r.riderId == _selectedRiderId,
        orElse: () => frameInput.riders.first,
      );
      title = '${rider.riderName} (${rider.teamTag})';
      subtitle =
          '${rider.wattsPerKg.toStringAsFixed(2)} W/kg • ${rider.powerWatts.toStringAsFixed(0)} W • ${rider.cadenceRpm} RPM';
      accent = EsportsCyberVelodromeAndHologram3dEngine.computeWkgBarColor(
        rider.wattsPerKg,
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsFooter(bool isCompact, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EsportsCyberWorldPreset.values.map((preset) {
              return _CyberSelectableChip(
                label: preset.shortTag,
                isSelected: _config.worldPreset == preset,
                accentColor: preset.primaryNeon,
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(worldPreset: preset);
                  });
                },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...EsportsCyberCameraMode.values.map((cam) {
                return _CyberSelectableChip(
                  label: cam.shortTag,
                  icon: cam.icon,
                  isSelected: _config.cameraMode == cam,
                  accentColor: AppColors.accentBlue,
                  onTap: () {
                    setState(() {
                      _config = _config.copyWith(cameraMode: cam);
                    });
                  },
                );
              }),
              _CyberSelectableChip(
                label: 'HOLOGRAMY',
                isSelected: _config.showPowerUpHolograms,
                accentColor: AppColors.cyanAccent,
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(
                      showPowerUpHolograms: !_config.showPowerUpHolograms,
                    );
                  });
                },
              ),
              _CyberSelectableChip(
                label: 'SŁUPKI W/KG',
                isSelected: _config.showWkgBars,
                accentColor: AppColors.goldAccent,
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(showWkgBars: !_config.showWkgBars);
                  });
                },
              ),
              _CyberSelectableChip(
                label: 'LASER 60s',
                isSelected: _config.showEliminationLaser,
                accentColor: AppColors.crimsonAlert,
                onTap: () {
                  setState(() {
                    _config = _config.copyWith(
                      showEliminationLaser: !_config.showEliminationLaser,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CyberSelectableChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _CyberSelectableChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.accentColor,
    this.onTap,
  });

  @override
  State<_CyberSelectableChip> createState() => _CyberSelectableChipState();
}

class _CyberSelectableChipState extends State<_CyberSelectableChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : (widget.isSelected || _focused)
            ? widget.accentColor
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.6)
                : AppTheme.borderColor;

    final Color bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 13,
                  color: !enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : widget.isSelected
                          ? widget.accentColor
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: !enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : widget.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyberActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isActive;
  final VoidCallback? onPressed;

  const _CyberActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<_CyberActionButton> createState() => _CyberActionButtonState();
}

class _CyberActionButtonState extends State<_CyberActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (widget.isActive || _focused || _hovered)
            ? widget.accentColor
            : AppTheme.borderColor;

    final Color bgColor = !enabled
        ? AppColors.background.withValues(alpha: 0.5)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.30)
            : widget.isActive
                ? widget.accentColor.withValues(alpha: 0.16)
                : _hovered
                    ? AppColors.surface
                    : AppColors.background;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: !enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : widget.accentColor,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: !enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
