import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Nawierzchnia zakrętu determinująca maksymalne bezpieczne przeciążenie boczne
/// i kąt przechyłu roweru w pochyleniu.
enum CornerSurfaceGripCondition {
  dryTarmac(
    labelPl: 'Suchy asfalt',
    labelEn: 'Dry Tarmac',
    shortCode: 'DRY',
    maxSafeLateralG: 1.15,
    maxSafeLeanDegrees: 49.0,
    frictionMu: 1.18,
  ),
  dampTarmac(
    labelPl: 'Mokry asfalt',
    labelEn: 'Wet Tarmac',
    shortCode: 'WET',
    maxSafeLateralG: 0.78,
    maxSafeLeanDegrees: 38.0,
    frictionMu: 0.80,
  ),
  wetCobbles(
    labelPl: 'Śliski bruk',
    labelEn: 'Wet Cobbles',
    shortCode: 'COB',
    maxSafeLateralG: 0.56,
    maxSafeLeanDegrees: 29.0,
    frictionMu: 0.58,
  ),
  gravelLoose(
    labelPl: 'Luźny szuter',
    labelEn: 'Loose Gravel',
    shortCode: 'GRV',
    maxSafeLateralG: 0.64,
    maxSafeLeanDegrees: 33.0,
    frictionMu: 0.66,
  );

  final String labelPl;
  final String labelEn;
  final String shortCode;
  final double maxSafeLateralG;
  final double maxSafeLeanDegrees;
  final double frictionMu;

  const CornerSurfaceGripCondition({
    required this.labelPl,
    required this.labelEn,
    required this.shortCode,
    required this.maxSafeLateralG,
    required this.maxSafeLeanDegrees,
    required this.frictionMu,
  });

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelPl;
}

/// Źródło kamery 3D, z którego pochodzi telemetria zakrętu.
enum CornerTelemetryCameraSource {
  onBoardActionCam(
    labelPl: 'Kamera z kierownicy',
    labelEn: 'OnBoard Action Cam',
    badgeCode: 'ONBOARD CAM',
  ),
  firstPersonCockpit(
    labelPl: 'Kokpit 1. osoby',
    labelEn: 'First-Person Cockpit',
    badgeCode: 'COCKPIT 3D',
  );

  final String labelPl;
  final String labelEn;
  final String badgeCode;

  const CornerTelemetryCameraSource({
    required this.labelPl,
    required this.labelEn,
    required this.badgeCode,
  });

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelPl;
}

/// Poziom obciążenia przyczepności opony w zakręcie.
enum CornerGripRiskTier {
  nominal(
    labelPl: 'Stabilny tor',
    labelEn: 'Nominal Grip',
    color: AppColors.statusSuccess,
  ),
  pushing(
    labelPl: 'Agresywny łuk',
    labelEn: 'Pushing Apex',
    color: AppColors.accentBlue,
  ),
  limit(
    labelPl: 'Granica opony',
    labelEn: 'Tire Limit',
    color: AppColors.amberWarning,
  ),
  slideAlert(
    labelPl: 'Ryzyko uślizgu!',
    labelEn: 'Low-Side Risk!',
    color: AppColors.crimsonAlert,
  );

  final String labelPl;
  final String labelEn;
  final Color color;

  const CornerGripRiskTier({
    required this.labelPl,
    required this.labelEn,
    required this.color,
  });

  String label(String languageCode) => languageCode == 'en' ? labelEn : labelPl;
}

/// Model danych telemetrycznych przeciążenia bocznego (G) i kąta przechyłu w zakręcie.
@immutable
class CornerGForceAndLeanTelemetryData {
  /// Przeciążenie boczne w osi poprzecznej `[G]` (`< 0` lewo, `> 0` prawo).
  final double lateralGForce;

  /// Przeciążenie wzdłużne `[G]` (`< 0` hamowanie przed zakrętem, `> 0` przyspieszenie).
  final double longitudinalGForce;

  /// Kąt przechyłu roweru w zakręcie `[°]` (`< 0` w lewo, `> 0` w prawo).
  final double leanAngleDegrees;

  /// Aktualna prędkość w zakręcie `[km/h]`.
  final double speedKmh;

  /// Szacowany promień łuku zakrętu `[m]`.
  final double cornerRadiusMeters;

  /// Szczytowe odnotowane przeciążenie boczne `|G|` w sesji.
  final double peakLateralG;

  /// Szczytowy odnotowany kąt przechyłu `|°|` w sesji.
  final double peakLeanDegrees;

  /// Stan nawierzchni i przyczepności zakrętu.
  final CornerSurfaceGripCondition surfaceGrip;

  /// Aktywny tryb kamery (OnBoard Action Cam / First-Person Cockpit).
  final CornerTelemetryCameraSource cameraSource;

  /// Czy wskaźnik HUD jest aktywny (odblokowany).
  final bool isEnabled;

  const CornerGForceAndLeanTelemetryData({
    required this.lateralGForce,
    this.longitudinalGForce = 0.0,
    required this.leanAngleDegrees,
    required this.speedKmh,
    this.cornerRadiusMeters = 45.0,
    double? peakLateralG,
    double? peakLeanDegrees,
    this.surfaceGrip = CornerSurfaceGripCondition.dryTarmac,
    this.cameraSource = CornerTelemetryCameraSource.onBoardActionCam,
    this.isEnabled = true,
  })  : peakLateralG = peakLateralG ??
            (lateralGForce < 0 ? -lateralGForce : lateralGForce),
        peakLeanDegrees = peakLeanDegrees ??
            (leanAngleDegrees < 0 ? -leanAngleDegrees : leanAngleDegrees);

  /// Całkowity wektor przeciążenia w płaszczyźnie opony `sqrt(Gx^2 + Gy^2)`.
  double get combinedGForce =>
      math.sqrt(lateralGForce * lateralGForce +
          longitudinalGForce * longitudinalGForce);

  /// Stopień wykorzystania dostępnej przyczepności (`0.0` – `1.35`).
  double get gripUtilizationRatio =>
      (lateralGForce.abs() / surfaceGrip.maxSafeLateralG).clamp(0.0, 1.35);

  /// Aktualny poziom ryzyka uślizgu przedniego lub tylnego koła.
  CornerGripRiskTier get riskTier => CornerGForcePhysicsCalculator.evaluateGripRisk(
        lateralG: lateralGForce,
        surface: surfaceGrip,
      );

  CornerGForceAndLeanTelemetryData copyWith({
    double? lateralGForce,
    double? longitudinalGForce,
    double? leanAngleDegrees,
    double? speedKmh,
    double? cornerRadiusMeters,
    double? peakLateralG,
    double? peakLeanDegrees,
    CornerSurfaceGripCondition? surfaceGrip,
    CornerTelemetryCameraSource? cameraSource,
    bool? isEnabled,
  }) {
    return CornerGForceAndLeanTelemetryData(
      lateralGForce: lateralGForce ?? this.lateralGForce,
      longitudinalGForce: longitudinalGForce ?? this.longitudinalGForce,
      leanAngleDegrees: leanAngleDegrees ?? this.leanAngleDegrees,
      speedKmh: speedKmh ?? this.speedKmh,
      cornerRadiusMeters: cornerRadiusMeters ?? this.cornerRadiusMeters,
      peakLateralG: peakLateralG ?? this.peakLateralG,
      peakLeanDegrees: peakLeanDegrees ?? this.peakLeanDegrees,
      surfaceGrip: surfaceGrip ?? this.surfaceGrip,
      cameraSource: cameraSource ?? this.cameraSource,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'lateralGForce': lateralGForce,
      'longitudinalGForce': longitudinalGForce,
      'leanAngleDegrees': leanAngleDegrees,
      'speedKmh': speedKmh,
      'cornerRadiusMeters': cornerRadiusMeters,
      'peakLateralG': peakLateralG,
      'peakLeanDegrees': peakLeanDegrees,
      'surfaceGrip': surfaceGrip.name,
      'cameraSource': cameraSource.name,
      'isEnabled': isEnabled,
    };
  }

  factory CornerGForceAndLeanTelemetryData.fromJson(Map<String, dynamic> json) {
    final String surfaceName = json['surfaceGrip'] as String? ?? 'dryTarmac';
    final String sourceName =
        json['cameraSource'] as String? ?? 'onBoardActionCam';

    final CornerSurfaceGripCondition surface =
        CornerSurfaceGripCondition.values.firstWhere(
      (CornerSurfaceGripCondition item) => item.name == surfaceName,
      orElse: () => CornerSurfaceGripCondition.dryTarmac,
    );
    final CornerTelemetryCameraSource source =
        CornerTelemetryCameraSource.values.firstWhere(
      (CornerTelemetryCameraSource item) => item.name == sourceName,
      orElse: () => CornerTelemetryCameraSource.onBoardActionCam,
    );

    return CornerGForceAndLeanTelemetryData(
      lateralGForce: (json['lateralGForce'] as num?)?.toDouble() ?? 0.0,
      longitudinalGForce:
          (json['longitudinalGForce'] as num?)?.toDouble() ?? 0.0,
      leanAngleDegrees: (json['leanAngleDegrees'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 0.0,
      cornerRadiusMeters:
          (json['cornerRadiusMeters'] as num?)?.toDouble() ?? 45.0,
      peakLateralG: (json['peakLateralG'] as num?)?.toDouble(),
      peakLeanDegrees: (json['peakLeanDegrees'] as num?)?.toDouble(),
      surfaceGrip: surface,
      cameraSource: source,
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CornerGForceAndLeanTelemetryData &&
        other.lateralGForce == lateralGForce &&
        other.longitudinalGForce == longitudinalGForce &&
        other.leanAngleDegrees == leanAngleDegrees &&
        other.speedKmh == speedKmh &&
        other.cornerRadiusMeters == cornerRadiusMeters &&
        other.peakLateralG == peakLateralG &&
        other.peakLeanDegrees == peakLeanDegrees &&
        other.surfaceGrip == surfaceGrip &&
        other.cameraSource == cameraSource &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode => Object.hash(
        lateralGForce,
        longitudinalGForce,
        leanAngleDegrees,
        speedKmh,
        cornerRadiusMeters,
        peakLateralG,
        peakLeanDegrees,
        surfaceGrip,
        cameraSource,
        isEnabled,
      );
}

/// Deterministyczny kalkulator fizyki przeciążeń bocznych i kąta przechyłu w zakręcie.
class CornerGForcePhysicsCalculator {
  const CornerGForcePhysicsCalculator._();

  static const double standardGravityMs2 = 9.80665;

  /// Wylicza przeciążenie odśrodkowe w zakręcie `G = v^2 / (R * g)`.
  static double computeLateralG({
    required double speedMs,
    required double cornerRadiusMeters,
    bool turnRight = true,
  }) {
    if (speedMs <= 0.0 || cornerRadiusMeters <= 0.5) return 0.0;
    final double magnitude =
        (speedMs * speedMs) / (cornerRadiusMeters * standardGravityMs2);
    final double clamped = magnitude.clamp(0.0, 1.65);
    return turnRight ? clamped : -clamped;
  }

  /// Wylicza idealny kąt przechyłu równowagi `theta = atan(|G_lat|)` w stopniach.
  static double computeLeanAngleDegrees({required double lateralG}) {
    final double radians = math.atan(lateralG.abs());
    final double deg = (radians * 180.0 / math.pi).clamp(0.0, 58.0);
    return lateralG < 0 ? -deg : deg;
  }

  /// Wylicza promień zakrętu `[m]` z prędkości i przeciążenia bocznego.
  static double estimateCornerRadiusMeters({
    required double speedMs,
    required double lateralG,
  }) {
    final double absG = lateralG.abs();
    if (speedMs <= 0.5 || absG < 0.04) return 250.0;
    return ((speedMs * speedMs) / (absG * standardGravityMs2))
        .clamp(8.0, 350.0);
  }

  /// Ocenia ryzyko uślizgu na podstawie stosunku `|G_lat| / maxSafeLateralG`.
  static CornerGripRiskTier evaluateGripRisk({
    required double lateralG,
    required CornerSurfaceGripCondition surface,
  }) {
    final double ratio = lateralG.abs() / surface.maxSafeLateralG;
    if (ratio >= 0.98) return CornerGripRiskTier.slideAlert;
    if (ratio >= 0.80) return CornerGripRiskTier.limit;
    if (ratio >= 0.52) return CornerGripRiskTier.pushing;
    return CornerGripRiskTier.nominal;
  }

  /// Buduje obiekt telemetrii na podstawie ruchu kamery 3D (pochylenie horyzontu / przechył).
  static CornerGForceAndLeanTelemetryData fromCameraMotion({
    required double speedKmh,
    required double leanAngleRadians,
    required CornerTelemetryCameraSource source,
    CornerSurfaceGripCondition surface = CornerSurfaceGripCondition.dryTarmac,
    double longitudinalG = 0.0,
    double? previousPeakG,
    double? previousPeakLeanDeg,
    bool isEnabled = true,
  }) {
    final double clampedRad = leanAngleRadians.clamp(-0.96, 0.96);
    final double leanDeg = (clampedRad * 180.0 / math.pi).clamp(-55.0, 55.0);
    final double lateralG = math.tan(clampedRad).clamp(-1.55, 1.55);
    final double speedMs = (speedKmh / 3.6).clamp(0.0, 40.0);
    final double radiusMeters = estimateCornerRadiusMeters(
      speedMs: speedMs,
      lateralG: lateralG,
    );

    final double absG = lateralG.abs();
    final double absDeg = leanDeg.abs();

    return CornerGForceAndLeanTelemetryData(
      lateralGForce: lateralG,
      longitudinalGForce: longitudinalG.clamp(-1.4, 1.0),
      leanAngleDegrees: leanDeg,
      speedKmh: speedKmh,
      cornerRadiusMeters: radiusMeters,
      peakLateralG: math.max(previousPeakG ?? 0.0, absG),
      peakLeanDegrees: math.max(previousPeakLeanDeg ?? 0.0, absDeg),
      surfaceGrip: surface,
      cameraSource: source,
      isEnabled: isEnabled,
    );
  }
}

/// Opcjonalny, produkcyjny wskaźnik przeciążenia bocznego (G) i kąta przechyłu w zakręcie
/// przeznaczony dla trybów `OnBoard Action Cam` oraz `First-Person Cockpit`.
class CornerGForceAndLeanAngleTelemetryHud extends StatefulWidget {
  final CornerGForceAndLeanTelemetryData data;

  /// Czy wskaźnik ma być renderowany (opcjonalne przełączanie widoczności w kamerze).
  final bool isVisible;

  /// Czy używać kompaktowego układu (np. bezpośrednio na podglądzie kamery 3D).
  final bool compactOverlay;

  /// Stan rozwinięcia karty (mini pigułka vs pełny wskaźnik z kołem tarcia i przechyłem).
  final bool isExpanded;

  /// Callback zmiany stanu rozwinięcia.
  final ValueChanged<bool>? onExpandedChanged;

  /// Callback zerowania szczytowych wartości sesji (`PEAK G` / `PEAK °`).
  final VoidCallback? onResetPeaks;

  /// Callback zmiany nawierzchni zakrętu (lub przełączenia w cyklu).
  final ValueChanged<CornerSurfaceGripCondition>? onSurfaceChanged;

  /// Callback ukrycia opcjonalnego HUD-a z poziomu przycisku zamknięcia.
  final VoidCallback? onToggleVisibility;

  /// Kod języka (`'pl'` lub `'en'`).
  final String languageCode;

  const CornerGForceAndLeanAngleTelemetryHud({
    super.key,
    required this.data,
    this.isVisible = true,
    this.compactOverlay = false,
    this.isExpanded = true,
    this.onExpandedChanged,
    this.onResetPeaks,
    this.onSurfaceChanged,
    this.onToggleVisibility,
    this.languageCode = 'pl',
  });

  @override
  State<CornerGForceAndLeanAngleTelemetryHud> createState() =>
      _CornerGForceAndLeanAngleTelemetryHudState();
}

class _CornerGForceAndLeanAngleTelemetryHudState
    extends State<CornerGForceAndLeanAngleTelemetryHud>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late double _animatedLatG;
  late double _animatedLongG;
  late double _animatedLeanDeg;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animatedLatG = widget.data.lateralGForce;
    _animatedLongG = widget.data.longitudinalGForce;
    _animatedLeanDeg = widget.data.leanAngleDegrees;
  }

  @override
  void didUpdateWidget(covariant CornerGForceAndLeanAngleTelemetryHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      _isExpanded = widget.isExpanded;
    }
    _animatedLatG = widget.data.lateralGForce;
    _animatedLongG = widget.data.longitudinalGForce;
    _animatedLeanDeg = widget.data.leanAngleDegrees;
  }

  void _toggleExpanded() {
    if (!widget.data.isEnabled) return;
    final bool next = !_isExpanded;
    setState(() {
      _isExpanded = next;
    });
    widget.onExpandedChanged?.call(next);
  }

  void _cycleSurface() {
    if (!widget.data.isEnabled || widget.onSurfaceChanged == null) return;
    const List<CornerSurfaceGripCondition> values =
        CornerSurfaceGripCondition.values;
    final int nextIndex =
        (values.indexOf(widget.data.surfaceGrip) + 1) % values.length;
    widget.onSurfaceChanged!(values[nextIndex]);
  }

  String _formatSignedG(double value) {
    final String dir = value.abs() < 0.03
        ? ''
        : (value < 0 ? ' L' : ' R');
    return '${value.abs().toStringAsFixed(2)} G$dir';
  }

  String _formatLeanDegrees(double degrees) {
    final String dir = degrees.abs() < 0.5
        ? ''
        : (degrees < 0 ? ' L' : ' R');
    return '${degrees.abs().toStringAsFixed(1)}°$dir';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final CornerGForceAndLeanTelemetryData data = widget.data;
    final CornerGripRiskTier risk = data.riskTier;
    final bool enabled = data.isEnabled;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      opacity: enabled ? 1.0 : 0.52,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double maxWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 640.0;
          final bool isTight = widget.compactOverlay || maxWidth < 360.0;
          final bool isWide = !widget.compactOverlay && maxWidth >= 560.0;

          if (!_isExpanded) {
            return _buildCollapsedPill(data: data, risk: risk, enabled: enabled);
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: risk == CornerGripRiskTier.slideAlert && enabled
                    ? AppColors.crimsonAlert.withValues(alpha: 0.85)
                    : AppColors.cardBorder,
                width: 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.all(isTight ? 10.0 : 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeaderRow(
                  data: data,
                  risk: risk,
                  enabled: enabled,
                  isTight: isTight,
                ),
                SizedBox(height: isTight ? 8.0 : 12.0),
                if (isWide)
                  _buildWideBody(data: data, risk: risk, enabled: enabled)
                else
                  _buildCompactBody(
                    data: data,
                    risk: risk,
                    enabled: enabled,
                    isTight: isTight,
                  ),
                SizedBox(height: isTight ? 8.0 : 10.0),
                _buildGripUtilizationFooter(
                  data: data,
                  risk: risk,
                  enabled: enabled,
                  isTight: isTight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedPill({
    required CornerGForceAndLeanTelemetryData data,
    required CornerGripRiskTier risk,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Icon(
            Icons.tire_repair_rounded,
            size: 15,
            color: enabled ? risk.color : AppColors.textSecondary,
          ),
          Text(
            'LAT ${_formatSignedG(data.lateralGForce)} • ${_formatLeanDegrees(data.leanAngleDegrees)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
              fontFeatures: <ui.FontFeature>[ui.FontFeature.tabularFigures()],
            ),
          ),
          _HudActionIconButton(
            tooltip: widget.languageCode == 'en'
                ? 'Expand G-Force HUD'
                : 'Rozwiń telemetrię zakrętu',
            icon: Icons.open_in_full_rounded,
            enabled: enabled,
            onPressed: _toggleExpanded,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow({
    required CornerGForceAndLeanTelemetryData data,
    required CornerGripRiskTier risk,
    required bool enabled,
    required bool isTight,
  }) {
    final String title = widget.languageCode == 'en'
        ? (isTight ? 'CORNER G & LEAN' : 'CORNER G-FORCE & LEAN ANGLE')
        : (isTight ? 'ZAKRĘT G / PRZECHYŁ' : 'PRZECIĄŻENIE I PRZECHYŁ W ZAKRĘCIE');

    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? risk.color : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isTight ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (!isTight) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: Text(
              data.cameraSource.badgeCode,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.goldAccent,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (widget.onResetPeaks != null)
          _HudActionIconButton(
            tooltip: widget.languageCode == 'en'
                ? 'Reset peak telemetry'
                : 'Resetuj szczytowe G/°',
            icon: Icons.restart_alt_rounded,
            enabled: enabled,
            onPressed: widget.onResetPeaks,
          ),
        _HudActionIconButton(
          tooltip: widget.languageCode == 'en'
              ? 'Collapse HUD'
              : 'Zwiń wskaźnik',
          icon: Icons.close_fullscreen_rounded,
          enabled: enabled,
          onPressed: _toggleExpanded,
        ),
        if (widget.onToggleVisibility != null) ...<Widget>[
          const SizedBox(width: 4),
          _HudActionIconButton(
            tooltip: widget.languageCode == 'en'
                ? 'Hide G-Force HUD'
                : 'Ukryj wskaźnik zakrętu',
            icon: Icons.visibility_off_rounded,
            enabled: enabled,
            onPressed: widget.onToggleVisibility,
          ),
        ],
      ],
    );
  }

  Widget _buildWideBody({
    required CornerGForceAndLeanTelemetryData data,
    required CornerGripRiskTier risk,
    required bool enabled,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 248,
          height: 122,
          child: _buildDualGaugeCanvas(
            data: data,
            risk: risk,
            enabled: enabled,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricsGrid(
            data: data,
            risk: risk,
            enabled: enabled,
            isTight: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBody({
    required CornerGForceAndLeanTelemetryData data,
    required CornerGripRiskTier risk,
    required bool enabled,
    required bool isTight,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: isTight ? 96 : 114,
          child: _buildDualGaugeCanvas(
            data: data,
            risk: risk,
            enabled: enabled,
          ),
        ),
        SizedBox(height: isTight ? 8 : 10),
        _buildMetricsGrid(
          data: data,
          risk: risk,
          enabled: enabled,
          isTight: isTight,
        ),
      ],
    );
  }

  Widget _buildDualGaugeCanvas({
    required CornerGForceAndLeanTelemetryData data,
    required CornerGripRiskTier risk,
    required bool enabled,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _animatedLatG),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double smoothLatG, Widget? child) {
        return CustomPaint(
          painter: CornerGForceAndLeanAnglePainter(
            lateralGForce: smoothLatG,
            longitudinalGForce: _animatedLongG,
            leanAngleDegrees: _animatedLeanDeg,
            maxSafeLateralG: data.surfaceGrip.maxSafeLateralG,
            maxSafeLeanDegrees: data.surfaceGrip.maxSafeLeanDegrees,
            peakLateralG: data.peakLateralG,
            riskColor: enabled ? risk.color : AppColors.textSecondary,
            isEnabled: enabled,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMetricsGrid({
    required CornerGForceAndLeanTelemetryData data,
    required CornerGripRiskTier risk,
    required bool enabled,
    required bool isTight,
  }) {
    final String latLabel =
        widget.languageCode == 'en' ? 'LATERAL G' : 'PRZECIĄŻENIE';
    final String leanLabel =
        widget.languageCode == 'en' ? 'LEAN ANGLE' : 'KĄT PRZECHYŁU';
    final String peakLabel =
        widget.languageCode == 'en' ? 'PEAK G / LEAN' : 'SZCZYT G / KĄT';
    final String radiusLabel =
        widget.languageCode == 'en' ? 'APEX RADIUS' : 'ŁUK / PRĘDKOŚĆ';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _TelemetryMetricTile(
          label: latLabel,
          value: _formatSignedG(data.lateralGForce),
          accentColor: enabled ? risk.color : AppColors.textSecondary,
          isTight: isTight,
        ),
        _TelemetryMetricTile(
          label: leanLabel,
          value: _formatLeanDegrees(data.leanAngleDegrees),
          accentColor: enabled ? AppColors.cyanAccent : AppColors.textSecondary,
          isTight: isTight,
        ),
        _TelemetryMetricTile(
          label: peakLabel,
          value:
              '${data.peakLateralG.toStringAsFixed(2)}G • ${data.peakLeanDegrees.toStringAsFixed(0)}°',
          accentColor: enabled ? AppColors.goldAccent : AppColors.textSecondary,
          isTight: isTight,
        ),
        _TelemetryMetricTile(
          label: radiusLabel,
          value:
              'R${data.cornerRadiusMeters.round()}m • ${data.speedKmh.toStringAsFixed(0)} km/h',
          accentColor: enabled ? AppColors.accentBlue : AppColors.textSecondary,
          isTight: isTight,
        ),
      ],
    );
  }

  Widget _buildGripUtilizationFooter({
    required CornerGForceAndLeanTelemetryData data,
    required CornerGripRiskTier risk,
    required bool enabled,
    required bool isTight,
  }) {
    final int gripPct = (data.gripUtilizationRatio * 100).round().clamp(0, 130);
    final double barFactor = (data.gripUtilizationRatio).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${risk.label(widget.languageCode)} ($gripPct%)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isTight ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  color: enabled ? risk.color : AppColors.textSecondary,
                  fontFeatures: const <ui.FontFeature>[
                    ui.FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SurfaceSelectorPill(
              label: data.surfaceGrip.label(widget.languageCode),
              enabled: enabled && widget.onSurfaceChanged != null,
              onTap: _cycleSurface,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 5,
            color: AppColors.surfaceLight,
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              widthFactor: barFactor,
              child: Container(
                decoration: BoxDecoration(
                  color: enabled ? risk.color : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rysuje dwuelementowy wskaźnik telemetryczny:
/// 1) Po lewej: koło tarcia 2D (G-G Friction Circle) z wektorem przeciążeń.
/// 2) Po prawej: inklinometr kąta przechyłu roweru z linią horyzontu i granicą przyczepności.
class CornerGForceAndLeanAnglePainter extends CustomPainter {
  final double lateralGForce;
  final double longitudinalGForce;
  final double leanAngleDegrees;
  final double maxSafeLateralG;
  final double maxSafeLeanDegrees;
  final double peakLateralG;
  final Color riskColor;
  final bool isEnabled;

  const CornerGForceAndLeanAnglePainter({
    required this.lateralGForce,
    required this.longitudinalGForce,
    required this.leanAngleDegrees,
    required this.maxSafeLateralG,
    required this.maxSafeLeanDegrees,
    required this.peakLateralG,
    required this.riskColor,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double halfWidth = size.width * 0.5;
    final Rect leftRect = Rect.fromLTWH(0, 0, halfWidth - 4, size.height);
    final Rect rightRect =
        Rect.fromLTWH(halfWidth + 4, 0, halfWidth - 4, size.height);

    _paintFrictionCircle(canvas, leftRect);
    _paintLeanInclinometer(canvas, rightRect);
  }

  void _paintFrictionCircle(Canvas canvas, Rect rect) {
    final Offset center = rect.center;
    final double radius = math.max(16.0, math.min(rect.width, rect.height) * 0.44);
    const double maxScaleG = 1.5;

    final Paint bgPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final Paint ringPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final double gRing in <double>[0.5, 1.0, 1.5]) {
      canvas.drawCircle(center, radius * (gRing / maxScaleG), ringPaint);
    }

    // Pierścień limitu przyczepności opony dla aktualnej nawierzchni.
    final double safeRatio = (maxSafeLateralG / maxScaleG).clamp(0.15, 1.0);
    final Paint safeLimitPaint = Paint()
      ..color = AppColors.amberWarning.withValues(alpha: isEnabled ? 0.55 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius * safeRatio, safeLimitPaint);

    // Osie X (boczne G) i Y (hamowanie / przyspieszenie).
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ringPaint,
    );

    // Wektor przeciążenia G-G.
    final double normX = (lateralGForce / maxScaleG).clamp(-1.0, 1.0);
    final double normY = (-longitudinalGForce / maxScaleG).clamp(-1.0, 1.0);
    final Offset dotPos = Offset(
      center.dx + normX * radius,
      center.dy + normY * radius,
    );

    final Paint vectorPaint = Paint()
      ..color = riskColor.withValues(alpha: isEnabled ? 0.75 : 0.35)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, dotPos, vectorPaint);

    final Paint glowPaint = Paint()
      ..color = riskColor.withValues(alpha: isEnabled ? 0.28 : 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotPos, 9.0, glowPaint);

    final Paint dotPaint = Paint()
      ..color = isEnabled ? riskColor : AppColors.textSecondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotPos, 4.5, dotPaint);
  }

  void _paintLeanInclinometer(Canvas canvas, Rect rect) {
    final Offset pivot = Offset(rect.center.dx, rect.bottom - 10);
    final double radius =
        math.max(20.0, math.min(rect.width * 0.45, rect.height - 16));

    // Tło łuku inklinometru (-55° do +55°).
    final Paint arcBgPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    final Rect arcRect = Rect.fromCircle(center: pivot, radius: radius);
    const double maxArcRad = 55.0 * math.pi / 180.0;
    canvas.drawArc(
      arcRect,
      -math.pi / 2 - maxArcRad,
      maxArcRad * 2,
      false,
      arcBgPaint,
    );

    // Bezpieczny zakres przechyłu na łuku.
    final double safeRad =
        (maxSafeLeanDegrees.clamp(10.0, 55.0)) * math.pi / 180.0;
    final Paint safeArcPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: isEnabled ? 0.55 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arcRect,
      -math.pi / 2 - safeRad,
      safeRad * 2,
      false,
      safeArcPaint,
    );

    // Podziałki co 15°.
    final Paint tickPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    for (final int deg in <int>[-45, -30, -15, 0, 15, 30, 45]) {
      final double angle = -math.pi / 2 + deg * math.pi / 180.0;
      final Offset p1 = Offset(
        pivot.dx + math.cos(angle) * (radius - 5),
        pivot.dy + math.sin(angle) * (radius - 5),
      );
      final Offset p2 = Offset(
        pivot.dx + math.cos(angle) * (radius + 3),
        pivot.dy + math.sin(angle) * (radius + 3),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Wskaźnik przechyłu sylwetki roweru (igła + kierownica).
    final double leanRad =
        (leanAngleDegrees.clamp(-55.0, 55.0)) * math.pi / 180.0;
    final double needleAngle = -math.pi / 2 + leanRad;
    final Offset tip = Offset(
      pivot.dx + math.cos(needleAngle) * (radius - 4),
      pivot.dy + math.sin(needleAngle) * (radius - 4),
    );

    final Paint needlePaint = Paint()
      ..color = isEnabled ? riskColor : AppColors.textSecondary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, tip, needlePaint);

    // Poprzeczka symbolizująca kierownicę przechyloną pod tym samym kątem.
    final double barAngle = needleAngle + math.pi / 2;
    final Offset barCenter = Offset(
      pivot.dx + math.cos(needleAngle) * (radius * 0.58),
      pivot.dy + math.sin(needleAngle) * (radius * 0.58),
    );
    const double halfBarWidth = 11.0;
    canvas.drawLine(
      Offset(
        barCenter.dx - math.cos(barAngle) * halfBarWidth,
        barCenter.dy - math.sin(barAngle) * halfBarWidth,
      ),
      Offset(
        barCenter.dx + math.cos(barAngle) * halfBarWidth,
        barCenter.dy + math.sin(barAngle) * halfBarWidth,
      ),
      Paint()
        ..color = isEnabled ? AppColors.textPrimary : AppColors.textSecondary
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      pivot,
      3.5,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant CornerGForceAndLeanAnglePainter oldDelegate) {
    return oldDelegate.lateralGForce != lateralGForce ||
        oldDelegate.longitudinalGForce != longitudinalGForce ||
        oldDelegate.leanAngleDegrees != leanAngleDegrees ||
        oldDelegate.maxSafeLateralG != maxSafeLateralG ||
        oldDelegate.maxSafeLeanDegrees != maxSafeLeanDegrees ||
        oldDelegate.peakLateralG != peakLateralG ||
        oldDelegate.riskColor != riskColor ||
        oldDelegate.isEnabled != isEnabled;
  }
}

class _TelemetryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final bool isTight;

  const _TelemetryMetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.isTight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: isTight ? 118 : 132),
      padding: EdgeInsets.symmetric(
        horizontal: isTight ? 8 : 10,
        vertical: isTight ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isTight ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const <ui.FontFeature>[
                ui.FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceSelectorPill extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _SurfaceSelectorPill({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SurfaceSelectorPill> createState() => _SurfaceSelectorPillState();
}

class _SurfaceSelectorPillState extends State<_SurfaceSelectorPill> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppColors.cardBorder
        : _isFocused
            ? AppColors.cyanAccent
            : _isHovered || _isPressed
                ? AppColors.goldAccent
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool focused) =>
          setState(() => _isFocused = focused),
      onShowHoverHighlight: (bool hovered) =>
          setState(() => _isHovered = hovered),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _isPressed ? AppColors.surface : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.swap_horiz_rounded,
                size: 12,
                color: widget.enabled
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
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

class _HudActionIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HudActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_HudActionIconButton> createState() => _HudActionIconButtonState();
}

class _HudActionIconButtonState extends State<_HudActionIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled && widget.onPressed != null;
    final Color borderColor = !active
        ? AppColors.cardBorder
        : _isFocused
            ? AppColors.cyanAccent
            : _isHovered || _isPressed
                ? AppColors.goldAccent
                : AppColors.cardBorder;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: active,
        onShowFocusHighlight: (bool focused) =>
            setState(() => _isFocused = focused),
        onShowHoverHighlight: (bool hovered) =>
            setState(() => _isHovered = hovered),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (active) widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: active ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: active ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: active ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _isPressed ? AppColors.surface : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Icon(
              widget.icon,
              size: 13,
              color: active ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
