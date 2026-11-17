import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/physics/carbohydrate_hydrogel_and_ketones_engine.dart';
import '../../models/rider/rider.dart';

/// Alias PascalCase dla spójności z konwencją nazewnictwa widgetów.
typedef NutritionStrategyPlannerPanel = NutritionStrategyplannerPanel;

/// Konfiguracja indywidualnej strategii żywieniowej i suplementacyjnej kolarza.
class RiderNutritionPlanEntry {
  final String riderId;
  final String riderName;
  final String roleLabel;

  /// Poziom wytrenowania jelit do wysokich dawek węglowodanów [0.0 - 1.0].
  final double gutTrainingLevel;

  /// Tolerancja przewodu pokarmowego na wodorowęglan sodu [0.0 - 1.0].
  final double bicarbonateTolerance;

  /// Docelowa gramatura węglowodanów na godzinę [60.0 - 120.0 g/h].
  final double carbsGramsPerHour;

  /// Protokół dwuwęglanu sodu przed czasówkami / startem (+6% W').
  final bool useBicarbonatePreLoad;

  /// Protokół egzogennych ketonów po etapie (+12% nocnej regeneracji).
  final bool usePostStageKetones;

  /// Czy kolarz jest dopuszczony medycznie do pełnej suplementacji.
  final bool isClearedForSupplementation;

  /// Współczynnik bazowej regeneracji kolarza [0.5 - 2.0].
  final double riderRecoveryRate;

  const RiderNutritionPlanEntry({
    required this.riderId,
    required this.riderName,
    this.roleLabel = 'Kolarz',
    required this.gutTrainingLevel,
    this.bicarbonateTolerance = 0.65,
    this.carbsGramsPerHour = 80.0,
    this.useBicarbonatePreLoad = false,
    this.usePostStageKetones = false,
    this.isClearedForSupplementation = true,
    this.riderRecoveryRate = 1.0,
  });

  double get clampedCarbsPerHour => carbsGramsPerHour.clamp(60.0, 120.0);
  double get clampedGutTraining => gutTrainingLevel.clamp(0.0, 1.0);
  double get clampedBicarbTolerance => bicarbonateTolerance.clamp(0.0, 1.0);

  /// Buduje wpis planu żywienia na podstawie modelu [Rider] z kariery.
  factory RiderNutritionPlanEntry.fromRider(
    Rider rider, {
    String? roleLabel,
    bool isTimeTrialStage = false,
    double defaultCarbsPerHour = 85.0,
  }) {
    final double formFactor = (rider.physiology.form / 100.0).clamp(0.35, 1.0);
    final double recoveryNorm = (rider.physiology.recoveryRate > 2.0
            ? rider.physiology.recoveryRate / 100.0
            : rider.physiology.recoveryRate / 1.5)
        .clamp(0.35, 1.0);
    final double gutLevel = (0.45 + formFactor * 0.45).clamp(0.30, 0.98);
    final double bicarbTol = (0.40 + recoveryNorm * 0.50).clamp(0.30, 0.95);
    final bool cleared = rider.health.currentInjury == null;

    return RiderNutritionPlanEntry(
      riderId: rider.id,
      riderName: rider.fullName,
      roleLabel: roleLabel ?? rider.specialization.displayName,
      gutTrainingLevel: gutLevel,
      bicarbonateTolerance: bicarbTol,
      carbsGramsPerHour: defaultCarbsPerHour.clamp(60.0, 120.0),
      useBicarbonatePreLoad: isTimeTrialStage && cleared && bicarbTol >= 0.55,
      usePostStageKetones: cleared && rider.physiology.fatigue > 55.0,
      isClearedForSupplementation: cleared,
      riderRecoveryRate: (0.75 + recoveryNorm * 0.55).clamp(0.5, 2.0),
    );
  }

  RiderSupplementationProfile toSupplementationProfile() {
    return RiderSupplementationProfile(
      riderId: riderId,
      riderName: riderName,
      gutTrainingLevel: clampedGutTraining,
      bicarbonateTolerance: clampedBicarbTolerance,
      isClearedForSupplementation: isClearedForSupplementation,
    );
  }

  RiderNutritionPlanEntry copyWith({
    String? riderId,
    String? riderName,
    String? roleLabel,
    double? gutTrainingLevel,
    double? bicarbonateTolerance,
    double? carbsGramsPerHour,
    bool? useBicarbonatePreLoad,
    bool? usePostStageKetones,
    bool? isClearedForSupplementation,
    double? riderRecoveryRate,
  }) {
    return RiderNutritionPlanEntry(
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      roleLabel: roleLabel ?? this.roleLabel,
      gutTrainingLevel: gutTrainingLevel ?? this.gutTrainingLevel,
      bicarbonateTolerance: bicarbonateTolerance ?? this.bicarbonateTolerance,
      carbsGramsPerHour: carbsGramsPerHour ?? this.carbsGramsPerHour,
      useBicarbonatePreLoad: useBicarbonatePreLoad ?? this.useBicarbonatePreLoad,
      usePostStageKetones: usePostStageKetones ?? this.usePostStageKetones,
      isClearedForSupplementation:
          isClearedForSupplementation ?? this.isClearedForSupplementation,
      riderRecoveryRate: riderRecoveryRate ?? this.riderRecoveryRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'roleLabel': roleLabel,
      'gutTrainingLevel': gutTrainingLevel,
      'bicarbonateTolerance': bicarbonateTolerance,
      'carbsGramsPerHour': carbsGramsPerHour,
      'useBicarbonatePreLoad': useBicarbonatePreLoad,
      'usePostStageKetones': usePostStageKetones,
      'isClearedForSupplementation': isClearedForSupplementation,
      'riderRecoveryRate': riderRecoveryRate,
    };
  }

  factory RiderNutritionPlanEntry.fromJson(Map<String, dynamic> json) {
    return RiderNutritionPlanEntry(
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      roleLabel: json['roleLabel'] as String? ?? 'Kolarz',
      gutTrainingLevel: (json['gutTrainingLevel'] as num).toDouble(),
      bicarbonateTolerance: (json['bicarbonateTolerance'] as num?)?.toDouble() ?? 0.65,
      carbsGramsPerHour: (json['carbsGramsPerHour'] as num?)?.toDouble() ?? 80.0,
      useBicarbonatePreLoad: json['useBicarbonatePreLoad'] as bool? ?? false,
      usePostStageKetones: json['usePostStageKetones'] as bool? ?? false,
      isClearedForSupplementation: json['isClearedForSupplementation'] as bool? ?? true,
      riderRecoveryRate: (json['riderRecoveryRate'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Wynik kalkulacji tolerancji żołądkowej i korzyści metabolicznych dla kolarza.
class RiderNutritionEvaluation {
  final RiderNutritionPlanEntry entry;
  final double targetCarbsGramsPerHour;
  final double effectiveCarbsGramsPerHour;
  final double requiredGutTrainingLevel;
  final bool meetsGutRequirement;
  final double giDistressRiskFraction;
  final double giToleranceScore;
  final GiDistressSeverity projectedSeverity;
  final double wPrimeBonusPercent;
  final double overnightRecoveryBonusPercent;
  final int costEur;

  const RiderNutritionEvaluation({
    required this.entry,
    required this.targetCarbsGramsPerHour,
    required this.effectiveCarbsGramsPerHour,
    required this.requiredGutTrainingLevel,
    required this.meetsGutRequirement,
    required this.giDistressRiskFraction,
    required this.giToleranceScore,
    required this.projectedSeverity,
    required this.wPrimeBonusPercent,
    required this.overnightRecoveryBonusPercent,
    required this.costEur,
  });

  double get giDistressRiskPercent => (giDistressRiskFraction * 100.0).clamp(0.0, 100.0);
  double get giTolerancePercent => (giToleranceScore * 100.0).clamp(0.0, 100.0);
}

/// Zbiorcze podsumowanie planu żywienia dla całej drużyny.
class TeamNutritionStrategySummary {
  final int riderCount;
  final double averageCarbsPerHour;
  final double averageEffectiveCarbsPerHour;
  final double averageGiRiskPercent;
  final int warningCount;
  final int bicarbRidersCount;
  final int ketonesRidersCount;
  final int totalCostEur;

  const TeamNutritionStrategySummary({
    required this.riderCount,
    required this.averageCarbsPerHour,
    required this.averageEffectiveCarbsPerHour,
    required this.averageGiRiskPercent,
    required this.warningCount,
    required this.bicarbRidersCount,
    required this.ketonesRidersCount,
    required this.totalCostEur,
  });
}

/// Kalkulator fizjologiczny dla panelu planowania żywienia [NutritionStrategyplannerPanel].
class NutritionStrategyPlannerCalculator {
  NutritionStrategyPlannerCalculator._();

  static const double minCarbsGramsPerHour = 60.0;
  static const double maxCarbsGramsPerHour = 120.0;

  /// Wylicza wymaganą adaptację jelit [0.0 - 0.85] dla zadanej gramatury 60–120 g/h.
  static double requiredGutTrainingForCarbs(double carbsGramsPerHour) {
    final double clamped = carbsGramsPerHour.clamp(minCarbsGramsPerHour, maxCarbsGramsPerHour);
    if (clamped <= 65.0) return 0.0;
    // 65 -> 0.15, 90 -> 0.48, 110 -> 0.70, 120 -> 0.85
    return (((clamped - 60.0) / 60.0) * 0.85).clamp(0.0, 0.85);
  }

  /// Oblicza ocenę planu żywienia pojedynczego kolarza z wykorzystaniem [CarbohydrateHydrogelAndKetonesEngine].
  static RiderNutritionEvaluation evaluateRiderPlan({
    required RiderNutritionPlanEntry entry,
    double raceTemperatureCelsius = 22.0,
  }) {
    final double targetCarbs = entry.clampedCarbsPerHour;
    final double gut = entry.clampedGutTraining;
    final double reqGut = requiredGutTrainingForCarbs(targetCarbs);
    final bool meetsGut = gut >= reqGut;
    final RiderSupplementationProfile profile = entry.toSupplementationProfile();

    // Bazowa ocena węglowodanów przez silnik WorldTouru
    final TeamNutritionStrategyType carbStrategy = targetCarbs >= 90.0
        ? TeamNutritionStrategyType.highCarbHydrogel110g
        : TeamNutritionStrategyType.standard60gCho;

    final PreRaceNutritionStrategyEvaluation baseEval =
        CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
      strategy: carbStrategy,
      profile: profile,
      raceTemperatureCelsius: raceTemperatureCelsius,
    );

    // Płynna interpolacja efektywnej absorpcji dla zakresu 60–120 g/h
    final double ratioAbove60 = ((targetCarbs - 60.0) / 60.0).clamp(0.0, 1.0);
    final double absorptionCapacity = 60.0 + 60.0 * math.min(1.0, gut / math.max(0.25, reqGut == 0 ? 0.25 : reqGut));
    final double effectiveCarbs = math.min(
      targetCarbs,
      math.max(60.0, absorptionCapacity * (0.85 + 0.15 * gut)),
    );

    // Ryzyko GI z węglowodanów rośnie nieliniowo powyżej 90 g/h przy niedostatecznym wytrenowaniu jelit
    double carbRisk = 0.02 + ratioAbove60 * 0.06;
    if (!meetsGut) {
      carbRisk += (reqGut - gut) * 0.58;
    }

    // Dodatkowe ryzyko przy wodorowęglanie sodu przed czasówkami
    double bicarbRisk = 0.0;
    double wPrimeBonus = 0.0;
    int cost = targetCarbs >= 100.0
        ? TeamNutritionStrategyType.highCarbHydrogel110g.costPerRiderEur
        : (targetCarbs >= 80.0 ? 30 : TeamNutritionStrategyType.standard60gCho.costPerRiderEur);

    if (entry.useBicarbonatePreLoad && entry.isClearedForSupplementation) {
      final PreRaceNutritionStrategyEvaluation bicarbEval =
          CarbohydrateHydrogelAndKetonesEngine.evaluatePreRaceStrategy(
        strategy: TeamNutritionStrategyType.bicarbonatePreLoad,
        profile: profile,
        raceTemperatureCelsius: raceTemperatureCelsius,
      );
      bicarbRisk = bicarbEval.giDistressRiskFraction * 0.85;
      wPrimeBonus = bicarbEval.wPrimeBonusPercent;
      cost += TeamNutritionStrategyType.bicarbonatePreLoad.costPerRiderEur;
    }

    // Ketony po etapie (+12% nocnej regeneracji)
    double recoveryBonus = 0.0;
    if (entry.usePostStageKetones && entry.isClearedForSupplementation) {
      final OvernightKetoneRecoveryResult ketoneRec =
          CarbohydrateHydrogelAndKetonesEngine.computeOvernightRecovery(
        strategy: TeamNutritionStrategyType.postFinishExogenousKetones,
        baseFatigueDropAtl: 10.0,
        baseGlycogenResynthesisGrams: 320.0,
        riderRecoveryRate: entry.riderRecoveryRate,
      );
      recoveryBonus = ketoneRec.recoveryBoostPercent;
      cost += TeamNutritionStrategyType.postFinishExogenousKetones.costPerRiderEur;
    }

    final double heatFactor = raceTemperatureCelsius > 28.0
        ? (1.0 + (raceTemperatureCelsius - 28.0) * 0.025).clamp(1.0, 1.35)
        : 1.0;

    final double combinedRisk =
        ((baseEval.giDistressRiskFraction * 0.35 + carbRisk * 0.65 + bicarbRisk) * heatFactor)
            .clamp(0.01, 0.80);

    final double toleranceScore = (1.0 - combinedRisk).clamp(0.0, 1.0);

    final GiDistressSeverity severity;
    if (!entry.isClearedForSupplementation || combinedRisk >= 0.32) {
      severity = GiDistressSeverity.severe;
    } else if (combinedRisk >= 0.20) {
      severity = GiDistressSeverity.moderate;
    } else if (combinedRisk >= 0.10) {
      severity = GiDistressSeverity.mild;
    } else {
      severity = GiDistressSeverity.none;
    }

    return RiderNutritionEvaluation(
      entry: entry,
      targetCarbsGramsPerHour: targetCarbs,
      effectiveCarbsGramsPerHour: effectiveCarbs,
      requiredGutTrainingLevel: reqGut,
      meetsGutRequirement: meetsGut,
      giDistressRiskFraction: combinedRisk,
      giToleranceScore: toleranceScore,
      projectedSeverity: severity,
      wPrimeBonusPercent: wPrimeBonus,
      overnightRecoveryBonusPercent: recoveryBonus,
      costEur: cost,
    );
  }

  /// Wylicza podsumowanie całego składu drużyny.
  static TeamNutritionStrategySummary evaluateTeamSummary({
    required List<RiderNutritionPlanEntry> entries,
    double raceTemperatureCelsius = 22.0,
  }) {
    if (entries.isEmpty) {
      return const TeamNutritionStrategySummary(
        riderCount: 0,
        averageCarbsPerHour: 0.0,
        averageEffectiveCarbsPerHour: 0.0,
        averageGiRiskPercent: 0.0,
        warningCount: 0,
        bicarbRidersCount: 0,
        ketonesRidersCount: 0,
        totalCostEur: 0,
      );
    }

    double sumTargetCarbs = 0.0;
    double sumEffectiveCarbs = 0.0;
    double sumRiskPct = 0.0;
    int warnings = 0;
    int bicarbCount = 0;
    int ketonesCount = 0;
    int totalCost = 0;

    for (final entry in entries) {
      final eval = evaluateRiderPlan(
        entry: entry,
        raceTemperatureCelsius: raceTemperatureCelsius,
      );
      sumTargetCarbs += eval.targetCarbsGramsPerHour;
      sumEffectiveCarbs += eval.effectiveCarbsGramsPerHour;
      sumRiskPct += eval.giDistressRiskPercent;
      if (!eval.meetsGutRequirement ||
          eval.projectedSeverity == GiDistressSeverity.moderate ||
          eval.projectedSeverity == GiDistressSeverity.severe) {
        warnings++;
      }
      if (entry.useBicarbonatePreLoad && entry.isClearedForSupplementation) {
        bicarbCount++;
      }
      if (entry.usePostStageKetones && entry.isClearedForSupplementation) {
        ketonesCount++;
      }
      totalCost += eval.costEur;
    }

    final int count = entries.length;
    return TeamNutritionStrategySummary(
      riderCount: count,
      averageCarbsPerHour: sumTargetCarbs / count,
      averageEffectiveCarbsPerHour: sumEffectiveCarbs / count,
      averageGiRiskPercent: sumRiskPct / count,
      warningCount: warnings,
      bicarbRidersCount: bicarbCount,
      ketonesRidersCount: ketonesCount,
      totalCostEur: totalCost,
    );
  }
}

/// Panel planowania żywienia i suplementacji dla Odprawy Przedstartowej oraz Centrum Medycznego.
///
/// Pozwala konfigurować:
/// - gramaturę węglowodanów na godzinę (60–120 g/h),
/// - protokół dwuwęglanu sodu przed czasówkami (+6% W'),
/// - protokół ketonów egzogennych po etapie (+12% regeneracji nocnej),
/// - wskaźnik tolerancji żołądkowej (GI Tolerance) każdego kolarza.
class NutritionStrategyplannerPanel extends StatefulWidget {
  final List<RiderNutritionPlanEntry> initialRiders;
  final bool isTimeTrialStage;
  final double raceTemperatureCelsius;
  final String contextTitle;
  final bool enabled;
  final ValueChanged<List<RiderNutritionPlanEntry>>? onPlanChanged;
  final ValueChanged<List<RiderNutritionPlanEntry>>? onApplyTeamPlan;

  const NutritionStrategyplannerPanel({
    super.key,
    required this.initialRiders,
    this.isTimeTrialStage = false,
    this.raceTemperatureCelsius = 22.0,
    this.contextTitle = 'PLANER ŻYWIENIA & SUPLEMENTACJI WORLDTOUR',
    this.enabled = true,
    this.onPlanChanged,
    this.onApplyTeamPlan,
  });

  @override
  State<NutritionStrategyplannerPanel> createState() =>
      _NutritionStrategyplannerPanelState();
}

class _NutritionStrategyplannerPanelState
    extends State<NutritionStrategyplannerPanel> {
  late List<RiderNutritionPlanEntry> _riders;
  int _selectedRiderIndex = 0;
  String? _hoveredPresetId;
  bool _applyFeedbackVisible = false;

  @override
  void initState() {
    super.initState();
    _riders = List<RiderNutritionPlanEntry>.from(widget.initialRiders);
  }

  @override
  void didUpdateWidget(covariant NutritionStrategyplannerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRiders != widget.initialRiders) {
      _riders = List<RiderNutritionPlanEntry>.from(widget.initialRiders);
      if (_selectedRiderIndex >= _riders.length) {
        _selectedRiderIndex = math.max(0, _riders.length - 1);
      }
    }
  }

  void _updateRider(int index, RiderNutritionPlanEntry updated) {
    if (!widget.enabled || index < 0 || index >= _riders.length) return;
    setState(() {
      _riders[index] = updated;
      _applyFeedbackVisible = false;
    });
    widget.onPlanChanged?.call(List<RiderNutritionPlanEntry>.unmodifiable(_riders));
  }

  void _applyTeamPreset({
    required double carbsPerHour,
    bool? bicarb,
    bool? ketones,
  }) {
    if (!widget.enabled || _riders.isEmpty) return;
    setState(() {
      _riders = [
        for (final r in _riders)
          r.copyWith(
            carbsGramsPerHour: carbsPerHour.clamp(60.0, 120.0),
            useBicarbonatePreLoad: r.isClearedForSupplementation
                ? (bicarb ?? r.useBicarbonatePreLoad)
                : false,
            usePostStageKetones: r.isClearedForSupplementation
                ? (ketones ?? r.usePostStageKetones)
                : false,
          ),
      ];
      _applyFeedbackVisible = true;
    });
    widget.onPlanChanged?.call(List<RiderNutritionPlanEntry>.unmodifiable(_riders));
  }

  void _commitTeamPlan() {
    if (!widget.enabled || _riders.isEmpty) return;
    setState(() {
      _applyFeedbackVisible = true;
    });
    widget.onApplyTeamPlan?.call(List<RiderNutritionPlanEntry>.unmodifiable(_riders));
  }

  @override
  Widget build(BuildContext context) {
    final summary = NutritionStrategyPlannerCalculator.evaluateTeamSummary(
      entries: _riders,
      raceTemperatureCelsius: widget.raceTemperatureCelsius,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.enabled ? AppTheme.borderColor : AppColors.cardBorder.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.62,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isMobile = width < 640;
            final bool isDesktop = width >= 1060;

            return Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(summary, isMobile: isMobile),
                  const SizedBox(height: 12),
                  _buildTeamPresetsBar(isMobile: isMobile),
                  const SizedBox(height: 14),
                  if (_riders.isEmpty)
                    _buildEmptyState()
                  else if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildRidersListSection(isCompact: false),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: _buildSelectedRiderDetailSection(isMobile: false),
                        ),
                      ],
                    )
                  else ...[
                    _buildRidersListSection(isCompact: isMobile),
                    const SizedBox(height: 14),
                    _buildSelectedRiderDetailSection(isMobile: isMobile),
                  ],
                  if (_riders.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildFooterSummaryBar(summary, isMobile: isMobile),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    TeamNutritionStrategySummary summary, {
    required bool isMobile,
  }) {
    final titleRow = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.45)),
          ),
          child: const Icon(
            Icons.local_drink_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contextTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.isTimeTrialStage
                    ? 'Etap Jazdy na Czas (ITT/TTT) • Zalecany protokół Bicarbonate (+6% W\')'
                    : 'Temp. wyścigu ${widget.raceTemperatureCelsius.toStringAsFixed(0)}°C • Hydrożel 60–120 g/h & Ketony',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final badges = Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _MetricBadge(
          label: 'ŚR. CHO',
          value: '${summary.averageCarbsPerHour.toStringAsFixed(0)} g/h',
          color: AppColors.cyanAccent,
        ),
        _MetricBadge(
          label: 'RYZYKO GI',
          value: '${summary.averageGiRiskPercent.toStringAsFixed(1)}%',
          color: summary.averageGiRiskPercent >= 20.0
              ? AppColors.crimsonAlert
              : (summary.averageGiRiskPercent >= 10.0
                  ? AppColors.amberWarning
                  : AppColors.statusSuccess),
        ),
        if (widget.isTimeTrialStage)
          const _MetricBadge(
            label: 'TRYB',
            value: 'CZASÓWKA TT',
            color: AppColors.goldAccent,
          ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const SizedBox(height: 10),
          badges,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleRow),
        const SizedBox(width: 12),
        badges,
      ],
    );
  }

  Widget _buildTeamPresetsBar({required bool isMobile}) {
    final presets = <({
      String id,
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
    })>[
      (
        id: 'standard60',
        label: 'Standard 60 g/h',
        icon: Icons.water_drop_outlined,
        color: AppColors.accentBlue,
        onTap: () => _applyTeamPreset(carbsPerHour: 60.0, bicarb: false),
      ),
      (
        id: 'hydrogel110',
        label: 'Hydrożel 110 g/h',
        icon: Icons.bolt_rounded,
        color: AppColors.cyanAccent,
        onTap: () => _applyTeamPreset(carbsPerHour: 110.0),
      ),
      (
        id: 'pro120',
        label: 'Pro Max 120 g/h',
        icon: Icons.rocket_launch_rounded,
        color: AppColors.goldAccent,
        onTap: () => _applyTeamPreset(carbsPerHour: 120.0),
      ),
      (
        id: 'bicarb_tt',
        label: 'Czasówka: Dwuwęglan',
        icon: Icons.timer_outlined,
        color: AppColors.amberWarning,
        onTap: () => _applyTeamPreset(carbsPerHour: 90.0, bicarb: true),
      ),
      (
        id: 'ketones_rec',
        label: 'Po etapie: Ketony',
        icon: Icons.nights_stay_outlined,
        color: AppColors.statusSuccess,
        onTap: () => _applyTeamPreset(carbsPerHour: 90.0, ketones: true),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRESETY ZESPOŁOWE (ZASTOSUJ DLA CAŁEJ EKIPY)',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final bool isHovered = _hoveredPresetId == preset.id;
              return _InteractiveActionChip(
                label: preset.label,
                icon: preset.icon,
                accentColor: preset.color,
                enabled: widget.enabled && _riders.isNotEmpty,
                isHovered: isHovered,
                onHoverChanged: (hover) {
                  setState(() {
                    _hoveredPresetId = hover ? preset.id : null;
                  });
                },
                onPressed: preset.onTap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.no_food_outlined,
            color: AppColors.textSecondary,
            size: 32,
          ),
          SizedBox(height: 10),
          Text(
            'Brak przypisanych kolarzy do planu żywienia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Dodaj zawodników do składu etapowego lub kadry medycznej, aby skonfigurować węglowodany, dwuwęglan sodu i ketony.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidersListSection({required bool isCompact}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOLERANCJA ŻOŁĄDKOWA KOLARZY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                '${_riders.length} zaw.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _riders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = _riders[index];
              final eval = NutritionStrategyPlannerCalculator.evaluateRiderPlan(
                entry: entry,
                raceTemperatureCelsius: widget.raceTemperatureCelsius,
              );
              final bool isSelected = index == _selectedRiderIndex;

              return _RiderNutritionRowTile(
                entry: entry,
                evaluation: eval,
                isSelected: isSelected,
                enabled: widget.enabled,
                isCompact: isCompact,
                onTap: () {
                  setState(() {
                    _selectedRiderIndex = index;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRiderDetailSection({required bool isMobile}) {
    final int safeIndex = _selectedRiderIndex.clamp(0, _riders.length - 1);
    final entry = _riders[safeIndex];
    final eval = NutritionStrategyPlannerCalculator.evaluateRiderPlan(
      entry: entry,
      raceTemperatureCelsius: widget.raceTemperatureCelsius,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: Container(
        key: ValueKey<String>(entry.riderId),
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedRiderHeader(entry, eval, isMobile: isMobile),
            const SizedBox(height: 14),
            _buildGiToleranceGaugeCard(entry, eval),
            const SizedBox(height: 14),
            _buildCarbsSliderCard(safeIndex, entry, eval, isMobile: isMobile),
            const SizedBox(height: 12),
            _buildProtocolToggles(safeIndex, entry, eval, isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedRiderHeader(
    RiderNutritionPlanEntry entry,
    RiderNutritionEvaluation eval, {
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.riderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.roleLabel} • Adaptacja jelit: ${(entry.clampedGutTraining * 100).round()}% • Tolerancja NaHCO₃: ${(entry.clampedBicarbTolerance * 100).round()}%',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: eval.projectedSeverity.statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: eval.projectedSeverity.statusColor.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            eval.projectedSeverity.displayName,
            style: TextStyle(
              fontFamily: 'Inter',
              color: eval.projectedSeverity.statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiToleranceGaugeCard(
    RiderNutritionPlanEntry entry,
    RiderNutritionEvaluation eval,
  ) {
    final Color statusColor = eval.projectedSeverity.statusColor;
    final double toleranceValue = eval.giToleranceScore.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: statusColor, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'WSKAŹNIK TOLERANCJI ŻOŁĄDKOWEJ (GI TOLERANCE)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${eval.giTolerancePercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: toleranceValue, end: toleranceValue),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Ryzyko GI Distress: ${eval.giDistressRiskPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Efektywna absorpcja: ${eval.effectiveCarbsGramsPerHour.toStringAsFixed(0)} g/h',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (!eval.meetsGutRequirement)
                Text(
                  'Wymagane wytrenowanie jelit ≥ ${(eval.requiredGutTrainingLevel * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.amberWarning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarbsSliderCard(
    int index,
    RiderNutritionPlanEntry entry,
    RiderNutritionEvaluation eval, {
    required bool isMobile,
  }) {
    final double carbs = entry.clampedCarbsPerHour;
    const List<double> quickDoses = [60.0, 80.0, 90.0, 110.0, 120.0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gramatura węglowodanów (CHO)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyanAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${carbs.round()} g/h',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.cyanAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.cyanAccent,
              inactiveTrackColor: AppColors.background,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
              disabledActiveTrackColor: AppColors.textSecondary.withValues(alpha: 0.4),
              disabledThumbColor: AppColors.textSecondary,
            ),
            child: Slider(
              value: carbs,
              min: 60.0,
              max: 120.0,
              divisions: 12,
              label: '${carbs.round()} g/h',
              onChanged: widget.enabled
                  ? (val) {
                      _updateRider(
                        index,
                        entry.copyWith(carbsGramsPerHour: val),
                      );
                    }
                  : null,
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickDoses.map((dose) {
              final bool active = (carbs - dose).abs() < 2.5;
              return _DoseChip(
                label: '${dose.round()} g/h',
                active: active,
                enabled: widget.enabled,
                onTap: () {
                  _updateRider(index, entry.copyWith(carbsGramsPerHour: dose));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolToggles(
    int index,
    RiderNutritionPlanEntry entry,
    RiderNutritionEvaluation eval, {
    required bool isMobile,
  }) {
    final bool canUseSupplements = widget.enabled && entry.isClearedForSupplementation;

    final bicarbCard = _ProtocolToggleCard(
      title: 'Dwuwęglan sodu przed czasówką',
      subtitle: widget.isTimeTrialStage
          ? 'Rekomendowane na ITT/TTT • +6% W\' i buforowanie mleczanu'
          : 'Protokół Bicarbonate Pre-Load • +6% pojemności beztlenowej W\'',
      badgeText: '+6% W\'',
      accentColor: AppColors.amberWarning,
      icon: Icons.science_outlined,
      value: entry.useBicarbonatePreLoad,
      enabled: canUseSupplements,
      warningText: !entry.isClearedForSupplementation
          ? 'Kolarz niedopuszczony medycznie'
          : (entry.clampedBicarbTolerance < 0.50
              ? 'Niska tolerancja NaHCO₃ (${(entry.clampedBicarbTolerance * 100).round()}%)'
              : null),
      onChanged: (val) {
        _updateRider(index, entry.copyWith(useBicarbonatePreLoad: val));
      },
    );

    final ketonesCard = _ProtocolToggleCard(
      title: 'Ketony egzogenne po etapie',
      subtitle: 'Estry ketonowe na mecie • +12% nocnej regeneracji glikogenu i spadku ATL',
      badgeText: '+12% REC',
      accentColor: AppColors.goldAccent,
      icon: Icons.nights_stay_rounded,
      value: entry.usePostStageKetones,
      enabled: canUseSupplements,
      warningText: !entry.isClearedForSupplementation
          ? 'Kolarz niedopuszczony medycznie'
          : null,
      onChanged: (val) {
        _updateRider(index, entry.copyWith(usePostStageKetones: val));
      },
    );

    if (isMobile) {
      return Column(
        children: [
          bicarbCard,
          const SizedBox(height: 10),
          ketonesCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: bicarbCard),
        const SizedBox(width: 10),
        Expanded(child: ketonesCard),
      ],
    );
  }

  Widget _buildFooterSummaryBar(
    TeamNutritionStrategySummary summary, {
    required bool isMobile,
  }) {
    final stats = Wrap(
      spacing: 14,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Koszt etapu: €${summary.totalCostEur}',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.goldAccent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          'Dwuwęglan: ${summary.bicarbRidersCount}/${summary.riderCount}',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Ketony: ${summary.ketonesRidersCount}/${summary.riderCount}',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (summary.warningCount > 0)
          Text(
            'Ostrzeżenia GI: ${summary.warningCount}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.amberWarning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );

    final applyButton = ElevatedButton.icon(
      onPressed: widget.enabled ? _commitTeamPlan : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _applyFeedbackVisible ? AppColors.statusSuccess : AppColors.primaryAccent,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.surfaceLight,
        disabledForegroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(
        _applyFeedbackVisible ? Icons.check_circle_outline : Icons.save_outlined,
        size: 18,
      ),
      label: Text(
        _applyFeedbackVisible ? 'Plan Żywienia Zapisany' : 'Zatwierdź Plan Żywienia',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stats,
                const SizedBox(height: 10),
                applyButton,
              ],
            )
          : Row(
              children: [
                Expanded(child: stats),
                const SizedBox(width: 12),
                applyButton,
              ],
            ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final bool isHovered;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onPressed;

  const _InteractiveActionChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    required this.isHovered,
    required this.onHoverChanged,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionChip> createState() => _InteractiveActionChipState();
}

class _InteractiveActionChipState extends State<_InteractiveActionChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_focused || widget.isHovered
            ? widget.accentColor
            : widget.accentColor.withValues(alpha: 0.45));

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => widget.onHoverChanged(true),
      onExit: (_) => widget.onHoverChanged(false),
      child: Focus(
        onFocusChange: (focus) => setState(() => _focused = focus),
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isHovered && widget.enabled
                  ? widget.accentColor.withValues(alpha: 0.20)
                  : widget.accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.enabled ? widget.accentColor : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _RiderNutritionRowTile extends StatefulWidget {
  final RiderNutritionPlanEntry entry;
  final RiderNutritionEvaluation evaluation;
  final bool isSelected;
  final bool enabled;
  final bool isCompact;
  final VoidCallback onTap;

  const _RiderNutritionRowTile({
    required this.entry,
    required this.evaluation,
    required this.isSelected,
    required this.enabled,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_RiderNutritionRowTile> createState() => _RiderNutritionRowTileState();
}

class _RiderNutritionRowTileState extends State<_RiderNutritionRowTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = widget.evaluation.projectedSeverity.statusColor;
    final Color borderColor = widget.isSelected
        ? AppColors.goldAccent
        : (_focused || _hovered ? AppColors.cyanAccent : AppTheme.borderColor);

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        onFocusChange: (focus) => setState(() => _focused = focus),
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 10 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primaryAccent.withValues(alpha: 0.16)
                  : (_hovered ? AppColors.surface.withValues(alpha: 0.9) : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: widget.isSelected ? 1.4 : 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.entry.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.entry.clampedCarbsPerHour.round()} g/h',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.evaluation.giToleranceScore,
                          minHeight: 5,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GI ${widget.evaluation.giTolerancePercent.round()}%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (widget.entry.useBicarbonatePreLoad) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.science_outlined, size: 13, color: AppColors.amberWarning),
                    ],
                    if (widget.entry.usePostStageKetones) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.nights_stay_rounded, size: 13, color: AppColors.goldAccent),
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

class _DoseChip extends StatefulWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _DoseChip({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_DoseChip> createState() => _DoseChipState();
}

class _DoseChipState extends State<_DoseChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.cyanAccent.withValues(alpha: 0.22)
                : (_hovered ? AppColors.surfaceLight : AppColors.background),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.active ? AppColors.cyanAccent : AppTheme.borderColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: widget.active ? AppColors.cyanAccent : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProtocolToggleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color accentColor;
  final IconData icon;
  final bool value;
  final bool enabled;
  final String? warningText;
  final ValueChanged<bool> onChanged;

  const _ProtocolToggleCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.accentColor,
    required this.icon,
    required this.value,
    required this.enabled,
    required this.warningText,
    required this.onChanged,
  });

  @override
  State<_ProtocolToggleCard> createState() => _ProtocolToggleCardState();
}

class _ProtocolToggleCardState extends State<_ProtocolToggleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.value
        ? widget.accentColor.withValues(alpha: 0.7)
        : (_hovered && widget.enabled ? widget.accentColor.withValues(alpha: 0.4) : AppTheme.borderColor);

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.value
                ? widget.accentColor.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: widget.accentColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: widget.value,
                    activeTrackColor: widget.accentColor,
                    onChanged: widget.enabled ? widget.onChanged : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.badgeText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: widget.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.warningText != null)
                    Text(
                      widget.warningText!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.crimsonAlert,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
