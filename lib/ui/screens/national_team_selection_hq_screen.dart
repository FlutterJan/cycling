import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/career/national_federation_team_manager_mode.dart';

/// Zakładki nawigacyjne w widoku mobilnym/tabletowym Biura Selekcjonera.
enum NationalTeamHqTab {
  callUpsAndPool('Powołania & Pula', Icons.how_to_reg_rounded),
  tacticsAndChemistry('Taktyka & Szatnia', Icons.psychology_rounded),
  federationAndHistory('Federacja & Wyniki', Icons.emoji_events_rounded);

  final String labelPl;
  final IconData icon;

  const NationalTeamHqTab(this.labelPl, this.icon);
}

/// Kryterium sortowania kandydatów do reprezentacji narodowej.
enum NationalCandidateSortBy {
  suitabilityScore('Dopasowanie'),
  uciPoints('Punkty UCI'),
  currentForm('Forma'),
  age('Wiek');

  final String labelPl;

  const NationalCandidateSortBy(this.labelPl);
}

/// Ekran Biura Selekcjonera Reprezentacji Narodowej i powołań kadry (MŚ / IO).
///
/// Zapewnia pełne zarządzanie powołaniami, rolami taktycznymi, negocjacjami
/// zwolnień klubowych, analizą chemii szatni oraz symulacją finałów MŚ i IO
/// w responsywnym układzie dla 390x844, 1024x768 i 1600x900.
class NationalTeamSelectionHqScreen extends ConsumerStatefulWidget {
  const NationalTeamSelectionHqScreen({
    super.key,
    this.isReadOnly = false,
    this.initialTab = NationalTeamHqTab.callUpsAndPool,
    this.onBackPressed,
  });

  final bool isReadOnly;
  final NationalTeamHqTab initialTab;
  final VoidCallback? onBackPressed;

  @override
  ConsumerState<NationalTeamSelectionHqScreen> createState() =>
      _NationalTeamSelectionHqScreenState();
}

class _NationalTeamSelectionHqScreenState
    extends ConsumerState<NationalTeamSelectionHqScreen> {
  static const Color _borderColor = Color(0xFF2A2F3D);

  late NationalTeamHqTab _activeTab;
  CandidatePoolFilter _poolFilter = CandidatePoolFilter.all;
  NationalCandidateSortBy _sortBy = NationalCandidateSortBy.suitabilityScore;
  String _searchQuery = '';
  String? _selectedCandidateId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nationalFederationManagerProvider);
    final chemistry = ref.watch(nationalSquadChemistryProvider);
    final notifier = ref.read(nationalFederationManagerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1200;
            final isTablet = width >= 720 && width < 1200;
            final horizontalPadding = width < 520 ? 12.0 : 20.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopHeader(
                  context: context,
                  state: state,
                  chemistry: chemistry,
                  notifier: notifier,
                  isCompact: width < 640,
                  horizontalPadding: horizontalPadding,
                ),
                if (state.statusBannerPl != null &&
                    state.statusBannerPl!.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      10,
                    ),
                    child: _StatusBannerStrip(
                      message: state.statusBannerPl!,
                      isLocked: state.isSelectionLocked,
                    ),
                  ),
                if (!isDesktop)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      10,
                    ),
                    child: _buildMobileTabBar(),
                  ),
                Expanded(
                  child: isDesktop
                      ? _buildDesktopCommandGrid(
                          state: state,
                          chemistry: chemistry,
                          notifier: notifier,
                          horizontalPadding: horizontalPadding,
                        )
                      : isTablet
                          ? _buildTabletLayout(
                              state: state,
                              chemistry: chemistry,
                              notifier: notifier,
                              horizontalPadding: horizontalPadding,
                            )
                          : _buildMobileLayout(
                              state: state,
                              chemistry: chemistry,
                              notifier: notifier,
                              horizontalPadding: horizontalPadding,
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopHeader({
    required BuildContext context,
    required NationalChampionshipCampaignState state,
    required NationalTeamChemistryReport chemistry,
    required NationalFederationTeamManagerNotifier notifier,
    required bool isCompact,
    required double horizontalPadding,
  }) {
    final startersCount = state.activeStarters.length;
    final maxStarters = state.activeMaxStarters;
    final reservesCount = state.reserves.length;
    final maxReserves = state.quota.maxReserves;

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isCompact ? 10 : 14,
        horizontalPadding,
        isCompact ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onBackPressed != null ||
                  Navigator.of(context).canPop()) ...[
                _HqIconActionButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Powrót',
                  isDisabled: false,
                  onTap: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const SizedBox(width: 10),
              ],
              _NationFlagBadge(nationCode: state.quota.nationCode),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Biuro Selekcjonera • ${state.quota.nationNamePl}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: isCompact ? 15 : 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (widget.isReadOnly) ...[
                          const SizedBox(width: 8),
                          const _PillTag(
                            label: 'PODGLĄD',
                            color: AppColors.amberWarning,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.eventType.displayNamePl} ${state.seasonYear} • '
                      '${state.courseProfile.displayNamePl} (${state.courseDistanceKm} km)',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                _HeaderKpiPill(
                  label: 'KWOTA',
                  value: '$startersCount/$maxStarters (+$reservesCount/$maxReserves)',
                  accentColor: startersCount == maxStarters
                      ? AppColors.statusSuccess
                      : AppColors.goldAccent,
                ),
                const SizedBox(width: 8),
                _HeaderKpiPill(
                  label: 'CHEMIA',
                  value: '${chemistry.cohesionScore.round()}%',
                  accentColor: chemistry.cohesionScore >= 75
                      ? AppColors.statusSuccess
                      : chemistry.cohesionScore >= 55
                          ? AppColors.amberWarning
                          : AppColors.crimsonAlert,
                ),
                const SizedBox(width: 8),
                _HeaderKpiPill(
                  label: 'BUDŻET',
                  value: _formatEur(state.quota.federationBudgetEur),
                  accentColor: AppColors.accentBlue,
                ),
              ],
            ],
          ),
          if (isCompact) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _HeaderKpiPill(
                  label: 'KWOTA',
                  value: '$startersCount/$maxStarters (+$reservesCount/$maxReserves)',
                  accentColor: startersCount == maxStarters
                      ? AppColors.statusSuccess
                      : AppColors.goldAccent,
                ),
                _HeaderKpiPill(
                  label: 'CHEMIA',
                  value: '${chemistry.cohesionScore.round()}%',
                  accentColor: chemistry.cohesionScore >= 75
                      ? AppColors.statusSuccess
                      : AppColors.amberWarning,
                ),
                _HeaderKpiPill(
                  label: 'BUDŻET',
                  value: _formatEur(state.quota.federationBudgetEur),
                  accentColor: AppColors.accentBlue,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: NationalTeamHqTab.values.map((tab) {
          final isSelected = _activeTab == tab;
          return Expanded(
            child: _HqTabPill(
              label: tab.labelPl,
              icon: tab.icon,
              isSelected: isSelected,
              onTap: () => setState(() => _activeTab = tab),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopCommandGrid({
    required NationalChampionshipCampaignState state,
    required NationalTeamChemistryReport chemistry,
    required NationalFederationTeamManagerNotifier notifier,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        14,
        horizontalPadding,
        16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: _buildFederationAndEventPanel(state, notifier),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: _buildCandidatePoolPanel(state, notifier, isScrollableList: true),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSelectedSquadAndChemistryPanel(
                    state,
                    chemistry,
                    notifier,
                  ),
                  const SizedBox(height: 14),
                  _buildSimulationAndHistoryPanel(state, chemistry, notifier),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout({
    required NationalChampionshipCampaignState state,
    required NationalTeamChemistryReport chemistry,
    required NationalFederationTeamManagerNotifier notifier,
    required double horizontalPadding,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        20,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        child: switch (_activeTab) {
          NationalTeamHqTab.callUpsAndPool => Row(
              key: const ValueKey('tablet_pool'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildCandidatePoolPanel(
                    state,
                    notifier,
                    isScrollableList: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 5,
                  child: _buildSelectedSquadAndChemistryPanel(
                    state,
                    chemistry,
                    notifier,
                  ),
                ),
              ],
            ),
          NationalTeamHqTab.tacticsAndChemistry => Row(
              key: const ValueKey('tablet_tactics'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSelectedSquadAndChemistryPanel(
                    state,
                    chemistry,
                    notifier,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSimulationAndHistoryPanel(
                    state,
                    chemistry,
                    notifier,
                  ),
                ),
              ],
            ),
          NationalTeamHqTab.federationAndHistory => Row(
              key: const ValueKey('tablet_federation'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFederationAndEventPanel(state, notifier),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSimulationAndHistoryPanel(
                    state,
                    chemistry,
                    notifier,
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }

  Widget _buildMobileLayout({
    required NationalChampionshipCampaignState state,
    required NationalTeamChemistryReport chemistry,
    required NationalFederationTeamManagerNotifier notifier,
    required double horizontalPadding,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        6,
        horizontalPadding,
        20,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        child: switch (_activeTab) {
          NationalTeamHqTab.callUpsAndPool => Column(
              key: const ValueKey('mobile_pool'),
              children: [
                _buildQuickActionBar(state, notifier),
                const SizedBox(height: 12),
                _buildCandidatePoolPanel(
                  state,
                  notifier,
                  isScrollableList: false,
                ),
              ],
            ),
          NationalTeamHqTab.tacticsAndChemistry => Column(
              key: const ValueKey('mobile_tactics'),
              children: [
                _buildSelectedSquadAndChemistryPanel(
                  state,
                  chemistry,
                  notifier,
                ),
              ],
            ),
          NationalTeamHqTab.federationAndHistory => Column(
              key: const ValueKey('mobile_federation'),
              children: [
                _buildFederationAndEventPanel(state, notifier),
                const SizedBox(height: 12),
                _buildSimulationAndHistoryPanel(state, chemistry, notifier),
              ],
            ),
        },
      ),
    );
  }

  Widget _buildQuickActionBar(
    NationalChampionshipCampaignState state,
    NationalFederationTeamManagerNotifier notifier,
  ) {
    final isLockedOrReadOnly = widget.isReadOnly || state.isSelectionLocked;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _HqPrimaryButton(
          label: 'Auto-Powołanie',
          icon: Icons.auto_awesome_rounded,
          accentColor: AppColors.goldAccent,
          isDisabled: isLockedOrReadOnly,
          onTap: notifier.autoSelectOptimalSquad,
        ),
        _HqPrimaryButton(
          label: state.isSelectionLocked ? 'Odblokuj Listę' : 'Zatwierdź Kadrę',
          icon: state.isSelectionLocked
              ? Icons.lock_open_rounded
              : Icons.lock_rounded,
          accentColor: state.isSelectionLocked
              ? AppColors.amberWarning
              : AppColors.primaryAccent,
          isDisabled: widget.isReadOnly,
          onTap: () => notifier.setSelectionLocked(!state.isSelectionLocked),
        ),
      ],
    );
  }

  Widget _buildFederationAndEventPanel(
    NationalChampionshipCampaignState state,
    NationalFederationTeamManagerNotifier notifier,
  ) {
    final presets = NationalFederationTeamManagerService.createSampleNationPresets();
    final isLockedOrReadOnly = widget.isReadOnly || state.isSelectionLocked;

    return _HqCard(
      title: 'Federacja, Impreza i Trasa',
      icon: Icons.public_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('WYBÓR REPREZENTACJI'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final isSelected =
                  preset.quota.nationCode == state.quota.nationCode;
              return _HqChoiceChip(
                label: '${preset.quota.nationCode} • ${preset.quota.nationNamePl}',
                isSelected: isSelected,
                isDisabled: widget.isReadOnly,
                onTap: () {
                  setState(() => _selectedCandidateId = null);
                  notifier.switchNationPreset(preset);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('RANGA MISTRZOSTW'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NationalChampionshipEventType.values.map((event) {
              return _HqChoiceChip(
                label: event.shortBadgePl,
                isSelected: state.eventType == event,
                isDisabled: isLockedOrReadOnly,
                onTap: () => notifier.switchEvent(event),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('PROFIL TRASY MISTRZOWSKIEJ'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: NationalTeamCourseProfile.values.map((profile) {
              return _HqChoiceChip(
                label: profile.displayNamePl,
                isSelected: state.courseProfile == profile,
                isDisabled: isLockedOrReadOnly || state.eventType.isTimeTrial,
                onTap: () => notifier.switchCourseProfile(profile),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${state.courseDistanceKm} km',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '+${state.elevationGainMeters} m przewyższenia',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _CourseElevationMiniPainter(
                      profile: state.courseProfile,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('MANDAT FEDERACJI & KWOTY UCI'),
          const SizedBox(height: 8),
          _StatGaugeBar(
            label: 'Zaufanie Federacji (${state.quota.nationCode})',
            value: state.federationTrust,
            maxValue: 100,
            color: state.federationTrust >= 65
                ? AppColors.statusSuccess
                : AppColors.amberWarning,
            valueSuffix: '%',
          ),
          const SizedBox(height: 10),
          _StatGaugeBar(
            label: 'Presja Mediów i Opinii',
            value: state.mediaPressure,
            maxValue: 100,
            color: state.mediaPressure >= 75
                ? AppColors.crimsonAlert
                : AppColors.accentBlue,
            valueSuffix: '%',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniInfoTile(
                  label: 'Ranking UCI',
                  value: '#${state.quota.uciNationRank}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfoTile(
                  label: 'Koszyk',
                  value: state.quota.quotaTier.displayNamePl.split(' ').first,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInfoTile(
                  label: 'Prestiż',
                  value: '${state.quota.federationPrestige.round()}/100',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatePoolPanel(
    NationalChampionshipCampaignState state,
    NationalFederationTeamManagerNotifier notifier, {
    required bool isScrollableList,
  }) {
    final filtered = _filteredAndSortedCandidates(state);
    final isLockedOrReadOnly = widget.isReadOnly || state.isSelectionLocked;

    final listContent = filtered.isEmpty
        ? _EmptyStateBox(
            icon: Icons.person_search_rounded,
            title: 'Brak kolarzy spełniających kryteria',
            subtitle:
                'Zmień frazę wyszukiwania lub zresetuj aktywny filtr puli narodowej.',
            actionLabel: 'Resetuj filtry',
            onAction: () {
              setState(() {
                _poolFilter = CandidatePoolFilter.all;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )
        : Column(
            children: filtered.map((candidate) {
              final selection = state.findSelection(candidate.riderId);
              final suitability = candidate.overallSelectionScore(
                state.eventType,
                state.courseProfile,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CandidateCallUpTile(
                  candidate: candidate,
                  selection: selection,
                  suitabilityScore: suitability,
                  isFocusedDetails: _selectedCandidateId == candidate.riderId,
                  isLockedOrReadOnly: isLockedOrReadOnly,
                  onInspect: () {
                    setState(() {
                      _selectedCandidateId =
                          _selectedCandidateId == candidate.riderId
                              ? null
                              : candidate.riderId;
                    });
                  },
                  onToggleCallUp: () =>
                      notifier.toggleRiderSelection(candidate.riderId),
                  onNegotiateRelease: () =>
                      notifier.resolveClubRelease(candidate.riderId),
                ),
              );
            }).toList(),
          );

    return _HqCard(
      title: 'Pula Kandydatów (${filtered.length}/${state.candidatePool.length})',
      icon: Icons.groups_rounded,
      headerTrailing: _HqPrimaryButton(
        label: 'Auto-Powołanie',
        icon: Icons.auto_awesome_rounded,
        accentColor: AppColors.goldAccent,
        isCompact: true,
        isDisabled: isLockedOrReadOnly,
        onTap: notifier.autoSelectOptimalSquad,
      ),
      expandChild: isScrollableList,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Szukaj nazwiska lub ekipy WorldTour...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.goldAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: CandidatePoolFilter.values.map((filter) {
              return _HqChoiceChip(
                label: filter.displayNamePl,
                isSelected: _poolFilter == filter,
                isDisabled: false,
                onTap: () => setState(() => _poolFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Sortuj:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: NationalCandidateSortBy.values.map((sort) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _HqChoiceChip(
                          label: sort.labelPl,
                          isSelected: _sortBy == sort,
                          isDisabled: false,
                          onTap: () => setState(() => _sortBy = sort),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isScrollableList)
            Expanded(
              child: SingleChildScrollView(
                child: listContent,
              ),
            )
          else
            listContent,
        ],
      ),
    );
  }

  Widget _buildSelectedSquadAndChemistryPanel(
    NationalChampionshipCampaignState state,
    NationalTeamChemistryReport chemistry,
    NationalFederationTeamManagerNotifier notifier,
  ) {
    final starters = state.activeStarters;
    final reserves = state.reserves;
    final isLockedOrReadOnly = widget.isReadOnly || state.isSelectionLocked;

    return _HqCard(
      title:
          'Powołana Kadra (${starters.length}/${state.activeMaxStarters} + ${reserves.length} rez.)',
      icon: Icons.shield_rounded,
      headerTrailing: _HqPrimaryButton(
        label: state.isSelectionLocked ? 'Odblokuj' : 'Zatwierdź',
        icon: state.isSelectionLocked
            ? Icons.lock_open_rounded
            : Icons.verified_rounded,
        accentColor: state.isSelectionLocked
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
        isCompact: true,
        isDisabled: widget.isReadOnly,
        onTap: () => notifier.setSelectionLocked(!state.isSelectionLocked),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatGaugeBar(
                  label: 'Spójność Szatni',
                  value: chemistry.cohesionScore,
                  maxValue: 100,
                  color: chemistry.cohesionScore >= 75
                      ? AppColors.statusSuccess
                      : chemistry.cohesionScore >= 55
                          ? AppColors.amberWarning
                          : AppColors.crimsonAlert,
                  valueSuffix: '%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatGaugeBar(
                  label: 'Balans Taktyczny',
                  value: chemistry.tacticalBalanceScore,
                  maxValue: 100,
                  color: AppColors.accentBlue,
                  valueSuffix: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PillTag(
                label: 'Konflikty Ego: ${chemistry.egoConflictCount}',
                color: chemistry.egoConflictCount == 0
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _PillTag(
                label: 'Klubowe: ${chemistry.tradeTeamConflictCount}',
                color: chemistry.tradeTeamConflictCount == 0
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _PillTag(
                label: 'Rywalizacje: ${chemistry.rivalryCount}',
                color: chemistry.rivalryCount == 0
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
            ],
          ),
          if (chemistry.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: chemistry.warnings
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $w',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (chemistry.strengths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.statusSuccess.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: chemistry.strengths
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '✓ $s',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const _SectionLabel('SKŁAD STARTOWY I ROLE TAKTYCZNE'),
          const SizedBox(height: 8),
          if (state.selectedSquad.isEmpty)
            _EmptyStateBox(
              icon: Icons.group_add_rounded,
              title: 'Brak powołanych kolarzy',
              subtitle:
                  'Wybierz zawodników z puli lub uruchom automatyczny dobór kadry.',
              actionLabel: 'Auto-Powołanie Optymalne',
              onAction: isLockedOrReadOnly ? null : notifier.autoSelectOptimalSquad,
            )
          else
            ...state.selectedSquad.map((entry) {
              final rider = state.findCandidate(entry.riderId);
              if (rider == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SquadAssignmentTile(
                  rider: rider,
                  entry: entry,
                  isLockedOrReadOnly: isLockedOrReadOnly,
                  onAssignRole: (role) =>
                      notifier.assignRiderRole(rider.riderId, role),
                  onRemove: () => notifier.toggleRiderSelection(rider.riderId),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSimulationAndHistoryPanel(
    NationalChampionshipCampaignState state,
    NationalTeamChemistryReport chemistry,
    NationalFederationTeamManagerNotifier notifier,
  ) {
    final last = state.lastSimulationResult;
    final canSimulate = !widget.isReadOnly && chemistry.isEligibleToStart;

    return _HqCard(
      title: 'Finał Mistrzostw & Archiwum',
      icon: Icons.emoji_events_rounded,
      headerTrailing: _HqPrimaryButton(
        label: 'Symuluj Finał',
        icon: Icons.play_arrow_rounded,
        accentColor: AppColors.primaryAccent,
        isCompact: true,
        isDisabled: !canSimulate,
        onTap: () => notifier.simulateChampionship(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!chemistry.isEligibleToStart)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.amberWarning.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'Aby wystartować w finale, rozwiąż konflikty klubowe i powołaj co najmniej 1 aktywnego startera.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          if (last == null)
            const _EmptyStateBox(
              icon: Icons.flag_rounded,
              title: 'Brak rozegranego finału',
              subtitle:
                  'Zatwierdź skład reprezentacji i uruchom symulację wyścigu o Tęczową Koszulkę lub medal olimpijski.',
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: last.medalWon == ChampionshipMedal.gold
                      ? AppColors.goldAccent
                      : _borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _PillTag(
                        label: last.medalWon == ChampionshipMedal.none
                            ? 'MIEJSCE #${last.bestFinishPosition}'
                            : last.medalWon.displayNamePl.toUpperCase(),
                        color: _medalColor(last.medalWon),
                      ),
                      const Spacer(),
                      Text(
                        '+${last.uciNationPointsEarned} pkt UCI',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    last.tacticalSummaryPl,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (last.rainbowJerseyWinnerName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Mistrz: ${last.rainbowJerseyWinnerName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ...last.riderPlacements.take(5).map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '#${p.finishPosition}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldAccent,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              p.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            p.timeGapSeconds == 0
                                ? '0:00'
                                : '+${_formatGap(p.timeGapSeconds)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          if (state.history.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _SectionLabel('HISTORIA WYSTĘPÓW KADRY'),
            const SizedBox(height: 8),
            ...state.history.take(4).map((h) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${h.seasonYear} • ${h.eventType.shortBadgePl}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '#${h.bestFinishPosition} (${h.medalWon.displayNamePl})',
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _medalColor(h.medalWon),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<NationalSelectionRiderCandidate> _filteredAndSortedCandidates(
    NationalChampionshipCampaignState state,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = state.candidatePool.where((c) {
      if (query.isNotEmpty) {
        final matchName = c.fullName.toLowerCase().contains(query);
        final matchTeam = c.tradeTeamName.toLowerCase().contains(query);
        if (!matchName && !matchTeam) return false;
      }
      switch (_poolFilter) {
        case CandidatePoolFilter.all:
          return true;
        case CandidatePoolFilter.selectedOnly:
          return state.findSelection(c.riderId) != null;
        case CandidatePoolFilter.conflictsOnly:
          return c.hasClubConflict || c.isInjured;
      }
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case NationalCandidateSortBy.suitabilityScore:
          return b
              .overallSelectionScore(state.eventType, state.courseProfile)
              .compareTo(
                a.overallSelectionScore(state.eventType, state.courseProfile),
              );
        case NationalCandidateSortBy.uciPoints:
          return b.seasonUciPoints.compareTo(a.seasonUciPoints);
        case NationalCandidateSortBy.currentForm:
          return b.currentFormScore.compareTo(a.currentFormScore);
        case NationalCandidateSortBy.age:
          return a.age.compareTo(b.age);
      }
    });

    return filtered;
  }

  static Color _medalColor(ChampionshipMedal medal) {
    switch (medal) {
      case ChampionshipMedal.gold:
        return AppColors.goldAccent;
      case ChampionshipMedal.silver:
        return const Color(0xFFD1D5DB);
      case ChampionshipMedal.bronze:
        return const Color(0xFFD97706);
      case ChampionshipMedal.none:
        return AppColors.accentBlue;
    }
  }

  static String _formatEur(double amount) {
    final k = (amount / 1000).round();
    return '€${k}k';
  }

  static String _formatGap(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

class _HqCard extends StatelessWidget {
  const _HqCard({
    required this.title,
    required this.icon,
    required this.child,
    this.headerTrailing,
    this.expandChild = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? headerTrailing;
  final bool expandChild;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (headerTrailing != null) ...[
                const SizedBox(width: 8),
                headerTrailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _StatusBannerStrip extends StatelessWidget {
  const _StatusBannerStrip({
    required this.message,
    required this.isLocked,
  });

  final String message;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final accent = isLocked ? AppColors.statusSuccess : AppColors.accentBlue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isLocked ? Icons.verified_rounded : Icons.info_outline_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderKpiPill extends StatelessWidget {
  const _HeaderKpiPill({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  const _MiniInfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGaugeBar extends StatelessWidget {
  const _StatGaugeBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.valueSuffix = '',
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${value.round()}$valueSuffix',
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
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _EmptyStateBox extends StatelessWidget {
  const _EmptyStateBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            _HqPrimaryButton(
              label: actionLabel!,
              icon: Icons.refresh_rounded,
              accentColor: AppColors.goldAccent,
              isCompact: true,
              isDisabled: false,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

class _CandidateCallUpTile extends StatefulWidget {
  const _CandidateCallUpTile({
    required this.candidate,
    required this.selection,
    required this.suitabilityScore,
    required this.isFocusedDetails,
    required this.isLockedOrReadOnly,
    required this.onInspect,
    required this.onToggleCallUp,
    required this.onNegotiateRelease,
  });

  final NationalSelectionRiderCandidate candidate;
  final NationalSquadSelectionEntry? selection;
  final double suitabilityScore;
  final bool isFocusedDetails;
  final bool isLockedOrReadOnly;
  final VoidCallback onInspect;
  final VoidCallback onToggleCallUp;
  final VoidCallback onNegotiateRelease;

  @override
  State<_CandidateCallUpTile> createState() => _CandidateCallUpTileState();
}

class _CandidateCallUpTileState extends State<_CandidateCallUpTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final isSelected = widget.selection != null;
    final borderColor = _isFocused
        ? AppColors.accentBlue
        : isSelected
            ? AppColors.goldAccent
            : _isHovered
                ? AppColors.primaryAccent
                : const Color(0xFF2A2F3D);

    return Focus(
      onFocusChange: (val) => setState(() => _isFocused = val),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.goldAccent.withValues(alpha: 0.08)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLight.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isSelected ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onInspect,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                c.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (c.isInjured)
                                const _PillTag(
                                  label: 'KONTUZJA',
                                  color: AppColors.crimsonAlert,
                                )
                              else if (c.hasClubConflict)
                                const _PillTag(
                                  label: 'WETO KLUBU',
                                  color: AppColors.amberWarning,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${c.tradeTeamName} • ${c.age} lat • ${c.seasonUciPoints} pkt UCI',
                            overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A2F3D)),
                    ),
                    child: Text(
                      '${widget.suitabilityScore.round()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: widget.suitabilityScore >= 82
                            ? AppColors.goldAccent
                            : AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HqPrimaryButton(
                    label: isSelected ? 'Odwołaj' : 'Powołaj',
                    icon: isSelected
                        ? Icons.remove_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    accentColor: isSelected
                        ? AppColors.crimsonAlert
                        : AppColors.statusSuccess,
                    isCompact: true,
                    isDisabled: widget.isLockedOrReadOnly || c.isInjured,
                    onTap: widget.onToggleCallUp,
                  ),
                ],
              ),
              if (c.hasClubConflict && !c.isInjured) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ekipa zawodowa wstrzymuje zwolnienie zawodnika.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.amberWarning,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HqPrimaryButton(
                      label: 'Negocjuj (€18k)',
                      icon: Icons.handshake_rounded,
                      accentColor: AppColors.amberWarning,
                      isCompact: true,
                      isDisabled: widget.isLockedOrReadOnly,
                      onTap: widget.onNegotiateRelease,
                    ),
                  ],
                ),
              ],
              if (widget.isFocusedDetails) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFF2A2F3D)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _PillTag(
                      label: 'GÓRY ${c.mountainRating.round()}',
                      color: AppColors.accentBlue,
                    ),
                    _PillTag(
                      label: 'PUNCH ${c.puncheurRating.round()}',
                      color: AppColors.goldAccent,
                    ),
                    _PillTag(
                      label: 'ITT ${c.timeTrialRating.round()}',
                      color: AppColors.cyanAccent,
                    ),
                    _PillTag(
                      label: 'SPR ${c.sprintRating.round()}',
                      color: AppColors.statusSuccess,
                    ),
                    _PillTag(
                      label: 'FORMA ${c.currentFormScore.round()}%',
                      color: AppColors.textPrimary,
                    ),
                    _PillTag(
                      label: 'EGO ${c.egoLevel.round()}',
                      color: c.egoLevel >= 75
                          ? AppColors.amberWarning
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SquadAssignmentTile extends StatelessWidget {
  const _SquadAssignmentTile({
    required this.rider,
    required this.entry,
    required this.isLockedOrReadOnly,
    required this.onAssignRole,
    required this.onRemove,
  });

  final NationalSelectionRiderCandidate rider;
  final NationalSquadSelectionEntry entry;
  final bool isLockedOrReadOnly;
  final ValueChanged<NationalRiderTacticalRole> onAssignRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.role.isLeadershipRole
              ? AppColors.goldAccent.withValues(alpha: 0.6)
              : const Color(0xFF2A2F3D),
        ),
      ),
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
                      rider.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${rider.tradeTeamName} • ${entry.isReserve ? "Rezerwa" : "Starter"}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.isIttStarter)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: _PillTag(label: 'ITT', color: AppColors.cyanAccent),
                ),
              _HqIconActionButton(
                icon: Icons.close_rounded,
                tooltip: 'Usuń z kadry',
                isDisabled: isLockedOrReadOnly,
                onTap: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: NationalRiderTacticalRole.values
                .where((r) => r != NationalRiderTacticalRole.reserveAlternate)
                .map((role) {
              return _HqChoiceChip(
                label: role.displayNamePl,
                isSelected: entry.role == role,
                isDisabled: isLockedOrReadOnly || entry.isReserve,
                onTap: () => onAssignRole(role),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HqTabPill extends StatefulWidget {
  const _HqTabPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_HqTabPill> createState() => _HqTabPillState();
}

class _HqTabPillState extends State<_HqTabPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryAccent
                : _hovered
                    ? AppColors.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
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

class _HqChoiceChip extends StatefulWidget {
  const _HqChoiceChip({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  State<_HqChoiceChip> createState() => _HqChoiceChipState();
}

class _HqChoiceChipState extends State<_HqChoiceChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: 0.18)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final border = widget.isDisabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : _focused
            ? AppColors.accentBlue
            : widget.isSelected
                ? AppColors.goldAccent
                : _hovered
                    ? AppColors.textSecondary
                    : const Color(0xFF2A2F3D);

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.isDisabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.5)
                    : widget.isSelected
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HqPrimaryButton extends StatefulWidget {
  const _HqPrimaryButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isDisabled,
    required this.onTap,
    this.isCompact = false,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isDisabled;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  State<_HqPrimaryButton> createState() => _HqPrimaryButtonState();
}

class _HqPrimaryButtonState extends State<_HqPrimaryButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? widget.accentColor.withValues(alpha: 0.85)
            : _hovered
                ? widget.accentColor.withValues(alpha: 0.28)
                : widget.accentColor.withValues(alpha: 0.16);
    final border = widget.isDisabled
        ? const Color(0xFF2A2F3D)
        : _focused
            ? AppColors.accentBlue
            : widget.accentColor.withValues(alpha: 0.7);

    return Focus(
      onFocusChange: (val) => setState(() => _focused = val),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown:
              widget.isDisabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: widget.isDisabled
              ? null
              : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 10 : 14,
              vertical: widget.isCompact ? 6 : 9,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: widget.isCompact ? 14 : 16,
                  color: widget.isDisabled
                      ? AppColors.textSecondary.withValues(alpha: 0.45)
                      : widget.accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.isCompact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: widget.isDisabled
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
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

class _HqIconActionButton extends StatefulWidget {
  const _HqIconActionButton({
    required this.icon,
    required this.tooltip,
    required this.isDisabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  State<_HqIconActionButton> createState() => _HqIconActionButtonState();
}

class _HqIconActionButtonState extends State<_HqIconActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Focus(
        onFocusChange: (val) => setState(() => _focused = val),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            onTap: widget.isDisabled ? null : widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _hovered ? AppColors.surfaceLight : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _focused
                      ? AppColors.accentBlue
                      : const Color(0xFF2A2F3D),
                ),
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: widget.isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NationFlagBadge extends StatelessWidget {
  const _NationFlagBadge({required this.nationCode});

  final String nationCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _NationalFlagCrestPainter(nationCode: nationCode),
      ),
    );
  }
}

class _NationalFlagCrestPainter extends CustomPainter {
  const _NationalFlagCrestPainter({required this.nationCode});

  final String nationCode;

  @override
  void paint(Canvas canvas, Size size) {
    final code = nationCode.toUpperCase();
    final paint = Paint();
    if (code == 'POL') {
      paint.color = const Color(0xFFF3F4F6);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height / 2), paint);
      paint.color = const Color(0xFFDC2626);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
        paint,
      );
    } else if (code == 'BEL') {
      final third = size.width / 3;
      paint.color = const Color(0xFF111827);
      canvas.drawRect(Rect.fromLTWH(0, 0, third, size.height), paint);
      paint.color = const Color(0xFFFACC15);
      canvas.drawRect(Rect.fromLTWH(third, 0, third, size.height), paint);
      paint.color = const Color(0xFFEF4444);
      canvas.drawRect(Rect.fromLTWH(third * 2, 0, third, size.height), paint);
    } else {
      final thirdH = size.height / 3;
      paint.color = const Color(0xFFF3F4F6);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, thirdH), paint);
      paint.color = const Color(0xFF2563EB);
      canvas.drawRect(Rect.fromLTWH(0, thirdH, size.width, thirdH), paint);
      paint.color = const Color(0xFFDC2626);
      canvas.drawRect(
        Rect.fromLTWH(0, thirdH * 2, size.width, thirdH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NationalFlagCrestPainter oldDelegate) =>
      oldDelegate.nationCode != nationCode;
}

class _CourseElevationMiniPainter extends CustomPainter {
  const _CourseElevationMiniPainter({required this.profile});

  final NationalTeamCourseProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    const samples = 24;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final x = t * size.width;
      final double yNorm;
      switch (profile) {
        case NationalTeamCourseProfile.flatSprinters:
          yNorm = 0.78 - 0.12 * math.sin(t * math.pi * 4);
          break;
        case NationalTeamCourseProfile.puncheurClassics:
          yNorm = 0.72 -
              0.24 * math.pow(math.sin(t * math.pi * 3.5).abs(), 1.4) -
              0.15 * t;
          break;
        case NationalTeamCourseProfile.alpineMountain:
          yNorm = 0.85 -
              0.38 * math.sin(t * math.pi * 2.2).abs() -
              0.32 * math.pow(t, 1.3);
          break;
        case NationalTeamCourseProfile.technicalTimeTrial:
          yNorm = 0.68 - 0.18 * math.sin(t * math.pi * 2);
          break;
      }
      points.add(Offset(x, (yNorm.clamp(0.12, 0.92)) * size.height));
    }

    final fillPath = Path()..moveTo(0, size.height);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.35),
          AppColors.goldAccent.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      strokePath.lineTo(points[i].dx, points[i].dy);
    }
    final strokePaint = Paint()
      ..color = AppColors.goldAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CourseElevationMiniPainter oldDelegate) =>
      oldDelegate.profile != profile;
}
