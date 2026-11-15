import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';
import 'rider_avatar_painter.dart';

/// Modal porównania 2 lub 3 kolarzy obok siebie (Side-by-Side Comparison).
///
/// Prezentuje w estetyce iOS Dark Mode (`#0F1115` / `#181B22` / `#2A2F3D` + blur 16px):
/// 1. Nagłówek z portretami [RiderAvatarWidget], flagami, wiekiem, specjalizacją,
///    oceną OVR (w złotym okręgu `#D4AF37` dla lidera), pensją i klauzulą wykupu.
/// 2. Przełącznik jednostek `Bezwzględne (W)` / `Względne (W/kg)` z `AnimatedContainer`.
/// 3. Zintegrowany wykres nakładający krzywe mocy (`5s..60m`) z podświetleniem Δ%.
/// 4. Tabelę poziomych pasków porównawczych dla 10 parametrów fizjologicznych i technicznych.
/// 5. Pełną responsywność `LayoutBuilder` (przyklejona kolumna na `<600px`, siatka na desktopie).
class RiderComparisonSideBySideModal extends StatefulWidget {
  /// Lista 2 lub 3 kolarzy do porównania.
  final List<Rider> riders;

  /// Opcjonalna mapa drużyn (po `teamId`) do renderowania barw koszulek w awatarach.
  final Map<String, CyclingTeam>? teamsById;

  /// Domyślny tryb jednostek mocy (`false` = W, `true` = W/kg).
  final bool initialRelativeWKg;

  /// Callback zamykania modala (domyślnie `Navigator.of(context).maybePop()`).
  final VoidCallback? onClose;

  const RiderComparisonSideBySideModal({
    super.key,
    required this.riders,
    this.teamsById,
    this.initialRelativeWKg = false,
    this.onClose,
  });

  /// Otwiera [RiderComparisonSideBySideModal] jako pełnoprawny dialog z efektem blur 16px.
  static Future<void> show(
    BuildContext context, {
    required List<Rider> riders,
    Map<String, CyclingTeam>? teamsById,
    bool initialRelativeWKg = false,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Zamknij porównanie kolarzy',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1180,
                maxHeight: 880,
              ),
              child: Material(
                color: Colors.transparent,
                child: RiderComparisonSideBySideModal(
                  riders: riders,
                  teamsById: teamsById,
                  initialRelativeWKg: initialRelativeWKg,
                  onClose: () => Navigator.of(dialogContext).maybePop(),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Kolory przypisane kolejno do porównywanych kolarzy (max 3).
  static const List<Color> riderPalette = [
    Color(0xFF8E4A49), // Burgund (AppColors.primaryAccent)
    Color(0xFFD4AF37), // Złoto (AppColors.goldAccent)
    Color(0xFF3B82F6), // Błękit telemetryczny
  ];

  static const List<String> _durationLabels = [
    '5s',
    '15s',
    '30s',
    '1m',
    '3m',
    '5m',
    '20m',
    '60m',
  ];

  @override
  State<RiderComparisonSideBySideModal> createState() =>
      _RiderComparisonSideBySideModalState();
}

class _RiderComparisonSideBySideModalState
    extends State<RiderComparisonSideBySideModal> {
  late bool _useRelativeWKg;
  int? _hoveredRiderIndex;
  int? _touchedDurationIndex;
  final ScrollController _horizontalTableController = ScrollController();

  List<Rider> get _comparedRiders =>
      widget.riders.length > 3 ? widget.riders.sublist(0, 3) : widget.riders;

  @override
  void initState() {
    super.initState();
    _useRelativeWKg = widget.initialRelativeWKg;
  }

  @override
  void dispose() {
    _horizontalTableController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Color _riderColor(int index) {
    return RiderComparisonSideBySideModal
        .riderPalette[index % RiderComparisonSideBySideModal.riderPalette.length];
  }

  double _powerValueAt(Rider rider, int durationIndex) {
    final p = rider.powerProfile;
    final int watts;
    switch (durationIndex) {
      case 0:
        watts = p.watts5s;
      case 1:
        watts = p.watts15s;
      case 2:
        watts = p.watts30s;
      case 3:
        watts = p.watts1m;
      case 4:
        watts = p.watts3m;
      case 5:
        watts = p.watts5m;
      case 6:
        watts = p.watts20m;
      default:
        watts = p.watts60m;
    }
    if (!_useRelativeWKg) return watts.toDouble();
    final weight = rider.physiology.weightKg > 0 ? rider.physiology.weightKg : 70.0;
    return watts / weight;
  }

  @override
  Widget build(BuildContext context) {
    final riders = _comparedRiders;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleClose,
      },
      child: Focus(
        autofocus: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 32,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isNarrow = constraints.maxWidth < 600;
                  final double horizontalPad = isNarrow ? 12.0 : 24.0;

                  if (riders.length < 2) {
                    return _buildInsufficientRidersState(horizontalPad);
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModalTopBar(riders, isNarrow, horizontalPad),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPad,
                            isNarrow ? 14 : 20,
                            horizontalPad,
                            isNarrow ? 18 : 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRidersHeaderSection(riders, isNarrow),
                              SizedBox(height: isNarrow ? 14 : 20),
                              _buildPowerCurveCard(riders, isNarrow),
                              SizedBox(height: isNarrow ? 14 : 20),
                              _buildComparisonBarsCard(riders, isNarrow),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsufficientRidersState(double horizontalPad) {
    return Padding(
      padding: EdgeInsets.all(horizontalPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.compare_arrows_rounded,
                color: AppColors.goldAccent,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Porównanie Kolarzy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _InteractiveCloseButton(onPressed: _handleClose),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wybierz co najmniej 2 kolarzy (maksymalnie 3), aby uruchomić analizę porównawczą.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalTopBar(
    List<Rider> riders,
    bool isNarrow,
    double horizontalPad,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: isNarrow ? 12 : 16,
      ),
      color: AppColors.surface.withValues(alpha: 0.72),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTitleBadge(riders.length)),
                    const SizedBox(width: 8),
                    _InteractiveCloseButton(onPressed: _handleClose),
                  ],
                ),
                const SizedBox(height: 10),
                _UnitToggleControl(
                  useRelativeWKg: _useRelativeWKg,
                  isCompact: true,
                  onChanged: (value) => setState(() => _useRelativeWKg = value),
                ),
              ],
            )
          : Row(
              children: [
                _buildTitleBadge(riders.length),
                const Spacer(),
                _UnitToggleControl(
                  useRelativeWKg: _useRelativeWKg,
                  isCompact: false,
                  onChanged: (value) => setState(() => _useRelativeWKg = value),
                ),
                const SizedBox(width: 12),
                _InteractiveCloseButton(onPressed: _handleClose),
              ],
            ),
    );
  }

  Widget _buildTitleBadge(int riderCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.compare_arrows_rounded,
            color: AppColors.goldAccent,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Porównanie Kolarzy',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Analiza $riderCount zawodników • Side-by-Side',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRidersHeaderSection(List<Rider> riders, bool isNarrow) {
    final int maxOvr = riders.map((r) => r.overallRating).reduce(math.max);

    if (isNarrow) {
      return SizedBox(
        height: 222,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: riders.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final rider = riders[index];
            return SizedBox(
              width: 280,
              child: _RiderHeaderCard(
                rider: rider,
                team: widget.teamsById?[rider.teamId],
                accentColor: _riderColor(index),
                isOvrLeader: rider.overallRating == maxOvr,
                isHighlighted: _hoveredRiderIndex == index,
                isCompact: true,
                onHoverChanged: (hovered) {
                  setState(() => _hoveredRiderIndex = hovered ? index : null);
                },
              ),
            );
          },
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < riders.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: _RiderHeaderCard(
              rider: riders[i],
              team: widget.teamsById?[riders[i].teamId],
              accentColor: _riderColor(i),
              isOvrLeader: riders[i].overallRating == maxOvr,
              isHighlighted: _hoveredRiderIndex == i,
              isCompact: false,
              onHoverChanged: (hovered) {
                setState(() => _hoveredRiderIndex = hovered ? i : null);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPowerCurveCard(List<Rider> riders, bool isNarrow) {
    final int activeIndex = _touchedDurationIndex ?? 6; // domyślnie 20m

    // Oblicz zakres osi Y
    double maxVal = 0.0;
    double minVal = double.infinity;
    for (final r in riders) {
      for (int i = 0; i < RiderComparisonSideBySideModal._durationLabels.length; i++) {
        final v = _powerValueAt(r, i);
        if (v > maxVal) maxVal = v;
        if (v < minVal) minVal = v;
      }
    }
    final double yPadding = _useRelativeWKg ? 1.2 : 120.0;
    final double chartMaxY = ((maxVal + yPadding) / (_useRelativeWKg ? 2.0 : 200.0)).ceil() *
        (_useRelativeWKg ? 2.0 : 200.0);
    final double chartMinY = math.max(
      0.0,
      ((minVal - (_useRelativeWKg ? 1.0 : 80.0)) / (_useRelativeWKg ? 1.0 : 100.0))
              .floor() *
          (_useRelativeWKg ? 1.0 : 100.0),
    );

    // Wyznacz lidera dla wybranego / najechanego punktu czasowego
    double bestAtActive = 0.0;
    for (final r in riders) {
      final v = _powerValueAt(r, activeIndex);
      if (v > bestAtActive) bestAtActive = v;
    }

    return _GlassCard(
      padding: EdgeInsets.all(isNarrow ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Krzywa Mocy (${_useRelativeWKg ? 'W/kg' : 'W'})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Najedź lub dotknij punktu, aby sprawdzić różnicę Δ% względem lidera',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < riders.length; i++)
                    _ChartLegendChip(
                      label: riders[i].lastName,
                      color: _riderColor(i),
                      isHighlighted: _hoveredRiderIndex == i,
                      onHover: (hovered) {
                        setState(() => _hoveredRiderIndex = hovered ? i : null);
                      },
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isNarrow ? 220 : 270,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 7,
                minY: chartMinY,
                maxY: chartMaxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval:
                      _useRelativeWKg ? math.max(2.0, (chartMaxY - chartMinY) / 5) : math.max(200.0, (chartMaxY - chartMinY) / 5),
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.borderColor.withValues(alpha: 0.55),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (x) => FlLine(
                    color: x.toInt() == _touchedDurationIndex
                        ? AppColors.goldAccent.withValues(alpha: 0.45)
                        : AppTheme.borderColor.withValues(alpha: 0.35),
                    strokeWidth: x.toInt() == _touchedDurationIndex ? 1.5 : 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppTheme.borderColor.withValues(alpha: 0.8),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round();
                        if (idx < 0 ||
                            idx >= RiderComparisonSideBySideModal._durationLabels.length ||
                            (value - idx).abs() > 0.05) {
                          return const SizedBox.shrink();
                        }
                        final isSelected = _touchedDurationIndex == idx;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            RiderComparisonSideBySideModal._durationLabels[idx],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _useRelativeWKg ? 44 : 50,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        final String label = _useRelativeWKg
                            ? value.toStringAsFixed(1)
                            : value.round().toString();
                        return Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback: (event, response) {
                    if (event is FlPanEndEvent ||
                        event is FlTapUpEvent ||
                        event is FlPointerExitEvent) {
                      return;
                    }
                    final spots = response?.lineBarSpots;
                    if (spots != null && spots.isNotEmpty) {
                      final idx = spots.first.x.round().clamp(0, 7);
                      if (_touchedDurationIndex != idx) {
                        setState(() => _touchedDurationIndex = idx);
                      }
                    }
                  },
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: (barData.color ?? AppColors.goldAccent)
                              .withValues(alpha: 0.6),
                          strokeWidth: 1.5,
                          dashArray: [3, 3],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, idx) {
                            return FlDotCirclePainter(
                              radius: 5.5,
                              color: bar.color ?? AppColors.goldAccent,
                              strokeWidth: 2,
                              strokeColor: AppColors.background,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipColor: (_) =>
                        AppColors.surfaceLight.withValues(alpha: 0.96),
                    getTooltipItems: (touchedSpots) {
                      if (touchedSpots.isEmpty) return [];
                      final int xIdx = touchedSpots.first.x.round().clamp(0, 7);
                      final String durLabel =
                          RiderComparisonSideBySideModal._durationLabels[xIdx];

                      double maxAtSpot = 0.0;
                      for (final r in riders) {
                        final v = _powerValueAt(r, xIdx);
                        if (v > maxAtSpot) maxAtSpot = v;
                      }

                      return touchedSpots.asMap().entries.map((entry) {
                        final spot = entry.value;
                        final int riderIdx = spot.barIndex.clamp(0, riders.length - 1);
                        final rider = riders[riderIdx];
                        final double val = spot.y;
                        final double deltaPct = maxAtSpot > 0
                            ? ((val - maxAtSpot) / maxAtSpot) * 100.0
                            : 0.0;
                        final bool isLeader = deltaPct.abs() < 0.05;
                        final String valStr = _useRelativeWKg
                            ? '${val.toStringAsFixed(2)} W/kg'
                            : '${val.round()} W';
                        final String deltaStr = isLeader
                            ? 'Lider (0.0%)'
                            : 'Δ ${deltaPct.toStringAsFixed(1)}%';
                        final String prefix = entry.key == 0 ? '$durLabel\n' : '';

                        return LineTooltipItem(
                          '$prefix${rider.lastName}: $valStr • $deltaStr',
                          TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isLeader
                                ? AppColors.statusSuccess
                                : _riderColor(riderIdx),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  for (int i = 0; i < riders.length; i++)
                    LineChartBarData(
                      spots: [
                        for (int d = 0;
                            d < RiderComparisonSideBySideModal._durationLabels.length;
                            d++)
                          FlSpot(d.toDouble(), _powerValueAt(riders[i], d)),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.24,
                      color: _riderColor(i),
                      barWidth: _hoveredRiderIndex == null || _hoveredRiderIndex == i
                          ? 2.8
                          : 1.6,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final bool isActive = index == _touchedDurationIndex;
                          return FlDotCirclePainter(
                            radius: isActive ? 4.5 : 3.0,
                            color: _riderColor(i),
                            strokeWidth: 1.5,
                            strokeColor: AppColors.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: _hoveredRiderIndex == i,
                        color: _riderColor(i).withValues(alpha: 0.12),
                      ),
                    ),
                ],
              ),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeltaSummaryStrip(riders, activeIndex, bestAtActive),
        ],
      ),
    );
  }

  Widget _buildDeltaSummaryStrip(
    List<Rider> riders,
    int durationIndex,
    double bestValue,
  ) {
    final String durLabel =
        RiderComparisonSideBySideModal._durationLabels[durationIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Punkt $durLabel:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          for (int i = 0; i < riders.length; i++)
            Builder(
              builder: (context) {
                final val = _powerValueAt(riders[i], durationIndex);
                final deltaPct =
                    bestValue > 0 ? ((val - bestValue) / bestValue) * 100.0 : 0.0;
                final isBest = deltaPct.abs() < 0.05;
                final valStr = _useRelativeWKg
                    ? '${val.toStringAsFixed(2)} W/kg'
                    : '${val.round()} W';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _riderColor(i),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${riders[i].lastName}: $valStr ',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isBest
                                ? AppColors.statusSuccess
                                : AppColors.textSecondary)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isBest ? 'LIDER' : '${deltaPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isBest
                              ? AppColors.statusSuccess
                              : AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  List<_ComparisonMetricRow> _buildMetrics(List<Rider> riders) {
    return [
      _ComparisonMetricRow(
        label: _useRelativeWKg ? 'FTP (W/kg)' : 'FTP (W)',
        subtitle: 'Próg mleczanowy',
        maxScale: _useRelativeWKg ? 7.2 : 520.0,
        values: riders
            .map((r) => _useRelativeWKg
                ? r.physiology.wattsPerKg
                : r.physiology.ftpWatts.toDouble())
            .toList(),
        formatValue: (v) => _useRelativeWKg
            ? '${v.toStringAsFixed(2)} W/kg'
            : '${v.round()} W',
        formatAdvantage: (diff) => _useRelativeWKg
            ? '+${diff.toStringAsFixed(2)}'
            : '+${diff.round()} W',
      ),
      _ComparisonMetricRow(
        label: "W' (Beztlenowe)",
        subtitle: 'Pojemność [kJ]',
        maxScale: 36.0,
        values:
            riders.map((r) => r.physiology.wPrimeJoules / 1000.0).toList(),
        formatValue: (v) => '${v.toStringAsFixed(1)} kJ',
        formatAdvantage: (diff) => '+${diff.toStringAsFixed(1)}',
      ),
      _ComparisonMetricRow(
        label: 'VO₂max',
        subtitle: 'Pułap tlenowy',
        maxScale: 96.0,
        values: riders.map((r) => r.physiology.vo2Max).toList(),
        formatValue: (v) => '${v.toStringAsFixed(1)} ml/kg',
        formatAdvantage: (diff) => '+${diff.toStringAsFixed(1)}',
      ),
      _ComparisonMetricRow(
        label: 'VLaMax',
        subtitle: 'Glikoliza [mmol/l/s]',
        maxScale: 1.0,
        values:
            riders.map((r) => r.labProfile.vlaMaxMmolLPerSec).toList(),
        formatValue: (v) => '${v.toStringAsFixed(2)} mmol',
        formatAdvantage: (diff) => '+${diff.toStringAsFixed(2)}',
      ),
      _ComparisonMetricRow(
        label: 'Cobbles',
        subtitle: 'Jazda po bruku',
        maxScale: 100.0,
        values: riders.map((r) => r.skills.cobbles.toDouble()).toList(),
        formatValue: (v) => '${v.round()}',
        formatAdvantage: (diff) => '+${diff.round()}',
      ),
      _ComparisonMetricRow(
        label: 'Descending',
        subtitle: 'Technika zjazdów',
        maxScale: 100.0,
        values: riders.map((r) => r.skills.descending.toDouble()).toList(),
        formatValue: (v) => '${v.round()}',
        formatAdvantage: (diff) => '+${diff.round()}',
      ),
      _ComparisonMetricRow(
        label: 'Bike Handling',
        subtitle: 'Panowanie nad rowerem',
        maxScale: 100.0,
        values: riders.map((r) => r.skills.bikeHandling.toDouble()).toList(),
        formatValue: (v) => '${v.round()}',
        formatAdvantage: (diff) => '+${diff.round()}',
      ),
      _ComparisonMetricRow(
        label: 'Aero Positioning',
        subtitle: 'Pozycja aero',
        maxScale: 100.0,
        values:
            riders.map((r) => r.skills.aeroPositioning.toDouble()).toList(),
        formatValue: (v) => '${v.round()}',
        formatAdvantage: (diff) => '+${diff.round()}',
      ),
      _ComparisonMetricRow(
        label: 'Drafting Efficiency',
        subtitle: 'Oszczędność w peletonie',
        maxScale: 100.0,
        values:
            riders.map((r) => r.skills.draftingEfficiency.toDouble()).toList(),
        formatValue: (v) => '${v.round()}',
        formatAdvantage: (diff) => '+${diff.round()}',
      ),
      _ComparisonMetricRow(
        label: 'Recovery Rate',
        subtitle: 'Regeneracja',
        maxScale: 100.0,
        values: riders.map((r) => r.physiology.recoveryRate).toList(),
        formatValue: (v) => v.toStringAsFixed(1),
        formatAdvantage: (diff) => '+${diff.toStringAsFixed(1)}',
      ),
    ];
  }

  Widget _buildComparisonBarsCard(List<Rider> riders, bool isNarrow) {
    final metrics = _buildMetrics(riders);

    return _GlassCard(
      padding: EdgeInsets.all(isNarrow ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fizjologia i Umiejętności Techniczne',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Najwyższa wartość w wierszu podświetlona zielonym akcentem #10B981',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNarrow)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Przewijaj',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isNarrow)
            _buildStickyNarrowTable(riders, metrics)
          else
            _buildDesktopGridTable(riders, metrics),
        ],
      ),
    );
  }

  /// Układ dla ekranów < 600px: przyklejona lewa kolumna nazw statystyk + poziomy scroll dla kolumn kolarzy.
  Widget _buildStickyNarrowTable(
    List<Rider> riders,
    List<_ComparisonMetricRow> metrics,
  ) {
    const double stickyColWidth = 128.0;
    const double riderColWidth = 148.0;
    const double rowHeight = 58.0;
    const double headerHeight = 34.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Przyklejona kolumna nazw parametrów
        SizedBox(
          width: stickyColWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: headerHeight,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: const Text(
                  'PARAMETR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              for (int m = 0; m < metrics.length; m++)
                Container(
                  height: rowHeight,
                  padding: const EdgeInsets.only(right: 8),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: m.isEven
                        ? Colors.transparent
                        : AppColors.surfaceLight.withValues(alpha: 0.24),
                    border: const Border(
                      bottom: BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metrics[m].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        metrics[m].subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Poziomo przewijane kolumny kolarzy
        Expanded(
          child: Scrollbar(
            controller: _horizontalTableController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalTableController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: riderColWidth * riders.length,
                child: Column(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: Row(
                        children: [
                          for (int i = 0; i < riders.length; i++)
                            Container(
                              width: riderColWidth,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.centerLeft,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom:
                                      BorderSide(color: AppTheme.borderColor),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _riderColor(i),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      riders[i].lastName.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (int m = 0; m < metrics.length; m++)
                      Container(
                        height: rowHeight,
                        decoration: BoxDecoration(
                          color: m.isEven
                              ? Colors.transparent
                              : AppColors.surfaceLight.withValues(alpha: 0.24),
                          border: const Border(
                            bottom: BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: Row(
                          children: _buildMetricCells(
                            metrics[m],
                            riders.length,
                            cellWidth: riderColWidth,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Pełna siatka wielokolumnowa dla ekranów >= 600px (tablet / desktop).
  Widget _buildDesktopGridTable(
    List<Rider> riders,
    List<_ComparisonMetricRow> metrics,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 176,
                child: Text(
                  'PARAMETR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              for (int i = 0; i < riders.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: _riderColor(i),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            riders[i].fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (int m = 0; m < metrics.length; m++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: m.isEven
                  ? Colors.transparent
                  : AppColors.surfaceLight.withValues(alpha: 0.24),
              border: const Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 176,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metrics[m].label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          metrics[m].subtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final cell in _buildMetricCells(metrics[m], riders.length))
                  Expanded(child: cell),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildMetricCells(
    _ComparisonMetricRow metric,
    int riderCount, {
    double? cellWidth,
  }) {
    final values = metric.values;
    final double maxVal = values.reduce(math.max);
    final List<double> sortedDesc = List<double>.from(values)
      ..sort((a, b) => b.compareTo(a));
    final double secondVal = sortedDesc.length > 1 ? sortedDesc[1] : maxVal;
    final double advantage = maxVal - secondVal;
    final int maxCount = values.where((v) => (v - maxVal).abs() < 1e-6).length;

    return [
      for (int i = 0; i < riderCount; i++)
        Builder(
          builder: (context) {
            final double val = values[i];
            final bool isHighest = (val - maxVal).abs() < 1e-6;
            final bool isUniqueLeader = isHighest && maxCount == 1 && advantage > 1e-4;
            final double ratio = (val / metric.maxScale).clamp(0.04, 1.0);
            final Color barColor =
                isHighest ? AppColors.statusSuccess : _riderColor(i);

            final Widget cellContent = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          metric.formatValue(val),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight:
                                isHighest ? FontWeight.w700 : FontWeight.w500,
                            color: isHighest
                                ? AppColors.statusSuccess
                                : AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (isUniqueLeader)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.statusSuccess.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.statusSuccess
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_upward_rounded,
                                size: 10,
                                color: AppColors.statusSuccess,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                metric.formatAdvantage(advantage),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.statusSuccess,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 7,
                      color: AppColors.surfaceLight,
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: ratio),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedRatio, _) {
                          return FractionallySizedBox(
                            widthFactor: animatedRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isHighest
                                    ? [
                                        BoxShadow(
                                          color: AppColors.statusSuccess
                                              .withValues(alpha: 0.35),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (cellWidth != null) {
              return SizedBox(width: cellWidth, child: cellContent);
            }
            return cellContent;
          },
        ),
    ];
  }
}

class _ComparisonMetricRow {
  final String label;
  final String subtitle;
  final double maxScale;
  final List<double> values;
  final String Function(double) formatValue;
  final String Function(double) formatAdvantage;

  const _ComparisonMetricRow({
    required this.label,
    required this.subtitle,
    required this.maxScale,
    required this.values,
    required this.formatValue,
    required this.formatAdvantage,
  });
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

class _RiderHeaderCard extends StatefulWidget {
  final Rider rider;
  final CyclingTeam? team;
  final Color accentColor;
  final bool isOvrLeader;
  final bool isHighlighted;
  final bool isCompact;
  final ValueChanged<bool> onHoverChanged;

  const _RiderHeaderCard({
    required this.rider,
    required this.team,
    required this.accentColor,
    required this.isOvrLeader,
    required this.isHighlighted,
    required this.isCompact,
    required this.onHoverChanged,
  });

  @override
  State<_RiderHeaderCard> createState() => _RiderHeaderCardState();
}

class _RiderHeaderCardState extends State<_RiderHeaderCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    final bool activeHighlight =
        _isHovered || _isFocused || widget.isHighlighted;
    final Color borderColor = activeHighlight
        ? widget.accentColor
        : (widget.isOvrLeader
            ? AppColors.goldAccent.withValues(alpha: 0.45)
            : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) {
        setState(() => _isHovered = hovered);
        widget.onHoverChanged(hovered);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: activeHighlight
              ? AppColors.surfaceLight.withValues(alpha: 0.85)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: activeHighlight ? 1.5 : 1.0,
          ),
          boxShadow: activeHighlight
              ? [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RiderAvatarWidget.fromRider(
                  rider: rider,
                  team: widget.team,
                  size: widget.isCompact ? 50 : 60,
                  borderColor: widget.accentColor,
                  borderWidth: 2.0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rider.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _NationalityFlagBadge(iso: rider.nationalityIso),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${rider.age} lat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rider.specialization.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _OvrCircleBadge(
                  ovr: rider.overallRating,
                  isLeader: widget.isOvrLeader,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borderColor),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ContractMetricChip(
                    label: 'Pensja / rok',
                    value: Formatters.formatCompactCurrency(
                      rider.contract.annualSalaryEur,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ContractMetricChip(
                    label: 'Klauzula',
                    value: Formatters.formatCompactCurrency(
                      rider.contract.releaseClauseEur,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OvrCircleBadge extends StatelessWidget {
  final int ovr;
  final bool isLeader;

  const _OvrCircleBadge({
    required this.ovr,
    required this.isLeader,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLeader
            ? AppColors.goldAccent.withValues(alpha: 0.16)
            : AppColors.surfaceLight,
        border: Border.all(
          color: isLeader ? AppColors.goldAccent : AppTheme.borderColor,
          width: isLeader ? 2.0 : 1.0,
        ),
        boxShadow: isLeader
            ? [
                BoxShadow(
                  color: AppColors.goldAccent.withValues(alpha: 0.28),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$ovr',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: isLeader ? AppColors.goldAccent : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'OVR',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color:
                  isLeader ? AppColors.goldAccent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _ContractMetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitToggleControl extends StatefulWidget {
  final bool useRelativeWKg;
  final bool isCompact;
  final ValueChanged<bool>? onChanged;

  const _UnitToggleControl({
    required this.useRelativeWKg,
    required this.isCompact,
    required this.onChanged,
  });

  @override
  State<_UnitToggleControl> createState() => _UnitToggleControlState();
}

class _UnitToggleControlState extends State<_UnitToggleControl> {
  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onChanged == null;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: widget.isCompact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (widget.isCompact)
            Expanded(
              child: _UnitPillButton(
                label: 'Bezwzględne (W)',
                isSelected: !widget.useRelativeWKg,
                isDisabled: isDisabled,
                onTap: () => widget.onChanged?.call(false),
              ),
            )
          else
            _UnitPillButton(
              label: 'Bezwzględne (W)',
              isSelected: !widget.useRelativeWKg,
              isDisabled: isDisabled,
              onTap: () => widget.onChanged?.call(false),
            ),
          const SizedBox(width: 4),
          if (widget.isCompact)
            Expanded(
              child: _UnitPillButton(
                label: 'Względne (W/kg)',
                isSelected: widget.useRelativeWKg,
                isDisabled: isDisabled,
                onTap: () => widget.onChanged?.call(true),
              ),
            )
          else
            _UnitPillButton(
              label: 'Względne (W/kg)',
              isSelected: widget.useRelativeWKg,
              isDisabled: isDisabled,
              onTap: () => widget.onChanged?.call(true),
            ),
        ],
      ),
    );
  }
}

class _UnitPillButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _UnitPillButton({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_UnitPillButton> createState() => _UnitPillButtonState();
}

class _UnitPillButtonState extends State<_UnitPillButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (widget.isDisabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.3);
    } else if (widget.isSelected) {
      bgColor = _isPressed
          ? AppColors.primaryAccent.withValues(alpha: 0.85)
          : AppColors.primaryAccent;
    } else if (_isPressed) {
      bgColor = AppColors.surfaceLight;
    } else if (_isHovered) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.65);
    } else {
      bgColor = Colors.transparent;
    }

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:
            widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp:
            widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            widget.isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _isFocused
                  ? AppColors.goldAccent
                  : (widget.isSelected
                      ? AppColors.primaryAccent.withValues(alpha: 0.9)
                      : Colors.transparent),
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isDisabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : (widget.isSelected
                      ? Colors.white
                      : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveCloseButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _InteractiveCloseButton({required this.onPressed});

  @override
  State<_InteractiveCloseButton> createState() =>
      _InteractiveCloseButtonState();
}

class _InteractiveCloseButtonState extends State<_InteractiveCloseButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    final Color bg = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.25)
        : (_isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.3)
            : (_isHovered ? AppColors.surfaceLight : AppColors.background));

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      mouseCursor:
          isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown:
            isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp:
            isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: isDisabled
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : (_isHovered
                    ? AppColors.textPrimary
                    : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ChartLegendChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool isHighlighted;
  final ValueChanged<bool> onHover;

  const _ChartLegendChip({
    required this.label,
    required this.color,
    required this.isHighlighted,
    required this.onHover,
  });

  @override
  State<_ChartLegendChip> createState() => _ChartLegendChipState();
}

class _ChartLegendChipState extends State<_ChartLegendChip> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? widget.color.withValues(alpha: 0.2)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isHighlighted ? widget.color : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NationalityFlagBadge extends StatelessWidget {
  final String iso;

  const _NationalityFlagBadge({required this.iso});

  static const Map<String, String> _iso3ToIso2 = {
    'POL': 'PL',
    'BEL': 'BE',
    'SLO': 'SI',
    'DEN': 'DK',
    'NED': 'NL',
    'FRA': 'FR',
    'ITA': 'IT',
    'ESP': 'ES',
    'GBR': 'GB',
    'USA': 'US',
    'COL': 'CO',
    'AUS': 'AU',
    'GER': 'DE',
    'SUI': 'CH',
    'NOR': 'NO',
    'POR': 'PT',
    'IRL': 'IE',
    'NZL': 'NZ',
    'CAN': 'CA',
    'SVK': 'SK',
    'CZE': 'CZ',
    'AUT': 'AT',
    'ECU': 'EC',
    'RSA': 'ZA',
    'KAZ': 'KZ',
    'ERI': 'ER',
    'LAT': 'LV',
    'EST': 'EE',
    'LUX': 'LU',
    'JPN': 'JP',
  };

  String _flagEmoji(String rawIso) {
    final upper = rawIso.trim().toUpperCase();
    final iso2 = upper.length == 3 ? (_iso3ToIso2[upper] ?? upper.substring(0, 2)) : upper;
    if (iso2.length != 2) return '🏳️';
    final int first = iso2.codeUnitAt(0);
    final int second = iso2.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) return '🏳️';
    return String.fromCharCode(0x1F1E6 + (first - 65)) +
        String.fromCharCode(0x1F1E6 + (second - 65));
  }

  @override
  Widget build(BuildContext context) {
    final code = iso.trim().toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _flagEmoji(code),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            code,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
