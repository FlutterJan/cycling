import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import 'rider_effort_slider_control.dart';

/// Preferowana dłoń obsługująca tryb jednoręczny (Strefa Kciuka).
enum ThumbHandedness {
  rightHanded('Prawa dłoń', Icons.pan_tool_alt_rounded),
  leftHanded('Lewa dłoń', Icons.back_hand_rounded);

  final String label;
  final IconData icon;

  const ThumbHandedness(this.label, this.icon);
}

/// Zakładki dolnej strefy kciuka na bardzo wąskich ekranach.
enum ThumbZoneSection {
  tactics('Taktyka', Icons.flash_on_rounded),
  power('Moc & Aero', Icons.bolt_rounded);

  final String label;
  final IconData icon;

  const ThumbZoneSection(this.label, this.icon);
}

/// Skondensowane dane telemetrii etapu wyświetlane w chowanym górnym pasku.
class MobileThumbStageTelemetry {
  final String stageTitle;
  final int stageNumber;
  final double remainingKm;
  final double totalKm;
  final double currentSpeedKmh;
  final double gradientPercent;
  final double windSpeedKmh;
  final String leaderGapLabel;
  final String elapsedTimeLabel;
  final SimulationTimeSpeed timeSpeed;
  final bool isPaused;

  const MobileThumbStageTelemetry({
    required this.stageTitle,
    required this.stageNumber,
    required this.remainingKm,
    required this.totalKm,
    required this.currentSpeedKmh,
    required this.gradientPercent,
    required this.windSpeedKmh,
    required this.leaderGapLabel,
    required this.elapsedTimeLabel,
    this.timeSpeed = SimulationTimeSpeed.x1,
    this.isPaused = false,
  });

  MobileThumbStageTelemetry copyWith({
    String? stageTitle,
    int? stageNumber,
    double? remainingKm,
    double? totalKm,
    double? currentSpeedKmh,
    double? gradientPercent,
    double? windSpeedKmh,
    String? leaderGapLabel,
    String? elapsedTimeLabel,
    SimulationTimeSpeed? timeSpeed,
    bool? isPaused,
  }) {
    return MobileThumbStageTelemetry(
      stageTitle: stageTitle ?? this.stageTitle,
      stageNumber: stageNumber ?? this.stageNumber,
      remainingKm: remainingKm ?? this.remainingKm,
      totalKm: totalKm ?? this.totalKm,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      gradientPercent: gradientPercent ?? this.gradientPercent,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      leaderGapLabel: leaderGapLabel ?? this.leaderGapLabel,
      elapsedTimeLabel: elapsedTimeLabel ?? this.elapsedTimeLabel,
      timeSpeed: timeSpeed ?? this.timeSpeed,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

/// Stan pojedynczego kolarza w mobilnym trybie jednoręcznym.
class MobileThumbRiderSummary {
  final String id;
  final String name;
  final String shortName;
  final int bibNumber;
  final String roleLabel;
  final int ftpWatts;
  final double weightKg;
  final int currentWatts;
  final int heartRateBpm;
  final double wPrimePercent;
  final double glycogenPercent;
  final double hydrationPercent;
  final double effortPercent;
  final TacticalOrder activeOrder;
  final RiderAeroPosition aeroPosition;
  final bool isInBreakaway;
  final bool isProtected;
  final int gelsRemaining;
  final int bidonsRemaining;

  const MobileThumbRiderSummary({
    required this.id,
    required this.name,
    required this.shortName,
    required this.bibNumber,
    required this.roleLabel,
    required this.ftpWatts,
    required this.weightKg,
    required this.currentWatts,
    required this.heartRateBpm,
    required this.wPrimePercent,
    required this.glycogenPercent,
    required this.hydrationPercent,
    this.effortPercent = 78.0,
    this.activeOrder = TacticalOrder.holdPosition,
    this.aeroPosition = RiderAeroPosition.standard,
    this.isInBreakaway = false,
    this.isProtected = false,
    this.gelsRemaining = 2,
    this.bidonsRemaining = 2,
  });

  double get wattsPerKg {
    if (weightKg <= 0) return 0.0;
    return currentWatts / weightKg;
  }

  int get targetWatts => (ftpWatts * (effortPercent / 100.0)).round();

  MobileThumbRiderSummary copyWith({
    String? id,
    String? name,
    String? shortName,
    int? bibNumber,
    String? roleLabel,
    int? ftpWatts,
    double? weightKg,
    int? currentWatts,
    int? heartRateBpm,
    double? wPrimePercent,
    double? glycogenPercent,
    double? hydrationPercent,
    double? effortPercent,
    TacticalOrder? activeOrder,
    RiderAeroPosition? aeroPosition,
    bool? isInBreakaway,
    bool? isProtected,
    int? gelsRemaining,
    int? bidonsRemaining,
  }) {
    return MobileThumbRiderSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      bibNumber: bibNumber ?? this.bibNumber,
      roleLabel: roleLabel ?? this.roleLabel,
      ftpWatts: ftpWatts ?? this.ftpWatts,
      weightKg: weightKg ?? this.weightKg,
      currentWatts: currentWatts ?? this.currentWatts,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      wPrimePercent: wPrimePercent ?? this.wPrimePercent,
      glycogenPercent: glycogenPercent ?? this.glycogenPercent,
      hydrationPercent: hydrationPercent ?? this.hydrationPercent,
      effortPercent: effortPercent ?? this.effortPercent,
      activeOrder: activeOrder ?? this.activeOrder,
      aeroPosition: aeroPosition ?? this.aeroPosition,
      isInBreakaway: isInBreakaway ?? this.isInBreakaway,
      isProtected: isProtected ?? this.isProtected,
      gelsRemaining: gelsRemaining ?? this.gelsRemaining,
      bidonsRemaining: bidonsRemaining ?? this.bidonsRemaining,
    );
  }
}

/// Dedykowany tryb ergonomii mobilnej (iOS/Android) dla obsługi jedną ręką.
///
/// Przenosi wszystkie kluczowe przyciski taktyczne, wybór kolarzy, suwak mocy
/// oraz kontrolę tempa symulacji do dolnej strefy zasięgu kciuka (`Thumb Zone`),
/// pozostawiając chowany górny pasek telemetrii wyścigu.
class MobileOneHandedThumbHudMode extends StatefulWidget {
  final MobileThumbStageTelemetry? stageTelemetry;
  final List<MobileThumbRiderSummary>? riders;
  final String? selectedRiderId;
  final ThumbHandedness initialHandedness;
  final bool initiallyTelemetryCollapsed;
  final bool isEnabled;
  final Widget? viewportChild;
  final ValueChanged<String>? onRiderSelected;
  final void Function(String riderId, TacticalOrder order)? onOrderIssued;
  final void Function(String riderId, double effortPercent)? onEffortChanged;
  final void Function(String riderId, RiderAeroPosition position)?
      onAeroPositionChanged;
  final ValueChanged<String>? onFeedGel;
  final ValueChanged<String>? onFeedBidon;
  final ValueChanged<SimulationTimeSpeed>? onSpeedSelected;
  final VoidCallback? onTogglePause;
  final ValueChanged<ThumbHandedness>? onHandednessChanged;
  final ValueChanged<bool>? onTelemetryCollapsedChanged;

  const MobileOneHandedThumbHudMode({
    super.key,
    this.stageTelemetry,
    this.riders,
    this.selectedRiderId,
    this.initialHandedness = ThumbHandedness.rightHanded,
    this.initiallyTelemetryCollapsed = false,
    this.isEnabled = true,
    this.viewportChild,
    this.onRiderSelected,
    this.onOrderIssued,
    this.onEffortChanged,
    this.onAeroPositionChanged,
    this.onFeedGel,
    this.onFeedBidon,
    this.onSpeedSelected,
    this.onTogglePause,
    this.onHandednessChanged,
    this.onTelemetryCollapsedChanged,
  });

  static List<MobileThumbRiderSummary> buildDefaultDemoRiders() {
    return const [
      MobileThumbRiderSummary(
        id: 'r1',
        name: 'Kacper Majewski',
        shortName: 'K. Majewski',
        bibNumber: 11,
        roleLabel: 'Lider GC',
        ftpWatts: 415,
        weightKg: 62.5,
        currentWatts: 365,
        heartRateBpm: 168,
        wPrimePercent: 84.0,
        glycogenPercent: 78.0,
        hydrationPercent: 82.0,
        effortPercent: 88.0,
        activeOrder: TacticalOrder.protectLeader,
        aeroPosition: RiderAeroPosition.standard,
        isProtected: true,
        gelsRemaining: 3,
        bidonsRemaining: 2,
      ),
      MobileThumbRiderSummary(
        id: 'r2',
        name: 'Michał Kowalczyk',
        shortName: 'M. Kowalczyk',
        bibNumber: 12,
        roleLabel: 'Góral',
        ftpWatts: 395,
        weightKg: 61.0,
        currentWatts: 340,
        heartRateBpm: 164,
        wPrimePercent: 76.0,
        glycogenPercent: 72.0,
        hydrationPercent: 74.0,
        effortPercent: 85.0,
        activeOrder: TacticalOrder.pullGroup,
        aeroPosition: RiderAeroPosition.standard,
        gelsRemaining: 2,
        bidonsRemaining: 1,
      ),
      MobileThumbRiderSummary(
        id: 'r3',
        name: 'Lucas Moreau',
        shortName: 'L. Moreau',
        bibNumber: 13,
        roleLabel: 'Sprinter',
        ftpWatts: 410,
        weightKg: 74.0,
        currentWatts: 260,
        heartRateBpm: 142,
        wPrimePercent: 95.0,
        glycogenPercent: 88.0,
        hydrationPercent: 86.0,
        effortPercent: 65.0,
        activeOrder: TacticalOrder.saveEnergy,
        aeroPosition: RiderAeroPosition.pelotonShelter,
        gelsRemaining: 3,
        bidonsRemaining: 2,
      ),
      MobileThumbRiderSummary(
        id: 'r4',
        name: 'Janek Nowak',
        shortName: 'J. Nowak',
        bibNumber: 14,
        roleLabel: 'Pomocnik',
        ftpWatts: 380,
        weightKg: 68.0,
        currentWatts: 310,
        heartRateBpm: 158,
        wPrimePercent: 62.0,
        glycogenPercent: 65.0,
        hydrationPercent: 68.0,
        effortPercent: 80.0,
        activeOrder: TacticalOrder.holdPosition,
        aeroPosition: RiderAeroPosition.standard,
        isInBreakaway: true,
        gelsRemaining: 1,
        bidonsRemaining: 1,
      ),
    ];
  }

  static MobileThumbStageTelemetry buildDefaultDemoTelemetry() {
    return const MobileThumbStageTelemetry(
      stageTitle: 'Tour de France — Col du Galibier',
      stageNumber: 14,
      remainingKm: 24.6,
      totalKm: 168.5,
      currentSpeedKmh: 28.4,
      gradientPercent: 8.2,
      windSpeedKmh: 16.0,
      leaderGapLabel: '+0:18',
      elapsedTimeLabel: '03:54:12',
      timeSpeed: SimulationTimeSpeed.x1,
      isPaused: false,
    );
  }

  @override
  State<MobileOneHandedThumbHudMode> createState() =>
      _MobileOneHandedThumbHudModeState();
}

class _MobileOneHandedThumbHudModeState
    extends State<MobileOneHandedThumbHudMode> {
  late ThumbHandedness _handedness;
  late bool _isTelemetryCollapsed;
  late List<MobileThumbRiderSummary> _riders;
  late MobileThumbStageTelemetry _telemetry;
  late String _selectedRiderId;
  ThumbZoneSection _activeSection = ThumbZoneSection.tactics;

  @override
  void initState() {
    super.initState();
    _handedness = widget.initialHandedness;
    _isTelemetryCollapsed = widget.initiallyTelemetryCollapsed;
    _riders = List<MobileThumbRiderSummary>.from(
      widget.riders ?? MobileOneHandedThumbHudMode.buildDefaultDemoRiders(),
    );
    _telemetry = widget.stageTelemetry ??
        MobileOneHandedThumbHudMode.buildDefaultDemoTelemetry();
    _selectedRiderId = widget.selectedRiderId ??
        (_riders.isNotEmpty ? _riders.first.id : '');
  }

  @override
  void didUpdateWidget(covariant MobileOneHandedThumbHudMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riders != null && widget.riders != oldWidget.riders) {
      _riders = List<MobileThumbRiderSummary>.from(widget.riders!);
      if (_riders.isNotEmpty &&
          !_riders.any((r) => r.id == _selectedRiderId)) {
        _selectedRiderId = _riders.first.id;
      }
    }
    if (widget.stageTelemetry != null &&
        widget.stageTelemetry != oldWidget.stageTelemetry) {
      _telemetry = widget.stageTelemetry!;
    }
    if (widget.selectedRiderId != null &&
        widget.selectedRiderId != oldWidget.selectedRiderId) {
      _selectedRiderId = widget.selectedRiderId!;
    }
  }

  MobileThumbRiderSummary? get _selectedRider {
    if (_riders.isEmpty) return null;
    for (final rider in _riders) {
      if (rider.id == _selectedRiderId) return rider;
    }
    return _riders.first;
  }

  void _selectRider(String riderId) {
    if (!widget.isEnabled) return;
    setState(() {
      _selectedRiderId = riderId;
    });
    widget.onRiderSelected?.call(riderId);
  }

  void _issueOrder(TacticalOrder order) {
    final rider = _selectedRider;
    if (!widget.isEnabled || rider == null) return;
    final double suggestedEffort = _suggestedEffortForOrder(order);
    setState(() {
      _riders = _riders
          .map((r) => r.id == rider.id
              ? r.copyWith(
                  activeOrder: order,
                  effortPercent: suggestedEffort,
                  currentWatts:
                      (r.ftpWatts * (suggestedEffort / 100.0)).round(),
                )
              : r)
          .toList();
    });
    widget.onOrderIssued?.call(rider.id, order);
    widget.onEffortChanged?.call(rider.id, suggestedEffort);
  }

  double _suggestedEffortForOrder(TacticalOrder order) {
    switch (order) {
      case TacticalOrder.attack:
        return 118.0;
      case TacticalOrder.pullGroup:
        return 96.0;
      case TacticalOrder.protectLeader:
        return 84.0;
      case TacticalOrder.followWheels:
        return 88.0;
      case TacticalOrder.holdPosition:
        return 76.0;
      case TacticalOrder.fetchBidonsFromCar:
        return 62.0;
      case TacticalOrder.saveEnergy:
        return 56.0;
    }
  }

  void _updateEffort(double effortPercent) {
    final rider = _selectedRider;
    if (!widget.isEnabled || rider == null) return;
    final clamped = effortPercent.clamp(40.0, 130.0);
    setState(() {
      _riders = _riders
          .map((r) => r.id == rider.id
              ? r.copyWith(
                  effortPercent: clamped,
                  currentWatts: (r.ftpWatts * (clamped / 100.0)).round(),
                )
              : r)
          .toList();
    });
    widget.onEffortChanged?.call(rider.id, clamped);
  }

  void _updateAeroPosition(RiderAeroPosition position) {
    final rider = _selectedRider;
    if (!widget.isEnabled || rider == null) return;
    setState(() {
      _riders = _riders
          .map((r) => r.id == rider.id ? r.copyWith(aeroPosition: position) : r)
          .toList();
    });
    widget.onAeroPositionChanged?.call(rider.id, position);
  }

  void _consumeGel() {
    final rider = _selectedRider;
    if (!widget.isEnabled || rider == null || rider.gelsRemaining <= 0) return;
    setState(() {
      _riders = _riders
          .map((r) => r.id == rider.id
              ? r.copyWith(
                  gelsRemaining: r.gelsRemaining - 1,
                  glycogenPercent: (r.glycogenPercent + 14.0).clamp(0.0, 100.0),
                )
              : r)
          .toList();
    });
    widget.onFeedGel?.call(rider.id);
  }

  void _consumeBidon() {
    final rider = _selectedRider;
    if (!widget.isEnabled || rider == null || rider.bidonsRemaining <= 0) {
      return;
    }
    setState(() {
      _riders = _riders
          .map((r) => r.id == rider.id
              ? r.copyWith(
                  bidonsRemaining: r.bidonsRemaining - 1,
                  hydrationPercent:
                      (r.hydrationPercent + 18.0).clamp(0.0, 100.0),
                )
              : r)
          .toList();
    });
    widget.onFeedBidon?.call(rider.id);
  }

  void _togglePause() {
    if (!widget.isEnabled) return;
    setState(() {
      _telemetry = _telemetry.copyWith(isPaused: !_telemetry.isPaused);
    });
    widget.onTogglePause?.call();
  }

  void _selectTimeSpeed(SimulationTimeSpeed speed) {
    if (!widget.isEnabled) return;
    setState(() {
      _telemetry = _telemetry.copyWith(timeSpeed: speed, isPaused: false);
    });
    widget.onSpeedSelected?.call(speed);
  }

  void _toggleHandedness() {
    if (!widget.isEnabled) return;
    final next = _handedness == ThumbHandedness.rightHanded
        ? ThumbHandedness.leftHanded
        : ThumbHandedness.rightHanded;
    setState(() {
      _handedness = next;
    });
    widget.onHandednessChanged?.call(next);
  }

  void _toggleTelemetryCollapsed() {
    if (!widget.isEnabled) return;
    final next = !_isTelemetryCollapsed;
    setState(() {
      _isTelemetryCollapsed = next;
    });
    widget.onTelemetryCollapsedChanged?.call(next);
  }

  int _powerZoneFromEffort(double effortPercent) {
    if (effortPercent < 55) return 1;
    if (effortPercent < 76) return 2;
    if (effortPercent < 91) return 3;
    if (effortPercent < 106) return 4;
    if (effortPercent < 121) return 5;
    if (effortPercent < 128) return 6;
    return 7;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 390.0;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 844.0;
        final bool isCompactMobile = width < 600;
        final bool isShortViewport = height < 680;
        final double dockMaxWidth = isCompactMobile ? width : 480.0;
        final Alignment dockAlignment = isCompactMobile
            ? Alignment.bottomCenter
            : (_handedness == ThumbHandedness.rightHanded
                ? Alignment.bottomRight
                : Alignment.bottomLeft);

        return Container(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.viewportChild ??
                    _DefaultRaceViewportBackdrop(
                      telemetry: _telemetry,
                      selectedRider: _selectedRider,
                    ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactMobile ? 10 : 16,
                      vertical: 8,
                    ),
                    child: _CollapsibleTopTelemetryBar(
                      telemetry: _telemetry,
                      isCollapsed: _isTelemetryCollapsed,
                      isEnabled: widget.isEnabled,
                      isCompact: isCompactMobile,
                      onToggleCollapse: _toggleTelemetryCollapsed,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: dockAlignment,
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: dockMaxWidth,
                      maxHeight: isShortViewport ? height * 0.68 : height * 0.56,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isCompactMobile ? 8 : 16,
                        0,
                        isCompactMobile ? 8 : 16,
                        isCompactMobile ? 8 : 14,
                      ),
                      child: _buildThumbZoneDock(
                        isCompactMobile: isCompactMobile,
                        isShortViewport: isShortViewport,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbZoneDock({
    required bool isCompactMobile,
    required bool isShortViewport,
  }) {
    final rider = _selectedRider;
    final bool isLeft = _handedness == ThumbHandedness.leftHanded;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isCompactMobile ? 10 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildThumbHeaderRow(rider, isLeft: isLeft),
            const SizedBox(height: 8),
            _buildRiderSelectorStrip(),
            const SizedBox(height: 8),
            if (isShortViewport) ...[
              _buildSectionSwitcher(),
              const SizedBox(height: 8),
              if (_activeSection == ThumbZoneSection.tactics)
                _buildTacticalButtonsGrid(rider, isLeft: isLeft)
              else
                _buildPowerAndAeroPanel(rider),
            ] else ...[
              _buildPowerAndAeroPanel(rider),
              const SizedBox(height: 8),
              _buildTacticalButtonsGrid(rider, isLeft: isLeft),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbHeaderRow(
    MobileThumbRiderSummary? rider, {
    required bool isLeft,
  }) {
    final Widget handednessChip = _ThumbActionChip(
      key: const Key('thumb_handedness_toggle'),
      icon: _handedness.icon,
      label: _handedness == ThumbHandedness.rightHanded ? 'Prawa' : 'Lewa',
      tooltip: 'Przełącz dłoń: ${_handedness.label}',
      isSelected: false,
      isEnabled: widget.isEnabled,
      onTap: _toggleHandedness,
    );

    final Widget pauseChip = _ThumbActionChip(
      key: const Key('thumb_pause_toggle'),
      icon: _telemetry.isPaused
          ? Icons.play_arrow_rounded
          : Icons.pause_rounded,
      label: _telemetry.isPaused ? 'Wznów' : 'Pauza',
      tooltip: _telemetry.isPaused ? 'Wznów symulację' : 'Pauza symulacji',
      isSelected: _telemetry.isPaused,
      accentColor: AppColors.goldAccent,
      isEnabled: widget.isEnabled,
      onTap: _togglePause,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (!isLeft) ...[
              Expanded(child: _buildSelectedRiderTelemetrySummary(rider)),
              const SizedBox(width: 6),
              handednessChip,
            ] else ...[
              handednessChip,
              const SizedBox(width: 6),
              Expanded(child: _buildSelectedRiderTelemetrySummary(rider)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (!isLeft) ...[
              if (rider != null)
                Expanded(
                  child: Text(
                    "W' ${rider.wPrimePercent.round()}% • Glik. ${rider.glycogenPercent.round()}%",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 6),
              pauseChip,
              const SizedBox(width: 6),
              _buildSpeedPillStrip(),
            ] else ...[
              _buildSpeedPillStrip(),
              const SizedBox(width: 6),
              pauseChip,
              const SizedBox(width: 6),
              if (rider != null)
                Expanded(
                  child: Text(
                    "W' ${rider.wPrimePercent.round()}% • Glik. ${rider.glycogenPercent.round()}%",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedRiderTelemetrySummary(MobileThumbRiderSummary? rider) {
    if (rider == null) {
      return const Text(
        'Brak aktywnych kolarzy',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              '#${rider.bibNumber}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${rider.currentWatts}W • ${rider.heartRateBpm} bpm',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedPillStrip() {
    const speeds = [
      SimulationTimeSpeed.x1,
      SimulationTimeSpeed.x2,
      SimulationTimeSpeed.x4,
      SimulationTimeSpeed.x8,
    ];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: speeds.map((speed) {
          final bool active =
              !_telemetry.isPaused && _telemetry.timeSpeed == speed;
          return _ThumbSpeedPill(
            key: Key('thumb_speed_${speed.name}'),
            label: '${speed.multiplier.toInt()}x',
            isSelected: active,
            isEnabled: widget.isEnabled,
            onTap: () => _selectTimeSpeed(speed),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRiderSelectorStrip() {
    if (_riders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'Brak kolarzy w składzie etapu.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _riders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final rider = _riders[index];
          final bool isSelected = rider.id == _selectedRider?.id;
          return _ThumbRiderChip(
            key: Key('thumb_rider_${rider.id}'),
            rider: rider,
            isSelected: isSelected,
            isEnabled: widget.isEnabled,
            onTap: () => _selectRider(rider.id),
          );
        },
      ),
    );
  }

  Widget _buildSectionSwitcher() {
    return Row(
      children: ThumbZoneSection.values.map((section) {
        final bool isSelected = _activeSection == section;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: section == ThumbZoneSection.tactics ? 6 : 0,
            ),
            child: _ThumbActionChip(
              key: Key('thumb_section_${section.name}'),
              icon: section.icon,
              label: section.label,
              isSelected: isSelected,
              accentColor: AppColors.goldAccent,
              isEnabled: widget.isEnabled,
              onTap: () => setState(() => _activeSection = section),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPowerAndAeroPanel(MobileThumbRiderSummary? rider) {
    final double effort = rider?.effortPercent ?? 75.0;
    final int zone = _powerZoneFromEffort(effort);
    final Color zoneColor = AppColors.getPowerZoneColor(zone);
    final int targetWatts = rider?.targetWatts ?? 300;
    final double wKg = rider != null && rider.weightKg > 0
        ? targetWatts / rider.weightKg
        : 4.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: zoneColor, width: 1.0),
                ),
                child: Text(
                  'Z$zone • ${effort.round()}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: zoneColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$targetWatts W (${wKg.toStringAsFixed(1)} W/kg)',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ThumbStepButton(
                key: const Key('thumb_power_minus'),
                icon: Icons.remove_rounded,
                tooltip: '-5% mocy',
                isEnabled: widget.isEnabled && rider != null && effort > 40.0,
                onTap: () => _updateEffort(effort - 5.0),
              ),
              const SizedBox(width: 4),
              _ThumbStepButton(
                key: const Key('thumb_power_plus'),
                icon: Icons.add_rounded,
                tooltip: '+5% mocy',
                isEnabled: widget.isEnabled && rider != null && effort < 130.0,
                onTap: () => _updateEffort(effort + 5.0),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: zoneColor,
              inactiveTrackColor: AppColors.background,
              thumbColor: AppColors.goldAccent,
              overlayColor: AppColors.goldAccent.withValues(alpha: 0.2),
              trackHeight: 7.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            ),
            child: Slider(
              key: const Key('thumb_effort_slider'),
              value: effort.clamp(40.0, 130.0),
              min: 40.0,
              max: 130.0,
              divisions: 18,
              onChanged: widget.isEnabled && rider != null ? _updateEffort : null,
            ),
          ),
          Row(
            children: RiderAeroPosition.values.map((pos) {
              final bool selected = rider?.aeroPosition == pos;
              final String shortText = switch (pos) {
                RiderAeroPosition.standard => 'Standard',
                RiderAeroPosition.aggressiveAero => 'Aero (-14%)',
                RiderAeroPosition.pelotonShelter => 'Peleton',
              };
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: pos == RiderAeroPosition.pelotonShelter ? 0 : 6,
                  ),
                  child: _ThumbActionChip(
                    key: Key('thumb_aero_${pos.name}'),
                    icon: pos.icon,
                    label: shortText,
                    isSelected: selected,
                    accentColor: AppColors.accentBlue,
                    isEnabled: widget.isEnabled && rider != null,
                    onTap: () => _updateAeroPosition(pos),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalButtonsGrid(
    MobileThumbRiderSummary? rider, {
    required bool isLeft,
  }) {
    final List<({TacticalOrder order, String label, IconData icon, Color accent})>
        primaryOrders = [
      (
        order: TacticalOrder.attack,
        label: 'Atakuj',
        icon: Icons.rocket_launch_rounded,
        accent: AppColors.crimsonAlert,
      ),
      (
        order: TacticalOrder.pullGroup,
        label: 'Zmiany',
        icon: Icons.speed_rounded,
        accent: AppColors.primaryAccent,
      ),
      (
        order: TacticalOrder.protectLeader,
        label: 'Chroń',
        icon: Icons.shield_rounded,
        accent: AppColors.goldAccent,
      ),
      (
        order: TacticalOrder.followWheels,
        label: 'Koło',
        icon: Icons.track_changes_rounded,
        accent: AppColors.accentBlue,
      ),
    ];

    final List<({TacticalOrder order, String label, IconData icon, Color accent})>
        secondaryOrders = [
      (
        order: TacticalOrder.holdPosition,
        label: 'Utrzymuj',
        icon: Icons.pause_circle_outline_rounded,
        accent: AppColors.textSecondary,
      ),
      (
        order: TacticalOrder.saveEnergy,
        label: 'Oszczędzaj',
        icon: Icons.battery_charging_full_rounded,
        accent: AppColors.statusSuccess,
      ),
      (
        order: TacticalOrder.fetchBidonsFromCar,
        label: 'Wóz',
        icon: Icons.directions_car_rounded,
        accent: AppColors.amberWarning,
      ),
    ];

    final orderedPrimary = isLeft ? primaryOrders.reversed.toList() : primaryOrders;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: orderedPrimary.map((item) {
            final bool isActive = rider?.activeOrder == item.order;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: item == orderedPrimary.last ? 0 : 6,
                ),
                child: _ThumbTacticalButton(
                  key: Key('thumb_order_${item.order.name}'),
                  icon: item.icon,
                  label: item.label,
                  accentColor: item.accent,
                  isSelected: isActive,
                  isEnabled: widget.isEnabled && rider != null,
                  onTap: () => _issueOrder(item.order),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ...secondaryOrders.map((item) {
              final bool isActive = rider?.activeOrder == item.order;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _ThumbActionChip(
                    key: Key('thumb_order_${item.order.name}'),
                    icon: item.icon,
                    label: item.label,
                    isSelected: isActive,
                    accentColor: item.accent,
                    isEnabled: widget.isEnabled && rider != null,
                    onTap: () => _issueOrder(item.order),
                  ),
                ),
              );
            }),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _ThumbActionChip(
                  key: const Key('thumb_feed_gel'),
                  icon: Icons.bolt_rounded,
                  label: 'Żel (${rider?.gelsRemaining ?? 0})',
                  isSelected: false,
                  accentColor: AppColors.amberWarning,
                  isEnabled: widget.isEnabled &&
                      rider != null &&
                      rider.gelsRemaining > 0,
                  onTap: _consumeGel,
                ),
              ),
            ),
            Expanded(
              child: _ThumbActionChip(
                key: const Key('thumb_feed_bidon'),
                icon: Icons.water_drop_rounded,
                label: 'Bidon (${rider?.bidonsRemaining ?? 0})',
                isSelected: false,
                accentColor: AppColors.cyanAccent,
                isEnabled: widget.isEnabled &&
                    rider != null &&
                    rider.bidonsRemaining > 0,
                onTap: _consumeBidon,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CollapsibleTopTelemetryBar extends StatelessWidget {
  final MobileThumbStageTelemetry telemetry;
  final bool isCollapsed;
  final bool isEnabled;
  final bool isCompact;
  final VoidCallback onToggleCollapse;

  const _CollapsibleTopTelemetryBar({
    required this.telemetry,
    required this.isCollapsed,
    required this.isEnabled,
    required this.isCompact,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCollapsed ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: Text(
                  'ETAP ${telemetry.stageNumber}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldAccent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCollapsed
                      ? '${telemetry.remainingKm.toStringAsFixed(1)} km • ${telemetry.gradientPercent.toStringAsFixed(1)}% • ${telemetry.currentSpeedKmh.toStringAsFixed(1)} km/h'
                      : telemetry.stageTitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ThumbStepButton(
                key: const Key('thumb_telemetry_collapse_btn'),
                icon: isCollapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                tooltip: isCollapsed
                    ? 'Rozwiń pasek telemetrii'
                    : 'Zwiń pasek telemetrii',
                isEnabled: isEnabled,
                onTap: onToggleCollapse,
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 240),
            crossFadeState: isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _TelemetryMetricCell(
                      label: 'Do mety',
                      value: '${telemetry.remainingKm.toStringAsFixed(1)} km',
                      accent: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: _TelemetryMetricCell(
                      label: 'Nachylenie',
                      value: '${telemetry.gradientPercent.toStringAsFixed(1)}%',
                      accent: telemetry.gradientPercent >= 7.0
                          ? AppColors.amberWarning
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: _TelemetryMetricCell(
                      label: 'Prędkość',
                      value:
                          '${telemetry.currentSpeedKmh.toStringAsFixed(1)} km/h',
                      accent: AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: _TelemetryMetricCell(
                      label: 'Strata',
                      value: telemetry.leaderGapLabel,
                      accent: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryMetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _TelemetryMetricCell({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _ThumbRiderChip extends StatefulWidget {
  final MobileThumbRiderSummary rider;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ThumbRiderChip({
    super.key,
    required this.rider,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ThumbRiderChip> createState() => _ThumbRiderChipState();
}

class _ThumbRiderChipState extends State<_ThumbRiderChip> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.goldAccent
            : _isHovered
                ? AppColors.primaryAccent
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.isEnabled) widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: widget.isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.isEnabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.isEnabled ? 1.0 : 0.42,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _isPressed ? 0.96 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 118,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primaryAccent.withValues(alpha: 0.24)
                      : _isHovered
                          ? AppColors.surfaceLight
                          : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected || _isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.rider.shortName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.isSelected
                                  ? AppColors.goldAccent
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${widget.rider.currentWatts}W',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.rider.wPrimePercent / 100.0)
                            .clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.rider.wPrimePercent < 25
                              ? AppColors.crimsonAlert
                              : AppColors.statusSuccess,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbTacticalButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ThumbTacticalButton({
    super.key,
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ThumbTacticalButton> createState() => _ThumbTacticalButtonState();
}

class _ThumbTacticalButtonState extends State<_ThumbTacticalButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? widget.accentColor
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.7)
                : AppColors.cardBorder;

    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.isEnabled) widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: widget.isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.isEnabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.isEnabled ? 1.0 : 0.42,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _isPressed ? 0.95 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.accentColor.withValues(alpha: 0.22)
                      : _isHovered
                          ? AppColors.surfaceLight
                          : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected || _isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: 20,
                      color: widget.isSelected
                          ? widget.accentColor
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isSelected
                            ? widget.accentColor
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final bool isSelected;
  final bool isEnabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThumbActionChip({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    required this.isSelected,
    required this.isEnabled,
    this.accentColor = AppColors.primaryAccent,
    required this.onTap,
  });

  @override
  State<_ThumbActionChip> createState() => _ThumbActionChipState();
}

class _ThumbActionChipState extends State<_ThumbActionChip> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? widget.accentColor
            : _isHovered
                ? widget.accentColor.withValues(alpha: 0.7)
                : AppColors.cardBorder;

    final Widget chip = FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.isEnabled) widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: widget.isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.isEnabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.isEnabled ? 1.0 : 0.42,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: _isPressed ? 0.96 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.accentColor.withValues(alpha: 0.22)
                      : _isHovered
                          ? AppColors.surfaceLight
                          : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: borderColor,
                    width: widget.isSelected || _isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      size: 14,
                      color: widget.isSelected
                          ? widget.accentColor
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: widget.isSelected
                              ? widget.accentColor
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: chip);
    }
    return chip;
  }
}

class _ThumbSpeedPill extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ThumbSpeedPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ThumbSpeedPill> createState() => _ThumbSpeedPillState();
}

class _ThumbSpeedPillState extends State<_ThumbSpeedPill> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.isEnabled,
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      child: MouseRegion(
        cursor: widget.isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: widget.isEnabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primaryAccent
                  : _isHovered
                      ? AppColors.surfaceLight
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _isFocused
                  ? Border.all(color: AppColors.goldAccent, width: 1.0)
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: widget.isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbStepButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ThumbStepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  State<_ThumbStepButton> createState() => _ThumbStepButtonState();
}

class _ThumbStepButtonState extends State<_ThumbStepButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: widget.isEnabled,
        onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
        onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
        child: MouseRegion(
          cursor: widget.isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTapDown: widget.isEnabled
                ? (_) => setState(() => _isPressed = true)
                : null,
            onTapUp: widget.isEnabled
                ? (_) => setState(() => _isPressed = false)
                : null,
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.isEnabled ? widget.onTap : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: widget.isEnabled ? 1.0 : 0.4,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 100),
                scale: _isPressed ? 0.92 : 1.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? AppColors.surfaceLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isFocused
                          ? AppColors.goldAccent
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultRaceViewportBackdrop extends StatelessWidget {
  final MobileThumbStageTelemetry telemetry;
  final MobileThumbRiderSummary? selectedRider;

  const _DefaultRaceViewportBackdrop({
    required this.telemetry,
    required this.selectedRider,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F1115),
            Color(0xFF161A23),
            Color(0xFF0F1115),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.landscape_rounded,
                size: 44,
                color: AppColors.goldAccent.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 6),
              Text(
                selectedRider != null
                    ? 'Kamera: ${selectedRider!.shortName} (${selectedRider!.activeOrder.label})'
                    : 'Widok wyścigu 3D',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
