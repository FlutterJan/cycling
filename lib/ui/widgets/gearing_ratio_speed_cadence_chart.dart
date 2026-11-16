// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../models/equipment/drivetrain_gearing_configuration.dart';

/// Pojedynczy punkt danych na wykresie przełożeń dla konkretnej kombinacji tarczy i koronki.
class GearingRatioGearPoint {
  /// Numer biegu w kolejności rosnącego przełożenia (1..24 dla 2x12, 1..12 dla 1x12).
  final int gearNumber;

  /// Indeks koronki na kasecie (0 = najmniejsza/najtwardsza, 11 = największa/najlżejsza).
  final int cogIndex;

  /// Liczba zębów przedniej tarczy.
  final int frontTeeth;

  /// Liczba zębów tylnej koronki kasety.
  final int rearTeeth;

  /// Czy bieg korzysta z dużej (zewnętrznej) tarczy korby.
  final bool isOuterRing;

  /// Czy kombinacja powoduje przekos łańcucha (cross-chain).
  final bool isCrossChained;

  /// Przełożenie `frontTeeth / rearTeeth`.
  final double ratio;

  /// Prędkość [km/h] przy referencyjnej kadencji (domyślnie 90 RPM).
  final double speedAtReferenceCadenceKmh;

  /// Prędkość [km/h] przy minimalnej kadencji podjazdowej (domyślnie 70 RPM).
  final double speedAtMinClimbCadenceKmh;

  /// Prędkość [km/h] przy wysokiej kadencji sprinterskiej/zjazdowej (110 RPM).
  final double speedAtHighCadenceKmh;

  const GearingRatioGearPoint({
    required this.gearNumber,
    required this.cogIndex,
    required this.frontTeeth,
    required this.rearTeeth,
    required this.isOuterRing,
    required this.isCrossChained,
    required this.ratio,
    required this.speedAtReferenceCadenceKmh,
    required this.speedAtMinClimbCadenceKmh,
    required this.speedAtHighCadenceKmh,
  });

  /// Etykieta przełożenia, np. `52x14T`.
  String get label => '${frontTeeth}x${rearTeeth}T';
}

/// Podsumowanie analizy przełożeń dla podjazdu 15% i zakresu prędkości.
class GearingSteepClimbSummary {
  /// Minimalna prędkość [km/h] na najlżejszym biegu bez spadku poniżej 70 RPM.
  final double minSpeedAt70RpmKmh;

  /// Maksymalna prędkość [km/h] na najtwardszym biegu przy referencyjnej kadencji (90 RPM).
  final double maxSpeedAtReferenceRpmKmh;

  /// Maksymalna prędkość [km/h] na najtwardszym biegu przy 110 RPM (dokręcanie na zjeździe).
  final double maxSpeedAt110RpmKmh;

  /// Szacowana moc [W] wymagana do utrzymania minimalnej prędkości (70 RPM) na podjeździe 15%.
  final double requiredPowerWattsAt15Percent;

  /// Szacowana moc względna [W/kg] na podjeździe 15% przy 70 RPM.
  final double requiredWattsPerKgAt15Percent;

  /// Najlżejsze przełożenie (np. `34x34T`).
  final String easiestGearLabel;

  /// Najtwardsze przełożenie (np. `54x11T`).
  final String hardestGearLabel;

  /// Najlżejszy stosunek zębów.
  final double easiestRatio;

  /// Najtwardszy stosunek zębów.
  final double hardestRatio;

  const GearingSteepClimbSummary({
    required this.minSpeedAt70RpmKmh,
    required this.maxSpeedAtReferenceRpmKmh,
    required this.maxSpeedAt110RpmKmh,
    required this.requiredPowerWattsAt15Percent,
    required this.requiredWattsPerKgAt15Percent,
    required this.easiestGearLabel,
    required this.hardestGearLabel,
    required this.easiestRatio,
    required this.hardestRatio,
  });
}

/// Kalkulator punktów wykresu i telemetrii podjazdu 15% dla [DrivetrainGearingConfiguration].
class GearingRatioChartCalculator {
  GearingRatioChartCalculator._();

  static const double defaultReferenceCadenceRpm = 90.0;
  static const double defaultMinClimbCadenceRpm = 70.0;
  static const double defaultSteepGradePercent = 15.0;
  static const double defaultRiderWeightKg = 68.0;
  static const double defaultBikeWeightKg = 7.2;

  /// Generuje posortowaną listę biegów (do 24 biegów dla 2x12, 12 dla 1x12).
  static List<GearingRatioGearPoint> buildGearPoints(
    DrivetrainGearingConfiguration config, {
    double referenceCadenceRpm = defaultReferenceCadenceRpm,
    double minClimbCadenceRpm = defaultMinClimbCadenceRpm,
  }) {
    final raw = <GearingRatioGearPoint>[];
    final cogs = config.cassetteCogs;

    for (final front in config.frontChainrings) {
      final isOuter = front == config.chainring.outerTeeth;
      for (var cogIdx = 0; cogIdx < cogs.length; cogIdx++) {
        final rear = cogs[cogIdx];
        final ratio = front / rear;
        final isCrossChained = !config.chainring.isSingleRing1x &&
            ((isOuter && cogIdx >= cogs.length - 2) ||
                (!isOuter && cogIdx <= 1));

        raw.add(
          GearingRatioGearPoint(
            gearNumber: 0,
            cogIndex: cogIdx,
            frontTeeth: front,
            rearTeeth: rear,
            isOuterRing: isOuter,
            isCrossChained: isCrossChained,
            ratio: ratio,
            speedAtReferenceCadenceKmh: config.speedKmhAtCadence(
              ratio: ratio,
              cadenceRpm: referenceCadenceRpm,
            ),
            speedAtMinClimbCadenceKmh: config.speedKmhAtCadence(
              ratio: ratio,
              cadenceRpm: minClimbCadenceRpm,
            ),
            speedAtHighCadenceKmh: config.speedKmhAtCadence(
              ratio: ratio,
              cadenceRpm: 110.0,
            ),
          ),
        );
      }
    }

    raw.sort((a, b) {
      final ratioCmp = a.ratio.compareTo(b.ratio);
      if (ratioCmp != 0) return ratioCmp;
      return a.frontTeeth.compareTo(b.frontTeeth);
    });

    return [
      for (var i = 0; i < raw.length; i++)
        GearingRatioGearPoint(
          gearNumber: i + 1,
          cogIndex: raw[i].cogIndex,
          frontTeeth: raw[i].frontTeeth,
          rearTeeth: raw[i].rearTeeth,
          isOuterRing: raw[i].isOuterRing,
          isCrossChained: raw[i].isCrossChained,
          ratio: raw[i].ratio,
          speedAtReferenceCadenceKmh: raw[i].speedAtReferenceCadenceKmh,
          speedAtMinClimbCadenceKmh: raw[i].speedAtMinClimbCadenceKmh,
          speedAtHighCadenceKmh: raw[i].speedAtHighCadenceKmh,
        ),
    ];
  }

  /// Oblicza podsumowanie podjazdu 15% przy minimalnej kadencji 70 RPM.
  static GearingSteepClimbSummary computeSteepClimbSummary(
    DrivetrainGearingConfiguration config, {
    double referenceCadenceRpm = defaultReferenceCadenceRpm,
    double minClimbCadenceRpm = defaultMinClimbCadenceRpm,
    double gradePercent = defaultSteepGradePercent,
    double riderWeightKg = defaultRiderWeightKg,
    double bikeWeightKg = defaultBikeWeightKg,
  }) {
    final easiestRatio = config.easiestGearRatio;
    final hardestRatio = config.hardestGearRatio;

    final minSpeedKmh = config.speedKmhAtCadence(
      ratio: easiestRatio,
      cadenceRpm: minClimbCadenceRpm,
    );
    final maxSpeedRefKmh = config.speedKmhAtCadence(
      ratio: hardestRatio,
      cadenceRpm: referenceCadenceRpm,
    );
    final maxSpeed110Kmh = config.speedKmhAtCadence(
      ratio: hardestRatio,
      cadenceRpm: 110.0,
    );

    final speedMs = minSpeedKmh / 3.6;
    final totalMassKg = math.max(40.0, riderWeightKg + bikeWeightKg);
    final slopeAngleRad = math.atan(gradePercent / 100.0);
    const gravity = 9.80665;
    const crr = 0.0042;
    const airDensity = 1.18;
    const cda = 0.31;

    final fGravity = totalMassKg * gravity * math.sin(slopeAngleRad);
    final fRolling = totalMassKg * gravity * crr * math.cos(slopeAngleRad);
    final fAero = 0.5 * airDensity * cda * speedMs * speedMs;
    final wheelPower = (fGravity + fRolling + fAero) * speedMs;
    final crankPower = wheelPower / config.drivetrainEfficiency;
    final wattsPerKg = crankPower / math.max(40.0, riderWeightKg);

    return GearingSteepClimbSummary(
      minSpeedAt70RpmKmh: minSpeedKmh,
      maxSpeedAtReferenceRpmKmh: maxSpeedRefKmh,
      maxSpeedAt110RpmKmh: maxSpeed110Kmh,
      requiredPowerWattsAt15Percent: crankPower,
      requiredWattsPerKgAt15Percent: wattsPerKg,
      easiestGearLabel:
          '${config.chainring.smallestTeeth}x${config.cassette.largestCog}T',
      hardestGearLabel:
          '${config.chainring.outerTeeth}x${config.cassette.smallestCog}T',
      easiestRatio: easiestRatio,
      hardestRatio: hardestRatio,
    );
  }
}

/// Interaktywny wykres przełożeń napędu dla ekranu Warsztatu / Garażu.
///
/// Prezentuje prędkość [km/h] na każdym z 24 biegów (12 dla napędu 1x) przy
/// wybranej kadencji (domyślnie 90 RPM) oraz minimalną prędkość na podjeździe 15%
/// bez spadku poniżej 70 RPM.
class GearingRatioSpeedCadenceChart extends StatefulWidget {
  /// Początkowa konfiguracja napędu (korba + kaseta).
  final DrivetrainGearingConfiguration initialConfiguration;

  /// Wywołane po zmianie tarczy korby lub kasety w widżecie.
  final ValueChanged<DrivetrainGearingConfiguration>? onConfigurationChanged;

  /// Referencyjna kadencja wykresu [RPM] (domyślnie 90 RPM).
  final double initialReferenceCadenceRpm;

  /// Masa kolarza do obliczenia wymaganej mocy na podjeździe 15% [kg].
  final double riderWeightKg;

  /// Masa roweru do obliczenia wymaganej mocy na podjeździe 15% [kg].
  final double bikeWeightKg;

  /// Czy widżet jest aktywny (obsługa stanu `disabled`).
  final bool enabled;

  const GearingRatioSpeedCadenceChart({
    super.key,
    this.initialConfiguration = const DrivetrainGearingConfiguration(
      chainring: CranksetChainringOption.semiCompact52_36,
      cassette: Cassette12SpeedOption.allRound11_30,
    ),
    this.onConfigurationChanged,
    this.initialReferenceCadenceRpm = 90.0,
    this.riderWeightKg = 68.0,
    this.bikeWeightKg = 7.2,
    this.enabled = true,
  });

  @override
  State<GearingRatioSpeedCadenceChart> createState() =>
      _GearingRatioSpeedCadenceChartState();
}

class _GearingRatioSpeedCadenceChartState
    extends State<GearingRatioSpeedCadenceChart>
    with SingleTickerProviderStateMixin {
  late DrivetrainGearingConfiguration _config;
  late double _referenceCadenceRpm;
  late AnimationController _transitionController;
  late Animation<double> _transitionCurve;

  int? _hoveredGearIndex;
  int? _selectedGearIndex;
  bool _isChartFocused = false;
  bool _hideCrossChained = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfiguration;
    _referenceCadenceRpm = widget.initialReferenceCadenceRpm.clamp(70.0, 120.0);
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..value = 1.0;
    _transitionCurve = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant GearingRatioSpeedCadenceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialConfiguration.chainring !=
            widget.initialConfiguration.chainring ||
        oldWidget.initialConfiguration.cassette !=
            widget.initialConfiguration.cassette ||
        oldWidget.initialConfiguration.wheelCircumferenceMm !=
            widget.initialConfiguration.wheelCircumferenceMm) {
      _config = widget.initialConfiguration;
      _animateUpdate();
    }
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _animateUpdate() {
    _transitionController.forward(from: 0.0);
  }

  void _updateChainring(CranksetChainringOption option) {
    if (!widget.enabled || _config.chainring == option) return;
    setState(() {
      _config = _config.copyWith(chainring: option);
      _selectedGearIndex = null;
      _hoveredGearIndex = null;
    });
    _animateUpdate();
    widget.onConfigurationChanged?.call(_config);
  }

  void _updateCassette(Cassette12SpeedOption option) {
    if (!widget.enabled || _config.cassette == option) return;
    setState(() {
      _config = _config.copyWith(cassette: option);
      _selectedGearIndex = null;
      _hoveredGearIndex = null;
    });
    _animateUpdate();
    widget.onConfigurationChanged?.call(_config);
  }

  List<GearingRatioGearPoint> _filteredPoints() {
    final all = GearingRatioChartCalculator.buildGearPoints(
      _config,
      referenceCadenceRpm: _referenceCadenceRpm,
      minClimbCadenceRpm: 70.0,
    );
    if (!_hideCrossChained) return all;
    return all.where((p) => !p.isCrossChained).toList(growable: false);
  }

  void _handleKeyEvent(KeyEvent event, int totalBars) {
    if (!widget.enabled || event is! KeyDownEvent || totalBars == 0) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        final next = (_selectedGearIndex ?? -1) + 1;
        _selectedGearIndex = next >= totalBars ? 0 : next;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        final prev = (_selectedGearIndex ?? 0) - 1;
        _selectedGearIndex = prev < 0 ? totalBars - 1 : prev;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _selectedGearIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _filteredPoints();
    final summary = GearingRatioChartCalculator.computeSteepClimbSummary(
      _config,
      referenceCadenceRpm: _referenceCadenceRpm,
      minClimbCadenceRpm: 70.0,
      riderWeightKg: widget.riderWeightKg,
      bikeWeightKg: widget.bikeWeightKg,
    );

    final activeIdx = _hoveredGearIndex ?? _selectedGearIndex;
    final activePoint =
        (activeIdx != null && activeIdx >= 0 && activeIdx < points.length)
            ? points[activeIdx]
            : null;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.55,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 520;
          final isMedium =
              constraints.maxWidth >= 520 && constraints.maxWidth < 900;

          return Container(
            padding: EdgeInsets.all(isCompact ? 14 : 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isChartFocused
                    ? AppColors.accentBlue
                    : AppColors.cardBorder,
                width: _isChartFocused ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact, points.length),
                const SizedBox(height: 14),
                _buildSelectors(isCompact),
                const SizedBox(height: 14),
                _buildClimb15TelemetryBanner(summary, isCompact),
                const SizedBox(height: 14),
                _buildCadenceAndFilterBar(isCompact),
                const SizedBox(height: 12),
                _buildChartCanvas(
                  points: points,
                  summary: summary,
                  isCompact: isCompact,
                  isMedium: isMedium,
                ),
                const SizedBox(height: 12),
                _buildLegendAndInspector(
                  points: points,
                  activePoint: activePoint,
                  isCompact: isCompact,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact, int visibleGearCount) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.settings_input_component_rounded,
                color: AppColors.goldAccent,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ANALIZA PRZEŁOŻEŃ & KADENCJI (${_config.chainring.isSingleRing1x ? "12" : "24"} BIEGÓW)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Prędkość na biegach przy ${_referenceCadenceRpm.round()} RPM oraz próg podjazdu 15% (min. 70 RPM)',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        'Zakres ${_config.gearRangePercent.toStringAsFixed(0)}% • $visibleGearCount poz.',
        style: const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.accentBlue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          const SizedBox(height: 8),
          badge,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleWidget),
        const SizedBox(width: 12),
        badge,
      ],
    );
  }

  Widget _buildSelectors(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KORBA (TARCZE)',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CranksetChainringOption.values.map((option) {
              final selected = _config.chainring == option;
              return _InteractiveGearChip(
                label: option.label,
                selected: selected,
                enabled: widget.enabled,
                accentColor: AppColors.goldAccent,
                onTap: () => _updateChainring(option),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          const Text(
            'KASETA 12-RZĘDOWA',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: Cassette12SpeedOption.values.map((option) {
              final selected = _config.cassette == option;
              return _InteractiveGearChip(
                label: option.label,
                selected: selected,
                enabled: widget.enabled,
                accentColor: AppColors.accentBlue,
                onTap: () => _updateCassette(option),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildClimb15TelemetryBanner(
    GearingSteepClimbSummary summary,
    bool isCompact,
  ) {
    final Color statusColor;
    final String statusLabel;
    if (summary.easiestRatio <= 1.15) {
      statusColor = AppColors.statusSuccess;
      statusLabel = 'OPTYMALNE NA 15%';
    } else if (summary.easiestRatio <= 1.32) {
      statusColor = AppColors.amberWarning;
      statusLabel = 'SIŁOWE NA 15%';
    } else {
      statusColor = AppColors.crimsonAlert;
      statusLabel = 'RYZYKO MIELENIA <70 RPM';
    }

    final items = [
      _TelemetryStatTile(
        label: 'MIN. PRĘDKOŚĆ @ 70 RPM (15%)',
        value: '${summary.minSpeedAt70RpmKmh.toStringAsFixed(1)} km/h',
        subtitle:
            'Bieg ${summary.easiestGearLabel} (${summary.easiestRatio.toStringAsFixed(2)})',
        accentColor: statusColor,
      ),
      _TelemetryStatTile(
        label: 'WYMAGANA MOC NA 15% (70 RPM)',
        value: '${summary.requiredPowerWattsAt15Percent.round()} W',
        subtitle:
            '${summary.requiredWattsPerKgAt15Percent.toStringAsFixed(2)} W/kg (${widget.riderWeightKg.round()} kg)',
        accentColor: statusColor,
      ),
      _TelemetryStatTile(
        label: 'MAX PRĘDKOŚĆ @ ${_referenceCadenceRpm.round()} RPM',
        value: '${summary.maxSpeedAtReferenceRpmKmh.toStringAsFixed(1)} km/h',
        subtitle:
            '110 RPM: ${summary.maxSpeedAt110RpmKmh.toStringAsFixed(1)} km/h (${summary.hardestGearLabel})',
        accentColor: AppColors.goldAccent,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.landscape_rounded, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TEST ŚCIANKI 15% BEZ SPADKU PONIŻEJ 70 RPM',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isCompact)
            Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1) const SizedBox(height: 8),
                ],
              ],
            )
          else
            Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(child: items[i]),
                  if (i < items.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCadenceAndFilterBar(bool isCompact) {
    final sliderRow = Row(
      children: [
        const Text(
          'Kadencja:',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${_referenceCadenceRpm.round()} RPM',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.goldAccent,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.16),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _referenceCadenceRpm,
              min: 70,
              max: 120,
              divisions: 10,
              onChanged: widget.enabled
                  ? (val) => setState(() => _referenceCadenceRpm = val)
                  : null,
            ),
          ),
        ),
      ],
    );

    final filterChip = FilterChip(
      selected: _hideCrossChained,
      onSelected: widget.enabled
          ? (v) => setState(() {
                _hideCrossChained = v;
                _selectedGearIndex = null;
                _hoveredGearIndex = null;
              })
          : null,
      label: const Text(
        'Ukryj przekosy',
        style: TextStyle(fontFamily: 'Inter', fontSize: 11),
      ),
      selectedColor: AppColors.primaryAccent.withValues(alpha: 0.35),
      backgroundColor: AppColors.surfaceLight,
      checkmarkColor: AppColors.textPrimary,
      labelStyle: TextStyle(
        color:
            _hideCrossChained ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color:
            _hideCrossChained ? AppColors.primaryAccent : AppColors.cardBorder,
      ),
      visualDensity: VisualDensity.compact,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sliderRow,
          const SizedBox(height: 6),
          filterChip,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: sliderRow),
        const SizedBox(width: 12),
        filterChip,
      ],
    );
  }

  Widget _buildChartCanvas({
    required List<GearingRatioGearPoint> points,
    required GearingSteepClimbSummary summary,
    required bool isCompact,
    required bool isMedium,
  }) {
    final chartHeight = isCompact ? 220.0 : (isMedium ? 245.0 : 270.0);

    return Focus(
      onFocusChange: (focused) => setState(() => _isChartFocused = focused),
      onKeyEvent: (_, event) {
        _handleKeyEvent(event, points.length);
        return KeyEventResult.handled;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onExit: (_) {
              if (_hoveredGearIndex != null) {
                setState(() => _hoveredGearIndex = null);
              }
            },
            onHover: (event) {
              if (!widget.enabled || points.isEmpty) return;
              final idx = _hitTestBarIndex(
                localPosition: event.localPosition,
                size: Size(width, chartHeight),
                count: points.length,
              );
              if (idx != _hoveredGearIndex) {
                setState(() => _hoveredGearIndex = idx);
              }
            },
            child: GestureDetector(
              onTapDown: (details) {
                if (!widget.enabled || points.isEmpty) return;
                final idx = _hitTestBarIndex(
                  localPosition: details.localPosition,
                  size: Size(width, chartHeight),
                  count: points.length,
                );
                if (idx != null) {
                  setState(() {
                    _selectedGearIndex =
                        (_selectedGearIndex == idx) ? null : idx;
                  });
                }
              },
              child: Container(
                height: chartHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: AnimatedBuilder(
                  animation: _transitionCurve,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(width, chartHeight),
                      painter: _GearingRatioBarChartPainter(
                        points: points,
                        minClimbSpeed70RpmKmh: summary.minSpeedAt70RpmKmh,
                        referenceCadenceRpm: _referenceCadenceRpm,
                        hoveredIndex: _hoveredGearIndex,
                        selectedIndex: _selectedGearIndex,
                        animationProgress: _transitionCurve.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int? _hitTestBarIndex({
    required Offset localPosition,
    required Size size,
    required int count,
  }) {
    if (count <= 0) return null;
    const leftPad = 44.0;
    const rightPad = 14.0;
    final plotWidth = size.width - leftPad - rightPad;
    if (plotWidth <= 0) return null;
    final relX = localPosition.dx - leftPad;
    if (relX < 0 || relX > plotWidth) return null;
    final index = (relX / (plotWidth / count)).floor();
    return index.clamp(0, count - 1);
  }

  Widget _buildLegendAndInspector({
    required List<GearingRatioGearPoint> points,
    required GearingRatioGearPoint? activePoint,
    required bool isCompact,
  }) {
    final legendItems = Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!_config.chainring.isSingleRing1x)
          _LegendDot(
            color: AppColors.accentBlue,
            label: 'Mała tarcza (${_config.chainring.smallestTeeth}T)',
          ),
        _LegendDot(
          color: AppColors.goldAccent,
          label: 'Duża tarcza (${_config.chainring.outerTeeth}T)',
        ),
        const _LegendDot(
          color: AppColors.crimsonAlert,
          label: 'Próg 15% @ 70 RPM',
          isDashed: true,
        ),
        const _LegendDot(
          color: AppColors.amberWarning,
          label: 'Przekos łańcucha',
        ),
      ],
    );

    final inspector = activePoint == null
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Najedź lub kliknij dowolny słupek biegu (lub użyj strzałek ← →), aby zobaczyć dokładne przełożenie i prędkości dla 70 / ${_referenceCadenceRpm.round()} / 110 RPM.',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),
          )
        : Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activePoint.isOuterRing
                    ? AppColors.goldAccent.withValues(alpha: 0.6)
                    : AppColors.accentBlue.withValues(alpha: 0.6),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Bieg #${activePoint.gearNumber}: ${activePoint.label}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'Przełożenie: ${activePoint.ratio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${_referenceCadenceRpm.round()} RPM: ${activePoint.speedAtReferenceCadenceKmh.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '70 RPM: ${activePoint.speedAtMinClimbCadenceKmh.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.accentBlue,
                    fontSize: 11.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '110 RPM: ${activePoint.speedAtHighCadenceKmh.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (activePoint.isCrossChained)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amberWarning.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Przekos łańcucha',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.amberWarning,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        legendItems,
        const SizedBox(height: 10),
        inspector,
      ],
    );
  }
}

class _InteractiveGearChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveGearChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveGearChip> createState() => _InteractiveGearChipState();
}

class _InteractiveGearChipState extends State<_InteractiveGearChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: 0.22)
        : (_hovered
            ? AppColors.surface.withValues(alpha: 0.95)
            : AppColors.surface);
    final borderColor = widget.selected
        ? widget.accentColor
        : (_focused
            ? AppColors.accentBlue
            : (_hovered
                ? AppColors.textSecondary.withValues(alpha: 0.6)
                : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enabled) setState(() => _pressed = true);
        },
        onTapUp: (_) {
          if (widget.enabled) setState(() => _pressed = false);
        },
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: widget.selected || _focused ? 1.4 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: widget.selected
                    ? widget.accentColor
                    : AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _TelemetryStatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10.5,
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
  final bool isDashed;

  const _LegendDot({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isDashed ? 14 : 9,
          height: isDashed ? 2.5 : 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isDashed ? 2 : 3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _GearingRatioBarChartPainter extends CustomPainter {
  final List<GearingRatioGearPoint> points;
  final double minClimbSpeed70RpmKmh;
  final double referenceCadenceRpm;
  final int? hoveredIndex;
  final int? selectedIndex;
  final double animationProgress;

  const _GearingRatioBarChartPainter({
    required this.points,
    required this.minClimbSpeed70RpmKmh,
    required this.referenceCadenceRpm,
    required this.hoveredIndex,
    required this.selectedIndex,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 44.0;
    const rightPad = 14.0;
    const topPad = 20.0;
    const bottomPad = 32.0;

    final plotRect = Rect.fromLTWH(
      leftPad,
      topPad,
      math.max(1.0, size.width - leftPad - rightPad),
      math.max(1.0, size.height - topPad - bottomPad),
    );

    final maxSpeed = points.isEmpty
        ? 65.0
        : math.max(
            65.0,
            points
                    .map((p) => p.speedAtReferenceCadenceKmh)
                    .reduce(math.max) *
                1.08,
          );

    // Siatka pozioma (co 10 km/h)
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;

    final step = maxSpeed > 80 ? 20.0 : 10.0;
    for (double spd = 0; spd <= maxSpeed; spd += step) {
      final y = plotRect.bottom - (spd / maxSpeed) * plotRect.height;
      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );
      _drawText(
        canvas,
        '${spd.round()}',
        Offset(6, y - 6),
        const TextStyle(
          fontFamily: 'Inter',
          color: AppColors.textSecondary,
          fontSize: 10,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
    }

    // Jednostka osi Y
    _drawText(
      canvas,
      'km/h',
      const Offset(6, 4),
      const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textSecondary,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    );

    if (points.isEmpty) return;

    final slotWidth = plotRect.width / points.length;
    final barWidth = math.max(4.0, slotWidth * 0.66);

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      final isActive = i == selectedIndex || i == hoveredIndex;
      final normalizedH =
          ((pt.speedAtReferenceCadenceKmh / maxSpeed).clamp(0.0, 1.0)) *
              animationProgress;
      final barHeight = normalizedH * plotRect.height;
      final cx = plotRect.left + slotWidth * (i + 0.5);
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          cx - barWidth / 2,
          plotRect.bottom - barHeight,
          barWidth,
          barHeight,
        ),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );

      final baseColor =
          pt.isOuterRing ? AppColors.goldAccent : AppColors.accentBlue;
      final fillColor = isActive
          ? baseColor
          : baseColor.withValues(alpha: pt.isCrossChained ? 0.38 : 0.78);

      canvas.drawRRect(
        barRect,
        Paint()..color = fillColor,
      );

      if (pt.isCrossChained) {
        canvas.drawRRect(
          barRect,
          Paint()
            ..color = AppColors.amberWarning
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
      }

      if (isActive) {
        canvas.drawRRect(
          barRect,
          Paint()
            ..color = AppColors.textPrimary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        _drawText(
          canvas,
          pt.speedAtReferenceCadenceKmh.toStringAsFixed(1),
          Offset(cx - 12, plotRect.bottom - barHeight - 15),
          const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        );
      }

      // Etykiety osi X (pokazujemy co 2. przy 24 biegach na wąskim widoku)
      final showLabel = points.length <= 14 ||
          plotWidthEnoughForAll(slotWidth) ||
          i % 2 == 0 ||
          isActive;
      if (showLabel) {
        _drawText(
          canvas,
          '${pt.rearTeeth}',
          Offset(cx - 7, plotRect.bottom + 6),
          TextStyle(
            fontFamily: 'Inter',
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      }
    }

    // Przerywana linia minimalnej prędkości na podjeździe 15% przy 70 RPM
    final minY = plotRect.bottom -
        ((minClimbSpeed70RpmKmh / maxSpeed).clamp(0.0, 1.0)) * plotRect.height;
    _drawDashedLine(
      canvas,
      Offset(plotRect.left, minY),
      Offset(plotRect.right, minY),
      Paint()
        ..color = AppColors.crimsonAlert
        ..strokeWidth = 1.6,
    );

    final tagText =
        '15% min @ 70 RPM: ${minClimbSpeed70RpmKmh.toStringAsFixed(1)} km/h';
    final tagWidth = math.min(plotRect.width - 8, 168.0);
    final tagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(plotRect.left + 6, math.max(topPad, minY - 19), tagWidth, 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      tagRect,
      Paint()..color = AppColors.crimsonAlert.withValues(alpha: 0.9),
    );
    _drawText(
      canvas,
      tagText,
      Offset(tagRect.left + 6, tagRect.top + 2),
      const TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimary,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  bool plotWidthEnoughForAll(double slotWidth) => slotWidth >= 22.0;

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    var currentX = start.dx;
    while (currentX < end.dx) {
      final nextX = math.min(currentX + dashWidth, end.dx);
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(nextX, end.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GearingRatioBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minClimbSpeed70RpmKmh != minClimbSpeed70RpmKmh ||
        oldDelegate.referenceCadenceRpm != referenceCadenceRpm ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.animationProgress != animationProgress;
  }
}
