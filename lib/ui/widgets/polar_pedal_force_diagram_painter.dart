// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/pedal_stroke_biomechanics_analyzer.dart';
import '../../models/rider/rider.dart';

/// Tryb prezentacji techniki pedałowania na wykresie kołowym (Polar View).
enum PolarPedalingTechniqueMode {
  activeRider(
    'Profil Kolarza',
    'Rzeczywista krzywa siły na korbie dla wybranego zawodnika.',
  ),
  climberSmoothSpin(
    'Góral: Okrągłe Pedałowanie',
    'Płynne przejście przez martwe punkty 0° i 180° przy wysokiej kadencji.',
  ),
  sprinterPowerMash(
    'Sprinter: Siłowe Depnięcie',
    'Ekstremalny pik siły w fazie 75°–115° z wyraźnym przewężeniem w 0°/180°.',
  ),
  climberVsSprinterComparison(
    'Porównanie: Góral vs Sprinter',
    'Nałożenie okrągłego pedałowania górala na siłowe depnięcie sprintera.',
  );

  final String label;
  final String description;

  const PolarPedalingTechniqueMode(this.label, this.description);
}

/// Zestaw wyliczonych metryk dla wykresu kołowego (Peanut Diagram).
class PolarPedalDiagramMetrics {
  final double deadZoneForceN;
  final double peakCombinedForceN;
  final double deadToPeakRatioPercent;
  final double torqueEffectivenessPercent;
  final double pedalSmoothnessPercent;
  final double leftBalancePercent;
  final double rightBalancePercent;

  const PolarPedalDiagramMetrics({
    required this.deadZoneForceN,
    required this.peakCombinedForceN,
    required this.deadToPeakRatioPercent,
    required this.torqueEffectivenessPercent,
    required this.pedalSmoothnessPercent,
    required this.leftBalancePercent,
    required this.rightBalancePercent,
  });
}

/// Kalkulator profili biomechanicznych i metryk wykresu Polar View.
class PolarPedalForceDiagramCalculator {
  static const PedalStrokeBiomechanicsAnalyzer _analyzer =
      PedalStrokeBiomechanicsAnalyzer();

  const PolarPedalForceDiagramCalculator._();

  /// Wylicza połączoną siłę styczną obu nóg dla zadanego kąta korby $\theta \in [0, 359]$.
  /// Lewa korba znajduje się na $\theta$, a prawa na $(\theta + 180) \bmod 360$.
  static double combinedForceAtAngle(
    PedalStrokeAnalysisResult result,
    int angleDeg,
  ) {
    if (result.samples.isEmpty) return 0.0;
    final int leftIdx = ((angleDeg % 360) + 360) % 360;
    final int rightIdx = (leftIdx + 180) % 360;
    final double leftN = math.max(0.0, result.samples[leftIdx].leftTangentialForceN);
    final double rightN =
        math.max(0.0, result.samples[rightIdx].rightTangentialForceN);
    return leftN + rightN;
  }

  /// Buduje wynik analizy dla wybranego kolarza (lub domyślnego profilu WorldTour).
  static PedalStrokeAnalysisResult analyzeForRider({
    Rider? rider,
    double? overridePowerWatts,
    double? overrideCadenceRpm,
  }) {
    if (rider == null) {
      return _analyzer.analyze(
        PedalStrokeAnalysisInput(
          targetPowerWatts: overridePowerWatts ?? 360.0,
          cadenceRpm: overrideCadenceRpm ?? 90.0,
          crankLengthMm: 172.5,
          posture: PedalingPosture.seatedNormal,
          fatigueLevel: 0.15,
          techniqueSkill: 0.85,
        ),
      );
    }

    final bool isSprinter =
        rider.specialization == RiderSpecialization.pureSprinter ||
            rider.specialization == RiderSpecialization.versatileSprinter;
    final bool isClimber =
        rider.specialization == RiderSpecialization.pureClimber ||
            rider.specialization == RiderSpecialization.gcClimber;

    final double defaultPower = isSprinter
        ? (rider.powerProfile.watts5s * 0.72).clamp(480.0, 1400.0)
        : rider.physiology.ftpWatts.toDouble().clamp(220.0, 520.0);
    final double defaultCadence = isClimber ? 92.0 : (isSprinter ? 104.0 : 88.0);
    final double skill = isClimber
        ? 0.94
        : (isSprinter ? 0.68 : 0.84);
    final PedalingPosture posture = isSprinter
        ? PedalingPosture.standingOutOfSaddle
        : (isClimber
            ? PedalingPosture.seatedClimbing
            : PedalingPosture.seatedNormal);

    return _analyzer.analyze(
      PedalStrokeAnalysisInput(
        targetPowerWatts: overridePowerWatts ?? defaultPower,
        cadenceRpm: overrideCadenceRpm ?? defaultCadence,
        crankLengthMm: isClimber ? 170.0 : 172.5,
        posture: posture,
        fatigueLevel: (rider.physiology.fatigue / 100.0).clamp(0.0, 0.9),
        techniqueSkill: skill,
      ),
    );
  }

  /// Profil referencyjny: "Okrągłe pedałowanie" górala.
  static PedalStrokeAnalysisResult analyzeClimberSmoothSpin({
    double? powerWatts,
    double? cadenceRpm,
  }) {
    return _analyzer.analyze(
      PedalStrokeAnalysisInput(
        targetPowerWatts: powerWatts ?? 385.0,
        cadenceRpm: cadenceRpm ?? 94.0,
        crankLengthMm: 170.0,
        posture: PedalingPosture.seatedClimbing,
        fatigueLevel: 0.10,
        techniqueSkill: 0.98,
        naturalRightDominanceBias: 0.004,
      ),
    );
  }

  /// Profil referencyjny: "Siłowe depnięcie" sprintera.
  static PedalStrokeAnalysisResult analyzeSprinterPowerMash({
    double? powerWatts,
    double? cadenceRpm,
  }) {
    return _analyzer.analyze(
      PedalStrokeAnalysisInput(
        targetPowerWatts: powerWatts ?? 980.0,
        cadenceRpm: cadenceRpm ?? 96.0,
        crankLengthMm: 175.0,
        posture: PedalingPosture.standingOutOfSaddle,
        fatigueLevel: 0.25,
        techniqueSkill: 0.52,
        naturalRightDominanceBias: 0.016,
      ),
    );
  }

  /// Oblicza zwięzłe metryki martwych punktów ($0^\circ / 180^\circ$) i szczytu siły.
  static PolarPedalDiagramMetrics computeMetrics(
    PedalStrokeAnalysisResult result,
  ) {
    if (result.samples.isEmpty) {
      return const PolarPedalDiagramMetrics(
        deadZoneForceN: 0.0,
        peakCombinedForceN: 0.0,
        deadToPeakRatioPercent: 0.0,
        torqueEffectivenessPercent: 0.0,
        pedalSmoothnessPercent: 0.0,
        leftBalancePercent: 50.0,
        rightBalancePercent: 50.0,
      );
    }

    final double f0 = combinedForceAtAngle(result, 0);
    final double f180 = combinedForceAtAngle(result, 180);
    final double deadZoneAvg = (f0 + f180) * 0.5;

    double peakCombined = 0.0;
    for (int deg = 0; deg < 360; deg++) {
      final double f = combinedForceAtAngle(result, deg);
      if (f > peakCombined) peakCombined = f;
    }

    final double ratio = peakCombined > 0.001
        ? (deadZoneAvg / peakCombined) * 100.0
        : 0.0;

    return PolarPedalDiagramMetrics(
      deadZoneForceN: deadZoneAvg,
      peakCombinedForceN: peakCombined,
      deadToPeakRatioPercent: ratio,
      torqueEffectivenessPercent: result.combinedTorqueEffectivenessPercent,
      pedalSmoothnessPercent: result.combinedPedalSmoothnessPercent,
      leftBalancePercent: result.leftBalancePercent,
      rightBalancePercent: result.rightBalancePercent,
    );
  }
}

/// Wykres kołowy (Polar View / "Peanut Diagram") rysujący w czasie rzeczywistym
/// wektory siły nacisku na pedały w zakresie $0^\circ–360^\circ$, martwe punkty
/// ($0^\circ$ i $180^\circ$) oraz porównanie techniki pedałowania.
class PolarPedalForceDiagramPainter extends CustomPainter {
  final PedalStrokeAnalysisResult primaryResult;
  final PedalStrokeAnalysisResult? comparisonResult;
  final double crankAngleDeg;
  final double? hoveredAngleDeg;
  final bool showForceVectors;
  final bool showDeadZones;
  final bool showComparison;
  final bool isDisabled;
  final Color primaryColor;
  final Color comparisonColor;
  final String primaryLabel;
  final String comparisonLabel;

  const PolarPedalForceDiagramPainter({
    required this.primaryResult,
    this.comparisonResult,
    required this.crankAngleDeg,
    this.hoveredAngleDeg,
    this.showForceVectors = true,
    this.showDeadZones = true,
    this.showComparison = true,
    this.isDisabled = false,
    this.primaryColor = AppColors.cyanAccent,
    this.comparisonColor = AppColors.crimsonAlert,
    this.primaryLabel = 'Profil Główny',
    this.comparisonLabel = 'Porównanie',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double minDim = math.min(size.width, size.height);
    if (minDim < 40) return;

    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    final double outerRadius = (minDim * 0.5) - 34.0;
    if (outerRadius <= 20.0) return;

    final double opacityScale = isDisabled ? 0.42 : 1.0;

    // 1. Wyznaczenie skali maksymalnej siły [N] dla obu krzywych.
    double maxForceN = 100.0;
    for (int deg = 0; deg < 360; deg += 3) {
      maxForceN = math.max(
        maxForceN,
        PolarPedalForceDiagramCalculator.combinedForceAtAngle(primaryResult, deg),
      );
      if (comparisonResult != null && showComparison) {
        maxForceN = math.max(
          maxForceN,
          PolarPedalForceDiagramCalculator.combinedForceAtAngle(
            comparisonResult!,
            deg,
          ),
        );
      }
    }
    // Zaokrąglenie górne do ładnego kroku co 100 N.
    final double scaleMaxN = (maxForceN / 100.0).ceil() * 100.0;

    // 2. Siatka polarna: koncentryczne okręgi oraz szprychy co 30°.
    _drawPolarGrid(canvas, center, outerRadius, scaleMaxN, opacityScale);

    // 3. Strefy martwych punktów (0° TDC oraz 180° BDC ±15°).
    if (showDeadZones) {
      _drawDeadZones(canvas, center, outerRadius, opacityScale);
    }

    // 4. Krzywa porównawcza (np. Sprinter: siłowe depnięcie), jeśli aktywna.
    if (comparisonResult != null && showComparison) {
      _drawPeanutCurve(
        canvas: canvas,
        center: center,
        outerRadius: outerRadius,
        scaleMaxN: scaleMaxN,
        result: comparisonResult!,
        color: comparisonColor.withValues(alpha: opacityScale),
        fillAlpha: 0.14,
        strokeWidth: 2.2,
        dashed: true,
      );
    }

    // 5. Główna krzywa Peanut Diagram.
    _drawPeanutCurve(
      canvas: canvas,
      center: center,
      outerRadius: outerRadius,
      scaleMaxN: scaleMaxN,
      result: primaryResult,
      color: primaryColor.withValues(alpha: opacityScale),
      fillAlpha: 0.22,
      strokeWidth: 2.8,
      dashed: false,
    );

    // 6. Wektory siły nacisku na pedały wokół całego zakresu 0°–360°.
    if (showForceVectors) {
      _drawForceVectorsField(
        canvas: canvas,
        center: center,
        outerRadius: outerRadius,
        scaleMaxN: scaleMaxN,
        result: primaryResult,
        opacityScale: opacityScale,
      );
    }

    // 7. Obracająca się w czasie rzeczywistym korba L/R + chwilowy wektor styczny.
    _drawLiveCrankAndInstantVector(
      canvas: canvas,
      center: center,
      outerRadius: outerRadius,
      scaleMaxN: scaleMaxN,
      opacityScale: opacityScale,
    );

    // 8. Kursor inspekcji kątowej (hover / scrub).
    if (hoveredAngleDeg != null && !isDisabled) {
      _drawHoverInspector(
        canvas: canvas,
        size: size,
        center: center,
        outerRadius: outerRadius,
        scaleMaxN: scaleMaxN,
        angleDeg: hoveredAngleDeg!,
      );
    }
  }

  double _degToCanvasRad(double deg) => (deg - 90.0) * math.pi / 180.0;

  void _drawPolarGrid(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double scaleMaxN,
    double opacityScale,
  ) {
    final Paint ringPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.65 * opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint outerRingPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.95 * opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const List<double> ringFractions = [0.25, 0.50, 0.75, 1.0];
    for (final double frac in ringFractions) {
      final double r = outerRadius * frac;
      canvas.drawCircle(
        center,
        r,
        frac == 1.0 ? outerRingPaint : ringPaint,
      );

      final int newtonLabel = (scaleMaxN * frac).round();
      _drawText(
        canvas,
        '$newtonLabel N',
        Offset(center.dx + 4.0, center.dy - r + 2.0),
        TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary.withValues(alpha: 0.75 * opacityScale),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }

    final Paint spokePaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.45 * opacityScale)
      ..strokeWidth = 0.9;

    for (int deg = 0; deg < 360; deg += 30) {
      final double rad = _degToCanvasRad(deg.toDouble());
      final Offset end = Offset(
        center.dx + outerRadius * math.cos(rad),
        center.dy + outerRadius * math.sin(rad),
      );
      canvas.drawLine(center, end, spokePaint);

      // Etykiety kątów na zewnątrz okręgu.
      final bool isCardinal = deg % 90 == 0;
      final double labelRadius = outerRadius + (isCardinal ? 18.0 : 15.0);
      final Offset labelPos = Offset(
        center.dx + labelRadius * math.cos(rad),
        center.dy + labelRadius * math.sin(rad),
      );
      _drawCenteredText(
        canvas,
        '$deg°',
        labelPos,
        TextStyle(
          fontFamily: 'Inter',
          fontSize: isCardinal ? 11.5 : 9.5,
          fontWeight: isCardinal ? FontWeight.w800 : FontWeight.w500,
          color: isCardinal
              ? AppColors.textPrimary.withValues(alpha: opacityScale)
              : AppColors.textSecondary.withValues(alpha: 0.75 * opacityScale),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    }
  }

  void _drawDeadZones(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double opacityScale,
  ) {
    final Paint sectorFill = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.11 * opacityScale)
      ..style = PaintingStyle.fill;

    final Paint sectorBorder = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: 0.55 * opacityScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Rect oval = Rect.fromCircle(center: center, radius: outerRadius);
    const double sweepAngle = 30.0 * math.pi / 180.0; // ±15° wokół 0° i 180°

    // 0° TDC (górny martwy punkt)
    final double tdcStart = _degToCanvasRad(-15.0);
    canvas.drawArc(oval, tdcStart, sweepAngle, true, sectorFill);
    canvas.drawArc(oval, tdcStart, sweepAngle, true, sectorBorder);

    // 180° BDC (dolny martwy punkt)
    final double bdcStart = _degToCanvasRad(165.0);
    canvas.drawArc(oval, bdcStart, sweepAngle, true, sectorFill);
    canvas.drawArc(oval, bdcStart, sweepAngle, true, sectorBorder);

    // Pigułki opisowe TDC / BDC.
    _drawBadge(
      canvas,
      Offset(center.dx, center.dy - outerRadius * 0.86),
      'TDC 0° MARTWY',
      AppColors.amberWarning.withValues(alpha: opacityScale),
    );
    _drawBadge(
      canvas,
      Offset(center.dx, center.dy + outerRadius * 0.86),
      'BDC 180° MARTWY',
      AppColors.amberWarning.withValues(alpha: opacityScale),
    );
  }

  void _drawPeanutCurve({
    required Canvas canvas,
    required Offset center,
    required double outerRadius,
    required double scaleMaxN,
    required PedalStrokeAnalysisResult result,
    required Color color,
    required double fillAlpha,
    required double strokeWidth,
    required bool dashed,
  }) {
    final Path path = Path();
    for (int deg = 0; deg < 360; deg += 2) {
      final double force =
          PolarPedalForceDiagramCalculator.combinedForceAtAngle(result, deg);
      final double r =
          ((force / scaleMaxN).clamp(0.03, 1.0)) * outerRadius;
      final double rad = _degToCanvasRad(deg.toDouble());
      final Offset pt = Offset(
        center.dx + r * math.cos(rad),
        center.dy + r * math.sin(rad),
      );
      if (deg == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    if (!dashed) {
      canvas.drawPath(path, strokePaint);
    } else {
      // Rysowanie przerywanej obwiedni porównawczej.
      for (final metric in path.computeMetrics()) {
        double distance = 0.0;
        const double dashLength = 7.0;
        const double gapLength = 4.5;
        while (distance < metric.length) {
          final double next = math.min(distance + dashLength, metric.length);
          canvas.drawPath(metric.extractPath(distance, next), strokePaint);
          distance += dashLength + gapLength;
        }
      }
    }
  }

  void _drawForceVectorsField({
    required Canvas canvas,
    required Offset center,
    required double outerRadius,
    required double scaleMaxN,
    required PedalStrokeAnalysisResult result,
    required double opacityScale,
  }) {
    final double baseCrankR = outerRadius * 0.22;

    for (int deg = 0; deg < 360; deg += 15) {
      final double force =
          PolarPedalForceDiagramCalculator.combinedForceAtAngle(result, deg);
      final double norm = (force / scaleMaxN).clamp(0.0, 1.0);
      final double targetR = math.max(baseCrankR + 4.0, norm * outerRadius);
      final double rad = _degToCanvasRad(deg.toDouble());

      final Offset start = Offset(
        center.dx + baseCrankR * math.cos(rad),
        center.dy + baseCrankR * math.sin(rad),
      );
      final Offset tip = Offset(
        center.dx + targetR * math.cos(rad),
        center.dy + targetR * math.sin(rad),
      );

      final Color vecColor = Color.lerp(
        AppColors.statusSuccess,
        AppColors.goldAccent,
        norm,
      )!
          .withValues(alpha: 0.72 * opacityScale);

      final Paint linePaint = Paint()
        ..color = vecColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, tip, linePaint);

      // Grot wektora.
      _drawArrowHead(
        canvas: canvas,
        tip: tip,
        directionRad: rad,
        size: 5.0,
        color: vecColor,
      );
    }
  }

  void _drawLiveCrankAndInstantVector({
    required Canvas canvas,
    required Offset center,
    required double outerRadius,
    required double scaleMaxN,
    required double opacityScale,
  }) {
    final double crankR = outerRadius * 0.28;
    final double leftRad = _degToCanvasRad(crankAngleDeg);
    final double rightRad = _degToCanvasRad(crankAngleDeg + 180.0);

    final Offset leftPedal = Offset(
      center.dx + crankR * math.cos(leftRad),
      center.dy + crankR * math.sin(leftRad),
    );
    final Offset rightPedal = Offset(
      center.dx + crankR * math.cos(rightRad),
      center.dy + crankR * math.sin(rightRad),
    );

    // Ramię korby L/R.
    canvas.drawLine(
      center,
      rightPedal,
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.75 * opacityScale)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      leftPedal,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: opacityScale)
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );

    // Oś suportu.
    canvas.drawCircle(
      center,
      6.5,
      Paint()..color = AppColors.surfaceLight.withValues(alpha: opacityScale),
    );
    canvas.drawCircle(
      center,
      6.5,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: opacityScale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Pedały (punkty).
    canvas.drawCircle(
      rightPedal,
      4.5,
      Paint()..color = AppColors.accentBlue.withValues(alpha: opacityScale),
    );
    canvas.drawCircle(
      leftPedal,
      5.5,
      Paint()..color = AppColors.goldAccent.withValues(alpha: opacityScale),
    );

    // Chwilowy wektor siły stycznej (prostopadły do ramienia korby) na lewym pedale.
    final int idx = ((crankAngleDeg.round() % 360) + 360) % 360;
    final double instantForceN = primaryResult.samples.isNotEmpty
        ? math.max(0.0, primaryResult.samples[idx].leftTangentialForceN)
        : 0.0;
    final double vectorLen =
        ((instantForceN / scaleMaxN).clamp(0.05, 1.0)) * (outerRadius * 0.55);

    // Kierunek styczny (zgodny z ruchem wskazówek zegara: rad + pi/2).
    final double tangentRad = leftRad + math.pi * 0.5;
    final Offset tangentTip = Offset(
      leftPedal.dx + vectorLen * math.cos(tangentRad),
      leftPedal.dy + vectorLen * math.sin(tangentRad),
    );

    final Paint instantPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacityScale)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(leftPedal, tangentTip, instantPaint);
    _drawArrowHead(
      canvas: canvas,
      tip: tangentTip,
      directionRad: tangentRad,
      size: 7.5,
      color: primaryColor.withValues(alpha: opacityScale),
    );
  }

  void _drawHoverInspector({
    required Canvas canvas,
    required Size size,
    required Offset center,
    required double outerRadius,
    required double scaleMaxN,
    required double angleDeg,
  }) {
    final int deg = ((angleDeg.round() % 360) + 360) % 360;
    final double rad = _degToCanvasRad(deg.toDouble());

    final Offset rayEnd = Offset(
      center.dx + outerRadius * math.cos(rad),
      center.dy + outerRadius * math.sin(rad),
    );
    canvas.drawLine(
      center,
      rayEnd,
      Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.75)
        ..strokeWidth = 1.3,
    );

    final double fPrimary =
        PolarPedalForceDiagramCalculator.combinedForceAtAngle(primaryResult, deg);
    final double rPrimary =
        ((fPrimary / scaleMaxN).clamp(0.03, 1.0)) * outerRadius;
    final Offset ptPrimary = Offset(
      center.dx + rPrimary * math.cos(rad),
      center.dy + rPrimary * math.sin(rad),
    );
    canvas.drawCircle(ptPrimary, 5.5, Paint()..color = primaryColor);
    canvas.drawCircle(
      ptPrimary,
      5.5,
      Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    String tooltipText = '$deg°  •  ${fPrimary.toStringAsFixed(0)} N';
    if (comparisonResult != null && showComparison) {
      final double fComp = PolarPedalForceDiagramCalculator.combinedForceAtAngle(
        comparisonResult!,
        deg,
      );
      final double rComp =
          ((fComp / scaleMaxN).clamp(0.03, 1.0)) * outerRadius;
      final Offset ptComp = Offset(
        center.dx + rComp * math.cos(rad),
        center.dy + rComp * math.sin(rad),
      );
      canvas.drawCircle(ptComp, 4.5, Paint()..color = comparisonColor);
      tooltipText =
          '$deg°  •  ${fPrimary.toStringAsFixed(0)} N vs ${fComp.toStringAsFixed(0)} N';
    }

    _drawBadge(
      canvas,
      Offset(center.dx, 14.0),
      tooltipText,
      AppColors.goldAccent,
    );
  }

  void _drawArrowHead({
    required Canvas canvas,
    required Offset tip,
    required double directionRad,
    required double size,
    required Color color,
  }) {
    const double spread = 0.45;
    final Offset p1 = Offset(
      tip.dx - size * math.cos(directionRad - spread),
      tip.dy - size * math.sin(directionRad - spread),
    );
    final Offset p2 = Offset(
      tip.dx - size * math.cos(directionRad + spread),
      tip.dy - size * math.sin(directionRad + spread),
    );
    final Path arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5),
    );
  }

  void _drawBadge(
    Canvas canvas,
    Offset center,
    String label,
    Color accentColor,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: accentColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Rect rect = Rect.fromCenter(
      center: center,
      width: tp.width + 12.0,
      height: tp.height + 6.0,
    );
    final RRect rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(
      rRect,
      Paint()..color = AppColors.background.withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = accentColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    tp.paint(
      canvas,
      Offset(center.dx - tp.width * 0.5, center.dy - tp.height * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant PolarPedalForceDiagramPainter oldDelegate) {
    return oldDelegate.crankAngleDeg != crankAngleDeg ||
        oldDelegate.hoveredAngleDeg != hoveredAngleDeg ||
        oldDelegate.primaryResult != primaryResult ||
        oldDelegate.comparisonResult != comparisonResult ||
        oldDelegate.showForceVectors != showForceVectors ||
        oldDelegate.showDeadZones != showDeadZones ||
        oldDelegate.showComparison != showComparison ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.comparisonColor != comparisonColor;
  }
}

/// Produkcyjny widget karty wykresu kołowego (Polar View / "Peanut Diagram")
/// do osadzenia w Laboratorium Wydolnościowym oraz Profilu Kolarza.
class PolarPedalForceDiagramWidget extends StatefulWidget {
  final Rider? rider;
  final PolarPedalingTechniqueMode initialMode;
  final bool isDisabled;
  final bool autoAnimate;

  const PolarPedalForceDiagramWidget({
    super.key,
    this.rider,
    this.initialMode = PolarPedalingTechniqueMode.climberVsSprinterComparison,
    this.isDisabled = false,
    this.autoAnimate = true,
  });

  @override
  State<PolarPedalForceDiagramWidget> createState() =>
      _PolarPedalForceDiagramWidgetState();
}

class _PolarPedalForceDiagramWidgetState
    extends State<PolarPedalForceDiagramWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _crankController;
  late PolarPedalingTechniqueMode _mode;

  bool _isPlaying = true;
  bool _showForceVectors = true;
  bool _showDeadZones = true;
  bool _showComparison = true;

  double _powerWatts = 385.0;
  double _cadenceRpm = 92.0;
  double? _hoveredAngleDeg;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _isPlaying = widget.autoAnimate && !widget.isDisabled;
    _syncDefaultsFromRider();

    _crankController = AnimationController(
      vsync: this,
      duration: _durationForCadence(_cadenceRpm),
    );
    if (_isPlaying) {
      _crankController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PolarPedalForceDiagramWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rider?.id != widget.rider?.id) {
      _syncDefaultsFromRider();
    }
    if (oldWidget.isDisabled != widget.isDisabled) {
      if (widget.isDisabled) {
        _crankController.stop();
      } else if (_isPlaying) {
        _crankController.repeat();
      }
    }
  }

  void _syncDefaultsFromRider() {
    final rider = widget.rider;
    if (rider != null) {
      _powerWatts = rider.physiology.ftpWatts.toDouble().clamp(180.0, 1400.0);
      _cadenceRpm =
          (rider.specialization == RiderSpecialization.pureClimber ||
                  rider.specialization == RiderSpecialization.gcClimber)
              ? 94.0
              : 90.0;
    }
  }

  Duration _durationForCadence(double rpm) {
    final double clampedRpm = rpm.clamp(40.0, 130.0);
    final int ms = (60000.0 / clampedRpm).round();
    return Duration(milliseconds: ms);
  }

  void _updateCadence(double newRpm) {
    setState(() {
      _cadenceRpm = newRpm;
    });
    _crankController.duration = _durationForCadence(newRpm);
    if (_isPlaying && !widget.isDisabled) {
      _crankController.repeat();
    }
  }

  void _togglePlayPause() {
    if (widget.isDisabled) return;
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _crankController.repeat();
      } else {
        _crankController.stop();
      }
    });
  }

  @override
  void dispose() {
    _crankController.dispose();
    super.dispose();
  }

  void _handlePointerAngle(Offset localPos, Size boxSize) {
    if (widget.isDisabled) return;
    final Offset center = Offset(boxSize.width * 0.5, boxSize.height * 0.5);
    final Offset delta = localPos - center;
    if (delta.distance < 8.0) return;

    double angleDeg = (math.atan2(delta.dy, delta.dx) * 180.0 / math.pi) + 90.0;
    if (angleDeg < 0) angleDeg += 360.0;
    setState(() {
      _hoveredAngleDeg = angleDeg % 360.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ({
      PedalStrokeAnalysisResult primary,
      PedalStrokeAnalysisResult? comparison,
      String primaryName,
      String comparisonName,
      Color primaryColor,
      Color comparisonColor,
    }) data = _resolveModeData();

    final PolarPedalDiagramMetrics primaryMetrics =
        PolarPedalForceDiagramCalculator.computeMetrics(data.primary);
    final PolarPedalDiagramMetrics? compMetrics = data.comparison != null
        ? PolarPedalForceDiagramCalculator.computeMetrics(data.comparison!)
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 820;
          final bool isCompact = constraints.maxWidth < 480;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 12),
              _buildModeSelector(),
              const SizedBox(height: 14),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildPolarCanvasBox(
                        data: data,
                        diagramHeight: 330,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 6,
                      child: _buildControlsAndMetricsColumn(
                        data: data,
                        primaryMetrics: primaryMetrics,
                        compMetrics: compMetrics,
                        isCompact: false,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPolarCanvasBox(
                      data: data,
                      diagramHeight: isCompact ? 270 : 310,
                    ),
                    const SizedBox(height: 14),
                    _buildControlsAndMetricsColumn(
                      data: data,
                      primaryMetrics: primaryMetrics,
                      compMetrics: compMetrics,
                      isCompact: isCompact,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  ({
    PedalStrokeAnalysisResult primary,
    PedalStrokeAnalysisResult? comparison,
    String primaryName,
    String comparisonName,
    Color primaryColor,
    Color comparisonColor,
  }) _resolveModeData() {
    switch (_mode) {
      case PolarPedalingTechniqueMode.activeRider:
        final riderName = widget.rider != null
            ? '${widget.rider!.firstName} ${widget.rider!.lastName}'
            : 'Aktywny Kolarz';
        return (
          primary: PolarPedalForceDiagramCalculator.analyzeForRider(
            rider: widget.rider,
            overridePowerWatts: _powerWatts,
            overrideCadenceRpm: _cadenceRpm,
          ),
          comparison: null,
          primaryName: riderName,
          comparisonName: '',
          primaryColor: AppColors.goldAccent,
          comparisonColor: AppColors.crimsonAlert,
        );
      case PolarPedalingTechniqueMode.climberSmoothSpin:
        return (
          primary: PolarPedalForceDiagramCalculator.analyzeClimberSmoothSpin(
            powerWatts: _powerWatts,
            cadenceRpm: _cadenceRpm,
          ),
          comparison: null,
          primaryName: 'Góral (Okrągłe Pedałowanie)',
          comparisonName: '',
          primaryColor: AppColors.cyanAccent,
          comparisonColor: AppColors.crimsonAlert,
        );
      case PolarPedalingTechniqueMode.sprinterPowerMash:
        return (
          primary: PolarPedalForceDiagramCalculator.analyzeSprinterPowerMash(
            powerWatts: math.max(_powerWatts, 680.0),
            cadenceRpm: _cadenceRpm,
          ),
          comparison: null,
          primaryName: 'Sprinter (Siłowe Depnięcie)',
          comparisonName: '',
          primaryColor: AppColors.primaryAccent,
          comparisonColor: AppColors.cyanAccent,
        );
      case PolarPedalingTechniqueMode.climberVsSprinterComparison:
        return (
          primary: PolarPedalForceDiagramCalculator.analyzeClimberSmoothSpin(
            powerWatts: _powerWatts,
            cadenceRpm: _cadenceRpm,
          ),
          comparison: PolarPedalForceDiagramCalculator.analyzeSprinterPowerMash(
            powerWatts: math.max(_powerWatts * 2.1, 860.0),
            cadenceRpm: _cadenceRpm,
          ),
          primaryName: 'Góral (Okrągłe)',
          comparisonName: 'Sprinter (Depnięcie)',
          primaryColor: AppColors.cyanAccent,
          comparisonColor: AppColors.crimsonAlert,
        );
    }
  }

  Widget _buildHeader(bool isCompact) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyanAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.cyanAccent.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: AppColors.cyanAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'WYKRES KOŁOWY SIŁY NA PEDAŁY (PEANUT DIAGRAM 0°–360°)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _mode.description,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    );

    final playButton = _InteractiveActionButton(
      icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      label: _isPlaying ? 'Pauza' : 'Start',
      isActive: _isPlaying,
      isDisabled: widget.isDisabled,
      onPressed: _togglePlayPause,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: playButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        playButton,
      ],
    );
  }

  Widget _buildModeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PolarPedalingTechniqueMode.values.map((mode) {
        final bool selected = _mode == mode;
        return _InteractiveChip(
          label: mode.label,
          isSelected: selected,
          isDisabled: widget.isDisabled,
          onTap: () {
            setState(() {
              _mode = mode;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPolarCanvasBox({
    required ({
      PedalStrokeAnalysisResult primary,
      PedalStrokeAnalysisResult? comparison,
      String primaryName,
      String comparisonName,
      Color primaryColor,
      Color comparisonColor,
    }) data,
    required double diagramHeight,
  }) {
    return Container(
      height: diagramHeight,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          final Size canvasSize = Size(
            boxConstraints.maxWidth,
            boxConstraints.maxHeight,
          );
          return MouseRegion(
            onHover: (event) => _handlePointerAngle(event.localPosition, canvasSize),
            onExit: (_) {
              if (_hoveredAngleDeg != null) {
                setState(() => _hoveredAngleDeg = null);
              }
            },
            child: GestureDetector(
              onTapDown: (details) =>
                  _handlePointerAngle(details.localPosition, canvasSize),
              onPanUpdate: (details) =>
                  _handlePointerAngle(details.localPosition, canvasSize),
              child: AnimatedBuilder(
                animation: _crankController,
                builder: (context, _) {
                  final double crankAngle = _crankController.value * 360.0;
                  return CustomPaint(
                    size: canvasSize,
                    painter: PolarPedalForceDiagramPainter(
                      primaryResult: data.primary,
                      comparisonResult: data.comparison,
                      crankAngleDeg: crankAngle,
                      hoveredAngleDeg: _hoveredAngleDeg,
                      showForceVectors: _showForceVectors,
                      showDeadZones: _showDeadZones,
                      showComparison: _showComparison,
                      isDisabled: widget.isDisabled,
                      primaryColor: data.primaryColor,
                      comparisonColor: data.comparisonColor,
                      primaryLabel: data.primaryName,
                      comparisonLabel: data.comparisonName,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsAndMetricsColumn({
    required ({
      PedalStrokeAnalysisResult primary,
      PedalStrokeAnalysisResult? comparison,
      String primaryName,
      String comparisonName,
      Color primaryColor,
      Color comparisonColor,
    }) data,
    required PolarPedalDiagramMetrics primaryMetrics,
    required PolarPedalDiagramMetrics? compMetrics,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Legenda serii
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _buildLegendDot(data.primaryName, data.primaryColor),
            if (data.comparison != null && _showComparison)
              _buildLegendDot(data.comparisonName, data.comparisonColor),
            if (_showDeadZones)
              _buildLegendDot('Martwe punkty (0° / 180°)', AppColors.amberWarning),
          ],
        ),
        const SizedBox(height: 12),

        // Przełączniki warstw
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InteractiveChip(
              label: 'Wektory 0°–360°',
              isSelected: _showForceVectors,
              isDisabled: widget.isDisabled,
              onTap: () => setState(() => _showForceVectors = !_showForceVectors),
            ),
            _InteractiveChip(
              label: 'Martwe punkty 0°/180°',
              isSelected: _showDeadZones,
              isDisabled: widget.isDisabled,
              onTap: () => setState(() => _showDeadZones = !_showDeadZones),
            ),
            if (data.comparison != null)
              _InteractiveChip(
                label: 'Nakładka porównawcza',
                isSelected: _showComparison,
                isDisabled: widget.isDisabled,
                onTap: () => setState(() => _showComparison = !_showComparison),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Suwaki mocy i kadencji
        _buildSliderRow(
          label: 'Moc Bazowa',
          valueLabel: '${_powerWatts.round()} W',
          value: _powerWatts,
          min: 150.0,
          max: 1200.0,
          onChanged: widget.isDisabled
              ? null
              : (v) => setState(() => _powerWatts = v),
        ),
        const SizedBox(height: 6),
        _buildSliderRow(
          label: 'Kadencja',
          valueLabel: '${_cadenceRpm.round()} RPM',
          value: _cadenceRpm,
          min: 55.0,
          max: 125.0,
          onChanged: widget.isDisabled ? null : _updateCadence,
        ),
        const SizedBox(height: 12),

        // Kafelki metryk biomechanicznych
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildMetricCard(
              label: 'Torque Effectiveness (TE)',
              value:
                  '${primaryMetrics.torqueEffectivenessPercent.toStringAsFixed(1)}%',
              comparisonValue: compMetrics != null && _showComparison
                  ? '${compMetrics.torqueEffectivenessPercent.toStringAsFixed(1)}%'
                  : null,
              accent: data.primaryColor,
              width: isCompact ? double.infinity : 175,
            ),
            _buildMetricCard(
              label: 'Pedal Smoothness (PS)',
              value:
                  '${primaryMetrics.pedalSmoothnessPercent.toStringAsFixed(1)}%',
              comparisonValue: compMetrics != null && _showComparison
                  ? '${compMetrics.pedalSmoothnessPercent.toStringAsFixed(1)}%'
                  : null,
              accent: AppColors.statusSuccess,
              width: isCompact ? double.infinity : 175,
            ),
            _buildMetricCard(
              label: 'Siła w Martwych (0°/180°)',
              value: '${primaryMetrics.deadZoneForceN.toStringAsFixed(0)} N',
              comparisonValue: compMetrics != null && _showComparison
                  ? '${compMetrics.deadZoneForceN.toStringAsFixed(0)} N'
                  : null,
              accent: AppColors.amberWarning,
              width: isCompact ? double.infinity : 175,
            ),
            _buildMetricCard(
              label: 'Szczyt Depnięcia (90°/270°)',
              value:
                  '${primaryMetrics.peakCombinedForceN.toStringAsFixed(0)} N',
              comparisonValue: compMetrics != null && _showComparison
                  ? '${compMetrics.peakCombinedForceN.toStringAsFixed(0)} N'
                  : null,
              accent: AppColors.goldAccent,
              width: isCompact ? double.infinity : 175,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double>? onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppTheme.borderColor,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
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
        ),
        SizedBox(
          width: 66,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color accent,
    required double width,
    String? comparisonValue,
  }) {
    return Container(
      width: width == double.infinity ? null : width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (comparisonValue != null)
                Text(
                  'vs $comparisonValue',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.crimsonAlert,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InteractiveChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.goldAccent
            : (_isFocused
                ? AppColors.cyanAccent
                : (_isHovered ? AppColors.textSecondary : AppTheme.borderColor));

    final Color bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: 0.16)
            : (_isHovered ? AppColors.surfaceLight : AppColors.background);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isDisabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.45)
                    : (widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        widget.isActive ? AppColors.primaryAccent : AppColors.goldAccent;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isDisabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? AppColors.surfaceLight.withValues(alpha: 0.4)
                  : accent.withValues(alpha: _isHovered ? 0.28 : 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isDisabled
                    ? AppTheme.borderColor
                    : (_isFocused ? AppColors.cyanAccent : accent),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.isDisabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.isDisabled
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
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
