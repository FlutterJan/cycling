// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../core/theme/app_colors.dart';
import '../../models/paracycling/uci_paracycling_tandem_handbike_model.dart';
import '../physics/tandem_and_handbike_physics_solver.dart';

// =============================================================================
// 1. KONFIGURACJA, TYPY POJAZDÓW I KAMERY 3D
// =============================================================================

/// Typ pojazdu paraolimpijskiego renderowanego w scenie 3D.
enum Paracycling3dVehicleType {
  tandemRoadB(
    labelPl: 'Tandem Szosowy (Klasa B)',
    shortTag: 'TANDEM B',
    wheelCount: 2,
  ),
  tandemTimeTrialB(
    labelPl: 'Tandem Czasowy Aero (Klasa B)',
    shortTag: 'TANDEM TT',
    wheelCount: 2,
  ),
  recumbentHandbikeH1H4(
    labelPl: 'Handbike Leżący (H1–H4)',
    shortTag: 'HANDBIKE H3',
    wheelCount: 3,
  ),
  kneelingHandbikeH5(
    labelPl: 'Handbike Klęczący (H5)',
    shortTag: 'HANDBIKE H5',
    wheelCount: 3,
  );

  final String labelPl;
  final String shortTag;
  final int wheelCount;

  const Paracycling3dVehicleType({
    required this.labelPl,
    required this.shortTag,
    required this.wheelCount,
  });

  bool get isTandem =>
      this == Paracycling3dVehicleType.tandemRoadB ||
      this == Paracycling3dVehicleType.tandemTimeTrialB;

  bool get isHandbike => !isTandem;
}

/// Presety kamery 3D dla tandemów i trójkołowych handbike'ów.
enum Paracycling3dCameraPreset {
  sideDynamic('Profil 3/4', '3/4 CHASE'),
  frontAero('Czoło Aero', 'AERO FRONT'),
  rearPeloton('Tył / Peleton', 'REAR VIEW'),
  topDownTelemetry('Rzut z Góry', 'TOP TELEMETRY');

  final String labelPl;
  final String shortTag;

  const Paracycling3dCameraPreset(this.labelPl, this.shortTag);
}

/// Konfiguracja wizualna renderera 3D tandemów i handbike'ów.
class Paracycling3dRenderConfig {
  final Paracycling3dVehicleType vehicleType;
  final Paracycling3dCameraPreset cameraPreset;
  final Color framePrimaryColor;
  final Color frameAccentColor;
  final Color pilotJerseyColor;
  final Color stokerJerseyColor;
  final bool showAeroStreamlines;
  final bool showThermalBrakeGlow;
  final bool showStabilityVectors;
  final bool showPlanarShadow;
  final bool showTelemetryOverlay;
  final double fieldOfViewDegrees;
  final double cameraOrbitYawOffsetRad;
  final double cameraOrbitPitchOffsetRad;
  final double cameraZoomFactor;

  const Paracycling3dRenderConfig({
    this.vehicleType = Paracycling3dVehicleType.tandemRoadB,
    this.cameraPreset = Paracycling3dCameraPreset.sideDynamic,
    this.framePrimaryColor = AppColors.primaryAccent,
    this.frameAccentColor = AppColors.goldAccent,
    this.pilotJerseyColor = AppColors.accentBlue,
    this.stokerJerseyColor = AppColors.goldAccent,
    this.showAeroStreamlines = true,
    this.showThermalBrakeGlow = true,
    this.showStabilityVectors = true,
    this.showPlanarShadow = true,
    this.showTelemetryOverlay = true,
    this.fieldOfViewDegrees = 50.0,
    this.cameraOrbitYawOffsetRad = 0.0,
    this.cameraOrbitPitchOffsetRad = 0.0,
    this.cameraZoomFactor = 1.0,
  });

  Paracycling3dRenderConfig copyWith({
    Paracycling3dVehicleType? vehicleType,
    Paracycling3dCameraPreset? cameraPreset,
    Color? framePrimaryColor,
    Color? frameAccentColor,
    Color? pilotJerseyColor,
    Color? stokerJerseyColor,
    bool? showAeroStreamlines,
    bool? showThermalBrakeGlow,
    bool? showStabilityVectors,
    bool? showPlanarShadow,
    bool? showTelemetryOverlay,
    double? fieldOfViewDegrees,
    double? cameraOrbitYawOffsetRad,
    double? cameraOrbitPitchOffsetRad,
    double? cameraZoomFactor,
  }) {
    return Paracycling3dRenderConfig(
      vehicleType: vehicleType ?? this.vehicleType,
      cameraPreset: cameraPreset ?? this.cameraPreset,
      framePrimaryColor: framePrimaryColor ?? this.framePrimaryColor,
      frameAccentColor: frameAccentColor ?? this.frameAccentColor,
      pilotJerseyColor: pilotJerseyColor ?? this.pilotJerseyColor,
      stokerJerseyColor: stokerJerseyColor ?? this.stokerJerseyColor,
      showAeroStreamlines: showAeroStreamlines ?? this.showAeroStreamlines,
      showThermalBrakeGlow: showThermalBrakeGlow ?? this.showThermalBrakeGlow,
      showStabilityVectors: showStabilityVectors ?? this.showStabilityVectors,
      showPlanarShadow: showPlanarShadow ?? this.showPlanarShadow,
      showTelemetryOverlay: showTelemetryOverlay ?? this.showTelemetryOverlay,
      fieldOfViewDegrees: fieldOfViewDegrees ?? this.fieldOfViewDegrees,
      cameraOrbitYawOffsetRad:
          cameraOrbitYawOffsetRad ?? this.cameraOrbitYawOffsetRad,
      cameraOrbitPitchOffsetRad:
          cameraOrbitPitchOffsetRad ?? this.cameraOrbitPitchOffsetRad,
      cameraZoomFactor: cameraZoomFactor ?? this.cameraZoomFactor,
    );
  }
}

// =============================================================================
// 2. DANE WEJŚCIOWE I TELEMETRIA RAMKI 3D
// =============================================================================

/// Stan kinematyczny dwuosobowego tandemu Klasy B do renderingu 3D.
class Tandem3dRenderInput {
  final double speedMs;
  final double gradientPercent;
  final double pilotCadenceRpm;
  final double stokerCadenceRpm;
  final double pilotWatts;
  final double stokerWatts;
  final TandemSyncPhase syncPhase;
  final double rotorTempCelsius;
  final DescentThermalBrakeStatus thermalStatus;
  final double leanAngleRad;
  final double steeringAngleRad;
  final double wheelbaseM;
  final double timeSeconds;

  const Tandem3dRenderInput({
    this.speedMs = 15.5,
    this.gradientPercent = 0.0,
    this.pilotCadenceRpm = 94.0,
    this.stokerCadenceRpm = 94.0,
    this.pilotWatts = 430.0,
    this.stokerWatts = 410.0,
    this.syncPhase = TandemSyncPhase.synchronized,
    this.rotorTempCelsius = 85.0,
    this.thermalStatus = DescentThermalBrakeStatus.nominal,
    this.leanAngleRad = 0.0,
    this.steeringAngleRad = 0.0,
    this.wheelbaseM = 1.72,
    this.timeSeconds = 0.0,
  });

  double get totalWatts => pilotWatts + stokerWatts;
  double get speedKmh => speedMs * 3.6;

  Tandem3dRenderInput copyWith({
    double? speedMs,
    double? gradientPercent,
    double? pilotCadenceRpm,
    double? stokerCadenceRpm,
    double? pilotWatts,
    double? stokerWatts,
    TandemSyncPhase? syncPhase,
    double? rotorTempCelsius,
    DescentThermalBrakeStatus? thermalStatus,
    double? leanAngleRad,
    double? steeringAngleRad,
    double? wheelbaseM,
    double? timeSeconds,
  }) {
    return Tandem3dRenderInput(
      speedMs: speedMs ?? this.speedMs,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      pilotCadenceRpm: pilotCadenceRpm ?? this.pilotCadenceRpm,
      stokerCadenceRpm: stokerCadenceRpm ?? this.stokerCadenceRpm,
      pilotWatts: pilotWatts ?? this.pilotWatts,
      stokerWatts: stokerWatts ?? this.stokerWatts,
      syncPhase: syncPhase ?? this.syncPhase,
      rotorTempCelsius: rotorTempCelsius ?? this.rotorTempCelsius,
      thermalStatus: thermalStatus ?? this.thermalStatus,
      leanAngleRad: leanAngleRad ?? this.leanAngleRad,
      steeringAngleRad: steeringAngleRad ?? this.steeringAngleRad,
      wheelbaseM: wheelbaseM ?? this.wheelbaseM,
      timeSeconds: timeSeconds ?? this.timeSeconds,
    );
  }
}

/// Stan kinematyczny trójkołowego handbike'a H1–H5 do renderingu 3D.
class Handbike3dRenderInput {
  final ParacyclingSportClass sportClass;
  final HandbikePostureType posture;
  final double speedMs;
  final double gradientPercent;
  final double handCrankRpm;
  final double watts;
  final double lateralG;
  final HandbikeTurnStabilityZone stabilityZone;
  final double innerWheelLiftRatio;
  final double steeringAngleRad;
  final double rearWheelCamberDeg;
  final double wheelbaseM;
  final double rearTrackWidthM;
  final double timeSeconds;

  const Handbike3dRenderInput({
    this.sportClass = ParacyclingSportClass.h3,
    this.posture = HandbikePostureType.recumbentLow,
    this.speedMs = 12.2,
    this.gradientPercent = 0.0,
    this.handCrankRpm = 88.0,
    this.watts = 265.0,
    this.lateralG = 0.22,
    this.stabilityZone = HandbikeTurnStabilityZone.planted,
    this.innerWheelLiftRatio = 0.0,
    this.steeringAngleRad = 0.0,
    this.rearWheelCamberDeg = 9.0,
    this.wheelbaseM = 1.38,
    this.rearTrackWidthM = 0.72,
    this.timeSeconds = 0.0,
  });

  double get speedKmh => speedMs * 3.6;

  Handbike3dRenderInput copyWith({
    ParacyclingSportClass? sportClass,
    HandbikePostureType? posture,
    double? speedMs,
    double? gradientPercent,
    double? handCrankRpm,
    double? watts,
    double? lateralG,
    HandbikeTurnStabilityZone? stabilityZone,
    double? innerWheelLiftRatio,
    double? steeringAngleRad,
    double? rearWheelCamberDeg,
    double? wheelbaseM,
    double? rearTrackWidthM,
    double? timeSeconds,
  }) {
    return Handbike3dRenderInput(
      sportClass: sportClass ?? this.sportClass,
      posture: posture ?? this.posture,
      speedMs: speedMs ?? this.speedMs,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      handCrankRpm: handCrankRpm ?? this.handCrankRpm,
      watts: watts ?? this.watts,
      lateralG: lateralG ?? this.lateralG,
      stabilityZone: stabilityZone ?? this.stabilityZone,
      innerWheelLiftRatio: innerWheelLiftRatio ?? this.innerWheelLiftRatio,
      steeringAngleRad: steeringAngleRad ?? this.steeringAngleRad,
      rearWheelCamberDeg: rearWheelCamberDeg ?? this.rearWheelCamberDeg,
      wheelbaseM: wheelbaseM ?? this.wheelbaseM,
      rearTrackWidthM: rearTrackWidthM ?? this.rearTrackWidthM,
      timeSeconds: timeSeconds ?? this.timeSeconds,
    );
  }
}

/// Telemetria pojedynczej wyrenderowanej klatki 3D.
class Paracycling3dFrameTelemetry {
  final Paracycling3dVehicleType vehicleType;
  final int wheelCount;
  final int primitiveCount;
  final int visibleMeshSegments;
  final double wheelRpm;
  final double syncPhaseDriftDeg;
  final double thermalGlowIntensity;
  final double innerWheelLiftMm;
  final double estimatedCdaM2;

  const Paracycling3dFrameTelemetry({
    required this.vehicleType,
    required this.wheelCount,
    required this.primitiveCount,
    required this.visibleMeshSegments,
    required this.wheelRpm,
    required this.syncPhaseDriftDeg,
    required this.thermalGlowIntensity,
    required this.innerWheelLiftMm,
    required this.estimatedCdaM2,
  });
}

// =============================================================================
// 3. PRYMITYWY SIATKI 3D I RZUTNIK PERSPEKTYWICZNY
// =============================================================================

/// Typ prymitywu 3D sortowanego algorytmem malarza (Z-depth).
enum _PrimitiveKind {
  line,
  polygon,
  circlePoint,
}

class _ProjectedPrimitive {
  final _PrimitiveKind kind;
  final double depth;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double radius;
  final bool filled;
  final Color? borderColor;

  const _ProjectedPrimitive({
    required this.kind,
    required this.depth,
    required this.points,
    required this.color,
    this.strokeWidth = 2.0,
    this.radius = 4.0,
    this.filled = true,
    this.borderColor,
  });
}

class _CameraTransform {
  final Vector3 eye;
  final Vector3 target;
  final Vector3 forward;
  final Vector3 right;
  final Vector3 up;
  final double focalLengthPx;
  final Size viewportSize;

  const _CameraTransform({
    required this.eye,
    required this.target,
    required this.forward,
    required this.right,
    required this.up,
    required this.focalLengthPx,
    required this.viewportSize,
  });

  /// Rzutuje punkt świata 3D na ekran 2D wraz z głębokością Z w przestrzeni kamery.
  ({Offset screen, double depth})? project(Vector3 worldPoint) {
    final rel = worldPoint - eye;
    final z = rel.dot(forward);
    if (z <= 0.15) return null;
    final x = rel.dot(right);
    final y = rel.dot(up);
    final scale = focalLengthPx / z;
    final sx = viewportSize.width * 0.5 + x * scale;
    final sy = viewportSize.height * 0.54 - y * scale;
    return (screen: Offset(sx, sy), depth: z);
  }

  /// Skala pikselowa dla promienia w świecie 3D na danej głębokości.
  double pixelsPerMeterAtDepth(double depth) {
    if (depth <= 0.15) return 0.0;
    return focalLengthPx / depth;
  }
}

// =============================================================================
// 4. GŁÓWNY RENDERER SIATEK 3D TANDEMÓW I HANDBIKE'ÓW
// =============================================================================

/// Silnik budowania i rzutowania siatek 3D dla tandemów Klasy B i trójkołowych handbike'ów H1–H5.
class TandemAndHandbike3dMeshRenderer {
  const TandemAndHandbike3dMeshRenderer();

  /// Buduje transformację kamery 3D na podstawie presetu, rozmiaru ekranu i offsetów orbity.
  _CameraTransform _buildCamera({
    required Paracycling3dRenderConfig config,
    required Size size,
  }) {
    final bool isTandem = config.vehicleType.isTandem;
    final Vector3 target = isTandem
        ? Vector3(0.0, 0.72, 0.0)
        : Vector3(0.0, 0.38, 0.0);

    double baseYaw;
    double basePitch;
    double baseDistance;

    switch (config.cameraPreset) {
      case Paracycling3dCameraPreset.sideDynamic:
        baseYaw = 0.62; // ~35 deg 3/4 view
        basePitch = 0.24;
        baseDistance = isTandem ? 3.55 : 2.95;
        break;
      case Paracycling3dCameraPreset.frontAero:
        baseYaw = 1.48; // frontal-ish view
        basePitch = 0.14;
        baseDistance = isTandem ? 3.45 : 2.75;
        break;
      case Paracycling3dCameraPreset.rearPeloton:
        baseYaw = -1.25; // rear 3/4 chase
        basePitch = 0.28;
        baseDistance = isTandem ? 3.65 : 2.95;
        break;
      case Paracycling3dCameraPreset.topDownTelemetry:
        baseYaw = 0.22;
        basePitch = 1.24; // steep overhead
        baseDistance = isTandem ? 3.90 : 3.25;
        break;
    }

    final yaw = baseYaw + config.cameraOrbitYawOffsetRad;
    final pitch = (basePitch + config.cameraOrbitPitchOffsetRad)
        .clamp(0.05, 1.45);
    final dist = (baseDistance / config.cameraZoomFactor.clamp(0.55, 2.2))
        .clamp(1.4, 8.0);

    final cosP = math.cos(pitch);
    final eye = Vector3(
      target.x + dist * cosP * math.cos(yaw),
      target.y + dist * math.sin(pitch),
      target.z + dist * cosP * math.sin(yaw),
    );

    final forward = (target - eye).normalized();
    final worldUp = Vector3(0.0, 1.0, 0.0);
    final right = forward.cross(worldUp).normalized();
    final up = right.cross(forward).normalized();

    final fovRad = config.fieldOfViewDegrees * math.pi / 180.0;
    final minDim = math.min(size.width, size.height).clamp(180.0, 2400.0);
    final focalLength = (minDim * 0.5) / math.tan(fovRad * 0.5);

    return _CameraTransform(
      eye: eye,
      target: target,
      forward: forward,
      right: right,
      up: up,
      focalLengthPx: focalLength,
      viewportSize: size,
    );
  }

  /// Renderuje pełną scenę 3D tandemu lub handbike'a na [Canvas] i zwraca telemetrię klatki.
  Paracycling3dFrameTelemetry renderFrame({
    required Canvas canvas,
    required Size size,
    required Paracycling3dRenderConfig config,
    required Tandem3dRenderInput tandemInput,
    required Handbike3dRenderInput handbikeInput,
  }) {
    if (size.isEmpty) {
      return Paracycling3dFrameTelemetry(
        vehicleType: config.vehicleType,
        wheelCount: config.vehicleType.wheelCount,
        primitiveCount: 0,
        visibleMeshSegments: 0,
        wheelRpm: 0.0,
        syncPhaseDriftDeg: 0.0,
        thermalGlowIntensity: 0.0,
        innerWheelLiftMm: 0.0,
        estimatedCdaM2: 0.20,
      );
    }

    final camera = _buildCamera(config: config, size: size);
    final primitives = <_ProjectedPrimitive>[];

    // 1. Siatka asfaltu i linie referencyjne toru jazdy
    final double speedMs = config.vehicleType.isTandem
        ? tandemInput.speedMs
        : handbikeInput.speedMs;
    final double timeSec = config.vehicleType.isTandem
        ? tandemInput.timeSeconds
        : handbikeInput.timeSeconds;
    final double gradientPercent = config.vehicleType.isTandem
        ? tandemInput.gradientPercent
        : handbikeInput.gradientPercent;

    _emitRoadGrid(
      primitives: primitives,
      camera: camera,
      speedMs: speedMs,
      timeSeconds: timeSec,
      gradientPercent: gradientPercent,
    );

    // 2. Generowanie siatki pojazdu i załogi
    late final Paracycling3dFrameTelemetry telemetry;
    if (config.vehicleType.isTandem) {
      telemetry = _emitTandemScene(
        primitives: primitives,
        camera: camera,
        config: config,
        input: tandemInput,
      );
    } else {
      telemetry = _emitHandbikeScene(
        primitives: primitives,
        camera: camera,
        config: config,
        input: handbikeInput,
      );
    }

    // 3. Sortowanie głębokości (algorytm malarza: od najdalszych do najbliższych)
    primitives.sort((a, b) => b.depth.compareTo(a.depth));

    // 4. Rasteryzacja prymitywów na Canvas
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final p in primitives) {
      switch (p.kind) {
        case _PrimitiveKind.line:
          if (p.points.length >= 2) {
            strokePaint
              ..color = p.color
              ..strokeWidth = p.strokeWidth;
            canvas.drawLine(p.points[0], p.points[1], strokePaint);
          }
          break;
        case _PrimitiveKind.polygon:
          if (p.points.length >= 3) {
            final path = Path()..moveTo(p.points[0].dx, p.points[0].dy);
            for (int i = 1; i < p.points.length; i++) {
              path.lineTo(p.points[i].dx, p.points[i].dy);
            }
            path.close();
            if (p.filled) {
              fillPaint.color = p.color;
              canvas.drawPath(path, fillPaint);
            }
            if (p.borderColor != null) {
              strokePaint
                ..color = p.borderColor!
                ..strokeWidth = p.strokeWidth;
              canvas.drawPath(path, strokePaint);
            }
          }
          break;
        case _PrimitiveKind.circlePoint:
          if (p.points.isNotEmpty) {
            if (p.filled) {
              fillPaint.color = p.color;
              canvas.drawCircle(p.points[0], p.radius, fillPaint);
            } else {
              strokePaint
                ..color = p.color
                ..strokeWidth = p.strokeWidth;
              canvas.drawCircle(p.points[0], p.radius, strokePaint);
            }
          }
          break;
      }
    }

    return telemetry;
  }

  // ---------------------------------------------------------------------------
  // SIATKA ASFALTU I STRUGI POWIETRZA
  // ---------------------------------------------------------------------------

  void _emitRoadGrid({
    required List<_ProjectedPrimitive> primitives,
    required _CameraTransform camera,
    required double speedMs,
    required double timeSeconds,
    required double gradientPercent,
  }) {
    final slopeRad = math.atan(gradientPercent / 100.0);
    final cosS = math.cos(slopeRad);
    final sinS = math.sin(slopeRad);

    Vector3 roadPt(double xLong, double zLat) {
      return Vector3(xLong * cosS, xLong * sinS, zLat);
    }

    // Pasek asfaltu (podłużne pasy)
    const double roadHalfLen = 4.2;
    const double roadHalfWidth = 1.65;

    final p1 = camera.project(roadPt(-roadHalfLen, -roadHalfWidth));
    final p2 = camera.project(roadPt(roadHalfLen, -roadHalfWidth));
    final p3 = camera.project(roadPt(roadHalfLen, roadHalfWidth));
    final p4 = camera.project(roadPt(-roadHalfLen, roadHalfWidth));

    if (p1 != null && p2 != null && p3 != null && p4 != null) {
      final avgDepth = (p1.depth + p2.depth + p3.depth + p4.depth) * 0.25 + 8.0;
      primitives.add(
        _ProjectedPrimitive(
          kind: _PrimitiveKind.polygon,
          depth: avgDepth,
          points: [p1.screen, p2.screen, p3.screen, p4.screen],
          color: const Color(0xFF141820),
          borderColor: AppColors.cardBorder.withValues(alpha: 0.45),
          strokeWidth: 1.0,
        ),
      );
    }

    // Ruchome pasy przerywane osi jezdni dające poczucie prędkości
    final double scrollOffset = (timeSeconds * speedMs) % 1.6;
    for (double x = -3.8 - scrollOffset; x <= 3.8; x += 1.6) {
      final xStart = x.clamp(-4.0, 4.0);
      final xEnd = (x + 0.65).clamp(-4.0, 4.0);
      if (xEnd - xStart < 0.08) continue;
      final a = camera.project(roadPt(xStart, 0.0));
      final b = camera.project(roadPt(xEnd, 0.0));
      if (a != null && b != null) {
        primitives.add(
          _ProjectedPrimitive(
            kind: _PrimitiveKind.line,
            depth: (a.depth + b.depth) * 0.5 + 7.5,
            points: [a.screen, b.screen],
            color: AppColors.goldAccent.withValues(alpha: 0.28),
            strokeWidth: 2.2,
          ),
        );
      }
    }

    // Krawędzie jezdni
    for (final zEdge in [-roadHalfWidth, roadHalfWidth]) {
      final a = camera.project(roadPt(-roadHalfLen, zEdge));
      final b = camera.project(roadPt(roadHalfLen, zEdge));
      if (a != null && b != null) {
        primitives.add(
          _ProjectedPrimitive(
            kind: _PrimitiveKind.line,
            depth: (a.depth + b.depth) * 0.5 + 7.5,
            points: [a.screen, b.screen],
            color: AppColors.textSecondary.withValues(alpha: 0.22),
            strokeWidth: 1.5,
          ),
        );
      }
    }
  }

  void _emitAeroStreamlines({
    required List<_ProjectedPrimitive> primitives,
    required _CameraTransform camera,
    required Vector3 Function(Vector3 local) toWorld,
    required double speedMs,
    required double timeSeconds,
    required double maxHeightM,
    required double lengthSpanM,
  }) {
    final phase = (timeSeconds * (1.4 + speedMs * 0.14)) % 1.0;
    const lanes = [
      (yFactor: 0.35, z: -0.26),
      (yFactor: 0.62, z: 0.0),
      (yFactor: 0.88, z: 0.18),
      (yFactor: 0.50, z: 0.28),
    ];

    for (int i = 0; i < lanes.length; i++) {
      final lane = lanes[i];
      final y = maxHeightM * lane.yFactor;
      final localOffset = ((phase + i * 0.25) % 1.0);
      final xFront = lengthSpanM * 0.68 - localOffset * lengthSpanM * 1.35;
      final xBack = xFront - 0.52;

      final pA = camera.project(toWorld(Vector3(xFront, y, lane.z)));
      final pB = camera.project(toWorld(Vector3(xBack, y + 0.02, lane.z)));
      if (pA != null && pB != null) {
        primitives.add(
          _ProjectedPrimitive(
            kind: _PrimitiveKind.line,
            depth: (pA.depth + pB.depth) * 0.5,
            points: [pA.screen, pB.screen],
            color: AppColors.cyanAccent.withValues(alpha: 0.32),
            strokeWidth: 1.4,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // RENDERER 3D TANDEMU DWUOSOBOWEGO (KLASA B)
  // ---------------------------------------------------------------------------

  Paracycling3dFrameTelemetry _emitTandemScene({
    required List<_ProjectedPrimitive> primitives,
    required _CameraTransform camera,
    required Paracycling3dRenderConfig config,
    required Tandem3dRenderInput input,
  }) {
    final slopeRad = math.atan(input.gradientPercent / 100.0);
    final leanRad = input.leanAngleRad;
    final bool isTt =
        config.vehicleType == Paracycling3dVehicleType.tandemTimeTrialB;

    const double wheelRadius = 0.34;
    final double wb = input.wheelbaseM.clamp(1.55, 1.95);
    final double frontAxleX = wb * 0.52;
    final double rearAxleX = -wb * 0.48;

    Vector3 toWorld(Vector3 local) {
      // Lean (roll around X)
      final cosL = math.cos(leanRad);
      final sinL = math.sin(leanRad);
      final ly = local.y * cosL - local.z * sinL;
      final lz = local.y * sinL + local.z * cosL;
      final lx = local.x;

      // Slope pitch (around Z)
      final cosS = math.cos(slopeRad);
      final sinS = math.sin(slopeRad);
      return Vector3(
        lx * cosS - ly * sinS,
        lx * sinS + ly * cosS,
        lz,
      );
    }

    // 1. Cień planarny na asfalcie
    if (config.showPlanarShadow) {
      final shadowPts = <Offset>[];
      final corners = [
        Vector3(rearAxleX - 0.36, 0.005, -0.18),
        Vector3(frontAxleX + 0.36, 0.005, -0.18),
        Vector3(frontAxleX + 0.36, 0.005, 0.18),
        Vector3(rearAxleX - 0.36, 0.005, 0.18),
      ];
      double avgD = 0.0;
      for (final c in corners) {
        final proj = camera.project(toWorld(Vector3(c.x, 0.005, c.z)));
        if (proj != null) {
          shadowPts.add(proj.screen);
          avgD += proj.depth;
        }
      }
      if (shadowPts.length == 4) {
        primitives.add(
          _ProjectedPrimitive(
            kind: _PrimitiveKind.polygon,
            depth: avgD * 0.25 + 6.0,
            points: shadowPts,
            color: Colors.black.withValues(alpha: 0.42),
          ),
        );
      }
    }

    // 2. Koła 3D (przednie i tylne) + tarcze hamulcowe z termiką
    final double wheelOmega = input.speedMs / wheelRadius;
    final double wheelPhase = input.timeSeconds * wheelOmega;

    final double thermalIntensity =
        ((input.rotorTempCelsius - 110.0) / 210.0).clamp(0.0, 1.0);
    final Color rotorColor = config.showThermalBrakeGlow
        ? Color.lerp(
            const Color(0xFF94A3B8),
            input.thermalStatus == DescentThermalBrakeStatus.thermalFade
                ? AppColors.crimsonAlert
                : AppColors.amberWarning,
            thermalIntensity,
          )!
        : const Color(0xFF94A3B8);

    _emit3dWheel(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      center: Vector3(frontAxleX, wheelRadius, 0.0),
      radius: wheelRadius,
      spinPhaseRad: wheelPhase,
      steerAngleRad: input.steeringAngleRad,
      camberAngleRad: 0.0,
      isDiscWheel: false,
      deepSection: isTt,
      rimColor: config.frameAccentColor,
      rotorColor: rotorColor,
      thermalIntensity: config.showThermalBrakeGlow ? thermalIntensity : 0.0,
    );

    _emit3dWheel(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      center: Vector3(rearAxleX, wheelRadius, 0.0),
      radius: wheelRadius,
      spinPhaseRad: wheelPhase,
      steerAngleRad: 0.0,
      camberAngleRad: 0.0,
      isDiscWheel: isTt,
      deepSection: true,
      rimColor: config.frameAccentColor,
      rotorColor: rotorColor,
      thermalIntensity: config.showThermalBrakeGlow ? thermalIntensity : 0.0,
    );

    // 3. Rama tandemu (podwójny kokpit, rura główna, tylny trójkąt, widelec)
    final double pilotBbX = frontAxleX - 0.62;
    final double stokerBbX = rearAxleX + 0.46;
    const double bbY = 0.28;

    final Vector3 rearAxle = Vector3(rearAxleX, wheelRadius, 0.0);
    final Vector3 frontAxle = Vector3(frontAxleX, wheelRadius, 0.0);
    final Vector3 stokerBb = Vector3(stokerBbX, bbY, 0.0);
    final Vector3 pilotBb = Vector3(pilotBbX, bbY, 0.0);

    final Vector3 stokerSeatCluster = Vector3(stokerBbX - 0.14, 0.78, 0.0);
    final Vector3 pilotSeatCluster = Vector3(pilotBbX - 0.14, 0.80, 0.0);
    final Vector3 headTubeBottom = Vector3(frontAxleX - 0.13, 0.68, 0.0);
    final Vector3 headTubeTop = Vector3(frontAxleX - 0.17, 0.85, 0.0);

    final frameColor = config.framePrimaryColor;
    final accentColor = config.frameAccentColor;

    // Główne rury ramy tandemu
    _emitTube(primitives, camera, toWorld, rearAxle, stokerBb, frameColor, 4.0);
    _emitTube(
      primitives,
      camera,
      toWorld,
      rearAxle,
      stokerSeatCluster,
      frameColor,
      3.5,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      stokerBb,
      stokerSeatCluster,
      frameColor,
      4.5,
    );
    _emitTube(primitives, camera, toWorld, stokerBb, pilotBb, frameColor, 6.0);
    _emitTube(
      primitives,
      camera,
      toWorld,
      stokerSeatCluster,
      pilotBb,
      accentColor,
      4.0,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      stokerSeatCluster,
      pilotSeatCluster,
      frameColor,
      4.5,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      pilotBb,
      pilotSeatCluster,
      frameColor,
      4.5,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      pilotSeatCluster,
      headTubeTop,
      frameColor,
      4.5,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      pilotBb,
      headTubeBottom,
      frameColor,
      5.5,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      headTubeBottom,
      headTubeTop,
      accentColor,
      5.0,
    );
    // Widelec przedni (podwójna goleń)
    _emitTube(
      primitives,
      camera,
      toWorld,
      headTubeBottom,
      Vector3(frontAxle.x, frontAxle.y, -0.05),
      frameColor,
      3.8,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      headTubeBottom,
      Vector3(frontAxle.x, frontAxle.y, 0.05),
      frameColor,
      3.8,
    );

    // Łańcuch synchronizujący (lewa strona) + łańcuch główny (prawa strona)
    _emitTube(
      primitives,
      camera,
      toWorld,
      Vector3(pilotBb.x, pilotBb.y + 0.05, -0.07),
      Vector3(stokerBb.x, stokerBb.y + 0.05, -0.07),
      AppColors.textSecondary.withValues(alpha: 0.7),
      1.6,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      Vector3(stokerBb.x, stokerBb.y + 0.06, 0.07),
      Vector3(rearAxle.x, rearAxle.y + 0.03, 0.05),
      AppColors.textSecondary.withValues(alpha: 0.8),
      1.8,
    );

    // Kierownice (Pilot: front drop/aero bars; Stoker: rear bars on pilot seatpost)
    final Vector3 pilotStem = Vector3(headTubeTop.x + 0.11, 0.92, 0.0);
    _emitTube(primitives, camera, toWorld, headTubeTop, pilotStem, accentColor, 3.2);
    final Vector3 pilotBarL = Vector3(pilotStem.x + (isTt ? 0.22 : 0.06), 0.90, -0.20);
    final Vector3 pilotBarR = Vector3(pilotStem.x + (isTt ? 0.22 : 0.06), 0.90, 0.20);
    _emitTube(primitives, camera, toWorld, pilotStem, pilotBarL, AppColors.textPrimary, 2.8);
    _emitTube(primitives, camera, toWorld, pilotStem, pilotBarR, AppColors.textPrimary, 2.8);

    final Vector3 stokerBarCenter = Vector3(pilotSeatCluster.x - 0.10, 0.89, 0.0);
    final Vector3 stokerBarL = Vector3(stokerBarCenter.x - 0.04, 0.88, -0.19);
    final Vector3 stokerBarR = Vector3(stokerBarCenter.x - 0.04, 0.88, 0.19);
    _emitTube(
      primitives,
      camera,
      toWorld,
      pilotSeatCluster,
      stokerBarCenter,
      accentColor,
      2.8,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      stokerBarCenter,
      stokerBarL,
      AppColors.textPrimary,
      2.6,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      stokerBarCenter,
      stokerBarR,
      AppColors.textPrimary,
      2.6,
    );

    // 4. Faza korby pilota i stokera
    final double pilotCrankPhase =
        input.timeSeconds * (input.pilotCadenceRpm / 60.0) * 2.0 * math.pi;
    final double stokerCrankPhase =
        input.timeSeconds * (input.stokerCadenceRpm / 60.0) * 2.0 * math.pi +
            (input.syncPhase == TandemSyncPhase.synchronized
                ? 0.0
                : input.syncPhase == TandemSyncPhase.marginalDrift
                    ? 0.28
                    : 0.72);
    final double syncDriftDeg =
        ((pilotCrankPhase - stokerCrankPhase).abs() * 180.0 / math.pi) % 180.0;

    // 5. Kolarz 1: Pilot (przód)
    _emitUprightCyclist(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      hipPos: Vector3(pilotSeatCluster.x - 0.03, 0.96, 0.0),
      bbPos: pilotBb,
      handLeft: pilotBarL,
      handRight: pilotBarR,
      crankPhaseRad: pilotCrankPhase,
      jerseyColor: config.pilotJerseyColor,
      helmetColor: isTt ? AppColors.goldAccent : AppColors.textPrimary,
      aeroTuck: isTt,
    );

    // 6. Kolarz 2: Stoker (tył — niewidomy/niedowidzący zawodnik)
    _emitUprightCyclist(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      hipPos: Vector3(stokerSeatCluster.x - 0.03, 0.94, 0.0),
      bbPos: stokerBb,
      handLeft: stokerBarL,
      handRight: stokerBarR,
      crankPhaseRad: stokerCrankPhase,
      jerseyColor: config.stokerJerseyColor,
      helmetColor: isTt ? AppColors.cyanAccent : config.frameAccentColor,
      aeroTuck: isTt || input.speedKmh > 45.0,
    );

    // 7. Strugi aero
    if (config.showAeroStreamlines) {
      _emitAeroStreamlines(
        primitives: primitives,
        camera: camera,
        toWorld: toWorld,
        speedMs: input.speedMs,
        timeSeconds: input.timeSeconds,
        maxHeightM: 1.42,
        lengthSpanM: wb + 0.9,
      );
    }

    return Paracycling3dFrameTelemetry(
      vehicleType: config.vehicleType,
      wheelCount: 2,
      primitiveCount: primitives.length,
      visibleMeshSegments: primitives.length,
      wheelRpm: (wheelOmega * 60.0) / (2.0 * math.pi),
      syncPhaseDriftDeg: syncDriftDeg,
      thermalGlowIntensity: thermalIntensity,
      innerWheelLiftMm: 0.0,
      estimatedCdaM2: isTt ? 0.285 : 0.315,
    );
  }

  // ---------------------------------------------------------------------------
  // RENDERER 3D TRÓJKOŁOWEGO HANDBIKE'A (H1–H5)
  // ---------------------------------------------------------------------------

  Paracycling3dFrameTelemetry _emitHandbikeScene({
    required List<_ProjectedPrimitive> primitives,
    required _CameraTransform camera,
    required Paracycling3dRenderConfig config,
    required Handbike3dRenderInput input,
  }) {
    final bool isKneeling =
        config.vehicleType == Paracycling3dVehicleType.kneelingHandbikeH5 ||
            input.posture == HandbikePostureType.kneeling;
    final slopeRad = math.atan(input.gradientPercent / 100.0);

    const double frontWheelR = 0.32;
    const double rearWheelR = 0.31;
    final double wb = input.wheelbaseM.clamp(1.15, 1.65);
    final double halfTrack = input.rearTrackWidthM.clamp(0.58, 0.88) * 0.5;
    final double camberRad = input.rearWheelCamberDeg * math.pi / 180.0;

    final double frontAxleX = wb * 0.60;
    final double rearAxleX = -wb * 0.40;

    // Przechył na zewnętrznym kole podczas ostrego zakrętu (unoszenie wewnętrznego koła!)
    final double liftRatio = input.innerWheelLiftRatio.clamp(0.0, 1.0);
    final double rollSign = input.steeringAngleRad >= 0 ? 1.0 : -1.0;
    final double chassisRollRad = liftRatio * 0.16 * rollSign;
    final double innerWheelLiftMm = liftRatio * halfTrack * 2.0 * math.sin(0.16) * 1000.0;

    Vector3 toWorld(Vector3 local) {
      // Roll wokół punktu styku zewnętrznego tylnego koła przy unoszeniu
      final pivotZ = rollSign * halfTrack;
      final dz = local.z - pivotZ;
      final cosR = math.cos(chassisRollRad);
      final sinR = math.sin(chassisRollRad);
      final ry = local.y * cosR - dz * sinR;
      final rz = pivotZ + local.y * sinR + dz * cosR;
      final rx = local.x;

      final cosS = math.cos(slopeRad);
      final sinS = math.sin(slopeRad);
      return Vector3(
        rx * cosS - ry * sinS,
        rx * sinS + ry * cosS,
        rz,
      );
    }

    // 1. Cień planarny 3-punktowy na asfalcie
    if (config.showPlanarShadow) {
      final shadowPts = <Offset>[];
      final corners = [
        Vector3(rearAxleX - 0.32, 0.005, -halfTrack - 0.10),
        Vector3(frontAxleX + 0.32, 0.005, -0.14),
        Vector3(frontAxleX + 0.32, 0.005, 0.14),
        Vector3(rearAxleX - 0.32, 0.005, halfTrack + 0.10),
      ];
      double avgD = 0.0;
      for (final c in corners) {
        final proj = camera.project(toWorld(Vector3(c.x, 0.005, c.z)));
        if (proj != null) {
          shadowPts.add(proj.screen);
          avgD += proj.depth;
        }
      }
      if (shadowPts.length == 4) {
        primitives.add(
          _ProjectedPrimitive(
            kind: _PrimitiveKind.polygon,
            depth: avgD * 0.25 + 6.0,
            points: shadowPts,
            color: Colors.black.withValues(alpha: 0.44),
          ),
        );
      }
    }

    // 2. Trzy koła 3D (1 przednie sterowane + 2 tylne z negatywnym pochyleniem camber)
    final double wheelOmega = input.speedMs / frontWheelR;
    final double wheelPhase = input.timeSeconds * wheelOmega;

    // Przednie koło napędowo-skrętne
    _emit3dWheel(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      center: Vector3(frontAxleX, frontWheelR, 0.0),
      radius: frontWheelR,
      spinPhaseRad: wheelPhase,
      steerAngleRad: input.steeringAngleRad,
      camberAngleRad: 0.0,
      isDiscWheel: false,
      deepSection: true,
      rimColor: config.frameAccentColor,
      rotorColor: const Color(0xFF94A3B8),
      thermalIntensity: 0.0,
    );

    // Tylne lewe koło (negative camber)
    _emit3dWheel(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      center: Vector3(rearAxleX, rearWheelR, -halfTrack),
      radius: rearWheelR,
      spinPhaseRad: wheelPhase,
      steerAngleRad: 0.0,
      camberAngleRad: camberRad,
      isDiscWheel: true,
      deepSection: true,
      rimColor: config.frameAccentColor,
      rotorColor: const Color(0xFF94A3B8),
      thermalIntensity: 0.0,
    );

    // Tylne prawe koło (negative camber)
    _emit3dWheel(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      center: Vector3(rearAxleX, rearWheelR, halfTrack),
      radius: rearWheelR,
      spinPhaseRad: wheelPhase,
      steerAngleRad: 0.0,
      camberAngleRad: -camberRad,
      isDiscWheel: true,
      deepSection: true,
      rimColor: config.frameAccentColor,
      rotorColor: const Color(0xFF94A3B8),
      thermalIntensity: 0.0,
    );

    // 3. Rama karbonowa handbike'a (belka główna, tylna oś delta, zderzak draftowy, maszt korby)
    final frameColor = config.framePrimaryColor;
    final accentColor = config.frameAccentColor;

    final Vector3 rearLeftHub = Vector3(rearAxleX, rearWheelR, -halfTrack);
    final Vector3 rearRightHub = Vector3(rearAxleX, rearWheelR, halfTrack);
    final Vector3 rearCenterAxle = Vector3(rearAxleX, rearWheelR, 0.0);
    final Vector3 seatBase = Vector3(rearAxleX + 0.24, isKneeling ? 0.30 : 0.17, 0.0);
    final Vector3 midChassis = Vector3(0.15, isKneeling ? 0.32 : 0.20, 0.0);
    final Vector3 frontHeadTube = Vector3(frontAxleX - 0.14, 0.56, 0.0);
    final Vector3 frontAxle = Vector3(frontAxleX, frontWheelR, 0.0);
    final Vector3 handCrankBb = Vector3(frontAxleX - 0.22, isKneeling ? 0.72 : 0.64, 0.0);

    // Tylna belka i zderzak UCI
    _emitTube(primitives, camera, toWorld, rearLeftHub, rearRightHub, frameColor, 4.2);
    _emitTube(primitives, camera, toWorld, rearLeftHub, seatBase, frameColor, 3.8);
    _emitTube(primitives, camera, toWorld, rearRightHub, seatBase, frameColor, 3.8);
    // Zderzak bezpieczeństwa za tylnymi kołami (obowiązkowy w UCI)
    final Vector3 bumperL = Vector3(rearAxleX - 0.33, rearWheelR, -halfTrack * 0.85);
    final Vector3 bumperR = Vector3(rearAxleX - 0.33, rearWheelR, halfTrack * 0.85);
    _emitTube(primitives, camera, toWorld, rearLeftHub, bumperL, accentColor, 2.6);
    _emitTube(primitives, camera, toWorld, rearRightHub, bumperR, accentColor, 2.6);
    _emitTube(primitives, camera, toWorld, bumperL, bumperR, accentColor, 3.0);

    // Główna rama i przedni widelec + wysięgnik korby ręcznej
    _emitTube(primitives, camera, toWorld, seatBase, midChassis, frameColor, 6.0);
    _emitTube(primitives, camera, toWorld, midChassis, frontHeadTube, frameColor, 5.5);
    _emitTube(
      primitives,
      camera,
      toWorld,
      frontHeadTube,
      Vector3(frontAxle.x, frontAxle.y, -0.06),
      frameColor,
      3.6,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      frontHeadTube,
      Vector3(frontAxle.x, frontAxle.y, 0.06),
      frameColor,
      3.6,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      frontHeadTube,
      handCrankBb,
      accentColor,
      4.2,
    );

    // Podnóżki (dla leżącego) lub platforma pod kolana (dla klęczącego)
    if (!isKneeling) {
      _emitTube(
        primitives,
        camera,
        toWorld,
        midChassis,
        Vector3(frontAxleX - 0.06, 0.25, -0.17),
        accentColor,
        2.8,
      );
      _emitTube(
        primitives,
        camera,
        toWorld,
        midChassis,
        Vector3(frontAxleX - 0.06, 0.25, 0.17),
        accentColor,
        2.8,
      );
    } else {
      // Platforma pod kolana H5
      _emitTube(
        primitives,
        camera,
        toWorld,
        Vector3(rearAxleX + 0.15, 0.24, -0.14),
        Vector3(rearAxleX + 0.45, 0.24, -0.14),
        accentColor,
        3.5,
      );
      _emitTube(
        primitives,
        camera,
        toWorld,
        Vector3(rearAxleX + 0.15, 0.24, 0.14),
        Vector3(rearAxleX + 0.45, 0.24, 0.14),
        accentColor,
        3.5,
      );
    }

    // 4. Synchroniczne korby ręczne (obracają się razem w fazie!)
    final double handCrankPhase =
        input.timeSeconds * (input.handCrankRpm / 60.0) * 2.0 * math.pi;
    const double crankArmLen = 0.17;
    final Vector3 handleL = Vector3(
      handCrankBb.x + crankArmLen * math.cos(handCrankPhase),
      handCrankBb.y + crankArmLen * math.sin(handCrankPhase),
      -0.21,
    );
    final Vector3 handleR = Vector3(
      handCrankBb.x + crankArmLen * math.cos(handCrankPhase),
      handCrankBb.y + crankArmLen * math.sin(handCrankPhase),
      0.21,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      Vector3(handCrankBb.x, handCrankBb.y, -0.16),
      handleL,
      AppColors.textPrimary,
      2.8,
    );
    _emitTube(
      primitives,
      camera,
      toWorld,
      Vector3(handCrankBb.x, handCrankBb.y, 0.16),
      handleR,
      AppColors.textPrimary,
      2.8,
    );

    // 5. Sylwetka zawodnika na handbike'u (H1-H4 leżący vs H5 klęczący)
    _emitHandcyclistPose(
      primitives: primitives,
      camera: camera,
      toWorld: toWorld,
      isKneeling: isKneeling,
      seatBase: seatBase,
      midChassis: midChassis,
      frontAxleX: frontAxleX,
      handleL: handleL,
      handleR: handleR,
      jerseyColor: config.pilotJerseyColor,
      helmetColor: config.frameAccentColor,
    );

    // 6. Chorągiewka bezpieczeństwa UCI na maszcie z tyłu
    final Vector3 flagBase = rearCenterAxle + Vector3(-0.18, 0.08, 0.0);
    final Vector3 flagTop = flagBase + Vector3(-0.04, 0.56, 0.0);
    _emitTube(
      primitives,
      camera,
      toWorld,
      flagBase,
      flagTop,
      AppColors.textSecondary,
      1.8,
    );
    final flutter = math.sin(input.timeSeconds * 11.0) * 0.05;
    final flagTip = flagTop + Vector3(-0.18, -0.04, flutter);
    final flagBot = flagTop + Vector3(0.0, -0.11, 0.0);
    final pFt = camera.project(toWorld(flagTop));
    final pFtip = camera.project(toWorld(flagTip));
    final pFb = camera.project(toWorld(flagBot));
    if (pFt != null && pFtip != null && pFb != null) {
      primitives.add(
        _ProjectedPrimitive(
          kind: _PrimitiveKind.polygon,
          depth: (pFt.depth + pFtip.depth + pFb.depth) / 3.0,
          points: [pFt.screen, pFtip.screen, pFb.screen],
          color: AppColors.amberWarning,
        ),
      );
    }

    // 7. Wektor stabilności poprzecznej w zakręcie
    if (config.showStabilityVectors && input.lateralG > 0.05) {
      final centerMass = Vector3(0.0, isKneeling ? 0.42 : 0.28, 0.0);
      final latVecEnd = centerMass +
          Vector3(0.0, 0.0, -rollSign * input.lateralG.clamp(0.0, 1.2) * 0.55);
      _emitTube(
        primitives,
        camera,
        toWorld,
        centerMass,
        latVecEnd,
        input.stabilityZone.color,
        3.2,
      );
    }

    // 8. Strugi aero
    if (config.showAeroStreamlines) {
      _emitAeroStreamlines(
        primitives: primitives,
        camera: camera,
        toWorld: toWorld,
        speedMs: input.speedMs,
        timeSeconds: input.timeSeconds,
        maxHeightM: isKneeling ? 0.92 : 0.72,
        lengthSpanM: wb + 0.7,
      );
    }

    return Paracycling3dFrameTelemetry(
      vehicleType: config.vehicleType,
      wheelCount: 3,
      primitiveCount: primitives.length,
      visibleMeshSegments: primitives.length,
      wheelRpm: (wheelOmega * 60.0) / (2.0 * math.pi),
      syncPhaseDriftDeg: 0.0,
      thermalGlowIntensity: 0.0,
      innerWheelLiftMm: innerWheelLiftMm,
      estimatedCdaM2: isKneeling ? 0.245 : 0.195,
    );
  }

  // ---------------------------------------------------------------------------
  // ELEMENTY GEOMETRII: KOŁO 3D, RURY RAMY, KOLARZ SZOSOWY, HANDBIKER
  // ---------------------------------------------------------------------------

  void _emitTube(
    List<_ProjectedPrimitive> primitives,
    _CameraTransform camera,
    Vector3 Function(Vector3) toWorld,
    Vector3 aLocal,
    Vector3 bLocal,
    Color color,
    double width,
  ) {
    final pA = camera.project(toWorld(aLocal));
    final pB = camera.project(toWorld(bLocal));
    if (pA == null || pB == null) return;
    primitives.add(
      _ProjectedPrimitive(
        kind: _PrimitiveKind.line,
        depth: (pA.depth + pB.depth) * 0.5,
        points: [pA.screen, pB.screen],
        color: color,
        strokeWidth: width,
      ),
    );
  }

  void _emit3dWheel({
    required List<_ProjectedPrimitive> primitives,
    required _CameraTransform camera,
    required Vector3 Function(Vector3) toWorld,
    required Vector3 center,
    required double radius,
    required double spinPhaseRad,
    required double steerAngleRad,
    required double camberAngleRad,
    required bool isDiscWheel,
    required bool deepSection,
    required Color rimColor,
    required Color rotorColor,
    required double thermalIntensity,
  }) {
    const int segments = 20;
    final cosSteer = math.cos(steerAngleRad);
    final sinSteer = math.sin(steerAngleRad);
    final cosCam = math.cos(camberAngleRad);
    final sinCam = math.sin(camberAngleRad);

    Vector3 wheelPt(double rx, double ry, double rz) {
      // Camber rotation around X
      final cy = ry * cosCam - rz * sinCam;
      final cz = ry * sinCam + rz * cosCam;
      // Steer rotation around Y
      final sx = rx * cosSteer + cz * sinSteer;
      final sz = -rx * sinSteer + cz * cosSteer;
      return center + Vector3(sx, cy, sz);
    }

    final tirePts = <Offset>[];
    final innerRimPts = <Offset>[];
    double depthSum = 0.0;

    final double rimInnerR = deepSection ? radius * 0.78 : radius * 0.88;

    for (int i = 0; i < segments; i++) {
      final a = (i / segments) * 2.0 * math.pi;
      final ca = math.cos(a);
      final sa = math.sin(a);

      final pOuter = camera.project(toWorld(wheelPt(radius * ca, radius * sa, 0)));
      final pInner =
          camera.project(toWorld(wheelPt(rimInnerR * ca, rimInnerR * sa, 0)));
      if (pOuter != null) {
        tirePts.add(pOuter.screen);
        depthSum += pOuter.depth;
      }
      if (pInner != null) {
        innerRimPts.add(pInner.screen);
      }
    }

    if (tirePts.length >= 3) {
      final avgDepth = depthSum / tirePts.length;
      if (isDiscWheel) {
        primitives.add(
          _ProjectedPrimitive(
            kind: _PrimitiveKind.polygon,
            depth: avgDepth + 0.05,
            points: tirePts,
            color: const Color(0xFF1F242E).withValues(alpha: 0.92),
            borderColor: const Color(0xFF101216),
            strokeWidth: 4.5,
          ),
        );
      } else {
        for (int i = 0; i < tirePts.length; i++) {
          final next = (i + 1) % tirePts.length;
          primitives.add(
            _ProjectedPrimitive(
              kind: _PrimitiveKind.line,
              depth: avgDepth,
              points: [tirePts[i], tirePts[next]],
              color: const Color(0xFF111318),
              strokeWidth: 4.8,
            ),
          );
          if (i < innerRimPts.length && next < innerRimPts.length) {
            primitives.add(
              _ProjectedPrimitive(
                kind: _PrimitiveKind.line,
                depth: avgDepth - 0.01,
                points: [innerRimPts[i], innerRimPts[next]],
                color: rimColor.withValues(alpha: 0.85),
                strokeWidth: deepSection ? 3.2 : 1.8,
              ),
            );
          }
        }
      }
    }

    // Szprychy obracające się zgodnie z fazą koła
    if (!isDiscWheel) {
      const int spokeCount = 8;
      for (int s = 0; s < spokeCount; s++) {
        final angle = spinPhaseRad + (s / spokeCount) * 2.0 * math.pi;
        final pHub = camera.project(toWorld(wheelPt(0, 0, 0)));
        final pRim = camera.project(
          toWorld(
            wheelPt(rimInnerR * math.cos(angle), rimInnerR * math.sin(angle), 0),
          ),
        );
        if (pHub != null && pRim != null) {
          primitives.add(
            _ProjectedPrimitive(
              kind: _PrimitiveKind.line,
              depth: (pHub.depth + pRim.depth) * 0.5 + 0.02,
              points: [pHub.screen, pRim.screen],
              color: AppColors.textSecondary.withValues(alpha: 0.48),
              strokeWidth: 1.1,
            ),
          );
        }
      }
    }

    // Piasta i tarcza hamulcowa (z poświatą termiczną przy >110°C)
    final pHubCenter = camera.project(toWorld(wheelPt(0, 0, -0.03)));
    if (pHubCenter != null) {
      final pxPerM = camera.pixelsPerMeterAtDepth(pHubCenter.depth);
      primitives.add(
        _ProjectedPrimitive(
          kind: _PrimitiveKind.circlePoint,
          depth: pHubCenter.depth - 0.03,
          points: [pHubCenter.screen],
          color: rotorColor,
          radius: (0.08 * pxPerM).clamp(3.0, 14.0),
          filled: false,
          strokeWidth: 2.0 + thermalIntensity * 2.5,
        ),
      );
      if (thermalIntensity > 0.25) {
        primitives.add(
          _ProjectedPrimitive(
            kind: _PrimitiveKind.circlePoint,
            depth: pHubCenter.depth - 0.04,
            points: [pHubCenter.screen],
            color: rotorColor.withValues(alpha: thermalIntensity * 0.45),
            radius: (0.11 * pxPerM).clamp(5.0, 22.0),
          ),
        );
      }
    }
  }

  void _emitUprightCyclist({
    required List<_ProjectedPrimitive> primitives,
    required _CameraTransform camera,
    required Vector3 Function(Vector3) toWorld,
    required Vector3 hipPos,
    required Vector3 bbPos,
    required Vector3 handLeft,
    required Vector3 handRight,
    required double crankPhaseRad,
    required Color jerseyColor,
    required Color helmetColor,
    required bool aeroTuck,
  }) {
    final double torsoTiltX = aeroTuck ? 0.36 : 0.28;
    final double torsoUpY = aeroTuck ? 0.25 : 0.34;
    final Vector3 shoulderCenter = hipPos + Vector3(torsoTiltX, torsoUpY, 0.0);
    final Vector3 shoulderL = shoulderCenter + Vector3(0.0, 0.0, -0.17);
    final Vector3 shoulderR = shoulderCenter + Vector3(0.0, 0.0, 0.17);
    final Vector3 headCenter = shoulderCenter + Vector3(0.11, 0.13, 0.0);

    // Tułów (koszulka)
    final pHipL = camera.project(toWorld(hipPos + Vector3(0, 0, -0.11)));
    final pHipR = camera.project(toWorld(hipPos + Vector3(0, 0, 0.11)));
    final pShR = camera.project(toWorld(shoulderR));
    final pShL = camera.project(toWorld(shoulderL));
    if (pHipL != null && pHipR != null && pShR != null && pShL != null) {
      primitives.add(
        _ProjectedPrimitive(
          kind: _PrimitiveKind.polygon,
          depth: (pHipL.depth + pHipR.depth + pShR.depth + pShL.depth) * 0.25,
          points: [pHipL.screen, pHipR.screen, pShR.screen, pShL.screen],
          color: jerseyColor,
          borderColor: Colors.black.withValues(alpha: 0.35),
          strokeWidth: 1.2,
        ),
      );
    }

    // Ramiona do kierownicy
    final Vector3 elbowL =
        (shoulderL + handLeft) * 0.5 + Vector3(0.02, -0.08, -0.02);
    final Vector3 elbowR =
        (shoulderR + handRight) * 0.5 + Vector3(0.02, -0.08, 0.02);
    _emitTube(primitives, camera, toWorld, shoulderL, elbowL, jerseyColor, 4.5);
    _emitTube(
      primitives,
      camera,
      toWorld,
      elbowL,
      handLeft,
      const Color(0xFFD9A689),
      3.8,
    );
    _emitTube(primitives, camera, toWorld, shoulderR, elbowR, jerseyColor, 4.5);
    _emitTube(
      primitives,
      camera,
      toWorld,
      elbowR,
      handRight,
      const Color(0xFFD9A689),
      3.8,
    );

    // Kask 3D (z ogonem aero dla TT)
    final pHead = camera.project(toWorld(headCenter));
    if (pHead != null) {
      final pxPerM = camera.pixelsPerMeterAtDepth(pHead.depth);
      primitives.add(
        _ProjectedPrimitive(
          kind: _PrimitiveKind.circlePoint,
          depth: pHead.depth - 0.02,
          points: [pHead.screen],
          color: helmetColor,
          radius: (0.105 * pxPerM).clamp(5.0, 22.0),
        ),
      );
      if (aeroTuck) {
        _emitTube(
          primitives,
          camera,
          toWorld,
          headCenter,
          headCenter + Vector3(-0.22, 0.02, 0.0),
          helmetColor,
          6.0,
        );
      }
    }

    // Nogi (kinematyka korby 172.5 mm)
    const double crankR = 0.1725;
    for (int side = -1; side <= 1; side += 2) {
      final double phase = crankPhaseRad + (side == 1 ? 0.0 : math.pi);
      final double zOff = side * 0.12;
      final Vector3 pedal = bbPos +
          Vector3(
            crankR * math.cos(phase),
            crankR * math.sin(phase),
            zOff,
          );
      final Vector3 hipSide = hipPos + Vector3(0.0, 0.0, zOff * 0.9);
      final Vector3 knee = (hipSide + pedal) * 0.5 +
          Vector3(0.16, 0.06 + 0.05 * math.sin(phase), 0.0);

      // Ramię korby
      _emitTube(
        primitives,
        camera,
        toWorld,
        bbPos + Vector3(0, 0, zOff * 0.6),
        pedal,
        AppColors.textSecondary,
        2.5,
      );
      // Udo (spodenki)
      _emitTube(
        primitives,
        camera,
        toWorld,
        hipSide,
        knee,
        const Color(0xFF1F242D),
        6.2,
      );
      // Łydka
      _emitTube(
        primitives,
        camera,
        toWorld,
        knee,
        pedal,
        const Color(0xFFD9A689),
        4.6,
      );
    }
  }

  void _emitHandcyclistPose({
    required List<_ProjectedPrimitive> primitives,
    required _CameraTransform camera,
    required Vector3 Function(Vector3) toWorld,
    required bool isKneeling,
    required Vector3 seatBase,
    required Vector3 midChassis,
    required double frontAxleX,
    required Vector3 handleL,
    required Vector3 handleR,
    required Color jerseyColor,
    required Color helmetColor,
  }) {
    late final Vector3 hipCenter;
    late final Vector3 shoulderCenter;
    late final Vector3 headCenter;

    if (!isKneeling) {
      // Pozycja leżąca H1–H4: biodra nisko, plecy pod kątem ~25°, nogi wyciągnięte do przodu
      hipCenter = seatBase + Vector3(0.06, 0.09, 0.0);
      shoulderCenter = seatBase + Vector3(-0.18, 0.36, 0.0);
      headCenter = shoulderCenter + Vector3(0.05, 0.16, 0.0);

      // Nogi na podnóżkach
      for (int side = -1; side <= 1; side += 2) {
        final double z = side * 0.13;
        final Vector3 hipS = hipCenter + Vector3(0, 0, z * 0.75);
        final Vector3 kneeS = midChassis + Vector3(0.18, 0.14, z * 0.9);
        final Vector3 footS = Vector3(frontAxleX - 0.08, 0.27, z * 1.15);
        _emitTube(primitives, camera, toWorld, hipS, kneeS, const Color(0xFF1F242D), 5.6);
        _emitTube(primitives, camera, toWorld, kneeS, footS, const Color(0xFF1F242D), 4.4);
      }
    } else {
      // Pozycja klęcząca H5: biodra nad kolanami, tułów pochylony nad klatką piersiową
      hipCenter = seatBase + Vector3(0.04, 0.24, 0.0);
      shoulderCenter = hipCenter + Vector3(0.32, 0.20, 0.0);
      headCenter = shoulderCenter + Vector3(0.11, 0.12, 0.0);

      for (int side = -1; side <= 1; side += 2) {
        final double z = side * 0.12;
        final Vector3 hipS = hipCenter + Vector3(0, 0, z * 0.8);
        final Vector3 kneeS = Vector3(seatBase.x + 0.18, 0.26, z);
        final Vector3 ankleS = Vector3(seatBase.x - 0.08, 0.26, z);
        _emitTube(primitives, camera, toWorld, hipS, kneeS, const Color(0xFF1F242D), 5.8);
        _emitTube(primitives, camera, toWorld, kneeS, ankleS, const Color(0xFF1F242D), 4.4);
      }
    }

    final Vector3 shoulderL = shoulderCenter + Vector3(0, 0, -0.17);
    final Vector3 shoulderR = shoulderCenter + Vector3(0, 0, 0.17);

    // Tułów
    final pHipL = camera.project(toWorld(hipCenter + Vector3(0, 0, -0.12)));
    final pHipR = camera.project(toWorld(hipCenter + Vector3(0, 0, 0.12)));
    final pShR = camera.project(toWorld(shoulderR));
    final pShL = camera.project(toWorld(shoulderL));
    if (pHipL != null && pHipR != null && pShR != null && pShL != null) {
      primitives.add(
        _ProjectedPrimitive(
          kind: _PrimitiveKind.polygon,
          depth: (pHipL.depth + pHipR.depth + pShR.depth + pShL.depth) * 0.25,
          points: [pHipL.screen, pHipR.screen, pShR.screen, pShL.screen],
          color: jerseyColor,
          borderColor: Colors.black.withValues(alpha: 0.35),
          strokeWidth: 1.2,
        ),
      );
    }

    // Ręce napędzające korbę ręczną
    final Vector3 elbowL = (shoulderL + handleL) * 0.5 + Vector3(0.0, -0.07, -0.03);
    final Vector3 elbowR = (shoulderR + handleR) * 0.5 + Vector3(0.0, -0.07, 0.03);
    _emitTube(primitives, camera, toWorld, shoulderL, elbowL, jerseyColor, 4.6);
    _emitTube(primitives, camera, toWorld, elbowL, handleL, const Color(0xFFD9A689), 3.9);
    _emitTube(primitives, camera, toWorld, shoulderR, elbowR, jerseyColor, 4.6);
    _emitTube(primitives, camera, toWorld, elbowR, handleR, const Color(0xFFD9A689), 3.9);

    // Kask
    final pHead = camera.project(toWorld(headCenter));
    if (pHead != null) {
      final pxPerM = camera.pixelsPerMeterAtDepth(pHead.depth);
      primitives.add(
        _ProjectedPrimitive(
          kind: _PrimitiveKind.circlePoint,
          depth: pHead.depth - 0.02,
          points: [pHead.screen],
          color: helmetColor,
          radius: (0.10 * pxPerM).clamp(5.0, 20.0),
        ),
      );
    }
  }
}

// =============================================================================
// 5. CUSTOM PAINTER SCENY 3D
// =============================================================================

/// CustomPainter rysujący tło atmosferyczne i siatkę 3D tandemu / handbike'a.
class TandemAndHandbike3dPainter extends CustomPainter {
  final Paracycling3dRenderConfig config;
  final Tandem3dRenderInput tandemInput;
  final Handbike3dRenderInput handbikeInput;
  final TandemAndHandbike3dMeshRenderer renderer;
  final ValueChanged<Paracycling3dFrameTelemetry>? onTelemetryUpdated;

  const TandemAndHandbike3dPainter({
    required this.config,
    required this.tandemInput,
    required this.handbikeInput,
    this.renderer = const TandemAndHandbike3dMeshRenderer(),
    this.onTelemetryUpdated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ciemne tło studyjno-szosowe w palecie AppColors
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0D12),
          AppColors.background,
          Color(0xFF151922),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Subtelna poświata studyjna za pojazdem
    final glowColor = config.vehicleType.isTandem
        ? AppColors.primaryAccent.withValues(alpha: 0.14)
        : AppColors.accentBlue.withValues(alpha: 0.12);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.12),
        radius: 0.65,
        colors: [glowColor, Colors.transparent],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, glowPaint);

    // 2. Renderowanie siatki 3D
    final telemetry = renderer.renderFrame(
      canvas: canvas,
      size: size,
      config: config,
      tandemInput: tandemInput,
      handbikeInput: handbikeInput,
    );

    if (onTelemetryUpdated != null) {
      onTelemetryUpdated!(telemetry);
    }
  }

  @override
  bool shouldRepaint(covariant TandemAndHandbike3dPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.tandemInput.timeSeconds != tandemInput.timeSeconds ||
        oldDelegate.tandemInput.speedMs != tandemInput.speedMs ||
        oldDelegate.tandemInput.gradientPercent != tandemInput.gradientPercent ||
        oldDelegate.tandemInput.rotorTempCelsius !=
            tandemInput.rotorTempCelsius ||
        oldDelegate.tandemInput.syncPhase != tandemInput.syncPhase ||
        oldDelegate.handbikeInput.timeSeconds != handbikeInput.timeSeconds ||
        oldDelegate.handbikeInput.speedMs != handbikeInput.speedMs ||
        oldDelegate.handbikeInput.gradientPercent !=
            handbikeInput.gradientPercent ||
        oldDelegate.handbikeInput.innerWheelLiftRatio !=
            handbikeInput.innerWheelLiftRatio;
  }
}

// =============================================================================
// 6. INTERAKTYWNY WIDŻET VIEWPORTU I PANELU STEROWANIA (RESPONSIVE 390/1024/1600)
// =============================================================================

/// Produkcyjny, responsywny viewport 3D z pełnym sterowaniem kamery, fizyki i telemetrii
/// dla dwuosobowych tandemów Klasy B oraz trójkołowych handbike'ów H1–H5.
class TandemAndHandbike3dMeshViewport extends StatefulWidget {
  final Paracycling3dRenderConfig initialConfig;
  final Tandem3dRenderInput initialTandemInput;
  final Handbike3dRenderInput initialHandbikeInput;
  final bool autoAnimate;

  const TandemAndHandbike3dMeshViewport({
    super.key,
    this.initialConfig = const Paracycling3dRenderConfig(),
    this.initialTandemInput = const Tandem3dRenderInput(),
    this.initialHandbikeInput = const Handbike3dRenderInput(),
    this.autoAnimate = true,
  });

  @override
  State<TandemAndHandbike3dMeshViewport> createState() =>
      _TandemAndHandbike3dMeshViewportState();
}

class _TandemAndHandbike3dMeshViewportState
    extends State<TandemAndHandbike3dMeshViewport>
    with SingleTickerProviderStateMixin {
  late Paracycling3dRenderConfig _config;
  late Tandem3dRenderInput _tandemInput;
  late Handbike3dRenderInput _handbikeInput;
  late Ticker _ticker;

  double _elapsedSeconds = 0.0;
  Duration _lastTick = Duration.zero;
  bool _isPlaying = true;

  Paracycling3dFrameTelemetry _latestTelemetry =
      const Paracycling3dFrameTelemetry(
    vehicleType: Paracycling3dVehicleType.tandemRoadB,
    wheelCount: 2,
    primitiveCount: 0,
    visibleMeshSegments: 0,
    wheelRpm: 0,
    syncPhaseDriftDeg: 0,
    thermalGlowIntensity: 0,
    innerWheelLiftMm: 0,
    estimatedCdaM2: 0.315,
  );

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _tandemInput = widget.initialTandemInput;
    _handbikeInput = widget.initialHandbikeInput;
    _isPlaying = widget.autoAnimate;

    _ticker = createTicker((elapsed) {
      if (!_isPlaying) {
        _lastTick = elapsed;
        return;
      }
      final dt = (_lastTick == Duration.zero)
          ? 0.016
          : ((elapsed - _lastTick).inMicroseconds / 1000000.0)
              .clamp(0.001, 0.05);
      _lastTick = elapsed;
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += dt;
        _tandemInput = _tandemInput.copyWith(timeSeconds: _elapsedSeconds);
        _handbikeInput = _handbikeInput.copyWith(timeSeconds: _elapsedSeconds);
      });
    });

    if (_isPlaying) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying && !_ticker.isActive) {
        _lastTick = Duration.zero;
        _ticker.start();
      } else if (!_isPlaying && _ticker.isActive) {
        _ticker.stop();
      }
    });
  }

  void _resetCameraOrbit() {
    setState(() {
      _config = _config.copyWith(
        cameraOrbitYawOffsetRad: 0.0,
        cameraOrbitPitchOffsetRad: 0.0,
        cameraZoomFactor: 1.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktopWide = constraints.maxWidth >= 980;
          final bool isCompactMobile = constraints.maxWidth < 600;

          if (isDesktopWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: _buildViewportCanvas(isCompactMobile: false),
                ),
                Container(width: 1, color: AppColors.cardBorder),
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: _buildControlSidebar(isCompact: false),
                  ),
                ),
              ],
            );
          }

          final double viewportHeight = isCompactMobile
              ? (constraints.maxHeight.isFinite
                  ? (constraints.maxHeight * 0.48).clamp(220.0, 340.0)
                  : 270.0)
              : (constraints.maxHeight.isFinite
                  ? (constraints.maxHeight * 0.54).clamp(260.0, 420.0)
                  : 320.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: viewportHeight,
                child: _buildViewportCanvas(isCompactMobile: isCompactMobile),
              ),
              Container(height: 1, color: AppColors.cardBorder),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isCompactMobile ? 10 : 14),
                  child: _buildControlSidebar(isCompact: isCompactMobile),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewportCanvas({required bool isCompactMobile}) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _config = _config.copyWith(
            cameraOrbitYawOffsetRad:
                _config.cameraOrbitYawOffsetRad + details.delta.dx * 0.008,
            cameraOrbitPitchOffsetRad: (_config.cameraOrbitPitchOffsetRad +
                    details.delta.dy * 0.006)
                .clamp(-0.35, 0.95),
          );
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: TandemAndHandbike3dPainter(
              config: _config,
              tandemInput: _tandemInput,
              handbikeInput: _handbikeInput,
              onTelemetryUpdated: (t) {
                _latestTelemetry = t;
              },
            ),
            child: const SizedBox.expand(),
          ),
          // Górny pasek informacyjny pojazdu
          Positioned(
            top: isCompactMobile ? 8 : 12,
            left: isCompactMobile ? 8 : 12,
            right: isCompactMobile ? 8 : 12,
            child: Row(
              children: [
                _StatusBadgePill(
                  label: _config.vehicleType.shortTag,
                  accentColor: _config.vehicleType.isTandem
                      ? AppColors.goldAccent
                      : AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                _StatusBadgePill(
                  label: '${_config.vehicleType.wheelCount} KOŁA',
                  accentColor: AppColors.statusSuccess,
                ),
                const Spacer(),
                _InteractiveIconButton(
                  tooltip: _isPlaying ? 'Pauza animacji' : 'Wznów animację',
                  icon: _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  isActive: _isPlaying,
                  onTap: _togglePlayPause,
                ),
                const SizedBox(width: 6),
                _InteractiveIconButton(
                  tooltip: 'Resetuj kamerę 3D',
                  icon: Icons.center_focus_strong_rounded,
                  isActive: false,
                  onTap: _resetCameraOrbit,
                ),
              ],
            ),
          ),
          // Dolna nakładka telemetrii 3D
          if (_config.showTelemetryOverlay)
            Positioned(
              left: isCompactMobile ? 8 : 12,
              right: isCompactMobile ? 8 : 12,
              bottom: isCompactMobile ? 8 : 12,
              child: _buildTelemetryOverlayBar(isCompact: isCompactMobile),
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryOverlayBar({required bool isCompact}) {
    final bool isTandem = _config.vehicleType.isTandem;
    final double speedKmh =
        isTandem ? _tandemInput.speedKmh : _handbikeInput.speedKmh;
    final double powerW =
        isTandem ? _tandemInput.totalWatts : _handbikeInput.watts;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Wrap(
        spacing: isCompact ? 10 : 18,
        runSpacing: 4,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _TelemetryMetricText(
            label: 'PRĘDKOŚĆ',
            value: '${speedKmh.toStringAsFixed(1)} km/h',
            color: AppColors.textPrimary,
          ),
          _TelemetryMetricText(
            label: 'MOC',
            value: '${powerW.toStringAsFixed(0)} W',
            color: AppColors.goldAccent,
          ),
          _TelemetryMetricText(
            label: 'CdA',
            value: '${_latestTelemetry.estimatedCdaM2.toStringAsFixed(3)} m²',
            color: AppColors.accentBlue,
          ),
          if (isTandem)
            _TelemetryMetricText(
              label: 'TARCZE',
              value: '${_tandemInput.rotorTempCelsius.toStringAsFixed(0)} °C',
              color: _tandemInput.thermalStatus.color,
            )
          else
            _TelemetryMetricText(
              label: 'UNIESIENIE KOŁA',
              value:
                  '${_latestTelemetry.innerWheelLiftMm.toStringAsFixed(0)} mm',
              color: _handbikeInput.stabilityZone.color,
            ),
        ],
      ),
    );
  }

  Widget _buildControlSidebar({required bool isCompact}) {
    final bool isTandem = _config.vehicleType.isTandem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'TYPY POJAZDÓW UCI PARA-CYCLING',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: Paracycling3dVehicleType.values.map((vType) {
            final selected = _config.vehicleType == vType;
            return _InteractiveFilterChip(
              label: vType.shortTag,
              selected: selected,
              accentColor: vType.isTandem
                  ? AppColors.goldAccent
                  : AppColors.accentBlue,
              onTap: () {
                setState(() {
                  _config = _config.copyWith(vehicleType: vType);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        const Text(
          'KAMERA 3D',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: Paracycling3dCameraPreset.values.map((cam) {
            return _InteractiveFilterChip(
              label: cam.labelPl,
              selected: _config.cameraPreset == cam,
              accentColor: AppColors.primaryAccent,
              onTap: () {
                setState(() {
                  _config = _config.copyWith(
                    cameraPreset: cam,
                    cameraOrbitYawOffsetRad: 0.0,
                    cameraOrbitPitchOffsetRad: 0.0,
                  );
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        // Suwaki fizyki i kinematyki
        _LabeledSliderControl(
          label: 'Prędkość jazdy',
          valueText: isTandem
              ? '${_tandemInput.speedKmh.toStringAsFixed(0)} km/h'
              : '${_handbikeInput.speedKmh.toStringAsFixed(0)} km/h',
          value: isTandem ? _tandemInput.speedKmh : _handbikeInput.speedKmh,
          min: 18.0,
          max: isTandem ? 105.0 : 65.0,
          accentColor: AppColors.accentBlue,
          onChanged: (val) {
            setState(() {
              final ms = val / 3.6;
              if (isTandem) {
                _tandemInput = _tandemInput.copyWith(speedMs: ms);
              } else {
                _handbikeInput = _handbikeInput.copyWith(speedMs: ms);
              }
            });
          },
        ),
        _LabeledSliderControl(
          label: 'Nachylenie trasy',
          valueText: isTandem
              ? '${_tandemInput.gradientPercent.toStringAsFixed(1)}%'
              : '${_handbikeInput.gradientPercent.toStringAsFixed(1)}%',
          value: isTandem
              ? _tandemInput.gradientPercent
              : _handbikeInput.gradientPercent,
          min: -12.0,
          max: 14.0,
          accentColor: AppColors.goldAccent,
          onChanged: (val) {
            setState(() {
              if (isTandem) {
                _tandemInput = _tandemInput.copyWith(gradientPercent: val);
              } else {
                _handbikeInput = _handbikeInput.copyWith(gradientPercent: val);
              }
            });
          },
        ),
        if (isTandem) ...[
          _LabeledSliderControl(
            label: 'Temperatura tarcz hamulcowych',
            valueText: '${_tandemInput.rotorTempCelsius.toStringAsFixed(0)} °C',
            value: _tandemInput.rotorTempCelsius,
            min: 40.0,
            max: 320.0,
            accentColor: _tandemInput.thermalStatus.color,
            onChanged: (val) {
              final status = val >= 260
                  ? DescentThermalBrakeStatus.thermalFade
                  : val >= 200
                      ? DescentThermalBrakeStatus.fadeWarning
                      : val >= 130
                          ? DescentThermalBrakeStatus.warm
                          : DescentThermalBrakeStatus.nominal;
              setState(() {
                _tandemInput = _tandemInput.copyWith(
                  rotorTempCelsius: val,
                  thermalStatus: status,
                );
              });
            },
          ),
        ] else ...[
          _LabeledSliderControl(
            label: 'Przeciążenie w zakręcie (Lateral G)',
            valueText: '${_handbikeInput.lateralG.toStringAsFixed(2)} G',
            value: _handbikeInput.lateralG,
            min: 0.0,
            max: 0.95,
            accentColor: _handbikeInput.stabilityZone.color,
            onChanged: (val) {
              final lift = ((val - 0.48) / 0.42).clamp(0.0, 1.0);
              final zone = val >= 0.78
                  ? HandbikeTurnStabilityZone.tipOverCritical
                  : val >= 0.48
                      ? HandbikeTurnStabilityZone.innerWheelLiftRisk
                      : HandbikeTurnStabilityZone.planted;
              setState(() {
                _handbikeInput = _handbikeInput.copyWith(
                  lateralG: val,
                  innerWheelLiftRatio: lift,
                  stabilityZone: zone,
                  steeringAngleRad: val * 0.38,
                );
              });
            },
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _InteractiveFilterChip(
              label: 'Strugi Aero',
              selected: _config.showAeroStreamlines,
              accentColor: AppColors.cyanAccent,
              onTap: () {
                setState(() {
                  _config = _config.copyWith(
                    showAeroStreamlines: !_config.showAeroStreamlines,
                  );
                });
              },
            ),
            _InteractiveFilterChip(
              label: 'Cień 3D',
              selected: _config.showPlanarShadow,
              accentColor: AppColors.statusSuccess,
              onTap: () {
                setState(() {
                  _config = _config.copyWith(
                    showPlanarShadow: !_config.showPlanarShadow,
                  );
                });
              },
            ),
            _InteractiveFilterChip(
              label: 'Telemetria',
              selected: _config.showTelemetryOverlay,
              accentColor: AppColors.goldAccent,
              onTap: () {
                setState(() {
                  _config = _config.copyWith(
                    showTelemetryOverlay: !_config.showTelemetryOverlay,
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

// =============================================================================
// 7. POMOCNICZE KOMPONENTY UI ZE STANAMI HOVER / ACTIVE / FOCUS / DISABLED
// =============================================================================

class _StatusBadgePill extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _StatusBadgePill({
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: accentColor,
        ),
      ),
    );
  }
}

class _TelemetryMetricText extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TelemetryMetricText({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null;
    final Color bg = disabled
        ? AppColors.surface.withValues(alpha: 0.4)
        : widget.selected
            ? widget.accentColor.withValues(alpha: _hovered ? 0.28 : 0.20)
            : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final Color border = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? widget.accentColor
            : (_hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: _focused ? 1.5 : 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : (widget.selected
                        ? widget.accentColor
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _InteractiveIconButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !disabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: disabled ? null : () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppColors.primaryAccent.withValues(alpha: 0.35)
                    : (_hovered ? AppColors.surfaceLight : AppColors.surface)
                        .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : (widget.isActive
                          ? AppColors.primaryAccent
                          : AppColors.cardBorder),
                  width: 1.0,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledSliderControl extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _LabeledSliderControl({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.18),
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
