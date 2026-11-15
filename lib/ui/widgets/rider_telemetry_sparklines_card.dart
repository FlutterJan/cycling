import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Pojedyncza próbka telemetryczna kolarza (1 sekunda).
class TelemetrySample {
  /// Znacznik czasu w sekundach od startu etapu (lub indeks próbki).
  final int timestampSeconds;

  /// Chwilowa moc generowana na pedałach [W].
  final double powerWatts;

  /// Chwilowe tętno kolarza [bpm].
  final int heartRateBpm;

  const TelemetrySample({
    required this.timestampSeconds,
    required this.powerWatts,
    required this.heartRateBpm,
  });
}

/// Wynik analizy strefy mocy Coggana (Z1–Z7).
class PowerZoneInfo {
  final int zone;
  final String code;
  final String name;
  final Color color;

  const PowerZoneInfo({
    required this.zone,
    required this.code,
    required this.name,
    required this.color,
  });
}

/// Wynik analizy spalonych "zapałek" (Matches Burned) podczas etapu.
class MatchesBurnedAnalysis {
  /// Liczba ukończonych zrywów beztlenowych (>120% FTP przez >15 s).
  final int matchesBurned;

  /// Czas trwania bieżącego aktywnego zrywu >120% FTP [s] (0 jeśli brak).
  final int currentSurgeSeconds;

  /// Czy kolarz jest aktualnie powyżej progu 120% FTP.
  final bool isAboveThresholdNow;

  /// Procentowa redukcja maksymalnego sprintu na finiszu [0..maxPenalty].
  final double sprintPenaltyPercent;

  /// Efektywna moc maksymalnego sprintu po uwzględnieniu spalonych zapałek [W].
  final double effectiveMaxSprintWatts;

  const MatchesBurnedAnalysis({
    required this.matchesBurned,
    required this.currentSurgeSeconds,
    required this.isAboveThresholdNow,
    required this.sprintPenaltyPercent,
    required this.effectiveMaxSprintWatts,
  });
}

/// Kalkulator stref mocy Z1–Z7 oraz spalonych zapałek beztlenowych.
class MatchesBurnedCalculator {
  MatchesBurnedCalculator._();

  static const double defaultThresholdRatio = 1.20;
  static const int defaultMinDurationSeconds = 15;
  static const double defaultSprintPenaltyPerMatchPercent = 2.5;
  static const double defaultMaxSprintPenaltyPercent = 35.0;

  /// Wyznacza strefę mocy Z1–Z7 na podstawie aktualnej mocy i FTP.
  static PowerZoneInfo resolvePowerZone({
    required double powerWatts,
    required double ftpWatts,
  }) {
    if (ftpWatts <= 0 || powerWatts <= 0) {
      return PowerZoneInfo(
        zone: 1,
        code: 'Z1',
        name: 'Regeneracja',
        color: AppColors.getPowerZoneColor(1),
      );
    }

    final double ratio = powerWatts / ftpWatts;
    if (ratio < 0.55) {
      return PowerZoneInfo(
        zone: 1,
        code: 'Z1',
        name: 'Regeneracja',
        color: AppColors.getPowerZoneColor(1),
      );
    } else if (ratio < 0.75) {
      return PowerZoneInfo(
        zone: 2,
        code: 'Z2',
        name: 'Wytrzymałość',
        color: AppColors.getPowerZoneColor(2),
      );
    } else if (ratio < 0.90) {
      return PowerZoneInfo(
        zone: 3,
        code: 'Z3',
        name: 'Tempo',
        color: AppColors.getPowerZoneColor(3),
      );
    } else if (ratio < 1.05) {
      return PowerZoneInfo(
        zone: 4,
        code: 'Z4',
        name: 'Próg mleczanowy',
        color: AppColors.getPowerZoneColor(4),
      );
    } else if (ratio < 1.20) {
      return PowerZoneInfo(
        zone: 5,
        code: 'Z5',
        name: 'VO2 Max',
        color: AppColors.getPowerZoneColor(5),
      );
    } else if (ratio < 1.50) {
      return PowerZoneInfo(
        zone: 6,
        code: 'Z6',
        name: 'Beztlenowa',
        color: AppColors.getPowerZoneColor(6),
      );
    } else {
      return PowerZoneInfo(
        zone: 7,
        code: 'Z7',
        name: 'Nerwowo-mięśniowa',
        color: AppColors.getPowerZoneColor(7),
      );
    }
  }

  /// Analizuje historię mocy z etapu (1 próbka = 1 sekunda) i zlicza spalone zapałki.
  ///
  /// Każde przekroczenie progu `> 120% FTP` trwające **dłużej niż 15 sekund**
  /// (czyli co najmniej 16 kolejnych próbek) zalicza jedną spaloną zapałkę.
  /// Każda spalona zapałka obniża maksymalny sprint na finiszu o `sprintPenaltyPerMatchPercent`.
  static MatchesBurnedAnalysis analyzeStageTelemetry({
    required List<double> stagePowerHistoryWatts,
    required double ftpWatts,
    double baseMaxSprintWatts = 1200.0,
    double thresholdRatio = defaultThresholdRatio,
    int minDurationSeconds = defaultMinDurationSeconds,
    double sprintPenaltyPerMatchPercent = defaultSprintPenaltyPerMatchPercent,
    double maxSprintPenaltyPercent = defaultMaxSprintPenaltyPercent,
  }) {
    final double safeSprint = math.max(0.0, baseMaxSprintWatts);
    if (stagePowerHistoryWatts.isEmpty || ftpWatts <= 0) {
      return MatchesBurnedAnalysis(
        matchesBurned: 0,
        currentSurgeSeconds: 0,
        isAboveThresholdNow: false,
        sprintPenaltyPercent: 0.0,
        effectiveMaxSprintWatts: safeSprint,
      );
    }

    final double thresholdWatts = ftpWatts * thresholdRatio;
    int matchesCount = 0;
    int streak = 0;

    for (final double watts in stagePowerHistoryWatts) {
      if (watts > thresholdWatts) {
        streak++;
      } else {
        if (streak > minDurationSeconds) {
          matchesCount++;
        }
        streak = 0;
      }
    }

    // Jeśli zryw trwa nadal na końcu bufora i już przekroczył 15s, jest aktywnie spalony.
    final bool isAboveNow = streak > 0;
    if (streak > minDurationSeconds) {
      matchesCount++;
    }

    final double penaltyPercent = (matchesCount * sprintPenaltyPerMatchPercent)
        .clamp(0.0, maxSprintPenaltyPercent);
    final double effectiveSprint = safeSprint * (1.0 - penaltyPercent / 100.0);

    return MatchesBurnedAnalysis(
      matchesBurned: matchesCount,
      currentSurgeSeconds: streak,
      isAboveThresholdNow: isAboveNow,
      sprintPenaltyPercent: penaltyPercent,
      effectiveMaxSprintWatts: effectiveSprint,
    );
  }
}

/// Pełny zestaw danych wejściowych dla karty `RiderTelemetrySparklinesCard`.
class RiderTelemetrySparklinesData {
  final String riderId;
  final String riderName;
  final double ftpWatts;
  final double baseMaxSprintWatts;
  final int maxHeartRateBpm;
  final int restingHeartRateBpm;

  /// Próbki z ostatnich 60 sekund (jeśli podano więcej, brane jest ostatnie 60).
  final List<TelemetrySample> last60sSamples;

  /// Opcjonalna pełna historia mocy z etapu do automatycznego wyliczenia zapałek.
  /// Jeśli null, używana jest wartość [matchesBurnedOverride] lub próbki z [last60sSamples].
  final List<double>? stagePowerHistoryWatts;

  /// Opcjonalne jawne nadpisanie licznika spalonych zapałek (np. z silnika symulacji).
  final int? matchesBurnedOverride;

  /// Opcjonalny bieżący czas trwania aktywnego zrywu >120% FTP [s].
  final int? currentSurgeSecondsOverride;

  const RiderTelemetrySparklinesData({
    required this.riderId,
    required this.riderName,
    required this.ftpWatts,
    required this.baseMaxSprintWatts,
    this.maxHeartRateBpm = 195,
    this.restingHeartRateBpm = 50,
    required this.last60sSamples,
    this.stagePowerHistoryWatts,
    this.matchesBurnedOverride,
    this.currentSurgeSecondsOverride,
  });

  List<TelemetrySample> get windowSamples {
    if (last60sSamples.length <= 60) return last60sSamples;
    return last60sSamples.sublist(last60sSamples.length - 60);
  }

  MatchesBurnedAnalysis resolveMatchesAnalysis() {
    if (matchesBurnedOverride != null) {
      final int count = math.max(0, matchesBurnedOverride!);
      final double penalty =
          (count * MatchesBurnedCalculator.defaultSprintPenaltyPerMatchPercent)
              .clamp(0.0, MatchesBurnedCalculator.defaultMaxSprintPenaltyPercent);
      final double effective =
          math.max(0.0, baseMaxSprintWatts) * (1.0 - penalty / 100.0);
      final double latestWatts =
          last60sSamples.isNotEmpty ? last60sSamples.last.powerWatts : 0.0;
      final bool aboveNow =
          ftpWatts > 0 && latestWatts > ftpWatts * MatchesBurnedCalculator.defaultThresholdRatio;
      return MatchesBurnedAnalysis(
        matchesBurned: count,
        currentSurgeSeconds: currentSurgeSecondsOverride ?? 0,
        isAboveThresholdNow: aboveNow,
        sprintPenaltyPercent: penalty,
        effectiveMaxSprintWatts: effective,
      );
    }

    final List<double> history = stagePowerHistoryWatts ??
        last60sSamples.map((s) => s.powerWatts).toList(growable: false);

    return MatchesBurnedCalculator.analyzeStageTelemetry(
      stagePowerHistoryWatts: history,
      ftpWatts: ftpWatts,
      baseMaxSprintWatts: baseMaxSprintWatts,
    );
  }
}

/// Zaawansowana karta analityczna Sparklines (60s Moc + Tętno) oraz licznik
/// spalonych zapałek beztlenowych dla wyścigu 3D i laboratorium wydolnościowego.
class RiderTelemetrySparklinesCard extends StatefulWidget {
  final RiderTelemetrySparklinesData data;
  final bool isSelected;
  final bool isDisabled;
  final bool showLaboratoryDetails;
  final VoidCallback? onTap;
  final ValueChanged<TelemetrySample?>? onSampleHovered;

  const RiderTelemetrySparklinesCard({
    super.key,
    required this.data,
    this.isSelected = false,
    this.isDisabled = false,
    this.showLaboratoryDetails = false,
    this.onTap,
    this.onSampleHovered,
  });

  @override
  State<RiderTelemetrySparklinesCard> createState() =>
      _RiderTelemetrySparklinesCardState();
}

class _RiderTelemetrySparklinesCardState
    extends State<RiderTelemetrySparklinesCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  double? _hoverFraction;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isInteractive => !widget.isDisabled && widget.onTap != null;

  void _updateHoverFraction(Offset localPosition, double width) {
    if (widget.isDisabled || width <= 0) return;
    final double fraction = (localPosition.dx / width).clamp(0.0, 1.0);
    if (_hoverFraction != fraction) {
      setState(() {
        _hoverFraction = fraction;
      });
      _notifyHoveredSample(fraction);
    }
  }

  void _clearHoverFraction() {
    if (_hoverFraction != null) {
      setState(() {
        _hoverFraction = null;
      });
      widget.onSampleHovered?.call(null);
    }
  }

  void _notifyHoveredSample(double fraction) {
    final samples = widget.data.windowSamples;
    if (samples.isEmpty || widget.onSampleHovered == null) return;
    final int idx =
        (fraction * (samples.length - 1)).round().clamp(0, samples.length - 1);
    widget.onSampleHovered!(samples[idx]);
  }

  TelemetrySample? _hoveredSample(List<TelemetrySample> samples) {
    if (_hoverFraction == null || samples.isEmpty) return null;
    final int idx = (_hoverFraction! * (samples.length - 1))
        .round()
        .clamp(0, samples.length - 1);
    return samples[idx];
  }

  @override
  Widget build(BuildContext context) {
    final samples = widget.data.windowSamples;
    final TelemetrySample? latest = samples.isNotEmpty ? samples.last : null;
    final TelemetrySample? hovered = _hoveredSample(samples);
    final TelemetrySample? displaySample = hovered ?? latest;

    final double displayWatts = displaySample?.powerWatts ?? 0.0;
    final int displayHr = displaySample?.heartRateBpm ?? 0;

    final PowerZoneInfo zoneInfo = MatchesBurnedCalculator.resolvePowerZone(
      powerWatts: displayWatts,
      ftpWatts: widget.data.ftpWatts,
    );

    final MatchesBurnedAnalysis matchesAnalysis =
        widget.data.resolveMatchesAnalysis();

    final Color borderColor = _resolveBorderColor(zoneInfo.color);
    final Color backgroundColor = _resolveBackgroundColor();

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) {
          setState(() => _isFocused = focused);
        }
      },
      onShowHoverHighlight: (hovered) {
        if (_isHovered != hovered) {
          setState(() => _isHovered = hovered);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (_isInteractive) widget.onTap?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: _isInteractive
            ? SystemMouseCursors.click
            : (widget.isDisabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.basic),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _isInteractive
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: _isInteractive
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: _isInteractive
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: _isInteractive ? widget.onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            opacity: widget.isDisabled ? 0.45 : 1.0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              scale: _isPressed ? 0.985 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected || _isFocused ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    if (widget.isSelected || _isHovered)
                      BoxShadow(
                        color: (widget.isSelected
                                ? AppColors.goldAccent
                                : zoneInfo.color)
                            .withValues(alpha: widget.isSelected ? 0.18 : 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isCompact = constraints.maxWidth < 360;
                    final bool isWide = constraints.maxWidth >= 560;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(
                          isCompact: isCompact,
                          zoneInfo: zoneInfo,
                          displayWatts: displayWatts,
                          displayHr: displayHr,
                          isScrubbing: hovered != null,
                          hoveredSecondsAgo: hovered != null && latest != null
                              ? (latest.timestampSeconds -
                                      hovered.timestampSeconds)
                                  .clamp(0, 60)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildSparklineCanvas(
                                  samples: samples,
                                  zoneInfo: zoneInfo,
                                  height: 96,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: _buildMatchesBurnedPanel(
                                  analysis: matchesAnalysis,
                                  isCompact: false,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildSparklineCanvas(
                            samples: samples,
                            zoneInfo: zoneInfo,
                            height: isCompact ? 76 : 88,
                          ),
                          const SizedBox(height: 10),
                          _buildMatchesBurnedPanel(
                            analysis: matchesAnalysis,
                            isCompact: isCompact,
                          ),
                        ],
                        if (widget.showLaboratoryDetails) ...[
                          const SizedBox(height: 10),
                          _buildLaboratoryFooter(
                            samples: samples,
                            isCompact: isCompact,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _resolveBorderColor(Color zoneColor) {
    if (widget.isDisabled) {
      return AppTheme.borderColor;
    }
    if (_isFocused) {
      return AppColors.goldAccent;
    }
    if (widget.isSelected) {
      return AppColors.goldAccent;
    }
    if (_isHovered) {
      return zoneColor.withValues(alpha: 0.75);
    }
    return AppTheme.borderColor;
  }

  Color _resolveBackgroundColor() {
    if (widget.isSelected) {
      return AppColors.surfaceLight;
    }
    if (_isHovered && !widget.isDisabled) {
      return const Color(0xFF1C2029);
    }
    return AppColors.surface;
  }

  Widget _buildHeader({
    required bool isCompact,
    required PowerZoneInfo zoneInfo,
    required double displayWatts,
    required int displayHr,
    required bool isScrubbing,
    required int? hoveredSecondsAgo,
  }) {
    final Widget zoneBadge = AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: zoneInfo.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: zoneInfo.color.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: Text(
        isCompact ? zoneInfo.code : '${zoneInfo.code} • ${zoneInfo.name}',
        style: TextStyle(
          fontFamily: 'Inter',
          color: zoneInfo.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final Widget metricsRow = Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 14, color: zoneInfo.color),
            const SizedBox(width: 2),
            Text(
              '${displayWatts.round()} W',
              style: AppTheme.statNumberStyle(
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 13,
              color: AppColors.crimsonAlert,
            ),
            const SizedBox(width: 3),
            Text(
              '$displayHr bpm',
              style: AppTheme.statNumberStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.data.riderName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              zoneBadge,
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: metricsRow),
              if (isScrubbing && hoveredSecondsAgo != null)
                Text(
                  '-${hoveredSecondsAgo}s',
                  style: AppTheme.statNumberStyle(
                    fontSize: 11,
                    color: AppColors.goldAccent,
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.data.riderName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isScrubbing && hoveredSecondsAgo != null
                        ? '(-${hoveredSecondsAgo}s)'
                        : '60s LIVE',
                    style: AppTheme.statNumberStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isScrubbing
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              metricsRow,
            ],
          ),
        ),
        const SizedBox(width: 8),
        zoneBadge,
      ],
    );
  }

  Widget _buildSparklineCanvas({
    required List<TelemetrySample> samples,
    required PowerZoneInfo zoneInfo,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (samples.isEmpty) {
              return const Center(
                child: Text(
                  'Brak danych telemetrycznych (60s)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            return MouseRegion(
              onHover: (event) =>
                  _updateHoverFraction(event.localPosition, constraints.maxWidth),
              onExit: (_) => _clearHoverFraction(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) => _updateHoverFraction(
                  details.localPosition,
                  constraints.maxWidth,
                ),
                onHorizontalDragEnd: (_) => _clearHoverFraction(),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, height),
                      painter: RiderTelemetrySparklinePainter(
                        samples: samples,
                        ftpWatts: widget.data.ftpWatts,
                        zoneColor: zoneInfo.color,
                        minHeartRateBpm: widget.data.restingHeartRateBpm,
                        maxHeartRateBpm: widget.data.maxHeartRateBpm,
                        hoverFraction: _hoverFraction,
                        livePulse: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchesBurnedPanel({
    required MatchesBurnedAnalysis analysis,
    required bool isCompact,
  }) {
    const int visualSlots = 5;
    final int burned = analysis.matchesBurned;
    final bool isBurning = analysis.isAboveThresholdNow &&
        analysis.currentSurgeSeconds > 0 &&
        analysis.currentSurgeSeconds <=
            MatchesBurnedCalculator.defaultMinDurationSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: analysis.isAboveThresholdNow
              ? AppColors.crimsonAlert.withValues(alpha: 0.55)
              : AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: burned > 0 || analysis.isAboveThresholdNow
                    ? AppColors.amberWarning
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Spalone zapałki',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$burned',
                style: AppTheme.statNumberStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: burned > 0
                      ? AppColors.amberWarning
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(visualSlots, (index) {
                final bool isUsed = index < burned;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _MatchstickGlyph(
                    isBurned: isUsed,
                    isActiveSurge: !isUsed &&
                        index == burned.clamp(0, visualSlots - 1) &&
                        isBurning,
                    pulse: _pulseController.value,
                  ),
                );
              }),
              if (burned > visualSlots)
                Text(
                  '+${burned - visualSlots}',
                  style: AppTheme.statNumberStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.crimsonAlert,
                  ),
                ),
              const Spacer(),
              Flexible(
                child: Text(
                  isCompact
                      ? '${analysis.effectiveMaxSprintWatts.round()}W'
                      : 'Sprint: ${analysis.effectiveMaxSprintWatts.round()} W',
                  style: AppTheme.statNumberStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: analysis.sprintPenaltyPercent > 0
                        ? AppColors.crimsonAlert
                        : AppColors.statusSuccess,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (analysis.sprintPenaltyPercent > 0 || isBurning) ...[
            const SizedBox(height: 6),
            if (isBurning)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Zryw >120% FTP',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.amberWarning,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${analysis.currentSurgeSeconds}s / 15s',
                        style: AppTheme.statNumberStyle(
                          fontSize: 10,
                          color: AppColors.amberWarning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (analysis.currentSurgeSeconds / 15.0)
                          .clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.amberWarning,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                'Kara finiszu: -${analysis.sprintPenaltyPercent.toStringAsFixed(1)}% maks. sprintu',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLaboratoryFooter({
    required List<TelemetrySample> samples,
    required bool isCompact,
  }) {
    if (samples.isEmpty) return const SizedBox.shrink();

    double sumWatts = 0;
    double maxWatts = 0;
    int sumHr = 0;
    int maxHr = 0;

    for (final s in samples) {
      sumWatts += s.powerWatts;
      if (s.powerWatts > maxWatts) maxWatts = s.powerWatts;
      sumHr += s.heartRateBpm;
      if (s.heartRateBpm > maxHr) maxHr = s.heartRateBpm;
    }

    final double avgWatts = sumWatts / samples.length;
    final int avgHr = (sumHr / samples.length).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Wrap(
        spacing: isCompact ? 10 : 16,
        runSpacing: 4,
        children: [
          _LabStatChip(label: 'Śr. 60s', value: '${avgWatts.round()} W'),
          _LabStatChip(label: 'Maks. 60s', value: '${maxWatts.round()} W'),
          _LabStatChip(label: 'Śr. HR', value: '$avgHr bpm'),
          _LabStatChip(label: 'Maks. HR', value: '$maxHr bpm'),
          _LabStatChip(
            label: 'Próg 120%',
            value: '${(widget.data.ftpWatts * 1.2).round()} W',
          ),
        ],
      ),
    );
  }
}

class _LabStatChip extends StatelessWidget {
  final String label;
  final String value;

  const _LabStatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTheme.statNumberStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Ikona pojedynczej zapałki (niepalona / spalona / aktywnie płonąca).
class _MatchstickGlyph extends StatelessWidget {
  final bool isBurned;
  final bool isActiveSurge;
  final double pulse;

  const _MatchstickGlyph({
    required this.isBurned,
    required this.isActiveSurge,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final Color headColor = isBurned
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : (isActiveSurge
            ? Color.lerp(
                AppColors.amberWarning,
                AppColors.crimsonAlert,
                pulse,
              )!
            : AppColors.crimsonAlert);

    final Color stickColor = isBurned
        ? AppColors.textSecondary.withValues(alpha: 0.25)
        : const Color(0xFFD6B98C);

    return SizedBox(
      width: 10,
      height: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: headColor,
              shape: BoxShape.circle,
              boxShadow: isActiveSurge
                  ? [
                      BoxShadow(
                        color: AppColors.amberWarning.withValues(alpha: 0.7),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          Container(
            width: 2.2,
            height: 10,
            decoration: BoxDecoration(
              color: stickColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lekki `CustomPainter` rysujący płynną krzywą mocy (60s) z gradientem strefy Z1–Z7
/// oraz nałożoną przerywaną linię tętna [bpm].
class RiderTelemetrySparklinePainter extends CustomPainter {
  final List<TelemetrySample> samples;
  final double ftpWatts;
  final Color zoneColor;
  final int minHeartRateBpm;
  final int maxHeartRateBpm;
  final double? hoverFraction;
  final double livePulse;

  const RiderTelemetrySparklinePainter({
    required this.samples,
    required this.ftpWatts,
    required this.zoneColor,
    this.minHeartRateBpm = 50,
    this.maxHeartRateBpm = 195,
    this.hoverFraction,
    this.livePulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0 || size.height <= 0) return;

    const double padTop = 8.0;
    const double padBottom = 8.0;
    const double padX = 6.0;
    final double plotWidth = math.max(1.0, size.width - padX * 2);
    final double plotHeight = math.max(1.0, size.height - padTop - padBottom);

    // Wyznacz zakres osi Y dla mocy
    double maxPower = math.max(ftpWatts * 1.45, 350.0);
    for (final s in samples) {
      if (s.powerWatts > maxPower) maxPower = s.powerWatts * 1.08;
    }

    // Linia odniesienia 120% FTP (próg spalania zapałek)
    if (ftpWatts > 0) {
      final double thresholdWatts = ftpWatts * 1.20;
      final double thresholdNorm = (thresholdWatts / maxPower).clamp(0.0, 1.0);
      final double thresholdY = padTop + plotHeight * (1.0 - thresholdNorm);

      final Paint thresholdPaint = Paint()
        ..color = AppColors.amberWarning.withValues(alpha: 0.35)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      _drawDashedHorizontalLine(
        canvas,
        Offset(padX, thresholdY),
        Offset(padX + plotWidth, thresholdY),
        thresholdPaint,
        dashWidth: 4,
        gapWidth: 4,
      );
    }

    // Punkty krzywej mocy
    final List<Offset> powerPoints = _buildPoints(
      samples.length,
      plotWidth,
      plotHeight,
      padX,
      padTop,
      (i) => (samples[i].powerWatts / maxPower).clamp(0.0, 1.0),
    );

    final Path powerCurve = _buildSmoothPath(powerPoints);

    // Wypełnienie gradientowe pod krzywą mocy odpowiadające strefie Z1–Z7
    if (powerPoints.length >= 2) {
      final Path fillPath = Path.from(powerCurve)
        ..lineTo(powerPoints.last.dx, padTop + plotHeight)
        ..lineTo(powerPoints.first.dx, padTop + plotHeight)
        ..close();

      final Paint fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, padTop),
          Offset(0, padTop + plotHeight),
          [
            zoneColor.withValues(alpha: 0.42),
            zoneColor.withValues(alpha: 0.03),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Obrys płynnej krzywej mocy
    final Paint powerLinePaint = Paint()
      ..color = zoneColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(powerCurve, powerLinePaint);

    // Punkty oraz przerywana linia tętna
    final int hrMin = math.min(minHeartRateBpm, 120);
    final int hrMax = math.max(maxHeartRateBpm, hrMin + 40);
    final List<Offset> hrPoints = _buildPoints(
      samples.length,
      plotWidth,
      plotHeight,
      padX,
      padTop,
      (i) => ((samples[i].heartRateBpm - hrMin) / (hrMax - hrMin))
          .clamp(0.0, 1.0),
    );
    final Path hrPath = _buildSmoothPath(hrPoints);

    // Ciemne podbicie dla czytelności linii tętna na tle strefy Z6
    final Paint hrCasingPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.65)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    _drawDashedPath(canvas, hrPath, hrCasingPaint, dashLength: 5, gapLength: 4);

    final Paint hrLinePaint = Paint()
      ..color = AppColors.crimsonAlert
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _drawDashedPath(canvas, hrPath, hrLinePaint, dashLength: 5, gapLength: 4);

    // Pulsujący punkt bieżącej mocy na końcu wykresu
    if (powerPoints.isNotEmpty) {
      final Offset lastPt = powerPoints.last;
      final double pulseRadius = 4.0 + livePulse * 3.0;
      canvas.drawCircle(
        lastPt,
        pulseRadius,
        Paint()..color = zoneColor.withValues(alpha: 0.28 * (1.0 - livePulse)),
      );
      canvas.drawCircle(
        lastPt,
        3.0,
        Paint()..color = zoneColor,
      );
    }

    // Kursor analizy (hover / scrub)
    if (hoverFraction != null && samples.isNotEmpty) {
      final int idx = (hoverFraction! * (samples.length - 1))
          .round()
          .clamp(0, samples.length - 1);
      final Offset pPt = powerPoints[idx];
      final Offset hPt = hrPoints[idx];

      final Paint guidePaint = Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.7)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(pPt.dx, padTop),
        Offset(pPt.dx, padTop + plotHeight),
        guidePaint,
      );

      canvas.drawCircle(pPt, 3.8, Paint()..color = AppColors.goldAccent);
      canvas.drawCircle(hPt, 3.2, Paint()..color = AppColors.crimsonAlert);
    }
  }

  List<Offset> _buildPoints(
    int count,
    double width,
    double height,
    double padX,
    double padTop,
    double Function(int index) normValue,
  ) {
    if (count == 1) {
      final double y = padTop + height * (1.0 - normValue(0));
      return [Offset(padX, y), Offset(padX + width, y)];
    }
    return List<Offset>.generate(count, (i) {
      final double x = padX + (i / (count - 1)) * width;
      final double y = padTop + height * (1.0 - normValue(i));
      return Offset(x, y);
    });
  }

  Path _buildSmoothPath(List<Offset> points) {
    final Path path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      return path;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = points[i];
      final Offset p1 = points[i + 1];
      final double midX = (p0.dx + p1.dx) / 2.0;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double next = math.min(distance + dashLength, metric.length);
        final Path segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, paint);
        distance = next + gapLength;
      }
    }
  }

  void _drawDashedHorizontalLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dashWidth,
    required double gapWidth,
  }) {
    double x = start.dx;
    while (x < end.dx) {
      final double nextX = math.min(x + dashWidth, end.dx);
      canvas.drawLine(Offset(x, start.dy), Offset(nextX, start.dy), paint);
      x = nextX + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant RiderTelemetrySparklinePainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.ftpWatts != ftpWatts ||
        oldDelegate.zoneColor != zoneColor ||
        oldDelegate.minHeartRateBpm != minHeartRateBpm ||
        oldDelegate.maxHeartRateBpm != maxHeartRateBpm ||
        oldDelegate.hoverFraction != hoverFraction ||
        oldDelegate.livePulse != livePulse;
  }
}
