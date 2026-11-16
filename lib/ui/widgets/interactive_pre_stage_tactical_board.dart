import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';
import '../../models/rider/rider.dart';
import 'elevation_profile_chart.dart';

/// Typ rozkazu taktycznego przypisywanego na Stole Taktycznym przed etapem.
enum TacticalBoardOrderType {
  protectLeader(
    label: 'Chroni lidera',
    shortLabel: 'Ochrona',
    icon: Icons.security_rounded,
    color: AppColors.accentBlue,
    supportsRange: true,
    defaultSpanKm: 40.0,
  ),
  mountainTrain(
    label: 'Pociąg górski',
    shortLabel: 'Pociąg',
    icon: Icons.terrain_rounded,
    color: Color(0xFFEC4899),
    supportsRange: true,
    defaultSpanKm: 12.0,
  ),
  attack(
    label: 'Atak',
    shortLabel: 'Atak',
    icon: Icons.flash_on_rounded,
    color: AppColors.crimsonAlert,
    supportsRange: false,
    defaultSpanKm: 0.0,
  ),
  breakaway(
    label: 'Ucieczka dnia',
    shortLabel: 'Ucieczka',
    icon: Icons.bolt_rounded,
    color: AppColors.amberWarning,
    supportsRange: true,
    defaultSpanKm: 65.0,
  ),
  sprintLeadout(
    label: 'Rozprowadzenie',
    shortLabel: 'Lead-out',
    icon: Icons.double_arrow_rounded,
    color: AppColors.cyanAccent,
    supportsRange: true,
    defaultSpanKm: 5.0,
  ),
  fetchBidons(
    label: 'Bidony i żele',
    shortLabel: 'Bidony',
    icon: Icons.local_drink_rounded,
    color: AppColors.statusSuccess,
    supportsRange: false,
    defaultSpanKm: 0.0,
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final bool supportsRange;
  final double defaultSpanKm;

  const TacticalBoardOrderType({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.supportsRange,
    required this.defaultSpanKm,
  });
}

/// Kolarz dostępny na Stole Taktycznym przed etapem.
class TacticalBoardRiderEntry {
  final String riderId;
  final String riderName;
  final String shortName;
  final String roleLabel;
  final int jerseyNumber;
  final Color accentColor;

  const TacticalBoardRiderEntry({
    required this.riderId,
    required this.riderName,
    required this.shortName,
    required this.roleLabel,
    required this.jerseyNumber,
    required this.accentColor,
  });

  factory TacticalBoardRiderEntry.fromRider(
    Rider rider, {
    int jerseyNumber = 1,
    String? roleLabel,
    Color? accentColor,
  }) {
    final bool isLeader =
        rider.specialization == RiderSpecialization.gcClimber ||
            rider.specialization == RiderSpecialization.pureClimber;
    final Color resolvedColor = accentColor ??
        (isLeader ? AppColors.goldAccent : AppColors.accentBlue);
    return TacticalBoardRiderEntry(
      riderId: rider.id,
      riderName: '${rider.firstName} ${rider.lastName}',
      shortName: rider.firstName.isNotEmpty
          ? rider.firstName
          : rider.lastName,
      roleLabel: roleLabel ?? rider.specialization.displayName,
      jerseyNumber: jerseyNumber,
      accentColor: resolvedColor,
    );
  }
}

/// Pojedynczy rozkaz taktyczny przypięty do profilu trasy.
class TacticalStageAssignment {
  final String id;
  final String riderId;
  final TacticalBoardOrderType orderType;
  final double startKm;
  final double? endKm;

  const TacticalStageAssignment({
    required this.id,
    required this.riderId,
    required this.orderType,
    required this.startKm,
    this.endKm,
  });

  double get effectiveEndKm =>
      orderType.supportsRange ? (endKm ?? startKm) : startKm;

  TacticalStageAssignment copyWith({
    String? id,
    String? riderId,
    TacticalBoardOrderType? orderType,
    double? startKm,
    double? endKm,
    bool clearEndKm = false,
  }) {
    return TacticalStageAssignment(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      orderType: orderType ?? this.orderType,
      startKm: startKm ?? this.startKm,
      endKm: clearEndKm ? null : (endKm ?? this.endKm),
    );
  }

  /// Czytelny opis taktyczny w języku polskim z dokładnym kilometrażem i nachyleniem.
  String describeForStage(
    RaceStage stage,
    TacticalBoardRiderEntry rider,
  ) {
    final int sKm = startKm.round();
    final int eKm = effectiveEndKm.round();
    final double gradient = StageProfileSampler.gradientAtKm(stage, startKm);
    final String gradStr = (gradient - gradient.round()).abs() < 0.05
        ? '${gradient.round()}%'
        : '${gradient.toStringAsFixed(1)}%';

    switch (orderType) {
      case TacticalBoardOrderType.protectLeader:
        return '${rider.shortName} chroni lidera od km $sKm do km $eKm';
      case TacticalBoardOrderType.mountainTrain:
        if (eKm > sKm + 1) {
          return '${rider.shortName} rozpoczyna pociąg górski na km $sKm (do km $eKm)';
        }
        return '${rider.shortName} rozpoczyna pociąg górski na km $sKm';
      case TacticalBoardOrderType.attack:
        return '${rider.shortName} atakuje na km $sKm (gradient $gradStr)';
      case TacticalBoardOrderType.breakaway:
        return '${rider.shortName} zabiera się w ucieczkę od km $sKm do km $eKm';
      case TacticalBoardOrderType.sprintLeadout:
        return '${rider.shortName} rozprowadza pociąg od km $sKm do km $eKm';
      case TacticalBoardOrderType.fetchBidons:
        return '${rider.shortName} zjeżdża po bidony na km $sKm';
    }
  }
}

/// Narzędzie pomocnicze do próbkowania wysokości, nachylenia i automatycznego planu taktycznego.
class StageProfileSampler {
  StageProfileSampler._();

  static double elevationAtKm(RaceStage stage, double km) {
    if (stage.segments.isEmpty) return 0.0;
    final double clampedKm = km.clamp(0.0, math.max(0.0, stage.totalDistanceKm));
    for (final seg in stage.segments) {
      if (clampedKm >= seg.startKm && clampedKm <= seg.endKm) {
        if (seg.lengthKm <= 0.0) return seg.startElevationM;
        final double t = ((clampedKm - seg.startKm) / seg.lengthKm).clamp(0.0, 1.0);
        return seg.startElevationM + (seg.endElevationM - seg.startElevationM) * t;
      }
    }
    return stage.segments.last.endElevationM;
  }

  static StageSegment? segmentAtKm(RaceStage stage, double km) {
    if (stage.segments.isEmpty) return null;
    final double clampedKm = km.clamp(0.0, math.max(0.0, stage.totalDistanceKm));
    for (final seg in stage.segments) {
      if (clampedKm >= seg.startKm && clampedKm <= seg.endKm) {
        return seg;
      }
    }
    return stage.segments.last;
  }

  static double gradientAtKm(RaceStage stage, double km) {
    return segmentAtKm(stage, km)?.gradientPercent ?? 0.0;
  }

  /// Generuje inteligentny plan taktyczny dopasowany do profilu trasy i składu.
  static List<TacticalStageAssignment> autoGenerateSmartPlan(
    RaceStage stage,
    List<TacticalBoardRiderEntry> riders,
  ) {
    if (riders.isEmpty || stage.totalDistanceKm <= 0.0) return const [];
    final double totalKm = stage.totalDistanceKm;
    final List<TacticalStageAssignment> plan = [];

    // Znajdź najstromszy odcinek podjazdowy na etapie
    StageSegment? steepestClimb;
    for (final seg in stage.segments) {
      if (seg.gradientPercent > 3.5) {
        if (steepestClimb == null ||
            seg.gradientPercent > steepestClimb.gradientPercent) {
          steepestClimb = seg;
        }
      }
    }

    // Znajdź podnóże kluczowego podjazdu
    double mountainTrainKm = math.max(0.0, totalKm * 0.72);
    double attackKm = math.max(0.0, totalKm * 0.85);
    if (steepestClimb != null) {
      attackKm = (steepestClimb.startKm + steepestClimb.lengthKm * 0.5)
          .clamp(0.0, totalKm);
      mountainTrainKm = math.max(0.0, steepestClimb.startKm - 5.0);
    }

    final TacticalBoardRiderEntry leader = riders.firstWhere(
      (r) =>
          r.roleLabel.toLowerCase().contains('lider') ||
          r.roleLabel.toLowerCase().contains('gc'),
      orElse: () => riders.first,
    );

    final List<TacticalBoardRiderEntry> helpers =
        riders.where((r) => r.riderId != leader.riderId).toList();

    if (helpers.isNotEmpty) {
      final double protectEnd =
          math.min(totalKm, math.max(10.0, mountainTrainKm - 5.0));
      plan.add(
        TacticalStageAssignment(
          id: 'auto_protect_${helpers.first.riderId}',
          riderId: helpers.first.riderId,
          orderType: TacticalBoardOrderType.protectLeader,
          startKm: 0.0,
          endKm: protectEnd,
        ),
      );
    }

    if (helpers.length >= 2 && steepestClimb != null) {
      plan.add(
        TacticalStageAssignment(
          id: 'auto_train_${helpers[1].riderId}',
          riderId: helpers[1].riderId,
          orderType: TacticalBoardOrderType.mountainTrain,
          startKm: mountainTrainKm.roundToDouble(),
          endKm: math.min(totalKm, attackKm),
        ),
      );
    } else if (helpers.length >= 2) {
      plan.add(
        TacticalStageAssignment(
          id: 'auto_leadout_${helpers[1].riderId}',
          riderId: helpers[1].riderId,
          orderType: TacticalBoardOrderType.sprintLeadout,
          startKm: math.max(0.0, totalKm - 8.0).roundToDouble(),
          endKm: math.max(0.0, totalKm - 0.5),
        ),
      );
    }

    plan.add(
      TacticalStageAssignment(
        id: 'auto_attack_${leader.riderId}',
        riderId: leader.riderId,
        orderType: TacticalBoardOrderType.attack,
        startKm: attackKm.roundToDouble(),
      ),
    );

    return plan;
  }
}

/// Interaktywny Stół Taktyczny na ekranie odprawy przed etapem (#223).
/// Umożliwia przeciąganie kolarzy bezpośrednio na wykres profilu trasy,
/// przesuwanie znaczników startu i końca rozkazu oraz precyzyjną edycję km.
class InteractivePreStageTacticalBoard extends StatefulWidget {
  final RaceStage stage;
  final List<TacticalBoardRiderEntry> riders;
  final List<TacticalStageAssignment>? initialAssignments;
  final ValueChanged<List<TacticalStageAssignment>>? onAssignmentsChanged;
  final bool enabled;

  const InteractivePreStageTacticalBoard({
    super.key,
    required this.stage,
    required this.riders,
    this.initialAssignments,
    this.onAssignmentsChanged,
    this.enabled = true,
  });

  @override
  State<InteractivePreStageTacticalBoard> createState() =>
      _InteractivePreStageTacticalBoardState();
}

class _InteractivePreStageTacticalBoardState
    extends State<InteractivePreStageTacticalBoard> {
  static const EdgeInsets _chartPadding =
      EdgeInsets.fromLTRB(44.0, 22.0, 16.0, 28.0);

  late List<TacticalStageAssignment> _assignments;
  TacticalBoardOrderType _activeOrderType =
      TacticalBoardOrderType.protectLeader;
  String? _selectedRiderId;
  String? _selectedAssignmentId;
  double? _hoverPreviewKm;
  String? _draggingAssignmentId;
  bool _draggingEndHandle = false;
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    _assignments = List<TacticalStageAssignment>.from(
      widget.initialAssignments ??
          StageProfileSampler.autoGenerateSmartPlan(
            widget.stage,
            widget.riders,
          ),
    );
    if (_assignments.isNotEmpty) {
      _selectedAssignmentId = _assignments.first.id;
    }
    if (widget.riders.isNotEmpty) {
      _selectedRiderId = widget.riders.first.riderId;
    }
  }

  @override
  void didUpdateWidget(covariant InteractivePreStageTacticalBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAssignments != null &&
        widget.initialAssignments != oldWidget.initialAssignments) {
      _assignments = List<TacticalStageAssignment>.from(
        widget.initialAssignments!,
      );
    }
  }

  double get _totalKm => math.max(1.0, widget.stage.totalDistanceKm);

  TacticalBoardRiderEntry? _riderById(String riderId) {
    for (final r in widget.riders) {
      if (r.riderId == riderId) return r;
    }
    return null;
  }

  TacticalStageAssignment? get _selectedAssignment {
    if (_selectedAssignmentId == null) return null;
    for (final a in _assignments) {
      if (a.id == _selectedAssignmentId) return a;
    }
    return null;
  }

  void _emitChanged() {
    widget.onAssignmentsChanged?.call(
      List<TacticalStageAssignment>.unmodifiable(_assignments),
    );
  }

  double _snapKm(double km) {
    final double clamped = km.clamp(0.0, _totalKm);
    return (clamped * 2.0).round() / 2.0;
  }

  double _dxToKm(double localDx, double chartWidth) {
    final double plotWidth =
        math.max(1.0, chartWidth - _chartPadding.left - _chartPadding.right);
    final double rel =
        ((localDx - _chartPadding.left) / plotWidth).clamp(0.0, 1.0);
    return _snapKm(rel * _totalKm);
  }

  double _kmToDx(double km, double chartWidth) {
    final double plotWidth =
        math.max(1.0, chartWidth - _chartPadding.left - _chartPadding.right);
    final double ratio = (km / _totalKm).clamp(0.0, 1.0);
    return _chartPadding.left + ratio * plotWidth;
  }

  double _elevationToDy(double elevationM, double chartHeight) {
    final double minElev = widget.stage.minElevationM;
    final double maxElev = widget.stage.maxElevationM;
    final double range = math.max(50.0, maxElev - minElev);
    final double plotHeight =
        math.max(1.0, chartHeight - _chartPadding.top - _chartPadding.bottom);
    final double ratio = ((elevationM - minElev) / range).clamp(0.0, 1.0);
    return _chartPadding.top + plotHeight * (1.0 - ratio);
  }

  void _addOrPlaceAssignment(
    TacticalBoardRiderEntry rider,
    double startKm, {
    TacticalBoardOrderType? forcedOrderType,
  }) {
    if (!widget.enabled) return;
    final TacticalBoardOrderType orderType = forcedOrderType ?? _activeOrderType;
    final double snappedStart = _snapKm(startKm);
    final double? snappedEnd = orderType.supportsRange
        ? math.min(
            _totalKm,
            math.max(snappedStart + 5.0, snappedStart + orderType.defaultSpanKm),
          )
        : null;

    _idCounter++;
    final TacticalStageAssignment newAssignment = TacticalStageAssignment(
      id: 'tac_${rider.riderId}_${DateTime.now().microsecondsSinceEpoch}_$_idCounter',
      riderId: rider.riderId,
      orderType: orderType,
      startKm: snappedStart,
      endKm: snappedEnd,
    );

    setState(() {
      _assignments.add(newAssignment);
      _selectedRiderId = rider.riderId;
      _selectedAssignmentId = newAssignment.id;
      _hoverPreviewKm = null;
    });
    _emitChanged();
  }

  void _updateAssignmentKm(
    String assignmentId, {
    double? newStartKm,
    double? newEndKm,
  }) {
    if (!widget.enabled) return;
    final int idx = _assignments.indexWhere((a) => a.id == assignmentId);
    if (idx < 0) return;

    final TacticalStageAssignment current = _assignments[idx];
    double start = newStartKm != null ? _snapKm(newStartKm) : current.startKm;
    double? end = current.endKm;

    if (current.orderType.supportsRange) {
      final double prevSpan =
          math.max(2.0, current.effectiveEndKm - current.startKm);
      if (newStartKm != null && newEndKm == null) {
        end = math.min(_totalKm, start + prevSpan);
      } else if (newEndKm != null) {
        end = _snapKm(newEndKm);
        if (end < start + 1.0) {
          end = math.min(_totalKm, start + 1.0);
        }
      }
    }

    setState(() {
      _assignments[idx] = current.copyWith(
        startKm: start,
        endKm: end,
      );
    });
    _emitChanged();
  }

  void _changeAssignmentOrderType(
    String assignmentId,
    TacticalBoardOrderType newType,
  ) {
    if (!widget.enabled) return;
    final int idx = _assignments.indexWhere((a) => a.id == assignmentId);
    if (idx < 0) return;

    final TacticalStageAssignment current = _assignments[idx];
    final double? newEnd = newType.supportsRange
        ? (current.endKm != null && current.endKm! > current.startKm + 1.0
            ? math.min(_totalKm, current.endKm!)
            : math.min(_totalKm, current.startKm + newType.defaultSpanKm))
        : null;

    setState(() {
      _assignments[idx] = current.copyWith(
        orderType: newType,
        endKm: newEnd,
        clearEndKm: !newType.supportsRange,
      );
    });
    _emitChanged();
  }

  void _removeAssignment(String assignmentId) {
    if (!widget.enabled) return;
    setState(() {
      _assignments.removeWhere((a) => a.id == assignmentId);
      if (_selectedAssignmentId == assignmentId) {
        _selectedAssignmentId =
            _assignments.isNotEmpty ? _assignments.first.id : null;
      }
    });
    _emitChanged();
  }

  void _applyAutoPlan() {
    if (!widget.enabled) return;
    final List<TacticalStageAssignment> generated =
        StageProfileSampler.autoGenerateSmartPlan(widget.stage, widget.riders);
    setState(() {
      _assignments = generated;
      _selectedAssignmentId =
          generated.isNotEmpty ? generated.first.id : null;
    });
    _emitChanged();
  }

  void _clearAll() {
    if (!widget.enabled) return;
    setState(() {
      _assignments.clear();
      _selectedAssignmentId = null;
    });
    _emitChanged();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bool isCompact = width < 640;
        final bool isWide = width >= 1120;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: widget.enabled ? 1.0 : 0.62,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 12),
                _buildOrderTypeToolbar(isCompact),
                const SizedBox(height: 12),
                _buildRiderDock(isCompact),
                const SizedBox(height: 14),
                _buildInteractiveProfileCanvas(isCompact),
                if (_selectedAssignment != null) ...[
                  const SizedBox(height: 12),
                  _buildSelectedInspector(_selectedAssignment!, isCompact),
                ],
                const SizedBox(height: 14),
                if (isWide && _assignments.isNotEmpty)
                  _buildTimelineList(isCompact: false)
                else
                  _buildTimelineList(isCompact: isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final Widget titleGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: const Icon(
            Icons.route_rounded,
            size: 18,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INTERAKTYWNY STÓŁ TAKTYCZNY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Przeciągnij kolarza na wykres profilu lub przesuwaj znaczniki km (${widget.stage.totalDistanceKm.toStringAsFixed(0)} km)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget actionsGroup = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TacticalActionButton(
          icon: Icons.auto_awesome_rounded,
          label: 'Auto-Taktyka',
          accentColor: AppColors.goldAccent,
          enabled: widget.enabled && widget.riders.isNotEmpty,
          onTap: _applyAutoPlan,
        ),
        _TacticalActionButton(
          icon: Icons.delete_sweep_rounded,
          label: 'Wyczyść',
          accentColor: AppColors.textSecondary,
          enabled: widget.enabled && _assignments.isNotEmpty,
          onTap: _clearAll,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleGroup,
          const SizedBox(height: 10),
          actionsGroup,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleGroup),
        const SizedBox(width: 12),
        actionsGroup,
      ],
    );
  }

  Widget _buildOrderTypeToolbar(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRYB ROZKAZU PRZED PRZECIĄGNIĘCIEM:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TacticalBoardOrderType.values.map((orderType) {
              final bool isSelected = _activeOrderType == orderType;
              return _OrderTypeChip(
                orderType: orderType,
                isSelected: isSelected,
                enabled: widget.enabled,
                compact: isCompact,
                onTap: () {
                  setState(() {
                    _activeOrderType = orderType;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderDock(bool isCompact) {
    if (widget.riders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'Brak przypisanych kolarzy w składzie na ten etap.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 14,
              color: AppColors.cyanAccent,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'KOLARZE SKŁADU — PRZECIĄGNIJ NA WYKRES LUB KLIKNIJ ABY WYBRAĆ:',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.riders.map((rider) {
            final bool isSelected = _selectedRiderId == rider.riderId;
            final int count =
                _assignments.where((a) => a.riderId == rider.riderId).length;
            final Widget chip = _RiderDockChip(
              rider: rider,
              isSelected: isSelected,
              assignmentCount: count,
              enabled: widget.enabled,
              compact: isCompact,
              onTap: () {
                setState(() {
                  _selectedRiderId = rider.riderId;
                });
              },
            );

            if (!widget.enabled) return chip;

            return Draggable<TacticalBoardRiderEntry>(
              data: rider,
              feedback: Material(
                color: Colors.transparent,
                child: _RiderDragFeedbackBadge(
                  rider: rider,
                  orderType: _activeOrderType,
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.45, child: chip),
              child: chip,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInteractiveProfileCanvas(bool isCompact) {
    final double chartHeight = isCompact ? 225.0 : 275.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hoverPreviewKm != null
              ? AppColors.cyanAccent.withValues(alpha: 0.7)
              : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, chartConstraints) {
          final double chartWidth = chartConstraints.maxWidth;

          return DragTarget<TacticalBoardRiderEntry>(
            onWillAcceptWithDetails: (_) => widget.enabled,
            onMove: (details) {
              if (!widget.enabled) return;
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final Offset local = box.globalToLocal(details.offset);
              final double km = _dxToKm(local.dx, chartWidth);
              if (_hoverPreviewKm != km) {
                setState(() {
                  _hoverPreviewKm = km;
                });
              }
            },
            onLeave: (_) {
              if (_hoverPreviewKm != null) {
                setState(() {
                  _hoverPreviewKm = null;
                });
              }
            },
            onAcceptWithDetails: (details) {
              if (!widget.enabled) return;
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              double dropKm = _totalKm * 0.5;
              if (box != null) {
                final Offset local = box.globalToLocal(details.offset);
                dropKm = _dxToKm(local.dx, chartWidth);
              } else if (_hoverPreviewKm != null) {
                dropKm = _hoverPreviewKm!;
              }
              _addOrPlaceAssignment(details.data, dropKm);
            },
            builder: (context, candidateData, rejectedData) {
              final bool isDragHovering = candidateData.isNotEmpty;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: widget.enabled
                    ? (details) {
                        if (_selectedRiderId == null) return;
                        final TacticalBoardRiderEntry? rider =
                            _riderById(_selectedRiderId!);
                        if (rider == null) return;
                        final double km =
                            _dxToKm(details.localPosition.dx, chartWidth);
                        _addOrPlaceAssignment(rider, km);
                      }
                    : null,
                child: SizedBox(
                  width: chartWidth,
                  height: chartHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Warstwa 1: Profil wysokościowy trasy
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ElevationProfileChart(
                            stage: widget.stage,
                            height: chartHeight,
                            showHeader: false,
                            enableScrubber: false,
                          ),
                        ),
                      ),

                      // Warstwa 2: Strefy rozkazów taktycznych (zakresy km start -> end)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _TacticalZonesPainter(
                              stage: widget.stage,
                              assignments: _assignments,
                              selectedAssignmentId: _selectedAssignmentId,
                              hoverPreviewKm: _hoverPreviewKm,
                              chartPadding: _chartPadding,
                              totalKm: _totalKm,
                            ),
                          ),
                        ),
                      ),

                      // Warstwa 3: Podgląd punktu upuszczenia podczas przeciągania
                      if (isDragHovering && _hoverPreviewKm != null)
                        _buildDropPreviewTooltip(
                          _hoverPreviewKm!,
                          chartWidth,
                          chartHeight,
                        ),

                      // Warstwa 4: Przeciągane znaczniki kolarzy oraz uchwyty końca zakresu
                      ..._buildInteractiveMarkers(chartWidth, chartHeight),

                      // Pasek podpowiedzi u góry wykresu
                      Positioned(
                        top: 6,
                        left: 10,
                        right: 10,
                        child: IgnorePointer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    isDragHovering
                                        ? 'Upuść kolarza, aby przypisać: ${_activeOrderType.shortLabel}'
                                        : 'Przeciągaj znaczniki poziomo po profilu trasy',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDragHovering
                                          ? AppColors.cyanAccent
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.stage.totalElevationGainM > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Text(
                                    '↑ ${widget.stage.totalElevationGainM.round()} m',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: AppColors.goldAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDropPreviewTooltip(
    double km,
    double chartWidth,
    double chartHeight,
  ) {
    final double dx = _kmToDx(km, chartWidth);
    final double elev = StageProfileSampler.elevationAtKm(widget.stage, km);
    final double grad = StageProfileSampler.gradientAtKm(widget.stage, km);
    final double left = (dx - 64).clamp(6.0, math.max(6.0, chartWidth - 134.0));

    return Positioned(
      left: left,
      top: 32,
      child: IgnorePointer(
        child: Container(
          width: 128,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cyanAccent, width: 1.0),
          ),
          child: Text(
            'km ${km.toStringAsFixed(1)} • ${elev.round()}m • ${grad.toStringAsFixed(1)}%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.cyanAccent,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInteractiveMarkers(double chartWidth, double chartHeight) {
    final List<Widget> widgets = [];
    // Proste rozsuwanie pionowe przy nakładających się markerach
    final List<double> placedStartDx = [];

    for (final assignment in _assignments) {
      final TacticalBoardRiderEntry? rider = _riderById(assignment.riderId);
      if (rider == null) continue;

      final bool isSelected = _selectedAssignmentId == assignment.id;
      final bool isDraggingThis = _draggingAssignmentId == assignment.id;
      final double startDx = _kmToDx(assignment.startKm, chartWidth);
      final double elev =
          StageProfileSampler.elevationAtKm(widget.stage, assignment.startKm);
      final double baseDy = _elevationToDy(elev, chartHeight);

      int overlapTier = 0;
      for (final prevDx in placedStartDx) {
        if ((prevDx - startDx).abs() < 68.0) {
          overlapTier++;
        }
      }
      placedStartDx.add(startDx);

      final double markerTop = (baseDy - 36.0 - (overlapTier % 3) * 28.0)
          .clamp(28.0, math.max(28.0, chartHeight - 58.0));
      final double markerLeft =
          (startDx - 44.0).clamp(4.0, math.max(4.0, chartWidth - 94.0));

      widgets.add(
        Positioned(
          left: markerLeft,
          top: markerTop,
          child: _DraggableChartMarker(
            key: ValueKey('marker_${assignment.id}'),
            rider: rider,
            assignment: assignment,
            isSelected: isSelected,
            isDragging: isDraggingThis && !_draggingEndHandle,
            enabled: widget.enabled,
            onSelect: () {
              setState(() {
                _selectedAssignmentId = assignment.id;
                _selectedRiderId = rider.riderId;
              });
            },
            onDragStart: () {
              setState(() {
                _draggingAssignmentId = assignment.id;
                _draggingEndHandle = false;
                _selectedAssignmentId = assignment.id;
              });
            },
            onDragDeltaDx: (deltaDx) {
              final double plotWidth = math.max(
                1.0,
                chartWidth - _chartPadding.left - _chartPadding.right,
              );
              final double deltaKm = (deltaDx / plotWidth) * _totalKm;
              _updateAssignmentKm(
                assignment.id,
                newStartKm: assignment.startKm + deltaKm,
              );
            },
            onDragEnd: () {
              setState(() {
                _draggingAssignmentId = null;
                _draggingEndHandle = false;
              });
            },
            onNudgeKm: (deltaKm) {
              _updateAssignmentKm(
                assignment.id,
                newStartKm: assignment.startKm + deltaKm,
              );
            },
          ),
        ),
      );

      if (assignment.orderType.supportsRange) {
        final double endKm = assignment.effectiveEndKm;
        final double endDx = _kmToDx(endKm, chartWidth);
        final double endElev =
            StageProfileSampler.elevationAtKm(widget.stage, endKm);
        final double endDy = _elevationToDy(endElev, chartHeight)
            .clamp(34.0, math.max(34.0, chartHeight - 36.0));
        final double handleLeft =
            (endDx - 18.0).clamp(4.0, math.max(4.0, chartWidth - 44.0));

        widgets.add(
          Positioned(
            left: handleLeft,
            top: endDy - 14.0,
            child: _DraggableRangeEndHandle(
              key: ValueKey('end_handle_${assignment.id}'),
              endKm: endKm,
              color: assignment.orderType.color,
              isSelected: isSelected,
              isDragging: isDraggingThis && _draggingEndHandle,
              enabled: widget.enabled,
              onSelect: () {
                setState(() {
                  _selectedAssignmentId = assignment.id;
                });
              },
              onDragStart: () {
                setState(() {
                  _draggingAssignmentId = assignment.id;
                  _draggingEndHandle = true;
                  _selectedAssignmentId = assignment.id;
                });
              },
              onDragDeltaDx: (deltaDx) {
                final double plotWidth = math.max(
                  1.0,
                  chartWidth - _chartPadding.left - _chartPadding.right,
                );
                final double deltaKm = (deltaDx / plotWidth) * _totalKm;
                _updateAssignmentKm(
                  assignment.id,
                  newEndKm: endKm + deltaKm,
                );
              },
              onDragEnd: () {
                setState(() {
                  _draggingAssignmentId = null;
                  _draggingEndHandle = false;
                });
              },
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildSelectedInspector(
    TacticalStageAssignment assignment,
    bool isCompact,
  ) {
    final TacticalBoardRiderEntry? rider = _riderById(assignment.riderId);
    if (rider == null) return const SizedBox.shrink();

    final String description =
        assignment.describeForStage(widget.stage, rider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assignment.orderType.color.withValues(alpha: 0.65),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                assignment.orderType.icon,
                size: 16,
                color: assignment.orderType.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _TacticalIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Usuń rozkaz',
                color: AppColors.crimsonAlert,
                enabled: widget.enabled,
                onTap: () => _removeAssignment(assignment.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _KmStepperControl(
                label: assignment.orderType.supportsRange ? 'Start km' : 'Km',
                valueKm: assignment.startKm,
                enabled: widget.enabled,
                onDecrement: () => _updateAssignmentKm(
                  assignment.id,
                  newStartKm: assignment.startKm - 1.0,
                ),
                onIncrement: () => _updateAssignmentKm(
                  assignment.id,
                  newStartKm: assignment.startKm + 1.0,
                ),
              ),
              if (assignment.orderType.supportsRange)
                _KmStepperControl(
                  label: 'Koniec km',
                  valueKm: assignment.effectiveEndKm,
                  enabled: widget.enabled,
                  onDecrement: () => _updateAssignmentKm(
                    assignment.id,
                    newEndKm: assignment.effectiveEndKm - 1.0,
                  ),
                  onIncrement: () => _updateAssignmentKm(
                    assignment.id,
                    newEndKm: assignment.effectiveEndKm + 1.0,
                  ),
                ),
              ...TacticalBoardOrderType.values.map((type) {
                final bool active = assignment.orderType == type;
                return _OrderTypeChip(
                  orderType: type,
                  isSelected: active,
                  enabled: widget.enabled,
                  compact: true,
                  onTap: () => _changeAssignmentOrderType(assignment.id, type),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList({required bool isCompact}) {
    final List<TacticalStageAssignment> sorted =
        List<TacticalStageAssignment>.from(_assignments)
          ..sort((a, b) => a.startKm.compareTo(b.startKm));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.playlist_add_check_rounded,
              size: 16,
              color: AppColors.goldAccent,
            ),
            const SizedBox(width: 6),
            Text(
              'PLAN TAKTYCZNY ETAPU (${sorted.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'Brak zaplanowanych rozkazów. Przeciągnij kolarza na profil trasy lub użyj „Auto-Taktyka”.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          Column(
            children: sorted.map((assignment) {
              final TacticalBoardRiderEntry? rider =
                  _riderById(assignment.riderId);
              if (rider == null) return const SizedBox.shrink();
              final bool isSelected = _selectedAssignmentId == assignment.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TimelineSummaryRow(
                  assignment: assignment,
                  rider: rider,
                  description:
                      assignment.describeForStage(widget.stage, rider),
                  isSelected: isSelected,
                  enabled: widget.enabled,
                  compact: isCompact,
                  onSelect: () {
                    setState(() {
                      _selectedAssignmentId = assignment.id;
                      _selectedRiderId = rider.riderId;
                    });
                  },
                  onDelete: () => _removeAssignment(assignment.id),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _TacticalZonesPainter extends CustomPainter {
  final RaceStage stage;
  final List<TacticalStageAssignment> assignments;
  final String? selectedAssignmentId;
  final double? hoverPreviewKm;
  final EdgeInsets chartPadding;
  final double totalKm;

  _TacticalZonesPainter({
    required this.stage,
    required this.assignments,
    required this.selectedAssignmentId,
    required this.hoverPreviewKm,
    required this.chartPadding,
    required this.totalKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double plotWidth =
        math.max(1.0, size.width - chartPadding.left - chartPadding.right);
    final double plotHeight =
        math.max(1.0, size.height - chartPadding.top - chartPadding.bottom);

    double kmToX(double km) =>
        chartPadding.left + (km / totalKm).clamp(0.0, 1.0) * plotWidth;

    for (final a in assignments) {
      final bool isSelected = a.id == selectedAssignmentId;
      final Color color = a.orderType.color;
      final double startX = kmToX(a.startKm);

      if (a.orderType.supportsRange) {
        final double endX = kmToX(a.effectiveEndKm);
        final Rect bandRect = Rect.fromLTRB(
          math.min(startX, endX),
          chartPadding.top,
          math.max(startX, endX),
          chartPadding.top + plotHeight,
        );
        final Paint fillPaint = Paint()
          ..color = color.withValues(alpha: isSelected ? 0.24 : 0.12);
        canvas.drawRect(bandRect, fillPaint);

        final Paint borderPaint = Paint()
          ..color = color.withValues(alpha: isSelected ? 0.95 : 0.65)
          ..strokeWidth = isSelected ? 2.0 : 1.2;
        canvas.drawLine(
          Offset(startX, chartPadding.top),
          Offset(startX, chartPadding.top + plotHeight),
          borderPaint,
        );
        canvas.drawLine(
          Offset(endX, chartPadding.top),
          Offset(endX, chartPadding.top + plotHeight),
          borderPaint,
        );
      } else {
        final Paint linePaint = Paint()
          ..color = color.withValues(alpha: isSelected ? 0.95 : 0.72)
          ..strokeWidth = isSelected ? 2.2 : 1.4;
        canvas.drawLine(
          Offset(startX, chartPadding.top),
          Offset(startX, chartPadding.top + plotHeight),
          linePaint,
        );
      }
    }

    if (hoverPreviewKm != null) {
      final double hx = kmToX(hoverPreviewKm!);
      final Paint previewPaint = Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.9)
        ..strokeWidth = 1.6;
      canvas.drawLine(
        Offset(hx, chartPadding.top),
        Offset(hx, chartPadding.top + plotHeight),
        previewPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalZonesPainter oldDelegate) {
    return oldDelegate.assignments != assignments ||
        oldDelegate.selectedAssignmentId != selectedAssignmentId ||
        oldDelegate.hoverPreviewKm != hoverPreviewKm ||
        oldDelegate.totalKm != totalKm;
  }
}

class _DraggableChartMarker extends StatefulWidget {
  final TacticalBoardRiderEntry rider;
  final TacticalStageAssignment assignment;
  final bool isSelected;
  final bool isDragging;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragDeltaDx;
  final VoidCallback onDragEnd;
  final ValueChanged<double> onNudgeKm;

  const _DraggableChartMarker({
    super.key,
    required this.rider,
    required this.assignment,
    required this.isSelected,
    required this.isDragging,
    required this.enabled,
    required this.onSelect,
    required this.onDragStart,
    required this.onDragDeltaDx,
    required this.onDragEnd,
    required this.onNudgeKm,
  });

  @override
  State<_DraggableChartMarker> createState() => _DraggableChartMarkerState();
}

class _DraggableChartMarkerState extends State<_DraggableChartMarker> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color orderColor = widget.assignment.orderType.color;
    final bool highlight =
        widget.isSelected || widget.isDragging || _isHovered || _isFocused;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            _NudgeMarkerIntent(-1.0),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            _NudgeMarkerIntent(1.0),
      },
      actions: <Type, Action<Intent>>{
        _NudgeMarkerIntent: CallbackAction<_NudgeMarkerIntent>(
          onInvoke: (intent) {
            widget.onNudgeKm(intent.deltaKm);
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: !widget.enabled
            ? SystemMouseCursors.forbidden
            : (widget.isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab),
        child: GestureDetector(
          onTap: widget.onSelect,
          onHorizontalDragStart:
              widget.enabled ? (_) => widget.onDragStart() : null,
          onHorizontalDragUpdate: widget.enabled
              ? (details) => widget.onDragDeltaDx(details.delta.dx)
              : null,
          onHorizontalDragEnd:
              widget.enabled ? (_) => widget.onDragEnd() : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.surfaceLight
                  : AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: highlight ? orderColor : AppColors.cardBorder,
                width: highlight ? 1.5 : 1.0,
              ),
              boxShadow: highlight
                  ? [
                      BoxShadow(
                        color: orderColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.assignment.orderType.icon,
                  size: 12,
                  color: orderColor,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.rider.shortName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.assignment.startKm.round()}k',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: orderColor,
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

class _NudgeMarkerIntent extends Intent {
  final double deltaKm;
  const _NudgeMarkerIntent(this.deltaKm);
}

class _DraggableRangeEndHandle extends StatefulWidget {
  final double endKm;
  final Color color;
  final bool isSelected;
  final bool isDragging;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragDeltaDx;
  final VoidCallback onDragEnd;

  const _DraggableRangeEndHandle({
    super.key,
    required this.endKm,
    required this.color,
    required this.isSelected,
    required this.isDragging,
    required this.enabled,
    required this.onSelect,
    required this.onDragStart,
    required this.onDragDeltaDx,
    required this.onDragEnd,
  });

  @override
  State<_DraggableRangeEndHandle> createState() =>
      _DraggableRangeEndHandleState();
}

class _DraggableRangeEndHandleState extends State<_DraggableRangeEndHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlight = widget.isSelected || widget.isDragging || _isHovered;

    return MouseRegion(
      cursor: !widget.enabled
          ? SystemMouseCursors.forbidden
          : (widget.isDragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.resizeLeftRight),
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        onHorizontalDragStart:
            widget.enabled ? (_) => widget.onDragStart() : null,
        onHorizontalDragUpdate: widget.enabled
            ? (details) => widget.onDragDeltaDx(details.delta.dx)
            : null,
        onHorizontalDragEnd: widget.enabled ? (_) => widget.onDragEnd() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: highlight
                ? widget.color.withValues(alpha: 0.24)
                : AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlight
                  ? widget.color
                  : widget.color.withValues(alpha: 0.65),
              width: 1.0,
            ),
          ),
          child: Text(
            '→${widget.endKm.round()}k',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: highlight ? AppColors.textPrimary : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _RiderDockChip extends StatefulWidget {
  final TacticalBoardRiderEntry rider;
  final bool isSelected;
  final int assignmentCount;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  const _RiderDockChip({
    required this.rider,
    required this.isSelected,
    required this.assignmentCount,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_RiderDockChip> createState() => _RiderDockChipState();
}

class _RiderDockChipState extends State<_RiderDockChip> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected || _isPressed;
    final Color borderColor = active
        ? widget.rider.accentColor
        : (_isHovered || _isFocused
            ? AppColors.textSecondary
            : AppColors.cardBorder);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.grab
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: widget.enabled
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onTap();
                }
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 9 : 11,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: active
                  ? widget.rider.accentColor.withValues(alpha: 0.16)
                  : (_isHovered
                      ? AppColors.surfaceLight
                      : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: active ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.rider.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.rider.jerseyNumber}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: widget.rider.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.rider.shortName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.rider.roleLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (widget.assignmentCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.assignmentCount}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.goldAccent,
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
}

class _RiderDragFeedbackBadge extends StatelessWidget {
  final TacticalBoardRiderEntry rider;
  final TacticalBoardOrderType orderType;

  const _RiderDragFeedbackBadge({
    required this.rider,
    required this.orderType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: orderType.color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: orderType.color.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(orderType.icon, size: 14, color: orderType.color),
          const SizedBox(width: 6),
          Text(
            '${rider.shortName} • ${orderType.shortLabel}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeChip extends StatefulWidget {
  final TacticalBoardOrderType orderType;
  final bool isSelected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  const _OrderTypeChip({
    required this.orderType,
    required this.isSelected,
    required this.enabled,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_OrderTypeChip> createState() => _OrderTypeChipState();
}

class _OrderTypeChipState extends State<_OrderTypeChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color color = widget.orderType.color;
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? color.withValues(alpha: 0.2)
                  : (_isHovered
                      ? AppColors.surface
                      : AppColors.background),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? color
                    : (_isFocused ? AppColors.textPrimary : AppColors.cardBorder),
                width: widget.isSelected ? 1.3 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.orderType.icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  widget.compact
                      ? widget.orderType.shortLabel
                      : widget.orderType.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

class _TacticalActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onTap;

  const _TacticalActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_TacticalActionButton> createState() => _TacticalActionButtonState();
}

class _TacticalActionButtonState extends State<_TacticalActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown:
              widget.enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: widget.enabled
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onTap();
                }
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _isPressed
                  ? widget.accentColor.withValues(alpha: 0.24)
                  : (_isHovered
                      ? widget.accentColor.withValues(alpha: 0.14)
                      : AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? widget.accentColor
                    : widget.accentColor.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: widget.accentColor),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

class _KmStepperControl extends StatelessWidget {
  final String label;
  final double valueKm;
  final bool enabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _KmStepperControl({
    required this.label,
    required this.valueKm,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          _TacticalIconButton(
            icon: Icons.remove_rounded,
            tooltip: '-1 km',
            color: AppColors.textPrimary,
            enabled: enabled,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${valueKm.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.goldAccent,
              ),
            ),
          ),
          _TacticalIconButton(
            icon: Icons.add_rounded,
            tooltip: '+1 km',
            color: AppColors.textPrimary,
            enabled: enabled,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _TacticalIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _TacticalIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_TacticalIconButton> createState() => _TacticalIconButtonState();
}

class _TacticalIconButtonState extends State<_TacticalIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 15, color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _TimelineSummaryRow extends StatefulWidget {
  final TacticalStageAssignment assignment;
  final TacticalBoardRiderEntry rider;
  final String description;
  final bool isSelected;
  final bool enabled;
  final bool compact;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _TimelineSummaryRow({
    required this.assignment,
    required this.rider,
    required this.description,
    required this.isSelected,
    required this.enabled,
    required this.compact,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  State<_TimelineSummaryRow> createState() => _TimelineSummaryRowState();
}

class _TimelineSummaryRowState extends State<_TimelineSummaryRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color color = widget.assignment.orderType.color;
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? color.withValues(alpha: 0.12)
                  : (_hovered ? AppColors.surfaceLight : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isSelected
                    ? color
                    : (_focused ? AppColors.textPrimary : AppColors.cardBorder),
                width: widget.isSelected ? 1.3 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(widget.assignment.orderType.icon, size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _TacticalIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Usuń rozkaz',
                  color: AppColors.textSecondary,
                  enabled: widget.enabled,
                  onTap: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
