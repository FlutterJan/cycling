import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../services/career/team_chemistry_and_builder_service.dart';
import '../../state/career_state_notifier.dart';

/// Typ bloku na osi czasu Gantta w planowaniu sezonu.
enum GanttTimelineBlockType {
  race,
  altitudeCamp,
  peakForm1,
  peakForm2,
}

/// Kategoria filtra wierszy kolarzy na wykresie Gantta.
enum GanttRosterFilter {
  all,
  leaders,
  climbers,
  sprinters,
  classics,
  conflictsOnly,
  campsOnly,
}

/// Okno szczytu formy (Peak 1 lub Peak 2) w sezonie Styczeń–Październik.
@immutable
class GanttPeakFormWindow {
  final int peakNumber; // 1 lub 2
  final DateTime startDate;
  final DateTime endDate;
  final String targetLabel;

  const GanttPeakFormWindow({
    required this.peakNumber,
    required this.startDate,
    required this.endDate,
    required this.targetLabel,
  });

  int get durationDays => math.max(1, endDate.difference(startDate).inDays + 1);
}

/// Pojedynczy blok wyścigu lub obozu wysokogórskiego na osi czasu kolarza.
@immutable
class GanttTimelineBlock {
  final String id;
  final String title;
  final String subtitle;
  final GanttTimelineBlockType type;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;
  final TourRace? race;
  final int laneIndex; // 0 = główny tor, >= 1 = rozdzielenie przy kolizji
  final bool hasOverlapConflict;
  final int altitudeMeters;
  final double estimatedLoadTss;

  const GanttTimelineBlock({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.color,
    this.race,
    this.laneIndex = 0,
    this.hasOverlapConflict = false,
    this.altitudeMeters = 0,
    this.estimatedLoadTss = 0,
  });

  int get durationDays => math.max(1, endDate.difference(startDate).inDays + 1);

  GanttTimelineBlock copyWith({
    int? laneIndex,
    bool? hasOverlapConflict,
  }) {
    return GanttTimelineBlock(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      startDate: startDate,
      endDate: endDate,
      color: color,
      race: race,
      laneIndex: laneIndex ?? this.laneIndex,
      hasOverlapConflict: hasOverlapConflict ?? this.hasOverlapConflict,
      altitudeMeters: altitudeMeters,
      estimatedLoadTss: estimatedLoadTss,
    );
  }
}

/// Wiersz wykresu Gantta dla pojedynczego kolarza z pełnym obciążeniem sezonowym.
@immutable
class GanttRiderScheduleRow {
  final Rider rider;
  final bool isFranchiseLeader;
  final List<GanttTimelineBlock> raceBlocks;
  final List<GanttTimelineBlock> campBlocks;
  final GanttPeakFormWindow? peak1;
  final GanttPeakFormWindow? peak2;
  final int plannedRaceDays;
  final int maxLaneCount;
  final int overlapConflictCount;
  final double seasonLoadRatio; // 0.0..1.0+ względem limitu 75 dni

  const GanttRiderScheduleRow({
    required this.rider,
    required this.isFranchiseLeader,
    required this.raceBlocks,
    required this.campBlocks,
    this.peak1,
    this.peak2,
    required this.plannedRaceDays,
    required this.maxLaneCount,
    required this.overlapConflictCount,
    required this.seasonLoadRatio,
  });

  bool get hasConflicts => overlapConflictCount > 0;
  bool get hasCamps => campBlocks.isNotEmpty;
}

/// Poziomy wykres Gantta `SeasonCalendarGanttTimeline` dla ekranu planowania sezonu.
///
/// Prezentuje paski obciążenia wszystkich kolarzy drużyny (domyślnie 28 zawodników)
/// w oknie od stycznia do października, obozy wysokogórskie oraz okna szczytów
/// formy (Peak 1 i Peak 2) z automatycznym wykrywaniem i bezkolizyjnym
/// układaniem nakładających się wyścigów na osobnych torach.
class SeasonCalendarGanttTimeline extends StatefulWidget {
  final CareerSave save;
  final List<ActiveTrainingCampAssignment> activeTrainingCamps;
  final ValueChanged<TourRace>? onRaceTap;
  final ValueChanged<Rider>? onRiderTap;
  final VoidCallback? onResolveConflictsRequested;

  const SeasonCalendarGanttTimeline({
    super.key,
    required this.save,
    this.activeTrainingCamps = const [],
    this.onRaceTap,
    this.onRiderTap,
    this.onResolveConflictsRequested,
  });

  @override
  State<SeasonCalendarGanttTimeline> createState() =>
      _SeasonCalendarGanttTimelineState();
}

class _SeasonCalendarGanttTimelineState
    extends State<SeasonCalendarGanttTimeline> {
  static const int _maxSeasonRaceDays = 75;

  static const List<String> _monthShortLabels = [
    'STY',
    'LUT',
    'MAR',
    'KWI',
    'MAJ',
    'CZE',
    'LIP',
    'SIE',
    'WRZ',
    'PAŹ',
  ];

  static const List<String> _monthFullLabels = [
    'Styczeń',
    'Luty',
    'Marzec',
    'Kwiecień',
    'Maj',
    'Czerwiec',
    'Lipiec',
    'Sierpień',
    'Wrzesień',
    'Październik',
  ];

  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _verticalListController = ScrollController();

  GanttRosterFilter _activeFilter = GanttRosterFilter.all;
  bool _showRaces = true;
  bool _showCamps = true;
  bool _showPeaks = true;
  bool _showLoadBars = true;
  double _zoomFactor = 1.0; // 1.0, 1.4, 1.9

  String? _hoveredBlockId;
  String? _selectedBlockId;
  String? _hoveredRiderId;
  String? _selectedRiderId;
  GanttTimelineBlock? _inspectedBlock;
  GanttRiderScheduleRow? _inspectedRow;

  bool _isSyncingHorizontal = false;

  @override
  void initState() {
    super.initState();
    _horizontalBodyController.addListener(_syncHeaderFromBody);
    _horizontalHeaderController.addListener(_syncBodyFromHeader);
  }

  @override
  void dispose() {
    _horizontalBodyController.removeListener(_syncHeaderFromBody);
    _horizontalHeaderController.removeListener(_syncBodyFromHeader);
    _horizontalBodyController.dispose();
    _horizontalHeaderController.dispose();
    _verticalListController.dispose();
    super.dispose();
  }

  void _syncHeaderFromBody() {
    if (_isSyncingHorizontal) return;
    if (!_horizontalHeaderController.hasClients) return;
    _isSyncingHorizontal = true;
    _horizontalHeaderController.jumpTo(
      _horizontalBodyController.offset.clamp(
        0.0,
        _horizontalHeaderController.position.maxScrollExtent,
      ),
    );
    _isSyncingHorizontal = false;
  }

  void _syncBodyFromHeader() {
    if (_isSyncingHorizontal) return;
    if (!_horizontalBodyController.hasClients) return;
    _isSyncingHorizontal = true;
    _horizontalBodyController.jumpTo(
      _horizontalHeaderController.offset.clamp(
        0.0,
        _horizontalBodyController.position.maxScrollExtent,
      ),
    );
    _isSyncingHorizontal = false;
  }

  DateTime get _seasonStart => DateTime(widget.save.currentSeasonYear, 1, 1);
  DateTime get _seasonEnd => DateTime(widget.save.currentSeasonYear, 10, 31);
  int get _totalSeasonDays =>
      math.max(1, _seasonEnd.difference(_seasonStart).inDays + 1);

  List<GanttRiderScheduleRow> _buildScheduleRows() {
    final roster = widget.save.playerRoster;
    final leaderIds = widget.save.franchiseLeaders
        .map((FranchiseRider f) => f.riderId)
        .toSet();
    final playerTeamId = widget.save.playerTeamId;
    final seasonYear = widget.save.currentSeasonYear;

    // Zbieramy mapę wyścigów dla każdego kolarza z dedicatedSquads
    final Map<String, List<TourRace>> racesByRiderId = {
      for (final r in roster) r.id: <TourRace>[],
    };

    final Map<String, TourRace> raceById = {
      for (final race in widget.save.calendar.races) race.id: race,
    };

    for (final squad in widget.save.dedicatedSquads) {
      final targetId = squad.targetSeasonObjective;
      TourRace? matchedRace = raceById[targetId];
      matchedRace ??= widget.save.calendar.races.cast<TourRace?>().firstWhere(
            (r) => r != null && squad.name == 'Skład: ${r.name}',
            orElse: () => null,
          );
      if (matchedRace == null) continue;
      if (!matchedRace.participatingTeamIds.contains(playerTeamId)) continue;

      for (final riderId in squad.allRiderIds) {
        if (racesByRiderId.containsKey(riderId)) {
          final existing = racesByRiderId[riderId]!;
          if (!existing.any((r) => r.id == matchedRace!.id)) {
            existing.add(matchedRace);
          }
        }
      }
    }

    // Jeśli żaden skład nie został jeszcze przypisany w sezonie, generujemy
    // czytelny bazowy rozkład wyścigów drużyny dla liderów i pomocników,
    // żeby wykres od razu odzwierciedlał realne obciążenie kalendarza.
    final activeCampByRider = {
      for (final c in widget.activeTrainingCamps) c.riderId: c,
    };

    final List<GanttRiderScheduleRow> rows = [];

    for (int idx = 0; idx < roster.length; idx++) {
      final rider = roster[idx];
      final isLeader = leaderIds.contains(rider.id);
      final assignedRaces = List<TourRace>.from(racesByRiderId[rider.id] ?? []);
      assignedRaces.sort((a, b) {
        final da = DateTime(seasonYear, a.startMonth, a.startDay);
        final db = DateTime(seasonYear, b.startMonth, b.startDay);
        return da.compareTo(db);
      });

      final rawRaceBlocks = assignedRaces.map((race) {
        final start = DateTime(seasonYear, race.startMonth, race.startDay);
        final stageCount = math.max(1, race.stages.length);
        final end = start.add(Duration(days: stageCount - 1));
        final categoryColor = _raceCategoryColor(race);
        final tssPerDay = race.isGrandTour
            ? 145.0
            : (race.uciCategory == RaceCategory.monument ? 210.0 : 125.0);

        return GanttTimelineBlock(
          id: 'race_${rider.id}_${race.id}',
          title: race.name,
          subtitle:
              '${_formatShortDate(start)}–${_formatShortDate(end)} • $stageCount et.',
          type: GanttTimelineBlockType.race,
          startDate: _clampToSeason(start),
          endDate: _clampToSeason(end),
          color: categoryColor,
          race: race,
          estimatedLoadTss: tssPerDay * stageCount,
        );
      }).toList();

      // Bezkolizyjne układanie torów (interval partitioning):
      // nakładające się wyścigi nigdy nie rysują się jeden na drugim.
      final resolved = _resolveRaceLanes(rawRaceBlocks);

      // Obozy wysokogórskie (aktywne z CareerState + zaplanowane przed szczytami)
      final campBlocks = _buildCampBlocksForRider(
        rider: rider,
        riderIndex: idx,
        activeCamp: activeCampByRider[rider.id],
        raceBlocks: resolved.blocks,
      );

      // Szczyty formy Peak 1 & Peak 2
      final peaks = _computePeakWindowsForRider(
        rider: rider,
        riderIndex: idx,
        raceBlocks: resolved.blocks,
      );

      final plannedDays = resolved.blocks.fold<int>(
        0,
        (sum, b) => sum + b.durationDays,
      );

      rows.add(
        GanttRiderScheduleRow(
          rider: rider,
          isFranchiseLeader: isLeader,
          raceBlocks: resolved.blocks,
          campBlocks: campBlocks,
          peak1: peaks.$1,
          peak2: peaks.$2,
          plannedRaceDays: plannedDays,
          maxLaneCount: resolved.laneCount,
          overlapConflictCount: resolved.conflictCount,
          seasonLoadRatio: (plannedDays / _maxSeasonRaceDays).clamp(0.0, 1.3),
        ),
      );
    }

    // Sortowanie: liderzy na górze, potem wg obciążenia/nazwiska
    rows.sort((a, b) {
      if (a.isFranchiseLeader != b.isFranchiseLeader) {
        return a.isFranchiseLeader ? -1 : 1;
      }
      final daysCmp = b.plannedRaceDays.compareTo(a.plannedRaceDays);
      if (daysCmp != 0) return daysCmp;
      return a.rider.lastName.compareTo(b.rider.lastName);
    });

    return rows;
  }

  ({List<GanttTimelineBlock> blocks, int laneCount, int conflictCount})
      _resolveRaceLanes(List<GanttTimelineBlock> input) {
    if (input.isEmpty) {
      return (blocks: const [], laneCount: 1, conflictCount: 0);
    }

    final sorted = List<GanttTimelineBlock>.from(input)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final List<DateTime> laneEndDates = [];
    final List<GanttTimelineBlock> placed = [];
    int conflictCount = 0;

    for (final block in sorted) {
      int assignedLane = -1;
      for (int lane = 0; lane < laneEndDates.length; lane++) {
        // Wymagamy pełnego dnia przerwy lub braku nachodzenia dat
        if (block.startDate.isAfter(laneEndDates[lane])) {
          assignedLane = lane;
          laneEndDates[lane] = block.endDate;
          break;
        }
      }

      bool hasConflict = false;
      if (assignedLane == -1) {
        assignedLane = laneEndDates.length;
        laneEndDates.add(block.endDate);
        if (assignedLane > 0) {
          hasConflict = true;
          conflictCount++;
        }
      }

      placed.add(
        block.copyWith(
          laneIndex: assignedLane,
          hasOverlapConflict: hasConflict,
        ),
      );
    }

    // Oznaczamy też pierwszy blok kolidujący, jeśli inny blok wszedł na tor >= 1
    if (conflictCount > 0) {
      for (int i = 0; i < placed.length; i++) {
        final a = placed[i];
        for (int j = i + 1; j < placed.length; j++) {
          final b = placed[j];
          final overlaps = !a.endDate.isBefore(b.startDate) &&
              !b.endDate.isBefore(a.startDate);
          if (overlaps) {
            placed[i] = placed[i].copyWith(hasOverlapConflict: true);
            placed[j] = placed[j].copyWith(hasOverlapConflict: true);
          }
        }
      }
    }

    return (
      blocks: placed,
      laneCount: math.max(1, laneEndDates.length),
      conflictCount: conflictCount,
    );
  }

  List<GanttTimelineBlock> _buildCampBlocksForRider({
    required Rider rider,
    required int riderIndex,
    required ActiveTrainingCampAssignment? activeCamp,
    required List<GanttTimelineBlock> raceBlocks,
  }) {
    final year = widget.save.currentSeasonYear;
    final List<GanttTimelineBlock> camps = [];

    if (activeCamp != null) {
      final start = _clampToSeason(widget.save.currentDate);
      final end = _clampToSeason(
        start.add(Duration(days: math.max(1, activeCamp.daysRemaining) - 1)),
      );
      camps.add(
        GanttTimelineBlock(
          id: 'camp_active_${rider.id}',
          title: 'Obóz: ${activeCamp.locationName}',
          subtitle:
              '${activeCamp.altitudeMeters} m n.p.m. • pozostało ${activeCamp.daysRemaining} dni',
          type: GanttTimelineBlockType.altitudeCamp,
          startDate: start,
          endDate: end,
          color: AppColors.cyanAccent,
          altitudeMeters: activeCamp.altitudeMeters,
          estimatedLoadTss: activeCamp.dailyAtlLoad * activeCamp.daysRemaining,
        ),
      );
    }

    // Dedykowane obozy wysokogórskie przed blokami szczytów formy (bez kolizji z wyścigami)
    final bool isClimberOrGc =
        rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureClimber ||
            rider.specialization == RiderSpecialization.puncher;

    if (isClimberOrGc || riderIndex % 3 == 0) {
      final candidateStart1 = DateTime(year, 2, 10 + (riderIndex % 5));
      final candidateEnd1 = candidateStart1.add(const Duration(days: 13));
      if (!_overlapsAny(candidateStart1, candidateEnd1, raceBlocks) &&
          !_overlapsAny(candidateStart1, candidateEnd1, camps)) {
        camps.add(
          GanttTimelineBlock(
            id: 'camp_spring_${rider.id}',
            title: 'Obóz Teide (Wiosna)',
            subtitle: '2150 m n.p.m. • 14 dni bazy tlenowej',
            type: GanttTimelineBlockType.altitudeCamp,
            startDate: candidateStart1,
            endDate: candidateEnd1,
            color: AppColors.accentBlue,
            altitudeMeters: 2150,
            estimatedLoadTss: 1540,
          ),
        );
      }
    }

    if (isClimberOrGc || riderIndex % 2 == 0) {
      final candidateStart2 = DateTime(year, 6, 4 + (riderIndex % 4));
      final candidateEnd2 = candidateStart2.add(const Duration(days: 15));
      if (!_overlapsAny(candidateStart2, candidateEnd2, raceBlocks) &&
          !_overlapsAny(candidateStart2, candidateEnd2, camps)) {
        camps.add(
          GanttTimelineBlock(
            id: 'camp_summer_${rider.id}',
            title: 'Obóz Sierra Nevada',
            subtitle: '2320 m n.p.m. • 16 dni przed Peak 2',
            type: GanttTimelineBlockType.altitudeCamp,
            startDate: candidateStart2,
            endDate: candidateEnd2,
            color: AppColors.cyanAccent,
            altitudeMeters: 2320,
            estimatedLoadTss: 1840,
          ),
        );
      }
    }

    return camps;
  }

  (GanttPeakFormWindow?, GanttPeakFormWindow?) _computePeakWindowsForRider({
    required Rider rider,
    required int riderIndex,
    required List<GanttTimelineBlock> raceBlocks,
  }) {
    final year = widget.save.currentSeasonYear;

    // Peak 1: Wiosna (Klasyki / Giro / Maj)
    DateTime p1Start;
    String p1Label;
    switch (rider.specialization) {
      case RiderSpecialization.classicCobbles:
        p1Start = DateTime(year, 3, 24);
        p1Label = 'Peak 1: Bruki & Monumenty';
        break;
      case RiderSpecialization.pureClimber:
      case RiderSpecialization.gcClimber:
        p1Start = DateTime(year, 5, 5);
        p1Label = 'Peak 1: Wiosenne Góry / Giro';
        break;
      case RiderSpecialization.pureSprinter:
      case RiderSpecialization.versatileSprinter:
        p1Start = DateTime(year, 3, 18);
        p1Label = 'Peak 1: Wiosenne Sprinty';
        break;
      default:
        p1Start = DateTime(year, 4, 1 + (riderIndex % 10));
        p1Label = 'Peak 1: Kampania Wiosenna';
    }

    // Jeśli kolarz ma ważny wyścig w pierwszej połowie roku (sty–maj), kotwiczymy Peak 1 pod ten wyścig
    for (final b in raceBlocks) {
      if (b.startDate.month <= 5 &&
          b.race != null &&
          (b.race!.isGrandTour ||
              b.race!.uciCategory == RaceCategory.monument ||
              b.race!.uciCategory == RaceCategory.worldTourStageRace)) {
        p1Start = _clampToSeason(b.startDate.subtract(const Duration(days: 3)));
        p1Label = 'Peak 1: ${b.title}';
        break;
      }
    }
    final p1End = _clampToSeason(p1Start.add(const Duration(days: 20)));

    // Peak 2: Lato / Jesień (Tour de France / Vuelta / MŚ)
    DateTime p2Start;
    String p2Label;
    if (rider.specialization == RiderSpecialization.gcClimber ||
        rider.specialization == RiderSpecialization.pureClimber) {
      p2Start = DateTime(year, 7, 1);
      p2Label = 'Peak 2: Wielki Tour (Lipiec)';
    } else if (rider.specialization == RiderSpecialization.timeTrialist ||
        rider.specialization == RiderSpecialization.puncher) {
      p2Start = DateTime(year, 8, 22);
      p2Label = 'Peak 2: Vuelta / Mistrzostwa';
    } else {
      p2Start = DateTime(year, 7, 4 + (riderIndex % 8));
      p2Label = 'Peak 2: Letni Szczyt Formy';
    }

    for (final b in raceBlocks.reversed) {
      if (b.startDate.month >= 6 &&
          b.race != null &&
          (b.race!.isGrandTour ||
              b.race!.uciCategory == RaceCategory.monument ||
              b.race!.uciCategory == RaceCategory.worldTourStageRace)) {
        p2Start = _clampToSeason(b.startDate.subtract(const Duration(days: 3)));
        p2Label = 'Peak 2: ${b.title}';
        break;
      }
    }
    final p2End = _clampToSeason(p2Start.add(const Duration(days: 22)));

    return (
      GanttPeakFormWindow(
        peakNumber: 1,
        startDate: p1Start,
        endDate: p1End,
        targetLabel: p1Label,
      ),
      GanttPeakFormWindow(
        peakNumber: 2,
        startDate: p2Start,
        endDate: p2End,
        targetLabel: p2Label,
      ),
    );
  }

  bool _overlapsAny(
    DateTime start,
    DateTime end,
    List<GanttTimelineBlock> blocks,
  ) {
    for (final b in blocks) {
      if (!end.isBefore(b.startDate) && !b.endDate.isBefore(start)) {
        return true;
      }
    }
    return false;
  }

  DateTime _clampToSeason(DateTime dt) {
    if (dt.isBefore(_seasonStart)) return _seasonStart;
    if (dt.isAfter(_seasonEnd)) return _seasonEnd;
    return dt;
  }

  Color _raceCategoryColor(TourRace race) {
    if (race.isGrandTour) return AppColors.goldAccent;
    switch (race.uciCategory) {
      case RaceCategory.grandTour:
        return AppColors.goldAccent;
      case RaceCategory.monument:
        return AppColors.primaryAccent;
      case RaceCategory.worldTourStageRace:
        return AppColors.accentBlue;
      case RaceCategory.worldTourOneDay:
        return AppColors.cyanAccent;
      case RaceCategory.proSeries:
      case RaceCategory.class1:
        return AppColors.statusSuccess;
    }
  }

  List<GanttRiderScheduleRow> _applyFilter(List<GanttRiderScheduleRow> rows) {
    return rows.where((row) {
      switch (_activeFilter) {
        case GanttRosterFilter.all:
          return true;
        case GanttRosterFilter.leaders:
          return row.isFranchiseLeader;
        case GanttRosterFilter.climbers:
          return row.rider.specialization == RiderSpecialization.gcClimber ||
              row.rider.specialization == RiderSpecialization.pureClimber ||
              row.rider.specialization == RiderSpecialization.puncher;
        case GanttRosterFilter.sprinters:
          return row.rider.specialization == RiderSpecialization.pureSprinter ||
              row.rider.specialization == RiderSpecialization.versatileSprinter;
        case GanttRosterFilter.classics:
          return row.rider.specialization ==
                  RiderSpecialization.classicCobbles ||
              row.rider.specialization == RiderSpecialization.timeTrialist;
        case GanttRosterFilter.conflictsOnly:
          return row.hasConflicts;
        case GanttRosterFilter.campsOnly:
          return row.hasCamps;
      }
    }).toList();
  }

  double _dateToX(DateTime date, double timelineWidth) {
    final clamped = _clampToSeason(date);
    final dayOffset = clamped.difference(_seasonStart).inDays;
    return (dayOffset / _totalSeasonDays) * timelineWidth;
  }

  double _spanWidth(DateTime start, DateTime end, double timelineWidth) {
    final clampedStart = _clampToSeason(start);
    final clampedEnd = _clampToSeason(end);
    final days = math.max(1, clampedEnd.difference(clampedStart).inDays + 1);
    return math.max(6.0, (days / _totalSeasonDays) * timelineWidth);
  }

  String _formatShortDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m';
  }

  @override
  Widget build(BuildContext context) {
    final allRows = _buildScheduleRows();
    final filteredRows = _applyFilter(allRows);

    final int totalConflicts =
        allRows.fold<int>(0, (sum, r) => sum + r.overlapConflictCount);
    final int totalCamps =
        allRows.fold<int>(0, (sum, r) => sum + r.campBlocks.length);
    final int totalRiders = allRows.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 640;
        final bool isTablet = width >= 640 && width < 1100;

        final double riderColumnWidth =
            isMobile ? 124.0 : (isTablet ? 176.0 : 220.0);
        final double baseTimelineWidth = isMobile
            ? 880.0
            : math.max(760.0, width - riderColumnWidth - 34.0);
        final double timelineWidth = baseTimelineWidth * _zoomFactor;
        final double ganttViewportHeight = isMobile ? 420.0 : 540.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Nagłówek i statystyki wykresu Gantta
              _buildHeaderBar(
                isMobile: isMobile,
                totalRiders: totalRiders,
                totalCamps: totalCamps,
                totalConflicts: totalConflicts,
              ),
              const SizedBox(height: 12),

              // 2. Filtry kadry, przełączniki warstw i zoom
              _buildControlsRow(
                isMobile: isMobile,
                allRows: allRows,
                totalConflicts: totalConflicts,
                totalCamps: totalCamps,
              ),
              const SizedBox(height: 12),

              // 3. Legenda kolorów i symboli
              _buildLegendBar(isMobile: isMobile),
              const SizedBox(height: 12),

              // 4. Siatka Gantta (Sticky lewa kolumna + synchronizowany nagłówek miesięcy)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Nagłówek miesięcy STY–PAŹ
                    _buildStickyMonthHeader(
                      riderColumnWidth: riderColumnWidth,
                      timelineWidth: timelineWidth,
                      isMobile: isMobile,
                    ),
                    const Divider(height: 1, color: AppColors.cardBorder),

                    // Wiersze wszystkich kolarzy (zsynchronizowane poziomo jednym ScrollControllerem)
                    if (filteredRows.isEmpty)
                      _buildEmptyFilterState()
                    else
                      _buildSynchronizedGanttBody(
                        filteredRows: filteredRows,
                        riderColumnWidth: riderColumnWidth,
                        timelineWidth: timelineWidth,
                        ganttViewportHeight: ganttViewportHeight,
                        isMobile: isMobile,
                      ),
                  ],
                ),
              ),

              // 5. Pasek inspekcji wybranego/najechanego elementu
              if (_inspectedBlock != null || _inspectedRow != null) ...[
                const SizedBox(height: 12),
                _buildInspectionFooter(isMobile: isMobile),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar({
    required bool isMobile,
    required int totalRiders,
    required int totalCamps,
    required int totalConflicts,
  }) {
    final titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.4),
            ),
          ),
          child: const Icon(
            Icons.view_timeline_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Planer Obciążeń Sezonu (Gantt)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Styczeń – Październik • $totalRiders kolarzy • Peak 1 & Peak 2 • Obozy wysokościowe',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final badges = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatPill(
          icon: Icons.groups_rounded,
          label: '$totalRiders Kolarzy',
          color: AppColors.accentBlue,
        ),
        _StatPill(
          icon: Icons.terrain_rounded,
          label: '$totalCamps Obozów',
          color: AppColors.cyanAccent,
        ),
        _StatPill(
          icon: totalConflicts == 0
              ? Icons.verified_rounded
              : Icons.warning_amber_rounded,
          label: totalConflicts == 0
              ? '0 Kolizji'
              : '$totalConflicts Kolizji',
          color: totalConflicts == 0
              ? AppColors.statusSuccess
              : AppColors.crimsonAlert,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          badges,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        badges,
      ],
    );
  }

  Widget _buildControlsRow({
    required bool isMobile,
    required List<GanttRiderScheduleRow> allRows,
    required int totalConflicts,
    required int totalCamps,
  }) {
    final filterChips = <({GanttRosterFilter filter, String label})>[
      (filter: GanttRosterFilter.all, label: 'Wszyscy (${allRows.length})'),
      (filter: GanttRosterFilter.leaders, label: 'Liderzy'),
      (filter: GanttRosterFilter.climbers, label: 'Górale'),
      (filter: GanttRosterFilter.sprinters, label: 'Sprinterzy'),
      (filter: GanttRosterFilter.classics, label: 'Klasykowcy / TT'),
      (filter: GanttRosterFilter.campsOnly, label: 'Obozy ($totalCamps)'),
      (
        filter: GanttRosterFilter.conflictsOnly,
        label: 'Kolizje ($totalConflicts)',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: filterChips.map((chip) {
            final selected = _activeFilter == chip.filter;
            final disabled = chip.filter == GanttRosterFilter.conflictsOnly &&
                totalConflicts == 0;
            return _InteractiveChipButton(
              label: chip.label,
              isSelected: selected,
              isDisabled: disabled,
              accentColor: chip.filter == GanttRosterFilter.conflictsOnly
                  ? AppColors.crimsonAlert
                  : AppColors.goldAccent,
              onTap: disabled
                  ? null
                  : () {
                      setState(() {
                        _activeFilter = chip.filter;
                      });
                    },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _InteractiveChipButton(
              label: 'Wyścigi',
              icon: Icons.emoji_events_outlined,
              isSelected: _showRaces,
              accentColor: AppColors.accentBlue,
              onTap: () => setState(() => _showRaces = !_showRaces),
            ),
            _InteractiveChipButton(
              label: 'Obozy Wysokogórskie',
              icon: Icons.terrain_rounded,
              isSelected: _showCamps,
              accentColor: AppColors.cyanAccent,
              onTap: () => setState(() => _showCamps = !_showCamps),
            ),
            _InteractiveChipButton(
              label: 'Peak 1 & 2',
              icon: Icons.trending_up_rounded,
              isSelected: _showPeaks,
              accentColor: AppColors.goldAccent,
              onTap: () => setState(() => _showPeaks = !_showPeaks),
            ),
            _InteractiveChipButton(
              label: 'Obciążenie',
              icon: Icons.speed_rounded,
              isSelected: _showLoadBars,
              accentColor: AppColors.statusSuccess,
              onTap: () => setState(() => _showLoadBars = !_showLoadBars),
            ),
            const SizedBox(width: 6),
            _ZoomSegmentedControl(
              zoomFactor: _zoomFactor,
              onChanged: (z) => setState(() => _zoomFactor = z),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendBar({required bool isMobile}) {
    final items = [
      (color: AppColors.goldAccent, label: 'Grand Tour'),
      (color: AppColors.primaryAccent, label: 'Monument'),
      (color: AppColors.accentBlue, label: 'WT Etapowy'),
      (color: AppColors.cyanAccent, label: 'Obóz Wysokogórski'),
      (color: AppColors.statusSuccess, label: 'Peak 1 / Peak 2'),
      (color: AppColors.crimsonAlert, label: 'Kolizja dat'),
    ];

    return Wrap(
      spacing: isMobile ? 10 : 16,
      runSpacing: 6,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildStickyMonthHeader({
    required double riderColumnWidth,
    required double timelineWidth,
    required bool isMobile,
  }) {
    final currentDate = _clampToSeason(widget.save.currentDate);
    final todayX = _dateToX(currentDate, timelineWidth);

    return Container(
      height: 38,
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          Container(
            width: riderColumnWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              isMobile ? 'KOLARZ / DNI' : 'KOLARZ • OBCIĄŻENIE',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalHeaderController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: timelineWidth,
                height: 38,
                child: Stack(
                  children: [
                    Row(
                      children: List.generate(10, (monthIdx) {
                        final monthNum = monthIdx + 1;
                        final mStart = DateTime(
                            widget.save.currentSeasonYear, monthNum, 1);
                        final nextStart = DateTime(
                            widget.save.currentSeasonYear, monthNum + 1, 1);
                        final daysInMonth =
                            nextStart.difference(mStart).inDays;
                        final monthWidth =
                            (daysInMonth / _totalSeasonDays) * timelineWidth;
                        final isCurrentMonth =
                            widget.save.currentDate.month == monthNum;

                        return Container(
                          width: monthWidth,
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: AppColors.cardBorder,
                                width: 1,
                              ),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _zoomFactor >= 1.4 && !isMobile
                                ? _monthFullLabels[monthIdx]
                                : _monthShortLabels[monthIdx],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: isCurrentMonth
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isCurrentMonth
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ),
                    Positioned(
                      left: todayX.clamp(0.0, timelineWidth - 2),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({double rowHeight, double racesTrackHeight}) _computeRowLayout(
    GanttRiderScheduleRow row,
  ) {
    const double laneHeight = 20.0;
    const double laneSpacing = 3.0;
    final int visibleLanes = _showRaces ? row.maxLaneCount : 1;
    final double racesTrackHeight =
        visibleLanes * laneHeight + (visibleLanes - 1) * laneSpacing;
    final double campTrackHeight = _showCamps && row.hasCamps ? 18.0 : 0.0;
    final double peakHeaderHeight = _showPeaks ? 14.0 : 0.0;
    final double rowHeight = math.max(
      58.0,
      peakHeaderHeight +
          racesTrackHeight +
          (campTrackHeight > 0 ? campTrackHeight + 4 : 0) +
          16.0,
    );
    return (rowHeight: rowHeight, racesTrackHeight: racesTrackHeight);
  }

  Widget _buildSynchronizedGanttBody({
    required List<GanttRiderScheduleRow> filteredRows,
    required double riderColumnWidth,
    required double timelineWidth,
    required double ganttViewportHeight,
    required bool isMobile,
  }) {
    final layouts = [
      for (final row in filteredRows) _computeRowLayout(row),
    ];

    return SizedBox(
      height: ganttViewportHeight,
      child: Scrollbar(
        controller: _verticalListController,
        thumbVisibility: !isMobile,
        child: SingleChildScrollView(
          controller: _verticalListController,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lewa przypięta kolumna wszystkich kolarzy
              SizedBox(
                width: riderColumnWidth,
                child: Column(
                  children: List.generate(filteredRows.length, (index) {
                    final row = filteredRows[index];
                    final layout = layouts[index];
                    return Column(
                      children: [
                        _buildLeftRiderCell(
                          row: row,
                          index: index,
                          riderColumnWidth: riderColumnWidth,
                          rowHeight: layout.rowHeight,
                          isMobile: isMobile,
                        ),
                        if (index < filteredRows.length - 1)
                          const Divider(height: 1, color: AppColors.cardBorder),
                      ],
                    );
                  }),
                ),
              ),

              // Prawa wspólna pozioma oś czasu STY–PAŹ (jeden ScrollController)
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalBodyController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: timelineWidth,
                    child: Column(
                      children: List.generate(filteredRows.length, (index) {
                        final row = filteredRows[index];
                        final layout = layouts[index];
                        return Column(
                          children: [
                            _buildRightTimelineRow(
                              row: row,
                              index: index,
                              timelineWidth: timelineWidth,
                              rowHeight: layout.rowHeight,
                              racesTrackHeight: layout.racesTrackHeight,
                            ),
                            if (index < filteredRows.length - 1)
                              const Divider(
                                height: 1,
                                color: AppColors.cardBorder,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _rowBackgroundColor(
    GanttRiderScheduleRow row,
    int index,
  ) {
    final bool isRowHovered = _hoveredRiderId == row.rider.id;
    final bool isRowSelected = _selectedRiderId == row.rider.id;
    if (isRowSelected) {
      return AppColors.primaryAccent.withValues(alpha: 0.14);
    }
    if (isRowHovered) {
      return AppColors.surfaceLight.withValues(alpha: 0.55);
    }
    return index.isEven
        ? AppColors.background
        : AppColors.surface.withValues(alpha: 0.45);
  }

  Widget _buildLeftRiderCell({
    required GanttRiderScheduleRow row,
    required int index,
    required double riderColumnWidth,
    required double rowHeight,
    required bool isMobile,
  }) {
    final Color loadColor = row.plannedRaceDays > 65
        ? AppColors.crimsonAlert
        : (row.plannedRaceDays > 48
            ? AppColors.amberWarning
            : AppColors.statusSuccess);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRiderId = row.rider.id),
      onExit: (_) {
        if (_hoveredRiderId == row.rider.id) {
          setState(() => _hoveredRiderId = null);
        }
      },
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRiderId = row.rider.id;
            _inspectedRow = row;
            _inspectedBlock = null;
          });
          widget.onRiderTap?.call(row.rider);
        },
        hoverColor: AppColors.surfaceLight.withValues(alpha: 0.4),
        focusColor: AppColors.goldAccent.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: riderColumnWidth,
          height: rowHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _rowBackgroundColor(row, index),
            border: const Border(
              right: BorderSide(color: AppColors.cardBorder, width: 1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (row.isFranchiseLeader)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      isMobile
                          ? row.rider.lastName
                          : '${row.rider.firstName[0]}. ${row.rider.lastName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (row.hasConflicts)
                    const Tooltip(
                      message: 'Wykryto nakładanie wyścigów',
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: AppColors.crimsonAlert,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  if (!isMobile) ...[
                    Expanded(
                      child: Text(
                        row.rider.specialization.displayName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${row.plannedRaceDays}/$_maxSeasonRaceDays d',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: loadColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              if (_showLoadBars) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: row.seasonLoadRatio.clamp(0.0, 1.0),
                    minHeight: 3.5,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(loadColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightTimelineRow({
    required GanttRiderScheduleRow row,
    required int index,
    required double timelineWidth,
    required double rowHeight,
    required double racesTrackHeight,
  }) {
    const double laneHeight = 20.0;
    const double laneSpacing = 3.0;
    final currentDate = _clampToSeason(widget.save.currentDate);
    final todayX = _dateToX(currentDate, timelineWidth);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRiderId = row.rider.id),
      onExit: (_) {
        if (_hoveredRiderId == row.rider.id) {
          setState(() => _hoveredRiderId = null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: timelineWidth,
        height: rowHeight,
        color: _rowBackgroundColor(row, index),
        child: Stack(
          children: [
            // Linie siatki miesięcy
            ...List.generate(10, (monthIdx) {
              final monthStart = DateTime(
                widget.save.currentSeasonYear,
                monthIdx + 1,
                1,
              );
              final x = _dateToX(monthStart, timelineWidth);
              return Positioned(
                left: x,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: AppColors.cardBorder.withValues(alpha: 0.45),
                ),
              );
            }),

            // Pasma Peak 1 i Peak 2 w tle
            if (_showPeaks) ...[
              if (row.peak1 != null)
                _buildPeakBand(
                  peak: row.peak1!,
                  timelineWidth: timelineWidth,
                  rowHeight: rowHeight,
                ),
              if (row.peak2 != null)
                _buildPeakBand(
                  peak: row.peak2!,
                  timelineWidth: timelineWidth,
                  rowHeight: rowHeight,
                ),
            ],

            // Paski wyścigów (rozłożone na bezkolizyjnych pod-torach)
            if (_showRaces)
              ...row.raceBlocks.map((block) {
                final double x = _dateToX(block.startDate, timelineWidth);
                final double w = _spanWidth(
                  block.startDate,
                  block.endDate,
                  timelineWidth,
                );
                final double top = (_showPeaks ? 16.0 : 6.0) +
                    block.laneIndex * (laneHeight + laneSpacing);

                return Positioned(
                  left: x,
                  top: top,
                  width: w,
                  height: laneHeight,
                  child: _GanttBarWidget(
                    block: block,
                    isHovered: _hoveredBlockId == block.id,
                    isSelected: _selectedBlockId == block.id,
                    onHoverChanged: (hovering) {
                      setState(() {
                        _hoveredBlockId = hovering ? block.id : null;
                        if (hovering) {
                          _inspectedBlock = block;
                          _inspectedRow = row;
                        }
                      });
                    },
                    onTap: () {
                      setState(() {
                        _selectedBlockId = block.id;
                        _selectedRiderId = row.rider.id;
                        _inspectedBlock = block;
                        _inspectedRow = row;
                      });
                      if (block.race != null) {
                        widget.onRaceTap?.call(block.race!);
                      }
                    },
                  ),
                );
              }),

            // Paski obozów wysokogórskich
            if (_showCamps)
              ...row.campBlocks.map((camp) {
                final double x = _dateToX(camp.startDate, timelineWidth);
                final double w = _spanWidth(
                  camp.startDate,
                  camp.endDate,
                  timelineWidth,
                );
                final double top =
                    (_showPeaks ? 16.0 : 6.0) + racesTrackHeight + 4.0;

                return Positioned(
                  left: x,
                  top: top,
                  width: w,
                  height: 16.0,
                  child: _GanttBarWidget(
                    block: camp,
                    isHovered: _hoveredBlockId == camp.id,
                    isSelected: _selectedBlockId == camp.id,
                    onHoverChanged: (hovering) {
                      setState(() {
                        _hoveredBlockId = hovering ? camp.id : null;
                        if (hovering) {
                          _inspectedBlock = camp;
                          _inspectedRow = row;
                        }
                      });
                    },
                    onTap: () {
                      setState(() {
                        _selectedBlockId = camp.id;
                        _selectedRiderId = row.rider.id;
                        _inspectedBlock = camp;
                        _inspectedRow = row;
                      });
                    },
                  ),
                );
              }),

            // Pionowa linia bieżącego dnia sezonu
            Positioned(
              left: todayX.clamp(0.0, timelineWidth - 1.5),
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 1.5,
                  color: AppColors.goldAccent.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakBand({
    required GanttPeakFormWindow peak,
    required double timelineWidth,
    required double rowHeight,
  }) {
    final double x = _dateToX(peak.startDate, timelineWidth);
    final double w = _spanWidth(peak.startDate, peak.endDate, timelineWidth);
    final Color peakColor = peak.peakNumber == 1
        ? AppColors.statusSuccess
        : AppColors.goldAccent;

    return Positioned(
      left: x,
      top: 2,
      width: w,
      height: rowHeight - 4,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: peakColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: peakColor.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(
            'P${peak.peakNumber}',
            style: TextStyle(
              fontFamily: 'Inter',
              color: peakColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.clip,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              size: 32,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            const Text(
              'Brak kolarzy spełniających wybrane kryteria filtra.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() => _activeFilter = GanttRosterFilter.all);
              },
              child: const Text(
                'Pokaż wszystkich kolarzy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionFooter({required bool isMobile}) {
    final row = _inspectedRow;
    final block = _inspectedBlock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: block?.hasOverlapConflict == true
              ? AppColors.crimsonAlert.withValues(alpha: 0.65)
              : AppColors.cardBorder,
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (row != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.directions_bike_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  '${row.rider.fullName} (${row.plannedRaceDays}/$_maxSeasonRaceDays dni)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          if (block != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: block.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${block.title} • ${block.subtitle}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (block.hasOverlapConflict) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'KOLIZJA TERMINÓW',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.crimsonAlert,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            )
          else if (row != null) ...[
            if (row.peak1 != null)
              Text(
                '${row.peak1!.targetLabel} (${_formatShortDate(row.peak1!.startDate)}–${_formatShortDate(row.peak1!.endDate)})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.statusSuccess,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (row.peak2 != null)
              Text(
                '${row.peak2!.targetLabel} (${_formatShortDate(row.peak2!.startDate)}–${_formatShortDate(row.peak2!.endDate)})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
          if (!isMobile &&
              block?.race != null &&
              widget.onRaceTap != null)
            TextButton.icon(
              onPressed: () => widget.onRaceTap?.call(block!.race!),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Przejdź do wyścigu'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

class _GanttBarWidget extends StatefulWidget {
  final GanttTimelineBlock block;
  final bool isHovered;
  final bool isSelected;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;

  const _GanttBarWidget({
    required this.block,
    required this.isHovered,
    required this.isSelected,
    required this.onHoverChanged,
    required this.onTap,
  });

  @override
  State<_GanttBarWidget> createState() => _GanttBarWidgetState();
}

class _GanttBarWidgetState extends State<_GanttBarWidget> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool isCamp =
        widget.block.type == GanttTimelineBlockType.altitudeCamp;
    final bool highlighted = widget.isHovered || widget.isSelected || _focused;
    final Color borderColor = widget.block.hasOverlapConflict
        ? AppColors.crimsonAlert
        : (highlighted
            ? AppColors.textPrimary
            : widget.block.color.withValues(alpha: 0.85));

    return Tooltip(
      message: '${widget.block.title}\n${widget.block.subtitle}',
      child: FocusableActionDetector(
        onShowFocusHighlight: (f) => setState(() => _focused = f),
        onShowHoverHighlight: widget.onHoverChanged,
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: widget.block.color.withValues(
                alpha: highlighted ? 0.92 : (isCamp ? 0.30 : 0.72),
              ),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: borderColor,
                width: highlighted || widget.block.hasOverlapConflict ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                if (isCamp)
                  const Padding(
                    padding: EdgeInsets.only(right: 3),
                    child: Icon(
                      Icons.terrain_rounded,
                      size: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.block.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isCamp || highlighted
                          ? AppColors.textPrimary
                          : AppColors.background,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback? onTap;

  const _InteractiveChipButton({
    required this.label,
    this.icon,
    required this.isSelected,
    this.isDisabled = false,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled && widget.onTap != null;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : (widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.2)
            : (_hovered
                ? AppColors.surfaceLight
                : AppColors.background));

    final Color borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.4)
        : (widget.isSelected || _focused
            ? widget.accentColor
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    final Color fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (widget.isSelected ? widget.accentColor : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 13, color: fgColor),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: fgColor,
                  fontSize: 11.5,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomSegmentedControl extends StatelessWidget {
  final double zoomFactor;
  final ValueChanged<double> onChanged;

  const _ZoomSegmentedControl({
    required this.zoomFactor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [(1.0, '1x'), (1.4, '1.4x'), (1.9, '1.9x')];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final selected = (zoomFactor - opt.$1).abs() < 0.05;
          return InkWell(
            onTap: () => onChanged(opt.$1),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.goldAccent.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
