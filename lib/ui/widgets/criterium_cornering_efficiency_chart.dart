// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/physics/braking_zone_kinetic_energy_loss_solver.dart';
import '../../models/equipment/wheelset_model.dart';

/// Tryb wizualizacji wykresu efektywności kół w zakrętach.
enum CriteriumChartViewMode {
  cumulativeGainCurve('Krzywa zysku czasowego', 'Time Gain Curve'),
  cornerBreakdown('Straty na zakrętach', 'Corner Breakdown');

  final String labelPl;
  final String labelEn;

  const CriteriumChartViewMode(this.labelPl, this.labelEn);
}

/// Punkt danych na krzywej zysku czasowego względem liczby okrążeń / zakrętów.
class CriteriumLapEfficiencyPoint {
  final int laps;
  final int totalCorners;
  final double distanceKm;
  final double netTimeGainSeconds;
  final double cornerReaccelGainSeconds;
  final double aeroStraightDeltaSeconds;
  final double rotationalEnergySavedKj;
  final double wPrimeSavedKj;

  const CriteriumLapEfficiencyPoint({
    required this.laps,
    required this.totalCorners,
    required this.distanceKm,
    required this.netTimeGainSeconds,
    required this.cornerReaccelGainSeconds,
    required this.aeroStraightDeltaSeconds,
    required this.rotationalEnergySavedKj,
    required this.wPrimeSavedKj,
  });
}

/// Interaktywny wykres zysku czasowego lekkich kół na trasach z licznymi zakrętami.
///
/// Wykorzystuje [BrakingZoneKineticEnergyLossSolver] do obliczania rzeczywistego
/// bilansu między niższą bezwładnością obrotową lekkich kół na wyjściach z zakrętów
/// a przewagą aerodynamiczną cięższych kół stożkowych na prostych.
class CriteriumCorneringEfficiencyChart extends StatefulWidget {
  final BrakingCourseDiscipline initialDiscipline;
  final WheelsetModel? lightWheelset;
  final WheelsetModel? aeroWheelset;
  final BrakingZoneRiderConfig baseRiderConfig;
  final List<BrakingCornerSpec>? customCorners;
  final int? initialLaps;
  final bool enabled;
  final bool useEnglishLabels;
  final ValueChanged<WheelsetBrakingComparisonResult>? onComparisonChanged;

  const CriteriumCorneringEfficiencyChart({
    super.key,
    this.initialDiscipline = BrakingCourseDiscipline.urbanCriterium,
    this.lightWheelset,
    this.aeroWheelset,
    this.baseRiderConfig = const BrakingZoneRiderConfig(),
    this.customCorners,
    this.initialLaps,
    this.enabled = true,
    this.useEnglishLabels = false,
    this.onComparisonChanged,
  });

  /// Domyślne presety lekkich i aerodynamicznych kół do szybkiego porównania.
  static const List<WheelsetModel> defaultLightWheelsets = [
    WheelsetModel(
      id: 'ws_feather_28',
      brandId: 'brand_alpine',
      name: 'FeatherLite 28mm',
      rimDepthMm: 28,
      weightGrams: 1160,
      aeroCdaModifier: -0.002,
      crosswindStabilityPenalty: 0.05,
      momentOfInertia: 0.088,
      hubEngagementDragWatts: 1.2,
      priceEur: 2850,
    ),
    WheelsetModel(
      id: 'ws_allround_38',
      brandId: 'brand_alpine',
      name: 'CritMaster 38mm',
      rimDepthMm: 38,
      weightGrams: 1290,
      aeroCdaModifier: -0.005,
      crosswindStabilityPenalty: 0.14,
      momentOfInertia: 0.102,
      hubEngagementDragWatts: 1.4,
      priceEur: 2400,
    ),
  ];

  static const List<WheelsetModel> defaultAeroWheelsets = [
    WheelsetModel(
      id: 'ws_aero_62',
      brandId: 'brand_vortex',
      name: 'Vortex Aero 62mm',
      rimDepthMm: 62,
      weightGrams: 1580,
      aeroCdaModifier: -0.011,
      crosswindStabilityPenalty: 0.48,
      momentOfInertia: 0.144,
      hubEngagementDragWatts: 1.5,
      priceEur: 2950,
    ),
    WheelsetModel(
      id: 'ws_deep_80',
      brandId: 'brand_vortex',
      name: 'Blade TT 80mm',
      rimDepthMm: 80,
      weightGrams: 1740,
      aeroCdaModifier: -0.015,
      crosswindStabilityPenalty: 0.72,
      momentOfInertia: 0.168,
      hubEngagementDragWatts: 1.7,
      priceEur: 3300,
    ),
  ];

  @override
  State<CriteriumCorneringEfficiencyChart> createState() =>
      _CriteriumCorneringEfficiencyChartState();
}

class _CriteriumCorneringEfficiencyChartState
    extends State<CriteriumCorneringEfficiencyChart>
    with SingleTickerProviderStateMixin {
  late BrakingCourseDiscipline _discipline;
  late CriteriumChartViewMode _viewMode;
  late WheelsetModel _selectedLight;
  late WheelsetModel _selectedAero;
  late bool _isWetSurface;
  late int _lapCount;
  int? _hoveredIndex;

  late AnimationController _animController;
  late Animation<double> _revealAnimation;

  late WheelsetBrakingComparisonResult _comparison;
  late List<CriteriumLapEfficiencyPoint> _curvePoints;

  @override
  void initState() {
    super.initState();
    _discipline = widget.initialDiscipline;
    _viewMode = CriteriumChartViewMode.cumulativeGainCurve;
    _selectedLight =
        widget.lightWheelset ??
        CriteriumCorneringEfficiencyChart.defaultLightWheelsets.first;
    _selectedAero =
        widget.aeroWheelset ??
        CriteriumCorneringEfficiencyChart.defaultAeroWheelsets.first;
    _isWetSurface = widget.baseRiderConfig.surfaceWetness > 0.25;
    _lapCount = widget.initialLaps ?? _defaultLapsForDiscipline(_discipline);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _revealAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _recomputePhysics(notifyParent: false);
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant CriteriumCorneringEfficiencyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    var shouldRecompute = false;
    if (widget.lightWheelset != null &&
        widget.lightWheelset != oldWidget.lightWheelset) {
      _selectedLight = widget.lightWheelset!;
      shouldRecompute = true;
    }
    if (widget.aeroWheelset != null &&
        widget.aeroWheelset != oldWidget.aeroWheelset) {
      _selectedAero = widget.aeroWheelset!;
      shouldRecompute = true;
    }
    if (widget.baseRiderConfig != oldWidget.baseRiderConfig ||
        widget.customCorners != oldWidget.customCorners) {
      shouldRecompute = true;
    }
    if (shouldRecompute) {
      _recomputePhysics(notifyParent: false);
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int _defaultLapsForDiscipline(BrakingCourseDiscipline discipline) {
    switch (discipline) {
      case BrakingCourseDiscipline.urbanCriterium:
        return 30;
      case BrakingCourseDiscipline.technicalCircuit:
        return 12;
      case BrakingCourseDiscipline.twistyTimeTrial:
        return 2;
      case BrakingCourseDiscipline.urbanPrologue:
        return 1;
    }
  }

  List<BrakingCornerSpec> _resolveCorners() {
    if (widget.customCorners != null && widget.customCorners!.isNotEmpty) {
      return widget.customCorners!;
    }
    switch (_discipline) {
      case BrakingCourseDiscipline.urbanCriterium:
        return BrakingZoneKineticEnergyLossSolver.urbanFourCornerCriterium();
      case BrakingCourseDiscipline.technicalCircuit:
        return BrakingZoneKineticEnergyLossSolver.technicalEightCornerCriterium();
      case BrakingCourseDiscipline.twistyTimeTrial:
      case BrakingCourseDiscipline.urbanPrologue:
        return BrakingZoneKineticEnergyLossSolver.twistyUrbanTimeTrial();
    }
  }

  void _recomputePhysics({bool notifyParent = true}) {
    final corners = _resolveCorners();
    final config = widget.baseRiderConfig.copyWith(
      surfaceWetness: _isWetSurface ? 0.72 : 0.0,
    );

    // wheelsetA = cięższe aero, wheelsetB = lekkie -> dodatnia delta oznacza zysk lekkich kół.
    _comparison = BrakingZoneKineticEnergyLossSolver.compareWheelsetsOnCourse(
      discipline: _discipline,
      lapCorners: corners,
      baseConfig: config,
      wheelsetA: _selectedAero,
      wheelsetB: _selectedLight,
      laps: _lapCount,
    );

    final sampleSteps = _buildLapSampleSteps(_lapCount);
    final points = <CriteriumLapEfficiencyPoint>[];
    final singleLapDistanceKm = corners.fold<double>(
          0.0,
          (sum, c) => sum + c.arcLengthMeters + c.straightLengthAfterMeters,
        ) /
        1000.0;

    for (final stepLaps in sampleSteps) {
      final stepComparison =
          BrakingZoneKineticEnergyLossSolver.compareWheelsetsOnCourse(
        discipline: _discipline,
        lapCorners: corners,
        baseConfig: config,
        wheelsetA: _selectedAero,
        wheelsetB: _selectedLight,
        laps: stepLaps,
      );
      points.add(
        CriteriumLapEfficiencyPoint(
          laps: stepLaps,
          totalCorners: stepLaps * corners.length,
          distanceKm: stepLaps * singleLapDistanceKm,
          netTimeGainSeconds: stepComparison.netTimeDeltaSeconds,
          cornerReaccelGainSeconds:
              stepComparison.cornerReaccelTimeDeltaSeconds,
          aeroStraightDeltaSeconds:
              stepComparison.aeroStraightTimeDeltaSeconds,
          rotationalEnergySavedKj: stepComparison.rotationalEnergySavedKj,
          wPrimeSavedKj: stepComparison.wPrimeSavedKj,
        ),
      );
    }

    _curvePoints = points;
    _hoveredIndex = null;

    if (notifyParent) {
      widget.onComparisonChanged?.call(_comparison);
    }
  }

  List<int> _buildLapSampleSteps(int maxLaps) {
    final safeMax = math.max(1, maxLaps);
    if (safeMax <= 8) {
      return List<int>.generate(safeMax, (i) => i + 1);
    }
    const targetBuckets = 8;
    final steps = <int>{1};
    for (var i = 1; i < targetBuckets; i++) {
      final val = ((safeMax - 1) * i / (targetBuckets - 1)).round() + 1;
      steps.add(val.clamp(1, safeMax));
    }
    steps.add(safeMax);
    final sorted = steps.toList()..sort();
    return sorted;
  }

  void _selectDiscipline(BrakingCourseDiscipline discipline) {
    if (!widget.enabled || _discipline == discipline) return;
    setState(() {
      _discipline = discipline;
      _lapCount = _defaultLapsForDiscipline(discipline);
      _recomputePhysics();
    });
    _animController.forward(from: 0.0);
  }

  void _selectViewMode(CriteriumChartViewMode mode) {
    if (!widget.enabled || _viewMode == mode) return;
    setState(() {
      _viewMode = mode;
      _hoveredIndex = null;
    });
    _animController.forward(from: 0.0);
  }

  void _toggleWetSurface() {
    if (!widget.enabled) return;
    setState(() {
      _isWetSurface = !_isWetSurface;
      _recomputePhysics();
    });
    _animController.forward(from: 0.0);
  }

  void _adjustLaps(int delta) {
    if (!widget.enabled) return;
    final next = (_lapCount + delta).clamp(1, 60);
    if (next == _lapCount) return;
    setState(() {
      _lapCount = next;
      _recomputePhysics();
    });
    _animController.forward(from: 0.0);
  }

  void _cycleLightWheelset() {
    if (!widget.enabled) return;
    const presets = CriteriumCorneringEfficiencyChart.defaultLightWheelsets;
    final idx = presets.indexWhere((w) => w.id == _selectedLight.id);
    final next = presets[(idx + 1) % presets.length];
    setState(() {
      _selectedLight = next;
      _recomputePhysics();
    });
    _animController.forward(from: 0.0);
  }

  void _cycleAeroWheelset() {
    if (!widget.enabled) return;
    const presets = CriteriumCorneringEfficiencyChart.defaultAeroWheelsets;
    final idx = presets.indexWhere((w) => w.id == _selectedAero.id);
    final next = presets[(idx + 1) % presets.length];
    setState(() {
      _selectedAero = next;
      _recomputePhysics();
    });
    _animController.forward(from: 0.0);
  }

  String _tr(String pl, String en) => widget.useEnglishLabels ? en : pl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isCompact = maxWidth < 600;
        final isWide = maxWidth >= 1000;
        final chartHeight = isCompact
            ? 210.0
            : isWide
                ? 270.0
                : 240.0;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.58,
          child: Container(
            padding: EdgeInsets.all(isCompact ? 14 : 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 14),
                _buildControlBar(isCompact),
                const SizedBox(height: 14),
                _buildKpiRow(isCompact),
                const SizedBox(height: 16),
                _buildChartContainer(chartHeight, isCompact),
                const SizedBox(height: 12),
                _buildLegendAndVerdict(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final lightFaster = _comparison.netTimeDeltaSeconds >= 0;
    final deltaAbs = _comparison.netTimeDeltaSeconds.abs();
    final badgeColor =
        lightFaster ? AppColors.statusSuccess : AppColors.accentBlue;
    final badgeText = lightFaster
        ? '+${deltaAbs.toStringAsFixed(2)} s (${_selectedLight.name})'
        : '+${deltaAbs.toStringAsFixed(2)} s (${_selectedAero.name})';

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.goldAccent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _tr(
                  'Efektywność Kół na Trasach Krętych',
                  'Criterium Cornering Wheelset Efficiency',
                ),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _tr(
            'Bilans bezwładności obrotowej (${_selectedLight.weightGrams} g) vs aero (${_selectedAero.rimDepthMm} mm)',
            'Rotational inertia (${_selectedLight.weightGrams} g) vs aero drag (${_selectedAero.rimDepthMm} mm)',
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            letterSpacing: -0.1,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: badgeColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          badge,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        badge,
      ],
    );
  }

  Widget _buildControlBar(bool isCompact) {
    final disciplines = [
      (
        BrakingCourseDiscipline.urbanCriterium,
        _tr('Kryterium 4-zakr.', '4-Turn Crit')
      ),
      (
        BrakingCourseDiscipline.technicalCircuit,
        _tr('Techniczny 8-zakr.', '8-Turn Tech')
      ),
      (
        BrakingCourseDiscipline.twistyTimeTrial,
        _tr('Kręta Czasówka', 'Twisty ITT')
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in disciplines)
          _ChartInteractiveChip(
            label: entry.$2,
            isActive: _discipline == entry.$1,
            enabled: widget.enabled,
            accentColor: AppColors.primaryAccent,
            onPressed: () => _selectDiscipline(entry.$1),
          ),
        _ChartInteractiveChip(
          label: _viewMode == CriteriumChartViewMode.cumulativeGainCurve
              ? _tr('Widok: Krzywa', 'View: Curve')
              : _tr('Widok: Zakręty', 'View: Corners'),
          icon: Icons.bar_chart_rounded,
          isActive: _viewMode == CriteriumChartViewMode.cornerBreakdown,
          enabled: widget.enabled,
          accentColor: AppColors.cyanAccent,
          onPressed: () => _selectViewMode(
            _viewMode == CriteriumChartViewMode.cumulativeGainCurve
                ? CriteriumChartViewMode.cornerBreakdown
                : CriteriumChartViewMode.cumulativeGainCurve,
          ),
        ),
        _ChartInteractiveChip(
          label: _isWetSurface ? _tr('Mokro', 'Wet') : _tr('Sucho', 'Dry'),
          icon: _isWetSurface ? Icons.water_drop_rounded : Icons.wb_sunny_rounded,
          isActive: _isWetSurface,
          enabled: widget.enabled,
          accentColor: AppColors.accentBlue,
          onPressed: _toggleWetSurface,
        ),
        _ChartInteractiveChip(
          label: '${_selectedLight.weightGrams}g vs ${_selectedAero.weightGrams}g',
          icon: Icons.tire_repair_rounded,
          isActive: false,
          enabled: widget.enabled,
          accentColor: AppColors.goldAccent,
          onPressed: () {
            _cycleLightWheelset();
          },
        ),
        _ChartInteractiveChip(
          label: '${_selectedAero.rimDepthMm}mm',
          icon: Icons.air_rounded,
          isActive: false,
          enabled: widget.enabled,
          accentColor: AppColors.accentBlue,
          onPressed: _cycleAeroWheelset,
        ),
        _LapStepperControl(
          laps: _lapCount,
          enabled: widget.enabled,
          label: _tr('Okr.', 'Laps'),
          onDecrement: () => _adjustLaps(-2),
          onIncrement: () => _adjustLaps(2),
        ),
      ],
    );
  }

  Widget _buildKpiRow(bool isCompact) {
    final lightFaster = _comparison.netTimeDeltaSeconds >= 0;
    final netColor =
        lightFaster ? AppColors.statusSuccess : AppColors.accentBlue;
    final netSign = _comparison.netTimeDeltaSeconds >= 0 ? '+' : '';

    final items = [
      _KpiItemData(
        label: _tr('Zysk Netto (Lekkie)', 'Net Gain (Light)'),
        value: '$netSign${_comparison.netTimeDeltaSeconds.toStringAsFixed(2)} s',
        subLabel: _tr(
          '${_comparison.profileB.totalBrakingEvents} hamowań',
          '${_comparison.profileB.totalBrakingEvents} brakings',
        ),
        accent: netColor,
      ),
      _KpiItemData(
        label: _tr('Oszczędność Obrotowa', 'Rotational Saved'),
        value: '${_comparison.rotationalEnergySavedKj.toStringAsFixed(1)} kJ',
        subLabel: _tr(
          'Wyjścia z zakrętów',
          'Corner re-accel',
        ),
        accent: AppColors.goldAccent,
      ),
      _KpiItemData(
        label: _tr('Zysk na Zakrętach', 'Corner Exit Delta'),
        value:
            '${_comparison.cornerReaccelTimeDeltaSeconds >= 0 ? '+' : ''}${_comparison.cornerReaccelTimeDeltaSeconds.toStringAsFixed(2)} s',
        subLabel: _tr(
          'Aero proste: ${_comparison.aeroStraightTimeDeltaSeconds.toStringAsFixed(2)} s',
          'Aero straight: ${_comparison.aeroStraightTimeDeltaSeconds.toStringAsFixed(2)} s',
        ),
        accent: AppColors.cyanAccent,
      ),
      _KpiItemData(
        label: _tr('Oszczędność W\'', 'W\' Reserve Saved'),
        value: '${_comparison.wPrimeSavedKj.toStringAsFixed(2)} kJ',
        subLabel: _tr(
          'Mniej zrywów beztlen.',
          'Less anaerobic burn',
        ),
        accent: AppColors.amberWarning,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _KpiMetricCard(data: items[0])),
              const SizedBox(width: 8),
              Expanded(child: _KpiMetricCard(data: items[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _KpiMetricCard(data: items[2])),
              const SizedBox(width: 8),
              Expanded(child: _KpiMetricCard(data: items[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _KpiMetricCard(data: items[i])),
        ],
      ],
    );
  }

  Widget _buildChartContainer(double chartHeight, bool isCompact) {
    return Container(
      height: chartHeight,
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          return MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.precise
                : SystemMouseCursors.basic,
            onHover: widget.enabled
                ? (event) => _updateHoveredPoint(event.localPosition, box.biggest)
                : null,
            onExit: (_) {
              if (_hoveredIndex != null) {
                setState(() => _hoveredIndex = null);
              }
            },
            child: GestureDetector(
              onTapDown: widget.enabled
                  ? (details) =>
                      _updateHoveredPoint(details.localPosition, box.biggest)
                  : null,
              onHorizontalDragUpdate: widget.enabled
                  ? (details) =>
                      _updateHoveredPoint(details.localPosition, box.biggest)
                  : null,
              child: AnimatedBuilder(
                animation: _revealAnimation,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: _viewMode ==
                                CriteriumChartViewMode.cumulativeGainCurve
                            ? CustomPaint(
                                painter: CriteriumCorneringCurvePainter(
                                  points: _curvePoints,
                                  progress: _revealAnimation.value,
                                  hoveredIndex: _hoveredIndex,
                                  useEnglishLabels: widget.useEnglishLabels,
                                ),
                              )
                            : CustomPaint(
                                painter: CriteriumCornerBreakdownPainter(
                                  lightCorners:
                                      _comparison.profileB.cornerResults,
                                  aeroCorners:
                                      _comparison.profileA.cornerResults,
                                  progress: _revealAnimation.value,
                                  hoveredIndex: _hoveredIndex,
                                ),
                              ),
                      ),
                      if (_hoveredIndex != null)
                        _buildHoverTooltip(isCompact),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateHoveredPoint(Offset localPos, Size size) {
    const leftPad = 48.0;
    const rightPad = 14.0;
    final plotWidth = math.max(1.0, size.width - leftPad - rightPad);
    final relX = ((localPos.dx - leftPad) / plotWidth).clamp(0.0, 1.0);

    final count = _viewMode == CriteriumChartViewMode.cumulativeGainCurve
        ? _curvePoints.length
        : _comparison.profileB.cornerResults.length;
    if (count == 0) return;

    final idx = count == 1 ? 0 : (relX * (count - 1)).round().clamp(0, count - 1);
    if (idx != _hoveredIndex) {
      setState(() => _hoveredIndex = idx);
    }
  }

  Widget _buildHoverTooltip(bool isCompact) {
    final idx = _hoveredIndex;
    if (idx == null) return const SizedBox.shrink();

    if (_viewMode == CriteriumChartViewMode.cumulativeGainCurve) {
      if (idx < 0 || idx >= _curvePoints.length) return const SizedBox.shrink();
      final pt = _curvePoints[idx];
      final sign = pt.netTimeGainSeconds >= 0 ? '+' : '';
      return Positioned(
        top: 4,
        right: 6,
        child: _TooltipPill(
          title:
              '${pt.laps} ${_tr('okr.', 'laps')} (${pt.totalCorners} ${_tr('zakr.', 'turns')})',
          line1:
              '${_tr('Bilans', 'Net')}: $sign${pt.netTimeGainSeconds.toStringAsFixed(2)} s',
          line2:
              '${_tr('Rotacja', 'Rot.')}: ${pt.rotationalEnergySavedKj.toStringAsFixed(1)} kJ  |  W\': ${pt.wPrimeSavedKj.toStringAsFixed(2)} kJ',
          accent: pt.netTimeGainSeconds >= 0
              ? AppColors.statusSuccess
              : AppColors.accentBlue,
        ),
      );
    }

    final lightCorners = _comparison.profileB.cornerResults;
    final aeroCorners = _comparison.profileA.cornerResults;
    if (idx < 0 || idx >= lightCorners.length || idx >= aeroCorners.length) {
      return const SizedBox.shrink();
    }
    final lc = lightCorners[idx];
    final ac = aeroCorners[idx];
    final timeSavedMs = (ac.timeLostSeconds - lc.timeLostSeconds) * 1000.0;
    final rotSavedJ =
        ac.rotationalEnergyLossJoules - lc.rotationalEnergyLossJoules;

    return Positioned(
      top: 4,
      right: 6,
      child: _TooltipPill(
        title: lc.cornerName,
        line1:
            '${_tr('Zysk/zakręt', 'Gain/turn')}: +${timeSavedMs.toStringAsFixed(0)} ms',
        line2:
            '${_tr('Energia obr.', 'Rot. saved')}: +${rotSavedJ.toStringAsFixed(0)} J',
        accent: AppColors.goldAccent,
      ),
    );
  }

  Widget _buildLegendAndVerdict(bool isCompact) {
    final summaryText = widget.useEnglishLabels
        ? _comparison.summaryReasonEn
        : _comparison.summaryReasonPl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(
                color: AppColors.statusSuccess,
                label: _tr(
                  'Przewaga lekkich kół (${_selectedLight.name})',
                  'Light wheels faster (${_selectedLight.name})',
                ),
              ),
              _LegendDot(
                color: AppColors.accentBlue,
                label: _tr(
                  'Przewaga kół aero (${_selectedAero.name})',
                  'Aero wheels faster (${_selectedAero.name})',
                ),
              ),
              _LegendDot(
                color: AppColors.goldAccent,
                label: _tr('Punkt równowagi (0.00 s)', 'Break-even (0.00 s)'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summaryText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 11.5 : 12.5,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter rysujący krzywą zysku czasowego lekkich kół względem liczby okrążeń.
class CriteriumCorneringCurvePainter extends CustomPainter {
  final List<CriteriumLapEfficiencyPoint> points;
  final double progress;
  final int? hoveredIndex;
  final bool useEnglishLabels;

  const CriteriumCorneringCurvePainter({
    required this.points,
    required this.progress,
    required this.hoveredIndex,
    required this.useEnglishLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPad = 48.0;
    const rightPad = 14.0;
    const topPad = 14.0;
    const bottomPad = 26.0;

    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(10.0, size.width - leftPad - rightPad),
      math.max(10.0, size.height - topPad - bottomPad),
    );

    var minVal = 0.0;
    var maxVal = 0.0;
    for (final p in points) {
      if (p.netTimeGainSeconds < minVal) minVal = p.netTimeGainSeconds;
      if (p.netTimeGainSeconds > maxVal) maxVal = p.netTimeGainSeconds;
    }
    final span = math.max(0.5, maxVal - minVal);
    minVal -= span * 0.14;
    maxVal += span * 0.14;

    double yForValue(double v) {
      final norm = (v - minVal) / math.max(1e-6, maxVal - minVal);
      return chartRect.bottom - norm * chartRect.height;
    }

    double xForIndex(int idx) {
      if (points.length == 1) return chartRect.center.dx;
      return chartRect.left +
          (idx / (points.length - 1)) * chartRect.width;
    }

    // Siatka pozioma i etykiety osi Y.
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    const yTicks = 4;
    for (var i = 0; i <= yTicks; i++) {
      final val = minVal + (maxVal - minVal) * (i / yTicks);
      final y = yForValue(val);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      _drawAxisLabel(
        canvas,
        '${val >= 0 ? '+' : ''}${val.toStringAsFixed(1)}s',
        Offset(2, y - 6),
        width: leftPad - 6,
        align: TextAlign.right,
      );
    }

    // Linia równowagi 0.00 s.
    final zeroY = yForValue(0.0).clamp(chartRect.top, chartRect.bottom);
    final zeroPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.75)
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(chartRect.left, zeroY),
      Offset(chartRect.right, zeroY),
      zeroPaint,
    );

    // Zbuduj ścieżkę krzywej z animacją postępu.
    final linePath = Path();
    final fillPath = Path();
    final coords = <Offset>[];

    for (var i = 0; i < points.length; i++) {
      final x = xForIndex(i);
      final targetY = yForValue(points[i].netTimeGainSeconds);
      final y = zeroY + (targetY - zeroY) * progress;
      coords.add(Offset(x, y));
    }

    if (coords.isNotEmpty) {
      linePath.moveTo(coords.first.dx, coords.first.dy);
      fillPath.moveTo(coords.first.dx, zeroY);
      fillPath.lineTo(coords.first.dx, coords.first.dy);

      for (var i = 1; i < coords.length; i++) {
        final prev = coords[i - 1];
        final curr = coords[i];
        final midX = (prev.dx + curr.dx) * 0.5;
        linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
        fillPath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
      }

      fillPath.lineTo(coords.last.dx, zeroY);
      fillPath.close();

      final lastGain = points.last.netTimeGainSeconds;
      final lineColor =
          lastGain >= 0 ? AppColors.statusSuccess : AppColors.accentBlue;

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.30),
            lineColor.withValues(alpha: 0.03),
          ],
        ).createShader(chartRect);
      canvas.drawPath(fillPath, areaPaint);

      final strokePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, strokePaint);

      // Węzły pomiarowe i etykiety osi X.
      for (var i = 0; i < coords.length; i++) {
        final c = coords[i];
        final pt = points[i];
        final isHovered = hoveredIndex == i;
        final nodeColor = pt.netTimeGainSeconds >= 0
            ? AppColors.statusSuccess
            : AppColors.accentBlue;

        if (isHovered) {
          canvas.drawLine(
            Offset(c.dx, chartRect.top),
            Offset(c.dx, chartRect.bottom),
            Paint()
              ..color = AppColors.textSecondary.withValues(alpha: 0.45)
              ..strokeWidth = 1.0,
          );
        }

        canvas.drawCircle(
          c,
          isHovered ? 5.5 : 3.5,
          Paint()..color = nodeColor,
        );
        canvas.drawCircle(
          c,
          isHovered ? 2.5 : 1.5,
          Paint()..color = AppColors.background,
        );

        final showXLabel = i == 0 ||
            i == coords.length - 1 ||
            coords.length <= 6 ||
            i.isEven;
        if (showXLabel) {
          _drawAxisLabel(
            canvas,
            '${pt.laps} ${useEnglishLabels ? 'L' : 'okr.'}',
            Offset(c.dx - 22, chartRect.bottom + 6),
            width: 44,
            align: TextAlign.center,
          );
        }
      }
    }
  }

  void _drawAxisLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    required TextAlign align,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          color: AppColors.textSecondary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CriteriumCorneringCurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.useEnglishLabels != useEnglishLabels;
  }
}

/// CustomPainter rysujący porównanie strat na poszczególnych zakrętach rundy.
class CriteriumCornerBreakdownPainter extends CustomPainter {
  final List<BrakingZoneEnergyResult> lightCorners;
  final List<BrakingZoneEnergyResult> aeroCorners;
  final double progress;
  final int? hoveredIndex;

  const CriteriumCornerBreakdownPainter({
    required this.lightCorners,
    required this.aeroCorners,
    required this.progress,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = math.min(lightCorners.length, aeroCorners.length);
    if (count == 0) return;

    const leftPad = 48.0;
    const rightPad = 14.0;
    const topPad = 14.0;
    const bottomPad = 26.0;

    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(10.0, size.width - leftPad - rightPad),
      math.max(10.0, size.height - topPad - bottomPad),
    );

    var maxLossJ = 100.0;
    for (var i = 0; i < count; i++) {
      maxLossJ = math.max(maxLossJ, aeroCorners[i].rotationalEnergyLossJoules);
      maxLossJ = math.max(maxLossJ, lightCorners[i].rotationalEnergyLossJoules);
    }
    maxLossJ *= 1.15;

    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    for (var i = 0; i <= 3; i++) {
      final frac = i / 3.0;
      final y = chartRect.bottom - frac * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final labelTp = TextPainter(
        text: TextSpan(
          text: '${(maxLossJ * frac).round()} J',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: leftPad - 6, maxWidth: leftPad - 6);
      labelTp.paint(canvas, Offset(2, y - 6));
    }

    final slotWidth = chartRect.width / count;
    final barWidth = math.min(18.0, slotWidth * 0.28);

    for (var i = 0; i < count; i++) {
      final centerX = chartRect.left + slotWidth * (i + 0.5);
      final isHovered = hoveredIndex == i;

      if (isHovered) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              chartRect.left + slotWidth * i + 2,
              chartRect.top,
              slotWidth - 4,
              chartRect.height,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = AppColors.surfaceLight.withValues(alpha: 0.45),
        );
      }

      final lightH =
          (lightCorners[i].rotationalEnergyLossJoules / maxLossJ) *
              chartRect.height *
              progress;
      final aeroH =
          (aeroCorners[i].rotationalEnergyLossJoules / maxLossJ) *
              chartRect.height *
              progress;

      final lightRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          centerX - barWidth - 2,
          chartRect.bottom - lightH,
          barWidth,
          lightH,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final aeroRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          centerX + 2,
          chartRect.bottom - aeroH,
          barWidth,
          aeroH,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      canvas.drawRRect(
        lightRect,
        Paint()..color = AppColors.statusSuccess,
      );
      canvas.drawRRect(
        aeroRect,
        Paint()..color = AppColors.accentBlue,
      );

      final xTp = TextPainter(
        text: TextSpan(
          text: 'C${i + 1}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
            color: isHovered ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: slotWidth, maxWidth: slotWidth);
      xTp.paint(
        canvas,
        Offset(chartRect.left + slotWidth * i, chartRect.bottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CriteriumCornerBreakdownPainter oldDelegate) {
    return oldDelegate.lightCorners != lightCorners ||
        oldDelegate.aeroCorners != aeroCorners ||
        oldDelegate.progress != progress ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

class _ChartInteractiveChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _ChartInteractiveChip({
    required this.label,
    this.icon,
    required this.isActive,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_ChartInteractiveChip> createState() => _ChartInteractiveChipState();
}

class _ChartInteractiveChipState extends State<_ChartInteractiveChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isActive
            ? widget.accentColor.withValues(alpha: 0.22)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.isActive
                ? widget.accentColor
                : _hovered
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : AppColors.cardBorder;

    final textColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.isActive
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
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
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 14, color: textColor),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

class _LapStepperControl extends StatelessWidget {
  final int laps;
  final bool enabled;
  final String label;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _LapStepperControl({
    required this.laps,
    required this.enabled,
    required this.label,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIconBtn(
            icon: Icons.remove_rounded,
            enabled: enabled && laps > 1,
            onPressed: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$laps $label',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepperIconBtn(
            icon: Icons.add_rounded,
            enabled: enabled && laps < 60,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepperIconBtn extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _StepperIconBtn({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_StepperIconBtn> createState() => _StepperIconBtnState();
}

class _StepperIconBtnState extends State<_StepperIconBtn> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _hovered && widget.enabled
                ? AppColors.surfaceLight
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: _focused
                ? Border.all(color: AppColors.goldAccent, width: 1.2)
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: widget.enabled
                ? AppColors.textPrimary
                : AppColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _KpiItemData {
  final String label;
  final String value;
  final String subLabel;
  final Color accent;

  const _KpiItemData({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.accent,
  });
}

class _KpiMetricCard extends StatelessWidget {
  final _KpiItemData data;

  const _KpiMetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: data.accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.subLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TooltipPill extends StatelessWidget {
  final String title;
  final String line1;
  final String line2;
  final Color accent;

  const _TooltipPill({
    required this.title,
    required this.line1,
    required this.line2,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.65), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            line1,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            line2,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
