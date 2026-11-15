import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/rider/rider.dart';

/// Tryb prezentacji tabeli ProCyclingStats (PCS).
enum PcsTableMode {
  /// Wyniki etapu lub klasyfikacji generalnej (Rnk, Kolarz, Drużyna, Wiek, Spec., Czas/Strata, Pkt).
  results,

  /// Lista startowa przed wyścigiem (Nr, Kolarz, Drużyna, Wiek, Spec., Forma/OVR, Pkt).
  startlist,

  /// Statystyki sezonowe lub historyczne kolarzy (Rnk, Kolarz, Drużyna, Wiek, Spec., Wyniki, Pkt).
  statistics,
}

/// Kolumna używana do sortowania tabeli [ProCyclingStatsTableWidget].
enum PcsSortColumn {
  rank,
  nationality,
  name,
  team,
  age,
  specialization,
  time,
  points,
  secondaryMetric,
}

/// Cztery główne specjalizacje kolarskie wraz z kodem kolorystycznym PCS.
///
/// - `sprint`: zielony (`#10B981`)
/// - `climber`: czerwony (`#EF4444`)
/// - `timeTrial`: niebieski (`#38BDF8`)
/// - `cobbles`: pomarańczowy (`#F97316`)
/// - `allRounder`: neutralny bursztynowy (`#F59E0B`)
enum PcsSpecializationCategory {
  sprint,
  climber,
  timeTrial,
  cobbles,
  allRounder;

  /// Kolor znacznika punktowego specjalizacji zgodny ze specyfikacją PCS.
  Color get dotColor {
    switch (this) {
      case PcsSpecializationCategory.sprint:
        return AppColors.statusSuccess; // Zielony (#10B981)
      case PcsSpecializationCategory.climber:
        return AppColors.crimsonAlert; // Czerwony (#EF4444)
      case PcsSpecializationCategory.timeTrial:
        return AppColors.accentBlue; // Niebieski (#38BDF8)
      case PcsSpecializationCategory.cobbles:
        return AppColors.powerZone5; // Pomarańczowy (#F97316)
      case PcsSpecializationCategory.allRounder:
        return AppColors.amberWarning; // Bursztynowy (#F59E0B)
    }
  }

  /// Krótka etykieta specjalizacji do widoku kompaktowego.
  String get shortLabel {
    switch (this) {
      case PcsSpecializationCategory.sprint:
        return 'SPR';
      case PcsSpecializationCategory.climber:
        return 'GÓR';
      case PcsSpecializationCategory.timeTrial:
        return 'TT';
      case PcsSpecializationCategory.cobbles:
        return 'BRK';
      case PcsSpecializationCategory.allRounder:
        return 'UNI';
    }
  }

  /// Pełna nazwa specjalizacji do dymków i widoku desktopowego.
  String get fullLabel {
    switch (this) {
      case PcsSpecializationCategory.sprint:
        return 'Sprint';
      case PcsSpecializationCategory.climber:
        return 'Góry';
      case PcsSpecializationCategory.timeTrial:
        return 'Jazda na czas';
      case PcsSpecializationCategory.cobbles:
        return 'Bruk / Klasyki';
      case PcsSpecializationCategory.allRounder:
        return 'Uniwersalny';
    }
  }

  /// Mapuje domenowy typ [RiderSpecialization] na kategorię PCS.
  static PcsSpecializationCategory fromRiderSpecialization(
    RiderSpecialization spec,
  ) {
    switch (spec) {
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        return PcsSpecializationCategory.sprint;
      case RiderSpecialization.gcClimber:
      case RiderSpecialization.pureClimber:
      case RiderSpecialization.puncher:
        return PcsSpecializationCategory.climber;
      case RiderSpecialization.timeTrialist:
        return PcsSpecializationCategory.timeTrial;
      case RiderSpecialization.classicCobbles:
        return PcsSpecializationCategory.cobbles;
      case RiderSpecialization.domestiqueEngine:
      case RiderSpecialization.breakawaySpecialist:
        return PcsSpecializationCategory.allRounder;
    }
  }
}

/// Niemutowalny model pojedynczego wiersza w tabeli [ProCyclingStatsTableWidget].
class PcsRiderRowData {
  final String id;
  final int? rank;
  final String? bibNumber;
  final String? statusLabel;
  final String firstName;
  final String lastName;
  final String nationalityIso;
  final String teamId;
  final String teamName;
  final String? teamShortCode;
  final Color teamPrimaryColor;
  final Color? teamSecondaryColor;
  final int age;
  final PcsSpecializationCategory specialization;
  final String? specializationLabel;
  final double? timeSeconds;
  final bool isTimeGap;
  final String? customTimeText;
  final int points;
  final int? secondaryMetric;
  final String? secondaryMetricText;
  final bool isPlayerTeam;
  final bool isLeader;
  final bool isDisabled;

  const PcsRiderRowData({
    required this.id,
    this.rank,
    this.bibNumber,
    this.statusLabel,
    required this.firstName,
    required this.lastName,
    required this.nationalityIso,
    required this.teamId,
    required this.teamName,
    this.teamShortCode,
    required this.teamPrimaryColor,
    this.teamSecondaryColor,
    required this.age,
    required this.specialization,
    this.specializationLabel,
    this.timeSeconds,
    this.isTimeGap = false,
    this.customTimeText,
    this.points = 0,
    this.secondaryMetric,
    this.secondaryMetricText,
    this.isPlayerTeam = false,
    this.isLeader = false,
    this.isDisabled = false,
  });

  /// Pełne nazwisko w stylu PCS: `NAZWISKO Imię`.
  String get pcsDisplayName => '${lastName.toUpperCase()} $firstName'.trim();

  /// Sformatowany tekst czasu lub statusu (np. `04:12:35`, `+0'14"`, `DNF`).
  String get formattedTime {
    if (customTimeText != null && customTimeText!.isNotEmpty) {
      return customTimeText!;
    }
    if (statusLabel != null && statusLabel!.isNotEmpty) {
      return statusLabel!;
    }
    if (timeSeconds == null) return '—';
    if (isTimeGap) {
      return Formatters.formatTimeGap(
        timeSeconds!,
        sameTimeLabel: "0'00\"",
      );
    }
    return Formatters.formatRaceTime(timeSeconds!);
  }
}

/// Ultraczytelna, kompaktowa tabela danych wzorowana na *ProCyclingStats (PCS)*
/// do prezentacji wyników, list startowych i statystyk kolarzy.
///
/// Obsługuje:
/// - Wektorowe flagi krajów na podstawie kodu ISO (np. `POL`, `SLO`, `BEL`, `FRA`),
/// - Pogrubione nazwisko + imię w konwencji PCS,
/// - Klikalną nazwę drużyny w jej kolorach (z automatyczną korekcją kontrastu),
/// - Specjalizację z kolorowym znacznikiem punktowym (zielony = sprint, czerwony = góry,
///   niebieski = TT, pomarańczowy = bruk),
/// - Błyskawiczne sortowanie po kliknięciu dowolnego nagłówka kolumny,
/// - Pole wyszukiwania na żywo (Live Search Filter) oraz szybkie filtry specjalizacji,
/// - Podświetlenie wierszy drużyny gracza subtelnym złotym paskiem bocznym `#D4AF37`,
/// - Pełną responsywność `LayoutBuilder` (`390x844`, `1024x768`, `1600x900`) i stany
///   `hover` / `active` / `disabled` / `focus`.
class ProCyclingStatsTableWidget extends StatefulWidget {
  final List<PcsRiderRowData> rows;
  final PcsTableMode mode;
  final String? title;
  final String? subtitle;
  final String searchHint;
  final bool showSearchBar;
  final bool showSpecializationFilters;
  final bool showPlayerTeamToggle;
  final bool showSecondaryMetricColumn;
  final String? secondaryMetricHeader;
  final String? timeColumnHeader;
  final String? pointsColumnHeader;
  final PcsSortColumn initialSortColumn;
  final bool initialSortAscending;
  final ValueChanged<PcsRiderRowData>? onRiderTap;
  final void Function(String teamId, String teamName)? onTeamTap;
  final EdgeInsetsGeometry? padding;
  final double? maxTableHeight;

  const ProCyclingStatsTableWidget({
    super.key,
    required this.rows,
    this.mode = PcsTableMode.results,
    this.title,
    this.subtitle,
    this.searchHint = 'Szukaj kolarza, drużyny lub kraju (ISO)...',
    this.showSearchBar = true,
    this.showSpecializationFilters = true,
    this.showPlayerTeamToggle = true,
    this.showSecondaryMetricColumn = true,
    this.secondaryMetricHeader,
    this.timeColumnHeader,
    this.pointsColumnHeader,
    this.initialSortColumn = PcsSortColumn.rank,
    this.initialSortAscending = true,
    this.onRiderTap,
    this.onTeamTap,
    this.padding,
    this.maxTableHeight,
  });

  @override
  State<ProCyclingStatsTableWidget> createState() =>
      _ProCyclingStatsTableWidgetState();
}

class _ProCyclingStatsTableWidgetState
    extends State<ProCyclingStatsTableWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _verticalScrollController = ScrollController();

  String _searchQuery = '';
  bool _isSearchFocused = false;
  bool _isSearchHovered = false;
  bool _onlyPlayerTeam = false;
  PcsSpecializationCategory? _selectedSpecFilter;
  late PcsSortColumn _sortColumn;
  late bool _sortAscending;
  List<PcsRiderRowData> _processedRows = const [];

  @override
  void initState() {
    super.initState();
    _sortColumn = widget.initialSortColumn;
    _sortAscending = widget.initialSortAscending;
    _searchFocusNode.addListener(_handleSearchFocusChange);
    _recomputeRows();
  }

  @override
  void didUpdateWidget(covariant ProCyclingStatsTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows ||
        oldWidget.mode != widget.mode ||
        oldWidget.initialSortColumn != widget.initialSortColumn ||
        oldWidget.initialSortAscending != widget.initialSortAscending) {
      _recomputeRows();
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChange() {
    if (mounted) {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
      _recomputeRows();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _recomputeRows();
    });
  }

  void _toggleSort(PcsSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        // Domyślnie punkty i metryki malejąco, pozostałe rosnąco
        _sortAscending = column != PcsSortColumn.points &&
            column != PcsSortColumn.secondaryMetric;
      }
      _recomputeRows();
    });
  }

  void _toggleSpecFilter(PcsSpecializationCategory? spec) {
    setState(() {
      _selectedSpecFilter = _selectedSpecFilter == spec ? null : spec;
      _recomputeRows();
    });
  }

  void _togglePlayerTeamOnly() {
    setState(() {
      _onlyPlayerTeam = !_onlyPlayerTeam;
      _recomputeRows();
    });
  }

  void _recomputeRows() {
    final Iterable<PcsRiderRowData> filtered = widget.rows.where((row) {
      if (_onlyPlayerTeam && !row.isPlayerTeam) return false;
      if (_selectedSpecFilter != null &&
          row.specialization != _selectedSpecFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final fullName = '${row.firstName} ${row.lastName}'.toLowerCase();
        final reverseName = '${row.lastName} ${row.firstName}'.toLowerCase();
        final team = row.teamName.toLowerCase();
        final teamShort = (row.teamShortCode ?? '').toLowerCase();
        final iso = row.nationalityIso.toLowerCase();
        final specLabel =
            (row.specializationLabel ?? row.specialization.fullLabel)
                .toLowerCase();

        final matches = fullName.contains(_searchQuery) ||
            reverseName.contains(_searchQuery) ||
            team.contains(_searchQuery) ||
            teamShort.contains(_searchQuery) ||
            iso.contains(_searchQuery) ||
            specLabel.contains(_searchQuery);
        if (!matches) return false;
      }
      return true;
    });

    final List<PcsRiderRowData> sorted = filtered.toList();
    sorted.sort((a, b) {
      final int cmp = _compareRows(a, b);
      if (cmp != 0) return _sortAscending ? cmp : -cmp;
      // Stabilne wiązanie remisów po pozycji / nazwisku
      final int rankA = a.rank ?? 999999;
      final int rankB = b.rank ?? 999999;
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
    });

    _processedRows = sorted;
  }

  int _compareRows(PcsRiderRowData a, PcsRiderRowData b) {
    switch (_sortColumn) {
      case PcsSortColumn.rank:
        final int rankA = a.rank ??
            (int.tryParse(a.bibNumber ?? '') ?? 999999);
        final int rankB = b.rank ??
            (int.tryParse(b.bibNumber ?? '') ?? 999999);
        return rankA.compareTo(rankB);
      case PcsSortColumn.nationality:
        return a.nationalityIso
            .toUpperCase()
            .compareTo(b.nationalityIso.toUpperCase());
      case PcsSortColumn.name:
        final int lastCmp =
            a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
        if (lastCmp != 0) return lastCmp;
        return a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
      case PcsSortColumn.team:
        return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
      case PcsSortColumn.age:
        return a.age.compareTo(b.age);
      case PcsSortColumn.specialization:
        return a.specialization.index.compareTo(b.specialization.index);
      case PcsSortColumn.time:
        final double timeA = a.timeSeconds ?? double.infinity;
        final double timeB = b.timeSeconds ?? double.infinity;
        return timeA.compareTo(timeB);
      case PcsSortColumn.points:
        return a.points.compareTo(b.points);
      case PcsSortColumn.secondaryMetric:
        final int secA = a.secondaryMetric ?? -1;
        final int secB = b.secondaryMetric ?? -1;
        return secA.compareTo(secB);
    }
  }

  String get _effectiveRankHeader {
    switch (widget.mode) {
      case PcsTableMode.results:
        return 'RNK';
      case PcsTableMode.startlist:
        return 'NR';
      case PcsTableMode.statistics:
        return 'POZ';
    }
  }

  String get _effectiveTimeHeader {
    if (widget.timeColumnHeader != null) return widget.timeColumnHeader!;
    switch (widget.mode) {
      case PcsTableMode.results:
        return 'CZAS';
      case PcsTableMode.startlist:
        return 'FORMA';
      case PcsTableMode.statistics:
        return 'ZWYC.';
    }
  }

  String get _effectivePointsHeader {
    if (widget.pointsColumnHeader != null) return widget.pointsColumnHeader!;
    switch (widget.mode) {
      case PcsTableMode.results:
        return 'PKT UCI';
      case PcsTableMode.startlist:
        return 'PKT UCI';
      case PcsTableMode.statistics:
        return 'PKT PCS';
    }
  }

  String get _effectiveSecondaryHeader {
    if (widget.secondaryMetricHeader != null) {
      return widget.secondaryMetricHeader!;
    }
    switch (widget.mode) {
      case PcsTableMode.results:
        return 'PCS';
      case PcsTableMode.startlist:
        return 'OVR';
      case PcsTableMode.statistics:
        return 'DNI WYŚ.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPlayerTeamRows = widget.rows.any((r) => r.isPlayerTeam);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool isMobile = width < 620;
        final bool isDesktop = width >= 1000;

        return Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.title != null ||
                  widget.showSearchBar ||
                  widget.showSpecializationFilters)
                _buildToolbar(
                  isMobile: isMobile,
                  isDesktop: isDesktop,
                  hasPlayerTeamRows: hasPlayerTeamRows,
                ),
              _buildColumnHeaderRow(
                isMobile: isMobile,
                isDesktop: isDesktop,
              ),
              if (_processedRows.isEmpty)
                _buildEmptyState()
              else
                _buildTableBody(
                  isMobile: isMobile,
                  isDesktop: isDesktop,
                ),
              _buildFooterBar(isMobile: isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar({
    required bool isMobile,
    required bool isDesktop,
    required bool hasPlayerTeamRows,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null || widget.subtitle != null) ...[
            Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildResultCountBadge(),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (isMobile) ...[
            if (widget.showSearchBar) _buildSearchField(),
            if (widget.showSpecializationFilters ||
                (widget.showPlayerTeamToggle && hasPlayerTeamRows)) ...[
              const SizedBox(height: 8),
              _buildFilterChipsWrap(hasPlayerTeamRows: hasPlayerTeamRows),
            ],
          ] else ...[
            Row(
              children: [
                if (widget.showSearchBar)
                  Expanded(
                    flex: isDesktop ? 4 : 5,
                    child: _buildSearchField(),
                  ),
                if (widget.showSearchBar &&
                    (widget.showSpecializationFilters ||
                        (widget.showPlayerTeamToggle && hasPlayerTeamRows)))
                  const SizedBox(width: 12),
                if (widget.showSpecializationFilters ||
                    (widget.showPlayerTeamToggle && hasPlayerTeamRows))
                  Expanded(
                    flex: isDesktop ? 6 : 5,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildFilterChipsWrap(
                        hasPlayerTeamRows: hasPlayerTeamRows,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Text(
        '${_processedRows.length}/${widget.rows.length}',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final Color borderColor = _isSearchFocused
        ? AppColors.goldAccent
        : _isSearchHovered
            ? AppColors.textSecondary.withValues(alpha: 0.45)
            : AppTheme.borderColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isSearchHovered = true),
      onExit: (_) => setState(() => _isSearchHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: _isSearchFocused ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(
              Icons.search_rounded,
              size: 16,
              color: _isSearchFocused
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
                cursorColor: AppColors.goldAccent,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: widget.searchHint,
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchQuery.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear_search'),
                      onPressed: _clearSearch,
                      tooltip: 'Wyczyść filtr',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const SizedBox(width: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChipsWrap({required bool hasPlayerTeamRows}) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.start,
      children: [
        if (widget.showSpecializationFilters) ...[
          _PcsFilterPill(
            label: 'Sprint',
            dotColor: PcsSpecializationCategory.sprint.dotColor,
            isSelected:
                _selectedSpecFilter == PcsSpecializationCategory.sprint,
            onTap: () => _toggleSpecFilter(PcsSpecializationCategory.sprint),
          ),
          _PcsFilterPill(
            label: 'Góry',
            dotColor: PcsSpecializationCategory.climber.dotColor,
            isSelected:
                _selectedSpecFilter == PcsSpecializationCategory.climber,
            onTap: () => _toggleSpecFilter(PcsSpecializationCategory.climber),
          ),
          _PcsFilterPill(
            label: 'TT',
            dotColor: PcsSpecializationCategory.timeTrial.dotColor,
            isSelected:
                _selectedSpecFilter == PcsSpecializationCategory.timeTrial,
            onTap: () =>
                _toggleSpecFilter(PcsSpecializationCategory.timeTrial),
          ),
          _PcsFilterPill(
            label: 'Bruk',
            dotColor: PcsSpecializationCategory.cobbles.dotColor,
            isSelected:
                _selectedSpecFilter == PcsSpecializationCategory.cobbles,
            onTap: () => _toggleSpecFilter(PcsSpecializationCategory.cobbles),
          ),
        ],
        if (widget.showPlayerTeamToggle && hasPlayerTeamRows)
          _PcsFilterPill(
            label: 'Moja ekipa',
            dotColor: AppColors.goldAccent,
            isSelected: _onlyPlayerTeam,
            isGoldHighlight: true,
            onTap: _togglePlayerTeamOnly,
          ),
      ],
    );
  }

  Widget _buildColumnHeaderRow({
    required bool isMobile,
    required bool isDesktop,
  }) {
    return Container(
      height: 34,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: isMobile ? 42 : 48,
            child: _PcsSortableHeaderCell(
              label: _effectiveRankHeader,
              column: PcsSortColumn.rank,
              activeColumn: _sortColumn,
              ascending: _sortAscending,
              alignment: Alignment.centerLeft,
              onTap: () => _toggleSort(PcsSortColumn.rank),
            ),
          ),
          if (!isMobile) ...[
            SizedBox(
              width: 44,
              child: _PcsSortableHeaderCell(
                label: 'KRAJ',
                column: PcsSortColumn.nationality,
                activeColumn: _sortColumn,
                ascending: _sortAscending,
                alignment: Alignment.center,
                onTap: () => _toggleSort(PcsSortColumn.nationality),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: isMobile ? 5 : 4,
            child: _PcsSortableHeaderCell(
              label: 'KOLARZ',
              column: PcsSortColumn.name,
              activeColumn: _sortColumn,
              ascending: _sortAscending,
              alignment: Alignment.centerLeft,
              onTap: () => _toggleSort(PcsSortColumn.name),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _PcsSortableHeaderCell(
                label: 'DRUŻYNA',
                column: PcsSortColumn.team,
                activeColumn: _sortColumn,
                ascending: _sortAscending,
                alignment: Alignment.centerLeft,
                onTap: () => _toggleSort(PcsSortColumn.team),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: _PcsSortableHeaderCell(
                label: 'WIEK',
                column: PcsSortColumn.age,
                activeColumn: _sortColumn,
                ascending: _sortAscending,
                alignment: Alignment.center,
                onTap: () => _toggleSort(PcsSortColumn.age),
              ),
            ),
          ],
          const SizedBox(width: 6),
          SizedBox(
            width: isMobile ? 50 : (isDesktop ? 124 : 74),
            child: _PcsSortableHeaderCell(
              label: 'SPEC',
              column: PcsSortColumn.specialization,
              activeColumn: _sortColumn,
              ascending: _sortAscending,
              alignment: Alignment.centerLeft,
              onTap: () => _toggleSort(PcsSortColumn.specialization),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: isMobile ? 70 : 86,
            child: _PcsSortableHeaderCell(
              label: _effectiveTimeHeader,
              column: PcsSortColumn.time,
              activeColumn: _sortColumn,
              ascending: _sortAscending,
              alignment: Alignment.centerRight,
              onTap: () => _toggleSort(PcsSortColumn.time),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 66,
              child: _PcsSortableHeaderCell(
                label: _effectivePointsHeader,
                column: PcsSortColumn.points,
                activeColumn: _sortColumn,
                ascending: _sortAscending,
                alignment: Alignment.centerRight,
                onTap: () => _toggleSort(PcsSortColumn.points),
              ),
            ),
          ],
          if (isDesktop && widget.showSecondaryMetricColumn) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 66,
              child: _PcsSortableHeaderCell(
                label: _effectiveSecondaryHeader,
                column: PcsSortColumn.secondaryMetric,
                activeColumn: _sortColumn,
                ascending: _sortAscending,
                alignment: Alignment.centerRight,
                onTap: () => _toggleSort(PcsSortColumn.secondaryMetric),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableBody({
    required bool isMobile,
    required bool isDesktop,
  }) {
    final Widget listView = ListView.builder(
      controller: _verticalScrollController,
      shrinkWrap: widget.maxTableHeight == null,
      physics: widget.maxTableHeight == null
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      itemCount: _processedRows.length,
      itemBuilder: (context, index) {
        final row = _processedRows[index];
        return _PcsRiderRow(
          key: ValueKey('pcs_row_${row.id}'),
          row: row,
          index: index,
          isMobile: isMobile,
          isDesktop: isDesktop,
          mode: widget.mode,
          showSecondaryMetric: widget.showSecondaryMetricColumn,
          onRiderTap: widget.onRiderTap,
          onTeamTap: widget.onTeamTap,
        );
      },
    );

    if (widget.maxTableHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxTableHeight!),
        child: Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: listView,
        ),
      );
    }
    return listView;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      color: AppColors.background.withValues(alpha: 0.45),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.filter_list_off_rounded,
            size: 28,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const Text(
            'Brak kolarzy spełniających kryteria wyszukiwania',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Zmień frazę w wyszukiwarce lub wyłącz aktywne filtry specjalizacji.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (_searchQuery.isNotEmpty ||
              _selectedSpecFilter != null ||
              _onlyPlayerTeam) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedSpecFilter = null;
                  _onlyPlayerTeam = false;
                  _recomputeRows();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Resetuj filtry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldAccent,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterBar({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 14,
        vertical: 7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          const Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _PcsLegendDot(
                color: AppColors.statusSuccess,
                label: 'Sprint',
              ),
              _PcsLegendDot(
                color: AppColors.crimsonAlert,
                label: 'Góry',
              ),
              _PcsLegendDot(
                color: AppColors.accentBlue,
                label: 'TT',
              ),
              _PcsLegendDot(
                color: AppColors.powerZone5,
                label: 'Bruk',
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title == null && widget.subtitle == null) ...[
                _buildResultCountBadge(),
                const SizedBox(width: 10),
              ],
              Container(
                width: 10,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'Twoja drużyna',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PcsLegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _PcsLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PcsFilterPill extends StatefulWidget {
  final String label;
  final Color dotColor;
  final bool isSelected;
  final bool isGoldHighlight;
  final VoidCallback onTap;

  const _PcsFilterPill({
    required this.label,
    required this.dotColor,
    required this.isSelected,
    this.isGoldHighlight = false,
    required this.onTap,
  });

  @override
  State<_PcsFilterPill> createState() => _PcsFilterPillState();
}

class _PcsFilterPillState extends State<_PcsFilterPill> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        widget.isGoldHighlight ? AppColors.goldAccent : widget.dotColor;
    final Color bgColor = widget.isSelected
        ? activeColor.withValues(alpha: _isPressed ? 0.28 : 0.18)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? activeColor.withValues(alpha: 0.75)
            : _isHovered
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PcsSortableHeaderCell extends StatefulWidget {
  final String label;
  final PcsSortColumn column;
  final PcsSortColumn activeColumn;
  final bool ascending;
  final Alignment alignment;
  final VoidCallback onTap;

  const _PcsSortableHeaderCell({
    required this.label,
    required this.column,
    required this.activeColumn,
    required this.ascending,
    required this.alignment,
    required this.onTap,
  });

  @override
  State<_PcsSortableHeaderCell> createState() => _PcsSortableHeaderCellState();
}

class _PcsSortableHeaderCellState extends State<_PcsSortableHeaderCell> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.column == widget.activeColumn;
    final bool isRight = widget.alignment == Alignment.centerRight;
    final bool isCenter = widget.alignment == Alignment.center;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.primaryAccent.withValues(alpha: 0.22)
                : _isHovered
                    ? AppColors.background.withValues(alpha: 0.45)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: _isFocused
                ? Border.all(color: AppColors.goldAccent, width: 1.0)
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: widget.alignment,
            child: Row(
              mainAxisAlignment: isRight
                  ? MainAxisAlignment.end
                  : isCenter
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: 0.35,
                    color: isActive
                        ? AppColors.goldAccent
                        : _isHovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: widget.ascending ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                  ),
                ] else if (_isHovered) ...[
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.unfold_more_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
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

class _PcsRiderRow extends StatefulWidget {
  final PcsRiderRowData row;
  final int index;
  final bool isMobile;
  final bool isDesktop;
  final PcsTableMode mode;
  final bool showSecondaryMetric;
  final ValueChanged<PcsRiderRowData>? onRiderTap;
  final void Function(String teamId, String teamName)? onTeamTap;

  const _PcsRiderRow({
    super.key,
    required this.row,
    required this.index,
    required this.isMobile,
    required this.isDesktop,
    required this.mode,
    required this.showSecondaryMetric,
    this.onRiderTap,
    this.onTeamTap,
  });

  @override
  State<_PcsRiderRow> createState() => _PcsRiderRowState();
}

class _PcsRiderRowState extends State<_PcsRiderRow> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final bool interactive = !row.isDisabled && widget.onRiderTap != null;
    final bool isEven = widget.index.isEven;

    final Color baseBg = row.isPlayerTeam
        ? AppColors.goldAccent.withValues(alpha: isEven ? 0.075 : 0.05)
        : isEven
            ? AppColors.surface
            : AppColors.background.withValues(alpha: 0.52);

    final Color bgColor = row.isDisabled
        ? baseBg.withValues(alpha: 0.5)
        : _isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.22)
            : _isHovered
                ? (row.isPlayerTeam
                    ? AppColors.goldAccent.withValues(alpha: 0.14)
                    : AppColors.surfaceLight.withValues(alpha: 0.85))
                : baseBg;

    return FocusableActionDetector(
      enabled: interactive,
      onShowHoverHighlight: (v) {
        if (interactive) setState(() => _isHovered = v);
      },
      onShowFocusHighlight: (v) {
        if (interactive) setState(() => _isFocused = v);
      },
      mouseCursor:
          interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (interactive) widget.onRiderTap?.call(row);
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: interactive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            interactive ? () => setState(() => _isPressed = false) : null,
        onTap: interactive ? () => widget.onRiderTap?.call(row) : null,
        child: Opacity(
          opacity: row.isDisabled ? 0.45 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: widget.isMobile ? 46 : 38),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                left: BorderSide(
                  color: row.isPlayerTeam
                      ? AppColors.goldAccent
                      : Colors.transparent,
                  width: row.isPlayerTeam ? 3.5 : 0.0,
                ),
                bottom: BorderSide(
                  color: _isFocused
                      ? AppColors.goldAccent
                      : AppTheme.borderColor.withValues(alpha: 0.55),
                  width: _isFocused ? 1.2 : 0.6,
                ),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 8 : 12,
              vertical: widget.isMobile ? 6 : 5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Pozycja / Numer startowy
                SizedBox(
                  width: widget.isMobile ? 42 : 48,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildRankCell(row),
                  ),
                ),

                // 2. Flaga kraju (Desktop/Tablet osobna kolumna)
                if (!widget.isMobile) ...[
                  SizedBox(
                    width: 44,
                    child: Center(
                      child: PcsCountryFlagBadge(
                        isoCode: row.nationalityIso,
                        showTooltip: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // 3. Kolarz (na mobile także flaga + klikalna drużyna pod spodem)
                Expanded(
                  flex: widget.isMobile ? 5 : 4,
                  child: widget.isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                PcsCountryFlagBadge(
                                  isoCode: row.nationalityIso,
                                  width: 18,
                                  height: 12,
                                ),
                                const SizedBox(width: 6),
                                Expanded(child: _buildRiderNameText(row)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: _PcsClickableTeamPill(
                                    teamName: row.teamShortCode ?? row.teamName,
                                    teamColor: row.teamPrimaryColor,
                                    isDisabled: row.isDisabled,
                                    compact: true,
                                    onTap: widget.onTeamTap == null ||
                                            row.isDisabled
                                        ? null
                                        : () => widget.onTeamTap!(
                                              row.teamId,
                                              row.teamName,
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${row.age}l',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10.5,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : _buildRiderNameText(row),
                ),

                // 4. Klikalna drużyna i wiek (Tablet & Desktop)
                if (!widget.isMobile) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _PcsClickableTeamPill(
                        teamName: row.teamName,
                        teamColor: row.teamPrimaryColor,
                        isDisabled: row.isDisabled,
                        onTap: widget.onTeamTap == null || row.isDisabled
                            ? null
                            : () =>
                                widget.onTeamTap!(row.teamId, row.teamName),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: Text(
                        '${row.age}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],

                // 5. Specjalizacja z kolorowym znacznikiem punktowym
                const SizedBox(width: 6),
                SizedBox(
                  width: widget.isMobile ? 50 : (widget.isDesktop ? 124 : 74),
                  child: _buildSpecializationCell(row),
                ),

                // 6. Czas / Strata (lub Forma/Zwyc.)
                const SizedBox(width: 6),
                SizedBox(
                  width: widget.isMobile ? 70 : 86,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          row.formattedTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: row.rank == 1
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: row.statusLabel != null
                                ? AppColors.crimsonAlert
                                : row.rank == 1
                                    ? AppColors.goldAccent
                                    : AppColors.textPrimary,
                          ),
                        ),
                        if (widget.isMobile && row.points > 0)
                          Text(
                            '${row.points} pkt',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: AppColors.accentBlue,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 7. Punkty UCI / PCS
                if (!widget.isMobile) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 66,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        row.points > 0 ? '${row.points}' : '—',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: row.points > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: row.points > 0
                              ? AppColors.accentBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],

                // 8. Dodatkowa metryka na Desktopie
                if (widget.isDesktop && widget.showSecondaryMetric) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 66,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        row.secondaryMetricText ??
                            (row.secondaryMetric != null
                                ? '${row.secondaryMetric}'
                                : '—'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.textSecondary,
                        ),
                      ),
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

  Widget _buildRankCell(PcsRiderRowData row) {
    final String rankStr = row.statusLabel != null && row.rank == null
        ? row.statusLabel!
        : widget.mode == PcsTableMode.startlist
            ? (row.bibNumber ?? row.rank?.toString() ?? '—')
            : (row.rank?.toString() ?? row.bibNumber ?? '—');

    final bool isPodium =
        widget.mode != PcsTableMode.startlist &&
        row.rank != null &&
        row.rank! <= 3;

    Color rankColor = AppColors.textSecondary;
    if (row.isLeader || row.rank == 1) {
      rankColor = AppColors.goldAccent;
    } else if (row.rank == 2) {
      rankColor = const Color(0xFFE5E7EB);
    } else if (row.rank == 3) {
      rankColor = const Color(0xFFD97706);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rankStr,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isPodium ? FontWeight.w800 : FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: rankColor,
          ),
        ),
        if (row.isLeader) ...[
          const SizedBox(width: 3),
          const Icon(
            Icons.emoji_events_rounded,
            size: 12,
            color: AppColors.goldAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildRiderNameText(PcsRiderRowData row) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: row.lastName.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.15,
              color: row.isPlayerTeam
                  ? AppColors.goldAccent
                  : AppColors.textPrimary,
            ),
          ),
          if (row.firstName.isNotEmpty)
            TextSpan(
              text: ' ${row.firstName}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.15,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSpecializationCell(PcsRiderRowData row) {
    final String label = widget.isDesktop
        ? (row.specializationLabel ?? row.specialization.fullLabel)
        : row.specialization.shortLabel;

    return Tooltip(
      message: row.specializationLabel ?? row.specialization.fullLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: row.specialization.dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: row.specialization.dotColor.withValues(alpha: 0.45),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PcsClickableTeamPill extends StatefulWidget {
  final String teamName;
  final Color teamColor;
  final bool isDisabled;
  final bool compact;
  final VoidCallback? onTap;

  const _PcsClickableTeamPill({
    required this.teamName,
    required this.teamColor,
    required this.isDisabled,
    this.compact = false,
    this.onTap,
  });

  @override
  State<_PcsClickableTeamPill> createState() => _PcsClickableTeamPillState();
}

class _PcsClickableTeamPillState extends State<_PcsClickableTeamPill> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  /// Zapewnia czytelność koloru drużyny na ciemnym tle `#181B22`.
  Color _readableTeamColor(Color raw) {
    final double luminance = raw.computeLuminance();
    if (luminance < 0.16) {
      return Color.lerp(raw, Colors.white, 0.42) ?? raw;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final bool interactive = !widget.isDisabled && widget.onTap != null;
    final Color displayColor = _readableTeamColor(widget.teamColor);

    return FocusableActionDetector(
      enabled: interactive,
      onShowHoverHighlight: (v) {
        if (interactive) setState(() => _isHovered = v);
      },
      onShowFocusHighlight: (v) {
        if (interactive) setState(() => _isFocused = v);
      },
      mouseCursor:
          interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (interactive) widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: interactive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: interactive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            interactive ? () => setState(() => _isPressed = false) : null,
        onTap: interactive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 5 : 7,
            vertical: widget.compact ? 1.5 : 3,
          ),
          decoration: BoxDecoration(
            color: _isPressed
                ? displayColor.withValues(alpha: 0.24)
                : _isHovered
                    ? displayColor.withValues(alpha: 0.14)
                    : displayColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isFocused
                  ? AppColors.goldAccent
                  : _isHovered
                      ? displayColor.withValues(alpha: 0.65)
                      : displayColor.withValues(alpha: 0.28),
              width: _isFocused ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.compact ? 3 : 4,
                height: widget.compact ? 9 : 11,
                decoration: BoxDecoration(
                  color: widget.teamColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  widget.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 10.5 : 11.5,
                    fontWeight: FontWeight.w600,
                    decoration: _isHovered && interactive
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: displayColor,
                    color: displayColor,
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

/// Wektorowy znacznik flagi kraju rysowany przez [CustomPainter] z kodu ISO.
class PcsCountryFlagBadge extends StatelessWidget {
  final String isoCode;
  final double width;
  final double height;
  final bool showTooltip;

  const PcsCountryFlagBadge({
    super.key,
    required this.isoCode,
    this.width = 22,
    this.height = 15,
    this.showTooltip = false,
  });

  @override
  Widget build(BuildContext context) {
    final String normalized = isoCode.trim().toUpperCase();
    final Widget flag = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.7,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        size: Size(width, height),
        painter: _PcsVectorFlagPainter(isoCode: normalized),
      ),
    );

    if (showTooltip && normalized.isNotEmpty) {
      return Tooltip(
        message: normalized,
        child: flag,
      );
    }
    return flag;
  }
}

class _PcsVectorFlagPainter extends CustomPainter {
  final String isoCode;

  const _PcsVectorFlagPainter({required this.isoCode});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    switch (isoCode) {
      case 'POL':
      case 'PL':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFFFFFFFF),
          const Color(0xFFDC143C),
        ]);
      case 'FRA':
      case 'FR':
        _drawVerticalStripes(canvas, size, [
          const Color(0xFF0055A4),
          const Color(0xFFFFFFFF),
          const Color(0xFFEF4135),
        ]);
      case 'BEL':
      case 'BE':
        _drawVerticalStripes(canvas, size, [
          const Color(0xFF111827),
          const Color(0xFFFDDA24),
          const Color(0xFFEF3340),
        ]);
      case 'ITA':
      case 'IT':
        _drawVerticalStripes(canvas, size, [
          const Color(0xFF009246),
          const Color(0xFFFFFFFF),
          const Color(0xFFCE2B37),
        ]);
      case 'IRL':
      case 'IE':
        _drawVerticalStripes(canvas, size, [
          const Color(0xFF169B62),
          const Color(0xFFFFFFFF),
          const Color(0xFFFF883E),
        ]);
      case 'NED':
      case 'NLD':
      case 'NL':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFFAE1C28),
          const Color(0xFFFFFFFF),
          const Color(0xFF21468B),
        ]);
      case 'LUX':
      case 'LU':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFFEA1D25),
          const Color(0xFFFFFFFF),
          const Color(0xFF00A1DE),
        ]);
      case 'GER':
      case 'DEU':
      case 'DE':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFF111827),
          const Color(0xFFDD0000),
          const Color(0xFFFFCE00),
        ]);
      case 'ESP':
      case 'ES':
        _drawHorizontalWeighted(canvas, size, [
          (const Color(0xFFAA151B), 0.25),
          (const Color(0xFFF1BF00), 0.50),
          (const Color(0xFFAA151B), 0.25),
        ]);
      case 'AUT':
      case 'AT':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFFED2939),
          const Color(0xFFFFFFFF),
          const Color(0xFFED2939),
        ]);
      case 'COL':
      case 'CO':
        _drawHorizontalWeighted(canvas, size, [
          (const Color(0xFFFCD116), 0.50),
          (const Color(0xFF003893), 0.25),
          (const Color(0xFFCE1126), 0.25),
        ]);
      case 'SLO':
      case 'SVN':
      case 'SI':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFFFFFFFF),
          const Color(0xFF005DA4),
          const Color(0xFFED1C24),
        ]);
        canvas.drawRect(
          Rect.fromLTWH(w * 0.16, h * 0.18, w * 0.18, h * 0.24),
          Paint()..color = const Color(0xFF005DA4),
        );
      case 'SVK':
      case 'SK':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFFFFFFFF),
          const Color(0xFF0B4EA2),
          const Color(0xFFEE1C25),
        ]);
        canvas.drawRect(
          Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.18, h * 0.45),
          Paint()..color = const Color(0xFFEE1C25),
        );
      case 'CZE':
      case 'CZ':
        _drawHorizontalStripes(canvas, size, [
          const Color(0xFFFFFFFF),
          const Color(0xFFD7141A),
        ]);
        final Path czTriangle = Path()
          ..moveTo(0, 0)
          ..lineTo(w * 0.48, h * 0.5)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(
          czTriangle,
          Paint()..color = const Color(0xFF11457E),
        );
      case 'SUI':
      case 'CHE':
      case 'CH':
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFFFF0000),
        );
        final Paint white = Paint()..color = Colors.white;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w * 0.48,
            height: h * 0.22,
          ),
          white,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w * 0.15,
            height: h * 0.62,
          ),
          white,
        );
      case 'DEN':
      case 'DNK':
      case 'DK':
        _drawNordicCross(
          canvas,
          size,
          bg: const Color(0xFFC60C30),
          cross: Colors.white,
        );
      case 'SWE':
      case 'SE':
        _drawNordicCross(
          canvas,
          size,
          bg: const Color(0xFF006AA7),
          cross: const Color(0xFFFECC00),
        );
      case 'NOR':
      case 'NO':
        _drawNordicCross(
          canvas,
          size,
          bg: const Color(0xFFBA0C2F),
          cross: Colors.white,
          innerCross: const Color(0xFF00205B),
        );
      case 'GBR':
      case 'GB':
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFF012169),
        );
        final Paint diagWhite = Paint()
          ..color = Colors.white
          ..strokeWidth = h * 0.2;
        canvas.drawLine(Offset.zero, Offset(w, h), diagWhite);
        canvas.drawLine(Offset(w, 0), Offset(0, h), diagWhite);
        final Paint crossWhite = Paint()..color = Colors.white;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w,
            height: h * 0.30,
          ),
          crossWhite,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w * 0.22,
            height: h,
          ),
          crossWhite,
        );
        final Paint crossRed = Paint()..color = const Color(0xFFC8102E);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w,
            height: h * 0.16,
          ),
          crossRed,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.5),
            width: w * 0.12,
            height: h,
          ),
          crossRed,
        );
      case 'POR':
      case 'PRT':
      case 'PT':
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w * 0.4, h),
          Paint()..color = const Color(0xFF006600),
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.4, 0, w * 0.6, h),
          Paint()..color = const Color(0xFFFF0000),
        );
        canvas.drawCircle(
          Offset(w * 0.4, h * 0.5),
          h * 0.2,
          Paint()..color = const Color(0xFFFFD700),
        );
      case 'USA':
      case 'US':
        for (int i = 0; i < 7; i++) {
          canvas.drawRect(
            Rect.fromLTWH(0, h * i / 7, w, h / 7),
            Paint()
              ..color =
                  i.isEven ? const Color(0xFFB22234) : const Color(0xFFFFFFFF),
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w * 0.45, h * 4 / 7),
          Paint()..color = const Color(0xFF3C3B6E),
        );
      case 'AUS':
      case 'AU':
      case 'NZL':
      case 'NZ':
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = const Color(0xFF00008B),
        );
        canvas.drawRect(
          Rect.fromLTWH(0, 0, w * 0.45, h * 0.5),
          Paint()..color = const Color(0xFFC8102E),
        );
        canvas.drawCircle(
          Offset(w * 0.74, h * 0.35),
          math.max(1.2, h * 0.09),
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(w * 0.78, h * 0.70),
          math.max(1.2, h * 0.09),
          Paint()..color = Colors.white,
        );
      case 'CAN':
      case 'CA':
        _drawVerticalWeighted(canvas, size, [
          (const Color(0xFFFF0000), 0.25),
          (const Color(0xFFFFFFFF), 0.50),
          (const Color(0xFFFF0000), 0.25),
        ]);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          h * 0.18,
          Paint()..color = const Color(0xFFFF0000),
        );
      default:
        _drawFallbackIsoFlag(canvas, size);
    }
  }

  void _drawHorizontalStripes(Canvas canvas, Size size, List<Color> colors) {
    final double stripeH = size.height / colors.length;
    for (int i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, stripeH * i, size.width, stripeH + 0.3),
        Paint()..color = colors[i],
      );
    }
  }

  void _drawVerticalStripes(Canvas canvas, Size size, List<Color> colors) {
    final double stripeW = size.width / colors.length;
    for (int i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(stripeW * i, 0, stripeW + 0.3, size.height),
        Paint()..color = colors[i],
      );
    }
  }

  void _drawHorizontalWeighted(
    Canvas canvas,
    Size size,
    List<(Color, double)> bands,
  ) {
    double y = 0;
    for (final (color, weight) in bands) {
      final double h = size.height * weight;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, h + 0.3),
        Paint()..color = color,
      );
      y += h;
    }
  }

  void _drawVerticalWeighted(
    Canvas canvas,
    Size size,
    List<(Color, double)> bands,
  ) {
    double x = 0;
    for (final (color, weight) in bands) {
      final double w = size.width * weight;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w + 0.3, size.height),
        Paint()..color = color,
      );
      x += w;
    }
  }

  void _drawNordicCross(
    Canvas canvas,
    Size size, {
    required Color bg,
    required Color cross,
    Color? innerCross,
  }) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final Paint crossPaint = Paint()..color = cross;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.28, 0, w * 0.16, h),
      crossPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.38, w, h * 0.24),
      crossPaint,
    );
    if (innerCross != null) {
      final Paint innerPaint = Paint()..color = innerCross;
      canvas.drawRect(
        Rect.fromLTWH(w * 0.32, 0, w * 0.08, h),
        innerPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, h * 0.44, w, h * 0.12),
        innerPaint,
      );
    }
  }

  void _drawFallbackIsoFlag(Canvas canvas, Size size) {
    final int hash = isoCode.codeUnits.fold<int>(0, (acc, c) => acc * 31 + c);
    final Color c1 = HSLColor.fromAHSL(
      1.0,
      (hash % 360).toDouble(),
      0.58,
      0.38,
    ).toColor();
    final Color c2 = HSLColor.fromAHSL(
      1.0,
      ((hash + 140) % 360).toDouble(),
      0.62,
      0.48,
    ).toColor();

    _drawHorizontalStripes(canvas, size, [c1, c2]);

    final String label =
        isoCode.length > 3 ? isoCode.substring(0, 3) : isoCode;
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: math.max(6.5, size.height * 0.44),
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _PcsVectorFlagPainter oldDelegate) {
    return oldDelegate.isoCode != isoCode;
  }
}
