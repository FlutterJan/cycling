import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/finance_and_budget_service.dart';

/// Pojedynczy miesięczny punkt danych 12-miesięcznej prognozy przepływów pieniężnych drużyny.
class MonthlyCashflowProjectionPoint {
  final int monthIndex; // 1..12
  final String monthLabel;
  final double sponsorTrancheEur;
  final double otherIncomeEur;
  final double salariesExpenseEur;
  final double trainingCampsExpenseEur;
  final double logisticsAndOtherExpenseEur;
  final double projectedEndingBalanceEur;

  const MonthlyCashflowProjectionPoint({
    required this.monthIndex,
    required this.monthLabel,
    required this.sponsorTrancheEur,
    this.otherIncomeEur = 0.0,
    required this.salariesExpenseEur,
    required this.trainingCampsExpenseEur,
    this.logisticsAndOtherExpenseEur = 0.0,
    required this.projectedEndingBalanceEur,
  });

  double get totalInflowEur => math.max(0.0, sponsorTrancheEur) + math.max(0.0, otherIncomeEur);

  double get totalOutflowEur =>
      math.max(0.0, salariesExpenseEur) +
      math.max(0.0, trainingCampsExpenseEur) +
      math.max(0.0, logisticsAndOtherExpenseEur);

  double get netCashflowEur => totalInflowEur - totalOutflowEur;

  bool get isDeficit => projectedEndingBalanceEur < 0.0;

  /// Konwertuje raport z [FinanceAndBudgetService] na punkt prognozy wykresu.
  factory MonthlyCashflowProjectionPoint.fromMonthlyReport(
    MonthlyCashflowReport report, {
    String? monthLabel,
  }) {
    final int month = report.period.month.clamp(1, 12);
    return MonthlyCashflowProjectionPoint(
      monthIndex: month,
      monthLabel: monthLabel ?? TeamCashflowProjectionCalculator.defaultMonthLabel(month),
      sponsorTrancheEur: report.sponsorPayoutEur.toDouble(),
      otherIncomeEur: (report.bikeManufacturerCashEur +
              report.prizeMoneyClubShareEur +
              report.riderBuyoutIncomeEur +
              report.otherIncomeEur)
          .toDouble(),
      salariesExpenseEur: (report.riderSalariesEur + report.staffSalariesEur).toDouble(),
      trainingCampsExpenseEur: report.trainingCampsEur.toDouble(),
      logisticsAndOtherExpenseEur: (report.raceLogisticsEur +
              report.physiologicalTestingEur +
              report.equipmentServiceAndPurchasesEur +
              report.facilitiesMaintenanceEur)
          .toDouble(),
      projectedEndingBalanceEur: report.endingBalanceEur.toDouble(),
    );
  }
}

/// Podsumowanie 12-miesięcznej prognozy budżetowej drużyny na koniec sezonu.
class TeamCashflowProjectionSummary {
  final double startingBalanceEur;
  final double endOfSeasonBalanceEur;
  final double lowestProjectedBalanceEur;
  final int? firstDeficitMonthIndex;
  final String? firstDeficitMonthLabel;
  final double totalSponsorTranchesEur;
  final double totalSalariesEur;
  final double totalCampsEur;
  final double totalOtherExpensesEur;

  const TeamCashflowProjectionSummary({
    required this.startingBalanceEur,
    required this.endOfSeasonBalanceEur,
    required this.lowestProjectedBalanceEur,
    required this.firstDeficitMonthIndex,
    required this.firstDeficitMonthLabel,
    required this.totalSponsorTranchesEur,
    required this.totalSalariesEur,
    required this.totalCampsEur,
    required this.totalOtherExpensesEur,
  });

  bool get hasDeficitWarning => lowestProjectedBalanceEur < 0.0 || endOfSeasonBalanceEur < 0.0;

  bool get isEndOfSeasonDeficit => endOfSeasonBalanceEur < 0.0;

  double get netSeasonDeltaEur => endOfSeasonBalanceEur - startingBalanceEur;
}

/// Kalkulator i narzędzia pomocnicze dla 12-miesięcznej prognozy przepływów drużyny.
class TeamCashflowProjectionCalculator {
  TeamCashflowProjectionCalculator._();

  static const List<String> _polishMonthAbbreviations = [
    'STY',
    'LUT',
    'MAR',
    'KWI',
    'MAJ',
    'CZE',
    'LIP',
    'SIE',
    'WRZ',
    'PAŹ',
    'LIS',
    'GRU',
  ];

  static String defaultMonthLabel(int monthIndex) {
    final idx = (monthIndex - 1).clamp(0, 11);
    return _polishMonthAbbreviations[idx];
  }

  /// Oblicza narastająco prognozowane saldo na koniec każdego z 12 miesięcy
  /// na podstawie salda początkowego oraz miesięcznych transz i wydatków.
  static List<MonthlyCashflowProjectionPoint> buildProjectedSeries({
    required double startingBalanceEur,
    required List<MonthlyCashflowProjectionPoint> monthlyInputs,
  }) {
    if (monthlyInputs.isEmpty) return const [];
    final List<MonthlyCashflowProjectionPoint> result = [];
    double runningBalance = startingBalanceEur;

    for (int i = 0; i < monthlyInputs.length && i < 12; i++) {
      final item = monthlyInputs[i];
      runningBalance += item.netCashflowEur;
      result.add(
        MonthlyCashflowProjectionPoint(
          monthIndex: item.monthIndex,
          monthLabel: item.monthLabel,
          sponsorTrancheEur: item.sponsorTrancheEur,
          otherIncomeEur: item.otherIncomeEur,
          salariesExpenseEur: item.salariesExpenseEur,
          trainingCampsExpenseEur: item.trainingCampsExpenseEur,
          logisticsAndOtherExpenseEur: item.logisticsAndOtherExpenseEur,
          projectedEndingBalanceEur: runningBalance,
        ),
      );
    }
    return result;
  }

  /// Wylicza zagregowane metryki sezonu i identyfikuje najwcześniejszy deficyt.
  static TeamCashflowProjectionSummary summarize({
    required double startingBalanceEur,
    required List<MonthlyCashflowProjectionPoint> months,
  }) {
    if (months.isEmpty) {
      return TeamCashflowProjectionSummary(
        startingBalanceEur: startingBalanceEur,
        endOfSeasonBalanceEur: startingBalanceEur,
        lowestProjectedBalanceEur: startingBalanceEur,
        firstDeficitMonthIndex: startingBalanceEur < 0 ? 1 : null,
        firstDeficitMonthLabel: startingBalanceEur < 0 ? defaultMonthLabel(1) : null,
        totalSponsorTranchesEur: 0.0,
        totalSalariesEur: 0.0,
        totalCampsEur: 0.0,
        totalOtherExpensesEur: 0.0,
      );
    }

    double lowestBalance = months.first.projectedEndingBalanceEur;
    int? firstDeficitMonthIndex;
    String? firstDeficitMonthLabel;
    double totalSponsors = 0.0;
    double totalSalaries = 0.0;
    double totalCamps = 0.0;
    double totalOther = 0.0;

    for (final point in months) {
      totalSponsors += math.max(0.0, point.sponsorTrancheEur);
      totalSalaries += math.max(0.0, point.salariesExpenseEur);
      totalCamps += math.max(0.0, point.trainingCampsExpenseEur);
      totalOther += math.max(0.0, point.logisticsAndOtherExpenseEur);

      if (point.projectedEndingBalanceEur < lowestBalance) {
        lowestBalance = point.projectedEndingBalanceEur;
      }
      if (point.projectedEndingBalanceEur < 0.0 && firstDeficitMonthIndex == null) {
        firstDeficitMonthIndex = point.monthIndex;
        firstDeficitMonthLabel = point.monthLabel;
      }
    }

    return TeamCashflowProjectionSummary(
      startingBalanceEur: startingBalanceEur,
      endOfSeasonBalanceEur: months.last.projectedEndingBalanceEur,
      lowestProjectedBalanceEur: lowestBalance,
      firstDeficitMonthIndex: firstDeficitMonthIndex,
      firstDeficitMonthLabel: firstDeficitMonthLabel,
      totalSponsorTranchesEur: totalSponsors,
      totalSalariesEur: totalSalaries,
      totalCampsEur: totalCamps,
      totalOtherExpensesEur: totalOther,
    );
  }
}

/// 12-miesięczny wykres przepływów pieniężnych drużyny kolarskiej.
///
/// Prezentuje:
/// - comiesięczne transze od sponsorów (wpływy),
/// - wypłaty pensji (kolarze + sztab),
/// - koszty obozów treningowych i logistyki,
/// - linię prognozowanego salda z końcową wartością na koniec sezonu,
/// - wyraźny alert o deficycie budżetowym wraz z miesiącem jego wystąpienia.
class TeamBudgetCashflowProjectionChart extends StatefulWidget {
  final List<MonthlyCashflowProjectionPoint> months;
  final double startingBalanceEur;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<MonthlyCashflowProjectionPoint>? onMonthSelected;
  final VoidCallback? onDeficitActionPressed;
  final String deficitActionLabel;

  const TeamBudgetCashflowProjectionChart({
    super.key,
    required this.months,
    this.startingBalanceEur = 0.0,
    this.title = 'PROGNOZA PRZEPŁYWÓW PIENIĘŻNYCH (12 MIES.)',
    this.subtitle = 'Transze sponsorskie, pensje, obozy treningowe oraz prognozowane saldo sezonu',
    this.enabled = true,
    this.onMonthSelected,
    this.onDeficitActionPressed,
    this.deficitActionLabel = 'Przegląd cięć kosztów',
  });

  @override
  State<TeamBudgetCashflowProjectionChart> createState() =>
      _TeamBudgetCashflowProjectionChartState();
}

class _TeamBudgetCashflowProjectionChartState extends State<TeamBudgetCashflowProjectionChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _revealAnimation;

  final FocusNode _chartFocusNode = FocusNode(debugLabel: 'cashflow_chart_focus');

  int? _hoveredIndex;
  int? _selectedIndex;
  bool _isChartFocused = false;

  bool _showSponsors = true;
  bool _showSalaries = true;
  bool _showCamps = true;
  bool _showBalanceLine = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _revealAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant TeamBudgetCashflowProjectionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.months != widget.months ||
        oldWidget.startingBalanceEur != widget.startingBalanceEur) {
      _animationController.forward(from: 0.0);
      if (_selectedIndex != null && _selectedIndex! >= widget.months.length) {
        _selectedIndex = widget.months.isEmpty ? null : widget.months.length - 1;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartFocusNode.dispose();
    super.dispose();
  }

  int? get _activeIndex => _hoveredIndex ?? _selectedIndex;

  void _selectMonthIndex(int index) {
    if (!widget.enabled || index < 0 || index >= widget.months.length) return;
    setState(() {
      _selectedIndex = index;
    });
    widget.onMonthSelected?.call(widget.months[index]);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || widget.months.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final int current = _activeIndex ?? 0;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _selectMonthIndex((current + 1).clamp(0, widget.months.length - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _selectMonthIndex((current - 1).clamp(0, widget.months.length - 1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final List<MonthlyCashflowProjectionPoint> visibleMonths =
        widget.months.length > 12 ? widget.months.sublist(0, 12) : widget.months;
    final TeamCashflowProjectionSummary summary = TeamCashflowProjectionCalculator.summarize(
      startingBalanceEur: widget.startingBalanceEur,
      months: visibleMonths,
    );

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.55,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth.isFinite ? constraints.maxWidth : 1024.0;
          final bool isCompact = width < 620.0;
          final bool isMedium = width >= 620.0 && width < 960.0;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isChartFocused
                    ? AppColors.goldAccent
                    : (summary.hasDeficitWarning
                        ? AppColors.crimsonAlert.withValues(alpha: 0.55)
                        : AppColors.cardBorder),
                width: _isChartFocused ? 1.5 : 1.0,
              ),
            ),
            padding: EdgeInsets.all(isCompact ? 14.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(summary, isCompact),
                const SizedBox(height: 12),
                if (summary.hasDeficitWarning) ...[
                  _buildDeficitWarningBanner(summary, isCompact),
                  const SizedBox(height: 14),
                ],
                _buildLegendControls(isCompact),
                const SizedBox(height: 14),
                if (visibleMonths.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildInteractiveChartArea(
                    months: visibleMonths,
                    isCompact: isCompact,
                    isMedium: isMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildActiveMonthInspector(
                    months: visibleMonths,
                    summary: summary,
                    isCompact: isCompact,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(TeamCashflowProjectionSummary summary, bool isCompact) {
    final Color balanceColor = summary.isEndOfSeasonDeficit
        ? AppColors.crimsonAlert
        : (summary.hasDeficitWarning ? AppColors.amberWarning : AppColors.statusSuccess);

    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: summary.hasDeficitWarning ? AppColors.crimsonAlert : AppColors.goldAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 11.5 : 12.5,
            color: AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    final Widget seasonEndKpi = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: balanceColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PROGNOZOWANE SALDO KOŃCOWE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.formatCurrency(summary.endOfSeasonBalanceEur),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: balanceColor,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          seasonEndKpi,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        seasonEndKpi,
      ],
    );
  }

  Widget _buildDeficitWarningBanner(TeamCashflowProjectionSummary summary, bool isCompact) {
    final String monthText = summary.firstDeficitMonthLabel ?? 'w trakcie sezonu';
    final String lowestText = Formatters.formatCurrency(summary.lowestProjectedBalanceEur);
    final String endText = Formatters.formatCurrency(summary.endOfSeasonBalanceEur);

    final String message = summary.isEndOfSeasonDeficit
        ? 'Ostrzeżenie o deficycie: pierwszy ujemny bilans wystąpi w $monthText '
            '(minimum $lowestText), a prognozowane saldo na koniec sezonu wynosi $endText.'
        : 'Ostrzeżenie o przejściowym deficycie: płynność spadnie poniżej zera w $monthText '
            '(minimum $lowestText), zanim transze sponsorskie przywrócą saldo końcowe ($endText).';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.crimsonAlert,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.onDeficitActionPressed != null) ...[
                  const SizedBox(height: 8),
                  _DeficitActionButton(
                    label: widget.deficitActionLabel,
                    enabled: widget.enabled,
                    onPressed: widget.onDeficitActionPressed!,
                  ),
                ],
              ],
            )
          : Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.crimsonAlert,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                if (widget.onDeficitActionPressed != null) ...[
                  const SizedBox(width: 12),
                  _DeficitActionButton(
                    label: widget.deficitActionLabel,
                    enabled: widget.enabled,
                    onPressed: widget.onDeficitActionPressed!,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildLegendControls(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SeriesToggleChip(
          label: 'Transze sponsorów',
          color: AppColors.statusSuccess,
          selected: _showSponsors,
          enabled: widget.enabled,
          onTap: () => setState(() => _showSponsors = !_showSponsors),
        ),
        _SeriesToggleChip(
          label: 'Wypłaty pensji',
          color: AppColors.primaryAccent,
          selected: _showSalaries,
          enabled: widget.enabled,
          onTap: () => setState(() => _showSalaries = !_showSalaries),
        ),
        _SeriesToggleChip(
          label: 'Koszty obozów',
          color: AppColors.amberWarning,
          selected: _showCamps,
          enabled: widget.enabled,
          onTap: () => setState(() => _showCamps = !_showCamps),
        ),
        _SeriesToggleChip(
          label: 'Prognozowane saldo',
          color: AppColors.goldAccent,
          selected: _showBalanceLine,
          enabled: widget.enabled,
          isLineIndicator: true,
          onTap: () => setState(() => _showBalanceLine = !_showBalanceLine),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Brak danych prognozy przepływów pieniężnych.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveChartArea({
    required List<MonthlyCashflowProjectionPoint> months,
    required bool isCompact,
    required bool isMedium,
  }) {
    final double chartHeight = isCompact ? 230 : (isMedium ? 260 : 290);

    return Focus(
      focusNode: _chartFocusNode,
      canRequestFocus: widget.enabled,
      onFocusChange: (focused) {
        if (mounted) {
          setState(() => _isChartFocused = focused);
        }
      },
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 800.0;
          // Na bardzo wąskich ekranach (390px) gwarantujemy min. szerokość 520px z poziomym przewijaniem
          // lub płynne dopasowanie, aby słupki i etykiety miesięcy nigdy nie nachodziły na siebie.
          final double canvasWidth = math.max(availableWidth, isCompact ? 540.0 : availableWidth);

          final Widget chartCanvas = MouseRegion(
            cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            onExit: (_) {
              if (_hoveredIndex != null) {
                setState(() => _hoveredIndex = null);
              }
            },
            onHover: (event) {
              if (!widget.enabled) return;
              final int? idx = _hitTestMonthIndex(
                localPosition: event.localPosition,
                canvasWidth: canvasWidth,
                monthCount: months.length,
              );
              if (idx != _hoveredIndex) {
                setState(() => _hoveredIndex = idx);
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                if (!widget.enabled) return;
                _chartFocusNode.requestFocus();
                final int? idx = _hitTestMonthIndex(
                  localPosition: details.localPosition,
                  canvasWidth: canvasWidth,
                  monthCount: months.length,
                );
                if (idx != null) {
                  _selectMonthIndex(idx);
                }
              },
              child: AnimatedBuilder(
                animation: _revealAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(canvasWidth, chartHeight),
                    painter: _CashflowProjectionChartPainter(
                      months: months,
                      animationProgress: _revealAnimation.value,
                      activeIndex: _activeIndex,
                      showSponsors: _showSponsors,
                      showSalaries: _showSalaries,
                      showCamps: _showCamps,
                      showBalanceLine: _showBalanceLine,
                    ),
                  );
                },
              ),
            ),
          );

          if (canvasWidth > availableWidth) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: chartCanvas,
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: chartCanvas,
            ),
          );
        },
      ),
    );
  }

  int? _hitTestMonthIndex({
    required Offset localPosition,
    required double canvasWidth,
    required int monthCount,
  }) {
    if (monthCount <= 0) return null;
    const double leftPad = _CashflowProjectionChartPainter.leftPadding;
    const double rightPad = _CashflowProjectionChartPainter.rightPadding;
    final double plotWidth = canvasWidth - leftPad - rightPad;
    if (plotWidth <= 0) return null;

    final double relX = localPosition.dx - leftPad;
    if (relX < 0 || relX > plotWidth) return null;

    final double slotWidth = plotWidth / monthCount;
    return (relX / slotWidth).floor().clamp(0, monthCount - 1);
  }

  Widget _buildActiveMonthInspector({
    required List<MonthlyCashflowProjectionPoint> months,
    required TeamCashflowProjectionSummary summary,
    required bool isCompact,
  }) {
    final int idx = (_activeIndex ?? (months.length - 1)).clamp(0, months.length - 1);
    final MonthlyCashflowProjectionPoint point = months[idx];
    final bool isPinned = _activeIndex != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: point.isDeficit
              ? AppColors.crimsonAlert.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isPinned
                      ? 'SZCZEGÓŁY MIESIĄCA: ${point.monthLabel}'
                      : 'PODSUMOWANIE KOŃCA SEZONU (${point.monthLabel})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (point.isDeficit) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonAlert.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.6),
                      width: 1.0,
                    ),
                  ),
                  child: const Text(
                    'DEFICYT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: isCompact ? 10 : 16,
            runSpacing: 10,
            children: [
              _InspectorMetricTile(
                label: 'Transze sponsorów',
                value: Formatters.formatCurrency(point.sponsorTrancheEur),
                accentColor: AppColors.statusSuccess,
              ),
              _InspectorMetricTile(
                label: 'Wypłaty pensji',
                value: '-${Formatters.formatCurrency(point.salariesExpenseEur)}',
                accentColor: AppColors.primaryAccent,
              ),
              _InspectorMetricTile(
                label: 'Koszty obozów',
                value: '-${Formatters.formatCurrency(point.trainingCampsExpenseEur)}',
                accentColor: AppColors.amberWarning,
              ),
              _InspectorMetricTile(
                label: 'Bilans netto m-ca',
                value: (point.netCashflowEur >= 0 ? '+' : '') +
                    Formatters.formatCurrency(point.netCashflowEur),
                accentColor:
                    point.netCashflowEur >= 0 ? AppColors.statusSuccess : AppColors.crimsonAlert,
              ),
              _InspectorMetricTile(
                label: 'Prognozowane saldo',
                value: Formatters.formatCurrency(point.projectedEndingBalanceEur),
                accentColor: point.isDeficit ? AppColors.crimsonAlert : AppColors.goldAccent,
              ),
              if (!isCompact)
                _InspectorMetricTile(
                  label: 'Najniższe saldo w sezonie',
                  value: Formatters.formatCurrency(summary.lowestProjectedBalanceEur),
                  accentColor: summary.lowestProjectedBalanceEur < 0
                      ? AppColors.crimsonAlert
                      : AppColors.accentBlue,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectorMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _InspectorMetricTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 126),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesToggleChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool enabled;
  final bool isLineIndicator;
  final VoidCallback onTap;

  const _SeriesToggleChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.isLineIndicator = false,
  });

  @override
  State<_SeriesToggleChip> createState() => _SeriesToggleChipState();
}

class _SeriesToggleChipState extends State<_SeriesToggleChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? widget.color.withValues(alpha: _hovered ? 0.9 : 0.65)
            : AppColors.cardBorder);

    final Color bgColor = widget.selected
        ? widget.color.withValues(alpha: _pressed ? 0.24 : (_hovered ? 0.18 : 0.12))
        : (_hovered ? AppColors.surfaceLight : AppColors.background);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLineIndicator)
                Container(
                  width: 14,
                  height: 3,
                  decoration: BoxDecoration(
                    color: widget.selected ? widget.color : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: widget.selected ? widget.color : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeficitActionButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _DeficitActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_DeficitActionButton> createState() => _DeficitActionButtonState();
}

class _DeficitActionButtonState extends State<_DeficitActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.crimsonAlert.withValues(alpha: 0.35)
                : (_hovered
                    ? AppColors.crimsonAlert.withValues(alpha: 0.25)
                    : AppColors.crimsonAlert.withValues(alpha: 0.16)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppColors.crimsonAlert,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CashflowProjectionChartPainter extends CustomPainter {
  static const double leftPadding = 66.0;
  static const double rightPadding = 18.0;
  static const double topPadding = 18.0;
  static const double bottomPadding = 32.0;

  final List<MonthlyCashflowProjectionPoint> months;
  final double animationProgress;
  final int? activeIndex;
  final bool showSponsors;
  final bool showSalaries;
  final bool showCamps;
  final bool showBalanceLine;

  const _CashflowProjectionChartPainter({
    required this.months,
    required this.animationProgress,
    required this.activeIndex,
    required this.showSponsors,
    required this.showSalaries,
    required this.showCamps,
    required this.showBalanceLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    final Rect plotRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      math.max(1.0, size.width - leftPadding - rightPadding),
      math.max(1.0, size.height - topPadding - bottomPadding),
    );

    // Wyznaczamy zakres osi Y obejmujący zarówno słupki wpływów/wydatków jak i krzywą salda.
    double maxVal = 0.0;
    double minVal = 0.0;

    for (final m in months) {
      final double inflow =
          (showSponsors ? math.max(0.0, m.sponsorTrancheEur) : 0.0) + math.max(0.0, m.otherIncomeEur);
      final double outflow = (showSalaries ? math.max(0.0, m.salariesExpenseEur) : 0.0) +
          (showCamps ? math.max(0.0, m.trainingCampsExpenseEur) : 0.0) +
          math.max(0.0, m.logisticsAndOtherExpenseEur);

      maxVal = math.max(maxVal, inflow);
      minVal = math.min(minVal, -outflow);

      if (showBalanceLine) {
        maxVal = math.max(maxVal, m.projectedEndingBalanceEur);
        minVal = math.min(minVal, m.projectedEndingBalanceEur);
      }
    }

    if (maxVal == 0.0 && minVal == 0.0) {
      maxVal = 100000.0;
      minVal = -100000.0;
    } else {
      final double span = math.max(1.0, maxVal - minVal);
      maxVal += span * 0.12;
      minVal -= span * 0.12;
      if (maxVal < 0) maxVal = 0;
      if (minVal > 0) minVal = 0;
    }

    double valueToY(double value) {
      final double ratio = (value - minVal) / math.max(1e-6, maxVal - minVal);
      return plotRect.bottom - ratio * plotRect.height;
    }

    final double zeroY = valueToY(0.0);

    // Strefa deficytu poniżej zera
    if (zeroY < plotRect.bottom) {
      final Rect deficitZone = Rect.fromLTRB(
        plotRect.left,
        zeroY,
        plotRect.right,
        plotRect.bottom,
      );
      canvas.drawRect(
        deficitZone,
        Paint()..color = AppColors.crimsonAlert.withValues(alpha: 0.07),
      );
    }

    // Siatka pozioma i etykiety osi Y
    const int gridSteps = 4;
    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= gridSteps; i++) {
      final double t = i / gridSteps;
      final double val = minVal + (maxVal - minVal) * t;
      final double y = valueToY(val);
      canvas.drawLine(Offset(plotRect.left, y), Offset(plotRect.right, y), gridPaint);
      _drawText(
        canvas,
        Formatters.formatCompactCurrency(val),
        Offset(4, y - 6),
        width: leftPadding - 10,
        align: TextAlign.right,
        color: val < 0 ? AppColors.crimsonAlert : AppColors.textSecondary,
        fontSize: 10,
      );
    }

    // Wyraźna linia zerowa (próg deficytu 0 €)
    canvas.drawLine(
      Offset(plotRect.left, zeroY),
      Offset(plotRect.right, zeroY),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.55)
        ..strokeWidth = 1.2,
    );

    final double slotWidth = plotRect.width / months.length;
    final double barWidth = math.min(26.0, math.max(10.0, slotWidth * 0.44));

    // Podświetlenie aktywnej kolumny miesiąca
    if (activeIndex != null && activeIndex! >= 0 && activeIndex! < months.length) {
      final double slotLeft = plotRect.left + activeIndex! * slotWidth;
      canvas.drawRect(
        Rect.fromLTWH(slotLeft + 2, plotRect.top, slotWidth - 4, plotRect.height),
        Paint()..color = AppColors.goldAccent.withValues(alpha: 0.08),
      );
    }

    // Słupki wpływów (powyżej 0) i skumulowanych wydatków (poniżej 0)
    final List<Offset> balancePoints = [];

    for (int i = 0; i < months.length; i++) {
      final MonthlyCashflowProjectionPoint m = months[i];
      final double centerX = plotRect.left + (i + 0.5) * slotWidth;
      final bool isSelected = activeIndex == i;

      // 1) Słupki wpływów (Transze od sponsorów)
      final double sponsorVal = showSponsors ? math.max(0.0, m.sponsorTrancheEur) : 0.0;
      final double otherIncomeVal = math.max(0.0, m.otherIncomeEur);
      final double totalInflow = (sponsorVal + otherIncomeVal) * animationProgress;
      if (totalInflow > 0) {
        final double topY = valueToY(totalInflow);
        final RRect inflowRect = RRect.fromRectAndCorners(
          Rect.fromLTRB(centerX - barWidth / 2, topY, centerX + barWidth / 2, zeroY),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        );
        canvas.drawRRect(
          inflowRect,
          Paint()
            ..color = AppColors.statusSuccess.withValues(alpha: isSelected ? 0.95 : 0.78),
        );
      }

      // 2) Skumulowane słupki wydatków (Pensje + Obozy + Inne) poniżej 0
      double expenseCursor = 0.0;
      if (showSalaries && m.salariesExpenseEur > 0) {
        final double segVal = m.salariesExpenseEur * animationProgress;
        final double yStart = valueToY(-expenseCursor);
        expenseCursor += segVal;
        final double yEnd = valueToY(-expenseCursor);
        canvas.drawRect(
          Rect.fromLTRB(centerX - barWidth / 2, yStart, centerX + barWidth / 2, yEnd),
          Paint()
            ..color = AppColors.primaryAccent.withValues(alpha: isSelected ? 0.98 : 0.85),
        );
      }

      if (showCamps && m.trainingCampsExpenseEur > 0) {
        final double segVal = m.trainingCampsExpenseEur * animationProgress;
        final double yStart = valueToY(-expenseCursor);
        expenseCursor += segVal;
        final double yEnd = valueToY(-expenseCursor);
        canvas.drawRect(
          Rect.fromLTRB(centerX - barWidth / 2, yStart, centerX + barWidth / 2, yEnd),
          Paint()
            ..color = AppColors.amberWarning.withValues(alpha: isSelected ? 0.98 : 0.85),
        );
      }

      if (m.logisticsAndOtherExpenseEur > 0) {
        final double segVal = m.logisticsAndOtherExpenseEur * animationProgress;
        final double yStart = valueToY(-expenseCursor);
        expenseCursor += segVal;
        final double yEnd = valueToY(-expenseCursor);
        canvas.drawRect(
          Rect.fromLTRB(centerX - barWidth / 2, yStart, centerX + barWidth / 2, yEnd),
          Paint()
            ..color = AppColors.accentBlue.withValues(alpha: isSelected ? 0.9 : 0.65),
        );
      }

      // Punkt linii salda
      final double animatedBalance = m.projectedEndingBalanceEur * animationProgress;
      balancePoints.add(Offset(centerX, valueToY(animatedBalance)));

      // Etykieta miesiąca na osi X
      _drawText(
        canvas,
        m.monthLabel,
        Offset(centerX - slotWidth / 2, plotRect.bottom + 8),
        width: slotWidth,
        align: TextAlign.center,
        color: isSelected
            ? AppColors.goldAccent
            : (m.isDeficit ? AppColors.crimsonAlert : AppColors.textSecondary),
        fontSize: 10.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      );
    }

    // 3) Krzywa prognozowanego salda na koniec każdego miesiąca
    if (showBalanceLine && balancePoints.isNotEmpty) {
      for (int i = 0; i < balancePoints.length - 1; i++) {
        final Offset p1 = balancePoints[i];
        final Offset p2 = balancePoints[i + 1];
        final bool segDeficit =
            months[i].projectedEndingBalanceEur < 0 || months[i + 1].projectedEndingBalanceEur < 0;

        canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = segDeficit ? AppColors.crimsonAlert : AppColors.goldAccent
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round,
        );
      }

      for (int i = 0; i < balancePoints.length; i++) {
        final Offset pt = balancePoints[i];
        final bool isDeficit = months[i].isDeficit;
        final bool isSelected = activeIndex == i;
        final Color nodeColor = isDeficit ? AppColors.crimsonAlert : AppColors.goldAccent;

        if (isSelected || isDeficit) {
          canvas.drawCircle(
            pt,
            isSelected ? 7.5 : 6.0,
            Paint()..color = nodeColor.withValues(alpha: 0.25),
          );
        }
        canvas.drawCircle(
          pt,
          isSelected ? 4.8 : 3.6,
          Paint()..color = nodeColor,
        );
        canvas.drawCircle(
          pt,
          isSelected ? 2.2 : 1.6,
          Paint()..color = AppColors.background,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    required TextAlign align,
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CashflowProjectionChartPainter oldDelegate) {
    return oldDelegate.months != months ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.showSponsors != showSponsors ||
        oldDelegate.showSalaries != showSalaries ||
        oldDelegate.showCamps != showCamps ||
        oldDelegate.showBalanceLine != showBalanceLine;
  }
}
