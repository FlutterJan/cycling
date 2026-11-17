import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../engine/simulation/multi_race_parallel_day_simulator.dart';

/// Kategoria roweru w bazie sprzętowej zespołu na dwa równoległe fronty.
enum SplitSquadBikeCategory {
  aero,
  climbing,
  allRounder,
  cobble,
  timeTrial;

  String toJson() => name;

  String get labelPl {
    switch (this) {
      case SplitSquadBikeCategory.aero:
        return 'Aero';
      case SplitSquadBikeCategory.climbing:
        return 'Górski';
      case SplitSquadBikeCategory.allRounder:
        return 'All-Round';
      case SplitSquadBikeCategory.cobble:
        return 'Bruk / Endurance';
      case SplitSquadBikeCategory.timeTrial:
        return 'Czasówka (TT)';
    }
  }

  IconData get icon {
    switch (this) {
      case SplitSquadBikeCategory.aero:
        return Icons.air_rounded;
      case SplitSquadBikeCategory.climbing:
        return Icons.terrain_rounded;
      case SplitSquadBikeCategory.allRounder:
        return Icons.pedal_bike_rounded;
      case SplitSquadBikeCategory.cobble:
        return Icons.grid_on_rounded;
      case SplitSquadBikeCategory.timeTrial:
        return Icons.timer_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case SplitSquadBikeCategory.aero:
        return AppColors.accentBlue;
      case SplitSquadBikeCategory.climbing:
        return AppColors.goldAccent;
      case SplitSquadBikeCategory.allRounder:
        return AppColors.statusSuccess;
      case SplitSquadBikeCategory.cobble:
        return AppColors.amberWarning;
      case SplitSquadBikeCategory.timeTrial:
        return AppColors.cyanAccent;
    }
  }

  bool isOptimalFor(ParallelRaceTerrain terrain) {
    switch (terrain) {
      case ParallelRaceTerrain.flat:
        return this == SplitSquadBikeCategory.aero ||
            this == SplitSquadBikeCategory.allRounder;
      case ParallelRaceTerrain.hilly:
        return this == SplitSquadBikeCategory.allRounder ||
            this == SplitSquadBikeCategory.climbing ||
            this == SplitSquadBikeCategory.aero;
      case ParallelRaceTerrain.highMountain:
        return this == SplitSquadBikeCategory.climbing ||
            this == SplitSquadBikeCategory.allRounder;
      case ParallelRaceTerrain.cobbleClassic:
        return this == SplitSquadBikeCategory.cobble ||
            this == SplitSquadBikeCategory.allRounder;
      case ParallelRaceTerrain.timeTrial:
        return this == SplitSquadBikeCategory.timeTrial;
    }
  }

  static SplitSquadBikeCategory fromJson(String value) {
    return SplitSquadBikeCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SplitSquadBikeCategory.allRounder,
    );
  }
}

/// Fizyczny egzemplarz roweru w garażu Service Course dostępny do przydziału na wyścig.
class SplitSquadBikeAsset {
  final String bikeId;
  final String modelName;
  final String frameBrand;
  final String wheelsetLabel;
  final SplitSquadBikeCategory category;
  final double weightKg;
  final double cdaModifier;
  final int conditionPercent;
  final bool isSpareRoofBike;

  const SplitSquadBikeAsset({
    required this.bikeId,
    required this.modelName,
    required this.frameBrand,
    required this.wheelsetLabel,
    required this.category,
    required this.weightKg,
    required this.cdaModifier,
    this.conditionPercent = 100,
    this.isSpareRoofBike = false,
  });

  bool get isUciCompliant => weightKg >= 6.80;

  bool get needsMaintenanceWarning => conditionPercent < 70;

  SplitSquadBikeAsset copyWith({
    String? bikeId,
    String? modelName,
    String? frameBrand,
    String? wheelsetLabel,
    SplitSquadBikeCategory? category,
    double? weightKg,
    double? cdaModifier,
    int? conditionPercent,
    bool? isSpareRoofBike,
  }) {
    return SplitSquadBikeAsset(
      bikeId: bikeId ?? this.bikeId,
      modelName: modelName ?? this.modelName,
      frameBrand: frameBrand ?? this.frameBrand,
      wheelsetLabel: wheelsetLabel ?? this.wheelsetLabel,
      category: category ?? this.category,
      weightKg: weightKg ?? this.weightKg,
      cdaModifier: cdaModifier ?? this.cdaModifier,
      conditionPercent: conditionPercent ?? this.conditionPercent,
      isSpareRoofBike: isSpareRoofBike ?? this.isSpareRoofBike,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bikeId': bikeId,
      'modelName': modelName,
      'frameBrand': frameBrand,
      'wheelsetLabel': wheelsetLabel,
      'category': category.toJson(),
      'weightKg': weightKg,
      'cdaModifier': cdaModifier,
      'conditionPercent': conditionPercent,
      'isSpareRoofBike': isSpareRoofBike,
    };
  }

  factory SplitSquadBikeAsset.fromJson(Map<String, dynamic> json) {
    return SplitSquadBikeAsset(
      bikeId: json['bikeId'] as String,
      modelName: json['modelName'] as String,
      frameBrand: json['frameBrand'] as String,
      wheelsetLabel: json['wheelsetLabel'] as String,
      category: SplitSquadBikeCategory.fromJson(json['category'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      cdaModifier: (json['cdaModifier'] as num).toDouble(),
      conditionPercent: (json['conditionPercent'] as num?)?.toInt() ?? 100,
      isSpareRoofBike: json['isSpareRoofBike'] as bool? ?? false,
    );
  }
}

/// Katalog i kalkulator przydziału floty rowerów na dwa równoległe fronty wyścigowe.
class SplitSquadBikeCatalog {
  SplitSquadBikeCatalog._();

  /// Generuje realistyczną 30-rowerową flotę zespołu WorldTour (szosa, góry, bruk, TT + zapasy).
  static List<SplitSquadBikeAsset> generateTeamFleet() {
    final List<SplitSquadBikeAsset> fleet = [];
    for (int i = 1; i <= 8; i++) {
      fleet.add(
        SplitSquadBikeAsset(
          bikeId: 'bike_climb_$i',
          modelName: 'Veloce SL-R #$i',
          frameBrand: 'Pinarello / Lab',
          wheelsetLabel: '35mm Carbon Light',
          category: SplitSquadBikeCategory.climbing,
          weightKg: 6.80 + (i % 3) * 0.04,
          cdaModifier: -0.004,
          conditionPercent: 98 - (i % 4) * 3,
        ),
      );
    }
    for (int i = 1; i <= 8; i++) {
      fleet.add(
        SplitSquadBikeAsset(
          bikeId: 'bike_aero_$i',
          modelName: 'Blade Aero RS #$i',
          frameBrand: 'Cervelo / Lab',
          wheelsetLabel: '62mm Deep Aero',
          category: SplitSquadBikeCategory.aero,
          weightKg: 7.12 + (i % 3) * 0.05,
          cdaModifier: -0.016,
          conditionPercent: 96 - (i % 5) * 4,
        ),
      );
    }
    for (int i = 1; i <= 6; i++) {
      fleet.add(
        SplitSquadBikeAsset(
          bikeId: 'bike_all_$i',
          modelName: 'Tarmac Pro Team #$i',
          frameBrand: 'Specialized / Lab',
          wheelsetLabel: '45mm All-Round',
          category: SplitSquadBikeCategory.allRounder,
          weightKg: 6.92 + (i % 2) * 0.05,
          cdaModifier: -0.010,
          conditionPercent: 95 - (i % 3) * 5,
        ),
      );
    }
    for (int i = 1; i <= 4; i++) {
      fleet.add(
        SplitSquadBikeAsset(
          bikeId: 'bike_cobble_$i',
          modelName: 'Roubaix Pavé 32c #$i',
          frameBrand: 'Trek / Lab',
          wheelsetLabel: '32mm Wide Tubeless',
          category: SplitSquadBikeCategory.cobble,
          weightKg: 7.38 + (i % 2) * 0.06,
          cdaModifier: -0.002,
          conditionPercent: 92 - (i % 3) * 6,
        ),
      );
    }
    for (int i = 1; i <= 4; i++) {
      fleet.add(
        SplitSquadBikeAsset(
          bikeId: 'bike_tt_$i',
          modelName: 'Chrono Disc TT #$i',
          frameBrand: 'BMC / Lab',
          wheelsetLabel: 'Full Disc + Tri-Spoke',
          category: SplitSquadBikeCategory.timeTrial,
          weightKg: 7.85 + (i % 2) * 0.08,
          cdaModifier: -0.032,
          conditionPercent: 99 - (i % 2) * 2,
        ),
      );
    }
    return fleet;
  }

  /// Automatycznie dobiera optymalne, unikalne rowery dla wszystkich kolarzy na Froncie A i Froncie B.
  static Map<String, String> autoAssignBikes({
    required List<ParallelRosterRiderSnapshot> squad,
    required Map<String, ParallelFrontSlot> riderAssignments,
    required List<SplitSquadBikeAsset> fleet,
    required ParallelRaceEventSpec frontA,
    required ParallelRaceEventSpec frontB,
  }) {
    final Map<String, String> result = {};
    final Set<String> usedBikeIds = {};

    int scoreBike(SplitSquadBikeAsset bike, ParallelRaceTerrain terrain) {
      int score = bike.conditionPercent;
      if (bike.category.isOptimalFor(terrain)) {
        score += 120;
      }
      if (terrain == ParallelRaceTerrain.highMountain &&
          bike.category == SplitSquadBikeCategory.climbing) {
        score += 45;
      } else if (terrain == ParallelRaceTerrain.flat &&
          bike.category == SplitSquadBikeCategory.aero) {
        score += 45;
      } else if (terrain == ParallelRaceTerrain.cobbleClassic &&
          bike.category == SplitSquadBikeCategory.cobble) {
        score += 55;
      } else if (terrain == ParallelRaceTerrain.timeTrial &&
          bike.category == SplitSquadBikeCategory.timeTrial) {
        score += 80;
      }
      if (!bike.isUciCompliant) score -= 200;
      return score;
    }

    // Najpierw Front A (zwykle priorytetowy), potem Front B.
    for (final targetSlot in [
      ParallelFrontSlot.frontA,
      ParallelFrontSlot.frontB,
    ]) {
      final terrain = targetSlot == ParallelFrontSlot.frontA
          ? frontA.terrain
          : frontB.terrain;

      final ridersInSlot = squad
          .where((r) => riderAssignments[r.riderId] == targetSlot)
          .toList()
        ..sort((a, b) => b.overallRating.compareTo(a.overallRating));

      for (final rider in ridersInSlot) {
        final candidates = fleet
            .where((b) => !usedBikeIds.contains(b.bikeId))
            .toList()
          ..sort(
            (a, b) => scoreBike(b, terrain).compareTo(scoreBike(a, terrain)),
          );
        if (candidates.isNotEmpty) {
          final chosen = candidates.first;
          result[rider.riderId] = chosen.bikeId;
          usedBikeIds.add(chosen.bikeId);
        }
      }
    }

    return result;
  }

  /// Waliduje przydział rowerów (brak podwójnego użycia tego samego roweru na 2 frontach, brak roweru, stan techniczny).
  static SplitSquadBikeValidationResult validateBikeAssignments({
    required List<ParallelRosterRiderSnapshot> squad,
    required Map<String, ParallelFrontSlot> riderAssignments,
    required Map<String, String> bikeAssignments,
    required List<SplitSquadBikeAsset> fleet,
    required ParallelRaceEventSpec frontA,
    required ParallelRaceEventSpec frontB,
  }) {
    final Map<String, SplitSquadBikeAsset> bikeById = {
      for (final b in fleet) b.bikeId: b,
    };
    final Map<String, List<String>> bikeUsage = {};
    final List<String> missingRiderIds = [];
    final List<String> nonCompliantBikeIds = [];
    final List<String> lowConditionBikeIds = [];
    final List<String> terrainMismatchRiderIds = [];

    for (final rider in squad) {
      final slot = riderAssignments[rider.riderId] ?? ParallelFrontSlot.reserve;
      if (slot == ParallelFrontSlot.reserve) continue;

      final bikeId = bikeAssignments[rider.riderId];
      if (bikeId == null || !bikeById.containsKey(bikeId)) {
        missingRiderIds.add(rider.riderId);
        continue;
      }

      bikeUsage.putIfAbsent(bikeId, () => []).add(rider.riderId);
      final bike = bikeById[bikeId]!;
      if (!bike.isUciCompliant) {
        nonCompliantBikeIds.add(bikeId);
      }
      if (bike.needsMaintenanceWarning) {
        lowConditionBikeIds.add(bikeId);
      }
      final terrain =
          slot == ParallelFrontSlot.frontA ? frontA.terrain : frontB.terrain;
      if (!bike.category.isOptimalFor(terrain)) {
        terrainMismatchRiderIds.add(rider.riderId);
      }
    }

    final List<String> duplicateBikeIds = bikeUsage.entries
        .where((e) => e.value.length > 1)
        .map((e) => e.key)
        .toList();

    return SplitSquadBikeValidationResult(
      isValid: missingRiderIds.isEmpty &&
          duplicateBikeIds.isEmpty &&
          nonCompliantBikeIds.isEmpty,
      missingRiderIds: missingRiderIds,
      duplicateBikeIds: duplicateBikeIds,
      nonCompliantBikeIds: nonCompliantBikeIds,
      lowConditionBikeIds: lowConditionBikeIds,
      terrainMismatchRiderIds: terrainMismatchRiderIds,
    );
  }
}

/// Wynik walidacji przydziału rowerów na dwa równoległe wyścigi.
class SplitSquadBikeValidationResult {
  final bool isValid;
  final List<String> missingRiderIds;
  final List<String> duplicateBikeIds;
  final List<String> nonCompliantBikeIds;
  final List<String> lowConditionBikeIds;
  final List<String> terrainMismatchRiderIds;

  const SplitSquadBikeValidationResult({
    required this.isValid,
    this.missingRiderIds = const [],
    this.duplicateBikeIds = const [],
    this.nonCompliantBikeIds = const [],
    this.lowConditionBikeIds = const [],
    this.terrainMismatchRiderIds = const [],
  });

  bool get hasWarnings =>
      lowConditionBikeIds.isNotEmpty || terrainMismatchRiderIds.isNotEmpty;
}

/// Zakładki okna przydziału kolarzy i rowerów na dwa równoległe wyścigi.
enum SplitSquadAssignmentTab {
  ridersAndBikes,
  bikeFleet,
  staffAndValidation;

  String get labelPl {
    switch (this) {
      case SplitSquadAssignmentTab.ridersAndBikes:
        return 'Kadra i Rowery';
      case SplitSquadAssignmentTab.bikeFleet:
        return 'Flota Rowerów';
      case SplitSquadAssignmentTab.staffAndValidation:
        return 'Sztab i Autobus';
    }
  }

  IconData get icon {
    switch (this) {
      case SplitSquadAssignmentTab.ridersAndBikes:
        return Icons.groups_rounded;
      case SplitSquadAssignmentTab.bikeFleet:
        return Icons.pedal_bike_rounded;
      case SplitSquadAssignmentTab.staffAndValidation:
        return Icons.directions_bus_rounded;
    }
  }
}

/// Filtr widoku listy kolarzy w oknie przydziału.
enum SplitSquadRiderFilter {
  all,
  frontA,
  frontB,
  reserve,
  injured;

  String get labelPl {
    switch (this) {
      case SplitSquadRiderFilter.all:
        return 'Wszyscy';
      case SplitSquadRiderFilter.frontA:
        return 'Front A';
      case SplitSquadRiderFilter.frontB:
        return 'Front B';
      case SplitSquadRiderFilter.reserve:
        return 'Rezerwa';
      case SplitSquadRiderFilter.injured:
        return 'Niedysponowani';
    }
  }
}

/// Wynik zwracany po zatwierdzeniu przydziału kolarzy i rowerów na dwa równoległe wyścigi.
class SplitSquadCalendarAssignmentResult {
  final DateTime calendarDate;
  final Map<String, ParallelFrontSlot> riderAssignments;
  final Map<String, String> bikeAssignments;
  final ParallelStaffSplitConfig staffSplit;
  final ParallelSplitStrategy strategy;
  final ParallelDayRosterValidation rosterValidation;
  final SplitSquadBikeValidationResult bikeValidation;
  final DateTime confirmedAt;

  const SplitSquadCalendarAssignmentResult({
    required this.calendarDate,
    required this.riderAssignments,
    required this.bikeAssignments,
    required this.staffSplit,
    required this.strategy,
    required this.rosterValidation,
    required this.bikeValidation,
    required this.confirmedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'calendarDate': calendarDate.toIso8601String(),
      'riderAssignments': riderAssignments.map((k, v) => MapEntry(k, v.toJson())),
      'bikeAssignments': bikeAssignments,
      'staffSplit': staffSplit.toJson(),
      'strategy': strategy.toJson(),
      'rosterValidation': rosterValidation.toJson(),
      'confirmedAt': confirmedAt.toIso8601String(),
    };
  }
}

/// Otwiera okno modalne przydziału kolarzy i rowerów na dwa równoległe wyścigi.
Future<SplitSquadCalendarAssignmentResult?>
    showSplitSquadCalendarAssignmentModal(
  BuildContext context, {
  DateTime? calendarDate,
  List<ParallelRosterRiderSnapshot>? squad,
  ParallelRaceEventSpec? frontAEvent,
  ParallelRaceEventSpec? frontBEvent,
  Map<String, ParallelFrontSlot>? initialRiderAssignments,
  Map<String, String>? initialBikeAssignments,
  List<SplitSquadBikeAsset>? bikeFleet,
  ParallelStaffSplitConfig? initialStaffSplit,
  ParallelSplitStrategy initialStrategy = ParallelSplitStrategy.prioritizeFrontA,
  bool isReadOnly = false,
}) {
  return showDialog<SplitSquadCalendarAssignmentResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: SplitSquadCalendarAssignmentModal(
          calendarDate: calendarDate,
          squad: squad,
          frontAEvent: frontAEvent,
          frontBEvent: frontBEvent,
          initialRiderAssignments: initialRiderAssignments,
          initialBikeAssignments: initialBikeAssignments,
          bikeFleet: bikeFleet,
          initialStaffSplit: initialStaffSplit,
          initialStrategy: initialStrategy,
          isReadOnly: isReadOnly,
          onConfirm: (result) => Navigator.of(dialogContext).pop(result),
          onCancel: () => Navigator.of(dialogContext).pop(null),
        ),
      );
    },
  );
}

/// Produkcyjne okno przydziału kolarzy i rowerów na dwa równoległe wyścigi w tym samym dniu.
class SplitSquadCalendarAssignmentModal extends ConsumerStatefulWidget {
  final DateTime? calendarDate;
  final List<ParallelRosterRiderSnapshot>? squad;
  final ParallelRaceEventSpec? frontAEvent;
  final ParallelRaceEventSpec? frontBEvent;
  final Map<String, ParallelFrontSlot>? initialRiderAssignments;
  final Map<String, String>? initialBikeAssignments;
  final List<SplitSquadBikeAsset>? bikeFleet;
  final ParallelStaffSplitConfig? initialStaffSplit;
  final ParallelSplitStrategy initialStrategy;
  final bool isReadOnly;
  final ValueChanged<SplitSquadCalendarAssignmentResult>? onConfirm;
  final VoidCallback? onCancel;

  const SplitSquadCalendarAssignmentModal({
    super.key,
    this.calendarDate,
    this.squad,
    this.frontAEvent,
    this.frontBEvent,
    this.initialRiderAssignments,
    this.initialBikeAssignments,
    this.bikeFleet,
    this.initialStaffSplit,
    this.initialStrategy = ParallelSplitStrategy.prioritizeFrontA,
    this.isReadOnly = false,
    this.onConfirm,
    this.onCancel,
  });

  @override
  ConsumerState<SplitSquadCalendarAssignmentModal> createState() =>
      _SplitSquadCalendarAssignmentModalState();
}

class _SplitSquadCalendarAssignmentModalState
    extends ConsumerState<SplitSquadCalendarAssignmentModal> {
  late DateTime _calendarDate;
  late List<ParallelRosterRiderSnapshot> _squad;
  late ParallelRaceEventSpec _frontA;
  late ParallelRaceEventSpec _frontB;
  late List<SplitSquadBikeAsset> _fleet;
  late Map<String, ParallelFrontSlot> _riderAssignments;
  late Map<String, String> _bikeAssignments;
  late ParallelStaffSplitConfig _staffSplit;
  late ParallelSplitStrategy _strategy;
  late ParallelDayRosterValidation _rosterValidation;
  late SplitSquadBikeValidationResult _bikeValidation;

  SplitSquadAssignmentTab _activeTab = SplitSquadAssignmentTab.ridersAndBikes;
  SplitSquadRiderFilter _riderFilter = SplitSquadRiderFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final defaults = ParallelDaySimulatorState.initialDefault();
    _calendarDate = widget.calendarDate ?? defaults.calendarDate;
    _squad = List<ParallelRosterRiderSnapshot>.from(
      widget.squad ?? defaults.squad,
    );
    _frontA = widget.frontAEvent ?? defaults.frontAEvent;
    _frontB = widget.frontBEvent ?? defaults.frontBEvent;
    _fleet = List<SplitSquadBikeAsset>.from(
      widget.bikeFleet ?? SplitSquadBikeCatalog.generateTeamFleet(),
    );
    _strategy = widget.initialStrategy;
    _staffSplit = widget.initialStaffSplit ?? defaults.staffSplit;

    _riderAssignments = widget.initialRiderAssignments != null
        ? Map<String, ParallelFrontSlot>.from(widget.initialRiderAssignments!)
        : MultiRaceParallelDaySimulator.autoSplitSquadForTwoFronts(
            squad: _squad,
            frontA: _frontA,
            frontB: _frontB,
            strategy: _strategy,
          );

    _bikeAssignments = widget.initialBikeAssignments != null
        ? Map<String, String>.from(widget.initialBikeAssignments!)
        : SplitSquadBikeCatalog.autoAssignBikes(
            squad: _squad,
            riderAssignments: _riderAssignments,
            fleet: _fleet,
            frontA: _frontA,
            frontB: _frontB,
          );

    _recomputeValidation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _recomputeValidation() {
    _rosterValidation = MultiRaceParallelDaySimulator.validateSplit(
      squad: _squad,
      assignments: _riderAssignments,
      frontA: _frontA,
      frontB: _frontB,
    );
    _bikeValidation = SplitSquadBikeCatalog.validateBikeAssignments(
      squad: _squad,
      riderAssignments: _riderAssignments,
      bikeAssignments: _bikeAssignments,
      fleet: _fleet,
      frontA: _frontA,
      frontB: _frontB,
    );
  }

  bool get _canConfirm =>
      !widget.isReadOnly &&
      _rosterValidation.isValid &&
      _bikeValidation.isValid &&
      _squad.isNotEmpty;

  void _setRiderSlot(String riderId, ParallelFrontSlot slot) {
    if (widget.isReadOnly) return;
    setState(() {
      _riderAssignments[riderId] = slot;
      if (slot == ParallelFrontSlot.reserve) {
        _bikeAssignments.remove(riderId);
      } else if (!_bikeAssignments.containsKey(riderId)) {
        final usedIds = _bikeAssignments.values.toSet();
        final terrain =
            slot == ParallelFrontSlot.frontA ? _frontA.terrain : _frontB.terrain;
        final freeBikes = _fleet
            .where((b) => !usedIds.contains(b.bikeId))
            .toList()
          ..sort((a, b) {
            final aOpt = a.category.isOptimalFor(terrain) ? 1 : 0;
            final bOpt = b.category.isOptimalFor(terrain) ? 1 : 0;
            if (aOpt != bOpt) return bOpt.compareTo(aOpt);
            return b.conditionPercent.compareTo(a.conditionPercent);
          });
        if (freeBikes.isNotEmpty) {
          _bikeAssignments[riderId] = freeBikes.first.bikeId;
        }
      }
      _recomputeValidation();
    });
  }

  void _setRiderBike(String riderId, String? bikeId) {
    if (widget.isReadOnly) return;
    setState(() {
      if (bikeId == null) {
        _bikeAssignments.remove(riderId);
      } else {
        _bikeAssignments[riderId] = bikeId;
      }
      _recomputeValidation();
    });
  }

  void _runAutoSplit(ParallelSplitStrategy strategy) {
    if (widget.isReadOnly) return;
    setState(() {
      _strategy = strategy;
      _riderAssignments =
          MultiRaceParallelDaySimulator.autoSplitSquadForTwoFronts(
        squad: _squad,
        frontA: _frontA,
        frontB: _frontB,
        strategy: strategy,
      );
      _bikeAssignments = SplitSquadBikeCatalog.autoAssignBikes(
        squad: _squad,
        riderAssignments: _riderAssignments,
        fleet: _fleet,
        frontA: _frontA,
        frontB: _frontB,
      );
      _recomputeValidation();
    });
  }

  void _autoMatchBikesOnly() {
    if (widget.isReadOnly) return;
    setState(() {
      _bikeAssignments = SplitSquadBikeCatalog.autoAssignBikes(
        squad: _squad,
        riderAssignments: _riderAssignments,
        fleet: _fleet,
        frontA: _frontA,
        frontB: _frontB,
      );
      _recomputeValidation();
    });
  }

  void _handleConfirm() {
    if (!_canConfirm) return;
    final result = SplitSquadCalendarAssignmentResult(
      calendarDate: _calendarDate,
      riderAssignments: Map<String, ParallelFrontSlot>.from(_riderAssignments),
      bikeAssignments: Map<String, String>.from(_bikeAssignments),
      staffSplit: _staffSplit,
      strategy: _strategy,
      rosterValidation: _rosterValidation,
      bikeValidation: _bikeValidation,
      confirmedAt: DateTime.now(),
    );
    if (widget.onConfirm != null) {
      widget.onConfirm!(result);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime date) {
    const months = [
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
      'LIS',
      'GRU',
    ];
    final m = months[(date.month - 1).clamp(0, 11)];
    return '${date.day.toString().padLeft(2, '0')} $m ${date.year}';
  }

  List<ParallelRosterRiderSnapshot> _filteredRiders() {
    final query = _searchQuery.trim().toLowerCase();
    return _squad.where((r) {
      final slot = _riderAssignments[r.riderId] ?? ParallelFrontSlot.reserve;
      switch (_riderFilter) {
        case SplitSquadRiderFilter.all:
          break;
        case SplitSquadRiderFilter.frontA:
          if (slot != ParallelFrontSlot.frontA) return false;
        case SplitSquadRiderFilter.frontB:
          if (slot != ParallelFrontSlot.frontB) return false;
        case SplitSquadRiderFilter.reserve:
          if (slot != ParallelFrontSlot.reserve) return false;
        case SplitSquadRiderFilter.injured:
          if (r.isFitToRace) return false;
      }
      if (query.isNotEmpty) {
        return r.fullName.toLowerCase().contains(query) ||
            r.nationalityIso.toLowerCase().contains(query) ||
            r.specialization.name.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 1200;
        final double maxH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 820;
        final bool isCompact = maxW < 640;
        final bool isMedium = maxW >= 640 && maxW < 1050;
        final double modalWidth = maxW > 1180 ? 1140 : maxW;
        final double modalHeight = maxH > 840 ? 800 : maxH;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: modalWidth,
              maxHeight: modalHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _buildHeader(isCompact),
                    _buildTabsBar(isCompact),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isCompact ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFrontsOverview(isCompact, isMedium),
                            const SizedBox(height: 14),
                            if (_activeTab ==
                                SplitSquadAssignmentTab.ridersAndBikes)
                              _buildRidersAndBikesSection(isCompact, isMedium)
                            else if (_activeTab ==
                                SplitSquadAssignmentTab.bikeFleet)
                              _buildBikeFleetSection(isCompact, isMedium)
                            else
                              _buildStaffAndValidationSection(isCompact),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(isCompact),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final bool allValid = _rosterValidation.isValid && _bikeValidation.isValid;
    final Color statusColor = allValid
        ? (_rosterValidation.hasWarnings || _bikeValidation.hasWarnings
            ? AppColors.amberWarning
            : AppColors.statusSuccess)
        : AppColors.crimsonAlert;
    final String statusText = allValid
        ? (_bikeValidation.hasWarnings
            ? 'Gotowe (Ostrzeżenia)'
            : 'Gotowe do startu')
        : 'Wymaga korekty';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.call_split_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Przydział Kolarzy i Rowerów',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 15 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _formatDate(_calendarDate),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.goldAccent,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '${_squad.length} kolarzy / ${_fleet.length} rowerów',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isCompact) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    allValid
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 15,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          _InteractiveIconButton(
            tooltip: 'Zamknij okno',
            icon: Icons.close_rounded,
            onPressed: _handleCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildTabsBar(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: Row(
        children: SplitSquadAssignmentTab.values.map((tab) {
          final bool selected = _activeTab == tab;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _InteractivePillButton(
                label: tab.labelPl,
                icon: tab.icon,
                selected: selected,
                accentColor: AppColors.goldAccent,
                compact: isCompact,
                onPressed: () {
                  setState(() => _activeTab = tab);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFrontsOverview(bool isCompact, bool isMedium) {
    final int bikesFrontA = _squad
        .where((r) =>
            _riderAssignments[r.riderId] == ParallelFrontSlot.frontA &&
            _bikeAssignments.containsKey(r.riderId))
        .length;
    final int bikesFrontB = _squad
        .where((r) =>
            _riderAssignments[r.riderId] == ParallelFrontSlot.frontB &&
            _bikeAssignments.containsKey(r.riderId))
        .length;

    final cardA = _FrontSummaryCard(
      frontLabel: 'FRONT A',
      event: _frontA,
      assignedRiders: _rosterValidation.frontACount,
      assignedBikes: bikesFrontA,
      directorLevel: _staffSplit.frontADirectorLevel,
      mechanicsLevel: _staffSplit.frontAMechanicsLevel,
      hasTeamBus: _staffSplit.frontATeamBusAvailable,
      accentColor: AppColors.goldAccent,
    );
    final cardB = _FrontSummaryCard(
      frontLabel: 'FRONT B',
      event: _frontB,
      assignedRiders: _rosterValidation.frontBCount,
      assignedBikes: bikesFrontB,
      directorLevel: _staffSplit.frontBDirectorLevel,
      mechanicsLevel: _staffSplit.frontBMechanicsLevel,
      hasTeamBus: _staffSplit.frontBTeamBusAvailable,
      accentColor: AppColors.accentBlue,
    );

    if (isCompact) {
      return Column(
        children: [
          cardA,
          const SizedBox(height: 10),
          cardB,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: cardA),
        SizedBox(width: isMedium ? 10 : 14),
        Expanded(child: cardB),
      ],
    );
  }

  Widget _buildRidersAndBikesSection(bool isCompact, bool isMedium) {
    final filtered = _filteredRiders();
    final Map<String, SplitSquadBikeAsset> bikeById = {
      for (final b in _fleet) b.bikeId: b,
    };

    // Mapa użycia rowerów do wykrycia duplikatów
    final Map<String, int> bikeUsageCounts = {};
    for (final bId in _bikeAssignments.values) {
      bikeUsageCounts[bId] = (bikeUsageCounts[bId] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pasek auto-przydziału i strategii
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Strategia Auto-Podziału:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  ...ParallelSplitStrategy.values.map((s) {
                    return _InteractivePillButton(
                      label: s.labelPl,
                      selected: _strategy == s,
                      disabled: widget.isReadOnly,
                      accentColor: AppColors.primaryAccent,
                      compact: true,
                      onPressed: () => _runAutoSplit(s),
                    );
                  }),
                  _InteractivePillButton(
                    label: 'Auto-Dobierz Rowery',
                    icon: Icons.auto_fix_high_rounded,
                    selected: false,
                    disabled: widget.isReadOnly,
                    accentColor: AppColors.goldAccent,
                    compact: true,
                    onPressed: _autoMatchBikesOnly,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Wyszukiwarka + filtry slotów
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 8),
                    _buildFilterChips(),
                  ],
                )
              else
                Row(
                  children: [
                    SizedBox(width: 240, child: _buildSearchField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFilterChips()),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 34,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 8),
                Text(
                  'Brak kolarzy spełniających wybrane kryteria filtrowania.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final rider = filtered[index];
              final slot = _riderAssignments[rider.riderId] ??
                  ParallelFrontSlot.reserve;
              final assignedBikeId = _bikeAssignments[rider.riderId];
              final assignedBike =
                  assignedBikeId != null ? bikeById[assignedBikeId] : null;
              final bool isBikeDuplicated = assignedBikeId != null &&
                  (bikeUsageCounts[assignedBikeId] ?? 0) > 1;

              return _RiderAssignmentRowCard(
                rider: rider,
                slot: slot,
                frontA: _frontA,
                frontB: _frontB,
                assignedBike: assignedBike,
                isBikeDuplicated: isBikeDuplicated,
                fleet: _fleet,
                bikeUsageCounts: bikeUsageCounts,
                isReadOnly: widget.isReadOnly,
                isCompact: isCompact,
                onSlotChanged: (newSlot) => _setRiderSlot(rider.riderId, newSlot),
                onBikeChanged: (newBikeId) =>
                    _setRiderBike(rider.riderId, newBikeId),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Szukaj kolarza lub kraju...',
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
                icon: const Icon(Icons.clear_rounded, size: 16),
                color: AppColors.textSecondary,
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldAccent),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SplitSquadRiderFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _InteractivePillButton(
              label: filter.labelPl,
              selected: _riderFilter == filter,
              accentColor: AppColors.accentBlue,
              compact: true,
              onPressed: () => setState(() => _riderFilter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBikeFleetSection(bool isCompact, bool isMedium) {
    final Map<String, ParallelRosterRiderSnapshot> riderById = {
      for (final r in _squad) r.riderId: r,
    };

    // Odwrotne mapowanie: bikeId -> lista riderIds
    final Map<String, List<String>> bikeToRiders = {};
    for (final entry in _bikeAssignments.entries) {
      bikeToRiders.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    if (_fleet.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'Brak zarejestrowanych rowerów w garażu zespołu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final int crossAxisCount = isCompact ? 1 : (isMedium ? 2 : 3);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fleet.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 124,
      ),
      itemBuilder: (context, index) {
        final bike = _fleet[index];
        final assignedRiderIds = bikeToRiders[bike.bikeId] ?? const [];
        final bool isConflict = assignedRiderIds.length > 1;
        final rider = assignedRiderIds.isNotEmpty
            ? riderById[assignedRiderIds.first]
            : null;
        final slot = rider != null
            ? (_riderAssignments[rider.riderId] ?? ParallelFrontSlot.reserve)
            : null;

        final Color borderColor = isConflict
            ? AppColors.crimsonAlert
            : (slot == ParallelFrontSlot.frontA
                ? AppColors.goldAccent.withValues(alpha: 0.6)
                : (slot == ParallelFrontSlot.frontB
                    ? AppColors.accentBlue.withValues(alpha: 0.6)
                    : AppColors.cardBorder));

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    bike.category.icon,
                    size: 18,
                    color: bike.category.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bike.modelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${bike.weightKg.toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: bike.isUciCompliant
                            ? AppColors.textSecondary
                            : AppColors.crimsonAlert,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${bike.category.labelPl} • ${bike.wheelsetLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isConflict
                          ? 'KONFLIKT: ${assignedRiderIds.length} kolarzy!'
                          : (rider != null
                              ? '${slot!.labelPl}: ${rider.fullName}'
                              : 'Wolny (Garaż / Zapas)'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isConflict
                            ? AppColors.crimsonAlert
                            : (rider != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stan ${bike.conditionPercent}%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: bike.needsMaintenanceWarning
                          ? AppColors.amberWarning
                          : AppColors.statusSuccess,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffAndValidationSection(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Logistyka Autobusów i Dyrektorów Sportowych',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Główny Autobus Drużyny na Froncie A',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Zapewnia pełną rozgrzewkę na trenażerach i regenerację w strefie paddocku.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  activeTrackColor: AppColors.goldAccent,
                  value: _staffSplit.frontATeamBusAvailable,
                  onChanged: widget.isReadOnly
                      ? null
                      : (val) {
                          setState(() {
                            _staffSplit = _staffSplit.copyWith(
                              frontATeamBusAvailable: val,
                              frontBTeamBusAvailable: !val,
                            );
                          });
                        },
                ),
              ),
              const Divider(color: AppColors.cardBorder, height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InteractivePillButton(
                    label: 'Zamień Głównych DS (A ↔ B)',
                    icon: Icons.swap_horiz_rounded,
                    selected: false,
                    disabled: widget.isReadOnly,
                    accentColor: AppColors.accentBlue,
                    onPressed: () {
                      setState(() {
                        _staffSplit = _staffSplit.copyWith(
                          frontADirectorLevel: _staffSplit.frontBDirectorLevel,
                          frontBDirectorLevel: _staffSplit.frontADirectorLevel,
                        );
                      });
                    },
                  ),
                  _InteractivePillButton(
                    label: 'Zamień Głównych Mechaników (A ↔ B)',
                    icon: Icons.build_rounded,
                    selected: false,
                    disabled: widget.isReadOnly,
                    accentColor: AppColors.goldAccent,
                    onPressed: () {
                      setState(() {
                        _staffSplit = _staffSplit.copyWith(
                          frontAMechanicsLevel: _staffSplit.frontBMechanicsLevel,
                          frontBMechanicsLevel: _staffSplit.frontAMechanicsLevel,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Raport Walidacji Przydziału',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (_rosterValidation.issues.isEmpty &&
                  _bikeValidation.isValid &&
                  !_bikeValidation.hasWarnings)
                const _ValidationItemRow(
                  severity: ParallelValidationSeverity.ok,
                  text:
                      'Składy, limity UCI (6.80 kg) oraz przydział rowerów na oba fronty są w 100% poprawne.',
                ),
              ..._rosterValidation.issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ValidationItemRow(
                    severity: issue.severity,
                    text: issue.message,
                  ),
                ),
              ),
              if (_bikeValidation.missingRiderIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ValidationItemRow(
                    severity: ParallelValidationSeverity.error,
                    text:
                        'Brak przypisanego roweru dla ${_bikeValidation.missingRiderIds.length} kolarzy startujących.',
                  ),
                ),
              if (_bikeValidation.duplicateBikeIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ValidationItemRow(
                    severity: ParallelValidationSeverity.error,
                    text:
                        'Ten sam rower został przypisany jednocześnie do kilku kolarzy (${_bikeValidation.duplicateBikeIds.length} konfliktów).',
                  ),
                ),
              if (_bikeValidation.terrainMismatchRiderIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ValidationItemRow(
                    severity: ParallelValidationSeverity.warning,
                    text:
                        '${_bikeValidation.terrainMismatchRiderIds.length} kolarzy ma rower niedopasowany do profilu terenu.',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isCompact) {
    final bool hasErrors = !_rosterValidation.isValid || !_bikeValidation.isValid;
    final String summaryText;
    final Color summaryColor;

    if (hasErrors) {
      final int errCount = _rosterValidation.errors.length +
          _bikeValidation.missingRiderIds.length +
          _bikeValidation.duplicateBikeIds.length +
          _bikeValidation.nonCompliantBikeIds.length;
      summaryText = 'Błędy do poprawy: $errCount';
      summaryColor = AppColors.crimsonAlert;
    } else if (_bikeValidation.hasWarnings || _rosterValidation.hasWarnings) {
      summaryText = 'Przydział poprawny (z ostrzeżeniami sprzętowymi)';
      summaryColor = AppColors.amberWarning;
    } else {
      summaryText =
          'Front A: ${_rosterValidation.frontACount} • Front B: ${_rosterValidation.frontBCount} • Rezerwa: ${_rosterValidation.reserveCount}';
      summaryColor = AppColors.statusSuccess;
    }

    final cancelButton = _InteractivePillButton(
      label: 'Anuluj',
      selected: false,
      accentColor: AppColors.textSecondary,
      onPressed: _handleCancel,
    );

    final confirmButton = _InteractivePillButton(
      label: 'Zatwierdź Skład i Sprzęt',
      icon: Icons.check_rounded,
      selected: true,
      disabled: !_canConfirm,
      accentColor: AppColors.goldAccent,
      onPressed: _handleConfirm,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.0),
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  summaryText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: summaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: cancelButton),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: confirmButton),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    summaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: summaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                cancelButton,
                const SizedBox(width: 10),
                confirmButton,
              ],
            ),
    );
  }
}

class _FrontSummaryCard extends StatelessWidget {
  final String frontLabel;
  final ParallelRaceEventSpec event;
  final int assignedRiders;
  final int assignedBikes;
  final int directorLevel;
  final int mechanicsLevel;
  final bool hasTeamBus;
  final Color accentColor;

  const _FrontSummaryCard({
    required this.frontLabel,
    required this.event,
    required this.assignedRiders,
    required this.assignedBikes,
    required this.directorLevel,
    required this.mechanicsLevel,
    required this.hasTeamBus,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool riderCountOk = assignedRiders >= event.requiredMinRiders &&
        assignedRiders <= event.requiredMaxRiders;
    final bool bikeCountOk = assignedBikes == assignedRiders;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  frontLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.raceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(event.terrain.icon, size: 17, color: accentColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${event.stageName} • ${event.distanceKm.toStringAsFixed(0)} km • ${event.elevationGainM} m',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetricBadge(
                label:
                    'Kolarze: $assignedRiders/${event.requiredMinRiders}–${event.requiredMaxRiders}',
                color: riderCountOk
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _MetricBadge(
                label: 'Rowery: $assignedBikes/$assignedRiders',
                color: bikeCountOk
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
              ),
              _MetricBadge(
                label: 'DS $directorLevel • Mech $mechanicsLevel',
                color: AppColors.textSecondary,
              ),
              if (hasTeamBus)
                const _MetricBadge(
                  label: 'Autobus Drużyny',
                  color: AppColors.goldAccent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MetricBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

class _RiderAssignmentRowCard extends StatelessWidget {
  final ParallelRosterRiderSnapshot rider;
  final ParallelFrontSlot slot;
  final ParallelRaceEventSpec frontA;
  final ParallelRaceEventSpec frontB;
  final SplitSquadBikeAsset? assignedBike;
  final bool isBikeDuplicated;
  final List<SplitSquadBikeAsset> fleet;
  final Map<String, int> bikeUsageCounts;
  final bool isReadOnly;
  final bool isCompact;
  final ValueChanged<ParallelFrontSlot> onSlotChanged;
  final ValueChanged<String?> onBikeChanged;

  const _RiderAssignmentRowCard({
    required this.rider,
    required this.slot,
    required this.frontA,
    required this.frontB,
    required this.assignedBike,
    required this.isBikeDuplicated,
    required this.fleet,
    required this.bikeUsageCounts,
    required this.isReadOnly,
    required this.isCompact,
    required this.onSlotChanged,
    required this.onBikeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isReadOnly || !rider.isFitToRace;
    final double fitA = rider.terrainAffinityScore(frontA.terrain);
    final double fitB = rider.terrainAffinityScore(frontB.terrain);

    final Color borderColor = !rider.isFitToRace
        ? AppColors.crimsonAlert.withValues(alpha: 0.45)
        : (slot == ParallelFrontSlot.frontA
            ? AppColors.goldAccent.withValues(alpha: 0.55)
            : (slot == ParallelFrontSlot.frontB
                ? AppColors.accentBlue.withValues(alpha: 0.55)
                : AppColors.cardBorder));

    final riderInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rider.nationalityIso.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rider.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: rider.isFitToRace
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'OVR ${rider.overallRating}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.goldAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'TSB ${rider.tsb >= 0 ? '+' : ''}${rider.tsb.toStringAsFixed(0)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: rider.tsb >= 0
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
            ),
            Text(
              'Dopas. A: ${fitA.toStringAsFixed(0)} • B: ${fitB.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textSecondary,
              ),
            ),
            if (!rider.isFitToRace)
              Text(
                'Kontuzja: ${rider.injuryLabel ?? 'Niedysponowany'}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.crimsonAlert,
                ),
              ),
          ],
        ),
      ],
    );

    final slotSelector = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InteractivePillButton(
          label: 'Front A',
          selected: slot == ParallelFrontSlot.frontA,
          disabled: disabled,
          accentColor: AppColors.goldAccent,
          compact: true,
          onPressed: () => onSlotChanged(ParallelFrontSlot.frontA),
        ),
        const SizedBox(width: 4),
        _InteractivePillButton(
          label: 'Front B',
          selected: slot == ParallelFrontSlot.frontB,
          disabled: disabled,
          accentColor: AppColors.accentBlue,
          compact: true,
          onPressed: () => onSlotChanged(ParallelFrontSlot.frontB),
        ),
        const SizedBox(width: 4),
        _InteractivePillButton(
          label: 'Rez.',
          selected: slot == ParallelFrontSlot.reserve,
          disabled: isReadOnly,
          accentColor: AppColors.textSecondary,
          compact: true,
          onPressed: () => onSlotChanged(ParallelFrontSlot.reserve),
        ),
      ],
    );

    final bikeDropdown = slot == ParallelFrontSlot.reserve
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'Brak startu (Rezerwa)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isBikeDuplicated || assignedBike == null
                    ? AppColors.crimsonAlert
                    : AppColors.cardBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                isDense: true,
                value: assignedBike?.bikeId,
                dropdownColor: AppColors.surface,
                hint: const Text(
                  'Wybierz rower...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.crimsonAlert,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                items: fleet.map((bike) {
                  final int count = bikeUsageCounts[bike.bikeId] ?? 0;
                  final bool takenByOther =
                      count > 0 && bike.bikeId != assignedBike?.bikeId;
                  return DropdownMenuItem<String>(
                    value: bike.bikeId,
                    child: Text(
                      '${bike.modelName} (${bike.category.labelPl})${takenByOther ? ' [ZAJĘTY]' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: takenByOther
                            ? AppColors.amberWarning
                            : AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: isReadOnly ? null : onBikeChanged,
              ),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                riderInfo,
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: slotSelector,
                ),
                const SizedBox(height: 8),
                bikeDropdown,
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: riderInfo),
                const SizedBox(width: 12),
                slotSelector,
                const SizedBox(width: 12),
                SizedBox(width: 225, child: bikeDropdown),
              ],
            ),
    );
  }
}

class _ValidationItemRow extends StatelessWidget {
  final ParallelValidationSeverity severity;
  final String text;

  const _ValidationItemRow({required this.severity, required this.text});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (severity) {
      case ParallelValidationSeverity.ok:
        color = AppColors.statusSuccess;
        icon = Icons.check_circle_outline_rounded;
      case ParallelValidationSeverity.warning:
        color = AppColors.amberWarning;
        icon = Icons.warning_amber_rounded;
      case ParallelValidationSeverity.error:
        color = AppColors.crimsonAlert;
        icon = Icons.error_outline_rounded;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final bool compact;
  final Color accentColor;
  final VoidCallback onPressed;

  const _InteractivePillButton({
    required this.label,
    this.icon,
    required this.selected,
    this.disabled = false,
    this.compact = false,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.disabled;
    final Color bgColor;
    if (isDisabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.35);
    } else if (widget.selected) {
      bgColor = widget.accentColor.withValues(alpha: _pressed ? 0.30 : 0.20);
    } else if (_pressed) {
      bgColor = AppColors.surfaceLight;
    } else if (_hovered) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.85);
    } else {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.55);
    }

    final Color borderColor = isDisabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : (_focused
            ? AppColors.cyanAccent
            : (widget.selected
                ? widget.accentColor
                : (_hovered
                    ? widget.accentColor.withValues(alpha: 0.55)
                    : AppColors.cardBorder)));

    final Color fgColor = isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (widget.selected ? widget.accentColor : AppColors.textPrimary);

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowFocusHighlight: (f) => setState(() => _focused = f),
      onShowHoverHighlight: (h) => setState(() => _hovered = h),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel:
            isDisabled ? null : () => setState(() => _pressed = false),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 7 : 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: widget.compact ? 14 : 16, color: fgColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 11 : 13,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
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

class _InteractiveIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _InteractiveIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_InteractiveIconButton> createState() => _InteractiveIconButtonState();
}

class _InteractiveIconButtonState extends State<_InteractiveIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowFocusHighlight: (f) => setState(() => _focused = f),
        onShowHoverHighlight: (h) => setState(() => _hovered = h),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.cyanAccent : AppColors.cardBorder,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
