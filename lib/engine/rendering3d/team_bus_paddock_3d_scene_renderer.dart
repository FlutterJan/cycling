// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/team/team_bus_and_warmup_protocol_model.dart';

// =============================================================================
// 1. KONFIGURACJA KAMERY, POGODY I SCENY PADDOCKU 3D
// =============================================================================

/// Tryby kamery w interaktywnej scenie 3D paddocku przed startem etapu.
enum PaddockCameraMode {
  overview(
    labelPl: 'Widok Paddocku',
    shortTag: 'OVERVIEW',
    defaultYawRadians: -0.58,
    defaultPitchRadians: 0.30,
    defaultDistanceMeters: 16.5,
  ),
  awningCloseUp(
    labelPl: 'Pod Markizą',
    shortTag: 'AWNING',
    defaultYawRadians: -0.22,
    defaultPitchRadians: 0.19,
    defaultDistanceMeters: 9.8,
  ),
  riderFocus(
    labelPl: 'Focus Kolarza',
    shortTag: 'RIDER',
    defaultYawRadians: 0.42,
    defaultPitchRadians: 0.16,
    defaultDistanceMeters: 4.8,
  ),
  paddockWalkaround(
    labelPl: 'Orbita 360°',
    shortTag: 'ORBIT',
    defaultYawRadians: 0.0,
    defaultPitchRadians: 0.28,
    defaultDistanceMeters: 14.5,
  );

  final String labelPl;
  final String shortTag;
  final double defaultYawRadians;
  final double defaultPitchRadians;
  final double defaultDistanceMeters;

  const PaddockCameraMode({
    required this.labelPl,
    required this.shortTag,
    required this.defaultYawRadians,
    required this.defaultPitchRadians,
    required this.defaultDistanceMeters,
  });
}

/// Presety pogody i pory dnia w paddocku przed startem etapu.
enum PaddockWeatherPreset {
  sunnyMorning(
    labelPl: 'Słoneczny Poranek',
    ambientTempCelsius: 21.0,
    skyTopColor: Color(0xFF152942),
    skyHorizonColor: Color(0xFF476C8E),
    asphaltColor: Color(0xFF232730),
    sunElevationRadians: 0.58,
    windSpeedMps: 2.4,
    isRaining: false,
  ),
  overcastBreezy(
    labelPl: 'Pochmurno & Wiatr',
    ambientTempCelsius: 15.5,
    skyTopColor: Color(0xFF1A202B),
    skyHorizonColor: Color(0xFF3A4352),
    asphaltColor: Color(0xFF1F232B),
    sunElevationRadians: 0.35,
    windSpeedMps: 7.2,
    isRaining: false,
  ),
  hotGrandTour(
    labelPl: 'Upał Grand Tour (33°C)',
    ambientTempCelsius: 33.0,
    skyTopColor: Color(0xFF1C2D47),
    skyHorizonColor: Color(0xFF7D6852),
    asphaltColor: Color(0xFF282B33),
    sunElevationRadians: 0.88,
    windSpeedMps: 1.8,
    isRaining: false,
  ),
  rainyClassic(
    labelPl: 'Deszczowy Klasyk',
    ambientTempCelsius: 10.5,
    skyTopColor: Color(0xFF11161F),
    skyHorizonColor: Color(0xFF283240),
    asphaltColor: Color(0xFF161A22),
    sunElevationRadians: 0.28,
    windSpeedMps: 5.8,
    isRaining: true,
  );

  final String labelPl;
  final double ambientTempCelsius;
  final Color skyTopColor;
  final Color skyHorizonColor;
  final Color asphaltColor;
  final double sunElevationRadians;
  final double windSpeedMps;
  final bool isRaining;

  const PaddockWeatherPreset({
    required this.labelPl,
    required this.ambientTempCelsius,
    required this.skyTopColor,
    required this.skyHorizonColor,
    required this.asphaltColor,
    required this.sunElevationRadians,
    required this.windSpeedMps,
    required this.isRaining,
  });
}

/// Konfiguracja sceny 3D Paddocku i Autobusu Drużyny.
class TeamBusPaddock3dConfig {
  final TeamBusTier busTier;
  final PaddockCameraMode cameraMode;
  final PaddockWeatherPreset weatherPreset;
  final String teamName;
  final String teamShortCode;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final double fieldOfViewDegrees;
  final bool showSpectatorsAndBarriers;
  final bool showFansAndCooling;
  final bool showMechanicsAndSpareBikes;
  final bool showTelemetryOverlay;

  const TeamBusPaddock3dConfig({
    this.busTier = TeamBusTier.worldTourFlagshipBus,
    this.cameraMode = PaddockCameraMode.overview,
    this.weatherPreset = PaddockWeatherPreset.sunnyMorning,
    this.teamName = 'Veloce Pro Cycling',
    this.teamShortCode = 'VPC',
    this.primaryColor = AppColors.primaryAccent,
    this.secondaryColor = const Color(0xFF1E2430),
    this.accentColor = AppColors.goldAccent,
    this.fieldOfViewDegrees = 52.0,
    this.showSpectatorsAndBarriers = true,
    this.showFansAndCooling = true,
    this.showMechanicsAndSpareBikes = true,
    this.showTelemetryOverlay = true,
  });

  TeamBusPaddock3dConfig copyWith({
    TeamBusTier? busTier,
    PaddockCameraMode? cameraMode,
    PaddockWeatherPreset? weatherPreset,
    String? teamName,
    String? teamShortCode,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    double? fieldOfViewDegrees,
    bool? showSpectatorsAndBarriers,
    bool? showFansAndCooling,
    bool? showMechanicsAndSpareBikes,
    bool? showTelemetryOverlay,
  }) {
    return TeamBusPaddock3dConfig(
      busTier: busTier ?? this.busTier,
      cameraMode: cameraMode ?? this.cameraMode,
      weatherPreset: weatherPreset ?? this.weatherPreset,
      teamName: teamName ?? this.teamName,
      teamShortCode: teamShortCode ?? this.teamShortCode,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
      showSpectatorsAndBarriers:
          showSpectatorsAndBarriers ?? this.showSpectatorsAndBarriers,
      showFansAndCooling: showFansAndCooling ?? this.showFansAndCooling,
      showMechanicsAndSpareBikes:
          showMechanicsAndSpareBikes ?? this.showMechanicsAndSpareBikes,
      showTelemetryOverlay: showTelemetryOverlay ?? this.showTelemetryOverlay,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamBusPaddock3dConfig &&
        other.busTier == busTier &&
        other.cameraMode == cameraMode &&
        other.weatherPreset == weatherPreset &&
        other.teamName == teamName &&
        other.teamShortCode == teamShortCode &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.accentColor == accentColor &&
        other.fieldOfViewDegrees == fieldOfViewDegrees &&
        other.showSpectatorsAndBarriers == showSpectatorsAndBarriers &&
        other.showFansAndCooling == showFansAndCooling &&
        other.showMechanicsAndSpareBikes == showMechanicsAndSpareBikes &&
        other.showTelemetryOverlay == showTelemetryOverlay;
  }

  @override
  int get hashCode => Object.hash(
        busTier,
        cameraMode,
        weatherPreset,
        teamName,
        teamShortCode,
        primaryColor,
        secondaryColor,
        accentColor,
        fieldOfViewDegrees,
        showSpectatorsAndBarriers,
        showFansAndCooling,
        showMechanicsAndSpareBikes,
        showTelemetryOverlay,
      );
}

// =============================================================================
// 2. MODELE KOLARZA NA TRENAŻERZE I TELEMETRII SCENY 3D
// =============================================================================

/// Stan kolarza rozgrzewającego się na trenażerze pod markizą autokaru w 3D.
class PaddockWarmupRider3D {
  final String riderId;
  final String riderName;
  final int bibNumber;
  final String roleLabel;
  final int slotIndex;
  final SmartTrainerType trainerType;
  final WarmupProtocolType protocolType;
  final CoolingStrategyType coolingStrategy;
  final double ftpWatts;
  final double currentPowerWatts;
  final double cadenceRpm;
  final int heartRateBpm;
  final double coreTempCelsius;
  final double warmupProgress;
  final bool isLeader;
  final Color jerseyColor;
  final Color helmetColor;

  const PaddockWarmupRider3D({
    required this.riderId,
    required this.riderName,
    required this.bibNumber,
    required this.roleLabel,
    required this.slotIndex,
    this.trainerType = SmartTrainerType.directDriveProErg,
    this.protocolType = WarmupProtocolType.progressiveRamp,
    this.coolingStrategy = CoolingStrategyType.fanAndColdTowels,
    this.ftpWatts = 395.0,
    this.currentPowerWatts = 245.0,
    this.cadenceRpm = 92.0,
    this.heartRateBpm = 138,
    this.coreTempCelsius = 37.5,
    this.warmupProgress = 0.55,
    this.isLeader = false,
    this.jerseyColor = AppColors.primaryAccent,
    this.helmetColor = AppColors.textPrimary,
  });

  /// Strefa mocy Coggana 1–7 na podstawie aktualnych watów względem FTP.
  int get powerZone {
    if (currentPowerWatts <= 0.0 || ftpWatts <= 0.0) return 1;
    final ratio = currentPowerWatts / ftpWatts;
    if (ratio < 0.56) return 1;
    if (ratio < 0.76) return 2;
    if (ratio < 0.91) return 3;
    if (ratio < 1.06) return 4;
    if (ratio < 1.21) return 5;
    if (ratio < 1.50) return 6;
    return 7;
  }

  bool get hasIceVest => coolingStrategy == CoolingStrategyType.preCoolingIceVest;

  bool get hasFan => coolingStrategy != CoolingStrategyType.none;

  PaddockWarmupRider3D copyWith({
    String? riderId,
    String? riderName,
    int? bibNumber,
    String? roleLabel,
    int? slotIndex,
    SmartTrainerType? trainerType,
    WarmupProtocolType? protocolType,
    CoolingStrategyType? coolingStrategy,
    double? ftpWatts,
    double? currentPowerWatts,
    double? cadenceRpm,
    int? heartRateBpm,
    double? coreTempCelsius,
    double? warmupProgress,
    bool? isLeader,
    Color? jerseyColor,
    Color? helmetColor,
  }) {
    return PaddockWarmupRider3D(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      bibNumber: bibNumber ?? this.bibNumber,
      roleLabel: roleLabel ?? this.roleLabel,
      slotIndex: slotIndex ?? this.slotIndex,
      trainerType: trainerType ?? this.trainerType,
      protocolType: protocolType ?? this.protocolType,
      coolingStrategy: coolingStrategy ?? this.coolingStrategy,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      currentPowerWatts: currentPowerWatts ?? this.currentPowerWatts,
      cadenceRpm: cadenceRpm ?? this.cadenceRpm,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      coreTempCelsius: coreTempCelsius ?? this.coreTempCelsius,
      warmupProgress: warmupProgress ?? this.warmupProgress,
      isLeader: isLeader ?? this.isLeader,
      jerseyColor: jerseyColor ?? this.jerseyColor,
      helmetColor: helmetColor ?? this.helmetColor,
    );
  }

  /// Tworzy domyślną listę kolarzy dopasowaną do klasy autobusu drużyny.
  static List<PaddockWarmupRider3D> buildDefaultRoster({
    required TeamBusTier busTier,
    required Color teamJerseyColor,
  }) {
    final slotCount = busTier.defaultTrainerSlots;
    const names = [
      ('M. Kowalski', 11, 'Lider GC', true, WarmupProtocolType.vo2PrimingItt, 420.0),
      ('L. Van Der Berg', 12, 'Klasyki / Kapitan', false, WarmupProtocolType.progressiveRamp, 405.0),
      ('T. Moreau', 13, 'Góral', false, WarmupProtocolType.mountainStartOpener, 385.0),
      ('J. Novak', 14, 'Sprinter', false, WarmupProtocolType.sprintNeuromuscularPriming, 375.0),
      ('A. Rossi', 15, 'Rozprowadzający', false, WarmupProtocolType.progressiveRamp, 390.0),
      ('K. Zieliński', 16, 'Domestique', false, WarmupProtocolType.lightSpinActivation, 365.0),
      ('S. Lindqvist', 17, 'Czasowiec', false, WarmupProtocolType.vo2PrimingItt, 410.0),
      ('P. Dubois', 18, 'Domestique', false, WarmupProtocolType.lightSpinActivation, 360.0),
      ('E. Navarro', 19, 'Młody Talent', false, WarmupProtocolType.progressiveRamp, 355.0),
    ];

    final SmartTrainerType defaultTrainer = switch (busTier) {
      TeamBusTier.continentalMinibus => SmartTrainerType.rollers,
      TeamBusTier.proTeamTourBus => SmartTrainerType.directDriveStandard,
      TeamBusTier.worldTourFlagshipBus => SmartTrainerType.directDriveProErg,
      TeamBusTier.grandTourCommandCenter => SmartTrainerType.directDriveProErg,
    };

    final CoolingStrategyType defaultCooling = switch (busTier) {
      TeamBusTier.continentalMinibus => CoolingStrategyType.none,
      TeamBusTier.proTeamTourBus => CoolingStrategyType.fanAndColdTowels,
      TeamBusTier.worldTourFlagshipBus => CoolingStrategyType.fanAndColdTowels,
      TeamBusTier.grandTourCommandCenter => CoolingStrategyType.preCoolingIceVest,
    };

    return List<PaddockWarmupRider3D>.generate(slotCount, (index) {
      final info = names[index % names.length];
      final protocol = info.$5;
      final ftp = info.$6;
      final baseRatio = switch (protocol) {
        WarmupProtocolType.none => 0.25,
        WarmupProtocolType.lightSpinActivation => 0.52,
        WarmupProtocolType.progressiveRamp => 0.68,
        WarmupProtocolType.vo2PrimingItt => 0.94,
        WarmupProtocolType.mountainStartOpener => 0.82,
        WarmupProtocolType.sprintNeuromuscularPriming => 0.78,
      };
      return PaddockWarmupRider3D(
        riderId: 'rider_$index',
        riderName: info.$1,
        bibNumber: info.$2,
        roleLabel: info.$3,
        slotIndex: index,
        trainerType: defaultTrainer,
        protocolType: protocol,
        coolingStrategy: info.$4
            ? CoolingStrategyType.preCoolingIceVest
            : defaultCooling,
        ftpWatts: ftp,
        currentPowerWatts: (ftp * baseRatio).roundToDouble(),
        cadenceRpm: protocol == WarmupProtocolType.none ? 0.0 : 88.0 + (index % 4) * 4.0,
        heartRateBpm: protocol == WarmupProtocolType.none ? 68 : 124 + index * 5,
        coreTempCelsius: 37.2 + (baseRatio * 0.65),
        warmupProgress: 0.35 + ((index * 0.11) % 0.58),
        isLeader: info.$4,
        jerseyColor: info.$4 ? AppColors.goldAccent : teamJerseyColor,
        helmetColor: info.$4 ? AppColors.goldAccent : AppColors.textPrimary,
      );
    });
  }
}


/// Rzutowany na ekran obszar kliknięcia / najechania kolarza na trenażerze.
class ProjectedRiderHitbox {
  final String riderId;
  final int slotIndex;
  final Rect screenRect;
  final double depthMeters;

  const ProjectedRiderHitbox({
    required this.riderId,
    required this.slotIndex,
    required this.screenRect,
    required this.depthMeters,
  });
}

/// Telemetria wyrenderowanej klatki sceny 3D paddocku.
class PaddockSceneTelemetry {
  final int renderedPolygonCount;
  final int activeWarmupRiders;
  final double averagePowerWatts;
  final double averageCadenceRpm;
  final double peakCoreTempCelsius;
  final TeamBusTier busTier;
  final double cameraDistanceMeters;
  final String? selectedRiderName;
  final List<ProjectedRiderHitbox> riderHitboxes;

  const PaddockSceneTelemetry({
    required this.renderedPolygonCount,
    required this.activeWarmupRiders,
    required this.averagePowerWatts,
    required this.averageCadenceRpm,
    required this.peakCoreTempCelsius,
    required this.busTier,
    required this.cameraDistanceMeters,
    required this.selectedRiderName,
    required this.riderHitboxes,
  });
}

// =============================================================================
// 3. SILNIK RZUTOWANIA 3D I RENDERER SCENY PADDOCKU
// =============================================================================

class _PaddockCameraRig {
  final Vector3 position;
  final Vector3 forward;
  final Vector3 right;
  final Vector3 up;
  final double focalLengthPx;
  final double centerX;
  final double centerY;

  const _PaddockCameraRig({
    required this.position,
    required this.forward,
    required this.right,
    required this.up,
    required this.focalLengthPx,
    required this.centerX,
    required this.centerY,
  });

  Offset? project(Vector3 worldPoint, {double? outDepth}) {
    final rel = worldPoint - position;
    final zCam = rel.dot(forward);
    if (zCam <= 0.25) return null;
    final xCam = rel.dot(right);
    final yCam = rel.dot(up);
    final invZ = focalLengthPx / zCam;
    return Offset(centerX + xCam * invZ, centerY - yCam * invZ);
  }

  double depthOf(Vector3 worldPoint) {
    return (worldPoint - position).dot(forward);
  }
}

class _SortedPolygon3D {
  final List<Offset> points;
  final double depth;
  final Color fillColor;
  final Color? strokeColor;
  final double strokeWidth;

  const _SortedPolygon3D({
    required this.points,
    required this.depth,
    required this.fillColor,
    this.strokeColor,
    this.strokeWidth = 1.0,
  });
}

class _SortedSegment3D {
  final Offset a;
  final Offset b;
  final double depth;
  final Color color;
  final double width;

  const _SortedSegment3D({
    required this.a,
    required this.b,
    required this.depth,
    required this.color,
    required this.width,
  });
}

/// Główny natywny renderer 3D Paddocku i Autobusu Drużyny przed startem etapu.
class TeamBusPaddock3dSceneRenderer {
  final TeamBusPaddock3dConfig config;

  const TeamBusPaddock3dSceneRenderer({
    this.config = const TeamBusPaddock3dConfig(),
  });

  /// Renderuje pełną scenę 3D paddocku i zwraca telemetrię klatki oraz hitboxy kolarzy.
  PaddockSceneTelemetry paintScene({
    required Canvas canvas,
    required Size size,
    required double timeSeconds,
    required List<PaddockWarmupRider3D> riders,
    String? selectedRiderId,
    String? hoveredRiderId,
    double cameraYawOffsetRadians = 0.0,
    double cameraPitchOffsetRadians = 0.0,
    double cameraDistanceOffsetMeters = 0.0,
  }) {
    if (size.width <= 1.0 || size.height <= 1.0) {
      return PaddockSceneTelemetry(
        renderedPolygonCount: 0,
        activeWarmupRiders: 0,
        averagePowerWatts: 0.0,
        averageCadenceRpm: 0.0,
        peakCoreTempCelsius: 37.0,
        busTier: config.busTier,
        cameraDistanceMeters: config.cameraMode.defaultDistanceMeters,
        selectedRiderName: null,
        riderHitboxes: const [],
      );
    }

    final weather = config.weatherPreset;
    final visibleSlots = config.busTier.defaultTrainerSlots;
    final activeRiders = riders.take(visibleSlots).toList(growable: false);

    // 1. Tło nieba i horyzontu
    _paintSkyAndBackdrop(canvas, size, weather);

    // 2. Ustawienie kamery 3D
    final PaddockWarmupRider3D? selectedRider = _findSelectedRider(
      activeRiders,
      selectedRiderId,
    );
    final rig = _buildCameraRig(
      size: size,
      timeSeconds: timeSeconds,
      selectedRider: selectedRider,
      totalSlots: visibleSlots,
      yawOffset: cameraYawOffsetRadians,
      pitchOffset: cameraPitchOffsetRadians,
      distanceOffset: cameraDistanceOffsetMeters,
    );

    final List<_SortedPolygon3D> polygons = [];
    final List<_SortedSegment3D> segments = [];
    final List<ProjectedRiderHitbox> hitboxes = [];

    // 3. Nawierzchnia asfaltowa paddocku i linie stanowisk
    _buildAsphaltAndBayLines(rig, polygons, segments, weather, visibleSlots);

    // 4. Autobus drużyny (skalowany wg TeamBusTier) + cień + koła + malowanie
    _buildTeamBus3D(rig, polygons, segments, timeSeconds, weather);

    // 5. Rozkładana markiza nad strefą trenażerów + słupki + cień
    _buildAwningAndSupportPoles(
      rig,
      polygons,
      segments,
      visibleSlots,
      weather,
    );

    // 6. Kolarze na trenażerach, rowery, maty, wentylatory i podświetlenie wyboru
    for (int i = 0; i < activeRiders.length; i++) {
      final rider = activeRiders[i];
      final isSelected = rider.riderId == selectedRider?.riderId;
      final isHovered = rider.riderId == hoveredRiderId;
      final hitbox = _buildTrainerStationAndRider3D(
        rig: rig,
        polygons: polygons,
        segments: segments,
        rider: rider,
        slotIndex: i,
        totalSlots: visibleSlots,
        timeSeconds: timeSeconds,
        isSelected: isSelected,
        isHovered: isHovered,
      );
      if (hitbox != null) {
        hitboxes.add(hitbox);
      }
    }

    // 7. Mechanik, stojak z kołami zapasowymi i flagi drużynowe
    if (config.showMechanicsAndSpareBikes) {
      _buildMechanicsAndSpareWheels(
        rig,
        polygons,
        segments,
        timeSeconds,
        weather,
        visibleSlots,
      );
    }

    // 8. Barierki paddocku ze sponsorami i sylwetki kibiców
    if (config.showSpectatorsAndBarriers) {
      _buildBarriersAndSpectators(
        rig,
        polygons,
        segments,
        timeSeconds,
        visibleSlots,
      );
    }

    // 9. Sortowanie malarskie (od najdalszego do najbliższego)
    polygons.sort((a, b) => b.depth.compareTo(a.depth));
    segments.sort((a, b) => b.depth.compareTo(a.depth));

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()..style = PaintingStyle.stroke;

    int polyIdx = 0;
    int segIdx = 0;
    while (polyIdx < polygons.length || segIdx < segments.length) {
      final bool drawPoly = segIdx >= segments.length ||
          (polyIdx < polygons.length &&
              polygons[polyIdx].depth >= segments[segIdx].depth);
      if (drawPoly) {
        final poly = polygons[polyIdx++];
        if (poly.points.length < 3) continue;
        final path = Path()..moveTo(poly.points[0].dx, poly.points[0].dy);
        for (int k = 1; k < poly.points.length; k++) {
          path.lineTo(poly.points[k].dx, poly.points[k].dy);
        }
        path.close();
        fillPaint.color = poly.fillColor;
        canvas.drawPath(path, fillPaint);
        if (poly.strokeColor != null) {
          strokePaint
            ..color = poly.strokeColor!
            ..strokeWidth = poly.strokeWidth
            ..strokeJoin = StrokeJoin.round;
          canvas.drawPath(path, strokePaint);
        }
      } else {
        final seg = segments[segIdx++];
        strokePaint
          ..color = seg.color
          ..strokeWidth = seg.width
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(seg.a, seg.b, strokePaint);
      }
    }

    // 10. Oznaczenie zespołu na boku autobusu i numery startowe nad wybranym kolarzem
    _paintBusBrandingAndRiderCallout(
      canvas: canvas,
      rig: rig,
      selectedRider: selectedRider,
      totalSlots: visibleSlots,
    );

    // 11. Efekty deszczu na pierwszym planie
    if (weather.isRaining) {
      _paintRainStreaks(canvas, size, timeSeconds);
    }

    // 12. Wyliczenie telemetrii
    final activeWarmupCount = activeRiders
        .where((r) => r.protocolType != WarmupProtocolType.none)
        .length;
    double sumPower = 0.0;
    double sumCadence = 0.0;
    double maxTemp = 37.0;
    for (final r in activeRiders) {
      sumPower += r.currentPowerWatts;
      sumCadence += r.cadenceRpm;
      if (r.coreTempCelsius > maxTemp) {
        maxTemp = r.coreTempCelsius;
      }
    }
    final count = activeRiders.isEmpty ? 1 : activeRiders.length;
    final camDist = (config.cameraMode.defaultDistanceMeters +
            cameraDistanceOffsetMeters)
        .clamp(3.2, 26.0);

    return PaddockSceneTelemetry(
      renderedPolygonCount: polygons.length + segments.length,
      activeWarmupRiders: activeWarmupCount,
      averagePowerWatts: sumPower / count,
      averageCadenceRpm: sumCadence / count,
      peakCoreTempCelsius: maxTemp,
      busTier: config.busTier,
      cameraDistanceMeters: camDist,
      selectedRiderName: selectedRider?.riderName,
      riderHitboxes: hitboxes,
    );
  }

  PaddockWarmupRider3D? _findSelectedRider(
    List<PaddockWarmupRider3D> riders,
    String? selectedId,
  ) {
    if (riders.isEmpty) return null;
    if (selectedId != null) {
      for (final r in riders) {
        if (r.riderId == selectedId) return r;
      }
    }
    return riders.first;
  }

  _PaddockCameraRig _buildCameraRig({
    required Size size,
    required double timeSeconds,
    required PaddockWarmupRider3D? selectedRider,
    required int totalSlots,
    required double yawOffset,
    required double pitchOffset,
    required double distanceOffset,
  }) {
    final mode = config.cameraMode;
    final double autoOrbitYaw = mode == PaddockCameraMode.paddockWalkaround
        ? timeSeconds * 0.22
        : 0.0;
    final double yaw = mode.defaultYawRadians + autoOrbitYaw + yawOffset;
    final double pitch =
        (mode.defaultPitchRadians + pitchOffset).clamp(0.08, 1.15);
    final double distance =
        (mode.defaultDistanceMeters + distanceOffset).clamp(3.2, 26.0);

    Vector3 target = Vector3(0.0, 1.15, 1.6);
    if (mode == PaddockCameraMode.riderFocus && selectedRider != null) {
      final slotX = _slotWorldX(selectedRider.slotIndex, totalSlots);
      target = Vector3(slotX, 0.95, 2.35);
    } else if (mode == PaddockCameraMode.awningCloseUp) {
      target = Vector3(0.0, 1.0, 2.35);
    }

    final double cosP = math.cos(pitch);
    final double sinP = math.sin(pitch);
    final double sinY = math.sin(yaw);
    final double cosY = math.cos(yaw);

    final Vector3 camPos = Vector3(
      target.x + distance * cosP * sinY,
      target.y + distance * sinP,
      target.z + distance * cosP * cosY,
    );

    final Vector3 forward = (target - camPos).normalized();
    final Vector3 worldUp = Vector3(0.0, 1.0, 0.0);
    final Vector3 right = forward.cross(worldUp).normalized();
    final Vector3 up = right.cross(forward).normalized();

    final double fovRad = config.fieldOfViewDegrees * math.pi / 180.0;
    final double focalLength = (size.height * 0.5) / math.tan(fovRad * 0.5);

    return _PaddockCameraRig(
      position: camPos,
      forward: forward,
      right: right,
      up: up,
      focalLengthPx: focalLength,
      centerX: size.width * 0.5,
      centerY: size.height * 0.54,
    );
  }

  double _slotWorldX(int slotIndex, int totalSlots) {
    final double spacing = totalSlots >= 8 ? 1.32 : 1.55;
    final double span = (totalSlots - 1) * spacing;
    return -span * 0.5 + slotIndex * spacing;
  }

  void _paintSkyAndBackdrop(
    Canvas canvas,
    Size size,
    PaddockWeatherPreset weather,
  ) {
    final rect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          weather.skyTopColor,
          weather.skyHorizonColor,
          AppColors.background,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Subtelne pasmo gór / zabudowy miasteczka startowego na horyzoncie
    final horizonY = size.height * 0.44;
    final ridgePath = Path()..moveTo(0, horizonY + 24);
    for (int i = 0; i <= 12; i++) {
      final x = size.width * (i / 12.0);
      final h = math.sin(i * 0.85) * 14.0 + math.cos(i * 1.7) * 9.0;
      ridgePath.lineTo(x, horizonY - 12.0 - h.abs());
    }
    ridgePath.lineTo(size.width, horizonY + 24);
    ridgePath.close();
    canvas.drawPath(
      ridgePath,
      Paint()..color = const Color(0xFF141821).withValues(alpha: 0.75),
    );
  }

  void _addQuad(
    _PaddockCameraRig rig,
    List<_SortedPolygon3D> polygons,
    Vector3 p0,
    Vector3 p1,
    Vector3 p2,
    Vector3 p3,
    Color fill, {
    Color? stroke,
    double strokeWidth = 1.0,
  }) {
    final o0 = rig.project(p0);
    final o1 = rig.project(p1);
    final o2 = rig.project(p2);
    final o3 = rig.project(p3);
    if (o0 == null || o1 == null || o2 == null || o3 == null) return;
    final center = (p0 + p1 + p2 + p3) * 0.25;
    final depth = rig.depthOf(center);
    if (depth <= 0.25) return;
    polygons.add(
      _SortedPolygon3D(
        points: [o0, o1, o2, o3],
        depth: depth,
        fillColor: fill,
        strokeColor: stroke,
        strokeWidth: strokeWidth,
      ),
    );
  }

  void _addBox3D(
    _PaddockCameraRig rig,
    List<_SortedPolygon3D> polygons, {
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
    required double minZ,
    required double maxZ,
    required Color frontColor,
    required Color sideColor,
    required Color topColor,
    Color? strokeColor,
  }) {
    final p000 = Vector3(minX, minY, minZ);
    final p100 = Vector3(maxX, minY, minZ);
    final p110 = Vector3(maxX, maxY, minZ);
    final p010 = Vector3(minX, maxY, minZ);
    final p001 = Vector3(minX, minY, maxZ);
    final p101 = Vector3(maxX, minY, maxZ);
    final p111 = Vector3(maxX, maxY, maxZ);
    final p011 = Vector3(minX, maxY, maxZ);

    // Przód (+Z) i tył (-Z)
    _addQuad(rig, polygons, p001, p101, p111, p011, frontColor, stroke: strokeColor);
    _addQuad(rig, polygons, p100, p000, p010, p110, frontColor.withValues(alpha: 0.88), stroke: strokeColor);
    // Boki (-X i +X)
    _addQuad(rig, polygons, p000, p001, p011, p010, sideColor, stroke: strokeColor);
    _addQuad(rig, polygons, p101, p100, p110, p111, sideColor, stroke: strokeColor);
    // Dach (+Y)
    _addQuad(rig, polygons, p011, p111, p110, p010, topColor, stroke: strokeColor);
  }

  void _addLine(
    _PaddockCameraRig rig,
    List<_SortedSegment3D> segments,
    Vector3 a,
    Vector3 b,
    Color color, {
    double width = 2.0,
  }) {
    final oa = rig.project(a);
    final ob = rig.project(b);
    if (oa == null || ob == null) return;
    final depth = rig.depthOf((a + b) * 0.5);
    if (depth <= 0.25) return;
    segments.add(
      _SortedSegment3D(a: oa, b: ob, depth: depth, color: color, width: width),
    );
  }

  void _buildAsphaltAndBayLines(
    _PaddockCameraRig rig,
    List<_SortedPolygon3D> polygons,
    List<_SortedSegment3D> segments,
    PaddockWeatherPreset weather,
    int totalSlots,
  ) {
    final double halfW = math.max(9.5, totalSlots * 0.95);
    _addQuad(
      rig,
      polygons,
      Vector3(-halfW, 0.0, -5.5),
      Vector3(halfW, 0.0, -5.5),
      Vector3(halfW, 0.0, 9.0),
      Vector3(-halfW, 0.0, 9.0),
      weather.asphaltColor,
    );

    // Linie stanowiska parkingowego w paddocku
    final lineColor = weather.isRaining
        ? AppColors.accentBlue.withValues(alpha: 0.35)
        : AppColors.goldAccent.withValues(alpha: 0.42);
    _addLine(
      rig,
      segments,
      Vector3(-halfW + 1.0, 0.01, 5.2),
      Vector3(halfW - 1.0, 0.01, 5.2),
      lineColor,
      width: 1.8,
    );
    _addLine(
      rig,
      segments,
      Vector3(-halfW + 1.0, 0.01, -3.6),
      Vector3(halfW - 1.0, 0.01, -3.6),
      lineColor,
      width: 1.5,
    );

    if (weather.isRaining) {
      // Kałuża z lekkim odbiciem przed barierkami
      _addQuad(
        rig,
        polygons,
        Vector3(-3.8, 0.005, 4.1),
        Vector3(2.4, 0.005, 4.1),
        Vector3(2.8, 0.005, 5.0),
        Vector3(-3.2, 0.005, 5.0),
        const Color(0xFF283A52).withValues(alpha: 0.48),
      );
    }
  }

  void _buildTeamBus3D(
    _PaddockCameraRig rig,
    List<_SortedPolygon3D> polygons,
    List<_SortedSegment3D> segments,
    double timeSeconds,
    PaddockWeatherPreset weather,
  ) {
    final tier = config.busTier;
    final double busHalfLength = switch (tier) {
      TeamBusTier.continentalMinibus => 3.1,
      TeamBusTier.proTeamTourBus => 5.2,
      TeamBusTier.worldTourFlagshipBus => 6.6,
      TeamBusTier.grandTourCommandCenter => 7.0,
    };
    final double busHeight = switch (tier) {
      TeamBusTier.continentalMinibus => 2.45,
      TeamBusTier.proTeamTourBus => 3.55,
      TeamBusTier.worldTourFlagshipBus => 3.85,
      TeamBusTier.grandTourCommandCenter => 4.25,
    };
    const double busMinZ = -2.45;
    const double busMaxZ = 0.25;

    // Cień pod autobusem
    _addQuad(
      rig,
      polygons,
      Vector3(-busHalfLength - 0.35, 0.01, busMinZ - 0.35),
      Vector3(busHalfLength + 0.35, 0.01, busMinZ - 0.35),
      Vector3(busHalfLength + 0.35, 0.01, busMaxZ + 0.45),
      Vector3(-busHalfLength - 0.35, 0.01, busMaxZ + 0.45),
      Colors.black.withValues(alpha: 0.46),
    );

    // Główna bryła autokaru
    _addBox3D(
      rig,
      polygons,
      minX: -busHalfLength,
      maxX: busHalfLength,
      minY: 0.45,
      maxY: busHeight,
      minZ: busMinZ,
      maxZ: busMaxZ,
      frontColor: config.secondaryColor,
      sideColor: Color.lerp(config.secondaryColor, Colors.black, 0.25)!,
      topColor: Color.lerp(config.secondaryColor, Colors.white, 0.08)!,
      strokeColor: AppColors.cardBorder,
    );

    // Pasy malowania drużynowego na froncie (+Z) od strony paddocku
    _addQuad(
      rig,
      polygons,
      Vector3(-busHalfLength + 0.1, 0.72, busMaxZ + 0.02),
      Vector3(busHalfLength - 0.1, 0.72, busMaxZ + 0.02),
      Vector3(busHalfLength - 0.1, 1.48, busMaxZ + 0.02),
      Vector3(-busHalfLength + 0.1, 1.48, busMaxZ + 0.02),
      config.primaryColor,
    );
    _addQuad(
      rig,
      polygons,
      Vector3(-busHalfLength + 0.1, 1.48, busMaxZ + 0.025),
      Vector3(busHalfLength - 0.1, 1.48, busMaxZ + 0.025),
      Vector3(busHalfLength - 0.1, 1.64, busMaxZ + 0.025),
      Vector3(-busHalfLength + 0.1, 1.64, busMaxZ + 0.025),
      config.accentColor,
    );

    // Okna pasażerskie (przyciemniane)
    final double winMinY = busHeight * 0.56;
    final double winMaxY = busHeight - 0.32;
    _addQuad(
      rig,
      polygons,
      Vector3(-busHalfLength + 0.7, winMinY, busMaxZ + 0.03),
      Vector3(busHalfLength - 1.1, winMinY, busMaxZ + 0.03),
      Vector3(busHalfLength - 1.1, winMaxY, busMaxZ + 0.03),
      Vector3(-busHalfLength + 0.7, winMaxY, busMaxZ + 0.03),
      const Color(0xFF0E1522),
      stroke: AppColors.accentBlue.withValues(alpha: 0.32),
      strokeWidth: 1.0,
    );

    // Przednia szyba (+X) i światła pozycyjne
    _addQuad(
      rig,
      polygons,
      Vector3(busHalfLength + 0.02, 1.35, busMinZ + 0.25),
      Vector3(busHalfLength + 0.02, 1.35, busMaxZ - 0.25),
      Vector3(busHalfLength + 0.02, busHeight - 0.35, busMaxZ - 0.25),
      Vector3(busHalfLength + 0.02, busHeight - 0.35, busMinZ + 0.25),
      const Color(0xFF101929),
      stroke: AppColors.cyanAccent.withValues(alpha: 0.35),
    );
    _addQuad(
      rig,
      polygons,
      Vector3(busHalfLength + 0.03, 0.72, busMaxZ - 0.55),
      Vector3(busHalfLength + 0.03, 0.72, busMaxZ - 0.18),
      Vector3(busHalfLength + 0.03, 0.90, busMaxZ - 0.18),
      Vector3(busHalfLength + 0.03, 0.90, busMaxZ - 0.55),
      weather.isRaining ? AppColors.cyanAccent : AppColors.goldAccent,
    );

    // Jednostki klimatyzacji na dachu
    final int acCount = tier == TeamBusTier.continentalMinibus ? 1 : 2;
    for (int i = 0; i < acCount; i++) {
      final double acX = acCount == 1 ? 0.0 : (i == 0 ? -2.2 : 2.1);
      _addBox3D(
        rig,
        polygons,
        minX: acX - 0.7,
        maxX: acX + 0.7,
        minY: busHeight,
        maxY: busHeight + 0.26,
        minZ: -1.6,
        maxZ: -0.6,
        frontColor: const Color(0xFF2D3340),
        sideColor: const Color(0xFF232833),
        topColor: const Color(0xFF3A4152),
      );
    }

    // Koła autokaru
    final List<double> wheelXs = tier == TeamBusTier.continentalMinibus
        ? [-2.0, 2.0]
        : tier == TeamBusTier.proTeamTourBus
            ? [-3.5, 3.3]
            : [-4.9, -3.5, 4.4];
    for (final wx in wheelXs) {
      _addQuad(
        rig,
        polygons,
        Vector3(wx - 0.45, 0.02, busMaxZ + 0.03),
        Vector3(wx + 0.45, 0.02, busMaxZ + 0.03),
        Vector3(wx + 0.45, 0.88, busMaxZ + 0.03),
        Vector3(wx - 0.45, 0.88, busMaxZ + 0.03),
        const Color(0xFF12141A),
        stroke: AppColors.textSecondary.withValues(alpha: 0.4),
      );
      _addQuad(
        rig,
        polygons,
        Vector3(wx - 0.24, 0.22, busMaxZ + 0.04),
        Vector3(wx + 0.24, 0.22, busMaxZ + 0.04),
        Vector3(wx + 0.24, 0.68, busMaxZ + 0.04),
        Vector3(wx - 0.24, 0.68, busMaxZ + 0.04),
        const Color(0xFF475569),
      );
    }

    // Dioda zasilania zespołu na boku autobusu (pulsująca subtelnie)
    final double pulse = 0.6 + 0.4 * math.sin(timeSeconds * 3.0);
    _addLine(
      rig,
      segments,
      Vector3(-busHalfLength + 0.4, 0.60, busMaxZ + 0.03),
      Vector3(busHalfLength - 0.4, 0.60, busMaxZ + 0.03),
      AppColors.cyanAccent.withValues(alpha: 0.25 * pulse),
      width: 2.0,
    );
  }

  void _buildAwningAndSupportPoles(
    _PaddockCameraRig rig,
    List<_SortedPolygon3D> polygons,
    List<_SortedSegment3D> segments,
    int totalSlots,
    PaddockWeatherPreset weather,
  ) {
    final double halfSpan = math.max(3.2, totalSlots * 0.72);
    const double busEdgeZ = 0.26;
    const double awningOuterZ = 4.05;
    const double innerY = 3.15;
    const double outerY = 2.65;

    // Cień markizy na asfalcie
    _addQuad(
      rig,
      polygons,
      Vector3(-halfSpan, 0.015, busEdgeZ),
      Vector3(halfSpan, 0.015, busEdgeZ),
      Vector3(halfSpan, 0.015, awningOuterZ + 0.25),
      Vector3(-halfSpan, 0.015, awningOuterZ + 0.25),
      Colors.black.withValues(alpha: 0.28),
    );

    // Płachta markizy drużynowej
    _addQuad(
      rig,
      polygons,
      Vector3(-halfSpan, innerY, busEdgeZ),
      Vector3(halfSpan, innerY, busEdgeZ),
      Vector3(halfSpan, outerY, awningOuterZ),
      Vector3(-halfSpan, outerY, awningOuterZ),
      Color.lerp(config.primaryColor, Colors.black, 0.25)!.withValues(alpha: 0.92),
      stroke: config.accentColor.withValues(alpha: 0.7),
      strokeWidth: 1.5,
    );

    // Przedni fartuch markizy
    _addQuad(
      rig,
      polygons,
      Vector3(-halfSpan, outerY - 0.26, awningOuterZ),
      Vector3(halfSpan, outerY - 0.26, awningOuterZ),
      Vector3(halfSpan, outerY, awningOuterZ),
      Vector3(-halfSpan, outerY, awningOuterZ),
      config.accentColor.withValues(alpha: 0.85),
    );

    // Boczne osłony w deszczu
    if (weather.isRaining) {
      _addQuad(
        rig,
        polygons,
        Vector3(-halfSpan, 0.15, busEdgeZ),
        Vector3(-halfSpan, 0.15, awningOuterZ),
        Vector3(-halfSpan, outerY, awningOuterZ),
        Vector3(-halfSpan, innerY, busEdgeZ),
        config.secondaryColor.withValues(alpha: 0.45),
        stroke: AppColors.cardBorder,
      );
    }

    // Aluminiowe słupki podporowe
    final poleXs = [-halfSpan + 0.15, 0.0, halfSpan - 0.15];
    for (final px in poleXs) {
      _addLine(
        rig,
        segments,
        Vector3(px, 0.0, awningOuterZ - 0.05),
        Vector3(px, outerY, awningOuterZ - 0.05),
        const Color(0xFF94A3B8),
        width: 3.0,
      );
    }
  }

  ProjectedRiderHitbox? _buildTrainerStationAndRider3D({
    required _PaddockCameraRig rig,
    required List<_SortedPolygon3D> polygons,
    required List<_SortedSegment3D> segments,
    required PaddockWarmupRider3D rider,
    required int slotIndex,
    required int totalSlots,
    required double timeSeconds,
    required bool isSelected,
    required bool isHovered,
  }) {
    final double rx = _slotWorldX(slotIndex, totalSlots);
    const double rz = 2.35; // Środek stanowiska trenażera pod markizą

    // Mata treningowa pod rowerem
    final Color matBorder = isSelected
        ? AppColors.goldAccent
        : (isHovered ? AppColors.accentBlue : AppColors.cardBorder);
    _addQuad(
      rig,
      polygons,
      Vector3(rx - 0.46, 0.02, rz - 0.92),
      Vector3(rx + 0.46, 0.02, rz - 0.92),
      Vector3(rx + 0.46, 0.02, rz + 0.92),
      Vector3(rx - 0.46, 0.02, rz + 0.92),
      isSelected
          ? AppColors.goldAccent.withValues(alpha: 0.22)
          : const Color(0xFF14171F),
      stroke: matBorder,
      strokeWidth: isSelected ? 2.2 : 1.0,
    );

    // Trenażer Smart / Direct-Drive / Rolki z tyłu (-Z)
    final zoneColor = AppColors.getPowerZoneColor(rider.powerZone);
    if (rider.trainerType == SmartTrainerType.rollers) {
      _addBox3D(
        rig,
        polygons,
        minX: rx - 0.24,
        maxX: rx + 0.24,
        minY: 0.03,
        maxY: 0.11,
        minZ: rz - 0.72,
        maxZ: rz + 0.62,
        frontColor: const Color(0xFF334155),
        sideColor: const Color(0xFF1E293B),
        topColor: const Color(0xFF475569),
      );
    } else {
      // Podstawa trenażera direct-drive + koło zamachowe + dioda strefy mocy
      _addBox3D(
        rig,
        polygons,
        minX: rx - 0.28,
        maxX: rx + 0.28,
        minY: 0.03,
        maxY: 0.36,
        minZ: rz - 0.68,
        maxZ: rz - 0.30,
        frontColor: const Color(0xFF1F2430),
        sideColor: const Color(0xFF151922),
        topColor: const Color(0xFF2D3445),
        strokeColor: zoneColor.withValues(alpha: 0.8),
      );
      // Podstawka pod przednie koło (Riser Block)
      _addBox3D(
        rig,
        polygons,
        minX: rx - 0.12,
        maxX: rx + 0.12,
        minY: 0.03,
        maxY: 0.12,
        minZ: rz + 0.44,
        maxZ: rz + 0.68,
        frontColor: const Color(0xFF282E3D),
        sideColor: const Color(0xFF1B1F2A),
        topColor: const Color(0xFF363E52),
      );
    }

    // Geometria roweru skierowanego przodem (+Z) w stronę paddocku
    final Vector3 rearAxle = Vector3(rx, 0.35, rz - 0.50);
    final Vector3 frontAxle = Vector3(rx, 0.35, rz + 0.54);
    final Vector3 bottomBracket = Vector3(rx, 0.29, rz - 0.06);
    final Vector3 seatCluster = Vector3(rx, 0.82, rz - 0.24);
    final Vector3 saddle = Vector3(rx, 0.96, rz - 0.28);
    final Vector3 headTubeTop = Vector3(rx, 0.85, rz + 0.36);
    final Vector3 handlebar = Vector3(rx, 0.88, rz + 0.45);

    // Przednie koło (kręci się na rolkach, nieruchome na direct-drive)
    _buildWheelSegments(
      rig,
      segments,
      center: frontAxle,
      radius: 0.33,
      spinAngle: rider.trainerType == SmartTrainerType.rollers
          ? timeSeconds * (rider.cadenceRpm / 60.0) * math.pi * 2.0
          : 0.0,
      rimColor: const Color(0xFF94A3B8),
    );
    if (rider.trainerType == SmartTrainerType.rollers) {
      _buildWheelSegments(
        rig,
        segments,
        center: rearAxle,
        radius: 0.33,
        spinAngle: timeSeconds * (rider.cadenceRpm / 60.0) * math.pi * 2.0,
        rimColor: const Color(0xFF94A3B8),
      );
    }

    // Rama roweru (trójkąt główny + widelec)
    final Color frameColor =
        rider.isLeader ? AppColors.goldAccent : config.primaryColor;
    _addLine(rig, segments, rearAxle, bottomBracket, frameColor, width: 2.6);
    _addLine(rig, segments, rearAxle, seatCluster, frameColor, width: 2.4);
    _addLine(rig, segments, bottomBracket, seatCluster, frameColor, width: 2.8);
    _addLine(rig, segments, seatCluster, headTubeTop, frameColor, width: 2.8);
    _addLine(rig, segments, bottomBracket, headTubeTop, frameColor, width: 3.0);
    _addLine(rig, segments, headTubeTop, frontAxle, frameColor, width: 2.6);
    _addLine(rig, segments, seatCluster, saddle, const Color(0xFF1E293B), width: 2.4);
    _addLine(rig, segments, headTubeTop, handlebar, const Color(0xFFCBD5E1), width: 2.4);

    // Animacja nóg i korby zgodnie z kadencją (RPM)
    final double crankOmega = (rider.cadenceRpm / 60.0) * math.pi * 2.0;
    final double crankPhase = timeSeconds * crankOmega + slotIndex * 0.9;
    const double crankRadius = 0.175;
    const double hipWidth = 0.11;

    final Vector3 hipCenter = Vector3(rx, 1.00, rz - 0.25);
    final Vector3 shoulderCenter = Vector3(rx, 1.32, rz + 0.14);
    final Vector3 headCenter = Vector3(rx, 1.50, rz + 0.24);

    // Lewa i prawa noga (przesunięte w fazie o PI)
    for (int side = -1; side <= 1; side += 2) {
      final double phase = side == 1 ? crankPhase : crankPhase + math.pi;
      final double pedalY = bottomBracket.y + crankRadius * math.sin(phase);
      final double pedalZ = bottomBracket.z + crankRadius * math.cos(phase);
      final double xOff = side * hipWidth;

      final Vector3 hip = Vector3(rx + xOff, hipCenter.y, hipCenter.z);
      final Vector3 pedal = Vector3(rx + xOff, pedalY, pedalZ);
      // Pozycja kolana z lekkim ruchem do przodu
      final Vector3 knee = Vector3(
        rx + xOff * 1.05,
        (hip.y + pedal.y) * 0.5 + 0.14,
        (hip.z + pedal.z) * 0.5 + 0.18,
      );

      _addLine(rig, segments, bottomBracket, pedal, const Color(0xFF94A3B8), width: 1.8);
      _addLine(rig, segments, hip, knee, const Color(0xFF1F2937), width: 4.5);
      _addLine(rig, segments, knee, pedal, const Color(0xFFE2C3A8), width: 3.6);
    }

    // Tułów kolarza (+ opcjonalna kamizelka chłodząca Ice Vest)
    final Color torsoColor =
        rider.hasIceVest ? AppColors.cyanAccent : rider.jerseyColor;
    _addLine(rig, segments, hipCenter, shoulderCenter, torsoColor, width: 7.5);

    // Ramiona na kierownicy
    for (int side = -1; side <= 1; side += 2) {
      final Vector3 shoulder =
          Vector3(rx + side * 0.16, shoulderCenter.y, shoulderCenter.z);
      final Vector3 hand =
          Vector3(rx + side * 0.18, handlebar.y + 0.02, handlebar.z);
      final Vector3 elbow = Vector3(
        rx + side * 0.19,
        (shoulder.y + hand.y) * 0.5 - 0.05,
        (shoulder.z + hand.z) * 0.5 - 0.04,
      );
      _addLine(rig, segments, shoulder, elbow, rider.jerseyColor, width: 3.4);
      _addLine(rig, segments, elbow, hand, const Color(0xFFE2C3A8), width: 2.8);
    }

    // Głowa i kask aero
    _addLine(
      rig,
      segments,
      shoulderCenter,
      headCenter,
      const Color(0xFFE2C3A8),
      width: 3.5,
    );
    _addBox3D(
      rig,
      polygons,
      minX: rx - 0.10,
      maxX: rx + 0.10,
      minY: headCenter.y - 0.04,
      maxY: headCenter.y + 0.14,
      minZ: headCenter.z - 0.14,
      maxZ: headCenter.z + 0.12,
      frontColor: rider.helmetColor,
      sideColor: Color.lerp(rider.helmetColor, Colors.black, 0.2)!,
      topColor: rider.helmetColor,
    );

    // Wentylator podłogowy przed kolarzem
    if (config.showFansAndCooling && rider.hasFan) {
      final fanPos = Vector3(rx, 0.24, rz + 1.15);
      _addLine(
        rig,
        segments,
        Vector3(rx, 0.02, rz + 1.15),
        fanPos,
        const Color(0xFF475569),
        width: 2.2,
      );
      _addBox3D(
        rig,
        polygons,
        minX: rx - 0.18,
        maxX: rx + 0.18,
        minY: 0.16,
        maxY: 0.48,
        minZ: rz + 1.10,
        maxZ: rz + 1.22,
        frontColor: const Color(0xFF1E293B),
        sideColor: const Color(0xFF0F172A),
        topColor: const Color(0xFF334155),
        strokeColor: AppColors.accentBlue.withValues(alpha: 0.65),
      );
      // Wirujące łopatki wentylatora
      final double bladeAngle = timeSeconds * 16.0 + slotIndex;
      for (int b = 0; b < 3; b++) {
        final a = bladeAngle + b * (math.pi * 2.0 / 3.0);
        _addLine(
          rig,
          segments,
          Vector3(rx, 0.32, rz + 1.09),
          Vector3(rx + math.cos(a) * 0.14, 0.32 + math.sin(a) * 0.14, rz + 1.09),
          AppColors.cyanAccent.withValues(alpha: 0.8),
          width: 2.0,
        );
      }
    }

    // Wyliczenie prostokąta hit-testu na ekranie
    final pHead = rig.project(headCenter + Vector3(0, 0.18, 0));
    final pBase = rig.project(Vector3(rx, 0.0, rz));
    if (pHead != null && pBase != null) {
      final double h = (pBase.dy - pHead.dy).abs().clamp(28.0, 240.0);
      final double w = (h * 0.58).clamp(24.0, 140.0);
      final center = Offset((pHead.dx + pBase.dx) * 0.5, (pHead.dy + pBase.dy) * 0.5);
      return ProjectedRiderHitbox(
        riderId: rider.riderId,
        slotIndex: slotIndex,
        screenRect: Rect.fromCenter(center: center, width: w, height: h),
        depthMeters: rig.depthOf(Vector3(rx, 0.8, rz)),
      );
    }
    return null;
  }

  void _buildWheelSegments(
    _PaddockCameraRig rig,
    List<_SortedSegment3D> segments, {
    required Vector3 center,
    required double radius,
    required double spinAngle,
    required Color rimColor,
  }) {
    const int rimSteps = 10;
    Vector3? prev;
    for (int i = 0; i <= rimSteps; i++) {
      final a = (i / rimSteps) * math.pi * 2.0;
      final pt = Vector3(
        center.x,
        center.y + math.sin(a) * radius,
        center.z + math.cos(a) * radius,
      );
      if (prev != null) {
        _addLine(rig, segments, prev, pt, const Color(0xFF0F172A), width: 2.8);
      }
      prev = pt;
    }
    // 4 szprychy ilustrujące obrót
    for (int s = 0; s < 4; s++) {
      final a = spinAngle + s * (math.pi * 0.5);
      final pt = Vector3(
        center.x,
        center.y + math.sin(a) * (radius - 0.03),
        center.z + math.cos(a) * (radius - 0.03),
      );
      _addLine(rig, segments, center, pt, rimColor.withValues(alpha: 0.65), width: 1.2);
    }
  }

  void _buildMechanicsAndSpareWheels(
    _PaddockCameraRig rig,
    List<_SortedPolygon3D> polygons,
    List<_SortedSegment3D> segments,
    double timeSeconds,
    PaddockWeatherPreset weather,
    int totalSlots,
  ) {
    final double rightEdge = math.max(3.6, totalSlots * 0.72) + 0.9;
    // Stojak mechanika z zapasowymi kołami
    _addLine(
      rig,
      segments,
      Vector3(rightEdge, 0.0, 1.4),
      Vector3(rightEdge, 1.15, 1.4),
      const Color(0xFF94A3B8),
      width: 2.6,
    );
    _addLine(
      rig,
      segments,
      Vector3(rightEdge - 0.45, 0.95, 1.4),
      Vector3(rightEdge + 0.45, 0.95, 1.4),
      AppColors.goldAccent,
      width: 2.4,
    );
    _buildWheelSegments(
      rig,
      segments,
      center: Vector3(rightEdge - 0.35, 0.36, 2.05),
      radius: 0.33,
      spinAngle: 0.2,
      rimColor: AppColors.goldAccent,
    );

    // Flaga drużynowa falująca na wietrze po lewej stronie paddocku
    final double leftFlagX = -math.max(3.6, totalSlots * 0.72) - 0.85;
    final double sway =
        math.sin(timeSeconds * (2.2 + weather.windSpeedMps * 0.35)) *
            (0.08 + weather.windSpeedMps * 0.025);
    _addLine(
      rig,
      segments,
      Vector3(leftFlagX, 0.0, 3.85),
      Vector3(leftFlagX, 3.45, 3.85),
      const Color(0xFFCBD5E1),
      width: 2.4,
    );
    _addQuad(
      rig,
      polygons,
      Vector3(leftFlagX, 2.25, 3.85),
      Vector3(leftFlagX + 0.75 + sway, 2.35, 3.85 + sway * 0.7),
      Vector3(leftFlagX + 0.72 + sway * 1.2, 3.35, 3.85 + sway),
      Vector3(leftFlagX, 3.40, 3.85),
      config.primaryColor,
      stroke: config.accentColor,
    );
  }

  void _buildBarriersAndSpectators(
    _PaddockCameraRig rig,
    List<_SortedPolygon3D> polygons,
    List<_SortedSegment3D> segments,
    double timeSeconds,
    int totalSlots,
  ) {
    final double halfSpan = math.max(4.2, totalSlots * 0.78);
    const double barrierZ = 5.15;
    final int barrierCount = (halfSpan * 2.0 / 2.2).ceil().clamp(4, 8);
    final double segLen = (halfSpan * 2.0) / barrierCount;

    for (int i = 0; i < barrierCount; i++) {
      final double x0 = -halfSpan + i * segLen;
      final double x1 = x0 + segLen - 0.08;
      // Nogi barierki
      _addLine(rig, segments, Vector3(x0, 0.0, barrierZ), Vector3(x0, 1.02, barrierZ), const Color(0xFF64748B), width: 2.0);
      _addLine(rig, segments, Vector3(x1, 0.0, barrierZ), Vector3(x1, 1.02, barrierZ), const Color(0xFF64748B), width: 2.0);
      // Baner sponsorski na barierce
      _addQuad(
        rig,
        polygons,
        Vector3(x0, 0.28, barrierZ),
        Vector3(x1, 0.28, barrierZ),
        Vector3(x1, 0.96, barrierZ),
        Vector3(x0, 0.96, barrierZ),
        i.isEven ? AppColors.surfaceLight : config.secondaryColor,
        stroke: config.accentColor.withValues(alpha: 0.6),
      );
    }

    // Kibice za barierkami (sylwetki z delikatnym ruchem)
    for (int s = 0; s < barrierCount + 1; s++) {
      final double sx = -halfSpan + 0.6 + s * (segLen * 0.92);
      final double sz = barrierZ + 0.55 + (s % 2) * 0.35;
      final double bob = math.sin(timeSeconds * 2.4 + s * 1.3) * 0.03;
      final Color jacket = s % 3 == 0
          ? config.primaryColor
          : (s % 3 == 1 ? const Color(0xFF334155) : const Color(0xFF475569));
      _addLine(
        rig,
        segments,
        Vector3(sx, 0.0, sz),
        Vector3(sx, 1.48 + bob, sz),
        jacket,
        width: 7.0,
      );
      _addLine(
        rig,
        segments,
        Vector3(sx, 1.48 + bob, sz),
        Vector3(sx, 1.66 + bob, sz),
        const Color(0xFFD8B89C),
        width: 4.5,
      );
    }
  }

  void _paintBusBrandingAndRiderCallout({
    required Canvas canvas,
    required _PaddockCameraRig rig,
    required PaddockWarmupRider3D? selectedRider,
    required int totalSlots,
  }) {
    // Skrót zespołu na górnej części boku autokaru
    final busLabelPos = rig.project(Vector3(0.0, 2.95, 0.28));
    if (busLabelPos != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: config.teamShortCode,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
            color: config.accentColor.withValues(alpha: 0.92),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(busLabelPos.dx - tp.width * 0.5, busLabelPos.dy - tp.height * 0.5),
      );
    }

    // Etykieta nad wybranym kolarzem w przestrzeni 3D
    if (selectedRider != null) {
      final rx = _slotWorldX(selectedRider.slotIndex, totalSlots);
      final calloutPos = rig.project(Vector3(rx, 1.88, 2.35));
      if (calloutPos != null) {
        final zoneColor = AppColors.getPowerZoneColor(selectedRider.powerZone);
        final text =
            '#${selectedRider.bibNumber} ${selectedRider.riderName} • ${selectedRider.currentPowerWatts.round()}W';
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final pillRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: calloutPos,
            width: tp.width + 18,
            height: 22,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          pillRect,
          Paint()..color = AppColors.surface.withValues(alpha: 0.92),
        );
        canvas.drawRRect(
          pillRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = zoneColor,
        );
        tp.paint(
          canvas,
          Offset(calloutPos.dx - tp.width * 0.5, calloutPos.dy - tp.height * 0.5),
        );
      }
    }
  }

  void _paintRainStreaks(Canvas canvas, Size size, double timeSeconds) {
    final paint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.22)
      ..strokeWidth = 1.1;
    for (int i = 0; i < 42; i++) {
      final double x = ((i * 73.0 + timeSeconds * 160.0) % size.width);
      final double y = ((i * 119.0 + timeSeconds * 540.0) % size.height);
      canvas.drawLine(Offset(x, y), Offset(x - 6, y + 18), paint);
    }
  }
}

// =============================================================================
// 4. CUSTOM PAINTER & INTERAKTYWNY WIDGET SCENY PADDOCKU 3D
// =============================================================================

/// `CustomPainter` renderujący interaktywną scenę 3D paddocku i autobusu drużyny.
class TeamBusPaddock3dPainter extends CustomPainter {
  final TeamBusPaddock3dSceneRenderer renderer;
  final double timeSeconds;
  final List<PaddockWarmupRider3D> riders;
  final String? selectedRiderId;
  final String? hoveredRiderId;
  final double cameraYawOffsetRadians;
  final double cameraPitchOffsetRadians;
  final double cameraDistanceOffsetMeters;
  final ValueChanged<PaddockSceneTelemetry>? onTelemetryUpdated;

  const TeamBusPaddock3dPainter({
    required this.renderer,
    required this.timeSeconds,
    required this.riders,
    this.selectedRiderId,
    this.hoveredRiderId,
    this.cameraYawOffsetRadians = 0.0,
    this.cameraPitchOffsetRadians = 0.0,
    this.cameraDistanceOffsetMeters = 0.0,
    this.onTelemetryUpdated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final telemetry = renderer.paintScene(
      canvas: canvas,
      size: size,
      timeSeconds: timeSeconds,
      riders: riders,
      selectedRiderId: selectedRiderId,
      hoveredRiderId: hoveredRiderId,
      cameraYawOffsetRadians: cameraYawOffsetRadians,
      cameraPitchOffsetRadians: cameraPitchOffsetRadians,
      cameraDistanceOffsetMeters: cameraDistanceOffsetMeters,
    );
    onTelemetryUpdated?.call(telemetry);
  }

  @override
  bool shouldRepaint(covariant TeamBusPaddock3dPainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.hoveredRiderId != hoveredRiderId ||
        oldDelegate.cameraYawOffsetRadians != cameraYawOffsetRadians ||
        oldDelegate.cameraPitchOffsetRadians != cameraPitchOffsetRadians ||
        oldDelegate.cameraDistanceOffsetMeters != cameraDistanceOffsetMeters ||
        oldDelegate.riders != riders ||
        oldDelegate.renderer.config != renderer.config;
  }
}

/// Kompletny, responsywny widget sceny 3D Paddocku i Autobusu Drużyny
/// (`390x844`, `1024x768`, `1600x900`) z obsługą orbity myszą/dotykiem,
/// wyborem kolarza w 3D, zmianą protokołu rozgrzewki i stanami `hover`/`active`/`disabled`/`focus`.
class TeamBusPaddock3dViewportWidget extends StatefulWidget {
  final TeamBusPaddock3dConfig initialConfig;
  final List<PaddockWarmupRider3D>? initialRiders;
  final bool autoPlay;
  final ValueChanged<PaddockWarmupRider3D>? onRiderSelected;

  const TeamBusPaddock3dViewportWidget({
    super.key,
    this.initialConfig = const TeamBusPaddock3dConfig(),
    this.initialRiders,
    this.autoPlay = true,
    this.onRiderSelected,
  });

  @override
  State<TeamBusPaddock3dViewportWidget> createState() =>
      _TeamBusPaddock3dViewportWidgetState();
}

class _TeamBusPaddock3dViewportWidgetState
    extends State<TeamBusPaddock3dViewportWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late TeamBusPaddock3dConfig _config;
  late List<PaddockWarmupRider3D> _riders;
  late String _selectedRiderId;
  String? _hoveredRiderId;
  bool _isPaused = false;
  double _cameraYawOffset = 0.0;
  double _cameraPitchOffset = 0.0;
  double _cameraDistanceOffset = 0.0;
  PaddockSceneTelemetry? _latestTelemetry;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _riders = widget.initialRiders != null && widget.initialRiders!.isNotEmpty
        ? List<PaddockWarmupRider3D>.from(widget.initialRiders!)
        : PaddockWarmupRider3D.buildDefaultRoster(
            busTier: _config.busTier,
            teamJerseyColor: _config.primaryColor,
          );
    _selectedRiderId = _riders.first.riderId;
    _isPaused = !widget.autoPlay;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    if (widget.autoPlay) {
      _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _animController.stop();
      } else {
        _animController.repeat();
      }
    });
  }

  void _resetCamera() {
    setState(() {
      _cameraYawOffset = 0.0;
      _cameraPitchOffset = 0.0;
      _cameraDistanceOffset = 0.0;
    });
  }

  void _selectBusTier(TeamBusTier tier) {
    setState(() {
      _config = _config.copyWith(busTier: tier);
      if (widget.initialRiders == null) {
        _riders = PaddockWarmupRider3D.buildDefaultRoster(
          busTier: tier,
          teamJerseyColor: _config.primaryColor,
        );
        if (!_riders.any((r) => r.riderId == _selectedRiderId)) {
          _selectedRiderId = _riders.first.riderId;
        }
      }
    });
  }

  void _updateSelectedRiderProtocol(WarmupProtocolType protocol) {
    setState(() {
      _riders = _riders.map((r) {
        if (r.riderId != _selectedRiderId) return r;
        final ratio = switch (protocol) {
          WarmupProtocolType.none => 0.0,
          WarmupProtocolType.lightSpinActivation => 0.52,
          WarmupProtocolType.progressiveRamp => 0.68,
          WarmupProtocolType.vo2PrimingItt => 0.94,
          WarmupProtocolType.mountainStartOpener => 0.82,
          WarmupProtocolType.sprintNeuromuscularPriming => 0.78,
        };
        return r.copyWith(
          protocolType: protocol,
          currentPowerWatts: (r.ftpWatts * ratio).roundToDouble(),
          cadenceRpm: protocol == WarmupProtocolType.none ? 0.0 : 94.0,
          heartRateBpm: protocol == WarmupProtocolType.none
              ? 68
              : (118 + ratio * 56).round(),
        );
      }).toList(growable: false);
    });
  }

  void _updateSelectedRiderCooling(CoolingStrategyType cooling) {
    setState(() {
      _riders = _riders.map((r) {
        if (r.riderId != _selectedRiderId) return r;
        return r.copyWith(
          coolingStrategy: cooling,
          coreTempCelsius:
              (37.9 - cooling.coreTempReductionCelsius).clamp(36.8, 39.2),
        );
      }).toList(growable: false);
    });
  }

  PaddockWarmupRider3D get _selectedRider {
    for (final r in _riders) {
      if (r.riderId == _selectedRiderId) return r;
    }
    return _riders.first;
  }

  String? _hitTestRider(Offset localPos) {
    final boxes = _latestTelemetry?.riderHitboxes;
    if (boxes == null || boxes.isEmpty) return null;
    ProjectedRiderHitbox? best;
    for (final box in boxes) {
      if (box.screenRect.contains(localPos)) {
        if (best == null || box.depthMeters < best.depthMeters) {
          best = box;
        }
      }
    }
    return best?.riderId;
  }

  @override
  Widget build(BuildContext context) {
    final renderer = TeamBusPaddock3dSceneRenderer(config: _config);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 760.0;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: isCompact
              ? Column(
                  children: [
                    Expanded(flex: 3, child: _buildCanvasArea(renderer)),
                    Container(
                      height: 1,
                      color: AppColors.cardBorder,
                    ),
                    Flexible(
                      flex: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: _buildControlsPanel(isCompact: true),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 7, child: _buildCanvasArea(renderer)),
                    Container(
                      width: 1,
                      color: AppColors.cardBorder,
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 1250 ? 370 : 320,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildControlsPanel(isCompact: false),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCanvasArea(TeamBusPaddock3dSceneRenderer renderer) {
    return Stack(
      children: [
        Positioned.fill(
          child: MouseRegion(
            cursor: _hoveredRiderId != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.grab,
            onHover: (event) {
              final hit = _hitTestRider(event.localPosition);
              if (hit != _hoveredRiderId) {
                setState(() => _hoveredRiderId = hit);
              }
            },
            onExit: (_) {
              if (_hoveredRiderId != null) {
                setState(() => _hoveredRiderId = null);
              }
            },
            child: GestureDetector(
              onTapDown: (details) {
                final hit = _hitTestRider(details.localPosition);
                if (hit != null) {
                  setState(() => _selectedRiderId = hit);
                  widget.onRiderSelected?.call(_selectedRider);
                }
              },
              onPanUpdate: (details) {
                setState(() {
                  _cameraYawOffset -= details.delta.dx * 0.008;
                  _cameraPitchOffset =
                      (_cameraPitchOffset + details.delta.dy * 0.005)
                          .clamp(-0.20, 0.75);
                });
              },
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: TeamBusPaddock3dPainter(
                      renderer: renderer,
                      timeSeconds: _animController.value * 60.0,
                      riders: _riders,
                      selectedRiderId: _selectedRiderId,
                      hoveredRiderId: _hoveredRiderId,
                      cameraYawOffsetRadians: _cameraYawOffset,
                      cameraPitchOffsetRadians: _cameraPitchOffset,
                      cameraDistanceOffsetMeters: _cameraDistanceOffset,
                      onTelemetryUpdated: (telemetry) {
                        _latestTelemetry = telemetry;
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_config.showTelemetryOverlay)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: _buildTopHudBar(),
            ),
          ),
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: _buildCameraQuickStrip(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHudBar() {
    final rider = _selectedRider;
    final zoneColor = AppColors.getPowerZoneColor(rider.powerZone);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PaddockHudPill(
          label: _config.teamShortCode,
          value: _config.busTier.displayNamePl.split('(').first.trim(),
          accentColor: _config.accentColor,
        ),
        _PaddockHudPill(
          label: 'KOLARZ #${rider.bibNumber}',
          value:
              '${rider.currentPowerWatts.round()}W • ${rider.cadenceRpm.round()} RPM • Z${rider.powerZone}',
          accentColor: zoneColor,
        ),
        _PaddockHudPill(
          label: 'FIZJO',
          value:
              '${rider.heartRateBpm} BPM • ${rider.coreTempCelsius.toStringAsFixed(1)}°C',
          accentColor: rider.hasIceVest
              ? AppColors.cyanAccent
              : AppColors.statusSuccess,
        ),
      ],
    );
  }

  Widget _buildCameraQuickStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _PaddockInteractiveButton(
            label: _isPaused ? 'Wznów' : 'Pauza',
            icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            isActive: !_isPaused,
            onPressed: _togglePlayPause,
          ),
          _PaddockInteractiveButton(
            label: 'Zoom +',
            icon: Icons.zoom_in_rounded,
            isEnabled: _cameraDistanceOffset > -9.0,
            onPressed: () {
              setState(() {
                _cameraDistanceOffset =
                    (_cameraDistanceOffset - 1.5).clamp(-10.0, 8.0);
              });
            },
          ),
          _PaddockInteractiveButton(
            label: 'Zoom -',
            icon: Icons.zoom_out_rounded,
            isEnabled: _cameraDistanceOffset < 7.5,
            onPressed: () {
              setState(() {
                _cameraDistanceOffset =
                    (_cameraDistanceOffset + 1.5).clamp(-10.0, 8.0);
              });
            },
          ),
          _PaddockInteractiveButton(
            label: 'Reset',
            icon: Icons.center_focus_strong_rounded,
            isEnabled: _cameraYawOffset != 0.0 ||
                _cameraPitchOffset != 0.0 ||
                _cameraDistanceOffset != 0.0,
            onPressed: _resetCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel({required bool isCompact}) {
    final rider = _selectedRider;
    final visibleCount =
        math.min(_riders.length, _config.busTier.defaultTrainerSlots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PADDOCK & AUTOBUS 3D',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 12 : 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(height: 10),
        _buildSectionTitle('KAMERA SCENY'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: PaddockCameraMode.values.map((mode) {
            return _PaddockInteractiveButton(
              label: mode.labelPl,
              isActive: _config.cameraMode == mode,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(cameraMode: mode);
                  _cameraYawOffset = 0.0;
                  _cameraPitchOffset = 0.0;
                  _cameraDistanceOffset = 0.0;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('KLASA AUTOBUSU & POGODA'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TeamBusTier.values.map((tier) {
            return _PaddockInteractiveButton(
              label: '${tier.defaultTrainerSlots} stan.',
              isActive: _config.busTier == tier,
              onPressed: () => _selectBusTier(tier),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: PaddockWeatherPreset.values.map((preset) {
            return _PaddockInteractiveButton(
              label: preset.labelPl,
              isActive: _config.weatherPreset == preset,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(weatherPreset: preset);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('KOLARZE NA TRENAŻERACH ($visibleCount)'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _riders.take(visibleCount).map((r) {
            final isSel = r.riderId == rider.riderId;
            return _PaddockInteractiveButton(
              label: '#${r.bibNumber} ${r.riderName.split(' ').last}',
              isActive: isSel,
              onPressed: () {
                setState(() => _selectedRiderId = r.riderId);
                widget.onRiderSelected?.call(r);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('PROTOKÓŁ ROZGRZEWKI (${rider.riderName})'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: WarmupProtocolType.values.map((protocol) {
            return _PaddockInteractiveButton(
              label: protocol.displayNamePl.split('(').first.trim(),
              isActive: rider.protocolType == protocol,
              onPressed: () => _updateSelectedRiderProtocol(protocol),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle('CHŁODZENIE PRZEDSTARTOWE'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CoolingStrategyType.values.map((cooling) {
            return _PaddockInteractiveButton(
              label: cooling.displayNamePl,
              isActive: rider.coolingStrategy == cooling,
              onPressed: () => _updateSelectedRiderCooling(cooling),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _PaddockHudPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _PaddockHudPill({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.65),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Przycisk interaktywny z pełnymi stanami `hover`, `active`, `disabled` i `focus`.
class _PaddockInteractiveButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _PaddockInteractiveButton({
    required this.label,
    this.icon,
    this.isActive = false,
    this.isEnabled = true,
    required this.onPressed,
  });

  @override
  State<_PaddockInteractiveButton> createState() =>
      _PaddockInteractiveButtonState();
}

class _PaddockInteractiveButtonState extends State<_PaddockInteractiveButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled;
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (!enabled) {
      bgColor = AppColors.surface.withValues(alpha: 0.45);
      borderColor = AppColors.cardBorder.withValues(alpha: 0.45);
      textColor = AppColors.textSecondary.withValues(alpha: 0.45);
    } else if (widget.isActive) {
      bgColor = _isPressed
          ? AppColors.primaryAccent
          : AppColors.primaryAccent.withValues(alpha: _isHovered ? 0.95 : 0.82);
      borderColor = _isFocused ? AppColors.goldAccent : AppColors.goldAccent.withValues(alpha: 0.75);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = _isPressed
          ? AppColors.surfaceLight
          : (_isHovered
              ? AppColors.surfaceLight
              : AppColors.surface);
      borderColor = _isFocused
          ? AppColors.accentBlue
          : (_isHovered ? AppColors.goldAccent.withValues(alpha: 0.55) : AppColors.cardBorder);
      textColor = _isHovered ? AppColors.textPrimary : AppColors.textSecondary;
    }

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (value) => setState(() => _isHovered = value),
      onShowFocusHighlight: (value) => setState(() => _isFocused = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
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
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              enabled ? () => setState(() => _isPressed = false) : null,
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
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: textColor),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
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
