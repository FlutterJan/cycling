// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../services/career/bike_sponsor_custom_prototype_lab.dart';

/// Tryb rzutu technicznego na rysunku Blueprint CAD prototypu Skunkworks.
enum BlueprintViewMode {
  sideProfile,
  aeroCrossSection,
  drivetrainDetail,
  explodedWireframe;

  String get label {
    switch (this) {
      case BlueprintViewMode.sideProfile:
        return 'Rzut Boczny';
      case BlueprintViewMode.aeroCrossSection:
        return 'Przekrój Aero';
      case BlueprintViewMode.drivetrainDetail:
        return 'Napęd & Mufa';
      case BlueprintViewMode.explodedWireframe:
        return 'Widok Rozstrzelony';
    }
  }

  String get shortCode {
    switch (this) {
      case BlueprintViewMode.sideProfile:
        return 'ISO-SIDE';
      case BlueprintViewMode.aeroCrossSection:
        return 'NACA-SEC';
      case BlueprintViewMode.drivetrainDetail:
        return 'BB-DRIVE';
      case BlueprintViewMode.explodedWireframe:
        return 'EXP-ASSY';
    }
  }

  IconData get icon {
    switch (this) {
      case BlueprintViewMode.sideProfile:
        return Icons.architecture_rounded;
      case BlueprintViewMode.aeroCrossSection:
        return Icons.air_rounded;
      case BlueprintViewMode.drivetrainDetail:
        return Icons.settings_rounded;
      case BlueprintViewMode.explodedWireframe:
        return Icons.layers_rounded;
    }
  }
}

/// Warstwy techniczne możliwe do włączenia lub ukrycia na rysunku CAD.
enum BlueprintLayerOption {
  grid,
  dimensions,
  stressHeatmap,
  airflowVectors,
  uciBoxOverlay,
  callouts;

  String get label {
    switch (this) {
      case BlueprintLayerOption.grid:
        return 'Siatka mm';
      case BlueprintLayerOption.dimensions:
        return 'Wymiary ISO';
      case BlueprintLayerOption.stressHeatmap:
        return 'Naprężenia FEA';
      case BlueprintLayerOption.airflowVectors:
        return 'Strugi CFD';
      case BlueprintLayerOption.uciBoxOverlay:
        return 'Limit UCI';
      case BlueprintLayerOption.callouts:
        return 'Piny CAD';
    }
  }
}

/// Schemat kolorystyczny arkusza Blueprint CAD.
enum BlueprintColorTheme {
  classicCyan,
  stealthGold,
  thermalStress;

  String get label {
    switch (this) {
      case BlueprintColorTheme.classicCyan:
        return 'Cyan CAD';
      case BlueprintColorTheme.stealthGold:
        return 'Skunkworks Gold';
      case BlueprintColorTheme.thermalStress:
        return 'FEA Thermal';
    }
  }

  Color get canvasBackground {
    switch (this) {
      case BlueprintColorTheme.classicCyan:
        return const Color(0xFF0A121E);
      case BlueprintColorTheme.stealthGold:
        return AppColors.background;
      case BlueprintColorTheme.thermalStress:
        return const Color(0xFF10131A);
    }
  }

  Color get primaryStroke {
    switch (this) {
      case BlueprintColorTheme.classicCyan:
        return AppColors.cyanAccent;
      case BlueprintColorTheme.stealthGold:
        return AppColors.goldAccent;
      case BlueprintColorTheme.thermalStress:
        return AppColors.accentBlue;
    }
  }

  Color get secondaryStroke {
    switch (this) {
      case BlueprintColorTheme.classicCyan:
        return AppColors.accentBlue;
      case BlueprintColorTheme.stealthGold:
        return AppColors.primaryAccent;
      case BlueprintColorTheme.thermalStress:
        return AppColors.amberWarning;
    }
  }
}

/// Punkt adnotacji inżynieryjnej (Callout Pin) osadzony na rysunku CAD.
@immutable
class BlueprintCalloutPin {
  final String id;
  final int indexNumber;
  final String title;
  final String subtitle;
  final String metricValue;
  final Offset normalizedPosition;
  final Color accentColor;

  const BlueprintCalloutPin({
    required this.id,
    required this.indexNumber,
    required this.title,
    required this.subtitle,
    required this.metricValue,
    required this.normalizedPosition,
    required this.accentColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlueprintCalloutPin &&
        other.id == id &&
        other.indexNumber == indexNumber &&
        other.title == title &&
        other.metricValue == metricValue &&
        other.normalizedPosition == normalizedPosition;
  }

  @override
  int get hashCode =>
      Object.hash(id, indexNumber, title, metricValue, normalizedPosition);
}

/// Wyliczona geometria inżynieryjna prototypu wyprowadzona deterministycznie
/// z parametrów [SkunkworksPrototypeSpec].
@immutable
class SkunkworksCadGeometrySpec {
  final double wheelbaseMm;
  final double stackMm;
  final double reachMm;
  final double headTubeAngleDeg;
  final double seatTubeAngleDeg;
  final double bbDropMm;
  final double chainstayMm;
  final double wheelRimDepthMm;
  final double tubeChordRatio;
  final double peakStressMpa;
  final double naturalFreqHz;
  final double cfdDragReductionN;
  final double uciTubeRatioMarginMm;

  const SkunkworksCadGeometrySpec({
    required this.wheelbaseMm,
    required this.stackMm,
    required this.reachMm,
    required this.headTubeAngleDeg,
    required this.seatTubeAngleDeg,
    required this.bbDropMm,
    required this.chainstayMm,
    required this.wheelRimDepthMm,
    required this.tubeChordRatio,
    required this.peakStressMpa,
    required this.naturalFreqHz,
    required this.cfdDragReductionN,
    required this.uciTubeRatioMarginMm,
  });
}

/// Deterministyczny kalkulator geometrii CAD i adnotacji inżynieryjnych
/// dla dowolnego prototypu [SkunkworksPrototypeSpec].
class SkunkworksBlueprintGeometryCalculator {
  SkunkworksBlueprintGeometryCalculator._();

  static SkunkworksCadGeometrySpec computeGeometry(
    SkunkworksPrototypeSpec spec,
  ) {
    final seed = spec.cadBlueprintSeed.abs();
    final seedUnit = (seed % 1000) / 1000.0;

    final double baseWheelbase;
    final double baseRimDepth;
    final double baseChordRatio;

    switch (spec.category) {
      case SkunkworksPrototypeCategory.aeroTtFrame:
        baseWheelbase = 996.0 + seedUnit * 12.0;
        baseRimDepth = 65.0 + seedUnit * 15.0;
        baseChordRatio = 6.4 + (spec.uciComplianceMarginPercent.clamp(0.0, 20.0) * 0.05);
      case SkunkworksPrototypeCategory.ultralightClimbingChassis:
        baseWheelbase = 978.0 + seedUnit * 10.0;
        baseRimDepth = 32.0 + seedUnit * 8.0;
        baseChordRatio = 2.8 + seedUnit * 0.6;
      case SkunkworksPrototypeCategory.cobbleSuspensionCockpit:
        baseWheelbase = 1008.0 + seedUnit * 14.0;
        baseRimDepth = 40.0 + seedUnit * 10.0;
        baseChordRatio = 3.2 + seedUnit * 0.5;
      case SkunkworksPrototypeCategory.ceramicDrivetrainWax:
        baseWheelbase = 986.0 + seedUnit * 8.0;
        baseRimDepth = 50.0 + seedUnit * 10.0;
        baseChordRatio = 4.1 + seedUnit * 0.7;
      case SkunkworksPrototypeCategory.carbonMonocoqueWheelset:
        baseWheelbase = 990.0 + seedUnit * 10.0;
        baseRimDepth = 68.0 + seedUnit * 12.0;
        baseChordRatio = 5.6 + seedUnit * 1.1;
    }

    final stackMm = spec.category == SkunkworksPrototypeCategory.aeroTtFrame
        ? 512.0 + seedUnit * 14.0
        : 544.0 + seedUnit * 18.0;
    final reachMm = spec.category == SkunkworksPrototypeCategory.aeroTtFrame
        ? 418.0 + seedUnit * 14.0
        : 392.0 + seedUnit * 12.0;

    final headAngle = spec.category == SkunkworksPrototypeCategory.cobbleSuspensionCockpit
        ? 71.8 + seedUnit * 0.7
        : 73.0 + seedUnit * 0.8;
    final seatAngle = spec.category == SkunkworksPrototypeCategory.aeroTtFrame
        ? 76.5 + seedUnit * 1.5
        : 73.5 + seedUnit * 0.7;

    final peakStressMpa =
        (310.0 + (spec.stiffnessToWeightRatio * 2.1) + (spec.failureRiskPercent * 4.5))
            .clamp(280.0, 680.0);

    final naturalFreqHz =
        (42.0 + (spec.vibrationDampingBonusPercent * 1.4) + seedUnit * 8.0)
            .clamp(35.0, 95.0);

    // Przybliżona redukcja oporu w Newtonach przy 45 km/h (12.5 m/s)
    final cfdDragReductionN =
        (spec.cdaDeltaPercent.abs() * 0.28 + spec.drivetrainWattSavings * 0.08)
            .clamp(0.4, 9.5);

    final uciMarginMm = (spec.uciComplianceMarginPercent * 0.45).clamp(0.2, 12.0);

    return SkunkworksCadGeometrySpec(
      wheelbaseMm: baseWheelbase,
      stackMm: stackMm,
      reachMm: reachMm,
      headTubeAngleDeg: headAngle,
      seatTubeAngleDeg: seatAngle,
      bbDropMm: 70.0 + seedUnit * 4.0,
      chainstayMm: spec.category == SkunkworksPrototypeCategory.cobbleSuspensionCockpit
          ? 418.0
          : 408.0,
      wheelRimDepthMm: baseRimDepth,
      tubeChordRatio: baseChordRatio,
      peakStressMpa: peakStressMpa,
      naturalFreqHz: naturalFreqHz,
      cfdDragReductionN: cfdDragReductionN,
      uciTubeRatioMarginMm: uciMarginMm,
    );
  }

  static List<BlueprintCalloutPin> buildCalloutPins(
    SkunkworksPrototypeSpec spec,
    SkunkworksCadGeometrySpec geometry,
  ) {
    final cdaText = spec.cdaDeltaPercent <= 0
        ? '${spec.cdaDeltaPercent.toStringAsFixed(1)}% CdA'
        : '+${spec.cdaDeltaPercent.toStringAsFixed(1)}% CdA';
    final weightText = spec.weightDeltaGrams <= 0
        ? '${spec.weightDeltaGrams} g'
        : '+${spec.weightDeltaGrams} g';

    return <BlueprintCalloutPin>[
      BlueprintCalloutPin(
        id: 'headtube_aero',
        indexNumber: 1,
        title: 'Główka Ramy & Przepływ CFD',
        subtitle:
            'Profil NACA ${geometry.tubeChordRatio.toStringAsFixed(1)}:1, kąt ${geometry.headTubeAngleDeg.toStringAsFixed(1)}°',
        metricValue: cdaText,
        normalizedPosition: const Offset(0.64, 0.36),
        accentColor: AppColors.cyanAccent,
      ),
      BlueprintCalloutPin(
        id: 'bb_stiffness',
        indexNumber: 2,
        title: 'Węzeł Mufy Suportu (FEA)',
        subtitle:
            'Włókno T1100 1K, szczytowe naprężenie ${geometry.peakStressMpa.toStringAsFixed(0)} MPa',
        metricValue: '${spec.stiffnessToWeightRatio.toStringAsFixed(1)} N/mm·kg',
        normalizedPosition: const Offset(0.46, 0.67),
        accentColor: spec.failureRiskPercent >= 12.0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
      ),
      BlueprintCalloutPin(
        id: 'rear_triangle',
        indexNumber: 3,
        title: 'Tylny Trójkąt & Tłumienie',
        subtitle:
            'Częstotliwość własna ${geometry.naturalFreqHz.toStringAsFixed(1)} Hz, widełki ${geometry.chainstayMm.toStringAsFixed(0)} mm',
        metricValue: '+${spec.vibrationDampingBonusPercent.toStringAsFixed(1)}% tłumienia',
        normalizedPosition: const Offset(0.28, 0.56),
        accentColor: AppColors.accentBlue,
      ),
      BlueprintCalloutPin(
        id: 'wheel_profile',
        indexNumber: 4,
        title: 'Zestaw Kół & Stożek Aero',
        subtitle:
            'Profil obręczy ${geometry.wheelRimDepthMm.toStringAsFixed(0)} mm, margines UCI ${geometry.uciTubeRatioMarginMm.toStringAsFixed(1)} mm',
        metricValue: weightText,
        normalizedPosition: const Offset(0.75, 0.62),
        accentColor: AppColors.goldAccent,
      ),
      BlueprintCalloutPin(
        id: 'drivetrain_eff',
        indexNumber: 5,
        title: 'Napęd & Straty Tarcia',
        subtitle:
            'Zysk ${spec.drivetrainWattSavings.toStringAsFixed(1)} W przy 400 W obciążenia',
        metricValue: '+${spec.drivetrainWattSavings.toStringAsFixed(1)} W',
        normalizedPosition: const Offset(0.40, 0.69),
        accentColor: AppColors.primaryAccent,
      ),
    ];
  }
}

/// Techniczny `CustomPainter` renderujący inżynieryjny rysunek Blueprint CAD
/// testowanego prototypu [SkunkworksPrototypeSpec].
class SkunkworksPrototypeBlueprintPainter extends CustomPainter {
  final SkunkworksPrototypeSpec prototype;
  final SkunkworksCadGeometrySpec geometry;
  final BlueprintViewMode viewMode;
  final Set<BlueprintLayerOption> activeLayers;
  final BlueprintColorTheme colorTheme;
  final List<BlueprintCalloutPin> calloutPins;
  final String? selectedPinId;
  final String? hoveredPinId;
  final double cfdAnimationProgress;
  final double zoomScale;
  final Offset panOffset;
  final bool isDisabled;

  const SkunkworksPrototypeBlueprintPainter({
    required this.prototype,
    required this.geometry,
    required this.viewMode,
    required this.activeLayers,
    required this.colorTheme,
    required this.calloutPins,
    this.selectedPinId,
    this.hoveredPinId,
    this.cfdAnimationProgress = 0.0,
    this.zoomScale = 1.0,
    this.panOffset = Offset.zero,
    this.isDisabled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Tło arkusza Blueprint
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()..color = colorTheme.canvasBackground;
    canvas.drawRect(bgRect, bgPaint);

    // Subtelna winieta techniczna
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.95,
        colors: [
          colorTheme.primaryStroke.withValues(alpha: 0.06),
          Colors.black.withValues(alpha: 0.35),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, vignettePaint);

    canvas.save();
    canvas.clipRect(bgRect);

    // 2. Siatka milimetrowa + linijki brzegowe
    if (activeLayers.contains(BlueprintLayerOption.grid)) {
      _drawEngineeringGrid(canvas, size);
    }

    // Zastosowanie zoomu i przesunięcia do warstwy modelu CAD
    canvas.save();
    final center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.translate(center.dx + panOffset.dx, center.dy + panOffset.dy);
    canvas.scale(zoomScale, zoomScale);
    canvas.translate(-center.dx, -center.dy);

    // Bazowy układ współrzędnych roweru w arkuszu
    final frameRect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.16,
      size.width * 0.72,
      size.height * 0.66,
    );

    // 3. Ramka limitów regulaminowych UCI
    if (activeLayers.contains(BlueprintLayerOption.uciBoxOverlay)) {
      _drawUciComplianceOverlay(canvas, frameRect);
    }

    // 4. Strugi przepływu CFD
    if (activeLayers.contains(BlueprintLayerOption.airflowVectors)) {
      _drawCfdAirflowStreamlines(canvas, frameRect);
    }

    // 5. Mapa naprężeń FEA
    if (activeLayers.contains(BlueprintLayerOption.stressHeatmap)) {
      _drawFeaStressHeatmap(canvas, frameRect);
    }

    // 6. Główny rysunek CAD zależny od wybranego rzutu
    switch (viewMode) {
      case BlueprintViewMode.sideProfile:
        _drawBicycleWireframe(canvas, frameRect, explodedFactor: 0.0);
      case BlueprintViewMode.explodedWireframe:
        _drawBicycleWireframe(canvas, frameRect, explodedFactor: 1.0);
      case BlueprintViewMode.aeroCrossSection:
        _drawBicycleWireframe(canvas, frameRect, explodedFactor: 0.0, dimmed: true);
        _drawAeroCrossSectionOverlay(canvas, frameRect);
      case BlueprintViewMode.drivetrainDetail:
        _drawDrivetrainDetailView(canvas, frameRect);
    }

    // 7. Wymiary inżynieryjne ISO
    if (activeLayers.contains(BlueprintLayerOption.dimensions)) {
      _drawIsoDimensions(canvas, frameRect);
    }

    // 8. Piny adnotacji CAD
    if (activeLayers.contains(BlueprintLayerOption.callouts)) {
      _drawCalloutPins(canvas, size);
    }

    canvas.restore(); // koniec transformacji zoom/pan

    // 9. Ramka arkusza i Tabelka Rysunkowa (Title Block)
    _drawSheetBorderAndTitleBlock(canvas, size);

    if (isDisabled) {
      canvas.drawRect(
        bgRect,
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
    }

    canvas.restore();
  }

  void _drawEngineeringGrid(Canvas canvas, Size size) {
    final minorStep = math.max(14.0, size.width / 44.0);
    final majorStep = minorStep * 4.0;

    final minorPaint = Paint()
      ..color = colorTheme.primaryStroke.withValues(alpha: 0.06)
      ..strokeWidth = 0.6;
    final majorPaint = Paint()
      ..color = colorTheme.primaryStroke.withValues(alpha: 0.14)
      ..strokeWidth = 0.9;

    for (double x = 0; x <= size.width; x += minorStep) {
      final isMajor = ((x / majorStep).round() * majorStep - x).abs() < 0.5;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }
    for (double y = 0; y <= size.height; y += minorStep) {
      final isMajor = ((y / majorStep).round() * majorStep - y).abs() < 0.5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }

    // Podziałka linijki u góry i po lewej
    final tickPaint = Paint()
      ..color = colorTheme.primaryStroke.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (double x = majorStep; x < size.width - 16; x += majorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, 7), tickPaint);
    }
    for (double y = majorStep; y < size.height - 16; y += majorStep) {
      canvas.drawLine(Offset(0, y), Offset(7, y), tickPaint);
    }
  }

  void _drawUciComplianceOverlay(Canvas canvas, Rect rect) {
    final uciPaint = Paint()
      ..color = prototype.uciComplianceMarginPercent < 2.0
          ? AppColors.crimsonAlert.withValues(alpha: 0.75)
          : AppColors.goldAccent.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final box = rect.inflate(10);
    _drawDashedRect(canvas, box, uciPaint, dash: 7, gap: 5);

    _drawCadLabel(
      canvas,
      'UCI 3:1/8:1 ENVELOPE (+${geometry.uciTubeRatioMarginMm.toStringAsFixed(1)} mm)',
      Offset(box.left + 8, box.top + 6),
      color: AppColors.goldAccent,
      fontSize: 9.5,
    );
  }

  void _drawCfdAirflowStreamlines(Canvas canvas, Rect rect) {
    const int lines = 8;
    for (int i = 0; i < lines; i++) {
      final t = i / (lines - 1);
      final baseY = rect.top + rect.height * (0.14 + t * 0.74);
      final path = Path();
      const int segments = 24;
      for (int s = 0; s <= segments; s++) {
        final u = s / segments;
        final x = rect.left - 24 + u * (rect.width + 48);

        // Odchylenie strugi wokół przedniego koła i główki ramy
        final distToHead = (u - 0.68).abs();
        final deflection = math.exp(-distToHead * distToHead * 28.0) *
            (t < 0.5 ? -14.0 : 12.0) *
            (1.0 + prototype.cdaDeltaPercent.abs() * 0.04);

        final wakeWave = u > 0.70
            ? math.sin((u * 14.0) - (cfdAnimationProgress * math.pi * 2.0) + i) *
                3.2
            : 0.0;

        final y = baseY + deflection + wakeWave;
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      final streamColor = i % 2 == 0
          ? AppColors.cyanAccent.withValues(alpha: 0.42)
          : AppColors.accentBlue.withValues(alpha: 0.30);

      final paint = Paint()
        ..color = streamColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15;
      canvas.drawPath(path, paint);

      // Ruchoma cząsteczka wektora prędkości na strudze
      final particleU = (cfdAnimationProgress + (i * 0.13)) % 1.0;
      final px = rect.left - 20 + particleU * (rect.width + 40);
      final distHead = (particleU - 0.68).abs();
      final py = baseY +
          math.exp(-distHead * distHead * 28.0) * (t < 0.5 ? -14.0 : 12.0);
      canvas.drawCircle(
        Offset(px, py),
        2.1,
        Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.85),
      );
    }
  }

  void _drawFeaStressHeatmap(Canvas canvas, Rect rect) {
    final bbCenter = Offset(rect.left + rect.width * 0.44, rect.top + rect.height * 0.72);
    final headCenter = Offset(rect.left + rect.width * 0.66, rect.top + rect.height * 0.36);
    final rearDrop = Offset(rect.left + rect.width * 0.20, rect.top + rect.height * 0.69);

    final spots = <(Offset, double, Color)>[
      (bbCenter, rect.width * 0.14, AppColors.crimsonAlert),
      (headCenter, rect.width * 0.11, AppColors.amberWarning),
      (rearDrop, rect.width * 0.09, AppColors.statusSuccess),
    ];

    for (final (center, radius, color) in spots) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.38),
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);

      // Izolinia naprężenia
      canvas.drawCircle(
        center,
        radius * 0.52,
        Paint()
          ..color = color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }

  void _drawBicycleWireframe(
    Canvas canvas,
    Rect rect, {
    required double explodedFactor,
    bool dimmed = false,
  }) {
    final strokeAlpha = dimmed ? 0.35 : 0.92;
    final primaryPaint = Paint()
      ..color = colorTheme.primaryStroke.withValues(alpha: strokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final thinPaint = Paint()
      ..color = colorTheme.primaryStroke.withValues(alpha: strokeAlpha * 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final accentPaint = Paint()
      ..color = colorTheme.secondaryStroke.withValues(alpha: strokeAlpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Kluczowe węzły ramy
    final wheelRadius = math.min(rect.width * 0.185, rect.height * 0.34);
    final rimInnerRadius =
        wheelRadius * (1.0 - (geometry.wheelRimDepthMm / 340.0).clamp(0.08, 0.30));

    final rearAxleBase = Offset(
      rect.left + rect.width * 0.21,
      rect.top + rect.height * 0.69,
    );
    final frontAxleBase = Offset(
      rect.left + rect.width * 0.77,
      rect.top + rect.height * 0.69,
    );

    final rearAxle = rearAxleBase + Offset(-26.0 * explodedFactor, 0);
    final frontAxle = frontAxleBase + Offset(28.0 * explodedFactor, 0);

    final bbCenter = Offset(
      rect.left + rect.width * 0.44,
      rect.top + rect.height * 0.72,
    );
    final seatCluster = Offset(
      rect.left + rect.width * 0.37,
      rect.top + rect.height * 0.35,
    );
    final headTop = Offset(
      rect.left + rect.width * 0.64,
      rect.top + rect.height * 0.31,
    );
    final headBottom = Offset(
      rect.left + rect.width * 0.66,
      rect.top + rect.height * 0.42,
    );

    // Linie osiowe dla widoku rozstrzelonego
    if (explodedFactor > 0.05) {
      final guidePaint = Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      _drawDashedLine(canvas, rearAxleBase, rearAxle, guidePaint);
      _drawDashedLine(canvas, frontAxleBase, frontAxle, guidePaint);
    }

    // Koła (opona, obręcz aero, szprychy, tarcza hamulcowa)
    for (final axle in [rearAxle, frontAxle]) {
      canvas.drawCircle(axle, wheelRadius, primaryPaint);
      canvas.drawCircle(axle, wheelRadius - 4.0, thinPaint);
      canvas.drawCircle(axle, rimInnerRadius, accentPaint);
      canvas.drawCircle(axle, 6.0, primaryPaint);
      // Tarcza hamulcowa
      canvas.drawCircle(axle, wheelRadius * 0.22, thinPaint);

      const int spokeCount = 16;
      for (int i = 0; i < spokeCount; i++) {
        final angle = (i / spokeCount) * math.pi * 2.0;
        final p1 = axle + Offset(math.cos(angle) * 6.0, math.sin(angle) * 6.0);
        final p2 = axle +
            Offset(
              math.cos(angle) * rimInnerRadius,
              math.sin(angle) * rimInnerRadius,
            );
        canvas.drawLine(p1, p2, thinPaint..color = colorTheme.primaryStroke.withValues(alpha: strokeAlpha * 0.24));
      }
    }
    thinPaint.color = colorTheme.primaryStroke.withValues(alpha: strokeAlpha * 0.55);

    // Główny trójkąt ramy (podwójne ścianki CAD dla przekroju rur)
    _drawCadTube(canvas, bbCenter, seatCluster, 9.0, primaryPaint, thinPaint);
    _drawCadTube(canvas, seatCluster, headTop, 8.5, primaryPaint, thinPaint);
    _drawCadTube(canvas, bbCenter, headBottom, 13.0, primaryPaint, thinPaint);
    _drawCadTube(canvas, headTop, headBottom, 10.5, primaryPaint, thinPaint);

    // Tylny trójkąt
    final rearDropTarget = rearAxleBase;
    _drawCadTube(canvas, bbCenter, rearDropTarget, 6.5, primaryPaint, thinPaint);
    _drawCadTube(
      canvas,
      seatCluster + const Offset(0, 12),
      rearDropTarget,
      5.0,
      primaryPaint,
      thinPaint,
    );

    // Widelec przedni (odsunięty w widoku rozstrzelonym)
    final forkOffset = Offset(14.0 * explodedFactor, 16.0 * explodedFactor);
    _drawCadTube(
      canvas,
      headBottom + forkOffset,
      frontAxleBase + forkOffset,
      7.5,
      primaryPaint,
      thinPaint,
    );

    // Sztyca podsiodłowa i siodło
    final seatOffset = Offset(-6.0 * explodedFactor, -22.0 * explodedFactor);
    final saddleCenter = seatCluster + const Offset(-14, -36) + seatOffset;
    canvas.drawLine(seatCluster + seatOffset, saddleCenter, primaryPaint);
    canvas.drawLine(
      saddleCenter + const Offset(-20, 0),
      saddleCenter + const Offset(22, 0),
      primaryPaint,
    );

    // Kokpit (kierownica TT lub szosowa)
    final cockpitOffset = Offset(10.0 * explodedFactor, -18.0 * explodedFactor);
    final stemEnd = headTop + const Offset(22, -16) + cockpitOffset;
    canvas.drawLine(headTop + cockpitOffset, stemEnd, primaryPaint);
    if (prototype.category == SkunkworksPrototypeCategory.aeroTtFrame) {
      // Przystawka czasowa (TT extensions)
      canvas.drawLine(stemEnd, stemEnd + const Offset(36, -6), accentPaint);
      canvas.drawLine(
        stemEnd + const Offset(36, -6),
        stemEnd + const Offset(44, -14),
        accentPaint,
      );
    } else {
      // Baranek szosowy
      final dropArc = Rect.fromCircle(
        center: stemEnd + const Offset(6, 12),
        radius: 12,
      );
      canvas.drawArc(dropArc, -math.pi * 0.5, math.pi * 1.15, false, primaryPaint);
    }

    // Korba i tarcza napędowa
    canvas.drawCircle(bbCenter, 19.0, accentPaint);
    canvas.drawCircle(bbCenter, 14.0, thinPaint);
    canvas.drawLine(
      bbCenter,
      bbCenter + const Offset(18, 22),
      primaryPaint,
    );
  }

  void _drawAeroCrossSectionOverlay(Canvas canvas, Rect rect) {
    final panelRect = Rect.fromLTWH(
      rect.left + rect.width * 0.04,
      rect.top + rect.height * 0.06,
      rect.width * 0.40,
      rect.height * 0.34,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      Paint()..color = colorTheme.canvasBackground.withValues(alpha: 0.90),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    _drawCadLabel(
      canvas,
      'PRZEKRÓJ PROFILU RURY DOLNEJ (KAMMTIAL ${geometry.tubeChordRatio.toStringAsFixed(1)}:1)',
      Offset(panelRect.left + 10, panelRect.top + 8),
      color: AppColors.cyanAccent,
      fontSize: 9.0,
    );

    // Kształt profilu NACA / Kamm-tail wewnątrz okna powiększenia
    final cx = panelRect.center.dx;
    final cy = panelRect.center.dy + 8;
    final halfLen = panelRect.width * 0.34;
    final halfThick = panelRect.height * 0.18;

    final airfoil = Path()
      ..moveTo(cx - halfLen, cy)
      ..cubicTo(
        cx - halfLen,
        cy - halfThick * 1.3,
        cx + halfLen * 0.25,
        cy - halfThick,
        cx + halfLen * 0.85,
        cy - halfThick * 0.55,
      )
      ..lineTo(cx + halfLen * 0.85, cy + halfThick * 0.55)
      ..cubicTo(
        cx + halfLen * 0.25,
        cy + halfThick,
        cx - halfLen,
        cy + halfThick * 1.3,
        cx - halfLen,
        cy,
      )
      ..close();

    canvas.drawPath(
      airfoil,
      Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.14),
    );
    canvas.drawPath(
      airfoil,
      Paint()
        ..color = AppColors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Oś symetrii profilu
    _drawDashedLine(
      canvas,
      Offset(cx - halfLen - 12, cy),
      Offset(cx + halfLen + 10, cy),
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.65)
        ..strokeWidth = 0.9,
    );
  }

  void _drawDrivetrainDetailView(Canvas canvas, Rect rect) {
    final center = Offset(rect.center.dx, rect.center.dy + 6);
    final outerRadius = math.min(rect.width, rect.height) * 0.28;

    final primary = Paint()
      ..color = colorTheme.primaryStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final secondary = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Zębatka korby 54T z zębami
    const int teeth = 36;
    final gearPath = Path();
    for (int i = 0; i < teeth * 2; i++) {
      final angle = (i / (teeth * 2)) * math.pi * 2.0;
      final r = i.isEven ? outerRadius : outerRadius - 6.5;
      final pt = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        gearPath.moveTo(pt.dx, pt.dy);
      } else {
        gearPath.lineTo(pt.dx, pt.dy);
      }
    }
    gearPath.close();
    canvas.drawPath(gearPath, primary);

    // Łożyska ceramiczne wewnątrz mufy
    canvas.drawCircle(center, outerRadius * 0.42, secondary);
    canvas.drawCircle(center, outerRadius * 0.24, primary);
    const int balls = 12;
    for (int b = 0; b < balls; b++) {
      final a = (b / balls) * math.pi * 2.0;
      final ballCenter =
          center + Offset(math.cos(a) * outerRadius * 0.33, math.sin(a) * outerRadius * 0.33);
      canvas.drawCircle(
        ballCenter,
        3.2,
        Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.85),
      );
    }

    // Wózek przerzutki OSPW i łańcuch PTFE
    final pulleyTop = center + Offset(-outerRadius * 1.45, outerRadius * 0.35);
    final pulleyBot = center + Offset(-outerRadius * 1.38, outerRadius * 0.88);
    canvas.drawCircle(pulleyTop, 16.0, secondary);
    canvas.drawCircle(pulleyBot, 22.0, secondary);
    canvas.drawLine(
      center + Offset(0, -outerRadius),
      pulleyTop + const Offset(0, -16),
      primary,
    );
    canvas.drawLine(
      center + Offset(0, outerRadius),
      pulleyBot + const Offset(0, 22),
      primary,
    );

    _drawCadLabel(
      canvas,
      'CERAMIC BB & OSPW (+${prototype.drivetrainWattSavings.toStringAsFixed(1)} W)',
      Offset(center.dx - outerRadius, rect.top + 14),
      color: AppColors.goldAccent,
      fontSize: 10.5,
    );
  }

  void _drawIsoDimensions(Canvas canvas, Rect rect) {
    final dimPaint = Paint()
      ..color = colorTheme.primaryStroke.withValues(alpha: 0.62)
      ..strokeWidth = 0.95;

    // Wymiar bazy kół (Wheelbase) na dole
    final rearX = rect.left + rect.width * 0.21;
    final frontX = rect.left + rect.width * 0.77;
    final baseY = rect.bottom + 14;

    canvas.drawLine(Offset(rearX, rect.bottom - 18), Offset(rearX, baseY + 4), dimPaint);
    canvas.drawLine(Offset(frontX, rect.bottom - 18), Offset(frontX, baseY + 4), dimPaint);
    _drawDimensionArrowLine(
      canvas,
      Offset(rearX, baseY),
      Offset(frontX, baseY),
      dimPaint,
    );
    _drawCadLabel(
      canvas,
      'WB ${geometry.wheelbaseMm.toStringAsFixed(0)} mm',
      Offset((rearX + frontX) * 0.5 - 32, baseY - 13),
      color: colorTheme.primaryStroke,
      fontSize: 9.5,
    );

    // Wymiar Stack (wysokość) po prawej
    final stackX = rect.right + 12;
    final topY = rect.top + rect.height * 0.31;
    final botY = rect.top + rect.height * 0.72;
    _drawDimensionArrowLine(
      canvas,
      Offset(stackX, topY),
      Offset(stackX, botY),
      dimPaint,
    );
    _drawCadLabel(
      canvas,
      'STK ${geometry.stackMm.toStringAsFixed(0)}',
      Offset(stackX - 24, (topY + botY) * 0.5 - 6),
      color: colorTheme.primaryStroke,
      fontSize: 9.0,
    );
  }

  void _drawCalloutPins(Canvas canvas, Size size) {
    for (final pin in calloutPins) {
      final pos = Offset(
        pin.normalizedPosition.dx * size.width,
        pin.normalizedPosition.dy * size.height,
      );
      final isSelected = pin.id == selectedPinId;
      final isHovered = pin.id == hoveredPinId;

      if (isSelected || isHovered) {
        canvas.drawCircle(
          pos,
          isSelected ? 17.0 : 14.5,
          Paint()
            ..color = pin.accentColor.withValues(alpha: isSelected ? 0.28 : 0.18),
        );
      }

      canvas.drawCircle(
        pos,
        10.5,
        Paint()..color = colorTheme.canvasBackground,
      );
      canvas.drawCircle(
        pos,
        10.5,
        Paint()
          ..color = pin.accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.2 : 1.5,
      );

      _drawCadLabel(
        canvas,
        '${pin.indexNumber}',
        pos + const Offset(-3.5, -6.0),
        color: AppColors.textPrimary,
        fontSize: 10.0,
        bold: true,
      );
    }
  }

  void _drawSheetBorderAndTitleBlock(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = colorTheme.primaryStroke.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      borderPaint,
    );

    // Tabelka rysunkowa (prawy dolny róg)
    final blockWidth = math.min(220.0, size.width * 0.44);
    const blockHeight = 52.0;
    final blockRect = Rect.fromLTWH(
      size.width - blockWidth - 14,
      size.height - blockHeight - 14,
      blockWidth,
      blockHeight,
    );

    canvas.drawRect(
      blockRect,
      Paint()..color = colorTheme.canvasBackground.withValues(alpha: 0.92),
    );
    canvas.drawRect(blockRect, borderPaint);

    _drawCadLabel(
      canvas,
      '${prototype.codename} • ${viewMode.shortCode}',
      Offset(blockRect.left + 8, blockRect.top + 7),
      color: colorTheme.primaryStroke,
      fontSize: 9.5,
      bold: true,
    );
    _drawCadLabel(
      canvas,
      '${prototype.manufacturerName} | ${prototype.phase.label}',
      Offset(blockRect.left + 8, blockRect.top + 21),
      color: AppColors.textSecondary,
      fontSize: 8.5,
    );
    _drawCadLabel(
      canvas,
      'SCALE 1:5 | SEED #${prototype.cadBlueprintSeed} | ${prototype.secrecyLevel.label.toUpperCase()}',
      Offset(blockRect.left + 8, blockRect.top + 35),
      color: prototype.secrecyLevel.color,
      fontSize: 8.0,
      bold: true,
    );
  }

  void _drawCadTube(
    Canvas canvas,
    Offset a,
    Offset b,
    double thickness,
    Paint outerPaint,
    Paint centerPaint,
  ) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) return;

    final nx = -dy / len * (thickness * 0.5);
    final ny = dx / len * (thickness * 0.5);
    final n = Offset(nx, ny);

    canvas.drawLine(a + n, b + n, outerPaint);
    canvas.drawLine(a - n, b - n, outerPaint);
    _drawDashedLine(canvas, a, b, centerPaint, dash: 4, gap: 4);
  }

  void _drawDimensionArrowLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint,
  ) {
    canvas.drawLine(a, b, paint);
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    const arrowLen = 6.0;
    const spread = 0.45;

    for (final sign in [1.0, -1.0]) {
      final base = sign > 0 ? a : b;
      final dir = sign > 0 ? angle : angle + math.pi;
      canvas.drawLine(
        base,
        base + Offset(math.cos(dir + spread) * arrowLen, math.sin(dir + spread) * arrowLen),
        paint,
      );
      canvas.drawLine(
        base,
        base + Offset(math.cos(dir - spread) * arrowLen, math.sin(dir - spread) * arrowLen),
        paint,
      );
    }
  }

  void _drawDashedRect(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    double dash = 6,
    double gap = 4,
  }) {
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dash: dash, gap: gap);
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dash: dash, gap: gap);
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dash: dash, gap: gap);
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dash: dash, gap: gap);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    double dash = 5,
    double gap = 4,
  }) {
    final total = (b - a).distance;
    if (total <= 0.1) return;
    final dir = (b - a) / total;
    double covered = 0.0;
    while (covered < total) {
      final end = math.min(covered + dash, total);
      canvas.drawLine(a + dir * covered, a + dir * end, paint);
      covered += dash + gap;
    }
  }

  void _drawCadLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    double fontSize = 10.0,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant SkunkworksPrototypeBlueprintPainter oldDelegate) {
    return oldDelegate.prototype.id != prototype.id ||
        oldDelegate.prototype.phase != prototype.phase ||
        oldDelegate.prototype.developmentProgress != prototype.developmentProgress ||
        oldDelegate.viewMode != viewMode ||
        oldDelegate.colorTheme != colorTheme ||
        oldDelegate.selectedPinId != selectedPinId ||
        oldDelegate.hoveredPinId != hoveredPinId ||
        oldDelegate.cfdAnimationProgress != cfdAnimationProgress ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.activeLayers.length != activeLayers.length ||
        !oldDelegate.activeLayers.containsAll(activeLayers);
  }
}

/// Pełny interaktywny panel inżynieryjny Blueprint CAD prototypu Skunkworks
/// z obsługą warstw, rzutów, powiększenia, stanów hover/active/disabled/focus
/// oraz pełną responsywnością 390x844 / 1024x768 / 1600x900.
class SkunkworksPrototypeBlueprintWidget extends StatefulWidget {
  final SkunkworksPrototypeSpec prototype;
  final BlueprintViewMode initialViewMode;
  final BlueprintColorTheme initialColorTheme;
  final bool enabled;
  final ValueChanged<BlueprintCalloutPin?>? onCalloutSelected;
  final VoidCallback? onExportBlueprint;

  const SkunkworksPrototypeBlueprintWidget({
    super.key,
    required this.prototype,
    this.initialViewMode = BlueprintViewMode.sideProfile,
    this.initialColorTheme = BlueprintColorTheme.classicCyan,
    this.enabled = true,
    this.onCalloutSelected,
    this.onExportBlueprint,
  });

  @override
  State<SkunkworksPrototypeBlueprintWidget> createState() =>
      _SkunkworksPrototypeBlueprintWidgetState();
}

class _SkunkworksPrototypeBlueprintWidgetState
    extends State<SkunkworksPrototypeBlueprintWidget>
    with SingleTickerProviderStateMixin {
  late BlueprintViewMode _viewMode;
  late BlueprintColorTheme _colorTheme;
  late Set<BlueprintLayerOption> _activeLayers;
  late AnimationController _cfdController;
  final FocusNode _canvasFocusNode = FocusNode(debugLabel: 'BlueprintCanvas');

  String? _selectedPinId;
  String? _hoveredPinId;
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  bool _isCanvasFocused = false;
  bool _isCfdPaused = false;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialViewMode;
    _colorTheme = widget.initialColorTheme;
    _activeLayers = <BlueprintLayerOption>{
      BlueprintLayerOption.grid,
      BlueprintLayerOption.dimensions,
      BlueprintLayerOption.airflowVectors,
      BlueprintLayerOption.uciBoxOverlay,
      BlueprintLayerOption.callouts,
    };

    _cfdController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.enabled) {
      _cfdController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SkunkworksPrototypeBlueprintWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled && !_isCfdPaused) {
        _cfdController.repeat();
      } else {
        _cfdController.stop();
      }
    }
  }

  @override
  void dispose() {
    _cfdController.dispose();
    _canvasFocusNode.dispose();
    super.dispose();
  }

  void _selectPin(BlueprintCalloutPin? pin) {
    if (!widget.enabled) return;
    setState(() {
      _selectedPinId = pin?.id == _selectedPinId ? null : pin?.id;
    });
    widget.onCalloutSelected?.call(
      _selectedPinId == null ? null : pin,
    );
  }

  void _adjustZoom(double delta) {
    if (!widget.enabled) return;
    setState(() {
      _zoomScale = (_zoomScale + delta).clamp(0.85, 2.4);
      if (_zoomScale <= 1.0) {
        _panOffset = Offset.zero;
      }
    });
  }

  void _resetView() {
    if (!widget.enabled) return;
    setState(() {
      _zoomScale = 1.0;
      _panOffset = Offset.zero;
    });
  }

  void _toggleCfdPlayback() {
    if (!widget.enabled) return;
    setState(() {
      _isCfdPaused = !_isCfdPaused;
      if (_isCfdPaused) {
        _cfdController.stop();
      } else {
        _cfdController.repeat();
      }
    });
  }

  BlueprintCalloutPin? _findHitPin(
    Offset localPosition,
    Size canvasSize,
    List<BlueprintCalloutPin> pins,
  ) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return null;
    for (final pin in pins) {
      final pinPos = Offset(
        pin.normalizedPosition.dx * canvasSize.width,
        pin.normalizedPosition.dy * canvasSize.height,
      );
      if ((localPosition - pinPos).distance <= 22.0) {
        return pin;
      }
    }
    return null;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.digit1) {
      setState(() => _viewMode = BlueprintViewMode.sideProfile);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit2) {
      setState(() => _viewMode = BlueprintViewMode.aeroCrossSection);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit3) {
      setState(() => _viewMode = BlueprintViewMode.drivetrainDetail);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit4) {
      setState(() => _viewMode = BlueprintViewMode.explodedWireframe);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _toggleCfdPlayback();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      _resetView();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final geometry =
        SkunkworksBlueprintGeometryCalculator.computeGeometry(widget.prototype);
    final calloutPins = SkunkworksBlueprintGeometryCalculator.buildCalloutPins(
      widget.prototype,
      geometry,
    );

    final selectedPin = calloutPins.cast<BlueprintCalloutPin?>().firstWhere(
          (p) => p?.id == _selectedPinId,
          orElse: () => calloutPins.first,
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCanvasFocused ? AppColors.cyanAccent : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;
          final isDesktopWide = constraints.maxWidth >= 1040;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 12),
              _buildToolbar(isCompact),
              const SizedBox(height: 12),
              if (isDesktopWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _buildCanvasViewport(
                        geometry,
                        calloutPins,
                        height: 410,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: _buildInspectorSidebar(
                        geometry,
                        calloutPins,
                        selectedPin,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildCanvasViewport(
                  geometry,
                  calloutPins,
                  height: isCompact ? 240 : 340,
                ),
                const SizedBox(height: 12),
                _buildInspectorSidebar(
                  geometry,
                  calloutPins,
                  selectedPin,
                ),
              ],
              const SizedBox(height: 12),
              _buildLayerToggleRow(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Icon(
                widget.prototype.category.icon,
                color: AppColors.cyanAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAD BLUEPRINT: ${widget.prototype.codename}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${widget.prototype.category.label} • ${widget.prototype.targetRaceName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _BlueprintBadge(
              label: widget.enabled
                  ? widget.prototype.secrecyLevel.label
                  : 'TRYB PODGLĄDU',
              color: widget.enabled
                  ? widget.prototype.secrecyLevel.color
                  : AppColors.textSecondary,
            ),
            if (widget.onExportBlueprint != null)
              _BlueprintActionButton(
                icon: Icons.download_rounded,
                label: 'Eksport CAD',
                enabled: widget.enabled,
                onPressed: widget.onExportBlueprint!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isCompact) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: BlueprintViewMode.values.map((mode) {
            final isSelected = _viewMode == mode;
            return _BlueprintModeChip(
              icon: mode.icon,
              label: isCompact ? mode.shortCode : mode.label,
              selected: isSelected,
              enabled: widget.enabled,
              onTap: () => setState(() => _viewMode = mode),
            );
          }).toList(),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...BlueprintColorTheme.values.map((theme) {
              final isSelected = _colorTheme == theme;
              return _BlueprintModeChip(
                icon: Icons.palette_outlined,
                label: theme.label,
                selected: isSelected,
                enabled: widget.enabled,
                accentOverride: theme.primaryStroke,
                onTap: () => setState(() => _colorTheme = theme),
              );
            }),
            _BlueprintActionButton(
              icon: _isCfdPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: _isCfdPaused ? 'CFD Start' : 'CFD Pauza',
              enabled: widget.enabled,
              onPressed: _toggleCfdPlayback,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCanvasViewport(
    SkunkworksCadGeometrySpec geometry,
    List<BlueprintCalloutPin> pins, {
    required double height,
  }) {
    return Focus(
      focusNode: _canvasFocusNode,
      onFocusChange: (focused) => setState(() => _isCanvasFocused = focused),
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(constraints.maxWidth, height);
          return MouseRegion(
            cursor: widget.enabled
                ? (_hoveredPinId != null
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.precise)
                : SystemMouseCursors.forbidden,
            onHover: (event) {
              if (!widget.enabled) return;
              final hit = _findHitPin(event.localPosition, canvasSize, pins);
              if (hit?.id != _hoveredPinId) {
                setState(() => _hoveredPinId = hit?.id);
              }
            },
            onExit: (_) {
              if (_hoveredPinId != null) {
                setState(() => _hoveredPinId = null);
              }
            },
            child: GestureDetector(
              onTapUp: (details) {
                if (!widget.enabled) return;
                _canvasFocusNode.requestFocus();
                final hit = _findHitPin(details.localPosition, canvasSize, pins);
                if (hit != null) {
                  _selectPin(hit);
                }
              },
              onPanUpdate: (details) {
                if (!widget.enabled || _zoomScale <= 1.0) return;
                setState(() {
                  _panOffset = Offset(
                    (_panOffset.dx + details.delta.dx).clamp(-120.0, 120.0),
                    (_panOffset.dy + details.delta.dy).clamp(-80.0, 80.0),
                  );
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    SizedBox(
                      width: canvasSize.width,
                      height: height,
                      child: AnimatedBuilder(
                        animation: _cfdController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: canvasSize,
                            painter: SkunkworksPrototypeBlueprintPainter(
                              prototype: widget.prototype,
                              geometry: geometry,
                              viewMode: _viewMode,
                              activeLayers: _activeLayers,
                              colorTheme: _colorTheme,
                              calloutPins: pins,
                              selectedPinId: _selectedPinId,
                              hoveredPinId: _hoveredPinId,
                              cfdAnimationProgress: _cfdController.value,
                              zoomScale: _zoomScale,
                              panOffset: _panOffset,
                              isDisabled: !widget.enabled,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BlueprintIconButton(
                            icon: Icons.zoom_in_rounded,
                            tooltip: 'Przybliż CAD',
                            enabled: widget.enabled,
                            onPressed: () => _adjustZoom(0.25),
                          ),
                          const SizedBox(width: 4),
                          _BlueprintIconButton(
                            icon: Icons.zoom_out_rounded,
                            tooltip: 'Oddal CAD',
                            enabled: widget.enabled,
                            onPressed: () => _adjustZoom(-0.25),
                          ),
                          const SizedBox(width: 4),
                          _BlueprintIconButton(
                            icon: Icons.center_focus_strong_rounded,
                            tooltip: 'Reset 1:1',
                            enabled: widget.enabled,
                            onPressed: _resetView,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInspectorSidebar(
    SkunkworksCadGeometrySpec geometry,
    List<BlueprintCalloutPin> pins,
    BlueprintCalloutPin? activePin,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TELEMETRIA INŻYNIERYJNA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '${(widget.prototype.developmentProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricTile(
                label: 'Delta CdA',
                value: '${widget.prototype.cdaDeltaPercent.toStringAsFixed(1)}%',
                accent: AppColors.cyanAccent,
              ),
              _MetricTile(
                label: 'Redukcja Masy',
                value: '${widget.prototype.weightDeltaGrams} g',
                accent: AppColors.statusSuccess,
              ),
              _MetricTile(
                label: 'Opór CFD @45km/h',
                value: '-${geometry.cfdDragReductionN.toStringAsFixed(1)} N',
                accent: AppColors.accentBlue,
              ),
              _MetricTile(
                label: 'Szczyt FEA',
                value: '${geometry.peakStressMpa.toStringAsFixed(0)} MPa',
                accent: widget.prototype.failureRiskPercent >= 12.0
                    ? AppColors.amberWarning
                    : AppColors.textPrimary,
              ),
            ],
          ),
          if (activePin != null) ...[
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activePin.accentColor.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '#${activePin.indexNumber} ${activePin.title}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activePin.metricValue,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: activePin.accentColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activePin.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pins.map((pin) {
              final selected = pin.id == _selectedPinId;
              return _BlueprintModeChip(
                icon: Icons.push_pin_outlined,
                label: '#${pin.indexNumber}',
                selected: selected,
                enabled: widget.enabled,
                accentOverride: pin.accentColor,
                onTap: () => _selectPin(pin),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerToggleRow() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'WARSTWY CAD:',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        ...BlueprintLayerOption.values.map((layer) {
          final active = _activeLayers.contains(layer);
          return _BlueprintModeChip(
            icon: active ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            label: layer.label,
            selected: active,
            enabled: widget.enabled,
            onTap: () {
              setState(() {
                if (active) {
                  _activeLayers.remove(layer);
                } else {
                  _activeLayers.add(layer);
                }
              });
            },
          );
        }),
      ],
    );
  }
}

class _BlueprintBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _BlueprintBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _BlueprintModeChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final Color? accentOverride;
  final VoidCallback onTap;

  const _BlueprintModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.accentOverride,
  });

  @override
  State<_BlueprintModeChip> createState() => _BlueprintModeChipState();
}

class _BlueprintModeChipState extends State<_BlueprintModeChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentOverride ?? AppColors.cyanAccent;
    final bgColor = !widget.enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : widget.selected
            ? accent.withValues(alpha: 0.18)
            : _pressed
                ? AppColors.surface
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.45)
        : _focused
            ? AppColors.goldAccent
            : widget.selected
                ? accent
                : _hovered
                    ? accent.withValues(alpha: 0.5)
                    : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13.5,
                color: !widget.enabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : widget.selected
                        ? accent
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: !widget.enabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : widget.selected
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

class _BlueprintActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _BlueprintActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_BlueprintActionButton> createState() => _BlueprintActionButtonState();
}

class _BlueprintActionButtonState extends State<_BlueprintActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: !widget.enabled
                ? AppColors.surface.withValues(alpha: 0.45)
                : _hovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.25)
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : _hovered
                      ? AppColors.primaryAccent
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlueprintIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  const _BlueprintIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_BlueprintIconButton> createState() => _BlueprintIconButtonState();
}

class _BlueprintIconButtonState extends State<_BlueprintIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : _hovered
                        ? AppColors.cyanAccent
                        : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
