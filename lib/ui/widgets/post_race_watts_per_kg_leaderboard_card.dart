import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../models/career/career_save.dart';
import '../../models/race/race_stage.dart';
import '../../models/rider/rider.dart';
import '../../models/team/cycling_team.dart';

/// Interwały pomiarowe zestawiane w tabeli rekordów mocy dnia po etapie.
enum PowerRecordInterval {
  sprint5s,
  attack1m,
  vo2Max5m,
  climb20m;

  /// Pełna etykieta interwału z jednostką.
  String get label {
    switch (this) {
      case PowerRecordInterval.sprint5s:
        return '5s Sprint (W)';
      case PowerRecordInterval.attack1m:
        return '1m Attack (W/kg)';
      case PowerRecordInterval.vo2Max5m:
        return '5m VO2max (W/kg)';
      case PowerRecordInterval.climb20m:
        return '20m Climb (W/kg)';
    }
  }

  /// Krótka etykieta do kompaktowych układów mobilnych.
  String get shortLabel {
    switch (this) {
      case PowerRecordInterval.sprint5s:
        return '5s Sprint';
      case PowerRecordInterval.attack1m:
        return '1m Attack';
      case PowerRecordInterval.vo2Max5m:
        return '5m VO2max';
      case PowerRecordInterval.climb20m:
        return '20m Climb';
    }
  }

  /// Jednostka prezentacji głównej wartości.
  String get unit {
    switch (this) {
      case PowerRecordInterval.sprint5s:
        return 'W';
      case PowerRecordInterval.attack1m:
      case PowerRecordInterval.vo2Max5m:
      case PowerRecordInterval.climb20m:
        return 'W/kg';
    }
  }

  /// Czy metryka jest normalizowana do masy ciała (W/kg).
  bool get isWattsPerKg => this != PowerRecordInterval.sprint5s;

  /// Kolor strefy Coggana przypisany do wysiłku w tym oknie czasowym.
  Color get zoneColor {
    switch (this) {
      case PowerRecordInterval.sprint5s:
        return AppColors.powerZone7;
      case PowerRecordInterval.attack1m:
        return AppColors.powerZone6;
      case PowerRecordInterval.vo2Max5m:
        return AppColors.powerZone5;
      case PowerRecordInterval.climb20m:
        return AppColors.powerZone4;
    }
  }

  /// Ikona reprezentująca charakterystykę wysiłku.
  IconData get icon {
    switch (this) {
      case PowerRecordInterval.sprint5s:
        return Icons.bolt_rounded;
      case PowerRecordInterval.attack1m:
        return Icons.flash_on_rounded;
      case PowerRecordInterval.vo2Max5m:
        return Icons.local_fire_department_rounded;
      case PowerRecordInterval.climb20m:
        return Icons.terrain_rounded;
    }
  }
}

/// Rekord mocy pojedynczego kolarza zarejestrowany podczas zakończonego etapu.
class PostRacePowerRecordEntry {
  final String riderId;
  final String riderName;
  final String teamId;
  final String teamName;
  final String teamShortCode;
  final Color teamColor;
  final bool isPlayerTeam;
  final double weightKg;
  final int peak5sWatts;
  final int peak1mWatts;
  final int peak5mWatts;
  final int peak20mWatts;
  final String? segmentLocation;

  const PostRacePowerRecordEntry({
    required this.riderId,
    required this.riderName,
    required this.teamId,
    required this.teamName,
    required this.teamShortCode,
    required this.teamColor,
    required this.isPlayerTeam,
    required this.weightKg,
    required this.peak5sWatts,
    required this.peak1mWatts,
    required this.peak5mWatts,
    required this.peak20mWatts,
    this.segmentLocation,
  });

  double get _safeWeightKg => weightKg > 35.0 ? weightKg : 68.0;

  double get peak5sWkg => peak5sWatts / _safeWeightKg;
  double get peak1mWkg => peak1mWatts / _safeWeightKg;
  double get peak5mWkg => peak5mWatts / _safeWeightKg;
  double get peak20mWkg => peak20mWatts / _safeWeightKg;

  /// Wartość główna dla wskazanego interwału (W dla 5s, W/kg dla 1m/5m/20m).
  double valueForInterval(PowerRecordInterval interval) {
    switch (interval) {
      case PowerRecordInterval.sprint5s:
        return peak5sWatts.toDouble();
      case PowerRecordInterval.attack1m:
        return peak1mWkg;
      case PowerRecordInterval.vo2Max5m:
        return peak5mWkg;
      case PowerRecordInterval.climb20m:
        return peak20mWkg;
    }
  }

  /// Sformatowana wartość główna (np. `"1 540 W"` lub `"6.42 W/kg"`).
  String formattedValueForInterval(PowerRecordInterval interval) {
    switch (interval) {
      case PowerRecordInterval.sprint5s:
        return '$peak5sWatts W';
      case PowerRecordInterval.attack1m:
        return '${peak1mWkg.toStringAsFixed(2)} W/kg';
      case PowerRecordInterval.vo2Max5m:
        return '${peak5mWkg.toStringAsFixed(2)} W/kg';
      case PowerRecordInterval.climb20m:
        return '${peak20mWkg.toStringAsFixed(2)} W/kg';
    }
  }

  /// Krótka wartość do komórek tabeli (bez powtarzania jednostki w nagłówku).
  String formattedCompactValue(PowerRecordInterval interval) {
    switch (interval) {
      case PowerRecordInterval.sprint5s:
        return '$peak5sWatts W';
      case PowerRecordInterval.attack1m:
        return peak1mWkg.toStringAsFixed(2);
      case PowerRecordInterval.vo2Max5m:
        return peak5mWkg.toStringAsFixed(2);
      case PowerRecordInterval.climb20m:
        return peak20mWkg.toStringAsFixed(2);
    }
  }

  /// Drugoplanowa informacja uzupełniająca (W/kg dla sprintu, W bezwzględne dla reszty).
  String formattedSecondaryForInterval(PowerRecordInterval interval) {
    switch (interval) {
      case PowerRecordInterval.sprint5s:
        return '${peak5sWkg.toStringAsFixed(1)} W/kg · ${weightKg.toStringAsFixed(1)} kg';
      case PowerRecordInterval.attack1m:
        return '$peak1mWatts W · ${weightKg.toStringAsFixed(1)} kg';
      case PowerRecordInterval.vo2Max5m:
        return '$peak5mWatts W · ${weightKg.toStringAsFixed(1)} kg';
      case PowerRecordInterval.climb20m:
        return '$peak20mWatts W · ${weightKg.toStringAsFixed(1)} kg';
    }
  }
}

/// Historyczny rekord trasy / podjazdu dla danego okna czasowego.
class HistoricalRoutePowerRecord {
  final PowerRecordInterval interval;
  final double recordValue;
  final String holderName;
  final int recordYear;
  final String routeOrClimbName;

  const HistoricalRoutePowerRecord({
    required this.interval,
    required this.recordValue,
    required this.holderName,
    required this.recordYear,
    required this.routeOrClimbName,
  });

  String get formattedRecord {
    if (interval == PowerRecordInterval.sprint5s) {
      return '${recordValue.round()} W';
    }
    return '${recordValue.toStringAsFixed(2)} W/kg';
  }
}

/// Wynik porównania szczytowej mocy dnia z historycznym rekordem trasy.
class PowerRecordComparison {
  final PowerRecordInterval interval;
  final double dayValue;
  final HistoricalRoutePowerRecord historicalRecord;
  final double deltaValue;
  final double deltaPercent;

  const PowerRecordComparison({
    required this.interval,
    required this.dayValue,
    required this.historicalRecord,
    required this.deltaValue,
    required this.deltaPercent,
  });

  factory PowerRecordComparison.compute({
    required PowerRecordInterval interval,
    required double dayValue,
    required HistoricalRoutePowerRecord historicalRecord,
  }) {
    final double delta = dayValue - historicalRecord.recordValue;
    final double pct = historicalRecord.recordValue > 0
        ? (delta / historicalRecord.recordValue) * 100.0
        : 0.0;
    return PowerRecordComparison(
      interval: interval,
      dayValue: dayValue,
      historicalRecord: historicalRecord,
      deltaValue: delta,
      deltaPercent: pct,
    );
  }

  /// Czy rekord historyczny został pobity.
  bool get isNewRouteRecord => deltaValue > 0.005;

  /// Czy wynik zbliżył się na mniej niż 2.5% do rekordu wszech czasów.
  bool get isNearRecord => !isNewRouteRecord && deltaPercent >= -2.5;

  String get formattedDelta {
    final String sign = deltaValue >= 0 ? '+' : '';
    if (interval == PowerRecordInterval.sprint5s) {
      return '$sign${deltaValue.round()} W ($sign${deltaPercent.toStringAsFixed(1)}%)';
    }
    return '$sign${deltaValue.toStringAsFixed(2)} W/kg ($sign${deltaPercent.toStringAsFixed(1)}%)';
  }

  String get shortDelta {
    final String sign = deltaValue >= 0 ? '+' : '';
    if (interval == PowerRecordInterval.sprint5s) {
      return '$sign${deltaValue.round()} W';
    }
    return '$sign${deltaValue.toStringAsFixed(2)}';
  }
}

/// Pełny zestaw danych do wyświetlenia tabeli rekordów mocy dnia po etapie.
class PostRaceWattsPerKgLeaderboardData {
  final String stageName;
  final String routeName;
  final List<PostRacePowerRecordEntry> entries;
  final Map<PowerRecordInterval, HistoricalRoutePowerRecord> historicalRecords;

  const PostRaceWattsPerKgLeaderboardData({
    required this.stageName,
    required this.routeName,
    required this.entries,
    required this.historicalRecords,
  });

  factory PostRaceWattsPerKgLeaderboardData.empty({
    String stageName = 'Etap',
    String routeName = 'Trasa wyścigu',
  }) {
    return PostRaceWattsPerKgLeaderboardData(
      stageName: stageName,
      routeName: routeName,
      entries: const [],
      historicalRecords: _defaultHistoricalRecords(StageType.highMountain, routeName),
    );
  }

  /// Buduje deterministyczne, realistyczne rekordy mocy dnia na podstawie
  /// wyników etapu (`StageSummaryReport`) oraz profili fizjologicznych z `CareerSave`.
  factory PostRaceWattsPerKgLeaderboardData.fromStageReport({
    required StageSummaryReport report,
    required String playerTeamId,
    CareerSave? save,
  }) {
    final ridersById = <String, Rider>{
      if (save != null)
        for (final r in save.riders) r.id: r,
    };
    final teamsById = <String, CyclingTeam>{
      if (save != null)
        for (final t in save.teams) t.id: t,
    };

    final candidates = report.results.where((r) => !r.isDnf).toList(growable: false);
    final entries = <PostRacePowerRecordEntry>[];

    for (final res in candidates.take(24)) {
      final Rider? rider = ridersById[res.riderId];
      final CyclingTeam? team = teamsById[res.teamId];
      final bool isPlayer = res.teamId == playerTeamId;

      final int seed = res.riderId.codeUnits.fold<int>(0, (acc, c) => acc + c) + report.stageNumber * 31;
      final math.Random rng = math.Random(seed);

      final double weightKg = rider?.physiology.weightKg ?? (60.0 + (seed % 18).toDouble());
      final double rankBoost = math.max(0.86, 1.04 - (res.rank - 1) * 0.008);
      final double terrainSprintFactor = report.stageType == StageType.flat ? 1.03 : 0.96;
      final double terrainClimbFactor = (report.stageType == StageType.highMountain ||
              report.stageType == StageType.summitFinish ||
              report.stageType == StageType.hilly)
          ? 1.02
          : 0.94;

      final int base5s = rider?.powerProfile.watts5s ?? (1180 + (seed % 420));
      final int base1m = rider?.powerProfile.watts1m ?? (620 + (seed % 160));
      final int base5m = rider?.powerProfile.watts5m ?? (450 + (seed % 95));
      final int base20m = rider?.powerProfile.watts20m ?? (390 + (seed % 85));

      final int peak5s = (base5s * rankBoost * terrainSprintFactor * (0.95 + rng.nextDouble() * 0.08)).round();
      final int peak1m = (base1m * rankBoost * (0.94 + rng.nextDouble() * 0.08)).round();
      final int peak5m = (base5m * rankBoost * terrainClimbFactor * (0.95 + rng.nextDouble() * 0.07)).round();
      final int peak20m = (base20m * rankBoost * terrainClimbFactor * (0.95 + rng.nextDouble() * 0.07)).round();

      final String teamName = team?.name ?? _formatTeamFallback(res.teamId, isPlayer);
      final Color teamColor = team != null
          ? _parseHexColor(team.primaryJerseyColorHex)
          : (isPlayer ? AppColors.goldAccent : AppColors.accentBlue);

      entries.add(
        PostRacePowerRecordEntry(
          riderId: res.riderId,
          riderName: res.riderName,
          teamId: res.teamId,
          teamName: teamName,
          teamShortCode: _buildShortCode(teamName),
          teamColor: teamColor,
          isPlayerTeam: isPlayer,
          weightKg: weightKg,
          peak5sWatts: peak5s,
          peak1mWatts: peak1m,
          peak5mWatts: peak5m,
          peak20mWatts: peak20m,
          segmentLocation: _inferSegmentLocation(report.stageType, res.rank),
        ),
      );
    }

    return PostRaceWattsPerKgLeaderboardData(
      stageName: 'Etap ${report.stageNumber}: ${report.stageName}',
      routeName: report.stageName,
      entries: entries,
      historicalRecords: _defaultHistoricalRecords(report.stageType, report.stageName),
    );
  }

  /// Zwraca listę posortowaną malejąco dla wybranego interwału (opcjonalnie przefiltrowaną).
  List<PostRacePowerRecordEntry> sortedEntries(
    PowerRecordInterval interval, {
    bool onlyPlayerTeam = false,
  }) {
    final filtered = onlyPlayerTeam
        ? entries.where((e) => e.isPlayerTeam).toList()
        : List<PostRacePowerRecordEntry>.from(entries);
    filtered.sort(
      (a, b) => b.valueForInterval(interval).compareTo(a.valueForInterval(interval)),
    );
    return filtered;
  }

  /// Najlepszy wynik dnia dla wskazanego interwału.
  PostRacePowerRecordEntry? bestEntryFor(PowerRecordInterval interval) {
    if (entries.isEmpty) return null;
    PostRacePowerRecordEntry best = entries.first;
    double bestVal = best.valueForInterval(interval);
    for (final entry in entries.skip(1)) {
      final val = entry.valueForInterval(interval);
      if (val > bestVal) {
        best = entry;
        bestVal = val;
      }
    }
    return best;
  }

  /// Porównuje dany wynik z historycznym rekordem trasy dla wskazanego interwału.
  PowerRecordComparison? compareWithHistorical(
    PowerRecordInterval interval,
    double dayValue,
  ) {
    final hist = historicalRecords[interval];
    if (hist == null) return null;
    return PowerRecordComparison.compute(
      interval: interval,
      dayValue: dayValue,
      historicalRecord: hist,
    );
  }

  static Map<PowerRecordInterval, HistoricalRoutePowerRecord> _defaultHistoricalRecords(
    StageType stageType,
    String routeName,
  ) {
    final bool isFlat = stageType == StageType.flat;
    final bool isMountain = stageType == StageType.highMountain ||
        stageType == StageType.summitFinish;
    return {
      PowerRecordInterval.sprint5s: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.sprint5s,
        recordValue: isFlat ? 1685.0 : 1540.0,
        holderName: isFlat ? 'M. Kittel' : 'P. Sagan',
        recordYear: isFlat ? 2017 : 2018,
        routeOrClimbName: '$routeName — Meta',
      ),
      PowerRecordInterval.attack1m: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.attack1m,
        recordValue: 11.45,
        holderName: 'M. van der Poel',
        recordYear: 2023,
        routeOrClimbName: '$routeName — Finałowy zryw',
      ),
      PowerRecordInterval.vo2Max5m: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.vo2Max5m,
        recordValue: 7.42,
        holderName: 'T. Pogačar',
        recordYear: 2024,
        routeOrClimbName: '$routeName — Sektor ataku',
      ),
      PowerRecordInterval.climb20m: HistoricalRoutePowerRecord(
        interval: PowerRecordInterval.climb20m,
        recordValue: isMountain ? 6.58 : 6.18,
        holderName: isMountain ? 'M. Pantani' : 'R. Evenepoel',
        recordYear: isMountain ? 1998 : 2024,
        routeOrClimbName: '$routeName — Kluczowy podjazd',
      ),
    };
  }

  static Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      final int? parsed = int.tryParse('FF$cleaned', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return AppColors.accentBlue;
  }

  static String _formatTeamFallback(String teamId, bool isPlayer) {
    if (isPlayer) return 'Twoja Drużyna';
    return teamId.replaceAll('_', ' ').toUpperCase();
  }

  static String _buildShortCode(String teamName) {
    final parts = teamName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PRO';
    if (parts.length == 1) {
      return parts.first.substring(0, math.min(3, parts.first.length)).toUpperCase();
    }
    return parts.take(3).map((p) => p[0].toUpperCase()).join();
  }

  static String _inferSegmentLocation(StageType stageType, int rank) {
    if (rank <= 3 && stageType == StageType.flat) return 'Finisz Sprinterski';
    if (stageType == StageType.highMountain || stageType == StageType.summitFinish) {
      return 'Finałowy Podjazd HC';
    }
    if (stageType == StageType.hilly) return 'Ścianka / Côte';
    if (stageType == StageType.individualTimeTrial ||
        stageType == StageType.teamTimeTrial) {
      return 'Pomiar Czasu';
    }
    if (stageType == StageType.cobbleClassic) return 'Sektor Brukowy';
    return 'Kluczowy Sektor';
  }
}

/// Tabela podsumowania etapu zestawiająca najlepsze rekordy mocy dnia
/// (`5s Sprint (W)`, `1m Attack (W/kg)`, `5m VO2max (W/kg)`, `20m Climb (W/kg)`)
/// wraz z porównaniem do historycznych rekordów trasy.
class PostRaceWattsPerKgLeaderboardCard extends StatefulWidget {
  final PostRaceWattsPerKgLeaderboardData data;
  final PowerRecordInterval initialInterval;
  final ValueChanged<PostRacePowerRecordEntry>? onRiderTap;
  final bool initiallyShowOnlyPlayerTeam;

  const PostRaceWattsPerKgLeaderboardCard({
    super.key,
    required this.data,
    this.initialInterval = PowerRecordInterval.climb20m,
    this.onRiderTap,
    this.initiallyShowOnlyPlayerTeam = false,
  });

  @override
  State<PostRaceWattsPerKgLeaderboardCard> createState() =>
      _PostRaceWattsPerKgLeaderboardCardState();
}

class _PostRaceWattsPerKgLeaderboardCardState
    extends State<PostRaceWattsPerKgLeaderboardCard> {
  late PowerRecordInterval _selectedInterval;
  late bool _onlyPlayerTeam;
  String? _hoveredRiderId;
  PowerRecordInterval? _hoveredSummaryInterval;

  @override
  void initState() {
    super.initState();
    _selectedInterval = widget.initialInterval;
    _onlyPlayerTeam = widget.initiallyShowOnlyPlayerTeam;
  }

  bool get _hasPlayerEntries =>
      widget.data.entries.any((entry) => entry.isPlayerTeam);

  void _selectInterval(PowerRecordInterval interval) {
    if (_selectedInterval == interval) return;
    setState(() {
      _selectedInterval = interval;
    });
  }

  void _togglePlayerFilter() {
    if (!_hasPlayerEntries) return;
    setState(() {
      _onlyPlayerTeam = !_onlyPlayerTeam;
    });
  }

  void _resetFilters() {
    setState(() {
      _onlyPlayerTeam = false;
      _selectedInterval = widget.initialInterval;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<PostRacePowerRecordEntry> sortedRows = widget.data.sortedEntries(
      _selectedInterval,
      onlyPlayerTeam: _onlyPlayerTeam,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final bool isMobile = width < 600;
          final bool isDesktop = width >= 980;
          final double pad = isMobile ? 14 : 20;

          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isMobile: isMobile),
                const SizedBox(height: 16),
                _buildSummaryCardsGrid(
                  width: width - pad * 2,
                  isMobile: isMobile,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildIntervalFilterToolbar(isMobile: isMobile),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: sortedRows.isEmpty
                      ? _buildEmptyState()
                      : (isMobile
                          ? _buildMobileLeaderboardList(sortedRows)
                          : _buildDesktopLeaderboardTable(sortedRows)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    final Widget titleGroup = Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.speed_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rekordy Mocy Dnia (W / W/kg)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.data.stageName} • Porównanie z historycznymi rekordami trasy',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final Widget filterButton = _PlayerTeamToggleButton(
      active: _onlyPlayerTeam,
      enabled: _hasPlayerEntries,
      onPressed: _togglePlayerFilter,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleGroup,
          const SizedBox(height: 12),
          filterButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleGroup),
        const SizedBox(width: 12),
        filterButton,
      ],
    );
  }

  Widget _buildSummaryCardsGrid({
    required double width,
    required bool isMobile,
    required bool isDesktop,
  }) {
    final int columns = isDesktop ? 4 : (width >= 520 ? 2 : 1);
    const double spacing = 10;
    final double cardWidth = columns == 1
        ? width
        : (width - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: PowerRecordInterval.values.map((interval) {
        final PostRacePowerRecordEntry? dayBest = widget.data.bestEntryFor(interval);
        final HistoricalRoutePowerRecord? historical =
            widget.data.historicalRecords[interval];
        final PowerRecordComparison? comparison = (dayBest != null && historical != null)
            ? PowerRecordComparison.compute(
                interval: interval,
                dayValue: dayBest.valueForInterval(interval),
                historicalRecord: historical,
              )
            : null;

        final bool isSelected = _selectedInterval == interval;
        final bool isHovered = _hoveredSummaryInterval == interval;

        return SizedBox(
          width: math.max(120, cardWidth),
          child: _SummaryIntervalCard(
            interval: interval,
            dayBest: dayBest,
            historicalRecord: historical,
            comparison: comparison,
            isSelected: isSelected,
            isHovered: isHovered,
            compact: isMobile,
            onHoverChanged: (hovering) {
              setState(() {
                _hoveredSummaryInterval = hovering ? interval : null;
              });
            },
            onTap: () => _selectInterval(interval),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIntervalFilterToolbar({required bool isMobile}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Sortuj wg:',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        for (final interval in PowerRecordInterval.values)
          _IntervalFilterChip(
            interval: interval,
            selected: _selectedInterval == interval,
            compact: isMobile,
            onTap: () => _selectInterval(interval),
          ),
      ],
    );
  }

  Widget _buildDesktopLeaderboardTable(List<PostRacePowerRecordEntry> rows) {
    final HistoricalRoutePowerRecord? activeHistorical =
        widget.data.historicalRecords[_selectedInterval];

    return Container(
      key: ValueKey('desktop_table_${_selectedInterval.name}_$_onlyPlayerTeam'),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Nagłówek tabeli z możliwością kliknięcia kolumny
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 38,
                  child: Text(
                    '#',
                    style: _tableHeaderStyle,
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'KOLARZ / DRUŻYNA',
                    style: _tableHeaderStyle,
                  ),
                ),
                for (final interval in PowerRecordInterval.values)
                  Expanded(
                    flex: 2,
                    child: _SortableColumnHeader(
                      label: interval.label,
                      isActive: _selectedInterval == interval,
                      accentColor: interval.zoneColor,
                      onTap: () => _selectInterval(interval),
                    ),
                  ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'VS REKORD TRASY',
                    textAlign: TextAlign.right,
                    style: _tableHeaderStyle,
                  ),
                ),
              ],
            ),
          ),
          // Wiersze kolarzy
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
            _DesktopLeaderboardRow(
              rank: i + 1,
              entry: rows[i],
              activeInterval: _selectedInterval,
              historicalRecord: activeHistorical,
              isHovered: _hoveredRiderId == rows[i].riderId,
              onHoverChanged: (hovering) {
                setState(() {
                  _hoveredRiderId = hovering ? rows[i].riderId : null;
                });
              },
              onTap: widget.onRiderTap != null
                  ? () => widget.onRiderTap!(rows[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileLeaderboardList(List<PostRacePowerRecordEntry> rows) {
    final HistoricalRoutePowerRecord? activeHistorical =
        widget.data.historicalRecords[_selectedInterval];

    return Column(
      key: ValueKey('mobile_list_${_selectedInterval.name}_$_onlyPlayerTeam'),
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _MobileLeaderboardRowCard(
            rank: i + 1,
            entry: rows[i],
            activeInterval: _selectedInterval,
            historicalRecord: activeHistorical,
            onTap: widget.onRiderTap != null
                ? () => widget.onRiderTap!(rows[i])
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      key: const ValueKey('empty_power_leaderboard'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak zarejestrowanych rekordów mocy dla wybranego filtra.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ukończ etap lub zmień filtr drużyny, aby zobaczyć pełne zestawienie W/kg.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (_onlyPlayerTeam) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Pokaż cały peleton'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldAccent,
                side: const BorderSide(color: AppColors.goldAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const TextStyle _tableHeaderStyle = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );
}

class _PlayerTeamToggleButton extends StatelessWidget {
  final bool active;
  final bool enabled;
  final VoidCallback onPressed;

  const _PlayerTeamToggleButton({
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !enabled
        ? AppColors.cardBorder
        : (active ? AppColors.goldAccent : AppTheme.borderColor);
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (active
            ? AppColors.goldAccent.withValues(alpha: 0.16)
            : AppColors.surfaceLight);
    final Color textColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (active ? AppColors.goldAccent : AppColors.textPrimary);

    return Tooltip(
      message: enabled
          ? 'Filtruj wyniki do kolarzy Twojej drużyny'
          : 'Brak kolarzy Twojej drużyny na liście',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.goldAccent.withValues(alpha: 0.1),
          focusColor: AppColors.goldAccent.withValues(alpha: 0.18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.check_circle_rounded : Icons.shield_outlined,
                  size: 15,
                  color: textColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tylko moja drużyna',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _SummaryIntervalCard extends StatelessWidget {
  final PowerRecordInterval interval;
  final PostRacePowerRecordEntry? dayBest;
  final HistoricalRoutePowerRecord? historicalRecord;
  final PowerRecordComparison? comparison;
  final bool isSelected;
  final bool isHovered;
  final bool compact;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  const _SummaryIntervalCard({
    required this.interval,
    required this.dayBest,
    required this.historicalRecord,
    required this.comparison,
    required this.isSelected,
    required this.isHovered,
    required this.compact,
    required this.onHoverChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNewRecord = comparison?.isNewRouteRecord ?? false;
    final Color borderColor = isSelected
        ? AppColors.goldAccent
        : (isHovered ? interval.zoneColor.withValues(alpha: 0.7) : AppColors.cardBorder);

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: interval.zoneColor.withValues(alpha: 0.08),
          focusColor: AppColors.goldAccent.withValues(alpha: 0.16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.surfaceLight
                  : AppColors.background.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.4 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(interval.icon, size: 15, color: interval.zoneColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        interval.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNewRecord)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccess.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.statusSuccess.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Text(
                          'REKORD',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.statusSuccess,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dayBest != null ? dayBest!.formattedValueForInterval(interval) : '--',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dayBest != null
                      ? '${dayBest!.riderName} (${dayBest!.teamShortCode})'
                      : 'Brak danych',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: (dayBest?.isPlayerTeam ?? false)
                        ? AppColors.goldAccent
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                const SizedBox(height: 7),
                if (historicalRecord != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hist: ${historicalRecord!.formattedRecord} (${historicalRecord!.holderName} ${historicalRecord!.recordYear})',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (comparison != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          comparison!.shortDelta,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: comparison!.isNewRouteRecord
                                ? AppColors.statusSuccess
                                : (comparison!.isNearRecord
                                    ? AppColors.amberWarning
                                    : AppColors.textSecondary),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
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

class _IntervalFilterChip extends StatelessWidget {
  final PowerRecordInterval interval;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _IntervalFilterChip({
    required this.interval,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = interval.zoneColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        hoverColor: accent.withValues(alpha: 0.12),
        focusColor: accent.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.2)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                interval.icon,
                size: 13,
                color: selected ? accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                compact ? interval.shortLabel : interval.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortableColumnHeader extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _SortableColumnHeader({
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: accentColor.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: isActive ? accentColor : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_downward_rounded,
                size: 12,
                color: accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopLeaderboardRow extends StatelessWidget {
  final int rank;
  final PostRacePowerRecordEntry entry;
  final PowerRecordInterval activeInterval;
  final HistoricalRoutePowerRecord? historicalRecord;
  final bool isHovered;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback? onTap;

  const _DesktopLeaderboardRow({
    required this.rank,
    required this.entry,
    required this.activeInterval,
    required this.historicalRecord,
    required this.isHovered,
    required this.onHoverChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final PowerRecordComparison? comparison = historicalRecord != null
        ? PowerRecordComparison.compute(
            interval: activeInterval,
            dayValue: entry.valueForInterval(activeInterval),
            historicalRecord: historicalRecord!,
          )
        : null;

    final Color rowBg = isHovered
        ? AppColors.surfaceLight.withValues(alpha: 0.75)
        : (entry.isPlayerTeam
            ? AppColors.goldAccent.withValues(alpha: 0.08)
            : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.surfaceLight.withValues(alpha: 0.5),
          focusColor: AppColors.goldAccent.withValues(alpha: 0.14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            color: rowBg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: _RankBadge(rank: rank),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 28,
                        decoration: BoxDecoration(
                          color: entry.teamColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    entry.riderName,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: entry.isPlayerTeam
                                          ? AppColors.goldAccent
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (entry.isPlayerTeam) ...[
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: AppColors.goldAccent,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${entry.teamName} · ${entry.weightKg.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (final interval in PowerRecordInterval.values)
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.formattedCompactValue(interval),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: activeInterval == interval
                            ? interval.zoneColor
                            : AppColors.textPrimary,
                        fontSize: activeInterval == interval ? 13.5 : 12.5,
                        fontWeight: activeInterval == interval
                            ? FontWeight.w800
                            : FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: comparison != null
                        ? _ComparisonPill(comparison: comparison)
                        : const Text(
                            '—',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
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

class _MobileLeaderboardRowCard extends StatelessWidget {
  final int rank;
  final PostRacePowerRecordEntry entry;
  final PowerRecordInterval activeInterval;
  final HistoricalRoutePowerRecord? historicalRecord;
  final VoidCallback? onTap;

  const _MobileLeaderboardRowCard({
    required this.rank,
    required this.entry,
    required this.activeInterval,
    required this.historicalRecord,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final PowerRecordComparison? comparison = historicalRecord != null
        ? PowerRecordComparison.compute(
            interval: activeInterval,
            dayValue: entry.valueForInterval(activeInterval),
            historicalRecord: historicalRecord!,
          )
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: entry.isPlayerTeam
                ? AppColors.goldAccent.withValues(alpha: 0.08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: entry.isPlayerTeam
                  ? AppColors.goldAccent.withValues(alpha: 0.45)
                  : AppColors.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RankBadge(rank: rank),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.riderName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: entry.isPlayerTeam
                                ? AppColors.goldAccent
                                : AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${entry.teamShortCode} · ${entry.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        entry.formattedValueForInterval(activeInterval),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: activeInterval.zoneColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (comparison != null) ...[
                        const SizedBox(height: 2),
                        _ComparisonPill(comparison: comparison, compact: true),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: PowerRecordInterval.values.map((interval) {
                  final bool isCurrent = interval == activeInterval;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? interval.zoneColor.withValues(alpha: 0.16)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? interval.zoneColor.withValues(alpha: 0.6)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      '${interval.shortLabel}: ${entry.formattedCompactValue(interval)}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isCurrent
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = AppColors.surfaceLight;
    Color textColor = AppColors.textSecondary;

    if (rank == 1) {
      badgeColor = AppColors.goldAccent.withValues(alpha: 0.22);
      textColor = AppColors.goldAccent;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFCBD5E1).withValues(alpha: 0.18);
      textColor = const Color(0xFFCBD5E1);
    } else if (rank == 3) {
      badgeColor = const Color(0xFFB45309).withValues(alpha: 0.22);
      textColor = const Color(0xFFF59E0B);
    }

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontFamily: 'Inter',
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ComparisonPill extends StatelessWidget {
  final PowerRecordComparison comparison;
  final bool compact;

  const _ComparisonPill({
    required this.comparison,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNew = comparison.isNewRouteRecord;
    final bool isNear = comparison.isNearRecord;

    final Color color = isNew
        ? AppColors.statusSuccess
        : (isNear ? AppColors.amberWarning : AppColors.textSecondary);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isNew ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isNew ? 0.6 : 0.3),
        ),
      ),
      child: Text(
        isNew
            ? 'NEW ${comparison.shortDelta}'
            : (compact ? comparison.shortDelta : comparison.formattedDelta),
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
