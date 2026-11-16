import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/career/legendary_historic_scenarios_seeder.dart';

/// Filtr widoku listy scenariuszy na ekranie Wyzwań Taktycznych.
enum TacticalChallengeFilter {
  all,
  veteran,
  legend,
  impossible,
  completed,
  uncompleted;

  String get label {
    switch (this) {
      case TacticalChallengeFilter.all:
        return 'Wszystkie (10)';
      case TacticalChallengeFilter.veteran:
        return 'Weteran';
      case TacticalChallengeFilter.legend:
        return 'Legenda';
      case TacticalChallengeFilter.impossible:
        return 'Hors Catégorie';
      case TacticalChallengeFilter.completed:
        return 'Ukończone';
      case TacticalChallengeFilter.uncompleted:
        return 'Nieukończone';
    }
  }
}

/// Progi czasowe medali (w sekundach) dla pojedynczego scenariusza.
class TacticalChallengeMedalTargets {
  final int bronzeTargetSeconds;
  final int silverTargetSeconds;
  final int goldTargetSeconds;

  const TacticalChallengeMedalTargets({
    required this.bronzeTargetSeconds,
    required this.silverTargetSeconds,
    required this.goldTargetSeconds,
  });

  /// Wylicza deterministyczne progi czasowe na podstawie dystansu i trudności.
  factory TacticalChallengeMedalTargets.forScenario(
    HistoricScenarioDefinition scenario,
  ) {
    final avgSpeedKmh = switch (scenario.category) {
      HistoricScenarioCategory.flatTimeTrial => 51.5,
      HistoricScenarioCategory.sprintChaos => 46.5,
      HistoricScenarioCategory.echelonChase => 45.0,
      HistoricScenarioCategory.crosswindAndCobbles => 42.5,
      HistoricScenarioCategory.gravelMonument => 40.0,
      HistoricScenarioCategory.mountainTimeTrial => 33.5,
      HistoricScenarioCategory.satelliteRelay => 36.0,
      HistoricScenarioCategory.alpineStormRaid => 32.0,
      HistoricScenarioCategory.bonkDefense => 24.5,
      HistoricScenarioCategory.extremeWallClimb => 21.0,
    };

    final baseSeconds =
        ((scenario.playableDistanceKm / avgSpeedKmh) * 3600.0).round();
    final difficultySpread = switch (scenario.difficulty) {
      HistoricScenarioDifficulty.veteran => 45,
      HistoricScenarioDifficulty.legend => 35,
      HistoricScenarioDifficulty.impossible => 25,
    };

    return TacticalChallengeMedalTargets(
      goldTargetSeconds: baseSeconds,
      silverTargetSeconds: baseSeconds + difficultySpread,
      bronzeTargetSeconds: baseSeconds + difficultySpread * 2,
    );
  }
}

/// Rekord najlepszego czasu i medalu gracza dla pojedynczego scenariusza.
class ChallengePlayerRecord {
  final String scenarioId;
  final int bestTimeSeconds;
  final ScenarioMedalTier medal;
  final int bestScorePoints;
  final int attemptsCount;
  final String leaderRiderName;
  final DateTime achievedAt;

  const ChallengePlayerRecord({
    required this.scenarioId,
    required this.bestTimeSeconds,
    required this.medal,
    required this.bestScorePoints,
    required this.attemptsCount,
    required this.leaderRiderName,
    required this.achievedAt,
  });

  Map<String, dynamic> toJson() => {
        'scenarioId': scenarioId,
        'bestTimeSeconds': bestTimeSeconds,
        'medal': medal.name,
        'bestScorePoints': bestScorePoints,
        'attemptsCount': attemptsCount,
        'leaderRiderName': leaderRiderName,
        'achievedAt': achievedAt.toIso8601String(),
      };

  factory ChallengePlayerRecord.fromJson(Map<String, dynamic> json) {
    final medalName = json['medal'] as String? ?? 'none';
    final medal = ScenarioMedalTier.values.firstWhere(
      (m) => m.name == medalName,
      orElse: () => ScenarioMedalTier.none,
    );
    return ChallengePlayerRecord(
      scenarioId: json['scenarioId'] as String,
      bestTimeSeconds: json['bestTimeSeconds'] as int,
      medal: medal,
      bestScorePoints: json['bestScorePoints'] as int? ?? 0,
      attemptsCount: json['attemptsCount'] as int? ?? 1,
      leaderRiderName: json['leaderRiderName'] as String? ?? 'Lider Ekipy',
      achievedAt: DateTime.tryParse(json['achievedAt'] as String? ?? '') ??
          DateTime(2026, 1, 1),
    );
  }
}

/// Wpis w tablicy najlepszych czasów gracza dla wybranego wyzwania.
class ChallengeBestTimeRunEntry {
  final int rank;
  final String riderName;
  final int timeSeconds;
  final ScenarioMedalTier medal;
  final int scorePoints;
  final String dateLabel;
  final bool isPersonalBest;

  const ChallengeBestTimeRunEntry({
    required this.rank,
    required this.riderName,
    required this.timeSeconds,
    required this.medal,
    required this.scorePoints,
    required this.dateLabel,
    this.isPersonalBest = false,
  });
}

/// Narzędzia pomocnicze formatowania i domyślnych rekordów Wyzwań Taktycznych.
class TacticalChallengesFormatter {
  TacticalChallengesFormatter._();

  /// Formatuje czas w sekundach do postaci `HH:MM:SS` lub `MM:SS`.
  static String formatDurationSeconds(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatuje różnicę czasową względem celu złotego medalu.
  static String formatDeltaToTarget(int actualSeconds, int targetSeconds) {
    final diff = actualSeconds - targetSeconds;
    if (diff == 0) return '0:00 (Cel)';
    final absDiff = diff.abs();
    final formatted = formatDurationSeconds(absDiff);
    return diff < 0 ? '-$formatted' : '+$formatted';
  }

  /// Buduje przykładowe rekordy początkowe gracza dla demonstracji tablicy wyników.
  static Map<String, ChallengePlayerRecord> buildShowcaseRecords() {
    const scenarios = LegendaryHistoricScenariosSeeder.scenarios;
    final t1 = TacticalChallengeMedalTargets.forScenario(scenarios[1]);
    final t4 = TacticalChallengeMedalTargets.forScenario(scenarios[3]);
    final t6 = TacticalChallengeMedalTargets.forScenario(scenarios[5]);

    return {
      scenarios[1].id: ChallengePlayerRecord(
        scenarioId: scenarios[1].id,
        bestTimeSeconds: t1.goldTargetSeconds - 18,
        medal: ScenarioMedalTier.gold,
        bestScorePoints: 1050,
        attemptsCount: 4,
        leaderRiderName: 'K. Majewski',
        achievedAt: DateTime(2026, 4, 12),
      ),
      scenarios[3].id: ChallengePlayerRecord(
        scenarioId: scenarios[3].id,
        bestTimeSeconds: t4.silverTargetSeconds - 6,
        medal: ScenarioMedalTier.silver,
        bestScorePoints: 700,
        attemptsCount: 2,
        leaderRiderName: 'M. Kwiatkowski',
        achievedAt: DateTime(2026, 5, 3),
      ),
      scenarios[5].id: ChallengePlayerRecord(
        scenarioId: scenarios[5].id,
        bestTimeSeconds: t6.bronzeTargetSeconds - 4,
        medal: ScenarioMedalTier.bronze,
        bestScorePoints: 850,
        attemptsCount: 3,
        leaderRiderName: 'J. Nowak',
        achievedAt: DateTime(2026, 6, 19),
      ),
    };
  }

  /// Generuje listę wpisów tablicy najlepszych czasów dla konkretnego scenariusza.
  static List<ChallengeBestTimeRunEntry> buildLeaderboardForScenario(
    HistoricScenarioDefinition scenario,
    ChallengePlayerRecord? record,
  ) {
    if (record == null) return const [];

    final dateStr =
        '${record.achievedAt.day.toString().padLeft(2, '0')}.${record.achievedAt.month.toString().padLeft(2, '0')}.${record.achievedAt.year}';
    final entries = <ChallengeBestTimeRunEntry>[
      ChallengeBestTimeRunEntry(
        rank: 1,
        riderName: record.leaderRiderName,
        timeSeconds: record.bestTimeSeconds,
        medal: record.medal,
        scorePoints: record.bestScorePoints,
        dateLabel: dateStr,
        isPersonalBest: true,
      ),
    ];

    if (record.attemptsCount >= 2) {
      entries.add(
        ChallengeBestTimeRunEntry(
          rank: 2,
          riderName: record.leaderRiderName,
          timeSeconds: record.bestTimeSeconds + 24,
          medal: record.medal == ScenarioMedalTier.gold
              ? ScenarioMedalTier.silver
              : ScenarioMedalTier.bronze,
          scorePoints: (record.bestScorePoints * 0.82).round(),
          dateLabel: dateStr,
        ),
      );
    }

    if (record.attemptsCount >= 3) {
      entries.add(
        ChallengeBestTimeRunEntry(
          rank: 3,
          riderName: record.leaderRiderName,
          timeSeconds: record.bestTimeSeconds + 51,
          medal: ScenarioMedalTier.bronze,
          scorePoints: (record.bestScorePoints * 0.65).round(),
          dateLabel: dateStr,
        ),
      );
    }

    return List<ChallengeBestTimeRunEntry>.unmodifiable(entries);
  }
}

/// Ekran Wyzwań Taktycznych (`TacticalChallengesHubScreen`) prezentujący
/// 10 scenariuszy z medalami (Brązowy, Srebrny, Złoty `#D4AF37`), warunkami
/// zwycięstwa oraz tablicą najlepszych czasów gracza.
class TacticalChallengesHubScreen extends StatefulWidget {
  final Map<String, ChallengePlayerRecord>? initialRecords;
  final String? initialSelectedScenarioId;
  final void Function(PlayableHistoricScenarioBundle bundle)? onLaunchScenario;
  final bool showAppBar;

  const TacticalChallengesHubScreen({
    super.key,
    this.initialRecords,
    this.initialSelectedScenarioId,
    this.onLaunchScenario,
    this.showAppBar = true,
  });

  @override
  State<TacticalChallengesHubScreen> createState() =>
      _TacticalChallengesHubScreenState();
}

class _TacticalChallengesHubScreenState
    extends State<TacticalChallengesHubScreen> {
  late final TextEditingController _searchController;
  late Map<String, ChallengePlayerRecord> _recordsByScenarioId;
  late String _selectedScenarioId;

  TacticalChallengeFilter _activeFilter = TacticalChallengeFilter.all;
  String _searchQuery = '';
  String? _hoveredScenarioId;
  bool _isLaunching = false;
  bool _showGlobalLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _recordsByScenarioId = Map<String, ChallengePlayerRecord>.from(
      widget.initialRecords ??
          TacticalChallengesFormatter.buildShowcaseRecords(),
    );
    _selectedScenarioId = widget.initialSelectedScenarioId ??
        LegendaryHistoricScenariosSeeder.scenarios.first.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoricScenarioDefinition> get _allScenarios =>
      LegendaryHistoricScenariosSeeder.scenarios;

  List<HistoricScenarioDefinition> get _filteredScenarios {
    final query = _searchQuery.trim().toLowerCase();
    return _allScenarios.where((scenario) {
      final record = _recordsByScenarioId[scenario.id];
      final isCompleted =
          record != null && record.medal != ScenarioMedalTier.none;

      final matchesFilter = switch (_activeFilter) {
        TacticalChallengeFilter.all => true,
        TacticalChallengeFilter.veteran =>
          scenario.difficulty == HistoricScenarioDifficulty.veteran,
        TacticalChallengeFilter.legend =>
          scenario.difficulty == HistoricScenarioDifficulty.legend,
        TacticalChallengeFilter.impossible =>
          scenario.difficulty == HistoricScenarioDifficulty.impossible,
        TacticalChallengeFilter.completed => isCompleted,
        TacticalChallengeFilter.uncompleted => !isCompleted,
      };
      if (!matchesFilter) return false;

      if (query.isEmpty) return true;
      return scenario.title.toLowerCase().contains(query) ||
          scenario.code.toLowerCase().contains(query) ||
          scenario.historicalInspiration.toLowerCase().contains(query) ||
          scenario.category.label.toLowerCase().contains(query);
    }).toList();
  }

  HistoricScenarioDefinition get _selectedScenario {
    return LegendaryHistoricScenariosSeeder.findById(_selectedScenarioId) ??
        _allScenarios.first;
  }

  int _countMedals(ScenarioMedalTier tier) {
    return _recordsByScenarioId.values.where((r) => r.medal == tier).length;
  }

  int get _completedCount => _recordsByScenarioId.values
      .where((r) => r.medal != ScenarioMedalTier.none)
      .length;

  int get _totalScorePoints => _recordsByScenarioId.values
      .fold<int>(0, (sum, rec) => sum + rec.bestScorePoints);

  void _handleLaunchScenario(HistoricScenarioDefinition scenario) {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    final bundle = LegendaryHistoricScenariosSeeder.buildPlayableScenario(
      scenario.id,
    );

    if (widget.onLaunchScenario != null) {
      widget.onLaunchScenario!(bundle);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Załadowano wyzwanie ${scenario.code}: ${scenario.title} '
            '(${bundle.stage.segments.length} segmentów, '
            '${bundle.playerRoster.length} kolarzy)',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: canPop
                  ? IconButton(
                      tooltip: 'Wróć',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : null,
              title: const Text(
                'Wyzwania Taktyczne',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: _ScoreBadge(points: _totalScorePoints),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktopWide = width >= 1220;
            final isTabletSplit = width >= 840 && width < 1220;
            final isCompact = width < 560;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryHeader(isCompact),
                _buildFilterAndSearchBar(isCompact),
                Expanded(
                  child: isDesktopWide
                      ? _buildDesktopThreeColumnLayout(isCompact)
                      : isTabletSplit
                          ? _buildTabletTwoColumnLayout(isCompact)
                          : _buildMobileSingleColumnLayout(isCompact),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(bool isCompact) {
    final goldCount = _countMedals(ScenarioMedalTier.gold);
    final silverCount = _countMedals(ScenarioMedalTier.silver);
    final bronzeCount = _countMedals(ScenarioMedalTier.bronze);
    final progress = _allScenarios.isEmpty
        ? 0.0
        : (_completedCount / _allScenarios.length).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        isCompact ? 8 : 12,
        isCompact ? 12 : 20,
        8,
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CENTRUM WYZWAŃ TAKTYCZNYCH',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '10 legendarnych scenariuszy • Ukończono $_completedCount / ${_allScenarios.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MedalCounterChip(
                    label: 'Złote',
                    count: goldCount,
                    color: AppColors.goldAccent,
                  ),
                  _MedalCounterChip(
                    label: 'Srebrne',
                    count: silverCount,
                    color: ScenarioMedalTier.silver.color,
                  ),
                  _MedalCounterChip(
                    label: 'Brązowe',
                    count: bronzeCount,
                    color: ScenarioMedalTier.bronze.color,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.goldAccent,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchBar(bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 4,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in TacticalChallengeFilter.values) ...[
                  _ChallengeFilterChip(
                    label: filter.label,
                    selected: _activeFilter == filter,
                    onTap: () => setState(() => _activeFilter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isCompact ? double.infinity : 280,
              minWidth: isCompact ? 200 : 220,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Szukaj scenariusza...',
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
                        tooltip: 'Wyczyść wyszukiwanie',
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
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.goldAccent,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopThreeColumnLayout(bool isCompact) {
    final selected = _selectedScenario;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _buildScenarioList(isCompact: false),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: _buildScenarioDossierCard(selected, isCompact: false),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: _buildMedalsAndLeaderboardColumn(
                selected,
                isCompact: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletTwoColumnLayout(bool isCompact) {
    final selected = _selectedScenario;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _buildScenarioList(isCompact: false),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScenarioDossierCard(selected, isCompact: false),
                  const SizedBox(height: 16),
                  _buildMedalsAndLeaderboardColumn(
                    selected,
                    isCompact: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSingleColumnLayout(bool isCompact) {
    final selected = _selectedScenario;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        8,
        isCompact ? 12 : 16,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScenarioList(isCompact: isCompact, shrinkWrap: true),
          const SizedBox(height: 16),
          _buildScenarioDossierCard(selected, isCompact: isCompact),
          const SizedBox(height: 16),
          _buildMedalsAndLeaderboardColumn(selected, isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildScenarioList({
    required bool isCompact,
    bool shrinkWrap = false,
  }) {
    final filtered = _filteredScenarios;
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            const Text(
              'Brak scenariuszy spełniających wybrane kryteria.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _activeFilter = TacticalChallengeFilter.all;
                  _searchQuery = '';
                });
              },
              child: const Text('Resetuj filtry'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final scenario = filtered[index];
        final isSelected = scenario.id == _selectedScenario.id;
        final isHovered = scenario.id == _hoveredScenarioId;
        final record = _recordsByScenarioId[scenario.id];
        final medal = record?.medal ?? ScenarioMedalTier.none;
        final targets = TacticalChallengeMedalTargets.forScenario(scenario);

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredScenarioId = scenario.id),
          onExit: (_) => setState(() => _hoveredScenarioId = null),
          child: InkWell(
            onTap: () => setState(() => _selectedScenarioId = scenario.id),
            borderRadius: BorderRadius.circular(16),
            focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
            hoverColor: AppColors.surfaceLight.withValues(alpha: 0.4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(isCompact ? 12 : 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surfaceLight
                    : isHovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.6)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.goldAccent
                      : isHovered
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppTheme.borderColor,
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scenario.difficulty.badgeColor
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${scenario.code} • ${scenario.difficulty.label}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scenario.difficulty.badgeColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MedalBadgePill(medal: medal, compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scenario.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scenario.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          record != null
                              ? 'Najlepszy czas: ${TacticalChallengesFormatter.formatDurationSeconds(record.bestTimeSeconds)}'
                              : 'Cel złota: ${TacticalChallengesFormatter.formatDurationSeconds(targets.goldTargetSeconds)}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: record != null
                                ? AppColors.goldAccent
                                : AppColors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Text(
                        '${scenario.playableDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScenarioDossierCard(
    HistoricScenarioDefinition scenario, {
    required bool isCompact,
  }) {
    final record = _recordsByScenarioId[scenario.id];
    final hasAnyMedal =
        record != null && record.medal != ScenarioMedalTier.none;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                scenario.category.icon,
                color: AppColors.goldAccent,
                size: 20,
              ),
              Text(
                '${scenario.category.label} • ${scenario.historicalInspiration} (${scenario.yearLabel})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            scenario.title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: isCompact ? 17 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TelemetryMetricChip(
                icon: Icons.route_outlined,
                label: '${scenario.playableDistanceKm.toStringAsFixed(1)} km',
              ),
              _TelemetryMetricChip(
                icon: Icons.schedule_outlined,
                label: scenario.formattedGapLabel,
              ),
              _TelemetryMetricChip(
                icon: Icons.air_rounded,
                label: 'Wiatr ${scenario.windSpeedKmh.round()} km/h',
              ),
              _TelemetryMetricChip(
                icon: Icons.thermostat_outlined,
                label: '${scenario.temperatureCelsius.round()}°C',
              ),
              _TelemetryMetricChip(
                icon: Icons.groups_outlined,
                label: 'Pomocnicy: ${scenario.availableDomestiquesCount}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ODPRAWA TAKTYCZNA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scenario.briefingStory,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scenario.tacticalHint,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'WARUNKI ZWYCIĘSTWA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final obj in scenario.objectives) ...[
            _VictoryConditionTile(
              objective: obj,
              achieved: hasAnyMedal &&
                  (obj.isPrimary ||
                      record.medal == ScenarioMedalTier.gold ||
                      record.medal == ScenarioMedalTier.silver),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _isLaunching ? null : () => _handleLaunchScenario(scenario),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.surfaceLight,
                disabledForegroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                _isLaunching
                    ? 'Przygotowywanie scenariusza...'
                    : 'Rozpocznij Wyzwanie (${scenario.code})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedalsAndLeaderboardColumn(
    HistoricScenarioDefinition scenario, {
    required bool isCompact,
  }) {
    final targets = TacticalChallengeMedalTargets.forScenario(scenario);
    final record = _recordsByScenarioId[scenario.id];
    final currentMedal = record?.medal ?? ScenarioMedalTier.none;
    final runEntries = TacticalChallengesFormatter.buildLeaderboardForScenario(
      scenario,
      record,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROGI MEDALOWE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _MedalTierRow(
                tier: ScenarioMedalTier.gold,
                requirement: 'Wszystkie cele + czas ≤ '
                    '${TacticalChallengesFormatter.formatDurationSeconds(targets.goldTargetSeconds)}',
                isEarned: currentMedal == ScenarioMedalTier.gold,
              ),
              const SizedBox(height: 8),
              _MedalTierRow(
                tier: ScenarioMedalTier.silver,
                requirement: 'Cel główny + 1 poboczny + czas ≤ '
                    '${TacticalChallengesFormatter.formatDurationSeconds(targets.silverTargetSeconds)}',
                isEarned: currentMedal == ScenarioMedalTier.silver ||
                    currentMedal == ScenarioMedalTier.gold,
              ),
              const SizedBox(height: 8),
              _MedalTierRow(
                tier: ScenarioMedalTier.bronze,
                requirement: 'Cel główny + czas ≤ '
                    '${TacticalChallengesFormatter.formatDurationSeconds(targets.bronzeTargetSeconds)}',
                isEarned: currentMedal != ScenarioMedalTier.none,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'TABLICA NAJLEPSZYCH CZASÓW GRACZA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(
                      () => _showGlobalLeaderboard = !_showGlobalLeaderboard,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _showGlobalLeaderboard ? 'Ten scenariusz' : 'Wszystkie',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_showGlobalLeaderboard)
                _buildGlobalBestTimesList()
              else
                _buildScenarioBestTimesList(scenario, targets, runEntries),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioBestTimesList(
    HistoricScenarioDefinition scenario,
    TacticalChallengeMedalTargets targets,
    List<ChallengeBestTimeRunEntry> entries,
  ) {
    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.timer_off_outlined,
              size: 26,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Brak zapisanych czasów dla ${scenario.code}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ukończ wyzwanie poniżej ${TacticalChallengesFormatter.formatDurationSeconds(targets.bronzeTargetSeconds)}, aby trafić na tablicę.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final entry in entries) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: entry.isPersonalBest
                  ? AppColors.goldAccent.withValues(alpha: 0.08)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: entry.isPersonalBest
                    ? AppColors.goldAccent.withValues(alpha: 0.55)
                    : AppTheme.borderColor,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: entry.isPersonalBest
                          ? AppColors.goldAccent
                          : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.riderName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${entry.dateLabel} • ${entry.scorePoints} pkt',
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
                      TacticalChallengesFormatter.formatDurationSeconds(
                        entry.timeSeconds,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      TacticalChallengesFormatter.formatDeltaToTarget(
                        entry.timeSeconds,
                        targets.goldTargetSeconds,
                      ),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: entry.timeSeconds <= targets.goldTargetSeconds
                            ? AppColors.statusSuccess
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: entry.medal.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildGlobalBestTimesList() {
    final completedRecords = _recordsByScenarioId.values
        .where((r) => r.medal != ScenarioMedalTier.none)
        .toList()
      ..sort((a, b) => b.bestScorePoints.compareTo(a.bestScorePoints));

    if (completedRecords.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Brak ukończonych wyzwań w globalnej tablicy.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final record in completedRecords) ...[
          Builder(
            builder: (context) {
              final def = LegendaryHistoricScenariosSeeder.findById(
                record.scenarioId,
              );
              return InkWell(
                onTap: () =>
                    setState(() => _selectedScenarioId = record.scenarioId),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 18,
                        color: record.medal.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${def?.code ?? record.scenarioId} • ${record.leaderRiderName}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        TacticalChallengesFormatter.formatDurationSeconds(
                          record.bestTimeSeconds,
                        ),
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
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int points;

  const _ScoreBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 15,
            color: AppColors.goldAccent,
          ),
          const SizedBox(width: 6),
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
    );
  }
}

class _MedalCounterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MedalCounterChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: $count',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChallengeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      focusColor: AppColors.goldAccent.withValues(alpha: 0.25),
      hoverColor: AppColors.surfaceLight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.goldAccent.withValues(alpha: 0.16)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.goldAccent : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.goldAccent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MedalBadgePill extends StatelessWidget {
  final ScenarioMedalTier medal;
  final bool compact;

  const _MedalBadgePill({
    required this.medal,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isNone = medal == ScenarioMedalTier.none;
    final label = switch (medal) {
      ScenarioMedalTier.none => 'Brak medalu',
      ScenarioMedalTier.bronze => 'Brązowy',
      ScenarioMedalTier.silver => 'Srebrny',
      ScenarioMedalTier.gold => 'Złoty',
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: isNone
            ? AppColors.background
            : medal.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNone
              ? AppTheme.borderColor
              : medal.color.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNone
                ? Icons.radio_button_unchecked_rounded
                : Icons.workspace_premium_rounded,
            size: 13,
            color: isNone ? AppColors.textSecondary : medal.color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isNone ? AppColors.textSecondary : medal.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TelemetryMetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _VictoryConditionTile extends StatelessWidget {
  final HistoricScenarioObjective objective;
  final bool achieved;

  const _VictoryConditionTile({
    required this.objective,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = achieved
        ? AppColors.statusSuccess
        : objective.isPrimary
            ? AppColors.goldAccent
            : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achieved
              ? AppColors.statusSuccess.withValues(alpha: 0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            achieved
                ? Icons.check_circle_rounded
                : objective.isPrimary
                    ? Icons.star_rounded
                    : Icons.flag_outlined,
            size: 17,
            color: accentColor,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${objective.isPrimary ? "[Główny]" : "[Poboczny]"} ${objective.title}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  objective.description,
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
    );
  }
}

class _MedalTierRow extends StatelessWidget {
  final ScenarioMedalTier tier;
  final String requirement;
  final bool isEarned;

  const _MedalTierRow({
    required this.tier,
    required this.requirement,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    final tierTitle = switch (tier) {
      ScenarioMedalTier.gold => 'Złoty Medal',
      ScenarioMedalTier.silver => 'Srebrny Medal',
      ScenarioMedalTier.bronze => 'Brązowy Medal',
      ScenarioMedalTier.none => 'Brak',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEarned
            ? tier.color.withValues(alpha: 0.12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEarned
              ? tier.color.withValues(alpha: 0.55)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 20,
            color: tier.color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tierTitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isEarned ? tier.color : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  requirement,
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
          if (isEarned)
            Icon(
              Icons.verified_rounded,
              size: 16,
              color: tier.color,
            ),
        ],
      ),
    );
  }
}
