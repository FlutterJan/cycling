import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/end_of_career_hall_of_fame_retirement_mode.dart';

/// Zakładki widoku Księgi Legendy Menedżera.
enum _BookViewMode {
  chronicleBook('Księga Legendy'),
  dynastyHall('Panteon i Dynastia NG+');

  const _BookViewMode(this.label);
  final String label;
}

/// Kryterium sortowania wpisów w Księdze Legendy.
enum _BookSortOrder {
  byGenerationDesc('Pokolenie (najnowsze)'),
  byScoreDesc('Punkty dziedzictwa (malejąco)'),
  byYearDesc('Rok zakończenia (malejąco)');

  const _BookSortOrder(this.label);
  final String label;
}

/// Ekran Księgi Legendy Menedżera ze złotymi tłoczeniami `#D4AF37`.
///
/// Prezentuje archiwum historycznych dokonań menedżera i jego dynastii
/// w formie luksusowej, skórzano-złotej księgi z tłoczonymi ornamentami,
/// rozkładówką dwustronicową na desktopie/tablecie oraz nawigacją po stronach
/// na urządzeniach mobilnych (`390x844`, `1024x768`, `1600x900`).
class ManagerLegacyHallOfFameBookScreen extends ConsumerStatefulWidget {
  const ManagerLegacyHallOfFameBookScreen({
    super.key,
    this.onStartNewGamePlus,
    this.initialEntryId,
  });

  /// Callback wywoływany po rozpoczęciu nowej kariery w trybie Dynastia NG+.
  final ValueChanged<DynastyInheritanceBundle>? onStartNewGamePlus;

  /// Opcjonalny identyfikator wpisu, który ma zostać otwarty przy starcie.
  final String? initialEntryId;

  @override
  ConsumerState<ManagerLegacyHallOfFameBookScreen> createState() =>
      _ManagerLegacyHallOfFameBookScreenState();
}

class _ManagerLegacyHallOfFameBookScreenState
    extends ConsumerState<ManagerLegacyHallOfFameBookScreen>
    with SingleTickerProviderStateMixin {
  _BookViewMode _viewMode = _BookViewMode.chronicleBook;
  _BookSortOrder _sortOrder = _BookSortOrder.byGenerationDesc;
  HallOfFameTier? _tierFilter;
  String _searchQuery = '';
  int _selectedPageIndex = 0;
  int _mobileSpreadSide = 0; // 0 = Lewa strona (Pieczęć i Punkty), 1 = Prawa (Palmares i Tablice)
  bool _includeLivePreview = true;

  late final TextEditingController _searchController;
  late final AnimationController _foilSheenController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _foilSheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _foilSheenController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _foilSheenController.dispose();
    super.dispose();
  }

  List<HallOfFameInductionEntry> _buildBookEntries(
    EndOfCareerRetirementState state,
    HallOfFameInductionEntry livePreview,
  ) {
    final combined = <HallOfFameInductionEntry>[
      if (_includeLivePreview) livePreview,
      ...state.archive.entries,
    ];

    final filtered = combined.where((entry) {
      if (_tierFilter != null && entry.tier != _tierFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesName =
            entry.palmares.managerName.toLowerCase().contains(q);
        final matchesDynasty =
            entry.palmares.dynastyName.toLowerCase().contains(q);
        final matchesTeam =
            entry.palmares.primaryTeamName.toLowerCase().contains(q);
        if (!matchesName && !matchesDynasty && !matchesTeam) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOrder) {
        case _BookSortOrder.byGenerationDesc:
          final genCmp = b.palmares.generationNumber
              .compareTo(a.palmares.generationNumber);
          if (genCmp != 0) return genCmp;
          return b.finalScore.compareTo(a.finalScore);
        case _BookSortOrder.byScoreDesc:
          return b.finalScore.compareTo(a.finalScore);
        case _BookSortOrder.byYearDesc:
          return b.palmares.endSeasonYear
              .compareTo(a.palmares.endSeasonYear);
      }
    });

    return filtered;
  }

  void _selectInitialEntryIfNeeded(List<HallOfFameInductionEntry> entries) {
    final targetId = widget.initialEntryId;
    if (targetId == null || entries.isEmpty) return;
    final idx = entries.indexWhere((e) => e.inductionId == targetId);
    if (idx >= 0 && idx != _selectedPageIndex) {
      _selectedPageIndex = idx;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(endOfCareerRetirementProvider);
    final notifier = ref.read(endOfCareerRetirementProvider.notifier);
    final livePreview = notifier.previewInduction();
    final entries = _buildBookEntries(state, livePreview);

    if (widget.initialEntryId != null && _selectedPageIndex == 0) {
      _selectInitialEntryIfNeeded(entries);
    }

    final safeIndex = entries.isEmpty
        ? 0
        : _selectedPageIndex.clamp(0, entries.length - 1);
    final activeEntry = entries.isNotEmpty ? entries[safeIndex] : null;
    final isLiveEntry = activeEntry != null &&
        activeEntry.inductionId == livePreview.inductionId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, state.archive),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 640;
          final isTablet = width >= 640 && width < 1100;
          final horizontalPadding = isMobile ? 12.0 : (isTablet ? 20.0 : 28.0);

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 12 : 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGoldEmbossedHeroBanner(
                        state: state,
                        entriesCount: state.archive.entries.length,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 16),
                      _buildViewModeSwitcher(isMobile: isMobile),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: _viewMode == _BookViewMode.chronicleBook
                            ? _buildChronicleBookView(
                                key: const ValueKey('book_chronicle'),
                                state: state,
                                entries: entries,
                                activeEntry: activeEntry,
                                activeIndex: safeIndex,
                                isLiveEntry: isLiveEntry,
                                isMobile: isMobile,
                                isTablet: isTablet,
                              )
                            : EndOfCareerHallOfFameRetirementPanel(
                                key: const ValueKey('book_dynasty_panel'),
                                onStartNewGamePlus: widget.onStartNewGamePlus,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    HallOfFameArchive archive,
  ) {
    return AppBar(
      backgroundColor: AppColors.background,
      titleSpacing: 12,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.goldAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Księga Legendy Menedżera',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Złote Kroniki Hall of Fame • Dynastia WorldTour',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.goldAccent,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.goldAccent,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rekord: ${archive.highestScore} pkt',
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
          ),
        ),
      ],
    );
  }

  Widget _buildGoldEmbossedHeroBanner({
    required EndOfCareerRetirementState state,
    required int entriesCount,
    required bool isMobile,
  }) {
    final palmares = state.currentPalmares;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _foilSheenController,
        curve: Curves.easeOutCubic,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1712),
              AppColors.surface,
              Color(0xFF1E1A13),
            ],
          ),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldAccent.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CustomPaint(
          painter: const _GoldEmbossedFiligreePainter(
            foilColor: AppColors.goldAccent,
            cornerRadius: 16,
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroTitleBlock(palmares, isMobile: true),
                      const SizedBox(height: 14),
                      _buildHeroMetricsRow(state, entriesCount, isMobile: true),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildHeroTitleBlock(palmares, isMobile: false),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _buildHeroMetricsRow(
                          state,
                          entriesCount,
                          isMobile: false,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroTitleBlock(
    ManagerCareerPalmaresSummary palmares, {
    required bool isMobile,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 48 : 58,
          height: isMobile ? 48 : 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.goldAccent.withValues(alpha: 0.35),
                AppColors.goldAccent.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: AppColors.goldAccent,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: AppColors.goldAccent,
            size: isMobile ? 24 : 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                palmares.dynastyName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.goldAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Złota Księga Legendy Kolarskiej',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tłoczona kronika dyrektorów sportowych, zwycięstw w Wielkich Tourach oraz dziedzictwa pokoleń.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 12 : 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetricsRow(
    EndOfCareerRetirementState state,
    int entriesCount, {
    required bool isMobile,
  }) {
    final archive = state.archive;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
      children: [
        _GoldMetricTile(
          label: 'Pokolenie',
          value: '#${state.currentPalmares.generationNumber}',
          icon: Icons.account_tree_rounded,
        ),
        _GoldMetricTile(
          label: 'Legendy w Księdze',
          value: '$entriesCount',
          icon: Icons.verified_rounded,
        ),
        _GoldMetricTile(
          label: 'Suma GT Dynastii',
          value:
              '${archive.entries.fold<int>(0, (sum, e) => sum + e.palmares.grandTourWins) + state.currentPalmares.grandTourWins}',
          icon: Icons.emoji_events_rounded,
        ),
      ],
    );
  }

  Widget _buildViewModeSwitcher({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: _BookViewMode.values.map((mode) {
          final isSelected = _viewMode == mode;
          return Expanded(
            child: _InteractiveGoldButton(
              onPressed: () {
                setState(() {
                  _viewMode = mode;
                });
              },
              isSelected: isSelected,
              borderRadius: 12,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: 11,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode == _BookViewMode.chronicleBook
                        ? Icons.auto_stories_rounded
                        : Icons.shield_rounded,
                    size: 17,
                    color: isSelected
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      mode.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 12 : 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChronicleBookView({
    required Key key,
    required EndOfCareerRetirementState state,
    required List<HallOfFameInductionEntry> entries,
    required HallOfFameInductionEntry? activeEntry,
    required int activeIndex,
    required bool isLiveEntry,
    required bool isMobile,
    required bool isTablet,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilterAndSearchBar(isMobile: isMobile),
        const SizedBox(height: 16),
        if (entries.isEmpty || activeEntry == null)
          _buildEmptyBookState()
        else ...[
          _buildPageSelectorStrip(
            entries: entries,
            activeIndex: activeIndex,
            liveId: ref
                .read(endOfCareerRetirementProvider.notifier)
                .previewInduction()
                .inductionId,
          ),
          const SizedBox(height: 16),
          _buildLeatherBoundBookSpread(
            entry: activeEntry,
            entryIndex: activeIndex,
            totalEntries: entries.length,
            isLiveEntry: isLiveEntry,
            isMobile: isMobile,
            isTablet: isTablet,
          ),
        ],
      ],
    );
  }

  Widget _buildFilterAndSearchBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            _buildSearchField(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildSortDropdown()),
                const SizedBox(width: 8),
                _buildLivePreviewToggle(),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: _buildSearchField()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _buildSortDropdown()),
                const SizedBox(width: 12),
                _buildLivePreviewToggle(),
              ],
            ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTierFilterChip(
                  label: 'Wszystkie Rangi',
                  tier: null,
                ),
                const SizedBox(width: 8),
                ...HallOfFameTier.values.map(
                  (tier) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTierFilterChip(
                      label: tier.label,
                      tier: tier,
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _selectedPageIndex = 0;
        });
      },
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Szukaj menedżera, dynastii lub zespołu...',
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.goldAccent,
          size: 18,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Wyczyść wyszukiwanie',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedPageIndex = 0;
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_BookSortOrder>(
          value: _sortOrder,
          isExpanded: true,
          dropdownColor: AppColors.surfaceLight,
          iconEnabledColor: AppColors.goldAccent,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          items: _BookSortOrder.values.map((order) {
            return DropdownMenuItem<_BookSortOrder>(
              value: order,
              child: Text(
                order.label,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (next) {
            if (next == null) return;
            setState(() {
              _sortOrder = next;
              _selectedPageIndex = 0;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLivePreviewToggle() {
    return _InteractiveGoldButton(
      onPressed: () {
        setState(() {
          _includeLivePreview = !_includeLivePreview;
          _selectedPageIndex = 0;
        });
      },
      isSelected: _includeLivePreview,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _includeLivePreview
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            size: 16,
            color: _includeLivePreview
                ? AppColors.goldAccent
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Bieżąca kariera',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _includeLivePreview
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierFilterChip({
    required String label,
    required HallOfFameTier? tier,
  }) {
    final isSelected = _tierFilter == tier;
    final accent = tier?.accentColor ?? AppColors.goldAccent;

    return _InteractiveGoldButton(
      onPressed: () {
        setState(() {
          _tierFilter = tier;
          _selectedPageIndex = 0;
        });
      },
      isSelected: isSelected,
      accentColor: accent,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tier != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSelectorStrip({
    required List<HallOfFameInductionEntry> entries,
    required int activeIndex,
    required String liveId,
  }) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isSelected = index == activeIndex;
          final isLive = entry.inductionId == liveId;
          return _InteractiveGoldButton(
            onPressed: () {
              setState(() {
                _selectedPageIndex = index;
              });
            },
            isSelected: isSelected,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldAccent.withValues(alpha: 0.22)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldAccent
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(
                    isLive
                        ? 'LIVE'
                        : 'POKOL. #${entry.palmares.generationNumber}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.palmares.managerName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${entry.finalScore} pkt • ${entry.palmares.startSeasonYear}–${entry.palmares.endSeasonYear}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeatherBoundBookSpread({
    required HallOfFameInductionEntry entry,
    required int entryIndex,
    required int totalEntries,
    required bool isLiveEntry,
    required bool isMobile,
    required bool isTablet,
  }) {
    final canGoPrev = entryIndex > 0;
    final canGoNext = entryIndex < totalEntries - 1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1F1914),
            Color(0xFF15171D),
          ],
        ),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.09),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _GoldEmbossedFiligreePainter(
          foilColor: AppColors.goldAccent,
          cornerRadius: 20,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBookSpreadTopControls(
                entry: entry,
                entryIndex: entryIndex,
                totalEntries: totalEntries,
                isLiveEntry: isLiveEntry,
                canGoPrev: canGoPrev,
                canGoNext: canGoNext,
                isMobile: isMobile,
              ),
              const SizedBox(height: 16),
              if (isMobile) ...[
                _buildMobilePageSideToggle(),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _mobileSpreadSide == 0
                      ? _buildLeftChroniclePage(
                          key: ValueKey('left_${entry.inductionId}'),
                          entry: entry,
                          isLiveEntry: isLiveEntry,
                          isCompact: true,
                        )
                      : _buildRightPalmaresPage(
                          key: ValueKey('right_${entry.inductionId}'),
                          entry: entry,
                          isCompact: true,
                        ),
                ),
              ] else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: IntrinsicHeight(
                    key: ValueKey('spread_${entry.inductionId}'),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildLeftChroniclePage(
                            entry: entry,
                            isLiveEntry: isLiveEntry,
                            isCompact: isTablet,
                          ),
                        ),
                        _buildBookSpineDivider(),
                        Expanded(
                          child: _buildRightPalmaresPage(
                            entry: entry,
                            isCompact: isTablet,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookSpreadTopControls({
    required HallOfFameInductionEntry entry,
    required int entryIndex,
    required int totalEntries,
    required bool isLiveEntry,
    required bool canGoPrev,
    required bool canGoNext,
    required bool isMobile,
  }) {
    return Row(
      children: [
        _InteractiveGoldButton(
          onPressed: canGoPrev
              ? () {
                  setState(() {
                    _selectedPageIndex = entryIndex - 1;
                  });
                }
              : null,
          isDisabled: !canGoPrev,
          borderRadius: 10,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 14,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: canGoPrev
                    ? AppColors.goldAccent
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 4),
                Text(
                  'Poprzednia strona',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: canGoPrev
                        ? AppColors.goldAccent
                        : AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Text(
                'ROZDZIAŁ ${entryIndex + 1} Z $totalEntries',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLiveEntry
                    ? 'Aktywna Kariera • Wersja Robocza Złotego Wpisu'
                    : 'Zarchiwizowany Wpis Panteonu',
                textAlign: TextAlign.center,
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
        const SizedBox(width: 8),
        _InteractiveGoldButton(
          onPressed: canGoNext
              ? () {
                  setState(() {
                    _selectedPageIndex = entryIndex + 1;
                  });
                }
              : null,
          isDisabled: !canGoNext,
          borderRadius: 10,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 14,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                Text(
                  'Następna strona',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: canGoNext
                        ? AppColors.goldAccent
                        : AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: canGoNext
                    ? AppColors.goldAccent
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePageSideToggle() {
    return Row(
      children: [
        Expanded(
          child: _InteractiveGoldButton(
            onPressed: () => setState(() => _mobileSpreadSide = 0),
            isSelected: _mobileSpreadSide == 0,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Center(
              child: Text(
                'Strona I: Pieczęć i Wynik',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _mobileSpreadSide == 0
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InteractiveGoldButton(
            onPressed: () => setState(() => _mobileSpreadSide = 1),
            isSelected: _mobileSpreadSide == 1,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Center(
              child: Text(
                'Strona II: Palmares i Tablice',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _mobileSpreadSide == 1
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookSpineDivider() {
    return Container(
      width: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.goldAccent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.goldAccent.withValues(alpha: 0.65),
                    AppColors.goldAccent.withValues(alpha: 0.15),
                    AppColors.goldAccent.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.goldAccent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftChroniclePage({
    Key? key,
    required HallOfFameInductionEntry entry,
    required bool isLiveEntry,
    required bool isCompact,
  }) {
    final palmares = entry.palmares;
    final breakdown = entry.scoreBreakdown;
    final tier = entry.tier;

    return Container(
      key: key,
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _GoldEmbossedSealBadge(
                tier: tier,
                generationNumber: palmares.generationNumber,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: tier.accentColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tier.accentColor.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            tier.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: tier.accentColor,
                            ),
                          ),
                        ),
                        if (isLiveEntry)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.statusSuccess.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.statusSuccess
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: const Text(
                              'AKTYWNY',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusSuccess,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      palmares.managerName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isCompact ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${palmares.nationalityCode} • ${palmares.dynastyName} • ${palmares.startSeasonYear}–${palmares.endSeasonYear} (${palmares.seasonsManaged} sez.)',
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
          const SizedBox(height: 16),
          // Złote tłoczone epitafium
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1914),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.goldAccent,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'INSKRYPCJA W ZŁOCIE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.epitaphQuote.isNotEmpty
                      ? '„${entry.epitaphQuote}”'
                      : '„Zbudował kolarską potęgę zapisaną złotymi zgłoskami w historii peletonu.”',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Powód zamknięcia rozdziału: ${entry.reason.label}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Główny wynik Legacy Score
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'PUNKTY DZIEDZICTWA (LEGACY SCORE)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${breakdown.finalScore} pkt',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ScoreBreakdownBar(
                  label: 'Wielkie Toury',
                  points: breakdown.grandTourPoints,
                  maxReference: 6000,
                ),
                const SizedBox(height: 8),
                _ScoreBreakdownBar(
                  label: 'Monumenty i MŚ/IO',
                  points: breakdown.monumentPoints + breakdown.championshipPoints,
                  maxReference: 5000,
                ),
                const SizedBox(height: 8),
                _ScoreBreakdownBar(
                  label: 'Dominacja UCI i Etapy',
                  points: breakdown.stageWinPoints +
                      breakdown.longevityAndRankingPoints,
                  maxReference: 3500,
                ),
                const SizedBox(height: 8),
                _ScoreBreakdownBar(
                  label: 'Akademia, Finanse i Odznaczenia',
                  points: breakdown.academyAndFinancialPoints +
                      breakdown.plaqueBonusPoints,
                  maxReference: 2500,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mnożnik Dynastii NG+',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'x${breakdown.dynastyMultiplier.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentBlue,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPalmaresPage({
    Key? key,
    required HallOfFameInductionEntry entry,
    required bool isCompact,
  }) {
    final palmares = entry.palmares;
    final plaques = entry.plaques;

    return Container(
      key: key,
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'PALMARES HISTORYCZNE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PalmaresStatCard(
                label: 'Wielkie Toury',
                value: '${palmares.grandTourWins}',
                icon: Icons.emoji_events_rounded,
                highlightGold: palmares.grandTourWins > 0,
              ),
              _PalmaresStatCard(
                label: 'Monumenty',
                value: '${palmares.monumentWins}',
                icon: Icons.military_tech_rounded,
                highlightGold: palmares.monumentWins > 0,
              ),
              _PalmaresStatCard(
                label: 'Tytuły MŚ / IO',
                value: '${palmares.worldAndOlympicTitles}',
                icon: Icons.public_rounded,
                highlightGold: palmares.worldAndOlympicTitles > 0,
              ),
              _PalmaresStatCard(
                label: 'Wygrane Etapy',
                value: '${palmares.totalStageWins}',
                icon: Icons.flag_rounded,
                highlightGold: false,
              ),
              _PalmaresStatCard(
                label: 'Lata #1 UCI',
                value: '${palmares.uciTeamNumberOneYears}',
                icon: Icons.leaderboard_rounded,
                highlightGold: palmares.uciTeamNumberOneYears > 0,
              ),
              _PalmaresStatCard(
                label: 'Szczytowy Budżet',
                value: Formatters.formatCurrency(palmares.peakTeamBudgetEur),
                icon: Icons.account_balance_rounded,
                highlightGold: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROWADZONE EKIPY WORLDTOUR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: palmares.teamsManaged.map((team) {
                    final isPrimary = team == palmares.primaryTeamName;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? AppColors.goldAccent.withValues(alpha: 0.14)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPrimary
                              ? AppColors.goldAccent.withValues(alpha: 0.65)
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Text(
                        team,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight:
                              isPrimary ? FontWeight.w700 : FontWeight.w500,
                          color: isPrimary
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.goldAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ZŁOTE TABLICE CHWAŁY',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ],
              ),
              Text(
                '${plaques.length} odznaczeń',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (plaques.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Text(
                'Brak wygrawerowanych tablic chwały dla tego wpisu. Wygrywaj Wielkie Toury, Monumenty i promuj talenty z Akademii, aby odblokować złote tłoczenia.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              children: plaques
                  .map(
                    (plaque) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _GoldPlaqueTile(plaque: plaque),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBookState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            size: 42,
            color: AppColors.goldAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Brak wpisów spełniających wybrane kryteria',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Zmień filtry rangi, wyczyść wyszukiwanie lub włącz podgląd bieżącej kariery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _InteractiveGoldButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _tierFilter = null;
                _includeLivePreview = true;
                _selectedPageIndex = 0;
              });
            },
            isSelected: true,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Text(
              'Przywróć domyślny widok Księgi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interaktywny przycisk ze złotym tłoczeniem obsługujący hover / active / focus / disabled.
class _InteractiveGoldButton extends StatefulWidget {
  const _InteractiveGoldButton({
    required this.onPressed,
    required this.child,
    this.isSelected = false,
    this.isDisabled = false,
    this.accentColor = AppColors.goldAccent,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<_InteractiveGoldButton> createState() => _InteractiveGoldButtonState();
}

class _InteractiveGoldButtonState extends State<_InteractiveGoldButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isDisabled || widget.onPressed == null;
    final bgColor = disabled
        ? AppColors.surface.withValues(alpha: 0.45)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _isPressed ? 0.24 : 0.16)
            : _isPressed
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.85)
                    : AppColors.surface;

    final borderColor = disabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : (_isFocused || widget.isSelected)
            ? widget.accentColor
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.55)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: !disabled,
      onShowFocusHighlight: (focused) {
        setState(() => _isFocused = focused);
      },
      child: MouseRegion(
        cursor:
            disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) {
          if (!disabled) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTapDown: (_) {
            if (!disabled) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (_isPressed) setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (_isPressed) setState(() => _isPressed = false);
          },
          onTap: disabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _GoldMetricTile extends StatelessWidget {
  const _GoldMetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.goldAccent, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldEmbossedSealBadge extends StatelessWidget {
  const _GoldEmbossedSealBadge({
    required this.tier,
    required this.generationNumber,
  });

  final HallOfFameTier tier;
  final int generationNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            tier.accentColor.withValues(alpha: 0.28),
            AppColors.background,
          ],
        ),
        border: Border.all(color: tier.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: tier.accentColor.withValues(alpha: 0.22),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: tier.accentColor,
            size: 24,
          ),
          Text(
            'GEN $generationNumber',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: tier.accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdownBar extends StatelessWidget {
  const _ScoreBreakdownBar({
    required this.label,
    required this.points,
    required this.maxReference,
  });

  final String label;
  final int points;
  final int maxReference;

  @override
  Widget build(BuildContext context) {
    final ratio = math.min(1.0, math.max(0.0, points / maxReference));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '$points pkt',
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
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.goldAccent,
            ),
          ),
        ),
      ],
    );
  }
}

class _PalmaresStatCard extends StatelessWidget {
  const _PalmaresStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.highlightGold,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlightGold;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightGold
              ? AppColors.goldAccent.withValues(alpha: 0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                highlightGold ? AppColors.goldAccent : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: highlightGold
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldPlaqueTile extends StatefulWidget {
  const _GoldPlaqueTile({required this.plaque});

  final HallOfFamePlaque plaque;

  @override
  State<_GoldPlaqueTile> createState() => _GoldPlaqueTileState();
}

class _GoldPlaqueTileState extends State<_GoldPlaqueTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final plaque = widget.plaque;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFF241F16)
              : const Color(0xFF1B1914),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.goldAccent.withValues(
              alpha: _hovered ? 0.85 : 0.45,
            ),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plaque.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (plaque.subtitle.isNotEmpty)
                    Text(
                      plaque.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${plaque.bonusPoints} pkt',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rysuje narożne złote tłoczenia (filigran) i podwójną złotą obwódkę Księgi Legendy.
class _GoldEmbossedFiligreePainter extends CustomPainter {
  const _GoldEmbossedFiligreePainter({
    required this.foilColor,
    required this.cornerRadius,
  });

  final Color foilColor;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final innerPaint = Paint()
      ..color = foilColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cornerPaint = Paint()
      ..color = foilColor.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    const inset = 6.0;
    if (size.width > inset * 2 && size.height > inset * 2) {
      final innerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          inset,
          size.width - inset * 2,
          size.height - inset * 2,
        ),
        Radius.circular(math.max(4, cornerRadius - 4)),
      );
      canvas.drawRRect(innerRect, innerPaint);
    }

    const ornamentLen = 16.0;
    const margin = 10.0;

    // Lewy górny narożnik
    canvas.drawLine(
      const Offset(margin, margin + ornamentLen),
      const Offset(margin, margin),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin + ornamentLen, margin),
      cornerPaint,
    );

    // Prawy górny narożnik
    canvas.drawLine(
      Offset(size.width - margin - ornamentLen, margin),
      Offset(size.width - margin, margin),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + ornamentLen),
      cornerPaint,
    );

    // Lewy dolny narożnik
    canvas.drawLine(
      Offset(margin, size.height - margin - ornamentLen),
      Offset(margin, size.height - margin),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + ornamentLen, size.height - margin),
      cornerPaint,
    );

    // Prawy dolny narożnik
    canvas.drawLine(
      Offset(size.width - margin - ornamentLen, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin - ornamentLen),
      Offset(size.width - margin, size.height - margin),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldEmbossedFiligreePainter oldDelegate) {
    return oldDelegate.foilColor != foilColor ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
