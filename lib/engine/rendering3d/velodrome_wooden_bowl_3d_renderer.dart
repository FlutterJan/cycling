// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/velodrome_track_and_hour_record_model.dart';
import '../physics/velodrome_banking_and_centripetal_solver.dart';

// =============================================================================
// 1. TRYBY KAMERY I KONFIGURACJA RENDERERA 3D WELODROMU
// =============================================================================

/// Tryby kamery 3D w krytym drewnianym welodromie.
enum VelodromeCameraMode {
  chaseMoto('Pościg Moto', 'MOTO'),
  broadcastBowl('Trybuny TV', 'TV BOWL'),
  turnApexLow('Wiraż 42°', 'APEX 42°'),
  infieldScoreboard('Środek Toru', 'INFIELD');

  final String labelPl;
  final String shortTag;

  const VelodromeCameraMode(this.labelPl, this.shortTag);
}

/// Konfiguracja wizualna i geometryczna renderera 3D welodromu.
class VelodromeWoodenBowlConfig {
  final VelodromeFacilitySpec facility;
  final VelodromeCameraMode cameraMode;
  final double fieldOfViewDegrees;
  final double trackWidthMeters;
  final double apronWidthMeters;
  final double woodVarnishGlossiness;
  final double spotlightIntensity;
  final double virtualRecordSpeedKmh;
  final bool showRoofAndSpotlights;
  final bool showParquetSpecularReflections;
  final bool showInfieldScoreboard;
  final bool showVirtualRecordLaser;
  final bool showTelemetryOverlay;

  const VelodromeWoodenBowlConfig({
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
    this.cameraMode = VelodromeCameraMode.chaseMoto,
    this.fieldOfViewDegrees = 58.0,
    this.trackWidthMeters = 7.5,
    this.apronWidthMeters = 0.75,
    this.woodVarnishGlossiness = 0.88,
    this.spotlightIntensity = 1.0,
    this.virtualRecordSpeedKmh = 56.792,
    this.showRoofAndSpotlights = true,
    this.showParquetSpecularReflections = true,
    this.showInfieldScoreboard = true,
    this.showVirtualRecordLaser = true,
    this.showTelemetryOverlay = true,
  });

  VelodromeWoodenBowlConfig copyWith({
    VelodromeFacilitySpec? facility,
    VelodromeCameraMode? cameraMode,
    double? fieldOfViewDegrees,
    double? trackWidthMeters,
    double? apronWidthMeters,
    double? woodVarnishGlossiness,
    double? spotlightIntensity,
    double? virtualRecordSpeedKmh,
    bool? showRoofAndSpotlights,
    bool? showParquetSpecularReflections,
    bool? showInfieldScoreboard,
    bool? showVirtualRecordLaser,
    bool? showTelemetryOverlay,
  }) {
    return VelodromeWoodenBowlConfig(
      facility: facility ?? this.facility,
      cameraMode: cameraMode ?? this.cameraMode,
      fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
      trackWidthMeters: trackWidthMeters ?? this.trackWidthMeters,
      apronWidthMeters: apronWidthMeters ?? this.apronWidthMeters,
      woodVarnishGlossiness:
          woodVarnishGlossiness ?? this.woodVarnishGlossiness,
      spotlightIntensity: spotlightIntensity ?? this.spotlightIntensity,
      virtualRecordSpeedKmh:
          virtualRecordSpeedKmh ?? this.virtualRecordSpeedKmh,
      showRoofAndSpotlights:
          showRoofAndSpotlights ?? this.showRoofAndSpotlights,
      showParquetSpecularReflections:
          showParquetSpecularReflections ?? this.showParquetSpecularReflections,
      showInfieldScoreboard:
          showInfieldScoreboard ?? this.showInfieldScoreboard,
      showVirtualRecordLaser:
          showVirtualRecordLaser ?? this.showVirtualRecordLaser,
      showTelemetryOverlay: showTelemetryOverlay ?? this.showTelemetryOverlay,
    );
  }
}

// =============================================================================
// 2. MODELE GEOMETRII 3D TORU, REFLEKTORÓW, KOLARZA I TELEMETRII
// =============================================================================

/// Próbka geometrii 3D zamkniętego toru welodromu 250 m.
class VelodromeTrackSample3D {
  final double distanceMeters;
  final Vector3 innerEdge;
  final Vector3 tangent;
  final Vector3 outwardRadial;
  final Vector3 surfaceCrossVector;
  final Vector3 surfaceNormal;
  final double bankingRadians;
  final VelodromeTrackSection section;

  const VelodromeTrackSample3D({
    required this.distanceMeters,
    required this.innerEdge,
    required this.tangent,
    required this.outwardRadial,
    required this.surfaceCrossVector,
    required this.surfaceNormal,
    required this.bankingRadians,
    required this.section,
  });

  double get bankingDegrees => bankingRadians * (180.0 / math.pi);

  /// Zwraca punkt 3D na powierzchni toru przesunięty w górę bandy o [lateralMeters]
  /// oraz prostopadle nad parkiet o [verticalOffsetMeters].
  Vector3 pointAt(double lateralMeters, {double verticalOffsetMeters = 0.0}) {
    return innerEdge +
        (surfaceCrossVector * lateralMeters) +
        (surfaceNormal * verticalOffsetMeters);
  }
}

/// Reflektor punktowy zamontowany pod konstrukcją dachu hali welodromu.
class VelodromeRoofSpotlight3D {
  final Vector3 position;
  final Vector3 target;
  final Color lightColor;
  final double intensity;

  const VelodromeRoofSpotlight3D({
    required this.position,
    required this.target,
    required this.lightColor,
    this.intensity = 1.0,
  });
}

/// Aktor kolarza torowego na welodromie 3D.
class VelodromeTrackRider3D {
  final String riderId;
  final String shortName;
  final Color jerseyColor;
  final Color helmetColor;
  final Color bikeFrameColor;
  final double distanceMeters;
  final double metersAboveBlackLine;
  final double speedKmh;
  final double cadenceRpm;
  final double powerWatts;

  const VelodromeTrackRider3D({
    required this.riderId,
    required this.shortName,
    required this.jerseyColor,
    required this.helmetColor,
    required this.bikeFrameColor,
    required this.distanceMeters,
    this.metersAboveBlackLine = 0.0,
    this.speedKmh = 56.8,
    this.cadenceRpm = 104.0,
    this.powerWatts = 445.0,
  });
}

/// Telemetria pojedynczej wyrenderowanej klatki welodromu 3D.
class VelodromeWoodenBowlTelemetry {
  final int currentLap;
  final int totalTargetLaps;
  final double riderDistanceMeters;
  final double riderSpeedKmh;
  final double virtualRecordSpeedKmh;
  final double deltaToRecordMeters;
  final double localBankingDegrees;
  final double gForceLoadFactor;
  final VelodromeTrackSection currentSection;
  final double projectedHourDistanceKm;
  final int renderedTrackQuads;
  final int renderedSpotlights;

  const VelodromeWoodenBowlTelemetry({
    required this.currentLap,
    required this.totalTargetLaps,
    required this.riderDistanceMeters,
    required this.riderSpeedKmh,
    required this.virtualRecordSpeedKmh,
    required this.deltaToRecordMeters,
    required this.localBankingDegrees,
    required this.gForceLoadFactor,
    required this.currentSection,
    required this.projectedHourDistanceKm,
    required this.renderedTrackQuads,
    required this.renderedSpotlights,
  });
}

// =============================================================================
// 3. BUILDER GEOMETRII OWALU 250 M I WIRAŻY 42°–45°
// =============================================================================

/// Generator dokładnej geometrii 3D krytego welodromu 250 m z przejściami klotoidalnymi.
class VelodromeTrackGeometryBuilder {
  final VelodromeFacilitySpec facility;
  late final double turnRadiusMeters;
  late final double trackLengthMeters;
  late final double straightLengthMeters;
  late final double halfStraightMeters;
  late final double turnArcLengthMeters;
  late final double straightBankRad;
  late final double turnBankRad;

  VelodromeTrackGeometryBuilder(this.facility) {
    trackLengthMeters = math.max(150.0, facility.trackLengthMeters);
    turnRadiusMeters = math.max(15.0, facility.turnRadiusMeters);
    final double twoTurns = 2.0 * math.pi * turnRadiusMeters;
    straightLengthMeters = math.max(20.0, (trackLengthMeters - twoTurns) * 0.5);
    halfStraightMeters = straightLengthMeters * 0.5;
    turnArcLengthMeters = math.pi * turnRadiusMeters;
    straightBankRad = facility.straightBankingDegrees * (math.pi / 180.0);
    turnBankRad = facility.turnBankingDegrees * (math.pi / 180.0);
  }

  /// Próbkuje geometrię owalu w dowolnym punkcie [distanceMeters] wzdłuż czarnej linii.
  VelodromeTrackSample3D sampleAt(double distanceMeters) {
    final double total = (2.0 * straightLengthMeters) + (2.0 * turnArcLengthMeters);
    double s = distanceMeters % total;
    if (s < 0) s += total;

    late Vector3 innerEdge;
    late Vector3 tangent;
    late Vector3 outwardRadial;
    late double bankRad;
    late VelodromeTrackSection section;

    final double sEndStraight1 = straightLengthMeters;
    final double sEndTurn1 = sEndStraight1 + turnArcLengthMeters;
    final double sEndStraight2 = sEndTurn1 + straightLengthMeters;

    const double transitionSpan = 14.0;

    if (s < sEndStraight1) {
      // Prosta 1 (X = +R, Z od -halfStraight do +halfStraight)
      final double localZ = -halfStraightMeters + s;
      innerEdge = Vector3(turnRadiusMeters, 0.0, localZ);
      tangent = Vector3(0.0, 0.0, 1.0);
      outwardRadial = Vector3(1.0, 0.0, 0.0);

      final double distToEnd = sEndStraight1 - s;
      final double distFromStart = s;
      if (distToEnd < transitionSpan) {
        final double t = 1.0 - (distToEnd / transitionSpan);
        bankRad = _smoothBank(straightBankRad, turnBankRad, t * 0.5);
        section = VelodromeTrackSection.transitionEntry;
      } else if (distFromStart < transitionSpan) {
        final double t = distFromStart / transitionSpan;
        bankRad = _smoothBank(turnBankRad, straightBankRad, 0.5 + t * 0.5);
        section = VelodromeTrackSection.transitionExit;
      } else {
        bankRad = straightBankRad;
        section = VelodromeTrackSection.straight;
      }
    } else if (s < sEndTurn1) {
      // Wiraż 1 (centrum (0, 0, +halfStraight), kąt 0 -> pi)
      final double arc = s - sEndStraight1;
      final double theta = arc / turnRadiusMeters;
      final double cosT = math.cos(theta);
      final double sinT = math.sin(theta);

      innerEdge = Vector3(
        turnRadiusMeters * cosT,
        0.0,
        halfStraightMeters + turnRadiusMeters * sinT,
      );
      tangent = Vector3(-sinT, 0.0, cosT)..normalize();
      outwardRadial = Vector3(cosT, 0.0, sinT)..normalize();

      if (arc < transitionSpan) {
        final double t = arc / transitionSpan;
        bankRad = _smoothBank(straightBankRad, turnBankRad, 0.5 + t * 0.5);
        section = VelodromeTrackSection.transitionEntry;
      } else if (turnArcLengthMeters - arc < transitionSpan) {
        final double t = 1.0 - ((turnArcLengthMeters - arc) / transitionSpan);
        bankRad = _smoothBank(turnBankRad, straightBankRad, t * 0.5);
        section = VelodromeTrackSection.transitionExit;
      } else {
        bankRad = turnBankRad;
        section = VelodromeTrackSection.turnApex;
      }
    } else if (s < sEndStraight2) {
      // Prosta 2 (X = -R, Z od +halfStraight do -halfStraight)
      final double localS = s - sEndTurn1;
      final double localZ = halfStraightMeters - localS;
      innerEdge = Vector3(-turnRadiusMeters, 0.0, localZ);
      tangent = Vector3(0.0, 0.0, -1.0);
      outwardRadial = Vector3(-1.0, 0.0, 0.0);

      final double distToEnd = sEndStraight2 - s;
      if (distToEnd < transitionSpan) {
        final double t = 1.0 - (distToEnd / transitionSpan);
        bankRad = _smoothBank(straightBankRad, turnBankRad, t * 0.5);
        section = VelodromeTrackSection.transitionEntry;
      } else if (localS < transitionSpan) {
        final double t = localS / transitionSpan;
        bankRad = _smoothBank(turnBankRad, straightBankRad, 0.5 + t * 0.5);
        section = VelodromeTrackSection.transitionExit;
      } else {
        bankRad = straightBankRad;
        section = VelodromeTrackSection.straight;
      }
    } else {
      // Wiraż 2 (centrum (0, 0, -halfStraight), kąt pi -> 2*pi)
      final double arc = s - sEndStraight2;
      final double theta = math.pi + (arc / turnRadiusMeters);
      final double cosT = math.cos(theta);
      final double sinT = math.sin(theta);

      innerEdge = Vector3(
        turnRadiusMeters * cosT,
        0.0,
        -halfStraightMeters + turnRadiusMeters * sinT,
      );
      tangent = Vector3(-sinT, 0.0, cosT)..normalize();
      outwardRadial = Vector3(cosT, 0.0, sinT)..normalize();

      if (arc < transitionSpan) {
        final double t = arc / transitionSpan;
        bankRad = _smoothBank(straightBankRad, turnBankRad, 0.5 + t * 0.5);
        section = VelodromeTrackSection.transitionEntry;
      } else if (turnArcLengthMeters - arc < transitionSpan) {
        final double t = 1.0 - ((turnArcLengthMeters - arc) / transitionSpan);
        bankRad = _smoothBank(turnBankRad, straightBankRad, t * 0.5);
        section = VelodromeTrackSection.transitionExit;
      } else {
        bankRad = turnBankRad;
        section = VelodromeTrackSection.turnApex;
      }
    }

    final double cosB = math.cos(bankRad);
    final double sinB = math.sin(bankRad);
    final Vector3 surfaceCross = Vector3(
      outwardRadial.x * cosB,
      sinB,
      outwardRadial.z * cosB,
    )..normalize();
    final Vector3 surfaceNormal = Vector3(
      -outwardRadial.x * sinB,
      cosB,
      -outwardRadial.z * sinB,
    )..normalize();

    return VelodromeTrackSample3D(
      distanceMeters: s,
      innerEdge: innerEdge,
      tangent: tangent,
      outwardRadial: outwardRadial,
      surfaceCrossVector: surfaceCross,
      surfaceNormal: surfaceNormal,
      bankingRadians: bankRad,
      section: section,
    );
  }

  double _smoothBank(double a, double b, double t) {
    final double clamped = t.clamp(0.0, 1.0);
    final double smooth = 0.5 - 0.5 * math.cos(clamped * math.pi);
    return a + (b - a) * smooth;
  }

  /// Generuje tablicę reflektorów punktowych pod dachem hali welodromu.
  List<VelodromeRoofSpotlight3D> buildRoofSpotlights() {
    final List<VelodromeRoofSpotlight3D> lights = [];
    const int count = 12;
    const double roofY = 18.5;
    for (int i = 0; i < count; i++) {
      final double s = (i / count) * trackLengthMeters;
      final sample = sampleAt(s);
      final Vector3 pos = sample.innerEdge +
          (sample.outwardRadial * 2.2) +
          Vector3(0.0, roofY, 0.0);
      final Vector3 target = sample.pointAt(3.2);
      final Color tint = i.isEven
          ? const Color(0xFFFFF8E6)
          : const Color(0xFFE0F2FE);
      lights.add(
        VelodromeRoofSpotlight3D(
          position: pos,
          target: target,
          lightColor: tint,
          intensity: 1.0,
        ),
      );
    }
    return lights;
  }
}

// =============================================================================
// 4. WEWNĘTRZNE ELEMENTY SORTOWANE GŁĘBOKOŚCIĄ (PAINTER'S ALGORITHM)
// =============================================================================

class _ProjectedCamPoint {
  final Offset screen;
  final double depth;
  const _ProjectedCamPoint(this.screen, this.depth);
}

class _SortedRenderQuad {
  final double avgDepth;
  final List<Offset> points;
  final Color fillColor;
  final Color? strokeColor;
  final double strokeWidth;

  const _SortedRenderQuad({
    required this.avgDepth,
    required this.points,
    required this.fillColor,
    this.strokeColor,
    this.strokeWidth = 0.0,
  });
}

// =============================================================================
// 5. GŁÓWNY RENDERER 3D KRYTEGO WELODROMU
// =============================================================================

/// Zjawiskowy renderer 3D krytego welodromu `VelodromeWoodenBowl3dRenderer`:
/// - lakierowany parkiet z drewna syberyjskiego ze stromymi wirażami 42°–45°,
/// - czarna, czerwona i niebieska linia torowa + błękitny pas Côte d'Azur,
/// - dach hali z kratownicami i reflektorami punktowymi odbijającymi się w parkiecie,
/// - elektroniczna tablica wyników na środku toru,
/// - laserowa zielona linia wirtualnego rekordu przesuwająca się po parkiecie.
class VelodromeWoodenBowl3dRenderer {
  final VelodromeWoodenBowlConfig config;
  late final VelodromeTrackGeometryBuilder geometryBuilder;
  late final List<VelodromeRoofSpotlight3D> spotlights;

  VelodromeWoodenBowl3dRenderer({required this.config}) {
    geometryBuilder = VelodromeTrackGeometryBuilder(config.facility);
    spotlights = geometryBuilder.buildRoofSpotlights();
  }

  /// Renderuje całą scenę 3D welodromu na przekazanym [Canvas] i zwraca telemetrię klatki.
  VelodromeWoodenBowlTelemetry paintScene({
    required Canvas canvas,
    required Size size,
    required double timeSeconds,
    required VelodromeTrackRider3D heroRider,
    List<VelodromeTrackRider3D> pacersOrRivals = const [],
    double cameraYawOffsetRadians = 0.0,
  }) {
    if (size.width <= 1.0 || size.height <= 1.0) {
      return _emptyTelemetry(heroRider);
    }

    // 1. Tło hali krytego welodromu
    _paintArenaBackdrop(canvas, size);

    // 2. Ustawienie kamery 3D zależnie od trybu
    final heroSample = geometryBuilder.sampleAt(heroRider.distanceMeters);
    final _CameraRig cam = _computeCameraRig(
      heroRider: heroRider,
      heroSample: heroSample,
      cameraYawOffsetRadians: cameraYawOffsetRadians,
    );

    final double fovRad = config.fieldOfViewDegrees * (math.pi / 180.0);
    final double focalLength =
        (size.height * 0.5) / math.tan(fovRad * 0.5);

    _ProjectedCamPoint? project(Vector3 worldPos) {
      final Vector3 rel = worldPos - cam.position;
      final double cx = rel.dot(cam.right);
      final double cy = rel.dot(cam.up);
      final double cz = rel.dot(cam.forward);
      if (cz <= 0.6) return null;
      final double sx = (size.width * 0.5) + (cx / cz) * focalLength;
      final double sy = (size.height * 0.5) - (cy / cz) * focalLength;
      return _ProjectedCamPoint(Offset(sx, sy), cz);
    }

    // 3. Wnętrze owalu (infield)
    _paintInfieldFloor(canvas, project);

    // 4. Dach hali i reflektory punktowe
    int renderedSpotlights = 0;
    if (config.showRoofAndSpotlights) {
      renderedSpotlights = _paintRoofTrussesAndSpotlights(canvas, project);
    }

    // 5. Parkiet z drewna syberyjskiego + odbicia reflektorów + linie torowe
    final int renderedQuads = _paintWoodenBowlAndLines(
      canvas: canvas,
      project: project,
      camPos: cam.position,
    );

    // 6. Laserowa zielona linia wirtualnego rekordu
    final double recordSpeedMps = config.virtualRecordSpeedKmh / 3.6;
    final double virtualRecordDistance = timeSeconds * recordSpeedMps;
    final double deltaMeters =
        heroRider.distanceMeters - virtualRecordDistance;

    if (config.showVirtualRecordLaser) {
      _paintVirtualRecordLaser(
        canvas: canvas,
        project: project,
        virtualDistanceMeters: virtualRecordDistance,
        timeSeconds: timeSeconds,
        isRiderAhead: deltaMeters >= 0.0,
      );
    }

    // 7. Obliczenie fizyki wirażu (G-Force i kąt złożenia)
    final double heroSpeedMps = heroRider.speedKmh / 3.6;
    final physicsResult =
        VelodromeBankingAndCentripetalSolver.solveInstantaneousPhysics(
      VelodromePhysicsInput(
        facility: config.facility,
        bike: const FixedGearTrackBike(
          modelName: 'Aero Track Pro',
          chainringTeeth: 64,
          cogTeeth: 14,
          bikeWeightKg: 6.8,
          cdaMetersSquared: 0.165,
        ),
        riderMassKg: 74.0,
        speedMs: heroSpeedMps,
        section: heroSample.section,
        metersAboveBlackLine: heroRider.metersAboveBlackLine,
      ),
    );

    final int currentLap =
        (heroRider.distanceMeters / geometryBuilder.trackLengthMeters).floor() +
            1;
    final int totalLaps =
        ((config.virtualRecordSpeedKmh * 1000.0) /
                geometryBuilder.trackLengthMeters)
            .round();

    // 8. Elektroniczna tablica wyników na środku toru
    if (config.showInfieldScoreboard) {
      _paintInfieldScoreboard(
        canvas: canvas,
        project: project,
        camPos: cam.position,
        currentLap: currentLap,
        totalLaps: totalLaps,
        riderSpeedKmh: heroRider.speedKmh,
        deltaMeters: deltaMeters,
        riderName: heroRider.shortName,
      );
    }

    // 9. Renderowanie kolarzy 3D na parkiecie (sortowane od najdalszego)
    final List<VelodromeTrackRider3D> allRiders = [
      ...pacersOrRivals,
      heroRider,
    ];
    final List<({VelodromeTrackRider3D rider, double depth})> sortedRiders = [];
    for (final r in allRiders) {
      final s = geometryBuilder.sampleAt(r.distanceMeters);
      final p = project(s.pointAt(r.metersAboveBlackLine, verticalOffsetMeters: 0.6));
      if (p != null) {
        sortedRiders.add((rider: r, depth: p.depth));
      }
    }
    sortedRiders.sort((a, b) => b.depth.compareTo(a.depth));
    for (final item in sortedRiders) {
      _paintTrackCyclist3D(
        canvas: canvas,
        project: project,
        rider: item.rider,
        timeSeconds: timeSeconds,
        focalLength: focalLength,
      );
    }

    return VelodromeWoodenBowlTelemetry(
      currentLap: currentLap,
      totalTargetLaps: totalLaps,
      riderDistanceMeters: heroRider.distanceMeters,
      riderSpeedKmh: heroRider.speedKmh,
      virtualRecordSpeedKmh: config.virtualRecordSpeedKmh,
      deltaToRecordMeters: deltaMeters,
      localBankingDegrees: heroSample.bankingDegrees,
      gForceLoadFactor: physicsResult.gForceLoadFactor,
      currentSection: heroSample.section,
      projectedHourDistanceKm: heroRider.speedKmh,
      renderedTrackQuads: renderedQuads,
      renderedSpotlights: renderedSpotlights,
    );
  }

  VelodromeWoodenBowlTelemetry _emptyTelemetry(VelodromeTrackRider3D heroRider) {
    return VelodromeWoodenBowlTelemetry(
      currentLap: 1,
      totalTargetLaps: 227,
      riderDistanceMeters: heroRider.distanceMeters,
      riderSpeedKmh: heroRider.speedKmh,
      virtualRecordSpeedKmh: config.virtualRecordSpeedKmh,
      deltaToRecordMeters: 0.0,
      localBankingDegrees: config.facility.turnBankingDegrees,
      gForceLoadFactor: 1.0,
      currentSection: VelodromeTrackSection.straight,
      projectedHourDistanceKm: heroRider.speedKmh,
      renderedTrackQuads: 0,
      renderedSpotlights: 0,
    );
  }

  void _paintArenaBackdrop(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF090B0E),
          Color(0xFF0F1115),
          Color(0xFF161A22),
        ],
        stops: [0.0, 0.52, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);
  }

  _CameraRig _computeCameraRig({
    required VelodromeTrackRider3D heroRider,
    required VelodromeTrackSample3D heroSample,
    required double cameraYawOffsetRadians,
  }) {
    late Vector3 camPos;
    late Vector3 lookTarget;

    final Vector3 riderPos = heroSample.pointAt(
      heroRider.metersAboveBlackLine,
      verticalOffsetMeters: 0.85,
    );

    switch (config.cameraMode) {
      case VelodromeCameraMode.chaseMoto:
        final backSample =
            geometryBuilder.sampleAt(heroRider.distanceMeters - 10.5);
        camPos = backSample.pointAt(
              heroRider.metersAboveBlackLine + 1.4,
              verticalOffsetMeters: 2.6,
            ) +
            Vector3(
              math.sin(cameraYawOffsetRadians) * 2.2,
              0.0,
              0.0,
            );
        lookTarget = heroSample.pointAt(
          heroRider.metersAboveBlackLine + 1.5,
          verticalOffsetMeters: 0.6,
        );
      case VelodromeCameraMode.broadcastBowl:
        final double angle = cameraYawOffsetRadians + 0.55;
        camPos = Vector3(
          math.cos(angle) * 44.0,
          21.5,
          math.sin(angle) * 52.0,
        );
        lookTarget = Vector3(0.0, 1.8, 0.0);
      case VelodromeCameraMode.turnApexLow:
        final double apexDist =
            geometryBuilder.straightLengthMeters +
            geometryBuilder.turnArcLengthMeters * 0.5;
        final apexSample = geometryBuilder.sampleAt(apexDist);
        camPos = apexSample.pointAt(0.2, verticalOffsetMeters: 1.55) -
            (apexSample.tangent * 9.0);
        lookTarget = apexSample.pointAt(3.6, verticalOffsetMeters: 1.4);
      case VelodromeCameraMode.infieldScoreboard:
        camPos = Vector3(
          math.sin(cameraYawOffsetRadians) * 14.0,
          3.4,
          math.cos(cameraYawOffsetRadians) * 14.0,
        );
        lookTarget = riderPos * 0.65 + Vector3(0.0, 2.2, 0.0);
    }

    final Vector3 forward = (lookTarget - camPos)..normalize();
    final Vector3 worldUp = Vector3(0.0, 1.0, 0.0);
    Vector3 right = forward.cross(worldUp);
    if (right.length2 < 1e-6) {
      right = Vector3(1.0, 0.0, 0.0);
    } else {
      right.normalize();
    }
    final Vector3 up = right.cross(forward)..normalize();

    return _CameraRig(
      position: camPos,
      forward: forward,
      right: right,
      up: up,
    );
  }

  void _paintInfieldFloor(
    Canvas canvas,
    _ProjectedCamPoint? Function(Vector3) project,
  ) {
    const int segments = 48;
    final List<Offset> pts = [];
    final double total = geometryBuilder.trackLengthMeters;
    for (int i = 0; i < segments; i++) {
      final s = (i / segments) * total;
      final sample = geometryBuilder.sampleAt(s);
      final p = project(sample.pointAt(-config.apronWidthMeters));
      if (p != null) {
        pts.add(p.screen);
      }
    }
    if (pts.length >= 3) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFF141820),
      );
      // Wewnętrzne boisko rozgrzewkowe
      final List<Offset> innerPts = [];
      for (int i = 0; i < segments; i++) {
        final s = (i / segments) * total;
        final sample = geometryBuilder.sampleAt(s);
        final inner = sample.innerEdge * 0.72;
        final p = project(Vector3(inner.x, -0.02, inner.z));
        if (p != null) innerPts.add(p.screen);
      }
      if (innerPts.length >= 3) {
        canvas.drawPath(
          Path()..addPolygon(innerPts, true),
          Paint()..color = const Color(0xFF1B212C),
        );
      }
    }
  }

  int _paintRoofTrussesAndSpotlights(
    Canvas canvas,
    _ProjectedCamPoint? Function(Vector3) project,
  ) {
    final Paint trussPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 7 poprzecznych kratownic łukowych nad halą
    const int trussCount = 7;
    final double halfZ = geometryBuilder.halfStraightMeters + 22.0;
    for (int i = 0; i < trussCount; i++) {
      final double z = -halfZ + (i / (trussCount - 1)) * (halfZ * 2.0);
      Offset? prev;
      for (int k = 0; k <= 10; k++) {
        final double t = k / 10.0;
        final double x = -34.0 + t * 68.0;
        final double archY = 14.5 + math.sin(t * math.pi) * 7.5;
        final p = project(Vector3(x, archY, z));
        if (p != null) {
          if (prev != null) {
            canvas.drawLine(prev, p.screen, trussPaint);
          }
          prev = p.screen;
        } else {
          prev = null;
        }
      }
    }

    // Reflektory punktowe i stożki świetlne
    int drawn = 0;
    for (final light in spotlights) {
      final pPos = project(light.position);
      if (pPos == null) continue;
      drawn++;
      final double scale = (320.0 / pPos.depth).clamp(4.0, 24.0);
      final double alpha = (0.38 * config.spotlightIntensity).clamp(0.1, 0.7);

      // Stożek poświaty
      final pTarget = project(light.target);
      if (pTarget != null) {
        final Path cone = Path()
          ..moveTo(pPos.screen.dx - scale * 0.4, pPos.screen.dy)
          ..lineTo(pPos.screen.dx + scale * 0.4, pPos.screen.dy)
          ..lineTo(pTarget.screen.dx + scale * 3.5, pTarget.screen.dy)
          ..lineTo(pTarget.screen.dx - scale * 3.5, pTarget.screen.dy)
          ..close();
        canvas.drawPath(
          cone,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                light.lightColor.withValues(alpha: alpha * 0.25),
                light.lightColor.withValues(alpha: 0.0),
              ],
            ).createShader(cone.getBounds()),
        );
      }

      // Halo reflektora
      canvas.drawCircle(
        pPos.screen,
        scale * 1.4,
        Paint()
          ..color = light.lightColor.withValues(alpha: alpha * 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
      );
      // Rdzeń LED
      canvas.drawCircle(
        pPos.screen,
        scale * 0.45,
        Paint()..color = light.lightColor,
      );
    }
    return drawn;
  }

  int _paintWoodenBowlAndLines({
    required Canvas canvas,
    required _ProjectedCamPoint? Function(Vector3) project,
    required Vector3 camPos,
  }) {
    const int longitudinalSegments = 96;
    final double total = geometryBuilder.trackLengthMeters;
    final double ds = total / longitudinalSegments;

    // Pasy poprzeczne: [apron, wood1..wood5]
    final List<double> bandOffsets = [
      -config.apronWidthMeters,
      0.0,
      1.2,
      2.6,
      4.2,
      5.8,
      config.trackWidthMeters,
    ];

    final List<_SortedRenderQuad> quads = [];
    final Color baseWood = _woodBaseColor(config.facility.woodSurface);

    for (int i = 0; i < longitudinalSegments; i++) {
      final double s0 = i * ds;
      final double s1 = (i + 1) * ds;
      final sample0 = geometryBuilder.sampleAt(s0);
      final sample1 = geometryBuilder.sampleAt(s1);

      for (int b = 0; b < bandOffsets.length - 1; b++) {
        final double latA = bandOffsets[b];
        final double latB = bandOffsets[b + 1];

        final Vector3 w00 = sample0.pointAt(latA);
        final Vector3 w10 = sample1.pointAt(latA);
        final Vector3 w11 = sample1.pointAt(latB);
        final Vector3 w01 = sample0.pointAt(latB);

        final p00 = project(w00);
        final p10 = project(w10);
        final p11 = project(w11);
        final p01 = project(w01);
        if (p00 == null || p10 == null || p11 == null || p01 == null) {
          continue;
        }

        final double avgDepth =
            (p00.depth + p10.depth + p11.depth + p01.depth) * 0.25;

        Color fillColor;
        Color? strokeColor;
        if (b == 0) {
          // Pas Côte d'Azur
          fillColor = const Color(0xFF1D6FA5);
          strokeColor = const Color(0xFF2888C7);
        } else {
          // Pasy klepek drewnianych z subtelnym zróżnicowaniem słojów
          final double grainShift = ((i + b * 3) % 4) * 0.025;
          final Vector3 quadCenter = (w00 + w10 + w11 + w01) * 0.25;
          final Vector3 normal = (sample0.surfaceNormal + sample1.surfaceNormal)
            ..normalize();

          // Oświetlenie rozproszone + odbicia reflektorów w lakierze
          double specular = 0.0;
          if (config.showParquetSpecularReflections) {
            final Vector3 viewDir = (camPos - quadCenter)..normalize();
            for (final light in spotlights) {
              final Vector3 lightDir = (light.position - quadCenter);
              final double dist2 = math.max(25.0, lightDir.length2);
              lightDir.normalize();
              final Vector3 halfVec = (lightDir + viewDir)..normalize();
              final double ndoth = math.max(0.0, normal.dot(halfVec));
              final double spec = math.pow(ndoth, 24).toDouble() *
                  (280.0 / dist2) *
                  config.spotlightIntensity *
                  config.woodVarnishGlossiness;
              specular += spec;
            }
          }
          specular = specular.clamp(0.0, 0.85);

          final Color plankTint = Color.lerp(
            baseWood,
            const Color(0xFF9C6330),
            grainShift + (b / 10.0) * 0.25,
          )!;
          fillColor = Color.lerp(
            plankTint,
            const Color(0xFFFFF3D1),
            specular,
          )!;
          strokeColor = const Color(0xFF5A371A).withValues(alpha: 0.45);
        }

        quads.add(
          _SortedRenderQuad(
            avgDepth: avgDepth,
            points: [p00.screen, p10.screen, p11.screen, p01.screen],
            fillColor: fillColor,
            strokeColor: strokeColor,
            strokeWidth: 0.6,
          ),
        );
      }

      // Górna banda ochronna toru (półprzezroczysta barierka akrylowa)
      final Vector3 railBottom0 = sample0.pointAt(config.trackWidthMeters);
      final Vector3 railBottom1 = sample1.pointAt(config.trackWidthMeters);
      final Vector3 railTop0 = railBottom0 + Vector3(0.0, 0.95, 0.0);
      final Vector3 railTop1 = railBottom1 + Vector3(0.0, 0.95, 0.0);
      final prb0 = project(railBottom0);
      final prb1 = project(railBottom1);
      final prt1 = project(railTop1);
      final prt0 = project(railTop0);
      if (prb0 != null && prb1 != null && prt1 != null && prt0 != null) {
        quads.add(
          _SortedRenderQuad(
            avgDepth: (prb0.depth + prb1.depth + prt1.depth + prt0.depth) * 0.25,
            points: [prb0.screen, prb1.screen, prt1.screen, prt0.screen],
            fillColor: const Color(0xFF222630).withValues(alpha: 0.55),
            strokeColor: AppColors.cardBorder,
            strokeWidth: 1.0,
          ),
        );
      }
    }

    // Sortowanie od najdalszego quada do najbliższego
    quads.sort((a, b) => b.avgDepth.compareTo(a.avgDepth));

    final Paint fillPaint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()..style = PaintingStyle.stroke;

    for (final q in quads) {
      final path = Path()..addPolygon(q.points, true);
      fillPaint.color = q.fillColor;
      canvas.drawPath(path, fillPaint);
      if (q.strokeColor != null) {
        strokePaint
          ..color = q.strokeColor!
          ..strokeWidth = q.strokeWidth;
        canvas.drawPath(path, strokePaint);
      }
    }

    // Oficjalne linie torowe: czarna pomiarowa, czerwona sprinterska, niebieska stayerska
    _paintTrackRibbonLine(
      canvas: canvas,
      project: project,
      lateralMeters: VelodromeTrackLine.measurementBlackLine.heightAboveBlackLineMeters,
      color: const Color(0xFF111317),
      strokeWidth: 2.6,
    );
    _paintTrackRibbonLine(
      canvas: canvas,
      project: project,
      lateralMeters: VelodromeTrackLine.sprinterRedLine.heightAboveBlackLineMeters,
      color: const Color(0xFFEF4444),
      strokeWidth: 2.2,
    );
    _paintTrackRibbonLine(
      canvas: canvas,
      project: project,
      lateralMeters: VelodromeTrackLine.stayerBlueLine.heightAboveBlackLineMeters,
      color: const Color(0xFF38BDF8),
      strokeWidth: 2.4,
    );

    // Linia mety (biało-czarna szachownica na s = 26 m)
    _paintFinishLineStripe(canvas, project, 26.0);

    return quads.length;
  }

  void _paintTrackRibbonLine({
    required Canvas canvas,
    required _ProjectedCamPoint? Function(Vector3) project,
    required double lateralMeters,
    required Color color,
    required double strokeWidth,
  }) {
    const int steps = 120;
    final double total = geometryBuilder.trackLengthMeters;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset? prev;
    for (int i = 0; i <= steps; i++) {
      final double s = (i / steps) * total;
      final sample = geometryBuilder.sampleAt(s);
      final p = project(sample.pointAt(lateralMeters, verticalOffsetMeters: 0.02));
      if (p != null) {
        if (prev != null) {
          canvas.drawLine(prev, p.screen, paint);
        }
        prev = p.screen;
      } else {
        prev = null;
      }
    }
  }

  void _paintFinishLineStripe(
    Canvas canvas,
    _ProjectedCamPoint? Function(Vector3) project,
    double distanceMeters,
  ) {
    final s0 = geometryBuilder.sampleAt(distanceMeters - 0.18);
    final s1 = geometryBuilder.sampleAt(distanceMeters + 0.18);
    final p0 = project(s0.pointAt(0.0, verticalOffsetMeters: 0.03));
    final p1 = project(s1.pointAt(0.0, verticalOffsetMeters: 0.03));
    final p2 = project(
      s1.pointAt(config.trackWidthMeters, verticalOffsetMeters: 0.03),
    );
    final p3 = project(
      s0.pointAt(config.trackWidthMeters, verticalOffsetMeters: 0.03),
    );
    if (p0 != null && p1 != null && p2 != null && p3 != null) {
      canvas.drawPath(
        Path()..addPolygon([p0.screen, p1.screen, p2.screen, p3.screen], true),
        Paint()..color = const Color(0xFFF3F4F6).withValues(alpha: 0.85),
      );
    }
  }

  void _paintVirtualRecordLaser({
    required Canvas canvas,
    required _ProjectedCamPoint? Function(Vector3) project,
    required double virtualDistanceMeters,
    required double timeSeconds,
    required bool isRiderAhead,
  }) {
    final sample = geometryBuilder.sampleAt(virtualDistanceMeters);
    final pInner = project(sample.pointAt(-0.1, verticalOffsetMeters: 0.04));
    final pOuter = project(
      sample.pointAt(config.trackWidthMeters, verticalOffsetMeters: 0.04),
    );
    if (pInner == null || pOuter == null) return;

    final double pulse = 0.78 + 0.22 * math.sin(timeSeconds * 6.0);
    const Color laserCore = Color(0xFF00FF88);
    const Color laserGlow = AppColors.emeraldGreen;

    // Zewnętrzna poświata lasera na deskach
    canvas.drawLine(
      pInner.screen,
      pOuter.screen,
      Paint()
        ..color = laserGlow.withValues(alpha: 0.45 * pulse)
        ..strokeWidth = 11.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );
    // Ostry promień laserowy
    canvas.drawLine(
      pInner.screen,
      pOuter.screen,
      Paint()
        ..color = laserCore.withValues(alpha: 0.95)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Pionowy znacznik WR PACE nad górną bandą
    final pMarker = project(
      sample.pointAt(config.trackWidthMeters, verticalOffsetMeters: 1.35),
    );
    if (pMarker != null) {
      canvas.drawLine(
        pOuter.screen,
        pMarker.screen,
        Paint()
          ..color = laserCore.withValues(alpha: 0.7)
          ..strokeWidth = 1.5,
      );
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: isRiderAhead ? 'WR LASER (-)' : 'WR LASER (+)',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: laserCore,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final Rect tagRect = Rect.fromCenter(
        center: pMarker.screen - const Offset(0, 10),
        width: tp.width + 12,
        height: 18,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tagRect, const Radius.circular(6)),
        Paint()..color = AppColors.background.withValues(alpha: 0.88),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tagRect, const Radius.circular(6)),
        Paint()
          ..color = laserGlow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      tp.paint(
        canvas,
        Offset(tagRect.left + 6, tagRect.top + 2),
      );
    }
  }

  void _paintInfieldScoreboard({
    required Canvas canvas,
    required _ProjectedCamPoint? Function(Vector3) project,
    required Vector3 camPos,
    required int currentLap,
    required int totalLaps,
    required double riderSpeedKmh,
    required double deltaMeters,
    required String riderName,
  }) {
    final Vector3 boardCenter = Vector3(0.0, 5.4, 0.0);
    final pCenter = project(boardCenter);
    if (pCenter == null) return;

    // Pylon centralny tablicy wyników
    final pBase = project(Vector3(0.0, 0.0, 0.0));
    if (pBase != null) {
      canvas.drawLine(
        pBase.screen,
        pCenter.screen,
        Paint()
          ..color = const Color(0xFF2A2F3D)
          ..strokeWidth = (120.0 / pCenter.depth).clamp(2.5, 8.0),
      );
    }

    final double scale = (115.0 / pCenter.depth).clamp(0.55, 1.35);
    final double boardW = 196.0 * scale;
    final double boardH = 92.0 * scale;
    final Rect boardRect = Rect.fromCenter(
      center: pCenter.screen,
      width: boardW,
      height: boardH,
    );

    final RRect boardRRect = RRect.fromRectAndRadius(
      boardRect,
      Radius.circular(10.0 * scale),
    );
    canvas.drawRRect(
      boardRRect,
      Paint()..color = AppColors.surface.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      boardRRect,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final String deltaPrefix = deltaMeters >= 0 ? '+' : '';
    final Color deltaColor =
        deltaMeters >= 0 ? AppColors.emeraldGreen : AppColors.crimsonAlert;

    final TextPainter headerTp = TextPainter(
      text: TextSpan(
        text: 'UCI HOUR RECORD • $riderName',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5 * scale,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.goldAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boardW - 12);
    headerTp.paint(
      canvas,
      Offset(boardRect.left + 8 * scale, boardRect.top + 7 * scale),
    );

    final TextPainter metricsTp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'LAP $currentLap/$totalLaps   ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: '${riderSpeedKmh.toStringAsFixed(2)} KM/H\n',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5 * scale,
              fontWeight: FontWeight.w700,
              color: AppColors.accentBlue,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: 'VS WR LASER: $deltaPrefix${deltaMeters.toStringAsFixed(2)} M',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.0 * scale,
              fontWeight: FontWeight.w700,
              color: deltaColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boardW - 12);
    metricsTp.paint(
      canvas,
      Offset(boardRect.left + 8 * scale, boardRect.top + 26 * scale),
    );
  }

  void _paintTrackCyclist3D({
    required Canvas canvas,
    required _ProjectedCamPoint? Function(Vector3) project,
    required VelodromeTrackRider3D rider,
    required double timeSeconds,
    required double focalLength,
  }) {
    final sample = geometryBuilder.sampleAt(rider.distanceMeters);
    final Vector3 contact = sample.pointAt(rider.metersAboveBlackLine);
    final Vector3 rearWheelPos = contact - (sample.tangent * 0.52);
    final Vector3 frontWheelPos = contact + (sample.tangent * 0.52);

    // Kolarz pochyla się do wnętrza wiraża zgodnie z kątem nachylenia toru
    final Vector3 leanUp = (sample.surfaceNormal * 0.85 +
            (-sample.outwardRadial) * math.sin(sample.bankingRadians) * 0.35)
        .normalized();

    final Vector3 saddlePos = contact + (leanUp * 0.92) - (sample.tangent * 0.12);
    final Vector3 barPos = contact + (leanUp * 0.86) + (sample.tangent * 0.36);
    final Vector3 shoulderPos =
        contact + (leanUp * 1.18) + (sample.tangent * 0.14);
    final Vector3 helmetPos =
        contact + (leanUp * 1.32) + (sample.tangent * 0.30);

    final pRear = project(rearWheelPos + (leanUp * 0.33));
    final pFront = project(frontWheelPos + (leanUp * 0.33));
    final pContact = project(contact);
    final pSaddle = project(saddlePos);
    final pBar = project(barPos);
    final pShoulder = project(shoulderPos);
    final pHelmet = project(helmetPos);

    if (pRear == null ||
        pFront == null ||
        pContact == null ||
        pSaddle == null ||
        pBar == null ||
        pShoulder == null ||
        pHelmet == null) {
      return;
    }

    final double wheelR = (0.33 / pContact.depth) * focalLength;
    final double clampedWheelR = wheelR.clamp(4.0, 34.0);

    // Cień na lakierowanym parkiecie
    canvas.drawOval(
      Rect.fromCenter(
        center: pContact.screen,
        width: clampedWheelR * 2.8,
        height: clampedWheelR * 0.9,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );

    // Koła dyskowe (pełny dysk z przodu i z tyłu)
    final Paint discPaint = Paint()..color = const Color(0xFF14171D);
    final Paint tirePaint = Paint()
      ..color = const Color(0xFF2E3440)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (clampedWheelR * 0.16).clamp(1.2, 3.2);

    for (final pWheel in [pRear.screen, pFront.screen]) {
      canvas.drawCircle(pWheel, clampedWheelR, discPaint);
      canvas.drawCircle(pWheel, clampedWheelR, tirePaint);
    }

    // Rama torowa aero
    final Paint framePaint = Paint()
      ..color = rider.bikeFrameColor
      ..strokeWidth = (clampedWheelR * 0.22).clamp(1.6, 4.5)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pRear.screen, pSaddle.screen, framePaint);
    canvas.drawLine(pSaddle.screen, pBar.screen, framePaint);
    canvas.drawLine(pBar.screen, pFront.screen, framePaint);

    // Tułów i ramiona w pozycji czasowej aero
    final Paint jerseyPaint = Paint()
      ..color = rider.jerseyColor
      ..strokeWidth = (clampedWheelR * 0.42).clamp(3.0, 8.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pSaddle.screen, pShoulder.screen, jerseyPaint);
    canvas.drawLine(
      pShoulder.screen,
      pBar.screen,
      Paint()
        ..color = rider.jerseyColor
        ..strokeWidth = (clampedWheelR * 0.25).clamp(2.0, 5.0)
        ..strokeCap = StrokeCap.round,
    );

    // Animacja kadencji nóg
    final double phase = timeSeconds * (rider.cadenceRpm / 60.0) * 2.0 * math.pi;
    final Offset pedalOffset = Offset(
      math.cos(phase) * clampedWheelR * 0.35,
      math.sin(phase) * clampedWheelR * 0.35,
    );
    canvas.drawLine(
      pSaddle.screen,
      pContact.screen + pedalOffset,
      Paint()
        ..color = const Color(0xFF1E222A)
        ..strokeWidth = (clampedWheelR * 0.24).clamp(1.8, 4.5)
        ..strokeCap = StrokeCap.round,
    );

    // Kask aero
    canvas.drawOval(
      Rect.fromCenter(
        center: pHelmet.screen,
        width: clampedWheelR * 0.72,
        height: clampedWheelR * 0.50,
      ),
      Paint()..color = rider.helmetColor,
    );
  }

  Color _woodBaseColor(VelodromeWoodSurface surface) {
    switch (surface) {
      case VelodromeWoodSurface.siberianPine:
        return const Color(0xFFC68B4B);
      case VelodromeWoodSurface.siberianSpruce:
        return const Color(0xFFD2A164);
      case VelodromeWoodSurface.balticBirch:
        return const Color(0xFFD9B27C);
      case VelodromeWoodSurface.accoyaTreatedPine:
        return const Color(0xFFB87B3E);
    }
  }
}

class _CameraRig {
  final Vector3 position;
  final Vector3 forward;
  final Vector3 right;
  final Vector3 up;

  const _CameraRig({
    required this.position,
    required this.forward,
    required this.right,
    required this.up,
  });
}

// =============================================================================
// 6. CUSTOM PAINTER & INTERAKTYWNY WIDGET VIEWPORTU 3D WELODROMU
// =============================================================================

/// `CustomPainter` delegujący renderowanie krytego welodromu 3D.
class VelodromeWoodenBowl3dPainter extends CustomPainter {
  final VelodromeWoodenBowl3dRenderer renderer;
  final double timeSeconds;
  final VelodromeTrackRider3D heroRider;
  final List<VelodromeTrackRider3D> pacersOrRivals;
  final double cameraYawOffsetRadians;
  final ValueChanged<VelodromeWoodenBowlTelemetry>? onTelemetryUpdated;

  const VelodromeWoodenBowl3dPainter({
    required this.renderer,
    required this.timeSeconds,
    required this.heroRider,
    this.pacersOrRivals = const [],
    this.cameraYawOffsetRadians = 0.0,
    this.onTelemetryUpdated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final telemetry = renderer.paintScene(
      canvas: canvas,
      size: size,
      timeSeconds: timeSeconds,
      heroRider: heroRider,
      pacersOrRivals: pacersOrRivals,
      cameraYawOffsetRadians: cameraYawOffsetRadians,
    );
    onTelemetryUpdated?.call(telemetry);
  }

  @override
  bool shouldRepaint(covariant VelodromeWoodenBowl3dPainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.heroRider.distanceMeters != heroRider.distanceMeters ||
        oldDelegate.heroRider.speedKmh != heroRider.speedKmh ||
        oldDelegate.heroRider.metersAboveBlackLine !=
            heroRider.metersAboveBlackLine ||
        oldDelegate.cameraYawOffsetRadians != cameraYawOffsetRadians ||
        oldDelegate.renderer.config != renderer.config;
  }
}

/// Kompletny, responsywny widget podglądu 3D krytego welodromu z kontrolkami
/// (`390x844`, `1024x768`, `1600x900`), pełnymi stanami `hover`/`active`/`disabled`/`focus`,
/// paletą `AppColors` i czcionką `Inter`.
class VelodromeWoodenBowlViewportWidget extends StatefulWidget {
  final VelodromeWoodenBowlConfig initialConfig;
  final bool autoPlay;

  const VelodromeWoodenBowlViewportWidget({
    super.key,
    this.initialConfig = const VelodromeWoodenBowlConfig(),
    this.autoPlay = true,
  });

  @override
  State<VelodromeWoodenBowlViewportWidget> createState() =>
      _VelodromeWoodenBowlViewportWidgetState();
}

class _VelodromeWoodenBowlViewportWidgetState
    extends State<VelodromeWoodenBowlViewportWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late VelodromeWoodenBowlConfig _config;
  bool _isPaused = false;
  double _riderSpeedKmh = 57.15;
  VelodromeTrackLine _selectedLine = VelodromeTrackLine.measurementBlackLine;
  double _cameraYawOffset = 0.0;
  VelodromeWoodenBowlTelemetry? _telemetry;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
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

  @override
  Widget build(BuildContext context) {
    final renderer = VelodromeWoodenBowl3dRenderer(config: _config);

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
                    Flexible(
                      flex: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: _buildControls(isCompact: true),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 7, child: _buildCanvasArea(renderer)),
                    Container(
                      width: 320,
                      color: AppColors.surface,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildControls(isCompact: false),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCanvasArea(VelodromeWoodenBowl3dRenderer renderer) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _cameraYawOffset += details.delta.dx * 0.008;
        });
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final double timeSec = _animController.value * 60.0;
          final double heroDist = timeSec * (_riderSpeedKmh / 3.6);
          final hero = VelodromeTrackRider3D(
            riderId: 'hero_track',
            shortName: 'GANNA / PRO',
            jerseyColor: AppColors.primaryAccent,
            helmetColor: AppColors.goldAccent,
            bikeFrameColor: AppColors.accentBlue,
            distanceMeters: heroDist,
            metersAboveBlackLine: _selectedLine.heightAboveBlackLineMeters,
            speedKmh: _riderSpeedKmh,
            cadenceRpm: 105.0,
            powerWatts: 455.0,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: VelodromeWoodenBowl3dPainter(
                  renderer: renderer,
                  timeSeconds: timeSec,
                  heroRider: hero,
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
                  child: _VelodromeHudBadge(
                    facility: _config.facility,
                    telemetry: _telemetry!,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls({required bool isCompact}) {
    const facilities = VelodromeTrackAndHourRecordModel.defaultVelodromes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.stadium_rounded,
              color: AppColors.goldAccent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Welodrom 3D • 250 m',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _VelodromeActionButton(
              label: _isPaused ? 'Wznów' : 'Pauza',
              icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              isActive: !_isPaused,
              onPressed: _togglePlayPause,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Kamera 3D',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: VelodromeCameraMode.values.map((mode) {
            return _VelodromeActionButton(
              label: mode.shortTag,
              isActive: _config.cameraMode == mode,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(cameraMode: mode);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Linia Torowa',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            VelodromeTrackLine.measurementBlackLine,
            VelodromeTrackLine.sprinterRedLine,
            VelodromeTrackLine.stayerBlueLine,
          ].map((line) {
            return _VelodromeActionButton(
              label: line == VelodromeTrackLine.measurementBlackLine
                  ? 'Czarna (250m)'
                  : line == VelodromeTrackLine.sprinterRedLine
                      ? 'Czerwona'
                      : 'Niebieska',
              isActive: _selectedLine == line,
              onPressed: () {
                setState(() {
                  _selectedLine = line;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hala Welodromu',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: facilities.take(3).map((fac) {
            return _VelodromeActionButton(
              label: fac.city,
              isActive: _config.facility.id == fac.id,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(facility: fac);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Prędkość kolarza: ${_riderSpeedKmh.toStringAsFixed(1)} km/h',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.goldAccent,
            inactiveTrackColor: AppColors.surfaceLight,
            thumbColor: AppColors.goldAccent,
          ),
          child: Slider(
            value: _riderSpeedKmh,
            min: 44.0,
            max: 64.0,
            onChanged: (val) {
              setState(() {
                _riderSpeedKmh = val;
              });
            },
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _VelodromeActionButton(
              label: 'Laser WR',
              isActive: _config.showVirtualRecordLaser,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(
                    showVirtualRecordLaser: !_config.showVirtualRecordLaser,
                  );
                });
              },
            ),
            _VelodromeActionButton(
              label: 'Reflektory',
              isActive: _config.showRoofAndSpotlights,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(
                    showRoofAndSpotlights: !_config.showRoofAndSpotlights,
                  );
                });
              },
            ),
            _VelodromeActionButton(
              label: 'Tablica LED',
              isActive: _config.showInfieldScoreboard,
              onPressed: () {
                setState(() {
                  _config = _config.copyWith(
                    showInfieldScoreboard: !_config.showInfieldScoreboard,
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

class _VelodromeHudBadge extends StatelessWidget {
  final VelodromeFacilitySpec facility;
  final VelodromeWoodenBowlTelemetry telemetry;

  const _VelodromeHudBadge({
    required this.facility,
    required this.telemetry,
  });

  @override
  Widget build(BuildContext context) {
    final bool ahead = telemetry.deltaToRecordMeters >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${facility.name} • ${facility.turnBankingDegrees.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Wiraż: ${telemetry.localBankingDegrees.toStringAsFixed(1)}° • '
            '${telemetry.gForceLoadFactor.toStringAsFixed(2)}G • '
            'WR: ${ahead ? '+' : ''}${telemetry.deltaToRecordMeters.toStringAsFixed(2)} m',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ahead ? AppColors.emeraldGreen : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _VelodromeActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _VelodromeActionButton({
    required this.label,
    this.icon,
    this.isActive = false,
    this.onPressed,
  });

  @override
  State<_VelodromeActionButton> createState() => _VelodromeActionButtonState();
}

class _VelodromeActionButtonState extends State<_VelodromeActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
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
        ? AppColors.textSecondary.withValues(alpha: 0.5)
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
