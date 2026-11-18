import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/career/ai_director_sportif_tactical_styles_engine.dart';

/// Zakładka aktywna w karcie wywiadu taktycznego o planie rywali.
enum RivalScoutingReportTab {
  threats('Zagrożenia', Icons.radar_rounded),
  pelotonIntel('Rozkład Peletonu', Icons.groups_rounded),
  counterPlan('Kontrtaktyka', Icons.shield_rounded);

  final String label;
  final IconData icon;
  const RivalScoutingReportTab(this.label, this.icon);
}

/// Filtr listy planów taktycznych rywali na podstawie przewidywanego manewru.
enum RivalScoutingThreatFilter {
  all('Wszystkie'),
  breakaway('Ucieczka'),
  chase('Pościg'),
  echelon('Wachlarze');

  final String label;
  const RivalScoutingThreatFilter(this.label);
}

/// Zbiorczy pakiet danych wejściowych dla karty wywiadu taktycznego przed etapem.
class RivalTeamScoutingReportData {
  final StageTacticalContextInput stageContext;
  final PelotonTacticalMatchupReport report;
  final double scoutConfidencePercent;
  final DateTime? generatedAt;

  const RivalTeamScoutingReportData({
    required this.stageContext,
    required this.report,
    this.scoutConfidencePercent = 88.0,
    this.generatedAt,
  });

  /// Buduje raport wywiadowczy bezpośrednio z kontekstu etapu i silnika stylów DS.
  factory RivalTeamScoutingReportData.fromStageContext({
    required StageTacticalContextInput stageContext,
    String playerTeamId = 'team_player',
    double scoutConfidencePercent = 88.0,
    Map<String, DirectorSportifTacticalProfile> customOverrides = const {},
  }) {
    final report = AiDirectorSportifTacticalStylesEngine.buildPelotonMatchupReport(
      playerTeamId: playerTeamId,
      context: stageContext,
      customOverrides: customOverrides,
    );
    return RivalTeamScoutingReportData(
      stageContext: stageContext,
      report: report,
      scoutConfidencePercent: scoutConfidencePercent.clamp(0.0, 100.0),
    );
  }
}

/// Karta wywiadu taktycznego o planie rywali na odprawie przed etapem.
///
/// Prezentuje prognozowane plany taktyczne drużyn AI (`DsStageTacticalPlan`),
/// prawdopodobieństwa ucieczki/pościgu/wachlarzy, przewidywane kilometry ataku,
/// rozkład archetypów peletonu oraz rekomendowane kontrtaktyki.
class RivalTeamTacticalScoutingReportCard extends StatefulWidget {
  final StageTacticalContextInput stageContext;
  final PelotonTacticalMatchupReport? report;
  final String playerTeamId;
  final double scoutConfidencePercent;
  final bool isDisabled;
  final ValueChanged<DsStageTacticalPlan>? onSelectRivalPlan;
  final ValueChanged<String>? onApplyCounterStrategy;

  const RivalTeamTacticalScoutingReportCard({
    super.key,
    required this.stageContext,
    this.report,
    this.playerTeamId = 'team_player',
    this.scoutConfidencePercent = 88.0,
    this.isDisabled = false,
    this.onSelectRivalPlan,
    this.onApplyCounterStrategy,
  });

  @override
  State<RivalTeamTacticalScoutingReportCard> createState() =>
      _RivalTeamTacticalScoutingReportCardState();
}

class _RivalTeamTacticalScoutingReportCardState
    extends State<RivalTeamTacticalScoutingReportCard> {
  static const TextStyle _baseInter = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  late PelotonTacticalMatchupReport _report;
  RivalScoutingReportTab _activeTab = RivalScoutingReportTab.threats;
  RivalScoutingThreatFilter _activeFilter = RivalScoutingThreatFilter.all;
  int _selectedPlanIndex = 0;
  String? _appliedCounterTeamId;

  @override
  void initState() {
    super.initState();
    _syncReport();
  }

  @override
  void didUpdateWidget(covariant RivalTeamTacticalScoutingReportCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report != widget.report ||
        oldWidget.stageContext != widget.stageContext ||
        oldWidget.playerTeamId != widget.playerTeamId) {
      _syncReport();
    }
  }

  void _syncReport() {
    _report = widget.report ??
        AiDirectorSportifTacticalStylesEngine.buildPelotonMatchupReport(
          playerTeamId: widget.playerTeamId,
          context: widget.stageContext,
        );
    _selectedPlanIndex = 0;
  }

  List<DsStageTacticalPlan> get _filteredPlans {
    final plans = _report.topThreatPlans;
    switch (_activeFilter) {
      case RivalScoutingThreatFilter.all:
        return plans;
      case RivalScoutingThreatFilter.breakaway:
        return plans.where((p) => p.sendBreakawayProbability >= 0.55).toList();
      case RivalScoutingThreatFilter.chase:
        return plans.where((p) => p.chaseBreakawayProbability >= 0.55).toList();
      case RivalScoutingThreatFilter.echelon:
        return plans.where((p) => p.echelonAmbushProbability >= 0.45).toList();
    }
  }

  DsStageTacticalPlan? get _selectedPlan {
    final plans = _filteredPlans;
    if (plans.isEmpty) return null;
    final safeIndex = _selectedPlanIndex.clamp(0, plans.length - 1);
    return plans[safeIndex];
  }

  Color _threatColor(double score) {
    if (score >= 0.72) return AppColors.crimsonAlert;
    if (score >= 0.52) return AppColors.amberWarning;
    return AppColors.accentBlue;
  }

  String _threatBadgeLabel(double score) {
    if (score >= 0.72) return 'WYSOKIE ZAGROŻENIE';
    if (score >= 0.52) return 'UMIARKOWANE';
    return 'KONTROLOWANE';
  }

  @override
  Widget build(BuildContext context) {
    final clampedConfidence = widget.scoutConfidencePercent.clamp(0.0, 100.0);

    return Opacity(
      opacity: widget.isDisabled ? 0.52 : 1.0,
      child: AbsorbPointer(
        absorbing: widget.isDisabled,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final isWide = constraints.maxWidth >= 960;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isCompact, clampedConfidence),
                  const SizedBox(height: 12),
                  _buildStageContextStrip(isCompact),
                  const SizedBox(height: 14),
                  _buildTabBar(isCompact),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: _buildActiveTabBody(isCompact, isWide),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact, double confidence) {
    final titleGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: const Icon(
            Icons.troubleshoot_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WYWIAD TAKTYCZNY RYWALI',
                style: _baseInter.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: isCompact ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Odprawa przedetapowa • Analiza ${_report.rivalTeamCount} ekip AI',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final confidencePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: confidence >= 75
              ? AppColors.statusSuccess.withValues(alpha: 0.45)
              : AppColors.amberWarning.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 14,
            color: confidence >= 75
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
          ),
          const SizedBox(width: 6),
          Text(
            'Pewność wywiadu: ${confidence.toStringAsFixed(0)}%',
            style: _baseInter.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleGroup,
          const SizedBox(height: 10),
          confidencePill,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleGroup),
        const SizedBox(width: 12),
        confidencePill,
      ],
    );
  }

  Widget _buildStageContextStrip(bool isCompact) {
    final ctx = widget.stageContext;
    final items = <Widget>[
      _ContextMetricChip(
        icon: Icons.flag_rounded,
        label: ctx.stageName,
        accent: AppColors.goldAccent,
      ),
      _ContextMetricChip(
        icon: Icons.route_rounded,
        label: '${ctx.distanceKm.toStringAsFixed(0)} km',
        accent: AppColors.accentBlue,
      ),
      _ContextMetricChip(
        icon: Icons.landscape_rounded,
        label: '+${ctx.elevationGainM} m',
        accent: AppColors.statusSuccess,
      ),
      _ContextMetricChip(
        icon: Icons.air_rounded,
        label: 'Wiatr ${ctx.crosswindKmh.toStringAsFixed(0)} km/h',
        accent: ctx.crosswindKmh >= 22
            ? AppColors.amberWarning
            : AppColors.textSecondary,
      ),
    ];

    if (ctx.hasCobbleSectors) {
      items.add(
        const _ContextMetricChip(
          icon: Icons.grid_on_rounded,
          label: 'Sektory Bruku',
          accent: AppColors.primaryAccent,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Wrap(
        spacing: isCompact ? 8 : 12,
        runSpacing: 8,
        children: items,
      ),
    );
  }

  Widget _buildTabBar(bool isCompact) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RivalScoutingReportTab.values.map((tab) {
        final isSelected = _activeTab == tab;
        return _ScoutingInteractivePill(
          label: tab.label,
          icon: tab.icon,
          selected: isSelected,
          disabled: widget.isDisabled,
          accentColor: AppColors.goldAccent,
          compact: isCompact,
          onTap: () {
            setState(() {
              _activeTab = tab;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildActiveTabBody(bool isCompact, bool isWide) {
    switch (_activeTab) {
      case RivalScoutingReportTab.threats:
        return KeyedSubtree(
          key: const ValueKey('tab_threats'),
          child: _buildThreatsTab(isCompact, isWide),
        );
      case RivalScoutingReportTab.pelotonIntel:
        return KeyedSubtree(
          key: const ValueKey('tab_peloton'),
          child: _buildPelotonIntelTab(isCompact, isWide),
        );
      case RivalScoutingReportTab.counterPlan:
        return KeyedSubtree(
          key: const ValueKey('tab_counter'),
          child: _buildCounterPlanTab(isCompact),
        );
    }
  }

  Widget _buildThreatsTab(bool isCompact, bool isWide) {
    final plans = _filteredPlans;
    final selected = _selectedPlan;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RivalScoutingThreatFilter.values.map((filter) {
            return _ScoutingInteractivePill(
              label: filter.label,
              selected: _activeFilter == filter,
              disabled: widget.isDisabled,
              accentColor: AppColors.accentBlue,
              compact: true,
              onTap: () {
                setState(() {
                  _activeFilter = filter;
                  _selectedPlanIndex = 0;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (plans.isEmpty)
          _buildEmptyState(
            'Brak ekip spełniających kryterium "${_activeFilter.label}".',
          )
        else if (isWide && selected != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildRivalPlansList(plans, isCompact),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: _buildSelectedPlanDossier(selected, isCompact),
              ),
            ],
          )
        else ...[
          _buildRivalPlansList(plans, isCompact),
          if (selected != null) ...[
            const SizedBox(height: 12),
            _buildSelectedPlanDossier(selected, isCompact),
          ],
        ],
      ],
    );
  }

  Widget _buildRivalPlansList(
    List<DsStageTacticalPlan> plans,
    bool isCompact,
  ) {
    final visiblePlans = plans.take(6).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visiblePlans.length, (index) {
        final plan = visiblePlans[index];
        final isSelected = index == _selectedPlanIndex.clamp(0, plans.length - 1);
        final threat = plan.threatScore;
        final threatColor = _threatColor(threat);

        return Padding(
          padding: EdgeInsets.only(bottom: index == visiblePlans.length - 1 ? 0 : 8),
          child: _RivalPlanTile(
            plan: plan,
            rank: index + 1,
            isSelected: isSelected,
            isDisabled: widget.isDisabled,
            threatColor: threatColor,
            isCompact: isCompact,
            onTap: () {
              setState(() {
                _selectedPlanIndex = index;
              });
              widget.onSelectRivalPlan?.call(plan);
            },
          ),
        );
      }),
    );
  }

  Widget _buildSelectedPlanDossier(DsStageTacticalPlan plan, bool isCompact) {
    final threatColor = _threatColor(plan.threatScore);
    final isApplied = _appliedCounterTeamId == plan.teamId;

    final threatBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: threatColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: threatColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Text(
        _threatBadgeLabel(plan.threatScore),
        style: _baseInter.copyWith(
          color: threatColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );

    final dossierHeaderInfo = Row(
      children: [
        Icon(
          plan.archetype.icon,
          color: plan.archetype.accentColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                plan.teamName,
                style: _baseInter.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'DS: ${plan.directorName} • ${plan.styleCodename}',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: plan.archetype.accentColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            dossierHeaderInfo,
            const SizedBox(height: 8),
            threatBadge,
          ] else
            Row(
              children: [
                Expanded(child: dossierHeaderInfo),
                const SizedBox(width: 8),
                threatBadge,
              ],
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PRZEWIDYWANY PLAN NA ETAP',
                  style: _baseInter.copyWith(
                    color: AppColors.goldAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.primaryObjectiveLabel,
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.tacticalAlertSummary,
                  style: _baseInter.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TelemetryStatBox(
                label: 'Tempo Pociągu',
                value: '${plan.recommendedTempoPctFtp.toStringAsFixed(0)}% FTP',
                accent: AppColors.cyanAccent,
              ),
              _TelemetryStatBox(
                label: 'Okno Ataku',
                value: '${plan.plannedAttackKmToGo.toStringAsFixed(1)} km',
                accent: AppColors.crimsonAlert,
              ),
              _TelemetryStatBox(
                label: 'Pomocnicy',
                value: '${plan.domestiquesCommittedToPace} kol.',
                accent: AppColors.accentBlue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProbabilityMeterBar(
            label: 'Wysłanie ucieczki',
            probability: plan.sendBreakawayProbability,
            color: AppColors.statusSuccess,
          ),
          const SizedBox(height: 8),
          _ProbabilityMeterBar(
            label: 'Praca w pościgu',
            probability: plan.chaseBreakawayProbability,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 8),
          _ProbabilityMeterBar(
            label: 'Zasadzka na wietrze (Wachlarz)',
            probability: plan.echelonAmbushProbability,
            color: AppColors.amberWarning,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.statusSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.statusSuccess.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ZALECANA KONTRTAKTYKA',
                  style: _baseInter.copyWith(
                    color: AppColors.statusSuccess,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.counterStrategyTip,
                  style: _baseInter.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ScoutingPrimaryButton(
            label: isApplied
                ? 'Kontrtaktyka aktywna w odprawie'
                : 'Zastosuj kontrtaktykę przeciw ${plan.teamName}',
            icon: isApplied ? Icons.check_circle_rounded : Icons.shield_rounded,
            isApplied: isApplied,
            isDisabled: widget.isDisabled,
            isCompact: isCompact,
            onPressed: () {
              setState(() {
                _appliedCounterTeamId = plan.teamId;
              });
              widget.onApplyCounterStrategy?.call(plan.counterStrategyTip);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPelotonIntelTab(bool isCompact, bool isWide) {
    final breakawayTeams = _report.expectedBreakawayTeams;
    final chaseTeams = _report.expectedChaseTeams;
    final echelonTeams = _report.expectedEchelonInstigators;
    final distributionEntries = _report.archetypeDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final teamGroups = <Widget>[
      _IntelTeamGroupBox(
        title: 'Ucieczka Dnia (${breakawayTeams.length})',
        subtitle: 'Ekipy planujące atak w pierwszych 25 km',
        teams: breakawayTeams,
        accent: AppColors.statusSuccess,
        icon: Icons.directions_bike_rounded,
      ),
      _IntelTeamGroupBox(
        title: 'Kontrola Pościgu (${chaseTeams.length})',
        subtitle: 'Ekipy gotowe dyktować tempo na czele peletonu',
        teams: chaseTeams,
        accent: AppColors.accentBlue,
        icon: Icons.speed_rounded,
      ),
      _IntelTeamGroupBox(
        title: 'Inicjatorzy Wachlarzy (${echelonTeams.length})',
        subtitle: 'Zagrożenie atakiem na otwartym wietrze bocznym',
        teams: echelonTeams,
        accent: AppColors.amberWarning,
        icon: Icons.air_rounded,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: teamGroups[0]),
              const SizedBox(width: 10),
              Expanded(child: teamGroups[1]),
              const SizedBox(width: 10),
              Expanded(child: teamGroups[2]),
            ],
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              teamGroups[0],
              const SizedBox(height: 10),
              teamGroups[1],
              const SizedBox(height: 10),
              teamGroups[2],
            ],
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROZKŁAD ARCHETYPÓW TAKTYCZNYCH W PELETONIE',
                style: _baseInter.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              if (distributionEntries.isEmpty)
                _buildEmptyState('Brak danych o archetypach peletonu.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: distributionEntries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: entry.key.accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: entry.key.accentColor.withValues(alpha: 0.45),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.key.icon,
                            size: 14,
                            color: entry.key.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key.shortLabel}: ${entry.value}',
                            style: _baseInter.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounterPlanTab(bool isCompact) {
    final topPlans = _report.topThreatPlans.take(3).toList();
    if (topPlans.isEmpty) {
      return _buildEmptyState('Brak zidentyfikowanych zagrożeń na tym etapie.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < topPlans.length; i++) ...[
          _CounterPlanItemCard(
            plan: topPlans[i],
            isApplied: _appliedCounterTeamId == topPlans[i].teamId,
            isDisabled: widget.isDisabled,
            isCompact: isCompact,
            onApply: () {
              setState(() {
                _appliedCounterTeamId = topPlans[i].teamId;
              });
              widget.onApplyCounterStrategy?.call(topPlans[i].counterStrategyTip);
            },
          ),
          if (i < topPlans.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: _baseInter.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _ContextMetricChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoutingInteractivePill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final Color accentColor;
  final bool compact;
  final VoidCallback onTap;

  const _ScoutingInteractivePill({
    required this.label,
    this.icon,
    required this.selected,
    required this.disabled,
    required this.accentColor,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_ScoutingInteractivePill> createState() =>
      _ScoutingInteractivePillState();
}

class _ScoutingInteractivePillState extends State<_ScoutingInteractivePill> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? widget.accentColor.withValues(alpha: 0.2)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? widget.accentColor
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !widget.disabled,
      mouseCursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.disabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.selected
                      ? widget.accentColor
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
                    letterSpacing: -0.2,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
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

class _RivalPlanTile extends StatefulWidget {
  final DsStageTacticalPlan plan;
  final int rank;
  final bool isSelected;
  final bool isDisabled;
  final Color threatColor;
  final bool isCompact;
  final VoidCallback onTap;

  const _RivalPlanTile({
    required this.plan,
    required this.rank,
    required this.isSelected,
    required this.isDisabled,
    required this.threatColor,
    required this.isCompact,
    required this.onTap,
  });

  @override
  State<_RivalPlanTile> createState() => _RivalPlanTileState();
}

class _RivalPlanTileState extends State<_RivalPlanTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? widget.plan.archetype.accentColor.withValues(alpha: 0.14)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? widget.plan.archetype.accentColor
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.45)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.isDisabled) widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused || widget.isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.threatColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.rank}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.threatColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.plan.teamName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.plan.archetype.shortLabel} • ${widget.plan.primaryObjectiveLabel}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(widget.plan.threatScore * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: widget.threatColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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

class _TelemetryStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryStatBox({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityMeterBar extends StatelessWidget {
  final String label;
  final double probability;
  final Color color;

  const _ProbabilityMeterBar({
    required this.label,
    required this.probability,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = probability.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(clamped * 100).round()}%',
              style: TextStyle(
                fontFamily: 'Inter',
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _IntelTeamGroupBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> teams;
  final Color accent;
  final IconData icon;

  const _IntelTeamGroupBox({
    required this.title,
    required this.subtitle,
    required this.teams,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          if (teams.isEmpty)
            const Text(
              'Brak wyraźnych kandydatów.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: teams.map((teamName) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  ),
                  child: Text(
                    teamName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _CounterPlanItemCard extends StatelessWidget {
  final DsStageTacticalPlan plan;
  final bool isApplied;
  final bool isDisabled;
  final bool isCompact;
  final VoidCallback onApply;

  const _CounterPlanItemCard({
    required this.plan,
    required this.isApplied,
    required this.isDisabled,
    required this.isCompact,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApplied ? AppColors.statusSuccess : AppTheme.borderColor,
          width: isApplied ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                plan.archetype.icon,
                size: 16,
                color: plan.archetype.accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${plan.teamName} (${plan.archetype.shortLabel})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Atak ~${plan.plannedAttackKmToGo.toStringAsFixed(0)} km',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.counterStrategyTip,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          _ScoutingPrimaryButton(
            label: isApplied ? 'Aktywna w planie' : 'Ustaw kontrtaktykę',
            icon: isApplied ? Icons.check_circle_rounded : Icons.shield_rounded,
            isApplied: isApplied,
            isDisabled: isDisabled,
            isCompact: isCompact,
            onPressed: onApply,
          ),
        ],
      ),
    );
  }
}

class _ScoutingPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isApplied;
  final bool isDisabled;
  final bool isCompact;
  final VoidCallback onPressed;

  const _ScoutingPrimaryButton({
    required this.label,
    required this.icon,
    required this.isApplied,
    required this.isDisabled,
    required this.isCompact,
    required this.onPressed,
  });

  @override
  State<_ScoutingPrimaryButton> createState() => _ScoutingPrimaryButtonState();
}

class _ScoutingPrimaryButtonState extends State<_ScoutingPrimaryButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isApplied ? AppColors.statusSuccess : AppColors.primaryAccent;
    final bgColor = _pressed
        ? baseColor.withValues(alpha: 0.78)
        : _hovered
            ? baseColor.withValues(alpha: 0.92)
            : baseColor;

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.isDisabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.isCompact ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: widget.isCompact ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
