// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/race/stage_segment.dart';
import 'peloton_instanced_renderer.dart';
import 'scene_3d_math_projection.dart';

// =============================================================================
// 1. TYPY POJAZDÓW NEUTRALNEGO SERWISU, MEDYCZNYCH I SĘDZIOWSKICH
// =============================================================================

/// Rola pojazdu oficjalnego i ratowniczego w kolumnie wyścigu kolarskiego.
enum RaceConvoyVehicleRole {
  /// Żółty samochód neutralnego serwisu (np. Mavic Service Course) z bagażnikiem pełnym rowerów.
  neutralServiceYellow(
    callSign: 'NEUTRAL 1',
    lengthMeters: 4.85,
    widthMeters: 1.88,
    heightMeters: 1.48,
    roofBikeCount: 4,
    primaryColor: Color(0xFFFACC15),
    roofColor: Color(0xFFFACC15),
    accentColor: Color(0xFF0F1115),
  ),

  /// Niebieski samochód neutralnego serwisu (np. Shimano Neutral Service) z bagażnikiem pełnym rowerów.
  neutralServiceBlue(
    callSign: 'NEUTRAL 2',
    lengthMeters: 4.85,
    widthMeters: 1.88,
    heightMeters: 1.48,
    roofBikeCount: 4,
    primaryColor: Color(0xFF0284C7),
    roofColor: Color(0xFF38BDF8),
    accentColor: Color(0xFFF3F4F6),
  ),

  /// Ambulans wyścigowy (Medical Car / Karetka) z wysoką zabudową i sygnalizacją świetlną.
  medicalAmbulance(
    callSign: 'AMBULANCE',
    lengthMeters: 5.55,
    widthMeters: 2.04,
    heightMeters: 2.35,
    roofBikeCount: 0,
    primaryColor: Color(0xFFF3F4F6),
    roofColor: Color(0xFFF3F4F6),
    accentColor: Color(0xFFEF4444),
  ),

  /// Wóz sędziowski Commissaire Car z charakterystycznym czerwonym dachem i anteną radiową.
  commissaireCar(
    callSign: 'COMMISSAIRE',
    lengthMeters: 4.75,
    widthMeters: 1.86,
    heightMeters: 1.46,
    roofBikeCount: 0,
    primaryColor: Color(0xFF181B22),
    roofColor: Color(0xFFDC2626),
    accentColor: Color(0xFFF3F4F6),
  );

  final String callSign;
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;
  final int roofBikeCount;
  final Color primaryColor;
  final Color roofColor;
  final Color accentColor;

  const RaceConvoyVehicleRole({
    required this.callSign,
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.roofBikeCount,
    required this.primaryColor,
    required this.roofColor,
    required this.accentColor,
  });

  bool get isNeutralService =>
      this == RaceConvoyVehicleRole.neutralServiceYellow ||
      this == RaceConvoyVehicleRole.neutralServiceBlue;

  bool get isAmbulance => this == RaceConvoyVehicleRole.medicalAmbulance;

  bool get isCommissaire => this == RaceConvoyVehicleRole.commissaireCar;
}

/// Strefa kolumny wyścigowej względem grup kolarzy na trasie.
enum ConvoyPlacementZone {
  /// Przed czołową grupą (ucieczką lub zwartym peletonem).
  aheadOfLeadGroup,

  /// Pomiędzy grupą czołową a grupą pościgową / peletonem.
  betweenGroups,

  /// Za ogonem głównej grupy / peletonu.
  behindPeloton,
}

/// Metryki rozkładu grup wykryte w bieżącej klatce symulacji.
class RaceConvoyGroupMetrics {
  final double leadFrontMeters;
  final double leadBackMeters;
  final double leadSpeedKmh;
  final double pelotonFrontMeters;
  final double pelotonBackMeters;
  final double pelotonSpeedKmh;
  final double gapBetweenLeadAndPelotonMeters;
  final bool hasBreakawayGroup;
  final bool hasActiveIncident;

  const RaceConvoyGroupMetrics({
    required this.leadFrontMeters,
    required this.leadBackMeters,
    required this.leadSpeedKmh,
    required this.pelotonFrontMeters,
    required this.pelotonBackMeters,
    required this.pelotonSpeedKmh,
    required this.gapBetweenLeadAndPelotonMeters,
    required this.hasBreakawayGroup,
    required this.hasActiveIncident,
  });
}

/// Instancja pojazdu neutralnego serwisu, ambulansu lub wozu sędziowskiego w scenie 3D.
class NeutralAndMedicalVehicle3D {
  final String id;
  final RaceConvoyVehicleRole role;
  final ConvoyPlacementZone placementZone;
  final String callSign;
  final Vector3 worldPosition;
  final Vector3 tangent;
  final Vector3 lateralRight;
  final Vector3 surfaceNormal;
  final double distanceAlongCourseMeters;
  final double lateralOffsetMeters;
  final double speedKmh;
  final bool isEmergencyBeaconActive;
  final bool isRepositioning;

  const NeutralAndMedicalVehicle3D({
    required this.id,
    required this.role,
    required this.placementZone,
    required this.callSign,
    required this.worldPosition,
    required this.tangent,
    required this.lateralRight,
    required this.surfaceNormal,
    required this.distanceAlongCourseMeters,
    required this.lateralOffsetMeters,
    required this.speedKmh,
    this.isEmergencyBeaconActive = false,
    this.isRepositioning = false,
  });

  double get lengthMeters => role.lengthMeters;
  double get widthMeters => role.widthMeters;
  double get heightMeters => role.heightMeters;
  int get roofBikeCount => role.roofBikeCount;
  Color get primaryColor => role.primaryColor;
  Color get roofColor => role.roofColor;
  Color get accentColor => role.accentColor;
}

/// Konfiguracja zachowania i renderowania samochodów neutralnych, ambulansu i sędziów.
class NeutralAndMedicalCarsConfig {
  final bool enabled;
  final bool enableYellowNeutralCar;
  final bool enableBlueNeutralCar;
  final bool enableAmbulance;
  final bool enableCommissaireCars;
  final bool enableRoofBikes;
  final double leadClearanceMeters;
  final double rearClearanceMeters;
  final double betweenGroupsMinGapMeters;
  final double maxRenderDistanceMeters;

  const NeutralAndMedicalCarsConfig({
    this.enabled = true,
    this.enableYellowNeutralCar = true,
    this.enableBlueNeutralCar = true,
    this.enableAmbulance = true,
    this.enableCommissaireCars = true,
    this.enableRoofBikes = true,
    this.leadClearanceMeters = 26.0,
    this.rearClearanceMeters = 18.0,
    this.betweenGroupsMinGapMeters = 42.0,
    this.maxRenderDistanceMeters = 380.0,
  });
}

class _VehicleTrackState {
  double distanceMeters = 0.0;
  double lateralOffsetMeters = 0.0;
  double speedKmh = 42.0;
  bool initialized = false;

  _VehicleTrackState();
}

// =============================================================================
// 2. KONTROLER RUCHU I RENDERER 3D POJAZDÓW NEUTRALNYCH, MEDYCZNYCH I SĘDZIÓW
// =============================================================================

/// Symuluje i renderuje w pełnym rzutowaniu 3D na obiekcie [Canvas]:
/// 1. Żółte i niebieskie samochody neutralnego serwisu z bagażnikiem dachowym pełnym rowerów,
/// 2. Ambulans wyścigowy z podwyższoną zabudową, czerwonym krzyżem i kogutami LED,
/// 3. Wozy sędziowskie `Commissaire Car` z czerwonym dachem poruszające się przed i za grupami.
class NeutralServiceAndMedicalCarsController {
  final NeutralAndMedicalCarsConfig config;

  final Map<String, _VehicleTrackState> _trackStates = {};
  List<NeutralAndMedicalVehicle3D> _latestVehicles = const [];
  RaceConvoyGroupMetrics? _latestMetrics;

  // Prealokowane obiekty malarskie dla płynności 120 FPS
  late final Paint _shadowPaint;
  late final Paint _bodyPaint;
  late final Paint _roofPaint;
  late final Paint _glassPaint;
  late final Paint _wheelPaint;
  late final Paint _rimPaint;
  late final Paint _outlinePaint;
  late final Paint _rackPaint;
  late final Paint _bikeFramePaint;
  late final Paint _bikeWheelPaint;
  late final Paint _taillightPaint;
  late final Paint _headlightPaint;
  late final Paint _beaconRedPaint;
  late final Paint _beaconBluePaint;
  late final Paint _beaconAmberPaint;
  late final Paint _beaconGlowPaint;
  late final Paint _crossPaint;
  late final Paint _badgeBgPaint;
  late final Paint _badgeBorderPaint;

  NeutralServiceAndMedicalCarsController({
    this.config = const NeutralAndMedicalCarsConfig(),
  }) {
    _initPaintCache();
  }

  List<NeutralAndMedicalVehicle3D> get latestVehicles => _latestVehicles;
  RaceConvoyGroupMetrics? get latestMetrics => _latestMetrics;

  void _initPaintCache() {
    _shadowPaint = Paint()
      ..color = const Color(0x88000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    _bodyPaint = Paint()..style = PaintingStyle.fill;
    _roofPaint = Paint()..style = PaintingStyle.fill;

    _glassPaint = Paint()
      ..color = const Color(0xD90F172A)
      ..style = PaintingStyle.fill;

    _wheelPaint = Paint()
      ..color = const Color(0xFF0F1115)
      ..style = PaintingStyle.fill;

    _rimPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    _outlinePaint = Paint()
      ..color = const Color(0x660F1115)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _rackPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _bikeFramePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    _bikeWheelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    _taillightPaint = Paint()
      ..color = AppColors.crimsonAlert
      ..style = PaintingStyle.fill;

    _headlightPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..style = PaintingStyle.fill;

    _beaconRedPaint = Paint()
      ..color = AppColors.crimsonAlert
      ..style = PaintingStyle.fill;

    _beaconBluePaint = Paint()
      ..color = AppColors.accentBlue
      ..style = PaintingStyle.fill;

    _beaconAmberPaint = Paint()
      ..color = AppColors.amberWarning
      ..style = PaintingStyle.fill;

    _beaconGlowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    _crossPaint = Paint()
      ..color = AppColors.crimsonAlert
      ..style = PaintingStyle.fill;

    _badgeBgPaint = Paint()
      ..color = AppColors.surface.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    _badgeBorderPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
  }

  /// Analizuje grupy kolarzy, aktualizuje płynnie pozycje pojazdów i zwraca listę
  /// instancji gotowych do wyrenderowania w przestrzeni 3D.
  List<NeutralAndMedicalVehicle3D> updateVehicles({
    required List<PelotonRenderItem> activeRiders,
    required List<StageSegment> segments,
    required double dtSeconds,
    required double elapsedSeconds,
  }) {
    if (!config.enabled || activeRiders.isEmpty) {
      _latestVehicles = const [];
      _latestMetrics = null;
      return const [];
    }

    final metrics = _analyzeGroupMetrics(activeRiders);
    _latestMetrics = metrics;

    final double clampedDt = dtSeconds.clamp(0.0, 0.25);
    final result = <NeutralAndMedicalVehicle3D>[];

    // 1. Wóz sędziowski Commissaire Car 1 (z czerwonym dachem) — PRZED czołową grupą
    if (config.enableCommissaireCars) {
      final double targetDist =
          metrics.leadFrontMeters + config.leadClearanceMeters + 12.0;
      final double sway = math.sin(elapsedSeconds * 0.45) * 0.18;
      result.add(
        _stepAndBuildVehicle(
          id: 'commissaire_lead',
          role: RaceConvoyVehicleRole.commissaireCar,
          placementZone: ConvoyPlacementZone.aheadOfLeadGroup,
          callSign: 'COMMISSAIRE 1',
          targetDistanceMeters: targetDist,
          targetLateralMeters: -1.65 + sway,
          targetSpeedKmh: metrics.leadSpeedKmh,
          segments: segments,
          dtSeconds: clampedDt,
          isEmergencyBeaconActive: metrics.hasActiveIncident,
        ),
      );
    }

    // 2. Żółty samochód neutralnego serwisu (Mavic) — PRZED czołową grupą
    if (config.enableYellowNeutralCar) {
      final double targetDist =
          metrics.leadFrontMeters + config.leadClearanceMeters;
      final double sway = math.cos(elapsedSeconds * 0.38) * 0.16;
      result.add(
        _stepAndBuildVehicle(
          id: 'neutral_yellow_lead',
          role: RaceConvoyVehicleRole.neutralServiceYellow,
          placementZone: ConvoyPlacementZone.aheadOfLeadGroup,
          callSign: 'NEUTRAL 1',
          targetDistanceMeters: targetDist,
          targetLateralMeters: 1.70 + sway,
          targetSpeedKmh: metrics.leadSpeedKmh,
          segments: segments,
          dtSeconds: clampedDt,
          isEmergencyBeaconActive: false,
        ),
      );
    }

    // 3. Niebieski samochód neutralnego serwisu (Shimano) — MIĘDZY grupami lub ZA grupą
    if (config.enableBlueNeutralCar) {
      final bool placeBetween = metrics.hasBreakawayGroup &&
          metrics.gapBetweenLeadAndPelotonMeters >=
              config.betweenGroupsMinGapMeters;

      final ConvoyPlacementZone zone = placeBetween
          ? ConvoyPlacementZone.betweenGroups
          : ConvoyPlacementZone.behindPeloton;

      final double targetDist = placeBetween
          ? metrics.leadBackMeters -
              math.min(18.0, metrics.gapBetweenLeadAndPelotonMeters * 0.35)
          : metrics.pelotonBackMeters - config.rearClearanceMeters;

      final double targetSpeed =
          placeBetween ? metrics.leadSpeedKmh : metrics.pelotonSpeedKmh;

      result.add(
        _stepAndBuildVehicle(
          id: 'neutral_blue_support',
          role: RaceConvoyVehicleRole.neutralServiceBlue,
          placementZone: zone,
          callSign: 'NEUTRAL 2',
          targetDistanceMeters: targetDist,
          targetLateralMeters: placeBetween ? 1.75 : -1.75,
          targetSpeedKmh: targetSpeed,
          segments: segments,
          dtSeconds: clampedDt,
          isEmergencyBeaconActive: false,
        ),
      );
    }

    // 4. Wóz sędziowski Commissaire Car 2 (z czerwonym dachem) — ZA peletonem
    if (config.enableCommissaireCars) {
      final double targetDist =
          metrics.pelotonBackMeters - config.rearClearanceMeters - 12.0;
      result.add(
        _stepAndBuildVehicle(
          id: 'commissaire_rear',
          role: RaceConvoyVehicleRole.commissaireCar,
          placementZone: ConvoyPlacementZone.behindPeloton,
          callSign: 'COMMISSAIRE 2',
          targetDistanceMeters: targetDist,
          targetLateralMeters: 1.70,
          targetSpeedKmh: metrics.pelotonSpeedKmh,
          segments: segments,
          dtSeconds: clampedDt,
          isEmergencyBeaconActive: metrics.hasActiveIncident,
        ),
      );
    }

    // 5. Ambulans wyścigowy (Medical Car) — ZA ostatnią grupą / peletonem
    if (config.enableAmbulance) {
      final double targetDist =
          metrics.pelotonBackMeters - config.rearClearanceMeters - 26.0;
      result.add(
        _stepAndBuildVehicle(
          id: 'medical_ambulance',
          role: RaceConvoyVehicleRole.medicalAmbulance,
          placementZone: ConvoyPlacementZone.behindPeloton,
          callSign: 'AMBULANCE',
          targetDistanceMeters: targetDist,
          targetLateralMeters: -1.65,
          targetSpeedKmh: metrics.pelotonSpeedKmh,
          segments: segments,
          dtSeconds: clampedDt,
          isEmergencyBeaconActive: true,
        ),
      );
    }

    _latestVehicles = result;
    return result;
  }

  RaceConvoyGroupMetrics _analyzeGroupMetrics(
      List<PelotonRenderItem> activeRiders) {
    final sorted = List<PelotonRenderItem>.from(activeRiders)
      ..sort((a, b) => b.snapshot.distanceCoveredMeters
          .compareTo(a.snapshot.distanceCoveredMeters));

    final double leadFront = sorted.first.snapshot.distanceCoveredMeters;
    final double pelotonBack = sorted.last.snapshot.distanceCoveredMeters;
    final double leadSpeed = sorted.first.snapshot.speedKmh;

    double leadBack = leadFront;
    double pelotonFront = leadFront;
    double largestGap = 0.0;
    int splitIndex = -1;

    for (int i = 0; i < sorted.length - 1; i++) {
      final double gap = sorted[i].snapshot.distanceCoveredMeters -
          sorted[i + 1].snapshot.distanceCoveredMeters;
      if (gap > largestGap) {
        largestGap = gap;
        splitIndex = i;
      }
    }

    final bool hasBreakaway =
        splitIndex >= 0 && largestGap >= config.betweenGroupsMinGapMeters;
    if (hasBreakaway) {
      leadBack = sorted[splitIndex].snapshot.distanceCoveredMeters;
      pelotonFront = sorted[splitIndex + 1].snapshot.distanceCoveredMeters;
    } else {
      leadBack = pelotonBack;
      pelotonFront = leadFront;
    }

    final double pelotonSpeed = hasBreakaway
        ? sorted[splitIndex + 1].snapshot.speedKmh
        : sorted.last.snapshot.speedKmh;

    final bool hasIncident = activeRiders.any(
      (r) =>
          r.snapshot.isCrashed ||
          r.snapshot.hasDefect ||
          (r.snapshot.speedKmh < 12.0 && r.snapshot.distanceCoveredMeters > 50),
    );

    return RaceConvoyGroupMetrics(
      leadFrontMeters: leadFront,
      leadBackMeters: leadBack,
      leadSpeedKmh: leadSpeed,
      pelotonFrontMeters: pelotonFront,
      pelotonBackMeters: pelotonBack,
      pelotonSpeedKmh: pelotonSpeed,
      gapBetweenLeadAndPelotonMeters: hasBreakaway ? largestGap : 0.0,
      hasBreakawayGroup: hasBreakaway,
      hasActiveIncident: hasIncident,
    );
  }

  NeutralAndMedicalVehicle3D _stepAndBuildVehicle({
    required String id,
    required RaceConvoyVehicleRole role,
    required ConvoyPlacementZone placementZone,
    required String callSign,
    required double targetDistanceMeters,
    required double targetLateralMeters,
    required double targetSpeedKmh,
    required List<StageSegment> segments,
    required double dtSeconds,
    required bool isEmergencyBeaconActive,
  }) {
    final state = _trackStates.putIfAbsent(id, () => _VehicleTrackState());

    bool repositioning = false;
    if (!state.initialized || dtSeconds <= 0.0) {
      state.distanceMeters = targetDistanceMeters;
      state.lateralOffsetMeters = targetLateralMeters;
      state.speedKmh = targetSpeedKmh;
      state.initialized = true;
    } else {
      final double lerpDist = (1.0 - math.exp(-dtSeconds * 4.5)).clamp(0.0, 1.0);
      final double lerpLat = (1.0 - math.exp(-dtSeconds * 3.2)).clamp(0.0, 1.0);

      final double distDiff = (targetDistanceMeters - state.distanceMeters).abs();
      repositioning = distDiff > 3.5;

      state.distanceMeters +=
          (targetDistanceMeters - state.distanceMeters) * lerpDist;
      state.lateralOffsetMeters +=
          (targetLateralMeters - state.lateralOffsetMeters) * lerpLat;
      state.speedKmh += (targetSpeedKmh - state.speedKmh) * lerpDist;
    }

    final double clampedLat = state.lateralOffsetMeters.clamp(-2.8, 2.8);
    final double elev = _calculateElevationAt(state.distanceMeters, segments);
    final double grad = _calculateGradientAt(state.distanceMeters, segments);

    final Vector3 worldPos = Scene3DMathProjection.courseToWorld3D(
      distanceMeters: state.distanceMeters,
      lateralOffsetMeters: clampedLat,
      elevationMeters: elev,
      turningRadiusMeters: double.infinity,
      gradientPercent: grad,
    );

    final double slopeRad = math.atan(grad / 100.0);
    final Vector3 tangent =
        Vector3(0.0, math.sin(slopeRad), math.cos(slopeRad))..normalize();
    final Vector3 lateralRight = Vector3(1.0, 0.0, 0.0);
    final Vector3 surfaceNormal = tangent.cross(lateralRight)..normalize();
    if (surfaceNormal.y < 0) {
      surfaceNormal.negate();
    }

    return NeutralAndMedicalVehicle3D(
      id: id,
      role: role,
      placementZone: placementZone,
      callSign: callSign,
      worldPosition: worldPos,
      tangent: tangent,
      lateralRight: lateralRight,
      surfaceNormal: surfaceNormal,
      distanceAlongCourseMeters: state.distanceMeters,
      lateralOffsetMeters: clampedLat,
      speedKmh: state.speedKmh,
      isEmergencyBeaconActive: isEmergencyBeaconActive,
      isRepositioning: repositioning,
    );
  }

  // ===========================================================================
  // 3. RENDEROWANIE 3D POJAZDÓW NA CANVAS (PEŁNA PROJEKCJA WIERZCHOŁKÓW 3D)
  // ===========================================================================

  /// Rysuje wszystkie widoczne pojazdy neutralnego serwisu, ambulans i wozy sędziowskie
  /// z sortowaniem głębokości Back-to-Front oraz rzutowaniem wierzchołków 3D.
  void renderVehicles({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required List<NeutralAndMedicalVehicle3D> vehicles,
    double elapsedAnimSeconds = 0.0,
  }) {
    if (!config.enabled || vehicles.isEmpty) return;

    final Vector3 eyePos = projection.cameraPosition;
    final visible = <(NeutralAndMedicalVehicle3D, ProjectedPoint3D, double)>[];

    for (final v in vehicles) {
      final double camDist = (v.worldPosition - eyePos).length;
      if (camDist > config.maxRenderDistanceMeters) continue;

      final ProjectedPoint3D proj = projection.worldToScreen(v.worldPosition);
      if (!proj.isInFrontOfCamera) continue;

      const double margin = 140.0;
      if (proj.screenX < -margin ||
          proj.screenX > projection.viewportWidth + margin ||
          proj.screenY < -margin ||
          proj.screenY > projection.viewportHeight + margin) {
        continue;
      }

      visible.add((v, proj, camDist));
    }

    if (visible.isEmpty) return;

    // Painter's Algorithm: najdalsze najpierw
    visible.sort((a, b) => b.$3.compareTo(a.$3));

    for (final (vehicle, proj, camDist) in visible) {
      _drawVehicle3D(
        canvas: canvas,
        projection: projection,
        vehicle: vehicle,
        centerProj: proj,
        cameraDistanceMeters: camDist,
        animSeconds: elapsedAnimSeconds,
      );
    }
  }

  Offset? _projectLocal(
    Scene3DMathProjection projection,
    NeutralAndMedicalVehicle3D v,
    double forwardM,
    double rightM,
    double upM,
  ) {
    final Vector3 p = v.worldPosition +
        (v.tangent * forwardM) +
        (v.lateralRight * rightM) +
        (v.surfaceNormal * upM);
    final ProjectedPoint3D res = projection.worldToScreen(p);
    if (!res.isInFrontOfCamera) return null;
    return Offset(res.screenX, res.screenY);
  }

  void _drawQuad(
    Canvas canvas,
    Offset? p0,
    Offset? p1,
    Offset? p2,
    Offset? p3,
    Paint fillPaint, {
    bool drawOutline = true,
  }) {
    if (p0 == null || p1 == null || p2 == null || p3 == null) return;
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(path, fillPaint);
    if (drawOutline) {
      canvas.drawPath(path, _outlinePaint);
    }
  }

  void _drawVehicle3D({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required NeutralAndMedicalVehicle3D vehicle,
    required ProjectedPoint3D centerProj,
    required double cameraDistanceMeters,
    required double animSeconds,
  }) {
    final double halfL = vehicle.lengthMeters * 0.5;
    final double halfW = vehicle.widthMeters * 0.5;
    final double bodyH = vehicle.role.isAmbulance ? 1.55 : 0.78;
    final double roofH = vehicle.heightMeters;
    final double roofHalfL =
        vehicle.role.isAmbulance ? halfL * 0.88 : halfL * 0.56;
    final double roofHalfW = halfW * 0.86;
    const double wheelRadius = 0.34;
    final double scale = (centerProj.perspectiveScale * 14.0).clamp(0.25, 4.5);

    // Kierunek patrzenia kamery względem osi pojazdu
    final Vector3 toVehicle = vehicle.worldPosition - projection.cameraPosition;
    final bool cameraBehind = toVehicle.dot(vehicle.tangent) > 0.0;
    final bool cameraOnRight = toVehicle.dot(vehicle.lateralRight) < 0.0;

    // 1. Cień kontaktowy na asfalcie
    final sFL = _projectLocal(projection, vehicle, halfL * 1.05, -halfW * 1.08, 0.02);
    final sFR = _projectLocal(projection, vehicle, halfL * 1.05, halfW * 1.08, 0.02);
    final sRR = _projectLocal(projection, vehicle, -halfL * 1.05, halfW * 1.08, 0.02);
    final sRL = _projectLocal(projection, vehicle, -halfL * 1.05, -halfW * 1.08, 0.02);
    _drawQuad(canvas, sFL, sFR, sRR, sRL, _shadowPaint, drawOutline: false);

    // 2. Cztery koła pojazdu
    final wheelOffsets = <(double, double)>[
      (halfL * 0.65, -halfW * 0.96),
      (halfL * 0.65, halfW * 0.96),
      (-halfL * 0.65, -halfW * 0.96),
      (-halfL * 0.65, halfW * 0.96),
    ];
    for (final (wf, wr) in wheelOffsets) {
      final wp = _projectLocal(projection, vehicle, wf, wr, wheelRadius * 0.85);
      if (wp != null) {
        final double r = (3.4 * scale).clamp(1.6, 14.0);
        canvas.drawCircle(wp, r, _wheelPaint);
        canvas.drawCircle(wp, r * 0.52, _rimPaint);
      }
    }

    // 3. Dolna bryła nadwozia (Chassis)
    const double baseZ = 0.24;
    final bFL = _projectLocal(projection, vehicle, halfL, -halfW, baseZ);
    final bFR = _projectLocal(projection, vehicle, halfL, halfW, baseZ);
    final bRR = _projectLocal(projection, vehicle, -halfL, halfW, baseZ);
    final bRL = _projectLocal(projection, vehicle, -halfL, -halfW, baseZ);

    final mFL = _projectLocal(projection, vehicle, halfL, -halfW, bodyH);
    final mFR = _projectLocal(projection, vehicle, halfL, halfW, bodyH);
    final mRR = _projectLocal(projection, vehicle, -halfL, halfW, bodyH);
    final mRL = _projectLocal(projection, vehicle, -halfL, -halfW, bodyH);

    _bodyPaint.color = vehicle.primaryColor;

    // Boki dolnej bryły (rysowane zależnie od strony kamery)
    if (cameraOnRight) {
      _drawQuad(canvas, bFR, bRR, mRR, mFR, _bodyPaint);
    } else {
      _drawQuad(canvas, bFL, bRL, mRL, mFL, _bodyPaint);
    }

    // Maska przednia lub tył karoserii
    if (cameraBehind) {
      _drawQuad(canvas, bRL, bRR, mRR, mRL, _bodyPaint);
    } else {
      _drawQuad(canvas, bFL, bFR, mFR, mFL, _bodyPaint);
    }
    // Górna płaszczyzna maski/klapy
    _drawQuad(canvas, mFL, mFR, mRR, mRL, _bodyPaint);

    // 4. Kabina i szyby (Greenhouse / Van Upper Body)
    final double cabFront = vehicle.role.isAmbulance ? halfL * 0.62 : roofHalfL;
    final double cabBack = vehicle.role.isAmbulance ? -halfL * 0.96 : -roofHalfL;

    final tFL = _projectLocal(projection, vehicle, cabFront, -roofHalfW, roofH);
    final tFR = _projectLocal(projection, vehicle, cabFront, roofHalfW, roofH);
    final tRR = _projectLocal(projection, vehicle, cabBack, roofHalfW, roofH);
    final tRL = _projectLocal(projection, vehicle, cabBack, -roofHalfW, roofH);

    final Paint cabinGlassOrBodyPaint =
        vehicle.role.isAmbulance ? _bodyPaint : _glassPaint;

    if (cameraOnRight) {
      _drawQuad(canvas, mFR, mRR, tRR, tFR, cabinGlassOrBodyPaint);
    } else {
      _drawQuad(canvas, mFL, mRL, tRL, tFL, cabinGlassOrBodyPaint);
    }

    if (cameraBehind) {
      _drawQuad(canvas, mRL, mRR, tRR, tRL, cabinGlassOrBodyPaint);
    } else {
      _drawQuad(canvas, mFL, mFR, tFR, tFL, _glassPaint);
    }

    // 5. Charakterystyczny dach (Czerwony dach dla Commissaire, biały dla Ambulansu, żółty/niebieski dla Neutral Service)
    _roofPaint.color = vehicle.roofColor;
    _drawQuad(canvas, tFL, tFR, tRR, tRL, _roofPaint);

    // 6. Detale specyficzne dla roli pojazdu
    if (vehicle.role.isNeutralService && config.enableRoofBikes) {
      _drawNeutralServiceRoofBikes(
        canvas: canvas,
        projection: projection,
        vehicle: vehicle,
        roofZ: roofH + 0.04,
        bikeColor: vehicle.primaryColor,
        accentColor: vehicle.accentColor,
      );
    } else if (vehicle.role.isAmbulance) {
      _drawAmbulanceDetails(
        canvas: canvas,
        projection: projection,
        vehicle: vehicle,
        roofZ: roofH,
        cameraBehind: cameraBehind,
        cameraOnRight: cameraOnRight,
        animSeconds: animSeconds,
      );
    } else if (vehicle.role.isCommissaire) {
      _drawCommissaireDetails(
        canvas: canvas,
        projection: projection,
        vehicle: vehicle,
        roofZ: roofH,
        animSeconds: animSeconds,
      );
    }

    // 7. Światła tylne lub przednie
    if (cameraBehind) {
      final tlL = _projectLocal(
          projection, vehicle, -halfL - 0.02, -halfW * 0.72, baseZ + 0.25);
      final tlR = _projectLocal(
          projection, vehicle, -halfL - 0.02, halfW * 0.72, baseZ + 0.25);
      final double lightR = (2.1 * scale).clamp(1.2, 6.5);
      if (tlL != null) canvas.drawCircle(tlL, lightR, _taillightPaint);
      if (tlR != null) canvas.drawCircle(tlR, lightR, _taillightPaint);
    } else {
      final hlL = _projectLocal(
          projection, vehicle, halfL + 0.02, -halfW * 0.72, baseZ + 0.25);
      final hlR = _projectLocal(
          projection, vehicle, halfL + 0.02, halfW * 0.72, baseZ + 0.25);
      final double lightR = (2.3 * scale).clamp(1.2, 7.0);
      if (hlL != null) canvas.drawCircle(hlL, lightR, _headlightPaint);
      if (hlR != null) canvas.drawCircle(hlR, lightR, _headlightPaint);
    }

    // 8. Czytelna etykieta pojazdu z bliska (Inter font, spójna z AppColors)
    if (cameraDistanceMeters < 95.0 && scale >= 0.42) {
      _drawCallsignBadge(
        canvas: canvas,
        projection: projection,
        vehicle: vehicle,
        anchorUpM: roofH + (vehicle.role.isNeutralService ? 1.15 : 0.55),
      );
    }
  }

  /// Rysuje bagażnik dachowy z 4 pełnymi rowerami szosowymi i 2 zapasowymi kołami.
  void _drawNeutralServiceRoofBikes({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required NeutralAndMedicalVehicle3D vehicle,
    required double roofZ,
    required Color bikeColor,
    required Color accentColor,
  }) {
    final double rackHalfW = vehicle.widthMeters * 0.42;
    // Dwie poprzeczne belki bagażnika dachowego
    for (final double fOffset in const [0.55, -0.55]) {
      final leftRail =
          _projectLocal(projection, vehicle, fOffset, -rackHalfW, roofZ);
      final rightRail =
          _projectLocal(projection, vehicle, fOffset, rackHalfW, roofZ);
      if (leftRail != null && rightRail != null) {
        canvas.drawLine(leftRail, rightRail, _rackPaint);
      }
    }

    // 4 rowery zamocowane obok siebie na bagażniku dachowym
    const lateralPositions = <double>[-0.63, -0.21, 0.21, 0.63];
    _bikeFramePaint.color = bikeColor;

    for (final double lat in lateralPositions) {
      final frontWheel =
          _projectLocal(projection, vehicle, 0.52, lat, roofZ + 0.26);
      final rearWheel =
          _projectLocal(projection, vehicle, -0.52, lat, roofZ + 0.26);
      final bottomBracket =
          _projectLocal(projection, vehicle, -0.05, lat, roofZ + 0.28);
      final saddle =
          _projectLocal(projection, vehicle, -0.28, lat, roofZ + 0.72);
      final stem =
          _projectLocal(projection, vehicle, 0.30, lat, roofZ + 0.70);

      if (frontWheel == null ||
          rearWheel == null ||
          bottomBracket == null ||
          saddle == null ||
          stem == null) {
        continue;
      }

      final double wheelRadiusPx =
          ((frontWheel - rearWheel).distance * 0.27).clamp(2.2, 11.0);

      // Dwa koła roweru
      canvas.drawCircle(rearWheel, wheelRadiusPx, _bikeWheelPaint);
      canvas.drawCircle(frontWheel, wheelRadiusPx, _bikeWheelPaint);

      // Rama diamentowa roweru
      canvas.drawLine(rearWheel, bottomBracket, _bikeFramePaint);
      canvas.drawLine(rearWheel, saddle, _bikeFramePaint);
      canvas.drawLine(bottomBracket, saddle, _bikeFramePaint);
      canvas.drawLine(bottomBracket, stem, _bikeFramePaint);
      canvas.drawLine(saddle, stem, _bikeFramePaint);
      canvas.drawLine(stem, frontWheel, _bikeFramePaint);
    }
  }

  /// Rysuje detale ambulansu: czerwony krzyż, pas ratowniczy i pulsujące koguty LED.
  void _drawAmbulanceDetails({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required NeutralAndMedicalVehicle3D vehicle,
    required double roofZ,
    required bool cameraBehind,
    required bool cameraOnRight,
    required double animSeconds,
  }) {
    // Czerwony krzyż na tylnych drzwiach lub na boku zabudowy
    final Offset? crossCenter = cameraBehind
        ? _projectLocal(
            projection, vehicle, -vehicle.lengthMeters * 0.505, 0.0, 1.35)
        : _projectLocal(
            projection,
            vehicle,
            -0.4,
            (cameraOnRight ? 1.0 : -1.0) * (vehicle.widthMeters * 0.505),
            1.35,
          );

    if (crossCenter != null) {
      const double crossHalf = 6.5;
      const double crossThick = 2.6;
      canvas.drawRect(
        Rect.fromCenter(
            center: crossCenter, width: crossHalf * 2, height: crossThick),
        _crossPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
            center: crossCenter, width: crossThick, height: crossHalf * 2),
        _crossPaint,
      );
    }

    // Koguty ratunkowe na przednim dachu (naprzemienny błysk czerwony / niebieski)
    final Offset? leftBeacon = _projectLocal(
        projection, vehicle, vehicle.lengthMeters * 0.25, -0.45, roofZ + 0.12);
    final Offset? rightBeacon = _projectLocal(
        projection, vehicle, vehicle.lengthMeters * 0.25, 0.45, roofZ + 0.12);

    final double phase = math.sin(animSeconds * 12.0);
    final bool redBright = phase >= 0.0;

    if (leftBeacon != null) {
      canvas.drawCircle(leftBeacon, 3.2, _beaconBluePaint);
      if (!redBright) {
        _beaconGlowPaint.color = AppColors.accentBlue.withValues(alpha: 0.75);
        canvas.drawCircle(leftBeacon, 8.5, _beaconGlowPaint);
      }
    }
    if (rightBeacon != null) {
      canvas.drawCircle(rightBeacon, 3.2, _beaconRedPaint);
      if (redBright) {
        _beaconGlowPaint.color = AppColors.crimsonAlert.withValues(alpha: 0.75);
        canvas.drawCircle(rightBeacon, 8.5, _beaconGlowPaint);
      }
    }
  }

  /// Rysuje detale wozu sędziowskiego Commissaire Car (antena radiowa + belka na czerwonym dachu).
  void _drawCommissaireDetails({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required NeutralAndMedicalVehicle3D vehicle,
    required double roofZ,
    required double animSeconds,
  }) {
    // Antena radia wyścigowego na tylnym rogu czerwonego dachu
    final antBase = _projectLocal(
        projection, vehicle, -vehicle.lengthMeters * 0.24, -0.45, roofZ);
    final antTip = _projectLocal(
        projection, vehicle, -vehicle.lengthMeters * 0.26, -0.45, roofZ + 0.85);
    if (antBase != null && antTip != null) {
      canvas.drawLine(antBase, antTip, _rackPaint);
    }

    // Belka sygnalizacyjna sędziów na środku czerwonego dachu
    final beaconCenter = _projectLocal(
        projection, vehicle, 0.10, 0.0, roofZ + 0.10);
    if (beaconCenter != null) {
      final Paint beaconPaint =
          vehicle.isEmergencyBeaconActive ? _beaconRedPaint : _beaconAmberPaint;
      canvas.drawCircle(beaconCenter, 2.8, beaconPaint);
      final double pulse = 0.5 + 0.5 * math.sin(animSeconds * 8.0);
      if (pulse > 0.45) {
        _beaconGlowPaint.color = (vehicle.isEmergencyBeaconActive
                ? AppColors.crimsonAlert
                : AppColors.amberWarning)
            .withValues(alpha: 0.60 * pulse);
        canvas.drawCircle(beaconCenter, 6.5 * pulse, _beaconGlowPaint);
      }
    }
  }

  void _drawCallsignBadge({
    required Canvas canvas,
    required Scene3DMathProjection projection,
    required NeutralAndMedicalVehicle3D vehicle,
    required double anchorUpM,
  }) {
    final anchor = _projectLocal(projection, vehicle, 0.0, 0.0, anchorUpM);
    if (anchor == null) return;

    final Color badgeAccent = vehicle.role.isCommissaire
        ? AppColors.crimsonAlert
        : vehicle.role.isAmbulance
            ? AppColors.crimsonAlert
            : vehicle.primaryColor;

    final textPainter = TextPainter(
      text: TextSpan(
        text: vehicle.callSign,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textPrimary,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double pillW = textPainter.width + 14.0;
    final double pillH = textPainter.height + 6.0;
    final RRect pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: anchor, width: pillW, height: pillH),
      const Radius.circular(8.0),
    );

    canvas.drawRRect(pillRect, _badgeBgPaint);
    _badgeBorderPaint.color = badgeAccent.withValues(alpha: 0.85);
    canvas.drawRRect(pillRect, _badgeBorderPaint);

    textPainter.paint(
      canvas,
      Offset(
        anchor.dx - textPainter.width * 0.5,
        anchor.dy - textPainter.height * 0.5,
      ),
    );
  }

  double _calculateElevationAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 450.0;
    final double km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        final double len = math.max(0.001, seg.endKm - seg.startKm);
        final double t = ((km - seg.startKm) / len).clamp(0.0, 1.0);
        return seg.startElevationM +
            (seg.endElevationM - seg.startElevationM) * t;
      }
    }
    return segments.last.endElevationM;
  }

  double _calculateGradientAt(double distMeters, List<StageSegment> segments) {
    if (segments.isEmpty) return 0.0;
    final double km = distMeters / 1000.0;
    for (final seg in segments) {
      if (km >= seg.startKm && km <= seg.endKm) {
        return seg.gradientPercent;
      }
    }
    return segments.last.gradientPercent;
  }
}
