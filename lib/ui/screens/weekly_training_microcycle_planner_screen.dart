// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/rider/rider.dart';
import '../../services/career/custom_training_microcycle_builder_service.dart';

/// Interaktywny ekran kalendarza tygodniowego mikrocyklu treningowego
/// z wyliczaniem dziennego/tygodniowego TSS oraz prognozą formy Banistera (CTL/ATL/TSB).
///
/// Obsługuje responsywnie rozdzielczości `390x844`, `1024x768` i `1600x900`.
class WeeklyTrainingMicrocyclePlannerScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const WeeklyTrainingMicrocyclePlannerScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<WeeklyTrainingMicrocyclePlannerScreen> createState() =>
      _WeeklyTrainingMicrocyclePlannerScreenState();
}

class _WeeklyTrainingMicrocyclePlannerScreenState
    extends ConsumerState<WeeklyTrainingMicrocyclePlannerScreen> {
  MicrocycleDayOfWeek? _swapSourceDay;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customTrainingMicrocycleProvider);
    final notifier = ref.read(customTrainingMicrocycleProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1200;
            final isTablet = width >= 720 && width < 1200;
            final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 18.0 : 12.0);

            return Column(
              children: [
                _PlannerHeaderBar(
                  state: state,
                  isCompact: !isDesktop && !isTablet,
                  onBack: widget.onBack ??
                      (Navigator.canPop(context)
                          ? () => Navigator.of(context).pop()
                          : null),
                  onSaveTemplate: notifier.saveCurrentAsTemplate,
                  onApplyPlan: notifier.applyActiveMicrocycle,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.lastActionFeedback != null) ...[
                          _FeedbackBanner(
                            message: state.lastActionFeedback!,
                            isError: state.lastActionError,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _PresetAndTemplatesStrip(
                          activePreset: state.activeMicrocycle.preset,
                          savedTemplates: state.savedTemplates,
                          activeId: state.activeMicrocycle.id,
                          onSelectPreset: notifier.loadPreset,
                          onSelectTemplate: notifier.loadSavedTemplate,
                        ),
                        const SizedBox(height: 16),
                        _WeeklyKpiSummaryStrip(
                          microcycle: state.activeMicrocycle,
                          projection: state.projection,
                          isCompact: !isDesktop && !isTablet,
                        ),
                        const SizedBox(height: 16),
                        _WeeklyCalendarSection(
                          microcycle: state.activeMicrocycle,
                          projection: state.projection,
                          selectedDay: state.selectedDay,
                          swapSourceDay: _swapSourceDay,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                          onSelectDay: (day) {
                            if (_swapSourceDay != null && _swapSourceDay != day) {
                              notifier.swapDays(_swapSourceDay!, day);
                              setState(() => _swapSourceDay = null);
                            } else {
                              setState(() => _swapSourceDay = null);
                              notifier.selectDay(day);
                            }
                          },
                          onStartSwap: (day) {
                            setState(() {
                              _swapSourceDay =
                                  _swapSourceDay == day ? null : day;
                            });
                          },
                          onSwapDays: (from, to) {
                            setState(() => _swapSourceDay = null);
                            notifier.swapDays(from, to);
                          },
                        ),
                        const SizedBox(height: 16),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _DaySessionEditorCard(
                                  session: state.selectedSession,
                                  projectionPoint: _projectionForDay(
                                    state.projection,
                                    state.selectedDay,
                                  ),
                                  onSelectWorkoutType: (type) =>
                                      notifier.updateDayWorkoutType(
                                    state.selectedDay,
                                    type,
                                  ),
                                  onChangeDuration: (minutes) =>
                                      notifier.updateDayDuration(
                                    state.selectedDay,
                                    minutes,
                                  ),
                                  onChangeIntensity: (intensity) =>
                                      notifier.updateDayIntensityFactor(
                                    state.selectedDay,
                                    intensity,
                                  ),
                                  onSwapWithDay: (target) => notifier.swapDays(
                                    state.selectedDay,
                                    target,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 6,
                                child: _TsbForecastPanel(
                                  microcycle: state.activeMicrocycle,
                                  projection: state.projection,
                                  validation: state.validation,
                                  selectedDay: state.selectedDay,
                                  onSelectDay: notifier.selectDay,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _DaySessionEditorCard(
                            session: state.selectedSession,
                            projectionPoint: _projectionForDay(
                              state.projection,
                              state.selectedDay,
                            ),
                            onSelectWorkoutType: (type) =>
                                notifier.updateDayWorkoutType(
                              state.selectedDay,
                              type,
                            ),
                            onChangeDuration: (minutes) =>
                                notifier.updateDayDuration(
                              state.selectedDay,
                              minutes,
                            ),
                            onChangeIntensity: (intensity) =>
                                notifier.updateDayIntensityFactor(
                              state.selectedDay,
                              intensity,
                            ),
                            onSwapWithDay: (target) => notifier.swapDays(
                              state.selectedDay,
                              target,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TsbForecastPanel(
                            microcycle: state.activeMicrocycle,
                            projection: state.projection,
                            validation: state.validation,
                            selectedDay: state.selectedDay,
                            onSelectDay: notifier.selectDay,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  MicrocycleDailyProjectionPoint _projectionForDay(
    MicrocyclePhysiologicalProjection projection,
    MicrocycleDayOfWeek day,
  ) {
    return projection.dailyProjections.firstWhere(
      (p) => p.day == day,
      orElse: () => projection.dailyProjections.first,
    );
  }
}

class _PlannerHeaderBar extends StatelessWidget {
  final CustomTrainingMicrocycleState state;
  final bool isCompact;
  final VoidCallback? onBack;
  final VoidCallback onSaveTemplate;
  final VoidCallback onApplyPlan;

  const _PlannerHeaderBar({
    required this.state,
    required this.isCompact,
    required this.onBack,
    required this.onSaveTemplate,
    required this.onApplyPlan,
  });

  @override
  Widget build(BuildContext context) {
    final rider = state.selectedRider;
    final canApply = state.validation.isValid;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null) ...[
                _InteractivePlannerButton(
                  tooltip: 'Wróć',
                  icon: Icons.arrow_back_rounded,
                  label: isCompact ? '' : 'Powrót',
                  isSecondary: true,
                  onPressed: onBack,
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalendarz Mikrocyklu Treningowego',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                        fontSize: isCompact ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${rider.fullName} • ${rider.specialization.displayName} • FTP ${rider.physiology.ftpWatts} W',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _RiderFormPill(rider: rider),
              _InteractivePlannerButton(
                icon: Icons.bookmark_add_outlined,
                label: 'Zapisz szablon',
                isSecondary: true,
                onPressed: onSaveTemplate,
              ),
              _InteractivePlannerButton(
                icon: Icons.check_circle_outline_rounded,
                label: 'Zastosuj plan',
                isSecondary: false,
                onPressed: canApply ? onApplyPlan : null,
                tooltip: canApply
                    ? 'Zastosuj mikrocykl do wybranego kolarza'
                    : 'Popraw błędy walidacji mikrocyklu przed zastosowaniem',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiderFormPill extends StatelessWidget {
  final Rider rider;

  const _RiderFormPill({required this.rider});

  @override
  Widget build(BuildContext context) {
    final ctl = rider.health.chronicTrainingLoad;
    final atl = rider.health.acuteTrainingLoad;
    final tsb = rider.health.trainingStressBalance;
    final tsbColor = tsb >= 5
        ? AppColors.statusSuccess
        : (tsb >= -15 ? AppColors.accentBlue : AppColors.amberWarning);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniStat('CTL', ctl.toStringAsFixed(0), AppColors.accentBlue),
          const SizedBox(width: 10),
          _miniStat('ATL', atl.toStringAsFixed(0), AppColors.powerZone5),
          const SizedBox(width: 10),
          _miniStat(
            'TSB',
            '${tsb >= 0 ? '+' : ''}${tsb.toStringAsFixed(1)}',
            tsbColor,
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackBanner({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final tone = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.verified_rounded,
            size: 18,
            color: tone,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetAndTemplatesStrip extends StatelessWidget {
  final MicrocycleGoalPreset activePreset;
  final List<WeeklyTrainingMicrocycle> savedTemplates;
  final String activeId;
  final ValueChanged<MicrocycleGoalPreset> onSelectPreset;
  final ValueChanged<WeeklyTrainingMicrocycle> onSelectTemplate;

  const _PresetAndTemplatesStrip({
    required this.activePreset,
    required this.savedTemplates,
    required this.activeId,
    required this.onSelectPreset,
    required this.onSelectTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'Szablony Mikrocyklu',
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activePreset.subtitlePl,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final preset in MicrocycleGoalPreset.values) ...[
                  _SelectableFilterChip(
                    label: preset.labelPl,
                    isSelected: activePreset == preset,
                    accentColor: AppColors.goldAccent,
                    onTap: () => onSelectPreset(preset),
                  ),
                  const SizedBox(width: 8),
                ],
                if (savedTemplates.length > 4) ...[
                  Container(
                    width: 1,
                    height: 22,
                    color: const Color(0xFF2A2F3D),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  for (final tpl in savedTemplates.take(3)) ...[
                    _SelectableFilterChip(
                      label: tpl.name,
                      isSelected: tpl.id == activeId,
                      accentColor: AppColors.accentBlue,
                      onTap: () => onSelectTemplate(tpl),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyKpiSummaryStrip extends StatelessWidget {
  final WeeklyTrainingMicrocycle microcycle;
  final MicrocyclePhysiologicalProjection projection;
  final bool isCompact;

  const _WeeklyKpiSummaryStrip({
    required this.microcycle,
    required this.projection,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final tsbDelta = projection.deltaTsb;
    final tsbColor = projection.projectedTsb >= 5
        ? AppColors.statusSuccess
        : (projection.projectedTsb >= -15
            ? AppColors.accentBlue
            : (projection.projectedTsb >= -30
                ? AppColors.amberWarning
                : AppColors.crimsonAlert));

    final items = [
      _KpiCardData(
        label: 'Łączny TSS',
        value: microcycle.totalWeeklyTss.toStringAsFixed(0),
        sub: '${microcycle.hardDaysCount} dni akcentu',
        color: AppColors.goldAccent,
        icon: Icons.bolt_rounded,
      ),
      _KpiCardData(
        label: 'Objętość Tygodnia',
        value: '${microcycle.totalHours.toStringAsFixed(1)} h',
        sub: '${microcycle.totalDurationMinutes} min',
        color: AppColors.accentBlue,
        icon: Icons.schedule_rounded,
      ),
      _KpiCardData(
        label: 'Prognoza TSB (Nd)',
        value:
            '${projection.projectedTsb >= 0 ? '+' : ''}${projection.projectedTsb.toStringAsFixed(1)}',
        sub:
            '${tsbDelta >= 0 ? '+' : ''}${tsbDelta.toStringAsFixed(1)} vs start',
        color: tsbColor,
        icon: Icons.trending_up_rounded,
      ),
      _KpiCardData(
        label: 'Fitness CTL / ATL',
        value:
            '${projection.projectedCtl.toStringAsFixed(0)} / ${projection.projectedAtl.toStringAsFixed(0)}',
        sub:
            'ΔCTL ${projection.deltaCtl >= 0 ? '+' : ''}${projection.deltaCtl.toStringAsFixed(1)}',
        color: AppColors.cyanAccent,
        icon: Icons.show_chart_rounded,
      ),
      _KpiCardData(
        label: 'Polaryzacja i Ryzyko',
        value: '${microcycle.polarizationScore.toStringAsFixed(0)}%',
        sub: projection.riskLevel.labelPl,
        color: projection.riskLevel.statusColor,
        icon: Icons.shield_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 1100 ? 5 : (w >= 680 ? 3 : 2);
        const spacing = 10.0;
        final tileWidth = (w - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2F3D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.icon, size: 15, color: item.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                letterSpacing: -0.2,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.value,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          letterSpacing: -0.4,
                          fontSize: isCompact ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.sub,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          letterSpacing: -0.2,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KpiCardData {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _KpiCardData({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });
}

class _WeeklyCalendarSection extends StatelessWidget {
  final WeeklyTrainingMicrocycle microcycle;
  final MicrocyclePhysiologicalProjection projection;
  final MicrocycleDayOfWeek selectedDay;
  final MicrocycleDayOfWeek? swapSourceDay;
  final bool isDesktop;
  final bool isTablet;
  final ValueChanged<MicrocycleDayOfWeek> onSelectDay;
  final ValueChanged<MicrocycleDayOfWeek> onStartSwap;
  final void Function(MicrocycleDayOfWeek from, MicrocycleDayOfWeek to)
      onSwapDays;

  const _WeeklyCalendarSection({
    required this.microcycle,
    required this.projection,
    required this.selectedDay,
    required this.swapSourceDay,
    required this.isDesktop,
    required this.isTablet,
    required this.onSelectDay,
    required this.onStartSwap,
    required this.onSwapDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_week_rounded,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Interaktywny Kalendarz Tygodniowy (Pon – Nd)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (swapSourceDay != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentBlue.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    'Wybierz dzień docelowy do zamiany z ${swapSourceDay!.shortLabelPl}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBlue,
                    ),
                  ),
                )
              else
                const Text(
                  'Przeciągnij dzień lub kliknij, aby edytować',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final columns = isDesktop ? 7 : (isTablet ? 4 : 1);
              const spacing = 10.0;
              final cardWidth =
                  columns == 1 ? w : (w - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final session in microcycle.sessions)
                    SizedBox(
                      width: cardWidth,
                      child: _CalendarDayTile(
                        session: session,
                        point: projection.dailyProjections.firstWhere(
                          (p) => p.day == session.day,
                          orElse: () => projection.dailyProjections.first,
                        ),
                        isSelected: session.day == selectedDay,
                        isSwapSource: session.day == swapSourceDay,
                        isCompactList: columns == 1,
                        onTap: () => onSelectDay(session.day),
                        onSwapTap: () => onStartSwap(session.day),
                        onDropFrom: (fromDay) => onSwapDays(fromDay, session.day),
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
}

class _CalendarDayTile extends StatefulWidget {
  final MicrocycleDaySession session;
  final MicrocycleDailyProjectionPoint point;
  final bool isSelected;
  final bool isSwapSource;
  final bool isCompactList;
  final VoidCallback onTap;
  final VoidCallback onSwapTap;
  final ValueChanged<MicrocycleDayOfWeek> onDropFrom;

  const _CalendarDayTile({
    required this.session,
    required this.point,
    required this.isSelected,
    required this.isSwapSource,
    required this.isCompactList,
    required this.onTap,
    required this.onSwapTap,
    required this.onDropFrom,
  });

  @override
  State<_CalendarDayTile> createState() => _CalendarDayTileState();
}

class _CalendarDayTileState extends State<_CalendarDayTile> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final zoneColor =
        AppColors.getPowerZoneColor(widget.session.primaryPowerZone);
    final tss = widget.session.estimatedTss;
    final tsb = widget.point.tsb;
    final tsbColor = tsb >= 5
        ? AppColors.statusSuccess
        : (tsb >= -15
            ? AppColors.accentBlue
            : (tsb >= -30 ? AppColors.amberWarning : AppColors.crimsonAlert));

    return DragTarget<MicrocycleDayOfWeek>(
      onWillAcceptWithDetails: (details) => details.data != widget.session.day,
      onAcceptWithDetails: (details) => widget.onDropFrom(details.data),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        final borderColor = isDropTarget
            ? AppColors.cyanAccent
            : widget.isSwapSource
                ? AppColors.accentBlue
                : widget.isSelected
                    ? AppColors.goldAccent
                    : (_isFocused
                        ? AppColors.accentBlue
                        : (_isHovered
                            ? AppColors.goldAccent.withValues(alpha: 0.55)
                            : const Color(0xFF2A2F3D)));

        final bgColor = widget.isSelected
            ? AppColors.surfaceLight
            : (_isHovered
                ? AppColors.surfaceLight.withValues(alpha: 0.65)
                : AppColors.background.withValues(alpha: 0.6));

        final card = FocusableActionDetector(
          onShowHoverHighlight: (v) => setState(() => _isHovered = v),
          onShowFocusHighlight: (v) => setState(() => _isFocused = v),
          mouseCursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _isPressed ? 0.985 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected || isDropTarget ? 1.5 : 1.0,
                  ),
                ),
                child: widget.isCompactList
                    ? _buildCompactRow(zoneColor, tss, tsb, tsbColor)
                    : _buildVerticalColumn(zoneColor, tss, tsb, tsbColor),
              ),
            ),
          ),
        );

        return LongPressDraggable<MicrocycleDayOfWeek>(
          data: widget.session.day,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 170,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.goldAccent, width: 1.5),
              ),
              child: Text(
                '${widget.session.day.labelPl}: ${widget.session.workoutType.shortCode}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          child: card,
        );
      },
    );
  }

  Widget _buildVerticalColumn(
    Color zoneColor,
    double tss,
    double tsb,
    Color tsbColor,
  ) {
    final tssBarFraction = (tss / 240.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.session.day.shortLabelPl.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: 0.4,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.isSelected
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ZoneBadge(
                  zone: widget.session.primaryPowerZone,
                  color: zoneColor,
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: widget.onSwapTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      size: 14,
                      color: widget.isSwapSource
                          ? AppColors.accentBlue
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.session.workoutType.shortCode,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.session.workoutType == TrainingWorkoutType.restDay
              ? 'Regeneracja'
              : '${widget.session.durationMinutes} min • IF ${widget.session.intensityFactor.toStringAsFixed(2)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            fontSize: 11,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: tssBarFraction,
            minHeight: 5,
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(zoneColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${tss.toStringAsFixed(0)} TSS',
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: zoneColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'TSB ${tsb >= 0 ? '+' : ''}${tsb.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tsbColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactRow(
    Color zoneColor,
    double tss,
    double tsb,
    Color tsbColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            widget.session.day.shortLabelPl.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
          ),
        ),
        _ZoneBadge(zone: widget.session.primaryPowerZone, color: zoneColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.session.workoutType.labelPl,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                widget.session.workoutType == TrainingWorkoutType.restDay
                    ? 'Dzień odpoczynku'
                    : '${widget.session.durationMinutes} min • IF ${widget.session.intensityFactor.toStringAsFixed(2)}',
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${tss.toStringAsFixed(0)} TSS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: zoneColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'TSB ${tsb >= 0 ? '+' : ''}${tsb.toStringAsFixed(1)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tsbColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: widget.onSwapTap,
          tooltip: 'Zamień dzień',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            Icons.swap_horiz_rounded,
            size: 18,
            color: widget.isSwapSource
                ? AppColors.accentBlue
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ZoneBadge extends StatelessWidget {
  final int zone;
  final Color color;

  const _ZoneBadge({required this.zone, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        'Z$zone',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _DaySessionEditorCard extends StatelessWidget {
  final MicrocycleDaySession session;
  final MicrocycleDailyProjectionPoint projectionPoint;
  final ValueChanged<TrainingWorkoutType> onSelectWorkoutType;
  final ValueChanged<int> onChangeDuration;
  final ValueChanged<double> onChangeIntensity;
  final ValueChanged<MicrocycleDayOfWeek> onSwapWithDay;

  const _DaySessionEditorCard({
    required this.session,
    required this.projectionPoint,
    required this.onSelectWorkoutType,
    required this.onChangeDuration,
    required this.onChangeIntensity,
    required this.onSwapWithDay,
  });

  @override
  Widget build(BuildContext context) {
    final isRest = session.workoutType == TrainingWorkoutType.restDay;
    final zoneColor = AppColors.getPowerZoneColor(session.primaryPowerZone);
    final hours = session.durationMinutes / 60.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ZoneBadge(zone: session.primaryPowerZone, color: zoneColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${session.day.labelPl} — Konfigurator Jednostki',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              DropdownButton<MicrocycleDayOfWeek>(
                value: null,
                hint: const Text(
                  'Zamień z...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.accentBlue,
                  ),
                ),
                dropdownColor: AppColors.surfaceLight,
                underline: const SizedBox.shrink(),
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: AppColors.accentBlue,
                ),
                items: [
                  for (final d in MicrocycleDayOfWeek.values)
                    if (d != session.day)
                      DropdownMenuItem(
                        value: d,
                        child: Text(
                          d.labelPl,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                ],
                onChanged: (target) {
                  if (target != null) onSwapWithDay(target);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rodzaj Treningu',
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in TrainingWorkoutType.values)
                _SelectableFilterChip(
                  label: '${type.shortCode} • ${type.labelPl}',
                  isSelected: session.workoutType == type,
                  accentColor:
                      AppColors.getPowerZoneColor(type.primaryPowerZone),
                  onTap: () => onSelectWorkoutType(type),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Czas trwania: ${isRest ? '0' : session.durationMinutes} min',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isRest
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _InteractivePlannerButton(
                icon: Icons.remove_rounded,
                label: '15m',
                isSecondary: true,
                onPressed: isRest || session.durationMinutes <= 15
                    ? null
                    : () => onChangeDuration(session.durationMinutes - 15),
              ),
              const SizedBox(width: 6),
              _InteractivePlannerButton(
                icon: Icons.add_rounded,
                label: '15m',
                isSecondary: true,
                onPressed: isRest || session.durationMinutes >= 420
                    ? null
                    : () => onChangeDuration(session.durationMinutes + 15),
              ),
            ],
          ),
          Slider(
            value: isRest
                ? 15.0
                : session.durationMinutes.toDouble().clamp(15.0, 420.0),
            min: 15,
            max: 420,
            divisions: 81,
            activeColor: zoneColor,
            inactiveColor: AppColors.surfaceLight,
            onChanged: isRest ? null : (v) => onChangeDuration(v.round()),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Współczynnik Intensywności (IF): ${isRest ? '0.00' : session.intensityFactor.toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isRest
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(session.intensityFactor * 100).toStringAsFixed(0)}% FTP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: zoneColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Slider(
            value: isRest
                ? 0.45
                : session.intensityFactor.clamp(0.45, 1.25),
            min: 0.45,
            max: 1.25,
            divisions: 80,
            activeColor: zoneColor,
            inactiveColor: AppColors.surfaceLight,
            onChanged: isRest ? null : onChangeIntensity,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
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
                        'Kalkulator TSS dnia',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${session.estimatedTss.toStringAsFixed(1)} TSS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: zoneColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isRest
                      ? 'Dzień regeneracyjny: TSS = 0.0 (maksymalna odbudowa TSB).'
                      : 'Wzór: ${hours.toStringAsFixed(2)}h × ${session.intensityFactor.toStringAsFixed(2)}² × 100'
                          '${session.behindMotorPacer ? ' × 1.06 (Motor-Pacer)' : ''}'
                          ' → TSB po dniu: ${projectionPoint.tsb >= 0 ? '+' : ''}${projectionPoint.tsb.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Struktura: ${session.intervalStructure}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TsbForecastPanel extends StatelessWidget {
  final WeeklyTrainingMicrocycle microcycle;
  final MicrocyclePhysiologicalProjection projection;
  final MicrocycleValidationReport validation;
  final MicrocycleDayOfWeek selectedDay;
  final ValueChanged<MicrocycleDayOfWeek> onSelectDay;

  const _TsbForecastPanel({
    required this.microcycle,
    required this.projection,
    required this.validation,
    required this.selectedDay,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 18,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Prognoza TSB, CTL & ATL (Model Banistera)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: projection.riskLevel.statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        projection.riskLevel.statusColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Synergia ${projection.synergyScore}/100',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: projection.riskLevel.statusColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendItem(label: 'TSS (słupki)', color: AppColors.powerZone3),
              _LegendItem(label: 'CTL Fitness', color: AppColors.accentBlue),
              _LegendItem(label: 'ATL Zmęczenie', color: AppColors.powerZone5),
              _LegendItem(label: 'TSB Świeżość', color: AppColors.goldAccent),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: WeeklyTsbForecastChartPainter(
                points: projection.dailyProjections,
                selectedDay: selectedDay,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AdaptationBadge(
                label: 'ΔFTP',
                value:
                    '+${projection.projectedFtpDeltaWatts.toStringAsFixed(1)} W',
                color: AppColors.statusSuccess,
              ),
              _AdaptationBadge(
                label: 'ΔVO2max',
                value: '+${projection.projectedVo2maxDelta.toStringAsFixed(2)}',
                color: AppColors.cyanAccent,
              ),
              _AdaptationBadge(
                label: 'Δ5m Moc',
                value:
                    '+${projection.projected5mWattsDelta.toStringAsFixed(1)} W',
                color: AppColors.powerZone5,
              ),
              _AdaptationBadge(
                label: 'ΔSprint',
                value:
                    '+${projection.projectedSprintWattsDelta.toStringAsFixed(1)} W',
                color: AppColors.powerZone7,
              ),
            ],
          ),
          if (validation.errors.isNotEmpty ||
              validation.warnings.isNotEmpty ||
              projection.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final err in validation.errors)
              _WarningRow(text: err, isError: true),
            for (final warn in [...validation.warnings, ...projection.warnings])
              _WarningRow(text: warn, isError: false),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AdaptationBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AdaptationBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              fontSize: 12,
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

class _WarningRow extends StatelessWidget {
  final String text;
  final bool isError;

  const _WarningRow({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final tone = isError ? AppColors.crimsonAlert : AppColors.amberWarning;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_rounded : Icons.warning_amber_rounded,
            size: 15,
            color: tone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _SelectableFilterChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_SelectableFilterChip> createState() => _SelectableFilterChipState();
}

class _SelectableFilterChipState extends State<_SelectableFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected
        ? widget.accentColor
        : (_focused
            ? AppColors.accentBlue
            : (_hovered
                ? widget.accentColor.withValues(alpha: 0.6)
                : const Color(0xFF2A2F3D)));

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.18)
                : (_hovered
                    ? AppColors.surfaceLight
                    : AppColors.background.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              fontSize: 12,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
              color: widget.isSelected
                  ? widget.accentColor
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractivePlannerButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSecondary;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _InteractivePlannerButton({
    required this.icon,
    required this.label,
    required this.isSecondary,
    required this.onPressed,
    this.tooltip,
  });

  @override
  State<_InteractivePlannerButton> createState() =>
      _InteractivePlannerButtonState();
}

class _InteractivePlannerButtonState extends State<_InteractivePlannerButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final baseBg = widget.isSecondary
        ? AppColors.surfaceLight
        : AppColors.primaryAccent;
    final bg = disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_hovered ? baseBg.withValues(alpha: 0.88) : baseBg);
    final borderColor = disabled
        ? const Color(0xFF2A2F3D)
        : (_focused
            ? AppColors.goldAccent
            : (widget.isSecondary
                ? const Color(0xFF2E3440)
                : AppColors.goldAccent.withValues(alpha: 0.45)));

    final button = FocusableActionDetector(
      enabled: !disabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed && !disabled ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.label.isEmpty ? 10 : 13,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: disabled
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                ),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Wykres prognozy 7-dniowego obciążenia (TSS) oraz krzywych CTL, ATL i TSB.
class WeeklyTsbForecastChartPainter extends CustomPainter {
  final List<MicrocycleDailyProjectionPoint> points;
  final MicrocycleDayOfWeek selectedDay;

  const WeeklyTsbForecastChartPainter({
    required this.points,
    required this.selectedDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const leftPad = 36.0;
    const rightPad = 14.0;
    const topPad = 14.0;
    const bottomPad = 28.0;

    final chartWidth = math.max(10.0, size.width - leftPad - rightPad);
    final chartHeight = math.max(10.0, size.height - topPad - bottomPad);

    final minTsb = points.map((p) => p.tsb).reduce(math.min);
    final maxTsb = points.map((p) => p.tsb).reduce(math.max);
    final maxLoad = points
        .map((p) => math.max(p.ctl, p.atl))
        .reduce(math.max)
        .clamp(60.0, 250.0);

    final yMin = math.min(-35.0, minTsb - 5.0);
    final yMax = math.max(maxLoad + 15.0, maxTsb + 10.0);
    final yRange = math.max(1.0, yMax - yMin);

    double yForValue(double v) =>
        topPad + chartHeight - ((v - yMin) / yRange) * chartHeight;

    // Optimal race readiness band (+5 .. +20 TSB)
    final bandTop = yForValue(20.0);
    final bandBottom = yForValue(5.0);
    final bandPaint = Paint()
      ..color = AppColors.statusSuccess.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(leftPad, bandTop, leftPad + chartWidth, bandBottom),
      bandPaint,
    );

    // Zero line
    final zeroY = yForValue(0.0);
    final gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(leftPad, zeroY),
      Offset(leftPad + chartWidth, zeroY),
      gridPaint,
    );

    // Y axis labels
    _drawLabel(canvas, '0', Offset(6, zeroY - 6), AppColors.textSecondary);
    _drawLabel(
      canvas,
      yMax.toStringAsFixed(0),
      const Offset(6, topPad - 4),
      AppColors.textSecondary,
    );
    _drawLabel(
      canvas,
      yMin.toStringAsFixed(0),
      Offset(6, topPad + chartHeight - 10),
      AppColors.textSecondary,
    );

    final stepX = chartWidth / points.length;
    final barWidth = math.min(26.0, stepX * 0.42);
    final maxTss = points.map((p) => p.dailyTss).reduce(math.max).clamp(100.0, 350.0);

    final ctlPath = Path();
    final atlPath = Path();
    final tsbPath = Path();

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = leftPad + stepX * i + stepX / 2;

      if (p.day == selectedDay) {
        final highlightPaint = Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.08);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              leftPad + stepX * i + 2,
              topPad,
              stepX - 4,
              chartHeight,
            ),
            const Radius.circular(8),
          ),
          highlightPaint,
        );
      }

      // Daily TSS bar scaled into bottom 45% of chart
      final barHeight = (p.dailyTss / maxTss) * (chartHeight * 0.45);
      final barRect = Rect.fromLTWH(
        cx - barWidth / 2,
        topPad + chartHeight - barHeight,
        barWidth,
        barHeight,
      );
      final zoneColor = AppColors.getPowerZoneColor(p.primaryPowerZone);
      canvas.drawRRect(
        RRect.fromRectAndRadius(barRect, const Radius.circular(4)),
        Paint()..color = zoneColor.withValues(alpha: 0.45),
      );

      final ctlOffset = Offset(cx, yForValue(p.ctl));
      final atlOffset = Offset(cx, yForValue(p.atl));
      final tsbOffset = Offset(cx, yForValue(p.tsb));

      if (i == 0) {
        ctlPath.moveTo(ctlOffset.dx, ctlOffset.dy);
        atlPath.moveTo(atlOffset.dx, atlOffset.dy);
        tsbPath.moveTo(tsbOffset.dx, tsbOffset.dy);
      } else {
        ctlPath.lineTo(ctlOffset.dx, ctlOffset.dy);
        atlPath.lineTo(atlOffset.dx, atlOffset.dy);
        tsbPath.lineTo(tsbOffset.dx, tsbOffset.dy);
      }

      _drawLabel(
        canvas,
        p.day.shortLabelPl,
        Offset(cx - 10, topPad + chartHeight + 8),
        p.day == selectedDay ? AppColors.goldAccent : AppColors.textSecondary,
      );
    }

    _strokeLine(canvas, ctlPath, AppColors.accentBlue, 2.2);
    _strokeLine(canvas, atlPath, AppColors.powerZone5, 2.2);
    _strokeLine(canvas, tsbPath, AppColors.goldAccent, 2.6);

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final cx = leftPad + stepX * i + stepX / 2;
      final tsbY = yForValue(p.tsb);
      canvas.drawCircle(
        Offset(cx, tsbY),
        p.day == selectedDay ? 5.0 : 3.5,
        Paint()..color = AppColors.goldAccent,
      );
    }
  }

  void _strokeLine(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant WeeklyTsbForecastChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedDay != selectedDay;
  }
}
