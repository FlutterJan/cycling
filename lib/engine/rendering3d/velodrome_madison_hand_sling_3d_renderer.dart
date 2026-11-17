// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/velodrome_track_and_hour_record_model.dart';
import '../physics/velodrome_keirin_and_madison_sling_solver.dart';
import 'velodrome_wooden_bowl_3d_renderer.dart';

// =============================================================================
// 1. TRYBY WYŚCIGU, KAMERY I KONFIGURACJA RENDERERA MADISON & KEIRIN 3D
// =============================================================================

/// Dyscyplina torowa renderowana na welodromie 3D.
enum VelodromeTrackDisciplineMode {
  madison('Madison (Pary)', 'MADISON'),
  keirin('Keirin (Derny)', 'KEIRIN');

  final String labelPl;
  final String shortTag;

  const VelodromeTrackDisciplineMode(this.labelPl, this.shortTag);
}

/// Tryby kamery 3D dla wyścigów Madison i Keirin.
enum MadisonKeirinCameraMode {
  chaseSling('Pościg Zmiany', 'SLING CAM'),
  dernyMoto('Motocykl Derny', 'DERNY CAM'),
  highBankingBowl('Trybuny 42°', 'BOWL TV'),
  infieldScoreboard('Tablica Punktów', 'SCOREBOARD');

  final String labelPl;
  final String shortTag;

  const MadisonKeirinCameraMode(this.labelPl, this.shortTag);
}

/// Konfiguracja renderera 3D wyścigu Madison i Keirin na welodromie.
class VelodromeMadisonKeirinConfig {
  final VelodromeFacilitySpec facility;
  final VelodromeTrackDisciplineMode discipline;
  final MadisonKeirinCameraMode cameraMode;
  final double fieldOfViewDegrees;
  final double trackWidthMeters;
  final double apronWidthMeters;
  final int totalLaps;
  final int sprintIntervalLaps;
  final bool showDernyMotorbike;
  final bool showSlingMomentumVectors;
  final bool showInfieldSprintBoard;
  final bool showTelemetryOverlay;

  const VelodromeMadisonKeirinConfig({
    this.facility = const VelodromeFacilitySpec(
      id: 'grenchen_tissot',
      name: 'Tissot Velodrome Grenchen',
      city: 'Grenchen',
      countryCode: 'SUI',
      trackLengthMeters: 250.0,
      turnBankingDegrees: 42.0,
      straightBankingDegrees: 13.0,
      altitudeMeters: 451.0,
      woodSurface: VelodromeWoodSurface.siberianPine,
      isIndoor: true,
      turnRadiusMeters: 23.0,
    ),
    this.discipline = VelodromeTrackDisciplineMode.madison,
    this.cameraMode = MadisonKeirinCameraMode.chaseSling,
    this.fieldOfViewDegrees = 56.0,
    this.trackWidthMeters = 7.5,
    this.apronWidthMeters = 0.75,
    this.totalLaps = 50,
    this.sprintIntervalLaps = 10,
    this.showDernyMotorbike = true,
    this.showSlingMomentumVectors = true,
    this.showInfieldSprintBoard = true,
    this.showTelemetryOverlay = true,
  });

  VelodromeMadisonKeirinConfig copyWith({
    VelodromeFacilitySpec? facility,
    VelodromeTrackDisciplineMode? discipline,
    MadisonKeirinCameraMode? cameraMode,
    double? fieldOfViewDegrees,
    double? trackWidthMeters,
    double? apronWidthMeters,
    int? totalLaps,
    int? sprintIntervalLaps,
    bool? showDernyMotorbike,
    bool? showSlingMomentumVectors,
    bool? showInfieldSprintBoard,
    bool? showTelemetryOverlay,
  }) {
    return VelodromeMadisonKeirinConfig(
      facility: facility ?? this.facility,
      discipline: discipline ?? this.discipline,
      cameraMode: cameraMode ?? this.cameraMode,
      fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
      trackWidthMeters: trackWidthMeters ?? this.trackWidthMeters,
      apronWidthMeters: apronWidthMeters ?? this.apronWidthMeters,
      totalLaps: totalLaps ?? this.totalLaps,
      sprintIntervalLaps: sprintIntervalLaps ?? this.sprintIntervalLaps,
      showDernyMotorbike: showDernyMotorbike ?? this.showDernyMotorbike,
      showSlingMomentumVectors:
          showSlingMomentumVectors ?? this.showSlingMomentumVectors,
      showInfieldSprintBoard:
          showInfieldSprintBoard ?? this.showInfieldSprintBoard,
      showTelemetryOverlay: showTelemetryOverlay ?? this.showTelemetryOverlay,
    );
  }
}

// =============================================================================
// 2. MODELE AKTORÓW 3D: PARY MADISON, MOTOCYKL DERNY, TABLICA PUNKTÓW
// =============================================================================

/// Para kolarzy w wyścigu Madison wraz ze stanem zmiany w locie (`Hand Sling`).
class MadisonHandSlingPair3D {
  final String teamId;
  final String teamCode;
  final Color jerseyColor;
  final Color secondaryColor;
  final String activeRiderName;
  final String reliefRiderName;
  final double activeDistanceMeters;
  final double activeMetersAboveBlackLine;
  final double activeSpeedKmh;
  final double reliefDistanceMeters;
  final double reliefMetersAboveBlackLine;
  final double reliefSpeedKmh;
  final bool isSlingInProgress;
  final double slingProgress01;
  final MadisonSlingQuality lastSlingQuality;
  final int sprintPoints;
  final int lapsGained;
  final bool isHeroTeam;

  const MadisonHandSlingPair3D({
    required this.teamId,
    required this.teamCode,
    required this.jerseyColor,
    required this.secondaryColor,
    required this.activeRiderName,
    required this.reliefRiderName,
    required this.activeDistanceMeters,
    required this.activeMetersAboveBlackLine,
    required this.activeSpeedKmh,
    required this.reliefDistanceMeters,
    required this.reliefMetersAboveBlackLine,
    required this.reliefSpeedKmh,
    this.isSlingInProgress = false,
    this.slingProgress01 = 0.0,
    this.lastSlingQuality = MadisonSlingQuality.textbookSlingshot,
    this.sprintPoints = 0,
    this.lapsGained = 0,
    this.isHeroTeam = false,
  });
}

/// Stan motocykla prowadzącego Derny w wyścigu Keirin lub neutralizacji Madison.
class KeirinDernyMotorbike3D {
  final double distanceMeters;
  final double metersAboveBlackLine;
  final double speedKmh;
  final KeirinRacePhase phase;
  final bool isPullingOff;
  final double pullOffProgress01;

  const KeirinDernyMotorbike3D({
    required this.distanceMeters,
    required this.metersAboveBlackLine,
    required this.speedKmh,
    required this.phase,
    this.isPullingOff = false,
    this.pullOffProgress01 = 0.0,
  });
}

/// Wpis na elektronicznej tablicy punktów sprinterskich co 10 okrążeń.
class MadisonTeamBoardEntry {
  final int rank;
  final String teamCode;
  final Color jerseyColor;
  final int points;
  final int lapsDelta;
  final bool isActiveSling;

  const MadisonTeamBoardEntry({
    required this.rank,
    required this.teamCode,
    required this.jerseyColor,
    required this.points,
    required this.lapsDelta,
    this.isActiveSling = false,
  });
}

/// Telemetria klatki renderera 3D Madison & Keirin.
class VelodromeMadisonHandSlingTelemetry {
  final VelodromeTrackDisciplineMode discipline;
  final int currentLap;
  final int totalLaps;
  final int lapsToNextSprint;
  final bool isSprintBellLap;
  final double dernySpeedKmh;
  final KeirinRacePhase dernyPhase;
  final int activeSlingCount;
  final MadisonSlingQuality lastSlingQuality;
  final double lastSlingSpeedGainKmh;
  final int visiblePairsCount;
  final double cameraBankingDegrees;
  final List<MadisonTeamBoardEntry> standings;

  const VelodromeMadisonHandSlingTelemetry({
    required this.discipline,
    required this.currentLap,
    required this.totalLaps,
    required this.lapsToNextSprint,
    required this.isSprintBellLap,
    required this.dernySpeedKmh,
    required this.dernyPhase,
    required this.activeSlingCount,
    required this.lastSlingQuality,
    required this.lastSlingSpeedGainKmh,
    required this.visiblePairsCount,
    required this.cameraBankingDegrees,
    required this.standings,
  });
}

// =============================================================================
// 3. WEWNĘTRZNE STRUKTURY SORTOWANIA GŁĘBOKOŚCIĄ 3D
// =============================================================================

class _ProjectedPoint3D {
  final Offset screen;
  final double depth;
  const _ProjectedPoint3D(this.screen, this.depth);
}

class _SortedTrackQuad {
  final double avgDepth;
  final List<Offset> points;
  final Color fillColor;
  final Color? strokeColor;
  final double strokeWidth;

  const _SortedTrackQuad({
    required this.avgDepth,
    required this.points,
    required this.fillColor,
    this.strokeColor,
    this.strokeWidth = 0.0,
  });
}

class _DepthSortedRenderItem {
  final double depth;
  final void Function(Canvas canvas) draw;

  const _DepthSortedRenderItem({
    required this.depth,
    required this.draw,
  });
}

// =============================================================================
// 4. GŁÓWNY RENDERER 3D WYŚCIGU MADISON I KEIRIN NA WELODROMIE
// =============================================================================

/// Renderer 3D wyścigu Madison i Keirin na krytym welodromie:
/// - wyścigi par Madison z animacją zmiany w locie (`Hand Sling`), chwytem dłoni
///   i wektorami transferu pędu na wirażach 42°–45°,
/// - motocykl prowadzący Derny w wyścigu Keirin (rozpędzanie do 50 km/h i zjazd z toru),
/// - elektroniczna tablica wyników punktacji sprinterskiej co 10 okrążeń na środku toru.
class VelodromeMadisonHandSling3dRenderer {
  final VelodromeMadisonKeirinConfig config;
  late final VelodromeTrackGeometryBuilder geometryBuilder;
  late final List<VelodromeRoofSpotlight3D> spotlights;

  VelodromeMadisonHandSling3dRenderer({required this.config}) {
    geometryBuilder = VelodromeTrackGeometryBuilder(config.facility);
    spotlights = geometryBuilder.buildRoofSpotlights();
  }

  /// Renderuje kompletną scenę 3D wyścigu Madison lub Keirin na przekazanym [Canvas].
  VelodromeMadisonHandSlingTelemetry renderScene({
    required Canvas canvas,
    required Size size,
    required double timeSeconds,
    required List<MadisonHandSlingPair3D> madisonPairs,
    required KeirinDernyMotorbike3D derny,
    required List<VelodromeTrackRider3D> keirinRiders,
    required int currentLap,
    double cameraYawOffsetRadians = 0.0,
  }) {
    if (size.width <= 1 || size.height <= 1) {
      return _emptyTelemetry(currentLap, derny, madisonPairs);
    }

    final double trackLen = config.facility.trackLengthMeters;
    final MadisonHandSlingPair3D? heroPair = madisonPairs.isEmpty
        ? null
        : madisonPairs.firstWhere(
            (p) => p.isHeroTeam,
            orElse: () => madisonPairs.first,
          );

    final double focusDist =
        config.discipline == VelodromeTrackDisciplineMode.keirin
            ? derny.distanceMeters
            : (heroPair?.activeDistanceMeters ?? 0.0);
    final VelodromeTrackSample3D focusSample =
        geometryBuilder.sampleAt(focusDist);

    final _CameraRig rig = _buildCameraRig(
      focusSample: focusSample,
      heroPair: heroPair,
      derny: derny,
      cameraYawOffsetRadians: cameraYawOffsetRadians,
    );

    final Matrix4 viewMatrix = _buildLookAtMatrix(
      eye: rig.position,
      target: rig.target,
      up: Vector3(0.0, 1.0, 0.0),
    );
    final double aspect = size.width / size.height;
    final Matrix4 projMatrix = _buildPerspectiveMatrix(
      fovYRadians: config.fieldOfViewDegrees * (math.pi / 180.0),
      aspect: aspect,
      nearPlane: 0.4,
      farPlane: 340.0,
    );
    final Matrix4 viewProj = projMatrix * viewMatrix;

    // 1. Tło hali welodromu i konstrukcja dachu z reflektorami
    _drawArenaBackground(canvas, size, rig.position, viewProj, timeSeconds);

    // 2. Środek toru (infield) + parkiet welodromu 250 m z liniami torowymi
    _drawTrackAndInfield(
      canvas: canvas,
      size: size,
      viewProj: viewProj,
      trackLen: trackLen,
    );

    // 3. Sortowanie głębokością: tablica sprinterska, motocykl Derny, pary Madison / Keirin
    final List<_DepthSortedRenderItem> items = <_DepthSortedRenderItem>[];

    if (config.showInfieldSprintBoard) {
      final _DepthSortedRenderItem? boardItem = _buildScoreboardRenderItem(
        size: size,
        viewProj: viewProj,
        timeSeconds: timeSeconds,
        currentLap: currentLap,
        madisonPairs: madisonPairs,
        derny: derny,
      );
      if (boardItem != null) {
        items.add(boardItem);
      }
    }

    if (config.showDernyMotorbike &&
        (config.discipline == VelodromeTrackDisciplineMode.keirin ||
            currentLap <= 2)) {
      final _DepthSortedRenderItem? dernyItem = _buildDernyRenderItem(
        size: size,
        viewProj: viewProj,
        timeSeconds: timeSeconds,
        derny: derny,
      );
      if (dernyItem != null) {
        items.add(dernyItem);
      }
    }

    int visiblePairs = 0;
    if (config.discipline == VelodromeTrackDisciplineMode.madison) {
      for (final MadisonHandSlingPair3D pair in madisonPairs) {
        final _DepthSortedRenderItem? pairItem = _buildMadisonPairRenderItem(
          size: size,
          viewProj: viewProj,
          timeSeconds: timeSeconds,
          pair: pair,
        );
        if (pairItem != null) {
          visiblePairs++;
          items.add(pairItem);
        }
      }
    } else {
      for (int i = 0; i < keirinRiders.length; i++) {
        final VelodromeTrackRider3D rider = keirinRiders[i];
        final _DepthSortedRenderItem? riderItem = _buildSingleTrackRiderItem(
          size: size,
          viewProj: viewProj,
          timeSeconds: timeSeconds,
          rider: rider,
          isHero: i == 0,
        );
        if (riderItem != null) {
          visiblePairs++;
          items.add(riderItem);
        }
      }
    }

    items.sort((a, b) => b.depth.compareTo(a.depth));
    for (final _DepthSortedRenderItem item in items) {
      item.draw(canvas);
    }

    final int interval = math.max(1, config.sprintIntervalLaps);
    final int remainder = currentLap % interval;
    final int lapsToNext = remainder == 0 ? 0 : interval - remainder;
    final bool isBellLap = lapsToNext == 1 || remainder == 0;

    final List<MadisonHandSlingPair3D> sortedPairs =
        List<MadisonHandSlingPair3D>.from(madisonPairs)
          ..sort((a, b) {
            final int lapCmp = b.lapsGained.compareTo(a.lapsGained);
            if (lapCmp != 0) return lapCmp;
            return b.sprintPoints.compareTo(a.sprintPoints);
          });

    final List<MadisonTeamBoardEntry> standings = <MadisonTeamBoardEntry>[
      for (int i = 0; i < sortedPairs.length; i++)
        MadisonTeamBoardEntry(
          rank: i + 1,
          teamCode: sortedPairs[i].teamCode,
          jerseyColor: sortedPairs[i].jerseyColor,
          points: sortedPairs[i].sprintPoints,
          lapsDelta: sortedPairs[i].lapsGained,
          isActiveSling: sortedPairs[i].isSlingInProgress,
        ),
    ];

    final int activeSlingCount =
        madisonPairs.where((p) => p.isSlingInProgress).length;
    final MadisonSlingQuality lastQuality = heroPair?.lastSlingQuality ??
        (madisonPairs.isNotEmpty
            ? madisonPairs.first.lastSlingQuality
            : MadisonSlingQuality.cleanExchange);

    return VelodromeMadisonHandSlingTelemetry(
      discipline: config.discipline,
      currentLap: currentLap,
      totalLaps: config.totalLaps,
      lapsToNextSprint: lapsToNext,
      isSprintBellLap: isBellLap,
      dernySpeedKmh: derny.speedKmh,
      dernyPhase: derny.phase,
      activeSlingCount: activeSlingCount,
      lastSlingQuality: lastQuality,
      lastSlingSpeedGainKmh: activeSlingCount > 0 ? 11.4 : 8.2,
      visiblePairsCount: visiblePairs,
      cameraBankingDegrees: focusSample.bankingDegrees,
      standings: standings,
    );
  }

  VelodromeMadisonHandSlingTelemetry _emptyTelemetry(
    int currentLap,
    KeirinDernyMotorbike3D derny,
    List<MadisonHandSlingPair3D> pairs,
  ) {
    return VelodromeMadisonHandSlingTelemetry(
      discipline: config.discipline,
      currentLap: currentLap,
      totalLaps: config.totalLaps,
      lapsToNextSprint: config.sprintIntervalLaps,
      isSprintBellLap: false,
      dernySpeedKmh: derny.speedKmh,
      dernyPhase: derny.phase,
      activeSlingCount: 0,
      lastSlingQuality: MadisonSlingQuality.cleanExchange,
      lastSlingSpeedGainKmh: 0.0,
      visiblePairsCount: pairs.length,
      cameraBankingDegrees: config.facility.turnBankingDegrees,
      standings: const [],
    );
  }

  _CameraRig _buildCameraRig({
    required VelodromeTrackSample3D focusSample,
    required MadisonHandSlingPair3D? heroPair,
    required KeirinDernyMotorbike3D derny,
    required double cameraYawOffsetRadians,
  }) {
    final double yaw = cameraYawOffsetRadians;
    final double cosY = math.cos(yaw);
    final double sinY = math.sin(yaw);

    Vector3 rotateY(Vector3 v) => Vector3(
          v.x * cosY - v.z * sinY,
          v.y,
          v.x * sinY + v.z * cosY,
        );

    switch (config.cameraMode) {
      case MadisonKeirinCameraMode.chaseSling:
        final double lateral = heroPair?.activeMetersAboveBlackLine ?? 1.1;
        final Vector3 target =
            focusSample.pointAt(lateral + 0.6, verticalOffsetMeters: 1.0);
        final Vector3 localOffset = rotateY(
          (-focusSample.tangent * 9.5) +
              (focusSample.outwardRadial * 2.4) +
              Vector3(0.0, 3.6, 0.0),
        );
        return _CameraRig(position: target + localOffset, target: target);

      case MadisonKeirinCameraMode.dernyMoto:
        final VelodromeTrackSample3D dSample =
            geometryBuilder.sampleAt(derny.distanceMeters);
        final Vector3 target = dSample.pointAt(
          derny.metersAboveBlackLine + 0.4,
          verticalOffsetMeters: 1.0,
        );
        final Vector3 localOffset = rotateY(
          (dSample.tangent * 6.8) +
              (dSample.outwardRadial * 2.1) +
              Vector3(0.0, 2.5, 0.0),
        );
        return _CameraRig(position: target + localOffset, target: target);

      case MadisonKeirinCameraMode.highBankingBowl:
        final Vector3 center = Vector3(0.0, 1.5, 0.0);
        final Vector3 basePos = Vector3(44.0, 22.0, 34.0);
        return _CameraRig(
          position: rotateY(basePos),
          target: center,
        );

      case MadisonKeirinCameraMode.infieldScoreboard:
        final Vector3 boardTarget = Vector3(0.0, 6.2, 0.0);
        final Vector3 eye = rotateY(Vector3(-22.0, 4.2, 16.0));
        return _CameraRig(position: eye, target: boardTarget);
    }
  }

  void _drawArenaBackground(
    Canvas canvas,
    Size size,
    Vector3 cameraPos,
    Matrix4 viewProj,
    double timeSeconds,
  ) {
    final Rect fullRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0D12),
          Color(0xFF131822),
          AppColors.background,
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    // Kratownica dachu hali i reflektory
    final Paint trussPaint = Paint()
      ..color = const Color(0xFF232936).withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double roofY = 18.8;
    const int archSegments = 16;
    final double trackLen = config.facility.trackLengthMeters;
    for (int i = 0; i < archSegments; i++) {
      final double sA = (i / archSegments) * trackLen;
      final double sB = ((i + 1) / archSegments) * trackLen;
      final VelodromeTrackSample3D a = geometryBuilder.sampleAt(sA);
      final VelodromeTrackSample3D b = geometryBuilder.sampleAt(sB);
      final Vector3 roofA =
          a.innerEdge + (a.outwardRadial * 4.5) + Vector3(0.0, roofY, 0.0);
      final Vector3 roofB =
          b.innerEdge + (b.outwardRadial * 4.5) + Vector3(0.0, roofY, 0.0);
      final _ProjectedPoint3D? pA = _project(roofA, viewProj, size);
      final _ProjectedPoint3D? pB = _project(roofB, viewProj, size);
      if (pA != null && pB != null) {
        canvas.drawLine(pA.screen, pB.screen, trussPaint);
      }
    }

    for (final VelodromeRoofSpotlight3D light in spotlights) {
      final _ProjectedPoint3D? p = _project(light.position, viewProj, size);
      if (p == null || p.depth > 180.0) continue;
      final double pulse =
          0.85 + 0.15 * math.sin(timeSeconds * 1.6 + light.position.x * 0.2);
      final double radius = (220.0 / math.max(8.0, p.depth)).clamp(3.0, 14.0);
      final Paint glowPaint = Paint()
        ..color = light.lightColor.withValues(alpha: 0.22 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawCircle(p.screen, radius * 1.8, glowPaint);
      canvas.drawCircle(
        p.screen,
        radius * 0.45,
        Paint()..color = light.lightColor.withValues(alpha: 0.9),
      );
    }
  }

  void _drawTrackAndInfield({
    required Canvas canvas,
    required Size size,
    required Matrix4 viewProj,
    required double trackLen,
  }) {
    const int slices = 90;
    final double step = trackLen / slices;
    final List<_SortedTrackQuad> quads = <_SortedTrackQuad>[];

    // Środek welodromu (ciemna płyta techniczna)
    final Vector3 infieldCenter = Vector3(0.0, 0.0, 0.0);
    final _ProjectedPoint3D? pCenter = _project(infieldCenter, viewProj, size);
    if (pCenter != null) {
      for (int i = 0; i < slices; i += 3) {
        final double s0 = i * step;
        final double s1 = ((i + 3) % slices) * step;
        final VelodromeTrackSample3D a = geometryBuilder.sampleAt(s0);
        final VelodromeTrackSample3D b = geometryBuilder.sampleAt(s1);
        final _ProjectedPoint3D? pA =
            _project(a.pointAt(-config.apronWidthMeters), viewProj, size);
        final _ProjectedPoint3D? pB =
            _project(b.pointAt(-config.apronWidthMeters), viewProj, size);
        if (pA != null && pB != null) {
          final double avgD = (pCenter.depth + pA.depth + pB.depth) / 3.0;
          quads.add(
            _SortedTrackQuad(
              avgDepth: avgD,
              points: [pCenter.screen, pA.screen, pB.screen],
              fillColor: const Color(0xFF131720),
            ),
          );
        }
      }
    }

    for (int i = 0; i < slices; i++) {
      final double s0 = i * step;
      final double s1 = (i + 1) * step;
      final VelodromeTrackSample3D a = geometryBuilder.sampleAt(s0);
      final VelodromeTrackSample3D b = geometryBuilder.sampleAt(s1);

      // Pas Côte d'Azur (błękitny pas bezpieczeństwa)
      _addQuadIfVisible(
        quads: quads,
        size: size,
        viewProj: viewProj,
        v0: a.pointAt(-config.apronWidthMeters),
        v1: a.pointAt(0.0),
        v2: b.pointAt(0.0),
        v3: b.pointAt(-config.apronWidthMeters),
        fillColor: const Color(0xFF1D6FA5),
      );

      // Główna nawierzchnia parkietu z sosny syberyjskiej
      final double shade = 0.88 + 0.12 * math.sin(a.bankingRadians * 2.0);
      final Color woodColor = Color.fromARGB(
        255,
        (196 * shade).round().clamp(0, 255),
        (146 * shade).round().clamp(0, 255),
        (92 * shade).round().clamp(0, 255),
      );
      _addQuadIfVisible(
        quads: quads,
        size: size,
        viewProj: viewProj,
        v0: a.pointAt(0.0),
        v1: a.pointAt(config.trackWidthMeters),
        v2: b.pointAt(config.trackWidthMeters),
        v3: b.pointAt(0.0),
        fillColor: woodColor,
        strokeColor: const Color(0xFF8C6239).withValues(alpha: 0.35),
        strokeWidth: 0.7,
      );

      // Zewnętrzna banda reklamowa welodromu
      _addQuadIfVisible(
        quads: quads,
        size: size,
        viewProj: viewProj,
        v0: a.pointAt(config.trackWidthMeters),
        v1: a.pointAt(config.trackWidthMeters, verticalOffsetMeters: 1.05),
        v2: b.pointAt(config.trackWidthMeters, verticalOffsetMeters: 1.05),
        v3: b.pointAt(config.trackWidthMeters),
        fillColor: i % 4 < 2 ? AppColors.surface : AppColors.primaryAccent,
        strokeColor: AppColors.cardBorder,
        strokeWidth: 0.8,
      );
    }

    quads.sort((a, b) => b.avgDepth.compareTo(a.avgDepth));
    for (final _SortedTrackQuad q in quads) {
      final Path path = Path()..moveTo(q.points.first.dx, q.points.first.dy);
      for (int i = 1; i < q.points.length; i++) {
        path.lineTo(q.points[i].dx, q.points[i].dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = q.fillColor);
      if (q.strokeColor != null && q.strokeWidth > 0.0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = q.strokeColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = q.strokeWidth,
        );
      }
    }

    // Oficjalne linie torowe UCI: czarna (0.20 m), czerwona (0.85 m), niebieska (2.45 m)
    _drawTrackLine(canvas, size, viewProj, 0.20, const Color(0xFF111827), 2.2);
    _drawTrackLine(canvas, size, viewProj, 0.85, AppColors.crimsonAlert, 2.0);
    _drawTrackLine(canvas, size, viewProj, 2.45, AppColors.accentBlue, 2.0);
  }

  void _addQuadIfVisible({
    required List<_SortedTrackQuad> quads,
    required Size size,
    required Matrix4 viewProj,
    required Vector3 v0,
    required Vector3 v1,
    required Vector3 v2,
    required Vector3 v3,
    required Color fillColor,
    Color? strokeColor,
    double strokeWidth = 0.0,
  }) {
    final _ProjectedPoint3D? p0 = _project(v0, viewProj, size);
    final _ProjectedPoint3D? p1 = _project(v1, viewProj, size);
    final _ProjectedPoint3D? p2 = _project(v2, viewProj, size);
    final _ProjectedPoint3D? p3 = _project(v3, viewProj, size);
    if (p0 == null || p1 == null || p2 == null || p3 == null) return;
    final double avgDepth = (p0.depth + p1.depth + p2.depth + p3.depth) * 0.25;
    quads.add(
      _SortedTrackQuad(
        avgDepth: avgDepth,
        points: [p0.screen, p1.screen, p2.screen, p3.screen],
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      ),
    );
  }

  void _drawTrackLine(
    Canvas canvas,
    Size size,
    Matrix4 viewProj,
    double lateralMeters,
    Color color,
    double strokeWidth,
  ) {
    const int segments = 90;
    final double trackLen = config.facility.trackLengthMeters;
    final double step = trackLen / segments;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < segments; i++) {
      final VelodromeTrackSample3D a = geometryBuilder.sampleAt(i * step);
      final VelodromeTrackSample3D b = geometryBuilder.sampleAt((i + 1) * step);
      final _ProjectedPoint3D? pA =
          _project(a.pointAt(lateralMeters, verticalOffsetMeters: 0.02), viewProj, size);
      final _ProjectedPoint3D? pB =
          _project(b.pointAt(lateralMeters, verticalOffsetMeters: 0.02), viewProj, size);
      if (pA != null && pB != null) {
        canvas.drawLine(pA.screen, pB.screen, paint);
      }
    }
  }

  // ===========================================================================
  // 5. ELEKTRONICZNA TABLICA PUNKTÓW SPRINTERSKICH CO 10 OKRĄŻEŃ
  // ===========================================================================

  _DepthSortedRenderItem? _buildScoreboardRenderItem({
    required Size size,
    required Matrix4 viewProj,
    required double timeSeconds,
    required int currentLap,
    required List<MadisonHandSlingPair3D> madisonPairs,
    required KeirinDernyMotorbike3D derny,
  }) {
    final Vector3 anchor = Vector3(0.0, 5.4, 0.0);
    final _ProjectedPoint3D? pCenter = _project(anchor, viewProj, size);
    if (pCenter == null || pCenter.depth > 160.0) return null;

    final double scale = (28.0 / math.max(8.0, pCenter.depth)).clamp(0.45, 1.55);
    final double boardW = 240.0 * scale;
    final double boardH = 128.0 * scale;

    return _DepthSortedRenderItem(
      depth: pCenter.depth,
      draw: (canvas) {
        final Rect rect = Rect.fromCenter(
          center: pCenter.screen,
          width: boardW,
          height: boardH,
        );
        final RRect rrect =
            RRect.fromRectAndRadius(rect, Radius.circular(10 * scale));

        // Słup nośny tablicy
        final _ProjectedPoint3D? pBase =
            _project(Vector3(0.0, 0.0, 0.0), viewProj, size);
        if (pBase != null) {
          canvas.drawLine(
            Offset(pCenter.screen.dx, rect.bottom),
            pBase.screen,
            Paint()
              ..color = const Color(0xFF334155)
              ..strokeWidth = 4.0 * scale,
          );
        }

        // Obudowa LED
        canvas.drawRRect(
          rrect,
          Paint()..color = const Color(0xFF0B0E14).withValues(alpha: 0.94),
        );
        final int interval = math.max(1, config.sprintIntervalLaps);
        final int rem = currentLap % interval;
        final int lapsToSprint = rem == 0 ? 0 : interval - rem;
        final bool bellFlash = (lapsToSprint == 1 || rem == 0) &&
            (math.sin(timeSeconds * 8.0) > 0.0);

        canvas.drawRRect(
          rrect,
          Paint()
            ..color = bellFlash ? AppColors.goldAccent : AppColors.cardBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = (bellFlash ? 2.2 : 1.4) * scale,
        );

        final double pad = 10.0 * scale;
        final String headerText =
            config.discipline == VelodromeTrackDisciplineMode.madison
                ? 'MADISON • LAP $currentLap/${config.totalLaps} • '
                    '${lapsToSprint == 0 ? "SPRINT!" : "SPRINT -$lapsToSprint"}'
                : 'KEIRIN • DERNY ${derny.speedKmh.toStringAsFixed(1)} KM/H';

        _drawBoardText(
          canvas,
          headerText,
          Offset(rect.left + pad, rect.top + 8 * scale),
          fontSize: 9.5 * scale,
          color: bellFlash ? AppColors.goldAccent : AppColors.cyanAccent,
          weight: FontWeight.w800,
        );

        if (config.discipline == VelodromeTrackDisciplineMode.madison) {
          final List<MadisonHandSlingPair3D> topTeams =
              List<MadisonHandSlingPair3D>.from(madisonPairs)
                ..sort((a, b) => b.sprintPoints.compareTo(a.sprintPoints));
          final int rows = math.min(4, topTeams.length);
          for (int i = 0; i < rows; i++) {
            final MadisonHandSlingPair3D t = topTeams[i];
            final double y = rect.top + (28 + i * 21) * scale;
            canvas.drawCircle(
              Offset(rect.left + pad + 4 * scale, y + 6 * scale),
              4.0 * scale,
              Paint()..color = t.jerseyColor,
            );
            _drawBoardText(
              canvas,
              '${i + 1}. ${t.teamCode}  ${t.lapsGained >= 0 ? "+${t.lapsGained}L" : "${t.lapsGained}L"}',
              Offset(rect.left + pad + 13 * scale, y),
              fontSize: 9.0 * scale,
              color: AppColors.textPrimary,
              weight: FontWeight.w700,
            );
            _drawBoardText(
              canvas,
              '${t.sprintPoints} PTS',
              Offset(rect.right - pad - 44 * scale, y),
              fontSize: 9.0 * scale,
              color: i == 0 ? AppColors.goldAccent : AppColors.emeraldGreen,
              weight: FontWeight.w800,
            );
          }
        } else {
          _drawBoardText(
            canvas,
            'FAZA: ${derny.phase.labelPl.toUpperCase()}',
            Offset(rect.left + pad, rect.top + 36 * scale),
            fontSize: 10.0 * scale,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          );
          _drawBoardText(
            canvas,
            derny.isPullingOff
                ? 'ZJAZD DERNY — SPRINT 750M!'
                : 'ZAKAZ WYPRZEDZANIA DERNY',
            Offset(rect.left + pad, rect.top + 60 * scale),
            fontSize: 9.0 * scale,
            color: derny.isPullingOff
                ? AppColors.amberWarning
                : AppColors.statusSuccess,
            weight: FontWeight.w800,
          );
        }
      },
    );
  }

  void _drawBoardText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required Color color,
    required FontWeight weight,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize.clamp(6.0, 20.0),
          fontWeight: weight,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, offset);
  }

  // ===========================================================================
  // 6. RENDEROWANIE MOTOCYKLA PROWADZĄCEGO DERNY W 3D
  // ===========================================================================

  _DepthSortedRenderItem? _buildDernyRenderItem({
    required Size size,
    required Matrix4 viewProj,
    required double timeSeconds,
    required KeirinDernyMotorbike3D derny,
  }) {
    final double effectiveLateral = derny.isPullingOff
        ? derny.metersAboveBlackLine + (derny.pullOffProgress01 * 4.2)
        : derny.metersAboveBlackLine;
    final VelodromeTrackSample3D sample =
        geometryBuilder.sampleAt(derny.distanceMeters);
    final Vector3 basePos = sample.pointAt(effectiveLateral);
    final _ProjectedPoint3D? pBase = _project(basePos, viewProj, size);
    if (pBase == null || pBase.depth > 150.0) return null;

    final Vector3 frontWheel =
        basePos + (sample.tangent * 0.85) + (sample.surfaceNormal * 0.30);
    final Vector3 rearWheel =
        basePos - (sample.tangent * 0.85) + (sample.surfaceNormal * 0.30);
    final Vector3 seatPos =
        basePos - (sample.tangent * 0.15) + (sample.surfaceNormal * 1.05);
    final Vector3 riderHead =
        basePos + (sample.tangent * 0.10) + (sample.surfaceNormal * 1.62);
    final Vector3 rollerBar =
        basePos - (sample.tangent * 1.25) + (sample.surfaceNormal * 0.32);

    final _ProjectedPoint3D? pFront = _project(frontWheel, viewProj, size);
    final _ProjectedPoint3D? pRear = _project(rearWheel, viewProj, size);
    final _ProjectedPoint3D? pSeat = _project(seatPos, viewProj, size);
    final _ProjectedPoint3D? pHead = _project(riderHead, viewProj, size);
    final _ProjectedPoint3D? pRoller = _project(rollerBar, viewProj, size);
    if (pFront == null ||
        pRear == null ||
        pSeat == null ||
        pHead == null ||
        pRoller == null) {
      return null;
    }

    final double wheelR = (140.0 / math.max(4.0, pBase.depth)).clamp(3.0, 18.0);

    return _DepthSortedRenderItem(
      depth: pBase.depth,
      draw: (canvas) {
        // Cień pod motocyklem
        canvas.drawOval(
          Rect.fromCenter(
            center: pBase.screen,
            width: wheelR * 4.2,
            height: wheelR * 1.4,
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.45),
        );

        // Koła motocykla Derny
        final Paint tirePaint = Paint()
          ..color = const Color(0xFF1F2937)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (wheelR * 0.35).clamp(1.5, 5.0);
        canvas.drawCircle(pFront.screen, wheelR, tirePaint);
        canvas.drawCircle(pRear.screen, wheelR, tirePaint);

        // Rolka dystansowa z tyłu Derny
        canvas.drawLine(
          pRear.screen,
          pRoller.screen,
          Paint()
            ..color = AppColors.goldAccent
            ..strokeWidth = (wheelR * 0.32).clamp(1.5, 4.5),
        );

        // Korpus / rama Derny (bordowo-złota)
        canvas.drawLine(
          pRear.screen,
          pFront.screen,
          Paint()
            ..color = AppColors.primaryAccent
            ..strokeWidth = (wheelR * 0.65).clamp(2.5, 8.0)
            ..strokeCap = StrokeCap.round,
        );

        // Pacer na motocyklu
        canvas.drawLine(
          pSeat.screen,
          pHead.screen,
          Paint()
            ..color = const Color(0xFF111827)
            ..strokeWidth = (wheelR * 0.72).clamp(2.5, 9.0)
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          pHead.screen,
          (wheelR * 0.48).clamp(2.5, 7.0),
          Paint()..color = AppColors.goldAccent,
        );

        // Etykieta DERNY
        _drawBoardText(
          canvas,
          'DERNY ${derny.speedKmh.toStringAsFixed(0)} km/h',
          Offset(pHead.screen.dx - 28, pHead.screen.dy - 18),
          fontSize: 10.0,
          color: AppColors.goldAccent,
          weight: FontWeight.w800,
        );
      },
    );
  }

  // ===========================================================================
  // 7. RENDEROWANIE PAR MADISON I ZMIANY W LOCIE (`HAND SLING`)
  // ===========================================================================

  _DepthSortedRenderItem? _buildMadisonPairRenderItem({
    required Size size,
    required Matrix4 viewProj,
    required double timeSeconds,
    required MadisonHandSlingPair3D pair,
  }) {
    final VelodromeTrackSample3D activeSample =
        geometryBuilder.sampleAt(pair.activeDistanceMeters);
    final Vector3 activePos =
        activeSample.pointAt(pair.activeMetersAboveBlackLine);
    final _ProjectedPoint3D? pActive = _project(activePos, viewProj, size);
    if (pActive == null || pActive.depth > 155.0) return null;

    final VelodromeTrackSample3D reliefSample =
        geometryBuilder.sampleAt(pair.reliefDistanceMeters);
    final Vector3 reliefPos =
        reliefSample.pointAt(pair.reliefMetersAboveBlackLine);
    final _ProjectedPoint3D? pRelief = _project(reliefPos, viewProj, size);

    return _DepthSortedRenderItem(
      depth: pActive.depth,
      draw: (canvas) {
        // Kolarz aktywny na dole toru
        _draw3dTrackCyclist(
          canvas: canvas,
          size: size,
          viewProj: viewProj,
          sample: activeSample,
          lateralMeters: pair.activeMetersAboveBlackLine,
          jerseyColor: pair.jerseyColor,
          helmetColor: pair.secondaryColor,
          isHero: pair.isHeroTeam,
        );

        // Kolarz rezerwowy / wchodzący do gry
        if (pRelief != null && pRelief.depth < 155.0) {
          _draw3dTrackCyclist(
            canvas: canvas,
            size: size,
            viewProj: viewProj,
            sample: reliefSample,
            lateralMeters: pair.reliefMetersAboveBlackLine,
            jerseyColor: pair.jerseyColor.withValues(alpha: 0.92),
            helmetColor: AppColors.textPrimary,
            isHero: pair.isHeroTeam,
          );
        }

        // Animacja chwytu za rękę (`Hand Sling`) + wektor pędu
        if (pair.isSlingInProgress && pRelief != null) {
          final Vector3 handA = activePos +
              (activeSample.surfaceCrossVector * 0.35) +
              (activeSample.surfaceNormal * 1.15);
          final Vector3 handB = reliefPos -
              (reliefSample.surfaceCrossVector * 0.35) +
              (reliefSample.surfaceNormal * 1.15);
          final _ProjectedPoint3D? pHandA = _project(handA, viewProj, size);
          final _ProjectedPoint3D? pHandB = _project(handB, viewProj, size);

          if (pHandA != null && pHandB != null) {
            final double pulse =
                0.6 + 0.4 * math.sin(timeSeconds * 16.0 + pair.slingProgress01);
            final Color slingColor =
                pair.lastSlingQuality == MadisonSlingQuality.textbookSlingshot
                    ? AppColors.goldAccent
                    : AppColors.cyanAccent;

            // Złączone ramiona przekazujące pęd
            canvas.drawLine(
              pHandA.screen,
              pHandB.screen,
              Paint()
                ..color = slingColor
                ..strokeWidth = 3.2
                ..strokeCap = StrokeCap.round,
            );

            final Offset claspMid = Offset(
              (pHandA.screen.dx + pHandB.screen.dx) * 0.5,
              (pHandA.screen.dy + pHandB.screen.dy) * 0.5,
            );
            canvas.drawCircle(
              claspMid,
              6.5 * pulse,
              Paint()
                ..color = slingColor.withValues(alpha: 0.35)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
            );
            canvas.drawCircle(
              claspMid,
              2.8,
              Paint()..color = AppColors.textPrimary,
            );

            if (config.showSlingMomentumVectors) {
              final Vector3 arrowTip = reliefPos +
                  (reliefSample.tangent * (1.8 + pair.slingProgress01 * 2.4)) +
                  (reliefSample.surfaceNormal * 0.65);
              final _ProjectedPoint3D? pTip =
                  _project(arrowTip, viewProj, size);
              if (pTip != null) {
                canvas.drawLine(
                  pRelief.screen,
                  pTip.screen,
                  Paint()
                    ..color = AppColors.emeraldGreen
                    ..strokeWidth = 2.4
                    ..strokeCap = StrokeCap.round,
                );
              }
            }
          }
        }

        // Etykieta drużyny nad kolarzem aktywnym
        if (pair.isHeroTeam || pair.isSlingInProgress) {
          final String badge = pair.isSlingInProgress
              ? '${pair.teamCode} • SLING!'
              : '${pair.teamCode} (${pair.sprintPoints}p)';
          _drawBoardText(
            canvas,
            badge,
            Offset(pActive.screen.dx - 24, pActive.screen.dy - 36),
            fontSize: 9.5,
            color: pair.isSlingInProgress
                ? AppColors.goldAccent
                : AppColors.textPrimary,
            weight: FontWeight.w700,
          );
        }
      },
    );
  }

  _DepthSortedRenderItem? _buildSingleTrackRiderItem({
    required Size size,
    required Matrix4 viewProj,
    required double timeSeconds,
    required VelodromeTrackRider3D rider,
    required bool isHero,
  }) {
    final VelodromeTrackSample3D sample =
        geometryBuilder.sampleAt(rider.distanceMeters);
    final Vector3 pos = sample.pointAt(rider.metersAboveBlackLine);
    final _ProjectedPoint3D? pPos = _project(pos, viewProj, size);
    if (pPos == null || pPos.depth > 155.0) return null;

    return _DepthSortedRenderItem(
      depth: pPos.depth,
      draw: (canvas) {
        _draw3dTrackCyclist(
          canvas: canvas,
          size: size,
          viewProj: viewProj,
          sample: sample,
          lateralMeters: rider.metersAboveBlackLine,
          jerseyColor: rider.jerseyColor,
          helmetColor: rider.helmetColor,
          isHero: isHero,
        );
        if (isHero) {
          _drawBoardText(
            canvas,
            '${rider.shortName} • ${rider.speedKmh.toStringAsFixed(1)} km/h',
            Offset(pPos.screen.dx - 30, pPos.screen.dy - 36),
            fontSize: 9.5,
            color: AppColors.goldAccent,
            weight: FontWeight.w700,
          );
        }
      },
    );
  }

  void _draw3dTrackCyclist({
    required Canvas canvas,
    required Size size,
    required Matrix4 viewProj,
    required VelodromeTrackSample3D sample,
    required double lateralMeters,
    required Color jerseyColor,
    required Color helmetColor,
    required bool isHero,
  }) {
    final Vector3 base = sample.pointAt(lateralMeters);
    final Vector3 frontHub =
        base + (sample.tangent * 0.52) + (sample.surfaceNormal * 0.34);
    final Vector3 rearHub =
        base - (sample.tangent * 0.52) + (sample.surfaceNormal * 0.34);
    final Vector3 saddle =
        base - (sample.tangent * 0.12) + (sample.surfaceNormal * 0.98);
    final Vector3 torsoTop =
        base + (sample.tangent * 0.28) + (sample.surfaceNormal * 1.32);
    final Vector3 head =
        base + (sample.tangent * 0.42) + (sample.surfaceNormal * 1.44);

    final _ProjectedPoint3D? pBase = _project(base, viewProj, size);
    final _ProjectedPoint3D? pFront = _project(frontHub, viewProj, size);
    final _ProjectedPoint3D? pRear = _project(rearHub, viewProj, size);
    final _ProjectedPoint3D? pSaddle = _project(saddle, viewProj, size);
    final _ProjectedPoint3D? pTorso = _project(torsoTop, viewProj, size);
    final _ProjectedPoint3D? pHead = _project(head, viewProj, size);

    if (pBase == null ||
        pFront == null ||
        pRear == null ||
        pSaddle == null ||
        pTorso == null ||
        pHead == null) {
      return;
    }

    final double r = (120.0 / math.max(3.5, pBase.depth)).clamp(2.5, 16.0);

    // Cień na parkiecie
    canvas.drawOval(
      Rect.fromCenter(center: pBase.screen, width: r * 3.0, height: r * 1.0),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    // Dyski/koła torowe
    final Paint wheelPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pFront.screen, r, wheelPaint);
    canvas.drawCircle(pRear.screen, r, wheelPaint);

    // Rama ostrokołowa
    canvas.drawLine(
      pRear.screen,
      pFront.screen,
      Paint()
        ..color = isHero ? AppColors.goldAccent : AppColors.textSecondary
        ..strokeWidth = (r * 0.25).clamp(1.2, 3.5),
    );

    // Tułów kolarza
    canvas.drawLine(
      pSaddle.screen,
      pTorso.screen,
      Paint()
        ..color = jerseyColor
        ..strokeWidth = (r * 0.58).clamp(2.0, 8.0)
        ..strokeCap = StrokeCap.round,
    );

    // Kask torowy
    canvas.drawCircle(
      pHead.screen,
      (r * 0.36).clamp(1.8, 5.5),
      Paint()..color = helmetColor,
    );
  }

  // ===========================================================================
  // 8. MATEMATYKA RZUTOWANIA 3D -> 2D
  // ===========================================================================

  _ProjectedPoint3D? _project(Vector3 world, Matrix4 viewProj, Size size) {
    final Vector4 clip =
        viewProj.transform(Vector4(world.x, world.y, world.z, 1.0));
    if (clip.w <= 0.15) return null;
    final double invW = 1.0 / clip.w;
    final double ndcX = clip.x * invW;
    final double ndcY = clip.y * invW;
    if (ndcX.abs() > 2.2 || ndcY.abs() > 2.2) return null;
    final double sx = (ndcX * 0.5 + 0.5) * size.width;
    final double sy = (0.5 - ndcY * 0.5) * size.height;
    return _ProjectedPoint3D(Offset(sx, sy), clip.w);
  }

  Matrix4 _buildLookAtMatrix({
    required Vector3 eye,
    required Vector3 target,
    required Vector3 up,
  }) {
    final Vector3 z = (eye - target)..normalize();
    final Vector3 x = up.cross(z)..normalize();
    final Vector3 y = z.cross(x);
    return Matrix4(
      x.x, y.x, z.x, 0.0,
      x.y, y.y, z.y, 0.0,
      x.z, y.z, z.z, 0.0,
      -x.dot(eye), -y.dot(eye), -z.dot(eye), 1.0,
    );
  }

  Matrix4 _buildPerspectiveMatrix({
    required double fovYRadians,
    required double aspect,
    required double nearPlane,
    required double farPlane,
  }) {
    final double f = 1.0 / math.tan(fovYRadians * 0.5);
    final double nf = 1.0 / (nearPlane - farPlane);
    return Matrix4(
      f / aspect, 0.0, 0.0, 0.0,
      0.0, f, 0.0, 0.0,
      0.0, 0.0, (farPlane + nearPlane) * nf, -1.0,
      0.0, 0.0, (2.0 * farPlane * nearPlane) * nf, 0.0,
    );
  }
}

class _CameraRig {
  final Vector3 position;
  final Vector3 target;
  const _CameraRig({required this.position, required this.target});
}

// =============================================================================
// 9. CUSTOM PAINTER I RESPONSYWNY WIDGET VIEWPORTU MADISON & KEIRIN 3D
// =============================================================================

/// Painter 3D sceny Madison i Keirin na welodromie.
class VelodromeMadisonHandSling3dPainter extends CustomPainter {
  final VelodromeMadisonHandSling3dRenderer renderer;
  final double timeSeconds;
  final List<MadisonHandSlingPair3D> madisonPairs;
  final KeirinDernyMotorbike3D derny;
  final List<VelodromeTrackRider3D> keirinRiders;
  final int currentLap;
  final double cameraYawOffsetRadians;
  final ValueChanged<VelodromeMadisonHandSlingTelemetry>? onTelemetryUpdated;

  const VelodromeMadisonHandSling3dPainter({
    required this.renderer,
    required this.timeSeconds,
    required this.madisonPairs,
    required this.derny,
    required this.keirinRiders,
    required this.currentLap,
    this.cameraYawOffsetRadians = 0.0,
    this.onTelemetryUpdated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final VelodromeMadisonHandSlingTelemetry telemetry = renderer.renderScene(
      canvas: canvas,
      size: size,
      timeSeconds: timeSeconds,
      madisonPairs: madisonPairs,
      derny: derny,
      keirinRiders: keirinRiders,
      currentLap: currentLap,
      cameraYawOffsetRadians: cameraYawOffsetRadians,
    );
    onTelemetryUpdated?.call(telemetry);
  }

  @override
  bool shouldRepaint(covariant VelodromeMadisonHandSling3dPainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.currentLap != currentLap ||
        oldDelegate.cameraYawOffsetRadians != cameraYawOffsetRadians ||
        oldDelegate.renderer.config.discipline !=
            renderer.config.discipline ||
        oldDelegate.renderer.config.cameraMode !=
            renderer.config.cameraMode ||
        oldDelegate.renderer.config.showDernyMotorbike !=
            renderer.config.showDernyMotorbike ||
        oldDelegate.renderer.config.showSlingMomentumVectors !=
            renderer.config.showSlingMomentumVectors ||
        oldDelegate.renderer.config.showInfieldSprintBoard !=
            renderer.config.showInfieldSprintBoard;
  }
}

/// Interaktywny i responsywny viewport 3D wyścigu Madison i Keirin na welodromie.
class VelodromeMadisonHandSlingViewportWidget extends StatefulWidget {
  final VelodromeMadisonKeirinConfig initialConfig;

  const VelodromeMadisonHandSlingViewportWidget({
    super.key,
    this.initialConfig = const VelodromeMadisonKeirinConfig(),
  });

  @override
  State<VelodromeMadisonHandSlingViewportWidget> createState() =>
      _VelodromeMadisonHandSlingViewportWidgetState();
}

class _VelodromeMadisonHandSlingViewportWidgetState
    extends State<VelodromeMadisonHandSlingViewportWidget>
    with SingleTickerProviderStateMixin {
  late VelodromeMadisonKeirinConfig _config;
  late AnimationController _ticker;
  double _elapsedSeconds = 0.0;
  double _cameraYawOffset = 0.0;
  bool _isPaused = false;
  bool _manualSlingRequested = false;
  bool _manualDernyPullOff = false;
  VelodromeMadisonHandSlingTelemetry? _telemetry;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(_onTick);
    _ticker.repeat();
  }

  void _onTick() {
    if (_isPaused) return;
    setState(() {
      _elapsedSeconds += 1.0 / 60.0;
    });
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _triggerHandSling() {
    setState(() {
      _manualSlingRequested = true;
    });
  }

  void _triggerDernyPullOff() {
    setState(() {
      _manualDernyPullOff = !_manualDernyPullOff;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool isMobile = w < 620;
        final bool isDesktop = w >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildViewportCanvas(),
                    ),
                    Container(
                      width: 340,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          left: BorderSide(
                            color: AppColors.cardBorder,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: _buildControls(isCompact: false),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      flex: isMobile ? 5 : 6,
                      child: _buildViewportCanvas(),
                    ),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        maxHeight: isMobile ? 260 : 230,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.cardBorder,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: _buildControls(isCompact: isMobile),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildViewportCanvas() {
    final VelodromeMadisonHandSling3dRenderer renderer =
        VelodromeMadisonHandSling3dRenderer(config: _config);

    final double trackLen = _config.facility.trackLengthMeters;
    final double t = _elapsedSeconds;
    final double baseDist = t * 15.2; // ~54.7 km/h
    final int currentLap =
        ((baseDist / trackLen).floor() % _config.totalLaps) + 1;

    // Cykl zmiany Madison co ~6 sekund lub na ręczne wywołanie
    final double slingCycle = (t % 6.0) / 1.4;
    final bool slingActive = _manualSlingRequested || slingCycle <= 1.0;
    final double slingProgress =
        _manualSlingRequested ? ((t % 1.4) / 1.4) : slingCycle.clamp(0.0, 1.0);

    final List<MadisonHandSlingPair3D> pairs = <MadisonHandSlingPair3D>[
      MadisonHandSlingPair3D(
        teamId: 'team_bel',
        teamCode: 'BEL',
        jerseyColor: AppColors.accentBlue,
        secondaryColor: AppColors.goldAccent,
        activeRiderName: 'L. De Vylder',
        reliefRiderName: 'R. Ghys',
        activeDistanceMeters: baseDist,
        activeMetersAboveBlackLine: slingActive ? 0.95 : 0.35,
        activeSpeedKmh: 55.4,
        reliefDistanceMeters: baseDist - (slingActive ? 0.35 : 8.5),
        reliefMetersAboveBlackLine:
            slingActive ? (2.2 - slingProgress * 0.95) : 3.2,
        reliefSpeedKmh: slingActive ? 44.0 + slingProgress * 12.0 : 34.0,
        isSlingInProgress: slingActive,
        slingProgress01: slingProgress,
        lastSlingQuality: MadisonSlingQuality.textbookSlingshot,
        sprintPoints: 25 + ((currentLap ~/ 10) * 5),
        lapsGained: 1,
        isHeroTeam: true,
      ),
      MadisonHandSlingPair3D(
        teamId: 'team_ned',
        teamCode: 'NED',
        jerseyColor: AppColors.amberWarning,
        secondaryColor: AppColors.textPrimary,
        activeRiderName: 'Y. Havik',
        reliefRiderName: 'J. van Schip',
        activeDistanceMeters: baseDist - 6.5,
        activeMetersAboveBlackLine: 0.45,
        activeSpeedKmh: 54.8,
        reliefDistanceMeters: baseDist - 14.0,
        reliefMetersAboveBlackLine: 3.1,
        reliefSpeedKmh: 35.0,
        sprintPoints: 19 + ((currentLap ~/ 10) * 3),
        lapsGained: 1,
      ),
      MadisonHandSlingPair3D(
        teamId: 'team_den',
        teamCode: 'DEN',
        jerseyColor: AppColors.crimsonAlert,
        secondaryColor: AppColors.textPrimary,
        activeRiderName: 'M. Mørkøv',
        reliefRiderName: 'N. Larsen',
        activeDistanceMeters: baseDist - 13.0,
        activeMetersAboveBlackLine: 0.65,
        activeSpeedKmh: 54.2,
        reliefDistanceMeters: baseDist - 13.4,
        reliefMetersAboveBlackLine: 1.5,
        reliefSpeedKmh: 48.0,
        isSlingInProgress: !slingActive && (t % 9.0) < 1.5,
        slingProgress01: ((t % 9.0) / 1.5).clamp(0.0, 1.0),
        lastSlingQuality: MadisonSlingQuality.cleanExchange,
        sprintPoints: 14 + ((currentLap ~/ 10) * 2),
        lapsGained: 0,
      ),
      MadisonHandSlingPair3D(
        teamId: 'team_gbr',
        teamCode: 'GBR',
        jerseyColor: AppColors.primaryAccent,
        secondaryColor: AppColors.cyanAccent,
        activeRiderName: 'O. Wood',
        reliefRiderName: 'M. Walls',
        activeDistanceMeters: baseDist - 21.0,
        activeMetersAboveBlackLine: 0.40,
        activeSpeedKmh: 53.9,
        reliefDistanceMeters: baseDist - 29.0,
        reliefMetersAboveBlackLine: 3.4,
        reliefSpeedKmh: 33.5,
        sprintPoints: 11,
        lapsGained: 0,
      ),
    ];

    final bool pullOff = _manualDernyPullOff || (currentLap >= 4);
    final KeirinDernyMotorbike3D derny = KeirinDernyMotorbike3D(
      distanceMeters: baseDist + 4.2,
      metersAboveBlackLine: 0.30,
      speedKmh: pullOff ? 50.0 : (32.0 + ((t * 2.5) % 18.0)),
      phase: pullOff
          ? KeirinRacePhase.dernyPullOff
          : KeirinRacePhase.dernyRampUp,
      isPullingOff: pullOff,
      pullOffProgress01: pullOff ? ((t * 0.4) % 1.0) : 0.0,
    );

    final List<VelodromeTrackRider3D> keirinRiders = <VelodromeTrackRider3D>[
      for (int i = 0; i < 6; i++)
        VelodromeTrackRider3D(
          riderId: 'keirin_$i',
          shortName: ['LAV', 'RIC', 'HOO', 'RUD', 'CAR', 'GLA'][i],
          jerseyColor: [
            AppColors.amberWarning,
            AppColors.accentBlue,
            AppColors.emeraldGreen,
            AppColors.crimsonAlert,
            AppColors.goldAccent,
            AppColors.primaryAccent,
          ][i],
          helmetColor: AppColors.textPrimary,
          bikeFrameColor: AppColors.surfaceLight,
          distanceMeters: baseDist - (i * 2.4),
          metersAboveBlackLine: 0.25 + (i.isOdd ? 0.55 : 0.0),
          speedKmh: pullOff ? 66.5 - i * 0.4 : derny.speedKmh,
          cadenceRpm: 124.0,
          powerWatts: pullOff ? 1420.0 - i * 40.0 : 410.0,
        ),
    ];

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _cameraYawOffset += details.delta.dx * 0.008;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: VelodromeMadisonHandSling3dPainter(
              renderer: renderer,
              timeSeconds: _elapsedSeconds,
              madisonPairs: pairs,
              derny: derny,
              keirinRiders: keirinRiders,
              currentLap: currentLap,
              cameraYawOffsetRadians: _cameraYawOffset,
              onTelemetryUpdated: (tel) {
                _telemetry = tel;
              },
            ),
          ),
          if (_config.showTelemetryOverlay && _telemetry != null)
            Positioned(
              top: 12,
              left: 12,
              child: _MadisonKeirinHudBadge(telemetry: _telemetry!),
            ),
        ],
      ),
    );
  }

  Widget _buildControls({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.sports_motorsports_rounded,
              color: AppColors.goldAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welodrom 3D • Madison & Keirin',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _MadisonActionButton(
              label: _isPaused ? 'Wznów' : 'Pauza',
              icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              isActive: !_isPaused,
              onPressed: _togglePlayPause,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Dyscyplina Torowa',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: VelodromeTrackDisciplineMode.values.map((mode) {
            return _MadisonActionButton(
              label: mode.labelPl,
              isActive: _config.discipline == mode,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(
                    discipline: mode,
                    totalLaps:
                        mode == VelodromeTrackDisciplineMode.keirin ? 6 : 50,
                  );
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kamera 3D',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: MadisonKeirinCameraMode.values.map((cam) {
            return _MadisonActionButton(
              label: cam.shortTag,
              isActive: _config.cameraMode == cam,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(cameraMode: cam);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MadisonActionButton(
              label: 'Rzut Hand Sling',
              icon: Icons.handshake_rounded,
              isActive: _manualSlingRequested,
              onPressed:
                  _config.discipline == VelodromeTrackDisciplineMode.madison
                      ? _triggerHandSling
                      : null,
            ),
            _MadisonActionButton(
              label: 'Zjazd Derny',
              icon: Icons.two_wheeler_rounded,
              isActive: _manualDernyPullOff,
              onPressed:
                  _config.discipline == VelodromeTrackDisciplineMode.keirin
                      ? _triggerDernyPullOff
                      : null,
            ),
            _MadisonActionButton(
              label: 'Tablica 10-okr.',
              isActive: _config.showInfieldSprintBoard,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(
                    showInfieldSprintBoard: !_config.showInfieldSprintBoard,
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _MadisonKeirinHudBadge extends StatelessWidget {
  final VelodromeMadisonHandSlingTelemetry telemetry;

  const _MadisonKeirinHudBadge({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final bool isMadison =
        telemetry.discipline == VelodromeTrackDisciplineMode.madison;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: telemetry.isSprintBellLap
              ? AppColors.goldAccent
              : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${telemetry.discipline.shortTag} • OKR. ${telemetry.currentLap}/${telemetry.totalLaps}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isMadison
                ? 'Sprint za ${telemetry.lapsToNextSprint} okr. • Aktywne zmiany: ${telemetry.activeSlingCount}'
                : 'Derny: ${telemetry.dernySpeedKmh.toStringAsFixed(1)} km/h • ${telemetry.dernyPhase.labelPl}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MadisonActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _MadisonActionButton({
    required this.label,
    this.icon,
    this.isActive = false,
    this.onPressed,
  });

  @override
  State<_MadisonActionButton> createState() => _MadisonActionButtonState();
}

class _MadisonActionButtonState extends State<_MadisonActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.isActive
            ? AppColors.primaryAccent
            : _isPressed
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.cardSurface
                    : AppColors.surface;
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isActive
            ? AppColors.goldAccent
            : AppColors.cardBorder;
    final Color textColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isActive
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
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
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: textColor),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
