import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Filtr wydarzeń wyświetlanych na interaktywnej osi czasu kariery menedżera.
enum CareerTimelineFilter {
  all('Wszystkie', Icons.timeline_rounded),
  grandTours('Wielkie Toury', Icons.emoji_events_rounded),
  monuments('Monumenty', Icons.workspace_premium_rounded),
  transfers('Transfery', Icons.swap_horiz_rounded),
  teamChanges('Zmiany Zespołu', Icons.groups_rounded);

  final String label;
  final IconData icon;

  const CareerTimelineFilter(this.label, this.icon);
}

/// Rodzaj wygranego Wielkiego Touru na osi czasu kariery.
enum CareerGrandTourType {
  tourDeFrance('TDF', 'Tour de France', Color(0xFFD4AF37)),
  giroDItalia('GIRO', 'Giro d\'Italia', Color(0xFFEC4899)),
  vueltaAEspana('VUELTA', 'La Vuelta a España', Color(0xFFEF4444));

  final String shortCode;
  final String displayName;
  final Color jerseyColor;

  const CareerGrandTourType(this.shortCode, this.displayName, this.jerseyColor);
}

/// Rodzaj wygranego Monumentu kolarskiego.
enum CareerMonumentType {
  milanoSanremo('MSR', 'Milano-Sanremo', Color(0xFF38BDF8)),
  rondeVanVlaanderen('RVV', 'Ronde van Vlaanderen', Color(0xFFF59E0B)),
  parisRoubaix('PR', 'Paris-Roubaix', Color(0xFFD4AF37)),
  liegeBastogneLiege('LBL', 'Liège-Bastogne-Liège', Color(0xFF10B981)),
  ilLombardia('LOM', 'Il Lombardia', Color(0xFF8E4A49));

  final String shortCode;
  final String displayName;
  final Color accentColor;

  const CareerMonumentType(this.shortCode, this.displayName, this.accentColor);
}

/// Kierunek ruchu transferowego w sezonie.
enum CareerTransferDirection {
  incoming('Przyjście', Color(0xFF10B981), Icons.south_west_rounded),
  outgoing('Odejście', Color(0xFFF59E0B), Icons.north_east_rounded),
  academyPromotion('Awans U23', Color(0xFF38BDF8), Icons.auto_awesome_rounded);

  final String label;
  final Color color;
  final IconData icon;

  const CareerTransferDirection(this.label, this.color, this.icon);
}

/// Wpis o wygranej klasyfikacji generalnej Wielkiego Touru w danym sezonie.
class CareerGrandTourWinEntry {
  final CareerGrandTourType tourType;
  final String riderName;
  final int stageWinsCount;
  final int? winningMarginSeconds;
  final List<String> additionalJerseys;

  const CareerGrandTourWinEntry({
    required this.tourType,
    required this.riderName,
    this.stageWinsCount = 1,
    this.winningMarginSeconds,
    this.additionalJerseys = const [],
  });
}

/// Wpis o wygranym Monumencie w danym sezonie.
class CareerMonumentWinEntry {
  final CareerMonumentType monumentType;
  final String riderName;
  final String finishMethod;

  const CareerMonumentWinEntry({
    required this.monumentType,
    required this.riderName,
    required this.finishMethod,
  });
}

/// Wpis o największym transferze sezonu.
class CareerHeadlineTransferEntry {
  final String riderName;
  final CareerTransferDirection direction;
  final String otherTeamName;
  final double feeEur;
  final int overallRating;
  final String roleLabel;

  const CareerHeadlineTransferEntry({
    required this.riderName,
    required this.direction,
    required this.otherTeamName,
    required this.feeEur,
    required this.overallRating,
    required this.roleLabel,
  });
}

/// Pełny rekord pojedynczego sezonu w historii kariery menedżera.
class CareerSeasonHistoryEntry {
  final int seasonYear;
  final String teamName;
  final String teamShortCode;
  final String teamDivision;
  final Color teamPrimaryColor;
  final Color teamSecondaryColor;
  final bool isTeamSwitchYear;
  final double budgetEur;
  final double? previousYearBudgetEur;
  final int uciWorldRank;
  final int totalSeasonWins;
  final int uciPoints;
  final String managerTitle;
  final String? seasonHighlightNote;
  final List<CareerGrandTourWinEntry> grandTourWins;
  final List<CareerMonumentWinEntry> monumentWins;
  final List<CareerHeadlineTransferEntry> headlineTransfers;

  const CareerSeasonHistoryEntry({
    required this.seasonYear,
    required this.teamName,
    required this.teamShortCode,
    required this.teamDivision,
    required this.teamPrimaryColor,
    required this.teamSecondaryColor,
    this.isTeamSwitchYear = false,
    required this.budgetEur,
    this.previousYearBudgetEur,
    required this.uciWorldRank,
    required this.totalSeasonWins,
    required this.uciPoints,
    this.managerTitle = 'Dyrektor Sportowy',
    this.seasonHighlightNote,
    this.grandTourWins = const [],
    this.monumentWins = const [],
    this.headlineTransfers = const [],
  });

  double? get budgetDeltaPercent {
    final prev = previousYearBudgetEur;
    if (prev == null || prev <= 0) return null;
    return ((budgetEur - prev) / prev) * 100.0;
  }

  bool get hasMajorTrophy => grandTourWins.isNotEmpty || monumentWins.isNotEmpty;

  bool matchesFilter(CareerTimelineFilter filter) {
    switch (filter) {
      case CareerTimelineFilter.all:
        return true;
      case CareerTimelineFilter.grandTours:
        return grandTourWins.isNotEmpty;
      case CareerTimelineFilter.monuments:
        return monumentWins.isNotEmpty;
      case CareerTimelineFilter.transfers:
        return headlineTransfers.isNotEmpty;
      case CareerTimelineFilter.teamChanges:
        return isTeamSwitchYear;
    }
  }
}

/// Zbiorcze statystyki kariery obliczone na podstawie listy sezonów.
class CareerTimelineAggregateStats {
  final int totalSeasons;
  final int distinctTeamsCount;
  final int totalGrandTours;
  final int totalMonuments;
  final int totalSeasonWins;
  final double peakBudgetEur;
  final double latestBudgetEur;
  final double biggestTransferFeeEur;
  final String biggestTransferSummary;

  const CareerTimelineAggregateStats({
    required this.totalSeasons,
    required this.distinctTeamsCount,
    required this.totalGrandTours,
    required this.totalMonuments,
    required this.totalSeasonWins,
    required this.peakBudgetEur,
    required this.latestBudgetEur,
    required this.biggestTransferFeeEur,
    required this.biggestTransferSummary,
  });
}

/// Kalkulator podsumowań i generator przykładowej wieloletniej historii kariery.
class CareerTimelineAnalytics {
  CareerTimelineAnalytics._();

  static CareerTimelineAggregateStats summarize(
    List<CareerSeasonHistoryEntry> seasons,
  ) {
    if (seasons.isEmpty) {
      return const CareerTimelineAggregateStats(
        totalSeasons: 0,
        distinctTeamsCount: 0,
        totalGrandTours: 0,
        totalMonuments: 0,
        totalSeasonWins: 0,
        peakBudgetEur: 0,
        latestBudgetEur: 0,
        biggestTransferFeeEur: 0,
        biggestTransferSummary: 'Brak transferów',
      );
    }

    final sorted = List<CareerSeasonHistoryEntry>.from(seasons)
      ..sort((a, b) => a.seasonYear.compareTo(b.seasonYear));

    final teams = <String>{};
    int gtCount = 0;
    int monumentCount = 0;
    int totalWins = 0;
    double peakBudget = 0;
    double biggestFee = -1;
    String biggestSummary = 'Brak transferów';

    for (final season in sorted) {
      teams.add(season.teamName);
      gtCount += season.grandTourWins.length;
      monumentCount += season.monumentWins.length;
      totalWins += math.max(0, season.totalSeasonWins);
      if (season.budgetEur > peakBudget) {
        peakBudget = season.budgetEur;
      }
      for (final transfer in season.headlineTransfers) {
        if (transfer.feeEur > biggestFee) {
          biggestFee = transfer.feeEur;
          biggestSummary = '${transfer.riderName} (${season.seasonYear})';
        }
      }
    }

    return CareerTimelineAggregateStats(
      totalSeasons: sorted.length,
      distinctTeamsCount: teams.length,
      totalGrandTours: gtCount,
      totalMonuments: monumentCount,
      totalSeasonWins: totalWins,
      peakBudgetEur: peakBudget,
      latestBudgetEur: sorted.last.budgetEur,
      biggestTransferFeeEur: biggestFee < 0 ? 0 : biggestFee,
      biggestTransferSummary: biggestSummary,
    );
  }

  static String formatCompactEuro(double amountEur) {
    if (amountEur.isNaN || amountEur.isInfinite || amountEur <= 0) {
      return '€0';
    }
    if (amountEur >= 1000000) {
      final millions = amountEur / 1000000.0;
      return '€${millions.toStringAsFixed(millions >= 10 ? 1 : 2)}M';
    }
    if (amountEur >= 1000) {
      return '€${(amountEur / 1000.0).toStringAsFixed(0)}k';
    }
    return Formatters.formatCurrency(amountEur);
  }

  static List<CareerSeasonHistoryEntry> defaultDemoHistory() {
    return const [
      CareerSeasonHistoryEntry(
        seasonYear: 2026,
        teamName: 'Veloce Polska ProTeam',
        teamShortCode: 'VPL',
        teamDivision: 'UCI ProTeam',
        teamPrimaryColor: Color(0xFF8E4A49),
        teamSecondaryColor: Color(0xFFF3F4F6),
        isTeamSwitchYear: true,
        budgetEur: 6800000,
        uciWorldRank: 19,
        totalSeasonWins: 14,
        uciPoints: 4120,
        managerTitle: 'Dyrektor Sportowy',
        seasonHighlightNote:
            'Debiutancki sezon z dziką kartą na Giro d\'Italia i awans do Top 20 UCI.',
        headlineTransfers: [
          CareerHeadlineTransferEntry(
            riderName: 'Kacper Zieliński',
            direction: CareerTransferDirection.incoming,
            otherTeamName: 'Nordic Aero Cycling',
            feeEur: 620000,
            overallRating: 82,
            roleLabel: 'Lider GC',
          ),
          CareerHeadlineTransferEntry(
            riderName: 'Marek Kowalczyk',
            direction: CareerTransferDirection.academyPromotion,
            otherTeamName: 'Veloce U23 Academy',
            feeEur: 0,
            overallRating: 76,
            roleLabel: 'Góral',
          ),
        ],
      ),
      CareerSeasonHistoryEntry(
        seasonYear: 2027,
        teamName: 'Veloce Polska WorldTeam',
        teamShortCode: 'VPL',
        teamDivision: 'UCI WorldTour',
        teamPrimaryColor: Color(0xFF8E4A49),
        teamSecondaryColor: Color(0xFFD4AF37),
        isTeamSwitchYear: false,
        budgetEur: 12400000,
        previousYearBudgetEur: 6800000,
        uciWorldRank: 11,
        totalSeasonWins: 24,
        uciPoints: 8950,
        managerTitle: 'General Manager',
        seasonHighlightNote:
            'Historyczne wejście do WorldTour i pierwsze zwycięstwo w Monumencie.',
        monumentWins: [
          CareerMonumentWinEntry(
            monumentType: CareerMonumentType.ilLombardia,
            riderName: 'Kacper Zieliński',
            finishMethod: 'Atak solo na Madonna del Ghisallo',
          ),
        ],
        headlineTransfers: [
          CareerHeadlineTransferEntry(
            riderName: 'Luca Moretti',
            direction: CareerTransferDirection.incoming,
            otherTeamName: 'Emirates Horizon',
            feeEur: 1450000,
            overallRating: 86,
            roleLabel: 'Sprinter',
          ),
        ],
      ),
      CareerSeasonHistoryEntry(
        seasonYear: 2028,
        teamName: 'Alpine Apex Cycling',
        teamShortCode: 'AAC',
        teamDivision: 'UCI WorldTour',
        teamPrimaryColor: Color(0xFF1D4ED8),
        teamSecondaryColor: Color(0xFF38BDF8),
        isTeamSwitchYear: true,
        budgetEur: 24500000,
        previousYearBudgetEur: 12400000,
        uciWorldRank: 4,
        totalSeasonWins: 39,
        uciPoints: 14820,
        managerTitle: 'General Manager',
        seasonHighlightNote:
            'Przejęcie czołowej ekipy alpejskiej i triumf w La Vuelta a España.',
        grandTourWins: [
          CareerGrandTourWinEntry(
            tourType: CareerGrandTourType.vueltaAEspana,
            riderName: 'Matteo Bernardi',
            stageWinsCount: 4,
            winningMarginSeconds: 102,
            additionalJerseys: ['KOM'],
          ),
        ],
        monumentWins: [
          CareerMonumentWinEntry(
            monumentType: CareerMonumentType.liegeBastogneLiege,
            riderName: 'Matteo Bernardi',
            finishMethod: 'Sprint z 3-osobowej czołówki',
          ),
        ],
        headlineTransfers: [
          CareerHeadlineTransferEntry(
            riderName: 'Matteo Bernardi',
            direction: CareerTransferDirection.incoming,
            otherTeamName: 'Iberia Movistar Pro',
            feeEur: 3200000,
            overallRating: 91,
            roleLabel: 'Lider GC',
          ),
          CareerHeadlineTransferEntry(
            riderName: 'Jonas Van Dijk',
            direction: CareerTransferDirection.outgoing,
            otherTeamName: 'Flanders Cobble Team',
            feeEur: 1900000,
            overallRating: 85,
            roleLabel: 'Klasykowiec',
          ),
        ],
      ),
      CareerSeasonHistoryEntry(
        seasonYear: 2029,
        teamName: 'Alpine Apex Cycling',
        teamShortCode: 'AAC',
        teamDivision: 'UCI WorldTour',
        teamPrimaryColor: Color(0xFF1D4ED8),
        teamSecondaryColor: Color(0xFFD4AF37),
        isTeamSwitchYear: false,
        budgetEur: 29800000,
        previousYearBudgetEur: 24500000,
        uciWorldRank: 2,
        totalSeasonWins: 47,
        uciPoints: 18440,
        managerTitle: 'General Manager',
        seasonHighlightNote:
            'Złoty dublet: Giro d\'Italia oraz Paris-Roubaix w jednym sezonie.',
        grandTourWins: [
          CareerGrandTourWinEntry(
            tourType: CareerGrandTourType.giroDItalia,
            riderName: 'Matteo Bernardi',
            stageWinsCount: 5,
            winningMarginSeconds: 164,
            additionalJerseys: ['Maglia Rosa', 'Points'],
          ),
        ],
        monumentWins: [
          CareerMonumentWinEntry(
            monumentType: CareerMonumentType.parisRoubaix,
            riderName: 'Wout Vermeer',
            finishMethod: 'Odjazd na Carrefour de l\'Arbre',
          ),
          CareerMonumentWinEntry(
            monumentType: CareerMonumentType.milanoSanremo,
            riderName: 'Luca Moretti',
            finishMethod: 'Atak z Poggio + sprint na Via Roma',
          ),
        ],
        headlineTransfers: [
          CareerHeadlineTransferEntry(
            riderName: 'Wout Vermeer',
            direction: CareerTransferDirection.incoming,
            otherTeamName: 'Lowlands Lotto',
            feeEur: 2850000,
            overallRating: 90,
            roleLabel: 'Bruk / Czasówka',
          ),
        ],
      ),
      CareerSeasonHistoryEntry(
        seasonYear: 2030,
        teamName: 'Alpine Apex Cycling',
        teamShortCode: 'AAC',
        teamDivision: 'UCI WorldTour',
        teamPrimaryColor: Color(0xFF1D4ED8),
        teamSecondaryColor: Color(0xFFD4AF37),
        isTeamSwitchYear: false,
        budgetEur: 34200000,
        previousYearBudgetEur: 29800000,
        uciWorldRank: 1,
        totalSeasonWins: 56,
        uciPoints: 21900,
        managerTitle: 'Dyrektor Generalny',
        seasonHighlightNote:
            'Zdobycie upragnionej Żółtej Koszulki Tour de France i nr 1 rankingu UCI.',
        grandTourWins: [
          CareerGrandTourWinEntry(
            tourType: CareerGrandTourType.tourDeFrance,
            riderName: 'Matteo Bernardi',
            stageWinsCount: 6,
            winningMarginSeconds: 218,
            additionalJerseys: ['Maillot Jaune', 'KOM'],
          ),
        ],
        monumentWins: [
          CareerMonumentWinEntry(
            monumentType: CareerMonumentType.rondeVanVlaanderen,
            riderName: 'Wout Vermeer',
            finishMethod: 'Solo na Oude Kwaremont',
          ),
        ],
        headlineTransfers: [
          CareerHeadlineTransferEntry(
            riderName: 'Théo Moreau',
            direction: CareerTransferDirection.incoming,
            otherTeamName: 'Gaul Aero Squad',
            feeEur: 4100000,
            overallRating: 89,
            roleLabel: 'Super-Pomocnik GC',
          ),
        ],
      ),
    ];
  }
}

/// Interaktywna oś czasu kariery menedżera pokazująca rok po roku prowadzone zespoły,
/// budżety, wygrane Wielkie Toury, Monumenty i największe transfery.
class InteractiveCareerTimelineHistoryWidget extends StatefulWidget {
  final List<CareerSeasonHistoryEntry> seasons;
  final String managerName;
  final int? initialSelectedYear;
  final ValueChanged<CareerSeasonHistoryEntry>? onSeasonSelected;
  final ValueChanged<CareerHeadlineTransferEntry>? onTransferTap;

  const InteractiveCareerTimelineHistoryWidget({
    super.key,
    required this.seasons,
    this.managerName = 'Dyrektor Sportowy',
    this.initialSelectedYear,
    this.onSeasonSelected,
    this.onTransferTap,
  });

  @override
  State<InteractiveCareerTimelineHistoryWidget> createState() =>
      _InteractiveCareerTimelineHistoryWidgetState();
}

class _InteractiveCareerTimelineHistoryWidgetState
    extends State<InteractiveCareerTimelineHistoryWidget> {
  CareerTimelineFilter _activeFilter = CareerTimelineFilter.all;
  bool _sortNewestFirst = false;
  late int? _selectedYear;
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedYear = _resolveInitialSelectedYear();
  }

  @override
  void didUpdateWidget(
    covariant InteractiveCareerTimelineHistoryWidget oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seasons != widget.seasons ||
        oldWidget.initialSelectedYear != widget.initialSelectedYear) {
      final filtered = _filteredSeasons();
      if (filtered.isEmpty) {
        _selectedYear = null;
      } else if (_selectedYear == null ||
          !filtered.any((s) => s.seasonYear == _selectedYear)) {
        _selectedYear = _resolveInitialSelectedYear();
      }
    }
  }

  @override
  void dispose() {
    _timelineScrollController.dispose();
    super.dispose();
  }

  int? _resolveInitialSelectedYear() {
    if (widget.seasons.isEmpty) return null;
    if (widget.initialSelectedYear != null &&
        widget.seasons.any((s) => s.seasonYear == widget.initialSelectedYear)) {
      return widget.initialSelectedYear;
    }
    final sorted = List<CareerSeasonHistoryEntry>.from(widget.seasons)
      ..sort((a, b) => a.seasonYear.compareTo(b.seasonYear));
    return sorted.last.seasonYear;
  }

  List<CareerSeasonHistoryEntry> _filteredSeasons() {
    final list = widget.seasons
        .where((s) => s.matchesFilter(_activeFilter))
        .toList();
    list.sort(
      (a, b) => _sortNewestFirst
          ? b.seasonYear.compareTo(a.seasonYear)
          : a.seasonYear.compareTo(b.seasonYear),
    );
    return list;
  }

  void _selectSeason(CareerSeasonHistoryEntry season) {
    setState(() {
      _selectedYear = season.seasonYear;
    });
    widget.onSeasonSelected?.call(season);
  }

  void _setFilter(CareerTimelineFilter filter) {
    setState(() {
      _activeFilter = filter;
      final filtered = _filteredSeasons();
      if (filtered.isEmpty) {
        _selectedYear = null;
      } else if (_selectedYear == null ||
          !filtered.any((s) => s.seasonYear == _selectedYear)) {
        _selectedYear = filtered.last.seasonYear;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = CareerTimelineAnalytics.summarize(widget.seasons);
    final filteredSeasons = _filteredSeasons();
    final selectedSeason = filteredSeasons.isEmpty
        ? null
        : filteredSeasons.firstWhere(
            (s) => s.seasonYear == _selectedYear,
            orElse: () => filteredSeasons.first,
          );
    final selectedIndex = selectedSeason == null
        ? -1
        : filteredSeasons.indexWhere(
            (s) => s.seasonYear == selectedSeason.seasonYear,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1200;
        final bool isCompact = width < 640;
        final bool isWide = width >= 1120;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2F3D), width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact, stats),
              const SizedBox(height: 16),
              _buildKpiRow(isCompact, isWide, stats),
              const SizedBox(height: 16),
              _buildControlsBar(
                isCompact: isCompact,
                filteredSeasons: filteredSeasons,
                selectedIndex: selectedIndex,
              ),
              const SizedBox(height: 16),
              if (widget.seasons.isEmpty)
                _buildEmptyState(
                  title: 'Brak zapisanych sezonów kariery',
                  subtitle:
                      'Ukończ pierwszy sezon w trybie kariery, aby oś czasu zarejestrowała Twoje zespoły, budżety i trofea.',
                )
              else if (filteredSeasons.isEmpty)
                _buildEmptyState(
                  title: 'Brak sezonów pasujących do filtra',
                  subtitle:
                      'Zmień aktywny filtr lub wyczyść kryteria, aby zobaczyć pełną historię kariery.',
                  actionLabel: 'Pokaż wszystkie sezony',
                  onAction: () => _setFilter(CareerTimelineFilter.all),
                )
              else ...[
                _buildTimelineRail(
                  filteredSeasons: filteredSeasons,
                  selectedSeason: selectedSeason!,
                  peakBudgetEur: stats.peakBudgetEur,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                _buildBudgetComparisonStrip(
                  seasons: filteredSeasons,
                  selectedYear: selectedSeason.seasonYear,
                  peakBudgetEur: stats.peakBudgetEur,
                  isCompact: isCompact,
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _SeasonDetailPanel(
                    key: ValueKey<int>(selectedSeason.seasonYear),
                    season: selectedSeason,
                    peakBudgetEur: stats.peakBudgetEur,
                    isCompact: isCompact,
                    isWide: isWide,
                    onTransferTap: widget.onTransferTap,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact, CareerTimelineAggregateStats stats) {
    final String spanText = widget.seasons.isEmpty
        ? 'Brak danych historycznych'
        : '${widget.seasons.map((s) => s.seasonYear).reduce(math.min)}–'
            '${widget.seasons.map((s) => s.seasonYear).reduce(math.max)} · '
            '${stats.totalSeasons} ${_polishSeasonsLabel(stats.totalSeasons)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isCompact ? 40 : 46,
          height: isCompact ? 40 : 46,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.history_edu_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OŚ CZASU KARIERY MENEDŻERA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.managerName} · $spanText',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(
    bool isCompact,
    bool isWide,
    CareerTimelineAggregateStats stats,
  ) {
    final cards = [
      _KpiSummaryTile(
        label: 'Zespoły',
        value: '${stats.distinctTeamsCount}',
        subtitle: '${stats.totalSeasonWins} zwycięstw łącznie',
        accentColor: AppColors.primaryAccent,
        icon: Icons.groups_rounded,
      ),
      _KpiSummaryTile(
        label: 'Wielkie Toury',
        value: '${stats.totalGrandTours}',
        subtitle: 'TDF / Giro / Vuelta GC',
        accentColor: AppColors.goldAccent,
        icon: Icons.emoji_events_rounded,
      ),
      _KpiSummaryTile(
        label: 'Monumenty',
        value: '${stats.totalMonuments}',
        subtitle: '5 klasyków królewskich',
        accentColor: AppColors.accentBlue,
        icon: Icons.workspace_premium_rounded,
      ),
      _KpiSummaryTile(
        label: 'Szczytowy Budżet',
        value: CareerTimelineAnalytics.formatCompactEuro(stats.peakBudgetEur),
        subtitle: stats.biggestTransferFeeEur > 0
            ? 'Max transfer: ${CareerTimelineAnalytics.formatCompactEuro(stats.biggestTransferFeeEur)}'
            : stats.biggestTransferSummary,
        accentColor: AppColors.statusSuccess,
        icon: Icons.account_balance_wallet_rounded,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isCompact ? 1.75 : 2.55,
      children: cards,
    );
  }

  Widget _buildControlsBar({
    required bool isCompact,
    required List<CareerSeasonHistoryEntry> filteredSeasons,
    required int selectedIndex,
  }) {
    final bool canGoPrev = selectedIndex > 0;
    final bool canGoNext =
        selectedIndex >= 0 && selectedIndex < filteredSeasons.length - 1;

    final filterStrip = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CareerTimelineFilter.values.map((filter) {
          final bool isSelected = _activeFilter == filter;
          final int matchCount = widget.seasons
              .where((s) => s.matchesFilter(filter))
              .length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _InteractivePillButton(
              label: '${filter.label} ($matchCount)',
              icon: filter.icon,
              isSelected: isSelected,
              accentColor: filter == CareerTimelineFilter.grandTours
                  ? AppColors.goldAccent
                  : filter == CareerTimelineFilter.monuments
                      ? AppColors.accentBlue
                      : AppColors.primaryAccent,
              onPressed: () => _setFilter(filter),
            ),
          );
        }).toList(),
      ),
    );

    final navControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InteractivePillButton(
          label: _sortNewestFirst ? 'Najnowsze' : 'Chronologicznie',
          icon: Icons.swap_vert_rounded,
          isSelected: _sortNewestFirst,
          accentColor: AppColors.cyanAccent,
          onPressed: widget.seasons.length < 2
              ? null
              : () => setState(() => _sortNewestFirst = !_sortNewestFirst),
        ),
        const SizedBox(width: 8),
        _InteractiveIconStepButton(
          tooltip: 'Poprzedni sezon',
          icon: Icons.chevron_left_rounded,
          onPressed: canGoPrev
              ? () => _selectSeason(filteredSeasons[selectedIndex - 1])
              : null,
        ),
        const SizedBox(width: 6),
        _InteractiveIconStepButton(
          tooltip: 'Następny sezon',
          icon: Icons.chevron_right_rounded,
          onPressed: canGoNext
              ? () => _selectSeason(filteredSeasons[selectedIndex + 1])
              : null,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filterStrip,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: navControls),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: filterStrip),
        const SizedBox(width: 12),
        navControls,
      ],
    );
  }

  Widget _buildTimelineRail({
    required List<CareerSeasonHistoryEntry> filteredSeasons,
    required CareerSeasonHistoryEntry selectedSeason,
    required double peakBudgetEur,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: SizedBox(
        height: isCompact ? 132 : 140,
        child: ListView.separated(
          controller: _timelineScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: filteredSeasons.length,
          separatorBuilder: (_, __) => Center(
            child: Container(
              width: isCompact ? 20 : 32,
              height: 2,
              color: const Color(0xFF2A2F3D),
            ),
          ),
          itemBuilder: (context, index) {
            final season = filteredSeasons[index];
            final bool isSelected =
                season.seasonYear == selectedSeason.seasonYear;
            return _TimelineYearNodeCard(
              season: season,
              isSelected: isSelected,
              peakBudgetEur: peakBudgetEur,
              compact: isCompact,
              onTap: () => _selectSeason(season),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBudgetComparisonStrip({
    required List<CareerSeasonHistoryEntry> seasons,
    required int selectedYear,
    required double peakBudgetEur,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 16,
                color: AppColors.statusSuccess,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dynamika budżetu i zdobytych trofeów rok po roku',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Peak: ${CareerTimelineAnalytics.formatCompactEuro(peakBudgetEur)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: _BudgetSparklinePainter(
                seasons: seasons,
                selectedYear: selectedYear,
                peakBudgetEur: peakBudgetEur,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timeline_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            _InteractivePillButton(
              label: actionLabel,
              icon: Icons.refresh_rounded,
              isSelected: true,
              accentColor: AppColors.goldAccent,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }

  String _polishSeasonsLabel(int count) {
    if (count == 1) return 'sezon';
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'sezony';
    }
    return 'sezonów';
  }
}

class _KpiSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const _KpiSummaryTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
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

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _InteractivePillButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    final Color borderColor = isDisabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.isSelected
                ? widget.accentColor
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.6)
                    : const Color(0xFF2A2F3D);

    final Color bgColor = isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: _pressed ? 0.3 : 0.2)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 14,
                    color: isDisabled
                        ? AppColors.textSecondary.withValues(alpha: 0.4)
                        : widget.isSelected
                            ? widget.accentColor
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isDisabled
                          ? AppColors.textSecondary.withValues(alpha: 0.4)
                          : widget.isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveIconStepButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _InteractiveIconStepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconStepButton> createState() =>
      _InteractiveIconStepButtonState();
}

class _InteractiveIconStepButtonState
    extends State<_InteractiveIconStepButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: !isDisabled,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: MouseRegion(
          cursor: isDisabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown:
                isDisabled ? null : (_) => setState(() => _pressed = true),
            onTapUp:
                isDisabled ? null : (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDisabled
                    ? AppColors.surfaceLight.withValues(alpha: 0.3)
                    : _pressed
                        ? AppColors.primaryAccent.withValues(alpha: 0.3)
                        : _hovered
                            ? AppColors.surfaceLight
                            : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : _hovered && !isDisabled
                          ? AppColors.goldAccent.withValues(alpha: 0.55)
                          : const Color(0xFF2A2F3D),
                ),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: isDisabled
                    ? AppColors.textSecondary.withValues(alpha: 0.35)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineYearNodeCard extends StatefulWidget {
  final CareerSeasonHistoryEntry season;
  final bool isSelected;
  final double peakBudgetEur;
  final bool compact;
  final VoidCallback onTap;

  const _TimelineYearNodeCard({
    required this.season,
    required this.isSelected,
    required this.peakBudgetEur,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_TimelineYearNodeCard> createState() => _TimelineYearNodeCardState();
}

class _TimelineYearNodeCardState extends State<_TimelineYearNodeCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final season = widget.season;
    final bool hasGt = season.grandTourWins.isNotEmpty;
    final bool hasMonument = season.monumentWins.isNotEmpty;
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent
            : _hovered
                ? season.teamPrimaryColor.withValues(alpha: 0.9)
                : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: widget.compact ? 148 : 168,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.surfaceLight
                    : _hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.7)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected || _focused ? 1.5 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: season.teamPrimaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: season.teamSecondaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${season.seasonYear}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: widget.isSelected
                              ? AppColors.goldAccent
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (season.isTeamSwitchYear)
                        const Tooltip(
                          message: 'Nowy zespół',
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            size: 14,
                            color: AppColors.cyanAccent,
                          ),
                        ),
                      if (hasGt) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: AppColors.goldAccent,
                        ),
                      ],
                      if (hasMonument) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: AppColors.accentBlue,
                        ),
                      ],
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CareerTimelineAnalytics.formatCompactEuro(season.budgetEur)} · UCI #${season.uciWorldRank}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _MiniTag(
                        text: '${season.totalSeasonWins} zw.',
                        color: AppColors.statusSuccess,
                      ),
                      if (season.headlineTransfers.isNotEmpty)
                        _MiniTag(
                          text: '${season.headlineTransfers.length} transf.',
                          color: AppColors.amberWarning,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: color,
        ),
      ),
    );
  }
}

class _BudgetSparklinePainter extends CustomPainter {
  final List<CareerSeasonHistoryEntry> seasons;
  final int selectedYear;
  final double peakBudgetEur;

  _BudgetSparklinePainter({
    required this.seasons,
    required this.selectedYear,
    required this.peakBudgetEur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (seasons.isEmpty || size.width <= 0 || size.height <= 0) return;

    final double safePeak = peakBudgetEur <= 0 ? 1.0 : peakBudgetEur;
    const double topPad = 8;
    const double bottomPad = 18;
    final double usableHeight = math.max(8.0, size.height - topPad - bottomPad);

    final gridPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, topPad + usableHeight),
      Offset(size.width, topPad + usableHeight),
      gridPaint,
    );

    final int count = seasons.length;
    final List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final double x = count == 1
          ? size.width / 2
          : (i / (count - 1)) * (size.width - 28) + 14;
      final double ratio = (seasons[i].budgetEur / safePeak).clamp(0.0, 1.0);
      final double y = topPad + usableHeight * (1.0 - ratio);
      points.add(Offset(x, y));
    }

    if (points.length >= 2) {
      final areaPath = Path()..moveTo(points.first.dx, topPad + usableHeight);
      for (final p in points) {
        areaPath.lineTo(p.dx, p.dy);
      }
      areaPath.lineTo(points.last.dx, topPad + usableHeight);
      areaPath.close();

      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.statusSuccess.withValues(alpha: 0.28),
            AppColors.statusSuccess.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, usableHeight));
      canvas.drawPath(areaPath, areaPaint);

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      final linePaint = Paint()
        ..color = AppColors.statusSuccess
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);
    }

    for (int i = 0; i < count; i++) {
      final season = seasons[i];
      final p = points[i];
      final bool isSelected = season.seasonYear == selectedYear;

      final dotPaint = Paint()
        ..color = isSelected
            ? AppColors.goldAccent
            : season.hasMajorTrophy
                ? AppColors.accentBlue
                : AppColors.statusSuccess;
      canvas.drawCircle(p, isSelected ? 5.0 : 3.5, dotPaint);

      if (isSelected) {
        final ringPaint = Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(p, 8.0, ringPaint);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '${season.seasonYear}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          (p.dx - tp.width / 2).clamp(0.0, math.max(0.0, size.width - tp.width)),
          topPad + usableHeight + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetSparklinePainter oldDelegate) {
    return oldDelegate.seasons != seasons ||
        oldDelegate.selectedYear != selectedYear ||
        oldDelegate.peakBudgetEur != peakBudgetEur;
  }
}

class _SeasonDetailPanel extends StatelessWidget {
  final CareerSeasonHistoryEntry season;
  final double peakBudgetEur;
  final bool isCompact;
  final bool isWide;
  final ValueChanged<CareerHeadlineTransferEntry>? onTransferTap;

  const _SeasonDetailPanel({
    super.key,
    required this.season,
    required this.peakBudgetEur,
    required this.isCompact,
    required this.isWide,
    this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamAndBudgetCard = _TeamAndBudgetDetailCard(
      season: season,
      peakBudgetEur: peakBudgetEur,
    );
    final trophiesCard = _TrophiesDetailCard(season: season);
    final transfersCard = _TransfersDetailCard(
      season: season,
      onTransferTap: onTransferTap,
    );

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: teamAndBudgetCard),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: trophiesCard),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: transfersCard),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        teamAndBudgetCard,
        const SizedBox(height: 12),
        if (isCompact) ...[
          trophiesCard,
          const SizedBox(height: 12),
          transfersCard,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: trophiesCard),
              const SizedBox(width: 12),
              Expanded(child: transfersCard),
            ],
          ),
      ],
    );
  }
}

class _TeamAndBudgetDetailCard extends StatelessWidget {
  final CareerSeasonHistoryEntry season;
  final double peakBudgetEur;

  const _TeamAndBudgetDetailCard({
    required this.season,
    required this.peakBudgetEur,
  });

  @override
  Widget build(BuildContext context) {
    final double? deltaPct = season.budgetDeltaPercent;
    final double ratioToPeak = peakBudgetEur > 0
        ? (season.budgetEur / peakBudgetEur).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      season.teamPrimaryColor,
                      season.teamSecondaryColor.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.25),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  season.teamShortCode,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEZON ${season.seasonYear} · ${season.teamDivision}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      season.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _DetailBadge(
                label: 'Rola: ${season.managerTitle}',
                color: AppColors.textSecondary,
              ),
              _DetailBadge(
                label: 'UCI #${season.uciWorldRank}',
                color: AppColors.accentBlue,
              ),
              _DetailBadge(
                label: '${season.totalSeasonWins} zwycięstw',
                color: AppColors.statusSuccess,
              ),
              _DetailBadge(
                label: '${season.uciPoints} pkt UCI',
                color: AppColors.goldAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2F3D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Budżet roczny zespołu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (deltaPct != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (deltaPct >= 0
                                  ? AppColors.statusSuccess
                                  : AppColors.crimsonAlert)
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${deltaPct >= 0 ? '+' : ''}${deltaPct.toStringAsFixed(1)}% r/r',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: deltaPct >= 0
                                ? AppColors.statusSuccess
                                : AppColors.crimsonAlert,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  CareerTimelineAnalytics.formatCompactEuro(season.budgetEur),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratioToPeak,
                    minHeight: 6,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.statusSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (season.seasonHighlightNote != null &&
              season.seasonHighlightNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              season.seasonHighlightNote!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrophiesDetailCard extends StatelessWidget {
  final CareerSeasonHistoryEntry season;

  const _TrophiesDetailCard({required this.season});

  @override
  Widget build(BuildContext context) {
    final bool hasAnyTrophy =
        season.grandTourWins.isNotEmpty || season.monumentWins.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 17,
                color: AppColors.goldAccent,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'WIELKIE TOURY I MONUMENTY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasAnyTrophy)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'W tym sezonie zespół nie sięgnął po klasyfikację generalną Wielkiego Touru ani po Monument.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else ...[
            for (final gt in season.grandTourWins) ...[
              _GrandTourTrophyTile(entry: gt),
              const SizedBox(height: 8),
            ],
            for (final monument in season.monumentWins) ...[
              _MonumentTrophyTile(entry: monument),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _GrandTourTrophyTile extends StatelessWidget {
  final CareerGrandTourWinEntry entry;

  const _GrandTourTrophyTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final String marginText = entry.winningMarginSeconds == null
        ? '${entry.stageWinsCount} et.'
        : '${entry.stageWinsCount} et. · przewaga ${Formatters.formatTimeGap(entry.winningMarginSeconds!, showPlusSign: false)}';

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.tourType.jerseyColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: entry.tourType.jerseyColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              entry.tourType.shortCode,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: entry.tourType.jerseyColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.tourType.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.riderName} ($marginText)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (entry.additionalJerseys.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: entry.additionalJerseys
                        .map(
                          (jersey) => _MiniTag(
                            text: jersey,
                            color: AppColors.goldAccent,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonumentTrophyTile extends StatelessWidget {
  final CareerMonumentWinEntry entry;

  const _MonumentTrophyTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.monumentType.accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: entry.monumentType.accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              entry.monumentType.shortCode,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: entry.monumentType.accentColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.monumentType.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.riderName} · ${entry.finishMethod}',
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
        ],
      ),
    );
  }
}

class _TransfersDetailCard extends StatelessWidget {
  final CareerSeasonHistoryEntry season;
  final ValueChanged<CareerHeadlineTransferEntry>? onTransferTap;

  const _TransfersDetailCard({
    required this.season,
    this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                size: 17,
                color: AppColors.amberWarning,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NAJWIĘKSZE TRANSFERY SEZONU',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (season.headlineTransfers.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Brak kluczowych ruchów transferowych odnotowanych w tym sezonie.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            for (final transfer in season.headlineTransfers) ...[
              _TransferEntryTile(
                transfer: transfer,
                onTap: onTransferTap == null
                    ? null
                    : () => onTransferTap!(transfer),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _TransferEntryTile extends StatefulWidget {
  final CareerHeadlineTransferEntry transfer;
  final VoidCallback? onTap;

  const _TransferEntryTile({
    required this.transfer,
    this.onTap,
  });

  @override
  State<_TransferEntryTile> createState() => _TransferEntryTileState();
}

class _TransferEntryTileState extends State<_TransferEntryTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final transfer = widget.transfer;
    final bool interactive = widget.onTap != null;
    final String feeText = transfer.feeEur <= 0
        ? 'Bez odstępnego'
        : CareerTimelineAnalytics.formatCompactEuro(transfer.feeEur);

    return FocusableActionDetector(
      enabled: interactive,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: MouseRegion(
        cursor:
            interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _hovered && interactive
                  ? AppColors.surfaceLight.withValues(alpha: 0.95)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : _hovered && interactive
                        ? transfer.direction.color.withValues(alpha: 0.65)
                        : const Color(0xFF2A2F3D),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: transfer.direction.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    transfer.direction.icon,
                    size: 16,
                    color: transfer.direction.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transfer.riderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _MiniTag(
                            text: 'OVR ${transfer.overallRating}',
                            color: AppColors.goldAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${transfer.direction.label} · ${transfer.otherTeamName} · ${transfer.roleLabel}',
                        maxLines: 1,
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
                Text(
                  feeText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: transfer.direction.color,
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

class _DetailBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: color,
        ),
      ),
    );
  }
}
