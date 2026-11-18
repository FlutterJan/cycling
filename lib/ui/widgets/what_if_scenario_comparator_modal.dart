import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/what_if_tactical_sandbox_simulator.dart';

/// Metryka wyświetlana na wykresach pudełkowych porównania scenariuszy „Co Jeśli?”.
enum WhatIfComparatorMetric {
  timeGapSeconds,
  finishPosition,
  remainingWPrime;

  String get labelPl {
    switch (this) {
      case WhatIfComparatorMetric.timeGapSeconds:
        return 'Strata [s]';
      case WhatIfComparatorMetric.finishPosition:
        return 'Pozycja';
      case WhatIfComparatorMetric.remainingWPrime:
        return "Zapas W' [%]";
    }
  }

  String get unitSuffix {
    switch (this) {
      case WhatIfComparatorMetric.timeGapSeconds:
        return 's';
      case WhatIfComparatorMetric.finishPosition:
        return '';
      case WhatIfComparatorMetric.remainingWPrime:
        return '%';
    }
  }

  bool get lowerIsBetter {
    switch (this) {
      case WhatIfComparatorMetric.timeGapSeconds:
      case WhatIfComparatorMetric.finishPosition:
        return true;
      case WhatIfComparatorMetric.remainingWPrime:
        return false;
    }
  }
}

/// Tryb sortowania wariantów taktycznych w komparatorze.
enum WhatIfComparatorSortMode {
  winProbabilityDesc,
  tacticalScoreDesc,
  medianValueBest,
  bonkRiskAsc;

  String get labelPl {
    switch (this) {
      case WhatIfComparatorSortMode.winProbabilityDesc:
        return 'Szansa wygranej';
      case WhatIfComparatorSortMode.tacticalScoreDesc:
        return 'Ocena AI';
      case WhatIfComparatorSortMode.medianValueBest:
        return 'Mediana';
      case WhatIfComparatorSortMode.bonkRiskAsc:
        return 'Najniższe ryzyko';
    }
  }
}

/// Akcja wynikowa zamknięcia modalu porównania scenariuszy.
enum WhatIfComparatorModalAction {
  appliedVariant,
  dismissed,
}

/// Wynik zwracany przez [showWhatIfScenarioComparatorModal].
@immutable
class WhatIfScenarioComparatorResult {
  const WhatIfScenarioComparatorResult({
    required this.action,
    this.selectedVariantId,
    this.comparedVariantIds = const <String>[],
  });

  final WhatIfComparatorModalAction action;
  final String? selectedVariantId;
  final List<String> comparedVariantIds;
}

/// Statystyki wykresu pudełkowego (Box-and-Whisker) dla jednego wariantu Monte Carlo.
@immutable
class WhatIfBoxPlotStats {
  const WhatIfBoxPlotStats({
    required this.variantId,
    required this.variantName,
    required this.strategy,
    required this.riskLevel,
    required this.metric,
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    required this.mean,
    required this.stdDev,
    required this.outliers,
    required this.winProbability,
    required this.podiumProbability,
    required this.top10Probability,
    required this.bonkRiskProbability,
    required this.incidentRiskProbability,
    required this.expectedUciPoints,
    required this.tacticalVerdictScore,
    required this.isOptimalRecommended,
    required this.runCount,
  });

  final String variantId;
  final String variantName;
  final WhatIfTacticalStrategyType strategy;
  final WhatIfRiskLevel riskLevel;
  final WhatIfComparatorMetric metric;
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final double mean;
  final double stdDev;
  final List<double> outliers;
  final double winProbability;
  final double podiumProbability;
  final double top10Probability;
  final double bonkRiskProbability;
  final double incidentRiskProbability;
  final double expectedUciPoints;
  final double tacticalVerdictScore;
  final bool isOptimalRecommended;
  final int runCount;

  double get iqr => math.max(0.0, q3 - q1);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'variantId': variantId,
        'variantName': variantName,
        'strategy': strategy.toJson(),
        'riskLevel': riskLevel.toJson(),
        'metric': metric.name,
        'min': min,
        'q1': q1,
        'median': median,
        'q3': q3,
        'max': max,
        'mean': mean,
        'stdDev': stdDev,
        'outliers': outliers,
        'winProbability': winProbability,
        'podiumProbability': podiumProbability,
        'top10Probability': top10Probability,
        'bonkRiskProbability': bonkRiskProbability,
        'incidentRiskProbability': incidentRiskProbability,
        'expectedUciPoints': expectedUciPoints,
        'tacticalVerdictScore': tacticalVerdictScore,
        'isOptimalRecommended': isOptimalRecommended,
        'runCount': runCount,
      };

  factory WhatIfBoxPlotStats.fromJson(Map<String, dynamic> json) {
    final metricName = (json['metric'] as String?) ?? 'timeGapSeconds';
    final metric = WhatIfComparatorMetric.values.firstWhere(
      (e) => e.name == metricName,
      orElse: () => WhatIfComparatorMetric.timeGapSeconds,
    );
    return WhatIfBoxPlotStats(
      variantId: (json['variantId'] as String?) ?? 'var_1',
      variantName: (json['variantName'] as String?) ?? 'Wariant',
      strategy: WhatIfTacticalStrategyType.fromJson(
        (json['strategy'] as String?) ?? 'defensivePelotonControl',
      ),
      riskLevel: WhatIfRiskLevel.fromJson(
        (json['riskLevel'] as String?) ?? 'balanced',
      ),
      metric: metric,
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      q1: (json['q1'] as num?)?.toDouble() ?? 0.0,
      median: (json['median'] as num?)?.toDouble() ?? 0.0,
      q3: (json['q3'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      mean: (json['mean'] as num?)?.toDouble() ?? 0.0,
      stdDev: (json['stdDev'] as num?)?.toDouble() ?? 0.0,
      outliers: ((json['outliers'] as List<dynamic>?) ?? const <dynamic>[])
          .map((e) => (e as num).toDouble())
          .toList(),
      winProbability: (json['winProbability'] as num?)?.toDouble() ?? 0.0,
      podiumProbability: (json['podiumProbability'] as num?)?.toDouble() ?? 0.0,
      top10Probability: (json['top10Probability'] as num?)?.toDouble() ?? 0.0,
      bonkRiskProbability:
          (json['bonkRiskProbability'] as num?)?.toDouble() ?? 0.0,
      incidentRiskProbability:
          (json['incidentRiskProbability'] as num?)?.toDouble() ?? 0.0,
      expectedUciPoints: (json['expectedUciPoints'] as num?)?.toDouble() ?? 0.0,
      tacticalVerdictScore:
          (json['tacticalVerdictScore'] as num?)?.toDouble() ?? 0.0,
      isOptimalRecommended: (json['isOptimalRecommended'] as bool?) ?? false,
      runCount: (json['runCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Różnica porównawcza pomiędzy wariantem głównym (A) a wariantem porównywanym (B).
@immutable
class WhatIfHeadToHeadDelta {
  const WhatIfHeadToHeadDelta({
    required this.primary,
    required this.challenger,
    required this.winProbDeltaPp,
    required this.podiumProbDeltaPp,
    required this.medianDelta,
    required this.bonkRiskDeltaPp,
    required this.uciPointsDelta,
    required this.verdictScoreDelta,
  });

  final WhatIfBoxPlotStats primary;
  final WhatIfBoxPlotStats challenger;

  /// Różnica w punktach procentowych (primary - challenger) * 100.
  final double winProbDeltaPp;
  final double podiumProbDeltaPp;
  final double medianDelta;
  final double bonkRiskDeltaPp;
  final double uciPointsDelta;
  final double verdictScoreDelta;
}

/// Kalkulator statystyk pudełkowych (kwartyle, wąsy Tukeya, outliery) i różnic H2H.
class WhatIfBoxPlotCalculator {
  const WhatIfBoxPlotCalculator._();

  /// Wylicza statystyki pudełkowe dla [outcome] oraz wybranej [metric].
  static WhatIfBoxPlotStats computeStats({
    required WhatIfVariantOutcome outcome,
    required WhatIfComparatorMetric metric,
  }) {
    final values = _extractMetricValues(outcome, metric);
    if (values.isEmpty) {
      final fallbackMedian = _fallbackMedian(outcome, metric);
      final fallbackLow = _fallbackLower(outcome, metric, fallbackMedian);
      final fallbackHigh = _fallbackUpper(outcome, metric, fallbackMedian);
      return WhatIfBoxPlotStats(
        variantId: outcome.variant.id,
        variantName: outcome.variant.name,
        strategy: outcome.variant.strategy,
        riskLevel: outcome.variant.riskLevel,
        metric: metric,
        min: fallbackLow,
        q1: (fallbackLow + fallbackMedian) * 0.5,
        median: fallbackMedian,
        q3: (fallbackMedian + fallbackHigh) * 0.5,
        max: fallbackHigh,
        mean: fallbackMedian,
        stdDev: (fallbackHigh - fallbackLow).abs() * 0.25,
        outliers: const <double>[],
        winProbability: outcome.winProbability,
        podiumProbability: outcome.podiumProbability,
        top10Probability: outcome.top10Probability,
        bonkRiskProbability: outcome.bonkRiskProbability,
        incidentRiskProbability: outcome.incidentRiskProbability,
        expectedUciPoints: outcome.expectedUciPoints,
        tacticalVerdictScore: outcome.tacticalVerdictScore,
        isOptimalRecommended: outcome.isOptimalRecommended,
        runCount: outcome.runCount,
      );
    }

    final sorted = List<double>.from(values)..sort();
    final q1 = _percentile(sorted, 0.25);
    final median = _percentile(sorted, 0.50);
    final q3 = _percentile(sorted, 0.75);
    final iqr = math.max(0.0, q3 - q1);
    final lowerFence = q1 - 1.5 * iqr;
    final upperFence = q3 + 1.5 * iqr;

    final inliers = <double>[];
    final outliers = <double>[];
    for (final v in sorted) {
      if (v < lowerFence || v > upperFence) {
        outliers.add(v);
      } else {
        inliers.add(v);
      }
    }

    final whiskerMin = inliers.isNotEmpty ? inliers.first : sorted.first;
    final whiskerMax = inliers.isNotEmpty ? inliers.last : sorted.last;

    double sum = 0.0;
    for (final v in sorted) {
      sum += v;
    }
    final mean = sum / sorted.length;
    double sqDiff = 0.0;
    for (final v in sorted) {
      final d = v - mean;
      sqDiff += d * d;
    }
    final stdDev = sorted.length > 1 ? math.sqrt(sqDiff / sorted.length) : 0.0;

    return WhatIfBoxPlotStats(
      variantId: outcome.variant.id,
      variantName: outcome.variant.name,
      strategy: outcome.variant.strategy,
      riskLevel: outcome.variant.riskLevel,
      metric: metric,
      min: whiskerMin,
      q1: q1,
      median: median,
      q3: q3,
      max: whiskerMax,
      mean: mean,
      stdDev: stdDev,
      outliers: outliers,
      winProbability: outcome.winProbability,
      podiumProbability: outcome.podiumProbability,
      top10Probability: outcome.top10Probability,
      bonkRiskProbability: outcome.bonkRiskProbability,
      incidentRiskProbability: outcome.incidentRiskProbability,
      expectedUciPoints: outcome.expectedUciPoints,
      tacticalVerdictScore: outcome.tacticalVerdictScore,
      isOptimalRecommended: outcome.isOptimalRecommended,
      runCount: outcome.runCount,
    );
  }

  /// Wyznacza globalny zakres osi `[minVal, maxVal]` dla listy statystyk.
  static ({double minVal, double maxVal}) computeAxisDomain(
    List<WhatIfBoxPlotStats> statsList,
    WhatIfComparatorMetric metric,
  ) {
    if (statsList.isEmpty) {
      switch (metric) {
        case WhatIfComparatorMetric.timeGapSeconds:
          return (minVal: 0.0, maxVal: 60.0);
        case WhatIfComparatorMetric.finishPosition:
          return (minVal: 1.0, maxVal: 20.0);
        case WhatIfComparatorMetric.remainingWPrime:
          return (minVal: 0.0, maxVal: 100.0);
      }
    }

    double lo = double.infinity;
    double hi = double.negativeInfinity;
    for (final s in statsList) {
      lo = math.min(lo, s.min);
      hi = math.max(hi, s.max);
      for (final o in s.outliers) {
        lo = math.min(lo, o);
        hi = math.max(hi, o);
      }
    }

    if (!lo.isFinite || !hi.isFinite) {
      return (minVal: 0.0, maxVal: 100.0);
    }

    if ((hi - lo).abs() < 1e-6) {
      return (minVal: math.max(0.0, lo - 5.0), maxVal: hi + 5.0);
    }

    final pad = (hi - lo) * 0.08;
    final clampedLo = metric == WhatIfComparatorMetric.finishPosition
        ? math.max(1.0, (lo - pad).floorToDouble())
        : math.max(0.0, lo - pad);
    final clampedHi = metric == WhatIfComparatorMetric.remainingWPrime
        ? math.min(100.0, hi + pad)
        : hi + pad;
    return (minVal: clampedLo, maxVal: clampedHi);
  }

  /// Wylicza deltę porównawczą pomiędzy dwoma wariantami.
  static WhatIfHeadToHeadDelta computeHeadToHeadDelta(
    WhatIfBoxPlotStats primary,
    WhatIfBoxPlotStats challenger,
  ) {
    return WhatIfHeadToHeadDelta(
      primary: primary,
      challenger: challenger,
      winProbDeltaPp: (primary.winProbability - challenger.winProbability) * 100,
      podiumProbDeltaPp:
          (primary.podiumProbability - challenger.podiumProbability) * 100,
      medianDelta: primary.median - challenger.median,
      bonkRiskDeltaPp:
          (primary.bonkRiskProbability - challenger.bonkRiskProbability) * 100,
      uciPointsDelta: primary.expectedUciPoints - challenger.expectedUciPoints,
      verdictScoreDelta:
          primary.tacticalVerdictScore - challenger.tacticalVerdictScore,
    );
  }

  /// Wybiera domyślne ID maksymalnie 4 wariantów do porównania z raportu.
  static List<String> pickDefaultComparedIds(
    WhatIfSandboxSimulationReport report, {
    int maxCount = 4,
  }) {
    if (report.outcomes.isEmpty) {
      return const <String>[];
    }
    final picked = <String>[];
    void addIfPresent(String id) {
      if (picked.length >= maxCount || picked.contains(id)) return;
      if (report.outcomes.any((o) => o.variant.id == id)) {
        picked.add(id);
      }
    }

    addIfPresent(report.bestWinVariantId);
    addIfPresent(report.bestSafeVariantId);

    final sorted = List<WhatIfVariantOutcome>.from(report.outcomes)
      ..sort(
        (a, b) => b.tacticalVerdictScore.compareTo(a.tacticalVerdictScore),
      );
    for (final o in sorted) {
      addIfPresent(o.variant.id);
      if (picked.length >= maxCount) break;
    }
    return picked;
  }

  static List<double> _extractMetricValues(
    WhatIfVariantOutcome outcome,
    WhatIfComparatorMetric metric,
  ) {
    if (outcome.samples.isEmpty) {
      return const <double>[];
    }
    return outcome.samples.map((s) {
      switch (metric) {
        case WhatIfComparatorMetric.timeGapSeconds:
          return s.timeGapToWinnerSeconds;
        case WhatIfComparatorMetric.finishPosition:
          return s.finishPosition.toDouble();
        case WhatIfComparatorMetric.remainingWPrime:
          return s.remainingWPrimePercent;
      }
    }).toList();
  }

  static double _fallbackMedian(
    WhatIfVariantOutcome outcome,
    WhatIfComparatorMetric metric,
  ) {
    switch (metric) {
      case WhatIfComparatorMetric.timeGapSeconds:
        return outcome.p50TimeGapSeconds;
      case WhatIfComparatorMetric.finishPosition:
        return outcome.expectedFinishPosition;
      case WhatIfComparatorMetric.remainingWPrime:
        return (1.0 - outcome.bonkRiskProbability) * 45.0;
    }
  }

  static double _fallbackLower(
    WhatIfVariantOutcome outcome,
    WhatIfComparatorMetric metric,
    double median,
  ) {
    switch (metric) {
      case WhatIfComparatorMetric.timeGapSeconds:
        return math.min(median, outcome.p10TimeGapSeconds);
      case WhatIfComparatorMetric.finishPosition:
        return math.max(1.0, median - 4.0);
      case WhatIfComparatorMetric.remainingWPrime:
        return math.max(0.0, median - 18.0);
    }
  }

  static double _fallbackUpper(
    WhatIfVariantOutcome outcome,
    WhatIfComparatorMetric metric,
    double median,
  ) {
    switch (metric) {
      case WhatIfComparatorMetric.timeGapSeconds:
        return math.max(median, outcome.p90TimeGapSeconds);
      case WhatIfComparatorMetric.finishPosition:
        return median + 6.0;
      case WhatIfComparatorMetric.remainingWPrime:
        return math.min(100.0, median + 18.0);
    }
  }

  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0.0;
    if (sorted.length == 1) return sorted.first;
    final pos = p.clamp(0.0, 1.0) * (sorted.length - 1);
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sorted[lo];
    final frac = pos - lo;
    return sorted[lo] + (sorted[hi] - sorted[lo]) * frac;
  }
}

/// Wyświetla szklany modal porównania wykresów pudełkowych i prawdopodobieństwa wygranej.
Future<WhatIfScenarioComparatorResult?> showWhatIfScenarioComparatorModal(
  BuildContext context, {
  required WhatIfSandboxSimulationReport report,
  List<String>? initialSelectedVariantIds,
  WhatIfComparatorMetric initialMetric = WhatIfComparatorMetric.timeGapSeconds,
  ValueChanged<WhatIfVariantOutcome>? onApplyVariant,
  bool enabled = true,
}) {
  return showGeneralDialog<WhatIfScenarioComparatorResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Zamknij komparator scenariuszy',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return SafeArea(
        child: Center(
          child: WhatIfScenarioComparatorModal(
            report: report,
            initialSelectedVariantIds: initialSelectedVariantIds,
            initialMetric: initialMetric,
            onApplyVariant: onApplyVariant,
            enabled: enabled,
          ),
        ),
      );
    },
    transitionBuilder: (
      BuildContext dialogContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Szklany modal porównania wykresów pudełkowych i prawdopodobieństwa wygranej
/// dla symulacji Monte Carlo „Co Jeśli?” ([WhatIfTacticalSandboxSimulator]).
class WhatIfScenarioComparatorModal extends StatefulWidget {
  const WhatIfScenarioComparatorModal({
    super.key,
    required this.report,
    this.initialSelectedVariantIds,
    this.initialMetric = WhatIfComparatorMetric.timeGapSeconds,
    this.onApplyVariant,
    this.enabled = true,
  });

  final WhatIfSandboxSimulationReport report;
  final List<String>? initialSelectedVariantIds;
  final WhatIfComparatorMetric initialMetric;
  final ValueChanged<WhatIfVariantOutcome>? onApplyVariant;
  final bool enabled;

  @override
  State<WhatIfScenarioComparatorModal> createState() =>
      _WhatIfScenarioComparatorModalState();
}

class _WhatIfScenarioComparatorModalState
    extends State<WhatIfScenarioComparatorModal> {
  static const int _maxComparedVariants = 5;

  late WhatIfComparatorMetric _metric;
  WhatIfComparatorSortMode _sortMode =
      WhatIfComparatorSortMode.winProbabilityDesc;
  WhatIfRiskLevel? _riskFilter;
  late List<String> _comparedIds;
  String? _primaryVariantId;
  String? _hoveredBoxVariantId;

  @override
  void initState() {
    super.initState();
    _metric = widget.initialMetric;
    _initSelection();
  }

  @override
  void didUpdateWidget(covariant WhatIfScenarioComparatorModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report != widget.report) {
      _initSelection();
    }
  }

  void _initSelection() {
    final validIds = widget.report.outcomes.map((o) => o.variant.id).toSet();
    final requested = (widget.initialSelectedVariantIds ?? const <String>[])
        .where(validIds.contains)
        .take(_maxComparedVariants)
        .toList();
    _comparedIds = requested.isNotEmpty
        ? requested
        : WhatIfBoxPlotCalculator.pickDefaultComparedIds(
            widget.report,
            maxCount: 4,
          );
    _primaryVariantId = _comparedIds.isNotEmpty ? _comparedIds.first : null;
  }

  List<WhatIfVariantOutcome> get _filteredAndSortedOutcomes {
    final base = widget.report.outcomes.where((o) {
      if (_riskFilter != null && o.variant.riskLevel != _riskFilter) {
        return false;
      }
      return true;
    }).toList();

    base.sort((a, b) {
      switch (_sortMode) {
        case WhatIfComparatorSortMode.winProbabilityDesc:
          return b.winProbability.compareTo(a.winProbability);
        case WhatIfComparatorSortMode.tacticalScoreDesc:
          return b.tacticalVerdictScore.compareTo(a.tacticalVerdictScore);
        case WhatIfComparatorSortMode.medianValueBest:
          final statsA =
              WhatIfBoxPlotCalculator.computeStats(outcome: a, metric: _metric);
          final statsB =
              WhatIfBoxPlotCalculator.computeStats(outcome: b, metric: _metric);
          return _metric.lowerIsBetter
              ? statsA.median.compareTo(statsB.median)
              : statsB.median.compareTo(statsA.median);
        case WhatIfComparatorSortMode.bonkRiskAsc:
          return a.bonkRiskProbability.compareTo(b.bonkRiskProbability);
      }
    });
    return base;
  }

  List<WhatIfBoxPlotStats> get _comparedStats {
    final result = <WhatIfBoxPlotStats>[];
    for (final id in _comparedIds) {
      final match = widget.report.outcomes.where((o) => o.variant.id == id);
      if (match.isNotEmpty) {
        result.add(
          WhatIfBoxPlotCalculator.computeStats(
            outcome: match.first,
            metric: _metric,
          ),
        );
      }
    }
    return result;
  }

  WhatIfVariantOutcome? get _primaryOutcome {
    if (_primaryVariantId == null || widget.report.outcomes.isEmpty) {
      return null;
    }
    for (final o in widget.report.outcomes) {
      if (o.variant.id == _primaryVariantId) return o;
    }
    return widget.report.outcomes.first;
  }

  void _toggleComparedVariant(String id) {
    if (!widget.enabled) return;
    setState(() {
      if (_comparedIds.contains(id)) {
        if (_comparedIds.length > 1) {
          _comparedIds.remove(id);
          if (_primaryVariantId == id) {
            _primaryVariantId = _comparedIds.first;
          }
        }
      } else {
        if (_comparedIds.length >= _maxComparedVariants) {
          _comparedIds.removeAt(_comparedIds.length - 1);
        }
        _comparedIds.add(id);
        _primaryVariantId ??= id;
      }
    });
  }

  void _selectPrimaryVariant(String id) {
    if (!widget.enabled) return;
    setState(() {
      _primaryVariantId = id;
      if (!_comparedIds.contains(id)) {
        if (_comparedIds.length >= _maxComparedVariants) {
          _comparedIds.removeLast();
        }
        _comparedIds.insert(0, id);
      }
    });
  }

  void _handleApply() {
    if (!widget.enabled) return;
    final outcome = _primaryOutcome;
    if (outcome == null) return;
    widget.onApplyVariant?.call(outcome);
    Navigator.of(context).maybePop(
      WhatIfScenarioComparatorResult(
        action: WhatIfComparatorModalAction.appliedVariant,
        selectedVariantId: outcome.variant.id,
        comparedVariantIds: List<String>.unmodifiable(_comparedIds),
      ),
    );
  }

  void _handleDismiss() {
    Navigator.of(context).maybePop(
      WhatIfScenarioComparatorResult(
        action: WhatIfComparatorModalAction.dismissed,
        selectedVariantId: _primaryVariantId,
        comparedVariantIds: List<String>.unmodifiable(_comparedIds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 1024.0;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 768.0;
        final isMobile = width < 680;
        final isDesktop = width >= 1120;

        final modalWidth = isMobile
            ? math.max(320.0, width - 20.0)
            : math.min(1260.0, width * 0.94);
        final modalMaxHeight = isMobile ? height * 0.94 : height * 0.90;

        return Material(
          color: Colors.transparent,
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) {
                    _handleDismiss();
                    return null;
                  },
                ),
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: modalWidth,
                  maxHeight: modalMaxHeight,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppColors.surface.withValues(alpha: 0.92),
                            AppColors.background.withValues(alpha: 0.94),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1.0,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildHeader(isMobile: isMobile),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.borderColor,
                          ),
                          if (widget.report.outcomes.isEmpty)
                            Flexible(child: _buildEmptyState())
                          else
                            Flexible(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(isMobile ? 12 : 18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    _buildControlsBar(isMobile: isMobile),
                                    const SizedBox(height: 12),
                                    _buildVariantPickerStrip(isMobile: isMobile),
                                    const SizedBox(height: 14),
                                    if (isDesktop || !isMobile)
                                      _buildDesktopComparisonGrid(
                                        isDesktop: isDesktop,
                                      )
                                    else
                                      _buildMobileComparisonStack(),
                                  ],
                                ),
                              ),
                            ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.borderColor,
                          ),
                          _buildFooter(isMobile: isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    final stage = widget.report.stageContext;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.45),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.candlestick_chart_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Komparator Scenariuszy „Co Jeśli?”',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 15 : 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stage.stageName} • ${stage.distanceKm.toStringAsFixed(1)} km • ${widget.report.totalSimulationsRun} prób (${widget.report.elapsedMs} ms)',
                  maxLines: 1,
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
          if (!isMobile) ...<Widget>[
            _GlassBadge(
              icon: Icons.verified_rounded,
              label:
                  '${_comparedStats.length}/$_maxComparedVariants wariantów',
              accentColor: AppColors.accentBlue,
            ),
            const SizedBox(width: 10),
          ],
          _InteractiveIconButton(
            key: const Key('what_if_comparator_close_button'),
            icon: Icons.close_rounded,
            tooltip: 'Zamknij (Esc)',
            onPressed: _handleDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar({required bool isMobile}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: WhatIfComparatorMetric.values.map((m) {
            final selected = _metric == m;
            return _GlassActionChip(
              key: Key('metric_chip_${m.name}'),
              label: m.labelPl,
              selected: selected,
              enabled: widget.enabled,
              accentColor: AppColors.cyanAccent,
              onTap: () {
                setState(() => _metric = m);
              },
            );
          }).toList(),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _GlassActionChip(
              key: const Key('risk_filter_all'),
              label: 'Wszystkie',
              selected: _riskFilter == null,
              enabled: widget.enabled,
              accentColor: AppColors.goldAccent,
              onTap: () => setState(() => _riskFilter = null),
            ),
            ...WhatIfRiskLevel.values.map((risk) {
              return _GlassActionChip(
                key: Key('risk_filter_${risk.name}'),
                label: risk.labelPl,
                selected: _riskFilter == risk,
                enabled: widget.enabled,
                accentColor: risk.color,
                onTap: () => setState(() {
                  _riskFilter = _riskFilter == risk ? null : risk;
                }),
              );
            }),
            if (!isMobile) _buildSortDropdown(),
          ],
        ),
        if (isMobile) _buildSortDropdown(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WhatIfComparatorSortMode>(
          key: const Key('what_if_sort_dropdown'),
          value: _sortMode,
          isDense: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textSecondary,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          onChanged: widget.enabled
              ? (WhatIfComparatorSortMode? next) {
                  if (next != null) {
                    setState(() => _sortMode = next);
                  }
                }
              : null,
          items: WhatIfComparatorSortMode.values.map((mode) {
            return DropdownMenuItem<WhatIfComparatorSortMode>(
              value: mode,
              child: Text('Sortuj: ${mode.labelPl}'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVariantPickerStrip({required bool isMobile}) {
    final outcomes = _filteredAndSortedOutcomes;
    if (outcomes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'Brak wariantów spełniających wybrany filtr ryzyka.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Porównywane warianty (kliknij aby dodać/usunąć, maks. 5):',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (!widget.enabled) ...<Widget>[
              const SizedBox(width: 8),
              const Text(
                'Tryb podglądu',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.amberWarning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: isMobile ? 42 : 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: outcomes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final outcome = outcomes[index];
              final id = outcome.variant.id;
              final isCompared = _comparedIds.contains(id);
              final isPrimary = _primaryVariantId == id;
              return _VariantChipItem(
                key: Key('variant_chip_$id'),
                outcome: outcome,
                isCompared: isCompared,
                isPrimary: isPrimary,
                enabled: widget.enabled,
                onTap: () => _toggleComparedVariant(id),
                onLongPress: () => _selectPrimaryVariant(id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopComparisonGrid({required bool isDesktop}) {
    final stats = _comparedStats;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: isDesktop ? 7 : 6,
          child: _buildBoxPlotCard(stats, height: 320),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: isDesktop ? 5 : 5,
          child: Column(
            children: <Widget>[
              _buildWinProbabilityCard(stats),
              const SizedBox(height: 14),
              _buildHeadToHeadDeltaCard(stats),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileComparisonStack() {
    final stats = _comparedStats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildBoxPlotCard(stats, height: 260),
        const SizedBox(height: 12),
        _buildWinProbabilityCard(stats),
        const SizedBox(height: 12),
        _buildHeadToHeadDeltaCard(stats),
      ],
    );
  }

  Widget _buildBoxPlotCard(
    List<WhatIfBoxPlotStats> stats, {
    required double height,
  }) {
    final domain = WhatIfBoxPlotCalculator.computeAxisDomain(stats, _metric);
    final hoveredStats = _hoveredBoxVariantId == null
        ? null
        : stats.where((s) => s.variantId == _hoveredBoxVariantId).firstOrNull;

    return _GlassSectionCard(
      title: 'Rozkład kwartylowy (Box Plot) — ${_metric.labelPl}',
      subtitle: 'Wąsy Min–Max (1.5×IQR) • Pudełko Q1–Q3 • Mediana & Średnia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: height,
            child: stats.isEmpty
                ? const Center(
                    child: Text(
                      'Wybierz co najmniej jeden wariant.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      return MouseRegion(
                        onHover: (PointerHoverEvent event) {
                          if (!widget.enabled || stats.isEmpty) return;
                          final slotHeight = box.maxHeight / stats.length;
                          final idx = (event.localPosition.dy / slotHeight)
                              .floor()
                              .clamp(0, stats.length - 1);
                          final targetId = stats[idx].variantId;
                          if (targetId != _hoveredBoxVariantId) {
                            setState(() => _hoveredBoxVariantId = targetId);
                          }
                        },
                        onExit: (_) {
                          if (_hoveredBoxVariantId != null) {
                            setState(() => _hoveredBoxVariantId = null);
                          }
                        },
                        child: GestureDetector(
                          onTapDown: (TapDownDetails details) {
                            if (!widget.enabled || stats.isEmpty) return;
                            final slotHeight = box.maxHeight / stats.length;
                            final idx = (details.localPosition.dy / slotHeight)
                                .floor()
                                .clamp(0, stats.length - 1);
                            _selectPrimaryVariant(stats[idx].variantId);
                          },
                          child: CustomPaint(
                            key: const Key('what_if_boxplot_canvas'),
                            size: Size(box.maxWidth, box.maxHeight),
                            painter: WhatIfBoxPlotComparisonPainter(
                              stats: stats,
                              metric: _metric,
                              minVal: domain.minVal,
                              maxVal: domain.maxVal,
                              primaryVariantId: _primaryVariantId,
                              hoveredVariantId: _hoveredBoxVariantId,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (hoveredStats != null) ...<Widget>[
            const SizedBox(height: 8),
            _buildQuartileInspectorBar(hoveredStats),
          ] else if (stats.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            _buildQuartileInspectorBar(
              stats.firstWhere(
                (s) => s.variantId == _primaryVariantId,
                orElse: () => stats.first,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuartileInspectorBar(WhatIfBoxPlotStats s) {
    final unit = _metric.unitSuffix;
    String fmt(double v) =>
        _metric == WhatIfComparatorMetric.finishPosition
            ? '#${v.toStringAsFixed(1)}'
            : '${v.toStringAsFixed(1)}$unit';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            s.variantName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
            ),
          ),
          _StatInlinePill(label: 'Min', value: fmt(s.min)),
          _StatInlinePill(label: 'Q1', value: fmt(s.q1)),
          _StatInlinePill(
            label: 'Mediana',
            value: fmt(s.median),
            highlightColor: AppColors.cyanAccent,
          ),
          _StatInlinePill(label: 'Q3', value: fmt(s.q3)),
          _StatInlinePill(label: 'Max', value: fmt(s.max)),
          _StatInlinePill(label: 'σ', value: s.stdDev.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildWinProbabilityCard(List<WhatIfBoxPlotStats> stats) {
    return _GlassSectionCard(
      title: 'Prawdopodobieństwo wygranej i podium',
      subtitle: 'Rozkład szans oraz ryzyko odcięcia (Bonk) w symulacji',
      child: Column(
        children: stats.map((s) {
          final isPrimary = s.variantId == _primaryVariantId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.enabled
                  ? () => _selectPrimaryVariant(s.variantId)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? AppColors.primaryAccent.withValues(alpha: 0.16)
                      : AppColors.surfaceLight.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPrimary
                        ? AppColors.goldAccent.withValues(alpha: 0.7)
                        : AppTheme.borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          s.strategy.icon,
                          size: 14,
                          color: s.riskLevel.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s.variantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Win ${(s.winProbability * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldAccent,
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _ProbabilityStackedBar(
                      winProbability: s.winProbability,
                      podiumProbability: s.podiumProbability,
                      top10Probability: s.top10Probability,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: <Widget>[
                        _MiniMetricText(
                          label: 'Podium',
                          value: '${(s.podiumProbability * 100).toStringAsFixed(0)}%',
                          color: AppColors.accentBlue,
                        ),
                        _MiniMetricText(
                          label: 'Top 10',
                          value: '${(s.top10Probability * 100).toStringAsFixed(0)}%',
                          color: AppColors.statusSuccess,
                        ),
                        _MiniMetricText(
                          label: 'Bonk',
                          value:
                              '${(s.bonkRiskProbability * 100).toStringAsFixed(0)}%',
                          color: s.bonkRiskProbability > 0.25
                              ? AppColors.crimsonAlert
                              : AppColors.textSecondary,
                        ),
                        _MiniMetricText(
                          label: 'UCI',
                          value: '+${s.expectedUciPoints.toStringAsFixed(0)} pkt',
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeadToHeadDeltaCard(List<WhatIfBoxPlotStats> stats) {
    if (stats.length < 2) {
      return const _GlassSectionCard(
        title: 'Porównanie bezpośrednie (H2H)',
        subtitle: 'Wybierz co najmniej 2 warianty, aby zobaczyć deltę taktyczną',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Zaznacz drugi wariant na górnym pasku, aby porównać zysk szansy wygranej i ryzyko odcięcia.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final primary = stats.firstWhere(
      (s) => s.variantId == _primaryVariantId,
      orElse: () => stats.first,
    );
    final challenger = stats.firstWhere(
      (s) => s.variantId != primary.variantId,
      orElse: () => stats[1],
    );
    final delta =
        WhatIfBoxPlotCalculator.computeHeadToHeadDelta(primary, challenger);

    return _GlassSectionCard(
      title: 'Bilans H2H: ${primary.variantName} vs ${challenger.variantName}',
      subtitle: 'Różnica względem wariantu porównawczego',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _DeltaTile(
            label: 'Szansa wygranej',
            value:
                '${delta.winProbDeltaPp >= 0 ? '+' : ''}${delta.winProbDeltaPp.toStringAsFixed(1)} pp',
            isPositiveGood: delta.winProbDeltaPp >= 0,
          ),
          _DeltaTile(
            label: 'Mediana (${_metric.labelPl})',
            value:
                '${delta.medianDelta >= 0 ? '+' : ''}${delta.medianDelta.toStringAsFixed(1)}${_metric.unitSuffix}',
            isPositiveGood: _metric.lowerIsBetter
                ? delta.medianDelta <= 0
                : delta.medianDelta >= 0,
          ),
          _DeltaTile(
            label: 'Ryzyko Bonk',
            value:
                '${delta.bonkRiskDeltaPp >= 0 ? '+' : ''}${delta.bonkRiskDeltaPp.toStringAsFixed(1)} pp',
            isPositiveGood: delta.bonkRiskDeltaPp <= 0,
          ),
          _DeltaTile(
            label: 'Punkty UCI',
            value:
                '${delta.uciPointsDelta >= 0 ? '+' : ''}${delta.uciPointsDelta.toStringAsFixed(0)} pkt',
            isPositiveGood: delta.uciPointsDelta >= 0,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.analytics_outlined,
              size: 44,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Brak danych symulacji Monte Carlo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Uruchom symulator scenariuszy „Co Jeśli?”, aby wygenerować rozkłady pudełkowe i porównać prawdopodobieństwo wygranej.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter({required bool isMobile}) {
    final primary = _primaryOutcome;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (primary != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.flag_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 260 : 420),
                  child: Text(
                    'Wybrany wariant: ${primary.variant.name} (${(primary.winProbability * 100).toStringAsFixed(1)}% Win)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              _ModalActionButton(
                key: const Key('what_if_comparator_cancel_button'),
                label: 'Zamknij',
                isPrimary: false,
                enabled: true,
                onPressed: _handleDismiss,
              ),
              _ModalActionButton(
                key: const Key('what_if_comparator_apply_button'),
                label: 'Zastosuj wariant',
                isPrimary: true,
                enabled: widget.enabled && primary != null,
                onPressed: _handleApply,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rysujący poziome wykresy pudełkowe (Box-and-Whisker)
/// dla porównywanych scenariuszy Monte Carlo.
class WhatIfBoxPlotComparisonPainter extends CustomPainter {
  WhatIfBoxPlotComparisonPainter({
    required this.stats,
    required this.metric,
    required this.minVal,
    required this.maxVal,
    this.primaryVariantId,
    this.hoveredVariantId,
  });

  final List<WhatIfBoxPlotStats> stats;
  final WhatIfComparatorMetric metric;
  final double minVal;
  final double maxVal;
  final String? primaryVariantId;
  final String? hoveredVariantId;

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty || size.width <= 40 || size.height <= 40) return;

    const leftMargin = 112.0;
    const rightMargin = 18.0;
    const topMargin = 12.0;
    const bottomMargin = 26.0;

    final chartWidth = math.max(10.0, size.width - leftMargin - rightMargin);
    final chartHeight = math.max(10.0, size.height - topMargin - bottomMargin);
    final span = math.max(1e-6, maxVal - minVal);

    double valueToX(double value) {
      final norm = ((value - minVal) / span).clamp(0.0, 1.0);
      return leftMargin + norm * chartWidth;
    }

    // Siatka pionowa + etykiety osi X
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    const gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final t = i / gridSteps;
      final val = minVal + t * span;
      final x = leftMargin + t * chartWidth;

      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, topMargin + chartHeight),
        gridPaint,
      );

      final label = metric == WhatIfComparatorMetric.finishPosition
          ? '#${val.round()}'
          : '${val.toStringAsFixed(0)}${metric.unitSuffix}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: AppColors.textSecondary,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          (x - tp.width / 2).clamp(leftMargin, size.width - tp.width),
          topMargin + chartHeight + 6,
        ),
      );
    }

    final slotHeight = chartHeight / stats.length;
    for (int i = 0; i < stats.length; i++) {
      final s = stats[i];
      final cy = topMargin + slotHeight * (i + 0.5);
      final isPrimary = s.variantId == primaryVariantId;
      final isHovered = s.variantId == hoveredVariantId;

      if (isPrimary || isHovered) {
        final highlightRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            4,
            topMargin + slotHeight * i + 2,
            size.width - 8,
            math.max(8.0, slotHeight - 4),
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          highlightRect,
          Paint()
            ..color = (isPrimary
                    ? AppColors.goldAccent
                    : AppColors.cyanAccent)
                .withValues(alpha: isHovered ? 0.12 : 0.08),
        );
      }

      // Etykieta wariantu po lewej
      final namePainter = TextPainter(
        text: TextSpan(
          text: s.variantName,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
            color: isPrimary ? AppColors.goldAccent : AppColors.textPrimary,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftMargin - 16);
      namePainter.paint(
        canvas,
        Offset(8, cy - namePainter.height / 2),
      );

      final color = isPrimary ? AppColors.goldAccent : s.riskLevel.color;
      final xMin = valueToX(s.min);
      final xQ1 = valueToX(s.q1);
      final xMed = valueToX(s.median);
      final xQ3 = valueToX(s.q3);
      final xMax = valueToX(s.max);
      final xMean = valueToX(s.mean);

      final whiskerPaint = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      // Wąsy Min - Q1 i Q3 - Max
      canvas.drawLine(Offset(xMin, cy), Offset(xQ1, cy), whiskerPaint);
      canvas.drawLine(Offset(xQ3, cy), Offset(xMax, cy), whiskerPaint);
      const capHalf = 6.0;
      canvas.drawLine(
        Offset(xMin, cy - capHalf),
        Offset(xMin, cy + capHalf),
        whiskerPaint,
      );
      canvas.drawLine(
        Offset(xMax, cy - capHalf),
        Offset(xMax, cy + capHalf),
        whiskerPaint,
      );

      // Pudełko Q1–Q3
      final boxHalfH = math.min(13.0, slotHeight * 0.28);
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          math.min(xQ1, xQ3),
          cy - boxHalfH,
          math.max(xQ1, xQ3).clamp(math.min(xQ1, xQ3) + 2.0, size.width),
          cy + boxHalfH,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        boxRect,
        Paint()..color = color.withValues(alpha: 0.26),
      );
      canvas.drawRRect(
        boxRect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = isPrimary ? 1.8 : 1.3,
      );

      // Linia mediany
      canvas.drawLine(
        Offset(xMed, cy - boxHalfH),
        Offset(xMed, cy + boxHalfH),
        Paint()
          ..color = AppColors.textPrimary
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );

      // Diament średniej
      const d = 3.5;
      final diamond = Path()
        ..moveTo(xMean, cy - d)
        ..lineTo(xMean + d, cy)
        ..lineTo(xMean, cy + d)
        ..lineTo(xMean - d, cy)
        ..close();
      canvas.drawPath(
        diamond,
        Paint()..color = AppColors.cyanAccent,
      );

      // Outliery
      final outlierPaint = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      for (final o in s.outliers) {
        final xo = valueToX(o);
        canvas.drawCircle(Offset(xo, cy), 2.5, outlierPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhatIfBoxPlotComparisonPainter oldDelegate) {
    return oldDelegate.stats != stats ||
        oldDelegate.metric != metric ||
        oldDelegate.minVal != minVal ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.primaryVariantId != primaryVariantId ||
        oldDelegate.hoveredVariantId != hoveredVariantId;
  }
}

class _GlassSectionCard extends StatelessWidget {
  const _GlassSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProbabilityStackedBar extends StatelessWidget {
  const _ProbabilityStackedBar({
    required this.winProbability,
    required this.podiumProbability,
    required this.top10Probability,
  });

  final double winProbability;
  final double podiumProbability;
  final double top10Probability;

  @override
  Widget build(BuildContext context) {
    final win = winProbability.clamp(0.0, 1.0);
    final podiumOnly = (podiumProbability - winProbability).clamp(0.0, 1.0);
    final top10Only = (top10Probability - podiumProbability).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 8,
        color: AppColors.background.withValues(alpha: 0.8),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final w = c.maxWidth;
            return Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: w * win,
                  color: AppColors.goldAccent,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: w * podiumOnly,
                  color: AppColors.accentBlue,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: w * top10Only,
                  color: AppColors.statusSuccess.withValues(alpha: 0.75),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VariantChipItem extends StatefulWidget {
  const _VariantChipItem({
    super.key,
    required this.outcome,
    required this.isCompared,
    required this.isPrimary,
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
  });

  final WhatIfVariantOutcome outcome;
  final bool isCompared;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_VariantChipItem> createState() => _VariantChipItemState();
}

class _VariantChipItemState extends State<_VariantChipItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isPrimary
        ? AppColors.goldAccent
        : widget.isCompared
            ? AppColors.accentBlue
            : _hovered || _focused
                ? AppColors.textSecondary
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        onLongPress: widget.enabled ? widget.onLongPress : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isCompared
                ? AppColors.surfaceLight
                : AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: widget.isPrimary ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.outcome.isOptimalRecommended) ...<Widget>[
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.outcome.variant.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight:
                      widget.isCompared ? FontWeight.w600 : FontWeight.w400,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(widget.outcome.winProbability * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.isPrimary
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassActionChip extends StatefulWidget {
  const _GlassActionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_GlassActionChip> createState() => _GlassActionChipState();
}

class _GlassActionChipState extends State<_GlassActionChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.accentColor.withValues(alpha: 0.18)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.surface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected
                  ? widget.accentColor
                  : _focused
                      ? AppColors.textPrimary
                      : AppTheme.borderColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              color: !widget.enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.5)
                  : widget.selected
                      ? widget.accentColor
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconButton extends StatefulWidget {
  const _InteractiveIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.surfaceLight
                  : AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalActionButton extends StatefulWidget {
  const _ModalActionButton({
    super.key,
    required this.label,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_ModalActionButton> createState() => _ModalActionButtonState();
}

class _ModalActionButtonState extends State<_ModalActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.isPrimary
            ? (_pressed
                ? AppColors.goldAccent.withValues(alpha: 0.85)
                : _hovered
                    ? AppColors.goldAccent
                    : AppColors.goldAccent.withValues(alpha: 0.92))
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.surface.withValues(alpha: 0.7));

    final textColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isPrimary
            ? AppColors.background
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.cyanAccent
                    : widget.isPrimary
                        ? AppColors.goldAccent
                        : AppTheme.borderColor,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatInlinePill extends StatelessWidget {
  const _StatInlinePill({
    required this.label,
    required this.value,
    this.highlightColor,
  });

  final String label;
  final String value;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: highlightColor ?? AppColors.textPrimary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MiniMetricText extends StatelessWidget {
  const _MiniMetricText({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
        children: <InlineSpan>[
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaTile extends StatelessWidget {
  const _DeltaTile({
    required this.label,
    required this.value,
    required this.isPositiveGood,
  });

  final String label;
  final String value;
  final bool isPositiveGood;

  @override
  Widget build(BuildContext context) {
    final toneColor =
        isPositiveGood ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: toneColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: toneColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
