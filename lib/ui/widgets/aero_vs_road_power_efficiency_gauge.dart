// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/motor_pacing_and_aero_tuck_adaptation.dart';

/// Klasyfikacja efektywności generowania mocy w pozycji aerodynamicznej (lemondka)
/// względem szosowego progu FTP.
enum AeroPowerEfficiencyTier {
  /// >= 96.0% szosowego FTP na lemondce.
  elite('Elitarna Adaptacja TT', AppColors.goldAccent),

  /// 92.0% - 95.9% szosowego FTP na lemondce.
  optimal('Wysoka Efektywność', AppColors.statusSuccess),

  /// 87.0% - 91.9% szosowego FTP na lemondce.
  moderate('Średnia Adaptacja', AppColors.amberWarning),

  /// < 87.0% szosowego FTP na lemondce (wysoka strata okluzji / oddechu).
  compromised('Strata Okluzji Biodra', AppColors.crimsonAlert);

  final String labelPl;
  final Color color;

  const AeroPowerEfficiencyTier(this.labelPl, this.color);
}

/// Tryb prezentacji głównego łuku telemetrycznego wskaźnika.
enum AeroGaugeDisplayMode {
  /// Procent zachowania mocy na lemondce względem szosowego FTP.
  powerRetention('Retencja FTP %'),

  /// Zysk efektywności aerodynamicznej W/CdA (waty na metr kwadratowy oporu).
  wattsPerCda('Efektywność W/CdA');

  final String labelPl;

  const AeroGaugeDisplayMode(this.labelPl);
}

/// Dane wejściowe dla wskaźnika efektywności mocy na lemondce względem szosowego FTP.
class AeroVsRoadComparisonData {
  final String riderName;
  final double roadFtpWatts;
  final double aeroTtPowerWatts;
  final double roadCda;
  final double aeroCda;
  final AeroTuckPosturePreset posturePreset;
  final double adaptationScore;
  final double hipOcclusionPenaltyPct;
  final double respiratoryCostPenaltyPct;
  final double targetSpeedKmh;
  final double estimatedTimeGain40KmSeconds;

  const AeroVsRoadComparisonData({
    required this.riderName,
    required this.roadFtpWatts,
    required this.aeroTtPowerWatts,
    this.roadCda = 0.285,
    this.aeroCda = 0.214,
    this.posturePreset = AeroTuckPosturePreset.standardTtExtensions,
    this.adaptationScore = 75.0,
    this.hipOcclusionPenaltyPct = 3.2,
    this.respiratoryCostPenaltyPct = 2.1,
    this.targetSpeedKmh = 51.2,
    this.estimatedTimeGain40KmSeconds = 138.0,
  });

  /// Tworzy model porównania bezpośrednio z wyniku silnika adaptacji TT (#640).
  factory AeroVsRoadComparisonData.fromAeroTuckResult({
    required String riderName,
    required double roadFtpWatts,
    required AeroTuckPowerAndCdaResult result,
    AeroTuckPosturePreset posturePreset =
        AeroTuckPosturePreset.standardTtExtensions,
    double roadCda = 0.285,
    double adaptationScore = 75.0,
  }) {
    return AeroVsRoadComparisonData(
      riderName: riderName,
      roadFtpWatts: roadFtpWatts,
      aeroTtPowerWatts: result.effectiveSustainablePowerWatts,
      roadCda: roadCda,
      aeroCda: result.effectiveCda,
      posturePreset: posturePreset,
      adaptationScore: adaptationScore,
      hipOcclusionPenaltyPct: result.hipOcclusionFactor * 100.0,
      respiratoryCostPenaltyPct: result.respiratoryCostFactor * 100.0,
      targetSpeedKmh: result.predictedTtSpeedKmh,
      estimatedTimeGain40KmSeconds: result.timeSavedOver40KmSeconds,
    );
  }

  /// Tworzy kopię danych z nadpisanymi parametrami.
  AeroVsRoadComparisonData copyWith({
    String? riderName,
    double? roadFtpWatts,
    double? aeroTtPowerWatts,
    double? roadCda,
    double? aeroCda,
    AeroTuckPosturePreset? posturePreset,
    double? adaptationScore,
    double? hipOcclusionPenaltyPct,
    double? respiratoryCostPenaltyPct,
    double? targetSpeedKmh,
    double? estimatedTimeGain40KmSeconds,
  }) {
    return AeroVsRoadComparisonData(
      riderName: riderName ?? this.riderName,
      roadFtpWatts: roadFtpWatts ?? this.roadFtpWatts,
      aeroTtPowerWatts: aeroTtPowerWatts ?? this.aeroTtPowerWatts,
      roadCda: roadCda ?? this.roadCda,
      aeroCda: aeroCda ?? this.aeroCda,
      posturePreset: posturePreset ?? this.posturePreset,
      adaptationScore: adaptationScore ?? this.adaptationScore,
      hipOcclusionPenaltyPct:
          hipOcclusionPenaltyPct ?? this.hipOcclusionPenaltyPct,
      respiratoryCostPenaltyPct:
          respiratoryCostPenaltyPct ?? this.respiratoryCostPenaltyPct,
      targetSpeedKmh: targetSpeedKmh ?? this.targetSpeedKmh,
      estimatedTimeGain40KmSeconds:
          estimatedTimeGain40KmSeconds ?? this.estimatedTimeGain40KmSeconds,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'riderName': riderName,
        'roadFtpWatts': roadFtpWatts,
        'aeroTtPowerWatts': aeroTtPowerWatts,
        'roadCda': roadCda,
        'aeroCda': aeroCda,
        'posturePreset': posturePreset.name,
        'adaptationScore': adaptationScore,
        'hipOcclusionPenaltyPct': hipOcclusionPenaltyPct,
        'respiratoryCostPenaltyPct': respiratoryCostPenaltyPct,
        'targetSpeedKmh': targetSpeedKmh,
        'estimatedTimeGain40KmSeconds': estimatedTimeGain40KmSeconds,
      };

  factory AeroVsRoadComparisonData.fromJson(Map<String, dynamic> json) {
    final String presetName =
        json['posturePreset'] as String? ?? 'standardTtExtensions';
    final AeroTuckPosturePreset preset = AeroTuckPosturePreset.values.firstWhere(
      (AeroTuckPosturePreset p) => p.name == presetName,
      orElse: () => AeroTuckPosturePreset.standardTtExtensions,
    );
    return AeroVsRoadComparisonData(
      riderName: json['riderName'] as String? ?? 'Kolarz TT',
      roadFtpWatts: (json['roadFtpWatts'] as num?)?.toDouble() ?? 0.0,
      aeroTtPowerWatts: (json['aeroTtPowerWatts'] as num?)?.toDouble() ?? 0.0,
      roadCda: (json['roadCda'] as num?)?.toDouble() ?? 0.285,
      aeroCda: (json['aeroCda'] as num?)?.toDouble() ?? 0.214,
      posturePreset: preset,
      adaptationScore: (json['adaptationScore'] as num?)?.toDouble() ?? 75.0,
      hipOcclusionPenaltyPct:
          (json['hipOcclusionPenaltyPct'] as num?)?.toDouble() ?? 0.0,
      respiratoryCostPenaltyPct:
          (json['respiratoryCostPenaltyPct'] as num?)?.toDouble() ?? 0.0,
      targetSpeedKmh: (json['targetSpeedKmh'] as num?)?.toDouble() ?? 0.0,
      estimatedTimeGain40KmSeconds:
          (json['estimatedTimeGain40KmSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Czysty kalkulator metryk porównawczych mocy TT względem szosowego FTP.
class AeroVsRoadEfficiencyCalculator {
  const AeroVsRoadEfficiencyCalculator._();

  /// Zwraca czy dane mają poprawną bazę FTP i CdA do obliczeń.
  static bool hasValidTelemetry(AeroVsRoadComparisonData? data) {
    if (data == null) return false;
    return data.roadFtpWatts > 0 &&
        data.roadFtpWatts.isFinite &&
        data.aeroTtPowerWatts >= 0 &&
        data.aeroTtPowerWatts.isFinite &&
        data.roadCda > 0 &&
        data.aeroCda > 0;
  }

  /// Stosunek mocy na lemondce do szosowego FTP (np. 0.946).
  static double powerRetentionRatio(AeroVsRoadComparisonData data) {
    if (data.roadFtpWatts <= 0 || !data.roadFtpWatts.isFinite) return 0.0;
    return (data.aeroTtPowerWatts / data.roadFtpWatts).clamp(0.0, 1.25);
  }

  /// Procent zachowania szosowego FTP na lemondce (np. 94.6%).
  static double powerRetentionPercent(AeroVsRoadComparisonData data) {
    return powerRetentionRatio(data) * 100.0;
  }

  /// Różnica mocy w watach między pozycją aero a szosową (np. -22.0 W).
  static double powerDeltaWatts(AeroVsRoadComparisonData data) {
    return data.aeroTtPowerWatts - data.roadFtpWatts;
  }

  /// Procentowa redukcja oporu aerodynamicznego CdA względem pozycji szosowej.
  static double cdaReductionPercent(AeroVsRoadComparisonData data) {
    if (data.roadCda <= 0 || !data.roadCda.isFinite) return 0.0;
    return (((data.roadCda - data.aeroCda) / data.roadCda) * 100.0)
        .clamp(-50.0, 75.0);
  }

  /// Stosunek mocy do oporu CdA [W/m²] w pozycji szosowej.
  static double wattsPerCdaRoad(AeroVsRoadComparisonData data) {
    if (data.roadCda <= 0 || !data.roadCda.isFinite) return 0.0;
    return data.roadFtpWatts / data.roadCda;
  }

  /// Stosunek mocy do oporu CdA [W/m²] na lemondce.
  static double wattsPerCdaAero(AeroVsRoadComparisonData data) {
    if (data.aeroCda <= 0 || !data.aeroCda.isFinite) return 0.0;
    return data.aeroTtPowerWatts / data.aeroCda;
  }

  /// Procentowy zysk netto w metryce W/CdA po przejściu na lemondkę.
  static double netAeroEfficiencyGainPercent(AeroVsRoadComparisonData data) {
    final double roadRatio = wattsPerCdaRoad(data);
    if (roadRatio <= 0) return 0.0;
    final double aeroRatio = wattsPerCdaAero(data);
    return (((aeroRatio - roadRatio) / roadRatio) * 100.0).clamp(-60.0, 120.0);
  }

  /// Klasyfikacja efektywności na podstawie procentu retencji FTP.
  static AeroPowerEfficiencyTier tierForRetention(double retentionPercent) {
    if (retentionPercent >= 96.0) return AeroPowerEfficiencyTier.elite;
    if (retentionPercent >= 92.0) return AeroPowerEfficiencyTier.optimal;
    if (retentionPercent >= 87.0) return AeroPowerEfficiencyTier.moderate;
    return AeroPowerEfficiencyTier.compromised;
  }

  /// Przelicza podglądowe wartości dla wybranego presetu pozycji bez mutacji źródła.
  static AeroVsRoadComparisonData projectForPosture(
    AeroVsRoadComparisonData base,
    AeroTuckPosturePreset targetPosture,
  ) {
    if (targetPosture == base.posturePreset) return base;
    final double adaptationFactor =
        (base.adaptationScore.clamp(0.0, 100.0) / 100.0);
    final double effectiveDropPct =
        targetPosture.basePowerDropPct * (1.0 - 0.55 * adaptationFactor);
    final double projectedPower =
        base.roadFtpWatts * (1.0 - effectiveDropPct / 100.0);
    final double projectedCda = base.roadCda * targetPosture.cdaMultiplier;
    final double occlusionPct =
        (targetPosture.basePowerDropPct * 0.52 * (1.0 - 0.45 * adaptationFactor))
            .clamp(0.0, 15.0);
    final double respPct =
        (targetPosture.neckCoreDemand * 3.8 * (1.0 - 0.40 * adaptationFactor))
            .clamp(0.0, 10.0);

    return base.copyWith(
      posturePreset: targetPosture,
      aeroTtPowerWatts: projectedPower,
      aeroCda: projectedCda,
      hipOcclusionPenaltyPct: occlusionPct,
      respiratoryCostPenaltyPct: respPct,
    );
  }
}

/// Rysuje zaawansowany łukowy wskaźnik efektywności mocy TT względem szosowego FTP.
class AeroVsRoadEfficiencyGaugePainter extends CustomPainter {
  final double animatedRetentionPercent;
  final double animatedNetGainPercent;
  final AeroGaugeDisplayMode displayMode;
  final AeroPowerEfficiencyTier tier;
  final bool isDisabled;
  final bool isHovered;

  const AeroVsRoadEfficiencyGaugePainter({
    required this.animatedRetentionPercent,
    required this.animatedNetGainPercent,
    required this.displayMode,
    required this.tier,
    this.isDisabled = false,
    this.isHovered = false,
  });

  static const double _startAngleRad = math.pi * 0.78; // 140.4 deg
  static const double _sweepAngleRad = math.pi * 1.44; // 259.2 deg
  static const double _minRetentionScale = 75.0;
  static const double _maxRetentionScale = 105.0;

  @override
  void paint(Canvas canvas, Size size) {
    final double diameter = math.min(size.width, size.height);
    final Offset center = Offset(size.width / 2, size.height * 0.54);
    final double outerRadius = (diameter * 0.42).clamp(48.0, 140.0);
    final double innerRadius = outerRadius - 18.0;

    final Rect outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final Rect innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    // 1. Tło głównego toru
    final Paint trackPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: isDisabled ? 0.35 : 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(outerRect, _startAngleRad, _sweepAngleRad, false, trackPaint);

    // 2. Pasek stref jakościowych na zewnętrznej krawędzi
    _drawZoneBand(canvas, center, outerRadius + 9.0);

    // 3. Aktywny łuk retencji FTP lub W/CdA
    final double normalizedPrimary = displayMode == AeroGaugeDisplayMode.powerRetention
        ? ((animatedRetentionPercent - _minRetentionScale) /
                (_maxRetentionScale - _minRetentionScale))
            .clamp(0.0, 1.0)
        : ((animatedNetGainPercent + 10.0) / 50.0).clamp(0.0, 1.0);

    final Color activeColor = isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : (displayMode == AeroGaugeDisplayMode.powerRetention
            ? tier.color
            : AppColors.cyanAccent);

    if (normalizedPrimary > 0.005) {
      if (isHovered && !isDisabled) {
        final Paint glowPaint = Paint()
          ..color = activeColor.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        canvas.drawArc(
          outerRect,
          _startAngleRad,
          _sweepAngleRad * normalizedPrimary,
          false,
          glowPaint,
        );
      }

      final Paint activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        outerRect,
        _startAngleRad,
        _sweepAngleRad * normalizedPrimary,
        false,
        activePaint,
      );
    }

    // 4. Wewnętrzny łuk pomocniczy (W/CdA lub retencja FTP w drugim trybie)
    final Paint innerTrackPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: isDisabled ? 0.25 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      innerRect,
      _startAngleRad,
      _sweepAngleRad,
      false,
      innerTrackPaint,
    );

    final double normalizedSecondary = displayMode == AeroGaugeDisplayMode.powerRetention
        ? ((animatedNetGainPercent + 10.0) / 50.0).clamp(0.0, 1.0)
        : ((animatedRetentionPercent - _minRetentionScale) /
                (_maxRetentionScale - _minRetentionScale))
            .clamp(0.0, 1.0);

    if (normalizedSecondary > 0.005) {
      final Paint innerActivePaint = Paint()
        ..color = isDisabled
            ? AppColors.textSecondary.withValues(alpha: 0.3)
            : (displayMode == AeroGaugeDisplayMode.powerRetention
                ? AppColors.accentBlue
                : tier.color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        innerRect,
        _startAngleRad,
        _sweepAngleRad * normalizedSecondary,
        false,
        innerActivePaint,
      );
    }

    // 5. Podziałka i znacznik 100% szosowego FTP
    _drawScaleTicks(canvas, center, outerRadius);

    // 6. Wskazówka (igła) na końcu aktywnego łuku
    final double pointerAngle =
        _startAngleRad + _sweepAngleRad * normalizedPrimary;
    final Offset tipOuter = Offset(
      center.dx + (outerRadius + 4.0) * math.cos(pointerAngle),
      center.dy + (outerRadius + 4.0) * math.sin(pointerAngle),
    );
    final Offset tipInner = Offset(
      center.dx + (outerRadius - 14.0) * math.cos(pointerAngle),
      center.dy + (outerRadius - 14.0) * math.sin(pointerAngle),
    );

    final Paint needlePaint = Paint()
      ..color = isDisabled ? AppColors.textSecondary : AppColors.textPrimary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tipInner, tipOuter, needlePaint);

    final Paint dotPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(
        center.dx + outerRadius * math.cos(pointerAngle),
        center.dy + outerRadius * math.sin(pointerAngle),
      ),
      4.5,
      dotPaint,
    );
  }

  void _drawZoneBand(Canvas canvas, Offset center, double radius) {
    final Rect bandRect = Rect.fromCircle(center: center, radius: radius);
    const List<(double, double, Color)> zones = <(double, double, Color)>[
      (75.0, 87.0, AppColors.crimsonAlert),
      (87.0, 92.0, AppColors.amberWarning),
      (92.0, 96.0, AppColors.statusSuccess),
      (96.0, 105.0, AppColors.goldAccent),
    ];

    for (final (double from, double to, Color color) in zones) {
      final double t0 = (from - _minRetentionScale) /
          (_maxRetentionScale - _minRetentionScale);
      final double t1 = (to - _minRetentionScale) /
          (_maxRetentionScale - _minRetentionScale);
      final Paint paint = Paint()
        ..color = color.withValues(alpha: isDisabled ? 0.15 : 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        bandRect,
        _startAngleRad + _sweepAngleRad * t0,
        _sweepAngleRad * (t1 - t0),
        false,
        paint,
      );
    }
  }

  void _drawScaleTicks(Canvas canvas, Offset center, double outerRadius) {
    const List<double> ticks = <double>[75, 80, 85, 90, 95, 100, 105];
    for (final double tick in ticks) {
      final double t = (tick - _minRetentionScale) /
          (_maxRetentionScale - _minRetentionScale);
      final double angle = _startAngleRad + _sweepAngleRad * t;
      final bool isFtpBaseline = tick == 100;
      final double rStart = outerRadius - (isFtpBaseline ? 10.0 : 8.0);
      final double rEnd = outerRadius + (isFtpBaseline ? 6.0 : 4.0);
      final Paint tickPaint = Paint()
        ..color = isFtpBaseline
            ? AppColors.goldAccent.withValues(alpha: isDisabled ? 0.3 : 0.85)
            : AppColors.textSecondary.withValues(alpha: isDisabled ? 0.2 : 0.45)
        ..strokeWidth = isFtpBaseline ? 2.0 : 1.0;

      canvas.drawLine(
        Offset(center.dx + rStart * math.cos(angle),
            center.dy + rStart * math.sin(angle)),
        Offset(center.dx + rEnd * math.cos(angle),
            center.dy + rEnd * math.sin(angle)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AeroVsRoadEfficiencyGaugePainter oldDelegate) {
    return oldDelegate.animatedRetentionPercent != animatedRetentionPercent ||
        oldDelegate.animatedNetGainPercent != animatedNetGainPercent ||
        oldDelegate.displayMode != displayMode ||
        oldDelegate.tier != tier ||
        oldDelegate.isDisabled != isDisabled ||
        oldDelegate.isHovered != isHovered;
  }
}

/// Wskaźnik efektywności mocy na lemondce (TT) względem szosowego FTP.
///
/// Prezentuje porównanie generowanej mocy na przystawce czasowej vs pozycja
/// szosowa, straty wynikające z okluzji biodra i ucisku przepony, efektywność
/// aerodynamiczną `W/CdA`, prognozowany zysk czasowy na 40 km ITT oraz
/// interaktywny przełącznik pozycji aero.
class AeroVsRoadPowerEfficiencyGauge extends StatefulWidget {
  final AeroVsRoadComparisonData? data;
  final bool isDisabled;
  final bool compact;
  final ValueChanged<AeroTuckPosturePreset>? onPostureSelected;
  final VoidCallback? onOptimizePressed;
  final EdgeInsetsGeometry? padding;

  const AeroVsRoadPowerEfficiencyGauge({
    super.key,
    required this.data,
    this.isDisabled = false,
    this.compact = false,
    this.onPostureSelected,
    this.onOptimizePressed,
    this.padding,
  });

  @override
  State<AeroVsRoadPowerEfficiencyGauge> createState() =>
      _AeroVsRoadPowerEfficiencyGaugeState();
}

class _AeroVsRoadPowerEfficiencyGaugeState
    extends State<AeroVsRoadPowerEfficiencyGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _retentionAnim;
  late Animation<double> _netGainAnim;

  AeroGaugeDisplayMode _displayMode = AeroGaugeDisplayMode.powerRetention;
  AeroTuckPosturePreset? _previewPosture;
  bool _isGaugeHovered = false;
  bool _isGaugeFocused = false;

  double _currentRetention = 0.0;
  double _currentNetGain = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final AeroVsRoadComparisonData? effective = _effectiveData;
    _currentRetention = effective != null &&
            AeroVsRoadEfficiencyCalculator.hasValidTelemetry(effective)
        ? AeroVsRoadEfficiencyCalculator.powerRetentionPercent(effective)
        : 0.0;
    _currentNetGain = effective != null &&
            AeroVsRoadEfficiencyCalculator.hasValidTelemetry(effective)
        ? AeroVsRoadEfficiencyCalculator.netAeroEfficiencyGainPercent(effective)
        : 0.0;

    _retentionAnim = AlwaysStoppedAnimation<double>(_currentRetention);
    _netGainAnim = AlwaysStoppedAnimation<double>(_currentNetGain);
  }

  @override
  void didUpdateWidget(covariant AeroVsRoadPowerEfficiencyGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      if (widget.data?.posturePreset != oldWidget.data?.posturePreset) {
        _previewPosture = null;
      }
      _animateToEffectiveData();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  AeroVsRoadComparisonData? get _effectiveData {
    final AeroVsRoadComparisonData? raw = widget.data;
    if (raw == null) return null;
    if (_previewPosture != null && _previewPosture != raw.posturePreset) {
      return AeroVsRoadEfficiencyCalculator.projectForPosture(
        raw,
        _previewPosture!,
      );
    }
    return raw;
  }

  void _animateToEffectiveData() {
    final AeroVsRoadComparisonData? effective = _effectiveData;
    final double targetRetention = effective != null &&
            AeroVsRoadEfficiencyCalculator.hasValidTelemetry(effective)
        ? AeroVsRoadEfficiencyCalculator.powerRetentionPercent(effective)
        : 0.0;
    final double targetNetGain = effective != null &&
            AeroVsRoadEfficiencyCalculator.hasValidTelemetry(effective)
        ? AeroVsRoadEfficiencyCalculator.netAeroEfficiencyGainPercent(effective)
        : 0.0;

    _retentionAnim = Tween<double>(
      begin: _currentRetention,
      end: targetRetention,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _netGainAnim = Tween<double>(
      begin: _currentNetGain,
      end: targetNetGain,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _currentRetention = targetRetention;
    _currentNetGain = targetNetGain;
    _controller.forward(from: 0.0);
  }

  void _handlePostureTap(AeroTuckPosturePreset preset) {
    if (widget.isDisabled) return;
    setState(() {
      _previewPosture = preset;
    });
    _animateToEffectiveData();
    widget.onPostureSelected?.call(preset);
  }

  void _handleModeToggle(AeroGaugeDisplayMode mode) {
    if (widget.isDisabled || _displayMode == mode) return;
    setState(() {
      _displayMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AeroVsRoadComparisonData? effective = _effectiveData;
    final bool valid = AeroVsRoadEfficiencyCalculator.hasValidTelemetry(effective);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useCompactLayout =
            widget.compact || constraints.maxWidth < 540;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.isDisabled ? 0.55 : 1.0,
          child: Container(
            padding: widget.padding ?? EdgeInsets.all(useCompactLayout ? 14 : 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isGaugeFocused
                    ? AppColors.goldAccent
                    : const Color(0xFF2A2F3D),
                width: 1.0,
              ),
            ),
            child: valid && effective != null
                ? _buildContent(effective, useCompactLayout)
                : _buildEmptyState(useCompactLayout),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool useCompactLayout) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildHeader(null, null, useCompactLayout),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.speed_rounded,
                color: AppColors.textSecondary,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Brak danych telemetrycznych FTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Uzupełnij bazowe FTP szosowe oraz CdA kolarza, aby obliczyć efektywność na lemondce.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    AeroVsRoadComparisonData data,
    bool useCompactLayout,
  ) {
    final double retentionPct =
        AeroVsRoadEfficiencyCalculator.powerRetentionPercent(data);
    final AeroPowerEfficiencyTier tier =
        AeroVsRoadEfficiencyCalculator.tierForRetention(retentionPct);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeader(data, tier, useCompactLayout),
        const SizedBox(height: 14),
        if (useCompactLayout) ...<Widget>[
          Center(child: _buildInteractiveGauge(data, tier, 200)),
          const SizedBox(height: 14),
          _buildMetricsPanel(data, tier, useCompactLayout),
        ] else ...<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 224,
                child: _buildInteractiveGauge(data, tier, 224),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _buildMetricsPanel(data, tier, useCompactLayout),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        _buildPostureSelector(data.posturePreset),
        if (widget.onOptimizePressed != null) ...<Widget>[
          const SizedBox(height: 12),
          _buildOptimizeAction(),
        ],
      ],
    );
  }

  Widget _buildHeader(
    AeroVsRoadComparisonData? data,
    AeroPowerEfficiencyTier? tier,
    bool useCompactLayout,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.air_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'EFEKTYWNOŚĆ MOCY AERO VS SZOSA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (data != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                '${data.riderName} • ${data.posturePreset.labelPl}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        if (tier != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tier.color.withValues(alpha: 0.55),
              ),
            ),
            child: Text(
              tier.labelPl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tier.color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractiveGauge(
    AeroVsRoadComparisonData data,
    AeroPowerEfficiencyTier tier,
    double size,
  ) {
    final double deltaW = AeroVsRoadEfficiencyCalculator.powerDeltaWatts(data);
    final String deltaSign = deltaW >= 0 ? '+' : '';

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowFocusHighlight: (bool focused) {
        if (_isGaugeFocused != focused) {
          setState(() => _isGaugeFocused = focused);
        }
      },
      onShowHoverHighlight: (bool hovered) {
        if (_isGaugeHovered != hovered) {
          setState(() => _isGaugeHovered = hovered);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            final AeroGaugeDisplayMode next =
                _displayMode == AeroGaugeDisplayMode.powerRetention
                    ? AeroGaugeDisplayMode.wattsPerCda
                    : AeroGaugeDisplayMode.powerRetention;
            _handleModeToggle(next);
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.isDisabled
            ? null
            : () {
                final AeroGaugeDisplayMode next =
                    _displayMode == AeroGaugeDisplayMode.powerRetention
                        ? AeroGaugeDisplayMode.wattsPerCda
                        : AeroGaugeDisplayMode.powerRetention;
                _handleModeToggle(next);
              },
        child: MouseRegion(
          cursor: widget.isDisabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: SizedBox(
            width: size,
            height: size * 0.86,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double retentionVal = _retentionAnim.value;
                final double netGainVal = _netGainAnim.value;
                final String mainReadout =
                    _displayMode == AeroGaugeDisplayMode.powerRetention
                        ? '${retentionVal.toStringAsFixed(1)}%'
                        : '${netGainVal >= 0 ? '+' : ''}${netGainVal.toStringAsFixed(1)}%';
                final String subLabel =
                    _displayMode == AeroGaugeDisplayMode.powerRetention
                        ? 'RETENCJA FTP'
                        : 'ZYSK W/CdA';

                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    CustomPaint(
                      size: Size(size, size * 0.86),
                      painter: AeroVsRoadEfficiencyGaugePainter(
                        animatedRetentionPercent: retentionVal,
                        animatedNetGainPercent: netGainVal,
                        displayMode: _displayMode,
                        tier: tier,
                        isDisabled: widget.isDisabled,
                        isHovered: _isGaugeHovered,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            subLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mainReadout,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: size < 210 ? 26 : 30,
                              fontWeight: FontWeight.w800,
                              color: _displayMode ==
                                      AeroGaugeDisplayMode.powerRetention
                                  ? tier.color
                                  : AppColors.cyanAccent,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${data.aeroTtPowerWatts.round()} W / ${data.roadFtpWatts.round()} W',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFeatures: <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          Text(
                            '$deltaSign${deltaW.round()} W',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: deltaW >= 0
                                  ? AppColors.statusSuccess
                                  : AppColors.amberWarning,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsPanel(
    AeroVsRoadComparisonData data,
    AeroPowerEfficiencyTier tier,
    bool useCompactLayout,
  ) {
    final double wPerCdaRoad =
        AeroVsRoadEfficiencyCalculator.wattsPerCdaRoad(data);
    final double wPerCdaAero =
        AeroVsRoadEfficiencyCalculator.wattsPerCdaAero(data);
    final double cdaReductionPct =
        AeroVsRoadEfficiencyCalculator.cdaReductionPercent(data);
    final double netGainPct =
        AeroVsRoadEfficiencyCalculator.netAeroEfficiencyGainPercent(data);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildModeToggleRow(),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _MetricTile(
              label: 'W/CdA (Szosa → TT)',
              value: '${wPerCdaRoad.round()} → ${wPerCdaAero.round()} W/m²',
              accent: AppColors.cyanAccent,
              badge: '${netGainPct >= 0 ? '+' : ''}${netGainPct.toStringAsFixed(1)}%',
            ),
            _MetricTile(
              label: 'Redukcja CdA',
              value: '${data.roadCda.toStringAsFixed(3)} → ${data.aeroCda.toStringAsFixed(3)}',
              accent: AppColors.accentBlue,
              badge: '-${cdaReductionPct.toStringAsFixed(1)}%',
            ),
            _MetricTile(
              label: 'Okluzja / Oddech',
              value:
                  '-${data.hipOcclusionPenaltyPct.toStringAsFixed(1)}% / -${data.respiratoryCostPenaltyPct.toStringAsFixed(1)}%',
              accent: AppColors.amberWarning,
              badge: 'Adapt. ${data.adaptationScore.round()}%',
            ),
            _MetricTile(
              label: 'Tempo ITT 40 km',
              value: '${data.targetSpeedKmh.toStringAsFixed(1)} km/h',
              accent: AppColors.goldAccent,
              badge: '-${data.estimatedTimeGain40KmSeconds.round()} s',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeToggleRow() {
    return Row(
      children: AeroGaugeDisplayMode.values.map((AeroGaugeDisplayMode mode) {
        final bool selected = _displayMode == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode == AeroGaugeDisplayMode.powerRetention ? 6 : 0,
            ),
            child: _InteractivePillButton(
              label: mode.labelPl,
              selected: selected,
              disabled: widget.isDisabled,
              accentColor: mode == AeroGaugeDisplayMode.powerRetention
                  ? AppColors.goldAccent
                  : AppColors.cyanAccent,
              onPressed: () => _handleModeToggle(mode),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPostureSelector(AeroTuckPosturePreset activePreset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'POZYCJA AERODYNAMICZNA',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AeroTuckPosturePreset.values
              .map((AeroTuckPosturePreset preset) {
            final bool selected = preset == activePreset;
            return _InteractivePillButton(
              label: preset.labelPl,
              selected: selected,
              disabled: widget.isDisabled,
              accentColor: AppColors.primaryAccent,
              onPressed: () => _handlePostureTap(preset),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOptimizeAction() {
    return _InteractiveActionButton(
      label: 'Optymalizuj pozycję TT w tunelu',
      icon: Icons.tune_rounded,
      disabled: widget.isDisabled,
      onPressed: widget.onOptimizePressed!,
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final Color accent;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.badge,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 155, maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2F3D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  badge,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractivePillButton({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? widget.accentColor
            : (_hovered
                ? widget.accentColor.withValues(alpha: 0.55)
                : const Color(0xFF2A2F3D)));

    final Color bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
        : (_hovered
            ? AppColors.surfaceLight.withValues(alpha: 0.95)
            : AppColors.background);

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (bool f) {
        if (_focused != f) setState(() => _focused = f);
      },
      onShowHoverHighlight: (bool h) {
        if (_hovered != h) setState(() => _hovered = h);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.disabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown:
            widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp:
            widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel:
            widget.disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.disabled
                    ? AppColors.textSecondary
                    : (widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool disabled;
  final VoidCallback onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.disabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.disabled
        ? AppColors.surfaceLight
        : (_pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.95)
                : AppColors.primaryAccent));

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (bool f) {
        if (_focused != f) setState(() => _focused = f);
      },
      onShowHoverHighlight: (bool h) {
        if (_hovered != h) setState(() => _hovered = h);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.disabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown:
            widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp:
            widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel:
            widget.disabled ? null : () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onPressed,
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : const Color(0xFF2A2F3D),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.disabled
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.disabled
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
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
