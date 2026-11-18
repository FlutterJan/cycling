import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/youth_talent_summer_combine_camp.dart';

/// Zakładki główne ekranu testów laboratoryjnych i wyścigu selekcyjnego juniorów.
enum CombineTryoutsTab {
  overview('Obóz & Przegląd', Icons.flag_rounded),
  labTests('Laboratorium (4 Stacje)', Icons.biotech_rounded),
  selectionRace('Wyścig Selekcyjny 85 km', Icons.directions_bike_rounded),
  draftBoard('Draft & Kontrakty', Icons.workspace_premium_rounded);

  final String label;
  final IconData icon;

  const CombineTryoutsTab(this.label, this.icon);
}

/// Filtr statusu kandydatów na liście obozu Combine.
enum CombineStatusFilter {
  all('Wszyscy'),
  shortlisted('Lista życzeń'),
  fullyTested('Pełne Lab'),
  signed('Podpisani');

  final String label;

  const CombineStatusFilter(this.label);
}

/// Ekran testów laboratoryjnych i wyścigu selekcyjnego juniorów
/// (`Global Young Talent Combine`).
///
/// Integruje się z [youthTalentSummerCombineProvider] oraz obsługuje responsywnie
/// rozdzielczości `390x844`, `1024x768` i `1600x900` z pełnymi stanami
/// `hover`, `active`, `disabled` i `focus`.
class TalentCombineTryoutsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const TalentCombineTryoutsScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<TalentCombineTryoutsScreen> createState() =>
      _TalentCombineTryoutsScreenState();
}

class _TalentCombineTryoutsScreenState
    extends ConsumerState<TalentCombineTryoutsScreen> {
  CombineTryoutsTab _activeTab = CombineTryoutsTab.overview;
  CombineCampLocation _selectedLocation = CombineCampLocation.aigleUciWcc;
  int _candidateCount = 16;
  int _maxSlotsToSign = 3;
  int _scoutSkill = 85;
  double _courseMountainWeight = 0.50;
  double _courseSprintWeight = 0.30;
  CombineStatusFilter _statusFilter = CombineStatusFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  List<CombineTalentCandidate> _filteredCandidates(
    YouthTalentSummerCombineState state,
    CombineCampEdition edition,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = edition.candidates.where((c) {
      if (state.regionFilter != null && c.region != state.regionFilter) {
        return false;
      }
      switch (_statusFilter) {
        case CombineStatusFilter.all:
          break;
        case CombineStatusFilter.shortlisted:
          if (c.status != CombineCandidateStatus.shortlisted) return false;
          break;
        case CombineStatusFilter.fullyTested:
          if (!c.isFullyLabTested) return false;
          break;
        case CombineStatusFilter.signed:
          if (!c.status.isSigned) return false;
          break;
      }
      if (query.isNotEmpty) {
        final fullName = c.rider.fullName.toLowerCase();
        final nat = c.rider.nationalityIso.toLowerCase();
        final role = c.recommendedRoleNote.toLowerCase();
        if (!fullName.contains(query) &&
            !nat.contains(query) &&
            !role.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (state.sortBy) {
        case CombineSortField.combineScore:
          return b.combineCompositeScore.compareTo(a.combineCompositeScore);
        case CombineSortField.estimatedPotential:
          final aMid = (a.estimatedPotentialMin + a.estimatedPotentialMax) / 2;
          final bMid = (b.estimatedPotentialMin + b.estimatedPotentialMax) / 2;
          return bMid.compareTo(aMid);
        case CombineSortField.wattsPerKg:
          return b.wPerKg20m.compareTo(a.wPerKg20m);
        case CombineSortField.selectionRaceRank:
          final aRank = a.raceResult?.rank ?? 999;
          final bRank = b.raceResult?.rank ?? 999;
          return aRank.compareTo(bRank);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(youthTalentSummerCombineProvider);
    final notifier = ref.read(youthTalentSummerCombineProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 720;
            final isDesktop = width >= 1180;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(state, isMobile),
                _buildTabBar(state, isMobile),
                if (state.feedbackMessage != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 20,
                      10,
                      isMobile ? 12 : 20,
                      0,
                    ),
                    child: _buildFeedbackBanner(
                      state.feedbackMessage!,
                      state.isErrorFeedback,
                    ),
                  ),
                Expanded(
                  child: _buildActiveBody(
                    state: state,
                    notifier: notifier,
                    isMobile: isMobile,
                    isDesktop: isDesktop,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(YouthTalentSummerCombineState state, bool isMobile) {
    final edition = state.activeEdition;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 10 : 14,
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
              _CombineActionButton(
                icon: Icons.arrow_back_rounded,
                label: isMobile ? '' : 'Powrót',
                variant: _CombineButtonVariant.secondary,
                compact: isMobile,
                onTap: _handleBack,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Young Talent Combine',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      edition == null
                          ? 'Centrum testów laboratoryjnych i wyścigu selekcyjnego U19'
                          : '${edition.location.label} • ${edition.phase.label}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
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
              _buildMetricPill(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Budżet',
                value: Formatters.formatCurrency(state.availableBudgetEur),
                accent: AppColors.goldAccent,
              ),
              if (edition != null)
                _buildMetricPill(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Sloty',
                  value:
                      '${edition.signedCandidateIds.length}/${edition.maxSlotsToSign}',
                  accent: AppColors.accentBlue,
                ),
              _buildScoutSkillSelector(isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
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
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoutSkillSelector(bool isMobile) {
    const levels = [70, 80, 90, 95];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_rounded,
            size: 14,
            color: AppColors.cyanAccent,
          ),
          if (!isMobile) ...[
            const SizedBox(width: 5),
            const Text(
              'Skaut:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(width: 6),
          for (final lvl in levels) ...[
            _CombineChipButton(
              label: '$lvl',
              selected: _scoutSkill == lvl,
              accentColor: AppColors.cyanAccent,
              onTap: () => setState(() => _scoutSkill = lvl),
            ),
            if (lvl != levels.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar(YouthTalentSummerCombineState state, bool isMobile) {
    final hasEdition = state.activeEdition != null;
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in CombineTryoutsTab.values) ...[
              _CombineTabButton(
                tab: tab,
                selected: _activeTab == tab,
                disabled: !hasEdition && tab != CombineTryoutsTab.overview,
                onTap: () => setState(() => _activeTab = tab),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner(String message, bool isError) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBody({
    required YouthTalentSummerCombineState state,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final edition = state.activeEdition;
    if (edition == null || _activeTab == CombineTryoutsTab.overview) {
      return _buildOverviewTab(
        state: state,
        edition: edition,
        notifier: notifier,
        isMobile: isMobile,
        isDesktop: isDesktop,
      );
    }

    switch (_activeTab) {
      case CombineTryoutsTab.overview:
        return _buildOverviewTab(
          state: state,
          edition: edition,
          notifier: notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
        );
      case CombineTryoutsTab.labTests:
        return _buildLabTestsTab(
          state: state,
          edition: edition,
          notifier: notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
        );
      case CombineTryoutsTab.selectionRace:
        return _buildSelectionRaceTab(
          state: state,
          edition: edition,
          notifier: notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
        );
      case CombineTryoutsTab.draftBoard:
        return _buildDraftBoardTab(
          state: state,
          edition: edition,
          notifier: notifier,
          isMobile: isMobile,
          isDesktop: isDesktop,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 1: OBÓZ & PRZEGLĄD
  // ---------------------------------------------------------------------------

  Widget _buildOverviewTab({
    required YouthTalentSummerCombineState state,
    required CombineCampEdition? edition,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isMobile,
    required bool isDesktop,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (edition == null)
            _buildLaunchCampSection(state, notifier, isMobile, isDesktop)
          else
            _buildActiveEditionOverview(state, edition, notifier, isMobile, isDesktop),
          if (state.history.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildHistoryArchiveCard(state.history, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildLaunchCampSection(
    YouthTalentSummerCombineState state,
    YouthTalentSummerCombineNotifier notifier,
    bool isMobile,
    bool isDesktop,
  ) {
    final canAfford =
        state.availableBudgetEur >= _selectedLocation.organizationCostEur;
    return _SectionCard(
      title: 'Konfiguracja Nowej Edycji Combine',
      subtitle:
          'Wybierz ośrodek testowy, wielkość kohorty 17-latków oraz liczbę miejsc kontraktowych.',
      icon: Icons.rocket_launch_rounded,
      accent: AppColors.goldAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final cols = isDesktop ? 3 : (box.maxWidth >= 600 ? 2 : 1);
              const spacing = 12.0;
              final itemWidth = (box.maxWidth - (cols - 1) * spacing) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final loc in CombineCampLocation.values)
                    SizedBox(
                      width: itemWidth,
                      child: _LocationSelectorCard(
                        location: loc,
                        selected: _selectedLocation == loc,
                        affordable: state.availableBudgetEur >= loc.organizationCostEur,
                        onTap: () => setState(() => _selectedLocation = loc),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildIntOptionGroup(
                label: 'Liczba talentów w kohorcie',
                options: const [12, 16, 20],
                selectedValue: _candidateCount,
                onSelected: (v) => setState(() => _candidateCount = v),
              ),
              _buildIntOptionGroup(
                label: 'Limit kontraktów',
                options: const [2, 3, 4],
                selectedValue: _maxSlotsToSign,
                onSelected: (v) => setState(() => _maxSlotsToSign = v),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koszt organizacji: ${Formatters.formatCurrency(_selectedLocation.organizationCostEur)}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canAfford
                            ? AppColors.goldAccent
                            : AppColors.crimsonAlert,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Wysokość testów: ${_selectedLocation.altitudeMeters} m n.p.m. (${_selectedLocation.countryIso})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CombineActionButton(
                icon: Icons.play_arrow_rounded,
                label: 'Otwórz Obóz Combine',
                variant: _CombineButtonVariant.gold,
                disabled: !canAfford,
                onTap: () {
                  notifier.launchNewEdition(
                    location: _selectedLocation,
                    candidateCount: _candidateCount,
                    maxSlotsToSign: _maxSlotsToSign,
                  );
                  setState(() => _activeTab = CombineTryoutsTab.labTests);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntOptionGroup({
    required String label,
    required List<int> options,
    required int selectedValue,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          for (final v in options)
            _CombineChipButton(
              label: '$v',
              selected: selectedValue == v,
              accentColor: AppColors.goldAccent,
              onTap: () => onSelected(v),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveEditionOverview(
    YouthTalentSummerCombineState state,
    CombineCampEdition edition,
    YouthTalentSummerCombineNotifier notifier,
    bool isMobile,
    bool isDesktop,
  ) {
    final isConcluded = edition.phase == CombineCampPhase.concluded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Przebieg Obozu Selekcyjnego ${edition.seasonYear}',
          subtitle: edition.campSummaryNote,
          icon: Icons.timeline_rounded,
          accent: AppColors.accentBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPhaseStepper(edition.phase, isMobile),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildKpiTile(
                    label: 'Kandydaci',
                    value: '${edition.candidates.length}',
                    subLabel: 'Globalna kohorta U19',
                    accent: AppColors.textPrimary,
                  ),
                  _buildKpiTile(
                    label: 'Pełne Lab',
                    value:
                        '${edition.fullyTestedCount}/${edition.candidates.length}',
                    subLabel: '${edition.testedCandidatesCount} rozpoczętych',
                    accent: AppColors.cyanAccent,
                  ),
                  _buildKpiTile(
                    label: 'Wyścig 85 km',
                    value: edition.isSelectionRaceCompleted
                        ? 'Ukończony'
                        : 'Oczekuje',
                    subLabel: edition.isSelectionRaceCompleted
                        ? 'Pełna telemetria'
                        : 'Gotowy do symulacji',
                    accent: edition.isSelectionRaceCompleted
                        ? AppColors.statusSuccess
                        : AppColors.amberWarning,
                  ),
                  _buildKpiTile(
                    label: 'Podpisani',
                    value:
                        '${edition.signedCandidateIds.length}/${edition.maxSlotsToSign}',
                    subLabel: 'Pozostało ${edition.remainingSignSlots} slotów',
                    accent: AppColors.goldAccent,
                  ),
                  _buildKpiTile(
                    label: 'Wydano',
                    value: Formatters.formatCurrency(edition.budgetSpentEur),
                    subLabel: 'Ośrodek: ${edition.location.countryIso}',
                    accent: AppColors.primaryAccent,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CombineActionButton(
                    icon: Icons.biotech_rounded,
                    label: 'Przejdź do Laboratorium',
                    variant: _CombineButtonVariant.primary,
                    onTap: () =>
                        setState(() => _activeTab = CombineTryoutsTab.labTests),
                  ),
                  _CombineActionButton(
                    icon: Icons.directions_bike_rounded,
                    label: 'Wyścig Selekcyjny 85 km',
                    variant: _CombineButtonVariant.secondary,
                    onTap: () => setState(
                      () => _activeTab = CombineTryoutsTab.selectionRace,
                    ),
                  ),
                  _CombineActionButton(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Board Draftu',
                    variant: _CombineButtonVariant.secondary,
                    onTap: () =>
                        setState(() => _activeTab = CombineTryoutsTab.draftBoard),
                  ),
                  _CombineActionButton(
                    icon: Icons.check_circle_rounded,
                    label: isConcluded ? 'Obóz Zakończony' : 'Zakończ Obóz',
                    variant: _CombineButtonVariant.gold,
                    disabled: isConcluded,
                    onTap: notifier.concludeActiveCamp,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isConcluded) ...[
          const SizedBox(height: 16),
          _buildLaunchCampSection(state, notifier, isMobile, isDesktop),
        ],
      ],
    );
  }

  Widget _buildPhaseStepper(CombineCampPhase currentPhase, bool isMobile) {
    const phases = [
      CombineCampPhase.labTestingInProgress,
      CombineCampPhase.selectionRaceCompleted,
      CombineCampPhase.draftingWindowOpen,
      CombineCampPhase.concluded,
    ];
    final currentIndex = phases.indexOf(currentPhase);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < phases.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: i == currentIndex
                  ? AppColors.accentBlue.withValues(alpha: 0.16)
                  : (i < currentIndex
                      ? AppColors.statusSuccess.withValues(alpha: 0.12)
                      : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: i == currentIndex
                    ? AppColors.accentBlue
                    : (i < currentIndex
                        ? AppColors.statusSuccess.withValues(alpha: 0.5)
                        : const Color(0xFF2A2F3D)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  i < currentIndex
                      ? Icons.check_circle_rounded
                      : (i == currentIndex
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded),
                  size: 14,
                  color: i == currentIndex
                      ? AppColors.accentBlue
                      : (i < currentIndex
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  '${i + 1}. ${phases[i].label}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isMobile ? 11 : 12,
                    fontWeight:
                        i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                    color: i == currentIndex
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required String subLabel,
    required Color accent,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryArchiveCard(
    List<CombineCampHistoryEntry> history,
    bool isMobile,
  ) {
    return _SectionCard(
      title: 'Archiwum Poprzednich Edycji Combine',
      subtitle: 'Historia odkrytych fenomenów pokolenia i podpisanych juniorów.',
      icon: Icons.history_edu_rounded,
      accent: AppColors.textSecondary,
      child: Column(
        children: [
          for (final entry in history)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Sezon ${entry.seasonYear} • ${entry.location.label}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Top: ${entry.topProspectName} (${entry.topCombineScore.toStringAsFixed(1)} pkt) • Podpisano: ${entry.signedCount}/${entry.totalCandidates}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.goldAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: LABORATORIUM FIZJOLOGII (4 STACJE)
  // ---------------------------------------------------------------------------

  Widget _buildLabTestsTab({
    required YouthTalentSummerCombineState state,
    required CombineCampEdition edition,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final candidates = _filteredCandidates(state, edition);
    final selected = state.selectedCandidate ??
        (candidates.isNotEmpty ? candidates.first : null);
    final isConcluded = edition.phase == CombineCampPhase.concluded;

    final listPanel = _buildCandidateListPanel(
      state: state,
      candidates: candidates,
      selectedId: selected?.id,
      notifier: notifier,
      isMobile: isMobile,
    );

    final labWorkbench = selected == null
        ? _buildEmptySelectionCard()
        : _buildLabWorkbench(
            state: state,
            candidate: selected,
            notifier: notifier,
            isConcluded: isConcluded,
            isMobile: isMobile,
          );

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 390,
              child: SingleChildScrollView(child: listPanel),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SingleChildScrollView(child: labWorkbench),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          listPanel,
          const SizedBox(height: 16),
          labWorkbench,
        ],
      ),
    );
  }

  Widget _buildCandidateListPanel({
    required YouthTalentSummerCombineState state,
    required List<CombineTalentCandidate> candidates,
    required String? selectedId,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isMobile,
  }) {
    return _SectionCard(
      title: 'Lista Adeptów (${candidates.length})',
      subtitle: 'Wybierz juniora do badań fizjologicznych i oceny skautingowej.',
      icon: Icons.groups_rounded,
      accent: AppColors.accentBlue,
      trailing: _CombineActionButton(
        icon: Icons.science_rounded,
        label: 'Batch Lab',
        compact: true,
        variant: _CombineButtonVariant.primary,
        disabled: state.activeEdition?.phase == CombineCampPhase.concluded,
        onTap: () => notifier.runBatchLabForAll(scoutSkill: _scoutSkill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Szukaj nazwiska, kraju lub roli...',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accentBlue),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CombineChipButton(
                  label: 'Wszystkie regiony',
                  selected: state.regionFilter == null,
                  accentColor: AppColors.accentBlue,
                  onTap: () => notifier.setRegionFilter(null),
                ),
                const SizedBox(width: 6),
                for (final region in CombineRegion.values) ...[
                  _CombineChipButton(
                    label: region.label,
                    selected: state.regionFilter == region,
                    accentColor: AppColors.accentBlue,
                    onTap: () => notifier.setRegionFilter(region),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in CombineStatusFilter.values) ...[
                  _CombineChipButton(
                    label: f.label,
                    selected: _statusFilter == f,
                    accentColor: AppColors.goldAccent,
                    onTap: () => setState(() => _statusFilter = f),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: isMobile ? 160 : 380,
            child: candidates.isEmpty
                ? const Center(
                    child: Text(
                      'Brak kandydatów spełniających wybrane filtry.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];
                      return _CombineCandidateTile(
                        candidate: candidate,
                        selected: candidate.id == selectedId,
                        onTap: () => notifier.selectCandidate(candidate.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySelectionCard() {
    return const _SectionCard(
      title: 'Brak Wybranego Kandydata',
      subtitle: 'Wybierz juniora z listy po lewej stronie, aby rozpocząć testy.',
      icon: Icons.person_search_rounded,
      accent: AppColors.textSecondary,
      child: SizedBox(height: 120),
    );
  }

  Widget _buildLabWorkbench({
    required YouthTalentSummerCombineState state,
    required CombineTalentCandidate candidate,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isConcluded,
    required bool isMobile,
  }) {
    final remainingFee = CombineTestStation.values
        .where((s) => !candidate.testedStations.containsKey(s))
        .fold<int>(0, (sum, s) => sum + s.testFeeEur);
    final canRunAll = !isConcluded &&
        !candidate.isFullyLabTested &&
        state.availableBudgetEur >= remainingFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: '${candidate.rider.fullName} (${candidate.rider.nationalityIso})',
          subtitle:
              '${candidate.prospectTier.label} • ${candidate.recommendedRoleNote}',
          icon: Icons.monitor_heart_rounded,
          accent: AppColors.cyanAccent,
          trailing: _CombineActionButton(
            icon: Icons.playlist_add_check_rounded,
            label: candidate.isFullyLabTested
                ? 'Pełne Lab Ukończone'
                : 'Wszystkie Stacje (${Formatters.formatCurrency(remainingFee)})',
            compact: isMobile,
            variant: _CombineButtonVariant.gold,
            disabled: !canRunAll,
            onTap: () => notifier.runAllLabForCandidate(
              candidateId: candidate.id,
              scoutSkill: _scoutSkill,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildKpiTile(
                    label: 'Ocena Combine',
                    value: candidate.combineCompositeScore.toStringAsFixed(1),
                    subLabel: 'Skala 0–100 pkt',
                    accent: AppColors.goldAccent,
                  ),
                  _buildKpiTile(
                    label: 'Szac. Potencjał',
                    value: candidate.displayPotentialRange,
                    subLabel: 'Rozrzut ±${candidate.potentialSpread} pkt',
                    accent: AppColors.accentBlue,
                  ),
                  _buildKpiTile(
                    label: 'W/kg (20 min)',
                    value: candidate.wPerKg20m.toStringAsFixed(2),
                    subLabel:
                        '${candidate.rider.physiology.weightKg.toStringAsFixed(1)} kg • ${candidate.rider.physiology.heightCm} cm',
                    accent: AppColors.statusSuccess,
                  ),
                  _buildKpiTile(
                    label: 'Status',
                    value: candidate.status.label,
                    subLabel:
                        '${candidate.testedStations.length}/4 stacji ukończonych',
                    accent: AppColors.cyanAccent,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, box) {
                  final showSideBySide = box.maxWidth >= 700;
                  final radar = Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A2F3D)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Profil Fizjologiczny vs Benchmark U23 Pro',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: CombineLabRadarPainter(candidate: candidate),
                          ),
                        ),
                      ],
                    ),
                  );

                  final stationsGrid = Column(
                    children: [
                      for (final station in CombineTestStation.values) ...[
                        _buildLabStationCard(
                          state: state,
                          candidate: candidate,
                          station: station,
                          notifier: notifier,
                          isConcluded: isConcluded,
                        ),
                        if (station != CombineTestStation.values.last)
                          const SizedBox(height: 10),
                      ],
                    ],
                  );

                  if (showSideBySide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 280, child: radar),
                        const SizedBox(width: 14),
                        Expanded(child: stationsGrid),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      radar,
                      const SizedBox(height: 14),
                      stationsGrid,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabStationCard({
    required YouthTalentSummerCombineState state,
    required CombineTalentCandidate candidate,
    required CombineTestStation station,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isConcluded,
  }) {
    final result = candidate.testedStations[station];
    final isTested = result != null;
    final canAfford = state.availableBudgetEur >= station.testFeeEur;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTested
              ? AppColors.statusSuccess.withValues(alpha: 0.5)
              : const Color(0xFF2A2F3D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isTested ? Icons.verified_rounded : Icons.science_outlined,
                size: 18,
                color: isTested ? AppColors.statusSuccess : AppColors.cyanAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  station.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!isTested)
                _CombineActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: Formatters.formatCurrency(station.testFeeEur),
                  compact: true,
                  variant: _CombineButtonVariant.primary,
                  disabled: isConcluded || !canAfford,
                  onTap: () => notifier.runLabStation(
                    candidateId: candidate.id,
                    station: station,
                    scoutSkill: _scoutSkill,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Wynik: ${result.rawScore.toStringAsFixed(1)}/100',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusSuccess,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildInlineTelemetry(
                  'VO2max',
                  '${result.measuredVo2Max.toStringAsFixed(1)} ml/kg',
                ),
                _buildInlineTelemetry(
                  'FTP',
                  '${result.measuredFtpWatts.round()} W',
                ),
                _buildInlineTelemetry(
                  '20m',
                  '${result.measuredWPerKg20m.toStringAsFixed(2)} W/kg',
                ),
                _buildInlineTelemetry(
                  '5s Peak',
                  '${result.measuredPeakSprintWatts.round()} W',
                ),
                _buildInlineTelemetry(
                  'Mleczan',
                  '${result.measuredLactateThresholdMmol.toStringAsFixed(1)} mmol/L',
                ),
                _buildInlineTelemetry(
                  'VAM',
                  '${result.measuredVamMetersPerHour.round()} m/h',
                ),
              ],
            ),
            if (result.scoutNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                result.scoutNote,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInlineTelemetry(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: WYŚCIG SELEKCYJNY 85 KM
  // ---------------------------------------------------------------------------

  Widget _buildSelectionRaceTab({
    required YouthTalentSummerCombineState state,
    required CombineCampEdition edition,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final isConcluded = edition.phase == CombineCampPhase.concluded;
    final racedCandidates = edition.candidates
        .where((c) => c.raceResult != null)
        .toList()
      ..sort(
        (a, b) => a.raceResult!.rank.compareTo(b.raceResult!.rank),
      );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Trasa Wyścigu Selekcyjnego Juniorów (85 km)',
            subtitle:
                'Skonfiguruj profil trasy przed startem lub przeanalizuj wyniki walki bezpośredniej.',
            icon: Icons.terrain_rounded,
            accent: AppColors.primaryAccent,
            trailing: _CombineActionButton(
              icon: Icons.flag_rounded,
              label: edition.isSelectionRaceCompleted
                  ? 'Wyścig Rozegrany'
                  : 'Symuluj Wyścig 85 km',
              variant: _CombineButtonVariant.gold,
              disabled: isConcluded || edition.isSelectionRaceCompleted,
              onTap: () => notifier.simulateSelectionRace(
                courseMountainWeight: _courseMountainWeight,
                courseSprintWeight: _courseSprintWeight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CombineChipButton(
                      label: 'Płaski / Sprinterski',
                      selected: _courseMountainWeight < 0.30,
                      accentColor: AppColors.accentBlue,
                      onTap: edition.isSelectionRaceCompleted
                          ? null
                          : () => setState(() {
                                _courseMountainWeight = 0.20;
                                _courseSprintWeight = 0.65;
                              }),
                    ),
                    _CombineChipButton(
                      label: 'Pagórkowaty / Klasyk',
                      selected: _courseMountainWeight >= 0.30 &&
                          _courseMountainWeight <= 0.60,
                      accentColor: AppColors.goldAccent,
                      onTap: edition.isSelectionRaceCompleted
                          ? null
                          : () => setState(() {
                                _courseMountainWeight = 0.50;
                                _courseSprintWeight = 0.30;
                              }),
                    ),
                    _CombineChipButton(
                      label: 'Górski / Wspinaczkowy',
                      selected: _courseMountainWeight > 0.60,
                      accentColor: AppColors.primaryAccent,
                      onTap: edition.isSelectionRaceCompleted
                          ? null
                          : () => setState(() {
                                _courseMountainWeight = 0.80;
                                _courseSprintWeight = 0.15;
                              }),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2F3D)),
                  ),
                  child: CustomPaint(
                    painter: CombineSelectionCoursePainter(
                      mountainWeight: _courseMountainWeight,
                      sprintWeight: _courseSprintWeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (racedCandidates.isEmpty)
            const _SectionCard(
              title: 'Oczekiwanie na Start',
              subtitle:
                  'Uruchom symulację wyścigu selekcyjnego 85 km, aby zobaczyć klasyfikację, ataki i Race IQ.',
              icon: Icons.hourglass_empty_rounded,
              accent: AppColors.amberWarning,
              child: SizedBox(height: 64),
            )
          else ...[
            _buildPodiumBanner(racedCandidates.take(3).toList(), isMobile),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Klasyfikacja Końcowa i Telemetria (${racedCandidates.length})',
              subtitle:
                  'Kliknij dowolnego juniora, aby otworzyć jego profil w laboratorium lub na boardzie draftu.',
              icon: Icons.leaderboard_rounded,
              accent: AppColors.goldAccent,
              child: Column(
                children: [
                  for (final candidate in racedCandidates) ...[
                    _buildRaceResultRow(candidate, notifier, isMobile),
                    if (candidate != racedCandidates.last)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPodiumBanner(
    List<CombineTalentCandidate> podium,
    bool isMobile,
  ) {
    final colors = [
      AppColors.goldAccent,
      const Color(0xFFC0C7D4),
      const Color(0xFFCD7F32),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < podium.length; i++)
          Container(
            width: isMobile ? double.infinity : 260,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors[i].withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 18, color: colors[i]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Miejsce #${i + 1}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors[i],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        podium[i].raceResult!.formattedGap,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${podium[i].rider.fullName} (${podium[i].rider.nationalityIso})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NP ${podium[i].raceResult!.normalizedPowerWPerKg.toStringAsFixed(2)} W/kg • Race IQ ${podium[i].raceResult!.raceIqScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRaceResultRow(
    CombineTalentCandidate candidate,
    YouthTalentSummerCombineNotifier notifier,
    bool isMobile,
  ) {
    final race = candidate.raceResult!;
    return InkWell(
      onTap: () {
        notifier.selectCandidate(candidate.id);
        setState(() => _activeTab = CombineTryoutsTab.draftBoard);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2F3D)),
        ),
        child: Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: race.rank <= 3
                    ? AppColors.goldAccent.withValues(alpha: 0.16)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: race.rank <= 3
                      ? AppColors.goldAccent
                      : const Color(0xFF2A2F3D),
                ),
              ),
              child: Text(
                '${race.rank}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: race.rank <= 3
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            SizedBox(
              width: isMobile ? 180 : 210,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${candidate.rider.fullName} (${candidate.rider.nationalityIso})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${candidate.prospectTier.label} • ${race.formattedGap}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildInlineTelemetry(
              'Moc',
              '${race.avgPowerWatts.round()} W (${race.normalizedPowerWPerKg.toStringAsFixed(2)} W/kg)',
            ),
            _buildInlineTelemetry(
              'Ucieczka',
              '${race.breakawayKm.toStringAsFixed(1)} km (${race.attackCount} ataki)',
            ),
            _buildInlineTelemetry(
              'Race IQ',
              '${race.raceIqScore.toStringAsFixed(0)}/100',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: DRAFT & KONTRAKTY
  // ---------------------------------------------------------------------------

  Widget _buildDraftBoardTab({
    required YouthTalentSummerCombineState state,
    required CombineCampEdition edition,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final candidates = _filteredCandidates(state, edition);
    final isConcluded = edition.phase == CombineCampPhase.concluded;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Board Draftu i Kontraktów Juniorów',
            subtitle:
                'Pozostałe sloty: ${edition.remainingSignSlots}/${edition.maxSlotsToSign} • Sortowanie i selekcja finalistów Combine.',
            icon: Icons.workspace_premium_rounded,
            accent: AppColors.goldAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sort in CombineSortField.values)
                      _CombineChipButton(
                        label: sort.label,
                        selected: state.sortBy == sort,
                        accentColor: AppColors.goldAccent,
                        onTap: () => notifier.setSortField(sort),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (candidates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Brak kandydatów w bieżącym widoku.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final c in candidates) ...[
                        _buildDraftCandidateCard(
                          state: state,
                          edition: edition,
                          candidate: c,
                          notifier: notifier,
                          isConcluded: isConcluded,
                          isMobile: isMobile,
                        ),
                        if (c != candidates.last) const SizedBox(height: 12),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCandidateCard({
    required YouthTalentSummerCombineState state,
    required CombineCampEdition edition,
    required CombineTalentCandidate candidate,
    required YouthTalentSummerCombineNotifier notifier,
    required bool isConcluded,
    required bool isMobile,
  }) {
    final isSigned = candidate.status.isSigned;
    final isShortlisted =
        candidate.status == CombineCandidateStatus.shortlisted;
    final canSign = !isConcluded &&
        !isSigned &&
        edition.remainingSignSlots > 0 &&
        state.availableBudgetEur >= candidate.signingFeeEur;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSigned
              ? AppColors.statusSuccess.withValues(alpha: 0.6)
              : (isShortlisted
                  ? AppColors.goldAccent.withValues(alpha: 0.55)
                  : const Color(0xFF2A2F3D)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${candidate.rider.fullName} (${candidate.rider.nationalityIso}) • ${candidate.region.label}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${candidate.prospectTier.label} • ${candidate.recommendedRoleNote}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A2F3D)),
                ),
                child: Text(
                  candidate.status.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isSigned
                        ? AppColors.statusSuccess
                        : AppColors.goldAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _buildInlineTelemetry(
                'Combine',
                '${candidate.combineCompositeScore.toStringAsFixed(1)} pkt',
              ),
              _buildInlineTelemetry(
                'Potencjał',
                candidate.displayPotentialRange,
              ),
              _buildInlineTelemetry(
                'W/kg',
                candidate.wPerKg20m.toStringAsFixed(2),
              ),
              _buildInlineTelemetry(
                'Lab',
                '${candidate.testedStations.length}/4',
              ),
              if (candidate.raceResult != null)
                _buildInlineTelemetry(
                  'Wyścig',
                  '#${candidate.raceResult!.rank} (${candidate.raceResult!.formattedGap})',
                ),
              _buildInlineTelemetry(
                'Konkurencja',
                '${candidate.competingTeamsInterest} zespoły',
              ),
              _buildInlineTelemetry(
                'Opłata',
                Formatters.formatCurrency(candidate.signingFeeEur),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CombineActionButton(
                icon: isShortlisted
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: isShortlisted ? 'Na liście życzeń' : 'Lista życzeń',
                compact: isMobile,
                variant: _CombineButtonVariant.secondary,
                disabled: isConcluded || isSigned,
                onTap: () => notifier.toggleShortlist(candidate.id),
              ),
              _CombineActionButton(
                icon: Icons.school_rounded,
                label: 'Podpisz (U19/U23)',
                compact: isMobile,
                variant: _CombineButtonVariant.primary,
                disabled: !canSign,
                onTap: () => notifier.signCandidate(
                  candidateId: candidate.id,
                  toSeniorProSquad: false,
                ),
              ),
              _CombineActionButton(
                icon: Icons.verified_user_rounded,
                label: 'Podpisz (Pro)',
                compact: isMobile,
                variant: _CombineButtonVariant.gold,
                disabled: !canSign,
                onTap: () => notifier.signCandidate(
                  candidateId: candidate.id,
                  toSeniorProSquad: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================

/// Wykres radarowy 5-osiowy prezentujący profil fizjologiczny juniora
/// na tle benchmarku zawodowego kolarza U23.
class CombineLabRadarPainter extends CustomPainter {
  final CombineTalentCandidate candidate;

  const CombineLabRadarPainter({required this.candidate});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;
    const axesCount = 5;

    final gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      final path = Path();
      for (var i = 0; i < axesCount; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * i / axesCount);
        final pt = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < axesCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / axesCount);
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    final vo2Val = ((candidate.rider.physiology.vo2Max - 60) / 30).clamp(0.2, 1.0);
    final wkgVal = ((candidate.wPerKg20m - 4.5) / 2.2).clamp(0.2, 1.0);
    final sprintVal = ((candidate.rider.powerProfile.watts5s - 900) / 700).clamp(0.2, 1.0);
    final techVal = (candidate.rider.skills.overallTechnicalSkill / 100).clamp(0.2, 1.0);
    final iqVal = ((candidate.raceResult?.raceIqScore ?? candidate.combineCompositeScore) / 100)
        .clamp(0.2, 1.0);

    final values = [vo2Val, wkgVal, sprintVal, techVal, iqVal];
    final labels = ['VO2max', 'W/kg', 'Sprint', 'Tech', 'Race IQ'];

    final fillPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dataPath = Path();
    for (var i = 0; i < axesCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / axesCount);
      final r = radius * values[i];
      final pt = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(pt.dx, pt.dy);
      } else {
        dataPath.lineTo(pt.dx, pt.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    for (var i = 0; i < axesCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / axesCount);
      final labelOffset = Offset(
        center.dx + (radius + 18) * math.cos(angle),
        center.dy + (radius + 18) * math.sin(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          labelOffset.dx - tp.width / 2,
          labelOffset.dy - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CombineLabRadarPainter oldDelegate) {
    return oldDelegate.candidate != candidate;
  }
}

/// Wykres profilu wysokościowego 85-kilometrowego wyścigu selekcyjnego juniorów.
class CombineSelectionCoursePainter extends CustomPainter {
  final double mountainWeight;
  final double sprintWeight;

  const CombineSelectionCoursePainter({
    required this.mountainWeight,
    required this.sprintWeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    const samples = 24;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final climb1 = math.sin(t * math.pi * 2.5).clamp(0.0, 1.0) * mountainWeight * 0.65;
      final climb2 = math.pow(math.sin(t * math.pi).clamp(0.0, 1.0), 2) * mountainWeight * 0.55;
      final flatFinish = t > 0.85 ? (1.0 - sprintWeight * 0.6) : 1.0;
      final elevation = ((climb1 + climb2) * flatFinish).clamp(0.05, 0.90);
      points.add(
        Offset(
          t * size.width,
          size.height - (elevation * size.height * 0.82) - 8,
        ),
      );
    }

    final fillPath = Path()..moveTo(0, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryAccent.withValues(alpha: 0.45),
          AppColors.primaryAccent.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    final linePaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CombineSelectionCoursePainter oldDelegate) {
    return oldDelegate.mountainWeight != mountainWeight ||
        oldDelegate.sprintWeight != sprintWeight;
  }
}

// =============================================================================
// REUSABLE INTERACTIVE UI COMPONENTS (HOVER / ACTIVE / DISABLED / FOCUS)
// =============================================================================

enum _CombineButtonVariant { primary, secondary, gold }

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CombineActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final _CombineButtonVariant variant;
  final bool disabled;
  final bool compact;
  final VoidCallback onTap;

  const _CombineActionButton({
    required this.icon,
    required this.label,
    required this.variant,
    this.disabled = false,
    this.compact = false,
    required this.onTap,
  });

  @override
  State<_CombineActionButton> createState() => _CombineActionButtonState();
}

class _CombineActionButtonState extends State<_CombineActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor;
    final Color fgColor;
    switch (widget.variant) {
      case _CombineButtonVariant.primary:
        baseColor = AppColors.primaryAccent;
        fgColor = AppColors.textPrimary;
        break;
      case _CombineButtonVariant.secondary:
        baseColor = AppColors.surfaceLight;
        fgColor = AppColors.textPrimary;
        break;
      case _CombineButtonVariant.gold:
        baseColor = AppColors.goldAccent;
        fgColor = AppColors.background;
        break;
    }

    final bg = widget.disabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseColor.withValues(alpha: 0.80)
            : (_hovered ? baseColor.withValues(alpha: 0.92) : baseColor));

    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.disabled ? null : widget.onTap,
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 14,
              vertical: widget.compact ? 7 : 9,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.cyanAccent
                    : (widget.disabled
                        ? const Color(0xFF2A2F3D)
                        : baseColor.withValues(alpha: 0.7)),
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.disabled ? AppColors.textSecondary : fgColor,
                ),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.disabled ? AppColors.textSecondary : fgColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CombineTabButton extends StatefulWidget {
  final CombineTryoutsTab tab;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _CombineTabButton({
    required this.tab,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  State<_CombineTabButton> createState() => _CombineTabButtonState();
}

class _CombineTabButtonState extends State<_CombineTabButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: !widget.disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.25)
                  : (_hovered && !widget.disabled
                      ? AppColors.surfaceLight
                      : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.cyanAccent
                    : (widget.selected
                        ? AppColors.primaryAccent
                        : const Color(0xFF2A2F3D)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.tab.icon,
                  size: 16,
                  color: widget.disabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : (widget.selected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary),
                ),
                const SizedBox(width: 7),
                Text(
                  widget.tab.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.disabled
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
                        : (widget.selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary),
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

class _CombineChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback? onTap;

  const _CombineChipButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_CombineChipButton> createState() => _CombineChipButtonState();
}

class _CombineChipButtonState extends State<_CombineChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return FocusableActionDetector(
      enabled: !disabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor:
              disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accentColor.withValues(alpha: 0.22)
                  : (_hovered
                      ? AppColors.surfaceLight
                      : AppColors.background),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.cyanAccent
                    : (widget.selected
                        ? widget.accentColor
                        : const Color(0xFF2A2F3D)),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight:
                    widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationSelectorCard extends StatefulWidget {
  final CombineCampLocation location;
  final bool selected;
  final bool affordable;
  final VoidCallback onTap;

  const _LocationSelectorCard({
    required this.location,
    required this.selected,
    required this.affordable,
    required this.onTap,
  });

  @override
  State<_LocationSelectorCard> createState() => _LocationSelectorCardState();
}

class _LocationSelectorCardState extends State<_LocationSelectorCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.goldAccent.withValues(alpha: 0.12)
                  : (_hovered
                      ? AppColors.surfaceLight.withValues(alpha: 0.9)
                      : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused
                    ? AppColors.cyanAccent
                    : (widget.selected
                        ? AppColors.goldAccent
                        : const Color(0xFF2A2F3D)),
                width: widget.selected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.location.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(widget.location.organizationCostEur),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: widget.affordable
                            ? AppColors.goldAccent
                            : AppColors.crimsonAlert,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.location.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
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

class _CombineCandidateTile extends StatefulWidget {
  final CombineTalentCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  const _CombineCandidateTile({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CombineCandidateTile> createState() => _CombineCandidateTileState();
}

class _CombineCandidateTileState extends State<_CombineCandidateTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.accentBlue.withValues(alpha: 0.14)
                  : (_hovered ? AppColors.background : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.cyanAccent
                    : (widget.selected
                        ? AppColors.accentBlue
                        : const Color(0xFF2A2F3D)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.rider.fullName} (${c.rider.nationalityIso})',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.region.label} • Lab ${c.testedStations.length}/4 • Pot. ${c.displayPotentialRange}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  c.combineCompositeScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
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
