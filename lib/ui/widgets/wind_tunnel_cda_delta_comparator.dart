// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/physics_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/equipment/bike_fit_configuration.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/rider/rider_physiology.dart';

/// Rozbicie delty CdA na poszczególne składowe sprzętu i pozycji.
class CdaDeltaComponentBreakdown {
  final String label;
  final double deltaCdaM2;
  final double deltaWatts;
  final double deltaSeconds40KmItt;

  const CdaDeltaComponentBreakdown({
    required this.label,
    required this.deltaCdaM2,
    required this.deltaWatts,
    required this.deltaSeconds40KmItt,
  });
}

/// Wynik porównania dwóch konfiguracji w tunelu aerodynamicznym (Baza A vs Setup B).
class CdaDeltaComparisonResult {
  final double baselineCdaM2;
  final double currentCdaM2;
  final double deltaCdaM2;
  final double wattsSavedAtSpeed;
  final double timeDeltaSeconds40KmItt;
  final double referenceSpeedKmh;
  final List<CdaDeltaComponentBreakdown> components;

  const CdaDeltaComparisonResult({
    required this.baselineCdaM2,
    required this.currentCdaM2,
    required this.deltaCdaM2,
    required this.wattsSavedAtSpeed,
    required this.timeDeltaSeconds40KmItt,
    required this.referenceSpeedKmh,
    required this.components,
  });

  bool get isGain => deltaCdaM2 < -0.00005;
  bool get isLoss => deltaCdaM2 > 0.00005;
  bool get isNeutral => !isGain && !isLoss;

  /// Sformatowany komunikat równania zysku/straty, np.:
  /// `Zysk: -0.008 m² CdA = +7.4 W przy 45 km/h = -42 sekundy na 40 km ITT`
  String formatHeadlineSummary() {
    final speedLabel = referenceSpeedKmh.round();
    if (isNeutral) {
      return 'Brak zmian: 0.000 m² CdA = 0.0 W przy $speedLabel km/h = 0 sekund na 40 km ITT';
    }

    final prefix = isGain ? 'Zysk:' : 'Strata:';
    final cdaSign = deltaCdaM2 >= 0 ? '+' : '';
    final wattsSign = wattsSavedAtSpeed >= 0 ? '+' : '';
    final timeSign = timeDeltaSeconds40KmItt >= 0 ? '+' : '';
    final roundedSec = timeDeltaSeconds40KmItt.round();
    final secWord = _polishSecondsWord(roundedSec.abs());

    return '$prefix $cdaSign${deltaCdaM2.toStringAsFixed(3)} m² CdA = '
        '$wattsSign${wattsSavedAtSpeed.toStringAsFixed(1)} W przy $speedLabel km/h = '
        '$timeSign$roundedSec $secWord na 40 km ITT';
  }

  static String _polishSecondsWord(int absSeconds) {
    if (absSeconds == 1) return 'sekunda';
    final mod10 = absSeconds % 10;
    final mod100 = absSeconds % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'sekundy';
    }
    return 'sekund';
  }
}

/// Czysty kalkulator fizyki porównującej dwie konfiguracje sprzętu i bike fittingu.
class WindTunnelCdaDeltaCalculator {
  WindTunnelCdaDeltaCalculator._();

  static CdaDeltaComparisonResult compare({
    required RiderPhysiology physiology,
    required BikeFitConfiguration baselineFit,
    required CompleteBike baselineBike,
    required BikeFitConfiguration currentFit,
    required CompleteBike currentBike,
    double speedKmh = 45.0,
  }) {
    final safeSpeedKmh = speedKmh.clamp(20.0, 75.0);
    final double baseFrontalArea =
        physiology.frontalAreaM2 > 0 ? physiology.frontalAreaM2 : 0.498;
    final double riderBaseCda = baseFrontalArea * 0.652;

    final double baseStemSpacers = _stemAndSpacersCda(baselineFit);
    final double currStemSpacers = _stemAndSpacersCda(currentFit);

    final double baseCockpit = _cockpitWidthCda(baselineFit);
    final double currCockpit = _cockpitWidthCda(currentFit);

    final double baseHoods = _hoodTiltCda(baselineFit);
    final double currHoods = _hoodTiltCda(currentFit);

    final double baseCrankSaddle = _crankAndSaddleCda(baselineFit);
    final double currCrankSaddle = _crankAndSaddleCda(currentFit);

    final double baseFrame = baselineBike.frame.aeroCdaModifier;
    final double currFrame = currentBike.frame.aeroCdaModifier;

    final double baseWheelset = baselineBike.wheelset.aeroCdaModifier;
    final double currWheelset = currentBike.wheelset.aeroCdaModifier;

    final double baselineCda = (riderBaseCda +
            baseFrame +
            baseWheelset +
            baseStemSpacers +
            baseCockpit +
            baseHoods +
            baseCrankSaddle)
        .clamp(0.165, 0.450);

    final double currentCda = (riderBaseCda +
            currFrame +
            currWheelset +
            currStemSpacers +
            currCockpit +
            currHoods +
            currCrankSaddle)
        .clamp(0.165, 0.450);

    final double deltaCda = currentCda - baselineCda;
    final double wattsSaved = _calculateWattsSaved(deltaCda, safeSpeedKmh);
    final double timeDeltaSec = _calculateItt40KmDeltaSeconds(
      baselineCda: baselineCda,
      currentCda: currentCda,
      speedKmh: safeSpeedKmh,
    );

    CdaDeltaComponentBreakdown buildPart(String label, double partDeltaCda) {
      return CdaDeltaComponentBreakdown(
        label: label,
        deltaCdaM2: partDeltaCda,
        deltaWatts: _calculateWattsSaved(partDeltaCda, safeSpeedKmh),
        deltaSeconds40KmItt: _calculateItt40KmDeltaSeconds(
          baselineCda: baselineCda,
          currentCda: (baselineCda + partDeltaCda).clamp(0.165, 0.450),
          speedKmh: safeSpeedKmh,
        ),
      );
    }

    final components = <CdaDeltaComponentBreakdown>[
      buildPart('Podkładki i mostek', currStemSpacers - baseStemSpacers),
      buildPart('Rama roweru', currFrame - baseFrame),
      buildPart('Zestaw kół', currWheelset - baseWheelset),
      buildPart('Szerokość kokpitu', currCockpit - baseCockpit),
      buildPart('Rotacja klamek', currHoods - baseHoods),
      buildPart('Korby i siodło', currCrankSaddle - baseCrankSaddle),
    ];

    return CdaDeltaComparisonResult(
      baselineCdaM2: baselineCda,
      currentCdaM2: currentCda,
      deltaCdaM2: deltaCda,
      wattsSavedAtSpeed: wattsSaved,
      timeDeltaSeconds40KmItt: timeDeltaSec,
      referenceSpeedKmh: safeSpeedKmh,
      components: components,
    );
  }

  static double _stemAndSpacersCda(BikeFitConfiguration fit) {
    return ((fit.spacersStackMm - 20) / 20.0) * 0.0055 -
        ((fit.stemLengthMm - 110) * 0.00008);
  }

  static double _cockpitWidthCda(BikeFitConfiguration fit) {
    return (fit.cockpitWidthMm - 400) * 0.00025;
  }

  static double _hoodTiltCda(BikeFitConfiguration fit) {
    final double clampedHoodTilt = fit.hoodInwardTiltDegrees.clamp(0.0, 35.0);
    return clampedHoodTilt <= 14.0
        ? -(clampedHoodTilt / 14.0) * 0.0042
        : -0.0042 - ((clampedHoodTilt - 14.0) / 21.0) * 0.0023;
  }

  static double _crankAndSaddleCda(BikeFitConfiguration fit) {
    final crank = (fit.crankArmLengthMm - 172.5) * 0.00026;
    final saddle = (fit.saddleTiltDegrees.clamp(-4.0, 0.0) / 4.0) * 0.0016;
    return crank + saddle;
  }

  static double _calculateWattsSaved(double deltaCdaM2, double speedKmh) {
    final double v = speedKmh / 3.6;
    // Dodatnie waty = oszczędność mocy przy ujemnej delcie CdA
    return 0.5 * PhysicsConstants.seaLevelAirDensity * (-deltaCdaM2) * math.pow(v, 3);
  }

  static double _calculateItt40KmDeltaSeconds({
    required double baselineCda,
    required double currentCda,
    required double speedKmh,
  }) {
    if (baselineCda <= 0.0) return 0.0;
    final double baseSeconds = 40000.0 / (speedKmh / 3.6);
    final double ratio = (currentCda / baselineCda).clamp(0.5, 1.5);
    return (math.pow(ratio, 1.0 / 3.0).toDouble() - 1.0) * baseSeconds;
  }
}

/// Predefiniowane warianty ramy do szybkiego testowania w komparatorze tunelu aero.
class WindTunnelFramePreset {
  final String id;
  final String label;
  final FrameCategory category;
  final double cdaModifier;
  final int weightGrams;

  const WindTunnelFramePreset({
    required this.id,
    required this.label,
    required this.category,
    required this.cdaModifier,
    required this.weightGrams,
  });

  static const List<WindTunnelFramePreset> presets = [
    WindTunnelFramePreset(
      id: 'climb',
      label: 'Górska (SL)',
      category: FrameCategory.lightweightClimbing,
      cdaModifier: -0.004,
      weightGrams: 690,
    ),
    WindTunnelFramePreset(
      id: 'allround',
      label: 'All-Round',
      category: FrameCategory.allRounder,
      cdaModifier: -0.010,
      weightGrams: 790,
    ),
    WindTunnelFramePreset(
      id: 'aero',
      label: 'Aero Road',
      category: FrameCategory.aero,
      cdaModifier: -0.016,
      weightGrams: 890,
    ),
    WindTunnelFramePreset(
      id: 'tt',
      label: 'Czasowa TT',
      category: FrameCategory.timeTrial,
      cdaModifier: -0.026,
      weightGrams: 1120,
    ),
  ];
}

/// Predefiniowane warianty kół do szybkiego testowania w komparatorze tunelu aero.
class WindTunnelWheelPreset {
  final String id;
  final String label;
  final int rimDepthMm;
  final double cdaModifier;
  final int weightGrams;

  const WindTunnelWheelPreset({
    required this.id,
    required this.label,
    required this.rimDepthMm,
    required this.cdaModifier,
    required this.weightGrams,
  });

  static const List<WindTunnelWheelPreset> presets = [
    WindTunnelWheelPreset(
      id: 'w32',
      label: '32mm Alpin',
      rimDepthMm: 32,
      cdaModifier: -0.002,
      weightGrams: 1210,
    ),
    WindTunnelWheelPreset(
      id: 'w45',
      label: '45mm All',
      rimDepthMm: 45,
      cdaModifier: -0.007,
      weightGrams: 1320,
    ),
    WindTunnelWheelPreset(
      id: 'w60',
      label: '60mm Aero',
      rimDepthMm: 60,
      cdaModifier: -0.012,
      weightGrams: 1410,
    ),
    WindTunnelWheelPreset(
      id: 'w80',
      label: '80mm / Dysk',
      rimDepthMm: 80,
      cdaModifier: -0.020,
      weightGrams: 1620,
    ),
  ];
}

/// Interaktywny komparator delty CdA w ekranie Tunelu Aerodynamicznego.
///
/// Przelicza każdą zmianę sprzętu (rama, koła) lub pozycji (wysokość podkładek
/// pod mostkiem, szerokość kokpitu, rotacja klamek, korby) na realne oszczędności:
/// `Zysk: -0.008 m² CdA = +7.4 W przy 45 km/h = -42 sekundy na 40 km ITT`.
class WindTunnelCdaDeltaComparator extends StatefulWidget {
  final RiderPhysiology physiology;
  final BikeFitConfiguration currentFit;
  final CompleteBike currentBike;
  final double windSpeedKmh;
  final ValueChanged<CompleteBike>? onBikeChanged;
  final ValueChanged<int>? onSpacersChanged;

  const WindTunnelCdaDeltaComparator({
    super.key,
    required this.physiology,
    required this.currentFit,
    required this.currentBike,
    this.windSpeedKmh = 45.0,
    this.onBikeChanged,
    this.onSpacersChanged,
  });

  @override
  State<WindTunnelCdaDeltaComparator> createState() =>
      _WindTunnelCdaDeltaComparatorState();
}

class _WindTunnelCdaDeltaComparatorState
    extends State<WindTunnelCdaDeltaComparator> {
  late BikeFitConfiguration _baselineFit;
  late CompleteBike _baselineBike;
  bool _showBreakdown = true;

  @override
  void initState() {
    super.initState();
    _baselineFit = _defaultStandardRoadFit(widget.currentFit);
    _baselineBike = widget.currentBike;
  }

  BikeFitConfiguration _defaultStandardRoadFit(BikeFitConfiguration source) {
    return source.copyWith(
      spacersStackMm: 20,
      cockpitWidthMm: 400,
      stemLengthMm: 110,
      hoodInwardTiltDegrees: 0.0,
      crankArmLengthMm: 172.5,
      saddleTiltDegrees: 0.0,
    );
  }

  bool get _isBaselineIdenticalToCurrent {
    return _baselineFit.spacersStackMm == widget.currentFit.spacersStackMm &&
        _baselineFit.stemLengthMm == widget.currentFit.stemLengthMm &&
        _baselineFit.cockpitWidthMm == widget.currentFit.cockpitWidthMm &&
        (_baselineFit.hoodInwardTiltDegrees -
                    widget.currentFit.hoodInwardTiltDegrees)
                .abs() <
            0.05 &&
        (_baselineFit.crankArmLengthMm - widget.currentFit.crankArmLengthMm)
                .abs() <
            0.05 &&
        (_baselineFit.saddleTiltDegrees - widget.currentFit.saddleTiltDegrees)
                .abs() <
            0.05 &&
        (_baselineBike.frame.aeroCdaModifier -
                    widget.currentBike.frame.aeroCdaModifier)
                .abs() <
            0.0001 &&
        (_baselineBike.wheelset.aeroCdaModifier -
                    widget.currentBike.wheelset.aeroCdaModifier)
                .abs() <
            0.0001;
  }

  void _lockCurrentAsBaseline() {
    setState(() {
      _baselineFit = widget.currentFit;
      _baselineBike = widget.currentBike;
    });
  }

  void _resetBaselineToStandard() {
    setState(() {
      _baselineFit = _defaultStandardRoadFit(widget.currentFit);
      _baselineBike = widget.currentBike.copyWith(
        frame: widget.currentBike.frame.copyWith(
          category: FrameCategory.allRounder,
          aeroCdaModifier: -0.010,
          weightGrams: 790,
          name: 'Standard All-Round Carbon',
        ),
        wheelset: widget.currentBike.wheelset.copyWith(
          rimDepthMm: 45,
          aeroCdaModifier: -0.007,
          weightGrams: 1320,
          name: 'All-Round 45mm Carbon',
        ),
      );
    });
  }

  void _applyFramePreset(WindTunnelFramePreset preset) {
    final updatedBike = widget.currentBike.copyWith(
      frame: widget.currentBike.frame.copyWith(
        name: '${preset.label} Carbon',
        category: preset.category,
        aeroCdaModifier: preset.cdaModifier,
        weightGrams: preset.weightGrams,
      ),
    );
    widget.onBikeChanged?.call(updatedBike);
  }

  void _applyWheelPreset(WindTunnelWheelPreset preset) {
    final updatedBike = widget.currentBike.copyWith(
      wheelset: widget.currentBike.wheelset.copyWith(
        name: '${preset.label} Carbon',
        rimDepthMm: preset.rimDepthMm,
        aeroCdaModifier: preset.cdaModifier,
        weightGrams: preset.weightGrams,
      ),
    );
    widget.onBikeChanged?.call(updatedBike);
  }

  @override
  Widget build(BuildContext context) {
    final result = WindTunnelCdaDeltaCalculator.compare(
      physiology: widget.physiology,
      baselineFit: _baselineFit,
      baselineBike: _baselineBike,
      currentFit: widget.currentFit,
      currentBike: widget.currentBike,
      speedKmh: widget.windSpeedKmh,
    );

    final Color statusColor = result.isGain
        ? AppColors.statusSuccess
        : result.isLoss
            ? AppColors.crimsonAlert
            : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 540;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 12),
              _buildHeadlineBanner(result, statusColor),
              const SizedBox(height: 14),
              _buildKpiRow(result, statusColor, isCompact),
              const SizedBox(height: 14),
              _buildQuickModifiersSection(isCompact),
              const SizedBox(height: 12),
              _buildBreakdownSection(result),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final titleRow = Row(
      mainAxisSize: MainAxisSize.min,
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
            Icons.compare_arrows_rounded,
            color: AppColors.goldAccent,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KOMPARATOR DELTY CdA (BAZA A vs SETUP B)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Przelicznik oszczędności watów i czasu 40 km ITT w czasie rzeczywistym',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ComparatorActionButton(
          label: 'Ustaw jako Bazę A',
          icon: Icons.bookmark_add_outlined,
          isDisabled: _isBaselineIdenticalToCurrent,
          accentColor: AppColors.cyanAccent,
          onPressed: _lockCurrentAsBaseline,
        ),
        _ComparatorActionButton(
          label: 'Baza Standard',
          icon: Icons.restart_alt_rounded,
          isDisabled: false,
          accentColor: AppColors.textSecondary,
          onPressed: _resetBaselineToStandard,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: 10),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleRow),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _buildHeadlineBanner(
    CdaDeltaComparisonResult result,
    Color statusColor,
  ) {
    final IconData icon = result.isGain
        ? Icons.trending_down_rounded
        : result.isLoss
            ? Icons.trending_up_rounded
            : Icons.horizontal_rule_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result.formatHeadlineSummary(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: result.isNeutral ? AppColors.textPrimary : statusColor,
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(
    CdaDeltaComparisonResult result,
    Color statusColor,
    bool isCompact,
  ) {
    final cdaSign = result.deltaCdaM2 >= 0 ? '+' : '';
    final wSign = result.wattsSavedAtSpeed >= 0 ? '+' : '';
    final tSign = result.timeDeltaSeconds40KmItt >= 0 ? '+' : '';
    final speedLabel = result.referenceSpeedKmh.round();

    final cards = [
      _DeltaMetricCard(
        label: 'DELTA CdA (B vs A)',
        value: '$cdaSign${result.deltaCdaM2.toStringAsFixed(3)} m²',
        subLabel:
            'Baza: ${result.baselineCdaM2.toStringAsFixed(3)} → Teraz: ${result.currentCdaM2.toStringAsFixed(3)}',
        accentColor: result.isNeutral ? AppColors.cyanAccent : statusColor,
      ),
      _DeltaMetricCard(
        label: 'OSZCZĘDNOŚĆ @ $speedLabel KM/H',
        value: '$wSign${result.wattsSavedAtSpeed.toStringAsFixed(1)} W',
        subLabel: result.isGain
            ? 'Mniejsze zapotrzebowanie mocy'
            : result.isLoss
                ? 'Większy opór aerodynamiczny'
                : 'Identyczne zapotrzebowanie',
        accentColor: result.isGain
            ? AppColors.goldAccent
            : result.isLoss
                ? AppColors.crimsonAlert
                : AppColors.textSecondary,
      ),
      _DeltaMetricCard(
        label: 'ZYSK NA 40 KM ITT',
        value: '$tSign${result.timeDeltaSeconds40KmItt.round()} s',
        subLabel: 'Czasówka indywidualna ($speedLabel km/h)',
        accentColor: result.isGain
            ? AppColors.statusSuccess
            : result.isLoss
                ? AppColors.crimsonAlert
                : AppColors.textSecondary,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildQuickModifiersSection(bool isCompact) {
    final currentSpacers = widget.currentFit.spacersStackMm;
    final canDecreaseSpacers = currentSpacers > 0 && widget.onSpacersChanged != null;
    final canIncreaseSpacers = currentSpacers < 35 && widget.onSpacersChanged != null;

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
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: AppColors.cyanAccent,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'SZYBKIE TESTY SPRZĘTU I PODKŁADEK',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Podkładki: $currentSpacers mm (Baza: ${_baselineFit.spacersStackMm} mm)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cyanAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Podkładki pod mostkiem
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Podkładki:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              _ComparatorActionButton(
                label: '-5 mm',
                icon: Icons.remove_rounded,
                isDisabled: !canDecreaseSpacers,
                accentColor: AppColors.statusSuccess,
                onPressed: () {
                  widget.onSpacersChanged?.call((currentSpacers - 5).clamp(0, 35));
                },
              ),
              _ComparatorActionButton(
                label: '+5 mm',
                icon: Icons.add_rounded,
                isDisabled: !canIncreaseSpacers,
                accentColor: AppColors.amberWarning,
                onPressed: () {
                  widget.onSpacersChanged?.call((currentSpacers + 5).clamp(0, 35));
                },
              ),
              _ComparatorActionButton(
                label: 'Slammed (0 mm)',
                icon: Icons.vertical_align_bottom_rounded,
                isDisabled: currentSpacers == 0 || widget.onSpacersChanged == null,
                accentColor: AppColors.goldAccent,
                onPressed: () {
                  widget.onSpacersChanged?.call(0);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Rama roweru
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Rama:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              for (final preset in WindTunnelFramePreset.presets)
                _EquipmentPresetChip(
                  label: preset.label,
                  isSelected: (widget.currentBike.frame.aeroCdaModifier -
                              preset.cdaModifier)
                          .abs() <
                      0.001,
                  isEnabled: widget.onBikeChanged != null,
                  onTap: () => _applyFramePreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Zestaw kół
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Koła:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              for (final preset in WindTunnelWheelPreset.presets)
                _EquipmentPresetChip(
                  label: preset.label,
                  isSelected: (widget.currentBike.wheelset.aeroCdaModifier -
                              preset.cdaModifier)
                          .abs() <
                      0.001,
                  isEnabled: widget.onBikeChanged != null,
                  onTap: () => _applyWheelPreset(preset),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(CdaDeltaComparisonResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showBreakdown = !_showBreakdown),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Icon(
                  _showBreakdown
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'ROZBICIE ZMIAN NA KOMPONENTY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showBreakdown) ...[
          const SizedBox(height: 6),
          for (final item in result.components) _buildBreakdownRow(item),
        ],
      ],
    );
  }

  Widget _buildBreakdownRow(CdaDeltaComponentBreakdown item) {
    final bool isZero = item.deltaCdaM2.abs() < 0.00005;
    final bool isGain = item.deltaCdaM2 < -0.00005;
    final Color color = isZero
        ? AppColors.textSecondary
        : isGain
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert;

    final cdaSign = item.deltaCdaM2 >= 0 ? '+' : '';
    final wSign = item.deltaWatts >= 0 ? '+' : '';
    final tSign = item.deltaSeconds40KmItt >= 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              item.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isZero
                  ? '0.000 m²'
                  : '$cdaSign${item.deltaCdaM2.toStringAsFixed(3)} m²',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              isZero ? '0.0 W' : '$wSign${item.deltaWatts.toStringAsFixed(1)} W',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Text(
              isZero ? '0 s' : '$tSign${item.deltaSeconds40KmItt.round()} s',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final Color accentColor;

  const _DeltaMetricCard({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ComparatorActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _ComparatorActionButton({
    required this.label,
    required this.icon,
    required this.isDisabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_ComparatorActionButton> createState() =>
      _ComparatorActionButtonState();
}

class _ComparatorActionButtonState extends State<_ComparatorActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled;
    final Color fgColor = enabled
        ? (_isHovered || _isFocused ? AppColors.textPrimary : widget.accentColor)
        : AppColors.textSecondary.withValues(alpha: 0.4);
    final Color bgColor = !enabled
        ? AppColors.surface
        : _isPressed
            ? widget.accentColor.withValues(alpha: 0.25)
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.16)
                : widget.accentColor.withValues(alpha: 0.08);

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isFocused
                    ? AppColors.goldAccent
                    : enabled
                        ? widget.accentColor.withValues(alpha: 0.4)
                        : AppTheme.borderColor.withValues(alpha: 0.5),
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: fgColor),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
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

class _EquipmentPresetChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _EquipmentPresetChip({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_EquipmentPresetChip> createState() => _EquipmentPresetChipState();
}

class _EquipmentPresetChipState extends State<_EquipmentPresetChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent
            : _isHovered
                ? AppColors.cyanAccent.withValues(alpha: 0.6)
                : AppTheme.borderColor;

    final Color bgColor = !widget.isEnabled
        ? AppColors.surface
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: 0.18)
            : _isPressed
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surface
                    : AppColors.background;

    final Color textColor = !widget.isEnabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.goldAccent
            : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      child: GestureDetector(
        onTapDown:
            widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp:
            widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            widget.isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.isEnabled ? widget.onTap : null,
        child: MouseRegion(
          cursor: widget.isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
