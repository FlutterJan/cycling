import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/rendering3d/broadcast_tv_graphics_overlay.dart';
import '../../models/race/stage_segment.dart';

/// Pasmo trudności nachylenia podjazdu używane w telewizyjnym profilu 3D.
enum ClimbGradientDifficultyBand {
  /// Łagodny odcinek poniżej 4%.
  gentle,

  /// 4–6% (żółty).
  yellow,

  /// 7–9% (pomarańczowy).
  orange,

  /// 10–12% (czerwony).
  red,

  /// Powyżej 12% (czarny — ekstremalna stromizna).
  black;

  /// Wyznacza pasmo kolorystyczne na podstawie nachylenia w procentach.
  static ClimbGradientDifficultyBand fromGradient(double gradientPercent) {
    final double g = gradientPercent.isNaN || gradientPercent.isInfinite
        ? 0.0
        : gradientPercent;
    if (g > 12.0) return ClimbGradientDifficultyBand.black;
    if (g >= 10.0) return ClimbGradientDifficultyBand.red;
    if (g >= 7.0) return ClimbGradientDifficultyBand.orange;
    if (g >= 4.0) return ClimbGradientDifficultyBand.yellow;
    return ClimbGradientDifficultyBand.gentle;
  }

  /// Główny kolor frontowej ściany słupka 3D.
  Color get frontColor {
    switch (this) {
      case ClimbGradientDifficultyBand.gentle:
        return AppColors.powerZone3;
      case ClimbGradientDifficultyBand.yellow:
        return AppColors.powerZone4;
      case ClimbGradientDifficultyBand.orange:
        return AppColors.powerZone5;
      case ClimbGradientDifficultyBand.red:
        return AppColors.crimsonAlert;
      case ClimbGradientDifficultyBand.black:
        return const Color(0xFF0A0C10);
    }
  }

  /// Rozjaśniony kolor górnej powierzchni słupka 3D (efekt oświetlenia z góry).
  Color get topColor {
    switch (this) {
      case ClimbGradientDifficultyBand.gentle:
        return const Color(0xFF34D399);
      case ClimbGradientDifficultyBand.yellow:
        return const Color(0xFFFACC15);
      case ClimbGradientDifficultyBand.orange:
        return const Color(0xFFFB923C);
      case ClimbGradientDifficultyBand.red:
        return const Color(0xFFF87171);
      case ClimbGradientDifficultyBand.black:
        return const Color(0xFF1F242D);
    }
  }

  /// Przyciemniony kolor bocznej ściany głębi 3D.
  Color get sideColor {
    switch (this) {
      case ClimbGradientDifficultyBand.gentle:
        return const Color(0xFF059669);
      case ClimbGradientDifficultyBand.yellow:
        return const Color(0xFFCA8A04);
      case ClimbGradientDifficultyBand.orange:
        return const Color(0xFFC2410C);
      case ClimbGradientDifficultyBand.red:
        return const Color(0xFFB91C1C);
      case ClimbGradientDifficultyBand.black:
        return const Color(0xFF040507);
    }
  }

  /// Kolor obramowania słupka 3D (dla czarnego >12% wyrazisty srebrno-biały kontur).
  Color get edgeColor {
    switch (this) {
      case ClimbGradientDifficultyBand.black:
        return AppColors.textPrimary.withValues(alpha: 0.72);
      default:
        return Colors.white.withValues(alpha: 0.24);
    }
  }

  /// Kolor tekstu wartości % wewnątrz lub nad słupkiem.
  Color get badgeTextColor {
    switch (this) {
      case ClimbGradientDifficultyBand.yellow:
        return AppColors.background;
      case ClimbGradientDifficultyBand.gentle:
      case ClimbGradientDifficultyBand.orange:
      case ClimbGradientDifficultyBand.red:
      case ClimbGradientDifficultyBand.black:
        return AppColors.textPrimary;
    }
  }

  /// Etykieta zakresu nachylenia do legendy i podpowiedzi.
  String get rangeLabel {
    switch (this) {
      case ClimbGradientDifficultyBand.gentle:
        return '<4%';
      case ClimbGradientDifficultyBand.yellow:
        return '4–6%';
      case ClimbGradientDifficultyBand.orange:
        return '7–9%';
      case ClimbGradientDifficultyBand.red:
        return '10–12%';
      case ClimbGradientDifficultyBand.black:
        return '>12%';
    }
  }
}

/// Pojedynczy odcinek kilometrowy w profilu 3D podjazdu.
@immutable
class ClimbKilometerSegment {
  final int kilometerIndex;
  final double lengthKm;
  final double gradientPercent;
  final double? startElevationM;
  final double? endElevationM;

  const ClimbKilometerSegment({
    required this.kilometerIndex,
    this.lengthKm = 1.0,
    required this.gradientPercent,
    this.startElevationM,
    this.endElevationM,
  });

  ClimbGradientDifficultyBand get band =>
      ClimbGradientDifficultyBand.fromGradient(gradientPercent);

  double get elevationGainM {
    if (startElevationM != null && endElevationM != null) {
      return endElevationM! - startElevationM!;
    }
    return lengthKm * 1000.0 * (gradientPercent / 100.0);
  }
}

/// Model danych dla telewizyjnego HUD profilu podjazdu [TvClimbGradient3dRibbonHud].
@immutable
class TvClimbGradient3dRibbonData {
  final String climbName;
  final SegmentClassification category;
  final double totalLengthKm;
  final double remainingKm;
  final double averageGradientPercent;
  final double currentGradientPercent;
  final double summitElevationM;
  final double currentElevationM;
  final double leaderVamMetersPerHour;
  final String? leaderName;
  final List<ClimbKilometerSegment> kilometerSegments;

  const TvClimbGradient3dRibbonData({
    required this.climbName,
    required this.category,
    required this.totalLengthKm,
    required this.remainingKm,
    required this.averageGradientPercent,
    required this.currentGradientPercent,
    required this.summitElevationM,
    required this.currentElevationM,
    required this.leaderVamMetersPerHour,
    this.leaderName,
    required this.kilometerSegments,
  });

  /// Ułamek postępu podjazdu w zakresie `0.0`–`1.0`.
  double get progressFraction {
    if (totalLengthKm <= 0.0 ||
        totalLengthKm.isNaN ||
        remainingKm.isNaN) {
      return 0.0;
    }
    return ((totalLengthKm - remainingKm) / totalLengthKm).clamp(0.0, 1.0);
  }

  /// Aktualnie przejechany dystans na podjeździe w kilometrach.
  double get coveredKm {
    if (totalLengthKm <= 0.0) return 0.0;
    return (totalLengthKm - remainingKm).clamp(0.0, totalLengthKm);
  }

  /// Konwertuje [BroadcastClimbTelemetryData] na model z segmentami co 1 km.
  factory TvClimbGradient3dRibbonData.fromBroadcastTelemetry(
    BroadcastClimbTelemetryData telemetry, {
    String? leaderName,
  }) {
    final double totalKm = math.max(0.5, telemetry.totalLengthKm);
    final int fullKmCount = totalKm.ceil().clamp(1, 35);
    final List<ClimbKilometerSegment> segments = <ClimbKilometerSegment>[];
    final List<double> samples = telemetry.elevationProfileSamples;

    for (int i = 0; i < fullKmCount; i++) {
      final bool isLast = i == fullKmCount - 1;
      final double remainder = totalKm - i;
      final double segLen = isLast ? remainder.clamp(0.2, 1.0) : 1.0;

      double gradient = telemetry.averageGradientPercent;
      double? startElev;
      double? endElev;

      if (samples.length >= 2) {
        final double startFrac = i / fullKmCount;
        final double endFrac = (i + 1) / fullKmCount;
        final int idxA =
            (startFrac * (samples.length - 1)).round().clamp(0, samples.length - 1);
        final int idxB =
            (endFrac * (samples.length - 1)).round().clamp(0, samples.length - 1);
        startElev = samples[idxA];
        endElev = samples[idxB];
        final double deltaM = endElev - startElev;
        gradient = (deltaM / (segLen * 1000.0)) * 100.0;
      }

      segments.add(
        ClimbKilometerSegment(
          kilometerIndex: i + 1,
          lengthKm: segLen,
          gradientPercent: gradient.clamp(-5.0, 28.0),
          startElevationM: startElev,
          endElevationM: endElev,
        ),
      );
    }

    return TvClimbGradient3dRibbonData(
      climbName: telemetry.climbName,
      category: telemetry.category,
      totalLengthKm: telemetry.totalLengthKm,
      remainingKm: telemetry.remainingKm,
      averageGradientPercent: telemetry.averageGradientPercent,
      currentGradientPercent: telemetry.currentGradientPercent,
      summitElevationM: telemetry.summitElevationM,
      currentElevationM: telemetry.currentElevationM,
      leaderVamMetersPerHour: telemetry.leaderGroupVamMetersPerHour,
      leaderName: leaderName,
      kilometerSegments: segments,
    );
  }
}

/// Telewizyjny widget profilu aktualnego podjazdu w rogu ekranu podczas wspinaczki.
///
/// Renderuje trójwymiarową wstęgę słupków dla każdego kolejnego kilometra,
/// pokolorowaną zgodnie z nachyleniem (4–6% żółty, 7–9% pomarańczowy,
/// 10–12% czerwony, >12% czarny) wraz ze średnim VAM lidera wyścigu.
class TvClimbGradient3dRibbonHud extends StatefulWidget {
  final TvClimbGradient3dRibbonData data;
  final bool enabled;
  final bool initiallyExpanded;
  final ValueChanged<ClimbKilometerSegment?>? onSegmentSelected;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onFocusClimbCamera;

  const TvClimbGradient3dRibbonHud({
    super.key,
    required this.data,
    this.enabled = true,
    this.initiallyExpanded = true,
    this.onSegmentSelected,
    this.onToggleExpand,
    this.onFocusClimbCamera,
  });

  @override
  State<TvClimbGradient3dRibbonHud> createState() =>
      _TvClimbGradient3dRibbonHudState();
}

class _TvClimbGradient3dRibbonHudState
    extends State<TvClimbGradient3dRibbonHud>
    with SingleTickerProviderStateMixin {
  static const Duration _animDuration = Duration(milliseconds: 260);

  late bool _isExpanded;
  bool _isCardHovered = false;
  bool _isCardFocused = false;
  bool _isToggleHovered = false;
  bool _isTogglePressed = false;
  bool _isToggleFocused = false;
  bool _isCameraHovered = false;
  bool _isCameraPressed = false;
  bool _isCameraFocused = false;

  int? _hoveredSegmentIndex;
  int? _selectedSegmentIndex;
  int? _pressedSegmentIndex;

  late final AnimationController _pulseController;
  final ScrollController _ribbonScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ribbonScrollController.dispose();
    super.dispose();
  }

  void _handleToggleExpand() {
    if (!widget.enabled) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggleExpand?.call();
  }

  void _selectSegment(int? index) {
    if (!widget.enabled) return;
    setState(() {
      if (_selectedSegmentIndex == index) {
        _selectedSegmentIndex = null;
      } else {
        _selectedSegmentIndex = index;
      }
    });
    final List<ClimbKilometerSegment> segs = widget.data.kilometerSegments;
    if (_selectedSegmentIndex != null &&
        _selectedSegmentIndex! >= 0 &&
        _selectedSegmentIndex! < segs.length) {
      widget.onSegmentSelected?.call(segs[_selectedSegmentIndex!]);
    } else {
      widget.onSegmentSelected?.call(null);
    }
  }

  void _stepSelectedSegment(int delta) {
    if (!widget.enabled || widget.data.kilometerSegments.isEmpty) return;
    final int len = widget.data.kilometerSegments.length;
    final int current = _selectedSegmentIndex ?? 0;
    final int next = (current + delta).clamp(0, len - 1);
    setState(() {
      _selectedSegmentIndex = next;
    });
    widget.onSegmentSelected?.call(widget.data.kilometerSegments[next]);
  }

  String _categoryBadgeLabel(SegmentClassification cat) {
    switch (cat) {
      case SegmentClassification.horsCategorie:
        return 'HC';
      case SegmentClassification.cat1:
        return 'KAT. 1';
      case SegmentClassification.cat2:
        return 'KAT. 2';
      case SegmentClassification.cat3:
        return 'KAT. 3';
      case SegmentClassification.cat4:
        return 'KAT. 4';
      case SegmentClassification.intermediateSprint:
        return 'SPRINT';
      case SegmentClassification.finishLine:
        return 'META';
      case SegmentClassification.none:
        return 'PODJAZD';
    }
  }

  Color _categoryBadgeColor(SegmentClassification cat) {
    switch (cat) {
      case SegmentClassification.horsCategorie:
        return AppColors.crimsonAlert;
      case SegmentClassification.cat1:
        return AppColors.primaryAccent;
      case SegmentClassification.cat2:
        return AppColors.powerZone5;
      case SegmentClassification.cat3:
        return AppColors.goldAccent;
      case SegmentClassification.cat4:
        return AppColors.accentBlue;
      default:
        return AppColors.surfaceLight;
    }
  }

  TextStyle _interStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    bool tabular = false,
    double letterSpacing = -0.2,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontFeatures:
          tabular ? const <FontFeature>[FontFeature.tabularFigures()] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 400.0;
        final bool isCompactMobile = availableWidth < 380.0;
        final bool isTabletOrDesktop = availableWidth >= 420.0;

        final double cardWidth = isCompactMobile
            ? availableWidth
            : (isTabletOrDesktop ? math.min(availableWidth, 430.0) : availableWidth);

        final Color borderColor = !widget.enabled
            ? AppColors.cardBorder.withValues(alpha: 0.45)
            : (_isCardFocused
                ? AppColors.goldAccent
                : (_isCardHovered
                    ? AppColors.goldAccent.withValues(alpha: 0.55)
                    : const Color(0xFF2A2F3D)));

        final List<ClimbKilometerSegment> segments =
            widget.data.kilometerSegments;
        final int? activeInspectIndex =
            _hoveredSegmentIndex ?? _selectedSegmentIndex;
        final ClimbKilometerSegment? inspectedSegment =
            (activeInspectIndex != null &&
                    activeInspectIndex >= 0 &&
                    activeInspectIndex < segments.length)
                ? segments[activeInspectIndex]
                : null;

        return FocusableActionDetector(
          enabled: widget.enabled,
          onShowFocusHighlight: (bool focused) {
            setState(() => _isCardFocused = focused);
          },
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowRight):
                _NextClimbKmIntent(),
            SingleActivator(LogicalKeyboardKey.arrowLeft):
                _PrevClimbKmIntent(),
            SingleActivator(LogicalKeyboardKey.enter): _ToggleClimbHudIntent(),
            SingleActivator(LogicalKeyboardKey.space): _ToggleClimbHudIntent(),
          },
          actions: <Type, Action<Intent>>{
            _NextClimbKmIntent: CallbackAction<_NextClimbKmIntent>(
              onInvoke: (_) {
                _stepSelectedSegment(1);
                return null;
              },
            ),
            _PrevClimbKmIntent: CallbackAction<_PrevClimbKmIntent>(
              onInvoke: (_) {
                _stepSelectedSegment(-1);
                return null;
              },
            ),
            _ToggleClimbHudIntent: CallbackAction<_ToggleClimbHudIntent>(
              onInvoke: (_) {
                _handleToggleExpand();
                return null;
              },
            ),
          },
          child: MouseRegion(
            onEnter: (_) {
              if (widget.enabled) setState(() => _isCardHovered = true);
            },
            onExit: (_) {
              if (mounted) {
                setState(() {
                  _isCardHovered = false;
                  _hoveredSegmentIndex = null;
                });
              }
            },
            child: AnimatedOpacity(
              duration: _animDuration,
              curve: Curves.easeOutCubic,
              opacity: widget.enabled ? 1.0 : 0.52,
              child: AnimatedContainer(
                duration: _animDuration,
                curve: Curves.easeOutCubic,
                width: cardWidth,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: _isCardFocused ? 1.5 : 1.0,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: _isCardHovered ? 24 : 16,
                      offset: const Offset(0, 8),
                    ),
                    if (_isCardFocused || _isCardHovered)
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.10),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildBroadcastHeader(isCompactMobile),
                      AnimatedSize(
                        duration: _animDuration,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _isExpanded
                            ? _buildExpandedBody(
                                isCompactMobile: isCompactMobile,
                                segments: segments,
                                inspectedSegment: inspectedSegment,
                              )
                            : _buildCollapsedSummary(isCompactMobile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBroadcastHeader(bool isCompactMobile) {
    final Color catColor = _categoryBadgeColor(widget.data.category);
    final String catLabel = _categoryBadgeLabel(widget.data.category);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactMobile ? 10 : 14,
        vertical: isCompactMobile ? 8 : 10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.surfaceLight,
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Text(
              catLabel,
              style: _interStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: widget.data.category == SegmentClassification.cat3
                    ? AppColors.background
                    : AppColors.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.data.climbName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _interStyle(
                    fontSize: isCompactMobile ? 12 : 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${widget.data.totalLengthKm.toStringAsFixed(1)} km  •  śr. ${widget.data.averageGradientPercent.toStringAsFixed(1)}%  •  ${widget.data.summitElevationM.toStringAsFixed(0)} m n.p.m.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _interStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    tabular: true,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onFocusClimbCamera != null) ...<Widget>[
            const SizedBox(width: 6),
            _HudActionIconButton(
              icon: Icons.videocam_rounded,
              tooltip: 'Kamera na lidera podjazdu',
              enabled: widget.enabled,
              isHovered: _isCameraHovered,
              isPressed: _isCameraPressed,
              isFocused: _isCameraFocused,
              onHoverChanged: (bool v) => setState(() => _isCameraHovered = v),
              onPressedChanged: (bool v) => setState(() => _isCameraPressed = v),
              onFocusChanged: (bool v) => setState(() => _isCameraFocused = v),
              onTap: widget.onFocusClimbCamera,
            ),
          ],
          const SizedBox(width: 6),
          _HudActionIconButton(
            icon: _isExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            tooltip: _isExpanded ? 'Zwiń profil 3D' : 'Rozwiń profil 3D',
            enabled: widget.enabled,
            isHovered: _isToggleHovered,
            isPressed: _isTogglePressed,
            isFocused: _isToggleFocused,
            onHoverChanged: (bool v) => setState(() => _isToggleHovered = v),
            onPressedChanged: (bool v) => setState(() => _isTogglePressed = v),
            onFocusChanged: (bool v) => setState(() => _isToggleFocused = v),
            onTap: _handleToggleExpand,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSummary(bool isCompactMobile) {
    final ClimbGradientDifficultyBand currentBand =
        ClimbGradientDifficultyBand.fromGradient(
      widget.data.currentGradientPercent,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompactMobile ? 10 : 14,
        vertical: 8,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _buildVamLeaderBadge(compact: true),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: currentBand.frontColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: currentBand.edgeColor, width: 1.0),
                ),
                child: Text(
                  '${widget.data.currentGradientPercent.toStringAsFixed(1)}%',
                  style: _interStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: currentBand.badgeTextColor,
                    tabular: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Do szczytu ${widget.data.remainingKm.toStringAsFixed(1)} km',
                style: _interStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  tabular: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBody({
    required bool isCompactMobile,
    required List<ClimbKilometerSegment> segments,
    required ClimbKilometerSegment? inspectedSegment,
  }) {
    final double hPad = isCompactMobile ? 10.0 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Pasek VAM lidera + aktualne nachylenie i dystans do szczytu
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _buildVamLeaderBadge(compact: isCompactMobile),
              _buildLiveSlopeAndRemainingPill(isCompactMobile),
            ],
          ),
          const SizedBox(height: 10),
          // Kontener 3D słupków kilometrowych
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _build3dRibbonCanvas(segments, isCompactMobile),
                if (inspectedSegment != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _buildInspectedSegmentPill(inspectedSegment),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Legenda progów nachylenia (4-6% żółty, 7-9% pomarańczowy, 10-12% czerwony, >12% czarny)
          _buildGradientLegendRow(isCompactMobile),
        ],
      ),
    );
  }

  Widget _buildVamLeaderBadge({required bool compact}) {
    final double vam = widget.data.leaderVamMetersPerHour.isNaN ||
            widget.data.leaderVamMetersPerHour.isInfinite
        ? 0.0
        : math.max(0.0, widget.data.leaderVamMetersPerHour);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.trending_up_rounded,
            size: 14,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 5),
          Text(
            'ŚR. VAM LIDERA',
            style: _interStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${vam.toStringAsFixed(0)} m/h',
            style: _interStyle(
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              tabular: true,
            ),
          ),
          if (!compact &&
              widget.data.leaderName != null &&
              widget.data.leaderName!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '(${widget.data.leaderName!.trim()})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _interStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveSlopeAndRemainingPill(bool isCompactMobile) {
    final ClimbGradientDifficultyBand band =
        ClimbGradientDifficultyBand.fromGradient(
      widget.data.currentGradientPercent,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: band.frontColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: band.edgeColor, width: 1.0),
          ),
          child: Text(
            '${widget.data.currentGradientPercent.toStringAsFixed(1)}%',
            style: _interStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: band.badgeTextColor,
              tabular: true,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: Text(
            'META ${widget.data.remainingKm.toStringAsFixed(1)} km',
            style: _interStyle(
              fontSize: isCompactMobile ? 10 : 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              tabular: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _build3dRibbonCanvas(
    List<ClimbKilometerSegment> segments,
    bool isCompactMobile,
  ) {
    if (segments.isEmpty) {
      return SizedBox(
        height: 92,
        child: Center(
          child: Text(
            'Brak danych profilowych podjazdu',
            style: _interStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final double canvasHeight = isCompactMobile ? 104.0 : 120.0;
    const double minBarWidth = 26.0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double maxW = box.maxWidth.isFinite ? box.maxWidth : 340.0;
        final double neededW =
            math.max(maxW, segments.length * minBarWidth + 24.0);
        final bool needsScroll = neededW > maxW + 1.0;

        Widget painterWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) {
            if (!widget.enabled) return;
            final int? hit = _hitTestBarIndex(
              details.localPosition,
              Size(neededW, canvasHeight),
              segments.length,
            );
            if (hit != null) {
              setState(() => _pressedSegmentIndex = hit);
            }
          },
          onTapUp: (TapUpDetails details) {
            if (!widget.enabled) return;
            final int? hit = _hitTestBarIndex(
              details.localPosition,
              Size(neededW, canvasHeight),
              segments.length,
            );
            setState(() => _pressedSegmentIndex = null);
            if (hit != null) {
              _selectSegment(hit);
            }
          },
          onTapCancel: () {
            if (mounted) setState(() => _pressedSegmentIndex = null);
          },
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onHover: (PointerHoverEvent event) {
              if (!widget.enabled) return;
              final int? hit = _hitTestBarIndex(
                event.localPosition,
                Size(neededW, canvasHeight),
                segments.length,
              );
              if (hit != _hoveredSegmentIndex) {
                setState(() => _hoveredSegmentIndex = hit);
              }
            },
            onExit: (_) {
              if (_hoveredSegmentIndex != null) {
                setState(() => _hoveredSegmentIndex = null);
              }
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, _) {
                return CustomPaint(
                  size: Size(neededW, canvasHeight),
                  painter: _ClimbGradient3dRibbonPainter(
                    segments: segments,
                    progressFraction: widget.data.progressFraction,
                    hoveredIndex: _hoveredSegmentIndex,
                    selectedIndex: _selectedSegmentIndex,
                    pressedIndex: _pressedSegmentIndex,
                    pulseValue: _pulseController.value,
                    enabled: widget.enabled,
                  ),
                );
              },
            ),
          ),
        );

        if (needsScroll) {
          painterWidget = SingleChildScrollView(
            controller: _ribbonScrollController,
            scrollDirection: Axis.horizontal,
            child: painterWidget,
          );
        }

        return SizedBox(
          height: canvasHeight,
          width: maxW,
          child: painterWidget,
        );
      },
    );
  }

  int? _hitTestBarIndex(Offset localPos, Size size, int count) {
    if (count <= 0) return null;
    const double leftPad = 10.0;
    const double rightPad = 14.0;
    final double usableWidth = math.max(10.0, size.width - leftPad - rightPad);
    final double slotWidth = usableWidth / count;
    final double relX = localPos.dx - leftPad;
    if (relX < 0 || relX > usableWidth) return null;
    return (relX / slotWidth).floor().clamp(0, count - 1);
  }

  Widget _buildInspectedSegmentPill(ClimbKilometerSegment seg) {
    final ClimbGradientDifficultyBand band = seg.band;
    final String elevGain = seg.elevationGainM.toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: band.frontColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: band.edgeColor, width: 0.9),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'KM ${seg.kilometerIndex} (${seg.lengthKm.toStringAsFixed(1)} km)  •  ${seg.gradientPercent.toStringAsFixed(1)}% (${band.rangeLabel})  •  +$elevGain m',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _interStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                tabular: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientLegendRow(bool isCompactMobile) {
    const List<ClimbGradientDifficultyBand> legendBands =
        <ClimbGradientDifficultyBand>[
      ClimbGradientDifficultyBand.yellow,
      ClimbGradientDifficultyBand.orange,
      ClimbGradientDifficultyBand.red,
      ClimbGradientDifficultyBand.black,
    ];

    return Wrap(
      spacing: isCompactMobile ? 8 : 12,
      runSpacing: 4,
      alignment: WrapAlignment.spaceBetween,
      children: legendBands.map((ClimbGradientDifficultyBand band) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: band.frontColor,
                borderRadius: BorderRadius.circular(2.5),
                border: Border.all(
                  color: band == ClimbGradientDifficultyBand.black
                      ? AppColors.textPrimary.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 0.9,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              band.rangeLabel,
              style: _interStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                tabular: true,
              ),
            ),
          ],
        );
      }).toList(growable: false),
    );
  }
}

class _NextClimbKmIntent extends Intent {
  const _NextClimbKmIntent();
}

class _PrevClimbKmIntent extends Intent {
  const _PrevClimbKmIntent();
}

class _ToggleClimbHudIntent extends Intent {
  const _ToggleClimbHudIntent();
}

class _HudActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final bool isHovered;
  final bool isPressed;
  final bool isFocused;
  final ValueChanged<bool> onHoverChanged;
  final ValueChanged<bool> onPressedChanged;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback? onTap;

  const _HudActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.isHovered,
    required this.isPressed,
    required this.isFocused,
    required this.onHoverChanged,
    required this.onPressedChanged,
    required this.onFocusChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = !enabled
        ? AppColors.surface
        : (isPressed
            ? AppColors.primaryAccent
            : (isHovered ? AppColors.surfaceLight : AppColors.background));

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (isFocused
            ? AppColors.goldAccent
            : (isHovered ? AppColors.goldAccent.withValues(alpha: 0.6) : AppColors.cardBorder));

    return Tooltip(
      message: tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: onFocusChanged,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onTap?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) {
            if (enabled) onHoverChanged(true);
          },
          onExit: (_) => onHoverChanged(false),
          child: GestureDetector(
            onTapDown: (_) {
              if (enabled) onPressedChanged(true);
            },
            onTapUp: (_) {
              if (enabled) {
                onPressedChanged(false);
                onTap?.call();
              }
            },
            onTapCancel: () => onPressedChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: isFocused ? 1.5 : 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: enabled
                    ? (isHovered || isFocused
                        ? AppColors.goldAccent
                        : AppColors.textPrimary)
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rysujący trójwymiarowe słupki nachylenia każdego kilometra
/// z rzutem izometrycznym (front + górna ściana + prawa ściana głębi).
class _ClimbGradient3dRibbonPainter extends CustomPainter {
  final List<ClimbKilometerSegment> segments;
  final double progressFraction;
  final int? hoveredIndex;
  final int? selectedIndex;
  final int? pressedIndex;
  final double pulseValue;
  final bool enabled;

  const _ClimbGradient3dRibbonPainter({
    required this.segments,
    required this.progressFraction,
    required this.hoveredIndex,
    required this.selectedIndex,
    required this.pressedIndex,
    required this.pulseValue,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    const double leftPad = 10.0;
    const double rightPad = 14.0;
    const double topPad = 18.0;
    const double bottomPad = 20.0;

    final double chartWidth = math.max(10.0, size.width - leftPad - rightPad);
    final double baseY = size.height - bottomPad;
    final double maxHeight = math.max(16.0, baseY - topPad);

    final int count = segments.length;
    final double slotWidth = chartWidth / count;
    final double depthX = math.min(7.5, slotWidth * 0.24);
    final double depthY = math.min(6.0, depthX * 0.8);
    final double barGap = math.min(3.5, slotWidth * 0.14);
    final double barWidth = math.max(6.0, slotWidth - depthX - barGap);

    // Subtelna linia podstawy i siatka odniesienia
    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(leftPad, baseY),
      Offset(size.width - rightPad + depthX, baseY),
      gridPaint,
    );

    // Wyznaczamy wysokość każdego słupka proporcjonalnie do skumulowanej wysokości / nachylenia
    double maxGrad = 14.0;
    for (final ClimbKilometerSegment s in segments) {
      if (s.gradientPercent > maxGrad) {
        maxGrad = s.gradientPercent;
      }
    }

    for (int i = 0; i < count; i++) {
      final ClimbKilometerSegment seg = segments[i];
      final ClimbGradientDifficultyBand band = seg.band;
      final bool isHovered = hoveredIndex == i;
      final bool isSelected = selectedIndex == i;
      final bool isPressed = pressedIndex == i;

      final double normalizedSlope =
          (seg.gradientPercent.clamp(1.0, maxGrad) / maxGrad).clamp(0.16, 1.0);
      // Lekkie wznoszenie wstęgi + wysokość zależna od stromizny kilometra
      final double climbStepLift = ((i + 1) / count) * (maxHeight * 0.28);
      final double slopeHeight = normalizedSlope * (maxHeight * 0.68);
      final double barHeight =
          (climbStepLift + slopeHeight).clamp(14.0, maxHeight);

      final double x = leftPad + i * slotWidth;
      final double pressOffsetY = isPressed ? 2.0 : 0.0;
      final double hoverLiftY = (isHovered || isSelected) && !isPressed ? 2.5 : 0.0;
      final double topY = (baseY - barHeight - hoverLiftY + pressOffsetY)
          .clamp(topPad - 4.0, baseY - 8.0);

      final double segProgress = (i + 0.5) / count;
      final bool isPassed = segProgress <= progressFraction;
      final double dimAlpha = !enabled ? 0.55 : (isPassed ? 0.62 : 1.0);

      // 1. Ściana frontowa
      final Rect frontRect = Rect.fromLTRB(x, topY, x + barWidth, baseY);
      final Paint frontPaint = Paint()
        ..color = band.frontColor.withValues(alpha: dimAlpha);
      canvas.drawRect(frontRect, frontPaint);

      // 2. Górna ściana 3D (równoległobok)
      final Path topFace = Path()
        ..moveTo(x, topY)
        ..lineTo(x + depthX, topY - depthY)
        ..lineTo(x + barWidth + depthX, topY - depthY)
        ..lineTo(x + barWidth, topY)
        ..close();
      final Paint topPaint = Paint()
        ..color = band.topColor.withValues(alpha: dimAlpha);
      canvas.drawPath(topFace, topPaint);

      // 3. Prawa ściana 3D głębi (równoległobok)
      final Path sideFace = Path()
        ..moveTo(x + barWidth, topY)
        ..lineTo(x + barWidth + depthX, topY - depthY)
        ..lineTo(x + barWidth + depthX, baseY - depthY)
        ..lineTo(x + barWidth, baseY)
        ..close();
      final Paint sidePaint = Paint()
        ..color = band.sideColor.withValues(alpha: dimAlpha);
      canvas.drawPath(sideFace, sidePaint);

      // 4. Krawędzie 3D (szczególnie ważne dla czarnego >12% oraz stanów hover/active)
      final Color outlineColor = (isSelected || isHovered)
          ? AppColors.goldAccent
          : band.edgeColor;
      final Paint outlinePaint = Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (isSelected || isHovered) ? 1.5 : 0.85;
      canvas.drawRect(frontRect, outlinePaint);
      canvas.drawPath(topFace, outlinePaint);
      canvas.drawPath(sideFace, outlinePaint);

      // 5. Etykieta % nad słupkiem (jeśli jest wystarczająco miejsca lub wybrany/najechano)
      if (slotWidth >= 24.0 || isHovered || isSelected) {
        final TextPainter gradTp = TextPainter(
          text: TextSpan(
            text: '${seg.gradientPercent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: slotWidth < 26 ? 8.0 : 9.0,
              fontWeight: FontWeight.w800,
              color: (isSelected || isHovered)
                  ? AppColors.goldAccent
                  : AppColors.textPrimary.withValues(alpha: 0.9),
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        gradTp.paint(
          canvas,
          Offset(
            x + (barWidth + depthX) * 0.5 - gradTp.width * 0.5,
            math.max(1.0, topY - depthY - gradTp.height - 2.0),
          ),
        );
      }

      // 6. Podpis kilometra pod osią (co 1 lub co 2 przy gęstych podjazdach)
      final bool showKmLabel =
          count <= 12 || i == 0 || i == count - 1 || (i + 1) % 2 == 1;
      if (showKmLabel) {
        final TextPainter kmTp = TextPainter(
          text: TextSpan(
            text: '${seg.kilometerIndex}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.0,
              fontWeight: (isSelected || isHovered)
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: (isSelected || isHovered)
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        kmTp.paint(
          canvas,
          Offset(
            x + barWidth * 0.5 - kmTp.width * 0.5,
            baseY + 4.0,
          ),
        );
      }
    }

    // 7. Znacznik pozycji lidera na podjeździe (złoty pulsujący znacznik)
    final double markerX =
        leftPad + (progressFraction.clamp(0.0, 1.0) * (chartWidth - barGap));
    final Paint markerLinePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.85)
      ..strokeWidth = 1.6;
    canvas.drawLine(
      Offset(markerX, 4.0),
      Offset(markerX, baseY),
      markerLinePaint,
    );

    final double glowRadius = 5.5 + pulseValue * 3.0;
    final Paint glowPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.28 * (1.0 - pulseValue * 0.4));
    canvas.drawCircle(Offset(markerX, 6.0), glowRadius, glowPaint);

    final Paint corePaint = Paint()..color = AppColors.goldAccent;
    canvas.drawCircle(Offset(markerX, 6.0), 3.6, corePaint);
  }

  @override
  bool shouldRepaint(covariant _ClimbGradient3dRibbonPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.progressFraction != progressFraction ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.pressedIndex != pressedIndex ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.enabled != enabled;
  }
}
