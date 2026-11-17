// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/real_time_cfd_vortex_and_drag_solver.dart';

/// Tryb mapy cieplnej CFD renderowanej na sylwetce kolarza w tunelu aero.
enum CfdHeatmapLayerMode {
  pressureCp('Pressure Cp', 'Ciśnienie Cp', 'Cp'),
  velocityField('Airflow Velocity', 'Prędkość strugi', 'm/s'),
  vorticityShear('Wake Turbulence', 'Turbulencja śladu', '%'),
  dragPowerShare('Drag Power', 'Moc oporu', 'W');

  final String labelEn;
  final String labelPl;
  final String unit;

  const CfdHeatmapLayerMode(this.labelEn, this.labelPl, this.unit);
}

/// Preset kamery 3D w komorze tunelu aerodynamicznego.
enum CfdCameraOrbitPreset {
  sideProfile('Side 90°', 0.0, 6.0, 1.0),
  threeQuarterFront('3/4 Front', -34.0, 14.0, 1.05),
  topDownYaw('Top Yaw', -12.0, 68.0, 0.95),
  rearWake('Rear Wake', 152.0, 16.0, 1.02);

  final String label;
  final double yawDeg;
  final double pitchDeg;
  final double zoom;

  const CfdCameraOrbitPreset(this.label, this.yawDeg, this.pitchDeg, this.zoom);
}

/// Wynik rzutowania punktu 3D na płaszczyznę 2D ekranu z głębią Z.
class CfdProjectedPoint3d {
  final Offset offset;
  final double depth;
  final double scale;

  const CfdProjectedPoint3d({
    required this.offset,
    required this.depth,
    required this.scale,
  });
}

/// Odczyt sondy CFD pod kursorem / fokusem na sylwetce lub w śladzie aerodynamicznym.
class CfdHeatmapProbeReading {
  final CfdAeroZone? zone;
  final String regionLabel;
  final double pressureCp;
  final double localVelocityMs;
  final double turbulencePercent;
  final double dragWatts;
  final CfdFlowRegime flowRegime;
  final Offset screenPosition;

  const CfdHeatmapProbeReading({
    required this.zone,
    required this.regionLabel,
    required this.pressureCp,
    required this.localVelocityMs,
    required this.turbulencePercent,
    required this.dragWatts,
    required this.flowRegime,
    required this.screenPosition,
  });
}

/// Region trafienia 2D powiązany ze strefą aerodynamiczną CFD do inspekcji hover/tap.
class CfdProjectedZoneHitbox {
  final CfdAeroZone zone;
  final Offset center;
  final double radius;
  final CfdZoneBreakdown breakdown;

  const CfdProjectedZoneHitbox({
    required this.zone,
    required this.center,
    required this.radius,
    required this.breakdown,
  });
}

/// Kalkulator rzutowania 3D, mapy barwnej CFD oraz geometrii strug dla 120 FPS CustomPaintera.
class CfdWindTunnelHeatmapCalculator {
  CfdWindTunnelHeatmapCalculator._();

  /// Rzutuje punkt w przestrzeni tunelu (X: przód-tył [m], Y: góra-dół [m], Z: lewo-prawo [m])
  /// na współrzędne 2D płótna z perspektywą.
  static CfdProjectedPoint3d projectPoint3d({
    required double x,
    required double y,
    required double z,
    required Size canvasSize,
    required double cameraYawDeg,
    required double cameraPitchDeg,
    required double zoom,
  }) {
    final double yawRad = cameraYawDeg * math.pi / 180.0;
    final double pitchRad = cameraPitchDeg * math.pi / 180.0;

    final double cosY = math.cos(yawRad);
    final double sinY = math.sin(yawRad);
    final double x1 = x * cosY - z * sinY;
    final double z1 = x * sinY + z * cosY;

    final double cosP = math.cos(pitchRad);
    final double sinP = math.sin(pitchRad);
    final double y2 = y * cosP - z1 * sinP;
    final double z2 = y * sinP + z1 * cosP;

    const double cameraDistance = 4.8;
    final double denom = math.max(1.2, cameraDistance + z2);
    final double persp = cameraDistance / denom;
    final double baseScale = math.min(canvasSize.width, canvasSize.height) * 0.34 * zoom;
    final double finalScale = baseScale * persp;

    final double cx = canvasSize.width * 0.47;
    final double cy = canvasSize.height * 0.66;

    return CfdProjectedPoint3d(
      offset: Offset(cx + x1 * finalScale, cy - y2 * finalScale),
      depth: denom,
      scale: finalScale,
    );
  }

  /// Mapuje znormalizowaną intensywność [0.0..1.0] na naukową skalę barwną CFD
  /// zharmonizowaną z paletą `AppColors`.
  static Color heatmapColorForNormalized(
    double t, {
    CfdHeatmapLayerMode mode = CfdHeatmapLayerMode.pressureCp,
  }) {
    final double clamped = t.clamp(0.0, 1.0);
    final List<Color> stops;
    switch (mode) {
      case CfdHeatmapLayerMode.pressureCp:
        stops = const <Color>[
          Color(0xFF1D4ED8), // Niskie podciśnienie (suction)
          AppColors.accentBlue,
          AppColors.cyanAccent,
          AppColors.statusSuccess,
          AppColors.amberWarning,
          AppColors.crimsonAlert, // Stagnacja czołowa (wysokie Cp)
        ];
      case CfdHeatmapLayerMode.velocityField:
        stops = const <Color>[
          Color(0xFF312E81), // Strefa martwa śladu
          AppColors.accentBlue,
          AppColors.cyanAccent,
          AppColors.statusSuccess,
          AppColors.goldAccent, // Maksymalne przyspieszenie strugi
        ];
      case CfdHeatmapLayerMode.vorticityShear:
        stops = const <Color>[
          Color(0xFF0F172A),
          AppColors.accentBlue,
          AppColors.powerZone7, // Wirowość
          AppColors.amberWarning,
          AppColors.crimsonAlert,
        ];
      case CfdHeatmapLayerMode.dragPowerShare:
        stops = const <Color>[
          AppColors.statusSuccess,
          AppColors.cyanAccent,
          AppColors.goldAccent,
          AppColors.amberWarning,
          AppColors.crimsonAlert,
        ];
    }

    final double scaled = clamped * (stops.length - 1);
    final int idx = scaled.floor().clamp(0, stops.length - 2);
    final double frac = scaled - idx;
    return Color.lerp(stops[idx], stops[idx + 1], frac) ?? stops.last;
  }

  /// Wyznacza znormalizowaną wartość [0..1] dla danej strefy CFD w wybranym trybie warstwy.
  static double normalizedMetricForZone({
    required CfdZoneBreakdown breakdown,
    required CfdSolverResult solverResult,
    required CfdHeatmapLayerMode mode,
  }) {
    switch (mode) {
      case CfdHeatmapLayerMode.pressureCp:
        return (breakdown.pressureCoefficientCp / 1.15).clamp(0.08, 1.0);
      case CfdHeatmapLayerMode.velocityField:
        final double accelFactor = (1.18 - breakdown.localCd * 0.35).clamp(0.15, 1.0);
        return accelFactor;
      case CfdHeatmapLayerMode.vorticityShear:
        final double regimeBias = switch (breakdown.flowRegime) {
          CfdFlowRegime.laminarAttached => 0.14,
          CfdFlowRegime.transitionalDragCrisis => 0.36,
          CfdFlowRegime.turbulentAttached => 0.56,
          CfdFlowRegime.separatedWake => 0.80,
          CfdFlowRegime.karmanVortexShedding => 0.96,
        };
        final double freqFactor = (breakdown.karmanFrequencyHz / 65.0).clamp(0.0, 0.25);
        return (regimeBias * 0.82 + freqFactor).clamp(0.08, 1.0);
      case CfdHeatmapLayerMode.dragPowerShare:
        return (breakdown.shareOfTotalDrag / 0.42).clamp(0.08, 1.0);
    }
  }

  /// Wyznacza pozycję 3D środka strefy na sylwetce kolarza (X przód +, Y góra +, Z prawo +).
  static ({double x, double y, double z, double hitRadiusMeters}) zoneAnchor3d({
    required CfdAeroZone zone,
    required CfdSolverInput input,
  }) {
    final double tuck = input.headTuckFactor.clamp(0.0, 1.0);
    final bool isTt = input.forearmPosture == CfdForearmPosture.ttAeroBars ||
        input.forearmPosture == CfdForearmPosture.highHandsMantis;
    final double torsoDrop = isTt ? 0.14 : (tuck * 0.08);

    switch (zone) {
      case CfdAeroZone.helmet:
        return (
          x: isTt ? 0.42 : 0.34,
          y: 1.24 - torsoDrop - tuck * 0.11,
          z: 0.0,
          hitRadiusMeters: 0.22,
        );
      case CfdAeroZone.forearms:
        return (
          x: isTt ? 0.60 : 0.48,
          y: 1.02 - torsoDrop * 0.7,
          z: 0.0,
          hitRadiusMeters: 0.22,
        );
      case CfdAeroZone.textiles:
        return (
          x: 0.05,
          y: 1.14 - torsoDrop * 0.65,
          z: 0.0,
          hitRadiusMeters: 0.30,
        );
      case CfdAeroZone.wheels:
        return (
          x: 0.56,
          y: 0.35,
          z: 0.0,
          hitRadiusMeters: 0.34,
        );
      case CfdAeroZone.frameAndCockpit:
        return (
          x: 0.14,
          y: 0.64,
          z: 0.0,
          hitRadiusMeters: 0.25,
        );
      case CfdAeroZone.legsAndDrivetrain:
        return (
          x: -0.08,
          y: 0.56,
          z: 0.0,
          hitRadiusMeters: 0.28,
        );
    }
  }

  /// Tworzy listę strefowych hitboxów 2D dla interakcji myszy i dotyku.
  static List<CfdProjectedZoneHitbox> buildProjectedZoneHitboxes({
    required Size canvasSize,
    required CfdSolverInput input,
    required CfdSolverResult solverResult,
    required double cameraYawDeg,
    required double cameraPitchDeg,
    required double zoom,
  }) {
    final List<CfdProjectedZoneHitbox> hitboxes = <CfdProjectedZoneHitbox>[];
    for (final CfdZoneBreakdown breakdown in solverResult.zones) {
      final anchor = zoneAnchor3d(zone: breakdown.zone, input: input);
      final CfdProjectedPoint3d proj = projectPoint3d(
        x: anchor.x,
        y: anchor.y,
        z: anchor.z,
        canvasSize: canvasSize,
        cameraYawDeg: cameraYawDeg,
        cameraPitchDeg: cameraPitchDeg,
        zoom: zoom,
      );
      hitboxes.add(
        CfdProjectedZoneHitbox(
          zone: breakdown.zone,
          center: proj.offset,
          radius: (anchor.hitRadiusMeters * proj.scale).clamp(18.0, 90.0),
          breakdown: breakdown,
        ),
      );
    }
    return hitboxes;
  }

  /// Wyszukuje strefę CFD pod pozycją wskaźnika oraz generuje odczyt sondy telemetrycznej.
  static CfdHeatmapProbeReading? hitTestProbe({
    required Offset position,
    required List<CfdProjectedZoneHitbox> hitboxes,
    required CfdSolverResult solverResult,
    required CfdHeatmapLayerMode mode,
  }) {
    CfdProjectedZoneHitbox? best;
    double bestDist = double.infinity;
    for (final CfdProjectedZoneHitbox box in hitboxes) {
      final double d = (position - box.center).distance;
      if (d <= box.radius && d < bestDist) {
        bestDist = d;
        best = box;
      }
    }
    if (best == null) return null;

    final CfdZoneBreakdown b = best.breakdown;
    final double localVel = solverResult.apparentWindSpeedMs *
        (1.16 - b.localCd * 0.34).clamp(0.42, 1.25);
    final double turbPct = normalizedMetricForZone(
          breakdown: b,
          solverResult: solverResult,
          mode: CfdHeatmapLayerMode.vorticityShear,
        ) *
        100.0;

    return CfdHeatmapProbeReading(
      zone: b.zone,
      regionLabel: b.zone.labelPl,
      pressureCp: b.pressureCoefficientCp,
      localVelocityMs: localVel,
      turbulencePercent: turbPct,
      dragWatts: b.aeroPowerWatts,
      flowRegime: b.flowRegime,
      screenPosition: best.center,
    );
  }
}

/// Natywny painter 120 FPS wizualizujący mapę ciśnień CFD, strugi powietrza,
/// ścieżkę wirów Kármána oraz obrotową platformę tunelu aerodynamicznego.
class CfdWindTunnelHeatmap3dPainter extends CustomPainter {
  final CfdSolverInput input;
  final CfdSolverResult solverResult;
  final double animationPhase;
  final double timeSeconds;
  final CfdHeatmapLayerMode layerMode;
  final double cameraYawDeg;
  final double cameraPitchDeg;
  final double zoom;
  final CfdAeroZone? hoveredZone;
  final CfdAeroZone? selectedZone;
  final bool showStreamlines;
  final bool showKarmanVortices;
  final bool showTurntable;
  final bool isDisabled;

  CfdWindTunnelHeatmap3dPainter({
    required this.input,
    required this.solverResult,
    required this.animationPhase,
    required this.timeSeconds,
    this.layerMode = CfdHeatmapLayerMode.pressureCp,
    this.cameraYawDeg = 0.0,
    this.cameraPitchDeg = 8.0,
    this.zoom = 1.0,
    this.hoveredZone,
    this.selectedZone,
    this.showStreamlines = true,
    this.showKarmanVortices = true,
    this.showTurntable = true,
    this.isDisabled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 4 || size.height <= 4) return;

    final Rect bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(bounds);

    _paintChamberBackdrop(canvas, size, bounds);
    if (showTurntable) {
      _paintTurntableFloor(canvas, size);
    }
    if (showKarmanVortices) {
      _paintKarmanVortexWake(canvas, size);
    }
    if (showStreamlines) {
      _paintAirflowStreamlines(canvas, size, foreground: false);
    }

    _paintCyclistAndBike3dHeatmap(canvas, size);

    if (showStreamlines) {
      _paintAirflowStreamlines(canvas, size, foreground: true);
    }

    _paintZoneHighlightRing(canvas, size);

    if (isDisabled) {
      canvas.drawRect(
        bounds,
        Paint()..color = AppColors.background.withValues(alpha: 0.45),
      );
    }

    canvas.restore();
  }

  void _paintChamberBackdrop(Canvas canvas, Size size, Rect bounds) {
    final Paint bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.15),
        radius: 1.05,
        colors: <Color>[
          Color(0xFF1A202E),
          AppColors.surface,
          AppColors.background,
        ],
        stops: <double>[0.0, 0.55, 1.0],
      ).createShader(bounds);
    canvas.drawRect(bounds, bgPaint);

    // Delikatna siatka pomiarowa komory tunelu
    final Paint gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.28)
      ..strokeWidth = 1.0;

    final double step = math.max(28.0, size.width / 16.0);
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _paintTurntableFloor(Canvas canvas, Size size) {
    final double yawTurnRad = solverResult.yawAngleDegrees * math.pi / 180.0;
    final double totalYaw = cameraYawDeg + solverResult.yawAngleDegrees;

    final List<Offset> ringPts = <Offset>[];
    const int segments = 40;
    const double radiusM = 1.38;
    for (int i = 0; i <= segments; i++) {
      final double a = (i / segments) * math.pi * 2.0;
      final CfdProjectedPoint3d p = CfdWindTunnelHeatmapCalculator.projectPoint3d(
        x: math.cos(a) * radiusM,
        y: 0.0,
        z: math.sin(a) * radiusM,
        canvasSize: size,
        cameraYawDeg: totalYaw,
        cameraPitchDeg: cameraPitchDeg,
        zoom: zoom,
      );
      ringPts.add(p.offset);
    }

    final Path discPath = Path()..addPolygon(ringPts, true);
    canvas.drawPath(
      discPath,
      Paint()
        ..color = AppColors.surfaceLight.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      discPath,
      Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: isDisabled ? 0.16 : 0.42)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Osie platformy + znacznik kąta yaw
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi * 0.5 + yawTurnRad * 0.25;
      final CfdProjectedPoint3d pA = CfdWindTunnelHeatmapCalculator.projectPoint3d(
        x: math.cos(angle) * 1.35,
        y: 0.0,
        z: math.sin(angle) * 1.35,
        canvasSize: size,
        cameraYawDeg: totalYaw,
        cameraPitchDeg: cameraPitchDeg,
        zoom: zoom,
      );
      final CfdProjectedPoint3d pB = CfdWindTunnelHeatmapCalculator.projectPoint3d(
        x: -math.cos(angle) * 1.35,
        y: 0.0,
        z: -math.sin(angle) * 1.35,
        canvasSize: size,
        cameraYawDeg: totalYaw,
        cameraPitchDeg: cameraPitchDeg,
        zoom: zoom,
      );
      canvas.drawLine(
        pA.offset,
        pB.offset,
        Paint()
          ..color = AppTheme.borderColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.0,
      );
    }
  }

  void _paintKarmanVortexWake(Canvas canvas, Size size) {
    final List<KarmanVortexNode> nodes = RealTimeCfdVortexAndDragSolver.sampleWakeVortexField(
      solverResult: solverResult,
      timeSeconds: isDisabled ? 0.0 : timeSeconds,
      vortexPairCount: 10,
    );
    final double totalYaw = cameraYawDeg + solverResult.yawAngleDegrees;

    for (final KarmanVortexNode node in nodes) {
      final CfdProjectedPoint3d center = CfdWindTunnelHeatmapCalculator.projectPoint3d(
        x: -0.68 - node.downstreamMeters * 0.55,
        y: 0.72 + math.sin(node.downstreamMeters * 3.1 + animationPhase * math.pi * 2) * 0.08,
        z: node.lateralOffsetMeters,
        canvasSize: size,
        cameraYawDeg: totalYaw,
        cameraPitchDeg: cameraPitchDeg,
        zoom: zoom,
      );

      final double r = (node.coreRadiusMeters * center.scale * 0.95).clamp(6.0, 34.0);
      final Color eddyColor = node.circulationStrength >= 0
          ? AppColors.amberWarning
          : AppColors.cyanAccent;
      final double alpha = (node.energyRetention * 0.55).clamp(0.08, 0.55);

      canvas.drawCircle(
        center.offset,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              eddyColor.withValues(alpha: alpha),
              eddyColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: center.offset, radius: r)),
      );

      // Łuk wirowy wskazujący kierunek rotacji
      final double spinDir = node.circulationStrength >= 0 ? 1.0 : -1.0;
      final double startAngle = (animationPhase * math.pi * 4.0 * spinDir) % (math.pi * 2);
      canvas.drawArc(
        Rect.fromCircle(center: center.offset, radius: r * 0.62),
        startAngle,
        math.pi * 1.25,
        false,
        Paint()
          ..color = eddyColor.withValues(alpha: alpha * 1.25)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _paintAirflowStreamlines(Canvas canvas, Size size, {required bool foreground}) {
    final double totalYaw = cameraYawDeg + solverResult.yawAngleDegrees;
    final double speedNorm = (solverResult.apparentWindSpeedKmh / 65.0).clamp(0.4, 1.5);
    final double tuck = input.headTuckFactor.clamp(0.0, 1.0);
    final bool isTt = input.forearmPosture == CfdForearmPosture.ttAeroBars ||
        input.forearmPosture == CfdForearmPosture.highHandsMantis;

    const int lineCount = 7;
    for (int i = 0; i < lineCount; i++) {
      final bool isFgLine = i.isOdd;
      if (isFgLine != foreground) continue;

      final double baseY = 0.24 + (i / (lineCount - 1)) * 1.18;
      final double baseZ = (i - 3) * (foreground ? 0.09 : -0.07);
      final Path path = Path();

      const int steps = 24;
      for (int s = 0; s <= steps; s++) {
        final double u = s / steps; // 0 = przód (x=+1.65), 1 = tył śladu (x=-1.85)
        final double x = 1.65 - u * 3.5;

        // Ugięcie strugi opływającej sylwetkę kolarza
        final double bodyEnvelope = math.exp(-math.pow((x - 0.12) / 0.58, 2));
        final double roofLift = (baseY > 0.72)
            ? bodyEnvelope * (0.28 - tuck * 0.08 - (isTt ? 0.05 : 0.0))
            : -bodyEnvelope * 0.06;
        final double wakeWave = (x < -0.35)
            ? math.sin((x * 4.2) + animationPhase * math.pi * 2.0 * speedNorm + i) *
                0.045 *
                solverResult.karmanWakeTurbulenceIntensity
            : 0.0;

        final CfdProjectedPoint3d p = CfdWindTunnelHeatmapCalculator.projectPoint3d(
          x: x,
          y: baseY + roofLift + wakeWave,
          z: baseZ,
          canvasSize: size,
          cameraYawDeg: totalYaw,
          cameraPitchDeg: cameraPitchDeg,
          zoom: zoom,
        );

        if (s == 0) {
          path.moveTo(p.offset.dx, p.offset.dy);
        } else {
          path.lineTo(p.offset.dx, p.offset.dy);
        }
      }

      // Kolor strugi zależny od trybu warstwy
      final Color streamColor = layerMode == CfdHeatmapLayerMode.vorticityShear
          ? AppColors.amberWarning
          : AppColors.cyanAccent;

      canvas.drawPath(
        path,
        Paint()
          ..color = streamColor.withValues(alpha: foreground ? 0.34 : 0.20)
          ..strokeWidth = foreground ? 1.8 : 1.2
          ..style = PaintingStyle.stroke,
      );

      // Animowany impuls cząsteczki lecący wzdłuż strugi (120 FPS)
      if (!isDisabled) {
        final double pulseU = (animationPhase * (0.9 + 0.25 * (i % 3)) + i * 0.17) % 1.0;
        final double px = 1.65 - pulseU * 3.5;
        final double bodyEnv = math.exp(-math.pow((px - 0.12) / 0.58, 2));
        final double py = baseY +
            ((baseY > 0.72)
                ? bodyEnv * (0.28 - tuck * 0.08 - (isTt ? 0.05 : 0.0))
                : -bodyEnv * 0.06);
        final CfdProjectedPoint3d dot = CfdWindTunnelHeatmapCalculator.projectPoint3d(
          x: px,
          y: py,
          z: baseZ,
          canvasSize: size,
          cameraYawDeg: totalYaw,
          cameraPitchDeg: cameraPitchDeg,
          zoom: zoom,
        );
        canvas.drawCircle(
          dot.offset,
          foreground ? 3.0 : 2.2,
          Paint()..color = AppColors.textPrimary.withValues(alpha: 0.85),
        );
      }
    }
  }

  void _paintCyclistAndBike3dHeatmap(Canvas canvas, Size size) {
    final double totalYaw = cameraYawDeg + solverResult.yawAngleDegrees;
    CfdProjectedPoint3d p3d(double x, double y, double z) =>
        CfdWindTunnelHeatmapCalculator.projectPoint3d(
          x: x,
          y: y,
          z: z,
          canvasSize: size,
          cameraYawDeg: totalYaw,
          cameraPitchDeg: cameraPitchDeg,
          zoom: zoom,
        );

    final Color wheelColor = _zoneColor(CfdAeroZone.wheels);
    final Color frameColor = _zoneColor(CfdAeroZone.frameAndCockpit);
    final Color legsColor = _zoneColor(CfdAeroZone.legsAndDrivetrain);
    final Color torsoColor = _zoneColor(CfdAeroZone.textiles);
    final Color armsColor = _zoneColor(CfdAeroZone.forearms);
    final Color helmetColor = _zoneColor(CfdAeroZone.helmet);

    // 1. Koła 700c (r = 0.34m)
    final double wheelSpinRad =
        isDisabled ? 0.0 : timeSeconds * (input.groundSpeedKmh / 3.6) / 0.34;
    _paintWheel3d(
      canvas: canvas,
      centerX: -0.52,
      centerY: 0.34,
      p3d: p3d,
      zoneColor: wheelColor,
      spinRad: wheelSpinRad,
      isRearDisc: input.wheelSpec == CfdWheelProfileSpec.ttDiscRear80Front,
      rimDepthMm: input.wheelSpec.rimDepthMm.toDouble(),
    );
    _paintWheel3d(
      canvas: canvas,
      centerX: 0.56,
      centerY: 0.34,
      p3d: p3d,
      zoneColor: wheelColor,
      spinRad: wheelSpinRad,
      isRearDisc: false,
      rimDepthMm: input.wheelSpec.rimDepthMm.toDouble(),
    );

    // 2. Rama aero i kokpit
    final CfdProjectedPoint3d rearAxle = p3d(-0.52, 0.34, 0.0);
    final CfdProjectedPoint3d frontAxle = p3d(0.56, 0.34, 0.0);
    final CfdProjectedPoint3d bb = p3d(-0.08, 0.29, 0.0);
    final CfdProjectedPoint3d seatCluster = p3d(-0.22, 0.78, 0.0);
    final CfdProjectedPoint3d headTubeTop = p3d(0.36, 0.84, 0.0);
    final CfdProjectedPoint3d saddle = p3d(-0.26, 0.92, 0.0);

    final double tubeScale = (rearAxle.scale * 0.022).clamp(2.5, 9.0);
    _paintHeatTube(canvas, rearAxle.offset, bb.offset, frameColor, tubeScale * 0.85);
    _paintHeatTube(canvas, rearAxle.offset, seatCluster.offset, frameColor, tubeScale * 0.75);
    _paintHeatTube(canvas, bb.offset, seatCluster.offset, frameColor, tubeScale * 1.15);
    _paintHeatTube(canvas, bb.offset, headTubeTop.offset, frameColor, tubeScale * 1.35);
    _paintHeatTube(canvas, seatCluster.offset, headTubeTop.offset, frameColor, tubeScale * 1.05);
    _paintHeatTube(canvas, headTubeTop.offset, frontAxle.offset, frameColor, tubeScale * 1.15);
    _paintHeatTube(canvas, seatCluster.offset, saddle.offset, frameColor, tubeScale * 0.85);

    // 3. Animacja nóg i korby (cadenceRpm)
    final double crankAngle = isDisabled
        ? 0.4
        : timeSeconds * (input.cadenceRpm / 60.0) * math.pi * 2.0;

    void drawLeg(double phaseOffset, double zSign) {
      final double a = crankAngle + phaseOffset;
      final double pedalX = -0.08 + math.cos(a) * 0.17;
      final double pedalY = 0.29 + math.sin(a) * 0.17;
      final double kneeX = 0.02 + math.cos(a + 0.45) * 0.11;
      final double kneeY = 0.62 + math.sin(a) * 0.08;

      final CfdProjectedPoint3d hip = p3d(-0.24, 0.96, zSign * 0.09);
      final CfdProjectedPoint3d knee = p3d(kneeX, kneeY, zSign * 0.10);
      final CfdProjectedPoint3d ankle = p3d(pedalX, pedalY, zSign * 0.09);

      _paintHeatLimb(canvas, hip.offset, knee.offset, legsColor, tubeScale * 2.1);
      _paintHeatLimb(canvas, knee.offset, ankle.offset, legsColor, tubeScale * 1.65);
    }

    // Dalsza noga, potem bliższa
    drawLeg(math.pi, -1.0);
    drawLeg(0.0, 1.0);

    // 4. Tułów, przedramiona i kask
    final double tuck = input.headTuckFactor.clamp(0.0, 1.0);
    final bool isTt = input.forearmPosture == CfdForearmPosture.ttAeroBars ||
        input.forearmPosture == CfdForearmPosture.highHandsMantis;
    final double torsoDrop = isTt ? 0.14 : (tuck * 0.08);

    final CfdProjectedPoint3d hipCenter = p3d(-0.24, 0.96, 0.0);
    final CfdProjectedPoint3d shoulderCenter = p3d(0.24, 1.18 - torsoDrop, 0.0);
    final CfdProjectedPoint3d headCenter = p3d(
      isTt ? 0.40 : 0.34,
      1.26 - torsoDrop - tuck * 0.10,
      0.0,
    );

    // Tułów z gradientem stagnacji od barków do bioder
    final Paint torsoPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: <Color>[
          torsoColor,
          Color.lerp(torsoColor, AppColors.accentBlue, 0.35) ?? torsoColor,
        ],
      ).createShader(Rect.fromPoints(hipCenter.offset, shoulderCenter.offset))
      ..strokeWidth = tubeScale * 3.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(hipCenter.offset, shoulderCenter.offset, torsoPaint);

    // Przedramiona i kierownica
    final double handX = isTt ? 0.64 : 0.49;
    final double handY = isTt ? 0.92 : (input.forearmPosture == CfdForearmPosture.dropsCompact ? 0.80 : 0.90);
    for (final double zSign in const <double>[-1.0, 1.0]) {
      final CfdProjectedPoint3d sh = p3d(0.24, 1.18 - torsoDrop, zSign * 0.14);
      final CfdProjectedPoint3d elbow = p3d(
        isTt ? 0.42 : 0.34,
        isTt ? 0.94 : 0.98 - torsoDrop * 0.5,
        zSign * (isTt ? 0.09 : 0.16),
      );
      final CfdProjectedPoint3d hand = p3d(handX, handY, zSign * (isTt ? 0.06 : 0.16));
      _paintHeatLimb(canvas, sh.offset, elbow.offset, armsColor, tubeScale * 1.45);
      _paintHeatLimb(canvas, elbow.offset, hand.offset, armsColor, tubeScale * 1.25);
    }

    // Kask aero (z wydłużonym ogonem dla TT)
    final double helmetRadius = (0.115 * headCenter.scale).clamp(10.0, 34.0);
    final Path helmetPath = Path();
    if (input.helmetType == CfdHelmetType.ttLongTeardrop ||
        input.helmetType == CfdHelmetType.ttShortTail) {
      final double tailLen = input.helmetType == CfdHelmetType.ttLongTeardrop ? 2.4 : 1.75;
      final CfdProjectedPoint3d tailPt = p3d(
        (isTt ? 0.40 : 0.34) - 0.14 * tailLen,
        1.27 - torsoDrop - tuck * 0.09,
        0.0,
      );
      helmetPath.addOval(Rect.fromCircle(center: headCenter.offset, radius: helmetRadius));
      helmetPath.moveTo(headCenter.offset.dx, headCenter.offset.dy - helmetRadius * 0.85);
      helmetPath.lineTo(tailPt.offset.dx, tailPt.offset.dy);
      helmetPath.lineTo(headCenter.offset.dx, headCenter.offset.dy + helmetRadius * 0.55);
      helmetPath.close();
    } else {
      helmetPath.addOval(Rect.fromCircle(center: headCenter.offset, radius: helmetRadius));
    }

    canvas.drawPath(
      helmetPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.55, -0.2),
          radius: 1.1,
          colors: <Color>[
            helmetColor,
            Color.lerp(helmetColor, AppColors.background, 0.35) ?? helmetColor,
          ],
        ).createShader(helmetPath.getBounds()),
    );
    canvas.drawPath(
      helmetPath,
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.45)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintWheel3d({
    required Canvas canvas,
    required double centerX,
    required double centerY,
    required CfdProjectedPoint3d Function(double, double, double) p3d,
    required Color zoneColor,
    required double spinRad,
    required bool isRearDisc,
    required double rimDepthMm,
  }) {
    const int pts = 28;
    const double r = 0.34;
    final Path outerPath = Path();
    for (int i = 0; i <= pts; i++) {
      final double a = (i / pts) * math.pi * 2.0;
      final CfdProjectedPoint3d p = p3d(
        centerX + math.cos(a) * r,
        centerY + math.sin(a) * r,
        0.0,
      );
      if (i == 0) {
        outerPath.moveTo(p.offset.dx, p.offset.dy);
      } else {
        outerPath.lineTo(p.offset.dx, p.offset.dy);
      }
    }
    outerPath.close();

    if (isRearDisc) {
      canvas.drawPath(
        outerPath,
        Paint()..color = zoneColor.withValues(alpha: 0.36),
      );
    }

    final CfdProjectedPoint3d center = p3d(centerX, centerY, 0.0);
    final double rimStroke = ((rimDepthMm / 80.0) * 6.5 + 2.5).clamp(2.5, 9.0);
    canvas.drawPath(
      outerPath,
      Paint()
        ..color = zoneColor.withValues(alpha: 0.9)
        ..strokeWidth = rimStroke
        ..style = PaintingStyle.stroke,
    );

    // Szprychy obracające się wg prędkości
    if (!isRearDisc) {
      final Paint spokePaint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.38)
        ..strokeWidth = 1.0;
      for (int s = 0; s < 6; s++) {
        final double a = spinRad + s * (math.pi / 3.0);
        final CfdProjectedPoint3d rimPt = p3d(
          centerX + math.cos(a) * (r - 0.03),
          centerY + math.sin(a) * (r - 0.03),
          0.0,
        );
        canvas.drawLine(center.offset, rimPt.offset, spokePaint);
      }
    }
  }

  void _paintHeatTube(Canvas canvas, Offset a, Offset b, Color color, double width) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintHeatLimb(Canvas canvas, Offset a, Offset b, Color color, double width) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color.withValues(alpha: 0.92)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintZoneHighlightRing(Canvas canvas, Size size) {
    final CfdAeroZone? focusZone = hoveredZone ?? selectedZone;
    if (focusZone == null) return;

    final double totalYaw = cameraYawDeg + solverResult.yawAngleDegrees;
    final anchor = CfdWindTunnelHeatmapCalculator.zoneAnchor3d(
      zone: focusZone,
      input: input,
    );
    final CfdProjectedPoint3d p = CfdWindTunnelHeatmapCalculator.projectPoint3d(
      x: anchor.x,
      y: anchor.y,
      z: anchor.z,
      canvasSize: size,
      cameraYawDeg: totalYaw,
      cameraPitchDeg: cameraPitchDeg,
      zoom: zoom,
    );
    final double radius = (anchor.hitRadiusMeters * p.scale).clamp(20.0, 84.0);
    final Color ringColor = selectedZone == focusZone
        ? AppColors.goldAccent
        : AppColors.cyanAccent;

    canvas.drawCircle(
      p.offset,
      radius,
      Paint()
        ..color = ringColor.withValues(alpha: 0.20)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      p.offset,
      radius,
      Paint()
        ..color = ringColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  Color _zoneColor(CfdAeroZone zone) {
    final CfdZoneBreakdown breakdown = solverResult.zoneOf(zone);
    final double t = CfdWindTunnelHeatmapCalculator.normalizedMetricForZone(
      breakdown: breakdown,
      solverResult: solverResult,
      mode: layerMode,
    );
    return CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(t, mode: layerMode);
  }

  @override
  bool shouldRepaint(covariant CfdWindTunnelHeatmap3dPainter oldDelegate) {
    return oldDelegate.animationPhase != animationPhase ||
        oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.layerMode != layerMode ||
        oldDelegate.cameraYawDeg != cameraYawDeg ||
        oldDelegate.cameraPitchDeg != cameraPitchDeg ||
        oldDelegate.zoom != zoom ||
        oldDelegate.hoveredZone != hoveredZone ||
        oldDelegate.selectedZone != selectedZone ||
        oldDelegate.showStreamlines != showStreamlines ||
        oldDelegate.showKarmanVortices != showKarmanVortices ||
        oldDelegate.showTurntable != showTurntable ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.solverResult.totalCdA != solverResult.totalCdA ||
        oldDelegate.solverResult.yawAngleDegrees != solverResult.yawAngleDegrees ||
        oldDelegate.input.cadenceRpm != input.cadenceRpm ||
        oldDelegate.input.headTuckFactor != input.headTuckFactor ||
        oldDelegate.input.forearmPosture != input.forearmPosture ||
        oldDelegate.input.helmetType != input.helmetType ||
        oldDelegate.input.wheelSpec != input.wheelSpec;
  }
}

/// Kompletny interaktywny widżet wizualizatora CFD 120 FPS z panelem warstw,
/// orbitą kamery 3D, sondą strefową oraz responsywnością LayoutBuilder.
class CfdWindTunnelHeatmap3dWidget extends StatefulWidget {
  final CfdSolverInput input;
  final ValueChanged<CfdAeroZone?>? onZoneSelected;
  final bool isDisabled;
  final bool isReadOnly;
  final bool enableAnimation;

  const CfdWindTunnelHeatmap3dWidget({
    super.key,
    this.input = const CfdSolverInput(
      groundSpeedKmh: 48.0,
      crosswindKmh: 12.0,
      helmetType: CfdHelmetType.aeroRoad,
      forearmPosture: CfdForearmPosture.dropsCompact,
      textileSpec: CfdTextileSpec.aeroSkinsuitRibbed,
      wheelSpec: CfdWheelProfileSpec.deepCarbon65,
    ),
    this.onZoneSelected,
    this.isDisabled = false,
    this.isReadOnly = false,
    this.enableAnimation = true,
  });

  @override
  State<CfdWindTunnelHeatmap3dWidget> createState() =>
      _CfdWindTunnelHeatmap3dWidgetState();
}

class _CfdWindTunnelHeatmap3dWidgetState extends State<CfdWindTunnelHeatmap3dWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final FocusNode _focusNode;

  CfdHeatmapLayerMode _layerMode = CfdHeatmapLayerMode.pressureCp;
  CfdCameraOrbitPreset _activePreset = CfdCameraOrbitPreset.threeQuarterFront;
  double _cameraYawDeg = CfdCameraOrbitPreset.threeQuarterFront.yawDeg;
  double _cameraPitchDeg = CfdCameraOrbitPreset.threeQuarterFront.pitchDeg;
  double _zoom = CfdCameraOrbitPreset.threeQuarterFront.zoom;

  bool _showStreamlines = true;
  bool _showKarmanVortices = true;
  bool _showTurntable = true;
  bool _isPaused = false;
  bool _isCanvasFocused = false;

  CfdAeroZone? _hoveredZone;
  CfdAeroZone? _selectedZone;
  CfdHeatmapProbeReading? _probeReading;
  Size _lastCanvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'CfdWindTunnel3dFocus');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enableAnimation && !widget.isDisabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CfdWindTunnelHeatmap3dWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDisabled || !widget.enableAnimation || _isPaused) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyPreset(CfdCameraOrbitPreset preset) {
    if (widget.isDisabled) return;
    setState(() {
      _activePreset = preset;
      _cameraYawDeg = preset.yawDeg;
      _cameraPitchDeg = preset.pitchDeg;
      _zoom = preset.zoom;
    });
  }

  void _togglePause() {
    if (widget.isDisabled || !widget.enableAnimation) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    });
  }

  void _handlePointerHover(Offset localPos, CfdSolverResult solverResult) {
    if (widget.isDisabled || _lastCanvasSize == Size.zero) return;
    final List<CfdProjectedZoneHitbox> hitboxes =
        CfdWindTunnelHeatmapCalculator.buildProjectedZoneHitboxes(
      canvasSize: _lastCanvasSize,
      input: widget.input,
      solverResult: solverResult,
      cameraYawDeg: _cameraYawDeg + solverResult.yawAngleDegrees,
      cameraPitchDeg: _cameraPitchDeg,
      zoom: _zoom,
    );
    final CfdHeatmapProbeReading? reading = CfdWindTunnelHeatmapCalculator.hitTestProbe(
      position: localPos,
      hitboxes: hitboxes,
      solverResult: solverResult,
      mode: _layerMode,
    );
    if (reading?.zone != _hoveredZone || reading != null) {
      setState(() {
        _hoveredZone = reading?.zone;
        _probeReading = reading;
      });
    }
  }

  void _handleTap(Offset localPos, CfdSolverResult solverResult) {
    if (widget.isDisabled || widget.isReadOnly || _lastCanvasSize == Size.zero) return;
    _focusNode.requestFocus();
    final List<CfdProjectedZoneHitbox> hitboxes =
        CfdWindTunnelHeatmapCalculator.buildProjectedZoneHitboxes(
      canvasSize: _lastCanvasSize,
      input: widget.input,
      solverResult: solverResult,
      cameraYawDeg: _cameraYawDeg + solverResult.yawAngleDegrees,
      cameraPitchDeg: _cameraPitchDeg,
      zoom: _zoom,
    );
    final CfdHeatmapProbeReading? reading = CfdWindTunnelHeatmapCalculator.hitTestProbe(
      position: localPos,
      hitboxes: hitboxes,
      solverResult: solverResult,
      mode: _layerMode,
    );
    setState(() {
      _selectedZone = reading?.zone == _selectedZone ? null : reading?.zone;
      _probeReading = reading;
    });
    widget.onZoneSelected?.call(_selectedZone);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.isDisabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() => _cameraYawDeg = (_cameraYawDeg - 10.0) % 360.0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() => _cameraYawDeg = (_cameraYawDeg + 10.0) % 360.0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _cameraPitchDeg = (_cameraPitchDeg + 6.0).clamp(-10.0, 80.0));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _cameraPitchDeg = (_cameraPitchDeg - 6.0).clamp(-10.0, 80.0));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePause();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _applyPreset(CfdCameraOrbitPreset.threeQuarterFront);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CfdSolverResult solverResult =
        RealTimeCfdVortexAndDragSolver.solveFrame(widget.input);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 680;
        final bool isWide = constraints.maxWidth >= 1024;

        return Focus(
          focusNode: _focusNode,
          onFocusChange: (bool focused) {
            if (_isCanvasFocused != focused) {
              setState(() => _isCanvasFocused = focused);
            }
          },
          onKeyEvent: _handleKeyEvent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isCanvasFocused
                    ? AppColors.goldAccent
                    : AppTheme.borderColor,
                width: _isCanvasFocused ? 1.5 : 1.0,
              ),
            ),
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildHeaderBar(solverResult, isCompact, constraints.maxWidth - (isCompact ? 24 : 32)),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 7,
                        child: _buildViewportCanvas(
                          solverResult: solverResult,
                          height: 360,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: _buildZoneTelemetrySidebar(solverResult),
                      ),
                    ],
                  )
                else ...<Widget>[
                  _buildViewportCanvas(
                    solverResult: solverResult,
                    height: isCompact ? 240 : 310,
                  ),
                  const SizedBox(height: 12),
                  _buildZoneTelemetrySidebar(solverResult),
                ],
                const SizedBox(height: 12),
                _buildBottomControlsBar(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar(CfdSolverResult solverResult, bool isCompact, double contentMaxWidth) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.max(160.0, contentMaxWidth)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Icon(
                  Icons.air_rounded,
                  size: 18,
                  color: widget.isDisabled
                      ? AppColors.textSecondary
                      : AppColors.cyanAccent,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CFD Wind Tunnel 3D Heatmap',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '${widget.input.groundSpeedKmh.toStringAsFixed(1)} km/h • Yaw ${solverResult.yawAngleDegrees.toStringAsFixed(1)}° • CdA ${solverResult.totalCdA.toStringAsFixed(4)} m²',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CfdHeatmapLayerMode.values.map((CfdHeatmapLayerMode mode) {
            final bool selected = _layerMode == mode;
            return _InteractiveCfdPillButton(
              label: mode.labelEn,
              selected: selected,
              disabled: widget.isDisabled,
              onTap: () => setState(() => _layerMode = mode),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildViewportCanvas({
    required CfdSolverResult solverResult,
    required double height,
  }) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              _lastCanvasSize = Size(box.maxWidth, box.maxHeight);
              return MouseRegion(
                cursor: widget.isDisabled
                    ? SystemMouseCursors.forbidden
                    : SystemMouseCursors.grab,
                onHover: (PointerHoverEvent event) =>
                    _handlePointerHover(event.localPosition, solverResult),
                onExit: (_) {
                  if (_hoveredZone != null || _probeReading != null) {
                    setState(() {
                      _hoveredZone = null;
                      _probeReading = null;
                    });
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: widget.isDisabled
                      ? null
                      : (DragUpdateDetails details) {
                          setState(() {
                            _cameraYawDeg = (_cameraYawDeg + details.delta.dx * 0.45) % 360.0;
                            _cameraPitchDeg =
                                (_cameraPitchDeg + details.delta.dy * 0.35).clamp(-10.0, 80.0);
                          });
                        },
                  onTapUp: (TapUpDetails details) =>
                      _handleTap(details.localPosition, solverResult),
                  onDoubleTap: () =>
                      _applyPreset(CfdCameraOrbitPreset.threeQuarterFront),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, _) {
                          final double phase = _controller.value;
                          final double secs = phase * 2.4;
                          return CustomPaint(
                            painter: CfdWindTunnelHeatmap3dPainter(
                              input: widget.input,
                              solverResult: solverResult,
                              animationPhase: phase,
                              timeSeconds: secs,
                              layerMode: _layerMode,
                              cameraYawDeg: _cameraYawDeg,
                              cameraPitchDeg: _cameraPitchDeg,
                              zoom: _zoom,
                              hoveredZone: _hoveredZone,
                              selectedZone: _selectedZone,
                              showStreamlines: _showStreamlines,
                              showKarmanVortices: _showKarmanVortices,
                              showTurntable: _showTurntable,
                              isDisabled: widget.isDisabled,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _buildColorbarLegend(),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _buildLiveTunnelStatsBadge(solverResult),
                      ),
                      if (_probeReading != null)
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: _buildProbeOverlayCard(_probeReading!),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildColorbarLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _layerMode.unit,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 84,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: <Color>[
                  CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(0.0, mode: _layerMode),
                  CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(0.5, mode: _layerMode),
                  CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(1.0, mode: _layerMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTunnelStatsBadge(CfdSolverResult solverResult) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        '${solverResult.totalAeroPowerWatts.toStringAsFixed(0)} W • fK ${solverResult.karmanDominantFrequencyHz.toStringAsFixed(1)} Hz',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.goldAccent,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildProbeOverlayCard(CfdHeatmapProbeReading reading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            reading.regionLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Cp ${reading.pressureCp.toStringAsFixed(2)} • ${reading.dragWatts.toStringAsFixed(1)} W • ${reading.flowRegime.labelPl}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneTelemetrySidebar(CfdSolverResult solverResult) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Zone Pressure & Drag Breakdown',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...solverResult.zones.map((CfdZoneBreakdown z) {
            final bool isSelected = _selectedZone == z.zone;
            final double norm = CfdWindTunnelHeatmapCalculator.normalizedMetricForZone(
              breakdown: z,
              solverResult: solverResult,
              mode: _layerMode,
            );
            final Color barColor =
                CfdWindTunnelHeatmapCalculator.heatmapColorForNormalized(norm, mode: _layerMode);

            return InkWell(
              onTap: widget.isDisabled || widget.isReadOnly
                  ? null
                  : () {
                      setState(() {
                        _selectedZone = isSelected ? null : z.zone;
                      });
                      widget.onZoneSelected?.call(_selectedZone);
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAccent.withValues(alpha: 0.25)
                      : AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 22,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            z.zone.labelEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Cp ${z.pressureCoefficientCp.toStringAsFixed(2)} • ${(z.shareOfTotalDrag * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${z.aeroPowerWatts.toStringAsFixed(0)} W',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomControlsBar(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CfdCameraOrbitPreset.values.map((CfdCameraOrbitPreset preset) {
            return _InteractiveCfdPillButton(
              label: preset.label,
              selected: _activePreset == preset,
              disabled: widget.isDisabled,
              onTap: () => _applyPreset(preset),
            );
          }).toList(),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _InteractiveCfdPillButton(
              label: 'Streamlines',
              selected: _showStreamlines,
              disabled: widget.isDisabled,
              onTap: () => setState(() => _showStreamlines = !_showStreamlines),
            ),
            _InteractiveCfdPillButton(
              label: 'Kármán Wake',
              selected: _showKarmanVortices,
              disabled: widget.isDisabled,
              onTap: () => setState(() => _showKarmanVortices = !_showKarmanVortices),
            ),
            _InteractiveCfdPillButton(
              label: 'Turntable',
              selected: _showTurntable,
              disabled: widget.isDisabled,
              onTap: () => setState(() => _showTurntable = !_showTurntable),
            ),
            _InteractiveCfdPillButton(
              label: _isPaused ? 'Resume' : 'Pause',
              selected: !_isPaused && !widget.isDisabled,
              disabled: widget.isDisabled || !widget.enableAnimation,
              onTap: _togglePause,
            ),
          ],
        ),
      ],
    );
  }
}

class _InteractiveCfdPillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _InteractiveCfdPillButton({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_InteractiveCfdPillButton> createState() => _InteractiveCfdPillButtonState();
}

class _InteractiveCfdPillButtonState extends State<_InteractiveCfdPillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (widget.disabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.4);
      borderColor = AppTheme.borderColor.withValues(alpha: 0.5);
      textColor = AppColors.textSecondary.withValues(alpha: 0.45);
    } else if (widget.selected) {
      bgColor = _pressed
          ? AppColors.primaryAccent
          : AppColors.primaryAccent.withValues(alpha: 0.35);
      borderColor = _focused ? AppColors.goldAccent : AppColors.goldAccent.withValues(alpha: 0.8);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = _pressed
          ? AppColors.surfaceLight
          : _hovered
              ? AppColors.surfaceLight
              : AppColors.background;
      borderColor = _focused
          ? AppColors.goldAccent
          : _hovered
              ? AppColors.cyanAccent.withValues(alpha: 0.6)
              : AppTheme.borderColor;
      textColor = _hovered ? AppColors.textPrimary : AppColors.textSecondary;
    }

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (bool v) => setState(() => _focused = v),
      onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: widget.disabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onTap();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
