import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/achievement_and_milestones_service.dart';
import '../../state/career_controller.dart';

/// Filtr statusu odblokowania osiągnięć.
enum _AchievementStatusFilter {
  all('Wszystkie'),
  unlocked('Odblokowane'),
  locked('Zablokowane');

  final String label;
  const _AchievementStatusFilter(this.label);
}

/// Tryb sortowania siatki osiągnięć.
enum _AchievementSortMode {
  catalog('Domyślne'),
  unlockedDate('Data zdobycia'),
  progressDesc('Postęp %');

  final String label;
  const _AchievementSortMode(this.label);
}

/// Kategoria terenu dla wykresu zwycięstw.
class _TerrainVictoryStat {
  final String label;
  final String shortLabel;
  final int wins;
  final Color color;
  final IconData icon;

  const _TerrainVictoryStat({
    required this.label,
    required this.shortLabel,
    required this.wins,
    required this.color,
    required this.icon,
  });
}

/// Ekran prezentujący Licencję Dyrektora Sportowego UCI, statystyki kariery,
/// wykresy zwycięstw według typu terenu oraz siatkę 45 osiągnięć z paskami postępu.
class ManagerProfileAndAchievementsScreen extends ConsumerStatefulWidget {
  const ManagerProfileAndAchievementsScreen({super.key});

  @override
  ConsumerState<ManagerProfileAndAchievementsScreen> createState() =>
      _ManagerProfileAndAchievementsScreenState();
}

class _ManagerProfileAndAchievementsScreenState
    extends ConsumerState<ManagerProfileAndAchievementsScreen> {
  AchievementTier? _selectedTierFilter;
  _AchievementStatusFilter _statusFilter = _AchievementStatusFilter.all;
  _AchievementSortMode _sortMode = _AchievementSortMode.catalog;
  int _touchedTerrainIndex = -1;
  bool _evaluatedInitialSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _evaluatedInitialSave) return;
      final save = ref.read(careerProvider).save;
      if (save != null) {
        ref.read(achievementServiceProvider).evaluateClubAndAero(save: save);
        setState(() => _evaluatedInitialSave = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(careerProvider).save;
    final achievementService = ref.watch(achievementServiceProvider);
    ref.watch(achievementUnlockStreamProvider);

    if (save == null) {
      return const ColoredBox(
        color: AppColors.background,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.goldAccent),
        ),
      );
    }

    final metrics = achievementService.metrics;
    final records = achievementService.progressRecords;
    final definitions = AchievementAndMilestonesService.definitions;

    final terrainStats = _buildTerrainStats(save, metrics);
    final filteredDefinitions = _filterAndSortDefinitions(definitions, records);

    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 680;
          final isTablet = width >= 680 && width < 1150;
          final horizontalPadding = isMobile ? 14.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isMobile ? 16 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopSection(
                  save: save,
                  metrics: metrics,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 20),
                _buildTerrainChartsSection(
                  stats: terrainStats,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 24),
                _buildAchievementsSection(
                  definitions: definitions,
                  filteredDefinitions: filteredDefinitions,
                  records: records,
                  width: width - (horizontalPadding * 2),
                  isMobile: isMobile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopSection({
    required CareerSave save,
    required CareerAchievementMetrics metrics,
    required bool isMobile,
    required bool isTablet,
  }) {
    final licenseCard = _UciHolographicLicenseCard(
      save: save,
      metrics: metrics,
      isCompact: isMobile,
    );
    final careerSummaryPanel = _CareerLicenseSummaryPanel(
      save: save,
      metrics: metrics,
      isCompact: isMobile,
    );

    if (isMobile || isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          licenseCard,
          const SizedBox(height: 16),
          careerSummaryPanel,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 6, child: licenseCard),
          const SizedBox(width: 18),
          Expanded(flex: 5, child: careerSummaryPanel),
        ],
      ),
    );
  }

  Widget _buildTerrainChartsSection({
    required List<_TerrainVictoryStat> stats,
    required bool isMobile,
    required bool isTablet,
  }) {
    final totalWins = stats.fold<int>(0, (sum, item) => sum + item.wins);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accentBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.terrain_rounded,
                      color: AppColors.accentBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zwycięstwa Według Typu Terenu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Rozkład triumfów na trasach płaskich, pagórkach, górach, bruku i czasówkach',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  'Łącznie: $totalWins zwycięstw',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              children: [
                SizedBox(
                  height: 220,
                  child: _buildTerrainPieChart(stats, totalWins),
                ),
                const SizedBox(height: 14),
                _buildTerrainLegend(stats, totalWins),
                const SizedBox(height: 18),
                SizedBox(
                  height: 210,
                  child: _buildTerrainBarChart(stats),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: isTablet ? 5 : 4,
                  child: SizedBox(
                    height: 230,
                    child: _buildTerrainPieChart(stats, totalWins),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildTerrainLegend(stats, totalWins),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 230,
                    child: _buildTerrainBarChart(stats),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTerrainPieChart(
    List<_TerrainVictoryStat> stats,
    int totalWins,
  ) {
    if (totalWins == 0) {
      return Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 48,
              sections: stats
                  .map(
                    (s) => PieChartSectionData(
                      value: 1,
                      color: s.color.withValues(alpha: 0.22),
                      radius: 26,
                      showTitle: false,
                    ),
                  )
                  .toList(),
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '0',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Brak zwycięstw',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final activeStat = (_touchedTerrainIndex >= 0 &&
            _touchedTerrainIndex < stats.length)
        ? stats[_touchedTerrainIndex]
        : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null) {
                  if (_touchedTerrainIndex != -1) {
                    setState(() => _touchedTerrainIndex = -1);
                  }
                  return;
                }
                final idx = response.touchedSection!.touchedSectionIndex;
                if (idx != _touchedTerrainIndex) {
                  setState(() => _touchedTerrainIndex = idx);
                }
              },
            ),
            borderData: FlBorderData(show: false),
            sectionsSpace: 3,
            centerSpaceRadius: 48,
            sections: List.generate(stats.length, (index) {
              final item = stats[index];
              final isTouched = index == _touchedTerrainIndex;
              final pct =
                  totalWins > 0 ? (item.wins / totalWins * 100).round() : 0;
              return PieChartSectionData(
                color: item.wins > 0
                    ? item.color
                    : item.color.withValues(alpha: 0.18),
                value: item.wins > 0 ? item.wins.toDouble() : 0.25,
                title: item.wins > 0 && pct >= 8 ? '$pct%' : '',
                radius: isTouched ? 42 : 34,
                titleStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              );
            }),
          ),
          swapAnimationDuration: const Duration(milliseconds: 260),
          swapAnimationCurve: Curves.easeOutCubic,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${activeStat?.wins ?? totalWins}',
              style: TextStyle(
                fontFamily: 'Inter',
                color: activeStat?.color ?? AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              activeStat?.shortLabel ?? 'Zwycięstwa',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTerrainLegend(List<_TerrainVictoryStat> stats, int totalWins) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(stats.length, (index) {
        final item = stats[index];
        final isHighlighted = _touchedTerrainIndex == index;
        final pct = totalWins > 0
            ? ((item.wins / totalWins) * 100).toStringAsFixed(0)
            : '0';

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: MouseRegion(
            onEnter: (_) => setState(() => _touchedTerrainIndex = index),
            onExit: (_) => setState(() => _touchedTerrainIndex = -1),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() {
                _touchedTerrainIndex =
                    _touchedTerrainIndex == index ? -1 : index;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? item.color.withValues(alpha: 0.16)
                      : AppColors.surfaceLight.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isHighlighted
                        ? item.color.withValues(alpha: 0.7)
                        : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, size: 15, color: item.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isHighlighted
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              isHighlighted ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${item.wins} ($pct%)',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: item.wins > 0
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTerrainBarChart(List<_TerrainVictoryStat> stats) {
    final maxWins = stats.fold<int>(0, (m, s) => math.max(m, s.wins));
    final maxY = math.max(5.0, (maxWins * 1.25).ceilToDouble());

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.spot == null) {
              if (_touchedTerrainIndex != -1) {
                setState(() => _touchedTerrainIndex = -1);
              }
              return;
            }
            final idx = response.spot!.touchedBarGroupIndex;
            if (idx != _touchedTerrainIndex) {
              setState(() => _touchedTerrainIndex = idx);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceLight,
            tooltipRoundedRadius: 8,
            tooltipBorder: const BorderSide(color: AppTheme.borderColor),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final stat = stats[group.x];
              return BarTooltipItem(
                '${stat.label}\n${stat.wins} wygr.',
                TextStyle(
                  fontFamily: 'Inter',
                  color: stat.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max(1, (maxY / 4).ceilToDouble()),
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.borderColor.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: math.max(1, (maxY / 4).ceilToDouble()),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= stats.length) {
                  return const SizedBox.shrink();
                }
                final stat = stats[idx];
                final isHighlighted = _touchedTerrainIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    stat.shortLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isHighlighted
                          ? stat.color
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight:
                          isHighlighted ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(stats.length, (index) {
          final item = stats[index];
          final isHighlighted = _touchedTerrainIndex == index;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.wins.toDouble(),
                width: isHighlighted ? 26 : 22,
                color: isHighlighted
                    ? item.color
                    : item.color.withValues(alpha: 0.82),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: AppColors.surfaceLight.withValues(alpha: 0.45),
                ),
              ),
            ],
          );
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 260),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }

  Widget _buildAchievementsSection({
    required List<AchievementDefinition> definitions,
    required List<AchievementDefinition> filteredDefinitions,
    required Map<String, AchievementProgressRecord> records,
    required double width,
    required bool isMobile,
  }) {
    final unlockedCount = definitions
        .where((def) => records[def.id]?.isUnlocked ?? false)
        .length;
    final totalPoints = definitions.fold<int>(0, (sum, def) {
      final isUnlocked = records[def.id]?.isUnlocked ?? false;
      return isUnlocked ? sum + def.points : sum;
    });
    final maxPoints = definitions.fold<int>(0, (sum, def) => sum + def.points);

    final columns = width >= 1200
        ? 3
        : width >= 660
            ? 2
            : 1;
    const spacing = 12.0;
    final cardWidth =
        ((width - (spacing * (columns - 1))) / columns).clamp(240.0, 620.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.goldAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Osiągnięcia Kariery ($unlockedCount / ${definitions.length})',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Zdobyte punkty prestiżu: $totalPoints / $maxPoints pkt',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildSortSelector(),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InteractiveFilterChip(
                    label: 'Wszystkie (${definitions.length})',
                    isSelected: _selectedTierFilter == null,
                    accentColor: AppColors.goldAccent,
                    onTap: () => setState(() => _selectedTierFilter = null),
                  ),
                  ...AchievementTier.values.map((tier) {
                    final tierTotal =
                        definitions.where((d) => d.tier == tier).length;
                    final tierUnlocked = definitions
                        .where(
                          (d) =>
                              d.tier == tier &&
                              (records[d.id]?.isUnlocked ?? false),
                        )
                        .length;
                    return _InteractiveFilterChip(
                      label: '${tier.label} ($tierUnlocked/$tierTotal)',
                      icon: tier.tierIcon,
                      isSelected: _selectedTierFilter == tier,
                      accentColor: tier.badgeColor,
                      onTap: () => setState(() {
                        _selectedTierFilter =
                            _selectedTierFilter == tier ? null : tier;
                      }),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _AchievementStatusFilter.values.map((status) {
                  return _InteractiveFilterChip(
                    label: status.label,
                    isSelected: _statusFilter == status,
                    accentColor: AppColors.accentBlue,
                    onTap: () => setState(() => _statusFilter = status),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filteredDefinitions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.filter_list_off_rounded,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
                SizedBox(height: 10),
                Text(
                  'Brak osiągnięć spełniających wybrane kryteria filtrowania.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: filteredDefinitions.map((def) {
              final record = records[def.id] ??
                  AchievementProgressRecord(
                    achievementId: def.id,
                    isUnlocked: false,
                    currentValue: 0,
                    targetValue: def.targetValue,
                  );
              return SizedBox(
                width: cardWidth,
                child: _AchievementProgressCard(
                  definition: def,
                  record: record,
                  onTap: () => _showAchievementDetailsDialog(def, record),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSortSelector() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _AchievementSortMode.values.map((mode) {
        return _InteractiveFilterChip(
          label: mode.label,
          isSelected: _sortMode == mode,
          accentColor: AppColors.cyanAccent,
          onTap: () => setState(() => _sortMode = mode),
        );
      }).toList(),
    );
  }

  List<AchievementDefinition> _filterAndSortDefinitions(
    List<AchievementDefinition> definitions,
    Map<String, AchievementProgressRecord> records,
  ) {
    final filtered = definitions.where((def) {
      if (_selectedTierFilter != null && def.tier != _selectedTierFilter) {
        return false;
      }
      final unlocked = records[def.id]?.isUnlocked ?? false;
      switch (_statusFilter) {
        case _AchievementStatusFilter.all:
          return true;
        case _AchievementStatusFilter.unlocked:
          return unlocked;
        case _AchievementStatusFilter.locked:
          return !unlocked;
      }
    }).toList();

    switch (_sortMode) {
      case _AchievementSortMode.catalog:
        return filtered;
      case _AchievementSortMode.unlockedDate:
        filtered.sort((a, b) {
          final ra = records[a.id];
          final rb = records[b.id];
          final ua = ra?.isUnlocked ?? false;
          final ub = rb?.isUnlocked ?? false;
          if (ua != ub) return ub ? 1 : -1;
          if (ua && ub) {
            final da = ra?.unlockedAt ?? DateTime(1970);
            final db = rb?.unlockedAt ?? DateTime(1970);
            return db.compareTo(da);
          }
          return (rb?.progressRatio ?? 0).compareTo(ra?.progressRatio ?? 0);
        });
        return filtered;
      case _AchievementSortMode.progressDesc:
        filtered.sort((a, b) {
          final ra = records[a.id];
          final rb = records[b.id];
          final ratioCmp =
              (rb?.progressRatio ?? 0).compareTo(ra?.progressRatio ?? 0);
          if (ratioCmp != 0) return ratioCmp;
          return b.points.compareTo(a.points);
        });
        return filtered;
    }
  }

  List<_TerrainVictoryStat> _buildTerrainStats(
    CareerSave save,
    CareerAchievementMetrics metrics,
  ) {
    final teamWinsInHistory = save.calendar.raceHistory.values
        .where((h) => h.winnerTeamId == save.playerTeamId)
        .toList();

    final flatWins = metrics.sprintStageWins;
    final mountainWins = metrics.mountainStageWins;
    final ttWins = metrics.timeTrialWins;
    final cobbleWins = metrics.distinctMonumentIdsWon
        .where((id) =>
            id.toLowerCase().contains('roubaix') ||
            id.toLowerCase().contains('flanders') ||
            id.toLowerCase().contains('vlaanderen'))
        .length;

    final accounted = flatWins + mountainWins + ttWins + cobbleWins;
    final totalRecorded = math.max(
      metrics.totalStageAndRaceWins,
      teamWinsInHistory.length,
    );
    final hillyWins = math.max(
      metrics.breakawayWins,
      math.max(0, totalRecorded - accounted),
    );

    return [
      _TerrainVictoryStat(
        label: 'Płaskie',
        shortLabel: 'Płaskie',
        wins: flatWins,
        color: AppColors.accentBlue,
        icon: Icons.bolt_rounded,
      ),
      _TerrainVictoryStat(
        label: 'Pagórki',
        shortLabel: 'Pagórki',
        wins: hillyWins,
        color: AppColors.statusSuccess,
        icon: Icons.landscape_rounded,
      ),
      _TerrainVictoryStat(
        label: 'Wysokie Góry',
        shortLabel: 'Góry',
        wins: mountainWins,
        color: AppColors.primaryAccent,
        icon: Icons.terrain_rounded,
      ),
      _TerrainVictoryStat(
        label: 'Bruki',
        shortLabel: 'Bruki',
        wins: cobbleWins,
        color: AppColors.amberWarning,
        icon: Icons.grid_view_rounded,
      ),
      _TerrainVictoryStat(
        label: 'Czasówki',
        shortLabel: 'Czasówki',
        wins: ttWins,
        color: AppColors.cyanAccent,
        icon: Icons.timer_rounded,
      ),
    ];
  }

  void _showAchievementDetailsDialog(
    AchievementDefinition def,
    AchievementProgressRecord record,
  ) {
    final isUnlocked = record.isUnlocked;
    final hideSecret = def.isSecret && !isUnlocked;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isUnlocked
                  ? def.tier.badgeColor.withValues(alpha: 0.7)
                  : AppTheme.borderColor,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: def.tier.badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hideSecret ? Icons.lock_outline_rounded : def.icon,
                  color: def.tier.badgeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hideSecret ? 'Sekretne Osiągnięcie' : def.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${def.tier.label} • ${def.category.label} • +${def.points} pkt',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: def.tier.badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hideSecret
                    ? 'Warunki odblokowania tego trofeum pozostają tajne aż do momentu jego zdobycia.'
                    : def.description,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              _AchievementProgressBar(
                record: record,
                accentColor: def.tier.badgeColor,
                labelPrefix: hideSecret ? 'Postęp' : def.title,
              ),
              const SizedBox(height: 12),
              Text(
                isUnlocked
                    ? 'Zdobyto: ${_formatUnlockDate(record)}'
                    : 'Status: W trakcie realizacji',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isUnlocked
                      ? AppColors.statusSuccess
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Zamknij',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fizyczna, holograficzna karta Licencji Dyrektora Sportowego UCI (VIP Tour Pass).
class _UciHolographicLicenseCard extends StatefulWidget {
  final CareerSave save;
  final CareerAchievementMetrics metrics;
  final bool isCompact;

  const _UciHolographicLicenseCard({
    required this.save,
    required this.metrics,
    required this.isCompact,
  });

  @override
  State<_UciHolographicLicenseCard> createState() =>
      _UciHolographicLicenseCardState();
}

class _UciHolographicLicenseCardState extends State<_UciHolographicLicenseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.save.playerTeam;
    final reputation = widget.save.managerReputation.clamp(1, 100);
    final seasonsPlayed = math.max(
      1,
      widget.metrics.seasonsCompleted > 0
          ? widget.metrics.seasonsCompleted
          : (widget.save.currentSeasonYear - widget.save.createdAt.year + 1),
    );
    final tacticalSpecialty = _resolveTacticalSpecialty(widget.save, widget.metrics);
    final nationalityLabel = _resolveCountryLabel(team.countryIso);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1D222E),
              AppColors.surface,
              _isHovered
                  ? AppColors.goldAccent.withValues(alpha: 0.16)
                  : const Color(0xFF161922),
            ],
          ),
          border: Border.all(
            color: _isHovered
                ? AppColors.goldAccent.withValues(alpha: 0.85)
                : AppColors.goldAccent.withValues(alpha: 0.45),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldAccent.withValues(
                alpha: _isHovered ? 0.22 : 0.08,
              ),
              blurRadius: _isHovered ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _HolographicPassPainter(
                        progress: _shimmerController.value,
                        isHovered: _isHovered,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(widget.isCompact ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wycięcie na smycz VIP Touru
                    Center(
                      child: Container(
                        width: 54,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.goldAccent,
                                  Color(0xFFF3D578),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'UCI • VIP DIRECTEUR SPORTIF',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFF0F1115),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Text(
                            'LIC. UCI-${widget.save.currentSeasonYear}-${team.countryIso.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LicenseAvatarEmblem(
                          team: team,
                          managerName: widget.save.playerManagerName,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.save.playerManagerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _LicensePill(
                                    icon: Icons.flag_rounded,
                                    label: nationalityLabel,
                                    color: AppColors.accentBlue,
                                  ),
                                  _LicensePill(
                                    icon: Icons.shield_rounded,
                                    label: team.name,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Pasek Reputacji 1-100
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'POZIOM REPUTACJI UCI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$reputation / 100',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.goldAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: reputation / 100.0,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.goldAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _LicenseMetaTile(
                          label: 'Specjalizacja Taktyczna',
                          value: tacticalSpecialty,
                          icon: Icons.psychology_rounded,
                          accent: AppColors.cyanAccent,
                        ),
                        _LicenseMetaTile(
                          label: 'Rozegrane Sezony',
                          value: '$seasonsPlayed',
                          icon: Icons.calendar_today_rounded,
                          accent: AppColors.accentBlue,
                        ),
                        _LicenseMetaTile(
                          label: 'Dywizja Licencyjna',
                          value: team.division.label,
                          icon: Icons.verified_rounded,
                          accent: AppColors.statusSuccess,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel bilansu zwycięstw i nagród finansowych obok karty licencji.
class _CareerLicenseSummaryPanel extends StatelessWidget {
  final CareerSave save;
  final CareerAchievementMetrics metrics;
  final bool isCompact;

  const _CareerLicenseSummaryPanel({
    required this.save,
    required this.metrics,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final stageWins = math.max(
      metrics.totalStageAndRaceWins,
      save.calendar.raceHistory.values
          .where((h) => h.winnerTeamId == save.playerTeamId)
          .length,
    );
    final gcWins =
        metrics.grandTourGcWins + metrics.worldTourStageRaceGcWins;
    final monumentWins = metrics.monumentsWonCount;
    final totalPrizeMoneyEur = save.financeLedger
        .where(
          (entry) =>
              (entry.category == FinanceCategory.racePrizeMoney ||
                  entry.category == FinanceCategory.prizeMoney) &&
              entry.amountEur > 0,
        )
        .fold<int>(0, (sum, entry) => sum + entry.amountEur);

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.military_tech_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dorobek Kariery i Nagrody',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _KpiStatBox(
                  label: 'Wygrane Etapy',
                  value: '$stageWins',
                  icon: Icons.flag_circle_rounded,
                  accent: AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiStatBox(
                  label: 'Klasyfikacje GC',
                  value: '$gcWins',
                  icon: Icons.emoji_events_rounded,
                  accent: AppColors.goldAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiStatBox(
                  label: 'Monumenty',
                  value: '$monumentWins',
                  icon: Icons.auto_awesome_rounded,
                  accent: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.statusSuccess.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.euro_rounded,
                    color: AppColors.statusSuccess,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Łączna Kwota Wygranych Nagród',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatCurrency(totalPrizeMoneyEur),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.statusSuccess,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
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

class _KpiStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _KpiStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 17),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseAvatarEmblem extends StatelessWidget {
  final CyclingTeam team;
  final String managerName;

  const _LicenseAvatarEmblem({
    required this.team,
    required this.managerName,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _parseHexColor(team.primaryJerseyColorHex, AppColors.primaryAccent);
    final secondary =
        _parseHexColor(team.secondaryJerseyColorHex, AppColors.goldAccent);
    final initials = managerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? 'DS' : initials,
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _LicensePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LicensePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseMetaTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _LicenseMetaTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rysuje holograficzny połysk, siatkę mikrowzorów oraz pasek bezpieczeństwa UCI.
class _HolographicPassPainter extends CustomPainter {
  final double progress;
  final bool isHovered;

  const _HolographicPassPainter({
    required this.progress,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;

    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final sweepX = (progress * 1.8 - 0.4) * size.width;
    final shimmerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + progress * 2.4, -1.0),
        end: Alignment(-0.2 + progress * 2.4, 1.0),
        colors: [
          Colors.transparent,
          AppColors.cyanAccent.withValues(alpha: isHovered ? 0.09 : 0.045),
          AppColors.goldAccent.withValues(alpha: isHovered ? 0.11 : 0.055),
          Colors.transparent,
        ],
      ).createShader(shimmerRect);
    canvas.drawRect(shimmerRect, shimmerPaint);

    // Subtelny znak wodny pierścienia holograficznego
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.goldAccent.withValues(alpha: isHovered ? 0.14 : 0.07);
    canvas.drawCircle(
      Offset(size.width - 34, size.height - 28 + math.sin(progress * 6.28) * 2),
      44,
      ringPaint,
    );
    canvas.drawCircle(
      Offset(sweepX.clamp(0, size.width), 18),
      14,
      ringPaint..color = AppColors.cyanAccent.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(covariant _HolographicPassPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isHovered != isHovered;
  }
}

/// Karta pojedynczego osiągnięcia z paskiem postępu, rangą i datą zdobycia.
class _AchievementProgressCard extends StatefulWidget {
  final AchievementDefinition definition;
  final AchievementProgressRecord record;
  final VoidCallback onTap;

  const _AchievementProgressCard({
    required this.definition,
    required this.record,
    required this.onTap,
  });

  @override
  State<_AchievementProgressCard> createState() =>
      _AchievementProgressCardState();
}

class _AchievementProgressCardState extends State<_AchievementProgressCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final rec = widget.record;
    final isUnlocked = rec.isUnlocked;
    final hideSecret = def.isSecret && !isUnlocked;
    final tierColor = def.tier.badgeColor;

    final borderColor = _isPressed || _isFocused
        ? AppColors.cyanAccent
        : _isHovered
            ? tierColor.withValues(alpha: 0.85)
            : isUnlocked
                ? tierColor.withValues(alpha: 0.48)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? AppColors.surface
                  : AppColors.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: _isHovered || _isFocused ? 1.4 : 1.0,
              ),
              boxShadow: _isHovered && isUnlocked
                  ? [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? tierColor.withValues(alpha: 0.16)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: isUnlocked
                              ? tierColor.withValues(alpha: 0.45)
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Icon(
                        hideSecret ? Icons.lock_outline_rounded : def.icon,
                        color: isUnlocked ? tierColor : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hideSecret ? 'Sekretne Osiągnięcie' : def.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                def.tier.tierIcon,
                                size: 13,
                                color: tierColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  def.tier.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: tierColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+${def.points} pkt',
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
                        ],
                      ),
                    ),
                    Icon(
                      isUnlocked
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isUnlocked
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  hideSecret
                      ? 'Ukończ ukryte wyzwanie w trakcie kariery, aby odsłonić szczegóły.'
                      : def.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _AchievementProgressBar(
                  record: rec,
                  accentColor: tierColor,
                  labelPrefix: hideSecret ? 'Postęp' : def.title,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        def.category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUnlocked
                          ? 'Zdobyto: ${_formatUnlockDate(rec)}'
                          : 'Zablokowane',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isUnlocked
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
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

class _AchievementProgressBar extends StatelessWidget {
  final AchievementProgressRecord record;
  final Color accentColor;
  final String labelPrefix;

  const _AchievementProgressBar({
    required this.record,
    required this.accentColor,
    required this.labelPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final target = record.targetValue <= 0 ? 1.0 : record.targetValue;
    final current = record.isUnlocked ? target : record.currentValue.clamp(0.0, target);
    final ratio = record.progressRatio;
    final pct = (ratio * 100).round();

    final currentStr =
        current == current.roundToDouble() ? '${current.round()}' : current.toStringAsFixed(1);
    final targetStr =
        target == target.roundToDouble() ? '${target.round()}' : target.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '$labelPrefix: $currentStr/$targetStr',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pct%',
              style: TextStyle(
                fontFamily: 'Inter',
                color: record.isUnlocked
                    ? AppColors.statusSuccess
                    : accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              record.isUnlocked ? AppColors.statusSuccess : accentColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.accentColor.withValues(alpha: 0.18)
                  : _isHovered
                      ? AppColors.surfaceLight
                      : AppColors.surfaceLight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? AppColors.cyanAccent
                    : widget.isSelected
                        ? widget.accentColor
                        : _isHovered
                            ? widget.accentColor.withValues(alpha: 0.5)
                            : AppTheme.borderColor,
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
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
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

String _formatUnlockDate(AchievementProgressRecord record) {
  final dt = record.unlockedAt;
  if (dt == null) {
    return record.unlockedSeasonYear != null
        ? 'Sezon ${record.unlockedSeasonYear}'
        : 'Odblokowano';
  }
  return DateFormat('dd.MM.yyyy').format(dt);
}

String _resolveTacticalSpecialty(
  CareerSave save,
  CareerAchievementMetrics metrics,
) {
  final buckets = <String, int>{
    'Sprint & Pociągi': metrics.sprintStageWins,
    'Góry & Klasyfikacja GC':
        metrics.mountainStageWins + metrics.grandTourGcWins * 2,
    'Ucieczki & Kontrataki': metrics.breakawayWins,
    'Jazda na Czas & Aero': metrics.timeTrialWins,
    'Klasyki & Monumenty': metrics.monumentsWonCount * 2,
  };

  var bestLabel = 'Taktyka Zrównoważona';
  var bestScore = 0;
  for (final entry in buckets.entries) {
    if (entry.value > bestScore) {
      bestScore = entry.value;
      bestLabel = entry.key;
    }
  }
  if (bestScore > 0) return bestLabel;

  if (save.windTunnelLevel >= 3) return 'Aerodynamika & Czasówki';
  if (save.serviceCourseLevel >= 3) return 'Klasyki & Logistyka';
  return 'Wszechstronny Sztab UCI';
}

String _resolveCountryLabel(String iso) {
  final code = iso.trim().toUpperCase();
  const map = <String, String>{
    'POL': 'Polska (POL)',
    'PL': 'Polska (POL)',
    'FRA': 'Francja (FRA)',
    'FR': 'Francja (FRA)',
    'BEL': 'Belgia (BEL)',
    'BE': 'Belgia (BEL)',
    'NED': 'Holandia (NED)',
    'NL': 'Holandia (NED)',
    'ITA': 'Włochy (ITA)',
    'IT': 'Włochy (ITA)',
    'ESP': 'Hiszpania (ESP)',
    'ES': 'Hiszpania (ESP)',
    'GBR': 'Wielka Brytania (GBR)',
    'GB': 'Wielka Brytania (GBR)',
    'GER': 'Niemcy (GER)',
    'DE': 'Niemcy (GER)',
    'SLO': 'Słowenia (SLO)',
    'SI': 'Słowenia (SLO)',
    'DEN': 'Dania (DEN)',
    'DK': 'Dania (DEN)',
    'USA': 'USA (USA)',
    'US': 'USA (USA)',
    'AUS': 'Australia (AUS)',
    'AU': 'Australia (AUS)',
    'COL': 'Kolumbia (COL)',
    'CO': 'Kolumbia (COL)',
    'NOR': 'Norwegia (NOR)',
    'NO': 'Norwegia (NOR)',
    'SUI': 'Szwajcaria (SUI)',
    'CH': 'Szwajcaria (SUI)',
  };
  return map[code] ?? 'Międzynarodowa ($code)';
}

Color _parseHexColor(String hex, Color fallback) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) {
    final parsed = int.tryParse('FF$cleaned', radix: 16);
    if (parsed != null) return Color(parsed);
  } else if (cleaned.length == 8) {
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed != null) return Color(parsed);
  }
  return fallback;
}
