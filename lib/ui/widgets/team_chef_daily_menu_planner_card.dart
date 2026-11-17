import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/team_bus_chef_and_microbiome_nutrition.dart';

/// Karta planowania posiłków i bilansu energetycznego Szefa Kuchni Drużyny
/// w ekranie Dnia Przerwy (oraz przed kolejnym etapem).
///
/// Responsywna dla `390x844` (mobile), `1024x768` (tablet) i `1600x900` (desktop).
class TeamChefDailyMenuPlannerCard extends ConsumerStatefulWidget {
  final VoidCallback? onMenuCommitted;

  const TeamChefDailyMenuPlannerCard({
    super.key,
    this.onMenuCommitted,
  });

  @override
  ConsumerState<TeamChefDailyMenuPlannerCard> createState() =>
      _TeamChefDailyMenuPlannerCardState();
}

class _TeamChefDailyMenuPlannerCardState
    extends ConsumerState<TeamChefDailyMenuPlannerCard> {
  MealPeriodType _selectedMealPeriod = MealPeriodType.teamBusDinner;
  int? _lastCommittedDay;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamBusChefNutritionProvider);
    final notifier = ref.read(teamBusChefNutritionProvider.notifier);

    final roster = state.roster;
    final reports = state.lastSummary.reports;

    RiderNutritionalProfile? selectedRider;
    for (final r in roster) {
      if (r.riderId == state.selectedRiderId) {
        selectedRider = r;
        break;
      }
    }
    selectedRider ??= roster.isNotEmpty ? roster.first : null;

    GlycogenAndMicrobiomeRecoveryReport? selectedReport;
    if (selectedRider != null) {
      for (final rep in reports) {
        if (rep.riderId == selectedRider.riderId) {
          selectedReport = rep;
          break;
        }
      }
    }

    final isCommittedThisDay = _lastCommittedDay == state.dayIndex;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 640;
          final isDesktop = width >= 1024;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(
                context: context,
                state: state,
                notifier: notifier,
                isMobile: isMobile,
                isCommittedThisDay: isCommittedThisDay,
              ),
              const SizedBox(height: 14),
              _buildTeamKpiStrip(
                summary: state.lastSummary,
                isMobile: isMobile,
              ),
              const SizedBox(height: 14),
              _buildMealPeriodTimeline(
                isRestDay: state.isRestDay,
                isMobile: isMobile,
              ),
              const SizedBox(height: 14),
              if (roster.isEmpty)
                _buildEmptyRosterBanner()
              else if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildRiderSelectorPanel(
                        roster: roster,
                        reports: reports,
                        selectedRiderId: selectedRider?.riderId,
                        notifier: notifier,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 7,
                      child: selectedRider != null && selectedReport != null
                          ? _buildRiderEnergyAndMenuPanel(
                              rider: selectedRider,
                              report: selectedReport,
                              isRestDay: state.isRestDay,
                              notifier: notifier,
                              isMobile: isMobile,
                            )
                          : _buildEmptyRosterBanner(),
                    ),
                  ],
                )
              else ...[
                _buildRiderSelectorPanel(
                  roster: roster,
                  reports: reports,
                  selectedRiderId: selectedRider?.riderId,
                  notifier: notifier,
                ),
                const SizedBox(height: 12),
                if (selectedRider != null && selectedReport != null)
                  _buildRiderEnergyAndMenuPanel(
                    rider: selectedRider,
                    report: selectedReport,
                    isRestDay: state.isRestDay,
                    notifier: notifier,
                    isMobile: isMobile,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required TeamBusChefNutritionState state,
    required TeamBusChefNutritionNotifier notifier,
    required bool isMobile,
    required bool isCommittedThisDay,
  }) {
    final chef = state.activeChef;

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Planer Posiłków i Bilansu Energetycznego',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  _StatusBadge(
                    label: state.isRestDay ? 'Dzień Przerwy' : 'Dzień Etapowy',
                    color: state.isRestDay
                        ? AppColors.goldAccent
                        : AppColors.accentBlue,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Szef: ${chef.name} (${chef.tier.displayName}) • '
                '${state.kitchenTier.shortLabel} (${state.kitchenTier.foodSafetyHygieneScore.toStringAsFixed(0)}% higieny)',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Danie dnia: ${chef.signatureDish}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actionButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _PlannerActionButton(
          label: state.isRestDay ? 'Tryb: Dzień Przerwy' : 'Tryb: Etap',
          icon: state.isRestDay ? Icons.hotel_rounded : Icons.directions_bike,
          accentColor: AppColors.accentBlue,
          isOutlined: true,
          onPressed: () => notifier.toggleRestDay(!state.isRestDay),
        ),
        _PlannerActionButton(
          label: 'Auto-Optymalizuj',
          icon: Icons.auto_fix_high_rounded,
          accentColor: AppColors.goldAccent,
          isOutlined: true,
          onPressed: notifier.autoOptimizeMenu,
        ),
        _PlannerActionButton(
          label: isCommittedThisDay
              ? 'Jadłospis Zatwierdzony'
              : 'Zatwierdź Jadłospis',
          icon: isCommittedThisDay
              ? Icons.check_circle_rounded
              : Icons.restaurant_rounded,
          accentColor: AppColors.statusSuccess,
          isDisabled: isCommittedThisDay,
          onPressed: () {
            setState(() {
              _lastCommittedDay = state.dayIndex;
            });
            notifier.commitOvernightRecovery();
            widget.onMenuCommitted?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surfaceLight,
                content: Text(
                  'Zatwierdzono jadłospis i nocną regenerację (Dzień ${state.dayIndex}).',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                  ),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          actionButtons,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        actionButtons,
      ],
    );
  }

  Widget _buildTeamKpiStrip({
    required TeamDailyCateringSummary summary,
    required bool isMobile,
  }) {
    final glycogenColor = summary.averageGlycogenPercent >= 85
        ? AppColors.statusSuccess
        : (summary.averageGlycogenPercent >= 65
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);

    final microbiomeColor = summary.averageMicrobiomeIndex >= 80
        ? AppColors.statusSuccess
        : (summary.averageMicrobiomeIndex >= 65
            ? AppColors.accentBlue
            : AppColors.amberWarning);

    final riskCount = summary.ridersAtBonkRisk + summary.ridersWithRedSWarning;
    final riskColor =
        riskCount == 0 ? AppColors.statusSuccess : AppColors.crimsonAlert;

    final tiles = [
      _KpiMetricTile(
        label: 'Śr. Glikogen',
        value: '${summary.averageGlycogenPercent.toStringAsFixed(1)}%',
        sublabel: 'Cel: >= 90%',
        accentColor: glycogenColor,
        icon: Icons.bolt_rounded,
      ),
      _KpiMetricTile(
        label: 'Mikrobiom Jelit',
        value: '${summary.averageMicrobiomeIndex.toStringAsFixed(1)} pkt',
        sublabel: 'Tolerancja GI',
        accentColor: microbiomeColor,
        icon: Icons.spa_rounded,
      ),
      _KpiMetricTile(
        label: 'Ryzyko Bonk / RED-S',
        value: '$riskCount os.',
        sublabel:
            'Bonk: ${summary.ridersAtBonkRisk} • RED-S: ${summary.ridersWithRedSWarning}',
        accentColor: riskColor,
        icon: Icons.warning_amber_rounded,
      ),
      _KpiMetricTile(
        label: 'Koszt Cateringu',
        value: Formatters.formatCurrency(summary.totalCateringCostEur),
        sublabel:
            'Morale ${summary.teamMoraleDelta >= 0 ? '+' : ''}${summary.teamMoraleDelta.toStringAsFixed(1)}',
        accentColor: AppColors.goldAccent,
        icon: Icons.euro_rounded,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.05,
        children: tiles,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          Expanded(child: tiles[i]),
          if (i < tiles.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildMealPeriodTimeline({
    required bool isRestDay,
    required bool isMobile,
  }) {
    final spec = _MealPeriodSpec.forPeriod(
      _selectedMealPeriod,
      isRestDay: isRestDay,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Harmonogram Posiłków Dnia (5 Pór Żywienia)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${spec.sharePercent}% podaży dnia',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: MealPeriodType.values.map((period) {
                final isSelected = period == _selectedMealPeriod;
                final periodSpec = _MealPeriodSpec.forPeriod(
                  period,
                  isRestDay: isRestDay,
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PlannerInteractivePill(
                    label: periodSpec.shortTitle,
                    icon: periodSpec.icon,
                    isSelected: isSelected,
                    accentColor: periodSpec.accentColor,
                    onTap: () {
                      setState(() {
                        _selectedMealPeriod = period;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: spec.accentColor.withValues(alpha: 0.35),
              ),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMealPeriod.displayName,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: spec.accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spec.menuDescription,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Makro: ${spec.macroSplitLabel}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMealPeriod.displayName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: spec.accentColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              spec.menuDescription,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A2F3D)),
                        ),
                        child: Text(
                          spec.macroSplitLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
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

  Widget _buildRiderSelectorPanel({
    required List<RiderNutritionalProfile> roster,
    required List<GlycogenAndMicrobiomeRecoveryReport> reports,
    required String? selectedRiderId,
    required TeamBusChefNutritionNotifier notifier,
  }) {
    final reportsById = {for (final r in reports) r.riderId: r};

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kolarze Drużyny (Wybierz do Planowania Menu)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roster.map((rider) {
              final report = reportsById[rider.riderId];
              final isSelected = rider.riderId == selectedRiderId;
              final hasWarning = report != null &&
                  (report.caloricBalance.relativeEnergyDeficiencyRisk ||
                      report.endingGlycogenPercent < 70.0);
              final statusColor = hasWarning
                  ? AppColors.crimsonAlert
                  : rider.assignedStrategy.accentColor;

              return _RiderPlannerChip(
                rider: rider,
                endingGlycogen: report?.endingGlycogenPercent,
                isSelected: isSelected,
                accentColor: statusColor,
                hasWarning: hasWarning,
                onTap: () => notifier.selectRider(rider.riderId),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderEnergyAndMenuPanel({
    required RiderNutritionalProfile rider,
    required GlycogenAndMicrobiomeRecoveryReport report,
    required bool isRestDay,
    required TeamBusChefNutritionNotifier notifier,
    required bool isMobile,
  }) {
    final balance = report.caloricBalance;
    final netBalance = balance.netCaloricBalanceKcal;
    final netColor = balance.relativeEnergyDeficiencyRisk
        ? AppColors.crimsonAlert
        : (netBalance >= 0 ? AppColors.statusSuccess : AppColors.amberWarning);

    final intakeRatio = balance.totalDailyExpenditureKcal <= 0
        ? 1.0
        : (balance.plannedIntakeKcal / balance.totalDailyExpenditureKcal)
            .clamp(0.0, 1.35);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rider.riderName} • ${rider.role}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Masa: ${rider.bodyWeightKg.toStringAsFixed(1)} kg '
                      '(Cel: ${rider.targetRaceWeightKg.toStringAsFixed(1)} kg) • '
                      'Gut Training: ${rider.gutTrainingLevel}/100',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (balance.relativeEnergyDeficiencyRisk)
                const _StatusBadge(
                  label: 'ALERT RED-S',
                  color: AppColors.crimsonAlert,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Bilans energetyczny kcal
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Bilans Energetyczny Dnia',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${netBalance >= 0 ? '+' : ''}${netBalance.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: netColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 8,
                    color: AppColors.background,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        widthFactor: (intakeRatio / 1.25).clamp(0.05, 1.0),
                        child: Container(color: netColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _CompactStat(
                      label: 'BMR',
                      value: '${balance.bmrKcal.toStringAsFixed(0)} kcal',
                    ),
                    _CompactStat(
                      label: isRestDay ? 'Coffee Ride' : 'Etap',
                      value: '${balance.stageBurnKcal.toStringAsFixed(0)} kcal',
                    ),
                    _CompactStat(
                      label: 'Wydatek całkowity',
                      value:
                          '${balance.totalDailyExpenditureKcal.toStringAsFixed(0)} kcal',
                    ),
                    _CompactStat(
                      label: 'Planowana podaż',
                      value:
                          '${balance.plannedIntakeKcal.toStringAsFixed(0)} kcal',
                      valueColor: AppColors.goldAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Makroskładniki i odbudowa glikogenu/mikrobiomu
          if (isMobile) ...[
            _buildMacrosBox(balance),
            const SizedBox(height: 8),
            _buildRecoveryProjectionBox(report),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildMacrosBox(balance)),
                const SizedBox(width: 10),
                Expanded(child: _buildRecoveryProjectionBox(report)),
              ],
            ),
          const SizedBox(height: 12),

          // Strategia menu
          const Text(
            'Strategia Menu Kolarza:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NutritionMenuStrategy.values.map((strategy) {
              final isSelected = rider.assignedStrategy == strategy;
              return _PlannerInteractivePill(
                label: '${strategy.shortLabel} (${strategy.targetCarbsPerKg.toStringAsFixed(1)} g/kg)',
                isSelected: isSelected,
                accentColor: strategy.accentColor,
                onTap: () => notifier.setRiderStrategy(rider.riderId, strategy),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Kuracja probiotyczna i notatki Szefa Kuchni
          Row(
            children: [
              Expanded(
                child: _PlannerInteractivePill(
                  label: rider.dailyProbioticCourseActive
                      ? 'Kuracja Probiotyczna: AKTYWNA (+Mikrobiom)'
                      : 'Włącz Kurację Probiotyczną & Błonnik',
                  icon: Icons.medication_liquid_rounded,
                  isSelected: rider.dailyProbioticCourseActive,
                  accentColor: AppColors.statusSuccess,
                  onTap: () => notifier.toggleProbioticCourse(rider.riderId),
                ),
              ),
            ],
          ),
          if (report.chefNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...report.chefNotes.take(2).map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            note,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacrosBox(CaloricBalanceCalculation balance) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Makroskładniki Dnia',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _MacroLine(
            label: 'Węglowodany (CHO)',
            value:
                '${balance.carbsGrams.toStringAsFixed(0)} g (${balance.carbsPerKg.toStringAsFixed(1)} g/kg)',
            color: AppColors.amberWarning,
          ),
          _MacroLine(
            label: 'Białko (PRO)',
            value:
                '${balance.proteinGrams.toStringAsFixed(0)} g (${balance.proteinPerKg.toStringAsFixed(1)} g/kg)',
            color: AppColors.accentBlue,
          ),
          _MacroLine(
            label: 'Tłuszcze (FAT)',
            value: '${balance.fatGrams.toStringAsFixed(0)} g',
            color: AppColors.statusSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryProjectionBox(
    GlycogenAndMicrobiomeRecoveryReport report,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prognoza Regeneracji Nocnej',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _MacroLine(
            label: 'Glikogen',
            value:
                '${report.startingGlycogenPercent.toStringAsFixed(0)}% → '
                '${report.endingGlycogenPercent.toStringAsFixed(0)}%',
            color: report.endingGlycogenPercent >= 85
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
          ),
          _MacroLine(
            label: 'Mikrobiom',
            value:
                '${report.microbiomeBefore.toStringAsFixed(0)} → '
                '${report.microbiomeAfter.toStringAsFixed(0)}',
            color: report.microbiomeState.statusColor,
          ),
          _MacroLine(
            label: 'Wchłanianie CHO / GI',
            value:
                '${report.maxOnBikeCarbAbsorptionGPerHour.toStringAsFixed(0)} g/h • '
                'GI ${report.giDistressRiskPercent.toStringAsFixed(0)}%',
            color: report.giDistressRiskPercent >= 25
                ? AppColors.crimsonAlert
                : AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRosterBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: const Text(
        'Brak aktywnych kolarzy w planie żywieniowym drużyny.',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _MealPeriodSpec {
  final String shortTitle;
  final String menuDescription;
  final String macroSplitLabel;
  final int sharePercent;
  final IconData icon;
  final Color accentColor;

  const _MealPeriodSpec({
    required this.shortTitle,
    required this.menuDescription,
    required this.macroSplitLabel,
    required this.sharePercent,
    required this.icon,
    required this.accentColor,
  });

  factory _MealPeriodSpec.forPeriod(
    MealPeriodType period, {
    required bool isRestDay,
  }) {
    switch (period) {
      case MealPeriodType.breakfastPreStage:
        return _MealPeriodSpec(
          shortTitle: 'Śniadanie',
          menuDescription: isRestDay
              ? 'Owsianka na mleku migdałowym, omlet z białek jaj, jagody i sok z buraka przed Coffee Ride.'
              : 'Ryż na parze z miodem, omlet białkowy i sok z buraka 3h przed startem.',
          macroSplitLabel: '65% CHO • 20% PRO • 15% FAT',
          sharePercent: 24,
          icon: Icons.free_breakfast_rounded,
          accentColor: AppColors.goldAccent,
        );
      case MealPeriodType.onBikeFueling:
        return _MealPeriodSpec(
          shortTitle: isRestDay ? 'Coffee Ride' : 'Na Trasie',
          menuDescription: isRestDay
              ? 'Espresso, małe ciastko ryżowe i 1 bidon izotoniczny podczas lekkiego rozjazdu Z1.'
              : 'Hydrożele 90–110 g/h CHO, bidony z elektrolitami i batony ryżowe w strefie bufetu.',
          macroSplitLabel: '92% CHO • 5% PRO • 3% FAT',
          sharePercent: isRestDay ? 12 : 28,
          icon: Icons.local_cafe_rounded,
          accentColor: AppColors.amberWarning,
        );
      case MealPeriodType.postStageRecoveryShake:
        return const _MealPeriodSpec(
          shortTitle: 'Szejk +20m',
          menuDescription:
              'Izolat serwatki + maltodekstryna 3:1 i koncentrat wiśni Montmorency w oknie anabolicznym.',
          macroSplitLabel: '72% CHO • 25% PRO • 3% FAT',
          sharePercent: 18,
          icon: Icons.local_drink_rounded,
          accentColor: AppColors.accentBlue,
        );
      case MealPeriodType.teamBusDinner:
        return const _MealPeriodSpec(
          shortTitle: 'Kolacja',
          menuDescription:
              'Risotto szafranowe lub komosa ryżowa, grillowany łosoś/indyk oraz warzywa gotowane na parze.',
          macroSplitLabel: '58% CHO • 26% PRO • 16% FAT',
          sharePercent: 32,
          icon: Icons.dinner_dining_rounded,
          accentColor: AppColors.primaryAccent,
        );
      case MealPeriodType.lateEveningCaseinSnack:
        return const _MealPeriodSpec(
          shortTitle: 'Kazeina',
          menuDescription:
              'Kefir probiotyczny, białko kazeinowe i błonnik prebiotyczny wspierające nocną regenerację.',
          macroSplitLabel: '25% CHO • 60% PRO • 15% FAT',
          sharePercent: 14,
          icon: Icons.nightlight_round,
          accentColor: AppColors.statusSuccess,
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _KpiMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color accentColor;
  final IconData icon;

  const _KpiMetricTile({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CompactStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderPlannerChip extends StatefulWidget {
  final RiderNutritionalProfile rider;
  final double? endingGlycogen;
  final bool isSelected;
  final Color accentColor;
  final bool hasWarning;
  final VoidCallback onTap;

  const _RiderPlannerChip({
    required this.rider,
    required this.endingGlycogen,
    required this.isSelected,
    required this.accentColor,
    required this.hasWarning,
    required this.onTap,
  });

  @override
  State<_RiderPlannerChip> createState() => _RiderPlannerChipState();
}

class _RiderPlannerChipState extends State<_RiderPlannerChip> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.accentColor
        : (_isFocused
            ? AppColors.goldAccent
            : (_isHovered
                ? widget.accentColor.withValues(alpha: 0.7)
                : const Color(0xFF2A2F3D)));

    final bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.16)
        : (_isPressed
            ? AppColors.surfaceLight
            : (_isHovered ? AppColors.surfaceLight : AppColors.surface));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.hasWarning) ...[
                    const Icon(
                      Icons.warning_rounded,
                      size: 13,
                      color: AppColors.crimsonAlert,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    widget.rider.riderName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.rider.role} • '
                '${widget.endingGlycogen != null ? '${widget.endingGlycogen!.toStringAsFixed(0)}% glik.' : widget.rider.assignedStrategy.shortLabel}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: widget.isSelected
                      ? widget.accentColor
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerInteractivePill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _PlannerInteractivePill({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    this.icon,
  });

  @override
  State<_PlannerInteractivePill> createState() =>
      _PlannerInteractivePillState();
}

class _PlannerInteractivePillState extends State<_PlannerInteractivePill> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;
    final effectiveColor =
        isDisabled ? AppColors.textSecondary : widget.accentColor;

    final bgColor = widget.isSelected
        ? effectiveColor.withValues(alpha: 0.18)
        : (_isPressed
            ? AppColors.surfaceLight
            : (_isHovered
                ? effectiveColor.withValues(alpha: 0.08)
                : AppColors.surface));

    final borderColor = widget.isSelected
        ? effectiveColor
        : (_isFocused
            ? AppColors.goldAccent
            : (_isHovered
                ? effectiveColor.withValues(alpha: 0.6)
                : const Color(0xFF2A2F3D)));

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel:
            isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isSelected
                      ? effectiveColor
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isDisabled
                        ? AppColors.textSecondary
                        : (widget.isSelected
                            ? effectiveColor
                            : AppColors.textPrimary),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannerActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isOutlined;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _PlannerActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.onPressed,
    this.isOutlined = false,
    this.isDisabled = false,
  });

  @override
  State<_PlannerActionButton> createState() => _PlannerActionButtonState();
}

class _PlannerActionButtonState extends State<_PlannerActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDisabled;
    final baseColor = disabled ? AppColors.textSecondary : widget.accentColor;

    final bgColor = widget.isOutlined
        ? (_isPressed
            ? baseColor.withValues(alpha: 0.20)
            : (_isHovered
                ? baseColor.withValues(alpha: 0.12)
                : AppColors.surfaceLight))
        : (disabled
            ? AppColors.surfaceLight
            : (_isPressed
                ? baseColor.withValues(alpha: 0.85)
                : (_isHovered ? baseColor : baseColor.withValues(alpha: 0.90))));

    final fgColor = widget.isOutlined
        ? baseColor
        : (disabled ? AppColors.textSecondary : AppColors.background);

    final borderColor = _isFocused
        ? AppColors.goldAccent
        : (widget.isOutlined
            ? baseColor.withValues(alpha: disabled ? 0.3 : 0.65)
            : Colors.transparent);

    return FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: disabled ? null : () => setState(() => _isPressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: fgColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
