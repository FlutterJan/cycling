// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../events/road_hazards_and_spectator_incidents.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TYPY WYSEPEK, PROGÓW, PRZEJAZDÓW KOLEJOWYCH I MOTOCYKLI SĘDZIOWSKICH
// =============================================================================

/// Kierunek nakazu ominięcia wysepki rozdzielającej jezdnię (znaki C-9 / C-10 / C-11).
enum TrafficIslandPassDirection {
  /// Nakaz jazdy z prawej strony znaku (C-9).
  passRight('Nakaz jazdy z prawej (C-9)'),

  /// Nakaz jazdy z lewej strony znaku (C-10).
  passLeft('Nakaz jazdy z lewej (C-10)'),

  /// Nakaz jazdy z prawej lub lewej strony znaku (C-11).
  passEitherSide('Jazda z obu stron (C-11)');

  final String labelPl;

  const TrafficIslandPassDirection(this.labelPl);
}

/// Konfiguracja renderera 3D wysepek, progów zwalniających, torów i motocykli sędziowskich.
class TrafficIslandsAndRailwayConfig {
  final bool enabled;
  final double forwardVisibilityMeters;
  final double backwardVisibilityMeters;
  final bool showTrafficIslands;
  final bool showSpeedBumps;
  final bool showRailwayCrossings;
  final bool showMarshalMotos;
  final double flashFrequencyHz;
  final double whistlePulseHz;
  final double flagWaveHz;

  const TrafficIslandsAndRailwayConfig({
    this.enabled = true,
    this.forwardVisibilityMeters = 340.0,
    this.backwardVisibilityMeters = 30.0,
    this.showTrafficIslands = true,
    this.showSpeedBumps = true,
    this.showRailwayCrossings = true,
    this.showMarshalMotos = true,
    this.flashFrequencyHz = 2.2,
    this.whistlePulseHz = 3.0,
    this.flagWaveHz = 3.6,
  });

  TrafficIslandsAndRailwayConfig copyWith({
    bool? enabled,
    double? forwardVisibilityMeters,
    double? backwardVisibilityMeters,
    bool? showTrafficIslands,
    bool? showSpeedBumps,
    bool? showRailwayCrossings,
    bool? showMarshalMotos,
    double? flashFrequencyHz,
    double? whistlePulseHz,
    double? flagWaveHz,
  }) {
    return TrafficIslandsAndRailwayConfig(
      enabled: enabled ?? this.enabled,
      forwardVisibilityMeters:
          forwardVisibilityMeters ?? this.forwardVisibilityMeters,
      backwardVisibilityMeters:
          backwardVisibilityMeters ?? this.backwardVisibilityMeters,
      showTrafficIslands: showTrafficIslands ?? this.showTrafficIslands,
      showSpeedBumps: showSpeedBumps ?? this.showSpeedBumps,
      showRailwayCrossings: showRailwayCrossings ?? this.showRailwayCrossings,
      showMarshalMotos: showMarshalMotos ?? this.showMarshalMotos,
      flashFrequencyHz: flashFrequencyHz ?? this.flashFrequencyHz,
      whistlePulseHz: whistlePulseHz ?? this.whistlePulseHz,
      flagWaveHz: flagWaveHz ?? this.flagWaveHz,
    );
  }
}

/// Wysepka rozdzielająca jezdnię 3D z krawężnikiem, pachołkami i znakiem nakazu jazdy.
class TrafficIsland3D {
  final String id;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double lengthMeters;
  final double widthMeters;
  final double curbHeightMeters;
  final TrafficIslandPassDirection passDirection;
  final bool hasYellowCones;
  final int coneCount;
  final bool hasBollardBeacon;

  const TrafficIsland3D({
    required this.id,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    this.lateralOffsetMeters = 0.0,
    this.lengthMeters = 7.5,
    this.widthMeters = 1.25,
    this.curbHeightMeters = 0.16,
    this.passDirection = TrafficIslandPassDirection.passRight,
    this.hasYellowCones = true,
    this.coneCount = 4,
    this.hasBollardBeacon = true,
  });
}

/// Próg zwalniający 3D (żółto-czarne pasy ostrzegawcze w poprzek szosy).
class SpeedBump3D {
  final String id;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final double widthMeters;
  final double lengthMeters;
  final double heightMeters;
  final int stripeCount;
  final bool hasWarningSign;

  const SpeedBump3D({
    required this.id,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    this.widthMeters = 6.8,
    this.lengthMeters = 1.1,
    this.heightMeters = 0.10,
    this.stripeCount = 10,
    this.hasWarningSign = true,
  });
}

/// Przejazd kolejowy 3D z torami, podkładami, rogatkami i migającymi czerwonymi światłami.
class RailwayCrossing3D {
  final String id;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final double trackGaugeMeters;
  final double roadSpanMeters;
  final double crossingAngleRadians;
  final RailwayBarrierState barrierState;
  final double barrierClosureProgress;
  final bool lightsActive;

  const RailwayCrossing3D({
    required this.id,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    this.trackGaugeMeters = 1.435,
    this.roadSpanMeters = 9.0,
    this.crossingAngleRadians = 0.18,
    this.barrierState = RailwayBarrierState.warningLightsFlashing,
    this.barrierClosureProgress = 0.0,
    this.lightsActive = true,
  });

  RailwayCrossing3D copyWith({
    RailwayBarrierState? barrierState,
    double? barrierClosureProgress,
    bool? lightsActive,
  }) {
    return RailwayCrossing3D(
      id: id,
      worldPosition: worldPosition,
      tangent: tangent,
      lateralRight: lateralRight,
      surfaceNormal: surfaceNormal,
      distanceAlongCourseMeters: distanceAlongCourseMeters,
      trackGaugeMeters: trackGaugeMeters,
      roadSpanMeters: roadSpanMeters,
      crossingAngleRadians: crossingAngleRadians,
      barrierState: barrierState ?? this.barrierState,
      barrierClosureProgress:
          barrierClosureProgress ?? this.barrierClosureProgress,
      lightsActive: lightsActive ?? this.lightsActive,
    );
  }
}

/// Motocykl sędziego / pilota wyścigu ostrzegającego peleton gwizdkiem i żółtą chorągiewką.
class CommissaireMarshalMoto3D {
  final String id;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double speedMs;
  final bool isWarningActive;
  final double whistlePulsePhase;
  final double flagWavePhase;
  final String marshalLabel;

  const CommissaireMarshalMoto3D({
    required this.id,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    this.lateralOffsetMeters = 1.9,
    this.speedMs = 13.5,
    this.isWarningActive = true,
    this.whistlePulsePhase = 0.0,
    this.flagWavePhase = 0.0,
    this.marshalLabel = 'MOTO SĘDZIA',
  });

  CommissaireMarshalMoto3D copyWith({
    Vector3? worldPosition,
    double? distanceAlongCourseMeters,
    bool? isWarningActive,
    double? whistlePulsePhase,
    double? flagWavePhase,
  }) {
    return CommissaireMarshalMoto3D(
      id: id,
      worldPosition: worldPosition ?? this.worldPosition,
      tangent: tangent,
      lateralRight: lateralRight,
      surfaceNormal: surfaceNormal,
      distanceAlongCourseMeters:
          distanceAlongCourseMeters ?? this.distanceAlongCourseMeters,
      lateralOffsetMeters: lateralOffsetMeters,
      speedMs: speedMs,
      isWarningActive: isWarningActive ?? this.isWarningActive,
      whistlePulsePhase: whistlePulsePhase ?? this.whistlePulsePhase,
      flagWavePhase: flagWavePhase ?? this.flagWavePhase,
      marshalLabel: marshalLabel,
    );
  }
}

/// Zbiorczy pakiet przeszkód drogowych, torów i motocykli sędziowskich dla etapu.
class StageTrafficIslandsAndRailwayPack {
  final String stageId;
  final List<TrafficIsland3D> islands;
  final List<SpeedBump3D> speedBumps;
  final List<RailwayCrossing3D> railwayCrossings;
  final List<CommissaireMarshalMoto3D> marshalMotos;

  const StageTrafficIslandsAndRailwayPack({
    required this.stageId,
    required this.islands,
    required this.speedBumps,
    required this.railwayCrossings,
    required this.marshalMotos,
  });

  bool get isEmpty =>
      islands.isEmpty &&
      speedBumps.isEmpty &&
      railwayCrossings.isEmpty &&
      marshalMotos.isEmpty;

  int get totalObjects =>
      islands.length +
      speedBumps.length +
      railwayCrossings.length +
      marshalMotos.length;
}

/// Telemetria pojedynczej klatki renderera 3D.
class TrafficIslandsAndRailwayTelemetry {
  final int visibleIslandsCount;
  final int visibleSpeedBumpsCount;
  final int visibleRailwaysCount;
  final int visibleMarshalMotosCount;
  final int activeRedLightsCount;
  final int activeWhistleAlertsCount;
  final double? nearestHazardDistanceMeters;

  const TrafficIslandsAndRailwayTelemetry({
    this.visibleIslandsCount = 0,
    this.visibleSpeedBumpsCount = 0,
    this.visibleRailwaysCount = 0,
    this.visibleMarshalMotosCount = 0,
    this.activeRedLightsCount = 0,
    this.activeWhistleAlertsCount = 0,
    this.nearestHazardDistanceMeters,
  });
}

enum _SortableElementKind {
  island,
  speedBump,
  railway,
  marshalMoto,
}

class _SortableRenderItem {
  final _SortableElementKind kind;
  final int index;
  final double depthEye;
  final double distanceAlongCourse;

  const _SortableRenderItem({
    required this.kind,
    required this.index,
    required this.depthEye,
    required this.distanceAlongCourse,
  });
}

// =============================================================================
// 2. GŁÓWNY RENDERER 3D WYSEPEK, PROGÓW, TORÓW I SĘDZIÓW NA MOTOCYKLACH
// =============================================================================

/// Wysokowydajny renderer 3D dla:
/// - wysepek rozdzielających jezdnię ze znakami nakazu jazdy z prawej/lewej strony (C-9/C-10/C-11) i pachołkami,
/// - progów zwalniających z żółto-czarnymi pasami ostrzegawczymi,
/// - przejazdów kolejowych z torami, rogatkami i naprzemiennie migającymi czerwonymi światłami,
/// - motocykli sędziowskich ostrzegających peleton gwizdkiem (animowane fale akustyczne) i żółtą chorągiewką.
class TrafficIslandsAndRailway3dRenderer {
  TrafficIslandsAndRailwayConfig config;

  double _elapsedSeconds = 0.0;
  StageTrafficIslandsAndRailwayPack? _cachedPack;

  // Prealokowane obiekty Paint (Zero-GC podczas renderowania klatek)
  late final Paint _fillPaint;
  late final Paint _strokePaint;
  late final Paint _shadowPaint;
  late final Paint _glowPaint;

  final Map<String, TextPainter> _textCache = {};

  TrafficIslandsAndRailway3dRenderer({
    this.config = const TrafficIslandsAndRailwayConfig(),
  }) {
    _fillPaint = Paint()..style = PaintingStyle.fill;
    _strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.36)
      ..style = PaintingStyle.fill;
    _glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
  }

  double get elapsedSeconds => _elapsedSeconds;

  void clearCache() {
    _cachedPack = null;
  }

  /// Aktualizuje zegar animacji migających świateł kolejowych, fali gwizdka i ruchu chorągiewki.
  void stepAnimation(double dtSeconds) {
    if (dtSeconds <= 0.0 || dtSeconds.isNaN || dtSeconds.isInfinite) return;
    _elapsedSeconds += dtSeconds;
  }

  /// Generuje obiekty 3D dla etapu na podstawie stref [RoadHazardZone] lub geometrii etapu.
  StageTrafficIslandsAndRailwayPack spawnForStage(
    RaceStage stage, {
    List<RoadHazardZone>? hazardZones,
    Vector3 Function(double distanceMeters)? worldPositionAt,
    RoadGeometryParameters Function(double distanceMeters)? geometryAt,
  }) {
    if (_cachedPack != null &&
        _cachedPack!.stageId == stage.id &&
        hazardZones == null) {
      return _cachedPack!;
    }

    final totalMeters = stage.totalDistanceKm * 1000.0;
    if (totalMeters <= 0.0) {
      return StageTrafficIslandsAndRailwayPack(
        stageId: stage.id,
        islands: const [],
        speedBumps: const [],
        railwayCrossings: const [],
        marshalMotos: const [],
      );
    }

    (Vector3 pos, Vector3 tangent, Vector3 right, Vector3 normal) resolveFrame(
      double distM,
    ) {
      final clampedDist = distM.clamp(0.0, totalMeters);
      final pos = worldPositionAt != null
          ? worldPositionAt(clampedDist)
          : Vector3(
              0.0,
              _elevationAt(clampedDist, stage.segments),
              clampedDist,
            );
      final geom = geometryAt != null
          ? geometryAt(clampedDist)
          : RoadGeometryParameters(
              gradientPercent: _gradientAt(clampedDist, stage.segments),
            );
      final bearing = geom.roadBearingRadians;
      final slope = geom.slopeAngleRadians;
      final cosSlope = math.cos(slope);
      final sinSlope = math.sin(slope);

      final tangent = Vector3(
        math.sin(bearing) * cosSlope,
        sinSlope,
        math.cos(bearing) * cosSlope,
      )..normalize();

      final right = Vector3(
        math.cos(bearing),
        0.0,
        -math.sin(bearing),
      )..normalize();

      final normal = right.cross(tangent)..normalize();
      if (normal.y < 0) {
        normal.negate();
      }
      return (pos, tangent, right, normal);
    }

    final islands = <TrafficIsland3D>[];
    final speedBumps = <SpeedBump3D>[];
    final railways = <RailwayCrossing3D>[];
    final motos = <CommissaireMarshalMoto3D>[];

    if (hazardZones != null && hazardZones.isNotEmpty) {
      int idx = 0;
      for (final zone in hazardZones) {
        final distM = (zone.kilometerMark * 1000.0).clamp(0.0, totalMeters);
        final frame = resolveFrame(distM);

        if (zone.type == RoadHazardType.trafficIslandBottleneck) {
          final dir = idx % 3 == 0
              ? TrafficIslandPassDirection.passRight
              : idx % 3 == 1
                  ? TrafficIslandPassDirection.passLeft
                  : TrafficIslandPassDirection.passEitherSide;
          islands.add(
            TrafficIsland3D(
              id: '${stage.id}_island_${zone.id}',
              worldPosition: frame.$1,
              tangent: frame.$2,
              lateralRight: frame.$3,
              surfaceNormal: frame.$4,
              distanceAlongCourseMeters: distM,
              passDirection: dir,
              hasYellowCones: zone.hasYellowCones,
            ),
          );

          final motoDist = math.max(0.0, distM - 38.0);
          final motoFrame = resolveFrame(motoDist);
          motos.add(
            CommissaireMarshalMoto3D(
              id: '${stage.id}_moto_${zone.id}',
              worldPosition: motoFrame.$1 + motoFrame.$3 * 1.9,
              tangent: motoFrame.$2,
              lateralRight: motoFrame.$3,
              surfaceNormal: motoFrame.$4,
              distanceAlongCourseMeters: motoDist,
              lateralOffsetMeters: 1.9,
              isWarningActive: true,
              marshalLabel: 'UWAGA WYSEPKA',
            ),
          );
        } else if (zone.type == RoadHazardType.railwayLevelCrossing) {
          final barrierProgress = switch (zone.railwayBarrierState) {
            RailwayBarrierState.open => 0.0,
            RailwayBarrierState.warningLightsFlashing => 0.12,
            RailwayBarrierState.closing => 0.65,
            RailwayBarrierState.closed => 1.0,
          };
          railways.add(
            RailwayCrossing3D(
              id: '${stage.id}_rail_${zone.id}',
              worldPosition: frame.$1,
              tangent: frame.$2,
              lateralRight: frame.$3,
              surfaceNormal: frame.$4,
              distanceAlongCourseMeters: distM,
              barrierState: zone.railwayBarrierState,
              barrierClosureProgress: barrierProgress,
              lightsActive: zone.railwayBarrierState != RailwayBarrierState.open,
            ),
          );

          final motoDist = math.max(0.0, distM - 55.0);
          final motoFrame = resolveFrame(motoDist);
          motos.add(
            CommissaireMarshalMoto3D(
              id: '${stage.id}_moto_rail_${zone.id}',
              worldPosition: motoFrame.$1 - motoFrame.$3 * 2.0,
              tangent: motoFrame.$2,
              lateralRight: motoFrame.$3,
              surfaceNormal: motoFrame.$4,
              distanceAlongCourseMeters: motoDist,
              lateralOffsetMeters: -2.0,
              isWarningActive: true,
              marshalLabel: 'PRZEJAZD KOLEJOWY',
            ),
          );
        }
        idx++;
      }
    }

    // Proceduralne elementy miejskie na końcówce etapu (ostatnie 5 km), jeśli brak dedykowanych stref
    if (islands.isEmpty && totalMeters > 4000.0) {
      final sampleOffsets = <double>[
        totalMeters - 3600.0,
        totalMeters - 2200.0,
        totalMeters - 1350.0,
      ];
      for (int i = 0; i < sampleOffsets.length; i++) {
        final distM = sampleOffsets[i].clamp(0.0, totalMeters - 250.0);
        final frame = resolveFrame(distM);
        islands.add(
          TrafficIsland3D(
            id: '${stage.id}_auto_island_$i',
            worldPosition: frame.$1,
            tangent: frame.$2,
            lateralRight: frame.$3,
            surfaceNormal: frame.$4,
            distanceAlongCourseMeters: distM,
            passDirection: i.isEven
                ? TrafficIslandPassDirection.passRight
                : TrafficIslandPassDirection.passLeft,
          ),
        );

        final motoDist = math.max(0.0, distM - 32.0);
        final motoFrame = resolveFrame(motoDist);
        motos.add(
          CommissaireMarshalMoto3D(
            id: '${stage.id}_auto_moto_$i',
            worldPosition: motoFrame.$1 + motoFrame.$3 * 1.95,
            tangent: motoFrame.$2,
            lateralRight: motoFrame.$3,
            surfaceNormal: motoFrame.$4,
            distanceAlongCourseMeters: motoDist,
            lateralOffsetMeters: 1.95,
            isWarningActive: true,
          ),
        );
      }
    }

    // Progi zwalniające w strefach miejskich / ostatnich 4.5 km
    if (speedBumps.isEmpty && totalMeters > 3000.0) {
      final bumpDistances = <double>[
        totalMeters - 2950.0,
        totalMeters - 1750.0,
      ];
      for (int i = 0; i < bumpDistances.length; i++) {
        final distM = bumpDistances[i].clamp(0.0, totalMeters - 200.0);
        final frame = resolveFrame(distM);
        speedBumps.add(
          SpeedBump3D(
            id: '${stage.id}_auto_bump_$i',
            worldPosition: frame.$1,
            tangent: frame.$2,
            lateralRight: frame.$3,
            surfaceNormal: frame.$4,
            distanceAlongCourseMeters: distM,
          ),
        );
      }
    }

    // Przykładowy przejazd kolejowy w środkowej części płaskich/pagórkowatych etapów
    if (railways.isEmpty && totalMeters > 15000.0) {
      final railDist = totalMeters * 0.48;
      final frame = resolveFrame(railDist);
      railways.add(
        RailwayCrossing3D(
          id: '${stage.id}_auto_rail_0',
          worldPosition: frame.$1,
          tangent: frame.$2,
          lateralRight: frame.$3,
          surfaceNormal: frame.$4,
          distanceAlongCourseMeters: railDist,
          barrierState: RailwayBarrierState.warningLightsFlashing,
          barrierClosureProgress: 0.25,
          lightsActive: true,
        ),
      );
    }

    final pack = StageTrafficIslandsAndRailwayPack(
      stageId: stage.id,
      islands: List.unmodifiable(islands),
      speedBumps: List.unmodifiable(speedBumps),
      railwayCrossings: List.unmodifiable(railways),
      marshalMotos: List.unmodifiable(motos),
    );
    if (hazardZones == null) {
      _cachedPack = pack;
    }
    return pack;
  }

  /// Renderuje wszystkie widoczne wysepki, progi zwalniające, przejazdy kolejowe i motocykle sędziowskie.
  TrafficIslandsAndRailwayTelemetry render({
    required Canvas canvas,
    required Size viewportSize,
    required Scene3DMathProjection projection,
    required StageTrafficIslandsAndRailwayPack pack,
    required double cameraDistanceMeters,
    double? elapsedTimeSeconds,
  }) {
    if (!config.enabled || pack.isEmpty) {
      return const TrafficIslandsAndRailwayTelemetry();
    }

    final timeSec = elapsedTimeSeconds ?? _elapsedSeconds;
    final minDist = cameraDistanceMeters - config.backwardVisibilityMeters;
    final maxDist = cameraDistanceMeters + config.forwardVisibilityMeters;

    final items = <_SortableRenderItem>[];
    double? nearestDist;

    void trackNearest(double distAlong) {
      final delta = (distAlong - cameraDistanceMeters).abs();
      if (nearestDist == null || delta < nearestDist!) {
        nearestDist = delta;
      }
    }

    if (config.showTrafficIslands) {
      for (int i = 0; i < pack.islands.length; i++) {
        final item = pack.islands[i];
        if (item.distanceAlongCourseMeters < minDist ||
            item.distanceAlongCourseMeters > maxDist) {
          continue;
        }
        final proj = projection.worldToScreen(item.worldPosition);
        if (!proj.isInFrontOfCamera) continue;
        trackNearest(item.distanceAlongCourseMeters);
        items.add(
          _SortableRenderItem(
            kind: _SortableElementKind.island,
            index: i,
            depthEye: proj.depthEye,
            distanceAlongCourse: item.distanceAlongCourseMeters,
          ),
        );
      }
    }

    if (config.showSpeedBumps) {
      for (int i = 0; i < pack.speedBumps.length; i++) {
        final item = pack.speedBumps[i];
        if (item.distanceAlongCourseMeters < minDist ||
            item.distanceAlongCourseMeters > maxDist) {
          continue;
        }
        final proj = projection.worldToScreen(item.worldPosition);
        if (!proj.isInFrontOfCamera) continue;
        trackNearest(item.distanceAlongCourseMeters);
        items.add(
          _SortableRenderItem(
            kind: _SortableElementKind.speedBump,
            index: i,
            depthEye: proj.depthEye,
            distanceAlongCourse: item.distanceAlongCourseMeters,
          ),
        );
      }
    }

    if (config.showRailwayCrossings) {
      for (int i = 0; i < pack.railwayCrossings.length; i++) {
        final item = pack.railwayCrossings[i];
        if (item.distanceAlongCourseMeters < minDist ||
            item.distanceAlongCourseMeters > maxDist) {
          continue;
        }
        final proj = projection.worldToScreen(item.worldPosition);
        if (!proj.isInFrontOfCamera) continue;
        trackNearest(item.distanceAlongCourseMeters);
        items.add(
          _SortableRenderItem(
            kind: _SortableElementKind.railway,
            index: i,
            depthEye: proj.depthEye,
            distanceAlongCourse: item.distanceAlongCourseMeters,
          ),
        );
      }
    }

    if (config.showMarshalMotos) {
      for (int i = 0; i < pack.marshalMotos.length; i++) {
        final item = pack.marshalMotos[i];
        if (item.distanceAlongCourseMeters < minDist ||
            item.distanceAlongCourseMeters > maxDist) {
          continue;
        }
        final proj = projection.worldToScreen(item.worldPosition);
        if (!proj.isInFrontOfCamera) continue;
        items.add(
          _SortableRenderItem(
            kind: _SortableElementKind.marshalMoto,
            index: i,
            depthEye: proj.depthEye,
            distanceAlongCourse: item.distanceAlongCourseMeters,
          ),
        );
      }
    }

    // Sortowanie od najdalszego do najbliższego (Painter's Algorithm)
    items.sort((a, b) => b.depthEye.compareTo(a.depthEye));

    int visibleIslands = 0;
    int visibleBumps = 0;
    int visibleRailways = 0;
    int visibleMotos = 0;
    int activeRedLights = 0;
    int activeWhistles = 0;

    for (final item in items) {
      switch (item.kind) {
        case _SortableElementKind.island:
          _drawTrafficIsland(
            canvas: canvas,
            projection: projection,
            island: pack.islands[item.index],
            timeSec: timeSec,
          );
          visibleIslands++;
          break;
        case _SortableElementKind.speedBump:
          _drawSpeedBump(
            canvas: canvas,
            projection: projection,
            bump: pack.speedBumps[item.index],
          );
          visibleBumps++;
          break;
        case _SortableElementKind.railway:
          final rail = pack.railwayCrossings[item.index];
          _drawRailwayCrossing(
            canvas: canvas,
            projection: projection,
            crossing: rail,
            timeSec: timeSec,
          );
          visibleRailways++;
          if (rail.lightsActive ||
              rail.barrierState != RailwayBarrierState.open) {
            activeRedLights++;
          }
          break;
        case _SortableElementKind.marshalMoto:
          final moto = pack.marshalMotos[item.index];
          _drawCommissaireMarshalMoto(
            canvas: canvas,
            projection: projection,
            moto: moto,
            timeSec: timeSec,
            viewportSize: viewportSize,
          );
          visibleMotos++;
          if (moto.isWarningActive) {
            activeWhistles++;
          }
          break;
      }
    }

    return TrafficIslandsAndRailwayTelemetry(
      visibleIslandsCount: visibleIslands,
      visibleSpeedBumpsCount: visibleBumps,
      visibleRailwaysCount: visibleRailways,
      visibleMarshalMotosCount: visibleMotos,
      activeRedLightsCount: activeRedLights,
      activeWhistleAlertsCount: activeWhistles,
      nearestHazardDistanceMeters: nearestDist,
    );
  }

  // ===========================================================================
  // 3. RYSOWANIE WYSEPKI ZE ZNAKIEM NAKAZU JAZDY Z PRAWEJ / LEWEJ STRONY
  // ===========================================================================

  void _drawTrafficIsland({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required TrafficIsland3D island,
    required double timeSec,
  }) {
    final center =
        island.worldPosition + island.lateralRight * island.lateralOffsetMeters;
    final halfL = island.lengthMeters * 0.5;
    final halfW = island.widthMeters * 0.5;
    final h = island.curbHeightMeters;

    // Białe pasy ostrzegawcze (szewrony na asfalcie przed najazdem na wysepkę)
    final chevronTip = center - island.tangent * (halfL + 4.5);
    final chevronLeft =
        center - island.tangent * (halfL + 0.3) - island.lateralRight * (halfW + 0.55);
    final chevronRight =
        center - island.tangent * (halfL + 0.3) + island.lateralRight * (halfW + 0.55);

    final pTip = projection.worldToScreen(chevronTip);
    final pCL = projection.worldToScreen(chevronLeft);
    final pCR = projection.worldToScreen(chevronRight);
    if (pTip.isInFrontOfCamera && pCL.isInFrontOfCamera && pCR.isInFrontOfCamera) {
      final chevronPath = Path()
        ..moveTo(pTip.screenX, pTip.screenY)
        ..lineTo(pCL.screenX, pCL.screenY)
        ..lineTo(pCR.screenX, pCR.screenY)
        ..close();
      _fillPaint.color = Colors.white.withValues(alpha: 0.28);
      canvas.drawPath(chevronPath, _fillPaint);
      _strokePaint
        ..color = Colors.white.withValues(alpha: 0.72)
        ..strokeWidth = math.max(1.0, 1.4 * pTip.perspectiveScale);
      canvas.drawPath(chevronPath, _strokePaint);
    }

    // Podstawa betonowa wysepki (6-wierzchołkowy kształt z zaokrąglonym dziobem)
    final nose = center - island.tangent * halfL;
    final tail = center + island.tangent * halfL;
    final fl = center - island.tangent * (halfL * 0.65) - island.lateralRight * halfW;
    final fr = center - island.tangent * (halfL * 0.65) + island.lateralRight * halfW;
    final bl = center + island.tangent * (halfL * 0.65) - island.lateralRight * halfW;
    final br = center + island.tangent * (halfL * 0.65) + island.lateralRight * halfW;

    final upVec = island.surfaceNormal * h;
    final basePts = [nose, fr, br, tail, bl, fl]
        .map(projection.worldToScreen)
        .toList(growable: false);
    final topPts = [nose, fr, br, tail, bl, fl]
        .map((v) => projection.worldToScreen(v + upVec))
        .toList(growable: false);

    if (basePts.every((p) => p.isInFrontOfCamera) &&
        topPts.every((p) => p.isInFrontOfCamera)) {
      // Cień wysepki
      final basePath = _buildPolygonPath(basePts);
      canvas.drawPath(basePath, _shadowPaint);

      // Boki krawężnika (żółto-szary krawężnik)
      _fillPaint.color = const Color(0xFF475569);
      canvas.drawPath(basePath, _fillPaint);

      // Górna płyta wysepki
      final topPath = _buildPolygonPath(topPts);
      _fillPaint.color = const Color(0xFFCBD5E1);
      canvas.drawPath(topPath, _fillPaint);

      _strokePaint
        ..color = AppColors.amberWarning
        ..strokeWidth = math.max(1.2, 2.0 * topPts.first.perspectiveScale);
      canvas.drawPath(topPath, _strokePaint);
    }

    // Żółte pachołki ostrzegawcze na krawędziach wysepki
    if (island.hasYellowCones && island.coneCount > 0) {
      for (int c = 0; c < island.coneCount; c++) {
        final t = island.coneCount == 1 ? 0.5 : c / (island.coneCount - 1);
        final zOff = -halfL * 0.72 + t * (halfL * 1.44);
        final coneBase =
            center + island.tangent * zOff + upVec;
        _drawTrafficCone(canvas, projection, coneBase, island.surfaceNormal);
      }
    }

    // Słupek ze znakiem nakazu jazdy z prawej/lewej strony (C-9 / C-10 / C-11)
    final signBase = center - island.tangent * (halfL * 0.55) + upVec;
    _drawMandatoryDirectionSign(
      canvas: canvas,
      projection: projection,
      basePos: signBase,
      surfaceNormal: island.surfaceNormal,
      direction: island.passDirection,
      hasBeacon: island.hasBollardBeacon,
      timeSec: timeSec,
    );
  }

  void _drawTrafficCone(
    Canvas canvas,
    Scene3DMathProjection projection,
    Vector3 basePos,
    Vector3 normal,
  ) {
    final pBase = projection.worldToScreen(basePos);
    final pTip = projection.worldToScreen(basePos + normal * 0.55);
    if (!pBase.isInFrontOfCamera || !pTip.isInFrontOfCamera) return;

    final scale = pBase.perspectiveScale;
    final halfBaseW = math.max(2.0, 5.5 * scale);
    final conePath = Path()
      ..moveTo(pTip.screenX, pTip.screenY)
      ..lineTo(pBase.screenX - halfBaseW, pBase.screenY)
      ..lineTo(pBase.screenX + halfBaseW, pBase.screenY)
      ..close();

    _fillPaint.color = AppColors.amberWarning;
    canvas.drawPath(conePath, _fillPaint);

    // Biały odblaskowy pasek na pachołku
    final midX = (pBase.screenX + pTip.screenX) * 0.5;
    final midY = (pBase.screenY + pTip.screenY) * 0.5;
    _strokePaint
      ..color = Colors.white
      ..strokeWidth = math.max(1.0, 2.2 * scale);
    canvas.drawLine(
      Offset(midX - halfBaseW * 0.45, midY),
      Offset(midX + halfBaseW * 0.45, midY),
      _strokePaint,
    );
  }

  void _drawMandatoryDirectionSign({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 basePos,
    required Vector3 surfaceNormal,
    required TrafficIslandPassDirection direction,
    required bool hasBeacon,
    required double timeSec,
  }) {
    final poleTopPos = basePos + surfaceNormal * 1.75;
    final signCenterPos = basePos + surfaceNormal * 1.45;
    final pBase = projection.worldToScreen(basePos);
    final pTop = projection.worldToScreen(poleTopPos);
    final pSign = projection.worldToScreen(signCenterPos);

    if (!pBase.isInFrontOfCamera || !pSign.isInFrontOfCamera) return;

    final scale = pSign.perspectiveScale;

    // Metalowy słupek
    _strokePaint
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = math.max(1.5, 3.0 * scale);
    canvas.drawLine(
      Offset(pBase.screenX, pBase.screenY),
      Offset(pTop.screenX, pTop.screenY),
      _strokePaint,
    );

    // Okrągła niebieska tarcza znaku nakazu (C-9 / C-10 / C-11)
    final radius = math.max(6.0, 14.5 * scale);
    final signOffset = Offset(pSign.screenX, pSign.screenY);

    _fillPaint.color = const Color(0xFF1D4ED8);
    canvas.drawCircle(signOffset, radius, _fillPaint);

    _strokePaint
      ..color = Colors.white
      ..strokeWidth = math.max(1.0, 1.8 * scale);
    canvas.drawCircle(signOffset, radius * 0.9, _strokePaint);

    // Biała strzałka nakazu (w dół-prawo, w dół-lewo lub rozwidlona)
    _strokePaint
      ..color = Colors.white
      ..strokeWidth = math.max(1.4, 2.5 * scale);

    if (direction == TrafficIslandPassDirection.passRight) {
      _drawArrowVector(
        canvas,
        signOffset + Offset(-radius * 0.32, -radius * 0.34),
        signOffset + Offset(radius * 0.36, radius * 0.36),
        radius * 0.28,
      );
    } else if (direction == TrafficIslandPassDirection.passLeft) {
      _drawArrowVector(
        canvas,
        signOffset + Offset(radius * 0.32, -radius * 0.34),
        signOffset + Offset(-radius * 0.36, radius * 0.36),
        radius * 0.28,
      );
    } else {
      _drawArrowVector(
        canvas,
        signOffset + Offset(0.0, -radius * 0.36),
        signOffset + Offset(radius * 0.34, radius * 0.32),
        radius * 0.24,
      );
      _drawArrowVector(
        canvas,
        signOffset + Offset(0.0, -radius * 0.36),
        signOffset + Offset(-radius * 0.34, radius * 0.32),
        radius * 0.24,
      );
    }

    // Pomarańczowy pulsacyjny kogut ostrzegawczy na szczycie słupka
    if (hasBeacon && pTop.isInFrontOfCamera) {
      final pulse =
          0.5 + 0.5 * math.sin(timeSec * 2.0 * math.pi * config.flashFrequencyHz);
      final beaconPos = Offset(pTop.screenX, pTop.screenY - radius * 0.2);
      _glowPaint.color = AppColors.amberWarning.withValues(alpha: 0.3 + 0.45 * pulse);
      canvas.drawCircle(beaconPos, radius * 0.55, _glowPaint);

      _fillPaint.color = Color.lerp(
        const Color(0xFF92400E),
        AppColors.amberWarning,
        pulse,
      )!;
      canvas.drawCircle(beaconPos, math.max(2.5, 4.2 * scale), _fillPaint);
    }
  }

  void _drawArrowVector(
    Canvas canvas,
    Offset start,
    Offset end,
    double headLen,
  ) {
    canvas.drawLine(start, end, _strokePaint);
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const spread = 0.55;
    canvas.drawLine(
      end,
      Offset(
        end.dx - headLen * math.cos(angle - spread),
        end.dy - headLen * math.sin(angle - spread),
      ),
      _strokePaint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - headLen * math.cos(angle + spread),
        end.dy - headLen * math.sin(angle + spread),
      ),
      _strokePaint,
    );
  }

  // ===========================================================================
  // 4. RYSOWANIE PROGÓW ZWALNIAJĄCYCH (SPEED BUMPS)
  // ===========================================================================

  void _drawSpeedBump({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required SpeedBump3D bump,
  }) {
    final halfW = bump.widthMeters * 0.5;
    final halfL = bump.lengthMeters * 0.5;
    final ridgeLift = bump.surfaceNormal * bump.heightMeters;
    final stripes = math.max(4, bump.stripeCount);

    for (int i = 0; i < stripes; i++) {
      final u0 = -halfW + (i / stripes) * bump.widthMeters;
      final u1 = -halfW + ((i + 1) / stripes) * bump.widthMeters;

      final p00 = projection.worldToScreen(
        bump.worldPosition - bump.tangent * halfL + bump.lateralRight * u0,
      );
      final p01 = projection.worldToScreen(
        bump.worldPosition - bump.tangent * halfL + bump.lateralRight * u1,
      );
      final p11 = projection.worldToScreen(
        bump.worldPosition + bump.tangent * halfL + bump.lateralRight * u1,
      );
      final p10 = projection.worldToScreen(
        bump.worldPosition + bump.tangent * halfL + bump.lateralRight * u0,
      );
      final ridge0 = projection.worldToScreen(
        bump.worldPosition + ridgeLift + bump.lateralRight * u0,
      );
      final ridge1 = projection.worldToScreen(
        bump.worldPosition + ridgeLift + bump.lateralRight * u1,
      );

      if (!p00.isInFrontOfCamera ||
          !p01.isInFrontOfCamera ||
          !p11.isInFrontOfCamera ||
          !p10.isInFrontOfCamera ||
          !ridge0.isInFrontOfCamera ||
          !ridge1.isInFrontOfCamera) {
        continue;
      }

      // Najazd przedni i zjazd tylny progu dające wypukły efekt 3D
      final frontFace = _buildPolygonPath([p00, p01, ridge1, ridge0]);
      final backFace = _buildPolygonPath([ridge0, ridge1, p11, p10]);

      final isYellow = i.isEven;
      _fillPaint.color =
          isYellow ? AppColors.amberWarning : const Color(0xFF1E293B);
      canvas.drawPath(frontFace, _fillPaint);

      _fillPaint.color = isYellow
          ? const Color(0xFFD97706)
          : const Color(0xFF0F172A);
      canvas.drawPath(backFace, _fillPaint);
    }

    // Znak ostrzegawczy progu zwalniającego na prawym poboczu
    if (bump.hasWarningSign) {
      final signBase =
          bump.worldPosition + bump.lateralRight * (halfW + 0.7) - bump.tangent * 2.5;
      _drawTriangularWarningSign(
        canvas: canvas,
        projection: projection,
        basePos: signBase,
        normal: bump.surfaceNormal,
      );
    }
  }

  void _drawTriangularWarningSign({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 basePos,
    required Vector3 normal,
  }) {
    final pBase = projection.worldToScreen(basePos);
    final pTop = projection.worldToScreen(basePos + normal * 1.55);
    if (!pBase.isInFrontOfCamera || !pTop.isInFrontOfCamera) return;

    final scale = pTop.perspectiveScale;
    final r = math.max(5.0, 12.0 * scale);
    _strokePaint
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = math.max(1.2, 2.2 * scale);
    canvas.drawLine(
      Offset(pBase.screenX, pBase.screenY),
      Offset(pTop.screenX, pTop.screenY),
      _strokePaint,
    );

    final tri = Path()
      ..moveTo(pTop.screenX, pTop.screenY - r)
      ..lineTo(pTop.screenX - r * 0.9, pTop.screenY + r * 0.65)
      ..lineTo(pTop.screenX + r * 0.9, pTop.screenY + r * 0.65)
      ..close();

    _fillPaint.color = AppColors.amberWarning;
    canvas.drawPath(tri, _fillPaint);
    _strokePaint
      ..color = AppColors.crimsonAlert
      ..strokeWidth = math.max(1.2, 2.2 * scale);
    canvas.drawPath(tri, _strokePaint);
  }

  // ===========================================================================
  // 5. RYSOWANIE PRZEJAZDU KOLEJOWEGO Z MIGAJĄCYMI CZERWONYMI ŚWIATŁAMI
  // ===========================================================================

  void _drawRailwayCrossing({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required RailwayCrossing3D crossing,
    required double timeSec,
  }) {
    final halfSpan = crossing.roadSpanMeters * 0.5;
    final cosA = math.cos(crossing.crossingAngleRadians);
    final sinA = math.sin(crossing.crossingAngleRadians);

    // Wektor wzdłuż torów (prawie prostopadły do drogi) i prostopadły do torów
    final trackDir =
        (crossing.lateralRight * cosA + crossing.tangent * sinA)..normalize();
    final trackPerp =
        (crossing.tangent * cosA - crossing.lateralRight * sinA)..normalize();

    final halfGauge = crossing.trackGaugeMeters * 0.5;

    // 1. Podkłady kolejowe (Sleepers)
    const double sleeperStep = 0.65;
    for (double u = -halfSpan; u <= halfSpan; u += sleeperStep) {
      final c = crossing.worldPosition + trackDir * u;
      final s0 = projection.worldToScreen(c - trackPerp * (halfGauge + 0.35));
      final s1 = projection.worldToScreen(c + trackPerp * (halfGauge + 0.35));
      if (!s0.isInFrontOfCamera || !s1.isInFrontOfCamera) continue;

      _strokePaint
        ..color = const Color(0xFF451A03).withValues(alpha: 0.85)
        ..strokeWidth = math.max(1.5, 4.0 * s0.perspectiveScale);
      canvas.drawLine(
        Offset(s0.screenX, s0.screenY),
        Offset(s1.screenX, s1.screenY),
        _strokePaint,
      );
    }

    // 2. Dwie stalowe szyny kolejowe z połyskiem
    for (final sign in const [-1.0, 1.0]) {
      final railOffset = trackPerp * (sign * halfGauge);
      final rStart =
          projection.worldToScreen(crossing.worldPosition - trackDir * halfSpan + railOffset);
      final rEnd =
          projection.worldToScreen(crossing.worldPosition + trackDir * halfSpan + railOffset);
      if (!rStart.isInFrontOfCamera || !rEnd.isInFrontOfCamera) continue;

      final scale = (rStart.perspectiveScale + rEnd.perspectiveScale) * 0.5;
      _strokePaint
        ..color = const Color(0xFF334155)
        ..strokeWidth = math.max(2.0, 5.0 * scale);
      canvas.drawLine(
        Offset(rStart.screenX, rStart.screenY),
        Offset(rEnd.screenX, rEnd.screenY),
        _strokePaint,
      );

      _strokePaint
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = math.max(1.0, 2.0 * scale);
      canvas.drawLine(
        Offset(rStart.screenX, rStart.screenY),
        Offset(rEnd.screenX, rEnd.screenY),
        _strokePaint,
      );
    }

    // 3. Rogatki (szlabany) oraz sygnalizatory z migającymi czerwonymi światłami po obu stronach
    final flashPhase = math.sin(timeSec * 2.0 * math.pi * config.flashFrequencyHz);
    final leftLightOn = crossing.lightsActive && flashPhase >= 0.0;
    final rightLightOn = crossing.lightsActive && flashPhase < 0.0;

    for (final side in const [-1.0, 1.0]) {
      final postBase = crossing.worldPosition +
          crossing.lateralRight * (side * (halfSpan - 0.6)) -
          crossing.tangent * (halfGauge + 1.15);
      _drawRailwaySignalAndBarrier(
        canvas: canvas,
        projection: projection,
        postBase: postBase,
        sideSign: side,
        lateralRight: crossing.lateralRight,
        normal: crossing.surfaceNormal,
        closureProgress: crossing.barrierClosureProgress,
        leftLightOn: leftLightOn,
        rightLightOn: rightLightOn,
      );
    }
  }

  void _drawRailwaySignalAndBarrier({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required Vector3 postBase,
    required double sideSign,
    required Vector3 lateralRight,
    required Vector3 normal,
    required double closureProgress,
    required bool leftLightOn,
    required bool rightLightOn,
  }) {
    final postTop = postBase + normal * 2.55;
    final lightBarPos = postBase + normal * 1.95;
    final pivotPos = postBase + normal * 0.95;

    final pBase = projection.worldToScreen(postBase);
    final pTop = projection.worldToScreen(postTop);
    final pLight = projection.worldToScreen(lightBarPos);
    final pPivot = projection.worldToScreen(pivotPos);

    if (!pBase.isInFrontOfCamera ||
        !pTop.isInFrontOfCamera ||
        !pLight.isInFrontOfCamera ||
        !pPivot.isInFrontOfCamera) {
      return;
    }

    final scale = pLight.perspectiveScale;

    // Słup sygnalizatora
    _strokePaint
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = math.max(1.5, 3.4 * scale);
    canvas.drawLine(
      Offset(pBase.screenX, pBase.screenY),
      Offset(pTop.screenX, pTop.screenY),
      _strokePaint,
    );

    // Krzyż św. Andrzeja nad światłami
    final crossArm = math.max(5.0, 12.0 * scale);
    final topPt = Offset(pTop.screenX, pTop.screenY);
    _strokePaint
      ..color = Colors.white
      ..strokeWidth = math.max(1.6, 3.0 * scale);
    canvas.drawLine(
      topPt + Offset(-crossArm, -crossArm * 0.6),
      topPt + Offset(crossArm, crossArm * 0.6),
      _strokePaint,
    );
    canvas.drawLine(
      topPt + Offset(-crossArm, crossArm * 0.6),
      topPt + Offset(crossArm, -crossArm * 0.6),
      _strokePaint,
    );

    // Podwójne naprzemiennie migające czerwone światła
    final lampSpacing = math.max(4.5, 9.0 * scale);
    final lampRadius = math.max(2.8, 5.2 * scale);
    final housingRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pLight.screenX, pLight.screenY),
        width: lampSpacing * 3.2,
        height: lampRadius * 2.8,
      ),
      Radius.circular(lampRadius),
    );
    _fillPaint.color = const Color(0xFF0F172A);
    canvas.drawRRect(housingRect, _fillPaint);

    final lampLeft = Offset(pLight.screenX - lampSpacing, pLight.screenY);
    final lampRight = Offset(pLight.screenX + lampSpacing, pLight.screenY);

    _drawRailwayLamp(canvas, lampLeft, lampRadius, leftLightOn);
    _drawRailwayLamp(canvas, lampRight, lampRadius, rightLightOn);

    // Ramię szlabanu biało-czerwonego (0 = pionowo otwarty, 1 = poziomo nad pasem)
    final angleFromVertical = closureProgress.clamp(0.0, 1.0) * (math.pi * 0.48);
    final inwardDir = lateralRight * (-sideSign);
    final armDir = (normal * math.cos(angleFromVertical) +
            inwardDir * math.sin(angleFromVertical))
        ..normalize();
    const double armLen = 3.6;
    const int segments = 6;
    for (int s = 0; s < segments; s++) {
      final a0 = pivotPos + armDir * ((s / segments) * armLen);
      final a1 = pivotPos + armDir * (((s + 1) / segments) * armLen);
      final pa0 = projection.worldToScreen(a0);
      final pa1 = projection.worldToScreen(a1);
      if (!pa0.isInFrontOfCamera || !pa1.isInFrontOfCamera) continue;

      _strokePaint
        ..color = s.isEven ? AppColors.crimsonAlert : Colors.white
        ..strokeWidth = math.max(2.0, 4.5 * scale);
      canvas.drawLine(
        Offset(pa0.screenX, pa0.screenY),
        Offset(pa1.screenX, pa1.screenY),
        _strokePaint,
      );
    }
  }

  void _drawRailwayLamp(
    Canvas canvas,
    Offset center,
    double radius,
    bool isOn,
  ) {
    if (isOn) {
      _glowPaint.color = AppColors.crimsonAlert.withValues(alpha: 0.72);
      canvas.drawCircle(center, radius * 2.2, _glowPaint);
      _fillPaint.color = AppColors.crimsonAlert;
    } else {
      _fillPaint.color = const Color(0xFF450A0A);
    }
    canvas.drawCircle(center, radius, _fillPaint);
  }

  // ===========================================================================
  // 6. RYSOWANIE MOTOCYKLA SĘDZIEGO Z GWIZDKIEM I ŻÓŁTĄ CHORĄGIEWKĄ
  // ===========================================================================

  void _drawCommissaireMarshalMoto({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required CommissaireMarshalMoto3D moto,
    required double timeSec,
    required Size viewportSize,
  }) {
    final rearWheelPos = moto.worldPosition - moto.tangent * 0.72;
    final frontWheelPos = moto.worldPosition + moto.tangent * 0.72;
    final saddlePos = moto.worldPosition + moto.surfaceNormal * 0.85;
    final helmetPos = moto.worldPosition + moto.surfaceNormal * 1.48;
    final handPos =
        moto.worldPosition + moto.surfaceNormal * 1.55 + moto.lateralRight * 0.35;

    final pRear = projection.worldToScreen(rearWheelPos);
    final pFront = projection.worldToScreen(frontWheelPos);
    final pSaddle = projection.worldToScreen(saddlePos);
    final pHelmet = projection.worldToScreen(helmetPos);
    final pHand = projection.worldToScreen(handPos);

    if (!pRear.isInFrontOfCamera ||
        !pFront.isInFrontOfCamera ||
        !pSaddle.isInFrontOfCamera ||
        !pHelmet.isInFrontOfCamera) {
      return;
    }

    final scale = pSaddle.perspectiveScale;

    // Cień motocykla na asfalcie
    final pCenter = projection.worldToScreen(moto.worldPosition);
    if (pCenter.isInFrontOfCamera) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pCenter.screenX, pCenter.screenY),
          width: math.max(10.0, 26.0 * scale),
          height: math.max(4.0, 9.0 * scale),
        ),
        _shadowPaint,
      );
    }

    // Koła motocykla
    final wheelRadius = math.max(3.5, 8.5 * scale);
    _fillPaint.color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(pRear.screenX, pRear.screenY - wheelRadius * 0.6), wheelRadius, _fillPaint);
    canvas.drawCircle(Offset(pFront.screenX, pFront.screenY - wheelRadius * 0.6), wheelRadius, _fillPaint);

    // Owiewka motocykla (ciemny granat + żółte akcenty sędziowskie)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pSaddle.screenX, pSaddle.screenY),
        width: math.max(12.0, 24.0 * scale),
        height: math.max(6.0, 12.0 * scale),
      ),
      Radius.circular(math.max(2.0, 4.0 * scale)),
    );
    _fillPaint.color = const Color(0xFF1E293B);
    canvas.drawRRect(bodyRect, _fillPaint);
    _strokePaint
      ..color = AppColors.goldAccent
      ..strokeWidth = math.max(1.0, 1.8 * scale);
    canvas.drawRRect(bodyRect, _strokePaint);

    // Korpus sędziego w kamizelce odblaskowej i biały kask
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          (pSaddle.screenX + pHelmet.screenX) * 0.5,
          (pSaddle.screenY + pHelmet.screenY) * 0.5,
        ),
        width: math.max(6.0, 11.0 * scale),
        height: math.max(8.0, 14.0 * scale),
      ),
      Radius.circular(math.max(2.0, 4.0 * scale)),
    );
    _fillPaint.color = AppColors.amberWarning;
    canvas.drawRRect(torsoRect, _fillPaint);

    _fillPaint.color = Colors.white;
    canvas.drawCircle(
      Offset(pHelmet.screenX, pHelmet.screenY),
      math.max(3.0, 5.5 * scale),
      _fillPaint,
    );

    // Żółta chorągiewka ostrzegawcza powiewająca w dłoni sędziego
    if (pHand.isInFrontOfCamera) {
      final wave = math.sin(
        timeSec * 2.0 * math.pi * config.flagWaveHz + moto.flagWavePhase,
      );
      final staffBase = Offset(pHand.screenX, pHand.screenY);
      final staffTop = Offset(
        pHand.screenX + wave * 3.5 * scale,
        pHand.screenY - math.max(12.0, 26.0 * scale),
      );

      _strokePaint
        ..color = Colors.white
        ..strokeWidth = math.max(1.0, 1.8 * scale);
      canvas.drawLine(staffBase, staffTop, _strokePaint);

      final flagW = math.max(9.0, 18.0 * scale);
      final flagH = math.max(6.0, 11.5 * scale);
      final flagPath = Path()
        ..moveTo(staffTop.dx, staffTop.dy)
        ..quadraticBezierTo(
          staffTop.dx + flagW * 0.5,
          staffTop.dy + wave * 4.5 * scale,
          staffTop.dx + flagW,
          staffTop.dy + flagH * 0.25 + wave * 3.0 * scale,
        )
        ..lineTo(
          staffTop.dx + flagW * 0.92,
          staffTop.dy + flagH + wave * 2.5 * scale,
        )
        ..quadraticBezierTo(
          staffTop.dx + flagW * 0.45,
          staffTop.dy + flagH * 0.85,
          staffTop.dx,
          staffTop.dy + flagH,
        )
        ..close();

      _fillPaint.color = const Color(0xFFFACC15);
      canvas.drawPath(flagPath, _fillPaint);
      _strokePaint
        ..color = AppColors.background.withValues(alpha: 0.7)
        ..strokeWidth = math.max(0.8, 1.2 * scale);
      canvas.drawPath(flagPath, _strokePaint);
    }

    // Fale akustyczne gwizdka sędziego
    if (moto.isWarningActive) {
      final whistleOrigin = Offset(pHelmet.screenX, pHelmet.screenY);
      final basePhase =
          (timeSec * config.whistlePulseHz + moto.whistlePulsePhase) % 1.0;

      for (int ring = 0; ring < 3; ring++) {
        final phase = (basePhase + ring * 0.33) % 1.0;
        final radius = math.max(4.0, (8.0 + phase * 24.0) * scale);
        final alpha = (1.0 - phase).clamp(0.0, 1.0) * 0.85;
        _strokePaint
          ..color = AppColors.cyanAccent.withValues(alpha: alpha)
          ..strokeWidth = math.max(1.0, 1.8 * scale);
        canvas.drawArc(
          Rect.fromCircle(center: whistleOrigin, radius: radius),
          -math.pi * 0.85,
          math.pi * 0.7,
          false,
          _strokePaint,
        );
      }

      // Etykieta ostrzegawcza dla bliskich obiektów
      if (pHelmet.depthEye < 85.0 &&
          pHelmet.screenX > 20 &&
          pHelmet.screenX < viewportSize.width - 20) {
        final tp = _getTextPainter(moto.marshalLabel);
        final badgeCenter = Offset(
          pHelmet.screenX,
          pHelmet.screenY - math.max(22.0, 38.0 * scale),
        );
        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: badgeCenter,
            width: tp.width + 12.0,
            height: tp.height + 6.0,
          ),
          const Radius.circular(6.0),
        );
        _fillPaint.color = AppColors.surface.withValues(alpha: 0.9);
        canvas.drawRRect(badgeRect, _fillPaint);
        _strokePaint
          ..color = AppColors.goldAccent
          ..strokeWidth = 1.0;
        canvas.drawRRect(badgeRect, _strokePaint);
        tp.paint(
          canvas,
          Offset(badgeCenter.dx - tp.width * 0.5, badgeCenter.dy - tp.height * 0.5),
        );
      }
    }
  }

  TextPainter _getTextPainter(String text) {
    return _textCache.putIfAbsent(text, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            color: AppColors.goldAccent,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  Path _buildPolygonPath(List<ProjectedPoint3D> pts) {
    final path = Path()..moveTo(pts.first.screenX, pts.first.screenY);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].screenX, pts[i].screenY);
    }
    path.close();
    return path;
  }

  double _elevationAt(double distM, List<StageSegment> segments) {
    if (segments.isEmpty) return 0.0;
    double covered = 0.0;
    double alt = 0.0;
    for (final seg in segments) {
      final segLen = seg.lengthKm * 1000.0;
      if (distM <= covered + segLen) {
        final frac = segLen > 0 ? (distM - covered) / segLen : 0.0;
        return alt + frac * segLen * (seg.gradientPercent / 100.0);
      }
      covered += segLen;
      alt += segLen * (seg.gradientPercent / 100.0);
    }
    return alt;
  }

  double _gradientAt(double distM, List<StageSegment> segments) {
    if (segments.isEmpty) return 0.0;
    double covered = 0.0;
    for (final seg in segments) {
      final segLen = seg.lengthKm * 1000.0;
      if (distM <= covered + segLen) {
        return seg.gradientPercent;
      }
      covered += segLen;
    }
    return segments.last.gradientPercent;
  }
}

// =============================================================================
// 7. CUSTOM PAINTER & RESPONSYWNY PANEL STEROWANIA (390x844 / 1024x768 / 1600x900)
// =============================================================================

/// CustomPainter rysujący obiekty [TrafficIslandsAndRailway3dRenderer] w podglądzie 3D.
class TrafficIslandsAndRailway3dPainter extends CustomPainter {
  final TrafficIslandsAndRailway3dRenderer renderer;
  final Scene3DMathProjection projection;
  final StageTrafficIslandsAndRailwayPack pack;
  final double cameraDistanceMeters;
  final double elapsedTimeSeconds;
  final ValueChanged<TrafficIslandsAndRailwayTelemetry>? onTelemetry;

  TrafficIslandsAndRailway3dPainter({
    required this.renderer,
    required this.projection,
    required this.pack,
    required this.cameraDistanceMeters,
    required this.elapsedTimeSeconds,
    this.onTelemetry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    projection.setViewport(width: size.width, height: size.height);
    final telemetry = renderer.render(
      canvas: canvas,
      viewportSize: size,
      projection: projection,
      pack: pack,
      cameraDistanceMeters: cameraDistanceMeters,
      elapsedTimeSeconds: elapsedTimeSeconds,
    );
    onTelemetry?.call(telemetry);
  }

  @override
  bool shouldRepaint(covariant TrafficIslandsAndRailway3dPainter oldDelegate) {
    return oldDelegate.elapsedTimeSeconds != elapsedTimeSeconds ||
        oldDelegate.cameraDistanceMeters != cameraDistanceMeters ||
        oldDelegate.pack != pack ||
        oldDelegate.renderer.config.enabled != renderer.config.enabled;
  }
}

/// Responsywny panel sterowania i telemetrii przeszkód drogowych 3D (Inter + AppColors).
class TrafficIslandsAndRailwayControlPanel extends StatefulWidget {
  final TrafficIslandsAndRailwayConfig config;
  final TrafficIslandsAndRailwayTelemetry telemetry;
  final RailwayBarrierState railwayState;
  final ValueChanged<TrafficIslandsAndRailwayConfig>? onConfigChanged;
  final ValueChanged<RailwayBarrierState>? onRailwayStateChanged;

  const TrafficIslandsAndRailwayControlPanel({
    super.key,
    required this.config,
    required this.telemetry,
    this.railwayState = RailwayBarrierState.warningLightsFlashing,
    this.onConfigChanged,
    this.onRailwayStateChanged,
  });

  @override
  State<TrafficIslandsAndRailwayControlPanel> createState() =>
      _TrafficIslandsAndRailwayControlPanelState();
}

class _TrafficIslandsAndRailwayControlPanelState
    extends State<TrafficIslandsAndRailwayControlPanel> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 480.0;
        final double padding = isCompact ? 12.0 : 16.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 12.0),
                _buildTelemetryRow(isCompact),
                const SizedBox(height: 12.0),
                _buildLayerToggles(),
                const SizedBox(height: 12.0),
                _buildRailwayBarrierControls(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final bool isEnabled = widget.config.enabled;
    return Row(
      children: [
        Container(
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled ? AppColors.statusSuccess : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            'Wysepki, Tory i Moto Sędziowie 3D',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 13.0 : 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        _HazardControlChip(
          label: isEnabled ? 'Aktywny' : 'Wyłączony',
          isActive: isEnabled,
          isDisabled: widget.onConfigChanged == null,
          activeBorderColor: AppColors.statusSuccess,
          onTap: widget.onConfigChanged == null
              ? null
              : () => widget.onConfigChanged!(
                    widget.config.copyWith(enabled: !isEnabled),
                  ),
        ),
      ],
    );
  }

  Widget _buildTelemetryRow(bool isCompact) {
    final nearestText = widget.telemetry.nearestHazardDistanceMeters != null
        ? '${widget.telemetry.nearestHazardDistanceMeters!.toStringAsFixed(0)} m'
        : '--';
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _TelemetryBadge(
          label: 'Wysepki',
          value: '${widget.telemetry.visibleIslandsCount}',
          accent: AppColors.accentBlue,
          isCompact: isCompact,
        ),
        _TelemetryBadge(
          label: 'Progi',
          value: '${widget.telemetry.visibleSpeedBumpsCount}',
          accent: AppColors.amberWarning,
          isCompact: isCompact,
        ),
        _TelemetryBadge(
          label: 'Przejazdy',
          value: '${widget.telemetry.visibleRailwaysCount}',
          accent: AppColors.crimsonAlert,
          isCompact: isCompact,
        ),
        _TelemetryBadge(
          label: 'Moto Sędziowie',
          value: '${widget.telemetry.visibleMarshalMotosCount}',
          accent: AppColors.goldAccent,
          isCompact: isCompact,
        ),
        _TelemetryBadge(
          label: 'Najbliższa strefa',
          value: nearestText,
          accent: AppColors.cyanAccent,
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildLayerToggles() {
    final bool masterDisabled =
        !widget.config.enabled || widget.onConfigChanged == null;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _HazardControlChip(
          label: 'Wysepki (C-9/C-10)',
          isActive: widget.config.showTrafficIslands,
          isDisabled: masterDisabled,
          onTap: masterDisabled
              ? null
              : () => widget.onConfigChanged!(
                    widget.config.copyWith(
                      showTrafficIslands: !widget.config.showTrafficIslands,
                    ),
                  ),
        ),
        _HazardControlChip(
          label: 'Progi zwalniające',
          isActive: widget.config.showSpeedBumps,
          isDisabled: masterDisabled,
          onTap: masterDisabled
              ? null
              : () => widget.onConfigChanged!(
                    widget.config.copyWith(
                      showSpeedBumps: !widget.config.showSpeedBumps,
                    ),
                  ),
        ),
        _HazardControlChip(
          label: 'Tory i światła',
          isActive: widget.config.showRailwayCrossings,
          isDisabled: masterDisabled,
          onTap: masterDisabled
              ? null
              : () => widget.onConfigChanged!(
                    widget.config.copyWith(
                      showRailwayCrossings: !widget.config.showRailwayCrossings,
                    ),
                  ),
        ),
        _HazardControlChip(
          label: 'Moto: gwizdek + flaga',
          isActive: widget.config.showMarshalMotos,
          isDisabled: masterDisabled,
          onTap: masterDisabled
              ? null
              : () => widget.onConfigChanged!(
                    widget.config.copyWith(
                      showMarshalMotos: !widget.config.showMarshalMotos,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildRailwayBarrierControls(bool isCompact) {
    final bool isDisabled =
        !widget.config.enabled || widget.onRailwayStateChanged == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stan rogatek przejazdu kolejowego',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 11.0 : 12.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: RailwayBarrierState.values.map((state) {
            final bool selected = widget.railwayState == state;
            return _HazardControlChip(
              label: state.labelPl,
              isActive: selected,
              isDisabled: isDisabled,
              activeBorderColor: state == RailwayBarrierState.open
                  ? AppColors.statusSuccess
                  : AppColors.crimsonAlert,
              onTap: isDisabled ? null : () => widget.onRailwayStateChanged!(state),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _TelemetryBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool isCompact;

  const _TelemetryBadge({
    required this.label,
    required this.value,
    required this.accent,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 10.0,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 12.0 : 13.0,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _HazardControlChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isDisabled;
  final Color activeBorderColor;
  final VoidCallback? onTap;

  const _HazardControlChip({
    required this.label,
    required this.isActive,
    required this.isDisabled,
    this.activeBorderColor = AppColors.goldAccent,
    this.onTap,
  });

  @override
  State<_HazardControlChip> createState() => _HazardControlChipState();
}

class _HazardControlChipState extends State<_HazardControlChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isDisabled
        ? AppColors.background.withValues(alpha: 0.45)
        : _isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : widget.isActive
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.65)
                    : AppColors.background;

    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isActive
            ? widget.activeBorderColor
            : _isHovered && !widget.isDisabled
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isDisabled ? null : widget.onTap,
            onHighlightChanged: (p) {
              if (!widget.isDisabled) {
                setState(() => _isPressed = p);
              }
            },
            borderRadius: BorderRadius.circular(10.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.5),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : widget.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
