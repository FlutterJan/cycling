import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'rider_telemetry_sparklines_card.dart';

/// Pojedyncza próbka wydatku energetycznego z ostatnich 60 sekund (1 próbka = 1 s).
@immutable
class EnergyExpenditureSample {
  /// Znacznik czasu w sekundach od startu etapu.
  final int timestampSeconds;

  /// Chwilowa moc generowana na pedałach [W].
  final double powerWatts;

  /// Chwilowe tętno kolarza [BPM].
  final int heartRateBpm;

  /// Chwilowe tempo spalania glikogenu [kcal/h].
  final double glycogenBurnKcalPerHour;

  const EnergyExpenditureSample({
    required this.timestampSeconds,
    required this.powerWatts,
    required this.heartRateBpm,
    required this.glycogenBurnKcalPerHour,
  });
}

/// Wynik prognozy wyczerpania glikogenu ("odcięcia" / bonku) dla kolarza.
@immutable
class BonkPredictionResult {
  /// Czy kolarz jest już w stanie odcięcia (glikogen <= próg krytyczny).
  final bool isAlreadyBonked;

  /// Czy odcięcie nastąpi przed metą etapu przy obecnym tempie spalania.
  final bool willBonkBeforeFinish;

  /// Czy ostrzeżenie jest pilne (odcięcie w ciągu najbliższych 35 km lub już aktywne).
  final bool isCriticalWarning;

  /// Prognozowany kilometr etapu, na którym nastąpi odcięcie (null jeśli bezpieczny).
  final double? predictedBonkKm;

  /// Pozostały dystans do prognozowanego odcięcia [km].
  final double? kmUntilBonk;

  /// Tempo spalania netto glikogenu po uwzględnieniu wchłaniania węglowodanów [g/h].
  final double netGlycogenBurnGramsPerHour;

  /// Sformatowany komunikat ostrzegawczy (np. "Bonk Warning at km 172").
  final String statusLabel;

  const BonkPredictionResult({
    required this.isAlreadyBonked,
    required this.willBonkBeforeFinish,
    required this.isCriticalWarning,
    required this.predictedBonkKm,
    required this.kmUntilBonk,
    required this.netGlycogenBurnGramsPerHour,
    required this.statusLabel,
  });
}

/// Kalkulator prognozy kilometra odcięcia ("Bonk Warning at km X") na bazie tempa spalania glikogenu.
class BonkPredictionCalculator {
  BonkPredictionCalculator._();

  /// Próg krytyczny glikogenu mięśniowego/wątrobowego wywołujący odcięcie [g].
  static const double bonkThresholdGrams = 50.0;

  /// Wartość kaloryczna 1 grama glikogenu [kcal/g].
  static const double kcalPerGramGlycogen = 4.0;

  /// Wylicza prognozowany kilometr odcięcia na podstawie aktualnych zapasów i tempa spalania.
  static BonkPredictionResult predict({
    required double currentDistanceKm,
    required double stageTotalKm,
    required double currentSpeedKmh,
    required double glycogenRemainingGrams,
    required double glycogenBurnKcalPerHour,
    double carbsIntakeGramsPerHour = 0.0,
    bool isBonking = false,
  }) {
    final double grossBurnGramsPerHour =
        math.max(0.0, glycogenBurnKcalPerHour) / kcalPerGramGlycogen;
    final double netBurnGramsPerHour =
        math.max(0.0, grossBurnGramsPerHour - math.max(0.0, carbsIntakeGramsPerHour));

    if (isBonking || glycogenRemainingGrams <= bonkThresholdGrams) {
      final int kmRounded = math.max(0, currentDistanceKm.round());
      return BonkPredictionResult(
        isAlreadyBonked: true,
        willBonkBeforeFinish: true,
        isCriticalWarning: true,
        predictedBonkKm: currentDistanceKm,
        kmUntilBonk: 0.0,
        netGlycogenBurnGramsPerHour: netBurnGramsPerHour,
        statusLabel: 'Bonk Active at km $kmRounded',
      );
    }

    if (netBurnGramsPerHour <= 0.1 || currentSpeedKmh <= 1.0) {
      return BonkPredictionResult(
        isAlreadyBonked: false,
        willBonkBeforeFinish: false,
        isCriticalWarning: false,
        predictedBonkKm: null,
        kmUntilBonk: null,
        netGlycogenBurnGramsPerHour: netBurnGramsPerHour,
        statusLabel: 'Glycogen Sustainable',
      );
    }

    final double usableGlycogenGrams =
        math.max(0.0, glycogenRemainingGrams - bonkThresholdGrams);
    final double hoursUntilBonk = usableGlycogenGrams / netBurnGramsPerHour;
    final double kmUntilBonk = hoursUntilBonk * currentSpeedKmh;
    final double predictedKm = currentDistanceKm + kmUntilBonk;
    final bool willBonkBeforeFinish = predictedKm <= stageTotalKm;
    final bool isCritical = willBonkBeforeFinish && kmUntilBonk <= 35.0;
    final int predictedKmRounded = math.max(0, predictedKm.round());

    if (willBonkBeforeFinish) {
      return BonkPredictionResult(
        isAlreadyBonked: false,
        willBonkBeforeFinish: true,
        isCriticalWarning: isCritical,
        predictedBonkKm: predictedKm,
        kmUntilBonk: kmUntilBonk,
        netGlycogenBurnGramsPerHour: netBurnGramsPerHour,
        statusLabel: 'Bonk Warning at km $predictedKmRounded',
      );
    }

    return BonkPredictionResult(
      isAlreadyBonked: false,
      willBonkBeforeFinish: false,
      isCriticalWarning: false,
      predictedBonkKm: predictedKm,
      kmUntilBonk: kmUntilBonk,
      netGlycogenBurnGramsPerHour: netBurnGramsPerHour,
      statusLabel: 'Safe to Finish (${stageTotalKm.round()} km)',
    );
  }
}

/// Pełny model telemetrii energetycznej pojedynczego kolarza dla HUD.
@immutable
class RiderEnergyTelemetryData {
  final String riderId;
  final String riderName;
  final String roleTag;
  final int? bibNumber;
  final double ftpWatts;
  final int maxHeartRateBpm;
  final double currentPowerWatts;
  final int currentHeartRateBpm;
  final double currentSpeedKmh;
  final double currentDistanceKm;
  final double stageTotalKm;
  final double glycogenRemainingGrams;
  final double maxGlycogenGrams;
  final double glycogenBurnKcalPerHour;
  final double carbsIntakeGramsPerHour;
  final bool isBonking;
  final bool isDisabled;
  final List<EnergyExpenditureSample> last60SecondsSamples;

  const RiderEnergyTelemetryData({
    required this.riderId,
    required this.riderName,
    this.roleTag = 'DOM',
    this.bibNumber,
    required this.ftpWatts,
    required this.maxHeartRateBpm,
    required this.currentPowerWatts,
    required this.currentHeartRateBpm,
    required this.currentSpeedKmh,
    required this.currentDistanceKm,
    required this.stageTotalKm,
    required this.glycogenRemainingGrams,
    required this.maxGlycogenGrams,
    required this.glycogenBurnKcalPerHour,
    this.carbsIntakeGramsPerHour = 0.0,
    this.isBonking = false,
    this.isDisabled = false,
    required this.last60SecondsSamples,
  });

  /// Procent pozostałego glikogenu [0.0..1.0].
  double get glycogenPercent {
    if (maxGlycogenGrams <= 0.0) return 0.0;
    return (glycogenRemainingGrams / maxGlycogenGrams).clamp(0.0, 1.0);
  }

  /// Wylicza prognozę odcięcia dla aktualnych parametrów kolarza.
  BonkPredictionResult computeBonkPrediction() {
    return BonkPredictionCalculator.predict(
      currentDistanceKm: currentDistanceKm,
      stageTotalKm: stageTotalKm,
      currentSpeedKmh: currentSpeedKmh,
      glycogenRemainingGrams: glycogenRemainingGrams,
      glycogenBurnKcalPerHour: glycogenBurnKcalPerHour,
      carbsIntakeGramsPerHour: carbsIntakeGramsPerHour,
      isBonking: isBonking,
    );
  }
}

/// Tryb wyświetlania serii na mini-wykresach 60s.
enum SparklineMetricMode {
  allOverlay,
  powerOnly,
  heartRateOnly,
  glycogenOnly,
}

/// Tryb sortowania listy 8 kolarzy w HUD.
enum EnergyHudSortMode {
  rosterOrder,
  earliestBonk,
  highestBurnRate,
  highestPower,
}

/// Panel HUD wyścigu prezentujący mini-wykresy z ostatnich 60 sekund dla maksymalnie 8 kolarzy gracza:
/// moc (W), tętno (BPM), tempo spalania glikogenu (kcal/h) oraz prognozę kilometra odcięcia.
class LiveEnergyExpenditureSparklinesHud extends StatefulWidget {
  /// Lista kolarzy gracza (zwykle do 8 kolarzy na etapie).
  final List<RiderEnergyTelemetryData> riders;

  /// Aktualnie wybrany/podświetlony kolarz w HUD 3D.
  final String? selectedRiderId;

  /// Callback po kliknięciu karty kolarza.
  final ValueChanged<RiderEnergyTelemetryData>? onRiderSelected;

  /// Opcjonalny callback podania żelu energetycznego kolarzowi zagrożonemu odcięciem.
  final ValueChanged<RiderEnergyTelemetryData>? onFeedGelPressed;

  /// Czy panel startuje w stanie rozwiniętym.
  final bool initiallyExpanded;

  /// Czy pulsowanie krytycznego alertu odcięcia jest włączone.
  final bool enableCriticalPulse;

  const LiveEnergyExpenditureSparklinesHud({
    super.key,
    required this.riders,
    this.selectedRiderId,
    this.onRiderSelected,
    this.onFeedGelPressed,
    this.initiallyExpanded = true,
    this.enableCriticalPulse = true,
  });

  @override
  State<LiveEnergyExpenditureSparklinesHud> createState() =>
      _LiveEnergyExpenditureSparklinesHudState();
}

class _LiveEnergyExpenditureSparklinesHudState
    extends State<LiveEnergyExpenditureSparklinesHud>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  SparklineMetricMode _metricMode = SparklineMetricMode.allOverlay;
  EnergyHudSortMode _sortMode = EnergyHudSortMode.rosterOrder;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.enableCriticalPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LiveEnergyExpenditureSparklinesHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableCriticalPulse != oldWidget.enableCriticalPulse) {
      if (widget.enableCriticalPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<RiderEnergyTelemetryData> _getSortedRiders() {
    final List<RiderEnergyTelemetryData> visible =
        widget.riders.take(8).toList(growable: false);
    if (_sortMode == EnergyHudSortMode.rosterOrder) {
      return visible;
    }

    final List<RiderEnergyTelemetryData> copy = List.of(visible);
    switch (_sortMode) {
      case EnergyHudSortMode.rosterOrder:
        return copy;
      case EnergyHudSortMode.earliestBonk:
        copy.sort((a, b) {
          if (a.isDisabled != b.isDisabled) {
            return a.isDisabled ? 1 : -1;
          }
          final BonkPredictionResult predA = a.computeBonkPrediction();
          final BonkPredictionResult predB = b.computeBonkPrediction();
          final double kmA = predA.willBonkBeforeFinish
              ? (predA.predictedBonkKm ?? double.infinity)
              : double.infinity;
          final double kmB = predB.willBonkBeforeFinish
              ? (predB.predictedBonkKm ?? double.infinity)
              : double.infinity;
          return kmA.compareTo(kmB);
        });
        return copy;
      case EnergyHudSortMode.highestBurnRate:
        copy.sort((a, b) {
          if (a.isDisabled != b.isDisabled) {
            return a.isDisabled ? 1 : -1;
          }
          return b.glycogenBurnKcalPerHour.compareTo(a.glycogenBurnKcalPerHour);
        });
        return copy;
      case EnergyHudSortMode.highestPower:
        copy.sort((a, b) {
          if (a.isDisabled != b.isDisabled) {
            return a.isDisabled ? 1 : -1;
          }
          return b.currentPowerWatts.compareTo(a.currentPowerWatts);
        });
        return copy;
    }
  }

  void _cycleSortMode() {
    setState(() {
      final int nextIndex =
          (_sortMode.index + 1) % EnergyHudSortMode.values.length;
      _sortMode = EnergyHudSortMode.values[nextIndex];
    });
  }

  String _sortModeLabel(EnergyHudSortMode mode) {
    switch (mode) {
      case EnergyHudSortMode.rosterOrder:
        return 'Roster';
      case EnergyHudSortMode.earliestBonk:
        return 'Bonk Risk';
      case EnergyHudSortMode.highestBurnRate:
        return 'kcal/h';
      case EnergyHudSortMode.highestPower:
        return 'Watts';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<RiderEnergyTelemetryData> sortedRiders = _getSortedRiders();
    int bonkRiskCount = 0;
    for (final RiderEnergyTelemetryData rider in sortedRiders) {
      if (!rider.isDisabled && rider.computeBonkPrediction().willBonkBeforeFinish) {
        bonkRiskCount++;
      }
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1200.0;
        final bool isCompactMobile = width < 600.0;
        final bool isTablet = width >= 600.0 && width < 1100.0;
        final int columns = isCompactMobile ? 1 : (isTablet ? 2 : 4);

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(isCompactMobile ? 10.0 : 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(
                isCompactMobile: isCompactMobile,
                riderCount: sortedRiders.length,
                bonkRiskCount: bonkRiskCount,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: _buildBody(
                          riders: sortedRiders,
                          columns: columns,
                          isCompactMobile: isCompactMobile,
                          availableWidth: width - (isCompactMobile ? 22.0 : 30.0),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required bool isCompactMobile,
    required int riderCount,
    required int bonkRiskCount,
  }) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Wrap(
          spacing: 8.0,
          runSpacing: 6.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'ENERGY & GLYCOGEN HUD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isCompactMobile ? 11.5 : 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$riderCount RIDERS • LAST 60S TELEMETRY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (bonkRiskCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.crimsonAlert.withValues(alpha: 0.65),
                  ),
                ),
                child: Text(
                  '$bonkRiskCount BONK RISK',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.crimsonAlert,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _HudFilterChip(
              label: 'ALL',
              isSelected: _metricMode == SparklineMetricMode.allOverlay,
              accentColor: AppColors.goldAccent,
              onPressed: () =>
                  setState(() => _metricMode = SparklineMetricMode.allOverlay),
            ),
            _HudFilterChip(
              label: 'W',
              isSelected: _metricMode == SparklineMetricMode.powerOnly,
              accentColor: AppColors.accentBlue,
              onPressed: () =>
                  setState(() => _metricMode = SparklineMetricMode.powerOnly),
            ),
            _HudFilterChip(
              label: 'BPM',
              isSelected: _metricMode == SparklineMetricMode.heartRateOnly,
              accentColor: AppColors.crimsonAlert,
              onPressed: () =>
                  setState(() => _metricMode = SparklineMetricMode.heartRateOnly),
            ),
            _HudFilterChip(
              label: 'KCAL',
              isSelected: _metricMode == SparklineMetricMode.glycogenOnly,
              accentColor: AppColors.amberWarning,
              onPressed: () =>
                  setState(() => _metricMode = SparklineMetricMode.glycogenOnly),
            ),
            _HudActionPillButton(
              icon: Icons.sort_rounded,
              label: _sortModeLabel(_sortMode),
              tooltip: 'Sort riders',
              onPressed: _cycleSortMode,
            ),
            _HudActionPillButton(
              icon: _isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              label: _isExpanded ? 'Hide' : 'Show',
              tooltip: _isExpanded ? 'Collapse HUD' : 'Expand HUD',
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody({
    required List<RiderEnergyTelemetryData> riders,
    required int columns,
    required bool isCompactMobile,
    required double availableWidth,
  }) {
    if (riders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.sensors_off_rounded,
                size: 16, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Text(
              'No active rider energy telemetry available.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    const double spacing = 10.0;
    final double cardWidth = columns == 1
        ? math.max(200.0, availableWidth)
        : math.max(
            180.0,
            (availableWidth - (spacing * (columns - 1))) / columns,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildLegendRow(),
        const SizedBox(height: 8),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final RiderEnergyTelemetryData rider in riders)
              SizedBox(
                width: cardWidth,
                child: _RiderEnergySparklineCard(
                  rider: rider,
                  isSelected: widget.selectedRiderId == rider.riderId,
                  metricMode: _metricMode,
                  pulseAnimation: _pulseController,
                  isCompact: isCompactMobile,
                  onTap: widget.onRiderSelected == null || rider.isDisabled
                      ? null
                      : () => widget.onRiderSelected!(rider),
                  onFeedGelPressed:
                      widget.onFeedGelPressed == null || rider.isDisabled
                          ? null
                          : () => widget.onFeedGelPressed!(rider),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendRow() {
    return const Wrap(
      spacing: 14,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _LegendDotLabel(
          color: AppColors.accentBlue,
          label: 'Power 60s (W / Z1–Z7)',
          isDashed: false,
        ),
        _LegendDotLabel(
          color: AppColors.crimsonAlert,
          label: 'Heart Rate 60s (BPM)',
          isDashed: true,
        ),
        _LegendDotLabel(
          color: AppColors.amberWarning,
          label: 'Glycogen Burn (kcal/h)',
          isDashed: false,
        ),
      ],
    );
  }
}

class _LegendDotLabel extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendDotLabel({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: isDashed ? 12 : 8,
          height: isDashed ? 2 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isDashed ? 1 : 4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _HudFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onPressed;

  const _HudFilterChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_HudFilterChip> createState() => _HudFilterChipState();
}

class _HudFilterChipState extends State<_HudFilterChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.22)
        : (_isHovered || _isPressed)
            ? AppColors.surfaceLight
            : AppColors.background.withValues(alpha: 0.7);
    final Color borderColor = _isFocused
        ? AppColors.cyanAccent
        : widget.isSelected
            ? widget.accentColor
            : _isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (bool v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (bool v) => setState(() => _isFocused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: widget.isSelected
                  ? widget.accentColor
                  : AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _HudActionPillButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HudActionPillButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_HudActionPillButton> createState() => _HudActionPillButtonState();
}

class _HudActionPillButtonState extends State<_HudActionPillButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    final Color borderColor = isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.cyanAccent
            : _isHovered
                ? AppColors.goldAccent.withValues(alpha: 0.7)
                : AppTheme.borderColor;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !isDisabled,
        onShowHoverHighlight: (bool v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _isFocused = v),
        mouseCursor:
            isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
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
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isDisabled
                  ? AppColors.surfaceLight.withValues(alpha: 0.3)
                  : _isPressed
                      ? AppColors.primaryAccent.withValues(alpha: 0.28)
                      : _isHovered
                          ? AppColors.surfaceLight
                          : AppColors.background.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 13,
                  color: isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : AppColors.textPrimary,
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

class _RiderEnergySparklineCard extends StatefulWidget {
  final RiderEnergyTelemetryData rider;
  final bool isSelected;
  final SparklineMetricMode metricMode;
  final Animation<double> pulseAnimation;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onFeedGelPressed;

  const _RiderEnergySparklineCard({
    required this.rider,
    required this.isSelected,
    required this.metricMode,
    required this.pulseAnimation,
    required this.isCompact,
    this.onTap,
    this.onFeedGelPressed,
  });

  @override
  State<_RiderEnergySparklineCard> createState() =>
      _RiderEnergySparklineCardState();
}

class _RiderEnergySparklineCardState extends State<_RiderEnergySparklineCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final RiderEnergyTelemetryData rider = widget.rider;
    final BonkPredictionResult bonkPrediction = rider.computeBonkPrediction();
    final PowerZoneInfo powerZone = MatchesBurnedCalculator.resolvePowerZone(
      powerWatts: rider.currentPowerWatts,
      ftpWatts: rider.ftpWatts,
    );

    final Color borderColor = rider.isDisabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.goldAccent
            : _isFocused
                ? AppColors.cyanAccent
                : _isHovered
                    ? AppColors.goldAccent.withValues(alpha: 0.65)
                    : bonkPrediction.isCriticalWarning
                        ? AppColors.crimsonAlert.withValues(alpha: 0.65)
                        : AppTheme.borderColor;

    final Color surfaceColor = rider.isDisabled
        ? AppColors.background.withValues(alpha: 0.6)
        : _isPressed
            ? AppColors.surfaceLight
            : _isHovered || widget.isSelected
                ? AppColors.surfaceLight.withValues(alpha: 0.92)
                : AppColors.background.withValues(alpha: 0.78);

    return Opacity(
      opacity: rider.isDisabled ? 0.48 : 1.0,
      child: FocusableActionDetector(
        enabled: !rider.isDisabled && widget.onTap != null,
        onShowHoverHighlight: (bool v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _isFocused = v),
        mouseCursor: (!rider.isDisabled && widget.onTap != null)
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => _isPressed = true),
          onTapUp: widget.onTap == null
              ? null
              : (_) => setState(() => _isPressed = false),
          onTapCancel: widget.onTap == null
              ? null
              : () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(widget.isCompact ? 10.0 : 11.0),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: widget.isSelected || _isFocused ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. Nagłówek kolarza
                Row(
                  children: <Widget>[
                    if (rider.bibNumber != null) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          '#${rider.bibNumber}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            fontFeatures: <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        rider.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        rider.roleTag,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: powerZone.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: powerZone.color.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Text(
                        powerZone.code,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: powerZone.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Aktualne odczyty W / BPM / kcal/h
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _MetricReadoutBadge(
                      value: '${rider.currentPowerWatts.round()} W',
                      color: powerZone.color,
                    ),
                    _MetricReadoutBadge(
                      value: '${rider.currentHeartRateBpm} BPM',
                      color: AppColors.crimsonAlert,
                    ),
                    _MetricReadoutBadge(
                      value: '${rider.glycogenBurnKcalPerHour.round()} kcal/h',
                      color: AppColors.amberWarning,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 3. Mini-wykres ostatnich 60 sekund
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.borderColor.withValues(alpha: 0.8),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: _EnergySparkline60sPainter(
                      samples: rider.last60SecondsSamples,
                      ftpWatts: rider.ftpWatts,
                      maxHeartRateBpm: rider.maxHeartRateBpm,
                      metricMode: widget.metricMode,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 7),

                // 4. Pasek glikogenu + prognoza kilometra odcięcia
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rider.glycogenPercent,
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            bonkPrediction.isCriticalWarning
                                ? AppColors.crimsonAlert
                                : bonkPrediction.willBonkBeforeFinish
                                    ? AppColors.amberWarning
                                    : AppColors.statusSuccess,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${rider.glycogenRemainingGrams.round()}g',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // 5. Baner prognozy odcięcia + przycisk żelu
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _BonkStatusBanner(
                        prediction: bonkPrediction,
                        isDisabled: rider.isDisabled,
                        pulseAnimation: widget.pulseAnimation,
                      ),
                    ),
                    if (widget.onFeedGelPressed != null &&
                        !rider.isDisabled &&
                        bonkPrediction.willBonkBeforeFinish) ...<Widget>[
                      const SizedBox(width: 6),
                      _FeedGelMiniButton(onPressed: widget.onFeedGelPressed!),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricReadoutBadge extends StatelessWidget {
  final String value;
  final Color color;

  const _MetricReadoutBadge({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

class _BonkStatusBanner extends StatelessWidget {
  final BonkPredictionResult prediction;
  final bool isDisabled;
  final Animation<double> pulseAnimation;

  const _BonkStatusBanner({
    required this.prediction,
    required this.isDisabled,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (isDisabled) {
      return const Text(
        'TELEMETRY OFFLINE',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      );
    }

    final Color statusColor = prediction.isAlreadyBonked
        ? AppColors.crimsonAlert
        : prediction.isCriticalWarning
            ? AppColors.crimsonAlert
            : prediction.willBonkBeforeFinish
                ? AppColors.amberWarning
                : AppColors.statusSuccess;

    final IconData icon = prediction.willBonkBeforeFinish
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (BuildContext context, Widget? child) {
        final double bgAlpha = prediction.isCriticalWarning
            ? (0.14 + 0.14 * pulseAnimation.value)
            : 0.12;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.55),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 12, color: statusColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  prediction.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeedGelMiniButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _FeedGelMiniButton({required this.onPressed});

  @override
  State<_FeedGelMiniButton> createState() => _FeedGelMiniButtonState();
}

class _FeedGelMiniButtonState extends State<_FeedGelMiniButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Send Energy Gel (+30g carbs)',
      child: FocusableActionDetector(
        onShowHoverHighlight: (bool v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (bool v) => setState(() => _isFocused = v),
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: _isPressed
                  ? AppColors.goldAccent.withValues(alpha: 0.35)
                  : _isHovered
                      ? AppColors.goldAccent.withValues(alpha: 0.24)
                      : AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _isFocused
                    ? AppColors.cyanAccent
                    : AppColors.goldAccent.withValues(alpha: 0.7),
              ),
            ),
            child: const Text(
              'GEL',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.goldAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rysujący mini-wykres 60s dla mocy (W), tętna (BPM) oraz tempa spalania (kcal/h).
class _EnergySparkline60sPainter extends CustomPainter {
  final List<EnergyExpenditureSample> samples;
  final double ftpWatts;
  final int maxHeartRateBpm;
  final SparklineMetricMode metricMode;

  const _EnergySparkline60sPainter({
    required this.samples,
    required this.ftpWatts,
    required this.maxHeartRateBpm,
    required this.metricMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Delikatna linia siatki poziomej w połowie wysokości
    final Paint gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.45)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      gridPaint,
    );

    if (samples.isEmpty) {
      return;
    }

    final List<EnergyExpenditureSample> window = samples.length > 60
        ? samples.sublist(samples.length - 60)
        : samples;

    final double safeFtp = math.max(100.0, ftpWatts);
    final double maxPower = math.max(
      safeFtp * 1.45,
      window.fold<double>(0.0, (double m, s) => math.max(m, s.powerWatts)),
    );
    const double minHr = 90.0;
    final double maxHr = math.max(175.0, maxHeartRateBpm.toDouble());

    double maxKcal = 1200.0;
    for (final EnergyExpenditureSample s in window) {
      if (s.glycogenBurnKcalPerHour > maxKcal) {
        maxKcal = s.glycogenBurnKcalPerHour;
      }
    }

    const double topPad = 4.0;
    const double bottomPad = 4.0;
    final double drawHeight = math.max(4.0, size.height - topPad - bottomPad);

    double xAt(int i) {
      if (window.length <= 1) return size.width;
      return (i / (window.length - 1)) * size.width;
    }

    double yPower(double watts) {
      final double norm = (watts / maxPower).clamp(0.0, 1.0);
      return topPad + drawHeight * (1.0 - norm);
    }

    double yHr(int bpm) {
      final double norm = ((bpm - minHr) / (maxHr - minHr)).clamp(0.0, 1.0);
      return topPad + drawHeight * (1.0 - norm);
    }

    double yKcal(double kcal) {
      final double norm = (kcal / maxKcal).clamp(0.0, 1.0);
      return topPad + drawHeight * (1.0 - norm);
    }

    // 1. Linia FTP referencyjna (jeśli widoczna moc)
    if (metricMode == SparklineMetricMode.allOverlay ||
        metricMode == SparklineMetricMode.powerOnly) {
      final double ftpY = yPower(safeFtp);
      _drawDashedLine(
        canvas,
        Offset(0, ftpY),
        Offset(size.width, ftpY),
        Paint()
          ..color = AppColors.textSecondary.withValues(alpha: 0.35)
          ..strokeWidth = 0.8,
        dashWidth: 3.0,
        dashSpace: 3.0,
      );
    }

    // 2. Wykres spalania glikogenu (kcal/h)
    if (metricMode == SparklineMetricMode.allOverlay ||
        metricMode == SparklineMetricMode.glycogenOnly) {
      final Path kcalPath = Path();
      for (int i = 0; i < window.length; i++) {
        final double x = xAt(i);
        final double y = yKcal(window[i].glycogenBurnKcalPerHour);
        if (i == 0) {
          kcalPath.moveTo(x, y);
        } else {
          kcalPath.lineTo(x, y);
        }
      }
      final Paint kcalPaint = Paint()
        ..color = AppColors.amberWarning.withValues(
          alpha: metricMode == SparklineMetricMode.glycogenOnly ? 0.95 : 0.65,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = metricMode == SparklineMetricMode.glycogenOnly ? 2.0 : 1.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(kcalPath, kcalPaint);
    }

    // 3. Wykres mocy (W) z wypełnieniem gradientowym
    if (metricMode == SparklineMetricMode.allOverlay ||
        metricMode == SparklineMetricMode.powerOnly) {
      final Path powerPath = Path();
      final Path fillPath = Path();
      for (int i = 0; i < window.length; i++) {
        final double x = xAt(i);
        final double y = yPower(window[i].powerWatts);
        if (i == 0) {
          powerPath.moveTo(x, y);
          fillPath.moveTo(x, size.height);
          fillPath.lineTo(x, y);
        } else {
          powerPath.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
      fillPath.lineTo(xAt(window.length - 1), size.height);
      fillPath.close();

      final Paint fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.accentBlue.withValues(alpha: 0.28),
            AppColors.accentBlue.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);

      final Paint powerPaint = Paint()
        ..color = AppColors.accentBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = metricMode == SparklineMetricMode.powerOnly ? 2.1 : 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(powerPath, powerPaint);
    }

    // 4. Wykres tętna (BPM) jako przerywana linia
    if (metricMode == SparklineMetricMode.allOverlay ||
        metricMode == SparklineMetricMode.heartRateOnly) {
      final Paint hrPaint = Paint()
        ..color = AppColors.crimsonAlert
        ..style = PaintingStyle.stroke
        ..strokeWidth = metricMode == SparklineMetricMode.heartRateOnly ? 2.0 : 1.4
        ..strokeCap = StrokeCap.round;

      if (window.length == 1) {
        canvas.drawCircle(
          Offset(xAt(0), yHr(window[0].heartRateBpm)),
          2.5,
          hrPaint..style = PaintingStyle.fill,
        );
      } else {
        for (int i = 0; i < window.length - 1; i++) {
          if (metricMode == SparklineMetricMode.allOverlay && i % 2 == 1) {
            continue;
          }
          canvas.drawLine(
            Offset(xAt(i), yHr(window[i].heartRateBpm)),
            Offset(xAt(i + 1), yHr(window[i + 1].heartRateBpm)),
            hrPaint,
          );
        }
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    double currentX = start.dx;
    while (currentX < end.dx) {
      final double nextX = math.min(currentX + dashWidth, end.dx);
      canvas.drawLine(Offset(currentX, start.dy), Offset(nextX, end.dy), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _EnergySparkline60sPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.ftpWatts != ftpWatts ||
        oldDelegate.maxHeartRateBpm != maxHeartRateBpm ||
        oldDelegate.metricMode != metricMode;
  }
}
