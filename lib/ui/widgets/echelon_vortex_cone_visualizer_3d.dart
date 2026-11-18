// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/aerodynamic_cross_drafting_echelon_vortex.dart';

/// Preset kamery 3D w trybie Aero Vision dla wizualizacji stożka wachlarza.
enum EchelonConeCameraPreset {
  chase3Quarter('3/4 Chase', -28.0, 26.0, 1.0),
  overheadTactical('Overhead', 0.0, 74.0, 0.92),
  lowGutter('Gutter Cam', 38.0, 14.0, 1.08),
  windwardSide('Windward', -52.0, 20.0, 0.98);

  final String label;
  final double yawDeg;
  final double pitchDeg;
  final double zoom;

  const EchelonConeCameraPreset(
    this.label,
    this.yawDeg,
    this.pitchDeg,
    this.zoom,
  );
}

/// Tryb filtrowania warstw stożka cienia aerodynamicznego w Aero Vision 3D.
enum EchelonVortexConeLayerMode {
  allZones('All Zones', 'Wszystkie strefy'),
  optimalConeOnly('Optimal Cone', 'Stożek optymalny'),
  gutterExposureOnly('Gutter Risk', 'Ekspozycja w rynsztoku');

  final String labelEn;
  final String labelPl;

  const EchelonVortexConeLayerMode(this.labelEn, this.labelPl);
}

/// Wynik rzutowania punktu 3D przestrzeni wachlarza na płaszczyznę 2D płótna.
@immutable
class EchelonProjectedPoint3d {
  final Offset offset;
  final double depth;
  final double scale;

  const EchelonProjectedPoint3d({
    required this.offset,
    required this.depth,
    required this.scale,
  });
}

/// Obszar trafienia 2D kolarza w widoku 3D do obsługi hover, kliknięcia i fokusu.
@immutable
class EchelonProjectedRiderHitbox {
  final EchelonVortexRiderNode3d rider;
  final Offset center;
  final double radius;
  final double depth;

  const EchelonProjectedRiderHitbox({
    required this.rider,
    required this.center,
    required this.radius,
    required this.depth,
  });
}

/// Reprezentacja pojedynczego kolarza w trójwymiarowej scenie wachlarza Aero Vision.
@immutable
class EchelonVortexRiderNode3d {
  final String id;
  final String name;
  final int bibNumber;
  final String teamCode;
  final bool isPlayerRider;

  /// Pozycja podłużna wzdłuż osi szosy [m] (0.0 = lider wachlarza, >0 = z tyłu za liderem).
  final double longitudinalMeters;

  /// Pozycja poprzeczna na szosie [m] (0.0 = środek drogi, <0 = lewa krawędź, >0 = prawa krawędź).
  final double lateralMeters;

  /// Aktualna prędkość jazdy [m/s].
  final double speedMs;

  /// Czy kolarz prowadzi wachlarz na wietrze (brak poprzednika).
  final bool isLeader;

  /// Wynik obliczeń fizyki stożka wirów dla tego kolarza (null dla lidera na czele).
  final EchelonVortexResult? vortexResult;

  const EchelonVortexRiderNode3d({
    required this.id,
    required this.name,
    required this.bibNumber,
    required this.teamCode,
    required this.isPlayerRider,
    required this.longitudinalMeters,
    required this.lateralMeters,
    required this.speedMs,
    this.isLeader = false,
    this.vortexResult,
  });

  /// Strefa aerodynamiczna kolarza (lider ma pełną ekspozycję czołową).
  EchelonConeZone get effectiveZone =>
      vortexResult?.coneZone ?? EchelonConeZone.windwardExposed;

  /// Procentowa redukcja oporu [0..38].
  double get dragReductionPercent => vortexResult?.dragReductionPercent ?? 0.0;

  /// Zaoszczędzona moc [W].
  double get powerSavedWatts => vortexResult?.powerSavedWatts ?? 0.0;
}

/// Kompletny zestaw danych wejściowych dla wizualizatora stożka wachlarza 3D.
@immutable
class EchelonVortexConeVisualizerData {
  final List<EchelonVortexRiderNode3d> riders;
  final double windSpeedMs;
  final double windRelativeAngleDegrees;
  final double riderSpeedMs;
  final double roadWidthMeters;
  final double gutterWidthMeters;
  final String stageKmLabel;
  final bool isAeroVisionActive;

  const EchelonVortexConeVisualizerData({
    required this.riders,
    required this.windSpeedMs,
    required this.windRelativeAngleDegrees,
    required this.riderSpeedMs,
    this.roadWidthMeters = 7.2,
    this.gutterWidthMeters = 1.15,
    this.stageKmLabel = 'KM 142.8 • De Moeren Crosswind',
    this.isAeroVisionActive = true,
  });

  /// Tworzy realistyczny zestaw demonstracyjny oparty o silnik [AerodynamicCrossDraftingEchelonVortex].
  factory EchelonVortexConeVisualizerData.demo({
    bool windFromLeft = true,
    double windSpeedMs = 9.2,
    double riderSpeedMs = 13.4,
  }) {
    final double sign = windFromLeft ? 1.0 : -1.0;
    final double windAngle = windFromLeft ? 90.0 : -90.0;
    final double shiftDeg =
        AerodynamicCrossDraftingEchelonVortex.computeWakeShiftAngleDegrees(
      riderSpeedMs: riderSpeedMs,
      windSpeedMs: windSpeedMs,
      windRelativeAngleDegrees: windAngle,
    );

    // Lider na nawietrznej krawędzi szosy, kolejni schodkowo w prawo/lewo.
    final double leaderLat = -1.65 * sign;
    const double stepGap = 1.25;
    const double longitudinalGap = 0.55;
    final double optimalLatStep =
        AerodynamicCrossDraftingEchelonVortex.computeOptimalLateralOffsetMeters(
      longitudinalGapMeters: longitudinalGap,
      wakeShiftAngleDegrees: shiftDeg,
    );

    final List<({String id, String name, int bib, String team, bool player, double longM, double latM})>
        specs = [
      (
        id: 'r1',
        name: 'V. Campenaerts',
        bib: 11,
        team: 'PPM',
        player: false,
        longM: 0.0,
        latM: leaderLat,
      ),
      (
        id: 'r2',
        name: 'M. Van der Poel',
        bib: 1,
        team: 'PPM',
        player: true,
        longM: stepGap,
        latM: leaderLat + optimalLatStep,
      ),
      (
        id: 'r3',
        name: 'W. Van Aert',
        bib: 21,
        team: 'VIS',
        player: false,
        longM: stepGap * 2.0,
        latM: leaderLat + optimalLatStep * 2.02,
      ),
      (
        id: 'r4',
        name: 'J. Philipsen',
        bib: 12,
        team: 'PPM',
        player: true,
        longM: stepGap * 3.0,
        latM: leaderLat + optimalLatStep * 2.95,
      ),
      (
        id: 'r5',
        name: 'T. Merlier',
        bib: 44,
        team: 'SOQ',
        player: false,
        longM: stepGap * 4.05,
        // Błąd taktyczny: jedzie prosto za poprzednikiem zamiast na zawietrznej.
        latM: leaderLat + optimalLatStep * 2.95,
      ),
      (
        id: 'r6',
        name: 'D. Groenewegen',
        bib: 71,
        team: 'JAY',
        player: false,
        longM: stepGap * 4.95,
        // Wypchnięty na krawędź rynsztoka (brak miejsca na wachlarz — czerwona strefa).
        latM: 3.15 * sign,
      ),
    ];

    final List<EchelonVortexRiderNode3d> nodes = [];
    for (int i = 0; i < specs.length; i++) {
      final spec = specs[i];
      if (i == 0) {
        nodes.add(
          EchelonVortexRiderNode3d(
            id: spec.id,
            name: spec.name,
            bibNumber: spec.bib,
            teamCode: spec.team,
            isPlayerRider: spec.player,
            longitudinalMeters: spec.longM,
            lateralMeters: spec.latM,
            speedMs: riderSpeedMs,
            isLeader: true,
          ),
        );
      } else {
        final prev = specs[i - 1];
        final EchelonVortexResult res =
            AerodynamicCrossDraftingEchelonVortex.evaluateSingleDraft(
          EchelonVortexInput(
            riderSpeedMs: riderSpeedMs,
            windSpeedMs: windSpeedMs,
            windRelativeAngleDegrees: windAngle,
            longitudinalGapMeters: longitudinalGap,
            lateralOffsetMeters: spec.latM - prev.latM,
          ),
        );
        nodes.add(
          EchelonVortexRiderNode3d(
            id: spec.id,
            name: spec.name,
            bibNumber: spec.bib,
            teamCode: spec.team,
            isPlayerRider: spec.player,
            longitudinalMeters: spec.longM,
            lateralMeters: spec.latM,
            speedMs: riderSpeedMs,
            vortexResult: res,
          ),
        );
      }
    }

    return EchelonVortexConeVisualizerData(
      riders: nodes,
      windSpeedMs: windSpeedMs,
      windRelativeAngleDegrees: windAngle,
      riderSpeedMs: riderSpeedMs,
    );
  }

  /// Kąt przesunięcia osi stożka cienia [stopnie].
  double get wakeShiftAngleDegrees =>
      AerodynamicCrossDraftingEchelonVortex.computeWakeShiftAngleDegrees(
        riderSpeedMs: riderSpeedMs,
        windSpeedMs: windSpeedMs,
        windRelativeAngleDegrees: windRelativeAngleDegrees,
      );

  /// Kierunek napływu wiatru bocznego.
  EchelonWindSide get windSide {
    final double shift = wakeShiftAngleDegrees;
    if (shift > 2.5) return EchelonWindSide.fromLeft;
    if (shift < -2.5) return EchelonWindSide.fromRight;
    return EchelonWindSide.neutral;
  }

  /// Liczba kolarzy w zielonej strefie optymalnego schowania.
  int get optimalConeCount => riders
      .where((r) => !r.isLeader && r.effectiveZone == EchelonConeZone.optimalVortexCone)
      .length;

  /// Liczba kolarzy w czerwonej strefie ekspozycji / rynsztoka.
  int get gutterExposedCount => riders
      .where(
        (r) =>
            !r.isLeader &&
            (r.effectiveZone == EchelonConeZone.windwardExposed ||
                r.effectiveZone == EchelonConeZone.directWheelMisaligned),
      )
      .length;

  /// Suma zaoszczędzonych watów w całym wachlarzu.
  double get totalPowerSavedWatts =>
      riders.fold<double>(0.0, (sum, r) => sum + r.powerSavedWatts);

  EchelonVortexConeVisualizerData copyWith({
    List<EchelonVortexRiderNode3d>? riders,
    double? windSpeedMs,
    double? windRelativeAngleDegrees,
    double? riderSpeedMs,
    double? roadWidthMeters,
    double? gutterWidthMeters,
    String? stageKmLabel,
    bool? isAeroVisionActive,
  }) {
    return EchelonVortexConeVisualizerData(
      riders: riders ?? this.riders,
      windSpeedMs: windSpeedMs ?? this.windSpeedMs,
      windRelativeAngleDegrees:
          windRelativeAngleDegrees ?? this.windRelativeAngleDegrees,
      riderSpeedMs: riderSpeedMs ?? this.riderSpeedMs,
      roadWidthMeters: roadWidthMeters ?? this.roadWidthMeters,
      gutterWidthMeters: gutterWidthMeters ?? this.gutterWidthMeters,
      stageKmLabel: stageKmLabel ?? this.stageKmLabel,
      isAeroVisionActive: isAeroVisionActive ?? this.isAeroVisionActive,
    );
  }
}

/// Kalkulator rzutowania 3D i geometrii przesuniętego stożka cienia aerodynamicznego.
class EchelonVortexCone3dCalculator {
  EchelonVortexCone3dCalculator._();

  /// Rzutuje punkt w przestrzeni 3D drogi na płaszczyznę 2D płótna:
  /// - [xLongitudinal]: pozycja wzdłuż szosy [m] (0 = środek formacji, + = tył)
  /// - [yVertical]: wysokość nad asfaltem [m]
  /// - [zLateral]: pozycja poprzeczna na jezdni [m] (- = lewa, + = prawa)
  static EchelonProjectedPoint3d projectPoint3d({
    required double xLongitudinal,
    required double yVertical,
    required double zLateral,
    required Size canvasSize,
    required double cameraYawDeg,
    required double cameraPitchDeg,
    required double zoom,
    double centerLongitudinal = 3.0,
  }) {
    final double cx = xLongitudinal - centerLongitudinal;
    final double cy = yVertical - 0.55;
    final double cz = zLateral;

    final double yawRad = cameraYawDeg * math.pi / 180.0;
    final double pitchRad = cameraPitchDeg * math.pi / 180.0;

    final double cosY = math.cos(yawRad);
    final double sinY = math.sin(yawRad);
    // Obrót wokół osi pionowej Y (kamera patrzy na szosę)
    final double rx = cz * cosY - cx * sinY;
    final double rz = cz * sinY + cx * cosY;

    final double cosP = math.cos(pitchRad);
    final double sinP = math.sin(pitchRad);
    final double ry = cy * cosP - rz * sinP;
    final double depth = cy * sinP + rz * cosP;

    const double cameraDist = 14.5;
    final double safeDepth = math.max(-cameraDist + 1.5, depth);
    final double perspective = cameraDist / (cameraDist + safeDepth);
    final double baseScale =
        math.min(canvasSize.width, canvasSize.height) * 0.115 * zoom;

    final double screenX = canvasSize.width * 0.5 + rx * perspective * baseScale;
    final double screenY =
        canvasSize.height * 0.56 - ry * perspective * baseScale;

    return EchelonProjectedPoint3d(
      offset: Offset(screenX, screenY),
      depth: safeDepth,
      scale: perspective * zoom,
    );
  }

  /// Wyznacza najbliższego kolarza pod kursorem / dotknięciem na płótnie 2D.
  static EchelonVortexRiderNode3d? hitTestRider({
    required Offset localPosition,
    required List<EchelonProjectedRiderHitbox> hitboxes,
  }) {
    EchelonVortexRiderNode3d? best;
    double bestDist = double.infinity;
    for (final EchelonProjectedRiderHitbox box in hitboxes) {
      final double d = (box.center - localPosition).distance;
      if (d <= box.radius && d < bestDist) {
        bestDist = d;
        best = box.rider;
      }
    }
    return best;
  }
}

/// CustomPainter renderujący w 3D przesunięty stożek cienia aerodynamicznego w trybie Aero Vision.
class EchelonVortexCone3dPainter extends CustomPainter {
  final EchelonVortexConeVisualizerData data;
  final double cameraYawDeg;
  final double cameraPitchDeg;
  final double zoom;
  final double animationPhase;
  final EchelonVortexConeLayerMode layerMode;
  final String? hoveredRiderId;
  final String? selectedRiderId;
  final bool enabled;
  final ValueChanged<List<EchelonProjectedRiderHitbox>>? onHitboxesComputed;

  const EchelonVortexCone3dPainter({
    required this.data,
    required this.cameraYawDeg,
    required this.cameraPitchDeg,
    required this.zoom,
    required this.animationPhase,
    required this.layerMode,
    this.hoveredRiderId,
    this.selectedRiderId,
    this.enabled = true,
    this.onHitboxesComputed,
  });

  double get _centerLongitudinal {
    if (data.riders.isEmpty) return 3.0;
    double minX = data.riders.first.longitudinalMeters;
    double maxX = minX;
    for (final r in data.riders) {
      if (r.longitudinalMeters < minX) minX = r.longitudinalMeters;
      if (r.longitudinalMeters > maxX) maxX = r.longitudinalMeters;
    }
    return (minX + maxX) * 0.5;
  }

  EchelonProjectedPoint3d _proj(
    double xLong,
    double yVert,
    double zLat,
    Size size,
  ) {
    return EchelonVortexCone3dCalculator.projectPoint3d(
      xLongitudinal: xLong,
      yVertical: yVert,
      zLateral: zLat,
      canvasSize: size,
      cameraYawDeg: cameraYawDeg,
      cameraPitchDeg: cameraPitchDeg,
      zoom: zoom,
      centerLongitudinal: _centerLongitudinal,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 4 || size.height <= 4) return;

    // 1. Tło przestrzeni Aero Vision
    final Rect fullRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A0C10),
          AppColors.background,
          Color(0xFF12161F),
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    // 2. Wstęga szosy 3D + czerwona strefa rynsztoka po stronie zawietrznej
    _paintRoadAndGutter3d(canvas, size);

    // 3. Strugi wiatru bocznego (Aero Vision Crosswind Streamlines)
    if (data.isAeroVisionActive && enabled) {
      _paintCrosswindStreamlines3d(canvas, size);
    }

    // 4. Przesunięte stożki cienia aerodynamicznego za kolarzami
    if (data.isAeroVisionActive) {
      _paintShiftedVortexCones3d(canvas, size);
    }

    // 5. Kolarze 3D posortowani wg głębi + wektory korekty pozycji
    final List<EchelonProjectedRiderHitbox> hitboxes =
        _paintRiders3d(canvas, size);
    onHitboxesComputed?.call(hitboxes);

    // 6. Wygaszenie przy stanie disabled
    if (!enabled) {
      canvas.drawRect(
        fullRect,
        Paint()..color = AppColors.background.withValues(alpha: 0.48),
      );
    }
  }

  void _paintRoadAndGutter3d(Canvas canvas, Size size) {
    final double halfRoad = data.roadWidthMeters * 0.5;
    final double minX = _centerLongitudinal - 5.5;
    final double maxX = _centerLongitudinal + 7.5;

    final Offset fl = _proj(minX, 0.0, -halfRoad, size).offset;
    final Offset fr = _proj(minX, 0.0, halfRoad, size).offset;
    final Offset br = _proj(maxX, 0.0, halfRoad, size).offset;
    final Offset bl = _proj(maxX, 0.0, -halfRoad, size).offset;

    final Path roadPath = Path()
      ..moveTo(fl.dx, fl.dy)
      ..lineTo(fr.dx, fr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    canvas.drawPath(
      roadPath,
      Paint()
        ..color = const Color(0xFF151922)
        ..style = PaintingStyle.fill,
    );

    // Siatka metryczna co 1.5 m dla łatwej oceny odstępów w 3D
    final Paint gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    for (double x = minX; x <= maxX; x += 1.5) {
      final Offset a = _proj(x, 0.0, -halfRoad, size).offset;
      final Offset b = _proj(x, 0.0, halfRoad, size).offset;
      canvas.drawLine(a, b, gridPaint);
    }

    // Oś przerywana jezdni
    final Paint centerLinePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1.4;
    for (double x = minX; x < maxX - 0.6; x += 1.4) {
      final Offset p1 = _proj(x, 0.01, 0.0, size).offset;
      final Offset p2 = _proj(x + 0.7, 0.01, 0.0, size).offset;
      canvas.drawLine(p1, p2, centerLinePaint);
    }

    // Czerwona strefa ekspozycji w rynsztoku (Gutter Danger Zone)
    final bool showGutter = layerMode != EchelonVortexConeLayerMode.optimalConeOnly;
    if (showGutter && data.windSide != EchelonWindSide.neutral) {
      final double leewardSign =
          data.windSide == EchelonWindSide.fromLeft ? 1.0 : -1.0;
      final double gutterOuter = halfRoad * leewardSign;
      final double gutterInner =
          (halfRoad - data.gutterWidthMeters).clamp(0.5, halfRoad) * leewardSign;

      final Offset g1 = _proj(minX, 0.015, gutterInner, size).offset;
      final Offset g2 = _proj(minX, 0.015, gutterOuter, size).offset;
      final Offset g3 = _proj(maxX, 0.015, gutterOuter, size).offset;
      final Offset g4 = _proj(maxX, 0.015, gutterInner, size).offset;

      final Path gutterPath = Path()
        ..moveTo(g1.dx, g1.dy)
        ..lineTo(g2.dx, g2.dy)
        ..lineTo(g3.dx, g3.dy)
        ..lineTo(g4.dx, g4.dy)
        ..close();

      final double pulse = 0.16 + 0.08 * math.sin(animationPhase * math.pi * 2.0);
      canvas.drawPath(
        gutterPath,
        Paint()
          ..color = AppColors.crimsonAlert.withValues(alpha: pulse)
          ..style = PaintingStyle.fill,
      );

      // Paski ostrzegawcze w rynsztoku
      final Paint hazardPaint = Paint()
        ..color = AppColors.crimsonAlert.withValues(alpha: 0.55)
        ..strokeWidth = 1.3;
      for (double x = minX; x < maxX; x += 0.9) {
        final Offset ha = _proj(x, 0.02, gutterInner, size).offset;
        final Offset hb = _proj(x + 0.45, 0.02, gutterOuter, size).offset;
        canvas.drawLine(ha, hb, hazardPaint);
      }
    }

    // Krawędzie asfaltu
    final Paint edgePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.55)
      ..strokeWidth = 1.8;
    canvas.drawLine(fl, bl, edgePaint);
    canvas.drawLine(fr, br, edgePaint);
  }

  void _paintCrosswindStreamlines3d(Canvas canvas, Size size) {
    final double shiftRad = data.wakeShiftAngleDegrees * math.pi / 180.0;
    final double dirZ = math.sin(shiftRad);
    final double dirX = math.cos(shiftRad);
    final double minX = _centerLongitudinal - 4.5;
    final double halfRoad = data.roadWidthMeters * 0.52;

    final Paint streamPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 14; i++) {
      final double t = (animationPhase + i / 14.0) % 1.0;
      final double laneX = minX + (i % 7) * 1.75;
      final double startZ =
          dirZ >= 0 ? -halfRoad + t * halfRoad * 2.0 : halfRoad - t * halfRoad * 2.0;
      final double startX = laneX + t * 1.8 * dirX;
      final double endZ = startZ + dirZ * 1.25;
      final double endX = startX + dirX * 1.25;
      final double y = 0.55 + (i % 3) * 0.32;

      final Offset p1 = _proj(startX, y, startZ, size).offset;
      final Offset p2 = _proj(endX, y, endZ, size).offset;

      final double alpha = (1.0 - (t - 0.5).abs() * 2.0).clamp(0.08, 0.45);
      streamPaint
        ..color = AppColors.accentBlue.withValues(alpha: alpha)
        ..strokeWidth = 1.3;
      canvas.drawLine(p1, p2, streamPaint);
    }
  }

  void _paintShiftedVortexCones3d(Canvas canvas, Size size) {
    final double shiftRad = data.wakeShiftAngleDegrees * math.pi / 180.0;
    final double tanShift = math.tan(shiftRad);
    final bool showOptimal =
        layerMode != EchelonVortexConeLayerMode.gutterExposureOnly;

    if (!showOptimal) return;

    // Rysujemy stożek aerodynamiczny za każdym kolarzem tworzącym cień (wszyscy poza ostatnim w ogonie)
    for (int i = 0; i < data.riders.length - 1; i++) {
      final EchelonVortexRiderNode3d leader = data.riders[i];
      // Jeśli kolarz sam jest wypchnięty do rynsztoka na końcu, jego stożek nie osłania innych
      if (!leader.isLeader &&
          leader.effectiveZone == EchelonConeZone.windwardExposed &&
          i == data.riders.length - 1) {
        continue;
      }

      const double coneLength = 2.65;
      final double apexX = leader.longitudinalMeters +
          AerodynamicCrossDraftingEchelonVortex.wakeOriginOffsetMeters;
      final double apexZ = leader.lateralMeters;
      const double centerY = 0.88;

      final double baseX = apexX + coneLength;
      final double baseZ = apexZ + coneLength * tanShift;
      const double optimalRadius = 0.52;
      const double outerRadius = 0.92;

      final Offset apexPt = _proj(apexX, centerY, apexZ, size).offset;

      // Zewnętrzna otoczka częściowej osłony (niebiesko-cyjanowa)
      final Offset outerLeft = _proj(baseX, centerY, baseZ - outerRadius, size).offset;
      final Offset outerRight = _proj(baseX, centerY, baseZ + outerRadius, size).offset;
      final Path outerCone = Path()
        ..moveTo(apexPt.dx, apexPt.dy)
        ..lineTo(outerLeft.dx, outerLeft.dy)
        ..lineTo(outerRight.dx, outerRight.dy)
        ..close();

      canvas.drawPath(
        outerCone,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentBlue.withValues(alpha: 0.22),
              AppColors.accentBlue.withValues(alpha: 0.03),
            ],
          ).createShader(outerCone.getBounds()),
      );

      // Wewnętrzny zielony stożek optymalnego schowania się w wachlarzu (30-38% redukcji oporu)
      final Offset innerLeft = _proj(baseX, centerY, baseZ - optimalRadius, size).offset;
      final Offset innerRight = _proj(baseX, centerY, baseZ + optimalRadius, size).offset;
      final Offset innerTop = _proj(baseX, centerY + 0.42, baseZ, size).offset;
      final Offset innerBottom = _proj(baseX, 0.14, baseZ, size).offset;

      final Path optimalCone = Path()
        ..moveTo(apexPt.dx, apexPt.dy)
        ..lineTo(innerLeft.dx, innerLeft.dy)
        ..lineTo(innerRight.dx, innerRight.dy)
        ..close();

      canvas.drawPath(
        optimalCone,
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.statusSuccess.withValues(alpha: 0.42),
              AppColors.statusSuccess.withValues(alpha: 0.12),
            ],
          ).createShader(optimalCone.getBounds()),
      );

      // Pionowy przekrój stożka dla wrażenia objętości 3D
      final Path verticalWing = Path()
        ..moveTo(apexPt.dx, apexPt.dy)
        ..lineTo(innerTop.dx, innerTop.dy)
        ..lineTo(innerBottom.dx, innerBottom.dy)
        ..close();
      canvas.drawPath(
        verticalWing,
        Paint()..color = AppColors.statusSuccess.withValues(alpha: 0.18),
      );

      // Krawędzie i oś przesuniętego stożka
      final Paint coneEdgePaint = Paint()
        ..color = AppColors.statusSuccess.withValues(alpha: 0.72)
        ..strokeWidth = 1.3;
      canvas.drawLine(apexPt, innerLeft, coneEdgePaint);
      canvas.drawLine(apexPt, innerRight, coneEdgePaint);

      // Animowane pierścienie wirów Kármána płynące wzdłuż przesuniętej osi
      for (int ringIdx = 0; ringIdx < 3; ringIdx++) {
        final double frac = (animationPhase + ringIdx / 3.0) % 1.0;
        final double rx = apexX + frac * coneLength;
        final double rz = apexZ + frac * coneLength * tanShift;
        final double rLat = 0.16 + frac * (optimalRadius - 0.14);

        final Offset cPt = _proj(rx, centerY, rz, size).offset;
        final Offset edgePt = _proj(rx, centerY, rz + rLat, size).offset;
        final double pixelRad = math.max(4.0, (edgePt - cPt).distance);
        final double alpha = (1.0 - frac) * 0.55;

        canvas.drawOval(
          Rect.fromCenter(
            center: cPt,
            width: pixelRad * 2.0,
            height: pixelRad * 1.15,
          ),
          Paint()
            ..color = AppColors.statusSuccess.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  List<EchelonProjectedRiderHitbox> _paintRiders3d(Canvas canvas, Size size) {
    final List<({EchelonVortexRiderNode3d rider, EchelonProjectedPoint3d proj})>
        projected = data.riders
            .map(
              (r) => (
                rider: r,
                proj: _proj(r.longitudinalMeters, 0.0, r.lateralMeters, size),
              ),
            )
            .toList()
          ..sort((a, b) => b.proj.depth.compareTo(a.proj.depth));

    final List<EchelonProjectedRiderHitbox> hitboxes = [];

    for (final entry in projected) {
      final EchelonVortexRiderNode3d rider = entry.rider;
      final EchelonProjectedPoint3d ground = entry.proj;
      final EchelonProjectedPoint3d head =
          _proj(rider.longitudinalMeters, 1.42, rider.lateralMeters, size);
      final EchelonProjectedPoint3d frontWheel =
          _proj(rider.longitudinalMeters - 0.55, 0.34, rider.lateralMeters, size);
      final EchelonProjectedPoint3d rearWheel =
          _proj(rider.longitudinalMeters + 0.55, 0.34, rider.lateralMeters, size);

      final bool isSelected = rider.id == selectedRiderId;
      final bool isHovered = rider.id == hoveredRiderId;
      final Color zoneColor = rider.isLeader
          ? AppColors.goldAccent
          : rider.effectiveZone.color;

      final double ringRx = math.max(12.0, 22.0 * ground.scale);
      final double ringRy = ringRx * 0.52;

      // Aura strefy na asfalcie
      canvas.drawOval(
        Rect.fromCenter(center: ground.offset, width: ringRx * 2, height: ringRy * 2),
        Paint()..color = zoneColor.withValues(alpha: isSelected ? 0.36 : 0.20),
      );
      canvas.drawOval(
        Rect.fromCenter(center: ground.offset, width: ringRx * 2, height: ringRy * 2),
        Paint()
          ..color = isSelected || isHovered
              ? AppColors.goldAccent
              : zoneColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.4 : 1.5,
      );

      // Koła i rama roweru 3D
      final Paint bikePaint = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.88)
        ..strokeWidth = math.max(1.5, 2.4 * ground.scale)
        ..strokeCap = StrokeCap.round;
      final double wheelRadius = math.max(4.0, 8.5 * ground.scale);
      canvas.drawCircle(
        frontWheel.offset,
        wheelRadius,
        Paint()
          ..color = AppColors.textSecondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, 2.0 * ground.scale),
      );
      canvas.drawCircle(
        rearWheel.offset,
        wheelRadius,
        Paint()
          ..color = AppColors.textSecondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, 2.0 * ground.scale),
      );
      canvas.drawLine(rearWheel.offset, frontWheel.offset, bikePaint);

      // Sylwetka kolarza + kask
      final Offset shoulder = Offset.lerp(ground.offset, head.offset, 0.72)!;
      canvas.drawLine(
        ground.offset,
        shoulder,
        Paint()
          ..color = rider.isPlayerRider ? AppColors.primaryAccent : const Color(0xFF4B5563)
          ..strokeWidth = math.max(4.0, 7.5 * ground.scale)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        head.offset,
        math.max(4.5, 6.8 * ground.scale),
        Paint()..color = rider.isPlayerRider ? AppColors.goldAccent : zoneColor,
      );

      // Wektor korekty bocznej dla kolarza w czerwonej/bursztynowej strefie
      if (data.isAeroVisionActive &&
          !rider.isLeader &&
          rider.vortexResult != null &&
          rider.vortexResult!.lateralCorrectionNeededMeters.abs() > 0.18 &&
          (isSelected ||
              isHovered ||
              rider.effectiveZone == EchelonConeZone.windwardExposed ||
              rider.effectiveZone == EchelonConeZone.directWheelMisaligned)) {
        final double targetLat = rider.lateralMeters +
            rider.vortexResult!.lateralCorrectionNeededMeters;
        final Offset targetPt =
            _proj(rider.longitudinalMeters, 0.25, targetLat, size).offset;
        final Offset startPt =
            _proj(rider.longitudinalMeters, 0.25, rider.lateralMeters, size).offset;

        canvas.drawLine(
          startPt,
          targetPt,
          Paint()
            ..color = AppColors.statusSuccess
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          targetPt,
          4.0,
          Paint()..color = AppColors.statusSuccess,
        );
      }

      // Etykieta nad kolarzem
      final String badgeText = rider.isLeader
          ? '#${rider.bibNumber} LEAD'
          : '-${rider.dragReductionPercent.toStringAsFixed(0)}%';
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: badgeText,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: math.max(9.5, 11.0 * ground.scale.clamp(0.8, 1.15)),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset pillCenter = head.offset + Offset(0, -14.0 * ground.scale.clamp(0.8, 1.2));
      final RRect pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pillCenter,
          width: tp.width + 10,
          height: tp.height + 4,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        pillRect,
        Paint()..color = AppColors.surface.withValues(alpha: 0.90),
      );
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = zoneColor.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      tp.paint(
        canvas,
        Offset(pillCenter.dx - tp.width * 0.5, pillCenter.dy - tp.height * 0.5),
      );

      hitboxes.add(
        EchelonProjectedRiderHitbox(
          rider: rider,
          center: Offset.lerp(ground.offset, head.offset, 0.5)!,
          radius: math.max(22.0, 28.0 * ground.scale),
          depth: ground.depth,
        ),
      );
    }

    return hitboxes;
  }

  @override
  bool shouldRepaint(covariant EchelonVortexCone3dPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.cameraYawDeg != cameraYawDeg ||
        oldDelegate.cameraPitchDeg != cameraPitchDeg ||
        oldDelegate.zoom != zoom ||
        oldDelegate.animationPhase != animationPhase ||
        oldDelegate.layerMode != layerMode ||
        oldDelegate.hoveredRiderId != hoveredRiderId ||
        oldDelegate.selectedRiderId != selectedRiderId ||
        oldDelegate.enabled != enabled;
  }
}

/// Interaktywny widżet 3D trybu Aero Vision wizualizujący przesunięty stożek cienia
/// aerodynamicznego na wietrze bocznym (zielona strefa optymalnego wachlarza vs czerwony rynsztok).
class EchelonVortexConeVisualizer3d extends StatefulWidget {
  final EchelonVortexConeVisualizerData data;
  final bool enabled;
  final EchelonConeCameraPreset initialCameraPreset;
  final EchelonVortexConeLayerMode initialLayerMode;
  final ValueChanged<EchelonVortexRiderNode3d>? onRiderSelected;
  final ValueChanged<bool>? onToggleWindDirection;

  const EchelonVortexConeVisualizer3d({
    super.key,
    required this.data,
    this.enabled = true,
    this.initialCameraPreset = EchelonConeCameraPreset.chase3Quarter,
    this.initialLayerMode = EchelonVortexConeLayerMode.allZones,
    this.onRiderSelected,
    this.onToggleWindDirection,
  });

  @override
  State<EchelonVortexConeVisualizer3d> createState() =>
      _EchelonVortexConeVisualizer3dState();
}

class _EchelonVortexConeVisualizer3dState
    extends State<EchelonVortexConeVisualizer3d>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late EchelonConeCameraPreset _cameraPreset;
  late EchelonVortexConeLayerMode _layerMode;
  late double _yawDeg;
  late double _pitchDeg;
  late double _zoom;

  String? _hoveredRiderId;
  String? _selectedRiderId;
  bool _viewportFocused = false;
  List<EchelonProjectedRiderHitbox> _latestHitboxes = const [];

  @override
  void initState() {
    super.initState();
    _cameraPreset = widget.initialCameraPreset;
    _layerMode = widget.initialLayerMode;
    _yawDeg = _cameraPreset.yawDeg;
    _pitchDeg = _cameraPreset.pitchDeg;
    _zoom = _cameraPreset.zoom;
    _selectedRiderId = widget.data.riders.isNotEmpty
        ? widget.data.riders.last.id
        : null;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enabled) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant EchelonVortexConeVisualizer3d oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    }
    if (_selectedRiderId != null &&
        !widget.data.riders.any((r) => r.id == _selectedRiderId)) {
      _selectedRiderId =
          widget.data.riders.isNotEmpty ? widget.data.riders.first.id : null;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyCameraPreset(EchelonConeCameraPreset preset) {
    if (!widget.enabled) return;
    setState(() {
      _cameraPreset = preset;
      _yawDeg = preset.yawDeg;
      _pitchDeg = preset.pitchDeg;
      _zoom = preset.zoom;
    });
  }

  void _selectRider(EchelonVortexRiderNode3d rider) {
    if (!widget.enabled) return;
    setState(() => _selectedRiderId = rider.id);
    widget.onRiderSelected?.call(rider);
  }

  void _cycleSelectedRider(int delta) {
    if (!widget.enabled || widget.data.riders.isEmpty) return;
    final int currentIndex = widget.data.riders
        .indexWhere((r) => r.id == _selectedRiderId);
    final int nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + delta) % widget.data.riders.length;
    final int wrapped =
        nextIndex < 0 ? widget.data.riders.length - 1 : nextIndex;
    _selectRider(widget.data.riders[wrapped]);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _cycleSelectedRider(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _cycleSelectedRider(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _applyCameraPreset(_cameraPreset);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  EchelonVortexRiderNode3d? get _activeRider {
    if (widget.data.riders.isEmpty) return null;
    return widget.data.riders.firstWhere(
      (r) => r.id == (_hoveredRiderId ?? _selectedRiderId),
      orElse: () => widget.data.riders.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1024.0;
        final bool isCompactMobile = width < 560;
        final bool isDesktopWide = width >= 980;
        final double canvasHeight = isCompactMobile
            ? 240.0
            : (isDesktopWide ? 340.0 : 290.0);

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.62,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _viewportFocused
                    ? AppColors.goldAccent
                    : AppTheme.borderColor,
                width: _viewportFocused ? 1.5 : 1.0,
              ),
            ),
            padding: EdgeInsets.all(isCompactMobile ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isCompactMobile),
                const SizedBox(height: 12),
                _buildControlsRow(isCompactMobile),
                const SizedBox(height: 12),
                if (isDesktopWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _build3dViewport(canvasHeight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _buildTelemetryInspectorPanel(isCompactMobile),
                      ),
                    ],
                  )
                else ...[
                  _build3dViewport(canvasHeight),
                  const SizedBox(height: 12),
                  _buildTelemetryInspectorPanel(isCompactMobile),
                ],
                const SizedBox(height: 10),
                _buildLegendAndRiderStrip(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompactMobile) {
    final double shiftDeg = widget.data.wakeShiftAngleDegrees;
    final String windDirLabel = widget.data.windSide.labelPl;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Row(
          children: [
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
                color: widget.enabled
                    ? AppColors.statusSuccess
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AERO VISION 3D • STOŻEK WACHLARZA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompactMobile ? 12 : 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.data.stageKmLabel} • $windDirLabel (${shiftDeg.toStringAsFixed(1)}°)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MetricBadge(
              label: 'W KIESZENI',
              value: '${widget.data.optimalConeCount}',
              color: AppColors.statusSuccess,
            ),
            _MetricBadge(
              label: 'RYNSZTOK',
              value: '${widget.data.gutterExposedCount}',
              color: AppColors.crimsonAlert,
            ),
            _MetricBadge(
              label: 'ZYSK',
              value: '+${widget.data.totalPowerSavedWatts.toStringAsFixed(0)} W',
              color: AppColors.goldAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsRow(bool isCompactMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final EchelonConeCameraPreset preset
              in EchelonConeCameraPreset.values) ...[
            _InteractiveChipButton(
              label: preset.label,
              selected: _cameraPreset == preset,
              enabled: widget.enabled,
              accentColor: AppColors.goldAccent,
              onTap: () => _applyCameraPreset(preset),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            width: 1,
            height: 22,
            color: AppTheme.borderColor,
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
          for (final EchelonVortexConeLayerMode mode
              in EchelonVortexConeLayerMode.values) ...[
            _InteractiveChipButton(
              label: isCompactMobile ? mode.labelEn : mode.labelPl,
              selected: _layerMode == mode,
              enabled: widget.enabled,
              accentColor: mode == EchelonVortexConeLayerMode.gutterExposureOnly
                  ? AppColors.crimsonAlert
                  : AppColors.statusSuccess,
              onTap: () {
                if (!widget.enabled) return;
                setState(() => _layerMode = mode);
              },
            ),
            const SizedBox(width: 6),
          ],
          if (widget.onToggleWindDirection != null) ...[
            Container(
              width: 1,
              height: 22,
              color: AppTheme.borderColor,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
            _InteractiveChipButton(
              label: widget.data.windRelativeAngleDegrees >= 0
                  ? 'Wiatr z Lewej'
                  : 'Wiatr z Prawej',
              selected: false,
              enabled: widget.enabled,
              accentColor: AppColors.accentBlue,
              onTap: () {
                if (!widget.enabled) return;
                widget.onToggleWindDirection
                    ?.call(widget.data.windRelativeAngleDegrees < 0);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _build3dViewport(double height) {
    return Focus(
      onFocusChange: (focused) => setState(() => _viewportFocused = focused),
      onKeyEvent: _handleKeyEvent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _viewportFocused
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
            ),
          ),
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.grab
                : SystemMouseCursors.forbidden,
            onHover: (PointerHoverEvent event) {
              if (!widget.enabled) return;
              final hit = EchelonVortexCone3dCalculator.hitTestRider(
                localPosition: event.localPosition,
                hitboxes: _latestHitboxes,
              );
              if (hit?.id != _hoveredRiderId) {
                setState(() => _hoveredRiderId = hit?.id);
              }
            },
            onExit: (_) {
              if (_hoveredRiderId != null) {
                setState(() => _hoveredRiderId = null);
              }
            },
            child: GestureDetector(
              onPanUpdate: widget.enabled
                  ? (DragUpdateDetails details) {
                      setState(() {
                        _yawDeg = (_yawDeg + details.delta.dx * 0.45)
                            .clamp(-85.0, 85.0);
                        _pitchDeg = (_pitchDeg + details.delta.dy * 0.35)
                            .clamp(8.0, 82.0);
                      });
                    }
                  : null,
              onTapUp: widget.enabled
                  ? (TapUpDetails details) {
                      final hit = EchelonVortexCone3dCalculator.hitTestRider(
                        localPosition: details.localPosition,
                        hitboxes: _latestHitboxes,
                      );
                      if (hit != null) {
                        _selectRider(hit);
                      }
                    }
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (BuildContext context, Widget? child) {
                      return CustomPaint(
                        painter: EchelonVortexCone3dPainter(
                          data: widget.data,
                          cameraYawDeg: _yawDeg,
                          cameraPitchDeg: _pitchDeg,
                          zoom: _zoom,
                          animationPhase: _animController.value,
                          layerMode: _layerMode,
                          hoveredRiderId: _hoveredRiderId,
                          selectedRiderId: _selectedRiderId,
                          enabled: widget.enabled,
                          onHitboxesComputed: (boxes) => _latestHitboxes = boxes,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: _ZoomControlsPill(
                      enabled: widget.enabled,
                      onZoomIn: () => setState(
                        () => _zoom = (_zoom + 0.12).clamp(0.70, 1.55),
                      ),
                      onZoomOut: () => setState(
                        () => _zoom = (_zoom - 0.12).clamp(0.70, 1.55),
                      ),
                      onReset: () => _applyCameraPreset(_cameraPreset),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryInspectorPanel(bool isCompactMobile) {
    final EchelonVortexRiderNode3d? rider = _activeRider;
    if (rider == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'Brak kolarzy w strefie wachlarza.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final Color zoneColor =
        rider.isLeader ? AppColors.goldAccent : rider.effectiveZone.color;
    final EchelonVortexResult? res = rider.vortexResult;

    return Container(
      padding: EdgeInsets.all(isCompactMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: zoneColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '#${rider.bibNumber} ${rider.name} (${rider.teamCode})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rider.isLeader
                ? 'Prowadzący wachlarz (czoło wiatru)'
                : rider.effectiveZone.labelPl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: zoneColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InspectorMetricTile(
                label: 'Redukcja oporu',
                value: rider.isLeader
                    ? '0.0%'
                    : '${rider.dragReductionPercent.toStringAsFixed(1)}%',
                valueColor: zoneColor,
              ),
              _InspectorMetricTile(
                label: 'Zysk mocy',
                value: rider.isLeader
                    ? '0 W'
                    : '+${rider.powerSavedWatts.toStringAsFixed(0)} W',
                valueColor: AppColors.textPrimary,
              ),
              _InspectorMetricTile(
                label: 'Efekt. CdA',
                value: res == null
                    ? '0.320 m²'
                    : '${res.effectiveCdA.toStringAsFixed(3)} m²',
                valueColor: AppColors.accentBlue,
              ),
              _InspectorMetricTile(
                label: 'Korekta boczna',
                value: res == null
                    ? '—'
                    : '${res.lateralCorrectionNeededMeters >= 0 ? '+' : ''}${res.lateralCorrectionNeededMeters.toStringAsFixed(2)} m',
                valueColor: res != null &&
                        res.lateralCorrectionNeededMeters.abs() > 0.25
                    ? AppColors.amberWarning
                    : AppColors.statusSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendAndRiderStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _LegendDot(
              color: AppColors.statusSuccess,
              label: 'Zielona strefa: optymalny stożek (30–38% oszczędności)',
            ),
            _LegendDot(
              color: AppColors.crimsonAlert,
              label: 'Czerwona strefa: ekspozycja w rynsztoku (<10%)',
            ),
            _LegendDot(
              color: AppColors.amberWarning,
              label: 'Błąd: bezpośrednio za kołem (~12%)',
            ),
          ],
        ),
        if (widget.data.riders.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final EchelonVortexRiderNode3d rider
                    in widget.data.riders) ...[
                  _InteractiveChipButton(
                    label: '#${rider.bibNumber} ${rider.teamCode}',
                    selected: rider.id == _selectedRiderId,
                    enabled: widget.enabled,
                    accentColor: rider.isLeader
                        ? AppColors.goldAccent
                        : rider.effectiveZone.color,
                    onTap: () => _selectRider(rider),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveChipButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : widget.selected || _focused
            ? widget.accentColor
            : (_hovered ? widget.accentColor.withValues(alpha: 0.65) : AppTheme.borderColor);

    final Color bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.selected
            ? widget.accentColor.withValues(alpha: 0.18)
            : (_pressed
                ? AppColors.surfaceLight
                : (_hovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.background));

    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: (node, event) {
        if (widget.enabled &&
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: !widget.enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
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

class _ZoomControlsPill extends StatelessWidget {
  final bool enabled;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _ZoomControlsPill({
    required this.enabled,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: enabled ? onZoomOut : null,
            icon: const Icon(Icons.remove, size: 16),
            tooltip: 'Oddal kamerę',
            visualDensity: VisualDensity.compact,
            color: AppColors.textPrimary,
          ),
          IconButton(
            onPressed: enabled ? onReset : null,
            icon: const Icon(Icons.center_focus_strong, size: 15),
            tooltip: 'Resetuj kamerę (R)',
            visualDensity: VisualDensity.compact,
            color: AppColors.goldAccent,
          ),
          IconButton(
            onPressed: enabled ? onZoomIn : null,
            icon: const Icon(Icons.add, size: 16),
            tooltip: 'Przybliż kamerę',
            visualDensity: VisualDensity.compact,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _InspectorMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InspectorMetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
